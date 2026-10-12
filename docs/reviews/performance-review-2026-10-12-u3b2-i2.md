Commit: cca66dc2

# Performance Review: feat/build-loop-u3b2 (`--main-log SINCE`), iteration 2 (fix range)

**Scope:** partial, fix range `1d829fee..cca66dc2`. The perf-relevant change is the per-merge `merge-tree --write-tree` in log_class (`scripts/build-loop.sh:1639-1642`); also the `main MAIN -` refusal lines (`:1677-1681`), `SUBJ=-` (`:1638`) and ANSWERS_AWK's counting change (`:1618-1619`)
**Date:** 2026-10-12
**Based on:** `docs/reviews/code-fact-check-report-2026-10-12-u3b2-i2.md` (Stage 1, its E5 timing: 8.01 s pre-fix and 9.95 s fixed for a root SINCE on a /workspace clone); my iteration-1 report `docs/reviews/performance-review-2026-10-12-u3b2-i1.md`

## Data Flow and Hot Paths

`--main-log` runs once per orchestrator iteration (warm, not hot). For each first-parent commit above SINCE, log_class reads the commit. The fix adds one step: **every** two-parent commit now runs `gate_git merge-tree --write-tree --no-messages P1 P2` and compares the result with the commit's tree. This happens before any subject test, at `:1639-1642`. gate_repo points the gate repository's `GIT_OBJECT_DIRECTORY` at the real repository's store (`:932`, comment `:921` "where it also writes"). So every merge-tree call writes any result objects that are not already there into the real store. When an object already exists, git freshens its file's mtime instead.

N, the number of commits in one iteration's window, is normally small (under 20). A merge stays in the window, and is merged again on every iteration, until the next cycle record moves SINCE past it.

**Measurements** (my probes, cwd under `/tmp/u3b2rv-perf2-*`, all removed afterwards; `LC_ALL=C`, `GIT_CONFIG_GLOBAL=/dev/null`; wall-clock from `$EPOCHREALTIME`; WSL2 host; one run each unless noted):

| Fixture | Script | Wall time | Loose objects written to the store |
|---|---|---|---|
| `git clone --no-local --single-branch --branch main /workspace` (1,119 first-parent commits, 422 of them merges, 3,427 paths; 1 pack, 20,300 objects), SINCE = root | pre-fix 1d829fee | 6.68 s, 6.78 s | 0 |
| same | cca66dc2 | 8.35, 8.43, 8.56, 8.64, 8.73 s | 87 (29 blobs, 58 trees, 616 KiB) on the first run; still 87 after four more runs |
| same | `mut2`: cca66dc2 with merge-tree run only when the subject matches the gate or the chore regex | 7.06, 7.12 s | 0 |
| same, plain git loop over the 422 merges | `git merge-tree --write-tree` per merge | 1.22 s total (about 2.9 ms/merge); 23 of 422 differ from the commit's tree or conflict | n/a |
| fast-import repo, 100,001 files; chore merge where main edits 1 file and the branch adds the record | pre / head / mut2 | 1.86 / 1.89 / 1.96 s | 0 |
| same plus 5,000 exact renames on the branch | pre / head / mut2 | 2.22 / 2.16 / 2.21 s | 0 |
| same plus 5,000 inexact renames (main edits only `d0/f0.txt`) | pre / head / mut2 | 2.27 / 2.20 / 2.13 s | 0 |
| 100,001 files; main modifies the 5,000 files the branch renames inexactly (rename detection is now relevant) | pre / head / mut2 | 2.26 / **7.61** / 7.71 s; merge-tree alone 5.47 s | 0 |
| 120,001 files; 20,000 inexact renames, both sides touching them (past merge.renameLimit) | pre / head / mut2 | 2.40 s `chore` / 2.57 s `other` / 2.61 s `other`; the fixture's own merge-tree rc 1 (conflict) in 0.28 s | 0 |

The stdout of cca66dc2 and mut2 was byte-identical on the /workspace clone (`cmp` exit 0). cca66dc2 and pre-fix also printed the same classes there (1,117 other and 1 answers). After each cca66dc2 or mut run, the pack file's mtime moved from a `touch -d 2020-01-01` to the run's time (e.g. `2026-10-12 16:05:41`). After the pre-fix run it stayed at `2020-01-01 00:00:00`.

## Findings

#### 1. merge-tree runs on every two-parent commit before the subject decides it could be gate or chore: about 1.5 s of a root SINCE on /workspace, and every loose object it writes

