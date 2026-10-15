Commit: 2141f7ee

# Code Fact-Check Report

**Repository:** claude-workflows (worktree `/workspace/.claude/wt-dev-cycle-2026-10-15-0357`, branch `chore/dev-cycle-2026-10-15-0357`)
**Scope:** `git diff main...2141f7ee` (main = 7f711bfe, which is also the merge base): `docs/working/questions.md`, `docs/roadmap.md`, `docs/working/cycles/cycle-2026-10-14.md`, `docs/working/questions-archive.md`, `docs/working/idea-log.md`, `docs/reviews/override-log.md`, and merge 16136a60. The review reports under `docs/reviews/` were not themselves fact-checked. Final confirming pass, replicate 1 of 3.
**Checked:** 2026-10-15
**Total claims checked:** 30
**Summary:** 24 verified, 3 mostly accurate, 1 stale, 0 incorrect, 2 unverifiable

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`). The relevant family is "a count stated in prose that the artifact no longer has" (e.g. "mode1-equiv 33 claimed … holds 25", first seen in that log). Claim 21 matches it.

Execution environment for every `executed` claim: git 2.39.5, jq 1.6, zsh at `/usr/bin/zsh`, `/bin/sh` = dash. All pastes ran in a throwaway clone `/tmp/claude-1000/-workspace/b1fde0b4-befb-4424-9add-ef12273f2f26/scratchpad/final-fc-1/repo` (all branches fetched from `/workspace`) or under a fake HOME in the same scratch directory. Nothing ran against `/workspace` itself. Each command ran under `timeout`, and no process was left running (`ps` check, 0 matches). Captured outputs are in `/tmp/claude-1000/-workspace/b1fde0b4-befb-4424-9add-ef12273f2f26/scratchpad/final-fc-1/`: `q162-runs.log`, `q163-164-runs.log`, `q176-hook.log`, `q176-mainvsbranch.log`, `q167b.log`, `static-exec.log`, `mergecheck.log`.

---

## Claim 1: "User-routed questions grow from 2 to 15 (`you: judgment` 1 to 10) … tech-debt-triage F2" / "… five vs seven units, "Next 3", 22a4bb1f vs d25254da, Q-106 "on" the ready branch … tech-debt-triage F3"

**Location:** `docs/reviews/override-log.md:828-829`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that both rows restate the tech-debt report's F2 and F3 (severity, counts, chains, the four drifted strings) and that each F3 string is corrected at HEAD; does not establish that the Defer decisions are right.

The tech-debt report gives F2 as Medium, with the table `| you: judgment | 1 | 10 |` and `| you: terminal | 1 | 5 |` (`docs/reviews/tech-debt-triage-review-2026-10-15-0357.md:48-51`). That is 2 user-routed entries on main and 15 at HEAD, as the row says. The chains it quotes (Q-166/Q-167/Q-169 on Q-165 and Q-162, `Waits on Q-172`, `When Q-176 is answered`, `:54-57`) are the four orderings the row lists. F3 is `**Severity:** Low` (`:75`), and its four strings (`:79-82`) are the row's "five vs seven units, "Next 3", 22a4bb1f vs d25254da, Q-106 "on"". At HEAD each one is corrected: Q-162 reads "plus seven reviewed units" (`docs/working/questions.md:83`), Q-165 reads "(roadmap Now, "Verify a branch without installing it" …)" (`:166`), Q-174 reads "built on an earlier `merge/ready-2026-10-15` commit, 184396ea" (`:343`), and the roadmap reads "tip d25254da" (`docs/roadmap.md:52`). The index at HEAD has 10 `you: judgment` rows and 5 `you: terminal` rows (paraphrased — no quote available because this is a count over the generated index table, `docs/working/questions.md:25-60`).

**Evidence:** `docs/reviews/override-log.md:828-829`, `docs/reviews/tech-debt-triage-review-2026-10-15-0357.md:43-88`, `docs/working/questions.md:25-60,83,166,343`, `docs/roadmap.md:52`

---

## Claim 2: Roadmap Now's branch names and hashes (`fix/t69-stage-race`, 4ee81106 … `fix/q092-drop-hook-deny-reader` aeda94b2, `docs/branch-verify-without-install` tip d25254da)

**Location:** `docs/roadmap.md:12-56`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that every branch named in Now exists, that every hash it gives is that branch's current tip, and that none is merged into main 7f711bfe; does not establish the review outcomes described in prose ("loop closed", "independent closing review was clean").

For each pair (branch, hash) named in Now and in Q-160..Q-177, I resolved `refs/heads/<branch>`, compared it with the hash, and ran `git merge-base --is-ancestor <hash> main`. All 18 returned `tipeq=Y inbr=yes inmain=no`. These are t69 4ee81106, q110 f5b7e49d, doc-drift c8e87a69, q160 4a44d2f3, q096 8717fd72, rebuild-hint 47da5a4b, one-workspace f6f37fad, q145 c035f2e7, u5 7c91b974, merge/u5-and-q145 a04d9776, merge/build-loop-u5-resolved 0f94bb77, merge/ready a760a5e5, branch-verify d25254da, dd-015 f050b487, q096b 75d08a94, q106 c6d7544f, q092a d27a3891 and q092b aeda94b2 (paraphrased — no quote available because this is the output of an 18-row shell loop, run 2026-10-15T20:0xZ in `/workspace/.claude/wt-dev-cycle-2026-10-15-0357`, exit 0). The roadmap's statement that rebuild-hint and one-workspace were "Next 3" holds historically: Next 3 reads "The launcher's rebuild hint misleads…" at 7550465b, and "Reject a second workspace argument" at 3356974b.

**Evidence:** `docs/roadmap.md:12-56`; `/tmp/claude-1000/-workspace/b1fde0b4-befb-4424-9add-ef12273f2f26/scratchpad/final-fc-1/static-exec.log`

---

## Claim 3: "Cycle 2 (2026-10-14): 42 multi-file landings; 25/42 carry the line, 38/42 committed a rubric, 4/42 have neither (df18413a, 0fbf9742, b8807e76, 52053432). About 36 are units of the one build-loop plan."

**Location:** `docs/roadmap.md:77-79` (repeated at `docs/working/cycles/cycle-2026-10-14.md:55`)
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the four counts and the four hashes under one reading: main at b279a2ba, first-parent merges with committer date ≥ 2026-10-02, cycle 1's three merges excluded, more than one file changed, "rubric" meaning a `docs/reviews/code-review-rubric*` file added or modified. Does not establish that this is the reading the cycle used. Under a stricter added-only rubric rule, 6cf869d7 joins "neither".

Command (bash, cwd `…/final-fc-1/repo`, 2026-10-15T20:11Z, exit 0): first-parent merges of b279a2ba dated ≥ 2026-10-02, skipping cac2ba0c, 188e0a7d and 90364c73 (cycle 1's three). For each, it greps the body for `← carried from RPI` and the A|M name list for `^docs/reviews/code-review-rubric`. Output: `merges=42 line=25 rubric=38 neither=[ df18413a 0fbf9742 b8807e76 52053432]`. Of the 42, 36 have `build-loop` in the subject. Without the cycle-1 exclusion the count is 45, which is the Cycle 3 figure already on main. With an added-only rubric rule, 6cf869d7 becomes a fifth "neither": it only modifies `code-review-rubric-2026-10-08-feat-build-loop-u2b1a.md`.

**Evidence:** `docs/roadmap.md:77-79`; `/tmp/claude-1000/-workspace/b1fde0b4-befb-4424-9add-ef12273f2f26/scratchpad/final-fc-1/static-exec.log` (last line)

---

## Claim 4: "The seven source paths are in `install.sh:135`, and a second copy of the names, with no parity test, is in `link-claude-home.sh:50`."

**Location:** `docs/roadmap.md:117-119`
**Type:** Reference / Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the two line references and the count of seven at main 7f711bfe and at HEAD; does not establish that no test compares the two lists anywhere outside `test/`.

```bash
# devcontainer-config/install.sh:135 (main and 2141f7ee)
CLAUDE_HOME_SRC=(global-instructions/CLAUDE.md skills workflows guides patterns hooks scripts)
# devcontainer-config/link-claude-home.sh:50
ENTRIES=(skills workflows guides patterns hooks scripts CLAUDE.md)
```

The only tests on either array are a grep of `CLAUDE_HOME_SRC=` (`test/cc-isolated-functions.bats:598`) and a pin of `scripts` (`test/link-claude-home-wiring.bats:307`, `grep -qE '^CLAUDE_HOME_SRC=\(.* scripts( |\))'`). No test checks that the two lists match.

**Evidence:** `devcontainer-config/install.sh:135`, `devcontainer-config/link-claude-home.sh:50`, `test/link-claude-home-wiring.bats:296-307`, `test/cc-isolated-functions.bats:598`

---

## Claim 5: "units grew from 102 to 842, 157 to 603, 217 to 538 and 392 to 570 code lines during review"

**Location:** `docs/working/cycles/cycle-2026-10-14.md:52` (and Q-160, `docs/working/questions.md:437`)
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the four final sizes and their merges (581d41d8, 73589cd7, dfa75374, 626dc300) as `git diff --shortstat <merge>^1 <merge> -- . ':(exclude)docs/'`; does not establish the four starting sizes (102, 157, 217, 392).

Output (cwd `…/final-fc-1/repo`, 2026-10-15T20:11Z, exit 0): `581d41d8 … 759 insertions(+), 83 deletions(-)` is 842; `73589cd7 … 527 (+), 76 (-)` is 603; `dfa75374 … 431 (+), 107 (-)` is 538; and `626dc300 … 546 (+), 24 (-)` is 570.

**Evidence:** `docs/working/cycles/cycle-2026-10-14.md:52`; `/tmp/claude-1000/-workspace/b1fde0b4-befb-4424-9add-ef12273f2f26/scratchpad/final-fc-1/static-exec.log` ("log row 62 merges")

---

## Claim 6: "`CLAUDE_HOME_SRC` and `assemble()` are still in `devcontainer-config/install.sh` (:135, :329-362; callers :498 and :858)"

**Location:** `docs/working/questions-archive.md:2738`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the line numbers at main 7f711bfe and HEAD (install.sh is identical in both); does not establish them for the ready branch a760a5e5, which edits install.sh.

```bash
# devcontainer-config/install.sh:329 … :362-363
assemble() {
}
# :498
  assemble "$stage/claude-home" "${dc_paths[@]}"
