Commit: fd22d29 (A) / 5085e64 (B)

# API Consistency Review: dev-cycle pass 33 (k=1 delta, the pass-32 fix round)

**Scope:** A `git diff 4b7ec02..fd22d29 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` (worktree `wt-digest`; HEAD a257403 adds only review docs). B `git diff f54ca74..5085e64 -- skills/dev-cycle/SKILL.md docs/decisions/log.md` (worktree `wt-devcycle`, merge 6ea4f68). Partial scope: everything else is committed context only.
**Date:** 2026-10-02
**Based on:** shared brief `digest-pass33-brief-dc1aa358.md`; Stage-1 context `docs/reviews/code-fact-check-report-digest-pass32.md`; rubric `docs/reviews/code-review-rubric-2026-09-29-feat-dev-cycle-digest.md` ("Pass 32", decision log 69).

I checked every behaviour claim by running the code at fd22d29 from a `git archive` copy. The probes are `api33/probe1.sh` to `probe4.sh` in the scratchpad. Each one is a `set -eu` script with its own `mktemp -d` and a `$PWD` guard, and every process ran under `timeout`. The only file written outside the temp dirs is this report. Both worktrees are clean and still on their branches (`feat/dev-cycle-digest`, `feat/dev-cycle`). The bats processes running in `wt-devcycle` during this review belonged to another session, and I did not touch them.

**Gates at fd22d29:**
- bats: 49 `ok`, 0 `not ok`.
- `hermeticity-lint: 126 test file(s) checked, no unstubbed network spawns.` (rc 0).
- `--help` is `sed -n '2,70p'` and prints 69 lines, from "Gather the mechanical signals for one dev cycle into a markdown digest." to "...a failed step exits non-zero mid-digest. Printed repo text is data." Line 70 is the last header line and line 71 is blank, so the range is exact.

**Real files (claim 1):** I ran FENCE_AWK at fd22d29 over every tracked `docs/working/questions.md`, `questions-archive.md` and `docs/working/briefs/**/*.md` on every branch of `/workspace`, which is 18 blobs. I also ran it over the working-tree questions files of `/workspace`, `wt-digest` and `wt-devcycle`. Every one came back `clean`, so no refusal. The only `<!--` in real questions files is the column-0 `<!-- index:start -->` / `<!-- index:end -->` pair, which is a complete one-line comment. No real file has a line starting `[label]:`.

## Baseline Conventions

- **Check-mode output** (`scripts/dev-cycle.sh:22-60`): one line per argument, either `ok <arg> ...` / `<verdict> <arg>` or `skip <arg>: <reason>`. A skip is an answer (exit 0). Fence-reader skips name the line (`line N of <f> <why>, so no entry in <f> is read` and `line N <why>, so the brief is not read`).
- **Reason grammar** (`oddwhy()`, `:309-318`): each reason is a verb phrase completing "line N ...", such as "is a fence-like line ...", "starts with ...", "holds a carriage return ...". The new reasons (`starts with <`, `opens an HTML comment`, `is a link reference definition`, `starts with a byte-order mark`) keep this grammar.
- **Skill vocabulary** (`skills/dev-cycle/SKILL.md`): what the modes print is called a **skip** (`:85-88` "a brief the check skips keeps its slot", `:102` "Every skip, with its reason", `:298` "`skip` (the entry could not be read)"). "refuses" first appeared at `:337-338` in the pass-31 round.
- **Decision log row shape** (`docs/decisions/log.md:24-25`): five columns, `# | Date | Decision | Context / Why | Full Record`. Rows 67 and 68 put references rather than a record link in the last column.

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `line N [of f] starts with < (a possible raw HTML block; only a complete one-line <!-- comment --> is read)` | skip reason | `is a fence-like line that is not a plain column-0 fence`; `holds a carriage return ...` | `scripts/dev-cycle.sh:311-316` | Consistent. Matches `rawhtml()` exactly (`/^[ \t]*</`, leading blanks allowed). Closes api32 F2 |
| `opens an HTML comment that does not close on the same line` | skip reason | same siblings | same | Consistent shape. Accurate for the first `<!--` on the line. Slightly off for a code-span `<!--` and for `<!-->` (F4) |
| `is a link reference definition (its title can span lines)` | skip reason | same siblings | same | Consistent shape. It also fires on an indented code line and a blank label (F4) |
| `starts with a byte-order mark` / `holds a carriage return that does not end it` | skip reasons | the merged pass-32 reason | same | Consistent. The split closes api32 F3 |
| `comment`, `refdef`, `bom` (reason keys); `opencomment()`, `refdef()` (awk) | private | `html`, `cr`, `fence`; `rawhtml()`, `fenceish()`, `opens()`, `closes()` | `scripts/dev-cycle.sh:279-317` | Private, and consistent: one word per key, which `read -r _ n why` needs; `fence` is already both a key and a function |
| B: "no line starting with `<` (write placeholders as `NAME`, not `<name>`), and no link reference definitions or stray carriage returns" | skill phrase | `--check-answer` help `:57-59` | `scripts/dev-cycle.sh:57-59` | Mostly consistent. It omits an open inline comment and a BOM, and its subject is "code" (F3) |
| B: "marking any `--check-brief` refused, with its reason" | skill phrase | "a brief the check skips keeps its slot" | `skills/dev-cycle/SKILL.md:85-87`, `:298` | Inconsistent verb: the script and most of the skill say "skip" (F5) |
| B: decision log row 69 | log row | rows 67, 68 | `docs/decisions/log.md:90-92` | Five columns, consistent shape. Two content slips (F2) |

