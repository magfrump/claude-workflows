Commit: 4b7ec02 (A) / f54ca74 (B)

# Security Review — dev-cycle pass 32 (k=1 delta: the reader refuses HTML blocks, stray CRs and a BOM; brief fence rule)

**Scope:** A `git diff 6f24d91..4b7ec02 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` (wt-digest; commits d0bf53f, 4b7ec02). B `git diff e19f411..f54ca74 -- skills/dev-cycle/SKILL.md` (wt-devcycle; commits 4e5cbbc, f54ca74). Merge 2080f23 carries the same `dev-cycle.sh`, bats, `questions.sh` and SKILL.md blobs (checked with `git rev-parse`).
**Date:** 2026-10-02
**Based on:** `docs/reviews/code-fact-check-report-digest-pass31.md` (Stage-1 context).
**Probes:** everything is under `scratchpad/sec32/`:
- `harvest.sh` and `cmp.sh`: every committed input from the pass 26–31 probe repos.
- `rerun.sh`: the pass-31 probes, re-pointed at 4b7ec02.
- `probe1.sh`: new input families.
- `probe2.sh`: real questions files on every branch.
- `probe3.sh` and `probe4.sh`: inline-span measurements.
- `probe5.sh`: briefs, `--help`, shellcheck, bats and lint.

Each probe is one `set -eu` script that makes its own `mktemp -d` and checks `$PWD` before it writes. No process is still running. The only file I wrote outside the scratch directory is this report. During the review both branches moved on through other sessions: wt-digest to fd22d29 ("refuse open inline comments and reference definitions") and wt-devcycle to 5085e64 (decision log 69, "inline constructs that span lines are an accepted limit"). Those commits are outside this pass's fixed scope and I did not review them.

## Trust Boundary Map

```
B1: [docs/working/questions*.md, working tree] → [FENCE_AWK + ANSWER_AWK, --check-answer] → [keep/drop/done/open → In flight close/keep, Applied:]
B2: [brief blob on the default branch]         → [FENCE_AWK + Status awk, --check-brief]    → [open/done/dropped → slot, Done/Ideas, git mv to closed/]
B3: [SKILL.md Build briefs / final message]    → [agent writing briefs, composing message]  → [B2 input shape; user's view of unsettled closed/ briefs]
```

| Label | Source | Mutability | Trust per sink |
|---|---|---|---|
| S1 | questions.md / questions-archive.md text (the user, agents, quoted reviews, `questions.sh`) | runtime-mutable | UNTRUSTED for the keep/drop/done sink. Text that CommonMark renders as quoted or hidden must stay inert. |
| S2 | brief text on the default branch (written by the cycle; build sessions edit `Status:`) | runtime-mutable | UNTRUSTED for the Status→close/move sink |
| S3 | `FENCE_AWK`/`ANSWER_AWK` programs, `-v id` (`^Q-[0-9]+$`), `oddwhy` reason words | code-constant / validated | trusted |
| S4 | SKILL.md text | deploy-time (merged) | trusted as instructions. The risk is how the agent reads them. |

Repo text enters through B1 and B2 and decides whether a brief closes, stays or moves. This diff widens the refusals: any line outside a fence that starts with `<` (except a `<!--` line that also holds `-->`), any CR that survives the trailing-CR strip, and a BOM on line 1. The question is whether any input that is not refused still reads differently from CommonMark. No input reaches an exec, eval, SQL or HTML sink.

## Findings

#### F1. Inline constructs that span lines (code spans, inline comments, link titles, tag attributes) hide an answer, header or Status line from CommonMark, but the reader still reads it, with no refusal. Two committed pass-31 probe inputs, K16 and C7, are this case, and their CommonMark labels were wrong

**Severity:** Low. This is the same class and calibration as pass-31 F1/F2, and it is not a regression: 6f24d91 gives identical readings. Whoever writes the shape could write the answer or Status line directly. After this review started, decision log 69 (5085e64, out of scope) recorded the user's choice to accept this class as a limit.
**Location:**
- `scripts/dev-cycle.sh:428-453`: the per-line answer and header read. `:440-452` is the `!done` block, and `:434-438` is the `**Needs:**` header.
- `:322-326`: `!seen && /^Status:/` in `check_brief`.
- `:274`: `rawhtml()`, which refuses a block-level `<` only.
- The comment at `:257-269` claims fence fidelity only.

