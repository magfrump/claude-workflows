Commit: c86b8f3e
# Code Fact-Check Report

**Repository:** claude-workflows (worktree `/workspace/.claude/wt-dev-cycle-2026-10-15-0357`, branch `chore/dev-cycle-2026-10-15-0357`)
**Scope:** `git diff 16136a60..c86b8f3e` (review-fix iteration 2): docs/working/questions.md (Q-162 to Q-177), docs/roadmap.md, docs/working/questions-archive.md (Q-107), docs/reviews/override-log.md (two rows), docs/reviews/code-review-rubric-2026-10-15-chore-dev-cycle-2026-10-15-0357.md. The iteration-1 reports added in the same commit are context, not under review. Earlier branch commits are context only. Claims were checked against the git objects and code they describe (`git show <rev>:<path>`, `git rev-parse`, `git merge-tree`). Pastes were run in a throwaway clone and a fake `$HOME` under `/tmp/claude-1000/-workspace/b1fde0b4-befb-4424-9add-ef12273f2f26/scratchpad/i2fc/`.
**Replication:** k=1 (loop pass, decision 031)
**Checked:** 2026-10-15
**Total claims checked:** 30
**Summary:** 24 verified, 3 mostly accurate, 0 stale, 3 incorrect, 0 unverifiable

I read the hallucination pattern log (`docs/reviews/hallucination-patterns.md`) first. No claim below matches a logged pattern, and none of the Incorrect verdicts names a fabricated symbol, so this pass adds nothing to the log.

**Read this first: Claims 1b and 11.** `merge/ready-2026-10-15` at a760a5e5 does not merge into main as main is now (7f711bfe). It also does not merge into main after this branch lands. The cause of the second failure is the fix commit: its two new override-log rows are appended at the same place as the ready branch's rows. The iteration-1 tech-debt report found that this merge was clean against 16136a60, and that is no longer true. Q-162's new abort guard works, so nothing is damaged. But the next step after landing, Q-162's paste, aborts every time. The ready branch has to be rebuilt on the landed tip, and the hash pinned in Q-162 has to change with it.

---

## Claim 1a: "All three pastes pinned to full hashes (a760a5e5…, a04d9776…, 0f94bb77…); Q-162 gains the abort wrapper and skips deletion on conflict"

**Location:** `docs/reviews/code-review-rubric-2026-10-15-chore-dev-cycle-2026-10-15-0357.md:16`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that each pinned hash matches its branch and that Q-162's guard runs as described; does not cover whether the pinned merges succeed today (Claims 1b and 11).

Every pin is the full hash of the branch named beside it. `git rev-parse` gives `merge/ready-2026-10-15 a760a5e5057ef3f0abd13145e7d945ef500b8abd`, `merge/u5-and-q145 a04d97762518389f053c3c609a3dfcc4531d553b` and `merge/build-loop-u5-resolved 0f94bb7702073f78992b8eba25ac131473b49825`. These are the same strings as the pastes at `docs/working/questions.md:87`, `:114` and `:144`. The guard is `{ git merge --no-ff a760a5e5… -m "…" || { git merge --abort; echo "conflict: merge aborted, nothing deleted"; false; }; } && \` (`docs/working/questions.md:87`). I ran it in a clone and it behaved as the note says (see Claim 10).

**Evidence:** `docs/working/questions.md:86-88`, `:114`, `:144`; `git rev-parse` output (above); `/tmp/claude-1000/-workspace/b1fde0b4-befb-4424-9add-ef12273f2f26/scratchpad/i2fc/q162-zsh-clean-b279a2ba.log`, `…/q162-zsh-conflict-main7f711bfe.log`, `…/q162-conflict-bash.log`

---

## Claim 1b: A3 marked "Fixed", where A3's finding includes "conflicts on today's main"

**Location:** `docs/reviews/code-review-rubric-2026-10-15-chore-dev-cycle-2026-10-15-0357.md:16`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers whether a760a5e5 merges into main, and into this branch's tip, as the landing order requires; does not establish how the rebuilt ready branch should resolve the conflict.

The A3 row lists "conflicts on today's main" as part of the finding. Only the guard was fixed. The conflict is still there, and this fix commit adds one more. Tech-debt F1 (`docs/reviews/tech-debt-triage-review-2026-10-15-0357.md:31-34`) wrote: "`git merge-tree --write-tree main merge/ready-2026-10-15` … exits 1 … Against HEAD (16136a60) the same command exits 0", and gave the cost of deferral as "`+0` if this branch lands before anyone runs Q-162". Re-run at 2026-10-15T19:5xZ:

- `git merge-tree --write-tree --name-only 16136a60 a760a5e5` exits 0
- `git merge-tree --write-tree --name-only c86b8f3e a760a5e5` exits 1: `CONFLICT (content): Merge conflict in docs/reviews/override-log.md`
- `git merge-tree --write-tree --name-only main a760a5e5` exits 1, with conflicts in roadmap.md, idea-log.md, questions-archive.md and questions.md

The cause is the two rows c86b8f3e appends after `docs/reviews/override-log.md:827` ("`| 2026-10-15 | \`chore/dev-cycle-2026-10-15-0357\` | User-routed questions gro…`" and "`… Branch hashes and statuse…`", now `:828-829`). a760a5e5 appends its own rows at the same point: `git diff 16136a60 a760a5e5 -- docs/reviews/override-log.md` shows `@@ -825,3 +825,26 @@`, which adds 23 rows. I also landed c86b8f3e in the clone (`git merge --no-ff origin/chore/dev-cycle-2026-10-15-0357`) and then ran Q-162's paste. It exited 1 with the override-log conflict, and the guard aborted the merge. The pinned a760a5e5 therefore cannot be merged after this landing. A rebuild means a new ready commit and a new pin in Q-162.