## Findings

#### F1. Two shapes the code comment, the help and row 69 say are refused are still read: a second `<!--` on a line, and a link reference definition behind a list marker or `>`

**Severity:** Inconsistent. The documented contract has three places, and all of them say both shapes refuse:
- the FENCE_AWK comment: "one that opens an HTML comment it does not close, a link reference definition";
- the help: "opening an unclosed comment, a link reference definition";
- row 69: "an unclosed inline comment, a link reference definition".

The code gives a wrong `drop` with no refusal. This is not Breaking, because no real file has either shape (checked above). Preconditions: an ANSWERED entry or a brief contains a line outside fences that either (a) closes one inline comment and opens a second, or (b) starts `- [x]: /u '` or `> [x]: /u '` with the title left open, and a column-0 answer or `Status:` line follows as lazy continuation text.

On scope: case (a) is outside the accepted class. Row 69 and the brief say an inline comment that closes later is refused. Case (b) is a block construct (a reference definition), not an inline one. Its title spanning lines is the reason the refdef refusal exists, so I count it as in scope. The user may instead decide it falls under "link title" in the accepted class.

**Location:** `scripts/dev-cycle.sh:282` (`opencomment`: checks only the first `<!--`), `:283` (`refdef`: anchored at `^[ \t]*\[`), contract at `:57-58`, `:264-267` and `docs/decisions/log.md:92`.
**Move:** 3 (consumer contract: documented behaviour vs code)
**Confidence:** High that it reproduces. High on the CommonMark reading of (a): spec §6.6, an inline comment runs from `<!--` to the next `-->` across line endings. Medium on (b): spec §4.7 reads a definition from paragraph content, and lazy continuation lines join the list item's or block quote's paragraph. No renderer is installed, so I could not run one.
**Legibility-target:** agent acting on keep/drop/done; maintainer reading the comment as the contract

**Evidence (verbatim):** probe `api33/probe1.sh`. Each case is one ANSWERED entry whose body is the first line shown, then `Q-1: [2]`, then a closing line:

| Case | Lines | CommonMark | fd22d29 prints |
|---|---|---|---|
| second-comment | `a <!-- x --> b <!--` · `Q-1: [2]` · `-->` | `Q-1: [2]` is inside the second comment, so there is no answer (`unrecognized`) | `drop Q-1` |
| list-refdef | `- [x]: /u 'title` · `Q-1: [2]` · `'` | the definition's title takes the lazy lines | `drop Q-1` |
| quote-refdef | `> [x]: /u 'title` · `Q-1: [2]` · `'` | same | `drop Q-1` |

```
function opencomment(l,   i) { i = index(l, "<!--"); return i && !index(substr(l, i + 4), "-->") }
function refdef(l) { return l ~ /^[ \t]*\[[^]]+\]:/ }
```

