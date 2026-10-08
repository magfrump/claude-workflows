Commit: 63ea50e7

# Performance Review — feat/build-loop-u2b1a2 (`build-loop.sh --check`, final confirming pass)

**Scope:** `git diff feat/build-loop-u2b1a1...HEAD` (HEAD 63ea50e7): `scripts/build-loop.sh` (harden, state_gate, gate_repo, merge_result, check_line, the `check` mode), read with `scripts/lib/dev-cycle-read.sh` check_branch (:436-451)
**Date:** 2026-10-08
**Based on:** the shared brief's Stage 1 summary (code-fact-check-report-build-loop-u2b1a2-final-r{1,2,3}.md); iteration 2's docs/reviews/performance-reviewer-review-2026-10-08-build-loop-u2b1a.md (at 9e5d92df) as the baseline; override-log row 500

## Data Flow and Hot Paths

Unchanged from iteration 2: `--check BRIEF...` runs once per orchestrator iteration over a handful of briefs. Path temperature: **cold** (per loop iteration, not per request; nothing waits on it with a latency budget). What changed since 9e5d92df, for performance:

1. `harden` adds `core.commitGraph=false` to every git call in every mode (`--status` and `--settings` too, not only `--check`).
2. `gate_repo` runs once per process (3 git calls + `mkdir`), replacing the per-brief `rev-parse --git-common-dir` and `mktemp -d`; merge-tree now runs through `env` in the gate's git dir with `GIT_OBJECT_DIRECTORY` set to the real store.
3. `state_gate` adds `shallow` and a `symbolic-ref` for origin/HEAD (+2 calls, once per process).
4. `GIT_ALLOW_PROTOCOL=none` (an environment variable; no spawn).

**Measurements** (this session, 2026-10-08, scratch `/tmp/perfu2b1a2-uhfd`). Setup: a `--no-hardlinks` clone of /workspace main (2,326 commits, 3,118 files, commit-graph chain present and rewritten after setup), six open briefs committed on main: five branches each forked from `main~150` with one commit plus `handoff: ready`, and one (`feat/old`) forked from the root commit. The three scripts compared are extracted with `git archive` from 9e5d92df, from 63ea50e7, and from 63ea50e7 with only ` core.commitGraph=false` removed from harden's list (`nocg`). git 2.39.5, WSL2, load average about 1.2 to 1.4. All runs gave identical output lines (same TIP and TREE).

| Run (10-run means) | 9e5d92df | 63ea50e7 | 63ea50e7 minus commitGraph=false |
|---|---|---|---|
| `--check` 5 briefs (base main~150) | 344 / 371 ms | 418 / 438 ms | 338 / 339 ms |
| `--check` 6 briefs (+ root-based) | 403 / 408 ms | 530 / 558 ms | 409 / 435 ms |
| `--status` 6 briefs | 314 / 318 ms | 353 / 354 ms | 311 / 343 ms |
| `--check` 1 brief (main~150) | 141 ms | 157 ms | 156 ms |
| `--check` 1 brief (root-based) | 141 ms | 191 ms | 147 ms |
| git calls, `--check` 5 briefs (PATH shim) | 157 | 157 | 157 |

So `--check` costs about +75 ms (5 briefs) to +135 ms (6 briefs, one old) per run over iteration 2, about +20 to +35%, and nearly all of it is `core.commitGraph=false`; the gate_repo restructuring is call-count neutral at 5 briefs (−5 `--git-common-dir`, +3 gate_repo calls, +2 state-gate calls) and saves one spawn plus one `mktemp` per brief beyond that. `--status` pays about +35 ms for 6 briefs (one walk per brief).

Per-call shim timings, one root-based brief, 63ea50e7 vs `nocg`: `rev-list --count MAIN..TIP` 20.4 ms and 20.3 ms (status_line's and check_line's reads) vs 2.0 ms each; `merge-tree --write-tree` 23.0 ms vs 2.2 ms. For a main~150 brief: 7.8 ms, 7.9 ms, 9.0 ms vs 1.7, 1.8, 1.8 ms. Direct timings in the clone: `rev-list --count` from main~2 1.1 ms either way; from main~20 2.3 ms off vs 1.2 ms on; root-based 18.6 ms off vs 1.4 ms on; `merge-base` root-based 20.6 ms off vs 1.4 ms on. In a synthetic 20,000-commit linear repository (fast-import, a branch off commit 10): `rev-list --count` 47.6 ms off vs 5.2 ms on, `merge-tree --write-tree` 47.9 ms off vs 4.7 ms on; `git commit-graph verify` 20.3 ms in the clone and 53.9 ms in the synthetic repository.

