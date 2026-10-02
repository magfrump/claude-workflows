Commit: dd1988d (A) / d39c8f2 (B)

# API Consistency Review — dev-cycle pass 36 (the pass-35 fix round)

**Scope:** A: `git diff f3c9ebb..dd1988d -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` (worktree `wt-digest`; HEAD 20d35e2 adds only review docs, and `scripts/dev-cycle.sh` is identical at dd1988d, 20d35e2 and dbfe402). B: `git diff 2bf03da..d39c8f2 -- skills/dev-cycle/SKILL.md` (worktree `wt-devcycle`, merge dbfe402). This is a partial scope: everything else is context only.
**Date:** 2026-10-02
**Based on:** Stage-1 context `docs/reviews/code-fact-check-report-digest-pass35.md` (loop pass 35's k=1 fact-check, Claims 1, 17 and 18) and this round's commits adb5260, dd1988d, e6c3fe9 and d39c8f2.
**Acceptance bar applied:** for every input, the fence reader gives the CommonMark reading or refuses, except decision log 69's accepted inline class. Refusing a file CommonMark would read is the design's cost unless a real file is hit.

Surfaces checked: `--help` (both refusal lists and the `sed -n '2,75p'` range), the `oddwhy` reason texts, the FENCE_AWK and `refdef()` comments, the skill's brief clause and the skip wording elsewhere in the skill, decision log row 69 (`wt-devcycle/docs/decisions/log.md:92`), and `--check-answer` against the real answer lines.

Probes (all under `scratchpad/api36/`): each was one `set -eu` script that made its own `mktemp -d` dir, checked `$PWD` before any write, `git init` or commit, and ran every process under `timeout`. The script under test was `wt-digest/scripts/dev-cycle.sh` (identical to dd1988d), and the old one came from `git show f3c9ebb:scripts/dev-cycle.sh`. Neither worktree was written except for this report. Bats and the hermeticity lint were not run here, because they run inside the worktree and the other critics cover them.

- P1: the old `sub()` loop against the new `match()`, on 200,000 random lines built from blanks, tabs, `>`, `-*+`, digits, `.`, `)`, `--`, `**`, `[`, `]`, `:` and `\`, under mawk (the system `awk`) with `LC_ALL=C`. Result: **0 differences**.
- P2: the new `match()` on a line of `- ` markers. 100,000 markers took 0.01 s and 400,000 took 0.035 s, so the cost is linear.
- P3 and P6: `--check-brief` on briefs that follow the skill's clause, plus edge shapes (results under F1).
- P4 and P5: `--check-answer` for every `### Q-NNN` heading in copies of `/workspace/docs/working/questions.md` and `questions-archive.md`. Result: 23 keep, 19 drop, 3 done, 12 open, 42 unrecognized, **0 skips**. The output is **byte-identical** between f3c9ebb and dd1988d. Spot check: Q-081 reads `drop`, and its answer line is `**Answered 2026-09-28: [2] spike ...`.

## Baseline Conventions

- **Check-mode output vocabulary.** The modes print `ok …`, `skip <arg>: <reason>` or a mode-specific verdict. The skill uses the same words ("prints a skip", "a skipped brief keeps its slot": `SKILL.md:341-342`, `:85-87`).
- **Reason grammar.** A refusal prints as `line N [of F] <verb phrase>, so … is not read`. The `oddwhy` texts are verb phrases (`scripts/dev-cycle.sh:329-338`).
- **Help style.** Each check mode lists its skip causes in plain words, with no internal identifiers, and the two lists (`--check-brief` `:36-42`, `--check-answer` `:58-65`) share their items, in the same order.
- **One rule, four surfaces.** Each surface states the refusal rule at its own level of detail: the code comment (`:263-283`), help, decision log 69 and the skill's brief clause. Pass 35's F1 and F2 brought help and the skill into line with the code on the comment exception and on `[` behind containers.

## Name-Pattern Audit

This round adds no flag, mode, output keyword, reason text or exported name. `refdef()` stays private to FENCE_AWK, and its signature and return contract are unchanged. The only consumer-visible strings that changed are the two help lists (A) and the skill's brief clause (B). The table audits them as output strings.

| New text | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| help: `a line starting (after blanks) with < other than a complete one-line <!-- comment -->, a line leaving a <!-- open` (in both lists) | help list | `oddwhy html`: `only a complete one-line <!-- comment --> is read`; log 69: `(except a complete one-line comment)`; FENCE_AWK comment `:271` | `scripts/dev-cycle.sh:39-40`, `:61-62`, `:331`; `docs/decisions/log.md:92` | Consistent. The same exception appears in the same words on all four surfaces, and the code matches it (`rawhtml()` `:288`; P3: `<!-- note -->` and `<!-- a --> <div>` read, an open `<!--` refused). Pass-35 F1 is fixed |
| help reflow: `inside a fence, a questions file that is not plain).` | help list | the previous two-line wrap | `scripts/dev-cycle.sh:65` | Consistent. Only the wrapping changed |
| help range `sed -n '2,75p'` | help extraction | the previous `2,74p` | `scripts/dev-cycle.sh:139` | Correct. Line 75 is the last header comment line and line 76 is blank |
| skill: `no line starting with [ (even indented, or behind > or list markers) that holds ]: or leaves its [ open, counting an escaped \] as no close` | skill brief clause | `refdef()` `:293-302`; log 69 `(behind any > and list markers)` | `scripts/dev-cycle.sh:293-302` | Consistent on containers and on `\]` (pass-35 F2 fixed; P3: `> - [a\] b`, `\t1)\t[x]: y` and `1234567890. [x]: y` are all refused). See F1 for escapes other than `\]` |
| skill: `These rules are stricter than --check-brief needs; it prints a skip for a brief with any line it cannot trust` | skill brief clause | the earlier `--check-brief prints a skip for a brief with any of these` | `skills/dev-cycle/SKILL.md:340-342` | Mostly true, with two exceptions; see F1 |

## Findings

#### F1. The skill now says its brief rules are "stricter than `--check-brief` needs", but two shapes that follow those rules are still skipped

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:335-342` (B, d39c8f2), against `scripts/dev-cycle.sh:293-302` (`refdef`) and `:316-318` (`fence`, in-fence branch) (A, dd1988d)
**Move:** 3 (consumer contract: documentation drift between a writer's rule and the checker)
**Confidence:** High (both shapes were reproduced with the real script in P3 and P6)
**Legibility-target:** the cycle agent that writes a brief by following the skill's clause, and then has to explain a skip it was told to expect would not happen.

**Evidence** (verbatim; the clause is quoted in full):
> Any code in a brief sits in plain column-0 ``` fences (no indented or list-item fences), and outside fences a brief has no line starting with `<` (write placeholders as `NAME`, not `<name>`, even indented), no `<!--` left open on its line, no line starting with `[` (even indented, or behind `>` or list markers) that holds `]:` or leaves its `[` open, counting an escaped `\]` as no close (a link reference definition, or text that starts like one), no stray carriage return and no byte-order mark. These rules are stricter than `--check-brief` needs; it prints a skip for a brief with any line it cannot trust, and a skipped brief keeps its slot until it is fixed.

```
  gsub(/\\./, "", l)
  return index(l, "]:") || !index(l, "]")
```
(`refdef`, `:300-301`; the function ends at `:302`.)
```
  if (infence) {
    if (closes(l)) infence = 0
    else if (fenceish(l) && substr(l, 1, 1) != "`" && substr(l, 1, 1) != "~") refuse("fence")
    return 1
  }
