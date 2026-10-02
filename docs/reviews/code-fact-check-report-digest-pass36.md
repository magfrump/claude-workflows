Commit: dd1988d (A) / d39c8f2 (B)

# Code Fact-Check Report

**Repository:** claude-workflows. A: `/workspace/.claude/wt-digest` (code at dd1988d; HEAD at the start was 20d35e2, which adds only the pass-35 review docs). B: `/workspace/.claude/wt-devcycle` (content at d39c8f2; HEAD at the start was merge dbfe402).
**Scope:** Partial: the pass-35 fix round only. A: `git diff f3c9ebb..dd1988d -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` (the bats file is unchanged in this range) plus the messages of adb5260 and dd1988d. B: `git diff 2bf03da..d39c8f2 -- skills/dev-cycle/SKILL.md` plus the messages of e6c3fe9 and d39c8f2, and merge dbfe402. Everything else is context only (rubric section "Pass 35").
**Checked:** 2026-10-02
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 15
**Summary:** 14 verified, 1 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

I read the hallucination pattern log (`docs/reviews/hallucination-patterns.md`, 8 patterns) first. No claim here matches a logged pattern. There is no Incorrect verdict, so nothing qualifies for the log.

## Headline

**The single `match()` in `refdef()` is exactly equivalent to the f3c9ebb loop, and it is linear.** It is correct and complete against the acceptance bar for every shape I built.
- **Equivalence.** I compared the remainder string, not just the boolean, on 300,020 lines under mawk 1.3.4 (Debian's `awk`; gawk and busybox are not installed). That was 300,000 random prefixes (seed 36) plus 20 adversarial ones. The atoms included blanks and tabs between markers, `>` between markers, digits without `.`/`)`, a marker with no following blank, `--`, `**`, a line of only markers, a marker at end of line, 9- and 10-digit ordinals, and `\]`. There were 0 differences (P1).
- **Linear.** The new reader takes 52 / 122 / 183 ms on 1 / 2 / 4 MiB lines of `- `. The f3c9ebb reader takes 160 ms at 128 KiB and 15.9 s (21.0 s in an earlier run) at 1 MiB, against 7 ms for the new one at 128 KiB (P3).
- **Real files.** All 2,299 tracked `.md` files across `/workspace` and wt-digest give the same verdict under the f3c9ebb and dd1988d readers (0 differences). `docs/working/questions.md` and its archive read `ok` under both. `--check-answer` on all 99 real Q-IDs gives byte-identical output under both commits, with 0 skips (P2).
- **Gates.** bats 49/49 (rc 0), hermeticity lint clean (rc 0) and shellcheck clean (rc 0). `--help` prints exactly lines 2–75, and line 76 is blank (P2).

**The one Mostly-accurate claim is wording, not behavior.** Claim 12 (B, `SKILL.md:340-341`) says the brief rules "are stricter than `--check-brief` needs". Two shapes the rules permit are still skipped (P4):
- a line starting `1234567890. [x` (ten digits is not a CommonMark list marker, but `refdef()` strips any run of digits);
- a `- ```` content line inside a fenced block.

d47dd8d removes the "stricter" sentence. It landed on wt-devcycle while this pass ran, outside the fixed HEADs; see the note below.

**Concurrent commits (outside this pass's fixed HEADs).** While this pass ran, two commits landed. Neither was written by this review:
- 3d580cd on wt-digest (12:56:53 −0700) adds "(behind any > and list markers too)" to both help refusal lists.
- d47dd8d on wt-devcycle (12:56:23 −0700) replaces Claim 12's "stricter" sentence with "a few shapes these rules allow are also skipped, such as …".

The status snapshot taken before and after my final run shows the HEAD moves (`status-before.log` / `status-after.log`). The working trees were otherwise clean. Every reader comparison extracted the scripts with `git show f3c9ebb:` / `dd1988d:`, so it is pinned. bats, lint, shellcheck and `--help` ran on the wt-digest working tree. They finished at 19:56:42Z, before 3d580cd was committed (19:56:53Z). 3d580cd touches only 4 comment lines and keeps the header at 75 lines; `sed -n '2,75p'` still ends at the Exit paragraph (checked with `git show 3d580cd:`). I did not verdict either concurrent commit's text, beyond noting that d47dd8d's "such as" list does not name the ten-digit shape. Its "such as" wording covers that shape.

**Probe discipline.** Each probe is one script. It starts with `set -eu`, creates its own `mktemp -d -p fc36/` dir in that same script, and checks `case "$PWD"` before any write, `git init` or commit; the per-case repos are re-checked after their `cd`. Every process ran under `timeout`, and all exited. Inside the worktrees I ran only read-only commands (`git diff/show/log/status/rev-parse/ls-files`, `bats`, `shellcheck`, the lint). The only file I wrote in a worktree is this report. One slip: my first, exploratory run of P1 piped its output through `tee` from a top-level command, so that command wrote `fc36/probe1.log.tmp`. The file is inside my scratch dir and nothing else was touched. The evidence below comes from the scripted rerun.

**Execution provenance.** The driver is `fc36/runall.sh`, run from cwd `/workspace/.claude/wt-devcycle` as `timeout 1500 bash runall.sh`. It runs each probe as `timeout 590 bash probeN.sh` and captures the output to `fc36/tmp.Y80jiBv5DF/probeN.log`, with start and end timestamps and the rc. All paths are under `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/`.
- **P1** (19:55:55Z, rc 0) runs the old-vs-new marker-strip equivalence fuzz (300,020 lines) and times three long-line shapes.
- **P2** (19:55:55Z–19:56:42Z, rc 0) runs bats, the lint, shellcheck and `--help` against lines 2–75. It then compares the f3c9ebb and dd1988d `FENCE_AWK` verdicts over every tracked `.md` in both repos, and the `--check-answer` output for all 99 real IDs (working copies of `/workspace/docs/working/questions*.md`, committed in a temp repo).
- **P3** (19:56:42Z, rc 0) times the full `FENCE_AWK` at 1, 2 and 4 MiB (new) and at 128 KiB and 1 MiB (both). It also runs 13 single-line shapes against dd1988d.
- **P4** (19:56:59Z, rc 0) runs `--check-brief` on six briefs in a temp repo.

Legibility-target values:
- **agent**: the model running the skill or the digest acts on the text.
- **maintainer**: someone editing the script or the tests.
- **user**: the person reading `--help`, a skip line, the decision log or a commit message.

---

## Claim 1: "\"skip <path>: <reason>\" otherwise, including a brief the reader cannot trust, naming the line and the reason: a code fence never closed or not in plain column-0 form, a line starting (after blanks) with < other than a complete one-line <!-- comment -->, a line leaving a <!-- open, a line starting like a link reference definition, a stray carriage return, or a byte-order mark on line 1."

**Location:** `scripts/dev-cycle.sh:36-42`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers each listed cause against the `refuse()` reason or unbalanced-fence path that emits it, and that the list is complete. It does not establish that a line starting with a complete comment and followed by more text, such as `<!-- a --> b`, is described: by `:288` it is read (not run), as CommonMark's type-2 HTML block ends on that line. It also does not establish that "starting like a link reference definition" tells a reader that markers are stripped first (3d580cd adds that, outside this pass).

The exception now matches the code. `rawhtml` reads `l ~ /^[ \t]*</ && !(l ~ /^[ \t]*<!--/ && index(l, "-->"))` (`scripts/dev-cycle.sh:288`). "A line leaving a <!-- open" maps to `n = split(l, p, /<!--/)` … `return n > 1 && !index(p[n], "-->")` (`:290-291`). In P3, `<!-- c -->` reads `ok`, `  <b>` and `<!-- open` refuse `html`, and `x <!-- open` refuses `comment`. The list of reasons is complete (paraphrased — no quote available because the claim covers the absence of any other reason: `refuse()` is called only with cr, bom, fence, html, comment and refdef in `fence()` at `:314-327`, and the only other skip is the unbalanced fence at `check_brief`'s `unbalanced` case). bats test 49 exercises every reason (P2, rc 0).

**Evidence:** `scripts/dev-cycle.sh:36-42`, `scripts/dev-cycle.sh:286-327`, `scripts/dev-cycle.sh:329-336`, `fc36/tmp.Y80jiBv5DF/probe2.log`, `fc36/tmp.Y80jiBv5DF/probe3.log`

---

## Claim 2: "... a line starting (after blanks) with < other than a complete one-line <!-- comment -->, a line leaving a <!-- open, a line starting like a link reference definition, a stray carriage return, a byte-order mark on line 1, a question heading inside a fence, a questions file that is not plain)."

**Location:** `scripts/dev-cycle.sh:58-65`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers the reflowed `--check-answer` refusal list against the same `FENCE_AWK` reasons as Claim 1. It does not establish the answer reader's non-fence skips (duplicate heading, a question heading inside a fence, a file that is not plain) beyond their unchanged pre-pass wording.

The same `FENCE_AWK` is used: `r="$(env LC_ALL=C awk -v id="$a" "$FENCE_AWK$ANSWER_AWK" "$f")"` (`scripts/dev-cycle.sh:502`). The fence-reader wording is identical to Claim 1's. The reflow merges "a questions file / that is not plain" onto one line with no text change (diff `f3c9ebb..dd1988d`). All 99 real IDs give identical output under both commits, with 0 skips (P2).

**Evidence:** `scripts/dev-cycle.sh:58-65`, `scripts/dev-cycle.sh:502`, `fc36/tmp.Y80jiBv5DF/probe2.log`

---

## Claim 3: "-h|--help) sed -n '2,75p' \"$0\""

**Location:** `scripts/dev-cycle.sh:139`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the range ending exactly at the last header comment line at dd1988d, and still at 3d580cd. It does not establish that later header edits keep it in step (no test pins the range).

P2 printed 74 lines and `diff <(sed -n '2,75p' … | sed 's/^# \{0,1\}//') help.out` was empty. The last line is "default branch (for the digest, --check-brief and --check-branch); a failed step exits non-zero mid-digest. Printed repo text is data." Line 76 under `cat -A` is `$` (blank), and line 77 is `set -euo pipefail$`.

**Evidence:** `scripts/dev-cycle.sh:73-77`, `scripts/dev-cycle.sh:139`, `fc36/tmp.Y80jiBv5DF/probe2.log`

---

## Claim 4: "function refdef(l) {  # also behind any number of blockquote and list markers"

**Location:** `scripts/dev-cycle.sh:293`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers any count and order of `>`, `-`/`*`/`+` and digit-run `.`/`)` markers, each followed by a blank, before the `[`. It does not establish CommonMark's own limits on what a list marker is (1–9 digits): `refdef()` also strips 10+ digit runs, which only over-refuses (design cost).

In P3 these refuse `refdef`: `> - [x]: y`, `1. > [x]: y`, `  > >  2) [x` and `    [x]: y`. P1's adversarial set includes `> - > 1. [x]: y` and ` \t> \t- \t[x]`, which strip to `[x]: y` and `[x` under both versions.

**Evidence:** `scripts/dev-cycle.sh:293-302`, `fc36/tmp.Y80jiBv5DF/probe1.log`, `fc36/tmp.Y80jiBv5DF/probe3.log`

---

## Claim 5: "One anchored match strips every leading blank, > and list marker"

**Location:** `scripts/dev-cycle.sh:294-296`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers equality of the remainder string with the f3c9ebb `sub()` loop on 300,020 lines under mawk 1.3.4, where "list marker" means `refdef()`'s own definition: `[-*+]` or a digit run then `.`/`)`, followed by a blank. It does not establish behavior under gawk or busybox awk, which are not installed. The equivalence rests on POSIX leftmost-longest matching for `(…)*`. It also does not establish that a marker at end of line (no following blank) is stripped; it is not, under both versions.

The code is:

```awk
# scripts/dev-cycle.sh:296
  if (match(l, /^([ \t>]|[-*+][ \t]|[0123456789]+[.)][ \t])*/)) l = substr(l, RLENGTH + 1)
