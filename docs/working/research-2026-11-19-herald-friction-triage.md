# Research: triage the belegarth-herald friction list as one unit

Brief: `docs/working/briefs/2026-11-19-herald-friction-triage.md` (at 1e826349).
Branch: docs/herald-friction-triage. Dispatch 1.

Source: `docs/working/feedback/belegarth-herald.md`, read whole (F-001 to F-012, from
herald's own records and its session transcripts, 2026-10-17 to 2026-11-12). Constraints:
`docs/constraints.md` at 1e826349.

Failure-pattern grep: FP-068, FP-076

(Grep terms: worktree, subagent, permission prompt, working directory, symlink, add-dir,
Write tool, report file, guard, taint, egress, allow rule, auto-approve. FP-076, "headless
read confined to cwd, critic briefs blocked", is the nearest match: the same read-scope family as
F-004 and F-006, but for headless runs, fixed there with `--add-dir`. FP-068, "gate artifacts
generated then deleted with the worktree", is a worktree-lifecycle cousin of F-008. Neither
changes a verdict below.)

## What "live" means here

`/opt/claude-workflows/.manifest` says `commit=0feaf08085b524c0c4345c52f8e285d842558f23`
(dirty=no). A fix is live when its commit is an ancestor of 0feaf080, checked with
`git merge-base --is-ancestor`. Herald's own rechecks used the image of 2026-11-11 (536b7082);
everything below was checked against the current one.

Commands run: `git`, `rg` and reads (`sed -n`, `cat`, `ls`, `wc`, one `python3 -c` that only
parsed `hooks/wiring.json` to list its keys), plus one `Read` of
`/opt/claude-workflows/workflows/research-plan-implement.md`. No code, test or hook was run.

## Per entry

**F-001 · hook-blocks-land-on-question-prose.** `hooks/guard-trusted-writes.py` denied Bash
writes whose text names `CLAUDE.md` next to a `.claude` reference.
- Cause: the guard's Bash tier works on command text by co-occurrence (header, lines 43-58;
  `bash_targets`). `.claude` counts as a home/global indicator, and every herald worktree
  was under `/workspace/.claude/wt-*`, so any heredoc or `sed` run there that named `CLAUDE.md`
  (or `hooks` / `settings*.json`) was denied. Q-048's worktree exemption was tried and withdrawn
  (header lines 51-58), so the guard is meant to stay this strict.
- Fixed on main: b3e25cf1 (merge of `feat/worktrees-outside-dot-claude`, 2026-11-19):
  `scripts/build-loop.sh` now puts worktrees under `.worktrees` in the main worktree
  (`WT_BASE_NAME=.worktrees`, line 1870), with no `.claude` in the path. Live: yes.
- Left by design: a command whose text names the global `~/.claude/CLAUDE.md` and writes
  something is still denied (header line 50, "Conservative"), and so is the sample-JSON probe
  of 2026-11-12 if its text carries a `.claude` path. The deny message names the workaround
  (Write tool plus `git commit -F`). Worktrees made by the Agent tool's own isolation still go
  under `.claude/worktrees/`, but parallel-worktrees' manual fallback puts them in `.worktrees/`.

**F-002 · cycle-diff-refuses-asked-on-merge-entry.** The dev-cycle skill's step 7 read as if a
merge entry's ID goes on the brief's `Asked:` line; `--cycle-diff` refused it 4 times.
- Cause: wording in `skills/dev-cycle/SKILL.md` step 7, as herald said.
- Fixed on main: 30eb0229 (2026-11-12): the sentence now ends "this is for blocked, stopped
  and capped entries only, never a merge entry, which is found by its heading" (skill lines
  770-771). Live: yes.

**F-003 · d6-block-run-from-a-copy.** The D6 heredoc block failed the auto-approve hook's
parse and drew prompts.
- Cause, old: the skill's D6 heredoc and zsh `${=args}` loop, which
  `hooks/auto-approve-allowed-commands.sh` cannot parse; the hook approves only a small set of
  AST shapes and nothing run through `bash` (its header, lines 25-46).
- Fixed on main: da07a77c (2026-11-05) replaced the block with `scripts/d6.sh` one-liners
  (`cd WT && bash /opt/claude-workflows/scripts/d6.sh SCRIPT ARG...`, skill line 55). Live: yes.
- What's left is the other repo's own setup: herald's `.claude/settings.json` allow list still
  names the old `~/.claude/scripts/...` forms. The harness wiring ships no allow rules
  (`hooks/wiring.json` has `permissions.deny` only; only the separate
  `profiles/interview/settings.json` carries an allow list), and herald runs every session in `auto`
  mode, so no prompt was seen. Not checked: whether a rule like
  `Bash(bash /opt/claude-workflows/scripts/d6.sh:*)` matches the `cd WT && ...` form in Claude
  Code's own matching.

