# VisualVM Evidence Guide

VisualVM is the interactive layer of this laboratory. JFR, k6, Actuator, Docker stats, and `jcmd` are captured automatically; VisualVM is used to create a small set of curated visual artifacts that explain the behavior.

Use a current standalone VisualVM release. VisualVM 2.2 introduced virtual-thread metrics, and 2.2.1 supports JDK versions through JDK 25.

## Automated native session

VisualVM attaches most reliably to a JVM started by the same host user. The helper runs the simulator in Docker and the selected checkout implementation natively.

Start MVC:

```bash
labs/01-loom-vs-reactive-checkout/scripts/visualvm-session.sh start mvc-vthreads
```

Start WebFlux instead:

```bash
labs/01-loom-vs-reactive-checkout/scripts/visualvm-session.sh start webflux-reactor
```

The command:

- builds the selected module;
- starts the simulator;
- launches the checkout JVM with a stable `visualvm.id`;
- records the PID and environment;
- waits for readiness;
- opens VisualVM automatically when the `visualvm` command is installed.

Run the measured window:

```bash
labs/01-loom-vs-reactive-checkout/scripts/visualvm-session.sh load moderate
```

Stop the session:

```bash
labs/01-loom-vs-reactive-checkout/scripts/visualvm-session.sh stop
```

Session files are stored under:

```text
.artifacts/visualvm/<SESSION_ID>/
```

## VisualVM configuration

Before the first capture:

1. use the same VisualVM version for both implementations;
2. use the same JDK to run VisualVM;
3. keep the same window size and chart time range;
4. install no experimental plugin during one side of a pair only;
5. use CPU **sampling**, not instrumentation, for comparative evidence;
6. use the same sampling interval and class filters;
7. do not take a heap dump during the measured load window.

Recommended optional plugins:

- Visual GC for a richer GC timeline;
- Threads Inspector for focused stack analysis;
- MBeans Browser when inspecting Micrometer/JMX behavior.

## Optional curated visual artifacts

Capture the same views at equivalent points for MVC and WebFlux.

### 1. Overview / JVM identity

Filename:

```text
<RUN_ID>-visualvm-overview-before.png
```

Must show:

- process name and PID;
- JDK version;
- JVM arguments;
- system properties or runtime identity sufficient to connect the image to the run.

Supports: proof that the correct process and Java runtime were inspected.

### 2. Monitor plateau during measured load

Filename:

```text
<RUN_ID>-visualvm-monitor-measured.png
```

Must show the complete measured plateau with:

- CPU;
- heap and metaspace;
- loaded classes;
- thread counts;
- GC activity;
- virtual-thread metrics when shown by the installed VisualVM version.

Supports: shape and stability of resource behavior. It does not prove causality by itself.

### 3. CPU sampler snapshot

Filename:

```text
<RUN_ID>-visualvm-cpu-sampler.nps
<RUN_ID>-visualvm-cpu-hot-methods.png
```

Procedure:

1. start CPU sampling immediately before the measured k6 window;
2. exclude obvious VisualVM/JMX plumbing only if the same filter is used for both implementations;
3. take a sampler snapshot at the end;
4. sort by self time and then total time;
5. save the `.nps` snapshot and one screenshot of the top methods.

Supports: where sampled CPU time appeared during this run.

### 4. Memory sampler snapshot

Filename:

```text
<RUN_ID>-visualvm-memory-sampler.nps
<RUN_ID>-visualvm-memory-allocations.png
```

Capture allocation-by-class after warm-up and during the measured window. Save the snapshot and a screenshot containing the highest allocation contributors.

Supports: allocation shape. It is not a retained-heap or leak conclusion.

### 5. Threads timeline

Filename:

```text
<RUN_ID>-visualvm-threads-measured.png
```

Show the full measured interval and preserve the legend. For MVC, include the virtual-thread metrics panel when available. For WebFlux, include the event-loop and worker-thread behavior.

Supports: runtime concurrency shape and blocking/parking patterns visible to the tool.

### 6. Thread dump at an outlier or degraded dependency

Filename:

```text
<RUN_ID>-visualvm-thread-dump.tdump
<RUN_ID>-visualvm-thread-dump-highlight.png
```

Take the dump only when it answers a question, such as a slow payment dependency or p99 spike. Save the raw dump and a screenshot highlighting the relevant stack.

Supports: a point-in-time stack state. It does not represent the entire run.

### 7. Optional Visual GC capture

Filename:

```text
<RUN_ID>-visualvm-visual-gc-measured.png
```

Capture only when the view adds evidence beyond the automated JFR GC and allocation reports.

### 8. Application snapshot

Filename:

```text
<RUN_ID>-visualvm-application.apps
```

Save an application snapshot after attaching the sampler snapshots and thread dump. This allows offline review of the curated session.

## Heap dump policy

A heap dump is **not required** for the normal Loom-vs-Reactor comparison. It is intrusive, large, and answers a different question. Capture one only after the measured window when investigating retained memory or a suspected leak:

```text
<RUN_ID>-visualvm-post-load.hprof
```

Publish heap dumps only as private or release assets after sanitization.

## Screenshot context sidecar

For every PNG, create a Markdown sidecar with the same base name:

```markdown
Run ID:
Implementation:
Scenario:
Git SHA:
Capture phase and elapsed time:
k6 rate and duration:
Simulator settings:
Observation supported:
What this image does not prove:
```

## Command-line helpers

VisualVM supports opening a PID, taking thread and heap dumps, starting CPU or memory sampling, saving a sampler snapshot, and starting or dumping JFR from its launcher. Useful examples:

```bash
visualvm --openpid <PID>
visualvm --threaddump <PID>
visualvm --start-cpu-sampler <PID>
visualvm --snapshot-sampler <PID>
visualvm --stop-sampler <PID>
visualvm --openfile <recording.jfr>
```

Use GUI screenshots only for views that support an explicit written observation. A screenshot without run identity and interpretation is decoration, not evidence. The v1.0.0 quantitative release does not require screenshots: structured JSON/CSV/JFR remains canonical, and generated Mermaid charts may visualize those aggregates without replacing their source data.
