Commit: 9e7c61c5

# API Consistency Review: feat/build-loop-u2c1 (U2c1, final confirming pass, full branch)

**Scope:** `git diff main...HEAD` in the U2c1 worktree (eddfd5f9..9e7c61c5). The consumer surface is --check's verdict, path and deny lines and their deny texts, --help (the --check S-rules paragraph and Exit:), the `Paths:` and `Self-merge never:` grammars (list_entries), and the lib's caller contract.
**Date:** 2026-10-10
**Based on:** the final-pass fact-check summary (scratchpad u2c1-final-fc-summary.md) and replicates code-fact-check-report-build-loop-u2c1-final-r1/-r2/-r3.md. The summary's items are being fixed and are not repeated here: ownfile's case, override rows 610/612/613, lib contract item 8, --help :155/:179 omitting the re-read refusal, srules' "$5" wording, the re-read deny text, nrules' "anything under" wording, and the :1967 test title. Prior reports from this branch: api-consistency-review-2026-10-10-u2c1.md and -i2.md.

## Baseline Conventions

- **List lines.** A list line is "KEY: E ..." with single spaces. `KEY: none` is the empty list and bare `KEY:` is malformed. The reasons are "is not exactly \"KEY: WORD ...\" with single spaces", "lists entry $i, which is not an allowed WORD form" and "lists entry $i twice". This holds for build-loop.sh list_entries (:364-379) and for the lib's reader_settings (:625-632). Each --help placeholder is the word the reason prints: `Self-merge never: GLOB ...` (:25), `Reader roots: PATH ...` (:43), `Branch: NAME`.
- **Result globals.** A helper empties its result globals on entry and puts the reason in `X_WHY`, as FILE_OUT/FILE_WHY, FLOOR_WHY, TRUTH_WHY, PATHS/PATHS_WHY and LIST/LIST_WHY do. When a caller needs a failure class, the helper gives it a token, not prose: BRIEF_ODD's `odd`/`unbalanced`/`error`, and now LIST_BAD.
- **Brief machine lines.** The first line at column 0 counts, case-sensitive, after one CR is dropped (brief_fields, lib :372-409). --help says "the brief's first X: line" for Branch:, Policy: and now Paths:.
- **Output lines.** `deny BRIEF S PATH: WHY`, where WHY is a phrase about the path. The N and S rules word a shared category the same way, for example "the user's constraints doc, which every loop prompt carries" (nrules) and floor's `user` word.

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `list_entries LINE KEY WORD FORM` | function | `read_settings`, `reader_settings`, `brief_fields` | `scripts/build-loop.sh:395`; `scripts/lib/dev-cycle-read.sh:386, 600-640` | Consistent (as in i2) |
| `LIST`, `LIST_WHY`, `LIST_BAD` | globals | `FILE_OUT`/`FILE_WHY`, `BRIEF_ODD` | `scripts/lib/dev-cycle-read.sh:385, 545` | Consistent in shape. `LIST_BAD=entry` has no reader (Finding 3) |
| `read_paths`, `PATHS`, `PATHS_WHY` | function, globals | `read_settings`, `NEVER`, `NEVER_LINE` | `scripts/build-loop.sh:395, 393` | Consistent |
| `never_res`, `NEVER_RES` | function, global | `NEVER`, `GATE_CODE` (regex global) | `scripts/build-loop.sh:393`; lib `:1813` | Consistent: lower-case function, upper-case global, set once |
| `srules STEM PATH LP S CO` | function | `nrules BRIEF OM NM NO S PATH LP`; `floor PATH STEM S` | `scripts/build-loop.sh:597`; lib `:1826` | Consistent with its sibling nrules (brief first, then path). floor/ownfile put the path first, but srules adapts that at its one call |
| deny "matched by GLOB in the Self-merge never: line of docs/dev-cycle.md" | output text | "neither listed in the brief's Paths: line nor one of its own files", FLOOR_WHY phrases | `scripts/build-loop.sh:662, 670` | Consistent |
| deny "a path below the name of one of the dev cycle's own files or the constraints doc" | output text | "one of the dev cycle's own files" | `scripts/build-loop.sh:607` | Consistent: it extends the N-rule wording |
| --help placeholder `"Paths: P ..."` | doc grammar | `Self-merge never: GLOB ...`, `Reader roots: PATH ...`; the reason's `"Paths: PATH ..."` | `scripts/build-loop.sh:25, 43, 369, 623` | Inconsistent (Finding 2) |

