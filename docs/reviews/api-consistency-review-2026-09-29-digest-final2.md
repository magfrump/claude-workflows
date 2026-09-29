Commit: de53069

# API Consistency Review: feat/dev-cycle-digest (final confirming pass 2)

**Scope:** `git diff main...HEAD -- scripts test` (`scripts/dev-cycle.sh`, `test/scripts/dev-cycle.bats`) and the `git log main..HEAD` messages
**Date:** 2026-09-29
**Based on:** brief-digest-final2.md; the fixes in 83e7895 on top of the pass-1 review of 3aee138 (`docs/reviews/api-consistency-review-2026-09-29-digest-final.md`)

> ⚠️ **No code fact-check report provided.** API documentation claims have not been
> independently verified against implementation. For full verification, run the
> `code-fact-check` skill first or use the code-review orchestrator. (To make up for this, I checked
> the header, `--help` and commit-message claims on my surfaces by running the script under `timeout` in
> throwaway repos in the scratchpad. Those repos have been deleted and no processes are left running.)

## Baseline Conventions

The baseline is unchanged from pass 1. It comes from `scripts/questions.sh`, `skill-usage-report.sh`, `flag-removal-candidates.sh`, `archive-working-docs.sh`, `run-tests.sh` and `confine-tests.sh`:
- long `--name=value` flags;
- `Unknown option: X` on stderr with exit 1 (the majority behaviour);
- `-h|--help` prints the header block with `sed`;
- env overrides use a script prefix and are documented in the header;
- the script acts on `$PWD`'s git toplevel.

The new contract is the digest's markdown, which the stacked skill reads. I read `skills/dev-cycle/SKILL.md` on `feat/dev-cycle` to see what it depends on:
- the phrase "no cycle record was found" (the digest prints "no cycle record found", which matches);
- "printed in full" and "carried forward" as the two trigger classes;
- the "`questions.sh open` failed" signal.

The skill does not match literally on `last changed`/`last committed`, on `> ` quoting, or on the Window line's wording. So none of the 83e7895 text changes breaks the stacked unit. The skill also says to run the digest "from the repo root". It does not say to run it on the default branch.

### Pass-1 fixes verified

| Pass-1 item | Status | Evidence |
|---|---|---|
| F1: Window line claimed `main` for every section | Fixed | Line 84 now names the sources: "Merges and commits: `main` at <sha>; triggers, questions and roadmap: the working tree." See new F1 below for a remaining mismatch *inside* section 2 |
| F2: empty date / uncommitted record carried | Fixed | An untracked `003-c.md` printed in full as `(last committed never: uncommitted)`. The roadmap printed `never (uncommitted)`. See F2 below |
| F3: `--since=2026-13-45` exit 0 | Fixed | Line 78 checks with `date -d`. Test 13 covers it. `--since --sample=3` is also rejected (rc=1) |
| F4: `DEV_CYCLE_TODAY` did not pin the default window | Fixed in code (line 75 `date -d "$TODAY - 14 days"`). Still missing from `--help` (F5 below) |
| F6: `--sample=0` message | Fixed (line 175) |
| F5, F8 | Deferred in the override log. Not re-filed |
| F7, F9 | F9 is fixed (test 3 adds a row dated on the record date). F7 is unchanged (F4 below) |
| `--help` after compression | Correct. `sed -n '2,18p'` prints exactly the header from the first sentence through "not orders". Line 19 is blank. Nothing is cut off and no code leaks into the help |

## Name-Pattern Audit