**Boundary:** B1, B2
**Move:** 11 (bypass enumeration), 2
**Confidence:**
- High for the code (executed, `probe1.log`, `probe5.log`).
- High for CommonMark on code spans and inline comments: spec §6.1, where a code span's backtick strings match across line endings inside a paragraph, and §6.6, where an inline HTML comment may span lines. A fence line still interrupts the paragraph, and the reader matches that (I7).
- Medium on whether "CommonMark's reading" of a line-based protocol means the rendered text. Pass 31 drew the same caveat for H1c.

**Legibility-target:** maintainer

**Evidence (verbatim):**
- `:442` `if (index(line, id ":") == 1) { result = option(substr(line, length(id) + 2)); done = 1; next }`. It is followed by the `**answer` label match at `:443-452`, which reads every unfenced line with no paragraph or inline context. The `:440-453` block ends there.
- `:274` `function rawhtml(l) { return l ~ /^[ \t]*</ && !(l ~ /^[ \t]*<!--/ && index(l, "-->")) }` matches only a `<` at the start of a line.

`probe1.log` and `probe5.log` show the results. Each questions case is a Q-5 ANSWERED entry followed by the listed body:

| Case | Body | 4b7ec02 | 6f24d91 | CommonMark (rendered) |
|---|---|---|---|---|
| I1 | `Note <!--` / `**Answer:** [2]` / `-->` / `**Answer:** [1]` | `drop` | `drop` | keep |
| I1b, I1c | `<!-- a --> b <!--` …, and `x --> <!--` … (the one-line exception, then an inline opener) | `drop` ×2 | same | keep |
| I2, I3 | a code span of 1 or 2 backticks around `**Answer:** [2]` | `drop` ×2 | same | keep |
| I4, I5 | a link title, or a `<span title="…">` attribute, spanning the answer line | `drop` ×2 | same | keep |
| I6, I6b | an ANSWERED `**Needs:**` header inside an inline comment, with the real header OPEN | `drop` ×2 | same | open |
| ib1–ib5 (briefs) | `Status: done` inside an inline comment, a 1/2-backtick or `\f`-prefixed code span, or a link title, then `Status: open` | `ok … done` ×5 | same | open: a wrong close that moves the brief to `closed/` and frees its slot |

From the harvest, these are the only 2 of 4,021 committed inputs that are not refused and hold a span-hidden deciding line:
- K16, `harvest/qa00241`: ` `` ` / `**Answer:** [2]` / ` `` `. Both readers say `drop`. CommonMark makes this a code span, so it reads unrecognized.
- C7, `harvest/qa00260`: `\f```` / `**Answer:** [1]` / `\f````. Both say `keep`. The form feed is not indentation, so this is not a fence but a 3-backtick code span, and CommonMark reads unrecognized.

Pass 31 labelled both `CM=drop`/`CM=keep`. My pass-31 Endorsement Claim 4, "K16 … reads as CommonMark does", was therefore wrong for K16. C7 was not in that claim, but it carries the same wrong label.

Measured on real files (`probe3.log`, `probe4.log`): 0 span-hidden deciding lines across all 24 copies, which are the questions and archive files on 9 branches plus three working trees. A blunt rule would be costly. Refusing any deciding line that continues a paragraph holding a backtick, `<` or `](` would refuse the real archive: 7 answer lines continue their question's paragraph, 4 of them with backticks, for example `:354` `**Answered 2026-09-17: replace-only stands …` after `` Should `--profile` stay replace-only … ``.

**Recommendation:**
- Treat this as the accepted limit that decision 69 now records, and do not chase it shape by shape. The pass-31 commits fd22d29 and 5085e64 already refuse open inline comments and name the limit. They are unreviewed here.
- If the limit is ever lifted, the only rule that leaves the real files unrefused tracks a code span or comment left open at a line boundary within the paragraph. "Continues a paragraph" alone is too blunt.
- Correct the K16 and C7 CommonMark labels wherever the pass-31 artifacts cite them.

#### F2. B: the new brief-format sentence names "raw HTML or stray carriage returns", but `--check-brief` refuses any line starting with `<` (an autolink, a `<placeholder>`) and a leading BOM, so a brief that follows the sentence can still be refused and hold its slot

