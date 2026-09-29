Commit: de53069

# Performance Review — feat/dev-cycle-digest (final pass 2)

**Scope:** `git diff main...HEAD -- scripts test` (scripts/dev-cycle.sh, test/scripts/dev-cycle.bats) and commit messages `main..HEAD`
**Date:** 2026-09-29
**Based on:** brief-digest-final2.md; override log rows 166-169 (deferred items not re-filed)

> ⚠️ **No code fact-check report provided.** Performance claims in comments and documentation
> have not been independently verified. For full verification, run the `code-fact-check` skill
> first or use the code-review orchestrator.

## Data Flow and Hot Paths

`scripts/dev-cycle.sh` is a CLI that runs once per dev cycle (the default window is 14 days), by hand or from the dev-cycle skill. **Every path in it is cold.** No request path calls it and nothing loops over it. The two costs worth looking at are wall-clock time as history grows, and digest size, because an agent reads the whole digest into its context.

Pass 2 adds two subprocesses per decision record that has a `## Revisit triggers` section (line 111): `git log -1 --first-parent --since=<midnight> <main-sha> -- <file>` and `git status --porcelain -- <file>`. Records that get printed also run `git log -1 --format=%ad -- <file>` (line 114). N is the number of such records: 11 of 32 in this repo today. It grows by roughly one per full decision record.

Measurements. I ran the committed script from the worktree against a throwaway clone of this repo in the scratchpad: 1,887 commits, 995 of them on main's first-parent line, 11 trigger records, 65 log rows, and an untracked `cycle-2026-09-15.md`.

| Run | Wall time | Digest size |
|---|---|---|
| default (carry-forward from the 09-15 record) | 0.19 s | 20,753 B, 137 lines |
| `--since=2026-09-15` (everything printed in full) | 0.20 s | 20,548 B |
| `--since=2025-09-29` (window covers all history) | 0.26 s | 20,586 B |

Per call, averaged over 20 calls on `docs/decisions/035-*.md`:

| Call | Time per call |
|---|---|
| first-parent `git log` in a 2-week window | 3.5 ms |
| first-parent `git log`, 1-year window, file never matched (worst case: walks the whole first-parent line) | 9.9 ms |
| `git status --porcelain -- <file>` | 3.2 ms |
| unbounded `git log -1 --format=%ad` (line 114) | 4-5 ms |

`bats test/scripts/dev-cycle.bats` passed all 13 tests in 2.1 s. No bats processes were left behind.

Digest composition (default run): §2 Revisit triggers is 17.5 KB, 85% of the digest (about 4.4k tokens). §1 Activity is 2.4 KB. Everything else is under 0.4 KB. Nine of the 11 records print in full because a 2026-09-26 bulk edit touched all of them. That is the file-level carry-forward cost already deferred in override row 166, so it is not re-filed here. The longest single quoted trigger line is 2,075 B.

## Findings

#### Per-record `git log` + `git status` pair scales linearly with the number of trigger records

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:105-120` (line 111)
**Move:** Count the hidden multiplications
**Classification:** Micro (a constant 2-3 forks per record) / Cold path (once per dev cycle, CLI)
**Baseline:** Measured on 2026-09-29 against a clone of this repo: the whole digest takes 0.19 s. The pair costs about 6.7 ms per record in a 2-week window, and at most about 13 ms per record when the window covers all 995 first-parent commits.

Each trigger record costs one first-parent `git log`, one `git status`, and one unbounded `git log` when it is printed. Cost is O(records × first-parent commits in the window). `--since` bounds the walk (git stops once commits are older than the cutoff), and `-1` stops at the first hit. At 11 records the pair adds about 75 ms. At a plausible 100 records it would add about 0.7-1.3 s, still negligible for a once-per-cycle CLI.

An optional cheap improvement: run one `git status --porcelain -- docs/decisions` before the loop and look each file up in that output. That removes N-1 forks. It is not worth the added lines while the unit sits at the 400-line cap.

**Confidence:** High. Measured, not inferred.

## What Looks Good

- `sed -n '1,30p'` replaced `head -30` on the merge list. sed reads its whole input, so the upstream `printf` can no longer get SIGPIPE, and the extra read is bounded by the size of the merge list, which is already in memory. [read: scripts/dev-cycle.sh:88-93]
- Control-character stripping is one `tr` pass over the merge list, run once and not per line. [read: scripts/dev-cycle.sh:88]
- The new first-parent carry-forward query is bounded by the window. It cost 3.5 ms per record over a 2-week window and 9.9 ms over the full history. [read: scripts/dev-cycle.sh:111; measured in the scratchpad clone, see Data Flow]
- Digest §1 caps the merge listing at 30 lines plus a "… N more" count, so activity stays about 2.4 KB even with 385 merges in the window. [read: scripts/dev-cycle.sh:93]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Per-record `git log`+`git status` pair is linear in trigger records (≈6.7 ms each; 0.19 s total) | Informational | `scripts/dev-cycle.sh:111` | High |

## Overall Assessment

The pass-2 fixes cost nothing that matters. The new per-record first-parent `git log` and `git status` calls add about 7 ms per record, and the whole digest runs in 0.19-0.26 s even when the window covers all of this repo's history. Worst-case scaling is linear in records × window commits, which is fine for a once-per-cycle CLI. The only real cost is digest size: about 20.5 KB (about 5k tokens), 85% of it in §2. That comes from file-level carry-forward, already deferred with a revisit trigger in override row 166. Nothing here needs fixing before merge, and no profiling is needed.

**Outside my scope, for the correctness critics:** "last committed" dates (lines 114 and 180) come from `git log -1 --format=%ad` against `HEAD`, using the author date, with no `--first-parent` and no `$MAIN_SHA`. So they can show a branch commit's date or a date from the current branch, which is inconsistent with the "Merges and commits: `<main>`" window line and with the carry-forward semantics pass 2 just fixed. Separately, in my clone the resolved `MAIN` was `feat/dev-cycle-digest`, because the clone's `origin/HEAD` follows the source repo's checked-out branch. That is expected behaviour, noted only so the measurement context is clear.
