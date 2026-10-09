Commit: 1f4f7a21

# Code Fact-Check Report

**Replication:** replicate r1 of k=3 (final confirming pass)
**Repository:** /workspace (worktree /workspace/.claude/wt-build-loop-u2b2, branch feat/build-loop-u2b2)
**Scope:** full branch `main...1f4f7a21`: scripts/build-loop.sh (help text, `callervar`, `gate_repo`, `checkout_gate`, `check_line`), scripts/lib/dev-cycle-read.sh (gate caller contract, lines 1-90), docs/working/known-issues-dev-cycle.md (A5), docs/working/plan-build-loop-handoff.md (U2b2 and U2c bullets), docs/reviews/override-log.md (the four 2026-10-08 `feat/build-loop-u2b2` rows), test/scripts/build-loop-check.bats (the five U2b2 tests), commit messages c10b972a, 639f7b40, 368a3194, 1f4f7a21
**Checked:** 2026-10-08 (executions 2026-10-09T01:36Z-01:41Z UTC)
**Total claims checked:** 43
**Summary:** 35 verified, 5 mostly accurate, 0 stale, 1 incorrect, 2 unverifiable

Reading done: scripts/build-loop.sh whole (1-781); scripts/lib/dev-cycle-read.sh 1-90, `import_reset` (:608) and `checkout_md` (:876-880); test/lib/build-loop-fixtures.bash 1-80; the five U2b2 tests and their helpers (build-loop-check.bats :1251-1252, :1444-1445, :1604-1705); the full diff; the four commit messages; the override rows; the iteration-1/2 rubric and the iteration-2 fact-check (for consistency, not as claim sources). Hallucination pattern log read (`docs/reviews/hallucination-patterns.md`): the nearest pattern is "per-suite counts in a commit message" (59ca38f, 37c5ea9 entries); Claims 34 and 39 check those counts and they match. No Incorrect verdict below is a fabricated symbol, so the log is not extended.

Execution logs (all outside the repo): `L=/tmp/claude-1000/-workspace/67a6f690-c029-41ac-9bf2-d19f7c0e4343/scratchpad/fcf-final-r1-1061983/`. Probe copy of HEAD's `scripts/` and `test/` (plus `docs/dev-cycle.md`): `/tmp/fcf-1061983-oHCM` (from `git archive 1f4f7a21`). Mutant copies and logs: `/tmp/fcf-1190629-iRp3/`. Every probe ran under `timeout`; all had exited before this report (ps checked).

---

## Claim 1: override row "639f7b40's subject and A4-A6 bullet say the checkout is judged 'after the merge and the N rules'; checkout_gate runs before the N rules and the per-path loop ... the code comment, help and plan were corrected in 368a3194"

**Location:** `docs/reviews/override-log.md:527`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the quoted subject/bullet text, the call position in check_line and the files 368a3194 changed; does not establish whether Accepted-immutable is the right disposition.
**Legibility-target:** for-orchestrator-synthesis

639f7b40's subject reads `judge the checkout per self-merge brief after the N rules` and its A4-A6 bullet `after the merge and the N rules` (`git show -s 639f7b40`). The call is at `scripts/build-loop.sh:739` (`co=""; if [[ "$pol" == self-merge ]] && ! checkout_gate; then ...`), before the N-rules loop at `:751-755`. `git show 368a3194 --stat` lists `scripts/build-loop.sh`, `docs/working/plan-build-loop-handoff.md` and the bats file, and its diff removes `-# failure. check_line calls it for each self-merge brief, after the N rules and` and the plan's `after the merge and the N rules`.

**Evidence:** `scripts/build-loop.sh:739`, `scripts/build-loop.sh:751-755`, commits 639f7b40, 368a3194

---

## Claim 2: override row "Per-brief checkout_gate multiplies its cost by the self-merge briefs in one --check (0.24 s each here; ~24 s for nine on a 50k-file repo with a 200 MB binary)"

**Location:** `docs/reviews/override-log.md:528`
**Type:** Performance
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the per-brief multiplication (executed) and the order of the per-run cost on this repo; does not establish the ~24 s figure for a 50k-file, 200 MB repo, which was not rebuilt.

The multiplication is real: with four self-merge briefs in one `--check`, all four printed the checkout refusal (probe P3, `$L/probe2.out`), so checkout_gate ran once per brief. A per-run cost on a clone of main (3,163 files) measured 0.29-0.79 s while another session's full bats run held the load average at about 3 (`$L/timing.out`, `$L/timing2.out`), consistent with 0.24 s on an idle machine but not a measurement of it. The 50k-file figure needs that fixture repo rebuilt (paraphrased — no quote available because the figure comes from the iteration-2 performance report, not from code).

Commands: `timeout 300 bash $L/probe2.sh` and `timeout 300 bash $L/timing.sh`, cwd: their own `mktemp -d /tmp/fcf-$$-XXXX` dirs; exit 0; 2026-10-09T01:37:38Z, 01:38:37Z, 01:38:55Z.

**Evidence:** `scripts/build-loop.sh:775-778`, `$L/probe2.out`, `$L/timing.out`, `$L/timing2.out`

---

## Claim 3: override row "Three green mutants: the gitlink -L test, the unparseable ls-tree record refusal (unreachable under LC_ALL=C), the stderr-only half of the git status rule"

**Location:** `docs/reviews/override-log.md:529`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the five U2b2 tests against each of the three mutants; does not establish that the three branches are unreachable in every environment (only that no U2b2 test reaches them).

Mutants applied with perl to copies of HEAD's `scripts/build-loop.sh`, each followed by `bats -f 'U2b2' test/scripts/build-loop-check.bats`:
- M1, `if [[ -L "$p" ]] || ` removed from `:673`: 5/5 ok.
- M2, `:666`'s refusal replaced by `|| continue`: 5/5 ok.
- M3, `&& [[ ! -s "$GATE_TMP/err" ]]` removed from `:654`: 5/5 ok.
The control (M0, no change) is 5/5 ok, and the other mutants in the same run turn tests red (Claim 33), so the harness discriminates.

