# Harness feedback

Project: philosophy-research

### F-001 · digest-misses-watching-file
**Feature:** dev-cycle digest (questions.sh open) · **Date:** 2026-10-29 · **Verdict:** fails

- **Context:** the first dev-cycle iteration after migration `questions-owner-routes-040` had moved every `deferred` entry out of `docs/working/questions.md` into `docs/working/watching.md` (`64c8e850`).
- **Expected:** the digest's section 3, "Watched questions (trigger and deferred routes)", lists the open `deferred` and `trigger` watches, which now live in `watching.md`.
- **Observed:** section 3 printed "None open" while `watching.md` held three OPEN `deferred` entries (Q-058, Q-079, Q-091). The image's `cmd_open` runs `parse_entries "$LIVE"` only, and `dev-cycle.sh` filters that output for the two watch routes, so the watches the migration moved are never seen. Step 3 was done by hand from `watching.md`.
- **Evidence:** `/opt/claude-workflows/scripts/questions.sh` `cmd_open`; `/opt/claude-workflows/scripts/dev-cycle.sh` lines 408–415; the image's manifest commit is `fe57e35`; the record is `docs/working/cycles/cycle-2026-10-29.md`, iteration 2026-10-30-0050, step 3.

### F-002 · cycle-cannot-create-feedback-file
**Feature:** dev-cycle path rules vs. the global harness-feedback instruction · **Date:** 2026-10-29 · **Verdict:** friction

- **Context:** the same iteration found F-001 and went to file it here, as the global instructions' "Harness feedback" section asks, but the project had no `docs/harness-feedback.md` yet.
- **Expected:** a harness failure found during a cycle can be recorded in the project's feedback file within that cycle.
- **Observed:** the dev-cycle skill lets an in-cycle fix edit only a file that `--check-fix` prints `ok` for, and `--check-fix` refuses every new file. So the cycle could not create the file. The finding went to the roadmap's Ideas and the idea log instead, and the owner created the file by hand (`72e3e6ea`).
- **Evidence:** the dev-cycle skill's "Paths from repo text" rule; `docs/roadmap.md` Ideas ("Report to claude-workflows that the digest's watched-questions section misses `watching.md`"); `72e3e6ea`.

### F-003 · brainstorm-refires-same-trigger
**Feature:** dev-cycle step 5 (brainstorm) · **Date:** 2026-10-29 · **Verdict:** friction

- **Context:** two iterations ran 10 minutes apart (2026-10-30-0040 and -0050 UTC), and Now held no item ready for a brief in either.
- **Expected:** a brainstorm runs when it can produce new ideas.
- **Observed:** "Roadmap Now holds 0–1 items ready for a build brief" fired again in the second iteration with Now unchanged, so the brainstorm ran twice on one day for one signal. The second added one idea, and that idea came from that iteration's own finding (F-001), not from the trigger.
- **Evidence:** `docs/working/cycles/cycle-2026-10-29.md`, both iterations' `5.` lines; `docs/working/idea-log.md`, the two `## Brainstorm 2026-10-29` headings.

### F-004 · answers-file-not-read-by-gate
**Feature:** dev-cycle step 7 (`--check-answer`) vs. this project's answer channel · **Date:** 2026-10-29 · **Verdict:** friction

- **Context:** the author answers questions in `docs/human-author/answers-<date>.txt`. On 2026-10-29 they committed `answers-10-28-26.txt` to `master` (`32b2230d`). It answers the three merge entries Q-118, Q-119 and Q-121 with `[1]` (merge).
- **Expected:** an answer the author has committed reaches the build loops it unblocks.
- **Observed:** `--check-answer` reads answers only from `docs/working/questions.md` and its archive on the default branch, so all three still read `open`. The cycle cannot transcribe them, because `--answered` is reserved for answers the user gives in the session, never ones read from repo text. Three ready branches have now waited since 2026-10-20, and their answers have sat in the repo since 2026-10-28.
- **Evidence:** `docs/human-author/answers-10-28-26.txt` at `32b2230d`; iteration 2026-10-30-0111 of `docs/working/cycles/cycle-2026-10-29.md`, step 7.

