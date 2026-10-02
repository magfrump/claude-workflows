Commit: baa46e3

# Performance Review — feat/dev-cycle-digest (final pass 3)

**Scope:** `scripts/dev-cycle.sh`, `test/scripts/dev-cycle.bats` at baa46e3 (full branch 4225753..baa46e3). Both files are byte-identical at HEAD 65bd433.
**Date:** 2026-09-30
**Based on:** Stage-1 merged fact-check summary (k=3, `code-fact-check-report-r{1,2,3}-digest-final3.md`); override log row 166; `performance-review-2026-09-29-digest-final{,2}.md`
**Execution log:** `docs/reviews/execution-logs/performance-digest-final3-measurements.txt`

## Data Flow and Hot Paths

`scripts/dev-cycle.sh` is a CLI that the dev-cycle skill runs once per cycle (14 days by default). **Every path is cold**: nothing calls it per request or in a loop. Two costs matter. The first is wall-clock time as history, records and log rows grow. The second is digest size, because an agent reads the whole digest into its context. Size was the subject of the deferred Medium finding (override row 166).

What baa46e3 changes, performance-wise:
- **Per trigger record (lines 110-124):** one `grep -q`, then one `git show "$base:$f"` and two `awk` passes compared with `cmp` (line 116). A record that prints also runs one `git log -1 -- "$f"` (line 118) and a third `awk` (line 120).
- **Once per run:** a `sed` over the last record plus one `merge-base --is-ancestor` or `rev-list -1 --first-parent --before` (lines 108-109), and one long-lived `tr` output filter (line 42).
- **Removed:** the de53069 per-record `git log --first-parent --since` and `git status --porcelain` pair.

**Measurements.** I ran both versions in a throwaway clone of /workspace under `mktemp -d` in the scratchpad. The clone had main at 84ec30f, 1,887 commits (998 of them first-parent), 11 trigger records and 65 log rows. Each cycle record was an untracked `cycle-<day>.md` whose `Main at:` line held the last first-parent commit before that day.

| Window start | Version | Wall time | Digest | §2 | Records printed | Records whose trigger section changed |
|---|---|---|---|---|---|---|
| 2026-09-02 (28 d) | de53069 | 0.26–0.63 s | 20,771 B | 17,533 B | 11 | 3 |
| 2026-09-02 | **baa46e3** | 0.23 s | 11,552 B | 8,134 B | 3 | 3 |
| 2026-09-16 (14 d, skill cadence) | de53069 | 0.26 s | 20,771 B | 17,533 B | 11 | 2 |
| 2026-09-16 | **baa46e3** | 0.20 s | **10,487 B** | **7,069 B** | **2** | 2 |
| 2026-09-23 (7 d) | de53069 | 0.24 s | 17,032 B | 14,049 B | 10 | 1 |
| 2026-09-23 | **baa46e3** | 0.19 s | 6,732 B | 3,569 B | 1 | 1 |

The first de53069 run took 0.63 s because the cache was cold.

### Escalation: does baa46e3 resolve the deferred file-level carry-forward cost?

**Yes, measured on this repo.** At the skill's 14-day cadence, §2 shrinks from 17.5 KB to 7.1 KB (−60%) and the digest from 20.8 KB to 10.5 KB (−50%). That matches the ~60% predicted in the final-pass-1 finding. The set of printed records now equals the set whose trigger section changed, at all three window starts (3/3, 2/2, 1/1); de53069 printed 11, 11 and 10. The records are counted by name in the "Carried forward" line.

The 2026-09-26 bulk edit touched every record and still defeated de53069's first-parent check. It no longer causes a reprint.

The revisit condition in row 166 was "reprints more than half the records while fewer than a quarter of their trigger sections changed". On this repo baa46e3 is well clear of it: 2 of 11 printed, and exactly the changed ones.

The reduction also holds on the silent date fallback. A record with no `Main at:` line, or with the decorated form `- Main at: \`<sha>\``, gave the same 10,487 B and 2 records here. The fallback still compares trigger sections; it only moves the base. FC-B shows the fallback can pick the **wrong** base after an old-dated fast-forward. That is a correctness issue already routed to the api/correctness critics, not a size one.

**Residual:** about half of what remains in §2 at 14 days is log rows (8 rows, 3,467 of 7,069 B). They are still selected by date, not by text. See Finding 2.

Runtime got slightly faster: 0.19–0.23 s against 0.24–0.26 s warm. `bats test/scripts/dev-cycle.bats` passed 13/13 in 2.2 s, and no bats process was left behind.

## Findings

