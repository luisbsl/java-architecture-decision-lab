# Curated Evidence

This directory contains small, sanitized, reviewable evidence generated from formal suites.

The latest materialized suite is linked from [`LATEST.md`](LATEST.md).

Each suite contains:

```text
docs/results/evidence/<SUITE_ID>-paired-evidence/
├── README.md
├── COMPARISON.md
├── FACTUAL_OBSERVATIONS.md
├── comparison.csv
├── comparison-aggregates.json
├── curated-manifest.sha256
├── suite.env
└── runs/
    └── <RUN_ID>/
        ├── RUN_SUMMARY.md
        ├── run-summary.json
        └── jfr-reports/
            ├── JFR_METRICS.md
            └── jfr-metrics.json
```

Validate the latest curated suite:

```bash
make -C labs/01-loom-vs-reactive-checkout evidence-validate
```

Do not commit raw `.jfr`, `.hprof`, full k6 point streams, or unsanitized logs. Attach large binaries to a release and reference their SHA-256 manifest.
