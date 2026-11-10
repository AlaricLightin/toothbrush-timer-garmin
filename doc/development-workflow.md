# Development Workflow

Use this workflow for a new feature, bug fix, or an explicitly requested continuation of an active plan. [AGENTS.md](../AGENTS.md) defines standing rules, approval boundaries, and verification policy.

## 1. Understand and scope the task

Read product requirements and technical design, inspect Git status and relevant code/tests, and consult UI design for visual work. Compare the request with current behavior and constraints. Follow AGENTS.md's confirmation process for conflicts or material product/architecture decisions before changing affected specifications or code.

Use each document for its own responsibility; update it only when the task changes that information:

| Document | Purpose and update trigger |
| --- | --- |
| [Product requirements](product-requirements.md) | User-visible behavior, product scope, localization, and device-support policy |
| [Technical design](technical-design.md) | Architecture, state/timing ownership, lifecycle, platform and implementation constraints |
| [UI design](design/ui-design.md) | Appearance, layout, controls, artwork, and visual references |
| [README](../README.md) / [development](development.md) | Quick-start commands / detailed setup, troubleshooting, and installation |
| [Testing](testing.md) | Reusable automated, simulator, and physical regression coverage |
| [Verification](verification.md) | Checks actually performed, tested revision/artifact/environment, results, and remaining limits |
| [AGENTS.md](../AGENTS.md) | Repository-wide working rules and approval boundaries |
| This workflow | Task intake, planning, implementation, and closure sequence |

Possible extensions are uncommitted ideas, not an instruction to implement them. Update affected specifications before implementation when an approved task changes the contract; do not rewrite them afterward simply to match an implementation choice.

## 2. Plan the work

For a small task, use a short working plan; no implementation-plan file is required. For larger work with dependencies or multiple delivery steps, create `doc/implementation-plan.md` containing only active work: scope, ordered steps/dependencies, verification checkpoints, and implementation/acceptance status. Link to specifications rather than restating them.

When explicitly asked to continue the plan, compare its steps with code and checks and select the first incomplete implementation step. Status markers alone are insufficient. If selection is ambiguous, explain and clarify; if all implementation is complete, report remaining acceptance work rather than inventing another step. Pending simulator/hardware acceptance does not block independent implementation work.

## 3. Implement and verify

Implement the requested task or selected step within its scope. Follow AGENTS.md and the authoritative documents; preserve independent regression coverage when updating tests. Run affected checks from testing.md with documented commands, and record results/limits in verification.md.

Distinguish tooling failures from application defects. Do not change application code to work around an unrelated environment problem; complete available checks and report blockers.

## 4. Review and correct

Review the actual diff and surrounding code for requirement compliance, correctness, regressions, test adequacy, maintainability, platform compatibility, and unnecessary scope/complexity. Fix actionable defects and repeat affected verification/review. Allow at most two correction iterations after initial implementation; if defects remain, report them, attempted fixes, and likely causes.

## 5. Close the task

Update affected documentation and any active plan's status, separating implementation completion from pending acceptance. Follow AGENTS.md's final-report requirements; for planned work also identify the completed step, review findings/resolutions, and correction count.

Once all plan work, including applicable acceptance, is complete, move lasting decisions/findings into their appropriate documents and remove the completed plan. Keep only a compact, scoped verification baseline; Git retains committed history. Do not remove unresolved acceptance work or carry an older pass forward as evidence for a new revision. No permanent archive or empty plan file is needed.
