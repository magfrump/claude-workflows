# Code Fact-Check Report

**Commit:** 46342d66
**Replication:** k=3
**Repository:** /workspace (worktree `/workspace/.claude/wt-q180`)
**Scope:** branch diff `git diff main...HEAD`, `chore/q180-repin-pastes` (46342d66) vs main (b71a4e9e): `docs/roadmap.md`, `docs/working/checkpoint-build-loop-handoff.md`, `docs/working/questions.md`, and the commit messages of 53bd1a56 and 46342d66
**Checked:** 2026-10-15
**Total claims checked:** 31
**Summary:** 22 verified, 7 mostly accurate, 0 stale, 1 incorrect, 1 unverifiable. Out-of-diff note: Q-180's own lines (on main) go stale when this branch lands (r3 Claim 27); listed under Escalations.

Merged most-severe-wins from `code-fact-check-report-r1.md`, `-r2.md`, `-r3.md` (all `Commit: 46342d66`). Evidence and probe logs live in each replicate's report, under `/tmp/claude-1000/-workspace/736a173d-70f8-4751-993a-da117d91dc21/scratchpad/cfc-r{1,2,3}/`. Verified claims carry a short body. The full evidence is in the replicate named.

---

## Claim 1: Q-162's "the hash names fixed content once the paste has checked that no replace refs, `info/grafts` or `shallow` file exists, and the merge itself ignores replace refs"

**Location:** `docs/working/questions.md:84` (Q-163 at `:115` and Q-164 at `:147` refer to it with "as for Q-162")
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which content can land, after the guard passes, that differs from what the pinned hash names, under the entry's own threat (an agent session that can plant hooks and config in `/workspace/.git`). It does not establish an exploit against the real `/workspace`.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Incorrect · r2=Mostly accurate · r3=Verified
**Replicate annotations:** r1: "a loose blob overwritten in `.git/objects` landed altered content with exit 0; git 2.39.5 checks commit-object hashes but not blob hashes on merge" · r1+r2+r3: "a planted merge driver (`info/attributes` + `merge.<x>.driver`) and `core.fsmonitor` run under `-c core.hooksPath=/dev/null`; in the checkpoint's order (Q-180's branch first) Q-164's merge three-way-merges `docs/roadmap.md` and `docs/working/questions.md`, so a driver decides what lands there; Q-162's own merge has no file changed on both sides" · r3: "the sentence is literally true about what the hash *names*; the gap is what lands" · r2: "gate code not affected"

The guard checks replace refs, grafts and shallow. The merge runs with `GIT_NO_REPLACE_OBJECTS=1 git -c core.hooksPath=/dev/null merge`. r1 executed two counterexamples (`cfc-r1/logs/probe-tamper.log`, `probe-merge-driver.log`): (a) a rewritten loose blob of a pinned commit merged with exit 0; (b) a planted merge driver wrote `PLANTED` into `docs/roadmap.md` and `docs/working/questions.md` during Q-164's paste. Both classes predate this branch, but the sentence now states a sufficient condition that does not hold.

**Evidence:** `docs/working/questions.md:84,88-93`; `cfc-r1/logs/probe-tamper.log`, `cfc-r1/logs/probe-merge-driver.log`, `cfc-r2/driver-probe.log`, r3's probe logs

---

## Claim 2: "five of those nine merges (Q-110, doc drift, Q-160 and the two docs branches) conflict with an earlier one, each only in the append-only `docs/reviews/override-log.md`"

**Location:** `docs/working/questions.md:84`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which of the nine re-merges conflicted and in which files. It does not establish pairwise conflicts among units off main.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Verified · r3=Verified
**Replicate annotations:** r1: "all five conflict with main's own new override-log rows; Q-110 and dd-015 conflict with no earlier unit at all, so 'with an earlier one' is wrong for those two"

The set of five and "only override-log" are right. The reason is wrong: they conflict with main's rows. Precise version: "five of those nine merges … conflict with main's new override-log rows."

**Evidence:** `cfc-r1` merge replay logs

---

## Claim 3: "Its diff from a760a5e5 is exactly main's own change since then"

**Location:** `docs/working/questions.md:86`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the tree diff a760a5e5..09a2876f against main's own change. It does not establish row order.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2: "identical added content; in `override-log.md` main's 15 rows sit before a760a5e5's rows rather than after, so the line-level diff is not identical" · r3: "tree equals a merge of a760a5e5 with main except the override-log order"

---

## Claim 4: Q-164's "with the questions, roadmap and override-log conflicts resolved again"

**Location:** `docs/working/questions.md:147`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the conflict file list of the U5 merge onto ready-r2.
**Legibility-target:** for-author
**Replicate verdicts:** r1=— · r2=Verified (note) · r3=Mostly accurate
**Replicate annotations:** r3+r2: "the merge also conflicted in `questions-archive.md` (an index row), the same omission Q-180 asked to fix in Q-162's list"

---

## Claim 5: Q-164's "U5's decision-015 idea dropped since main's Next 5 holds it"

