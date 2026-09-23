# Plan: bare-host install by blessed copy, not symlink

- **Goal**: Replace the README's bare-host symlink install of the global files into `~/.claude` (and decide whether `~/.gemini` follows) with a copy that `devcontainer-config/install.sh` makes only after a human has read the diff and answered y.
- **Project state**: docs-only research and plan for the Q-050 answer (2026-09-23) · follows the 2026-09-21 answers branch, whose guard redesign is paused at its review cap · not blocked (cite: 970e525)
- **Task status**: in-progress (plan drafted, awaiting approval; DD pick is tentative, Path C)

Research: [research-copy-install-bare-host.md](research-copy-install-bare-host.md)

## Approach

Add explicit host targets to the existing installer, so one diff-and-bless code path serves every destination. This is DD pick [2] A: tentative, 70% confidence; the runner-up is D.
- `install.sh` with no target flag keeps its current devcontainer behavior exactly.
- `install.sh --claude-home` stages the same seven-entry `claude-home` payload the image uses and diffs it against `~/.claude`. The diff names every symlink it will replace. It asks y/N at an interactive terminal and swaps the entries in, moving the old ones to a backup dir.
- `install.sh --gemini` does the same for `~/.gemini`'s six entries.
- The settings.json wiring merge stays manual (research, Scope decisions). The installer only reports when `hooks/wiring.json` changed.

## Steps

1. **test: hermetic suite for the host targets** (`test/install-host.bats`, new). Build tests T1–T17 from the Test specification.
   - Adapt the fake-repo helper: copy `fake_install_repo` from `test/cc-isolated-functions.bats:586-602` rather than share it. That suite is 1084 lines, and a shared lib is a later refactor.
   - `setup()` exports `HOME`, `CLAUDE_HOME_DIR`, `GEMINI_HOME_DIR`, `CLAUDE_DEVC_CONFIG_DIR`, `CLAUDE_DEVC_BIN_DIR` and `TMPDIR` into `BATS_TEST_TMPDIR`. Every run gets `</dev/null` unless it deliberately drives a pty.
   - Drive the y path with `script -qec "<cmd>" /dev/null` fed `y\n` (util-linux `script` is present here). Skip with a reason if `script` is absent.
   - All must fail against current install.sh: unknown flag / no host target. When proving that against old code, keep every destination pointed at scratch (memory note).
2. **refactor: argument parsing in install.sh, no behavior change.**
   - Replace `ASSUME_YES="${1:-}"` with a loop accepting `--yes`, `--devcontainer` (default), `--claude-home` and `--gemini` in any order. Anything else prints usage and exits 2 before assembly.
   - Extract two functions without changing the devcontainer flow:
     - `assemble <stage-dir> <entry...>`: the current `:49-79` loop with the fatal-missing check and the `.manifest` write.
     - `review_diff <dest> <stage> <item...>`: the current `:85-114`.
   - `test/cc-isolated-functions.bats` must pass unmodified.
3. **feat: `--claude-home` target.**
   - `CLAUDE_HOME_DEST="${CLAUDE_HOME_DIR:-$HOME/.claude}"`. Stage into `mktemp -d` under `${TMPDIR:-/tmp}` with a cleanup trap, *not* into `$SRC/claude-home`, so a host run leaves the devcontainer staging and diff state alone. The entries are the same `CLAUDE_HOME_SRC` array (invariant 3).
   - **Symlink-aware review**: for each entry whose destination is `-L`, print `REPLACE symlink <dest> -> <readlink target> with a copy` and count it as a change, then diff the resolved target against the stage. Print foreign files inside an owned real dir as deletions with a one-line warning.
   - **Prompt**: host targets refuse `--yes` (exit 2) and refuse a non-TTY stdin (`[ -t 0 ]` false → "host install needs an interactive terminal", exit 1) *before* any write. EOF is still "no".
   - **Install**, for each entry:
     1. `cp -r "$STAGE/$name" "$DEST/.cw-new.$name"`.
     2. Only after all copies succeed, move the current entry (link or real, never with a trailing slash) to `$DEST/.claude-workflows-backup/<UTC-stamp>/$name`.
     3. `mv` the new copy into place.
   - Write `$DEST/.claude-workflows-manifest` from the stage's `.manifest`. Print the backup path.
   - If the new `hooks/wiring.json` differs from the backed-up one, or none was installed, print a loud reminder to redo `guides/bare-host-hook-wiring.md` §2.
   - Never call `cc-isolated.sh --bless`. Never create the devcontainer config dir or the bin link.
   - Update the header comment (`:1-14`): install.sh now also writes host dirs, so "edits here are inert" is doubly false; say so, per 035 H5.