### F-005 · answers-read-from-questions-file-only
**Feature:** dev-cycle answer intake (`--check-answer`, `--answered`) · **Date:** 2026-10-29 · **Verdict:** friction

- **Context:** the owner asked for this entry after the 2026-10-30-0111 iteration reported: "The cycle only reads answers from `docs/working/questions.md` on master." F-004 records the instance. This entry records the rule behind it.
- **Expected:** the questions protocol says answering costs one line, written "anywhere — a reply, a file, a commit". An answer the owner writes in a file or commit should reach the cycle.
- **Observed:** the cycle reads an answer only from an entry in `docs/working/questions.md` or `questions-archive.md` on the default branch, and only when its header reads `**Status:** ANSWERED` and it holds a `Q-NNN:` or `**Answer…` line. It reads nothing from a separate answers file, a commit message, or an answer written in a working tree. The one other way in is `--answered`, for an answer the owner gives in the session. So an owner answering in a file must also edit the entry, or repeat the answer in chat, before anything moves.
- **Evidence:** `check_answer` and its header comment in `/opt/claude-workflows/scripts/lib/dev-cycle-read.sh`; the "Running questions document" section of the global instructions; F-004.

### F-006 · approved-merge-refused-by-newer-gate-rule
**Feature:** `build-loop.sh --merge --approved` failure-pattern checks · **Date:** 2026-10-29 · **Verdict:** friction

- **Context:** two build loops finished on 2026-10-20, and the author approved both merges (Q-119 and Q-121 `[1]`). The image's gate now checks each branch's research doc for a `Failure-pattern grep:` line, and checks `fix(...)` commits for an `FP-NNN` entry or a `Failure-pattern skip:` line. Neither check existed when the loops ran.
- **Expected:** a merge the author approved after reading its diff lands. Or `--check`, which wrote the merge entry, reports the gap first, so the author is not asked to approve something the gate will refuse.
- **Observed:** `--merge --approved` refused both on those gaps. The skill files that refusal as `stopped`, so each needs a second author answer (re-dispatch, Q-129 and Q-130), another loop run to add one or two process lines, and a third answer on the new merge entry. Census-ceiling (Q-118), approved at the same time, merged, because its branch had no gap.
- **Evidence:** the `refuse … failure-pattern gaps` and `gap` lines quoted in Q-129 and Q-130; iteration 2026-10-30-0122 of `docs/working/cycles/cycle-2026-10-29.md`, step 7; merge `1e3aaf00`.

### F-007 · judgment-entry-buries-the-decision
**Feature:** questions entry grammar (`you: judgment`) as the dev cycle writes it · **Date:** 2026-11-01 · **Verdict:** fails

- **Context:** Q-133 asked the owner how to apply a 566-line regrade report. Its options were "answer D1–D16 first", "rule-free moves now" or "hold".
- **Expected:** a judgment entry that the owner can answer from the entry, with each decision it depends on stated there or reached by a direct link, and a route only when the call is really theirs.
- **Observed:** the owner's words: "a horrible question, referencing a huge amount of other text without giving links/pointers for me to understand the text. D1–D16 are buried in an enormous markdown sheet, which in turn has very brief summarized decisions which will require me to take in far more context, which does not have reference links/pointers itself." The entry also gave a wrong reason why the call was theirs. It cited constraint H1 for Proof-mark changes, but H1 covers changes of meaning, not of working status. So the whole entry should not have been routed to the owner.
- **Evidence:** Q-133 in `docs/working/questions.md`; `docs/working/report-2026-10-30-proof-regrade-candidates.md` §4; the owner's answer of 2026-11-01. Suggested harness change: the entry grammar should require each sub-decision an option depends on to sit in the entry, or behind a line-anchored link. It should also require the "Why it's yours" line to quote the constraint text it relies on.

### F-008 · self-merge-floor-refuses-routine-research-output
**Feature:** `build-loop.sh` self-merge floor (`docs/thoughts/` as a record) · **Date:** 2026-11-01 · **Verdict:** friction