## Findings

#### 1. Path lines under a checkout refusal omit the floor without saying so, and a loop's advisory run always gets that kind

**Severity:** Minor
**Location:** `scripts/build-loop.sh:661` (srules, :658-671), `:811` and `:833` (check_line, :769-837), --help `:150-151` and `:179`
**Move:** 3 (consumer contract), 7 (asymmetry: one line shape, two meanings)
**Confidence:** High on the mechanism (code read in full; fact-check r2's re-read probe shows no floor reason under a `co` refusal). Medium on impact (the loop prompt is U3's).
**Legibility-target:** for-orchestrator-synthesis

Evidence:
```bash
# scripts/build-loop.sh:811
  co=""; if [[ "$pol" == self-merge ]] && ! checkout_gate; then co="refuse $a: a self-merge brief needs --check run from a clean checkout of the default branch's commit; $CHECKOUT_WHY"; fi
# scripts/build-loop.sh:661
  if [[ -z "$5" ]] && floor "$2" "$1" "$4"; then DENY="$FLOOR_WHY"; return 0; fi
```
```
# --help :150-151
#                 only the verdict line, so a loop running --check from its
#                 own branch still gets the path lines. A review brief does
```

The plan makes a loop's own --check an advisory dry run (plan:28, :83, :234). A loop runs from its own worktree, whose HEAD is its branch tip, not MAIN_SHA. So checkout_gate always refuses there, `co` is set, and srules skips the floor. That loop then sees `path BRIEF A CLAUDE.md` or `path BRIEF A scripts/build-loop.sh` whenever its Paths: lists them. The orchestrator's run from a clean main checkout denies the same paths. The help states the skip (":179 not run over a checkout refused above"). Still, the line a loop reads is the same `path` line that follows an `ok`, and nothing on the path lines or in the refusal says they skipped the floor. The help line at :150-151 presents those lines as useful to that loop. Before U2c1 this was latent, because no floor was wired. Now it is the S rules' main consumer-visible gap for the advisory caller. It is not a safety issue: the verdict line is a refusal, and the deciding run executes the floor.

**Recommendation:** Say so on the output. For example, append "(the floor was not run)" to the `co` refusal text when `pol` is self-merge, or have the help's :150-151 sentence add that those path lines omit the floor. Otherwise record it for U3's loop prompt, whose "`--check` is advisory" line (T19) could say what a loop's run cannot see.

#### 2. --help writes the Paths: placeholder as `P`; the reason it prints, the read_paths comment and the sibling lists use the word

**Severity:** Minor
**Location:** `scripts/build-loop.sh:186` (also plan:238 and :311 `Paths: P…`)
**Move:** 2 (naming against the grain)
**Confidence:** High
**Legibility-target:** for-author

Precedent: the help placeholder equals the reason's word, as `Self-merge never: GLOB ...` in scripts/build-loop.sh:25 and :369 (`${3^^}`), and `Reader roots: PATH ...` in scripts/build-loop.sh:43 and scripts/lib/dev-cycle-read.sh:625

Evidence:
```
# scripts/build-loop.sh:186
#                 case, though the floor passes any case). "Paths: P ..." lists paths
# scripts/build-loop.sh:623
# list_entries reads "Paths: PATH ...", each entry pathform's, a trailing /
```
The deny a reader sees for a bad line is `the brief's Paths: line is not exactly "Paths: PATH ..." with single spaces, so only its own files land` (test build-loop-check.bats, the malformed-Paths case). Someone matching that text against --help finds a different placeholder. The fix costs one character class.

**Recommendation:** Write `"Paths: PATH ..."` at :186. The plan's `P…` can stay, since it is the plan's shorthand, or change alongside.

#### 3. `LIST_BAD=entry` is set but no caller reads it

**Severity:** Informational
**Location:** `scripts/build-loop.sh:362, 378` (list_entries, :364-379), against its callers `:420` (read_settings) and `:630-631` (read_paths)
**Move:** 3 (contract surface)
**Confidence:** High (grep: LIST_BAD appears only at :362, 363, 367, 369, 378 and 420)
**Legibility-target:** for-author

