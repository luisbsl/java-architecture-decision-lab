# Publish to GitHub

This package intentionally contains no `.git` directory and no branch stack. For the complete source → evidence → documentation → release workflow, use [`docs/runbook/GITHUB_RELEASE_RUNBOOK.md`](docs/runbook/GITHUB_RELEASE_RUNBOOK.md).

## 1. Verify locally

```bash
./scripts/verify-all.sh
```

## 2. Create one clean history

```bash
git init -b main
git add .
git commit -m "feat: publish complete Java architecture decision lab"
```

## 3. Create and push the repository with GitHub CLI

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

## 4. Create the first release

```bash
git tag -a v1.0.0 -m "Complete lab and automated evidence pipeline"
git push origin v1.0.0

gh release create v1.0.0 \
  --title "Java Architecture Decision Lab v1.0.0" \
  --notes "Complete MVC + Virtual Threads and WebFlux/Reactor lab with observability, automated paired performance evidence, JFR reports, generated evidence charts, optional VisualVM diagnostics, load testing, and profiling protocols."
```

## 5. Repository settings

After the first CI run is green:

- protect `main`;
- require the `Maven and Docker verification` check;
- block force pushes;
- enable Dependabot alerts;
- add the repository to the LinkedIn Featured section.