# :858
  assemble "$stage"
```

The question text the archived entry keeps verbatim still says "lines 498 and 857". The resolution added on this branch says :858, which is correct.

**Evidence:** `devcontainer-config/install.sh:135,329-362,498,858`

---

## Claim 7: Q-162: "That branch is main (as of b279a2ba) plus seven reviewed units … each merged with `--no-ff`", "The tip, a760a5e5, adds after that gate [3fe6d6e3] the rebuild-hint and one-workspace unit merges …, two docs-branch merges and nine cycle-record merges", "deletes the twelve build-loop branches already merged into main, along with their worktrees"

**Location:** `docs/working/questions.md:83,102`
**Type:** Architectural / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the first-parent structure of b279a2ba..a760a5e5, which units it does and does not hold, and that the twelve `feat/build-loop-u3a1…u4c` branches are merged into main with clean registered worktrees; does not establish the gate results quoted (983, 300/300).

`git log --first-parent b279a2ba..a760a5e5` shows 19 merges with parent-1 chained from b279a2ba. They are 7 unit merges (t69, q110, doc-drift, q160, q096, rebuild-hint, one-workspace), 2 docs merges (branch-verify d25254da, dd-015 f050b487) and 10 `chore/dev-cycle-2026-10-15-0357` merges, 9 of them after 3fe6d6e3 (paraphrased — no quote available because this is a 19-line log summarized by category). q145, u5, q096b and q092a are not ancestors of a760a5e5. All 12 build-loop branches are `--merged main`, and each `/workspace/.claude/wt-build-loop-<u>` worktree has 0 `status --porcelain` lines.

**Evidence:** `docs/working/questions.md:83,102`; `/tmp/claude-1000/-workspace/b1fde0b4-befb-4424-9add-ef12273f2f26/scratchpad/final-fc-1/q162-runs.log` (scenario C deletes all 12)

---

## Claim 8: "It exists because every pair of these units conflicts only in the append-only `docs/reviews/override-log.md`"

**Location:** `docs/working/questions.md:83`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the pairwise `merge-tree` results of the five independently built units (t69, q110, doc-drift, q160, q096); does not establish the pairs involving rebuild-hint and one-workspace, which were built on the ready branch and so have no independent pairing.

The conclusion holds: no pair conflicts anywhere except `override-log.md`. "Every pair conflicts" does not hold. Only 3 of the 10 pairs conflict at all:

```
# static-exec.log, "pairwise unit merge-tree" (cwd …/final-fc-1/repo, 2026-10-15T20:11Z)
t69xq110: []   t69xdrift: []   t69xq160: []   t69xq096: []
q110xdrift: [docs/reviews/override-log.md ]   q110xq160: [docs/reviews/override-log.md ]
q110xq096: []  driftxq160: [docs/reviews/override-log.md ]  driftxq096: []  q160xq096: []
```

A precise version: "the units that conflict (Q-110, doc drift and Q-160, pairwise) do so only in the append-only `docs/reviews/override-log.md`."

**Evidence:** `docs/working/questions.md:83`; `/tmp/claude-1000/-workspace/b1fde0b4-befb-4424-9add-ef12273f2f26/scratchpad/final-fc-1/static-exec.log`

---

## Claim 9: "**Not runnable yet (2026-10-15):** … After Q-178's landing of the 0357 cycle branch, merging a760a5e5 conflicts in `docs/reviews/override-log.md` (and, before it, in the questions, roadmap and idea-log files), so the paste below aborts and deletes nothing."

**Location:** `docs/working/questions.md:85`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers `git merge-tree --write-tree` of a760a5e5 against main 7f711bfe and against HEAD 2141f7ee, and the paste's abort in both states; does not establish the conflict set against whatever main is when the user actually pastes.

Command: `git merge-tree --write-tree --name-only <base> a760a5e5` (cwd `…/final-fc-1/repo`, 2026-10-15T20:11Z, exit 1 both times).
- Against HEAD 2141f7ee (main after this branch lands), it conflicts in `docs/reviews/override-log.md` alone. That matches the claim.
- Against main 7f711bfe ("before it"), it conflicts in `docs/roadmap.md`, `docs/working/idea-log.md`, `docs/working/questions-archive.md` and `docs/working/questions.md`. The parenthetical omits `questions-archive.md`.

The stated reason, that main moved past the pin, is accurate. Executing the paste in both states printed `conflict: merge aborted, nothing deleted` and exited 1 with HEAD unchanged, 12 branches and 12 worktrees intact (Claim 10). Precise version: "(and, before it, in the questions, questions-archive, roadmap and idea-log files)".

**Evidence:** `docs/working/questions.md:85`; `/tmp/claude-1000/-workspace/b1fde0b4-befb-4424-9add-ef12273f2f26/scratchpad/final-fc-1/static-exec.log`, `/tmp/claude-1000/-workspace/b1fde0b4-befb-4424-9add-ef12273f2f26/scratchpad/final-fc-1/q162-runs.log`

---

## Claim 10: Q-162's paste: it merges by hash "once the paste has checked that no replace refs exist", aborts on conflict with nothing deleted, and on success deletes the twelve branches and their worktrees

**Location:** `docs/working/questions.md:87-92`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the four paths (replace ref present, conflict against HEAD, conflict against current main, clean merge on b279a2ba) run under zsh in a clone with `cd /workspace` rewritten to the clone; does not establish behavior when a worktree is dirty (that iteration's `git branch -d` is skipped and the loop continues).

```
# docs/working/questions.md:88-91
{ test -z "$(git for-each-ref refs/replace/)" || { echo "replace refs present: stop"; false; }; } && \
{ git merge --no-ff a760a5e5… -m "…" || { git merge --abort; echo "conflict: merge aborted, nothing deleted"; false; }; } && \
for u in u3a1 … u4c; do git worktree remove .claude/wt-build-loop-$u && git branch -d feat/build-loop-$u; done
```

Each run was `timeout 120 zsh q162-local.sh` (cwd `…/final-fc-1/repo`, 2026-10-15T20:02:20-21Z):
- **A**, main=2141f7ee: override-log conflict, `conflict: merge aborted, nothing deleted`, `exit=1`, 12 branches and 12 worktrees intact.
- **B**, main=7f711bfe: 4-file conflict, same message, `exit=1`, nothing deleted.
- **D**, `git replace 7f711bfe b279a2ba`: `replace refs present: stop`, `exit=1`, no merge.
- **C**, main=b279a2ba: `Merge made by the 'ort' strategy`, then 12 `Deleted branch feat/build-loop-…` lines, `exit=0`, 0 worktrees left.

**Evidence:** `docs/working/questions.md:87-92`; `/tmp/claude-1000/-workspace/b1fde0b4-befb-4424-9add-ef12273f2f26/scratchpad/final-fc-1/q162-runs.log`

---

## Claim 11: "`fix/q110-not-run-undercount` (f5b7e49d): the runner unsets `RUN_TESTS_NOT_RUN_FILE` after writing it."

**Location:** `docs/working/questions.md:96`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the write and the unset, and that bats is invoked after the unset at f5b7e49d; does not establish the regression test's red/green claim.

```bash
# scripts/run-tests.sh:360-369 at f5b7e49d
if [[ -n "${RUN_TESTS_NOT_RUN_FILE:-}" ]]; then
  echo "${#not_run[@]}" > "$RUN_TESTS_NOT_RUN_FILE"
