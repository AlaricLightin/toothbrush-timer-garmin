# Toothbrush Timer — Technical Design

## Platform and boundaries

This document defines architecture and implementation constraints for the [product requirements](product-requirements.md). Use official Connect IQ project conventions and Monkey C. The [manifest product list](../manifest.xml) supplies the device IDs for Store export and release verification. Single-device builds default to `vivoactive6`. All targets use the same source, resources, and minimum API `3.2.0`. Verify API or device changes under [AGENTS.md](../AGENTS.md) and retain the lowest API level supporting actual usage. Garmin lists device capabilities in its [device reference](https://developer.garmin.com/connect-iq/device-reference/) and [API-level table](https://developer.garmin.com/connect-iq/compatible-devices/).

## Components and ownership

| Component | Responsibility |
| --- | --- |
| `ToothbrushTimerApp` | Creates objects, returns the initial view, and performs exit cleanup. |
| `ToothbrushTimerView` | Presentation only: renders all four states and formats resource-based text. |
| `ToothbrushTimerDelegate` | Touch/hardware input, periodic synchronization, haptics, redraws, and completion-delay scheduling. |
| `BrushingTimer` | Single authoritative source of session state and elapsed brushing time. |
| `TimerConfig` | Centralized brushing/presentation durations and derived stage count. |
| Clock / `SystemClock` | Injected millisecond time; production uses `System.getTimer()`, tests use a fake clock. |
| `HapticsService` | Garmin vibration capability/settings handling and the two cue profiles. |
| `TimerLayout`, `TimerPalette`, `SegmentedRing` | Shared drawing/hit-test geometry, semantic colors, and progress-ring arithmetic/rendering. |

The app constructs the model and collaborators. The view reads the model/configuration/resources; the delegate coordinates the model, view, haptics, and SDK timer. The model depends on configuration and the injected clock, never on drawing, `WatchUi`, vibration, or application-exit APIs. Do not duplicate domain state or elapsed time in the controller or view.

## Configuration and state

`TimerConfig` holds `totalDurationMs = 120000`, `intervalDurationMs = 30000`, and `stageCount = totalDurationMs / intervalDurationMs`. Durations are positive and total duration is evenly divisible by interval duration. Do not duplicate timing or stage-count literals across components.

The separate `completionDisplayDurationMs = 3000` is tunable and centrally defined. It affects only presentation scheduling, never brushing time, stage count, or cues.

```text
READY --start--> RUNNING --pause--> PAUSED
  ^                  ^                 |
  |                  +----resume-------+
  +------stop--------+------stop--------+

RUNNING --duration reached--> COMPLETED
```

COMPLETED is terminal: remaining brushing time is zero and progress is one. Its display delay adds no domain state or elapsed time. Back/exit is an application action; no STOPPED or CANCELLED states are needed.

## Timing and cue detection

Elapsed time comes from the injected clock, never callback counts. Calculate durations from `System.getTimer()` differences so rollover remains correct. Store accumulated time from completed RUNNING periods, the current run's start clock value, and the highest interval boundary processed.

Model getters are side-effect-free: they neither sample the clock nor change state or cue bookkeeping, and return values derived from the last synchronization or action. The view reads these values without synchronizing the model. Each `synchronize()` or `handleAction()` call samples the clock once; input synchronization, completion priority, and the action transition use that same sample. The delegate handles the returned cue once.

```text
elapsedMs   = accumulatedElapsed + elapsedSince(runStartedAt)  // while RUNNING
remainingMs = max(totalDurationMs - elapsedMs, 0)
progress    = clamp(elapsedMs / totalDurationMs, 0..1)
stage       = min(floor(elapsedMs / intervalDurationMs) + 1, stageCount)
```

Pause adds the current running delta to accumulated elapsed time; Resume sets a new run start. No pause-interval list is needed. Display seconds use `ceil(remainingMs / 1000)`: `0:01` remains until completion, which replaces time/stage text rather than showing `0:00`.

The delegate owns one `Timer.Timer`, repeating at 250 ms while RUNNING and rearmed as a one-shot for completion. The repeating period may be tuned on hardware without changing timing semantics. Each repeating callback:

1. Returns unless the controller is active and the session is RUNNING.
2. Synchronizes the model with the clock and processes at most one result: `NONE`, `INTERVAL`, or `COMPLETION`.
3. Requests `WatchUi.requestUpdate()` if the app remains active.

Process each intermediate boundary at most once. When a delayed callback crosses several, emit one interval cue and mark all crossed boundaries processed: 29.8 → 60.2 seconds produces one cue. Input handling applies the Stop suppression rule below before returning a cue to the delegate. At or beyond completion, emit only COMPLETION; never replay overdue interval cues. Repeated observations cannot repeat an event.

## Input and lifecycle

The delegate extends `WatchUi.BehaviorDelegate`. Touch uses the view's shared layout: Start in READY, Pause/Resume and Stop in RUNNING/PAUSED. The primary hardware action starts, pauses, or resumes respectively; Stop stays touch-only where no natural dedicated hardware action exists. COMPLETED ignores primary input and stale control taps; Back remains available.

Select can originate from a tap or Enter. Consuming `onSelect()` can prevent raw coordinate/key delivery. The current delegate returns false there and routes `onTap()` and `KEY_ENTER` separately, ensuring one action per input and no action outside controls. Verify delivery when changing input support ([Garmin behavior delegate](https://developer.garmin.com/connect-iq/api-docs/Toybox/WatchUi/BehaviorDelegate.html)).

Pause and Stop synchronize first. If completion is reached, return COMPLETION and handle it without applying the requested action. Before completion:

- For Stop, `BrushingTimer.handleAction()` discards any newly detected INTERVAL result, resets the model and boundary bookkeeping to READY defaults, and returns NONE. The delegate stops periodic updates and requests a redraw without submitting a new cue. This also applies when synchronization crosses several overdue interval boundaries.
- For Pause, preserve the synchronized position and return the detected cue, if any. The delegate attempts at most one interval cue and stops periodic updates. Crossed boundaries remain processed so Resume cannot replay them.

An interval vibration already submitted by an earlier callback is outside Stop's suppression rule; Stop neither waits for it nor attempts to retract it. These rules implement the [session behavior](product-requirements.md#session-behavior).

Back/system exit has priority in every state, including the completion boundary. Without synchronizing the model or starting any new cue/presentation, stop pending updates/exit callbacks, discard the session, and exit immediately through the normal Connect IQ mechanism (or allow system closure). Never wait for a submitted vibration or presentation delay.

### Completion scheduling

When completion is observed and exit has not taken priority:

1. The model enters COMPLETED once; stop repeating updates.
2. Attempt the complete three-pulse pattern once, respecting system restrictions.
3. Request COMPLETED rendering and rearm the owned timer as a one-shot for `completionDisplayDurationMs`, measured from handling time rather than a past brushing deadline.
4. Consume pending exit ownership once and exit cleanly when the callback runs. Haptic failure/suppression must not prevent presentation or scheduled exit.

Use `Timer.Timer.start(callback, duration, false)` with a distinct completion callback ([timer API](https://developer.garmin.com/connect-iq/api-docs/Toybox/Timer/Timer.html), API 1.0.0). Reuse the owned timer; add no concurrent timer or blocking wait.

The controller tracks only pending callback ownership. Guard completion exit with active lifecycle ownership, pending status, and authoritative COMPLETED state; clear pending ownership before exiting. Redraws, late RUNNING callbacks, and repeated observations must not rearm the delay or repeat cues/exit. Rendering/callback latency makes visible duration approximate; never wait for a frame or display wake.

### Cleanup

Back, actual suspension/termination, and application cleanup stop the timer in either mode and clear pending ownership. Cleanup is repeatable and releases callback references to avoid strong cycles. A discarded controller's callback must not affect a fresh launch. Display blanking or view hiding alone is not suspension and must not cancel timing or the delay.

Every later launch starts fresh in READY, including a reported resume. `AppBase.onStop()` performs cleanup only.

## Haptics and display power

`HapticsService` exposes interval and completion cues. Interval cues share one single-pulse profile. Completion submits five `Attention.VibeProfile` entries in one `Attention.vibrate()` call: pulse/pause/pulse/pause/pulse, using zero duty cycle for pauses. Do not schedule separate calls or timers between pulses. Tune profile values and presentation duration on Vivoactive 6 so all three pulses remain perceptible through automatic exit, without changing the brushing deadline or delaying the completion cue.

Capability checks, settings reads, profile creation, and vibration calls must handle platform refusal without corrupting timer state or preventing completion. Respect DND and vibration settings; use no sound. See the official [vibration](https://developer.garmin.com/connect-iq/api-docs/Toybox/Attention.html#vibrate-instance_function) and [profile](https://developer.garmin.com/connect-iq/api-docs/Toybox/Attention/VibeProfile.html) APIs and [tested firmware observations](verification.md#platform-observations).

Display power is system-owned. Do not call `Attention.backlight()` (even with false), set brightness, or add keep-awake requests/renewal timers. No backlight capability/retry/exception machinery is needed. Keep normal redraws and timing independent of display visibility; actual lifecycle cleanup follows the rules above.

## Rendering and resources

One view renders all states using the [UI design](design/ui-design.md). Centralize semantic colors; derive layout from display bounds and available inner radius. Drawing and hit testing share geometry. The view formats text but makes no domain decisions.

Draw the ring programmatically from model progress and configured stage count, following [segment geometry](design/ui-design.md#4-dynamic-progress-ring). Equal arc angles can draw a full circle and angles truncate to integers: handle zero/tiny fills and full segments explicitly ([drawing API](https://developer.garmin.com/connect-iq/api-docs/Toybox/Graphics/Dc.html#drawArc-instance_function)). Use standard fonts/primitives for text, buttons, control icons, and static rays where practical.

Use [string resources](product-requirements.md#localization), passing both current stage and count to the stage format. Icon-only controls need no visible labels. Load/cache strings and artwork outside frequent redraws.

Keep the launcher and transparent in-app toothbrush as separate static resources. Prefer editable vector sources with appropriately sized Connect IQ-compatible exports; runtime vector support is not assumed. Reference PNGs are design inputs, never full-screen runtime backgrounds. The current view uses `WatchUi.Bitmap` to handle underlying bitmap resource types. Verify export transparency, strokes, and resource loading on the target.

## Implementation constraints

- Use Monkey Types and Strict checking; explicitly type parameters, results, and fields. Avoid `Any`/unchecked casts except documented API compatibility needs.
- Account for reference-counted memory: avoid strong cycles, including callback cycles, and keep ownership simple.
- Keep handlers short and non-blocking. Avoid unnecessary work, allocation, and resource loads in frequent callbacks; do not micro-optimize without evidence.
- Lightweight `System.println()` diagnostics may describe meaningful events or recoverable failures; never log every tick. Platform failures must preserve domain invariants.
- Do not add persistence, background execution, networking, settings infrastructure, generic event frameworks/schedulers, arbitrary per-stage durations, DI infrastructure, repository/DTO/view-model layers, exit-service abstractions, logging frameworks, or device-specific views without a concrete later requirement.

## Verification

Follow [AGENTS.md](../AGENTS.md) and the reusable [regression matrix](testing.md). Use fake-clock Monkey C tests for domain logic, presentation arithmetic, controller scheduling, and side-effect counts, without real-time sleeps, pixel assertions, or vibration-profile unit tests. Simulator checks cover rendering/input/lifecycle integration; physical Vivoactive 6 checks establish motor feel, readability, touch, display restrictions, controls, and real lifecycle behavior. [Verification](verification.md) records evidence and limits for specific artifacts.