4. **feat: `--gemini` target.**
   - `GEMINI_HOME_DEST="${GEMINI_HOME_DIR:-$HOME/.gemini}"`, entries `GEMINI.md workflows skills patterns guides global-instructions`, staged under their repo paths. `global-instructions` is copied as a directory, so GEMINI.md's `global-instructions/CLAUDE.md` pointer resolves.
   - Same review, prompt, swap, backup and manifest as step 3. No wiring reminder.
   - Can be dropped without affecting steps 1–3 if the user says Gemini is unused.
5. **docs: README + guides.**
   - README Linux/macOS block: replace the `ln -s` and `cp` lines with `./devcontainer-config/install.sh --claude-home`, plus a "migrating from the symlink install" paragraph (the diff shows each replaced link; the old links land in `.claude-workflows-backup/`).
   - Gemini block: the same, with `--gemini`.
   - Antigravity-on-Windows: `GEMINI_HOME_DIR=/mnt/c/Users/<you>/.gemini ./devcontainer-config/install.sh --gemini`, marked unverified. Keep the PowerShell symlink recipe under a "deprecated" note until the user confirms.
   - "Configuration outside this repo" table: the hook-copies row now says installed by `--claude-home`.
   - Line 193: drop "(symlinked to `~/.claude/skills`...)".
   - `guides/bare-host-hook-wiring.md`: rewrite §1 to one convention, the install.sh copy, closing the claude-config-audit symlink follow-up. Fix "a plain checkout symlinked into `~/.claude`" in Scope. §2's last paragraph: the installer now tells you when wiring.json changed.
   - `guides/README.md:47`: the one-line summary.
   - Note that AGENTS.md per-project symlinks are unaffected.
6. **docs: decision record** `docs/decisions/0NN-bare-host-install-by-blessed-copy.md` (next free number).
   - Promote the research doc's DD section: context = the Q-050 answer. Record the chosen flag design, the settings-merge scope-out, the "bless on a bare host" definition, and revisit triggers:
     - Q-049 resolved → reconsider automating the merge;
     - a report of an agent-run host install → strengthen S3;
     - the 035 regex lands → confirm install.sh is covered.
   - Add a Consequences note to 035: install.sh now writes host dirs, which raises the stakes of its pending regex.
7. **you: terminal — host migration and live check** (not an agent step). On the host:
   1. `./devcontainer-config/install.sh --claude-home`, read the diff, answer y.
   2. Start a Claude Code session, confirm a skill loads and `~/.claude/logs/usage.jsonl` gains a line.
   3. Run the guide §4 checks.
   4. Confirm `global-instructions/CLAUDE.md` in the checkout is now editable with Edit (the R6 symptom gone).
   5. Optionally repeat with `--gemini`.

## Implementation order

`1 → 2 → 3 → 4 → [5, 6] → 7`

Step 1 writes the failing tests. Step 2 is a pure refactor that the existing suite pins, and it must land before 3 so the host code reuses the extracted functions. Step 4 reuses step 3's swap and backup. Docs (5) and the decision record (6) are independent of each other and need the final flag names. Step 7 is the human's host run after merge. If Gemini is dropped, 4 is skipped and 5 loses its Gemini paragraph.

## Size estimate

| Step | Size |
|---|---|
| 1 | ~350 lines, new `test/install-host.bats` |
| 2 | ~60 lines changed in install.sh (158 → ~180) |
| 3 | ~130 lines added to install.sh (→ ~310) |
| 4 | ~40 lines (→ ~350; under 500, no split needed) |
| 5 | ~60 lines changed across README, bare-host guide, guides/README |
| 6 | ~90-line decision record + 3-line 035 note |
| 7 | host time ~10 min |

Estimated context cost: Research ~60k, Implementation ~90k, Review ~45k.
Actual context cost (post-implementation): __

## Test specification

Not generated by the `test-strategy` skill: this was a docs-only subagent pass that was told to plan, not invoke skills. The manual test specification follows, with hand-assigned gap IDs.