**Evidence:** `/tmp/claude-1000/-workspace/b1fde0b4-befb-4424-9add-ef12273f2f26/scratchpad/i2fc/merge-tree-16136a60-vs-a760a5e5.txt`, `…/merge-tree-c86b8f3e-vs-a760a5e5.txt`, `…/merge-tree-main-vs-a760a5e5.txt`, `…/q162-zsh-conflict-main-plus-c86b8f3e.log`; `docs/reviews/override-log.md:827-829`; `docs/reviews/tech-debt-triage-review-2026-10-15-0357.md:31-37`

---

## Claim 2: "checked: 7/7 allow, `ls -la` and `cat x.q092-canary; id` get no output"

**Location:** `docs/reviews/code-review-rubric-2026-10-15-chore-dev-cycle-2026-10-15-0357.md:22`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the hook script's output for the seven commands, the two named negatives and five more near-misses when jq is present; does not cover Claude Code calling the hook (needs `claude`, which this pass must not run).

I wrote the script with the paste's heredoc, built each input as `jq -n --arg c "$c" '{tool_name:"Bash",tool_input:{command:$c}}'`, and piped it to `sh` (dash) running the script. All seven listed commands returned `{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow"}}`. These returned nothing: `cat x.q092-canary; id`, `ls -la`, `git push`, `cat 'secret'`, `cat x.q092-canary ` (trailing space), ` cat secret` (leading space), `cat x.q092-c\\anary` (doubled backslash), and an input with no command. Exit code 0. Run at 2026-10-15T19:50:39Z, cwd the scratch directory.

**Evidence:** `docs/working/questions.md:381-387`; `/tmp/claude-1000/-workspace/b1fde0b4-befb-4424-9add-ef12273f2f26/scratchpad/i2fc/q176-hook.log`

---

## Claim 3: "checked against the full body sha256 `032cc9a8…afb7` (re-computed here)"

**Location:** `docs/reviews/code-review-rubric-2026-10-15-chore-dev-cycle-2026-10-15-0357.md:25`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the hash of the extracted block; the host path in the extraction command is Claim 22.

See Claim 20. The extraction command, run against the repo's object store, prints `032cc9a81e4e1c9266ec3ad3b5fe7053d9876eb21f5ffa7f0a35f2ccfed4afb7`.

**Evidence:** `/tmp/claude-1000/-workspace/b1fde0b4-befb-4424-9add-ef12273f2f26/scratchpad/i2fc/q169-sha.log`

---

## Claim 4: The rubric's other "Fixed" author notes (A1, A2, A4–A8, A10, A11, A13, C1, C2, C8) match the diff

**Location:** `docs/reviews/code-review-rubric-2026-10-15-chore-dev-cycle-2026-10-15-0357.md:14-41`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that each note describes an edit in `git diff 16136a60..c86b8f3e`; whether each edit is accurate is checked in the per-entry claims below.

I matched each note to its hunk. A1 is `questions.md:203`, which now names both the bless output and the `--list` output. A2: "main (as of b279a2ba) plus seven reviewed units" (`:83`). A4: `:161`, `:178`. A5: `roadmap.md:52`, `questions.md:164`. A6: `roadmap.md:118` and archive `:2738`. A7: `:137`. A8: `:338`. A10: the seven-item list at `:396-402`, the controls, and Q-177's cell at `:421`. A11: `:404`. A13: `:364`, `:368`, `:371`. C1: `:191`. C2: Step 2 moved out of the fence (`:228-232`). C8: `:120`. The note for C8 gives no target text. The edit reads "(Q-156, filed on `feat/build-loop-u5`; it reaches main with Q-164)" (paraphrased: no quote available because each hunk is quoted in the claim for its entry below).

