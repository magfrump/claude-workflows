Commit: 3d2d8c44
# Code Fact-Check Report

**Repository:** claude-workflows
**Scope:** `git diff main...HEAD -- scripts test` on `feat/build-loop-u2b3a` (final confirming pass), plus the plan's U2b3 bullet for claims
**Checked:** 2026-10-08
**Total claims checked:** 36 clusters (r1 34, r2 30, r3 42 claims before clustering)
**Summary:** 34 Verified, 2 Mostly accurate, 0 Stale, 0 Incorrect, 0 Unverifiable
**Commit:** 3d2d8c44
**Replication:** k=3

Merged most-severe-wins from `code-fact-check-report-build-loop-u2b3a-final-r1.md`, `-r2.md` and `-r3.md` (all at `Commit: 3d2d8c44`). Only the clusters where a replicate's verdict was not Verified, or where a replicate attached an annotation, are written out below; every other cluster was Verified by all replicates that surfaced it, and its evidence is in the replicate reports.

## Claim 1: import_targets "returns 1 ... when ROOT_REAL is empty"

**Location:** `scripts/lib/dev-cycle-read.sh:701-702`
**Type:** Behavioral
**Statement:** "It returns 1 when sed, python3, awk or import_home fails, when ROOT_REAL is empty, ..."
**Verdict:** Mostly accurate
**Confidence:** High
**Evidence:** r3 probe P5: after import_readers ran with ROOT_REAL empty (it skips the blank first entry and memoizes the registry's roots under that key), a later import_targets call with ROOT_REAL still empty takes a registered worktree as its first root and returns 0. Both walks call need_root first, which exits on an empty ROOT_REAL, so no caller reaches it.
**Verification mode:** executed
**Scope:** covers import_targets called after import_readers outside a walk; does not establish any walk-reachable path.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Mostly accurate · single-replicate detection
**Replicate annotations:** r3: "word it as an empty first reader root, or have import_readers refuse an empty ROOT_REAL"
**Legibility-target:** for-author

## Claim 2: the per-file work bound costs "about 0.1-5 s here with one root and about 9 s with 24"

**Location:** `scripts/lib/dev-cycle-read.sh:629`
**Type:** Performance
**Statement:** "the unit of its per-file bound of 50,000,000, about 0.1-5 s here with one root and about 9 s with 24, by the name's shape"
**Verdict:** Mostly accurate
**Confidence:** Medium
**Evidence:** Upper ends held in every replicate (r1 1.7 s and 7.8 s; r2 0.18-2.9 s and 7.5 s; r3 5.3 s and 9.3 s). r1 measured a single long `@` run spending the bound in 28 ms, below the stated low end; the low end was already in main's "0.1-4 s".
**Verification mode:** executed
**Scope:** covers the shapes each replicate timed; the low end is informational (only the upper end bounds cost).
**Replicate verdicts:** r1=Mostly accurate · r2=Verified · r3=Verified
**Replicate annotations:** r3: "the 0.1 s low end was not measured (every shape timed was heavy)"
**Legibility-target:** for-author

## Claim 3: over /workspace both walks give main's 128 names; a cached isimported takes about 3 ms; honest work about 330,600 (8,200 with one root); near 570 roots spends the bound

**Location:** `scripts/lib/dev-cycle-read.sh:631-635`, plan and commit messages
**Type:** Performance
**Statement:** as above
**Verdict:** Verified
**Confidence:** High
**Evidence:** all three replicates: 24 roots, 128 names equal to main's set; 330,570 work (8,240 at one root); cached isimported 2.9-3.5 ms; r1 fit 130R² + 12,070R − 33,990 (bound at ~576 roots), r2 pass at 560 and fail at 580, r3 pass at 580 with shorter roots (~585).
**Verification mode:** executed
**Scope:** covers /workspace at 3d2d8c44; the exact limit moves with root length.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: "from a gate worktree both walks give 64 names, not 128: the other 64 come from /workspace/devcontainer-config/claude-home/CLAUDE.md, a gitignored start that exists only in /workspace's checkout; none is a tracked path (U2b3b's outside-starts gap)" · r3: "test 7 (worktree path holding a newline) also passes on 5516c6e6: it guards only against a regression to main"
**Legibility-target:** for-orchestrator-synthesis

## Claim 4: import_targets outside a walk with a HOME holding a newline

**Location:** `scripts/lib/dev-cycle-read.sh:929-933`
**Type:** Behavioral
**Statement:** import_readers reads a home holding a newline as empty (fails only a ~/ name)
**Verdict:** Verified
**Confidence:** High
**Evidence:** inside a walk, a ~/ name fails (exit 1, test 6); outside a walk, import_targets uses the raw IMPORT_HOME pair and a newline HOME splits into an absolute first line, so a ~/ name resolves (r2 observation; no caller reaches it).
**Verification mode:** executed
**Scope:** covers both paths; the standalone path is the deferred row "import_targets falls back to ROOT_REAL alone" (architecture i2 N3).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "outside a walk a newline HOME resolves ~/ under its first line instead of failing"
**Legibility-target:** for-orchestrator-synthesis

## Escalations

- `dev-cycle-read.sh:701-702` (r3) → orchestrator: claim 1's wording or a guard in import_readers.
- Gate worktree vs /workspace name counts (r1) → orchestrator: a checkout-only gitignored start in another worktree is not walked; route to U2b3b's named exceptions.

## Verdict stability

36 clusters; 34 agreed (all reporting replicates Verified); 2 disagreed: claim 1 (r1=Verified · r2=Verified · r3=Mostly accurate) and claim 2 (r1=Mostly accurate · r2=Verified · r3=Verified). Agreement rate 94%.

## Goal-Alignment Note
- Success criterion (restated verbatim): A merged k=3 report at docs/reviews/code-fact-check-report-build-loop-u2b3a-final.md.
- Answered: yes
- Out of scope: U2b3b, U2c, settled override rows.
- Escalate: the two entries above.
