# Code Fact-Check Report

**Commit:** 9e7c61c5
**Repository:** /workspace/.claude/wt-build-loop-u2c1 (branch `feat/build-loop-u2c1`)
**Replication:** final confirming pass, replicate r2 of k=3
**Scope:** the whole branch, `git diff main...HEAD` at 9e7c61c5: scripts/build-loop.sh, scripts/lib/dev-cycle-read.sh, test/scripts/build-loop-check.bats, docs/working/plan-build-loop-handoff.md (:238, :310-312), the override rows dated 2026-10-10 for `feat/build-loop-u2c1` (docs/reviews/override-log.md:608-617), and the five branch commit messages. Review reports under docs/reviews/ are artifacts, not claims under review. Unchanged comments in the changed files were checked where the branch's code changes their subject (lib header item 8).
**Checked:** 2026-10-10
**Total claims checked:** 47
**Summary:** 36 verified, 5 mostly accurate, 4 stale, 0 incorrect, 2 unverifiable

## Execution logs

Scratch dir `S=/tmp/claude-1000/-workspace/54247aa5-2a95-449b-b931-3ed456da322c/scratchpad/u2c1-final-fc-r2`. Every probe script starts `set -eu`, creates its own `mktemp -d /tmp/u2c1-fcr2-XXXX` dir, cds into it, refuses to go on unless `pwd -P` is under it, and removes it at the end. No git write command ran in /workspace or the review worktree. Mutants and probe tests ran in `git archive 9e7c61c5` copies.

- **E1 suites.** `$S/suites.sh` ran in the worktree (`bats test/scripts/build-loop-check.bats`, then `bats test/scripts/build-loop-read.bats`, serially, with `LC_ALL=C TMPDIR=<own mktemp dir>`). It started 2026-10-10T10:45:26Z and both suites exited 0 (`$S/suites.exits`). Results: 138/138 ok (`$S/run-check-full.txt`) and 20/20 ok (`$S/run-read.txt`).
- **E2 probes.** `$S/probes2.sh` (cwd `$S`, 2026-10-10T10:46:13Z) ran FCPROBE 1 and 2 from `$S/probe-tests.bats.part`. They print their output and then fail on purpose so bats shows it, so rc=1 is expected. Output: `$S/run-probes2.txt`.
- **E3 diff-tree probe.** `$S/probe3.sh` (2026-10-10T10:46:27Z) ran FCPROBE 3 from `$S/probe3.bats.part`. It fails on purpose (rc=1). Output: `$S/run-probe3.txt`.
- **E4 mutants.** `$S/probes.sh` (2026-10-10T10:45:55Z to 10:45:59Z; exits in `$S/probes.exits`) built three mutants, with diffstats in `$S/mut-*.diffstat`:
  - `reread`: check_line's `if brief_fields "$a"; then read_paths;` became `if false; then read_paths;`. Running the T9 test exited 1. Output: `$S/run-reread.txt`.
  - `nolcall`: check_line's `local -x LC_ALL=C` was removed. Running the walk test exited 1. Output: `$S/run-nolcall.txt`.
  - `noreset`: check_line's `import_reset` was removed. Running the walk test exited 1. Output: `$S/run-noreset.txt`.
- **E5 exit probe.** `$S/probe-exit.sh` (2026-10-10T10:49:50Z) built a mutant whose srules sets `ROOT_REAL=/nonexistent-fcr2` for brief y (`$S/mut-exit.grep`), then ran FCPROBE E (`$S/probe-exit.bats.part`), which fails on purpose. Output: `$S/run-exit.txt`.
- **E6 count probe.** `$S/countprobe.sh` (cwd `$S`, 2026-10-10T10:47:46Z, exit 0; `$S/countprobe.ts`) counts need_root and lower runs per floor call after a warm-up walk. Output: `$S/countprobe.out`.
- **E7 timing.** `$S/timeprobe.sh` (cwd `$S`, 2026-10-10T10:48:11Z, exit 0; `$S/timeprobe.ts`) times `--check` with main's build-loop.sh against 9e7c61c5's, on a 3,000-file fixture with a self-merge brief, for 1 and 400 changed paths, two samples each. Output: `$S/timeprobe.out`.

I read the hallucination pattern log (docs/reviews/hallucination-patterns.md). No claim here matches a logged pattern. The nearest class is commit-message suite counts, and claim 44's counts match the suites as run.

---

## Claim 1: row 608, a directory at an instruction-file name or import target lands; "the floor tests the whole path only"

**Location:** `docs/reviews/override-log.md:608`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the claim that floor's instruction test reads only the last part and its import test reads only the whole lowered path. Does not establish the row's availability-only reasoning, and it does not re-run i1 security's probe.

isstart reads the last part only: `isstart() { [[ "${1##*/}" =~ $INSTRUCTION_FILE ]] || ...` (`scripts/lib/dev-cycle-read.sh:663`). So `src/claude.md/n.txt` is tested as `n.txt`. The import test compares the whole lowered path with the walk list: `main) main_imports || return 0; [[ "$IMPORTED_MAIN" == *$'\n'"$lp"$'\n'* ]] ;;` (`scripts/lib/dev-cycle-read.sh:1760`). Neither test looks at a directory above the path.

**Evidence:** `scripts/lib/dev-cycle-read.sh:663`, `scripts/lib/dev-cycle-read.sh:1754-1763`, `scripts/lib/dev-cycle-read.sh:1828-1850`

---

## Claim 2: row 609, an added review named NAME-STEM.md can take a sibling brief's STEM.md name

**Location:** `docs/reviews/override-log.md:609`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers ownfile's suffix match and the claim that briefs/ is N-denied. Does not judge the Won't-Fix reasoning.

