---
name: jfr-live-monitor
description: >-
  Use when the user wants to watch a running Java/Spring Boot process for hot
  methods, GC pressure, or memory allocation live/repeatedly — e.g. "is this
  process CPU-bound right now", "poll the JVM every 30s", "live monitor this
  pid", "keep an eye on GC while load is running". Polls a rolling JFR
  recording on the target pid via jcmd + jfr view — no APM agent, no restart
  of the target JVM, no JMX setup required. Also ships a standalone
  companion, heap-dump-on-oom.sh, for catching an actual
  OutOfMemoryError — jfr view can't see that event at all.
license: MIT
compatibility: "Requires JDK 21+ on PATH for jfr view (added in 21) — bring your own JDK; point JFR_BIN/JCMD_BIN at one if PATH's isn't 21+. The target app doesn't need JDK 21+, only this tool does."
metadata:
  author: kaushik912
  version: "1.0.0"
  category: development
  tags: ["jfr", "jvm", "profiling", "gc", "monitoring", "diagnostics", "cli"]
---
# JFR Live Monitor — Poll a Running JVM's Hot Methods / GC

## Overview

Watches a live JVM without an APM agent, JMX, or a restart: starts one
rolling JFR recording on the target pid, then on a timer dumps just the
trailing window and renders it with `jfr view` (`hot-methods`, `gc`, etc).
Each cycle shows *recent* activity only, not a lifetime average, so a hot
method or GC spike shows up as it happens.

JDK 21+ is required for `jfr view` (added in 21) — bring your own. The
script checks `jfr` on `PATH` and exits with a clear error naming the
detected version if it's too old; point `JFR_BIN`/`JCMD_BIN` at a 21+
install if PATH's isn't one. No JDK management here on purpose — this script
does one thing (JFR analysis), not JDK installation.

## Usage

Find the pid first (`jps -l`), then:

```bash
./jfr-monitor.sh <pid> [interval_seconds=30] [window_seconds=60]
```

Ctrl+C stops cleanly (stops the recording it started, removes its temp dump
file). Reuses an already-running `jfr-live-monitor` recording on that pid
instead of erroring if one exists.

Env overrides:
- `JFR_BIN` / `JCMD_BIN` — path to `jfr`/`jcmd`, if the ones on `PATH`
  aren't JDK 21+ (or aren't on `PATH` at all).
