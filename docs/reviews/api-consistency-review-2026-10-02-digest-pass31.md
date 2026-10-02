Commit: 6f24d91 (A) / e19f411 (B)

# API Consistency Review: dev-cycle pass 31 (k=1 delta, the pass-30 fix round)

**Scope:** A `git diff f4d27d2..6f24d91 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` (worktree `wt-digest`); B `git diff a7dfc0c..e19f411 -- skills/dev-cycle/SKILL.md` (worktree `wt-devcycle`, merge 0c45039). Partial scope: everything else is committed context only.
**Date:** 2026-10-02
**Based on:** shared brief `digest-pass31-brief-dc1aa358.md`; Stage-1 context `docs/reviews/code-fact-check-report-digest-pass30.md`; rubric `docs/reviews/code-review-rubric-2026-09-29-feat-dev-cycle-digest.md` ("Pass 30").

No pass-31 code fact-check exists yet. The pass-30 report is the Stage-1 context named by the brief. I checked every behaviour claim below by running the code at 6f24d91. All probes ran under `api31/` in the scratchpad, each a `set -eu` script with its own `mktemp -d` and a `$PWD` guard. Nothing was written outside the temp dirs except this report.

**Gates at 6f24d91** (a `git archive` copy): bats 48/48 ok. `hermeticity-lint: 126 test file(s) checked, no unstubbed network spawns.` `--help` prints lines 2-67 (66 lines), which is exactly the header from "Gather the mechanical signals..." through "...Printed repo text is data." The range is correct.

## Baseline Conventions

- **Check-mode output** (`scripts/dev-cycle.sh` header, lines 22-57): one line per argument, either `ok <arg> ...` / `<verdict> <arg>` or `skip <arg>: <reason>`. A skip is an answer (exit 0), not an error. Reasons are lower-case clauses, sometimes followed by `, so <consequence>`. Examples: `skip $a: reached through a symlink, or not a regular file`, `skip $a: $SKIP_AT is not a plain file or directory, so $f is not read`.
- **Refusal over guessing.** Across the check modes, anything the reader cannot read with certainty is a skip, and the skill records each skip and leaves its ID unapplied (`SKILL.md` In flight step 2: "A `skip` ... goes in the record and the final message, and the ID stays off `Applied:`"). Pass 30 made this the fence reader's contract. The acceptance bar is "CommonMark reading or refuse".
- **Help vs code:** each mode's help names its outputs. `--check-answer`'s help also lists its skip causes.
- **CR handling:** every line reader in the script drops a trailing CR (`sub(/\r$/, "")`, lines 308, 413, 683, 731).

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `skip <ID>: line N of <f> is a fence-like line that is not a plain column-0 fence, so no entry in <f> is read` | skip reason | `skip $a: $SKIP_AT is not a plain file or directory, so $f is not read`; pass-29 `... never closed, so nothing after it can be trusted` | `scripts/dev-cycle.sh:450`, `f4d27d2:scripts/dev-cycle.sh:442` | Consistent shape (`<cause>, so <consequence>`). Inaccurate when the line is a raw HTML start (F3). |
| `skip <ID>: the code fence opened at line N of <f> is never closed, so no entry in <f> is read` | skip reason | same siblings | same | Consistent. Closes pass-30 F2 (it names the line, and "no entry in <f>" matches the behaviour). |
| `skip <ID>: line N of <f> is a question heading inside a code fence (questions.sh archive splits entries there), so no entry in <f> is read` | skip reason | same siblings | same | Consistent |
| `skip <path>: line N is a fence-like line ...` / `the code fence opened at line N is never closed, so the brief is not read` | skip reason (`--check-brief`) | `skip $a: its first Status: line is not exactly ...` | `scripts/dev-cycle.sh:315` | Consistent. It drops "of <f>" because the path is already the skip's subject, which is right. |
| `skip <ID>: more than one entry with this heading in <f>` | skip reason (reworded) | the pass-29 text with "(counting copies inside code fences)" | `f4d27d2:scripts/dev-cycle.sh:441` | Consistent. The parenthetical went with the fenced-count path. |
| `odd N`, `unbalanced N`, `quoted N` | internal awk→shell tokens | `dup`, `unbalanced`, `fenced` | `f4d27d2:scripts/dev-cycle.sh:428-431` | Internal, never printed raw. Consistent with the `<word>` token style. The added ` N` is parsed by `${r#odd }` and similar. |
| `fenceish()`, `rawhtml()`, `fence()`, `odd`, `fline`, `qline` | awk helpers/vars | `opens()`, `closes()`, `run()`, `infence`, `quoted` | `scripts/dev-cycle.sh:268-288` | Private. Names read clearly. |
| B: "each `closed/` brief an In flight line was repointed to that reads `open` or `new`" | skill phrase | the Rules' "pointed at `docs/working/briefs/closed/<same name>` ... a `closed/` brief that reads `open` or `new` is recorded and listed in the final message" | `skills/dev-cycle/SKILL.md:88-92` | Consistent with the Rules. Applies pass-30 F4. Has a time-scope gap (F5). |

