Commit: 3e9e448

# Code Review Rubric

**Scope:** `ans/guard-q048-q050` net diff `970e525..3e9e448` (hooks/guard-trusted-writes.py +40/−8, test/hooks/guard-trusted-writes.bats +345, guides/bare-host-hook-wiring.md +14) | **Reviewed:** 2026-09-23 | **Status: 🟡 CONDITIONAL PASS** — 6 amber item(s) awaiting resolution or justification

## Review-fix loop history (3 passes + confirmation)

| Pass | HEAD | Fact-check | Outcome |
|---|---|---|---|
| 1 | 035869c | k=3, 24 claims, 6 Incorrect (unanimous) | The Q-048 worktree exemption let quote-split `..`, a quoted `"$HOME"` or a second `=`, and a symlinked `wt-*` dir write the real `~/.claude` (executed). Gate → user: **fix first**. |
| 2 | 835f99d | k=3 | The pass-1 routes closed. New routes: `cd <wt> && cd ..` / `../` into the parent project's `.claude/`, and same-command root swaps. Gate → user: **whole-command gate**. |
| 3 | 053c0b7 | k=3 | The pass-2 routes closed. New routes: `-t..`, `.{,.}`, `env -C`, `cp -P`/`-rs`, `git checkout`, `tar -x`, `find -delete`. Loop cap reached → user: **drop the exemption**. |
| confirm | 3e9e448 | k=1, 19 claims (11 V, 4 MA, 2 I, 2 U) | The exemption is fully withdrawn. The Q-048 tests pass against the 970e525 hook; the only failures there are the new N12/N15 tests. This rubric covers this pass. |

Per-pass reports: `docs/reviews/code-fact-check-report*-pass{1,2,3}-*.md`. Critics on the confirmation pass: security-reviewer and api-consistency-reviewer (opus).

---

## 🔴 Must Fix

None.

---

## 🟡 Must Address

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | The new Bash deny message ("Claude cannot write these: make the change outside Claude …", `hooks/guard-trusted-writes.py:291-295`) also fires for a project's or worktree's own `.claude/settings.json` and `.claude/hooks/`. Edit/Write can change those, so the message misdirects. The 970e525 wording was right for them. Fix: branch the message on whether the target could be global, or say "use Edit/Write for project files". | API / Docs | Incorrect (high), message-only; Inconsistent | Fact-check Claim 12b; api-consistency F1 (Convergence: fact-check + api) | for-author | — | 🟡 Open | — |
| A2 | The same Bash deny message advises "write that text with the Write tool and pass the file". A steered model can follow that literally: write the command to a script and run `bash <file>`. That is the logged A8 bypass, and it passes even in a tainted session. Fix: restrict the advice to prose (commit messages or PR bodies passed with `-F` or `--body-file`), and never suggest running a written file. | Security | Medium | security-reviewer M2 | for-author | A8 (2026-09-21) — inherited; this row is about the message steering toward it, not A8 itself | 🟡 Open | — |
| A3 | The docstring (`:54-55`) says worktree agents "use Edit/Write or absolute paths". An absolute worktree path that names a policy file is still denied, and a test pins that. The commit message's "absolute paths without a policy name" qualifier was dropped. | Docs | Incorrect (high), doc-only; Minor | Fact-check Claim 9c; api-consistency F4 | for-author | — | 🟡 Open | — |
| A4 | Claude can still edit the checkout files that the per-file-linked hooks `source` (`hooks/lib/usage-common.sh`, `scripts/lib/skill-paths.sh`), with no prompt even when tainted. They run on every tool call, so an injected edit persists. This predates the branch. The planned copy-based install (ans/copy-install) removes it, because the live hooks become copies. | Security | Medium | security-reviewer M1; fact-check (N12 edge cases) | for-author | — | 🟡 Open | Revisit trigger candidate: closes when the copy-based install is merged and run on the host. |
| A5 | Deny and guide wording is inconsistent. The file-tool deny (`:314-317`) says only "Claude's file tools cannot edit it", which points toward Bash, and Bash writes to a linked hook's checkout path get no opinion. The guide heading "can't be edited from Claude" is broader than the code, and its Bash sentence wrongly takes in the checkout `CLAUDE.md`, whose Bash writes are denied. | API / Docs | Inconsistent ×2; Mostly Accurate ×2 | api-consistency F2, F3; fact-check Claims 1, 5 | for-author | — | 🟡 Open | — |
| A6 | Two more docstring claims are imprecise. "No opinion" (`:56-58`) holds only when the command has no `.claude`, so a checkout under a `.claude/` dir is denied. The report glob (`:53`) matches only untracked pass reports plus unrelated tracked `pass2-r*` reports: commit the pass reports or narrow the glob. | Docs | Mostly Accurate ×2 | Fact-check Claims 10, 9b | for-author | — | 🟡 Open | — |

---

