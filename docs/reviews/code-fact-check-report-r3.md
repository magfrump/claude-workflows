Commit: 46342d66

# Code Fact-Check Report

**Repository:** /workspace (worktree /workspace/.claude/wt-q180)
**Scope:** branch diff `git diff main...HEAD` for `chore/q180-repin-pastes` (46342d66 vs main b71a4e9e): `docs/working/questions.md`, `docs/roadmap.md`, `docs/working/checkpoint-build-loop-handoff.md`, and the two commit messages; plus the brief's twelve claim groups
**Checked:** 2026-10-15
**Total claims checked:** 27
**Summary:** 23 verified, 2 mostly accurate, 1 stale, 0 incorrect, 1 unverifiable

Replicate r3. Execution ran under `/tmp/claude-1000/-workspace/736a173d-70f8-4751-993a-da117d91dc21/scratchpad/cfc-r3/` (written `$X/` below). That directory holds a local clone of /workspace (`$X/repo`, `core.hooksPath=/dev/null`) where the pastes were run for real. In /workspace I ran only read-only git. The captured logs are under `$X/`: `git-checks.log`, `count-checks.log`, `run.log` (paste runs), `guard.log`, `driver.log`, `driver2.log`, `t23-alone.log`, `q167.log`, `q176.log`, `qcheck.log`. Throughout, `$X/repo` runs used git 2.39 with bash 5 and zsh. Before checking, I read `docs/reviews/hallucination-patterns.md`. Its count-claim entries (lines 26-30: claimed totals that the suites or corpus do not hold) bear on the count claims here (Claims 4, 10, 19, 20, 21). Every such count was recomputed, and none matches a logged pattern.

---

## Claim 1: "`merge/ready-2026-10-15-r2` re-merges the same nine unit tips onto main b71a4e9e" / "main (as of b71a4e9e) plus seven reviewed units, the branch-verify research and spike docs … and the decision-015 divergent design … each merged with `--no-ff`"

**Location:** `docs/working/questions.md:84-86`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the tip hash, the first-parent chain from b71a4e9e, the nine second parents and the 7+1+1 composition. It does not establish anything about the units' own content beyond their hashes.
**Legibility-target:** for-orchestrator-synthesis

`merge/ready-2026-10-15-r2` resolves to `09a2876ff5ea6f7e5b86eea723c2aa0094759145`. Its first-parent merges since b71a4e9e have these second parents, in order: 4ee81106 (t69), f5b7e49d (q110), c8e87a69 (doc-drift), 4a44d2f3 (q160), 8717fd72 (q096), d25254da (branch-verify), f050b487 (dd-015), 47da5a4b (rebuild-hint) and f6f37fad (one-workspace). The bottom merge's first parent is b71a4e9e. a760a5e5's first-parent chain holds the same nine second parents, plus ten `chore/dev-cycle-2026-10-15-0357` merges (paraphrased, no quote available because this is commit-graph output, captured in `$X/git-checks.log` § "r2 first-parent merges").

Command: the loop in `$X/git-checks.log` (cwd `/workspace/.claude/wt-q180`, 2026-10-15T14:06-07:00, exit 0).

**Evidence:** `docs/working/questions.md:84`, `$X/git-checks.log`

---

## Claim 2: "Its diff from a760a5e5 is exactly main's own change since then"

**Location:** `docs/working/questions.md:86`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers tree equality between 09a2876f and a three-way merge of a760a5e5 with main, outside `docs/reviews/override-log.md` (that file is Claim 3). It does not establish that the per-merge commit messages match.
**Legibility-target:** for-orchestrator-synthesis

`git merge-tree --write-tree a760a5e5 main` (merge base 92f3b080, the only one) conflicts only in `docs/reviews/override-log.md`. Its result tree differs from 09a2876f's tree only in that file: `docs/reviews/override-log.md | 33 +++---` (paraphrased, no quote available because this is command output, captured in `$X/git-checks.log` § "a760 merge-tree main"). `git diff a760a5e5 09a2876f` touches the same 19 files as `git diff 92f3b080 main`.

**Evidence:** `docs/working/questions.md:86`, `$X/git-checks.log`

---

## Claim 3: "its override-log rows are exactly the union of a760a5e5's and main's"

**Location:** `docs/working/questions.md:86`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the line multiset and order of `docs/reviews/override-log.md` at 09a2876f against a760a5e5, main and their base 92f3b080. It does not establish that the row content is right.
**Legibility-target:** for-orchestrator-synthesis

