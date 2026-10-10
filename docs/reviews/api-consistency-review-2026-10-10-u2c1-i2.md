Commit: cf7dd447

# API Consistency Review: feat/build-loop-u2c1 (U2c1, iteration 2, fix range)

**Scope:** `git diff eddfd5f9..HEAD -- scripts test` (d435100e, cf7dd447) plus the plan text changed in that range (plan:238, :311, :312). Surface: the `Paths:` grammar (`Paths: none`, bare `Paths:`), `list_entries`' interface, the new never deny wording, --help and the Exit: line.
**Date:** 2026-10-10
**Based on:** docs/reviews/code-fact-check-report-build-loop-u2c1-i2.md (20 claims; its three Mostly-accurate claims, 5, 7 and 14a, are being fixed and are not repeated here). Iteration-1 report: docs/reviews/api-consistency-review-2026-10-10-u2c1.md.
**Runs:** `bats -f 'U2c1' test/scripts/build-loop-check.bats` (6/6 ok) and `bats test/scripts/build-loop-read.bats` (20/20 ok), serially, `LC_ALL=C TMPDIR=<own mktemp dir>`. Logs: scratchpad/u2c1-i2-api/run-u2c1.txt, run-read.txt.

## Baseline Conventions

Unchanged from iteration 1. The parts this range touches:
- **List lines.** "KEY: E ..." with single spaces; `KEY: none` is the empty list; bare `KEY:` is malformed. Sub-reasons are "is not exactly \"KEY: WORD ...\" with single spaces", "lists entry $i, which is not an allowed WORD form" and "lists entry $i twice" (build-loop.sh:367-373; lib reader_settings has the same words for `Reader roots:`).
- **Result globals.** A helper returns through globals it empties first, with the reason in `X_WHY`. For example, main_file sets FILE_OUT/FILE_WHY (lib :545-548), floor sets FLOOR_WHY (lib :1824-1829) and truthrule sets TRUTH_WHY (lib :1776-1778).
- **Reason classes.** When a caller has to tell failure kinds apart, the callee gives it a token, not prose. brief_fields' BRIEF_ODD is `odd N WHY`, `unbalanced N` or `error` (lib :376-389), and callers match on the first word.
- **Deny WHYs** describe the path. The S-rule allowlist WHY is participial ("neither listed in the brief's Paths: line nor one of its own files", :667).

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `list_entries` | function | `read_settings`, `read_paths`, `brief_fields`, `reader_settings` | `scripts/build-loop.sh:362, 395, 625`; `scripts/lib/dev-cycle-read.sh:390` | Consistent: verb-first or noun-noun readers; "entries" is the word the sub-reasons already use ("lists entry $i") |
| `LIST`, `LIST_WHY` | global | `FILE_OUT`/`FILE_WHY`, `PATHS`/`PATHS_WHY`, `FLOOR_WHY` | `scripts/lib/dev-cycle-read.sh:545`, `scripts/build-loop.sh:624` | Consistent: the scratch-result plus X_WHY pair, emptied on entry (:365) |
| `list_entries LINE KEY WORD FORM` | signature | `ownfile PATH STEM S`, `floor PATH STEM S`, `srules STEM PATH LP S CO` | `scripts/lib/dev-cycle-read.sh:1805, 1826`; `scripts/build-loop.sh:656` | Consistent: subject first, then qualifiers. Calling FORM by name has no direct precedent but is local and documented (:358-359) |
| `read_paths` | function | `read_settings` | `scripts/build-loop.sh:395` | Consistent (iteration-1 Finding 8 fixed) |
| deny WHY "matched by GLOB in the Self-merge never: line of docs/dev-cycle.md" | output text | "neither listed in the brief's Paths: line nor one of its own files"; FLOOR_WHY noun phrases | `scripts/build-loop.sh:667`; `scripts/lib/dev-cycle-read.sh:1833-1847` | Consistent: participial, like the other S-rule WHY. Names the glob as written, as the settings reader names entries |
| `Paths: none` / bare `Paths:` | brief line | `Self-merge never: none`, `Reader roots: none`; bare `KEY:` malformed | `scripts/build-loop.sh:25-27, 46, 367` | Consistent (iteration-1 Finding 1 fixed): one parser, one empty spelling |