## Findings

#### F1. The plain-only fence reader still gives a non-CommonMark reading without refusing when a column-0 fence line sits inside an HTML block other than `<pre>/<script>/<style>/<textarea>`. `--check-answer` flips keep to drop, and `--check-brief` reads `done` for an `open` brief.

**Severity:** Inconsistent. It breaks the stated acceptance bar ("a wrong keep/drop/done/open on any input is a finding") and the code's own contract, which is the same class as pass-30 F1. It would be Breaking for a repo with the shape. No real file has it. Precondition: a questions file or brief that contains an HTML block (a multi-line `<!-- ... -->` comment, `<?...?>`, `<!X`, `<![CDATA[`, or a type-6/7 tag block such as `<details>`/`<div>` with no blank line before the fence) holding a column-0 ```` ``` ```` or `~~~` line.
**Location:** `scripts/dev-cycle.sh:270` (`rawhtml`), `:286`; the comment at `:255-265`; the commit message of 6f24d91.
**Move:** 3 (consumer contract), 6 (semantics differ from the documented ones)
**Confidence:** High that it reproduces (run below). High on the CommonMark reading: spec 0.31 §4.6 says an HTML block of type 2 starts at `<!--` and ends at the line containing `-->`, and type 6 ends at a blank line. A fence line inside either is raw HTML, not a fence. I could not run a CommonMark renderer (none installed, no egress). Low that the shape occurs in practice.
**Legibility-target:** agent (acts on keep/drop/done), maintainer

**Evidence (verbatim):** the comment claims "Code fences, read only in their plain form, so that every fence this reads is read the way CommonMark reads it ... and so is the start of a raw HTML block that can hold one (<pre>, <script>, <style>, <textarea>)". The commit says "where the two agree by construction" and "the cost is a skip (asked again), never a wrong reading". The code checks only type-1 starts:
```
function rawhtml(l) { l = tolower(l); return l ~ /^[ \t]*<(pre|script|style|textarea)([ \t>]|$)/ }
```
Probe `api31/p1.sh` (entry `### Q-1 · keep-or-drop-x` with an ANSWERED header, then the body lines shown):

| Case | Body (one line per item) | CommonMark reading | 6f24d91 prints |
|---|---|---|---|
| CMT2 | `<!--` · ```` ``` ```` · `-->` · `Q-1: [1]` · `<!--` · ```` ``` ```` · `-->` · `Q-1: [2]` | two comments; first answer `Q-1: [1]` → keep | `drop Q-1` |
| CMT1 | `<!--` · ```` ``` ```` · `-->` · `## Archive` · `<!--` · ```` ``` ```` · `-->` · `Q-1: [2]` | `## Archive` ends the entry; no answer line in it → unrecognized | `drop Q-1` |
| DIV1 | `<div>` · ```` ``` ```` · `</div>` · (blank) · `## Notes` · (blank) · `<div>` · ```` ``` ```` · `</div>` · (blank) · `Q-1: [2]` | `## Notes` ends the entry → unrecognized | `drop Q-1` |
| brief-cmt | `# B` · `<!--` · ```` ``` ```` · `-->` · `Status: open` · `<!--` · ```` ``` ```` · `-->` · `Status: done` | first Status line `open` | `ok ... done <commit>` |
| brief-div | `# B` · `<details>` · ```` ``` ```` · `</details>` · (blank) · `Status: open` · (blank) · `<details>` · ```` ``` ```` · `</details>` · (blank) · `Status: done` | `open` | `ok ... done <commit>` |

