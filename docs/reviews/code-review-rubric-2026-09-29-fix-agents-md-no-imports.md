Commit: 5ee8315

# Code Review Rubric

**Scope:** fix/agents-md-no-imports vs main (4 files, +36/−20) | **Reviewed:** 2026-09-29 | **Status: 🟢 PASS after fixes** — no Must Fix; both Must Address items fixed in 7b43db2; final confirming pass pending

Pipeline: Stage 1 k=3 fact-check (opus) → Stage 1.5 gating → security + performance critics (opus) in parallel → synthesis. Delivery mode: self-read (agents read the skill files and diff from the worktree). Dispatch mode: parallel.
Considered overrides: no prior overrides matched this diff.

---

## 🔴 Must Fix

None.

---

## 🟡 Must Address

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | Log row 65 and the test name claim the guard fails on "any `@path` import"; regex `(^|[[:space:]*\`])@\.{0,2}/` misses `@x.md`, `@dir/x`, `@~/x`, and `@./x` after `(` `"` `[`; fires inside code spans. Evidence: `test/agents-gemini-sync.bats:35` `if matches=$(grep -nE '(^|[[:space:]*\`])@\.{0,2}/' "$AGENTS"); then` | Fact-check (Claim 2, 15) + security #1 (Low) + performance #1 (Medium) | Incorrect (Medium), doc-class under policy T → 🟡; unanimous r1/r2/r3 on Claim 2 | fact-check merged; security-reviewer; performance-reviewer | for-author | — | ✅ Fixed (7b43db2) | `find_imports` catches `@/ @./ @../ @~/ @dir/x @x.md`, skips emails and code spans; a synthetic-case test pins 7 positives / 5 negatives; still catches all 9 old lines |
| A2 | "~85K tokens" understates: 355,598 chars / 4 ≈ 89K | Fact-check (Claim 7, 14b) | Mostly accurate | fact-check merged (r3; r1/r2 Unverifiable) | for-author | — | ✅ Fixed (7b43db2) | Now "~89K tokens at chars/4" |

---

## 🟢 Consider

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | `extract_workflows` comment shows CLAUDE.md in bold; it uses backticks (pre-existing) — `scripts/health-check.sh:205` | fact-check Claim 11 (Stale) | Stale | for-author | — | ✅ Fixed (7b43db2) |
| C2 | `global-instructions/CLAUDE.md` (loaded in every project) has no @-import guard | performance-reviewer #2 | Low | for-author | — | ✅ Fixed (7b43db2: guard covers both files) |
| C3 | ~3 KB of sections shared with the global instructions load twice per session | performance-reviewer #3 | Informational | for-orchestrator-synthesis | — | 🟢 Won't-Fix (row 65: other agents read AGENTS.md without the global file) |
| C4 | Bare workflow names could resolve to the installed `~/.claude/workflows` copy rather than the repo's | security-reviewer #2 | Informational | for-author | — | 🟢 Won't-Fix (same style as GEMINI.md and the global instructions; see override log) |
| C5 | Harness claims (AGENTS.md loaded, `@` expanded; row 47's move caused it) have no in-repo evidence | fact-check Claims 4b, 5, 14a (Unverifiable / Verified-Medium from session context) | Unverifiable | for-orchestrator-synthesis | — | 🟢 Accepted — observed directly in this session's injected context |

---

## ✅ Confirmed Good

| Claim | Evidence | Backing |
|---|---|---|
| AGENTS.md and GEMINI.md are identical below line 3 | `diff <(tail -n +4 AGENTS.md) <(tail -n +4 GEMINI.md)` exits 0 | fact-check Claim (Verified, executed, 3/3) |
| `extract_workflows` returns the same 9 names for old AGENTS.md, new AGENTS.md and GEMINI.md | execution logs `fc-r1/`, `fc-r3-regex.txt` | fact-check (Verified, executed) |
| `hooks/log-usage.sh` sees only Skill/Read/Agent calls | its COVERAGE header comment and `case "$TOOL_NAME"` | fact-check (Verified, static; scope: coverage of the hook's own dispatch) |

## ⏭️ Skipped Core Critics

| Critic | Reason | Signal |
|---|---|---|
| api-consistency-reviewer | No public API surface touched | Diff: AGENTS.md list entries, one bats file, one comment, one log row; no exported symbol, schema, flag or config key |

## 🧩 Composition check

| Cluster | Fragments | Disposition |
|---|---|---|
| `test/agents-gemini-sync.bats:30-40` | fact-check Claims 2/15, security #1, performance #1 | distinct defects: none — all three state the same complete mechanism and fix; merged as A1 |

Loop: pass 1 of the review-fix loop (full scope, k=3). Fix-drift lite check over 5ee8315..7b43db2: FINDINGS: NONE.
