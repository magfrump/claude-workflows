Commit: 1f4f7a21
Loop closed at 1f4f7a21
# Code Review Rubric

**Branch:** `feat/build-loop-u2b2` (U2b2: the gate's checkout, caller-contract items 2-4), on main 45ca46c3.
**Status: ✅ ITERATION 3 (final confirming pass) — no red; the final ambers are help, comment and plan text plus one misleading reason (a newline name), fixed after the pass (unreviewed, lite-checked); converged at the cap** (single-sample review; absence of findings is not an attestation)

## Iteration 1 (Commit c10b972a, `--loop-pass`, k=1, scope `main...HEAD`, full panel)

Delivery mode: self-read (diff saved to the scratchpad; agents read the files). Reports: `code-fact-check-report-build-loop-u2b2.md` (k=1: 20 claims, 12 Verified, 8 Mostly accurate), `security-reviewer-review-2026-10-08-build-loop-u2b2.md`, `performance-reviewer-review-2026-10-08-build-loop-u2b2.md`, `api-consistency-reviewer-review-2026-10-08-build-loop-u2b2.md`, `architecture-review-review-2026-10-08-build-loop-u2b2.md`. Architecture auto-selected (the lib's caller contract and `--check`'s grammar change); test-strategy not selected (tests in the diff). Stage 2.5 skipped (loop pass): security's two routed endorsements stay pending execution verification. No short-circuit (no behavioral red).

### 🔴 Must Fix

None.

### 🟡 Must Address

| # | Finding | Severity | Source | Considered overrides | Status |
|---|---|---|---|---|---|
| A1 | ls-tree records that miss the regex are skipped (`|| continue`); under a UTF-8 locale `.` does not match an invalid byte, so a file with a non-UTF-8 name escapes the byte check (executed: ok under C.utf8, refused under C). | Medium | security 2 | row 399 (LC_ALL=C for the walk) | Fixed in 639f7b40: `local LC_ALL=C`, mode 120000 skipped by name, any other unmatched record refuses |
| A2 | `hash-object --stdin-paths` unquotes a name starting with `"` and drops a trailing CR, so that file's own bytes are never compared (executed with an ident expansion, status clean). | Medium | security 1; fact-check claim 4 | — | Fixed in 639f7b40: refuse such names as newline names are |
| A3 | A gitlink path `ls -A` cannot list reads as empty (`chmod 111 sub`; the file inside is still readable by name). | Medium | security 3 | rows 366, 373 | Fixed in 639f7b40: refuse a gitlink path that exists and cannot be listed, or is a symlink |
| A4 | The checkout refusal comes before merge_result and the N rules, so a loop's advisory `--check` of a self-merge brief (HEAD is its branch) never sees a conflict or deny line, against plan D1's advisory dry run. | Inconsistent / Coupling | api F1; architecture F2 | — | Fixed in 639f7b40: the checkout is judged after the N rules; path and deny lines still follow the refusal |
| A5 | The checkout is checked once per run in the parent shell, while the walk (U2c) runs per brief: "final before the walk" (item 2) has no owner. | Coupling | architecture F1 | rows 439, 459 | Fixed in 639f7b40: checkout_gate runs inside check_line, per self-merge brief, at the point U2c's floor will run |
| A6 | Empty CHECKOUT_WHY means both "passed" and "never ran"; producer and consumer use different predicates. | Minor (fail-open shape) | architecture F3; performance (out of domain note) | — | Fixed in 639f7b40: with A5 (computed where it is read) |
| A7 | The trusted GIT_* rule is written twice (gate_repo, checkout_gate) and the copies differ; both let GIT_CONFIG (a file redirect `git config` follows) through, which can switch off the core.* refusals. | Minor / Mostly accurate | architecture F5; fact-check claim 6 | row 314 (inherited GIT_DIR) | Fixed in 639f7b40: one `callervar` predicate; GIT_CONFIG is not a caller config pair |
| A8 | Help text omits refusals (unreadable core.*, listing failures, newline names, exemptions); lib item-3 note claims all of item 2 (fsmonitor and replace refs are harden's and the state gate's; stderr is the walk's); A5's not-covered list is stale; test comment "Each index flag hides a change" (only assume-unchanged does); commit's "each refusal" tested. | Mostly accurate | fact-check claims 1, 3a, 10, 11, 18; api F2, F5; architecture F4, F6 | rows 459, 465 | Fixed in 639f7b40: (docs, comment, tests for the untested refusals) |
| A9 | Reason wording: "its HEAD/index" names the checkout where every other `refuse BRIEF` reason's "its" is the brief; "X or unreadable" folds a read failure into a refusal (the state gate keeps them apart). | Minor | api F3, F4, F6 | — | Fixed in 639f7b40: the checkout as subject; read failures worded apart; the HEAD reason prints the actual HEAD |

### 🟢 Consider

| # | Finding | Source | Status |
|---|---|---|---|
| G1 | Hashing cost grows with tracked bytes (a 200 MB binary: ~1.1 s); ran even when every brief was review. | performance 1 (Low) | Addressed by A5 (runs only for a self-merge brief) |
| G2 | The bash read loop costs ~29 µs per tree record (1.4 s at 50k files); `ls-files --others` walks ignored trees (0.06 s at 100k). | performance 2, 3 (Informational) | Won't-Fix: under a second at this repo's scale; `--directory` would hide nested repositories |
| G3 | checkout_gate lives in the calling script, apart from the lib contract it enforces. | architecture F7 | Defer: revisit when a second floor caller appears |
| G4 | Untested bypass candidates: a FIFO at a tracked path (row 440), a dangling symlink at a gitlink path, and three more listed in the security report. | security (not tested) | Gitlink symlink folded into A3; the rest carried to iteration 2's security brief |
| G5 | Export LC_ALL=C for the whole script (contract item 1) rather than per function. | security open question | Defer to U2c, which runs the walk (row 399) |

### Considered overrides

Rows 366, 373 (nested repositories: now refused), 387 (GIT_INDEX_FILE, sparse, case-insensitive bypasses: now refused), 388 (the gate's checkout is U2b's), 391, 392, 397 (conversions, core.symlinks: this unit's target), 399 (LC_ALL=C), 439 (cache cleared per decision), 440 (FIFO start: still open), 459/465 (one numbered contract), 314 (inherited GIT_DIR), 425/431/432/437/477 (reader model: U2b3's).

### Tokens

fc 1×150k; critics 4× (security 136k, performance 82k, api 103k, architecture 130k) ≈ 600k total.

## Iteration 2 (Commit 368a3194, `--loop-pass`, k=1, scope `c10b972a..368a3194`, full panel)

Reports: `code-fact-check-report-build-loop-u2b2-i2.md` (26 claims: 16 Verified, 7 Mostly accurate, 3 Incorrect), `*-review-2026-10-08-build-loop-u2b2-i2.md` for security (no new finding; every iteration-1 fix holds; FIFO at a tracked path, smudge filter from global config, config.worktree keys, unmerged entries and more all refused), performance, api-consistency, architecture. Iteration 1's A1-A9 all confirmed fixed by their critics. Stage 2.5 skipped (loop pass). No short-circuit: the Incorrects are doc-only (tier T).

### 🔴 Must Fix

None.

### 🟡 Must Address

| # | Finding | Severity | Source | Status |
|---|---|---|---|---|
| B1 | The checkout_gate comment, help text, plan bullet and 639f7b40's message said the checkout is judged "after the N rules"; it runs before them (before the per-path loop), the right place for "final before the walk". | Incorrect (doc) | fact-check i2 claims 7, 17, 22 | Fixed in 368a3194 (before the critics ran); 639f7b40's message is immutable (override row) |
| B2 | After a checkout refusal the per-path loop still runs, and nothing says U2c's floor must not walk a refused checkout (a loop's advisory run would print floor results over it). | Coupling | architecture i2 1 | Fixed after the pass: check_line comment and the U2c bullet: floor runs only when `co` is empty |

### 🟢 Consider

| # | Finding | Source | Status |
|---|---|---|---|
| C1 | Contract item 1 (LC_ALL=C) has no process-wide owner; checkout_gate sets it only for itself. | architecture i2 2 (Minor) | Fixed after the pass: the lib header and U2c bullet name U2c's floor caller as the owner |
| C2 | Deny lines can follow the checkout refusal (help said "as they follow ok"); the fixed prefix carries read failures a clean checkout does not cure; the name rule is for regular files. | api i2 N1, N2, N4 (Minor/Info); fact-check claim 1 | Fixed after the pass (help text) |
| C3 | "core.X could not be read" omits the git config exit code; "unreadable" sits where a commit id goes in the HEAD reason. | api i2 N3 (Info) | Won't-Fix: wording only |
| C4 | Per-brief checkout_gate multiplies its cost by the self-merge briefs in one --check (0.24 s each here; ~24 s for nine briefs on a 50k-file, 200 MB repo). | performance i2 1 (Low) | Accepted: a fresh check per decision is the point (item 4); the cost is recorded in the check_line comment |
| C5 | Verdict precedence spread across two early returns and an if-chain; callervar answers two questions. | architecture i2 3, 4 (Info) | Defer: U2c restructures the verdict; split callervar at a second exception |
| C6 | Mutants that stay green: the gitlink -L test, the unparseable-record refusal (unreachable under C), the stderr-only half of the git status rule. | fact-check i2 claim 24 | Accepted: defense in depth; git status fails first in every reachable case (security i2 sweep) |
| C7 | LC_ALL in 639f7b40 was not exported to children; GIT_CONFIG wording; test comment said git "warns" on a gitlink symlink (it fails, exit 128); A5 omitted case-insensitive FS with ignoreCase false. | fact-check i2 claims 4, 16, 21, 23 | Fixed in 368a3194 |

### Tokens (iteration 2)

fc 167k; critics security 135k, performance 109k, api 112k, architecture 115k ≈ 640k.

## Iteration 3 of 3: final confirming pass (Commit 1f4f7a21, k=3, full panel, Stage 2.5, scope `main...HEAD`)

Reports: `code-fact-check-report-build-loop-u2b2-final.md` (merged r1-r3: 61 clusters, 44 Verified, 11 Mostly accurate, 4 Incorrect, 2 Unverifiable; agreement 47/61, 77.0%; plus Stage 2.5's six submitted claims 62-67: five Verified, four executed, one Mostly accurate), `security-reviewer-review-2026-10-08-build-loop-u2b2-final.md` (one Informational; no bypass found: global sparse checkout, autocrlf, a global-only ident attribute, intent-to-add, core.worktree all refused), `performance-reviewer-review-2026-10-08-build-loop-u2b2-final.md` (no finding; 0.27 s per pass), `api-consistency-reviewer-review-2026-10-08-build-loop-u2b2-final.md` (2 Minor, 2 Informational), `architecture-review-review-2026-10-08-build-loop-u2b2-final.md` (2 Informational). The Fact-Check Gate did not pause in away mode: no Incorrect is behavioral.

### 🔴 Must Fix

None.

### 🟡 Must Address

| # | Finding | Severity | Source | Status |
|---|---|---|---|---|
| D1 | Help :124-125 promised an "or one of them unreadable" core.* refusal that cannot print: git rejects a bad boolean before any command, so --check exits 1 with no line (fails closed; exit 1 is documented for usage and no repo). | Incorrect (doc) | fact-check claim 13 (r3); security final 1; api final F1 | Fixed after the pass: the help says a bad boolean stops git itself (exit 1, no line); the dead branch is commented as defensive |
| D2 | A regular file name holding a newline was refused under the index-bits reason (`ls-files -v -z \| tr` split the record), never the name reason. | Mostly accurate (misleading reason; still refused) | fact-check claim 14 (r1, r2); api final F2 | Fixed after the pass: the index count reads NUL-ended records with perl -0; a newline-name test (fails on the old count) |
| D3 | Comments: the C-locale comment described a skipped record (now refused); the pipefail comment's "stops early" half; "about 0.25 s" (0.27-0.36 measured); "at most the slot count" (not enforced). | Mostly accurate | fact-check claims 27, 33, 39, 41; architecture final 2; api final | Fixed after the pass |
| D4 | Plan :284 "no repo-local GIT_* variable" without the exemptions. | Mostly accurate | fact-check claim 7; api final F4 | Fixed after the pass |
| D5 | Commit messages: 639f7b40 ("after the N rules", "each fix's mutant", "warns"), 368a3194 ("only bash's own matching"), c10b972a ("0.14 s"), 1f4f7a21 ("full panel over c10b972a..368a3194"). | Incorrect / Mostly accurate (immutable) | fact-check claims 50-53, 57, 59 | Accepted-immutable (row 527 and the row added now) |

### 🟢 Consider

| # | Finding | Source | Status |
|---|---|---|---|
| E1 | U2c's floor will run inside check_line's `$(...)` subshell, where need_root's exit ends only the subshell (fails closed: no line for that brief). | architecture final 1 | Routed: U2c plan bullet |
| E2 | Green mutants: dropping the export from `local -x LC_ALL=C` (bash still pins its own regex locale); removing import_reset (no walk runs yet). | fact-check r2; security final | Routed: U2c bullet asks for an import_reset test; LC export accepted (row added) |
| E3 | Help folds an unreadable HEAD into "HEAD at another commit" and an unparseable tree record into "a listing ... that fails"; no stable marker for read-failure WHYs. | api final F2, F3; fact-check claim 12 | Won't-Fix: wording; every case refuses |
| E4 | The main /workspace checkout refuses every self-merge brief (its agent worktrees are untracked nested repositories); a bad-locale caller sees a setlocale warning when checkout_gate returns. | performance final (out of domain); Stage 2.5 note | Accepted: fail closed as intended (D13: the orchestrator runs in its own worktree); the warning is the shell's own, already printed at start-up |
| E5 | Claim 66: the process count is fixed in the number of regular files, but each populated gitlink adds an ls. | Stage 2.5 claim 66 | Noted |

### Tokens (final pass)

fc 3× (217k, 231k, 230k), merge 193k, critics security 147k, performance 93k, api 97k, architecture 106k, Stage 2.5 125k ≈ 1.44M. Loop total ≈ 2.7M.
