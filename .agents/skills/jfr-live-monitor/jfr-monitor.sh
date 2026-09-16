#!/usr/bin/env bash
# Poll a running JVM's hot methods / GC behavior via a rolling JFR recording.
# Usage: ./jfr-monitor.sh <pid> [interval_seconds] [window_seconds]
set -euo pipefail

PID="${1:-}"
INTERVAL="${2:-30}"
WINDOW="${3:-60}"

usage() {
    echo "Usage: $0 <pid> [interval_seconds=30] [window_seconds=60]" >&2
    echo "  env overrides: JFR_VIEWS (comma-separated), JFR_MAXSIZE" >&2
    echo "  companion: heap-dump-on-oom.sh in this same directory catches an" >&2
    echo "  actual OutOfMemoryError — jfr view can't (see SKILL.md)." >&2
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

# Load the JDK 21+ toolchain pinned in this skill's .sdkmanrc via SDKMAN —
# required, no manual override. `jfr view` needs JDK 21+; the target app
# doesn't have to run on it, only this analysis tool does.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SDKMAN_INIT="${SDKMAN_DIR:-$HOME/.sdkman}/bin/sdkman-init.sh"

if [ ! -f "$SDKMAN_INIT" ]; then
    echo "ERROR: SDKMAN not found (looked for $SDKMAN_INIT)." >&2
    echo "This skill loads its JDK 21+ toolchain (for 'jfr view') from .sdkmanrc via SDKMAN." >&2
    echo "Install it:" >&2
    echo "  curl -s \"https://get.sdkman.io\" | bash" >&2
    echo "then open a new shell and re-run." >&2
    exit 1
fi

set +euo pipefail
# shellcheck disable=SC1090
source "$SDKMAN_INIT" >/dev/null 2>&1
ORIG_DIR="$PWD"
cd "$SCRIPT_DIR"
sdk env >/dev/null 2>&1
cd "$ORIG_DIR"
set -euo pipefail

# `sdk env` sets JAVA_HOME to the pinned candidate, but a system jfr earlier
# in PATH (e.g. from /etc/profile.d or .bashrc) can still win a plain
# `command -v jfr` lookup — go straight at JAVA_HOME instead.
if [ -z "${JAVA_HOME:-}" ] || [ ! -x "${JAVA_HOME}/bin/jfr" ]; then
    echo "ERROR: SDKMAN didn't resolve a usable JDK from .sdkmanrc (JAVA_HOME=${JAVA_HOME:-unset})." >&2
    echo "Run 'sdk env install' in $SCRIPT_DIR to install the pinned candidate, then retry." >&2
    exit 1
fi

JFR_BIN="${JAVA_HOME}/bin/jfr"
JCMD_BIN="${JAVA_HOME}/bin/jcmd"
echo "Loaded JDK via SDKMAN (.sdkmanrc): $JFR_BIN"

JFR_VIEWS="${JFR_VIEWS:-hot-methods,gc}"
JFR_MAXSIZE="${JFR_MAXSIZE:-200m}"
RECORDING_NAME="jfr-live-monitor"
DUMP_FILE="$(mktemp -t jfr-live-monitor-XXXXXX.jfr)"
STARTED_RECORDING=0

# Registered immediately after DUMP_FILE exists so every exit path from here
# on (including the validation checks right below) cleans it up.
cleanup() {
    if [ "$STARTED_RECORDING" -eq 1 ]; then
        "$JCMD_BIN" "$PID" JFR.stop name="$RECORDING_NAME" >/dev/null 2>&1 || true
    fi
    rm -f "$DUMP_FILE"
}
trap cleanup EXIT INT TERM

JFR_VIEW_HELP="$("$JFR_BIN" view 2>&1 || true)"
if printf '%s' "$JFR_VIEW_HELP" | grep -qi "unknown command"; then
    echo "ERROR: '$JFR_BIN' (from SDKMAN's .sdkmanrc candidate) doesn't support 'jfr view'." \
         "The pinned candidate needs to be JDK 21+ — check .sdkmanrc in $SCRIPT_DIR." >&2
    exit 1
fi

JFR_CHECK_OUTPUT="$("$JCMD_BIN" "$PID" JFR.check 2>&1 || true)"
if printf '%s' "$JFR_CHECK_OUTPUT" | grep -q "$RECORDING_NAME"; then
    echo "Reusing already-running recording '$RECORDING_NAME' on pid $PID."
else
    "$JCMD_BIN" "$PID" JFR.start name="$RECORDING_NAME" settings=profile \
        disk=true "maxage=${WINDOW}s" "maxsize=${JFR_MAXSIZE}" >/dev/null
    STARTED_RECORDING=1
    echo "Started rolling recording '$RECORDING_NAME' on pid $PID (window=${WINDOW}s, poll every ${INTERVAL}s)."
fi

echo "Views per cycle: $JFR_VIEWS. Ctrl+C to stop and clean up."
echo

IFS=',' read -r -a VIEWS <<< "$JFR_VIEWS"

# Self-contained safety net: if dumping fails this many cycles in a row, give
# up instead of looping forever repeating the same error — don't rely on an
# external `timeout` wrapper (or the user remembering Ctrl+C) to bound this.
MAX_CONSECUTIVE_FAILURES=5
CONSECUTIVE_FAILURES=0

while true; do
    if ! kill -0 "$PID" 2>/dev/null; then
        echo "Process $PID is gone, stopping."
        break
    fi

    # jcmd can exit 0 even when the underlying JFR.dump semantically failed
    # (attach succeeded, command didn't) — check the file actually landed,
    # not just jcmd's exit code.
    if ! "$JCMD_BIN" "$PID" JFR.dump name="$RECORDING_NAME" filename="$DUMP_FILE" >/dev/null 2>&1 \
       || [ ! -s "$DUMP_FILE" ]; then
        CONSECUTIVE_FAILURES=$((CONSECUTIVE_FAILURES + 1))
        echo "WARNING: JFR.dump didn't produce a readable file (attempt $CONSECUTIVE_FAILURES/$MAX_CONSECUTIVE_FAILURES)." >&2
        if [ "$CONSECUTIVE_FAILURES" -ge "$MAX_CONSECUTIVE_FAILURES" ]; then
            echo "ERROR: giving up after $MAX_CONSECUTIVE_FAILURES consecutive failed dumps." >&2
            exit 1
        fi
        sleep "$INTERVAL"
        continue
    fi
    CONSECUTIVE_FAILURES=0

    echo "===== $(date '+%Y-%m-%d %H:%M:%S') — pid $PID — last ~${WINDOW}s ====="
    for view in "${VIEWS[@]}"; do
        echo "--- $view ---"
        "$JFR_BIN" view "$view" "$DUMP_FILE" 2>&1 || echo "(no data for '$view' yet)"
        echo
    done

    sleep "$INTERVAL"
done
