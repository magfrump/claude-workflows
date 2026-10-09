Commit: a382a3f8

# API Consistency Review — feat/build-loop-u2b1b (iteration 2, fix range)

**Scope:** `git diff 809df345..a382a3f8` (the iteration-1 fix commit): `scripts/build-loop.sh`, `scripts/lib/dev-cycle-read.sh` (header item 5), `test/scripts/build-loop-check.bats`, plan step 13. Context read: the rest of the branch, iteration 1's api review and rubric (C4, C5, A4), the override log's U2b1b rows.
**Date:** 2026-10-08
**Based on:** Stage 1 summary `scratchpad/u2b1b-i2/factcheck-summary.md` and `docs/reviews/code-fact-check-report-build-loop-u2b1b-i2.md` (30 claims, 0 Incorrect)
**Public surface:** `build-loop.sh --check`'s verdict, path/deny and state lines, its exit status and help text (`scripts/build-loop.sh:83-134`), and the plan's interface line for `--state` (`docs/working/plan-build-loop-handoff.md:207`).

## Baseline Conventions

The same as iteration 1, re-checked against HEAD:

- **Line shape.** The first word is the line type. Fixed fields come before any colon (`ok BRIEF TIP TREE`, `path BRIEF S PATH`), and prose for humans comes after `WORD ARG:` (`refuse`, `skip`, `deny`, `refuse state WHAT:`).
- **Ids in prose.** Some refuse reasons already put an id after the colon: `refuse $a: the tip of $br is $sha, not the expected $EXPECT` (`scripts/build-loop.sh:586`).
- **Refuse-reason subject.** Every other per-brief refusal about the merge names the branch: "the merge of $br could not be computed" (`:591`), "the paths the merge of $br changes could not be listed/read/lower-cased" (`:596`, `:600`, `:605`, `:614`), and "$br conflicts with the default branch" (`:590`).
- **State lines.** `refuse state WHAT: WHY`, one per finding, every finding printed before exit 2 (`state_gate`, `:212-235`).
- **Glob/path-form wording.** `--settings`' help gives the full rule: "letters, digits, . _ - / * ? ... has no empty, . or .. part, does not start with / or -" (`:28-31`). The lib states pathform as "no component starting .git (any case)" (`scripts/lib/dev-cycle-read.sh`, the comment above `NAMECHARS`, `:172-183`).

## Iteration-1 findings: verification

| Iteration 1 | Claimed fix | Verdict | Evidence |
|---|---|---|---|
| api 1: the K-of-N refusal drops TIP and TREE | "... refused in the merge of TIP (tree TREE)" | **Fixed** | `:620` `echo "refuse $a: $nd of ${#ps[@]} changed paths refused in the merge of $sha (tree $tree)"`. Help `:109-110` matches. The test helper `nref` (`build-loop-check.bats`, beside `NBRIEF`) pins the full line with `$(git rev-parse feat/x)` and `$(git merge-tree --write-tree main feat/x)` in T14, T12, T13 and the own-brief test. The ids sit after the colon, which follows the `:586` precedent, so a reader quoting the output (D4/F48) gets TIP and TREE. U3's field-level need is already deferred (override row for architecture 3). |
| api 2: default-branch findings stop at the first, sit outside the state gate, and are missing from the planned `--state` | `default_gate` beside `state_gate`, printing every finding | **Fixed in code; plan line not amended** (Finding 2) | `:240-251` accumulates `bad=1` and `return "$bad"`, as `state_gate` does. Probed: with `refs/heads/master` written by hand to a blob id and origin/HEAD set to origin/master, `--check` printed both lines, `refuse state default-branch: both main and master exist` and `refuse state default-branch: origin/HEAD names origin/master, but the default branch taken is main`, then exit 2. The two findings can co-occur only when a ref is not a commit (resolve_main skips it but `show-ref --verify` accepts it), which is why no honest-path test shows both. The comment at `:236` says "U3b's --state calls both", but plan `:207` still names only `state_gate`. The optional single WHAT for origin/HEAD was not taken: `:231` uses `origin/HEAD`, `:247` uses `default-branch`. My iteration-1 report offered it only as optional, so it is not re-flagged. |
| api 3: path-form and mode deny reasons misdescribe their rules | reworded | **Fixed** | `:555` now lists the leading `-`/`/` and empty/`.`/`..` rules, and `-x.md` (T13) is explained by "no leading -". `:556` no longer says "on both sides", which matches an absent side passing. The test constants `NFORM` and `NMODE` were updated. The wording still drifts from the help and the lib in small ways (Findings 1, 3). |

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `refuse BRIEF: K of N changed paths refused in the merge of TIP (tree TREE)` | verdict variant | `refuse BRIEF: the tip of BR is SHA, not the expected X`, `ok BRIEF TIP TREE` | `scripts/build-loop.sh:586`, `:620` | Consistent: ids in prose have the `:586` precedent, and TIP comes before TREE as in `ok`. Its subject differs from the sibling reasons (Finding 4). |
| `refuse BRIEF: the merge of BR names a file the object store lacks` | refuse reason | `the merge of BR could not be computed`, `the paths the merge of BR changes could not be listed` | `:591`, `:596` | Consistent subject ("the merge of $br"). The noun differs from the help's (Finding 3). |
| `default_gate` | internal helper | `state_gate`, `gate_repo`, `gate_git` | `:212`, `:240` | Consistent: `<noun>_gate`, the same print-and-return contract as `state_gate`. Not public. |
| deny WHY `a symlink, gitlink or other non-file entry on one side (...)` | deny reason | the help's "on either side (a symlink or gitlink)" | `:122`, `:556` | Consistent in substance. "on one side" vs the help's "on either side" is a wording nuance, Informational only (folded into Finding 3). |
| deny WHY `not an allowed path form (...; no part starting .git)` | deny reason | `--settings` glob rule, lib pathform comment | `:28-31`; `scripts/lib/dev-cycle-read.sh:172` | Matches `--settings`' structure. The help's deny paragraph lags it (Finding 1). |
| `nref` | test helper | `has`, `chk`, `onx`, `gated` | `test/scripts/build-loop-check.bats:1444-1450` | Consistent short lower-case helper. |