## Findings

#### 1. read_settings' reason order depends on list_entries' message text, and no test pins the order

**Severity:** Minor
**Location:** `scripts/build-loop.sh:416-418` (read_settings, :393-452), against `scripts/build-loop.sh:367` (list_entries, :362-377)
**Move:** 3 (consumer contract between the shared parser and its caller), 4 (error consistency)
**Confidence:** High on the mechanism; Medium on test coverage (grep of build-loop-read.bats)
**Legibility-target:** for-author

Evidence:
```bash
# scripts/build-loop.sh:416-418
      list_entries "$t" "Self-merge never" glob globform; why="$LIST_WHY"
      # The form reason comes first, then the next line, then the entries.
      if [[ "$why" != "is not exactly"* && "${next[never]}" != 1 ]]; then why="is followed by a non-blank line outside a fence (it may continue the list)"; fi
```
```bash
# scripts/build-loop.sh:367
  if [[ "$1" != "$2: "* || ! "$v" =~ ^[^\ ]+(\ [^\ ]+)*$ ]]; then LIST_WHY="is not exactly \"$2: ${3^^} ...\" with single spaces"; return 0; fi
```

The precedence that read_settings promises (form first, then the next line, then entries) is recovered by matching the first words of a reason string. That string now belongs to a parser two callers share. Rewording the form reason for the `Paths:` side would quietly change which reason the never line reports, and nothing would fail. The read suite never combines a form-malformed line, or a bad entry, with a non-blank next line. Its next-line cases (build-loop-read.bats:144-145, :428-429) all use a well-formed `Self-merge never: a/`. So the order rests on the fact-check's differential probe (44 cases equal, fact-check Claim 10), not on a test. The house pattern for telling failure kinds apart is a token the callee sets, like BRIEF_ODD's `odd`/`unbalanced`/`error`. Behaviour today is identical to eddfd5f9's, so this is a fragility note, not a regression.

**Recommendation:** Have list_entries signal the form failure separately (for example a distinct return status, or a `LIST_FORM=1` flag set before the reason), and test that in read_settings. At minimum, add one read-suite case with a malformed entry followed by a non-blank line, which pins the entries-after-next-line order.

#### 2. The `none` spelling is decided in two places

**Severity:** Informational
**Location:** `scripts/build-loop.sh:368` (list_entries), `scripts/build-loop.sh:420` (read_settings)
**Move:** 7 (asymmetry)
**Confidence:** High
**Legibility-target:** for-author

Evidence:
```bash
# scripts/build-loop.sh:368
  [[ "$v" != none ]] || return 0
# scripts/build-loop.sh:420
      elif [[ "$v" == none ]]; then never_ok=1; NEVER_LINE="never none: line ${first[never]} $where lists none"
```

list_entries already reports none as an empty LIST with no LIST_WHY. read_settings still keeps its own `v` and compares it with `none` again to pick the `never none` line. read_paths relies on the parser alone. The two copies agree today. The point of A1 was a single grammar, though, and this is the one keyword read_settings still parses for itself.

**Recommendation:** Optional. Branch on `${#LIST[@]} -eq 0` in place of `$v == none` (with `v` kept only for the `never $v set` text). Not worth a fix pass on its own.

## Iteration-1 dispositions confirmed

