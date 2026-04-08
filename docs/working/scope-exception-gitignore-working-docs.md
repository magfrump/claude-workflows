# Scope Exception: gitignore-working-docs

## Scripts that write to docs/working/ flat paths

The following scripts hardcode `docs/working/` paths and would need updates
to write into subdirectories (rounds/, reports/, scratch/) instead:

- **scripts/self-improvement.sh** — writes `summary-*.md`, `plan-*.md`,
  `research-*.md`, `feature-ideas-round-*.md`, `tasks-round-*.json`,
  `round-*-report.json`, `round-history.json`, `problem-history.json`
- ~~**scripts/search-external-ideas.sh**~~ — removed in round 5 (dead code cleanup)
- **scripts/archive-working-docs.sh** — iterates `docs/working/*` to archive

These scripts were NOT modified (outside file scope constraint). The .gitignore
approach works without script changes: scripts still write to docs/working/,
but generated files are now gitignored so they don't create git status noise.

To fully migrate to subdirectories, these scripts would need path updates.
