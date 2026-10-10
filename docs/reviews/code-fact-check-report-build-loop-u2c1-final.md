# Code Fact-Check Report

**Commit:** 9e7c61c5
**Replication:** k=3
**Repository:** /workspace/.claude/wt-build-loop-u2c1 (branch `feat/build-loop-u2c1`)
**Scope:** `git diff main...HEAD` at 9e7c61c5, the whole branch: scripts/build-loop.sh, scripts/lib/dev-cycle-read.sh, test/scripts/build-loop-check.bats, docs/working/plan-build-loop-handoff.md, the override-log rows dated 2026-10-10 for `feat/build-loop-u2c1` (docs/reviews/override-log.md:608-617), and the branch's commit messages. Review reports under docs/reviews/ are artifacts, not claims. Merged (most-severe-wins, annotations by union) from replicates r1, r2 and r3: `docs/reviews/code-fact-check-report-build-loop-u2c1-final-r1.md`, `-r2.md`, `-r3.md`.
**Checked:** 2026-10-10
**Total claims checked:** 63
**Summary:** 40 verified, 9 mostly accurate, 4 stale, 6 incorrect, 4 unverifiable

This report is mechanical collation of the three replicate reports (code-review SKILL.md, "Merging replicate verdicts (most-severe-wins)"). It adds no claim or evidence. Where any replicate split a sentence into sub-claims, the merged report carries one `## Claim` per sub-claim, and a replicate that verdicted only the compound shows its verdict on each sub-claim row marked `(compound)`. Each claim's headline evidence comes from the replicate whose verdict won.

## Claims Requiring Attention

### Incorrect
- **Claim 3a** (`docs/reviews/override-log.md:610`): one cached floor call runs need_root **4** times, not twice: floor itself, main_imports through truthwalk, isimported, and main_imports again from isimported. (r1 Incorrect, r2 Mostly accurate, r3 Verified)
- **Claim 3b** (`docs/reviews/override-log.md:610`): "~5.7 ms of the S rules' ~6.4 ms": r1 measured two lower plus four need_root calls at about 4.4 ms of floor's 6.6 ms. (r1 Incorrect, r2 Mostly accurate (compound), r3 Unverifiable (compound))
- **Claim 12b** (`docs/working/plan-build-loop-handoff.md:311`): "an own file counts only when the diff spells it in lower case" does not hold for an added `docs/reviews/NAME-STEM.md`, whose NAME matches in any case. r3's E7 landed `docs/reviews/Code-Review-2026-10-01-x.md` while main held `code-review-…`. (r3 only)
- **Claim 18b** (`scripts/build-loop.sh:185-186`): --help's "the allowlist takes these only in lower case": the same NAME-STEM.md exception. (r3 only)
- **Claim 27b** (`scripts/build-loop.sh:654-657`): srules' "an own file passes only when the diff spells it in lower case": the same exception. The mechanism ("ownfile folds nothing") is right. (r3 only)
- **Claim 50** (commit `d435100e` message, B1): "an own file lands only in lower case": the same exception. The commit message is immutable. (r3 only, single-replicate detection)

### Stale
- **Claim 6** (`docs/reviews/override-log.md:613`): "it now lands only own files" predates C1. A failed re-read now refuses the verdict, with every line printed. Amend the row in a new row. (r1, r2 Stale; r3 Verified)
- **Claim 37** (`scripts/lib/dev-cycle-read.sh:90-93`): contract item 8 still tells callers to pass ownfile a lower-cased path, but srules passes it as spelled, on purpose. (r2, r3)
- **Claim 46** (commit `eddfd5f9` message): "'Paths:' alone … lists none" was superseded by d435100e, which made bare `Paths:` malformed. Immutable. (r1, r2, r3)
- **Claim 52** (commit `d435100e` message, B5): "a failed brief re-read lands only own files" was superseded by C1. Immutable. (r2 only, single-replicate detection)

### Mostly Accurate
- **Claim 3c** (`docs/reviews/override-log.md:610`): "400 paths take 3.1 s against main's 0.3 s". Only r2's compound Mostly accurate verdict makes this Mostly accurate, and that verdict is about need_root. r2's own text says "The totals also reproduce". r1 Verified it; r3 Unverifiable (compound).
- **Claim 5** (`docs/reviews/override-log.md:612`): the Paths reason shows only on non-own paths that the floor and never globs pass. With only own files changed, the verdict is ok and the malformed line shows nowhere. (r2)
- **Claim 14** (`scripts/build-loop.sh:155`): path lines also follow the brief re-read refusal. --help lists only ok, K of N and checkout refusals. (all three)
- **Claim 16b** (`scripts/build-loop.sh:179`): the floor's "not run over a checkout refused above" leaves out the re-read refusal, which also skips the floor. (r1 compound with :155)
- **Claim 23a** (`scripts/build-loop.sh:590-592`): nrules' comment says only "anything under" briefs/ and cycles/. The code also denies them as files. (r3 only, single-replicate detection)
- **Claim 23b** (`scripts/build-loop.sh:593-595`): r3's compound Mostly accurate verdict on the nrules comment carries onto this row. r1 and r2 Verified it.
- **Claim 27a** (`scripts/build-loop.sh:649-654`): srules' `$5` is the checkout **or re-read** refusal, not only the checkout refusal. (r2)
- **Claim 28** (`scripts/build-loop.sh:666`): on a failed re-read the deny text says "so only its own files land", but the verdict refuses everything. (r2 only, single-replicate detection)
- **Claim 42** (`test/scripts/build-loop-check.bats:1967`): the title's "own files, spelled in lower case" holds for the working doc it tests, not for NAME-STEM.md reviews. (r3)

### Unverifiable
- **Claim 4** (`docs/reviews/override-log.md:611`): the timings of the membership glob. Checking them needs a micro-benchmark on 28 KB and IMPORT_OUT_MAX-sized walk lists. r1's benchmark was blocked by a safety check.
- **Claim 13b** (`docs/working/plan-build-loop-handoff.md:312`): the figures 6.4 ms, 3.1 s and 0.3 s (r3 Unverifiable). r1 and r2 Verified them by their own timing runs.
- **Claim 48** (commit `eddfd5f9` message): the timings need the 3,284-file clone, which is not in the repo.
- **Claim 54** (commit `62877331` message): the i1 fact-check counts. That report is an artifact outside this pass's scope. (r3 only)

## Execution provenance

Every `executed` verdict below comes from one replicate's own runs. That replicate's report records the command, cwd, exit code, timestamp and captured-output file. The scratch directories are:

- `$S1` = `/tmp/claude-1000/-workspace/54247aa5-2a95-449b-b931-3ed456da322c/scratchpad/u2c1-final-fc-r1` (r1's E1-E5: mutations M1, M2, M3 and M5, probes P1 and C1, both full suites, the bench, count and timing runs).
- `$S2` = `/tmp/claude-1000/-workspace/54247aa5-2a95-449b-b931-3ed456da322c/scratchpad/u2c1-final-fc-r2` (r2's E1-E7: suites, FCPROBE 1-3, the reread/nolcall/noreset mutants, the exit probe, the count probe and the timing probe).
- `$S3` = `/tmp/claude-1000/-workspace/54247aa5-2a95-449b-b931-3ed456da322c/scratchpad/u2c1-final-fc-r3` (r3's E1-E8: the U2c1 tests, mutants A and B, the exit probe, the diff-tree probe, the fork timing, the mixed-case review probe E7, and build-loop-read).

All three replicates ran both suites green: build-loop-check 138/138 and build-loop-read 20/20. r3 ran the six U2c1 tests plus build-loop-read; its one build-loop-read failure was its archive copy's missing file, and the test passed on a re-run.

---

## Claim 1: row 608, "A directory at an instruction-file name or an @-import target lands under self-merge (`src/CLAUDE.md/n.txt` …): the floor tests the whole path only"

**Location:** `docs/reviews/override-log.md:608`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the claim that floor tests only the whole lower-cased path and never a directory above it. Does not establish the row's availability argument (that a directory is never loaded as instructions).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "does not re-run i1 security's probe" · r3: "does not establish what U2c2's planned fix does"

From r1, the winner by lowest replicate number: floor tests `lp`, the whole path (`if truthrule "$lp"; then` … `elif truthwalk main "$lp"; then`, `scripts/lib/dev-cycle-read.sh:1832-1849`). isstart tests only the last part: `isstart() { [[ "${1##*/}" =~ $INSTRUCTION_FILE ]] || …` (`scripts/lib/dev-cycle-read.sh:663`). The import test is exact membership: `[[ "$IMPORTED_MAIN" == *$'\n'"$lp"$'\n'* ]]` (`:1759`, per r2 and r3).

**Evidence:** `scripts/lib/dev-cycle-read.sh:663`, `scripts/lib/dev-cycle-read.sh:1754-1763`, `scripts/lib/dev-cycle-read.sh:1827-1850`

---

## Claim 2: row 609, "An added review named NAME-STEM.md can take a sibling brief's STEM.md name … A loop cannot choose sibling stems (… briefs/ is N-denied), and an added review takes no existing name."

**Location:** `docs/reviews/override-log.md:609`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers ownfile's suffix match, the N rule denying `docs/working/briefs/`, and the rule that only an added review counts. Does not establish how the cycle chooses stems.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r3: "does not cover the row's reason that 'an added review takes no existing name'. That holds case-sensitively, but on a case-insensitive checkout a mixed-case added review can share an existing review's name (Claim 15b, E7)" (r3's 15b is merged Claim 18b) · r2: "Does not judge the Won't-Fix reasoning."

From r1: `[[ "$3" == A && "$1" == docs/reviews/* && "$b" != */* && ( "$b" == "$2.md" || "$b" == *"-$2.md" ) ]]` (`scripts/lib/dev-cycle-read.sh:1810`). The N rules deny briefs/: `[[ ! "$7" =~ ^docs/working/(briefs|cycles)(/|$) ]] || DENY=…` (`scripts/build-loop.sh:614`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1806-1811`, `scripts/build-loop.sh:614`

---

## Claim 3a: row 610, "floor forks twice per path to lower-case it and runs need_root twice"

**Location:** `docs/reviews/override-log.md:610`
**Type:** Performance
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers how many times one cached floor call runs lower and need_root, for a path that reaches truthwalk. Does not establish the costs on the performance reviewer's machine.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Incorrect (compound with 3b) · r2=Mostly accurate (compound) · r3=Verified
**Replicate annotations:** r1+r2: the lower count (2) is right; the need_root count is 4 · r3: "does not establish the count for paths an earlier arm refuses, which stop after one need_root and one lower" · r1: "Both main_imports calls also run import_readers before the cache test" · r1: "A U2c2 fix that removes two need_root calls would still leave two."

From r1: one cached floor call runs `lower` twice and `need_root` **four** times (`$S1/count.out`: "need_root calls in one cached floor: 4", "lower calls in one cached floor: 2"). The four calls are floor's own (`scripts/lib/dev-cycle-read.sh:1829`), main_imports through truthwalk (`:1630`), isimported (`:1756`), and main_imports again from isimported (`main) main_imports || return 0;`, `:1759`). r2's E6 count agrees independently (`$S2/countprobe.out`: `need_root runs: 4, lower runs: 2`). r3 counted statically and found two.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1626-1631`, `scripts/lib/dev-cycle-read.sh:1754-1762`, `scripts/lib/dev-cycle-read.sh:1827-1832`, `$S1/count.out`, `$S2/countprobe.out`

---

## Claim 3b: row 610, "~5.7 ms of the S rules' ~6.4 ms per path"

**Location:** `docs/reviews/override-log.md:610`
**Type:** Performance
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the share of floor's per-path time taken by the lower and need_root calls, on this machine. Does not establish the costs on the performance reviewer's machine.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Incorrect (compound with 3a) · r2=Mostly accurate (compound) · r3=Unverifiable (compound with 3c)
**Replicate annotations:** r2: "Does not re-measure floor's 5.7 ms in isolation." · r3: E6 measured the four calls at "2.85 ms per path on this host, against the row's ~5.7 ms. The numbers depend on the host and its load." · r1: "The row's conclusion holds: the cost is forks per call, not the membership test."

From r1 (`$S1/bench2.out`, three runs): floor whole call 6.57–6.58 ms, lower ~1.35 ms per call, need_root ~0.42 ms per call, cached main_imports ~0.85 ms. "Two lower calls and four need_root calls come to about 4.4 ms of 6.6 ms, not 5.7 ms. The rest is mostly the two cached main_imports/import_readers entries."

**Evidence:** `docs/reviews/override-log.md:610`, `$S1/bench2.out`, `$S1/count.out`, `$S3/probe6.log`

---

## Claim 3c: row 610, "400 paths take 3.1 s against main's 0.3 s"

**Location:** `docs/reviews/override-log.md:610`
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the 400-path totals on a 3,000-file fixture with a self-merge brief. Does not establish timings on other hardware or with a larger walk.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Verified · r2=Mostly accurate (compound) · r3=Unverifiable (compound with 3b)
**Replicate annotations:** r2 (the winning replicate) on this part of its compound: "The totals also reproduce. E7 measured 400 paths at `secs=3.124` and `secs=3.17` on the branch against `secs=0.349` and `secs=0.35` on main"; r2's Mostly accurate verdict rests on the need_root count (Claim 3a) · r1: E5 measured 3.02 / 3.05 s against 0.33 / 0.33 s, "(3.03 − 0.47) / 399 ≈ 6.4 ms per path" · r3: "does not reproduce the 3,000-file fixture or the 400-path end-to-end timing"

The verdict is r2's compound Mostly accurate, applied by most-severe-wins. Both replicates that timed the 400-path run got the row's figures (r1 `$S1/timing.out`, r2 `$S2/timeprobe.out`).

**Evidence:** `$S1/timing.out`, `$S2/timeprobe.out`, `docs/reviews/override-log.md:610`

---

## Claim 4: row 611, "the glob test is 0.12 ms per path on a 28 KB walk list, 43 ms only near IMPORT_OUT_MAX"

**Location:** `docs/reviews/override-log.md:611`
**Type:** Performance
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers that the numbers trace to i1 performance's measurement. Does not establish the timings themselves, which no replicate re-ran.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Unverifiable · r2=Unverifiable · r3=Unverifiable
**Replicate annotations:** r1: "My benchmark of it was blocked by a Claude Code safety check before it ran" · r3: the test is "linear in the list's size, which fits the row's scaling" · r1+r2+r3: verifying it needs the membership glob timed on 28 KB and IMPORT_OUT_MAX (6 MB) strings

From r2, which has the most specific Scope line: the row quotes i1 performance, "Membership itself costs 118 µs" and "43 ms per path at 6 MB" (`docs/reviews/performance-review-2026-10-10-u2c1.md:53`, `:72`). The test is `[[ "$IMPORTED_MAIN" == *$'\n'"$lp"$'\n'* ]]` (`scripts/lib/dev-cycle-read.sh:1760`).

**Evidence:** `docs/reviews/performance-review-2026-10-10-u2c1.md:53`, `docs/reviews/performance-review-2026-10-10-u2c1.md:72`, `scripts/lib/dev-cycle-read.sh:1759-1760`

---

## Claim 5: row 612, "A malformed Paths: line shows only as the same reason on every non-own deny line, while --status still prints POLICY self-merge"

**Location:** `docs/reviews/override-log.md:612`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers where the malformed-Paths reason appears and the verdict when only own files change. Does not judge the deferral.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Verified · r2=Mostly accurate · r3=Verified
**Replicate annotations:** r3: "does not establish 'every non-own' for paths the floor or a never glob refuses first, which carry their own reasons" · r1: "Does not establish what U3 or U4 will need."

From r2: the reason is per path (`DENY="the brief's Paths: line $PATHS_WHY, so only its own files land"`, `scripts/build-loop.sh:666`), and status_line's policy ignores Paths: (`scripts/build-loop.sh:501-503`). Both quantifiers are too broad. First, floor and never-glob denials come first (`:661-664`): in FCPROBE 2, `deny ... A docs/thoughts/t.md: a record later runs read as truth` carries the floor's reason. Second, when only own files change, the verdict is ok: FCPROBE 1 prints `status=0` for `Paths:  docs/a` (`$S2/run-probes2.txt`).

**Evidence:** `scripts/build-loop.sh:501-503`, `scripts/build-loop.sh:658-670`, `$S2/run-probes2.txt`, `$S2/probe-tests.bats.part`

---

## Claim 6: row 613, "The concrete slip (a failed re-read printed no path line) is fixed: it now lands only own files with every line printed."

**Location:** `docs/reviews/override-log.md:613`
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what --check does at 9e7c61c5 when the brief re-read fails. Does not establish the verdict-chain deferral the row records.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Stale · r2=Stale · r3=Verified
**Replicate annotations:** r3 (verdicted Verified, statically): "does not cover a test, since none fails a second read" · r1+r2: "Every line printed" still holds; "lands only own files" does not

From r1: the row describes d435100e. C1 (9e7c61c5) changed the behaviour: `if brief_fields "$a"; then read_paths; else PATHS=(); PATHS_WHY="could not be read again"; co="${co:-refuse $a: the brief could not be read again from the default branch}"; fi` (`scripts/build-loop.sh:817`). E4 (`$S1/run-c1.txt`) prints `status=2` and the refuse line, then path and deny lines. r2's reread mutant agrees (`$S2/run-reread.txt`).

**Evidence:** `scripts/build-loop.sh:812-819`, `docs/reviews/override-log.md:613`, `$S1/run-c1.txt`, `$S2/run-reread.txt`

---

## Claim 7: row 614, "The lib's caller contract item 5 and FLOOR_WHY's comment name build-loop.sh's nrules and srules"

**Location:** `docs/reviews/override-log.md:614`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the lib text names the caller's rules. Does not judge whether naming them is right.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=—
**Replicate annotations:** r2: "Item 5 names the rules ('N rules', 'S rules') rather than the function names."

From r1: item 5 reads "build-loop.sh's N rules apply them … and its S rules run floor only on a path they pass" (`scripts/lib/dev-cycle-read.sh:82-83`). The FLOOR_WHY comment reads `# read by floor's caller (build-loop.sh srules)` (`:1825`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:76-85`, `scripts/lib/dev-cycle-read.sh:1825`

---

## Claim 8: row 615, "check_line's `local -x LC_ALL=C` is dynamic: status_line runs under C in --check but under the caller's locale in --status"

**Location:** `docs/reviews/override-log.md:615`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the locale scoping. Does not establish the row's reason that every regex in status_line is safe under any locale.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2+r3: "does not establish the row's claim that status_line's output is the same either way" · r1: "only marker_kind's grep was read for that" · r2: "The only other script-level LC_ALL settings are per command or in checkout_gate (`:482`, `:582`, `:692`, `:713`)."

From r1: check_line sets `local -x LC_ALL=C` (`scripts/build-loop.sh:771`), then `out="$(status_line "$a")"` (`:774`). --status runs `for a in "${ARGS[@]}"; do status_line "$a"; done` (`:843`) with no locale set.

**Evidence:** `scripts/build-loop.sh:482`, `scripts/build-loop.sh:771-774`, `scripts/build-loop.sh:841-844`

---

## Claim 9: row 616, "list_entries now parses both Self-merge never: and Paths: (and Paths: takes "none" as the settings lists do). The lib's reader_settings keeps its own copy"

**Location:** `docs/reviews/override-log.md:616`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers list_entries' two callers and reader_settings' separate parser. Does not establish that the two grammars are identical.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r3: "does not establish that there are no other list-line parsers" · r2: "Does not judge the deferral."

From r1: the callers are `list_entries "$t" "Self-merge never" glob globform` (`scripts/build-loop.sh:418`) and `list_entries "${BRIEF[paths]}" Paths path pathform` (`:630`). `[[ "$v" != none ]] || return 0` (`:370`). reader_settings parses its own lines (`scripts/lib/dev-cycle-read.sh:604-650`).

**Evidence:** `scripts/build-loop.sh:364-379`, `scripts/build-loop.sh:418`, `scripts/build-loop.sh:630`, `scripts/lib/dev-cycle-read.sh:604-650`

---

## Claim 10: row 617, "list_entries depends on nothing in build-loop.sh (pathform, globform's NAMECHARS are the lib's)"

**Location:** `docs/reviews/override-log.md:617`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers list_entries' own body. Does not establish that its FORM argument `globform`, defined in build-loop.sh, could move with it.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2+r3: globform is a build-loop.sh function passed in as FORM, and whether it moves is not established

From r1: list_entries touches only its arguments and its own globals, and calls `"$4" "${e%/}"` (`scripts/build-loop.sh:374`). globform uses the lib's `$NAMECHARS` (`:384`), which the lib defines (`scripts/lib/dev-cycle-read.sh:212`, per r2).

**Evidence:** `scripts/build-loop.sh:363-391`, `scripts/lib/dev-cycle-read.sh:212`

---

## Claim 11: "`Paths: P…` (`Paths: none` or no line lists none; a malformed or duplicate entry lands only the brief's own files: U2c1)"

**Location:** `docs/working/plan-build-loop-handoff.md:238`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers read_paths, list_entries and srules for each case. Does not establish behaviour under review policy, where the S rules never run.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "Does not cover a failed re-read, which refuses the verdict" · r3: "does not cover which own files land (see Claim 15b)" (merged Claim 18b)

From r1: no line, `[[ -n "${BRIEF[paths]+set}" ]] || return 0` (`scripts/build-loop.sh:629`). For none, `[[ "$v" != none ]] || return 0` (`:370`). A duplicate gives `LIST_WHY="lists entry $i twice"` (`:375`). For a malformed line, srules keeps own files (`:665`) and then refuses the rest (`:666`). All seven cases of the malformed-line test pass (`$S1/full-build-loop-check.txt`).

**Evidence:** `scripts/build-loop.sh:364-379`, `scripts/build-loop.sh:627-632`, `scripts/build-loop.sh:658-670`, `test/scripts/build-loop-check.bats:1967-1978`, `$S1/full-build-loop-check.txt`

---

## Claim 12a: plan U2c1 note: floor only when `co` is empty, never-glob semantics, Paths: grammar, check_line in the parent shell with output to a file, import_reset observable by a worktree-listing count, under `LC_ALL=C`, S rules off under review

**Location:** `docs/working/plan-build-loop-handoff.md:311`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed atom against the code and the mutation runs. Does not establish the own-file lower-case atom (Claim 12b) or the carried rows' own past wording.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r2: "Does not cover rows 526, 349 and 474 beyond the N rules' mode test"; E3 shows a symlink and a gitlink at listed paths denied · r1: "Does not establish the 'Carried' rows' own past wording."

From r3: srules runs `if [[ -z "$5" ]] && floor ...`, then the NEVER_RES loop, then ownfile and Paths: (`scripts/build-loop.sh:661-670`). The main loop runs `check_line "$a" > "$GATE_TMP/line"; cat "$GATE_TMP/line"` (`:858`). The S rules are skipped unless `"$pol" == self-merge` (`:833`). The test fails without import_reset or without the C locale (`$S3/bats-u2c1-mutA.out`, `$S3/bats-u2c1-mutB.out`); r1's M1 and M2 and r2's noreset and nolcall mutants agree.

**Evidence:** `scripts/build-loop.sh:658-671`, `scripts/build-loop.sh:769-838`, `scripts/build-loop.sh:849-862`, `$S3/bats-u2c1-mutA.out`, `$S3/bats-u2c1-mutB.out`, `$S1/run-m1.txt`, `$S1/run-m2.txt`

---

## Claim 12b: plan U2c1 note: "an own file counts only when the diff spells it in lower case, as ownfile's patterns are (i1 security 2)"

**Location:** `docs/working/plan-build-loop-handoff.md:311`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers added reviews named NAME-STEM.md and working docs. Does not establish whether a case-colliding added review is a security problem (that is the security critic's call).
**Legibility-target:** for-author
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Incorrect
**Replicate annotations:** r1: "The lower-case own-file rule: the malformed-line test denies `Docs/Working/Plan-2026-10-01-x.md`" (a working doc only) · r3: "The rule holds for working docs (E7's `docs/working/Plan-…` was denied) and for STEM.md reviews." · r3: escalation to security-reviewer (see Escalations)

From r3: ownfile pins the case of `docs/reviews/`, the STEM and `.md`, but not NAME: `[[ "$3" == A && "$1" == docs/reviews/* && "$b" != */* && ( "$b" == "$2.md" || "$b" == *"-$2.md" ) ]]` (`scripts/lib/dev-cycle-read.sh:1810`). In E7, `docs/reviews/Code-Review-2026-10-01-x.md` and `docs/reviews/CODE-2026-10-01-x.md` both printed `path` under `Paths: none`, while main held `docs/reviews/code-review-2026-10-01-x.md` (`$S3/probe7.log`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1806-1811`, `scripts/build-loop.sh:665`, `$S3/probe7.log`

---

## Claim 13a: U2c2 note: "floor's per-path cost … the forks in lower and need_root, not row 470's membership test"

**Location:** `docs/working/plan-build-loop-handoff.md:312`
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers that lower and need_root fork and take the largest share of floor's time. Does not establish the membership test's own cost (Claim 4).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r1+r2: "The bullet gives no count, so the miscount in claim 3a does not apply here." · r2: "Does not apportion the cost between forks and membership, which I did not micro-time." · r3: "does not establish the split between them, which is measured"

From r1: E3 measured floor at 6.6 ms, with two lower calls and four need_root calls taking about 4.4 ms of that (`$S1/bench2.out`, `$S1/count.out`). From r2, both functions fork: `lower() { printf '%s' "$1" | tr ...; }` (`scripts/lib/dev-cycle-read.sh:825`) and `[[ "$ROOT_REAL" == "$(pwd -P)" ]]` (`:162`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:160-164`, `scripts/lib/dev-cycle-read.sh:825`, `$S1/bench2.out`, `$S1/count.out`

---

## Claim 13b: U2c2 note: "(i1 performance: 6.4 ms per path, 400 paths 3.1 s against main's 0.3 s …)"

**Location:** `docs/working/plan-build-loop-handoff.md:312`
**Type:** Performance
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the order of magnitude of the four fork-bearing calls on r3's host. Does not reproduce the 3,000-file fixture or the end-to-end timing.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Unverifiable
**Replicate annotations:** r1: E5 measured "3.02–3.05 s on the branch against 0.33 s on main for 400 paths, about 6.4 ms per path" (`$S1/timing.out`) · r2: E7 measured `secs=3.124` / `secs=3.17` against `secs=0.349` / `secs=0.35`, "about 6.7 ms per path, close to the 6.4 ms quoted" (`$S2/timeprobe.out`)

From r3: "E6 found the same order of magnitude on this host (2.85 ms for the four fork-bearing calls). The end-to-end figures need the 3,000-file fixture." (`$S3/probe6.log`)

**Evidence:** `docs/working/plan-build-loop-handoff.md:312`, `$S3/probe6.log`, `$S1/timing.out`, `$S2/timeprobe.out`

---

## Claim 14: --help, "After an ok line, a K of N refusal or a checkout refusal, one line per path TREE changes against main"

**Location:** `scripts/build-loop.sh:155`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which verdict lines are followed by path lines. Does not establish the refuse list's text at :114-116, whose "it … could not be read again" is pre-existing and ambiguous between the branch and the brief.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate (compound with :179) · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r1: "The floor clause at `:179` should also name the re-read refusal" (merged Claim 16b) · r2: "--help lists this refusal only as 'it moved or could not be read again after --status read it' (`:115`)" · r2: "Does not cover skip lines or the merge's own refusals, which print no path lines (unchanged)."

From r1: the list leaves out C1's new refusal, `co` set to `refuse $a: the brief could not be read again from the default branch` (`scripts/build-loop.sh:817`). check_line then prints the path and deny lines (`$S1/run-c1.txt`). All three replicates propose the same fix: "an ok line, a K of N refusal, a checkout refusal or a brief re-read refusal".

**Evidence:** `scripts/build-loop.sh:113-116`, `scripts/build-loop.sh:155`, `scripts/build-loop.sh:812-837`, `$S1/run-c1.txt`, `$S2/run-reread.txt`

---

## Claim 15: --help N rules, "the dev cycle's own files (… anything under docs/working/briefs/ or docs/working/cycles/, or either as a file) and docs/constraints.md, or a path below one of those names"

**Location:** `scripts/build-loop.sh:167-172`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the regex arm and the parent-path loop over truthrule's cycle, settings and user words. Does not establish that truthrule's earlier words (instr, dot) never hide a covered ancestor.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: "none do today" (of the instr and dot words) · r3: "does not establish briefs/ as a file by test (only cycles/ is tested; the regex covers both)"

From r1: the regex arm is `^docs/working/(briefs|cycles)(/|$)` (`scripts/build-loop.sh:614`). The parent loop is `while [[ -z "$DENY" && "$d" == */* ]]; do d="${d%/*}"; truthrule "$d" || true; [[ ! "$TRUTH_WHY" =~ ^(cycle|settings|user)$ ]] || DENY=…` (`:616-619`). With the loop removed (M3), the row-523 test fails (`$S1/run-m3.txt`).

**Evidence:** `scripts/build-loop.sh:597-621`, `scripts/lib/dev-cycle-read.sh:1777-1787`, `$S1/run-m3.txt`

---

## Claim 16a: --help S rules, "for a brief --status reads as self-merge, on each path the N rules pass but the brief's own file (first match): the self-merge floor (… instruction and prompt files and what they import with @, dot paths, the gate's own code, the user's and the cycle's records, a working doc or review that is not the brief's own …)"

**Location:** `scripts/build-loop.sh:173-179`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the call condition, the first-match order and floor's categories. Does not establish floor's failure words beyond the readers line's mention of them.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified (compound with 16b) · r3=Verified (compound with 16b, 17)
**Replicate annotations:** r3: "does not cover floor's walk internals"

From r1: the call condition is `[[ -n "$DENY" || "$pol" != self-merge || "$p" == "$a" ]] || srules …` (`scripts/build-loop.sh:833`). The order is floor, the never loop, ownfile, then PATHS (`:661-669`). floor's arms are instr, dot, user, record, cycle, GATE_CODE, docs/thoughts/, docs/working/ and docs/reviews/ not own, and truthwalk (`scripts/lib/dev-cycle-read.sh:1832-1849`). T10 passes (`$S1/full-build-loop-check.txt`).

**Evidence:** `scripts/build-loop.sh:658-670`, `scripts/build-loop.sh:833`, `scripts/lib/dev-cycle-read.sh:1827-1850`, `test/scripts/build-loop-check.bats:1948-1965`, `$S1/full-build-loop-check.txt`

---

## Claim 16b: --help S rules, the floor is "not run over a checkout refused above"

**Location:** `scripts/build-loop.sh:179`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers when floor is skipped. Does not establish the refuse list's text at :114-116.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate (compound with :155) · r2=Verified (compound with 16a) · r3=Verified (compound with 16a, 17)
**Replicate annotations:** r2: "The floor is also skipped on a failed re-read, which --help does not mention here (claim 14 covers that line)."

From r1 (its claim 14 quotes this clause and says in Claims Requiring Attention "(`scripts/build-loop.sh:155`, also `:179`)"): floor is skipped for the brief re-read refusal as it is for a refused checkout (`srules … "$co"`, `:833`; `[[ -z "$5" ]] && floor`, `:661`), and E4 shows it (`$S1/run-c1.txt`). "The floor clause at `:179` should also name the re-read refusal."

**Evidence:** `scripts/build-loop.sh:179`, `scripts/build-loop.sh:661`, `scripts/build-loop.sh:817`, `scripts/build-loop.sh:833`, `$S1/run-c1.txt`

---

## Claim 17: --help never globs, "a glob of --settings' never line, compared lower-cased, * and ? within one part, matching the path or a directory above it"

**Location:** `scripts/build-loop.sh:179-181`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the regex built from every character globform admits (letters, digits, `. _ - / * ?`). Does not establish behaviour for a glob globform refuses, since read_settings turns self-merge off then.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified (compound with 16a, 16b)
**Replicate annotations:** none

From r1: never_res builds `case "$c" in '*') re+='[^/]*' ;; '?') re+='[^/]' ;; .) re+='\.' ;; *) re+="$c" ;; esac` and `NEVER_RES+=("^$re(/|\$)")` (`scripts/build-loop.sh:644-646`), after `g="$(lower "${g%/}")"`. srules matches it against `$3`, the lower-cased path (`:663`). T45 passes. P1 shows `docs/?.txt` denying `docs/a.txt` and passing `docs/ab.txt`, and shows `a-b_c.md` denying itself and passing `axb_c.md` (`$S1/run-p1.txt`).

**Evidence:** `scripts/build-loop.sh:633-647`, `scripts/build-loop.sh:662-664`, `test/scripts/build-loop-check.bats:1980-1991`, `$S1/run-p1.txt`

---

## Claim 18a: --help allowlist, "a path neither listed in the brief's first "Paths:" line nor one of its own files (docs/working/{research,plan,checkpoint,handoff,test-strategy}-STEM.md, an added docs/reviews/STEM.md or NAME-STEM.md; … though the floor passes any case)"

**Location:** `scripts/build-loop.sh:181-186`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the own-file patterns, "first" Paths: line, and floor lower-casing before ownfile. Does not establish the "only in lower case" atom (Claim 18b) or stems with upper case.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound with 18b) · r2=Verified (compound with 18b, 19) · r3=Verified
**Replicate annotations:** r1: "Does not establish stems with upper case (SLUG admits none)." · r2: "A failed re-read is outside this sentence (claim 14)."

From r3: the patterns match ownfile (`scripts/lib/dev-cycle-read.sh:1809-1810`). floor passes `ownfile "$lp" "$2" "$3"` on the lower-cased path (`:1843-1844`). In E1 test 3, `Docs/Working/Plan-2026-10-01-x.md` gets the Paths reason, not floor's WORK reason. From r1, "first" holds because brief_fields records only the first match: `if (!(k in got))` (`scripts/lib/dev-cycle-read.sh:398`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:386-409`, `scripts/lib/dev-cycle-read.sh:1806-1811`, `scripts/lib/dev-cycle-read.sh:1843-1844`, `$S3/bats-u2c1-base.out`

---

## Claim 18b: --help allowlist, "the allowlist takes these only in lower case"

**Location:** `scripts/build-loop.sh:185-186`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers NAME-STEM.md reviews. Does not dispute the lower-case rule for working docs and STEM.md reviews.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Verified (compound with 18a) · r2=Verified (compound with 18a, 19) · r3=Incorrect
**Replicate annotations:** r1+r2: the malformed-line test denies `Docs/Working/Plan-2026-10-01-x.md` and lands the lower-case copy (a working doc) · r3: escalation to security-reviewer (see Escalations)

From r3: the NAME part of `docs/reviews/NAME-STEM.md` matches in any case (`( "$b" == "$2.md" || "$b" == *"-$2.md" )`, `scripts/lib/dev-cycle-read.sh:1810`). In E7 the allowlist took `docs/reviews/Code-Review-2026-10-01-x.md` and `docs/reviews/CODE-2026-10-01-x.md` (`$S3/probe7.log`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1810`, `scripts/build-loop.sh:665`, `$S3/probe7.log`

---

## Claim 19: --help, ""Paths: P ..." lists paths pathform allows, with single spaces, each once, compared exactly (a trailing / makes a directory, matched at a part boundary; unlike a never glob, an entry without one matches that file alone); "Paths: none" or no line lists none; any other line is malformed, and only own files land."

**Location:** `scripts/build-loop.sh:186-191`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers list_entries' grammar and srules' match. Does not establish behaviour for a CR-ended line (brief_fields strips one CR first).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified (compound with 18a, 18b) · r3=Verified
**Replicate annotations:** r3: "does not cover a second Paths: line (brief_fields keeps the first)"

From r1: the match is `[[ "$2" != "$e" && ( "$e" != */ || "$2" != "$e"* ) ]] || return 0` (`scripts/build-loop.sh:668`). A bare `Paths:` fails `"$1" != "$2: "*` (`:369`). In T10, `docs/a` matches the file alone and `docs/ab.md` is denied. The malformed cases pass (`$S1/full-build-loop-check.txt`).

**Evidence:** `scripts/build-loop.sh:364-379`, `scripts/build-loop.sh:666-669`, `test/scripts/build-loop-check.bats:1948-1978`, `$S1/full-build-loop-check.txt`

---

## Claim 20: Exit:, "A --check can also stop part way, after the lines of the briefs before, with 1 (need_root) or a failed command's own status: a caller reads any exit but 0 as nothing decided."

**Location:** `scripts/build-loop.sh:199-204`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers need_root's exit inside check_line, run in the parent shell. Does not establish a test for the failed-command branch, which rests on `set -euo pipefail` and a plain call of check_line.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

From r1: M5 forces need_root to fail in brief y's floor. The run exits 1, prints only brief x's two lines, and writes `ROOT_REAL is not the current directory` to stderr (`$S1/run-m5.txt`). Brief y's partial lines went to `$GATE_TMP/line` (`check_line "$a" > "$GATE_TMP/line"; cat "$GATE_TMP/line"`, `:858`). r2's E5 and r3's E4 reproduce this with other ways of forcing the failure.

**Evidence:** `scripts/build-loop.sh:199-206`, `scripts/build-loop.sh:852-861`, `scripts/lib/dev-cycle-read.sh:160-164`, `$S1/run-m5.txt`, `$S2/run-exit.txt`, `$S3/probe4.log`

---

## Claim 21: list_entries contract, "LINE is exactly "KEY: none" or "KEY: E ..." with single spaces …, and each E, a trailing / dropped, passes FORM … and is listed once. Sets LIST … or LIST_WHY, and LIST_BAD to form … or entry …, or empty."

**Location:** `scripts/build-loop.sh:357-362`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the function body and both callers' use of LIST, LIST_WHY and LIST_BAD. Does not cover reader_settings' separate copy or lines with a CR.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "Does not cover lines with a CR, which brief_fields and main_file strip before this." · r3: "The comments on :368 and :371 also hold: tabs survive the split (IFS is a single space) and FORM refuses them; a bare `$v` would glob."

From r3: `if [[ "$1" != "$2: "* || ! "$v" =~ ^[^\ ]+(\ [^\ ]+)*$ ]]; then LIST_WHY=…; LIST_BAD=form; return 0; fi` … `[[ -z "$LIST_WHY" ]] || { LIST=(); LIST_BAD=entry; }` (`scripts/build-loop.sh:369-378`). The tests pass in E1 and E8.

**Evidence:** `scripts/build-loop.sh:357-379`, `$S3/bats-u2c1-base.out`, `$S3/bats-read.out`

---

## Claim 22: read_settings, "The form reason comes first, then the next line, then the entries." (never line, reasons and precedence unchanged)

**Location:** `scripts/build-loop.sh:419`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the order of reasons and NEVER/NEVER_LINE against main's elif chain. Does not cover --settings' other lines.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "Does not re-run i2's 44-case differential." · r2+r3: the reason strings are equal (`${3^^}` with WORD `glob` gives main's `"Self-merge never: GLOB ..."`)

From r1: `why="$LIST_WHY"`, then `if [[ "$LIST_BAD" != form && "${next[never]}" != 1 ]]; then why="is followed by …"` (`scripts/build-loop.sh:418-420`). build-loop-read passes 20/20 (`$S1/full-build-loop-read.txt`).

**Evidence:** `scripts/build-loop.sh:413-424`, `$S1/full-build-loop-read.txt`

---

## Claim 23a: nrules comment, "the cycle's files (truthrule's cycle and settings words: writable() and docs/dev-cycle.md, plus anything under docs/working/briefs/ or docs/working/cycles/) and the constraints doc"

**Location:** `scripts/build-loop.sh:590-592`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the comment against nrules' arms. Does not establish any behavioural gap (the code covers more than the comment says).
**Legibility-target:** for-author
**Replicate verdicts:** r1=— · r2=— · r3=Mostly accurate (compound with 23b) · single-replicate detection
**Replicate annotations:** none

From r3: the code also denies `docs/working/briefs` and `docs/working/cycles` as files (`^docs/working/(briefs|cycles)(/|$)`, `scripts/build-loop.sh:614`). --help says so ("or either as a file", `:170-171`), but this comment says only "anything under". r3's fix: "plus docs/working/briefs and docs/working/cycles and anything under them".

**Evidence:** `scripts/build-loop.sh:586-621`

---

## Claim 23b: nrules comment, "so does a path below one of those names (docs/roadmap.md/x, which main may lack, would keep the cycle from writing the file: row 523). srules adds the S rules."

**Location:** `scripts/build-loop.sh:593-595`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the comment against nrules' arms. Does not establish the consequence for the cycle.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Mostly accurate (compound with 23a)
**Replicate annotations:** r1+r2: the parent-path loop exists and the row-523 test passes; with the loop removed (r1's M3), it fails (`$S1/run-m3.txt`) · r3: the Mostly accurate verdict is about the briefs/cycles "as a file" omission (Claim 23a)

The verdict is r3's compound Mostly accurate, applied by most-severe-wins. The row-523 atom was Verified by execution (r1 M3, `scripts/build-loop.sh:616-619`).

**Evidence:** `scripts/build-loop.sh:586-621`, `$S1/run-m3.txt`

---

## Claim 24: nrules' parent loop covers every name the other arms cover (cycle, settings, user, briefs/, cycles/) and nothing else

**Location:** `scripts/build-loop.sh:614-617`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the loop's deny condition against the arms above it. Does not cover instr or dot words on a parent, which the loop ignores by design.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=— · r2=Verified · r3=— · single-replicate detection
**Replicate annotations:** none

From r2: the loop denies only when `[[ ! "$TRUTH_WHY" =~ ^(cycle|settings|user)$ ]]` fails (`:616`), the same three words as the case arms (`:611-612`). A path below briefs/ or cycles/ is caught by the `(/|$)` regex (`:613`). Since `d` is lowered, the case word cannot fire (`scripts/lib/dev-cycle-read.sh:1779`).

**Evidence:** `scripts/build-loop.sh:609-618`, `scripts/lib/dev-cycle-read.sh:1777-1787`

---

## Claim 25: read_paths, "from BRIEF[paths] … "Paths: none", or no line, lists none. Sets PATHS or, for a malformed line, PATHS_WHY (which lands only the brief's own files)."

**Location:** `scripts/build-loop.sh:622-625`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the function at `:627-632`. Does not establish the re-read failure branch, where check_line sets PATHS itself.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r3: "does not cover the own-files case rule (15b)" (merged Claim 18b)

From r1: `PATHS=(); PATHS_WHY=""`, then `[[ -n "${BRIEF[paths]+set}" ]] || return 0`, then `list_entries …; PATHS=("${LIST[@]}"); PATHS_WHY="$LIST_WHY"` (`scripts/build-loop.sh:628-631`).

**Evidence:** `scripts/build-loop.sh:622-632`

---

## Claim 26: never_res, "NEVER's globs as regexes for a lower-cased path …: * and ? match within one part, and a glob matches the path or any directory above it (a trailing / changes nothing). Set once, after read_settings."

**Location:** `scripts/build-loop.sh:633-635`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers never_res and its single call site. Does not establish that `--status` builds it (it does not, and does not need it).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r3: "does not cover a NEVER changed after the call (none is)"

From r1: the trailing `/` is dropped by `g="$(lower "${g%/}")"` (`:643`). The only call site is `read_settings; never_res` (`:850`). P1 and T45 pass.

**Evidence:** `scripts/build-loop.sh:636-647`, `scripts/build-loop.sh:850`, `$S1/run-p1.txt`

---

## Claim 27a: srules comment, "$5 the checkout refusal, if any … Sets DENY, first match winning: the floor (only when $5 is empty: it walks the checkout), a Self-merge never: glob, then the allowlist (Paths:, or ownfile)."

**Location:** `scripts/build-loop.sh:649-654`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what check_line passes as $5 and srules' first-match order. Does not cover the comment's lower-case conclusion (Claim 27b).
**Legibility-target:** for-author
**Replicate verdicts:** r1=Verified (compound with 27b) · r2=Mostly accurate · r3=Verified
**Replicate annotations:** r2: "The mechanism (floor skipped when $5 is set) is right." · r3: "Inside the allowlist, ownfile is tested before PATHS_WHY and Paths: entries, so own files land even when the line is malformed."

From r2: check_line passes `"$co"` (`scripts/build-loop.sh:833`). Since C1, co also holds the failed re-read refusal: `co="${co:-refuse $a: the brief could not be read again from the default branch}"` (`:817`). So $5 is "the checkout or re-read refusal".

**Evidence:** `scripts/build-loop.sh:649-661`, `scripts/build-loop.sh:817`, `scripts/build-loop.sh:833`

---

## Claim 27b: srules comment, "The allowlist widens nothing by case: Paths: entries compare exactly, and ownfile gets the path as spelled, so an own file passes only when the diff spells it in lower case (ownfile folds nothing)."

**Location:** `scripts/build-loop.sh:654-657`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the "passes only when … lower case" conclusion for NAME-STEM.md reviews. The mechanism atoms ("compare exactly", "as spelled", "folds nothing") are true.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Verified (compound with 27a) · r2=— · r3=Incorrect
**Replicate annotations:** r1: "ownfile's patterns are lower-case literals: `^docs/working/(research|plan|checkpoint|handoff|test-strategy)-(.+)\.md$`" · r2 (Scope of its claim 26): "The rest of the comment (first match, the allowlist's case rule) is Verified by claims 16-18." · r3: escalation to security-reviewer (see Escalations)

From r3: `! ownfile "$2" "$1" "$4" || return 0` passes the spelled path (`scripts/build-loop.sh:665`), but ownfile's `*"-$2.md"` (`scripts/lib/dev-cycle-read.sh:1810`) accepts any case in NAME. E7 landed `docs/reviews/Code-Review-2026-10-01-x.md` (`$S3/probe7.log`). The conclusion holds for working docs and STEM.md reviews only.

**Evidence:** `scripts/build-loop.sh:649-671`, `scripts/lib/dev-cycle-read.sh:1806-1811`, `$S3/probe7.log`

---

## Claim 28: deny text on a failed re-read, "the brief's Paths: line could not be read again, so only its own files land"

**Location:** `scripts/build-loop.sh:666`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the deny reason printed when PATHS_WHY is check_line's "could not be read again". Does not cover the malformed-line case, where the text is accurate.
**Legibility-target:** for-author
**Replicate verdicts:** r1=— · r2=Mostly accurate · r3=— · single-replicate detection
**Replicate annotations:** r2: "This fails closed. Only the wording of 'land' overstates what happens."

From r2: with `PATHS_WHY="could not be read again"` (`:817`), srules prints `DENY="the brief's Paths: line $PATHS_WHY, so only its own files land"` (`:666`). But the verdict is co's refusal (`:836`), so nothing lands. The reread run shows the refuse line above `deny ... A hooks/x.sh: the brief's Paths: line could not be read again, so only its own files land` (`$S2/run-reread.txt`).

**Evidence:** `scripts/build-loop.sh:666`, `scripts/build-loop.sh:813-818`, `scripts/build-loop.sh:836`, `$S2/run-reread.txt`

---

## Claim 29: checkout_gate comment, "check_line calls it for each self-merge brief once the merge and its changed paths are read, before the N rules and the floor walk run per path"

**Location:** `scripts/build-loop.sh:677-679`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the order of calls in check_line. Does not establish checkout_gate's internals.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=— · r3=— · single-replicate detection
**Replicate annotations:** none

From r1: checkout_gate runs at `:811` (`co=""; if [[ "$pol" == self-merge ]] && ! checkout_gate; then …`), before the per-path loop at `:831-835`.

**Evidence:** `scripts/build-loop.sh:811`, `scripts/build-loop.sh:831-835`

---

## Claim 30a: check_line comment, "It runs in the caller's shell, so an exit (need_root's) ends the run, and set -e applies to its own lines but not inside a helper called in a condition (floor and its walk, brief_fields, checkout_gate, nul_list) or in $(...), which refuse by their own guards."

**Location:** `scripts/build-loop.sh:761-764`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the call contexts of the four named helpers and bash's errexit rules without inherit_errexit. Does not establish that the named list is complete.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified (compound with 30b) · r3=Verified
**Replicate annotations:** r1: "srules, the last command after `||` at `:833`, does run under set -e" · r3: "does not establish that set -e cannot fire inside nrules, srules, read_paths or list_entries, which run outside conditions. Each line there was read and none fails on a normal path."

From r1: floor runs as `[[ -z "$5" ]] && floor …` inside `if` (`:661`), brief_fields as `if brief_fields "$a"` (`:817`), checkout_gate as `! checkout_gate` (`:811`), and nul_list as `if ! nul_list lps …` (`:829`). The scripts never enable inherit_errexit (paraphrased — no quote available because the claim is about absence: r1's and r3's greps found no match). M5 ran the exit path.

**Evidence:** `scripts/build-loop.sh:811`, `scripts/build-loop.sh:817`, `scripts/build-loop.sh:829`, `scripts/build-loop.sh:661`, `$S1/run-m5.txt`

---

## Claim 30b: check_line comment, "Nothing but its locals and the walk caches it resets may carry from one brief to the next: each helper empties its own globals before use (DENY, PATHS and PATHS_WHY, LIST and LIST_WHY, BRIEF, CHECKOUT_WHY, FLOOR_WHY, TRUTH_WHY)."

**Location:** `scripts/build-loop.sh:765-768`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the reset at the top of each named helper. Does not establish lib globals outside the list (FILE_OUT, SKIPPED and the like), which no replicate audited.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified (compound with 30a) · r3=Verified
**Replicate annotations:** r1+r2+r3: a review brief can leave the previous brief's PATHS (r3: "and BRIEF") behind, but srules never reads them for review (`"$pol" != self-merge`, `:833`) · r2: "Does not enumerate every lib global the walk writes beyond what import_reset clears." · r3: "does not cover walk globals that import_reset does not clear (recomputed after a reset)"

From r1: the resets are DENY (`:599`, `:660`), PATHS and PATHS_WHY (`:628`), LIST, LIST_WHY and LIST_BAD (`:367`), BRIEF (`scripts/lib/dev-cycle-read.sh:390`), FLOOR_WHY (lib `:1830`), TRUTH_WHY (lib `:1778`) and CHECKOUT_WHY (checkout_gate's first statement, `:694` per r2 and r3). The walk caches are reset by `import_reset` (`:773`).

**Evidence:** `scripts/build-loop.sh:367`, `scripts/build-loop.sh:599`, `scripts/build-loop.sh:628`, `scripts/build-loop.sh:660`, `scripts/build-loop.sh:773`, `scripts/build-loop.sh:833`, `scripts/lib/dev-cycle-read.sh:390`, `scripts/lib/dev-cycle-read.sh:1778`, `scripts/lib/dev-cycle-read.sh:1830`

---

## Claim 31: "# Contract item 1 (the floor's walk); exported, so its children run under it too." `local -x LC_ALL=C`

**Location:** `scripts/build-loop.sh:770-771`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the C.utf8 case the test exercises. Does not establish other locales.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

From r1: with the line removed (M2), `LC_ALL=C.utf8 chk` gives status 2 with `the default branch's instruction files could not be walked for @ imports` (`$S1/run-m2.txt`). r2's nolcall and r3's mutB runs agree.

**Evidence:** `scripts/build-loop.sh:769-773`, `test/scripts/build-loop-check.bats:2012-2015`, `$S1/run-m2.txt`, `$S2/run-nolcall.txt`, `$S3/bats-u2c1-mutB.out`

---

## Claim 32: "A failed read refuses the verdict as a checkout refusal does (path lines still print, the floor does not run)."

**Location:** `scripts/build-loop.sh:814-815`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the forced re-read failure. Does not establish which real conditions cause one.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: "only a transient git or awk failure" · r3: "does not cover a test of it"

From r1: E4 forces `if brief_fields "$a"` to `if false`. The output has `status=2`, the refuse line, a `path` line for the own plan doc, and a `deny` line carrying the Paths reason (`$S1/run-c1.txt`). The floor does not run because `co` is non-empty (`:661`).

**Evidence:** `scripts/build-loop.sh:812-819`, `scripts/build-loop.sh:661`, `$S1/run-c1.txt`, `$S2/run-reread.txt`

---

## Claim 33: "In this shell, not $(...): the floor's need_root exit ends the run, and check_line's import_reset is what keeps one brief's walk from the next."

**Location:** `scripts/build-loop.sh:856-857`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the M1 and M5 runs. Does not establish anything about --status, which has no walk, or other caches.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

From r1: M1 removes import_reset, and two self-merge briefs then list the worktrees once instead of twice (`$S1/run-m1.txt`). M5 shows the exit.

**Evidence:** `scripts/build-loop.sh:855-860`, `$S1/run-m1.txt`, `$S1/run-m5.txt`

---

## Claim 34: "open_shared  # once, in this shell: status_line runs in a subshell"

**Location:** `scripts/build-loop.sh:851`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers where status_line runs. Does not establish open_shared's own contents.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=— · r3=Verified
**Replicate annotations:** r3: `[[ -z "$OPEN_SHARED" ]] || return 0` (`scripts/lib/dev-cycle-read.sh:501`) makes it compute once per process, and the subshell call hits the parent's cached value

From r1: check_line runs `out="$(status_line "$a")"` (`:774`), a subshell, and status_line calls `open_shared` (`:487`).

**Evidence:** `scripts/build-loop.sh:485-488`, `scripts/build-loop.sh:774`, `scripts/build-loop.sh:851`, `scripts/lib/dev-cycle-read.sh:497-513`

---

## Claim 35: lib header item 3, "(U2b2; its check_line runs the walk under item 1's LC_ALL=C)"

**Location:** `scripts/lib/dev-cycle-read.sh:63`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `local -x LC_ALL=C` in check_line. Does not establish other callers of the walk, or the rest of item 3, which is unchanged.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: checkout_gate runs before the per-path loop (`scripts/build-loop.sh:811`, `:831-835`)

From r1: the line is `local -x LC_ALL=C` (`scripts/build-loop.sh:771`), and M2 shows the test depends on it.

**Evidence:** `scripts/build-loop.sh:771`, `$S1/run-m2.txt`

---

## Claim 36: lib header item 5, "build-loop.sh reads diff-tree -r of main and the merge instead, where a symlink or gitlink above a path is a changed entry of its own. … its S rules run floor only on a path they pass"

**Location:** `scripts/lib/dev-cycle-read.sh:76-86`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a directory replaced by a symlink and by a gitlink. Does not cover a gitlink introduced with no prior directory.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r3: the gitlink variant was not run by them (r1: "same tree rule: one name cannot be both a tree and a link"; r3: "diff-tree -r does not descend into a gitlink, which shows as a 160000 entry") · r2: a gitlink introduced with no prior directory "is still its own 160000 entry by the same diff-tree rule"

From r2, the most specific Scope (the only replicate to run both symlink and gitlink): E3 shows `deny ... A lnk: a symlink, gitlink or other non-file entry` with `path ... D lnk/f`, and `deny ... A sub: ...` with `path ... D sub/f` (`$S2/run-probe3.txt`). Floor runs only after the N rules pass (`scripts/build-loop.sh:833`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:76-86`, `scripts/build-loop.sh:791-800`, `scripts/build-loop.sh:833`, `$S2/run-probe3.txt`, `$S1/difftree.txt`, `$S3/probe5.log`

---

## Claim 37: lib header item 8, "Pass truthrule, isstart, ownfile, prompt_dir and prompt_bases a lower-cased path"

**Location:** `scripts/lib/dev-cycle-read.sh:90-93`
**Type:** Invariant
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers ownfile's entry in item 8. Does not cover truthrule, isstart, prompt_dir or prompt_bases, which this branch's callers pass lowered.
**Legibility-target:** for-author
**Replicate verdicts:** r1=— · r2=Stale · r3=Stale
**Replicate annotations:** none

From r2: item 8 was last edited 2026-10-08 (`git blame` 2f9464d34 and 185e92f18). The branch's B1 fix made srules pass ownfile the path as spelled: `! ownfile "$2" "$1" "$4" || return 0` (`scripts/build-loop.sh:665`). ownfile's comment was updated to match ("for a path $1 (it folds no case: floor passes it lower-cased, build-loop.sh srules as spelled)", `scripts/lib/dev-cycle-read.sh:1800-1801`). The fix: drop ownfile from item 8's list, or note that srules passes the path as spelled.

**Evidence:** `scripts/lib/dev-cycle-read.sh:90-93`, `scripts/lib/dev-cycle-read.sh:1799-1811`, `scripts/build-loop.sh:665`

---

## Claim 38: ownfile, "for a path $1 (it folds no case: floor passes it lower-cased, build-loop.sh srules as spelled)"

**Location:** `scripts/lib/dev-cycle-read.sh:1800-1801`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers ownfile's body and both callers. Does not establish callers outside scripts/.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r3: "does not cover the case of NAME (see Claim 25)" (merged Claim 27b)

From r1: ownfile has no `lower` call (`:1806-1811`). The callers are floor, `ownfile "$lp" "$2" "$3"` (`:1843-1844`), and srules, `ownfile "$2" "$1" "$4"` (`scripts/build-loop.sh:665`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1806-1811`, `scripts/lib/dev-cycle-read.sh:1843-1844`, `scripts/build-loop.sh:665`

---

## Claim 39: "FLOOR_WHY=""  # read by floor's caller (build-loop.sh srules)"

**Location:** `scripts/lib/dev-cycle-read.sh:1825`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the reader in build-loop.sh. Does not establish readers in test code.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r3: "the test harness also prints it"

From r1: srules reads it, `DENY="$FLOOR_WHY"` (`scripts/build-loop.sh:661`).

**Evidence:** `scripts/build-loop.sh:661`

---

## Claim 40: test title "--check self-merges listed paths (exec bit, a directory entry), the brief's own working docs and added reviews, and its Status line (T9, U2c1)"

**Location:** `test/scripts/build-loop-check.bats:1938`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each part of the title against the test's assertions. Does not establish coverage of handoff- or test-strategy- docs.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r3: "does not cover a modified review (correctly not an own file)"

From r1: `chmod +x scripts/other.sh`, directory entries `skills/x/` and `test/`, research, plan and checkpoint docs, two added reviews, `has "path $B M $B"`, and 13 lines in all. The test passes (`$S1/full-build-loop-check.txt`).

**Evidence:** `test/scripts/build-loop-check.bats:1938-1946`, `$S1/full-build-loop-check.txt`

---

## Claim 41: test title "--check refuses a self-merge path the floor names though Paths: lists it, a symlink at a listed path, and a path Paths: does not list exactly (T10, rows 349, 474, U2c1)"

**Location:** `test/scripts/build-loop-check.bats:1948`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the asserted deny lines. Does not establish a gitlink case (row 474 is named, but only the symlink is asserted).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "E3 covers it" (the gitlink half, by probe)

From r1: the first 11 floor paths are listed, the listed symlink is denied by mode (`deny $B A scripts/link.sh: $NMODE`), and `docs/ab.md`, `Hooks/x.sh` and `scripts/x.sh` are denied as unlisted. `nref 17 18`. The test passes.

**Evidence:** `test/scripts/build-loop-check.bats:1948-1965`, `$S1/full-build-loop-check.txt`

---

## Claim 42: test title "--check: a malformed Paths: line lands only the brief's own files, spelled in lower case; Paths: none or no line lists nothing (T10, U2c1 i1)"

**Location:** `test/scripts/build-loop-check.bats:1967`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the assertions (a lower-case working doc lands, an upper-case one is denied, docs/a is denied). Does not establish "own files … spelled in lower case" for added NAME-STEM.md reviews, which this test does not exercise and which land in any case.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Mostly accurate
**Replicate annotations:** r1: "Does not establish a malformed line with an upper-case own file under a valid line." · r2: "Does not cover added reviews."

From r3: the assertions match the title for the working-doc pattern (`has "path $B A docs/working/plan-2026-10-01-x.md"`, the denied `Docs/Working/Plan-…`, `:1976-1977`). The title states the case rule for own files generally, and the code does not hold it for NAME-STEM.md (`$S3/probe7.log`).

**Evidence:** `test/scripts/build-loop-check.bats:1967-1978`, `$S3/bats-u2c1-base.out`, `$S3/probe7.log`

---

## Claim 43: test title "--check: a Self-merge never: glob refuses a listed path under self-merge, by part and in any case; review ignores it (T45, U2c1)"

**Location:** `test/scripts/build-loop-check.bats:1980`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the asserted lines. Does not establish `?` globs, which r1's P1 covers.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

From r1: `Workflows/Z.md` is denied (any case). `docs/sub/n.txt` and `workflowsx.md` pass (by part). Under review, status is 0 and 7 lines print. The test passes.

**Evidence:** `test/scripts/build-loop-check.bats:1980-1991`, `$S1/full-build-loop-check.txt`

---

## Claim 44: test title "--check refuses a path below a cycle file's or the constraints doc's name, and cycles/ as a file (an N rule; row 523, U2c1)"

**Location:** `test/scripts/build-loop-check.bats:1993`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four parent-name cases and `docs/working/cycles` as a file. Does not establish `briefs` as a file.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2+r3: the test uses a review brief (`gated`), so it exercises an N rule

From r1: the test passes, and fails with the loop removed (M3, `$S1/run-m3.txt`).

**Evidence:** `test/scripts/build-loop-check.bats:1993-2002`, `$S1/run-m3.txt`

---

## Claim 45: test title "--check walks once per self-merge decision (check_line's import_reset, in the parent shell) and under the C locale (contract items 1, 4; row 532, U2c1)"

**Location:** `test/scripts/build-loop-check.bats:2004`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the worktree-listing count and the C.utf8 case. Does not establish that every walk entry is counted; only `worktree list` calls are.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "Does not cover more than two briefs." · r1+r3: C.utf8 is installed, so the locale case is not vacuous

From r1: M1 (no import_reset) fails the count with 1 (`$S1/run-m1.txt`). M2 (no LC_ALL=C) fails the C.utf8 part (`$S1/run-m2.txt`).

**Evidence:** `test/scripts/build-loop-check.bats:2004-2016`, `$S1/run-m1.txt`, `$S1/run-m2.txt`

---

## Claim 46: commit eddfd5f9, ""Paths:" alone or no line lists none"

**Location:** commit `eddfd5f9` message
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the claim against HEAD. Does not establish anything about eddfd5f9's own code, where it held.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Stale · r2=Stale · r3=Stale
**Replicate annotations:** r1: "The outcome is the same (only own files land), but the reason differs. The commit is immutable, so this needs an Accepted-immutable override row, or a note in the merge message." · r2: "d435100e's message records the change" ("bare "Paths:" is now malformed")

From r1, chosen by the Scope and lowest-number tie-break: d435100e made bare `Paths:` malformed, `[[ "$1" != "$2: "* || …` → `LIST_BAD=form` (`scripts/build-loop.sh:369`). The malformed-line test asserts `"Paths:|is not exactly \"Paths: PATH ...\" with single spaces"` (`test/scripts/build-loop-check.bats:1970`).

**Evidence:** `scripts/build-loop.sh:369`, `test/scripts/build-loop-check.bats:1968-1971`

---

## Claim 47: commit eddfd5f9, "Tests: build-loop-check 138, build-loop-read 20, dev-cycle 79, fixture-git-env 2, fixture-hermeticity 2. 229 changed code lines."

**Location:** commit `eddfd5f9` message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the counts at HEAD and eddfd5f9's numstat. Does not establish that the dev-cycle and fixture suites passed at eddfd5f9.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2+r3: dev-cycle and fixture counts "not counted or run" (r1 counted them with `bats --count`: 79, 2, 2) · r1+r3: checked against the hallucination log's suite-count pattern, and every figure holds

From r1: `bats --count` gives 138, 20, 79, 2 and 2 (`$S1/counts.txt`). `git diff --numstat` for eddfd5f9 against main gives 105/15, 12/9 and 87/1, a sum of 229.

**Evidence:** `test/scripts/build-loop-check.bats:1938-2016`, `$S1/counts.txt`, `$S1/full-summary.txt`

---

## Claim 48: commit eddfd5f9, "Timing on a 3,284-file clone: 3.6 s for 1 path, 6.1 s for 150, 7.6 s for 400."

**Location:** commit `eddfd5f9` message
**Type:** Performance
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers nothing about that clone. A 3,000-file fixture gives different absolute numbers because its walk is smaller.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Unverifiable · r2=Unverifiable · r3=Unverifiable
**Replicate annotations:** r1+r2: already Accepted (rubric B11) · r2: E7's fixture "shows the same shape (about +2.7 s from 1 to 400 paths) but not these totals"

From r1: the named clone and briefs are not in the repo (paraphrased — no quote available because the claim concerns a measurement environment absent from the repository). E5's fixture gives 0.47/1.42/3.03 s.

**Evidence:** `scripts/build-loop.sh:849-862`, `$S1/timing.out`

---

## Claim 49: commit eddfd5f9, "check_line now runs in the parent shell under LC_ALL=C (contract item 1), so the floor's need_root exit ends the run and import_reset is observable … nrules also refuses a path below a cycle file's or the constraints doc's name, and docs/working/{briefs,cycles} as a file (row 523)."

**Location:** commit `eddfd5f9` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each atom against Claims 15, 31 and 33. Does not establish anything beyond those.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=— · r2=— · r3=Verified · single-replicate detection
**Replicate annotations:** none

From r3: paraphrased — no quote available because each atom is quoted in r3's claims 13, 28 and 30 (`scripts/build-loop.sh:614-618`, `:771`, `:858`) and executed by r3's E1-E4.

**Evidence:** `scripts/build-loop.sh:614-618`, `scripts/build-loop.sh:771`, `scripts/build-loop.sh:858`

---

## Claim 50: commit d435100e, "B1: ownfile gets the path as spelled, so an own file lands only in lower case."

**Location:** commit `d435100e` message
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** As Claim 27b. Commit messages are immutable, so this is for the record.
**Legibility-target:** for-author
**Replicate verdicts:** r1=— · r2=— · r3=Incorrect · single-replicate detection
**Replicate annotations:** none

From r3: the same defect as Claim 27b. E7 landed `docs/reviews/Code-Review-2026-10-01-x.md` (`*"-$2.md"`, `scripts/lib/dev-cycle-read.sh:1810`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1810`, `$S3/probe7.log`

---

## Claim 51: commit d435100e, "Making bare "Paths:" malformed changes no outcome (both land only own files)"

**Location:** commit `d435100e` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the landing outcome. The deny reason text differs (malformed against NLIST), which the commit does not deny.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=— · r2=— · r3=Verified · single-replicate detection
**Replicate annotations:** none

From r3: bare `Paths:` fails `"$1" != "$2: "*` (`scripts/build-loop.sh:369`). With PATHS_WHY set, srules lands only ownfile matches, as an empty PATHS would. E1 test 3 covers `Paths:`.

**Evidence:** `scripts/build-loop.sh:369`, `scripts/build-loop.sh:665-670`, `$S3/bats-u2c1-base.out`

---

## Claim 52: commit d435100e, "B5: a failed brief re-read lands only own files, every path line printed."

**Location:** commit `d435100e` message
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the behaviour at 9e7c61c5. The message is immutable and was superseded by 9e7c61c5's C1.
**Legibility-target:** for-author
**Replicate verdicts:** r1=— · r2=Stale · r3=— · single-replicate detection
**Replicate annotations:** none

From r2: see Claim 6. At HEAD the verdict is refused (`scripts/build-loop.sh:817`, `$S2/run-reread.txt`).

**Evidence:** `scripts/build-loop.sh:817`, `$S2/run-reread.txt`

---

## Claim 53: commit 9e7c61c5, "C1: a failed brief re-read refuses the verdict (path lines still print). C2: list_entries sets LIST_BAD, so read_settings no longer reads its wording. C3: ownfile's comment: it folds no case."

**Location:** commit `9e7c61c5` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers C1 to C3 against the code. Does not establish C4 and C5 beyond the claims on --help text, check_line's comment and list_entries.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: verdicted C1 only, with "the rest of the message (C2–C5)" covered by its other claims

From r2: C1 is shown by `$S2/run-reread.txt`. C2: `if [[ "$LIST_BAD" != form && ...` (`scripts/build-loop.sh:420`). C3: `scripts/lib/dev-cycle-read.sh:1800-1801`.

**Evidence:** `scripts/build-loop.sh:420`, `scripts/build-loop.sh:817`, `scripts/lib/dev-cycle-read.sh:1800-1801`, `$S2/run-reread.txt`

---

## Claim 54: commit 62877331, "fact-check 0 Incorrect, 1 Stale, 1 Mostly accurate"

**Location:** commit `62877331` message
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** The i1 fact-check report is an artifact outside this pass's scope and was not read.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=— · r2=— · r3=Unverifiable · single-replicate detection
**Replicate annotations:** none

From r3: paraphrased — no quote available because the claim concerns a review artifact this brief puts out of scope.

**Evidence:** `docs/reviews/override-log.md:608-617`

---

## Escalations

1. **`docs/reviews/override-log.md:610`** (r1). Addressee: orchestrator. The override row's need_root count is wrong (4, not 2) and needs a correcting new row. U2c2's "one root check per decision" should cover all four calls (Claim 3a).
2. **`docs/reviews/override-log.md:613`** (r1 Escalate; r2 "Amend the row in a new row"). Addressee: orchestrator. The row has been stale since C1 and needs a new override row (Claim 6).
3. **`scripts/build-loop.sh:155`**, also `:179` (r1). Addressee: orchestrator. A one-line --help fix: name the brief re-read refusal (Claims 14, 16b).
4. **commit `eddfd5f9` message** (r1). Addressee: orchestrator. The stale bare-`Paths:` clause needs an Accepted-immutable override row or a note in the merge message (Claim 46).
5. **`scripts/lib/dev-cycle-read.sh:1810`**, which bears on `docs/working/plan-build-loop-handoff.md:311`, `scripts/build-loop.sh:185-186` and `scripts/build-loop.sh:654-657` (r3). Addressee: security-reviewer. An added `docs/reviews/NAME-STEM.md` matches NAME in any case, so on a case-insensitive checkout it can take an existing review's name. r3: "does not establish whether a case-colliding added review is a security problem (that is the security critic's call)" (Claims 2, 12b, 18b, 27b, 50).

## Verdict stability

- Total clusters: 63 (54 claim positions; 9 positions split into sub-claims because at least one replicate split them or because a compound in one replicate met atomic claims in another).
- Clusters where all reporting replicates agreed: 50. Of these, 9 are single-replicate clusters (Claims 23a, 24, 28, 29, 49, 50, 51, 52, 54), so 41 of the 54 multi-replicate clusters agreed.
- Clusters where verdicts disagreed: 13.
  - Claim 3a: r1=Incorrect (compound) · r2=Mostly accurate (compound) · r3=Verified
  - Claim 3b: r1=Incorrect (compound) · r2=Mostly accurate (compound) · r3=Unverifiable (compound)
  - Claim 3c: r1=Verified · r2=Mostly accurate (compound) · r3=Unverifiable (compound)
  - Claim 5: r1=Verified · r2=Mostly accurate · r3=Verified
  - Claim 6: r1=Stale · r2=Stale · r3=Verified
  - Claim 12b: r1=Verified (compound) · r2=Verified (compound) · r3=Incorrect
  - Claim 13b: r1=Verified (compound) · r2=Verified (compound) · r3=Unverifiable
  - Claim 16b: r1=Mostly accurate (compound) · r2=Verified (compound) · r3=Verified (compound)
  - Claim 18b: r1=Verified (compound) · r2=Verified (compound) · r3=Incorrect
  - Claim 23b: r1=Verified · r2=Verified · r3=Mostly accurate (compound)
  - Claim 27a: r1=Verified (compound) · r2=Mostly accurate · r3=Verified
  - Claim 27b: r1=Verified (compound) · r2=— · r3=Incorrect
  - Claim 42: r1=Verified · r2=Verified · r3=Mostly accurate
- Agreement rate: 50/63 = 79.4% over all clusters, or 41/54 = 75.9% over multi-replicate clusters. Both are below the 90% falsifier, so k stays at 3.
- Single-replicate detections: 9. These include two non-Verified findings found by one replicate only (r3's Claim 50 Incorrect and Claim 23a Mostly accurate; r2's Claim 28 Mostly accurate and Claim 52 Stale). Each replicate also left out claims the other two caught: r3 did not verdict row 614, r2 did not verdict open_shared, and r1 did not verdict lib item 8.
- Merge decisions: a compound verdict is applied to every sub-claim row it covers, marked `(compound)`. This is why Claims 3c and 23b are Mostly accurate although the winning replicate's text locates its defect in a sibling sub-claim. Both rows say so in their annotations.
