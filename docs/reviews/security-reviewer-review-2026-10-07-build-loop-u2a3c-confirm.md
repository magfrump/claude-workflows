Commit: 380ed01b

# Security Review — feat/build-loop-u2a3c (final confirming pass)

**Scope:** `git diff main...HEAD` in `/workspace/.claude/wt-build-loop-u2a3c`, weighted to 4b7f2357 (`scripts/lib/dev-cycle-read.sh` `main_checkout`, `main_imports`; plan U2b bullet, A5, F11)
**Date:** 2026-10-07
**Based on:** Stage-1 summary `u2a3c-i4-stage1.md`; `## Escalations` of `docs/reviews/code-fact-check-report-build-loop-u2a3c-r{1,2,3}.md` (Commit 380ed01b)

The goal preamble is supplied upstream (shared context file), so no User-goal line is restated here.

## Trust Boundary Map

```
B1: [checkout working tree: untracked/ignored/index-only files, dirs, links] → [main_checkout admission (0/2/1)] → [phase-2 queue tq → capped_read → import_targets]
B2: [main's commit tree (ls-tree modes, blobs, link text)]                → [ent[] parse, 120000 arm checks]  → [main walk queue → IMPORTED_MAIN]
B3: [second caller of main_checkout (U2b, not built)]                       → [ENT/MEMO type check, PATH guard]  → [admission answer the caller acts on]
B4: [parser output (names + "/N" trailer)]                                  → [import_work]                      → [IMPORT_WORK_MAX / IMPORT_OUT_MAX budgets]
```

| Label | Source | Mutability | Trust classification (per sink) |
|---|---|---|---|
| S1 | checkout file contents and shapes (any branch author or loop session can write them) | request-time | UNTRUSTED for path-admission and parse sinks; the walk must over-read, never under-read |
| S2 | main's commit tree and blobs | deploy-time (main is the reviewed base) | trusted for structure only after the shape refusals (dup names, link text rules); UNTRUSTED for work/size sinks (crafted blobs) |
| S3 | arguments a second caller passes (ENT, MEMO, PATH) | code-constant per caller, but unbuilt | trusted only as far as the written contract binds; the type check is the one runtime guard |
| S4 | parser trailer `/N` and printed names | derived from S1/S2 | UNTRUSTED toward budget arithmetic; `import_work` regex-checks it |

