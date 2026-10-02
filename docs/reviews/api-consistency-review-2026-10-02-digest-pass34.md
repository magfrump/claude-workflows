Commit: e93312d (A) / 823f494 (B)

# API Consistency Review — dev-cycle pass 34 (the pass-33 fix round)

**Scope:** A: `git diff fd22d29..e93312d -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` (worktree `wt-digest`); B: `git diff 5085e64..823f494 -- skills/dev-cycle/SKILL.md docs/decisions/log.md` (worktree `wt-devcycle`, merge ba93f23). Partial scope: everything else is context only.
**Date:** 2026-10-02
**Based on:** Stage-1 context `docs/reviews/code-fact-check-report-digest-pass33.md` (loop pass 33's k=1 fact-check) and the pass-33 rubric section.
**Acceptance bar applied:** the fence reader gives the CommonMark reading or refuses, except decision log 69's accepted inline class. Refusing a file CommonMark would read is the design's cost unless a real file is hit.

Surfaces checked: the `oddwhy` reason texts, `--help` (lines 2–71), the FENCE_AWK / check_brief / ANSWER_AWK comments, the skill's brief clause and final message against `--check-brief`, decision log row 69 against the code and the skill, and `--check-answer` against the real answer lines.

Probes: each one was a single `set -eu` script that made its own `mktemp -d` dir under `scratchpad/api34/` and checked `$PWD` before any write or commit. Every process ran under `timeout`. Afterwards `git status --short` was empty in both worktrees, and no process is left running.

## Baseline Conventions

- **Check-mode output vocabulary.** Every check mode prints `ok …`, `skip <arg>: <reason>`, or a mode-specific verdict (`absent`, `keep|drop|done|open|unrecognized`). The skill uses the same words ("prints a skip", "`--check-path` skips"), at `skills/dev-cycle/SKILL.md:85-88`, `:298`, `:338`, `:378`.
- **Reason grammar.** A refusal prints as `line N [of F] <verb phrase>, so … is not read`. Each `oddwhy` text is a verb phrase that completes the sentence: "opens an HTML comment …", "holds a carriage return …", "starts with a byte-order mark", "is a fence-like line …" (`scripts/dev-cycle.sh:320-329`).
- **Help style.** Each check mode's help entry lists its skip causes in plain words. `--check-answer` (lines 51–60) is the fullest list. No other help entry names an internal identifier: the only cross-references are to files and to question IDs ("scripts/questions.sh header; Q-074").
- **Decision-log style.** Each row names the rule and its exceptions, and points at the code comment that holds the full list (`docs/decisions/log.md` rows 66–69).

## Name-Pattern Audit

This round adds no flag, mode, output keyword or exported name. The awk functions `opencomment` and `refdef` are private to FENCE_AWK. The only consumer-visible strings that changed are two reason texts and the help list. They are audited here as output values.

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| reason `starts with < after any blanks (a possible raw HTML block; …)` | skip reason | `starts with a byte-order mark`, `opens an HTML comment that does not close on the same line`, `holds a carriage return that does not end it` | `scripts/dev-cycle.sh:320-329` | Consistent: a verb phrase that completes "line N of F …" |
| reason `starts like a link reference definition (its label or title can span lines)` | skip reason | same three | `scripts/dev-cycle.sh:320-329` | Consistent in grammar. Scope wording: see F3 |
| help `a line starting like a link reference definition`, `a byte-order mark on line 1`, `a line starting (after blanks) with < or leaving a <!-- open` | help list item | the other `--check-answer` causes (`a duplicate heading`, `a question heading inside a fence`) | `scripts/dev-cycle.sh:51-60` | Consistent. Each item matches an `oddwhy` reason |
| skill wording `printed a skip` | skill prose | `prints a skip` (`:338`), `the check skips` (`:87`), `` `--check-path` skips `` (`:88`) | `skills/dev-cycle/SKILL.md` | Consistent: replaces the last "refused" in the final message |

## Findings

#### F1. A reference definition behind two list markers is read, but log 69, the help and the code comment say it is refused

**Severity:** Inconsistent (the documented contract and the code disagree on an input outside the accepted class; no consumer breaks today)
**Location:** `scripts/dev-cycle.sh:288-294` (`refdef`); contract at `docs/decisions/log.md` row 69, `scripts/dev-cycle.sh:56-57` (help), `:268` (FENCE_AWK comment)
**Move:** 3 (consumer contract), 8 (the contract's stated domain)
**Confidence:** High on the code's behaviour (probed). Medium-High on the CommonMark reading: no CommonMark parser is installed (no egress), so this rests on the spec. It is the same mechanism pass 33 fixed one level shallower (A2): a list item's paragraph takes lazy continuation lines, and a reference definition is parsed out of that paragraph, so its title can span those lines.
**Legibility-target:** the user reading decision log 69 ("refuse a file on anything else they do not model"), and a reviewer trusting the help's refusal list.

**Evidence** (verbatim):

```
function refdef(l) {  # also behind blockquote markers and list markers
  sub(/^[ \t>]*/, "", l)
  if (l ~ /^([-*+]|[0123456789]+[.)])[ \t]/) { sub(/^[^ \t]+[ \t]+/, "", l); sub(/^[ \t>]*/, "", l) }
  …(remainder: the two-line comment and the return of `[`-start with `]:` or no `]`)
```

Log 69: "a link reference definition (also behind `>` or a list marker)". The code strips exactly one list marker, so a second marker is left in front of the `[`.

Probe results at e93312d. Each questions file was `### Q-014 · t` / an ANSWERED header / the shape below.

| Shape (line 4 onward) | `--check-answer Q-014` |
|---|---|
| `- - [x]: /u '` / `Q-014: [1]` / `'` | `keep Q-014` |
| `1. - [x]: /u '` / `Q-014: [1]` / `'` | `keep Q-014` |
| `> - - [x]: /u '` / `Q-014: [1]` / `'` | `keep Q-014` |
| `- [x]: /u '` / `Q-014: [1]` / `'` (one marker, the pass-33 fix) | `skip Q-014: line 4 … starts like a link reference definition …` |

The brief side behaves the same way. `# Brief` / `- - [x]: /u '` / `Status: done` / `'` / `Status: open` gives `ok docs/working/briefs/2026-01-01-n.md done fef1c08…`. CommonMark hides line 3 in the definition's title and reads `Status: open`.

Preconditions: someone writes a nested-list reference definition whose title spans lines in a questions file or brief. No real file does (see What Looks Good). This is block structure, not one of log 69's inline constructs, so it is inside the acceptance bar.

**Recommendation:** strip container prefixes in a loop until no `>` or list marker remains, e.g. `while (l ~ /^[ \t>]/ || l ~ /^([-*+]|[0123456789]+[.)])[ \t]/) { sub(/^[ \t>]*/, "", l); if (l ~ /^([-*+]|[0123456789]+[.)])[ \t]/) sub(/^[^ \t]+[ \t]+/, "", l) }`. Add `- - ` and `1. - ` to the bats prefix loop at `test/scripts/dev-cycle.bats` (the `for pre in '- ' '> ' '1. '` block). Log 69's "a list marker" then becomes "list markers".

#### F2. `--check-brief`'s help names the internal `FENCE_AWK` and points to a list that holds answer-only causes

**Severity:** Minor
**Location:** `scripts/dev-cycle.sh:37-38` (help, printed by `--help`)
**Move:** 2 (vocabulary against the grain), 3 (documentation for the consumer)
**Confidence:** High
**Legibility-target:** a reader of `scripts/dev-cycle.sh --help` (the skill author, or the user debugging a brief skip) who has not read the source.

Precedent: help entries state their skip causes in plain words and name no internal identifier, as in `scripts/dev-cycle.sh:51-60` (`--check-answer`), `:23-25` (`--check-path`) and `:41-45` (`--check-branch`)

**Evidence** (verbatim): `#             including a brief FENCE_AWK refuses (as for --check-answer,` / `#             naming the line and the reason).`

`--help` prints lines 2–71 with the `# ` stripped, so a user sees "a brief FENCE_AWK refuses". FENCE_AWK is a shell variable that holds awk code, and the help never introduces it. The pointer "as for --check-answer" sends the reader to a list that includes causes that cannot apply to a brief: "no such entry", "a duplicate heading", "a question heading inside a fence" and "a questions file that is not plain". The pass-33 fix replaced the old wording ("fences cannot be trusted") for accuracy, which was correct, but it swapped one opacity for another. The skill's brief clause (`SKILL.md:335-339`) already states the brief-side list in plain words.

**Recommendation:** replace the phrase with the brief-side causes, for example: "including a brief with a fence-like line that is not a plain column-0 fence, a fence never closed, or, outside fences, a line starting (after blanks) with <, a <!-- left open, a line starting like a link reference definition, a stray carriage return or a byte-order mark on line 1 (naming the line and the reason)". Then recheck the `sed -n '2,71p'` range.

#### F3. Three surfaces describe a narrower reference-definition refusal than `refdef()` applies

**Severity:** Informational
**Location:** `docs/decisions/log.md` row 69 ("a link reference definition"), `skills/dev-cycle/SKILL.md:337-338` ("no link reference definition"), `scripts/dev-cycle.sh:268` (FENCE_AWK comment: "a link reference definition")
**Move:** 3 (documentation drift)
**Confidence:** High
**Legibility-target:** a brief author following the skill's clause, and the user reading log 69.

**Evidence** (verbatim, `scripts/dev-cycle.sh:291-293`): `# Any line starting [ that holds ]: (an escaped ] in the label too) or never` / `# closes its [ (a label that continues on the next line) counts.` / `return substr(l, 1, 1) == "[" && (index(l, "]:") || !index(l, "]"))`

The help and the `oddwhy` text say "starts like a link reference definition", which is accurate. The other three surfaces say "a link reference definition". Two kinds of line that are not definitions are therefore refused without the skill's clause warning about them:

- a hard-wrapped line that begins with a link's text, e.g. `[long link text that`;
- a task-list row with a later `]:`. Tracked examples: `workflows/codebase-onboarding.md:356` (`- [ ] Otherwise, the section contains one `[NNN]: <Goal line text>` row …`) and `workflows/spike.md:235`.

Neither kind occurs in any questions file or brief on any branch, so this is the design's cost and not a defect. The finding is only about the wording.

**Recommendation:** when F1's log edit is made, write "a line starting like a link reference definition (also behind `>` or list markers)" in log 69. Optionally add "or a line starting with `[` that does not close it" to the skill's clause.

#### F4. Log 69's references column still cites only passes 30–32

**Severity:** Informational
**Location:** `docs/decisions/log.md` row 69, last column
**Move:** 3
**Confidence:** High
**Legibility-target:** a future reader tracing why the refusal list has its current shape.

**Evidence** (verbatim): `` `scripts/dev-cycle.sh` FENCE_AWK comment; rubric `docs/reviews/code-review-rubric-2026-09-29-feat-dev-cycle-digest.md` passes 30–32 ``

The pass-33 round changed the row's rule (the container prefixes, the skip consequence, PI/CDATA/declarations). The rubric section that explains those changes is "Pass 33".

**Recommendation:** "passes 30–33" (or 30–34 after this round).

## What Looks Good

- **Reason texts and help agree one-to-one.** Each `--check-answer` help item (`:51-60`) maps to an `oddwhy` text or a caller-printed skip: the fence, html, comment, refdef, cr and bom reasons, plus unbalanced, quoted, dup, no-entry and not-plain. "after blanks" matches `rawhtml`'s `^[ \t]*<`. "a byte-order mark on line 1" matches `NR == 1`. "leaving a <!-- open" matches `opencomment` on the last `<!--`. The `--help` range `2,71p` ends exactly at the last header line (line 71; line 72 is blank).
- **Comments no longer say "fences cannot be trusted" for refusals that are not about fences.** The check_brief comment (`:331-333`) and the ANSWER_AWK comment (`:413-415`) point to the FENCE_AWK comment, which does list every reason, including the fence still open at the end. The FENCE_AWK limit paragraph names PI, CDATA and declarations, as log 69 does, and the two lists match word for word. As e93312d says, a line *starting* with any of the three is already refused by `rawhtml`.
- **The skill's brief clause matches `--check-brief`.** Plain column-0 fences, then, outside fences: `<`, an open `<!--`, a reference definition, a CR and a BOM. The consequence ("prints a skip … keeps its slot until it is fixed", `:338-339`) matches the slot rule at `:85-87`. The clause is stricter than the code in two places (it permits only ``` fences, and forbids any line starting with `<`), which is safe authoring guidance. Apart from F1 and F3, the clause is correct and complete for the brief side.
- **The final message says "printed a skip".** This matches the script's output and the rest of the skill; no "refused" remains for check output in the skill.
- **Decision log 69's skip consequence matches the skill.** "a keep-or-drop ID stays off `Applied:` and blocks a new question" matches `SKILL.md:298-299` (stays off `Applied:`) and `:300-302` (step 3 waits while an `Asked:` ID is "still `open` or skipped"). "a refused brief keeps its slot" matches `:87` and `:339`. The row defines "refuses" as "a skip" in its own parenthesis, so its vocabulary is self-consistent. Apart from F1, F3 and F4, the row is correct and complete against the code.
- **`--check-answer` against the real answer lines.** At e93312d, `--check-answer` ran over all 99 IDs in `/workspace/docs/working/questions{,-archive}.md`: 23 keep, 19 drop, 3 done, 12 open, 42 unrecognized, 0 skip. The keep/drop/done results were checked by eye against each entry's first `Q-NNN:` or `**Answer…` line, for the roughly 45 that the probe printed (output was capped, so a few may be missing) (e.g. `Q-040 drop :: **Answered 2026-09-20: [2] with escalation.**`, `Q-019 done :: **Answered 2026-09-18 (…):** done, …`). None disagrees.
- **Real files on every branch.** FENCE_AWK at e93312d ran over `questions.md` and `questions-archive.md` on all 9 local branches and in the three working trees, and refused none. No branch holds a brief yet.
- **Tests and lint.** On an archive of e93312d: `bats test/scripts/dev-cycle.bats` passes 49/49, and `python3 scripts/hermeticity-lint --root .` is clean (126 files).

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| F1 | A reference definition behind two list markers (`- - [x]: …`, `1. - [x]: …`, `> - - [x]: …`) is read on both readers; log 69, the help and the comment say it is refused | Inconsistent | `scripts/dev-cycle.sh:288-294` | High (code) / Medium-High (CommonMark, from the spec) |
| F2 | `--check-brief` help names internal `FENCE_AWK` and points to `--check-answer`'s list, which holds answer-only causes | Minor | `scripts/dev-cycle.sh:37-38` | High |
| F3 | Log 69, the skill's clause and the FENCE_AWK comment say "a link reference definition"; `refdef()` refuses any `[`-start line holding `]:` or no `]` | Informational | log row 69; `SKILL.md:337-338`; `dev-cycle.sh:268` | High |
| F4 | Log 69's references column cites passes 30–32, not 33 | Informational | `docs/decisions/log.md` row 69 | High |

## Overall Assessment

The pass-33 round made the refusal surfaces consistent: reason texts, help, comments, the skill's brief clause and decision log 69 now use the same vocabulary ("skip", "starts like", "after blanks", "line 1"). Each reason the help lists matches a code path, and real answer lines read as before. One gap remains in the contract, F1. The container strip handles one list marker, but the documented rule ("refuse … anything else they do not model", "a link reference definition") covers nested list markers too, and both readers read text there that CommonMark hides. The fix is a loop in `refdef` plus two test prefixes, the same fix as pass 33's A2 one level deeper. F2 is a help-wording fix, and F3 and F4 are wording-only. Consumer impact is low: no real file has any of these shapes. But F1 is a known issue that is not in log 69's accepted class, so this pass is not clean.

## Goal-Alignment Note

Success criterion (verbatim): "a markdown report saved at the path your role instructions give, structured per your skill file."

This report is saved at `/workspace/.claude/wt-digest/docs/reviews/api-consistency-review-2026-10-02-digest-pass34.md` with first line `Commit: e93312d (A) / 823f494 (B)`. It follows the skill's structure: title, header, Baseline Conventions, Name-Pattern Audit, Findings, What Looks Good, Summary Table, Overall Assessment. Each finding carries Severity, Location, Evidence (verbatim), Confidence and Legibility-target. F2 is the only naming-shaped finding and carries a `Precedent:` line. Nothing was committed, and nothing outside the scratch dir was written except this file.
