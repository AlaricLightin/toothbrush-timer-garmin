# Verification baseline

Each result applies to the identified product, artifact, and environment. Use the [regression checklists](testing.md) for future changes.

## Nine-device build, simulator tests, and export check, 2026-11-23

The working tree over `2ebb20d` included the eight added manifest products and both launcher overrides. With all nine profiles and fonts installed, `python3 scripts/check-release.py` built every debug and test PRG without warnings using Connect IQ SDK 9.2.0. The simulator in Ubuntu 22.04 Distrobox printed `PASSED (passed=63, failed=0, errors=0)` for each product.

| Product | Debug PRG SHA-256 | Test PRG SHA-256 |
| --- | --- | --- |
| `vivoactive6` | `e55664891efdbad5152823edcce2b48b4c8e8c229fc27cce85126d3e457a3635` | `6f8f08b5b8c5ae7ead82683bec69dd8f8e05f0692788428f8149b663686755e0` |
| `vivoactive5` | `a013f5fe250da625323b3b119927f949c5db3785bbb86a933fe66a48d086b38a` | `82307e75893c5327aff5d7238ae6462603a0d88b719520b7b1ce3d58707ea41d` |
| `venu3s` | `0893666745261c53268c51cb1978a3284874a2b4d01685756b5d0cd1efabba9b` | `484eb96cb2ee0fd9e23ec4a6a7d79d323edde13ccb23ffe7ae0a6fa9a4144a3f` |
| `venu441mm` | `1b65b68a3a070c68d3a3be249ec1ffaa7337018f6d4fac59a67e5c64cac5d9ab` | `d7b7f2bc25c17188a7d173cf02767ad949e5f7aa07b2aca3036c81988560f2e6` |
| `fr165` | `ddb706703df0a0241e0c7209a9399ba0f735cd42e5700e45f7004b41937a7b63` | `1d1fb1e1af4bb3ab7fb481e485eb8e76884a89ffb4451751b4f0f8a924ce9c6b` |
| `fr165m` | `c204b59a0fc3304b26429a4f5a94d89a8a049252c4bcd91b696d35bd3cd20f71` | `7500104d759d67ca62e7f0d0da383fd818f4ca14d38781b2cbe6ed60bada0d97` |
| `fr170` | `e147ea8f15f320107e82bcb872caab320d612899cbd7896deae3d091f89662a0` | `8f6cc7243a4ae3b83bc0d6b558f19eb87eb67b1a7237338de1be8549dd889e58` |
| `fr170m` | `8425ce8738b8f1dc1cfe6c549faebf4ae7251bcd826c2b98f99e96ae63e2fe2a` | `1b26d9b454700d8d6796d7af88734bf82d86e6214a62b8fcd2bb8053ad44f283` |
| `fr57042mm` | `121d43928b59cf758d526fc528d1f0c66ac405959e9c9be18b2852aeb5aaf7b3` | `bcc2c347935f60c38563074ac80fc499a35fa4aa362d2de73a896192611f9f7e` |

The launcher overrides matched the installed profile dimensions of 56 × 56 for Vivoactive 5 and 70 × 70 for Venu 3S. The signed export built all nine products without warnings. The archive manifest mapped one PRG to each installed profile, and the archive integrity check passed. The SHA-256 of `build/ToothbrushTimer.iq` was `da301edd1962e4b92dc7b8ca0c76c21ad62b3855ba2fdebc6a244ee7230c5b93`. The exported Vivoactive 6 PRG matched the standalone release build at `fb546c61d25edc7ebb8528f09f9d77b70b107660fc848a22982844b78ea687cd`.

Manual simulator acceptance and the release-candidate Vivoactive 6 hardware checks are pending. Physical checks on the eight additional models were not run.

## Launcher icon sizes, 2026-11-23

With the Vivoactive 5 and Venu 3S launcher overrides in the working tree over `2ebb20d`, SDK 9.2.0 built the Vivoactive 6 debug PRG (SHA-256 `6a872771ea5d8471ffbe9425e0e5d8590e72ba3a976e356f5365771aacc7b940`). Its only warnings concerned the eight missing device profiles.

In two temporary builds, each override was selected in turn for the installed Vivoactive 6 profile. The compiler's size diagnostic identified the Vivoactive 5 icon as 56 × 56 and the Venu 3S icon as 70 × 70 before resizing to the test profile's 54 × 54. The nine-device check above records the subsequent builds on the intended profiles.

## Store release tooling, 2026-11-23

The working tree over `2ebb20d` added eight manifest products and the [release check](testing.md#store-release-checklist). Connect IQ SDK 9.2.0 had only the Vivoactive 6 profile installed.

| Product | Result |
| --- | --- |
| `vivoactive6` | Default debug and release builds succeeded. The release check built the per-device debug and test PRGs and the simulator printed `PASSED (passed=63, failed=0, errors=0)`. The compiler warned about all eight missing profiles. |
| `vivoactive5`, `venu3s`, `venu441mm`, `fr165`, `fr165m`, `fr170`, `fr170m`, `fr57042mm` | Each debug build failed at device selection because its SDK profile was missing. Simulator tests were not run for these products. The release check reported each failure and exited with status 1. |

Vivoactive 6 matrix PRG SHA-256 values matched those of the subsequent nine-device check above.

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
