Commit: f2829bcf
# Code Review Rubric

**Scope:** fix/guard-worktree-taint, f5fbc9be..f2829bcf (full branch, 1 commit, 4 files) | **Reviewed:** 2026-11-19 | **Status: 🔴 DOES NOT PASS** — 1 red item(s) unresolved

Reports in this directory: code-fact-check-report.md (merged, k=3), code-fact-check-report-r1/r2/r3.md, security-review-2026-11-19.md, performance-review-2026-11-19.md, api-consistency-review-2026-11-19.md; probes under probe-*/.

---

## 🔴 Must Fix

| # | Finding | Domain | Severity | Source | Location | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|---|---|
| R1 | **Policy-named symlinks inside a verified `.claude/` worktree lose the ask in a web-tainted session.** `_soft_in_worktree` reduces every candidate to `os.path.realpath(cand)` before applying the name rules (`rel = Path(os.path.realpath(cand)).relative_to(real)`), so the name as written is never judged. Executed repro (temp HOME, tainted session, real `git worktree add` at `<repo>/.claude/wt-foo`): `ln -s docs/x.md CLAUDE.md` (also `AGENTS.md`, `docs/CLAUDE.local.md`, `settings.json`, `hooks -> docs/hk` then `hooks/x.sh`, `skills -> realskills` then `skills/x.md`, `.claude -> shared-claude` then `.claude/rules/r.md` / `.claude/output-styles/o.md`), then Edit `<wt>/CLAUDE.md`: the parent hook f5fbc9be returns ask, the new hook returns no decision. The same symlinks in the main checkout still ask. This is an honest layout (symlinked CLAUDE.md/AGENTS.md is common), so S1's hostile-author exclusion does not apply. It contradicts the header (:45-53, "own policy files stay SOFT", "Every candidate (as given, `..`-folded, resolved) is judged"), the docstring (:316-319), research doc :76-79/:86-88 and the commit body. **Fix:** also judge the lexical path relative to the lexical root (`Path(os.path.normpath(cand)).relative_to(root)`, SOFT on ValueError) with the same rules, and return SOFT if either the lexical or the resolved relative path is SOFT. Add bats cases for symlinked `CLAUDE.md`, `hooks/` and `.claude/` inside a worktree. An ordinary name that points at an ordinary file still defers, so the relaxation is kept. Severity bound: before this change, editing the target by its real name also got no ask. | Security | Fact-check Incorrect (high), behavioral; security Medium; api-consistency Inconsistent | Fact-check (r1+r2+r3, executed) + security-reviewer + api-consistency-reviewer. Convergence: fact-check + security + api | `hooks/guard-trusted-writes.py:324-335` | for-author | — | ✅ Fixed (881d87a9) |

Evidence (`hooks/guard-trusted-writes.py:324-325`, verbatim):
> `    try:`
> `        rel = Path(os.path.realpath(cand)).relative_to(real)`

---

