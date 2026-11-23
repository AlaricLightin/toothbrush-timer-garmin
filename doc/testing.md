# Regression Testing

Use these checklists for the current specification. Behavior and architecture
remain defined by [product requirements](product-requirements.md) and
[technical design](technical-design.md); [AGENTS.md](../AGENTS.md) defines the
verification policy. Build and run commands are in [README](../README.md).

Select cases affected by a change, run the full suite when integration scope
warrants it, and build for Vivoactive 6 after production-code changes. Include
applicable simulator and physical checks; record unavailable checks explicitly.
Review product requirements alongside the matrices, including resource
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
| Stop around interval | Stop at boundary −1, boundary, and boundary +1 for 30000/60000/90000 ms, with due boundaries unprocessed or already processed; repeat across clock rollover | Before completion, return NONE and reset to READY; delegate submits no new interval vibration; processed cues are not repeated |
| Stop with overdue intervals | Stop after 29800 → 60200 ms or start → 95000 ms without intervening synchronization; restart and reach the first interval | Discard all overdue interval cues, return NONE, cancel periodic updates, and reset bookkeeping; no stale cue while READY; restarted session cues normally |
| Completion boundary | Synchronize at 119999, 120000, and beyond | RUNNING until actual duration; then COMPLETED, remaining zero, progress 1, stage capped |
| Completion priority | Jump from before an interval to beyond 120000; process Pause/Stop at completion | Only COMPLETION; no overdue interval or subsequent pause/stop transition |
| System exit priority | Back/system cleanup just before, at, and after completion is due, before completion handling; also during presentation | Immediate exit/cleanup without model synchronization, new cue, or new presentation; pending callbacks cancelled; no wait for haptics or delay |
| Terminal handling | Repeat synchronization/callback/primary input after completion | No second completion effect; terminal state retained until discarded/new session |
| Signed rollover | Start near `2147483647`, advance across signed wrap | Small positive elapsed difference; normal boundaries/cues |
| Wrap and pause | Cross −1 → 0 and wrap during a paused interval | Correct running delta; paused time still excluded |
| Alternate configuration | Test-only positive equal-stage durations/count different from the default configuration | Derived stage count, boundaries, and completion work without literal four |
| Presentation | Remaining ms: 120000, 119999, 119000, 1000, 1; dynamic stage resource | `2:00`, `2:00`, `1:59`, `0:01`, `0:01`; configured stage denominator. COMPLETED replaces countdown/stage with the completion message |
| Segment fractions | Zero, tiny/partial progress within stages, exact boundaries, completion; alternate stage counts including fractional slot angles | Fractions follow UI design §4, independent of rounded countdown text; paused fractions remain frozen. Integer sweeps skip sub-degree fills, full fills match track endpoints, and gaps survive completion. Test arithmetic, not pixels |
| Shared layout geometry | Vivoactive 6 content positions and control row, plus control extents and pill ends on representative square and rectangular displays | The content has the intended vertical spacing and all controls share the same row on Vivoactive 6. The ring stroke stays inside display bounds and controls fit inside the ring with circular clearance. Hit testing includes pill centers and ends and excludes rounded-off corners and outside points. |
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
| [Shared timer layout](design/ui-design.md#shared-layout) | Follow READY → RUNNING → PAUSED → READY using Start, Pause, and Stop. The toothbrush and countdown stay in place, the stage label appears below the countdown only in RUNNING and PAUSED, and the controls stay on the same row. | On wrist, check that the toothbrush clears the ring and that visible gaps separate the toothbrush, countdown, stage label, and controls. The time and stage should each be readable at a glance. |
| Full session | Continuous clockwise ring enclosing controls, stages, countdown rounding, partial fill and boundaries; three interval requests and one completion request | Time against an independent stopwatch; cues at approximately 30/60/90 seconds of active time and completion at approximately 120 seconds, allowing callback/platform latency; no accumulated drift |
| COMPLETED presentation | Full mint-green segments with gaps, toothbrush/static rays, localized `Nice job!`, no countdown/stage/buttons or active control hit regions; automatic exit after configured duration | Approximately three-second initial presentation when display is visible; readable message and complete vibration; Back exits early; display-off completion/exit remains correct |
| Vibration | Trace request order/count; confirm one completion API call with pulse/pause/pulse/pause/pulse profiles; inspect runtime errors | All interval cues feel the same; final cue has three distinct short pulses separated by brief pauses, with all three perceptible through automatic exit; no sound |
| Pause/resume | Freeze time/ring/stage; filled ring yellow, Resume/play button mint green; exact continuation restores mint-green progress | Include a long pause; verify active-time cue schedule, color distinction, and screen dimming/resume behavior |
| Stop/restart | Before completion is due, RUNNING and PAUSED Stop reset all visible state immediately; trace Stop at an unprocessed interval boundary to confirm no new vibration request, while Pause still requests one cue | Touch is reliable; no confirmation; subsequent session has normal cue sequence. Check Stop near interval boundaries; an already submitted vibration may still be felt and does not establish a new Stop-triggered request |
| Touch geometry | Center/edge taps inside each pill, rounded-off corners, and outside all regions; no accidental Select fallback. Stale control taps and primary input in COMPLETED do nothing | Comfortable targets on wrist; Pause/Resume and Stop easy to distinguish |
| Hardware controls | Enter primary action, Esc/swipe-right Back, no double dispatch | Confirm actual short-press behavior and standard system exit controls |
| Completion/input race | Pause/Stop yields to completion; Back/system exit bypasses completion handling and cancels pending exit work | Back/system exit closes immediately at the boundary and during presentation, without waiting for vibration; no extra cues or stuck app |
| System-controlled display | Normal transitions/redraws; source review confirms no display-power requests; simulator cannot certify brightness or wake behavior | Record timeout/brightness/gesture settings; run a full session with wrist down and display off, long pause/resume, sleep and battery saver. Verify permitted cues and completion/exit continue, normal system wake restores current state, and Start/Resume cause no app-requested brightness change. Check whether a wake touch/button also invokes a control; do not assume every input wakes the display or is consumed solely for wake |
| System haptic settings | Record simulator limits | DND/sleep/vibration settings respected; suppressed feedback does not stop countdown or exit |
| Lifecycle | External exit/suspend where supported, including during completion delay; cancel callbacks; new launch READY | Leave through normal controls/system interruptions, resume/relaunch, and confirm no background timing, stale exit callback, or restored session |
| Repeated use | Several complete/stop/pause cycles; stable memory/timer count | Several sessions, including release build; no leftover cues or growing instability |

Record **pass**, **fail**, or **not run**, with evidence and reason. Simulator request logs cannot certify motor feel, AMOLED behavior, touch ergonomics, or the real watch's exit destination.

## Platform regression notes

- After resource or API changes, check drawable loading, the manifest API minimum, and support on each target device. See [rendering and resources](technical-design.md#rendering-and-resources).
- Test DND, System and Alert vibration switches independently, including recovery. Record which switches were set. Firmware-specific results are in [platform observations](verification.md#platform-observations).
- Check release of timer callbacks and object references. Exercise actual suspension or termination separately from display blanking, view hiding, or an interruption overlay.

## Recording results

Keep a compact, dated [verification baseline](verification.md). Identify the change, source revision or working-tree changes, artifact hash, SDK, device, firmware, and relevant settings. Record automated, simulator, and user-reported watch results separately, including which checks ran and what remains unverified. Link to reusable commands.

Retain earlier evidence only for coverage or limits that still matter, with its original date and artifact. A focused follow-up establishes only the cases it exercised. Git preserves superseded records.
