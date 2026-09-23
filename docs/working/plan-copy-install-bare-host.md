# Plan: bare-host install by blessed copy, not symlink

- **Goal**: Replace the README's bare-host symlink install of the global files into `~/.claude` with copies that `devcontainer-config/install.sh` makes only after a human has read the diff and answered y.
- **Project state**: implements the Q-050 answer on `ans/copy-install` · follows the 2026-09-21 answers branch, whose guard redesign is paused at its review cap · not blocked; plan approved with shape D (cite: docs/decisions/037-bare-host-copy-install.md)
- **Task status**: in-progress (steps 1–8 implemented and verified on `ans/copy-install`; step 9, the host run, is the user's)

Research: [research-copy-install-bare-host.md](research-copy-install-bare-host.md)

## Revision 2026-09-23 (user answers)

The user's answers are binding and change the shape of the plan:
- **Q-054 [2] = shape D, not A.** A plain `install.sh` run offers every target in turn, each with its own diff and its own y/N: the devcontainer config first (as today), then the host `~/.claude` target. There are no target flags. The user's reason: "I *will* forget to add flags to install.sh." This is plan approval with D in place of A. Recorded in [decision 037](../decisions/037-bare-host-copy-install.md).
- **Q-055 [2]: Gemini is dropped.** Old step 4 (`--gemini`) is removed, along with the README's Gemini CLI and Antigravity install blocks.
- **Q-056 [1]: the host target refuses `--yes` and requires a TTY.** Under D, "refuse" means *skip the host target with a message*; it does not abort the run (see the next bullet).
- **Q-057 [1]: foreign files in install-owned directories move to `.claude-workflows-backup/<stamp>/`**, and the review lists each one.
- **The devcontainer target is unchanged for non-interactive runs.** A plain run with closed stdin, or with `--yes`, still does exactly what it does today for the devcontainer config. Only the host target is skipped, with a message, and the skip does not change the exit status.

## Approach

One installer and one run offer every install target, each gated by its own shown diff and its own y. This is DD pick D, chosen by the user (decision 037).
- **Target 1, the devcontainer config**: today's code path, extracted into functions but unchanged in behavior. The one change is what happens when the human declines it: the run moves on to target 2 instead of exiting. The exit status stays 1 and the `Aborted. Nothing was changed.` line is still printed.
- **Target 2, host `~/.claude`** (`${CLAUDE_HOME_DIR:-$HOME/.claude}`):
  - It is skipped, before it reads or stages anything, when `--yes` was given or stdin is not a TTY.
  - Otherwise it assembles the same seven-entry payload into a private temp stage and shows a symlink-aware review: every symlink it will replace, every foreign file it will move, and the content diff.
  - It asks y/N, then copies the entries in, moving whatever they replace into a timestamped backup directory.
- The `settings.json` wiring merge stays manual (research, Scope decisions). The installer prints a reminder when `hooks/wiring.json` changed.

## Steps

1. **docs: revise the plan to the answers** (this revision): the plan, the checkpoint, and decision record 037.
2. **docs: plan reviews.** Run `/pre-mortem` and `/architecture-review` on this plan. Save them to `docs/reviews/pre-mortem-copy-install.md` and `docs/reviews/architecture-review-copy-install.md`, and fold their findings into Steps and Failure modes.
3. **test: hermetic suite for the host target** (`test/install-host.bats`, new). T1–T19 from the Test specification.
   - The fake-repo helper is copied from `test/cc-isolated-functions.bats:586-602` rather than shared.
   - `setup()` exports `HOME`, `CLAUDE_HOME_DIR`, `CLAUDE_DEVC_CONFIG_DIR`, `CLAUDE_DEVC_BIN_DIR` and `TMPDIR` into `BATS_TEST_TMPDIR`.
   - Runs are non-TTY (`</dev/null` or a pipe) unless a test deliberately drives a pty with `script -qec "<cmd>" /dev/null`, fed `n\ny\n` (decline the devcontainer, accept the host). The file skips with a reason if `script` is absent.
   - Confirm the suite fails against the current install.sh, with every destination still pointed at scratch.
4. **refactor: argument parsing and function extraction, no behavior change.**
   - Replace `ASSUME_YES="${1:-}"` with a loop accepting `--yes` and `-h`/`--help`. Anything else prints usage to stderr and exits 2, before assembly.
     - This changes behavior only for invalid input. Today a typo like `--yse` silently means "no".
   - Extract `assemble <stage-dir>` (current `:49-79`: fatal on a missing source, writes `.manifest`) and `review_diff <dest> <src> <item...>` (current `:85-114`).
     - `review_diff` reports "changed" through its return status (0 = no change, 1 = changed) instead of a global. It still exits the script on diff trouble.
   - Wrap the devcontainer flow in `install_devcontainer`, called from a short main sequence (architecture review #1). The devcontainer flow is otherwise unchanged.
   - `usage()` states the CLI contract: the targets in order, the skip rules, and exit codes 0/1/2 (architecture review #4).
   - `test/cc-isolated-functions.bats` passes unmodified.
5. **feat: host `~/.claude` target in the default run.**
   - **Structure** (architecture review #1–#3):
     - a new function `install_claude_home`, called after `install_devcontainer` in the main sequence;
     - the host entry names are computed once as the `basename` of each `CLAUDE_HOME_SRC` item, never a restated list;
     - the host review is a print-and-count pre-pass followed by the shared `review_diff`.
   - **Destination**: `${CLAUDE_HOME_DIR:-${CLAUDE_CONFIG_DIR:-$HOME/.claude}}`. The review's first line names which variable chose it (pre-mortem #5).
   - **Per-target decline.** Declining the devcontainer target prints `Aborted. Nothing was changed. (devcontainer config)`, records the decline and continues to the host target. The final exit status is 1 if any target was declined.
     - Diff trouble and missing sources stay fatal for the whole run.
     - The devcontainer install, `--bless` and bin link run exactly as today when the answer is y.
   - **Skip rules**, checked first, before any read of the host destination or any staging:
     - `--yes` → `Skipped host target (~/.claude): it never installs with --yes …`
     - `[ -t 0 ]` false → `Skipped host target (~/.claude): it needs an interactive terminal …`
     - `CLAUDECODE` set (it is set in the Claude Code Bash tool environment) → `Skipped host target: running inside a Claude Code session …` (pre-mortem #4)
     - A skip does not change the exit status.
   - **Destination guards.** Refuse (exit 1, nothing written) when:
     - the destination resolves inside the repo checkout (`pwd -P` prefix check), which catches `~/.claude` itself being a symlink into the checkout;
     - `$DEST/.claude-workflows-backup` is a symlink or resolves inside the checkout (pre-mortem #3);
     - any `$DEST/.cw-new.*` leftover is a symlink (pre-mortem #3).
   - **Dirty warning.** If the stage manifest says `dirty=yes`, print a prominent `WARNING: the checkout has uncommitted changes; they are included in this install` line above the prompt. The pre-mortem's optional second prompt is not adopted; see Risks.
   - **Stage** with `assemble` into `mktemp -d "${TMPDIR:-/tmp}/cw-host-stage.XXXXXX"`, with an EXIT trap that removes it. The stage never goes into `$SRC/claude-home`.
   - **Symlink-aware review**, for each of the seven entry names:
     - If `$DEST/<name>` is a symlink: print `REPLACE symlink <dest> -> <target> with a copy` and count it as a change.
     - If it is a real directory: `find -type l` inside it (per-file hook links) prints one `REPLACE symlink` line per link, each counted as a change. Every regular file or link inside it that the stage lacks prints as `MOVE to backup (not in the repo): <path>`, with a one-line warning above the list. For a foreign file under `hooks/` whose basename appears in `$DEST/settings.json` or `settings.local.json`, the line also says `WIRED in settings: moving it breaks that hook` (pre-mortem #2).
     - Then `diff -ruN "$DEST/<name>" "$STAGE/<name>"`: exit 1 counts as a change, exit >1 aborts before the prompt.
     - `(none — ~/.claude already matches the repo)` only when nothing above fired.
   - **Prompt**: `Install these files into <dest>? [y/N]`. EOF means no.
   - **Install**, all or nothing up to the swap:
     1. For each entry, `rm -rf "$DEST/.cw-new.<name>"` (clearing leftovers, no trailing slash), then `cp -R "$STAGE/<name>" "$DEST/.cw-new.<name>"`. On any failure, remove the `.cw-new.*` copies and exit 1 before touching a live entry.
     2. Create `$DEST/.claude-workflows-backup/<UTC stamp>/`. If that directory exists, append `.$$` to the stamp.
     3. For each entry that exists or is a link, `mv "$DEST/<name>" "$BACKUP/<name>"`, with no trailing slash, so a link moves as a link.
     4. `mv "$DEST/.cw-new.<name>" "$DEST/<name>"`, after checking that nothing is at `$DEST/<name>`.
   - **Provenance**: `rm -f`, then `cp` the stage `.manifest` to `$DEST/.claude-workflows-manifest`. The `rm` stops a planted symlink from redirecting the write. Then append `installed_by=host-tty`, `installed_parent=<parent process command name>` and `installed_at=<stamp>` (additive keys, architecture review #5; pre-mortem #4).
   - **Wiring reminder**: computed before the swap. If `$DEST/hooks/wiring.json` is missing or differs from the stage's copy, print a loud reminder to redo `guides/bare-host-hook-wiring.md` §2.
   - Print the backup path.
   - Never call `--bless`, and never create the devcontainer config dir or the bin link from this target.
   - Rewrite the header comment (`:1-14`). install.sh now also writes the host `~/.claude`, and its own edits are not inert (035 H5).
   - Commit trailer: `Live-verified: no — <host run in step 9>` (decision 035).
6. **docs: README and guides.**
   - README Linux/macOS block: replace the `mkdir`/`ln -s`/`cp` lines with `./devcontainer-config/install.sh` and a description of the two prompts. Add a "migrating from the symlink install" paragraph: the review shows each replaced link, and the old links land in `.claude-workflows-backup/`. Close Claude Code sessions first, and check any `WIRED` lines before answering y.
   - Remove the Gemini CLI and Antigravity install blocks. The file list keeps `GEMINI.md`, with a note that no install recipe ships.
   - "Configuration outside this repo" table: the hook-copies row now says installed by `install.sh`.
   - Line 193: drop "(symlinked to `~/.claude/skills` …)".
   - `guides/bare-host-hook-wiring.md`:
     - Scope: drop "a plain checkout symlinked into `~/.claude`".
     - §1: one convention, the install.sh copy. The symlink-vs-copy split and the `claude-config-audit.sh` follow-up are superseded.
     - §2's last paragraph: the installer says when `wiring.json` changed.
   - `guides/README.md:47`: the one-line summary.
   - Per-project AGENTS.md symlinks are unaffected; say so.
7. **docs: 035 Consequences note.** install.sh now writes host `~/.claude`, which raises the stakes of 035's pending regex.
8. **verify**: run the new suite, `test/cc-isolated-functions.bats`, `test/link-claude-home-wiring.bats`, the `test/hooks/*.bats` suites, and `scripts/run-tests.sh --fast` if it is quick. Fill in Actual context cost.
9. **you: terminal — host migration and live check** (not an agent step). On the host:
   1. Run `./devcontainer-config/install.sh`. Answer the devcontainer prompt as usual. Read the `~/.claude` review (expect `REPLACE symlink` lines) and answer y.
   2. Start a Claude Code session. Confirm a skill loads and `~/.claude/logs/usage.jsonl` gains a line.
   3. Run the guide §4 checks.
   4. Confirm `global-instructions/CLAUDE.md` in the checkout is now editable with Edit (the R6 symptom is gone).

## Implementation order

`1 → 2 → 3 → 4 → 5 → [6, 7] → 8 → 9`

Steps 1 and 2 are docs. Step 3 writes the failing tests. Step 4 is a pure refactor pinned by the existing suite, and it lands before 5 so the host code reuses the extracted functions. Docs (6, 7) need the final behavior. Step 8 verifies. Step 9 is the human's run after merge.

## Size estimate

| Step | Size |
|---|---|
| 1 | plan rewrite + ~100-line decision record |
| 2 | two review artifacts, plan edits |
| 3 | ~350 lines, new `test/install-host.bats` |
| 4 | ~50 lines changed in install.sh (158 → ~185) |
| 5 | ~150 lines added to install.sh (→ ~340; under 500) |
| 6 | ~70 lines changed across README, bare-host guide, guides/README |
| 7 | ~5-line 035 note |
| 9 | host time ~10 min |

Estimated context cost: Research ~60k (done), Implementation ~90k, Review ~45k.
Actual context cost (post-implementation): plan revision ~40k, Implementation ~75k, Review ~20k. These are estimates of new material read and written. The session counter shows ~350k cumulative, because it includes the ~60k standing context re-sent on every turn. Within budget; no pause triggered.

## Implementation notes and deviations (written back 2026-09-23)

- **Existing test edited (deviation).** `test/link-claude-home-wiring.bats` test 14 grepped the README for the old `ln -s ~/claude-workflows/scripts ~/.claude/scripts` line. That is exactly what Q-050 retires. Its intent (the bare-host install makes `~/.claude/scripts` resolve) is kept by re-pointing the assertion: `scripts` must be in `CLAUDE_HOME_SRC`, and the README must point at `./devcontainer-config/install.sh`. The behavior itself is covered by `test/install-host.bats` T9. `test/cc-isolated-functions.bats` is unmodified, as planned.
- **Stage layout.** The host stage is `$HOST_TMP/payload` inside the `mktemp -d` dir, not the mktemp dir itself. `assemble` does `rm -rf` + `mkdir -p` on its argument, which would have reset mktemp's 0700 mode.
- **Extra guards** beyond the step 5 list: a dangling-symlink destination, and a destination that exists but is not a directory, are both refused.
- **`installed_parent=`** records the parent process's command name. Under a `script` pty wrapper it reads `script` (seen in the tests), which leaves an audit trace for the agent-bypass case the TTY rule cannot stop.
- **Tests**: 24 (T1–T24), not 19, after the review fold-in. The suite is tagged `@category slow`.
- **install.sh is 464 lines**, under the 500 guideline.

## Test specification

Not generated by the `test-strategy` skill. Manual test specification with hand-assigned gap IDs, revised for D:
- **G1**: no test drives install.sh's y path.
- **G2**: a non-human run of the host target.
- **G3**: symlinked destinations make the diff silent.
- **G4**: `cp`/`rm` through a symlink writing into, or emptying, the checkout.
- **G5**: user state in `~/.claude`.
- **G6**: hermeticity.
- **G7**: a host install leaking into devcontainer state.
- **G8**: devcontainer regression.
- **G9**: hook sibling resolution after copy.
- **G10**: provenance.
- **G11**: wiring drift.
- **G12**: diff failure.
- **G13**: foreign content.
- **G14**: a destination inside the checkout.
- **G15**: argument parsing.
- **G16**: partial failure.
- **G17**: per-target decline under D.

"pty n,y" means driven through `script` with input `n\ny\n`: decline the devcontainer, accept the host.

| # | Test case (closes) | Expected behavior | Level | Diagnostic expectation |
|---|---|---|---|---|
| T1 | plain run, closed stdin (G2, G8) | devcontainer prompt declines as today (`Aborted. Nothing was changed.`, exit 1); host `Skipped … interactive terminal`; `CLAUDE_HOME_DIR` listing and checksums unchanged; no `cw-host-stage.*` in TMPDIR | integration | before/after listing diff |
| T2 | `n\ny\n` piped, no TTY (G2) | host skipped; dest unchanged | integration | output + listing |
| T3 | `--yes`, no TTY (G2, G8) | devcontainer installs (stub `--bless` runs), exit 0; host `Skipped … --yes`; dest unchanged | integration | output |
| T4 | `--yes` inside a pty (G2) | host still skipped: the `--yes` rule does not depend on the TTY | integration | output |
| T5 | migration review, pty n,n (G3) | one `REPLACE symlink` line per README-style link (5 dir links, CLAUDE.md, per-file hook links) before the host prompt; no `(none`; dest unchanged after n | integration | full output |
| T6 | migration, pty n,y (G1, G4) | every entry a real file/dir equal to the repo source; fake checkout checksums unchanged; no `checkout/skills/skills`; backup holds the old links as links; a planted `.claude-workflows-manifest` symlink into the checkout left the checkout file unchanged | integration | checksum lists, backup listing |
| T7 | user state preserved (G5) | `settings.json`, `settings.local.json`, `projects/x`, `memory/m.md`, `logs/usage.jsonl`, `.credentials.json` byte-identical after y | integration | per-sentinel sha |
| T8 | hermeticity (G6, G7) | after pty n,y: `CLAUDE_DEVC_CONFIG_DIR` and `CLAUDE_DEVC_BIN_DIR/cc-isolated` absent; nothing under `$HOME` outside `CLAUDE_HOME_DIR` changed; no stage left in TMPDIR; `$SRC/claude-home` exists only because the devcontainer target assembles it | integration | `find -newer` listing |
| T9 | hooks resolve siblings (G9) | with real `hooks/` + `scripts/` in the fake repo: installed `hooks/log-usage.sh`, fed a Skill event with scratch HOME, exits 0 and appends a line to `$HOME/.claude/logs/usage.jsonl` | integration | hook stderr |
| T10 | manifest (G10) | `.claude-workflows-manifest` has `commit=` and `assembled_from=<fake repo>` | unit | contents |
| T11 | wiring reminder (G11) | first install: reminder names guide §2; identical second install: no reminder and `(none`; changed `wiring.json`: reminder | integration | outputs |
| T12 | diff failure (G12) | a file at `$DEST/skills` where the stage has a dir → `could not diff`, no host prompt, exit 1, dest unchanged | integration | output |
| T13 | foreign file (G13) | a file `skills/mine/SKILL.md` not in the repo is listed as `MOVE to backup`; after y it is in the backup, not in `skills/` | integration | backup listing |
| T14 | destination inside the checkout (G14) | `CLAUDE_HOME_DIR` a symlink to a dir in the fake repo → refused, nothing written | integration | output + checksums |
| T15 | unknown flag (G15) | usage on stderr, exit 2, `$SRC/claude-home` not created | unit | output |
| T16 | partial failure (G16) | dest dir read-only → error, exit 1; every entry unchanged; no backup dir; no `.cw-new.*` | integration | dest listing |
| T17 | host decline, pty n,n (G17) | exit 1; host `Aborted`; dest unchanged; stage removed | integration | output |
| T18 | first install into a missing dest (G1) | dest created with all seven entries, the manifest and no backup dir contents | integration | listing |
| T19 | devcontainer y still installs, then host offered (G8, G17) | pty y,n: devcontainer installed (stub bless ran), host prompt shown and declined, exit 1 | integration | output |
| T20 | wired foreign hook (G13; pre-mortem #2) | foreign `hooks/mine.sh` named in a scratch `settings.json` → review line carries `WIRED in settings` | integration | output |
| T21 | planted backup-dir symlink (G4; pre-mortem #3) | `.claude-workflows-backup` → a dir in the fake repo: exit 1, no entry moved, fake repo checksums unchanged | integration | output + checksums |
| T22 | `CLAUDECODE=1` inside a pty (G2; pre-mortem #4) | host target skipped with the Claude Code message; dest unchanged | integration | output |
| T23 | dirty checkout (pre-mortem #4) | fake repo is a git repo with an uncommitted change → review shows the dirty WARNING | integration | output |
| T24 | `CLAUDE_CONFIG_DIR` honoured (G6; pre-mortem #5) | `CLAUDE_HOME_DIR` unset and `CLAUDE_CONFIG_DIR` set → install lands there and the review names the variable | integration | listing |

The pty tests unset `CLAUDECODE` for the child: this suite itself runs under Claude Code, where the variable is set. That is the T22 rule working as intended.

Existing regression (G8): `test/cc-isolated-functions.bats` passes unmodified.

## Failure modes considered

Required: more than 5 steps, and a trust boundary (host file I/O into policy dirs).

| Failure mode | Guard |
|---|---|
| The migration diff says "(none)" because `diff` follows the symlink, and the human blesses a change they never saw | T5; the `-L` and `find -type l` notices count as changes |
| An install empties or writes into the checkout through a link (`rm -rf link/`, `cp -r` into a link, a planted manifest link, `~/.claude` itself a link) | T6, T14; structural: copy to `.cw-new.*`, move with no trailing slash, `rm -f` before the manifest write, and a checkout-prefix guard |
| An agent self-blesses a host install via Bash | T2, T3, T4; structural: `--yes` skips the host target and non-TTY stdin skips it. **Residual:** an agent can wrap the installer in `script` to get a pty (see Risks) |
| A host install clobbers `settings.json`, memory or credentials | T7; structural: only the seven named entries are touched |
| A copied `log-usage.sh` fails every tool call because `hooks/lib` wasn't copied | T9; structural: whole-dir copies |
| Under D, an existing non-interactive devcontainer run now touches `~/.claude` or the real HOME | T1, T3; structural: the skip rules run before any read or stage of the host dest; `cc-isolated-functions.bats` unmodified |
| A test writes the real `~/.claude` or relinks the real `~/.local/bin/cc-isolated` | T8; `setup()` pins HOME, `CLAUDE_CONFIG_DIR` and every `*_DIR` |
| A foreign hook wired in `settings.json` is moved to the backup and fails open (pre-mortem #2) | T20; the `WIRED` line in the review |
| The backup dir is a planted symlink and the old entries land in the checkout (pre-mortem #3) | T21; the backup-dir guard |
| The install goes to `~/.claude` while Claude Code reads `$CLAUDE_CONFIG_DIR` (pre-mortem #5) | T24; destination precedence |
| A payload entry added to `CLAUDE_HOME_SRC` never reaches the host (architecture review #2) | structural: host names derived by `basename`; T6 compares every entry |

Round-1 triggers:
- `/pre-mortem`: **triggered and run.** Output: `docs/reviews/pre-mortem-copy-install.md`. Folded in:
  - #2 → WIRED line and T20;
  - #3 → backup-dir guard and T21;
  - #4 → `CLAUDECODE` skip, `installed_by` provenance, dirty warning, T22/T23;
  - #5 → `CLAUDE_CONFIG_DIR` precedence and T24;
  - the mid-swap note → the README migration paragraph.
  - #1 (quiet drift) is acknowledged via decision 037's revisit trigger.
- `/architecture-review`: **triggered and run.** Output: `docs/reviews/architecture-review-copy-install.md`. Findings #1–#5 folded into steps 4–5. #6 is covered by step 7.

## Risks

- **The TTY barrier does not stop a determined agent.** Verified 2026-09-23 in this session: the Bash tool gives commands no TTY (`[ -t 0 ]`, `[ -t 1 ]` and `[ -t 2 ]` are all false, `tty` prints "not a tty", and fd 0 is `/dev/null`). A piped `y` is therefore refused. But util-linux `script` is installed, and `script -qec ./devcontainer-config/install.sh /dev/null <<<$'n\ny\n'` gives the child a pty. That is exactly how this plan's own tests drive the y path. The TTY check stops the accidental case (an agent running the installer as part of a routine) and makes the deliberate case conspicuous. It does not stop an agent that sets out to bless its own edit. The backstops are the sandbox `denyWrite ~/.claude` for Bash (manual hardening, guide §3) and `permissions.deny` for the Bash tool's direct writes. A host without that sandbox setting has no hard barrier.
- **The `CLAUDECODE` skip is the same kind of barrier as the TTY check.** An agent can `env -u CLAUDECODE`. Needing both a faked pty and an unset variable makes the deliberate case conspicuous in a transcript; it does not make it impossible.
- **Dirty stage: warning only.** The pre-mortem suggested an optional second confirmation for a dirty checkout. Not adopted: it adds a ritual prompt, and the diff already shows the content. Revisit if a dirty install is ever regretted.
- **Mid-swap window.** Between the moves, a running session can briefly find no hook file. The README asks the user to close Claude Code sessions before installing.
- **D changes what an existing command does.** A plain run now asks a second question. Non-interactive runs are unchanged except for one extra skip line.
- **Exit status under D**: 1 if any target was declined. A human who declines the devcontainer target and accepts `~/.claude` gets exit 1. That matches "declined = 1" today, and no caller depends on it.
- **035's regex has not landed.** install.sh commits carry `Live-verified: no — …` trailers anyway.
- **Q-049 unresolved.** The copied hooks may be wired to deny rules that match nothing. This plan leaves that as it is and does not automate the merge.
- **Foreign content is moved, not preserved** (Q-057 [1]). A user's own skills leave `~/.claude/skills` until restored from the backup.
- **Same-user TOCTOU between review and copy.** The stage is a `mktemp -d` owned by the same user the agent runs as. An agent racing the human's read could alter it. Same exposure as the devcontainer stage in `$SRC/claude-home`, and not closable within a same-user model.
- **macOS**: the code avoids GNU-only flags (`mv -T`, `cp --no-dereference`). `cp -R` of a stage with no symlinks behaves the same. Not tested on macOS.
- Deferred: a SessionStart staleness warning (DD [9]) and an automated settings merge.

## Rollback

1. Code: `git revert` the step-4 to step-7 commits on `ans/copy-install` (or on main after the merge), newest first. The devcontainer path is pinned by `cc-isolated-functions.bats` and T3/T19, and it needs no re-run or re-bless: the installed `~/.config/claude-devcontainer` payload never depended on the host-target code.
2. Host `~/.claude`, if an install went wrong: the previous entries are in `~/.claude/.claude-workflows-backup/<stamp>/`. From a plain shell outside Claude Code (the guard and sandbox will rightly block it inside), for each of `skills workflows guides patterns hooks scripts CLAUDE.md`:
   - `rm -rf ~/.claude/<name>` (**no trailing slash**)
   - `mv ~/.claude/.claude-workflows-backup/<stamp>/<name> ~/.claude/<name>`

   The backup holds the original symlinks as symlinks, so this restores the symlink install exactly. Then `rm -f ~/.claude/.claude-workflows-manifest` if the symlink install had none.
3. `settings.json` is never written by this change: nothing to restore.
4. Docs: the README revert restores the `ln -s` recipe and the Gemini blocks.

Irreversible component: none. Replacing entries is a move into the backup, which the user deletes by hand.
