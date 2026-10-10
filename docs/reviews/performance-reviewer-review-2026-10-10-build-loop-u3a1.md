Commit: 65007bf8

# Performance Review: feat/build-loop-u3a1 (iteration 1)

**Scope:** `git diff main...HEAD` (base d5736445, HEAD 65007bf8): `scripts/build-loop.sh` (store_check, gate_start, status_fields, check_line) and one test in `test/scripts/build-loop-check.bats`
**Date:** 2026-10-10
**Based on:** `docs/reviews/code-fact-check-report-build-loop-u3a1.md` (Stage 1, k=1, 0 Incorrect; Claim 20 times store_check on main at 0.236 s and says it "does not establish the time ... for the per-brief tip/merge calls")

## Data Flow and Hot Paths

`--check BRIEF...` is a CLI run by the orchestrator, and by a loop as an advisory dry run. It starts once (`gate_start`, `:818-824`) and then runs `check_line` once per brief argument (`:913-918`). D9 caps the running loops at 1 to 9 slots (default 3), so N, the number of briefs in one run, is small. **Path temperature:** gate_start is cold (once per run). check_line is a per-item loop, but N is at most about 10, so it is warm at most. No finding here reaches the hot-path gate for High.

New work per run:
- `gate_start`: `store_check "$MAIN_SHA"` lists main's tree (`ls-tree -r -t`), deduplicates the ids with awk, inflates every object with one `git cat-file --batch`, and re-hashes each one in perl (Digest::SHA).
- `check_line`, per brief that reaches a merge tree: `store_check "$sha" "$tree"` (`:879`) does the same over the tip's whole tree and the merge result's whole tree. The deduplication covers only the ids within that one call.

Removed work per brief: `check_line` no longer runs `status_line` in a `$(...)` subshell, no longer re-runs `check_branch` (about 6 git forks), and no longer re-reads the brief (`brief_fields`, one `cat-file` plus awk) for a self-merge brief.

Measurements, all read-only against /workspace's object store (pack only, nothing written). The probe is store_check extracted verbatim from `:594-610` into a scratch file and run under `bash` with `LC_ALL=C`. Scripts and logs are in `scratchpad/u3a1-i1/performance/`. The machine is shared, so treat these as order-of-magnitude figures.

| Measurement | Result |
|---|---|
| main d5736445's tree | 3,691 entries, 3,581 objects; blob bytes 67,853,429 (largest blob 2,206,820 B, `runs/review-arms/e7-fable-3x/mfc-corpus/rep3/transcript.jsonl`) |
| `store_check $MAIN` | 0.246 / 0.245 / 0.238 s; child max RSS about 43 MB |
| `store_check $TIP $MAIN^{tree}` (a brief's shape: the u3a1 tip, plus main's tree standing in for the merge tree) | 0.240 / 0.237 / 0.237 s |
| Cost breakdown for main | ls-tree plus awk 0.004 s; plus `cat-file --batch` 0.199 s; plus perl 0.237 s. Inflating the objects dominates, and that cost scales with blob bytes, not with object count |
| Objects in the u3a1 tip's tree that are not in main's (`diff-tree -r -t`, non-null new side) | 5 |
| The same per-brief listing with main's verified ids pre-seeded into the awk set | 8 objects left to read, 239,967 bytes of cat-file output, 0.010 s |
| The removed check_branch re-read (its 6 git calls) | 0.059 s for 10 repetitions, about 6 ms per brief |
| Size of main's tree over time (entries, blob bytes) | 2026-07-10: 348, 3.0 MB; 2026-08-10: 654, 8.9 MB; 2026-09-10: 1,231, 33.4 MB; now: 3,691, 67.9 MB. The largest top-level directories are `docs/` (35.6 MB) and `runs/` (26.6 MB) |

## Findings

#### F1. The per-brief store_check re-hashes every object of main's tree that the tip and merge trees share with it, objects gate_start already re-hashed in the same run

**Severity:** Low
**Location:** `scripts/build-loop.sh:879` (call), `scripts/build-loop.sh:594-610` (store_check)
**Move:** Count the hidden multiplications; work that moved to the wrong place
**Classification:** Macro (the cost scales with the whole repository's blob bytes, not with the brief's change) / warm path (once per brief, with N at most about 10)
**Confidence:** High (measured)
**Baseline:** 0.237 s per `store_check $TIP $MAIN^{tree}` call on /workspace d5736445, measured 2026-10-10 (3 runs; probe in `scratchpad/u3a1-i1/performance/`)

Evidence (store_check, whole function):