## Findings

#### 1. The help's deny paragraph still says "a .git part", while the deny reason and pathform refuse any part *starting* .git

**Severity:** Minor
**Location:** `scripts/build-loop.sh:120-121` (help); reason at `:555`
**Move:** 3 (documentation drift), 4 (error consistency)
**Confidence:** High
**Legibility-target:** the help's `deny BRIEF S PATH: WHY` paragraph, the reference a user reads to understand why `.github/w.yml` was denied

Evidence (help):
```
#                 The N rules, under either policy: a path pathform refuses
#                 (a .git part included); a mode other than 100644 or 100755
```
and the reworded reason (`nrules`, `:552-567`):
```
  if ! pathform "$6"; then DENY="not an allowed path form (letters, digits and . _ - / only; no leading - or /; no empty, . or .. part; no part starting .git)"
```
pathform (`scripts/lib/dev-cycle-read.sh`, the function after `NAMECHARS`): `[[ ... "$c" != [.][gG][iI][tT]* ]] || return 1`.

The fix made the deny reason the complete statement, but the help it sits under still describes the narrower rule. cc9b69d3's Notes call out that "pathform as an N rule refuses `.github/` and `.gitattributes` changes under review". Those paths have a part *starting* .git, not a `.git` part, so a reader of the help will not expect T13's `deny ... .github/w.yml`. Neither string says the match ignores case (`.GITHUB/` is refused too), though the lib comment says "(any case)". This is honest-path wording with no consumer break.

**Recommendation:** In the help, write "(any part starting .git, in any case, included)" or reuse the reason's parenthesis. Optionally add "(any case)" to the reason.

#### 2. Plan `--state` still names only `state_gate`; `default_gate`'s role in U3b's `--state` lives only in a code comment

**Severity:** Minor
**Location:** `docs/working/plan-build-loop-handoff.md:207`; `scripts/build-loop.sh:236`
**Move:** 3 (consumer contract: the planned interface)
**Confidence:** High
**Legibility-target:** plan interface line `:207`, which U3b will be built to

Evidence (plan, unchanged by a382a3f8):
```
- `--state` → `ok`, or `refuse state WHAT: WHY` for each planted `.git` state the gate refuses (exit 2), as `--check` prints them (U2b1a's `state_gate`).
```
and the code comment (`default_gate`, `:236-251`):
```
# The state gate's second half, once resolve_main has run (U3b's --state calls
# both): the default branch counts only when no other name could claim it. A
```
Iteration 1's finding 2(c) was that a `--state` built to `:207` passes a repo that `--check` refuses. Rubric C5 records it as fixed "beside state_gate for U3b's --state". The function now exists, but the planned interface still points U3b at `state_gate` alone, so the fix relies on the U3b builder reading a comment in the script rather than the plan. T42 (`:353`) also lists only `state_gate` cases.

**Recommendation:** Amend `:207` to "(`state_gate`, then `default_gate` once the default branch is resolved)" and add an ambiguous-default-branch case to T42.

#### 3. The new missing-blob refusal and its help sentence use different nouns, and the help files it under "could not be computed"

**Severity:** Minor
**Location:** `scripts/build-loop.sh:611` (message), `:105-109` (help)
**Move:** 4 (error consistency), 3 (documentation)
**Confidence:** Medium
**Legibility-target:** the help's `refuse BRIEF: WHY` paragraph and the refusal string a merge entry quotes

Evidence (message, in `check_line`, `:575-622`; the check at `:609-612`):
```
    echo "refuse $a: the merge of $br names a file the object store lacks"; return
```
help:
```
#                 or the merge (or its changed paths) could not be computed:
#                 git failed, or warned on stderr (a missing tree object), or
#                 the tree of main, TIP or a merge base is missing; or a file
#                 the merge adds or changes names a blob the object store
#                 lacks. Or "K of N changed paths refused in the merge of TIP
```
In the help, the *file* names a *blob* the store lacks, which is accurate. The message says the merge names a *file* the store lacks, which states the store holds files. The help's punctuation also places the case after "could not be computed:", but the printed line is its own reason, not "could not be computed", so a reader matching help to output looks under the wrong heading. The subject "the merge of $br" matches its siblings (`:591`, `:596`). Fact-check item 5 confirms the scope "adds or changes" (every new regular file, including a T to a file). The deny mode reason's "on one side" vs the help's "on either side" (`:556` vs `:122`) is the same kind of small help/reason drift; that part is Informational.