Command: `timeout 1800 bash $L/mutants.sh`, cwd `/tmp/fcf-1190629-iRp3`; exit 0; 2026-10-09T01:36Z-01:38Z.

**Evidence:** `scripts/build-loop.sh:654`, `scripts/build-loop.sh:666`, `scripts/build-loop.sh:673`, `$L/mutants.out`, `/tmp/fcf-1190629-iRp3/M1-gitlink-L.log`, `/tmp/fcf-1190629-iRp3/M2-record-continue.log`, `/tmp/fcf-1190629-iRp3/M3-status-stderr.log`

---

## Claim 4: override row "Verdict precedence in check_line spread over two early returns and an if-chain; callervar serves gate_repo and checkout_gate with one answer; checkout_gate lives in build-loop.sh apart from the lib contract"

**Location:** `docs/reviews/override-log.md:530`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the existence of the structures named; "two early returns" is read as the two returns after `co` is set (`:740`, `:747`; `:750` is a third); does not judge the deferral.

`if [[ ${#ps[@]} -eq 0 ]]; then echo "${co:-ok $a $sha $tree}"; return; fi` (`:740`) and the missing-blob `return` (`:747`) precede the chain `if [[ -n "$co" ]]; then echo "$co"; elif [[ "$nd" -eq 0 ]] ...` (`:756`). `callervar` is called by `gate_repo` (`:537`) and `checkout_gate` (`:636`). `checkout_gate` is defined at `scripts/build-loop.sh:628`, not in the lib.

**Evidence:** `scripts/build-loop.sh:533-537`, `scripts/build-loop.sh:628-692`, `scripts/build-loop.sh:739-757`

---

## Claim 5: A5 "U2b2 closes several of these for the gate (not for the walk itself): ... Still open there: start files under a symlinked directory, a FIFO start, other names one file has on a case-insensitive filesystem whose core.ignoreCase is false, and a checkout file swapped between the gate's check and the walk's read."

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers each closed item against checkout_gate and each open item against the absence of a check for it; does not establish a case-insensitive-filesystem run or a timing race.

Closed items map to code: HEAD `[[ "$x" == "$MAIN_SHA" ]]` (`:640`); `core.symlinks false`, `core.ignoreCase true`, `core.sparseCheckout true` (`:641-642`); nested repository `awk '/\/$/ ...'` (`:662-663`); gitlink with files (`:676`); byte comparison (`:688-691`). Open items: a mode-120000 entry is skipped (`120000) continue ;;`, `:671`), so nothing under a symlinked directory is checked; untracked files are allowed and `git ls-files --others` does not list a FIFO (paraphrased — no quote available because the claim covers absence of a FIFO check: no `-p` test exists in checkout_gate); no check compares names case-insensitively; nothing pins the checkout between `checkout_gate` and a later read.

**Evidence:** `scripts/build-loop.sh:640-691`, `docs/working/known-issues-dev-cycle.md:18`

---

## Claim 6: plan U2b2 bullet "checkout_gate, run per self-merge brief inside check_line once the merge's paths are read, before the N rules and U2c's per-path floor walk ... refused unless ... HEAD at MAIN_SHA, no repo-local GIT_* variable, core.symlinks true, core.ignoreCase and core.sparseCheckout false, only plain index entries, a clean git status, no untracked nested repository or populated gitlink ... Iteration 1 added: ... A review brief does not read the checkout. check_line calls import_reset first."

**Location:** `docs/working/plan-build-loop-handoff.md:284`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed condition against code and the U2b2 tests; "core.ignoreCase and core.sparseCheckout false" is read as "not true" (unset passes, `:646`); does not establish a global-scope core.ignoreCase (git config runs with GIT_CONFIG_GLOBAL=/dev/null, `:229`, so only repo, worktree and command-line scopes are read).

Each item is in code: `local -x LC_ALL=C` (`:631`), the env loop (`:634-638`), HEAD (`:639-640`), config (`:641-647`), `substr($0, 1, 2) != "H "` (`:650`), git status (`:654-656`), nested repo (`:661-663`), gitlink (`:672-677`), names (`:682-683`), hash (`:688-691`); `import_reset` is the first statement of `check_line` (`:701`); the gate is guarded by `[[ "$pol" == self-merge ]]` (`:739`). The five U2b2 tests pass at HEAD (Claim 33) and a review brief over a dirty checkout passes (probe P8 in `$L/probe2.out`: `ok docs/working/briefs/2026-10-01-rv.md ...`).

Command: `timeout 300 bash $L/probe2.sh`, cwd its own mktemp dir; exit 0; 2026-10-09T01:38:37Z.

**Evidence:** `scripts/build-loop.sh:629-692`, `scripts/build-loop.sh:701`, `scripts/build-loop.sh:739`, `$L/probe2.out`

---

## Claim 7: plan U2c bullet "floor runs in check_line's per-path loop only when U2b2's checkout refusal (co) is empty, never over a refused checkout; and U2c owns contract item 1, running the walk under LC_ALL=C (checkout_gate sets it only for itself)"

**Location:** `docs/working/plan-build-loop-handoff.md:286`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with check_line's comment and checkout_gate's `local`; the floor rule is a U2c commitment and cannot be checked against code that does not exist yet.