**Evidence:** `git diff 16136a60..c86b8f3e -- docs/working/questions.md docs/roadmap.md docs/working/questions-archive.md`

---

## Claim 5: Override-log row for tech-debt F2: "User-routed questions grow from 2 to 15 (`you: judgment` 1 to 10), and the order to answer them in (Q-162 before Q-163/Q-164/Q-167, Q-165 before Q-166/Q-169, Q-176 before Q-177, Q-172 before Q-173) … (tech-debt-triage F2, Medium)"

**Location:** `docs/reviews/override-log.md:828`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers that the row's wording matches F2; does not re-count the open entries.

F2's table (`docs/reviews/tech-debt-triage-review-2026-10-15-0357.md:47-50`) gives `| you: judgment | 1 | 10 |` and `| you: terminal | 1 | 5 |`. That is 2 to 15 user-routed entries. F2's order line is "(Q-162 → Q-167; Q-165 → Q-166/Q-169; Q-176 → Q-177; Q-172 → Q-173; Q-162 before Q-163/164)" (`:60-61`), and its severity is "**Severity:** Medium" (`:44`). The row merges the two Q-162 chains into one, which keeps the meaning.

**Evidence:** `docs/reviews/override-log.md:828`; `docs/reviews/tech-debt-triage-review-2026-10-15-0357.md:43-72`

---

## Claim 6: Override-log row for tech-debt F3: "the copies drifted (five vs seven units, "Next 3", 22a4bb1f vs d25254da, Q-106 "on" the ready branch) … Each drifted copy found here is corrected in this landing"

**Location:** `docs/reviews/override-log.md:829`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the four strings F3 quotes; does not cover older cycle records, which F3 does not quote.

F3 quotes the same four drifts (`tech-debt-triage-review-2026-10-15-0357.md:79-84`) at "**Severity:** Low". At c86b8f3e, `rg -n 'Next 3|five reviewed|22a4bb1f'` finds only historical "was Next 3" mentions in the roadmap (`roadmap.md:41`, `:45`, `:51`). It also finds Q-165's `:164`, which cites 22a4bb1f as the doc commit and d25254da as the tip. Q-174 no longer says the branch is "on" the ready branch (`questions.md:338`).

**Evidence:** `docs/reviews/override-log.md:829`; `docs/reviews/tech-debt-triage-review-2026-10-15-0357.md:74-91`; `docs/roadmap.md:41-52`; `docs/working/questions.md:164`, `:338`

---

## Claim 7: "(was Next 3; `docs/branch-verify-without-install`, tip d25254da)"

**Location:** `docs/roadmap.md:51-52`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the hash; does not cover the rest of the item.

`git rev-parse docs/branch-verify-without-install` gives `d25254dae30fe05fd385b3ff430104fb63c39158`, and the item sits under `## Now` (`roadmap.md:12`).

**Evidence:** `docs/roadmap.md:51-52`

---

## Claim 8: "a second copy of the names, with no parity test" / "with no parity test (one test pins `scripts`)"

**Location:** `docs/roadmap.md:118`; `docs/working/questions-archive.md:2738`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the two name lists and the test that pins `scripts`; does not prove that no other test compares the lists (only a grep).

On main, `ENTRIES=(skills workflows guides patterns hooks scripts CLAUDE.md)` (`devcontainer-config/link-claude-home.sh:50`) and `CLAUDE_HOME_SRC=(global-instructions/CLAUDE.md skills workflows guides patterns hooks scripts)` (`devcontainer-config/install.sh:135`). The comment at `test/link-claude-home-wiring.bats:298` mentions "`scripts` from ENTRIES or from CLAUDE_HOME_SRC", and the test at `:300` is "installed ~/.claude/scripts/{lite-review.py,questions.sh} resolve after install". No test compares the whole lists (paraphrased: no quote available because this is the absence of matches in an `rg` over `test/` for the two array names).

**Evidence:** `devcontainer-config/link-claude-home.sh:50`; `devcontainer-config/install.sh:135`; `test/link-claude-home-wiring.bats:295-301`

---

## Claim 9: "It merges `merge/ready-2026-10-15` by its reviewed tip, a760a5e5 … That branch is main (as of b279a2ba) plus seven reviewed units"

**Location:** `docs/working/questions.md:83`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the hash, the base and the unit list; whether the merge succeeds is Claim 11.

