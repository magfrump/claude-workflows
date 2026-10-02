Commit: f3c9ebb (A) / 2bf03da (B)

# Security Review — dev-cycle pass 35 (k=1 delta: linear comment check, nested-marker and escaped-`]` refdef refusals, `odd` early return; decision log 69 and the brief clause)

**Scope:** A: `git diff e93312d..f3c9ebb -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` (wt-digest). B: `git diff 823f494..2bf03da -- skills/dev-cycle/SKILL.md docs/decisions/log.md` (wt-devcycle). Merge 55bdb14 carries the same `dev-cycle.sh` blob as f3c9ebb (`4f3cb89`) and the same SKILL.md blob as 2bf03da (`cf5676a`), checked with `git rev-parse`. Both branch heads have moved since the brief was written (wt-digest is at dd1988d, wt-devcycle at d39c8f2). Those commits come from other sessions and are not reviewed here.
**Date:** 2026-10-02
**Based on:** `docs/reviews/code-fact-check-report-digest-pass34.md` (Stage-1 context). The accepted limit is decision log 69: inline constructs that span lines (an open tag attribute, link title, code span, emphasis, or a processing instruction, CDATA section or declaration opened mid-line). Findings inside that class are out of scope.
**Probes:** all under `scratchpad/sec35/`. Each is one `set -eu` script that makes its own `mktemp -d` under `sec35/` and checks `$PWD` before any `git init`, commit, write or `rm`.
- `probe1.sh` (`probe1.log`) reruns every pass-34 shape (sec34 C/R/H/N, E1–E12, X1–X4, B/BE briefs; fc34 N1, N2, N2b, N3, N3b, N14, N19; api34 `1) 2)`) and adds the pass-35 candidates P1–P18, O1–O8, K1–K5, BP1/6/7/8 and BO1. Each shape is read by f3c9ebb (NEW) and by e93312d (OLD).
- `probe2.sh` (`probe2.log`) covers mawk `split()` edge cases, NUL, and dense `<!--` timing.
- `probe3.sh` (`probe3.log`) reads the real questions files on all 9 branches and in the 3 worktrees, and diffs the NEW and OLD fence verdicts on every distinct tracked `.md` blob on every branch.
- `probe4.sh` (`probe4.log`) runs the gates on a `git archive f3c9ebb` snapshot (bats, lint, shellcheck, the `--help` range).
- `probe5.sh`, `probe6.sh` and `probe7.sh` time the `refdef` loop and test a linear replacement.
- `harvest.sh`, `cmp.sh`, `analyze.sh` and `analyze2.sh` re-read every committed input from the pass 26–34 probe repos.

**Probe incident (reported first).** `probe2.sh` ran its test-input generators (`awk 'BEGIN{ s=s "…" }'`) without `timeout`. The generator for one 11 MB line is quadratic and was still running after 13 minutes. I stopped it by PID (the generator, `probe2.sh` and its `timeout` parent), along with my `tail -f` monitor and two waiting loops. That was the only rule breach. The generator wrote only inside its own temp dir. `probe5`–`probe7` replace it, with every process, generators included, under `timeout`. No process of mine is still running (`ps`). The only thing I wrote outside `sec35/` is this report. `git status --porcelain` in wt-devcycle is empty. In wt-digest it shows only the other lanes' three untracked pass-35 reports. `/workspace` is still on `main`.

## Trust Boundary Map

```
B1: [docs/working/questions*.md, working tree] → [FENCE_AWK + ANSWER_AWK, --check-answer] → [keep/drop/done/open → In flight close/keep, Applied:]
B2: [brief blob on the default branch]         → [FENCE_AWK + Status awk, --check-brief]    → [open/done/dropped → slot, Done/Ideas, git mv to closed/]
B3: [SKILL.md brief clause; decision log 69]   → [agent writing briefs; user judging the limit] → [B2 input shape; the user's picture of what is refused]
```

