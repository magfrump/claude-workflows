Commit: b00c057 (A) / 7f3e392 (B)

# Performance Review — dev-cycle pass 27 (pass-26 fix round, k=1 delta)

**Scope:** Partial. A: `git diff 10c2809..b00c057 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` in `/workspace/.claude/wt-digest`. B: `git diff 875b41f..7f3e392 -- skills/dev-cycle/SKILL.md` in `/workspace/.claude/wt-devcycle`, merged as c7a29b3 (its first parent is 7f3e392, and `git diff 7f3e392 c7a29b3 -- skills/dev-cycle/SKILL.md` is empty). The focus, per the brief, is `--check-brief` now that it reads whole blobs and runs `git log -1 -G'^Status: '`, plus reruns of pass 26's large-brief, answer and fence probes. Everything else is context only.
**Date:** 2026-10-02
**Based on:** Stage-1 context `docs/reviews/code-fact-check-report-digest-pass26.md` (verdicts on 10c2809 / 875b41f), `performance-review-2026-10-02-digest-pass26.md` and its probes in `scratchpad/perf26/`.

> ⚠️ **No code fact-check report covers b00c057 / 7f3e392.** The comments, help text and commit claims added this round have not been checked by a fact-check stage. Every number below comes from my own runs, and the runtime endorsements are submitted as claims.

**Measurements.** All measurements are mine, taken 2026-10-02 in this sandbox (git 2.39.5, mawk). "new" is `git show b00c057:scripts/dev-cycle.sh` and "old" is `10c2809:…`; both ran in the same loop. Scratch lives in `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/perf27/` (written `perf27/` below). Each probe is one `set -eu` script that creates its own `mktemp -d -p perf27` dir in that same script and checks `case "$PWD"` before any `git init`, commit, write or `rm`. Every process ran under `timeout`, and none is still running (`pgrep` is empty). Nothing was written to either worktree except this file. `/workspace` is still on `main`, its status is unchanged, and both worktrees show an empty `git status --short`.

- **Q1, long histories** (`perf27/q1-history.sh`, `q1.log`). `perf27/gen.py` is pass 26's generator with three more briefs: **edited** (Status set at commit 1, a `Kept:` line edited every 10th commit), **bigedit** (80 KiB, Status set at commit 1, edited every 100th commit) and **nostatus** (no Status line at all). Runs cover 10k and 100k linear commits, without and then with a `--changed-paths` commit-graph, two runs each.
- **Q2, large briefs** (`perf27/q-p2-edges.sh`, `q2.log`). This is pass 26's P2 rerun: briefs of 1 KiB to 64 MiB with `Status: open` first, last or missing, each followed by a 1 KiB brief in the same call, three runs each. It also covers the `%cs` time zone and the no-`main` exit.
- **Q3, `--check-answer`** (`perf27/q-p3-answer.sh`, `q3.log`). This is pass 26's P3 rerun: readings over every real ID, the header shapes, cost against the 1×/10×/100× archives and a 17.5 MB all-fenced archive.
- **Q4, fences** (`perf27/q4-fence.sh`, `q4.log`). This reruns pass 26's perf P4, fact-check P1 (Q-1/Q-7/Q-8) and P6, security F1, F3 (tilde brief) and F5 (forged entry, no real Q-017). It adds a `~~~` block that quotes a ```` ``` ```` line in an answer, and a count of real entries with an unclosed same-kind fence.
- **Q5, semantics** (`perf27/q5-semantics.sh`, `q5.log`). This checks which commit `--check-brief` prints after a Kept-only edit, a fenced-example edit, a rename, a `--no-ff` merge, a conflict-resolving merge, a squash and a line-ending-only edit. It also runs the six check modes in an unborn repo and on a detached HEAD with no default branch.
- **Q6, tests** (`perf27/q6-bats.sh`, `q6.log`, on `git archive b00c057`). `bats test/scripts/dev-cycle.bats` gives **44/44 ok, rc 0, 10.6 s**. `python3 scripts/hermeticity-lint --root .` gives **rc 0** (126 files, 4.8 s), and `shellcheck scripts/dev-cycle.sh` is clean.