fi
# …comment :363-368…
unset RUN_TESTS_NOT_RUN_FILE
```

The `bats_args=()` construction and the bats invocation follow at :416 onward, so the unset happens before bats runs.

**Evidence:** `scripts/run-tests.sh:19-23,360-369,416-420` (at f5b7e49d)

---

## Claim 12: Unit sizes: doc drift "6 files, +26/−10"; Q-160 "43 code lines"; Q-096 "399 lines"; rebuild-hint "131 code lines"; one-workspace "260 code lines"; U5 "26 code lines outside `docs/`, 409 lines outside `docs/reviews/`"; Q-168 "562 changed lines"; Q-106 "561 code lines"; Q-092 "413 + 451 lines"

**Location:** `docs/working/questions.md:97-101,141,300,357,426`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each size as `git diff --shortstat <base> <tip>`, excluding `docs/` (or `docs/reviews/` where the entry says so), from each unit's own base. The bases are b279a2ba for units built on main. For the stacked units they are the ready-branch commit each was built on (9660d4f6, 5e6e9266, 00a27a2f, 184396ea) or the unit it is stacked on (8717fd72, d27a3891). Does not establish which measuring command each review loop used.

From `static-exec.log` (cwd `…/final-fc-1/repo`, 2026-10-15T20:11Z, exit 0):
- doc drift: `6 files changed, 26 insertions(+), 10 deletions(-)`.
- Q-160: 31+12 = 43.
- Q-096: 355+44 = 399.
- rebuild-hint: 108+23 = 131.
- one-workspace: 220+40 = 260.
- U5: 21+5 = 26 outside `docs/`, and 371+38 = 409 outside `docs/reviews/`.
- Q-168: 483+79 = 562.
- Q-106: 460+101 = 561.
- Q-092a: 167+246 = 413.
- Q-092b: 152+299 = 451.

**Evidence:** `/tmp/claude-1000/-workspace/b1fde0b4-befb-4424-9add-ef12273f2f26/scratchpad/final-fc-1/static-exec.log`

---

## Claim 13: Q-163 and Q-164 pastes: each picks the combined `merge/u5-and-q145` (a04d9776) only if the other unit is already on main, merges by hash behind the replace-ref guard, and on a conflict "merge aborted; the loop rebuilds this entry's branch"; Q-162: "Their pastes abort on a conflict"

**Location:** `docs/working/questions.md:113-120,144-151,83`
**Type:** Error-handling / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers branch selection and abort at main = 2141f7ee, 7f711bfe and b279a2ba, plus the contents of a04d9776 and 0f94bb77. Does not establish the a04d9776 arm by execution (the other unit was never on main in these runs). It also notes that on abort these two pastes exit 0, unlike Q-162's.

```
# docs/working/questions.md:117-118 (Q-163)
if git merge-base --is-ancestor 7c91b974… HEAD; then B=a04d9776…; else B=c035f2e7…; fi && \
{ git merge --no-ff "$B" -m "…" || { git merge --abort; echo "conflict: merge aborted; the loop rebuilds this entry's branch against main"; }; }
```

From `q163-164-runs.log` (zsh -x, cwd `…/final-fc-1/repo`, 2026-10-15T20:10:07-08Z):
- At 2141f7ee, Q-163 picked `B=c035f2e7…` and conflicted in override-log. Q-164 picked `B=0f94bb77…` and conflicted in override-log, roadmap, questions-archive and questions. Both aborted, leaving HEAD 2141f7ee and 0 dirty files.
- At 7f711bfe, Q-163 merged cleanly. Q-164 aborted on a 4-file conflict.
- At b279a2ba, both merged cleanly.

a04d9776's first parent is 0f94bb77 and its second is c035f2e7, and 0f94bb77 contains 7c91b974 and f5b7e49d. That matches "both units" and "U5's reviewed tip is unchanged inside it". The abort branch has no trailing `false`, so the paste ends with status 0 after printing the message. The entry does not claim a status.

**Evidence:** `docs/working/questions.md:113-120,144-151`; `/tmp/claude-1000/-workspace/b1fde0b4-befb-4424-9add-ef12273f2f26/scratchpad/final-fc-1/q163-164-runs.log`

---

## Claim 14: Cross-references to Q-149..Q-156 (Q-163 "Q-156, filed on `feat/build-loop-u5`"; Q-164 "files Q-149..Q-156", "Q-149 asks how wide", "Blocks: Q-156 …, Q-155")

**Location:** `docs/working/questions.md:124,140,153`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the existence of every Q-id cited in this branch's added lines in HEAD's questions or archive file, or on a named branch; does not establish the content of the U5-only entries.

Every Q-id cited in the added lines of the six docs was looked up as a `### Q-NNN ` heading in HEAD's `questions.md` and `questions-archive.md`. 53 IDs resolve. Q-149, Q-155 and Q-156 exist only on `feat/build-loop-u5`, `merge/build-loop-u5-resolved` and `merge/u5-and-q145`, which is how Q-163 and Q-164 describe them ("filed on `feat/build-loop-u5`; it reaches main with Q-164"; "files Q-149..Q-156") (paraphrased — no quote available because this is the output of a per-ID lookup loop over all refs). No added line calls an archived entry open. Q-110, Q-108 and Q-125, which are described as open, are open at HEAD. Q-089 and Q-107 are archived at HEAD and are described as answered.