**F-004 · build-loops-cannot-read-harness-files.** The `Read` tool refused workflow and skill
files under `~/.claude` in herald loops.
- Cause: the other repo's own setup. Herald's home `settings.json` sets
  `blockReadsOutsideWorkingDirectories` (F-006's recheck says so). This repo ships no such
  setting: `rg` for `blockReadsOutside` and `additionalDirectories` finds nothing outside
  docs, and neither key is in this workspace's home or project settings. Here, on 2026-11-19, a
  `Read` of `/opt/claude-workflows/workflows/research-plan-implement.md` from a build loop
  succeeded, which fits the setting being the cause.
- Fixed on main: nothing to fix here. Live: n/a.

**F-005 · merge-floor-refuses-a-self-merge-brief.** `--merge` refused 1 of 3 paths of a
self-merge brief, which then fell through to a review entry.
- Cause: the cycle wrote `Policy: self-merge` on a brief whose `Paths:` held a working doc
  not its own. The floor (`floor()` in `scripts/lib/dev-cycle-read.sh`) did its job and failed
  closed. `check_brief` in the same lib (lines 449-492) has `brief_fields` parse `Policy:` and
  `Paths:`, but itself tests only the Status field (lines 474-475), so nothing catches the mismatch when the brief is written.
- Fixed on main: not as code. The dispatch prompt has spelled out the floor since 23ba4511
  (2026-10-10, before this entry), and herald saw no recurrence across five self-merge briefs
  on 2026-11-12. Live: n/a.

**F-006 · added-guides-dir-still-refused-via-symlink.** Adding `~/.claude/guides`, then
`/opt/claude-workflows`, to `permissions.additionalDirectories` did not clear the refusal.
- Cause: cannot tell. Herald's restart recheck rules out the symlink: the real
  `/opt/claude-workflows` path, once added, was still refused, while an added directory under
  home worked. The likely common factor is herald's `blockReadsOutsideWorkingDirectories`
  (see F-004), which is the other repo's own setup. What would tell: in a session with that
  setting on and `/opt/claude-workflows` added, note the Claude Code version and `Read` one
  file under it; then turn the setting off and `Read` again. Only the herald owner's machine
  can run that.
- Fixed on main: nothing to fix here. Live: n/a.

**F-007 · web-taint-hook-asks-on-build-files.** After a web search, the guard asked on writes
to `CLAUDE.md`, memory files, and also `app/build.gradle.kts`, `gradle/libs.versions.toml` and
`tools/train/requirements.txt`.
- Cause: `hooks/guard-trusted-writes.py`, `classify_path` (line 224; its SOFT rules are lines 246-259, the
  `.claude` rule 257-258). A path with a
  `.claude` segment anywhere is SOFT, and a SOFT write in a web-tainted session asks. The
  build files were in herald worktrees under `/workspace/.claude/wt-*`, so they counted as
  SOFT. None of the other SOFT rules can match them (they are not `.md`, `.txt` or
  suffix-less files under skills, memories, commands or agents; not `CLAUDE.md`, `AGENTS.md`,
  `CLAUDE.local.md` or `managed-settings.json`; not `.mdc`), so this is the only route. The `CLAUDE.md` and memory-file asks are by design.
- Fixed on main: same as F-001, b3e25cf1 (worktrees moved to `.worktrees`). Live: yes.
  Inferred from the code, not observed: herald has not had a tainted session since the move.

**F-008 · bash-refused-after-worktree-removed.** A build loop's first Bash call was refused,
with "working directory ... is gone", 9 times.
- Cause: `skills/dev-cycle/SKILL.md`. The orchestrator runs from its own worktree WT, dispatches
  build loops in step 10, and removes WT once step 10's land is verified (step 0.3, lines
  338-339). A subagent starts in the orchestrator's working directory, so once WT is gone, the
  loop's first Bash call is refused and its shell falls back to `/workspace`. It reproduced in this
  very dispatch: this loop started in `/workspace/.worktrees/wt-dev-cycle-2026-11-19-2316`, and
  its sixth Bash call was refused with "Working directory ... no longer exists, so this command
  was not run". The call worked when sent again. The dispatch prompt's "start every command
  with cd ..." does not help, since the refused call is that `cd`.
- Fixed on main: no. Open.

**F-009 · agent-worktree-isolation-fails.** The Agent tool's worktree isolation could not
confirm the repo's `.git` belongs to its folder.
- Cause: Claude Code's own isolation check; cannot tell why from here (herald's `.git` was a
  real directory). Out of scope: this repo does not ship that feature.
- Already handled: `workflows/parallel-worktrees.md` (line 40) says to use the manual fallback
  when isolation fails, and has since 4114b8bd (2026-09-26) or earlier. Herald did exactly
  that. Live: yes.

