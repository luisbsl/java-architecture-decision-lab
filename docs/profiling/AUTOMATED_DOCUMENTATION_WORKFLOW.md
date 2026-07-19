# Automated Evidence Documentation Workflow

> Evidence is generated from immutable artifacts. Published numeric tables must not be assembled by copy and paste.

## Goal

The pipeline turns each bounded measurement into three layers:

```text
recording.jfr + k6 + Docker Stats + Actuator
                ↓
structured machine-readable evidence
                ↓
curated Markdown and comparative documentation
```

The numeric source of truth is:

```text
run-summary.json
jfr-reports/jfr-metrics.json
comparison-aggregates.json
```

VisualVM and JDK Mission Control reopen the same raw `recording.jfr` for interactive investigation. Screenshots are optional explanatory artifacts, not the source used to type values into tables.

## One command after a completed suite

```bash
make -C labs/01-loom-vs-reactive-checkout evidence-docs \
  SUITE_DIR=.artifacts/evidence/<SUITE_ID> \
  UPDATE_ANALYSIS=1
```

Equivalent direct command:

```bash
labs/01-loom-vs-reactive-checkout/scripts/materialize-evidence-docs.sh \
  .artifacts/evidence/<SUITE_ID> \
  --update-analysis
```

The command:

1. streams each `recording.jfr` through the JDK Flight Recorder consumer API;
2. produces bounded `jfr-metrics.json` and `JFR_METRICS.md` files;
3. rebuilds each `run-summary.json` and `RUN_SUMMARY.md`;
4. creates run-level `comparison.csv`;
5. creates grouped `comparison-aggregates.json` and `COMPARISON.md`;
6. exports curated, small evidence to `docs/results/evidence/<SUITE_ID>/`;
7. updates the evidence overview, complete per-run table, aggregate table, and neutral factual-observation blocks in `docs/results/01-loom-vs-reactive-analysis.md`;
8. creates `FACTUAL_OBSERVATIONS.md` and a stable `docs/results/evidence/LATEST.md` pointer;
9. validates `curated-manifest.sha256` automatically before returning success;
10. preserves every manually written hypothesis, inference, alternative explanation, limitation, and decision outside managed blocks.

## Managed Markdown contract

Generated content uses three explicit contracts:

```markdown
<!-- BEGIN AUTO-GENERATED:EVIDENCE -->
...
<!-- END AUTO-GENERATED:EVIDENCE -->

<!-- BEGIN AUTO-GENERATED:QUANTITATIVE-EVIDENCE -->
...
<!-- END AUTO-GENERATED:QUANTITATIVE-EVIDENCE -->

<!-- BEGIN AUTO-GENERATED:FACTUAL-OBSERVATIONS -->
...
<!-- END AUTO-GENERATED:FACTUAL-OBSERVATIONS -->
```

Never write manual interpretation inside those markers. The next materialization replaces them. The factual-observation block states measured relationships only; it does not assert causality or choose an architecture.

## Structured JFR metrics

The extractor records, when available:

- bounded recording duration;
- JVM CPU average and p95;
- allocation sample weight and estimated allocation pressure;
- GC count, total pause, and longest pause;
- active platform-thread average and maximum;
- thread park, monitor-enter, virtual-thread pinning, and submit-failure events;
- socket read/write counts, bytes, and duration;
- JFR data-loss events;
- top allocation classes and sites;
- top sampled CPU methods;
- top thread-park sites.

### Important semantics

`ObjectAllocationSample.weight` is a statistically weighted estimate of allocation pressure. It is not retained heap and it must not be labeled as exact allocation bytes.

A zero event count means no event was observed **above the configured threshold during that measured window**. It is not proof that the behavior is impossible.

## Formal publication gates

The default materialization refuses to publish when:

- the suite is incomplete;
- a completed run has no raw `recording.jfr`;
- a completed run has no k6 summary;
- the Git SHA is missing or `unknown`.

Diagnostic preview only:

```bash
labs/01-loom-vs-reactive-checkout/scripts/materialize-evidence-docs.sh \
  .artifacts/evidence/<SUITE_ID> \
  --allow-partial \
  --allow-unknown-git
```

Do not commit or release a preview as formal comparative evidence.

## Rebuild old recordings

When the extraction schema changes, regenerate JFR views and structured metrics without rerunning load:

```bash
make -C labs/01-loom-vs-reactive-checkout evidence-docs \
  SUITE_DIR=.artifacts/evidence/<SUITE_ID> \
  REFRESH_JFR=1
```

This is valid only for derived reports. Changing the JFR event profile, application code, workload, or protocol requires a new measured suite.

## Editing responsibility

Automation can extract and format observations. Engineering judgment remains responsible for:

- deciding whether an observed difference is meaningful;
- connecting evidence to code and runtime behavior;
- documenting alternative explanations;
- distinguishing correlation from causation;
- translating findings into contextual architecture decisions.

## What is automated and what remains engineering work

Automatically generated and safe to commit:

- curated suite `README.md`;
- `COMPARISON.md`;
- run-level `RUN_SUMMARY.md`;
- run-level `JFR_METRICS.md`;
- machine-readable JSON/CSV summaries;
- SHA-256 manifests;
- the overview, quantitative, aggregate, and factual-observation blocks plus measurement status in the main comparative analysis;
- automatic SHA-256 validation of the curated directory;
- `LATEST.md`, which points to the most recently materialized suite.

Intentionally manual:

- hypotheses written before reading results;
- interpretation and causal reasoning;
- alternative explanations;
- limitations;
- contextual architecture decision;
- final release narrative and changelog.

This boundary removes copy/paste without delegating engineering judgment to the generator.

## Integrity validation

`evidence-docs` validates the generated manifest automatically. Revalidate the latest curated suite later with:

```bash
make -C labs/01-loom-vs-reactive-checkout evidence-validate
```

Or validate an explicit directory:

```bash
make -C labs/01-loom-vs-reactive-checkout evidence-validate \
  CURATED_DIR=docs/results/evidence/<SUITE_ID>-paired-evidence
```

No shell variable from the materialization command is required.