`local -x LC_ALL=C` (`:631`) is function-local, so it ends with checkout_gate. check_line's comment says the same walk rule: `before U2c's floor walk, which runs per path below and only when co is empty (never over a checkout refused here)` (`:733-734`). No `floor` call exists in build-loop.sh today (grep: zero hits for `floor ` outside comments).

**Evidence:** `scripts/build-loop.sh:631`, `scripts/build-loop.sh:732-739`, `scripts/lib/dev-cycle-read.sh:57`

---

## Claim 8: help "for a brief --status reads as self-merge, 'a self-merge brief needs --check run from a clean checkout of the default branch's commit; WHY' (the text up to '; ' is fixed ..."

**Location:** `scripts/build-loop.sh:112-116`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the refusal's prefix and its self-merge-only trigger; does not establish anything about WHY texts (Claim 11a).

`co="refuse $a: a self-merge brief needs --check run from a clean checkout of the default branch's commit; $CHECKOUT_WHY"` (`:739`) is the only producer, behind `[[ "$pol" == self-merge ]]`; `pol` is `--status`'s POLICY field (`read -r _ _ st pol br loop sha _`, `:704`). The prefix holds no other `; `. Every U2b2 coref compares `"refuse $B: $CO; $1"` and passes (Claim 33).

**Evidence:** `scripts/build-loop.sh:704`, `scripts/build-loop.sh:739`, `test/scripts/build-loop-check.bats:1624-1628`, `$L/build-loop-check.bats.log`

---

## Claim 9: help "but a WHY naming a read failure is not one a clean checkout cures"

**Location:** `scripts/build-loop.sh:116-117`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the existence of read-failure WHYs under the fixed prefix (e.g. `the default branch's tree could not be listed`, `:664`; `the checkout's files could not be hashed`, `:689`); "is not one a clean checkout cures" is read as "not necessarily cured by"; an unreadable index (`:651`) might be cured by a fresh checkout, which the sentence does not exclude.

`CHECKOUT_WHY="${v%% *} could not be read"` (`:645`), `"the checkout's index could not be listed"` (`:651`), `"the default branch's tree could not be listed"` (`:664`), `"the default branch's tree could not be read"` (`:666`, `:678`), `"the checkout's files could not be hashed"` (`:689`) all print under the same prefix.

**Evidence:** `scripts/build-loop.sh:645-689`

---

## Claim 10: help "path and deny lines follow it as they follow a K of N refusal" and ":143 After an ok line, a K of N refusal or a checkout refusal, one line per path TREE changes"

**Location:** `scripts/build-loop.sh:117-118`, `scripts/build-loop.sh:143`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the order (verdict line, then rows) for a checkout refusal with one or more changed paths and the zero-path case; does not establish U2c's future rows.

`if [[ -n "$co" ]]; then echo "$co"; elif ... fi` then `printf '%s\n' "${rows[@]}"` (`:756-757`). With zero changed paths, `echo "${co:-ok $a $sha $tree}"; return` (`:740`) prints no rows, as a K of N refusal cannot occur there either. Executed: test 4 (`refuse ... HEAD is ...`, then `deny $B A docs/roadmap.md: $NOWN` and `path $B A work-feat-x.txt`) passes; probe P7 (branch's change already on main, dirty checkout) printed only the refusal line (`$L/probe2.out`).

**Evidence:** `scripts/build-loop.sh:740`, `scripts/build-loop.sh:756-757`, `test/scripts/build-loop-check.bats:1683-1690`, `$L/probe2.out`

---

## Claim 11a: help's list of checkout refusals (HEAD at another commit; a repo-local variable; core.symlinks/ignoreCase/sparseCheckout or unreadable; skip-worktree, assume-unchanged or unmerged; a git status change, failure or warning; an untracked nested repository; a gitlink path that is a symlink, cannot be listed or holds files; a regular file name with a newline, leading quote or trailing CR; bytes not main's blob; a listing or hash that fails) matches checkout_gate's refusals in both directions

**Location:** `scripts/build-loop.sh:119-135`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the one-to-one mapping of the 18 `CHECKOUT_WHY=` assignments to listed conditions; the unreadable-HEAD case (`x="unreadable"`, `:639`) is folded into "HEAD at another commit" and the unknown-mode record (`:678`) into "a listing ... that fails"; which WHY a condition actually prints is Claim 11b.

`grep -c 'CHECKOUT_WHY=' scripts/build-loop.sh` covers `:637` (env), `:640` (HEAD), `:645-646` (config), `:651-652` (index), `:655-656` (status), `:661`, `:663` (others), `:664`, `:666`, `:674`, `:676`, `:678` (tree, gitlink), `:683` (names), `:689`, `:691` (hash). Each has a listed counterpart and each listed condition has an assignment.

**Evidence:** `scripts/build-loop.sh:119-135`, `scripts/build-loop.sh:633-691`

---

## Claim 11b: help "a regular file main stores whose name holds a newline ... (the byte comparison cannot read it)" and "a gitlink's path that is a symlink" as checkout refusals

**Location:** `scripts/build-loop.sh:129-132`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which WHY prints for these two conditions in a clean checkout; does not establish any case where the newline branch of `:682-683` or the `-L` branch of `:673` is reached.

Both conditions are refused, but under an earlier rule's WHY. A newline name splits in `git ls-files -v -z | tr '\0' '\n' | awk 'substr($0, 1, 2) != "H " { n++ } ...'` (`:650`), so the second half of the name counts as a flagged entry: probe P5 (`n\nl.md` committed on main, checkout clean) printed `the checkout's index marks entries skip-worktree, assume-unchanged or unmerged` (`$L/probe2.out`), not the name WHY. A symlink at a gitlink path fails git status first (`error: expected submodule path 'sub' not to be a symbolic link`, rc=128, `$L/probe3.out`), so it prints `git status failed or warned in the checkout`, as test 5's comment already says. Precise version: the newline case is refused, under the index-bits reason (a reader seeing that WHY would look for update-index flags that are not there); the symlink case under the git status reason.

Commands: `timeout 300 bash $L/probe2.sh`, `timeout 60 bash $L/probe3.sh`, cwd their own mktemp dirs; exit 0; 2026-10-09T01:38:37Z, 01:39:17Z.

