# Toothbrush Timer

A Garmin Connect IQ watch app for Vivoactive 6. A two-minute countdown shows
continuous progress through four stages, with short cues at 30, 60, and 90
seconds and a longer completion cue. Touch and the upper hardware button provide
Start/Pause/Resume; touch Stop resets the session. The lower button exits, and
completion exits automatically. Every launch starts fresh at `2:00`.

Start/Resume make a best-effort backlight request; system timeout, gesture,
power, and burn-in restrictions still apply. Requests are not renewed during
countdown or pause.

The MVP is complete, with simulator regression and user-reported physical
acceptance on Vivoactive 6 firmware 18.32 recorded in the
[verification baseline](doc/verification.md). See the [requirements](doc/product-requirements.md),
[design](doc/technical-design.md), [regression checklists](doc/testing.md), and
[completed plan](doc/implementation-plan.md).

## Setup

Run commands from the repository root in **Bash on Ubuntu Linux**. Builds and
`monkeydo` run on the host; the simulator can run natively or in Distrobox.
Other operating systems need their corresponding SDK launchers and shell syntax.

- Install the [official Connect IQ SDK](https://developer.garmin.com/connect-iq/sdk/)
  through SDK Manager, including the Vivoactive 6 device package and fonts,
  discoverable by the user running builds.
- Put a compatible Java runtime on `PATH` (Java 11+ for SDK 9.2.0).
- Install OpenSSL if creating a signing key. Simulator use also needs a graphical
  desktop and the SDK's native libraries; compilation does not need a display.

Set these in your shell or CI configuration, using your own absolute paths:

```bash
export CIQ_SDK="/absolute/path/to/connectiq-sdk"
export CIQ_KEY="/absolute/path/to/private/developer-key.der"
```

`CIQ_SDK` contains `bin/monkeyc`. Keep the signing key outside the checkout and
retain it for published updates. Do not commit keys or local configuration.
Paths containing spaces are supported.

For a new key, follow the [signing-key procedure](doc/development.md#signing-key).

## Build

```bash
"$CIQ_SDK/bin/monkeyc" --version
bash scripts/build.sh debug
bash scripts/build.sh release
bash scripts/build.sh test
```

Outputs are `build/ToothbrushTimer.prg`, `build/ToothbrushTimer-release.prg`, and
`build/ToothbrushTimer-test.prg`; release strips debug information and test enables
unit-test compilation with `-t`. Omitting the mode builds debug. All modes target
`vivoactive6` with warnings enabled and Strict checking in `monkey.jungle`.
Do not also pass `-l 3`, which causes a duplicate-setting warning.

The wrapper checks prerequisites and preserves compiler failures. Install missing
device packages through SDK Manager. It scopes Java AWT headless mode to compilation;
`base.sourcePath = source;tests` excludes generated copies from source discovery.
Outputs are ignored by Git; use them only after a successful build, since failures
can leave older artifacts. Test functions and the fake clock use `:test` annotations
and are excluded from normal debug and release artifacts.

## Unit tests

Build the test artifact using the command above, then start the simulator using
the [simulator instructions](#simulator). Run on the host from the repository root:

```bash
"$CIQ_SDK/bin/monkeydo" build/ToothbrushTimer-test.prg vivoactive6 -t
```

The Unix launcher also accepts a function name for a focused test:

```bash
"$CIQ_SDK/bin/monkeydo" build/ToothbrushTimer-test.prg vivoactive6 -t defaultTimerConfig
```

Confirm the expected tests ran and the printed summary reports `PASSED`, with
zero failures and errors. Do not infer success from the process exit status:
the verified SDK 9.2.0 launcher returned 1 for both passing and deliberately
failing runs. A missing summary does not establish a pass.

The haptics simulator smoke test requires vibration enabled and Do Not Disturb
disabled in the simulator settings. It verifies that both real vibration API
calls return without an exception; it cannot establish physical motor behavior.

## Simulator

Use a graphical desktop terminal. If the simulator is already running, skip to
[running the app](#run-the-app-from-the-host).

### Native launch

Check dependencies, resolve any `not found` libraries, then launch:

```bash
ldd "$CIQ_SDK/bin/simulator"
"$CIQ_SDK/bin/connectiq"
```

If native libraries are unavailable, use the [Distrobox setup](doc/development.md#distrobox-simulator).

### Run the app from the host

Wait for the simulator window, then run in a second host terminal with `CIQ_SDK`
set, from the repository root:

```bash
"$CIQ_SDK/bin/monkeydo" build/ToothbrushTimer.prg vivoactive6
```

The launch check is the toothbrush icon, `2:00`, and Start rendering without a
runtime error or automatic countdown. Tap Start or press the simulator's upper
hardware button (Enter) to start; tap Pause/Resume or press Enter to toggle.
Stop resets from RUNNING or PAUSED. The lower hardware button (Back) exits;
completion also exits automatically. Taps outside the visible controls do nothing.
Relaunch always starts a fresh READY session. See
[regression checklists](doc/testing.md) for full coverage.

For launch or connection errors, see [simulator troubleshooting](doc/development.md#simulator-troubleshooting).

## Physical-device installation and acceptance

Use the release artifact for Vivoactive 6 hardware checks. From the repository
root, with the [setup](#setup) prerequisites configured:

```bash
bash scripts/build.sh release
sha256sum build/ToothbrushTimer-release.prg
```

Connect the watch with a USB data cable and open it in Ubuntu Files. Use
`Internal Storage/GARMIN/Apps` on the watch; do not assume a local mount path.
Copy `build/ToothbrushTimer-release.prg` into that folder, following Garmin's
[sideloading procedure](https://developer.garmin.com/connect-iq/connect-iq-basics/your-first-app/).
The watch's [USB Mode setting](https://www8.garmin.com/manuals/webhelp/GUID-8C2C402F-55AC-431F-9CF2-1442B89CE149/EN-US/GUID-67C130E2-B01F-4253-8810-4762AB9DEB1D.html)
supports MTP for file transfer.

For command-line installation, use the [MTP transfer procedure](doc/development.md#command-line-mtp-transfer).
For updates through Files, confirm replacement of only this app’s PRG.

Wait for transfer completion, read the copied file back to compare its SHA-256
with the local artifact, and eject/unmount the watch in Files before unplugging.
Open Toothbrush Timer from the watch's apps list. First verify a readable
toothbrush icon, `2:00`, and Start, with no automatic countdown.

Work through the [manual acceptance matrix](doc/testing.md#manual-acceptance-matrix)
and record the artifact hash, watch firmware, relevant display/haptic/power
settings, observations, and outstanding checks in [verification](doc/verification.md).
Copying a PRG does not establish successful on-watch launch or physical acceptance.

On tested firmware 18.32, **Alert vibration** controls app cues; System vibration
alone does not disable them. DND suppresses cues, while countdown and exit
continue. Sleep/power settings can limit display visibility and gesture wake.
See the [physical results and limits](doc/verification.md#physical-acceptance-2026-11-03)
for tested combinations; other firmware/settings require verification.