Evidence:
```bash
# scripts/build-loop.sh:378
  [[ -z "$LIST_WHY" ]] || { LIST=(); LIST_BAD=entry; }
# scripts/build-loop.sh:420
      if [[ "$LIST_BAD" != form && "${next[never]}" != 1 ]]; then why="is followed by a non-blank line outside a fence (it may continue the list)"; fi
```
C2's token fixed i2 Finding 1's prose sniffing, which was the real problem. Only `form` is consumed, though. `entry` repeats what a non-empty LIST_WHY already says. Its harm is small: a future caller could branch on `entry` versus empty, which is the same as testing LIST_WHY. The i2 suggestion of a read-suite case for "bad entry + non-blank next line" (which reason wins) is still not in build-loop-read.bats (only :145 and :520 test the next-line reason, both with good entries). The order now rests on the token, not on wording, so that matters less.

**Recommendation:** Optional. Keep `entry` as documented symmetry, or drop it and document LIST_BAD as `form` or empty. A one-line read test for the entry-plus-next-line order would pin the precedence read_settings' comment at :419 states.

## What Looks Good

- **One parser, one empty spelling, one set of words** for `Self-merge never:` and `Paths:`. read_settings' precedence (form, then next line, then entries) and its `none` handling are unchanged in output: `none` is now read from the empty LIST (:421), as i2 Finding 2 asked.
- **Brief-line conventions hold.** Paths: is read by brief_fields like Branch: and Policy: (first unfenced line at column 0, CR dropped), and the help says "first "Paths:" line" as it does for the others. Not applying the never line's next-line rule to Paths: is the right asymmetry: a missed continuation of Paths: only narrows what lands.
- **Deny texts stay in house style.** The new never deny names its glob as written. The row-523 deny extends the N rules' "one of the dev cycle's own files" wording. A category shared by the N rules and floor (`user`, the cycle's files) prints identical text from either rule.
- **The order is stated and kept.** floor, then never, then the allowlist, so a never glob also refuses an own file. --help (:174-191) and srules' comment both give that order, and T45 shows a never glob beating a Paths: listing.
- **The Exit: text** now tells a caller that a mid-run stop exits 1 or a command's own status after earlier briefs' lines, and that any exit but 0 means nothing was decided. That matches the parent-shell loop (`check_line > $GATE_TMP/line; cat`), where the stopped brief prints nothing.
- **Lib contract items 3 and 5** now name what build-loop.sh discharges and how (diff-tree -r, with a symlink or gitlink above a path as its own entry; the fact-check executed this). FLOOR_WHY's comment names its real reader.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Path lines under a checkout refusal omit the floor unmarked; a loop's advisory run always gets these | Minor | `scripts/build-loop.sh:661, 811, 150-151` | High (mechanism) / Medium (impact) |
| 2 | --help `"Paths: P ..."` vs the reason's and comment's `"Paths: PATH ..."` | Minor | `scripts/build-loop.sh:186` | High |
| 3 | `LIST_BAD=entry` has no reader; the entry-plus-next-line order is still untested | Informational | `scripts/build-loop.sh:378, 420` | High |

## Overall Assessment

The branch's consumer surface is consistent with the codebase's conventions. Both list lines share one grammar and one set of reason texts. Paths: follows the brief-line rules. The new deny texts read in the existing voice. --help and the lib contract match the code, apart from the text items the fact-check is already fixing. No change breaks a consumer: --check's line shapes are unchanged, the S rules only add denies under a self-merge brief, and nothing outside the gate writes Paths: yet (U4). The one point of substance is Finding 1. The advisory dry-run the plan gives loops always runs without the floor, and its output does not say so. It is fixable in text (the refusal or the help) or by routing it to U3's loop prompt. Findings 2 and 3 are one-line cleanups.

## Goal-Alignment Note

- Success criterion (from the i1 brief): a markdown report saved at the output path the dispatch names, structured per the skill, every finding with verbatim Evidence and a path:line.
- Answered: yes. Saved at docs/reviews/api-consistency-review-2026-10-10-u2c1-final.md with `Commit: 9e7c61c5` at the top. 3 findings (2 Minor, 1 Informational), each with Severity, path:line, verbatim Evidence, Confidence and Legibility-target. The naming finding carries a Precedent line.
- Not duplicated: every item in the final fact-check summary. Settled rows not re-raised: B3, B4, B9 (malformed Paths: only per path), B10, A1's lib copy, and floor-only-when-co-empty (plan:309) itself. Finding 1 is about the output not marking that rule, not the rule.
- No probes or suites run. The mechanism in Finding 1 comes from reading check_line and srules in full, and fact-check r2 executed it for the re-read case.
- Escalate: none. Finding 1's fix could go in this unit (text) or U3 (loop prompt); that is the orchestrator's call.
