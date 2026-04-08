# Scope Exception: gitignore-restructuring

The following scripts reference `docs/working/round-history.json` or other paths
that moved to subdirectories (`reports/`, `rounds/`) but were outside the allowed
file scope for this task. They need path updates in a follow-up:

| Script | References | New path |
|--------|-----------|----------|
| `scripts/print-round-summary.sh` | `docs/working/round-history.json` | `docs/working/reports/round-history.json` |
| `scripts/failure-analysis.sh` | `docs/working/round-history.json` | `docs/working/reports/round-history.json` |
| `scripts/flag-removal-candidates.sh` | `docs/working/round-history.json` | `docs/working/reports/round-history.json` |
| `scripts/archive-working-docs.sh` | iterates `docs/working/*`, lists `tasks.json` as permanent | needs update for subdirectory structure |
| `scripts/collect-evidence.sh` | counts `docs/working/*.md` | may need to recurse into subdirs |

These scripts use env-var overrides (e.g., `ROUND_HISTORY`) so they can be
pointed at the new paths without code changes as a temporary workaround:

```bash
export ROUND_HISTORY=docs/working/reports/round-history.json
```