## Findings

#### F1: core.commitGraph=false turns each brief's three ancestry walks into O(main's commits since the branch's base) object parses

**Severity:** Low
**Location:** `scripts/build-loop.sh:160` (in `harden`, :158-164); paid at `scripts/lib/dev-cycle-read.sh:447` (twice per brief: status_line's check_branch and check_line's re-read at `scripts/build-loop.sh:477`) and `scripts/build-loop.sh:463`
**Move:** Work moved to the wrong place (a precomputed index switched off; the walk now happens per call) / asymptotic behavior
**Classification:** Macro (cost grows with history depth between main and the branch base, not with call frequency) / Cold path (once per brief per loop iteration)
**Confidence:** High
**Baseline:** `--check` over 6 briefs 530-558 ms at 63ea50e7 vs 403-408 ms at 9e5d92df and 409-435 ms with only this pair removed (10-run means, 2026-10-08 benchmark above); a root-based brief's three walks cost 63.7 ms vs 6.2 ms with the graph.
**Legibility-target:** for-author
**Evidence:**
```
  for kv in core.useReplaceRefs=false core.hooksPath=/dev/null core.fsmonitor=false core.attributesFile=/dev/null core.commitGraph=false; do
```
```
    elif n="$(git rev-list --count "$MAIN_SHA..$sha" 2>/dev/null)" && [[ "$n" =~ ^$DIGIT+$ ]] \
```
```
  out="$(cd "$GATE_TMP/work" && "${GATE_ENV[@]}" git merge-tree --write-tree --no-messages "$MAIN_SHA" "$1" 2>/dev/null)" || rc=$?
```

The pair is the iteration-2 fix for rubric A7 (a forged commit-graph changing merge bases), and the pair also reaches merge-tree in the gate repository, because GATE_ENV keeps `GIT_CONFIG*` (so iteration 2's F3 advice, "keep `GIT_OBJECT_DIRECTORY` on the real store so the commit-graph still speeds merge-base", no longer buys anything; the measured 23.0 ms merge-tree confirms it). Without generation numbers each of `rev-list --count MAIN..TIP` (twice) and merge-tree's merge-base parses every main commit back to the branch's base: about 1 ms for a fresh branch, 8 ms for a main~150 base, 20 ms for a root base at 2,326 commits, and about 48 ms per call at 20,000 commits. It grows linearly with history: a brief whose branch has fallen far behind costs about 3 × (8 µs per commit here) per check, so at 10× today's history an old-base brief would cost roughly 0.5 s per iteration. It is cold-path and bounded by history size (no DoS shape), so Low. The `--status` and `--settings` modes pay it too (one walk per brief for `--status`), though they decide nothing; that is a side effect of setting the pair in `harden` for every mode.

**Recommendation:** Keep the pair (it is a security fix; this is its price, not a defect) and record the number. If the price matters later, two cheaper shapes exist: (a) cut the walks from three to two per brief by taking the ahead count from status_line's read and re-checking only the tip in check_line (F2); (b) let the security owner decide whether `git commit-graph verify` once per process (20 ms here, 54 ms at 20,000 commits, O(all commits) regardless of base) and then using the graph is acceptable. It reads every commit once instead of up to three walks per brief, but it adds a verify-then-use window the security reviewer would have to price. Do not change it for this unit.

#### F2: check_line's re-read now repeats a history walk, so override row 500's "about 9.8 ms per brief" price is stale

**Severity:** Low
**Location:** `scripts/build-loop.sh:477-480` (in `check_line`, :470-488); callee `scripts/lib/dev-cycle-read.sh:436-451`
**Move:** Hidden multiplication
**Classification:** Micro in call count (6 extra spawns) but now Macro in cost (one of them is the O(history) walk from F1) / Cold path
**Confidence:** High
**Baseline:** the re-read's `rev-list --count` took 20.3 ms for the root-based brief and 7.9 ms for a main~150 brief at 63ea50e7, against 2.0 and 1.8 ms at 9e5d92df's configuration (PATH-shim timings, 2026-10-08 benchmark above).
**Legibility-target:** for-orchestrator-synthesis
**Evidence:**
```
  out="$(check_branch "$br")"
  read -r _ _ _ n _ <<<"$out"
  if [[ "$out" != "ok $br $sha "* || ! "$n" =~ ^$DIGIT+$ ]]; then echo "refuse $a: its branch $br moved or could not be read again"; return; fi
  if [[ "$n" -eq 0 ]]; then echo "refuse $a: its branch $br has no commit the default branch lacks"; return; fi
```

Override-log row 500 settled iteration 2's F1 as Won't-Fix on the premise that the re-read costs about 9.8 ms per brief ("The re-read is deliberate (the tip can move between the two reads)"). That reason still holds, but the price changed: with the commit-graph off, the re-read's `rev-list --count` walks main's history again, so the re-read now costs 15 to 30 ms per brief here and grows with history. The tip-moved check itself needs only `show-ref --verify --hash` plus the `^{commit}` peel (about 3 ms); the walk is there only because status_line's printed line drops `ahead`. This is a re-pricing of a settled row, not a new disposition: the decision is the orchestrator's.

**Recommendation:** Optional, at the author's or orchestrator's discretion: update row 500's figure, or keep the re-read's tip check and take `n` from status_line's own check_branch read (the row-496 `status_fields` refactor at U3's `--merge` is the natural place). Either way the walk count per brief goes from three to two.

