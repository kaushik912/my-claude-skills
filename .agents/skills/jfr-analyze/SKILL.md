---
name: jfr-analyze
description: >-
  Use when the user has a finished `.jfr` recording and wants it read —
  "analyze this jfr file", "what's slow in this recording", "run a CPU/
  memory/GC/IO analysis on this JFR dump", "is this recording CPU-bound or
  memory-bound". Runs a structured, category-by-category report (CPU,
  Memory/Allocation, GC, I/O, plus a short Locking/Exceptions bonus pass)
  entirely with the JDK's own `jfr view`/`jfr print` commands — no extra
  script, no APM agent. Complements the jfr skill (produces the recording)
  and jfr-live-monitor (watches a JVM live instead of reading a finished file).
license: MIT
compatibility: "Requires JDK 21+ on PATH for `jfr view` (added in 21) — point JFR_BIN at one if PATH's isn't. The recording itself can come from any JDK version; JFR's file format is forward-compatible, so a JDK 17/11-recorded .jfr reads fine with a JDK 21+ jfr tool."
metadata:
  author: kaushik912
  version: "1.0.0"
  category: development
  tags: ["jfr", "jvm", "profiling", "gc", "cpu", "memory", "io", "analysis", "diagnostics"]
---
# JFR Analyze — Structured CPU/Memory/GC/IO Report From a Recording

## Overview

Given a `.jfr` file, walk through it category by category using `jfr view`
(pre-built report templates — no hand-parsing `jfr print` output) and, where
a view alone won't show *who* is responsible, `jfr print` with a stack
trace. All commands here are read-only against the file — nothing touches
a live JVM, so this works equally well on a file just produced by the `jfr`
skill or one pulled off a remote box.