**Location:** `docs/working/questions.md:147`
**Type:** Attribution
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the origin of the dropped Ideas bullet.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=— · r3=Verified (compound)
**Replicate annotations:** r1: "the idea came from the 2026-10-14 cycle commit 46942678 (moved to Ideas by e088c7e3), not from U5; dropping it is right"

---

## Claim 6: Q-167(b): "(on a launcher older than the fix, the third prints the project list instead: the install has not taken effect, so stop there)"

**Location:** `docs/working/questions.md:220`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each of the four lines' behaviour on main's launcher and on f6f37fad's.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Verified
**Replicate annotations:** r1+r2: "on a pre-fix launcher line 1 heads toward a launch (or exits 1) and line 2 already prints the list, so line 3 is not the first sign; the note should say the first line that does not print ERROR/exit=2 means the install has not taken effect"

---

## Claim 7: Checkpoint: "Q-149..Q-155 and Q-103 become the live asks"

**Location:** `docs/working/checkpoint-build-loop-handoff.md:48`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the status of Q-149..Q-155 on U5's branch.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Verified · r3=Mostly accurate
**Replicate annotations:** r1+r3: "Q-154 (C5) is filed answered and archived by U5; the live asks are Q-149..Q-153, Q-155 and Q-103"

---

## Claim 8: Q-162 Interim: "(its review: `docs/reviews/code-review-rubric-2026-10-15-chore-q180-repin-pastes.md`)"

**Location:** `docs/working/questions.md:105`
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** High
**Verification mode:** static
**Scope:** The file does not exist at 46342d66. This is the review in progress, so it must be committed before landing.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=— · r2=Unverifiable · r3=Unverifiable
**Replicate annotations:** none

---

## Claim 9: ready-r2 makeup: "main (as of b71a4e9e) plus seven reviewed units, the branch-verify … docs …, and the decision-015 divergent design", nine unit tips, every cycle-record merge already on main

**Location:** `docs/working/questions.md:84`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers first-parent history, second parents and ancestry against main.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

---

## Claim 10: "its override-log rows are exactly the union of a760a5e5's and main's"

**Location:** `docs/working/questions.md:86`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Sorted row sets; no row lost or duplicated.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

---

## Claim 11: "the first pin, a760a5e5, was built on b279a2ba and conflicted once Q-178 landed …"

**Location:** `docs/working/questions.md:86`
**Type:** Historical
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** merge-tree of a760a5e5 into main and into Q-178's first parent.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=— · r3=Verified
**Replicate annotations:** none

---

## Claim 12: "Paste the block into the container's shell … never in your host checkout"

**Location:** `docs/working/questions.md:84`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Wording against security final F2's recommendation. It does not establish where the user's host checkout lives.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r3: "nothing in the pastes guards against planted config; the container instruction is the only control" (see Claim 1)

---

## Claim 13: The guard refuses replace refs, `info/grafts` and `shallow` (incl. empty file and dangling symlink), under bash and zsh, in a linked worktree, and with `GIT_GRAFT_FILE` elsewhere

**Location:** `docs/working/questions.md:90,121,153`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Each planted state, both shells, a linked worktree. It does not establish anything about objects or merge drivers (Claim 1).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "a non-conflict merge failure still prints 'conflict'; nothing merged or deleted"

---

## Claim 14: The merge runs with `GIT_NO_REPLACE_OBJECTS=1` and hooks off; `git merge --abort` runs on failure

**Location:** `docs/working/questions.md:91,123,155`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** `.git/hooks` and a configured hooksPath hook did not fire. Merge drivers and fsmonitor do run (Claim 1).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2+r3: "merge drivers and core.fsmonitor still run"

---

## Claim 15: "Run it before Q-163 and Q-164: their pastes stop unless this merge is on main"

**Location:** `docs/working/questions.md:84,115,147`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Q-163 and Q-164 run on bare main.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

---

## Claim 16: Branch selection in Q-163/Q-164, and "both orders … land the same tree", including Q-180's branch landed first

**Location:** `docs/working/questions.md:115-124,147-156`; checkpoint `:10`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Both orders, under bash and zsh, with and without Q-180's branch first; the hardened text survives the U5 merge.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

---

## Claim 17: Q-163/Q-164 branch makeups (q145-r2 = ready-r2 + c035f2e7; u5-resolved-r2 = ready-r2 + e088c7e3; u5-and-q145-r2 = q145-r2 + u5-resolved-r2), c035f2e7 unchanged inside, U5's Q-103 and Q-149..Q-156 byte-identical to e088c7e3's, roadmap Next 3–6 + 7

**Location:** `docs/working/questions.md:115,147`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Parents, per-file content of the unit tips, entry bytes.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Mostly accurate (compound; see Claim 4)
**Replicate annotations:** none

---

## Claim 18: "Gate for the rebuilt tip (09a2876f): one fast red, build-loop-merge's T23 …; passes 3/3 alone; slow 300/300"

