Commit: cbfdf35 (A) / 77e21af (B)

# Performance Review — dev-cycle pass 25 (pass-24 fix round, k=1 delta)

**Scope:** Partial. A: `git diff c1d0a80..cbfdf35 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` in `/workspace/.claude/wt-digest` (HEAD 2121c24 adds review docs only). B: `git diff fb643e2..77e21af -- skills/dev-cycle/SKILL.md` in `/workspace/.claude/wt-devcycle` (merge 60fb513; `git show 60fb513:scripts/dev-cycle.sh` is byte-identical to `cbfdf35:scripts/dev-cycle.sh`, checked with `cmp`). Focus, per the brief: `--check-brief`'s `git cat-file` and `git log -1` per brief on a long history, `--check-branch`'s `rev-list --count` for long-lived branches, and `--check-answer` after the rewrite. Everything else is context only.
**Date:** 2026-10-02
**Based on:** Stage-1 context `code-fact-check-report-digest-pass24.md` (verdicts on c1d0a80 / fb643e2, the code this round changes), plus `performance-review-2026-10-02-digest-pass24.md` and its probes in `scratchpad/perf24/`.

> ⚠️ **No code fact-check report covers cbfdf35 / 77e21af.** The comments and help text this round added have not been checked by a fact-check stage. The numbers below come from my own runs, and runtime endorsements are submitted as claims.

**Measurements.** All are mine, taken 2026-10-02 in this sandbox: git 2.39.5, mawk, 16 CPUs. The script under test is `git show cbfdf35:scripts/dev-cycle.sh` ("new"). For `--check-answer` I also ran `git show c1d0a80:…` ("old"), in the same loop. Scratch is under `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/perf25/` (written `perf25/` below). Each probe (`p1`–`p4`) is one `set -eu` script that creates its own `mktemp -d` dir under `perf25/` and checks `$PWD` before any `git init`, commit or write. Every process ran under `timeout`, and none of mine is still running. Nothing was written to either worktree or to `/workspace`, except this file. `/workspace` is still on `main`, and its status is unchanged. Stderr in P1 is 2 lines per call: the sandbox's `setlocale` warning (the uninstalled `en_US.UTF-8`), not script output.

- **P1, long histories** (`perf25/p1.log`; generator `perf25/gen.py`). Repos are built with `git fast-import`. Main gets N commits. One brief is added in commit 1 and never touched again: the worst case for `git log -1`. Three briefs are added at 25/50/75% of the history, and one at the last commit. `feat/longlived` forks at commit 1 with N commits of its own, and `feat/orphan` is an unrelated history of N commits. Every repo was measured without a commit-graph, and then with `git commit-graph write --reachable --changed-paths`. Each cell is a whole script call (two runs):

  | History | `--check-brief` oldest brief | newest brief | `new` (absent on main) | 5 briefs, one call | `--check-branch` long-lived | orphan | raw `git log -1 -- <oldest>` |
  |---|---|---|---|---|---|---|---|
  | 1k linear, no graph | 22–23 ms | 20–21 | 15–17 | 59–60 | 20 (n=1000) | 18 | 5 ms |
  | 10k linear, no graph | **51–56 ms** | 19 | 15 | 138–142 | **62–65** (n=10000) | 40 | 36 ms |
  | 10k linear, graph | 23 ms | 20 | 15–16 | 62–64 | 21–22 | 19–20 | 5 ms |
  | 100k linear, no graph | **454–476 ms** | 19–21 | 15–17 | **1,134–1,253** | **584–594** (n=100000) | 287–301 | 430 ms |
  | 100k linear, graph | 79–85 ms | 19–21 | 16 | 232 | 99 | 58–65 | 63 ms |
  | 30k (20k merges), no graph | 102–104 ms | 19–21 | 15 | 260–264 | 149–163 | 68–73 | 92 ms |
  | 30k (20k merges), graph | 30–31 ms | 20–21 | 16–17 | 93–101 | 30–33 | 25–26 | 13 ms |

  Lifecycle on the 10k repo:
  - After `git mv` of the oldest brief to `closed/`, committed on main: the old path prints `ok … new` (16 ms), and the `closed/` path prints `skip …: not an open build brief`.
  - A brief in the working tree only prints `ok … new`, and so does a brief committed on a checked-out non-default branch.
  - `--check-branch` prints count **3** for a squash-merged branch with 3 commits, **0** for a `--no-ff`-merged branch, and **0** for a fresh branch at main.
