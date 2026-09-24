Commit: d0fdd04

# Performance Review: `ans/copy-install` (host `~/.claude` copy install)

**Scope:** `712c626..d0fdd04`, mainly `devcontainer-config/install.sh` (`install_claude_home()` and its helpers) and `test/install-host.bats`
**Date:** 2026-09-23
**Based on:** `docs/reviews/code-fact-check-report.md` (k=3 merge; Claims Requiring Attention, Replicate annotations and Escalations E2, E3, E6 and E7 read)
**Probe evidence:** hermetic drivers and logs are in `/tmp/claude-1000/-workspace/d516ca2c-2abb-4732-a34a-041aa98280c8/scratchpad/perf-copy/` (`probe.sh`, `probe2.sh`, `run/out-*.txt`, `audit-with.txt`, `audit-without.txt`, `bats.txt`). `$TMPDIR` was unset in this session, so the scratchpad stood in for `$TMPDIR/perf-copy/`. Every run used a copy of the worktree's real payload under a temp `HOME`, with `CLAUDE_HOME_DIR`, `CLAUDE_DEVC_CONFIG_DIR`, `CLAUDE_DEVC_BIN_DIR` and `TMPDIR` pinned there, `CLAUDECODE` unset and `cc-isolated.sh` stubbed. Nothing touched the real `~/.claude`, `~/.config` or `~/.local`.

## Data Flow and Hot Paths

`install.sh` runs by hand on the host. Every path in this diff is **cold**: it runs once per human install, and there are no request handlers or per-item loops at scale. On an interactive run it:

1. assembles the whole payload into `devcontainer-config/claude-home` and diffs it against `$DEST`;
2. passes the skip rules, then assembles the same payload a second time into `mktemp`;
3. runs the pre-pass (`find` over each owned directory), then a second full `diff -ruN`;
4. on y, runs `cp -R` into `.cw-new.*`, `mv`s the old entries into `.claude-workflows-backup/<stamp>/`, and `mv`s the new copies in.

Payload size, measured on the worktree: 108 files, about 2.3 MB (skills 884K, scripts 576K, workflows 384K, guides 264K, hooks 96K, patterns 52K, CLAUDE.md 36K).

The double assembly and double diff flagged in the brief cost nothing noticeable at this size. A no-change interactive run with both targets took **0.27 s** wall (`out-noop-1.txt`), and a `--yes` run took **0.05 s**. The first case below that took longer (2.11 s) spent the time printing to the pty, not assembling. `test/install-host.bats` ran 24/24 in **19.2 s** (`bats.txt`). It is tagged `# @category slow`, so `run-tests.sh --fast` leaves it out. Neither cost is a finding.

The costs that do scale are **disk and attention**, not CPU. Two things grow: the backup directory, with every accepted run, and the review text, with the size of the payload. Findings 1 and 2 are about those two.

## Findings

#### 1. Every accepted install, including a no-change one, adds a full ~2.4 MB copy of the tree to `.claude-workflows-backup/`, and the repo's own security auditor re-scans every copy

**Severity:** Medium
**Location:** `devcontainer-config/install.sh:410-428` (with `:375-390` and `:450-452`); interacts with `scripts/claude_config_audit.py:46`, `:146` and `:216-217` (not in this diff)
**Move:** Trace the memory lifecycle (unbounded growth) / Price the deployment environment
**Classification:** Macro (unbounded, grows linearly with install count) / Cold path (manual install). Matrix default: Low. **Escalated to Medium** because the growth lands on a security-review surface: the `claude-config-security-checkup` audit's findings multiply, not just its runtime.
**Confidence:** High (executed)
**Baseline:** 1.13 s audit wall time over 77 policy files with 38 LOW findings for a single installed tree, against **6.80 s over 457 files with 228 findings** after five accepted installs (hermetic probe, 2026-09-23, `audit-without.txt` / `audit-with.txt`)
**Legibility-target:** for-author

**Evidence:**
```bash
# devcontainer-config/install.sh:415-427
  if [ "$any" -eq 1 ]; then
    backup="$bkroot/$stamp"
    if [ -e "$backup" ]; then backup="$backup.$$"; fi
    if ! mkdir -p "$backup"; then
      for name in "${CLAUDE_HOME_NAMES[@]}"; do rm -rf "$dest/.cw-new.$name"; done
      echo "ERROR: could not create $backup; nothing was replaced." >&2
      exit 1
    fi
    for name in "${CLAUDE_HOME_NAMES[@]}"; do
      if [ -e "$dest/$name" ] || [ -L "$dest/$name" ]; then
        mv "$dest/$name" "$backup/$name"
      fi
    done
```
```bash
# devcontainer-config/install.sh:375-377, 386
  if [ "$changed" -eq 0 ]; then
    echo "(none — the destination already matches the repo)"
  fi
  if ! confirm "Install these files into $dest?"; then
```
```python
# scripts/claude_config_audit.py:46 (is_policy_file), :146 (walk), :216-217 (default roots)
    if ".claude" in parts and p.suffix.lower() in {".md", ".json", ".yaml", ".yml", ".toml", ".txt", ""}:
        for dirpath, dirnames, files in os.walk(root, followlinks=True):
    roots = args.paths or [".claude", str(Path.home()/".claude"), "CLAUDE.md",
                           "global-instructions/CLAUDE.md"]
```

