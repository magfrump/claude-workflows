# Harness feedback

Entries on how claude-workflows features work or fail in this project.
Grammar: ~/.claude/guides/harness-feedback.md.

Project: belegarth-herald

## How this was gathered

First gathered on 2026-11-07 from this repo's own records (`docs/working/cycles/`, the research
docs, `docs/working/idea-log.md` and the brief that asked for this file). Extended on 2026-11-12,
after the owner granted access, from the session transcripts under the home `.claude/projects`
directory for this workspace: 62 transcript files (24 main sessions, 38 subagents), dated
2026-10-17 to 2026-11-12. The session that dispatched this work was left out, since it was still
running.

The transcripts were searched with a small script for tool calls that came back refused or
blocked, for hook output that asked for approval, and for calls the owner declined. Each kind
below is one entry, grouped by what triggered it, with a count of distinct tool calls and the
date range. Commands are summarized, not pasted.

This list is incomplete. Every session ran in `auto` permission mode, and a prompt the owner
approved usually leaves no trace in a transcript: only a refusal, a decline or a hook's own output
shows. So the counts are floors, and kinds of prompt that were always approved may be missing
entirely. The owner should add what they recall.

F-001 to F-005 were first filed on 2026-11-07 and copied to claude-workflows then; their headings
and meta lines are kept as they were, so the copy's `ingest` accepts this file. On 2026-11-12 each
got a "Recheck" line against the image installed 2026-11-11 (claude-workflows 536b708): F-001 is
partly fixed, F-002 and F-004 are still current, F-003's block is gone but its one-liners match no
allow rule, and F-005 has not recurred. F-006 to F-012 are new since that copy. A later session
on 2026-11-12 rechecked F-006 after a restart: granting the image path did not help.

### F-001 · hook-blocks-land-on-question-prose
**Feature:** PreToolUse hook · **Date:** 2026-11-07 · **Verdict:** friction

- **Recheck 2026-11-12, on the image installed 2026-11-11 (claude-workflows 536b708):** partly
fixed, still current for heredocs in worktrees. `hooks/guard-trusted-writes.py`, fed sample
commands: a read-only `rg -n CLAUDE.md` from a worktree, a `git commit -F FILE` from a worktree,
and a heredoc append from `/workspace` (no `.claude` in the path) all get no opinion. A heredoc
append from a worktree under `/workspace/.claude/wt-*` whose prose names `CLAUDE.md` is still
denied: the worktree path is the `.claude` reference. Live: the hook denied a read-only Bash call
in the owner's session on 2026-11-12 that piped sample JSON naming `CLAUDE.md` and a
`/workspace/.claude/wt-*` path into a hook. Workaround in use: write prose with the Write tool,
or run from a path without `.claude`.

- **Context:** Dev cycles and build loops writing records, research docs and commit messages
through Bash, mostly from git worktrees under `/workspace/.claude/wt-*`.

- **Expected:** Prose inside a record or question does not count as writing the files it names.

- **Observed:** The hook blocked Bash calls that named `CLAUDE.md` next to a `.claude` or home
reference, or named a home `.claude` hooks or settings path. The known case: iteration
2026-11-07-0625's land was blocked because a question's prose named an instruction file next to a
dot path. By a reading of the blocked commands, about 8 wrote cycle records, research docs or
commit messages through a heredoc whose prose named one of these files; about 6 edited or
committed files by `sed` or `python`, 2 of them `CLAUDE.md` itself; and about 4 were searches or
experiments, such as piping test input into a hook. Every worktree path contains `/.claude/`, so
any command run in a worktree carries a `.claude` reference. Each block cost a rewrite through
the Write tool or a message file.

- **Evidence:** Count 18 blocked calls in 8 sessions and their subagents, 2026-10-17 to 2026-11-11, plus 2 more on
2026-11-12 in the loop that wrote this entry (a read-only search script and a heredoc append to
its research doc, both naming `CLAUDE.md`).
Source: transcripts, tool results starting `PreToolUse:Bash hook error: Bash write that names a
protected policy file`. The 0625 case is the 2026-11-07 06:26 UTC block in the orchestrator session.

### F-002 · cycle-diff-refuses-asked-on-merge-entry
**Feature:** dev-cycle `--cycle-diff` · **Date:** 2026-11-01 · **Verdict:** friction