## 🟡 Must Address

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | **The `hooks`, `settings*.json` and `.git` rules apply at any depth, and only inside `.claude/` worktrees**, while the research doc (:76-79) says "at the root". So `.claude/wt-foo/src/hooks/useX.ts`, `.vscode/settings.json` and `config/settings.json` still ask in a tainted session, but get no opinion in `.worktrees/wt-x` or the main checkout. The verdict therefore depends on where the worktree sits, and some ordinary repos (React `src/hooks/`) keep the per-edit asks the change set out to remove. The header and R2 also say worktrees behave "as in the main checkout". No regression: the parent hook asked on all of these. Fix: either limit the rules to the root (`low[0] == "hooks"`, `len(low) == 1` for settings*.json) or keep them at any depth and correct the docs. Over-asking is the safe direction. | API consistency / docs | Inconsistent; fact-check Mostly accurate (M5, r1+r2+r3) | api-consistency-reviewer + fact-check M5 | for-author | — | ✅ Fixed (881d87a9) | — |
| A2 | **The docstring and comment say "outside the config dir and home" and "never inside ... home's top level", but the code refuses only a root AT home or one that HOLDS home** (:308-310). A worktree under `$HOME/proj/.claude/wt-h` is relaxed (executed). This is not a gap, since `~/CLAUDE.md` is HARD and decided first, but the wording is wrong. The commit body (immutable) and research doc :122-123 repeat it. Fix: make :274-275, :303-304 and the research doc say "at or holding home", as the header at :50 does. | Docs | Fact-check Incorrect (high), comment-only (M4; r1 Incorrect, r2/r3 Mostly accurate) | Fact-check + security (Info) + api (Minor) | for-author | — | 🟡 Open | Commit-body part: Accepted-immutable candidate; record in override log on landing. |
| A3 | **"Claude Code loads nothing from `.claude/wt-x/<ordinary>`" is wrong as worded.** `<wt>/.mcp.json` now defers where the parent hook asked (executed), and CC loads it as project MCP config. Files @-imported from a CLAUDE.md are loaded too. This matches main-checkout behaviour and residual R2, so under S1 it is a valid relaxation, but the claim needs fixing. Fix: reword research doc :121 to point at R2. Optionally add `.mcp.json` to the SOFT names for every checkout. | Docs / security | Fact-check Incorrect (medium, r1; r2/r3 Unverifiable); security Informational | Fact-check M3 + security-reviewer | for-author | — | ✅ Fixed (881d87a9, 076ba817) | — |
| A4 | **"A relative file path ... is never a worktree root" is wrong.** The resolved candidate is anchored at the hook's cwd and gets worktree-relative treatment: with cwd inside the worktree, `chapter3.md` defers. The outcome is harmless (same as the absolute form), but the stated mechanism is wrong. Fix: reword research doc :89 and the comment at :256. | Docs | Fact-check Incorrect (medium), doc (M2, r1 only) | Fact-check | for-author | — | ✅ Fixed (881d87a9, 076ba817, 5070403e) | — |
| A5 | **The reproduction recipe is stale.** "running the new test file against `git show HEAD:hooks/guard-trusted-writes.py`" now names the fixed hook. Fix: say `f5fbc9be:` (research doc :19, :33-34). | Docs | Fact-check Stale (M6, r1 only) | Fact-check | for-author | — | ✅ Fixed (881d87a9) | — |

---

## 🟢 Consider

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | **H2 fail-open: the realpath at :325 is outside every try.** The except catches only ValueError, and neither `classify_path` nor `main()` has an outer handler. Executed: a chain of about 1500 symlinks inside the worktree, then Edit `<wt>/c/l1500`. The parent hook returns ask (rc 0); the new hook raises RecursionError and exits 1, and the tool proceeds. No honest layout reaches it. NUL bytes and lone surrogates fail closed only because the ValueError except happens to catch them. Fix (one line): `except Exception: return True`. Optionally wrap the SOFT loop so any exception returns "soft". | security-reviewer (executed) + fact-check r1 annotation | Low | for-author | — | 🟢 Open |
| C2 | **`open(g / "gitdir")` has no type or size check**, unlike `.git` at :285-287. If G/gitdir is a FIFO the hook blocks until timeout (executed: killed by `timeout 5`, exit 124). It needs forged metadata, so it is out of scope under S1. Fix: reuse the lstat + S_ISREG + 4096-byte check. | performance-reviewer | Informational | for-author | — | 🟢 Open |
| C3 | **The worktree root is re-verified from scratch for each of the three candidates.** An ordinary worktree file costs about 0.78 ms against 0.08 ms before, which is small next to roughly 17 ms of Python startup. Optional fix: a local per-call cache keyed by root. | performance-reviewer | Low | for-author | — | 🟢 Open |
| C4 | **Naming:** `_is_linked_worktree` returns a path, not a bool. `_soft_in_worktree` is the SOFT check for every path, not only worktree ones. | api-consistency-reviewer | Minor | for-author | — | 🟢 Open |
| C5 | **The roadmap item `docs/roadmap.md:124-148` still reads "briefed".** Close it when landing. | api-consistency-reviewer | Informational | for-author | — | 🟢 Open |
| C6 | **The bats "unverifiable root" case (:870) mixes in three paths that are not worktree-shaped**, so it tests "no root" as well as "unverifiable root". | fact-check r1 annotation | Informational | for-author | — | 🟢 Open |

---

## ↩️ Considered Overrides