Gaps:
- **G1**: no test drives install.sh's y path.
- **G2**: nothing stops a non-human run of a host install.
- **G3**: symlinked destinations make the diff silent (research gotcha).
- **G4**: `cp`/`rm` through a symlink can write into, or empty, the checkout.
- **G5**: user state in `~/.claude`.
- **G6**: hermeticity of the new destinations.
- **G7**: host run leaking into devcontainer state.
- **G8**: devcontainer regression.
- **G9**: hook sibling resolution after copy.
- **G10**: provenance.
- **G11**: wiring drift.
- **G12**: diff failure.
- **G13**: foreign content in owned dirs.
- **G14**: Gemini target isolation.
- **G15**: arg parsing.
- **G16**: partial failure.

| # | Test case (closes) | Expected behavior | Level | Diagnostic expectation |
|---|---|---|---|---|
| T1 | `--claude-home` with closed stdin (G1, G2) | exit 1, "Aborted"/no-TTY message; dest tree byte-identical (compare `find -printf '%p %y %l\n'` + checksums before/after) | integration | print the before/after listings diff |
| T2 | `--claude-home` with `y` piped (non-TTY) (G2) | refused before any write, exit 1 | integration | output plus dest listing |
| T3 | `--claude-home --yes` (G2) | exit 2, nothing written | unit | output |
| T4 | migration: dest has README-style symlinks (dirs, CLAUDE.md, per-file hooks) (G3) | review output contains one `REPLACE symlink` line per link, before `bless it?`; no "(none" | integration | full output |
| T5 | migration y path via pty (G1, G4) | every entry is a real file/dir, `diff -r` stage vs dest = 0; **fake checkout checksum unchanged**; no `checkout/skills/skills` | integration | checksum lists before/after, `find checkout -newer` |
| T6 | user state preserved (G5) | `settings.json`, `settings.local.json`, `projects/x`, `memory/m.md`, `logs/usage.jsonl`, `.credentials.json` sentinels byte-identical after y | integration | per-sentinel sha before/after |
| T7 | hermeticity (G6, G7) | after y: `CLAUDE_DEVC_CONFIG_DIR` and `CLAUDE_DEVC_BIN_DIR/cc-isolated` do not exist; `$SRC/claude-home` not created; nothing under `$HOME` except `CLAUDE_HOME_DIR` changed | integration | `find $BATS_TEST_TMPDIR -newer <stamp>` |
| T8 | default run unchanged (G8) | `test/cc-isolated-functions.bats` passes unmodified | regression | bats TAP output |
| T9 | hooks resolve siblings (G9) | installed `hooks/lib/usage-common.sh`, `scripts/lib/skill-paths.sh`, `scripts/claude_config_audit.py` exist; `bash $DEST/hooks/log-usage.sh <<<'{}'` exits 0 with scratch HOME (fixture repo uses real hook+lib copies for this test) | integration | stderr of the hook run |
| T10 | manifest written (G10) | `$DEST/.claude-workflows-manifest` has `commit=` and `assembled_from=<fake repo>` | unit | file contents |
| T11 | wiring reminder (G11) | changed `hooks/wiring.json` → reminder line naming guide §2; unchanged second install → no reminder | integration | output of both runs |
| T12 | diff failure aborts (G12) | dest entry of the wrong type (file where the stage has a dir, unreadable) → "could not diff", no prompt, exit 1 | integration | output |
| T13 | foreign file in owned real dir (G13) | diff shows it as a deletion plus a warning; after y it is in the backup dir, not lost | integration | backup listing |
| T14 | `--gemini` (G14) | six entries in `GEMINI_HOME_DIR`, `global-instructions/CLAUDE.md` present, nothing written to `CLAUDE_HOME_DIR` | integration | both listings |
| T15 | unknown flag (G15) | usage on stderr, exit 2, no staging dir created | unit | output |
| T16 | `--yes` anywhere still works for devcontainer (G15) | `install.sh --devcontainer --yes` reaches install with a stubbed `cc-isolated.sh --bless` | integration | output |
| T17 | partial failure (G16) | stage copy fails (dest parent read-only) → error, no entry swapped, no backup dir with partial content | integration | dest listing |

Coverage beyond scope: the TTY check's value against a real Claude Code Bash tool is [assumed]. Only step 7 on the host, or a follow-up probe, can confirm it.

## Failure modes considered

Required: more than 5 steps, and a trust boundary (host file I/O into policy dirs).