- **P3, this repo's real history** (`perf25/p3.log`; a `git clone --no-checkout /workspace` into the temp dir; 1,897 commits on main). `git log -1 main -- docs/decisions/001-code-fact-checking.md` (the oldest-added doc, last changed 2026-03-20) takes **6 ms** without a commit-graph and 2–3 ms with one. `git log -1` on a path that never existed takes 7–8 ms. A branch at the root commit: `rev-list --count main..` 4 ms, and the whole `--check-branch` call **17–19 ms**.
- **P2, `--check-answer`** (`perf25/p2.log`). Same generator as pass 24: wt-devcycle's real `questions-archive.md` (186,439 B, 89 entries), repeated with renumbered IDs to 10× and 100×, plus `questions.md`. Readings are diffed over every real ID, in two real copies of the files: wt-devcycle's (102 IDs) and `/workspace`'s (99 IDs, read-only via `cp`). The line that decided each recognized reading was printed by an instrumented copy of the new awk.

  | Archive | live ID old → new | archived ID old → new | absent ID old → new | 10 IDs old → new | 100 IDs old → new | awk program alone |
  |---|---|---|---|---|---|---|
  | x1: 186 KB | 21–35 → 21 ms | 21–23 → 21–22 | 21 → 21–24 | 106 → 105 | 859 → 860 (89 IDs) | 2 → 2 ms |
  | x10: 1.7 MB | 23–25 → 22–24 | 23–27 → 23–24 | 23–24 → 23 | 138 → 131 | 1,230 → 1,197 | 5 → 5 ms |
  | x100: 17 MB | 48–50 → **44–45** | 48–49 → 44–45 | 48–49 → 43–44 | 377 → 338 | 3,728 → **3,289** | 29 → 25 ms |

  All real IDs in one call: wt-devcycle 1,014 → 997 ms; `/workspace` 972 → 954 ms.
- **P4, tests** (`perf25/p4.log`): `bats test/scripts/dev-cycle.bats` on `git archive cbfdf35 scripts test`: **39/39 ok, rc 0, 10.0 s** (pass 24: 36 tests, 9.6 s).