**Evidence:** `docs/working/questions.md:124,140,153`; per-ID loop over `git for-each-ref refs/heads` (cwd `…/final-fc-1/repo`)

---

## Claim 15: Q-165: "`docs/working/research-branch-verify-without-install.md` and `docs/working/dd-branch-verify-without-install.md` on `docs/branch-verify-without-install` (22a4bb1f; the branch tip, d25254da, adds the spike doc and its review commits)"

**Location:** `docs/working/questions.md:169`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that both docs exist at 22a4bb1f, that the spike doc does not, and that 22a4bb1f is an ancestor of the tip d25254da; does not establish the research findings summarized in the bullets.

`git cat-file -e` succeeds for `22a4bb1f:docs/working/dd-branch-verify-without-install.md` and `d25254da:docs/working/research-branch-verify-without-install.md`, and fails for `22a4bb1f:docs/working/spike-cc-verify-q117.md`. `git merge-base --is-ancestor 22a4bb1f d25254da` succeeds, and 22a4bb1f's subject is `docs: research and DD for verifying a branch without installing it on the host`.

**Evidence:** `docs/working/questions.md:169`

---

## Claim 16: Q-166 [1]: "For Q-125 that difference is real: a staged run never executes its `install.sh` `PAYLOAD` or `cc-isolated.sh` `enforcement_files()` changes (Q-117 changes only `init-firewall.sh`)"

