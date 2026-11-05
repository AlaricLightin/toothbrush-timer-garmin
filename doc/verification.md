# Verification Baseline

The MVP was accepted on 2026-11-03 for the tested Vivoactive 6 firmware 18.32,
settings, and scenarios below. This is a condensed historical record, not a new
verification run or certification of later changes. Production source was
unchanged between the final simulator regression and physical acceptance.

Use [testing.md](testing.md) for regression coverage and recording future results;
use [README](../README.md) and [development.md](development.md) for commands.
The [archived plan](archive/implementation-plan.md) preserves the completed sequence.

Focused physical checks of the subsequent display and completion changes passed
on 2026-11-04; see [results and remaining coverage](#focused-physical-verification-2026-11-04).
Implementation entries below retain the evidence and pending checks from their
original verification runs.

## Implementation history

| Date | Completed scope | Recorded evidence |
| --- | --- | --- |
| 2026-10-18 | Baseline build | Strict debug/release builds; paths containing spaces; prerequisite/failure diagnostics; signing-key creation/non-overwrite; source discovery; starter rendering |
| 2026-10-20 | Configuration, clock, test harness | 8 passing tests; deliberately failing probe confirmed summary reporting; focused run; test-code exclusion |
| 2026-10-21 | Timer model, then UI/layout | 27, then 31 passing tests; boundary/rollover coverage; state previews; dynamic six-stage formatting; shared hit geometry |
| 2026-10-28–29 | Haptics | 38 passing tests; settings suppression/nonfatal failures; real simulator API calls and completion/exit probe |
| 2026-10-29 | Input/lifecycle, then backlight/ownership | 48, then 52 passing tests; input routing; exactly-once effects; fresh launch after cleanup; 40 real SDK timer cycles with weak-reference release checks |

All final builds at these increments passed without compiler/analyzer warnings.
Temporary fixtures and test helpers were excluded from production artifacts.
Earlier pending hardware statements were resolved to the extent documented in
physical acceptance and its limits below.

Recorded environment: Ubuntu 24.04.5 LTS host, Bash, OpenJDK 21.0.12.1;
Ubuntu 22.04.5 LTS Distrobox simulator under X11/XWayland; Connect IQ SDK 9.2.0,
build `2026-06-09-92a1605b2`. Vivoactive 6 device package
`eddc2840754f6d29c6c9a3ede43befdaadd25a09` advertised API 6.0.3.
These versions are evidence, not universal prerequisites.

## Automated and simulator regression (2026-10-29)

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

The API audit recorded production calls within manifest API 3.2.0's compatibility
range. The final `WatchUi.Bitmap` drawable uses resource-ID construction,
dimensions, drawing, and inherited `setLocation()`; the platform handles the
underlying bitmap type. Boolean backlight activation avoids the newer Float
brightness API; the exception boundary does not name a newer protection type.
Testing on the API 6.0.3 simulator does not certify older devices. API/target
changes require a fresh audit under AGENTS.md.

Simulator limits: interactive DND/sleep toggles and actual burn-in refusal were
not exercised. The Simulation menu exposed no watch-app suspension action;
automated tests covered stop/reported-resume handling. Stalled launches needed
the [Distrobox workaround](development.md#simulator-troubleshooting). On-screen
hardware buttons were used because injected keyboard Return was unreliable.

## Physical acceptance (2026-11-03)

Host checks verified the release build and transfer. Physical behavior was
reported by the user; it was not directly observed by the development agent.

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
| Touch ergonomics and outside-control taps | Pass (user reported) | Controls comfortable and easy to distinguish; taps on the countdown/icon outside controls ignored. Physical edge taps not separately reported; simulator geometry coverage is recorded above |
| Hardware controls | Pass (user reported) | Short upper-button presses Start/Pause/Resume, exactly one action per press; lower-button Back exits from RUNNING, PAUSED, and READY; no unexpected behavior |
| Active display with baseline settings | Pass (user reported, system limits apply) | Dims after about 10–12 seconds; stays visible when horizontal, blanks when turned away, normally wakes when turned toward viewing position; countdown and completion remain correct |
| DND suppression | Pass (user reported) | Run A: no interval or completion vibrations with DND on; countdown and automatic exit correct; no errors |
| Vibration switches | Pass (user reported; switch behavior established) | With DND off: System off / Alert on permits cues (B); both off suppress all cues and still complete/exit (C); System on / Alert off suppresses the 30-second cue (D). Alert vibration controls app cues in these tested combinations |
| Haptic recovery after settings restoration | Pass (user reported) | Run E: both vibration switches on, DND off; cue returns around 30 seconds; no errors |
| Sleep mode | Pass (user reported, tested settings) | Alert vibration on; usual DND switch off, separate sleep DND setting not found. Cues, countdown, and automatic exit work; display dims and does not wake on gestures; no errors |
| Battery saver | Pass (user reported, existing configuration) | App launches; cues, countdown, and automatic exit work. Display slightly darker, no gesture wake; no errors or restrictions reported. Detailed saver options not supplied |
| Platform protection limits | Not induced | No actual burn-in refusal reproduced; automated backlight-refusal coverage is included in the baseline suite. No crash observed in baseline, long-pause, sleep, or saver sessions |
| Back cancellation and fresh relaunch | Pass (user reported) | Back exits while running; no cues during the requested 35-second wait outside the app; relaunch shows fresh `2:00`. Back also exits from PAUSED and READY |
| System alarm interruption | Pass (user reported, observed scenario) | Alarm appeared during the session; after dismissal the user reported normal screen/timer/state and continued normal operation. Exact timer values and lifecycle callbacks were not supplied |
| Input near completion | Pass (user reported, pre-completion pause) | Upper-button press at `0:01` paused; no duplicate final cues, stuck screen, or errors reported; fresh relaunch works at `2:00`. Actual simultaneous completion/input on hardware was not established |
| Repeated use | Pass (user reported) | Guided release-build checks include two completed sessions and three Stop/reset cycles; no errors or leftover cues reported across these checks |

### Vibration switch findings

With DND, sleep, and battery saver off:

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
vibration API, or both. Sleep-specific observations are recorded in the results table.

The initial assumption that System vibration alone disabled app cues was
incorrect. Independent-switch checks resolved it without a production or
requirements/design change. The observed completion cue survived immediate exit;
no exit delay was introduced. Display observations did not establish a need for
backlight renewal.

### Acceptance scope and limits

- All guided manual scenario rows had user-reported coverage; no further manual
  run was requested at MVP handoff. No production defect or unresolved conflict
  with requirements/design was identified.
- Timing observations were qualitative: individual stopwatch timestamps and
  quantitative latency/drift measurements were not supplied.
- The alarm check did not instrument callbacks or establish forced suspension,
  termination, or resume. The hardware input at `0:01` tested pre-completion
  Pause; exact completion/input priority is supported by automated tests and
  eight deterministic simulator cases, not simultaneous hardware input.
- Actual burn-in refusal was not induced. Physical edge taps, detailed saver
  options, and a separate sleep-specific DND setting were not established.
  Sleep and saver observations apply only to the configurations reported.
- Other devices, firmware versions, and settings combinations require separate
  verification. These unobserved cases are not claimed as physically verified.
- The 2026-11-03 release build passed without warnings and transfer read-back
  matched its hash. The 52-test suite and simulator regression were not rerun
  that day because production source was unchanged. Documentation whitespace,
  then-current Bash examples' syntax, and local Markdown links were checked;
  syntax checking did not execute the commands.

## System-only display implementation (2026-11-04)

The user requested system-only display control after observing occasional stronger
illumination; its cause was not established. The policy supersedes Start/Resume
backlight activation in archived step 7. Earlier results describe the old policy.

- Status: implementation complete; physical acceptance pending. This artifact
  still used the single long completion cue, before the three-pulse implementation below.
- Source: uncommitted changes on `f478f87456fce495c9c13fd31e419116824eeb7b`.
  Removed Start/Resume backlight handling from `ToothbrushTimerDelegate.mc`
  and obsolete fixtures/tests from `DelegateTests.mc`.
- Environment: Ubuntu Linux host, official Connect IQ SDK 9.2.0, installed
  Vivoactive 6 package, Strict checking; simulator in the existing Distrobox
  container. Native launch dependencies were missing (`libwebkit2gtk-4.0.so.37`
  and `libjavascriptcoregtk-4.0.so.18`); container/test access required approved
  execution outside the sandbox. Startup GTK diagnostics were not application errors.
- Builds: [README debug/release/test commands](../README.md#build) all reported
  `BUILD SUCCESSFUL`, with no compiler/analyzer warnings.
- Tests: the README full-suite `monkeydo` command printed
  `PASSED (passed=49, failed=0, errors=0)`. The launcher returned 1; success is
  established by the printed summary. The reduction from 52 is solely the three
  obsolete backlight tests. No new domain logic or test cases were needed.
- Simulator: fresh launch showed the icon, `2:00`, and Start. Touch Start and
  Pause worked; the paused time/ring/stage remained unchanged across a three-second
  observation at `1:57`. The upper hardware control resumed to `1:55` after two
  seconds. Touch Stop from both RUNNING and PAUSED restored READY at `2:00`.
  A subsequent uninterrupted session showed `1:29` / Stage 2, `0:58` / Stage 3,
  and `0:27` / Stage 4 with advancing progress, then automatically exited by
  the capture at 124 seconds. Cue counts/order remain covered by automated tests;
  this production run did not instrument vibration calls or establish motor feel.
  Reloading after automatic exit stalled in the simulator, as seen in earlier
  local verification tooling. After restarting the simulator, fresh launch
  showed READY at `2:00`; the upper hardware control started the session and the
  lower hardware Back control exited. Same-process reload after automatic exit
  was therefore not verified; application stop/resume reset coverage passed in
  the unit suite. No application code was changed for the simulator issue.
- Review: no actionable defects. Source/test search found no remaining
  backlight/brightness/keep-awake code or view-visibility lifecycle hooks.
  Independent timing, input, haptics, completion, lifecycle, and timer-ownership
  coverage was retained. Whitespace and local Markdown links passed checks.
- Physical checks not run: normal timeout/wake and brightness on Start/Resume,
  wake-touch/button delivery, full countdown/cues/exit with the display off,
  long pause/resume, sleep and battery saver, and real exit/lifecycle behavior.
  No physical watch was exercised in this change; historical acceptance does
  not verify these new artifacts. Simulator observations cannot certify these
  display and hardware behaviors.
- Local evidence: ignored `build/verification/system-only-display/` contains
  build logs, `tests.log`, `app.log`, and simulator captures. Artifacts:

| Artifact | SHA-256 |
| --- | --- |
| Debug | `5da12c75c0c78c9375d5b634566fb6863ee245bfca7f7db11c04fb54c0ffb947` |
| Release | `f77a8a68f7f1e3f43c28be71db46a38e4fd355c3613eab52ff153a19f6315e80` |
| Test | `d029b7d4b4a2d15ed21611d3d4c8555cf3bc04350e3f0d6bfaa5b6979eee13e7` |

## Three-pulse completion implementation (2026-11-04)

The user requested three short completion vibrations in one command, replacing
the single long signal. Requirements and design were updated before implementation.

- Status: implementation complete; physical acceptance pending. Replaced the
  single long completion vibration in `HapticsService.mc` with three 170 ms
  pulses at 75% duty cycle and two 120 ms zero-duty pauses (750 ms total),
  submitted together in one call. These are initial tuning values; physical
  feel has not been established. Interval cues remain one 250 ms pulse at 100% duty cycle.
- Source: uncommitted changes on `54dea9bd0c1b4cf8347270ce891e32ef552fe28f`.
- API review: current official Garmin [vibration API](https://developer.garmin.com/connect-iq/api-docs/Toybox/Attention.html#vibrate-instance_function)
  documents sequential playback of up to eight profiles and zero-duty pauses;
  [VibeProfile](https://developer.garmin.com/connect-iq/api-docs/Toybox/Attention/VibeProfile.html)
  documents API 1.0.0 availability and Vivoactive 6 support. No API or manifest
  minimum change was needed; the existing minimum remains 3.2.0.
- Environment: same Ubuntu Linux / SDK 9.2.0 / Vivoactive 6 package / Strict /
  Distrobox setup and native-library limitations as the display verification above;
  simulator API 6.0.3. The simulator/test connection initially stalled without
  a summary; restarting the simulator and retrying produced the result below.
  Startup GTK diagnostics were not application errors.
- Builds: [README debug/release/test commands](../README.md#build) each printed
  `BUILD SUCCESSFUL` without compiler/analyzer warnings.
- Tests: README full-suite `monkeydo` command printed
  `PASSED (passed=49, failed=0, errors=0)`. This includes real simulator vibration
  API smoke calls, settings suppression/recovery, nonfatal haptic failures,
  completion priority/exactly-once handling, and timer ownership. Existing tests
  were retained unchanged; no vibration-profile unit tests were added, per
  AGENTS.md. The changed pattern is checked through simulator tracing instead.
- Simulator: the isolated trace app launched READY at `2:00`. Touch Start/Pause
  froze the display at `1:58`; captures two seconds apart were identical.
  The upper hardware control resumed, and touch Stop restored READY at `2:00`.
  A subsequent full default-duration session showed `1:29` / Stage 2, `0:59` /
  Stage 3, and `0:29` / Stage 4 with advancing progress. Trace recorded one
  interval call at elapsed 30001, 60000, and 90005 ms, each with the unchanged
  single-pulse profile. At 120000 ms, updates stopped, one completion call
  submitted five profiles in order `(75,170), (0,120), (75,170), (0,120),
  (75,170)` (duty %, duration ms), the real vibration API returned, and normal
  exit/cleanup followed immediately. No extra completion/interval requests or
  application runtime errors appeared. The capture at 123 seconds showed the
  simulator's idle logo. This confirms request submission and automatic exit,
  not physical pulse playback through exit.
- Review: no actionable defects or unresolved contradictions. Capability/settings
  checks, nonfatal failure handling, and immediate exit were preserved; no timers,
  waits, sound, or display-power calls were added.
- Physical checks not run: three distinct, perceptible pulses with all three
  surviving immediate exit; strength/pulse/pause tuning; interval contrast;
  suppression and recovery under Alert/System vibration, DND, sleep, and power
  settings; display-off countdown/cues/exit and real lifecycle behavior. No watch
  was exercised. Historical acceptance of a single long completion cue does
  not verify this pattern, and simulator traces cannot certify motor behavior.
- Local evidence: ignored `build/verification/three-pulse-completion/` contains
  build logs, `tests-retry.log`, simulator logs/captures, and an isolated trace
  app using identical copies of current production components. Only its app
  wiring and subclasses add tracing; it uses the production clock, default
  timing configuration, real vibration API, periodic timer, and exit mechanism.
  Artifacts:

| Artifact | SHA-256 |
| --- | --- |
| Debug | `e07cc660938345143ecf2a1ca1eb26a7b1f4cf31cf4a9f2586550b4326ad772d` |
| Release | `b9b975584d5bb0b70396b66c5ef4ba1d3f47acdb93c083c2b30970da5e3a8c3d` |
| Test | `6ae1ef9070aa35935bb2ecc08896cdabffaee59774d15f2b4883bb5710257755` |

## Documentation consolidation (2026-11-04)

Shortened change summaries, workflow policy duplication, and verification history;
product behavior and acceptance requirements are unchanged. Diff/consistency review,
`git diff --check`, and local Markdown file/anchor checks passed. Original acceptance
records, artifact hashes, and the archived plan were preserved. No application builds
or runtime checks were run for this documentation-only change; hardware acceptance
of the display and completion changes remains pending.

## Focused physical verification (2026-11-04)

Both subsequent changes passed the requested two-test physical check on Vivoactive 6.
Results were reported by the user, not directly observed by the development agent;
this was not a full regression or acceptance run.

- Installed release SHA-256 reported by the user:
  `b9b975584d5bb0b70396b66c5ef4ba1d3f47acdb93c083c2b30970da5e3a8c3d`.
  This matches the release artifact in the
  [three-pulse implementation record](#three-pulse-completion-implementation-2026-11-04),
  which also records its source, SDK, build, unit-test, and simulator evidence.
- Firmware: **18.32**. Display timeout: **8 seconds**. Always-on display: **off**.
  The protocol requested Alert vibration enabled and DND, sleep, and battery saver
  disabled; these switches and the exact brightness setting were not separately
  restated in the results.

| Check | Result | User-reported evidence |
| --- | --- | --- |
| Display-off full session | Pass | Display dimmed/turned off; interval cues occurred at roughly 30/60/90 seconds; completion time was `2:00` |
| Three-pulse completion through exit | Pass | Three distinct final pulses, including a complete third pulse; automatic exit to the app list |
| Brightness, sound, and errors | Pass | No unexpected brightness, sound, or errors in the full session; Start/Resume brightness behaved as expected |
| Idle timeout and wake | Pass | Idle timeout behaved as expected; wake was by gesture |
| Pause/resume | Pass | Remaining time stayed at `1:35` across the 45-second pause; first cue after Resume behaved as expected |
| Stop reset | Pass | Stop returned the display to `2:00` |

Remaining coverage: sleep and battery saver; DND and vibration-switch suppression
and recovery with this artifact; touch/button wake delivery; broader lifecycle,
hardware-control, and repeated-use regression. Detailed pulse-strength/spacing
tuning and an explicit comparison with interval-cue feel were not separately
reported. No failures were reported in the focused checks; earlier acceptance
does not establish these untested cases for this artifact or other firmware/settings.

This follow-up changes documentation only. No new application build, unit-test,
or simulator run was performed when recording the user-reported results.

## UI design documentation (2026-11-05)

Updated requirements and technical design, and added [UI design](design/ui-design.md)
for the approved segmented-ring layouts, semantic palette, separate artwork, and
configured COMPLETED presentation before exit. The initial documentation pass
inspected all five reference PNGs; their approximate progress does not override
elapsed-time calculations. README distinguishes the current implementation from
the approved design, the plan tracks pending work, and the regression checklist
describes required coverage.

User-approved follow-ups clarified immediate Back/system-exit priority without
new completion effects or waiting for haptics, the centrally defined delay,
completion priority over Pause/Stop, and mandatory session disposal. Removed the
worked progress example, grouped timer presentation requirements, updated section
references, and consolidated repeated lifecycle rules, architectural exclusions,
test notes, and these same-day documentation records.

Documentation consistency/diff review, `git diff --check`, and local Markdown
file/anchor and whitespace checks passed for the consolidated working-tree docs.
Application source, tests, and runtime assets are unchanged; no builds, unit tests,
simulator sessions, or hardware checks were run. Prior runtime evidence remains
historical and does not establish acceptance of the new design.

Implementation and production artwork remain outstanding, followed by the
Vivoactive 6 build, simulator checks, and physical acceptance in
[testing.md](testing.md).

## Evidence availability

Logs, captures, and isolated probes were local ignored artifacts under
`build/verification/`, unavailable in a fresh checkout. Step directories
`stage2/` through `stage8/` contain the historical checks where retained.
The final simulator evidence includes `stage8/regression-final.log`,
`stage8/bitmap/tests.log`, and the eight case logs/probe under
`stage8/completion-input/`. This document preserves the reported outcomes;
rerun affected checks for future changes.
