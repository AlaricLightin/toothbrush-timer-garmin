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
- No background service, network access, settings storage, or session persistence is required.

## 3. Components

| Component | Responsibility |
| --- | --- |
| Application class | Creates application objects, returns the initial view, performs cleanup on exit. |
| `MainView` | Draws READY, RUNNING, and PAUSED states. Contains presentation logic only. |
| `MainDelegate` | Handles touch/hardware input, periodic updates, haptics orchestration, redraws, and exit. |
| `BrushingTimer` | Single authoritative source for session state and brushing-time logic. |
| `TimerConfig` | Centralizes total duration and interval duration; derives stage count. |
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

`BrushingTimer` must not depend on `WatchUi`, drawing, vibration, or application-exit APIs. No DI framework, repository layer, generic scheduler, exit-service abstraction, or separate view-model layer is needed.

## 4. Configuration

MVP timing values are centralized:

- total duration: `120000 ms`;
- interval duration: `30000 ms`;
- stage count: `totalDuration / intervalDuration`.

The literals `120`, `30`, and `4` must not be duplicated across timer, UI, and haptics code. The configuration assumes positive durations and equal-length stages; a generic arbitrary-event scheduler is deliberately out of scope.

## 5. Session State

`BrushingTimer` has four states:

```text
READY --start--> RUNNING --pause--> PAUSED
  ^                  ^                 |
  |                  +----resume-------+
  +------stop--------+------stop--------+

RUNNING --duration reached--> COMPLETED
```

`COMPLETED` is terminal for the current session and exists primarily to guarantee one-time completion handling. The controller exits immediately after completion, so there is no completion screen.

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

The displayed remaining seconds use `ceil(remainingMs / 1000)`. Therefore the session starts at `2:00`, `0:01` remains visible until actual completion, and `0:00` normally is not rendered because completion exits immediately.

## 7. Periodic Updates and Cue Detection

`MainDelegate` owns one repeating `Timer.Timer` while the session is RUNNING. A period around 250 ms is the initial target; it may be tuned on hardware without changing timer semantics.

Each callback:

1. returns immediately unless the session is RUNNING;
2. synchronizes `BrushingTimer` with the current clock value;
3. processes at most one resulting event;
4. requests `WatchUi.requestUpdate()` if the application remains active.

The only domain results needed are conceptually `NONE`, `INTERVAL`, and `COMPLETION`; no generic event framework is required.

Interval boundaries are tracked so each is processed at most once. If a delayed callback crosses several intermediate boundaries, emit one interval cue and mark all crossed intermediate boundaries processed. For example, a jump from 29.8 s to 60.2 s produces one vibration, not two.

Completion has priority. If synchronization first observes elapsed time at or beyond 120 s, emit only the completion event, even if an earlier interval cue was missed.

State-changing user actions that depend on current time, especially Pause, should synchronize first. If synchronization reaches completion, completion wins over the requested user action.

## 8. UI

One `MainView` renders all states instead of switching between separate views.

READY shows the toothbrush asset, `2:00`, and Start. RUNNING/PAUSED show the toothbrush asset, remaining time, progress ring, stage label, Pause/Resume, and Stop.

The progress indicator consists of:

- a background ring;
- a foreground arc proportional to `progress`;
- stage separators derived from `stageCount`.

The view should use relative layout calculations where practical rather than device-specific coordinates. Visual styling should favor high contrast; no fixed product palette is required.

There is no separate DTO/view-model layer. `MainView` may perform simple presentation transformations such as milliseconds to `m:ss`, state to Pause/Resume label, and stage values to a localized stage string. Domain decisions remain in `BrushingTimer`.

The toothbrush image is a small static resource asset.

## 9. Input

`MainDelegate` should extend `WatchUi.BehaviorDelegate` so touch and device-independent Garmin behaviors share one controller.

Touch uses tappable regions for Start, Pause/Resume, and Stop. Layout geometry used for hit testing must come from the same layout definition/calculation used by the view rather than duplicate unrelated hardcoded coordinates.

Hardware behavior:

- Back: cancel the current session and exit;
- Select/primary action where naturally supported: Start in READY, Pause in RUNNING, Resume in PAUSED;
- Stop remains touch-only when there is no natural dedicated hardware action.

## 10. Haptics

