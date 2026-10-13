Commit: 7a927183
Loop-pass short-circuit: used at 7a927183

# Code Review Rubric: feat/build-loop-u3b3 (U3b3, git_harden and the D6 snippet)

**Iteration 1 of 3** · scope: full branch `main...7a927183` (no prior rubric for this loop) · delivery mode: self-read (shared brief plus the saved diff) · fact-check k=1 (loop pass, decision 031), opus · report `docs/reviews/code-fact-check-report-2026-10-12-u3b3-i1.md` (48 claims: 37 Verified, 4 Mostly Accurate, 1 Stale, 3 Incorrect, 3 Unverifiable)

Loop-pass short-circuit: behavioural 🔴 confirmed at fact-check (claim: the snippet "trusts no file the uid can write"; executed probe P3 ran a planted build-loop.sh). Critics skipped this pass; the loop's one short-circuit is now used, so iteration 2 runs the full panel. No enforcement file in the diff (mechanic 7 does not apply).

Status (iteration 1): 🔴 1 · 🟡 1 · 🟢 5, all fixed in the iteration-1 fix commit (unreviewed until iteration 2). Single-sample review; absence of findings is not an attestation.

## 🔴 Must Fix

| ID | Finding | Source | Evidence | Status |
|---|---|---|---|---|
| A1 | The snippet hash-checks the four blobs against ids read from main's trees but never re-hashes the commit or trees: an in-place rewrite of the loose `scripts` tree object (main's ref unchanged) points ls-tree at planted blob ids, and the snippet runs the planted build-loop.sh (exit 0). store_check, which would catch it, runs inside the script the snippet already chose. The root-commit identity has the same gap: an in-place rewrite of a first-parent commit can make a non-claude-workflows repo's chain end at 640cf007 | fact-check claim (Incorrect, executed P3) | `test/lib/d6-snippet.bash` ls-tree / hash-object loop; header lines 10-14 | Fixed (main's first-parent commits and the trees down to scripts/lib/ re-hashed in one cat-file --batch pass; two tests, the tree one killed by a mutant that drops the check) |

## 🟡 Must Address

| ID | Finding | Source | Evidence | Status |
|---|---|---|---|---|
| A2 | The as-built note says the default branch must be "a commit", but the snippet peels `refs/heads/$m^{commit}`: a main naming an annotated tag passes, and dev-cycle.sh (which runs no default_gate) then runs through it (executed P4) | fact-check claim (Incorrect, behavioural vs doc) | `test/lib/d6-snippet.bash` sha line; plan note | Fixed (the ref's own object must be a commit; T36 case) |

## 🟢 Consider

| ID | Finding | Source | Status |
|---|---|---|---|
| A3 | Header says "T33 asserts the two match"; T33 has only a pending comment until U4 | fact-check (Incorrect, comment) | Fixed (header: pending until U4) |
| A4 | `build-loop-orchestrator.bats:50` still says "a count harden would misread" | fact-check (Stale) | Fixed |
| A5 | "a bash script body, not a function" (the file defines and calls `d6()`; what holds is that no function lands in the caller's shell) | fact-check (Mostly Accurate) | Fixed (plan note, header); commit a0014ce5 message immutable, left as is |
| A6 | "Every git call ... runs hardened" (build-loop.sh, lib header) omits the two deliberate exceptions: caller_gate's caller-count read and merge_ident's CALLER_GLOBAL | fact-check (Mostly Accurate) | Fixed (both comments name the two exceptions) |
| A7 | The snippet's Exit list omits the "names no commit" refusal and the failed-read / temp-dir refusals | fact-check (Mostly Accurate) | Fixed (Exit list) |

Unverifiable (no action): the zsh alias incident (session transcript), "refuses when run as root" (needs uid 0), the safe.directory note (needs another uid's repo).

## ⏭️ Skipped Core Critics

| Critic | Reason |
|---|---|
| security-reviewer | loop-pass short-circuit (behavioral red confirmed) |
| performance-reviewer | loop-pass short-circuit (behavioral red confirmed) |
| api-consistency-reviewer | loop-pass short-circuit (behavioral red confirmed) |
| architecture-review | loop-pass short-circuit (behavioral red confirmed) |

## 🧩 Composition check

No multi-source co-located clusters qualified (one source this pass).

## Considered overrides

Rows 200, 281, 311, 495, 505, 644, 648, 666, 702, 704, 709 (keyed to this unit; the plan's as-built note discharges or closes them), 509 and 548 (Q-103 residuals). A1 is not covered by any: row 509 is a race on the gate's own temp dir, and the U3a1 rows treat in-place rewrites only behind store_check's re-hash, which the snippet runs before.