## 🟢 Consider

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | One unreadable entry in `~/.claude/hooks/` makes `is_dir()` raise. That stops the N12 loop (the `try` wraps the whole loop) and leaves the hooks after it editable. Fix: move the `try` inside the loop. | security-reviewer L3 | Low | for-author | — | 🟢 Open |
| C2 | Links inside a subfolder of `~/.claude/hooks/` are not resolved. | security-reviewer I4; fact-check | Informational | for-author | — | 🟢 Open |
| C3 | The two deny messages name the protected set differently. | api-consistency F5 | Minor | for-author | — | 🟢 Open |
| C4 | The guide cites internal IDs (Q-050, N2, A8), and wiring.json's `_comment` doesn't mention the resolved tier. | api-consistency F6, F7 | Informational | for-author | — | 🟢 Open |
| C5 | Unverifiable: "a hook deny has no approve option" (Claude Code UI behaviour), and the guide's reference to the copy-based install.sh, which is not merged yet. | Fact-check Claims (2) | Unverifiable | for-orchestrator-synthesis | — | 🟢 Open |

---

## ↩️ Considered Overrides

| Override (PR ref / Date) | Prior finding | Original → Override | Reason | This run's treatment |
|---|---|---|---|---|
| `answers-2026-09-20` / 2026-09-21 | N2: Bash writes still ungated for unusual spellings and whole-tree `cp -r` (`hooks/guard-trusted-writes.py:190-205`) | 🟡 → Deferred | text-based Bash tier; redesign pending | Inherited, not re-flagged. The withdrawn exemption's pass-3 routes were N2/A8-class; with the exemption gone, the diff no longer widens N2. |
| `answers-2026-09-20` / 2026-09-21 | A8: WRITE_PRIMITIVE misses `ln -sf`, `curl -o`, `tar -C`, `git config --global`… | 🟡 → Deferred | predates the branch | Inherited. A2 is a separate finding: the new message steers toward A8. |
| `answers-2026-09-20` / 2026-09-21 | N3: deny rules render single-slash and may match nothing | 🟡 → Deferred (host check) | unverified then | Not applicable to this diff. Since confirmed and fixed on `answers-2026-09-20` (aa21535). |
| `answers-2026-09-20` / 2026-09-21 | Commit `c5a7c96` / `4c7a2bb` message-claim rows | Accepted-immutable | merged history | Not applicable. |

---

## ✅ Confirmed Good

| Item | Verdict | Evidence | Source | Legibility-target |
|---|---|---|---|---|
| The Q-048 exemption is fully withdrawn: no worktree neutralization remains, and the Bash tier treats worktree paths as 970e525 did. | ✅ Confirmed | FC confirmation claims (executed): HEAD bats 85/85; the same file against the 970e525 hook passes every Q-048 test, failing only the new N12 and N15 tests. `rg -n "_neutralize_worktrees\|_WT_SEG" hooks/` → 0 code matches. | fact-check; security endorsement (route: code-fact-check) | for-orchestrator-synthesis |
| N12 resolution denies Edit/Write on the checkout target of a per-file-linked hook, a directory link (whole target), a dangling link, and a `hooks` dir that is itself a symlink. It defers for a copied hook's source. | ✅ Confirmed | FC confirmation claims (executed, temp HOME). Scope: top-level entries of `hooks/` only (C2); the sourced `lib` files are not covered (A4). | fact-check; security endorsement (route: code-fact-check) | for-orchestrator-synthesis |
| Every pass-1, pass-2 and pass-3 bypass command is pinned in `test/hooks/guard-trusted-writes.bats` as a deny test and passes. | ✅ Confirmed | bats 85/85 at 3e9e448 (orchestrator re-run: 185/185 across `test/hooks/` + link-claude-home-wiring) | fact-check; orchestrator | for-orchestrator-synthesis |

---

## ⚠️ Unverified Findings

All findings' evidence resolved.

---

## ⏭️ Skipped Core Critics

| Critic | Reason | Signal |
|---|---|---|
| performance-reviewer | No performance-domain change in the confirmation diff beyond one `iterdir()` over `~/.claude/hooks/` per hook process | `git diff --stat 970e525..3e9e448`: hook +40/−8, of which the loop is 9 lines; the rest is test and doc |

---

## 🧩 Composition check

| Cluster | File / lines | Fragments | Disposition |
|---|---|---|---|
| 1 | `hooks/guard-trusted-writes.py:291-295` | FC 12b, api F1, security M2 | distinct defects: a wrong audience (A1) and advice steering to A8 (A2) are separate mechanisms in one message; both fixed by one rewrite |
| 2 | `guides/bare-host-hook-wiring.md:59-70` | FC 1, FC 5, api F3 | distinct defects: stated completely; A5 |

---

To pass review, every 🔴 item must be resolved. Every 🟡 item must be fixed or carry a qualifying author note (a discoverable TODO or a concrete revisit trigger; see "Qualifying author note" in `skills/code-review/references/rubric.md`). 🟢 items are optional.
