Implement the first incomplete work item from doc/implementation-plan.md.

A work item may be a numbered implementation Step or a subsequent change
described under its own heading. Apply this workflow to both the initial
implementation and later changes to the completed application.

Follow the repository's AGENTS.md instructions and all applicable
project documentation.

Execute the following workflow autonomously.

## 1. Preparation

- Read the current implementation plan, product requirements, technical
  design, relevant existing code, and linked change-status records.
- Inspect the current Git status and preserve unrelated changes.
- Examine the work items in doc/implementation-plan.md in their defined
  order, including subsequent changes after the completed MVP summary.
  Do not treat completion of the original MVP as completion of later work.
- Treat the archived plan as implementation history, not the active work
  queue. Do not reopen archived Steps to restore behavior superseded by
  the current product requirements and technical design.
- Compare each work item's scope, requirements, and acceptance criteria
  against the actual project state. For subsequent changes, use the current
  requirements and design together with the applicable regression checks
  in doc/testing.md; separate acceptance headings are not required.
- Identify the first work item that has not been fully implemented.
- If that work item is partially implemented, complete the remaining work
  rather than starting from scratch.
- Do not rely solely on completion markers in the plan; verify
  implementation status against the actual code.
- Distinguish incomplete implementation from implemented work awaiting
  simulator or physical acceptance. Keep those checks explicitly pending;
  they do not by themselves require reimplementation or block selection of
  a later independent work item.
- Do not implement functionality planned for later work items.
- Changes to existing code are allowed only when necessary for the
  selected work item. Preserve unrelated behavior and regression coverage.
- Make a short working plan for nontrivial work.

If all work items are already implemented, report that, identify any
outstanding verification, and stop. Do not invent a new change or select
work from the archive.

If you cannot reliably determine which work item should be implemented,
stop and explain the ambiguity.

If you discover contradictory requirements, conflicting documentation,
or an ambiguity requiring a significant architectural or product
decision, pause the affected work and follow the conflict process in
AGENTS.md. Continue independent work where possible.

Explain the issue, identify the conflicting requirements or missing
decision, propose the necessary documentation change, and obtain explicit
confirmation before changing the affected implementation or documentation.
An explicit confirmation already given for that specific change is sufficient.

## 2. Implementation

- Implement the selected work item according to the current implementation
  plan, product requirements, and technical design.
- Follow the established architecture and coding conventions.
- Add or update meaningful automated tests for nontrivial logic that can
  reasonably be tested automatically. Remove obsolete tests only where the
  selected change supersedes their expectations; preserve independent
  regression coverage. Follow AGENTS.md exclusions for pixel-level drawing
  tests and vibration-profile unit tests.
- Avoid unrelated changes, speculative abstractions, and unnecessary
  refactoring.

## 3. Verification

After implementation:

- Use the established commands and prerequisites in README.md and
  doc/development.md, and the applicable checklists in doc/testing.md.
- Build the project for Vivoactive 6 after production-code changes.
- Run the relevant automated tests, confirming success from the printed
  summary rather than the process exit status.
- Run the full test suite if the changes warrant it.
- Perform applicable simulator checks if the simulator is available.
- Check for new compiler or analyzer warnings.
- For documentation-only changes, review consistency, references, and the
  Git diff; application builds and runtime tests are not required.

Do not claim that a check passed unless it was actually executed.

If verification is blocked by an environment or tooling problem,
distinguish it from an implementation failure. Do not modify
application code to work around an unrelated environment problem.

If a required verification step cannot be executed, complete the available
checks and review, then report the blocker and the checks that remain
unverified. Physical acceptance requires a Vivoactive 6; simulator results
cannot substitute for it.

Record dated results and limitations in doc/verification.md. Historical
acceptance applies only to the tested revision and environment, not to the
selected change. Update doc/testing.md only when reusable regression
coverage changes.

## 4. Code Review

Review the actual code changes, using the Git diff and surrounding
code rather than relying on your implementation summary.

Review the changes critically, as if they had been written by
another developer.

Focus on:

- Compliance with the selected work item's requirements and acceptance criteria.
- Compliance with product requirements and technical design.
- Correctness, including edge cases and state transitions.
- Potential regressions in existing functionality.
- Adequacy and correctness of automated tests.
- Maintainability, simplicity, and consistency with existing code.
- Garmin Connect IQ platform constraints and compatibility.
- Unnecessary complexity or changes outside the requested scope.

Identify actionable defects, not merely stylistic preferences.
Do not introduce speculative refactoring just to satisfy the review.

## 5. Correction Loop

If verification fails or code review identifies actionable defects
affecting the selected work item:

1. Analyze the problems and their likely root causes.
2. Fix the problems within the allowed scope.
3. Repeat the entire verification phase.
4. Repeat the code review on the updated changes.

Allow at most TWO correction iterations after the initial
implementation.

A correction iteration includes the fixes, verification, and review.

If problems remain after the second correction iteration, stop.
Do not attempt a third correction iteration.

Report the remaining problems, attempted fixes, and likely root causes.

At any point, if you discover a requirements contradiction or a
decision requiring user approval, pause the affected work and follow the
conflict process above instead of resolving it in the correction loop.

## 6. Completion

Do not commit or push changes.

Update the selected work item's status in doc/implementation-plan.md to
reflect the actual implementation outcome and link its verification record.
Keep implementation completion separate from pending simulator or hardware
acceptance. Preserve archived implementation history and historical results.

Provide a concise final report containing:

- Selected work item heading/title, including its Step number or date if present.
- Implementation status: completed, partially completed, or blocked.
- Summary of changes and affected files.
- Build results.
- Test results, including tests added or modified.
- Code review findings and their resolution.
- Number of correction iterations performed.
- Remaining problems, if any.
- Simulator or physical-device checks still required.

Clearly distinguish verified results from checks that could not
be performed.

Do not declare the selected work item fully verified if required checks
were not successfully completed.
