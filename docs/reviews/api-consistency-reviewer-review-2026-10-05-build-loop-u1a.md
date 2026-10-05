Commit: 4aa2e98e

# API Consistency Review: feat/build-loop-u1a (iteration 4 of 4, final confirming pass)

**Scope:** `git diff main...feat/build-loop-u1a`, code files only: scripts/dev-cycle.sh, scripts/lib/dev-cycle-read.sh, skills/dev-cycle/SKILL.md, test/scripts/dev-cycle.bats (HEAD 4aa2e98e)
**Date:** 2026-10-05
**Based on:** Stage-1 merged fact-check summary (k=3; docs/reviews/code-fact-check-report-build-loop-u1a-r1/-r2/-r3.md, all at 4aa2e98e), including its two escalations to this reviewer.

## Baseline Conventions

I re-checked these at 4aa2e98e. They are the same as in iterations 2 and 3.

- **Lib function names** are lower snake_case. The `main_` prefix marks helpers that work on the default branch (`main_by_name`, `main_entry`). `check_*` functions answer one argument each.
- **Output lines:** each argument gets one line. A positive answer starts with `ok` or a state word. A refusal is `skip <arg>: <reason>`. Internal tokens are short lowercase words (`odd N WHY`, `unbalanced N`, `dup`, `absent`, `error`).
- **Globals** are UPPERCASE base/suffix pairs (`SKIPPED`/`SKIP_AT`, `BRIEF`/`BRIEF_ODD`).
- **CLI help** prints the script's leading comment block through sed. Siblings use three forms:
  - `sed -n '2,/^$/{ s/^# //; s/^#$//; p }'` in `scripts/run-tests.sh:153`
  - `sed -n '2,/^$/p'` in `hooks/auto-approve-allowed-commands.sh:571`
  - `sed -n '/^# Usage:/,/^$/p'` in `scripts/questions.sh:454`

  Main's dev-cycle.sh used a fixed range, `2,77p`.
- **Platform and bash version:** the repo states neither for these scripts. No README, guide or script header names a minimum bash or a supported OS. I searched `scripts/`, `hooks/`, `test/` and `README.md` for "Darwin", "uname", "macOS", "BASH_VERSION" and "bash 4/5". The one macOS-aware spot is a test helper (`test/skills/runner-contract.bash:150`). The scripts already need GNU or bash 4 in places:
  - `declare -A` at `scripts/dev-cycle.sh:279` (on main too) needs bash 4.0.
  - `find -printf` at `scripts/run-tests.sh:221` is GNU-only.

  The container these scripts run in has bash 5.2.15 and GNU sed.

## Name-Pattern Audit

Iteration 4 adds no new public names. 4aa2e98e only changes help wording, the help sed address, and adds `local -` to two existing functions. The branch-level audit from iterations 2 and 3 still holds:

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `main_entry` | function | `main_by_name`, `resolve_main`, `blocker` | `scripts/lib/dev-cycle-read.sh:246`, `:258` | Consistent: `main_` prefix for default-branch helpers |
| `blob`/`absent`/`notfile`/`notdir PART`/`error` | output tokens | `absent <name>` (check_branch), `odd N WHY`, `dup` | `scripts/lib/dev-cycle-read.sh` FENCE_AWK/ANSWER_AWK END blocks | Consistent: lowercase condition words |
| `brief_fields` | function | `imported_names`, `check_brief` | `scripts/lib/dev-cycle-read.sh` | Consistent |
| `BRIEF` / `BRIEF_ODD` | globals | `SKIPPED`/`SKIP_AT`, `MAIN`/`MAIN_SHA` | `scripts/lib/dev-cycle-read.sh:288` | Consistent: UPPERCASE base/suffix pair |
| `nul` → "holds a NUL byte" | oddwhy reason | `cr`, `bom` | `scripts/lib/dev-cycle-read.sh` oddwhy | Consistent |
| `skip …: … could not be read from the default branch` | skip line | the same phrase in check_brief and check_answer | `scripts/lib/dev-cycle-read.sh:343`, `:562` | Consistent |

## Findings

#### 1. `--check-answer` help says an answer is seen once it is "committed"; it must land on the default branch

