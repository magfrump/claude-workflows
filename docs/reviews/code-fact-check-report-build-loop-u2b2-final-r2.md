Commit: 1f4f7a21

# Code Fact-Check Report

**Replication:** k=3, replicate r2 (final confirming pass)
**Repository:** /workspace (worktree /workspace/.claude/wt-build-loop-u2b2, branch feat/build-loop-u2b2)
**Scope:** full branch `main...1f4f7a21` (base 45ca46c3): scripts/build-loop.sh (help text :80-170, `callervar`, `gate_repo`, `checkout_gate`, `check_line`), scripts/lib/dev-cycle-read.sh :1-90 (contract item 3 note), docs/working/known-issues-dev-cycle.md (A5), docs/working/plan-build-loop-handoff.md (U2b2 and U2c bullets), the four 2026-10-08 `feat/build-loop-u2b2` rows of docs/reviews/override-log.md, the five U2b2 tests in test/scripts/build-loop-check.bats, and the messages of c10b972a, 639f7b40, 368a3194, 1f4f7a21 (d67966fe holds only reports)
**Checked:** 2026-10-08 (executions 2026-10-09T01:36Z-01:41Z UTC)
**Total claims checked:** 43
**Summary:** 33 verified, 9 mostly accurate, 0 stale, 1 incorrect, 0 unverifiable

Reading done: scripts/build-loop.sh whole (781 lines), including `checkout_gate` (:627-692) and `check_line` (:699-758) signature to final line, and the `check` mode driver (:769-780); scripts/lib/dev-cycle-read.sh :1-95, `import_reset` (:608) and `checkout_md` (:880); the full-branch diff; the test helpers `sm`/`coref`/`cook` (:1605-1617) and all five U2b2 tests (:1620-1705); c10b972a's `checkout_gate` and its call site. Hallucination pattern log read: its nearest pattern class is "a per-suite test count in a commit message" (the 37c5ea9 and 59ca38f entries). Claims 35a and 36d check it, and the counts match. The one Incorrect verdict below is a call-order error, not a fabricated symbol, so the log is not extended.

Execution environment: git 2.39.5, bash 5.2.15, shellcheck 0.9.0; the locales installed are C, C.utf8, POSIX. The session's `LC_ALL=en_US.UTF-8` is not installed, so unset-locale tools fall back to C. Captured output is under `/tmp/claude-1000/-workspace/67a6f690-c029-41ac-9bf2-d19f7c0e4343/scratchpad/fcr2/`, written `$FCR2/` below. Each probe script creates and enters its own `/tmp/fcf-<pid>-XXXX` dir and removes exactly that dir. Mutants ran on `git archive` copies inside those dirs. Nothing was written to /workspace or the worktree except this file. Host load average was about 3.0 during the timings (other replicates were running).

---

## Claim 1: override row 527: "639f7b40's subject and A4-A6 bullet say the checkout is judged "after the merge and the N rules"; checkout_gate runs before the N rules and the per-path loop ... the code comment, help and plan were corrected in 368a3194"

**Location:** `docs/reviews/override-log.md:527`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the quoted wording of 639f7b40's message, the call order at 639f7b40 and at HEAD, and the three corrections in 368a3194; does not establish whether "Accepted-immutable" is the right disposition (author's call).
**Legibility-target:** for-orchestrator-synthesis

639f7b40's subject reads "judge the checkout per self-merge brief after the N rules", and its body reads "checkout_gate runs inside check_line for each self-merge brief, after the merge and the N rules" (quoted from `git log main..HEAD`). In 639f7b40 the call is at :731 and the per-path loop at :743 (`git show 639f7b40:scripts/build-loop.sh`, grep output `731:  co=""; if [[ "$pol" == self-merge ]] && ! checkout_gate; ...` and `743:  for i in "${!ps[@]}"; do`). HEAD has the same order:
```bash
# scripts/build-loop.sh:739
  co=""; if [[ "$pol" == self-merge ]] && ! checkout_gate; then co="refuse $a: a self-merge brief needs --check run from a clean checkout of the default branch's commit; $CHECKOUT_WHY"; fi
# scripts/build-loop.sh:751-753 (excerpt; enclosing check_line continues to :758 — read)
  for i in "${!ps[@]}"; do
    p="${ps[$i]}"; shown="?"; [[ ! "$p" =~ ^[$NAMECHARS]+$ ]] || shown="$p"
    nrules "$a" "${oms[$i]}" "${nms[$i]}" "${nos[$i]}" "${ss[$i]}" "$p" "${lps[$i]}"
```
The comment, help and plan now say "before the N rules" (Claims 6, 12 and 17).

**Evidence:** `docs/reviews/override-log.md:527`, `scripts/build-loop.sh:739-757`; commit messages 639f7b40, 368a3194

---

## Claim 2: override row 528: "Per-brief checkout_gate multiplies its cost by the self-merge briefs in one --check (0.24 s each here; ~24 s for nine on a 50k-file repo with a 200 MB binary) ... the cost is recorded in check_line's comment"

