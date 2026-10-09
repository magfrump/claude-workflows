Commit: e02d056b

# Performance Review — feat/build-loop-u2b1b (U2b1b, final confirming pass, full branch)

**Scope:** `git diff main...HEAD` (0e4596ce...e02d056b; commits cc9b69d3, 809df345, a382a3f8, e02d056b): `scripts/build-loop.sh` (default_gate, gate_git, merge_result, own_blob, nrules, check_line), `scripts/lib/dev-cycle-read.sh` (comment only)
**Date:** 2026-10-08
**Based on:** Stage 1 fact-check summary, final pass (k=3, e02d056b; replicates `docs/reviews/code-fact-check-report-build-loop-u2b1b-final-r{1,2,3}.md`, no behavioral Incorrect); prior prices in `docs/reviews/override-log.md:511` (merge-base --all by history depth) and `:520` (truthrule per path, missing-blob batch-check, linear per path); iterations 1-2 performance reviews

All timings are mine, on this host (WSL2, 16 cores, git 2.39.5, load average 0.3-0.5), probes in `/tmp/claude-1000/-workspace/0c855a7c-1c04-4bab-8bf1-7620be67b78e/scratchpad/u2b1b-i3/perf/`: `probeB.sh B R` (B briefs, each branch adds one file and flips its Status open→done; `--check` over all B, main's script `git archive main scripts` and e02d056b's interleaved, R runs), `probeB-noflip.sh` (same, Status unchanged, so `own_blob` never runs), `lowerm.sh` (the lib's `lower` called 1,000 times). I also re-ran iteration 2's `u2b1b-i2/perf/probe1.sh 5000` against e02d056b's script (its temp dir was created and removed by the probe; nothing else there was touched).

## Data Flow and Hot Paths

`--check BRIEF...` is one CLI run per merge attempt (cold, advisory until U3; in U3 it sits between `--expect`'s read and `--merge`'s CAS). Per run, U2b1b adds `default_gate` once (`scripts/build-loop.sh:241-251`, called `:260`: two `show-ref --verify` and one `symbolic-ref`). Per brief it adds, after U2b1a2's `status_line` and `check_branch` reads: `merge-base --all` (`:522`), one `cat-file -e` per tree for main, the tip and each base (`:525`), the existing `merge-tree` now through `gate_git` (`:526`), one `diff-tree -z` to `$GATE_TMP/diff` (`:599`), the parse loop (`:602-607`), one `tr | wc` NUL count (`:609`), one `cat-file --batch-check` over new regular files (`:615-616`), one `nul_list lower_all` (`:620`), and, only when the brief's own path is among the changes, `own_blob` (`:536-543`: two `cat-file blob`, `awk`, `perl`, `hash-object`). Per path: the parse loop and `nrules` (`:553-572`, with `truthrule` at `:565`). Every `gate_git` call (`:510-515`) is a subshell fork plus `env` and `git` execs.

e02d056b changes only comments, help text and one refusal string in the code (`git diff a382a3f8 e02d056b -- scripts/`), so iteration 2's per-path prices stand. Re-measured at 5,000 changed paths: 1,304 / 1,378 / 1,338 ms, merged tree `fbbe1faa…` as before (iteration 2: 1,326 / 1,346 / 1,369 ms; row 520's ≈0.25 ms per path holds).

What no row prices yet is the **per-brief fixed cost** the branch adds against main (`probeB.sh`, wall ms):

| fixture | main (0e4596ce) | e02d056b | added per brief |
|---|---|---|---|
| B=1, Status flips (5 runs) | 78-82 | 99-103 | ≈21 ms |
| B=10, Status flips (3 runs) | 485-498 | 676-723 | ≈20 ms |
| B=10, Status unchanged (3 runs) | 480-508 | 629-639 | ≈14 ms |

Main's own per-brief cost is ≈45 ms ((491 − 80) / 9). So U2b1b adds ≈14 ms per brief for the merge-base, tree-existence, diff-tree, batch-check and lower passes, and ≈6 ms more when the brief's Status line changes (`own_blob`; iteration 1 F3 called it below noise for one brief, and that holds: it shows up only summed over ten). That is about +45% per brief, linear in B.

The comment at `:619` ("a tr per path cost 1 to 2.5 ms each") is consistent with measurement. `lower` called 1,000 times in a bare script takes 870-894 ms, so ≈0.9 ms per call. Iteration 1 measured 2.2-2.6 ms per path inside the full script, where every fork copies a larger process.

## Findings

#### F1. U2b1b adds ≈14-20 ms of fixed process work per brief (≈+45% over main's per-brief cost); no row prices it