```bash
store_check() {
  local r alg
  case "$(git rev-parse --show-object-format)" in sha1) alg=1 ;; sha256) alg=256 ;; *) return 1 ;; esac
  # One object name per line, each once.
  { for r in "$@"; do
      printf '%s\n' "$r" "$r^{tree}"
      git ls-tree -r -t --full-tree --format='%(objecttype) %(objectname)' "$r" | awk '$1 != "commit" { print $2 }' || exit 1
    done; } | awk '!seen[$0]++' | git cat-file --batch \
    | env LC_ALL=C ALG="$alg" perl -e 'use Digest::SHA; binmode STDIN; my $n = 0;
      [... the perl loop, :603-609, reads and re-hashes each object whole ...]
      exit($n ? 0 : 1)'
}
```

and the per-brief caller:

```bash
  # The tip's objects and the merge's, re-hashed (main's were, in gate_start).
  if ! store_check "$sha" "$tree"; then echo "refuse $a: an object of $br's tip or of its merge does not hash to its id, or could not be read"; return; fi
```

The `seen` set is local to one awk process, so it deduplicates the tip's tree against the merge's tree. It does not deduplicate either of them against the main objects that gate_start's call already verified. A branch tree is main's tree plus a few changed paths (5 objects for this branch), so each brief re-inflates and re-hashes about the whole of main again: 0.237 s, against 0.010 s when main's ids are pre-seeded. A `--check` of N briefs therefore costs about 0.24 × (N + 1) s in store_check alone, which is 0.96 s at the default 3 slots and 2.4 s at 9. That is on top of checkout_gate's existing "about 0.3 s ... times the self-merge briefs" (`:885-886`).

The cost scales with main's blob bytes, and those have roughly doubled every month: 3 MB, then 9 MB, then 33 MB, now 68 MB. Committed run transcripts under `runs/` are 27 MB of that. If the trend holds, the per-call cost passes 1 s within about two months, and the per-brief multiple multiplies it. For a CLI run by hand or by the orchestrator this is a cost, not a failure, so the severity stays Low.

Skipping the shared ids does not change what the check covers. An id that gate_start verified names the same object for the rest of the run, and a rewrite after that point is the race the comment already leaves to Q-103. The security reviewer should confirm that. One case does reopen: a loose and a packed copy of one id, where git could read a different copy later. That is the same residual as the existing race.

**Recommendation:** Have gate_start's call keep the id list it verified (for example `$GATE_TMP/checked`, holding resolved hex ids rather than `REV^{tree}` names), and have the per-brief call filter its list against that file before cat-file: `awk 'NR==FNR { seen[$0] = 1; next } !seen[$0]++' "$GATE_TMP/checked" -`. The per-brief cost then follows the brief's diff (measured 0.010 s), and the full-tree listing stays, so coverage does not depend on diff-tree. If the full re-hash per brief is meant to be deliberate, defence in depth against a mid-run rewrite, the code should say so. Today's comment (`:878`) implies main's objects are not re-checked.
**Legibility-target:** for-author

#### F2. store_check's cost grows with the whole repository, and the growth is fast

