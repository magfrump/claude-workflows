# Checkpoint: copy-install-bare-host
Date: 2026-09-23
Branch: ans/copy-install-plan (based on 970e525)
Research: docs/working/research-copy-install-bare-host.md
Plan: docs/working/plan-copy-install-bare-host.md

## Project state
- **Branch purpose**: research and plan (docs only) for the Q-050 answer. The bare-host `~/.claude` (and `~/.gemini`) install moves from symlinks into the checkout to copies that `install.sh` makes after a shown diff and a human y.
- **Position in larger initiative**: follows the 2026-09-21 answers branch. Its guard-hook redesign (R6/N12, "hook denies HARD itself") is paused and independent. This change makes R6 and N12 moot on a bare host.
- **Blocked on**: plan approval. The DD pick is tentative (Path C). Open questions: Gemini in scope, `--yes`/TTY policy, and foreign content in owned dirs.

## Key findings
- The README (`:9-38`) symlinks `CLAUDE.md` and five dirs into `~/.claude`, per-file-symlinks five hooks, and copies four security hooks. Wiring is a manual merge (guide §2). [observed]
- `install.sh` already has the whole mechanism for the devcontainer:
  - `CLAUDE_HOME_SRC` (7 entries) assembled into a stage, with missing sources fatal and a `.manifest`;
  - `diff -ruN` review that aborts on diff trouble;
  - an EOF-safe `[y/N]`;
  - `rm -rf` + `cp -r`, then `cc-isolated --bless`.

  Only `$1` is parsed. [observed]
- **Three hazards, verified experimentally in scratch** [observed]:
  - `diff -ruN` through a symlinked dest shows nothing (rc 0), so the migration is invisible.
  - `cp -r stage/x dest/x` where `dest/x` is a link to a dir writes *into the checkout*.
  - `rm -rf dest/x/` with a trailing slash empties the checkout.
- `log-usage.sh`/`log-usage-post.sh` source `lib/usage-common.sh` and `../scripts/lib/skill-paths.sh` via `readlink -f`. `claude-config-audit.sh` finds `../scripts/claude_config_audit.py` the same way. Per-file hook copies would break these; whole `hooks/` and `scripts/` copies keep them working. [observed]
- Bless on a bare host = a human at a TTY who read the diff and typed y. No hash receipt is checked, because Claude Code reads `~/.claude` directly. The provenance stamp is `.claude-workflows-manifest`. The agent can run the installer on a bare host, so host targets refuse `--yes` and require a TTY. [assumed: the Bash tool has no TTY]
- `settings.json` merge: **out of scope**. It holds host-private hardening, Q-049 is unresolved, and the only correct merger is link-claude-home's provenance jq (FP-161). The installer prints a reminder when `wiring.json` changed.
- Decision 035's regex addition for install.sh has not landed (`live-verify-gate.sh:57`). Still put a `Live-verified:` trailer on install.sh commits. [observed]
- Failure-pattern priors: FP-146 (a symlink hides content from the review), FP-066 (a subset install silently disables process), FP-073 (copied is not wired), FP-161, FP-061, FP-167.

## Plan
DD pick [2] A: `install.sh --claude-home` / `--gemini`, one target per run; the default is unchanged. Runner-up D (offer both by default), axis = one run covering every target vs one boundary per bless. Confidence 70%.
1. **test**: new `test/install-host.bats`, T1–T17. `setup()` pins `HOME`, `CLAUDE_HOME_DIR`, `GEMINI_HOME_DIR`, `CLAUDE_DEVC_CONFIG_DIR`, `CLAUDE_DEVC_BIN_DIR` and `TMPDIR` into scratch. The y path is driven via `script -qec` (pty).
2. **refactor**: arg loop (`--yes`, `--devcontainer`, `--claude-home`, `--gemini`, else usage exit 2). Extract `assemble` and `review_diff`. The existing suite must pass unmodified.
3. **feat `--claude-home`**:
   - stage in `mktemp -d` (not `$SRC/claude-home`);
   - symlink-aware review with a `REPLACE symlink … with a copy` line counted as a change, and foreign files as deletions plus a warning;
   - refuse `--yes` and non-TTY;
   - copy all entries to `.cw-new.<name>`, then move the old entries to `.claude-workflows-backup/<stamp>/` (no trailing slash), then `mv` the new ones in;
   - write the manifest and the wiring reminder;
   - no `--bless`, no devcontainer dir, no bin link;
   - fix the header comment.
