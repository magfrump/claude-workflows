Commit: 1f4f7a21
# Code Fact-Check Report

**Repository:** /workspace (worktree `/workspace/.claude/wt-build-loop-u2b2`, branch `feat/build-loop-u2b2`)
**Scope:** full branch `main...HEAD` (45ca46c3..1f4f7a21): `scripts/build-loop.sh` (read whole), `scripts/lib/dev-cycle-read.sh` 1-90 (+ the walk helpers cited), `test/scripts/build-loop-check.bats` (the five U2b2 tests), `docs/working/known-issues-dev-cycle.md` A5, `docs/working/plan-build-loop-handoff.md` U2b2/U2c bullets, the four 2026-10-08 `feat/build-loop-u2b2` rows of `docs/reviews/override-log.md`, and commit messages c10b972a, 639f7b40, 368a3194, 1f4f7a21. Final confirming pass, replicate r3 (k=3).
**Checked:** 2026-10-08 (probes run 2026-10-09T01:34Z-01:46Z UTC)
**Total claims checked:** 46
**Summary:** 37 verified, 4 mostly accurate, 0 stale, 4 incorrect, 1 unverifiable

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) read first; no claim matches a logged pattern (all five logged patterns are fabricated measured values or file-symbol associations; this run's suite counts, file count and timing figures were each recomputed). The log was not updated: none of the four Incorrect verdicts is a fabrication (no non-existent symbol, option or API), and this pass's rules allow writing only this report.

Execution provenance (all probes ran under `timeout`, in `mktemp -d "/tmp/fcf-$$-XXXX"` dirs, with `unset $(git rev-parse --local-env-vars)`, `GIT_CONFIG_GLOBAL=/dev/null`; git 2.39.5, bash 5.2.15, shellcheck 0.9.0):

- **E1 suites:** `cd /workspace/.claude/wt-build-loop-u2b2 && LC_ALL=C.UTF-8 TMPDIR=/tmp/fcf-944033-AxOn/tmp timeout 1500 bats --jobs 4 test/scripts/build-loop-check.bats test/scripts/build-loop-read.bats test/scripts/dev-cycle.bats test/scripts/fixture-git-env.bats test/scripts/utility-smoke.bats`; exit 0; 2026-10-09T01:34:37Z-01:35:32Z; 207/207 ok. Output: `/tmp/fcf-944033-AxOn/logs/suites.txt`.
- **E2 behaviour probes:** `timeout 400 bash /tmp/fcf-1320198-M9G8/probe1.sh /tmp/fcf-1320198-M9G8` (cwd `/tmp/fcf-1320198-M9G8`); exit 0; 2026-10-09T01:3xZ. Fourteen scenarios P1-P14 against fresh fixture repos (self-merge settings, brief x, feat/x). Output: `/tmp/fcf-1320198-M9G8/probe1.out`.
- **E3 global-attributes probe:** `timeout 120 bash /tmp/fcf-1320198-M9G8/p4b.sh /tmp/fcf-1320198-M9G8`; exit 0 (script), `--check` exit 2; 2026-10-09T01:45:41Z. Output: `/tmp/fcf-1320198-M9G8/p4b.out`.
- **E4 mutants:** `timeout 1200 bash /tmp/fcf-1429237-mgZd/runmut.sh /tmp/fcf-1429237-mgZd` (cwd `/tmp/fcf-1429237-mgZd`; each mutant is `git archive HEAD scripts test` with one textual edit by `mut.py`, then `bats -f U2b2 test/scripts/build-loop-check.bats`); 2026-10-09T01:44:12Z-01:45:24Z. Output: `/tmp/fcf-1429237-mgZd/mutants.out`. Baseline (unmutated copy): 5/5 ok.
- **E5 timing:** `timeout 300 bash /tmp/fcf-1429237-mgZd/t2.sh /tmp/fcf-1429237-mgZd` and `t3.sh` (same with c10b972a's `scripts/` from `git archive`), in a clone of this repo's main (3,163 regular files) with the policy line switched to self-merge, brief `tx` (self-merge) and `ty` (no Policy line), 6 runs each, twice; 2026-10-09T01:45:24Z-01:45:41Z, load average 1.06. Output: `/tmp/fcf-1429237-mgZd/timing.out`.
- **E6 shellcheck:** `cd /workspace/.claude/wt-build-loop-u2b2 && shellcheck -S warning scripts/build-loop.sh scripts/lib/dev-cycle-read.sh test/scripts/build-loop-check.bats` (the health-check's severity, `scripts/health-check.sh:480`); exit 0; 2026-10-09T01:4xZ. No output (exit status is the result; the info-level run is noted in Claim 46).
- **E7 suite counts:** `grep -c '^@test'` over `git show <c>:test/scripts/*.bats` for c10b972a, 639f7b40, 1f4f7a21 and main; inline output transcribed in Claims 38 and 41.

---

## Claim 1: "639f7b40's subject and A4-A6 bullet say the checkout is judged "after the merge and the N rules"; checkout_gate runs before the N rules and the per-path loop ... the code comment, help and plan were corrected in 368a3194"

**Location:** `docs/reviews/override-log.md:527`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the quoted wording in 639f7b40, the call position in `check_line`, and the files 368a3194 touched; does not establish that every other "after" phrasing on the branch was corrected (Claims 16, 7 check the corrected texts).
**Legibility-target:** for-orchestrator-synthesis

639f7b40's subject reads "judge the checkout per self-merge brief after the N rules" and its bullet "checkout_gate runs inside check_line for each self-merge brief, after the merge and the N rules" (quoted from `git log main..HEAD`). The code calls it before the per-path `nrules` loop:

```bash
# scripts/build-loop.sh:739-753 (excerpt ends :753; enclosing check_line continues to :758 — read)
  co=""; if [[ "$pol" == self-merge ]] && ! checkout_gate; then co="refuse $a: ..."; fi
  if [[ ${#ps[@]} -eq 0 ]]; then echo "${co:-ok $a $sha $tree}"; return; fi
  ...
    nrules "$a" "${oms[$i]}" "${nms[$i]}" "${nos[$i]}" "${ss[$i]}" "$p" "${lps[$i]}"
```

`git show --stat 368a3194` lists `scripts/build-loop.sh`, `docs/working/plan-build-loop-handoff.md`, `docs/working/known-issues-dev-cycle.md` and the test file (paraphrased — no quote available because the claim is about a commit's file list, transcribed from command output).

**Evidence:** `scripts/build-loop.sh:739-756`, `git show --stat 368a3194`, `git log 639f7b40 -1`

---

## Claim 2: "Per-brief checkout_gate multiplies its cost by the self-merge briefs in one --check (0.24 s each here; ~24 s for nine on a 50k-file repo with a 200 MB binary)"

**Location:** `docs/reviews/override-log.md:528`
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the per-brief placement and the "here" cost (reproduced at ~0.28 s); the 24 s figure is traced to its source (performance i2 report: ~2.7 s per gate on the synthetic repo × 9), not re-measured.
**Legibility-target:** for-orchestrator-synthesis

`checkout_gate` is called inside `check_line` (`scripts/build-loop.sh:739`), which the check mode runs per brief argument (`for a in "${ARGS[@]}"; do out="$(check_line "$a")"`, `scripts/build-loop.sh:775-776`). E5: a self-merge brief's `--check` took 0.39-0.43 s and a review brief's 0.12-0.13 s, a difference of ~0.28 s. The 24 s comes from `docs/reviews/performance-reviewer-review-2026-10-08-build-loop-u2b2-i2.md:43`: "in the iteration-1 synthetic repo (50k files, one 200 MB binary, ~2.7 s per gate) nine briefs would cost about 24 s".

**Evidence:** `scripts/build-loop.sh:739`, `scripts/build-loop.sh:775-776`, `docs/reviews/performance-reviewer-review-2026-10-08-build-loop-u2b2-i2.md:40-43`, `/tmp/fcf-1429237-mgZd/timing.out`

---

## Claim 3: "Three green mutants: the gitlink -L test, the unparseable ls-tree record refusal (unreachable under LC_ALL=C), the stderr-only half of the git status rule"

**Location:** `docs/reviews/override-log.md:529`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers these three mutants against the five U2b2 tests; does not establish that the full 106-test check suite stays green under them (only `-f U2b2` was run per mutant).
**Legibility-target:** for-orchestrator-synthesis

E4: `M3b_no_L` (drop `[[ -L "$p" ]] ||` from `scripts/build-loop.sh:673`), `M8_skip_bad_record` (`[[ "$r" =~ $re ]] || continue` at :666) and `M9_no_status_stderr` (drop `&& [[ ! -s "$GATE_TMP/err" ]]` at :654) each left 5/5 ok. Every other mutant in E4 (13 more) turned at least one U2b2 test red.

**Evidence:** `scripts/build-loop.sh:654`, `scripts/build-loop.sh:666`, `scripts/build-loop.sh:673`, `/tmp/fcf-1429237-mgZd/mutants.out`

---

## Claim 4: "Verdict precedence in check_line spread over two early returns and an if-chain; callervar serves gate_repo and checkout_gate with one answer"

**Location:** `docs/reviews/override-log.md:530`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the shape after `co` is computed and callervar's two callers; does not judge the design.
**Legibility-target:** for-orchestrator-synthesis

After `co` is set, two refusals return before it is printed (`echo "refuse $a: the merge of $br names a blob the object store lacks"; return`, `scripts/build-loop.sh:747`; the lower-casing refusal, :750), then `if [[ -n "$co" ]]; then echo "$co"; elif [[ "$nd" -eq 0 ]]; ...` (:756). `callervar` is called at `scripts/build-loop.sh:537` (gate_repo) and :636 (checkout_gate).

**Evidence:** `scripts/build-loop.sh:533-537`, `scripts/build-loop.sh:636`, `scripts/build-loop.sh:739-756`

---

## Claim 5: "U2b2 closes several of these for the gate (not for the walk itself): `build-loop.sh --check` refuses a self-merge brief unless the checkout it runs from is clean at main with `core.symlinks` true, `core.ignoreCase` and sparse checkout off, no untracked nested repository or gitlink checked out with files, and every regular file main stores hashing, unfiltered, to main's blob"

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed refusal as exercised by E1/E2/E3; "core.symlinks true" and "off" mean "not set to the refused value" (unset passes); does not establish anything about the walk, which this unit does not change.
**Legibility-target:** for-orchestrator-synthesis

The refusals are in `checkout_gate` (`scripts/build-loop.sh:639-691`), e.g. `[[ "$x" != "${r%%:*}" ]] || { CHECKOUT_WHY="${v%% *} is $r"; return 1; }` (:646) and the byte comparison `[[ "$x" == "$(printf '%s\n' "${ids[@]}")" ]]` (:690). E2 P6 refused an untracked nested repo (also one inside an ignored directory); P7 refused a gitlink path holding files and passed an empty one; E3 refused an ident expansion git status could not see. The walk files are untouched by the diff (`git diff --stat main...HEAD` shows only the lib header changed in `scripts/lib/`).

**Evidence:** `scripts/build-loop.sh:639-691`, `/tmp/fcf-1320198-M9G8/probe1.out`, `/tmp/fcf-1320198-M9G8/p4b.out`, `/tmp/fcf-944033-AxOn/logs/suites.txt`

---

## Claim 6: "Still open there: start files under a symlinked directory, a FIFO start, other names one file has on a case-insensitive filesystem whose `core.ignoreCase` is false, and a checkout file swapped between the gate's check and the walk's read."

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers that checkout_gate has no rule against each listed case; does not establish that the list is exhaustive.
**Legibility-target:** for-orchestrator-synthesis

Untracked entries refuse only when a listed name ends in `/` (`awk '/\/$/ { n++ }'`, `scripts/build-loop.sh:662`), so an untracked symlink to a directory (listed as a plain name) and an unlisted FIFO pass (paraphrased — no quote available because the claim covers absence of a rule: no code in `checkout_gate` tests a symlinked directory, a FIFO or the filesystem's case behaviour). `core.ignoreCase` is refused only when `true` (:642-646). The gate runs once inside `check_line`, before any walk, so a later swap is outside it.

**Evidence:** `scripts/build-loop.sh:642-646`, `scripts/build-loop.sh:657-663`

---

## Claim 7: plan U2b2 bullet: "`checkout_gate`, run per self-merge brief inside `check_line` once the merge's paths are read, before the N rules and U2c's per-path floor walk (its refusal replaces only the verdict line ...); a self-merge brief is refused unless ... HEAD at MAIN_SHA, no repo-local GIT_* variable, core.symlinks true, core.ignoreCase and core.sparseCheckout false, only plain index entries, a clean `git status`, no untracked nested repository or populated gitlink ... Iteration 1 added: ... LC_ALL=C ... GIT_CONFIG (one `callervar` rule, shared with gate_repo). A review brief does not read the checkout. `check_line` calls `import_reset` first."

**Location:** `docs/working/plan-build-loop-handoff.md:284`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every listed rule and the call position; "no repo-local GIT_* variable" means none of `git rev-parse --local-env-vars` except the four exempt names; "false" means not set true (unset passes).
**Legibility-target:** for-orchestrator-synthesis

`import_reset  # caller contract item 4` is check_line's first statement (`scripts/build-loop.sh:701`); the gate's position is as in Claim 1; `callervar` is shared (`:537`, `:636`). The exemptions: `[[ -z "${!v+set}" || "$v" == GIT_PREFIX ]] || callervar "$v"` (`:636`). E1 and E4 (M7: making review briefs read the checkout turns test 4 red) confirm the review-brief rule.

**Evidence:** `scripts/build-loop.sh:533-537`, `scripts/build-loop.sh:628-691`, `scripts/build-loop.sh:699-758`, `/tmp/fcf-1429237-mgZd/mutants.out`

---

## Claim 8: plan U2c bullet: "floor runs in check_line's per-path loop only when U2b2's checkout refusal (`co`) is empty, never over a refused checkout; and U2c owns contract item 1, running the walk under LC_ALL=C (checkout_gate sets it only for itself)"

**Location:** `docs/working/plan-build-loop-handoff.md:286`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the present-tense part ("checkout_gate sets it only for itself") and the bullet's agreement with check_line's comment; the floor rule is U2c's future obligation and is not checkable yet (see Claim 28).
**Legibility-target:** for-orchestrator-synthesis

`local -x LC_ALL=C  # exported: tr, awk and git run under it too` (`scripts/build-loop.sh:631`) is function-local; E2 P11 showed a `local -x` value reaches children and the caller's value is restored after return ("child LC_ALL=C.utf8 / after: C"). The bullet matches the code comment at `scripts/build-loop.sh:733-734`.

**Evidence:** `scripts/build-loop.sh:631`, `scripts/build-loop.sh:732-734`, `/tmp/fcf-1320198-M9G8/probe1.out`

---

## Claim 9: The help's checkout-refusal list (every refusal it lists exists; every refusal in checkout_gate is listed)

**Location:** `scripts/build-loop.sh:113-136`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the mapping between help clauses and the `CHECKOUT_WHY` assignments at :637-691, except the "or one of them unreadable" clause (Claim 10); an unreadable HEAD and an unexpected tree mode are covered only by "another commit" and "a listing ... that fails".
**Legibility-target:** for-orchestrator-synthesis

Each `CHECKOUT_WHY=` in `checkout_gate` has a help clause: GIT_* variable (:637), HEAD (:640), core keys (:646), index bits / listing (:651-652), git status failing or showing a change (:655-656), untracked listing / nested repository (:661-663), tree listing / record (:664, :666, :678), gitlink symlink-or-unlistable / with files (:674, :676), name rule (:683), hash failure / blob mismatch (:689, :691). The help names each: "has its HEAD at another commit; a repo-local git variable set ...; core.symlinks false, core.ignoreCase or core.sparseCheckout true ...; an index entry marked skip-worktree, assume-unchanged or unmerged; a change git status shows ..., or git status failing or warning; an untracked nested repository, or a gitlink's path that is a symlink, cannot be listed or holds files; a regular file main stores whose name holds a newline, starts with a quote or ends with a CR ...; or a regular file whose bytes are not main's blob ...; or a listing or hash of these that fails" (`scripts/build-loop.sh:119-136`). Nothing the help lists is missing from the code.

**Evidence:** `scripts/build-loop.sh:113-136`, `scripts/build-loop.sh:628-691`

---

## Claim 10: "core.symlinks false, core.ignoreCase or core.sparseCheckout true, or one of them unreadable" (a refusal line "... ; core.X could not be read")

**Location:** `scripts/build-loop.sh:124-125`
**Type:** Error-handling
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the "or one of them unreadable" atom only (the false/true atoms are Verified in Claims 9, 33); does not establish whether some other git config read failure could reach the branch, though none was found.
**Legibility-target:** for-author

The code does have a branch for this:

```bash
# scripts/build-loop.sh:643-645 (excerpt ends :645; enclosing loop continues to :647 — read)
    rc=0; x="$(git config --type=bool --get "${v%% *}" 2>/dev/null)" || rc=$?
    r="${v#* }"
    [[ "$rc" -le 1 ]] || { CHECKOUT_WHY="${v%% *} could not be read"; return 1; }
```

But all three keys are parsed as booleans by git at the start of every command, so a value git cannot read stops every git call before `checkout_gate` runs. E2 P3 set `core.ignoreCase maybe`, then `core.sparseCheckout maybe`, then `core.symlinks maybe`. Each time `--check` printed no verdict line, exited 1, and wrote `Not inside a git repository` to stderr. That stderr comes from `ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "Not inside a git repository" >&2; exit 1; }` (`scripts/build-loop.sh:283`). This failure blocks the merge, but a reader of the help expects a refusal line and exit 2, and instead gets exit 1, which the header reserves for "bad usage, not a git repo" (`scripts/build-loop.sh:168-170`). Precise version: drop "or one of them unreadable" from the help, or say that an unreadable value ends the run with exit 1 before any brief is read. The branch can stay as defense in depth.

**Evidence:** `scripts/build-loop.sh:124-125`, `scripts/build-loop.sh:168-170`, `scripts/build-loop.sh:283`, `scripts/build-loop.sh:641-647`, `/tmp/fcf-1320198-M9G8/probe1.out` (section P3)

---

## Claim 11: "(the text up to "; " is fixed, but a WHY naming a read failure is not one a clean checkout cures ...)"

**Location:** `scripts/build-loop.sh:115-117`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the constant prefix and that read-failure WHYs exist under it; does not establish that every read failure is permanent.
**Legibility-target:** for-orchestrator-synthesis

The line is built from one constant: `co="refuse $a: a self-merge brief needs --check run from a clean checkout of the default branch's commit; $CHECKOUT_WHY"` (`scripts/build-loop.sh:739`), and that prefix has no `; ` inside it. Some WHYs under the prefix name main's own data, not the checkout: `"the default branch's tree could not be listed"` (:664), `"the default branch's tree could not be read"` (:666, :678). A fresh checkout does not cure those.

**Evidence:** `scripts/build-loop.sh:664-678`, `scripts/build-loop.sh:739`

---

## Claim 12: "path and deny lines follow it as they follow a K of N refusal" / "After an ok line, a K of N refusal or a checkout refusal, one line per path TREE changes against main"

**Location:** `scripts/build-loop.sh:117-118`, `scripts/build-loop.sh:143`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the order (verdict, then rows) and that rows print after a checkout refusal; with zero changed paths the checkout refusal prints alone, as an ok line does.
**Legibility-target:** for-orchestrator-synthesis

`if [[ -n "$co" ]]; then echo "$co"; elif ...; fi` then `printf '%s\n' "${rows[@]}"` (`scripts/build-loop.sh:756-757`). Test 4 (`build-loop-check.bats:1678`) asserts the refusal, a deny line and a path line (3 lines). E2 P2 (a branch whose only commit is empty, run detached) printed only the checkout refusal, matching `echo "${co:-ok $a $sha $tree}"; return` (:740).

**Evidence:** `scripts/build-loop.sh:740`, `scripts/build-loop.sh:751-757`, `test/scripts/build-loop-check.bats:1678-1691`, `/tmp/fcf-1320198-M9G8/probe1.out` (P2)

---

## Claim 13: "The merge's own refusals above (a conflict, a missing blob...) come first; this one replaces only the verdict line, so a loop running --check from its own branch still gets the path lines."

**Location:** `scripts/build-loop.sh:136-139`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the conflict case (executed) and the missing-blob/lower-casing cases (static: they return after `co` is set without printing it); does not cover future U2c refusals.
**Legibility-target:** for-orchestrator-synthesis

The conflict returns at `1) echo "refuse $a: $br conflicts with the default branch"; return ;;` (`scripts/build-loop.sh:715`), before `checkout_gate` (:739). The missing-blob refusal returns at :747 even when `co` is set. E2 P1 (a conflict and a dirty checkout) printed only `refuse ...: feat/x conflicts with the default branch`. Test 4 and E2 P4/P6/P7 show path lines after a checkout refusal.

**Evidence:** `scripts/build-loop.sh:712-717`, `scripts/build-loop.sh:739-748`, `/tmp/fcf-1320198-M9G8/probe1.out` (P1)

---

## Claim 14: "Untracked and ignored files are allowed." / "A review brief does not read the checkout."

**Location:** `scripts/build-loop.sh:135-140`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers untracked and ignored plain files and review-policy briefs; does not cover untracked nested repositories, which are refused.
**Legibility-target:** for-orchestrator-synthesis

`git status ... --untracked-files=no` (`scripts/build-loop.sh:654`) does not list untracked files, and the `--others` listing refuses only `dir/` entries (:662-663). The gate runs only for `[[ "$pol" == self-merge ]]` (:739). Test 1 passes with an ignored `CLAUDE.local.md` and an untracked `untracked.md`. Test 4 passes a review brief in a dirty, detached checkout. E4 M7 turns test 4 red.

**Evidence:** `scripts/build-loop.sh:654-663`, `scripts/build-loop.sh:739`, `test/scripts/build-loop-check.bats:1620-1624`, `/tmp/fcf-1429237-mgZd/mutants.out`

---

## Claim 15: "callervar NAME: a repo-local variable (git rev-parse --local-env-vars) the gate keeps: the caller's config pairs, which harden extends and trusts (GIT_CONFIG_PARAMETERS, GIT_CONFIG_COUNT), and GIT_NO_REPLACE_OBJECTS, which this script sets. GIT_CONFIG is not one: git config then reads that one file instead of every scope (gate_repo unsets it; checkout_gate refuses it)."

**Location:** `scripts/build-loop.sh:528-533`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the predicate, both callers and git 2.39.5's handling of GIT_CONFIG; does not establish behaviour on other git versions.
**Legibility-target:** for-orchestrator-synthesis

`callervar() { [[ "$1" == GIT_CONFIG_PARAMETERS || "$1" == GIT_CONFIG_COUNT || "$1" == GIT_NO_REPLACE_OBJECTS ]]; }` (`:533`). harden extends the count: `export GIT_CONFIG_COUNT="$c"` (:224). The script sets `GIT_NO_REPLACE_OBJECTS=1` (:229). `git rev-parse --local-env-vars` lists `GIT_CONFIG`, so gate_repo's `-u` loop (:537) unsets it. E2 P13: with `core.ignoreCase true` in the repo, `GIT_CONFIG=<file without it> git config --type=bool --get core.ignoreCase` exits 1, so git config read only that file. `--check` with GIT_CONFIG set refused it with "GIT_CONFIG is set, so git can read another work tree, index, object store or config file". E4 M4 turns test 1 red.

**Evidence:** `scripts/build-loop.sh:219-229`, `scripts/build-loop.sh:533-537`, `scripts/build-loop.sh:634-638`, `/tmp/fcf-1320198-M9G8/probe1.out` (P13)

---

## Claim 16: checkout_gate header: "Item 2's fsmonitor and replace refs are harden's and the state gate's, and its ls-files stderr rule is the walk's own ... check_line calls it for each self-merge brief once the merge and its changed paths are read, before the N rules and U2c's floor walk run per path, so it is final before that walk."

**Location:** `scripts/build-loop.sh:611-618`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers who owns each part and where the call sits; "final before that walk" holds for the gate's decision, not against a checkout changed after the gate ran (A5 lists that swap as open).
**Legibility-target:** for-orchestrator-synthesis

harden sets `core.fsmonitor=false` and `core.useReplaceRefs=false` (`scripts/build-loop.sh:221`). The state gate refuses `core\.fsmonitor` keys and replace refs (`:243`, `:259-260`). The walk's stderr rule is `checkout_md() { local e; { e="$(md_ls --cached --others 2>&1 >&3)"; } 3>&1 && [[ -z "$e" ]]; }` (`scripts/lib/dev-cycle-read.sh:880`). The call follows the diff read and record count (`scripts/build-loop.sh:720-731`) and comes before `nrules` (:753).

**Evidence:** `scripts/build-loop.sh:221`, `scripts/build-loop.sh:243-260`, `scripts/build-loop.sh:720-756`, `scripts/lib/dev-cycle-read.sh:876-880`

---

## Claim 17: "Item 3 is checked by its effect, not by predicting it with check-attr: every regular file main stores must hash, unfiltered, to main's blob, so no conversion (a filter, working-tree-encoding, ident or eol attribute from any attributes source, the user's global ones included, which harden hides from the gate's own git) changed what a session reads there."

**Location:** `scripts/build-loop.sh:618-623`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers regular files (100644/100755) main stores, ident and eol (executed), and the user's global attributesFile (executed); filter and working-tree-encoding follow from the same byte comparison but were not run separately.
**Legibility-target:** for-orchestrator-synthesis

`x="$(printf '%s\n' "${ps[@]}" | git hash-object --no-filters --stdin-paths 2>/dev/null)"` is compared to main's blob ids (`scripts/build-loop.sh:688-691`). harden passes `core.attributesFile=/dev/null` and the script exports `GIT_CONFIG_GLOBAL=/dev/null` (:221, :229). E3: the file was checked out under a global config whose `attributesFile` holds `*.md ident`, the index was refreshed, and plain `git status` was empty. `--check` then refused with "a file's checked-out bytes are not the default branch's blob ...". (In E2 P4, without the settle step, git status caught the same file first through racy-timestamp rehashing.)

**Evidence:** `scripts/build-loop.sh:219-229`, `scripts/build-loop.sh:686-691`, `/tmp/fcf-1320198-M9G8/p4b.out`, `/tmp/fcf-1320198-M9G8/probe1.out` (P4)

---

## Claim 18: "Untracked and ignored files are allowed: the walk reads them as they are. A nested repository's files are not walk starts (rows 366, 373), so an untracked one, or a gitlink checked out with any file, fails. Needs GATE_TMP."

**Location:** `scripts/build-loop.sh:623-626`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers untracked nested repos (including one under an ignored directory, and an empty `git init`) and a populated gitlink; the walk's reading of untracked files is taken from the lib header and was not re-traced.
**Legibility-target:** for-orchestrator-synthesis

E2 P6: `git ls-files -z --others` listed `build/nested/` (under an ignored `build/`) and `sub/inner/`, and `--check` refused both. With only the ignored one left it still refused, and with neither it passed. P7: an empty gitlink directory passed and a populated one failed (test 5). GATE_TMP is written at :654, :661, :664.

**Evidence:** `scripts/build-loop.sh:654-676`, `/tmp/fcf-1320198-M9G8/probe1.out` (P6, P7)

---

## Claim 19: "The C locale: under UTF-8 a regex . does not match an invalid byte, and a record skipped for its name would escape the byte comparison." / "local -x LC_ALL=C  # exported: tr, awk and git run under it too"

**Location:** `scripts/build-loop.sh:629-631`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the export to children and that test 2 depends on the C locale; does not establish behaviour under locales other than C.utf8.
**Legibility-target:** for-orchestrator-synthesis

E2 P11: inside a function, `local -x LC_ALL=C.utf8` reached a child bash. The caller's value came back after return. E4 M1 (delete the line) turns test 2 red. That test runs the non-UTF-8 name `docs/\xff.md` under `LC_ALL=C.utf8`, a locale this host has (`locale -a` lists `C.utf8`).

**Evidence:** `scripts/build-loop.sh:629-632`, `test/scripts/build-loop-check.bats:1663-1668`, `/tmp/fcf-1320198-M9G8/probe1.out` (P11), `/tmp/fcf-1429237-mgZd/mutants.out`

---

## Claim 20: "GIT_PREFIX only names a subdirectory for an alias; the script cds to the top level."

**Location:** `scripts/build-loop.sh:635`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the cd and that a set GIT_PREFIX passes; that git itself never reads GIT_PREFIX to change behaviour comes from git's documentation, not a source trace.
**Legibility-target:** for-orchestrator-synthesis

`cd "$ROOT"` (`scripts/build-loop.sh:284`) runs before any mode. E2 P14: `GIT_PREFIX=docs/` gave `ok`, and `GIT_DIR=$PWD/.git` refused.

**Evidence:** `scripts/build-loop.sh:283-284`, `scripts/build-loop.sh:634-638`, `/tmp/fcf-1320198-M9G8/probe1.out` (P14)

---

## Claim 21: "ls-files -v tags each entry: H is plain; S is skip-worktree, lower case is assume-unchanged (git status skips a change under either), M is unmerged."

**Location:** `scripts/build-loop.sh:648-649`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers H, h (assume-unchanged), M (unmerged, executed) and S (test 1); an intent-to-add entry tags H and is left to git status.
**Legibility-target:** for-orchestrator-synthesis

E2 P9: a conflicted merge listed `M m.txt` three times, assume-unchanged listed `h m.txt`, and `git add -N` listed `H ita.txt`. Test 1 asserts `[ -z "$(git status --porcelain --untracked-files=no)" ]` under assume-unchanged and skip-worktree, then `coref "$IDX"` (`build-loop-check.bats:1630-1635`). E4 M6 turns test 1 red.

**Evidence:** `scripts/build-loop.sh:650-652`, `test/scripts/build-loop-check.bats:1629-1635`, `/tmp/fcf-1320198-M9G8/probe1.out` (P9)

---

## Claim 22: "To a file: bash would warn on stderr about the NULs a $(...) drops."

**Location:** `scripts/build-loop.sh:653`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bash 5.2.15.
**Legibility-target:** for-orchestrator-synthesis

E2 P10: `x="$(printf 'a\0b')"` printed `warning: command substitution: ignored null byte in input` to stderr.

**Evidence:** `scripts/build-loop.sh:653-656`, `/tmp/fcf-1320198-M9G8/probe1.out` (P10)

---

## Claim 23: "Without --exclude-standard every untracked file is listed, ignored ones too, and a nested repository as its directory with a trailing / (no file name holds a /)."

**Location:** `scripts/build-loop.sh:657-659`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5.
**Legibility-target:** for-orchestrator-synthesis

E2 P6: without `--exclude-standard`, the listing held `build/ignored.txt`, `build/nested/` and `sub/inner/`. With it, the listing held only `sub/inner/`.

**Evidence:** `scripts/build-loop.sh:661-663`, `/tmp/fcf-1320198-M9G8/probe1.out` (P6)

---

## Claim 24: "Listed to a file first: under pipefail a reader that stops early, or finds nothing, would hide a failed listing."

**Location:** `scripts/build-loop.sh:659-660`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the "finds nothing" half under bash's pipefail rule; does not establish the "stops early" half, which under pipefail produces a spurious failure (the writer's SIGPIPE status) rather than hiding a real one.
**Legibility-target:** for-author

Under `set -o pipefail` a pipeline returns the rightmost non-zero status (paraphrased — no quote available because this is bash's documented pipefail semantics, not repo code). A reader such as `grep` that finds nothing exits 1, and that status replaces the listing's 128. A caller that tolerates 1 therefore hides the failure. A reader that stops early (`grep -q`, `head`) makes the writer die of SIGPIPE, which shows up as a failure (141), not a hidden one. Writing to a file first (`git ls-files -z --others > "$GATE_TMP/others" || {...}`, `scripts/build-loop.sh:661`) avoids both. Precise version: "a reader that finds nothing can mask the listing's status, and one that stops early can fail it".

**Evidence:** `scripts/build-loop.sh:657-663`

---

## Claim 25: "git status compares a link's text to its blob unconverted (core.symlinks is true here)."

**Location:** `scripts/build-loop.sh:670`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers that a changed link target shows in git status (executed) and that core.symlinks false was already refused (:641-646); "unconverted" (no attribute applies to a symlink) comes from git's design and was not traced in git's source.
**Legibility-target:** for-orchestrator-synthesis

E2 P12: re-pointing a tracked link from `target1` to `target2` showed ` M lnk` and `--check` refused it with the git-status reason. `120000) continue ;;` (:671) skips the byte comparison for links.

**Evidence:** `scripts/build-loop.sh:641-647`, `scripts/build-loop.sh:668-671`, `/tmp/fcf-1320198-M9G8/probe1.out` (P12)

---

## Claim 26: "hash-object --stdin-paths reads a line: a newline splits a name, a leading " is unquoted and a trailing CR dropped, so another file is hashed."

**Location:** `scripts/build-loop.sh:680-681`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5.
**Legibility-target:** for-orchestrator-synthesis

E2 P8: the line `"q"` hashed to `73c52c3e...`, the hash of file `q`, not of the file named `"q"` (`37d547c4...`). The line `r\r` hashed to `331bae08...`, the hash of `r`, not of `r\r` (`415dade1...`). E4 M2 (drop the name rule) turns test 3 red.

**Evidence:** `scripts/build-loop.sh:680-684`, `/tmp/fcf-1320198-M9G8/probe1.out` (P8), `/tmp/fcf-1429237-mgZd/mutants.out`

---

## Claim 27: "import_reset  # caller contract item 4: no walk cache outlives a decision"

**Location:** `scripts/build-loop.sh:701`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what import_reset clears and that it runs first in each check_line; no test pins it (E4 M12, which drops it, leaves the U2b2 tests green), and no walk runs in check_line yet.
**Legibility-target:** for-orchestrator-synthesis

`import_reset() { IMPORTED_DONE=""; IMPORTED_MAIN_DONE=""; }` (`scripts/lib/dev-cycle-read.sh:608`). Those two variables are the cache keys both walks test (`:930`, `:979`). check_line also runs in a subshell per brief (`scripts/build-loop.sh:776`).

**Evidence:** `scripts/build-loop.sh:701`, `scripts/build-loop.sh:776`, `scripts/lib/dev-cycle-read.sh:606-608`, `scripts/lib/dev-cycle-read.sh:930`, `scripts/lib/dev-cycle-read.sh:979`

---

## Claim 28: "before U2c's floor walk, which runs per path below and only when co is empty (never over a checkout refused here)"

**Location:** `scripts/build-loop.sh:732-734`
**Type:** Architectural
**Verdict:** Unverifiable
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that no floor or walk call exists in build-loop.sh yet; the rule binds U2c's future code and cannot be checked against code until U2c lands.
**Legibility-target:** for-orchestrator-synthesis

`rg -n 'floor|main_imports' scripts/build-loop.sh` matches only comments (:119, :611, :617, :733). Today the per-path loop runs `nrules` whether or not `co` is set (`scripts/build-loop.sh:751-755`). That is the intended behaviour for the N rules, and the plan's U2c bullet records the obligation (Claim 8). Verifying this needs U2c's floor call in the loop.

**Evidence:** `scripts/build-loop.sh:732-755`, `docs/working/plan-build-loop-handoff.md:286`

---

## Claim 29: "Run per brief, so each decision sees the checkout as it is: about 0.25 s here"

**Location:** `scripts/build-loop.sh:736-737`
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers this repo's main (3,163 regular files) on this host; timings vary with load and disk cache.
**Legibility-target:** for-orchestrator-synthesis

E5: a self-merge brief's `--check` took 0.39-0.43 s against 0.12-0.13 s for a review brief at load 1.06, a difference of ~0.28 s. An earlier run at load ~3 gave 0.41-0.43 s against 0.12-0.13 s. "About 0.25 s" is within that range.

**Evidence:** `scripts/build-loop.sh:739`, `/tmp/fcf-1429237-mgZd/timing.out`

---

## Claim 30: "times the self-merge briefs in one --check (at most the slot count)"

**Location:** `scripts/build-loop.sh:738`
**Type:** Performance / Invariant
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the multiplication (accurate) and whether anything bounds it by the slot count; does not establish how U3's orchestrator will call --check.
**Legibility-target:** for-author

The cost does multiply per self-merge brief argument (Claim 2). Nothing in `--check` bounds the count. The parser takes any number of briefs (`else ARGS+=("$1"); shift; fi`, `scripts/build-loop.sh:198`), and the script never reads `SLOTS_LINE` outside `--settings` (:767). The plan's slot rule frees a slot at the `ready` marker ("A `blocked`, `ready`-awaiting-review or `stopped` item holds none", `docs/working/plan-build-loop-handoff.md:90`). So the ready self-merge briefs one --check judges are not capped by slots either. Precise version: "times the self-merge briefs passed to one --check (in practice the briefs collected that cycle)".

**Evidence:** `scripts/build-loop.sh:190-201`, `scripts/build-loop.sh:765-767`, `docs/working/plan-build-loop-handoff.md:90`

---

## Claim 31: "The walk checks neither item but item 2's ls-files stderr rule. build-loop.sh --check does, for each self-merge brief before the walk (U2b2; item 1's LC_ALL=C for the walk is its U2c floor caller's): harden and its state gate own item 2's fsmonitor and replace refs; checkout_gate the rest of item 2 (a clean checkout at MAIN_SHA, the GIT_* variables, core.ignoreCase, sparse checkout), core.symlinks, and the attributes by their effect, not by check-attr"

**Location:** `scripts/lib/dev-cycle-read.sh:55-60`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the ownership split against the code; "for each self-merge brief before the walk" relies on U2c placing the walk after the gate (Claim 28).
**Legibility-target:** for-orchestrator-synthesis

The walk's only checkout-state check is `checkout_md`'s stderr rule (`scripts/lib/dev-cycle-read.sh:880`). Ownership is as in Claim 16. checkout_gate covers HEAD (`scripts/build-loop.sh:639-640`), the variables (:634-638), `core.ignoreCase`/`core.sparseCheckout`/`core.symlinks` (:641-647) and the byte comparison (:686-691). No `check-attr` call exists in `scripts/build-loop.sh` (paraphrased — no quote available because the claim covers absence of code: `rg check-attr scripts/build-loop.sh` matches only comments).

**Evidence:** `scripts/lib/dev-cycle-read.sh:46-62`, `scripts/lib/dev-cycle-read.sh:876-880`, `scripts/build-loop.sh:628-691`

---

## Claim 32: "every regular file main stores hashes, unfiltered, to main's blob (so an eol conversion fails it too, and an attribute that changes no bytes does not)"

**Location:** `scripts/lib/dev-cycle-read.sh:60-62`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers eol=crlf on an LF file (fails), and eol=lf, text, ident without `$Id$`, and working-tree-encoding=UTF-8 on plain ASCII (pass).
**Legibility-target:** for-orchestrator-synthesis

Test 2 refuses `docs/i.md eol=crlf` under a clean git status (`build-loop-check.bats:1656-1659`). E2 P5: `docs/p.md eol=lf text ident working-tree-encoding=UTF-8` on `plain\n` gave `ok` (exit 0).

**Evidence:** `scripts/build-loop.sh:686-691`, `test/scripts/build-loop-check.bats:1650-1668`, `/tmp/fcf-1320198-M9G8/probe1.out` (P5)

---

## Claim 33: Test "--check refuses a self-merge brief unless it runs from a clean checkout of main: HEAD, env, config, index bits, status, nested repositories (contract item 2, U2b2)"

**Location:** `test/scripts/build-loop-check.bats:1620`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each named area; unmerged index entries are not exercised here (E2 P9 showed their tag), nor is a GIT_DIR refusal (E2 P14).
**Legibility-target:** for-orchestrator-synthesis

The test runs coref for a detached HEAD, a modified and a staged file, assume-unchanged, skip-worktree, the three core keys, GIT_INDEX_FILE, GIT_WORK_TREE, GIT_CONFIG and a nested repo. It runs cook with the caller's config pairs (`GIT_CONFIG_COUNT=1 ... cook`, :1645). E4 mutants M4, M6, M11, M13, M15 and M16 each turn this test red.

**Evidence:** `test/scripts/build-loop-check.bats:1620-1648`, `/tmp/fcf-1429237-mgZd/mutants.out`

---

## Claim 34: Test "--check refuses a self-merge brief whose checked-out bytes are not main's blob though git status is clean: ident and eol attributes, a non-UTF-8 name under a UTF-8 locale (contract item 3, row 397, U2b2 i1 security 2)"

**Location:** `test/scripts/build-loop-check.bats:1650`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers ident, eol and the non-UTF-8 record; filter and working-tree-encoding are not exercised.
**Legibility-target:** for-orchestrator-synthesis

Each case asserts `[ -z "$(git status --porcelain)" ]` before `coref "$WHY"` (:1655, :1659, :1666). E4 M5 (no byte comparison) and M1 (no C locale) each turn it red, so the `\xff` name case depends on the locale fix as its name says.

**Evidence:** `test/scripts/build-loop-check.bats:1650-1668`, `/tmp/fcf-1429237-mgZd/mutants.out`

---

## Claim 35: Test "--check refuses a self-merge brief when main holds a file name hash-object reads as another: a leading quote, a trailing CR (U2b2 i1 security 1)"

**Location:** `test/scripts/build-loop-check.bats:1670`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the quote and CR names; the newline name is not exercised.
**Legibility-target:** for-orchestrator-synthesis

The test runs `echo q > '"q"'; commit_all quote; coref "$NAME"` and `echo r > $'r\r'; commit_all cr; coref "$NAME"` (:1673-1675). E4 M2 turns it red, and E2 P8 confirms hash-object reads each as another file.

**Evidence:** `test/scripts/build-loop-check.bats:1670-1676`, `/tmp/fcf-1429237-mgZd/mutants.out`

---

## Claim 36: Test "--check judges a review brief without its checkout, and a self-merge brief's checkout after its paths, so a loop's advisory run from its branch still lists them (U2b2 i1 api F1, architecture F2)"

**Location:** `test/scripts/build-loop-check.bats:1678`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** "after its paths" holds in the sense that the gate runs once the paths are read and its refusal still lists them (the refusal line prints before them); covers a deny line under the checkout refusal.
**Legibility-target:** for-orchestrator-synthesis

The review run passes in a dirty, detached checkout (:1680-1681). On feat/x the test asserts the checkout refusal as line 0 and 3 lines in all, including `deny $B A docs/roadmap.md: $NOWN` (:1687-1690). E4 M7 and M10 (deny count winning over the checkout refusal) each turn it red.

**Evidence:** `test/scripts/build-loop-check.bats:1678-1691`, `/tmp/fcf-1429237-mgZd/mutants.out`

---

## Claim 37: Test "--check refuses a self-merge brief when a gitlink's path holds files, is a symlink or cannot be listed (rows 366, 373, U2b2 i1 security 3)" and its comments "an empty directory there passes (git status reports an absent one)", "git status already fails on a symlink there (exit 128), before the gitlink rule reads it."

**Location:** `test/scripts/build-loop-check.bats:1693-1705`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers all three cases as refusals; the symlink case is refused by the git status rule, as the comment says, so the gitlink rule's `-L` test is not pinned (Claim 3).
**Legibility-target:** for-orchestrator-synthesis

E2 P7: an absent gitlink path showed ` D sub` and was refused. An empty directory gave `ok`. A symlink made `git status ... --ignore-submodules=none` exit 128 with `error: expected submodule path 'sub' not to be a symbolic link`, and `--check` refused with "git status failed or warned in the checkout". E4 M14 and M3a turn the test red, and M3b stays green.

**Evidence:** `test/scripts/build-loop-check.bats:1693-1705`, `scripts/build-loop.sh:672-677`, `/tmp/fcf-1320198-M9G8/probe1.out` (P7), `/tmp/fcf-1429237-mgZd/mutants.out`

---

## Claim 38: c10b972a: "checkout_gate runs once per --check when the policy is self-merge ... A review brief does not read the checkout ... this repo's 3,163 files ... Tests: three in build-loop-check.bats ... Mutants that drop the refusal, the byte comparison or the index-bit check each turn a test red. Suites 104/19/78/2/2"

**Location:** commit `c10b972a` message
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the structure at c10b972a (read), the file count, test counts (E7) and the mutant claims (rerun on HEAD's equivalents M5, M6, M16); the c10b972a suites were not rerun, and health-check was not run.
**Legibility-target:** for-orchestrator-synthesis

At c10b972a the check mode ran `if [[ "$POLICY" == self-merge ]]; then checkout_gate || true; fi` once (c10b972a `scripts/build-loop.sh:726`), and only `[[ "$pol" == self-merge && -n "$CHECKOUT_WHY" ]]` read it (:668). E5 confirms the gate's cost under c10b972a for a review brief too (`ty` ~0.43 s). `git ls-tree -r main` gives 3,163 regular files. E7: build-loop-check.bats had 104 tests at c10b972a (101 on main + 3), build-loop-read 19, dev-cycle 78, fixture-git-env 2, utility-smoke 2.

**Evidence:** `git show c10b972a:scripts/build-loop.sh` (:603-668, :726), `/tmp/fcf-1429237-mgZd/timing.out`, `/tmp/fcf-1429237-mgZd/mutants.out`

---

## Claim 39: c10b972a: "It costs 0.14 s over this repo's 3,163 files."

**Location:** commit `c10b972a` message
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers c10b972a's script on this host; the original measurement's conditions are unknown.
**Legibility-target:** for-author

E5 ran c10b972a's own `scripts/` on a clone of main. A self-merge policy run took 0.41-0.46 s for either brief, and HEAD's review-brief runs, which skip the gate, took 0.12-0.13 s. That puts the gate near 0.30 s, about twice the stated 0.14 s. The bare `hash-object --stdin-paths` over every file took 0.15 s, so the 0.14 s may have timed only the hashing. The order of magnitude (well under a second) holds. The commit is immutable, and HEAD's comment (Claim 29) gives a figure close to this measurement.

**Evidence:** `/tmp/fcf-1429237-mgZd/timing.out`

---

## Claim 40: 639f7b40 subject "judge the checkout per self-merge brief after the N rules" and bullet "checkout_gate runs inside check_line for each self-merge brief, after the merge and the N rules"

**Location:** commit `639f7b40` message
**Type:** Architectural
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the call order at 639f7b40 and at HEAD; already recorded as Accepted-immutable (override row 527), reported here for completeness.
**Legibility-target:** for-author

`checkout_gate` runs before the per-path `nrules` loop (Claim 1; same order at 639f7b40 per the i2 fact-check, Claim 22). The commit cannot be edited, and the code comment, help and plan now state the order correctly (368a3194).

**Evidence:** `scripts/build-loop.sh:739-753`, `docs/reviews/override-log.md:527`

---

## Claim 41: 639f7b40: "no red, nine ambers, all fixed here ... Tests: five U2b2 tests (from three). New cases: GIT_WORK_TREE, GIT_CONFIG, the caller's config pairs passing, skip-worktree hiding a real change, a non-UTF-8 name under C.utf8, quote and CR names, an advisory run from feat/x listing a deny line, a gitlink unlistable or a symlink. Every cook/coref now asserts an empty stderr. Suites 106/19/78/2/2; shellcheck clean"

**Location:** commit `639f7b40` message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers rubric statuses A1-A9, the test file and suite counts (E7, and E1's 207 passing at HEAD, the same counts); "scripts/health-check.sh passed" was not rerun.
**Legibility-target:** for-orchestrator-synthesis

The rubric's iteration 1 lists A1-A9, each "Fixed in 639f7b40", under "🔴 Must Fix: None" (`docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b2.md:13-27`). Each listed case is in the tests (Claims 33-37). `cook` and `coref` both assert `[ -z "$stderr" ]` (`build-loop-check.bats:1609-1613`). E7: 106/19/78/2/2 at 639f7b40 (build-loop-check, build-loop-read, dev-cycle, fixture-git-env, utility-smoke). E6: shellcheck at the health-check severity exits 0.

**Evidence:** `docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b2.md:11-27`, `test/scripts/build-loop-check.bats:1604-1705`, `/tmp/fcf-944033-AxOn/logs/suites.txt`

---

## Claim 42: 639f7b40: "Each fix's mutant turns a test red."

**Location:** commit `639f7b40` message
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the mutants of 639f7b40's fixes as they stand at HEAD; the later override row (527/529) and 368a3194's Notes already record the two exceptions, so this is for the record only.
**Legibility-target:** for-author

Two of 639f7b40's fix parts have mutants that stay green (E4). One is A3's "or is a symlink" (`[[ -L "$p" ]] ||`, M3b): git status fails first. The other is A1's "any other unmatched record refuses" (`[[ "$r" =~ $re ]] || { ... }`, M8): such a record is unreachable under the C locale. A1's locale part (M1) and A3's listing part (M3a) do go red. Precise version: "each fix's mutant turns a test red, except the gitlink -L check and the unmatched-record refusal (defense in depth)".

**Evidence:** `scripts/build-loop.sh:666`, `scripts/build-loop.sh:673`, `/tmp/fcf-1429237-mgZd/mutants.out`, `docs/reviews/override-log.md:529`

---

## Claim 43: 639f7b40 Notes: "a symlink at a gitlink path is refused by the git status rule (git warns) before the gitlink rule reads it"

**Location:** commit `639f7b40` message
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5; the refusal itself is correct, and only the stated mechanism ("warns") is wrong.
**Legibility-target:** for-author

E2 P7: `git status --porcelain=v1 -z --untracked-files=no --ignore-submodules=none` exits 128 with `error: expected submodule path 'sub' not to be a symbolic link`, so git fails rather than warns. 368a3194 corrected the matching test comment (`build-loop-check.bats:1703`, "git status already fails on a symlink there (exit 128)"). The commit message cannot be edited.

**Evidence:** `test/scripts/build-loop-check.bats:1703`, `/tmp/fcf-1320198-M9G8/probe1.out` (P7)

---

## Claim 44: 368a3194: "found three Incorrect claims with one cause ... The symlink-at-gitlink test comment: git status fails (exit 128), it does not warn ... three mutants stay green, as the fact-check recorded: the gitlink -L test (git status fails first), the unparseable-record refusal (unreachable under the C locale), and the stderr-only half of the git status rule"

**Location:** commit `368a3194` message
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the i2 report's Incorrect count and topics, the exit status and the three green mutants.
**Legibility-target:** for-orchestrator-synthesis

The i2 report's summary reads "16 verified, 7 mostly accurate, 0 stale, 3 incorrect". Its three Incorrect claims (7, 17, 22) are all the "after the N rules" placement (`code-fact-check-report-build-loop-u2b2-i2.md:160-164, 341-345, 424-428`). The exit status is from E2 P7, and the mutants are from E4 (Claim 3).

**Evidence:** `docs/reviews/code-fact-check-report-build-loop-u2b2-i2.md:10`, `/tmp/fcf-1320198-M9G8/probe1.out`, `/tmp/fcf-1429237-mgZd/mutants.out`

---

## Claim 45: 368a3194: "`local -x LC_ALL=C`, so tr, awk and git inherit the C locale (before, only bash's own matching used it, claim 23)"

**Location:** commit `368a3194` message
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the "before" half: whether 639f7b40's `local LC_ALL=C` reached children; the "now" half is Verified (Claim 19).
**Legibility-target:** for-author

E2 P11 had two cases. When the caller had already exported LC_ALL, a plain `local LC_ALL=C.utf8` did reach a child ("child-nox LC_ALL=C.utf8"), because a local shadowing an exported variable stays exported. Only when LC_ALL was not exported did the child not see it ("child-nox-unexported LC_ALL=unset"). So before the fix, the children also ran under C whenever the caller exported LC_ALL, as the bats fixtures do (`export ... LC_ALL=C`, `test/lib/build-loop-fixtures.bash`). Precise version: "before, children inherited it only when the caller had exported LC_ALL".

**Evidence:** `git show 639f7b40:scripts/build-loop.sh` (:627 `local LC_ALL=C`), `/tmp/fcf-1320198-M9G8/probe1.out` (P11)

---

## Claim 46: 1f4f7a21: "Iteration 2 (k=1, full panel over c10b972a..368a3194) found no red and no security finding ... Fixed here: B2 ..., C1 ..., C2 ..., C4 ... Override rows: 639f7b40's message (Accepted-immutable), the per-brief cost (Accepted), three green defense-in-depth mutants (Accepted), and the verdict chain and callervar shape (Defer, trigger U2c). ... the U2b2 tests (5/5) and shellcheck pass."

**Location:** commit `1f4f7a21` message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the rubric's iteration-2 statuses, the four override rows, the text changes B2/C1/C2/C4 in the tree, the U2b2 tests (E4 baseline 5/5; E1) and shellcheck at the gate's severity (E6). An info-level shellcheck run reports SC2015 at `scripts/build-loop.sh:654`, which the health-check's `-S warning` ignores.
**Legibility-target:** for-orchestrator-synthesis

The rubric's iteration 2 has "🔴 Must Fix: None" and says "security (no new finding; every iteration-1 fix holds ...)" (`code-review-rubric-...-u2b2.md:51-55`). B2 is in check_line's comment (`scripts/build-loop.sh:733-734`) and the U2c bullet. C1 is in the lib header (`scripts/lib/dev-cycle-read.sh:57`). C2 is in the help (`scripts/build-loop.sh:115-118`, "a regular file main stores whose name ..."). C4 is in `scripts/build-loop.sh:736-738`. The four override rows are at `docs/reviews/override-log.md:527-530`, with the dispositions stated.

**Evidence:** `docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b2.md:49-76`, `docs/reviews/override-log.md:527-530`, `scripts/build-loop.sh:113-145`, `scripts/build-loop.sh:732-738`, `/tmp/fcf-1429237-mgZd/mutants.out`

---

## Claims Requiring Attention

### Incorrect
- **Claim 10** (`scripts/build-loop.sh:124-125`): "or one of them unreadable" cannot happen as a refusal. git rejects an unparseable core.symlinks/ignoreCase/sparseCheckout at startup, so `--check` exits 1 with "Not inside a git repository" before any brief is read. Drop the clause, or describe the exit-1 outcome. It fails closed. This is new in this pass.
- **Claim 40** (commit 639f7b40 subject/bullet): says the checkout is judged "after the N rules"; it runs before them. Already Accepted-immutable (override row 527).
- **Claim 42** (commit 639f7b40): "Each fix's mutant turns a test red", but the gitlink `-L` and unmatched-record mutants stay green. Already recorded (override row 529; 368a3194 Notes). Immutable.
- **Claim 43** (commit 639f7b40 Notes): "git warns" on a symlink at a gitlink path; git fails (exit 128). The test comment was fixed in 368a3194, and the commit is immutable.

### Stale
- None.

### Mostly Accurate
- **Claim 24** (`scripts/build-loop.sh:659-660`): under pipefail, a reader that finds nothing can mask the listing's status. One that stops early causes a spurious failure, not a hidden one.
- **Claim 30** (`scripts/build-loop.sh:738`): "at most the slot count" is not enforced. `--check` takes any number of briefs, and D9 frees a slot at `ready`. Say "the self-merge briefs passed to one --check".
- **Claim 39** (commit c10b972a): "0.14 s" reproduced as ~0.30 s for the whole gate here (0.15 s is the hashing alone). Immutable.
- **Claim 45** (commit 368a3194): "before, only bash's own matching used it" holds only when the caller had not exported LC_ALL. Immutable.

### Unverifiable
- **Claim 28** (`scripts/build-loop.sh:732-734`): "the floor walk runs only when co is empty" is U2c's future obligation, since no floor call exists yet. Recheck when U2c adds the call to the per-path loop.

## Goal-Alignment Note

The PR's goal is that `--check` refuses a self-merge brief unless it runs from a clean checkout of main's commit (contract items 2-4), with item 3 checked by its effect, so U2c's floor walk can trust the checkout. The executed evidence supports this goal. All 207 tests in the five named suites pass at 1f4f7a21. Every refusal the help lists exists, and 13 of 16 mutants turn a U2b2 test red; the three green ones are the accepted defense-in-depth checks. The byte comparison catches an ident expansion from the user's global attributes file that git status cannot see. A review brief is unaffected. One help clause (Claim 10) promises a refusal line that cannot be produced, because git fails earlier and the run exits 1. The outcome is still fail-closed, so this does not weaken the gate, but the exit-code contract a caller reads is different from what the help says. The other non-Verified items are wording or measurements in immutable commit messages, or a U2c obligation that only U2c's code can confirm (Claim 28). Nothing found blocks landing U2b2.
