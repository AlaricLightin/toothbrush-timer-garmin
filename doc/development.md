# Development Setup and Troubleshooting

Use the [README setup](../README.md#setup) prerequisites and environment variables.
All commands run from the repository root in **Bash on Ubuntu Linux**, using
caller-supplied paths. The SDK, Vivoactive 6 device package, and fonts must be
available to the user running the tools. Builds and `monkeydo` run on the host;
simulator use needs a graphical desktop. Other operating systems need their
SDK launchers and shell syntax. Versions below describe verified examples.

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

## Command-line MTP transfer

Build the release and record its hash using the
[installation instructions](../README.md#physical-device-installation-and-acceptance).
Connect the watch with a USB data cable and open it in Ubuntu Files.

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

Finish by following the README's read-back hash, eject, launch, and acceptance
checks. A successful transfer alone does not establish physical acceptance.