ownfile accepts any added top-level review that ends in `-STEM.md`: `[[ "$3" == A && "$1" == docs/reviews/* && "$b" != */* && ( "$b" == "$2.md" || "$b" == *"-$2.md" ) ]]` (`scripts/lib/dev-cycle-read.sh:1810`). So `docs/reviews/2026-10-02-y-2026-10-01-x.md` matches stem `2026-10-01-x`. briefs/ is N-denied: `*) [[ ! "$7" =~ ^docs/working/(briefs|cycles)(/|$) ]] || DENY="one of the dev cycle's own files" ;;` (`scripts/build-loop.sh:613`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1806-1811`, `scripts/build-loop.sh:609-614`

---

## Claim 3: row 610, "floor forks twice per path to lower-case it and runs need_root twice, ~5.7 ms of the S rules' ~6.4 ms per path; 400 paths take 3.1 s against main's 0.3 s"

**Location:** `docs/reviews/override-log.md:610`
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the number of lower and need_root runs per floor call and the totals for 400 paths on a 3,000-file fixture. Does not re-measure floor's 5.7 ms in isolation.

Two parts hold. floor lowers the path twice: once in floor (`lp="$(lower "$1")"`, `scripts/lib/dev-cycle-read.sh:1831`) and once in isimported (`lp="$(lower "$2")" || return 0`, `scripts/lib/dev-cycle-read.sh:1757`). The totals also reproduce. E7 (`$S/timeprobe.out`) measured 400 paths at `secs=3.124` and `secs=3.17` on the branch against `secs=0.349` and `secs=0.35` on main. That is about 6.7 ms per path on the branch against 0.24 ms on main.

The need_root count is wrong: it runs four times per path, not twice. E6 (`$S/countprobe.out`) prints `docs/b.md need_root runs: 4, lower runs: 2`. The four calls are floor's own (`need_root`, `:1829`), main_imports' through truthwalk (`need_root`, `:1630`), isimported's (`:1756`), and main_imports' again when isimported calls it (`:1630`). The precise version: "lowers twice and runs need_root four times (each `$(pwd -P)` forks)".

**Evidence:** `scripts/lib/dev-cycle-read.sh:1626-1632`, `scripts/lib/dev-cycle-read.sh:1754-1763`, `scripts/lib/dev-cycle-read.sh:1794-1797`, `scripts/lib/dev-cycle-read.sh:1827-1832`, `$S/countprobe.out`, `$S/timeprobe.out`

---

## Claim 4: row 611, "the glob test is 0.12 ms per path on a 28 KB walk list, 43 ms only near IMPORT_OUT_MAX"

**Location:** `docs/reviews/override-log.md:611`
**Type:** Performance
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that the numbers trace to i1 performance's measurement. Does not establish the timings themselves, which I did not re-run.

The row quotes i1 performance: "Membership itself costs 118 µs" and "43 ms per path at 6 MB" (`docs/reviews/performance-review-2026-10-10-u2c1.md:53`, `:72`). Verifying it needs a micro-benchmark of isimported's membership glob over a 28 KB and a 6 MB list. That is a timing run, which this pass did not repeat.

**Evidence:** `docs/reviews/performance-review-2026-10-10-u2c1.md:53`, `docs/reviews/performance-review-2026-10-10-u2c1.md:72`, `scripts/lib/dev-cycle-read.sh:1760`

---

## Claim 5: row 612, "A malformed Paths: line shows only as the same reason on every non-own deny line, while --status still prints POLICY self-merge" / reason "the verdict still refuses"

**Location:** `docs/reviews/override-log.md:612`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers where the malformed-Paths reason appears and the verdict when only own files change. Does not judge the deferral.

Two parts hold. The malformed reason appears only on deny lines (`DENY="the brief's Paths: line $PATHS_WHY, so only its own files land"`, `scripts/build-loop.sh:666`). status_line's policy ignores Paths: (`[[ "$POLICY" == self-merge && "${BRIEF[policy]-}" == "Policy: self-merge" ]] && pol=self-merge`, `scripts/build-loop.sh:503`).

Both quantifiers are too broad:
- **Not every non-own deny line carries the reason.** The floor and never globs run first (`scripts/build-loop.sh:661-664`). In E2's FCPROBE 2 (`$S/run-probes2.txt`), `deny ... A docs/thoughts/t.md: a record later runs read as truth` carries the floor's reason while `docs/b.md` carries the Paths reason.
- **The verdict does not always refuse.** When only own files change, it is ok and the malformed line shows nowhere. FCPROBE 1 prints `status=0` and `ok docs/working/briefs/2026-10-01-x.md ...` for a brief with `Paths:  docs/a` and one own plan file.

The precise version: "on each non-own path the floor and never globs pass; a branch changing only own files merges with no sign of it".

**Evidence:** `scripts/build-loop.sh:503`, `scripts/build-loop.sh:658-670`, `$S/run-probes2.txt`, `$S/probe-tests.bats.part`

---

## Claim 6: row 613, "The concrete slip (a failed re-read printed no path line) is fixed: it now lands only own files with every line printed."

**Location:** `docs/reviews/override-log.md:613`
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the outcome of a failed brief re-read at 9e7c61c5. Does not judge the deferral of the verdict chain.

The row described d435100e. Since 9e7c61c5's C1, a failed re-read refuses the verdict: `else PATHS=(); PATHS_WHY="could not be read again"; co="${co:-refuse $a: the brief could not be read again from the default branch}"; fi` (`scripts/build-loop.sh:817`). The verdict line then prints `co`: `if [[ -n "$co" ]]; then echo "$co"; ...` (`scripts/build-loop.sh:836`). Nothing lands, own files included.

The E4 `reread` mutant (`$S/run-reread.txt`) shows `refuse docs/working/briefs/2026-10-01-x.md: the brief could not be read again from the default branch`, with the path and deny lines following. "Every line printed" still holds. "Lands only own files" no longer does: it refuses the verdict, and own files print as path lines.

**Evidence:** `scripts/build-loop.sh:813-818`, `scripts/build-loop.sh:836-837`, `$S/run-reread.txt`

---

## Claim 7: row 614, "The lib's caller contract item 5 and FLOOR_WHY's comment name build-loop.sh's nrules and srules"

**Location:** `docs/reviews/override-log.md:614`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that both comments name build-loop.sh's rules. Does not judge the Won't-Fix.

Item 5 reads `build-loop.sh's N rules apply them, and pathform, under both policies, and its S rules run floor only on a path they pass` (`scripts/lib/dev-cycle-read.sh:83-84`). FLOOR_WHY's comment reads `FLOOR_WHY=""  # read by floor's caller (build-loop.sh srules)` (`scripts/lib/dev-cycle-read.sh:1825`). Item 5 names the rules ("N rules", "S rules") rather than the function names.

**Evidence:** `scripts/lib/dev-cycle-read.sh:76-86`, `scripts/lib/dev-cycle-read.sh:1825`

---

## Claim 8: row 615, "check_line's `local -x LC_ALL=C` is dynamic: status_line runs under C in --check but under the caller's locale in --status"

**Location:** `docs/reviews/override-log.md:615`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers where LC_ALL is set in build-loop.sh. Does not establish the row's claim that status_line's output is the same either way.

`local -x LC_ALL=C` appears in check_line (`scripts/build-loop.sh:771`), which calls `out="$(status_line "$a")"` (`:774`). The --status branch calls `for a in "${ARGS[@]}"; do status_line "$a"; done` (`:842`) with no LC_ALL set. The only other script-level LC_ALL settings are per command or in checkout_gate (`:482`, `:582`, `:692`, `:713`).

**Evidence:** `scripts/build-loop.sh:771-774`, `scripts/build-loop.sh:840-843`

---

## Claim 9: row 616, "list_entries now parses both Self-merge never: and Paths: (and Paths: takes "none" as the settings lists do). The lib's reader_settings keeps its own copy"

**Location:** `docs/reviews/override-log.md:616`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers both callers and the lib's separate copy. Does not judge the deferral.

The two callers are `list_entries "$t" "Self-merge never" glob globform` (`scripts/build-loop.sh:418`) and `list_entries "${BRIEF[paths]}" Paths path pathform` (`:630`). `none` is the empty list: `[[ "$v" != none ]] || return 0` (`:370`). reader_settings keeps its own grammar: `elif [[ "$t" != "$key "* || ! "$v" =~ ^[^\ ]+(\ [^\ ]+)*$ ]]; then why="line ${first[$k]} is not exactly \"$key PATH ...\" with single spaces"` (within reader_settings, `scripts/lib/dev-cycle-read.sh:604` onward).

**Evidence:** `scripts/build-loop.sh:364-379`, `scripts/build-loop.sh:418`, `scripts/build-loop.sh:630`, `scripts/lib/dev-cycle-read.sh:604-645`

---

## Claim 10: row 617, "list_entries depends on nothing in build-loop.sh (pathform, globform's NAMECHARS are the lib's)"

**Location:** `docs/reviews/override-log.md:617`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the symbols list_entries' body references. Does not establish that globform itself (defined in build-loop.sh) would move, which the row does not claim.

list_entries' body uses only its arguments, the globals it sets, and `"$4" "${e%/}"` (`scripts/build-loop.sh:374`). FORM is passed in. globform reads `$NAMECHARS` (`:384`), which the lib defines (`NAMECHARS='abc...'`, `scripts/lib/dev-cycle-read.sh:212`).

**Evidence:** `scripts/build-loop.sh:364-379`, `scripts/build-loop.sh:382-390`, `scripts/lib/dev-cycle-read.sh:212`

---

## Claim 11: "`Paths: P…` (`Paths: none` or no line lists none; a malformed or duplicate entry lands only the brief's own files: U2c1)"

**Location:** `docs/working/plan-build-loop-handoff.md:238`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers read_paths and srules for none, absent, malformed and duplicate lines. Does not cover a failed re-read, which refuses the verdict (claim 30).

read_paths returns empty when there is no line: `[[ -n "${BRIEF[paths]+set}" ]] || return 0` (`scripts/build-loop.sh:629`). srules then lands own files and denies the rest: `! ownfile "$2" "$1" "$4" || return 0` then `[[ -z "$PATHS_WHY" ]] || { DENY=...; return 0; }` (`:665-666`). The malformed test at `test/scripts/build-loop-check.bats:1967` covers a duplicate, a double space, `..`, a leading `/`, bare `Paths:`, `Paths: none` and no line. It passed in E1 (`$S/run-check-full.txt`).

**Evidence:** `scripts/build-loop.sh:626-632`, `scripts/build-loop.sh:658-670`, `test/scripts/build-loop-check.bats:1967-1978`, `$S/run-check-full.txt`

---

## Claim 12: the U2c1 split note (S rules order, Paths: grammar, own-file case, parent-shell check_line, LC_ALL=C, carried rows)

**Location:** `docs/working/plan-build-loop-handoff.md:311`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each code property the note names. "Carried" lists work items, so a gitlink at a listed path is checked by E3 rather than by a branch test. Does not cover rows 526, 349 and 474 beyond the N rules' mode test.

- **S rules order.** `if [[ -z "$5" ]] && floor ...`, then the NEVER_RES loop, then `ownfile` and PATHS (`scripts/build-loop.sh:661-669`).
- **Own brief excluded.** `[[ -n "$DENY" || "$pol" != self-merge || "$p" == "$a" ]] || srules ...` (`:833`).
- **Parent shell, output to a file.** `check_line "$a" > "$GATE_TMP/line"` (`:858`).
- **LC_ALL=C.** `local -x LC_ALL=C` (`:771`).
- **Mutants.** E4's `noreset` and `nolcall` mutants each fail the walk test (`$S/run-noreset.txt`, `$S/run-nolcall.txt`). E3 shows a symlink and a gitlink at listed paths denied as `a symlink, gitlink or other non-file entry` (`$S/run-probe3.txt`).
- **Review keeps S rules off.** T45's review half passed in E1.

**Evidence:** `scripts/build-loop.sh:658-670`, `scripts/build-loop.sh:771`, `scripts/build-loop.sh:833`, `scripts/build-loop.sh:858`, `$S/run-noreset.txt`, `$S/run-nolcall.txt`, `$S/run-probe3.txt`

---

## Claim 13: U2c2 note, "floor's per-path cost: U2c1's measurement asks for it (i1 performance: 6.4 ms per path, 400 paths 3.1 s against main's 0.3 s; the forks in lower and need_root, not row 470's membership test)"

**Location:** `docs/working/plan-build-loop-handoff.md:312`
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the 400-path totals and the per-path figure on a 3,000-file fixture, and that lower and need_root fork. Does not apportion the cost between forks and membership, which I did not micro-time.

E7 (`$S/timeprobe.out`) measured `n=400 head ... secs=3.124` and `secs=3.17` against `n=400 main ... secs=0.349` and `secs=0.35`. That is about 6.7 ms per path, close to the 6.4 ms quoted. lower forks (`lower() { printf '%s' "$1" | tr ...; }`, `scripts/lib/dev-cycle-read.sh:825`), and so does need_root (`[[ "$ROOT_REAL" == "$(pwd -P)" ]]`, `:162`). The note names no count, so claim 3's undercount does not touch it.

**Evidence:** `scripts/lib/dev-cycle-read.sh:160-164`, `scripts/lib/dev-cycle-read.sh:825`, `$S/timeprobe.out`

---

## Claim 14: --help, "After an ok line, a K of N refusal or a checkout refusal, one line per path TREE changes against main"

**Location:** `scripts/build-loop.sh:155`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers which verdict lines are followed by path lines. Does not cover skip lines or the merge's own refusals, which print no path lines (unchanged).

C1 added a fourth case. A failed brief re-read sets `co="${co:-refuse $a: the brief could not be read again from the default branch}"` (`scripts/build-loop.sh:817`), and the rows still print after `echo "$co"` (`:836-837`). The E4 `reread` mutant (`$S/run-reread.txt`) shows `refuse ...: the brief could not be read again from the default branch` followed by `path` and `deny` lines.

--help lists this refusal only as "it moved or could not be read again after --status read it" (`:115`), and the sentence at :155 omits it. The precise version: "After an ok line, a K of N refusal, a checkout refusal or a brief that could not be read again".

**Evidence:** `scripts/build-loop.sh:113-118`, `scripts/build-loop.sh:155-158`, `scripts/build-loop.sh:813-818`, `scripts/build-loop.sh:836-837`, `$S/run-reread.txt`

---

## Claim 15: --help N rules, "anything under docs/working/briefs/ or docs/working/cycles/, or either as a file) and docs/constraints.md, or a path below one of those names"

**Location:** `scripts/build-loop.sh:170-172`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the briefs/cycles regex and the parent loop. Does not establish that the loop denies nothing else (claim 23).

The regex is `^docs/working/(briefs|cycles)(/|$)` (`scripts/build-loop.sh:613`). The parent loop denies on `^(cycle|settings|user)$` (`:614-617`). The test at `test/scripts/build-loop-check.bats:1993` denies `docs/roadmap.md/f`, `docs/constraints.md/f`, `Docs/Dev-Cycle.md/x`, `docs/working/questions.md/a/b` and `docs/working/cycles` as a file. It passed in E1.

**Evidence:** `scripts/build-loop.sh:597-619`, `test/scripts/build-loop-check.bats:1993-2002`, `$S/run-check-full.txt`

---

## Claim 16: --help S rules, "for a brief --status reads as self-merge, on each path the N rules pass but the brief's own file (first match): the self-merge floor (... not run over a checkout refused above)"

**Location:** `scripts/build-loop.sh:173-179`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the gating condition, the order, the floor's listed contents, and the floor being skipped on a checkout refusal. The floor is also skipped on a failed re-read, which --help does not mention here (claim 14 covers that line).

The call is `[[ -n "$DENY" || "$pol" != self-merge || "$p" == "$a" ]] || srules ...` (`scripts/build-loop.sh:833`). Inside srules: `if [[ -z "$5" ]] && floor "$2" "$1" "$4"; then DENY="$FLOOR_WHY"; return 0; fi` (`:661`). floor's arms are instr, dot, user, record, case, cycle, GATE_CODE, docs/thoughts/, docs/working/ and docs/reviews/ not own, and the import walk (`scripts/lib/dev-cycle-read.sh:1832-1850`). The --help list matches them. T10 (`test/scripts/build-loop-check.bats:1948`) exercises each floor reason under a listing Paths: and passed in E1.

**Evidence:** `scripts/build-loop.sh:658-670`, `scripts/build-loop.sh:833`, `scripts/lib/dev-cycle-read.sh:1827-1851`, `$S/run-check-full.txt`

---

## Claim 17: --help never globs, "compared lower-cased, * and ? within one part, matching the path or a directory above it"

**Location:** `scripts/build-loop.sh:179-181`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers never_res' regex and srules' match on the lowered path. Does not cover glob characters globform refuses.

never_res builds the regex: `case "$c" in '*') re+='[^/]*' ;; '?') re+='[^/]' ;; .) re+='\.' ;; *) re+="$c" ;; esac` then `NEVER_RES+=("^$re(/|\$)")` (`scripts/build-loop.sh:643-645`). It runs over `g="$(lower "${g%/}")"` (`:640`). srules tests `$3`, the lowered path (`:663`). The other characters globform admits (letters, digits, `_`, `-`, `/`) are literal in an ERE. T45 (`test/scripts/build-loop-check.bats:1980`) passed in E1: `Workflows/Z.md` was denied, while `docs/sub/n.txt` and `workflowsx.md` passed.

**Evidence:** `scripts/build-loop.sh:633-647`, `scripts/build-loop.sh:662-664`, `test/scripts/build-loop-check.bats:1980-1991`

---

## Claim 18: --help allowlist, own-file list, "the allowlist takes these only in lower case, though the floor passes any case", the Paths: grammar, and "any other line is malformed, and only own files land"

**Location:** `scripts/build-loop.sh:181-191`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers ownfile's patterns, the exact and part-boundary match, and malformed handling. A failed re-read is outside this sentence (claim 14).

srules' match loop is `[[ "$2" != "$e" && ( "$e" != */ || "$2" != "$e"* ) ]] || return 0` (`scripts/build-loop.sh:668`). ownfile gets `$2` as spelled (`:665`). The floor lowers before it calls ownfile (`ownfile "$lp" "$2" "$3"`, `scripts/lib/dev-cycle-read.sh:1843-1844`). In the malformed test (`:1967`), `Docs/Working/Plan-2026-10-01-x.md` gets the Paths reason, not the floor's WORK reason, while the lower-case copy lands. In T10, `docs/ab.md`, `Hooks/x.sh` and `scripts/x.sh` are denied as unlisted. Both passed in E1.

**Evidence:** `scripts/build-loop.sh:658-670`, `scripts/lib/dev-cycle-read.sh:1806-1811`, `scripts/lib/dev-cycle-read.sh:1843-1844`, `test/scripts/build-loop-check.bats:1948-1978`

---

## Claim 19: Exit:, "A --check can also stop part way, after the lines of the briefs before, with 1 (need_root) or a failed command's own status"

**Location:** `scripts/build-loop.sh:200-203`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the need_root exit mid-run with the earlier brief's lines kept. Does not exercise a set -e stop from another failed command.

The E5 mutant makes need_root fail for the second brief. `$S/run-exit.txt` shows `status=1`, brief x's `ok` and `path` lines, nothing for y, and `stderr=dev-cycle-read.sh: ROOT_REAL is not the current directory`. That brief's partial lines are lost because they go to a file first: `check_line "$a" > "$GATE_TMP/line"; cat "$GATE_TMP/line"` (`scripts/build-loop.sh:858`).

**Evidence:** `scripts/build-loop.sh:199-203`, `scripts/build-loop.sh:852-861`, `$S/run-exit.txt`, `$S/mut-exit.grep`

---

## Claim 20: list_entries' contract ("LINE is exactly "KEY: none" or "KEY: E ..." with single spaces ... Sets LIST ... or LIST_WHY, and LIST_BAD to form ... or entry ..., or empty")

**Location:** `scripts/build-loop.sh:357-362`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the whole function body (`:364-379`) and both callers' use of LIST, LIST_WHY and LIST_BAD. Does not cover lines with a CR, which brief_fields and main_file strip before this.

- **Form check.** `if [[ "$1" != "$2: "* || ! "$v" =~ ^[^\ ]+(\ [^\ ]+)*$ ]]; then LIST_WHY=...; LIST_BAD=form; return 0; fi` (`:369`).
- **none.** `[[ "$v" != none ]] || return 0` with LIST empty (`:370`).
- **Entries.** Each passes FORM on `${e%/}` and is deduped on `${e%/}` (`:374-376`).
- **On failure.** `[[ -z "$LIST_WHY" ]] || { LIST=(); LIST_BAD=entry; }` (`:378`).
- **As written.** LIST keeps entries as written, from `IFS=' ' read -ra LIST <<<"$v"` (`:371`).

**Evidence:** `scripts/build-loop.sh:357-379`, `scripts/build-loop.sh:416-423`, `scripts/build-loop.sh:627-632`

---

## Claim 21: read_settings, "The form reason comes first, then the next line, then the entries." (never line unchanged in reasons and precedence)

**Location:** `scripts/build-loop.sh:419`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers precedence against main's code (form, then next line, then entries or none). Does not re-run i2's 44-case differential. The suite run is the execution.

The new code is `list_entries ...; why="$LIST_WHY"` then `if [[ "$LIST_BAD" != form && "${next[never]}" != 1 ]]; then why="is followed by a non-blank line ..."; fi` (`scripts/build-loop.sh:418-420`). The next-line reason overrides an entry reason, never a form reason. Main's version tested form, then `next`, then none and entries, in an if/elif chain (the removed lines in the diff at `:414-423`). The reason strings are equal: `"is not exactly \"$2: ${3^^} ...\" with single spaces"` with KEY `Self-merge never` and WORD `glob` gives main's `is not exactly "Self-merge never: GLOB ..." with single spaces`. build-loop-read.bats passed 20/20 (E1).

**Evidence:** `scripts/build-loop.sh:413-424`, `scripts/build-loop.sh:369`, `$S/run-read.txt`

---

## Claim 22: nrules' comment, "so does a path below one of those names (docs/roadmap.md/x, which main may lack, would keep the cycle from writing the file: row 523). srules adds the S rules."

**Location:** `scripts/build-loop.sh:593-595`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the lowered parent loop. Does not establish the row 523 rationale.

The loop is `while [[ -z "$DENY" && "$d" == */* ]]; do d="${d%/*}"; truthrule "$d" || true` (`scripts/build-loop.sh:614-615`), with `d="$7"`, the lowered path (`:598`). The row-523 test passed in E1.

**Evidence:** `scripts/build-loop.sh:586-619`, `test/scripts/build-loop-check.bats:1993-2002`

---

## Claim 23: nrules' prefix loop covers every name the other arms cover (cycle, settings, user, briefs/, cycles/) and nothing else

**Location:** `scripts/build-loop.sh:614-617`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the loop's deny condition against the arms above it. Does not cover instr or dot words on a parent, which the loop ignores by design (the floor's domain).

