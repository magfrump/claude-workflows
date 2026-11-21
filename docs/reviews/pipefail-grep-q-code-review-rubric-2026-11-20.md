# Code Review Rubric — here-strings for grep pipes under pipefail (brief 2026-11-20-pipefail-grep-q)

**Commit:** da3dc615 (pass 1 reviewed) → doc fixes in the following commit
**Scope:** `c12095f4..HEAD`, branch `fix/pipefail-grep-q` | **Reviewed:** 2026-11-20 | **Status: ✅ PASSES (all rows resolved)**. Single-sample review: no findings is not proof that none exist.

One fresh read-only reviewer covered four things: behaviour equivalence of each rewrite, the research doc's site table against its own search of `scripts/` and `hooks/`, the tests (old code red, new code green, hermetic), and scope. It ran the new tests against copies of the old and new code.

---

## 🔴 Must Fix

None.

---

## 🟡 Must Address

| # | Finding | Domain | Severity | Source | Status |
|---|---|---|---|---|---|
| A1 | The research doc's "pipefail comes from" sentence named 3 of the 16 pipefail files, which contradicted its own `run-tests.sh` row. | Docs | Incorrect | Fact-check | Fixed: the sentence now gives the full search and the count |
| A2 | `scripts/dev-cycle.sh:558` (`printf \| awk '… exit'` under pipefail) was missing from the table. | Docs | Coverage gap | Table review | Fixed: added as safe from a lost match, a `\| head`-class abort risk |
| A3 | The health-check result was not recorded. | Tests | Missing evidence | Brief criterion 4 | Fixed: `scripts/health-check.sh` exit 0, "All checks passed." |

---

## 🟢 Consider

| # | Finding | Source | Severity | Status |
|---|---|---|---|---|
| C1 | The Design note on `:1830` credited the old `!`'s true to git's status. It was grep's 1 on empty input. | Fact-check | Informational | Fixed: wording corrected |
| C2 | A here-string over a pipe buffer goes to a temp file. If no temp dir were writable, grep would not run and the `if` would read no match. | Security | Informational | Won't-Fix: bash falls back to /tmp, and the two existing FP-175 fixes use the same form |
| C3 | The board test's `!=` assertion is redundant on the old code, since the `==` before it fails first. | Test review | Nit | Won't-Fix: it pins the single-line shape on the new code |

---

## ✅ Confirmed Good

| Item | Verdict | Evidence |
|---|---|---|
| Rewrites are equivalent apart from the SIGPIPE loss | Good | `echo` and `<<<` both add one trailing newline. Empty input and grep exit 2 still reach the board fallback. A substitution failure under `if`/`!` does not trip errexit |
| Tests fail on old code and pass on new code | Good | Reviewer's `git archive` copies: the 3 FP-175 cases were 3/3 not ok on old and 3/3 ok on new, about 6 s |
| Hermeticity | Good | Existing claude stub and network-sentinel shims are used, and `scripts/hermeticity-lint --root .` passes |
| Scope | Good | Only the three sites plus their FP-175 comments, two test files, the research doc and this rubric |
