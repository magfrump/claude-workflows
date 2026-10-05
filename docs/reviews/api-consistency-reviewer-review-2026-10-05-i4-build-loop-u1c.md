Commit: 13380172

# API Consistency Review — feat/build-loop-u1c, iteration 4 (fix commit 13380172)

**Scope:** 32bef87b..13380172 (scripts/build-loop.sh, test/scripts/build-loop-read.bats, docs/reviews/override-log.md); public surface = `scripts/build-loop.sh --help` header (:1-78) and the `--status` / `--settings` output lines U2-U4 parse
**Date:** 2026-10-05
**Based on:** docs/reviews/code-fact-check-report-build-loop-u1c.md (Stage 1, k=1)

## Baseline Conventions

- **Output line shape.** `--status` prints `ok BRIEF ...` or `skip BRIEF: WHY`; `--settings` prints `<key> <state>...: WHY`. Consumers key on the first word and the `BRIEF:` prefix; WHY is prose for a human (build-loop.sh:46, :64; lib check_brief :321-360).
- **Help enumerates every skip cause.** The `skip BRIEF: WHY` paragraph (build-loop.sh:64-71) is a closed list, "X, Y, ..., or Z". When F31's same-branch skip was added it got its own clause (:68-69). The lib's skip reasons are summarised the same way by dev-cycle.sh's help.
- **Failure-to-read wording.** A failed git read says "... could not be read" plus "the default branch": `the tree of the default branch could not be read` (lib :337), `the brief could not be read from the default branch` (lib :343), `$f could not be read from the default branch` (lib :562).
- **Parenthesised mechanism.** Siblings explain why in a trailing parenthesis: `(compared ignoring case)` (:337), `(narrow the glob)` (dev-cycle.sh:151), `(questions.sh archive splits entries there)` (lib :568).
- **Help and message say the same thing.** `--settings` help :34-35 says `before the next constraint or "#" heading`.

## Name-Pattern Audit

The commit adds no flags, modes, functions in the lib, or output keywords. Its new public strings are one skip reason and one changed `--settings` message.

| New / changed string | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `skip BRIEF: the open briefs on the default branch could not be listed (git grep failed)` | skip reason | `the tree of the default branch could not be read`; `the brief could not be read from the default branch`; `another open brief on the default branch names the same branch (compared ignoring case)` | `scripts/lib/dev-cycle-read.sh:337,343,562`; `scripts/build-loop.sh:337` | Consistent wording ("could not be ...", "the default branch", trailing parenthesis). It is **not documented in the help**: see F1. |
| `constraints unreadable: ... before the next constraint or "#" heading` | settings WHY | help `before the next constraint or "#" heading` | `scripts/build-loop.sh:34-35` | Consistent. C32 is closed: message, help, and all three test assertions (bats :169, :184, :186) match. |
| `SHARED_BRANCHES=error` sentinel | internal global | `BRIEF_ODD=error`, `FILE_WHY` | `scripts/lib/dev-cycle-read.sh:283-286` | Consistent ("error" sentinel in a global). Not public. A lower-cased branch can't collide with it, because the set is always newline-delimited (`$'\n'...`) and the match is `*$'\n'name$'\n'*`. |

## Findings

#### F1. The new skip reason is missing from the help's closed list of skip causes

**Severity:** Minor
**Location:** `scripts/build-loop.sh:64-71` (help), `scripts/build-loop.sh:335` (code)
**Move:** 3 (consumer contract: documentation drift)
**Confidence:** High
**Legibility-target:** for-author

Evidence:
```
64: #             skip BRIEF: WHY
65: #                 The brief cannot be read (as --check-brief), its Branch:
66: #                 line is missing or malformed or its Dispatched: line
67: #                 malformed, its branch name is refused (as --check-branch),
68: #                 for an open brief, another open brief on main (in briefs/ or
69: #                 closed/) names the same branch (ignoring case), or the tip's subject (its
70: #                 message's first line) starts "handoff:" but it is not a
71: #                 marker.
...
335:   if [[ "$st" == open && "$SHARED_BRANCHES" == error ]]; then echo "skip $a: the open briefs on the default branch could not be listed (git grep failed)"; return; fi
```

The help lists every cause as a closed "X, ..., or Z" set. When F31's same-branch skip was added, it got a clause (:68-69), which is the precedent. The new fail-closed skip has none. A reader of `--help`, such as U2-U4's author or the orchestrator's prompt, would not know that every open brief can skip together when the listing fails. The line shape (`skip BRIEF: WHY`) is unchanged, so parsers still work. That makes this documentation drift, not a breaking change. The comment at :304-306 states the rule, but it is not in the help. No 2026-10-05 override row covers it. It is new in this commit.

**Recommendation:** Extend the "for an open brief" clause at :68-69. For example: "for an open brief, another open brief on main (in briefs/ or closed/) names the same branch (ignoring case), or the open briefs on main could not be listed".

#### F2. A22's new sentence contradicts the unchanged skip clause for a level-with-main tip

**Severity:** Minor
**Location:** `scripts/build-loop.sh:61-62` vs `:69-71`
**Move:** 7 (asymmetry within the documented contract)
**Confidence:** High (the code at :346 calls marker_kind only when `ahead -gt 0`. Fact-check Claim 2 agrees.)
**Legibility-target:** for-author

