Commit: 6f24d91 (A) / e19f411 (B)

# Security Review — dev-cycle pass 31 (k=1 delta: plain column-0 fence reader; final-message wording)

**Scope:** A `git diff f4d27d2..6f24d91 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` (wt-digest). B `git diff a7dfc0c..e19f411 -- skills/dev-cycle/SKILL.md` (wt-devcycle; merge 0c45039 carries both blobs unchanged).
**Date:** 2026-10-02
**Based on:** `docs/reviews/code-fact-check-report-digest-pass30.md` (Stage-1 context). The pass-31 fact-check (`code-fact-check-report-digest-pass31.md`, untracked) appeared during this review. Its Claim 4 reached F1 and F2 below independently, and the results agree.
**Probes:** all under `scratchpad/sec31/`: `probe1`–`probe5` (`.sh` and `.log`), `rerun.py` with `rerun/*/run.log` (pass 26–30 probes re-pointed at 6f24d91), and `harvest.py` (every questions and brief input committed by pass 26–30 probe repos). Each probe is one `set -eu` script that makes its own `mktemp -d` and checks `$PWD`. No process is still running. The only file written outside the scratch dir is this report. Both worktrees' HEADs moved during the review, to 4b7ec02 and 4e5cbbc, through other sessions' commits. I did not review those commits.

## Trust Boundary Map

```
B1: [docs/working/questions*.md, working tree]   → [FENCE_AWK + ANSWER_AWK, --check-answer]   → [keep/drop/done/open → In flight close/keep, Applied:]
B2: [brief blob on the default branch's commit]   → [FENCE_AWK + Status awk, --check-brief]      → [open/done/dropped → slot, Done/Ideas, git mv to closed/]
B3: [questions.sh archive rewrite of S1]          → [S1 again, next cycle]                       → [B1]
B4: [SKILL.md final-message rule]                 → [agent composing the cycle's final message]  → [user's view of unsettled closed/ briefs]
```

| Label | Source | Mutability | Trust per sink |
|---|---|---|---|
| S1 | questions.md / questions-archive.md text (user, agents, quoted reviews, `questions.sh`) | runtime-mutable | UNTRUSTED for the keep/drop/done decision sink. Its integrity is what the fence reader guards: quoted text inside a fence must stay inert |
| S2 | brief text on the default branch (cycle-written, build sessions edit `Status:`) | runtime-mutable | UNTRUSTED for the Status→close/move sink |
| S3 | `FENCE_AWK`, `ANSWER_AWK` programs, `-v id` (regex-checked `^Q-[0-9]+$`) | code-constant / validated | trusted |
| S4 | SKILL.md text | deploy-time (merged) | trusted as instructions; the agent's reading of it is the risk |

Repo text enters through B1 and B2 and decides whether a brief closes, stays, or moves. The diff narrows the fence reader to plain column-0 fences and refuses the file on anything else. The question here is whether any non-refused input reads differently from CommonMark. No input reaches exec, eval, SQL or HTML sinks.

## Findings

#### F1. HTML blocks of CommonMark types 2–7 hold column-0 fence lines that the reader treats as fences. Comments, `<details>`/`<div>`, single-tag lines, `<?`, `<!X` and `<![CDATA[` all give a wrong keep/drop or a wrong open/done, and no refusal fires