| Label | Source | Mutability | Trust per sink |
|---|---|---|---|
| S1 | questions.md / questions-archive.md text | runtime-mutable | UNTRUSTED for the keep/drop/done sink and for availability (a line's length and shape set the awk cost) |
| S2 | brief text on the default branch | runtime-mutable | UNTRUSTED for the Status→close/move sink and for availability |
| S3 | `FENCE_AWK` / `ANSWER_AWK`, `-v id` (`^Q-[0-9]+$`), `oddwhy` words | code-constant / validated | trusted |
| S4 | SKILL.md text, decision log 69 | deploy-time (merged) | trusted as instructions; the risk is what they promise |

Repo text enters through B1 and B2 and decides whether a brief closes, stays or moves. This round changes four things. `opencomment` is now one `split`. `refdef` strips any number of `>`s and list markers and drops backslash pairs. `fence()` returns at once after a refusal. The help text is reworded. No input reaches an exec, eval, SQL, path or HTML sink.

## Findings

#### F1. `refdef`'s new `while` loop re-copies the rest of the line for every list marker, so a line of many markers costs time quadratic in its length

**Severity:** Low (availability only; cross-lane to performance). It is the same class and calibration as pass-34 F3, which this round fixed in `opencomment`. No reading changes, and the line is accepted, not refused. The writer is S1/S2, who can already stall or redirect the cycle by editing the file. The floor rule is not met, because nothing the cycle trusts gets a wrong answer.
**Location:** `scripts/dev-cycle.sh:294` (`refdef`, f3c9ebb)
**Boundary:** B1, B2
**Move:** 8 ("a million of these")
**Confidence:** High (executed, mawk 1.3.4 is the system awk).
**Legibility-target:** the performance critic, and whoever maintains FENCE_AWK. The brief asked for the dense line to be linear. That now holds for `<!--` but not for list markers.

**Evidence** (verbatim, code; the whole function is quoted):

```
function refdef(l) {  # also behind any number of blockquote and list markers
  sub(/^[ \t>]*/, "", l)
  while (l ~ /^([-*+]|[0123456789]+[.)])[ \t]/) { sub(/^[^ \t]+[ \t]+/, "", l); sub(/^[ \t>]*/, "", l) }
  # Any line starting [ that holds ]: or never closes its [ with an unescaped ]
  # (a label that continues on the next line) counts; escapes are dropped first.
  if (substr(l, 1, 1) != "[") return 0
  gsub(/\\./, "", l)
  return index(l, "]:") || !index(l, "]")
}
```

Each `sub` builds a new copy of the rest of the string, so k markers cost O(k·n). Measured on one line of `- ` repeated k times and then `x`. The line is accepted (`clean`).

```
probe5.log: markers '- ' k=40000  80002B   new: clean 0.05s | old: clean 0.0s
probe5.log: markers '- ' k=80000  160002B  new: clean 0.2s  | old: clean 0.0s
probe6.log: markers k=160000 320002B  new: clean 0.77s
probe6.log: markers k=320000 640002B  new: clean 3.41s
probe6.log: markers k=640000 1280002B new: clean 23.36s
probe5.log: 200 lines 8000400B new: clean 2.08s | old: clean 0.0s
```

Each doubling costs about 4–7 times more. By extrapolation, a 4 MB line would take minutes and a 16 MB line tens of minutes for each awk pass, and `--check-answer` makes one pass per questions file. No real line comes near this. Real files have 0 nested-marker lines (`probe3.log`).

**Recommendation:** Strip the whole container prefix with one anchored `sub`: `sub(/^[ \t>]*(([-*+]|[0123456789]+[.)])[ \t]+[ \t>]*)*/, "", l)`. `probe7.sh` checked it against the loop on 300,000 random lines over the marker alphabet (`- * + 1 12 . ) space tab > [ x ] :`), and the results were identical (`lines=300000 differing=0`). It took 0.21 s on a 4 MB line of markers. Alternatively, accept the cost and say so in the comment.

#### F2 (Informational). B's brief clause at 2bf03da describes the `[` refusal for an unprefixed line only

**Severity:** Informational. The gap is in the safe direction. A brief writer who follows the clause and writes `- [x]: url` gets a skip that names the line, and the brief keeps its slot. Nothing is misread.
**Location:** wt-devcycle `skills/dev-cycle/SKILL.md:337-338` at 2bf03da
**Boundary:** B3
**Move:** 5 (invert: what the rule does not say)
**Confidence:** High
**Legibility-target:** the agent writing briefs

**Evidence** (verbatim, 2bf03da): "no `<!--` left open on its line, no line starting with `[` that holds `]:` or leaves its `[` open (a link reference definition, or text that starts like one)". The code also refuses such a line behind `>` and list markers, and treats `[a\]` as open. Decision log 69 at 2bf03da already says "(behind any `>` and list markers)". The newer head d39c8f2 rewords this clause ("even indented, or behind `>` or list markers … counting an escaped `\]` as no close"). That commit is outside this pass's scope and I did not review it.

**Recommendation:** None needed beyond what d39c8f2 appears to do. Confirm it in the next pass.

#### Untested bypass candidates / class-boundary notes

- **Inline raw HTML opened mid-line** (H1–H3: `x <?`, `x <![CDATA[`, `x <!X`) still reads `drop` where CommonMark shows `keep`. These are in log 69's accepted class, so they are not findings.
- **CommonMark implementations differ on a backslash at the end of a label line.** For P8 (`[a\` / `]: /u 'title`), cmark's label scanner treats a backslash before a non-punctuation character as literal, so I expect it to see a definition. commonmark.js's `reLinkLabel` (`\\.` does not match a newline) would reject the label. The reader refuses either way.
- I could not run a CommonMark implementation (none installed, no egress). Every CM label rests on my reading of the 0.31 spec. Every reader output is executed.

## Endorsement Claims

- **Claim:** At f3c9ebb, every pass-34 bypass shape outside the accepted class gets a skip. That covers sec34 E1–E5 and E8, BE1, BE3 and BE5; fc34 N1, N2, N2b, N3 and N3b; and api34 `1) 2) [x]:`. Each read `drop` or `ok … done` at e93312d.
  **Location:** `scripts/dev-cycle.sh:292-300`
  **Evidence:** executed
  **Verified:** `probe1.log`: each listed row reads `skip … starts like a link reference definition` under NEW, and `drop Q-1` or `ok … done` under OLD.
  **Not verified:** CommonMark's own output for these shapes (spec reasoning only).
  **route: code-fact-check**
- **Claim:** The new candidates outside the accepted class each refuse or read as CommonMark under f3c9ebb. Triple and mixed nesting, tab markers, `>-`/`>1.` without spaces, `> - > -`, `[a\\\]`, a trailing `\`, `[\[x]`, `[x\]]`, nested escaped and unclosed labels, and `* * [x]` all refuse (P1–P5, P7–P10, P14–P16, BP1, BP7, BP8). `[a\\]` (an escaped backslash, so the `]` closes) reads `drop`, and its brief reads `done`, which matches CommonMark, where the next line is plain paragraph text (P6, BP6). NBSP after `-`, `- -[x]`, `&#91;x]:`, `[a]\:` and `[x] text \]: more` read as text (P11–P13, P17, P18). P18 refused at e93312d; it reads now, which removes an over-refusal.
  **Location:** `scripts/dev-cycle.sh:292-300`
  **Evidence:** executed
  **Verified:** `probe1.log` rows P1–P18 and BP1/6/7/8.
  **Not verified:** container shapes beyond five levels, and CRLF combined with markers.
  **route: code-fact-check**