**Recommendation:** Test the last `<!--` on the line instead of the first. A comment opened earlier either closed before it or contains it, so the last one is enough. Let `refdef` accept leading `>` and list-marker prefixes, for example `/^[ \t]*((>[ \t]?)|([-*+]|[0123456789]+[.)])[ \t]+)*\[[^]]+\]:/`. Add the three cases to test 49. If the user rules (b) inside the accepted class, row 69 should say "a link reference definition at the start of a line".

#### F2. Decision log row 69: "so the question is asked again" contradicts the skill, and "any fence-like line not at column 0" leaves out a refusal

**Severity:** Minor. A decision record that misstates a consequence. It has no runtime effect.
**Location:** `docs/decisions/log.md:92` (B, 5085e64)
**Move:** 3 (documentation drift)
**Confidence:** High
**Legibility-target:** future maintainer and reviewer reading the decision

**Evidence (verbatim):**
- Row 69: "The reader refuses (a skip, so the question is asked again) on any fence-like line not at column 0, …"
- The skill, which is what acts on a skip: "A `skip` (the entry could not be read) goes in the record and the final message, and the ID stays off `Applied:`, so the answer is read once the cause is fixed" (`SKILL.md:298-299`). Step 3 files a new question only when "no ID on its `Asked:` line is still `open` or skipped" (`:300-302`). A skip is therefore *not* asked again; that is the `unrecognized` path (`scripts/dev-cycle.sh:421`: "is unrecognized, and the user is asked again"). The parenthetical also has no meaning for the brief reader that the same sentence covers. A refused brief "keeps its slot" (`SKILL.md:338`).
- The code also refuses a column-0 fence-like line that does not open a fence (`fence()` `:301-302`: `opens(l)` fails, then `if (fenceish(l)) { refuse("fence"); ... }`, for example ```` ```a`b ````). The help says so ("not in plain column-0 form") and the reason text says so ("is a fence-like line that is not a plain column-0 fence"). Row 69 narrows this to "not at column 0".
- Columns: five cells (`awk -F'|'` gives NF 7, the same as rows 65 to 68), date 2026-10-02, and the Full Record cell cites the FENCE_AWK comment and the rubric, like rows 67 and 68. The shape is correct. "no real file has one" is verified above. The user's choice and its alternatives ("over chasing each shape or moving answers to a machine line") match the rubric's Pass 32 user-decision line.

**Recommendation:** Replace the parenthetical with "(a skip: the answer is left unapplied, or the brief keeps its slot, until the file is fixed)". Write "any fence-like line that is not a plain column-0 fence".

#### F3. The skill's brief-format clause omits two refusals and attaches the rules to "code"