**Evidence:** `scripts/build-loop.sh:650-652`, `scripts/build-loop.sh:673`, `scripts/build-loop.sh:682-683`, `$L/probe2.out`, `$L/probe3.out`

---

## Claim 12: help "the caller's GIT_CONFIG_PARAMETERS and GIT_CONFIG_COUNT pairs, GIT_NO_REPLACE_OBJECTS and GIT_PREFIX aside"

**Location:** `scripts/build-loop.sh:122-124`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four exempt names among `git rev-parse --local-env-vars` on git 2.39.5; does not establish the list on other git versions.

`[[ -z "${!v+set}" || "$v" == GIT_PREFIX ]] || callervar "$v" || { CHECKOUT_WHY=...` (`:636-637`); `callervar` accepts exactly `GIT_CONFIG_PARAMETERS`, `GIT_CONFIG_COUNT`, `GIT_NO_REPLACE_OBJECTS` (`:533`). `git rev-parse --local-env-vars` lists 16 names, GIT_CONFIG_KEY_n/VALUE_n not among them, so harden's pairs never trip it. Executed: `GIT_PREFIX=sub/` with a clean checkout printed `ok ...` (probe P2, `$L/probe2.out`); test 1's `GIT_CONFIG_COUNT=1 ... cook` passes.

**Evidence:** `scripts/build-loop.sh:533`, `scripts/build-loop.sh:634-638`, `test/scripts/build-loop-check.bats:1658`, `$L/probe2.out`

---

## Claim 13: help "The merge's own refusals above (a conflict, a missing blob...) come first; this one replaces only the verdict line, so a loop running --check from its own branch still gets the path lines"

**Location:** `scripts/build-loop.sh:136-139`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers precedence over the conflict, missing-blob and lower-casing refusals (all `return` before `:756`), and over earlier status/branch refusals; "come first" describes which line prints, not call order (checkout_gate runs before the missing-blob check at `:745`).

Conflict returns at `:715`; missing blob at `:747` and lower-casing at `:750` return before `:756` prints `$co`. Executed: a conflicting self-merge brief over a dirty checkout printed `refuse ...: feat/c conflicts with the default branch` only (probe P1, `$L/probe2.out`). Test 4 pins the path lines after the refusal on feat/x.

**Evidence:** `scripts/build-loop.sh:712-757`, `$L/probe2.out`, `test/scripts/build-loop-check.bats:1683-1690`

---

## Claim 14: help "A review brief does not read the checkout."

**Location:** `scripts/build-loop.sh:139-140`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers checkout_gate's call guard; does not establish that nothing else in --check reads the working tree for a review brief (check_brief's working-tree path test, help :50, still applies).

`co=""; if [[ "$pol" == self-merge ]] && ! checkout_gate; then` (`:739`). Executed: probe P8 (review brief, dirty tracked file) printed `ok`; mutant M12 (guard removed) turns test 4 red (`/tmp/fcf-1190629-iRp3/M12-review-reads-checkout.log`).

**Evidence:** `scripts/build-loop.sh:739`, `$L/probe2.out`, `$L/mutants.out`

---

## Claim 15: help "Untracked and ignored files are allowed." (also checkout_gate header :623-624)

**Location:** `scripts/build-loop.sh:135-136`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers untracked and ignored regular files and symlinks; an untracked nested repository (a `dir/` record) is the stated exception; an untracked file whose name starts with a newline inside a directory splits into a `dir/` line and is refused as a nested repository (fail closed).

git status runs with `--untracked-files=no` (`:654`); the others listing counts only lines matching `/\/$/` (`:662`). Test 1 adds `CLAUDE.local.md` (ignored) and `untracked.md` and then `cook` passes.

**Evidence:** `scripts/build-loop.sh:654`, `scripts/build-loop.sh:661-663`, `test/scripts/build-loop-check.bats:1639-1641`

---

## Claim 16: callervar comment "the caller's config pairs, which harden extends and trusts (GIT_CONFIG_PARAMETERS, GIT_CONFIG_COUNT), and GIT_NO_REPLACE_OBJECTS, which this script sets. GIT_CONFIG is not one: git config then reads that one file instead of every scope (gate_repo unsets it; checkout_gate refuses it)."

**Location:** `scripts/build-loop.sh:528-533`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three names, the GIT_CONFIG redirect for `git config`, and both consumers; "harden extends" applies to the GIT_CONFIG_COUNT pairs only (harden appends KEY_n/VALUE_n, `:220-224`; it does not touch GIT_CONFIG_PARAMETERS).

`export GIT_LITERAL_PATHSPECS=1 GIT_NO_REPLACE_OBJECTS=1 ...` (`:229`). Executed: with `core.ignoreCase true` in the repo config, `GIT_CONFIG=../cfg git config --type=bool --get core.ignoreCase` exited 1 (not found) while the plain call printed `true` (`$L/probe1.out`), so git config read only that file. `gate_repo`: `callervar "$v" || GATE_ENV+=(-u "$v")` (`:537`) and GIT_CONFIG is in `--local-env-vars`. Test 1's `GIT_CONFIG=... coref "GIT_CONFIG $ENVS"` passes; mutant M7 (callervar accepts GIT_CONFIG) turns test 1 red.

Command: `timeout 60 bash $L/probe1.sh`, cwd its mktemp dir; exit 0; 2026-10-09T01:36Z.

**Evidence:** `scripts/build-loop.sh:220-229`, `scripts/build-loop.sh:533-537`, `scripts/build-loop.sh:636-637`, `$L/probe1.out`, `$L/mutants.out`

---

## Claim 17: checkout_gate header "Item 2's fsmonitor and replace refs are harden's and the state gate's, and its ls-files stderr rule is the walk's own ... Needs GATE_TMP."