**Location:** `docs/working/questions.md:196`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers what Q-125 changes in install.sh and cc-isolated.sh, that Q-117's only code file is init-firewall.sh, and that the spike runs main's installed launcher; does not establish every other config path a staged run skips.

Q-125 (`feat/q125-cc-isolated-sandbox` at 2961ca2f, against its merge base with main) changes the payload list and adds three lines to `enforcement_files()`:

```
-PAYLOAD=(devcontainer.json Dockerfile init-firewall.sh … egress claude-home)
+PAYLOAD=(devcontainer.json Dockerfile seccomp-cc-sandbox.json managed-settings.json cc-sandbox-settings.sh init-firewall.sh …)
+  echo "seccomp-cc-sandbox.json"
+  echo "managed-settings.json"
+  echo "cc-sandbox-settings.sh"
```

`fix/egress-dnsmasq-ipset` (b26d4b8b) changes `devcontainer-config/init-firewall.sh`, `docs/…` and `test/init-firewall-rules.bats` only. The spike's block runs `LAUNCHER="$MAIN_CFG/cc-isolated.sh"` with `MAIN_CFG="$HOME/.config/claude-devcontainer"` (spike block lines 23-26), so a staged run uses main's `enforcement_files()`, never the branch's.

**Evidence:** `docs/working/questions.md:196`; `devcontainer-config/install.sh`, `devcontainer-config/cc-isolated.sh` at 2961ca2f; `docs/working/spike-cc-verify-q117.md:72-75` at a760a5e5

---

## Claim 17: Q-167 (a): "the install's bless output should show `Verified live:  NO — a bless is a review, not a test.` followed by `Next: cc-isolated --probe-only <repo>` alone on its line, and `cc-isolated --list` should show `Blessed config <hash> — verified live: NO (run: cc-isolated --probe-only <repo>)`"

**Location:** `docs/working/questions.md:208`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the echo text in a760a5e5's cc-isolated.sh, and that install.sh's bless calls it. Does not establish the live probe. Nor does it establish that these lines show the rebuild-hint change itself: the changed text is in `rebuild_hint()`, which a passing install does not print.

```bash
# devcontainer-config/cc-isolated.sh:327-329 at a760a5e5
  else
    echo "Verified live:  NO — a bless is a review, not a test. Nothing has run this config."
    echo "  Next: cc-isolated --probe-only <repo>"
# :501
      echo "Blessed config $b — verified live: NO (run: cc-isolated --probe-only <repo>)"
```

The quoted "Verified live" text is a prefix. The real line continues "Nothing has run this config." On main the Next line still carries `   # rebuilds from it and probes as node` (main `cc-isolated.sh:316`), so "alone on its line" tells main's output apart from the branch's. install.sh's bless is `CLAUDE_DEVC_CONFIG_DIR="$DEST" "$DEST/cc-isolated.sh" --bless` (`install.sh:607` at a760a5e5).

**Evidence:** `devcontainer-config/cc-isolated.sh:324-331,497-502` (a760a5e5), `devcontainer-config/cc-isolated.sh:315-316` (main), `devcontainer-config/install.sh:607` (a760a5e5)

---

## Claim 18: Q-167 (b): "Paste these lines as written in default zsh; each of the first three must print an ERROR and `exit=2` with nothing done"

**Location:** `docs/working/questions.md:216-223`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the first three lines, run as the argv default (non-`interactive_comments`) zsh would pass, against a760a5e5's cc-isolated.sh. Does not establish the fourth line's probe, which needs docker and a host.

Command: `bash probe-q167b.sh`, which runs `bash cfg167/cc-isolated.sh <argv>` with a fake HOME and `CLAUDE_DEVC_CONFIG_DIR`, and `docker`/`devcontainer` stubs that exit 99 and log any call (cwd scratch, 2026-10-15T20:05:27Z, exit 0). Results:
- argv `~/code/a ~/code/b` gave `ERROR: two workspaces given: … cc-isolated takes one.` and `exit=2`.
- argv `--list # registered projects` gave `ERROR: \# is not a workspace; it looks like a pasted comment.` and `exit=2`.
- argv `--profile # --bless` gave `ERROR: \# is not an egress profile; …` and `exit=2`.

No stub was called, and the config dir held only `cc-isolated.sh` afterwards.

**Evidence:** `docs/working/questions.md:216-223`; `/tmp/claude-1000/-workspace/b1fde0b4-befb-4424-9add-ef12273f2f26/scratchpad/final-fc-1/q167b.log`

---

## Claim 19: Q-167 (c): "a planted pre-receive hook in a repository that a remote is rewritten to must be caught … (expect 3, naming hook …/mirror-repo/hooks/pre-receive)"

**Location:** `docs/working/questions.md:227-237`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers only that the paste's rewrite `url.$T/proj/mirror-.insteadOf https://example.invalid/` maps remote `o` (`https://example.invalid/repo`) to `$T/proj/mirror-repo`, the bare repo the step-2 command plants into. Does not establish the exit-3 verdict, which needs a cc-isolated session on the host.

It is an executable guarantee that needs host docker and a cc-isolated container, which this sandbox cannot run. Reading the paste: the prefix rewrite turns `https://example.invalid/repo` into `$T/proj/mirror-repo`, and step 2 writes `mirror-repo/hooks/pre-receive` relative to the session's workspace, which is `$T/proj` (paraphrased — no quote available because this is the composition of the two pastes at `:229` and `:235`). What would verify it: the host run itself.

**Evidence:** `docs/working/questions.md:227-237`

---

## Claim 20: Q-169: "the single ```bash block in `docs/working/spike-cc-verify-q117.md` (498 lines with its fences) … The hash must be `032cc9a8…afb7` … Its first output line must be `script sha256 a65f4c30ba1b8907`"

**Location:** `docs/working/questions.md:256-260`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the extraction command's output hash from a760a5e5 (also equal at d25254da), the line count, the self-hash line, and that no other line prints first on a normal start. Does not establish durability: if the next cycle rebuilds `merge/ready-2026-10-15` as Q-162 says, a760a5e5 becomes unreachable and is gc-eligible, and the extraction then fails closed, with an empty file and the wrong hash.

