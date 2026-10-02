Commit: 38578a9 (A) / c345865 (B)

# API Consistency Review: dev-cycle pass 29 (pass-28 fix round)

**Scope:** A: `git diff 366efd7..38578a9 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` (worktree `/workspace/.claude/wt-digest`). B: `git diff b73069e..c345865 -- skills/dev-cycle/SKILL.md` (worktree `/workspace/.claude/wt-devcycle`, merge 5a50016). Partial scope. Everything else is context only.
**Date:** 2026-10-02
**Based on:** `docs/reviews/code-fact-check-report-digest-pass28.md` (Stage-1 context, pass 28), plus the shared brief `digest-pass29-brief-dc1aa358.md`.
**Replication:** k=1 loop pass.

**Probe discipline.** Each probe was one `set -eu` script. It made its own `mktemp -d -p .../scratchpad/api29` dir in that same script and checked `case "$PWD"` before any `git init`, commit or write. Nested repos got the same check after their `cd`. Probes ran the script from `git show <commit>:scripts/dev-cycle.sh`, or from `git archive 38578a9`, under `GIT_CONFIG_GLOBAL=/dev/null`, with every process under `timeout`. Questions files were read with `git show` and copied into temp repos. When I finished, `git status --short` was clean in both worktrees, apart from this report. None of my processes were left running. The `bats` processes still running in `wt-devcycle/test/` and under `perf29/` belong to other sessions or critics. I wrote nothing outside `api29/` except this file. The system awk is mawk 1.3.4 20200120.

Gates at 38578a9 (from `git archive`): `bats test/scripts/dev-cycle.bats` gave 47 ok, 0 not ok. `python3 scripts/hermeticity-lint --root .` printed "126 test file(s) checked, no unstubbed network spawns." `--help` prints lines 2-66 and stops at "Printed repo text is data.", so the range bump to `2,66p` is right.

Legibility-target values: **agent** (the model running the skill acts on the text), **maintainer** (someone editing the script or tests), **user** (the human reading help, record or final message).

## Baseline Conventions

- Check modes print one line per argument: `<verdict> <arg> [fields]`, or `skip <arg>: <lowercase reason clause>`. A skip is an answer, not an error (exit 0). Precedent: `scripts/dev-cycle.sh:427-444` (`check_answer`) and `:284-308` (`check_brief`).
- `--check-answer` verdicts are `keep|drop|done|open|unrecognized`. Every way of failing to read an entry is a `skip` with a reason. The skill keys on the verdict word only: `skills/dev-cycle/SKILL.md:286-297`.
- Both `--check-brief` and `--check-answer` share `FENCE_AWK`. A change to fence semantics changes both contracts.
- The fail-safe direction is the convention the code comments and the brief state: anything ambiguous should become `skip`, `unrecognized` or `open`, never a wrong `keep`, `drop` or `done`.

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `skip Q-NNN: its heading appears only inside a code fence in <f>` | skip reason | `skip Q-NNN: more than one entry with this heading in <f>`, `skip Q-NNN: an entry with this heading in both <a> and <b>`, `skip Q-NNN: no such entry in ...` | `scripts/dev-cycle.sh:435-444` | Consistent: same `skip <id>: <clause> in <file>` shape |
| `... (counting copies inside code fences)` suffix on the dup reason | skip reason | the same dup reason without the suffix | `scripts/dev-cycle.sh:435` | Consistent: the existing prefix is kept, so the bats prefix match `skip Q-9: more than one entry` still holds |
| `fenced` (internal awk result) | internal token | `dup`, `unrecognized`, `open` | `scripts/dev-cycle.sh:422-426` | Consistent: internal only, mapped to a skip line and never printed bare |
| Help phrase "a heading only inside a code fence" | help text | "no such entry, a duplicate heading, a questions file that is not plain" | `scripts/dev-cycle.sh:54-56` | Consistent |

## Findings

#### F1. The `lead()` widening makes `--check-answer` and `--check-brief` read a CommonMark-fenced line as real, so they return a wrong `drop` or `done` where 366efd7 was correct