**Location:** `scripts/build-loop.sh:611-616`, `scripts/build-loop.sh:626`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the owners named for each item-2 part; does not establish the floor caller's (U2c) future use.

`for kv in core.useReplaceRefs=false core.hooksPath=/dev/null core.fsmonitor=false ...` (`:221`); state gate keys include `core\.fsmonitor` (`:243`) and `refs/replace/` is refused (`:259-260`). The walk: `checkout_md() { local e; { e="$(md_ls --cached --others 2>&1 >&3)"; } 3>&1 && [[ -z "$e" ]]; }` (`scripts/lib/dev-cycle-read.sh:880`). checkout_gate writes `$GATE_TMP/status`, `err`, `others`, `tree` (`:654-664`).

**Evidence:** `scripts/build-loop.sh:221-260`, `scripts/build-loop.sh:654-664`, `scripts/lib/dev-cycle-read.sh:876-880`

---

## Claim 18: checkout_gate header "check_line calls it for each self-merge brief once the merge and its changed paths are read, before the N rules and U2c's floor walk run per path, so it is final before that walk"

**Location:** `scripts/build-loop.sh:616-618`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers call position within check_line and per-brief invocation; does not establish that the checkout cannot change between this call and a U2c walk (A5 lists the swap as open).

The paths are read and counted at `:723-731`; the call is at `:739`; the per-path N-rules loop is `:751-755`. `check_line` runs once per brief (`for a in "${ARGS[@]}"; do out="$(check_line "$a")"`, `:775-776`).

**Evidence:** `scripts/build-loop.sh:723-757`, `scripts/build-loop.sh:775-776`

---

## Claim 19: checkout_gate header "Item 3 is checked by its effect, not by predicting it with check-attr: every regular file main stores must hash, unfiltered, to main's blob, so no conversion (a filter, working-tree-encoding, ident or eol attribute from any attributes source, the user's global ones included, which harden hides from the gate's own git) changed what a session reads there."

**Location:** `scripts/build-loop.sh:618-623`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers modes 100644/100755 on main; mode-120000 links are not hashed (Claim 26) and gitlinks are handled separately; does not establish anything about untracked files, which a session also reads.

`printf '%s\n' "${ps[@]}" | git hash-object --no-filters --stdin-paths` compared to `"$(printf '%s\n' "${ids[@]}")"` (`:688-691`); no `check-attr` call exists. `core.attributesFile=/dev/null` is in harden (`:221`). Executed: an `eol=crlf` checkout gave `DIFF` and an `ident` attribute on a file with no `$Id$` gave `SAME-noid` (`$L/probe1.out`); test 2 (ident, eol, non-UTF-8 name) passes; mutant M8 (comparison skipped) turns test 2 red.

**Evidence:** `scripts/build-loop.sh:221`, `scripts/build-loop.sh:665-691`, `$L/probe1.out`, `$L/mutants.out`

---

## Claim 20: checkout_gate header "A nested repository's files are not walk starts (rows 366, 373), so an untracked one, or a gitlink checked out with any file, fails."

**Location:** `scripts/build-loop.sh:624-626`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two refusals and the cited override rows; an absent gitlink path is refused by git status (` D sub`, `$L/probe3.out`) before `:676`'s `! -e` branch.

Override rows 366 and 373 (`docs/reviews/override-log.md`) are the U2a3 rows on submodule and untracked-nested-repo files not being start files. Code: `:663` and `:676`. Test 1 (`git init -q nested; coref ...`) and test 5 (`sub/CLAUDE.md`) pass; mutants M13 and M6 turn tests 1 and 5 red.

**Evidence:** `docs/reviews/override-log.md:366`, `docs/reviews/override-log.md:373`, `scripts/build-loop.sh:661-677`, `$L/mutants.out`, `$L/probe3.out`

---

## Claim 21: "The C locale: under UTF-8 a regex . does not match an invalid byte, and a record skipped for its name would escape the byte comparison." / "local -x LC_ALL=C  # exported: tr, awk and git run under it too"

