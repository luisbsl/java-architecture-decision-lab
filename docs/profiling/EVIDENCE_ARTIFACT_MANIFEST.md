# Evidence Artifact Manifest

## Automatically required per run

| Artifact | Purpose | Commit to Git? |
|---|---|---|
| `run.env` | immutable run identity and workload configuration | curated copy |
| `environment.txt` | OS, JDK, CPU, memory, Docker, k6 | sanitized excerpt |
| `docker-compose-effective.yml` | actual runtime configuration | yes, when sanitized |
| `load/k6-summary.json` | authoritative aggregated HTTP metrics | yes |
| `load/k6-points.json.gz` | timestamped raw k6 data | release asset |
| `docker-stats.csv` | CPU, memory, network, block I/O, PIDs | yes |
| `before-*`, `after-*` | JVM and Actuator snapshots | selected files |
| `recording.jfr` | JVM event evidence | release asset |
| `jfr-reports/*.txt` | human-readable JFR views | yes |
| `jfr-reports/jfr-metrics.json` | structured JFR values consumed by documentation automation | yes |
| `jfr-reports/JFR_METRICS.md` | generated per-run JFR summary and top contributors | yes |
| `compose-logs.txt` | correlated operational evidence | sanitized excerpt |
| `container-inspect.json` | runtime image and container metadata | sanitized excerpt |
| `run-summary.json` | normalized machine-readable summary | yes |
| `RUN_SUMMARY.md` | generated human-readable run summary | yes |
| `comparison-aggregates.json` | grouped suite statistics used by generated docs | yes |
| `COMPARISON.md` | generated HTTP, container, and JFR comparison | yes |
| `manifest.sha256` | artifact integrity | yes |

## Optional VisualVM supplemental captures

See `visualvm-setup.md` for the optional screenshot and snapshot checklist. VisualVM evidence supplements JFR; it does not replace the automated pipeline and is not required for the quantitative v1.0.0 scope.

## Sanitization

Before publication, inspect all artifacts for:

- usernames and absolute home paths;
- hostnames and IP addresses;
- environment variables and credentials;
- proprietary source paths;
- tokens in HTTP headers;
- excessively large binary files.