**Severity:** Minor. A brief author who follows the clause can still write a brief that `--check-brief` refuses. The cost is a slot held by an unreadable brief until someone notices. Preconditions: a brief whose prose has a mid-line `<!--` with no `-->` after it on that line (for example, a brief about the questions index that writes `` `<!--` `` alone), or a BOM from an editor.
**Location:** `skills/dev-cycle/SKILL.md:335-338` (B, 5085e64)
**Move:** 3 (consumer contract: the skill is the brief writer's spec for what `--check-brief` reads)
**Confidence:** High (the refusals were reproduced: probe1, `2026-01-01-c.md` gives `line 2 opens an HTML comment that does not close on the same line, so the brief is not read`, and `2026-01-02-b.md` gives `line 1 starts with a byte-order mark, so the brief is not read`)
**Legibility-target:** the agent writing briefs in step 6

**Evidence (verbatim):** "Any code in a brief sits in plain column-0 ``` fences, with no indented or list-item fences, no line starting with `<` (write placeholders as `NAME`, not `<name>`), and no link reference definitions or stray carriage returns (`--check-brief` refuses a brief with those, and a refused brief keeps its slot)."

Grammatically, "with no … no line starting with `<` … no link reference definitions" qualifies "any code". In the code, those rules apply only *outside* fences: `fence()` returns at `:299` for fenced lines before `rawhtml`, `opencomment` or `refdef` run. A literal reader would ban `<html>` lines inside a fence, where they are harmless, and might miss that prose lines are the ones at risk. The clause does correctly cover placeholders, column-0 `<`, refdefs and CRs. `<name>` mid-line is not refused (the test's code-span case gives `keep Q-1`), so the `NAME` advice is safe but stricter than needed.

**Recommendation:** Split the sentence: "Code sits in plain column-0 ``` fences (no indented or list-item fences). Outside fences, no line starts with `<` (write placeholders as `NAME`), and there is no `<!--` without a `-->` after it on the same line, no link reference definition, no stray carriage return and no byte-order mark (`--check-brief` refuses …)."

#### F4. Two reason texts name a construct the line does not contain: a `<!--` inside a code span, `<!-->`, and an indented `[x]:` line

**Severity:** Informational. Refusing these lines is the design's accepted cost (the brief: "refusing a file CommonMark would read is the design's cost"). No real file has any of them. The finding is only that the printed reason misnames what it saw, and the reader of a skip line acts on that reason to fix the file.
**Location:** `scripts/dev-cycle.sh:282-283`, `:312-313`
**Move:** 4 (error message accuracy)
**Confidence:** High
**Legibility-target:** the user or agent fixing a skipped questions file

**Evidence (verbatim, probe1):**
- ``Write `<!--` to comment.`` gives `skip Q-1: line 3 of docs/working/questions.md opens an HTML comment that does not close on the same line, …`. CommonMark reads it as a code span, not a comment.
- `<!-->` gives the same reason. Under CommonMark 0.31 §6.6, `<!-->` is a complete comment. `rawhtml` lets it through because `index(l, "-->")` matches the `-->` overlapping `<!--`, and then `opencomment` refuses it.
- `    [x]: /u` (4 spaces) and `[ ]: /u` give `is a link reference definition (its title can span lines)`. The first is an indented code block and the second has a blank label; neither is a definition.
- Controls are correct: a `[x]: /u` line inside a fence gives `keep Q-1`, and `[x] not a def` gives `keep Q-1`.

**Recommendation:** Optional. Word the two reasons by trigger rather than by construct, as the `html` reason now does: "has a `<!--` with no `-->` after it on the line" and "starts like a link reference definition (`[label]:`)".

#### F5. "refused" in the final-message clause vs "skip" everywhere the script and the rest of the skill name the same outcome

**Severity:** Minor (naming).
**Location:** `skills/dev-cycle/SKILL.md:377`, also `:337-338`
**Move:** 2 (naming against the grain)
**Confidence:** Medium. A reader can probably map "refused" to "the check printed `skip`", but the clause does not say whether every brief skip counts (a bad `Status:` line, a symlink, a non-brief path) or only the fence-reader ones the brief-format clause lists.
**Legibility-target:** the agent writing the final message

Precedent: `skip` as the name for an unreadable input used in `skills/dev-cycle/SKILL.md:85-88,102,298,308` and `scripts/dev-cycle.sh:25,36,42,49,54` (help: `"skip <path>: <reason>"`)

**Evidence (verbatim):** "brief holding a slot by path (marking any `--check-brief` refused, with its reason)" vs "a brief the check skips keeps its slot (recorded) until the cause is fixed" (`:86-87`).

**Recommendation:** "(marking any that `--check-brief` skips, with its reason)". At `:337-338`, either use "skips" or keep "refuses" and add "(prints a skip)" once.

#### F6. Two comments still describe the refusal set by fences only, or list part of it

**Severity:** Minor (comment and help drift; the brief asked that the ANSWER_AWK list cover every refusal).
**Location:** `scripts/dev-cycle.sh:401-407` (ANSWER_AWK comment), `:37-38` (`--check-brief` help), `:322` (`check_brief` comment)
**Move:** 3 (documentation drift)
**Confidence:** High
**Legibility-target:** maintainer; a `--help` reader of `--check-brief`

**Evidence (verbatim):**
- `:399-400` was updated correctly: `"odd N WHY", "unbalanced N" or "quoted N" (the file cannot be trusted; N is the line, WHY the oddwhy reason)`.
- `:402-407` still lists only three causes: "Each of these makes the whole file a skip for every ID, naming the line, …: an ambiguous fence-like line, a fence still open at the end, or a "### Q-NNN " heading inside a fence … No real questions file has any of them." It leaves out `<`-lines, open comments, refdefs, CR and BOM.
- Help `:37-38`: "including a brief whose fences cannot be trusted (as for --check-answer, naming the line)". Comment `:322`: "A brief whose fences cannot be trusted (FENCE_AWK refuses it) is not read at all". BOM, refdef and comment refusals are not about fences. The `--check-answer` help (`:55-60`) enumerates them correctly.

**Recommendation:** At `:404`, write "an ambiguous fence-like line or any other line FENCE_AWK refuses (its comment lists them)". At `:37` and `:322`, write "a brief FENCE_AWK refuses (as for --check-answer, naming the line)".

## What Looks Good

- **Reason texts now state the rule.** `starts with < (a possible raw HTML block; …)` matches `rawhtml()` exactly, BOM and CR have separate reasons, and every new reason keeps the "line N <verb phrase>" grammar of its siblings. api32 F2 and F3 are closed.
- **Help and `--check-answer` contract.** `:57-59` lists every `oddwhy` key (`fence`, `html`, `comment`, `refdef`, `cr`, `bom`), and the help range `2,70` is exact.
- **The FENCE_AWK comment** states the accepted limit with its decision-log reference and its rationale, so the next reviewer can tell the class from a bug.
- **Tests.** Test 49 asserts each new reason by its exact prefix and has a positive code-span control (`keep Q-1`). The brief-side assertion moved to `starts with <`.
- **Real files.** All 18 tracked questions files and briefs on every branch, plus the three working trees, read clean, so the new refusals cost nothing today.
- **Row 69** has the right five-column shape and accurately records the user's choice and its rationale (apart from F2).
- **Skill final message** now marks refused briefs with their reason, which closes api32's open item, apart from the F5 wording.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| F1 | Second `<!--` on a line and a refdef behind `-`/`>` are read, not refused, although comment, help and row 69 say they refuse (wrong `drop`) | Inconsistent | `scripts/dev-cycle.sh:282-283` | High (repro); Medium on (b)'s CommonMark reading and scope |
| F2 | Row 69: "so the question is asked again" contradicts the skill; "not at column 0" omits the non-opening column-0 fence line | Minor | `docs/decisions/log.md:92` | High |
| F3 | Brief-format clause omits open comment and BOM, and attaches the outside-fence rules to "code" | Minor | `skills/dev-cycle/SKILL.md:335-338` | High |
| F5 | "refused" vs the established "skip" | Minor | `skills/dev-cycle/SKILL.md:377`, `:337-338` | Medium |
| F6 | ANSWER_AWK cause list and `--check-brief` help/comment still describe refusals as fence-only | Minor | `scripts/dev-cycle.sh:37-38,322,402-407` | High |
| F4 | Reason text misnames a code-span `<!--`, `<!-->` and indented/blank-label `[..]:` | Informational | `scripts/dev-cycle.sh:282-283,312-313` | High |

## Overall Assessment

The round does what it set out to do at the API surface. The skip reasons now state the rule they apply, BOM and CR are separated, the help lists every refusal, its range is exact, and no real file is refused. One behavioural gap remains (F1). The cheap refusals added for "an unclosed inline comment" and "a link reference definition" are narrower than the three places that document them: a second comment on a line, and a definition behind a list marker or `>`, still give a wrong `drop`. The second-comment case is clearly outside the accepted class. The container-refdef case is arguable. Both are fixable in place with a one-line change each. The rest is wording: row 69's consequence clause, the brief-format clause's subject and omissions, "refused" vs "skip", and two fence-only comments. No consumer breaks, because no real file has any of these shapes.

## Goal-Alignment Note

Success criterion (verbatim): "a markdown report saved at the path your role instructions give, structured per your skill file."

This report is saved at `/workspace/.claude/wt-digest/docs/reviews/api-consistency-review-2026-10-02-digest-pass33.md`, with the first line `Commit: fd22d29 (A) / 5085e64 (B)`. It follows the skill's structure: header, Baseline Conventions, Name-Pattern Audit, Findings, What Looks Good, Summary Table and Overall Assessment. Every finding carries Severity, Location, Evidence (verbatim), Confidence and Legibility-target, and the naming finding (F5) carries a `Precedent:` line. It serves the user goal by stating whether a clean pass is reached. It is not: F1 is an Inconsistent finding outside the accepted limit, at least for the second-comment case. Nothing was committed.
