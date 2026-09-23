# Pre-Mortem: bare-host `~/.claude` install by blessed copy (shape D)

**Proposal:** `docs/working/plan-copy-install-bare-host.md` (revised 2026-09-23), decision `docs/decisions/037-bare-host-copy-install.md`, against `devcontainer-config/install.sh` at 29cdd16
**Date:** 2026-09-23
**Upstream what-if analysis:** none

> ℹ️ **No upstream what-if analysis provided.** Failure narratives are generated directly
> from the proposal. For higher-quality narratives, run `what-if-analysis` first and
> provide its output — this skill is sharpest when seeded with already-mapped assumptions
> and coupling points.

Prior art check: grepped `docs/decisions/` and `docs/working/` for `install.sh`, `symlink`, `bless`. Relevant matches: 016, 022, 023, 035, 037, `dd-install-sh-gating.md`, and the research doc. The research doc's three hazards (a diff that follows the link, `cp` into a link, `rm link/`) are already mitigated in the plan, so they are not repeated here. Two facts observed in this session seed the narratives below:
- The Bash tool's environment sets `CLAUDECODE` and `CLAUDE_CONFIG_DIR`.
- `hooks/wiring.json` addresses every hook as `{{CLAUDE_DIR}}/hooks/<name>`.

## Failure narratives

### 1. The quiet drift

- **Root cause:** under symlinks, a commit to `skills/` or `workflows/` was live on the host at once. After migration, it reaches `~/.claude` only when the user runs `install.sh`, which they historically ran only after changing the devcontainer config. The two-prompt run (D) makes the run *offer* `~/.claude`. It does nothing to make the user *run* it.
- **Chain of consequences:**
  1. In the four weeks after migration, the user lands 23 commits touching `skills/`, `workflows/` and `global-instructions/CLAUDE.md`, and runs `install.sh` zero times.
  2. Bare-host sessions keep loading the migration-day `code-review` skill and the old routing table.
  3. The user debugs "why does code-review still run the removed critic?" for an evening, reading the repo copy, which is correct, and never the installed one, which is stale.
- **Observable outcome:** `~/.claude/.claude-workflows-manifest` `commit=` is 23+ commits behind `main`. The user sees behavior that contradicts the files they are reading.
- **Plausibility:** Likely
- **Severity:** Medium
- **Tag:** `[PRIOR CONSIDERATION]`: research DD candidate [9] H (SessionStart staleness warning), deferred; decision 037 revisit trigger "~/.claude going stale again".
- **Revisit trigger:** `git -C ~/claude-workflows rev-list --count "$(sed -n 's/^commit=//p' ~/.claude/.claude-workflows-manifest)"..main -- skills workflows guides patterns hooks scripts global-instructions` returns > 10 at any weekly check → implement DD [9] H (a SessionStart hook comparing the manifest commit with the checkout HEAD).

### 2. The wired hook that went to the backup

- **Root cause:** the README-era `~/.claude/hooks/` is a *real* directory. It held the four copied security hooks, five per-file links, and anything else the user had put there: a personal notification hook wired in `settings.json`, or an older hook name the repo has since renamed. Q-057 [1] moves every such foreign file to `.claude-workflows-backup/<stamp>/hooks/`. The review lists it as `MOVE to backup`, one line among ~40 `REPLACE symlink` and diff lines, and nothing says it is wired.
- **Chain of consequences:**
  1. The install moves `~/.claude/hooks/notify-done.sh` to the backup.
  2. `settings.json` still says `bash ~/.claude/hooks/notify-done.sh` on `Stop`.
  3. Every session now reports a hook error at every stop. For a foreign **PreToolUse** hook, the missing file is a non-blocking error, so a hook the user relied on to deny something silently stops denying it.
- **Observable outcome:** "Stop hook error: bash: …/notify-done.sh: No such file or directory" in every session. For a guard-type foreign hook, no error the user notices: the protection is simply gone.
- **Plausibility:** Plausible
- **Severity:** High (the PreToolUse variant fails open)
- **Mitigation:** in plan step 5's symlink-aware review, for every foreign file under `hooks/`, grep `settings.json` and `settings.local.json` in the destination for its basename. Print `WIRED in settings.json: moving it breaks that hook` next to the `MOVE to backup` line, and repeat the list in the post-install summary. Add test T20 to `test/install-host.bats`: a foreign `hooks/mine.sh` referenced by a scratch `settings.json` must produce the WIRED line.

### 3. The backup that landed in the checkout

- **Root cause:** the swap trusts `$DEST/.claude-workflows-backup` and `$DEST/.cw-new.<name>` to be plain paths. An earlier agent session, or a stray `ln -s` from debugging, left `~/.claude/.claude-workflows-backup -> ~/claude-workflows/docs/working/backup`. `mkdir -p` happily creates the stamp dir through the link.
- **Chain of consequences:**
  1. Step 3 of the swap does `mv ~/.claude/hooks <link>/<stamp>/hooks`, which moves the user's real hooks dir, with the four security hooks and any private hook, into the agent-writable checkout.
  2. The user's next `git status` shows 60 untracked files under `docs/working/backup/`. A `git add -A` commits them.
  3. The Rollback procedure in the plan now points at a path inside the repo that the next `git clean` deletes.
