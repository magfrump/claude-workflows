Commit: 4b7ec02 (A) / f54ca74 (B)

# API Consistency Review: dev-cycle pass 32 (k=1 delta, the pass-31 fix round)

**Scope:** A `git diff 6f24d91..4b7ec02 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` (worktree `wt-digest`; HEAD b28ae48 adds only review docs, and `git diff 4b7ec02 b28ae48 -- scripts test` is empty). B `git diff e19f411..f54ca74 -- skills/dev-cycle/SKILL.md` (worktree `wt-devcycle`, merge 2080f23). Partial scope: everything else is committed context only.
**Date:** 2026-10-02
**Based on:** shared brief `digest-pass32-brief-dc1aa358.md`; Stage-1 context `docs/reviews/code-fact-check-report-digest-pass31.md`; rubric `docs/reviews/code-review-rubric-2026-09-29-feat-dev-cycle-digest.md` ("Pass 31").

Every behaviour claim below was checked by running the code at 4b7ec02 (`git show 4b7ec02:scripts/dev-cycle.sh`; old = 6f24d91). All probes live under `api32/` in the scratchpad. Each is a `set -eu` script with its own `mktemp -d` and a `$PWD` guard, and each process ran under `timeout`. Nothing was written outside the temp dirs except this report. Both worktrees are still clean and on their branches (`git status --short` is empty).

**Gates at 4b7ec02** (a `git archive` copy, probe `p8.sh`): bats 49/49 ok, rc 0. `hermeticity-lint: 126 test file(s) checked, no unstubbed network spawns.` shellcheck rc 0. `--help` prints `sed -n '2,69p'`, 68 lines, from "Gather the mechanical signals..." to "...Printed repo text is data." Line 70 is blank, so the range is exact.

## Baseline Conventions

- **Check-mode output** (`scripts/dev-cycle.sh:22-59`): one line per argument, `ok <arg> ...` / `<verdict> <arg>` or `skip <arg>: <reason>`. A skip is an answer (exit 0). Reasons are lower-case clauses, often `<cause>, so <consequence>`. Since pass 30, fence-reader skips name the line: `line N of <f> ...` for `--check-answer` and `line N ...` for `--check-brief`.
- **Refusal over guessing.** The acceptance bar is "CommonMark reading or refuse". Pass 31 counted text *hidden* from CommonMark as a wrong reading, not only fence lines. Examples: sec31 H1c, where a comment hides `**Answer:** [2]`; perf31 Q-219 and "Status inside comment, no fence".
- **Skill ↔ modes:** the skill takes state only from what the modes print. A `--check-answer` skip goes "in the record and the final message" (`SKILL.md:298`). Other skips go "in the record under `## Skipped inputs`" (`:102-103`).

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `skip <ID>: line N of <f> starts a raw HTML block (only a one-line <!-- comment --> is read), so no entry in <f> is read` | skip reason | `line N of <f> is a fence-like line that is not a plain column-0 fence, so no entry in <f> is read`; `... is a question heading inside a code fence (...), so ...` | `scripts/dev-cycle.sh:471-473` | Consistent shape. Over-claims for `<` lines that are not HTML (F2) |
| `skip <ID>: line N of <f> holds a carriage return that does not end it, or a byte-order mark, so ...` | skip reason | same siblings | same | Consistent shape. Merges two causes the code can tell apart (F3) |
| `skip <path>: line N <oddwhy>, so the brief is not read` | skip reason (`--check-brief`) | `the code fence opened at line N is never closed, so the brief is not read` | `scripts/dev-cycle.sh:328-329` | Consistent. It is the same text as `--check-answer` without "of <f>", which is right because the path is the subject |
| `odd N <why>` (`why` ∈ `fence`/`html`/`cr`) | internal awk→shell token | `odd N`, `unbalanced N`, `quoted N`, `dup` | `scripts/dev-cycle.sh:326`, `:455-459` | Internal. Parsed by `read -r _ n why`, and every `why` is one word. Consistent |
| `refuse(why)`, `oddwhy` (awk var), `oddwhy()` (shell fn) | private helpers | `fence()`, `opens()`, `closes()`, `fenceish()`, `rawhtml()`; vars `odd`, `fline`, `qline` | `scripts/dev-cycle.sh:272-303` | Private. One name for the awk variable and the shell function that renders it is readable: one feeds the other |
| B: "each In flight line naming a `closed/` brief that reads `open` or `new`" | skill phrase | Rules: "a `closed/` brief that reads `open` or `new` is recorded and listed in the final message" | `skills/dev-cycle/SKILL.md:91-92` | Consistent. Closes api31 F5 |
| B: "plain column-0 ``` fences, with no indented or list-item fences, raw HTML or stray carriage returns" | skill phrase | `--check-answer` help: "not in plain column-0 form, a raw HTML block, a stray carriage return or byte-order mark" | `scripts/dev-cycle.sh:55-58` | Consistent vocabulary. Narrower than what the code refuses (F2) |