4. **feat `--gemini`**: `GEMINI.md workflows skills patterns guides global-instructions` into `${GEMINI_HOME_DIR:-$HOME/.gemini}`. Droppable.
5. **docs**:
   - README Claude, Gemini and Antigravity blocks, including a migration paragraph and `/mnt/c` for Windows (unverified);
   - the outside-repo table, and line 193;
   - `guides/bare-host-hook-wiring.md` §1, Scope and §2;
   - `guides/README.md:47`.
6. **docs**: new decision record, plus a Consequences note in 035.
7. **you: terminal**: host migration, skill-load and usage-log check, guide §4, confirm the checkout CLAUDE.md is Edit-able.

Order: `1 → 2 → 3 → 4 → [5, 6] → 7`.

## Invariants
- The devcontainer path is byte-for-byte unchanged in behavior: `PAYLOAD`, diff, prompt, `--bless`, bin link. `link-claude-home.sh` is untouched.
- Nothing is installed without a shown diff and a y. Diff trouble aborts before the prompt. EOF means no.
- One payload definition: the same seven `CLAUDE_HOME_SRC` entries and `.manifest` format as the image.
- Installed `hooks/` keeps `lib/` and `../scripts/` reachable.
- Only the named entries are ever touched. `settings*.json`, `projects/`, memory, `logs/`, `plugins/` and credentials are untouched.
- Tests never touch the real HOME. Every destination is env-overridable and pinned.
- Never `rm -rf` with a trailing slash. Never `cp` onto an existing destination.

## File map
- `test/install-host.bats`: new hermetic suite (step 1)
- `test/cc-isolated-functions.bats`: read only; `fake_install_repo` pattern at `:586-602`; must pass unmodified (steps 1–2)
- `devcontainer-config/install.sh`: arg parsing, `assemble`/`review_diff` extraction, host targets, header (steps 2–4)
- `devcontainer-config/link-claude-home.sh`: read only; ENTRIES and manifest reference
- `hooks/log-usage.sh`, `hooks/log-usage-post.sh`, `hooks/claude-config-audit.sh`: read only; sibling resolution (T9)
- `README.md`: setup blocks, outside-repo table, line 193 (step 5)
- `guides/bare-host-hook-wiring.md`: Scope, §1, §2 (step 5)
- `guides/README.md`: line 47 (step 5)
- `docs/decisions/0NN-bare-host-install-by-blessed-copy.md`: new (step 6)
- `docs/decisions/035-install-sh-gating.md`: Consequences note (step 6)

## Open questions
- **Gemini**: still in use (CLI or Antigravity)? If not, drop step 4 and mark the Gemini README block deprecated. Interim: planned, droppable.
- **Self-bless policy**: should host targets refuse `--yes` and require a TTY (planned), or allow `--yes` for parity? The TTY barrier's effectiveness is [assumed].
- **Foreign content** in owned dirs: move to backup (planned) or preserve in place?
- **DD axis**: A (explicit target flag) vs D (default run offers both). A was chosen on least surprise.
- **settings.json merge automation**: a follow-up after Q-049 is answered?
- `/pre-mortem` and `/architecture-review` both triggered and not yet run. Run them before approval.
- Q-050 itself should be archived with the user's answer, and R6/N12 noted as moot for bare hosts after migration. The orchestrator does this, not this branch.