- **Context:** this repo's policy is `Build-loop policy: self-merge`, with `Self-merge never: none`. Here, `docs/thoughts/` holds the theorem catalog and the results notes. Every Lean build must update them (the project instructions' Theorem Atlas rule).
- **Expected:** with self-merge set, a finished Lean loop lands without an owner review.
- **Observed:** the floor refuses every `docs/thoughts/` path as "the user's and the cycle's records". So each Lean brief became `Policy: review`, and each finished loop became a merge entry (Q-118–Q-121, Q-131, Q-135–Q-137). The owner then wrote: "this repo's policy is self-merge, NOT review". Workaround from 2026-11-01: briefs keep `docs/thoughts/` off their `Paths:`. The loop hands its catalog and results text over in its research doc, and the orchestrator applies it by hand after the self-merge.
- **Evidence:** `floor()` in `/opt/claude-workflows/scripts/lib/dev-cycle-read.sh` (the `docs/thoughts/*` → `record` line); `docs/dev-cycle.md`; briefs `docs/working/briefs/2026-11-01-*.md`. Suggested harness change: a per-repo setting that marks floor directories as routine output.

### F-009 · loop-may-not-merge-default-branch-in
**Feature:** `build-loop.sh --prompt` / `--start` dispatch text ("never … merge") · **Date:** 2026-11-01 · **Verdict:** friction

- **Context:** four finished loop branches fell behind master while they waited on owner answers. When `--merge --approved` refused them for conflicts with the default branch, the skill filed each one as `stopped` (Q-138–Q-140). The re-dispatched prior-art loop then fixed its own gap, but its branch also conflicted.
- **Expected:** a re-dispatched loop merges the default branch into its own branch, resolves the conflict, re-runs its gates and reports ready, as the gate's own refusal suggests ("merge the default branch into HEAD first").
- **Observed:** the dispatch prompt says "never send your branch to a remote, merge, open a pull request or publish". Two loops read this differently on the same day:
  - the prior-art loop read it as forbidding a merge into its own branch, and ended `blocked` asking for permission (Q-141);
  - the count-drift loop merged the default branch in (`d106f791`) and reported ready.

  Where a loop takes the strict reading, every conflict costs the owner two answers before the merge answer: re-dispatch, then permission to merge in.
- **Evidence:** the prior-art loop's marker at `3842eaf0` on `lit/prior-art-92-94`; `build-loop.sh` line 1862 (the prompt text) and line 2243 (the refusal text). Suggested harness change: the prompt allows merging the default branch into the loop's own branch, and only forbids merging into the default branch.

### F-010 · generated-count-lines-conflict-approved-review-branches
**Feature:** `build-loop.sh --check`/`--merge` conflict refusal, with the dev-cycle `stopped` route · **Date:** 2026-11-02 · **Verdict:** friction

- **Context:** this repo's theorem catalog has a generated `README.md` whose count lines (entries, edges, class counts) change with every catalog edit. Review-policy loops (they write `docs/thoughts/`) regenerate it, and so does each self-merge loop's by-hand catalog follow-up.
- **Expected:** once the owner has approved a branch's content, master moving under it only in generated files is resolved mechanically.
- **Observed:** a catalog follow-up that lands before a ready review branch is merged makes `--check` refuse that branch, and the skill files it as `stopped` for the owner. On 2026-11-02 that happened to regrade gaps (Q-146) right after its Q-139 re-dispatch. Orbit's fresh merge entry (Q-145) went stale within minutes on a results-section number. Each round costs the owner a re-dispatch answer and then a merge answer, while the approved content does not change.
- **Evidence:** `git merge-tree master 44d80bab` (the conflict is only in `docs/thoughts/theorem-catalog/README.md`); `af510ecb`; Q-145, Q-146 and Q-147 in `docs/working/questions.md`. Suggested harness change: a stop whose conflicting paths a repo setting lists as generated (or that only renumber sections) is re-dispatched to merge the default branch in without an owner entry, within the dispatch cap. Or the gate regenerates such files at merge time.

### F-011 · subagent-report-file-refused
**Feature:** `parallel-worktrees` workflow, subagent writes under `docs/` · **Date:** 2026-11-05 · **Verdict:** friction

