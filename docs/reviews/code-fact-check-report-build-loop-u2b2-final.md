Commit: 1f4f7a21

# Code Fact-Check Report

**Commit:** 1f4f7a21
**Replication:** k=3
**Repository:** /workspace (worktree /workspace/.claude/wt-build-loop-u2b2, branch feat/build-loop-u2b2)
**Scope:** full branch `main...1f4f7a21` (base 45ca46c3): scripts/build-loop.sh (help text, `callervar`, `gate_repo`, `checkout_gate`, `check_line`), scripts/lib/dev-cycle-read.sh :1-90 (caller contract, item 3 note), docs/working/known-issues-dev-cycle.md (A5), docs/working/plan-build-loop-handoff.md (U2b2 and U2c bullets), the four 2026-10-08 `feat/build-loop-u2b2` rows of docs/reviews/override-log.md, the five U2b2 tests in test/scripts/build-loop-check.bats, and the messages of c10b972a, 639f7b40, 368a3194, 1f4f7a21. Merged from replicates r1, r2, r3 (`code-fact-check-report-build-loop-u2b2-final-r1.md`, `-r2.md`, `-r3.md`, each `Commit: 1f4f7a21`) by most-severe-wins; no claims or evidence added in the merge.
**Checked:** 2026-10-08 (replicate executions 2026-10-09T01:34Z-01:46Z UTC)
**Total claims checked:** 61
**Summary:** 44 verified, 11 mostly accurate, 0 stale, 4 incorrect, 2 unverifiable

Replicate totals as filed: r1 43 claims (35 verified, 5 mostly accurate, 1 incorrect, 2 unverifiable); r2 43 claims (33 verified, 9 mostly accurate, 1 incorrect); r3 46 claims (37 verified, 4 mostly accurate, 4 incorrect, 1 unverifiable). The 61 merged claims are the finest granularity any replicate used; a replicate that verdicted only a compound claim carries that verdict on each part, marked `(compound)`. Execution logs: r1 `/tmp/claude-1000/-workspace/67a6f690-c029-41ac-9bf2-d19f7c0e4343/scratchpad/fcf-final-r1-1061983/` (`$L/` below) and `/tmp/fcf-1190629-iRp3/`; r2 `/tmp/claude-1000/-workspace/67a6f690-c029-41ac-9bf2-d19f7c0e4343/scratchpad/fcr2/` (`$FCR2/` below); r3 `/tmp/fcf-944033-AxOn/`, `/tmp/fcf-1320198-M9G8/`, `/tmp/fcf-1429237-mgZd/`. Environment (all three): git 2.39.5, bash 5.2.15, shellcheck 0.9.0.

## Claims Requiring Attention (summary)

### Incorrect
- **Claim 13** (`scripts/build-loop.sh:124-125`): help's "or one of them unreadable" cannot produce a refusal line; git rejects an unparseable core.symlinks/ignoreCase/sparseCheckout at startup, so `--check` exits 1 with "Not inside a git repository" (fail-closed). r3 only; r1, r2 verdicted it inside their compound list claims.
- **Claim 51** (commit 639f7b40): "after the N rules"; checkout_gate runs before them. Already Accepted-immutable (override row 527). All three agree.
- **Claim 52** (commit 639f7b40): "Each fix's mutant turns a test red"; the gitlink `-L` and unmatched-record mutants stay green (r1, r2 also name the status-stderr mutant). Already recorded (override row 529). r3 Incorrect, r1/r2 Mostly accurate.
- **Claim 53** (commit 639f7b40 Notes): "git warns" at a symlinked gitlink path; git status fails (exit 128). Immutable; test comment fixed in 368a3194. r3 Incorrect, r1/r2 Mostly accurate.

### Stale
None.

### Mostly Accurate
- **Claim 7** (`docs/working/plan-build-loop-handoff.md:284`): "no repo-local GIT_* variable" omits the exemptions (caller config pairs, GIT_NO_REPLACE_OBJECTS, GIT_PREFIX), which harden always sets.
- **Claim 12** (`scripts/build-loop.sh:119-135`): help folds an unreadable HEAD into "another commit" and an unparseable tree record into "a listing ... that fails"; "a quote" means a double quote only.
- **Claim 14** (`scripts/build-loop.sh:129-132`): a newline name is refused under the index-bits WHY, a gitlink symlink under the git status WHY, not their own rules' WHYs.
- **Claim 27** (`scripts/build-loop.sh:629-630`): the code no longer skips an unmatched record; without the C locale it is refused as unreadable, not let through.
- **Claim 33** (`scripts/build-loop.sh:659-660`): under pipefail a reader that finds nothing can mask the listing's status; one that stops early causes a spurious failure, not a hidden one.
- **Claim 39** (`scripts/build-loop.sh:736-737`): "about 0.25 s" is the low end; re-measured 0.31-0.36 s under load ("about 0.25-0.35 s").
- **Claim 40** (`scripts/build-loop.sh:738`): "times the self-merge briefs in one --check" carries the compound Mostly-accurate verdicts of the slot-count claims; every replicate's text says the multiplication itself holds.
- **Claim 41** (`scripts/build-loop.sh:738`): "at most the slot count" is not enforced; --check takes any number of briefs and D9 frees a slot at `ready`.
- **Claim 50** (commit c10b972a): "0.14 s" not reproduced (~0.30-0.31 s for the whole gate here; same order).
- **Claim 57** (commit 368a3194): "before, only bash's own matching used it" holds only when the caller had not exported LC_ALL.
- **Claim 59** (commit 1f4f7a21): the iteration-2 fact-check covered c10b972a..639f7b40; only the critics covered ..368a3194.

### Unverifiable
- **Claim 2** (`docs/reviews/override-log.md:528`): the ~24 s / 50k-file figure needs that fixture repo rebuilt (r1); r2 and r3 Verified it as faithfully cited from the performance i2 report.
- **Claim 37** (`scripts/build-loop.sh:732-734`): "floor walk runs only when co is empty" is U2c's future obligation; no floor call exists yet (r3); r1 and r2 Verified it as consistent with the plan.

---

## Claim 1: override row 527 "639f7b40's subject and A4-A6 bullet say the checkout is judged 'after the merge and the N rules'; checkout_gate runs before the N rules and the per-path loop ... corrected in 368a3194"

**Location:** `docs/reviews/override-log.md:527`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the quoted subject/bullet text, the call position in check_line and the files 368a3194 changed; does not establish whether Accepted-immutable is the right disposition.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2: "does not establish whether Accepted-immutable is the right disposition (author's call)" · r3: "does not establish that every other 'after' phrasing on the branch was corrected" · r3: 368a3194's file list also includes `docs/working/known-issues-dev-cycle.md`

(From r1.) 639f7b40's subject reads `judge the checkout per self-merge brief after the N rules` and its A4-A6 bullet `after the merge and the N rules` (`git show -s 639f7b40`). The call is at `scripts/build-loop.sh:739` (`co=""; if [[ "$pol" == self-merge ]] && ! checkout_gate; then ...`), before the N-rules loop at `:751-755`. `git show 368a3194 --stat` lists `scripts/build-loop.sh`, `docs/working/plan-build-loop-handoff.md` and the bats file, and its diff removes `-# failure. check_line calls it for each self-merge brief, after the N rules and` and the plan's `after the merge and the N rules`.

**Evidence:** `scripts/build-loop.sh:739`, `scripts/build-loop.sh:751-755`, commits 639f7b40, 368a3194

---

## Claim 2: override row 528 "Per-brief checkout_gate multiplies its cost by the self-merge briefs in one --check (0.24 s each here; ~24 s for nine on a 50k-file repo with a 200 MB binary)"

**Location:** `docs/reviews/override-log.md:528`
**Type:** Performance
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the per-brief multiplication (executed) and the order of the per-run cost on this repo; does not establish the ~24 s figure for a 50k-file, 200 MB repo, which was not rebuilt.
**Replicate verdicts:** r1=Unverifiable · r2=Verified · r3=Verified
**Replicate annotations:** r2+r3: the ~24 s is traced to its source, `docs/reviews/performance-reviewer-review-2026-10-08-build-loop-u2b2-i2.md:43` ("~2.7 s per gate) nine briefs would cost about 24 s"), a projection (9 × ~2.7 s), not re-measured · r2: re-measured gate ≈0.31-0.36 s under load average 3.0 · r3: re-measured ≈0.28 s at load 1.06 · r1: per-run 0.29-0.79 s under load ~3, "consistent with 0.24 s on an idle machine but not a measurement of it"

(From r1.) The multiplication is real: with four self-merge briefs in one `--check`, all four printed the checkout refusal (probe P3, `$L/probe2.out`), so checkout_gate ran once per brief. A per-run cost on a clone of main (3,163 files) measured 0.29-0.79 s while another session's full bats run held the load average at about 3 (`$L/timing.out`, `$L/timing2.out`). The 50k-file figure needs that fixture repo rebuilt (paraphrased — no quote available because the figure comes from the iteration-2 performance report, not from code).

Commands: `timeout 300 bash $L/probe2.sh` and `timeout 300 bash $L/timing.sh`, cwd their own `mktemp -d /tmp/fcf-$$-XXXX` dirs; exit 0; 2026-10-09T01:37:38Z, 01:38:37Z, 01:38:55Z.

**Evidence:** `scripts/build-loop.sh:775-778`, `$L/probe2.out`, `$L/timing.out`, `$L/timing2.out`

---

## Claim 3: override row 529 "Three green mutants: the gitlink -L test, the unparseable ls-tree record refusal (unreachable under LC_ALL=C), the stderr-only half of the git status rule"