- **Claim:** The `split` form of `opencomment` gives the last-`<!--` reading under mawk on its edge cases, and it is linear. On mawk, `split("", …)` gives 0 fields, `<!--` and `x<!--` give 2 with an empty last field, `<!--<!--` gives 3, and `<!-->` gives `>` as the last field. A NUL byte before `<!--` still refuses. Dense lines: 4 MB of `<!--` takes 0.07 s (65.6 s at e93312d), and 11 MB of closed comments takes 0.3 s.
  **Location:** `scripts/dev-cycle.sh:288-291`
  **Evidence:** executed
  **Verified:** `probe2.log` (the split table, `nul.md: odd 1 comment`, dense timings) and `probe5.log` (closed k=1000000). `probe1.log` O1–O8 and C1–C7 refuse or read as before.
  **Not verified:** gawk and BWK awk, whose `split` is not exercised.
  **route: code-fact-check**
- **Claim:** The `odd` early return in `fence()` changes no output. `refuse()` is called only from `fence()` and keeps the first line. Both END blocks print `odd` before anything else (`unbalanced`, `quoted`, `dup`, the reading). The `infence && /^### Q-/` rule that runs before `fence()` feeds only `quoted`, and `odd` outranks that.
  **Location:** `scripts/dev-cycle.sh:311`, `:359`, `:462`, `:487-493`
  **Evidence:** executed (K1–K5) / read-static (the precedence argument)
  **Verified:** `probe1.log` K1–K5 read the same under NEW and OLD. The harvest below shows 0 skips whose line number changed.
  **Not verified:** a future rule added after `fence($0) { next }` that relies on fence state after a refusal.