- **Context:** a batch fan-out gave a subagent an isolated worktree and told it to write and commit a report under `docs/thoughts/`, as the workflow says ("commit its work inside its worktree").
- **Expected:** the subagent commits its deliverable in its worktree.
- **Observed:** the Write tool refused the file: "Subagents should return findings as text, not write report files." The same subagent's handoff under `docs/working/` was accepted. The report came back in the final message, and the parent placed it by extracting the text from the transcript. A second unit worked around it by committing a draft under `docs/working/` and letting the parent move it.
- **Evidence:** Q-144 unit's hand-back, 2026-11-05; `docs/thoughts/report-2026-11-05-colony-agency-and-closure.md` placed at `909c04a8`; the Q-123 unit's draft moved in `f8b18d9f`.

### F-012 · loop-idle-on-monitor-reads-as-running
**Feature:** build-loop stall rule (dev-cycle step 7) with subagents waiting on background work · **Date:** 2026-11-05 · **Verdict:** friction

- **Context:** the orchestrator dispatched three loops and told them to wait for a warm-build file before copying it. Two went idle for about two hours, one of them right after loading the `Monitor` tool, while the agent list still said `running`.
- **Expected:** a loop waiting on something that has already happened wakes at once, or an idle loop can be told apart from a working one.
- **Observed:** `SendMessage` queued until the next tool round and did not wake them. The two-hour rule stopped one, at about the moment it may have been waking; the other woke by itself and finished cleanly. Separately, a loop that ended its turn with a reviewer still running got a `[handback-send-enforce]` message and handed back early, with no marker. Loops later told to run in the foreground finished in 30 to 60 minutes.
- **Evidence:** transcript gaps 03:22→05:20 and 03:26→05:23 UTC on 2026-11-06; Q-160; `docs/working/cycles/cycle-2026-11-05.md`.

### F-013 · subagent-tool-call-never-returns
**Feature:** build-loop stall rule (dev-cycle step 7) with background subagents · **Date:** 2026-11-07 · **Verdict:** friction

- **Context:** three build loops ran as background subagents. A fourth had gone quiet earlier the same night for about two hours and woken by itself.
- **Expected:** a subagent's tool call returns, or fails, and the loop continues.
- **Observed:** each loop's transcript ended on a `tool_use` with no result (`Bash` 03:43, `Skill` 03:53, `Bash` 04:26 local). None woke by 06:28, although the orchestrator's own commands ran normally and the audit loop's background job had finished at 04:16. The two-hour rule stopped all three. The orchestrator held the first two past their limit to make one decision, since F-012 showed a stalled loop can wake. The cause is not known.
- **Evidence:** subagent transcripts of session 1363cdff, 2026-11-07; Q-167 to Q-169; `docs/working/cycles/cycle-2026-11-07.md`.

### F-014 · locked-loop-worktree-blocks-branch-cleanup
**Feature:** build-loop worktree lock with dev-cycle step 1's merged-branch cleanup · **Date:** 2026-11-07 · **Verdict:** friction