| New or changed name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `--since=YYYY-MM-DD` / `--since DATE` | CLI flag | `--round=`, `--project=` | `scripts/flag-removal-candidates.sh`, `scripts/skill-usage-report.sh` | Consistent. Now validated as a real date |
| `--sample=N` / `--sample N` | CLI flag | same | same | Consistent |
| `--since must be a real YYYY-MM-DD date` / `--sample must be a non-negative integer` | error text | `Unknown option: X` | same three scripts | Consistent: plain stderr, exit 1. The bare `--since` case prints bash's `line 26: 2: --since needs a date` (F6) |
| `DEV_CYCLE_TODAY` | env var | `QUESTIONS_LIVE`, `USAGE_LOG_FILE` | `scripts/questions.sh` header | Name consistent. Not in `--help` (F5) |
| `Window: since D (from S). Merges and commits: …; triggers, questions and roadmap: the working tree.` | digest line | pass-1 Window line | `scripts/dev-cycle.sh:84` | Clearer. The nested parentheses remain (F4) |
| `### <path> (last committed <date>)` | digest line | pass-1 `(last changed <date>)` | `scripts/dev-cycle.sh:115` | Renamed. Accurate, since the date is the last commit. No consumer depends on the old wording |
| `never: uncommitted` vs `never (uncommitted)` | digest token | each other | `scripts/dev-cycle.sh:115, 181` | Inconsistent (F2) |
| `> ` quoting of repo text | digest convention | none before 83e7895 | `scripts/dev-cycle.sh:116, 131, 183` | Two different constructs under one marker (F3) |
| `An explicit --since was given, so every trigger is printed in full.` | digest line | `No earlier cycle record to carry verdicts from, …` | `scripts/dev-cycle.sh:101` | Consistent pair |
| `Sample size 0: no spot-check requested.` | digest line | `No merges in the window to sample.` | `scripts/dev-cycle.sh:175` | Consistent |

## Findings

#### F1. A decision record committed on the checked-out branch, but not on the default branch, is carried forward with no verdict to carry

**Severity:** Inconsistent
**Location:** `scripts/dev-cycle.sh:105-119` (line 111)
**Move:** 7 (asymmetry) / 3 (consumer contract)
**Confidence:** High

The Window line now says triggers come from "the working tree". Section 2 globs the working tree. But the "changed" test on line 111 asks two questions:
- whether the file entered `$MAIN_SHA`'s first-parent history in the window;
- whether `git status` shows it dirty.

A record that is committed on the current branch but absent from the default branch passes neither. Probe: on branch `feat`, with a cycle record dated yesterday, a newly committed `002-b.md` produced `Carried forward (2): 001-a.md 002-b.md`. The printed rule says that record's verdict "carries forward from docs/working/cycles/cycle-….md", but no cycle ever judged it. This is the same silent miss that pass-1 F2(c) and fact-check r3 fixed for uncommitted and branch-merged records. It is still reachable, because the stacked skill says "from the repo root", not "on the default branch". The date on line 114 has the same mix of sources: it comes from HEAD's history while "changed" comes from main's.

**Recommendation:** Also count a record as changed when it differs from the default branch: `git diff --quiet "$MAIN_SHA" -- "$f"` returns non-zero, or `git cat-file -e "$MAIN_SHA:$f"` fails. That one check also covers the uncommitted case, so it could replace the `git status` half. Alternatively, print a warning in the Window line when `HEAD` is not `$MAIN_SHA`, and have the skill say to run on the default branch.

#### F2. The "uncommitted" date has two spellings, and the commit message claims only one

**Severity:** Minor
**Location:** `scripts/dev-cycle.sh:115, 181`; commit 83e7895 body
**Move:** 2 (naming)
**Confidence:** High

Precedent: `last committed ${d:-never: uncommitted}` used in `scripts/dev-cycle.sh:115`

Section 2 prints `(last committed never: uncommitted)`. Section 5 prints `docs/roadmap.md last committed never (uncommitted).` The two sentences state the same fact about the same kind of file in the same digest, but a reader or grep has to match both forms. The 83e7895 message says "Uncommitted files show \"never: uncommitted\"", which is true only for section 2.

**Recommendation:** Pick one token and use it on both lines, for example `never committed` or `uncommitted`, which also reads better after "last committed".

#### F3. `> ` marks repo text in two different ways, and one section of repo text is unmarked

**Severity:** Minor
**Location:** `scripts/dev-cycle.sh:116, 131, 173, 183`
**Move:** 7 (asymmetry in the digest contract)
**Confidence:** High

For decision records (line 116) and the roadmap (line 183), `> ` starts the line, so it is a real markdown blockquote. For log rows (line 131), it appears in the middle of a list item (`- log row 5 (2026-09-29): > Revisit if y. `). There it is only a literal character, not a quote, and the text runs to the end of the line with a trailing space. Merge subjects in section 1 are fenced. The same subjects in section 4 (line 173) are neither fenced nor quoted. The brief describes the convention as "record/row/roadmap text quoted with \"> \"", so a consumer might expect one rule for where repo text starts and ends.

**Recommendation:** Put the log-row clause on its own `  > ` line under its list item, or wrap it in backticks. Fence section 4 as section 1 is fenced. Alternatively, have the header say in one sentence what the marker means for each section.

