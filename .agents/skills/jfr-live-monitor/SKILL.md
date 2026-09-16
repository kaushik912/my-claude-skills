---
name: jfr-live-monitor
description: >-
  Use when the user wants to watch a running Java/Spring Boot process for hot
  methods, GC pressure, or memory allocation live/repeatedly — e.g. "is this
  process CPU-bound right now", "poll the JVM every 30s", "live monitor this
  pid", "keep an eye on GC while load is running". Polls a rolling JFR
  recording on the target pid via jcmd + jfr view — no APM agent, no restart
  of the target JVM, no JMX setup required.
license: MIT
compatibility: "Requires SDKMAN (https://sdkman.io) installed — loads its own JDK 21+ toolchain from this skill's .sdkmanrc for jfr view; the target app doesn't need JDK 21+, only this tool does."
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

JDK 21+ is required for `jfr view` — loaded automatically via SDKMAN from
this skill's `.sdkmanrc`, unconditionally, no env var to override it. If
SDKMAN isn't installed the script exits with install instructions instead of
falling through to whatever `jfr` is on `PATH`. To change the JDK version,
edit `.sdkmanrc` directly.

## Usage

Find the pid first (`jps -l`), then:

```bash
./jfr-monitor.sh <pid> [interval_seconds=30] [window_seconds=60]
```

Ctrl+C stops cleanly (stops the recording it started, removes its temp dump
file). Reuses an already-running `jfr-live-monitor` recording on that pid
instead of erroring if one exists.

Env overrides:
- `JFR_VIEWS` — comma-separated `jfr view` names per cycle. Default
  `hot-methods,gc` (CPU hot loop + GC pressure).
- `JFR_MAXSIZE` — disk cap for the rolling recording. Default `200m`.

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

## Troubleshooting

- `SDKMAN not found` — install it, open a new shell, re-run.
- `SDKMAN didn't resolve a usable JDK` — candidate pinned in `.sdkmanrc`
  isn't installed; run `sdk env install` in the skill directory.
- `doesn't support 'jfr view'` — `.sdkmanrc` is pinned to a pre-21 Java.
- `no process with pid ...` — wrong pid, or a different container/namespace.
- `AttachNotSupportedException` — target isn't a JVM (check `jcmd <pid>
  VM.version` works alone first).
- `(no data for '<view>' yet)` — normal for the first cycle or two.
