# Toothbrush Timer

A Garmin Connect IQ watch app for Vivoactive 6. A two-minute countdown shows
continuous progress through four stages, with short cues at 30, 60, and 90
seconds and a three-pulse completion cue. Touch and the upper hardware button provide
Start/Pause/Resume; touch Stop resets the session. The lower button exits, and
completion shows `Nice job!` for about three seconds before automatic exit.
Every launch starts fresh at `2:00`.

Display wake, brightness, and timeout are controlled entirely by the system.
The display may dim or turn off during brushing; normal watch wake mechanisms apply.

For new work, start with [development workflow](doc/development-workflow.md) and
[repository rules](AGENTS.md). The documentation has these responsibilities:

| Document | Purpose |
| --- | --- |
| [Product requirements](doc/product-requirements.md) | Current behavior, scope, and possible extensions |
| [Technical design](doc/technical-design.md) | Architecture, timing, lifecycle, and platform constraints |
| [UI design](doc/design/ui-design.md) | Palette, layouts, components, and reference artwork |
| [Development](doc/development.md) | Detailed setup, troubleshooting, and watch installation |
| [Testing](doc/testing.md) | Reusable automated and manual regression checks |
| [Verification](doc/verification.md) | Tested artifacts, results, and remaining limits |

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

The wrapper checks prerequisites and preserves compiler failures. Use outputs
only after successful builds: failures can leave older artifacts. Test functions
and helpers use `:test` annotations and are excluded from debug/release builds.

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

Confirm READY shows the toothbrush, `2:00`, and Start without automatic countdown
or runtime errors. Simulator Enter performs Start/Pause/Resume; Back exits.
Use the [regression checklists](doc/testing.md) for further checks.

For launch or connection errors, see [simulator troubleshooting](doc/development.md#simulator-troubleshooting).

## Physical-device installation and acceptance

Build/install the release using the [watch installation procedure](doc/development.md#watch-installation-and-acceptance),
then run the applicable [manual checks](doc/testing.md#manual-acceptance-matrix).
Record results and limits for that artifact; a successful transfer alone does
not establish physical acceptance.
