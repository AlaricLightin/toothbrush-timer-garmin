# Toothbrush Timer — Implementation Plan

## 1. Purpose and status

Implement the MVP in [product-requirements.md](product-requirements.md) using [technical-design.md](technical-design.md) and the workflow rules in [AGENTS.md](../AGENTS.md). Those documents remain authoritative for behavior, architecture, and development policy.

Step 1 is complete: Strict debug and release builds pass without warnings after fixing the template language declaration and launcher icon dimensions. The current debug artifact was rerun through host `monkeydo` on the Vivoactive 6 simulator running in Distrobox; the template image and prompt render without app runtime errors after the resource fixes. See [verification.md](verification.md). Steps 2–9 and full simulator/hardware acceptance remain pending.

## 2. Original starting point

Before step 1, the repository contained the standard application/view/delegate scaffold and sample menu, image, strings, and layout. No timer, tests, README, or build scripts existed. Replace template behavior incrementally.

`manifest.xml` targets `vivoactive6`, uses entry class `ToothbrushTimerApp`, and requests API `3.2.0`; permissions, languages, and barrels were initially empty. English is now declared; permissions and barrels remain empty. Preserve application identity and target, and audit the API minimum against actual usage. Initially, `monkey.jungle` contained only `project.manifest = manifest.xml`.

## 3. Platform pitfalls and open checks

Keep these details in mind during implementation:

| Topic | Implementation consequence |
| --- | --- |
| [Elapsed clock](https://developer.garmin.com/connect-iq/api-docs/Toybox/System.html#getTimer-instance_function) | `System.getTimer()` rolls over. Prove duration arithmetic with fake-clock tests; callback counts and absolute deadlines are unsuitable. |
| [Arc drawing](https://developer.garmin.com/connect-iq/api-docs/Toybox/Graphics/Dc.html#drawArc-instance_function) | Parameters truncate toward zero; equal start/end angles draw a full circle. Skip zero/tiny foreground arcs and handle full progress separately. |
| [Input routing](https://developer.garmin.com/connect-iq/api-docs/Toybox/WatchUi/BehaviorDelegate.html) | Select can originate from Enter or a tap. Returning true consumes the corresponding raw input, so blindly toggling on Select can defeat touch hit testing. |
| [Resource loading](https://developer.garmin.com/connect-iq/api-docs/Toybox/WatchUi.html#loadResource-instance_function) | Account for modern bitmap references rather than assuming the legacy bitmap type. |
| [Backlight control](https://developer.garmin.com/connect-iq/api-docs/Toybox/Attention.html#backlight-instance_function) | Timeout/settings and burn-in protection still apply. Handle `BacklightOnTooLongException` without retrying around protection or affecting timer state. |

Resolve the following checks at the indicated implementation steps:

1. **Minimum API (steps 1–8):** inventory actual calls, types, resources, and exceptions. Select the lowest level supporting them and Vivoactive 6; verify compilation and execution. Neither the template value nor the device's supported API version determines the answer.
2. **Touch versus Select (step 6):** first probe returning false from `onSelect()` so taps reach `onTap()` and Enter reaches `onKey()`. Route `KEY_ENTER` through the shared primary action and handle `onBack()` normally. Confirm one action per input and no action outside controls before binding final controls.
3. **Completion vibration followed by exit (step 5, early when hardware is available):** probe the completion profile immediately followed by `System.exit()` on Vivoactive 6. If exit truncates the signal, propose a clarification to requirements §§4.6/5.3 and design §§5/12 and obtain approval before changing exit timing. Do not add a speculative wait or completion screen.
4. **Screen behavior (step 7):** measure timeout and burn-in restrictions. Start/Resume requests are the baseline; add coarse renewal only if hardware evidence shows it is useful and permitted.
5. **System haptic restrictions (steps 5 and 9):** verify ordinary vibration, DND, and sleep settings. API availability alone does not establish firmware behavior. Resolve any conflict with the requirement to respect system restrictions before acceptance.

Hardware unavailability leaves the relevant checks open; it does not establish that the proposed behavior works.

## 4. Build and test workflow

Use [README.md](../README.md) for prerequisites, signing-key provisioning, verified debug/release build commands, and the simulator launch procedure. Strict checking is configured in `monkey.jungle`; do not also pass `-l 3`. Build and simulator-launch results are recorded in [verification.md](verification.md).

Step 2 will add and validate test compilation with `-t` and execution using the SDK's `monkeydo` test mode, then document the verified commands in README. The inspected Unix launcher accepts `-t testFunctionName` for a focused test; verify the selected host's help before using other variants such as `/t`. Check test results rather than assuming the launcher's exit status proves a pass.

## 5. Implementation steps

Each increment must build for Vivoactive 6 with Strict checking and no new warnings. Run relevant tests after logic changes and the full suite after integration. Use §§6–7 for detailed coverage; record unavailable checks explicitly.

### Step 1 — Establish the baseline build

**Dependencies:** none.

**Status:** complete. Debug/release builds pass, including paths containing spaces. Host `monkeydo` launches the starter in the Distrobox simulator; the template screen renders. Source discovery is restricted to `source/` so generated verification copies cannot enter normal builds. See [verification.md](verification.md).

- Build the untouched starter first to identify existing warnings. Make only the template typing/configuration adjustments needed for Strict checking.
- Establish debug and release CLI builds using §4 and launch the starter in the simulator.
- Add README setup instructions covering prerequisites, environment variables, signing-key provisioning, simulator launch, and repository-relative outputs. Add wrappers only if needed.

**Verify:** record compiler version, target, commands, results, and blockers. Check clear setup failures and path quoting, including paths containing spaces when possible. Keep keys and generated artifacts outside the tracked file set.

### Step 2 — Add configuration, clock, and test harness

**Dependencies:** step 1.

- Add typed `TimerConfig`, deriving stage count from positive, evenly divisible durations.
- Add the production clock around `System.getTimer()` and a fake clock using a simple typed dependency.
- Configure Jungle discovery for `source/` and `tests/`; annotate test functions and test-only helpers with `:test` so normal builds exclude them.

**Verify:** discover and run meaningful configuration tests without wall-clock sleeps. Temporarily introduce a failing test to establish failure reporting, then remove it and obtain a passing run. Confirm normal/release artifacts exclude test code. Test duration arithmetic with the model in step 3.

### Step 3 — Implement the session model and cue detection

**Dependencies:** step 2.

- Implement `BrushingTimer` state, accumulated running time, rollover-safe deltas, and derived remaining time/progress/stage according to design §§5–7.
- Use one clock sample per synchronization/action. Keep synchronized values readable by the view without advancing time or consuming events during drawing.
- Return the conceptual `NONE`, `INTERVAL`, or `COMPLETION` result. Track processed boundaries, collapse overdue interval cues, and give completion priority over intervals and simultaneous input.
- Expose synchronization/action handling so the delegate consumes each result once without silently discarding it.

**Verify:** all domain cases in §6 pass, including alternate configuration, reset, irregular callbacks, pause/resume, and rollover. Keep platform side effects outside the model.

### Step 4 — Replace the template UI and share layout geometry

**Dependencies:** step 3.

- Wire one model, view, and delegate with clear ownership. Build READY first, then extend the same view for RUNNING/PAUSED.
- Add English resources, including `Stage $1$/$2$`, and a small static toothbrush asset and launcher resource. Remove unreferenced sample menu/code/resources.
- Calculate relative layout once for rendering and touch hit testing. Render countdown using ceiling seconds, continuous progress with stage separators, and state-appropriate controls.
- Cache resources outside frequent redraws where practical. If live input is not ready, preview representative model states through a temporary fixture excluded from production artifacts.

**Verify:** presentation cases in §6 pass. Preview READY, PAUSED, partial progress, exact stage boundaries, 50 seconds, and near completion in the simulator. Check circular layout, resource types, and zero/tiny arc behavior; do not add pixel-level tests.

### Step 5 — Add haptics and probe completion/exit

**Dependencies:** steps 1–2. This work can proceed alongside steps 3–4, especially when hardware is available early.

- Implement typed `HapticsService` with interval and completion operations and profiles within documented API limits.
- Use capability checks and handle recoverable failures without changing session state or preventing exit.
- Run the completion/exit and system-settings probes from §3. Record results in `doc/verification.md`.

**Verify:** simulator calls complete without exceptions; hardware establishes perceptibility, distinctness, and survival through exit. Keep unavailable hardware checks open. Count service calls in orchestration tests rather than testing motor-profile values.

### Step 6 — Integrate inputs, periodic updates, and lifecycle cleanup

**Dependencies:** steps 3–5; physical haptic acceptance may remain pending.

- Verify the §3 input-routing probe, then bind touch controls through shared geometry and Enter through the shared Start/Pause/Resume action. Preserve standard Back behavior.
- Introduce one repeating timer while RUNNING, initially around 250 ms. Synchronize on callbacks and before running-state user actions; consume at most one event and return after completion before processing further input or redraws.
- Implement Stop/reset, Back/exit, and exactly-once completion orchestration as specified in design §12.
- **Add application-stop cleanup in this same increment:** stop callbacks, discard the session, and release ownership appropriately on exit/suspension. Ensure launch/resume starts READY. Treat `View.onHide()` as visibility information rather than proof of termination.

**Verify:** input, stale-callback, failure, and repeated-cleanup cases in §6 pass using minimal test doubles/hooks within existing components. Run applicable input and lifecycle scenarios in §7. Reserve actual platform exit/input delivery for simulator/device checks.

### Step 7 — Add screen behavior and review ownership

**Dependencies:** step 6.

- Request Boolean backlight activation on Start/Resume. Stop requests on Pause, Stop, Back, completion, and application cleanup; allow normal dimming while paused.
- If the §3 hardware check justifies renewal, use the existing callback/clock with a separate coarse renewal timestamp. Stop renewal after platform refusal for that running period.
- Review object and timer-callback references for strong cycles, including what stopping/releasing the timer retains. Keep callbacks short and diagnostics limited to meaningful events.

**Verify:** request-policy and failure tests in §6 pass. Exercise screen and lifecycle scenarios in §7; repeated sessions must not accumulate retained memory or exhaust timers. Record hardware limitations explicitly.

### Step 8 — Run complete simulator regression

**Dependencies:** steps 1–7.

- Run the full Monkey C suite and Strict debug, test, and release builds, then all simulator scenarios in §7, including a real-duration session.
- Re-audit actual API usage/minimum level, resource-based strings, permissions, imports, and excluded features. Remove probes/fixtures from production artifacts.
- Record results, SDK version, relevant captures, and memory readings in `doc/verification.md`, referencing README commands rather than duplicating them. Fix in-scope issues and rerun affected checks.

**Verify:** no new warnings, full automated/simulator coverage passes, and memory remains within the target limit. Review product acceptance criteria §17 alongside the matrices, including absence of sound, settings, and persistence. Additional device testing is optional and does not expand the supported target list automatically.

### Step 9 — Validate physical Vivoactive 6 and hand off

**Dependencies:** step 8; earlier hardware findings feed this step.

- Build and sideload the release `.prg` into `GARMIN/APPS` using Garmin's supported transfer procedure; document the host procedure without assuming a mount path.
- Run physical scenarios in §7 over complete and interrupted sessions. Record firmware, relevant settings, artifact, results, and outstanding checks in `doc/verification.md`.
- Tune permitted profile/layout/refresh details as needed and repeat affected verification. Complete README instructions and propose stable commands for `AGENTS.md`.

**Verify:** handoff distinguishes implementation completion, simulator verification, and physical acceptance. Full MVP acceptance requires the hardware checks and no unresolved contradiction with the authoritative documents; unavailable checks remain explicitly outstanding.

## 6. Minimum automated test matrix

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
| Integration failure paths | Haptic/backlight refusal; callbacks in READY/PAUSED/COMPLETED; repeated cleanup | Domain state remains correct; completion effects occur once; cleanup is safe to repeat |
| Screen request policy | Start/resume, pause/stop/exit, and platform refusal; coarse renewal if implemented | Requests follow allowed transitions/cadence, stop after refusal, and never change domain time |

Test domain event counts separately from delegate side-effect counts: a correct timer alone does not prove the delegate cannot vibrate or exit twice. Use minimal seams within the existing components for tests; reserve actual platform exit/input delivery for simulator/device verification.

## 7. Manual acceptance matrix

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
| Screen restrictions | Transition logic and available simulator protection behavior | Full session with wrist down, normal timeout/gesture settings, long pause, resume, relevant power settings; no crash or retry loop on protection |
| System haptic settings | Record simulator limits | DND/sleep/vibration settings respected; suppressed feedback does not stop countdown or exit |
| Lifecycle | External exit/suspend where supported; new launch READY | Leave through normal controls/system interruptions, resume/relaunch, and confirm no background timing or restored session |
| Repeated use | Several complete/stop/pause cycles; stable memory/timer count | Several sessions, including release build; no leftover cues or growing instability |

Record **pass**, **fail**, or **not run**, with evidence and reason. Simulator request logs cannot certify motor feel, AMOLED behavior, touch ergonomics, or the real watch's exit destination.

