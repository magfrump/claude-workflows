Commit: fd22d29 (A) / 5085e64 (B)

# Security Review — dev-cycle pass 33 (k=1 delta: refusals for open inline comments and link reference definitions; BOM reason; brief clause; decision log 69)

**Scope:** A `git diff 4b7ec02..fd22d29 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` (wt-digest). B `git diff f54ca74..5085e64 -- skills/dev-cycle/SKILL.md docs/decisions/log.md` (wt-devcycle). Merge 6ea4f68 carries the same `dev-cycle.sh` blob (`c3f03fb`) and SKILL.md blob (`5da32ef`), checked with `git hash-object` / `git rev-parse`. wt-digest HEAD a257403 adds only review artifacts on top of fd22d29 (`git diff fd22d29 HEAD -- scripts test` is empty).
**Date:** 2026-10-02
**Based on:** `docs/reviews/code-fact-check-report-digest-pass32.md` (Stage-1 context). The accepted limit is decision log 69 (inline constructs that span lines: an open tag attribute, link title, code span or emphasis). Findings inside that class are out of scope.
**Probes:** everything is under `scratchpad/sec33/`:
- `probe1.sh`: bypass and false-refusal families for the two new refusals, read by fd22d29 and by 4b7ec02 (`probe1.log`).
- `probe2.sh`: real questions files and briefs on all 9 branches, plus worktree status (`probe2.log`).
- `harvest.sh`, `cmp.sh`, `analyze.sh`, `analyze2.sh`: every committed input from the pass 26–32 probe repos, read by fd22d29 and by 4b7ec02 (`harvest.log`, `cmp.log`, `analyze.log`, `analyze2.log`).
- `probe3.sh`, `probe4.sh`: `--help` range, bats, hermeticity lint and shellcheck on a `git archive fd22d29` snapshot.

Each probe is one `set -eu` script that makes its own `mktemp -d` under `sec33/` and checks `$PWD` before any `git init`, commit, write or `rm`. Every process ran under `timeout` and has exited. The only file I wrote outside the scratch directory is this report. `git status` of /workspace and both worktrees' questions files was clean after the probes.

## Trust Boundary Map

```
B1: [docs/working/questions*.md, working tree] → [FENCE_AWK + ANSWER_AWK, --check-answer] → [keep/drop/done/open → In flight close/keep, Applied:]
B2: [brief blob on the default branch]         → [FENCE_AWK + Status awk, --check-brief]    → [open/done/dropped → slot, Done/Ideas, git mv to closed/]
B3: [SKILL.md brief format / final message; decision log 69] → [agent writing briefs; user deciding what the reader guarantees] → [B2 input shape; the user's picture of the limit]
```

| Label | Source | Mutability | Trust per sink |
|---|---|---|---|
| S1 | questions.md / questions-archive.md text (the user, agents, quoted reviews, `questions.sh`) | runtime-mutable | UNTRUSTED for the keep/drop/done sink. Text CommonMark hides must not decide, outside the accepted class. |
| S2 | brief text on the default branch (written by the cycle; build sessions edit `Status:`) | runtime-mutable | UNTRUSTED for the Status→close/move sink |
| S3 | `FENCE_AWK`/`ANSWER_AWK` programs, `-v id` (`^Q-[0-9]+$`), `oddwhy` reason words | code-constant / validated | trusted |
| S4 | SKILL.md text, decision log 69 | deploy-time (merged) | trusted as instructions; the risk is what they claim the reader refuses |

Repo text enters through B1 and B2 and decides whether a brief closes, stays or moves. This round adds two refusals (`opencomment`, `refdef`) and splits the BOM reason from CR. The question is whether an input outside log 69's class still gets a non-CommonMark reading with no refusal. No input reaches an exec, eval, SQL or HTML sink. The reason strings go to stdout through the existing scrub.

## Findings

#### F1. The open-comment refusal checks only the first `<!--` on a line. A line whose first comment closes and that then opens a second one is not refused, and that comment hides the following lines from CommonMark while the reader reads them

