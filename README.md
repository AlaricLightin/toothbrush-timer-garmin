# Toothbrush Timer

A Garmin Connect IQ watch app for Vivoactive 6. A two-minute countdown shows
continuous progress through four stages, with short cues at 30, 60, and 90
seconds and a longer completion cue. Touch and the upper hardware button provide
Start/Pause/Resume; touch Stop resets the session. The lower button exits, and
completion exits automatically. Every launch starts fresh at `2:00`.

Start/Resume make a best-effort backlight request; system timeout, gesture,
power, and burn-in restrictions still apply. Requests are not renewed during
countdown or pause.

Steps 1–9 are complete, including simulator regression and user-reported
physical acceptance on Vivoactive 6 firmware 18.32. The
[verification record](doc/verification.md#step-9--physical-vivoactive-6-acceptance-2026-11-03)
identifies the tested release, settings, results, and verification limits. See the
[requirements](doc/product-requirements.md), [design](doc/technical-design.md),
and [implementation plan](doc/implementation-plan.md).

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

If you need a new key, this creates an RSA 4096-bit, unencrypted PKCS#8 DER key
using Garmin's [documented format](https://developer.garmin.com/connect-iq/reference-guides/monkey-c-command-line-setup/)
and refuses to overwrite an existing file:

```bash
(
    set -euo pipefail
    : "${CIQ_KEY:?Set CIQ_KEY to the new signing-key path}"
    if [[ -e "$CIQ_KEY" ]]; then
        echo "Error: CIQ_KEY already exists; use it or choose a new path." >&2
        exit 1
    fi
    umask 077
    mkdir -p "$(dirname "$CIQ_KEY")"
    openssl genrsa 4096 | openssl pkcs8 -topk8 -inform PEM -outform DER \
        -out "$CIQ_KEY" -nocrypt
)
```

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

If the required libraries are unavailable in your host release, use Distrobox.

### Distrobox launch

Install [Distrobox and a supported container engine](https://distrobox.it/#installation).
Reuse a compatible container, or create one. This example uses Ubuntu 22.04 for
SDKs requiring [WebKitGTK 4.0](https://packages.ubuntu.com/jammy/libwebkit2gtk-4.0-37):

```bash
export CIQ_BOX="your-simulator-container"
distrobox create --name "$CIQ_BOX" --image docker.io/library/ubuntu:22.04
distrobox enter --name "$CIQ_BOX" -- sudo apt-get update
distrobox enter --name "$CIQ_BOX" -- sudo apt-get install \
    libwebkit2gtk-4.0-37 libusb-1.0-0 libudev1 libsm6 libxxf86vm1
```

Package installation runs inside the container; adjust packages for your SDK.
Retain Distrobox's shared files, desktop integration, and host networking.
The same SDK path, device package, and fonts must be accessible inside the
container; custom homes/storage may require mounts and resource configuration.
If SDK Manager also lacks native libraries, run it in the compatible environment.

From a host terminal, check dependencies and resolve any `not found` libraries
inside the container before launching:

```bash
: "${CIQ_SDK:?Set CIQ_SDK to the shared SDK root}"
: "${CIQ_BOX:?Set CIQ_BOX to the simulator container name}"
distrobox enter --name "$CIQ_BOX" -- ldd "$CIQ_SDK/bin/simulator"
distrobox enter --name "$CIQ_BOX" -- "$CIQ_SDK/bin/connectiq"
```

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
[verification](doc/verification.md) and the implementation plan's acceptance matrices.

For connection/display failures, check simulator readiness, the shared SDK,
host networking, and desktop integration. If GTK/GIO errors reference host-only
module paths, relaunch with this scoped workaround in an X11/XWayland session:

```bash
distrobox enter --name "$CIQ_BOX" -- env \
    -u GDK_PIXBUF_MODULE_FILE -u GDK_PIXBUF_MODULEDIR \
    -u GTK_IM_MODULE_FILE -u GTK_PATH \
    -u GIO_MODULE_DIR -u GIO_EXTRA_MODULES \
    -u GTK_IM_MODULE -u GSETTINGS_SCHEMA_DIR \
    GDK_BACKEND=x11 "$CIQ_SDK/bin/connectiq"
```

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

For a first installation through the command line, Ubuntu's desktop session
must have working GVfs MTP support and the watch must already be mounted in
Files. Discover its actual `mtp://.../` URI:

```bash
env -u GIO_MODULE_DIR -u GIO_EXTRA_MODULES gio mount -l
```

Set `CIQ_WATCH_URI` in your shell to that watch's root URI, then copy:

```bash
: "${CIQ_WATCH_URI:?Set CIQ_WATCH_URI to the connected watch MTP root URI}"
env -u GIO_MODULE_DIR -u GIO_EXTRA_MODULES gio copy -i \
    build/ToothbrushTimer-release.prg \
    "${CIQ_WATCH_URI%/}/Internal Storage/GARMIN/Apps/ToothbrushTimer-release.prg" \
    < /dev/null
```

This first-install command declines overwrite prompts; it does not update an
existing copy. For later replacements, use Files and confirm replacement of
only this app's PRG. Unsetting the two GIO module variables is scoped to each
command; an inherited Snap module path prevented MTP access during verification.
Ordinary filesystem copying through the GVfs mount returned `Operation not
supported`; the GIO MTP transfer succeeded.

Wait for transfer completion, read the copied file back to compare its SHA-256
with the local artifact, and eject/unmount the watch in Files before unplugging.
Open Toothbrush Timer from the watch's apps list. First verify a readable
toothbrush icon, `2:00`, and Start, with no automatic countdown.

Work through the [manual acceptance matrix](doc/implementation-plan.md#7-manual-acceptance-matrix)
and record the artifact hash, watch firmware, relevant display/haptic/power
settings, observations, and outstanding checks in [verification](doc/verification.md).
Copying a PRG does not establish successful on-watch launch or physical acceptance.

On the tested Vivoactive 6 firmware 18.32, **Alert vibration** controls the app's
cues: turning it off suppresses cues with System vibration either on or off.
Turning System vibration off alone leaves app cues enabled when Alert vibration
is on. DND also suppresses cues. Countdown and automatic exit continue with
feedback suppressed. See the step 9 verification record for tested combinations
and verification limits; other firmware/settings require verification.

With the tested sleep and battery-saver configurations, the app still completed
normally, while the display dimmed and gesture wake was unavailable. Sleep mode
with Alert vibration on and the usual DND switch off still allowed cues. Account
for the active focus mode's settings when checking haptics or display behavior.
