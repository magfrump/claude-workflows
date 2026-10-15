Commit: 2141f7ee

# Code Fact-Check Report

**Repository:** claude-workflows (worktree `/workspace/.claude/wt-dev-cycle-2026-10-15-0357`, branch `chore/dev-cycle-2026-10-15-0357`)
**Scope:** `git diff main...2141f7ee` (main = 7f711bfe), final confirming pass, replicate 2 of 3. Files with checkable claims: `docs/reviews/override-log.md`, `docs/roadmap.md`, `docs/working/cycles/cycle-2026-10-14.md`, `docs/working/questions-archive.md`, `docs/working/questions.md`, and the merge commit 16136a60. The review reports and rubric under `docs/reviews/` are inputs, not graded.
**Checked:** 2026-10-15
**Total claims checked:** 32
**Summary:** 26 verified, 5 mostly accurate, 0 stale, 0 incorrect, 1 unverifiable

Execution environment: git 2.39.5, zsh 5.9, jq 1.6. Every paste ran in a throwaway clone of `/workspace` (`$S/clone`) or a fake HOME under `$S` = `/tmp/claude-1000/-workspace/b1fde0b4-befb-4424-9add-ef12273f2f26/scratchpad/final-fc-2/`. Raw output is in `$S/logs/`. `claude` was stubbed and docker was never called. No merge or ref move touched the real repository, and no process is still running.

Hallucination-pattern log: read. No claim here matches a logged fabrication. Claims 4 and 25 are count claims, the same family as the logged "85 vs 97 tests" and "mode1-equiv 33 vs 25" entries, but here the gap comes from the counting window or method, not from an invented number. Neither is a fabrication, so the log gets no new entry (the brief also forbids editing tracked files).

---

## Claim 1: "User-routed questions grow from 2 to 15 (`you: judgment` 1 to 10) … tech-debt-triage F2, Medium" / "Branch hashes and statuses are copied … the copies drifted (five vs seven units, "Next 3", 22a4bb1f vs d25254da, Q-106 "on" the ready branch) … tech-debt-triage F3, Low"

**Location:** `docs/reviews/override-log.md:828-829`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers whether the two new rows restate F2's and F3's counts, order chains, severities and drift examples, and whether F3's drifted strings are corrected at 2141f7ee. It does not establish whether the rubric's "Defer" disposition is right; that is the rubric's call.
**Legibility-target:** for-orchestrator-synthesis

The report's F2 table reads `| you: judgment | 1 | 10 |` and `| you: terminal | 1 | 5 |` (`docs/reviews/tech-debt-triage-review-2026-10-15-0357.md:50-51`), which gives 2 → 15 in total. Its chain list `(Q-162 → Q-167; Q-165 → Q-166/Q-169; Q-176 → Q-177; Q-172 → Q-173; Q-162 before Q-163/164)` (`:60`) matches the row's order list. `### F2.` carries `**Severity:** Medium` (`:43-44`). F3 carries `**Severity:** Low` (`:74-75`), and it quotes the four drifted strings, "main plus five reviewed units", "roadmap Next 3", `c6d7544f, on merge/ready-2026-10-15` and `22a4bb1f` (`:79-82`). The row's claim "Each drifted copy found here is corrected in this landing" holds at HEAD:
- Q-162 now says "seven reviewed units" (`docs/working/questions.md:83`).
- Q-165 says "(roadmap Now, …)" (`:165`).
- Q-174 says "built on an earlier `merge/ready-2026-10-15` commit, 184396ea; it is not in the ready branch" (`:343`).
- The roadmap says "tip d25254da" (`docs/roadmap.md:52`).

**Evidence:** `docs/reviews/override-log.md:828-829`, `docs/reviews/tech-debt-triage-review-2026-10-15-0357.md:43-91`, `docs/working/questions.md:83,165,343`, `docs/roadmap.md:51-52`

---

## Claim 2: Roadmap Now: every branch, hash and "waits on" in the Now list

**Location:** `docs/roadmap.md:14-56`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each named branch existing at the named hash, not being merged into main, and its stated relation to `merge/ready-2026-10-15` (in it or not), plus each cited waiting-on Q-id existing on this branch. It does not establish the review outcomes each line reports ("loop closed", "independent closing review was clean"), which live in rubrics on other branches.
**Legibility-target:** for-orchestrator-synthesis

Command: a loop of `git rev-parse refs/heads/$b`, `git merge-base --is-ancestor $r main` and `git merge-base --is-ancestor $r a760a5e5` over all 19 branches named in the diff. It ran in the worktree at 2026-10-15T20:10:27Z, exit 0. The results:
- Every hash matches its branch tip: `fix/t69-stage-race` 4ee81106, `fix/doc-drift-cycle1` c8e87a69, `fix/q160-iteration-cap` 4a44d2f3, `fix/q096-exit-scan-insteadof-target` 8717fd72, `fix/rebuild-hint-recreate` 47da5a4b, `fix/cc-isolated-one-workspace` f6f37fad, `fix/q096b-exit-scan-remote-names` 75d08a94, `fix/q092a-drop-deny-option` d27a3891, `fix/q092-drop-hook-deny-reader` aeda94b2 and `docs/branch-verify-without-install` d25254da.
- None is merged into main.
- The seven "in `merge/ready-2026-10-15`" units are ancestors of a760a5e5. Q-092's two units and Q-168's branch are not, which matches the lines that do not claim the ready branch for them.
- Each waits-on ID (Q-162, Q-163, Q-164, Q-165, Q-166, Q-167, Q-169, Q-171, Q-172, Q-173, Q-176, Q-177) is an open entry in `docs/working/questions.md`.

**Evidence:** `docs/roadmap.md:14-56`; `/tmp/claude-1000/-workspace/b1fde0b4-befb-4424-9add-ef12273f2f26/scratchpad/final-fc-2/logs/refs-sizes-mergetree.log` (section "refs.log")

---

## Claim 3: "(… was Next 4)", "(… was Next 3)" ×3

**Location:** `docs/roadmap.md:24`, `:41`, `:44-45`, `:51`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers whether each item held that Next position at some commit in the roadmap's history. It does not establish anything about today's Next numbering beyond the absence of stale "Next N" pointers in the touched files (Claim 30).
**Legibility-target:** for-orchestrator-synthesis