- `JFR_VIEWS` — comma-separated `jfr view` names per cycle. Default
  `hot-methods,gc` (CPU hot loop + GC pressure). Other views worth trying:
  `gc-pauses` (a statistical summary — total/count/min/median/avg/P90 pause
  time — instead of a long per-GC table) and `memory-leaks-by-class`
  (samples of objects that have survived a while; see the OOM section below
  for what it can and can't tell you).
- `JFR_MAXSIZE` — disk cap for the rolling recording. Default `200m`.

This script is purely `jfr view`-based and doesn't touch any JVM flags —
for catching an actual `OutOfMemoryError`, see `heap-dump-on-oom.sh` below.

## Running it as an agent

Prefer a bounded run over an open-ended one: `timeout <seconds>
./jfr-monitor.sh <pid> ...`, so the tool call finishes and its full
transcript is available to read and summarize in one pass. For a longer
watch the user explicitly wants left running, start it with a background
task instead and check its output periodically — don't just dump raw tables
back at the user; interpret them (see below) each time you read new output.

## Interpreting results

Don't just relay the raw tables — read them and say what they mean.

**`hot-methods`**: look at the top row's `Percent`. If one method — especially
application code, not `java.lang.*`/`jdk.internal.*` — holds a large,
standalone share (rule of thumb: >20-30%, clearly ahead of the rest), name it
as the likely hot path. JDK-internal methods just below it (e.g.
`String.equals`, `ArrayList.indexOf`) are usually what that method's inner
loop is calling — mention them together, not as separate findings. If no
single method stands out, say so plainly instead of guessing a culprit.

**`gc`**: compare `Heap Before GC` to `Heap After GC` across consecutive
rows. If `After` stays close to `Before` (GC reclaiming little), that's a
real memory-pressure signal, not just churn — say so. Watch `Longest Pause`
for a climbing trend alongside growing heap size — that combination is worse
than either alone. `No events found` for a cycle is normal (nothing
GC-worthy happened in that window), not an error — don't flag it as one.
(`Longest Pause` already *is* the raw `jdk.GCPhasePause` duration for that
GC — no need to also `jfr print --events jdk.GCPhasePause`, same number.)

If both signals are strong in the same run, call out that the process may be
both CPU- and memory-bound rather than picking one.

## How it works

`window_seconds` becomes the recording's `maxage`, so JFR discards older
chunks and it behaves as a ring buffer instead of growing forever.
`interval_seconds` is how often it's dumped and rendered — keep `window`
larger than `interval` so polls overlap rather than leaving gaps.
`settings=profile` (not `default`) is used so both method and allocation
sampling are on.

## Rules

- Target must be a real, running JVM reachable by `jcmd` from this
  shell/user — for a container/pod, run inside its namespace
  (`docker exec`/`kubectl exec`), not from the host.
- Don't drop `interval_seconds` below a few seconds — each cycle is a real
  `JFR.dump`, and there's no extra signal from polling faster.

## Catching an actual OutOfMemoryError

`jdk.JavaErrorThrow` — the event `jfr view`/`print` would otherwise use to
catch a thrown error — explicitly ignores `OutOfMemoryError` (the JDK's own
event metadata says so: *"OutOfMemoryErrors are ignored"*). Not a views bug;
the event genuinely isn't there. Neither `hot-methods` nor `gc` will ever
show an OOM happening.

`memory-leaks-by-class`/`memory-leaks-by-site` (backed by
`jdk.OldObjectSample`) looked like it might substitute, since it samples
objects that survive a while. Tested against this repo's actual OOM bug
(`resource-exhaustion-demo`, `MemoryHogService.buildReport`) and it doesn't:
across two runs (21 and lower sample counts) **zero** samples named the
actual culprit class or call site — every one was Tomcat/framework noise
(`Http11OutputBuffer`, `ConcurrentHashMap` internals, class loading), and
every sample's `root` field (the reference-chain-to-GC-root info) came back
`N/A`. Reservoir sampling just doesn't get a fair chance against a fast
crash — it might do better for a genuinely slow leak (hours, not seconds),
but don't rely on it for the crash case.

Also tried `jcmd <pid> JFR.dump ... path-to-gc-roots=true` (a one-off dump
option, not something for `jfr-monitor.sh`'s routine poll loop — the JDK
docs say it "creates overhead similar to a full garbage collection"). It
does populate `root` for *some* samples (previously always `N/A`) with real
thread/class-loader reference chains — but `MemoryHogService` still never
showed up, and the actual request thread's objects stayed `N/A` too. It adds
depth to whatever gets sampled, not a fair shot at catching the actual
culprit in a fast crash. Same conclusion holds.

**What does work**: `heap-dump-on-oom.sh <pid> [path]` in this same
directory — a standalone script, no JFR or JDK 21+ needed, just `jcmd`.
Enables `HeapDumpOnOutOfMemoryError` live via `jcmd`'s `{manageable}` flags
(no restart), so the *next* OOM on that pid writes a real `.hprof` you can
open in Eclipse MAT or JMC and see the actual retained object graph. Turn it
off again with `heap-dump-on-oom.sh <pid> --off`.

```bash
./heap-dump-on-oom.sh 12345 /var/diagnostics/heap.hprof   # enable
./heap-dump-on-oom.sh 12345 --off                          # disable
```

Not automatic, not bundled into `jfr-monitor.sh` — a heap dump is roughly
the size of `-Xmx` (100MB heap → 117MB dump, ~1.9GB heap → 2.75GB dump, both
measured against this repo's demo), and if the target's `$TMPDIR` is tmpfs
(common in containers) that write competes with the app for the same RAM
right when it's already under pressure. Point it at real disk with headroom
before enabling, and think about whether you want this running before you
turn it on.

## Troubleshooting

- `'jfr' not found on PATH` / `doesn't support 'jfr view'` — no JDK 21+
  available. Install one and put it on `PATH`, or set
  `JFR_BIN=/path/to/jdk21/bin/jfr` (and `JCMD_BIN` alongside it).
- `no process with pid ...` — wrong pid, or a different container/namespace.
- `AttachNotSupportedException` — target isn't a JVM (check `jcmd <pid>
  VM.version` works alone first).
- `(no data for '<view>' yet)` — normal for the first cycle or two.
- `heap-dump-on-oom.sh`: `couldn't set the flags on pid ...` — check they're
  actually `{manageable}` on that JVM (`jcmd <pid> VM.flags -all | grep
  HeapDump`); if not, it has to go on the JVM's own startup command line
  instead (`-XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=...`).
