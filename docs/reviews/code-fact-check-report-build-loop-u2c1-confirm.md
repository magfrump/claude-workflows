# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u2c1 (branch `feat/build-loop-u2c1`)
**Commit:** 069ddfa9
**Replication:** k=1 (confirming pass)
**Scope:** Partial. `git diff fcc2dd9b..HEAD -- scripts test` (commits 0f9b6a46 and 069ddfa9: `scripts/build-loop.sh`, `scripts/lib/dev-cycle-read.sh`, `test/scripts/build-loop-check.bats`), the override-log rows added in fcc2dd9b (`git diff 9e7c61c5..fcc2dd9b -- docs/reviews/override-log.md`, rows 618-622), and commit 0f9b6a46's message. The rest of the branch is context only.
**Checked:** 2026-10-10
**Total claims checked:** 17
**Summary:** 16 verified, 1 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) read first. No claim matches a logged pattern.

## Execution provenance

Scratch dir `S=/tmp/claude-1000/-workspace/54247aa5-2a95-449b-b931-3ed456da322c/scratchpad/u2c1-confirm-fc`.

- **E1** `LC_ALL=C TMPDIR=$(mktemp -d /tmp/u2c1-cfc-XXXX) bats test/scripts/build-loop-check.bats`. Run in `/workspace/.claude/wt-build-loop-u2c1`, exit 0, started 2026-10-10T11:18:34Z. 138 of 138 ok. Output: `$S/check.log`.
- **E2** `LC_ALL=C TMPDIR=$(mktemp -d /tmp/u2c1-cfc-XXXX) bats test/scripts/build-loop-read.bats`. Same cwd, run after E1 (serially), exit 0, finished 2026-10-10T11:19:45Z. 20 of 20 ok. Output: `$S/read.log`.
- **E3** `bash $S/probe.sh`, started 2026-10-10T11:21:30Z, exit 0. The script uses `set -eu` and `T=$(mktemp -d /tmp/u2c1-cfc-XXXX)`, then copies `scripts/` and `test/` into `$T/A` and `$T/B`. It runs no git write command in the worktree. Script: `$S/probe.sh`. Output: `$S/probe.log`.
  - **E3a** (copy A): `brief_fields` is wrapped to fail only when `$BASHPID == $$`, so check_line's re-read in the parent shell fails while status_line's subshell read still succeeds. A probe test runs `Paths: docs/a` with docs/a, a lower-case plan doc, an upper-case `Docs/Working/Plan-…` and a lower-case added review. Result: `ok 1 PROBE cfc unread`. It asserts status 2; verdict `refuse $B: the brief could not be read again from the default branch`; deny lines carrying that same text for docs/a and Docs/Working/Plan-…; and path lines for the two lower-case own files.
  - **E3b** (copy B): D1's guard is reverted to `! ownfile "$2" "$1" "$4" || return 0`, then the malformed-Paths test is run. Result: `not ok 1`, failing at the assertion chain ending `:1977` on its first row (`Paths: docs/a docs/a/|lists entry 2 twice`), so the new test row catches the pre-D1 code.

---

## Claim 1: "After an ok line, a K of N refusal, a checkout refusal or "refuse BRIEF: the brief could not be read again from the default branch" (a self-merge brief), one line per path TREE changes against main"

**Location:** `scripts/build-loop.sh:155-158`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility target:** the reader of --help knows path lines still follow a re-read refusal.
**Scope:** Covers the case where the re-read refusal is the verdict line and the merge changes at least one path. Does not cover a merge that changes no path, where the code prints only the verdict (`if [[ ${#ps[@]} -eq 0 ]]; then echo "${co:-ok $a $sha $tree}"; return; fi`, `:827`), which is consistent with "one line per path".

check_line sets the refusal as `co` when the re-read fails: `if brief_fields "$a"; then read_paths; else PATHS=(); PATHS_WHY=unread; co="${co:-refuse $a: the brief could not be read again from the default branch}"; fi` (`scripts/build-loop.sh:825`). It then prints `co` and every row: `if [[ -n "$co" ]]; then echo "$co"; elif ...; fi` / `printf '%s\n' "${rows[@]}"` (`:844-845`; check_line ends at `:846`, read). In E3a the verdict was the refusal and path and deny lines followed.

**Evidence:** `scripts/build-loop.sh:155-158`, `scripts/build-loop.sh:825-846`, `$S/probe.log`

---

## Claim 2: floor "not run when the verdict already refuses for the checkout or the brief's re-read, so a loop's advisory run from its own branch can print a path the floor would refuse as a path line" (D3, D4)