`HapticsService` exposes only two semantic operations:

- interval cue;
- completion cue.

All intermediate cues share one vibration profile. Completion uses a clearly longer or otherwise more noticeable profile. Exact duty cycles/durations are selected during implementation and verified on Vivoactive 6.

The service should use Garmin capability checks where required. Unsupported or restricted vibration must not corrupt timer state or prevent completion. No sound APIs are used.

## 11. Screen Behavior

While RUNNING, the application makes a best-effort request to keep the display/backlight active using supported Connect IQ behavior. Garmin timeout, power, burn-in, and user-setting restrictions take precedence.

Backlight control must not run on every UI tick. Start and Resume activate the behavior; if periodic renewal is needed on Vivoactive 6, use a much coarser cadence and respect platform limits. Unsupported behavior or a backlight-related exception degrades gracefully without affecting the timer.

While PAUSED, no keep-awake requests are made and normal system dimming is allowed.

## 12. Stop, Exit, Completion, and Lifecycle

Stop in RUNNING or PAUSED:

1. stop the periodic timer;
2. reset `BrushingTimer` to READY;
3. request a redraw.

Back:

1. stop the periodic timer;
2. discard session state;
3. exit cleanly with the normal Connect IQ application exit mechanism.

Completion:

1. `BrushingTimer` enters COMPLETED once;
2. stop the periodic timer;
3. emit the completion vibration once;
4. exit cleanly.

The application never persists or restores an active session. If the platform suspends or terminates the app, the session is discarded. A later launch always starts in READY at `2:00`, including when the platform reports a resume. `AppBase.onStop()` performs cleanup only; no background timing mechanism is used.

## 13. Resources and Localization

All user-visible text must come from standard Connect IQ string resources. Initial resources contain English only, including Start, Pause, Resume, Stop, and the stage label.

The stage format should accept both current stage and total stage count rather than embedding `4` in the localized string.

The toothbrush illustration is stored as a static drawable/resource asset.

## 14. Diagnostics and Failure Handling

Development builds may use lightweight `System.println()` diagnostics for meaningful events such as state transitions, interval cues, completion, ignored callbacks, and recoverable device-capability failures. Do not log every periodic tick and do not introduce a logging framework.

Unexpected timer callbacks in non-RUNNING states are ignored. Haptics/backlight failures are nonfatal. No recoverable platform-feature failure should leave session state inconsistent.

## 15. Core Invariants

1. `BrushingTimer` is the only authoritative source of session state and elapsed brushing time.
2. Callback frequency never determines elapsed time.
3. Paused time never counts toward brushing time.
4. Each intermediate boundary is processed at most once.
5. Delayed callbacks do not replay multiple old cues.
6. Completion occurs exactly once and has priority over overdue interval cues or simultaneous user input.
7. Stop fully resets the session.
8. Back/exit never leaves timing active in the background.
9. Every new launch starts with a fresh READY session.
10. Timing constants and UI strings are centralized rather than duplicated.

## 16. Testing Strategy

### Unit Tests

Use the Connect IQ Monkey C test framework with a fake clock. Unit tests should cover:

- initial state, start, stop/reset;
- elapsed/remaining time and stage boundaries;
- pause/resume, including multiple cycles;
- interval crossing and duplicate prevention;
- delayed callbacks crossing multiple boundaries;
- pause around a boundary;
- completion at and beyond total duration;
- completion priority and exactly-once behavior;
- `System.getTimer()` rollover-sensitive duration calculation.

Pixel-level drawing tests and vibration-profile unit tests are unnecessary.

### Simulator

Use the Connect IQ Simulator for normal navigation, touch behavior, countdown, stage/progress rendering, Pause/Resume/Stop, Back, automatic completion/exit, and layout checks on additional candidate devices.

### Physical Vivoactive 6

Verify on hardware:

- interval vs completion vibration feel;
- touch ergonomics and display readability;
- screen/backlight behavior and system restrictions;
- hardware Back/Select behavior;
- real application exit/lifecycle behavior.

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

The MVP does not introduce persistence, background execution, networking, settings infrastructure, a generic timed-event scheduler, arbitrary per-stage durations, DI infrastructure, a separate view-model layer, an exit-service abstraction, a logging framework, or device-specific views unless a later concrete requirement makes one of them necessary.

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

