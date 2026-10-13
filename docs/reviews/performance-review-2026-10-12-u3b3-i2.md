Commit: 5d175c0e

# Performance Review — feat/build-loop-u3b3 (U3b3, iteration 2 of 3)

**Scope:** `git diff main...5d175c0e` (full branch; docs/reviews/ excluded): scripts/lib/dev-cycle-read.sh (git_harden), scripts/build-loop.sh, scripts/dev-cycle.sh, test/lib/d6-snippet.bash, test/scripts/build-loop-orchestrator.bats, test/scripts/build-loop-check.bats, docs/working/plan-build-loop-handoff.md
**Date:** 2026-10-12
**Based on:** docs/reviews/code-fact-check-report-2026-10-12-u3b3-i2.md (Claim 53 timing, P5; Mostly Accurate claims 7, 26, 30c, 33, 43; two security escalations, not performance)
**Agent tag:** perf2

## Data Flow and Hot Paths

The diff changes two things on the orchestrator's path.

1. **git_harden.** It moves from build-loop.sh into the lib. It runs once per script process: a loop over 8 HARDEN pairs plus one `export`, with no forks. dev-cycle.sh now calls it too, so the digest's and check modes' git calls also run with `core.commitGraph=false` and `core.multiPackIndex=false`. Before this branch, dev-cycle.sh used the repository's commit-graph.
2. **The D6 snippet (test/lib/d6-snippet.bash).** It runs in front of every gate and digest call: several per iteration, per the dispatch context. That makes it a warm path, not a per-item hot loop. Every call does the following:
   - ref checks (for-each-ref, rev-parse, 2× show-ref, symbolic-ref, rev-parse, cat-file -t);
   - the root check: one full first-parent `rev-list` walk with the commit-graph off;
   - the re-hash: a second full first-parent `rev-list`, a `rev-parse` and one `cat-file --batch`, SHA-1'd in a perl process;
   - 4× (ls-tree + cat-file blob) and 4× hash-object, a `mktemp -d`, then the script.

Two sizes drive the cost: main's first-parent history length and the per-call fork count. Neither depends on the number of worktrees or on the size of the working tree, because the snippet reads only objects.

**Measured context** (probes `/tmp/u3b3-perf2-XXXX`, a `git clone --shared` of /workspace with nothing written to /workspace; 2026-10-12; 16 cores, load average 6.3–8.2 from other sessions):
- main 27cedb99. First-parent commits: **1,122** (2,517 in all). Worktrees on /workspace: **13**. Pack size 425 MiB.
- main's recent growth: 554 first-parent commits over its last 40 active days, so about 14 per active day.

| Stage (5 runs, ms) | Measured |
|---|---|
| Re-hash pipeline (rev-list + rev-parse + cat-file --batch + perl) | 22, 22, 26, 22, 22 |
| Root check `rev-list --first-parent --max-parents=0`, commit-graph off (as the snippet runs it) | 13, 13, 15, 12, 13 |
| The same with the repository's commit-graph on | 3, 3, 3, 3, 4 |
| Whole snippet + main's `build-loop.sh --help` vs a direct run of the checkout's copy | 88/17, 84/18, 99/20, 92/17, 81/17 |
| Whole snippet + `build-loop.sh --settings` vs direct | 113/43, 111/53, 116/46, 124/44, 110/42 |
| git processes in one snippet + `--help` run | 23 |
| dev-cycle.sh digest (`--since=2026-09-01`): branch (hardened) / branch with `core.commitgraph=true` as a caller pair / main's (unhardened) | 706/687/709, 779/783/695,773/738/695 |

The fact-check's P5 measured the re-hash at 36 ms over 1,125 objects. That agrees with these numbers.

## Findings

#### 1. Two full first-parent history walks per snippet call, both with the commit-graph off