Legibility-target values: **maintainer** (someone editing the script or skill) and **agent** (the model that runs the skill and reads the check's output).

## Data Flow and Hot Paths

Every check mode is a **cold path**: one agent Bash call per mode and batch, once per cycle. N is about 3 briefs (the slot cap) plus any roadmap paths. A finding can still rise in severity for three reasons: the agent's 120 s Bash timeout, a non-zero exit (which stops the step for the whole batch, `SKILL.md:91-92`), or a cost that grows without bound.

- **`--check-brief`** (`scripts/dev-cycle.sh:256-277`). The awk at `:265-270` no longer exits. A `seen { next }` rule drains the blob after the first unfenced `Status:` line, so the reader always reads to EOF: linear in blob size, about 2.5 ms/MiB. The commit lookup at `:273` became `git log -1 --format=%H -G'^Status: ' "$MAIN_SHA" -- "$a"`, with a plain `git log -1 -- "$a"` fallback at `:274`. `-1 -- path` stops at the newest commit that touched the file. `-G` keeps walking and diffs every touching commit until one adds or removes a line matching `^Status: `. Its cost is therefore linear in the **number of edits to the brief since its status was last set**. When no Status line matches anywhere, it is a full-history walk followed by the fallback walk.
- **`--check-answer`** (`:359-385`). Heading lines now always end the entry. Fence state is tracked only inside the target entry, by kind, and an entry that ends with its fence still open reads `unrecognized`. The per-line work is the same set of string tests in a different order.
- **Mode gate** (`:424-430`). The "Could not resolve" exit is skipped for check modes. Only `--check-brief` and `--check-branch` need `MAIN_BY_NAME`. Within the check modes, `MAIN_SHA` is read only in `check_brief` (`:261,265,273-274`) and `check_branch` (`:291,295`), both of which sit behind that gate (grep of `MAIN_SHA` in b00c057).
- **B** adds no loop over unbounded input. A stale In flight line costs one more `--check-path` on `briefs/closed/<same name>`. An orphan brief gets an In flight line and then the same three checks as any other brief. The final message gains at most one `open` ID per brief, because step 3 files no new question while one is open (`SKILL.md:286-287`).

## Findings

#### 1. `-G` makes `--check-brief`'s commit lookup linear in the brief's edits since its status was set, not O(1) in recent history

**Severity:** Informational. Preconditions: a brief whose Status line was set long ago and which has been edited many times since (its `Kept:`, `Asked:` or `Applied:` lines), on a long history. Real briefs: none on `main` or `feat/dev-cycle` yet (`git log -- docs/working/briefs` is empty on both). At about one edit per cycle, a brief sees tens of edits in its life. Confidence: High (measured).
**Location:** `scripts/dev-cycle.sh:273-274` (A, b00c057)
**Evidence (verbatim):**
```bash
  c="$(git log -1 --format=%H -G'^Status: ' "$MAIN_SHA" -- "$a")"
  [[ -n "$c" ]] || c="$(git log -1 --format=%H "$MAIN_SHA" -- "$a")"
```
(This is `:273-274`. The function continues at `:275-276`, which prints `ok $a <status> $c` when `st` is set and otherwise the skip line, and it ends at `:277`. `c`'s first and only use is `:275`.)
**Move:** Count the hidden multiplications (one diff per commit that touched the file, until a Status-line change)
**Classification:** Macro (linear in edits since the status change) / Cold path (≤ about 3 calls per cycle)
**Confidence:** High
**Baseline:** Q1 (`perf27/q1.log`), 2026-10-02. Raw `git log -1 -G` on **edited**: 53 ms at 10k commits / 1,001 touches, 556 ms at 100k / 10,001 touches without a graph, and 259 ms with one. Plain `-1 --` takes 2 ms in all three cases. Through the whole call, old → new: 10k 19–22 → 63 ms, 100k 19–24 → 589–646 ms, and 100k with a graph 20–21 → 273–274 ms. A brief **old**, never edited, costs the same in both (55–57 ms at 10k; 451–540 ms at 100k without a graph, where the walk to commit 1 dominates either way).
**Legibility-target:** maintainer

This is the intended trade: the old lookup printed the latest `Kept:` edit (`ok open 29cdff5`), and the new one prints the commit that set the status (`ok open 6e1c542`, commit 1). The cost is roughly 50 µs of diff per touching commit. A brief edited 10,000 times would need 0.6 s, so no realistic brief comes near the 120 s timeout. Blob size adds a little: a 64 MiB brief whose only Status line comes last costs 347–353 ms new against 158–164 ms old (Q2), because `-G` scans the whole added text. I'm recording this so the cost model is written down. It is not a fix request.

**Recommendation:** None needed at current scale. If the cost ever matters, add `--max-count=1` with `-- "$a"` and a commit-graph (`--changed-paths` halves it, per Q1). Do not restrict the walk to `--first-parent`, which would change which commit is printed.

#### 2. A brief with no valid Status line pays a full-history `-G` walk plus the fallback walk, and then the commit is thrown away

**Severity:** Informational. Preconditions: a landed brief whose first unfenced `Status:` line is missing or malformed (the skip path), on a long history. The skip is already rare and recorded. Confidence: High (measured).
**Location:** `scripts/dev-cycle.sh:273-276` (A, b00c057)
**Evidence (verbatim):**
```bash
  c="$(git log -1 --format=%H -G'^Status: ' "$MAIN_SHA" -- "$a")"
  [[ -n "$c" ]] || c="$(git log -1 --format=%H "$MAIN_SHA" -- "$a")"
  if [[ -n "$st" ]]; then echo "ok $a ${st#Status: } $c"
  else echo "skip $a: its first Status: line is not exactly Status: open, done or dropped"; fi
```
(This is `:273-276`. `:277` closes the function. The skip branch at `:276` never reads `c`.)
**Move:** Find the work that moved to the wrong place (the lookup runs before the branch that decides whether it is needed)
**Classification:** Micro (two walks per skipped brief) / Cold path
**Confidence:** High
**Baseline:** Q1, **nostatus**, old → new: 10k 55–67 → 96–98 ms, 100k 482–489 → 942–992 ms, 100k with a graph 72–79 → 148–184 ms. The raw `-G` walk for this brief alone takes 457 ms at 100k (no graph).
**Legibility-target:** maintainer

When no line matches `^Status: `, `-G` walks the whole history, and the fallback then walks to the newest touching commit. Both were computed before 10c2809 too (one walk then), so the waste is pre-existing and this round doubled it. It stays under a second at 100k commits.

**Recommendation:** Run the two `git log` lines only when `st` is set (move them inside the `if`), so the skip path costs one `cat-file`. This is optional.

## Cross-lane observations (not graded here; for fact-check and API consistency)

- **Which commit `-G` prints** (Q5, `perf27/q5.log`). A Kept-only edit after the status is set prints the commit that set it (`a: set done`), which is correct. A `--no-ff` merge prints the side commit (`s: side sets done`), and a squash prints the squash commit. A rename `a.md → b.md` prints the rename commit, because without `-M` the new path's Status line counts as added. Two cases depart from `SKILL.md:263-265` "the last commit … that changed the brief's Status line" and from `:254-255` "the commit that set the status". (1) A later commit that adds a **fenced** `Status: open` example is printed (`a: add fenced example`), even though the status is read from the unfenced line. (2) In a merge that resolves a conflicting Status line to `done`, the merge's own diff is not inspected (`git log` shows no merge diffs by default), so the printed commit is `e: side2 sets dropped`, a commit that set a different status. A line-ending-only edit of the Status line is also printed. All of these need unusual history. Done still records the right status; only the cited commit is off. `[unverified — submitted as claim]` (my execution, Q5)
- In an unborn repo and on a detached HEAD with no default branch, the four non-brief modes run and answer (12–21 ms each): `--check-path` skip, `--check-write` skip, `--check-fix` skip or `ok`, `--check-answer keep Q-1`. `--check-brief` and `--check-branch` exit 1 with "needs a default branch". The digest itself (no check mode) still exits with "Could not resolve a default branch". In the unborn repo, `--check-path` also wrote git's `warning: could not open directory 'docs/working/briefs/'` on stderr, which is harmless. `[unverified — submitted as claim]` (my execution, Q5)

## Endorsements

- Pass 26 finding 2 is closed. With an early status line, `--check-brief` returns rc 0 with both lines at every size: 28 ms at 70 and 256 KiB, 38–41 ms at 4 MiB and 186–196 ms at 64 MiB. At 10c2809 it exited 141 with 0 lines from 4 MiB, and pass 26 measured the same from 70 KiB. Q1's 80 KiB **bigedit** brief also reads at b00c057 (`ok open`) where 10c2809 gives `rc=141` (Q1, Q2). `[unverified — submitted as claim]` (my execution)
- Pass 26 finding 1 and its sibling fence probes are closed. Every probe now gives a skip, `open` or `unrecognized`, never a wrong keep, drop or done. Perf P4 gives `skip Q-1` (dup) and `open Q-2` (10c2809: `drop Q-1`). Fact-check P1 gives `unrecognized Q-1` and dup skips for Q-7 and Q-8 (10c2809: `open Q-7`, `unrecognized Q-8`). P6 gives a dup skip for Q-11 (10c2809: `drop Q-11`). Security F5 gives `unrecognized Q-017` (10c2809: `done Q-017`). In a `~~~` block quoting a ```` ``` ```` line, the real answer below the block is read (`keep Q-013`; 10c2809: `drop Q-013`). Security F3's brief now reads `ok open` (10c2809: `ok … done`). No entry in the four real questions files has an unclosed same-kind fence (Q4). `[unverified — submitted as claim]` (my execution, Q4)
- The answer readings are unchanged. Old and new match exactly over all 102 IDs in wt-devcycle's files and all 99 in `/workspace`'s (`(no difference)`, 0 stderr), and every header shape is unchanged (Q3). `[unverified — submitted as claim]` (my execution, Q3)
- `--check-answer` costs the same within noise: 1.04 s against 1.06 s for 102 IDs, 3.36 s against 3.57 s for 100 IDs on the 17 MB archive, and 88–90 ms against 94–96 ms on the 17.5 MB all-fenced archive (Q3). The whole-blob read adds about 2.5 ms/MiB to `--check-brief`, and nothing at real brief sizes (1–256 KiB: 28–34 ms, Q2). `[unverified — submitted as claim]` (my execution)
- B adds attention cost only within the existing bounds. The new final-message item is at most one `open` ID per brief, since step 3 files nothing while an `Asked:` ID is open (`:286-287`). A future-dated tip now reads as idle, so its question rate is the same ≤1 per brief per 14 days that `Kept:` already bounds. A stale-line fix costs one `--check-path`. `[read: skills/dev-cycle/SKILL.md:84-87,278-281,286-299,356-358]`

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | `-G` lookup is linear in edits since the status was set (100k commits / 10k edits: 2 → 556 ms raw). This is the intended trade, with no realistic risk | Informational | `scripts/dev-cycle.sh:273-274` (A) | High |
| 2 | Skip path runs a full-history `-G` walk plus the fallback, then discards `c` (100k: 489 → 942–992 ms) | Informational | `scripts/dev-cycle.sh:273-276` (A) | High |

## Overall Assessment

The round closes both of pass 26's code findings that I could measure. The early-status pipe cliff is gone at every size up to 64 MiB, and every pass-26 fence probe from all three critics now reads a skip, `open` or `unrecognized`, never a wrong keep, drop or done. Readings over all 201 real IDs are unchanged. The price is the `-G` lookup. Its cost now grows with a brief's edit count since its status was set, rather than stopping at the newest touch. It measures at 0.6 s for an implausible 10,000 edits on 100k commits and is negligible at real sizes. On the skip path it doubles a walk whose result is thrown away. Both are Informational, cold-path and optional. B adds no unbounded loop and keeps the question rate within existing bounds. Two commit-citation edge cases (a fenced example edit, a conflict-resolving merge) are passed to fact-check above. No further benchmarking is needed. From the performance lane, nothing blocks the clean pass.

## Goal-Alignment Note

Success criterion, restated verbatim: "a markdown report saved at the path your role instructions give, structured per your skill file."
- **Path:** saved at `/workspace/.claude/wt-digest/docs/reviews/performance-review-2026-10-02-digest-pass27.md`, first line `Commit: b00c057 (A) / 7f3e392 (B)`. Not committed.
- **Structure:** follows the performance-reviewer layout: header, the no-fact-check warning, data flow and hot paths, findings, cross-lane observations, evidence-tagged endorsements (≤5), summary table and overall assessment. Each finding carries Severity (with preconditions and confidence), Location, verbatim Evidence with a note naming the rest of its unit, Move, Classification, Confidence, Baseline and Legibility-target.
