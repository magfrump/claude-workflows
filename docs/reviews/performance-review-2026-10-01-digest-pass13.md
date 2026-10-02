Commit: 591f098 (A) / 44d06b7 (B)

# Performance Review: dev-cycle pass 13 (k=1 loop pass, partial scope: the pass-12 fix round)

**Scope:** A `git diff 71e618d..591f098 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` (6d6637d, 591f098); B `git diff 8286c2b..44d06b7 -- skills/dev-cycle/SKILL.md`
**Date:** 2026-10-01
**Based on:** `docs/reviews/code-fact-check-report-digest-pass12.md` (the pass-12 fact-check, on 71e618d; this round's code was not in it)

Line numbers: A at 591f098 (`git show 591f098:scripts/dev-cycle.sh`; HEAD 8a52771 has the same script and tests, `git diff --stat 591f098 HEAD -- scripts test` is empty). B at 44d06b7. Probes ran under `timeout`, in `mktemp -d` repos under `scratchpad/perf13/`. They used copies of the script at 71e618d (`perf13/old/`) and 591f098 (`perf13/new/`), driven by `perf13/bench.sh`, with a `realpath` counting shim at `perf13/shim/realpath`. Nothing was written to either worktree except this file, and no process was left running. Bats at 591f098: 22/22 passed in 6.3 s wall.

## Data Flow and Hot Paths

`scripts/dev-cycle.sh` is a read-only CLI run once per dev cycle, so the whole digest is a **cold path**. It is not latency-sensitive: the agent reads its output once. This round changes the cost in two places:

- **Fixed-name sites.** `inrepo` (`:117`) now runs `blocker "$1" file` in a command substitution, then `rawfile`. `blocker` (`:102-113`) forks `realpath` once per existing parent (via `plaindir`) and once for the leaf (via `rawfile`). `inrepo` then forks `realpath` on the leaf a second time. The sites are `docs/decisions/log.md` (`:212`), `docs/working/questions.md` (`:234`), `docs/roadmap.md` twice (`:269`, `:319`) and `$LOG` = `docs/working/idea-log.md` (`:330`). That is 5 calls per run, a fixed number that does not grow with the repo.
- **Glob loops** (`:149`, `:203`). These now call `rawfile` directly: one `realpath` fork per item, exactly as `inrepo` cost at 71e618d. A skipped item still pays `skipped` → `blocker`, which walks the plain parents again. The old `skipped()` already walked parents, so the per-skipped-item cost is unchanged in kind.

N for the fixed-name sites is 5, a constant. N for the globs is the number of cycle records (about one per cycle) plus the number of decision records. Both grow slowly.

## Findings

#### 1. `inrepo` triples the `realpath` forks at the five fixed-name sites (+15 forks, about +17 ms per run)

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:117` (callers `:212`, `:234`, `:269`, `:319`, `:330`; walk at `:102-113`)
**Move:** Hidden multiplication / work that moved
**Classification:** Micro (fixed per-call fork overhead, constant count) / Cold path (once-per-cycle CLI)
**Confidence:** High (executed)
**Baseline:** 44 ms per digest (5 runs: 44 45 44 44 43) at 71e618d, in a repo where all five fixed-name inputs exist as plain files. Measured with `scratchpad/perf13/bench.sh fixed` on 2026-10-01.

**Evidence:** `inrepo() { [[ -z "$(blocker "$1" file)" ]] && rawfile "$1"; }` (`:117`, the whole function). Inside `blocker`: `plaindir "$p" || { printf '%s/' "$p"; return 0; }` per parent (`:108`), then `else rawfile "$1" || printf '%s' "${1//$'\n'/ }"; fi` on the leaf (`:112`; the function ends at `:113`). So when the input is plain, `rawfile` runs on the leaf twice: once in `blocker` and once in `inrepo`.

The `realpath` counting shim measured 8 calls at 71e618d and 23 at 591f098 for the same repo (`docs` 1→7, `docs/working` 0→3, `docs/decisions` 2→3, each leaf 1→2, `docs/roadmap.md` 2→4). That is 15 extra `realpath` forks plus 5 command-substitution subshells. The run went from 44 ms to 59–63 ms. In an empty repo it went from 21 ms to 25–26 ms, and with a symlinked `docs/` from 30–31 ms to 38–41 ms. The cost is fixed per run, about 1 ms per fork on this host, and does not grow with history or the number of records. Five of the extra forks are the duplicate leaf `rawfile`, and one walk at `:319` repeats `:269` on the same path. None of this matters for a once-per-cycle CLI.

**Recommendation:** No action is needed for performance. If the code is touched again, `inrepo() { [[ -z "$(blocker "$1" file)" && -f "$1" ]]; }` drops the duplicate leaf fork. An empty `blocker` result for an existing path already means `rawfile` passed. Readability should decide, not cost.

**Legibility-target:** for-author

#### 2. Step 6's stale-brief rule tells the agent to read `questions-archive.md`, which grows without bound (186 KB here)

**Severity:** Low
**Location:** `skills/dev-cycle/SKILL.md:227-229` (B, 44d06b7)
**Move:** What's the size of N / price the deployment environment (agent context is the cost)
**Classification:** Macro (cost grows linearly with the archive, which only grows) / Cold path (once per cycle, only when a brief is past 14 days)
**Confidence:** Medium (the archive size is measured; whether an agent reads the whole file or searches it is not)
**Baseline:** `docs/working/questions-archive.md` is 186,439 bytes, 1,838 lines and 89 entries in this repo (`wc -lc` at wt-devcycle HEAD, 2026-10-01). At about 4 bytes per token, a full read is roughly 46,600 tokens.

**Evidence:** "Apply answers here, reading `questions-archive.md` too (step 1 has already archived answered entries), and apply each before deciding whether to ask again." (quoted to the end of the sentence; the bullet ends with "Until the user answers, the brief still holds its slot.")

The rule is correct: an answered keep/drop entry is archived by step 1, so the agent must look there. But "reading" invites a whole-file read. The archive has no eviction, so in a long-lived repo each stale-brief check pulls in tens of thousands of tokens of unrelated entries. Only the entry titled "keep or drop the brief for <item>?" is needed. This applies only when some brief is stale, and there are at most 3 briefs.

**Recommendation:** Say "search `questions-archive.md` for the `keep or drop the brief for <item>?` entry" (e.g. `rg -n`), not "reading". This is a wording change only. Severity stays Low because the path is cold and the cost is bounded by one read per cycle.

**Legibility-target:** for-author

## Endorsements

- The glob loops' switch from `inrepo` to `rawfile` keeps the per-record cost at one `realpath` fork. With 1,000 plain cycle records the digest took 943–1,079 ms at 591f098, against 950–970 ms at 71e618d (5 runs each, `bench.sh records`). With 1,000 symlinked records it took 5.0–6.5 s against 4.9–6.3 s (`bench.sh skiprecords`), about 5 ms per skipped record either way. That cost predates this round. [read: scripts/dev-cycle.sh:146-159, 102-113, 92, 95]
- Claim: across five scenarios (empty, fixed, symparent, records, skiprecords), the digest at 591f098 prints the same output as at 71e618d except for the intended wording changes: the Window note, the `skipnote` lines and the section-8 header. Checked by `diff` of `perf13/out-*-{old,new}.txt`. [unverified — submitted as claim]
- Claim: in the symparent probe (`docs` → a directory with no `cycles`), the Window line changed from "no cycle record found" to "no readable cycle record (records or their directory were skipped as not plain…)". This is because `skipdir docs/working/cycles` now walks parents and records `docs/`. That matches the design (nothing is probed below a blocking part), but "their directory" is looser than the actual blocker `docs/`. B's step 0 bullet names `docs/` and `docs/working/` too, so the skill covers it. Routed to fact-check, not a performance finding. [unverified — submitted as claim]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 2 | Stale-brief rule reads the whole unbounded questions archive | Low | `skills/dev-cycle/SKILL.md:227-229` | Medium |
| 1 | `inrepo` walk triples fixed-name `realpath` forks (+~17 ms/run) | Informational | `scripts/dev-cycle.sh:117` | High |

## Overall Assessment

The cost of running `blocker()` first at every fixed-name site is measured and small. It adds 15 `realpath` forks and 5 subshells per run, a constant that does not grow with the repo: about +17 ms with all inputs present (44 → about 61 ms) and +4 ms in an empty repo. Five of those forks are a duplicate leaf `rawfile`, which can be removed without changing behavior. The cost is not worth acting on for a once-per-cycle CLI. The glob loops' move to `rawfile` keeps the per-record cost at one fork, and the 1,000-record runs match 71e618d within noise. The only item above Informational is in B: the stale-brief rule says to read a questions archive that only grows (186 KB here). A one-word change to "search" fixes it. Nothing needs profiling. Nothing in this lane rates above Low, so performance does not block a clean pass.

## Goal-Alignment Note

Success criterion (verbatim): "a markdown report saved at the path your role instructions give, structured per your skill file."

This report is saved at `/workspace/.claude/wt-digest/docs/reviews/performance-review-2026-10-01-digest-pass13.md`, with first line `Commit: 591f098 (A) / 44d06b7 (B)`. It has the skill's header, Data Flow, Findings (each with Severity, Location, Move, Classification, Confidence, Baseline, Evidence and Legibility-target), evidence-tagged Endorsements, a Summary Table and an Overall Assessment. It serves the user goal (merge both branches once a clean pass is reached): no performance finding blocks that pass, and the one Low is a single-word wording fix in B.