Evidence:
```
61: #                 printed last. A tip on a branch level with main, or whose
62: #                 subject does not start "handoff:", is working. ...
69: #                 ... or the tip's subject (its
70: #                 message's first line) starts "handoff:" but it is not a
71: #                 marker.
346:   if [[ "$ahead" -gt 0 ]]; then
347:     kind="$(marker_kind "$sha")"
```

Take a tip on a branch level with main whose subject is, say, `handoff: junk`. The `ok` paragraph (:61-62) now says it is `working`, which is what the code prints. The `skip` paragraph (:69-71) says it skips, because its subject starts "handoff:" and it is not a marker (by :55-56 a 0-ahead tip is never a marker). A22 fixed one half of the help and left the other half saying the opposite. A consumer reading the skip clause alone would expect `skip` and would mis-model the case. This is the same class of issue as iteration 3's A22, and it is only half fixed, so no override row settles it.

Separately, and Informational only: the A22 edit left :62 at 115 columns. The header wraps at about 80 elsewhere, and main already has some long header lines, so this is no convention breach.

**Recommendation:** Change :69 to "or the tip of a branch ahead of main has a subject (its message's first line) that starts "handoff:" but is not a marker", as fact-check Claim 2 suggests. Rewrap :61-62.

#### F3. The trailing parenthesis names the tool, not the condition

**Severity:** Informational
**Location:** `scripts/build-loop.sh:335`
**Move:** 4 (error message consistency)
**Confidence:** Medium
**Legibility-target:** for-author

Evidence: `... could not be listed (git grep failed)`. Siblings' parentheses either tell the reader what to do or explain the rule: `(narrow the glob)` at dev-cycle.sh:151, `(compared ignoring case)` at build-loop.sh:337. The lib's read failures don't name the git command: `the tree of the default branch could not be read` (lib :337). Here, "(git grep failed)" is accurate and does help a human debugging. But it adds an implementation detail to a reason U2's `--check` may reuse once enumeration moves into the lib (A21's override row: U2). The reason would then have to change when the mechanism changes. Fact-check Claim 6 also notes that "failed" means exit status above 1 only. A missing blob exits 0 and is just not counted.

**Recommendation:** None required. If U2 moves enumeration into the lib, consider "... could not be listed, so none is dispatched", which states the consequence and matches "so the brief is not read" (lib :342).

## What Looks Good

- **C32:** the nosuccess message now matches help :34-35 word for word, and every test assertion was updated in step. Verified at bats :169, :184, :186 and by grep: no other copy of the old "or heading" wording remains in scripts, tests or docs. `route: code-fact-check`
- **A23:** the SC2034 comment `# NEVER: for the planned gate` is now accurate. POLICY is read at :334, so it never needed the suppression. NEVER is only assigned (:201, :206, :242). `shellcheck -x scripts/build-loop.sh` exits 0 at 13380172. `route: code-fact-check`
- **The fail-closed skip is scoped like its sibling.** It applies only when `st == open`, as the same-branch skip at :336 does. It comes after the Branch:/Dispatched: validation, so a malformed brief still reports its own more specific reason. A done or dropped brief still prints `ok` (T28 :388-389 asserts `ok $c done`). That matches the help's "for an open brief" qualifier. `route: code-fact-check`
- **C29:** `local -A BRIEF=()` in shared_branches keeps the caller's BRIEF intact. The "first:" ordering comment at :320 could then be dropped, which removes a hidden call-order contract from status_line. Fact-check Claim 9 notes that no test kills a revert of this. That is a test-gap matter, not an API one.
- No flag, mode, exit code or output-line shape changed. Existing consumers of `ok ...` and `skip BRIEF: ...` are unaffected.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| F1 | New skip reason missing from help's closed list of skip causes | Minor | `scripts/build-loop.sh:64-71`, `:335` | High |
| F2 | A22's :61-62 "level with main ... is working" contradicts the unchanged skip clause :69-71 | Minor | `scripts/build-loop.sh:61-62`, `:69-71` | High |
| F3 | "(git grep failed)" names the mechanism, unlike sibling parentheses | Informational | `scripts/build-loop.sh:335` | Medium |

## Overall Assessment

The commit is consistent with build-loop.sh's and the lib's output conventions. The new skip reason uses the established "could not be ... the default branch" wording and the `skip BRIEF: WHY` shape, and C32/A23 close cleanly. Both remaining issues are help-text drift in the surface U2-U4 will read. The help's closed list of skip causes omits the new fail-closed cause (F1). A22's fix updated the `ok` paragraph but not the matching `skip` clause, so the help now says two things about a level-with-main "handoff:" tip (F2). Neither changes output shape or breaks a parser. Both can be fixed in place with one-line help edits, or deferred to U1d alongside the other wording deferrals.

## Goal-Alignment Note

**Success criterion (verbatim):** A markdown report saved at the path named in your tail, structured per your skill, with a `Commit: 13380172` first line.

**Status:** Met. The report is saved at docs/reviews/api-consistency-reviewer-review-2026-10-05-i4-build-loop-u1c.md with first line `Commit: 13380172` and the skill's sections: header, Baseline Conventions, Name-Pattern Audit, Findings, What Looks Good, Summary Table, Overall Assessment. Scope was held to 32bef87b..13380172. No other repo file was edited, nothing was committed, and no probe files were created: only read-only greps and shellcheck were run, so the scratch dir was not needed.
