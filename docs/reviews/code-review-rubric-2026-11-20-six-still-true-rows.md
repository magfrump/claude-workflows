Commit: dff37675c
# Code Review Rubric

**Scope:** fix/six-still-true-rows, b516c62d..dff37675c (5 commits: hooks/guard-trusted-writes.py, scripts/questions.sh, scripts/lite-review.py, their bats suites, docs/reviews/override-log.md, the research doc) | **Reviewed:** 2026-11-20 | **Status: 🟢 PASSES**. 0 red; 2 amber from pass 1 and 1 from pass 2, all fixed.

Two passes, each one fresh general-purpose reviewer doing fact-check, security and test review in compact form (their reports came back as messages; findings are restated here). The lite fix-drift check on the pass-1 fix commit (6f53e96e..22bab455) printed `FINDINGS: NONE`.

Security, both passes: no bypass. The `classify_path` change only moves verdicts from defer to deny (10 spellings probed, old vs new); the questions.sh `.git/` refusal compares two `realpath -m` results with a quoted root and refuses only default paths.

---

## 🔴 Must Fix

None.

---

## 🟡 Must Address

| # | Finding | Domain | Severity | Source | Location | Status | Author note |
|---|---|---|---|---|---|---|---|
| A1 | "Every path this changes is a HARD target ... nothing legitimate is lost": a `..` spelling whose kernel target is SOFT or ordinary is denied too (`~/.claude/hooks/../skills/s/SKILL.md`) | Docs / Security | Incorrect | pass 1 F1 | ae318371 message; research doc N13 note | Fixed in 22bab455 | Research doc and the `classify_path` comment state the over-deny; the deny text names the respelling route (pass 1 F3); a bats case pins it. The commit message is immutable. |
| A2 | The A11 override row pinned `scripts/lite-review.py:61`, its pre-branch line | Docs | Stale | pass 1 F2 | docs/reviews/override-log.md (A11 row) | Fixed in 22bab455 | Now `:68` (`DEFAULT_MODEL`). |
| A3 | The N17 row and research doc pinned TODO(N2) `:430` and `bash_targets` `:485`; 22bab455 moved them to `:432`, `:487` | Docs | Stale | pass 2 F1 | docs/reviews/override-log.md (N17 row); research doc | Fixed in dff37675c | Pins re-read after the last code change. |

---

## 🟢 Consider

| # | Finding | Status |
|---|---|---|
| C1 | `..` deny named a skill file as "a global hook, settings or CLAUDE.md" (pass 1 F3) | Fixed in 22bab455: own deny text |
| C2 | No test for `$HOME/x/../CLAUDE.md` or the `hooks/..` shape (pass 1 T1); loop did not pin the deny text (pass 2 T1) | Fixed in 22bab455 and dff37675c |
| C3 | The A10 grep test is a heuristic (pass 1 T2); its `A10:` label collided with a guard test (T3); a 104-char comment line (C1) | Fixed in 22bab455 |
| C4 | Research doc said "the two R4 cases" were converted; only the MultiEdit one was (pass 2 F2) | Fixed in dff37675c |
| C5 | `docs -> .GIT` on a case-insensitive filesystem passes the `.git/` check (pass 1 S1) | Won't-Fix: it writes only the questions files there, the same nil impact |
| C6 | Only `init` exercises the `.git/` refusal (pass 2 T2) | Won't-Fix: `index` and `archive` reach the same `assert_write_targets` |