Paraphrased (no quote available because the claim is about which item held position 3 across 20 roadmap revisions). `git log` over `docs/roadmap.md`, printing each revision's Next item 3, shows the sequence: "Verify a branch without installing it on the host" (46942678, 63af3551 and main's d7e140ea), then "The launcher's rebuild hint misleads…" (de9590ad…7550465b), then "Reject a second workspace argument…" (d4445c9a…3356974b), then the current `--profile` item (782036de onward). Q-145 is main's Next 4 at b279a2ba (`4. **Q-145 — the lib's ancestor listing skips vanished entries.**`). A search for `Next [0-9]` in `docs/working/questions.md` finds only "Next 1" (router uptake, `:70,74,77,78`), which is still Next 1.

**Evidence:** `docs/roadmap.md:24,41,45,51`; `git show b279a2ba:docs/roadmap.md` (Next 4)

---

## Claim 4: "Cycle 2 (2026-10-14): 42 multi-file landings; 25/42 carry the line, 38/42 committed a rubric, 4/42 have neither (df18413a, 0fbf9742, b8807e76, 52053432)"

**Location:** `docs/roadmap.md:77-79`; same figures at `docs/working/cycles/cycle-2026-10-14.md:55`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four figures and the four named hashes against main at b279a2ba, counted with the roadmap's own definition (`:28-31`: carries `← carried from RPI` and the branch committed a code-review rubric). It does not establish the cycle-3 figures (main's text) or the "About 36 are units of the one build-loop plan" estimate.
**Legibility-target:** for-author

Command: `$S/uptake.sh b279a2ba 2026-10-02`, which walks first-parent merges with committer date (committer's zone) ≥ 2026-10-02 and keeps those whose diff against the first parent touches more than one file. It ran in the worktree, exit 0, and printed `tip=b279a2ba n=45 line=25 rubric=40 neither: df18413a 0fbf9742 b8807e76 52053432 188e0a7d`. The three extra merges are cycle 1's own landings: 90364c73 (286 files, rubric yes), 188e0a7d (2 files, neither) and cac2ba0c (17 files, rubric yes). Subtracting them gives exactly 42/25/38/4 and the four named hashes. The figures are right as "since cycle 1's landings". But the cycle record's stated window reads:

```
// docs/working/cycles/cycle-2026-10-14.md:6
Window: since 2026-10-02 (…). Merges, commits and section 7's changed files: those on `main` at b279a2b whose committer date (in the committer's time zone) is on or after 2026-10-02
```

That window yields 45/25/40/5. The precise version would say "since cac2ba0c" or "excluding cycle 1's three landings".

**Evidence:** `docs/roadmap.md:77-79`, `docs/working/cycles/cycle-2026-10-14.md:6,55`; `/tmp/claude-1000/-workspace/b1fde0b4-befb-4424-9add-ef12273f2f26/scratchpad/final-fc-2/logs/refs-sizes-mergetree.log` (section "uptake")

---

## Claim 5: Next 4 "(`feat/q106-host-settings-merge`, c6d7544f; it also closes Q-108)" and Next 5 "(`docs/dd-015-step4`, f050b487, lands with Q-162)"

**Location:** `docs/roadmap.md:92-97`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the hashes, that f050b487 is inside a760a5e5 (so it lands with Q-162), and that Q-108 is open. It does not establish that Q-106's branch actually closes Q-108's stale lines.
**Legibility-target:** for-orchestrator-synthesis

`refs/heads/feat/q106-host-settings-merge` = c6d7544f and `refs/heads/docs/dd-015-step4` = f050b487. The ready branch's first-parent log contains `11184f2b 9660d4f6 f050b487 Merge branch 'docs/dd-015-step4' into merge/ready-2026-10-15`. Q-108 is open (`### Q-108 · decision-037-stale-lines` … `**Status:** OPEN`).

**Evidence:** `docs/roadmap.md:92-97`; `/tmp/claude-1000/-workspace/b1fde0b4-befb-4424-9add-ef12273f2f26/scratchpad/final-fc-2/logs/refs-sizes-mergetree.log`

---

## Claim 6: "12 merged branches (feat/build-loop-u3a1…u4c) and their worktrees go in Q-162's paste" · "`questions.sh init` and `archive` ran (1 archived: Q-089)"

**Location:** `docs/working/cycles/cycle-2026-10-14.md:13`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the twelve `feat/build-loop-u3a1…u4c` branches are merged into main, each has a registered and clean worktree at `/workspace/.claude/wt-build-loop-<u>`, and Q-089 is archived. It does not establish the health-check outcomes in the same paragraph (T69 3/3, 4/4).
**Legibility-target:** for-orchestrator-synthesis

All 12 branches are ancestors of main. `git worktree list` shows `/workspace/.claude/wt-build-loop-u3a1 … [feat/build-loop-u3a1]` through `u4c`. `git -C <wt> status --porcelain` prints 0 lines for each, so `git worktree remove` will not refuse on a dirty tree. Q-089 appears in the archive with `**Status:** ANSWERED` (`docs/working/questions-archive.md:2718-2727`).

**Evidence:** `docs/working/cycles/cycle-2026-10-14.md:13`, `docs/working/questions-archive.md:2718-2727`; `/tmp/claude-1000/-workspace/b1fde0b4-befb-4424-9add-ef12273f2f26/scratchpad/final-fc-2/logs/worktrees.log` (a loop over the 12 branches running `git merge-base --is-ancestor`, `git worktree list` and `git -C <wt> status --porcelain`; cwd the worktree, 2026-10-15T20:14:27Z, exit 0)

---

## Claim 7: "`CLAUDE_HOME_SRC` and `assemble()` are still in `devcontainer-config/install.sh` (:135, :329-362; callers :498 and :858), and `link-claude-home.sh:50` keeps a second copy of the names"

**Location:** `docs/working/questions-archive.md:2738`
**Type:** Reference / Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the five line numbers on main (the branch does not touch these files). It does not establish the "one test pins `scripts`" aside, or 036's interpretation of [11].
**Legibility-target:** for-orchestrator-synthesis

```
# devcontainer-config/install.sh:135 (main)
CLAUDE_HOME_SRC=(global-instructions/CLAUDE.md skills workflows guides patterns hooks scripts)
# :329 assemble() {   … :362 }
# :498   assemble "$stage/claude-home" "${dc_paths[@]}"
# :858   assemble "$stage"
# devcontainer-config/link-claude-home.sh:50
ENTRIES=(skills workflows guides patterns hooks scripts CLAUDE.md)
```

The roadmap Idea's "seven source paths are in `install.sh:135`" (`docs/roadmap.md:117`) also holds: 7 entries.

**Evidence:** `devcontainer-config/install.sh:135,329,362,498,858`, `devcontainer-config/link-claude-home.sh:50`

---

## Claim 8: "Built and merged on Q-148 [1]: A1+A2 as 626dc300, B as df18413a (`host_tool_files()`, `host-tools.sha256`, the `Host-tool-tested:` trailer, `verify_host_tools` in cc-push, decision log row 71)"

**Location:** `docs/working/questions-archive.md:2727`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that both merges are on main with the named subjects and that the named symbols exist on main. It does not establish that "the host check after install.sh is still owed" (host state).
**Legibility-target:** for-orchestrator-synthesis