**Severity:** Informational. This is availability and bookkeeping: the skip is legible and names the line, and the skill already says a refused brief keeps its slot.
**Location:** `skills/dev-cycle/SKILL.md:335-337` (f54ca74), and `scripts/dev-cycle.sh:274`, `:285`
**Boundary:** B3 → B2
**Move:** 3 (failure state)
**Confidence:** High (executed: `probe5.log` ib6)
**Legibility-target:** agent

**Evidence (verbatim):**
- Skill: "Any code in a brief sits in plain column-0 ``` fences, with no indented or list-item fences, raw HTML or stray carriage returns (`--check-brief` refuses a brief with those, and a refused brief keeps its slot)."
- `probe5.log`: `ib6-autolink-line CM=open 4b7=[skip docs/working/briefs/2026-01-01-ib6-autolink-line.md: line] 6f2=[ok … open]`. The body is `# B` / `<https://x.example>` / `Status: open`.

An agent writing a goal line such as `<https://…>` or `<branch-name>` is not writing "raw HTML" in its own terms.

**Recommendation:** Say "no line starting with `<` (except a one-line `<!-- … -->`), no stray carriage returns, no byte-order mark". The later 5085e64 subject ("no line starting with < (placeholders as NAME, not <name>)") looks like this change. It was not reviewed here.

## Re-run of earlier probes (executed)

- **Every committed input from the pass 26–31 probe repos**, read by 4b7ec02 and by 6f24d91 (`harvest.sh`, `cmp.sh`).
  - Coverage: 1,679 repos, of which 1,642 touch `docs/working`. That gives 439 distinct (questions, archive) pairs and 3,475 brief blobs.
  - Answers: 7,003 readings. 6,275 are identical non-skip readings and 688 skip in both. 35 were read at 6f24d91 and now refuse: 29 `html` and 6 `cr`. In 5 more, both versions skip and the reason changes from "fence-like" to "raw HTML" for an old `<pre>` line. **0 non-skip readings differ.**
  - Briefs: 3,406 identical, 50 skip in both, 16 now refuse (`html`/`cr`), 3 change only the skip reason, and **0 non-skip readings differ**.
  - The `setlocale` stderr lines, 838 and 4, are excluded from these counts. They pair up in both columns.
- **Pass-31 probe scripts re-pointed** (`rerun.sh`: 6f24d91→4b7ec02, f4d27d2→6f24d91; 13 scripts, all rc=0).
  - Every row the brief lists now refuses with the new reason:
    - sec31 probe3: H1–H7, H1c, C1, C2, C9, briefs b1–b6;
    - fc31 probe2: H1–H7, H1c, R1, R2, BH1–BH3, BR1;
    - perf31 p6: Q-215 to Q-219, plus the three comment/div briefs.
  - Every column-0 row reads as before: K1–K6, K11–K13, K15, K17, C3, C7, C8, b7–b9; fc31 C1–C17; perf31 Q-201 to Q-214.
  - Stale labels:
    - K16 and C7: see F1.
    - sec31 K14 says `CM=open`, but its body's fenced `**Needs:** … OPEN` sits after the harness's real ANSWERED header, so `keep` is correct.
    - K8 says `CM=keep`, but the closing fence at EOF closes it, so `unrecognized` is correct, as pass 31 already said in prose.
- **Real files on every branch** (`probe2.log`). All 9 local branches were checked. The 6 distinct (questions, archive) pairs give 590 readings: byte-identical at 6f24d91 and 4b7ec02, and **0 skips**. The only `<` lines are the four `<!-- index:start/end -->` one-line markers. There are 0 CRs, 0 BOMs and 0 unclosed mid-line `<!--`. No branch has a brief (`docs/working/briefs/` is empty everywhere). The working-tree copies in wt-digest, wt-devcycle and /workspace are included in `probe3`'s 24 files.
- `fc31-probe3`, re-run, prints the same four marker lines at main and 0c45039, and `briefs: 0`.

## New families checked (`probe1.log`)