The loop denies only when `[[ ! "$TRUTH_WHY" =~ ^(cycle|settings|user)$ ]]` fails (`:616`), the same three words as the case arms at `:611-612`. A path below briefs/ or cycles/ is already caught by the `(/|$)` regex (`:613`), so the loop needs no arm for them. Since `d` is lowered, the case word cannot fire (`truthrule` tests upper-case first, `scripts/lib/dev-cycle-read.sh:1779`).

**Evidence:** `scripts/build-loop.sh:609-618`, `scripts/lib/dev-cycle-read.sh:1777-1787`

---

## Claim 24: read_paths' comment ("as list_entries reads "Paths: PATH ...", ... "Paths: none", or no line, lists none. Sets PATHS or, for a malformed line, PATHS_WHY")

**Location:** `scripts/build-loop.sh:622-625`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers read_paths' body. Does not cover check_line's own PATHS_WHY on a failed re-read.

The body is `PATHS=(); PATHS_WHY=""; [[ -n "${BRIEF[paths]+set}" ]] || return 0; list_entries "${BRIEF[paths]}" Paths path pathform; PATHS=("${LIST[@]}"); PATHS_WHY="$LIST_WHY"` (`scripts/build-loop.sh:628-631`).

**Evidence:** `scripts/build-loop.sh:622-632`