All four files share the base's 827 lines as a prefix. r2's tail is exactly main's 15 appended lines followed by a760a5e5's 23 (`r2 tail == main tail + a760 tail: True`). 827+15+23 = 865, which is r2's line count. No row is dropped or duplicated.

**Evidence:** `$X/count-checks.log` § "override-log union"

---

## Claim 4: "five of those nine merges (Q-110, doc drift, Q-160 and the two docs branches) conflict with an earlier one, each only in the append-only `docs/reviews/override-log.md`, and it resolves that by keeping both sides' rows"

**Location:** `docs/working/questions.md:84`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers replaying each of r2's nine merges with `merge-tree` over its recorded parents. It does not establish conflicts in any other merge order.
**Legibility-target:** for-orchestrator-synthesis

The q110, doc-drift, q160, branch-verify and dd-015 merges each exit 1 with `conflicts=[docs/reviews/override-log.md]`. Each recorded resolution differs from the conflicted tree by `3 deletions(-)`, which is just the conflict-marker lines, so both sides are kept. The t69, q096, rebuild-hint and one-workspace merges are clean, and each one's tree equals its commit's tree.

**Evidence:** `$X/git-checks.log` § "r2 first-parent merges and per-merge replay"

---

## Claim 5: Every cycle-record merge in a760a5e5 is already on main (implied by dropping "and this cycle's record" from Q-162)

**Location:** `docs/working/questions.md:84`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the ten `chore/dev-cycle-2026-10-15-0357` second parents in a760a5e5's first-parent chain. It does not establish anything about their content.
**Legibility-target:** for-orchestrator-synthesis

de9590ad, 8781b882, b9b4d59a, 5f0f00d9, 7550465b, d4445c9a, e1ad59fd, 3356974b, 782036de and 92f3b080 are all ancestors of main. The unchanged "Gate for the whole branch" line's "nine cycle-record merges" counts the nine that come after the 3fe6d6e3 gate; de9590ad comes before it.

**Evidence:** `docs/working/questions.md:103`, `$X/git-checks.log` § "cycle-record merges"

---

## Claim 6: "the first pin, a760a5e5, was built on b279a2ba and conflicted once Q-178 landed the 0357 cycle branch (in the override log, and before that landing in the questions, questions-archive, roadmap and idea-log files)"

**Location:** `docs/working/questions.md:86`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers merge-tree of a760a5e5 against main b71a4e9e and against the pre-Q-178 main 7f711bfe. It does not establish main tips other than those two.
**Legibility-target:** for-orchestrator-synthesis

Against main, the only conflict is `docs/reviews/override-log.md`. Against 7f711bfe, the conflicts are `docs/roadmap.md`, `docs/working/idea-log.md`, `docs/working/questions-archive.md` and `docs/working/questions.md`. a760a5e5's bottom first parent is b279a2ba.

**Evidence:** `$X/git-checks.log` §§ "a760 merge-tree main", "a760 merge-tree 7f711bfe"

---

## Claim 7: "the hash names fixed content once the paste has checked that no replace refs, `info/grafts` or `shallow` file exists, and the merge itself ignores replace refs"

**Location:** `docs/working/questions.md:84`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers what the pinned hash identifies: the guard refuses refs/replace/, info/grafts and shallow (also `GIT_GRAFT_FILE`, which `--git-path` follows), and the merge runs with `GIT_NO_REPLACE_OBJECTS=1`. It does not establish that the merge result equals the reviewed tree. Repo config can still change the result and run code, and the sentence does not claim otherwise.
**Legibility-target:** for-orchestrator-synthesis

