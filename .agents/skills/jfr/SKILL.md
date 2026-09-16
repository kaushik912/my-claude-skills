---
name: jfr
description: >-
  Use when the user types `/jfr start <pid>` or `/jfr stop <pid>` — starts or
  stops a one-shot JFR recording on a running Java/Spring Boot process via
  jcmd, walking through it step by step. `start` begins recording with
  `settings=profile` (CPU + allocation sampling on) and hands control back to
  the user to go stress-test their app; `stop` dumps the recording to a
  `.jfr` file, then stops it. Not for live/repeated polling (see
  jfr-live-monitor) or reading a finished `.jfr` file (see jfr-analyze) —
  this skill only manages the recording's start/stop lifecycle.
license: MIT
compatibility: "Requires jcmd from the same JDK family as the target JVM (or a compatible attach) — JFR.start/JFR.stop work from JDK 11 onward, no JDK 21 needed here (that's only required for reading the file back with `jfr view`, done by the jfr-analyze skill)."
metadata:
  author: kaushik912
  version: "1.0.0"
  category: development
  tags: ["jfr", "jvm", "profiling", "recording", "cli"]
---
# JFR Start/Stop — One-Shot Recording Lifecycle

## Overview

Manages exactly one thing: turning a JFR recording on and off on a running
JVM by pid, via `jcmd`. No polling, no report rendering — this is the
"attach, record, hand off, dump" half of the workflow; reading the resulting
`.jfr` file back is the [jfr-analyze](../jfr-analyze/SKILL.md) skill's job,
and watching a JVM live/repeatedly is
[jfr-live-monitor](../jfr-live-monitor/SKILL.md)'s job.

Recording name is always `manual-<pid>` — deterministic and pid-scoped so
`/jfr stop <pid>` doesn't need any state remembered from the `start` call,
and so it can't collide with `jfr-live-monitor`'s own recording (which uses
the name `jfr-live-monitor`) running on the same JVM at the same time.

## Usage: `/jfr start <pid>`

1. **Sanity-check the pid is a real, attachable JVM:**
   ```bash
   jcmd <pid> VM.version
   ```
   If this fails, stop here — see Troubleshooting.

2. **Check nothing's already recording under this name:**
   ```bash
   jcmd <pid> JFR.check
   ```
   Look for `manual-<pid>` in the output. If it's already there, tell the
   user and ask whether to stop it first (`/jfr stop <pid>`) or leave it
   running — don't blindly start a second one under the same name (`jcmd`
   will just error with "already exists" anyway).

3. **Start the recording:**
   ```bash
   jcmd <pid> JFR.start name=manual-<pid> settings=profile
   ```
   `settings=profile`, not `default`, on purpose — it turns on both **method
   sampling** (for CPU-bound bugs) and **allocation sampling** (for
   memory-bound bugs). `default` samples too lightly and can miss the signal
   in anything short of a very long recording.

4. Confirm from `jcmd`'s own output (`Started recording <N> ...`) and tell
   the user the recording ID.

5. Hand control back with something like: **"Recording started — go ahead
   and stress-test your app!"** Then stop and wait — don't keep polling or
   dumping on your own; that's the live-monitor skill's job, not this one.

## Usage: `/jfr stop <pid>`

1. **Confirm the recording is actually there:**
   ```bash
   jcmd <pid> JFR.check
   ```
   Look for `manual-<pid>`. If it's missing (never started, already stopped,
   wrong pid), say so and stop.

2. **Dump, then stop — in that order.** Dumping after stopping would throw
   away the buffer, so don't reverse these two lines:
   ```bash
   jcmd <pid> JFR.dump name=manual-<pid> filename=/tmp/jfr-manual-<pid>-$(date +%Y%m%d-%H%M%S).jfr
   jcmd <pid> JFR.stop name=manual-<pid>
   ```

3. **Report the exact file path back to the user**, and point them at the
   `jfr-analyze` skill to read it (e.g. "run the jfr-analyze skill against
   that file to see what it caught").

## Rules

- Target must be a real, running JVM reachable by `jcmd` from this
  shell/user — for a container/pod, run inside its namespace (`docker
  exec`/`kubectl exec`), not from the host.
- Always dump before stop, never the reverse.
- Don't invent a different recording name per call — sticking to
  `manual-<pid>` is what lets `stop` find `start`'s recording without any
  memory of the earlier call.

## Troubleshooting

- `jcmd <pid> VM.version` fails — wrong pid, not a JVM, or a
  permissions/namespace mismatch (different user, or the pid is inside a
  container and you're running from the host).
- `JFR.check` shows nothing named `manual-<pid>` on stop — it was never
  started, already stopped, or this is the wrong pid. Don't fabricate a dump.
- `JFR.start` errors "already exists" — a `manual-<pid>` recording is
  already running; either stop it first or just let the existing one keep
  going.
- Recording started but `hot-methods`/`allocation-by-class` come back empty
  later in `jfr-analyze` — check `settings=profile` was actually used, not
  `default` (see step 3 above).
