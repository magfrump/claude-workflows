Commit: 6f624cdf

# API Consistency Review — feat/build-loop-u2a1

**Scope:** `git diff main...HEAD` (one commit, 6f624cdf): scripts/lib/dev-cycle-read.sh, scripts/build-loop.sh, scripts/dev-cycle.sh, skills/dev-cycle/SKILL.md, test/lib/build-loop-fixtures.bash, test/scripts/{dev-cycle,build-loop-read}.bats
**Date:** 2026-10-06
**Based on:** docs/reviews/code-fact-check-report-build-loop-u2a1.md (Stage 1, k=1); docs/reviews/override-log.md rows 202-204, 228, 233, 284, 292, 298, 306-320

## Baseline Conventions

- **Check-mode output contract** (dev-cycle.sh `--check-*`, lib `check_brief`/`check_answer`, build-loop.sh `--status`/`--settings`): one line per argument, `ok ...` or `skip <arg>: <reason>`; the reason is free English text. Consumers act on the leading word only: SKILL.md:310 says a `skip` "goes in the record and the final message"; no script or doc parses the reason text. The bats suites pin full lines, so they are the only text consumers. docs/dev-cycle.md documents no skip text (searched: no `skip ` hits).
- **Reason phrasing in the lib**: check_brief's reasons drop the subject because the `skip <a>:` prefix already names it (`not an allowed path form`, `not a build brief ...`, `reached through a symlink, or not a regular file`). check_answer names the file it was reading, since the prefix holds a question ID: `..., so no entry in $f is read` (lib:578-580). build-loop.sh's `FILE_WHY` reasons all name `$f` (build-loop.sh:136, :138, :139), because the `--settings` line prefix (`policy`, `constraints`) does not hold a path.
- **Path-form refusals** are spelled `skip <x>: not an allowed path form` in all five check functions (dev-cycle.sh:146, :152, :162, :175; lib:341).
- **main_entry result words**: lower-case run-together words (`blob`, `absent`, `notfile`, `notdir PART`, `error`); callers `case` on them and treat their default arm as a refusal.
- **Lib function names**: snake_case for multi-word names (`main_entry`, `main_by_name`, `brief_fields`, `check_brief`, `need_root`, `imported_names`), a run-together `is`/`in` prefix for path predicates (`isbrief`, `inrepo`), and one run-together `<word>why` reason mapper (`oddwhy`, lib:232).
- **--check-fix exclusion list** is written out in four places: the dev-cycle.sh usage header (:50-55, printed by `--help`), the comment above `check_fix` (:167-171), the skip reason (:183) and SKILL.md:72-76.

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `badform` | main_entry result word | `notfile`, `notdir`, `absent`, `error` | `scripts/lib/dev-cycle-read.sh:252-279` | Consistent: lower-case, run-together, like `notfile`/`notdir` |
| `isclosed` | lib path predicate | `isbrief`, `inrepo`, `writable` | `scripts/lib/dev-cycle-read.sh:158-162` | Consistent: matches `isbrief`'s `is<noun>` form, and it is defined in terms of isbrief |
| `entry_why` | lib reason mapper | `oddwhy`, `main_entry`, `brief_fields` | `scripts/lib/dev-cycle-read.sh:232`, `:263`, `:304` | Consistent with the lib's snake_case majority; `oddwhy` (no underscore) is the sole run-together `*why` and stays the outlier. No finding |
| new `--check-fix` exclusion `constraints.md` | CLI allowlist entry | `dev-cycle.md`, `working/`, `decisions/` | `scripts/dev-cycle.sh:50-55`, `:183`; `skills/dev-cycle/SKILL.md:72-76` | Consistent: bare `constraints.md` beside bare `dev-cycle.md` in the header and the skip reason; `docs/constraints.md` beside `docs/dev-cycle.md` in SKILL.md |

There are no new CLI flags, modes or output-line prefixes.

## Findings

#### 1. build-loop.sh's `error` reason no longer names the file, unlike every other `FILE_WHY`

**Severity:** Minor
**Location:** `scripts/build-loop.sh:133` (via `scripts/lib/dev-cycle-read.sh:287`)
**Move:** 7 (asymmetry), 3 (consumer contract)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**
```
    *) FILE_WHY="$(entry_why "$e" "$f")"; return 1 ;;
```
(build-loop.sh:133)
```
    error) echo "the tree of the default branch could not be read" ;;
```
(lib:287). On main, build-loop.sh:133 read:
```
    error) FILE_WHY="the default branch's tree could not be read for $f"; return 1 ;;
```
Sibling reasons in the same function (build-loop.sh:136, :138):
```
    || { FILE_WHY="$f could not be read from the default branch"; return 1; }
    odd\ *) read -r _ n why <<<"$FILE_OUT"; FILE_WHY="line $n of $f $(oddwhy "$why"), so the file is not read"; return 1 ;;
```

