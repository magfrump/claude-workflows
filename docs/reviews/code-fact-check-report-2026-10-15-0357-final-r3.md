Commit: 2141f7ee

# Code Fact-Check Report

**Repository:** claude-workflows, worktree `/workspace/.claude/wt-dev-cycle-2026-10-15-0357` (HEAD 2141f7ee4ffbc7afd59b7b29664e4b49b801c9d4; main 7f711bfe23b224a71c85fb06597ca4d91e9fdb65)
**Scope:** `git diff main...2141f7ee` (final confirming pass, replicate 3 of k=3): `docs/working/questions.md` (Q-160..Q-177 and the index), `docs/working/questions-archive.md` (Q-089, Q-107), `docs/roadmap.md` (Now, Next, Ideas), `docs/working/cycles/cycle-2026-10-14.md`, `docs/working/idea-log.md`, `docs/reviews/override-log.md` (two new rows), and the merge commit 16136a60's message. Review reports added by the branch were read as context, not graded.
**Checked:** 2026-10-15
**Total claims checked:** 35
**Summary:** 31 verified, 1 mostly accurate, 1 stale, 1 incorrect, 1 unverifiable

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) read first. No claim below matches a logged pattern. The one Incorrect (Claim 25) is a stale count copied from an earlier revision of a doc, not a fabricated symbol, so it does not qualify for the log (and this run writes no tracked file other than this report).

Execution provenance. Every executed claim ran under `timeout`, in a throwaway clone or fake HOME under `/tmp/claude-1000/-workspace/b1fde0b4-befb-4424-9add-ef12273f2f26/scratchpad/final-fc-3/` (abbreviated `$S` below), on git 2.39.5, between 2026-10-15T20:02Z and 20:10Z. Captured output is under `$S/logs/`. No paste ran against `/workspace`, no `install.sh`, `cc-isolated` (the real launcher against docker) or `claude` was run, and no process is left running. Pastes that `cd /workspace` were run with only that path rewritten to `$S/clone`, a `git clone --no-checkout /workspace` whose `main` was reset to each state tested.

---

## Claim 1: "User-routed questions grow from 2 to 15 (`you: judgment` 1 to 10) … tech-debt-triage F2, Medium" / "… the copies drifted (five vs seven units, "Next 3", 22a4bb1f vs d25254da, Q-106 "on" the ready branch) … tech-debt-triage F3, Low … Each drifted copy found here is corrected in this landing"

**Location:** `docs/reviews/override-log.md:828-829`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that both rows match F2 and F3 of `docs/reviews/tech-debt-triage-review-2026-10-15-0357.md` (counts, severities, the drift list) and that the four drifted strings are corrected at HEAD; does not establish that the Defer decisions are right (not a factual claim).
**Legibility-target:** for-orchestrator-synthesis

The tech-debt report gives the same counts and severities: `` | you: judgment | 1 | 10 | `` and `` | you: terminal | 1 | 5 | `` (`docs/reviews/tech-debt-triage-review-2026-10-15-0357.md:50-51`), `- **Severity:** Medium` for F2 (:44) and `- **Severity:** Low` for F3 (:75). 1+1 = 2 and 10+5 = 15. F3's evidence list (:79-82) names the same four strings as row 829. At HEAD each is corrected: `That branch is main (as of b279a2ba) plus seven reviewed units` (`docs/working/questions.md:83`); `(roadmap Now, "Verify a branch without installing it": …)` (`docs/working/questions.md:166`); `built on an earlier `merge/ready-2026-10-15` commit, 184396ea; it is not in the ready branch Q-162 merges` (`docs/working/questions.md:343`); `tip d25254da` (`docs/roadmap.md:52`). The answer-order list in row 828 matches F2's "Carrying cost" chain (:59-60) plus the Q-163/164 order. HEAD's index has 10 `you: judgment` and 5 `you: terminal` rows (`docs/working/questions.md:28-42`).

**Evidence:** `docs/reviews/override-log.md:828-829`, `docs/reviews/tech-debt-triage-review-2026-10-15-0357.md:43-90`, `docs/working/questions.md:28-42,83,166,343`, `docs/roadmap.md:52`

---

## Claim 2: Roadmap Now: every unit's branch and hash, and where each lands

**Location:** `docs/roadmap.md:14-56`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that each named branch exists at the named hash, is unmerged into main, and is (or is not) inside `merge/ready-2026-10-15` (a760a5e5) exactly as the line says; does not establish the review outcomes the lines summarise.
**Legibility-target:** for-orchestrator-synthesis

Branch tips, from `git rev-parse`, all unmerged into main (paraphrased — no quote available because the evidence is ref and ancestry queries, captured in `$S/logs/refs.log`): `fix/t69-stage-race` 4ee81106, `fix/doc-drift-cycle1` c8e87a69, `fix/q160-iteration-cap` 4a44d2f3, `fix/q096-exit-scan-insteadof-target` 8717fd72, `fix/rebuild-hint-recreate` 47da5a4b, `fix/cc-isolated-one-workspace` f6f37fad, `docs/branch-verify-without-install` d25254da, `fix/q096b-exit-scan-remote-names` 75d08a94, `fix/q092a-drop-deny-option` d27a3891, `fix/q092-drop-hook-deny-reader` aeda94b2, `feat/build-loop-u5` 7c91b974, `fix/q110-not-run-undercount` f5b7e49d, `fix/q145-ancestor-vanish` c035f2e7. The lines saying "in `merge/ready-2026-10-15`" or "waits on Q-162's paste" (T69, doc drift, Q-160, Q-096, Q-110, the rebuild hint, one workspace, the branch-verify docs) name commits that are ancestors of a760a5e5; Q-168 (75d08a94), Q-092 (d27a3891, aeda94b2), U5 and Q-145 are not, matching lines 11-13, 36-40 and 46-49. aeda94b2 contains d27a3891 ("then"), and 75d08a94 contains 8717fd72.

**Evidence:** `docs/roadmap.md:14-56`, `$S/logs/refs.log`

---

## Claim 3: "Cycle 2 (2026-10-14): 42 multi-file landings; 25/42 carry the line, 38/42 committed a rubric, 4/42 have neither (df18413a, 0fbf9742, b8807e76, 52053432)"

**Location:** `docs/roadmap.md:77-79` (and the same tally at `docs/working/cycles/cycle-2026-10-14.md:55`)
**Type:** Configuration
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the tally on main at b279a2ba over first-parent merges with committer date on or after 2026-10-02 that change more than one file, minus cycle 1's three landings, counting "the line" as `← carried from RPI` in the message and "a rubric" as a merge diff touching a `code-review-rubric` file; does not establish that the cycle used exactly this operationalisation (it is the one that reproduces every figure).