A "(none)" review still ends in a y/N prompt, and a y still does the full copy, move-aside and swap. Every accepted run therefore moves the whole prior tree into a new stamp directory, whether or not anything changed. Nothing prunes these directories. The only mitigation is the "delete it when satisfied" line at `:451`. Five accepted runs left 5 backup directories holding 12 MB, 545 files and 125 `SKILL.md` copies, against 2.4 MB installed (`probe.sh`).

`claude_config_audit.py` walks `~/.claude` recursively by default. `SKIP_DIRS` does not include `.claude-workflows-backup`, and every `.md` file under a `.claude` path counts as a policy file. So each backup adds about 76 policy files to every audit. Audit time, finding count and the "top files" list all grow linearly, and after five installs the top-files list is mostly backup duplicates of the same guide. Growth is one tree per accepted install. At a weekly `git pull` + install cadence that is roughly 50 trees and about 120 MB a year, with the audit around 50× slower. That annual figure is extrapolated, not measured; verify it against the user's actual install cadence.

**Recommendation:** When the pre-pass and diff find no change (`changed=0`), say so and return without prompting, so a no-op run never swaps or backs up. Separately, cap retained backups: keep the last N stamps, or at least print the backup root's total size next to the "delete it when satisfied" line. Add `.claude-workflows-backup` to `SKIP_DIRS` in `claude_config_audit.py`, in the same change or a follow-up.

---

#### 2. A first install into a destination without the entries prints the whole payload, ~32k lines, and scrolls the REPLACE/MOVE/WIRED lines far above the prompt

**Severity:** Medium
**Location:** `devcontainer-config/install.sh:342-386` (the pre-pass prints first, then `review_diff` at `:372`, then the prompt at `:386`); `review_diff` at `:133-155`
**Move:** Ask "what's the size of N?" (N = payload size; output is O(payload bytes))
**Classification:** Macro (review text scales linearly with the payload) / Cold path (one-time). Matrix default: Low. **Escalated to Medium** because the cold path blocks the operation that matters here, a human reading the review gate. The pre-mortem (`docs/reviews/pre-mortem-copy-install.md:72`) names this exact "every file shows as new" review as the camouflage for a hostile install.
**Confidence:** High (executed)
**Baseline:** 31,930 lines / 2,066,143 bytes of review before the host `[y/N]` for a destination that lacks the seven entries. A realistic migration from the old README layout (five top-level links, a real `hooks/` directory with five per-file links, four copies and one foreign wired hook) gave **258 lines**, with the MOVE/WIRED line 227 lines above the prompt (hermetic probe 2026-09-23, `out-first-empty.txt`, `out-realistic.txt`)
**Legibility-target:** for-author

**Evidence:**
```bash
# devcontainer-config/install.sh:144-145 (inside review_diff, :133-155)
    rc=0
    diff -ruN "$dest/$item" "$src/$item" || rc=$?
```
```bash
# devcontainer-config/install.sh:370-379
  # Content diff: the same review_diff the devcontainer target uses. Through a
  # symlinked entry it compares the link's target (the checkout) with the stage.
  if ! review_diff "$dest" "$stage" "${CLAUDE_HOME_NAMES[@]}"; then
    changed=1
  fi
  if [ "$changed" -eq 0 ]; then
    echo "(none — the destination already matches the repo)"
  fi
  echo "==============================================================================="
  echo
```
```bash
# devcontainer-config/install.sh:185-187 (devcontainer target, for contrast)
  else
    echo "First install — $DEST does not exist yet."
    echo
```

`-N` prints every file of an absent entry as additions, so review size equals payload size. The devcontainer target avoids this by skipping the diff when `$DEST` is absent (`:185-187`). The host target cannot use the same test, because `~/.claude` nearly always exists (Claude Code creates it) while the seven entries do not. Triggers include:

- a fresh host;
- a new `CLAUDE_CONFIG_DIR`;
- a user who removed the old links by hand before running the installer, a path the README invites.

In those cases the only lines needing judgment (`REPLACE symlink`, `MOVE to backup`, `<-- WIRED in settings`) print *before* 32k lines of diff and are gone from any ordinary terminal scrollback when the prompt appears. Scrollback length is [assumed] in the 1k–10k range typical of terminal defaults. The review also grows with the payload: every skill added makes the first-install gate longer.

The user's plan-step-9 migration from links reviews at about 258 lines and is not at risk.

**Recommendation:** Before the `[y/N]`, print a short footer that repeats the pre-pass verdicts: counts plus the full MOVE/WIRED lines, which are few, then the prompt. For an entry that is entirely absent, consider printing `NEW <entry>: <n> files` with the file list instead of the full content, the way the devcontainer target does. The full diff can stay available by paging (`| less`) or through an env var.

---

#### 3. Ignored build artifacts in the checkout (`__pycache__`) are installed into `~/.claude` and become permanent review noise once Python recompiles them

