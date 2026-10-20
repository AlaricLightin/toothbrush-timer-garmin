#!/usr/bin/env bash
set -euo pipefail

fail() {
    echo "Error: $*" >&2
    exit 1
}

if [[ $# -gt 1 ]]; then
    fail "Usage: bash scripts/build.sh [debug|release|test]"
fi

mode="${1:-debug}"
case "$mode" in
    debug) output="build/ToothbrushTimer.prg"; flags=() ;;
    release) output="build/ToothbrushTimer-release.prg"; flags=(-r) ;;
    test) output="build/ToothbrushTimer-test.prg"; flags=(-t) ;;
    *) fail "Usage: bash scripts/build.sh [debug|release|test]" ;;
esac

[[ -f monkey.jungle && -f manifest.xml ]] || fail "Run from the repository root."
[[ -n "${CIQ_SDK:-}" ]] || fail "Set CIQ_SDK to the official Connect IQ SDK root."
[[ -x "$CIQ_SDK/bin/monkeyc" ]] || fail "CIQ_SDK must contain executable bin/monkeyc."
[[ -n "${CIQ_KEY:-}" ]] || fail "Set CIQ_KEY to a developer signing key in DER format."
[[ -f "$CIQ_KEY" && -r "$CIQ_KEY" ]] || fail "CIQ_KEY must name a readable signing-key file."
command -v java >/dev/null 2>&1 || fail "Install a compatible Java runtime and put java on PATH."

mkdir -p build

# SVG resource compilation uses Java AWT, but does not need a desktop display.
# Scope headless mode to the compiler so simulator launch remains graphical.
JAVA_TOOL_OPTIONS="${JAVA_TOOL_OPTIONS:+$JAVA_TOOL_OPTIONS }-Djava.awt.headless=true" \
    "$CIQ_SDK/bin/monkeyc" -f monkey.jungle -d vivoactive6 \
    -o "$output" -y "$CIQ_KEY" -w "${flags[@]}"
