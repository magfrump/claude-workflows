Commit: 368a3194

# API Consistency Review — feat/build-loop-u2b2 (U2b2, the gate's checkout), iteration 2

**Scope:** delta `c10b972a..368a3194` (fix commits 639f7b40, 368a3194): scripts/build-loop.sh, scripts/lib/dev-cycle-read.sh, test/scripts/build-loop-check.bats, docs/working/known-issues-dev-cycle.md, docs/working/plan-build-loop-handoff.md; read against the whole `--check` help text (build-loop.sh:80-160), `checkout_gate` and `check_line` whole (:609-750) and the check-mode driver
**Date:** 2026-10-08
**Based on:** docs/reviews/code-fact-check-report-build-loop-u2b2-i2.md (k=1, 26 claims; its 3 Incorrect, about documented order, fixed in 368a3194; residue Claims 1 and 3 used below); iteration-1 report docs/reviews/api-consistency-reviewer-review-2026-10-08-build-loop-u2b2.md

## Baseline Conventions

Unchanged from iteration 1 (that report's Baseline section): `--check` prints one verdict line per brief (`ok BRIEF TIP TREE` / `refuse BRIEF: WHY` / `skip BRIEF: WHY`), path/deny lines after it, exit 2 on any non-ok verdict; WHYs are lower-case clauses saying "the default branch"; a mismatch prints both sides (`the tip of $br is $sha, not the expected $EXPECT`, :709); a read failure gets its own WHY, with the git exit code where known (`refuse state $f: it could not be read (git config exit $rc)`, :248); `*_gate` returns 1 and carries its reason in a `*_WHY` global. One new convention this delta sets: the checkout refusal's text up to `; ` is declared fixed for parsers (help :115-116), the first `refuse BRIEF` WHY to be declared a parse token.

## Verification of iteration-1 findings

| # | Iteration-1 finding | Status at 368a3194 | Evidence |
|---|---|---|---|
| F1 | Advisory run lost path lines | Fixed | `co=""; if [[ "$pol" == self-merge ]] && ! checkout_gate; then co="refuse $a: ..."; fi` (:733) and `if [[ -n "$co" ]]; then echo "$co"; elif ...` (:748), rows still printed; test "On feat/x itself, as a loop runs it: the refusal, then every path line, a deny among them" pins it. Plan U2b2 bullet updated. Residue: N1. |
| F2 | Help text incomplete | Fixed, small residue | Help now names the GIT_* exemptions, "or one of them unreadable", git status failing/warning, gitlink symlink/unlistable, the name rule, "a listing or hash of these that fails"; lib note now attributes fsmonitor/replace refs to harden and the state gate. Residue: N4 (fact-check Claim 1). |
| F3 | `its` meant the checkout | Fixed | Every CHECKOUT_WHY now names its subject: "the checkout's HEAD is ...", "the checkout's index ...", "the checkout holds ...", "git status failed or warned in the checkout". |
| F4 | Read failures folded into refusals | Fixed, small residue | `[[ "$rc" -le 1 ]] \|\| { CHECKOUT_WHY="${v%% *} could not be read"; ...}` split from `"${v%% *} is $r"`; index listing split from flagged entries; hash failure split from mismatch. Residue: N3. |
| F5 | A5 stale | Fixed | A5 now: "U2b2 closes several of these for the gate (not for the walk itself) ... Still open there: ...". |
| F6 | Fixed prefix; actual HEAD | Fixed | "(the text up to "; " is fixed; path and deny lines follow it as they follow ok)"; `"the checkout's HEAD is $x, not the default branch's commit $MAIN_SHA"`. Residue: N2. |

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `callervar NAME` | function (predicate) | `inrepo`, `anybrief`, `isstart` | `scripts/lib/dev-cycle-read.sh:169,210,536` | Consistent — lower-case run-together predicate returning status, no `is_` underscore form |
| `the checkout's HEAD is X, not the default branch's commit Y` | WHY | `the tip of $br is $sha, not the expected $EXPECT` | `scripts/build-loop.sh:709` | Consistent — "A is X, not Y" mismatch shape; X may be the word `unreadable` (N3) |
| `core.X could not be read` | WHY | `refuse state $f: it could not be read (git config exit $rc)`, `$f could not be read from the default branch` | `scripts/build-loop.sh:248,305` | Mostly consistent — omits the exit code the state gate's git-config twin prints (N3) |
| `core.X is V: EXPLANATION` | WHY | `refuse state $line: set in $f, ...` | `scripts/build-loop.sh:233-260` | Consistent |
| `the checkout's index could not be listed`, `the checkout's untracked files could not be listed`, `the checkout's files could not be hashed`, `the default branch's tree could not be read` | WHY | `the paths the merge of $br changes could not be listed/read`, `the merge of $br could not be computed` | `scripts/build-loop.sh:719,723,729` | Consistent in wording; but sit under the checkout prefix (N2) |
| `git status failed or warned in the checkout` | WHY | help's "git failed, or warned on stderr" for merge failures | `scripts/build-loop.sh:104-106` | Consistent — same failed/warned pairing |
| `a gitlink's path in the checkout is a symlink or cannot be listed` | WHY | `a gitlink is checked out with files, ...` (iteration 1) | `scripts/build-loop.sh:671-674` | Consistent |
| `a file on the default branch has a name the byte comparison cannot read (...)` | WHY | iteration 1's `... has a newline in its name` | `scripts/build-loop.sh:680-681` | Consistent — supersedes it |
| `$v is set, so git can read another work tree, index, object store or config file` | WHY | iteration-1 wording minus "or config file" | `scripts/build-loop.sh:633-634` | Consistent — extended for GIT_CONFIG |
| bats `ENVS`, `LINK`, `NAME`, `WHY` | test constants | `CO`, `IDX`, `STAT`, `NOWN`, `NFORM` | `test/scripts/build-loop-check.bats:1605-1620` | Consistent — upper-case expected-WHY constants |

No new flag, line kind or exit code. The verdict-line precedence changed (checkout refusal over ok and over K-of-N); see N1.

## Findings

#### N1. The checkout refusal now displaces the K-of-N line, and the help's "as they follow ok" does not describe deny lines

**Severity:** Minor
**Location:** `scripts/build-loop.sh:115-116, :111-112, :141` (help), `:748` (check_line)
**Move:** 3 (consumer contract), 7 (asymmetry)
**Confidence:** High
**Legibility-target:** for-author

Evidence (code): `if [[ -n "$co" ]]; then echo "$co"; elif [[ "$nd" -eq 0 ]]; then echo "ok $a $sha $tree"; else echo "refuse $a: $nd of ${#ps[@]} changed paths refused in the merge of $sha (tree $tree)"; fi`. Evidence (help): `Or "K of N changed paths refused in the merge of TIP (tree TREE)", when deny lines follow.` and `(the text up to "; " is fixed; path and deny lines follow it as they follow ok)`.

Before this delta, deny lines followed only the K-of-N line, and that line carried the count, TIP and TREE. Now a self-merge brief whose checkout fails and whose merge has denies prints the checkout refusal followed by deny lines, with no K, no TIP and no TREE (the ok line's TREE is also lost when only path lines follow). The help still reads as if K-of-N is the line that precedes deny lines, and "as they follow ok" is literally untrue for deny lines (ok is printed only when nothing is denied). A parser written from the header (the orchestrator, a loop reading its advisory run) that keys "deny lines expected" off the K-of-N line, or reads TREE from the verdict line, gets neither. Not Breaking: no consumer is built yet (U3/U4).

**Recommendation:** Say it in the help: "path and deny lines follow it as they follow ok or a K of N refusal; it outranks both, so K, TIP and TREE are not printed — count the deny lines". Optionally append the K-of-N facts to the checkout line, but a sentence suffices.

#### N2. The fixed checkout prefix now names a remedy that several of its WHYs do not need

**Severity:** Minor
**Location:** `scripts/build-loop.sh:660, 664, 676, 688-689` (CHECKOUT_WHY), composed at `:733`; help `:115-116`
**Move:** 4 (error consistency)
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

Evidence: `CHECKOUT_WHY="the default branch's tree could not be listed"`, `CHECKOUT_WHY="the default branch's tree could not be read"` (twice), `CHECKOUT_WHY="the checkout's files could not be hashed"`, each printed as `refuse $a: a self-merge brief needs --check run from a clean checkout of the default branch's commit; $CHECKOUT_WHY`.

Iteration 2 declares the prefix fixed so that a parser can recognise this refusal (F6), which in practice means routing it to "rerun from a clean main checkout". The main-tree listing/read failures are object-store or git failures, not checkout state; the merge-side equivalents get their own non-checkout lines (`the merge of $br could not be computed`, `the paths the merge of $br changes could not be read`). An orchestrator classifying by prefix would retry from a fresh checkout and fail the same way. The hash failure can be either (an unreadable checkout file, or git failing).

**Recommendation:** Either print the main-tree failures without the checkout prefix (`refuse $a: the default branch's tree could not be listed`, like the merge-side read failures), or say in the help that the prefix marks "the checkout check could not pass", not "the checkout is dirty", so consumers do not equate it with one remedy.

#### N3. Two read-failure WHYs drift from their neighbours: no git exit code, and `unreadable` in the commit slot

**Severity:** Informational
**Location:** `scripts/build-loop.sh:643, 637-638`
**Move:** 4 (error consistency)
**Confidence:** Medium
**Legibility-target:** for-author

Evidence: `[[ "$rc" -le 1 ]] || { CHECKOUT_WHY="${v%% *} could not be read"; return 1; }` vs the state gate's `echo "refuse state $f: it could not be read (git config exit $rc)"` (:248), the same `git config` read failure; and `x="$(git rev-parse --verify -q 'HEAD^{commit}')" || x="unreadable"` printed as `the checkout's HEAD is unreadable, not the default branch's commit SHA`.

The F4 split is done; these are wording residues. The state gate's twin carries the exit code, which is the only diagnostic a user has. The HEAD line is good English, but a parser reading the "is X, not ... Y" mismatch shape (shared with `the tip of $br is $sha, not the expected $EXPECT`) gets a non-hex word where a commit id goes. Both are cheap to align.

**Recommendation:** `${v%% *} could not be read (git config exit $rc)`; for HEAD, either `the checkout's HEAD could not be read` as its own WHY or leave it and note the word in the help.

#### N4. Help residue: the name rule is stated for every file main stores, and two refusals are folded into neighbours

**Severity:** Informational
**Location:** `scripts/build-loop.sh:117-118, 128-133` (help)
**Move:** 3 (documentation drift)
**Confidence:** High (fact-check i2 Claim 1)
**Legibility-target:** for-author

Evidence (help): `a file main stores whose name holds a newline, starts with a quote or ends with a CR`; `has its HEAD at another commit`. Evidence (code): `120000) continue ;;` and the 160000 branch `continue`s before the name test (:667-675); `x="unreadable"` (:637); `*) CHECKOUT_WHY="the default branch's tree could not be read"` for an unexpected mode (:676).

A symlink or gitlink with such a name is not refused, so "a regular file main stores" is the exact scope. An unreadable HEAD and an unexpected tree mode each print a WHY the help covers only by implication ("another commit", "a listing ... that fails").

**Recommendation:** "a regular file main stores whose name ..."; "has its HEAD at another commit (or unreadable)"; leave the mode case under "a listing ... that fails" or name it.

## What Looks Good

- F1's fix is the minimal contract change: one verdict line per brief, exit 2, line kinds unchanged, and the path lines a loop's advisory run needs are back, pinned by a test that runs from the brief's own branch.
- Every checkout WHY now names its subject ("the checkout's ..."), matching the explicit-subject style of the merge-side WHYs.
- The read-failure/refusal split now mirrors the state gate in shape, for config, index, listing and hashing.
- The help now declares the prefix fixed and lists the exemptions; the plan, A5 and the lib caller-contract note all describe the per-brief placement, so header, plan and lib agree (the three Incorrect order claims were fixed in 368a3194).
- `callervar` gives gate_repo and checkout_gate one exemption rule, so the two cannot drift on which repo-local variables are the caller's; its name follows the lib's run-together predicate style.
- `coref` now asserts both lines and an empty stderr, so wording and line-order changes surface as test diffs.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---|---|---|---|
| N1 | Checkout refusal displaces the K-of-N line (no K/TIP/TREE before deny lines); help's "as they follow ok" inaccurate for deny lines | Minor | `scripts/build-loop.sh:111-116,141,748` | High |
| N2 | Fixed checkout prefix also carries main-tree read failures that a clean checkout does not fix | Minor | `scripts/build-loop.sh:660,664,676,688,733` | Medium |
| N3 | `core.X could not be read` lacks the git exit code the state-gate twin prints; `unreadable` in the HEAD mismatch's commit slot | Informational | `scripts/build-loop.sh:637-643` | Medium |
| N4 | Help: name rule applies to regular files only; unreadable HEAD and unexpected tree mode folded into neighbours | Informational | `scripts/build-loop.sh:117-133` | High |

## Overall Assessment

All six iteration-1 findings are fixed, and F1 in the form that keeps the existing line grammar. What remains comes from that fix and from declaring the prefix a parse token: the checkout refusal now outranks the K-of-N line, so the help should say deny lines can follow it without the count (N1), and a prefix declared stable for routing should not also carry failures that a clean checkout does not cure (N2). Both can be fixed in place in the help text or with a one-line reroute; neither blocks a consumer that has not been built. N3 and N4 are wording.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to /workspace/.claude/wt-build-loop-u2b2/docs/reviews/api-consistency-reviewer-review-2026-10-08-build-loop-u2b2-i2.md (first line `Commit: 368a3194`), structured per the critic skill.
- Answered: yes. Each iteration-1 fix checked against the code at 368a3194; the new and reworded WHYs and `callervar` compared with their neighbours; the verdict-line precedence traced for the orchestrator and loops that will parse it.
- Out of scope: whether the checks can be bypassed (security); cost of running checkout_gate per self-merge brief, and before the blob/lower-casing refusals that can discard its result (performance).
- Escalate: none. N1 and N2 are help-text or small reroute decisions for the author.
- Decisions I made: no probe run, since each finding follows directly from check_line's print order and the CHECKOUT_WHY assignments, and the fact-check executed the suites at HEAD; rated N2 Minor rather than Informational because this delta is what declared the prefix a parse token.
