# Regression Testing

Use these checklists for the current specification. Behavior and architecture
remain defined by [product requirements](product-requirements.md) and
[technical design](technical-design.md); [AGENTS.md](../AGENTS.md) defines the
verification policy. Build and run commands are in [README](../README.md).

See [README](../README.md) for implementation status. These checklists include
pending design changes; historical passes do not establish their acceptance.

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
| Completion priority | Jump from before an interval to beyond 120000; process Pause/Stop at completion | Only COMPLETION; no overdue interval or subsequent pause/stop transition |
| System exit priority | Back/system cleanup just before, at, and after completion is due, before completion handling; also during presentation | Immediate exit/cleanup without model synchronization, new cue, or new presentation; pending callbacks cancelled; no wait for haptics or delay |
| Terminal handling | Repeat synchronization/callback/primary input after completion | No second completion effect; terminal state retained until discarded/new session |
| Signed rollover | Start near `2147483647`, advance across signed wrap | Small positive elapsed difference; normal boundaries/cues |
| Wrap and pause | Cross −1 → 0 and wrap during a paused interval | Correct running delta; paused time still excluded |
| Alternate configuration | Test-only positive equal-stage durations/count different from MVP | Derived stage count, boundaries, and completion work without literal four |
| Presentation | Remaining ms: 120000, 119999, 119000, 1000, 1; dynamic stage resource | `2:00`, `2:00`, `1:59`, `0:01`, `0:01`; configured stage denominator. COMPLETED replaces countdown/stage with the completion message |
| Segment fractions | Zero, partial progress within stages, exact boundaries, completion; alternate stage count | Fractions follow UI design §4, independent of rounded countdown text. Test arithmetic, not pixels |
| Completion delay | Completion observed on time and late; alternate configured display durations | One cue attempt at completion handling, no immediate exit; one exit after the configured delay; brushing state/time remain terminal |
| Completion cancellation | Back/cleanup before exit, repeated cleanup, old callback after fresh launch | Pending callback cancelled; no duplicate exit or cue; new session unaffected |
| Input routing logic | Inside/outside each control, each session state | Exactly one intended action, no action outside controls |
| Integration failure paths | Haptic refusal; callbacks in READY/PAUSED/COMPLETED; repeated cleanup | Domain state remains correct; completion effects occur once; cleanup is safe to repeat |

Test domain event counts separately from delegate side-effect counts: a correct timer alone does not prove the delegate cannot vibrate or exit twice. Use minimal seams within the existing components for tests; reserve actual platform exit/input delivery for simulator/device verification.

Review production source for the absence of backlight/brightness control and
keep-awake requests, including Start/Resume and cleanup.

## Manual acceptance matrix

| Scenario | Simulator checks | Physical Vivoactive 6 checks |
| --- | --- | --- |
| Fresh launch | Empty segmented ring, toothbrush, resource loading, time and Start; no automatic countdown | Separate launcher icon is recognizable; READY readable at a glance |
| Full session | Continuous clockwise ring enclosing controls, stages, countdown rounding, partial fill and boundaries; three interval requests and one completion request | Time against an independent stopwatch; cues at approximately 30/60/90 seconds of active time and completion at approximately 120 seconds, allowing callback/platform latency; no accumulated drift |
| COMPLETED presentation | Full mint-green segments with gaps, toothbrush/static rays, localized `Nice job!`, no countdown/stage/buttons or active control hit regions; automatic exit after configured duration | Approximately three-second initial presentation when display is visible; readable message and complete vibration; Back exits early; display-off completion/exit remains correct |
| Vibration | Trace request order/count; confirm one completion API call with pulse/pause/pulse/pause/pulse profiles; inspect runtime errors | All interval cues feel the same; final cue has three distinct short pulses separated by brief pauses, with all three perceptible through automatic exit; no sound |
| Pause/resume | Freeze time/ring/stage; filled ring yellow, Resume/play button mint green; exact continuation restores mint-green progress | Include a long pause; verify active-time cue schedule, color distinction, and screen dimming/resume behavior |
| Stop/restart | Before completion is due, RUNNING and PAUSED Stop reset all visible state immediately | Touch is reliable; no confirmation; subsequent session has normal cue sequence |
| Touch geometry | Center/edge taps inside each region and outside all regions; no accidental Select fallback | Comfortable targets on wrist; Pause/Resume and Stop easy to distinguish |
| Hardware controls | Enter primary action, Esc/swipe-right Back, no double dispatch | Confirm actual short-press behavior and standard system exit controls |
| Completion/input race | Pause/Stop yields to completion; Back/system exit bypasses completion handling and cancels pending exit work | Back/system exit closes immediately at the boundary and during presentation, without waiting for vibration; no extra cues or stuck app |
| System-controlled display | Normal transitions/redraws; source review confirms no display-power requests; simulator cannot certify brightness or wake behavior | Record timeout/brightness/gesture settings; run a full session with wrist down and display off, long pause/resume, sleep and battery saver. Verify permitted cues and completion/exit continue, normal system wake restores current state, and Start/Resume cause no app-requested brightness change. Check whether a wake touch/button also invokes a control; do not assume every input wakes the display or is consumed solely for wake |
| System haptic settings | Record simulator limits | DND/sleep/vibration settings respected; suppressed feedback does not stop countdown or exit |
| Lifecycle | External exit/suspend where supported, including during completion delay; cancel callbacks; new launch READY | Leave through normal controls/system interruptions, resume/relaunch, and confirm no background timing, stale exit callback, or restored session |
| Repeated use | Several complete/stop/pause cycles; stable memory/timer count | Several sessions, including release build; no leftover cues or growing instability |

Record **pass**, **fail**, or **not run**, with evidence and reason. Simulator request logs cannot certify motor feel, AMOLED behavior, touch ergonomics, or the real watch's exit destination.

## Platform regression notes

- Clock: use time differences across rollover, not absolute deadlines
  ([clock API](https://developer.garmin.com/connect-iq/api-docs/Toybox/System.html#getTimer-instance_function)).
- Rendering: include zero/tiny arcs and near completion in previews.
  Equal arc angles draw a full circle; check integer-angle
  truncation and handle full progress separately ([arc API](https://developer.garmin.com/connect-iq/api-docs/Toybox/Graphics/Dc.html#drawArc-instance_function)).
- Input: Select consumption can prevent raw input delivery
  ([behavior delegate](https://developer.garmin.com/connect-iq/api-docs/Toybox/WatchUi/BehaviorDelegate.html)).
- Resources/API changes: check drawable loading, actual API minimum, and target
  support. The baseline uses `WatchUi.Bitmap` so the platform handles underlying
  bitmap types. Compilation and an API 6.0.3 simulator do not certify older devices.
- Settings: test DND and the System/Alert vibration switches independently,
  including restoration, sleep, and power modes. Record actual settings instead
  of assuming which physical switch maps to an API flag. Baseline observations
  are in [verification](verification.md#physical-acceptance-2026-11-03).
- Ownership/lifecycle: check release of timer callbacks and object references.
  Distinguish display-off operation, view hiding, and interruption overlays from
  actual app suspension/termination.

## Recording results

Add dated results to [verification.md](verification.md), identifying the change,
source revision/working-tree changes, artifact hash, SDK/device/firmware/settings,
checks actually rerun, results, and remaining limits. Separate automated,
simulator, and user-reported physical evidence. Link reusable commands instead
of duplicating them. Historical acceptance applies only to its tested revision
and environment; do not carry a previous pass forward as a new test result.