**F-010 · subagent-report-file-write-refused.** A critic and a fact-check subagent started by
a build loop were refused when they wrote their reports to their scratch directories.
- Cause: Claude Code's Write tool refuses a report file from a subagent (platform). On this
  repo's side, prose tells a subagent to write one: the build-loop dispatch prompt gives
  review subagents "its own scratch directory" (`scripts/build-loop.sh` line 1978), 11
  review skills have a standalone save line (worded variously, e.g. "When run standalone, save
  your report as `docs/reviews/...`" in `skills/code-fact-check/SKILL.md` 477 and
  `skills/security-reviewer/SKILL.md` 574), and `skills/code-review/SKILL.md` 1039 tells its
  fact-check subagent to save a report file outright, the nearest match to F-010. `rg -l` for
  "save (your|the) (report|critique|review|output)" lists those 12 skills and 2 workflows
  (`pr-prep.md` 145 and `user-testing-workflow.md` 404, weaker matches). A reviewer subagent
  that loads a skill with a standalone line reads itself as standalone.
- Partly fixed on main: cd0194572 (2026-11-19) makes parallel-worktrees report items return
  text and has the parent write and commit them. Live: yes. Still open: the build-loop
  prompt and the review skills' standalone lines.

**F-011 · compound-read-of-home-claude-md-prompted.** A read-only compound Bash command that
searched the repo and the home `CLAUDE.md` and then ran `git log` prompted, once.
- Cause: cannot tell. Herald summarized the command rather than pasting it. Candidates: Claude
  Code's working-directory check on a home path (the same read scope as F-004), or a construct
  the auto-approve hook's shape allowlist refuses. What would tell: the exact command, fed to
  `hooks/auto-approve-allowed-commands.sh --debug` with herald's allow rules from that date.
- Fixed on main: unknown. One event, which the owner called a misclick.

**F-012 · sandbox-egress-refused-dl-google-com.** The SNI proxy refused `dl.google.com`
because its rotating addresses left the snapshot the firewall took at start.
- Cause: `devcontainer-config/init-firewall.sh`'s resolver, which handed the proxy fresh
  addresses outside the ipset.
- Fixed on main: 9ad2de46 and 3ec947e3 (2026-10-20, decision 039): dnsmasq pins each exact
  name to the addresses phase A admitted. Herald confirms it with a 30-minute probe on
  2026-11-07. Live: yes.

## Groups by cause

| Group | Entries | Cause | State |
|---|---|---|---|
| A. Worktrees under `.claude/` | F-001, F-007 | the guard treats a `.claude` path as policy | fixed, b3e25cf1, live |
| B. Skill wording | F-002 | dev-cycle step 7 sentence | fixed, 30eb0229, live |
| C. Old D6 block | F-003 | heredoc block the hook can't parse | fixed, da07a77c, live; rest is herald's settings |
| D. Read scope in herald's settings | F-004, F-006, F-011 | `blockReadsOutsideWorkingDirectories` (other repo's setup); F-006 and F-011 not fully explained | not fixable here |
| E. Cycle-written policy vs floor | F-005 | no check at brief-write time; floor fails closed | not recurred; optional |
| F. Loop starts in a removed cwd | F-008 | orchestrator removes WT after dispatch | open, fixable here |
| G. Reviewer report files | F-010 | prose tells subagents to write reports | partly fixed, cd0194572; rest open |
| H. Platform features | F-009, F-012 | Claude Code isolation; egress resolver | F-009 out of scope with fallback; F-012 fixed |

### Group F: a loop's first call lands in a removed working directory (F-008)

Motive (S5, establish the motive first): each loop loses one Bash call, which is sent again
on its own, and the harness moves the shell to `/workspace`. That costs a turn, never
correctness, and the status quo is a valid outcome. It happens on every dispatch whose
orchestrator lands before the loop's first call, which is the common case.

Fix: choose among four approaches (not picked, per the brief):
1. Orchestrator changes directory to MAIN_WT before step 10's Agent calls, so loops start in
   a directory that outlives WT. Path: `skills/dev-cycle/SKILL.md`. Unverified: whether a
   main-session `cd` changes a new subagent's start directory.
