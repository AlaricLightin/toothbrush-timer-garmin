# Toothbrush Timer — Technical Design

## 1. Scope

This document defines the implementation architecture for the MVP described in `product-requirements.md`. It is intentionally compact: it specifies the decisions needed for reliable implementation without duplicating the product requirements or prescribing every method and line of code.

The implementation plan is out of scope and will be maintained separately.

## 2. Platform and Compatibility

- Language: Monkey C.
- Platform: Garmin Connect IQ watch app.
- Primary device: Garmin Vivoactive 6.
- The minimum Connect IQ API level is selected when the project is created: use the lowest level that supports Vivoactive 6 and all APIs actually used.
- The initial manifest may target only Vivoactive 6, while the code should avoid unnecessary device-specific assumptions so compatible devices can be added later.

## 3. Components

| Component | Responsibility |
| --- | --- |
| Application class | Creates application objects, returns the initial view, performs cleanup on exit. |
| `MainView` | Draws READY, RUNNING, PAUSED, and COMPLETED states. Contains presentation logic only. |
| `MainDelegate` | Handles touch/hardware input, periodic updates, haptics orchestration, redraws, and the completion presentation delay before exit. |
| `BrushingTimer` | Single authoritative source for session state and brushing-time logic. |
| `TimerConfig` | Centralizes duration values, including completion presentation duration; derives stage count from brushing durations only. |
| Clock | Provides millisecond time; production implementation uses `System.getTimer()`, tests use a fake clock. |
| `HapticsService` | Encapsulates Garmin vibration APIs and vibration profiles. |

Dependency direction:

```text
Application
  +-- MainView --------> BrushingTimer, TimerConfig, Resources
  +-- MainDelegate ----> BrushingTimer, HapticsService, Clock
                            |
                            +--> TimerConfig
```

`BrushingTimer` must not depend on `WatchUi`, drawing, vibration, or application-exit APIs. Architectural exclusions are collected in §18.

## 4. Configuration

MVP timing values are centralized:

- total duration: `120000 ms`;
- interval duration: `30000 ms`;
- stage count: `totalDuration / intervalDuration`.

Keep a separate named `completionDisplayDurationMs`, initially `3000 ms`, in the same configuration. The controller reads this tunable presentation delay; do not duplicate it in exit logic. It does not affect brushing time, stage count, or cue scheduling.

The literals `120`, `30`, and `4` must not be duplicated across timer, UI, and haptics code. The configuration assumes positive durations and equal-length stages.

## 5. Session State

`BrushingTimer` has four states:

```text
READY --start--> RUNNING --pause--> PAUSED
  ^                  ^                 |
  |                  +----resume-------+
  +------stop--------+------stop--------+

RUNNING --duration reached--> COMPLETED
```

`COMPLETED` is terminal: remaining brushing time is zero and progress is one. The presentation delay adds no domain state or brushing elapsed time; controller handling follows §12.

Back/exit is an application action, not a session state. Stop resets the session to READY; separate STOPPED or CANCELLED states are unnecessary.

## 6. Timing Model

### 6.1 Clock

A repeating `Timer.Timer` drives reevaluation and redraws but is not the source of elapsed time. Actual elapsed time comes from the injected millisecond clock.

Production uses `System.getTimer()`. Code must calculate durations from timer-value differences rather than compare absolute timer values, so normal operation remains correct across timer rollover. Rollover behavior should be unit-tested.

### 6.2 Running and Paused Time

The session stores:

- accumulated elapsed time from completed RUNNING periods;
- the clock value at which the current RUNNING period began;
- the highest interval boundary already processed.

While RUNNING:

```text
elapsed = accumulatedElapsed + elapsedSince(runStartedAt)
```

On Pause, the current running delta is added to `accumulatedElapsed`. On Resume, `runStartedAt` is set to the current clock value. No list of pause intervals is stored.

Derived values:

```text
remainingMs = max(totalDurationMs - elapsedMs, 0)
progress    = clamp(elapsedMs / totalDurationMs, 0..1)
stage       = min(floor(elapsedMs / intervalDurationMs) + 1, stageCount)
```

The displayed remaining seconds use `ceil(remainingMs / 1000)`. Therefore the session starts at `2:00` and `0:01` remains visible until actual completion. COMPLETED replaces the countdown and stage label with a completion message; it does not display `0:00`.

## 7. Periodic Updates and Cue Detection

`MainDelegate` owns one `Timer.Timer`, used in repeating mode while the session is RUNNING and rearmed in one-shot mode for completion presentation (§12). A repeating period around 250 ms is the initial target; it may be tuned on hardware without changing timer semantics.

Each repeating brushing callback:

1. returns immediately unless the session is RUNNING;
2. synchronizes `BrushingTimer` with the current clock value;
3. processes at most one resulting event;
4. requests `WatchUi.requestUpdate()` if the application remains active.

The only domain results needed are conceptually `NONE`, `INTERVAL`, and `COMPLETION`.

