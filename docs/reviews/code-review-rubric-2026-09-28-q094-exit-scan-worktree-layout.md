# Code Review Rubric: q094-exit-scan-worktree-layout

**Commit:** 5a6d689 (iteration 1 reviewed); fixes in the iteration-1 fix commit
**Scope:** `main...HEAD` (dfe4c0d..5a6d689): `devcontainer-config/cc-exit-scan.sh`, `guides/cc-isolated-usage.md`, `test/cc-isolated-functions.bats`, plan doc
**Iteration:** 1 of 3 (`--loop-pass`, fact-check k=1 per decision 031)
**Delivery mode:** self-read (a prepared diff file, plus the files it touches)
**Status:** 🔴 → fixed in iteration-1 fix commit; iteration 2 pending

## 🔴 Must Fix

| # | Source | Finding | Location | Status |
|---|---|---|---|---|
| R1 | performance-reviewer (Medium, measured), promoted: breaks the tripwire's fail-closed contract | `printf \| grep -q` under the launcher's `set -o pipefail`: an early match SIGPIPEs printf, so the pipeline reads as "no match". The W refusal (`:807`) then **fails open** on large snapshots (>~128 KiB of records after the match). Only the second SIGPIPE at `:812` hid this. Same pattern pre-existing at `:939` (the `invalid` check) | `cc-exit-scan.sh:807, :812, :939` | Fixed: `[[ ]]` pattern matches; test with 40k padding records, under pipefail, in both directions (a mutation reverting either check fails it) |
| R2 | security-reviewer (Medium, experiment-confirmed) | Removal pairing was **by count**: one clean worktree removal absorbed the deletion of another worktree's `.git`, returning 0 with a note that named only the clean one. B27 in the plan was wrong | `cc-exit-scan.sh:896-903` | Fixed by content pairing (a removed `dotgit` must have held `gitdir: P\n`). Removal acceptance **moved to the stacked unit** `q094b-exit-scan-worktree-removal` (size cap); in this unit any removal warns |

## 🟡 Must Address

| # | Source | Finding | Location | Status |
|---|---|---|---|---|
| A1 | code-fact-check (Incorrect) + security Low | Commit 5a6d689's message says "The rest of the scan checks -f before every read"; `_snap_worktree_of` read a possibly-FIFO `config` (pre-existing). Fails closed as a hang, then exit 4 | `cc-exit-scan.sh:325` | Fixed (a `-f` guard), so the claim now holds. The commit message itself is unpushed history and is left as written |
| A2 | performance Low | O(n²) dotgit lookup per added worktree | `:874-879` | Fixed: records indexed once (`dot[]`) |
| A3 | performance Low | Back-pointer read whole (up to 64 MiB) before any length check | `:869` | Fixed: size cap of 4097 bytes before the read |
| A4 | fact-check Mostly accurate ×6; api-consistency Minor 1, Info 5 | Doc accuracy: the config.worktree exception; "repo config" in rule 3; "tracked files"; the return-2 doc; the exit-status text in `cc-isolated.sh --help` and in the guide; a stray line break in the doc comment | header, guide, `cc-isolated.sh:20` | Fixed |
| A5 | api-consistency Minor 3 | `branch.<b>.remote = .` made a W record, so every repo with local tracking warned | `:352` | Fixed: `.` exempt (verified: from a worktree, a push to `.` runs the common hooks) |

## 🟢 Consider

| # | Source | Finding | Disposition |
|---|---|---|---|
| C1 | api-consistency Minor 2 | Lower-case `note:` and one long line, where other messages use upper-case tags and wrap | Won't fix: the user's Q-094 answer specified "a one-line `note:`" |
| C2 | api-consistency Info 4 | `GIT_EXIT_SCAN_CONTAINER_WS` duplicates devcontainer.json's mount target | Fixed: a bats assertion ties the two |
| C3 | performance Info 4 | The guide's "A slow scan" section omits the cost of the note path | Fixed: one clause |
| C4 | fact-check escalation | bats test 1 counts output lines, so it is sensitive to locale warnings on stderr (environmental) | Deferred: tests run with a working locale in CI/host |

## ⏭️ Skipped Core Critics
None. Contextual critics were not triggered: tests changed, fewer than 10 files, no manifest, no UI, and no module-structure change.

## Considered overrides
Override-log rows 133–135 (integrate/q076, `cc-exit-scan.sh`): the bare-layout limit (133) and scan cost (134) are unchanged by this diff and were not re-raised as findings. Row 135 (`commondir` first-line read outside cc-gitdir.sh) is unchanged; the new code reads the worktree `commondir` only through a byte-exact hash comparison.

## 🧩 Composition check
One multi-source cluster: `cc-exit-scan.sh:~325`, where fact-check A1 and security Low describe the same FIFO read. Disposition: the same defect restated, not a composition.

## ✅ Confirmed Good
None asserted. The critics' endorsements (the added-worktree path's byte-exact checks) are pending execution verification; the loop pass skipped Stage 2.5.

---

## Iteration 2 (`--range 5a6d689..HEAD`, reviewed at c32a734 / 5fadfc2)

Fact-check (k=1): 36 claims. 1 Incorrect: the stacked unit was described as existing. It now exists as branch `q094b-exit-scan-worktree-removal`. 5 Stale: "or removed" leftovers, fixed in 5fadfc2. 3 Mostly accurate, fixed (the header's "." exception, B28's coverage wording, the host-dependent ms figure). Critics: security and performance. Api-consistency was gated off: nothing on the public surface changed beyond doc text.

| # | Tier | Source | Finding | Status |
|---|---|---|---|---|
| R3 | 🔴 | security (Medium, experiment-confirmed) | The `.` remote exemption also covered `url.<base>.insteadOf` bases, where `.` starts a relative path (`.evil`), so a planted hook in the new worktree passed with the note | Fixed: insteadOf bases of `.` always make a W record; a test case pins it and a mutation that drops the fix fails it. The older gap underneath (the rewritten URL is never walked) is now a guide Known route |
| I1 | 🟢 | security Info | A container still running after exit can swap `P/gitdir` for a FIFO after the checks, so the scan hangs, then Ctrl-C and exit 4 | Accepted: fails closed; the existing "After the scan" route (B24) |
| — | — | performance | No findings. The `[[ ]]` matches are linear (12–18 ms/MiB); the O(n²) is gone (3,000 worktrees: 165 s → 0.2 s); the note holds at 300 and 600 worktrees | — |

Status after the iteration-2 fixes: 0 Must Fix open, pending the confirming pass (iteration 3).

Single-sample review; absence of findings is not an attestation.