Don't just relay raw tables back to the user — every section below says
what to look for and what it means. End with the synthesis in
[Putting it together](#putting-it-together) so the user gets a verdict, not
just four tables.

## Usage

```bash
jfr view <view-name> <file.jfr>
jfr print --events <event-name> --stack-depth 5 <file.jfr>
```

**Start with a sanity check** before diving into categories:
```bash
jfr summary <file.jfr>
```
This shows the recording's duration and a count per event type. If
`jdk.ExecutionSample` or `jdk.ObjectAllocationSample` show 0 (or are
missing), the recording was taken with `settings=default` instead of
`settings=profile` — say so up front, because the CPU and Memory sections
below will come back empty through no fault of the code being profiled.

## CPU

```bash
jfr view hot-methods <file.jfr>
jfr view thread-cpu-load <file.jfr>
jfr view cpu-load <file.jfr>
jfr view cpu-information <file.jfr>
```

- **`hot-methods`**: ranked methods by sample count. If one method —
  especially application code, not `java.lang.*`/`jdk.internal.*` — holds a
  large, standalone share (rule of thumb: >20-30%, clearly ahead of the
  rest), name it as the likely hot path. JDK-internal methods just below it
  (e.g. `String.equals`, `ArrayList.indexOf`) are usually what that method's
  inner loop is calling — mention them together, not as separate findings.
- **`thread-cpu-load`**: per-thread CPU%. One thread pinned near 100% while
  others idle points at a single-threaded hot loop (matches `top -H -p
  <pid>` showing one thread pegged, per the resource-exhaustion bug notes).
- **`cpu-load`** / **`cpu-information`**: overall process/machine CPU and
  core count — needed context for the above (100% of one core on an 8-core
  box is very different from 100% of one core on a 1-core container).
- If no single method stands out and CPU load is unremarkable, say so
  plainly instead of guessing a culprit.

## Memory / Allocation

```bash
jfr view allocation-by-class <file.jfr>
jfr view allocation-by-site <file.jfr>
jfr view allocation-by-thread <file.jfr>
jfr view heap-configuration <file.jfr>
```

- **`allocation-by-class`**: which class is generating the most allocation
  pressure (`byte[]` at the top is the classic "unbounded row-materializing
  loop" signature).
- **`allocation-by-site`**: which call site/stack is doing that allocating —
  this is usually the more actionable of the two, since it names the method,
  not just the type.
- **`allocation-by-thread`**: worth a glance if allocation is concentrated
  in one request-handling thread vs spread across a pool.
- **`heap-configuration`**: `-Xmx`/initial heap and the collector in use —
  context for whether the allocation volume above is actually close to a
  ceiling.

**Leak detection caveat** — `memory-leaks-by-class` / `memory-leaks-by-site`
(backed by `jdk.OldObjectSample`) sample objects that have survived a while,
but reservoir sampling doesn't get a fair shot against a *fast* crash:
tested against this repo's own OOM bug, it never once named the actual
culprit class across multiple runs — every sample was framework noise. Only
trust these two for a genuinely slow leak (hours, not seconds); for a fast
OOM, `allocation-by-site` above plus the GC section below is the reliable
signal. JFR also cannot see the `OutOfMemoryError` event itself — the JDK's
own event metadata excludes it. If the user needs the actual crash and a
heap dump, that's `heap-dump-on-oom.sh` from the jfr-live-monitor skill, not
this one.

## GC

```bash
jfr view gc <file.jfr>
jfr view gc-pauses <file.jfr>
jfr view gc-configuration <file.jfr>
jfr view gc-cpu-time <file.jfr>
```

- **`gc`**: per-collection table, heap-before vs heap-after vs pause
  duration. If **Heap After** stays close to **Heap Before** across
  consecutive rows (GC reclaiming little) while **Longest Pause** climbs,
  that's a real memory-pressure signal, not just churn — say so plainly.
- **`gc-pauses`**: the same signal as a statistical summary (count / min /
  median / avg / P90) instead of a long per-GC table — good for a quick
  headline number.
- **`gc-configuration`**: which collector and generational setup is active
  — relevant before judging whether pause behavior is normal for that
  collector.
- **`gc-cpu-time`**: what share of total CPU time GC itself is consuming —
  a high, sustained number here means GC is competing with the app's own
  threads for cores, which shows up as slowness even when no single
  application method looks "hot" in the CPU section above.

## I/O

```bash
jfr view file-reads-by-path <file.jfr>
jfr view file-writes-by-path <file.jfr>
jfr view socket-reads-by-host <file.jfr>
jfr view socket-writes-by-host <file.jfr>
jfr print --events jdk.FileRead,jdk.FileWrite,jdk.SocketRead,jdk.SocketWrite --stack-depth 5 <file.jfr>
```

- The four `*-by-path`/`*-by-host` views aggregate reads/writes and their
  durations, grouped by what was touched — good for spotting one path or
  host that's consistently slow.
- The `jfr print` line above is the drill-down: with `settings=profile`,
  file/socket read and write events are only recorded once they cross a
  threshold (10ms on this JDK's `profile.jfc`), so **every event that shows
  up here is already a slow one** — no need to hunt for a "top" one, name
  whatever's printed. `--stack-depth 5` shows which application code issued
  the slow call.
- A thread blocked on I/O is idle, not "hot" — this is the one category
  `hot-methods` structurally cannot catch, so don't skip it just because CPU
  looked clean.

```bash
jfr print --events jdk.ThreadSleep,jdk.ThreadPark --stack-depth 5 <file.jfr>
```

- **`jdk.ThreadSleep`/`jdk.ThreadPark`**: a thread parked or sleeping without
  a corresponding file/socket event isn't doing real file/socket I/O — it's
  blocked on something else (a simulated delay, a rate limiter, a retry
  backoff, or — see below — a "real" call that just isn't instrumented as
  socket I/O). Don't mistake it for the signal above. Read the stack for the
  application call site, and check the event's thread name: a pool meant to
  be isolated (e.g. a dedicated `@Async` executor) should show its own
  thread-name prefix, not the web server's request-handling threads
  (`http-nio-*-exec-*`) — if request threads show up parked/sleeping, that
  pool is being held hostage by a blocking call instead of the work being
  offloaded.
- **Gotcha, confirmed against a real recording**: `java.net.http.HttpClient`'s
  synchronous `send()` does *not* generate `jdk.SocketRead`/`jdk.SocketWrite`
  events, even for a genuine outbound HTTP call — its "synchronous" API is
  built on the same async NIO internals as the rest of the client, and the
  calling thread just blocks on a `CompletableFuture.get()`. JFR records that
  as `jdk.ThreadPark`, stack bottoming out at
  `jdk.internal.net.http.HttpClientImpl.send(...)` via
  `CompletableFuture.waitingGet`/`ForkJoinPool.managedBlock`. If you're
  chasing a known-blocking `HttpClient` call and the file/socket views come
  back empty, check `jdk.ThreadPark` before concluding there's no I/O
  bottleneck — the socket views only catch clients whose blocking API is a
  literal blocking read, not everything that blocks.

## Bonus: Locking & Exceptions

Quick, cheap checks worth a glance even outside a specific CPU/Memory/GC/IO
investigation — both are common causes of "slow but not CPU-hot and not
GC-heavy":

```bash
jfr view contention-by-class <file.jfr>
jfr view contention-by-site <file.jfr>
jfr view exception-count <file.jfr>
jfr view exception-by-site <file.jfr>
```

- **`contention-by-class`/`contention-by-site`**: threads waiting on a lock
  instead of doing work — shows up as slow requests with unremarkable CPU
  and GC numbers, because the thread is parked, not spinning.
- **`exception-count`/`exception-by-site`**: a high count concentrated at
  one site usually means exceptions are being used for control flow (each
  throw fills in a stack trace, which isn't free) — worth flagging even
  though it's neither a CPU, memory, GC, nor I/O finding on its own.

## Putting it together

Close with a verdict, not just four/six tables — name what kind of problem
this recording shows, using the same shape as the bug-fix notes' signal
table:

| Signal seen | Points to |
|---|---|
| One non-JDK method dominates `hot-methods`, one thread pinned near 100% in `thread-cpu-load` | **CPU-bound** — an inefficient algorithm, not a resource leak |
| `allocation-by-site` dominated by one call site, `gc` shows Heap After ≈ Heap Before and climbing pauses | **Memory-bound** — likely an unbounded accumulation, check that call site for a missing stream/page/limit |
| `gc-cpu-time` high/sustained but no single hot method | **GC-bound** — the heap is undersized or churn is too high for the allocation rate, even without a leak |
| Slow events in `file-reads-by-path`/`socket-*` or the `jfr print` drill-down, CPU otherwise idle | **I/O-bound** — a downstream call or disk read is the bottleneck, not application code |
| `jdk.ThreadSleep`/`jdk.ThreadPark` events present with no corresponding `jdk.FileRead`/`jdk.FileWrite`/`jdk.SocketRead`/`jdk.SocketWrite` events, CPU otherwise idle | **Blocked on something other than instrumented file/socket I/O** — a simulated delay, rate limiter, backoff, or a blocking client (like `HttpClient.send()`) whose wait doesn't register as a socket event; check the thread name to see whether it's a request-handling thread (pool held hostage) or an isolated worker (correctly isolated) |
| Contention views show real wait time, CPU/GC/IO otherwise unremarkable | **Lock-bound** — threads are queued behind a lock, not doing or waiting on real work |
| Nothing above stands out | Say so plainly — a clean recording is a valid, useful answer |

More than one of these can be true at once (e.g. sorting a huge in-memory
dataset is CPU work *and* memory work at the same time) — call out overlap
rather than forcing a single label.

## Troubleshooting

- `jfr: 'view' is not a jfr command` / `unknown command 'view'` — the `jfr`
  on `PATH` predates JDK 21. Point at a 21+ install directly, e.g.
  `/usr/lib/jvm/java-21-openjdk-amd64/bin/jfr view ...`. The `.jfr` file
  itself doesn't need to be re-recorded — only the tool reading it needs to
  be 21+.
- A view runs but every table is empty — check `jfr summary` first (see
  Usage above): if `jdk.ExecutionSample`/`jdk.ObjectAllocationSample` counts
  are 0, the recording was taken with `settings=default`, not `profile`,
  and CPU/allocation sampling was simply off the whole time.
- `Unknown view` error for a view name — run `jfr view` with no view/file
  arguments to print the current JDK's full list of valid names; they've
  shifted slightly across JDK versions (e.g. `file-reads-by-path` used to
  need a different name on older previews).