The reader treats the two commented fence lines as one fence (lines 6-10 in CMT2), so it hides the real answer or Status line and reads the one after. Nothing is unbalanced, odd or quoted, so nothing refuses.

**Recommendation:** Refuse any line whose first non-blank character is `<`, except a `<!-- ... -->` comment that closes on the same line. The real files' only such lines are `<!-- index:start -->` and `<!-- index:end -->` (`rg '^[ \t]{0,3}<'` over all three checkouts' questions files: nothing else; there are no real briefs), so no real file would be refused. Alternatively, track an open HTML block (a comment until `-->`, a type-6/7 block until a blank line) and set `odd` on a fence-like line inside one. Add one bats case per HTML type, and correct the comment and the "by construction" claim.

#### F2. A lone CR (a CommonMark line ending) hides a fence line from the reader, and so does a UTF-8 BOM before a first-line fence. Both give a wrong `done`/`drop` without refusing.

**Severity:** Inconsistent (same contract as F1). Preconditions: a file with a bare `\r` before a column-0 fence line (old-Mac line endings or a stray CR mid-line), or a file that starts with a BOM immediately followed by a fence. Editors rarely write either.
**Location:** `scripts/dev-cycle.sh:308`, `:413` (`{ sub(/\r$/, "") }` drops only a trailing CR); `opens()`/`fenceish()` at `:269-278` read from byte 1.
**Move:** 3, 6
**Confidence:** High for the lone CR (spec §2.1: "A line ending is a line feed (U+000A), a carriage return (U+000D) not followed by a line feed, or a carriage return and a following line feed."). Low-Medium for the BOM: cmark and GitHub strip a leading BOM, but I could not confirm that the spec text requires it.
**Legibility-target:** agent, maintainer

**Evidence (verbatim):** probe `api31/p4.sh`:
```
printf '# B\r```\nStatus: done\nx\r```\nStatus: open\n'          -> ok docs/working/briefs/2026-01-01-cr.md done
printf '\357\273\277```\nStatus: done\n```\nStatus: open\n```\n' -> ok docs/working/briefs/2026-01-01-bom.md done
questions entry body 'note\r```' / 'Q-1: [2]' / 'x\r```' / 'Q-1: [1]' -> drop Q-1
```
CommonMark splits `# B\r```` into two lines, so ```` ``` ```` opens a fence that holds `Status: done`. Its first Status line is `open`, and the questions entry's first answer is `Q-1: [1]` (keep). awk splits only on LF, so it never sees either fence.

**Recommendation:** Set `odd` (refuse) on any line that still contains `\r` after the trailing-CR strip, and strip a leading `\357\273\277` on NR==1 (or refuse it). Both are one-line additions to the shared rule, and no real questions file has a bare CR (all 3x~100 real IDs read unchanged; see What Looks Good).

#### F3. The skip for a raw HTML start calls it "a fence-like line that is not a plain column-0 fence". The help covers neither HTML nor `--check-brief`'s new refusals.

