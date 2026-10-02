Commit: e93312d (A) / 823f494 (B)

# Security Review — dev-cycle pass 34 (k=1 delta: the last `<!--`, widened reference-definition refusal, reason and help wording; decision log 69 and the brief clause)

**Scope:** A: `git diff fd22d29..e93312d -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` (wt-digest; commits 5630135, 0db12bd, e93312d). B: `git diff 5085e64..823f494 -- skills/dev-cycle/SKILL.md docs/decisions/log.md` (wt-devcycle; commits 12f4cd6, 823f494). I checked that merge ba93f23 carries the same `dev-cycle.sh` blob as e93312d (`23007670`) and the same SKILL.md blob as 823f494 (`dea6d21`), with `git rev-parse`.
**Date:** 2026-10-02
**Based on:** `docs/reviews/code-fact-check-report-digest-pass33.md` (Stage-1 context). The accepted limit is decision log 69: inline constructs that span lines (an open tag attribute, link title, code span, emphasis, or a processing instruction, CDATA section or declaration opened mid-line). Findings inside that class are out of scope.
**Probes:** all under `scratchpad/sec34/`:
- `probe1.sh` reruns every pass-33 probe shape (sec33 C1–C7, R1–R5, H1–H3, N1–N11, B1–B6; fc33 P2/P3; api33 shapes) and adds new bypass and over-refusal candidates. Each shape is read by e93312d and by fd22d29 (`probe1.log`).
- `probe2.sh` reads the real questions files on all 9 branches and in all 3 worktrees, and times `opencomment` on long lines (`probe2.log`).
- `probe3.sh` checks the `--help` range, bats, the hermeticity lint and shellcheck on a `git archive e93312d` snapshot (`probe3.log`).
- `probe4.sh` tests a candidate fix against the new bypasses and the real files, and checks how `opencomment` cost grows with line length (`probe4.log`).
- `harvest.sh`, `cmp.sh`, `analyze.sh`, `analyze2.sh` re-read every committed input from the pass 26–33 probe repos with e93312d and with fd22d29.

Each probe is one `set -eu` script that makes its own `mktemp -d` under `sec34/` and checks `$PWD` before any `git init`, commit, write or `rm`. Every process ran under `timeout` and has exited. The only file I wrote outside the scratch directory is this report. The worktree questions files were clean (`probe2.log`).

## Trust Boundary Map

```
B1: [docs/working/questions*.md, working tree] → [FENCE_AWK + ANSWER_AWK, --check-answer] → [keep/drop/done/open → In flight close/keep, Applied:]
B2: [brief blob on the default branch]         → [FENCE_AWK + Status awk, --check-brief]    → [open/done/dropped → slot, Done/Ideas, git mv to closed/]
B3: [SKILL.md brief clause / final message; decision log 69] → [agent writing briefs; user judging what the reader guarantees] → [B2 input shape; the user's picture of the limit]
```

| Label | Source | Mutability | Trust per sink |
|---|---|---|---|
| S1 | questions.md / questions-archive.md text (the user, agents, quoted reviews, `questions.sh`) | runtime-mutable | UNTRUSTED for the keep/drop/done sink: outside the accepted class, text CommonMark hides must not decide |
| S2 | brief text on the default branch | runtime-mutable | UNTRUSTED for the Status→close/move sink |
| S3 | `FENCE_AWK` / `ANSWER_AWK` programs, `-v id` (`^Q-[0-9]+$`), `oddwhy` reason words | code-constant / validated | trusted |
| S4 | SKILL.md text, decision log 69 | deploy-time (merged) | trusted as instructions; the risk is what they claim the reader refuses |

Repo text enters through B1 and B2 and decides whether a brief closes, stays or moves. This round changes two refusals: `opencomment` now tests the last `<!--`, and `refdef` now strips containers and refuses an unclosed `[`. The question is whether any input outside log 69's class still gets a non-CommonMark reading with no refusal, and whether a real file is refused. No input reaches an exec, eval, SQL or HTML sink.

## Findings

#### F1. A reference-definition label whose first line holds only an escaped `]` is not refused. Its label continues on the next line, and its title hides the deciding line