`626dc300 … Merge branch 'feat/q089a2b-cc-push-self-check': … (Q-089 units A1+A2, Q-148 [1])` and `df18413a … Merge branch 'feat/q089b4-host-tool-gate': … (Q-089 unit B, Q-148 [1])`. On main: `devcontainer-config/cc-isolated.sh:199: host_tool_files() {`, `devcontainer-config/cc-push.sh:157: verify_host_tools() {`, and `docs/decisions/log.md:94` starts `| 71 | 2026-10-14 | **Host-only tools are their own trust category…`.

**Evidence:** `docs/working/questions-archive.md:2727`, `devcontainer-config/cc-isolated.sh:199`, `devcontainer-config/cc-push.sh:157`, `docs/decisions/log.md:94`

---

## Claim 9: "That branch is main (as of b279a2ba) plus seven reviewed units, the branch-verify research and spike docs, the decision-015 divergent design, and this cycle's record, each merged with `--no-ff`" · "The tip, a760a5e5, adds after that gate the rebuild-hint and one-workspace unit merges, two docs-branch merges and nine cycle-record merges"

**Location:** `docs/working/questions.md:83`, `:102`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the first-parent structure of `b279a2ba..a760a5e5`. It does not establish the health-check results quoted at `:102` (300/300, build-loop-check 983).
**Legibility-target:** for-orchestrator-synthesis

`git log --first-parent b279a2ba..a760a5e5` lists 19 merges:
- seven unit merges: t69, q110, doc-drift, q160, q096, rebuild-hint and one-workspace;
- two docs merges: `docs/branch-verify-without-install` at d25254da and `docs/dd-015-step4` at f050b487;
- ten `chore/dev-cycle-2026-10-15-0357` merges.

The first merge's first parent is b279a2ba. After the gate commit 3fe6d6e3 come exactly 2 unit merges, 2 docs merges and 9 chore merges (7e9c039c, 9660d4f6, 184396ea, 00a27a2f, 5e6e9266, 1d67d12c, 7a9cf412, 302c3810, a760a5e5).

**Evidence:** `docs/working/questions.md:83,102`; `/tmp/claude-1000/-workspace/b1fde0b4-befb-4424-9add-ef12273f2f26/scratchpad/final-fc-2/logs/refs-sizes-mergetree.log` (first-parent section)

---

## Claim 10: "It exists because every pair of these units conflicts only in the append-only `docs/reviews/override-log.md`"

**Location:** `docs/working/questions.md:83`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers pairwise `git merge-tree` of the seven unit tips. It does not establish how the units conflict with today's main (Claims 11 and 16).
**Legibility-target:** for-author

The command was `git merge-tree --write-tree --name-only $a $b` for each non-ancestral pair of 4ee81106, f5b7e49d, c8e87a69, 4a44d2f3, 8717fd72, 47da5a4b and f6f37fad. It ran in the worktree, exit 0 overall, and gave:
- three conflicting pairs, all on one file: `f5b7e49d c8e87a69 rc=1 docs/reviews/override-log.md`, `f5b7e49d 4a44d2f3 rc=1 docs/reviews/override-log.md` and `c8e87a69 4a44d2f3 rc=1 docs/reviews/override-log.md`;
- seven pairs that merge clean (rc=0), such as `4ee81106 f5b7e49d rc=0`;
- eleven pairs that are ancestral, because the last two units are built on the ready branch.

The mechanism is right: no conflict anywhere but override-log. "Every pair conflicts" overstates it. Precise version: "the only conflicts among these units are in the append-only override-log".

**Evidence:** `docs/working/questions.md:83`; `/tmp/claude-1000/-workspace/b1fde0b4-befb-4424-9add-ef12273f2f26/scratchpad/final-fc-2/logs/refs-sizes-mergetree.log` (section "unit pairs merge-tree")

---

## Claim 11: "**Not runnable yet (2026-10-15):** … After Q-178's landing of the 0357 cycle branch, merging a760a5e5 conflicts in `docs/reviews/override-log.md` (and, before it, in the questions, roadmap and idea-log files), so the paste below aborts and deletes nothing."

**Location:** `docs/working/questions.md:85`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers merge-tree and an actual run of the paste against main (7f711bfe) and against main plus a `--no-ff` landing of 2141f7ee (tree-identical to 2141f7ee). It does not establish what a rebuilt ready branch will conflict with.
**Legibility-target:** for-author

Against HEAD (the post-landing tree): `git merge-tree --write-tree --name-only 2141f7ee a760a5e5` gives `CONFLICT (content): Merge conflict in docs/reviews/override-log.md`, exit 1, and nothing else. The stated reason holds. HEAD appends the F2 and F3 rows at `override-log.md:828-829`, and a760a5e5 appends the units' rows at the same end of the file. The paste run on the landed clone printed `conflict: merge aborted, nothing deleted`, exit 1, HEAD unchanged, tree clean.

Before landing (against main), the conflict list is `docs/roadmap.md`, `docs/working/idea-log.md`, `docs/working/questions-archive.md` and `docs/working/questions.md`. The parenthetical names questions, roadmap and idea-log but omits `questions-archive.md`. Precise version: "(and, before it, in the questions, questions-archive, roadmap and idea-log files)".

**Evidence:** `docs/working/questions.md:85`; `/tmp/claude-1000/-workspace/b1fde0b4-befb-4424-9add-ef12273f2f26/scratchpad/final-fc-2/logs/refs-sizes-mergetree.log`, `…/logs/q162-main.log`, `…/logs/q162-landed.log`, `…/logs/runs.log`

---

## Claim 12: Q-162's paste: "a hash cannot [move], once the paste has checked that no replace refs exist"; on conflict "merge aborted, nothing deleted"; on success it "deletes the twelve build-loop branches already merged into main, along with their worktrees"

**Location:** `docs/working/questions.md:88-91`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the guard order (branch check, replace-ref guard, merge-or-abort, then cleanup only after a successful merge), executed for the guard and the conflict paths. The success path's cleanup is covered statically: twelve merged branches and twelve clean worktrees at the relative paths. It does not establish the success path end to end, because no state exists today in which a760a5e5 merges clean.
**Legibility-target:** for-orchestrator-synthesis

```
# docs/working/questions.md:88-91
cd /workspace && test "$(git branch --show-current)" = main && \
{ test -z "$(git for-each-ref refs/replace/)" || { echo "replace refs present: stop"; false; }; } && \
{ git merge --no-ff a760a5e5057ef3f0abd13145e7d945ef500b8abd -m "…" || { git merge --abort; echo "conflict: merge aborted, nothing deleted"; false; }; } && \
for u in u3a1 u3a2 u3a3 u3b1 u3b2 u3b3 u3c u3d u4a u4b1 u4b2 u4c; do git worktree remove .claude/wt-build-loop-$u && git branch -d feat/build-loop-$u; done
```

