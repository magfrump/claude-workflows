# dev-cycle.sh digest misses decision-log revisit triggers in date-first logs

**Found:** 2026-10-04, first dev cycle in the threadwork repo.
**Script:** `scripts/dev-cycle.sh`, section 2 "Revisit triggers" (installed copy at `/opt/claude-workflows/scripts/dev-cycle.sh`, around lines 709<E2><80><93>719 and 732<E2><80><93>733).
**Severity:** a silent false negative. The digest printed "No revisit triggers recorded." even though the log had two live triggers, and one of them had fired.

## What happened

threadwork's `docs/decisions/log.md` has two rows that contain revisit triggers:

- 2026-07-09, "Data layer in Python 3.10 <E2><80><A6> not TypeScript": *"Revisit when a real frontend starts."* This trigger **had fired**.
- 2026-07-22, "admission stays boolean": *"Revisit trigger: R1 positive **and** demanding ranking."* This one had not fired.

The digest reported neither. I only caught them because I grepped the log by hand.

## Cause

The row selector assumes claude-workflows' own log layout, where the first column is a row number:

```
grep -E '^\| [0-9]+ \|' docs/decisions/log.md | grep -i 'revisit'
```

threadwork's log starts with the date and has no number column (`| date | decision | rationale | confidence |`). So `^\| [
0-9]+ \|` matches **0 of its 41 rows**. The `n` and `d` extraction (`$2` and `$3`) assumes the same layout too.

The real problem is that it fails silently. When a log exists and has table rows but none match the expected shape, the sc
ript falls through to the same "No revisit triggers recorded." message it prints for a genuinely empty log. The skill then
 tells the cycle not to reopen anything that has not fired, so a parse miss turns into "nothing to check".

## Repro

```
R=$(mktemp -d) && cd "$R" && git init -q -b main && mkdir -p docs/decisions
printf '# Decision log\n\n| date | decision | rationale | confidence |\n|---|---|---|---|\n| 2026-07-09 | Use X | Because.
 Revisit when Y happens. | medium |\n' > docs/decisions/log.md
git add . && git -c user.name=t -c user.email=t@t commit -qm init
scripts/dev-cycle.sh | sed -n '/## 2. Revisit/,/## 3/p'
# -> "No revisit triggers recorded."
# Prepend a "| 1 |" number column to the row (and the header) and the same row prints:
# -> "- log row 1 (2026-07-09): > Revisit when Y happens."
```

## Suggested fix

1. **Accept both layouts.** Select table data rows with `^\|` (skipping the header and the `|---|` separator) instead of r
equiring a numeric first cell. Name each row by its number cell when there is one. Otherwise use its date plus its line nu
mber in `log.md`, for example `log row L23 (2026-07-09)`, so cycle records still have a stable handle.
2. **Never report zero when nothing could be parsed.** If `log.md` has table rows but none match the expected shape, print
 a warning such as "decision log rows not in a recognized format; triggers NOT checked". That matches how section 3 alread
y reports "Watched questions were NOT checked".
3. **Add a test** with a date-first log fixture next to the existing digest tests.

## Related gap (lower priority, maybe by design)

Revisit triggers that live in `docs/working/` design docs are never scanned. For example, threadwork's `docs/working/dd-ti
me-and-ritual.md` has a `### Revisit triggers` section (H3, in a tentative DD that never became a decision record). The di
gest scans only decision records with an H2 `## Revisit triggers`. Either note this limitation in the section-2 header tex
t, or also scan `docs/working/dd-*.md` for any heading level of "Revisit triggers".

## How threadwork handled it

Both rows were judged by hand and recorded in `docs/working/cycles/cycle-2026-10-04.md` under their log line numbers (23 a
nd 42). The fired one became Q-002.