| Override (PR ref / Date) | Prior finding | Original → Override | Reason | This run's treatment |
|---|---|---|---|---|
| `answers-2026-09-20` / 2026-09-21 (log row 98) | Bash writes still ungated for several spellings, `hooks/guard-trusted-writes.py:190-205` (security) | 🟡 Must-Address → Defer | Pre-existing, outside that branch's scope | Category match only (same file, security): Bash tier untouched by this diff. Not re-flagged. |
| `answers-2026-09-20` / 2026-09-21 (log row 103) | A8: WRITE_PRIMITIVE misses `ln -sf`, `curl -o`, etc. (security) | 🟡 Must-Address → Defer | Pre-existing gap | Category match only: Bash tier untouched. Not re-flagged. |

---

## ✅ Confirmed Good

| Item | Verdict | Evidence | Source | Legibility-target |
|---|---|---|---|---|
| The SOFT name rules outside a verified worktree are unchanged | ✅ Confirmed | `hooks/guard-trusted-writes.py:222` "def _is_soft_parts(parts) -> bool:". Old inline rules vs `_is_soft_parts` gave 0 differences on 25,438 / 128,291 / 1,465,082 generated paths (FC r1/r2/r3, executed). | Fact-check (executed) | for-orchestrator-synthesis |
| The 12 new tests pin the change: 7 fail on f5fbc9be, all on defer assertions; 100/100 in the guard file, 220/220 in test/hooks; hermeticity-lint passes | ✅ Confirmed | `test/hooks/guard-trusted-writes.bats:783` "# --- File tools inside a linked worktree under .claude/" (FC r1/r2/r3, executed) | Fact-check (executed) | for-orchestrator-synthesis |
| The enumerated unverifiable roots fail closed: plain dir, missing, dangling gitdir, wrong back-pointer, `.git` dir, `.git` symlink, modules/ gitdir, copied pointer, unreadable `.git`, config-dir root, CLAUDE_CONFIG_DIR inside the worktree | ✅ Confirmed | `hooks/guard-trusted-writes.py:289-290` "except Exception:" / "return None". Each case was executed in the bats file and the probes (FC claims, executed). | Fact-check (executed) | for-orchestrator-synthesis |

Security endorsements routed to code-fact-check (HARD-first deny through a worktree link, out-of-worktree resolution keeps the ask, config-dir roots refused): pending execution verification. Stage 2.5 did not run (see below). HARD-first is also covered by bats :789-801 (executed in FC test runs).

---

## ⚠️ Unverified Findings

All findings' evidence resolved.

---

## ⏭️ Skipped Core Critics

All core critics ran; no skips applied.

---

## 🧩 Composition check

| Cluster | File / lines | Fragments | Disposition |
|---|---|---|---|
| 1 | `hooks/guard-trusted-writes.py:316-335` | FC M1, security F1, api #2 | distinct defects: none. All three fragments state the same complete mechanism and fix, already merged into R1 |
| 2 | `hooks/guard-trusted-writes.py:324-327` | security F2, FC r1 annotation | distinct defects: the RecursionError fail-open (C1) is a different failure from R1's name-blindness, though both sit on the same line |
| 3 | `hooks/guard-trusted-writes.py:330-333` + research :76-79 | api #1, FC M5 | distinct defects: none. Same root (rule scope vs doc), merged into A1 |
| 4 | `hooks/guard-trusted-writes.py:274-275, :303-310` | FC M4, security F4, api #3 | distinct defects: none. Merged into A2 |

---

To pass review: all 🔴 items must be resolved. All 🟡 items must be either fixed or
carry a qualifying author note (a discoverable TODO or a concrete revisit trigger; see
"Qualifying author note" in `skills/code-review/references/rubric.md`). 🟢 items are optional.

Run notes: delivery mode self-read, with a shared brief file. Stage 1 k=3 (opus); verdict agreement about 80%, and M1 was 3/3. The fact-check gate auto-continued (no user present). Stage 2: security, performance and api-consistency ran in parallel (opus); no contextual critics were triggered (tests changed, under 500 lines, no UI, deps or module restructuring). Stage 2.5 was skipped, which is a deviation: routed endorsements were left pending and not used for ✅ rows. Tokens: fc 3×~126k, critics ~82k + ~107k + security (not reported) ≈ 0.6M+ total.