- **Context:** A dev cycle recording an `Asked:` line on a brief whose question was a merge
approval, in three iterations.

- **Expected:** An `Asked:` line on a merge entry is accepted, as the brief for this file says the
skill's step 7 reads as if it might apply.

- **Observed:** `--cycle-diff` refused the line each time, saying the question's heading was not
`WORDS-<brief stem>-N`, an entry filed for that brief. The merge entries' headings were
`merge-<brief stem>-<commit>`. Each time a second commit removed the line before the cycle could
land.

- **Evidence:** Count 3 refusals, 2026-11-01 to 2026-11-07, on the briefs
`2026-11-01-claude-md-phase2-on-main` (Q-018), `2026-11-02-claude-md-field-guide-link` (Q-020) and
`2026-11-06-phase3-adr` (Q-028). Sources: transcripts, and `docs/working/cycles/cycle-2026-11-01.md`
for the first.

- **Recheck 2026-11-12:** still current. A fourth refusal on 2026-11-12, iteration 2334 (brief
`2026-11-12-phase3-benchmark`, merge entry Q-035), in `docs/working/cycles/cycle-2026-11-12.md`.
The cause is the skill's wording: in `skills/dev-cycle/SKILL.md` step 7, the sentence "Add
`Q-NNN@TIP` to the brief's `Asked:` line" closes a paragraph that also covers merge entries
("here or in a merge entry"), so it reads as applying to them. The gate is right; the sentence
needs "(blocked, stopped and capped entries only; a merge entry is found by its heading)".

### F-003 · d6-block-run-from-a-copy
**Feature:** dev-cycle D6 block · **Date:** 2026-10-28 · **Verdict:** friction

- **Recheck 2026-11-12:** the D6 block itself is gone: the skill now runs each script as one line,
`cd WT && bash /opt/claude-workflows/scripts/d6.sh SCRIPT ARG...`, so there is no heredoc to copy
and no loop to misparse. `hooks/auto-approve-allowed-commands.sh` parses those one-liners
(`build-loop.sh --state`, `dev-cycle.sh --check-brief`, `questions.sh next-id`) and has no opinion
on them; the old `${=args}` loop still gives `Parse error: 1:12: invalid parameter name`, but the
skill no longer writes it. New friction: no allow rule matches the one-liner, so outside `auto`
mode each would prompt. This project's `.claude/settings.json` allow list still names the old
`~/.claude/scripts/questions.sh` and `~/.claude/scripts/dev-cycle.sh` forms, which the skill now
forbids, so those rules are stale.

- **Context:** The dev cycle running its scripts through the D6 block, a long heredoc fed to
`bash -s`, often several calls in one Bash command through a zsh `for` loop.

- **Expected:** The block runs as the skill gives it without asking the owner, since the scripts
it runs are allowlisted.

- **Observed:** Three things. The auto-approve hook failed to parse 5 D6 commands that looped over
calls with zsh's `${=args}` word splitting (`Parse error: invalid parameter name`), so those
commands did not get its approval. Two D6-related commands reached the owner as prompts and were
refused or interrupted: on 2026-10-17 the owner interrupted an `awk` command that copied the D6
block out of the skill file into the scratchpad, and then ran `/fewer-permission-prompts`; on
2026-11-01 a deny of a read-only `questions.sh next-id` call paused the cycle, and the owner then
said it was a misclick. On 2026-10-28 the block ran from a byte-identical copy in the scratchpad,
with no reason recorded.

- **Evidence:** Transcripts: 5 parse errors, 2026-11-01 to 2026-11-02; 2 refused or interrupted D6
prompts, 2026-10-17 and 2026-11-01. `docs/working/cycles/cycle-2026-10-28.md`, step 0, for the copy.
About 180 D6 calls with timestamps ran in the period. For the rest, the transcripts cannot tell
whether a prompt was shown and approved or none was shown.

### F-004 · build-loops-cannot-read-harness-files
**Feature:** build loop dispatch · **Date:** 2026-11-07 · **Verdict:** friction

- **Recheck 2026-11-12:** still current. The owner added `~/.claude/guides` and the transcripts
directory to `permissions.additionalDirectories` in this project's `.claude/settings.json`, but not
`~/.claude/workflows` or `~/.claude/skills`. On 2026-11-12 the harness-feedback loop did not read
the workflow files, and the listening-tool loop read `pr-prep.md` outside the Read tool. See F-006
for why granting the `~/.claude` links may not be enough.

