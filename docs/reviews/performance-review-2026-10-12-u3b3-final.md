Commit: 5583a2cd

# Performance Review — feat/build-loop-u3b3 (U3b3, iteration 3 of 3, final)

**Scope:** `git diff main...5583a2cd` (full branch; docs/reviews/ excluded from the saved diff): test/lib/d6-snippet.bash (the verified reader), scripts/lib/dev-cycle-read.sh (git_harden), scripts/build-loop.sh, scripts/dev-cycle.sh, the two bats files, the plan note
**Date:** 2026-10-12
**Based on:** docs/reviews/code-fact-check-report-2026-10-12-u3b3-final-r{1,2,3}.md (no behavioural Incorrect; row 734's "~70 ms fixed" Mostly Accurate, measured 80-100 ms with part of it the history walk); rubric B11, B16
**Agent tag:** perf4

## Data Flow and Hot Paths

Since i2, the snippet decides what to run with one perl process, the **verified reader** (`test/lib/d6-snippet.bash:58-71`). That process talks to one `git cat-file --batch` in request/response mode. `obj()` writes one id and then blocks until the reply is read (`:60-62`). The next id is the `parent` line of the bytes just checked (`:65-66`), so the requests cannot be pipelined. Each call to the snippet walks main's whole first-parent chain this way, one round trip per commit.

- **In claude-workflows,** the walk is followed by 6 tree reads and 4 blob reads. The scripts tree is read four times, once per `entry()` call (`:68-70`); that is a negligible cost.
- **In any other repository,** the reader also walks the full chain on every call. It answers `other` only after reaching that repository's root (`:65-67`), and only then does the snippet take the /opt copy.

The i2 code this replaced (5d175c0e) did the same work in two pieces. It ran a native `rev-list --first-parent --max-parents=0` for the root, then, in claude-workflows only, a pipelined `rev-list | cat-file --batch | perl` re-hash.

How often it runs: before every gate and digest call, which is several times per orchestrator iteration. I class that as a warm path, not a per-item loop.

**Measured context** (probes `/tmp/u3b3-perf4-XXXX`; a `git clone --shared --single-branch` of /workspace plus synthetic fast-import repos; nothing written to /workspace or the worktree; 2026-10-12; 16 cores; load average 1.3-1.9; 10 runs each unless stated):

- **This repository:** /workspace main 27cedb99, with **1,122** first-parent commits (2,517 in all). **13** worktrees on /workspace. /opt/claude-workflows is root-owned 555.

| claude-workflows clone (1,122 first-parent) | ms |
|---|---|
| New snippet + `build-loop.sh --help` | 86-91 (median 89) |
| i2 snippet (5d175c0e) + `--help` | 65-71 (median 66) |
| Direct `--help` | 13-15 |
| New verified reader alone | 60-67 (median 63) |
| i2 re-hash pipeline alone | 19-21 |
| i2 root check (native rev-list) | 9-11 |
| Streamed alternative (see Finding 1), 5 runs | 19-20 |

| Non-claude-workflows repo, first-parent chain of N (falls to /opt) | new snippet + `--help` | i2 snippet + `--help` | new reader alone | native rev-list root check |
|---|---|---|---|---|
| N = 1,000 | 73-119 (median ~76) | 29-33 | 41-49 | 3-4 |
| N = 10,000 | 356-385 | 49-52 | 335-389 | 22-27 |
| N = 100,000 | 3,368-4,817 | 246-282 | 3,270-4,228 | 233-278 |
| N = 300,000 | 10,164-12,381 | 787-862 | 9,934-10,423 | 711-793 |
| Streamed alternative, N = 300,000 (5 runs) | — | — | 1,208-1,235 | — |

- **Per-commit cost:** about 33-35 µs for the reader, against about 2.5 µs for the native walk it replaced in non-claude-workflows repos.
- **Reader memory:** the reader's peak RSS (VmHWM, read in an END block) was 7.2-7.7 MB at every N from 1,000 to 300,000, and in the claude-workflows clone. Memory per object is bounded by the largest object read; it does not grow with history.
- **Not measured:** my sampling of `cat-file --batch`'s RSS broke the protocol in 3 of 4 runs (a backgrounded child gets /dev/null on stdin), so its RSS was not measured. Those runs are discarded.

## Findings

#### 1. The verified reader walks main's first-parent history one blocking round trip per commit: about 13x the per-commit cost of the walk it replaced, paid on every call, in every repository

**Severity:** Low
**Location:** `test/lib/d6-snippet.bash:60-62` (`obj`), `:65-67` (the walk), `:78` (one run per snippet call)
**Move:** Count the hidden multiplications; check the asymptotic behaviour (constant per object, linear in history)
**Classification:** Macro (O(first-parent history) per call, with a per-commit constant raised about 13x) / Warm path (several calls per iteration, not per item)
**Confidence:** High (measured; mechanism read in full)
**Baseline:** verified reader 63 ms (median of 10) vs 30 ms for the i2 walks it replaced (re-hash pipeline 20 + root check 10), at 1,122 first-parent commits with 13 worktrees, measured by perf4's probe 2026-10-12
**Legibility-target:** for-orchestrator-synthesis

**Evidence:**
- `sub obj { my ($id, $want) = @_; print $w "$id\n"; my $h = <$r>; die "no answer for $id\n" unless defined $h; ...` (`:60`; the unit continues through `:62`'s `return $b }`)
- `my $tree; while (1) { my ($hd) = split /\n\n/, obj($c, "commit"), 2; $tree //= ...;` / `my ($p) = $hd =~ /^parent ([0-9a-f]{40})$/m; last unless defined $p; $c = $p }` (`:65-66`)
- `if ($c ne $root) { print "other\n"; exit 0 }` (`:67`)

**The cost.** Each commit costs one write, a wait for cat-file to look the object up and flush, and a read. Nothing overlaps, because the next id is known only after the reply has been hashed. That is the security property B1's fix needed.

- **In this repository:** the snippet's overhead over a direct run rose from about 52 ms (i2: 66 − 14) to about 75 ms (89 − 14). B11's "one walk" fix removed one walk but made the remaining one slower than the two together (63 ms vs 30 ms).
- **Elsewhere:** in a repository other than claude-workflows, the reader replaced a 2.5 µs-per-commit native `rev-list` with a 33-35 µs round trip per commit. For a repository's first call that only ends in "use /opt", that is:
  - 1,000 commits: 3 → 44 ms
  - 10,000 commits: 23 → 355 ms
  - 100,000 commits: 0.24 → 3.4 s
  - 300,000 commits: 0.75 → 10.2 s

  The cost is paid on every call, several per iteration. There is no ceiling and no cache. A large monorepo (10^5 first-parent commits) would pay 10-20 s per iteration in the snippet alone.

**Why Low.**
- At this repository's size the extra 23 ms per call is immaterial next to a 0.7 s digest and minutes of agent work.
- The user's other projects are probably far below 10^4 first-parent commits (assumption; verify data size per project U4 targets).
- Escalate to Medium if U4 runs the orchestrator on a repository past roughly 30,000 first-parent commits, where a call reaches about 1 s.

**A fix that keeps the security property (probed, not a patch).** The reader can stream instead of ping-pong, and still take no id from unchecked bytes:
- Feed it `rev-list --first-parent MAIN | cat-file --batch`, and accept each streamed object only if its id equals the `parent` line of the commit just hashed (the first one: main's id). Die on any mismatch, extra object or early end.
- rev-list then only proposes ids; every id used is still one the checked bytes named, and a lying rev-list makes the snippet refuse (B2's direction), never run something else.
- Measured: 19-20 ms at 1,122 commits (vs 63) and 1.21-1.24 s at 300,000 (vs 10.2 s). The trees and blobs after the walk can stay request/response.

The security reviewer should confirm the linkage rule is equivalent to B1's "every next id from checked bytes" before anyone adopts it. The fact-check's r1 escalation on `:67` (`$c ne $root`) is security's, and this change would not alter it.

**Recommendation:** Accept the current reader for U3b3 (cost immaterial at 1,122 commits). Add a revisit trigger, for U4 or the first non-claude-workflows target repository, so the history size is checked against the ~1 s line. If the trigger fires, switch the commit walk to the streamed-and-linked form above, subject to security sign-off.

## Endorsements

- The verified reader's memory is constant in history length: peak RSS 7.2-7.7 MB from 1,000 to 300,000 first-parent commits. `obj` returns one object's bytes and the walk keeps only `$c`, `$tree` and the current header (`test/lib/d6-snippet.bash:60-66`). `[unverified — submitted as claim]`
- The snippet's temp dir is removed on every run: the probe's private TMPDIR held 0 leftover dirs after 80+ snippet runs that took both the `main` and the `other` path. `[unverified — submitted as claim]`
- git_harden adds no forks: it is a bash loop over 8 HARDEN pairs and one `export`, and it returns at once on a second call (`scripts/lib/dev-cycle-read.sh`, `git_harden`). `[unverified — submitted as claim]`
- The digest's switch to `core.commitGraph=false` costs no measurable time at this size: perf2 measured 706/779/773 ms hardened vs 687/783/738 ms with the graph on. This pass did not re-measure. `[unverified — submitted as claim]`

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Verified reader walks first-parent history one blocking round trip per commit: 63 ms vs 30 ms at 1,122 commits; in other repos 13x the native walk it replaced (10.2 s vs 0.75 s at 300k), every call; a streamed-and-linked walk measures 20 ms / 1.2 s | Low | `test/lib/d6-snippet.bash:60-67,78` | High |

## Re-flagged settled decisions

- **Row 734 (B16, Won't-Fix: "~70 ms of fixed fork overhead").** This is not a new finding; the ruling stands. Two of the row's premises measure differently on this pass:
  - Its reason, "the verified reader already cut the history walks from two to one", is true as a count. In time, one walk now costs 63 ms where the two i2 walks cost 30 ms.
  - Its "fixed" overhead is about 75 ms here, and part of it is linear in history, which is Finding 1's subject.
- **B11 (rubric: "Fixed (one walk)").** Fixed as stated (one walk), but the time went up, not down. This is context for Finding 1; nothing is re-opened.

## Overall Assessment

This change performs adequately for this repository.

- **What it costs.** The D6 snippet now costs about 89 ms per call against about 66 ms in i2 and 14 ms direct. That is immaterial next to the gate, the digest and the agent work.
- **The one structural cost.** The verified reader walks history by blocking round trip. That multiplies the per-commit cost about 13x in every repository, including those that only end up running /opt. It is linear and has no ceiling.
- **The fix, if it is ever needed.** It is a contained change to the walk loop (streamed ids accepted only when they match the checked parent line). It measured about 8x faster at 300,000 commits. It needs a security reviewer's sign-off before use.
- **Memory** is flat at about 7.5 MB.
- **Not measured.** cat-file's RSS, cold-cache runs, and a full gate `--check` through the snippet. Re-measure the snippet's share of iteration wall time when U4 wires it in.

## Goal-Alignment Note

- Success criterion (restated verbatim): A markdown report saved to /workspace/.claude/wt-build-loop-u3b3/docs/reviews/performance-review-2026-10-12-u3b3-final.md, structured per the performance-reviewer skill.
- Answered: yes. I reviewed the full diff `main...5583a2cd`. The focus items were the verified reader's round trip per object, the full history walk in non-claude-workflows repos, and memory per object. Each is measured against the i2 code it replaced (5d175c0e), and history length (1,122 first-parent commits; synthetic 10^3 to 3×10^5) and worktree count (13) are recorded with the timings. Probes ran only in `/tmp/u3b3-perf4-XXXX` dirs, which were removed afterwards (one dir leaked by a failed first run was removed by hand). No file but this report was written.
- Out of scope: the security judgement on fact-check r1's `:67` escalation, and whether the streamed-and-linked walk preserves B1's property (security-reviewer). Bats suites were not run.
- Decisions I made: I kept the warm-path class from i2, which caps Finding 1 at Low, with an explicit escalation line at about 30,000 first-parent commits. I used synthetic linear-history repos for scaling, which have small commits; real commits are larger but the round trip dominates.
