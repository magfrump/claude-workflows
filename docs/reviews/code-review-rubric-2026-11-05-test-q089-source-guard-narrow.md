Commit: 2174b7af
Loop closed at 2174b7af

# Code Review Rubric

**Scope:** test/q089-source-guard-narrow, `db31db8b..2174b7af` (full branch) | **Reviewed:** 2026-11-05 | **Status: 🟢 PASSES** — 0 red, 0 open amber; single-sample review; absence of findings is not an attestation

Pass 1 (`--loop-pass`, k=1 fact-check at 8880c925, critics at cb59c2bb), then the final confirming pass (iteration 2 of 3: k=3 fact-check at cb428e81, critics at 2174b7af). Delivery mode: self-read. Critics: security, performance, and architecture (forced, for the coupling to `cc-verify.sh`).

Final fact-check, k=3, reports `code-fact-check-report-q089-source-guard-r{1,2,3}.md`: 61, 53 and 51 claims; 0 Incorrect and 0 Unverifiable in every replicate. All three found the same stale research-doc lines left by cb428e81 (rename scope, case count, seeded block, case number) and the same Mostly-accurate citations; all fixed in 2174b7af. Replicates were not merged claim by claim: with no Incorrect, the merge could not change a tier. Final critics: security none; performance none; architecture one Informational (C8).

---

## 🔴 Must Fix

None.

---

## 🟡 Must Address

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | A plain `source` on a last line with no newline passes: `source_lines_ok`'s read loop never sees it, though bash runs it. Location: `test/cc-host-tool-sources.bats`, `devcontainer-config/cc-verify.sh:54,62` | Test | Medium | security-reviewer F1 | for-author | — | 🟢 Fixed: `check_entry` adds a final newline to its copies; new seeded case | — |
| A2 | "pinned by other tests, by accident of those tests' fixtures" holds only for one seed; dropped names are asserted directly. Location: research doc | Docs | Incorrect | code-fact-check claim 8 | for-author | — | 🟢 Fixed in cb59c2bb | — |
| A3 | "largest failure family" is wrong by the library's `cause:` tags. Location: research doc | Docs | Incorrect | code-fact-check claim 19b | for-author | — | 🟢 Fixed in cb59c2bb | — |

---

## 🟢 Consider

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | The rename covered only `cc-push.sh`, so a helper using `$CC_PUSH_DIR` got a false red | architecture-review F1 | Minor | for-author | — | 🟢 Fixed: the rename runs over every copy; new seeded case |
| C2 | The research doc said none of the lost forms is a plain line, but the one-line case arm is these files' idiom | architecture-review F2 | Minor | for-author | — | 🟢 Fixed |
| C3 | The header's limits did not cover a listed helper sourced outside the check's `if` | security-reviewer F2 | Info | for-author | — | 🟢 Fixed: "before the source or gates it" |
| C4 | A quoted call above the real check replaces the real list, through `head -1` | security-reviewer F3 | Info | for-orchestrator-synthesis | — | 🟢 Fixed: stated in the header |
| C5 | `source_lines_ok` runs twice per passing `check_entry`, about 0.45 s of 1.3 s | performance-reviewer F1 | Info | for-author | — | 🟢 Won't-Fix: override-log row |
| C6 | Nothing at `cc-verify.sh:41-47` names the test as a second consumer | architecture-review F3 | Info | for-author | — | 🟢 Defer: override-log row |
| C7 | The shipped `source_lines_ok` has the same last-line gap | security-reviewer escalation | Info | for-orchestrator-synthesis | — | 🟢 Defer: override-log row; a host-tool change, out of this unit |
| C8 | (final pass) `check_entry`'s comment left out that the grammar's eval and reassignment refusals now reach cc-push.sh | architecture-review P2-1 | Info | for-author | — | 🟢 Fixed, comment only |

The 8 Mostly-accurate fact-check claims were fixed in cb59c2bb. Claim 33 sits in the message of 8880c925, which stays; that commit's successor says what the run covered.

---

## ↩️ Considered Overrides

No prior overrides matched this diff.

---

## ✅ Confirmed Good

No rows claimed. The executed results are in the critics' reports: each mutation of `check_entry` tried failed the suite.

---

## 🧩 Composition check

| Cluster | Span | Fragments | Disposition |
|---|---|---|---|
| `check_entry` adjustments | test lines 37-46 | A1, C1, C5 | distinct defects: each states its own mechanism and fix |

---

## ⏭️ Skipped Core Critics

api-consistency-reviewer: no public surface touched (`git diff --stat`: one new test file and one working doc), and no fact-check claim in its domain.

`scripts/confine-tests.sh` exited 3 under the security critic, because the session cannot confine itself; `scripts/hermeticity-lint --root .` is clean.