**Location:** `scripts/build-loop.sh:181-184`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility target:** a loop author knows the advisory run's path lines are not floor-checked.
**Scope:** Covers the floor skip when `co` is set, and the checkout refusal on a branch checkout. Does not establish which other rule (a never glob, the allowlist) may still deny such a path. Only a path the never globs pass that Paths: lists, or an own file, prints as a path line.

srules gates the floor on `$5`: `if [[ -z "$5" ]] && floor "$2" "$1" "$4"; then DENY="$FLOOR_WHY"; return 0; fi` (`scripts/build-loop.sh:668`). check_line passes `co` as `$5`: `srules "$stem" "$p" "${lps[$i]}" "${ss[$i]}" "$co"` (`:841`). `co` holds either the checkout refusal (`:819`) or the re-read refusal (`:825`). checkout_gate refuses any HEAD other than main's commit: `[[ "$x" == "$MAIN_SHA" ]] || { CHECKOUT_WHY="the checkout's HEAD is $x, not the default branch's commit $MAIN_SHA"; return 1; }` (`:709`). So on a loop's own branch, with at least one commit beyond main (check_line refuses n=0 at `:790`), `co` is always set.

**Evidence:** `scripts/build-loop.sh:181-184`, `scripts/build-loop.sh:665-678`, `scripts/build-loop.sh:709`, `scripts/build-loop.sh:790`, `scripts/build-loop.sh:819`, `scripts/build-loop.sh:825`, `scripts/build-loop.sh:841`

---

## Claim 3: "the allowlist takes these only when the whole path is lower case, though the floor passes any case" (D1)

**Location:** `scripts/build-loop.sh:190-192`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility target:** --help states D1's rule.
**Scope:** Covers working docs and added reviews in any case, through the srules guard and floor's lowered call. Does not cover a stem containing upper case, which cannot occur because the stem comes from an isbrief name (Claim 7).

srules: `[[ "$2" != "$3" ]] || ! ownfile "$2" "$1" "$4" || return 0` (`scripts/build-loop.sh:672`). floor: `lp="$(lower "$1")"` then `elif [[ "$lp" == docs/working/* ]] && ! ownfile "$lp" "$2" "$3"` (`scripts/lib/dev-cycle-read.sh:1832`, `:1844`; floor continues to `:1851`, read). In E1, test 1967 denies `Docs/Working/Plan-…` and `docs/reviews/Code-Review-…` with the allowlist's reason, not the floor's, so the floor passed both.

**Evidence:** `scripts/build-loop.sh:190-192`, `scripts/build-loop.sh:672`, `scripts/lib/dev-cycle-read.sh:1826-1851`, `$S/check.log`

---

## Claim 4: ""Paths: PATH ..." lists paths pathform allows" (D5 placeholder)

**Location:** `scripts/build-loop.sh:192`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility target:** the help placeholder matches the malformed-line reason.
**Scope:** Covers the reason's spelling for Paths:. Does not re-check the grammar, which the final pass reviewed.

list_entries words the reason with `"is not exactly \"$2: ${3^^} ...\" with single spaces"` (`scripts/build-loop.sh:375`), and read_paths calls `list_entries "${BRIEF[paths]}" Paths path pathform` (`:636`). That gives `Paths: PATH ...`, the string test 1967 asserts.

**Evidence:** `scripts/build-loop.sh:375`, `scripts/build-loop.sh:636`, `test/scripts/build-loop-check.bats:1968`

---

## Claim 5: nrules' comment: "plus docs/working/briefs and docs/working/cycles, as files or anything under them" (D5)

**Location:** `scripts/build-loop.sh:597`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility target:** the comment names the file case the code covers.
**Scope:** Covers the fallback arm on the lower-cased path. Does not cover paths that truthrule tags cycle, settings or user, which the arm before it denies.

`*) [[ ! "$7" =~ ^docs/working/(briefs|cycles)(/|$) ]] || DENY="one of the dev cycle's own files" ;;` (`scripts/build-loop.sh:620`). `(/|$)` matches the bare name as a file, and anything under it. nrules continues to `:626`, read.

**Evidence:** `scripts/build-loop.sh:591-626`

---

## Claim 6: srules' comment: "$5 the verdict's refusal, if any (the checkout's or the brief re-read's) ... an own file counts only when the whole path is lower case (ownfile folds nothing, and its review pattern would take any letter in NAME, so this test is what keeps NAME lower case)" (D3, 069ddfa9)

**Location:** `scripts/build-loop.sh:655-664`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility target:** a reader knows why the case test exists.
**Scope:** Covers what `$5` holds, the review pattern's NAME, and that the working-doc branch is already lower case. Does not cover other ownfile callers; floor is the only other one (Claim 10).