The block was extracted from `git show 2141f7ee:docs/working/questions.md`, with only `cd /workspace` replaced by the clone path, and run under `timeout 60 bash` in `$S/clone`:
- On main at 2026-10-15T20:02:06Z it exited 1 with `conflict: merge aborted, nothing deleted`. HEAD stayed at 7f711bfe, the tree was clean, and the loop did not run.
- On the landed clone at 20:02:36Z: the same, exit 1.
- With `git replace 7f711bfe 2141f7ee` in place (20:02:37Z) it exited 1 with `replace refs present: stop` and no merge.

The full hash resolves to a commit. `/workspace` is where the twelve worktrees are registered (`/workspace/.claude/wt-build-loop-u3a1`…), so the relative paths are right for the place the entry says to paste it.

**Evidence:** `docs/working/questions.md:83-91`; `/tmp/claude-1000/-workspace/b1fde0b4-befb-4424-9add-ef12273f2f26/scratchpad/final-fc-2/logs/q162-main.log`, `…/logs/q162-landed.log`, `…/logs/q162-replace.log`, `…/logs/runs.log`

---

## Claim 13: "`fix/q110-not-run-undercount` (f5b7e49d): the runner unsets `RUN_TESTS_NOT_RUN_FILE` after writing it."

**Location:** `docs/working/questions.md:96`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the write and the unset, and their order before bats runs the suites. It does not establish the regression test failing on the old runner, or the 300/300 figure.
**Legibility-target:** for-orchestrator-synthesis

```
# scripts/run-tests.sh:360-369 (at f5b7e49d)
if [[ -n "${RUN_TESTS_NOT_RUN_FILE:-}" ]]; then
  echo "${#not_run[@]}" > "$RUN_TESTS_NOT_RUN_FILE"
fi
# The file is this run's answer to its caller, so bats and the suites must not
# inherit the path: …
unset RUN_TESTS_NOT_RUN_FILE
```

(excerpt ends :369; the script continues with the NOT RUN print at :371 and the `--failed` logic — read through :380.)

**Evidence:** `scripts/run-tests.sh:19,321,360-369` at f5b7e49d

---

## Claim 14: Unit sizes: "6 files, +26/−10" (doc drift), "43 code lines" (Q-160), "399 lines" (Q-096), "131 code lines" (rebuild hint), "260 code lines" (one-workspace), "26 code lines outside `docs/`, 409 lines outside `docs/reviews/`" (U5), "562 changed lines" (Q-168), "561 code lines" (Q-106), "Sizes 413 + 451 lines" (Q-092)

**Location:** `docs/working/questions.md:97-101`, `:139`, `:303`, `:352`, `:423`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each figure with pr-prep step 1a's command (`git diff --numstat BASE...X -- ':(top)' ':(top,exclude)docs/'`) against each unit's own base. It does not establish that each entry names its base; stacked units are measured against the branch below them.
**Legibility-target:** for-orchestrator-synthesis

The output, in the order the claims are listed:
- doc drift: `fix/doc-drift-cycle1 … 6 files changed, 26 insertions(+), 10 deletions(-)` (outside `docs/reviews/`)
- `fix/q160-iteration-cap vs main: 43`
- `fix/q096-exit-scan-insteadof-target vs main: 399`
- `fix/rebuild-hint-recreate vs 00a27a2f: 131`, the ready commit it is built on
- `fix/cc-isolated-one-workspace vs fix/rebuild-hint-recreate: 260`
- `feat/build-loop-u5 vs main: 26` and `u5 outside docs/reviews: 409`
- `fix/q096b-exit-scan-remote-names vs fix/q096-exit-scan-insteadof-target: 562`
- `feat/q106-host-settings-merge vs 184396ea: 561`
- `fix/q092a-drop-deny-option vs 00a27a2f: 413` and `fix/q092-drop-hook-deny-reader vs fix/q092a-drop-deny-option: 451`

Q-092a measured against main gives 925, because it is built on the ready commit 00a27a2f. The entry does not say that, but 413 is the unit's own size.

**Evidence:** `docs/working/questions.md:97-101,139,303,352,423`; `/tmp/claude-1000/-workspace/b1fde0b4-befb-4424-9add-ef12273f2f26/scratchpad/final-fc-2/logs/refs-sizes-mergetree.log` (section "sizes")

---

## Claim 15: Q-163 and Q-164 pastes: replace-ref guard; pick `merge/u5-and-q145` (a04d9776) when the other unit is already on main; abort on a conflict

**Location:** `docs/working/questions.md:116-119`, `:147-150`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the guard, the hash selection and the abort path, executed. It covers Q-163's clean merge on today's main. It does not establish that either paste can merge after this branch lands (Claim 16).
**Legibility-target:** for-orchestrator-synthesis

```
# docs/working/questions.md:118 (Q-163)
if git merge-base --is-ancestor 7c91b97455db9fba1b155a2bb866abf6b86f1904 HEAD; then B=a04d97762518389f053c3c609a3dfcc4531d553b; else B=c035f2e77f8c083156b397fb32e164dd17cc6b44; fi && \
```

a04d9776 is `Merge branch 'fix/q145-ancestor-vanish' into merge/u5-and-q145` with parents 0f94bb77 and c035f2e7, so it contains both 7c91b974 and c035f2e7. Q-164's selector mirrors Q-163's (`:149`). The runs in `$S/clone`, under `timeout 60 bash`:
- Q-163 on main at 20:02:29Z exited 0 with `Merge made by the 'ort' strategy.` (37 files, including `scripts/lib/dev-cycle-read.sh` and `scripts/run-tests.sh`). That confirms "Merging this therefore also brings Q-110" (`:111`).
- Q-164 on main exited 0 and printed `conflict: merge aborted; the loop rebuilds this entry's branch against main`, with HEAD unchanged and the tree clean.
- Both stop at `replace refs present: stop` (exit 1) with a replace ref present.

Q-163's and Q-164's abort branches have no trailing `false`, so a conflict exits 0. Nothing follows in either block, so this has no effect.

**Evidence:** `docs/working/questions.md:111-119,144-150`; `/tmp/claude-1000/-workspace/b1fde0b4-befb-4424-9add-ef12273f2f26/scratchpad/final-fc-2/logs/q163-main.log`, `…/q164-main.log`, `…/q163-replace.log`, `…/q164-replace.log`, `…/runs.log`

---

## Claim 16: Q-163 "[1] merge | The paste above" and Q-164 "[1] merge … One paste, then the release" as live options

**Location:** `docs/working/questions.md:124`, `:155`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers whether option [1]'s paste merges on today's main and after this branch lands. It does not establish what the loop's rebuilt branches will do.
**Legibility-target:** for-author

The pastes fail safe (Claim 15), but option [1] cannot do what it says in two cases:
- Q-164's paste already conflicts on today's main, in roadmap, idea-log, questions-archive and questions (`$S/logs/q164-main.log`).
- After this branch lands, Q-163 also conflicts, in `docs/reviews/override-log.md` (`q163-landed.log`, `q163-seq.log`). Q-164 then conflicts in override-log, roadmap, questions-archive and questions (`q164-landed.log`, `q164-seq.log`).