Before this change, every `FILE_WHY` that main_file produced named `$f`. check_answer adds its own `, so $f is not read` suffix after entry_why, but main_file does not add one, so main_file is now the only caller whose `error` reason drops the path. The result is `constraints unreadable: the tree of the default branch could not be read` and `policy review unset: the tree of the default branch could not be read` (executed: `entry_why error docs/constraints.md` printed that text with no path). The `--settings` line prefix says which key was affected, not which file, so the reader loses the one fact that tells them where to look. The arm is hard to reach (it needs ls-tree to fail or a duplicate tree name), and no test pins either wording (on main, `could not be read for` appears in no test). So nothing breaks, and the information is simply lost.

**Recommendation:** Name the file in main_file's own arm, for example `*) FILE_WHY="$(entry_why "$e" "$f")"` followed by ` for $f` on the error word only. A simpler alternative is `entry_why`'s error arm saying `... could not be read for $2`, but then check_answer's suffix repeats the path. Add one in-process test that pins the reason, using the same route as dev-cycle.bats:1324 (a bogus `MAIN_SHA`).

#### 2. The shared mapping puts the path into reasons whose prefix already names it

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:352`, `:570` (wording from `:285`)
**Move:** 4 (message consistency), 3 (consumer contract)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**
```
    *) echo "skip $a: $(entry_why "$e" "$a")"; return ;;
```
(lib:352)
```
      *) echo "skip $a: $(entry_why "$e" "$f"), so $f is not read"; return ;;
```
(lib:570)
```
    notfile) echo "$2 is not a regular file on the default branch" ;;
```
(lib:285). Sibling arms in check_answer (lib:578-579):
```
      odd\ *) read -r _ n why <<<"$r"; echo "skip $a: line $n of $f $(oddwhy "$why"), so no entry in $f is read"; return ;;
      unbalanced\ *) echo "skip $a: the code fence opened at line ${r#unbalanced } of $f is never closed, so no entry in $f is read"; return ;;
```
The test now pins the doubled path (dev-cycle.bats:1039, :1195):
```
    [[ "$output" == "skip docs/working/briefs/2026-01-01-s.md: docs/working/briefs/2026-01-01-s.md is not a regular file on the default branch" ]] || { echo "$output"; return 1; }
    [ "$output" = "skip Q-1: docs/working/questions.md is not a regular file on the default branch, so docs/working/questions.md is not read" ] \
```

Before this change, check_brief's notfile reason had no subject (`skip A: not a regular file on the default branch`), which matched its other reasons (lib:341, :345). Now it repeats `A`. check_answer's notfile reason now names `$f` twice in one sentence. Its trailing clause `so $f is not read` also differs from the `so no entry in $f is read` used by its three sibling arms, although the notdir and error arms already used `is not read` on main. The reason text is free-form: SKILL.md:310 records it verbatim and nothing parses it. So this is legibility drift in a user-facing message, not a break. Row 228's premise was "two callers with different messages", and folding them into one mapping is the change that caused this drift.

**Recommendation:** Either accept it and note that the mapping fixes the subject, or have entry_why's notfile arm print `is not a regular file on the default branch` without `$2`, as notdir would need to keep its PART. Then check_answer composes `$f is not ...` and check_brief keeps its subject-less style. Either choice is fine. Pick it before U2a2's floor becomes the fourth caller, so the floor's skip lines inherit a deliberate form.

#### 3. Two spellings of the path-form refusal now exist; the second becomes reachable in U2's floor

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:286` vs `:341`, `scripts/dev-cycle.sh:146,152,162,175`
**Move:** 4 (error consistency)
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

**Evidence:**
```
    badform) echo "$2 is not an allowed path form" ;;
```
(lib:286)
```
  if ! pathform "$a"; then echo "skip ${a//$'\n'/ }: not an allowed path form"; return; fi
```
(lib:341)

Every current entry_why caller either runs pathform first (check_brief, lib:341) or passes fixed paths (check_answer, main_file). So the `badform` arm cannot be reached today, which matches the fact-check's executed finding. U2a2's floor will pass changed paths (row 306: `.gitattributes`, `.github/x.yml`) straight to main_entry. Its skip lines would then read `skip X: X is not an allowed path form`, while the five check modes read `skip X: not an allowed path form`. Also, `badform` maps any pathform refusal, a `.git*` part included, to one generic reason, so it is the same message for the same condition. Only the subject is duplicated, which is the same issue as finding 2.

**Recommendation:** Resolve this together with finding 2. If entry_why drops `$2` from its notfile and badform arms, the floor's reason matches the existing five spellings exactly.

#### 4. The comment above check_fix is the one place, of four, whose exclusion list differs from the code

**Severity:** Minor
**Location:** `scripts/dev-cycle.sh:167-171`
**Move:** 3 (documentation drift)
**Confidence:** High (fact-check: Mostly accurate)
**Legibility-target:** for-author