**Location:** `docs/reviews/override-log.md:528`
**Type:** Performance / Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the per-brief call and whether the row cites its source faithfully, plus a re-measurement on this repo; does not reproduce the 50k-file synthetic repo (its ~24 s is the performance report's projection: 9 × ~2.7 s).
**Legibility-target:** for-orchestrator-synthesis

The call is per brief: `out="$(check_line "$a")"` runs inside `for a in "${ARGS[@]}"` (`scripts/build-loop.sh:775-776`), and `check_line` calls `checkout_gate` at :739. The figures match the performance i2 report: "0.24 s per gate ... on this repo's 3,170 files" (`docs/reviews/performance-reviewer-review-2026-10-08-build-loop-u2b2-i2.md:40`) and "~2.7 s per gate) nine briefs would cost about 24 s" (:43). My re-measurement in a `--shared` clone of main (3,163 regular files) gave 0.43-0.48 s for a self-merge brief against 0.12-0.135 s for the same brief under review. That puts the gate at about 0.31-0.36 s under load average 3.0, the same order as the cited 0.24 s. check_line's comment records the cost (Claim 30).

**Evidence:** `scripts/build-loop.sh:737-739`, `scripts/build-loop.sh:775-776`; command `timeout 300 bash $FCR2/timing.sh` and `timeout 300 bash $FCR2/timing2.sh`, cwd a `/tmp/fcf-*` dir each creates, exit 0, 2026-10-09T01:38:35Z and 01:38:58Z; output `$FCR2/timing.log`, `$FCR2/timing2.log`

---

## Claim 3: override row 529: "Three green mutants: the gitlink -L test, the unparseable ls-tree record refusal (unreachable under LC_ALL=C), the stderr-only half of the git status rule"

**Location:** `docs/reviews/override-log.md:529`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers these three mutants at 1f4f7a21 against the five U2b2 tests; does not establish that no fourth green mutant exists (two more found, Claim 34's scope).
**Legibility-target:** for-orchestrator-synthesis

Each mutant was applied by a perl substitution to an archive copy of 1f4f7a21 and run with `bats -f U2b2`:
```
m0-none: bats exit 0 (5 ok, 0 not ok)
m3-nosymlinktest: bats exit 0 (5 ok, 0 not ok)
m6-skiprecord: bats exit 0 (5 ok, 0 not ok)
m7-nostatusstderr: bats exit 0 (5 ok, 0 not ok)
```
m3 changes `if [[ -L "$p" ]] || {` to `if {` (:673); m6 makes `[[ "$r" =~ $re ]] || continue` (:666); m7 drops `&& [[ ! -s "$GATE_TMP/err" ]]` (:654). "Unreachable under LC_ALL=C": ls-tree's record is `mode type oid<TAB>path`, and under C a regex `.` matches any byte (P2), so git's own output always matches the regex at :632 (paraphrased — no quote available because the claim is about the absence of a reachable input, inferred from ls-tree's fixed format plus probe P2). The symlink case is refused earlier by git status, which exits 128 (P9: `status rc=128 stderr: error: expected submodule path 'sub' not to be a symbolic link`).

**Evidence:** `scripts/build-loop.sh:654`, `scripts/build-loop.sh:666`, `scripts/build-loop.sh:673`; command `timeout 3000 bash $FCR2/mut.sh`, cwd a `/tmp/fcf-*` dir it creates, exit 0, 2026-10-09T01:37:37Z-01:38:23Z; output `$FCR2/mut-summary.log`, `$FCR2/mut-m3-nosymlinktest.log`, `$FCR2/mut-m6-skiprecord.log`, `$FCR2/mut-m7-nostatusstderr.log`, `$FCR2/probes.log`

---

## Claim 4: override row 530: "Verdict precedence in check_line spread over two early returns and an if-chain; callervar serves gate_repo and checkout_gate with one answer; checkout_gate lives in build-loop.sh apart from the lib contract (architecture i1 F7, i2 3, 4)"

**Location:** `docs/reviews/override-log.md:530`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the cited finding numbers and the three structural facts; does not judge the Defer disposition.
**Legibility-target:** for-orchestrator-synthesis

The cited findings exist: architecture i1 "#### F7. `checkout_gate` lives in the caller while the contract it enforces lives in the lib" (:192), and i2 "#### 3. The verdict line's precedence is now spread across four early returns and a final if-chain" (:115) and "#### 4. `callervar` merges two questions" (:141). The code matches. The two early returns after `co` is set are :740 and :745-748, and the if-chain is :756. `callervar` is called from both `gate_repo` (:537) and `checkout_gate` (:636).

**Evidence:** `scripts/build-loop.sh:533-537`, `scripts/build-loop.sh:636`, `scripts/build-loop.sh:739-756`; `docs/reviews/architecture-review-review-2026-10-08-build-loop-u2b2.md:192`, `docs/reviews/architecture-review-review-2026-10-08-build-loop-u2b2-i2.md:115-141`

---

## Claim 5: A5: "U2b2 closes several of these for the gate (not for the walk itself) ... Still open there: start files under a symlinked directory, a FIFO start, other names one file has on a case-insensitive filesystem whose `core.ignoreCase` is false, and a checkout file swapped between the gate's check and the walk's read."

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each closed item against a `checkout_gate` refusal, and each "still open" item against the absence of one, compared with A5's own not-covered list; does not establish behaviour on a case-insensitive filesystem (not available here).
**Legibility-target:** for-orchestrator-synthesis

Every item A5 calls closed has a refusal. `core.symlinks` and `core.ignoreCase`/`core.sparseCheckout` are refused at :641-646. The nested repository is refused at :661-663 and the populated gitlink at :672-677. The byte comparison is :688-691:
```bash
# scripts/build-loop.sh:688-691
  x="$(printf '%s\n' "${ps[@]}" | git hash-object --no-filters --stdin-paths 2>/dev/null)" \
    || { CHECKOUT_WHY="the checkout's files could not be hashed"; return 1; }
  [[ "$x" == "$(printf '%s\n' "${ids[@]}")" ]] \
    || { CHECKOUT_WHY="a file's checked-out bytes are not the default branch's blob (a filter, working-tree-encoding, ident or eol conversion)"; return 1; }
```
Each "still open" item escapes the gate. A FIFO is not listed by `ls-files --others` (A5's own note), and untracked entries are otherwise allowed. Symlinked directories that are not gitlinks are not inspected, ignoreCase false is accepted, and nothing re-checks after the gate (paraphrased — no quote available because the claim covers the absence of code: no `checkout_gate` branch handles these). The remaining items of A5's older not-covered list (submodule or nested-repo starts, conversions, `core.symlinks=false`) are the closed ones.

**Evidence:** `scripts/build-loop.sh:641-691`, `docs/working/known-issues-dev-cycle.md:18`

---

## Claim 6: plan U2b2 bullet: "run per self-merge brief inside `check_line` once the merge's paths are read, before the N rules and U2c's per-path floor walk ... a self-merge brief is refused unless the checkout `--check` runs from has HEAD at MAIN_SHA, no repo-local GIT_* variable, core.symlinks true, ... A review brief does not read the checkout. `check_line` calls `import_reset` first."

**Location:** `docs/working/plan-build-loop-handoff.md:284`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the bullet's call placement, its list of conditions, and the iteration-1 additions against `checkout_gate` and `check_line`; does not establish the U2c behaviour it anticipates.
**Legibility-target:** for-author

Placement, every condition, the iteration-1 additions and `import_reset` all match the code (Claims 12, 14, 18, 19, 28). One imprecision: "no repo-local GIT_* variable". The code exempts the caller's config pairs, GIT_NO_REPLACE_OBJECTS and GIT_PREFIX:
```bash
# scripts/build-loop.sh:636-637
    [[ -z "${!v+set}" || "$v" == GIT_PREFIX ]] || callervar "$v" \
      || { CHECKOUT_WHY="$v is set, so git can read another work tree, index, object store or config file"; return 1; }
```
GIT_CONFIG_COUNT and GIT_NO_REPLACE_OBJECTS are in fact always set, by `harden` (:224) and the export line (:229). Read literally, the condition never holds. The bullet's later mention of GIT_CONFIG and `callervar` implies the exemption without stating it. Precise version: "no repo-local GIT_* variable but the caller's config pairs, GIT_NO_REPLACE_OBJECTS and GIT_PREFIX".

**Evidence:** `docs/working/plan-build-loop-handoff.md:284`, `scripts/build-loop.sh:224-229`, `scripts/build-loop.sh:533`, `scripts/build-loop.sh:634-638`

---

## Claim 7: plan U2c bullet: "floor runs in check_line's per-path loop only when U2b2's checkout refusal (`co`) is empty, never over a refused checkout; and U2c owns contract item 1, running the walk under LC_ALL=C (checkout_gate sets it only for itself)."

**Location:** `docs/working/plan-build-loop-handoff.md:286`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers agreement with check_line's comment and the scope of `checkout_gate`'s locale; does not establish U2c's code (the rule is a plan for U2c; no floor call exists in check_line today).
**Legibility-target:** for-orchestrator-synthesis

check_line's comment states the same rule: "U2c's floor walk, which runs per path below and only when co is empty (never over a checkout refused here)" (`scripts/build-loop.sh:733-734`). `grep -n floor scripts/build-loop.sh` finds only comments, no call. The locale is function-local: `local -x LC_ALL=C` (:631). Probe P1 shows it is unset again after the function returns (`after-return LC_ALL=[unset]`).

**Evidence:** `scripts/build-loop.sh:631`, `scripts/build-loop.sh:732-739`; `$FCR2/probes.log` (P1; command `timeout 120 bash $FCR2/probes.sh`, cwd a `/tmp/fcf-*` dir it creates, exit 0, 2026-10-09T01:36:51Z)

---

## Claim 8: help: every checkout refusal is listed ("the checkout --check runs from ... has its HEAD at another commit; a repo-local git variable set ...; or a listing or hash of these that fails")

**Location:** `scripts/build-loop.sh:112-135`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two-way match between the help's clauses and all 16 `CHECKOUT_WHY=` assignments in `checkout_gate` (:633-691); does not establish the exact reason texts (the help lists conditions).
**Legibility-target:** for-author

Every help clause has a matching refusal. Most refusals have a clause: the environment rule (:637), HEAD (:640), the three keys and their read failure (:645-646), the index bits and their listing (:651-652), git status failing/warning or non-empty (:655-656), the untracked listing and nested repository (:661-663), the tree listing (:664), the gitlink rules (:674-676), the name rule (:683), the hash failure and the mismatch (:689-691). Three refusals are folded into clauses that do not quite describe them:
- An unreadable HEAD: `x="$(git rev-parse --verify -q 'HEAD^{commit}')" || x="unreadable"` (:639), which the help covers only as "HEAD at another commit".
- An unparseable tree record, or an unexpected mode: `CHECKOUT_WHY="the default branch's tree could not be read"` (:666, :678). This is a parse failure, not "a listing or hash ... that fails" (unreachable in practice, Claim 3).
- "starts with a quote": the code refuses only a leading double quote, `"$p" != \"*` (:682). P5 confirms that hash-object unquotes only `"`.

**Evidence:** `scripts/build-loop.sh:112-140`, `scripts/build-loop.sh:633-691`

---

## Claim 9: help: "the text up to "; " is fixed"

**Location:** `scripts/build-loop.sh:115-116`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the refusal text after "refuse BRIEF: " up to the first "; "; does not cover a brief path holding "; " (the path precedes that text).
**Legibility-target:** for-orchestrator-synthesis

The prefix is a literal, followed by `; $CHECKOUT_WHY` (:739, Claim 1). No text before it contains "; ". `coref` pins it: `[ "${lines[0]}" = "refuse $B: $CO; $1" ]` (`test/scripts/build-loop-check.bats:1611`), with `CO="a self-merge brief needs --check run from a clean checkout of the default branch's commit"` (:1606). The full suites pass at HEAD (207/207).

**Evidence:** `scripts/build-loop.sh:739`, `test/scripts/build-loop-check.bats:1606-1612`; command `TMPDIR=$(mktemp -d /tmp/fcf-$$-XXXX) timeout 1500 bats test/scripts/build-loop-check.bats test/scripts/build-loop-read.bats test/scripts/dev-cycle.bats test/scripts/fixture-git-env.bats test/fixture-hermeticity.bats`, cwd the worktree, exit 0, 2026-10-09T01:36:20Z-01:37:52Z; output `$FCR2/suites-head.log`

---

## Claim 10: help: "a WHY naming a read failure is not one a clean checkout cures"

**Location:** `scripts/build-loop.sh:115-117`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the existence of read-failure reasons behind the fixed prefix; does not establish which of them a re-run might cure.
**Legibility-target:** for-orchestrator-synthesis

Several reasons that share the fixed prefix name read failures, not checkout state. Examples are `"the checkout's index could not be listed"` (:651), `"the default branch's tree could not be listed"` (:664) and `"the checkout's files could not be hashed"` (:689). So the help's caveat describes real outputs.

**Evidence:** `scripts/build-loop.sh:645`, `scripts/build-loop.sh:651`, `scripts/build-loop.sh:661-666`, `scripts/build-loop.sh:689`

---

## Claim 11: help: "path and deny lines follow it as they follow a K of N refusal"; "this one replaces only the verdict line, so a loop running --check from its own branch still gets the path lines"; "After an ok line, a K of N refusal or a checkout refusal, one line per path"

**Location:** `scripts/build-loop.sh:117-118`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the refusal's position and the rows that follow it when the merge changes paths; does not establish output when the blob or lower-casing refusal fires (they replace it, Claim 12).
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/build-loop.sh:756-757
  if [[ -n "$co" ]]; then echo "$co"; elif [[ "$nd" -eq 0 ]]; then echo "ok $a $sha $tree"; else echo "refuse $a: $nd of ${#ps[@]} changed paths refused in the merge of $sha (tree $tree)"; fi
  printf '%s\n' "${rows[@]}"
```
Test 4 runs --check from feat/x and asserts the HEAD refusal, then three lines, among them `deny $B A docs/roadmap.md: $NOWN` and `path $B A work-feat-x.txt` (`test/scripts/build-loop-check.bats:1684-1690`). It passes.

**Evidence:** `scripts/build-loop.sh:739-757`, `test/scripts/build-loop-check.bats:1678-1691`; `$FCR2/suites-head.log` (exit 0, 2026-10-09T01:37:52Z)

---

## Claim 12: help: "The merge's own refusals above (a conflict, a missing blob...) come first"

**Location:** `scripts/build-loop.sh:136-137`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers which line wins when a merge refusal and a checkout refusal both apply; does not establish when `checkout_gate` runs relative to the blob check (it runs before it, and its result is then discarded).
**Legibility-target:** for-orchestrator-synthesis

The conflict, merge-computation and path-listing refusals return before :739. The blob-presence and lower-casing refusals return after `co` is set, without printing it:
```bash
# scripts/build-loop.sh:745-750
  if [[ ${#ids[@]} -gt 0 ]] && { ! out="$(printf '%s\n' "${ids[@]}" | gate_git cat-file --batch-check='%(objecttype)')" \
    || [[ "$(printf '%s\n' "$out" | grep -cx blob)" -ne ${#ids[@]} ]]; }; then
    echo "refuse $a: the merge of $br names a blob the object store lacks"; return
  fi
  # One lower-casing pass for every path (a tr per path cost 1 to 2.5 ms each).
  if ! nul_list lps lower_all "${ps[@]}" || [[ ${#lps[@]} -ne ${#ps[@]} ]]; then echo "refuse $a: the paths the merge of $br changes could not be lower-cased"; return; fi
```
In either case the merge's refusal is the line printed. That is "come first" read as precedence, which is what the sentence asserts.

**Evidence:** `scripts/build-loop.sh:705-750`

---

## Claim 13: help: "A review brief does not read the checkout."

**Location:** `scripts/build-loop.sh:139-140`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `checkout_gate` being skipped when `pol` is review, whether by global policy or by the brief's own Policy line; does not cover the walk (U2c).
**Legibility-target:** for-orchestrator-synthesis

The guard is `[[ "$pol" == self-merge ]] && ! checkout_gate` (:739), and `pol` comes from status_line (:496, :704). In test 4, a review brief in a dirty, detached checkout gets `ok` (`test/scripts/build-loop-check.bats:1679-1681`). Timing agrees: in a clone of main the same brief took 0.12-0.135 s as review and 0.42-0.48 s as self-merge (timing2.log, HEAD rows).

**Evidence:** `scripts/build-loop.sh:496`, `scripts/build-loop.sh:704`, `scripts/build-loop.sh:739`, `test/scripts/build-loop-check.bats:1678-1682`; `$FCR2/timing2.log` (command `timeout 300 bash $FCR2/timing2.sh`, exit 0, 2026-10-09T01:38:58Z)

---

## Claim 14: help: "a repo-local git variable set (GIT_DIR, GIT_WORK_TREE, GIT_INDEX_FILE, GIT_CONFIG and the like; the caller's GIT_CONFIG_PARAMETERS and GIT_CONFIG_COUNT pairs, GIT_NO_REPLACE_OBJECTS and GIT_PREFIX aside)"

**Location:** `scripts/build-loop.sh:121-124`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5's `--local-env-vars` list and the refusal for GIT_DIR, GIT_WORK_TREE, GIT_INDEX_FILE and GIT_CONFIG; does not run the other twelve variables individually.
**Legibility-target:** for-orchestrator-synthesis

P3 lists all sixteen variables. GIT_CONFIG, GIT_PREFIX, GIT_NO_REPLACE_OBJECTS, GIT_CONFIG_COUNT, GIT_CONFIG_PARAMETERS, GIT_DIR, GIT_WORK_TREE and GIT_INDEX_FILE are `listed`, and `GIT_CONFIG_KEY_0: not listed`, so the key/value pairs need no exemption. In a clean clone of main, `GIT_DIR="$PWD/.git"` was refused: `refuse ...: a self-merge brief needs --check run from a clean checkout of the default branch's commit; GIT_DIR is set, so git can read another work tree, index` (timing.log, line cut at 200 bytes). Test 1 covers GIT_INDEX_FILE, GIT_WORK_TREE and GIT_CONFIG, and shows that caller pairs pass (`test/scripts/build-loop-check.bats:1641-1644`).

**Evidence:** `scripts/build-loop.sh:533`, `scripts/build-loop.sh:634-638`, `test/scripts/build-loop-check.bats:1640-1644`; `$FCR2/probes.log` (P3), `$FCR2/timing.log` (command `timeout 300 bash $FCR2/timing.sh`, exit 0, 2026-10-09T01:38:35Z)

---

## Claim 15: callervar: "the caller's config pairs, which harden extends and trusts (GIT_CONFIG_PARAMETERS, GIT_CONFIG_COUNT), and GIT_NO_REPLACE_OBJECTS, which this script sets. GIT_CONFIG is not one: git config then reads that one file instead of every scope (gate_repo unsets it; checkout_gate refuses it)."

**Location:** `scripts/build-loop.sh:528-532`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `git config`'s handling of GIT_CONFIG, the two call sites, and harden; does not establish that any other subcommand ignores GIT_CONFIG (only `git config` was probed this pass). "extends" holds for the COUNT pairs, the only ones harden appends to.
**Legibility-target:** for-orchestrator-synthesis

In P4 the repo config sets `core.ignoreCase true`. Plain `git config --type=bool --get core.ignoreCase` printed `true rc=0`; under `GIT_CONFIG=../cfg` (a file without the key) it gave `rc=1`. So that one file replaces every scope. harden appends to the COUNT pairs (`export GIT_CONFIG_COUNT="$c"`, :224), and the export line sets `GIT_NO_REPLACE_OBJECTS=1` (:229). gate_repo unsets every non-callervar variable, `callervar "$v" || GATE_ENV+=(-u "$v")` (:537). checkout_gate refuses a set GIT_CONFIG (Claim 14; test 1 :1643).

**Evidence:** `scripts/build-loop.sh:219-229`, `scripts/build-loop.sh:528-537`, `scripts/build-loop.sh:634-638`; `$FCR2/probes.log` (P3, P4)

---

## Claim 16: checkout_gate header: "Item 2's fsmonitor and replace refs are harden's and the state gate's, and its ls-files stderr rule is the walk's own."

**Location:** `scripts/build-loop.sh:612-614`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers who handles each element item 2 names; does not establish that every ls-files call in the walk checks stderr (only `checkout_md` was read).
**Legibility-target:** for-orchestrator-synthesis

harden sets `core.useReplaceRefs=false ... core.fsmonitor=false` (:221), and the export line sets `GIT_NO_REPLACE_OBJECTS=1` (:229). The state gate's key regex includes `core\.fsmonitor` (:243), and it refuses any `refs/replace/` ref (:259-260). The walk owns the stderr rule: `checkout_md() { local e; { e="$(md_ls --cached --others 2>&1 >&3)"; } 3>&1 && [[ -z "$e" ]]; }` (`scripts/lib/dev-cycle-read.sh:880`).

**Evidence:** `scripts/build-loop.sh:219-229`, `scripts/build-loop.sh:243-260`, `scripts/lib/dev-cycle-read.sh:47-51`, `scripts/lib/dev-cycle-read.sh:880`

---

## Claim 17: checkout_gate header: "check_line calls it for each self-merge brief once the merge and its changed paths are read, before the N rules and U2c's floor walk run per path, so it is final before that walk."

**Location:** `scripts/build-loop.sh:616-618`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the call's position in check_line today; does not establish U2c's placement of the walk (not built).
**Legibility-target:** for-orchestrator-synthesis

The changed paths are read at :720-731, the call is at :739, and `nrules` runs in the loop at :751-755 (Claim 1's excerpts). Nothing between :739 and the loop touches the checkout. The intervening code is the blob batch-check through `gate_git` and an in-memory lower-casing (:745-750, Claim 12). This corrects iteration 2's Claim 7 (Incorrect at 639f7b40).

**Evidence:** `scripts/build-loop.sh:720-757`

---

## Claim 18: checkout_gate header: "Item 3 is checked by its effect, not by predicting it with check-attr: every regular file main stores must hash, unfiltered, to main's blob, so no conversion (a filter, working-tree-encoding, ident or eol attribute from any attributes source, the user's global ones included, which harden hides from the gate's own git) changed what a session reads there."

**Location:** `scripts/build-loop.sh:618-623`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers regular files (100644/100755) main stores, hashed with `--no-filters`; does not cover symlinks (git status compares those, Claim 26) or untracked files (allowed by design).
**Legibility-target:** for-orchestrator-synthesis

No `check-attr` call exists in the function (paraphrased — no quote available because the claim covers the absence of code in :628-692). harden hides the global attributes with `core.attributesFile=/dev/null` (:221) and `GIT_CONFIG_GLOBAL=/dev/null` (:229). The comparison is the one quoted in Claim 5. Test 2 checks out an ident and an eol=crlf file with a clean `git status` and asserts the mismatch refusal (`test/scripts/build-loop-check.bats:1650-1668`). P10b confirms an eol=crlf file with a clean status hashes differently (`e.md blob 35821... hashed 414e6... status=[]`).

**Evidence:** `scripts/build-loop.sh:221-229`, `scripts/build-loop.sh:664-691`, `test/scripts/build-loop-check.bats:1650-1668`; `$FCR2/probes.log` (P10, P10b); `$FCR2/suites-head.log`

---

## Claim 19: checkout_gate header: "Untracked and ignored files are allowed: the walk reads them as they are. A nested repository's files are not walk starts (rows 366, 373), so an untracked one, or a gitlink checked out with any file, fails."

**Location:** `scripts/build-loop.sh:623-626`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers untracked and ignored plain files, `git init` nested repos and populated gitlinks; does not cover a nested repo whose `.git` is a file (not probed this pass).
**Legibility-target:** for-orchestrator-synthesis

git status runs with `--untracked-files=no` (:654), and the only untracked rule is the trailing-slash count (:662-663). Test 1 passes `cook` with an ignored `CLAUDE.local.md` and an untracked `untracked.md`, and refuses after `git init -q nested` (`test/scripts/build-loop-check.bats:1622-1624`, `:1645`). Test 5 refuses `sub/CLAUDE.md` under a gitlink (:1698-1699). Override rows 366 and 373 are about submodule and nested-repo files not being starts (read in `docs/reviews/override-log.md`).

**Evidence:** `scripts/build-loop.sh:654-677`, `test/scripts/build-loop-check.bats:1620-1648`, `test/scripts/build-loop-check.bats:1693-1705`, `docs/reviews/override-log.md:366`, `docs/reviews/override-log.md:373`

---

## Claim 20: "The C locale: under UTF-8 a regex . does not match an invalid byte, and a record skipped for its name would escape the byte comparison."

**Location:** `scripts/build-loop.sh:629-630`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bash 5.2's `=~` on a 0xFF byte and what the current code does with an unmatched record; does not establish other regex engines.
**Legibility-target:** for-author

The first half holds. P2 printed `C.utf8: no match` and `local -x C: match` for `[[ $'a\xffb' =~ ^a.b$ ]]`. The second half describes a skip the code no longer has. Since 639f7b40 an unmatched record refuses:
```bash
# scripts/build-loop.sh:666
    [[ "$r" =~ $re ]] || { CHECKOUT_WHY="the default branch's tree could not be read"; return 1; }
```
Mutant m1 (no `local -x LC_ALL=C`) shows what the locale prevents now: test 2's non-UTF-8 name is refused with `the default branch's tree could not be read` instead of the byte-mismatch reason. That is a false refusal, not an escape. Precise version: "under UTF-8 a regex . does not match an invalid byte, so a valid record with such a name would be refused as unreadable (and, were it skipped, would escape the byte comparison)".

**Evidence:** `scripts/build-loop.sh:629-632`, `scripts/build-loop.sh:666`; `$FCR2/probes.log` (P2), `$FCR2/mut-m1-noLCALL.log` (bats exit 1, 2026-10-09T01:37Z)

---

## Claim 21: `local -x LC_ALL=C  # exported: tr, awk and git run under it too`

**Location:** `scripts/build-loop.sh:631`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers export to children when the caller has no LC_ALL, and restoration on return; does not establish that any test pins the export (mutant m1b, `local` without `-x`, stays green: 5/5).
**Legibility-target:** for-orchestrator-synthesis

P1 ran under `env -u LC_ALL LANG=C.utf8` with `f() { local -x LC_ALL=C; bash -c ...; env | grep -c "^LC_ALL=C$"; }`. It printed `child LC_ALL=[C]`, `1`, and `after-return LC_ALL=[unset]`. This fixes iteration 2's Claim 23 (the earlier `local LC_ALL=C` reached children only if the caller had exported LC_ALL).

**Evidence:** `scripts/build-loop.sh:631`; `$FCR2/probes.log` (P1), `$FCR2/mut-m1b-notexported.log` (bats exit 0)

---

## Claim 22: "GIT_PREFIX only names a subdirectory for an alias; the script cds to the top level."

**Location:** `scripts/build-loop.sh:635`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the script's cd before any checkout_gate call; does not establish git's use of GIT_PREFIX beyond aliases.
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/build-loop.sh:283-284
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "Not inside a git repository" >&2; exit 1; }
cd "$ROOT"
```
This runs at top level, before the mode dispatch (:760) that reaches check_line.

**Evidence:** `scripts/build-loop.sh:283-284`, `scripts/build-loop.sh:634-638`

---

## Claim 23: "ls-files -v tags each entry: H is plain; S is skip-worktree, lower case is assume-unchanged (git status skips a change under either), M is unmerged."

**Location:** `scripts/build-loop.sh:648-649`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the tags under fsmonitor off (harden) and git status's blindness under both bits; does not cover the tags with an enabled fsmonitor.
**Legibility-target:** for-orchestrator-synthesis

P6 printed `H a`, `h b` (assume-unchanged), `S c` (skip-worktree), and during a conflicted merge `M a` three times. Test 1 asserts `[ -z "$(git status --porcelain --untracked-files=no)" ]` after a real change under each bit, then expects `$IDX` (`test/scripts/build-loop-check.bats:1630-1635`). It passes.

**Evidence:** `scripts/build-loop.sh:648-652`, `test/scripts/build-loop-check.bats:1629-1636`; `$FCR2/probes.log` (P6), `$FCR2/suites-head.log`

---

## Claim 24: "To a file: bash would warn on stderr about the NULs a $(...) drops."

**Location:** `scripts/build-loop.sh:653`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bash 5.2.15's command-substitution warning; does not cover older bash.
**Legibility-target:** for-orchestrator-synthesis

P8 printed `bash: line 1: warning: command substitution: ignored null byte in input` for `x="$(printf "a\0b")"`. Every `cook`/`coref` asserts an empty stderr (`[ -z "$stderr" ]`, `test/scripts/build-loop-check.bats:1612`, `:1614`).

**Evidence:** `scripts/build-loop.sh:653-656`; `$FCR2/probes.log` (P8)

---

## Claim 25: "Without --exclude-standard every untracked file is listed, ignored ones too, and a nested repository as its directory with a trailing / (no file name holds a /)."

**Location:** `scripts/build-loop.sh:657-659`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `ls-files -z --others` with an info/exclude pattern, an untracked file, a `git init` nested repo and an empty directory; does not cover `.gitignore` files at depth (the same mechanism).
**Legibility-target:** for-orchestrator-synthesis

P7 printed `nested/`, `u.txt`, `x.ign` (the ignored file). With `--exclude-standard` it printed only `nested/` and `u.txt`. The empty directory was not listed.

**Evidence:** `scripts/build-loop.sh:657-663`; `$FCR2/probes.log` (P7)

---

## Claim 26: "git status compares a link's text to its blob unconverted (core.symlinks is true here)."

**Location:** `scripts/build-loop.sh:670`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a symlink under an `ident` attribute and a retargeted link with core.symlinks at its Linux default; does not cover a filesystem without symlinks (refused at :641 when core.symlinks is false).
**Legibility-target:** for-orchestrator-synthesis

P12 committed `l -> x$Id$` with `l ident` in `.gitattributes`. After checkout the link text was `x$Id$` (not expanded) and status was clean (`link text after checkout: x$Id$ status=[]`). Retargeting it gave `retargeted status=[ M l]`. core.symlinks being true is enforced before the loop (:641-646).

**Evidence:** `scripts/build-loop.sh:641-646`, `scripts/build-loop.sh:668-671`; command `timeout 60 bash $FCR2/probe2.sh`, cwd a `/tmp/fcf-*` dir it creates, exit 0, 2026-10-09T01:40Z; output `$FCR2/probe2.log`

---

## Claim 27: "hash-object --stdin-paths reads a line: a newline splits a name, a leading " is unquoted and a trailing CR dropped, so another file is hashed."

**Location:** `scripts/build-loop.sh:680-681`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5's `--stdin-paths` handling of `"q"` and `r<CR>`; the newline case follows from line-reading and was not run separately.
**Legibility-target:** for-orchestrator-synthesis

P5: the file `"q"` hashes to `d50e63...` directly, but `--stdin-paths` given `"q"` printed `d169a2...`, the hash of `q`. The file `r<CR>` hashes to `f7d55c...`, but `--stdin-paths` printed `9a6c8d...`, the hash of `r`. Mutant m10 (rule dropped) turns test 3 red.

**Evidence:** `scripts/build-loop.sh:680-684`, `test/scripts/build-loop-check.bats:1670-1676`; `$FCR2/probes.log` (P5), `$FCR2/mut-m10-noquoteCR.log` (bats exit 1)

---

## Claim 28: `import_reset  # caller contract item 4: no walk cache outlives a decision`

**Location:** `scripts/build-loop.sh:701`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the call's position (first statement of each brief's decision) and what it clears; does not establish any observable effect today (no walk runs in check_line; mutant m11 without the call stays green, 5/5).
**Legibility-target:** for-orchestrator-synthesis

`import_reset() { IMPORTED_DONE=""; IMPORTED_MAIN_DONE=""; }` (`scripts/lib/dev-cycle-read.sh:608`). Contract item 4 reads "Call import_reset before each gate decision and after any checkout change" (`scripts/lib/dev-cycle-read.sh:63`). The call is check_line's first statement, and check_line runs once per brief.

**Evidence:** `scripts/build-loop.sh:699-701`, `scripts/lib/dev-cycle-read.sh:63-65`, `scripts/lib/dev-cycle-read.sh:608`; `$FCR2/mut-m11-noimportreset.log` (bats exit 0)

---

## Claim 29: check_line: "before U2c's floor walk, which runs per path below and only when co is empty (never over a checkout refused here); its refusal replaces the verdict line only, so the N rules' path and deny lines still print"

**Location:** `scripts/build-loop.sh:732-736`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the present code (the refusal replaces only the verdict line) and agreement with the U2c plan bullet; does not establish U2c's code, which will have to honour "only when co is empty".
**Legibility-target:** for-orchestrator-synthesis

The present-tense half is Claim 11. The U2c half is a plan stated identically in `docs/working/plan-build-loop-handoff.md:286` (Claim 7). Today `co` is consulted only at :740 and :756.

**Evidence:** `scripts/build-loop.sh:732-757`, `docs/working/plan-build-loop-handoff.md:286`

---

## Claim 30: "Run per brief, so each decision sees the checkout as it is: about 0.25 s here, times the self-merge briefs in one --check"

**Location:** `scripts/build-loop.sh:736-738`
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers per-brief invocation and one host's cost on this repo's 3,163 regular files; does not separate load effects.
**Legibility-target:** for-author

Per brief: Claim 2. Re-measured, the self-merge minus review difference was 0.31-0.36 s (self-merge 0.42-0.48 s, review 0.12-0.135 s, five runs each, in two scripts, load average 3.0). The performance i2 reviewer measured 0.24 s. Same order; "about 0.25 s" is the low end. Precise version: "about 0.25-0.35 s here".

**Evidence:** `scripts/build-loop.sh:737-739`; `$FCR2/timing.log`, `$FCR2/timing2.log`

---

## Claim 31: "(at most the slot count)"

**Location:** `scripts/build-loop.sh:738`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers what bounds the number of self-merge briefs in one --check run; does not establish the orchestrator's actual call pattern (U3 not built).
**Legibility-target:** for-author

Nothing in the script bounds it. `--check` accepts any number of brief paths, repeats included:
```bash
# scripts/build-loop.sh:192-200 (excerpt; enclosing case arm continues to :201 — read)
    while [[ $# -gt 0 ]]; do
      if [[ "$1" == --expect ]]; then
        ...
      else ARGS+=("$1"); shift; fi
    done
    [[ ${#ARGS[@]} -gt 0 ]] || usage "--check needs at least one brief path"
```
(the `--expect` branch, :193-197, is elided). The slot count is read for `--settings` only (:428-431). The plan's D9 says "Only a live dispatched loop holds a slot. A `blocked`, `ready`-awaiting-review or `stopped` item holds none" (`docs/working/plan-build-loop-handoff.md:90`). So the ready briefs gated in one cycle are bounded by the slots only in the usual flow, not by rule. The performance i2 report says "at most the slot count in practice" (:82). Precise version: "(in practice at most the slot count)".

**Evidence:** `scripts/build-loop.sh:190-201`, `scripts/build-loop.sh:428-431`, `scripts/build-loop.sh:775-778`, `docs/working/plan-build-loop-handoff.md:90`

---

## Claim 32: lib item 3 note: "The walk checks neither item but item 2's ls-files stderr rule. build-loop.sh --check does, for each self-merge brief before the walk (U2b2; item 1's LC_ALL=C for the walk is its U2c floor caller's): harden and its state gate own item 2's fsmonitor and replace refs; checkout_gate the rest of item 2 (a clean checkout at MAIN_SHA, the GIT_* variables, core.ignoreCase, sparse checkout), core.symlinks, and the attributes by their effect, not by check-attr"

**Location:** `scripts/lib/dev-cycle-read.sh:55-60`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the ownership split against harden, state_gate, checkout_gate and `checkout_md`; does not establish U2c's ownership of item 1 beyond the plan (Claim 7).
**Legibility-target:** for-orchestrator-synthesis

The split matches Claims 16-18, and `checkout_gate`'s locale is function-local (Claim 21). The four parts of "the rest of item 2" map to :639-640 (HEAD), :634-638 (GIT_*), :641-646 (ignoreCase, sparseCheckout, plus core.symlinks) and :650-656 (index bits and status). "GIT_* variables" carries the same exemptions as Claim 6, here in a summary context that names no exception.

**Evidence:** `scripts/lib/dev-cycle-read.sh:43-62`, `scripts/build-loop.sh:219-260`, `scripts/build-loop.sh:631-656`

---

## Claim 33: lib item 3 note: "every regular file main stores hashes, unfiltered, to main's blob (so an eol conversion fails it too, and an attribute that changes no bytes does not)."

**Location:** `scripts/lib/dev-cycle-read.sh:60-62`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers eol=crlf on an LF file, and ident and eol=crlf on files they leave unchanged; does not cover filter drivers (refused by the state gate before this runs).
**Legibility-target:** for-orchestrator-synthesis

P10: `n.md` (ident, no `$Id$`) and `m.md` (eol=crlf, no newline) each hashed to their blob (`n.md blob 30d617... hashed 30d617...`, `m.md blob c79f22... hashed c79f22...`). P10b: an LF file under eol=crlf hashed differently with a clean status. Test 2 refuses the eol case (`test/scripts/build-loop-check.bats:1658-1661`).

**Evidence:** `scripts/build-loop.sh:688-691`, `test/scripts/build-loop-check.bats:1650-1668`; `$FCR2/probes.log` (P10, P10b)

---

## Claim 34: the five U2b2 test names (HEAD, env, config, index bits, status, nested repos; ident/eol and a non-UTF-8 name; a leading quote and trailing CR; a review brief and the advisory run; a gitlink holding files, a symlink or unlistable)

**Location:** `test/scripts/build-loop-check.bats:1620-1705`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each named case being exercised and asserted, and which mutants each catches; does not establish that each named case is pinned to its own rule. Test 5's symlink case is refused by git status (m3 green), and nothing pins the export of `LC_ALL` (m1b green) or the `import_reset` call (m11 green).
**Legibility-target:** for-orchestrator-synthesis

Every case each name lists is exercised. Test 1 covers HEAD (:1626), status (:1627-1628), both index bits (:1630-1635), the three config keys (:1637-1639), the env variables and caller pairs (:1641-1644) and the nested repo (:1645). Test 2 covers ident and eol under a clean status, and `\xff` under `LC_ALL=C.utf8` (:1652-1667); C.utf8 is installed here (`locale -a`), so that case is real, and m1 turns it red. Test 3 covers `"q"` and `r\r` (:1673-1675; m10 red). Test 4 covers a review brief in a dirty detached checkout, then the advisory run from feat/x with a deny line (:1679-1690). Test 5 covers a populated gitlink, `chmod 111` and a symlink (:1697-1704); the test comment says git status refuses the symlink first ("git status already fails on a symlink there (exit 128)", :1703), which P9 confirms. Test 1's name says "contract item 2" but also covers core.symlinks (item 3); this is cosmetic. Results: m0 5/5 ok; red: m1 (test 2), m10 (test 3); green: m1b, m3, m6, m7, m11.

**Evidence:** `test/scripts/build-loop-check.bats:1605-1705`; `$FCR2/mut-summary.log` (command `timeout 3000 bash $FCR2/mut.sh`, exit 0, 2026-10-09T01:37:37Z-01:38:23Z), `$FCR2/suites-head.log`, `$FCR2/probes.log` (P9)

---

## Claim 35a: commit c10b972a: "checkout_gate runs once per --check when the policy is self-merge"; "A review brief does not read the checkout"; "Tests: three in build-loop-check.bats"; "Mutants that drop the refusal, the byte comparison or the index-bit check each turn a test red. Suites 104/19/78/2/2"

**Location:** commit c10b972a message
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers c10b972a's code, its test counts, and three mutants of it; does not rerun the full suites or scripts/health-check.sh at c10b972a (iteration 1's fact-check did).
**Legibility-target:** for-orchestrator-synthesis

At c10b972a: `if [[ "$POLICY" == self-merge ]]; then checkout_gate || true; fi` in the check driver, run once before the brief loop, and check_line refuses only `if [[ "$pol" == self-merge && -n "$CHECKOUT_WHY" ]]` (`git show c10b972a:scripts/build-loop.sh`, :726, :668). `grep -c '^@test'` gives 101 on main and 104 at c10b972a, and 19/78/2/2 for the other four suites. Mutants on a c10b972a archive copy were all red: refusal guard `if false` (`0 ok, 3 not ok`), byte comparison `return 0` (test 2 red), index bits `true ||` (test 1 red).

**Evidence:** `git show c10b972a:scripts/build-loop.sh` :618-670, :726; command `timeout 900 bash $FCR2/mut-c10.sh`, cwd a `/tmp/fcf-*` dir it creates, exit 0, 2026-10-09T01:40:56Z-01:41:03Z; output `$FCR2/mutc10-summary.log`, `$FCR2/mutc10-c0-refusal.log`, `$FCR2/mutc10-c1-bytes.log`, `$FCR2/mutc10-c2-indexbits.log`

---

## Claim 35b: commit c10b972a: "It costs 0.14 s over this repo's 3,163 files."

**Location:** commit c10b972a message
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the file count and c10b972a's full gate cost on this host under load; does not reproduce the author's method.
**Legibility-target:** for-author

The count is exact: the merge base 45ca46c3 and main both hold 3,163 regular files (`git ls-tree -r ... | awk '$1=="100644"||$1=="100755"' | wc -l`). Under c10b972a the gate runs for any brief when the policy is self-merge. Its cost was c10b972a's review-brief time (0.43-0.45 s) minus HEAD's (0.12-0.125 s), about 0.31 s, at load average 3.0. Iteration 1 measured 0.26 s for the hash part alone. Same order; 0.14 s not reproduced.

**Evidence:** `$FCR2/timing2.log` (command `timeout 300 bash $FCR2/timing2.sh`, exit 0, 2026-10-09T01:38:58Z)

---

## Claim 36a: commit 639f7b40: subject "judge the checkout per self-merge brief after the N rules" and "checkout_gate runs inside check_line for each self-merge brief, after the merge and the N rules, and before the point U2c's floor walk runs"

**Location:** commit 639f7b40 message
**Type:** Architectural
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the call order at 639f7b40; does not establish any behavioural consequence (the checkout refusal still wins over the K-of-N line).
**Legibility-target:** for-author

At 639f7b40 the call is at :731 and the loop that runs `nrules` at :743 (Claim 1). The checkout is judged before the N rules. The message is immutable, and override row 527 records it as Accepted-immutable. Code, help and plan now say "before" (Claims 12, 17, 6).

**Evidence:** `git show 639f7b40:scripts/build-loop.sh` :731, :743; `docs/reviews/override-log.md:527`

---

## Claim 36b: commit 639f7b40: "Each fix's mutant turns a test red."

**Location:** commit 639f7b40 message
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers mutants at 1f4f7a21 of the iteration-1 fixes, whose code is unchanged since 639f7b40 apart from `local -x`; does not rerun them at 639f7b40.
**Legibility-target:** for-author

Some fixes have red mutants: A1's locale (m1), A2's name rule (m10), and A7's GIT_CONFIG (iteration 2's m5). Three sub-rules of the fixes stay green: A3's `-L` (m3), A1's refusal of an unmatched record (m6), and the status rule's stderr half (m7) (Claim 3). The message's own Notes disclose only m3. Precise version: "each fix has a mutant that turns a test red; three defensive sub-rules do not".

**Evidence:** `$FCR2/mut-summary.log`; `scripts/build-loop.sh:654`, `scripts/build-loop.sh:666`, `scripts/build-loop.sh:673`

---

## Claim 36c: commit 639f7b40 Notes: "a symlink at a gitlink path is refused by the git status rule (git warns) before the gitlink rule reads it"

**Location:** commit 639f7b40 message, Notes
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5's status on a symlink at a gitlink path; the refusal and its order are right, and only how git signals it is wrong.
**Legibility-target:** for-author

P9: `status rc=128 stderr: error: expected submodule path 'sub' not to be a symbolic link`. git fails; it does not just warn. The rule refuses either way, with the reason "git status failed or warned in the checkout" (:655). The test comment was corrected in 368a3194 (`test/scripts/build-loop-check.bats:1703`).

**Evidence:** `scripts/build-loop.sh:654-655`, `test/scripts/build-loop-check.bats:1703-1704`; `$FCR2/probes.log` (P9)

---

## Claim 36d: commit 639f7b40: "five U2b2 tests (from three)"; "Suites 106/19/78/2/2; shellcheck clean"; "Every cook/coref now asserts an empty stderr"

**Location:** commit 639f7b40 message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the counts at 639f7b40 (unchanged at HEAD), the helpers' stderr assertions, and shellcheck at HEAD at the health check's severity; does not rerun shellcheck at 639f7b40.
**Legibility-target:** for-orchestrator-synthesis

`grep -c '^@test'` at 639f7b40 gives 106/19/78/2/2 (build-loop-check, build-loop-read, dev-cycle, fixture-git-env, fixture-hermeticity), which is 104 + 2 new tests. One HEAD run printed `1..207`, 207 `ok`, no `not ok`, exit 0. `shellcheck -x -e SC1091 -s bash -S warning scripts/build-loop.sh` exits 0. At default severity it exits 1 on one info note, SC2015 at :654. Both helpers end with `[ -z "$stderr" ]` (`test/scripts/build-loop-check.bats:1612`, `:1614`). The counts match; the hallucination log's per-suite-count pattern does not recur.

**Evidence:** `test/scripts/build-loop-check.bats:1609-1614`; `$FCR2/suites-head.log` (command in Claim 9, exit 0, 2026-10-09T01:36:20Z-01:37:52Z)

---

## Claim 37: commit 368a3194: "found three Incorrect claims with one cause ... `local -x LC_ALL=C`, so tr, awk and git inherit the C locale (before, only bash's own matching used it, claim 23). callervar's GIT_CONFIG wording ... (claim 4). The symlink-at-gitlink test comment: git status fails (exit 128), it does not warn (claim 21). A5's still-open list gains other names on a case-insensitive filesystem whose core.ignoreCase is false (claim 16). ... three mutants stay green"

**Location:** commit 368a3194 message
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each claim number against the iteration-2 report, and each fix against HEAD; does not re-verify the iteration-2 report's own verdicts.
**Legibility-target:** for-orchestrator-synthesis

The iteration-2 report lists Incorrect claims 7, 17 and 22, all about the "after the N rules" order (`docs/reviews/code-fact-check-report-build-loop-u2b2-i2.md`, "Claims Requiring Attention"). Claims 4, 16, 21 and 23 there are the ones named. The fixes are present: the export (Claim 21 here), the callervar wording (Claim 15), the test comment (:1703), and A5's list (Claim 5). The three green mutants were reproduced (Claim 3).

**Evidence:** `docs/reviews/code-fact-check-report-build-loop-u2b2-i2.md:520-544`, `scripts/build-loop.sh:528-532`, `scripts/build-loop.sh:631`, `test/scripts/build-loop-check.bats:1703`; `$FCR2/probes.log` (P1), `$FCR2/mut-summary.log`

---

## Claim 38a: commit 1f4f7a21: "Iteration 2 (k=1, full panel over c10b972a..368a3194)"

**Location:** commit 1f4f7a21 message
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the commit and scope headers of the iteration-2 reports.
**Legibility-target:** for-author

The four critics' i2 reports carry `Commit: 368a3194` and scope `c10b972a..368a3194`. The iteration-2 fact-check carries `Commit: 639f7b40` and scope `c10b972a..639f7b40`. 368a3194 was its fix, so the panel's fact-check stage did not cover 368a3194. Precise version: "fact-check over c10b972a..639f7b40, critics over c10b972a..368a3194".

**Evidence:** `docs/reviews/code-fact-check-report-build-loop-u2b2-i2.md:1-7`, `docs/reviews/security-reviewer-review-2026-10-08-build-loop-u2b2-i2.md:1-3`, `docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b2.md` (Iteration 2 heading)

---

## Claim 38b: commit 1f4f7a21: "found no red and no security finding"; B2, C1, C2, C4 fixes; the four override rows; "the U2b2 tests (5/5) and shellcheck pass"

**Location:** commit 1f4f7a21 message
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the rubric's iteration-2 tables, the security i2 summary, presence of each named fix at HEAD, and the test and shellcheck runs; "shellcheck pass" holds at the health check's warning severity, not at default severity (SC2015 info).
**Legibility-target:** for-orchestrator-synthesis

The rubric's iteration 2 reads `### 🔴 Must Fix` / `None.`, and the security i2 report's Findings section reads "No findings." The fixes are present: B2 (Claim 29, plan :286), C1 (`scripts/lib/dev-cycle-read.sh:57`), C2 (help :115-118 and "a regular file main stores whose name", :130), C4 (Claim 30). The four override rows are :527-530. m0 gave `5 ok, 0 not ok`; for shellcheck see Claim 36d.

**Evidence:** `docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b2.md` (Iteration 2), `docs/reviews/security-reviewer-review-2026-10-08-build-loop-u2b2-i2.md:32-34`, `scripts/build-loop.sh:115-130`, `scripts/lib/dev-cycle-read.sh:55-62`; `$FCR2/mut-summary.log` (m0)

---

## Claims Requiring Attention

### Incorrect
- **Claim 36a** (commit 639f7b40): the checkout is judged before the N rules, not after. The message is immutable and already logged as Accepted-immutable (override row 527); code, help and plan are correct.

### Stale
None.

### Mostly Accurate
- **Claim 6** (`docs/working/plan-build-loop-handoff.md:284`): "no repo-local GIT_* variable" omits the exemptions (caller config pairs, GIT_NO_REPLACE_OBJECTS, GIT_PREFIX), which harden always sets.
- **Claim 8** (`scripts/build-loop.sh:112-135`): the help folds an unreadable HEAD into "another commit" and an unparseable tree record into "a listing ... that fails"; "a quote" means a double quote only.
- **Claim 20** (`scripts/build-loop.sh:629-630`): the code no longer skips an unmatched record. Without the C locale such a record is refused as unreadable (m1), not let through.
- **Claim 30** (`scripts/build-loop.sh:737`): about 0.31-0.36 s here under load (0.24 s per the performance review), so "about 0.25-0.35 s".
- **Claim 31** (`scripts/build-loop.sh:738`): nothing enforces "at most the slot count" (--check takes any number of briefs, and D9 frees a ready loop's slot), so "in practice".
- **Claim 35b** (commit c10b972a): 0.14 s not reproduced (about 0.31 s here under load; same order).
- **Claim 36b** (commit 639f7b40): mutants of three defensive sub-rules stay green (m3, m6, m7). Each fix has some red mutant.
- **Claim 36c** (commit 639f7b40 Notes): git status fails (exit 128) on a symlinked gitlink path; it does not just warn.
- **Claim 38a** (commit 1f4f7a21): the iteration-2 fact-check covered c10b972a..639f7b40; only the critics covered ..368a3194.

### Unverifiable
None.

---

## Goal-Alignment Note

**Success criterion (restated verbatim):** A markdown report saved to the path named at the end of this prompt, structured per the code-fact-check skill, with `Commit: 1f4f7a21` as its first line.

**Answered:** all eight focus areas. (1) Help text: Claims 8-14. Every listed refusal exists, and every refusal is listed, though three are folded loosely (Claim 8). The fixed prefix, the read-failure caveat, the path/deny lines, merge-refusal precedence and the review-brief exemption all hold. (2) The checkout_gate header and inline comments: Claims 16-27. All hold except the C-locale rationale's "skipped" record (Claim 20). (3) callervar and GIT_PREFIX: Claims 15, 22. (4) check_line: Claims 28-31. import_reset and "only when co is empty" hold; the timing and the slot bound are approximate. (5) Lib item 3: Claims 32-33. (6) Docs: Claims 1-7. A5 and the U2c bullet are verified, the U2b2 bullet is mostly accurate, and all four override rows are verified. (7) Commits: Claims 35a-38b. The counts, mutants and fixes hold; the one Incorrect is the already-logged 639f7b40 order. (8) Tests: Claim 34. Each test exercises what its name says, and m1 and m10 are caught. Test 5's symlink case rests on git status, and the `local -x` export and `import_reset` call are unpinned (m1b, m11 green).

**Out of scope:** whether the green mutants deserve tests (security/test-strategy call); U2c's eventual code; a case-insensitive filesystem run; scripts/health-check.sh as a whole.

**Escalate:** none blocking. Nothing here is red. All nine Mostly accurate verdicts are wording; the one Incorrect is an immutable commit message already in the override log.

**Questions / Decisions:** none.
