Commit: f14cf11a

# Performance Review — feat/q106-host-settings-merge (loop pass 2)

**Scope:** range `git diff 05b13d11..HEAD` (f7680e0d, d53d2bf4, a4f3614a, f14cf11a), self-read. `git diff 184396ea..HEAD` checked before calling anything missing. The whole enclosing unit `install_claude_home` (`devcontainer-config/install.sh:790-1218`) and the new top-level helpers (`:721-732`) were read in full at HEAD.
**Date:** 2026-10-15
**Based on:** `docs/reviews/code-fact-check-report.md` (Commit a4f3614a, k=1; HEAD f14cf11a then rekeys the by-name list by event and matcher and adds its failure WARNING, so fact-check claim 7b describes the earlier program). Also my pass-1 report `performance-review-2026-10-15-q106.md` (context only), plus the probes below.

**Probes.** `/home/node/.claude/jobs/00bcf178/tmp/q106/apiperf2/run.sh`, started 2026-10-15T12:06:19Z at HEAD f14cf11a under `timeout 600`, exit 0, 4/4 ok. It runs a throwaway copy of `test/install-host.bats` with four appended `PROBE` tests. The copy's `../devcontainer-config` and `../hooks` are symlinks to this worktree. Every install ran under bats' own temp HOME, never the real HOME. Timing comes from `timing.sh` in the same directory (2026-10-15T12:06:31Z, load average 2.36: other sessions' bats suites were running). The Q-106 tests T93-T102 were also rerun at HEAD (12:07:28Z, 10/10 ok). Logs are in `…/apiperf2/logs/`. Nothing was left running: `ps` after the runs shows no process from these scripts.

## Data Flow and Hot Paths

- **`install.sh` host target (cold).** A human runs it occasionally at a terminal. Between the content review and the prompt, the settings block now starts **six** jq processes (pass 1 had three), all through `sjq` (`env -i … jq`):
  1. `WIRING_SHAPE` over the staged `wiring.json`;
  2. `ONE_OBJ` over the one copy of the live file;
  3. `sjq .` to pretty-print that copy;
  4. the merge;
  5. `ONE_OBJ` over the merged output;
  6. the by-name summary program.
  Around them sit one `stat`, one `cp` and one `chmod`. On a write, the tail adds a `mkdir -p` and a `cp -pP`.
- **Measured cost.** A bare `sjq` start costs **14.7 ms** (100 launches in 1.469 s). The merge program over the real `hooks/wiring.json` (3 events, 7 groups, 9 commands, 12 rules) takes **18.7 ms** per run (100 runs in 1.867 s). The three extra launches add ≈45 ms to an interactive run whose ≈2.8 MiB payload copy, hash and diff were unchanged by this range.
- **The summary program.** Three array subtractions: commands old − new, and per mode rules old − new and new − old. jq's array `-` compares every element against every element of the other array, so the cost is O(|old|·|new|) per pair. Commands number in the tens. User `allow` lists can reach a few hundred rules, which still means at most ~10⁵ equality tests, a few ms. Nothing scales with user data beyond the size of `settings.json`.
- **`link-claude-home.sh` (cold, container start).** The only change is the `env -i PATH HOME=/nonexistent` prefix on the merge call. That is one extra `env` exec, and the program and its input are unchanged.
- **The hot path touched indirectly.** The merged `settings.json` decides which hooks fire on every matching tool call. Pass 1's Finding 2 (a trailing slash duplicating a hook) was the one hot-path effect. It is resolved: see the next section.

## Pass-1 findings: status

- **Pass-1 Finding 2 (a trailing-slash destination duplicates a hand-merged hook; the hook runs twice per call): resolved.** `s_dir="$(cd "$dest" && pwd)"` (`install.sh:1012`) is what the merge gets as `--arg dir` (`:1027`). T98 now runs with `CLAUDE_HOME_DIR="$CLAUDE_HOME_DIR/"`, passes at HEAD (my rerun, 12:07:28Z), and fails on 05b13d11 (fact-check claim 6).
- **Pass-1 Finding 1 (a settings failure after the swap leaves an unstamped ≈2.8 MiB entries backup that rotation never prunes): message fixed, leak accepted.** The rubric records C3: "unpruned backup after that failure accepted". The error now names the backup: `s_fail="$s_fail; the files above WERE installed${backup:+, their previous versions are in $backup}"` (`:1166`), so the user can reclaim the space by hand. Not re-filed.

## Findings

#### 1. Settings-only backups are never pruned, so each settings-only run leaves one more directory for good

**Severity:** Informational
**Location:** `devcontainer-config/install.sh:1167-1169`, `devcontainer-config/install.sh:1180-1183`, `devcontainer-config/install.sh:1205`
**Move:** 4. Trace the memory lifecycle (retention)
**Classification:** Macro (disk use that accumulates across runs with no reclaim) / Cold path (interactive installer). The matrix default is Low. I lowered it to Informational because each directory holds one `settings.json` of a few KiB, and the run prints its path with "delete it when satisfied".
**Confidence:** High (static; T94 asserts the unstamped directory)
**Legibility-target:** for-author
**Baseline:** no baseline available — flagged as speculative
**Evidence:**
> `      if [ -z "$backup" ]; then backup="$bkroot/$stamp"; if [ -e "$backup" ]; then backup="$backup.$$"; fi; fi`
> `    # Review A6: not stamped, so it never counts among (or prunes) the 3 kept.`
> `        [ -f "$d/.install-stamp" ] || continue`

This is the intended fix for pass-1 API Finding 1, and it changes retention in the other direction. A settings-only run (`files_changed=0`) creates `$bkroot/<stamp>/settings.json`, never stamps it, and the rotation skips anything unstamped, so the directory stays until the user deletes it. The count grows with the number of settings-only runs: a `wiring.json` change on its own, or drift fixes. That number is small in practice, and each directory costs one inode plus a few KiB. The only real cost is that `.claude-workflows-backup/` slowly fills with unrotated stamps. Neither the README nor `--help` says these directories are outside the "last 3 installs" rule (API-consistency pass-2 Finding 5).

**Recommendation:** None needed for cost. If a bound is wanted later, give settings-only backups their own stamp key and keep the newest N of those, separately from the entries rotation.

#### 2. The by-name summary runs before the diff, so its jq start is wasted on every already-merged rerun

**Severity:** Informational
**Location:** `devcontainer-config/install.sh:1039-1053`
**Move:** 3. Find the work that moved to the wrong place
**Classification:** Micro (one process start) / Cold path (interactive installer)
**Confidence:** High (static; branch order)
**Legibility-target:** for-author
**Baseline:** 14.7 ms per `sjq` start (100 bare `env -i … jq -n 1` launches in 1.469 s, `…/apiperf2/logs/timing.txt`, 2026-10-15T12:06:31Z, load average 2.36)
**Evidence:**
> `    sjq -rn --slurpfile o "$s_view" --slurpfile n "$snew" '`
> `      0) rm -f "$snew" ;;   # already merged: nothing to write`
> `         vis_or_die < "$s_view.sum"`

The summary is computed into `$s_view.sum` unconditionally. Its output is read only in the `rc=1` arm. The `rc=0` arm (`settings.json` already merged, the common rerun) discards it. That costs ≈15 ms per no-op run, once, on a human-driven path, so it is not worth changing for speed alone.

**Recommendation:** Optional. Move the `sjq -rn …` call into the `1)` arm before `vis_or_die < "$s_view.sum"`. That also keeps the summary next to the only place it is shown.

## Endorsements (evidence-gated)

- The merge's `--arg dir` now has no trailing slash, so `CLAUDE_HOME_DIR=…/` no longer produces the duplicate hook that fired twice per matching tool call (pass-1 Finding 2) [fact-check: claim 6 — Verified].
- Every settings-block jq call runs as `sjq`, so a `~/.jq` library cannot add work to, or reshape, the merge [fact-check: claim 3 — Verified].
- The live `settings.json` is read once into `$s_view.raw`, and the one-object check, the hash and the merge all read that copy. This replaces pass 1's separate check read and copy read [fact-check: claim 5 — Verified].
- A settings-only run no longer stamps its backup, so it cannot prune a ≈2.8 MiB entries backup out of the keep-3 window (pass-1 API Finding 1) [fact-check: claim 9 — Verified].
- The extra validation (`WIRING_SHAPE`, `ONE_OBJ` on the output) costs ≈15 ms per launch on a cold path. Over the real wiring the merge itself runs in ≈19 ms [read: devcontainer-config/install.sh:1019-1029] (timing from `…/apiperf2/logs/timing.txt`).

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Settings-only backups are never pruned; one more directory per settings-only run | Informational | `devcontainer-config/install.sh:1167-1183` | High |
| 2 | Summary jq runs before the diff, wasted on an already-merged rerun | Informational | `devcontainer-config/install.sh:1039-1053` | High |

## Overall Assessment

On performance this range is benign and closes the one finding that reached a hot path: the trailing-slash duplicate hook is gone, and a test pins it. What the range adds is three more jq starts (≈45 ms measured) and one small set-difference program, all on a human-driven installer, next to a payload stage that dominates the run. The two findings are informational. Settings-only backups now accumulate outside the rotation by design, at a few KiB each. The summary jq start is wasted on an already-merged rerun. Neither blocks merging. No further profiling is needed: the costs were measured directly.

## Goal-Alignment Note
- Success criterion (restated verbatim): "(1) performance per … SKILL.md → docs/reviews/performance-review-2026-10-15-q106-pass2.md", first line `Commit: <HEAD short sha>`; "performance: the extra jq invocations and the summary program's cost"; "Verify your pass-1 findings are resolved".
- Answered: yes. The extra jq starts and the merge are timed. The summary program's complexity is bounded. Pass-1 Finding 2 is resolved and test-pinned; pass-1 Finding 1 is accepted with its message fixed. Two informational findings.
- Out of scope: the message and contract issues PROBE1-4 found (a first install announces "Previous entries moved" for a settings-only backup; an empty by-name list prints nothing; the empty-group refusal reason) are filed in the API-consistency pass-2 report.
- Escalate: none.
- Decisions I made: I lowered Finding 1 from the matrix default (Macro × Cold = Low) to Informational, because the per-directory size is KiB and the user is told the path. The timings ran while other sessions' bats suites loaded the machine (load average 2.36), so they are upper-ish figures, not a quiet-machine baseline.