`git rev-parse merge/ready-2026-10-15` gives a760a5e5…, and `git merge-base main a760a5e5` gives b279a2ba. `git log --first-parent main..a760a5e5` shows exactly seven unit merges: `fix/t69-stage-race`, `fix/q110-not-run-undercount`, `fix/doc-drift-cycle1`, `fix/q160-iteration-cap`, `fix/q096-exit-scan-insteadof-target`, `fix/rebuild-hint-recreate` and `fix/cc-isolated-one-workspace`. It also shows the two docs branches and the chore-record merges the sentence names. All twelve `feat/build-loop-u*` branches are ancestors of main (`git merge-base --is-ancestor` on each).

**Evidence:** `docs/working/questions.md:83`; `git log --first-parent --oneline main..a760a5e5`

---

## Claim 10: Q-162 paste grouping: on merge success the deletion loop runs; on failure the merge is aborted, the message prints, and the loop does not run

**Location:** `docs/working/questions.md:86-88`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the paste's control flow in zsh and bash in a clone, with `cd /workspace` replaced by the clone path; does not cover the shared `/workspace` checkout's state.

The block (`questions.md:86-88`) was extracted to `q162.txt` and run with `cd /workspace` rewritten to the clone (`q162-clone.sh`). The clone had all twelve worktrees and branches created.

- **Clean case** (main reset to b279a2ba in the clone; zsh; 2026-10-15T19:48:45Z): exit 0. The merge commit is "Merge branch 'merge/ready-2026-10-15': T69, …", then "Deleted branch feat/build-loop-u3a1 … u4c" for all twelve. Afterwards 0 branches and 1 worktree remain.
- **Conflict case** (main 7f711bfe; zsh at 19:48:28Z and bash at 19:52:58Z): exit 1, then `conflict: merge aborted, nothing deleted`. There was no `MERGE_HEAD`, the status was clean, and all 12 branches and 13 worktrees were still there.

The trailing `false` makes the `{ …; }` group fail, so `&&` skips the `for` loop.

**Evidence:** `/tmp/claude-1000/-workspace/b1fde0b4-befb-4424-9add-ef12273f2f26/scratchpad/i2fc/q162-zsh-clean-b279a2ba.log`, `…/q162-zsh-conflict-main7f711bfe.log`, `…/q162-conflict-bash.log`, `…/q162-clone.sh`

---

## Claim 11: "Paste the block from `/workspace` with `main` checked out. It merges `merge/ready-2026-10-15` by its reviewed tip, a760a5e5 …, then deletes the twelve build-loop branches"

**Location:** `docs/working/questions.md:83`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the paste run against today's main and against main after this branch lands; does not cover a ready branch rebuilt later.

The paste aborts and deletes nothing in both states. On main 7f711bfe it hits "CONFLICT (content): Merge conflict in docs/working/questions-archive.md" and in questions.md. On main with c86b8f3e merged it hits "CONFLICT (content): Merge conflict in docs/reviews/override-log.md". The entry's only recovery sentence is about the other two entries: "Their pastes abort on a conflict, and once main moves, the loop rebuilds their merge branches" (`:83`, Q-163/Q-164). For Q-162 the user gets "conflict: merge aborted, nothing deleted" and no next step. The hash is pinned, so the fix needs a rebuilt ready commit and a new hash in the entry. For the same reason, Q-163's and Q-164's pinned targets also conflict with c86b8f3e (override-log, roadmap, questions and archive for a04d9776 and 0f94bb77; override-log for c035f2e7). Their entries already say they abort and get rebuilt.

**Evidence:** `/tmp/claude-1000/-workspace/b1fde0b4-befb-4424-9add-ef12273f2f26/scratchpad/i2fc/q162-zsh-conflict-main7f711bfe.log`, `…/q162-zsh-conflict-main-plus-c86b8f3e.log`; `git merge-tree --write-tree --name-only c86b8f3e {a04d9776,0f94bb77,c035f2e7}`

---

## Claim 12: "The tip, a760a5e5, adds the rebuild-hint and one-workspace merges after that gate; each of those units ran its own gate (above), and the tip holds exactly the units listed."

**Location:** `docs/working/questions.md:99`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the first-parent merges after 3fe6d6e3; does not re-run either unit's gate.

After 3fe6d6e3, the first-parent history has the two unit merges (`c29d1acf Merge branch 'fix/rebuild-hint-recreate'`, `fc4c6840 Merge branch 'fix/cc-isolated-one-workspace'`). It also has `a53e1bc2 Merge branch 'docs/branch-verify-without-install'`, `11184f2b Merge branch 'docs/dd-015-step4'` and nine `Merge branch 'chore/dev-cycle-2026-10-15-0357'` commits. The units are correct. More precisely: the tip adds those two unit merges plus the two docs-only branches and the cycle-record merges, all docs.

**Evidence:** `git log --first-parent --oneline main..a760a5e5`; `docs/working/questions.md:99`

---

## Claim 13: Q-163 pins `merge/u5-and-q145` at a04d9776 and c035f2e7; Q-156 is "filed on `feat/build-loop-u5`; it reaches main with Q-164"