ownfile's review arm: `[[ "$3" == A && "$1" == docs/reviews/* && "$b" != */* && ( "$b" == "$2.md" || "$b" == *"-$2.md" ) ]]` (`scripts/lib/dev-cycle-read.sh:1811`). `*` takes any case in NAME. The working-doc arm fixes lower-case literals plus the stem: `^docs/working/(research|plan|checkpoint|handoff|test-strategy)-(.+)\.md$ && "${BASH_REMATCH[2]}" == "$2"` (`:1810`), so for that arm only NAME needed the test. E3b shows the pre-D1 code passes `docs/reviews/Code-Review-2026-10-01-x.md`.

**Evidence:** `scripts/build-loop.sh:655-664`, `scripts/lib/dev-cycle-read.sh:1807-1812`, `$S/probe.log`

---

## Claim 7: D1 opens nothing and denies no lower-case own file it should pass

**Location:** `scripts/build-loop.sh:672`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility target:** a reader knows D1 only narrows the allowlist.
**Scope:** Covers working docs, STEM.md and NAME-STEM.md reviews spelled in lower case. Does not establish behaviour under a locale where `lower` and `lower_all` disagree. Both are the same explicit A-Z tr (`scripts/lib/dev-cycle-read.sh:826`, `:1491`), run under check_line's `local -x LC_ALL=C` (`:778`).

The added guard can only skip ownfile, so a path either falls through to the Paths: test or reaches `return 0` as before. It never returns early with an empty DENY that the old line did not. `$3` is `lower_all`'s spelling of `$2` (`:837`, `:841`), so `$2 == $3` holds exactly when the path has no A-Z. The stem is `stem="${a##*/}"; stem="${stem%.md}"` (`:821`), and briefs match `SLUG='[abcdefghijklmnopqrstuvwxyz0123456789-]+'` (`scripts/lib/dev-cycle-read.sh:230-231`), so every own file of a valid brief is lower case. In E1, the self-merge own-files test (`test/scripts/build-loop-check.bats:1938-1946`, verdict `ok` with path lines for `docs/reviews/2026-10-01-x.md` and `docs/reviews/code-review-2026-10-01-x.md` plus three working docs) and test 1967 (`path $B A docs/working/plan-2026-10-01-x.md`) pass.

**Evidence:** `scripts/build-loop.sh:672`, `scripts/build-loop.sh:821`, `scripts/build-loop.sh:837-841`, `scripts/lib/dev-cycle-read.sh:230-231`, `$S/check.log`

---

## Claim 8: a failed re-read sets PATHS_WHY=unread, with its own deny text "the brief could not be read again from the default branch"; the sentinel cannot collide with list_entries' values (D3)

**Location:** `scripts/build-loop.sh:673`, `scripts/build-loop.sh:825`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility target:** the sentinel and its deny text are unambiguous.
**Scope:** Covers every PATHS_WHY writer and the per-brief reset. Does not cover a test in the suite. No suite test drives the re-read failure (`grep 'could not be read again' test/scripts/build-loop-check.bats` finds nothing), so E3a is the only execution.

PATHS_WHY is written only at `PATHS=(); PATHS_WHY=""` (`:632`, `:634`), `PATHS=("${LIST[@]}"); PATHS_WHY="$LIST_WHY"` (`:637`) and `PATHS_WHY=unread` (`:825`). LIST_WHY's only values are `"is not exactly …"` (`:375`), `"lists entry $i, which is not an allowed $3 form"` (`:380`) and `"lists entry $i twice"` (`:381`). None is `unread`. Every self-merge brief runs one of the two branches at `:825` before srules, so no earlier brief's value carries over. srules: `[[ "$PATHS_WHY" != unread ]] || { DENY="the brief could not be read again from the default branch"; return 0; }` (`:673`). It comes after the ownfile test, so own files still pass. E3a observed this.

**Evidence:** `scripts/build-loop.sh:370-385`, `scripts/build-loop.sh:632-638`, `scripts/build-loop.sh:673`, `scripts/build-loop.sh:825`, `$S/probe.log`

---

## Claim 9: check_line's globals list: "each helper empties its own globals before use (DENY, PATHS and PATHS_WHY, LIST, LIST_WHY and LIST_BAD, ...)" (D5)

**Location:** `scripts/build-loop.sh:773-776`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility target:** the list names LIST_BAD.
**Scope:** Covers LIST_BAD, the item this diff added. Does not re-check the other names, which the final pass reviewed.

