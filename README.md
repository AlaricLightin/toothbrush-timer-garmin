# Toothbrush Timer

A Garmin Connect IQ app for Vivoactive 6 that times two minutes of brushing, gives short cues at 30, 60, and 90 seconds, and ends with three vibration pulses.

## Setup

Run commands from the repository root in Bash on Ubuntu Linux. Install the [official Connect IQ SDK](https://developer.garmin.com/connect-iq/sdk/) through SDK Manager with the Vivoactive 6 device package and fonts. Put a compatible Java runtime on `PATH` (Java 11+ for SDK 9.2.0).

Set the SDK root and your private DER signing key in each host shell that runs SDK tools. Keep the key outside the checkout and retain it for published updates. To create one with OpenSSL, follow the [signing-key procedure](doc/development.md#signing-key).

```bash
export CIQ_SDK="/absolute/path/to/connectiq-sdk"
export CIQ_KEY="/absolute/path/to/private/developer-key.der"
```

## Build

```bash
bash scripts/build.sh debug    # build/ToothbrushTimer.prg (default)
bash scripts/build.sh test     # build/ToothbrushTimer-test.prg
bash scripts/build.sh release  # build/ToothbrushTimer-release.prg
```

All modes target `vivoactive6` with Strict checking and warnings enabled. Use the output only after a successful build. A failed build can leave an older PRG in place.

## Simulator

From a graphical desktop terminal, start the simulator and wait for its window. For missing native libraries or connection errors, see [Distrobox setup](doc/development.md#distrobox-simulator) and [simulator troubleshooting](doc/development.md#simulator-troubleshooting).

```bash
"$CIQ_SDK/bin/connectiq"
```

### Run the app from the host

In a second host terminal, launch the debug build. READY should show the toothbrush, `2:00`, and Start.

```bash
"$CIQ_SDK/bin/monkeydo" build/ToothbrushTimer.prg vivoactive6
```

## Unit tests

With the simulator running, enable vibration and disable Do Not Disturb for the haptics smoke test. Run the test build from the host. To run a single test, append its function name after `-t` (e.g., `defaultTimerConfig`).

```bash
"$CIQ_SDK/bin/monkeydo" build/ToothbrushTimer-test.prg vivoactive6 -t
```

Confirm the expected test count and a printed `PASSED` summary with zero failures and errors. The SDK 9.2.0 Unix launcher returned status 1 for both passing and failing runs.

## Development

- [Repository rules](AGENTS.md) and [development workflow](doc/development-workflow.md)
- [Product requirements](doc/product-requirements.md), [technical design](doc/technical-design.md), and [UI design](doc/design/ui-design.md)
- [Watch installation](doc/development.md#watch-installation-and-acceptance), [regression checks](doc/testing.md), and [verification results](doc/verification.md)