**Severity:** Low (same property and calibration as pass-32 F1 and pass-31 F1/F2: the S1 writer could write the deciding line directly; the loss is "the cycle acts on what the user sees"). This is outside log 69's accepted class: the row lists "an unclosed inline comment" among the refusals, not the accepted constructs.
**Location:** `scripts/dev-cycle.sh:282` (`opencomment`), with the claims at `:57` (help: "opening an unclosed comment"), `:267` (comment: "one that opens an HTML comment it does not close") and decision log row 69 (`docs/decisions/log.md:92` in wt-devcycle: "an unclosed inline comment").
**Boundary:** B1, B2
**Move:** 11 (bypasses for every guardrail)
**Confidence:** High for the reader's output (executed). Medium-high for the CommonMark side (spec reading; no CommonMark implementation is installed in the sandbox).
**Legibility-target:** the user reading log 69, who is told inline comments are refused.

**Evidence** (verbatim):

```
function opencomment(l,   i) { i = index(l, "<!--"); return i && !index(substr(l, i + 4), "-->") }
```

`index` returns the first `<!--`. If a `-->` follows it anywhere on the line, the line passes, whatever comes after that `-->`. Inputs (`probe1.log`), each after an ANSWERED header and a blank line. The CM column is the first visible answer:

```
C1-second-comment	CM=keep	NEW=drop Q-1 	OLD=drop Q-1      'Note <!-- a --> and <!--' / '**Answer:** [2]' / '-->' / '**Answer:** [1]'
C2-codespan-then-comment	CM=keep	NEW=drop Q-1                'Note `<!-- -->` then <!--' / ...
C3-indented-lazy	CM=keep	NEW=drop Q-1                        'Para' / '    <!-- a --> <!--' / ...   (4-space paragraph continuation, not an HTML block)
C4-hide-header	CM=open	NEW=drop Q-1                            'Note <!-- a --> <!--' / ANSWERED header / '-->' / OPEN header / 'Q-1: [2]'
C5-hide-Qline	CM=keep	NEW=drop Q-1                            'x <!----> y <!--' / 'Q-1: [2]' / '-->' / 'Q-1: [1]'
B1-second-comment	CM=open	NEW=ok docs/working/briefs/2026-01-01-p.md done   '# Brief' / 'x <!-- a --> <!--' / 'Status: done' / '-->' / 'Status: open'
```

Control: `C7` (`Note <!--` alone) is refused at fd22d29, so the new check works for the one-comment case. In CommonMark the second `<!--` opens an inline comment (raw HTML; the leftmost construct wins over a later code span) that runs to the next `-->`, across the paragraph's line endings. So the deciding line in between is hidden. C4 is the worst shape: the hidden ANSWERED header makes an entry the user sees as OPEN read `drop`. In B1 a brief the user sees as `Status: open` reads `done`, which moves it to `closed/`.

**Recommendation:** Test the last `<!--` on the line instead of the first. Comments do not nest, so "a `-->` follows the last `<!--`" holds exactly when every comment the line opens also closes on it. Code spans can only add over-refusals. For example, find the last `<!--` with a loop over `index` (mawk has no reverse search), then apply the same `-->` test. Add C1, C4 and B1 to the bats test next to the `Note <!--` case.

#### F2. The link-reference-definition refusal sees only a one-line `[label]:` at the start of a line. Three CommonMark refdef shapes slip past it, and their multi-line titles hide the deciding line

**Severity:** Low (same calibration as F1). Class status: the hiding mechanism is a link title spanning lines, and "link title" is one of log 69's accepted examples. But log 69 places "a link reference definition" in the refused list, and the help and code comment say the same. So these inputs sit between the two lists. I report them so the user can place them. If log 69's "link title" is meant to include refdef titles, this reduces to wording.
**Location:** `scripts/dev-cycle.sh:283` (`refdef`), with the claims at `:57-58` (help), `:268` (comment), `:313` (reason text), and log row 69.
**Boundary:** B1, B2
**Move:** 11
**Confidence:** High for the reader's output (executed). Medium for the CommonMark side of R3/R4 (lazy continuation into a refdef paragraph, by spec reading). Medium-high for R1/R2/R5.
**Legibility-target:** the user reading log 69 and the `refdef` skip reason.

**Evidence** (verbatim):

```
function refdef(l) { return l ~ /^[ \t]*\[[^]]+\]:/ }
```

