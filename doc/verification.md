# Verification Baseline

This records application checks for specific revisions and artifacts. Use [testing.md](testing.md) for coverage and recording rules. The 2026-11-08 baseline below remains historical evidence, not certification of later changes. Earlier implementation sequences and superseded evidence are available in Git history.

## Stop interval-cue suppression (2026-11-10)

Implemented the approved [session behavior](product-requirements.md#session-behavior) and [input design](technical-design.md#input-and-lifecycle): `BrushingTimer.handleAction(STOP)` returns NONE after resetting, discarding newly detected interval cues before completion. Pause cue delivery and completion priority are preserved. Source: working tree over `fcda7e9d83bd2a6b3841ec8999d7ef9d2652f166`, changing `source/BrushingTimer.mc`, `tests/BrushingTimerTests.mc`, and `tests/DelegateTests.mc` alongside the approved documentation update.

Checks ran from the repository root in Bash on Ubuntu 24.04.5 LTS, with OpenJDK 21.0.12.1, official SDK/compiler 9.2.0, the Vivoactive 6 device package, caller-supplied `CIQ_SDK`/`CIQ_KEY`, and the existing Distrobox simulator using the documented X11 workaround. No minimum API or device target changed.

| Check | Result |
| --- | --- |
| Builds | README debug, test, and release commands each printed `BUILD SUCCESSFUL`, with Strict checking and no compiler/analyzer warnings. |
| Full unit suite | README `monkeydo` command printed `Ran 62 tests` and `PASSED (passed=62, failed=0, errors=0)`. Launcher status was 1, as documented. New coverage includes Stop before/at/after all interval boundaries, processed/unprocessed cues, both clock wrap edges, overdue intervals, no stale cue in READY, and normal restart cues. Existing Pause, completion priority, delay, cancellation, failure, and lifecycle tests passed. |
| Simulator touch integration | Three isolated probes copied current production components, injected a clock held at 29800 ms, and advanced it only when the next RUNNING touch was dispatched. At 30000 ms, Stop reset to READY with no interval/completion/vibration request; Pause requested one interval cue and one single-entry vibration call. At 120000 ms, Stop yielded to completion, one five-entry vibration call, and one automatic exit after the 3000 ms delay. All probe builds passed without compiler/analyzer warnings; all three launches exited cleanly. READY rendering after Stop was visually inspected. |
| Review and static checks | Production diff and affected tests reviewed against the approved policy; no unresolved implementation defects found. `git diff --check`, local Markdown links/anchors, and code-fence balance passed. |

| Artifact | SHA-256 |
| --- | --- |
| Debug | `c9625895a6267c3c5e23822aaa6c392836fb8f3b730e3936d82691e5d1511e7b` |
| Test | `5591cc3665c549f42a7d9acf093300d2568b6ca1c97947ea5a65ed1669c668c9` |
| Release | `674e7b292515011b518aab215b8d77c736d5e77affaf68706b4a2f711f20e32d` |

Implementation and available automated/simulator verification are complete. Physical Vivoactive 6 acceptance for this release remains pending: check Stop near interval boundaries, normal cues after restart, retained Pause cue behavior, and completion priority. A previously submitted vibration may still be felt after Stop; this does not establish a new request from Stop. Historical physical results below apply to the older release only. Probe sources, driver, logs, and captures are local ignored artifacts under `build/verification/stop-cue-suppression/`, unavailable in a fresh checkout.

## Artifact and environment (2026-11-08 baseline)

- Integrated regression: unchanged production code over `5f6f639`. Physical preparation: clean source revision `8cd11fa04b5ce3f5d01eec5e4d7c12286ad378e0`, with the same release hash.
- Official Connect IQ SDK/compiler 9.2.0 (`2026-06-09-92a1605b2`), Strict checking; Vivoactive 6 package `eddc2840754f6d29c6c9a3ede43befdaadd25a09`, simulator API 6.0.3. Manifest minimum API 3.2.0; no other device was built/run.
- Ubuntu 24.04.5 LTS host, Bash, OpenJDK 21.0.12.1; Ubuntu 22.04 Distrobox simulator under X11/XWayland. These identify tested environments, not universal prerequisites.
- Physical Vivoactive 6 firmware **18.32**. Baseline: Alert vibration on; DND, sleep, and battery saver off; timeout 8 seconds, always-on display off, gesture wake on, low brightness.
- Physical installation and observations were user-reported from another PC. The supplied release hash matched; watch-file read-back was not reported.

| Artifact | SHA-256 |
| --- | --- |
| Debug | `1c7afd91b5ec70b4ef0dc3853647623b4c09ffe0f6934832ade3a2bbbbc09166` |
| Test | `d12b15d7404dbd9e7f1114b757215a33cc8d6a78113180423f214cf7a30d148f` |
| Release (25,948 bytes) | `af116369bdf09147de8f46fc29478031682c284458a728aeafb228cac11081dd` |

## Automated and simulator results (2026-11-08 baseline)

| Check | Recorded result |
| --- | --- |
| Strict debug/test/release builds | All printed `BUILD SUCCESSFUL`, without compiler/analyzer warnings. Release build repeated during physical preparation; tests/simulator were not repeated then because source/artifact were unchanged. |
| Unit tests | `Ran 60 tests`; `PASSED (passed=60, failed=0, errors=0)`. Includes boundaries/rollover, geometry/input, scheduling/failure/cancellation, lifecycle, and weak-reference release after 40 SDK timer cycles in each ownership mode. Launcher status was 1; the summary establishes the pass. |
| Rendering and input | Production debug/release launch and control smoke checks passed; compiled launcher bitmap loaded/rendered. Full session showed correct states, segments, pause colors, completion message, and inactive completed controls. |
| Full-duration diagnostic session | Unchanged production components with real SDK clock/timers/vibration/exit: interval requests at 30001/60198/90198 ms active time, completion about 198 ms late after a 6012 ms pause; exactly three interval calls and one five-entry completion call. One exit after a 3002 ms delay. |
| Completion/input boundaries | Eight injected-clock simulator cases with real input passed at 119999/120000 ms. Pause/Stop/primary action yielded to completion when due; Back bypassed synchronization/cue/presentation. Back during COMPLETED cancelled the one-shot without a later exit callback. |
| Lifecycle | Simulator Kill App in RUNNING and COMPLETED invoked cleanup and cancelled pending work; relaunch was fresh READY. Actual suspension/reported-resume delivery was not exercised; automated tests cover reported resume and repeated cleanup. |
| Repeated use | Four observed control cycles returned to 17112 bytes at reset (active 17208–17216). Unexpected Back interrupted a longer automation attempt; subsequent cycles were not counted. |
| Artifact/API audit | Test functions/helpers and probes excluded from debug/release; centralized timing/resources, one SDK timer, empty permissions/barrels, no excluded platform features. Used APIs fit the retained 3.2.0 minimum; other devices remain unverified. |

Initial stalled/premature launches were retried after simulator restart/readiness and are not passes. Exhaustive simulator touch-edge/swipe delivery and interactive DND/sleep toggles were not rerun; automated geometry and suppression tests passed.

## Physical results (2026-11-08 baseline)

All results below are **user-reported** for the identified release and configurations. No defects or tuning needs were reported; acceptance is complete for this scope.

| Check | Recorded result and scope |
| --- | --- |
| Launcher, states, controls | Readable/unclipped artwork and all four layouts; wrist touch targets comfortable; upper-button Start/Pause/Resume and lower-button exit worked once per press. Start-end and outside-control taps passed; exhaustive edges/corners were not tested. |
| Timing, pause, Stop | Full sessions had correct stages/cues; a 60-second pause preserved values with no cues; Stop from RUNNING/PAUSED reset immediately, with no stale cues. Repeated completion/control cycles showed no reported instability. |
| Completion | Three distinct final pulses finished; `Nice job!` with full segmented ring for about three seconds, then application-list exit. Primary input and former Stop-position touch did not restart or repeat effects. |
| Immediate exit and relaunch | Back in READY/RUNNING/PAUSED, at displayed `0:01`, and during COMPLETED reported immediate exit. Fresh relaunch remained READY without stale exit/cues. During COMPLETED, checked assertions establish the reported Back result; an additional free-text certainty question was unanswered. |
| Dimmed and black display | Separate sessions continued cues/completion without observed wake/brightness changes. Manual stopwatch cues at 0:29/0:59/1:29 and first completion pulse at 1:59 showed no accumulating offset at whole-second precision; app had exited when checked at 2:08. Exact black-screen exit time was not observed. |
| DND/vibration | DND suppressed cues without stopping timing/presentation/exit; disabling it restored cues. Independent System/Alert switch checks and recovery passed as detailed below. |
| Sleep and saver | Timing/cues/completion/exit continued in reported modes. Sleep gesture wake was unavailable; saver gesture wake could not be assessed because the display remained dimmed. Detailed options and numeric saver presentation duration were not established. |
| Input while black | Upper button woke and started READY; center/countdown touch woke RUNNING without an unintended action; lower button exited RUNNING. |
| Alarm overlay | Alarm at stopwatch 0:40 showed last countdown 1:20; after dismissal countdown was 1:10. Timing continued without reset/burst cues, then completed/exited normally. This establishes overlay continuity, not actual suspension. |

## Platform observations

- Firmware 18.32: with DND/sleep/saver off, **System vibration off / Alert on** allowed cues; **System on / Alert off** suppressed a full session's cues; both on restored them. Both off was not retested on this release (an older 2026-11-03 artifact had a passing suppression check). The actual `vibrateOn` flag was not sampled, so these observations do not locate suppression in a particular API layer.
- DND suppression leaves timing and exit functional. Sleep/saver settings can restrict visibility and gesture wake; never infer suspension from a dark display or overlay.
- Tested haptic values: interval 250 ms at 100% duty; completion three 170 ms pulses at 75% with two 120 ms zero-duty pauses. All final pulses were reported perceptible with the configured 3000 ms presentation. Future tuning needs physical checks.
- SDK launcher exit-status handling is documented in [README](../README.md#unit-tests); reusable drawing/input/clock pitfalls are in [testing](testing.md#platform-regression-notes) and [technical design](technical-design.md).

## Remaining limits and evidence

Exact simultaneous completion/input and forced suspension/termination were not induced on hardware. Other unestablished checks include watch-file read-back, exhaustive touch corners, former Pause/Resume-position touch during COMPLETED, both vibration switches off together on this artifact, sleep-specific DND/options and touch wake, detailed saver options, and long-term endurance. Manual stopwatch readings are not calibrated latency measurements. Other devices, firmware, and settings need separate verification.

Integrated logs/captures/probes were local ignored artifacts under `build/verification/integrated-regression/`, unavailable in a fresh checkout; Git retains committed descriptions, not those artifacts. Rerun affected checks for future changes rather than treating this baseline as current acceptance.

## Documentation checks (2026-11-08)

Documentation-only working-tree cleanup over `5789ce8`: consistency/diff review, `git diff --check`, all 82 local links/anchors, code-fence balance, and `bash -n` on 13 Bash examples passed. Commands were syntax-checked, not executed. No application source, tests, resources, or build configuration changed; builds, unit tests, simulator, and hardware checks were not rerun or needed for this cleanup. The runtime evidence and limits above remain scoped to their original artifacts.

## Model observation contract documentation (2026-11-10)

Added the getter and single-clock-sample contract to technical design. Consistency review against `BrushingTimer` and the existing `timerSamplesAndObservation` test, local link/anchor checks in technical design and this record, and `git diff --check` passed. Documentation only; no builds or runtime tests were run or required, and existing runtime acceptance limits remain unchanged.