**Evidence:**
```
# An in-cycle fix edits documentation only: a tracked .md file under docs/,
# outside the cycle's own files, working/, human-author/ (the user's), reviews/
# and decisions/ (records), the settings file, constraints.md (the user's: plan
# D2), any dot-directory, and any instruction file (CLAUDE.md, AGENT(S).md,
# GEMINI.md, SKILL.md, any case); or README.md. Anything else is filed.
```
(dev-cycle.sh:167-171) The header, which `--help` prints (dev-cycle.sh:51-53), reads:
```
#             human-author/, reviews/, decisions/, dev-cycle.md, constraints.md, a dot-directory
#             or dotfile, an instruction file, or a file an instruction file
#             imports with @; compared ignoring case) or README.md; "skip <path>: <reason>"
```

The diff adds `constraints.md` to all four copies, which is consistent. The comment still omits dotfiles and `@`-imported files, as the Stage 1 fact-check found, and it calls `dev-cycle.md` "the settings file" where the other three copies name it. The three consumer-facing copies (help, skip reason, SKILL.md) agree with each other and with the predicate at :181-185, so this is drift in a maintainer comment only. The diff touched this comment, so it is cheap to fix now.

**Recommendation:** Add "dotfile" and "a file an instruction file imports with @" to the comment, and name `dev-cycle.md` explicitly.

## What Looks Good

- **`badform` is an additive, fail-closed change to the lib's caller contract.** The new rule on main_entry (lib:256-258: "Only blob reads the file, and only absent means there is none: every other word is a refusal") turns the set of words into an open set that callers must default to refusal. Every caller already does that: three through `*) ... entry_why`, and brief_fields through `!= blob`. Stage 1 fact-check verified this by execution (every caller treats badform as a refusal; 0 git calls). It also resolves row 306's overloaded `error`. [unverified — submitted as claim: no out-of-tree caller of main_entry exists; searched scripts/, hooks/, skills/, test/]
- **`isclosed` matches `isbrief`'s naming and is built on it.** Stage 1 verified that it is equivalent to all three old spellings on 23 edge cases. This resolves row 292.
- **The `--check-fix` exclusion of `constraints.md` is written the same way in all three consumer-facing copies.** It uses a bare name in the header and skip reason, beside `dev-cycle.md`, and a `docs/` path in SKILL.md, beside `docs/dev-cycle.md`. It is compared lower-cased like its neighbours, and dev-cycle.bats pins the mixed-case `docs/Constraints.md` refusal and the `docs/thoughts/` positive case.
- **The help-text wording now matches the code.** "not ahead of main" (build-loop.sh:65) matches the n-commits-ahead semantics that `--check-branch` documents, and "a checked task box" (:44) agrees with the policy paragraph at :18-20. These resolve row 319.
- **No CLI flag, mode, exit code or output-line prefix changed.** Only `skip` reason text changed, and every changed line is re-pinned in the suites.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | main_file's `error` reason dropped `$f`; every other FILE_WHY names it | Minor | `scripts/build-loop.sh:133` / `lib:287` | High |
| 2 | Shared mapping doubles the path in check_brief/check_answer notfile skip lines; check_answer clause drifts from siblings | Minor | `scripts/lib/dev-cycle-read.sh:285,352,570` | High |
| 3 | `X is not an allowed path form` vs five existing `not an allowed path form` spellings; reachable once U2a2's floor calls main_entry | Informational | `scripts/lib/dev-cycle-read.sh:286` | High |
| 4 | check_fix comment omits dotfiles and @-imports, unlike header/skip/SKILL.md | Minor | `scripts/dev-cycle.sh:167-171` | High |

## Overall Assessment

The branch is consistent with the codebase's API conventions. The new result word, predicate and mapper follow their neighbours' names. `badform` is additive and fails closed under a now-explicit "anything but blob or absent is a refusal" rule. The `--check-fix` addition is the same in all three consumer-facing copies. No flag, mode, exit code or line prefix changed. Every finding concerns the free-text `skip` reason, which nothing parses (SKILL.md:310 records it verbatim). Centralizing the wording in `entry_why` has made three reasons slightly worse: one lost path (1) and two doubled paths (2). It has also set up a mismatch that U2a2's floor will expose (3). All of these can be fixed in place in a few lines, and fixing them in entry_why before the floor becomes its fourth caller is cheapest. None of them is blocking.

## Goal-Alignment Note

- **Success criterion (verbatim):** A markdown report saved to docs/reviews/<critic>-review-2026-10-06-build-loop-u2a1.md inside the worktree, structured per your skill, with `Commit: 6f624cdf` as its first line.
- **Answered:** This report was saved at docs/reviews/api-consistency-reviewer-review-2026-10-06-build-loop-u2a1.md with `Commit: 6f624cdf` as its first line, in the skill's structure (baseline, name-pattern audit, findings, what looks good, summary, assessment). It covers the requested focus areas: skip-line wording and its consumers, main_entry's new word in the caller contract, the four copies of the --check-fix list, and the help text.
- **Out of scope:** Security exploitability, performance and module structure (other critics). Settled override-log rows were not re-filed. Findings 2 and 3 extend row 228's resolution rather than reopening it.
- **Escalate:** none.
- **Decisions:** Finding 2's fix direction (whether entry_why prints the subject) is the author's choice. It should be settled before U2a2's floor adds a fourth caller.