**Recommendation:** Print "the merge of $br names a file whose blob the object store lacks" (or "... a blob the object store lacks"). In the help, end the "could not be computed" list with a full stop and give the missing-blob case its own sentence.

#### 4. "the merge of X" now names a commit id on the K-of-N line and a branch on every other refusal

**Severity:** Informational
**Location:** `scripts/build-loop.sh:620` vs `:591`, `:596`, `:600`, `:605`, `:611`, `:614`
**Move:** 2 (naming), 7 (asymmetry)
**Confidence:** Medium
**Legibility-target:** the refuse-reason family a human scans in a merge entry

Precedent: refuse reasons say "the merge of $br" with the branch name, used in `scripts/build-loop.sh:591-614`.

Evidence:
```
    *) echo "refuse $a: the merge of $br could not be computed"; return ;;
...
  if [[ "$nd" -eq 0 ]]; then echo "ok $a $sha $tree"; else echo "refuse $a: $nd of ${#ps[@]} changed paths refused in the merge of $sha (tree $tree)"; fi
```
The same phrase takes a branch name in six reasons and a 40/64-hex id in one. The K-of-N line is also the only merge refusal that no longer names the branch. This is deliberate (D4 pins TIP, and the branch is on `--status`'s line), and the `:586` reason already puts both into prose ("the tip of $br is $sha"). The cost is only that a person grepping an entry for "the merge of feat/x" misses the K-of-N line. Under the precedent rule this naming observation stays Informational.

**Recommendation:** Optional: "... refused in the merge of $br at $sha (tree $tree)" keeps both. Otherwise leave as is.

## What Looks Good

- **api 1 is closed the way the codebase already does it.** TIP and TREE appear in the refusing verdict, in `ok`'s order, using the `:586` ids-in-prose precedent. Every refusing-verdict assertion goes through one `nref` helper that computes TIP and TREE independently with `git rev-parse` and `git merge-tree`, so the line is pinned exactly in four tests.
- **`default_gate` matches `state_gate`'s contract.** Same `refuse state WHAT: WHY` shape, accumulating `bad`, `return "$bad"`, and a `|| exit 2` call site parallel to `state_gate`'s (`:256`, `:259`). It also has a name U3b's `--state` can call. The exit status and one-line-per-finding behaviour match the help's "Each finding prints" (`:90`).
- **The deny reasons now explain T13's `-x.md`**, and the mode reason no longer contradicts the add/delete case. Both stay fixed strings, so exact matching still works.
- **The missing-blob refusal follows the single-line refusal convention.** No path lines follow it, as the help states for every refusal other than K of N. It names the branch like its siblings and exits 2 through the unchanged verdict-line test.
- **Lib header item 5** (`scripts/lib/dev-cycle-read.sh:59-65`) now gives the caller ordering build-loop.sh actually uses (pathform before floor under both policies). This fixes a contract-doc drift for the next caller.
- **Exit status and line order are unchanged.** The verdict line still comes first, and `path`/`deny` lines follow in diff-tree order (T14 still pins `lines[1]` and the last line).

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Help deny paragraph says "a .git part"; reason and pathform refuse any part starting .git (any case) | Minor | `scripts/build-loop.sh:120-121` | High |
| 2 | Plan `--state` line names only `state_gate`; `default_gate` is in a code comment only | Minor | `docs/working/plan-build-loop-handoff.md:207` | High |
| 3 | Missing-blob refusal says "a file the object store lacks" (help: a blob), filed under "could not be computed" in the help | Minor | `scripts/build-loop.sh:611`, `:105-109` | Medium |
| 4 | "the merge of X" takes a commit id on the K-of-N line, a branch elsewhere | Informational | `scripts/build-loop.sh:620` | Medium |

## Overall Assessment

The three iteration-1 api findings are fixed in code. The refusing verdict carries TIP and TREE in a form the codebase already uses, `default_gate` prints every finding with `state_gate`'s contract (probed with both findings at once), and the deny reasons now describe their rules. What remains is wording drift between the strings and the reference text around them: the help's deny paragraph and the new missing-blob sentence trail the code, and the plan's `--state` line was not updated to name `default_gate`. All of this is honest-path legibility with no consumer break, since nothing calls `--check` until U3. Each item is a one-line text edit.

## Goal-Alignment Note

The goal is to land U2b1b after a clean review-fix loop. From the API side the fix commit is landable: no Breaking or Inconsistent findings, three Minor and one Informational, all text-only. Finding 2 is worth fixing before landing because it is the only one that steers later work: U3b builds `--state` from plan `:207`, and without the amendment the C5 fix depends on a code comment being read.
