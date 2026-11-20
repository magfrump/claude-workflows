Commit: 98d78d32
# Code Review Rubric (pass 3, iteration 3 of 3, final confirming pass)

**Scope:** fix/guard-worktree-taint, full branch `40e5df45...98d78d32` (hook, bats, research doc; the merge of main at 98d78d32 brought only unrelated dev-cycle files) | **Reviewed:** 2026-11-19 | **Status: 🟡 CONDITIONAL PASS**: the one red (R1) and three ambers were fixed in 5070403e and checked by tests and a fix-drift pass, not by a fourth full pass (the 3-iteration cap). Single-sample review; absence of findings is not an attestation.

Earlier rubrics: `code-review-rubric-2026-11-19-guard-worktree-taint-pass1.md` (pass 1) and `-pass2.md` (pass 2). Their rows now read Fixed with the fixing commit. Agent reports for this pass are in the build loop's scratch dir, not here.

## ⤴️ Carried forward

From `docs/reviews/code-review-rubric-2026-11-19-guard-worktree-taint-pass2.md`:

| Prior ID | Tier | Now | Reason |
|---|---|---|---|
| A6 | 🟡 | Fixed | 076ba817 added the unresolved absolute candidate; this pass's R1 is a regression of that fix, fixed in 5070403e |
| A7 | 🟡 | Fixed | 076ba817 reworded residual R1 |
| A8 | 🟡 | Fixed | 076ba817 fixed the rubric path and counts |
| A9 | 🟡 | Fixed | 076ba817 made the header list precise |
| A10 | 🟡 | Fixed | 076ba817 fixed the `_is_soft_rel` docstring |
| A11 | 🟡 | Fixed | 076ba817 made the claim true (C7 fix) |

---

## 🔴 Must Fix

| # | Finding | Domain | Severity | Source | Location | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|---|---|
| R1 | **A relative file_path with a deleted cwd crashed the hook (exit 1), so the edit went ahead with no ask.** Pass 2's SOFT-only candidate `Path(os.path.abspath(str(p)))` sat outside any try; `getcwd` raised FileNotFoundError. In a tainted session, relative `CLAUDE.md`, `.claude/settings.json` and `skills/a/SKILL.md` asked on 40e5df45 and crashed on 98d78d32. HARD unaffected. Breaks H2 and the header's "erroring keeps SOFT". Fix: abspath failing returns "soft"; bats case M1 (fails on 98d78d32, passes on 5070403e). | Security / correctness | Medium (reachability Low: needs a relative file_path and a vanished cwd) | Fact-check M1 (r1, executed), confirmed by security-reviewer and api-consistency F1 (executed), orchestrator re-run | `hooks/guard-trusted-writes.py:394` | for-author | — | ✅ Fixed (5070403e) |

Evidence (`hooks/guard-trusted-writes.py:394` at 98d78d32, verbatim):
> `    for cand in cands + (Path(os.path.abspath(str(p))),):`

---

## 🟡 Must Address

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | **Research doc :94-98 "a relative spelling gets the absolute spelling's result" is false** when the relative text names `.claude/wt-*/` or `.claude/worktrees/<n>/`: it asks, the absolute spelling does not. Fails closed (an extra ask). | Docs | Low | Fact-check M2 (3/3), api F2 | for-author | — | ✅ Fixed (5070403e) | Reworded; bats case M2 pins the behaviour |
| A2 | **Hook header :55-57 "each relative to the root both as written and resolved"** holds only for absolute candidates; a relative as-written candidate keeps the blanket rules. | Docs | Low | Fact-check M3 (3/3), api F2 | for-author | — | ✅ Fixed (5070403e) | Header now says so |
| A3 | **Research doc :91 "each of the three candidates"** is stale: the SOFT check has four since 076ba817. | Docs | Low | Fact-check M4 (r3), api F3 | for-author | — | ✅ Fixed (5070403e) | — |

---

