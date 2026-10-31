Commit: 05b13d11

# Performance Review — feat/q106-host-settings-merge

**Scope:** branch diff `git diff 184396ea..HEAD` (9 files), self-read; whole enclosing unit `install_claude_home` (`devcontainer-config/install.sh:774-1171`) and the linker's wiring block (`devcontainer-config/link-claude-home.sh:84-127`) read in full
**Date:** 2026-10-15
**Based on:** `docs/reviews/code-fact-check-report.md` (Commit 188f5c3c; HEAD 05b13d11 adds only a decision-doc edit on top), plus three execution probes run for this review (below)

**Probes.** These use a throwaway copy of `test/install-host.bats` with three appended `PROBE` tests, run by `/home/node/.claude/jobs/00bcf178/tmp/q106/apiperf/run.sh` (start 2026-10-15T11:37:10Z, HEAD 05b13d11, `timeout 600`, exit 0, 3/3 ok). The copy resolves `../devcontainer-config` and `../hooks` to this worktree. Every install ran under bats' own temp HOME, never the real HOME. Logs are in `/home/node/.claude/jobs/00bcf178/tmp/q106/apiperf/logs/`. Payload size was measured with `du -sk global-instructions skills workflows guides patterns hooks scripts` in this worktree: **2,788 KiB**.

## Data Flow and Hot Paths

- **`install.sh` host target (cold).** A human runs it at a terminal, occasionally. The diff adds work after the content review:
  - a one-object check (`jq -se`), a `cp` plus `jq .` of the live `settings.json`, and one `jq -f wiring-merge.jq` run;
  - a `diff -u` of the two, piped through `vis`;
  - after the y, two `sha256sum` re-checks, a `cp -p` into the backup, a `chmod --reference` and an `mv`.
  - `settings.json` is a few KiB, so every step is O(size of settings.json) and runs once per invocation. The existing payload staging, copying, hashing and diffing (≈2.8 MiB, unchanged by this diff) dominates the run.
- **`link-claude-home.sh` at container start (cold).** It now reads the program from `hooks/lib/wiring-merge.jq` with `jq -f` instead of an inline string. That costs one extra stat (`[ ! -f "$MERGE" ]`) and one small file read. The program is otherwise the same (fact-check Claim 11).
- **Hot path touched indirectly.** The merged `settings.json` decides which hook commands Claude Code runs on *every* matching tool call. A merge that leaves a duplicate group makes a per-tool-call cost fire twice. Finding 2 is that case.
- **Data sizes.** `settings.json` holds tens of hook groups and permission rules. `wiring.json` holds one-digit counts of groups and rules. The merge program is O(groups × hooks + rules²) for array subtraction, and both sides are tiny. Nothing in the diff grows with user data.

## Findings

#### 1. A settings write or backup failure after the swap leaves an unstamped entries backup that rotation never prunes

**Severity:** Low
**Location:** `devcontainer-config/install.sh:1124-1133`, `devcontainer-config/install.sh:1147`, `devcontainer-config/install.sh:1158`
**Move:** 4. Trace the memory lifecycle (resource retention)
**Classification:** Macro (disk use that accumulates across runs, never reclaimed by the rotation) / Cold path (interactive installer, failure branch only)
**Confidence:** High (static; the branch order is unambiguous)
**Legibility-target:** for-author
**Baseline:** 2,788 KiB, the on-disk size of the seven payload sources the entries backup holds (`du -sk` in this worktree, 2026-10-15)
**Evidence:**
> `      if ! cp -p "$settings" "$backup/settings.json" || ! chmod --reference="$settings" "$snew"; then`
> `        echo "ERROR: could not back up $settings; it was not changed. Rerun install.sh." >&2`
> `        exit 1`
> `    printf 'installed_epoch=%s\n' "$(date -u +%s)" > "$backup/.install-stamp"`
> `        [ -f "$d/.install-stamp" ] || continue`

When entries were swapped (`files_changed=1`), the previous seven entries are already in `$backup` when the settings block runs. The settings backup/`chmod` failure and the `mv` failure (`:1131-1133`) both `exit 1` before `.install-stamp` is written at `:1147`. The rotation skips any directory without that stamp (`:1158`; the comment at `:1145-1146` says such a directory "is never removed"). Each such failure therefore leaves one ≈2.8 MiB backup outside the keep-3 budget, never reclaimed. The likeliest trigger is a full disk (a `cp` failure), where leaking more disk is the wrong direction. The size is bounded by the number of failures, which is why this is Low and not higher. API-consistency Finding 4 covers the matching message gap: the user is not told where the entries went.

**Recommendation:** Write `.install-stamp` (or run the rotation) before the settings block, as soon as the entries swap completes. Alternatively, print the backup path in both error branches so the user can reclaim the space.

#### 2. A trailing-slash destination keeps a hand-merged group as foreign and appends a duplicate, so that hook runs twice on every matching tool call

