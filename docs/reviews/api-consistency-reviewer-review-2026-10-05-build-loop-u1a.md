Commit: 2da477b7

# API Consistency Review: feat/build-loop-u1a (iteration 2)

**Scope:** `git diff main...feat/build-loop-u1a` over scripts/lib/dev-cycle-read.sh, scripts/dev-cycle.sh, skills/dev-cycle/SKILL.md, test/scripts/dev-cycle.bats (HEAD 2da477b7)
**Date:** 2026-10-05
**Based on:** Stage-1 merged fact-check summary (k=3), docs/reviews/code-fact-check-report-build-loop-u1a.md

## Baseline Conventions

Surveyed on main and the branch: `check_brief`, `check_branch`, `check_answer`, `blocker`, `skipped`, `oddwhy`, `resolve_main`/`main_by_name`, `imported_names` (scripts/lib/dev-cycle-read.sh), and dev-cycle.sh's `--check-*` help block (:20-80).

- **Function names:** lower snake_case. A `main_` prefix marks default-branch helpers (`main_by_name`). Plural nouns name readers that collect data (`imported_names`). `check_*` names the per-argument answerers.
- **Output vocabulary:** one line per answer. Positive answers start with `ok` or a state word, and refusals with `skip <arg>: <reason>`. Internal tokens are short, lowercase and name the condition, with an optional argument: FENCE_AWK END prints `odd N WHY` / `unbalanced N`, ANSWER_AWK prints `dup` / `quoted N` / `open` / `unrecognized`, and check_branch prints `absent <name>`.
- **Globals:** UPPERCASE, in base plus `_SUFFIX` pairs (`SKIPPED`/`SKIP_AT`, `IMPORTED`/`IMPORTED_DONE`, `MAIN`/`MAIN_SHA`/`MAIN_BY_NAME`). Bash 4 associative arrays are already in use (`declare -A last_date` at scripts/dev-cycle.sh:277, `declare -gA` at scripts/lib/si-morning-summary.sh:1226).
- **oddwhy reasons:** short lowercase codes (`fence`, `comment`, `refdef`, `cr`, `bom`) mapped to a "holds/starts/opens …" clause.
- **Error handling:** a lib function that cannot judge an input prints a `skip` line. It never exits non-zero for a per-argument condition. The CLI exits 1 only for usage errors or a missing default branch, and the skill (SKILL.md:100-101) records a non-zero check and stops the step.
- **Platform baseline:** the lib already depends on GNU coreutils `realpath -e` (:96, :99) and `realpath -ms --relative-to` (:441), and on bash ≥4. The only awk-dialect comment in the code targets mawk (scripts/dev-cycle.sh:443: "mawk, Debian's default awk, lacks them"). README documents no supported platform for dev-cycle.sh.

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `main_entry` | function | `main_by_name`, `resolve_main`, `blocker` | scripts/lib/dev-cycle-read.sh:246, :376, :107 | Consistent: `main_` prefix for default-branch helpers; answers on stdout like `blocker` |
| `blob` / `absent` / `notfile` / `notdir PART` | output tokens | `absent <name>` (check_branch), `odd N WHY`, `quoted N` | scripts/lib/dev-cycle-read.sh:368, FENCE_AWK END, ANSWER_AWK END | Consistent: `absent` reuses check_branch's word; `notdir PART` follows the token-plus-argument shape |
| `error` (main_entry) | output token | `dup`, `unbalanced`, `odd` | scripts/lib/dev-cycle-read.sh FENCE_AWK/ANSWER_AWK END blocks | New category: the first token for "git failed" (all others name a property of the input). Acceptable; both callers map it to a distinct skip line |
| `brief_fields` | function | `imported_names`, `check_brief`, `oddwhy` | scripts/lib/dev-cycle-read.sh:418, :309 | Consistent: plural noun for a collecting reader, as `imported_names` |
| `BRIEF` / `BRIEF_ODD` | globals | `SKIPPED`/`SKIP_AT`, `IMPORTED`/`IMPORTED_DONE` | scripts/lib/dev-cycle-read.sh:125, :415 | Consistent: base plus `_SUFFIX` pair; `declare -gA` as si-morning-summary.sh:1226 |
| `BRIEF[status]` … `BRIEF[dispatched]` (values are the whole line, key prefix included) | fields | check_brief's old `st` held `Status: open` whole, stripped by `${st#Status: }` | main:scripts/lib/dev-cycle-read.sh check_brief | Consistent with the old whole-line capture; U1b consumers must strip the prefix themselves (documented: "The callers judge the values") |
| `nul` → "holds a NUL byte" | oddwhy reason | `cr` → "holds a carriage return that does not end it", `bom` | scripts/lib/dev-cycle-read.sh:236-238 | Consistent |
| check_brief `skip …: PART is not a directory on the default branch` / `…: the default branch's tree could not be read` | skip lines | `skip $a: not a regular file on the default branch` | scripts/lib/dev-cycle-read.sh:326 | Consistent: same "on the default branch" phrasing; no "so the brief is not read" suffix, as the sibling lines have none |
| check_answer `…, so $f is not read` (notdir, error) vs `…, so no entry in it is read` (notfile) | skip lines | main's `$SKIP_AT is not a plain file or directory, so $f is not read`; `…, so no entry in $f is read` (odd/unbalanced/quoted) | main:scripts/lib/dev-cycle-read.sh check_answer; scripts/lib/dev-cycle-read.sh:551-553 | Consistent: each suffix has a precedent (path-blocked lines vs content-refused lines) |
| `--check-answer` needs a default branch found by name (exit 1) | CLI contract | `--check-brief`, `--check-branch` | scripts/dev-cycle.sh:187-193 | Consistent: same gate, same stderr message, help and Exit line updated |

