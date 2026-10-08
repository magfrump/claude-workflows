Commit: 380ed01b

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u2a3c (feat/build-loop-u2a3c)
**Scope:** Stage 2.5 submitted claims only (9 critic endorsements from the confirming pass at HEAD 380ed01b; the code is 4b7f2357's); no harvested claims. Numbering continues the canonical merged report (ends at 58).
**Checked:** 2026-10-07
**Total claims checked:** 9
**Summary:** 8 verified, 1 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Execution provenance for every executed claim: scripts and captured output are in the scratch dir `/tmp/u2a3c-i4-sub-NsDf/` (logs under `logs/`; the brief forbids writing anything else in the worktree, so logs were not copied to `docs/reviews/execution-logs/`). Libraries probed: `head-lib.sh` = `git show 380ed01b:scripts/lib/dev-cycle-read.sh` (identical to 4b7f2357's lib), `3a35-lib.sh` = 3a35c8b9's, `main-lib.sh` = main at fd14a967; `old-mc.sh` is 3a35c8b9's `main_checkout` renamed `main_checkout_old`. Every fixture repo is built under the scratch dir with `mktemp -d` and removed after the run. Host: 16 cores, WSL2, bash 5.2.15, 2026-10-07 22:52-23:03 UTC, with other review agents running at the same time; timing claims are verdicted on shape (who is faster, by roughly what factor, linear or not), not exact seconds. Each command ran with cwd `/tmp/u2a3c-i4-sub-NsDf`.

---

## Submitted Claims

## Claim 59: "4b7f2357's PATH guard only adds `return 1` (fail-closed) outcomes; for a PATH main stores as 120000 or 160000 it answers 1 before any memo write, so a checkout directory there is never memoized as d."

**Submitted by:** security-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:743`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers random call sequences on one MEMO per version over a shared random ENT (modes 100644/100755/120000/160000, 8 entries) and checkouts holding absent nodes, plain and unreadable files, symlinks, FIFOs, searchable and non-searchable directories, PATH depth 1-4; does not establish depths over 4, a checkout that changes between calls, or any caller other than `main_imports` (which never passes a PATH main stores, so the guard is unreachable from the gate today).

The guard is the second statement of the function, after the type check and before the bottom-up loop and every memo write:

```bash
# scripts/lib/dev-cycle-read.sh:741-746
  set +u; [[ "${mc_e[0]@a}" == *A* && "${mc_m[0]@a}" == *A* ]] || return 1
  # Main's link or gitlink at PATH refuses before a checkout directory there is memoized as d (U2a3c final fact-check 34).
  [[ ! "${mc_e[$3]:-}" =~ ^1[26]0000$ ]] || return 1
  # Bottom up to the nearest decided ancestor, then top down from it (U2a3c
  # i2 performance F1: top down alone rescanned every absent ancestor).
  while [[ "$c" == */* ]]; do c="${c%/*}"; if [[ -n "${mc_m[$c]+set}" ]]; then st="${mc_m[$c]}"; break; fi; anc+=("$c"); done
```

The only memo writes come later, `mc_m[$c]="$st"` at `scripts/lib/dev-cycle-read.sh:754` and `[[ ! -x "$c" ]] || mc_m[$c]=d` at `scripts/lib/dev-cycle-read.sh:760`, so a 1 from line 743 leaves MEMO untouched. The guard's only effect is an early `return 1`; its downstream effect (no memo entry where 3a35c8b9 might have written d) can only make a later call re-run the per-ancestor mode check `[[ ! "${mc_e[$c]:-}" =~ ^1[26]0000$ ]] || return 1` (`scripts/lib/dev-cycle-read.sh:749`), which again can only add 1s. The differential probe compared HEAD's and 3a35c8b9's `main_checkout` call by call: every differing return code was HEAD's 1, and every call at a PATH ENT stores as 120000/160000 returned 1 with MEMO's size unchanged (result line in `logs/s1.log`).

Command: `timeout 110 bash s1.sh head-lib.sh old-mc.sh /tmp/u2a3c-i4-sub-NsDf 1000`, exit 0, 2026-10-07T23:00:15Z to 23:01:16Z (`logs/s1.ts`). Result: `sequences=1000 calls=15000 link_or_gitlink_PATH_calls=629 differing=853 differing_not_head1=0`, with no `LINKPATH-BAD` line (each of the 629 calls at main's link or gitlink PATH returned 1 and left MEMO's size unchanged). (Two earlier runs of the probe hung on its own fixture writing into a FIFO; they were stopped by PID and the fixture fixed. They exercised no lib code past the hang.)

**Evidence:** `scripts/lib/dev-cycle-read.sh:741-761`, `/tmp/u2a3c-i4-sub-NsDf/s1.sh`, `/tmp/u2a3c-i4-sub-NsDf/logs/s1.log`, `/tmp/u2a3c-i4-sub-NsDf/logs/s1.ts`

---

## Claim 60: "`${mc_e[0]@a}` / `${mc_m[0]@a}` answer `A` for an empty, an unassigned-declared and a 200,000-key associative array, `a` for an indexed one and empty for a scalar or unset name, and cost does not grow with the array, on bash 5.2.15."

**Submitted by:** security-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:741`
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the expansion through a nameref (as `main_checkout` uses it) under `set +u` for empty, declared-unassigned, 200,000-key, key-"0"-present associative arrays, non-empty and empty indexed arrays, a scalar and an unset name, on bash 5.2.15; does not establish other bash versions or a nameref whose target is itself a nameref.

The check reads element 0's attributes, `set +u; [[ "${mc_e[0]@a}" == *A* && "${mc_m[0]@a}" == *A* ]] || return 1` (`scripts/lib/dev-cycle-read.sh:741`). The probe (`timeout 300 bash s2.sh`, exit 0, 2026-10-07T22:52:36Z, `logs/s2.log`) printed `A` for `emptyA`, `declA` (declared, never assigned), `bigA` (200,000 keys) and `withzero` (key 0 present), `a` for `idx` and the empty `idxE`, and empty for `sc` and `unsetvar`, matching `${x@a}` in every case. Key 0's presence does not matter. Per-call cost of `${r[0]@a}` was 1.98 / 2.15 / 2.22 / 2.15 µs at 0 / 1,000 / 100,000 / 200,000 keys, against 0.09 / 14.10 / 29.43 ms for `${r@a}` at 1,000 / 100,000 / 200,000 (`logs/s2.log`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:741`, `/tmp/u2a3c-i4-sub-NsDf/s2.sh`, `/tmp/u2a3c-i4-sub-NsDf/logs/s2.log`

---

## Claim 61: "The ENT/MEMO type check runs before any `mc_e[...]`/`mc_m[...]` subscript, so an indexed array with an arithmetic-subscript payload in PATH returns 1 without executing it."

**Submitted by:** security-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:741-749`
**Type:** Invariant / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers indexed ENT, indexed MEMO and both indexed, with PATH `x[$(touch MARKER)]`; does not establish safety for an associative ENT/MEMO (where subscripts are not arithmetic, so the question does not arise) or for payloads reaching other functions.

Line 741 subscripts only the literal 0 (`"${mc_e[0]@a}"`), and the first `$3`-dependent subscript is line 743's `"${mc_e[$3]:-}"`, after the `|| return 1` (quoted under claim 59). The probe (`timeout 60 bash s3.sh head-lib.sh /tmp/u2a3c-i4-sub-NsDf`, exit 0, 2026-10-07T22:52:46Z, `logs/s3.log`) printed `rc=1 marker=absent` for all three combinations (`ient amemo`, `aent imemo`, `ient imemo`), while the control `${ient[$pay]}` printed `marker=CREATED`, showing the payload does execute when an indexed array is subscripted with it.

**Evidence:** `scripts/lib/dev-cycle-read.sh:741-743`, `/tmp/u2a3c-i4-sub-NsDf/s3.sh`, `/tmp/u2a3c-i4-sub-NsDf/logs/s3.log`

---

## Claim 62: "In a checkout where a path main stores as a blob is replaced by a directory, `main_imports` admits and walks the checkout file below it and its imports (walk ok, names present): the dirty shape over-reads rather than answering not imported."

**Submitted by:** security-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:808-883`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers main storing `x` as a 100644 blob with the checkout holding directory `x/` with both an untracked start (`x/CLAUDE.md`) and an import of main's CLAUDE.md (`x/w.md`) and their transitive imports; does not establish the case where main stores the path as 100755 or any ancestor deeper than one level, nor whether over-reading is the right policy for U2b.

`main_checkout` checks ancestors' main modes only for links and gitlinks, `[[ ! "${mc_e[$c]:-}" =~ ^1[26]0000$ ]] || return 1` (`scripts/lib/dev-cycle-read.sh:749`), then decides by the checkout's shape, so a blob-mode ancestor that is a plain searchable directory in the checkout passes `plaindir` and memoizes d (`scripts/lib/dev-cycle-read.sh:750-754`). The fixture (`timeout 60 bash s4.sh head-lib.sh /tmp/u2a3c-i4-sub-NsDf`, exit 0, 2026-10-07T22:55:11Z, `logs/s4.log`) committed `x` as a blob and CLAUDE.md with `see @x/w.md`, then replaced `x` with a directory holding `x/CLAUDE.md` (`see @y.md`), `x/y.md` (`see @z.md`), `x/z.md`, `x/w.md` (`see @v.md`) and `x/v.md`. The walk printed `walk ok` and `IMPORTED_MAIN` held `x/w.md`, `x/v.md`, `x/y.md` and `x/z.md`, so both the checkout start below the blob path and main's import there were admitted and walked transitively.

**Evidence:** `scripts/lib/dev-cycle-read.sh:749-760`, `scripts/lib/dev-cycle-read.sh:832`, `scripts/lib/dev-cycle-read.sh:877`, `/tmp/u2a3c-i4-sub-NsDf/s4.sh`, `/tmp/u2a3c-i4-sub-NsDf/logs/s4.log`

---

## Claim 63: "`${mc_e[0]@a}` costs about 7 µs per call whatever the array size (0 to 100,000 entries), where `${m@a}` costs 20.6 ms at 100,000; same type answer for empty, keyed, 50,000-entry, indexed, scalar and unset variables."

**Submitted by:** performance-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:741`
**Type:** Performance / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the shape (constant per-call cost of the element form, linear cost of the whole-array form, matching type answers) on this host; does not establish the exact microsecond figures, which depend on host and on what the measured loop includes.

Same probe as claim 60 (`logs/s2.log`): the element form cost 1.98-2.22 µs per call from 0 to 200,000 keys (flat), and the whole-array form 14.10 ms at 100,000 and 29.43 ms at 200,000 (linear), with the same type answers for every variable kind tested. The absolute figures differ from the claim's (2 µs vs 7 µs, 14.1 ms vs 20.6 ms); the shape (O(1) against O(n), a factor of thousands at 100,000) holds.

**Evidence:** `scripts/lib/dev-cycle-read.sh:741`, `/tmp/u2a3c-i4-sub-NsDf/logs/s2.log`

---

## Claim 64: "At HEAD the checkout phase is linear in distinct absent tokens: 1.67, 3.42, 6.72 and 13.87 s for 2,000, 4,000, 8,000 and 16,000 8-deep tokens."

**Submitted by:** performance-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:735-762`, `scripts/lib/dev-cycle-read.sh:873-882`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers one main walk over N distinct absent 8-deep tokens (`@qI/b/c/d/e/f/g/x.md`) in a one-file main tree; does not establish other token shapes, present directories, or the cost under a large main tree (claim 65).

`for n in 2000 4000 8000 16000; do timeout 200 bash perf.sh absent8 head-lib.sh /tmp/u2a3c-i4-sub-NsDf $n; done` (2026-10-07T22:55:27Z, every walk `ok`, `logs/p2.log`) took 1.46, 2.90, 5.88 and 11.87 s: each doubling of N doubles the time (ratios 1.99, 2.03, 2.02), so linear, about 10% faster than the claim's figures.

**Evidence:** `scripts/lib/dev-cycle-read.sh:746-755`, `/tmp/u2a3c-i4-sub-NsDf/perf.sh`, `/tmp/u2a3c-i4-sub-NsDf/logs/p2.log`

---

## Claim 65: "With a 50,000-entry main tree, HEAD's walk costs 3.52 s with 1,000 absent tokens and 5.49 s with 8,000, within 1.6 s of main's lib (3.38 and 3.94 s)."

**Submitted by:** performance-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:808-883`
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers 2-deep absent tokens (`@tI/x.md`, the submitting critic's fixture) and 8-deep absent tokens (claim 64's shape) over a 50,000-blob main tree; does not establish other depths or token counts, and the gap's size depends on token depth, which the claim does not state.

With the critic's shape (index-only 50,000-entry tree, 2-deep tokens; `logs/p3b.log`, 2026-10-07T22:56:57Z, tree size printed as 50001): HEAD 3.30 / 5.11 s against main 3.13 / 3.73 s at 1,000 / 8,000 tokens, a gap of 0.17 / 1.38 s, which reproduces the claim. With the 8-deep tokens of claim 64 over a 50,000-file tree (`logs/p3.log`, 2026-10-07T22:55:53Z): HEAD 3.76 / 8.86 s against main 3.28 / 5.35 s, a gap of 3.5 s at 8,000 tokens, outside "within 1.6 s". The checkout phase's cost grows with each token's depth (one MEMO decision per absent ancestor, `scripts/lib/dev-cycle-read.sh:746-755`), so "within 1.6 s" holds for shallow tokens only.

**Evidence:** `scripts/lib/dev-cycle-read.sh:746-755`, `/tmp/u2a3c-i4-sub-NsDf/perf.sh`, `/tmp/u2a3c-i4-sub-NsDf/logs/p3.log`, `/tmp/u2a3c-i4-sub-NsDf/logs/p3b.log`

---

## Claim 66: "A deep absent token at D=1990 walks in 2.34 s, and 20,000 absent siblings walk in 4.59 s at HEAD, both unchanged from 3a35c8b9."

**Submitted by:** performance-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:735-762`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers one 1990-deep absent token and 20,000 absent siblings under one directory the checkout holds, at HEAD and 3a35c8b9; does not establish deep present-directory tokens (a settled deferral) or depths near the parser's limits.

`for L in head-lib.sh 3a35-lib.sh; do perf.sh deep $L ... 1990; perf.sh sibspres $L ... 20000; done` (2026-10-07T22:57:24Z, all walks `ok`, `logs/p4.log`): deep 2.26 s at HEAD vs 2.47 s at 3a35c8b9; siblings 4.66 s vs 4.13 s. Both are within about 13% of each other and of the claimed figures, so unchanged in shape.

**Evidence:** `scripts/lib/dev-cycle-read.sh:741-743`, `/tmp/u2a3c-i4-sub-NsDf/perf.sh`, `/tmp/u2a3c-i4-sub-NsDf/logs/p4.log`

---

## Claim 67: "The budgets cap the cheapest-per-byte shape: 200,000 single-component absent tokens walk in 10.58 s, and 300,000 fail in 1.31 s."

**Submitted by:** performance-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:503-512`, `scripts/lib/dev-cycle-read.sh:871`
**Type:** Performance / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers tokens `@<hex>` with no extension (the critic's fixture) at 200,000 and 300,000; does not establish which budget (IMPORT_OUT_MAX or IMPORT_WORK_MAX) trips at 300,000 or the exact threshold between the two counts.

`for n in 200000 300000; do perf.sh hex head-lib.sh ... $n; done` (2026-10-07T22:57:53Z, `logs/p5.log`): 200,000 walked `ok` in 10.07 s and 300,000 `failed` in 1.45 s. An earlier run with a longer spelling (`@sI.md`, shape `single` in `perf.sh`) already failed at 200,000 in 2.18 s and at 300,000 in 2.21 s (its log was overwritten by the hex run; the figures are from the command's terminal output), consistent with the shortest spelling being the one that gets furthest before a budget trips. The budgets are `IMPORT_OUT_MAX=4000000` (`scripts/lib/dev-cycle-read.sh:503`), charged as `(( (used += ${#out}) <= IMPORT_OUT_MAX )) || { IMPORTED_MAIN=error; return 1; }` (`scripts/lib/dev-cycle-read.sh:871`), and `IMPORT_WORK_MAX=50000000` (`scripts/lib/dev-cycle-read.sh:512`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:503`, `scripts/lib/dev-cycle-read.sh:512`, `scripts/lib/dev-cycle-read.sh:871`, `/tmp/u2a3c-i4-sub-NsDf/perf.sh`, `/tmp/u2a3c-i4-sub-NsDf/logs/p5.log`