**Severity:** Low
**Location:** `devcontainer-config/install.sh:1004`, `devcontainer-config/install.sh:1387-1389`, `hooks/lib/wiring-merge.jq:37-38`
**Move:** 1. Count the hidden multiplications
**Classification:** Micro (a constant 2× on one hook's per-call cost) / Hot path (Claude Code runs the hook on every matching tool call in every host session)
**Confidence:** Medium. The duplication is execution-verified; how often a destination carries a trailing slash is not known.
**Legibility-target:** for-author
**Baseline:** no baseline available — flagged as speculative
**Evidence:**
> `          jq --arg dir "$dest" --slurpfile w "${new}hooks/wiring.json" \`
> `  if [ -n "${CLAUDE_HOME_DIR:-}" ]; then HOST_DEST="$CLAUDE_HOME_DIR"; HOST_LABEL='$CLAUDE_HOME_DIR'`
> `                                      | all((.command // "")`
> `                                            | contains($dir + "/hooks/")))`

`$dest` is passed to the merge exactly as the environment spells it. Nothing strips a trailing slash, and `install.sh` never normalised `HOST_DEST`, because before Q-106 only file operations used it. PROBE3 used a hand-merged group `bash $HOME/.claude/hooks/h.sh`, the spelling guide §2 tells the user to use, with `CLAUDE_HOME_DIR="$HOME/.claude/"`. The provenance test looks for `…/.claude//hooks/`, does not match, and keeps the old group as foreign. Then it appends `…/.claude//hooks/h.sh`. The result is `["bash …/.claude/hooks/h.sh","bash …/.claude//hooks/h.sh", …]` (`logs/probe3-commands.txt`): the same hook is wired twice, which is the FP-161 double-fire class the provenance rule exists to prevent. Each matching tool call then pays that hook's process start-up twice. For the Python guard hooks that is tens of milliseconds per call (an estimate, not a measurement). Later runs with the same spelling are idempotent, so the duplicate is stable rather than growing. The same probe also emitted the deny rule `Edit(//…/.claude//settings*.json)` with an inner `//`. Whether that still matches is a security-reviewer question, not a performance one.

**Recommendation:** Normalise once in `main`, for example `HOST_DEST="${HOST_DEST%/}"` (or the physical path, if that matches what Claude Code and link-claude-home use). Then add a test with a trailing-slash `CLAUDE_HOME_DIR` that asserts a single `h.sh` command.

## Endorsements (evidence-gated)

- A settings-only change swaps none of the seven entries and leaves the manifest alone, so a settings fix does not copy a ≈2.8 MiB entries backup [fact-check: claim 8 — Verified].
- Rerunning on an already-merged `settings.json` writes nothing and does not prompt. The old side is `jq .` of the live file, so a layout-only difference does not trigger a rewrite (T94: "Nothing to install", snapshot equal) [fact-check: claim 32 — Mostly accurate; the idempotence half is execution-verified, the inaccuracy concerns authorship wording].
- The merge runs from the `.cw-new.` copies already staged and hashed for the content review (`${new}hooks/wiring.json`, `-f "${new}hooks/lib/wiring-merge.jq"`). It adds no second `git archive` or extraction [read: devcontainer-config/install.sh:892-904,998-1005].
- The container-start cost of the merge is unchanged: the program text is identical to the inline version, and only its source moved to a file [fact-check: claim 11 — Verified].
- The three staging files (`settings.view`, `.raw`, `.diff`) live under `$HOST_TMP`, and main's EXIT trap removes that directory on every path, so nothing accumulates across runs [unverified — submitted as claim].

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Settings backup/write failure after the swap leaves an unstamped ≈2.8 MiB entries backup that rotation never prunes | Low | `devcontainer-config/install.sh:1124-1133` | High |
| 2 | Trailing-slash destination: the hand-merged group is kept as foreign and duplicated, so the hook runs twice per matching tool call | Low | `devcontainer-config/install.sh:1004`, `:1387-1389` | Medium |

## Overall Assessment

On performance this change is benign. Everything it adds runs once per human-driven install over a file of a few KiB, beside a payload stage that is three orders of magnitude larger. The settings-only path makes the common drift fix cheaper than a full install. Neither finding blocks merging, and both can be fixed in place:

- Finding 1 is a retention leak on a failure branch: stamp the backup before the settings block.
- Finding 2 is the one place where the cold-path installer affects a hot path. An unnormalised destination reintroduces the duplicate-hook double-fire the provenance merge exists to prevent, so normalise `HOST_DEST`.

No profiling is needed. Both findings follow from code structure, and Finding 2's duplication is shown by PROBE3.

One related observation is outside performance, because it concerns recovery and not cost. A settings-only run creates a stamped backup that counts toward the "last 3 installs". PROBE2 ran one full install and then three settings-only drifts, and it pruned the only backup holding the replaced entries (`logs/probe2-backups.txt`: three backups, each holding only `.install-stamp settings.json`). This is filed in the API-consistency report as a documented-contract change.

## Goal-Alignment Note
- Success criterion (restated verbatim): both reports saved at those paths.
- Answered: yes. This is the performance half: full diff and the whole `install_claude_home` read, with two findings and five endorsements.
- Out of scope: whether the `//` deny rule from Finding 2 still matches (security-reviewer). The backup-rotation contract change (filed in the API-consistency report).
- Escalate: Finding 2's deny-rule spelling (`Edit(//…/.claude//settings*.json)`) to the security reviewer. PROBE2's retention result to synthesis, as a recovery concern.
- Decisions I made: I counted Finding 2 as touching a hot path (per tool call), not the cold installer, and capped it at Low because the trigger is an edge spelling. I used the measured payload size as Finding 1's baseline instead of the "2.4 MB" in a code comment, whose source is undocumented.
