# Performance Review — feat/build-loop-u3a2 (final confirming pass)

**Scope:** `git diff main...HEAD -- scripts test` at 6cbca87c (`scripts/build-loop.sh`, `test/scripts/build-loop-merge.bats`) and `git log main..HEAD`; the new code since iteration 2 is `f4278181..6cbca87c`
**Date:** 2026-10-10
**Based on:** Stage 1 summary of `docs/reviews/code-fact-check-report-u3a2-final-r{1,2,3}.md` (the merged report is still pending), `docs/reviews/performance-review-2026-10-10-u3a2-i{1,2}.md`, override-log rows 494, 639 and 646

## Data Flow and Hot Paths

`--merge BRIEF --expect SHA` lands one self-merge brief per process, a few times a day, so the whole mode is a **cold path**. Iteration 1 measured the main costs on /workspace. One `store_check --main` pass in `gate_start` (`scripts/build-loop.sh:914`) took 0.24 s, and everything `land` adds came to about 50 ms in forks and stats. I read these functions in full at HEAD: `state_gate` (`:341-363`), `default_gate` (`:369-379`), `gate_start` (`:910-917`), `check_line`'s `verdict_ok` (`:989-995`, `:1005`), `merge_ident` (`:1015-1022`), `land` (`:1043-1112`) and the merge arm (`:1134-1146`).

Fix commit 6cbca87c (B1, D1–D4) changes the cost profile in four ways:

- **B1, early state gate in W** (`:1072-1073`): a `[[ -d ]]` check, then `(cd "$w" && state_gate)` in a subshell, before any git command runs in W. When W exists, `state_gate` therefore runs in W twice per landing: once here and once in the re-run at `:1099`. I measured one `state_gate` in a subshell against /workspace at **10.5–11.4 ms** (5 runs of 10 each; probe `scratchpad/u3a2-final-performance/probe.sh`, load average 0.4–1.4). That is about 10 git forks: 6 `rev-parse --git-path`, 1–2 `git config --file`, `for-each-ref` and `symbolic-ref`.
- **D1, rebase/bisect scan** (`:1062-1067`): a third probe file was added (`rebase-merge/update-refs`). The `[[ -f ]] && $(<f)` read of head-name became `[[ -e ]]`, `[[ -r ]]` and `grep -qxF`. Absent files, which is almost every file in almost every run, still cost a `stat` and no fork, because `[[ ! -e … ]] ||` short-circuits. A `grep` fork runs only when rebase state exists, and in that case the scan refuses or moves on after one file.
- **D3, `land AUTHORITY`**: `$1` is spliced into `msg` and the `printf` format. This costs nothing.
- **D4**: test only. It adds a `--merge` run, two `find | wc -l` calls and a `reset --hard` to the W test.

Net effect: a W landing pays about 11 ms more (one extra `state_gate`). An update-ref landing pays nothing more. `land` still calls no `store_check`, and `--merge` still calls `gate_start` once (`:1135`), so row 639's "second full pass" trigger is still not met within a process. Each landing still costs about 0.29 s, dominated by `store_check`.

## Findings

No findings.

Iteration 1's F1 (foreground maintenance) and F2 (`cat` forks) were fixed in f782d9ee. Iteration 2's F1 (no regression guard for `maintenance.auto=false`) was addressed by D4's pack-count test (`test/scripts/build-loop-merge.bats:104-108`). The second `state_gate` in W is a deliberate early gate. It costs about 11 ms on a cold path, which is below the Informational bar, so it is not filed here.

## Endorsements

- The rebase/bisect scan forks nothing for an absent probe file: `[[ ! -e "$d/$q" ]] ||` short-circuits before `[[ -r ]]` and `grep` run, so its cost per git dir is 4 `stat`s, not 4 forks [read: scripts/build-loop.sh:1059-1068].
- Within one `--merge` process, main's tree is re-hashed exactly once. `gate_start` runs once in the merge arm, and neither `land` nor `merge_ident` calls `store_check` [read: scripts/build-loop.sh:910-917, 1015-1022, 1043-1112, 1134-1146].
- The early W gate runs before `git status` in W. A refused W therefore never pays for the `status` walk or the added-path prefix walk. The extra cost on an accepted landing is one `state_gate` (measured 10.5–11.4 ms) [read: scripts/build-loop.sh:1069-1094, 341-363].
- D4's pack-count assertion fails when `-c maintenance.auto=false` is removed from the ff-merge in W, so the iteration-1 F1 fix is pinned by the suite. The source is commit 6cbca87c's "Each new guard's mutant fails the suite (… maintenance …)". I did not re-run it [unverified — submitted as claim].

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| — | No findings | — | — | — |

## Overall Assessment

For a once-per-landing command, the branch's performance is sound and leaves nothing to address. Everything in `land` scales at most linearly: with worktree count (the scan and `worktree list`) and with added paths (the builtin prefix walk). All of it is small next to the single `store_check --main` pass. The final fix batch adds about 11 ms per W landing for the early state gate, and nothing elsewhere. Every earlier performance finding is resolved, and the last of them now has a regression test. The amber inventory from the performance angle is empty. No profiling is needed. The plan's two passes per landing (the loop's advisory `--check`, then `--merge`) are still the only per-landing store cost above 0.25 s, and that cost comes from the flow, not from this diff (iteration 1).

## Goal-Alignment Note
- Success criterion (restated verbatim): "A markdown report saved to /workspace/.claude/wt-build-loop-u3a2/docs/reviews/performance-review-2026-10-10-u3a2-final.md, structured per the performance-reviewer skill."
- Answered: the cost of every change in 6cbca87c (the early W `state_gate`, measured at about 11 ms; the scan's new `-e`/`-r`/`grep` form, which forks nothing when files are absent; the authority argument; the D4 test), whether row 639's trigger is still unmet per process (it is), and whether the earlier performance findings are closed (all three are).
- Out of scope: the Stage 1 Incorrect verdicts (an unsearchable `.git/worktrees` or admin dir hides W from `worktree list`; directory-shaped or unsearchable rebase/bisect state reads as absent; the empty-email identity). These are correctness and security failures with no performance angle.
- Escalate: none from performance. The Stage 1 Incorrect verdicts belong to the security critic and the rubric, not to this report.