## Findings

#### 1. brief_fields reports a failed blob read as "no machine lines" when called as documented

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:281-300` (read at :286)
**Move:** 8 (nullability contract), 4 (error consistency)
**Confidence:** High (executed)
**Legibility-target:** for-author

**Evidence:**
```
  out="$(git cat-file blob "$MAIN_SHA:$1" | env LC_ALL=C awk "$FENCE_AWK"'
```
```
# BRIEF[status], BRIEF[branch], ... (a key with no such line stays unset) and empties
# BRIEF_ODD. A file FENCE_AWK refuses sets no key and returns 1,
```
(excerpt; enclosing brief_fields() continues to :300, read)

This diff gives main_entry an explicit `error` token so that a failed git read is never taken as `absent` (A2). brief_fields has no matching channel. The lib's own call pattern is `if ! brief_fields "$a"` (:328), and set -e is off in that context. A failing `git cat-file` there returns 0 with no keys set and `BRIEF_ODD` empty, which looks the same as a readable brief that has no Status/Branch/… lines. Called outside an `if`, the same failure exits the caller (128). So one condition gets two different outcomes depending on call context, and the lib's other readers (main_entry, check_*) give it a named outcome. The documented precondition (main_entry printed `blob`) means this cannot happen for check_brief today. The gap is in the contract that U1b's consumers will code against. (Fact-check Escalation #3, addressed to security-reviewer, covers the exploit side; this finding covers only the contract asymmetry.)

Verification (scratch repo, run): `if ! brief_fields docs/working/briefs/nope.md; then …; else echo "rc=0 keys=${#BRIEF[@]} odd=[$BRIEF_ODD]"; fi` prints `rc=0 keys=0 odd=[]`. The same call outside `if` exits 128.

**Recommendation:** Give the read failure its own BRIEF_ODD value (e.g. capture cat-file's status separately and set `BRIEF_ODD="error"`, return 1), mirroring main_entry. Or state in the header that a call before main_entry printed `blob` is undefined and may read as an empty brief.

#### 2. --check-answer help lists every skip reason but the new tree-read error

**Severity:** Minor
**Location:** `scripts/dev-cycle.sh:62-70`
**Move:** 3 (documentation drift)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**
```
#             <reason>" when it cannot be read (no such entry, a duplicate
```
```
#             inside a fence, a questions file that is not a regular file
#             under plain directories on the default branch).
```
versus `scripts/lib/dev-cycle-read.sh:544`:
```
      error) echo "skip $a: the default branch's tree could not be read, so $f is not read"; return ;;
```

The --check-answer help reads as a closed list of skip reasons, and it was updated for notfile/notdir and NUL. The new `error` skip is missing from it. The --check-brief help says "including …", so its list is open, and check_brief's new `notdir`/`error` lines are covered there. Consumers treat any skip as a skip (SKILL.md:303-305), so no caller breaks. The help is the published contract for the CLI, though.

**Recommendation:** Append "or a tree on the default branch that could not be read" to the --check-answer list (and consider naming it in --check-brief's for symmetry).

#### 3. `"\0"` in FENCE_AWK assumes an awk whose strings can hold NUL (Escalation #1)

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:216`
**Move:** 1 (baseline: platform contract), 4 (error consistency of the skip line)
**Confidence:** Medium (mawk behaviour executed by Stage 1; the behaviour of other awks is reasoned from source, not run: gawk, busybox and one-true-awk are not installed here, and /usr/bin/nawk resolves to mawk)
**Legibility-target:** for-orchestrator-synthesis