#### 1. Per-record `git show` + two `awk` + `cmp` (and a `git log` per printed record) are linear in trigger records

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:110-124` (lines 116, 118)
**Evidence:**
> `  if [[ $full -eq 1 || -z "$base" ]] || ! cmp -s <(git show "$base:$f" 2>/dev/null | trig) <(trig < "$f"); then`
> `    d="$(git log -1 --format=%ad --date=short -- "$f")"`
**Move:** Count the hidden multiplications; what's the size of N
**Classification:** Micro (about 5 forks per record, constant per record) / Cold path (once per dev cycle, CLI)
**Confidence:** High (measured)
**Legibility-target:** for-orchestrator-synthesis
**Baseline:** Measured 2026-09-30 in a clone of this repo. The comparison at line 116 costs 3.7 ms per record, and the whole digest takes 0.20 s with 11 records. At 311 records it takes 1.65 s when all are carried and 2.75 s when all print.

The comparison costs one `git show` (2.3 ms) plus awk and cmp for each record with a triggers section. A record that prints adds a `git log -1 -- "$f"`: 2.8 ms when it finds the file quickly, and 6.6 ms for a never-committed file. The never-committed case walks all 1,887 commits because the clone has no commit-graph. This log call is O(commits back to the file's last change), so its worst case grows with history. It is still single-digit milliseconds at this repo's size.

Total cost is O(records) with a small constant. The 311-record synthetic run adds about 5 ms per carried record and 9 ms per printed record. Cost is not the concern at that scale. Digest size is: 42 KB with 300 records printed. The per-record comparison is exactly what keeps that size down in normal cycles.

**Recommendation:** None needed. A batched alternative, such as one `git ls-tree`/`cat-file --batch` for all records, would remove N−1 `git show` forks. It is not worth the added lines while the unit sits at the 400-line cap.

#### 2. Log rows still carry forward by date, so they are about half of the residual §2

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:126-139` (line 130)
**Evidence:**
> `    if [[ $full -eq 1 || ! "$d" < "$SINCE" ]]; then`
**Move:** What's the size of N
**Classification:** Macro-ish for size (grows with log rows dated in the window) / Cold path
**Confidence:** High for the measured split; Medium on whether it matters
**Legibility-target:** for-author
**Baseline:** Measured 2026-09-30, 14-day window from 2026-09-16: the 8 printed log rows take 3,467 B of §2's 7,069 B (49%).

Decision records now print only when their trigger text changed. A log row prints whenever its date cell falls in the window, whether or not its "Revisit" clause is new or changed. In this repo the in-window rows are new rows, so every one needs a first verdict and this costs nothing in practice. It only becomes waste if rows get re-dated or bulk-edited. That is the same failure mode row 166 described for records, now confined to rows added in the window.

**Recommendation:** No change now. If a cycle digest shows log rows reprinting without their Revisit clause changing, compare each row's clause against `git show "$base:docs/decisions/log.md"` the same way line 116 does for records.

## Endorsements

- The trigger-section comparison (line 116) replaced the de53069 per-record `git log --first-parent --since` + `git status` pair. It is faster per record (3.7 ms against the 6.7 ms measured in final2) and it cut the 14-day digest from 20.8 KB to 10.5 KB in this repo. That the reduction generalises to other repos and cadences is submitted as a claim. [unverified — submitted as claim]
- The output filter is a single `tr` process that streams the whole of stdout, started once. There is no per-line or per-section fork. [read: scripts/dev-cycle.sh:42]
- The window-start lookup runs once per digest, not per record: 1.7–1.8 ms whether it takes the `merge-base --is-ancestor` path or the `rev-list -1 --before` fallback, even with `--before=2020-01-01`. [read: scripts/dev-cycle.sh:108-109; measured, see execution log §3]
- With `--since` or no earlier record (`full=1`), the `||` short-circuits past `git show`/`cmp` entirely. [read: scripts/dev-cycle.sh:97-103,116]
- The activity walks at lines 89 and 91 take 2.3 ms (14-day window) and 4.7 ms (all history) for the merge log, and 2.1 ms for `rev-list --count` over all history. These timings do not depend on whether the counts are correct, which FC-C disputes and which is not re-derived here. [read: scripts/dev-cycle.sh:89-91; measured, see execution log §3]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Per-record `git show`+awk+cmp (+`git log` when printed) linear in records: 3.7 ms/record; 1.65–2.75 s at 311 records | Informational | `scripts/dev-cycle.sh:116,118` | High |
| 2 | Log rows still carried by date; 49% of residual §2 at 14 days | Informational | `scripts/dev-cycle.sh:130` | High / Medium |

## Overall Assessment

baa46e3 resolves the deferred file-level carry-forward cost (override row 166, performance Medium), measured on this repo's real history. At the 14-day cadence it printed exactly the 2 records whose trigger text changed rather than all 11, and the digest halved to 10.5 KB. It is also slightly faster than de53069. Everything else is cold-path and linear with small constants: well under a second at 10× today's record count, and under 3 s at about 28×. Neither finding needs a change before merge. Row 166 can be marked resolved, and its strikethrough "Resolved in baa46e3" is consistent with these measurements. The residual size cost is log rows selected by date, which is harmless while rows are only ever appended.

## Goal-Alignment Note
- Success criterion (restated verbatim): "Success criterion: a markdown report saved at the path named below, structured per the skill."
- Answered: yes. I measured the escalation (resolved: 11→2 records printed and §2 −60% at 14 days) and covered lines 42, 89-91, 106-124 and 109, plus scaling to 311 records.
- Out of scope: the correctness of the fallback base (FC-B), of the activity counts (FC-C) and of the filter (FC-D), and the forged newline line (FC-A). They belong to the correctness, security and api critics and were not re-derived. No file was edited except this report and its execution log. Measurements ran only in a throwaway clone under the scratchpad.
- Escalate: to the orchestrator: the shared brief at `scratchpad/shared.md` describes a different review (run-tests `--jobs`, 088bc97, wt-run-tests-jobs). It looks overwritten by another session, so I took scope from the dispatch prompt. The success criterion above is quoted from that file. Also, row 166 can be closed on the measurements above.
- Decisions I made: I judged the escalation on the skill's 14-day cadence, with 7 and 28 days as bounds. I counted the fallback and decorated-line cases as "resolved" for size, since both still compare trigger sections.