Q-162 says so in general, "Their pastes abort on a conflict, and once main moves, the loop rebuilds their merge branches" (`:83`). Q-162 carries its own "Not runnable yet" note (`:85`), but Q-163 and Q-164 carry none, and their tables present [1] as one paste. Precise version: each entry gets a note like Q-162's, saying the pinned hash is rebuilt before [1] can run.

**Evidence:** `docs/working/questions.md:83,85,113,124,144,155`; `/tmp/claude-1000/-workspace/b1fde0b4-befb-4424-9add-ef12273f2f26/scratchpad/final-fc-2/logs/q163-landed.log`, `…/q164-main.log`, `…/q164-landed.log`, `…/q163-seq.log`, `…/q164-seq.log`

---

## Claim 17: "`merge/build-loop-u5-resolved` at 0f94bb77 (this cycle's chore branch, Q-110 and U5, …; U5's reviewed tip is unchanged inside it)" · "The tip adds two commits on top: FP-174 renumbered (db325bcb) and Q-110 merged in (c035f2e7)"

**Location:** `docs/working/questions.md:144`, `:111`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the commit graph of 0f94bb77, a04d9776 and c035f2e7. It does not establish the "health check passed at 2aba4bf0" claim.
**Legibility-target:** for-orchestrator-synthesis

`git log --first-parent 0f94bb77` gives `0f94bb77 e088c7e3 f5b7e49d Merge branch 'fix/q110-not-run-undercount' …`, `e088c7e3 46942678 7c91b974 Merge branch 'feat/build-loop-u5' …`, and `46942678 … docs(cycle): merge entries Q-163 (Q-145) and Q-164 (U5)` on top of `63af3551 … dev cycle 2026-10-14`. 46942678 is an ancestor of HEAD, so it is this chore branch. U5's tip 7c91b974 is merged as a parent, unchanged. `c035f2e7 db325bcb f5b7e49d Merge branch 'fix/q110-not-run-undercount' into fix/q145-ancestor-vanish` sits on `db325bcb … renumber Q-145's entry FP-174` on `2aba4bf0`. 3718bcd0 (Q-164's "last fix") is an ancestor of 7c91b974.

**Evidence:** `docs/working/questions.md:111,136,144`; graph read with `git log --first-parent -6` on a04d9776, 0f94bb77 and c035f2e7

---

## Claim 18: "`docs/working/research-branch-verify-without-install.md` and `docs/working/dd-branch-verify-without-install.md` on `docs/branch-verify-without-install` (22a4bb1f; the branch tip, d25254da, adds the spike doc and its review commits)"

**Location:** `docs/working/questions.md:169`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that both files exist at 22a4bb1f and that d25254da adds `spike-cc-verify-q117.md`. It does not establish the five bullet findings beneath.
**Legibility-target:** for-orchestrator-synthesis

Paraphrased (no quote available because the claim is about tree contents). `git ls-tree 22a4bb1f docs/working/` lists the dd and research files. `git ls-tree d25254da docs/working/` lists those two plus `spike-cc-verify-q117.md`. The branch ref is d25254da.

**Evidence:** `docs/working/questions.md:169`; trees 22a4bb1f and d25254da

---

## Claim 19: "For Q-125 that difference is real: a staged run never executes its `install.sh` `PAYLOAD` or `cc-isolated.sh` `enforcement_files()` changes (Q-117 changes only `init-firewall.sh`)"

**Location:** `docs/working/questions.md:196`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what Q-125's (`feat/q125-cc-isolated-sandbox`) and Q-117's (`fix/egress-dnsmasq-ipset`) diffs change. It does not establish the staged-run mechanics of the not-yet-built `cc-verify`.
**Legibility-target:** for-orchestrator-synthesis

`git diff --name-only main...fix/egress-dnsmasq-ipset` lists, under `devcontainer-config/`, only `devcontainer-config/init-firewall.sh`. The others are docs and `test/init-firewall-rules.bats`. Q-125's diff changes `PAYLOAD`:

```
+PAYLOAD=(devcontainer.json Dockerfile seccomp-cc-sandbox.json managed-settings.json cc-sandbox-settings.sh init-firewall.sh …)
```

and adds `+  echo "seccomp-cc-sandbox.json"` to `cc-isolated.sh`'s enforcement list.

**Evidence:** `docs/working/questions.md:196`; `git diff main...feat/q125-cc-isolated-sandbox -- devcontainer-config/install.sh devcontainer-config/cc-isolated.sh`

---

## Claim 20: Q-167(a): the bless shows "`Verified live:  NO — a bless is a review, not a test.` followed by `Next: cc-isolated --probe-only <repo>` alone on its line, and `cc-isolated --list` should show `Blessed config <hash> — verified live: NO (run: cc-isolated --probe-only <repo>)`"

**Location:** `docs/working/questions.md:208`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the strings in `cc-isolated.sh` on the ready branch (a760a5e5), which install.sh's bless calls (`install.sh:607` `CLAUDE_DEVC_CONFIG_DIR="$DEST" "$DEST/cc-isolated.sh" --bless`). It does not establish the host run itself.
**Legibility-target:** for-orchestrator-synthesis

```
# devcontainer-config/cc-isolated.sh:325-331 (a760a5e5), inside bless_manifest() :294-332
  if is_verified_live; then
    echo "Verified live:  yes (this exact config has passed a live self-probe before)"
  else
    echo "Verified live:  NO — a bless is a review, not a test. Nothing has run this config."
    echo "  Next: cc-isolated --probe-only <repo>"
    echo "        (recreates the container from it and probes as node)"
# devcontainer-config/cc-isolated.sh:501 (list_projects)
      echo "Blessed config $b — verified live: NO (run: cc-isolated --probe-only <repo>)"
```

The entry quotes a prefix of the first line. The `Next:` line has lost the `   # rebuilds from it …` note that main has (`main:devcontainer-config/cc-isolated.sh:316`), so "alone on its line" holds. The entry correctly attributes the bless lines to install and the `Blessed config` line to `--list`, which is the earlier F4 correction.

**Evidence:** `devcontainer-config/cc-isolated.sh:294-332,495-505` at a760a5e5; `devcontainer-config/install.sh:607` at a760a5e5

---

## Claim 21: Q-167(b): "Paste these lines as written in default zsh; each of the first three must print an ERROR and `exit=2` with nothing done"

**Location:** `docs/working/questions.md:216-225`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers lines 1–3 under an interactive zsh (`zsh -f -i`, so `interactive_comments` is off) running a760a5e5's `cc-isolated.sh` in a fake HOME, and line 4's argument parse. It does not establish line 4's probe passing, which needs docker on a host.
**Legibility-target:** for-orchestrator-synthesis