**Location:** `docs/reviews/override-log.md:529`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers these three mutants at 1f4f7a21 against the five U2b2 tests; does not establish that no fourth green mutant exists (two more found, Claim 48's scope).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: "does not establish that the three branches are unreachable in every environment (only that no U2b2 test reaches them)" · r2: two more green mutants found (m1b `local` without `-x`; m11 no `import_reset`) · r3: "does not establish that the full 106-test check suite stays green under them (only `-f U2b2` was run per mutant)"

(From r2.) Each mutant was applied by a perl substitution to an archive copy of 1f4f7a21 and run with `bats -f U2b2`: `m0-none`, `m3-nosymlinktest`, `m6-skiprecord`, `m7-nostatusstderr` each `bats exit 0 (5 ok, 0 not ok)`. m3 changes `if [[ -L "$p" ]] || {` to `if {` (:673); m6 makes `[[ "$r" =~ $re ]] || continue` (:666); m7 drops `&& [[ ! -s "$GATE_TMP/err" ]]` (:654). The symlink case is refused earlier by git status, which exits 128 (P9: `status rc=128 stderr: error: expected submodule path 'sub' not to be a symbolic link`). r1 (M1-M3) and r3 (M3b, M8, M9) reproduced the same three green.

**Evidence:** `scripts/build-loop.sh:654`, `scripts/build-loop.sh:666`, `scripts/build-loop.sh:673`; command `timeout 3000 bash $FCR2/mut.sh`, exit 0, 2026-10-09T01:37:37Z-01:38:23Z; `$FCR2/mut-summary.log`, `$FCR2/probes.log`

---

## Claim 4: override row 530 "Verdict precedence in check_line spread over two early returns and an if-chain; callervar serves gate_repo and checkout_gate with one answer; checkout_gate lives in build-loop.sh apart from the lib contract"

**Location:** `docs/reviews/override-log.md:530`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the cited finding numbers and the three structural facts; does not judge the Defer disposition.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: "'two early returns' is read as the two returns after `co` is set (`:740`, `:747`; `:750` is a third)" (r1 Confidence Medium) · r2: the cited architecture i2 finding 3 says "four early returns and a final if-chain"; r2 reads the two after `co` as :740 and :745-748 · r3: names :747 and :750 as the two

(From r2.) The cited findings exist: architecture i1 "#### F7. `checkout_gate` lives in the caller while the contract it enforces lives in the lib" (:192), and i2 "#### 3. The verdict line's precedence is now spread across four early returns and a final if-chain" (:115) and "#### 4. `callervar` merges two questions" (:141). The if-chain is :756. `callervar` is called from both `gate_repo` (:537) and `checkout_gate` (:636).

**Evidence:** `scripts/build-loop.sh:533-537`, `scripts/build-loop.sh:636`, `scripts/build-loop.sh:739-756`; `docs/reviews/architecture-review-review-2026-10-08-build-loop-u2b2.md:192`, `docs/reviews/architecture-review-review-2026-10-08-build-loop-u2b2-i2.md:115-141`

---

## Claim 5: A5 "U2b2 closes several of these for the gate (not for the walk itself): ... clean at main with core.symlinks true, core.ignoreCase and sparse checkout off, no untracked nested repository or gitlink checked out with files, and every regular file main stores hashing, unfiltered, to main's blob"

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed refusal as exercised by E1/E2/E3; "core.symlinks true" and "off" mean "not set to the refused value" (unset passes); does not establish anything about the walk, which this unit does not change.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r1: "does not establish a case-insensitive-filesystem run or a timing race" · r2: "does not establish behaviour on a case-insensitive filesystem (not available here)"

(From r3.) The refusals are in `checkout_gate` (`scripts/build-loop.sh:639-691`), e.g. `[[ "$x" != "${r%%:*}" ]] || { CHECKOUT_WHY="${v%% *} is $r"; return 1; }` (:646) and the byte comparison `[[ "$x" == "$(printf '%s\n' "${ids[@]}")" ]]` (:690). E2 P6 refused an untracked nested repo (also one inside an ignored directory); P7 refused a gitlink path holding files and passed an empty one; E3 refused an ident expansion git status could not see.

**Evidence:** `scripts/build-loop.sh:639-691`, `/tmp/fcf-1320198-M9G8/probe1.out`, `/tmp/fcf-1320198-M9G8/p4b.out`, `/tmp/fcf-944033-AxOn/logs/suites.txt`

---

## Claim 6: A5 "Still open there: start files under a symlinked directory, a FIFO start, other names one file has on a case-insensitive filesystem whose core.ignoreCase is false, and a checkout file swapped between the gate's check and the walk's read."

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers that checkout_gate has no rule against each listed case; does not establish that the list is exhaustive.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r1: a mode-120000 entry is skipped (`120000) continue ;;`, :671), so nothing under a symlinked directory is checked · r1+r2: does not establish a case-insensitive-filesystem run or a timing race

(From r3.) Untracked entries refuse only when a listed name ends in `/` (`awk '/\/$/ { n++ }'`, `scripts/build-loop.sh:662`), so an untracked symlink to a directory and an unlisted FIFO pass (paraphrased — no quote available because the claim covers absence of a rule). `core.ignoreCase` is refused only when `true` (:642-646). The gate runs once inside `check_line`, before any walk, so a later swap is outside it.

**Evidence:** `scripts/build-loop.sh:642-646`, `scripts/build-loop.sh:657-663`

---

## Claim 7: plan U2b2 bullet "checkout_gate, run per self-merge brief inside check_line once the merge's paths are read, before the N rules ... refused unless ... HEAD at MAIN_SHA, no repo-local GIT_* variable, core.symlinks true, ... A review brief does not read the checkout. check_line calls import_reset first."

**Location:** `docs/working/plan-build-loop-handoff.md:284`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the bullet's call placement, its list of conditions, and the iteration-1 additions against `checkout_gate` and `check_line`; does not establish the U2c behaviour it anticipates.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Verified · r2=Mostly accurate · r3=Verified
**Replicate annotations:** r1: "'core.ignoreCase and core.sparseCheckout false' is read as 'not true' (unset passes)"; "does not establish a global-scope core.ignoreCase (git config runs with GIT_CONFIG_GLOBAL=/dev/null, :229, so only repo, worktree and command-line scopes are read)" · r3: reads "no repo-local GIT_* variable" as "none of `--local-env-vars` except the four exempt names" (the reading under which it Verified)

(From r2.) Placement, every condition, the iteration-1 additions and `import_reset` all match the code. One imprecision: "no repo-local GIT_* variable". The code exempts the caller's config pairs, GIT_NO_REPLACE_OBJECTS and GIT_PREFIX:
```bash
# scripts/build-loop.sh:636-637
    [[ -z "${!v+set}" || "$v" == GIT_PREFIX ]] || callervar "$v" \
      || { CHECKOUT_WHY="$v is set, so git can read another work tree, index, object store or config file"; return 1; }
```
GIT_CONFIG_COUNT and GIT_NO_REPLACE_OBJECTS are in fact always set, by `harden` (:224) and the export line (:229). Read literally, the condition never holds. Precise version: "no repo-local GIT_* variable but the caller's config pairs, GIT_NO_REPLACE_OBJECTS and GIT_PREFIX".

**Evidence:** `docs/working/plan-build-loop-handoff.md:284`, `scripts/build-loop.sh:224-229`, `scripts/build-loop.sh:533`, `scripts/build-loop.sh:634-638`

---

## Claim 8: plan U2c bullet "floor runs in check_line's per-path loop only when U2b2's checkout refusal (co) is empty, never over a refused checkout; and U2c owns contract item 1, running the walk under LC_ALL=C (checkout_gate sets it only for itself)"

**Location:** `docs/working/plan-build-loop-handoff.md:286`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers agreement with check_line's comment and the scope of `checkout_gate`'s locale; does not establish U2c's code (the rule is a plan for U2c; no floor call exists in check_line today).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2+r3: the floor rule is U2c's future commitment and cannot be checked against code that does not exist yet (r3 routes it to Claim 37)

(From r2.) check_line's comment states the same rule: "U2c's floor walk, which runs per path below and only when co is empty (never over a checkout refused here)" (`scripts/build-loop.sh:733-734`). `grep -n floor scripts/build-loop.sh` finds only comments, no call. The locale is function-local: `local -x LC_ALL=C` (:631). Probe P1 shows it is unset again after the function returns (`after-return LC_ALL=[unset]`).

**Evidence:** `scripts/build-loop.sh:631`, `scripts/build-loop.sh:732-739`; `$FCR2/probes.log` (P1; command `timeout 120 bash $FCR2/probes.sh`, exit 0, 2026-10-09T01:36:51Z)

---

## Claim 9: help "a self-merge brief needs --check run from a clean checkout of the default branch's commit; WHY' (the text up to '; ' is fixed"

**Location:** `scripts/build-loop.sh:112-116`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the refusal's prefix and its self-merge-only trigger; does not establish anything about WHY texts.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r2: "does not cover a brief path holding '; ' (the path precedes that text)"

(From r1.) `co="refuse $a: a self-merge brief needs --check run from a clean checkout of the default branch's commit; $CHECKOUT_WHY"` (`:739`) is the only producer, behind `[[ "$pol" == self-merge ]]`; `pol` is `--status`'s POLICY field (`read -r _ _ st pol br loop sha _`, `:704`). The prefix holds no other `; `. Every U2b2 coref compares `"refuse $B: $CO; $1"` and passes.

**Evidence:** `scripts/build-loop.sh:704`, `scripts/build-loop.sh:739`, `test/scripts/build-loop-check.bats:1624-1628`, `$L/build-loop-check.bats.log`

---

## Claim 10: help "but a WHY naming a read failure is not one a clean checkout cures"

**Location:** `scripts/build-loop.sh:116-117`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the existence of read-failure WHYs under the fixed prefix; "is not one a clean checkout cures" is read as "not necessarily cured by"; an unreadable index (`:651`) might be cured by a fresh checkout, which the sentence does not exclude.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r2+r3: "does not establish which of them a re-run might cure" / "that every read failure is permanent" · r3: the WHYs that name main's own data (:664, :666, :678) are the ones a fresh checkout does not cure · r3 (Claim 13): the `${v%% *} could not be read` WHY (:645) that r1 lists here was found unreachable as a refusal line

(From r1, Confidence Medium per r1's reading caveat.) `CHECKOUT_WHY="${v%% *} could not be read"` (`:645`), `"the checkout's index could not be listed"` (`:651`), `"the default branch's tree could not be listed"` (`:664`), `"the default branch's tree could not be read"` (`:666`, `:678`), `"the checkout's files could not be hashed"` (`:689`) all print under the same prefix.

**Evidence:** `scripts/build-loop.sh:645-689`

---

## Claim 11: help "path and deny lines follow it as they follow a K of N refusal" and ":143 After an ok line, a K of N refusal or a checkout refusal, one line per path TREE changes"

**Location:** `scripts/build-loop.sh:117-118`, `scripts/build-loop.sh:143`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the order (verdict line, then rows) for a checkout refusal with one or more changed paths and the zero-path case; does not establish U2c's future rows.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r2: "does not establish output when the blob or lower-casing refusal fires (they replace it)" · r1+r3: with zero changed paths the checkout refusal prints alone, as an ok line does

(From r1.) `if [[ -n "$co" ]]; then echo "$co"; elif ... fi` then `printf '%s\n' "${rows[@]}"` (`:756-757`). With zero changed paths, `echo "${co:-ok $a $sha $tree}"; return` (`:740`) prints no rows. Executed: test 4 (`refuse ... HEAD is ...`, then `deny $B A docs/roadmap.md: $NOWN` and `path $B A work-feat-x.txt`) passes; probe P7 (branch's change already on main, dirty checkout) printed only the refusal line (`$L/probe2.out`).

**Evidence:** `scripts/build-loop.sh:740`, `scripts/build-loop.sh:756-757`, `test/scripts/build-loop-check.bats:1683-1690`, `$L/probe2.out`

---

## Claim 12: help's list of checkout refusals matches checkout_gate's refusals in both directions

**Location:** `scripts/build-loop.sh:119-135`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two-way match between the help's clauses and all 16 `CHECKOUT_WHY=` assignments in `checkout_gate` (:633-691); does not establish the exact reason texts (the help lists conditions).
**Legibility-target:** for-author
**Replicate verdicts:** r1=Verified · r2=Mostly accurate · r3=Verified
**Replicate annotations:** r1: counts 18 `CHECKOUT_WHY=` assignments; "the unreadable-HEAD case (`x="unreadable"`, `:639`) is folded into 'HEAD at another commit' and the unknown-mode record (`:678`) into 'a listing ... that fails'" · r3: same two foldings noted in scope; excludes the "or one of them unreadable" clause (Claim 13) · r2: "starts with a quote" covers only a leading double quote

(From r2.) Every help clause has a matching refusal. Three refusals are folded into clauses that do not quite describe them:
- An unreadable HEAD: `x="$(git rev-parse --verify -q 'HEAD^{commit}')" || x="unreadable"` (:639), which the help covers only as "HEAD at another commit".
- An unparseable tree record, or an unexpected mode: `CHECKOUT_WHY="the default branch's tree could not be read"` (:666, :678). This is a parse failure, not "a listing or hash ... that fails" (unreachable in practice, Claim 3).
- "starts with a quote": the code refuses only a leading double quote, `"$p" != \"*` (:682). P5 confirms that hash-object unquotes only `"`.

**Evidence:** `scripts/build-loop.sh:112-140`, `scripts/build-loop.sh:633-691`

---

## Claim 13: help "core.symlinks false, core.ignoreCase or core.sparseCheckout true, or one of them unreadable"

**Location:** `scripts/build-loop.sh:124-125`
**Type:** Error-handling
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the "or one of them unreadable" atom only (the false/true atoms are Verified in Claims 12, 15); does not establish whether some other git config read failure could reach the branch, though none was found.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Verified (compound) · r2=Mostly accurate (compound) · r3=Incorrect
**Replicate annotations:** r3: "It fails closed. This is new in this pass." · r3 (Goal-Alignment): "One help clause (Claim 10) promises a refusal line that cannot be produced, because git fails earlier and the run exits 1. The outcome is still fail-closed, so this does not weaken the gate, but the exit-code contract a caller reads is different from what the help says." · r3: "The branch can stay as defense in depth." · r1+r2: listed the config read failure (:645-646) among the refusals with a help counterpart, without executing it

(From r3.) The code does have a branch for this:
```bash
# scripts/build-loop.sh:643-645 (excerpt ends :645; enclosing loop continues to :647 — read)
    rc=0; x="$(git config --type=bool --get "${v%% *}" 2>/dev/null)" || rc=$?
    r="${v#* }"
    [[ "$rc" -le 1 ]] || { CHECKOUT_WHY="${v%% *} could not be read"; return 1; }
```
But all three keys are parsed as booleans by git at the start of every command, so a value git cannot read stops every git call before `checkout_gate` runs. E2 P3 set `core.ignoreCase maybe`, then `core.sparseCheckout maybe`, then `core.symlinks maybe`. Each time `--check` printed no verdict line, exited 1, and wrote `Not inside a git repository` to stderr, from `ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "Not inside a git repository" >&2; exit 1; }` (`scripts/build-loop.sh:283`). A reader of the help expects a refusal line and exit 2, and instead gets exit 1, which the header reserves for "bad usage, not a git repo" (`scripts/build-loop.sh:168-170`). Precise version: drop "or one of them unreadable" from the help, or say that an unreadable value ends the run with exit 1 before any brief is read.

Command: `timeout 400 bash /tmp/fcf-1320198-M9G8/probe1.sh /tmp/fcf-1320198-M9G8`, cwd `/tmp/fcf-1320198-M9G8`; exit 0; 2026-10-09T01:3xZ.

**Evidence:** `scripts/build-loop.sh:124-125`, `scripts/build-loop.sh:168-170`, `scripts/build-loop.sh:283`, `scripts/build-loop.sh:641-647`, `/tmp/fcf-1320198-M9G8/probe1.out` (section P3)

---

## Claim 14: help "a regular file main stores whose name holds a newline ... (the byte comparison cannot read it)" and "a gitlink's path that is a symlink" as checkout refusals

**Location:** `scripts/build-loop.sh:129-132`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which WHY prints for these two conditions in a clean checkout; does not establish any case where the newline branch of `:682-683` or the `-L` branch of `:673` is reached.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate (compound) · r3=Verified (compound)
**Replicate annotations:** r1 (Escalate): "a misleading WHY for a newline name; fail-closed, wording only" · r2+r3 (Claims 48, 3): test 5's symlink case is refused by git status, so the `-L` test is unpinned · r3: the newline name is not exercised by test 3

(From r1.) Both conditions are refused, but under an earlier rule's WHY. A newline name splits in `git ls-files -v -z | tr '\0' '\n' | awk 'substr($0, 1, 2) != "H " { n++ } ...'` (`:650`), so the second half of the name counts as a flagged entry: probe P5 (`n\nl.md` committed on main, checkout clean) printed `the checkout's index marks entries skip-worktree, assume-unchanged or unmerged` (`$L/probe2.out`), not the name WHY. A symlink at a gitlink path fails git status first (`error: expected submodule path 'sub' not to be a symbolic link`, rc=128, `$L/probe3.out`), so it prints `git status failed or warned in the checkout`. Precise version: the newline case is refused, under the index-bits reason (a reader seeing that WHY would look for update-index flags that are not there); the symlink case under the git status reason.

Commands: `timeout 300 bash $L/probe2.sh`, `timeout 60 bash $L/probe3.sh`, cwd their own mktemp dirs; exit 0; 2026-10-09T01:38:37Z, 01:39:17Z.

**Evidence:** `scripts/build-loop.sh:650-652`, `scripts/build-loop.sh:673`, `scripts/build-loop.sh:682-683`, `$L/probe2.out`, `$L/probe3.out`

---

## Claim 15: help "a repo-local git variable set (GIT_DIR, GIT_WORK_TREE, GIT_INDEX_FILE, GIT_CONFIG and the like; the caller's GIT_CONFIG_PARAMETERS and GIT_CONFIG_COUNT pairs, GIT_NO_REPLACE_OBJECTS and GIT_PREFIX aside)"

**Location:** `scripts/build-loop.sh:121-124`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5's `--local-env-vars` list and the refusal for GIT_DIR, GIT_WORK_TREE, GIT_INDEX_FILE and GIT_CONFIG; does not run the other twelve variables individually.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r1: "does not establish the list on other git versions"

(From r2.) P3 lists all sixteen variables; GIT_CONFIG, GIT_PREFIX, GIT_NO_REPLACE_OBJECTS, GIT_CONFIG_COUNT, GIT_CONFIG_PARAMETERS, GIT_DIR, GIT_WORK_TREE and GIT_INDEX_FILE are `listed`, and `GIT_CONFIG_KEY_0: not listed`. In a clean clone of main, `GIT_DIR="$PWD/.git"` was refused: `refuse ...: ...; GIT_DIR is set, so git can read another work tree, index` (timing.log). Test 1 covers GIT_INDEX_FILE, GIT_WORK_TREE and GIT_CONFIG, and shows that caller pairs pass (`test/scripts/build-loop-check.bats:1641-1644`). r1 additionally ran `GIT_PREFIX=sub/` → `ok` (probe P2).

**Evidence:** `scripts/build-loop.sh:533`, `scripts/build-loop.sh:634-638`, `test/scripts/build-loop-check.bats:1640-1644`; `$FCR2/probes.log` (P3), `$FCR2/timing.log` (command `timeout 300 bash $FCR2/timing.sh`, exit 0, 2026-10-09T01:38:35Z)

---

## Claim 16: help "Untracked and ignored files are allowed."

**Location:** `scripts/build-loop.sh:135-136`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers untracked and ignored regular files and symlinks; an untracked nested repository (a `dir/` record) is the stated exception; an untracked file whose name starts with a newline inside a directory splits into a `dir/` line and is refused as a nested repository (fail closed).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=— · r3=Verified (compound)
**Replicate annotations:** r3: "does not cover untracked nested repositories, which are refused"

(From r1.) git status runs with `--untracked-files=no` (`:654`); the others listing counts only lines matching `/\/$/` (`:662`). Test 1 adds `CLAUDE.local.md` (ignored) and `untracked.md` and then `cook` passes.

**Evidence:** `scripts/build-loop.sh:654`, `scripts/build-loop.sh:661-663`, `test/scripts/build-loop-check.bats:1639-1641`

---

## Claim 17: help "The merge's own refusals above (a conflict, a missing blob...) come first"

**Location:** `scripts/build-loop.sh:136-137`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers precedence over the conflict, missing-blob and lower-casing refusals (all `return` before `:756`), and over earlier status/branch refusals; "come first" describes which line prints, not call order (checkout_gate runs before the missing-blob check at `:745`).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r2: "does not establish when `checkout_gate` runs relative to the blob check (it runs before it, and its result is then discarded)" · r1 (Decisions): read "come first" as output precedence, not call order · r3: "does not cover future U2c refusals"

(From r1.) Conflict returns at `:715`; missing blob at `:747` and lower-casing at `:750` return before `:756` prints `$co`. Executed: a conflicting self-merge brief over a dirty checkout printed `refuse ...: feat/c conflicts with the default branch` only (probe P1, `$L/probe2.out`).

**Evidence:** `scripts/build-loop.sh:712-757`, `$L/probe2.out`

---

## Claim 18: help "this one replaces only the verdict line, so a loop running --check from its own branch still gets the path lines"

**Location:** `scripts/build-loop.sh:137-139`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the refusal's position and the rows that follow it when the merge changes paths; does not establish output when the blob or lower-casing refusal fires (they replace it).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** none

(From r1, Claim 13.) Test 4 pins the path lines after the refusal on feat/x (`test/scripts/build-loop-check.bats:1683-1690`): `if [[ -n "$co" ]]; then echo "$co"; elif ...` then `printf '%s\n' "${rows[@]}"` (`:756-757`).

**Evidence:** `scripts/build-loop.sh:756-757`, `test/scripts/build-loop-check.bats:1683-1690`, `$L/build-loop-check.bats.log`

---

## Claim 19: help "A review brief does not read the checkout."

**Location:** `scripts/build-loop.sh:139-140`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers checkout_gate's call guard; does not establish that nothing else in --check reads the working tree for a review brief (check_brief's working-tree path test, help :50, still applies).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r2: "does not cover the walk (U2c)"; also covers a brief's own Policy line; timing agrees (review 0.12-0.135 s vs self-merge 0.42-0.48 s)

(From r1.) `co=""; if [[ "$pol" == self-merge ]] && ! checkout_gate; then` (`:739`). Executed: probe P8 (review brief, dirty tracked file) printed `ok`; mutant M12 (guard removed) turns test 4 red (`/tmp/fcf-1190629-iRp3/M12-review-reads-checkout.log`).

**Evidence:** `scripts/build-loop.sh:739`, `$L/probe2.out`, `$L/mutants.out`

---

## Claim 20: callervar comment "the caller's config pairs, which harden extends and trusts (GIT_CONFIG_PARAMETERS, GIT_CONFIG_COUNT), and GIT_NO_REPLACE_OBJECTS, which this script sets. GIT_CONFIG is not one: git config then reads that one file instead of every scope (gate_repo unsets it; checkout_gate refuses it)."

**Location:** `scripts/build-loop.sh:528-533`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three names, the GIT_CONFIG redirect for `git config`, and both consumers; "harden extends" applies to the GIT_CONFIG_COUNT pairs only (harden appends KEY_n/VALUE_n, `:220-224`; it does not touch GIT_CONFIG_PARAMETERS).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "does not establish that any other subcommand ignores GIT_CONFIG (only `git config` was probed this pass)" · r3: "does not establish behaviour on other git versions"

(From r1.) `export GIT_LITERAL_PATHSPECS=1 GIT_NO_REPLACE_OBJECTS=1 ...` (`:229`). Executed: with `core.ignoreCase true` in the repo config, `GIT_CONFIG=../cfg git config --type=bool --get core.ignoreCase` exited 1 (not found) while the plain call printed `true` (`$L/probe1.out`). `gate_repo`: `callervar "$v" || GATE_ENV+=(-u "$v")` (`:537`). Test 1's `GIT_CONFIG=... coref "GIT_CONFIG $ENVS"` passes; mutant M7 (callervar accepts GIT_CONFIG) turns test 1 red.

Command: `timeout 60 bash $L/probe1.sh`, cwd its mktemp dir; exit 0; 2026-10-09T01:36Z.

**Evidence:** `scripts/build-loop.sh:220-229`, `scripts/build-loop.sh:533-537`, `scripts/build-loop.sh:636-637`, `$L/probe1.out`, `$L/mutants.out`

---

## Claim 21: checkout_gate header "Item 2's fsmonitor and replace refs are harden's and the state gate's, and its ls-files stderr rule is the walk's own."

**Location:** `scripts/build-loop.sh:611-614`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers who handles each element item 2 names; does not establish that every ls-files call in the walk checks stderr (only `checkout_md` was read).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r1: "does not establish the floor caller's (U2c) future use"

(From r2.) harden sets `core.useReplaceRefs=false ... core.fsmonitor=false` (:221), and the export line sets `GIT_NO_REPLACE_OBJECTS=1` (:229). The state gate's key regex includes `core\.fsmonitor` (:243), and it refuses any `refs/replace/` ref (:259-260). The walk owns the stderr rule: `checkout_md() { local e; { e="$(md_ls --cached --others 2>&1 >&3)"; } 3>&1 && [[ -z "$e" ]]; }` (`scripts/lib/dev-cycle-read.sh:880`).

**Evidence:** `scripts/build-loop.sh:219-229`, `scripts/build-loop.sh:243-260`, `scripts/lib/dev-cycle-read.sh:47-51`, `scripts/lib/dev-cycle-read.sh:880`

---

## Claim 22: checkout_gate header "check_line calls it for each self-merge brief once the merge and its changed paths are read, before the N rules and U2c's floor walk run per path, so it is final before that walk"

**Location:** `scripts/build-loop.sh:616-618`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers call position within check_line and per-brief invocation; does not establish that the checkout cannot change between this call and a U2c walk (A5 lists the swap as open).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r2: "does not establish U2c's placement of the walk (not built)"; "This corrects iteration 2's Claim 7 (Incorrect at 639f7b40)" · r3: "'final before that walk' holds for the gate's decision, not against a checkout changed after the gate ran"

(From r1.) The paths are read and counted at `:723-731`; the call is at `:739`; the per-path N-rules loop is `:751-755`. `check_line` runs once per brief (`for a in "${ARGS[@]}"; do out="$(check_line "$a")"`, `:775-776`).

**Evidence:** `scripts/build-loop.sh:723-757`, `scripts/build-loop.sh:775-776`

---

## Claim 23: checkout_gate header "Item 3 is checked by its effect, not by predicting it with check-attr: every regular file main stores must hash, unfiltered, to main's blob, so no conversion (... the user's global ones included, which harden hides from the gate's own git) changed what a session reads there."

**Location:** `scripts/build-loop.sh:618-623`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers modes 100644/100755 on main; mode-120000 links are not hashed (Claim 34) and gitlinks are handled separately; does not establish anything about untracked files, which a session also reads.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r3: "filter and working-tree-encoding follow from the same byte comparison but were not run separately"; E3 executed the user's global attributesFile (`*.md ident`) case and the gate refused it while git status was empty

(From r1.) `printf '%s\n' "${ps[@]}" | git hash-object --no-filters --stdin-paths` compared to `"$(printf '%s\n' "${ids[@]}")"` (`:688-691`); no `check-attr` call exists. `core.attributesFile=/dev/null` is in harden (`:221`). Executed: an `eol=crlf` checkout gave `DIFF` and an `ident` attribute on a file with no `$Id$` gave `SAME-noid` (`$L/probe1.out`); test 2 passes; mutant M8 (comparison skipped) turns test 2 red.

**Evidence:** `scripts/build-loop.sh:221`, `scripts/build-loop.sh:665-691`, `$L/probe1.out`, `$L/mutants.out`

---

## Claim 24: checkout_gate header "Untracked and ignored files are allowed: the walk reads them as they are."

**Location:** `scripts/build-loop.sh:623-624`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers untracked and ignored plain files; the walk's reading of untracked files is taken from the lib header and was not re-traced.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r1: an untracked file whose name starts with a newline inside a directory is refused as a nested repository (fail closed)

(From r2, Claim 19.) git status runs with `--untracked-files=no` (:654), and the only untracked rule is the trailing-slash count (:662-663). Test 1 passes `cook` with an ignored `CLAUDE.local.md` and an untracked `untracked.md` (`test/scripts/build-loop-check.bats:1622-1624`).

**Evidence:** `scripts/build-loop.sh:654-663`, `test/scripts/build-loop-check.bats:1620-1648`, `$FCR2/suites-head.log`

---

## Claim 25: checkout_gate header "A nested repository's files are not walk starts (rows 366, 373), so an untracked one, or a gitlink checked out with any file, fails."

**Location:** `scripts/build-loop.sh:624-626`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two refusals and the cited override rows; an absent gitlink path is refused by git status (` D sub`) before `:676`'s `! -e` branch.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r2: "does not cover a nested repo whose `.git` is a file (not probed this pass)" · r3: also refuses a nested repo under an ignored directory (E2 P6)

(From r1.) Override rows 366 and 373 are the U2a3 rows on submodule and untracked-nested-repo files not being start files. Code: `:663` and `:676`. Test 1 (`git init -q nested; coref ...`) and test 5 (`sub/CLAUDE.md`) pass; mutants M13 and M6 turn tests 1 and 5 red.

**Evidence:** `docs/reviews/override-log.md:366`, `docs/reviews/override-log.md:373`, `scripts/build-loop.sh:661-677`, `$L/mutants.out`, `$L/probe3.out`

---

## Claim 26: checkout_gate header "Needs GATE_TMP."

**Location:** `scripts/build-loop.sh:626`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the files checkout_gate writes under GATE_TMP; does not establish the floor caller's (U2c) future use.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=— · r3=Verified (compound)
**Replicate annotations:** none

(From r1, Claim 17.) checkout_gate writes `$GATE_TMP/status`, `err`, `others`, `tree` (`:654-664`).

**Evidence:** `scripts/build-loop.sh:654-664`

---

## Claim 27: "The C locale: under UTF-8 a regex . does not match an invalid byte, and a record skipped for its name would escape the byte comparison."

**Location:** `scripts/build-loop.sh:629-630`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bash 5.2's `=~` on a 0xFF byte and what the current code does with an unmatched record; does not establish other regex engines.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Verified (compound) · r2=Mostly accurate · r3=Verified (compound)
**Replicate annotations:** r1: mutant M4 (the `local -x` line removed) turns test 2 red "(the record fails `$re` and `:666` refuses with another WHY)" · r3: "does not establish behaviour under locales other than C.utf8"

(From r2.) The first half holds. P2 printed `C.utf8: no match` and `local -x C: match` for `[[ $'a\xffb' =~ ^a.b$ ]]`. The second half describes a skip the code no longer has. Since 639f7b40 an unmatched record refuses:
```bash
# scripts/build-loop.sh:666
    [[ "$r" =~ $re ]] || { CHECKOUT_WHY="the default branch's tree could not be read"; return 1; }
```
Mutant m1 (no `local -x LC_ALL=C`) shows what the locale prevents now: test 2's non-UTF-8 name is refused with `the default branch's tree could not be read` instead of the byte-mismatch reason. That is a false refusal, not an escape. Precise version: "under UTF-8 a regex . does not match an invalid byte, so a valid record with such a name would be refused as unreadable (and, were it skipped, would escape the byte comparison)".

**Evidence:** `scripts/build-loop.sh:629-632`, `scripts/build-loop.sh:666`; `$FCR2/probes.log` (P2), `$FCR2/mut-m1-noLCALL.log` (bats exit 1, 2026-10-09T01:37Z)

---

## Claim 28: `local -x LC_ALL=C  # exported: tr, awk and git run under it too`

**Location:** `scripts/build-loop.sh:631`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers export to children when the caller has no LC_ALL, and restoration on return; does not establish that any test pins the export (mutant m1b, `local` without `-x`, stays green: 5/5).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r1: "does not establish the walk's locale (contract item 1, U2c's)"; mutant M4b (`local` without `-x`) stays green because the test exports LC_ALL

(From r2.) P1 ran under `env -u LC_ALL LANG=C.utf8` with `f() { local -x LC_ALL=C; bash -c ...; env | grep -c "^LC_ALL=C$"; }`. It printed `child LC_ALL=[C]`, `1`, and `after-return LC_ALL=[unset]`.

**Evidence:** `scripts/build-loop.sh:631`; `$FCR2/probes.log` (P1), `$FCR2/mut-m1b-notexported.log` (bats exit 0)

---

## Claim 29: "GIT_PREFIX only names a subdirectory for an alias; the script cds to the top level."

**Location:** `scripts/build-loop.sh:635`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the script's cd and that no command in checkout_gate reads GIT_PREFIX; does not establish git's alias semantics beyond its documentation.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r3: "that git itself never reads GIT_PREFIX to change behaviour comes from git's documentation, not a source trace" (r3 Confidence Medium)

(From r1.) `ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || ...; cd "$ROOT"` (`:283-284`). Executed: `GIT_PREFIX=sub/` produced `ok` (probe P2).

**Evidence:** `scripts/build-loop.sh:283-284`, `scripts/build-loop.sh:636`, `$L/probe2.out`

---

## Claim 30: "ls-files -v tags each entry: H is plain; S is skip-worktree, lower case is assume-unchanged (git status skips a change under either), M is unmerged."

**Location:** `scripts/build-loop.sh:648-649`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5 output for the four states; does not establish fsmonitor-valid lower-casing (harden sets core.fsmonitor=false).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r3: "an intent-to-add entry tags H and is left to git status"

(From r1.) `git ls-files -v` printed `H "\"q\""`, `S q`, `h r`, and `M q` three times for an unmerged path (`$L/probe1.out`). Test 1 asserts `git status --porcelain --untracked-files=no` is empty under each flag before `coref "$IDX"`; mutant M9 turns test 1 red.

**Evidence:** `scripts/build-loop.sh:650-652`, `test/scripts/build-loop-check.bats:1645-1650`, `$L/probe1.out`

---

## Claim 31: "To a file: bash would warn on stderr about the NULs a $(...) drops."

**Location:** `scripts/build-loop.sh:653`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bash 5.2.15's command-substitution warning; does not cover older bash.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

(From r2.) P8 printed `bash: line 1: warning: command substitution: ignored null byte in input` for `x="$(printf "a\0b")"`. Every `cook`/`coref` asserts an empty stderr (`[ -z "$stderr" ]`, `test/scripts/build-loop-check.bats:1612`, `:1614`).

**Evidence:** `scripts/build-loop.sh:653-656`; `$FCR2/probes.log` (P8)

---

## Claim 32: "Without --exclude-standard every untracked file is listed, ignored ones too, and a nested repository as its directory with a trailing / (no file name holds a /)."

**Location:** `scripts/build-loop.sh:657-659`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `ls-files -z --others` with an info/exclude pattern, an untracked file, a `git init` nested repo and an empty directory; does not cover `.gitignore` files at depth (the same mechanism).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1: "after `tr '\0' '\n'` a name holding a newline can yield a line ending in `/`"

(From r2.) P7 printed `nested/`, `u.txt`, `x.ign` (the ignored file). With `--exclude-standard` it printed only `nested/` and `u.txt`. The empty directory was not listed.

**Evidence:** `scripts/build-loop.sh:657-663`; `$FCR2/probes.log` (P7)

---

## Claim 33: "Listed to a file first: under pipefail a reader that stops early, or finds nothing, would hide a failed listing."

**Location:** `scripts/build-loop.sh:659-660`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the "finds nothing" half under bash's pipefail rule; does not establish the "stops early" half, which under pipefail produces a spurious failure (the writer's SIGPIPE status) rather than hiding a real one.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Verified (compound) · r2=— · r3=Mostly accurate
**Replicate annotations:** r1: "The listing's exit status is checked on its own (`> "$GATE_TMP/others" || {...}`, `:661`)"

(From r3.) Under `set -o pipefail` a pipeline returns the rightmost non-zero status (paraphrased — no quote available because this is bash's documented pipefail semantics, not repo code). A reader such as `grep` that finds nothing exits 1, and that status replaces the listing's 128. A reader that stops early (`grep -q`, `head`) makes the writer die of SIGPIPE, which shows up as a failure (141), not a hidden one. Writing to a file first (`git ls-files -z --others > "$GATE_TMP/others" || {...}`, `scripts/build-loop.sh:661`) avoids both. Precise version: "a reader that finds nothing can mask the listing's status, and one that stops early can fail it".

**Evidence:** `scripts/build-loop.sh:657-663`

---

## Claim 34: "git status compares a link's text to its blob unconverted (core.symlinks is true here)."

**Location:** `scripts/build-loop.sh:670`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a symlink under an `ident` attribute and a retargeted link with core.symlinks at its Linux default; does not cover a filesystem without symlinks (refused at :641 when core.symlinks is false).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: "does not establish other attributes on links"; a global `core.symlinks=false` checkout is refused by git status (`$L/probe4.out`) · r3: "'unconverted' ... comes from git's design and was not traced in git's source" (r3 Confidence Medium)

(From r2.) P12 committed `l -> x$Id$` with `l ident` in `.gitattributes`. After checkout the link text was `x$Id$` (not expanded) and status was clean (`link text after checkout: x$Id$ status=[]`). Retargeting it gave `retargeted status=[ M l]`. core.symlinks being true is enforced before the loop (:641-646).

**Evidence:** `scripts/build-loop.sh:641-646`, `scripts/build-loop.sh:668-671`; command `timeout 60 bash $FCR2/probe2.sh`, exit 0, 2026-10-09T01:40Z; `$FCR2/probe2.log`

---

## Claim 35: "hash-object --stdin-paths reads a line: a newline splits a name, a leading \" is unquoted and a trailing CR dropped, so another file is hashed."

**Location:** `scripts/build-loop.sh:680-681`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5's `--stdin-paths` handling of `"q"` and `r<CR>`; the newline case follows from line-reading and was not run separately.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

(From r2.) P5: the file `"q"` hashes to `d50e63...` directly, but `--stdin-paths` given `"q"` printed `d169a2...`, the hash of `q`. The file `r<CR>` hashes to `f7d55c...`, but `--stdin-paths` printed `9a6c8d...`, the hash of `r`. Mutant m10 (rule dropped) turns test 3 red.

**Evidence:** `scripts/build-loop.sh:680-684`, `test/scripts/build-loop-check.bats:1670-1676`; `$FCR2/probes.log` (P5), `$FCR2/mut-m10-noquoteCR.log` (bats exit 1)

---

## Claim 36: "import_reset  # caller contract item 4: no walk cache outlives a decision"

**Location:** `scripts/build-loop.sh:701`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the call's position (first statement of each brief's decision) and what it clears; does not establish any observable effect today (no walk runs in check_line; mutant m11 without the call stays green, 5/5).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r3: "no test pins it (E4 M12, which drops it, leaves the U2b2 tests green)"; check_line also runs in a subshell per brief (`:776`)

(From r2.) `import_reset() { IMPORTED_DONE=""; IMPORTED_MAIN_DONE=""; }` (`scripts/lib/dev-cycle-read.sh:608`). Contract item 4 reads "Call import_reset before each gate decision and after any checkout change" (`scripts/lib/dev-cycle-read.sh:63`). The call is check_line's first statement, and check_line runs once per brief.

**Evidence:** `scripts/build-loop.sh:699-701`, `scripts/lib/dev-cycle-read.sh:63-65`, `scripts/lib/dev-cycle-read.sh:608`; `$FCR2/mut-m11-noimportreset.log` (bats exit 0)

---

## Claim 37: check_line "before U2c's floor walk, which runs per path below and only when co is empty (never over a checkout refused here)"

**Location:** `scripts/build-loop.sh:732-734`
**Type:** Architectural
**Verdict:** Unverifiable
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that no floor or walk call exists in build-loop.sh yet; the rule binds U2c's future code and cannot be checked against code until U2c lands.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Unverifiable
**Replicate annotations:** r1: "'only when co is empty' is a U2c commitment, consistent with the plan's U2c bullet, not yet code"; r1 (Decisions) verdicted U2c-only commitments as consistent with the plan, not as code · r2: "does not establish U2c's code, which will have to honour 'only when co is empty'" · r3: "Recheck when U2c adds the call to the per-path loop"

(From r3.) `rg -n 'floor|main_imports' scripts/build-loop.sh` matches only comments (:119, :611, :617, :733). Today the per-path loop runs `nrules` whether or not `co` is set (`scripts/build-loop.sh:751-755`). That is the intended behaviour for the N rules, and the plan's U2c bullet records the obligation (Claim 8). Verifying this needs U2c's floor call in the loop.

**Evidence:** `scripts/build-loop.sh:732-755`, `docs/working/plan-build-loop-handoff.md:286`

---

## Claim 38: check_line "its refusal replaces the verdict line only, so the N rules' path and deny lines still print"

**Location:** `scripts/build-loop.sh:734-736`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the call position and the verdict-line replacement (executed, Claim 11); does not establish U2c's future rows.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=—
**Replicate annotations:** r2: "Today `co` is consulted only at :740 and :756"

(From r1, Claim 29.) See Claims 11 and 22: `if [[ -n "$co" ]]; then echo "$co"; elif ...` then `printf '%s\n' "${rows[@]}"` (`:756-757`); test 4 and probe P7 executed.

**Evidence:** `scripts/build-loop.sh:739-757`, `docs/working/plan-build-loop-handoff.md:286`, `$L/probe2.out`

---

## Claim 39: check_line "Run per brief, so each decision sees the checkout as it is: about 0.25 s here"

**Location:** `scripts/build-loop.sh:736-737`
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers per-brief invocation and one host's cost on this repo's 3,163 regular files; does not separate load effects.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Verified · r2=Mostly accurate (compound) · r3=Verified
**Replicate annotations:** r1: 0.290-0.689 s over five runs "under a load average of about 3 ... so the idle figure is inferred" · r3: ~0.28 s difference at load 1.06; "timings vary with load and disk cache"; "'About 0.25 s' is within that range"

(From r2.) Re-measured, the self-merge minus review difference was 0.31-0.36 s (self-merge 0.42-0.48 s, review 0.12-0.135 s, five runs each, in two scripts, load average 3.0). The performance i2 reviewer measured 0.24 s. Same order; "about 0.25 s" is the low end. Precise version: "about 0.25-0.35 s here".

**Evidence:** `scripts/build-loop.sh:737-739`; `$FCR2/timing.log`, `$FCR2/timing2.log` (commands `timeout 300 bash $FCR2/timing.sh`, `timing2.sh`, exit 0, 2026-10-09T01:38:35Z, 01:38:58Z)

---

## Claim 40: check_line "times the self-merge briefs in one --check"

**Location:** `scripts/build-loop.sh:738`
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the multiplication (accurate) and whether anything bounds it by the slot count; does not establish how U3's orchestrator will call --check.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate (compound) · r2=Mostly accurate (compound) · r3=Mostly accurate (compound)
**Replicate annotations:** r1: probe P3 (four self-merge briefs) ran checkout_gate four times · r2: its compound Mostly-accurate concerns the 0.25 s figure (Claim 39), not the multiplication · r1+r3: their compound Mostly-accurate concerns the slot bound (Claim 41), not the multiplication · r3: "The cost does multiply per self-merge brief argument"

(From r3, Claim 30.) The cost does multiply per self-merge brief argument (`for a in "${ARGS[@]}"; do out="$(check_line "$a")"`, `scripts/build-loop.sh:775-776`). Nothing in `--check` bounds the count (Claim 41).

**Evidence:** `scripts/build-loop.sh:190-201`, `scripts/build-loop.sh:775-776`

---

## Claim 41: check_line "(at most the slot count)"

**Location:** `scripts/build-loop.sh:738`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers what bounds the number of self-merge briefs in one --check run; does not establish the orchestrator's actual call pattern (U3 not built).
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate (compound) · r2=Mostly accurate · r3=Mostly accurate (compound)
**Replicate annotations:** r1: probe P3 (slots 3, four self-merge briefs) ran checkout_gate four times; precise version "at most the slot count when the orchestrator passes only dispatched briefs; --check itself takes any number" (r1 Confidence High) · r3: precise version "times the self-merge briefs passed to one --check (in practice the briefs collected that cycle)"

(From r2.) Nothing in the script bounds it. `--check` accepts any number of brief paths, repeats included:
```bash
# scripts/build-loop.sh:192-200 (excerpt)
    while [[ $# -gt 0 ]]; do
      ...
      else ARGS+=("$1"); shift; fi
    done
    [[ ${#ARGS[@]} -gt 0 ]] || usage "--check needs at least one brief path"
```
The slot count is read for `--settings` only (:428-431). The plan's D9 says "Only a live dispatched loop holds a slot. A `blocked`, `ready`-awaiting-review or `stopped` item holds none" (`docs/working/plan-build-loop-handoff.md:90`). The performance i2 report says "at most the slot count in practice" (:82). Precise version: "(in practice at most the slot count)".

**Evidence:** `scripts/build-loop.sh:190-201`, `scripts/build-loop.sh:428-431`, `scripts/build-loop.sh:775-778`, `docs/working/plan-build-loop-handoff.md:90`

---

## Claim 42: lib item 3 note "The walk checks neither item but item 2's ls-files stderr rule. build-loop.sh --check does, for each self-merge brief before the walk (U2b2; item 1's LC_ALL=C for the walk is its U2c floor caller's): harden and its state gate own item 2's fsmonitor and replace refs; checkout_gate the rest of item 2 ..., core.symlinks, and the attributes by their effect, not by check-attr"

**Location:** `scripts/lib/dev-cycle-read.sh:55-60`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the ownership split against harden, state_gate, checkout_gate and `checkout_md`; does not establish U2c's ownership of item 1 beyond the plan (Claim 8).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1: "does not establish item 2's 'final before the walk' against a concurrent writer" · r2: "'GIT_* variables' carries the same exemptions as Claim 7, here in a summary context that names no exception" · r3: "'for each self-merge brief before the walk' relies on U2c placing the walk after the gate (Claim 37)"

(From r2.) The split matches Claims 21-23, and `checkout_gate`'s locale is function-local (Claim 28). The four parts of "the rest of item 2" map to :639-640 (HEAD), :634-638 (GIT_*), :641-646 (ignoreCase, sparseCheckout, plus core.symlinks) and :650-656 (index bits and status).

**Evidence:** `scripts/lib/dev-cycle-read.sh:43-62`, `scripts/build-loop.sh:219-260`, `scripts/build-loop.sh:631-656`

---

## Claim 43: lib item 3 note "every regular file main stores hashes, unfiltered, to main's blob (so an eol conversion fails it too, and an attribute that changes no bytes does not)"

**Location:** `scripts/lib/dev-cycle-read.sh:60-62`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers eol=crlf on an LF file, and ident and eol=crlf on files they leave unchanged; does not cover filter drivers (refused by the state gate before this runs).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r3: also executed eol=lf, text, ident without `$Id$`, and working-tree-encoding=UTF-8 on plain ASCII (pass)

(From r2.) P10: `n.md` (ident, no `$Id$`) and `m.md` (eol=crlf, no newline) each hashed to their blob (`n.md blob 30d617... hashed 30d617...`, `m.md blob c79f22... hashed c79f22...`). P10b: an LF file under eol=crlf hashed differently with a clean status. Test 2 refuses the eol case (`test/scripts/build-loop-check.bats:1658-1661`).

**Evidence:** `scripts/build-loop.sh:688-691`, `test/scripts/build-loop-check.bats:1650-1668`; `$FCR2/probes.log` (P10, P10b)

---

## Claim 44: test "--check refuses a self-merge brief unless it runs from a clean checkout of main: HEAD, env, config, index bits, status, nested repositories (contract item 2, U2b2)"

**Location:** `test/scripts/build-loop-check.bats:1620`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each named area; unmerged index entries are not exercised here (E2 P9 showed their tag), nor is a GIT_DIR refusal (E2 P14).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r1: "test 1 does not create an unmerged entry" · r2: "Test 1's name says 'contract item 2' but also covers core.symlinks (item 3); this is cosmetic"

(From r3.) The test runs coref for a detached HEAD, a modified and a staged file, assume-unchanged, skip-worktree, the three core keys, GIT_INDEX_FILE, GIT_WORK_TREE, GIT_CONFIG and a nested repo. It runs cook with the caller's config pairs (`GIT_CONFIG_COUNT=1 ... cook`, :1645). E4 mutants M4, M6, M11, M13, M15 and M16 each turn this test red.

Command: `timeout 1200 bash /tmp/fcf-1429237-mgZd/runmut.sh /tmp/fcf-1429237-mgZd`; 2026-10-09T01:44:12Z-01:45:24Z.

**Evidence:** `test/scripts/build-loop-check.bats:1620-1648`, `/tmp/fcf-1429237-mgZd/mutants.out`

---

## Claim 45: test "--check refuses a self-merge brief whose checked-out bytes are not main's blob though git status is clean: ident and eol attributes, a non-UTF-8 name under a UTF-8 locale"

**Location:** `test/scripts/build-loop-check.bats:1650`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers ident, eol and the non-UTF-8 record; filter and working-tree-encoding are not exercised.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r1+r2: C.utf8 is installed (`locale -a`), so the UTF-8 path is real

(From r3.) Each case asserts `[ -z "$(git status --porcelain)" ]` before `coref "$WHY"` (:1655, :1659, :1666). E4 M5 (no byte comparison) and M1 (no C locale) each turn it red.

**Evidence:** `test/scripts/build-loop-check.bats:1650-1668`, `/tmp/fcf-1429237-mgZd/mutants.out`

---

## Claim 46: test "--check refuses a self-merge brief when main holds a file name hash-object reads as another: a leading quote, a trailing CR"

**Location:** `test/scripts/build-loop-check.bats:1670`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the quote and CR names; the newline name is not exercised.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified
**Replicate annotations:** none

(From r3.) The test runs `echo q > '"q"'; commit_all quote; coref "$NAME"` and `echo r > $'r\r'; commit_all cr; coref "$NAME"` (:1673-1675). E4 M2 turns it red, and E2 P8 confirms hash-object reads each as another file.

**Evidence:** `test/scripts/build-loop-check.bats:1670-1676`, `/tmp/fcf-1429237-mgZd/mutants.out`

---

## Claim 47: test "--check judges a review brief without its checkout, and a self-merge brief's checkout after its paths, so a loop's advisory run from its branch still lists them"

**Location:** `test/scripts/build-loop-check.bats:1678`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** "after its paths" holds in the sense that the gate runs once the paths are read and its refusal still lists them (the refusal line prints before them); covers a deny line under the checkout refusal.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r1: "'after its paths' in test 4 means the output order"

(From r3.) The review run passes in a dirty, detached checkout (:1680-1681). On feat/x the test asserts the checkout refusal as line 0 and 3 lines in all, including `deny $B A docs/roadmap.md: $NOWN` (:1687-1690). E4 M7 and M10 each turn it red.

**Evidence:** `test/scripts/build-loop-check.bats:1678-1691`, `/tmp/fcf-1429237-mgZd/mutants.out`

---

## Claim 48: test "--check refuses a self-merge brief when a gitlink's path holds files, is a symlink or cannot be listed" and its comments "an empty directory there passes (git status reports an absent one)", "git status already fails on a symlink there (exit 128), before the gitlink rule reads it."

**Location:** `test/scripts/build-loop-check.bats:1693-1705`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers all three cases as refusals; the symlink case is refused by the git status rule, as the comment says, so the gitlink rule's `-L` test is not pinned (Claim 3).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r2: "does not establish that each named case is pinned to its own rule ... nothing pins the export of `LC_ALL` (m1b green) or the `import_reset` call (m11 green)"

(From r3.) E2 P7: an absent gitlink path showed ` D sub` and was refused. An empty directory gave `ok`. A symlink made `git status ... --ignore-submodules=none` exit 128 with `error: expected submodule path 'sub' not to be a symbolic link`, and `--check` refused with "git status failed or warned in the checkout". E4 M14 and M3a turn the test red, and M3b stays green.

**Evidence:** `test/scripts/build-loop-check.bats:1693-1705`, `scripts/build-loop.sh:672-677`, `/tmp/fcf-1320198-M9G8/probe1.out` (P7), `/tmp/fcf-1429237-mgZd/mutants.out`

---

## Claim 49: commit c10b972a "checkout_gate runs once per --check when the policy is self-merge"; "Tests: three in build-loop-check.bats"; "Mutants that drop the refusal, the byte comparison or the index-bit check each turn a test red. Suites 104/19/78/2/2"; "this repo's 3,163 files"

**Location:** commit c10b972a
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers c10b972a's code, its test counts, and three mutants of it; does not rerun the full suites or scripts/health-check.sh at c10b972a.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: mutants run against HEAD's tests (not c10b972a's three tests) · r3: mutant claims rerun on HEAD's equivalents (M5, M6, M16); the fifth suite counted as utility-smoke (r1, r2 name fixture-hermeticity)

(From r2.) At c10b972a: `if [[ "$POLICY" == self-merge ]]; then checkout_gate || true; fi` in the check driver, run once before the brief loop, and check_line refuses only `if [[ "$pol" == self-merge && -n "$CHECKOUT_WHY" ]]` (`git show c10b972a:scripts/build-loop.sh`, :726, :668). `grep -c '^@test'` gives 101 on main and 104 at c10b972a, and 19/78/2/2 for the other four suites. Mutants on a c10b972a archive copy were all red: refusal guard `if false` (`0 ok, 3 not ok`), byte comparison `return 0` (test 2 red), index bits `true ||` (test 1 red). r1 and r3: `git ls-tree -r` gives 3,163.

**Evidence:** `git show c10b972a:scripts/build-loop.sh` :618-670, :726; command `timeout 900 bash $FCR2/mut-c10.sh`, exit 0, 2026-10-09T01:40:56Z-01:41:03Z; `$FCR2/mutc10-summary.log`

---

## Claim 50: commit c10b972a "It costs 0.14 s over this repo's 3,163 files."

**Location:** commit c10b972a
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the file count and c10b972a's full gate cost on this host under load; does not reproduce the author's method.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Unverifiable · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r1: "the 0.14 s figure is for c10b972a's version on an unloaded machine and was not re-measured at that commit"; "A quiet machine and c10b972a's function would be needed" · r3: gate ≈0.30 s at load 1.06; "The bare `hash-object --stdin-paths` over every file took 0.15 s, so the 0.14 s may have timed only the hashing"; "the original measurement's conditions are unknown"; immutable · r2: iteration 1 measured 0.26 s for the hash part alone

(From r2.) The count is exact: the merge base 45ca46c3 and main both hold 3,163 regular files. Under c10b972a the gate runs for any brief when the policy is self-merge. Its cost was c10b972a's review-brief time (0.43-0.45 s) minus HEAD's (0.12-0.125 s), about 0.31 s, at load average 3.0. Same order; 0.14 s not reproduced.

**Evidence:** `$FCR2/timing2.log` (command `timeout 300 bash $FCR2/timing2.sh`, exit 0, 2026-10-09T01:38:58Z)

---

## Claim 51: commit 639f7b40 subject "judge the checkout per self-merge brief after the N rules" and bullet "checkout_gate runs inside check_line for each self-merge brief, after the merge and the N rules"

**Location:** commit 639f7b40
**Type:** Architectural
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the call order at 639f7b40 and at HEAD; does not establish any behavioural consequence (the checkout refusal still wins over the K-of-N line). Already recorded Accepted-immutable (override row 527).
**Legibility-target:** for-author
**Replicate verdicts:** r1=Incorrect · r2=Incorrect · r3=Incorrect
**Replicate annotations:** r1+r2+r3: already Accepted-immutable (override row 527); code, help and plan now say "before"

(From r2.) At 639f7b40 the call is at :731 and the loop that runs `nrules` at :743 (`git show 639f7b40:scripts/build-loop.sh`). The checkout is judged before the N rules. The message is immutable, and override row 527 records it as Accepted-immutable.

**Evidence:** `git show 639f7b40:scripts/build-loop.sh` :731, :743; `scripts/build-loop.sh:739-757`; `docs/reviews/override-log.md:527`

---

## Claim 52: commit 639f7b40 "Each fix's mutant turns a test red."

**Location:** commit 639f7b40
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the mutants of 639f7b40's fixes as they stand at HEAD; the later override row (527/529) and 368a3194's Notes already record the two exceptions, so this is for the record only.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Incorrect
**Replicate annotations:** r1+r2: also count the status-stderr mutant as a third green; precise version "each fix has a mutant that turns a test red; three defensive sub-rules do not" · r2: "The message's own Notes disclose only m3"; does not rerun them at 639f7b40 · r1: already Accepted (override row 529)

(From r3.) Two of 639f7b40's fix parts have mutants that stay green (E4). One is A3's "or is a symlink" (`[[ -L "$p" ]] ||`, M3b): git status fails first. The other is A1's "any other unmatched record refuses" (`[[ "$r" =~ $re ]] || { ... }`, M8): such a record is unreachable under the C locale. A1's locale part (M1) and A3's listing part (M3a) do go red. Precise version: "each fix's mutant turns a test red, except the gitlink -L check and the unmatched-record refusal (defense in depth)".

**Evidence:** `scripts/build-loop.sh:666`, `scripts/build-loop.sh:673`, `/tmp/fcf-1429237-mgZd/mutants.out`, `docs/reviews/override-log.md:529`

---

## Claim 53: commit 639f7b40 Notes "a symlink at a gitlink path is refused by the git status rule (git warns) before the gitlink rule reads it"

**Location:** commit 639f7b40
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5; the refusal itself is correct, and only the stated mechanism ("warns") is wrong.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Incorrect
**Replicate annotations:** r1+r2: "the refusal and its order are right"; only how git signals it is wrong; the rule refuses either way with "git status failed or warned in the checkout" (:655) · r1+r2+r3: 368a3194 fixed the matching test comment; the commit message is immutable

(From r3.) E2 P7: `git status --porcelain=v1 -z --untracked-files=no --ignore-submodules=none` exits 128 with `error: expected submodule path 'sub' not to be a symbolic link`, so git fails rather than warns. 368a3194 corrected the matching test comment (`build-loop-check.bats:1703`, "git status already fails on a symlink there (exit 128)").

**Evidence:** `test/scripts/build-loop-check.bats:1703`, `/tmp/fcf-1320198-M9G8/probe1.out` (P7)

---

## Claim 54: commit 639f7b40 "Suites 106/19/78/2/2; shellcheck clean"

**Location:** commit 639f7b40
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the counts at 639f7b40 and a pass at HEAD (639f7b40..HEAD changes 2 test lines, no test count); shellcheck as health-check.sh runs it (`-x -e SC1091 -s bash -S warning`).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r2+r3: at default severity shellcheck reports one info note, SC2015 at `scripts/build-loop.sh:654` (exit 1), which `-S warning` ignores · r2: does not rerun shellcheck at 639f7b40 · r1: first build-loop-read run's one failure was r1's archive lacking `docs/dev-cycle.md`; rerun 19/19

(From r1.) Counts at 639f7b40: 106, 19, 78, 2, 2. At HEAD all pass: build-loop-check 106/106, build-loop-read 19/19, dev-cycle 78/78, fixture-git-env 2/2, fixture-hermeticity 2/2. Shellcheck exit 0 on build-loop.sh, the lib and the bats file.

Commands: the suite loop in `/tmp/fcf-1061983-oHCM` (2026-10-09T01:36:18Z, exits 0/1/0/0/0, then the read-suite rerun at 01:38:03Z, exit 0); `shellcheck -x -e SC1091 -s bash -S warning FILE` (01:39:43Z, exits 0).

**Evidence:** `$L/suites.summary`, `$L/build-loop-read.rerun.log`, `$L/shellcheck2.out`

---

## Claim 55: commit 639f7b40 "five U2b2 tests (from three)"; "Every cook/coref now asserts an empty stderr"

**Location:** commit 639f7b40
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the counts at 639f7b40 (unchanged at HEAD) and the helpers' stderr assertions.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=— · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** none

(From r2, Claim 36d.) `grep -c '^@test'` at 639f7b40 gives 106 for build-loop-check, which is 104 + 2 new tests. Both helpers end with `[ -z "$stderr" ]` (`test/scripts/build-loop-check.bats:1612`, `:1614`). One HEAD run printed `1..207`, 207 `ok`, no `not ok`, exit 0.

**Evidence:** `test/scripts/build-loop-check.bats:1609-1614`; `$FCR2/suites-head.log` (exit 0, 2026-10-09T01:36:20Z-01:37:52Z)

---

## Claim 56: commit 639f7b40 "no red, nine ambers, all fixed here ... New cases: GIT_WORK_TREE, GIT_CONFIG, the caller's config pairs passing, skip-worktree hiding a real change, a non-UTF-8 name under C.utf8, quote and CR names, an advisory run from feat/x listing a deny line, a gitlink unlistable or a symlink"

**Location:** commit 639f7b40
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers rubric statuses A1-A9 and the listed test cases; "scripts/health-check.sh passed" was not rerun.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=— · r2=— · r3=Verified (compound) · single-replicate detection
**Replicate annotations:** none

(From r3, Claim 41.) The rubric's iteration 1 lists A1-A9, each "Fixed in 639f7b40", under "🔴 Must Fix: None" (`docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b2.md:13-27`). Each listed case is in the tests (Claims 44-48).

**Evidence:** `docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b2.md:11-27`, `test/scripts/build-loop-check.bats:1604-1705`, `/tmp/fcf-944033-AxOn/logs/suites.txt`

---

## Claim 57: commit 368a3194 "`local -x LC_ALL=C`, so tr, awk and git inherit the C locale (before, only bash's own matching used it, claim 23)."

**Location:** commit 368a3194
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bash 5.2.15's handling of a `local` over an exported variable; the "now" half is Verified (Claim 28).
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Verified (compound) · r3=Mostly accurate
**Replicate annotations:** r1: "That is why mutant M4b (`local` without `-x`) stays green: the test exports LC_ALL" · r3: the bats fixtures export LC_ALL (`test/lib/build-loop-fixtures.bash`); immutable · r2: Claim 21 notes the earlier `local LC_ALL=C` "reached children only if the caller had exported LC_ALL" while verdicting the commit's compound claim Verified

(From r1.) The "now" half holds. The "before" half holds only when the caller had not exported LC_ALL: `g(){ local LC_ALL=C; env | grep "^LC_ALL"; }` printed `LC_ALL=C` when called with `LC_ALL=C.utf8` in the environment and `none` when LC_ALL was unset (shell probe, 2026-10-09T01:37Z). Precise version (r3): "before, children inherited it only when the caller had exported LC_ALL".

**Evidence:** `scripts/build-loop.sh:631`, `$L/mutants.out`

---

## Claim 58: commit 368a3194 "found three Incorrect claims with one cause ... three mutants stay green, as the fact-check recorded: the gitlink -L test (git status fails first), the unparseable-record refusal (unreachable under the C locale), and the stderr-only half of the git status rule" and its list of corrections

**Location:** commit 368a3194
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each claim number against the iteration-2 report, and each fix against HEAD; does not re-verify the iteration-2 report's own verdicts.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** none

(From r2.) The iteration-2 report lists Incorrect claims 7, 17 and 22, all about the "after the N rules" order (`docs/reviews/code-fact-check-report-build-loop-u2b2-i2.md`, "Claims Requiring Attention"). Claims 4, 16, 21 and 23 there are the ones named. The fixes are present: the export, the callervar wording, the test comment (:1703), and A5's list. The three green mutants were reproduced (Claim 3).

**Evidence:** `docs/reviews/code-fact-check-report-build-loop-u2b2-i2.md:520-544`, `scripts/build-loop.sh:528-532`, `scripts/build-loop.sh:631`, `test/scripts/build-loop-check.bats:1703`; `$FCR2/probes.log` (P1), `$FCR2/mut-summary.log`

---

## Claim 59: commit 1f4f7a21 "Iteration 2 (k=1, full panel over c10b972a..368a3194)"

**Location:** commit 1f4f7a21
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the commit and scope headers of the iteration-2 reports.
**Legibility-target:** for-author
**Replicate verdicts:** r1=— · r2=Mostly accurate · r3=Verified (compound)
**Replicate annotations:** none

(From r2.) The four critics' i2 reports carry `Commit: 368a3194` and scope `c10b972a..368a3194`. The iteration-2 fact-check carries `Commit: 639f7b40` and scope `c10b972a..639f7b40`. 368a3194 was its fix, so the panel's fact-check stage did not cover 368a3194. Precise version: "fact-check over c10b972a..639f7b40, critics over c10b972a..368a3194".

**Evidence:** `docs/reviews/code-fact-check-report-build-loop-u2b2-i2.md:1-7`, `docs/reviews/security-reviewer-review-2026-10-08-build-loop-u2b2-i2.md:1-3`, `docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b2.md` (Iteration 2 heading)

---

## Claim 60: commit 1f4f7a21 "found no red and no security finding"

**Location:** commit 1f4f7a21
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the rubric's iteration-2 tables and the security i2 summary; does not re-derive the panel's findings.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=— · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r1: "'found no red and no security finding' is the rubric's record, not re-derived"

(From r2, Claim 38b.) The rubric's iteration 2 reads `### 🔴 Must Fix` / `None.`, and the security i2 report's Findings section reads "No findings."

**Evidence:** `docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b2.md` (Iteration 2), `docs/reviews/security-reviewer-review-2026-10-08-build-loop-u2b2-i2.md:32-34`

---

## Claim 61: commit 1f4f7a21 B2, C1, C2, C4 items, the four override rows, and "the U2b2 tests (5/5) and shellcheck pass"

**Location:** commit 1f4f7a21
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that each named edit is present at HEAD and the 5/5 and shellcheck results; "shellcheck pass" holds at the health check's warning severity, not at default severity (SC2015 info).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r2+r3: shellcheck passes at `-S warning` only; an info-level run reports SC2015 at `scripts/build-loop.sh:654`

(From r1.) B2: `:733-734` and plan :286; C1: lib :57 and plan :286; C2: help :115-118 and `a regular file main stores whose name` (:130); C4: `:736-738`. Override rows 527-530 match the four listed dispositions. The U2b2 tests pass 5/5 (M0 control) and shellcheck exits 0 (Claim 54).

**Evidence:** `scripts/build-loop.sh:115-130`, `scripts/build-loop.sh:732-738`, `scripts/lib/dev-cycle-read.sh:57`, `docs/reviews/override-log.md:527-530`, `$L/mutants.out`, `$L/shellcheck2.out`

---

## Escalations

1. **Misleading WHY for a newline file name** — `scripts/build-loop.sh:650` (help `:129-132`, name rule `:682-683`). A newline name on main is refused under the index-bits WHY, not the name WHY; fail-closed, wording only. Raised by: r1 (Goal-Alignment Escalate: Claim 11b → merged Claim 14). Addressee: orchestrator.
2. **Global/system core.ignoreCase and core.sparseCheckout not seen** — `scripts/build-loop.sh:641-646` (env `:229`). checkout_gate reads these keys with GIT_CONFIG_GLOBAL=/dev/null and GIT_CONFIG_NOSYSTEM=1, so a global or system setting is not seen (a global core.symlinks=false is still caught, by git status: `$L/probe4.out`). Raised by: r1 (Goal-Alignment Escalate, "Residue for the security pass"; also r1 Claim 6 scope → merged Claim 7 annotation). Addressee: security-reviewer.
3. **Green mutants: do they deserve tests?** — `scripts/build-loop.sh:654`, `:666`, `:673` (and the unpinned `local -x` at `:631`, `import_reset` at `:701`). Raised by: r2 (Out of scope: "whether the green mutants deserve tests (security/test-strategy call)"). Addressee: security-reviewer, test-strategy.
4. **Help's "or one of them unreadable" exit-code contract** — `scripts/build-loop.sh:124-125` (exit codes `:168-170`, `:283`). The help promises a refusal line (exit 2); the run exits 1 with "Not inside a git repository". Raised by: r3 (Goal-Alignment note; Claim 10 → merged Claim 13). Addressee: orchestrator.
5. **Recheck the floor-only-when-co-empty rule when U2c lands** — `scripts/build-loop.sh:732-734`, `:751-755`. Raised by: r3 (Claim 28 → merged Claim 37: "Recheck when U2c adds the call to the per-path loop"); r1, r2 annotate it as a U2c commitment. Addressee: orchestrator.
6. **Unreproduced measurements** — `docs/reviews/override-log.md:528` (~24 s needs the 50k-file, 200 MB fixture rebuilt) and commit c10b972a (0.14 s needs c10b972a's function timed on an idle machine). Raised by: r1 (Claims 2, 35 → merged Claims 2, 50). Addressee: orchestrator.

r2's Goal-Alignment `Escalate:` reads "none blocking"; r3 has no `Escalate:` field.

---

## Verdict stability

- **Total clusters:** 61
- **Agreeing clusters** (all reporting replicates gave the same verdict, compound verdicts included): 47
- **Disagreeing clusters:** 14
  - Claim 2: r1=Unverifiable · r2=Verified · r3=Verified
  - Claim 7: r1=Verified · r2=Mostly accurate · r3=Verified
  - Claim 12: r1=Verified · r2=Mostly accurate · r3=Verified
  - Claim 13: r1=Verified (compound) · r2=Mostly accurate (compound) · r3=Incorrect
  - Claim 14: r1=Mostly accurate · r2=Mostly accurate (compound) · r3=Verified (compound)
  - Claim 27: r1=Verified (compound) · r2=Mostly accurate · r3=Verified (compound)
  - Claim 33: r1=Verified (compound) · r2=— · r3=Mostly accurate
  - Claim 37: r1=Verified (compound) · r2=Verified (compound) · r3=Unverifiable
  - Claim 39: r1=Verified · r2=Mostly accurate (compound) · r3=Verified
  - Claim 50: r1=Unverifiable · r2=Mostly accurate · r3=Mostly accurate
  - Claim 52: r1=Mostly accurate · r2=Mostly accurate · r3=Incorrect
  - Claim 53: r1=Mostly accurate · r2=Mostly accurate · r3=Incorrect
  - Claim 57: r1=Mostly accurate · r2=Verified (compound) · r3=Mostly accurate
  - Claim 59: r1=— · r2=Mostly accurate · r3=Verified (compound)
- **Agreement rate:** 47/61 = 77.0%
- Single-replicate clusters: Claim 56 (r3 only). Claim 13's Incorrect is r3's alone; r1 and r2 verdicted it only inside compound claims. Clusters with one replicate absent: Claims 16, 26, 33, 38, 55, 59, 60.

## Submitted Claims

## Claim 62: "A checkout made under a global `core.sparseCheckout=true` — a setting the gate's own config read does not see (GIT_CONFIG_GLOBAL=/dev/null) — is refused for a self-merge brief, through the skip-worktree index-bit rule."

**Submitted by:** security-reviewer
**Location:** `scripts/build-loop.sh:650-652`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a checkout whose sparse-checkout under a global-only `core.sparseCheckout=true` left a main file outside the patterns (index tag `S`); the gate's config read sees nothing and the `ls-files -v` rule refuses it. Does not establish anything about cone-mode or `index.sparse` sparse indexes (not built), and a global sparseCheckout whose patterns cover every file sets no S bit and passes, correctly, since that checkout is complete.

The config-read arm cannot see a global setting. The script exports `GIT_CONFIG_GLOBAL=/dev/null` (`scripts/build-loop.sh:229`, `export GIT_LITERAL_PATHSPECS=1 ... GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 ...`), and checkout_gate reads only `git config --type=bool --get "${v%% *}"` (`:641-647`). The index-bit rule reads the checkout's index, not config:

```bash
# scripts/build-loop.sh:650-652
  n="$(git ls-files -v -z | tr '\0' '\n' | awk 'substr($0, 1, 2) != "H " { n++ } END { print n + 0 }')" \
    || { CHECKOUT_WHY="the checkout's index could not be listed"; return 1; }
  [[ "$n" == 0 ]] || { CHECKOUT_WHY="the checkout's index marks entries skip-worktree, assume-unchanged or unmerged"; return 1; }
```

Executed. The probe added a top-level `README.md` on main and checked out under a probe-local `$HOME/.gitconfig` holding `[core] sparseCheckout = true` (repo config untouched) with `.git/info/sparse-checkout` = `/docs/`, then ran `git read-tree -mu HEAD`. Its output: `repo config core.sparseCheckout: []`, `global core.sparseCheckout: [true]`, `gate-view config read: []`, `S README.md` in `ls-files -v`, README.md absent from the work tree, and an empty user-view `git status`. The baseline `--check` was `ok ...` (exit 0). After the sparse checkout:

```
refuse docs/working/briefs/2026-10-01-x.md: a self-merge brief needs --check run from a clean checkout of the default branch's commit; the checkout's index marks entries skip-worktree, assume-unchanged or unmerged
path docs/working/briefs/2026-10-01-x.md A work-feat-x.txt
exit 2
```

Control: with the same global setting but sparse patterns `/*`, every entry was `H` and `--check` returned `ok` with exit 0.

- Command: `timeout 120 bash $LOGS/probe-62-64.sh 62`. The probe itself runs `timeout 60 bash /workspace/.claude/wt-build-loop-u2b2/scripts/build-loop.sh --check docs/working/briefs/2026-10-01-x.md` with `HOME=$d/home` and no GIT_CONFIG_GLOBAL exported.
- cwd: `/tmp/sc25u2b2-Uca4/repo`. Probe exit 0; gate exit 2. Timestamp 2026-10-09T01:59:52Z.

**Evidence:** `scripts/build-loop.sh:229`, `scripts/build-loop.sh:641-652`, `$LOGS/claim62.log`, `$LOGS/probe-62-64.sh`

---

## Claim 63: "A checkout made with repo `core.autocrlf=true` (CRLF written, git status clean) is refused for a self-merge brief by the byte comparison."

**Submitted by:** security-reviewer
**Location:** `scripts/build-loop.sh:686-691`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers repo-config `core.autocrlf=true` on LF blobs, with the index racy and with it made non-racy; in both, git status is clean and the byte comparison refuses. Does not establish `core.eol` or `text=auto` attribute variants, `core.autocrlf=input` (which writes LF and would correctly pass), or files whose blobs already hold CRLF.

The byte comparison hashes each regular file's checked-out bytes with conversions off and compares them to main's blob ids:

```bash
# scripts/build-loop.sh:686-691
  [[ ${#ps[@]} -gt 0 ]] || return 0
  # --stdin-paths: one hash-object for every file (one per path cost a process each).
  x="$(printf '%s\n' "${ps[@]}" | git hash-object --no-filters --stdin-paths 2>/dev/null)" \
    || { CHECKOUT_WHY="the checkout's files could not be hashed"; return 1; }
  [[ "$x" == "$(printf '%s\n' "${ids[@]}")" ]] \
    || { CHECKOUT_WHY="a file's checked-out bytes are not the default branch's blob (a filter, working-tree-encoding, ident or eol conversion)"; return 1; }
```

`core.autocrlf` is not in `STATE_KEYS_RE` (`scripts/build-loop.sh:243`, `'^(filter\.|include|hook\.|merge\.|diff\.|core\.fsmonitor|core\.attributesfile|core\.hookspath|gpg\.|log\.showsignature|extensions\.partialclone$|remote\..*\.promisor$)'`), so the state gate lets it through. The gate's own git status reads the repo config, applies the same conversion, and reports clean.

Executed. After `git config core.autocrlf true` and a fresh checkout of every tracked file, `od -c docs/a.md` showed `l i n e   o n e \r \n ...`, and `git status --porcelain` was empty. `--check` then printed:

```
refuse docs/working/briefs/2026-10-01-x.md: a self-merge brief needs --check run from a clean checkout of the default branch's commit; a file's checked-out bytes are not the default branch's blob (a filter, working-tree-encoding, ident or eol conversion)
exit 2
```

The probe then backdated the files and ran `git update-index -q --really-refresh`, which left status clean and the index non-racy. `--check` printed the same refusal, from the same byte rule. The baseline before autocrlf was `ok` with exit 0.

- Command: `timeout 120 bash $LOGS/probe-62-64.sh 63`, running `timeout 60 bash .../scripts/build-loop.sh --check docs/working/briefs/2026-10-01-x.md`.
- cwd: `/tmp/sc25u2b2-*/repo` (the dir is named in the log). Gate exit 2 both times. Timestamp 2026-10-09T01:59:58Z.

**Evidence:** `scripts/build-loop.sh:243`, `scripts/build-loop.sh:654-656`, `scripts/build-loop.sh:686-691`, `$LOGS/claim63.log`

---

## Claim 64: "An `ident` attribute set only by a global `core.attributesFile` (so the gate's git never sees it) yields a refused self-merge brief." (Submitter saw the git status rule refuse; verdict which rule refuses, and whether the byte-hash arm would also catch it.)

**Submitted by:** security-reviewer
**Location:** `scripts/build-loop.sh:654-656`, `scripts/build-loop.sh:686-691`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a global-only `core.attributesFile` naming `docs/i.md ident`, where the file is checked out expanded to `$Id: <sha> $`. The brief is refused in both index states tried. Which rule refuses depends on index raciness: the git status rule when the index entry is racy (as right after a checkout), the byte-hash rule when the index stat matches. Does not establish other global-only attributes (`filter`, `working-tree-encoding`, `eol`), which were not run here.

The gate's git cannot see the attribute. harden sets `core.attributesFile=/dev/null` (`scripts/build-loop.sh:221`, `for kv in ... core.attributesFile=/dev/null ...`), and `:229` exports `GIT_CONFIG_GLOBAL=/dev/null`. Two arms can therefore notice the expanded file. The first is the status rule at `:654-656`:

```bash
# scripts/build-loop.sh:654-656
  git status --porcelain=v1 -z --untracked-files=no --ignore-submodules=none > "$GATE_TMP/status" 2>"$GATE_TMP/err" && [[ ! -s "$GATE_TMP/err" ]] \
    || { CHECKOUT_WHY="git status failed or warned in the checkout"; return 1; }
  [[ ! -s "$GATE_TMP/status" ]] || { CHECKOUT_WHY="the checkout's index or tracked files differ from that commit (git status)"; return 1; }
```

The second is the `--no-filters` byte comparison at `:686-691`, quoted under Claim 63.

Executed. Under the probe HOME, `docs/i.md` read `see @docs/x$Id: 0f9460c8de7b4f783def78cdbe6b2895d712b8d4 $` and the user-view status was empty.

- **64a, right after checkout (index racy):** `--check` refused through the status rule: `refuse ...; the checkout's index or tracked files differ from that commit (git status)`, exit 2. The status rule fires because git does not trust a racily clean entry's stat and re-reads the file without the hidden attribute. That cause is inferred from git's documented racy-git handling and is consistent with 64b; it was not traced inside git. A variant with no diagnostic `git status` before the gate gave the same result (`$LOGS/claim64-nodiag.log`), so the probe's own status call did not cause it.
- **64b, files backdated and `git update-index --really-refresh` run under the global config (non-racy):** the gate-view `git status` with `GIT_OPTIONAL_LOCKS=0` was empty, so the status rule passed. `--check` refused through the byte-hash arm: `refuse ...; a file's checked-out bytes are not the default branch's blob (a filter, working-tree-encoding, ident or eol conversion)`, exit 2.

So the byte-hash arm catches it whenever the status rule does not. In the racy case the status rule's `return 1` (`:656`) fires first, so the byte arm never runs in that pass. The bytes differ in both states, so the byte arm would also refuse it.

- Command: `timeout 120 bash $LOGS/probe-62-64.sh 64` (and `$LOGS/probe-64-nodiag.sh 64`), each running `timeout 60 bash .../scripts/build-loop.sh --check docs/working/briefs/2026-10-01-x.md` with `HOME=$d/home`.
- cwd: `/tmp/sc25u2b2-*/repo`. Gate exit 2 in all four runs; baseline `ok` with exit 0. Timestamps 2026-10-09T01:59:59Z and 02:00:09Z.

**Evidence:** `scripts/build-loop.sh:221`, `scripts/build-loop.sh:229`, `scripts/build-loop.sh:654-656`, `scripts/build-loop.sh:686-691`, `$LOGS/claim64.log`, `$LOGS/claim64-nodiag.log`

---

## Claim 65: "Once `co` is set in check_line (~:739), every exit from check_line prints a first line that is not `ok` (paths ~:740, :747, :750, :756)."

**Submitted by:** security-reviewer
**Location:** `scripts/build-loop.sh:739-757`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every normal exit of check_line after `:739` with `co` non-empty. Does not establish abnormal termination: an unbound-variable abort under `set -u`, which the subshell inherits, or a signal would print no first line at all. That empty line is also not `ok`, and the caller's `[[ "$out" == "ok "* ]] || fails=1` (`:777`) counts it as a failure.

The whole function after `:739` was read through its closing brace (`:758`). The read covered `nrules` (`:590-610`) and the lib helpers it and `:750` call (`pathform`, `truthrule`, `nul_list`, `lower_all` in `scripts/lib/dev-cycle-read.sh:191-200`, `:1096-1107`, `:859`, `:864`). None of them calls `exit` or `echo`s to stdout. The statements after `:739` that can end the function are these:

```bash
# scripts/build-loop.sh:739-740
  co=""; if [[ "$pol" == self-merge ]] && ! checkout_gate; then co="refuse $a: a self-merge brief needs --check run from a clean checkout of the default branch's commit; $CHECKOUT_WHY"; fi
  if [[ ${#ps[@]} -eq 0 ]]; then echo "${co:-ok $a $sha $tree}"; return; fi
# :747
    echo "refuse $a: the merge of $br names a blob the object store lacks"; return
# :750
  if ! nul_list lps lower_all "${ps[@]}" || [[ ${#lps[@]} -ne ${#ps[@]} ]]; then echo "refuse $a: the paths the merge of $br changes could not be lower-cased"; return; fi
# :756-757
  if [[ -n "$co" ]]; then echo "$co"; elif [[ "$nd" -eq 0 ]]; then echo "ok $a $sha $tree"; else echo "refuse $a: $nd of ${#ps[@]} changed paths refused in the merge of $sha (tree $tree)"; fi
  printf '%s\n' "${rows[@]}"
```

- `:740` prints `$co` when it is set, because of `${co:-...}`.
- `:747` and `:750` print fixed `refuse` lines.
- `:756` tests `-n "$co"` before the `ok` branch.
- The loop at `:751-755` only appends to `rows`.
- `:757` prints after the first line.

`co` always begins `refuse `. The script runs `set -euo pipefail` (`:172`). check_line is called as `out="$(check_line "$a")"` (`:776`), and without `inherit_errexit`, bash 5.2 clears `-e` in command substitutions; a grep finds no `shopt` in `scripts/build-loop.sh`. So no failing statement exits early and silently, apart from the `set -u` case named in Scope. The executed runs for claims 62-64 match: each refusal printed `refuse` first and then the `path` row.

**Evidence:** `scripts/build-loop.sh:172`, `scripts/build-loop.sh:739-758`, `scripts/build-loop.sh:776-777`, `scripts/build-loop.sh:590-610`, `scripts/lib/dev-cycle-read.sh:191-200`, `scripts/lib/dev-cycle-read.sh:859-864`, `scripts/lib/dev-cycle-read.sh:1096-1107`

---

## Claim 66: "One `git hash-object --stdin-paths` process hashes all regular files per gate pass: the number of processes checkout_gate spawns is fixed, independent of the number of tracked files."

**Submitted by:** performance-reviewer
**Location:** `scripts/build-loop.sh:628-692`
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers external execs and forks across 10 vs 2,000 regular files, and across 0 vs 5 gitlinks. Does not establish the cost of the bash-side per-entry loop, which is builtin-only but linear CPU. The precise version is: fixed for regular files and symlinks, plus one forked subshell and one `ls` per gitlink whose directory exists in the checkout.

The first half holds. One pipeline hashes every collected path:

```bash
# scripts/build-loop.sh:688
  x="$(printf '%s\n' "${ps[@]}" | git hash-object --no-filters --stdin-paths 2>/dev/null)" \
```

The per-entry loop (`:665-685`) uses only builtins for 100644, 100755 and 120000 entries. The second half needs a qualifier. Gitlink entries, which are tracked, spawn a subshell and an `ls` each when their directory exists:

```bash
# scripts/build-loop.sh:673
        if [[ -L "$p" ]] || { [[ -e "$p" ]] && ! x="$(ls -A -- "$p" 2>/dev/null)"; }; then
```

Executed with exec-logging shims on PATH for git, tr, awk, ls and the other externals, plus the `/proc/stat` `processes` delta (min of 3 runs). Each repo was run once as self-merge and once as review; the difference is checkout_gate's share:

| repo | self-merge execs | review execs | delta | system forks (sm / rv) |
|---|---|---|---|---|
| 10 files | 94 | 80 | 14 (10 git, 2 tr, 2 awk) | 185 / 163 |
| 2,000 files | 94 | 80 | 14 | 189 / 163 |
| 10 files + 5 gitlinks (empty dirs) | 99 (incl. `5 ls`) | 80 | 19 | 195 / 163 |

- Command: `timeout 300 bash $LOGS/probe-66.sh`, running `timeout 120 bash .../scripts/build-loop.sh --check docs/working/briefs/2026-10-01-x.md` per repo.
- cwd: `/tmp/sc25u2b2-*/<repo>`. Probe exit 0. Timestamp 2026-10-09T02:00:35Z. Load 0.49.

The fork column is system-wide and noisy (±4), but it moves by +10 for 5 gitlinks: 5 subshell forks plus 5 `ls` execs. On this worktree's tree (3,116 entries at 100644 and 58 at 100755, no gitlink) the count is fixed in practice.

**Evidence:** `scripts/build-loop.sh:665-692`, `scripts/build-loop.sh:673`, `scripts/build-loop.sh:688`, `$LOGS/claim66.log`, `$LOGS/probe-66.sh`

---

## Claim 67: "One checkout_gate pass costs about 0.27-0.28 s on this worktree (~3,170 files) at low load, and nine passes about 2.55 s."

**Submitted by:** performance-reviewer
**Location:** `scripts/build-loop.sh:736-738`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers checkout_gate's body, extracted byte for byte from `:533` (callervar) and `:628-692`, run under the script's harden and export environment in this worktree at 1f4f7a21 (3,174 tracked entries), at load 0.45-0.61. Does not establish check_line's other costs, or behavior under higher load or a cold page cache. The in-code comment at `:737` says "about 0.25 s here", about 8% under the measured figure. That comment is not this claim's text but sits at the cited location.

The cited comment:

```bash
# scripts/build-loop.sh:736-738
  # still print (a loop's advisory run from its own branch learns them). Run
  # per brief, so each decision sees the checkout as it is: about 0.25 s here,
  # times the self-merge briefs in one --check (at most the slot count).
```

Executed: `timeout 300 bash $LOGS/probe-67.sh`, cwd `/workspace/.claude/wt-build-loop-u2b2`, which is read-only. Status ran with `GIT_OPTIONAL_LOCKS=0` and hash-object without `-w`. `MAIN_SHA=HEAD=1f4f7a21247d047a9e83fa94670b01dede63d690`, probe exit 0, timestamp 2026-10-09T02:01:00Z. Uptime before was `load average: 0.45, 0.60, 0.82` and after `0.61, 0.63, 0.83`.

- The pass returned `rc=0 WHY=[]`, so the walk went to completion, through the hash-object comparison.
- Single passes (bash `time`, real): 0.271, 0.276, 0.275, 0.267, 0.271 s.
- Nine passes: 2.635, 2.550, 2.545 s.

Both figures match the claim: 0.27-0.28 s, and about 2.55 s for nine (one of three runs was 2.64).

**Evidence:** `scripts/build-loop.sh:533`, `scripts/build-loop.sh:628-692`, `scripts/build-loop.sh:736-738`, `$LOGS/claim67.log`, `$LOGS/probe-67.sh`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 66** (`scripts/build-loop.sh:673`): the process count is fixed in the number of regular files and symlinks, not in all tracked entries. Each gitlink whose directory exists adds one subshell and one `ls`. Tighten it to "independent of the number of tracked regular files".

### Unverifiable
(none)

---