**Location:** `docs/working/questions.md:110-114`, `:120`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the hashes, what the commits contain and where Q-156 lives; does not cover the merge result (it conflicts; see Claim 11).

a04d9776 is "Merge branch 'fix/q145-ancestor-vanish' into merge/u5-and-q145: U5 and Q-145 together". It contains c035f2e7, 7c91b974 and f5b7e49d. c035f2e7 is `fix/q145-ancestor-vanish`. `### Q-156` has 1 match in `feat/build-loop-u5:docs/working/questions.md` and 0 on main, HEAD and a760a5e5. Both Q-164 targets contain 7c91b974.

**Evidence:** `docs/working/questions.md:110-120`; `git merge-base --is-ancestor` results above

---

## Claim 14: "Size: 26 code lines outside `docs/`, 409 lines in all."

**Location:** `docs/working/questions.md:137`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers `git diff --numstat b279a2ba 7c91b974`; does not establish the exclusion the author meant.

Outside `docs/`, the count is 26, which matches. Excluding `docs/reviews/` (16 files), the total is 409. Everything included, the total is 6,102. "in all" leaves out the review artifacts without saying so. The precise version is "409 lines excluding review artifacts".

**Evidence:** `git diff --numstat b279a2ba 7c91b974` (numstat sum, paraphrased: no quote available because it is an awk sum over 29 numstat rows)

---

## Claim 15: Q-164 pins `merge/build-loop-u5-resolved` at 0f94bb77 ("this cycle's chore branch, Q-110 and U5 … U5's reviewed tip is unchanged inside it")

**Location:** `docs/working/questions.md:140-144`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the hash and what the commit contains; does not check every resolved hunk.

0f94bb77's first-parent history is `Merge branch 'fix/q110-not-run-undercount' into merge/build-loop-u5-resolved`, then `e088c7e3 Merge branch 'feat/build-loop-u5' …`, then `46942678`/`63af3551` (the 2026-10-14 chore commits), then `b279a2ba`. It contains 7c91b974 and f5b7e49d. It does not contain c035f2e7, as intended.

**Evidence:** `git log --first-parent --oneline -6 0f94bb77`

---

## Claim 16a: Q-165 "(roadmap Now, "Verify a branch without installing it" …)" and "**Blocks:** the roadmap Now item …"

**Location:** `docs/working/questions.md:161`, `:178`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the cross-reference to the roadmap.

`docs/roadmap.md:51` "- **Verify a branch without installing it** (was Next 3; …" sits under `## Now` (`:12`), before `## In flight` (`:58`).

**Evidence:** `docs/roadmap.md:12`, `:51`

---

## Claim 16b: "(22a4bb1f; the branch tip, d25254da, adds the spike's review commits)"

**Location:** `docs/working/questions.md:164`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers 22a4bb1f..d25254da; does not cover the docs' content.

22a4bb1f is an ancestor of d25254da. Between them, the two cited docs are unchanged. The 8 commits in between start with `12fcb61c docs: spike doc with the one-paste Q-117 verify that installs nothing`, so they add the spike doc itself (`docs/working/spike-cc-verify-q117.md`, +711) as well as its review commits. Precise version: "adds the spike doc and its review commits".

**Evidence:** `git log --oneline 22a4bb1f..d25254da`; `git diff --stat 22a4bb1f d25254da`

---

## Claim 17: "For Q-125 that difference is real: a staged run never executes its `install.sh` `PAYLOAD` or `cc-isolated.sh` `enforcement_files()` changes (Q-117 changes only `init-firewall.sh`)"

**Location:** `docs/working/questions.md:191`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the two branches' devcontainer-config diffs from their merge-bases; Q-117 also changes tests and docs, which are not config.

`feat/q125-cc-isolated-sandbox` (2961ca2f) changes `PAYLOAD=(devcontainer.json Dockerfile seccomp-cc-sandbox.json managed-settings.json cc-sandbox-settings.sh …)` in install.sh. It also adds `echo "seccomp-cc-sandbox.json"`, `echo "managed-settings.json"` and `echo "cc-sandbox-settings.sh"` to `enforcement_files()` in cc-isolated.sh (diff at `cc-isolated.sh:129-134` on the branch). Under devcontainer-config, `fix/egress-dnsmasq-ipset` (b26d4b8b) changes only `devcontainer-config/init-firewall.sh | 293`. A staged run uses main's launcher, so main's `enforcement_files()` applies. The spike also refuses a merged tree whose PAYLOAD differs: `grep -qxF "$EXPECT_PAYLOAD" <<< "$inst" || die "install.sh's PAYLOAD in the merged tree is not the list this spike stages; update the spike."` (spike block lines 364-365 at a760a5e5).

