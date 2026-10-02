Commit: f3c9ebb (A) / 2bf03da (B)

# API Consistency Review — dev-cycle pass 35 (the pass-34 fix round)

**Scope:** A: `git diff e93312d..f3c9ebb -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` (worktree `wt-digest`); B: `git diff 823f494..2bf03da -- skills/dev-cycle/SKILL.md docs/decisions/log.md` (worktree `wt-devcycle`, merge 55bdb14). Partial scope: everything else is context only.
**Date:** 2026-10-02
**Based on:** Stage-1 context `docs/reviews/code-fact-check-report-digest-pass34.md` (loop pass 34's k=1 fact-check) and the rubric's "Pass 34" section.
**Acceptance bar applied:** for every input, the fence reader gives the CommonMark reading or refuses, except decision log 69's accepted inline class. Refusing a file CommonMark would read is the design's cost unless a real file is hit.

Surfaces checked: the refusal reasons (`oddwhy`), `--help` (lines 2–74, including `--check-brief`'s new list), the FENCE_AWK, `refdef`, `fence`, check_brief and ANSWER_AWK comments, the skill's brief clause and final message against `--check-brief`, decision log row 69 against the code and the skill, and `--check-answer` against the real answer lines.

Probes: each was one `set -eu` script that made its own `mktemp -d` dir under `scratchpad/api35/` and checked `$PWD` before any write, `git init` or commit. The code came from `git archive f3c9ebb` or `git show f3c9ebb:scripts/dev-cycle.sh`. Every process ran under `timeout`. Afterwards `git status --short` was empty in both worktrees, except for this report, and no process is left running.

## Baseline Conventions

- **Check-mode output vocabulary.** Each check mode prints `ok …`, `skip <arg>: <reason>` or a mode-specific verdict. The skill uses the same words ("prints a skip", "printed a skip": `SKILL.md:339`, `:379`).
- **Reason grammar.** A refusal prints as `line N [of F] <verb phrase>, so … is not read`. Each `oddwhy` text is a verb phrase (`scripts/dev-cycle.sh:327-336`).
- **Help style.** Each check mode's help entry lists its skip causes in plain words and names no internal identifier. Before this round, `--check-answer` (`:55-64`) was the only full list. Pass 34's F2 asked `--check-brief` to follow it.
- **Decision-log style.** A row names the rule and its exceptions, and points at the code comment that holds the full list (rows 66–69).

## Name-Pattern Audit

This round adds no flag, mode, output keyword, reason text or exported name. `opencomment`, `refdef` and `fence` are private to FENCE_AWK. The only consumer-visible change is `--check-brief`'s help list (A) and the wording in log 69 and the brief clause (B). These are audited as output strings.

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| help: `a code fence never closed or not in plain column-0 form, a line starting (after blanks) with < or leaving a <!-- open, a line starting like a link reference definition, a stray carriage return, or a byte-order mark on line 1` | help list (`--check-brief`) | the same items in `--check-answer`'s list | `scripts/dev-cycle.sh:57-62` | Consistent: the same phrases in the same order. No internal identifier (pass-34 F2 fixed). The one-line comment exception is missing; see F1 |
| log 69: `a line starting (after blanks) with <`, `a <!-- left open on its line`, `a line that starts like a link reference definition (behind any > and list markers)`, `a BOM on line 1`, `(for questions files) a question heading inside a fence` | decision-log list | help items; `oddwhy` texts; FENCE_AWK comment `:268-275` | `scripts/dev-cycle.sh:268-275`, `:327-336` | Consistent (pass-34 F3 and F4 fixed) |
| skill: `no line starting with [ that holds ]: or leaves its [ open (a link reference definition, or text that starts like one)`, `even indented` | skill brief clause | `--check-brief` help; `refdef()` | `scripts/dev-cycle.sh:292-300` | Consistent with the help's "starts like". Narrower than `refdef()` on containers and escapes; see F2 |

## Findings

#### F1. Both help lists say any line starting with `<` is refused, but a complete one-line comment is read

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:39-40` (`--check-brief` help) and `:60-61` (`--check-answer` help)
**Move:** 3 (documentation for the consumer)
**Confidence:** High (probed)
**Legibility-target:** a reader of `scripts/dev-cycle.sh --help` who is debugging a skip, or deciding whether a `<!-- note -->` line is allowed.

**Evidence** (verbatim, help): `form, a line starting (after blanks) with < or leaving a <!--` / `open, a line starting like a link reference definition, a stray`

The other three surfaces state the exception:
- the `oddwhy` text: `starts with < after any blanks (a possible raw HTML block; only a complete one-line <!-- comment --> is read)`;
- log 69: "a line starting (after blanks) with `<` (except a complete one-line comment)";
- the FENCE_AWK comment (`:270`).

Probe: a brief `# Brief` / `<!-- note -->` / `Status: open` gives `ok docs/working/briefs/2026-01-01-n.md open 9798e7e…`, and a questions file with `x <!-- a --> b <!-- c -->` reads `keep Q-014`. The help is stricter than the code, so no consumer misreads a skip. A reader of the help alone would avoid a form the reader accepts.

**Recommendation:** optional. Append "(except a complete one-line comment)" after "with <" in both lists, then recheck the `sed -n '2,74p'` range if a line is added.

#### F2. The skill's brief clause describes the `[` rule for a line starting with `[` only; `refdef()` also refuses one behind blanks, `>` or list markers, and treats an escaped `]` as no close

**Severity:** Informational
**Location:** `skills/dev-cycle/SKILL.md:337-339` (B, 2bf03da); code at `scripts/dev-cycle.sh:292-300` (A, f3c9ebb)
**Move:** 3 (documentation drift between the skill and the check)
**Confidence:** High (probed)
**Legibility-target:** the cycle agent writing a brief by following the clause, and the user who reads a brief skip.

**Evidence** (verbatim, skill): `placeholders as `NAME`, not `<name>`, even indented), no `<!--` left open on its line, no` / `line starting with `[` that holds `]:` or leaves its `[` open (a link reference definition,` / `or text that starts like one), …`

**Evidence** (verbatim, code):
```
function refdef(l) {  # also behind any number of blockquote and list markers
  sub(/^[ \t>]*/, "", l)
  while (l ~ /^([-*+]|[0123456789]+[.)])[ \t]/) { sub(/^[^ \t]+[ \t]+/, "", l); sub(/^[ \t>]*/, "", l) }
  …(remainder: the escape comment, the `[` test, `gsub(/\\./, "", l)`, and the `]:` / no-`]` return)
```

The same sentence says "even indented" for `<` but nothing similar for `[`. Probes at f3c9ebb on a brief (`# Brief` / shape / `Status: open`):

| Shape | `--check-brief` | What the clause says |
|---|---|---|
| `  [a]: /u` | skip, "starts like a link reference definition" | allowed: the line does not start with `[` |
| `- [x]: /u` | skip, same | allowed |
| `[a\]` | skip, same | ambiguous: the line has a `]`, though it is escaped |
| `- [ ] task` | `ok … open` | allowed (agrees) |

Preconditions: a brief author writes one of these shapes. The consequence is a recorded skip with its reason, and the brief keeps its slot until the line is fixed (`SKILL.md:339`), so the failure is visible and recoverable. No brief exists on any branch yet. Log 69 and the help already describe the rule correctly ("starts like a link reference definition (behind any `>` and list markers)"), so this is the skill's prose only.

**Recommendation:** optional. Write "no line starting (after blanks, `>` or list markers) with `[` that holds `]:` or leaves its `[` open (an escaped `\]` does not close it)", which mirrors "even indented" in the same sentence.

## What Looks Good

- **Pass 34's findings are closed.**
  - F1 (nested markers): `- - [x]: /u '`, `1. - [x]: /u '` and `> - - [x]: /u '` before `Q-014: [1]` each give `skip Q-014: line 3 … starts like a link reference definition …`. The brief shape `- - [x]: /u '` / `Status: done` / `'` / `Status: open` gives `skip …: line 2 starts like a link reference definition …, so the brief is not read`. At e93312d these read `keep` and `done`.
  - F2: `--check-brief`'s help now names its own causes in plain words, matching `--check-answer`'s phrases and order, and no longer names FENCE_AWK.
  - F3/F4: log 69 now says "starts like a link reference definition (behind any `>` and list markers)" and cites passes 30–34. The Pass 34 section exists at the merge 55bdb14 where the row is read; at 2bf03da alone the rubric stops at Pass 33, which is expected for a fix commit.
- **Escape handling reads as CommonMark or refuses.** `[a\]`, `[a\\]: /u` and `[a\\\]` are refused. `[a\\]` (an escaped backslash, then a real close, then no colon) and `\[a]: /u` read `keep`, which is the CommonMark reading: neither is a definition.
- **`split()` under mawk 1.3.4.** A line that is only `<!--` is refused as html (it starts with `<`). `x <!--` and `x <!-- a --> b <!--` are refused as an open comment. `x <!-- a --> b <!-- c -->` and `x <!--<!---->` read as text, which matches CommonMark: the comment closes at the first `-->`. A 1.8 MB line holding 200,000 `<!-- -->` pairs took 46 ms end to end, so the check is linear.
- **The early return in `fence()`.** After a refusal, every later line returns 1 and is skipped. Both END blocks print `odd` before `unbalanced`, `quoted` or `dup`, so a frozen `infence` or a later quoted heading cannot change the output. Probe: `<x>` / a fence / `### Q-014 x` gives the `<` skip at line 3. The comment ("nothing after it is read") is accurate.
- **Reason texts, help, comments and log 69 agree item by item**, apart from F1's exception: fence, html, comment, refdef, cr and bom, plus "never closed" and the questions-only heading-in-fence cause. The `--help` range `2,74p` ends exactly at the last header line ("…Printed repo text is data."); line 75 is blank.
- **The skill's final message** (`SKILL.md:379`) says "printed a skip, with its reason", matching the output grammar. The brief clause's consequence ("prints a skip … keeps its slot until it is fixed") matches the slot rule at `:85-87` and log 69. "even indented" is accurate: `   <name>` is refused.
- **`--check-answer` against the real answer lines.** All IDs in `questions{,-archive}.md` were run on all 9 local branches and in the three working trees (12 file sets), at f3c9ebb. There were 0 skips; for example, main gave 23 keep, 19 drop, 3 done, 12 open and 42 unrecognized. The /workspace checkout's readings are byte-identical to e93312d's. Sampled readings match their first answer lines, for example `Q-009 drop :: **Answered 2026-09-17: [2] — …`, `Q-085 done :: **Answered 2026-09-28: [3] ~400 code lines…` and `Q-026 keep :: **Answered 2026-09-20: [1].**`. The sampled `unrecognized` entries (Q-001–Q-004) have no answer line, which is the help's "no answer line was found" case.
- **Tests and lint.** On an archive of f3c9ebb, `bats test/scripts/dev-cycle.bats` passes 49/49, and `python3 scripts/hermeticity-lint --root .` is clean (126 files). The bats literal `'[a\]b]: /u'` is now a real escaped bracket, and the new `'[a\]'` and nested-prefix cases cover both pass-34 roots.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| F1 | Both help lists omit the complete one-line `<!-- … -->` exception that `oddwhy`, log 69 and the FENCE_AWK comment state | Informational | `scripts/dev-cycle.sh:39-40`, `:60-61` | High |
| F2 | The skill's `[` clause covers only lines starting with `[`; `refdef()` also refuses one behind blanks, `>` or list markers, and one whose only `]` is escaped | Informational | `skills/dev-cycle/SKILL.md:337-339` | High |

## Overall Assessment

The pass-34 fix round is consistent across every surface it touched. Both container roots (nested list markers, an escaped-only `]`) now refuse on both readers. The `--check-brief` help lists its causes in the same plain words as `--check-answer`. Log 69 and the code agree item by item. Real answer lines on every branch read exactly as before, with no skips. The two remaining items are Informational wording gaps where the documentation is stricter (F1) or narrower (F2) than the code. Neither lets a reader get a wrong reading. Each fails safe, as a skip or as authoring guidance that avoids an accepted form. Nothing at Minor or above was found, so from the API-consistency side this pass has no known issues that block the clean-pass run.

## Goal-Alignment Note

Success criterion (verbatim): "a markdown report saved at the path your role instructions give, structured per your skill file."

This report is saved at `/workspace/.claude/wt-digest/docs/reviews/api-consistency-review-2026-10-02-digest-pass35.md` with first line `Commit: f3c9ebb (A) / 2bf03da (B)`. It follows the skill's structure: title, header, Baseline Conventions, Name-Pattern Audit, Findings, What Looks Good, Summary Table, Overall Assessment. Each finding carries Severity, Location, Evidence (verbatim), Confidence and Legibility-target. Neither finding is naming-shaped, so neither needs a precedent line. Nothing was committed, and nothing outside the scratch dir was written except this file.