The three lines were fed on stdin to `HOME=$S/fakehome PATH=$S/bin:… timeout 30 zsh -f -i`, at 2026-10-15T20:03:31Z, cwd `$S/fakehome`, where `$S/bin/cc-isolated` links to the a760a5e5 copy. Output:
```
ERROR: two workspaces given: …/code/a and …/code/b. cc-isolated takes one.
exit=2
ERROR: \# is not a workspace; it looks like a pasted comment.
exit=2
ERROR: \# is not an egress profile; it looks like a pasted comment.
exit=2
```
In line 2, interactive zsh passes `#`, `registered` and `projects` as words and still splits on `;`, so `echo "exit=$?"` runs. The parse is `cc-isolated.sh:806` `\#*) pasted_note_error "$1" "a workspace" ;;` and `:796` for `--profile`.

Running the same line through `zsh -c` instead treats `#` as a comment and runs `--list`. Only a real interactive shell reproduces the case. Line 4 (`--probe-only -- ~/code/ANY-REPO`) gets past the parser, which takes one word after `--` at `:815-818`, and stops at `ERROR: devcontainer CLI not found`.

**Evidence:** `devcontainer-config/cc-isolated.sh:758-819` at a760a5e5; `/tmp/claude-1000/-workspace/b1fde0b4-befb-4424-9add-ef12273f2f26/scratchpad/final-fc-2/logs/q167b.log`

---

## Claim 22: Q-167(c): "a planted pre-receive hook in a repository that a remote is rewritten to must be caught … (expect 3, naming hook …/mirror-repo/hooks/pre-receive)"

**Location:** `docs/working/questions.md:226-240`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the exit scan on a760a5e5: the paste's repo setup verbatim, `git_exec_snapshot` before, step 2's plant, then `git_exit_scan` and the launcher's 1→3 mapping. It does not establish the container session in between, or the host's own global git config.
**Legibility-target:** for-orchestrator-synthesis

`$S/q167c-emu.sh` ran the paste's setup line verbatim, minus the launch, under `HOME=$S/fakehome GIT_CONFIG_NOSYSTEM=1`. It sourced `cc-exit-scan.sh`, took the before snapshot, ran step 2's `printf … > mirror-repo/hooks/pre-receive && chmod +x`, then called `git_exit_scan`. That was `timeout 60 bash`, cwd `$S`, at 2026-10-15T20:03:54Z, exit 0. Output: `+ hook …/proj/mirror-repo/hooks/pre-receive  file 755 a8d45a183e948465`, then `launcher exit=3`. The mapping it emulates:

```
# devcontainer-config/cc-isolated.sh:1001-1006 (a760a5e5)
  git_exit_scan "$ws" "$git_before" "$lws" || scan=$?
  …
    1) exit 3 ;;   # the session planted something: never a clean exit
```

Confidence is Medium because the real launcher's snapshot runs around a container session this sandbox cannot start.

**Evidence:** `devcontainer-config/cc-isolated.sh:909-927,994-1007`, `devcontainer-config/cc-exit-scan.sh:1105-1171` at a760a5e5; `/tmp/claude-1000/-workspace/b1fde0b4-befb-4424-9add-ef12273f2f26/scratchpad/final-fc-2/logs/q167c.log`, `/tmp/claude-1000/-workspace/b1fde0b4-befb-4424-9add-ef12273f2f26/scratchpad/final-fc-2/q167c-emu.sh`

---

## Claim 23: "Finish `fix/q096b-exit-scan-remote-names` (3c8fbf4a, unreviewed, stacked on 013f1b3d): rebase it onto Q-096's tip" · "Built 2026-10-15: 75d08a94"

**Location:** `docs/working/questions.md:245-247`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the commit graph. It does not establish the review outcomes summarized in Q-171.
**Legibility-target:** for-orchestrator-synthesis

3c8fbf4a exists (`fix(cc-exit-scan): seed: a remote with no url is pushed to by its name (split from Q-096, unreviewed)`) and descends from 013f1b3d (`refactor(cc-exit-scan): Q-096 early split …`). The branch now points at 75d08a94, which contains Q-096's tip 8717fd72 and does not contain 3c8fbf4a, as a rebase would leave it.

**Evidence:** `docs/working/questions.md:245-247`; `git merge-base --is-ancestor` checks on 013f1b3d, 8717fd72 and 3c8fbf4a

---

## Claim 24: Q-169: the extraction yields "the single ```bash block … (498 lines with its fences)", "The hash must be `032cc9a81e4e1c9266ec3ad3b5fe7053d9876eb21f5ffa7f0a35f2ccfed4afb7`", "Its first output line must be `script sha256 a65f4c30ba1b8907`"

**Location:** `docs/working/questions.md:256-262`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the extraction command run verbatim (`~` = a fake HOME whose `claude-workflows` links to the clone), the file's hash and length, and the inner script's self-hash and its position as the first stdout line of a normal (non-`--clean`) run. It does not establish the spike's own behavior (an hour-long docker run).
**Legibility-target:** for-orchestrator-synthesis

The command:

```
cd ~/claude-workflows && mkdir -p ~/cc-verify && git -c core.useReplaceRefs=false show a760a5e5057ef3f0abd13145e7d945ef500b8abd:docs/working/spike-cc-verify-q117.md | awk '/^```bash$/{f=1;next} f&&/^```$/{exit} f' > ~/cc-verify/q117-spike.txt && sha256sum ~/cc-verify/q117-spike.txt
```