## Endorsements (evidence-gated)

- gate_repo's once-per-process setup keeps `--check`'s spawn count flat while dropping per-brief work: 157 git calls for 5 briefs at both 9e5d92df and 63ea50e7, with `rev-parse --git-common-dir` ×5 replaced by `rev-parse --local-env-vars`, `--git-path objects` and `--show-object-format` once, and `mktemp -d` no longer per brief. `[unverified — submitted as claim]`
- Without the commitGraph pair, the new gate repository adds no measurable cost: the `nocg` variant ran 5 briefs in 338-339 ms against 9e5d92df's 344-371 ms, and merge-tree in the gate's git dir took 2.2 ms for a root-based brief, about what iteration 2 measured in the real git dir (2.1 ms). `[unverified — submitted as claim]`
- `GIT_ALLOW_PROTOCOL=none` and the two added state-gate checks (`shallow`, `symbolic-ref` for origin/HEAD) are environment or once-per-process costs (2 spawns, about 3 ms), not per brief. `[read: scripts/build-loop.sh:166, 181-203]`
- The fact-check's executed verdict that every --check call carries harden's pairs is what makes F1's cost apply to merge-tree in the gate repository as well as to the real repo's calls. `[fact-check: Stage 1 "Verified (executed): every call carries harden's pairs and exports" — verified]`

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | core.commitGraph=false makes each brief's 3 ancestry walks O(main's commits since base): `--check` +75 ms (5 briefs) to +135 ms (6, one root-based) over 9e5d92df; ≈48 ms per walk at 20k commits | Low | `scripts/build-loop.sh:160` (paid at `dev-cycle-read.sh:447`, `build-loop.sh:463`) | High |
| 2 | check_line's re-read now repeats a history walk (8-20 ms here, growing with history), so override row 500's 9.8 ms price is stale | Low | `scripts/build-loop.sh:477-480` | High |

## Overall Assessment

The delta since iteration 2 is one price: `core.commitGraph=false` raises `--check` from about 345 to 430 ms for 5 briefs and from about 405 to 545 ms when one brief's branch sits on an old base, and it raises `--status` by about one walk per brief. Everything else in the unit (gate_repo once per process, the gate repository, the protocol block, the extra state-gate checks) is call-count neutral or saves work per brief. The commitGraph cost is linear in the history between main and each branch's base. It stays cold-path and bounded, so it is Low and fine to land. The one thing worth recording is the new number, both for F1's security trade and for row 500's re-read price. Nothing needs profiling beyond what is measured here.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the path your task names, structured per your skill, with a `Commit: 63ea50e7` line at the top.
- Answered: yes
- Out of scope: the security merit of the commit-graph pair and of a verify-then-use alternative (security reviewer's); merge_result's exit-0-with-missing-tree behavior and the vacuous submodule and partial-clone tests (Stage 1's, not re-reported); iteration 2's settled F2-F4 (row 500).
- Escalate: nothing