**Evidence:** `git diff $(git merge-base main feat/q125-cc-isolated-sandbox) feat/q125-cc-isolated-sandbox -- devcontainer-config/install.sh devcontainer-config/cc-isolated.sh`; `git diff --stat $(git merge-base main fix/egress-dnsmasq-ipset) fix/egress-dnsmasq-ipset`

---

## Claim 18: Q-167(a): the bless output shows "`Verified live:  NO — a bless is a review, not a test.` followed by `Next: cc-isolated --probe-only <repo>`"; `--list` shows "`Blessed config <hash> — verified live: NO (run: cc-isolated --probe-only <repo>)`"

**Location:** `docs/working/questions.md:203`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the strings at a760a5e5 (what Q-162 installs); the quoted bless line is a prefix of the printed line; does not run the launcher.

At a760a5e5: `echo "Verified live:  NO — a bless is a review, not a test. Nothing has run this config."` / `echo "  Next: cc-isolated --probe-only <repo>"` (`devcontainer-config/cc-isolated.sh:328-329`, inside the bless function, which ends at `:330+`, read). `--list` has `echo "Blessed config $b — verified live: NO (run: cc-isolated --probe-only <repo>)"` (`:501`).

**Evidence:** `a760a5e5:devcontainer-config/cc-isolated.sh:324-330`, `:499-501`

---

## Claim 19: Q-167(c) Step 2 moved out of the fence (C2)

**Location:** `docs/working/questions.md:228-232`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers that no fenced line in Q-167 starts with `#`; does not run the probe.

The Step 2 sentence is now prose (`:228`), and its fence holds only `! printf '#!/bin/sh\necho planted\n' > mirror-repo/hooks/pre-receive && chmod +x …` (`:231`). No fenced line in Q-167 starts with `#`.

**Evidence:** `docs/working/questions.md:198-236`

---

## Claim 20: Q-169: `git show a760a5e5…:docs/working/spike-cc-verify-q117.md | awk '/^```bash$/{f=1;next} f&&/^```$/{exit} f'` yields a body whose sha256 "must be `032cc9a81e4e1c9266ec3ad3b5fe7053d9876eb21f5ffa7f0a35f2ccfed4afb7`"; block "(498 lines with its fences)"

**Location:** `docs/working/questions.md:252-257`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the extraction and hash run in this repo's object store with the output redirected to scratch; the `cd /workspace` part is Claim 22.

Command: the paste's pipeline, with `~/q117-spike.txt` replaced by the scratch path, run under `timeout 30 sh -c` in `/workspace/.claude/wt-dev-cycle-2026-10-15-0357` at 2026-10-15T19:49:19Z. Exit 0. Output: `032cc9a81e4e1c9266ec3ad3b5fe7053d9876eb21f5ffa7f0a35f2ccfed4afb7`. The body is 496 lines. The doc's fences are at lines 49 (```` ```bash ````) and 546 (```` ``` ````), so the block is 498 lines. The doc is byte-identical at d25254da and a760a5e5 (same sha256, `7e444167…`).

**Evidence:** `/tmp/claude-1000/-workspace/b1fde0b4-befb-4424-9add-ef12273f2f26/scratchpad/i2fc/q169-sha.log`, `…/q117-spike.txt`

---

## Claim 21: "Then paste the file's contents, editing only its last line … Its first output line must be `script sha256 a65f4c30ba1b8907`"

**Location:** `docs/working/questions.md:257`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the hash that `BASH_EXECUTION_STRING` would produce from the extracted file in bash and zsh; does not run the spike (it drives docker).

The block is `bash -c "$(cat <<'CCVERIFY'` … `CCVERIFY` / `)" spike-q117 ~/claude-workflows`. It prints `"   script sha256 $(printf '%s' "$BASH_EXECUTION_STRING" | sha256sum | cut -c1-16)"` (spike line 296). I replaced `bash -c` with `printf "%s"` and dropped the trailing arguments (`q117-printf.sh`), then hashed the output. bash gives `a65f4c30ba1b8907` and zsh gives `a65f4c30ba1b8907` (2026-10-15T19:49:32Z, exit 0). The last line is outside the heredoc, so editing it does not change the hash. That the hash is the *first* output line rests on reading: no top-level output comes before line 296 except on the `--clean` path (paraphrased: no quote available because it is the absence of echo/printf at top level in spike lines 1-295, checked by grep).

**Evidence:** `/tmp/claude-1000/-workspace/b1fde0b4-befb-4424-9add-ef12273f2f26/scratchpad/i2fc/q169-selfhash.log`, `…/q117-printf.sh`

---