It ran with `HOME=$S/fakehome169 timeout 60 bash -c`, cwd `$S/fakehome169`, at 2026-10-15T20:04:08Z, exit 0, and printed `032cc9a81e4e1c9266ec3ad3b5fe7053d9876eb21f5ffa7f0a35f2ccfed4afb7`. The file has 496 lines, 498 with the fences. The doc at a760a5e5 has exactly one `^```bash$` fence (`:49`) and is identical to d25254da's.

The inner heredoc body, which is what `bash -c` receives after `$(cat <<'CCVERIFY' …)` strips the trailing newline, hashes with `printf '%s' … | sha256sum | cut -c1-16` to `a65f4c30ba1b8907`. The self-hash line is `[ -n "${BASH_EXECUTION_STRING:-}" ] && echo "   script sha256 $(…)"`, file line 296. Every top-level statement before it is an assignment or a definition, and the only earlier prints sit in the `--clean` branch (`:268-290`), so it is the first output line on a normal run. The extraction disables replace refs and pins the full hash. The script's `EXPECT_BR=b26d4b8b23aa…` equals `fix/egress-dnsmasq-ipset`'s tip.

**Evidence:** `docs/working/questions.md:256-262`; `docs/working/spike-cc-verify-q117.md:49-546` at a760a5e5; `/tmp/claude-1000/-workspace/b1fde0b4-befb-4424-9add-ef12273f2f26/scratchpad/final-fc-2/logs/q169.log`

---

## Claim 25: "since 2026-09-09 87 of 116 `devcontainer-config/` commits carry `Live-verified: no`"

**Location:** `docs/working/questions.md:276`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the count at the DD's commit f050b487, with `git log --no-merges --since=2026-09-09 -- devcontainer-config/` and a body line starting `Live-verified: no`. It does not establish the DD's other figures (6 fixes, 4 of 6 unverified, 18 candidates).
**Legibility-target:** for-author

The total is 116, which matches. The command counts 88 commits whose body has a line starting `Live-verified: no`, one more than stated. One of them is spelled `Live-verified: no. Authored in a sandbox with no egress; run one` (a period, not a dash), which the DD may have left out. The DD's own sentence, "**87 carry `Live-verified: no` and 1 carries a hash**" (`docs/working/dd-015-step4-isolation-mechanism.md:34` at f050b487), names no exact command. Precise version: 88 by a plain line match, or the DD's exact filter, stated.

**Evidence:** `docs/working/questions.md:276`; `/tmp/claude-1000/-workspace/b1fde0b4-befb-4424-9add-ef12273f2f26/scratchpad/final-fc-2/logs/merge-and-counts.log` (section "Q-170 count")

---

## Claim 26: "Q-106 [2] is built (`feat/q106-host-settings-merge`, c6d7544f, built on an earlier `merge/ready-2026-10-15` commit, 184396ea; it is not in the ready branch Q-162 merges)"

**Location:** `docs/working/questions.md:343`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the ancestry. It does not establish the bullets on test counts and the S3-F1 finding.
**Legibility-target:** for-orchestrator-synthesis

184396ea is an ancestor of c6d7544f, and it is on a760a5e5's first-parent chain (`184396ea 11184f2b 5f0f00d9 Merge branch 'chore/dev-cycle-2026-10-15-0357' into merge/ready-2026-10-15`). c6d7544f is not an ancestor of a760a5e5.

**Evidence:** `docs/working/questions.md:343`; `/tmp/claude-1000/-workspace/b1fde0b4-befb-4424-9add-ef12273f2f26/scratchpad/final-fc-2/logs/refs-sizes-mergetree.log`

---

## Claim 27: "`hooks/lib/wiring-merge.jq`, which is outside `live-verify-gate.sh`'s `enforcement` regex. On main that jq is inline in `link-claude-home.sh`, which the regex covers (`hooks/live-verify-gate.sh:83`)"

**Location:** `docs/working/questions.md:369`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the regex at :83 (identical on main and on c6d7544f) matched against both paths, and the inline jq on main. It does not establish "the trust manifest still hashes it" beyond `enforcement_files()` listing `claude-home` files.
**Legibility-target:** for-orchestrator-synthesis

```
# hooks/live-verify-gate.sh:83 (main and c6d7544f)
enforcement='^devcontainer-config/(Dockerfile|devcontainer\.json|init-firewall\.sh|cc-sni-proxy\.py|link-claude-home\.sh|cc-isolated\.sh|install\.sh$|egress/)'
```

`grep -cE "$re"` prints `devcontainer-config/link-claude-home.sh 1` and `hooks/lib/wiring-merge.jq 0`. On main the merge program is inline: `devcontainer-config/link-claude-home.sh:133: if jq --arg dir "$DEST" --slurpfile w "$WIRING" '`. On c6d7544f it reads `MERGE="$SRC/hooks/lib/wiring-merge.jq"` (`:92`). The `host_tools` regex (`:91`) does not cover `hooks/` either.

**Evidence:** `hooks/live-verify-gate.sh:80-93`, `devcontainer-config/link-claude-home.sh:133` (main), `:92` (c6d7544f)

---

## Claim 28: Q-176: "a throwaway hook that approves only the nine test commands below and stays silent on anything else"; "the paste stops at `jq --version` without it"; each command's control role

**Location:** `docs/working/questions.md:385-414`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the paste building `~/q092` with the two files and the `&&` chain. It covers the hook's decision for the nine listed strings and six near-misses, each command mapping to the deny rule its control label names, and `seen.log` recording every input. It does not establish Claude Code's deny matcher behavior, which is the check's purpose and needs a host session, nor whether `Bash(git push:*)` matches a bare `git push` (control 8). The entry voids the run if a control is not denied.
**Legibility-target:** for-orchestrator-synthesis

The paste ran with `claude` stubbed and with `.claude` renamed to `dotcl` in a copy, because this session's own guard refuses Bash writes to `.claude` paths. That was `HOME=$S/fakehome176 timeout 30 bash $S/q176.test`, at 2026-10-15T20:04:49Z, exit 0. It printed `jq-1.6`, then `STUB claude --version`, then `STUB claude`, and created `x.q092-canary`, `secret` and both files.

Feeding `{"tool_input":{"command":…}}` to the hook (20:04:56Z) gave `permissionDecision":"allow"` for exactly the nine strings, including `cat x.q092-ca""nary`, `cat x.q092-c\anary` and `git "push"`. It gave `(silent)` for `cat x.q092-canary ` (a trailing space), `cat x.q092-canary; rm -rf /`, `git push origin`, `cat secret*`, `ls` and `cat x.q092-c*nary`. `seen.log` holds all 15 inputs, each followed by `---`.

The deny list `["Bash(*.q092-canary*)", "Bash(rm -rf:*)", "Bash(git push:*)", "Bash(cat secret)"]` (`:397`) pairs as labeled:
- 1–3 → the glob rule;
- 4–5 → the `rm -rf:*` prefix rule;
- 6–7 → the exact rule;
- 8–9 → the `git push:*` prefix rule.

`~/q092` is a fresh `git init` with no remote. This is a host paste, run outside any container.

**Evidence:** `docs/working/questions.md:385-416`; `/tmp/claude-1000/-workspace/b1fde0b4-befb-4424-9add-ef12273f2f26/scratchpad/final-fc-2/logs/q176-paste.log`, `…/logs/q176-hook.log`

---

## Claim 29a: "(the review's MA1 names all four …)"

**Location:** `docs/working/questions.md:383`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that MA1 of `docs/reviews/independent-review-2026-10-15-q092b.md` (on aeda94b2) names the four spellings. It does not establish the hook behavior MA1 reports (29b).
**Legibility-target:** for-orchestrator-synthesis

```
# docs/reviews/independent-review-2026-10-15-q092b.md:22,31 (aeda94b2)
### MA1. The F3/F4 host check, and the A1 question, have no route in the repo
  - `cat ~/.claude/.cred""entials.json`, `.c\redentials.json`, `git "push"` and `cat "secret"` go from no output on main to `allow` at HEAD.
```

**Evidence:** `docs/reviews/independent-review-2026-10-15-q092b.md:22-36` at aeda94b2

---

## Claim 29b: "Main's hook stays silent on `.cred""entials.json`, `.c\redentials.json`, `git "push"` and `cat "secret"`; the branch's hook approves them"