```
(`fence`, `:316-320`; the rest of `fence()` handles lines outside a fence.)

The d39c8f2 sentence promises that a brief following the clause is never skipped, so the writing rule covers the checker. That holds for `<`, `<!--`, CR, BOM and the `\]` case. It fails in two places:

1. **An escape other than `\]` creates a `]:`.** `refdef()` removes every backslash escape (`\\.`) before it looks for `]:`. The line `[a]\\: b` holds no `]:` and closes its `[`, and so does `[note]\*: see below`, so the clause allows both. P6 shows both are refused: `skip …esc-colon.md: line 3 starts like a link reference definition (its label or title can span lines), so the brief is not read`. CommonMark reads neither line as a definition (the `]` is not followed directly by `:`). That makes the refusal itself the design's cost, not a finding, but the skill's claim does not hold for these lines.
2. **A fence-like line inside a plain fence's content.** The clause governs the fences ("no indented or list-item fences") and puts no limit on what code sits inside them. A brief showing a Markdown snippet can follow it:
   ````
   ```
   - ```bash
     x
   ```
   ````
   P3 shows that this (and a plain `   ~~~` content line) is refused: `skip …inner-list.md: line 4 is a fence-like line that is not a plain column-0 fence, so the brief is not read`. Log 69's "any fence-like line that is not a plain column-0 fence" covers this case, so the code and log 69 agree. Only the skill's "stricter" claim misses it.

Preconditions: a brief author writes one of these shapes. No real brief exists on either branch (`docs/working/briefs` is absent in `/workspace`), and the skip message names the line, so the cost is one extra fix cycle while the brief keeps its slot. Nothing is read wrongly. This is a documentation contract that is off by two shapes, not a reader bug.