## Claim 22: Q-169's extraction runs as `cd /workspace && git show … > ~/q117-spike.txt`, for a block that must run on the host

**Location:** `docs/working/questions.md:254`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the path conventions in the repo; does not observe the user's host, which might have a `/workspace`.

`/workspace` is the container's mount point: `"workspaceMount": "source=${localWorkspaceFolder},target=/workspace,type=bind,…"` (`devcontainer-config/devcontainer.json:134`). The spike says "Run on the HOST, from your own terminal" and "[ -z "${CLAUDECODE:-}" ] || die …" (spike lines 4, 298). Its last line names the host checkout as `~/claude-workflows`. Earlier host pastes in the archive use `cd ~/claude-workflows && git show …` (`docs/working/questions-archive.md:2206`, `:2535`). On the host, `cd /workspace` would most likely fail, and nothing runs after it (it fails closed). Run inside the container instead, it writes `~/q117-spike.txt` to the container's home, not the host's. Precise version: `cd ~/claude-workflows && …`.

**Evidence:** `devcontainer-config/devcontainer.json:134-135`; `docs/working/questions-archive.md:2206`, `:2535`; spike block line 1-4, 298, 496

---

## Claim 23: "Q-106 [2] is built (`feat/q106-host-settings-merge`, c6d7544f, built on an earlier `merge/ready-2026-10-15` commit, 184396ea; it is not in the ready branch Q-162 merges)"

**Location:** `docs/working/questions.md:338`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the ancestry.

`git rev-parse feat/q106-host-settings-merge` gives c6d7544f…. 184396ea is an ancestor of it and is `git merge-base c6d7544f a760a5e5`. `git merge-base --is-ancestor c6d7544f a760a5e5` fails, so Q-106 is not in the ready branch.

**Evidence:** ancestry commands above

---

## Claim 24: "On main that jq is inline in `link-claude-home.sh`, which the regex covers (`hooks/live-verify-gate.sh:83`), so the move takes away coverage the program has today."

**Location:** `docs/working/questions.md:364`, `:368`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the regex and where the jq program lives on main and on Q-106's branch; does not cover the trust-manifest clause.

Main has `enforcement='^devcontainer-config/(Dockerfile|devcontainer\.json|init-firewall\.sh|cc-sni-proxy\.py|link-claude-home\.sh|cc-isolated\.sh|install\.sh$|egress/)'` (`hooks/live-verify-gate.sh:83`). The merge program is inline: `if jq --arg dir "$DEST" --slurpfile w "$WIRING" '` … `' "$SETTINGS" > "$tmp"` (`devcontainer-config/link-claude-home.sh:133-161`, read through the `then`). `hooks/lib/wiring-merge.jq` exists on c6d7544f and not on main, and `echo hooks/lib/wiring-merge.jq | grep -E "$enforcement"` matches nothing.

**Evidence:** `main:hooks/live-verify-gate.sh:83`; `main:devcontainer-config/link-claude-home.sh:128-162`

---

## Claim 25: "Main's hook stays silent on `.cred""entials.json`, `.c\redentials.json`, `git "push"` and `cat "secret"`; the branch's hook approves them (the review's MA1 names all four; the check below tries each shape)"

**Location:** `docs/working/questions.md:378`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the parenthetical (the MA1 citation and the shape mapping); the main-vs-branch hook behaviour was rated Unverifiable in iteration 1 (C7) and is not re-run here.

MA1 says: "`cat ~/.claude/.cred""entials.json`, `.c\redentials.json`, `git "push"` and `cat "secret"` go from no output on main to `allow` at HEAD" (`fix/q092-drop-hook-deny-reader:docs/reviews/independent-review-2026-10-15-q092b.md:30`). MA1 also names "a denied subcommand in a list" (`:28`). In the check, items 2 (`ca""nary`), 3 (`c\anary`), 7 (`git "push"`), 6 (`cat "secret"`) and 4 (the compound) cover those shapes.

**Evidence:** `fix/q092-drop-hook-deny-reader:docs/reviews/independent-review-2026-10-15-q092b.md:22-33`; `docs/working/questions.md:396-402`

---

## Claim 26: Q-176's paste writes the hook script and settings (heredocs well-formed, JSON valid, hook command path matches the written script)

**Location:** `docs/working/questions.md:380-395`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers parsing and the files written in bash and zsh; does not cover Claude Code loading `settings.local.json` from a non-git `~/q092` (needs `claude`).