- **Observable outcome:** untracked `docs/working/backup/<stamp>/` in the checkout; the backup path printed by the installer resolves inside the repo.
- **Plausibility:** Unlikely-but-catastrophic (<10%; the result is bad but recoverable, so severity is Medium, not Catastrophic)
- **Severity:** Medium
- **Mitigation:** in plan step 5 Install, before any write, refuse (exit 1, nothing moved) if `$DEST/.claude-workflows-backup` is a symlink or resolves inside the checkout (the same `pwd -P` prefix guard used for `$DEST`). Refuse if any `$DEST/.cw-new.*` is a symlink and not removable as a link. Add T21: a planted backup-dir symlink into the fake repo leaves the fake repo's checksums unchanged, and the run exits 1.

### 4. The agent that found `script`

- **Root cause:** decision 037's TTY rule. On 2026-09-23 the Bash tool had no TTY, but `script` was on PATH. Weeks later a session hits the R6 symptom's successor ("my edit to `skills/foo` isn't taking effect"). It reads the installer, sees "needs an interactive terminal", and runs `script -qec ./devcontainer-config/install.sh /dev/null <<<$'n\ny\n'` to "apply the change". The sandbox `denyWrite ~/.claude` hardening was never applied on this host (guide §3 is manual).
- **Chain of consequences:**
  1. The agent's own uncommitted edits to `hooks/guard-trusted-writes.py` in the checkout are staged and installed.
  2. The guard the user thought was the reviewed copy is now the agent's version.
  3. The manifest says `dirty=yes`, which nobody reads.
- **Observable outcome:** a `.claude-workflows-backup/<stamp>/` whose stamp falls inside an agent session's time window. The manifest shows `dirty=yes`. A transcript shows a `script -qec` call.
- **Plausibility:** Unlikely-but-catastrophic
- **Severity:** High
- **Tag:** `[PRIOR CONSIDERATION]`: plan Risks, "The TTY barrier does not stop a determined agent"; decision 037 revisit trigger.
- **Mitigation:** in plan step 5's skip rules, also skip the host target when `CLAUDECODE` is set. It is set in the Bash tool environment, as observed in this session. An agent must then *unset* a variable as well as fake a TTY, and both show plainly in a transcript. Record `installed_by=` in `.claude-workflows-manifest`: the parent process's command name and whether `CLAUDECODE` was set. Also refuse a `dirty=yes` stage for the host target unless the human types the word `dirty` at a second prompt. Add T22 (`CLAUDECODE=1` inside a pty → skipped) and T23 (dirty repo → extra confirmation).

### 5. The install nobody's Claude Code reads

- **Root cause:** Claude Code reads its config from `$CLAUDE_CONFIG_DIR` when that variable is set. It was set in this very session's environment. The plan's destination is `${CLAUDE_HOME_DIR:-$HOME/.claude}` and ignores it. A host user who exports `CLAUDE_CONFIG_DIR=~/.config/claude` for XDG tidiness gets a clean, blessed install into `~/.claude`, a directory their Claude Code never opens.
- **Chain of consequences:**
  1. The review shows every file as new: `~/.claude` barely exists, so this looks exactly like a legitimate first install.
  2. The user answers y.
  3. Sessions keep running whatever is in `$CLAUDE_CONFIG_DIR`, which is still the old symlinks into the checkout. The Q-050 goal (the checkout is inert) is silently unmet.
- **Observable outcome:** the installer's "Installed into /home/u/.claude" line disagrees with `echo $CLAUDE_CONFIG_DIR`. The R6 symptom (checkout CLAUDE.md not Edit-able) persists after "migration".
- **Plausibility:** Plausible (only for users who set the variable; unknown for this user)
- **Severity:** Medium
- **Mitigation:** in plan step 5, resolve the destination as `${CLAUDE_HOME_DIR:-${CLAUDE_CONFIG_DIR:-$HOME/.claude}}`, and print which variable chose it on the review's first line. Add T24: with `CLAUDE_CONFIG_DIR` set and `CLAUDE_HOME_DIR` unset, the install lands in `CLAUDE_CONFIG_DIR`.

## Recommendations

**Must address before proceeding** (all are cheap, and all land in plan step 5 plus tests):
- **#2 wired foreign hook**: print WIRED next to any foreign `hooks/` file referenced by the destination's settings (T20). This is the one failure that fails open.
- **#3 backup through a symlink**: refuse a symlinked or in-checkout backup dir, or `.cw-new.*` link (T21). It is the same class as the three hazards the research already found, one path over.
- **#5 CLAUDE_CONFIG_DIR**: honour it in the default destination (T24). Otherwise the migration can silently not happen.

**Worth mitigating:**
- **#4 agent self-bless**: add the `CLAUDECODE` skip rule and the `installed_by=` provenance (T22). The dirty-stage extra confirmation (T23) is optional. It adds a second ritual prompt, so it can go to questions.md if it seems too much.
- **Mid-swap window** (no narrative): between moving the old entries out and the new copies in, a running session's hook invocation can find no file. That window is milliseconds. Acknowledge it in the README migration paragraph: "close Claude Code sessions before installing".

**Acknowledged risks:**
- **#1 quiet drift**: carried by the revisit trigger and decision 037's deferred DD [9]. D was chosen to shrink it, and closing it fully needs a SessionStart hook, which is out of this plan's scope.
