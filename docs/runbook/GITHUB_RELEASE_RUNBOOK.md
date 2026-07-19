# GitHub Release Runbook

This document covers only repository publication. The complete build → runtime → evidence → documentation → release sequence is maintained in [`MASTER_RUNBOOK.md`](MASTER_RUNBOOK.md).

## 1. Start from the extracted clean delivery

```bash
unzip java-architecture-decision-lab.zip
cd java-architecture-decision-lab
```

Validate the adjacent checksum when supplied:

```bash
sha256sum -c java-architecture-decision-lab.zip.sha256
```

## 2. Run the release gate

```bash
./scripts/verify-evidence-tooling.sh
./scripts/verify-all.sh
make -C labs/01-loom-vs-reactive-checkout evidence-validate \
  CURATED_DIR=docs/results/evidence/20260718T215210Z-paired-evidence
```

Do not publish from an unverified environment.

## 3. Create one clean `main` history

```bash
git init -b main
git add .
git commit -m "feat: publish complete Java architecture decision lab"

git status --short
git log --oneline --decorate -1
```

## 4. Create the GitHub repository

```bash
gh repo create java-architecture-decision-lab \
  --public \
  --source=. \
  --remote=origin \
  --push
```

For an existing empty repository:

```bash
git remote add origin git@github.com:luisbsl/java-architecture-decision-lab.git
git push -u origin main
```

## 5. Protect `main`

After the first CI run is green:

- require pull requests for later changes;
- require `Maven and Docker verification`;
- block force pushes and branch deletion;
- require conversation resolution;
- enable Dependabot alerts.

## 6. Create the first release

```bash
git tag -a v1.0.0 -m "Complete Java architecture decision lab"
git push origin v1.0.0

gh release create v1.0.0 \
  --title "Java Architecture Decision Lab v1.0.0" \
  --notes "Complete MVC + Virtual Threads and WebFlux/Reactor lab with observability, balanced paired evidence, JFR reports, generated evidence charts, optional VisualVM diagnostics, load testing, and publication-grade integrity gates."
```

## 7. Optionally upload a sanitized raw evidence suite

```bash
SUITE_DIR=/absolute/path/to/<SUITE_ID>-paired-evidence

make -C labs/01-loom-vs-reactive-checkout evidence-release \
  SUITE_DIR="$SUITE_DIR" \
  RELEASE_TAG=v1.0.0
```

Large raw JFR and load artifacts belong in release assets, not in Git history.