Command (cwd `…/final-fc-1/repo`, 2026-10-15T20:03Z, exit 0): `git -c core.useReplaceRefs=false show a760a5e5…:docs/working/spike-cc-verify-q117.md | awk '/^```bash$/{f=1;next} f&&/^```$/{exit} f' > …/home/cc-verify/q117-spike.txt && sha256sum …` printed `032cc9a81e4e1c9266ec3ad3b5fe7053d9876eb21f5ffa7f0a35f2ccfed4afb7`. The file has 496 lines, and the fences sit at doc lines 49 and 546, so 498 lines with its fences. Running the block with two arguments printed `   script sha256 a65f4c30ba1b8907`, then `REFUSED: usage: …`, then exit; no `~/cc-verify` was created. The source line is:

```bash
# spike block :296 (doc line 345)
[ -n "${BASH_EXECUTION_STRING:-}" ] && echo "   script sha256 $(printf '%s' "$BASH_EXECUTION_STRING" | sha256sum | cut -c1-16)"
```

Nothing before it echoes on a non-`--clean` start (`:1-295` are definitions, plus the `--clean` branch at `:268-292`). The block's last line is `)" spike-q117 ~/claude-workflows`, which matches "editing only its last line, the checkout path".

**Evidence:** `docs/working/questions.md:256-260`; `docs/working/spike-cc-verify-q117.md:49,296-345,546` (a760a5e5); `/tmp/claude-1000/-workspace/b1fde0b4-befb-4424-9add-ef12273f2f26/scratchpad/final-fc-1/static-exec.log` ("Q-169 extraction")

---

## Claim 21: Q-169 Read: ""Not verified" (8 items only this run can show)"

**Location:** `docs/working/questions.md:266`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the numbered-item count of the doc's `## Not verified (needs the host run)` section at the pinned commit and at each earlier commit of the doc; does not establish which items are strictly "only this run can show".

At a760a5e5 and d25254da the section lists 12 numbered items, from `1. **Image naming**` to `12. **The build's network, time and cache.**` (`docs/working/spike-cc-verify-q117.md:664-679`). Per-commit counts (cwd `…/final-fc-1/repo`): 12fcb61c has 7, 190fa1a4 has 8, and 53770142 through d25254da have 12. The "8" matches 190fa1a4, the iteration-2 commit. The section grew to 12 after it. Matches the prior hallucination-pattern family of prose counts that no longer match the artifact. Precise version: "(12 items only this run can show)".

**Evidence:** `docs/working/spike-cc-verify-q117.md:664-679` (a760a5e5); `/tmp/claude-1000/-workspace/b1fde0b4-befb-4424-9add-ef12273f2f26/scratchpad/final-fc-1/static-exec.log`

---

## Claim 22: Q-169 Read: "rubric `docs/reviews/code-review-rubric-2026-10-15-cc-verify-spike.md` (CONDITIONAL PASS: 2 iterations, 3 narrow passes, matrix 27/27 in a stub harness)"

**Location:** `docs/working/questions.md:266`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the rubric's status line and pass rows, and the doc's matrix total; does not establish that the matrix cases are adequate.

The rubric at a760a5e5 reads `**Status: 🟡 CONDITIONAL PASS** — 2 amber item(s) awaiting resolution or justification (A17, A18)` (`:6`), with iterations 1-2 and three narrow rows: "A-cap narrow pass", "A-cap pass 2 (one narrow check on the non-trivial fix)" and "A16 structural fix … one narrow security check" (`:14-16`). The spike doc says `That makes 27 cases, all ok.` (`spike-cc-verify-q117.md:661`). The rubric's own A-cap row says "matrix 25/25" for an earlier point (`:55`), so 27/27 is the doc's final figure.

**Evidence:** `docs/reviews/code-review-rubric-2026-10-15-cc-verify-spike.md:6,10-16,55` (a760a5e5), `docs/working/spike-cc-verify-q117.md:647-661` (a760a5e5)

---

## Claim 23: Q-170: "since 2026-09-09 87 of 116 `devcontainer-config/` commits carry `Live-verified: no`"

**Location:** `docs/working/questions.md:276`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers a recount at the DD's own commit f050b487 with `git log --no-merges --since=2026-09-09 -- devcontainer-config/`; does not establish how the DD classified the commit or commits that differ.

The total matches. The trailer count is one higher than claimed:

```
# recount (cwd …/final-fc-1/repo, 2026-10-15T20:09Z, exit 0)
f050b487 total=116 lvno=88   (anchored '^Live-verified: no' = 88; case-insensitive anywhere = 88; hash trailer = 1, 6c35e39d)
```

The DD doc itself says "87 carry `Live-verified: no` and 1 carries a hash … the other 28 carry neither" (`dd-015-step4-isolation-mechanism.md:34`). With 88, the remainder is 27. The conclusion (the large majority unverified) is unaffected. Precise version: "88 of 116", or name the DD's counting rule.

**Evidence:** `docs/working/questions.md:276`; `docs/working/dd-015-step4-isolation-mechanism.md:34` (f050b487)

---

## Claim 24: Q-172: "It grew from 761 to 1,364 lines in 18 days."

**Location:** `docs/working/questions.md:317`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers `wc -l` of `devcontainer-config/cc-exit-scan.sh` at its creating commit and at Q-168's tip; does not establish the "every review pass found new families" history.