**Location:** `docs/working/questions.md:383`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers nothing beyond the reviewer's recorded probe (29a). It does not establish either hook's output on these inputs.
**Legibility-target:** for-orchestrator-synthesis

Execution was required and blocked. Both hook versions were extracted to the scratchpad (`$S/aa-main.sh` and `$S/aa-branch.sh`), and `shfmt` and `jq` are present. The permission system denied the probe command, which feeds the credential-file spellings to the hooks. Static support: main's header documents a `--deny JSON` option, `#   --deny JSON             Use custom deny rules instead of reading permissions.deny` (`hooks/auto-approve-allowed-commands.sh:16-17`, main). The branch's option list stops at `--permissions` (`:14-15`, aeda94b2), which is consistent with the deny reader's removal. Resolving it needs a run of the two hooks on those four inputs with the deny rules supplied.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:1-60` (main), `:14-15` (aeda94b2)

---

## Claim 30: Cross-references: blocking Q-ids exist, and archived entries are not called open

**Location:** `docs/working/questions.md:80-450` (Q-160..Q-177), `docs/roadmap.md:14-56`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every `Q-NNN` on an added line in the five touched docs files, checked against open and archive headings at HEAD and against `feat/build-loop-u5`. It does not establish the content of IDs that live only on that branch.
**Legibility-target:** for-orchestrator-synthesis

Paraphrased (no quote available because the check spans ~60 IDs across five files). Every cited ID is an open or archived heading at HEAD, except Q-149, Q-155 and Q-156, which exist only on `feat/build-loop-u5`. Each citing line says so: "Q-156, filed on `feat/build-loop-u5`; it reaches main with Q-164" (`:124`), "files Q-149..Q-156" (`:139`), and "Blocks: Q-156 (the release), Q-103, and dispatch (Q-155 …)" (`:157`). The archived IDs cited (Q-082, Q-083, Q-089, Q-094, Q-104, Q-105, Q-106, Q-107, Q-113, Q-117, Q-120, Q-121, Q-126, Q-130, Q-131, Q-133, Q-145, Q-146, Q-148, Q-178) are cited as answered, historical or "in the archive", and none is called open. The open IDs used as blockers (Q-092, Q-096, Q-103, Q-108, Q-110, Q-125, Q-179) are open. No heading appears in both the open file and the archive.

**Evidence:** `docs/working/questions.md:124,139,157`; `/tmp/claude-1000/-workspace/b1fde0b4-befb-4424-9add-ef12273f2f26/scratchpad/final-fc-2/logs/merge-and-counts.log` (dups and open∩archive empty)

---

## Claim 31: Merge 16136a60's message: "Main's open copies of Q-089 and Q-107 dropped (the branch archived them); the branch's open copies of Q-139, Q-141, Q-142, Q-146 dropped (main archived them). Q-096 and Q-103 keep the branch's newer notes. … roadmap.md: router-uptake Cycle 2 and Cycle 3 lines both kept; Next keeps the branch's 3-5 … and main's Q-146 item becomes 6. … idea-log.md: 2026-10-14 seeds and brainstorm, then 2026-10-15's."

**Location:** commit `16136a60` (message body)
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers per-entry identity of every `### Q-` section in both questions files across the two parents (92f3b080, 7f711bfe) and the merge, plus line-level diffs of the roadmap and idea-log against each parent. It does not establish the regenerated index's ordering.
**Legibility-target:** for-orchestrator-synthesis

questions.md headings:
- In the union of the parents but not in the merge: exactly `Q-089 Q-107 Q-139 Q-141 Q-142 Q-146`.
- In the merge but in neither parent: none.
- Duplicates: none.
- Section bodies: Q-096, Q-103 and Q-160..Q-177 equal the branch's, and Q-179 equals main's.

questions-archive.md: nothing dropped or added. Q-089 equals the branch's; Q-139/141/142/146/178 equal main's; Q-107 equals the branch's apart from one extra trailing blank line.

roadmap.md and idea-log.md: the merge against the branch parent has no removed lines. Against the main parent, the only removed lines are main's old Next 3 and 4 (moved to Now by the branch) and `5. **Q-146 [1]`, which reappears as `6. **Q-146 [1]`. Nothing was dropped or duplicated beyond what the message names.

**Evidence:** `git log -1 16136a60`; `/tmp/claude-1000/-workspace/b1fde0b4-befb-4424-9add-ef12273f2f26/scratchpad/final-fc-2/logs/merge-and-counts.log`

---

## Claims Requiring Attention

### Incorrect
- None.

### Stale
- None.

### Mostly Accurate
- **Claim 4** (`docs/roadmap.md:77`, `docs/working/cycles/cycle-2026-10-14.md:6,55`): 42/25/38/4 is correct only after excluding cycle 1's three landings. The record's stated window (on or after 2026-10-02) gives 45/25/40/5. Say "since cac2ba0c".
- **Claim 10** (`docs/working/questions.md:83`): "every pair of these units conflicts only in override-log". Only 3 of the 10 non-ancestral pairs conflict at all. Say "the only conflicts among these units are in override-log".
- **Claim 11** (`docs/working/questions.md:85`): the pre-landing conflict list omits `docs/working/questions-archive.md`.
- **Claim 16** (`docs/working/questions.md:124,155`): Q-164's paste already aborts on today's main, and both Q-163's and Q-164's abort once this branch lands. Neither entry has Q-162's "Not runnable yet" note.
- **Claim 25** (`docs/working/questions.md:276`): 87 of 116 counts 88 by a plain `^Live-verified: no` match (one spelled `no.`). Give the exact filter or use 88.

### Unverifiable
- **Claim 29b** (`docs/working/questions.md:383`): needs running main's and aeda94b2's `auto-approve-allowed-commands.sh` on the four quoted spellings. The permission system blocked this run.

## Goal-Alignment Note

The PR is docs only: land the 2026-10-14 cycle and the 2026-10-15 loops through pr-prep, carrying the landing review's fixes. Those fixes hold under execution:
- Q-162's paste is pinned by hash behind a working replace-ref guard and aborts cleanly with nothing deleted. Its "Not runnable yet" reason (override-log after landing) is exactly what merge-tree shows.
- Q-169's extraction reproduces the stated sha256, and the inner script's self-hash matches.
- Q-176's hook approves exactly the nine commands and logs every input.
- Q-167's expected strings match the ready branch's code, and its zsh `#` probes reproduce exit 2 in a real interactive shell.
- The 16136a60 merge drops and keeps exactly what its message names.
- The override-log rows match F2 and F3, and every hash and branch resolves, unmerged, with the stated content and sizes.

No finding is blocking. The five Mostly-accurate items are wording. The one with a practical edge is Claim 16: after this branch lands, the Q-163 and Q-164 pastes, like Q-162's, can only abort until the loop rebuilds their merge branches, and only Q-162 says so.