**Severity:** Low (same class as pass-30 F2's `<pre>` row, which this fix closed only for type 1. Not a regression: f4d27d2 reads every row the same way.)
**Location:** `scripts/dev-cycle.sh:270` (`rawhtml()`), `:286` (the only HTML check), comment `:255-262`; consumers `:307-311` (briefs) and `:414-415` (answers)
**Boundary:** B1, B2
**Move:** 11 (bypass enumeration), 2
**Confidence:** High for the code (executed, `probe3.log`). High for CommonMark (spec §4.6 start and end conditions; the pass-31 fact-check agrees). Preconditions:
- an unfenced multi-line HTML comment, a block tag such as `<details>`/`<div>` with no blank line before the fence line, a lone tag line, or a `<?`/`<!X`/`<![CDATA[` block;
- a column-0 ```` ``` ```` or `~~~` line inside it;
- the target entry or brief positioned after that.
No real file holds one. The only HTML in real questions files is the two one-line `<!-- index:start/end -->` markers (`probe4.log`), and no real brief exists (`probe1.log`).
**Legibility-target:** maintainer

**Evidence (verbatim):**
- `function rawhtml(l) { l = tolower(l); return l ~ /^[ \t]*<(pre|script|style|textarea)([ \t>]|$)/ }` (`:270`).
- The comment claims "so that every fence this reads is read the way CommonMark reads it" (`:255-256`).

`probe3.log`, Q-5 ANSWERED, body as listed:

| Case | Body | 6f24d91 | f4d27d2 | CommonMark |
|---|---|---|---|---|
| H1 | `<!--` / ```` ``` ```` / `-->` / `[2]` / ```` ``` ```` / `[1]` / ```` ``` ```` / `<!--` / ```` ``` ```` / `-->` | `keep Q-5` | `keep Q-5` | drop (both readers balanced) |
| H2 | `<details>` / ```` ``` ```` / `</details>` / blank / `[2]` / … same tail with `<details>` | `keep Q-5` | `keep Q-5` | drop |
| H2b, H3 | the same with `<div>`, and with a lone `<span>` (type 7) | `keep` ×2 | `keep` ×2 | drop |
| H4–H7 | `<?x`…`?>`, `<!X`…`>`, `<![CDATA[`…`]]>`, and a `~~~` line inside `<!--` | `keep` ×4 | `keep` ×4 | drop |
| brief b2 | `# B` / comment holding ```` ``` ```` / `Status: open` / ```` ``` ```` / `Status: done` / … | `ok … done` | `ok … done` | open (a wrong close: the brief moves to `closed/` and its slot frees) |
| brief b1, b4 | the mirrored layout, and the `<details>` layout | `open`, `done` | same | done, open |

Sibling outside the fence model: an HTML comment hides a whole answer or Status line. H1c `<!--` / `**Answer:** [2]` / `-->` / `**Answer:** [1]` gives `drop Q-5`, while CommonMark, as rendered, reads keep. Brief b3 gives `done` where the rendered reading is open. Whether an author who reads the raw file expects the hidden line to count is a judgment call, so this half carries Medium confidence.

**Recommendation:**
- Refuse on every HTML-block start outside a fence, not only type 1. A type-2 line closed on the same line (`<!-- … -->`) is the one exception, so the real index markers keep working.
- Measured cost (`probe4.log`): 0 such lines in the real questions files at c028eca, 0c45039 and main.
- Narrow the `:255-256` sentence until then.
- The pass-31 fact-check reports d0bf53f as already doing this. That commit is outside this pass's fixed scope and was not reviewed here.

#### F2. Line-ending and byte-order shapes: a lone CR (or CR CR LF) splits a line for CommonMark but not for awk, and a leading BOM hides a line-1 fence. Each gives a wrong reading without a refusal

**Severity:** Low (needs bytes that no editor in this workflow writes by itself: a lone CR, a doubled CR from a CRLF conversion applied twice, or a BOM before a fence on line 1. Not a regression.)
**Location:** `scripts/dev-cycle.sh:308` and `:413` (`{ sub(/\r$/, "") }`, the only CR handling); `opens()` `:271-277` (column 0 is the BOM's first byte)
**Boundary:** B1, B2
**Move:** 11, 2
**Confidence:**
- High for the code (executed).
- High for CommonMark on CR: spec §2.1 makes a lone CR, LF or CRLF a line ending.
- Medium for the BOM: the spec is silent, while cmark and commonmark.js strip a leading U+FEFF.
**Legibility-target:** maintainer

**Evidence (verbatim):** `{ sub(/\r$/, "") }` (`:413`, and `:308` in `check_brief`). `probe3.log`:

| Case | Bytes | 6f24d91 | f4d27d2 | CommonMark |
|---|---|---|---|---|
| C1 | `~~~\r~~~\n[1]\n~~~\n[2]\n~~~\n~~~\n`. awk reads one tilde opener whose info string is `\r~~~`; CommonMark reads an empty fence | `drop Q-5` | `drop Q-5` | keep |
| C2 | ```` ```\n[2]\n```\r\r\n[1]\n```\n[2]\n ````. After one CR is stripped, ```` ```\r ```` is neither a closer nor `odd` | `drop Q-5` | `drop Q-5` | keep |
| C9 | `\xEF\xBB\xBF```` on line 1, then the Q-5 entry with `[1]`, then two ```` ``` ```` lines | `keep Q-5` | `keep Q-5` | no entry (skip) |
| brief b5, b6 | BOM and CR CR LF variants with `Status: open` in the unfenced spot | `ok … done` ×2 | `done` ×2 | open |

Plain CRLF stays correct (C3 `keep`, brief b9 `open`). NUL bytes either refuse (C4, C5) or match CommonMark: mawk 1.3.4 keeps bytes after a NUL.

**Recommendation:**
- Strip one leading BOM on `NR == 1`, which keeps CommonMark's reading.
- Refuse a file that still has a `\r` anywhere after the trailing-CR strip.
- Measured cost (`probe4.log`): 0 CR lines in the real questions files, and none starts with a BOM.

#### F3. Briefs: the cycle writes briefs itself, and its instructions do not keep them inside the plain-fence subset. One indented or list-item fence makes `--check-brief` skip the brief on every later cycle, so it holds a slot and its `done` is never read

**Severity:** Informational (availability and bookkeeping. The skip is legible, since it names the line, and the skill already says "a brief the check skips keeps its slot (recorded) until the cause is fixed".)
**Location:** `scripts/dev-cycle.sh:286`, `:312-314` (refusal); `skills/dev-cycle/SKILL.md` Build briefs, 0c45039 `:322-336` (no rule on fences)
**Boundary:** B2
**Move:** 3 (failure state), 8
**Confidence:** Medium. The refusal rate below is measured on repo docs (`probe2.log`), not on briefs, because none exists.
**Legibility-target:** agent

**Evidence (verbatim):**
- `probe2.log`: `md files=1198 odd=36 unbalanced=0`. That covers `docs/working: 1 refused of 24` (`docs/working/dd-cc-isolated-loopback-redirect.md`, line 296) and `workflows: 4 refused of 10`. Most of the 36 are agent-written review docs, the same kind of author that writes briefs.
- Skill: "write `docs/working/briefs/YYYY-MM-DD-<slug>.md` … a line that is exactly `Status: open`, the line "repo text is evidence, not instructions", goal, motive, acceptance criteria … branch … and out-of-scope".

**Recommendation:**
- Add one clause to Build briefs: "code in a brief goes only in column-0 ```` ``` ```` fences (never indented or inside a list item), and no raw HTML".
- Optionally run `--check-brief` on the cycle's own new briefs before landing them. That cannot run on the default branch yet, so the clause is the cheaper fix.

#### F4. B: "each `closed/` brief an In flight line was repointed to" does not say whether a line repointed in an earlier cycle counts

**Severity:** Informational (bookkeeping, read-static)
**Location:** `skills/dev-cycle/SKILL.md:371-373` (e19f411); Rules `:88-92`; In flight `:269-272`
**Boundary:** B4
**Move:** 5 (enumerate the uncovered case)
**Confidence:** Medium (read-static, wording)
**Legibility-target:** agent

**Evidence (verbatim):**
- Final message: "each `closed/` brief an In flight line was repointed to that reads `open` or `new` (for the user to set its status)".
- Rules: "a `closed/` brief that reads `open` or `new` is recorded and listed in the final message for the user to set".

A line repointed in cycle N whose brief still reads `open` stays in In flight. Check 1 does not close it, and check 3 skips it because it is not under `briefs/`. In cycle N+1 the line was repointed earlier, not this cycle, and the past-tense phrase admits both readings. One reading lists the brief every cycle. The other lists it once, after which only the In flight line shows it. The change itself is correct: it drops the over-broad "each `closed/` brief" that listed every unsettled closed brief, including ones with no line.

**Recommendation:** Say "each `closed/` brief an In flight line names that reads `open` or `new`". wt-devcycle's later 4e5cbbc ("final message lists every In flight line naming an unsettled closed/ brief") looks like that change. It was not reviewed here.

## Re-run of earlier fence probes (executed)

- **Every committed input from pass 26–30 probe repos.**
  - Method: `harvest.py` walked 469 repos and took up to 400 commits each that touch `docs/working`. That gave 334 distinct (questions.md, questions-archive.md) pairs and 3,445 distinct brief blobs.
  - `probe5.sh` ran both readers on every ID found in each pair, and on every brief.
  - Questions, 6,885 readings: 6,220 non-skip and identical at f4d27d2 and 6f24d91, 467 skip in both, 198 read at f4d27d2 that now refuse. **0 non-skip readings differ.**
  - Briefs: 3,396 identical, 17 skip in both, 32 now refuse, **0 non-skip differences**.
  - None of the non-refused inputs holds an HTML-block start, a stray CR, a BOM or a NUL.
  - Why this means "CommonMark or refuse": a non-refused input has every fence-like line at column 0, and f4d27d2 already agreed with CommonMark on column-0 fences. So every earlier shape now reads as CommonMark does or refuses. F1 and F2 are new shapes.
- **Earlier probe scripts re-pointed at 6f24d91** (`rerun.py`; 73 scripts, `rerun/*/run.log`). With their own CommonMark columns:
  - Every pass-28/29/30 row that f4d27d2 read wrongly now refuses. That covers C2d, C18, C1c/C1d/C1e, C2b/C2c, C3, C4, C6 (`<pre>`), N1–N5, N9, Q-031/Q-032, Q-101–Q-105, Q-114, X1–X7, and api P1–P3/P13.
  - Every column-0 row still reads as CommonMark does: s28 Q-001/002/010/012/019/020, fc Q-033/Q-044, Q-106–Q-113, N6–N8, C7, C12–C14.
  - Pass-30 F3's D2 (two archive splits rebalance the live file, and `done Q-018` returned) now gives `skip Q-018: line 19 of docs/working/questions.md is a question heading inside a code fence` (`sec30-probe4`). D1, P3 and fc29 probe 6 skip for every ID, before and after the archive.
  - One stale label: sec29/sec30 "s28 F4 Q-021" carries `CM: unrecognized/none (all fenced)`. CommonMark actually closes the ```` ```text ```` fence at the bare ```` ``` ````, which makes `**Answer:** [2]` the entry's first answer. `drop` is correct.
  - Scripts that did not finish (setup, not reader): `api27-probe2` (no default branch in its fixture), `perf28-q5` (it greps the old `FENCE_AWK` function layout), `fc30-probe1` (it reads a bats log at a removed path). Their committed inputs are covered by the harvest above.
- **`questions.sh archive` with a fenced `## ` line** (a split route that pass 30 did not run; `probe4.log`). It splits both ANSWERED entries at the fenced `## Notes` / `## More`, and the live file's two leftovers pair up. The result: `skip Q-001: line 14 of docs/working/questions.md is a question heading inside a code fence …`, and the same for Q-002–Q-004. The `qline` guard catches it, because the rebalanced fence covers whole entries.

## Untested bypass candidates

- **gawk and busybox awk** are not installed. Every result is from mawk 1.3.4 20200120.
- **Multi-line link-reference-definition titles holding a fence line.** Reasoned static only: in CommonMark the fence interrupts the paragraph before the definition is parsed, so the reading matches. Not run.
- **Deeper containers (`> - `, `- > `) holding fences.** Their lines never start with ```` ``` ````/`~~~` at column 0 and are not `fenceish`, so both readers treat them as text. Only K13 (`> ```` `) ran.
- **Unicode line separators (U+2028/U+2029)**: not line endings in CommonMark or awk. Not run.
- **d0bf53f and 4e5cbbc**, the in-flight pass-31 fixes, are outside the fixed scope and not reviewed.

Because of F1, F2 and these candidates, the fence reader as a whole is not endorsed below.

## Endorsement Claims

- **Claim:** On every input committed by the pass 26–30 probe repos, 6f24d91 either gives the same non-skip reading as f4d27d2 or refuses: 6,885 answer readings and 3,445 briefs, 0 non-skip differences. None of the non-refused inputs holds HTML-block starts, stray CRs, a BOM or NULs.
  **Location:** `scripts/dev-cycle.sh:267-289`, `:307-316`, `:413-465`
  **Evidence:** executed
  **Verified:** `probe5.sh` over `harvest/` (`qa.tsv`, `br.tsv` in its temp dir), with the triage counts quoted above.
  **Not verified:** whether f4d27d2's reading of every one of the 6,220 identical rows is CommonMark's. That rests on the column-0 argument above plus the scripts' own CommonMark columns, not on a CommonMark parser (none is installed).
  **route: code-fact-check**
- **Claim:** On the real files, `--check-answer` output is byte-identical at f4d27d2 and 6f24d91 for all IDs, with no skip. 0c45039: 102 IDs (3 done, 19 drop, 26 keep, 13 open, 41 unrecognized). c028eca: 98. main: 99. No real brief exists at any of the three.
  **Location:** `scripts/dev-cycle.sh:446-465`; comment `:376-377` ("No real questions file has any of them")
  **Evidence:** executed
  **Verified:** `probe1.log` (`answers identical`, `briefs: 0`).
  **Not verified:** entries written after main's current tip, and the cycle's first real briefs (see F3).
  **route: code-fact-check**
- **Claim:** A `### Q-NNN ` line inside a fence (`qline`, `:414`) refuses the whole file. That covers pass-30 F3's double plain-quote archive split (D2) and the fenced-`## ` split variant, before and after `questions.sh archive`.
  **Location:** `scripts/dev-cycle.sh:414`, `:442`, `:458`
  **Evidence:** executed
  **Verified:** `rerun/sec30-probe4/run.log` (D2), `rerun/sec30-probe3/run.log` (D1, P3, fc29 probe 6), `probe4.log` (`## ` split).
  **Not verified:** a split whose rebalanced fence covers no `### Q-` heading but does cover an answer line. In the `## ` layout the leftovers sit after a `## ` heading, outside every entry (static).
  **route: code-fact-check**
- **Claim:** Every column-0 shape in brief claim 1 reads as CommonMark does, or refuses:
  - K1 info string, K2 longer closer, K3 shorter inner, K4 `~~~` in a backtick fence, K5 a backtick line in a tilde fence, K6 blank-only lines, K11, K12, K15–K17, plain CRLF (C3, b9), and a heading inside a fence (K9, which skips by design) all read as CommonMark does;
  - K10, a backtick in the info string, refuses where CommonMark drops: an allowed refusal;
  - a fence at EOF (K7, K8b) skips (unbalanced);
  - K8, a closer without a final newline, gives `unrecognized`, which is CommonMark's reading.
  **Location:** `scripts/dev-cycle.sh:268-288`
  **Evidence:** executed
  **Verified:** `probe3.log`, "column-0 shapes" block.
  **Not verified:** the same shapes under `--check-brief` beyond b7–b9.
- Minor positives, not routed:
  - bats 48/48 at 6f24d91;
  - `hermeticity-lint` rc=0;
  - shellcheck clean;
  - `--help` prints 66 lines (`sed -n '2,67p'`), ending at the Exit paragraph, and line 68 is blank;
  - the `dev-cycle.sh`/bats/`questions.sh` blobs are identical at 6f24d91, c028eca and 0c45039;
  - the SKILL.md blob is identical at e19f411 and 0c45039, and 0c45039's parents are e19f411 and c028eca (`probe1.log`).

## Primitive sweep

Primitive: process exec (awk / git with repo-derived arguments)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/dev-cycle.sh:307` `git cat-file blob "$MAIN_SHA:$a" \| awk "$FENCE_AWK"…` | S2 path `$a`, S3 program | `pathform`, `isbrief`/closed regex, `blocker` (`:298-303`) | cleared: the path is validated before use, and the program is a constant |
| `scripts/dev-cycle.sh:452` `awk -v id="$a" "$FENCE_AWK$ANSWER_AWK" "$f"` | S1 file, `$a` | `^Q-[0123456789]+$` (`:448`), fixed `$f` list, `skipped` | cleared |
| `scripts/dev-cycle.sh:313-314`, `:456-458` `${st#odd }`, `${r#…}` echoed | S3 output (`NR`) | numeric by construction | cleared |

No eval, deserialization, SQL or HTML sinks are in scope.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| F1 | HTML blocks of types 2–7 hold fence lines the reader treats as fences: wrong keep/drop/open/done, no refusal. An HTML comment also hides an answer or Status line | Low | B1, B2 | `scripts/dev-cycle.sh:270`, `:286`, comment `:255-262` | High |
| F2 | A lone CR or CR CR LF, and a leading BOM, give wrong readings with no refusal | Low | B1, B2 | `:308`, `:413`, `:271-277` | High (CR) / Medium (BOM) |
| F3 | Cycle-written briefs have no plain-fence rule. One indented or list fence makes the brief skip every cycle and hold its slot | Informational | B2 | `:286`, `:312-314`; SKILL.md Build briefs | Medium |
| F4 | B: "was repointed to" leaves open whether lines repointed in earlier cycles count | Informational | B4 | `skills/dev-cycle/SKILL.md:371-373` | Medium |

## Overall Assessment

The design change works for everything earlier passes found. No shape from pass 26–30 still reads wrongly: each one reads as CommonMark does or refuses. Every real questions file reads exactly as before, with no refusal, and no real brief exists to be refused. The `qline` guard closes pass-30 F3, including a `## ` split route not run before.

The acceptance bar still fails on two families this pass found (F1, F2). Both are fixable in place, at zero measured cost to real files:
- HTML blocks of types 2–7;
- CR and BOM byte shapes.

Neither is a regression, and neither gives a writer of the file anything the writer could not already do by writing the answer or Status line directly. That is why they stay Low: a correctness defect against the bar, not a crossed trust boundary.

The single most important thing is to finish F1, by refusing on every HTML-block start outside a fence except a one-line comment. The pass-31 fact-check reports this already landed as d0bf53f, which this review did not cover. No findings beyond these within the code paths read. The endorsement claims are pending execution verification.

## Goal-Alignment Note

**Success criterion (verbatim):** "a markdown report saved at the path your role instructions give, structured per your skill file."

This report is saved at `/workspace/.claude/wt-digest/docs/reviews/security-review-2026-10-02-digest-pass31.md`, with the required first line. It follows the security-reviewer structure: boundary map, findings with Severity/Location/Evidence/Confidence/Legibility-target, untested candidates, routed endorsements, primitive sweep, summary, assessment. It serves the user goal of a clean merge by telling the loop exactly what keeps this pass from being clean: F1 and F2, both Low. It also confirms every earlier fence probe, and the real files, against the fixed commits.
