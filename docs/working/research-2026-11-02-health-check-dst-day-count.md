# Research: health-check gate 12 counts days by date, not by seconds

Brief: `docs/working/briefs/2026-11-02-health-check-dst-day-count.md` (dispatched at 9a50c75a).
Workflow: research-plan-implement, no plan-approval gate; bug-fix path (root cause known from the brief, so straight to verify).

Failure-pattern grep: `rg -n -i 'dst|daylight|timezone|86400|epoch|calendar|days since|date -d|fall-back|clock' docs/failure-patterns.md` — no entry matches; only the file's own header examples mention `timezone`.

Failure-pattern skip: a one-off wrong unit (elapsed local seconds used as a calendar-day count) in one function, fixed and pinned by a DST test in the same file; the repo's one other `/ 86400` (`scripts/lib/si-morning-summary.sh:1402`) ages a full timestamp in UTC, where elapsed seconds is the right unit, so there is no recurring mechanism to name.

## Reproduction

Reproduction: `bats -f "gate 12" test/scripts/health-check.bats` with the new case "a persona sampled today reads 0 days on a DST fall-back day". On the old code it fails with `✓ today-persona: fresh (1 days since 2026-11-01)`; on the fix it passes.

## Root cause

`check_persona_freshness` (`scripts/health-check.sh`, section 12) took `now = date +%s` and `sampled = date -d DATE +%s` (local midnight) and divided the difference by 86400. On a 25-hour local day, any time after 23:00 is more than 86400 s past local midnight, so a date of today reads 1 day. It is the only day arithmetic in the script (`rg -n 'date ' scripts/health-check.sh`; section 11 validates a date's format only).

## Design

Options, against H2/H3/S3/S8 and the brief's "exact across DST" criterion:

1. **UTC day numbers via `date -u -d`** on both `date +%F` (local today) and the sampled date, then divide by 86400. Exact: UTC has no DST, so two UTC midnights are a whole multiple of 86400 apart. One-line change per side, same tool already used, same parse-failure path.
2. Round the local-seconds difference (`(diff + 43200) / 86400`). Correct for ±1 h shifts but a heuristic; leaves the wrong unit in place.
3. Python `datetime.date` subtraction. Exact, but adds a python3 call to a bash gate for no gain over option 1.

Option 1 dominates (Path A): exact, smallest, no new dependency, keeps the 180-day threshold, the output wording and the invalid-date branch (`date -u -d` still fails on an unparseable date).

## Test

The new bats case puts a `date` shim first on PATH that answers "now" as `2026-11-01 23:30` and passes every `-d`/`--date` call straight to the real `date` (so it is exactly as strict as the real tool for those), and sets `TZ='EST5EDT,M3.2.0,M11.1.0'` — a POSIX rule string, so a sandbox without tzdata cannot silently fall back to UTC and pass vacuously. Two guard assertions check the shim's today is 2026-11-01 and that "now" is 88200 s (24.5 h) after local midnight before the gate runs.

## Docs

No other doc changes: no doc describes the day arithmetic (the section-12 header in the script and `AGENTS.md`/skills only say "last sampled > ~6 months ago"); the function now carries a three-line comment saying why it counts in UTC dates.
