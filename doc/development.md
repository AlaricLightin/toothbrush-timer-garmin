# Development Setup and Troubleshooting

Use the [README setup](../README.md#setup) prerequisites and caller-supplied environment variables.
All commands use Bash on the Ubuntu host from the repository root.

## Signing key

Install OpenSSL and set `CIQ_KEY` as described in README before creating a key.

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

## Distrobox simulator

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

After launch, follow [Run the app from the host](../README.md#run-the-app-from-the-host).

## Simulator troubleshooting

For native launch failures, run `ldd "$CIQ_SDK/bin/simulator"` and resolve any
`not found` libraries or use the [Distrobox setup](#distrobox-simulator).
For connection or display failures, check simulator readiness, the shared SDK,
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

## Watch installation and acceptance

Use the release artifact for Vivoactive 6 hardware checks. From the repository
root, with the [README setup](../README.md#setup) prerequisites configured:

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

For command-line installation, use the [MTP transfer procedure](#command-line-mtp-transfer).
For updates through Files, confirm replacement of only this app’s PRG.

Wait for transfer completion, read the copied file back to compare its SHA-256
with the local artifact, and eject/unmount the watch in Files before unplugging.
Open Toothbrush Timer from the watch's apps list. First verify a readable
toothbrush icon, `2:00`, and Start, with no automatic countdown.

Work through the [manual acceptance matrix](testing.md#manual-acceptance-matrix)
and record the artifact hash, watch firmware, relevant display/haptic/power
settings, observations, and outstanding checks in [verification](verification.md).

## Command-line MTP transfer

For a first install, build the release and connect the watch as
[described above](#watch-installation-and-acceptance). With GVfs MTP support
and the watch mounted in Files, discover its `mtp://.../` URI:

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

The command declines overwrite prompts. Use Files for updates. If a GVfs copy
reports `Operation not supported`, use the GIO transfer above. Clearing the
two GIO variables for each command avoids inherited Snap module paths that
can prevent MTP access.

Finish with the [read-back, eject, launch, and acceptance checks](#watch-installation-and-acceptance).