Command (cwd `/workspace/.claude/wt-dev-cycle-2026-10-15-0357`, 2026-10-15T20:09Z, exit 0): a loop over `git log --first-parent --merges --format='%h|%cd' --date=format:%Y-%m-%d b279a2ba`, filtered to dates ≥ 2026-10-02 and >1 changed file, grepping each message for `← carried from RPI` and each `git diff --name-only m^1 m` for `code-review-rubric`. Output: 45 merges, 25 with the line, 40 with a rubric, neither on df18413a, 0fbf9742, b8807e76, 52053432 and 188e0a7d. Cycle 1's three landings since 4225753a (188e0a7d, 90364c73, cac2ba0c; Cycle 1's own line says "0/3 carry the line, 2/3 committed a rubric, 1/3 (188e0a7d …) has neither", `docs/roadmap.md:75-76`) account for the difference: 45−3 = 42, 25−0 = 25, 40−2 = 38, and the four remaining "neither" are exactly the four named.

**Evidence:** `docs/roadmap.md:75-79`, `docs/working/cycles/cycle-2026-10-14.md:55`, `$S/logs/router-uptake-b279a2ba.log`

---

## Claim 4: Roadmap Next 4 and 5: "`feat/q106-host-settings-merge`, c6d7544f" and "`docs/dd-015-step4`, f050b487, lands with Q-162"

**Location:** `docs/roadmap.md:92-98`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two hashes, that f050b487 is inside a760a5e5 and c6d7544f is not; does not establish the DD's conclusions.
**Legibility-target:** for-orchestrator-synthesis

`docs/dd-015-step4` resolves to f050b487 and `feat/q106-host-settings-merge` to c6d7544f; f050b487 is an ancestor of a760a5e5 (merged as 11184f2b on the ready branch), c6d7544f is not (paraphrased — no quote available because the evidence is ref queries, `$S/logs/refs.log`). f050b487 adds one file, `docs/working/dd-015-step4-isolation-mechanism.md | 387 +++` (`git show --stat f050b487`).

**Evidence:** `docs/roadmap.md:92-98`, `$S/logs/refs.log`

---

## Claim 5: "The seven source paths are in `install.sh:135`, and a second copy of the names, with no parity test, is in `link-claude-home.sh:50`"

**Location:** `docs/roadmap.md:116-122`
**Type:** Reference / Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers main's line numbers and the seven names; "no parity test" covers that no test compares the two lists (one test pins only `scripts`), not whether one should exist.
**Legibility-target:** for-orchestrator-synthesis

`main:devcontainer-config/install.sh:135`: `CLAUDE_HOME_SRC=(global-instructions/CLAUDE.md skills workflows guides patterns hooks scripts)` (seven entries). `main:devcontainer-config/link-claude-home.sh:50`: `ENTRIES=(skills workflows guides patterns hooks scripts CLAUDE.md)`. The only test touching both is `test/link-claude-home-wiring.bats:307`: `grep -qE '^CLAUDE_HOME_SRC=\(.* scripts( |\))' "$REPO_ROOT/devcontainer-config/install.sh"`, which pins `scripts` alone.

**Evidence:** `devcontainer-config/install.sh:135`, `devcontainer-config/link-claude-home.sh:50`, `test/link-claude-home-wiring.bats:296-307`

---

## Claim 6: "Main at: b279a2ba…" · "12 merged branches (feat/build-loop-u3a1…u4c) and their worktrees go in Q-162's paste" · "Q-089 closed (merged 626dc300, df18413a)"

**Location:** `docs/working/cycles/cycle-2026-10-14.md:5,13,15`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the hashes and the twelve branches' merged state; does not establish the health-check result on line 13 (see Claim 35).
**Legibility-target:** for-orchestrator-synthesis

b279a2ba is the merge-base of HEAD's two sides (`git merge-base 16136a60^1 16136a60^2` = b279a2ba2a8ff1b905cc56a9d3a5323fef7f0d26). All twelve `feat/build-loop-{u3a1,u3a2,u3a3,u3b1,u3b2,u3b3,u3c,u3d,u4a,u4b1,u4b2,u4c}` are ancestors of main, and each has a worktree at `/workspace/.claude/wt-build-loop-<u>` on that branch with a clean `git status --porcelain` (paraphrased — no quote available because the evidence is ref and worktree queries, `$S/logs/refs.log`). 626dc300 and df18413a are both ancestors of main.

**Evidence:** `docs/working/cycles/cycle-2026-10-14.md:5,13,15`, `$S/logs/refs.log`

---

## Claim 7: "Its FP-173 was renumbered FP-174 (db325bcb), and Q-110 was merged in (c035f2e7)" · "Merge entry Q-164, via `merge/build-loop-u5-resolved` (this chore branch plus U5, conflicts resolved)"

**Location:** `docs/working/cycles/cycle-2026-10-14.md:74-75`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers commit identities and ancestry; does not establish the conflict resolutions' content.
**Legibility-target:** for-orchestrator-synthesis

`git log --oneline -4 c035f2e7`: `c035f2e7 Merge branch 'fix/q110-not-run-undercount' into fix/q145-ancestor-vanish: pre-resolve the failure-patterns append` and `db325bcb docs(failure-patterns): renumber Q-145's entry FP-174`. `git log --first-parent --oneline 0f94bb77`: `0f94bb77 Merge branch 'fix/q110-not-run-undercount' into merge/build-loop-u5-resolved`, `e088c7e3 Merge branch 'feat/build-loop-u5' into merge/build-loop-u5-resolved: U5 on top of cycle 2026-10-14`, `46942678 docs(cycle): …`, `63af3551 docs(cycle): dev cycle 2026-10-14, run by hand`, `b279a2ba …`. So the resolved branch is this chore branch's first two commits plus U5 plus Q-110.

**Evidence:** `docs/working/cycles/cycle-2026-10-14.md:74-75`, `git log c035f2e7`, `git log 0f94bb77`

---

## Claim 8: "Built and merged on Q-148 [1]: A1+A2 as 626dc300, B as df18413a"

**Location:** `docs/working/questions-archive.md:2727`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two merge hashes being on main and Q-148's archived answer naming them; does not establish the listed feature contents of each merge.
**Legibility-target:** for-orchestrator-synthesis

Both hashes are ancestors of main. Q-148's archived answer says `Merged: A as 626dc300, B as df18413a.` (`docs/working/questions-archive.md:2698`), and df18413a's subject is `Merge branch 'feat/q089b4-host-tool-gate': host tools carry Host-tool-tested, not Live-verified (Q-089 unit B, Q-148 [1])` (`git log -1 df18413a`).

**Evidence:** `docs/working/questions-archive.md:2698,2727`

---

## Claim 9: Q-107's resolution: "`devcontainer-config/install.sh` (:135, :329-362; callers :498 and :858), and `link-claude-home.sh:50` … (one test pins `scripts`)"

**Location:** `docs/working/questions-archive.md:2738`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every line number in the resolution against main's files; does not cover the question body's original "lines 498 and 857" (line 2734), which is the text as filed and was correct then.
**Legibility-target:** for-orchestrator-synthesis