2. Defer WT's removal to the next iteration's step 0.3. Path: `skills/dev-cycle/SKILL.md`.
   Leaves one registered worktree on disk between iterations (step 0.3's disk rationale).
3. `scripts/build-loop.sh --prompt` warns that the first call may be refused for a gone
   working directory, and to send it again. Path: `scripts/build-loop.sh`. Names the cost
   and does not remove it.
4. Status quo.

Paths: `skills/dev-cycle/` and `scripts/build-loop.sh` are both gate code (GATE_CODE,
`scripts/lib/dev-cycle-read.sh` line 1037), so either needs a review merge. Neither is an
enforcement file (`hooks/live-verify-gate.sh` line 83) or under `workflows/`.

First step for a later brief: a hermetic probe of option 1's premise. From a main session
whose cwd is a throwaway worktree, `cd` to the main checkout, dispatch one Agent whose first
call prints `pwd`, then remove the worktree; record what the subagent's environment names as
its working directory. If option 1 holds, it is a one-sentence skill change.

### Group G: reviewer subagents told to write report files (F-010 remainder)

Motive: each refused write costs one call, and the report comes back as text anyway. The
parallel-worktrees half is fixed. What's left is mostly wasted calls and confusing prose, not lost
work. Status quo is valid.

Fix: choose among three approaches, plus the status quo (not picked):
1. One line in the build-loop dispatch prompt: review subagents return their report as text,
   and the loop writes it. Path: `scripts/build-loop.sh` (gate code, review merge).
2. Each review skill's standalone save line gains "(a subagent returns it as text
   instead)", and code-review line 1039 asks its subagent for text. Paths: 12
   `skills/*/SKILL.md` files. S3 (one source of truth per rule) weighs against restating it
   11 times.
3. One rule in a place every session loads, `global-instructions/CLAUDE.md` (an instruction
   file, on the self-merge floor, and S2's always-loaded budget applies), or a guide the
   skills link to.
4. Status quo.

Paths: option 1 is gate code; option 3's instruction file is on the floor; none is an
enforcement file. Option 2 touches no `workflows/` file unless `pr-prep.md` and
`user-testing-workflow.md` (which also hold save lines) are included, and then it is a
`workflows/` change.

First step for a later brief: list every skill and workflow line that tells its runner to
save a report (`rg -n -i 'save (your|the) (report|critique|review|output)' skills workflows`).
For each, mark whether a subagent can run it (code-review's critics, a build loop's
reviewers). Then pick among the options with that count in hand.

### Group E: cycle-written policy vs the floor (F-005), optional

One event, failed closed, not recurred in five tries. If it is filed at all: `--check-brief`
(the `check_brief` function in `scripts/lib/dev-cycle-read.sh`, gate code) could print an
advisory line when a self-merge brief's `Paths:` names a floor path. Its first step is to
check whether `floor()` can be called on a brief's `Paths:` before a branch exists (it takes
the path, the brief stem, a diff status letter and an optional lower-cased path). This is one approach, not a choice among three or
more.

## Design choices in this unit

- Whether to pick fixes for groups F and G: no. The brief says to name three or more
  approaches and not pick.
- Whether group E is a roadmap item or a close: listed under closes, with its optional first
  step, since it failed closed and has not recurred (S5).
- Group D: closed as the other repo's setup rather than filed, because this repo ships
  neither setting. The open "why" in F-006 can only be checked on herald's machine.

## For the dev cycle

File as roadmap items:

1. **Build loops start in the orchestrator's removed worktree (herald F-008)**.
   Motive: every loop dispatched before the cycle's land loses its first Bash call, and it
   reproduced in this triage's own dispatch on 2026-11-19. First step: the hermetic probe
   in group F above (does a main-session `cd` before an Agent call move the subagent's start
   directory?), then choose among group F's four approaches. Paths are gate code (review merge).
2. **Review subagents are told to write report files Claude Code refuses (herald F-010
   remainder)**.
   Motive: the build-loop prompt, 11 review skills' standalone lines and code-review's
   fact-check dispatch still tell a subagent to save its report, which costs a refused call each time. First step: the listing in group G above,
   then choose among its four approaches. Option 1 is gate code (review merge).

Close as already fixed (live in image 0feaf080):
- F-001: b3e25cf1 moved worktrees out of `.claude/`; the residual deny on prose naming the
  global `~/.claude/CLAUDE.md` is by design (guard header, line 50).
- F-002: 30eb0229 scoped the `Asked:` sentence to non-merge entries.
- F-003: da07a77c replaced the D6 block with `d6.sh` one-liners; the stale allow rules are
  in herald's own `.claude/settings.json`.
- F-007: b3e25cf1, the same fix as F-001 (`classify_path` makes any `.claude` segment SOFT).
- F-012: 9ad2de46 and 3ec947e3 pin the resolver; herald probe-confirmed 2026-11-07.

Close as out of scope or the other repo's setup:
- F-004: herald's `blockReadsOutsideWorkingDirectories`; this repo ships no such setting.
- F-006: same setting; why an added `/opt` directory is still refused can only be checked
  on herald's machine (the test is under F-006 above). Herald can rely on the shell workaround.
- F-009: Claude Code's isolation; `workflows/parallel-worktrees.md` line 40 already gives the
  manual fallback herald used.
- F-011: one event that cannot be diagnosed without the exact command; the owner called it a
  misclick.
- F-005: failed closed, has not recurred; the optional `--check-brief` advisory is under
  group E if the cycle wants it as an Idea.
