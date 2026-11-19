Commit: 969e8227

# Performance Review — fix/dev-cycle-roadmap-staleness

**Scope:** `git diff main...HEAD` (HEAD 969e8227): `scripts/dev-cycle.sh` sections 3 and 5 (the code that runs); `scripts/lib/migrations.sh` (one registry line); skill and docs text (no runtime cost)
**Date:** 2026-11-18
**Based on:** `docs/reviews/code-fact-check-report-2026-11-18-roadmap-staleness.md` and `...-pass2.md` (their Incorrect findings are reported fixed; neither makes a performance claim)

## Data Flow and Hot Paths

The digest (`scripts/dev-cycle.sh`) runs once per dev-cycle iteration, dozens of times a day. It is a CLI report, so this is a **cold path**: nothing waits on it with a latency budget, and it runs over small files that people edit by hand.

What the branch adds:

- **Section 3 (`scripts/dev-cycle.sh:385`, `:418`):** two variable assignments (`open_ok`, `open_q`). Section 3 already ran `questions.sh open` and kept `open_q`. Section 5 now reads that same output instead of calling it again.
- **Section 5 (`scripts/dev-cycle.sh:464-522`):**
  - one awk pass over `docs/working/questions.md` to build the set of ANSWERED IDs;
  - one awk pass over `docs/roadmap.md` to emit one record per Now/Next item;
  - a bash loop over items × named IDs, which forks one `printf | awk` over `open_q` for each ID.

Sizes in this worktree, measured:

| Input | Size |
|---|---|
| `docs/roadmap.md` | 743 lines (201 `Q-NNN` mentions in the whole file) |
| `docs/working/questions.md` | 129 lines |
| `open_q` | 9 lines |
| Now/Next items | 5 |
| IDs named per item | 5, 2, 1, 0, 0 |

So the loop forks awk 8 times per digest run.

Timings, all measured in this worktree on 2026-11-18:

- **Full digest:** 0.436–0.449 s wall over 3 runs of `timeout 120 bash scripts/dev-cycle.sh`.
- **Section 5's new block alone** (lines 483–521, extracted into a harness and fed the real `open_q`): 0.012 s per run, 0.115 s for 10 runs. Both figures include bash startup.
- **Synthetic stress case:** 30 items, 1,215 named IDs and a 300-line `open_q` took 1.36 s, about 1.1 ms per ID. Cost grows linearly with the number of IDs.

## Findings

#### One awk fork per named ID in the section 5 loop

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:511-520` (the fork is at line 515)
**Move:** Count the hidden multiplications
**Classification:** Micro (a fixed process-spawn cost per ID) / Cold path (a CLI digest that runs once per iteration, dozens of times a day)
**Confidence:** High
**Baseline:** section 5's new block took 0.012 s wall against a 0.44 s full digest (3 runs, this worktree, 2026-11-18). The synthetic case with 1,215 IDs took 1.36 s.

Evidence (line 515):

```
r="$(printf '%s\n' "$open_q" | awk -v id="$id" '$1 == id { r = substr($0, index($0, "  ") + 2, 16); sub(/ +$/, "", r); print r; exit }')"
```

For each ID an item names, the loop pays for:

- a command-substitution subshell;
- a pipe;
- an awk process that rescans all of `open_q`.

The total cost is (IDs named across Now/Next) × (one fork plus a scan of `open_q`). The real roadmap has 8 such IDs, which costs about 10 ms, or 2–3% of a digest whose runtime is mostly other sections' git log walks. Fork cost would only be noticeable if Now/Next grew to hundreds of named IDs, and even 1,215 IDs stays under 1.5 s. The block has no unbounded resource, no quadratic term at realistic sizes, and no repeated I/O beyond these forks.

**Recommendation:** No change needed at the current scale. If it is ever wanted, the per-ID lookup can be replaced with one pass that does not fork per ID: build a `declare -A` map of route by ID from `open_q` once before the loop, or join items and `open_q` in a single awk. Keep the route-by-position parse from line 515 if you do.

## Endorsements

- Section 5 reuses section 3's `open_q` (lines 417–418, 515) instead of running `questions.sh open` a second time. That saves a second launch of the script and its file reads on every digest. [read: scripts/dev-cycle.sh:416-418, 476, 515]
- The ANSWERED set is built once, before the loop, by a single awk pass (lines 483–486). The loop checks each ID against it with a bash substring test (line 514), not a fork. [read: scripts/dev-cycle.sh:483-486, 513-514]
- Item records come from one streaming awk pass over the roadmap (lines 487–505). It stops collecting outside the first Now and first Next headings, and its per-item `seen` array is a local, so it resets on every `flush()` call. [read: scripts/dev-cycle.sh:487-505]
- Claim: the item awk joins each item's text with repeated string concatenation (line 503), and the ID scan copies the text with `substr` once per match (line 493). Both are quadratic in the length of a single item, but items are a few lines long, so this is not measurable. The stress case gives linear total time. [unverified — submitted as claim]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | One awk fork per named ID in the section 5 loop | Informational | `scripts/dev-cycle.sh:515` | High |

## Overall Assessment

This branch has no performance problems. The new section 5 work is two single-pass awk scans plus a loop whose cost is linear in the number of IDs that Now/Next items name. On the real roadmap that is 8 awk forks, about 12 ms, against a 0.44 s digest. The one structural inefficiency, a fork per ID, is Micro × Cold. It would take hundreds of IDs in Now/Next before anyone noticed. Reusing section 3's `open_q` was the right choice: it avoids a second `questions.sh` run. No profiling is needed beyond the timings above. The `migrations.sh` line and the skill text add no runtime cost on this path.

## Goal-Alignment Note
- Success criterion (restated verbatim): "a markdown report saved to /workspace/.claude/wt-roadmap-staleness/docs/reviews/performance-review-2026-11-18-roadmap-staleness.md, structured per the performance-reviewer skill, with `Commit: 969e8227` as its first line."
- Answered: performance of every runtime change in `main...HEAD`. I read sections 3 and 5 of `scripts/dev-cycle.sh` in full (lines 384–527). I timed the full digest (3 runs), the isolated section 5 block on real data, and a synthetic stress case. Result: one Informational finding and four endorsements.
- Out of scope: whether section 5 is correct. That belongs to the fact-check reports, and I re-verified nothing in them. Also out of scope: the cost of other digest sections, security, API consistency, and the bats tests.
- Escalate: nothing.