- **Context:** the gate locks each build loop's worktree. Step 1 deletes merged branches with `git branch -d` and never prunes a locked worktree, since a locked one may be a live loop's.
- **Expected:** once a loop's branch has self-merged and its brief reads `done`, its worktree is released, so the next cycle can delete the merged branch.
- **Observed:** the lock stays after the merge. `git branch -d` refuses each such branch ("checked out at"), so merged branches pile up until the owner runs a removal paste. That happened with Q-155 (39 branches) and Q-157, and on 2026-11-07 three more merged `lean/*-2026-11-07` branches were refused.
- **Evidence:** `git worktree list` shows `.claude/wt-2026-11-07-audit-axioms-hardening`, `-lean-ladder-monotonicity` and `-lean-vcg-player-set` as `locked`; their briefs are under `docs/working/briefs/closed/` and read `done`; `docs/working/cycles/cycle-2026-11-07.md`, iteration 2026-11-08-0558. Suggested harness change: `--merge` (or step 6's close of a `done` brief) unlocks and removes the loop's worktree.

### F-015 · identity-check-misses-environment-identity
**Feature:** dev-cycle Rules, "The orchestrator's git" identity check · **Date:** 2026-11-10 · **Verdict:** friction

- **Context:** the sandbox supplies the commit identity through `GIT_AUTHOR_NAME`, `GIT_AUTHOR_EMAIL`, `GIT_COMMITTER_NAME` and `GIT_COMMITTER_EMAIL`; no git config file sets `user.name` or `user.email`.
- **Expected:** the skill's identity check passes when git has a real identity, as the gate's own check does (`merge_ident` in `build-loop.sh` reads the environment's variables first, then git config).
- **Observed:** the skill says `git -C WT config user.email` and `user.name` "must each print one (none: a stop)". Both print nothing here, so the rule as written stops every iteration, although git would not make an identity up: `git var GIT_AUTHOR_IDENT` succeeds and gives the same author as the last cycle land. The iteration went on, on the gate's reading, and says so in its record.
- **Evidence:** `git config --show-origin --get-regexp '^user\.'` prints nothing; `/opt/claude-workflows/scripts/build-loop.sh` lines 464, 1542 and 1613; `docs/working/cycles/cycle-2026-11-10.md`, iteration 2026-11-10-1903, step 0. Suggested harness change: the skill checks `git var GIT_AUTHOR_IDENT` and `GIT_COMMITTER_IDENT` with `user.useConfigOnly`-style strictness, or names the environment variables as the gate's header does.

### F-016 · health-checkout-has-no-build-cache
**Feature:** dev-cycle step 1, the health checkout HC · **Date:** 2026-11-10 · **Verdict:** friction

- **Context:** step 1 runs the repo's health check from a fresh detached worktree HC. This repo's check runs `lake build Philos`, whose cache (`verifier/lean-project/.lake`, gitignored: Mathlib's packages and 1.9 GB of built `Philos` modules) exists only in the main checkout.
- **Expected:** the health check runs in HC at about the cost it has in a warm checkout.
- **Observed:** a fresh HC has no `.lake`, so the check would rebuild Mathlib and 304 modules from nothing. The iteration symlinked `.lake/packages` to the main checkout's and copied `.lake/build` and `.lake/config` into HC before starting (the build loops' own recipe); the Lean gate then took 96 s. The skill names no such preparation, and "nothing else names HC" reads as forbidding it.
- **Evidence:** `docs/working/cycles/cycle-2026-11-10.md`, iteration 2026-11-10-1903, step 1; health log `PASS lean (96s)`. Suggested harness change: a per-repo hook or settings line that prepares HC (a command, or paths to link or copy from the main checkout).

### F-017 · free-worktrees-releases-finished-loops
**Feature:** `build-loop.sh --free-worktrees` in dev-cycle step 1 · **Date:** 2026-11-10 · **Verdict:** works

- **Context:** F-014 reported that a finished loop's locked worktree blocked `git branch -d` on its merged branch. Three such worktrees were left from 2026-11-07.
- **Expected:** the cycle frees them without a paste from the owner.
- **Observed:** `--free-worktrees` printed three `freed` lines, and `git branch -d` then deleted the three merged `lean/*-2026-11-07` branches.
- **Evidence:** `docs/working/cycles/cycle-2026-11-10.md`, iteration 2026-11-10-1903, step 1; `git worktree list` afterwards shows only the main checkout and the iteration's worktree.

### F-018 · no-worktree-sandbox-stops-cycle-unfiled
**Feature:** dev-cycle step 0.3 (the iteration's worktree) and the stop rule · **Date:** 2026-11-12 · **Verdict:** fails

- **Context:** `/loop /dev-cycle` in a session whose Bash sandbox mounts the repository's `.git/worktrees` and `.git/config` read-only (new in this session; the sessions of 2026-11-12 earlier in the day made worktrees freely). `--state` printed `ok` and `--main-log` listed one `chore` line, so the iteration was a light pass.
- **Expected:** the iteration makes its worktree WT and runs; or, when it cannot, the stop is filed where the next session finds it.
- **Observed:** `git worktree add -b chore/dev-cycle-2026-11-13-0037 …` created the branch and then failed with `fatal: could not create directory of '/workspace/.git/worktrees/wt-dev-cycle-2026-11-13-0037': Read-only file system`. The harness's own worktree tool also refused ("could not confirm that this repository's .git entry belongs to the folder it is in"). Every write the skill allows goes through WT, so the stop could not be filed as an agent work item or in a record, and HC, GT and a build loop's `--start` would fail the same way. The iteration ended with no record. The half-made branch (at master's commit) was deleted with `git branch -d`. This entry was committed by hand on master, outside the cycle, since no worktree exists to land it from.
- **Evidence:** `/proc/self/mountinfo` lists `/workspace/.git/worktrees ro`; `git branch -d` printed `error: could not lock config file /workspace/.git/config`; `git worktree list` shows only `/workspace`. Suggested harness change: step 0 tests worktree creation before anything else (a `--state` refusal naming the read-only directory), and the skill says where a stop is filed when no WT can exist.

### F-019 · worktrees-under-dot-claude-prompt-on-every-write
**Feature:** dev-cycle Rules ("Its own directory and worktree") and step 10 (`build-loop.sh --start` worktrees) · **Date:** 2026-11-14 · **Verdict:** friction

- **Context:** a `/loop /dev-cycle` session ran about fifteen iterations (2026-11-14 local 12:18 to 16:40), each self-merging a build loop and dispatching the next. The skill puts the iteration's worktree WT at `.claude/wt-dev-cycle-DATE-HHMM`, the health checkout HC at `.claude/wt-dev-cycle-health-*`, the gate checkout GT at `.claude/wt-dev-cycle-gate-*`, and `--start` puts each loop's worktree at `.claude/wt-<brief stem>`; the repo's warm Lean cache is copied in from `.claude/lake-build-warm-latest`. Every brief the cycle writes is therefore a new file under `/workspace/.claude/`.
- **Expected:** a dev-cycle iteration runs without the owner approving routine file writes; the skill's own instructions name the paths.
- **Observed:** the owner reported the session's permission asks as excessive and denied some (not because the actions were wrong) to keep a record. The denied call was the Write tool creating `/workspace/.claude/wt-dev-cycle-2026-11-15-0039/docs/working/briefs/2026-11-14-mais-o56-box1.md`. The session made about 18 Write-tool calls creating briefs inside `.claude/wt-*` worktrees; `.claude/` is the harness's protected configuration directory, which is the most likely source of the repeated asks. The session also made about 17 background Agent dispatches, about 13 Artifact publishes of the Theorem Atlas, and many Bash calls that create, copy into or remove `.claude/wt-*` worktrees and `.claude/lake-build-warm-*` caches; which of those asked is not visible from inside the session. A build loop met the same wall: the O75 box-2 loop's Write of `docs/proof/mais-o75-channel.md` in its worktree `/workspace/.claude/wt-2026-11-14-mais-o75-box2` was denied although the path is on its brief's `Paths:` line; it put the text in its research doc and asked in its ready marker (`df99b86e`) for the orchestrator to create the file, which the orchestrator left to the owner. A second loop (O54 box 1, marker `81e5420a`) reported that the Write tool was refused for paths inside its worktree `/workspace/.claude/wt-2026-11-14-mais-o54-box1`, and that it drafted its files in its scratchpad and copied them in with shell commands, which were not refused: the loop routed around the denial instead of stopping, and its brief and prompt did not tell it which to do. Side effect of the denial: a Bash call sent in the same response still ran and landed iteration 2026-11-15-0039's record (`db2078bc`), which names an O56 brief and a roadmap edit that never landed (the edit is uncommitted in that worktree).
- **Evidence:** `docs/working/cycles/cycle-2026-11-14.md`, iterations 2026-11-14-2018 through 2026-11-15-0039; master `db2078bc`; uncommitted `docs/roadmap.md` in `/workspace/.claude/wt-dev-cycle-2026-11-15-0039`. Suggested harness change: put the cycle's and the loops' worktrees and caches outside `.claude/` (a sibling directory such as `/workspace/.worktrees/`, or under the session temp directory), or ship an allow rule scoped to `.claude/wt-*/` and `.claude/lake-build-warm-*/` with the skill; and say in the skill that a brief write and the commands that depend on it go in separate responses, so a denied write cannot leave a half-landed iteration.
