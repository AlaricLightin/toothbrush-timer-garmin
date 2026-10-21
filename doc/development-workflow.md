Implement the first incomplete Step from doc/implementation-plan.md.

Follow the repository's AGENTS.md instructions and all applicable
project documentation.

Execute the following workflow autonomously.

## 1. Preparation

- Read the implementation plan, product requirements, technical design,
  and relevant existing code.
- Inspect the current Git status and preserve unrelated changes.
- Examine the Steps in doc/implementation-plan.md in their defined order.
- Compare each Step's requirements and acceptance criteria against
  the actual project state.
- Identify the first Step that has not been fully implemented.
- If that Step is partially implemented, complete the remaining work
  rather than starting from scratch.
- Do not rely solely on completion markers in the plan; verify
  implementation status against the actual code.
- Do not implement functionality planned for later Steps.
- Changes to code from earlier Steps are allowed only when necessary
  for the selected Step.

If all Steps are already implemented, report that and stop.

If you cannot reliably determine which Step should be implemented,
stop and explain the ambiguity.

If you discover contradictory requirements, conflicting documentation,
or an ambiguity requiring a significant architectural or product
decision, stop immediately.

Explain the issue, identify the conflicting requirements or missing
decision, and propose possible resolutions. Do not make assumptions
to resolve such issues.

## 2. Implementation

- Implement the selected Step according to the implementation plan.
- Follow the established architecture and coding conventions.
- Add or update meaningful automated tests for the implemented behavior.
- Avoid unrelated changes, speculative abstractions, and unnecessary
  refactoring.

## 3. Verification

After implementation:

- Build the project for the primary target device.
- Run the relevant automated tests.
- Run the full test suite if the changes warrant it.
- Perform applicable simulator checks if the simulator is available.
- Check for new compiler or analyzer warnings.

Do not claim that a check passed unless it was actually executed.

If verification is blocked by an environment or tooling problem,
distinguish it from an implementation failure. Do not modify
application code to work around an unrelated environment problem.

If a required verification step cannot be executed, stop and report
the blocker and the checks that remain unverified.

## 4. Code Review

Review the actual code changes, using the Git diff and surrounding
code rather than relying on your implementation summary.

Review the changes critically, as if they had been written by
another developer.

Focus on:

- Compliance with the selected Step's requirements and acceptance criteria.
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
affecting the selected Step:

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
decision requiring user approval, stop immediately instead of
continuing the correction loop.

## 6. Completion

Do not commit or push changes.

Provide a concise final report containing:

- Selected Step number and title.
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

Do not declare the selected Step fully verified if required checks
were not successfully completed.