**Recommendation:** Either drop the escapes from the clause's `[` rule ("…holds `]:` once backslash escapes are removed, or leaves its `[` open…") and add "nor any fence-like line inside a fence", or soften the d39c8f2 sentence to "These rules cover nearly everything `--check-brief` skips; it prints a skip for any line it cannot trust…". The second change is one phrase and keeps the clause short.

#### F2. Help is now the only surface that does not say a reference-definition line can sit behind `>` or list markers

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:41` and `:63` (A)
**Move:** 3 (documentation drift across surfaces)
**Confidence:** High
**Legibility-target:** a `--help` reader who sees `> [x]: y` refused.

**Evidence** (verbatim):
- help (both lists): `a line starting like a link reference definition, a stray`
- FENCE_AWK comment `:272-273`: `a line starting like a link reference definition (after any > and list markers)`
- log 69: `a line that starts like a link reference definition (behind any > and list markers)`
- skill `:338`: `no line starting with [ (even indented, or behind > or list markers)`

After e6c3fe9, three of the four surfaces name the container case and help does not. "Starting like" is not wrong, and the skip line names the offending line, so the impact is minimal. This is pre-existing wording that became the outlier this round, and I am not asking for a change unless a help edit happens anyway.

**Recommendation:** Optional. Add "(behind any > and list markers)" to both help lists, using log 69's words. The help range would then need to move again.

## What Looks Good

- **dd1988d preserves behaviour.** The single anchored `match()` gives the same stripped remainder as the old loop on 200,000 adversarial lines (P1: 0 differences), including blanks and tabs between markers, `>` between markers, digits without `.`/`)`, a marker with no following blank, `--`, `**` and lines made only of markers. Its cost is linear (P2). The new comment states why it uses one match. The `refdef()` contract (return 1 to refuse) is unchanged. `--check-answer` output on the real questions files is byte-identical to f3c9ebb, with no ID skipped (P5). The commit message's claims ("same result", "no real ID refused") hold.
- **adb5260: one exception, four surfaces.** Help, `oddwhy`, the FENCE_AWK comment and log 69 now state the one-line-comment exception in the same words, and the code matches it. The help range was moved with the extra line and is exact.
- **e6c3fe9: the skill's `[` rule now matches `refdef()`** on indentation, `>` and list markers (including `1)` and long digit runs) and on `\]`.
- **d39c8f2 fixed what pass 35 found.** The clause no longer claims that every listed shape is skipped (pass-35 fact-check Claim 17): `[a] x \]: y` and a one-line comment are read, and the clause now calls itself a writing rule. F1 only narrows the reverse claim.
- **Decision log row 69 checked against the code: correct and complete.** It covers the refusal list (fence-like lines, `<` with the comment exception, an open `<!--`, refdef behind containers, CR, BOM, an open fence at the end, and a heading in a fence for questions files) and the accepted inline class. This round changed none of these behaviours.
- **The reason texts are unchanged and still accurate** for every refusal P3 and P6 triggered.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | The skill's "stricter than `--check-brief` needs" misses escape-created `]:` lines (`[a]\\: b`) and fence-like lines inside a fence | Minor | `skills/dev-cycle/SKILL.md:335-342` | High |
| 2 | Help is the one surface that does not name a reference definition behind `>` or list markers | Informational | `scripts/dev-cycle.sh:41`, `:63` | High |

## Overall Assessment

The round is consistent with the codebase's conventions. A's help change brings the comment exception into line on every surface. Its `match()` rewrite is behaviour-preserving and linear, and it changes no output for any real questions entry. B's clause now matches `refdef()` on containers and `\]`. One wording gap is left (F1, Minor): the new claim that the skill's rules are stricter than the checker misses two shapes the checker refuses. Neither shape is in a real file, and either fix is a phrase in the clause. F2 is optional. Nothing is Breaking or Inconsistent, and no finding falls inside log 69's accepted class or touches the reader's behaviour.

## Goal-Alignment Note

Success criterion (verbatim): "a markdown report saved at the path your role instructions give, structured per your skill file."

This report is saved at `/workspace/.claude/wt-digest/docs/reviews/api-consistency-review-2026-10-02-digest-pass36.md` and starts with `Commit: dd1988d (A) / d39c8f2 (B)`. It follows the skill's structure: title and header, Baseline Conventions, Name-Pattern Audit, Findings, What Looks Good, Summary Table and Overall Assessment. Each finding carries Severity, Location, Evidence (verbatim), Confidence and Legibility-target. For the user goal (merge once a pass finds no known issue), this delta pass leaves one Minor wording issue (F1) open in the skill. It is a known issue, so by the loop's rule it needs a fix (one phrase) before the k=1 full review.