| Family | Result | Verdict |
|---|---|---|
| One-line comment exception: `<!-- a -->`, `<!-->`, `<!--->`, 3-space and tab indent, `<!-- a --> <!-- b`, `<!-- a --><div>`, the index markers, `- <!--` and `> <!--` before a column-0 fence | all `keep`, as CommonMark reads them. Type 2 ends on any line containing `-->`, including its start line (cmark and commonmark.js both scan from the `<`), and a container's HTML block ends at the next unindented line | rule correct and complete |
| `<!-- x` / `--> y` (`-->` only on a later line) | refuses | correct |
| `<` lines CommonMark reads as text (autolink, `< 5`, a type-7 tag inside a paragraph, a lazy `<div>` after a list item) | refuse | allowed cost (0 such lines in real files) |
| CR / BOM: trailing CR only, a CR ending a no-LF last line, BOM mid-file, classic-Mac CR-only file | `keep`, `keep`, `keep`, refuse | match or refuse |
| BOM on line 1 before ordinary text | refuses (CommonMark: keep) | allowed cost (0 real files start with a BOM) |
| NUL before a fence, NUL inside a fence, U+2028 in an info string, form feed after a closer (not a closer), tab after a closer, tab after a list marker | match CommonMark, or refuse (the list tab) | match or refuse |
| Multi-line link-reference-definition title holding a fence (C12) | `keep`: the fence interrupts the definition paragraph | match |
| Setext, tab-separated, indented and empty ATX headings inside an entry (S1–S4) | `drop`, while CommonMark's section boundary would give unrecognized | outside the fence model. `questions.sh` itself splits only at `^### Q-` and `^## ` (`questions.sh:223-228`, `:364-369`), so the reader matches the protocol owner. Not a finding |
| Inline constructs spanning lines | wrong readings | F1 |

## Untested bypass candidates

- **gawk, busybox awk**: not installed. Every result is from mawk 1.3.4 20200120.
- **Emphasis spanning lines** (`*` … `*` around an answer line): this is the same inline class as F1 and was not run. Static reasoning says it does not hide the label text, only restyles it.
- **Entity and escape forms of `<`** (`&lt;!--`, `\<!--`): static reasoning says CommonMark reads these as text, and so does the reader (the line does not start with `<`). Not run.
- **fd22d29 and 5085e64**: these are later fixes, outside the fixed scope, and not reviewed.

Because F1's family stays open at 4b7ec02, the reader as a whole is not endorsed below. Only the rules I tested are.

## Endorsement Claims

- **Claim:** On every input committed by the pass 26–31 probe repos, 4b7ec02 gives the same non-skip reading as 6f24d91 or refuses. That is 7,003 answer readings and 3,475 briefs, with 0 non-skip differences. Each of the 51 new refusals names `html` or `cr`.
  **Location:** `scripts/dev-cycle.sh:271-303`, `:322-331`, `:454-474`
  **Evidence:** executed
  **Verified:** `cmp.sh` over `harvest/` (`qa.tsv`, `br.tsv` in its temp dir), with the counts above.
  **Not verified:** whether 6f24d91's reading of every identical row is CommonMark's. Two rows are not (F1: K16, C7). The rest rests on the column-0 argument and on the probes' own CommonMark columns, not on a CommonMark parser, since none is installed.
  **route: code-fact-check**
- **Claim:** On the real questions files of all 9 local branches, `--check-answer` output is byte-identical at 6f24d91 and 4b7ec02 for every `### Q-` ID (590 readings in 6 distinct pairs), and none refuses. No branch holds a brief.
  **Location:** `scripts/dev-cycle.sh:461-480`
  **Evidence:** executed
  **Verified:** `probe2.log`
  **Not verified:** entries written after these branch tips, and the cycle's first real briefs.
  **route: code-fact-check**
- **Claim:** The `<!--` one-line exception accepts exactly the lines on which CommonMark's type-2 block both starts and ends: 9 shapes executed. A comment whose `-->` sits only on a later line refuses.
  **Location:** `scripts/dev-cycle.sh:274`
  **Evidence:** executed
  **Verified:** `probe1.log`, rows E1–E11.
  **Not verified:** the brief path (`--check-brief`) for E2–E11. Only E8-like markers ran there (bats test 49).
  **route: code-fact-check**