On main: `install.sh:135` `CLAUDE_HOME_SRC=(…)`; `install.sh:329` `assemble() {`, closing `}` at :362; `install.sh:498` `  assemble "$stage/claude-home" "${dc_paths[@]}"`; `install.sh:858` `  assemble "$stage"`. `link-claude-home.sh:50` `ENTRIES=(…)`. The body's "857" (`docs/working/questions-archive.md:2734`) was moved verbatim from the open entry; at 20a462d4, where that text was introduced, the second caller was at :857 (`git show 20a462d4:devcontainer-config/install.sh` → `857:  assemble "$stage"`), so it is historical, and the resolution gives the current :858. "Q-106's branch does not change this": on c6d7544f the array and function are still in install.sh (`145:CLAUDE_HOME_SRC=…`, `339:assemble() {`).

**Evidence:** `devcontainer-config/install.sh:135,329-362,498,858`, `devcontainer-config/link-claude-home.sh:50`, `docs/working/questions-archive.md:2734,2738`

---

## Claim 10: Q-162's description of `merge/ready-2026-10-15`: "main (as of b279a2ba) plus seven reviewed units, the branch-verify research and spike docs …, the decision-015 divergent design …, and this cycle's record, each merged with `--no-ff`" · the per-unit hashes and sizes in Read · "The tip, a760a5e5, adds after that gate the rebuild-hint and one-workspace unit merges …, two docs-branch merges and nine cycle-record merges"

