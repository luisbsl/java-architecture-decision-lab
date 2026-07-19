# Evidence Suite Audit

- Status: **PASS**
- Protocol version: `4`
- Audit policy version: `2`
- Controlled-workload boundary tolerance: `±1 iteration`
- Audit script SHA-256: `81406378a878511f21df5fdf8e40c07fa541e2b38275a4fc19158424130f8968`
- Runs audited: **16**
- Failed runs: **0**

## Global warnings

- `controlled_workload_boundary_iteration_delta:high:3:delta=1`
- `controlled_workload_boundary_iteration_delta:moderate:2:delta=1`
- `controlled_workload_boundary_iteration_delta:moderate:4:delta=1`

All per-run manifests, measured-window bounds, stats lifecycle, dropped-iteration gates, JFR bounds, Git/protocol identity, and paired controlled-workload gates passed.
A one-iteration scheduler-boundary delta is accepted only when both runs remain within ±1 iteration of the configured rate × measured duration; any larger deviation fails closed.
