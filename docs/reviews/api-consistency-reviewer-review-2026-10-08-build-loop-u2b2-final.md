Commit: 1f4f7a21

# API Consistency Review — feat/build-loop-u2b2 (U2b2, the gate's checkout), final confirming pass

**Scope:** the whole branch, `main...1f4f7a21`: scripts/build-loop.sh (`--check` help :80-165 and Exit line :167-170, `callervar`, `gate_repo`, `checkout_gate` :609-691, `check_line` :697-760), scripts/lib/dev-cycle-read.sh (caller-contract item 3 note), test/scripts/build-loop-check.bats (five U2b2 tests), docs/working/plan-build-loop-handoff.md (U2b2, U2c bullets), docs/working/known-issues-dev-cycle.md (A5)
**Date:** 2026-10-08
**Based on:** code-fact-check-report-build-loop-u2b2-final-r1/-r2/-r3.md (k=3); my iteration reports api-consistency-reviewer-review-2026-10-08-build-loop-u2b2.md and -i2.md; override rows 459/465 (one numbered contract) and 530 (verdict-chain shape, deferred to U2c), which this report does not reopen

## Baseline Conventions

- `--check` prints one verdict line per brief: `ok BRIEF TIP TREE`, `refuse BRIEF: WHY` or `skip BRIEF: WHY`. Path and deny lines (`path BRIEF S PATH`, `deny BRIEF S PATH: WHY`) follow it. Exit 2 means some verdict was not ok. Exit 1 is reserved for bad usage, no repo, no perl or lib, a failed mktemp, or no default branch (:167-170). In every one of those cases no verdict line prints.
- WHYs are lower-case clauses that say "the default branch". A mismatch names both sides (`the tip of $br is $sha, not the expected $EXPECT`). A read failure gets its own WHY (`... could not be read`, `... could not be listed`), separate from the refusal it blocks. The state gate's git-config twin also gives the exit code (`it could not be read (git config exit $rc)`).
- A gate helper (`*_gate`) returns 1 and leaves its reason in a `*_WHY` global. Predicates are lower-case words run together (`inrepo`, `anybrief`, `isstart`).
- U2b2 adds the first WHY prefix that the help declares fixed for parsers: `a self-merge brief needs --check run from a clean checkout of the default branch's commit; WHY`.

## Verification of iteration-2 findings

| # | Iteration-2 finding | Status at 1f4f7a21 | Evidence |
|---|---|---|---|
| N1 | The checkout refusal displaces the K-of-N line, and "as they follow ok" was wrong for deny lines | Fixed | Help: `path and deny lines follow it as they follow a K of N refusal` and `After an ok line, a K of N refusal or a checkout refusal, one line per path`. Fact-check r3 Claim 12 verified this by running it. |
| N2 | The fixed prefix also carries main-tree read failures that a clean checkout does not cure | Fixed in the docs | Help: `the text up to "; " is fixed, but a WHY naming a read failure is not one a clean checkout cures`. Residue: F3. |
| N3 | `core.X could not be read` has no exit code, and `unreadable` sits in the HEAD commit slot | Moot / open | The core.* branch can never run (F1). `x="unreadable"` is unchanged (:639) and is folded into F2. |
| N4 | The name rule's scope, and the unreadable-HEAD and tree-mode cases | Partly fixed | Help now says `a regular file main stores whose name ...`. The unreadable HEAD and an unparseable tree record are still covered only by neighbouring clauses (F2). |

## Name-Pattern Audit

No new flag, line kind or exit code. The new public names are WHY strings and one shell predicate. They are unchanged since iteration 2, and that audit's verdicts stand:

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `callervar NAME` | function (predicate) | `inrepo`, `anybrief`, `isstart` | `scripts/lib/dev-cycle-read.sh` | Consistent: a lower-case predicate written as one word |
| `checkout_gate` / `CHECKOUT_WHY` | function / global | `gate_repo`, the state gate's WHY globals, `IMPORTED_MAIN_WHY` | `scripts/build-loop.sh`, `scripts/lib/dev-cycle-read.sh` | Consistent: the `*_gate` / `*_WHY` pair |
| `a self-merge brief needs --check run from a clean checkout of the default branch's commit; WHY` | refuse WHY (fixed prefix) | `the brief is $st on the default branch; only an open brief merges` | `scripts/build-loop.sh:705` | Consistent: a clause, then `; ` and a qualifier, the same shape the brief-status refusal already uses |
| `the checkout's HEAD is X, not the default branch's commit Y` | WHY | `the tip of $br is $sha, not the expected $EXPECT` | `scripts/build-loop.sh` (check_line) | Consistent shape, but X can be the word `unreadable` (F2) |
| `core.X is V: ...` / `core.X could not be read` | WHY | `refuse state $line: set in $f, ...` / `it could not be read (git config exit $rc)` | `scripts/build-loop.sh:233-260` | Consistent; the read-failure form can never print (F1) |
| `the checkout's index/untracked files could not be listed`, `the default branch's tree could not be listed/read`, `the checkout's files could not be hashed` | WHY | `the paths the merge of $br changes could not be read` | `scripts/build-loop.sh` (check_line) | Consistent wording |
| `git status failed or warned in the checkout` | WHY | help's "git failed, or warned on stderr" | `scripts/build-loop.sh:104-106` | Consistent |
| `a gitlink ...`, `a file on the default branch has a name the byte comparison cannot read (...)`, `$v is set, so git can read ...` | WHY | the merge-side WHYs, which name their subject | `scripts/build-loop.sh` | Consistent: each names its subject |
| bats `CO`, `IDX`, `STAT`, `ENVS`, `LINK`, `NAME`, `WHY` | test constants | `NOWN`, `NFORM` | `test/scripts/build-loop-check.bats` | Consistent: expected WHYs held in upper-case constants |