- **Context:** Sessions and build loops told to follow workflows, skills or guides under the home
`.claude` directory.

- **Expected:** A loop can read the workflow and skill files its dispatch or brief relies on.

- **Observed:** The `Read` tool refused them, because the setting blocks reads outside the working
directories. Refused files: the research-plan-implement workflow (most often, one refusal per
build loop on 2026-11-07), the review-fix-loop workflow, the code-fact-check skill, a
constraints-builder template and a dev-cycle script library. Loops followed their dispatch prompt
instead, and the first loop for this file stopped short of the transcripts.

- **Evidence:** Count 11 refused reads in 4 sessions and their subagents, 2026-10-20 to 2026-11-07, from transcripts.
Also `docs/working/research-2026-11-05-phase3-dd-impact-rescore.md` and this file's research doc.

### F-005 · merge-floor-refuses-a-self-merge-brief
**Feature:** build loop `--merge` · **Date:** 2026-11-05 · **Verdict:** friction

- **Context:** Collecting a `Policy: self-merge` brief that edited a working doc outside its own stem,
iteration 2026-11-06-0151.

- **Expected:** The brief's policy matches what the floor will accept.

- **Observed:** `--merge` refused 1 of 3 paths as not the brief's own file, and the brief fell through
to review as a merge entry. The cycle record puts the cause on the cycle, which wrote the policy.

- **Evidence:** Count 1, in the 2026-11-05 cycle record. `docs/working/cycles/cycle-2026-11-05.md`,
step 7 of that iteration, and the matching seed in `docs/working/idea-log.md`.

- **Recheck 2026-11-12:** not seen again. Five self-merge briefs merged on 2026-11-12
(harness-feedback-prompts, phase3-cpu-scorer, phase3-listening-tool, phase3-train,
listening-tool-label-evidence) with no floor refusal. Each brief listed its exact `Paths:`, and the
dispatch prompt now spells out the floor ("working docs or reviews not your own"). Not proof of a
fix, only that the cycle's side of it held five times.

### F-006 · added-guides-dir-still-refused-via-symlink
**Feature:** permissions.additionalDirectories with harness symlinks · **Date:** 2026-11-12 · **Verdict:** fails

- **Context:** The owner added the home `.claude/guides` directory to the additional directories so
a build loop could read the harness feedback guide (answer to Q-029).

- **Expected:** The `Read` tool can read files in the added directory.

- **Observed:** It still refused the guide with the same outside-the-working-directories message.
In this sandbox the home `guides`, `workflows`, `skills`, `scripts` and `hooks` entries are
symlinks into `/opt/claude-workflows`, and this refusal named the resolved `/opt` path, where the
earlier refusals in F-004 named the home path. The added
transcripts directory, a real directory, read fine. The loop read the guide through the shell.

- **Evidence:** Count 1, on 2026-11-12, in the build loop that wrote this entry.