**Severity:** Low
**Location:** `scripts/build-loop.sh:1639-1642` (the check), `:1643` and `:1650` (the subject tests it runs ahead of)
**Move:** Count the hidden multiplications; find the work that moved to the wrong place
**Classification:** Micro (one extra git process per merge, plus ort's merge work) / Cold-to-warm path (once per iteration, N normally small)
**Confidence:** High
**Baseline:** 8.35-8.73 s (cca66dc2, 5 runs) against 7.06-7.12 s (subject-first mutant, 2 runs) for a root SINCE on a `--no-local` clone of /workspace main, 422 merges; measured by this review's probe 2026-10-12
**Legibility-target:** U3b2 implementer (log_class's ordering)

Evidence (`:1639-1643`):
```
  if [[ ${#ps[@]} -eq 2 ]]; then
    x="$(gate_git merge-tree --write-tree --no-messages "${ps[0]}" "${ps[1]}")" \
      && [[ "$x" == "$(LC_ALL=C awk '/^tree / { print $2; exit }' "$GATE_TMP/c")" ]] || return 0
  fi
  if [[ ${#ps[@]} -eq 2 && "$SUBJ" =~ ^Merge\ branch\ \'(.+)\'\ \(build-loop\ (self-merge|approved merge)\)$ ]]; then
```

A two-parent commit can only be gate or chore when its subject matches `:1643` or `:1650`. Any other merge reads as other whatever merge-tree says. The merge-tree is still computed first. On /workspace's history, 421 of the 422 merges match neither subject (the probe counted 1 `chore/dev-cycle-` subject and 0 `(build-loop ` subjects). That is where nearly all of the fix's added time comes from: about 1.5 s of about 8.5 s, consistent with the fact-check's E5 (8.01 s to 9.95 s). It is also where the store writes come from (Finding 2): the 23 hand-resolved or conflicting merges in that history wrote 87 loose objects. The subject-first mutant wrote none, and its output was byte-identical. In a normal iteration window this is a few milliseconds per merge (about 2.9 ms per call, plain git loop). So this is a cheap reordering, not a scaling problem.

**Recommendation:** Run the merge-tree check only after a subject matches. Either move it into the gate and chore branches (after `cmp` for gate, before the record read for chore), or guard it with the two subject regexes. Re-capture BASH_REMATCH after it, since `[[ =~ ]]` in the tree comparison does not reset it, but any regex guard added would. The output is unchanged, as the mutant showed.

#### 2. merge-tree writes the merge result of every non-clean merge into the real object store and freshens the pack's mtime on every run

**Severity:** Low
**Location:** `scripts/build-loop.sh:1640` (the write), `:932` (GIT_OBJECT_DIRECTORY = the real store), `:965-967` (store_check's comment)
**Move:** Trace the memory (storage) lifecycle; price the deployment environment
**Classification:** Micro (bounded, idempotent writes) / Cold-to-warm path
**Confidence:** High
**Baseline:** 87 loose objects (29 blobs, 58 trees, 616 KiB) written by the first cca66dc2 run over a /workspace clone's 422 merges, 0 more on four later runs; pack mtime moved on each cca66dc2 run and not on the pre-fix run; measured by this review's probe 2026-10-12
**Legibility-target:** U4 implementer and whoever maintains store_check's comment

Evidence (`:921`): `# object store (GIT_OBJECT_DIRECTORY, where it also writes). GATE_ENV unsets the`
Evidence (`:932`): `  GATE_ENV+=(GIT_DIR="$GATE_TMP/git" GIT_OBJECT_DIRECTORY="$v")`
Evidence (`:966-967`): `# between a check and a later read (R8's family, Q-103), which for main's` / `# objects spans the whole run, as they are re-hashed once. Reads the real` / `# repository's object store, as merge-tree writes into it. Needs GATE_TMP.`

Before this fix, --main-log wrote nothing to the store. Now it is a read mode that writes. For a clean merge whose tree is already committed, no new objects are written (0 in every honest fixture above). But git freshens the existing objects, so the pack file's mtime is bumped on every run. For a merge that does not match, either amended or hand-resolved (the case D1 exists to catch), the clean-merge result tree and its blobs are written as unreachable loose objects. For a conflicted merge, the blobs with conflict markers are written too. The ids are deterministic, so the volume is bounded: one copy per distinct merge, written once. Later runs only re-freshen them, which keeps them younger than gc's 2-week prune for as long as the merge stays in the window. In the expected window of one iteration, that is a few objects at most, and Finding 1's reordering removes all writes for merges whose subject cannot match. --merge already wrote this way (`merge_result`, `:1012`), so the design accepts it. My concern is the bookkeeping: store_check's "second copy" rule (`:950-954`) relies on git not writing a loose copy of an object it already has in a pack. Git checks for the object first, and I saw no duplicate (`count-objects` showed `prune-packable: 0`). I did not test a race with a concurrent repack.

**Recommendation:** No code change needed beyond Finding 1. Add a clause to the --main-log header or log_class's comment: "writes the clean merge of a two-parent commit into the object store (as --merge does)". That way U4 and anyone reading `--main-log` as a pure read know it is not one.

#### 3. One merge's merge-tree is bounded by ort's rename detection: 5.47 s for a 5,000-rename merge on a 100,001-file tree, paid again on every iteration while it is in the window

**Severity:** Informational
**Location:** `scripts/build-loop.sh:1640`
**Move:** What's the size of N? Check the asymptotic behavior
**Classification:** Macro (rename detection grows with the renamed paths both sides touch) / Cold path (pathological history, once per iteration)
**Confidence:** Medium (one run per fixture)
**Baseline:** 7.61 s cca66dc2 against 2.26 s pre-fix for N=1 (one chore merge: 100,001 files, 5,000 inexact renames on the branch, main modifying the same 5,000 files); merge-tree alone 5.47 s; measured by this review's probe 2026-10-12
**Legibility-target:** U4 implementer (window size and bootstrap SINCE)

Evidence (`:1640`): `    x="$(gate_git merge-tree --write-tree --no-messages "${ps[0]}" "${ps[1]}")" \`

On large trees, merge-tree is cheap unless renames are relevant. 100,001 files with 5,000 exact or inexact renames on one side cost nothing measurable, because ort skips detection when the other side did not touch the sources. When both sides touch the renamed paths, one merge costs seconds. That cost repeats on every iteration until SINCE moves past the merge. It is capped by merge.renameLimit (the gate repository reads no config, so git's default applies). Past the cap, inexact detection is skipped and the merge conflicted in 0.28 s. That read as `other`, while pre-fix read it as `chore`. It fails closed, but it is a false `other` for a merge git would also refuse to do cleanly. In this repository's history, all 422 merges together took 1.22 s, so this is a constructed worst case, not an observed one.

**Recommendation:** Nothing in U3b2. If U4 ever passes an old SINCE over a rename-heavy history, the cost lands here. Finding 1's reordering limits it to gate and chore merges, which are small by construction.

## Endorsements

- **The fix costs nothing measurable on a large tree for a typical chore merge.** With 100,001 files and only the record changed, it took 1.89 s against 1.86 s pre-fix. Nearly all of that is store_check of main, shared with --state, as in iteration 1. `[unverified — submitted as claim]` (one run each; not execution-verified by the fact-check report)
- **The merge-tree check is idempotent across iterations in the store.** Repeated root-SINCE runs wrote 87, then 0, 0, 0, 0 new loose objects. `[unverified — submitted as claim]` (measured here; not a fact-check verdict)
- **The refusal lines and `SUBJ=-` add no per-commit work.** `main MAIN -` is one echo on the two refusal paths, and `SUBJ=-` is one `[[ -n ]]` per commit. `[read: scripts/build-loop.sh:1638, 1674-1687]`
- **ANSWERS_AWK's counting change keeps it single-pass.** Only the increment's condition changed (`{ if (s == "+") n++; next }`). The per-hunk arrays and `flush` are unchanged, so iteration 1's 500,000-line measurement still applies. `[read: scripts/build-loop.sh:1600-1624]`

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | merge-tree runs on every merge before the subject test: about 1.5 s of an about 8.5 s root SINCE on /workspace, and all the store writes; subject-first ordering gives identical output | Low | `scripts/build-loop.sh:1639-1643`, `:1650` | High |
| 2 | --main-log now writes into the real store: 87 loose objects (616 KiB) for /workspace's mismatched merges, idempotent; the pack's mtime is freshened every run; undocumented in the mode's text | Low | `scripts/build-loop.sh:1640`, `:932`, `:965-967` | High |
| 3 | One rename-heavy merge costs seconds (5.47 s at 5,000 renames on 100,001 files), repeated per iteration; past the rename limit it conflicts and reads other | Informational | `scripts/build-loop.sh:1640` | Medium |

## Overall Assessment

The fix is performance-sound for --main-log's real use, a handful of commits per iteration. The merge-tree check adds about 3 ms per honest merge. It writes nothing new for a clean merge, and its writes for a mismatched merge are bounded and idempotent. The one improvement worth making now is Finding 1. Running merge-tree only after a gate or chore subject matches recovers most of the measured regression (about 8.5 s to about 7.1 s for a root SINCE on /workspace, against 6.7 s pre-fix). It also removes every store write for merges that could never count, with byte-identical output. Finding 2 is a documentation gap: a mode that looks like a read now writes into the store. Finding 3 is a constructed worst case bounded by git's rename limit. All numbers are single-machine measurements without a variance study.

## Goal-Alignment Note

Success criterion: "A performance review saved to docs/reviews/performance-review-2026-10-12-u3b2-i2.md in the worktree, per the performance-reviewer skill." This report is saved at that path. Its first line is `Commit: cca66dc2`. It follows the skill: a baseline on every finding, classification × path tags, a Legibility-target on every finding, verbatim evidence, and tagged endorsements.

It covers the brief's focus:
- the merge-tree's cost on large trees (Finding 3 and the 100,001-file rows);
- the objects it writes into the real store on each run (Finding 2: 87 objects, then 0);
- the repetition across iterations (Findings 2-3);
- the rest of the fix range (endorsements 3-4).

All probes used the `/tmp/u3b2rv-perf2-` prefix and were removed, and no process I started is left running. No finding blocks landing U3b2.