From `probe1.log` (each after an ANSWERED header and a blank line; the CM column is the first visible answer):

```
R1-multiline-label	CM=keep	NEW=drop Q-1    '[a' / "b]: /u 'title" / '**Answer:** [2]' / "'" / '' / '**Answer:** [1]'
R2-escaped-bracket	CM=keep	NEW=drop Q-1    "[a\]b]: /u 'title" / ...
R3-blockquote-lazy	CM=keep	NEW=drop Q-1    "> [x]: /u 'title" / '**Answer:** [2]' / "'" / ...
R4-listitem-lazy	CM=keep	NEW=drop Q-1        "- [x]: /u 'title" / '**Answer:** [2]' / "'" / ...
R5-paren-title	CM=keep	NEW=drop Q-1        '[a' / 'b]: /u (' / 'Q-1: [2]' / ')' / '' / 'Q-1: [1]'
B2-multiline-label	CM=open	NEW=ok ... done
```

A CommonMark label may contain a line ending (R1, R5) and backslash-escaped brackets (R2), and a definition is parsed from paragraph text. That includes a paragraph inside a block quote or list item that collects lazy continuation lines (R3, R4).

**Recommendation:** If the user wants these refused rather than accepted, three cheap additions would cover them: allow escapes in the label (`\[([^]\\]|\\.)+\]:`); refuse a line that starts (after spaces) with `[` and has no `]` on it; and accept leading `>` and list markers before the `[`. Probe2's real-file lines starting with `[` (`[confidence: high], …`, `[1] was rejected …`) close their bracket, so none would be refused. A broader "any line containing `]:`" rule would refuse real files: `questions.md:179` and `:188` on main contain `Q-081 [2]: can …` / `Q-083 [1]: host-only …`. Whichever way the user goes, name the remaining shapes in log 69.

#### F3. B: the brief-format clause lists `<` lines, refdefs and stray CRs, but `--check-brief` also refuses a mid-line unclosed `<!--` and a leading BOM

**Severity:** Informational (availability only: the skip names the line, and the final message now marks refused briefs with their reason).
**Location:** `skills/dev-cycle/SKILL.md:335-338` (5085e64).
**Boundary:** B3 → B2
**Move:** 1
**Confidence:** High (executed: `B3-open-comment-mid … NEW=skip …: line 2 opens an HTML comment that does not close on the same line`).
**Legibility-target:** the agent writing a brief in step 6.

**Evidence** (verbatim): "no line starting with `<` (write placeholders as `NAME`, not `<name>`), and
no link reference definitions or stray carriage returns (`--check-brief` refuses a brief with
those, and a refused brief keeps its slot)". A brief with `See <!-- note` (B3) follows this sentence and is refused. A comment in a brief is unlikely, and a BOM even more so.

**Recommendation:** Optionally add "or an HTML comment left open" to the clause, or say "anything `--check-brief` refuses (its skip names the line)".

#### Untested bypass candidates / class-boundary notes

- **Other inline raw HTML that spans lines** (processing instruction `x <?` … `?>`, CDATA `x <![CDATA[` … `]]>`, declaration `x <!X` … `>`). These were executed (`probe1.log` H1–H3: CM keep, reader drop, no refusal at either commit). They are inline constructs that span lines, so they fall in log 69's class by its general phrase, though the row's parenthetical names only "an open tag attribute, link title, code span or emphasis". Not a finding. If the row's list is meant to be complete, add "processing instruction, CDATA or declaration".
- No CommonMark implementation could be run (no cmark, markdown-it, commonmark.js or pandoc in the sandbox, no egress). Every CM label rests on my reading of the 0.30/0.31 spec. The reader outputs are executed.

## Endorsement Claims

