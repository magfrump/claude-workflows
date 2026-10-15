Commit: 16136a60
# Code Fact-Check Report

**Repository:** claude-workflows (worktree `/workspace/.claude/wt-dev-cycle-2026-10-15-0357`, branch `chore/dev-cycle-2026-10-15-0357`)
**Scope:** `git diff main...HEAD` at HEAD 16136a60 (main 7f711bfe): docs/roadmap.md, docs/working/cycles/cycle-2026-10-14.md, docs/working/idea-log.md, docs/working/questions-archive.md, docs/working/questions.md, plus the merge commit 16136a60's message. Claims checked against the git objects and code they describe (branch tips via `git show <branch>:<path>`).
**Replication:** k=1 (loop pass, decision 031)
**Checked:** 2026-10-15
**Total claims checked:** 31
**Summary:** 21 verified, 4 mostly accurate, 2 stale, 1 incorrect, 3 unverifiable

Hallucination pattern log (`docs/reviews/hallucination-patterns.md`, 8 entries) read first; no claim below matches a logged pattern. The one Incorrect verdict (Claim 22) attributes output to the wrong subcommand. It names no fabricated symbol, so it is not a log entry, and this pass did not touch that file.

Execution logs are in the session scratchpad (outside the repo, because this pass may write only this report): `/tmp/claude-1000/-workspace/b1fde0b4-befb-4424-9add-ef12273f2f26/scratchpad/cfc0357/execlogs/`.

---

## Claim 1: "resolved by keeping both sides … Main's open copies of Q-089 and Q-107 dropped … the branch's open copies of Q-139, Q-141, Q-142, Q-146 dropped … Q-096 and Q-103 keep the branch's newer notes … Next keeps the branch's 3-5 … and main's Q-146 item becomes 6. Ideas from both sides kept"

**Location:** commit message of 16136a60 (`git show -s 16136a60`); applies to `docs/working/questions.md`, `docs/working/questions-archive.md`, `docs/roadmap.md:87-99`, `docs/working/idea-log.md:20-46`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers entry-level presence, absence and byte equality of every `### Q-NNN` entry across `16136a60^1`, `16136a60^2` and HEAD in both questions files, plus line-level loss and duplication in roadmap.md and idea-log.md. It does not establish that prose inside kept entries is still current; Claims 13, 21 and 22 cover the stale content.