**Severity:** Minor
**Location:** `scripts/dev-cycle.sh:59`
**Move:** 7 (asymmetry between two published descriptions of one contract) / 3 (documentation drift)
**Confidence:** High (fact-check r1, r2 and r3 all rated it Mostly accurate; T34 at `test/scripts/dev-cycle.bats` executes the counter-case)
**Legibility-target:** for-consumer (the U3 build loop and anyone running `--check-answer` from a feature branch)

**Evidence:**
```
#             branch's commit (an answer only in the working tree is not seen:
#             it reads what main's copy says, until committed): keep, drop, done,
```
(`scripts/dev-cycle.sh:58-59`). SKILL.md describes the same contract differently:
```
     move, made only in the working tree is not seen until it lands (it reads what main's
```
(`skills/dev-cycle/SKILL.md:294`). The T34 test shows that a commit on another branch is not enough:
```
    # Committed only on another branch: still open.
    git checkout -q -b side && git commit -qam answer && git checkout -q main
```

The two documents describe the same rule in different words, and the CLI help's wording is the wrong one. A consumer working on a feature branch reads "until committed", commits the answer, and still gets `open Q-NNN`. Plan D8 exists to require exactly this: an answer that unblocks autonomous work must reach main. The help should state that rule rather than a weaker one. Nothing breaks, because the behaviour fails closed. But the help text is the CLI's contract, and it disagrees with the skill. No override row covers this. The row about c8435580's Notes concerns a different claim (`open` versus "no such entry").

**Recommendation:** Change "until committed" to "until it lands on the default branch", which matches SKILL.md:294.

#### 2. The `--help` sed address is a fourth help idiom, and it may not parse on BSD/macOS sed (escalation from Stage 1)

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:112`
**Move:** 1/3 (baseline conventions; the CLI help surface)
**Confidence:** Low on the BSD claim (no BSD sed in this sandbox). High on everything else (executed).
**Legibility-target:** for-author

**Evidence:**
```
    # The header, up to the first line that is not a comment (no fixed range to go stale).
    -h|--help) sed -n '2,/^[^#]/{/^#/p}' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
