# Regression Testing

Use these checklists for changes to the completed MVP. Behavior and architecture
remain defined by [product requirements](product-requirements.md) and
[technical design](technical-design.md); [AGENTS.md](../AGENTS.md) defines the
verification policy. Build and run commands are in [README](../README.md).

Select cases affected by a change, run the full suite when integration scope
warrants it, and build for Vivoactive 6 after production-code changes. Include
applicable simulator and physical checks; record unavailable checks explicitly.
Review product acceptance criteria alongside the matrices, including resource
strings and the absence of sound, settings, persistence, and background timing.

Use the Monkey C test framework and a fake clock for deterministic timing tests.
Do not add pixel-level drawing tests or vibration-profile unit tests. Keep
fixtures/probes outside production artifacts and use `:test` for test helpers.

## Minimum automated test matrix

Use fresh model/fake-clock instances per test. Time values below are test inputs and expectations, not additional production timing constants.

| Case | Inputs/actions | Required outcome |
| --- | --- | --- |
| Initial state | Construct model | READY, elapsed zero, full remaining time, zero progress, stage 1 |
| Start | Start at a nonzero clock value | RUNNING with zero brushing elapsed; no immediate cue |
| Boundary values | For 30000, 60000, 90000 ms: synchronize at boundary −1, boundary, boundary +1 | Correct remaining/progress; stage changes at the boundary; one interval event |
| Repeated observation | Synchronize repeatedly at/after a processed boundary | No duplicate cue |
| Delayed callback | 29800 → 60200 ms | One interval event, stage 3, both crossed boundaries marked processed |
| Several missed intervals | Jump from start to 95000 ms | One interval event, stage 4; no replay on next callback |
| Fractional pause | Pause after 12345 ms, advance clock while paused, resume | Exact elapsed preservation; only subsequent RUNNING delta is added |
| Multiple pauses | Several different running/paused durations | Elapsed equals sum of running durations only |
| Pause around interval | Pause just before, exactly at, and just after a boundary | No early cue; a newly crossed cue is consumed once; no duplicate on resume |
| Stop/reset | Stop RUNNING and PAUSED models after cues | READY defaults and boundary bookkeeping reset; next session cues normally |
| Completion boundary | Synchronize at 119999, 120000, and beyond | RUNNING until actual duration; then COMPLETED, remaining zero, progress 1, stage capped |
| Completion priority | Jump from before an interval to beyond 120000; process input at completion | Only COMPLETION; no overdue interval or subsequent pause/stop transition |
| Terminal handling | Repeat synchronization/callback/input after completion | No second completion effect; terminal state retained until discarded/new session |
| Signed rollover | Start near `2147483647`, advance across signed wrap | Small positive elapsed difference; normal boundaries/cues |
| Wrap and pause | Cross −1 → 0 and wrap during a paused interval | Correct running delta; paused time still excluded |
| Alternate configuration | Test-only positive equal-stage durations/count different from MVP | Derived stage count, boundaries, and completion work without literal four |
| Presentation | Remaining ms: 120000, 119999, 119000, 1000, 1; dynamic stage resource | `2:00`, `2:00`, `1:59`, `0:01`, `0:01`; configured stage denominator. Test zero formatting separately without a completion screen |
| Input routing logic | Inside/outside each control, each session state | Exactly one intended action, no action outside controls |
| Integration failure paths | Haptic refusal; callbacks in READY/PAUSED/COMPLETED; repeated cleanup | Domain state remains correct; completion effects occur once; cleanup is safe to repeat |

Test domain event counts separately from delegate side-effect counts: a correct timer alone does not prove the delegate cannot vibrate or exit twice. Use minimal seams within the existing components for tests; reserve actual platform exit/input delivery for simulator/device verification.

Review production source for the absence of backlight/brightness control and
keep-awake requests, including Start/Resume and cleanup. Remove obsolete
backlight-request/refusal tests when removing that implementation; retain
independent input, timing, haptics, completion, and timer-ownership coverage.

## Manual acceptance matrix