## Findings

#### F1. Text inside a multi-line inline construct (an HTML comment, a tag attribute or a link title) or inside a multi-line link reference definition title is hidden from CommonMark, but the reader still reads it: a wrong `drop`/`done` with no refusal.

**Severity:** Inconsistent. It breaks the stated acceptance bar ("a wrong keep/drop/done/open on any input is a finding") and is the same class pass 31 counted (text hidden by a block comment: sec31 H1c, perf31 Q-219). It is not Breaking, because no real file has the shape. Preconditions: a questions entry or brief in which a line outside fences opens one of these and leaves it open across lines, and an answer, `**Needs:**` or `Status:` line sits inside it:
- an inline `<!--` with no `-->` on that line;
- `<tag attr="` with the attribute value still open;
- `[a](/u "` with the link title still open;
- a link reference definition `[x]: /u '` with its title still open.

**Location:** `scripts/dev-cycle.sh:274` (`rawhtml` fires only when `<` starts the line), `:284-295` (`fence()`), `:263-266` (comment: "anything this reader does not model"), `:440-453` (answer read), `:325` (Status read).
**Move:** 3 (consumer contract), 6 (semantics differ from the documented ones)
**Confidence:** High that it reproduces. Medium-High on the CommonMark reading, from the spec (0.31.2). §6.6 defines an HTML comment as "`<!--`, a string of characters not including the string `-->`, and `-->`", and its examples include a comment spanning a line ending inside a paragraph. §4.7 allows a link reference definition title to span lines (the `[foo]: /url '\ntitle\nline1\nline2\n'` example). No CommonMark renderer is installed and the sandbox has no egress, so I could not run one. Low that the shape occurs in practice.
**Legibility-target:** agent (acts on keep/drop/done), maintainer

**Evidence (verbatim):** probe `api32/p6.sh` and `p7.sh`. Each `--check-answer` case is one ANSWERED entry `### Q-1 · keep-or-drop-x` followed by the body shown:

| Case | Body | CommonMark reading | 4b7ec02 prints |
|---|---|---|---|
| INL-CMT | `Note <!--` · `Q-1: [2]` · `-->` · (blank) · `Q-1: [1]` | `Q-1: [2]` is inside an inline comment → keep | `drop Q-1` |
| INL-ANS | `Note <!--` · `**Answer:** [2]` · `-->` · (blank) · `**Answer:** [1]` | keep | `drop Q-1` |
| INL-ATTR | `Note <span title="` · `Q-1: [2]` · `">x</span>` · (blank) · `Q-1: [1]` | keep | `drop Q-1` |
| INL-LINK | `See [a](/u "` · `Q-1: [2]` · `")` · (blank) · `Q-1: [1]` | keep | `drop Q-1` |
| LRD-ans | `[x]: /u '` · `Q-1: [2]` · `'` · (blank) · `Q-1: [1]` | the definition consumes the first three lines → keep | `drop Q-1` |
| brief inl-cmt | `# B` · (blank) · `Note <!--` · `Status: done` · `-->` · (blank) · `Status: open` | open | `ok ... done` |
| brief inl-link | `# B` · (blank) · `See [a](/u '` · `Status: done` · `')` · (blank) · `Status: open` | open | `ok ... done` |
| brief lrd / lrd-paren | `# B` · (blank) · `[x]: /u '` (or `(`) · `Status: done` · `'` (or `)`) · (blank) · `Status: open` | open | `ok ... done <commit>` |

