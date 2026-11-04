Implement the first incomplete work item from [implementation-plan.md](implementation-plan.md),
whether a numbered Step or a subsequent change.

Execute this workflow autonomously under [AGENTS.md](../AGENTS.md), which defines
scope, conflict handling, coding, verification, and reporting policy.

## 1. Preparation

- Read the current plan, product requirements, technical design, relevant code,
  and linked verification records; inspect Git status.
- Compare work items in plan order against the actual code and applicable
  [regression checks](testing.md), rather than relying solely on completion markers.
  Complete the first partially implemented or unimplemented item.
- Treat the archived plan as history, not an active work queue. Current
  requirements and design supersede archived behavior.
- Keep pending simulator or physical acceptance separate from incomplete
  implementation; it does not by itself block a later independent work item.
- If all items are implemented, report outstanding verification and stop.
  If selection is ambiguous, stop and explain why.
- Make a short working plan for nontrivial work.

Follow the AGENTS.md conflict process whenever requirements conflict or a
significant product or architectural decision is needed.

## 2. Implementation

Implement only the selected item's scope under the current requirements and
design. Change earlier code only as needed; do not implement later items.
Apply AGENTS.md testing rules, removing superseded tests only where necessary
and preserving independent regression coverage.

## 3. Verification

Follow AGENTS.md verification policy using the commands and prerequisites in
[README](../README.md) and [development.md](development.md), and the applicable
checklists in [testing.md](testing.md).

For documentation-only changes, review consistency, references, and the Git diff;
application builds and runtime tests are not required.

Distinguish tooling failures from implementation failures. Do not change
application code to work around an unrelated environment problem. Complete
available checks and report any blockers or unverified checks.

Record dated results and limitations in [verification.md](verification.md).
Update testing.md only when reusable regression coverage changes.

## 4. Code Review

Review the actual Git diff and surrounding code for requirement compliance,
correctness, regressions, test adequacy, maintainability, platform compatibility,
and unnecessary complexity or scope expansion. Identify actionable defects,
not merely stylistic preferences.

## 5. Correction Loop

If verification or review finds actionable defects in the selected scope:

1. Analyze and fix the defects.
2. Repeat the verification phase and review the updated changes.

Allow at most **two correction iterations** after initial implementation, each
including fixes, verification, and review. If problems remain after the second,
stop and report the remaining problems, attempted fixes, and likely causes.

## 6. Completion

Update the selected item's status in [implementation-plan.md](implementation-plan.md)
and link its verification record. Separate implementation completion from pending
acceptance; preserve archived history and historical results. Do not commit or push.

Use the AGENTS.md final-report requirements, also identifying the selected item,
its implementation status, review findings and resolutions, and correction count.