The diff's trust assumption: a session loads checkout bytes, the walk reads main's blob for every path main stores and the checkout only for paths main lacks, so the two agree only when the checkout is a clean worktree at MAIN_SHA (U2b's first duty). Inside that assumption the walk must fail toward "imported" (over-read) or fail closed; the fail-open class is a load the walk answers as not imported with walk ok.

## Findings

#### I1. The U2b bullet's blob-PATH allowance for a second caller rests on the clean-worktree duty in the same bullet (contract item for U2b, not a defect in this unit)

**Severity:** Informational
**Location:** `docs/working/plan-build-loop-handoff.md:279` (U2b bullet); `scripts/lib/dev-cycle-read.sh:743,756-761`
**Boundary:** B3, B1
**Move:** 1 (trust boundaries), 5 (invert the access model), 11 (bypasses)
**Confidence:** High
**Legibility-target:** U2b bullet (plan), when U2b builds its caller

Evidence (verbatim, bullet): "A caller of `main_checkout` other than `main_imports` passes a fresh MEMO per walk and ENT (a MEMO hit skips main's mode check too) and a PATH main lacks or stores as a blob (a link or gitlink there answers 1)". Evidence (code): `[[ ! "${mc_e[$3]:-}" =~ ^1[26]0000$ ]] || return 1` — PATH's blob mode is not consulted; the answer then follows the checkout's shape (`if rawfile "$c"; then [[ -r "$c" ]]; return; fi` / `plaindir "$c" || return 1` / `[[ ! -x "$c" ]] || mc_m[$c]=d` / `return 2`).

Executed (`/tmp/u2a3c-i4-sec-JfW2/p1.sh`): main stores `b` as a blob. Clean checkout: `b 0`, `b/x.md 2`, memo `b=2`. Dirty checkout (b replaced by a directory holding `b/x.md` that imports `../secret.md`): `b 2`, `b/x.md 0`, memo `b=d`, and `main_imports` answers `walk ok` with `b/x.md` and `secret.md` both in IMPORTED_MAIN. So a blob PATH answers by what a session reading the checkout can load (a directory loads nothing; a file below it does), and in main_imports the dirty case over-reads (main's blob `b` is walked too). I found no input where the blob-PATH answer turns a load into "not imported": the only divergence is between main's blob bytes and the checkout's bytes at a path main stores, which is the general clean-worktree duty (U2a3c final security F2), not something main_checkout's PATH handling adds. `main_imports` never passes such a PATH (`[[ -n "${ent[$p]+set}" ]] || main_checkout ...`, lines 832, 877), so nothing in this unit reaches it.

Answer to the escalation: a U2b contract item, not a finding against U2a3c. The duty that makes it safe is the first of the four duties in the same bullet, which binds U2b as the second caller.

**Recommendation:** No change in this unit. When U2b writes its caller, its precondition text should cite the clean-worktree duty beside the blob-PATH allowance (or refuse a blob PATH the checkout holds as a directory) so the dependency is stated where it is used. Optionally pin the blob-PATH answers (clean: `b 0`; dirty dir: `b 2`, memo d) in a test, as test-strategy's escalation notes.

## Untested bypass candidates

None for `main_checkout`'s 4b7f2357 changes; every candidate below was executed:

| Candidate | Result |
|---|---|
| Main link at PATH, checkout holds a plain directory there (dirty) | `l 1`, `l/k.md 1` (p1.sh) and test 65 |
| Main blob at PATH, checkout holds a directory (dirty) | answers by checkout, over-reads in main_imports (I1) |
| Indexed ENT or MEMO with subscript `x[$(touch …)]` (arithmetic-subscript injection) | `indexed-ENT rc=1 pwned=no`, `indexed-MEMO rc=1 pwned=no` (p2.sh): the type check precedes every subscript |
| `declare -A N` with no assignment as MEMO (`${N[0]@a}` with key 0 absent) | type check passes (`unassigned-memo 2`), the same answer as an assigned empty array |
| One MEMO reused across two ENTs | `E2 (u is main link) reusing MEMO rc=0`, `E2 fresh MEMO rc=1` (p2.sh): fails open, as the comment's contract says ("a MEMO serves one walk and one ENT"); the only caller declares `local -A … pok=()` per call (line 811). Contract-bound, not reachable in this unit |

## Endorsement Claims

- **Claim:** 4b7f2357's PATH guard only adds `return 1` (fail-closed) outcomes; for a PATH main stores as 120000 or 160000 it answers 1 before any memo write, so a checkout directory there is never memoized as d.
  **Location:** `scripts/lib/dev-cycle-read.sh:743`
  **Evidence:** executed
  **Verified:** p1.sh `l 1` / `l/k.md 1` on clean and dirty-directory checkouts, memo without `l`; build-loop-check test 65 passes (66/66 under a 71-character TMPDIR).
  **Not verified:** the Stage-1 random-order differential against 21b35ebf (cited from r1-r3, not re-run here).
  **route: code-fact-check**

- **Claim:** `${mc_e[0]@a}` / `${mc_m[0]@a}` answer `A` for an empty, an unassigned-declared and a 200,000-key associative array, `a` for an indexed one and empty for a scalar or unset name, and cost does not grow with the array (20,000 checks on 200,000 keys in 0.06 s vs 20 `${L@a}` in 0.47 s), on bash 5.2.15.
  **Location:** `scripts/lib/dev-cycle-read.sh:741`
  **Evidence:** executed
  **Verified:** `/tmp/u2a3c-i4-sec-JfW2/t1.sh`, `t2.sh`.
  **Not verified:** bash versions other than 5.2.15 (the host fallback of Q-121 may run a different bash).
  **route: code-fact-check**

- **Claim:** The ENT/MEMO type check runs before any `mc_e[...]`/`mc_m[...]` subscript, so an indexed array with an arithmetic-subscript payload in PATH returns 1 without executing it.
  **Location:** `scripts/lib/dev-cycle-read.sh:741-749`
  **Evidence:** executed
  **Verified:** p2.sh `indexed-ENT rc=1 pwned=no`, `indexed-MEMO rc=1 pwned=no`.
  **Not verified:** a nameref ENT naming an associative array declared in an outer function scope of a future caller.
  **route: code-fact-check**

- **Claim:** In a checkout where a path main stores as a blob is replaced by a directory, `main_imports` admits and walks the checkout file below it and its imports (walk ok, names present), i.e. the dirty shape over-reads rather than answering not imported.
  **Location:** `scripts/lib/dev-cycle-read.sh:808-883`
  **Evidence:** executed
  **Verified:** p1.sh dirty case: IMPORTED_MAIN holds `b/x.md` and `secret.md`.
  **Not verified:** a dirty checkout that edits a tracked file's bytes in place (outside main_checkout; U2b's clean-worktree duty).
  **route: code-fact-check**

## Primitive sweep

Primitive: file read / blob read on walk-derived paths (path traversal, unbounded read)
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `dev-cycle-read.sh:782` `capped_read < "$f"` (imported_names) | S1 | `inrepo_here` (blocker + -f), 4 MiB + 1 cap | cleared — unchanged admission, cap added |
| `:844` `capped_read < "$f"` (phase 2) | S1 | main_checkout 0 = `rawfile` (realpath equals ROOT_REAL/$f) and `-r` | cleared — links and non-regular nodes answer 1; TOCTOU settled (snapshot row) |
| `:846` `git cat-file blob … \| capped_read drain` | S2 | ent mode 100644/100755 | cleared — capped parse, drain uncharged (settled row) |
| `:850` `git cat-file -s` then `:853-854` two whole reads of link text | S2 | size ≤ 4096 checked first | cleared — B3 fix of 2fbd929b holds; non-numeric -s settled |
| `:862`, `:865` `realpath -ms --relative-to` on link text | S2/S1 | empty/absolute/newline/NUL and `..`-after-link refusals | cleared — unchanged by 4b7f2357 |

Primitive: associative/indexed array subscripts with caller- or file-derived keys (arithmetic-subscript injection)
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `:743` `mc_e[$3]`, `:746` `mc_m[$c]`, `:749` `mc_e[$c]`, `:754`, `:760` | S3 PATH, S1 tokens | `[[ "${mc_e[0]@a}" == *A* && "${mc_m[0]@a}" == *A* ]] \|\| return 1` first | cleared — executed (p2.sh) |
| `:820-834`, `:876-880` `ent[$f]`, `seen[$p]`, `dir[$c]` | S1/S2 | `local -A` in the same function | cleared — associative subscripts are literal |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| I1 | Blob-PATH allowance for a second caller rests on the clean-worktree duty (U2b contract item) | Informational | B3, B1 | `plan-build-loop-handoff.md:279`; `dev-cycle-read.sh:743,756-761` | High |

## Overall Assessment

No fail-open found in 4b7f2357 or the rest of the branch within the code paths read and probed: the new PATH guard and the O(1) type check only add or preserve fail-closed answers, the type check still precedes every subscript, and the one escalated shape (a blob PATH from a second caller) answers by what a checkout reader can load and over-reads in `main_imports`. Its residual dependence on a clean worktree is U2b's existing first duty, so it is a contract item for U2b (I1, Informational), not a blocker here. Every endorsement claim is `Evidence: executed` with its nearest unverified hop named; they are routed to code-fact-check for Stage 2.5. build-loop-check.bats ran 66/66 under a 71-character TMPDIR.

## Goal-Alignment Note

The user goal is to land feat/build-loop-u2a3c once its loop is clean. From the security side this pass adds no Must Fix: the escalation resolves as a U2b contract item (I1), which does not block the merge, and the most useful follow-up is for U2b's caller text to cite the clean-worktree duty next to the blob-PATH allowance. This review wrote only this file in the worktree; probes lived in `/tmp/u2a3c-i4-sec-JfW2` and `/tmp/u2a3c-i4-sec-bats-*`, and it started no background processes.