---

## Claim 25: never_res' comment, "NEVER's globs as regexes for a lower-cased path ... a glob matches the path or any directory above it (a trailing / changes nothing). Set once, after read_settings."

**Location:** `scripts/build-loop.sh:633-635`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the regex construction and the single call site. Does not test a glob of every admitted character (claim 17 covers the characters by reading).

`${g%/}` drops the trailing slash (`:640`). The sole call is `read_settings; never_res` in the check branch (`:850`).

**Evidence:** `scripts/build-loop.sh:633-647`, `scripts/build-loop.sh:850`

---

## Claim 26: srules' comment, "$5 the checkout refusal, if any ... the floor (only when $5 is empty: it walks the checkout)"

**Location:** `scripts/build-loop.sh:649-657`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers what check_line passes as $5. The rest of the comment (first match, the allowlist's case rule) is Verified by claims 16-18.

check_line passes `"$co"` (`scripts/build-loop.sh:833`). Since C1, co also holds the failed re-read refusal: `co="${co:-refuse $a: the brief could not be read again from the default branch}"` (`:817`). So $5 is "the checkout or re-read refusal". The mechanism (floor skipped when $5 is set) is right.

**Evidence:** `scripts/build-loop.sh:649-661`, `scripts/build-loop.sh:817`, `scripts/build-loop.sh:833`

---

## Claim 27: deny text on a failed re-read, "the brief's Paths: line could not be read again, so only its own files land"

**Location:** `scripts/build-loop.sh:666`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the deny reason printed when PATHS_WHY is check_line's "could not be read again". Does not cover the malformed-line case, where the text is accurate.

With `PATHS_WHY="could not be read again"` (`:817`), srules prints `DENY="the brief's Paths: line $PATHS_WHY, so only its own files land"` (`:666`). But the verdict is co's refusal (`:836`), so nothing lands. The E4 `reread` run (`$S/run-reread.txt`) shows `refuse ...: the brief could not be read again from the default branch` above `deny ... A hooks/x.sh: the brief's Paths: line could not be read again, so only its own files land`. This fails closed. Only the wording of "land" overstates what happens.

**Evidence:** `scripts/build-loop.sh:666`, `scripts/build-loop.sh:813-818`, `scripts/build-loop.sh:836`, `$S/run-reread.txt`

---

## Claim 28: check_line's comment, "It runs in the caller's shell, so an exit (need_root's) ends the run, and set -e applies to its own lines but not inside a helper called in a condition (...) or in $(...) ... each helper empties its own globals before use (DENY, PATHS and PATHS_WHY, LIST and LIST_WHY, BRIEF, CHECKOUT_WHY, FLOOR_WHY, TRUTH_WHY)"

**Location:** `scripts/build-loop.sh:761-768`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the need_root exit (E5), the named helpers' condition contexts, and each named global's reset. Does not enumerate every lib global the walk writes beyond what import_reset clears. PATHS is not reset for a review brief, but nothing reads it then.

- **Exit.** E5 shows the run ending at need_root (`status=1`, `$S/run-exit.txt`).
- **Condition contexts.** `if [[ -z "$5" ]] && floor` (`:661`), `if brief_fields "$a"` (`:817`), `! checkout_gate` (`:811`), `if ! nul_list` (`:830`).
- **Resets.** DENY in nrules and srules (`:599`, `:660`). PATHS and PATHS_WHY in read_paths (`:628`), or set at `:817`. LIST in list_entries (`:367`). BRIEF in brief_fields (`BRIEF=(); BRIEF_ODD=""`, `scripts/lib/dev-cycle-read.sh:390`). CHECKOUT_WHY in checkout_gate (`:694`). FLOOR_WHY in floor (`scripts/lib/dev-cycle-read.sh:1830`). TRUTH_WHY in truthrule (`:1778`).
- **Reads of PATHS.** srules reads PATHS only under `pol == self-merge` (`:833`), and that branch always rewrites it first (`:816-818`).

**Evidence:** `scripts/build-loop.sh:757-838`, `scripts/lib/dev-cycle-read.sh:386-391`, `scripts/lib/dev-cycle-read.sh:1777-1779`, `scripts/lib/dev-cycle-read.sh:1827-1830`, `$S/run-exit.txt`

---

## Claim 29: "Contract item 1 (the floor's walk); exported, so its children run under it too."

**Location:** `scripts/build-loop.sh:770-771`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that the walk runs under C when the caller's locale is C.utf8. Does not test other locales.

The E4 `nolcall` mutant, with `local -x LC_ALL=C` removed, fails the walk test under `LC_ALL=C.utf8`. It prints `deny ... A work-feat-x.txt: the default branch's instruction files could not be walked for @ imports` (`$S/run-nolcall.txt`). The unmutated test passes (E1).

**Evidence:** `scripts/build-loop.sh:770-772`, `test/scripts/build-loop-check.bats:2004-2016`, `$S/run-nolcall.txt`

---

## Claim 30: "A failed read refuses the verdict as a checkout refusal does (path lines still print, the floor does not run)."

**Location:** `scripts/build-loop.sh:814-815`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the forced-failure mutant's output. Does not cause a real brief_fields failure.

`$S/run-reread.txt` shows the refuse line, then path and deny lines. No deny carries a floor reason: `scripts/other.sh` and others get the Paths reason. The floor is skipped via `[[ -z "$5" ]]` (`:661`).

**Evidence:** `scripts/build-loop.sh:813-818`, `scripts/build-loop.sh:661`, `$S/run-reread.txt`

---

## Claim 31: "In this shell, not $(...): the floor's need_root exit ends the run, and check_line's import_reset is what keeps one brief's walk from the next."

**Location:** `scripts/build-loop.sh:856-857`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers both effects for two self-merge briefs. Does not cover review briefs, which do not walk.

The E4 `noreset` mutant fails the count test: the shim's `calls` file holds one `worktree list` instead of two (`$S/run-noreset.txt`). E5 shows the exit (`$S/run-exit.txt`).

**Evidence:** `scripts/build-loop.sh:852-861`, `$S/run-noreset.txt`, `$S/run-exit.txt`

---

## Claim 32: lib header item 3, "build-loop.sh --check does, for each self-merge brief before the walk (U2b2; its check_line runs the walk under item 1's LC_ALL=C)"

**Location:** `scripts/lib/dev-cycle-read.sh:62-63`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the LC_ALL clause and that checkout_gate runs before srules. The rest of item 3 is unchanged and was not re-verified.

`co=""; if [[ "$pol" == self-merge ]] && ! checkout_gate; ...` (`scripts/build-loop.sh:811`) comes before the per-path loop (`:831-835`). LC_ALL is covered by claim 29.

**Evidence:** `scripts/lib/dev-cycle-read.sh:58-68`, `scripts/build-loop.sh:811`, `$S/run-nolcall.txt`

---

## Claim 33: lib header item 5, "build-loop.sh reads diff-tree -r of main and the merge instead, where a symlink or gitlink above a path is a changed entry of its own ... its S rules run floor only on a path they pass"

**Location:** `scripts/lib/dev-cycle-read.sh:76-86`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers a directory replaced by a symlink and by a gitlink. Does not cover a gitlink introduced with no prior directory, which is still its own 160000 entry by the same diff-tree rule.

E3 (`$S/run-probe3.txt`) shows `deny ... A lnk: a symlink, gitlink or other non-file entry` with `path ... D lnk/f`, and `deny ... A sub: ...` with `path ... D sub/f`. The symlink and the gitlink are entries of their own and are denied. Floor runs only after the N rules pass (`scripts/build-loop.sh:833`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:76-86`, `scripts/build-loop.sh:791-800`, `scripts/build-loop.sh:833`, `$S/run-probe3.txt`

---

## Claim 34: lib header item 8, "Pass truthrule, isstart, ownfile, prompt_dir and prompt_bases a lower-cased path"

**Location:** `scripts/lib/dev-cycle-read.sh:90-93`
**Type:** Invariant
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers ownfile's callers. Does not cover truthrule, isstart, prompt_dir or prompt_bases, which this branch's callers pass lowered (nrules' `$7` and `d`).

Item 8 was last edited 2026-10-08 (`git blame` 2f9464d34 and 185e92f18). The branch's B1 fix then made srules pass ownfile the path as spelled, on purpose: `! ownfile "$2" "$1" "$4" || return 0` (`scripts/build-loop.sh:665`). ownfile's own comment was updated to match ("for a path $1 (it folds no case: floor passes it lower-cased, build-loop.sh srules as spelled)", `scripts/lib/dev-cycle-read.sh:1800-1801`). So the contract still tells callers to lower the path, and srules' as-spelled call, required by "an allowlist widens nothing by case", reads as a violation. What to change: drop ownfile from item 8's list, or note that srules passes the path as spelled.

**Evidence:** `scripts/lib/dev-cycle-read.sh:90-93`, `scripts/lib/dev-cycle-read.sh:1799-1811`, `scripts/build-loop.sh:665`

---

## Claim 35: ownfile's comment, "for a path $1 (it folds no case: floor passes it lower-cased, build-loop.sh srules as spelled)"

**Location:** `scripts/lib/dev-cycle-read.sh:1800-1801`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers ownfile's body and its only two call sites (grep). Does not cover callers outside scripts/.

The body compares `$1` with no lowering (`:1807-1810`). The call sites are floor's `ownfile "$lp" ...` (`:1843-1844`) and srules' `ownfile "$2" ...` (`scripts/build-loop.sh:665`). A grep of scripts/ finds no others.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1799-1811`, `scripts/lib/dev-cycle-read.sh:1843-1844`, `scripts/build-loop.sh:665`

---

## Claim 36: `FLOOR_WHY=""  # read by floor's caller (build-loop.sh srules)`

**Location:** `scripts/lib/dev-cycle-read.sh:1825`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that srules reads it. Does not search for readers outside scripts/.

`DENY="$FLOOR_WHY"` (`scripts/build-loop.sh:661`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1825`, `scripts/build-loop.sh:661`

---

## Claim 37: test title, "--check self-merges listed paths (exec bit, a directory entry), the brief's own working docs and added reviews, and its Status line (T9, U2c1)"

**Location:** `test/scripts/build-loop-check.bats:1938`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the assertions against the title. Does not cover handoff-STEM.md or test-strategy-STEM.md, which the test does not add.

The setup runs `chmod +x scripts/other.sh` and lists the directories `skills/x/` and `test/`. It adds research, plan and checkpoint docs and two reviews, and makes the `Status: done` edit. The assertions are `[ "${#lines[@]}" -eq 13 ]`, `has "path $B M $B"`, and a path line for each file. It passed in E1.

**Evidence:** `test/scripts/build-loop-check.bats:1938-1946`, `$S/run-check-full.txt`

---

## Claim 38: test title, "--check refuses a self-merge path the floor names though Paths: lists it, a symlink at a listed path, and a path Paths: does not list exactly (T10, rows 349, 474, U2c1)"

**Location:** `test/scripts/build-loop-check.bats:1948`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the 18 changed paths and their asserted reasons. A gitlink at a listed path (row 349/474's other half) is not in this test. E3 covers it.

It asserts `nref 17 18`. Each floor reason appears against a path Paths: lists. `deny $B A scripts/link.sh: $NMODE` covers the symlink, and NLIST covers `docs/ab.md Hooks/x.sh scripts/x.sh`. Passed in E1.

**Evidence:** `test/scripts/build-loop-check.bats:1948-1965`, `$S/run-check-full.txt`

---

## Claim 39: test title, "--check: a malformed Paths: line lands only the brief's own files, spelled in lower case; Paths: none or no line lists nothing (T10, U2c1 i1)"

**Location:** `test/scripts/build-loop-check.bats:1967`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers seven Paths: variants with three changed paths each. Does not cover added reviews.

For each variant the test asserts `nref 2 3`, a deny of `docs/a`, a deny of `Docs/Working/Plan-...`, and a path line for `docs/working/plan-...`. For `Paths: none` and no line, the reason is NLIST. Passed in E1.

**Evidence:** `test/scripts/build-loop-check.bats:1967-1978`

---

## Claim 40: test title, "--check: a Self-merge never: glob refuses a listed path under self-merge, by part and in any case; review ignores it (T45, U2c1)"

**Location:** `test/scripts/build-loop-check.bats:1980`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the title against its assertions. Does not cover `?` globs.

The self-merge half asserts four denies, including `Workflows/Z.md`, and two passes (`docs/sub/n.txt`, `workflowsx.md`). The review half asserts status 0 and 7 lines. Passed in E1.

**Evidence:** `test/scripts/build-loop-check.bats:1980-1991`

---

## Claim 41: test title, "--check refuses a path below a cycle file's or the constraints doc's name, and cycles/ as a file (an N rule; row 523, U2c1)"

**Location:** `test/scripts/build-loop-check.bats:1993`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the five asserted denies under a review brief (`gated`). briefs/ as a file is not tested.

The test asserts `nref 5 5`, four "a path below the name ..." lines, and `deny $B A docs/working/cycles: $NOWN`. Passed in E1.

**Evidence:** `test/scripts/build-loop-check.bats:1993-2002`

---

## Claim 42: test title, "--check walks once per self-merge decision (check_line's import_reset, in the parent shell) and under the C locale (contract items 1, 4; row 532, U2c1)"

**Location:** `test/scripts/build-loop-check.bats:2004`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers both halves of the title, each killed by its mutant. Does not cover more than two briefs.

The `noreset` mutant fails the `worktree list` count (`$S/run-noreset.txt`). The `nolcall` mutant fails the C.utf8 half (`$S/run-nolcall.txt`). So neither assertion passes vacuously.

**Evidence:** `test/scripts/build-loop-check.bats:2004-2016`, `$S/run-noreset.txt`, `$S/run-nolcall.txt`

---

## Claim 43: commit eddfd5f9, ""Paths:" alone or no line lists none"

**Location:** `git show eddfd5f9` (message body, line 8)
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the bare-`Paths:` clause at 9e7c61c5. A commit message is immutable, and d435100e's message records the change.

At HEAD, bare `Paths:` fails list_entries' `"$1" != "$2: "*` test (`scripts/build-loop.sh:369`) and is malformed. The malformed test's variant `"Paths:|is not exactly \"Paths: PATH ...\" with single spaces"` passed in E1. d435100e's message says "bare "Paths:" is now malformed".

**Evidence:** `scripts/build-loop.sh:369`, `test/scripts/build-loop-check.bats:1968-1970`

---

## Claim 44: commit eddfd5f9, "Tests: build-loop-check 138, build-loop-read 20 ... 229 changed code lines."

**Location:** `git show eddfd5f9` (message body)
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the two suite counts (still 138 and 20 at HEAD) and the 229 as additions plus deletions under scripts/ and test/ at eddfd5f9 (log row 62's "changed code lines outside docs/"). The dev-cycle, fixture-git-env and fixture-hermeticity counts were not re-run.

E1 shows `1..138` and 20 ok. `git diff --numstat main...eddfd5f9 -- scripts test` gives `105 15`, `12 9`, `87 1`, which sum to 229.

**Evidence:** `$S/run-check-full.txt`, `$S/run-read.txt`

---

## Claim 45: commit eddfd5f9, "Timing on a 3,284-file clone: 3.6 s for 1 path, 6.1 s for 150, 7.6 s for 400."

**Location:** `git show eddfd5f9` (message body)
**Type:** Performance
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers nothing beyond what my fixture shows. The author's clone and its walk are not available.

The blocker is that the 3,284-file clone is not named or present. E7's 3,000-file fixture shows the same shape (about +2.7 s from 1 to 400 paths) but not these totals. This is already Accepted (rubric B11).

**Evidence:** `$S/timeprobe.out`

---

## Claim 46: commit d435100e, "B5: a failed brief re-read lands only own files, every path line printed."

**Location:** `git show d435100e` (message body)
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the behavior at 9e7c61c5. An immutable message, superseded by 9e7c61c5's C1.

See claim 6. At HEAD the verdict is refused (`$S/run-reread.txt`).

**Evidence:** `scripts/build-loop.sh:817`, `$S/run-reread.txt`

---

## Claim 47: commit 9e7c61c5, "C1: a failed brief re-read refuses the verdict (path lines still print). C2: list_entries sets LIST_BAD, so read_settings no longer reads its wording. C3: ownfile's comment: it folds no case."

**Location:** `git show 9e7c61c5` (message body)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers C1 to C3 against the code. C4's text fixes are covered by claims 14, 19 and 28, and C5 by claim 10.

- **C1.** `$S/run-reread.txt`.
- **C2.** `if [[ "$LIST_BAD" != form && ...` (`scripts/build-loop.sh:420`), with no wording test left.
- **C3.** `scripts/lib/dev-cycle-read.sh:1800-1801`.

**Evidence:** `scripts/build-loop.sh:420`, `scripts/lib/dev-cycle-read.sh:1800-1801`, `$S/run-reread.txt`

---

## Claims Requiring Attention

### Incorrect
None.

### Stale
- **Claim 6** (`docs/reviews/override-log.md:613`): the row says a failed re-read "now lands only own files". Since C1 it refuses the verdict. Amend the row in a new row.
- **Claim 34** (`scripts/lib/dev-cycle-read.sh:90-93`): contract item 8 still tells callers to pass ownfile a lower-cased path. srules passes it as spelled on purpose (B1). Drop ownfile from item 8 or note the exception.
- **Claim 43** (eddfd5f9 message): bare `Paths:` is now malformed. The message is immutable, and d435100e records the change.
- **Claim 46** (d435100e message): B5's "lands only own files" was superseded by C1. The message is immutable.

### Mostly Accurate
- **Claim 3** (`docs/reviews/override-log.md:610`): need_root runs four times per floor call, not twice. The lower count (2) and the 400-path totals hold.
- **Claim 5** (`docs/reviews/override-log.md:612`): the Paths reason shows only on non-own paths the floor and never globs pass. With only own files changed, the verdict is ok and the malformed line shows nowhere.
- **Claim 14** (`scripts/build-loop.sh:155`): path lines also follow the "brief could not be read again" refusal. --help lists only ok, K of N and checkout refusals.
- **Claim 26** (`scripts/build-loop.sh:649-657`): srules' $5 is the checkout or re-read refusal, not only the checkout refusal.
- **Claim 27** (`scripts/build-loop.sh:666`): on a failed re-read, the deny text says "so only its own files land", but the verdict refuses everything.

### Unverifiable
- **Claim 4** (`docs/reviews/override-log.md:611`): the membership-glob micro-timings need a re-run against 28 KB and 6 MB walk lists.
- **Claim 45** (eddfd5f9 message): the 3,284-file clone is not available. E7's fixture shows the same shape only.

## Goal-Alignment Note

The success criterion, restated verbatim: "a markdown report saved at the output path your dispatch names, structured per your skill, every finding with verbatim Evidence and a path:line." This report is at `docs/reviews/code-fact-check-report-build-loop-u2c1-final-r2.md`, carries `**Commit:** 9e7c61c5`, follows the skill's header, the seven per-claim fields plus Legibility-target, and the attention summary. Every Stale, Mostly accurate and Unverifiable claim quotes source with a path:line or names its captured execution log. No commit was made.
