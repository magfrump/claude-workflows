Commit: 881d87a9
# Code Review Rubric (pass 2)

**Scope:** fix/guard-worktree-taint, f5fbc9be..881d87a9 (full branch, 2 commits, 5 files, +616/-10) | **Reviewed:** 2026-11-19 | **Status: 🟡 DOES NOT PASS YET**. 0 red items; 6 amber items are open (1 behavioural, 5 docs).

Reports in this directory:
- code-fact-check-report.md (k=1, loop pass)
- security-review-2026-11-19.md
- performance-review-2026-11-19.md
- api-consistency-review-2026-11-19.md

Probes are under fact-check/, security/, performance/ and api/.

**Central question.** Is there a real policy file that asks at f5fbc9be and gets no ask at HEAD in a web-tainted session?
- Absolute paths: no. Fact-check checked 66+ paths in three hook versions. Security tried symlinks, `..`, case variants, nested worktrees, links into ~/.claude and the main checkout, and a root `.claude` symlink.
- Relative paths: yes. A relative spelling of a symlinked worktree-root `hooks/` or `settings*.json` loses the ask (A6, executed and re-run by the orchestrator).
- Contrived layouts: a worktree nested inside the main project's `.claude/commands|skills|agents/` also loses it (C7, Low).
- HARD paths: decided identically in all three versions; none ever reaches "ask".

---

## 🔴 Must Fix

None.

Pass-1 R1 (symlinked policy names lost the ask) is resolved for absolute paths. `_is_soft_path` now judges both the lexical and the resolved relative path, and bats R1 case :826 passes (it fails on f2829bcf). The same mechanism survives for relative spellings; see A6.

---

## 🟡 Must Address

