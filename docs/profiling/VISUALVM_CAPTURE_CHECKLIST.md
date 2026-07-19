# Optional VisualVM Capture Checklist

Use the same VisualVM version, screen dimensions, sampling intervals, and measured scenario for both implementations.

## Optional per implementation

- [ ] Overview before measured load: `<RUN_ID>-visualvm-overview-before.png`
- [ ] Monitor plateau: `<RUN_ID>-visualvm-monitor-measured.png`
- [ ] CPU sampler snapshot: `<RUN_ID>-visualvm-cpu-sampler.nps`
- [ ] CPU hot methods screenshot: `<RUN_ID>-visualvm-cpu-hot-methods.png`
- [ ] Memory sampler snapshot: `<RUN_ID>-visualvm-memory-sampler.nps`
- [ ] Allocation screenshot: `<RUN_ID>-visualvm-memory-allocations.png`
- [ ] Threads timeline: `<RUN_ID>-visualvm-threads-measured.png`
- [ ] Application snapshot: `<RUN_ID>-visualvm-application.apps`

## Conditional

- [ ] Thread dump and highlighted stack when investigating an outlier
- [ ] Visual GC screenshot when it adds information beyond JFR
- [ ] Post-load heap dump only for a retained-memory question

## Sidecar required for every screenshot

```text
Run ID:
Implementation:
Scenario:
Git SHA:
Capture phase:
Elapsed time:
k6 configuration:
Simulator settings:
Observation supported:
Alternative explanation:
What this image does not prove:
```