`f511cc19 2026-09-27 761` (`--diff-filter=A`, the file's creation) and `75d08a94 2026-10-15 1364`, 18 days apart (static-exec.log, "exit-scan size").

**Evidence:** `/tmp/claude-1000/-workspace/b1fde0b4-befb-4424-9add-ef12273f2f26/scratchpad/final-fc-1/static-exec.log`

---

## Claim 25: Q-174: "`feat/q106-host-settings-merge`, c6d7544f, built on an earlier `merge/ready-2026-10-15` commit, 184396ea; it is not in the ready branch Q-162 merges"

**Location:** `docs/working/questions.md:343`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers ancestry; does not establish the review findings (S3-F1) or the test tallies.

`git merge-base --is-ancestor 184396ea c6d7544f` succeeds, and so does `184396ea a760a5e5` (184396ea is a first-parent commit of the ready branch). `c6d7544f a760a5e5` fails ("q106 NOT in ready").

**Evidence:** `docs/working/questions.md:343`

---

## Claim 26: Q-175: "On main that jq is inline in `link-claude-home.sh`, which the regex covers (`hooks/live-verify-gate.sh:83`), so the move takes away coverage the program has today. The trust manifest still hashes it"

**Location:** `docs/working/questions.md:369`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the regex at main :83, the inline jq on main, its move at c6d7544f, and the manifest path. Does not establish that `live-verify-gate.sh` checks every commit path (see the roadmap Idea on `git commit <path>`/`-o`/`-i`).

```bash
# hooks/live-verify-gate.sh:83 (main 7f711bfe)
enforcement='^devcontainer-config/(Dockerfile|devcontainer\.json|init-firewall\.sh|cc-sni-proxy\.py|link-claude-home\.sh|cc-isolated\.sh|install\.sh$|egress/)'
# devcontainer-config/link-claude-home.sh:133 (main)
    if jq --arg dir "$DEST" --slurpfile w "$WIRING" '
# devcontainer-config/link-claude-home.sh:92,115 (c6d7544f)
MERGE="$SRC/hooks/lib/wiring-merge.jq"
    if env -i PATH="$PATH" HOME=/nonexistent jq --arg dir "$DEST" --slurpfile w "$WIRING" -f "$MERGE" \
```

`hooks/lib/wiring-merge.jq` is not under `devcontainer-config/`, so the regex cannot match it. Manifest: `enforcement_files()` lists `find claude-home \( -type f -o -type l \)` (`cc-isolated.sh` at c6d7544f), and `hooks` is in `CLAUDE_HOME_SRC` (`install.sh:145` at c6d7544f), so the jq file is hashed. The cited F6 does recommend "Consider making [2] the interim" (`security-review-2026-10-15-0357.md:188`), which matches "leans to [2]".

**Evidence:** `hooks/live-verify-gate.sh:83`, `devcontainer-config/link-claude-home.sh:133` (main), `devcontainer-config/link-claude-home.sh:92,115` and `devcontainer-config/install.sh:145` (c6d7544f), `docs/reviews/security-review-2026-10-15-0357.md:163-188`

---

## Claim 27: Q-176: "Main's hook stays silent on `.cred""entials.json`, `.c\redentials.json`, `git "push"` and `cat "secret"`; the branch's hook approves them (the review's MA1 names all four …)"

**Location:** `docs/working/questions.md:383`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers main's and aeda94b2's `hooks/auto-approve-allowed-commands.sh` with one global settings file (allow `Bash(cat:*)`, `Bash(git push:*)`, `Bash(git:*)`; deny `Bash(*.credentials.json*)`, `Bash(git push:*)`, `Bash(cat secret)`, `Bash(rm -rf:*)`) and no project settings; does not establish what Claude Code's own matcher does with those spellings, which is the point of Q-176.

Command: `env -u CLAUDE_CONFIG_DIR LC_ALL=C bash probe-hooks.sh` (cwd scratch `hp/`, HOME scratch `hh/`, 2026-10-15T20:04:12Z, exit 0):

```
[main] rc=0 cat ~/.claude/.cred""entials.json => <silent>
[br] rc=0 cat ~/.claude/.cred""entials.json => {"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow"}}
… same pattern for .c\redentials.json, git "push", cat "secret" (and the plain cat secret / git push)
```

MA1 at aeda94b2 lists exactly those four (`independent-review-2026-10-15-q092b.md:33`). The first run left `CLAUDE_CONFIG_DIR` set, so both hooks read the real config and were silent. That run is discarded, and the log holds the corrected run.

**Evidence:** `docs/working/questions.md:383`; `docs/reviews/independent-review-2026-10-15-q092b.md:22-36` (aeda94b2); `/tmp/claude-1000/-workspace/b1fde0b4-befb-4424-9add-ef12273f2f26/scratchpad/final-fc-1/q176-mainvsbranch.log`

---

## Claim 28: Q-176: "a throwaway hook that approves only the nine test commands below and stays silent on anything else", with each test mapped to a control ("glob rule", "`:*` prefix rule", "exact rule"), `seen.log` logging, and "the paste stops at `jq --version` without it"

**Location:** `docs/working/questions.md:385-412`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the paste's file creation under zsh (with `claude` stubbed and a fake HOME), and the hook's allow/silent output for the nine commands plus five near-misses. Does not establish Claude Code's deny decisions, `/hooks` listing, or whether Claude rewrites a command before the hook sees it.

The paste ran as `HOME=…/fh PATH=…/bin:$PATH timeout 30 zsh q176.sh` (2026-10-15T20:04Z, exit 0). It printed `jq-1.6`, `claude-stub --version` and `claude-stub`, then created `~/q092/{x.q092-canary,secret,.claude/allow-tests.sh,.claude/settings.local.json}`, and the settings file parses as JSON. Feeding the hook (`probe-q176.sh`, run under dash, 2026-10-15T20:04:31Z, exit 0):
- Each of the nine listed commands returned the `"permissionDecision":"allow"` JSON.
- `cat x.q092-canary ` (trailing space), `cat secret; ls`, `git push origin`, `cat x.q092-c\\anary` and `ls` were all `<silent>`.
- `seen.log` held 14 entries, one per call.

Deny mapping, from the paste's settings (`:394`): 1-3 fall under `Bash(*.q092-canary*)`, 4-5 under `Bash(rm -rf:*)`, 6-7 under `Bash(cat secret)`, and 8-9 under `Bash(git push:*)`. Each control (1, 4, 6, 8) is the literal form of its rule, as the entry labels it.

```sh
# docs/working/questions.md:389 (the hook's case pattern)
  'cat x.q092-canary'|'cat x.q092-ca""nary'|'cat x.q092-c\anary'|'rm -rf ./nothing-here'|'echo hi && rm -rf ./nothing-here'|'cat secret'|'cat "secret"'|'git push'|'git "push"')
```

**Evidence:** `docs/working/questions.md:385-412`; `/tmp/claude-1000/-workspace/b1fde0b4-befb-4424-9add-ef12273f2f26/scratchpad/final-fc-1/q176-hook.log`

---

## Claim 29: Q-162 (and Q-163, Q-164): "Paste the block from `/workspace` with `main` checked out" (`cd /workspace && …`)

**Location:** `docs/working/questions.md:83,88,116,147`
**Type:** Architectural
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers only that these three pastes use the path under which the repository and its `.claude/wt-build-loop-*` worktrees are registered. Does not establish whether the user's host terminal has a `/workspace` path (the host checkout is `~/claude-workflows` in Q-169 and in Q-126's archived paste).