#### F4. The Window source note still nests parentheses and still names a flag as its source (pass-1 F7, unchanged)

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:71, 76, 84`
**Move:** 2
**Confidence:** High

The line still renders as `(from no cycle record found, so the default of 14 days (the previous cycle, if any, did not write its record))` and `(from --since)`. The item was neither fixed nor logged in the override log.

**Recommendation:** Reword so each note fits `(from …)`, or add an override row so the next pass does not raise it again. Keep the substring "no cycle record found", because the skill matches on it.

#### F5. `DEV_CYCLE_TODAY` is still not in `--help`

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:40`
**Move:** 3
**Confidence:** High

The variable is now a full date pin, since it also sets the default window. The only statement that it is test-only is the comment on line 40, which the `2,18p` help range does not print. Each env override in questions.sh is listed in its header.

**Recommendation:** Optional: add a line to the header ("DEV_CYCLE_TODAY=YYYY-MM-DD: tests only, pins today's date") and widen the `sed` range to match.

#### F6. `--since` with no value prints bash's internal error format

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:26, 28`
**Move:** 4 (error consistency)
**Confidence:** High

`dev-cycle.sh --since` prints `…/dev-cycle.sh: line 26: 2: --since needs a date` with rc=1. The exit code is correct, but the message carries the script path, a line number and `2:`. The script's other usage errors are plain sentences.

**Recommendation:** Optional: `[[ $# -ge 2 ]] || { echo "--since needs a date" >&2; exit 1; }` (and the same for `--sample`).

## What Looks Good

- Every pass-1 fix I could exercise holds. Real-date validation, the `--sample=0` message, the explicit `--since` sentence, a non-empty uncommitted date, the future-dated record filter and the first-parent carry-forward all behave as the commit message says.
- `--help` survived the compression intact. The documented exit contract (0, or 1 for usage/repo/branch/step failure) matches the probes.
- The Window line now states which sections read the default branch and which read the working tree. That is the contract a reader needs.
- `last changed` → `last committed` is the more accurate label, and nothing downstream depends on the old text.
- The stacked skill's phrase dependencies ("no cycle record found", "printed in full", "carried forward", "`questions.sh open` failed") all still appear in the output.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Record committed only on the checked-out branch is carried forward unjudged | Inconsistent | `scripts/dev-cycle.sh:111` | High |
| 2 | Two spellings of the uncommitted date; commit message names one | Minor | `scripts/dev-cycle.sh:115, 181` | High |
| 3 | `> ` is a blockquote in two places and an inline character in one; section 4 unmarked | Minor | `scripts/dev-cycle.sh:116, 131, 173, 183` | High |
| 4 | Window note nests parentheses (pass-1 F7, unlogged) | Informational | `scripts/dev-cycle.sh:71, 76, 84` | High |
| 5 | `DEV_CYCLE_TODAY` absent from `--help` | Informational | `scripts/dev-cycle.sh:40` | High |
| 6 | Bare `--since`/`--sample` gives bash's internal error text | Informational | `scripts/dev-cycle.sh:26, 28` | High |

## Overall Assessment

The CLI surface (flags, exit codes, `--help`) is consistent with the sibling scripts, and every pass-1 finding on it is fixed or deferred on record. The one substantive item is F1. The 83e7895 carry-forward fix judges "changed" against the default branch's history, while the Window line says triggers come from the working tree. So a record committed only on a feature branch is silently carried forward, and the stacked skill does not require running on the default branch. The fix is small: add one `git diff --quiet "$MAIN_SHA" -- "$f"` check, or have the skill require the default branch. F2 and F3 are wording and markup fixes to the digest contract. None of the findings breaks the stacked skill as it stands.

## Goal-Alignment Note

- **Answered:** I verified the pass-1 fixes on the CLI, exit-code, `--help` and digest-structure surfaces by probing in scratchpad repos (deleted; no processes left). I found one new Inconsistent item created by the carry-forward fix (F1), two Minor contract items (F2, F3) and three Informational items. I also checked the stacked skill's phrase dependencies against the new output.
- **Out of scope:** I did not re-review deferred items (file-level carry-forward cost, the two-defence option-name test, the untested SIGPIPE fix, the carried-list format). I did not run the bats suite or health-check. I did not assess security or performance.
- **Escalate:** F1 is a design choice for the author. Either widen "changed" to "differs from the default branch", or make the skill require running on the default branch. This is the loop's last allowed iteration, so if it is not fixed it needs an override row.