## Findings

#### F1. The help documents a checkout refusal that cannot print; the real outcome is exit 1 with a wrong diagnosis

**Severity:** Minor
**Location:** `scripts/build-loop.sh:124-125` (help), `:643-645` (branch), `:167-170` (Exit), `:283`
**Move:** 3 (consumer contract: documentation drift), 4 (error consistency)
**Confidence:** High (fact-check r3, Incorrect, executed: E2 P3)
**Legibility-target:** for-orchestrator-synthesis

Evidence (help): `core.symlinks false, core.ignoreCase or core.sparseCheckout true, or one of them unreadable`. Evidence (code): `[[ "$rc" -le 1 ]] || { CHECKOUT_WHY="${v%% *} could not be read"; return 1; }`, and `ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "Not inside a git repository" >&2; exit 1; }`. Evidence (header): `1 bad usage, not a git repo, no perl or lib/dev-cycle-read.sh, a failed mktemp (--check; no line printed), or no default branch found by name`.

git parses these three keys as booleans when any command starts. So an unreadable value (r3 set each one to `maybe`) makes the first git call fail. `--check` then prints no verdict line, exits 1, and says `Not inside a git repository`. The help promises a `refuse BRIEF: ...; core.X could not be read` line with exit 2. An orchestrator built from the header (U3/U4) would treat this exit 1 as "not a repo / bad usage", so the wrong remedy follows. The run still fails safe, because nothing merges. The misleading exit 1 predates U2b2, since any git call would fail the same way. U2b2's help line is what newly promises otherwise.

**Recommendation:** Drop `or one of them unreadable` from the help, or replace it with "an unreadable value stops every git call, so the run exits 1 before any brief is read". The branch can stay as defense in depth. Rewording the `Not inside a git repository` message is optional and outside this unit.

#### F2. Three refusals print under a WHY or help clause that names a different cause

**Severity:** Minor
**Location:** `scripts/build-loop.sh:649-652` (index-bits count), `:639` (HEAD), `:666, :678` (tree record), `:126-131` (help)
**Move:** 4 (error consistency)
**Confidence:** High (code; fact-check r1, r2)
**Legibility-target:** for-author

Evidence: `n="$(git ls-files -v -z | tr '\0' '\n' | awk 'substr($0, 1, 2) != "H " { n++ } ...')"`, which then prints `the checkout's index marks entries skip-worktree, assume-unchanged or unmerged`. The help says `a regular file main stores whose name holds a newline, starts with a quote or ends with a CR`. Also `x="unreadable"`, which prints `the checkout's HEAD is unreadable, not the default branch's commit ...`, while the help says only `has its HEAD at another commit`.

- **Newline in a regular file's name.** The NUL-to-newline step splits the record. The second half does not start with `H `, so the index-bits check refuses first and gives the skip-worktree/assume-unchanged/unmerged WHY. The name rule's own WHY, which the help documents for exactly this case, never prints for a newline (r1). A user told their index has flagged entries will look for flags that are not there.
- **Unreadable HEAD** (for example an orphan or unborn branch). It prints the word `unreadable` where the "is X, not Y" shape puts a commit id.
- **Unparseable tree record.** It prints `the default branch's tree could not be read`, which the help covers only as "a listing ... that fails".

The refusals themselves are correct. The WHYs or help mislead.

**Recommendation:** Count the index flags without splitting on newlines (for example, read the `-z` records directly), so that a newline name reaches the name rule. Alternatively, say in the help that it is refused under the index reason. For HEAD, add an own WHY (`the checkout's HEAD could not be read`) or add "(or unreadable)" to the help clause. "Starts with a quote" should say "a double quote" (r2).

#### F3. Parsers are told some WHYs under the fixed prefix are read failures, but not how to recognise them

**Severity:** Informational
**Location:** `scripts/build-loop.sh:115-117` (help), CHECKOUT_WHY assignments `:645-689`
**Move:** 4 (error consistency), 3 (consumer contract)
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

Evidence: `the text up to "; " is fixed, but a WHY naming a read failure is not one a clean checkout cures`. The read-failure WHYs are `... could not be listed`, `... could not be read`, `... could not be hashed`, `git status failed or warned in the checkout` and `the checkout's HEAD is unreadable, ...`.