**Location:** `scripts/build-loop.sh:629-631`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bash's regex and the children of checkout_gate; does not establish the walk's locale (contract item 1, U2c's).

`local -x` exports for the function's children: `f(){ local -x LC_ALL=C; env | grep '^LC_ALL'; }; LC_ALL=C.utf8 f` printed `LC_ALL=C` (`$L/probe1.out`). C.utf8 is installed (`locale -a`), so test 2's `LC_ALL=C.utf8 coref "$WHY"` with `docs/\xff.md` exercises the UTF-8 path; mutant M4 (the `local -x` line removed) turns test 2 red (the record fails `$re` and `:666` refuses with another WHY).

**Evidence:** `scripts/build-loop.sh:631-632`, `scripts/build-loop.sh:665-666`, `test/scripts/build-loop-check.bats:1666-1670`, `$L/probe1.out`, `/tmp/fcf-1190629-iRp3/M4-no-LC_ALL.log`

---

## Claim 22: "GIT_PREFIX only names a subdirectory for an alias; the script cds to the top level."

**Location:** `scripts/build-loop.sh:635`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the script's cd and that no command in checkout_gate reads GIT_PREFIX; does not establish git's alias semantics beyond its documentation.

`ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || ...; cd "$ROOT"` (`:283-284`). Executed: `GIT_PREFIX=sub/` produced `ok` (probe P2).

**Evidence:** `scripts/build-loop.sh:283-284`, `scripts/build-loop.sh:636`, `$L/probe2.out`

---

## Claim 23: "ls-files -v tags each entry: H is plain; S is skip-worktree, lower case is assume-unchanged (git status skips a change under either), M is unmerged."

**Location:** `scripts/build-loop.sh:648-649`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5 output for the four states; does not establish fsmonitor-valid lower-casing (harden sets core.fsmonitor=false).

`git ls-files -v` printed `H "\"q\""`, `S q`, `h r`, and `M q` three times for an unmerged path (`$L/probe1.out`). Test 1 asserts `git status --porcelain --untracked-files=no` is empty under each flag before `coref "$IDX"`; mutant M9 turns test 1 red.

**Evidence:** `scripts/build-loop.sh:650-652`, `test/scripts/build-loop-check.bats:1645-1650`, `$L/probe1.out`

---

## Claim 24: "To a file: bash would warn on stderr about the NULs a $(...) drops."

**Location:** `scripts/build-loop.sh:653`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bash 5.2.15.

`x="$(printf 'a\0b')"` printed `warning: command substitution: ignored null byte in input` (`$L/probe1.out`).

**Evidence:** `scripts/build-loop.sh:654`, `$L/probe1.out`

---

## Claim 25: "Without --exclude-standard every untracked file is listed, ignored ones too, and a nested repository as its directory with a trailing / (no file name holds a /). Listed to a file first: under pipefail a reader that stops early, or finds nothing, would hide a failed listing."

**Location:** `scripts/build-loop.sh:657-660`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5 output; after `tr '\0' '\n'` a name holding a newline can yield a line ending in `/` (Claim 15's scope).

`git ls-files -z --others` printed `d/z`, `ign.log` (ignored by info/exclude) and `nested/` (`$L/probe1.out`). The listing's exit status is checked on its own (`> "$GATE_TMP/others" || {...}`, `:661`).

**Evidence:** `scripts/build-loop.sh:661-663`, `$L/probe1.out`

---

## Claim 26: "git status compares a link's text to its blob unconverted (core.symlinks is true here)."

**Location:** `scripts/build-loop.sh:670`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers an `ident` attribute on a link; does not establish other attributes on links.

A link `lnk -> tgt$Id$` with `lnk ident` re-checked-out kept `tgt$Id$` and git status was clean (`$L/probe1.out`). `core.symlinks false` is refused earlier (`:641`), and a global `core.symlinks=false` checkout is refused by git status (`$L/probe4.out`).

**Evidence:** `scripts/build-loop.sh:641-646`, `scripts/build-loop.sh:671`, `$L/probe1.out`, `$L/probe4.out`

---

## Claim 27: "hash-object --stdin-paths reads a line: a newline splits a name, a leading \" is unquoted and a trailing CR dropped, so another file is hashed."

**Location:** `scripts/build-loop.sh:680-681`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5.

`printf '%s\n' '"q"' $'r\r' | git hash-object --no-filters --stdin-paths` printed the ids of `q` and `r`, not of `"q"` and `r\r` (`$L/probe1.out`). Test 3 passes; mutant M5 (name rule removed) turns it red.

**Evidence:** `scripts/build-loop.sh:682-683`, `$L/probe1.out`, `$L/mutants.out`

---

## Claim 28: "import_reset  # caller contract item 4: no walk cache outlives a decision"

**Location:** `scripts/build-loop.sh:701`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the function exists, clears both walk caches and is called per brief; no walk runs in check_line yet.

`import_reset() { IMPORTED_DONE=""; IMPORTED_MAIN_DONE=""; }` (`scripts/lib/dev-cycle-read.sh:608`); item 4 is `Call import_reset before each gate decision` (`:65`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:65-67`, `scripts/lib/dev-cycle-read.sh:608`, `scripts/build-loop.sh:701`

---

## Claim 29: check_line "checked once the merge's paths are read and before U2c's floor walk, which runs per path below and only when co is empty (never over a checkout refused here); its refusal replaces the verdict line only, so the N rules' path and deny lines still print"

**Location:** `scripts/build-loop.sh:732-736`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the call position and the verdict-line replacement (executed, Claim 10); "only when co is empty" is a U2c commitment, consistent with the plan's U2c bullet, not yet code.

See Claims 10 and 18.

**Evidence:** `scripts/build-loop.sh:739-757`, `docs/working/plan-build-loop-handoff.md:286`

---

## Claim 30: check_line "Run per brief, so each decision sees the checkout as it is: about 0.25 s here"

**Location:** `scripts/build-loop.sh:736-737`
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers order of magnitude on a clone of main (3,163 files); the timing ran under a load average of about 3 from another session's suite run, so the idle figure is inferred.

checkout_gate (extracted with `sed -n '/^callervar() {/p; /^checkout_gate() {/,/^}/p'`) on a clone of main took 0.290-0.689 s over five runs (`$L/timing2.out`), lowest 0.29 s under load.

Command: `timeout 300 bash $L/timing.sh`, cwd its mktemp dir; exit 0; 2026-10-09T01:38:55Z.

**Evidence:** `scripts/build-loop.sh:628-692`, `$L/timing.sh`, `$L/timing2.out`

---

## Claim 31: check_line "times the self-merge briefs in one --check (at most the slot count)"

**Location:** `scripts/build-loop.sh:738`
**Type:** Performance / Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers whether --check bounds the number of self-merge briefs; does not establish how the orchestrator (U3) will call it.

Nothing in --check caps the count: `for a in "${ARGS[@]}"; do out="$(check_line "$a")"` (`:775-776`), and SLOTS is not read in check mode. Probe P3 (slots 3, four self-merge briefs) ran checkout_gate four times (four refusals, `$L/probe2.out`). Precise version: "at most the slot count when the orchestrator passes only dispatched briefs; --check itself takes any number".

**Evidence:** `scripts/build-loop.sh:769-779`, `$L/probe2.out`

---

## Claim 32: lib header item 3 note "The walk checks neither item but item 2's ls-files stderr rule. build-loop.sh --check does, for each self-merge brief before the walk (U2b2; item 1's LC_ALL=C for the walk is its U2c floor caller's): harden and its state gate own item 2's fsmonitor and replace refs; checkout_gate the rest of item 2 ..., core.symlinks, and the attributes by their effect, not by check-attr: every regular file main stores hashes, unfiltered, to main's blob (so an eol conversion fails it too, and an attribute that changes no bytes does not)."

**Location:** `scripts/lib/dev-cycle-read.sh:55-62`
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the ownership split (Claim 17) and the two parenthetical effects; does not establish item 2's "final before the walk" against a concurrent writer.

Executed: eol=crlf → `DIFF`; ident with no `$Id$` → `SAME-noid` (`$L/probe1.out`); test 2 refuses eol=crlf under a clean git status.

**Evidence:** `scripts/lib/dev-cycle-read.sh:45-62`, `scripts/build-loop.sh:688-691`, `$L/probe1.out`

---

## Claim 33: the five U2b2 tests' names and comments (test 1: "HEAD, env, config, index bits, status, nested repositories"; test 2: "ident and eol attributes, a non-UTF-8 name under a UTF-8 locale"; test 3: "a leading quote, a trailing CR"; test 4: "judges a review brief without its checkout, and a self-merge brief's checkout after its paths"; test 5: "a gitlink's path holds files, is a symlink or cannot be listed")

**Location:** `test/scripts/build-loop-check.bats:1637-1705`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that each test passes and that a mutant of each named rule turns the named test red; test 5's symlink case is refused by the git status rule, as its own comment says (the `-L` branch is not exercised, Claim 3); test 1 does not create an unmerged entry; "after its paths" in test 4 means the output order.

All 106 build-loop-check tests pass. Mutant → red test: M4 LC_ALL → 2; M5 names → 3; M6 gitlink unlistable → 5; M7 GIT_CONFIG → 1; M8 byte compare → 2; M9 index bits → 1; M10 refusal removed → 1-5; M11 rows dropped → 1-5; M12 review reads checkout → 4; M13 nested repo → 1. Test 5's comment "git status already fails on a symlink there (exit 128)" matches `$L/probe3.out` (rc=128); "an empty directory there passes (git status reports an absent one)" matches ` D sub` for the absent path and a clean status for an empty directory.

Commands: `TMPDIR=$T timeout 1500 bats -j 4 test/scripts/build-loop-check.bats`, cwd `/tmp/fcf-1061983-oHCM`, exit 0, 2026-10-09T01:36:18Z; `timeout 1800 bash $L/mutants.sh`, exit 0, 01:36Z-01:38Z.

**Evidence:** `test/scripts/build-loop-check.bats:1604-1705`, `$L/build-loop-check.bats.log`, `$L/mutants.out`, `/tmp/fcf-1190629-iRp3/*.log`, `$L/probe3.out`

---

## Claim 34: commit c10b972a "Tests: three in build-loop-check.bats ... Mutants that drop the refusal, the byte comparison or the index-bit check each turn a test red. Suites 104/19/78/2/2" and "this repo's 3,163 files"

**Location:** commit c10b972a
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the counts at c10b972a and the three mutants against HEAD's tests (not c10b972a's three tests).

`grep -c '^@test '` at c10b972a: 104 (main 101, so three added), 19, 78; fixture-git-env 2, fixture-hermeticity 2. `git ls-tree -r c10b972a | wc -l` = 3163. Mutants M10, M8, M9 turn tests red (Claim 33).

**Evidence:** commit c10b972a, `$L/mutants.out`

---

## Claim 35: commit c10b972a "It costs 0.14 s over this repo's 3,163 files."

**Location:** commit c10b972a
**Type:** Performance
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** executed
**Scope:** The file count is verified (Claim 34); the 0.14 s figure is for c10b972a's version on an unloaded machine and was not re-measured at that commit.

HEAD's checkout_gate measured 0.29-0.69 s under load (Claim 30); HEAD's version has more steps than c10b972a's. A quiet machine and c10b972a's function would be needed.

**Evidence:** `$L/timing2.out`

---

## Claim 36: commit 639f7b40 subject "judge the checkout per self-merge brief after the N rules" and A4-A6 bullet "checkout_gate runs inside check_line for each self-merge brief, after the merge and the N rules"

**Location:** commit 639f7b40
**Type:** Architectural
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers call order at 639f7b40 and at HEAD; already recorded Accepted-immutable (override row, Claim 1).

The call (`:739` at HEAD) precedes the N-rules loop (`:751-755`); only the printed verdict line follows the rows' computation. The commit message cannot be edited; the code comment, help and plan now say "before the N rules".

**Evidence:** `scripts/build-loop.sh:739-757`, `docs/reviews/override-log.md:527`

---

## Claim 37: commit 639f7b40 "Each fix's mutant turns a test red."

**Location:** commit 639f7b40
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the iteration-1 fixes' mutants against HEAD's tests.

The LC_ALL (M4), name (M5), gitlink-unlistable (M6) and GIT_CONFIG (M7) mutants turn tests red, but the gitlink `-L`, unmatched-record refusal and status-stderr mutants stay green (Claim 3). Precise version: "each fix's main mutant turns a test red; three defensive sub-rules have no failing mutant".

**Evidence:** `$L/mutants.out`

---

## Claim 38: commit 639f7b40 Notes "a symlink at a gitlink path is refused by the git status rule (git warns) before the gitlink rule reads it"

**Location:** commit 639f7b40
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5.

git status exits 128 with `error: expected submodule path 'sub' not to be a symbolic link` (`$L/probe3.out`): it fails, not warns; the refusal and its order are right. 368a3194 fixed the matching test comment.

**Evidence:** `$L/probe3.out`, `scripts/build-loop.sh:654-655`

---

## Claim 39: commit 639f7b40 "Suites 106/19/78/2/2; shellcheck clean"

**Location:** commit 639f7b40
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the counts at 639f7b40 and a pass at HEAD (639f7b40..HEAD changes 2 test lines, no test count); shellcheck as health-check.sh runs it (`-x -e SC1091 -s bash -S warning`).

Counts at 639f7b40: 106, 19, 78, 2, 2. At HEAD all pass: build-loop-check 106/106, build-loop-read 19/19 (the first run's one failure was my archive lacking `docs/dev-cycle.md`; rerun with it, 19/19), dev-cycle 78/78, fixture-git-env 2/2, fixture-hermeticity 2/2. Shellcheck exit 0 on build-loop.sh, the lib and the bats file.

Commands: the suite loop in `/tmp/fcf-1061983-oHCM` (2026-10-09T01:36:18Z, exits 0/1/0/0/0, then the read-suite rerun at 01:38:03Z, exit 0); `shellcheck -x -e SC1091 -s bash -S warning FILE` (01:39:43Z, exits 0).

**Evidence:** `$L/suites.summary`, `$L/build-loop-read.rerun.log`, `$L/dev-cycle.bats.log`, `$L/fixture-git-env.bats.log`, `$L/fixture-hermeticity.bats.log`, `$L/shellcheck2.out`

---

## Claim 40: commit 368a3194 "Also: `local -x LC_ALL=C`, so tr, awk and git inherit the C locale (before, only bash's own matching used it, claim 23)."

**Location:** commit 368a3194
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bash 5.2.15's handling of a `local` over an exported variable.

The "now" half holds (Claim 21). The "before" half holds only when the caller had not exported LC_ALL: `g(){ local LC_ALL=C; env | grep "^LC_ALL"; }` printed `LC_ALL=C` when called with `LC_ALL=C.utf8` in the environment and `none` when LC_ALL was unset (shell probe, 2026-10-09T01:37Z). That is why mutant M4b (`local` without `-x`) stays green: the test exports LC_ALL.

**Evidence:** `scripts/build-loop.sh:631`, `$L/mutants.out`

---

## Claim 41: commit 368a3194 "three mutants stay green, as the fact-check recorded: the gitlink -L test (git status fails first), the unparseable-record refusal (unreachable under the C locale), and the stderr-only half of the git status rule" and its list of corrections

**Location:** commit 368a3194
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the mutants (Claim 3) and that the named comment/help/plan/A5/test edits are in 368a3194's diff.

The diff changes the checkout_gate comment, help, plan bullet, callervar wording, the test comment (`warns` → `fails (exit 128)`) and A5 (adds "other names one file has on a case-insensitive filesystem whose core.ignoreCase is false").

**Evidence:** commit 368a3194, `$L/mutants.out`

---

## Claim 42: commit 1f4f7a21 B2, C1, C2, C4 items, the four override rows, and "the U2b2 tests (5/5) and shellcheck pass"

**Location:** commit 1f4f7a21
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that each named edit is present at HEAD and the 5/5 and shellcheck results; "found no red and no security finding" is the rubric's record, not re-derived.

B2: `:733-734` and plan :286; C1: lib :57 and plan :286; C2: help :115-118 and `a regular file main stores whose name` (:130); C4: `:736-738`. Override rows 527-530 match the four listed dispositions. The U2b2 tests pass 5/5 (M0 control) and shellcheck exits 0 (Claim 39).

**Evidence:** `scripts/build-loop.sh:115-130`, `scripts/build-loop.sh:732-738`, `scripts/lib/dev-cycle-read.sh:57`, `docs/reviews/override-log.md:527-530`, `$L/mutants.out`, `$L/shellcheck2.out`

---

## Claims Requiring Attention

### Incorrect
- **Claim 36** (commit 639f7b40): "after the N rules"; the check runs before them. Already Accepted-immutable (override row 527); nothing left to fix.

### Stale
None.

### Mostly Accurate
- **Claim 11b** (`scripts/build-loop.sh:129-132`): a newline name on main is refused under the index-bits WHY ("marks entries skip-worktree, assume-unchanged or unmerged"), because `ls-files -v -z | tr` splits it at `:650`; the name WHY at `:683` is unreachable for a newline. A symlink at a gitlink path is refused under the git status WHY.
- **Claim 31** (`scripts/build-loop.sh:738`): "at most the slot count" is the orchestrator's convention; --check accepts any number of self-merge briefs and checks each one.
- **Claim 37** (commit 639f7b40): three fixes' mutants stay green (already Accepted, override row 529).
- **Claim 38** (commit 639f7b40): git status fails (exit 128) at a gitlink symlink; it does not warn.
- **Claim 40** (commit 368a3194): before `-x`, children already inherited LC_ALL=C whenever the caller exported LC_ALL.

### Unverifiable
- **Claim 2** (`docs/reviews/override-log.md:528`): the ~24 s figure needs the 50k-file, 200 MB fixture rebuilt.
- **Claim 35** (commit c10b972a): the 0.14 s figure needs c10b972a's function timed on an idle machine.

---

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to the path named at the end of this prompt, structured per the code-fact-check skill, with `Commit: 1f4f7a21` as its first line.
- Answered: yes. All eight focus areas: (1) Claims 8-15, 11b; (2) 17-27; (3) 12, 16, 22; (4) 28-31; (5) 32; (6) 1-7; (7) 34-42; (8) 33.
- Out of scope: whether the newline-name WHY should be reworded or the slot-count wording changed (author's call); a case-insensitive filesystem; scripts/health-check.sh as a whole; timings on an idle machine (another session's suite run held the load at about 3).
- Escalate: Claim 11b (a misleading WHY for a newline name; fail-closed, wording only). Residue for the security pass: checkout_gate reads core.ignoreCase and core.sparseCheckout with GIT_CONFIG_GLOBAL=/dev/null and GIT_CONFIG_NOSYSTEM=1, so a global or system setting is not seen (a global core.symlinks=false is still caught, by git status: `$L/probe4.out`).
- Decisions I made: read "come first" (help :136) as output precedence, not call order; verdicted the U2c-only commitments (Claims 7, 29) as consistent with the plan, not as code.
