# Toothbrush Timer — Implementation Plan

All nine original implementation steps are complete as of 2026-11-03.
The [archived implementation plan](archive/implementation-plan.md) retains the
original sequence and historical step descriptions. Subsequent changes below
define the active work queue under [AGENTS.md](../AGENTS.md).

- [Regression checklists](testing.md): reusable automated and manual test coverage.
- [Verification baseline](verification.md): tested artifact, results, and limitations.

## Subsequent change: system-only display control (2026-11-04)

Implemented: system-only display control. Focused physical checks passed on
Vivoactive 6 firmware 18.32; see
[results and remaining coverage](verification.md#focused-physical-verification-2026-11-04).

## Subsequent change: three-pulse completion signal (2026-11-04)

Implemented: three-pulse completion in one vibration command. Focused physical
checks passed, including all three pulses through automatic exit, on Vivoactive 6
firmware 18.32; see
[results and remaining coverage](verification.md#focused-physical-verification-2026-11-04).

## Subsequent change: approved UI and completion presentation (2026-11-05)

**Status:** Step 1 implemented; simulator artwork preview and physical acceptance
remain pending. Steps 2–7 are pending.

Implement the approved [UI design](design/ui-design.md) under the current
[requirements](product-requirements.md) and [technical design](technical-design.md).
Those documents remain authoritative; the steps below define work order and
verification checkpoints, not additional product or architecture decisions.

For each production increment, build for Vivoactive 6 with Strict checking and
no new warnings, and run relevant automated tests using the commands and
prerequisites in [README](../README.md). Use [testing.md](testing.md) for detailed
coverage and record dated results and limitations in [verification.md](verification.md).
Keep unavailable simulator and hardware checks separate from implementation status.

### Step 1 — Prepare production artwork

**Dependencies:** none.

**Status:** implemented; simulator visual preview and physical readability remain
pending. See [verification](verification.md#production-artwork-2026-11-06).

- Update the separate in-app toothbrush and launcher resources in
  `resources/drawables/` to follow UI design §§2–3 and §6. Preserve editable vector
  sources and prepare appropriately sized Connect IQ-compatible exports where
  needed; do not use reference screenshots as runtime backgrounds.
- Keep the in-app toothbrush transparent and free of a surrounding ring. Preserve
  the launcher's independent static four-segment motif and handle/ring overlap.
- Verify resource declarations and loading against the current API minimum and
  Vivoactive 6. Cache loaded artwork outside redraw callbacks.

**Verify:** build and preview both resources in the simulator; inspect transparency,
palette, sizing, and stroke readability. Final on-watch readability remains step 7.

### Step 2 — Implement shared geometry, palette, and segmented progress

**Dependencies:** none; coordinate artwork dimensions with step 1 before step 3.

- Update `source/TimerLayout.mc` and the view's drawing code so the outer ring
  encloses the content and controls with safe circular-screen clearance.
  Centralize semantic colors and share control geometry with touch hit testing.
- Replace the continuous sweep with equal drawable segments derived from the
  configured stage count. Apply the per-segment fill formula in UI design §4,
  advancing clockwise from the top with a gap centered on every boundary.
- Handle zero, tiny, and full fills explicitly, including integer-angle truncation;
  retain gaps at full completion. Keep presentation arithmetic independent of
  rounded countdown text and domain state transitions.
- Extend `tests/PresentationTests.mc` for segment fractions, exact boundaries,
  partial progress, and an alternate stage count. Test arithmetic, not pixels.

**Verify:** relevant presentation tests and target build pass; simulator previews
cover empty, tiny, partial, boundary, and full progress without accidental circles
or clipped controls.

### Step 3 — Render all four approved states and align controls

**Dependencies:** steps 1–2.

- Update `source/ToothbrushTimerView.mc` for READY, RUNNING, PAUSED, and COMPLETED
  using UI design §5. Add the resource-based completion message in
  `resources/strings/strings.xml`.
- Draw pill-shaped Start and Pause/Resume/Stop controls with the approved icons
  and colors. Preserve identical RUNNING/PAUSED geometry, frozen paused values,
  and the configured stage denominator.
- Render COMPLETED with a full accent ring, toothbrush, static rays, and message;
  omit countdown, stage, controls, and active control hit regions. Keep the view
  free of scheduling and haptic side effects.
- Update touch handling in `source/ToothbrushTimerDelegate.mc` as needed to match
  the shared geometry. Preserve one action per touch/hardware input and ignore
  primary actions and stale control taps in COMPLETED.
- Update affected presentation and input tests. Preview COMPLETED using a
  test-only fixture until step 5 makes it visible in the live flow.

**Verify:** relevant tests and target build pass; simulator previews match all four
states, including color changes, text clearance, and inside/outside control taps.

### Step 4 — Give Back and system exit immediate priority

**Dependencies:** none; complete before step 5.

- Change delegate Back handling to clean up and exit without synchronizing the
  model or submitting a new cue, including when completion is already due.
- Review `source/ToothbrushTimerApp.mc` and delegate cleanup together: actual
  suspension/termination discards the session, cleanup is repeatable, and later
  launch/resume starts fresh. View hiding or display blanking alone is not cleanup.
- Update `tests/DelegateTests.mc` for exit just before, at, and after the completion
  boundary, overdue intervals, repeated cleanup, and discarded callbacks. Preserve
  completion priority over Pause/Stop.

**Verify:** relevant controller/domain tests and target build pass; Back produces
no new cue or completion handling. Confirm ordinary Back and fresh relaunch in
the simulator; extend cancellation coverage for the delay in step 5.

### Step 5 — Integrate the configured completion presentation delay

**Dependencies:** steps 3–4.

- Add the separate `completionDisplayDurationMs` configuration, initially
  `3000 ms`, in `source/TimerConfig.mc`; update construction sites and configuration
  tests without changing brushing durations, stage derivation, or cue scheduling.
- Update delegate completion handling per technical design §12: retain terminal
  model state, stop repeating updates, attempt the existing three-pulse cue once,
  request COMPLETED redraw, and rearm the same owned SDK timer as a one-shot.
  Start the configured delay when completion is handled, including late detection.
- Track only pending callback ownership in the controller. Guard the exit callback
  by active lifecycle ownership, pending status, and authoritative COMPLETED state;
  consume pending ownership before exit. Do not introduce another timer, domain
  state, scheduler, blocking wait, or display-power request.
- Cancel either timer mode and clear pending ownership on Back or cleanup. Release
  callback references; stale callbacks must not exit a fresh session. Haptic
  suppression/failure must not prevent presentation or scheduled exit.
- Extend configuration and delegate tests with a fake clock and minimal scheduling
  seams for on-time/late completion, alternate display durations, exactly-once
  cue/scheduling/exit, ignored input, haptic failures, cancellation, and stale callbacks.

**Verify:** relevant tests and target build pass. Confirm repeating-to-one-shot
timer reuse and cancellation in the simulator, including Back during presentation;
redraws and late callbacks neither repeat the cue nor restart the delay.

### Step 6 — Run integrated regression and update implementation status

**Dependencies:** steps 1–5.

- Run the full Monkey C test suite and Strict debug, test, and release builds for
  Vivoactive 6. Confirm test success from the printed summary.
- Run applicable simulator scenarios in [testing.md](testing.md), including a
  real-duration session, all state transitions, completion/input races, external
  exit, relaunch, and repeated sessions with memory/timer ownership checks.
- Review actual API usage/minimum level, resource strings, production exclusion of
  test fixtures, and absence of display-power control or other excluded features.
- Record artifact/environment details, results, and unrun checks in
  `doc/verification.md`. Update README and this plan to reflect implemented behavior
  while keeping outstanding simulator or hardware acceptance explicit.

**Verify:** available automated/build/simulator checks pass without new warnings;
remaining limitations are recorded rather than inherited as passes from older builds.

### Step 7 — Validate physical Vivoactive 6 acceptance

**Dependencies:** step 6 for final acceptance; earlier hardware feedback may inform
artwork, layout, and timing tuning.

- Install the verified release artifact using the documented transfer procedure
  and run the applicable physical matrix in [testing.md](testing.md).
- Check launcher/state readability, touch ergonomics, hardware controls, all three
  completion pulses, approximately three-second presentation, immediate Back exit,
  system interruptions, and fresh relaunch.
- Verify display-off countdown/completion/exit and system haptic restrictions.
  Tune only the permitted layout/profile/presentation values if needed, then rerun
  affected automated, build, simulator, and physical checks for the changed artifact.
- Record artifact hash, firmware, settings, observations, and remaining limits in
  `doc/verification.md`; update this plan's acceptance status accordingly.

**Verify:** physical acceptance is recorded for the tested artifact and environment.
If hardware is unavailable, leave this step pending and report implementation and
available verification separately.