The guard is quoted from `docs/working/questions.md:90`:
```
{ test -z "$(git for-each-ref refs/replace/)" && g="$(git rev-parse --git-path info/grafts)" && s="$(git rev-parse --git-path shallow)" && test ! -e "$g" && test ! -L "$g" && test ! -e "$s" && test ! -L "$s" || { echo "replace refs, info/grafts or shallow present: stop"; false; }; }
```
With `GIT_GRAFT_FILE=/x/y` set, `git rev-parse --git-path info/grafts` prints `/x/y`, so a relocated graft file is checked too (`$X/guard.log`, last line). Alternates do not weaken the sentence, because objects stay content-addressed (paraphrased, no quote available because this is a property of git's object model, not of repo code). The residual is outside the sentence. In `$X/repo` I planted `core.fsmonitor` and ran the Q-163 paste: the fsmonitor command ran (`pwned-fsmonitor`). I planted `* merge=evil` in `info/attributes` with a `merge.evil.driver` and ran the Q-164 paste: the driver ran (`pwned-driver`). The planted hooks did not run (Claim 15). So config planted in /workspace can run code during the paste and change the merged tree. The entry's own reason for running in the container ("where an agent session can plant hooks and config", `:84`) names this class, but no part of the paste neutralises it.

**Evidence:** `docs/working/questions.md:84,90-91`, `$X/guard.log`, `$X/driver.log`, `$X/driver2.log`

---

## Claim 8: "Paste the block into the container's shell … never in your host checkout: it runs git in `/workspace`"

**Location:** `docs/working/questions.md:84`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the fact that each of the three merge pastes starts with `cd /workspace` and that the prose says to run them in the container. It does not establish the container's mount layout, or that a `!` command in a cc-isolated session lands in that shell.
**Legibility-target:** for-orchestrator-synthesis

Each of the three blocks begins `cd /workspace && test "$(git branch --show-current)" = main` (`docs/working/questions.md:89`, `:118`, `:150`). Q-163 and Q-164 say "run it in the container's shell, as for Q-162" (`:115`, `:147`). This closes prior finding F2.

**Evidence:** `docs/working/questions.md:84,89,115,118,147,150`

---

## Claim 9: "Run it before Q-163 and Q-164: their pastes stop unless this merge is on main" / Q-163 and Q-164: "only after Q-162's paste (it stops otherwise)"

**Location:** `docs/working/questions.md:84,115,147`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the ancestor check on a clone at main b71a4e9e, under bash and zsh. It does not establish behaviour when main already holds 09a2876f by some route other than this paste. The check would then pass, as intended.
**Legibility-target:** for-orchestrator-synthesis

Line `:120`/`:152` reads `{ git merge-base --is-ancestor 09a2876ff5ea6f7e5b86eea723c2aa0094759145 HEAD || { echo "Q-162's merge is not on main: run it first"; false; }; }`. Run on main before Q-162, the Q-163 paste under bash printed that message and exited 1, as did the Q-164 paste under zsh. HEAD stayed b71a4e9e.

Commands: `timeout 60 bash $X/Q-163.sh` and `timeout 60 zsh $X/Q-164.sh` (both blocks extracted verbatim from 46342d66 with `cd /workspace` rewritten to `cd $X/repo`), cwd `$X/repo`, 2026-10-15T14:01:07-07:00, both exit=1.

**Evidence:** `docs/working/questions.md:120,152`, `$X/run.log`

---

## Claim 10: "Gate for the rebuilt tip (09a2876f, 2026-10-15): the fast suites had one red, build-loop-merge's T23 test, whose log shows the Q-145 `/tmp` race (`find: '/tmp/bats-run-…': No such file or directory`); it passes 3/3 alone. The slow suites, run separately: 300/300. Shellcheck and the other checks passed."

**Location:** `docs/working/questions.md:104`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the content of the two logs and my own 3/3 re-run of that test at 09a2876f. It does not establish that the health log was produced at 09a2876f, because the log records no commit (hence Medium).
**Legibility-target:** for-orchestrator-synthesis

`health-ready-r2.log` has exactly one `not ok` line: `not ok 1103 --merge refuses a file or link where the merge adds a directory, … (T23, U3a2; i1 security)` (line 1301). Line 1310 is `# find: '/tmp/bats-run-0FMk9A/bats.1565803.out': No such file or directory`. The only `✗` line is "Fast BATS suites failed". The shellcheck section has only `✓` lines, and the other sections show only `⚠` advisories (stale docs, skill fixtures). `slow-ready-r2.log` shows `1..300`, 300 `ok` and 0 `not ok`. My re-run of that test alone, 3 times, in a worktree of my clone at 09a2876f: `ok 1` each time.

Command: `timeout 300 bats -f 'merge refuses a file or link where the merge adds a directory' test/scripts/build-loop-merge.bats` ×3, cwd a detached worktree at 09a2876f (removed afterwards), 2026-10-15T14:02:53-07:00, exit 0 ×3.

**Evidence:** `/tmp/claude-1000/-workspace/736a173d-70f8-4751-993a-da117d91dc21/scratchpad/health-ready-r2.log:1301-1310`, `/tmp/claude-1000/-workspace/736a173d-70f8-4751-993a-da117d91dc21/scratchpad/slow-ready-r2.log:18`, `$X/t23-alone.log`

---

## Claim 11: "Q-180 rebuilt the branch and hardened this paste (its review: `docs/reviews/code-review-rubric-2026-10-15-chore-q180-repin-pastes.md`)"

**Location:** `docs/working/questions.md:105`
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** High
**Verification mode:** static
**Scope:** Covers whether the cited file exists at 46342d66. It does not establish whether the review in progress will write it under that name before landing.
**Legibility-target:** for-orchestrator-synthesis

The file does not exist in the worktree at 46342d66 (`ls`: "No such file or directory") (paraphrased, no quote available because the claim is about a file's absence). It is a forward reference to this review's rubric. It has to be committed on the branch before landing, or the Interim line points at nothing.

**Evidence:** `docs/working/questions.md:105`

---

## Claim 12: Q-163 paste: "`merge/q145-r2` at 35e13638 (Q-162's branch plus this unit …), or `merge/u5-and-q145-r2` at 6c841192 (that plus U5) if U5 is already on main … both orders of Q-163 and Q-164 were run against main and land the same tree. The unit's own tip, c035f2e7, is unchanged inside them."

**Location:** `docs/working/questions.md:115-122`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers branch composition, which branch the `if` picks in each order, and the final tree with the chore branch landed first. It does not establish an order that runs Q-163/Q-164 before the chore landing (they would still work, since the ancestor check needs only 09a2876f).
**Legibility-target:** for-orchestrator-synthesis

35e13638's parents are 09a2876f and c035f2e7. 7326d715's are 09a2876f and e088c7e3. 6c841192's are 35e13638 and 7326d715. Each merge's only conflict was `override-log.md`, resolved by deleting the markers (3 lines), except 7326d715 (Claim 13). In `$X/repo` I landed 46342d66 with `--no-ff`, ran the Q-162 paste (zsh), and from that state S ran both orders. Order A was Q-164 (bash), which picked 7326d715, then Q-163 (zsh), which picked 6c841192. Order B was Q-163 (bash), which picked 35e13638, then Q-164 (zsh), which picked 6c841192. `treeA=e12d4a6a…` = `treeB=e12d4a6a…` → `SAME-TREE`. Each `if git merge-base --is-ancestor <other unit's tip> HEAD` picked the combined branch exactly when the other unit was already on main. The final tree's Q-162, Q-163, Q-164, Q-167, Q-169, Q-170 and Q-176 entries are byte-identical to 46342d66's, so the U5 merge does not revert the hardened pastes. `questions.sh check` passes at both final tips (`$X/qcheck.log`).

Commands: `$X/run.log` (cwd `$X/repo`, 2026-10-15T14:01-07:00, every paste exit 0 apart from the expected stops; the Q-162 paste's trailing worktree loop exits 128 only because the clone has no `.claude/wt-build-loop-*` worktrees).

**Evidence:** `docs/working/questions.md:121`, `$X/run.log`, `$X/git-checks.log` § "u5/q145 branches", `$X/qcheck.log`

---

## Claim 13: Q-164 paste: "`merge/build-loop-u5-resolved-r2` at 7326d715 (Q-162's branch plus U5, by the earlier reviewed resolution e088c7e3, with the questions, roadmap and override-log conflicts resolved again: main's Next 3–6 kept and U5's C5 item added as 7, both Ideas lists kept, U5's decision-015 idea dropped since main's Next 5 holds it, indexes regenerated; U5's entries Q-103 and Q-149..Q-156 are byte-identical to e088c7e3's)"

**Location:** `docs/working/questions.md:147`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers merge-tree of 09a2876f with e088c7e3, the resolved roadmap, the entry bytes and the index check. It does not establish that the resolution of `questions-archive.md` was reviewed.
**Legibility-target:** for-author

`git merge-tree 09a2876f e088c7e3` conflicts in four files: `docs/reviews/override-log.md`, `docs/roadmap.md`, `docs/working/questions-archive.md` and `docs/working/questions.md`. The list in the claim omits `questions-archive.md`, whose conflict is in the index (the Q-178 and Q-154 rows; both are kept at 7326d715). That is the same omission Q-180 asked to correct in Q-162's list. The rest holds. The Next items at 7326d715 are main's 1–6 plus `7. **Revisit the light pass between full cycles (C5, Q-154).**`. e088c7e3's Next 3 ("Verify a branch…") and Next 5 ("Automate the host settings.json merge") are base text that main had already moved (the merge base 46942678 holds both). The Ideas bullet `Re-run decision 015's step 4 as a divergent design (Q-105 [3])` is absent at 7326d715, and main's Next 5 is `Decision 015's re-run: apply the outcome (Q-170)`. Both Ideas lists' bullets are kept. A heading-to-next-heading extraction finds Q-103, Q-149–Q-153, Q-155 and Q-156 (questions.md) and Q-154 (archive) `IDENTICAL` at 7326d715 and at 6c841192. `questions.sh check` passes at 7326d715. e088c7e3 adds nothing to r2 beyond U5's commits and itself (`rev-list e088c7e3 ^09a2876f ^7c91b974` = e088c7e3 only). Precise version: "the questions, questions-archive, roadmap and override-log conflicts".

**Evidence:** `docs/working/questions.md:147`, `$X/git-checks.log` §§ "u5/q145 branches", "roadmap Next", "entries", `$X/qcheck.log`

---

## Claim 14: The paste guard refuses replace refs, info/grafts and shallow, including an empty file and a dangling symlink, under bash and zsh, and in a linked worktree

**Location:** `docs/working/questions.md:90,119,151`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the guard line, identical in all three pastes, run alone in `$X/repo` and from a linked worktree. It does not establish replace refs under a non-default `GIT_REPLACE_REF_BASE` (the user's own environment). The merge is covered there by `GIT_NO_REPLACE_OBJECTS=1`, but the two ancestor checks are not.
**Legibility-target:** for-orchestrator-synthesis

Under each of bash and zsh, the baseline exits 0. Each of these exits 1 with "replace refs, info/grafts or shallow present: stop": `refs/replace/<HEAD>`, an empty `.git/info/grafts`, a dangling `info/grafts` symlink, an empty `.git/shallow`, and a dangling `shallow` symlink. In a linked worktree, `git rev-parse --git-path info/grafts` and `--git-path shallow` print `…/repo/.git/info/grafts` and `…/repo/.git/shallow`, the common dir and not `.git/worktrees/lwt`. A common-dir `shallow` stops the guard run from the linked worktree. This closes prior finding F1.

Command: `$X/guard.sh` (the guard line verbatim), cwd `$X/repo`, 2026-10-15T14:01:37-07:00.

**Evidence:** `docs/working/questions.md:90`, `$X/guard.log`

---

## Claim 15: The merge runs "with GIT_NO_REPLACE_OBJECTS=1 and hooks off" (commit 53bd1a56; `-c core.hooksPath=/dev/null`), and `git merge --abort` runs on failure

**Location:** `docs/working/questions.md:91,122,154`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers hooks: a planted `core.hooksPath` dir with `pre-merge-commit` and `post-merge` did not run. It does not establish that other config-borne commands are off (fsmonitor and merge drivers did run, see Claim 7), or what a merge failure that is not a conflict does.
**Legibility-target:** for-orchestrator-synthesis

The line is `{ GIT_NO_REPLACE_OBJECTS=1 git -c core.hooksPath=/dev/null merge --no-ff "$B" … || { git merge --abort; echo "conflict: merge aborted; …"; }; }` (`:122`). With `core.hooksPath=$X/hk` planted, the Q-163 paste merged (`Merge made by the 'ort' strategy.`, exit 0) and no `pwned-hook` file appeared. The command-line `-c` overrides the repo setting. In Q-163 and Q-164 the `||` branch has no `false`, so a conflict prints the message and the paste exits 0. Q-162's `||` branch ends in `false` (`:91`).

**Evidence:** `docs/working/questions.md:91,122,154`, `$X/driver.log`

---

## Claim 16: Landing `chore/q180-repin-pastes` first, then the pastes, does not conflict (checkpoint: "land `chore/q180-repin-pastes` …, then Q-162 …, then Q-164 [1] and, if wanted, Q-163, in either order")

**Location:** `docs/working/checkpoint-build-loop-handoff.md:10`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the order from main b71a4e9e as it stands today. It does not establish what happens if main moves before the pastes run.
**Legibility-target:** for-orchestrator-synthesis

`git merge --no-ff 46342d66` on main exits 0. The Q-162 paste then merges 09a2876f cleanly (`468c6bd8`, parents `900badf4 09a2876f`), and both orders follow as in Claim 12.

**Evidence:** `$X/run.log`

---

## Claim 17: Q-167(b): "each of the first three must print an ERROR and `exit=2` with nothing done (on a launcher older than the fix, the third prints the project list instead …)" with line 3 `cc-isolated --profile '#' --list; echo "exit=$?"`

**Location:** `docs/working/questions.md:220,225`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers line 3 against main's launcher and the fixed one (f6f37fad's file, identical at 09a2876f), run with a scratch HOME. It does not establish lines 1-2, or the host's installed launcher.
**Legibility-target:** for-orchestrator-synthesis

Main's parser sets `profiles="$2"` and then `--list)       action="list"` (`devcontainer-config/cc-isolated.sh:737,745` at main), and `list)  list_projects;  exit 0 ;;` (`:789`). The run printed "No projects registered …" with exit 0, a harmless listing in place of the bless. The fixed parser has `\#*) pasted_note_error "$2" "an egress profile" ;;` (`:796` at f6f37fad), which reaches `exit 2` in `arg_usage_error` (`:759-764`). The run printed `ERROR: \# is not an egress profile; it looks like a pasted comment.` with exit 2. This closes prior finding F3.

Command: `HOME=$X/home timeout 30 bash <wt>/devcontainer-config/cc-isolated.sh --profile '#' --list`, run in worktrees at b71a4e9e and 09a2876f, 2026-10-15T14:03:43-07:00, exit 0 and exit 2 respectively.

**Evidence:** `devcontainer-config/cc-isolated.sh:737-789` (main), `devcontainer-config/cc-isolated.sh:759-796` (f6f37fad), `$X/q167.log`

---

## Claim 18: Q-169 pins `d25254dae30f…`; the extracted block's hash "must be `032cc9a8…afb7`"; "498 lines with its fences"; "Not verified" (12 items)

**Location:** `docs/working/questions.md:260-270`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the hash and line count of the awk extraction at d25254da and the count of numbered items under "Not verified". It does not establish the block's runtime behaviour.
**Legibility-target:** for-orchestrator-synthesis

The paste's own extraction prints `032cc9a81e4e1c9266ec3ad3b5fe7053d9876eb21f5ffa7f0a35f2ccfed4afb7`. The block is 496 lines, 498 with its fences. `docs/branch-verify-without-install` = d25254da. The spike file is byte-identical at a760a5e5 and at 09a2876f. `## Not verified (needs the host run)` lists items 1–12.

**Evidence:** `docs/working/questions.md:263,267,270`, `$X/count-checks.log` § "Q-169"

---

## Claim 19: Q-170: "since 2026-09-09 88 of 116 `devcontainer-config/` commits carry `Live-verified: no`"

**Location:** `docs/working/questions.md:280`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `git log --no-merges --since=2026-09-09 f050b487 -- devcontainer-config/` with a `^Live-verified: no` body match. It does not establish the DD doc's own figure, which still reads 87.
**Legibility-target:** for-orchestrator-synthesis

The command prints `f050b487 total=116 lvno=88`. The entry's Read doc still says "**87 carry `Live-verified: no` and 1 carries a hash**" (`docs/working/dd-015-step4-isolation-mechanism.md:34` at f050b487). The entry and the doc it points to now disagree by one. That is not within this diff's lines, but a reader comparing them will notice.

**Evidence:** `docs/working/questions.md:280`, `$X/count-checks.log` § "Q-170"

---

## Claim 20: Q-176: `mkdir ~/q092 && mkdir ~/q092/.claude && …` "also stops if `~/q092` already exists, so nothing planted there is reused"

**Location:** `docs/working/questions.md:390,406`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the first two commands of the paste with `~/q092` pre-planted as a directory, a symlink to a directory, a dangling symlink, or a file, under bash and zsh. It does not establish a race where `~/q092` is planted between the two `mkdir` calls.
**Legibility-target:** for-orchestrator-synthesis

All eight planted cases print `mkdir: cannot create directory …: File exists` and exit 1 without reaching `CONTINUED`. The absent case continues (exit 0). This closes prior finding F4.

Command: `HOME=$X/h176-<kind>-<sh> <sh> -c 'mkdir ~/q092 && mkdir ~/q092/.claude && echo CONTINUED'`, 2026-10-15T14:03:56-07:00.

**Evidence:** `docs/working/questions.md:390`, `$X/q176.log`

---

## Claim 21: "Cycle 2 (2026-10-14): 42 multi-file landings after cac2ba0c (cycle 1's own three landings excluded); 25/42 carry the line, 38/42 committed a rubric, 4/42 have neither (df18413a, 0fbf9742, b8807e76, 52053432)"

**Location:** `docs/roadmap.md:77-80`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers first-parent merges in `cac2ba0c..b279a2ba` that touch more than one file, a body grep for `← carried from RPI`, and the name grep `^docs/reviews/code-review-rubric`. It does not establish other window ends.
**Legibility-target:** for-orchestrator-synthesis

The command prints `n=42 line=25 rubric=38 neither= df18413a 0fbf9742 b8807e76 52053432`. 90364c73 and 188e0a7d are at or before cac2ba0c, so "after cac2ba0c" already excludes all three cycle-1 landings.

**Evidence:** `docs/roadmap.md:77`, `$X/count-checks.log` § "roadmap cycle-2 tally"

---

## Claim 22: Checkpoint: "U4c merged at 308196e7 (Q-144 [1]); U5 built and reviewed on `feat/build-loop-u5` (tip 7c91b974, loop ended escalate, narrow check held), not merged … it lands inside `merge/build-loop-u5-resolved-r2` 7326d715 or `merge/u5-and-q145-r2` 6c841192"

**Location:** `docs/working/checkpoint-build-loop-handoff.md:2-3`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers ancestry, the Q-144 archive answer and the U5 rubric's loop decision. "Narrow check held" is read as Q-164's 2026-10-15 option-[2] narrow check, which the entry records as passing.
**Legibility-target:** for-orchestrator-synthesis

308196e7 is on main, and the Q-144 archive entry reads `**Answer (2026-10-14, in session):** [1] … Merged at 308196e7.` 7c91b974 is not on main and is an ancestor of both 7326d715 and 6c841192. The U5 rubric on the branch reads `**Loop decision (iteration cap): \`escalate\`.**` (`docs/reviews/code-review-rubric-2026-10-14-feat-build-loop-u5.md:154` at 7c91b974). Q-164 reads "Option [2]'s narrow check was run on 2026-10-15 … It refused the local, worktree, included … cases" (`docs/working/questions.md:138`).

**Evidence:** `docs/working/checkpoint-build-loop-handoff.md:2-3`, `docs/working/questions.md:138`, `$X/git-checks.log` § "u3a1..u4c merged; u5"

---

## Claim 23: Checkpoint: "The first Q-162 paste on 2026-10-15 aborted on the override-log conflict, as its note said (a760a5e5 predated Q-178's landing); main was left clean."

**Location:** `docs/working/checkpoint-build-loop-handoff.md:10`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers /workspace's reflog, the absence of MERGE_HEAD, and the merge-tree result for a760a5e5 against main. The user's run itself is not replayable, so the evidence is circumstantial (Medium).
**Legibility-target:** for-orchestrator-synthesis

`HEAD@{2026-10-15 13:43:41 -0700}: reset: moving to HEAD` follows the 13:28:41 Q-178 merge. That is the reflog shape `git merge --abort` leaves. `main` has not moved since b71a4e9e, `.git/MERGE_HEAD` is absent, and merge-tree of a760a5e5 with main conflicts only in `override-log.md` (Claim 6).

**Evidence:** `$X/count-checks.log` § "main reflog", `$X/git-checks.log` § "a760 merge-tree main"

---

## Claim 24: Checkpoint: "U5 was built and reviewed on 2026-10-14 (rubric `docs/reviews/code-review-rubric-2026-10-14-feat-build-loop-u5.md` on the branch)"

**Location:** `docs/working/checkpoint-build-loop-handoff.md:48`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the existence of the rubric path in 7c91b974's tree and the commit date. It does not establish the rubric's content beyond the loop decision.
**Legibility-target:** for-orchestrator-synthesis

`git ls-tree -r --name-only 7c91b974` lists `docs/reviews/code-review-rubric-2026-10-14-feat-build-loop-u5.md`. 7c91b974's date is `Wed Oct 14 23:10:34 2026 -0700`.

**Evidence:** `docs/working/checkpoint-build-loop-handoff.md:48`

---

## Claim 25: Checkpoint: "Q-149..Q-155 and Q-103 become the live asks"

**Location:** `docs/working/checkpoint-build-loop-handoff.md:48`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers where those entries sit once U5 lands (7326d715). It does not establish which of them the user will answer.
**Legibility-target:** for-author

At 7326d715, Q-103, Q-149–Q-153 and Q-155 are open entries in `docs/working/questions.md` (`### Q-103` at :492, `### Q-150` at :690, … `### Q-155` at :755). Q-154 is in `docs/working/questions-archive.md` (`### Q-154 · build-loop-c5-cycle-cost` at :2730), which means it is already answered and not a live ask. Precise version: "Q-149..Q-153, Q-155 and Q-103 (Q-154 is answered)".

**Evidence:** `docs/working/checkpoint-build-loop-handoff.md:48`

---

## Claim 26: Commit messages 53bd1a56 and 46342d66 (branch names and hashes; guard; container wording; "both orders were run against main and land the same tree"; Q-167(b), Q-176, Q-169 "same block hash", "12 items, 88 of 116"; ready-r2 gate; "rebuilt as -r2 branches rather than force-moving the reviewed ones"; the paste order; "the first Q-162 paste aborted cleanly on the stale pin")

**Location:** commits `53bd1a56`, `46342d66` (`git log main..HEAD`)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each factual item in both bodies against Claims 1-23. It does not establish the Confidence/Notes judgments.
**Legibility-target:** for-orchestrator-synthesis

The four `-r2` hashes match their refs. The old branches still exist at their old hashes (`merge/ready-2026-10-15` a760a5e5, `merge/u5-and-q145` a04d9776, `merge/build-loop-u5-resolved` 0f94bb77), so nothing was force-moved. Every other item is verified in the claim noted: guard and hooks (14, 15), both orders (12), Q-167(b) (17), Q-176 (20), Q-169 (18), counts (19, 21), gate (10), paste order (16), abort (23). The note that the Q-162-first check was "not in Q-180's list" matches Q-180's entry, whose work list has no such item (`docs/working/questions.md:441-450`).

**Evidence:** `$X/git-checks.log` § "branch tips", `docs/working/questions.md:441-450`

---

## Claim 27: Q-180: "**Blocks:** the pastes of Q-162, Q-163, Q-164, Q-167, Q-169 and Q-176. Each says so in its Interim." / "**Interim:** every merge paste aborts on today's main or once Q-178's landing is on main"

**Location:** `docs/working/questions.md:451-452`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers Q-180's text as left by this branch, against the Interims the branch edited and the pastes' current behaviour. It does not establish whether the landing process closes Q-180 in the same commit.
**Legibility-target:** for-author

This branch deletes "Do not run this entry's paste until Q-180 is done." from all six Interims (diff lines 72, 102, 130, 154, 172, 209). So "Each says so in its Interim" is no longer true. The re-pinned pastes no longer abort on today's main: the Q-162 paste merges cleanly (Claim 16). So "every merge paste aborts on today's main" is false at 46342d66. Q-180 remains `**Status:** OPEN` and `**Needs:** agent`. Its Blocks and Interim should be closed or rewritten when the branch lands.

**Evidence:** `docs/working/questions.md:438-452`, `$X/run.log`

---

## Claims Requiring Attention

### Incorrect
- None.

### Stale
- **Claim 27** (`docs/working/questions.md:451-452`): Q-180's Blocks ("Each says so in its Interim") and Interim ("every merge paste aborts on today's main") describe the state before this branch. Close Q-180 or rewrite both lines on landing.

### Mostly Accurate
- **Claim 13** (`docs/working/questions.md:147`): the U5-resolution conflict list omits `questions-archive.md`. Say "questions, questions-archive, roadmap and override-log".
- **Claim 25** (`docs/working/checkpoint-build-loop-handoff.md:48`): Q-154 is already answered (archived). Say "Q-149..Q-153, Q-155 and Q-103".
- (Within a Verified claim) **Claim 19**: Q-170 now says 88 while its Read doc, `dd-015-step4-isolation-mechanism.md:34`, still says 87. Consider a note.

### Unverifiable
- **Claim 11** (`docs/working/questions.md:105`): the cited rubric `code-review-rubric-2026-10-15-chore-q180-repin-pastes.md` does not exist at 46342d66. Commit it on the branch before landing.

### Residual noted inside a Verified claim (for the security critic)
- **Claim 7 / 15**: with hooks off and replace refs ignored, a `core.fsmonitor` or a `merge.<x>.driver` with `info/attributes` planted in /workspace still ran code during the Q-163 and Q-164 pastes (executed in `$X/repo`). A driver can also change the merged tree. The prose does not claim otherwise, because it names planted config as the reason to paste in the container. But no part of the paste guards against it.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report at the output path you were given, structured per your skill.
- Answered: yes. All 12 brief claim groups were checked, 23 of the 27 claims by execution (pastes run for real in a local clone, both orders, both shells).
- Out of scope: the host-only parts (a `!` command reaching the container shell, the installed launcher on the host) and code-quality judgments.
- Escalate: Claim 27 (Q-180's own Blocks/Interim go stale on landing). Claim 11 (the forward-referenced rubric must be committed). The fsmonitor/merge-driver residual (Claim 7) goes to the security critic.
- Decisions I made: I read "narrow check held" as Q-164's option-[2] narrow check. I read "questions" in Claim 13 as questions.md only, which is why it is Mostly accurate. Claim 7 is Verified on the sentence's narrow subject (what the hash names), not the merge result.