**Location:** `docs/working/questions.md:83,95-102`
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the ready branch's first-parent merge list, each unit's hash, and the stated sizes (code lines outside `docs/`, pr-prep step 1a's measure); does not establish the test and gate results quoted in the bullets (Claim 35).
**Legibility-target:** for-orchestrator-synthesis

`git log --first-parent --oneline b279a2ba..a760a5e5` lists 19 merges (paraphrased — no quote available because the list is 19 lines): one chore merge, then T69, Q-110, doc drift, Q-160 and Q-096 (3fe6d6e3), then after 3fe6d6e3 exactly 9 `chore/dev-cycle-2026-10-15-0357` merges, 2 docs merges (`docs/branch-verify-without-install` a53e1bc2, `docs/dd-015-step4` 11184f2b) and the 2 unit merges (rebuild hint c29d1acf, one workspace fc4c6840). Seven units in total. Sizes from `git diff --numstat` outside `docs/` against each unit's base: Q-160 43, Q-096 399, rebuild hint 131, one workspace 260; doc drift `6 files changed, 26 insertions(+), 10 deletions(-)` outside `docs/reviews`; T69 changes only `test/install-host.bats` (`$S/logs/refs.log`).

**Evidence:** `docs/working/questions.md:83,95-102`, `$S/logs/refs.log`

---

## Claim 11: "**Not runnable yet (2026-10-15):** … After Q-178's landing of the 0357 cycle branch, merging a760a5e5 conflicts in `docs/reviews/override-log.md` (and, before it, in the questions, roadmap and idea-log files), so the paste below aborts and deletes nothing."

**Location:** `docs/working/questions.md:85`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `git merge-tree` and the real paste against main at 7f711bfe and at 2141f7ee (a fast-forward stand-in for the landing; main is an ancestor of HEAD); does not establish the result against whatever merge commit the actual landing creates, if it differs in content from 2141f7ee.
**Legibility-target:** for-author

After landing it is exactly as stated: `git merge-tree --write-tree --name-only 2141f7ee a760a5e5` lists only `docs/reviews/override-log.md`, and the paste prints `CONFLICT (content): Merge conflict in docs/reviews/override-log.md` then `conflict: merge aborted, nothing deleted`, exit 1, main unmoved (`$S/logs/q162-2141f7ee.log`). Before landing (main 7f711bfe) the conflicting files are four, not three: `docs/roadmap.md`, `docs/working/idea-log.md`, `docs/working/questions-archive.md`, `docs/working/questions.md` (`$S/logs/q162-7f711bfe.log`, `$S/logs/merge-tree.log`). The parenthetical omits `questions-archive.md`; precise version: "(and, before it, in the questions, questions-archive, roadmap and idea-log files)". The mechanism and conclusion (aborts, deletes nothing) hold in both states.

Commands: `timeout 60 bash $S/q162.sh` (the paste with `cd /workspace` → `cd $S/clone` and the `for` body replaced by an echo), cwd `$S/clone`, 2026-10-15T20:02:17Z, exit 1 in both states.

**Evidence:** `docs/working/questions.md:85-92`, `$S/logs/q162-7f711bfe.log`, `$S/logs/q162-2141f7ee.log`, `$S/logs/merge-tree.log`

---

## Claim 12: Q-162's paste: "merges `merge/ready-2026-10-15` by its reviewed tip, a760a5e5 (a branch name can move; a hash cannot, once the paste has checked that no replace refs exist), then deletes the twelve build-loop branches …" with a conflict path that aborts and deletes nothing

**Location:** `docs/working/questions.md:83,87-92`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `&&`/`||` grouping on the not-on-main, replace-ref, conflict and success-gating paths in bash, and that the twelve worktrees exist, are clean and are on merged branches, so `git worktree remove` and `git branch -d` can succeed; does not establish the `for` loop's own behaviour on a worktree that becomes dirty or locked before the paste runs (each iteration is independent and a failure there does not stop later ones), and was not run in zsh.
**Legibility-target:** for-orchestrator-synthesis

```
cd /workspace && test "$(git branch --show-current)" = main && \
{ test -z "$(git for-each-ref refs/replace/)" || { echo "replace refs present: stop"; false; }; } && \
{ git merge --no-ff a760a5e5… -m "…" || { git merge --abort; echo "conflict: merge aborted, nothing deleted"; false; }; } && \
for u in u3a1 … u4c; do git worktree remove .claude/wt-build-loop-$u && git branch -d feat/build-loop-$u; done
```
(`docs/working/questions.md:88-91`). Executed in `$S/clone`: with a replace ref planted (`git replace a760a5e5 2141f7ee`) it printed `replace refs present: stop`, exit 1, no merge (`$S/logs/q162-replace.log`); on a non-main branch it exited 1 silently (`$S/logs/q162-notmain.log`); on conflict, abort and exit 1 (Claim 11). Because the merge group ends in `false`, the `&&` keeps the loop from running on any failure. The path `/workspace` is where the paste must run: the twelve worktrees are registered as `/workspace/.claude/wt-build-loop-<u>` (`git worktree list`), and the loop removes them by the relative path `.claude/wt-build-loop-$u` from `/workspace`.

**Evidence:** `docs/working/questions.md:87-92`, `$S/logs/q162-replace.log`, `$S/logs/q162-notmain.log`, `$S/logs/q162-2141f7ee.log`, `$S/logs/refs.log`

---

## Claim 13: "`fix/q110-not-run-undercount` (f5b7e49d): the runner unsets `RUN_TESTS_NOT_RUN_FILE` after writing it. A regression test fails on the old runner."

**Location:** `docs/working/questions.md:96`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the runner's write-then-unset order at f5b7e49d and the new test failing against main's `scripts/run-tests.sh`; does not establish the gate results in the same bullet (Claim 35).
**Legibility-target:** for-orchestrator-synthesis

```
360 if [[ -n "${RUN_TESTS_NOT_RUN_FILE:-}" ]]; then
361   echo "${#not_run[@]}" > "$RUN_TESTS_NOT_RUN_FILE"
362 fi
…
369 unset RUN_TESTS_NOT_RUN_FILE
```
(`f5b7e49d:scripts/run-tests.sh:360-369`). Command: `timeout 120 bats -f 'do not inherit' test/skills/eval-helpers-gating.bats`, in `$S/q110new` (f5b7e49d's `scripts`, `test/skills`, `test/lib`) and in `$S/q110old` (the same with main's `run-tests.sh`), 2026-10-15T20:04:45Z. New: `ok 1`, exit 0. Old: `not ok 1 … `[ "$(cat "$T/nr")" = 4 ]' failed`, exit 1.

**Evidence:** `scripts/run-tests.sh:360-369` (at f5b7e49d), `test/skills/eval-helpers-gating.bats:74-87` (at f5b7e49d), `$S/logs/q110-q110new.log`, `$S/logs/q110-q110old.log`

---

## Claim 14: "The hint's first line is now `cc-isolated --probe-only WS && cc-isolated WS`. The copyable lines lose their trailing `# …` notes"

**Location:** `docs/working/questions.md:100`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers `rebuild_hint()`'s first echo on the ready branch; does not establish the other copyable lines in the guides.
**Legibility-target:** for-orchestrator-synthesis

`a760a5e5:devcontainer-config/cc-isolated.sh:580`: `echo "    cc-isolated --probe-only $(printf '%q' "$ws") && cc-isolated $(printf '%q' "$ws")" >&2`, and the explanation sits on its own line (:581) with the comment at :578-579 giving the zsh reason.

**Evidence:** `devcontainer-config/cc-isolated.sh:571-583` (at a760a5e5)

---

## Claim 15: Q-163's paste: merges `fix/q145-ancestor-vanish` at c035f2e7, or `merge/u5-and-q145` at a04d9776 if U5 is on main; aborts on conflict

**Location:** `docs/working/questions.md:113-120`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the selection test, the hashes' contents, and both outcomes; does not establish that the paste still merges after this branch lands: against 2141f7ee it conflicts in `docs/reviews/override-log.md` and aborts, which the entry covers only through its abort message and Q-162's "once main moves, the loop rebuilds their merge branches".
**Legibility-target:** for-orchestrator-synthesis

`if git merge-base --is-ancestor 7c91b974… HEAD; then B=a04d9776…; else B=c035f2e7…; fi` (`docs/working/questions.md:118`). a04d9776 contains both 7c91b974 and c035f2e7; c035f2e7 contains f5b7e49d (Q-110), as "Merging this therefore also brings Q-110" says (:112). Executed in `$S/clone` with main at 7f711bfe: `Merge made by the 'ort' strategy.`, a new merge commit on main, exit 0 (`$S/logs/q163-7f711bfe.log`). With main at 2141f7ee: `CONFLICT (content): Merge conflict in docs/reviews/override-log.md` then `conflict: merge aborted; the loop rebuilds this entry's branch against main`, main unmoved (`$S/logs/q163-2141f7ee.log`). Unlike Q-162 the group has no trailing `false`, which is harmless here because nothing follows it.

**Evidence:** `docs/working/questions.md:112-120`, `$S/logs/q163-7f711bfe.log`, `$S/logs/q163-2141f7ee.log`

---

## Claim 16: Q-164 "**Paste for [1]:** it merges `merge/build-loop-u5-resolved` at 0f94bb77 …, or `merge/u5-and-q145` at a04d9776 if Q-145 is already on main" and option [1] "One paste, then the release"

**Location:** `docs/working/questions.md:144-155`
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the paste against main as it is now (7f711bfe) and as it will be after this branch lands (2141f7ee); does not establish behaviour after a rebuild of its merge branches.
**Legibility-target:** for-author

The branch contents are as described: 0f94bb77 is `63af3551`/`46942678` (this chore branch's first commits) plus U5 (7c91b974) plus Q-110 (Claim 7), and a04d9776 contains both units. But neither merge can succeed in any state the user can now reach. With main at 7f711bfe (Q-145 not on main, so `B=0f94bb77…`) it conflicts in roadmap, idea-log, questions-archive and questions; with main at 2141f7ee it conflicts in override-log, roadmap, questions-archive and questions. Both times it prints `conflict: merge aborted; the loop rebuilds this entry's branch against main` and leaves main unmoved (`$S/logs/q164-7f711bfe.log`, `$S/logs/q164-2141f7ee.log`). It was runnable when written (2026-10-14, main b279a2ba). Q-162 got a "Not runnable yet" note for the same cause (main moved with Q-178); Q-164 did not, so its "[1] merge … One paste" reads as runnable. The failure path is safe and self-describing.

**Evidence:** `docs/working/questions.md:144-155`, `$S/logs/q164-7f711bfe.log`, `$S/logs/q164-2141f7ee.log`, `$S/logs/merge-tree.log`

---

## Claim 17: Q-164: "files Q-149..Q-156 (C1–C5, the constraints doc, the image-lag release entry)"; "**Blocks:** Q-156 (the release), Q-103, and dispatch (Q-155: `docs/constraints.md`)"; Q-163: "(Q-156, filed on `feat/build-loop-u5`; it reaches main with Q-164)"

**Location:** `docs/working/questions.md:124,140,159`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that each cited ID exists, and where; does not establish the content of those entries.
**Legibility-target:** for-orchestrator-synthesis

Q-149..Q-156 exist on neither main nor HEAD; they exist only on `feat/build-loop-u5` (7c91b974): `### Q-149 · self-merge-never-scope` … `### Q-156 · image-lag` in its `questions.md`, and `### Q-154 · build-loop-c5-cycle-cost` in its archive (`7c91b974:docs/working/questions-archive.md:2712`). The entries say so (:124 "filed on `feat/build-loop-u5`", :140 "files Q-149..Q-156"). Q-164's Blocks line (:159) cites Q-155 and Q-156 without repeating "on the U5 branch", but the same entry establishes it two bullets earlier. Every other Q-id cited in Q-160..Q-177 and in roadmap Now/Next exists on HEAD, open or archived (paraphrased — no quote available because the evidence is a grep over all cited IDs); none cites an archived question as open, and no "Next N" reference in the open entries is stale (the roadmap's "was Next 3/4" and the cycle record's "Next 3/4" are dated history).

**Evidence:** `docs/working/questions.md:124,140,159`, `7c91b974:docs/working/questions.md`, `7c91b974:docs/working/questions-archive.md:2712`

---

## Claim 18: "`docs/working/research-branch-verify-without-install.md` and `docs/working/dd-branch-verify-without-install.md` on `docs/branch-verify-without-install` (22a4bb1f; the branch tip, d25254da, adds the spike doc and its review commits)"

**Location:** `docs/working/questions.md:169`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two commits' file sets; does not establish the research doc's findings summarised beneath.
**Legibility-target:** for-orchestrator-synthesis

`git ls-tree --name-only 22a4bb1f docs/working/` shows `dd-branch-verify-without-install.md` and `research-branch-verify-without-install.md` and no spike doc; `git diff --name-only 22a4bb1f d25254da` includes `docs/working/spike-cc-verify-q117.md` and the `docs/reviews/*cc-verify-spike*` files. d25254da is the branch tip.

**Evidence:** `docs/working/questions.md:169`, `git ls-tree 22a4bb1f`, `git diff --name-only 22a4bb1f d25254da`

---

## Claim 19: "For Q-125 that difference is real: a staged run never executes its `install.sh` `PAYLOAD` or `cc-isolated.sh` `enforcement_files()` changes (Q-117 changes only `init-firewall.sh`)"

**Location:** `docs/working/questions.md:196`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what each branch changes; "never executes" rests on Q-165's finding (`docs/working/questions.md:173`) that main's launcher loads its code from its own directory, which this claim did not re-trace.
**Legibility-target:** for-orchestrator-synthesis

Q-125's U2 (2961ca2f) against its merge-base with main changes `PAYLOAD`: `-PAYLOAD=(devcontainer.json Dockerfile init-firewall.sh …)` / `+PAYLOAD=(devcontainer.json Dockerfile seccomp-cc-sandbox.json managed-settings.json cc-sandbox-settings.sh init-firewall.sh …)`, and adds three `echo` lines to `enforcement_files()` (`+  echo "seccomp-cc-sandbox.json"` …). Q-117 (`fix/egress-dnsmasq-ipset`, b26d4b8b) changes `devcontainer-config/init-firewall.sh` and otherwise only docs and `test/init-firewall-rules.bats`, matching the spike's `BRANCH_PATHS`.

**Evidence:** `devcontainer-config/install.sh` (2961ca2f diff), `devcontainer-config/cc-isolated.sh` (2961ca2f diff), `git diff --name-only $(git merge-base main b26d4b8b) b26d4b8b`

---

## Claim 20: Q-167(a): the bless output "should show `Verified live:  NO — a bless is a review, not a test.` followed by `Next: cc-isolated --probe-only <repo>` alone on its line, and `cc-isolated --list` should show `Blessed config <hash> — verified live: NO (run: cc-isolated --probe-only <repo>)`"

**Location:** `docs/working/questions.md:208`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the strings on the ready branch and that install.sh reaches `bless_manifest`; the first string is a prefix of the printed line, which continues; does not establish the host's live output.
**Legibility-target:** for-orchestrator-synthesis

```
328     echo "Verified live:  NO — a bless is a review, not a test. Nothing has run this config."
329     echo "  Next: cc-isolated --probe-only <repo>"
```
(`a760a5e5:devcontainer-config/cc-isolated.sh:328-329`; main's :316 had the trailing `# rebuilds from it and probes as node`, so "alone on its line" is the change being probed) and `:501` `echo "Blessed config $b — verified live: NO (run: cc-isolated --probe-only <repo>)"` in `list_projects`. install.sh runs `CLAUDE_DEVC_CONFIG_DIR="$DEST" "$DEST/cc-isolated.sh" --bless` (`a760a5e5:devcontainer-config/install.sh:607`), which dispatches to `bless) bless_manifest; exit 0 ;;` (`cc-isolated.sh:856`).

**Evidence:** `devcontainer-config/cc-isolated.sh:324-332,496-503,856` (a760a5e5), `devcontainer-config/install.sh:607` (a760a5e5)

---

## Claim 21: Q-167(b): "Paste these lines as written in default zsh; each of the first three must print an ERROR and `exit=2` with nothing done"

**Location:** `docs/working/questions.md:216-223`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the argv each line produces in `zsh -f -i` and the ready branch's parser on that argv (exit 2, ERROR, no file created in the fake HOME or config dir); does not establish line 4's live probe.
**Legibility-target:** for-orchestrator-synthesis

Step 1, argv: the three lines fed to `zsh -f -i` with a shim `cc-isolated` that prints its arguments gave `argv[1]=--list argv[2]=# argv[3]=registered argv[4]=projects` for line 2 and `--profile # --bless` for line 3, with `echo "exit=$?"` still run after `;` (`$S/logs/q167b-zsh-argv.log`, 2026-10-15T20:09:19Z, cwd `$S`). Step 2, parser: `env -i PATH=/usr/bin:/bin HOME=$S/home2 CLAUDE_DEVC_CONFIG_DIR=$S/home2/cfg timeout 20 bash cc-isolated.sh <argv>` (a760a5e5's `devcontainer-config/` extracted to `$S/dc`), cwd `$S`, 2026-10-15T20:03:46Z: `exit=2` for all three, with `ERROR: two workspaces given: …`, `ERROR: \# is not a workspace; it looks like a pasted comment.` and `ERROR: \# is not an egress profile; …`; `$S/home2/cfg` was never created (`$S/logs/q167b.log`). The parser raises these inside the argument loop, before the host-tool check or any action: `\#*) pasted_note_error "$1" "a workspace" ;;` (`cc-isolated.sh:806`), `\#*) pasted_note_error "$2" "an egress profile" ;;` (:796), and `arg_usage_error` ends in `exit 2` (:763).

**Evidence:** `devcontainer-config/cc-isolated.sh:750-819` (a760a5e5), `$S/logs/q167b-zsh-argv.log`, `$S/logs/q167b.log`

---

## Claim 22: Q-167(c): "a planted pre-receive hook in a repository that a remote is rewritten to must be caught" · "(expect 3, naming hook …/mirror-repo/hooks/pre-receive)"

**Location:** `docs/working/questions.md:227-240`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the paste's repo setup and the ready branch's `git_exec_snapshot`/`git_exit_scan` on it, with the in-session step done directly on the host side, and the launcher's mapping of scan result 1 to exit 3; does not establish the live run through a container (the hook written from inside the bind mount).
**Legibility-target:** for-orchestrator-synthesis

`$S/q167c.bash` sources a760a5e5's `cc-exit-scan.sh`, builds the repo with the paste's exact commands (`git config "url.$T/proj/mirror-.insteadOf" https://example.invalid/`, bare `mirror-repo`), snapshots, plants `printf '#!/bin/sh\necho planted\n' > mirror-repo/hooks/pre-receive`, then scans. Run with `env -i PATH=/usr/bin:/bin LC_ALL=C timeout 120 bash q167c.bash $S`, cwd `$S`, 2026-10-15T20:07:52Z, exit 0: control scan `rc=0`; after planting, `+ hook …/proj/mirror-repo/hooks/pre-receive  file 755 a8d45a183e948465` and `scan rc=1` (`$S/logs/q167c.log`). The launcher maps that to exit 3: `1) exit 3 ;;   # the session planted something: never a clean exit` (`a760a5e5:devcontainer-config/cc-isolated.sh:1005`).

**Evidence:** `devcontainer-config/cc-isolated.sh:1001-1007` (a760a5e5), `$S/q167c.bash`, `$S/logs/q167c.log`

---

## Claim 23: Q-169's extraction: "the single ```bash block in `docs/working/spike-cc-verify-q117.md` (498 lines with its fences)" · the pinned, replace-ref-free `git show a760a5e5…` extraction · "The hash must be `032cc9a8…afb7`" · "Its first output line must be `script sha256 a65f4c30ba1b8907`" · "editing only its last line, the checkout path"

**Location:** `docs/working/questions.md:256-262`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the extraction's output hash, the block's length, that it is the only bash block, the script fingerprint, that editing the last line leaves the fingerprint unchanged, and that the fingerprint is the first line a normal run prints; does not establish the host run itself.
**Legibility-target:** for-orchestrator-synthesis

Command, cwd `$S/clone`, 2026-10-15T20:02:39Z, exit 0: `git -c core.useReplaceRefs=false show a760a5e5057ef3f0abd13145e7d945ef500b8abd:docs/working/spike-cc-verify-q117.md | awk '/^```bash$/{f=1;next} f&&/^```$/{exit} f' > $S/home/cc-verify/q117-spike.txt && sha256sum …` → `032cc9a81e4e1c9266ec3ad3b5fe7053d9876eb21f5ffa7f0a35f2ccfed4afb7`, 496 lines, plus two fences = 498 (`$S/logs/q169-extract.log`). The doc has one ```` ```bash ```` fence (line 49); its blob is the same at a760a5e5 and d25254da (55893b38…). The extracted block is `bash -c "$(cat <<'CCVERIFY' … CCVERIFY\n)" spike-q117 ~/claude-workflows`; the fingerprint line is `[ -n "${BASH_EXECUTION_STRING:-}" ] && echo "   script sha256 $(printf '%s' "$BASH_EXECUTION_STRING" | sha256sum | cut -c1-16)"` (extracted line 296), the first top-level output after the `--clean` branch (everything earlier that prints is inside function bodies). Hashing the heredoc body with its trailing newline stripped, as `$(…)` does, gives `a65f4c30ba1b8907`. The checkout path is only on the last line, outside the hashed string.

**Evidence:** `docs/working/questions.md:256-262`, `docs/working/spike-cc-verify-q117.md:49-546` (a760a5e5), `$S/logs/q169-extract.log`

---

## Claim 24: "Exit 0 with `RESULT Q-117 pass` and five `CHECK … ok` lines is a pass; 2 means no rotation was seen, so rerun later; 1 is a failure or refusal, named by step. On an interrupted teardown, rerun the same block with `--clean` as its last argument."

**Location:** `docs/working/questions.md:264`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the script's CHECK lines, verdict exit codes and `--clean` argument; does not establish the timing ("up to about an hour"), which needs a host run.
**Legibility-target:** for-orchestrator-synthesis

The teardown prints exactly five `CHECK` lines (`main install untouched`, `no pre-existing volume removed`, `verify image carried no pre-existing tag`, `verify volumes gone`, `verify container gone`; extracted lines 210-229). The verdict: `pass) exit 0 ;;`, `no-rotation) … exit 2 ;;`, `*) VERDICT=1; exit 1 ;;` (lines 490-494); refusals go through `die() { DIED=1; printf 'REFUSED: %s\n' "$*" >&2; exit 1; }` (line 49). `if [ "${1:-}" = "--clean" ]; then` (line 269) handles the cleanup argument.

**Evidence:** `$S/home/cc-verify/q117-spike.txt:49,210-229,269,490-494` (the extracted block)

---

## Claim 25: "**Read:** the doc's step table …, "Not verified" (8 items only this run can show) and "Residual risks""

**Location:** `docs/working/questions.md:266`
**Type:** Reference / Staleness
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the item count of the doc's "Not verified" section at the pinned commit; does not grade the items themselves.
**Legibility-target:** for-author

The section at a760a5e5 (same blob as d25254da) has 12 numbered items, `1. **Image naming**` through `12. **The build's network, time and cache.**` (`docs/working/spike-cc-verify-q117.md:664-679`). Per-commit counts of that section: 7 at 12fcb61c, 8 at 190fa1a4, 12 from 53770142 on, through d25254da. Q-169's text was added in b9b4d59a (2026-10-15 03:51), after d25254da (03:50), so "8" was never right for the doc it pins. Precise version: "(12 items only this run can show)".

**Evidence:** `docs/working/spike-cc-verify-q117.md:664-679` (a760a5e5), `git log 22a4bb1f..d25254da -- docs/working/spike-cc-verify-q117.md`

---

## Claim 26: "rubric `docs/reviews/code-review-rubric-2026-10-15-cc-verify-spike.md` (CONDITIONAL PASS: 2 iterations, 3 narrow passes, matrix 27/27 in a stub harness)"; "residuals A17 and A18"

**Location:** `docs/working/questions.md:263,266`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the rubric's status line, its iteration table and the doc's matrix count; does not re-run the matrix.
**Legibility-target:** for-orchestrator-synthesis

`**Status: 🟡 CONDITIONAL PASS** — 2 amber item(s) awaiting resolution or justification (A17, A18)` (`d25254da:docs/reviews/code-review-rubric-2026-10-15-cc-verify-spike.md:6`); the iteration table lists iterations 1-2 and three narrow rows, "A-cap narrow pass", "A-cap pass 2" and "A16 structural fix" (:14-16). The spike doc closes its matrix with `That makes 27 cases, all ok.` (`spike-cc-verify-q117.md:660`).

**Evidence:** `docs/reviews/code-review-rubric-2026-10-15-cc-verify-spike.md:6,10-16` (d25254da), `docs/working/spike-cc-verify-q117.md:634-662` (d25254da)

---

## Claim 27: Q-171/Q-172: "Q-168 (`fix/q096b-exit-scan-remote-names`, 75d08a94, stacked on Q-096)" · "562 changed lines, over the 400 cap and under the 800 stop" · "It grew from 761 to 1,364 lines in 18 days"

**Location:** `docs/working/questions.md:293,303,317`
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers ancestry, the code-line count against Q-096's tip and the exit scan's line counts; does not establish the rubric's findings.
**Legibility-target:** for-orchestrator-synthesis

8717fd72 is an ancestor of 75d08a94; `git diff --numstat 8717fd72 75d08a94 -- . ':!docs'` sums to 562 (+483/−79). `devcontainer-config/cc-exit-scan.sh` has 761 lines at its first commit f511cc19 (2026-09-27) and 1364 at 75d08a94 (2026-10-15): 18 days (`$S/logs/refs.log`). Q-168's "3c8fbf4a, unreviewed, stacked on 013f1b3d" (:245) also holds: 013f1b3d is an ancestor of 3c8fbf4a and is Q-096's early-split commit.

**Evidence:** `docs/working/questions.md:245,293,303,317`, `$S/logs/refs.log`

---

## Claim 28: "Q-106 [2] is built (`feat/q106-host-settings-merge`, c6d7544f, built on an earlier `merge/ready-2026-10-15` commit, 184396ea; it is not in the ready branch Q-162 merges)" · "561 code lines (under 800)"

**Location:** `docs/working/questions.md:343,352`
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers ancestry and the size against its base; does not establish the test counts in the same list (Claim 35).
**Legibility-target:** for-orchestrator-synthesis

184396ea is a first-parent commit of the ready branch (`184396ea Merge branch 'chore/dev-cycle-2026-10-15-0357' into merge/ready-2026-10-15`) and an ancestor of c6d7544f; c6d7544f is not an ancestor of a760a5e5. `git diff --numstat 184396ea c6d7544f -- . ':!docs'` sums to 561 (`$S/logs/refs.log`).

**Evidence:** `docs/working/questions.md:343,352`, `$S/logs/refs.log`

---

## Claim 29: "Q-106 moved the settings merge jq into `hooks/lib/wiring-merge.jq`, which is outside `live-verify-gate.sh`'s `enforcement` regex. On main that jq is inline in `link-claude-home.sh`, which the regex covers (`hooks/live-verify-gate.sh:83`) … The trust manifest still hashes it, and both installs show it in their reviews."

**Location:** `docs/working/questions.md:369`
**Type:** Configuration / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the regex on main and on c6d7544f, where the program lives on each, and the manifest path through `claude-home`; does not establish the install review diff's display of the file.
**Legibility-target:** for-orchestrator-synthesis

`main:hooks/live-verify-gate.sh:83`: `enforcement='^devcontainer-config/(Dockerfile|devcontainer\.json|init-firewall\.sh|cc-sni-proxy\.py|link-claude-home\.sh|cc-isolated\.sh|install\.sh$|egress/)'`, unchanged at c6d7544f; `hooks/lib/wiring-merge.jq` matches none of it. On main the program is inline: `if jq --arg dir "$DEST" --slurpfile w "$WIRING" '` (`main:devcontainer-config/link-claude-home.sh:133`); at c6d7544f, `MERGE="$SRC/hooks/lib/wiring-merge.jq"` (`link-claude-home.sh:92`). The manifest covers it through `if [ -d claude-home ]; then find claude-home \( -type f -o -type l \) …` (`c6d7544f:devcontainer-config/cc-isolated.sh:149`), and `claude-home` is assembled from `CLAUDE_HOME_SRC=(… hooks scripts)` (`c6d7544f:devcontainer-config/install.sh`, PAYLOAD at :120).

**Evidence:** `hooks/live-verify-gate.sh:83`, `devcontainer-config/link-claude-home.sh:133` (main), `devcontainer-config/link-claude-home.sh:92` (c6d7544f), `devcontainer-config/cc-isolated.sh:128-151` (c6d7544f)

---

## Claim 30: Q-176: "a throwaway hook that approves only the nine test commands below and stays silent on anything else, so every other command prompts as usual"

**Location:** `docs/working/questions.md:383-399`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the hook body under `sh`, `bash` and `dash` on the nine commands and 13 near-misses, and that the settings JSON parses; does not establish Claude Code's own hook invocation or matcher (that is what the check measures), and the paste itself was not run because this session's guard refuses any Bash write naming a `.claude/settings` path.
**Legibility-target:** for-orchestrator-synthesis

```
case "$c" in
  'cat x.q092-canary'|'cat x.q092-ca""nary'|'cat x.q092-c\anary'|'rm -rf ./nothing-here'|'echo hi && rm -rf ./nothing-here'|'cat secret'|'cat "secret"'|'git push'|'git "push"')
    echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow"}}' ;;
esac
```
(`docs/working/questions.md:390-393`). `$S/test176.py` extracted lines 387-393 and 395-398 by line number, fed each command as `{"tool_input":{"command":…}}`, cwd `$S`, 2026-10-15T20:04:23Z, exit 0: the nine listed commands are approved in all three shells, with valid JSON; `cat x.q092-c\\anary`, `cat x.q092-ca"nary`, `echo hi; rm -rf ./nothing-here`, `cat 'secret'`, `git push origin`, `cat  secret`, leading or trailing spaces, empty and `ls` are silent. One residue: `$(jq …)` strips trailing newlines, so `cat secret` followed by newlines is also approved and is logged identically in `seen.log`. It is the same shell command, so the test's meaning is unchanged. The settings block parses (`json.loads`), with `"Bash(*.q092-canary*)", "Bash(rm -rf:*)", "Bash(git push:*)", "Bash(cat secret)"` (:396).

**Evidence:** `docs/working/questions.md:386-399`, `$S/test176.py`, `$S/logs/q176-hook.log`

---

## Claim 31: Q-176's test design: controls 1, 4, 6, 8 "must be denied" by their rules; "the review's MA1 names all four" spellings; "`~/q092` is its own git repository with no remote"; "the paste stops at `jq --version` without it"

**Location:** `docs/working/questions.md:383,402-413`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the mapping of each numbered test to the deny rule the entry implies, the paste's `&&` chain, and MA1's text; does not establish how Claude Code's matcher treats any spelling (the check's purpose).
**Legibility-target:** for-orchestrator-synthesis

