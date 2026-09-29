Commit: d5880ad
Loop closed at d5880ad

# Code Review Rubric

**Scope:** fix/agents-md-no-imports vs main (AGENTS.md, test/agents-gemini-sync.bats, scripts/health-check.sh comment, decision log row 65) | **Reviewed:** 2026-09-29 | **Status: 🟢 PASS** — no Must Fix; every Must Address fixed or acknowledged with a revisit trigger. Single-sample review; absence of findings is not an attestation.

Loop: 3 iterations (the cap).
1. Pass 1 on 5ee8315: full panel (k=3 fact-check, security, performance; api-consistency skipped, no public surface).
2. Final pass 1 on 7c2253a: k=3 fact-check.
3. Final pass 2 on 832932a: k=3 fact-check. Two replicates ran Claude Code 2.1.284's own extractor from the binary.

Each round's fixes were verified by the targeted suites and the fix-drift lite check. There was no fourth full pass: the exit rule is met and the one open item carries a revisit trigger. Delivery mode: self-read. Considered overrides: no prior overrides matched this diff.

---

## 🔴 Must Fix

None.

---

## 🟡 Must Address

| # | Finding | Source | Status | Author note |
|---|---|---|---|---|
| A1 | Guard narrower than claimed: caught only `@/ @./ @../` (pass 1) | fact-check ×3, security #1, performance #1 | ✅ Fixed (7b43db2 → d5880ad) | — |
| A2 | Widened guard still missed `@README`, `@package.json`, `@x.MD`; "every form" overclaimed (final pass 1) | fact-check ×3 | ✅ Fixed (2f5fba3 → d5880ad) | — |
| A3 | "Mirrors Claude Code's grammar" was false: 18/27 probes disagreed. A four-backtick fence hid the rest of a file; link text, `>@`, `~~@`, `<span>@` were missed (final pass 2) | fact-check ×3 (r1, r3 executed CC's extractor) | ✅ Fixed (d5880ad) | The finder now over-approximates and removes only same-line code spans. 16 must-flag forms are pinned, including the fence trap |
| A4 | Known miss: an import inside a code span in a tight list item | final pass 2 r3 | 🟡 Acknowledged | Documented in the test comment and log row 65. Revisit if CC's import grammar widens, or a false alarm forces rewording a guarded file more than once |
| A5 | "~85K tokens" → ~89K | fact-check | ✅ Fixed (7b43db2) | — |

## 🟢 Consider

| # | Finding | Status |
|---|---|---|
| C1 | CLAUDE.md example in the extract_workflows comment used bold; the file uses backticks | ✅ Fixed |
| C2 | Global instructions unguarded | ✅ Fixed (guard covers both files) |
| C3 | ~3 KB of shared sections loads twice per session | 🟢 Won't-Fix (override log) |
| C4 | Bare names could resolve to the installed workflow copy | 🟢 Won't-Fix (override log) |
| C5 | Harness-loading claims have no in-repo evidence | 🟢 Accepted: observed in session context and confirmed from the binary |
| C6 | Emphasis comment's mechanism read backwards | ✅ Fixed (comment rewritten) |
| C7 | Fix-drift lite check on d5880ad: "row 65 says 16 must-flag forms, test has ~11–12" | 🟢 Dismissed: the test asserts exactly 16 matched lines and passes; the positive heredoc has 11 original plus 5 added forms |

Immutable-history Incorrects (commit messages 5ee8315, 7b43db2, 2f5fba3) are logged as Accepted-immutable in the override log.

## 🧩 Composition check

| Cluster | Disposition |
|---|---|
| `test/agents-gemini-sync.bats` find_imports, across all three passes | distinct defects: none new. The same mechanism narrowed each round; see A1–A3 |
