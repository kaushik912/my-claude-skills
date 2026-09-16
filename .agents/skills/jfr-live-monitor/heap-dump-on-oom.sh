#!/usr/bin/env bash
# Enable (or disable) HeapDumpOnOutOfMemoryError on a running JVM, live, via
# jcmd's {manageable} flags -- no restart needed. Standalone: doesn't need
# JFR, JDK 21+, or SDKMAN, just jcmd on PATH.
#
# Usage: ./heap-dump-on-oom.sh <pid> [heap_dump_path]
#        ./heap-dump-on-oom.sh <pid> --off
set -euo pipefail

JCMD_BIN="${JCMD_BIN:-jcmd}"
PID="${1:-}"
ARG2="${2:-}"

usage() {
    echo "Usage: $0 <pid> [heap_dump_path]" >&2
    echo "         enable -- dumps to heap_dump_path, or \$TMPDIR/heap-dump-<pid>-<timestamp>.hprof" >&2
    echo "       $0 <pid> --off" >&2
    echo "         disable" >&2
    echo "  env override: JCMD_BIN" >&2
    exit 1
}

[ -n "$PID" ] || usage
case "$PID" in
    ''|*[!0-9]*) echo "ERROR: pid must be numeric, got '$PID'" >&2; exit 1 ;;
esac

if ! kill -0 "$PID" 2>/dev/null; then
    echo "ERROR: no process with pid $PID (or not accessible from this shell)" >&2
    exit 1
fi

if ! command -v "$JCMD_BIN" >/dev/null 2>&1; then
    echo "ERROR: '$JCMD_BIN' not found on PATH. Set JCMD_BIN=/path/to/jcmd." >&2
    exit 1
fi

if [ "$ARG2" = "--off" ]; then
    if ! "$JCMD_BIN" "$PID" VM.set_flag HeapDumpOnOutOfMemoryError false >/dev/null 2>&1; then
        echo "ERROR: couldn't clear the flag on pid $PID." >&2
        exit 1
    fi
    echo "Disabled HeapDumpOnOutOfMemoryError on pid $PID."
    exit 0
fi

HEAP_DUMP_PATH="${ARG2:-${TMPDIR:-/tmp}/heap-dump-${PID}-$(date +%s).hprof}"

if ! "$JCMD_BIN" "$PID" VM.set_flag HeapDumpOnOutOfMemoryError true >/dev/null 2>&1 \
   || ! "$JCMD_BIN" "$PID" VM.set_flag HeapDumpPath "$HEAP_DUMP_PATH" >/dev/null 2>&1; then
    echo "ERROR: couldn't set the flags on pid $PID." >&2
    echo "Check they're manageable: jcmd $PID VM.flags -all | grep HeapDump" >&2
    exit 1
fi

echo "Enabled HeapDumpOnOutOfMemoryError on pid $PID -> $HEAP_DUMP_PATH"
echo "Dump size tracks -Xmx, not how much actually leaked -- make sure this path has room, and"
echo "isn't tmpfs (common in containers) fighting the app for the same RAM it's already short on."
echo "Disable later with: $0 $PID --off"