Mapping: 1-3 target `x.q092-canary`, rule `Bash(*.q092-canary*)` (1 is the plain control; 2 and 3 hide the literal with `""` and `\a`); 4-5 `rm -rf`, rule `Bash(rm -rf:*)` (5 puts it after `&&`); 6-7 `cat secret`, rule `Bash(cat secret)`; 8-9 `git push`, rule `Bash(git push:*)` (`docs/working/questions.md:396,403-411`). The paste chains `mkdir -p ~/q092/.claude && cd ~/q092 && git init -q && jq --version && …` (:386), so a missing jq stops before the hook is written, and `git init` adds no remote. MA1 at aeda94b2: `` `cat ~/.claude/.cred""entials.json`, `.c\redentials.json`, `git "push"` and `cat "secret"` go from no output on main to `allow` at HEAD `` (`docs/reviews/independent-review-2026-10-15-q092b.md:30`).

**Evidence:** `docs/working/questions.md:383-416`, `docs/reviews/independent-review-2026-10-15-q092b.md:22-33` (aeda94b2)

---

## Claim 32: Q-177: "`fix/q092a-drop-deny-option` (d27a3891), then `fix/q092-drop-hook-deny-reader` (aeda94b2)" · "Sizes 413 + 451 lines"

**Location:** `docs/working/questions.md:421,423`
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers hashes, stacking and sizes, with U1 measured against the ready-branch commit it was built on (00a27a2f) and U2 against U1; does not establish the review results.
**Legibility-target:** for-orchestrator-synthesis