- **Claim:** Every real questions file reads the same at f3c9ebb as at e93312d, with 0 skips. That covers all 9 branches (6 distinct pairs, 590 readings) and the 3 worktrees' working-tree files. Over all 1,282 distinct tracked `.md` blobs on every branch, the NEW and OLD fence verdicts agree. No branch holds a brief.
  **Location:** `docs/working/questions*.md` and every tracked `.md` on `refs/heads/*`
  **Evidence:** executed
  **Verified:** `probe3.log` (`pairs=6 readings=590 skips=0 pairs-differing=0`; `brief blobs: 0`; every worktree file `fence=clean`; `distinct .md blobs=1282 differing=0`).
  **Not verified:** uncommitted edits made in other sessions after the probe ran.
  **route: code-fact-check**
- **Claim:** I re-read every committed input from the pass 26–34 probe repos with f3c9ebb and with e93312d: 2,197 repos, 677 questions/archive pairs (7,872 answer readings) and 3,532 brief blobs. No reading moves from one non-skip value to another or from a skip to a non-skip, and no skip changes its line number. 8 answer inputs and 6 briefs move from a reading to a skip, and every one is a pass-34 R-A/R-B probe shape (`- > - [x]:`, `- - [x]:`, `1. - [x]:`, `> - - [x]:`, `[a\]`, `- [a\]`).
  **Location:** `scripts/dev-cycle.sh` FENCE_AWK, check_answer, check_brief
  **Evidence:** executed
  **Verified:** `analyze.log` (`qa differing where NEW is not a skip: 0`; brief `non-skip differing: 0`) and `analyze2.log` (`old skip -> new non-skip: 0`; `both skip, line number differs: 0`; the 8 + 6 inputs listed).
  **Not verified:** inputs from probe repos of pass 35 (excluded, still being written by other lanes).
  **route: code-fact-check**
