# AGENTS.md

## Authority and scope

This is the single root instruction file for the entire Toothbrush Timer repository: a Monkey C Garmin Connect IQ watch app, primarily for Vivoactive 6.

Before implementation, read [product requirements](doc/product-requirements.md) and [technical design](doc/technical-design.md), the authoritative sources for behavior and implementation constraints. Use [development workflow](doc/development-workflow.md) to handle new tasks and active plans; consult [UI design](doc/design/ui-design.md) for visual changes.

- Do not silently deviate from the authoritative documents. If a task, conflicting documents, or new findings require a change, identify the conflict, propose the documentation change, and obtain explicit confirmation before changing affected implementation or documentation. Continue independent work where possible. Existing explicit confirmation for that specific change is sufficient.
- Make local, reversible implementation decisions independently. Ask before decisions materially affecting architecture, user behavior, device compatibility, or future extensibility.
- Limit changes to the task. Small related refactorings and local fixes are appropriate when needed for correctness or reduced duplication; report unrelated issues unless they block the work. Preserve the technical design's exclusions; do not add speculative features or abstractions.
- Make a short working plan for nontrivial tasks; a persistent planning file is not routinely required.
- Read-only Git inspection is allowed. Do not commit, push, create/switch branches, rewrite history, or revert others' changes without explicit authorization. Preserve unrelated user changes.

## Toolchain and portability

- Use the official Garmin SDK, Monkey C, standard APIs, and project-template conventions while preserving the design's component boundaries. Builds/tests must work without a particular IDE. Third-party dependencies require substantial justification and explicit approval.
- Follow [README commands](README.md#setup) and [development procedures](doc/development.md). Confirm test success from the printed summary, not process exit status. Do not invent commands or report unexecuted checks.
- Consult current official Garmin documentation for unclear behavior. Before using an unfamiliar API, verify availability at the selected minimum API level and on Vivoactive 6, especially haptics, display, input, and lifecycle APIs. Use the lowest API level supporting the target and actual usage; third-party sources may supplement official documentation.
- Prioritize correctness, Vivoactive 6 compatibility, simplicity, portability, then micro-optimizations.
- Keep code, configuration, and commands portable: repository-relative project paths; documented environment variables (`CIQ_SDK`, `CIQ_KEY`) or documented `PATH` lookup for tools/credentials. Never embed usernames, home/checkout/SDK/key paths or commit secrets/local configuration.
- State command working directory, shell/OS, SDK/device prerequisites, and missing dependencies. Quote path variables, support spaces, and do not assume an IDE, SDK Manager layout, or existing simulator/display session. Preserve environment-variable references in recorded commands; tested versions are evidence, not universal prerequisites.
- Add only tooling required for the authorized task; portability alone does not justify frameworks, CI, or wrappers.

## Code and documentation

- Follow existing Monkey C style with descriptive names and familiar abbreviations only. Prefer simple helpers for concrete responsibilities, reuse, or testing; retain required components.
- Generate project documentation in Markdown and all development text/comments/diagnostics in English. Product localization follows its locale. Comments explain reasons, platform constraints, or non-obvious decisions.
- Follow the technical design for state ownership, timing/configuration, resource-based text, shared drawing/hit-test geometry, type safety, memory, haptics, and system-owned display power. Introduce device-specific code only for a verified requirement.
- Do not add checks for states ruled out by invariants. Handle actual API, capability, and lifecycle failures; recoverable haptics failures must preserve timer state. Avoid unnecessary callback work and allocation, without speculative optimization.
- Introduce no compiler/analyzer warnings; report unrelated existing warnings instead of fixing them automatically.
- Keep documentation focused on current behavior, constraints, reusable procedures, and verification limits. Store each decision in its authoritative document and link to it. Completed plans and superseded narratives belong in Git history; retain durable findings in current documentation.

## Verification and handoff

- Use [testing.md](doc/testing.md) for reusable coverage and [verification.md](doc/verification.md) for dated, artifact-specific results and limits. Historical acceptance never certifies later changes.
- After production changes, run relevant unit tests when possible and build for Vivoactive 6; run the full suite when scope warrants it. Add/update meaningful tests for nontrivial testable logic in any component, using the Monkey C framework and fake clocks.
- Use Vivoactive 6 for routine feature checks. Before each Store release, complete the [release checklist](doc/testing.md#store-release-checklist) for every manifest product.
- Cover affected timing boundaries, pause/resume, reset, duplicate prevention, delayed callbacks, completion priority/exactly-once effects, and rollover. Use simulator checks for applicable input/rendering/navigation/lifecycle behavior, not pixel-level drawing or vibration-profile unit tests.
- Physical Vivoactive 6 checks are required for vibration feel, touch ergonomics, readability, display restrictions, hardware controls, and real exit/lifecycle behavior. Identify checks still requiring hardware when unavailable.
- For documentation-only changes, check consistency, references, and the Git diff; application builds/runtime tests are not required. If required checks cannot run, perform available static checks and explain the limitation without claiming full verification.
- Handoff requires implemented scope, relevant tests, passing available required checks, and no unresolved specification contradiction. Distinguish implementation completion from pending simulator/hardware acceptance.

Keep the final response concise: changed files/behavior, checks actually run and results, manual verification still needed, and unresolved issues or limits.