**Severity:** Low. This uses the same calibration as pass-33 F1/F2: the S1 writer could write the deciding line directly, so what is lost is "the cycle acts on what the user sees". It is outside log 69's class, because a link reference definition is in the row's refused list, not in its accepted list.
**Location:** `scripts/dev-cycle.sh:288-294` (`refdef`). The comment at `:291-292` claims the case is covered, and so does commit message 0db12bd ("so an escaped ] in the label counts").
**Boundary:** B1, B2
**Move:** 11 (bypasses for every guardrail)
**Confidence:** High for the reader's output (executed). Medium-high for the CommonMark side: this rests on my reading of the 0.31 spec, which says "a link label … ends with the first right bracket that is not backslash-escaped" and allows line endings in labels. No CommonMark implementation is installed in the sandbox: no cmark, pandoc, markdown-it or the Python packages.
**Legibility-target:** the user reading log 69 and the `refdef` comment, which say reference definitions are refused.

**Evidence** (verbatim, code):

```
  # Any line starting [ that holds ]: (an escaped ] in the label too) or never
  # closes its [ (a label that continues on the next line) counts.
  return substr(l, 1, 1) == "[" && (index(l, "]:") || !index(l, "]"))
```

`!index(l, "]")` counts an escaped `\]` as a close, so `[a\]` passes. Inputs from `probe1.log`: each follows an ANSWERED header and a blank line, and the CM column is the first answer the user sees.

```
E1-escaped-close-then-label-continues	CM=keep	NEW=drop Q-1 	OLD=drop Q-1      '[a\]' / "b]: /u 'title" / '**Answer:** [2]' / "'" / '' / '**Answer:** [1]'
E2-escaped-close-Qline	CM=keep	NEW=drop Q-1                        '[x\]' / "y]: /u 'title" / 'Q-1: [2]' / "'" / '' / 'Q-1: [1]'
E8-list-escaped-label	CM=keep	NEW=drop Q-1                        '- [a\]' / "b]: /u 'title" / ...
BE1-escaped-close	CM=open	NEW=ok docs/working/briefs/2026-01-01-p.md done              '# Brief' / '' / '[a\]' / "b]: /u 'title" / 'Status: done' / "'" / '' / 'Status: open'
```

In CommonMark, the label is `a\]⏎b`, the destination is `/u`, and the title `'title⏎**Answer:** [2]⏎'` hides the middle line. The reader reads the hidden `[2]` (drop). In BE1, a brief the user sees as `Status: open` reads `done`, so the cycle would move it to `closed/`.

**Recommendation:** Remove backslash pairs before testing for the label's end: `gsub(/\\./, "", l)` after the `[` check, then apply the same `index(l, "]:") || !index(l, "]")` test. `probe4.sh` ran this fix (`fix.awk`). It refuses E1 and E8, keeps `[x] text`, `[a\]b] text` and `\[x]: y` readable, and refuses no real questions file on any branch. Add E1 and BE1 to bats test 49.

#### F2. `refdef` strips only one list marker, so a reference definition behind nested containers (`- - `, `1. - `, `- > - `) is not refused, and a lazy continuation line in its title is hidden

**Severity:** Low (same calibration as F1). It is outside log 69's class. The row says "a link reference definition (also behind `>` or a list marker)", and the code comment says "also behind blockquote markers and list markers".
**Location:** `scripts/dev-cycle.sh:290` (one `if`, not a loop). The claims are at `:288` (comment) and in wt-devcycle `docs/decisions/log.md:92`.
**Boundary:** B1, B2
**Move:** 11
**Confidence:** High for the reader's output (executed). Medium for the CommonMark side: lazy paragraph continuation inside nested list and blockquote items, by spec reading.
**Legibility-target:** the user reading log 69 ("behind `>` or a list marker").

**Evidence** (verbatim, code):

```
  sub(/^[ \t>]*/, "", l)
  if (l ~ /^([-*+]|[0123456789]+[.)])[ \t]/) { sub(/^[^ \t]+[ \t]+/, "", l); sub(/^[ \t>]*/, "", l) }
```

Results from `probe1.log`:

```
E3-nested-list	CM=keep	NEW=drop Q-1 	OLD=drop Q-1        "- - [x]: /u 'title" / '**Answer:** [2]' / "'" / '' / '**Answer:** [1]'
E4-ordered-in-bullet	CM=keep	NEW=drop Q-1                    "1. - [x]: /u 'title" / ...
E5-list-quote-list	CM=keep	NEW=drop Q-1                    "- > - [x]: /u 'title" / ...
E6-quote-list-quote	CM=keep	NEW=skip Q-1: line 6 starts like a link reference definition   (control: one list marker, refused)
BE3-nested-list	CM=open	NEW=ok docs/working/briefs/2026-01-01-p.md done
BE5-list-quote-list	CM=open	NEW=ok docs/working/briefs/2026-01-01-p.md done
```

After one list marker and the `>`s around it are stripped, the line still starts with `-`, so it is not refused. In CommonMark, the innermost paragraph is `[x]: /u 'title`. The column-0 lines that follow continue it lazily, and the definition's title then hides them.

**Recommendation:** Turn the `if` into a `while`, which strips every list marker and the `>`s after each one. `probe4.sh` ran this fix together with F1's. It refuses E3, E4 and E5, keeps `- - item` and `1. 2) item` readable, and refuses no real file: the real files on every branch have 0 nested-marker lines (`probe2.log`). Add E3 and BE3 to the test.

#### F3. `opencomment` finds the last `<!--` with a loop that copies the rest of the line on every match, so its cost grows quadratically with the number of `<!--` on one line

**Severity:** Low (availability only; cross-lane to performance). A line with many `<!--` slows every `--check-answer` and `--check-brief` that reads the file. It is not refused, because the line ends with `-->`. No reading changes. The floor rule is not met. The writer is S1, who can already stall or redirect the cycle by editing the file. The slowdown needs a line of more than a megabyte, and nothing the cycle trusts gets a wrong answer.
**Location:** `scripts/dev-cycle.sh:284-287`
**Boundary:** B1, B2
**Move:** 8 ("a million of these")
**Confidence:** High (executed, mawk).
**Legibility-target:** the performance critic; whoever maintains FENCE_AWK.

**Evidence** (verbatim, code):

```
function opencomment(l,   i, j) {  # the last <!-- on the line has no --> after it
  i = 0; while ((j = index(substr(l, i + 1), "<!--")) > 0) i += j
  return i && !index(substr(l, i + 4), "-->")
}
```

From `probe2.log` and `probe4.log`, one line of `x <!-- <!-- … -->`:

```
80000 (400006 bytes): clean 0.28s
160000 (800006 bytes): clean 1.33s
320000 (1600006 bytes): clean 8.52s
control (400 KB, no <!--): clean 0.0s
```

Each doubling costs about 5–6 times more, so a 16 MB line would take on the order of 10 minutes for each awk call. The fd22d29 version made one `index` call and was linear.

**Recommendation:** Use `n = split(l, p, "<!--"); return n > 1 && !index(p[n], "-->")`. It is linear and gives the same answer, including `<!-->`, where both versions test `>`. Alternatively, accept the cost and say so in the comment.

#### Untested bypass candidates / class-boundary notes

- **Other inline raw HTML opened mid-line** (H1–H3: `x <?`, `x <![CDATA[`, `x <!X`). These still read `drop` where CommonMark shows `keep`. They are now named in log 69's class (e93312d, 823f494), so they are not findings.
- **HTML blocks inside containers** (`- <div>`, `> <pre>`). I traced these but did not execute them. An HTML block cannot take a lazy continuation, so a column-0 `Status:`, `Q-NNN:` or `**Answer` line closes the container rather than being hidden. A `- Q-1:` line starts a sibling item. This leaves no hiding path, but no probe confirms it.
- **CommonMark 0.30 vs 0.31 comment rules.** Under 0.30, `<!-- a -- b` is not a comment. The reader refuses it, which is an over-refusal only. I found no input in the other direction, where CommonMark sees a comment and the reader does not.
- I could not run a CommonMark implementation (none installed, no egress). Every CM label rests on my reading of the spec. The reader outputs are executed.

## Endorsement Claims

