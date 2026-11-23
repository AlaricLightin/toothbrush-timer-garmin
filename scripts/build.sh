#!/usr/bin/env bash
set -euo pipefail

fail() {
    echo "Error: $*" >&2
    exit 1
}

usage="Usage: bash scripts/build.sh [debug|release|test] [device]"
if [[ $# -gt 2 ]]; then
    fail "$usage"
fi

mode="${1:-debug}"
device="${2-vivoactive6}"
[[ "$device" =~ ^[a-z0-9_]+$ ]] || fail "Invalid device ID: $device"
output_dir="build"
if [[ $# -eq 2 ]]; then
    output_dir="build/$device"
fi
case "$mode" in
    debug) output="$output_dir/ToothbrushTimer.prg"; flags=() ;;
    release) output="$output_dir/ToothbrushTimer-release.prg"; flags=(-r) ;;
    test) output="$output_dir/ToothbrushTimer-test.prg"; flags=(-t) ;;
    *) fail "$usage" ;;
esac

[[ -f monkey.jungle && -f manifest.xml ]] || fail "Run from the repository root."
[[ -n "${CIQ_SDK:-}" ]] || fail "Set CIQ_SDK to the official Connect IQ SDK root."
[[ -x "$CIQ_SDK/bin/monkeyc" ]] || fail "CIQ_SDK must contain executable bin/monkeyc."
[[ -n "${CIQ_KEY:-}" ]] || fail "Set CIQ_KEY to a developer signing key in DER format."
[[ -f "$CIQ_KEY" && -r "$CIQ_KEY" ]] || fail "CIQ_KEY must name a readable signing-key file."
command -v java >/dev/null 2>&1 || fail "Install a compatible Java runtime and put java on PATH."

mkdir -p "$output_dir"

# SVG resource compilation uses Java AWT, but does not need a desktop display.
# Scope headless mode to the compiler so simulator launch remains graphical.
JAVA_TOOL_OPTIONS="${JAVA_TOOL_OPTIONS:+$JAVA_TOOL_OPTIONS }-Djava.awt.headless=true" \
    "$CIQ_SDK/bin/monkeyc" -f monkey.jungle -d "$device" \
    -o "$output" -y "$CIQ_KEY" -w "${flags[@]}"