## 🟢 Consider

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | bats "an unverifiable worktree root fails closed" also asserts ask for the roots themselves; name was narrower than the body | Fact-check M5 (r3) | Low | for-author | — | Fixed (5070403e, renamed) |
| C2 | Header's "Unlike the main checkout" sentence left out root `.git` and that root names match in any case | api F4, fact-check (r2) | Info | for-author | — | Fixed (5070403e) |
| C3 | A worktree named after a policy word (`.claude/worktrees/skills/x.md`) now gets no opinion where it asked; CC loads no skills there | api F6, fact-check (r1, r2) | Info | for-author | — | Fixed (5070403e, documented in research doc) |
| C4 | The root is re-verified once per candidate (4 times): 0.92 ms vs 0.085 ms per classify_path; hook end to end 20 ms vs 17 ms | performance #1 (executed) | Info | for-author | — | 🟢 Open |
| C5 | Relative paths are judged from the hook's cwd, an unstated assumption; if wrong, only the A6 extra ask is lost, never an ask the old hook gave | api F5 | Info | for-author | — | 🟢 Open |
| C6 | A hardlink in a verified worktree to `~/.claude/settings.json` lost its incidental `.claude`-segment ask; creating one is deliberate (S1 out of scope), and realpath cannot see hardlinks anywhere | security #2 | Info | for-author | — | 🟢 Open |
| C7 | `.mcp.json`, `.gitattributes`, `skills/*/x.py` in a worktree no longer ask: stated residual R2, same as the main checkout | security #3 | Info | for-orchestrator-synthesis | — | 🟢 Open |
| C8 | Pre-existing (outside this diff): `main()` fail-opens on a list file_path or an unreadable taint marker | pass-2 C8 | Low | for-author | — | 🟢 Open |
| C9 | A lstat-then-open FIFO swap could block the hook; needs a deliberate race (R3 class) | performance #2 | Info | for-author | — | 🟢 Open |
| C10 | Pre-existing (outside this diff): at import, `config_dir()` calls `os.path.abspath` on a relative `CLAUDE_CONFIG_DIR`, so a deleted cwd still exits 1 in the old and new hook | fix-drift check | Low | for-author | — | 🟢 Open |

---

## ↩️ Considered Overrides

| Override (PR ref / Date) | Prior finding | Original → Override | Reason | This run's treatment |
|---|---|---|---|---|
| `answers-2026-09-20` / 2026-09-21 (log row 98) | Bash writes ungated for several spellings, guard-trusted-writes.py Bash tier | 🟡 → Defer | Pre-existing | Category match only. The Bash tier is untouched; not re-flagged. |
| `answers-2026-09-20` / 2026-09-21 (log row 103) | A8: WRITE_PRIMITIVE misses `ln -sf`, `curl -o`, … | 🟡 → Defer | Pre-existing | Category match only. Not re-flagged. |

---

## ✅ Confirmed Good

| Item | Verdict | Evidence | Source | Legibility-target |
|---|---|---|---|---|
| Per-commit test claims: the HEAD bats file fails 7 of the first 12 new cases on f5fbc9be, the R1/A1/C1 cases on f2829bcf, only A6/C7 on 881d87a9, none on 98d78d32 | ✅ Confirmed | All three fact-check replicates ran the HEAD test file against each older hook (executed) | Fact-check r1, r2, r3 | for-orchestrator-synthesis |
| The HARD candidates are the unchanged tuple `(p, norm, rp)`; the abspath candidate is used only in the SOFT loop | ✅ Confirmed (static, full classify_path read) | `hooks/guard-trusted-writes.py` — "cands = (p, norm, rp)"; SOFT loop "for cand in cands + (absp,):" | Fact-check r1, api-consistency | for-orchestrator-synthesis |

Security's two endorsement claims (HARD unchanged and first; SOFT differs from base only under a verified root) were not sent to Stage 2.5 because this pass carried a red; they stay pending execution verification.

---

## ⚠️ Unverified Findings

- Whether Claude Code ever sends a relative `file_path`, or runs the hook in a deleted cwd (R1's reachability). Needs a host check.
- `_verified_worktree`'s relative back-pointer branch (`worktree.useRelativePaths`): the sandbox's git 2.39.5 cannot create one.

---

## ⏭️ Skipped Core Critics

All core critics ran; no skips applied.

---

## 🧩 Composition check

| Cluster | File / lines | Fragments | Disposition |
|---|---|---|---|
| 1 | `hooks/guard-trusted-writes.py:394` + header :58-59 | fact-check M1, security #1, api F1 | Distinct defects: none. One root, stated in R1 by every fragment |
| 2 | header :55-57 + research :91-98 | fact-check M2, M3, M4, api F2, F3 | Distinct defects: three separate wording errors about one behaviour (the as-written relative candidate is never a root); A1-A3 |

---

To pass review, every 🟡 item must be fixed or carry a qualifying author note; 🟢 items are optional.

Loop decision at the cap: the fixes in 5070403e were verified by the full guard file (107/107), test/hooks (227/227), hermeticity-lint and a fix-drift subagent pass; no iteration 4 was run. Merge policy for this brief is review, so the owner reviews before landing.

Run notes:
- Delivery mode: self-read with a shared brief file. Agents read their own skill files.
- Stage 1: k=3 (opus). The fact-check gate fired on M1 (high-confidence behavioural Incorrect); taken as Continue (no user in a build loop).
- Stage 2: security, performance and api-consistency ran in parallel (opus). No contextual critics were triggered (tests change with the source; under 500 lines).
- Stage 2.5 was skipped (the pass carried a red).
- Executable-defect channel: the orchestrator re-ran R1's case against 98d78d32 (fails, exit 1 with a traceback) and 5070403e (passes).
- Tokens: fact-check about 124k + 137k + 140k, security about 117k, performance about 90k, api about 112k, fix-drift about 0.1M (no findings; 107/107, a 54-case deleted-cwd probe); about 0.82M in total, plus the orchestrator's own.
