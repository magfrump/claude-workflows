# 037 — Bare-host `~/.claude` is installed by blessed copy, offered on every `install.sh` run

- **Goal**: decide how the global instructions, skills, workflows, guides, patterns, hooks and scripts reach a bare host's `~/.claude` once the README's symlinks into the checkout are deprecated (Q-050).
- **Project state**: `ans/copy-install` implements it · follows the 2026-09-21 answers branch (its guard redesign R6/N12 is paused and becomes moot on a bare host after migration) · not blocked.
- **Task status**: in-progress (decided 2026-09-23 by the user, Q-054 [2]; implementation on `ans/copy-install`, live check is the user's host run)

## Context

On a bare host, the README symlinked `~/.claude/CLAUDE.md` and five directories into the checkout, linked five hooks one file at a time, and copied four security hooks. So the *live* global process was the checkout itself: any edit to the repo, by an agent or anyone, went live immediately with no review.

The user's Q-050 answer (2026-09-23): "This repo's copy is the only global instruction file that should be editable, and the symlink connection should be deprecated in favor of edits getting checked in and propagated by copying after a human bless via install.sh."

`devcontainer-config/install.sh` already has the whole mechanism for the devcontainer config:
- it assembles the same seven-entry payload;
- it shows a `diff -ruN` review and aborts if the diff itself fails;
- it asks an EOF-safe `[y/N]`, then copies.

Research, the DD matrix and the three experimentally verified hazards: `docs/working/research-copy-install-bare-host.md`. The hazards: `diff -ruN` through a symlinked destination shows nothing; `cp -r` onto a directory symlink writes into the checkout; `rm -rf link/` empties the checkout.

## Options considered

12 candidates (0–11): status quo; docs-only `cp`; A (`--claude-home` target flag); B (a separate host script); C (one diff and one y for both targets); D (every run offers every target, each with its own diff and y); E (chmod the checkout); F (symlink into the installed devcontainer payload); G (a pinned git worktree); H (A plus a SessionStart staleness warning); I (a make target); J (plugin packaging). Three survived pruning: **A, D, B**. The non-interactive research pass recommended A (70%, Path C). The user chose D.

## Decision and rationale

**Chosen: D.** A plain `install.sh` run offers every target in turn: the devcontainer config first, exactly as today, then the host `~/.claude`. Each target has its own review and its own y/N. There are no target flags.

The user's reason: "I *will* forget to add flags to install.sh, and it already replaces some files in place instead of symlinks." That settles the research's axis of disagreement (*one run covering every target* vs *one boundary per bless*) for the first option. D keeps a separate boundary per target anyway, because each target gets its own diff and its own y. That was the main reason the research gave for A.

Sub-decisions, all from the user's 2026-09-23 answers:
- **Host target never installs non-interactively (Q-056 [1]).**
  - It is skipped, with a message, when `--yes` is given or stdin is not a TTY.
  - The skip happens before it reads or stages anything, so every existing non-interactive devcontainer run is unchanged apart from two extra lines (a blank line and the skip line).
  - A skip is not a decline and does not change the exit status.
- **Foreign files move to the backup (Q-057 [1]).** A file inside an install-owned directory that the repo lacks is listed in the review and moved to `.claude-workflows-backup/<stamp>/`. Each of the seven entries the install replaces goes there too, including the old symlinks, as symlinks. (Review fixes 2026-09-23: the backups of the last 3 installs are kept, ordered by the stamp each install writes, and the current run's is never removed; a run with nothing to change makes none.)
- **Gemini is dropped (Q-055 [2]).** The README's `~/.gemini` and Antigravity recipes are removed, not converted.
- **`settings.json` stays a manual merge.** It holds host-private hardening, Q-049 is open, and the only correct merger is link-claude-home's provenance jq (FP-161). The installer prints a reminder when `hooks/wiring.json` changed.
- **"Bless" on a bare host means a human at a terminal who read the review and typed y.** No hash receipt is checked, because Claude Code reads `~/.claude` directly. Provenance is `~/.claude/.claude-workflows-manifest`, in the same format link-claude-home writes.

See alternatives considered → *Pruned candidates and why*, below.

## Pruned candidates and why

How to read: each entry is `[candidate-ID]: one-line reason for discard`. Future DDs in adjacent areas can grep this section to avoid regenerating already-pruned approaches.

`[2 A target flags]: user-declined, not dead — the flag is the thing that gets forgotten, leaving ~/.claude stale with no error.` `[3 B separate host script]: a second host-executed installer outside 035's gate, and a shared lib is a new coupling [carried from 016 [4]: two code paths, two trust regimes].` `[0 status quo]: contradicts the Q-050 answer; no review before a change goes live.` `[1 docs-only cp]: a hand copy shows no diff and hides the symlink migration (the diff-follows-link hazard).` `[4 C one diff, one y]: one y spans two boundaries and forces the devcontainer bless on hosts that want only ~/.claude.` `[6 E chmod the checkout]: no diff, and a read-only worktree breaks checkout and stash [carried from 035 [10]].` `[7 F link into the installed devcontainer payload]: ~/.config is agent-writable on a bare host, so the devcontainer bless would silently change ~/.claude.` `[8 G pinned worktree]: the agent can move the worktree HEAD.` `[9 H staleness warning]: deferred add-on to any survivor, not a rival.` `[10 I make target]: a second mechanism.` `[11 J plugin packaging]: the plugin layout doesn't carry CLAUDE.md or hook wiring.` `Prior pruning grep: 035's Pruned candidates matched install|bless|symlink — [carried from 016 [4]] as above; [carried from 035 [7] move the installer off the repo: declined on unverifiability] not re-proposed.`

## Stress-test mitigations

- How to read: *Failure-driven* mitigation. An agent running the installer on the same host is the new failure category that no devcontainer bless faces. It produced the `--yes` and TTY skip rules. The residual is stated rather than hidden. In this session the Bash tool has no TTY (verified 2026-09-23: fd 0 is `/dev/null` and `tty` prints "not a tty"). But util-linux `script` can wrap the installer in a pty, which is how the tests drive it. The check stops accidents, not intent. The backstop is sandbox `denyWrite ~/.claude` (guide §3).
- How to read: *Push to extreme* mitigation. Replacing a symlinked entry through the naive `rm -rf` + `cp -r` pair either writes into the checkout or empties it (verified in scratch). So the host target copies to `.cw-new.<name>`, moves the old entry (link or dir, never with a trailing slash) to the backup, and only then moves the new copy into place.
- How to read: *Invert the thesis* mitigation. For A, "don't change what an existing command does" was the tiebreaker. D honours most of it by skipping the host target before touching anything on every non-interactive run. So scripted callers see two extra lines (a blank line and the skip line), not a new behavior.

## Consequences

**Easier.** The checkout is inert on a bare host: an edit reaches `~/.claude` only through a shown review and a y. One command keeps both installs current, with nothing to remember. The guard's resolved-path HARD tier (R6/N12) stops mattering on a bare host, because `~/.claude/CLAUDE.md` and `~/.claude/hooks` resolve to themselves. That makes the checkout's `global-instructions/CLAUDE.md` editable again. `hooks/lib/` and `../scripts` now always travel with the hooks.

**Harder.** install.sh now writes a second host destination, so an agent edit to it has a wider blast radius. That raises the stakes of 035's still-pending regex. Every plain run asks a second question. The settings merge is still manual, and a changed `wiring.json` is only announced, not applied. Hand-installed skills in `~/.claude/skills` move to the backup on the first install.

## Trust model (Q-058)

The user answered Q-058 [2] on 2026-09-23: no agent may run during an install.

**What the installer is.** `install.sh` runs as the user's uid, from the checkout. So does every Claude Code session on the host. A cc-isolated container writes the checkout, `.git` included, through its bind mount, whatever uid it runs as. The stage in `$TMPDIR`, the checkout, its `.git` and (on a bare host) `~/.claude` are all writable by whatever else runs as the user's uid.

**The guarantee.** "What you reviewed is what is installed" holds only when no agent runs from the start of the install to the end of the swap. The hash check (R2) catches a stage edited while the prompt waits. It cannot catch an agent that rewrites the commit, the checkout's `.git` or the installer itself before the stage is built.

**How it is enforced.** `install.sh` refuses to run while an agent can run, and names each agent with how to stop it. It checks at startup, before either target stages anything, and again after each y, before that target writes to its destination. (The devcontainer target rebuilds its `claude-home` mirror inside the checkout before its prompt; that is a staging copy, not an install.)
- a Claude Code process of the user's uid: `pgrep -u <uid> -af` for a command line that runs `claude` (argv0 `claude` or `…/claude`, the native binary) or the npm package (`node …/bin/claude`, `…/@anthropic-ai/claude-code/…`). Without `pgrep` the install is refused.
- a running cc-isolated container: `docker ps --filter label=cc-project` (cc-isolated's `--id-label`). If docker is missing or unreachable, one line says so and no container is assumed.

**Residuals accepted.**
- File or directory names holding a TAB or newline: a TAB in a backup directory's name can mis-prune, and a relative `CLAUDE_HOME_DIR` from a working directory whose name holds a newline gets past the in-repo guard (fact-check final Claims 4 and 6; rubric A4, A5, parked). Both need a crafted name, which needs an agent, which the gate refuses.
- The checkout's git state (mitigated 2026-09-25, review R1). git runs commands named in the checkout's `.git/config` and `.git/info/attributes`. `git archive` runs a `filter.<x>.smudge` that an attributes file assigns, and `git status` runs `core.fsmonitor` and clean filters. A cc-isolated container writes `.git` through its bind mount, so an agent inside the *isolated* container could plant a command that the user's unsandboxed shell runs at the next install: a container-to-host path. The gate cannot see it, because the state persists after the container stops. So before any other git call, `install.sh` refuses and names each entry when the local config (or `config.worktree`) holds a `filter.*`, `core.fsmonitor` or `include*` key, or when `info/attributes` is non-empty. Both `git status` calls also pass `-c core.fsmonitor=false` (T65, T66). What remains: a command-running key outside that list, and the user's own global or system git config. Other git commands the user runs in the checkout are still exposed to what an agent plants there. `install.sh` is the one the bare host is required to run, which is why it checks.
- A process the probe misses: an agent on another host or in another container runtime writing the checkout (a network or shared mount), a renamed or wrapped binary whose command line does not end in `claude`, one running under another uid, or a docker the user's uid cannot reach.

Review record: [code-review-rubric-2026-09-23-ans-copy-install-final.md](../reviews/code-review-rubric-2026-09-23-ans-copy-install-final.md).

## Revisit triggers

How to read: each entry is a concrete, observable condition that should prompt re-evaluating this decision. Future readers can grep this section when their context changes to see whether earlier decisions still apply.

`if Q-049 is resolved → reconsider automating the settings.json merge from the host target.` `if any host ~/.claude install is traced to an agent session (backup stamp with no human at the terminal) → the TTY rule has failed in practice; move the host install off the agent-writable repo or require a sandbox denyWrite check before install.` `if 035's regex lands → confirm devcontainer-config/install.sh is covered, and drop the manual Live-verified trailers.` `if the user reports ~/.claude going stale again → the two-prompt run is being declined by reflex; consider H (a SessionStart staleness warning).` `if Gemini or Antigravity comes back into use → add it as a third target in the same run, not as a flag.` `if Claude Code's process shape changes (argv0 no longer claude or .../claude, and not the npm package path) or cc-isolated stops labelling containers cc-project → the Q-058 probe goes blind; update CLAUDE_PROC_RE or the docker filter.`
