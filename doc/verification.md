# Verification

Current handoff: steps 1–9 are complete for the tested Vivoactive 6 firmware
18.32 and settings. See [step 9](#step-9--physical-vivoactive-6-acceptance-2026-11-03)
for user-reported hardware acceptance and verification limits. Earlier sections
are dated snapshots; hardware checks marked pending there were addressed in
step 9 to the extent described in its results and limits.

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

## Step 4 — Presentation and shared layout (2026-10-21)

Step 4 is implemented. Verified with Connect IQ SDK 9.2.0, OpenJDK 21.0.12.1,
and the Vivoactive 6 package in the Ubuntu 22.04 Distrobox simulator using the
README's GTK/X11 workaround. Build and suite commands remain in
[README.md](../README.md#build) and [unit tests](../README.md#unit-tests).

| Check | Result | Evidence |
| --- | --- | --- |
| Strict debug/release/test builds | Pass | README build commands report `BUILD SUCCESSFUL`; no compiler/analyzer warnings |
| Full Monkey C suite | Pass | `PASSED (passed=31, failed=0, errors=0)`; all 27 existing and 4 new tests ran |
| New presentation tests | Pass | Ceiling formatting at initial, fractional-second, minute, near-completion, and zero values; model-driven labels/reset/pause; dynamic six-stage resource formatting |
| Shared geometry tests | Pass | Centers, corners, and immediately outside each control; separate active-control regions at three display sizes. These exercise bounds, not pixels or platform input dispatch |
| Simulator state previews | Pass | READY; RUNNING at 0, 1, 15000, 30000, 50000, 60000, 90000, and 119999 ms; PAUSED at 50000 ms; alternate six-stage configuration |
| Visual review | Pass | Full toothbrush, readable countdown/stage/control labels, Resume fits its border; circular layout stays inside display; zero/tiny progress does not draw a full foreground circle; partial arcs and stage separators follow configuration; `0:01` remains near completion |
| Production debug launch | Pass | README `monkeydo` command loads the final artifact in READY with toothbrush, `2:00`, and Start; no automatic countdown or runtime errors; `production-ready.png` |
| Test/fixture exclusion | Pass | New test functions and fake clock absent from normal debug/release symbol metadata, present in test metadata; preview app absent from all main-project artifacts |
| Static checks and code review | Pass | Shell syntax, tracked/new-file whitespace, Git diff and surrounding code reviewed; no unresolved actionable defects |
| Physical Vivoactive 6 | Not run | No hardware used; readability and touch ergonomics still require on-watch acceptance |

State previews use the production view and fake-clock models in an isolated,
test-only project under `build/verification/stage4/preview/`. Captures and the
preview log are in `build/verification/stage4/final-previews/`; build logs and
`tests-final.log` are in `build/verification/stage4/`. These ignored artifacts
are unavailable in a fresh checkout. The passing launcher returned 1; the
printed summary establishes the test result.

The official [arc contract](https://developer.garmin.com/connect-iq/api-docs/Toybox/Graphics/Dc.html#drawArc-instance_function)
(API 1.2.0) requires skipping equal angles at zero/tiny progress; full progress
uses a circle separately. Basic drawing/fonts, Math, and
[resource substitution](https://developer.garmin.com/connect-iq/api-docs/Toybox/Lang.html#format-instance_function)
use API 1.0.0 facilities. The cached bitmap accepts both legacy resources and
modern references, as documented by
[`loadResource`](https://developer.garmin.com/connect-iq/api-docs/Toybox/WatchUi.html#loadResource-instance_function);
the reference path executed on the Vivoactive 6 simulator (API 6.0.3).
Manifest 3.2.0 remains unchanged; the project-wide minimum-API audit remains open
for the later platform integrations and step 8.

Live touch/Enter/Back routing, periodic redraws, session effects, and lifecycle
acceptance remain for steps 5–8. Physical readability, ergonomics, vibration,
screen restrictions, hardware controls, and real exit/lifecycle behavior remain
outstanding under the [manual acceptance matrix](implementation-plan.md#7-manual-acceptance-matrix).

## Step 5 — Haptics and completion/exit probe (2026-10-28)

Step 5 implementation is complete; physical acceptance remains pending. Verified
with Connect IQ SDK 9.2.0 and the Vivoactive 6 simulator (API 6.0.3) in the
existing Ubuntu 22.04 Distrobox. Commands and prerequisites remain in
[README build](../README.md#build), [unit tests](../README.md#unit-tests), and
[simulator](../README.md#simulator). Builds and the expanded test suite were
reverified on 2026-10-29.

`HapticsService` provides interval and completion cues as single pulses at 100%
duty cycle, lasting 250 ms and 1,000 ms respectively. It checks capability,
vibration enablement, and available DND state on every request. Capability/settings
reads, profile construction, and vibration calls share a nonfatal exception
boundary. The service has no timer/session or exit dependency; controller
orchestration and its exactly-once call-count tests remain for step 6.

| Check | Result | Evidence |
| --- | --- | --- |
| Strict debug/test/release builds | Pass | All three README build commands report `BUILD SUCCESSFUL`; no compiler/analyzer warnings |
| Full Monkey C suite | Pass | Printed summary: `PASSED (passed=38, failed=0, errors=0)`; 31 existing tests and seven haptics tests |
| Haptics automated coverage | Pass | Production settings logic suppresses both cues when vibration is disabled or DND is enabled, reevaluates settings after re-enablement, and handles absent DND; settings-read and vibration exceptions are nonfatal and allow later cues |
| Actual simulator vibration calls | Pass | Smoke test uses production capability/settings checks and vibration API; completion counters advance only after the API returns without an exception |
| Completion followed immediately by exit | Pass in simulator | Isolated fixture logs completion cue, successful vibration API return, immediate `System.exit()`, then `onStop()`; launcher returns 0 without a runtime error |
| Test/probe exclusion | Pass | Seven haptics test functions and four test helpers appear only in test symbol metadata; isolated probe app absent from every main-project artifact |
| Static checks | Pass | Whitespace checks pass |
| Physical vibration/exit | Not run | No physical Vivoactive 6 available; perceptibility, equal interval feel, final distinctness, and motor continuation through immediate exit remain open |
| Physical system settings | Not run | Normal, vibration-disabled, DND, and sleep behavior still need on-watch verification; simulator settings flags cannot establish firmware behavior |

The simulator probe observed `vibrateOn=true` and `doNotDisturb=false`. Automated
suppression tests supply fake settings to the production decision logic; they do
not establish firmware behavior. Interactive simulator settings changes remain
unverified. Run the full suite with vibration enabled and DND disabled for its
real API smoke check.

Local build/test logs and the isolated probe are ignored under
`build/verification/stage5/` and unavailable in a fresh checkout.

The isolated probe has its own manifest entry and Jungle source path, referencing
the production source directory. Its view's `onShow()` calls
`HapticsService.completionCue()` and immediately calls `System.exit()`; its
`onStop()` logs cleanup. A service subclass logs only after the real vibration
API returns. The fixture is outside normal source discovery and adds no wait,
completion screen, or live application integration.

Official API checks:

- [`Attention.vibrate`](https://developer.garmin.com/connect-iq/api-docs/Toybox/Attention.html#vibrate-instance_function)
  and [`VibeProfile`](https://developer.garmin.com/connect-iq/api-docs/Toybox/Attention/VibeProfile.html)
  support Vivoactive 6 at API 1.0.0; arrays allow one to eight profiles, duty
  cycle is 0–100%, and lengths are milliseconds. Both cues use one profile.
- [`System.getDeviceSettings`](https://developer.garmin.com/connect-iq/api-docs/Toybox/System.html#getDeviceSettings-instance_function)
  and [`vibrateOn`](https://developer.garmin.com/connect-iq/api-docs/Toybox/System/DeviceSettings.html#vibrateOn-var)
  require API 1.0.0;
  [`doNotDisturb`](https://developer.garmin.com/connect-iq/api-docs/Toybox/System/DeviceSettings.html#doNotDisturb-var)
  requires 2.1.0 and is capability-guarded. The service only reads these settings.
- [`System.exit`](https://developer.garmin.com/connect-iq/api-docs/Toybox/System.html#exit-instance_function)
  requires API 1.0.0 and is used only by the isolated probe in this step.

This step adds no production API requirement above manifest 3.2.0. The final
project-wide minimum-API audit remains open for the later integrations and step 8.
No known requirements contradiction was found. If hardware shows truncated
completion vibration or conflicting system-settings behavior, follow the
[plan's platform checks](implementation-plan.md#3-platform-pitfalls-and-open-checks)
before changing exit timing or accepting haptic behavior. Step 5 is not fully
verified until the physical checks pass.

## Step 6 — Inputs, periodic updates, and lifecycle cleanup (2026-10-29)

Step 6 implementation is complete; physical acceptance remains pending. Verified
with Connect IQ SDK/compiler 9.2.0 and the Vivoactive 6 simulator (API 6.0.3) in
Ubuntu 22.04 Distrobox. Build, suite, and simulator commands are the commands in
[README](../README.md#build). Screen/backlight policy remains for step 7.

The delegate integrates touch/Enter/Back input, 250 ms updates, and exactly-once
completion effects. Application cleanup stops and releases updates; each launch,
including a reported resume, creates a fresh READY session.

| Check | Result | Evidence |
| --- | --- | --- |
| Strict debug/test/release builds | Pass | All three README build commands report `BUILD SUCCESSFUL`; no compiler/analyzer warnings |
| Full Monkey C suite | Pass | Printed summary: `PASSED (passed=48, failed=0, errors=0)`; 38 existing and ten new controller/application tests |
| New automated coverage | Pass | Visible/hidden control hit testing, edges/outside taps, Enter, fractional pause/resume, delayed/duplicate callbacks, Stop/reset/restart, completion priority over touch/Enter/Back, exactly-once effects, callback-stop-haptic-exit order, READY/PAUSED/terminal callbacks, repeated/external cleanup, nonfatal haptics failure, and application stop/reported-resume freshness |
| Input-routing probe | Pass | Returning false from Select delivers exactly one coordinate tap or raw Enter (`KEY_ENTER=4`); standard Back reaches `onBack`. Inside and outside taps observed before binding final inputs |
| Production input/rendering | Pass | READY/outside tap, Start, advancing time/ring, frozen time/ring on Pause, Enter Resume, Stop from RUNNING and PAUSED, restart, and hardware Back/normal exit |
| Controller completion fixture | Pass | Production controller/view/services with test-only 8000/2000 ms configuration: three interval requests, one completion request, four real vibration API returns, callback stop before completion, immediate exit, then application cleanup; no runtime errors |
| Cleanup and relaunch | Pass for covered paths | Actual Back exits; fresh production launch shows READY. Automated app test calls repeated `onStop`, rejects stale input/callback effects, then starts with reported resume and obtains fresh READY |
| Additional real-duration production run | Unverified | Simulator launches stalled at the idle logo, so full real-duration regression remains for step 8 |
| Test/fixture exclusion | Pass | Debug/release symbol metadata excludes new tests/helpers; test metadata includes them. Both isolated probe apps are absent from every main-project artifact |
| Static checks and code review | Pass | Actual Git diff, new tests, and surrounding model/view/haptics reviewed; no unresolved actionable defects |
| Physical Vivoactive 6 | Not run | Hardware unavailable; real controls, ergonomics, screen readability, vibration settings/feel/survival through exit, and real system interruption/suspension/resume behavior remain open |

Local logs, final captures, and isolated fixtures are ignored under
`build/verification/stage6/` and unavailable in a fresh checkout. `tests-final.log`
contains the passing summary; `live.log` records the shortened completion trace.

Official platform checks:

- [`BehaviorDelegate`](https://developer.garmin.com/connect-iq/api-docs/Toybox/WatchUi/BehaviorDelegate.html)
  consumes raw input only when its behavior returns true. `onSelect` is API
  1.2.0; standard Back is API 1.0.0. The Vivoactive 6 simulator confirms the
  plan's Select-false/raw-tap/raw-Enter strategy.
- [`ClickEvent.getCoordinates`](https://developer.garmin.com/connect-iq/api-docs/Toybox/WatchUi/ClickEvent.html#getCoordinates-instance_function),
  [`KeyEvent.getKey`](https://developer.garmin.com/connect-iq/api-docs/Toybox/WatchUi/KeyEvent.html#getKey-instance_function),
  [`Timer.Timer.start/stop`](https://developer.garmin.com/connect-iq/api-docs/Toybox/Timer/Timer.html),
  [`AppBase.onStart/onStop`](https://developer.garmin.com/connect-iq/api-docs/Toybox/Application/AppBase.html),
  and [`System.exit`](https://developer.garmin.com/connect-iq/api-docs/Toybox/System.html#exit-instance_function)
  are API 1.0.0 facilities. Timer callbacks may be skipped, so elapsed time
  continues to come exclusively from the injected clock/model.

This integration introduces no API requirement above manifest 3.2.0; the final
minimum-API audit remains for step 8. Full simulator regression and physical
acceptance remain for steps 7–9.

## Step 7 — Screen behavior and ownership review (2026-10-29)

Step 7 implementation is complete; physical screen acceptance remains pending.
Verified with Connect IQ SDK/compiler 9.2.0 and the Vivoactive 6 simulator
(API 6.0.3) in Ubuntu 22.04 Distrobox. Commands follow the
[README build](../README.md#build), [unit-test](../README.md#unit-tests), and
[simulator](../README.md#simulator) instructions.

The delegate makes one Boolean backlight activation request on Start and Resume.
Capability checks and platform exceptions are contained at that boundary. There
is no periodic renewal, so Pause, Stop, Back, completion, and application cleanup
cannot leave future requests scheduled. Pause allows normal system timeout
rather than forcibly disabling the backlight. Hardware evidence is required by
the plan before adding coarse renewal; none is available.

| Check | Result | Evidence |
| --- | --- | --- |
| Strict debug/test/release builds | Pass | All three README build commands report `BUILD SUCCESSFUL`; no compiler/analyzer warnings |
| Full Monkey C suite | Pass | Printed summary: `PASSED (passed=52, failed=0, errors=0)`; 48 existing and four new tests |
| Screen policy and failure coverage | Pass | Start/Resume request counts; no requests on regular/delayed/stale callbacks, pause, stop, terminal input, Back, or repeated/external cleanup; unsupported API and thrown refusal preserve active time, pause/resume, completion priority, and exactly-once exit |
| Real SDK timer ownership | Pass | Forty Start/Pause/Resume/Stop cycles, followed by running-state cleanup, without timer exhaustion; weak references confirm delegate, view, and model are released after the helper returns |
| Simulator screen/lifecycle probe | Pass | Isolated 8000/2000 ms configuration with production controller/view/model/haptics; three real backlight calls return on Start, Resume, and restart; no requests during a 15-second pause; Stop returns READY; completion stops updates, exits, and invokes application cleanup without runtime errors |
| Additional production input smoke | Unverified | Production artifact renders READY, but synthetic mouse/Enter input did not produce reliable visible state transitions. Captures are not counted as an input pass; complete manual simulator regression remains for step 8 |
| Simulator memory observation | Recorded | Probe READY uses 14920 bytes, Stop/reset uses 14928 bytes; these snapshots alone do not establish a memory trend. Repeated timer release is established by the ownership test |
| Test/probe exclusion | Pass | All five new test/helper symbols are absent from debug/release metadata and present in test metadata; isolated screen probe is absent from every main-project artifact |
| Static checks and code review | Pass | Actual diff and surrounding application/model/view/haptics reviewed; whitespace checks pass; no unresolved actionable defects |
| Physical Vivoactive 6 | Not run | Hardware unavailable; wrist-down timeout, long pause/dimming, Resume, gesture/settings interaction, power modes, burn-in refusal, and real interruption/exit behavior remain open |

The simulator required the [documented Distrobox workaround](../README.md#simulator).

Ownership review: application and platform own the delegate; the delegate owns
the view, model, haptics, and active update timer. The view/model/haptics hold no
reference back to the delegate. The timer's bound callback points to the
delegate; stopping updates and clearing `_updateTimer` breaks that cycle even if
`Timer.stop()` retains its callback. Application cleanup clears its delegate
reference. The weak-reference test exercises these real SDK timer operations;
no additional ownership abstraction or production change is needed.

Official API checks:

- [`Attention.backlight`](https://developer.garmin.com/connect-iq/api-docs/Toybox/Attention.html#backlight-instance_function)
  lists Vivoactive 6 and supports Boolean activation at API 1.0.0. The request
  respects system timeout; gesture behavior and burn-in protection still apply.
  Float brightness requires 3.2.1 and is unused. The boundary catches
  `Lang.Exception`, including the platform's backlight protection exception,
  without naming a newer exception type or retrying during the running period.
- [`Timer.start/stop`](https://developer.garmin.com/connect-iq/api-docs/Toybox/Timer/Timer.html)
  are API 1.0.0. Timer exhaustion and reference retention are tested using real
  timers rather than inferred from mocks or undocumented callback-release behavior.

No production API requirement above manifest 3.2.0 is introduced. The final
minimum-API audit and complete real-duration simulator regression remain for
step 8. Step 7 is not fully verified until physical screen checks pass.

Local logs, captures, and the isolated probe are ignored under
`build/verification/stage7/` and unavailable in a fresh checkout. `tests.log`
contains the final passing summary; `screen-probe.log` contains the real API and
lifecycle trace. No probe is included in production source discovery.

## Step 8 — Complete simulator regression (2026-10-29)

Verified with SDK/compiler 9.2.0, OpenJDK 21.0.12.1, and the Vivoactive 6
simulator (API 6.0.3) in Ubuntu 22.04 Distrobox. Commands and prerequisites are
in [README](../README.md#build).

| Check | Result | Evidence |
| --- | --- | --- |
| Final Strict debug/test/release builds | Pass | `BUILD SUCCESSFUL`; no compiler/analyzer warnings |
| Final full test suite | Pass | 52 existing tests; `PASSED (passed=52, failed=0, errors=0)`. Covers domain boundaries/rollover, presentation, input, completion priority, cleanup, and platform failures. Launcher returned 1; the printed summary establishes success |
| Input and session controls | Pass | Touch centers/edges, 14 outside-control taps without action, upper-button Start/Pause/Resume, lower-button Back, long-pause freeze, Stop from RUNNING/PAUSED, and fresh READY launches; release controls/exit also checked |
| Two-minute session | Pass | Continuous progress and all stages; `0:01` visible near completion. Interval requests at 30001, 60000, and 90000 ms; completion once at 120000 ms. Four real vibration API returns; updates stop before completion vibration, then exit and cleanup |
| Completion/input boundary | Pass | Eight simulator cases: touch Pause/Stop and on-screen Enter/Back buttons at 119999 and 120000 ms. Before completion, Pause/Enter preserve PAUSED at `0:01`, Stop resets READY, and Back exits without a completion cue. At completion, all four inputs stop updates, emit one completion vibration, exit once, and invoke cleanup once; no extra interval cue or pause/reset transition |
| Repeated use and memory | Pass | Twelve touch Start/Pause/Resume/Stop cycles return to 15240 bytes at every reset; active snapshots 15336 bytes. Suite also verifies release after 40 real SDK timer cycles. Below the package's 786432-byte watch-app limit |
| Final drawable rendering | Pass | `WatchUi.Bitmap` icon size/placement checked in READY, RUNNING, PAUSED, and after Stop; Start/Pause/Back work without runtime errors. Displayed heap approximately 13.1–13.2 KB |
| Artifact and scope audit | Pass | 52 test functions and 11 helpers excluded from debug/release; probes excluded from all main artifacts. Strings/configuration centralized; permissions/barrels empty; no sound, settings, persistence, background service, or networking |
| Review and static checks | Pass | Actual diff and surrounding code reviewed; shell syntax and whitespace checks pass; no unresolved defects |

The full-session trace used an isolated diagnostic app with production components,
normal timing, real SDK calls, and added event/memory logging. Full-session,
repeated-use, release-input, and artifact checks preceded the final drawable
refactor. Builds, all tests, and rendering/input checks were rerun afterward;
the unchanged timing code's two-minute trace was not repeated.

The completion/input follow-up uses the final production model, view, delegate,
and haptics in an isolated probe. An injected clock advances through the three
interval boundaries to 119750 ms, then to 119999 or 120000 ms when a real simulator
input arrives, before forwarding it to the production handler. SDK timers,
vibration, and exit remain real. This deterministic exercise complements the
real-duration session above. Both Strict probe builds passed without warnings;
the full suite was rerun: `PASSED (passed=52, failed=0, errors=0)`.

API audit: production calls fit the manifest's API 3.2.0 compatibility range.
[`WatchUi.Bitmap`](https://developer.garmin.com/connect-iq/api-docs/Toybox/WatchUi/Bitmap.html)
resource-ID construction, dimensions, drawing, and inherited
[`setLocation()`](https://developer.garmin.com/connect-iq/api-docs/Toybox/WatchUi/Drawable.html#setLocation-instance_function)
are API 1.0.0 operations; the platform handles the underlying bitmap type.
Other API checks are recorded in steps 4–7. Testing on the API 6.0.3 simulator
does not certify older devices.

Outstanding acceptance and environment limits:

- Hardware was unavailable. All [physical acceptance checks](implementation-plan.md#7-manual-acceptance-matrix)
  remain open, particularly completion vibration surviving exit and system haptic restrictions.
- Automated tests cover DND/vibration suppression and backlight refusal.
  Interactive DND/sleep toggles were not tested; no actual burn-in refusal was
  reproduced. The Simulation menu exposes no watch-app suspension action;
  stop/resume handling is covered by automated tests.
- Stalled simulator launches required restarting with the
  [README Distrobox workaround](../README.md#simulator). Hardware-input checks
  used on-screen buttons because injected keyboard Return was unreliable.

Local evidence is ignored under `build/verification/stage8/` and unavailable in a
fresh checkout: `regression-final.log`, `trace-full-*.png`, `trace-paused*.png`,
`release-*.png`, and `exclusion.log`. Final builds, `tests.log`, and drawable
captures are in its `bitmap/` subdirectory.
Completion/input probe sources, driver, eight case logs/captures, build logs,
`at-summary.log`, `before-summary.log`, and the rerun `tests.log` are in
`completion-input/`. Each case needed a fresh simulator and a wait for device
layout before input; probe symbols are absent from all main-project artifacts.

## Step 9 — Physical Vivoactive 6 acceptance (2026-11-03)

Hardware was connected to the Ubuntu host for transfer. The user reported no
previous installation of Toothbrush Timer. Observations below distinguish host
checks from user-reported physical results. Step 9 is complete for the tested
firmware/settings and scenarios, with verification limits listed at handoff.

### Artifact and environment

- Source revision: `bc52569b65dde6ec85b9519ba41547e3f4a1c133`; working tree clean
  before preparation. Documentation changes follow the build; production source
  is unchanged.
- Official SDK/compiler: 9.2.0; OpenJDK 21.0.12.1.
- Artifact: `build/ToothbrushTimer-release.prg`, release build for `vivoactive6`,
  17,276 bytes.
- SHA-256: `149b311586fad419f283f46650e5f117c0a84998058ea7bd4be61785542afdef`.
- Device description read from `GarminDevice.xml`: `vívoactive 6`.
  Raw `SoftwareVersion`: `1832`; user confirmed on-watch firmware **18.32**.
- User-reported display timeout: **8 seconds**; always-on display: **off**.
  Gesture wake restores the view in normal use; the gesture setting itself was
  not separately reported.
- User confirmed the baseline requested for the full session: vibration on;
  DND, sleep mode, and battery saver off; display settings unchanged.

### Results

| Check | Result | Evidence / remaining work |
| --- | --- | --- |
| Release build | Pass | `bash scripts/build.sh release`: `BUILD SUCCESSFUL`, no compiler/analyzer warnings |
| Sideload transfer | Pass | GIO MTP copy into `Internal Storage/GARMIN/Apps/ToothbrushTimer-release.prg`; read-back SHA-256 matches local artifact |
| App discovery and fresh launch | Pass (user reported) | App appears in the list; expected initial screen is visible with no errors or readability problems. Idle screen dims, then blanks; touch restores the app view |
| Full session, timing, progress, haptics, and automatic exit | Pass (user reported) | Three similar short cues and expected countdown/ring/stages; final cue at expected time, distinct and without cutoff; exit to app list, then quickly to watch face; no sound or errors. Individual stopwatch timestamps were not supplied |
| Long pause/resume | Pass (user reported) | Fresh launch at `2:00`; paused at `1:35` remaining for 60 seconds; time/ring/stage frozen, Resume label shown, no paused cues; first cue about 5 seconds after Resume; display, remaining cues, completion, and exit as expected; no errors |
| Stop/restart | Pass (user reported) | Stop resets correctly from RUNNING and PAUSED; restarted session's first cue around 30 seconds; no leftover cues during the requested 35-second wait after Stop; no errors |
| Touch ergonomics and outside-control taps | Pass (user reported) | Controls comfortable and easy to distinguish; taps on the countdown/icon outside controls ignored. Physical edge taps not separately reported; simulator geometry coverage is recorded in step 8 |
| Hardware controls | Pass (user reported) | Short upper-button presses Start/Pause/Resume, exactly one action per press; lower-button Back exits from RUNNING, PAUSED, and READY; no unexpected behavior |
| Active display with baseline settings | Pass (user reported, system limits apply) | Dims after about 10–12 seconds; stays visible when horizontal, blanks when turned away, normally wakes when turned toward viewing position; countdown and completion remain correct |
| DND suppression | Pass (user reported) | Run A: no interval or completion vibrations with DND on; countdown and automatic exit correct; no errors |
| Vibration switches | Pass (user reported; switch behavior established) | With DND off: System off / Alert on permits cues (B); both off suppress all cues and still complete/exit (C); System on / Alert off suppresses the 30-second cue (D). Alert vibration controls app cues in these tested combinations |
| Haptic recovery after settings restoration | Pass (user reported) | Run E: both vibration switches on, DND off; cue returns around 30 seconds; no errors |
| Sleep mode | Pass (user reported, tested settings) | Alert vibration on; usual DND switch off, separate sleep DND setting not found. Cues, countdown, and automatic exit work; display dims and does not wake on gestures; no errors |
| Battery saver | Pass (user reported, existing configuration) | App launches; cues, countdown, and automatic exit work. Display slightly darker, no gesture wake; no errors or restrictions reported. Detailed saver options not supplied |
| Platform protection limits | Not induced | No actual burn-in refusal reproduced; automated backlight-refusal coverage is recorded in steps 7–8. No crash observed in baseline, long-pause, sleep, or saver sessions |
| Back cancellation and fresh relaunch | Pass (user reported) | Back exits while running; no cues during the requested 35-second wait outside the app; relaunch shows fresh `2:00`. Back also exits from PAUSED and READY |
| System alarm interruption | Pass (user reported, observed scenario) | Alarm appeared during the session; after dismissal the user reported normal screen/timer/state and continued normal operation. Exact timer values and lifecycle callbacks were not supplied |
| Input near completion | Pass (user reported, pre-completion pause) | Upper-button press at `0:01` paused; no duplicate final cues, stuck screen, or errors reported; fresh relaunch works at `2:00`. Actual simultaneous completion/input on hardware was not established |
| Repeated use | Pass (user reported) | Guided release-build checks include two completed sessions and three Stop/reset cycles; no errors or leftover cues reported across these checks |

First physical observation (user reported): after the requested untouched
10-second launch check, the watch dimmed and then showed a blank screen;
touching the screen restored the application view. The user confirmed the
expected initial screen and reported no errors or readability problems.
No Start action was requested in this check. This established idle display
behavior only; the subsequent full session checked the active countdown.
Normal idle dimming is consistent with the design's Start/Resume backlight
policy and does not by itself establish an active-display problem.

Full-session observation (user reported): firmware 18.32, timeout 8 seconds,
always-on display off, and the requested baseline settings confirmed. The user
confirmed the three short cues' approximate timing and equal feel, expected
countdown/ring/stages, and expected completion timing/distinctness without a
cutoff. No individual measured timestamps were supplied, so this is qualitative
acceptance rather than a quantitative latency/drift measurement. Automatic exit
returned to the application list, then very quickly to the main watch screen.
No sound or errors were reported. This closes the baseline physical check that
the completion vibration survives immediate exit for this firmware/settings.

During the active session, the screen dimmed after about 10–12 seconds. It did
not blank while horizontal, blanked when turned away, and normally restored the
view on a viewing gesture. This is consistent with the best-effort display
policy in requirements §10/design §11:
[Garmin's backlight API](https://developer.garmin.com/connect-iq/api-docs/Toybox/Attention.html#backlight-instance_function)
respects device timeout/settings, and the
[Vivoactive 6 manual](https://www8.garmin.com/manuals/webhelp/GUID-8C2C402F-55AC-431F-9CF2-1442B89CE149/EN-US/vivoactive_6_OM_EN-US.pdf)
documents timeout and gesture wake. No production change or backlight renewal
is indicated by these observations alone. The subsequent long-pause check
reports expected paused/resumed display behavior. Subsequent sleep and battery
saver sessions below exercise additional system restrictions; actual burn-in
refusal was not induced.

Long-pause observation (user reported): a fresh launch showed `2:00`. The user
confirmed pausing at `1:35` remaining for `1:00` of wall-clock time; time, ring,
and stage remained frozen for those 60 seconds. Resume was displayed, and no
cues occurred while paused. Display behavior while
paused and after resuming, remaining cues, completion, and automatic exit were
reported as expected; no errors were reported. The subsequent Stop/touch check
confirmed comfortable, distinguishable controls.

The first cue was reported about 5 seconds after Resume, as expected from
`1:35` remaining. The user's correction clarified that the initially supplied
`1:00` referred to the pause duration. The timing discrepancy is resolved;
the long-pause/resume scenario passes without a production change.

Stop/restart and touch observation (user reported): Stop reset the session
correctly both while running after the first interval cue and while paused.
The next restarted session's first cue occurred around 30 seconds after Start.
After stopping that session, no leftover cues occurred during the requested
35-second wait. Taps on the countdown/icon outside controls were ignored.
Controls were comfortable and easy to distinguish; no errors were reported.
These repeated complete/interrupted release sessions also satisfy the baseline
physical repeated-use check. The subsequent hardware check confirmed button
input and cleanup on Back; the final alarm check exercised a system interruption.

Hardware-controls observation (user reported): short upper-button presses
correctly started, paused, and resumed the session, with one action per press.
The lower button exited while running, while paused, and from the initial
screen. No cues occurred during the requested 35-second wait after the running
exit; reopening showed a fresh `2:00` session. No unexpected behavior was
reported. This confirms normal Back cancellation and fresh relaunch on physical
hardware; it does not establish behavior under a separate system interruption
or an input at the completion boundary. The final batch below separately
exercised an alarm and input near completion.

Haptic-settings observation (user reported): Run A produced no interval or
completion vibrations with DND on, and countdown/automatic exit worked. In
Run B, DND was off and the user disabled **System vibration**, leaving **Alert
vibration** on. Vibrations still occurred; the report does not separately
identify which interval/completion cues occurred. Countdown and automatic exit
worked, with no other errors. The user deferred the restoration/recovery check
because of this unexpected result.

The original Run B instruction assumed that System vibration alone disabled
app cues. This mapping was not established. The
[watch manual](https://www8.garmin.com/manuals/webhelp/GUID-8C2C402F-55AC-431F-9CF2-1442B89CE149/EN-US/GUID-F262E210-94DD-4A28-90ED-07830979D19B.html)
lists System and Alert vibration separately, while
[`DeviceSettings.vibrateOn`](https://developer.garmin.com/connect-iq/api-docs/Toybox/System/DeviceSettings.html#vibrateOn-var)
only describes a Boolean vibration-enabled setting, without specifying the
mapping to these two controls on Vivoactive 6. The production haptics service
checks this flag and DND for every cue. Simulator tests using a false flag do
not establish the physical switches' mapping. The subsequent C–E checks below
resolve Run B's unexpected result as an incorrect test expectation about the
System switch. No production or normative-document change is required by these
observations.

Independent-switch and recovery observations (user reported), with DND, sleep,
and battery saver off:

| Run | System vibration | Alert vibration | Observation |
| --- | --- | --- | --- |
| B | Off | On | Vibrations occurred; countdown and automatic exit worked |
| C | Off | Off | No interval or completion vibrations through the full session; countdown and automatic exit worked |
| D | On | Off | No vibration around 30 seconds in the requested 35-second run |
| E | On | On | Vibration around 30 seconds returned in the requested 35-second run |

No errors were reported for C–E. These physical observations establish that
Alert vibration controls the app's cues in the tested combinations on firmware
18.32; System vibration off alone does not suppress them. This satisfies the
physical vibration-disable/recovery check for the effective alert setting.
The watch's actual `vibrateOn` value was not directly sampled, so the results
do not establish whether suppression occurs in the settings flag, inside the
vibration API, or both. Sleep-specific behavior was subsequently checked below.

Sleep-mode observation (user reported): Alert vibration was on. A separate
sleep-specific DND setting was not found; the usual DND switch was off. Cues,
countdown, and automatic exit worked. The display dimmed and did not respond
to wrist gestures. No errors or other restrictions were reported. This accepts
the observed sleep configuration without assuming that sleep alone silences
alerts or that a separate sleep DND state was directly verified.

Battery-saver observation (user reported): the app launched under the requested
existing saver configuration, with sleep off and baseline haptics requested.
Cues, countdown, and automatic exit worked. The display was slightly darker than
usual and did not respond to wrist gestures. No errors or other restrictions
were reported. Individual saver options were not supplied, so acceptance is
limited to the configuration tested. These observations are consistent with
respecting system display restrictions; no backlight-policy change is indicated.

Final interruption/completion-input observations (user reported): a watch alarm
appeared during the session. After dismissal, the screen, timer value, and
running/paused/reset state were described as normal/as expected, and subsequent
session behavior was normal. The user did not supply exact before/after timer
values or distinguish an overlay from actual platform suspension. Pressing the
upper button at `0:01` paused the session. No duplicate final cues, stuck screen,
or errors were reported. Fresh relaunch at `2:00` worked as usual. This accepts
the observed alarm scenario and pre-completion input path without claiming that
actual simultaneous completion/input or forced suspension occurred on hardware.

The watch was already mounted through the desktop's GVfs MTP backend. Inherited
`GIO_MODULE_DIR` pointed to Snap-specific modules and prevented system `gio`
from accessing MTP. Scoping `env -u GIO_MODULE_DIR -u GIO_EXTRA_MODULES` to the
transfer command resolved this. Python exclusive-create and ordinary filesystem
copy attempts returned `Operation not supported` and created no destination
file; the subsequent GIO copy succeeded. No global environment changes or
additional packages were needed. The reusable host procedure is in
[README](../README.md#physical-device-installation-and-acceptance).

### Handoff and verification limits

- Implementation: steps 1–8 remain unchanged; step 9 required release installation,
  guided physical verification, and documentation only. No production defect or
  unresolved contradiction with requirements/design was identified. No code
  correction iterations or new/modified automated tests were needed.
- Build and static checks: the release build passed without warnings; transfer
  matched the artifact hash above; final documentation whitespace, all 13 README
  Bash examples' syntax, and 50 local Markdown link targets/anchors passed.
  Syntax checking does not execute the examples. The artifact hash was rechecked
  at handoff.
- Automated/simulator evidence: step 8 records Strict debug/test/release builds,
  52 passing tests (`passed=52, failed=0, errors=0`), and simulator regression.
  These were not rerun in step 9 because production source is unchanged.
- Physical acceptance: all manual scenario rows have user-reported coverage on
  firmware 18.32 and the settings described above. Required guided runs are
  complete; no further manual run is requested for this handoff.
- Limits: exact stopwatch timestamps were not supplied; timing observations are
  qualitative. The alarm test did not instrument lifecycle callbacks or prove
  a forced suspend/terminate/resume sequence. The hardware completion-input test
  exercised Pause before completion, not a proven simultaneous event; the eight
  deterministic simulator cases and automated tests remain the evidence for
  exact completion priority. No actual burn-in refusal was induced. Physical
  edge taps and detailed battery-saver options were not separately reported.
  These unobserved cases are not claimed as physically verified. Other devices,
  firmware versions, and settings combinations require separate verification.
- Review: the final documentation diff was reviewed against requirements/design
  and reported observations. The System/Alert switch discrepancy was resolved
  by independent physical checks and documented; no application fix was needed.
  One documentation correction removed an unmatched apostrophe from the new
  MTP URI prerequisite diagnostic; Bash syntax and local link checks passed
  afterward.

Proposed stable commands for AGENTS.md are `bash scripts/build.sh release`,
`sha256sum build/ToothbrushTimer-release.prg`, and `git diff --check`, with README
remaining authoritative for prerequisites and transfer steps. AGENTS.md already
requires using README commands, so no duplicate command block or root-instruction
edit is needed. The MTP recipe stays in README with a caller-supplied watch URI;
no host mount path, USB identifier, SDK path, or signing key is embedded.