- **Claim:** At fd22d29 a line whose only `<!--` has no later `-->` is refused with reason `comment`, and a `[label]:` line at line start (spaces/tabs allowed) with a bracket-free label is refused with reason `refdef`. Both are checked only outside fences and after the fence and `<` checks.
  **Location:** `scripts/dev-cycle.sh:282-283, 303-305`
  **Evidence:** executed
  **Verified:** `probe1.log` C7 (`skip … line 6 … opens an HTML comment that does not close on the same line`), B3, B5 (`is a link reference definition`), N1 (`[x]:` inside a ``` fence reads `drop`), N6 (`x <!--` inside a `~~~` fence reads `drop`); bats test 49 at fd22d29.
  **Not verified:** a `<!--` after a closed one (F1) and multi-line or container refdefs (F2), where the claim does not hold.
  **route: code-fact-check**
- **Claim:** Shapes that are not the constructs read as before: `[x] text` (no colon), `- [ ] item` / `- [x]: done`, `\[x]: y`, `[]: /u`, `a --> b <!-- c -->`, and an autolink mid-line followed by a closed comment all read `drop` at fd22d29, as at 4b7ec02.
  **Location:** `scripts/dev-cycle.sh:282-283`
  **Evidence:** executed
  **Verified:** `probe1.log` N2–N5, N8, N11.
  **Not verified:** over-refusals that are the design's cost and not findings: N7 (`` `<!--` `` in a code span), N9 (`#### Sub <!--`) and N10 (`[a b]:` followed by a line that is not a valid destination/title) are refused although CommonMark reads them.
- **Claim:** All real questions files on all 9 branches (6 distinct questions/archive pairs, 590 readings) read identically at fd22d29 and 4b7ec02, with 0 skips. No branch holds a brief under `docs/working/briefs/`.
  **Location:** `docs/working/questions*.md` on every `refs/heads/*`
  **Evidence:** executed
  **Verified:** `probe2.log`: `distinct (questions,archive) pairs=6 readings=590 skips=0 pairs-differing=0`; `brief blobs: 0`. The real files hold 4 `<!--` lines each (the `index:start`/`index:end` markers, complete one-line comments), 2 lines starting `[`, and 5 lines containing `]:` (mid-line `Q-NNN [n]:` text), none refused.
  **Not verified:** uncommitted edits in other sessions' worktrees after the probe ran (all three worktrees' questions files were clean at the time).
  **route: code-fact-check**
- **Claim:** Over every committed input from the pass 26–32 probe repos (2,040 repos, 579 distinct questions/archive pairs giving 7,774 answer readings, and 3,505 brief blobs), no reading moves from one non-skip value to another or from a skip to a non-skip between 4b7ec02 and fd22d29, and no skip changes its line number. The only changes are new refusals and reworded reasons.
  **Location:** `scripts/dev-cycle.sh` FENCE_AWK, check_answer, check_brief
  **Evidence:** executed
  **Verified:** `analyze.log` and `analyze2.log` over `cmp.sh`'s `qa.tsv`/`br.tsv`. 23 answer inputs and 4 briefs move from a reading to a skip: 15 + 2 `comment` (`Note <!--`, `x <!--`, `x --> <!--`, and also `<!-->`, `<!--->`, `> <!--`, `- <!--`), 6 + 2 `refdef` (`[a]: /u '`, `[x]: /u "`). Every other difference (83 answer, 31 brief readings) is the same skip on the same line with reworded text (`starts with <`, `holds a carriage return`, `starts with a byte-order mark`). The `<!-->`/`<!--->` and container (`> <!--`, `- <!--`) refusals cover inputs that CommonMark reads and that 4b7ec02 read correctly. They are over-refusals (the design's cost) on probe files, not real ones.
  **Not verified:** inputs outside the pass 26–32 probe repos; the CommonMark label of each new skip beyond the line shapes listed.
  **route: code-fact-check**
- **Claim:** `--help` prints lines 2–70, ending at the header's last comment line ("…Printed repo text is data."). Line 71 is blank.
  **Location:** `scripts/dev-cycle.sh:134`
  **Evidence:** executed
  **Verified:** `probe3.log` (`sed -n '70p;71p' | cat -A` shows the comment line and `$`; `--help | tail -2` ends with it).
  **Not verified:** whether a later header edit keeps the number in step (no test pins it).
- **Claim:** Splitting the BOM out of the CR test does not change which files are refused, only the reason. Both tests still run before the fence state is consulted, and the BOM test still keys on `NR == 1`, which is the file's first line because each awk call reads one file or one blob.
  **Location:** `scripts/dev-cycle.sh:294-295, 482, 337`
  **Evidence:** executed (for the first part) / read-static (the one-file-per-call part)
  **Verified:** the diff hunk; bats test 49's BOM case (`starts with a byte-order mark`); harvest (no non-skip change).
  **Not verified:** a caller passing two files to one awk (none exists at fd22d29).