**Severity:** Low
**Location:** `test/lib/d6-snippet.bash:48` (root check), `test/lib/d6-snippet.bash:53-55` (re-hash)
**Move:** Count the hidden multiplications / asymptotic behaviour
**Classification:** Macro (O(first-parent history) per call, growing about 14 commits per active day) / Warm path (once per gate or digest call, several per iteration; not a per-item loop)
**Confidence:** High
**Baseline:** about 35 ms per call (root check 13 ms + re-hash 22 ms) at 1,122 first-parent commits, measured by perf2's probe on 2026-10-12 against a shared clone of /workspace (load average about 7)
**Legibility-target:** for-orchestrator-synthesis

**Evidence:**
- `if [[ "$(g rev-list --first-parent --max-parents=0 "$sha")" == "$D6_ROOT" ]]; then` (`:48`)
- `{ g rev-list --first-parent "$sha" && g rev-parse "$sha^{tree}" "$sha:scripts" "$sha:scripts/lib"; } | g cat-file --batch \` (`:53`, continuing through `:55`'s `|| no ...`)

**The cost.** Both walks traverse main's whole first-parent chain. `g` passes `-c core.commitGraph=false`, so neither walk can use the repository's commit-graph. The root check alone took 13 ms without the graph and 3 ms with it. The re-hash must read and hash every commit (that is its purpose, i1 A1), so its cost is inherent. The root check's walk duplicates the re-hash's: the root is the last line the re-hash's own `rev-list --first-parent` prints.

**Growth.** Cost is linear in history: about 31 µs per first-parent commit across both walks. At the recent growth rate this adds roughly 0.15 s per call per year. That is small next to a gate run (`--settings` alone runs 43 ms direct, and a digest 700 ms) and nowhere near a cliff.

**Constraint on a fix.** The order matters for security. The root check selects which branch runs, and the re-hash runs only in the claude-workflows branch. Folding the two walks into one is possible only if the re-hash's commit list is computed first and its last line is used as the root. That also changes which path a failed walk takes: the fact-check's escalation (1) is that a failed root-check rev-list today selects /opt instead of refusing.

**Recommendation:** No change needed for this unit. If the security reviewer's answer to fact-check escalation (1) makes the root check refuse on a failed walk, consider running `rev-list --first-parent` once into a variable and using it for both the root comparison and the re-hash input. That removes one walk (about 13 ms today) and the fail-open in the same edit. Leave `core.commitGraph=false` as it is: a forged graph is the reason it is off.

#### 2. Fixed per-call overhead of about 70 ms, mostly process forks (23 git processes plus perl and mktemp)

**Severity:** Informational
**Location:** `test/lib/d6-snippet.bash:56-68` (temp dir, the per-file ls-tree / cat-file blob loop, the per-file hash-object loop)
**Move:** Count the hidden multiplications (per-call fork count)
**Classification:** Micro (a constant number of forks, independent of data size) / Warm path (several calls per iteration)
**Confidence:** High
**Baseline:** snippet + `build-loop.sh --help` 81–99 ms vs 17–20 ms direct (overhead about 70 ms); snippet + `--settings` 110–124 ms vs 42–53 ms direct; 23 git processes counted by a PATH shim, measured by perf2's probe on 2026-10-12
**Legibility-target:** for-orchestrator-synthesis

**Evidence:**
- `x="$(g ls-tree --format='%(objectmode) %(objecttype) %(objectname)' "$sha" -- "scripts/$f")" || no "scripts/$f could not be listed"` (`:61`, inside the `for f in "${F[@]}"` loop that ends at `:65`)
- `g cat-file blob "${BASH_REMATCH[2]}" > "$d/scripts/$f" || no "scripts/$f could not be read from $m"` (`:64`)
- `[[ "$(g hash-object --no-filters "$d/scripts/${F[i]}")" == "${ids[i]}" ]] || no ...` (`:67`, inside the `for i in "${!F[@]}"` loop that ends at `:68`)

**Where the time goes.** About 35 ms is Finding 1's walks. The rest is roughly 21 more git forks:
- the 7 ref checks;
- 4 ls-tree, 4 cat-file blob and 4 hash-object calls;
- the rev-parse.

**Per iteration.** At "several calls per iteration" the total is a few hundred ms per iteration. An iteration's gate and digest calls already take tens of ms to about 0.7 s each, and an iteration's agent work takes minutes. The overhead is not material.

**What batching would save.** The 12 per-file forks could become 2 (one `ls-tree` over all four paths, one `cat-file --batch` for the four blobs). That saves perhaps 15–20 ms per call, at the price of more parsing in a snippet that U4 pastes byte for byte and that reviewers must read as security code.

**Recommendation:** Keep it as written. The per-file form is easier to audit, and the saving is under 20 ms per call. Revisit only if a measured iteration shows snippet time is a visible share of wall time.

## Endorsements

- dev-cycle.sh now runs with `core.commitGraph=false` and `core.multiPackIndex=false` through git_harden. The claim: this costs the digest no measurable time at this repository's size. Three paired runs gave 706/779/773 ms hardened and 687/783/738 ms with the graph re-enabled by a caller pair, a spread inside the run-to-run noise of 685–783 ms. The probe was perf2's, at 1,122 first-parent commits with 13 worktrees. `[unverified — submitted as claim]`
- git_harden itself adds no forks: a bash loop over 8 pairs and one `export`, run once per process after scrub_reexec (`scripts/lib/dev-cycle-read.sh:348-359`; called at `scripts/build-loop.sh:496` and `scripts/dev-cycle.sh:128`). `[read: scripts/lib/dev-cycle-read.sh:348-359]`
- The re-hash's perl loop reads one object at a time into `$b` and keeps only a counter, so its memory is bounded by the largest object, not by history length (`read(STDIN, $b, $s)` per header, `test/lib/d6-snippet.bash:54`). `[read: test/lib/d6-snippet.bash:53-55]`
- The snippet's temp dir is removed on every exit path through the EXIT trap. Both probes left `$TMPDIR` empty after 10+ runs each, and so did the fact-check's test 11. `[fact-check: claim 35 — Verified]`

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Two full first-parent walks per call, commit-graph off; root check duplicates the re-hash's walk (35 ms at 1,122 commits, linear in history) | Low | `test/lib/d6-snippet.bash:48,53-55` | High |
| 2 | Fixed overhead of about 70 ms per call from 23 git forks; the per-file loops could batch | Informational | `test/lib/d6-snippet.bash:56-68` | High |

## Re-flagged settled decisions

None. No override row keyed to this unit (200, 281, 311, 495, 505, 644, 648, 666, 702, 704, 709), and neither related row (509, 548), settles a performance question these findings touch. Finding 1's recommendation touches fact-check escalation (1), which is not settled. It is cited, not re-flagged.

## Overall Assessment

This change performs fine.

- **Costs.** The new per-call cost is the D6 snippet: about 70 ms fixed plus about 31 µs per first-parent commit. That is roughly 35 ms of history walking today, and it grows by roughly 0.15 s per call per year at the current commit rate. Moving git_harden into the lib, and with it switching off the commit-graph for dev-cycle.sh, showed no measurable change to the digest.
- **Linear cost.** The only cost that grows with data is the history walk, and that is the price of i1 A1's fix. Removing the duplicate root-check walk would trim it by about a third, and is worth doing only if the root check is rewritten for escalation (1) anyway.
- **Not measured.** Cold-cache runs, other hosts, and a full gate `--check` through the snippet. Re-measure the snippet's share of iteration wall time once U4 wires it into SKILL.md.

## Goal-Alignment Note

- Success criterion (restated verbatim): A markdown report saved to /workspace/.claude/wt-build-loop-u3b3/docs/reviews/performance-review-2026-10-12-u3b3-i2.md, structured per the performance-reviewer skill.
- Answered: yes. The full branch diff was reviewed, and each finding carries a measured baseline taken in perf2's own `/tmp/u3b3-perf2-XXXX` dirs. Every probe ran against a shared clone, and the dirs were removed afterwards. The worktree count (13) and history length (1,122 first-parent commits) are recorded with the timings.
- Out of scope: the security judgement in fact-check escalations (1) and (2) (security-reviewer). Running the bats suites was not needed for timing.
- Decisions I made: I classed the snippet as a warm path (several calls per iteration), not hot, which caps Finding 1 at Low. I measured the digest with `--since=2026-09-01` as a representative window.