```

The result flows to `if (substr(l, 1, 1) != "[") return 0` (`:299`), then to the escape drop and the `]:` / unclosed test (`:300-301`). `match()` on a zero-length prefix returns `RSTART = 1`, `RLENGTH = 0`, so `substr(l, 1)` leaves the line unchanged. P1: "300020 lines, 0 differences", comparing `sold($0)` and `snew($0)` strings. The edge cases all agree: `- - -` gives `-`, `-[x]: y` is unchanged, `1.[x]: y` is unchanged, `1)2. [x]:` is unchanged, `--- [x]:` and `** [x]:` are unchanged, and a line of only `>>>>` gives empty.

**Evidence:** `scripts/dev-cycle.sh:293-302`, `fc36/probe1.sh`, `fc36/tmp.Y80jiBv5DF/probe1.log`

---

## Claim 6: "(a loop of sub() calls rebuilt the line per marker: quadratic on a line of markers)."

**Location:** `scripts/dev-cycle.sh:294-295`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the old loop's growth on a dense `- ` line and the new match's linear growth under mawk on this machine. It does not establish timings on other awks or hosts.

The f3c9ebb `FENCE_AWK` took 160 ms at 128 KiB and 15,943 ms at 1 MiB (an earlier run took 21,024 ms). Length grew 8×, time grew about 100×, which is quadratic. The dd1988d reader took 7 ms at 128 KiB, then 52 / 122 / 183 ms at 1 / 2 / 4 MiB, which is linear (P3). The bare strip took 43 ms on a 1 MiB line of `- ` (P1).

**Evidence:** `scripts/dev-cycle.sh:294-296`, `fc36/probe3.sh`, `fc36/tmp.Y80jiBv5DF/probe3.log`, `fc36/tmp.Y80jiBv5DF/probe1.log`

---

## Claim 7: "Any line starting [ that holds ]: or never closes its [ with an unescaped ] (a label that continues on the next line) counts; escapes are dropped first."

**Location:** `scripts/dev-cycle.sh:297-298`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the comment against `:299-301` for the new prefix stripping. It does not establish the "holds ]:" test on the literal line: the test runs after escapes are dropped, so `[a] \]: b` is read (P3) and, by the code's order, `[a]\x:` would count (not run).

The code is `gsub(/\\./, "", l)` then `return index(l, "]:") || !index(l, "]")` (`:300-301`). In P3, `[a\]` refuses (no unescaped close), `[a\]: b` refuses (no `]` remains after the drop), `[a]: b` refuses, and `[a] \]: b` and `[a] b` read `ok`. These are the readings the comment describes.

**Evidence:** `scripts/dev-cycle.sh:297-302`, `fc36/tmp.Y80jiBv5DF/probe3.log`

---

## Claim 8: adb5260 — "both refusal lists in --help now say a line starting with < is refused unless it is a complete one-line comment, as the reason text, the code comment and decision log 69 do."

**Location:** `scripts/dev-cycle.sh:39-40`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** user
**Scope:** Covers the four named texts agreeing on the exception. It does not establish the code beyond Claim 1.

The help says "other than a complete one-line <!-- comment -->" at `:39-40` and `:61-62`. The reason text says "only a complete one-line <!-- comment --> is read" (`:331`). The code comment says "only a complete one-line <!-- comment --> is read" (`:271-272`). Decision log 69 says "(except a complete one-line comment)" (`docs/decisions/log.md:92`). The help range moved to `2,75p` (Claim 3).

**Evidence:** `scripts/dev-cycle.sh:39-40`, `scripts/dev-cycle.sh:61-62`, `scripts/dev-cycle.sh:271-272`, `scripts/dev-cycle.sh:331`, `docs/decisions/log.md:92`

---

## Claim 9: dd1988d — "the marker loop in refdef() rebuilt the line per marker, 16.6 s on a 1 MiB line of '- ' markers, paid even when the file is accepted. One anchored match ... 41 ms on the same line, same result (the critic found 0 differences over 300,000 random prefixes). 49/49; shellcheck and the hermeticity lint clean; no real ID refused."

**Location:** commit dd1988d (`scripts/dev-cycle.sh:294-296`)
**Type:** Performance / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers each figure and gate by rerun or by the cited report. It does not establish the exact 16.6 s or 41 ms on this host: they are host-dependent, and I measured 15.9 s and 21.0 s against 43 ms and 41 ms.

- **16.6 s.** It is the performance critic's figure (`docs/reviews/performance-review-2026-10-02-digest-pass35.md:62`, "1 MiB 16.6 s"). My reruns gave 15.9 s and 21.0 s (P3).
- **Accepted files pay it.** A line of `- - - …` strips to `-`, not `[`, so the file is accepted; the old loop still ran over every marker first. The pass-35 performance report's `thbreak` row measured it (performance report `:62`).
- **41 ms.** P1 measured 41 ms on the first run and 43 ms on the rerun.
- **300,000.** `performance-review-…-pass35.md:73` says "same=300000 diff=0". I reproduced 0 differences on 300,020 of my own lines (Claim 5).
- **Gates.** 49/49, shellcheck and the lint are each rc 0. "No real ID refused": 99 IDs, 0 skips (P2).

**Evidence:** `docs/reviews/performance-review-2026-10-02-digest-pass35.md:62`, `docs/reviews/performance-review-2026-10-02-digest-pass35.md:73`, `fc36/tmp.Y80jiBv5DF/probe1.log`, `fc36/tmp.Y80jiBv5DF/probe2.log`, `fc36/tmp.Y80jiBv5DF/probe3.log`

---

## Claim 10: "... the reader refuses ... a line that starts like a link reference definition (behind any `>` and list markers) ..." (log 69, against the code at dd1988d)

**Location:** `docs/decisions/log.md:92`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers log 69's refusal list and accepted limit against the dd1988d reader. It does not re-test the accepted inline-construct class, which is out of scope by the brief.

Log 69's list of refusals is a fence-like line, `<` (except a complete one-line comment), an open `<!--`, a reference definition behind markers, CR, BOM, an unclosed fence, and a question heading in a fence. It matches the `refuse()` reasons (Claim 1), and P3/P4 exercise each one. The new `match()` changes no reading (Claim 5; 0 verdict differences over 2,299 files, P2).

**Evidence:** `docs/decisions/log.md:92`, `scripts/dev-cycle.sh:286-327`, `fc36/tmp.Y80jiBv5DF/probe2.log`

---

## Claim 11: "no line starting with `[` (even indented, or behind `>` or list markers) that holds `]:` or leaves its `[` open, counting an escaped `\]` as no close (a link reference definition, or text that starts like one)"

**Location:** `skills/dev-cycle/SKILL.md:337-340` (d39c8f2)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers the clause as a writing rule: every line it bans that `refdef()` also refuses does refuse. It does not establish the converse; see Claim 12.

`refdef()` strips blanks, `>` and markers (`scripts/dev-cycle.sh:296`). It drops escapes so that `\]` is no close (`:300`) and refuses on `]:` or no `]` (`:301`). In P3, `    [x]: y`, `> - [x]: y`, `1. > [x]: y`, `[a\]` and `  > >  2) [x` all refuse. In P4, `123456789. [x` refuses.

**Evidence:** `skills/dev-cycle/SKILL.md:337-340`, `scripts/dev-cycle.sh:293-302`, `fc36/tmp.Y80jiBv5DF/probe3.log`, `fc36/tmp.Y80jiBv5DF/probe4.log`

---

## Claim 12: "These rules are stricter than `--check-brief` needs"

**Location:** `skills/dev-cycle/SKILL.md:340-341` (d39c8f2)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers whether a brief obeying every rule in the clause is always read. It does not establish anything about d47dd8d's replacement text, which landed outside this pass's fixed HEAD.

For nearly every shape, the rules ban more than the check refuses. They ban every `<` line (the check exempts complete comments), `~~~` fences (the check accepts them), and any literal `]:` (the check reads `[a] \]: b`, P4 `esc` → `ok`). Two shapes the rules permit are still skipped (P4):
- `1234567890. [x`. Ten digits is not a list marker, so the rule does not reach this line, but `refdef()` strips any digit run (`[0123456789]+[.)][ \t]`, `scripts/dev-cycle.sh:296`). Result: `skip …-ten.md: line 3 starts like a link reference definition`.
- A ```` ``` ```` block whose content line is `- ````. The rule bans list-item *fences*, and a content line is not one, but `else if (fenceish(l) && substr(l, 1, 1) != "`" && …) refuse("fence")` (`:318`) refuses it. Result: `skip …-fenced-item.md: line 4 is a fence-like line that is not a plain column-0 fence`.

The precise version would say the rules make a skip unlikely, not impossible, or name these shapes. d47dd8d does this concurrently ("a few shapes these rules allow are also skipped, such as a fence-like line inside a fence's content or a `]:` made by an escape"). **Wording.** Both shapes are contrived, no real brief has one, and the result is a visible skip, not a wrong reading.

**Evidence:** `skills/dev-cycle/SKILL.md:335-342`, `scripts/dev-cycle.sh:296`, `scripts/dev-cycle.sh:314-327`, `fc36/probe4.sh`, `fc36/tmp.Y80jiBv5DF/probe4.log`

---

## Claim 13: "it prints a skip for a brief with any line it cannot trust, and a skipped brief keeps its slot until it is fixed."

**Location:** `skills/dev-cycle/SKILL.md:341-342` (d39c8f2)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers the skip output, with the line named, and the slot rule's statement in the skill's Rules. It does not establish that an agent applies the slot rule; that is behavior of the model, not code.

P4 prints `skip <path>: line N <reason>, so the brief is not read` for each refused brief, from `echo "skip $a: line $n $(oddwhy "$why"), so the brief is not read"` (`scripts/dev-cycle.sh:363`). The Rules say "a brief the check skips keeps its slot (recorded) until the cause is fixed" (`skills/dev-cycle/SKILL.md:86-87`), and log 69 says "a refused brief keeps its slot".

**Evidence:** `scripts/dev-cycle.sh:355-366`, `skills/dev-cycle/SKILL.md:84-87`, `docs/decisions/log.md:92`, `fc36/tmp.Y80jiBv5DF/probe4.log`

---

## Claim 14: e6c3fe9 — "a line starting with [ behind blanks, > or list markers, and an escaped ] counting as no close, as refdef() does."

**Location:** commit e6c3fe9 (`skills/dev-cycle/SKILL.md:338-339`)
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** user
**Scope:** Covers that the clause now names both properties and that `refdef()` has them. It does not establish the "stricter" sentence (Claim 12).

The clause reads "(even indented, or behind `>` or list markers)" and "counting an escaped `\]` as no close" (`SKILL.md:338-339`). `refdef()` does both: `:296` strips the prefix, and `gsub(/\\./, "", l)` (`:300`) drops escapes.

**Evidence:** `skills/dev-cycle/SKILL.md:338-339`, `scripts/dev-cycle.sh:296-301`

---

## Claim 15: d39c8f2 — "the clause is a writing rule stricter than --check-brief; the check skips a brief with any line it cannot trust (some listed shapes, such as a line holding \]:, are read)."

**Location:** commit d39c8f2 (`skills/dev-cycle/SKILL.md:340-342`)
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers the example (`[a] \]: b` is banned by the clause and read by the check) and that the clause now carries the writing-rule framing. Its "stricter" premise is the residue Claim 12 records; this commit message is not verdicted on it twice.

P4 `esc` (`[a] \]: b`) gives `ok … open`. The clause bans the line because it literally holds `]:`. The diff replaces "`--check-brief` prints a skip for a brief with any of these" with the writing-rule sentence.

**Evidence:** `skills/dev-cycle/SKILL.md:340-342`, `fc36/tmp.Y80jiBv5DF/probe4.log`

---

## Claims Requiring Attention

### Incorrect
None.

### Stale
None.

### Mostly Accurate
- **Claim 12** (`skills/dev-cycle/SKILL.md:340-341`): "stricter than `--check-brief` needs" has two contrived exceptions: a ten-digit "ordinal" before `[` and a `- ```` content line inside a fence. Both are skipped although the rules permit them. **Wording.** d47dd8d already replaces the sentence (concurrent, outside this pass's HEADs).

### Unverifiable
None.

## Goal-Alignment Note

Success criterion (verbatim): "a markdown report saved at the path your role instructions give, structured per your skill file."

This report is saved at `/workspace/.claude/wt-digest/docs/reviews/code-fact-check-report-digest-pass36.md`. Its first line is `Commit: dd1988d (A) / d39c8f2 (B)`, and its header carries `**Replication:** k=1 (loop pass, decision 031)`. It follows `skills/code-fact-check/SKILL.md`: header fields, the seven mandatory per-claim fields plus Legibility-target, quote-or-paraphrase evidence, and provenance for executed verdicts.

For the user goal (no known issue in this delta pass, then the k=1 full review): the dd1988d fix is behaviorally exact and linear. It changes no verdict on any real file and refuses no real ID. Its comments, help text and commit messages are accurate. The only imprecision is Claim 12's wording in the skill, and d47dd8d already rewords it. Nothing here is behavioral, Medium or above, or inside log 69's accepted class. Two concurrent commits (3d580cd, d47dd8d) landed outside this pass's fixed HEADs. They are unreviewed here, so the next pass should cover them.