d27a3891 is an ancestor of aeda94b2. U1 sits on 00a27a2f (`git log main..d27a3891` shows `00a27a2f Merge branch 'chore/dev-cycle-2026-10-15-0357' into merge/ready-2026-10-15` under its own commits); `git diff --numstat 00a27a2f d27a3891 -- . ':!docs'` = 413 and `d27a3891 aeda94b2` = 451 (`$S/logs/refs.log`). Measured against its merge-base with main instead, U1 counts 925, because the base includes the ready branch's units.

**Evidence:** `docs/working/questions.md:421-423`, `$S/logs/refs.log`

---

## Claim 33: The generated index and entry structure ("The index below is generated — edit entries, not the table")

**Location:** `docs/working/questions.md:21-60`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `questions.sh check` (structure and index currency) at HEAD; does not establish entry content.
**Legibility-target:** for-orchestrator-synthesis

Command: `timeout 60 bash scripts/questions.sh check`, cwd `$S/clone` checked out at 2141f7ee, 2026-10-15T20:08:23Z, exit 0: `✓ questions: structure valid, indexes current` (`$S/logs/questions-check.log`).

**Evidence:** `docs/working/questions.md:21-60`, `$S/logs/questions-check.log`

---

## Claim 34: 16136a60's message: conflicts in four files "resolved by keeping both sides", with the named drops (main's open Q-089/Q-107, the branch's open Q-139/141/142/146) and "main's Q-146 item becomes 6"