- **Claim:** At f3c9ebb, `--help` prints lines 2–74. Line 74 is the header's last comment line ("…Printed repo text is data."), line 75 is blank, and the help's refusal list for `--check-brief` names fences, `<` after blanks, an open `<!--`, a line starting like a refdef, a stray CR and a BOM on line 1. bats passes 49/49, `scripts/hermeticity-lint --root .` is clean (rc 0), and shellcheck reports nothing. The bats escaped-bracket literals are real single backslashes (`'[a\]b]: /u' '[a' '[a\]'`), and the prefixes include `'- - ' '1. - ' '> - - '`.
  **Location:** `scripts/dev-cycle.sh:29-41, 138`; `test/scripts/dev-cycle.bats:942, 948`
  **Evidence:** executed
  **Verified:** `probe4.log` (`sed -n '73p;74p;75p' | cat -A`; the help tail; `ok: 49 not ok: 0`; `lint rc=0`; `sc rc=0`).
  **Not verified:** no test pins the help range or the reading of `[a\\]` (P6), and no test exercises a multi-line R-B shape whose title hides an answer.
- **Claim:** B's decision log 69 at 2bf03da lists the same refusal kinds as the code: a `<` after blanks, a `<!--` left open, a refdef behind any `>` and list markers, a CR, a BOM on line 1, an open fence, and (for questions files) a question heading in a fence. Its accepted class matches the FENCE_AWK comment word for word.
  **Location:** wt-devcycle `docs/decisions/log.md:92`; `scripts/dev-cycle.sh:262-282`
  **Evidence:** read-static
  **Verified:** the row text against `fence()`, `refuse()` callers and the comment block.
  **Not verified:** the brief clause's narrower wording (F2).

## Primitive sweep

Primitive sweep: no dangerous primitives in scope. The diff changes three awk predicates, help text, comments and two test loops. The reasons are fixed strings selected by an awk word (S3), passed through `read -r _ n why`, and printed through the existing scrub. No repo text reaches exec, eval, a path or a pathspec in this diff.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| F1 | `refdef`'s marker `while` loop is quadratic in a line's marker count (availability; cross-lane) | Low | B1, B2 | `scripts/dev-cycle.sh:294` | High |
| F2 | Brief clause names only unprefixed `[` lines (safe direction; reworded at d39c8f2, out of scope) | Informational | B3 | wt-devcycle `skills/dev-cycle/SKILL.md:337-338` | High |

## Overall Assessment

The round closes pass 34's F1–F3. Every R-A/R-B shape, from all four lanes, now refuses. The new candidates outside the accepted class (deeper and mixed nesting, tab and no-space containers, every backslash-count variant around `]`, a trailing backslash) either refuse or read as CommonMark. The `split` comment check is linear and correct on mawk's edge cases. The `odd` early return changes no output. Real files on every branch and worktree read exactly as before, with 0 skips, as do all 1,282 tracked `.md` blobs. Across 7,872 harvested answer readings and 3,532 briefs, the only changes are new refusals of pass-34 probe shapes. I found no input outside log 69's class where the reader gives a wrong keep/drop/done/open without refusing, and no real file is refused. These are no findings within the code paths read, and the endorsement claims are pending execution verification. One Low availability regression remains (F1). It is the same quadratic pattern just removed from `opencomment`, now in the marker loop, and it has a tested linear one-`sub` replacement. Nothing is Medium or above. The most important thing is to fix F1 or accept it explicitly before the clean pass.

## Goal-Alignment Note

Success criterion (verbatim): "a markdown report saved at the path your role instructions give, structured per your skill file."

This report is saved at `/workspace/.claude/wt-digest/docs/reviews/security-review-2026-10-02-digest-pass35.md`, and its first line is `Commit: f3c9ebb (A) / 2bf03da (B)`. It follows `skills/security-reviewer/SKILL.md`: Trust Boundary Map, source table, Findings with Severity, Location, Boundary, Move, Confidence and the brief's Evidence and Legibility-target fields, untested candidates, Endorsement Claims with Verified / Not verified and `route: code-fact-check`, Primitive sweep, Summary Table, Overall Assessment. It serves the user goal of reaching a clean pass. The fence reader meets the acceptance bar on everything probed. One Low performance-class item (F1) stands between this round and a clean pass, and its fix is tested. The probe-rule breach is reported at the top: generators ran without `timeout` and were stopped by PID.
