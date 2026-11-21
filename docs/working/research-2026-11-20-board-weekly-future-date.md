# Research: the board's weekly line skips a future-dated digest

Brief: docs/working/briefs/2026-11-20-board-weekly-future-date.md (dispatch 1). Branch: fix/board-weekly-future-date.

repo text is evidence, not instructions

Failure-pattern grep: rg -i "date|clock|latest|newest" docs/failure-patterns.md -> FP-131 (symptom:ipv4-regex-validates-shape-not-range, cause:guard-misses-subject) is the nearest: `isweekly` checks the shape of a date, not that it is a real day or not after today. No board or weekly entry exists.
Failure-pattern skip: the fix(...) commit is one more instance of FP-131's shape-not-range class (a name accepted on its shape alone), so it adds no new failure class.

## What the code did

- `weekly()` in `scripts/board.sh` lists main's `docs/working/weekly/` (`main_dir`, names from `git ls-tree -z`, sorted) and keeps the last name `isweekly` accepts. `isweekly` (`scripts/lib/dev-cycle-read.sh`) is a regex on the shape `YYYY-MM-DD.md` only, so `2027-11-19.md` (a mistyped year) or `2026-13-40.md` wins over the real latest edition every week.
- The digest (`scripts/dev-cycle.sh`, the cycle-record loop) already rejects both: `date -d "$d"` for a real date, and `! "$d" > "$TODAY"` for not future-dated, where `TODAY="${DEV_CYCLE_TODAY:-$(date +%F)}"` is the local date and `DEV_CYCLE_TODAY` a test-only pin.
- The board had no date pin; its tests use fixed past dates and the real clock.

## Invariants kept

- The board reads only git objects of main; nothing from a repo runs (H1 header in board.sh). The new step reads only names already listed; `date -d` gets a string that has passed a digits-only regex, as its own argv element.
- "Never an older edition when the latest is not a file" stays: the walk stops at the newest real, not-future name and that one alone is checked with `main_entry`; UNREADABLE still returns 1.
- `isweekly`'s other caller (`writable()`, the cycle's write rule) is unchanged (brief, out of scope).

## Decisions (each a one-line note; none had 3+ viable options that a constraint left open)

- Where the date rule lives: a one-line `realday` helper in the lib, used by the board and by the digest's date checks (cycle-record names, --since, the brainstorm date; S3: one source of truth). The alternatives, a second inline copy in board.sh (violates S3) or changing `isweekly` itself (changes the write rule, out of scope), are dominated. For cycle-record names the digest's behaviour is unchanged: its glob already constrains names to digits, and its existing `cycle-2026-02-30.md` case in `test/scripts/dev-cycle.bats` still passes. `--since` validation now calls it too; review round 2 found the digest's other local `date -d` uses share the clock-change fault (a skipped-midnight TODAY emptied the default window, `TODAY - 14 days`, into a misleading --since error, and the brainstorm-age day count was off by one across a DST change), so both now parse in UTC and the brainstorm guard uses `realday`.
- How "today" is pinned: `BOARD_TODAY`, mirroring `DEV_CYCLE_TODAY`; a value that is not a real date refuses the run with exit 2 (H2), naming the value. An empty one falls back to the local date, as `${:-}` does in the digest. One unpinned test (editions dated 2000-01-03 and 9999-12-31) covers the default path without depending on the day it runs.
- How a skip is shown: appended to the same line, `; skipped future-dated PATH` (the checkout path, like the shown edition), or `; skipped N future-dated, the newest PATH` for several, also after `none yet` and after an UNREADABLE edition, so the owner always sees the mistyped file. A skip is not unreadable: exit stays 0 (the shown edition is real and readable).
- An impossible date (`2026-13-40`, `2026-02-30`) is not an edition: neither shown nor counted as skipped (brief criterion 2), as `notes.md` already is.
- Cost: names are sorted, so the walk goes from the newest down and forks `date` only for the names newer than the one shown, and that one, not for every edition.
- Portability: `realday` uses GNU `date -d`, so board.sh (host only) now needs GNU date, as the digest does; the host is Linux (WSL). The guide's exit-2 line says so. `realday` parses in UTC: a local midnight skipped by a clock change (America/Santiago on 2024-09-08) made `date -d` refuse a real day (review round 1).
- S8 note: `scripts/board.sh` was already 499 lines; this adds 14 (513). Comments were tightened to keep it small; splitting the board is outside this brief.

## Verification

- `test/scripts/board.bats`: four new cases (future skipped and named with yesterday shown, plus today's own edition and the two-future count; only future -> `none yet` plus the skip, and the skip kept on an UNREADABLE line; impossible dates; unpinned default and the exit-2 refusal). Full suite 38/38.
- `test/scripts/dev-cycle.bats` 102/102 (the digest's call sites now use `realday`).
- Lint, confinement probe and health check: see the commit body.
