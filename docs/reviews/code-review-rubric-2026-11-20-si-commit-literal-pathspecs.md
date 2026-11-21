# Code Review Rubric — si_commit_child_work turns literal pathspecs off itself (brief 2026-11-20-si-commit-literal-pathspecs)

**Commit:** 064e2a38 (pass 1 reviewed) → fix in 94bbae87
**Scope:** `10c42a29..HEAD`, branch `fix/si-commit-literal-pathspecs` | **Reviewed:** 2026-11-20 | **Status: ✅ PASSES (pass 1, all rows resolved)**. Single-sample review: no findings is not proof that none exist.

One fresh read-only reviewer covered correctness (empirically, on git 2.39.5), the other global pathspec env vars, the removed call-site guard, code-fact-check of the comments and research doc, and whether the new case fails without the fix.

---

## 🔴 Must Fix

None.

---

## 🟡 Must Address

None.

---

## 🟢 Consider

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | The new case's closing `[ "$GIT_LITERAL_PATHSPECS" = 1 ]` could not fail: `run` puts the function in a subshell. `test/si-commit-child-work.bats:59` | Test review | Low | for-author | — | Fixed 94bbae87: called without `run`; a function-wide export now fails the case (checked by mutation). |
| C2 | Also unset GIT_GLOB/NOGLOB/ICASE_PATHSPECS on the add. `scripts/lib/si-commit.sh:99` | Correctness | Nit | for-author | — | Won't-Fix: each alone leaves the exclude working; nothing in the harness exports them; the brief scopes literal pathspecs. |
| C3 | `guides/validation-gates.md:33` lists this function's hardening but not the new guard. | Fact-check | Nit | for-author | — | Won't-Fix here: outside the brief's doc scope; left for the cycle. |

---

## ✅ Confirmed Good

| Item | Verdict | Evidence | Source | Legibility-target |
|---|---|---|---|---|
| Prefix reaches git | Good | `GIT_LITERAL_PATHSPECS=0` before the `env ... git` array overrides an inherited 1, true or invalid value | Correctness probe | for-author |
| Removed call-site guard | Good | the lib's other git calls take no pathspec; one caller; clean-state case at line 354 still pins the wiring | Fact-check | for-author |
| New case bites | Good | fails on the 10c42a29 lib, passes now; suite 16/16 with the variable exported and unset | Test review | for-author |