| i1 # | Finding | Rubric | Confirmed |
|---|---|---|---|
| 1 | `Paths:` empty spelling vs `none` | A1 Fixed | Yes. `Paths: none` is empty and bare `Paths:` is malformed with the settings' wording (:367, :628; test build-loop-check.bats:1969-1970 passes). |
| 2 | --help "other briefs' working docs and reviews" | B7 Fixed | Yes (:178-179). The fact-check's Claim 5 note on "in lower case" is being fixed separately. |
| 3 | Own files compare lower-cased | B1 Fixed | Yes. `ownfile "$2"` (:663). The srules comment (:652-655), help (:185) and plan:311 agree. Test :1972-1975 denies `Docs/Working/Plan-…`. |
| 4 | Never deny names no glob; clause | B8 Fixed | Yes. `NEVER_RES` is built one regex per `NEVER` entry in order (:637-645), so `${!NEVER_RES[@]}` indexes `NEVER` correctly. The text names the glob as written (:661). Test :1985-1986 asserts both globs. |
| 5 | Malformed Paths: only per path; plan:238 | B2 Fixed (plan); B9 Defer | Yes. plan:238 now matches plan:311. Override row (override-log, B9 row) has a revisit trigger. |
| 6 | Trailing `/` opposite in the two lists | B7 Fixed | Yes. "unlike a never glob, an entry without one matches that file alone" (:188-189). |
| 7 | Exit 1 mid-run unlisted | B6 Fixed | Listed (:201-203). The fact-check's Claim 7 refinement (a failed command exits with its own status) is being fixed separately. |
| 8 | `paths_read` name | B12 Fixed | Yes. `read_paths` (:625). `grep paths_read scripts test` finds nothing (fact-check Claim 3). |

## What Looks Good

- **One grammar, one set of words.** Both lists now produce the same three sub-reasons from one function. `${3^^}` keeps the old `GLOB`/`PATH` placeholders byte for byte (the read suite's never tests and the U2c1 Paths: tests pass).
- **Making bare `Paths:` malformed changes no outcome** (both cases land only own files). Only the deny text differs, and that text is now the settings lists' text. The branch is unmerged, so no consumer depended on the old reading.
- **The new never deny** names the offending glob as written, the way read_settings names an offending entry. It reads in the same participial voice as the other S-rule WHY, and it keeps the `deny BRIEF S PATH: WHY` shape.
- **read_paths' unset test** (`${BRIEF[paths]+set}`) distinguishes "no line" from a line, matching brief_fields' contract ("a key with no such line stays unset", lib :380).
- **The help's Paths: sentence** now states the one asymmetry with never globs that iteration 1 flagged, and the Exit: line covers the parent-shell stop.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Never-line reason order sniffs list_entries' "is not exactly" prefix; no test pins it | Minor | `scripts/build-loop.sh:416-418` | High |
| 2 | `none` checked in list_entries and again in read_settings | Informational | `scripts/build-loop.sh:368, 420` | High |

## Overall Assessment

The fix range resolves every iteration-1 finding of mine marked Fixed (1, 2, 3, 4, 6, 7 and 8; 5's plan half is fixed and its output half deferred with a row). It adds no inconsistency to the consumer surface. The `Paths:` and `Self-merge never:` lines now share one parser, one empty spelling and one set of reason texts. The never deny names its glob, and the help states the trailing-`/` difference and the mid-run exit. The two remaining notes are internal. read_settings recovers a reason class from message text (Minor; untested ordering). It also keeps a second `none` check (Informational). Neither changes any output today.

## Goal-Alignment Note

- Success criterion (restated verbatim from the i1 brief): a markdown report saved at the output path your dispatch names, structured per your skill, every finding with verbatim Evidence and a path:line.
- Answered: yes. Saved at docs/reviews/api-consistency-review-2026-10-10-u2c1-i2.md with `Commit: cf7dd447` at the top. 2 findings, each with Severity, Location path:line, verbatim Evidence, Confidence and Legibility-target. All 8 iteration-1 dispositions were confirmed against the code.
- Out of scope / not repeated: fact-check i2 Claims 5, 7 and 14a (being fixed); deferred rows B3, B4, B9, B10 and A1's lib copy (rows exist, fact-check Claim 1).
- Escalate: none.