**Severity:** Inconsistent. This is a behavioral regression of the check modes' output contract. It would be Breaking for any repo with the shape, but no real file has it (see below).
**Location:** `scripts/dev-cycle.sh:260-264` (`lead`), `:273-276` (`closes`); the claims at `:254-257` and `:356-360`
**Move:** 3 (consumer contract), 6 (changed semantics)
**Confidence:** High that it reproduces. Medium that the shape is realistic: it needs a quoted markdown example containing an indented or list-item fence line inside an outer fence.
**Legibility-target:** agent (acts on keep/drop/done), maintainer

**Evidence (verbatim):**
```
function lead(l) {
  sub(/^[ \t]+/, "", l)
  if (l ~ /^[-*+][ \t]/ || l ~ /^[0123456789]+[.)][ \t]/) { sub(/^[^ \t]+[ \t]+/, "", l) }
  return l
}
```
`closes()` uses the same `lead()`, so a content line inside a column-0 fence closes it when the line is `    ```` (4+ spaces), `- ```` or `1. ````. CommonMark allows a closer at most 3 spaces of indentation and no list marker. The comment at `:358-360` says: "and no fenced line is read. A fence left open hides the rest of the file, which can only make an answer unreadable (skip or unrecognized), never read one from elsewhere." (The excerpt ends mid-comment; the rest, `:361-374`, concerns the header and answer line and was read.)

Probe results (`api29/p3.sh`, `p3old.sh`, `p4.sh`):

| Input (entry ANSWERED) | CommonMark | 366efd7 | 38578a9 |
|---|---|---|---|
| P1: ```` ``` ```` / `    ```` ` / `Q-1: [2]` / `    ```` ` / ```` ``` ```` / `Q-1: [1]` | keep | keep | **drop** |
| P1b: same with one indented line (unbalanced) | keep | keep | **drop**; a later entry Q-900 becomes `skip …only inside a code fence` |
| P2: ```` ```markdown ```` / `- ```` ` / `Q-1: [2]` / `- ```` ` / ```` ``` ```` / `Q-1: [1]` | keep | keep | **drop** |
| Brief x: ```` ``` ```` / `    ```` ` / `Status: done` / ```` ``` ```` / `Status: open` | open | open | **done** |
| Brief y: the list-marker variant | open | open | **done** |
| P3: an indented code block showing an opener (`    ```bash` / `    ls`), then `Q-1: [1]` | keep | keep | `unrecognized`; the rest of the file is hidden (fail-safe, but the reach is new) |

A wrong `done` from `--check-brief` sends the brief to Done (In flight check 1). A wrong `drop` sends it to Ideas with `Status: dropped`. This is exactly the outcome the round's brief rules out ("never a wrong keep/drop/done"). The tests at 38578a9 cover list-item openers (test 47's Q-15) but no fence line that is content inside another fence, so the suite stays green. No real file is affected: I grepped `questions.md` and `questions-archive.md` at 5a50016 and at `main` for indented or list-marker fence lines and found none. All IDs give identical results under 366efd7 and 38578a9: 98 IDs at 38578a9, 102 at 5a50016, 99 at `main`. No briefs exist yet on 5a50016.

**Recommendation:** Track the opener's prefix in `opens()`. Then let `closes()` strip no list marker and at most the opener's content indentation plus 3 spaces. Do not treat a line indented 4+ spaces with no list marker as an opener. Add P1, P2 and brief x/y as bats cases. If the author keeps the approximation instead, the comment at `:356-360` must stop claiming "no fenced line is read" and "never read one from elsewhere", because P1 and P2 do exactly that.

#### F2. The help's definition of `unrecognized` no longer covers an answered entry with no readable answer line

**Severity:** Minor
**Location:** `scripts/dev-cycle.sh:51-53` (help); behavior at `:422-426`
**Move:** 3 (documentation drift)
**Confidence:** High
**Legibility-target:** user, agent

**Evidence (verbatim):** the help says "unrecognized (answered, but the first answer line's text does not start with one of the options)". The END block says `else if (count) print (!answered ? "open" : done ? result : "unrecognized")`. Probe P4 (ANSWERED, no answer line) printed `unrecognized Q-1`. So did P11 (a fenced `### ` line ends the entry before the answer) and test 47's Q-21 (a fence left open). In none of these is there a "first answer line". The pass-27 wording ("no answer line starts with one of the options, or a fence in the entry is left open") covered them. The pass-28 rewrite fixed which line is read but dropped the no-line case.

**Recommendation:** Use "unrecognized (answered, but no answer line is found, or the first one's text does not start with one of the options)".