One case is a control, not a finding. In LRD-ans2 the hidden line was `- Q-1: [2]`, and the reader's `drop` is correct there: a bullet item interrupts the paragraph, so the definition never forms.

**Real-file cost of a fix** (probe `p5.sh` collected the 11 distinct `questions.md` / `questions-archive.md` blobs on all 9 branches of `/workspace`; `p7.sh` scanned them outside fences): 0 lines open an inline `<!--` without a later `-->`, 0 lines leave a `<tag ...` unclosed, 0 lines leave a `](... "` link title open, and 0 lines start a link reference definition. There are no briefs on any branch. A broad "any `<` + letter anywhere" rule *would* refuse real files: 5-14 lines per blob, all in code spans such as `` `Q-0NN: <your answer>` `` and `` `url.<base>.insteadOf` ``.

**Recommendation:** Extend `fence()` with narrow refusals that cost no real file. Refuse a line outside a fence that contains `<!--` with no `-->` after it. Refuse a line that starts (after up to 3 spaces) with `[label]:`, which is a link reference definition. Then either refuse a line where a `<tag` or `](` leaves a quote or paren open at line end, or name that last case in the FENCE_AWK comment as an accepted limit. That limit holds because the protocol writes answers as `Q-NNN:` lines. Add one bats case per refusal.

#### F2. The HTML refusal is wider than its wording. Any line starting with `<` after blanks is refused: an autolink, `< 3`, a `<slug>` placeholder. Yet the skip says "starts a raw HTML block", and the help and the new brief-format clause say "raw HTML". An agent following the skill can write a brief that `--check-brief` refuses.

**Severity:** Minor. The refusal itself is the design's stated cost, and no real file has such a line. The defect is that three consumer-facing texts describe a narrower rule than the code applies.
**Location:** `scripts/dev-cycle.sh:299` (`oddwhy` html text), `:57` (help: "a raw HTML block"), `:263-266` (comment: "a line outside a fence that starts with <" — the code also allows leading blanks, including 4+ spaces, which CommonMark reads as indented code); `skills/dev-cycle/SKILL.md:335-337` (f54ca74).
**Move:** 4 (error helpfulness), 3 (documentation drift: skill vs mode)
**Confidence:** High
**Legibility-target:** user (reads the skip), agent (writes briefs)

**Evidence (verbatim):** probe `api32/p6.sh`:
```
AUTO   "<https://example.com/x>"      -> skip Q-1: line 6 of docs/working/questions.md starts a raw HTML block (only a one-line <!-- comment --> is read), so no entry in docs/working/questions.md is read
LT     "< 3 items left"               -> (same text)
b-ph   "<slug>: lowercase letters"    -> skip docs/working/briefs/2026-01-01-ph.md: line 3 starts a raw HTML block (only a one-line <!-- comment --> is read), so the brief is not read
b-mail "<user@example.com> asked"     -> (same, line 3)
```
None of these lines starts an HTML block in CommonMark. An autolink or email autolink is inline, `<` followed by a space is text, and `<slug>:` is not a complete tag, which type 7 needs. The code is `function rawhtml(l) { return l ~ /^[ \t]*</ && !(l ~ /^[ \t]*<!--/ && index(l, "-->")) }`. The skill's new clause says "Any code in a brief sits in plain column-0 ``` fences, with no indented or list-item fences, raw HTML or stray carriage returns (`--check-brief` refuses a brief with those, and a refused brief keeps its slot)". A writer who keeps out "raw HTML" can still begin a line with `<placeholder>`, and that brief then holds a slot until someone fixes it.

**Recommendation:** Word the reason by the rule, not by the CommonMark category. For example: "starts with < (a possible raw HTML block; only a one-line <!-- comment --> is read)". Use the same words in the help. In the skill, say "no line outside a fence that starts with `<` (other than a one-line `<!-- ... -->` comment)". Optionally change the comment to "starts, after blanks, with <".