**Severity:** Informational
**Location:** `scripts/build-loop.sh:522-526` (merge_result), `:599`, `:609`, `:615-616`, `:620` (check_line), `:540-542` (own_blob, via `:559`)
**Move:** 1, Count the hidden multiplications (per-brief process count × briefs per run)
**Classification:** Micro (fixed fork/exec cost per brief, ≈7 process groups plus 5 in own_blob) / Cold path (one CLI run per merge attempt; B is the briefs named, single digits in practice)
**Confidence:** High (measured, interleaved runs; the attribution among the individual processes is inferred, not phase-timed)
**Baseline:** `--check` over 10 briefs: 491 ms mean on main's script, 696 ms mean on e02d056b's (Status flips), 635 ms (Status unchanged), measured 2026-10-08 with `perf/probeB.sh` and `perf/probeB-noflip.sh`
**Legibility-target:** override log (a per-brief price beside row 520's per-path price)

Evidence (verbatim):

```
  bases="$(gate_git merge-base --all "$MAIN_SHA" "$1")" || rc=$?
  [[ "$rc" -le 1 ]] || return 2
  # shellcheck disable=SC2086  # one commit id per word
  for b in "$MAIN_SHA" "$1" $bases; do gate_git cat-file -e "$b^{tree}" || return 2; done
  rc=0; out="$(gate_git merge-tree --write-tree --no-messages "$MAIN_SHA" "$1")" || rc=$?
```
```
  (cd "$GATE_TMP/work" && "${GATE_ENV[@]}" git "$@") 2>"$GATE_TMP/err" || rc=$?
```

The first excerpt (`:522-526`) ends inside `merge_result`, which continues to `:530` (the tree-id check and `echo`). Its output, `tree`, is first used at `:599`. The second excerpt is `gate_git`'s body (`:512`; the function runs `:510-515`). Each `gate_git` call costs a subshell, an `env` exec and a `git` exec. The tree-existence loop runs 2 + (number of merge bases) of them, so a criss-cross history adds about 2 ms per extra base (inferred from the ≈14 ms over ≈7 process groups). That is still bounded by the history and nowhere near the merge-base walk itself (row 511). None of this scales with the changed paths. It is the R6 and A16 fixes plus the N rules' setup, each needed for correctness. At the realistic B (1 to 9 briefs, `Build-loop slots:` caps at 9), it costs at most ≈0.2 s per run.

**Recommendation:** no code change. Add ≈14 ms per brief (≈20 ms when the brief's Status flips) to row 520's price line, so U3's CAS-window budget has a per-brief term next to the 0.25 ms per path term.

## Endorsements

- e02d056b changes no executed code: its `scripts/` diff touches only comments, help text and one refusal message, so iteration 2's measured per-path prices carry to this commit. [read: `git diff a382a3f8 e02d056b -- scripts/`; scripts/build-loop.sh:559-570, :611-620]
- `own_blob` runs at most once per brief. Its only call is in `nrules`' `[[ "$6" == "$1" ]]` branch, and the `&&` chain skips it unless the status is M with modes kept. [read: scripts/build-loop.sh:558-560, :536-543]
- Claim: `--check` at 5,000 changed paths takes 1,304-1,378 ms on e02d056b, unchanged from a382a3f8 (1,326-1,369 ms), with the same merged tree. [unverified — submitted as claim]
- Claim: the branch's fixed cost per brief is ≈14 ms without the Status flip and ≈20 ms with it, measured against main's script at B=1 and B=10. [unverified — submitted as claim]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | ≈14-20 ms fixed process work added per brief (≈+45%); not in any price row | Informational | `scripts/build-loop.sh:522-526` | High |

## Overall Assessment

The branch's performance posture is settled. The one Low from iteration 1 (the per-path `tr` fork) is fixed. Per-path cost is linear at ≈0.25 ms and unchanged at e02d056b, which changes no executed code. The merge-base walk, `truthrule` and the batch-check are priced in rows 511 and 520. The only unpriced term is the fixed cost per brief: ≈14 ms of extra git processes, plus ≈6 ms when the brief's Status flips. It is linear in the number of briefs (at most 9) and buys the R6, A16 and N-rule checks. It is a price line for the override log, not a red or an amber. No profiling is needed before merge. U3 should check the summed budget (fixed cost per brief + 0.25 ms × paths + merge-base by depth) against main's commit rate when it sizes the CAS window.

## Goal-Alignment Note

The user's goal is to land U2b1b after a clean review-fix loop, and this terminal pass decides the merge from the full amber inventory. From the performance side the inventory is empty. There is no red and no amber. One Informational finding (F1) gives the per-brief fixed cost no row records yet, measured against main's script. The prices already recorded (row 511: merge-base by depth; row 520: truthrule, batch-check, ≈0.25 ms per path) were re-checked at e02d056b and hold. No Won't-Fix row is re-flagged, and nothing here blocks the merge. R8 and the A15 test gap are security and test questions with no performance side, so this pass leaves them alone.