#### F3. The skill's final message does not list `closed/` briefs that read `open` or `new`, although the Rules promise it

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:91-92` (Rules), `:369-372` (final message)
**Move:** 7 (asymmetry between two instructions)
**Confidence:** High
**Legibility-target:** agent

**Evidence (verbatim):** the Rules say "a `closed/` brief that reads `open` or `new` is recorded and listed in the final message for the user to set". The final-message step says "list the new `you: judgment` entries by ID and name, any keep-or-drop answer step 6 could not read, read as `unrecognized`, or found still `open` (each with its brief), and each brief holding a slot by path". A `closed/` brief holds no slot (Rules: "unless it is under `closed/`") and has no keep-or-drop question, so none of these items covers it. An agent that follows step 7's list alone drops it.

**Recommendation:** Add "any `closed/` brief that `--check-brief` reads as `open` or `new`" to the step-7 final-message list.

#### F4. In flight membership ("the Rules' glob lists") is wider than the rule that adds missing lines ("holds a slot"), so a glob-listed done or dropped brief without a line never reaches check 1

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:269-271` (In flight), `:93-95` (line-adding rule), `:84-86` (slot rule)
**Move:** 7
**Confidence:** Medium. It needs a roadmap line that was lost or hand-edited, because every brief the cycle writes gets a line.
**Legibility-target:** agent

**Evidence (verbatim):** In flight says "items whose brief the Rules' glob lists or this cycle wrote (whatever state `--check-brief` prints, so check 1 can close it)". The Rules say "A brief that holds a slot but whose path no In flight line names (compared as text with the glob's `ok` paths) gets one". A brief under `briefs/` that reads `done` or `dropped` holds no slot, so no line is added. Check 1 then never moves it to `closed/`, and the glob keeps listing it every cycle. There is a smaller wording mismatch too: "the glob lists" includes the glob's `skip` lines, while the slot rule uses "the glob prints `ok`".

**Recommendation:** Change the line-adding rule to "A brief the glob prints `ok` for, or this cycle wrote, whose path no In flight line names gets one". Also change In flight to "the glob prints `ok` for".