**Evidence:**
```
  if (index(l, "\0")) { refuse("nul"); return 1 }  # $(...) drops NUL, so a printed line would not be the line read
```

Is the lib expected to run under other awks? Nothing in the repo says so. README and install.sh document no supported platform for dev-cycle.sh. The lib already requires GNU `realpath -e` (:96, :99) and `realpath -ms --relative-to` (:441), which stock macOS/BSD lacks, so it does not run on the platforms where a C-string awk (BWK/one-true-awk on macOS, busybox) is the default. The one dialect the code is written against is mawk (dev-cycle.sh:443). gawk keeps `"\0"` as one byte. So on every platform the lib can run on today, the check behaves as Stage 1 verified.

The residual risk is how the failure shows up, not that it fails. In an awk where `"\0"` lexes to `""`, `index(l, "")` is non-zero for every non-empty line (BWK's sindex returns 1). Every brief and questions file would then be refused with `line N holds a NUL byte`. That fails closed, as Stage 1 says, but the skip line misstates the cause, and nothing else in the lib makes the user look at the awk.

**Recommendation:** Optional. Add a one-time BEGIN self-check (e.g. `if (length("\0") != 1)` → refuse every file with a distinct oddwhy code such as `awk`, "cannot be read by this awk (no NUL support)"), or at least extend the :216 comment to name the mawk/gawk assumption, as dev-cycle.sh:443 does for intervals. No change is needed for current platforms.

## What Looks Good

- Every new name follows the lib's existing patterns (audit above): `main_` prefix, a plural noun for the collecting reader, `BRIEF`/`BRIEF_ODD` as a base/suffix global pair, and the `nul` oddwhy code with its "holds a …" message.
- main_entry's `error` vs `absent` split carries the A2 fix through to both callers with distinct skip lines. Stage 1 verified this by execution (Claim set "A2 fixed"); route: code-fact-check, scripts/lib/dev-cycle-read.sh:259-266, :325, :544.
- The `--check-answer` contract change (reads main's commit; exit 1 without a default branch found by name) breaks behaviour on purpose and is documented in all four places a consumer reads it: help (dev-cycle.sh:56-58, :74-75), the Exit line (:80), SKILL.md:291-294, and the c8435580 commit Notes. The skill's existing rule at SKILL.md:100-101 ("A check that exits non-zero … is recorded, and the step that needed it stops") already covers the new exit 1. [unverified, submitted as claim] The installed image copy keeps the old behaviour until a release (c8435580 Notes). Route: orchestrator.
- check_brief now reads its Status line through brief_fields, so a brief has one parser (T31), and its skip vocabulary is unchanged. Route: code-fact-check, scripts/lib/dev-cycle-read.sh:328-337.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | brief_fields returns 0 with no keys on a failed read under `if !` (no `error` channel like main_entry's) | Minor | `scripts/lib/dev-cycle-read.sh:286` | High |
| 2 | --check-answer help's closed reason list omits "tree could not be read" | Minor | `scripts/dev-cycle.sh:62-70` | High |
| 3 | `"\0"` assumes a NUL-capable awk; under a C-string awk every file is refused with a misleading "holds a NUL byte" | Informational | `scripts/lib/dev-cycle-read.sh:216` | Medium |

## Overall Assessment

The public surface added in U1a (main_entry's five-token vocabulary, brief_fields with its BRIEF/BRIEF_ODD globals, the `nul` reason, the new skip lines and the `--check-answer` default-branch gate) matches the lib's established conventions closely. No naming inconsistencies were found. The one contract-level gap is that brief_fields does not carry main_entry's new fail-closed `error` distinction. It is harmless for check_brief and worth closing before U1b's consumers code against it. The help omission is a one-line fix. The awk portability question (Escalation #1) is not a current-platform problem: the lib already requires GNU coreutils and is written against mawk. At most it calls for a comment or a self-check that makes the failure name its cause.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to the output path given in your tail, structured per your skill, with `Commit: 2da477b7` as its first line.
- Answered: API-consistency review of main_entry/brief_fields/BRIEF/BRIEF_ODD/oddwhy/skip lines/--check-* help, with Escalation #1 answered (no documented platform beyond what GNU realpath and mawk imply; Informational).
- Out of scope: U1b/U1c consumers; settled rows 201/208/213/215/220/221 (not re-raised); Escalations #2 (test), #3 (security side; contract side is finding 1), #4 (digest readers).
- Escalate: none beyond routing finding 1 alongside Escalation #3 to the orchestrator so the security and contract views are reconciled once.
