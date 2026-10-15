# AGENTS.md

## Scope and authoritative documents

This is the single root instruction file for the Toothbrush Timer repository. It applies to the entire project: a Monkey C Garmin Connect IQ watch app, with Garmin Vivoactive 6 as the primary target.

Before implementation, locate and read `doc/product-requirements.md` and `doc/technical-design.md`. Requirements define product behavior; the technical design defines architecture and implementation constraints. Use those documents as normative sources rather than duplicating their full contents here.

- Do not silently deviate from either document.
- If a task conflicts with either document, identify the specific conflict, propose the necessary documentation change, and obtain explicit confirmation before changing the affected implementation or documentation. Continue independent work where possible.
- Apply the same rule to conflicts between the documents or discoveries that would make them outdated. Do not automatically rewrite them to match an implementation decision.
- An explicit confirmation already given for the specific change is sufficient; do not ask again.

## Autonomy and change scope

- Make local, easily reversible implementation decisions independently. Ask before decisions that materially affect architecture, user behavior, device compatibility, or future extensibility.
- Use the minimum changes needed for the task. Small related refactorings are appropriate when they directly improve correctness or reduce duplication.
- Do not implement future features as incidental additions. Preserve the deliberately excluded complexity listed in the technical design.
- Do not fix unrelated issues automatically unless they block the task. A very local issue directly affecting changed code may be fixed; otherwise report it separately.
- For nontrivial tasks, make a short working plan. No separate `PLANS.md`, ExecPlan, or persistent planning file is required.
- Read-only Git inspection, including `git status` and `git diff`, is allowed. Do not commit, push, create or switch branches, rewrite history, or revert someone else's changes without an explicit request authorizing that action. Preserve unrelated user changes.

## Toolchain and platform verification

- Use the official Garmin Connect IQ SDK and Monkey C. Builds and tests must work through SDK tools without depending on a particular IDE.
- Follow official Connect IQ project-template conventions for source and resource organization, while preserving the logical component boundaries in the design. Its example filenames and directory layout are not contractual.
- Build and test commands are not established yet. Determine actual commands from the project's configuration, scripts, README, and official SDK documentation; do not invent commands or report unexecuted commands as checks. Once commands are stable, propose recording them here.
- Use standard Connect IQ APIs and SDK facilities. Add third-party dependencies only for a substantial reason and after explicit approval.
- For unclear Garmin behavior, consult current official Garmin documentation rather than guessing. Third-party material may supplement it.
- Before using an unfamiliar Connect IQ API, verify availability at the selected minimum API level and on Vivoactive 6, especially for haptics, backlight, input, and lifecycle behavior. Select the lowest API level supporting the target and all APIs actually used.
- When multiple approaches are available, prioritize correctness, Vivoactive 6 compatibility, simplicity, portability to other devices, then micro-optimizations, in that order.

## Code and resources

- Prefer simple code over speculative abstractions. Introduce helpers, services, or interfaces when they serve a concrete responsibility, reuse, or testing need; retain the components already required by the design.
- Follow established Monkey C conventions and the existing project's style. For new code, use consistent, descriptive names and avoid abbreviations except familiar ones such as `ms` or `UI`.
- All project documentation and other text generated as part of development must be in English, including code comments, README files, design notes, diagnostics, and commit-message drafts. Product localization resources are the exception: their language follows the locale. Generated project documents must be Markdown.
- Comments should explain reasons, platform constraints, or non-obvious decisions rather than restating obvious code.
- Load user-visible text through standard Connect IQ string resources. MVP resources contain English only. Format the stage label using both the current stage and the configured stage count; do not embed a literal `4` in its resource string.
- Centralize timing configuration and derive stage count. Do not duplicate duration or stage-count literals across timer, UI, and haptics code.
- Keep domain timing logic independent of drawing, vibration, and application-exit APIs. Preserve the single authoritative source of session state and elapsed time defined in the design.
- Prefer relative layout and standard APIs over model-specific branches. Add device-specific code only when a verified requirement makes it necessary. Rendering and touch hit testing must share layout geometry.
- Do not add defensive checks for states ruled out by established invariants. Handle actual limitations and failures at Garmin API, hardware-capability, and lifecycle boundaries; recoverable haptics or backlight failures must not corrupt timer state.
- Respect watch memory and performance limits. Avoid clearly unnecessary allocations or work in frequent callbacks, but do not micro-optimize without a measurable reason. Do not request backlight control on every UI tick or log every tick.
- Changes must not introduce compiler or analyzer warnings. Report unrelated existing warnings rather than automatically fixing them.

## Verification

- After production-code changes, run relevant unit tests whenever the environment permits. Run the full unit-test suite when changes are broad enough to warrant it, and build for the primary target.
- Add or update meaningful unit tests for nontrivial logic that can reasonably be tested automatically, especially timer/domain behavior. This rule applies to all such logic, not only a class named `BrushingTimer`.
- Use the Connect IQ Monkey C test framework and a fake clock. For timer changes, cover the affected cases from the technical design: boundaries, pause/resume, reset, duplicate prevention, delayed callbacks, completion priority and exactly-once handling, and clock rollover.
- Do not create artificial pixel-level drawing tests or vibration-profile unit tests. Use the simulator for applicable navigation, input, rendering, and lifecycle checks when available.
- Physical Vivoactive 6 checks are required for vibration feel, touch ergonomics, readability, screen/backlight restrictions, hardware controls, and real exit/lifecycle behavior. If hardware is unavailable, explicitly identify the checks still needing manual verification.
- If a build or test cannot run, state what was not checked and why, perform the available static checks, and do not claim the change is fully verified.

## Completion and final response

A task is ready for handoff when the requested change is implemented, relevant tests are added or updated, available required tests and builds pass, and no known unresolved contradiction with the authoritative documents remains. Clearly distinguish implementation completion from outstanding simulator or hardware acceptance checks.

Keep the final response concise and include:

- what changed, including the relevant files;
- tests and build checks actually run, with their results;
- manual verification still needed;
- unresolved issues or verification limitations, if any.