#### F3. The `cr` reason merges two causes the code tells apart: "holds a carriage return that does not end it, or a byte-order mark". The line number counts LF lines only.

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:285` (one `refuse("cr")` for both tests), `:300`
**Move:** 4 (error helpfulness)
**Confidence:** High
**Legibility-target:** user

**Evidence (verbatim):** `if (index(l, "\r") || (NR == 1 && substr(l, 1, 3) == "\357\273\277")) { refuse("cr"); return 1 }`. A BOM-only file prints `skip Q-1: line 1 of docs/working/questions.md holds a carriage return that does not end it, or a byte-order mark, so no entry in docs/working/questions.md is read` (bats test 49 asserts exactly this). A reader must check line 1 for both causes, although the code knows which one it found. For a file with lone-CR line endings, "line N" is awk's LF count, so an editor that breaks lines at CR shows a different number. The skill's brief clause names "stray carriage returns" but not a BOM.
No existing precedent in `scripts/dev-cycle.sh` skip reasons (no other reason token covers two causes).

**Recommendation:** Use `refuse("bom")` for the BOM test and give it its own `oddwhy` arm ("starts with a byte-order mark"). Optionally add "(lines counted by LF)" to the CR text.

#### F4. B: a brief that `--check-brief` refuses keeps its slot, but only the record says why. The final message lists it among the slot holders, with no skip reason.

**Severity:** Informational
**Location:** `skills/dev-cycle/SKILL.md:84-87` (slot rule), `:102-103` (skips go to the record), `:335-337` (f54ca74's new parenthetical), `:371-376` (final message)
**Move:** 7 (asymmetry: `--check-answer` skips reach the final message, `--check-brief` skips do not)
**Confidence:** Medium. It depends on whether the user reads the record.
**Legibility-target:** user

**Evidence (verbatim):** the clause says "a refused brief keeps its slot", and the Rules say "a brief the check skips keeps its slot (recorded) until the cause is fixed". The In flight step says a `--check-answer` "`skip` (the entry could not be read) goes in the record and the final message". The final message lists "each brief holding a slot by path, so the user can start any of them", and that list includes a refused brief with nothing to mark it as refused. Nothing in the skill names who fixes the cause. The cycle could fix it, since `--check-write` allows open briefs.

**Recommendation:** Add "and each brief `--check-brief` skipped, with its reason" to the final-message list. Alternatively, say in the Build-briefs clause that the cycle rewrites a refused brief it wrote (through `--check-write`).

## What Looks Good

- **Every pass-31 probe now refuses or gives the CommonMark reading.** I reran api31 `p1`/`p4`, fc31 `probe2` (E2: C1-C20, H1-H8, R1, R2, B1-B4, BH1-BH4, BR1), perf31 `p6-shapes` (Q-201..219 and the 8 brief shapes) and sec31 `probe3` (H1-H7, H1c, C1-C9, K1-K17, b1-b9), each retargeted to old 6f24d91 / new 4b7ec02 (`api32/r-*.sh`, log `rerun31.log`).
  - Every case where 6f24d91 gave a wrong `keep`/`drop`/`done` now prints a line-numbered skip with the right reason: `html` for H1-H8 / BH1-BH3 / Q-215-219, `cr` for R1, R2, BR1, C1, C2, b6, and BOM for C9, b5.
  - Every column-0 case that read correctly still reads the same.
  - Line numbers are right: PRE → line 6 and brief-pre → line 2, counted by hand.
  - Two sec31 labels look like mismatches but are not. K14 is labelled `CM=open` but prints `keep`. The fenced `**Needs:**` line is not the header, because the real header precedes it, so `keep` is correct. K8 prints `unrecognized`, which is CommonMark's reading, as sec31 itself notes.
- **The other families the brief named give the CommonMark reading** (`p6.sh`):
  - one-line comments: `<!-- a --> <div>` → keep (type 2 ends on its start line); `<!-->` → keep (the overlapping `-->` agrees with spec 0.31's end condition); a comment indented 4+ spaces → keep;
  - tabs: `` ```<TAB> `` closes and `` ```<TAB>sh `` opens (spec: a closer "may be followed only by spaces or tabs");
  - NUL bytes: a NUL after a closer keeps it from closing, as CommonMark's U+FFFD would (sec31 C5, my `nulclose`); a NUL inside content is harmless (`nulmid` → open). mawk 1.3.4 handles NUL without truncating;
  - setext: `Q-1: [1]` / `---` → keep. A setext heading hides no text, and entry boundaries are `questions.sh`'s ATX split (`/^## /`, `/^### Q-[0-9]+ /`, `scripts/questions.sh:223-228`), which the reader follows;
  - blockquote and list-item HTML (`> <!--`, `- <pre>`): the container's HTML block cannot take a column-0 line (HTML blocks have no lazy continuation), and an indented fence line inside one is already refused as `fence`.

  Link reference definitions are the exception: F1.
