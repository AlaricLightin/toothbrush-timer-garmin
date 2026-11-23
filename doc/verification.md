# Verification baseline

Each result applies to the identified Vivoactive 6 artifact and environment. Use the [regression checklists](testing.md) for future changes.

## Timer layout and Stop behavior, 2026-11-22 to 2026-11-23

The debug and test builds used the layout and geometry-test changes later committed as `071df11`, built over `4bb4290`. The host ran Ubuntu 24.04.5, OpenJDK 21.0.13.1, and Connect IQ SDK 9.2.0. Unit tests ran in the Vivoactive 6 simulator (API 6.0.3) in Distrobox.

| Check | Result |
| --- | --- |
| Strict debug and test builds | Both printed `BUILD SUCCESSFUL` without warnings. The full suite printed `PASSED (passed=63, failed=0, errors=0)`, including layout geometry and hit tests. |
| Simulator layout, user-reported | Across READY → RUNNING → PAUSED → READY, the toothbrush, time, and control row stayed in place. The stage label appeared with visible gaps and cleared on Stop. The local debug hash matched the record. The loaded PRG was not independently identified. |
| On-wrist layout, user-reported | On firmware 19.23 with always-on display and battery saver off, the toothbrush cleared the ring and gaps between elements were visible in READY, RUNNING, and PAUSED. The countdown and stage label were readable at a glance wherever shown. Brightness and ambient lighting were unreported. |
| On-wrist input, same release, user-reported | Stop near an interval reset immediately without an extra pulse. Restart delivered all three interval cues. Pause/Resume preserved the stage without replay. Stop at displayed `0:01` reset silently. Tapping the former Stop position once completion began allowed all three pulses and automatic exit. Exact callback order was unmeasured. |

| Artifact | SHA-256 |
| --- | --- |
| Debug | `6a872771ea5d8471ffbe9425e0e5d8590e72ba3a976e356f5365771aacc7b940` |
| Test | `6fdd0419193fe7f446d32650d13b035ca7bea11070f06c7da0e470462fe31a17` |
| Release used for both watch checks | `fb546c61d25edc7ebb8528f09f9d77b70b107660fc848a22982844b78ea687cd` |

The reported release hash matched the local PRG. Watch-file read-back was unreported.

## Exact Stop and Pause boundaries, 2026-11-10

SDK 9.2.0 debug, test, and release builds passed Strict checking without warnings for the changes over `fcda7e9` committed as `003d03b`. The full suite printed `PASSED (passed=62, failed=0, errors=0)` (test PRG SHA-256 `5591cc3665c549f42a7d9acf093300d2568b6ca1c97947ea5a65ed1669c668c9`).

Three injected-clock simulator probes made touch the first handler to observe a boundary. At 30,000 ms, Stop reset without a vibration request and Pause requested one interval pulse. At 120,000 ms, Stop yielded to the five-entry completion vibration and one automatic exit after the three-second delay.

## Full-session baseline, 2026-11-08

SDK 9.2.0 Strict debug, test, and release builds passed without warnings on unchanged production code over `5f6f639`. The suite printed `PASSED (passed=60, failed=0, errors=0)`. The physical check used the matching release prepared at `8cd11fa` (SHA-256 `af116369bdf09147de8f46fc29478031682c284458a728aeafb228cac11081dd`, no watch-file read-back reported).

- **Simulator (API 6.0.3).** Rendering, input, and a full timed session passed, with three interval requests, one completion pattern, and one exit. Injected-clock checks exercised Back, Pause, and Stop at the completion boundary. Kill App in RUNNING and COMPLETED cancelled pending work and relaunch opened in READY.
- **Watch (firmware 18.32, user-reported).** Launcher, touch and button controls, pause/resume, Stop, three-pulse completion, automatic exit, Back, and fresh relaunch passed. Timing and cues continued through dimming, a black screen, and an alarm overlay. The watch had exited when checked at 2:08 in the black-screen session. Baseline settings were an eight-second timeout, always-on display off, low brightness, gesture wake and Alert vibration on, and DND, sleep, and battery saver off.

### Platform observations

- On firmware 18.32, System vibration off with Alert on allowed cues. System on with Alert off suppressed them. Both on restored them. DND suppressed cues while timing and exit continued. The both-off combination was not retested on this release, and the API's `vibrateOn` flag was not sampled.
- The tested interval pulse was 250 ms at 100% duty. All three 170 ms completion pulses at 75% duty, separated by 120 ms pauses, were perceptible before automatic exit.
- In both the sleep-mode and battery-saver checks, the timer continued, the watch delivered its cues, and the app exited automatically after completion. Sleep mode prevented gesture wake. The display stayed dimmed in battery saver, leaving saver gesture wake unverified. With the screen black, the upper button woke and started READY, a center touch woke RUNNING without activating a control, and the lower button exited RUNNING.

**Coverage limits.** Real suspension/resume and exact simultaneous hardware input at completion remain unverified. Other limits include exhaustive touch edges and former Pause/Resume taps during COMPLETED, exact black-screen exit timing, detailed sleep/saver settings and touch wake, and long-term endurance. The later layout and Stop checks covered only the cases listed above.