Interval boundaries are tracked so each is processed at most once. If a delayed callback crosses several intermediate boundaries, emit one interval cue and mark all crossed intermediate boundaries processed. For example, a jump from 29.8 s to 60.2 s produces one vibration, not two.

Completion has priority over overdue interval cues. If synchronization first observes elapsed time at or beyond 120 s, emit only the completion event, even if an earlier interval cue was missed.

Input synchronization and completion/exit priority follow §12.

## 8. UI

One `MainView` renders all states using the palette, layout, and components in [UI design](design/ui-design.md). Centralize semantic colors and derive shared drawing/hit-test geometry from display bounds and available inner radius.

Draw the ring programmatically from model progress and `stageCount`, following [UI design §4](design/ui-design.md#4-dynamic-progress-ring). Handle zero and full segments explicitly to avoid zero-length arcs becoming full circles. Use standard text rendering and drawing primitives for buttons, control icons, and static completion rays where practical.

`MainView` may format time, control labels, and localized stage text. Domain decisions remain in `BrushingTimer`. Static assets and loading constraints are specified in §13.

## 9. Input

`MainDelegate` should extend `WatchUi.BehaviorDelegate` so touch and device-independent Garmin behaviors share one controller.

Touch uses Start, Pause/Resume, and Stop regions from the shared geometry (§8).

Hardware behavior:

- Back: follow the exit procedure in §12;
- Select/primary action where naturally supported: Start in READY, Pause in RUNNING, Resume in PAUSED;
- Stop remains touch-only when there is no natural dedicated hardware action.

In COMPLETED, ignore primary actions and stale control taps; expose no tappable controls. Back/system exit remains available through §12.

## 10. Haptics

`HapticsService` exposes only two semantic operations:

- interval cue;
- completion cue.

All intermediate cues share one single-pulse vibration profile. Completion uses three short pulses separated by two brief pauses, submitted in one `Attention.vibrate()` call with five `Attention.VibeProfile` entries in pulse/pause/pulse/pause/pulse order. Pause entries use zero duty cycle. Keep the pattern in `HapticsService`; do not schedule separate calls or add timers or blocking waits between pulses.

Tune pulse strength and pulse/pause durations on Vivoactive 6; values used in tested artifacts are recorded in [verification](verification.md#three-pulse-completion-implementation-2026-11-04). API references: [vibrate](https://developer.garmin.com/connect-iq/api-docs/Toybox/Attention.html#vibrate-instance_function) and [VibeProfile](https://developer.garmin.com/connect-iq/api-docs/Toybox/Attention/VibeProfile.html).

The service should use Garmin capability checks where required. Unsupported or restricted vibration must not corrupt timer state or prevent completion. No sound APIs are used.

## 11. Screen Behavior

The application delegates display wake, brightness, dimming, and timeout entirely to Garmin system mechanisms and user settings in every session state.

Do not call `Attention.backlight()` (including with `false`), set display brightness, or introduce keep-awake requests or renewal timers. Start, Resume, interval cues, completion, and cleanup perform no display-power control. No backlight capability checks, retry logic, or exception handling are needed.

Retain normal redraws and the periodic timing mechanism defined in §7. Display dimming or blanking alone does not change session state, stop timing, or suppress haptic orchestration. Do not infer application suspension from display visibility; actual suspension/termination follows §12. Verify timing, cues, and completion with the display off on Vivoactive 6.

## 12. Stop, Exit, Completion, and Lifecycle

Pause and Stop synchronize first (§7). If synchronization reaches completion, handle completion without applying the requested action.

Otherwise, Stop in RUNNING or PAUSED:

1. stop the periodic timer;
2. reset `BrushingTimer` to READY;
3. request a redraw.

Back or another system exit action takes priority in every state, including at the completion boundary. Process exit without synchronizing the model, submitting a new cue, or starting a completion presentation:

1. stop any repeating updates or pending completion exit callback;
2. discard session state;
3. exit immediately with the normal Connect IQ application exit mechanism, or allow system-initiated closure to proceed. Never wait for an already submitted vibration or the presentation delay.

Completion, when exit has not taken priority:

1. `BrushingTimer` enters COMPLETED once;
2. stop the periodic timer;
3. submit the entire three-pulse completion pattern once in a single vibration call, subject to system haptic restrictions;
4. request a redraw of COMPLETED and rearm the owned timer as a one-shot for `completionDisplayDurationMs`, starting at completion handling rather than at an inferred past brushing deadline;
5. when that callback runs, consume the pending exit once and exit cleanly. Haptics being unavailable, suppressed, or failing must not skip the presentation or prevent the scheduled exit.

The SDK supports one-shot operation through `Timer.Timer.start(callback, duration, false)` and restarting a stopped timer ([official timer API](https://developer.garmin.com/connect-iq/api-docs/Toybox/Timer/Timer.html), API 1.0.0). Reuse the existing timer with a distinct completion-exit callback; do not add a concurrent timer or blocking wait. This does not require raising the existing API minimum. Confirm the mode change and cancellation on the Vivoactive 6 simulator and hardware during implementation.

Keep only pending callback ownership in the controller; do not duplicate domain completion state or elapsed brushing time. Guard the exit callback with active lifecycle ownership, pending status, and the authoritative COMPLETED state. Clear pending ownership before exiting. Repeated redraws, late RUNNING callbacks, or repeated completion observations must neither rearm the delay nor repeat haptics or exit. The delay is independent of redraw count and display visibility; platform callback/render latency makes its visible duration approximate. Do not wait for a rendered frame or request display wake.

Back, actual suspension/termination, and application cleanup stop the timer in either mode and clear pending ownership. Cleanup must be safe to repeat and release callback references, avoiding strong reference cycles. A discarded controller's callback must not affect a fresh launch. Display dimming or view hiding alone is not a suspension signal and must not cancel the delay.

Verify on Vivoactive 6 that all three completion pulses are perceptible through automatic exit. Tune the named presentation value and haptic profile coherently if needed; the presentation delay must never postpone the completion signal or change the two-minute brushing deadline.

A later launch always starts fresh in READY at `2:00`, including when the platform reports a resume. `AppBase.onStop()` performs cleanup only.

## 13. Resources and Localization

Use standard Connect IQ string resources as required by [requirements §9](product-requirements.md#9-localization), with both current stage and stage count as stage-format arguments. Icon-only controls do not require visible text labels.

Store the in-app toothbrush and launcher icon as separate static graphical resources, with transparency around the in-app illustration. Prefer editable vector sources and appropriately sized Connect IQ-compatible exports; runtime vector support is not assumed. Follow the standard project template and load/cache resources outside frequent redraws. Verify exports, transparency, stroke readability, and resource loading on Vivoactive 6. Reference PNGs are design inputs, never full-screen runtime backgrounds.

## 14. Diagnostics and Failure Handling

Development builds may use lightweight `System.println()` diagnostics for meaningful events such as state transitions, interval cues, completion, ignored callbacks, and recoverable device-capability failures. Do not log every periodic tick.

No recoverable platform-feature failure should leave session state inconsistent. Callback guards and haptics failure handling follow §§7, 10, and 12.

## 15. Core Invariants

1. `BrushingTimer` is the only authoritative source of session state and elapsed brushing time.
2. Callback frequency never determines elapsed time.
3. Paused time never counts toward brushing time.
4. Each intermediate boundary is processed at most once.
5. Delayed callbacks do not replay multiple old cues.
6. Timing constants and UI strings are centralized rather than duplicated.

Completion priority, exactly-once effects, reset, exit, and fresh-launch guarantees follow §12; terminal brushing values follow §5.

## 16. Testing Strategy

Use [testing.md](testing.md) as the reusable coverage specification and [verification.md](verification.md) for dated results and limitations.

- Automated: Monkey C tests with a fake clock for domain logic, presentation arithmetic, controller scheduling, and side-effect counts; no pixel tests, vibration-profile tests, or real-time sleeps.
- Simulator: rendering, resource loading, navigation, input, lifecycle integration, and layout on additional candidate devices.
- Physical Vivoactive 6: vibration feel, touch ergonomics, readability, display restrictions, hardware controls, and real exit/lifecycle behavior. Simulator success cannot certify these.

## 17. Suggested Source Organization

Exact filenames are not contractual, but a structure similar to this is appropriate:

```text
source/
    ToothbrushTimerApp.mc
    MainView.mc
    MainDelegate.mc
    BrushingTimer.mc
    TimerConfig.mc
    Clock.mc
    HapticsService.mc

tests/
    BrushingTimerTests.mc

resources/
    strings/
    drawables/
```

Use the actual Connect IQ project-template conventions where they differ from this example.

## 18. Deliberately Excluded Complexity

The MVP does not introduce persistence, background execution, networking, settings infrastructure, a generic event framework or timed-event scheduler, arbitrary per-stage durations, DI infrastructure, a repository or DTO/view-model layer, an exit-service abstraction, a logging framework, or device-specific views unless a later concrete requirement makes one of them necessary.

## 19. Implementation Conventions

### Type Safety

- Use Monkey Types throughout the application.
- Enable Strict type checking in the project build configuration.
- Explicitly type function parameters, return values, and class fields.
- Avoid `Any` and unchecked casts unless necessary for compatibility with Connect IQ APIs. Document such exceptions.

### Memory Management

- Account for Monkey C's reference-counted memory model.
- Avoid circular strong references, including cycles involving callback methods.
- Avoid unnecessary allocations and repeated resource loading in frequently invoked callbacks, particularly UI redraws and timer callbacks.
- Prefer simple object ownership and lifecycle management over elaborate memory-management abstractions.

### Event Handlers

- Keep timer and UI event handlers short and non-blocking.
- Avoid expensive operations during periodic updates.

