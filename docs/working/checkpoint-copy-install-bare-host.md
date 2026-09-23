# Checkpoint: copy-install-bare-host
Date: 2026-09-23
Branch: ans/copy-install (based on 712c626 + the cherry-picked plan commit)
Research: docs/working/research-copy-install-bare-host.md
Plan: docs/working/plan-copy-install-bare-host.md
Decision: docs/decisions/037-bare-host-copy-install.md

## Project state
- **Branch purpose**: implement the Q-050 answer. The bare-host `~/.claude` install moves from symlinks into the checkout to copies that `install.sh` makes after a shown review and a human y.
- **Position in larger initiative**: follows the 2026-09-21 answers branch. That branch's guard redesign (R6/N12) is independent, and this change makes it moot on a bare host.
- **Blocked on**: nothing. The plan was approved via Q-054 with shape D. Q-055 dropped Gemini; Q-056 settled `--yes` and the TTY; Q-057 settled foreign files.

## Key findings
- The README (`:9-38`) symlinks `CLAUDE.md` and five dirs into `~/.claude`, per-file-symlinks five hooks and copies four security hooks. Wiring is a manual merge (guide §2). [observed]
- `install.sh` already has the whole mechanism for the devcontainer: assemble the seven `CLAUDE_HOME_SRC` entries (missing = fatal, plus `.manifest`), a `diff -ruN` review that aborts on diff trouble, an EOF-safe `[y/N]`, then `rm -rf` + `cp -r`, the bin link and `--bless`. Only `$1` is parsed. [observed]
- **Three hazards, verified in scratch**: `diff -ruN` through a symlinked dest shows nothing; `cp -r stage/x dest/x` onto a dir link writes into the checkout; `rm -rf dest/x/` with a trailing slash empties the checkout. [observed]
- The log-usage hooks source `lib/` and `../scripts/lib` via `readlink -f`, so `hooks/` and `scripts/` must be copied whole. [observed]
- **TTY finding (2026-09-23)**: the Bash tool has no TTY (fd 0 = `/dev/null`, `tty` prints "not a tty"). But `script` (util-linux 2.38.1) is present and gives a pty, so the TTY rule stops accidents, not intent. [observed]
- Existing `cc-isolated-functions.bats` install tests run `</dev/null` **without pinning HOME**. Under D the host target must skip before reading or staging anything, or those tests would touch the real `~/.claude`. [observed]
- Decision 035's regex has not landed. install.sh commits still carry `Live-verified:` trailers. [observed]

## Plan (shape D)
1. docs: revise the plan, this checkpoint and decision 037.
2. docs: `/pre-mortem` and `/architecture-review` → `docs/reviews/*-copy-install.md`; fold the findings in.
3. test: `test/install-host.bats` T1–T19; pty via `script -qec … /dev/null` fed `n\ny\n`; everything pinned to scratch; confirm it fails on the old install.sh.
4. refactor: an arg loop (`--yes`, `-h`; anything else → usage, exit 2), and extract `assemble` and `review_diff`. The existing suite passes unmodified.
5. feat: host target in the default run:
   - a devcontainer decline continues to the host target (exit 1 at the end);
   - skip on `--yes` or no TTY, before any read;
   - refuse a dest inside the checkout;
   - a mktemp stage with a trap;
   - a symlink-aware review (`REPLACE symlink`, `MOVE to backup`, diff);
   - a prompt;
   - install via `.cw-new.*` → backup → swap;
   - the manifest (`rm -f` first) and the wiring reminder;
   - a new header.
6. docs: the README (install flow and migration paragraph; Gemini blocks removed; table; line 193), the bare-host guide (Scope, §1, §2) and guides/README.
7. docs: a 035 Consequences note.
8. verify: the suites; fill in Actual context cost.
9. you: terminal: the host run, then the skill-load and usage-log checks.

Order: `1 → 2 → 3 → 4 → 5 → [6, 7] → 8 → 9`.

## Invariants
- The devcontainer target behaves as today for every non-interactive run (closed stdin, piped input, `--yes`): same PAYLOAD, diff, prompt, `--bless` and bin link. `link-claude-home.sh` is untouched.
- Nothing is installed without a shown review and a y. Diff trouble aborts before the prompt. EOF means no.
- One payload definition: the same seven `CLAUDE_HOME_SRC` entries and `.manifest` format.
- The installed `hooks/` keeps `lib/` and `../scripts/` reachable.
- Only the seven entries (plus the manifest and backup dir) are touched in `~/.claude`.
- Tests never touch the real HOME. Every destination is env-overridable and pinned.
- Never `rm -rf` with a trailing slash. Never `cp` onto an existing destination.

## File map
- `test/install-host.bats`: new hermetic suite (step 3)
- `test/cc-isolated-functions.bats`: read only; must pass unmodified
- `devcontainer-config/install.sh`: steps 4–5
- `README.md`: step 6
- `guides/bare-host-hook-wiring.md`, `guides/README.md`: step 6
- `docs/decisions/037-bare-host-copy-install.md`: new (step 1)
- `docs/decisions/035-install-sh-gating.md`: Consequences note (step 7)
- `docs/reviews/pre-mortem-copy-install.md`, `docs/reviews/architecture-review-copy-install.md`: step 2

## Open questions
- settings.json merge automation: follow-up after Q-049.
- macOS behavior of the host target is untested.