**Severity:** Low
**Location:** `devcontainer-config/install.sh:108-110` (`assemble`'s `cp -r` of each whole source directory), reached by the host target at `:335`
**Move:** Find the work that moved to the wrong place
**Classification:** Micro (one extra file per module) / Cold path. Matrix default: Informational. Raised to Low because it defeats the `(none)` short-circuit that Finding 1's fix depends on.
**Confidence:** Medium (the recompile was executed; whether anything on the host imports from `~/.claude/scripts` is [assumed])
**Baseline:** no baseline available — flagged as speculative
**Legibility-target:** for-author

**Evidence:**
```bash
# devcontainer-config/install.sh:108-111
  for item in "${CLAUDE_HOME_SRC[@]}"; do
    if [ -e "$REPO_ROOT/$item" ]; then
      cp -r "$REPO_ROOT/$item" "$stage/$(basename "$item")"
    else
```

The worktree has git-ignored `scripts/__pycache__/` and `hooks/__pycache__/`. `assemble` copies whatever is on disk, so two `.pyc` files are installed into `~/.claude/scripts/__pycache__/`. The `dirty=` check at `:125` uses `git status --porcelain`, which does not list ignored files, so nothing tells the user about them. `cp -R` does not preserve mtimes, so the installed `.pyc` no longer matches its source's recorded mtime. When `lite-review.py` was imported from the installed copy, Python rewrote the `.pyc` (md5 `59e1f0ea…` → `4c71894f…`). From then on every review shows `Binary files … differ` and `changed=1`. The same path would install any larger ignored tree the user keeps in the checkout, such as `.venv` or `node_modules`, without saying so.

**Recommendation:** Stage from `git ls-files` (or `git archive`) for the tracked set, plus a dirty-tree warning for untracked files. At minimum, exclude `__pycache__`/`*.pyc` from `assemble`.

## Endorsements

- For `--yes`, non-TTY and `CLAUDECODE` runs, the host target returns before `mktemp`/`assemble`, so scripted runs pay no second staging or diff. `[fact-check: claim 12 — Mostly accurate overall; the ordering half was Verified by all three replicates (r3 P1c exit 0), and the defect is Claim 13's "one line" wording]`
- The pre-pass tests `[ -L "$dest/$name" ]` before `[ -d … ]`, so a top-level symlink into the checkout gets one REPLACE line and is never walked by `find`. `find` runs only over real directories. `[read: devcontainer-config/install.sh:345-368]`
- The backup is a `mv` into a directory under `$dest`, so on the usual single-filesystem `~/.claude` it is a rename per entry, not a second full copy. Only the staging copy (`cp -R` into `.cw-new.*`) costs payload-size I/O. `[unverified — submitted as claim]` (same-filesystem is assumed; a `~/.claude` with an entry on another mount would fall back to copy-then-delete)
- The whole interactive two-target run with no changes costs about 0.27 s wall on a 108-file payload, so the double assembly and double diff are not a runtime concern at the current payload size. `[unverified — submitted as claim]` (single-machine probe, `out-noop-1.txt`)

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Backup dir grows by a full tree per accepted install, no-op runs included; the security auditor re-scans every copy (6× files, 6× time and findings after 5 runs) | Medium | `devcontainer-config/install.sh:410-428` (+ `scripts/claude_config_audit.py:46,146,216`) | High |
| 2 | A first install into a destination without the entries prints ~32k lines of diff, burying the REPLACE/MOVE/WIRED lines above the prompt | Medium | `devcontainer-config/install.sh:342-386` | High |
| 3 | Ignored `__pycache__` is installed; a Python recompile makes the review permanently non-"(none)" | Low | `devcontainer-config/install.sh:108-110` | Medium |

## Overall Assessment

Runtime cost is a non-issue. At about 2.3 MB and 108 files, assembling and diffing twice costs a fraction of a second, and the slow-tagged bats file runs in about 19 s. The change's performance posture is about **what it accumulates and what it asks a human to read**, and both scale linearly with things that only grow:

- the backup directory grows with the number of accepted installs;
- the first-install review grows with payload size.

Both fixes are small and local to `install_claude_home()`: skip the swap when nothing changed, cap or size-report backups, and repeat the pre-pass verdicts right above the prompt. None needs a structural change. The most important fix is the no-op short-circuit in Finding 1, because it also removes most of the backup growth. Finding 2 does not affect the user's own plan-step-9 migration from links, which reviews at about 258 lines. No further profiling is needed. The one number worth confirming on the real host is how often the user will accept an install, since that sets Finding 1's growth rate.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the output path your task names, structured per your skill, beginning with a `Commit: d0fdd04` line.
- Answered: yes
- Out of scope: correctness of the step-2/3 failure window and concurrent-run collisions (fact-check E2/E7). They were not re-derived here, and they are correctness issues, not performance ones. macOS/BSD behavior (E8) was not run.
- Escalate: Finding 1's interaction with `scripts/claude_config_audit.py` (outside this diff) needs an owner decision on whether the `SKIP_DIRS` fix rides on this branch or follows it.