| Scenario | Simulator checks | Physical Vivoactive 6 checks |
| --- | --- | --- |
| Fresh launch | READY layout, resource loading, no automatic countdown | App is discoverable; icon/time/Start readable at a glance |
| Full session | Continuous ring, stages, countdown rounding; three interval requests and one completion request; automatic exit | Time against an independent stopwatch; cues at approximately 30/60/90 seconds of active time and completion at approximately 120 seconds, allowing callback/platform latency; no accumulated drift |
| Vibration | Trace request order/count, inspect runtime errors | All interval cues feel the same; final cue is clearly distinct and not truncated by exit; no sound |
| Pause/resume | Freeze time/ring/stage, Resume label, exact continuation | Include a long pause; verify active-time cue schedule and screen dimming/resume behavior |
| Stop/restart | RUNNING and PAUSED Stop reset all visible state immediately | Touch is reliable; no confirmation; subsequent session has normal cue sequence |
| Touch geometry | Center/edge taps inside each region and outside all regions; no accidental Select fallback | Comfortable targets on wrist; Pause/Resume and Stop easy to distinguish |
| Hardware controls | Enter primary action, Esc/swipe-right Back, no double dispatch | Confirm actual short-press behavior and standard system exit controls |
| Completion/input race | Domain/delegate tests plus simulator exercise | Input near completion does not leave an app stuck or produce extra cues |
| System-controlled display | Normal transitions/redraws; source review confirms no display-power requests; simulator cannot certify brightness or wake behavior | Record timeout/brightness/gesture settings; run a full session with wrist down and display off, long pause/resume, sleep and battery saver. Verify permitted cues and completion/exit continue, normal system wake restores current state, and Start/Resume cause no app-requested brightness change. Check whether a wake touch/button also invokes a control; do not assume every input wakes the display or is consumed solely for wake |
| System haptic settings | Record simulator limits | DND/sleep/vibration settings respected; suppressed feedback does not stop countdown or exit |
| Lifecycle | External exit/suspend where supported; new launch READY | Leave through normal controls/system interruptions, resume/relaunch, and confirm no background timing or restored session |
| Repeated use | Several complete/stop/pause cycles; stable memory/timer count | Several sessions, including release build; no leftover cues or growing instability |

Record **pass**, **fail**, or **not run**, with evidence and reason. Simulator request logs cannot certify motor feel, AMOLED behavior, touch ergonomics, or the real watch's exit destination.

## Platform regression notes

- Clock: cover both signed wrap and −1 → 0 using time differences, not callback
  counts or absolute deadlines ([clock API](https://developer.garmin.com/connect-iq/api-docs/Toybox/System.html#getTimer-instance_function)).
- Rendering: preview zero/tiny arcs, exact boundaries, partial progress at 50 s,
  and near completion. Equal arc angles draw a full circle; check integer-angle
  truncation and handle full progress separately ([arc API](https://developer.garmin.com/connect-iq/api-docs/Toybox/Graphics/Dc.html#drawArc-instance_function)).
- Input: verify coordinate taps and raw Enter each cause one action, with no
  action outside controls. Select consumption can prevent raw input delivery
  ([behavior delegate](https://developer.garmin.com/connect-iq/api-docs/Toybox/WatchUi/BehaviorDelegate.html)).
- Resources/API changes: check drawable loading, actual API minimum, and target
  support. The baseline uses `WatchUi.Bitmap` so the platform handles underlying
  bitmap types. Compilation and an API 6.0.3 simulator do not certify older devices.
- Completion: recheck that the final vibration survives immediate exit after
  haptics/lifecycle changes. If a conflict appears, follow AGENTS.md before
  changing exit timing; do not introduce a speculative delay or completion screen.
- Display: the application must make no backlight or keep-awake requests.
  Garmin documents that the [backlight API](https://developer.garmin.com/connect-iq/api-docs/Toybox/Attention.html#backlight-instance_function)
  can suppress gesture detection while active; do not use it to compensate for
  system timeout or disabled gesture wake. Dimming/blanking alone must not
  change timer state. Hardware checks must distinguish display-off operation
  from actual app suspension/termination; do not add background execution.
- Settings: test DND and the System/Alert vibration switches independently,
  including restoration, sleep, and power modes. Record actual settings instead
  of assuming which physical switch maps to an API flag. Baseline observations
  are in [verification](verification.md#physical-acceptance-2026-11-03).
- Ownership/lifecycle: repeated sessions must release timer callbacks and object
  references. Treat view hiding as visibility information, not proof of app
  termination; distinguish an interruption overlay from actual suspension.

## Recording results

Add dated results to [verification.md](verification.md), identifying the change,
source revision/working-tree changes, artifact hash, SDK/device/firmware/settings,
checks actually rerun, results, and remaining limits. Separate automated,
simulator, and user-reported physical evidence. Link reusable commands instead
of duplicating them. Historical acceptance applies only to its tested revision
and environment; do not carry a previous pass forward as a new test result.