- **Claim:** A CR that survives the trailing-CR strip, or a BOM on line 1, refuses the file in both modes. Plain CRLF still reads as before (C3, b9, perf Q-204).
  **Location:** `scripts/dev-cycle.sh:285`, `:323`, `:428`
  **Evidence:** executed
  **Verified:** the `rerun.sh` logs for sec31-probe3 and fc31-probe2, and `probe1.log` C1–C5.
  **Not verified:** a CR inside a fenced line of a brief, which the code reads statically as the same refusal.
  **route: code-fact-check**
- Minor positives, not routed:
  - bats passes 49/49 on a `git archive` copy of 4b7ec02;
  - `hermeticity-lint` returns rc=0;
  - shellcheck is clean;
  - `--help` prints 68 lines (`sed -n '2,69p'`, `:133`), ending at the Exit paragraph, and line 70 is blank;
  - the skip lines name the line and the reason through `oddwhy`, and the reason word is code-constant (S3);
  - the 4e5cbbc final-message wording ("each In flight line naming a `closed/` brief that reads `open` or `new`") resolves pass-31 F4. It lists such a brief on every cycle until the user sets it (read-static);
  - one stale comment: `:384` still documents `"odd N"`, while `:455` prints `"odd N <why>"`. This is for code-fact-check, not a security matter.

## Primitive sweep

Primitive: process exec (awk / git with repo-derived arguments)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/dev-cycle.sh:322` `git cat-file blob "$MAIN_SHA:$a" \| env LC_ALL=C awk "$FENCE_AWK"…` | S2 path `$a`, S3 program | `pathform`, `isbrief`/closed regex, `blocker` (`:313-318`) | cleared: the path is validated before use, and the program is a constant |
| `scripts/dev-cycle.sh:467` `env LC_ALL=C awk -v id="$a" "$FENCE_AWK$ANSWER_AWK" "$f"` | S1 file, `$a` | `^Q-[0123456789]+$` (`:463`), fixed `$f` list, `skipped` | cleared |
| `:328`, `:471` `read -r _ n why <<<"$st"` then `$(oddwhy "$why")` | S3 output (`NR` and a fixed reason word) | numeric and word by construction | cleared: `oddwhy` only echoes constants |

No eval, deserialization, SQL or HTML sinks are in scope.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| F1 | Inline constructs spanning lines hide a deciding line from CommonMark, but the reader reads it. A brief can close wrongly (ib1–ib5). Pass-31's K16/C7 labels were wrong | Low | B1, B2 | `scripts/dev-cycle.sh:428-453`, `:322-326`, `:274` | High (code) / Medium (rendered-reading lens) |
| F2 | B: the brief-format sentence names "raw HTML", but every `<`-led line and a BOM refuse | Informational | B3→B2 | `skills/dev-cycle/SKILL.md:335-337` | High |

## Overall Assessment

The pass-31 fix does what it set out to do. Every HTML-block, CR and BOM probe from pass 31 now refuses with a reason that names the line. No input committed by passes 26–31 that is not refused reads differently from before. Every real questions file on every branch reads byte-identically, with no refusal. The one-line-comment exception is exact.

The only remaining family I found against the "CommonMark or refuse" bar is inline constructs that span lines (F1). It is not a fence shape, it is not a regression, and no real file has one. It does include two committed pass-31 inputs whose CommonMark labels, and my pass-31 endorsement of K16, were wrong. The user has since accepted that class as a limit (decision 69, 5085e64), so F1 should not block a clean pass once that commit is reviewed. F2 is wording, and 5085e64's subject suggests it is already addressed.

The single most important thing is to review fd22d29 and 5085e64 next, because they carry the remaining resolution. No findings beyond these within the code paths read. The endorsement claims are pending execution verification.

## Goal-Alignment Note

**Success criterion (verbatim):** "a markdown report saved at the path your role instructions give, structured per your skill file."

This report is saved at `/workspace/.claude/wt-digest/docs/reviews/security-review-2026-10-02-digest-pass32.md`, with the required first line. It follows the security-reviewer structure:
- trust boundary map and source table;
- findings with Severity, Location, Evidence (verbatim), Confidence and Legibility-target;
- untested candidates;
- routed endorsements;
- primitive sweep;
- summary;
- assessment.

It serves the user's goal of merging after a clean pass. It confirms the pass-31 fix against every earlier probe input and every real file. It names the one remaining family, which the user has since accepted as a limit, and it points the loop at the two later commits that still need review.
