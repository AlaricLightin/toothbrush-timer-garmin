"""Build and test each manifest product in the running Connect IQ simulator."""

import os
from pathlib import Path
import signal
import subprocess
import sys
import xml.etree.ElementTree as ET


# Update when adding or removing Monkey C tests. A partial suite must fail.
EXPECTED_TESTS = 63
SIMULATOR_TIMEOUT_SECONDS = 60


def check_device(device, monkeydo):
    for mode in ("debug", "test"):
        print(f"\nBuilding {mode} for {device}", flush=True)
        build = subprocess.run(["bash", "scripts/build.sh", mode, device])
        if build.returncode:
            return f"FAIL ({mode} build, simulator tests not run)"

    program = Path("build") / device / "ToothbrushTimer-test.prg"
    print(f"Running simulator tests for {device}", flush=True)
    with subprocess.Popen(
        [monkeydo, program, device, "-t"],
        stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True,
        start_new_session=True,
    ) as tests:
        try:
            output, _ = tests.communicate(timeout=SIMULATOR_TIMEOUT_SECONDS)
        except subprocess.TimeoutExpired as timeout:
            if timeout.output:
                print(timeout.output.decode(tests.stdout.encoding, errors="replace"), end="")
            return f"FAIL (simulator tests timed out after {SIMULATOR_TIMEOUT_SECONDS} seconds)"
        finally:
            # monkeydo is a shell wrapper. Stop its child processes as well.
            if tests.returncode is None:
                try:
                    os.killpg(tests.pid, signal.SIGKILL)
                except ProcessLookupError:
                    pass

    print(output, end="")
    summaries = [line.strip() for line in output.splitlines()
                 if line.strip().startswith(("PASSED (", "FAILED ("))]
    expected = f"PASSED (passed={EXPECTED_TESTS}, failed=0, errors=0)"
    # The SDK 9.2.0 Unix monkeydo launcher exits 1 even after a passing suite.
    if tests.returncode in (0, 1) and summaries == [expected]:
        return "PASS"
    return f"FAIL (expected '{expected}', launcher status {tests.returncode})"


def main():
    if not Path("manifest.xml").is_file() or not Path("monkey.jungle").is_file():
        sys.exit("Run from the repository root.")
    sdk = os.environ.get("CIQ_SDK")
    if not sdk:
        sys.exit("Set CIQ_SDK to the official Connect IQ SDK root.")
    monkeydo = Path(sdk) / "bin" / "monkeydo"
    if not os.access(monkeydo, os.X_OK):
        sys.exit("CIQ_SDK must contain executable bin/monkeydo.")

    namespace = {"iq": "http://www.garmin.com/xml/connectiq"}
    products = ET.parse("manifest.xml").findall(
        "iq:application/iq:products/iq:product", namespace
    )
    if not products:
        sys.exit("No release targets found in manifest.xml.")

    results = {}
    for product in products:
        device = product.attrib["id"]
        results[device] = check_device(device, monkeydo)

    print("\nAutomated release checks")
    for device, result in results.items():
        print(f"{device}: {result}")
    return 0 if all(result == "PASS" for result in results.values()) else 1


if __name__ == "__main__":
    sys.exit(main())