- **Real files:** 11 distinct questions blobs across all 9 branches gave 504 ID readings. Old and new are identical, with 0 skips. No blob has a non-exempt `<`-start line, a CR or a BOM. There are no briefs on any branch, so the commit's "all real IDs ... read as before, none refused" holds.
- **The FENCE_AWK comment, help and skips agree with the code** for the three refusal kinds and their order. The CR test comes first, before the `infence` branch, so CR inside fenced content refuses too, as the comment's "a carriage return inside a line" says. `refuse()` keeps the first cause and line. `--check-brief` and `--check-answer` share `oddwhy()`, so the two modes' texts cannot drift. Pass-31 F3 (wording, help for both modes) and F4 (tests: the `<details>` block, a multi-line comment, a lone CR, a BOM, the index-marker comment still read, a brief's HTML and never-closed refusals) are closed.
- **B 4e5cbbc** matches the Rules' sentence (`SKILL.md:91-92`) and closes api31 F5. A line that check 1 moves goes to Done or Ideas and stops being an In flight line, so the new wording cannot list a just-moved brief that reads `new` because its move has not landed.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---|---|---|---|
| F1 | Multi-line inline comment/attribute/link title or link-reference-definition title hides an answer or Status line from CommonMark; reader gives `drop`/`done`, no refusal | Inconsistent | `scripts/dev-cycle.sh:274`, `:284-295`, `:263-266` | High (repro) / Medium-High (CM reading) |
| F2 | HTML refusal covers any `<`-start line, but skip, help and the new brief clause say "raw HTML" | Minor | `scripts/dev-cycle.sh:299`, `:57`; `SKILL.md:335-337` | High |
| F3 | `cr` reason merges CR and BOM; LF-counted line numbers | Informational | `scripts/dev-cycle.sh:285`, `:300` | High |
| F4 | A refused brief keeps its slot, but the final message does not say it was refused | Informational | `SKILL.md:84-87`, `:371-376` | Medium |

## Overall Assessment

The pass-31 fix does what it set out to do. Every HTML-block, lone-CR and BOM probe from all four pass-31 critics now refuses, with a reason-specific skip in the established `<cause>, so <consequence>` shape. Both modes share one reason renderer. All 504 real ID readings are unchanged and none is refused. The remaining gap is narrow but in the same class the bar counts. CommonMark also hides text inside multi-line *inline* constructs (a comment or tag attribute opened mid-line, a link title) and inside a link reference definition's multi-line title, and the reader still reads those lines (F1). The fix is a few narrow refusals that no real file trips. The rest is wording: the HTML reason, help and skill text describe "raw HTML" where the rule is "starts with `<`" (F2), plus two Informational clarity items. Pass 32 is **not clean** at this critic: 1 Inconsistent, 1 Minor, 2 Informational, nothing Breaking.

## Goal-Alignment Note

Success criterion, restated verbatim: "a markdown report saved at the path your role instructions give, structured per your skill file." The report is at `/workspace/.claude/wt-digest/docs/reviews/api-consistency-review-2026-10-02-digest-pass32.md`. Its first line is `Commit: 4b7ec02 (A) / f54ca74 (B)`. It has the skill's sections: Baseline, Name-Pattern Audit, Findings with Severity/Location/Evidence/Confidence/Legibility-target, What Looks Good, Summary Table, Overall Assessment. It serves the user goal of merging once a clean pass is reached: this delta pass is not yet clean, because F1 is a wrong-reading-without-refusal under the brief's unchanged acceptance bar, and its fix leaves every real file readable.
