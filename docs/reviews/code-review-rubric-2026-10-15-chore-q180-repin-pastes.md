Commit: 46342d66

# Code Review Rubric

**Scope:** `chore/q180-repin-pastes` vs main b71a4e9e (docs only: `docs/working/questions.md`, `docs/roadmap.md`, `docs/working/checkpoint-build-loop-handoff.md`) | **Reviewed:** 2026-10-15 | **Status: 🟡 CONDITIONAL**: all ambers fixed in the fix commit after 46342d66, unreviewed until iteration 2

Iteration 1: full-branch scope (`git diff main...46342d66`), the first pass (no `--loop-pass` flag): fact-check k=3 merged most-severe-wins into `code-fact-check-report.md` (replicates `-r1`, `-r2`, `-r3`; 31 clusters, agreement 22/31 = 71%), then `security-reviewer` (`security-review-2026-10-15-q180.md`). Delivery mode: self-read (agents read the 65 KB diff file, the skill files and a shared brief from disk). The Fact-Check Gate's high-confidence Incorrect (A1) was taken as "continue" without pausing: the fix needed the security critic's view. Stage 2.5 skipped: no routed endorsement claims.

---

## 🔴 Must Fix

None.

---

## 🟡 Must Address

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | Q-162's "the hash names fixed content once the paste has checked … replace refs, grafts, shallow" overclaims: planted merge drivers, filters (smudge), `core.fsmonitor`, `commit.gpgSign`+`gpg.program`, `info/attributes`, alternates and a rewritten loose blob all pass the guard; a driver decided Q-164's `questions.md`/`roadmap.md` (executed) (`questions.md:84,90,121,153`) | Security / Docs | Incorrect (high, executed); Medium | fact-check Claim 1 (r1; r2 MA; r3 V); security F1 | for-author | rows 830, 831 (the F1/F2 this unit was for) | Fixed (unreviewed) | Guard now refuses build-loop.sh's STATE_KEYS_RE keys (minus log.showsignature, plus `fsck.`), `info/attributes`, alternates, and runs `git -c core.commitGraph=false fsck --no-dangling`; merge adds `-c core.commitGraph=false`; prose says "the merged side is the reviewed commit" and names what is not checked. Passes on the real `/workspace` in ~5 s |
| A2 | No guard can stop a moved main, a shell alias for `git`/`test`, or a race with a running agent; the prose should say so and give the log check (`questions.md:84`) | Security | Medium | security F2 | for-author | — | Fixed (unreviewed) | Run with no agent working; check `git log --oneline --first-parent b71a4e9e..HEAD` first; names the shell and main limits |
| A3 | `/workspace` is a bind mount of the host checkout, so "never in your host checkout" misdescribes it; Q-169 starts with `cd ~/claude-workflows`, where a zsh prompt's `git status` runs a planted fsmonitor on the host (`questions.md:84,263`) | Security | Medium | security F3 | for-author | row 831 | Fixed (unreviewed) | Reworded to "which git runs"; Q-169 uses `git -C ~/claude-workflows` with no `cd`. Q-156's host release is outside this diff (see C3) |
| A4 | "five … conflict with an earlier one": they conflict with main's new rows; Q-110 and dd-015 conflict with no earlier unit (`questions.md:84`) | Docs | Mostly Accurate | fact-check Claim 2 | for-author | row 834 | Fixed (unreviewed) | "conflict with main's new rows" |
| A5 | "Its diff from a760a5e5 is exactly main's own change": same added content, but main's override-log rows sit before a760a5e5's (`questions.md:86`) | Docs | Mostly Accurate | fact-check Claim 3 | for-author | — | Fixed (unreviewed) | Says so |
| A6 | Q-164's conflict list omits `questions-archive.md` (`questions.md:147`) | Docs | Mostly Accurate | fact-check Claim 4 | for-author | row 834 | Fixed (unreviewed) | Added |
| A7 | "U5's decision-015 idea": it came from the 2026-10-14 cycle commit 46942678 (`questions.md:147`) | Docs | Mostly Accurate | fact-check Claim 5 | for-author | — | Fixed (unreviewed) | Attributed |
| A8 | Q-167(b)'s new note: on a pre-fix launcher lines 1 and 2 already go wrong, not only line 3 (`questions.md:220`) | Docs | Mostly Accurate | fact-check Claim 6 | for-author | row 837 | Fixed (unreviewed) | "stop at the first line that does not print `exit=2`" |
| A9 | Checkpoint "Q-149..Q-155 and Q-103 become the live asks": Q-154 is filed answered (`checkpoint-build-loop-handoff.md:48`) | Docs | Mostly Accurate | fact-check Claim 7 | for-author | — | Fixed (unreviewed) | Q-149..Q-153, Q-155, Q-103 |
| A10 | Q-180 (on main) goes stale on landing: "Each says so in its Interim", "every merge paste aborts" (`questions.md:451-452`) | Docs | Stale | fact-check escalation (r3 Claim 27) | for-author | — | Fixed (unreviewed) | Q-180 resolved and archived on this branch |
| A11 | Roadmap Now still names `merge/ready-2026-10-15` (lines 29, 42, 45) | Docs | Stale | orchestrator scan (override row 829's drift class) | for-author | row 829 | Fixed (unreviewed) | `-r2` |

---

## 🟢 Consider

| # | Finding | Source | Status | Author note |
|---|---|---|---|---|
| C1 | The pastes, hashes and expected sha256 are read from an agent-editable working tree (`questions.md`) | security F4 (Informational) | Fixed (unreviewed) | Q-162 says to take the block from `git show main:docs/working/questions.md` |
| C2 | Q-170 says 88; the DD doc it cites (`dd-015-step4-isolation-mechanism.md:34`, on the pinned `docs/dd-015-step4`) says 87 | fact-check Claim 22 annotation | Fixed (unreviewed) | Q-170 notes the recount; the doc is not edited (it is inside the pinned ready branch) |
| C3 | Q-156's host release crosses the same host/container line (out of this diff) | security F3 | Open | For the next cycle |
| C4 | Untested: a tampered object inside a pack, a crafted commit-graph or multi-pack-index, a working-tree `.gitattributes` with built-in `merge=union`, a planted `MERGE_HEAD` | security (Not tested) | Open | No endorsement claimed for either guard |
| C5 | A merge failure that is not a conflict still prints "conflict"; nothing is merged or deleted | fact-check Claim 13 annotation (r2) | Open | Wording only |
| C6 | The ready-r2 health log has no commit stamp (Claim 18 is Medium confidence); T23 re-run alone at 09a2876f by all three replicates, 3/3 | fact-check Claim 18 | Accepted | — |

---

## ✅ Confirmed Good

| Item | Evidence | Backing |
|---|---|---|
| ready-r2 re-merges the same nine unit tips onto b71a4e9e; override-log rows are exactly the union of a760a5e5's and main's | fact-check Claims 9, 10 (executed, all three replicates) | Scope covers parents, ancestry, sorted row sets |
| Q-163/Q-164 stop unless Q-162's merge is on main; each picks the right branch; both orders, with Q-180's branch first, land one tree (bash and zsh) | fact-check Claims 15, 16 (executed, all three) | Scope covers both orders, both shells |
| U5's Q-103 and Q-149..Q-156 entries byte-identical to e088c7e3's; c035f2e7 unchanged inside both Q-145 branches | fact-check Claim 17 (executed) | Scope covers entry bytes and per-file content |
| Q-169's pinned block hashes to 032cc9a8…afb7 at d25254da; Q-176's `mkdir` stops on any existing `~/q092` | fact-check Claims 20, 23 (executed) | — |

---

## ⏭️ Skipped Core Critics

| Critic | Reason | Signal |
|---|---|---|
| performance-reviewer | copy-only docs diff | `git diff --stat`: 3 `.md` files; no fact-check claim in the domain |
| api-consistency-reviewer | no public API surface | no exported symbol, schema, flag or config key changed |

## 🧩 Composition check

- `docs/working/questions.md:84-93` (fact-check Claim 1, security F1, F2, F3): composed → A1. All four fragments describe one root: the paste's guard checks only ref-level history rewrites while the threat is any agent-written `.git` state. The fix is to reuse the state gate's key list plus an object check, and to state the residue. (Inherits 🟡.)
- No other multi-source co-located cluster qualified.

## Considered overrides

Rows 829–841 (`chore/dev-cycle-2026-10-15-0357`, each deferred to Q-180) match this diff. Rows 830–838 are the items this unit applies. A1 supersedes 830 (grafts), A3 supersedes 831 (container or host), A6 covers 834, A8 covers 837. Row 841 (T69 timing) is unchanged.