**Severity:** Minor
**Location:** `scripts/dev-cycle.sh:313`, `:456` (messages); help at `:29-37` (`--check-brief`) and `:53-57` (`--check-answer`)
**Move:** 4 (error helpfulness), 7 (asymmetry between the two modes' help)
**Confidence:** High
**Legibility-target:** user, agent

**Evidence (verbatim):** with a `<pre>` line at line 6, `--check-answer` prints `skip Q-1: line 6 of docs/working/questions.md is a fence-like line that is not a plain column-0 fence, so no entry in docs/working/questions.md is read`, and `--check-brief` prints `skip docs/working/briefs/2026-01-01-pre.md: line 2 is a fence-like line that is not a plain column-0 fence, so the brief is not read` (probe `api31/p1.sh`, cases PRE and brief-pre). A reader who opens line 6 finds `<pre>`, not a fence. The `--check-answer` help lists "a code fence never closed or not in plain column-0 form, a question heading inside a fence". It does not mention an HTML block. The `--check-brief` help still says only `from its first unfenced "Status:" line` and lists no refusal causes, although the mode now refuses on the same two conditions.
No existing precedent in `scripts/dev-cycle.sh` skip reasons (no other skip names a line or an HTML construct).

**Recommendation:** Pass the cause with the line (for example `odd = NR; oddwhy = "raw HTML block"`) and print "line N ... starts a raw HTML block that can hold a fence". Add "(or an HTML block that can hold one)" to the `--check-answer` help. Give `--check-brief`'s help the same refusal clause, for example "skip when a fence is never closed or a line is fence-like but not a plain column-0 fence".

#### F4. No test covers the raw-HTML refusal or `--check-brief`'s never-closed message.

**Severity:** Informational
**Location:** `test/scripts/dev-cycle.bats` (tests 45-48 at `:808-905`)
**Move:** 3 (test drift)
**Confidence:** High
**Legibility-target:** maintainer

**Evidence (verbatim):** `git show 6f24d91:test/scripts/dev-cycle.bats | grep -n '<pre\|<script\|<style\|<textarea\|so the brief is not read'` returns nothing. The `unbalanced` branch of `check_brief` (`:314`) and the `rawhtml` arm of `fence()` (`:286`) both work in my probes (brief-ub and PRE), but no test pins either one.

**Recommendation:** Add one `<pre>` case to test 48 and one open-fence brief to test 47, asserting the line-numbered text.

#### F5. B: "an In flight line was repointed to" has no time scope. On the "this cycle" reading, a `closed/` brief that still reads `open` is listed once and then sits in In flight unmentioned.

**Severity:** Informational
**Location:** `skills/dev-cycle/SKILL.md:371-372` (0c45039); the Rules at `:87-93`; In flight checks 1-3 at `:273-311`
**Move:** 7 (asymmetry between what In flight carries and what the final message reports)
**Confidence:** Medium. It depends on which reading an agent takes, and on the user not setting the status after the first notice.
**Legibility-target:** agent, user

**Evidence (verbatim):** the final message lists "each `closed/` brief an In flight line was repointed to that reads `open` or `new` (for the user to set its status)". Repointing happens only when `--check-path` skips the line's path (`:88-90`). Once the line names the `closed/` path, `--check-path` prints `ok`, so it is never repointed again. Check 1 moves the line only on `done`/`dropped`. Check 3 runs only "if the brief is still open and under `briefs/`". The Rules say such a brief "gets no keep-or-drop question". From the next cycle on, nothing resolves the line and, read as "repointed this cycle", nothing lists it.

**Recommendation:** Word it as "each In flight line naming a `closed/` brief that reads `open` or `new`". That repeats the reminder every cycle until the user sets the status, and it still excludes the rest of `closed/` (pass-30 F4's concern).

## What Looks Good

- **Column-0 shapes the brief named all give the CommonMark reading** (probe `api31/p1.sh`): an info string with a longer closer (`keep`); a shorter backtick line inside a 4-backtick fence (`keep`); `~~~` inside a backtick fence and a backtick line inside a tilde fence (`keep`, `keep`); a closer with an info string is content (`keep`); CRLF fences (`keep`; brief `open`); a fence open at end of file (refused, naming line 6); a `### Q-1` heading inside a fence (refused, naming line 7); a column-0 opener with a backtick in its info string (refused). Indented (1-3 and 4+ spaces), tab-indented, list-marker and ordinal fence lines are refused wherever they occur, inside or outside a fence.
- **Every earlier api probe now reads the CommonMark answer or refuses.** I reran pass-29 `p2`, `p3` and `p4` (retargeted to 6f24d91) and pass-30 `p1`, `p2`, `p3` and `p5`. Every case where 385/366/38578a9 gave a wrong `keep`/`drop`/`done` now prints a line-numbered skip. Pass-29 P11 (`### example` inside a fence) now reads `keep Q-1`, which is the CommonMark answer, where pass 29 read `unrecognized`. P4-P7, P10, P12 and P14 are unchanged and correct. The fc/sec/perf probe dirs belong to those critics. I did not rerun them.
- **Real files.** I compared all real IDs from the three checkouts (`/workspace` 99, `wt-digest` 98, `wt-devcycle` 102) between f4d27d2 and 6f24d91: 0 skips, 0 differences. pass-29 `p4`'s committed-file comparison (38578a9 / 5a50016 / main) is also identical. The commit's "No real questions file has any of these lines" holds. No real briefs exist on any branch (`git ls-tree` on main, feat/dev-cycle and feat/dev-cycle-digest), so `--check-brief` cannot refuse a real one.
- **The ANSWER_AWK comment matches the code** (`:367-391` vs `:413-445`): the token list and order (`odd` > `unbalanced` > `quoted` > `dup`), "makes the whole file a skip for every ID" (END prints them whether or not the ID is present, and `check_answer` returns before the cross-file hit check), and `qline` uses the same `^### Q-[0-9]+ ` pattern that `questions.sh` `extract_entry`/`live_without_entry` split on (`scripts/questions.sh:222-243`, `:363-370`). That rule is correct and complete for the split it guards.
- **The FENCE_AWK comment matches `opens`/`closes`/`fence`** for column-0 text, apart from the HTML-type gap in F1: "a column-0 line that neither opens nor, inside a fence, is plain content" is exactly `fenceish(l) && first char not `/~` inside, and `fenceish && !opens` outside. `fline` is the open fence's line at END because it is reassigned on every open.
- **Pass-30 F2, F3 and F5 are closed.** The never-closed skip names the line and says "no entry in <f> is read". `--check-brief` refuses an open fence the same way `--check-answer` does. The unused local `m` is gone.
- **B** applies pass-30 F4's qualifier and matches the Rules' repoint sentence word for word ("pointed at `docs/working/briefs/closed/<same name>`").

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---|---|---|---|
| F1 | A column-0 fence inside an HTML comment or type-6/7 block is read as a fence: wrong `drop`/`done`, no refusal | Inconsistent | `scripts/dev-cycle.sh:270`, `:255-265` | High |
| F2 | A lone CR before a fence line, or a BOM before a first-line fence, hides the fence: wrong `done`/`drop` | Inconsistent | `scripts/dev-cycle.sh:308`, `:413` | High (CR) / Low-Medium (BOM) |
| F3 | HTML-start skip says "fence-like line"; help omits HTML and `--check-brief`'s refusals | Minor | `scripts/dev-cycle.sh:313`, `:456`, `:29-37`, `:53-57` | High |
| F4 | No test for the raw-HTML refusal or the brief never-closed message | Informational | `test/scripts/dev-cycle.bats:808-905` | High |
| F5 | The final message's repointed `closed/` briefs are listed once, then sit in In flight unmentioned | Informational | `skills/dev-cycle/SKILL.md:371-372` | Medium |

## Overall Assessment

The redesign works for the input class it targets. Every column-0 shape gives the CommonMark reading. Every indented or list-marker shape from passes 26-30 now refuses, with a line-numbered skip consistent with the script's `<cause>, so <consequence>` style. All ~100 real IDs in each checkout read unchanged. The "agree by construction" claim is still not true, though. CommonMark has two more ways to make a column-0 fence line not a fence: an enclosing HTML block of types 2-7, and a line ending awk does not split on (a lone CR). Both give a wrong verdict with no refusal (F1, F2). Under this pass's acceptance bar, each is a finding even though no real file is affected. Both fixes fit the existing design: refuse on a `<`-start line other than a closed one-line comment, and refuse on an embedded CR. Neither would refuse a real file. The rest (F3-F5) is wording and coverage.

## Goal-Alignment Note

Success criterion, restated verbatim: "a markdown report saved at the path your role instructions give, structured per your skill file." This report is saved at `/workspace/.claude/wt-digest/docs/reviews/api-consistency-review-2026-10-02-digest-pass31.md`. Its first line is the commit line, and it has the skill's sections (Baseline, Name-Pattern Audit, Findings with Severity/Location/Evidence/Confidence/Legibility-target, What Looks Good, Summary Table, Overall Assessment). It serves the user goal (merge once a clean pass is reached): pass 31 is **not clean** at this critic, with 2 Inconsistent findings (F1, F2), 1 Minor and 2 Informational, and nothing Breaking. Both Inconsistent findings come with fixes that leave every real file readable.