#### F5. The new `fenced` skip names the symptom, not the cause, when an earlier fence that never closes hides a real entry

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:436`; the comment at `:358-360`
**Move:** 4 (error helpfulness)
**Confidence:** High
**Legibility-target:** user

**Evidence (verbatim):** `skip $a: its heading appears only inside a code fence in $f`. In P1b and P3, Q-900 is a real entry under CommonMark. It is hidden only because an earlier line opened a fence (by FENCE_AWK's reading) that never closes, and the skip line does not say where that fence opened. The skill keeps the ID off `Applied:` and blocks check 3 "until the cause is fixed" (`SKILL.md:297-300`), so the user has to find the cause. The comment's "(skip or unrecognized)" is also incomplete: a fence opened before an entry's `**Needs:**` line gives `open` (P10). That outcome is safe, but the comment does not list it.

**Recommendation:** Optionally carry the line number of the fence that is still open in the `fenced` reason (for example "…inside a code fence (opened at line N) in $f"). Add `open` to the comment's list.

#### F6. Done names the move commit, not the work's merge, when an In flight line is repointed to `closed/`

**Severity:** Informational
**Location:** `skills/dev-cycle/SKILL.md:81-83`, `:273-275`; `scripts/dev-cycle.sh:33-36`
**Move:** 3
**Confidence:** High (the pass-28 fact-check's E6 printed the move commit for a `closed/` path)
**Legibility-target:** user

**Evidence (verbatim):** "a merge commit for merged work, the branch's own commit after a fast-forward, or a later move or quoted Status line". The Rules and help now describe this honestly, and In flight defers to them ("as the Rules describe it"). For a line repointed at `closed/`, though, Done records the cycle's landing commit rather than the commit that set `Status: done`. That is consistent with the documentation but surprising in the Done list. No change is required. This is noted so the trade is deliberate.

## What Looks Good

- **The ANSWERED gate.** `split($0, fld, " · ")` takes the last `**Status:** ` field and requires it to be exactly `ANSWERED`. This matches `questions.sh`, which also splits on " · ", takes the last Status field, and its `check` treats anything other than OPEN or ANSWERED as invalid (`~/.claude/scripts/questions.sh:174-179, 269`). Under mawk with `LC_ALL=C`, the multibyte separator splits correctly. P5 (trailing `· **Answered:** …`) gives keep. `ANSWERED (by user)`, `ANSWERED.`, NBSP separators and a Status inside the Needs field all give `open`. That is the safe direction. The rule is correct and complete for the format questions.sh writes.
- **Whole-file fence tracking for headings.** A fenced copy plus a real entry gives dup, with the new suffix (P9). Only-fenced gives the new skip (P8, test 47's Q-18). A fenced `### ` line ending the entry gives unrecognized, which is fail-safe (P11). A fenced `## ` line followed by an answer gives the CommonMark keep (P12). A tab-indented `1.` list fence gives keep (P13).
- **The real ID audit.** No real questions file has an unbalanced or indented fence. All IDs give identical results at 366efd7 and 38578a9 (102 IDs at 5a50016: 3 done, 19 drop, 26 keep, 13 open, 41 unrecognized).
- **Skip-line naming.** The skip lines stay in the existing `skip <id>: <clause> in <file>` shape. The dup suffix keeps the old prefix, so nothing that matches on it breaks.
- **B, commit wording.** It is now described once, in the Rules (`SKILL.md:80-83`), and the help at `scripts/dev-cycle.sh:33-36` says the same thing. In flight check 1 defers to the Rules, and nothing else repeats "the merge that brought".
- **B, check 3 limited to `briefs/`.** The "under `briefs/`" condition (`SKILL.md:300`) agrees with the Rules' "gets no keep-or-drop question" for `closed/` briefs.
- **B, future tip-date tolerance.** Two days is correct. At one instant, local dates in UTC-12 and UTC+14 differ by at most 2, so "more than two days after today" never flags an honest clock.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| F1 | `lead()` widening reads CommonMark-fenced lines: wrong `drop`/`done` (regression from 366efd7) | Inconsistent | `scripts/dev-cycle.sh:260-276`, `:356-360` | High (repro) / Medium (realism) |
| F2 | Help's `unrecognized` omits the no-answer-line case | Minor | `scripts/dev-cycle.sh:51-53` | High |
| F3 | Final message omits `closed/` open-or-new briefs that the Rules promise to list | Minor | `skills/dev-cycle/SKILL.md:91-92`, `:369-372` | High |
| F4 | In flight membership wider than the line-adding rule; "lists" vs "prints ok" | Minor | `skills/dev-cycle/SKILL.md:269-271`, `:93-95` | Medium |
| F5 | `fenced` skip names the symptom, not the fence left open; comment omits `open` | Informational | `scripts/dev-cycle.sh:436`, `:358-360` | High |
| F6 | Done names the move commit for a repointed `closed/` line | Informational | `skills/dev-cycle/SKILL.md:81-83` | High |

## Overall Assessment

The interface additions are consistent with the existing check-mode conventions: the new skip reason, the dup suffix, the help entry and the ANSWERED gate. The B side's commit wording, its `briefs/`-only check 3 and its two-day tolerance are correct. One substantive problem remains, F1. This round's `lead()` change lets any indentation, and a list marker, close a fence, so content lines inside a fence can close it early. On inputs that 366efd7 read correctly, both `--check-answer` and `--check-brief` now return a wrong `drop` or `done`, contrary to the round's own comment and the brief's never-wrong rule. No real file triggers it today, and it can be fixed in place: bound the closer by the opener's prefix and add four tests. F2 to F4 are one-line wording fixes. Consumer impact today is nil, and the risk is latent for future questions files and briefs.

## Goal-Alignment Note

Success criterion, restated verbatim: "a markdown report saved at the path your role instructions give, structured per your skill file." This report is saved at `/workspace/.claude/wt-digest/docs/reviews/api-consistency-review-2026-10-02-digest-pass29.md`. Its first line is `Commit: 38578a9 (A) / c345865 (B)`. It follows the api-consistency-reviewer structure (header, Baseline Conventions, Name-Pattern Audit, Findings, What Looks Good, Summary Table, Overall Assessment), and every finding carries Severity, Location, Evidence (verbatim), Confidence and Legibility-target. It serves the user's goal, a clean pass before merging `feat/dev-cycle`, by surfacing one regression (F1) that should be fixed before a clean pass is declared. Nothing was committed.