**Location:** `docs/working/questions.md:104`
**Type:** Test result
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Logs read and T23 re-run alone at 09a2876f, 3/3. The health log has no commit stamp, so it cannot itself prove it ran at 09a2876f.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r3: "log has no commit stamp"

---

## Claim 19: Q-167(b) line 3 `cc-isolated --profile '#' --list`: old launcher lists, f6f37fad exits 2

**Location:** `docs/working/questions.md:225`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Both launcher versions.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

---

## Claim 20: Q-169 pins d25254da (full hash); the block's sha256 is 032cc9a8…afb7; 498 lines with fences

**Location:** `docs/working/questions.md:263-266`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Extraction at the pinned commit.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

---

## Claim 21: Q-169 "'Not verified' (12 items …)"

**Location:** `docs/working/questions.md:270`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Count at d25254da.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

---

## Claim 22: Q-170 "since 2026-09-09 88 of 116 `devcontainer-config/` commits carry `Live-verified: no`"

**Location:** `docs/working/questions.md:280`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Non-merge commits at f050b487.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2+r3: "the DD doc it points to (`dd-015-step4-isolation-mechanism.md:34`, on `docs/dd-015-step4`) still says 87"

---

## Claim 23: Q-176 `mkdir ~/q092 && mkdir ~/q092/.claude && …` stops on an existing `~/q092`; the added prose

**Location:** `docs/working/questions.md:390,406`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Directory, file, symlink and dangling symlink at `~/q092` (fake HOME).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

---

## Claim 24: Roadmap "42 multi-file landings after cac2ba0c …; 25/42 …, 38/42 …, 4/42 …"

**Location:** `docs/roadmap.md:77-80`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Counted with the roadmap's definition at b279a2ba.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

---

## Claim 25: Q-162 "then deletes the twelve build-loop branches already merged into main, along with their worktrees"

**Location:** `docs/working/questions.md:84,93`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** All twelve are ancestors of main and have the named worktrees.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=— · r2=Verified · r3=—
**Replicate annotations:** single-replicate detection

---

## Claim 26: "The first tip, a760a5e5, added after that gate …"

**Location:** `docs/working/questions.md:103`
**Type:** Historical
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** First-parent history 3fe6d6e3..a760a5e5.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=— · r2=Verified · r3=—
**Replicate annotations:** single-replicate detection

---

## Claim 27: Checkpoint Date/Branch lines (U4c at 308196e7, U5 tip 7c91b974 not merged, lands inside 7326d715 or 6c841192)

**Location:** `docs/working/checkpoint-build-loop-handoff.md:2-3`
**Type:** Historical
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Ancestry and parents.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

---

## Claim 28: Checkpoint "The first Q-162 paste on 2026-10-15 aborted on the override-log conflict …; main was left clean"

**Location:** `docs/working/checkpoint-build-loop-handoff.md:10`
**Type:** Historical
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Reflog and status of /workspace main.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r3: "'main was left clean' rests on reflog evidence only"

---

## Claim 29: Checkpoint paste order and U5's rubric path on the branch

**Location:** `docs/working/checkpoint-build-loop-handoff.md:10,48`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** File exists at 7c91b974; the order was replayed.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Mostly accurate (compound; see Claim 7) · r2=Verified · r3=Verified
**Replicate annotations:** none

---

## Claim 30: Commit message 53bd1a56

**Location:** commit 53bd1a56
**Type:** Historical
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Hashes, guard, ancestor check, the listed entry changes, the gate.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

---

## Claim 31: Commit message 46342d66

**Location:** commit 46342d66
**Type:** Historical
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** The paste order and the abort claim.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

---

## Escalations

- `docs/working/questions.md:84,115,147` — planted merge drivers and `core.fsmonitor` run under the pastes; a rewritten loose blob merges unchecked (r1, r2, r3) → **security-reviewer**.
- `docs/working/questions.md:446-452` (Q-180 on main, outside the diff) — "Blocks: … Each says so in its Interim" and "Interim: every merge paste aborts" go stale once this branch lands; close Q-180 on landing (r3, Stale) → **orchestrator**.
- `dd-015-step4-isolation-mechanism.md:34` still says 87 (r1, r2, r3) → **orchestrator**.

## Verdict stability

- Clusters: 31 (including 2 single-replicate detections).
- All reporting replicates agreed: 22.
- Disagreed: 9. Claim 1 (I/MA/V), Claim 2 (MA/V/V), Claim 3 (MA/V/V), Claim 4 (—/V/MA), Claim 5 (MA/—/V), Claim 6 (MA/MA/V), Claim 7 (MA/V/MA), Claim 17 (V/V/MA compound), Claim 29 (MA compound/V/V).
- Agreement rate: 22/31 = 71%.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report at the output path you were given, structured per your skill.
- Answered: yes (merge of three replicates)
- Out of scope: none
- Escalate: Claim 1 to security-reviewer; Q-180 closure and the DD doc's 87 to the orchestrator
