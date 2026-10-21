# Verification

## Step 1 — Baseline build (2026-10-18)

Step 1 is complete. Strict debug/release builds pass without warnings. The current
debug artifact was rerun in the Vivoactive 6 simulator after the language/icon
fixes; the template image and prompt render without app runtime errors. Full
simulator and physical-device acceptance remain pending.
Reusable commands and prerequisites are in [README.md](../README.md).

### Environment

- Host: Ubuntu 24.04.5 LTS, Bash, OpenJDK 21.0.12.1.
- Simulator: Ubuntu 22.04.5 LTS in Distrobox, X11/XWayland, same SDK as the host.
- Connect IQ SDK: 9.2.0, build `2026-06-09-92a1605b2`.
- Target: `vivoactive6`; device package `eddc2840754f6d29c6c9a3ede43befdaadd25a09`,
  advertising API 6.0.3 (package metadata, not observed watch firmware).
- Signing: disposable RSA 4096-bit PKCS#8 DER key in ignored verification output.

These versions record the tested environment, not universal prerequisites.

### Results

| Check | Result | Evidence |
| --- | --- | --- |
| Untouched Strict build | Pass | `BUILD SUCCESSFUL`; missing-language and 24×24 launcher-icon warnings |
| Debug and release builds | Pass | README build commands succeed without warnings after declaring `eng` and setting SVG output to 54×54; original artwork/view box retained |
| Paths containing spaces | Pass | Debug/release builds with spaces in SDK, key, and checkout paths |
| Setup failures | Pass | Missing/invalid SDK or key, missing Java, invalid mode, extra arguments, and wrong directory give actionable errors |
| Compiler failure propagation | Pass | Invalid DER key returns compiler exit status 101 |
| README key provisioning | Pass | OpenSSL validates key; mode 0600; spaces supported; existing file rejected |
| Static checks | Pass | Shell syntax, manifest language/SVG dimensions, and `git diff --check`; generated artifacts and keys ignored |
| Source discovery | Pass | Debug/release rebuilds exclude copied projects under `build/` |
| Simulator launch and rendering | Pass after resource fixes | README host `monkeydo` command launches the rebuilt debug artifact in the existing Distrobox simulator; template image/prompt render without app runtime errors; `starter-current.png` and `monkeydo-current.log` |
| Simulator cleanup | Pass | File > Kill App stops the app; host `monkeydo` returns 0 |
| Sample menu / Back | Not verified | Earlier Escape/simulated Back and rerun X11 input injection produced no visible transition; input delivery was not established, so input acceptance remains for steps 4/6 |
| Monkey C tests | Not run | No tests yet; step 2 adds the harness |
| Physical Vivoactive 6 | Not run | No connected test device used |

Logs and the starter capture are local, ignored artifacts under `build/verification/`;
they are not available in a fresh checkout.

The post-fix rerun used the README debug/release build commands and debug
`monkeydo` command. Both builds returned zero without warnings; their logs are
`debug-current.log` and `release-current.log`. The debug app remained running in
the simulator for inspection. The release artifact was rebuilt but not launched
in this rerun. No Monkey C unit tests exist at this step.

### Limitations and follow-up

- Headless Java compilation avoids the initial AWT/display failure; explicit
  `base.sourcePath = source` prevents duplicate definitions from verification copies.
