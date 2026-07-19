# Evidence Session Checklist

```text
[ ] clean worktree
[ ] Git SHA and branch captured
[ ] exact JDK and Spring Boot versions captured
[ ] host and container limits captured
[ ] simulator configuration captured
[ ] one implementation running, not both
[ ] readiness verified
[ ] pre-warm-up snapshot captured
[ ] fixed warm-up completed
[ ] bounded JFR/VisualVM window identified
[ ] same k6 scenario executed
[ ] post-load snapshots captured
[ ] fixed cool-down completed
[ ] service stopped cleanly
[ ] artifacts complete and sanitized
[ ] observation separated from inference
```

## Canonical automation

The checklist above is implemented by:

```bash
labs/01-loom-vs-reactive-checkout/scripts/run-evidence-suite.sh \
  --scenarios moderate,high \
  --pairs 4
```

JFR is the default automated JVM evidence. VisualVM screenshots are optional curated explanations because chart selection, time range, sort order, and written interpretation require engineering judgment. Numeric tables are materialized from structured artifacts with `materialize-evidence-docs.sh`; session startup and optional GUI load generation remain automated by `visualvm-session.sh`.