The worktrees Q-162 removes are registered as `/workspace/.claude/wt-build-loop-<u>` (`git worktree list --porcelain`). So the paste is consistent with being run where `/workspace` is this checkout, for example from inside a session via `!`, as Q-167 (c) step 2 does. The entries do not say host or container. Q-169 and Q-176 say "Run it on the host" explicitly (`:260`, `:383`). What would verify it: the user's host layout. If `/workspace` does not exist on the host, `cd /workspace` fails and the `&&` chain stops before any git command, which fails safe.

**Evidence:** `docs/working/questions.md:83,88,116,147,260,383`; `docs/working/questions-archive.md` Q-126 (`cd ~/claude-workflows && …`)

---

## Claim 30: Merge 16136a60's message: "Conflicts in questions.md, questions-archive.md, roadmap.md and idea-log.md … resolved by keeping both sides" (Q-162..Q-177 from the branch, Q-179 from main; Q-089/Q-107 open copies dropped; Q-139/141/142/146 open copies dropped; Q-096/Q-103 keep the branch's notes; archive both sides; roadmap Next 3-5 branch, Q-146 becomes 6; idea log both)

**Location:** commit 16136a60 (message body); `docs/working/questions.md`, `docs/working/questions-archive.md`, `docs/roadmap.md`, `docs/working/idea-log.md` at 16136a60
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers per-entry comparison of both questions files and per-line comparison of the roadmap and idea log against both parents and their merge base (b279a2ba), plus `questions.sh check` and `index` at HEAD. Does not establish the semantic wording of entries edited after the merge (c86b8f3e, ae810886, 2141f7ee).

`python3 -I mergecheck.py` (cwd scratch, 2026-10-15T20:06Z, exit 0) results:
- **questions.md:** every entry in the merge equals its copy in one parent, with no duplicates. The dropped entries are Q-089 and Q-107, which main left unchanged from the base and the branch archived, and Q-139, Q-141, Q-142 and Q-146, which the branch left unchanged from the base and main archived. So no side's edit to a dropped entry was lost. Q-096 and Q-103 come from the branch, and main had left both unchanged from the base.
- **questions-archive.md:** Q-089 and Q-107 come from the branch; Q-139, Q-141, Q-142, Q-146 and Q-178 come from main.
- **roadmap.md:** every line either side added is present. The only line in neither parent is the renumbered `6. **Q-146 [1] …`.
- **idea-log.md:** nothing is missing. The one line in neither parent is a blank separator.
- `cycle-2026-10-15.md` and `test/scripts/build-loop-orchestrator.bats` equal main's copies, and `cycle-2026-10-14.md` equals the branch's.

At HEAD, `questions.sh check` prints `✓ questions: structure valid, indexes current`, and `questions.sh index` leaves the file byte-identical.

**Evidence:** `git show 16136a60`; `/tmp/claude-1000/-workspace/b1fde0b4-befb-4424-9add-ef12273f2f26/scratchpad/final-fc-1/mergecheck.log`

---

## Claims Requiring Attention

### Incorrect
- None.

### Stale
- **Claim 21** (`docs/working/questions.md:266`): Q-169 says the spike's "Not verified" section has 8 items. At the pinned a760a5e5 (and d25254da) it has 12; 8 was the count at 190fa1a4. Change it to 12.

### Mostly Accurate
- **Claim 8** (`docs/working/questions.md:83`): "every pair of these units conflicts only in override-log". Only Q-110, doc drift and Q-160 conflict, pairwise. T69 and Q-096 conflict with nothing. Say that the units that conflict do so only in override-log.
- **Claim 9** (`docs/working/questions.md:85`): the "before it" conflict list omits `docs/working/questions-archive.md`. Against main 7f711bfe, a760a5e5 conflicts in four files.
- **Claim 23** (`docs/working/questions.md:276`): "87 of 116". A recount at f050b487 gives 88 `Live-verified: no` of 116. Either use 88 or name the counting rule.

### Unverifiable
- **Claim 19** (`docs/working/questions.md:227-237`): Q-167 (c)'s exit-3 result needs the host cc-isolated run.
- **Claim 29** (`docs/working/questions.md:83`): whether `/workspace` exists where the user pastes Q-162/Q-163/Q-164 depends on the host layout. The entries do not say host or container, and the chain fails safe at `cd`.

## Goal-Alignment Note

The PR aims to land the 2026-10-14/15 cycle docs so that Q-162..Q-177 are actionable. The load-bearing artifacts hold under execution:
- All 18 branch/hash pins resolve to current, unmerged tips.
- Q-162's paste aborts cleanly and deletes nothing, both against current main and after this branch lands, and stops on a replace ref. On a base it can merge, it deletes exactly the twelve merged branches.
- Q-169's extraction yields 032cc9a8…afb7, and the block's first line is `script sha256 a65f4c30ba1b8907`.
- Q-176's hook approves exactly the nine commands. The main-versus-branch difference it tests is real.
- Merge 16136a60 dropped and duplicated nothing beyond what its message names.

What remains is wording: one stale count (Claim 21) and three imprecise statements (Claims 8, 9, 23), none of which changes an action the user would take. One forward-looking point is outside the claims' wording. Q-169 pins the same a760a5e5 that Q-162 says the next cycle will replace. Once `merge/ready-2026-10-15` is rebuilt, that commit is reachable only from reflogs. The extraction would then fail closed (wrong hash, so the user stops), so Q-169's pin needs re-pointing to d25254da or the rebuilt tip at the same time as Q-162's.