**Location:** commit 16136a60 (message)
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every non-blank line either parent added relative to the merge base (b279a2ba), checked for presence in the merge, and duplicated headings or index rows; does not establish semantic ordering within the hand-merged files.
**Legibility-target:** for-orchestrator-synthesis

`git merge-tree --write-tree 16136a60^1 16136a60^2` conflicts in exactly `docs/roadmap.md`, `docs/working/idea-log.md`, `docs/working/questions-archive.md`, `docs/working/questions.md`, the four named. `$S/mergecheck.py` (cwd `$S`, 2026-10-15T20:08:10Z, exit 0) found one added line missing from the merge, main's `5. **Q-146 [1] — self-improvement.sh commits for its implementer.**`, which is the renumbering the message names (it is item 6 at `docs/roadmap.md:99`). No `### Q-`, index-row or heading line occurs more often in the merge than in either parent. The only line a side removed that survives is the generic `**Needs:** you: judgment · … · **Status:** OPEN` header shared by other entries (`$S/logs/merge-16136a60.log`, `$S/logs/merge-16136a60-v2.log`). At HEAD, questions.md has no Q-089, Q-107, Q-139, Q-141, Q-142 or Q-146 heading, and the archive holds each once.

**Evidence:** commit 16136a60, `$S/mergecheck.py`, `$S/logs/merge-16136a60.log`, `$S/logs/merge-16136a60-v2.log`