This closes iteration 2's N2 for a human reader. An orchestrator that wants to route "rerun from a clean main checkout" against "escalate" must still sort free text. Most read failures share `could not be`, but two do not (`failed or warned`, `is unreadable`). Row 530 defers the shape of the verdict chain to U2c, and this point is narrower: a stable marker for the class of WHY.

**Recommendation:** Either give every read failure the `could not be ...` form (`git status could not be run cleanly in the checkout`, `the checkout's HEAD could not be read`) and say in the help that this is the marker, or leave it to U3's parser design and note it in the U3 bullet.

#### F4. The plan's U2b2 bullet states the variable rule without the exemptions the help lists

**Severity:** Informational
**Location:** `docs/working/plan-build-loop-handoff.md:284`
**Move:** 3 (documentation drift)
**Confidence:** High (fact-check r2)
**Legibility-target:** for-author

Evidence: `no repo-local GIT_* variable`. The help says `the caller's GIT_CONFIG_PARAMETERS and GIT_CONFIG_COUNT pairs, GIT_NO_REPLACE_OBJECTS and GIT_PREFIX aside`. The code is `[[ -z "${!v+set}" || "$v" == GIT_PREFIX ]] || callervar "$v"`.

The help and the code agree with each other. The plan is the third copy, and override row 459 already accepts some duplication of the contract. A reader of the plan alone would expect `GIT_CONFIG_COUNT=1 ...` to be refused, but the U2b2 test asserts that it passes.

**Recommendation:** Add "(the caller's config pairs, GIT_NO_REPLACE_OBJECTS and GIT_PREFIX aside)", or point the plan bullet to the help.

## What Looks Good

- The line grammar is untouched: no new line kind, flag or exit code. The checkout refusal is an ordinary `refuse BRIEF: WHY`, and its prefix is declared fixed, which is what a parser needs.
- A loop's advisory run from its own branch still gets every path and deny line. Both the help (N1 fixed) and a test that runs on `feat/x` pin this.
- A review brief is unaffected, as the PR promises. The test "judges a review brief without its checkout" covers a dirty, detached checkout under the review policy.
- Each WHY names its subject. Refusals and read failures are separate for HEAD, config, index, status, listing and hashing, which matches the state gate.
- `callervar` gives `gate_repo` and `checkout_gate` one exemption rule. GIT_CONFIG moved out of the exempt set in both places together, and a test pins it.
- The lib's caller-contract note, the plan's U2b2/U2c bullets and A5 all describe the same placement: run per brief, after the paths are read, before U2c's floor, never over a refused checkout.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---|---|---|---|
| F1 | Help's "or one of them unreadable" can never print; an unreadable core.* value really gives exit 1 "Not inside a git repository", against the Exit contract | Minor | `scripts/build-loop.sh:124-125,643-645,167-170,283` | High |
| F2 | A newline-named file is refused under the index-bits WHY; an unreadable HEAD prints `unreadable` in the commit slot; tree-record failure only implied; "quote" means double quote | Minor | `scripts/build-loop.sh:639,649-652,666,678,126-131` | High |
| F3 | No stable marker separates the read-failure WHYs under the fixed prefix from the checkout-state WHYs | Informational | `scripts/build-loop.sh:115-117,645-689` | Medium |
| F4 | Plan says "no repo-local GIT_* variable" without the exemptions | Informational | `docs/working/plan-build-loop-handoff.md:284` | High |

## Overall Assessment

The branch fits `--check`'s conventions. It keeps the verdict, path and deny grammar and the exit codes. It adds one refusal with a declared-fixed prefix and per-cause WHYs in the existing style. Both iteration-2 Minors (N1, N2) are fixed in the help. What remains is narrower and does not block a merge: one documented refusal that cannot happen and actually ends as exit 1 (F1), and three cases where the printed or documented reason names the wrong cause (F2). Both are fixable in place with a help edit or a small change to the newline handling. Every case fails safe, and no consumer is built yet. F3 and F4 are wording or forward notes for U3.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to /workspace/.claude/wt-build-loop-u2b2/docs/reviews/api-consistency-reviewer-review-2026-10-08-build-loop-u2b2-final.md (first line `Commit: 1f4f7a21`), structured per the critic skill.
- Answered: yes. I read the whole branch fresh against the full `--check` help and Exit line. Each iteration-2 finding has its status. The new names are audited, and the results U3/U4 will parse (verdict line, prefix, WHYs, exit codes) are traced against the help.
- Out of scope: the check_line comment "at most the slot count" (cost, for performance); bypassability (security); the verdict-chain shape (override row 530, deferred to U2c); the single numbered contract (rows 459/465).
- Escalate: none. F1 and F2 are author fixes in the help text or one pipeline.
- Decisions I made: I ran no probe. F1 rests on fact-check r3's executed P3, and F2's newline case follows directly from the `tr '\0' '\n' | awk` pipeline (r1 agrees). I rated F1 Minor, not Inconsistent, because it fails safe and its exit-1 misdiagnosis predates U2b2. I rated F2 Minor because a misattributed WHY sends a user to the wrong fix even though the refusal is correct.
