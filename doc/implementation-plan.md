# Toothbrush Timer — Completed MVP Plan

All nine original implementation steps are complete as of 2026-11-03.
The [archived implementation plan](archive/implementation-plan.md) retains the
original sequence and historical step descriptions. There is no incomplete MVP
step to select; future changes need their own scope under [AGENTS.md](../AGENTS.md).

- [Regression checklists](testing.md): reusable automated and manual test coverage.
- [Verification baseline](verification.md): tested artifact, results, and limitations.

This page preserves the original plan path for existing references, including
`development-workflow.md`.

## Subsequent change: system-only display control (2026-11-04)

The requirements and design now prohibit app backlight/keep-awake requests.
This documentation change supersedes the archived step 7 screen policy;
the original implementation history remains unchanged.

Implementation is pending: remove Start/Resume backlight activation and its
helpers from `ToothbrushTimerDelegate`, remove obsolete backlight test fixtures
and cases while preserving independent regression coverage, then build for
Vivoactive 6 and run the relevant tests and simulator checks. Physical acceptance
must cover the updated system-controlled display scenario in [testing.md](testing.md).
See [change status](verification.md#system-only-display-policy-2026-11-04).

## Subsequent change: three-pulse completion signal (2026-11-04)

The requirements and design now specify three short completion vibrations with
brief pauses, submitted as one vibration command. Exact strength and timing are
tunable; the design records an illustrative starting pattern.

Implementation is pending: replace the single long completion profile in
`HapticsService`, preserve interval cues and nonfatal haptics handling, then
build for Vivoactive 6 and run relevant automated and simulator regression
checks. Verify three perceptible pulses and no truncation by immediate exit on
the physical watch, including system haptic suppression and recovery. See
[change status](verification.md#three-pulse-completion-signal-2026-11-04).