- Native simulator libraries were missing on the host. Distrobox resolved them;
  the [README GTK/X11 workaround](../README.md#run-the-app-from-the-host) resolved
  a capture-dialog crash. Optional GTK/accessibility diagnostics remained.
- The post-fix rendering check confirms that the template prompt is still clipped
  at the round display edge. Step 4 replaces the scaffold UI and launcher artwork.
- Manifest API 3.2.0 is retained; the minimum-API audit is still open.
- Hardware acceptance still requires vibration feel, touch ergonomics, readability,
  screen/backlight restrictions, hardware controls, and exit/lifecycle checks.
  Follow the [implementation plan's acceptance matrices](implementation-plan.md).
- Proposed `AGENTS.md` update: record the README's debug/release build commands
  as stable. Add test commands after step 2 validates the harness.

## Step 2 — Configuration, clock, and test harness (2026-10-20)

Verified with Connect IQ SDK 9.2.0, OpenJDK 21.0.12.1, and the Vivoactive 6
device package. The simulator ran in Ubuntu 22.04 Distrobox using the README's
GTK/X11 workaround. Reusable commands are in [README.md](../README.md#unit-tests).

| Check | Result | Evidence |
| --- | --- | --- |
| Strict debug/release/test builds | Pass | `BUILD SUCCESSFUL`; no compiler/analyzer warnings |
| Full Monkey C suite | Pass | `PASSED (passed=8, failed=0, errors=0)`; configuration variants, deterministic fake time, raw rollover, and production clock sampling; no sleeps |
| Failure reporting | Pass | Temporary probe: `FAILED (passed=0, failed=1, errors=0)`; removed before final rebuild and passing suite |
| Focused test | Pass | `defaultTimerConfig`: `PASSED (passed=1, failed=0, errors=0)` |
| Test-code exclusion | Pass | Eight test symbols and `FakeClock` present in test PRG/debug metadata, absent from debug/release PRGs and metadata |
| Static checks | Pass | `bash -n scripts/build.sh`, `git diff --check`, and source/diff review |

`monkeydo` returned **1** for passing and deliberately failing runs; results above
use printed summaries. Optional GTK/accessibility diagnostics were environmental.
Local logs are ignored under `build/verification/stage2/`, unavailable in a fresh checkout.

[`System.getTimer()`](https://developer.garmin.com/connect-iq/api-docs/Toybox/System.html#getTimer-instance_function)
requires API 1.0.0, adding no requirement above the current manifest's 3.2.0.
The project-wide minimum-API audit remains open.

Stage 2 checks are complete. Fake-clock wraparound is verified; rollover-safe
session-duration arithmetic remains for step 3. Full application simulator and
physical Vivoactive 6 acceptance remain pending; see the
[acceptance matrices](implementation-plan.md#7-manual-acceptance-matrix).

Proposed `AGENTS.md` update: record the README build/test commands as stable,
retaining their prerequisites and printed-summary check.

## Step 3 — Session model and cue detection (2026-10-21)

Step 3 is implemented and its required domain checks pass. Verified with Connect
IQ SDK 9.2.0, OpenJDK 21.0.12.1, and the Vivoactive 6 device package. The simulator
ran in the existing Ubuntu 22.04 Distrobox with the README's GTK/X11 workaround.
Commands and prerequisites remain in [README.md](../README.md#build) and
[unit tests](../README.md#unit-tests).

### Results

| Check | Result | Evidence |
| --- | --- | --- |
| Strict debug/test/release builds | Pass | `BUILD SUCCESSFUL`, no compiler/analyzer warnings |
| Full Monkey C suite in Vivoactive 6 simulator | Pass | `PASSED (passed=27, failed=0, errors=0)`; all 19 new domain tests and 8 existing tests ran |
| Domain coverage | Pass | All Step 3 cases in the [automated test matrix](implementation-plan.md#6-minimum-automated-test-matrix), plus input cue propagation, single-sample actions, and getters without clock reads or cue consumption |
| Test-code exclusion | Pass | 19 new test function symbols, assertion class, and fake clock present in test PRG/metadata and absent from normal debug/release PRGs/metadata |
| Static checks and code review | Pass | Shell syntax, tracked/new-file whitespace checks, actual diffs and surrounding configuration/clock code reviewed; no unresolved actionable defects |
| Interactive simulator acceptance | Not run | This increment adds only domain logic; the starter UI does not use it yet. Applicable domain checks executed through the simulator test runner |
| Physical Vivoactive 6 | Not run | No connected hardware used; vibration, touch/readability, screen restrictions, hardware controls, and real exit/lifecycle checks remain pending for later steps |

The launcher returned 1 for the passing run; the result above uses its printed
summary. Optional GTK/accessibility diagnostics were environmental. Local logs
are ignored under `build/verification/stage3/`, unavailable in a fresh checkout;
`*-build-final.log` and `tests-final.log` record the final checks.

The model adds no device API calls. Its clock dependency retains the existing
[`System.getTimer()`](https://developer.garmin.com/connect-iq/api-docs/Toybox/System.html#getTimer-instance_function)
contract. Duration subtraction uses rolling 32-bit
[`Number`](https://developer.garmin.com/connect-iq/api-docs/Toybox/Lang/Number.html)
arithmetic, verified at both wrap edges for normal running periods. `toFloat()`
requires API 1.0.0, so this step adds no requirement above the current manifest's
3.2.0; the project-wide minimum-API audit remains open.