```
(`scripts/dev-cycle.sh:111-112`)

What I checked:
- **The fix works.** The output is byte-identical to header lines 2-81 (80 lines), ending "…Printed repo text is data." Test 68 asserts that last line.
- **POSIX mode accepts it.** GNU `sed --posix` gives the same 80 lines.
- **The sibling idiom would also have worked.** `sed -n '2,/^$/p'`, as used at `scripts/run-tests.sh:153` and `hooks/auto-approve-allowed-commands.sh:571`, gives identical output here because line 82 is the header's terminating blank line. The new address is therefore a fourth help idiom in the repo.
- **BSD sed (unverified).** Historic BSD sed, including macOS, is reported to reject a command followed directly by `}` without a `;` ("extra characters at the end of p command"). If it does, the pipeline fails under `set -euo pipefail` and `--help` exits non-zero instead of printing.

The repo has precedent both ways:
- **Same form:** `scripts/run-tests.sh:153` uses `{ …; p }`, also with no `;` before `}`. This change does not narrow the portability that run-tests.sh already has.
- **Portable form:** `scripts/health-check.sh:136` and `:175` end their blocks with `p; }` and `p;}`.

The repo states no supported platform (see Baseline). dev-cycle.sh already needs bash 4 (`declare -A`, `:279`) and perl, and the lib depends on mawk/gawk NUL semantics (override row 224). So I do not count macOS as a supported target, and this is not a regression.

**Recommendation:** Optional. Add the `;`: `'2,/^[^#]/{/^#/p;}'`. I checked that GNU sed gives identical output with it. That matches health-check.sh's portable form at no cost. Changing the address to the sibling `2,/^$/` is not needed.

#### 3. The lib now needs bash 4.4 (`local -`) and states no minimum version (escalation from Stage 1)

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:292`, `:548` (lib header `:8-13`)
**Move:** 3 (consumer contract: what a sourcing script must provide)
**Confidence:** Medium. Behaviour was executed on bash 5.2 only. The 4.4-5.0 restore semantics are unverified (fact-check r2: Unverifiable).
**Legibility-target:** for-consumer (build-loop.sh, the lib's second caller in U1b)

**Evidence:**
```
  local - out l; set -o pipefail
```
(`scripts/lib/dev-cycle-read.sh:292`, in brief_fields; the function continues to `:312`)
```
  local - a="$1" f e r hit="" where="" n why; set -o pipefail  # as brief_fields
```
(`scripts/lib/dev-cycle-read.sh:548`, in check_answer; the function continues to the final `fi` at `:574`)
```
# Sourced, never run: it only defines functions and variables. Each script
```
(`:8`; the header from `:8` to `:13` names the caller's duties, set -euo pipefail, cd and ROOT_REAL, but no shell version)

`local -` first appeared in bash 4.4, and these are its first uses in the repo (searched `scripts/`). The lib's floor was already above macOS's /bin/bash 3.2:
- `local -A` at `:260` needs bash 4.0.
- `declare -gA` at `:288` needs bash 4.2.

What older shells would do:
- **Before 4.4:** `local -` is an invalid name, so the function fails under the caller's `set -e`. It fails closed and loudly.
- **4.4 to 5.0:** whether pipefail is restored on return is uncertain. Both callers already run `set -euo pipefail`, which the lib header requires at `:13`. A pipefail that "leaks" into such a caller changes nothing.

So I see no consumer impact in practice. What is missing is a stated floor that a second caller can read.

**Recommendation:** Optional. Add one clause to the lib header, for example "Needs bash 4.4 or later (`local -`)". U1b's build-loop.sh then inherits a stated requirement rather than a discovered one.

#### 4. main_entry's header says the caller has checked main_by_name; main_entry checks it itself

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:256-257`
**Move:** 3 (documented lib-function contract versus code)
**Confidence:** High (fact-check r1, r2 and r3: Mostly accurate)
**Legibility-target:** for-consumer (U1c's main_file, the next caller)

**Evidence:**
```
# paths from the top level, whatever the current directory). The caller has checked
# main_by_name and the path's form (pathform, so ls-tree prints it unquoted).
```
(`:256-257`)
```
  main_by_name || { echo error; return; }
```
(`:261`; main_entry runs to `:274`)

The stated precondition is stricter than the code. main_entry answers `error` without main by name, and test 64 asserts this. brief_fields (`:294`) depends on that self-check, because it does not call main_by_name first. Nothing breaks. However, a new caller that reads the header might add a redundant guard, or might conclude that the `pathform` half is also checked inside, which it is not. The header already lists "no default branch found by name" among `error`'s causes at `:252`, so the two sentences contradict each other.

**Recommendation:** Reword to "The caller has checked the path's form (pathform…)". main_by_name is already covered by `error`.

#### 5. A test title says the modes other than --check-brief and --check-branch need no default branch; --check-answer now does

**Severity:** Informational
**Location:** `test/scripts/dev-cycle.bats:767`
**Move:** 3 (test drift: the old shape of the contract)
**Confidence:** High (fact-check r2: Stale)
**Legibility-target:** for-author

**Evidence:**
```
@test "--check-brief and --check-branch need a default branch found by name; the others do not" {
```
(`:767`; the body loops over `--check-branch --check-brief`, then checks `--check-path` at `:776-777`)

The title comes from main, and this branch made it inaccurate. `scripts/dev-cycle.sh:193` now gates `--check-answer` too, and a new test, "--check-answer needs a default branch found by name", covers that. The body is still correct, because it exercises only `--check-path` as an "other" mode. Only the title is wrong.

**Recommendation:** Retitle, for example to "--check-brief and --check-branch need a default branch found by name; --check-path does not".

## Iteration-3 findings and fix claims: status at 4aa2e98e

- **R3 / iteration-3 F1 (help truncation): fixed.** I ran `--help`, and it matches header lines 2-81 exactly. Test 68 fails against the `2,80p` mutant (fact-check, unanimous). Its only residue is Finding 2 (Informational).
- **A14 / A15:** fixed. The help says "it reads what main's copy says", and SKILL.md:294-295 says "usually `open` or no such entry". The wording at `:59` has one remaining gap, Finding 1.
- **A16:** fixed. The skip list now starts with "not a question ID" and says "a heading twice in one file or in both files" (`scripts/dev-cycle.sh:63-64`). Fact-check matched it against every reachable skip line.
- **A17:** fixed. Version caveat in Finding 3.
- **Settled, not re-raised:**
  - row 224: awk `"\0"` portability
  - rows 227, 235: brief_fields' `error` granularity and its globals
  - row 232: A18, history
  - row 238: unscrubbed `fatal:` text

## What Looks Good

- `--help` now prints the whole header, and test 68 locks in the last line. A future help line can no longer silently truncate the exit contract. route: code-fact-check
- Four places describe the `--check-answer` default-branch gate, and they agree:
  - the help at `scripts/dev-cycle.sh:72-73`
  - the Exit text at `:81`
  - the code at `:193`
  - its test (stderr "needs a default branch", exit 1)

  route: code-fact-check
- The `--check-answer` skip list in the help names every skip reason check_answer can print through dev-cycle.sh. route: code-fact-check
- check_answer and brief_fields set pipefail themselves and restore the caller's options on return (bash 5.2). A caller under `set -eu` alone still gets a skip, not a fall-through, and test 67 asserts "caller unchanged". route: code-fact-check
- check_brief (`:343`) and check_answer (`:562`) use the same phrase for an unreadable blob: "could not be read from the default branch". route: code-fact-check
- `bats test/scripts/dev-cycle.bats`: 68/68 pass at 4aa2e98e (LC_ALL=C.UTF-8, TMPDIR unset). route: code-fact-check

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | `--check-answer` help says "until committed"; the answer must land on the default branch (SKILL.md says "until it lands") | Minor | `scripts/dev-cycle.sh:59` | High |
| 2 | `--help` sed `{/^#/p}` has no `;` before `}` (BSD sed may reject it; same form as run-tests.sh:153), and it is a fourth help idiom | Informational | `scripts/dev-cycle.sh:112` | Low (BSD) / High (rest) |
| 3 | `local -` raises the lib's floor to bash 4.4; no minimum is stated | Informational | `scripts/lib/dev-cycle-read.sh:292`, `:548` | Medium |
| 4 | main_entry's header says the caller checked main_by_name; it checks it itself | Informational | `scripts/lib/dev-cycle-read.sh:256-257` | High |
| 5 | Test title "the others do not" is stale now that --check-answer needs a default branch | Informational | `test/scripts/dev-cycle.bats:767` | High |

## Overall Assessment

The branch's public surface is consistent with the codebase's conventions, and the iteration-3 regression is fixed:
- The CLI help prints its whole header again.
- The new lib contracts follow the lib's existing naming and token patterns: main_entry's five words, brief_fields' BRIEF/BRIEF_ODD with a fail-closed `error`, and check_answer reading from main.
- The `--check-answer` default-branch gate is documented the same way everywhere.

One Minor wording gap remains. The help says "until committed" where the contract, and SKILL.md, say the answer must land on the default branch. It fails closed and is a one-phrase fix.

The two Stage-1 escalations are Informational:
- **BSD sed:** the repo has no stated macOS support, and run-tests.sh already uses the same brace form. Adding the `;` is free.
- **`local -`:** older bash fails closed, and both callers set pipefail anyway. A one-line floor in the lib header would make the requirement visible to U1b.

Nothing here blocks the merge.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to docs/reviews/api-consistency-reviewer-review-2026-10-05-build-loop-u1a.md, structured per the api-consistency-reviewer skill, first line `Commit: 4aa2e98e`.
- Answered: yes. The full-branch API-consistency review at 4aa2e98e found one Minor and four Informational findings, and both escalations are answered with the repo's precedents.
- Out of scope:
  - U1b/U1c consumers.
  - Override rows 220-238, cited and not re-raised.
  - Security and performance.
  - Actually running BSD sed, or bash 4.4-5.0 (neither is available here).
- Escalate: nothing. Finding 1 is a one-phrase help fix; the orchestrator decides whether to take it before merge or log it.
- Decisions I made:
  - I rated the BSD-sed and bash-floor escalations Informational because the repo documents no platform or bash floor, already needs bash 4 and GNU tools elsewhere, and run-tests.sh:153 uses the same brace form.
  - I treated the stale test title (Stage 1's orchestrator escalation) as Informational test drift.