Legibility-target values: **maintainer** (someone editing the script or skill) and **agent** (the model that runs the skill and reads the check's output).

## Data Flow and Hot Paths

Every check mode is a **cold path**: one agent Bash call per mode and batch, once per cycle. Three things can still push a finding up: the agent's 120 s Bash timeout, the agent's context (which receives the output), and inputs that grow without bound.

- **`--check-brief`** (`scripts/dev-cycle.sh:245-259`). Per argument, it does a `pathform` + `isbrief` regex and a `blocker` walk (one `realpath` subshell per existing path part), then `git cat-file -t MAIN_SHA:<path>`. A brief that is not on main (`new`) stops there: that is O(1) in history, 15–17 ms flat (P1). A landed brief adds `git cat-file blob | grep -m1` and `git log -1 --format=%H MAIN_SHA -- <path>`. The log walk is O(commits since the brief last changed on main), with tree diffs at each commit. N is the In-flight briefs plus roadmap brief paths, capped by the 3-slot rule (`SKILL.md:297`, `:326` "3/3: no new briefs"). The digest already runs the same `git log -1 -- <file>` per tracked file (`:491-492`, `:576`), so the new call follows existing practice.
- **`--check-branch`** (`:261-276`). For an existing branch this round adds one `git rev-list --count MAIN_SHA..<sha>`. That walk is O(commits on the branch side + main commits back to the merge base). Without a commit-graph's generation numbers, git walks main's side down to the fork point too. For an unrelated history, it walks both histories whole. N is one name per open brief, so 3 at most.
- **`--check-answer`** (`:293-366`). The structure is unchanged from pass 24: two `awk` passes per ID, each over a whole file. The awk now runs `heading()`, the `#`-heading test and `!inside { next }` before the fence and status rules (`:328-332`), so lines outside the entry skip the remaining per-line regex work. The answer test is anchored: `low !~ /^\*\*answer(:|ed| \()/` (`:338`) replaces the old `index(low, "**answer")` scan of every line. N is the not-yet-`Applied:` IDs on open briefs' `Asked:` lines, so a handful.
- **B** adds no new loop. The cycle calls `--check-brief` once per In-flight brief (`SKILL.md:257`) and once per name it writes (`:301-302`). It calls `--check-branch` once per brief (`:285-286`) and `--check-answer` once per brief's pending IDs. The skill's remaining git commands are `git branch --show-current`, `git add -A`, `git worktree list`/`prune` and `git mv`. None takes a brief's branch name (`grep` of 77e21af's SKILL.md).

## Findings

#### 1. `--check-brief`'s `git log -1` walks back to the brief's last change on main, linear in history

**Severity:** Informational. Preconditions: a brief that has not changed on main for tens of thousands of commits, in a repo with no changed-path commit-graph. Even then a call stays under 0.5 s per brief, and N ≤ about 3. Confidence: High (measured).
**Location:** `scripts/dev-cycle.sh:254-256` (A, cbfdf35)
**Evidence (verbatim):**
```bash
  if [[ "$(git cat-file -t "$MAIN_SHA:$a" 2>/dev/null || true)" != blob ]]; then echo "ok $a new"; return; fi
  st="$(git cat-file blob "$MAIN_SHA:$a" | { env LC_ALL=C grep -m1 -E '^Status: (open|done|dropped)$' || true; })"
  c="$(git log -1 --format=%H "$MAIN_SHA" -- "$a")"
```
(This is `:254-256`. The function continues at `:257-259`, `if [[ -n "$st" ]]; then echo "ok $a ${st#Status: } $c"` / `else echo "skip $a: no line that is exactly Status: open, done or dropped"; fi` / `}`. `$c` is computed for every landed brief, including `open` and `dropped`, though the skill only names it for `done` (`SKILL.md:257-259`).)
**Move:** Ask "what's the size of N?" (N = commits since the brief last changed on main)
**Classification:** Macro (linear in history depth) / Cold path (once per brief per cycle, ≤ about 3 briefs)
**Confidence:** High
**Baseline:** P1, `perf25/p1.log`, 2026-10-02. For the oldest brief, the whole call takes 22 ms at 1k commits, 51–56 ms at 10k and **454–476 ms at 100k** without a commit-graph. With `--changed-paths` it takes 23 ms at 10k and 79–85 ms at 100k. Five briefs in one call at 100k take 1,134–1,253 ms, or 232 ms with the graph. P3: this repo's 1,897 commits cost 6 ms for the raw `git log -1`.
**Legibility-target:** maintainer

The cost is linear in how far back the brief's last change lies, about 4.5 ms per 1,000 commits without a changed-path Bloom filter. The matrix default for Macro × Cold is Low. I grade it Informational on the evidence: N is capped at 3 by the slot rule, and briefs change every few cycles (`Asked:`, `Applied:`, `Kept:`), which keeps the walk short. This repo would need about 50× its current history before one call reached 0.5 s. A `new` brief never pays the walk, because `cat-file -t` gates it (flat 15–17 ms at every size). The log itself is the same call the digest already makes per file (`:491-492`).