- **Claim:** At e93312d, every pass-33 bypass shape outside the accepted class now gets a skip. These are C1–C5, R1–R5, B1 and B2 (sec33), the second, third and line-start comments, the escaped, blockquote and multi-line refdefs (fc33 P2/P3), and the api33 shapes. Each was a non-skip reading at fd22d29.
  **Location:** `scripts/dev-cycle.sh:284-294, 314-316`
  **Evidence:** executed
  **Verified:** `probe1.log`: each listed shape reads `skip … opens an HTML comment` or `skip … starts like a link reference definition` at e93312d, where it read `drop` or `ok … done` at fd22d29. bats 49/49 at e93312d (`probe3.log`).
  **Not verified:** the shapes in F1 and F2, where the refusal does not hold.
  **route: code-fact-check**
- **Claim:** Testing the last `<!--` matches CommonMark for one-line comments. If a `-->` follows the last `<!--`, every comment the line opens also closes on it. E10 (`a <!-- x <!-- y -->`) and E11 (two closed comments) still read. E12 (`<!-- a --> <!--` at line start) is now refused.
  **Location:** `scripts/dev-cycle.sh:284-287`
  **Evidence:** executed (E10–E12, C1–C5) / read-static (the general argument: comments do not nest and end at the first `-->`)
  **Verified:** `probe1.log` rows E10, E11, E12, C1–C5, F-third-comment.
  **Not verified:** comments that span lines and start inside another inline construct that spans lines (the accepted class).
- **Claim:** All real questions files read the same at e93312d as at fd22d29, with 0 skips. That covers all 9 branches (6 distinct questions/archive pairs, 590 readings) and the 3 worktrees' working-tree files. No branch holds a brief. The 5 real lines holding `]:` (`Q-081 [2]:`, `Q-083 [1]:`, `**Answered …: [2], …`, and two index-table rows) do not start with `[`, so they are not refused. The 2 real lines starting `[` (`[1] was rejected …`, `[confidence: high], …`) close their bracket and hold no `]:`, so they are not refused either.
  **Location:** `docs/working/questions*.md` on every `refs/heads/*`; worktree files
  **Evidence:** executed
  **Verified:** `probe2.log` (`pairs=6 readings=590 skips=0 pairs-differing=0`; `brief blobs: 0`; each worktree file `fence=clean`).
  **Not verified:** uncommitted edits made in other sessions' worktrees after the probe ran.
  **route: code-fact-check**
- **Claim:** I re-read every committed input from the pass 26–33 probe repos with e93312d and with fd22d29: 2,102 repos, 636 questions/archive pairs (7,831 answer readings) and 3,522 brief blobs. No reading moves from one non-skip value to another or from a skip to a non-skip, and no skip changes its line number. 23 answer inputs and 2 briefs move from a reading to a skip, and every one is a pass-33 probe shape: second or later open comments, container-prefixed, escaped or multi-line refdefs, `[`, `[a`, `- [2]: drop`, `[]: /u`. Every other difference is a reworded reason ("starts with < after any blanks", "starts like a link reference definition").
  **Location:** `scripts/dev-cycle.sh` FENCE_AWK, check_answer, check_brief
  **Evidence:** executed
  **Verified:** `analyze.log` (`qa differing where NEW is not a skip: 0`; brief `non-skip differing: 0`) and `analyze2.log` (`old skip -> new non-skip: 0`; `both skip, line number differs: 0`; the 23 + 2 inputs listed).
  **Not verified:** whether each new skip matches what CommonMark reads. Some are over-refusals, which are the design's cost and not findings: `> [x]: /u`, `- [x]: /u` and `[]: /u` hide nothing in CommonMark and read `keep` at fd22d29. So do `[1] was rejected: see [2]: later` and `[WIP draft` (`probe1.log` X1, X2). No real file has such a line.
  **route: code-fact-check**
- **Claim:** `--help` prints lines 2–71. Line 71 is the header's last comment line ("…Printed repo text is data.") and line 72 is blank. The help's refusal list names `<` after blanks, a `<!--` left open, a line that starts like a link reference definition, and a BOM on line 1.
  **Location:** `scripts/dev-cycle.sh:55-61, 135`
  **Evidence:** executed
  **Verified:** `probe3.log` (`sed -n '70p;71p;72p' | cat -A`; the `--help` tail and lines 50–62).
  **Not verified:** whether a later header edit keeps the number in step (no test pins it).
