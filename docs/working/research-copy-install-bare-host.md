# Research: bare-host install by blessed copy, not symlink

- **Goal**: Replace the README's bare-host symlink install of the global files into `~/.claude` (and decide whether `~/.gemini` follows) with a copy that `devcontainer-config/install.sh` makes only after a human has read the diff and answered y.
- **Problem framing**: The problem is that on a bare host the *live* global instructions, skills and hooks are the checkout itself, so any edit to the repo (by an agent or anyone) is live immediately with no review. Considered and discarded: "the guard hook denies or ignores the wrong paths on a bare host" (Q-050's R6/N12 framing). The user's Q-050 answer moots that framing: once the installed files are copies, the checkout is inert and there is nothing for the guard to protect at the checkout path.
- **Project state**: docs-only research and plan for the Q-050 answer (2026-09-23) · follows the 2026-09-21 answers branch, whose guard redesign is paused at its review cap · not blocked (cite: 970e525)
- **Task status**: complete (research done; plan drafted in `plan-copy-install-bare-host.md`, awaiting approval)

## Original request

> "This repo's copy is the only global instruction file that should be editable, and the symlink connection should be deprecated in favor of edits getting checked in and propagated by copying after a human bless via install.sh." (Q-050 answer, 2026-09-23)

## What exists

**Bare-host install today: README Linux/macOS block** (`README.md:9-38`) [observed]
- It symlinks `~/.claude/CLAUDE.md` to `global-instructions/CLAUDE.md`, and symlinks `workflows`, `skills`, `patterns`, `guides` and `scripts` as whole directories.
- It makes a real `~/.claude/hooks/` and symlinks five non-blocking hooks into it one file at a time: `log-usage.sh`, `log-usage-post.sh`, `dd-routing-reminder.sh`, `batch-feedback-routing-reminder.sh`, `claude-config-audit.sh`.
- It **copies** four permission-path hooks: `guard-trusted-writes.py`, `web-taint-mark.py`, `auto-approve-allowed-commands.sh`, `live-verify-gate.sh`.
- Wiring into `~/.claude/settings.json` is a manual merge of `hooks/wiring.json`, done by following `guides/bare-host-hook-wiring.md` §2.
- The guide's §1 explains the two conventions and names the symlinked `claude-config-audit.sh` as "an open follow-up" (`guides/bare-host-hook-wiring.md:16-27`).

**Gemini / Antigravity** (`README.md:48-86`) [observed]
- `~/.gemini/` gets six symlinks: `GEMINI.md`, `workflows`, `skills`, `patterns`, `guides`, `global-instructions`. `global-instructions` is there because `GEMINI.md:17` points into `global-instructions/CLAUDE.md`.
- Windows Antigravity uses elevated-PowerShell symlinks to `\\wsl.localhost\...` UNC targets.
- No guard hook or deny rule covers `~/.gemini` [inferred: grep of `hooks/` finds no `gemini`].

**Per-project AGENTS.md symlinks** (`README.md:88-122`) [observed]
- These are project-level wiring for Cursor, Copilot and similar tools, not global files. Out of scope (see Coverage check).

**`devcontainer-config/install.sh`** (158 lines) [observed]
- `SRC` is the script dir. `DEST="${CLAUDE_DEVC_CONFIG_DIR:-$HOME/.config/claude-devcontainer}"` and `BIN_DIR="${CLAUDE_DEVC_BIN_DIR:-$HOME/.local/bin}"`. `ASSUME_YES="${1:-}"`: only `$1` is read, and only `--yes` means anything.
- **Assembly (`:49-79`)**:
  - Copies `CLAUDE_HOME_SRC=(global-instructions/CLAUDE.md skills workflows guides patterns hooks scripts)` fresh into `$SRC/claude-home`, one entry per basename. That staging dir is gitignored (`.gitignore:41`).
  - Missing sources are fatal, and every miss is reported, not just the first.
  - Writes a `.manifest` with `commit=`, `dirty=` and `assembled_from=`.
- **Review diff (`:85-114`)**:
  - Runs `diff -ruN "$DEST/$item" "$SRC/$item"` per `PAYLOAD` item. Exit 1 counts as a change; exit >1 aborts before the prompt.
  - `-N` makes new content visible. This was the D1 regression; tests at `test/cc-isolated-functions.bats:663-700`.
- **Prompt (`:116-126`)**: `[y/N]`. EOF on stdin reads as "no" (`read -r reply || reply=""`).
- **Install (`:128-145`)**:
  - For each item, `rm -rf "${DEST:?}/$item"; cp -r "$SRC/$item" "$DEST/$item"`, then chmods.
  - Links `$BIN_DIR/cc-isolated`.
  - Runs `cc-isolated.sh --bless`, which records the config hash. The launcher checks that hash at every start.
- Its header (`:7-14`) is the rationale the user's answer generalizes: *"Symlinking would hand the agent the boundary. So: read the diff. It is the rebuild gate."*

**`devcontainer-config/link-claude-home.sh`** [observed]
- Inside the container it symlinks `ENTRIES=(skills workflows guides patterns hooks scripts CLAUDE.md)` from the root-owned `0555` `/opt/claude-workflows` into the per-project volume.
- It copies `.manifest` to `~/.claude/.claude-workflows-manifest`.
- It merges `hooks/wiring.json` into `settings.json` using provenance subtraction (FP-161).
- Its symlinks point at a read-only, human-blessed payload, not at a writable checkout, so the user's answer does not reach it. **It needs no change.** Its seven entries are the same set the bare host should copy, which gives a single payload definition.

**Hooks that locate siblings by their own real path** [observed]
- `hooks/log-usage.sh:11,14` and `log-usage-post.sh:20` source `$(dirname "$(readlink -f "$0")")/lib/usage-common.sh` and `../scripts/lib/skill-paths.sh`.
- `hooks/claude-config-audit.sh:47-49` resolves `<hook dir>/../scripts/claude_config_audit.py`, with `~/private_reviews/` as a fallback.
- Per-file symlinks work today only because `readlink -f` lands in the checkout. **Per-file copies would break log-usage.** The README never installs `hooks/lib/`, so a copied `log-usage.sh` in `~/.claude/hooks/` would fail to source `lib/usage-common.sh`. Copying the whole `hooks/` and `scripts/` directories keeps every relative lookup working. `hooks/` then resolves to `~/.claude/hooks/`, and `../scripts` to `~/.claude/scripts/`.

**`hooks/guard-trusted-writes.py`** [observed]
- `_HARD_FILE_TARGETS` (`:95`) and `_HARD_DIR_TARGETS` (`:102`) are resolved from `~/.claude/CLAUDE.md` and `~/.claude/hooks`. The "hard-resolved" tier (`:151-155`) denies a file-tool edit that is HARD only after `resolve()`.
- With the README symlinks, `resolve(~/.claude/CLAUDE.md)` is the checkout's `global-instructions/CLAUDE.md`. That is why a577546 made the repo's own source file uneditable (R6). The per-file hook links resolve to checkout paths that are covered by nothing (N12).
- **Once `~/.claude/CLAUDE.md` and `~/.claude/hooks` are real copies, both target sets resolve to themselves.** The checkout file classifies as `none`, so it is editable, which is what the user wants. The resolved tier is then moot on a bare host. It still matters in the devcontainer, where `~/.claude/hooks` and `CLAUDE.md` link into `/opt`.
- Not planned here, but relevant: the pending redesign in `docs/reviews/code-review-rubric-2026-09-21-answers-2026-09-20-iter3.md:175`. Under it, "the hook returns `deny` itself for HARD paths instead of deferring". It is independent of this change, and this change removes the bare-host motivation for R6 and N12.

**Test harness for install.sh** (`test/cc-isolated-functions.bats`, 1084 lines) [observed]
- `setup()` pins `CLAUDE_DEVC_CONFIG_DIR` and `CLAUDE_DEVC_BIN_DIR` into `mktemp -d` (`:21-29`). The comment there records the memory-note incident: pre-fix code relinked the real `~/.local/bin/cc-isolated`.
- `fake_install_repo` (`:586-602`) builds a throwaway repo holding a copy of `install.sh` plus stub payload sources.
- `fake_payload_and_dest` (`:640-661`) mirrors an installed dir.
- All tests run with `</dev/null`, so they reach the prompt and decline. No test drives the y path.

**Gates on install.sh itself** [observed]
- Decision 035 chose to add `install\.sh` to `hooks/live-verify-gate.sh`'s enforcement regex. It is not implemented at 970e525: the regex at `live-verify-gate.sh:57` still lists only the six siblings. The decision is still `in-progress` and sequenced behind A7.

## What "bless" means: devcontainer vs bare host

| | Devcontainer (today) | Bare host (proposed) |
|---|---|---|
| Who can run the installer | Only the host human. The agent is inside a container that cannot reach the host shell. | **The agent can too.** It runs on the same host, as the same user. |
| What the human approves | The `diff -ruN` of `PAYLOAD` against `~/.config/claude-devcontainer`, then `[y/N]`. | The same diff over the seven `claude-home` entries against `~/.claude`, then `[y/N]`. |
| Receipt | `cc-isolated --bless` records the config hash. The launcher refuses an unblessed config at every start, and `--probe-only` records a verified-live pass. | **None is checked.** Claude Code reads `~/.claude` directly, so there is no launcher to check a hash. The receipt is provenance only: `~/.claude/.claude-workflows-manifest`, the same format link-claude-home writes, which names the installed commit. |
| What protects the installed copy afterward | The root-owned `0555` `/opt` payload, plus the container boundary. | Sandbox `denyWrite ~/.claude` for Bash (manual hardening, guide §3). `permissions.deny` plus the guard for `hooks/**`, `settings*.json` and `CLAUDE.md` (subject to Q-049). The `skills`, `workflows`, `guides`, `patterns` and `scripts` copies are SOFT: ask only when tainted. |

So "bless" on a bare host means **a human at an interactive terminal who read the diff and typed y**. It is weaker than the devcontainer bless in one specific way: the agent can invoke the installer itself. Two mitigations follow, and both are in the plan:
- Host targets refuse `--yes`.
- Host targets require stdin to be a TTY, so an agent's Bash tool, which has no TTY [assumed; unverified], cannot answer the prompt by piping `y`.

Either way the installed copy sits under `~/.claude`, which is sandbox-`denyWrite` for Bash. The copy is therefore better protected than today's checkout, which has no such protection.

## Invariants

1. **Devcontainer path unchanged.** `install.sh` with no target flag must behave exactly as it does now: the same `PAYLOAD`, diff, prompt, `cp`, `cc-isolated --bless` and bin link. `link-claude-home.sh`, `enforcement_files()` and the payload hash are untouched. [observed: `test/cc-isolated-functions.bats:574-700,770+` pin the current behavior]
2. **Nothing is installed without a shown diff and a y.** A diff that fails to run aborts before the prompt. EOF on stdin means no. [observed: `install.sh:96-104,121-125`]
3. **One payload definition.** The seven `CLAUDE_HOME_SRC` entries, their basenames and the `.manifest` format are shared by the image and link-claude-home. A bare host installs the same set, not a hand-picked subset. [observed: `install.sh:49`, `link-claude-home.sh:50,70-72`]
4. **Hooks find their siblings by real path.** `hooks/lib/`, `../scripts/lib/skill-paths.sh` and `../scripts/claude_config_audit.py` must exist relative to the installed `hooks/` dir. [observed: `log-usage.sh:11,14`, `claude-config-audit.sh:47-49`]
5. **User-owned state in `~/.claude` is never touched.** That covers `settings*.json`, `projects/`, memory, `logs/`, `plugins/`, `.credentials.json` and anything not among the seven entries. [inferred from `install.sh:130-132`'s `projects/` carve-out and 023's merge-not-link rationale]
6. **Tests are hermetic.** Every destination the installer writes is env-overridable, and every test points all of them, plus `HOME`, into scratch. [observed: `cc-isolated-functions.bats:26-29`; memory note "prove old-code failures hermetically"]
7. **Commits to install.sh answer the Live-verified question**, as decision 035 directs, even before its regex lands. [observed: 035 decision text; regex not yet extended]

## Prior art

- **install.sh itself** already has the copy-after-diff-and-y pattern, the `-N` diff, fatal missing sources and the manifest. A host target should reuse all of it rather than add a second mechanism. This is 016's "two code paths, two trust regimes" objection, carried by 035 as S2.
- **link-claude-home.sh** already has an idempotent install that refuses to clobber, and the `.claude-workflows-manifest` stamp.
- **cc-isolated-functions.bats** already has the fake-repo and fake-dest helpers, and the hermetic-destination pattern.
- **The README's "copies for security hooks" convention** is this idea applied to four files by hand. The plan generalizes it to all seven entries, and to the installer instead of by hand.

## Gotchas

- **[observed, scratch experiment] `diff -ruN` follows a symlinked destination.** With `~/.claude/skills -> checkout/skills` and a stage that equals the checkout, the diff prints nothing and exits 0. The migration from symlink to copy would be **invisible in the review diff**, and the loop would report "(none — already matches)". The host diff must detect `-L` destinations and print an explicit "will replace symlink → target with a copy" line, counted as a change.
- **[observed] `cp -r stage/skills ~/.claude/skills` when the destination is a symlink to a directory writes into the checkout.** It creates `checkout/skills/skills`. The link must be removed first.
- **[observed] `rm -rf ~/.claude/skills/` with a trailing slash, on a symlink, deletes the checkout's contents** and leaves the link in place. `rm -rf ~/.claude/skills` without the slash removes only the link. `install.sh:135` has no slash today. A host target must keep it that way, and a test must prove the checkout survives.
- **[observed] `rsync` is not installed here**, so the plan uses `cp`/`mv`.
- **[observed] `ASSUME_YES="${1:-}"` reads only `$1`.** Adding target flags needs real argument parsing, and `--yes` must keep working in any position for the devcontainer path.
- **[observed] The per-file hook links hide `hooks/lib/`.** Per-file copies would break `log-usage.sh`. Copy the directories whole.
- **[observed] The installer ends with `cc-isolated.sh --bless`.** A host target must not run it (no devcontainer config may exist), and must not create `~/.config/claude-devcontainer` or `~/.local/bin/cc-isolated`.
- **[inferred] Foreign content inside an owned entry disappears on a whole-directory replace.** A user's own skill in `~/.claude/skills/` is one example. Today `skills` is a symlink into the checkout, so user skills would live in the repo anyway. A foreign file in the real `~/.claude/hooks/` directory would show in the diff as a deletion. The plan backs up rather than deletes.
- **[inferred] `settings.json` wiring is not solved by copying.** A copy that changes `hooks/wiring.json` still needs the guide §2 hand-merge. The installer can detect the change and say so, but should not merge (see the scope decision below).
- **[assumed] Windows Antigravity can read copies written from WSL to `/mnt/c/Users/<you>/.gemini`.** That would remove the Developer Mode or elevation requirement symlinks have. Unverified: the sandbox has no Windows side.
- **[assumed] Claude Code's Bash tool gives commands a non-TTY stdin.** The TTY requirement's value as a self-bless barrier rests on this.

Failure-pattern grep: FP-061, FP-066, FP-073, FP-146, FP-161, FP-167 (see Prior failures section)

## Prior failures

Grep: `grep -inE 'symlink|install|copy|bless|stale|drift|hermetic|home|gemini' docs/thoughts/failure-patterns.md`

- **FP-146** `symlink-hashed-by-target-only-rewritten-content-invisible`: the same class as the diff-follows-symlink gotcha. A symlink hid a content change from the review artifact. The migration notice exists for this reason.
- **FP-167** `tracked-symlink-to-absolute-host-path-is-dangling`: symlinks into host paths go dangling. Copies don't.
- **FP-066** `repo-skills-never-registered-in-any-container-session`: installing a subset silently disables process. This is why invariant 3 (one payload definition) holds.
- **FP-073** `guard-defers-to-deny-rules-that-were-never-wired`: copying the hooks is not wiring them. The installer must say when `wiring.json` changed.
- **FP-161** `wiring-merge-by-deep-equality-leaves-stale-group-beside-new`: the reason not to hand-roll a second settings merger on the host (scope decision below).
- **FP-061** `hardcoded-home-paths-break-after-sandbox-move`: every destination must come from an env override, never a literal `$HOME/...`.

## Scope decisions

- **`~/.claude/settings.json` wiring merge: out of scope.**
  - (a) `settings.json` holds host-private hardening that `wiring.json` does not carry (the allow-list trims, the sandbox block; guide §3). It is written by Claude Code at runtime, so the installer should not own it.
  - (b) Q-049 is still open. The deny-rule path form (`/` vs `//`) may make the emitted rules match nothing, and automating the merge now would bake that bug into every host.
  - (c) The only correct merger is link-claude-home's provenance-subtraction jq (FP-161). Reusing it on the host means either sourcing a devcontainer enforcement file from the host installer, a coupling 035 would flag, or copying it (a second copy to drift).
  - What the plan does instead: print a loud reminder when the installed `hooks/wiring.json` differs from the new one. Filed as an open question for a follow-up.
- **`link-claude-home.sh`: unchanged.** Its symlinks target a read-only blessed payload.
- **Guard hook: unchanged.** R6 and N12 become moot on a bare host once the copies are installed; the pending "hook denies HARD itself" redesign is independent.
- **Per-project AGENTS.md symlinks: out of scope.** They are project wiring for other tools, not global instruction files. A README note says so.

## Divergent design (inline, Path C)

Prior pruning grep: 035's Pruned candidates matched `install|bless|symlink`. Carried: **[carried from 016 [4]: two code paths, two trust regimes]** becomes soft S2. **[carried from 035 [7] move installer off repo: declined on unverifiability]**: not re-proposed.

**Candidates (step 1).**
0. Status quo: symlinks.
1. Docs-only: the README says `cp -r` by hand.
2. **A: `install.sh --claude-home` / `--gemini` target flags.** One target per run; the default is unchanged.
3. **B: a separate `devcontainer-config/install-host.sh`** sharing a sourced lib with install.sh.
4. C: install.sh always installs the devcontainer config and `~/.claude` together, with one diff and one y.
5. **D: install.sh offers both by default,** in sequence, with a separate diff and y per target, plus `--only-*` flags.
6. E: keep the symlinks and `chmod -R a-w` the checkout's global files.
7. F: `~/.claude` entries symlink into the *installed* devcontainer payload `~/.config/claude-devcontainer/claude-home`, which is already blessed.
8. G: `~/.claude` is a `git worktree` pinned at a blessed commit, and "bless" means `git checkout <commit>` there.
9. H: A plus a SessionStart hook that warns when `.claude-workflows-manifest` commit ≠ repo HEAD (ideal-if-free).
10. I: a make target (`make install-host`) wrapping cp + diff.
11. J: Claude Code plugin packaging: install the repo as a local plugin (unconventional).

Health check: the candidates cluster on "where the installer lives" (2, 3, 4, 5, 10). 7, 8 and 11 were added to move on a different dimension: *what the live file points at*.

**Constraints (step 2).**
- **H1** (hard): the installed copy changes only after a shown diff and a y. success: a bats test with closed stdin leaves the destination byte-identical, and the y path makes it equal the stage.
- **H2** (hard): the symlink-to-copy migration is visible in the diff and gated. success: a bats test shows the "replace symlink" line in output before the prompt.
- **H3** (hard): the checkout is never modified by an install. success: a bats test checksums the fake repo before and after a migrating install.
- **H4** (hard): the devcontainer path is unchanged. success: the existing `test/cc-isolated-functions.bats` passes unmodified.
- **H5** (hard): hermetic tests. success: every writing test sets `HOME` and every `*_DIR` into `BATS_TEST_TMPDIR`, and a test asserts no dest outside it was created.
- **H6** (hard): copied hooks still find `lib/` and `../scripts`. success: a bats smoke test runs the installed `log-usage.sh` with scratch `HOME` and it exits 0.
- **S1** (soft): one command a human already knows.
- **S2** (soft): one diff and bless code path.
- **S3** (soft): the agent cannot trivially self-bless.
- **S4** (soft): Gemini is handled by the same mechanism.

**Match (step 3).**

| # | H1 | H2 | H3 | H4 | H5 | H6 | S1 | S2 | S3 |
|---|---|---|---|---|---|---|---|---|---|
| 0 | ✗ | ✗ | ✗ | ✓ | – | ✓ | ✓ | – | ✗ |
| 1 | ✗ | ✗ | ~ | ✓ | – | ~ | ~ | ✗ | ✗ |
| 2 A | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ~ |
| 3 B | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ~ | ~ | ~ |
| 4 C | ✓ | ✓ | ✓ | ⚠ | ✓ | ✓ | ✓ | ✓ | ~ |
| 5 D | ✓ | ✓ | ✓ | ~ | ✓ | ✓ | ✓ | ✓ | ~ |
| 6 E | ✗ | ✗ | ✓ | ✓ | – | ✓ | ~ | ✗ | ~ |
| 7 F | ~ | ✗ | ✓ | ~ | ✓ | ✓ | ✓ | ✓ | ✗ |
| 8 G | ✗ | ~ | ✓ | ✓ | ~ | ✓ | ✗ | ✗ | ✗ |
| 9 H | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ~ |
| 10 I | ✓ | ~ | ✓ | ✓ | ✓ | ✓ | ~ | ✗ | ~ |
| 11 J | ~ | ✗ | ✓ | ✓ | ~ | ✗ | ✗ | ✗ | ~ |

Survivors: **[2] A, [5] D, [3] B**. [9] H is A plus an add-on, deferred as a follow-up: nothing on the host needs it to meet the answer.

**Tradeoff (step 4).**

| # | Effort | Risk | Coverage | Key downside | Hypothesis |
|---|---|---|---|---|---|
| ★ 2 A | ~1 day (~250 LOC + ~300 LOC tests) | low | 6/6 hard | install.sh's host blast radius widens: it now writes `~/.claude` (mitig.: TTY + no `--yes` for host targets) | If chosen, the first host migration shows every symlink in the diff and leaves the checkout unchanged, within the first install; counter-evidence = any user report of an empty checkout dir or a "(none)" diff on a symlinked host. |
| 5 D | ~1.2 days | med | 6/6 hard (H4 ~) | Changes what `install.sh` with no args does for existing users, and two prompts per run invite reflex-y | If chosen, a default run asks twice and users bless both; counter-evidence = a user declining the host prompt they didn't expect. |
| 3 B | ~1.3 days | med | 6/6 hard | A second host-executed script outside 035's gate, and a shared lib is a new coupling | If chosen, the two scripts stay in step for 3 months; counter-evidence = a diff/prompt fix landing in one and not the other. |

Stress tests:
- *Boring alternative*: [1] docs-only cp fails H2. The invisible-migration gotcha is exactly the failure a hand `cp` has.
- *Invert the thesis*: for D, "one command and nothing forgotten" is real. The counter is that the host prompt gains a new consequence for existing muscle memory. That keeps A in front.
- *Failure-driven*: an agent running `install.sh --claude-home --yes` in Bash is the new failure category. It is mitigated in A (TTY required, `--yes` refused) and applies equally to B and D.
- *Organizational survival*: A keeps one file that 035 already gates by decision. B needs a 035 amendment.

```
▶ recommend [2] A (install.sh --claude-home / --gemini, one target per run) · confidence 70% · runner-up [5] D, axis = convenience of one run covering every install target vs. one boundary per bless
```

**Path C resolution.** This subagent is non-interactive, so no prompt was issued. The tentative pick is **A**. Stated preference on the axis: 035 and decision log 45 prefer a single mechanism that makes each boundary change loud. Tiebreaker where that doesn't decide: *do not change what an existing command does* (least surprise). The `questions.md` entry is left to the orchestrator, to avoid a merge conflict with parallel worktrees on the same file.

Pruned: `[0]: contradicts the answer; H1/H2 ✗.` `[1]: ✗ H1/H2 — a hand cp shows no diff and hides the migration.` `[4 C]: ⚠ H4 — forces the devcontainer bless on hosts that only want ~/.claude, and one y spans two boundaries.` `[6 E]: ✗ H1 — no diff, and chmod on a git checkout breaks checkout and stash [carried from 035 [10]].` `[7 F]: ✗ H2, ✗ S3 — symlinks into an agent-writable ~/.config, so the devcontainer bless silently changes the host.` `[8 G]: ✗ H1 — the agent can move the worktree HEAD.` `[9 H]: deferred add-on, not a rival.` `[10 I]: ✗ S2 — a second mechanism.` `[11 J]: ✗ H6 — plugin layout doesn't carry CLAUDE.md or hooks wiring; unverifiable here.`

## Coverage check

| Element of the brief | Where addressed |
|---|---|
| Deprecate the bare-host symlinks into `~/.claude` | Plan steps 3 and 5 |
| Copies only after a human bless via install.sh | DD pick A; plan step 3; "What bless means" above |
| Whether `~/.gemini` follows | Plan step 4, `--gemini`. Open question: is Gemini still used? Windows side [assumed] |
| Migrating an existing symlinked install (replace shown in diff, gated) | Gotchas (diff follows the link, cp into the link, rm trailing slash); plan step 3; tests T4/T5 |
| settings.json wiring merge in or out, and why | Scope decisions: out, with reasons; reminder in step 3 |
| Bless on bare host vs devcontainer config-hash bless | "What bless means" table |
| Hermetic bats tests | Invariant 6; plan Test specification |
| README / guide updates | Plan step 5 |
| Guard resolved-path HARD tier becomes moot | What exists → guard; not planned |
| Pending "hook denies HARD itself" redesign | Noted, not planned |
| Per-project AGENTS.md symlinks | Scoped out: project wiring, not global files |

Moved to plan: all invariants are [observed], and the three hazardous `cp`/`rm`/`diff` behaviors were verified experimentally.

## Files read

Last verified: 2026-09-23
README.md
GEMINI.md
guides/bare-host-hook-wiring.md
guides/README.md
guides/claude-config-security-checkup.md
devcontainer-config/install.sh
devcontainer-config/link-claude-home.sh
devcontainer-config/cc-isolated.sh
hooks/guard-trusted-writes.py
hooks/live-verify-gate.sh
hooks/claude-config-audit.sh
hooks/log-usage.sh
hooks/log-usage-post.sh
hooks/
scripts/lib/skill-paths.sh
test/cc-isolated-functions.bats
test/lib/hermetic-env.bash
docs/decisions/016-multi-project-devcontainer-central-config.md
docs/decisions/022-claude-workflows-payload-in-cc-isolated.md
docs/decisions/023-wire-hooks-from-the-image.md
docs/decisions/035-install-sh-gating.md
docs/decisions/log.md
docs/reviews/code-review-rubric-2026-09-21-answers-2026-09-20-iter3.md
docs/working/questions.md
docs/thoughts/failure-patterns.md
.gitignore