Entry comparison (paraphrased — no quote available because the evidence is a script's per-entry table over three file versions): every Q-160..Q-177 entry in HEAD is byte-identical to parent 1, and Q-179 is byte-identical to parent 2. Q-096 and Q-103 equal parent 1, and parent 1 differs from parent 2 only by the added lines `- **Built 2026-10-15:** \`fix/q096-exit-scan-insteadof-target\` …` (questions.md:527) and `- **Note (dev cycle 2026-10-14):** …` (questions.md:442). Nothing from main's side was lost. The only open entries missing from HEAD are Q-089 and Q-107 (archived by the branch, `questions-archive.md:2718`, `:2731`) and Q-139, Q-141, Q-142 and Q-146 (archived by main, `**Status:** ANSWERED` at `questions-archive.md:2743`, `:2768`, `:2790`, `:2813`). HEAD has no duplicate entry in either file. `scripts/questions.sh check` exits 0 and prints `✓ questions: structure valid, indexes current`.

Roadmap and idea-log (paraphrased — no quote available because the evidence is a `comm` line-set difference): no non-blank line of parent 1 is missing from HEAD in either file. From parent 2's roadmap, only main's old Next 3 and Next 4 bodies (the branch moved both to Now, `roadmap.md:21` and `:51`) and the replaced line `Nothing waiting outside a brief…` are gone. `git diff b279a2ba main -- docs/roadmap.md` shows that main never edited those bodies, so no main-side edit was lost. HEAD's only repeated non-blank line is the wrapped fragment `  Q-162's paste.` in two different Now items, not a duplicate item. No remaining entry or roadmap line calls Q-139, Q-141, Q-142 or Q-146 open. Roadmap Next 6 (`roadmap.md:99`) implements Q-146's archived answer [1].

**Evidence:** `docs/working/questions.md:442`, `docs/working/questions.md:527`, `docs/working/questions-archive.md:2718-2850`, `docs/roadmap.md:87-99`, `docs/working/idea-log.md:20-46`, `execlogs/questions-check.log` (cmd `bash scripts/questions.sh check`, cwd the worktree, exit 0, 2026-10-15T19:30:05Z)

---

## Claim 2: Roadmap Now's branch and SHA citations (U5 `feat/build-loop-u5`, `fix/q110-not-run-undercount`, `fix/q145-ancestor-vanish`, `fix/t69-stage-race` 4ee81106, `fix/doc-drift-cycle1` c8e87a69, `fix/q160-iteration-cap` 4a44d2f3, `fix/q096-exit-scan-insteadof-target` 8717fd72, Q-168 "Built (75d08a94)", `fix/q092a-drop-deny-option` d27a3891 "then" `fix/q092-drop-hook-deny-reader` aeda94b2)

**Location:** `docs/roadmap.md:13-50`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each branch's existence, the cited SHA being its tip, and its unmerged state against main 7f711bfe. It does not establish review quality or test results claimed in the same items.

Paraphrased — no quote available because the evidence is `git rev-parse`/`merge-base --is-ancestor` output for 11 refs: every cited branch exists, its tip equals the cited SHA (feat/build-loop-u5 7c91b974, fix/q110 f5b7e49d, fix/q145 c035f2e7, t69 4ee81106, doc-drift c8e87a69, q160 4a44d2f3, q096 8717fd72, q096b 75d08a94, q092a d27a3891, q092 aeda94b2), and none is an ancestor of main, so no Now item is already landed. `git merge-base fix/q092-drop-hook-deny-reader fix/q092a-drop-deny-option` is d27a3891, which confirms the "then" stacking.

**Evidence:** `docs/roadmap.md:13-50`; refs `refs/heads/*` listed above

---

## Claim 3: "The launcher's rebuild hint (`fix/rebuild-hint-recreate`, 47da5a4b; was Next 3) … in `merge/ready-2026-10-15`" and "One workspace per `cc-isolated` call (`fix/cc-isolated-one-workspace`, f6f37fad; was Next 3) … In `merge/ready-2026-10-15`"

**Location:** `docs/roadmap.md:41-46`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the tips, their containment in merge/ready-2026-10-15 (a760a5e5), and each item having once been Next 3 in this branch's history. It does not establish the items' live-verify status.

Paraphrased — no quote available because the evidence is ancestry checks and `git show <commit>:docs/roadmap.md` across 11 commits: both tips are ancestors of merge/ready-2026-10-15 (first-parent merges c29d1acf and fc4c6840). Next 3 was the rebuild hint at de9590ad..7550465b, "Reject a second workspace argument" at d4445c9a..3356974b, and the branch-verify item at 63af3551. So all three "was Next 3" labels are true at different times. Feat/q106, q096b, q145, U5 and q092a are not in the ready branch, which matches Q-162's list.

**Evidence:** `docs/roadmap.md:41-52`; `git log --first-parent main..merge/ready-2026-10-15`

---

## Claim 4: "Verify a branch without installing it (was Next 3; `docs/branch-verify-without-install`, 22a4bb1f)"

**Location:** `docs/roadmap.md:51-52`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the branch and SHA citation. It does not establish the content of the spike doc beyond its presence on the branch.

The branch's tip is d25254da ("docs: record the A16 check's residuals; stop the review as instructed"), not 22a4bb1f. 22a4bb1f is the first of nine commits (`22a4bb1f docs: research and DD for verifying a branch without installing it on the host`), and the other eight build and review the Q-117 spike doc `docs/working/spike-cc-verify-q117.md` that the same item cites (Q-169). Q-165 (questions.md:164) cites 22a4bb1f for the research and DD docs, which is precise. The roadmap item covers the spike too, so the tip is the accurate citation. The full tip is in merge/ready-2026-10-15.

**Evidence:** `docs/roadmap.md:51-55`; `git log --oneline main..docs/branch-verify-without-install`

---

## Claim 5: "Cycle 2 (2026-10-14): 42 multi-file landings; 25/42 carry the line, 38/42 committed a rubric, 4/42 have neither (df18413a, 0fbf9742, b8807e76, 52053432)"

**Location:** `docs/roadmap.md:77-79` (also `docs/working/cycles/cycle-2026-10-14.md:55`)
**Type:** Configuration
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers a reproduction of the tally under the cycle record's stated window. It does not establish which counting rule cycle 2 actually used, and that rule decides the verdict.

The record states its window as merges on main at b279a2ba "whose committer date … is on or after 2026-10-02" (cycle-2026-10-14.md:6). Counting first-parent merges with more than one changed file in that window, "line" as `carried from RPI` in any commit of the merge range, and "rubric" as a `code-review-rubric` file, gives 45 merges, 29 with the line, 40 with a rubric and 5 with neither: the four cited plus 188e0a7d (`2026-10-02 16:51:30 -0700`, 2 files, neither). That result is paraphrased — no quote available because it is the output of an ad-hoc counting loop. The figures differ from the claim, but the claim does not state its counting rule, so the mismatch cannot be called an error. The adjacent cycle-3 line from main (`roadmap.md:80-82`) counts by different criteria (any docs/reviews/ file) and lists a different set of four, including 188e0a7d and excluding df18413a. Read together, the two lines look contradictory. Verifying this needs the rule cycle 2 used.

**Evidence:** `docs/roadmap.md:77-82`, `docs/working/cycles/cycle-2026-10-14.md:6`; command `git log --first-parent --merges b279a2ba --since='2026-10-02 00:00 -0700'` with per-merge `git diff --name-only <m>^1 <m>` (cwd the worktree, 2026-10-15, exit 0)

---

## Claim 6: Next renumbering after the merge — "3. `cc-isolated --profile` …", "4. Automate the host settings.json merge (Q-106 [2]). Built (`feat/q106-host-settings-merge`, c6d7544f; it also closes Q-108). Paused at the iteration-4 gate …", "5. Decision 015's re-run … (`docs/dd-015-step4`, f050b487, lands with Q-162)", "6. Q-146 [1] …"

**Location:** `docs/roadmap.md:87-99`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the cited SHAs, the containment of dd-015 in the ready branch, and the Q-106 tip's state. It does not establish the 015 DD's conclusions.

The c6d7544f tip's subject is `docs(reviews): Q-106 pass-3 security review; loop paused at the iteration-4 gate (escalate)`. The branch edits `docs/decisions/037-bare-host-copy-install.md` (+16/−2), which matches "closes Q-108". docs/dd-015-step4's tip is f050b487, an ancestor of merge/ready-2026-10-15 (merge 11184f2b). The numbering 1–6 matches the merge message.

**Evidence:** `docs/roadmap.md:87-99`; `git log -1 c6d7544f`; `git diff --numstat 184396ea feat/q106-host-settings-merge`

---

## Claim 7: "The seven source paths are in `install.sh:135`, and a second, untested copy of the names is in `link-claude-home.sh:50`"

**Location:** `docs/roadmap.md:116-119` (same wording in `docs/working/questions-archive.md:2738`: "`link-claude-home.sh:50` keeps an untested second copy of the names")
**Type:** Reference / Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the two line citations and whether any test reads ENTRIES. It does not establish whether a parity test is the right first step.

Both lines are where the claim says, on main:

```bash
# devcontainer-config/install.sh:135
CLAUDE_HOME_SRC=(global-instructions/CLAUDE.md skills workflows guides patterns hooks scripts)
# devcontainer-config/link-claude-home.sh:50
ENTRIES=(skills workflows guides patterns hooks scripts CLAUDE.md)
```

"Untested" is too strong. One test pins one name in ENTRIES:

```bash
# test/link-claude-home-wiring.bats:298-299
# `scripts` from ENTRIES or from CLAUDE_HOME_SRC, or the README no longer
# pointing bare-host users at install.sh, fails this test.
```

No test checks that ENTRIES equals CLAUDE_HOME_SRC's basenames (paraphrased — no quote available because this is an absence: `git grep ENTRIES main -- test/` has that one hit only). The precise wording is "a second copy with no parity test (only `scripts` is pinned)".

**Evidence:** `devcontainer-config/install.sh:135`, `devcontainer-config/link-claude-home.sh:50`, `test/link-claude-home-wiring.bats:293-309`

---

## Claim 8: "Health check failed at b279a2ba with 1 red: `test/install-host.bats` T69 … It fails 3/3 alone" (also Q-162: "T69 … failed 3 out of 3 runs alone on main b279a2ba" and Interim "main's health check stays red on T69 until the merge")

**Location:** `docs/working/cycles/cycle-2026-10-14.md:13`, `docs/working/questions.md:92`, `docs/working/questions.md:100`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers running T69 alone twice on main's tree and twice on the fix branch's tree in this sandbox. It does not establish the outcome under the load of a full health-check run or on the machine that recorded 3/3.

T69 passed 2/2 on main's tree, which is unchanged in `test/install-host.bats` and `devcontainer-config/` since b279a2ba, and 2/2 on the fix. Output: `ok 1 T69 a devcontainer stage edited while its prompt waits is neither installed nor blessed (review A1, P3)`. The race mechanism is real in the code:

```bash
# test/install-host.bats:1163-1164 on main (excerpt ends :1164; enclosing @test continues to ~:1175 — read)
  feed="for _i in \$(seq 200); do [ -e '$ROOT/devcontainer-config/claude-home/.manifest' ] && break; sleep 0.1; done
    sleep 1; for f in \"\$TMPDIR\"/cw-devc-stage.*/config/devcontainer.json; do printf 'TAMPERED\n' > \"\$f\"; done; printf 'y\nn\n'"
```

The wait matches a file the earlier `--yes` run left behind, so the tamper lands only if staging finishes within about 1 s. Whether it fails 3/3 depends on timing, and this sandbox did not reproduce the failure. The fix touches only that test (`test/install-host.bats | 10 ++++++++--`, 1 file), which confirms the "test file is the only change" part.

**Evidence:** `test/install-host.bats:1158-1175` (main), `execlogs/t69main-run1.log`, `execlogs/t69main-run2.log`, `execlogs/t69fix-run1.log`, `execlogs/t69fix-run2.log` (cmd `timeout 240 bats -f T69 test/install-host.bats`, cwd `…/cfc0357/t69main` and `…/t69fix` (git-archive extracts of main and fix/t69-stage-race), exit 0 ×4, 2026-10-15T19:26:30Z–19:26:42Z)

---

## Claim 9: "12 merged branches (feat/build-loop-u3a1…u4c) and their worktrees go in Q-162's paste"

**Location:** `docs/working/cycles/cycle-2026-10-14.md:13`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the existence of the 12 branches and their worktrees, their merge state, and whether the worktrees are clean. It does not establish that no other session holds a worktree open when the paste runs.

Paraphrased — no quote available because the evidence is per-branch `merge-base --is-ancestor` and `git worktree list --porcelain` output: all 12 branches feat/build-loop-{u3a1,u3a2,u3a3,u3b1,u3b2,u3b3,u3c,u3d,u4a,u4b1,u4b2,u4c} exist and are ancestors of main. Each is checked out in a registered, unlocked worktree `/workspace/.claude/wt-build-loop-<u>` with 0 lines of `git status --porcelain`. So `git worktree remove` and `git branch -d` would both succeed today.

**Evidence:** `docs/working/cycles/cycle-2026-10-14.md:13`, `docs/working/questions.md:88`

---

## Claim 10: "Q-089 closed (merged 626dc300, df18413a)" and log row 62's "units grew from 102 to 842, 157 to 603, 217 to 538 and 392 to 570" (with Q-160's SHAs 581d41d8, 73589cd7, dfa75374, 626dc300)

**Location:** `docs/working/cycles/cycle-2026-10-14.md:15`, `docs/working/cycles/cycle-2026-10-14.md:52`, `docs/working/questions.md:403`
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the merges being on main and the final sizes, measured as code lines outside docs/ against each merge's first parent. It does not establish the starting sizes (102, 157, 217, 392).

Both 626dc300 (`Merge branch 'feat/q089a2b-cc-push-self-check' …`) and df18413a (`Merge branch 'feat/q089b4-host-tool-gate' …`) are on main. Measured outside docs/: 581d41d8 is 842, 73589cd7 is 603, dfa75374 is 538 and 626dc300 is 570, all exactly as claimed. The measurements are paraphrased — no quote available because they are numstat sums.

**Evidence:** `git diff --numstat <m>^1 <m>` for each merge

---

## Claim 11: Results section — "`fix/t69-stage-race` 4ee81106", "`fix/q110-not-run-undercount` f5b7e49d", "`fix/q145-ancestor-vanish` c035f2e7 … health check passed at 2aba4bf0 … renumbered FP-174 (db325bcb), and Q-110 was merged in (c035f2e7)", "`feat/build-loop-u5` 7c91b974 … last fix 3718bcd0 … via `merge/build-loop-u5-resolved`"

**Location:** `docs/working/cycles/cycle-2026-10-14.md:72-76`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the SHAs, their order, and the Q-110 merge into Q-145. It does not establish the health-check pass at 2aba4bf0.

`git log --oneline -4 fix/q145-ancestor-vanish` shows `c035f2e7 Merge branch 'fix/q110-not-run-undercount' into fix/q145-ancestor-vanish…`, `db325bcb docs(failure-patterns): renumber Q-145's entry FP-174`, `2aba4bf0 docs(reviews): Q-145 final confirming pass artifacts…`. f5b7e49d is an ancestor of c035f2e7. 3718bcd0 (`fix(questions): Q-156 refuses core.attributesFile in any repository scope…`) is the last commit before U5's tip 7c91b974.

**Evidence:** `git log main..feat/build-loop-u5`, `git log -4 fix/q145-ancestor-vanish`

---

## Claim 12: "`CLAUDE_HOME_SRC` and `assemble()` are still in `devcontainer-config/install.sh` (:135, :329-362; callers :498 and :858) … Q-106's branch does not change this"

**Location:** `docs/working/questions-archive.md:2738`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the line numbers on main 7f711bfe and the Q-106 branch's effect on the seam. It does not establish decision 036's reading of [11].

On main, `install.sh:135` is `CLAUDE_HOME_SRC=(…)`, `install.sh:329` is `assemble() {`, its closing `}` is at :362, `install.sh:498` is `  assemble "$stage/claude-home" "${dc_paths[@]}"` and `install.sh:858` is `  assemble "$stage"`. On feat/q106-host-settings-merge, `CLAUDE_HOME_SRC` (:145), `assemble()` (:339) and `ENTRIES` (link-claude-home.sh:50) remain, and no `scripts/build-payload.sh` exists. The entry's original body cites ":857" (`questions-archive.md:2734`). That line is pre-existing text, and the resolution corrects it to :858.

**Evidence:** `devcontainer-config/install.sh:135`, `:329-362`, `:498`, `:858` (main); `devcontainer-config/install.sh:145`, `:339` (feat/q106-host-settings-merge)

---

## Claim 13: "That branch is main plus five reviewed units, the branch-verify research and spike docs …, the decision-015 divergent design …, and this cycle's record, each merged with `--no-ff`: T69, Q-110, doc drift, Q-160, Q-096, the rebuild-hint fix and the one-workspace rule."

**Location:** `docs/working/questions.md:83`
**Type:** Reference
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the unit count and the branch's base. It does not establish the units' review states (Claim 15).

The same sentence lists seven units, and merge/ready-2026-10-15's first-parent history holds seven unit merges (a9056cee T69, c7a862d5 Q-110, 8134726c doc drift, 98e5c32a Q-160, 3fe6d6e3 Q-096, c29d1acf rebuild-hint, fc4c6840 one-workspace). The count was five before the rebuild-hint (d4445c9a) and one-workspace (782036de) units joined. "Main plus" is also loose. The ready branch is based on b279a2ba, and current main 7f711bfe is not in it, so it is "main as of b279a2ba plus …". The rest is paraphrased — no quote available because it is ref ancestry. Fix: "seven reviewed units".

**Evidence:** `docs/working/questions.md:83`; `git log --first-parent main..merge/ready-2026-10-15`; `git merge-base main merge/ready-2026-10-15` = b279a2ba

---

## Claim 14: Q-162's paste — "It merges `merge/ready-2026-10-15`, then deletes the twelve build-loop branches already merged into main, along with their worktrees"

**Location:** `docs/working/questions.md:85-89`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the paste run after this branch (16136a60) has landed on main, which is the order the current landing produces. It does not establish behavior if the paste runs on today's main 7f711bfe before this branch lands. In that case it conflicts and leaves main mid-merge.

```bash
# docs/working/questions.md:86-88
cd /workspace && test "$(git branch --show-current)" = main && \
git merge --no-ff merge/ready-2026-10-15 -m "…" && \
for u in u3a1 … u4c; do git worktree remove .claude/wt-build-loop-$u && git branch -d feat/build-loop-$u; done
```

On today's main, `git merge-tree --write-tree main merge/ready-2026-10-15` exits 1 with `CONFLICT (content)` in docs/roadmap.md, idea-log.md, questions-archive.md and questions.md. Unlike Q-163's and Q-164's pastes, this paste has no `|| git merge --abort`, so run before this branch lands it would leave /workspace's main in a conflicted merge, and the `&&` chain would stop before the deletions. Against HEAD 16136a60, the same `merge-tree` exits 0 (tree ee916ce1). A simulated landing in a scratch object store (merge commit of main and HEAD, then ready) also merges cleanly. Claim 9 covers the deletion loop's preconditions. Precise wording: "Paste after `chore/dev-cycle-2026-10-15-0357` has landed (Q-178)".

**Evidence:** `docs/working/questions.md:85-89`; `execlogs/merge-sim.log` (cmds `git merge-tree --write-tree --name-only main|HEAD merge/ready-2026-10-15`, cwd the worktree, exit 1 and 0, 2026-10-15)

---

## Claim 15: Q-162's per-unit descriptions — T69 "The test file is the only change"; doc drift "6 files, +26/−10" and AGENTS.md/GEMINI.md list dev-cycle; Q-160 "43 code lines" and the new log-row-62 trigger "2+ waivers past the in-loop re-check within 14 days"; Q-096 "399 lines", "Three caps fail closed: 4 KiB per URL, 100k comparisons and 2,000 targets", "Every `read` runs under `LC_ALL=C`"; rebuild hint "131 code lines", hint "`cc-isolated --probe-only WS && cc-isolated WS`"; one-workspace "260 code lines"

**Location:** `docs/working/questions.md:92-98`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers file and size counts and the quoted constants and strings on each branch tip. It does not establish the reported test pass counts or review outcomes.

Sizes (paraphrased — no quote available because they are numstat sums outside docs/reviews and docs/working, against each unit's base): T69 changes 1 file. Doc drift's six files are AGENTS.md +1, GEMINI.md +1, guides/README.md 1/1, cc-isolated-usage.md 1/1, devcontainer-setup.md 21/7 and the brief 1/1, for +26/−10. Q-160 is 43. Q-096 is 157+34+32+10+166 = 399. The rebuild hint is 131 against 9660d4f6, and one-workspace is 260 against 5e6e9266. Constants and strings:

```bash
# devcontainer-config/cc-exit-scan.sh:394-396 (8717fd72)
GIT_EXIT_SCAN_MAX_REWRITE_BYTES=4096
GIT_EXIT_SCAN_MAX_REWRITE_PAIRS=100000
GIT_EXIT_SCAN_MAX_REWRITE_TARGETS=2000
# devcontainer-config/cc-isolated.sh:569 (47da5a4b)
  echo "    cc-isolated --probe-only $(printf '%q' "$ws") && cc-isolated $(printf '%q' "$ws")" >&2
```

All 10 `read -r` loops in cc-exit-scan.sh at 8717fd72 are written `while LC_ALL=C IFS= read -r …` (`:335`, `:487`, `:611`, `:687`, `:722`, `:730`, `:744`, `:752`, `:822`, `:998`). Q-160's log row 62 reads "… past the in-loop ~800 re-check within any 14 days", which paraphrases the quoted trigger closely.

**Evidence:** `docs/working/questions.md:92-98`; `devcontainer-config/cc-exit-scan.sh:390-420` (8717fd72); `devcontainer-config/cc-isolated.sh:569` (47da5a4b); `docs/decisions/log.md` row 62 (fix/q160-iteration-cap)

---

## Claim 16: "the runner unsets `RUN_TESTS_NOT_RUN_FILE` after writing it"

**Location:** `docs/working/questions.md:93`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the write-then-unset order in scripts/run-tests.sh at f5b7e49d. It does not establish the claimed regression test's failure on the old runner, which was not run.

```bash
# scripts/run-tests.sh:360-369 (fix/q110-not-run-undercount)
if [[ -n "${RUN_TESTS_NOT_RUN_FILE:-}" ]]; then
  echo "${#not_run[@]}" > "$RUN_TESTS_NOT_RUN_FILE"
fi
# The file is this run's answer to its caller, so bats and the suites must not
# inherit the path: …
unset RUN_TESTS_NOT_RUN_FILE
```

Main has the write at :357-358 and no unset.

**Evidence:** `scripts/run-tests.sh:360-369` (f5b7e49d), `scripts/run-tests.sh:357-358` (main)

---

## Claim 17: "the top-level ancestor and config-dir listing uses `find -ignore_readdir_race`, retries up to 3 times … re-checks that every top is still a directory"

**Location:** `docs/working/questions.md:109`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the retry count and the race flag in scripts/lib/dev-cycle-read.sh at c035f2e7. It does not establish the race test's or the mutants' results, or the residual's exploitability.

```bash
# scripts/lib/dev-cycle-read.sh:1566-1567 (c035f2e7; excerpt ends :1567, enclosing block continues — read through :1570)
  if [[ ${#tops[@]} -gt 0 ]]; then
    top_files fl "${tops[@]}" 2>/dev/null || top_files fl "${tops[@]}" 2>/dev/null || top_files fl "${tops[@]}" || return 1
```

`:1551` names `(-ignore_readdir_race)` in the comment above `top_files`. The diff against main touches only that lib in gate code (`scripts/lib/dev-cycle-read.sh | 58 +++…`), plus run-tests.sh from the merged-in Q-110.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1545-1570` (c035f2e7)

---

## Claim 18: Q-163 and Q-164's pastes — "merges the branch alone, or `merge/u5-and-q145` (both units …) if U5 is already on main"; "`merge/build-loop-u5-resolved` (this cycle's chore branch, Q-110 and U5 …; U5's reviewed tip is unchanged inside it), or `merge/u5-and-q145` if Q-145 is already on main"; and Q-162's "Run it before Q-163 and Q-164. Their pastes abort on a conflict, and once main moves, the loop rebuilds their merge branches."

**Location:** `docs/working/questions.md:110-116`, `docs/working/questions.md:140-146`, `docs/working/questions.md:83`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers branch composition, the paste conditions, and simulated merges after this branch lands and after Q-162. It does not establish clean merges in that order. They conflict, and the pastes abort as they say.

merge/u5-and-q145 (a04d9776) contains 7c91b974, c035f2e7 and f5b7e49d. merge/build-loop-u5-resolved (0f94bb77) contains 7c91b974, f5b7e49d and the chore branch at 46942678, but not c035f2e7. The conditions test `git merge-base --is-ancestor 7c91b974… HEAD` (Q-163) and `… c035f2e7… HEAD` (Q-164), which match the stated rules. Simulated in a scratch object store: with this branch landed (C1), c035f2e7 merges cleanly, and both combined branches conflict in roadmap.md, questions-archive.md and questions.md. After Q-162 (C2), every candidate also conflicts in docs/reviews/override-log.md. Both pastes wrap the merge in

```bash
# docs/working/questions.md:116
{ git merge --no-ff "$B" -m "…" || { git merge --abort; echo "conflict: merge aborted; the loop rebuilds this entry's branch against main"; }; }
```

so they fail safe, as the entry says. Both combined branches carry the older chore-branch state 46942678, which is why they conflict once 16136a60 lands. The rebuild the entry promises is therefore required.

**Evidence:** `docs/working/questions.md:110-146`; `execlogs/merge-sim.log` (cmds `git merge-tree --write-tree --name-only <C1|C2> <branch>` with `GIT_OBJECT_DIRECTORY` set to scratch, cwd the worktree, exit 0 or 1 per line, 2026-10-15)

---

## Claim 19: References to Q-156 ("once the image is rebuilt (Q-156)") and Q-149..Q-156 / Q-155 as live entries

**Location:** `docs/working/questions.md:120`, `docs/working/questions.md:133-153`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers where these IDs are defined. It does not establish that a main-only reader can resolve them before U5 lands.

Q-149, Q-150, Q-151, Q-152, Q-153, Q-155 and Q-156 are `### Q-…` entries in feat/build-loop-u5's questions.md, and Q-154 is in its archive (`questions-archive.md:2712`). None is defined in HEAD's questions files. Q-164 says so ("files Q-149..Q-156", questions.md:136), but Q-163's table cites Q-156 without saying it lives on U5's branch. The rest is paraphrased — no quote available because it is `git grep` hit and absence lists. Every other Q-id the diff adds resolves to an entry in HEAD.

**Evidence:** `docs/working/questions.md:120`, `:136`; `git grep '### Q-15' feat/build-loop-u5 -- docs/working/`

---

## Claim 20: "Size: 26 code lines outside `docs/`, 410 lines in all."

**Location:** `docs/working/questions.md:137`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers `git diff --numstat main...feat/build-loop-u5`. It does not establish which exclusions "in all" used.

Outside docs/: skills/dev-cycle/SKILL.md 14/4, test/scripts/build-loop-read.bats 3/0 and workflows/codebase-onboarding.md 4/1, for 26, which matches. Excluding docs/reviews/, the total is 409, not 410. The measurement is paraphrased — no quote available because it is a numstat sum. The difference is one line, possibly from a different base or exclusion.

**Evidence:** `git diff --numstat main...feat/build-loop-u5`

---

## Claim 21: "(roadmap Next 3: Q-117, Q-125/Q-130 and Q-098 wait on this)" and "**Blocks:** roadmap Next 3, and through it Q-125's merge …"

**Location:** `docs/working/questions.md:161`, `docs/working/questions.md:178`
**Type:** Reference
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the roadmap position cited. It does not establish the blocking relationship itself, which holds.

The branch-verify item is now in Now (`roadmap.md:51`, "**Verify a branch without installing it** (was Next 3; …"), and Next 3 is

```markdown
<!-- docs/roadmap.md:87 -->
3. **`cc-isolated --profile` accepts path-like values, and `--register` with no profile
```

The item left Next at de9590ad, so both mentions should read "roadmap Now (branch verify)".

**Evidence:** `docs/working/questions.md:161`, `:178`; `docs/roadmap.md:51`, `:87`

---

## Claim 22: "`cc-isolated --list` should show "Verified live: NO" and `Next: cc-isolated --probe-only <repo>` alone on its line."

**Location:** `docs/working/questions.md:203`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers which code path prints those strings at 47da5a4b and at merge/ready-2026-10-15. It does not establish what install.sh's bless step prints on the host.

`--list` dispatches to `list_projects`, which prints one combined line:

```bash
# devcontainer-config/cc-isolated.sh:484-491 (47da5a4b; excerpt ends :491, list_projects continues — read)
list_projects() {
  local pd f pid b
  if b="$(blessed_hash)"; then
    if is_verified_live; then
      echo "Blessed config $b — verified live: yes"
    else
      echo "Blessed config $b — verified live: NO (run: cc-isolated --probe-only <repo>)"
```

The two strings the probe expects come from the bless report, not from `--list`:

```bash
# devcontainer-config/cc-isolated.sh:317-318 (47da5a4b, inside bless_manifest)
    echo "Verified live:  NO — a bless is a review, not a test. Nothing has run this config."
    echo "  Next: cc-isolated --probe-only <repo>"
```

The same holds on merge/ready-2026-10-15 (`:328-329` against `:501`). A user who runs `cc-isolated --list` as told sees neither the "Verified live: NO" line nor a standalone `Next:` line, and may report a false failure of the rebuild-hint fix. Fix: say the two lines appear in the bless output that `install.sh` (or `cc-isolated --bless`) prints, and that `--list` shows `verified live: NO (run: …)`.

**Evidence:** `devcontainer-config/cc-isolated.sh:300-320`, `:484-495`, `:799` (47da5a4b); `devcontainer-config/cc-isolated.sh:326-329`, `:499-501` (merge/ready-2026-10-15)

---

## Claim 23: "each of the first three must print an ERROR and `exit=2` with nothing done" (`cc-isolated ~/code/a ~/code/b`, `cc-isolated --list  # registered projects`, `cc-isolated --profile '#' --bless`)

**Location:** `docs/working/questions.md:211-218`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the launcher's parse-time refusals at f6f37fad, run with the argv that default zsh produces (where `#` is not a comment). It does not establish the fourth line's live probe or the behavior of the installed copy on the host.

Run from a git-archive extract of f6f37fad with a scratch HOME, all three exited 2 with `ERROR: two workspaces given: …`, `ERROR: \# is not a workspace; it looks like a pasted comment.` and `ERROR: \# is not an egress profile; it looks like a pasted comment.` The refusals sit in the arg loop, before the host-tool check or any action:

```bash
# devcontainer-config/cc-isolated.sh:796 and :806 (f6f37fad)
          \#*) pasted_note_error "$2" "an egress profile" ;;
      \#*)          pasted_note_error "$1" "a workspace" ;;
```

**Evidence:** `devcontainer-config/cc-isolated.sh:758-820` (f6f37fad); `execlogs/q167b.log` (cmd `HOME=<scratch> PATH=/usr/bin:/bin timeout 20 bash devcontainer-config/cc-isolated.sh <args>`, cwd `…/cfc0357/ow`, exit 2 ×3, 2026-10-15T19:27:22Z)

---

## Claim 24: "the single ```bash block in `docs/working/spike-cc-verify-q117.md` (498 lines with its fences; sha256 of the block 032cc9a8…afb7) … Its first output line must be `script sha256 a65f4c30ba1b8907`" and "five `CHECK … ok` lines"

**Location:** `docs/working/questions.md:247-249`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the doc's block on merge/ready-2026-10-15 (identical to d25254da): its length, its hash, the self-reported script hash, and the number of CHECK lines. It does not establish the paste's runtime behavior on a host, or that no earlier line prints output first on every path.

The doc has exactly one ```` ```bash ```` fence. The block is 498 lines with fences, and the sha256 of its body is `032cc9a81e4e1c9266ec3ad3b5fe7053d9876eb21f5ffa7f0a35f2ccfed4afb7`. The script prints its own hash from `BASH_EXECUTION_STRING`:

```bash
# docs/working/spike-cc-verify-q117.md block line 296
[ -n "${BASH_EXECUTION_STRING:-}" ] && echo "   script sha256 $(printf '%s' "$BASH_EXECUTION_STRING" | sha256sum | cut -c1-16)"
```

The heredoc body hashes to `a65f4c30ba1b8907`. The value does not depend on the edited last line, which is an argument outside the heredoc. The block has five `echo "CHECK … ok"` sites (block lines 210, 213, 223, 227, 229) and `echo "RESULT Q-117 $v …"` at line 489.

**Evidence:** `docs/working/spike-cc-verify-q117.md` (merge/ready-2026-10-15); `execlogs/q169-hash.log` (cmds `sha256sum` and `printf '%s' "$(cat heredoc)" | sha256sum`, cwd `…/cfc0357`, exit 0, 2026-10-15T19:31:03Z)

---

## Claim 25: "Q-168 (`fix/q096b-exit-scan-remote-names`, 75d08a94, stacked on Q-096) … 562 changed lines" and Q-168's "Built 2026-10-15: 75d08a94"

**Location:** `docs/working/questions.md:238`, `docs/working/questions.md:278-291`
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the stacking and size. It does not establish the rubric's red count or the 206/206 test count.

`git merge-base fix/q096b-exit-scan-remote-names fix/q096-exit-scan-insteadof-target` is 8717fd72 (Q-096's tip). Against it, the branch changes cc-exit-scan.sh 244/62, guides/cc-isolated-usage.md 21/16 and test/cc-isolated-functions.bats 218/1, which is 562 lines. The seed 3c8fbf4a that Q-168's original body cites was rebased as 7daf6f80 on that base, as the body asked. All of this is paraphrased — no quote available because it is ref and numstat output.

**Evidence:** `git diff --numstat 8717fd72 75d08a94`; `git log 8717fd72..75d08a94`

---

## Claim 26: "Q-106 [2] is built (`feat/q106-host-settings-merge`, c6d7544f, on `merge/ready-2026-10-15`)" with "Size: 561 code lines" and "Tests: T93–T103 11/11"

**Location:** `docs/working/questions.md:328-342`
**Type:** Reference / Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the branch's relation to the ready branch, its size and its test names. It does not establish the test results or S3-F1's severity.

The branch is forked from an older ready commit (merge-base 184396ea) and is not merged into merge/ready-2026-10-15. `merge-base --is-ancestor c6d7544f merge/ready-2026-10-15` is false, and option [1] says it goes "then into Q-162's branch". So "on" means "built on", and a reader could take it to mean "in". Precise: "built on `merge/ready-2026-10-15` (184396ea); not in it". Size outside docs/ is 579 lines minus decision 037's 18, which is 561, a match. `test/install-host.bats:1646-1806` on the branch defines T93 to T103, which are 11 tests. The verdicts above are paraphrased — no quote available because they are ancestry and numstat output.

**Evidence:** `docs/working/questions.md:328`, `:338-341`; `test/install-host.bats:1646-1806` (c6d7544f)

---

## Claim 27: "Q-106 moved the settings merge jq into `hooks/lib/wiring-merge.jq`, which is outside `live-verify-gate.sh`'s `enforcement` regex. The trust manifest still hashes it"

**Location:** `docs/working/questions.md:354`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the gate regex and enforcement_files() on feat/q106-host-settings-merge. It does not establish what "both installs show it in their reviews" displays.

```bash
# hooks/live-verify-gate.sh:83 (c6d7544f)
enforcement='^devcontainer-config/(Dockerfile|devcontainer\.json|init-firewall\.sh|cc-sni-proxy\.py|link-claude-home\.sh|cc-isolated\.sh|install\.sh$|egress/)'
# devcontainer-config/cc-isolated.sh:149 (c6d7544f, inside enforcement_files)
    if [ -d claude-home ]; then find claude-home \( -type f -o -type l \) | LC_ALL=C sort; fi
```

`hooks` is in `CLAUDE_HOME_SRC` (install.sh:145 on the branch), so `claude-home/hooks/lib/wiring-merge.jq` is hashed, while the repo path `hooks/lib/wiring-merge.jq` does not match the gate regex. Link-claude-home.sh (`:92 MERGE="$SRC/hooks/lib/wiring-merge.jq"`) and install.sh (`:1034`) both use it.

**Evidence:** `hooks/live-verify-gate.sh:80-92`, `devcontainer-config/cc-isolated.sh:128-151`, `devcontainer-config/link-claude-home.sh:92`, `devcontainer-config/install.sh:1023-1034` (c6d7544f)

---

## Claim 28: "Main's hook stays silent on `.cred""entials.json`, `.c\redentials.json`, `git "push"` and `cat "secret"`; the branch's hook approves them."

**Location:** `docs/working/questions.md:368`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the de-quoting deny check on main and its removal on the branch, from reading the code. It does not establish the hook's actual outputs for these four strings, which require execution.

This is an executable guarantee: the hooks run in this sandbox with `--permissions`/`--deny` and JSON on stdin. Execution was required but blocked, because the harness's permission layer denied the command that ran both hooks. Statically, main's header says the deny check runs on "the de-quoted form of either (every `'`, `"` and `\` removed …)" (`hooks/auto-approve-allowed-commands.sh:70-72` on main). The branch's header says "It never emits "ask", "deny" or "defer"" (`:53` on aeda94b2) and that the deny reader "is gone" (`:64-66`). Whether the branch approves each quoted spelling also depends on its shape allowlist, which was not traced end to end. To verify, pipe `{"tool_input":{"command":…}}` into both hook versions with allow rules `Bash(cat:*)`, `Bash(git:*)` and the deny rules, and record stdout.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:66-75`, `:318` (main), `hooks/auto-approve-allowed-commands.sh:50-90`, `:369` (fix/q092-drop-hook-deny-reader)

---

## Claim 29: Q-176's paste builds a settings file with a deny list and an always-allow Bash hook

**Location:** `docs/working/questions.md:371`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the paste's `printf` output being valid JSON with the stated deny rules, and the hook command emitting a PreToolUse allow. It does not establish Claude Code's behavior in the live session, which is the point of the host check.

The paste's `printf` was run unchanged, writing to `out.json` in a scratch dir, because the harness refuses Bash writes to `.claude/` paths. `jq -e .` exits 0, and the hook command `echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow"}}'` prints that object, which parses with `jq -c`. The deny array is `["Bash(*.q092-canary*)", "Bash(rm -rf:*)"]`, as quoted in the paste.

**Evidence:** `docs/working/questions.md:371`; `execlogs/q176-settings.log` (cmd: the paste's `printf … > out.json; jq -e . out.json`, cwd `…/cfc0357/q176`, exit 0, 2026-10-15T19:29:18Z)

---

## Claim 30: "The hook never emits `ask`, and tests pin its stdout … Sizes 413 + 451 lines."

**Location:** `docs/working/questions.md:389`
**Type:** Invariant / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the hook's only decision emission at aeda94b2 and the two unit sizes. It does not establish the independent reviewer's findings or the 35/35 suite count.

```bash
# hooks/auto-approve-allowed-commands.sh:369 (fix/q092-drop-hook-deny-reader)
    echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow"}}'
```

This is the only `permissionDecision` emission in the file (paraphrased — no quote available because the rest is grep absence). U1 (d27a3891, against its ready base 00a27a2f) is 40/77 + 127/169, which is 413. U2 (aeda94b2, against d27a3891) outside docs/ is 1+1 + 6+4 + 100+171 + 5+3 + 38+119 + 3+2 = 453, minus decision log's 2 = 451. Both match.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:53`, `:369` (aeda94b2); `git diff --numstat 00a27a2f d27a3891`, `git diff --numstat d27a3891 aeda94b2`

---

## Claim 31: Q-103 "a reader has landed (`scripts/build-loop.sh --settings`, U1–U4)" and Q-096 "Built 2026-10-15: `fix/q096-exit-scan-insteadof-target` (8717fd72, loop closed), merged by Q-162's paste … `Host-tool-tested: no`"

**Location:** `docs/working/questions.md:442`, `docs/working/questions.md:527`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the reader's presence on main and Q-096's containment in the ready branch. It does not establish the review history in Q-096's note.

```bash
# scripts/build-loop.sh:537 (main)
  --settings) MODE=settings; [[ $# -eq 1 ]] || usage "--settings takes no arguments" ;;
```

8717fd72 is merged into merge/ready-2026-10-15 at 3fe6d6e3.

**Evidence:** `scripts/build-loop.sh:537` (main); `git log --first-parent main..merge/ready-2026-10-15`

---

## Claims Requiring Attention

### Incorrect
- **Claim 22** (`docs/working/questions.md:203`): `cc-isolated --list` prints `Blessed config <hash> — verified live: NO (run: …)`. The "Verified live: NO" and standalone `Next:` lines come from the bless output that install prints. Point probe (a) at that output.

### Stale
- **Claim 13** (`docs/working/questions.md:83`): "main plus five reviewed units" is now seven units (rebuild hint and one-workspace joined), and the branch is based on b279a2ba, not current main.
- **Claim 21** (`docs/working/questions.md:161`, `:178`): Q-165 still says "roadmap Next 3". The branch-verify item is in Now, and Next 3 is the `--profile` bug.

### Mostly Accurate
- **Claim 4** (`docs/roadmap.md:51-52`): cite the branch tip d25254da (research, DD and spike) rather than 22a4bb1f (research and DD only).
- **Claim 7** (`docs/roadmap.md:116-119`, `questions-archive.md:2738`): ENTRIES is not wholly untested. `test/link-claude-home-wiring.bats` pins `scripts`, and what is missing is a parity test.
- **Claim 20** (`docs/working/questions.md:137`): 409 lines measured, not 410.
- **Claim 26** (`docs/working/questions.md:328`): Q-106 is built on merge/ready-2026-10-15 (184396ea), not in it. Say so, so no one expects Q-162 to land it.

### Unverifiable
- **Claim 5** (`docs/roadmap.md:77-79`): the cycle-2 tally does not reproduce under the stated window (45/29/40/5, adding 188e0a7d). Its counting rule is needed, and the adjacent cycle-3 line uses different criteria.
- **Claim 8** (`cycle-2026-10-14.md:13`, `questions.md:92`, `:100`): T69 passed 2/2 alone on main's tree here. The 3/3 failure is load- and timing-dependent, so main may not be red on T69 everywhere.
- **Claim 28** (`docs/working/questions.md:368`): executing both hook versions on the four quoted spellings is needed. The run was blocked by a permission denial.

## Goal-Alignment Note

The PR's goal is to land the 2026-10-14 cycle's docs and its 2026-10-15 follow-ons onto main via 16136a60, keeping both sides of the merge. The resolution holds. No entry, roadmap item, Idea or idea-log line from either side was lost or duplicated beyond the drops the merge message names, and `questions.sh check` passes. Every cited branch and SHA exists and is unmerged, so nothing in Now or the merge asks is already landed.

The finding that bears most on the next step: Q-162's paste conflicts on today's main and has no `--abort`. It merges cleanly only after this branch lands, so landing order matters. After Q-162, Q-163's and Q-164's combined branches conflict as they say, and their pastes abort safely. The for-author items (Claims 13, 21, 22, plus 4, 7, 20, 26) are text corrections inside question entries. Claim 22 is the only one that would mislead the user at the terminal, during the Q-167 host probe.