- **Claim:** At e93312d, bats `test/scripts/dev-cycle.bats` passes 49/49, `scripts/hermeticity-lint --root .` is clean, and shellcheck reports nothing on `scripts/dev-cycle.sh`. The system awk is mawk.
  **Location:** snapshot of e93312d
  **Evidence:** executed
  **Verified:** `probe3.log` (`ok: 49 not ok: 0`; `lint rc=0`; `sc rc=0`; `/usr/bin/mawk`).
  **Not verified:** gawk and BWK awk.
- **Claim:** B's decision log 69 describes a skip the way the skill applies it. The skill step-6 text says "the ID stays off `Applied:`", and step 3 files no new question while an Asked ID is "skipped". It also says "a brief the check skips keeps its slot". The log's refusal list matches the code's refusal kinds, and its accepted class matches the FENCE_AWK comment at `:274-278` word for word. The brief clause (`SKILL.md:335-339`) lists the refusals that `--check-brief` applies outside fences: `<`, an open `<!--`, a refdef, a CR, a BOM.
  **Location:** wt-devcycle `docs/decisions/log.md:92`; `skills/dev-cycle/SKILL.md:85-87, 297-301, 335-339, 378`
  **Evidence:** read-static, plus executed for the brief refusals (`probe1.log` B3, B5, B6)
  **Verified:** the row text, the skill lines named, and the code.
  **Not verified:** the row's "also behind `>` or a list marker" holds for one marker only (F2), and its refdef entry misses F1's shape. The clause says "starting with `<`", while the code also refuses a `<` after blanks. That is wording only, and the skip names the line.

## Primitive sweep

Primitive sweep: no dangerous primitives in scope. The diff changes two awk predicates, two `oddwhy` reason strings, comments, help text and a test. The reasons are fixed strings chosen by an awk-selected word (S3), passed through `read -r _ n why` and printed through the existing scrub. No repo text reaches exec, eval, a path or a pathspec in this diff.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| F1 | Refdef label whose first line holds only an escaped `]` is not refused; its title hides answer/Status lines | Low | B1, B2 | `scripts/dev-cycle.sh:288-294` | High (reader) / Medium-high (CM) |
| F2 | Only one list marker is stripped; refdefs behind nested containers are not refused | Low | B1, B2 | `scripts/dev-cycle.sh:290` | High (reader) / Medium (CM) |
| F3 | `opencomment`'s last-`<!--` loop is quadratic in a line's `<!--` count (availability; cross-lane) | Low | B1, B2 | `scripts/dev-cycle.sh:284-287` | High |

## Overall Assessment

The round closes every bypass that pass 33 reported. The last-`<!--` test is exact for one-line comments. The widened `refdef` refuses the escaped, multi-line and single-container shapes. Real files on every branch and in every worktree read exactly as before, with 0 skips. Across 7,831 harvested answer readings and 3,522 briefs, the only changes are new refusals of probe shapes and reworded reasons. Two narrow refdef shapes still sit outside the accepted class and are not refused: an escaped `]` that ends the first line of a multi-line label (F1), and nested container markers (F2). One combined, tested change closes both, a `while` loop over markers plus `gsub(/\\./, "", l)`, and it refuses no real file. F3 is an availability cost that the previous version did not have, and it has a linear drop-in (`split`). All three stay Low, because S1 can write the deciding line directly. No findings beyond these within the code paths read. The routed endorsement claims are pending execution verification by code-fact-check. Most important: fix F1 and F2 together, since both contradict log 69's refusal list.

## Goal-Alignment Note

Success criterion (verbatim): "a markdown report saved at the path your role instructions give, structured per your skill file."

This report is saved at `/workspace/.claude/wt-digest/docs/reviews/security-review-2026-10-02-digest-pass34.md`, and its first line is `Commit: e93312d (A) / 823f494 (B)`. It follows `skills/security-reviewer/SKILL.md`: Trust Boundary Map, source table, Findings with Severity, Location, Boundary, Move, Confidence and the brief's Evidence and Legibility-target fields, Endorsement Claims with Verified / Not verified and `route: code-fact-check`, Primitive sweep, Summary Table, Overall Assessment. It serves the user goal of reaching a clean pass. F1 and F2 are the remaining known gaps outside the accepted limit, and both have one tested fix. F3 is a Low availability regression with a linear replacement. Nothing is Medium or above.