**Severity:** Low
**Location:** `scripts/build-loop.sh:822` (`store_check "$MAIN_SHA"` in gate_start)
**Move:** Ask "what's the size of N?"
**Classification:** Macro (linear in main's blob bytes) / cold path (once per `--check` run)
**Confidence:** Medium (the trend is measured from four points; the forecast is an extrapolation)
**Baseline:** 0.236 to 0.246 s per call for 67.9 MB of blobs on /workspace d5736445, measured 2026-10-10 (this review, 3 runs; the fact-check's Claim 20 measured 0.236 s)

Evidence:

```bash
  store_check "$MAIN_SHA" || { echo "refuse state objects: the default branch's commit or an object of its tree does not hash to its id, or could not be read"; exit 2; }
```

Every file of main is inflated and hashed on every `--check`, including runs where every brief skips, and including each advisory run by a loop. Inflating is about 85% of the cost (cat-file 0.199 s of 0.237 s). The cost scales with blob bytes, and the decision reads only a few KB of them: settings, briefs, and walk targets. The commit's own note ("store_check checks whole trees (0.3 s for main here) rather than each read") makes this trade-off on purpose. The trade-off is sound today. It ties the gate's fixed cost to how much data the repository holds, which this repository grows by roughly 2x a month.

**Recommendation:** No change in this unit. Record the growth figure next to the plan's "68 MB here: 0.3 s" (`docs/working/plan-build-loop-handoff.md:317`) as a revisit trigger, for example re-measure when main's blob bytes pass 250 MB or the call passes 1 s. U3a2's `--merge` re-runs check_line's steps, so it should not add a second whole-main pass on top of this one.
**Legibility-target:** for-orchestrator-synthesis

#### F3. perl holds each object whole in memory, so peak memory is set by the largest blob

**Severity:** Informational
**Location:** `scripts/build-loop.sh:605` (inside store_check's perl, `:602-610`)
**Move:** Trace the memory lifecycle
**Classification:** Micro / cold path
**Confidence:** Medium
**Baseline:** about 43 MB child max RSS per store_check call on /workspace (largest blob 2.2 MB), measured 2026-10-10. Attributing that RSS to git or to perl was not measured.

Evidence:

```perl
        read(STDIN, my $b, $s) == $s && (getc(STDIN) // "") eq "\n" or exit 1;
        Digest::SHA->new($ENV{ALG})->add("$t $s\0", $b)->hexdigest eq $id or exit 1;
```

`$b` holds one object at a time and is reused, so memory does not accumulate across objects. The peak is the largest object, which is 2.2 MB today. A large file committed to main, such as a multi-hundred-MB transcript or dataset, would be held whole by perl during every `--check`. The awk `seen` set is about 3.6k ids, which is negligible.

**Recommendation:** None needed now. If large blobs become plausible, read in fixed-size chunks (`read` of 1 MB at a time into `->add`) so the peak no longer depends on object size.
**Legibility-target:** for-orchestrator-synthesis

## Endorsements

- gate_start runs main's store_check once per run, not "at the start of each check_line" as the plan's U3 split note had it (`docs/working/plan-build-loop-handoff.md:317`). That keeps main's whole-tree pass out of the per-brief loop. [read: scripts/build-loop.sh:818-824, :910-918]
- status_fields runs in the caller's shell and check_line reads STATUS. The `$(status_line ...)` subshell, the second `check_branch` (about 6 git forks, roughly 6 ms per brief as measured above) and the self-merge brief re-read (`brief_fields`: cat-file plus awk) are gone from each brief's path. [read: scripts/build-loop.sh:841-848 and the removed lines in the diff; scripts/lib/dev-cycle-read.sh check_branch, brief_fields]
- store_check reads each call's objects in one `cat-file --batch` stream into one perl, not one process per object, so the per-object cost is a pipe read, not a fork. [read: scripts/build-loop.sh:594-610]
- The moved blob batch-check (`:874-877`) is still one `cat-file --batch-check` per brief, so moving it ahead of checkout_gate changes no cost. [read: scripts/build-loop.sh:870-879]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | The per-brief store_check re-hashes main's shared objects (about 0.24 s × N; 0.010 s with main's ids pre-seeded) | Low | `scripts/build-loop.sh:879`, `:594-610` | High |
| 2 | The whole-main re-hash cost tracks main's blob bytes (about 2x a month) | Low | `scripts/build-loop.sh:822` | Medium |
| 3 | perl's peak memory is set by the largest blob | Informational | `scripts/build-loop.sh:605` | Medium |

## Overall Assessment

The change trades correctness for a fixed cost that is acceptable today. It adds about 0.24 s per run for main, plus about 0.24 s per brief, against a few milliseconds saved per brief by the removed re-reads. The only structural issue is F1. The per-brief call re-verifies the whole of main again because its dedup set does not span calls. Seeding the per-brief awk with gate_start's verified ids fixes it in place: one file and one awk argument, measured to cut the per-brief call from 0.237 s to 0.010 s, with no loss of coverage beyond the existing Q-103 race. Nothing here blocks the merge. F2 is a revisit trigger, given how fast main's tree is growing. No further profiling is needed to act on F1.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the path your dispatch names, structured per your skill.
- Answered: yes. I measured store_check's per-call cost on main and per brief, its memory, how it scales with repository size and with N, the awk dedup's scope, and the status_fields saving.
- Out of scope: whether skipping already-verified ids is sound against a loose-copy and packed-copy split (a security-reviewer call). Correctness of store_check's failure paths (the fact-check's Claims 9-11).
- Escalate: F1's fix is a small, safe in-place change worth taking in this loop. The security reviewer should confirm that seeding from gate_start's ids keeps the coverage claim.
- Decisions I made: I treated `--check` as warm, not hot, because D9 caps N at 9 slots, so I capped severities at Low. I used main's tree as the stand-in for a merge tree in the per-brief timing, since a real merge tree differs from main by only a few objects.
