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