`bash -n` and `zsh -n` on the extracted block both pass. This session's write guard refuses Bash writes under `.claude/`, so the block was run with `.claude` renamed to `dotc`, `settings.local.json` to `sl.json`, `claude --version && claude` stubbed, and `HOME` set to scratch. It ran in bash and zsh (2026-10-15T19:50:32Z), exit 0 each time. It wrote `secret`, `x.q092-canary`, `dotc/allow-tests.sh` and `dotc/sl.json`. `jq .` accepts the JSON. The deny list reads `["Bash(*.q092-canary*)","Bash(rm -rf:*)","Bash(git push:*)","Bash(cat secret)"]`, and the hook command is `sh "$HOME/q092/dotc/allow-tests.sh"`. The renaming was consistent, so the original paste's `sh \"$HOME/q092/.claude/allow-tests.sh\"` (`:390`) names the file the first heredoc writes (`cat > .claude/allow-tests.sh` after `cd ~/q092`, `:380`).

**Evidence:** `/tmp/claude-1000/-workspace/b1fde0b4-befb-4424-9add-ef12273f2f26/scratchpad/i2fc/q176.txt`, `…/q176-stub.sh`, `…/q176-paste.log`

---

## Claim 27: "a throwaway hook that approves only the seven test commands below and stays silent on anything else"

**Location:** `docs/working/questions.md:378`, `:381-387`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers exact-string matching of the seven commands as JSON-encoded by jq; the hook needs `jq` on the host, which the entry does not say. Without jq, `c` is empty and the hook is silent on everything.

See Claim 2 for the run. The case patterns are single-quoted in a `/bin/sh` script, so `""` and `\a` are literal. The commands, encoded as JSON (`"cat x.q092-ca\"\"nary"`, `"cat x.q092-c\\anary"`) and decoded by `jq -r`, match exactly.

**Evidence:** `/tmp/claude-1000/-workspace/b1fde0b4-befb-4424-9add-ef12273f2f26/scratchpad/i2fc/q176-hook.log`; `docs/working/questions.md:381-387`

---

## Claim 28: The deny rules correspond to the controls and spellings: each listed command would be denied by a working matcher

**Location:** `docs/working/questions.md:389`, `:396-402`, `:404`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the mapping from each command to a rule; does not establish Claude Code's matcher semantics (the purpose of the live check). The controls test only the glob rule and the exact rule, not the `:*` prefix rules, so a "runs" on items 4 or 7 cannot tell quote handling apart from prefix-rule handling. A "prompts" result (the hook did not fire, e.g. jq missing) is not covered by the entry's decision line.

Mapping, with the rules from `"deny": ["Bash(*.q092-canary*)", "Bash(rm -rf:*)", "Bash(git push:*)", "Bash(cat secret)"]` (`:389`):

- `*.q092-canary*`: item 1 (control, literal match), items 2 and 3 (same target, spelled with `""` or `\` mid-word)
- `rm -rf:*`: item 4 (subcommand after `&&`)
- `cat secret`: item 5 (control, exact) and item 6 (quoted)
- `git push:*`: item 7 (quoted)

Each test command is harmless if it runs: a missing file for `rm -rf`, and `~/q092` is not a git repository. The entry's rule "If a control is not denied, the check is void" (`:404`) covers item 1 and item 5 only. With the hook approving, a listed command that the deny matcher misses *runs*. So "prompts" means the hook was inactive. The entry's "If the answer differs" line (`:407`) covers only "runs" and "denied".

**Evidence:** `docs/working/questions.md:378-407`

---

## Claims Requiring Attention

### Incorrect
- **Claim 1b** (`docs/reviews/code-review-rubric-2026-10-15-chore-dev-cycle-2026-10-15-0357.md:16`): A3 is marked Fixed, but the conflict half is not fixed. c86b8f3e's two override-log rows (`override-log.md:828-829`) make a760a5e5 conflict with this branch's own tip; it was clean against 16136a60. Rebuild `merge/ready-2026-10-15` on the landed tip and re-pin Q-162, or say in the merge summary that Q-162 needs a rebuild after landing.
- **Claim 11** (`docs/working/questions.md:83`): Q-162's paste aborts on main today and on main after this landing; the entry gives no next step for its own abort.
- **Claim 22** (`docs/working/questions.md:254`): Q-169's extraction does `cd /workspace` (the container mount) for a block that must run on the host. Earlier host pastes use `cd ~/claude-workflows`. It fails closed.

### Mostly Accurate
- **Claim 12** (`docs/working/questions.md:99`): after 3fe6d6e3 the tip also adds the two docs-branch merges and nine cycle-record merges, not only the two unit merges.
- **Claim 14** (`docs/working/questions.md:137`): 409 excludes `docs/reviews/`; say so ("409 lines excluding review artifacts").
- **Claim 16b** (`docs/working/questions.md:164`): d25254da adds the spike doc itself as well as its review commits.

### Unverifiable
None. Note for the orchestrator (Claims 27 and 28): Q-176's hook depends on `jq` on the host, and the entry does not cover a "prompts" outcome.