---

## Claim 35: Gate and test tallies quoted in the entries: "the slow suites passed 300/300", "290/290 in its suites", "Related suites 436/436", "13 new tests … 206/206 pass", "T93–T103 11/11, link-claude-home 16/16", "Hook suite 35/35; health check passed clean", "bats-only verification (193/193)", "old one fails and the new one passes 4/4", and the cycle record's health-check result

**Location:** `docs/working/questions.md:95-102,239,303,353,423`; `docs/working/cycles/cycle-2026-10-14.md:13`
**Type:** Configuration
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers that these are reported results of past runs on other branches; does not establish any of the counts, except Q-110's regression test (Claim 13).
**Legibility-target:** for-orchestrator-synthesis

Each tally reports a full-suite or health-check run on a unit branch, sometimes under load (paraphrased — no quote available because the claim set spans nine bullets across two files). Reproducing them needs the full slow suites (minutes each) on each of eight branches. That is outside a final confirming pass of a docs-only landing: it verifies no claim this branch introduces about its own content, and the units' own rubrics carry these runs. To verify: `scripts/health-check.sh` and `scripts/run-tests.sh` on each named tip.

**Evidence:** `docs/working/questions.md:95-102,239,303,353,423`, `docs/working/cycles/cycle-2026-10-14.md:13`

---

## Claims Requiring Attention

### Incorrect
- **Claim 25** (`docs/working/questions.md:266`): Q-169 says the spike doc's "Not verified" section has 8 items; at the pinned commit (a760a5e5 = d25254da blob) it has 12. Change "8 items" to "12 items".

### Stale
- **Claim 16** (`docs/working/questions.md:144-155`): Q-164's paste cannot merge against main now (7f711bfe: conflicts in roadmap, idea-log, questions-archive, questions) or after this landing (2141f7ee: plus override-log). Only its abort path runs. Add a "Not runnable yet" note like Q-162's, or say the loop rebuilds `merge/build-loop-u5-resolved` and `merge/u5-and-q145` first.

### Mostly Accurate
- **Claim 11** (`docs/working/questions.md:85`): "before it, in the questions, roadmap and idea-log files" omits `docs/working/questions-archive.md`, which also conflicts against current main.

### Unverifiable
- **Claim 35** (`docs/working/questions.md:95-102` and others): the unit branches' suite and gate tallies need full slow-suite runs on each named tip.

## Goal-Alignment Note

The PR's goal is to land this docs-only cycle branch with every hash, branch, paste and cross-reference accurate for the user who acts on them. The fixes the brief lists hold under execution:
- the replace-ref guard and the abort paths of Q-162 and Q-163;
- Q-162's stale-pin note, whose post-landing conflict is exactly override-log;
- Q-176's hook, which approves exactly the nine commands up to trailing newlines;
- Q-169's pinned extraction (sha256 032cc9a8…afb7, fingerprint a65f4c30ba1b8907).

The merge 16136a60 dropped and renumbered only what its message names.

Two findings bear on what the user does next. Q-164's paste, presented as option [1] "One paste", cannot succeed in either reachable state (Claim 16): it fails safe, but it is the same not-runnable condition Q-162 now discloses. Q-163's paste works on today's main but not once this branch lands, which only Q-162's "once main moves" covers.

One prose count in Q-169 is wrong (Claim 25), and one conflict-file list is short a file (Claim 11). None changes a decision or makes a paste unsafe.

Not checked by this replicate:
- Q-156's `core.attributesFile` claims on the U5 branch (Q-164 "Why it's yours");
- Q-170's DD statistics (6 fixes, 87 of 116 commits);
- Q-179 and the roadmap's Cycle 3 line, which came from main through the merge;
- the full Q-096 exit scan beyond the Q-167(c) scenario.