| Failure mode | Guard |
|---|---|
| Migration diff says "(none)" because `diff` follows the symlink, and the human blesses a change they never saw | T4; step 3's `-L` notice counted as a change |
| An install empties or writes into the user's checkout through a link (`rm -rf link/`, `cp -r` into a link) | T5 checkout checksum; structural: move-then-swap with no trailing slash, never `cp` onto an existing dest |
| An agent self-blesses a host install via Bash | T2/T3; structural: `--yes` refused and TTY required for host targets; sandbox `denyWrite ~/.claude` as backstop |
| A host install silently clobbers `settings.json`, memory or credentials | T6; structural: only the seven named entries are ever touched |
| Copied `log-usage.sh` fails every tool call because `hooks/lib` wasn't copied | T9; structural: whole-dir copy of `hooks` and `scripts` |
| A test run relinks the real `~/.local/bin/cc-isolated` or writes the real `~/.claude` | T7; `setup()` pins HOME and every `*_DIR` |

Round-1 triggers:
- `/pre-mortem`: **triggered, not run.** The plan touches a security boundary: the host installer is the bless gate and writes policy files under `~/.claude`. This docs-only subagent pass was told to annotate, not invoke. Run it on this plan before approval; output to `docs/reviews/pre-mortem-copy-install-bare-host.md`.
- `/architecture-review`: **triggered, not run.** Files to touch span `devcontainer-config/`, `test/`, `guides/`, `docs/decisions/` and the root README, which is 2 or more modules. It was deferred for the same reason. Run it before approval; output to `docs/reviews/architecture-review-copy-install-bare-host.md`. The main question for it: does a host target in a devcontainer-named directory's installer blur the 016/035 boundary more than a separate script (DD runner-up B)?

## Risks

- **DD pick is tentative (Path C).** Its axis: one run covering every target (D) vs one boundary per bless (A). If the user prefers D, steps 2–3 change shape (a default multi-prompt flow) but not substance.
- **TTY barrier is [assumed].** If Claude Code's Bash tool presents a TTY, S3 degrades to the `--yes` refusal plus sandbox `denyWrite ~/.claude`. That sandbox setting is manual hardening, and a host without it has no barrier.
- **035's regex has not landed.** Until install.sh is in `live-verify-gate.sh`'s enforcement regex, an agent edit to install.sh's host code is not loud. Commits in steps 2–4 should still carry a `Live-verified:` trailer, following the 035 decision (`Live-verified: no — host-target code; verified by step 7 host run` is acceptable).
- **Q-049 unresolved.** The copied hooks may be wired to deny rules that match nothing. That is unchanged by this plan, which deliberately doesn't automate the merge.
- **Foreign content in owned dirs** is moved to a backup, not preserved in place. A user with private skills in a real `~/.claude/skills` would need to re-add them (open question).
- **Windows Antigravity via `/mnt/c`** is unverified.
- **install.sh grows to ~350 lines**: within the 500 guideline.
- Deferred coverage: a SessionStart staleness warning (DD [9]) and an automated settings merge are follow-ups, not in this plan.

## Rollback

1. Code: `git revert <step-6..step-2 commit range>` on main, in reverse order. The devcontainer path is pinned unchanged by T8, so the revert is not a devcontainer-affecting change. No `install.sh` re-run or re-bless is needed for the devcontainer, because the installed `~/.config/claude-devcontainer` payload never depended on the host-target code.
2. Host `~/.claude`, if a `--claude-home` install went wrong: the previous entries sit in `~/.claude/.claude-workflows-backup/<stamp>/`. From a plain shell, outside Claude Code (the guard and sandbox will rightly block it inside), for each of `skills workflows guides patterns hooks scripts CLAUDE.md`:
   - `rm -rf ~/.claude/<name>` (**no trailing slash**)
   - `mv ~/.claude/.claude-workflows-backup/<stamp>/<name> ~/.claude/<name>`

   The backup holds the original symlinks as symlinks, so this restores the symlink install exactly.
3. Host `~/.gemini`: the same, from `~/.gemini/.claude-workflows-backup/<stamp>/`.
4. `settings.json` is never written by this change, so there is nothing to restore there.
5. Docs: the README revert restores the `ln -s` recipe.

Irreversible component: none. The only destructive operation, replacing entries, is a move into the backup, which the user deletes by hand when satisfied.