| # | Finding | Domain | Severity | Source | Location | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|---|
| A6 | **A relative path to a symlinked worktree-root `settings.json`, `settings.local.json` or `hooks/` gets no ask in a tainted session. The parent f5fbc9be asked.** (Pass-1 R1's mechanism, limited to relative spellings.) `_verified_worktree` refuses a relative root (:282-283). So the as-written candidate falls back to `_is_soft_parts`, which has no root-only hooks/settings rule. Only the resolved candidate is judged against the root, and the symlink has removed the policy name from it. Names on the general SOFT list (`CLAUDE.md`) still ask. **Repro** (`review2/api/probe-rel.sh`, hermetic; re-run by the orchestrator): in a real `git worktree add` at `<repo>/.claude/wt-foo`, run `ln -s docs/x.md settings.json` and `ln -s docs/hk hooks`, taint the session, then Edit from cwd `<wt>` with `file_path` set to `settings.json`, `settings.local.json` or `hooks/x.sh`. The same happens from cwd `<wt>/sub` with `../settings.json`, and from cwd `<repo>/.claude` with `wt-foo/settings.json`. Parent: ask. HEAD: no output (defer). The absolute forms still ask. This contradicts the header (:51-53, "each relative to the root both as written and resolved") and research doc :94-96 ("same result as the absolute spelling"), which also fails the other way: a relative `.claude/wt-foo/x.md` from cwd `<repo>` asks while its absolute form defers (fact-check, over-ask only). **Reachability:** depends on whether Claude Code ever passes a relative `file_path` to a PreToolUse hook. Its Edit/Write tools document an absolute path; this is unverified here. **Fix:** add `Path(os.path.abspath(str(p)))` (or the abspath of `norm`) as a SOFT-only candidate in `classify_path`'s SOFT loop (:378-382), so the lexical judgement always has an absolute root; keep the HARD candidates unchanged. Add a bats case run from `cd "$w"` with symlinked `settings.json` and `hooks/`, and correct research :94-96. | Security / API consistency | api-consistency Inconsistent (executed); fact-check Mostly accurate (research :94-96) | api-consistency #1 + fact-check (the relative-path claim) | `hooks/guard-trusted-writes.py:282-283, :340-349, :361` | for-author | — | ✅ Fixed (076ba817) | — |
| A7 | **Residual R1 still says "Nothing loads those files as policy".** That contradicts the same doc at :131-132 and residual R2 (`.mcp.json`, files a CLAUDE.md @-imports). The A3 fix did not reach this bullet. **Fix:** say that ordinary-named files a forged worktree exposes are those residual R2 lists, and that Bash could write them anyway. | Docs | Fact-check Incorrect (doc) + api Minor | Fact-check + api-consistency #2 | `docs/working/research-2026-11-19-guard-worktree-taint.md:150-151` | for-author | — | ✅ Fixed (076ba817) | — |
| A8 | **The research doc names a rubric that does not exist and a stale test count.** :160 cites `docs/reviews/code-review-rubric-2026-11-19-guard-worktree-taint.md`; the real file ends in `-pass1.md`. :172 says "`bats test/hooks/`: 220/220", while HEAD has 223 cases and the commit says 223/223. The fact-check did not re-run the full `test/hooks` suite, so 223/223 is unchecked. **Fix:** correct the path and the count. | Docs | Fact-check Incorrect (doc) + Stale; api Minor | Fact-check + api-consistency #3 | `docs/working/research-2026-11-19-guard-worktree-taint.md:160, :172` | for-author | — | ✅ Fixed (076ba817) | — |
| A9 | **The header's list of a worktree's own policy files is imprecise.** skills/agents/commands/memories ask only for `.md`, `.txt` or extensionless names. CLAUDE.local.md, managed-settings.json and `*.mdc` ask but are not listed. :55-56 also leaves out `.git`, which is root-only like `hooks/`. **Fix:** make the list point at `_is_soft_parts` plus root `hooks/`, `settings*.json` and `.git`. | Docs | Fact-check Mostly accurate; api Minor | Fact-check + api-consistency #5 | `hooks/guard-trusted-writes.py:45-47, :55-56` | for-author | — | ✅ Fixed (076ba817) | — |
| A10 | **The `_is_soft_rel` docstring says this repo's root holds the harness's own "hooks and settings"**, but there is a root `hooks/` and no root `settings*.json`. Nested settings (e.g. `profiles/interview/settings.json`, which `install.sh` copies into a profile) now defer, as in the main checkout. **Fix:** reword to "root hooks (and any root settings*.json)" and list the nested hooks/settings and a nested repo's `.git/hooks` under residual R2 (security F2). | Docs | Fact-check Mostly accurate; security Informational | Fact-check + security F2 | `hooks/guard-trusted-writes.py:322-324`; research `:152-155` | for-author | — | ✅ Fixed (076ba817) | — |
| A11 | **Research :131-132 says the files that lose the ask are ones the main checkout leaves ungated.** That does not hold when a directory above the worktree root is named skills/agents/commands/memories: the main checkout asks and the worktree defers. Security found the live form (C7). **Fix:** either refuse such roots (C7's fix makes the claim true) or qualify the sentence. | Docs | Fact-check Mostly accurate | Fact-check | `docs/working/research-2026-11-19-guard-worktree-taint.md:131-132` | for-author | — | ✅ Fixed (076ba817) | — |

Evidence for A6 (`hooks/guard-trusted-writes.py:282-283`, verbatim):
> `        if not root.is_absolute():        # a relative candidate as written; its`
> `            return None                   # resolved form is anchored at the hook's cwd`

and `:341-343` (excerpt; `_is_soft_path` continues to :351, which was read):
> `        real = _verified_worktree(root) if root is not None else None`
> `        if real is None:`
> `            return _is_soft_parts(cand.parts)`

---

## 🟢 Consider

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C7 | **A real worktree nested inside the main project's `.claude/commands/`, `skills/` or `agents/` gets the relaxation.** `_worktree_root` never judges the path above the root (:262-274). Executed: `repo/.claude/commands/.claude/wt-c/evil.md` and the skills/agents equivalents go from ask to defer for Edit, Write and MultiEdit. No harness creates this layout, and whether Claude Code loads `.md` files from hidden subdirectories there is unverified (needs a live host). **Fix:** refuse a root when a case-folded SOFT segment sits above it (it then falls back to the blanket rule). Add one bats case. | security F1 (executed) | Low | for-author | — | 🟢 Open |
| C8 | **Pre-existing fail-opens in `main()`:** a list `file_path` raises TypeError at :514, and a taint dir that raises PermissionError on `exists()` at :469 makes the hook exit 1 and the tool proceed. Both happen in all three versions and are outside the diff. **Fix later:** coerce `fp` to a string and wrap `main()` so any exception fails closed (H2). | security F3 + fact-check escalation | Informational | for-author | — | 🟢 Open |
| C9 | **With `CLAUDE_CONFIG_DIR` pointing elsewhere, a worktree at `~/.claude/wt-x` gets the relaxation.** This follows the documented `config_dir()` rule. No action. | security F4 + fact-check | Informational | for-orchestrator-synthesis | — | 🟢 Open |
| C10 | **A bats test name keeps the pre-A2 wording "in or around the config dir".** | api-consistency #4 | Minor | for-author | — | 🟢 Open |
| C11 | **`_is_soft_rel`'s `rel.parts[0] == ".."` branch is unreachable** from its only caller, whose paths are already folded or resolved. | api #7 + fact-check | Informational | for-author | — | 🟢 Open |
| C12 | **Root `hooks/`, `settings*.json` and `.git` ask only in `.claude/` worktrees,** not in the main checkout or `.worktrees/`. This is documented, and over-asking is the safe direction. | api #6 | Informational | for-orchestrator-synthesis | — | 🟢 Open |
| C13 | **`_safe_resolve(HOME)` is recomputed for each candidate**; it could be computed at import. Deep symlink chains cost about 3× the parent's time but stay bounded (1500 links: ask in 74 ms). | performance F2/F3 | Informational | for-author | — | 🟢 Open |

---

## Pass-1 items carried forward

| Pass-1 # | Finding (short) | Pass-2 status | Evidence |
|---|---|---|---|
| R1 | Symlinked policy names in a `.claude/` worktree lost the ask | ✅ Resolved for absolute paths. The relative-spelling residue is new item A6 (🟡) | `_is_soft_path` :334-351 judges lexical and resolved. Fact-check, security and api verified by execution; bats R1 case passes, fails on f2829bcf |
| A1 | hooks/settings rules at any depth vs docs "at the root" | ✅ Resolved (root-only chosen) | `_is_soft_rel` :327-331; bats :839-845. Nested settings and `.mcp.json` ask→defer judged acceptable under S1 (security F2); doc follow-up in A10 |
| A2 | "outside home" wording | ✅ Resolved in hook and research doc. The f2829bcf commit body is immutable (Accepted-immutable candidate); the test-name leftover is C10 | hook :276-279, :309-310 |
| A3 | ".claude/wt-x loads nothing" claim | ◐ Partly resolved. :121/:131-132 reworded; R1 residual :150-151 still contradicts it (new A7) | fact-check |
| A4 | "relative path is never a worktree root" | ✅ Mechanism wording resolved (hook :282-283). The new "same result as absolute" claim is wrong in both directions; tracked in A6 | fact-check + api |
| A5 | Stale reproduction recipe | ✅ Resolved (now names `f5fbc9be:`) | fact-check |
| C1 | RecursionError fail-open in the realpath | ✅ Resolved (outer `except Exception: return True`) | Executed: 1500-link chain asks; NUL bytes and surrogates ask |
| C2 | FIFO at G/gitdir blocked the hook | ✅ Resolved | Executed: FIFO and symlink-to-FIFO variants ask in under 20 ms (f2829bcf: killed at 5 s). A lstat→open race remains, out of scope under S1 |
| C3 | Root re-verified once per candidate | 🟢 Open (Low) | 0.774 ms vs 0.078 ms, about 2% of hook runtime. Optional fix: dedupe `cands` |
| C4 | Helper names | ✅ Resolved | Old names appear only in the pass-1 rubric |
| C5 | Roadmap item still "briefed" | 🟢 Open (the landing cycle closes it) | `docs/roadmap.md:124-148` |
| C6 | Mixed bats "unverifiable root" case | 🟢 Open (not re-checked) | — |

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
| The guard bats file passes at HEAD, and the 3 new pass-1 cases (R1, A1, C1) fail on f2829bcf | ✅ Confirmed | 103/103 at HEAD; 100/103 on the f2829bcf hook (tests 78-80 fail); 94/103 on f5fbc9be (fact-check, executed, `fact-check/bats.out`) | Fact-check (executed) | for-orchestrator-synthesis |
| HARD paths are decided identically by f5fbc9be, f2829bcf and HEAD, and never reach "ask" | ✅ Confirmed (on the enumerated probe set) | Security probe1-3 and fact-check probe1-3 (executed), covering links into ~/.claude, home memory and the config-dir hooks | Fact-check + security (executed) | for-orchestrator-synthesis |

Endorsements were not routed to Stage 2.5. This is a loop pass, so routed claims stay pending.

---

## ⚠️ Unverified Findings

- A6's reachability: whether Claude Code ever sends a relative `file_path` to the hook. Needs a host check.
- C7's impact: whether Claude Code loads `.md` files from hidden subdirectories of commands/agents/skills. Needs a host check.

---

## ⏭️ Skipped Core Critics

All core critics ran; no skips applied.

---

## 🧩 Composition check

| Cluster | File / lines | Fragments | Disposition |
|---|---|---|---|
| 1 | `hooks/guard-trusted-writes.py:282-283, :340-349` + research :94-96 | api #1, fact-check (relative-path claim), fact-check escalation to api | Distinct defects: none. One root (a relative candidate has no absolute root for the lexical judgement); merged into A6 |
| 2 | `hooks/guard-trusted-writes.py:262-274` + research :131-132 | security F1, fact-check M (skills above root) | Distinct defects: the code gap (C7, Low) and the doc claim (A11) are tiered separately. C7's fix also makes the A11 claim true |
| 3 | `hooks/guard-trusted-writes.py:321-332` + research :152-155 | security F2, fact-check M (:322-324), api #6 | Distinct defects: none. One doc follow-up, A10; the behaviour was judged acceptable |

---

To pass review, every 🟡 item must be fixed or carry a qualifying author note; 🟢 items are optional. A6 is the only behavioural item.

Run notes:
- Delivery mode: self-read with a shared brief file (`shared-brief.md`). Each agent read its own skill file from the repo rather than having it pasted, a deviation from the skill.
- Stage 1: k=1 (opus), loop pass. The fact-check gate did not fire: no high-confidence behavioural Incorrect.
- Stage 2: security, performance and api-consistency ran in parallel (opus). No contextual critics were triggered.
- Stage 2.5 was skipped (loop pass).
- Executable-defect channel: the orchestrator re-ran A6's probe and it reproduced.
- Tokens: fact-check about 184k, security about 137k, performance about 101k, api about 137k; about 0.56M in total plus the orchestrator's own.
- Artifacts are in the scratch dir, not `docs/reviews/`, by the caller's instruction.