**Recommendation:** None needed for merge. If it ever matters, `git commit-graph write --reachable --changed-paths` cuts it about 5× (measured). Alternatively, run `git log -1` only when the status is `done`, but that changes the output contract for `open`/`dropped`, so it is for the API critic to weigh.

#### 2. `--check-branch`'s `rev-list --count` walks main back to the fork point for a long-lived branch

**Severity:** Informational. Preconditions: a brief's branch that forked tens of thousands of main commits ago, or an unrelated history, in a repo without a commit-graph. Confidence: High (measured).
**Location:** `scripts/dev-cycle.sh:274` (A, cbfdf35)
**Evidence (verbatim):**
```bash
    if [[ -n "$sha" ]]; then echo "ok $a $sha $(git rev-list --count "$MAIN_SHA..$sha")"; else echo "absent $a"; fi
```
(This is `:274`, inside the `else` arm that starts at `:271`. The arm ends `fi` at `:275`, and the function ends at `:276`. `$sha` is the peeled `refs/heads/<name>` commit from `:272-273`.)
**Move:** Count the hidden multiplications (one walk per brief, but the walk spans main's history since the fork)
**Classification:** Macro (linear in commits between the fork point and main's tip) / Cold path (≤ 3 calls per cycle)
**Confidence:** High
**Baseline:** P1, `perf25/p1.log`, 2026-10-02. A branch forked at commit 1 takes 20 ms with 1k main commits, 62–65 ms with 10k and **584–594 ms with 100k**, or 99 ms with a commit-graph. An unrelated history of 100k takes 287–301 ms. P3: on this repo (1,897 commits), a branch at the root commit takes 17–19 ms for the whole call.
**Legibility-target:** maintainer

The number is only used to test `0` (`SKILL.md:285-286`), but `--count` walks every commit on the far side. A branch that really is long-lived (forked long ago, never rebased) pays for all of main's history since the fork. At this repo's size the cost is noise. It would take ~100k commits since the fork to approach a second per brief.

**Recommendation:** None needed for merge. If the count is only ever compared with 0, `git rev-list --max-count=1 MAIN_SHA..<sha>` stops at the first commit found (any output means non-zero). But the printed `<n>` is now part of the check's output contract, so keep it unless the contract changes.

#### 3. A brief whose branch has any commit beyond main never reaches keep-or-drop, so [3] done cannot reach a squash-merged or abandoned branch, and its slot is held indefinitely

**Severity:** Low. Preconditions: the brief's build session never set `Status: done`/`dropped`, *and* its branch still exists with ≥1 commit not on main, for example after a squash or rebase merge with the branch kept, or after a build abandoned mid-way with work-in-progress commits. Each such brief holds one of the 3 slots until a human edits its status by hand. Three of them stop new briefs entirely. Confidence: High on the mechanism (measured); Medium on how often it happens (this repo merges locally, and a `--no-ff` or fast-forward merge gives 0).
**Location:** `skills/dev-cycle/SKILL.md:278-286` (B, 77e21af), with `scripts/dev-cycle.sh:274` (A)
**Evidence (verbatim):**
```
  3. Then, if the brief is still open and no ID on its `Asked:` line is still `open` or
     skipped, and its branch shows no work 14 days after
     the brief's last `Kept:` date (none yet: the brief's own date), file one
     `you: judgment` entry, slug `keep-or-drop-<brief file name without .md>-<n>` (n = how
     many it has been asked), asking "keep, drop or mark done <brief path>?" with options
     **[1] keep**, **[2] drop** and **[3] done** (it shipped; its status line was not set),
     and add its ID to `Asked:` (IDs separated by ", "). Until it is answered, the brief still
     holds its slot. "Shows no work": `--check-branch` prints `absent`, skips the name
     (recorded), or prints `ok <name> <commit> 0`.
```
(This is `:278-286`, the whole of In flight step 3. The section continues at `:287` with **Next**.)
**Move:** Trace the memory lifecycle (a slot is a bounded resource. Nothing on this path frees it.)
**Classification:** Macro (an unbounded hold on 1 of 3 slots) / Cold path (evaluated once per cycle)
**Confidence:** High (mechanism) / Medium (frequency)
**Baseline:** P1, `perf25/p1.log`, 2026-10-02, 10k repo. A squash-merged branch with 3 commits prints `ok feat/sq <sha> 3`. A `--no-ff`-merged branch and a fresh branch at main both print `… 0`. Pass 24's fact-check P5 measured the same (`ok squashed … -> rev-list count 1`).
**Legibility-target:** agent

This round added **[3] done** for "it shipped; its status line was not set". That case is the forgotten-status brief that pass 24's fact-check left open (`code-fact-check-report-digest-pass24.md:605`, "It does not establish what a brief whose build session forgot `Status: done` costs"). But the question is filed only when the branch "shows no work", and any commit beyond main counts as work, whatever its age. So [3] is reachable for a merged-then-kept (`--no-ff` or fast-forward, count 0) or deleted (`absent`) branch, but not for a squash- or rebase-merged branch that is kept, nor for an abandoned branch with WIP commits. Those stay In flight with no question asked. The rule is unchanged from fb643e2, and pass 23's API review raised the squash case as Informational (#8). This round makes it more visible, because the new option was designed for exactly this case and does not reach it. The "14 days" timer never starts while the count is above 0.

**Recommendation:** Have "shows no work" also cover a branch whose newest commit is older than the 14-day window. That would mean `--check-branch` printing the tip's commit date (one `git log -1 --format=%cs <sha>`, O(1)) and the skill comparing it with `Kept:` or the brief date. Alternatively, file keep-or-drop-or-done every 14 days regardless of the count. Either way the question reaches every stuck brief, and [3] covers the squash case.

## Cross-lane observations (not graded here; for the API-consistency critic and fact-check)

- `--check-brief` prints `ok <path> new` in four different states: never written, written but uncommitted, committed only on a non-default branch, and **moved away to `closed/` on main** (P1 lifecycle). The skill's name-uniqueness test (`SKILL.md:301-302`, "`--check-brief` prints `new` for it and `--check-path` on the same name under `closed/` prints a skip") therefore does not see a same-name brief that exists only in the working tree or on an unmerged cycle branch. The surrounding text's "plus any this cycle has written" list covers the same-cycle case. `[unverified — submitted as claim]`
- `--check-answer`: on both real copies, every recognized reading was decided by a user-answer record line (`**Answered …` / `**Answer (…` at line start). For Q-081 and Q-083, the deciding line is the answer that precedes an "Original entry:" quote, so the quoted text below it is never read (the reader stops at the first match). The awk cannot tell who wrote a line, though: an agent note starting `**Answer (…):` above the user's line would be read first. No real entry does this today. `[unverified — submitted as claim]`

## Endorsements

- `--check-answer`'s rewrite changes exactly the readings the brief predicts, and no others. Q-070, Q-071 and Q-073 go from `keep` to `unrecognized` (ANSWERED entries with no answer line at line start). Q-019, Q-037 and Q-085 go from `unrecognized` to `done`. Nothing else changes, in both wt-devcycle's files (102 IDs) and `/workspace`'s (99 IDs), with 0 stderr. No keep, drop or done reading was taken from a line that is not an answer record. `[unverified — submitted as claim]` (my execution, P2, diff of old/new plus the instrumented deciding lines)
- The rewritten awk program is no slower and is faster at scale: 100 IDs on a 17 MB archive take 3,728 → 3,289 ms, and a single ID 48–50 → 44–45 ms. This holds because `!inside { next }` now precedes the fence and status rules, and the answer test is anchored at line start instead of an `index()` over every line. `[read: scripts/dev-cycle.sh:327-347]`
- `--check-brief` on a brief not yet on main (the cycle that writes it) costs one `git cat-file -t` and no log walk: 15–17 ms flat from 1k to 100k commits. `[unverified — submitted as claim]` (my execution, P1)
- The help range `sed -n '2,58p'` (`:121`) covers the whole header: `:57` is the last comment line and `:58` is blank. `[read: scripts/dev-cycle.sh:55-58,121]`
- The suite is 39/39 ok at cbfdf35, in 10.0 s. `[unverified — submitted as claim]` (my execution, P4)

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | `--check-brief`'s `git log -1` is linear in commits since the brief's last change (51 ms at 10k, 454–476 ms at 100k without a graph; 6 ms on this repo) | Informational | `scripts/dev-cycle.sh:254-256` (A) | High |
| 2 | `--check-branch`'s `rev-list --count` walks main back to the fork point (584–594 ms for a branch forked 100k commits ago; 17–19 ms on this repo) | Informational | `scripts/dev-cycle.sh:274` (A) | High |
| 3 | "Shows no work" is count == 0, so keep-or-drop-or-done is never filed for a squash/rebase-merged-and-kept or abandoned-with-commits branch; the new [3] done misses the case it was added for, and the slot is held indefinitely | Low | `skills/dev-cycle/SKILL.md:278-286` (B); `scripts/dev-cycle.sh:274` (A) | High (mechanism) / Medium (frequency) |

## Overall Assessment

From a performance standpoint the fix round is sound. Both new git calls are cold-path. They are bounded by the 3-slot rule and linear in history depth, and on this repo's 1,897 commits each costs single-digit milliseconds. It would take roughly 50–100× the current history, with no changed-path commit-graph, before either approached half a second per brief (findings 1–2, Informational). `--check-answer`'s rewrite is slightly faster than c1d0a80 at every scale I measured, and its readings change in exactly the six entries the brief predicted. The one structural issue is a lifecycle one, not a cost one (finding 3, Low): the keep-or-drop gate counts any commit beyond main as work, forever. A squash-merged-and-kept or abandoned branch therefore holds a slot with no question ever filed, and the new [3] done option does not reach the forgotten-status case it was added for. That rule predates this round, so it is fixable in the skill text plus one O(1) date field. No further benchmarking is needed.

## Goal-Alignment Note

Success criterion, restated verbatim: "a markdown report saved at the path your role instructions give, structured per your skill file."
- **Path:** saved at `/workspace/.claude/wt-digest/docs/reviews/performance-review-2026-10-02-digest-pass25.md`, first line `Commit: cbfdf35 (A) / 77e21af (B)`.
- **Structure:** follows the performance-reviewer layout: header, no-fact-check warning, data flow and hot paths, findings, evidence-tagged endorsements (≤5), summary table and overall assessment. Each finding carries Severity (with preconditions and confidence), Location, verbatim Evidence with truncation notes, Move, Classification, Confidence, Baseline and Legibility-target.
- **Coverage of the brief's scope:**
  - `--check-brief` was measured on linear histories of 1k, 10k and 100k commits and on a 30k merge-heavy history, with and without a changed-path commit-graph. That covers oldest, newest and absent briefs, five per call, and the lifecycle states (after `git mv`, uncommitted, unmerged branch).
  - `--check-branch` was measured for long-lived, unrelated, squash-merged, merged and fresh branches.
  - `--check-answer` was re-measured against c1d0a80 at 1×, 10× and 100×, and diffed over every real ID in two real copies.
  - This repo's real history was timed through a clone. The bats suite and the help range were checked.
  - Rules found correct and complete for performance: the `cat-file -t` gate (a `new` brief pays no walk), `--check-branch`'s count semantics (0 for merged and fresh, >0 for squash-merged, as designed), and the awk's early `!inside` skip.
- **Probe rule:** followed. Every probe is self-contained under `perf25/`, and every process ran under `timeout`. Nothing outside the temp dirs changed except this report.
- **Not committed**, per instructions.