`LIST=(); LIST_WHY=""; LIST_BAD=""` is list_entries' first statement after its locals (`scripts/build-loop.sh:373`).

**Evidence:** `scripts/build-loop.sh:370-385`, `scripts/build-loop.sh:773-776`

---

## Claim 10: lib contract item 8: "ownfile folds no case: floor passes it the lowered path, build-loop.sh's srules only an all-lower-case one" (D2)

**Location:** `scripts/lib/dev-cycle-read.sh:90-94`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility target:** the contract names both ownfile callers and what each passes.
**Scope:** Covers every ownfile call in `scripts/`. Does not cover callers outside the repo's scripts.

`grep -n ownfile` finds calls only at `scripts/lib/dev-cycle-read.sh:1844-1845` (`! ownfile "$lp" "$2" "$3"`, with lp lowered at `:1832`) and `scripts/build-loop.sh:672` (guarded by `[[ "$2" != "$3" ]]`). ownfile itself compares with no case folding (`:1807-1812`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:90-94`, `scripts/lib/dev-cycle-read.sh:1807-1845`, `scripts/build-loop.sh:672`

---

## Claim 11: test 1967's title, "a malformed Paths: line lands only the brief's own files, spelled in lower case", with the new Code-Review row and `nref 3 4`

**Location:** `test/scripts/build-loop-check.bats:1967-1979`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility target:** the test catches D1's regression.
**Scope:** Covers the upper-case NAME review on every row, the count, and the test catching the pre-D1 code. Does not cover a lower-case review row in this test; test 1938 covers that.

The row adds `echo x > docs/reviews/Code-Review-2026-10-01-x.md` (`:1972`) and asserts `has "deny $B A docs/reviews/Code-Review-2026-10-01-x.md: $w"` (`:1976`). The count is 4 changed paths with 3 denied, matching `nref 3 4` (`:1975`). It passes at HEAD (E1) and fails with D1 reverted (E3b).

**Evidence:** `test/scripts/build-loop-check.bats:1967-1979`, `$S/check.log`, `$S/probe.log`

---

## Claim 12: override row 618: "Correction to the row above on floor's per-path forks: one cached floor call runs need_root 4 times (floor, isimported, main_imports twice before its cache check), not twice; measured ~476 µs each, about 36% of floor's ~6 ms; the two lower forks are as stated"

**Location:** `docs/reviews/override-log.md:618`
**Type:** Reference / Performance
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility target:** a U2c2 author sizes the root-check work from this row.
**Scope:** Covers the call count against the code and the figures against the final performance report. Does not re-measure the timings.

The count is right. floor runs `need_root` (`scripts/lib/dev-cycle-read.sh:1830`). truthwalk's `main_imports` runs `need_root` (`:1631`) before its cache test (`:1633`). isimported runs `need_root` (`:1757`) and calls `main_imports || return 0` again (`:1760`). The figures match `docs/reviews/performance-review-2026-10-10-u2c1-final.md:35` ("`floor` 6,007 µs per call and `need_root` 476 µs per call") and `:55` ("Stubbing `need_root` removes 2.17 ms of 6.0 ms, about 36 %").

The imprecise part is the locator. The row directly above (617) is the list_entries/reader_settings row. The row corrected is 610 (`floor forks twice per path to lower-case it and runs need_root twice`). The precise text is "Correction to row 610".

**Evidence:** `docs/reviews/override-log.md:610`, `docs/reviews/override-log.md:617-618`, `scripts/lib/dev-cycle-read.sh:1627-1633`, `scripts/lib/dev-cycle-read.sh:1754-1760`, `scripts/lib/dev-cycle-read.sh:1830`, `docs/reviews/performance-review-2026-10-10-u2c1-final.md:35`, `docs/reviews/performance-review-2026-10-10-u2c1-final.md:55`

---

## Claim 13: override row 619: "the malformed-Paths row's 'the verdict still refuses' fails when only own files change (the verdict is ok and the reason shows nowhere), and ... a failed brief re-read now refuses the verdict, path lines still printed, with its own deny text"

**Location:** `docs/reviews/override-log.md:619`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility target:** the corrected rows match the as-built gate.
**Scope:** Covers both corrections at HEAD. Does not cover the state at fcc2dd9b, where the row was written. "Its own deny text" became a distinct string only in 0f9b6a46 (D3).

With a malformed line and only lower-case own files changed, every path returns at `:672` before the PATHS_WHY test (`:674`). The verdict is then `ok` (`:844`), and no line carries the reason. The re-read half was observed in E3a. "Two rows above" names rows 612 and 613 by subject ("the malformed-Paths row", "the verdict-chain row"), which identifies them.

**Evidence:** `docs/reviews/override-log.md:612-613`, `docs/reviews/override-log.md:619`, `scripts/build-loop.sh:672-674`, `scripts/build-loop.sh:844`, `$S/probe.log`

---

## Claim 14: override row 620: commit eddfd5f9 says '"Paths:" alone ... lists none' (bare "Paths:" became malformed in d435100e); d435100e says B1 "an own file lands only in lower case" and B5 "a failed re-read lands only own files"

**Location:** `docs/reviews/override-log.md:620`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility target:** the row quotes the commits correctly.
**Scope:** Covers the quoted commit text and the B1 residue. Does not cover other commit messages.

`git show -s eddfd5f9` line 9: `a trailing / a directory at a part boundary, each once; "Paths:" alone or no`. `git show -s d435100e`: `(bare "Paths:" is now` / `malformed). B1: ownfile gets the path as spelled, so an own file lands only in` / `lower case. B5: a failed brief re-read lands only own files`. B1's residue (any-case NAME) was shown in E3b.

**Evidence:** `docs/reviews/override-log.md:620`, commits eddfd5f9 and d435100e (messages), `$S/probe.log`

---

## Claim 15: override row 621: "LIST_BAD=entry has no reader; only form is read"

**Location:** `docs/reviews/override-log.md:621`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility target:** the row's premise holds.
**Scope:** Covers every LIST_BAD read in `scripts/`. Does not cover test reads.

The only read is `if [[ "$LIST_BAD" != form && "${next[never]}" != 1 ]]` (`scripts/build-loop.sh:426`). The writes are at `:369`, `:373`, `:375` and `:384`.

**Evidence:** `scripts/build-loop.sh:369-384`, `scripts/build-loop.sh:426`

---

## Claim 16: override row 622: "A loop's advisory --check from its own branch always carries a checkout refusal, so srules skips the floor and a floor path Paths: lists prints as a plain path line"

**Location:** `docs/reviews/override-log.md:622`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility target:** the row's premise holds.
**Scope:** Covers the HEAD check and the floor gate. Does not cover a never glob matching that path, which still denies it.

paraphrased — no quote available because this row restates the mechanism already quoted in Claim 2 (`scripts/build-loop.sh:709`, `:668`, `:841`): checkout_gate refuses a HEAD other than main's commit, and srules runs floor only when `$5` is empty.

**Evidence:** `scripts/build-loop.sh:668`, `scripts/build-loop.sh:709`, `scripts/build-loop.sh:841`

---

## Claim 17: commit 0f9b6a46's message: D1-D6 as listed ("D6: correction rows for 610, 612, 613 (in the reports commit)")

**Location:** commit 0f9b6a46 (message)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility target:** the message maps to the diff.
**Scope:** Covers each D item against the diff and the rows' commit. Does not cover the rubric's own wording of D1-D6.

D1 is `:672` plus the test row at `test/scripts/build-loop-check.bats:1972-1976`. D2 is lib `:90-94`. D3 is `:155-157`, `:657-658`, `:673` and `:825`. D4 is `:181-184`. D5 is `:192`, `:775` and `:597`. Rows 618 and 619 (correcting 610, 612 and 613) appear in `git diff 9e7c61c5..fcc2dd9b -- docs/reviews/override-log.md`, and fcc2dd9b is the reports commit.

**Evidence:** `scripts/build-loop.sh:155-192`, `scripts/build-loop.sh:597`, `scripts/build-loop.sh:655-673`, `scripts/build-loop.sh:775`, `scripts/build-loop.sh:825`, `scripts/lib/dev-cycle-read.sh:90-94`, `docs/reviews/override-log.md:618-619`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 12** (`docs/reviews/override-log.md:618`): "Correction to the row above" points at row 617 (list_entries). The row it corrects is 610. Read it as "Correction to row 610". The count and figures are right.

### Unverifiable
(none)

Note (not a verdict): no suite test drives the failed-re-read branch (`scripts/build-loop.sh:825`, `:673`). Only probe E3a exercised it.

## Goal-Alignment Note

Success criterion, restated verbatim: "a markdown report saved at the output path your dispatch names, structured per your skill, every finding with verbatim Evidence and a path:line." This report is saved at `docs/reviews/code-fact-check-report-build-loop-u2c1-confirm.md`, follows the skill's header and seven per-claim fields (plus a legibility target), and quotes code with path:line for every finding. One paraphrase (Claim 16) is tagged with its reason. The build-loop-check suite (138/138) and build-loop-read suite (20/20) were run serially, both green.