- **Recheck 2026-11-12, the owner's session:** reproduced. The setting lives in the project's
`.claude/settings.json` and `blockReadsOutsideWorkingDirectories` in the home `settings.json`;
the two scopes combine, since a `Read` of `~/.claude/projects/-workspace/memory/MEMORY.md`
succeeded while a `Read` of `~/.claude/guides/harness-feedback.md` was refused ("outside
/workspace"). The likely cause is the symlink: the check sees `/opt/claude-workflows/guides`. The
owner then added `/opt/claude-workflows` itself; a `Read` under it was still refused in the same
session, because the change takes effect at the next session start. Not yet confirmed: whether
granting `/opt/claude-workflows` clears this after a restart. If it does, the harness's install
should grant the image path, not the home links.

- **Recheck 2026-11-12, after a restart:** it does not clear it, and the symlink is not the
cause. A new session started with `/opt/claude-workflows` among its additional working
directories (the session's environment lists it). A `Read` of
`/opt/claude-workflows/guides/harness-feedback.md` was refused with the same message ("outside
/workspace"), and so was the home-link path. `/opt/claude-workflows` and its `guides` are real
directories, not links. In the same session a `Read` of a transcript file under the added
transcripts directory succeeded. That file is not a memory file, so the earlier `MEMORY.md` test
may only have shown that memory is always readable. So an added directory under the home
directory works, and the added `/opt` image directory does not, whether it is reached by its link
or its real path. Why is not known. Workaround is still the shell.

### F-007 · web-taint-hook-asks-on-build-files
**Feature:** PreToolUse hook (web taint) · **Date:** 2026-11-05 · **Verdict:** friction

- **Context:** Sessions that ran a web search, then edited files.

- **Expected:** Edits after a web search prompt only for files that carry instructions.

- **Observed:** After one or two web searches, the hook asked for approval on each later write to
what it called a trusted-policy file: `CLAUDE.md` three times, two memory files, and also
`app/build.gradle.kts`, `gradle/libs.versions.toml` twice and `tools/train/requirements.txt` while
adding the Phase 3 dependencies. All 9 were approved.

- **Evidence:** Count 9 prompts in 2 sessions, 2026-11-05 (4) and 2026-11-11 (5). Source:
transcripts, hook output with `permissionDecision` set to `ask`.

### F-008 · bash-refused-after-worktree-removed
**Feature:** Bash working-directory check · **Date:** 2026-11-02 · **Verdict:** friction

- **Context:** Build loops (subagents) that started in a worktree the orchestrator had already
removed, making their first Bash call, most often a `cd` into their own worktree.

- **Expected:** A command that changes to an existing directory first runs.

- **Observed:** The call was not run, with "the working directory no longer leads where it did" or
"working directory ... is gone", and had to be issued again. Every one of the 9 was a loop's first
Bash call. At 2026-11-07 18:53 UTC three loops dispatched together each lost their first call this
way, and at 08:33 two more did.

- **Evidence:** Count 9 refused calls, all in subagents of 2 sessions, 2026-11-02 to 2026-11-07,
from transcripts.

### F-009 · agent-worktree-isolation-fails
**Feature:** Agent tool worktree isolation · **Date:** 2026-11-06 · **Verdict:** fails

- **Context:** A session in the main checkout fanning out two fixes to subagents with worktree
isolation.

- **Expected:** Each subagent gets its own git worktree, as the parallel-worktrees workflow asks.

- **Observed:** Both Agent calls failed: Claude Code could not confirm that the repository's `.git`
entry belongs to its folder, so no worktree could be made. The session's `.git` was a real
directory. It went on with worktrees made by hand and plain Agent calls.

- **Evidence:** Count 2 refused Agent calls, 2026-11-06, one session, from transcripts.

### F-010 · subagent-report-file-write-refused
**Feature:** Write tool in subagents · **Date:** 2026-11-07 · **Verdict:** friction

- **Context:** Review subagents (a critic and a fact-check) started by a build loop, each with its
own scratch directory.

- **Expected:** A reviewer can save its report in its scratch directory, as its brief asked.

- **Observed:** The Write tool refused both, saying subagents should return findings as text, not
write report files. The reports came back as text instead.

- **Evidence:** Count 2 refused writes, 2026-11-07, from transcripts.

### F-011 · compound-read-of-home-claude-md-prompted
**Feature:** Bash permission prompt (compound command) · **Date:** 2026-10-20 · **Verdict:** friction

- **Context:** A session drafting the constraints doc, running one read-only Bash command that
searched the repo and the home `CLAUDE.md`, then listed commit trailers with `git log`.

- **Expected:** A read-only command does not need the owner.

- **Observed:** It prompted. The owner declined it, then said it was a misclick, and the session
went on.

- **Evidence:** Count 1, on 2026-10-20, from transcripts. Prompts on compound commands that were
approved leave no trace, so this says nothing about how often they happen.

### F-012 · sandbox-egress-refused-dl-google-com
**Feature:** sandbox egress firewall · **Date:** 2026-10-17 · **Verdict:** fails

- **Context:** Gradle builds in the agent sandbox downloading Android dependencies.

- **Expected:** An allowlisted host such as `dl.google.com` stays reachable for the whole session.

- **Observed:** The proxy refused `dl.google.com` (`FAIL sni=dl.google.com` in its log), so builds
failed on downloads. The address list was filled once at start, and that host's addresses rotate.
A later image fixed it: on 2026-11-07 a 30-minute probe saw no refused addresses and a cold build
passed.

- **Evidence:** Live failures in October 2026, first in a transcript on 2026-10-17; probe sessions
on 2026-11-07. Sources: transcripts and the project's memory note on sandbox builds. The number of
failed builds was not counted.