- **Claim:** At fd22d29 bats `test/scripts/dev-cycle.bats` passes 49/49, `scripts/hermeticity-lint --root .` is clean, and shellcheck reports nothing on `scripts/dev-cycle.sh`. The system awk is mawk.
  **Location:** snapshot of fd22d29
  **Evidence:** executed
  **Verified:** `probe3.log`, `probe4.log` (`1..49 ok: 49 not ok: 0`; `lint rc=0`; `sc rc=0`; `/usr/bin/mawk`).
  **Not verified:** gawk/BWK awk behavior of `[^]]` (mawk parses it as intended here).
- **Claim:** Decision log row 69 has five cells, matching the table's five columns. Its refusal list matches the code's refusal kinds (fence-like, `<` except a complete one-line comment, unclosed inline comment, refdef, CR, BOM, open fence, quoted heading). Its accepted-class list matches the FENCE_AWK comment word for word ("an open tag attribute, link title, code span or emphasis").
  **Location:** wt-devcycle `docs/decisions/log.md:92`; `scripts/dev-cycle.sh:273-276`
  **Evidence:** executed (cell count: `awk -F'|' '{print NF-2}'` → 5) / read-static (wording)
  **Verified:** the row text and the comment.
  **Not verified:** the row's two refusal entries are narrower in code than in words (F1, F2).

## Primitive sweep

Primitive sweep: no dangerous primitives in scope. The diff adds two awk predicates, two `oddwhy` reason strings and a test. The reasons are fixed strings selected by an awk-chosen word (S3), passed through `read -r _ n why` and printed through the existing scrub. No repo text reaches exec, eval, a path or a pathspec in this diff.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| F1 | Only the first `<!--` is tested; a second, unclosed comment after a closed one hides answer/header/Status lines (outside log 69's class) | Low | B1, B2 | `scripts/dev-cycle.sh:282` | High (reader) / Medium-high (CM) |
| F2 | Refdef refusal misses multi-line labels, escaped brackets and lazy container refdefs; titles hide lines (between log 69's refused and accepted lists) | Low | B1, B2 | `scripts/dev-cycle.sh:283` | High (reader) / Medium (CM) |
| F3 | Brief clause omits the open-comment and BOM refusals | Informational | B3 → B2 | `skills/dev-cycle/SKILL.md:335-338` | High |

## Overall Assessment

The round does what it set out to do for the plain shapes. The single-comment and one-line-refdef cases are refused, the reasons now match their triggers, and the BOM has its own reason. No real questions file on any branch is refused or reads differently. Across 7,774 harvested answer readings and 3,505 briefs, nothing changes except new refusals and reworded reasons. Two narrow gaps remain in the new guardrails. F1 is outside the accepted class and has an exact, cheap fix (test the last `<!--` instead of the first). F2 needs the user to say whether refdef titles belong to log 69's "link title". Neither gives the S1 writer anything beyond writing the deciding line directly, which is why both stay Low. No findings beyond these within the code paths read. The endorsement claims routed above are pending execution verification by code-fact-check. Most important: fix F1 (it contradicts log 69's own refusal list), and have the user place F2.

## Goal-Alignment Note

Success criterion (verbatim): "a markdown report saved at the path your role instructions give, structured per your skill file."

This report is saved at `/workspace/.claude/wt-digest/docs/reviews/security-review-2026-10-02-digest-pass33.md`, first line `Commit: fd22d29 (A) / 5085e64 (B)`, structured per `skills/security-reviewer/SKILL.md` (Trust Boundary Map, source table, Findings with Severity/Location/Boundary/Move/Confidence plus the brief's Evidence and Legibility-target fields, Endorsement Claims with Verified/Not verified and `route: code-fact-check`, Primitive sweep, Summary Table, Overall Assessment). It serves the user goal of reaching a clean pass: F1 is the one known issue outside the accepted limit, F2 is a placement question for the user, and F3 is wording.
