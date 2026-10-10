**Commit:** 9e7c61c5

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u2c1 (branch `feat/build-loop-u2c1`)
**Scope:** `git diff main...HEAD` at 9e7c61c5, the whole branch. Covered: scripts/build-loop.sh, scripts/lib/dev-cycle-read.sh, test/scripts/build-loop-check.bats, docs/working/plan-build-loop-handoff.md, the override-log rows dated 2026-10-10 for this branch, and the branch's commit messages. Review reports are treated as artifacts, not claims.
**Checked:** 2026-10-10
**Total claims checked:** 48
**Summary:** 42 verified, 1 mostly accurate, 2 stale, 1 incorrect, 2 unverifiable

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`, 5 entries). Three of them are commit-message tallies; claims 45 and 46 are that kind and are compared against them there. No claim here is a fabrication.

## Execution provenance

`$S` = `/tmp/claude-1000/-workspace/54247aa5-2a95-449b-b931-3ed456da322c/scratchpad/u2c1-final-fc-r1`. Every probe followed the shared brief's safety rules: `set -eu`, its own `mktemp -d /tmp/u2c1-fcr1-XXXX`, `git archive 9e7c61c5` copies, and bats run serially with `LC_ALL=C` and its own TMPDIR. No git write command ran in /workspace or in the worktree.

- **E1** `bash $S/probe.sh`. Run from cwd `$S` at 2026-10-10T10:45:21Z, exit 0, log `$S/probe.out`. It ran five cases:
  - P1, extra never-glob cases on a clean copy: `$S/run-p1.txt`, ok.
  - M1, check_line's `import_reset` removed: `$S/run-m1.txt`. The test fails, and the shim log shows 1 `worktree list` call.
  - M2, check_line's `local -x LC_ALL=C` removed: `$S/run-m2.txt`. The test fails on its C.utf8 part.
  - M3, nrules' parent-path loop removed: `$S/run-m3.txt`. The row-523 test fails.
  - M5, need_root forced to fail in brief y's floor: `$S/run-m5.txt`, ok (exit 1, and only brief x's lines print).
  - A diff-tree probe: `$S/difftree.txt`.
- **E2** Full suites, run from cwd `/workspace/.claude/wt-build-loop-u2c1` at 2026-10-10T10:45:47Z:
  - `bats test/scripts/build-loop-check.bats`: exit 0, 138 ok (`$S/full-build-loop-check.txt`).
  - `bats test/scripts/build-loop-read.bats`: exit 0, 20 ok (`$S/full-build-loop-read.txt`).
  - Summary in `$S/full-summary.txt`; `bats --count` results in `$S/counts.txt`.
- **E3** Floor timing and call counts, run from cwd `$S`:
  - `bash $S/bench2.sh` at 2026-10-10T10:47:52Z, 3 runs, exit 0, log `$S/bench2.out`.
  - `bash $S/count.sh` at 2026-10-10T10:48:31Z, exit 0, log `$S/count.out`.
- **E4** `bash $S/probe2.sh`, run from cwd `$S` at 2026-10-10T10:49:16Z, exit 0. It forces check_line's brief re-read to fail and runs one test; output in `$S/run-c1.txt`.
- **E5** `bash $S/timing.sh`, run from cwd `$S` at 2026-10-10T10:50:12Z, exit 0, log `$S/timing.out`. It times `--check` with main's and the branch's scripts on a repo of 3,000 files, with 1, 150 and 400 changed paths, two runs each.
- One more benchmark, the walk-list glob test, was blocked by a Claude Code safety check (it flagged an `rm` inside the `bash -c` script). It did not run; see claim 4.

---

## Claim 1: "A directory at an instruction-file name or an @-import target lands under self-merge (`src/CLAUDE.md/n.txt` …): the floor tests the whole path only"

**Location:** `docs/reviews/override-log.md:608`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the claim that floor tests only the whole lower-cased path, never a directory above it. Does not establish the row's availability argument (that a directory is never loaded as instructions).
**Legibility-target:** for-orchestrator-synthesis

floor tests `lp`, the whole path: `if truthrule "$lp"; then` … `elif truthwalk main "$lp"; then` (`scripts/lib/dev-cycle-read.sh:1832-1849`, the whole function, read). isstart tests only the last part: `isstart() { [[ "${1##*/}" =~ $INSTRUCTION_FILE ]] || …` (`scripts/lib/dev-cycle-read.sh:663`). So for `src/claude.md/n.txt`, isstart tests the name `n.txt`. Nothing tests the directory parts above the file.

**Evidence:** `scripts/lib/dev-cycle-read.sh:663`, `scripts/lib/dev-cycle-read.sh:1827-1850`

---

## Claim 2: "An added review named NAME-STEM.md can take a sibling brief's STEM.md name … A loop cannot choose sibling stems (… briefs/ is N-denied), and an added review takes no existing name."

**Location:** `docs/reviews/override-log.md:609`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers ownfile's suffix match, the N-rule denial of `docs/working/briefs/`, and the rule that only an added review counts. Does not establish how the cycle chooses stems.
**Legibility-target:** for-orchestrator-synthesis

The suffix rule is in ownfile: `[[ "$3" == A && "$1" == docs/reviews/* && "$b" != */* && ( "$b" == "$2.md" || "$b" == *"-$2.md" ) ]]` (`scripts/lib/dev-cycle-read.sh:1810`). Under it, `2026-10-02-y-2026-10-01-x.md` ends in `-2026-10-01-x.md`. The N rules deny `docs/working/briefs/`: `[[ ! "$7" =~ ^docs/working/(briefs|cycles)(/|$) ]] || DENY=…` (`scripts/build-loop.sh:614`). The `"$3" == A` test means only an added review counts.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1806-1811`, `scripts/build-loop.sh:614`

---

## Claim 3a: "floor forks twice per path to lower-case it and runs need_root twice, ~5.7 ms of the S rules' ~6.4 ms per path"

**Location:** `docs/reviews/override-log.md:610`
**Type:** Performance
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers how many times one cached floor call runs lower and need_root, and the share of floor's per-path time those calls take. Does not establish the costs on the performance reviewer's own machine.
**Legibility-target:** for-author

The lower count is right and the need_root count is wrong. One cached floor call runs `lower` twice and `need_root` **four** times (`$S/count.out`: "need_root calls in one cached floor: 4", "lower calls in one cached floor: 2"). The four need_root calls come from:

- floor itself: `need_root` (`scripts/lib/dev-cycle-read.sh:1829`);
- main_imports, reached through truthwalk: `need_root` (`scripts/lib/dev-cycle-read.sh:1630`);
- isimported: `need_root` (`scripts/lib/dev-cycle-read.sh:1756`);
- main_imports again, called from isimported: `main) main_imports || return 0;` (`:1759`).

Both main_imports calls also run import_readers before the cache test (`import_readers || {…}`, `:1631`).

Measured over three runs (`$S/bench2.out`):

| What | Time per call |
|---|---|
| floor, whole call | 6.57–6.58 ms (9.6 ms in a first, noisy run) |
| lower, one call | ~1.35 ms |
| need_root, one call | ~0.42 ms |
| main_imports, cached | ~0.85 ms |

Two lower calls and four need_root calls come to about 4.4 ms of 6.6 ms, not 5.7 ms. The rest is mostly the two cached main_imports/import_readers entries. The row's conclusion holds: the cost is forks per call, not the membership test. A U2c2 fix that removes two need_root calls would still leave two.

**Evidence:** `docs/reviews/override-log.md:610`, `scripts/lib/dev-cycle-read.sh:1626-1631`, `scripts/lib/dev-cycle-read.sh:1754-1762`, `scripts/lib/dev-cycle-read.sh:1827-1832`, `$S/count.out`, `$S/bench2.out`

---

## Claim 3b: "400 paths take 3.1 s against main's 0.3 s"

**Location:** `docs/reviews/override-log.md:610`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a 3,000-file repo with 400 changed paths under a self-merge brief, on this machine. Does not establish timings on other hardware or with a larger walk.
**Legibility-target:** for-orchestrator-synthesis

Measured in E5 (`$S/timing.out`):

| Changed paths | main | branch |
|---|---|---|
| 1 | 0.24 / 0.24 s | 0.47 / 0.46 s |
| 150 | 0.29 / 0.28 s | 1.41 / 1.43 s |
| 400 | 0.33 / 0.33 s | 3.02 / 3.05 s |

That is (3.03 − 0.47) / 399 ≈ 6.4 ms per path, which matches the "~6.4 ms" figure. The numbers match the final brief's performance figures (main 0.24/0.27/0.33 s, branch 0.57/1.50/3.13 s).

**Evidence:** `$S/timing.sh`, `$S/timing.out`

---

## Claim 4: "the glob test is 0.12 ms per path on a 28 KB walk list, 43 ms only near IMPORT_OUT_MAX"

**Location:** `docs/reviews/override-log.md:611`
**Type:** Performance
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers nothing beyond confirming the test's form. Does not establish either timing.
**Legibility-target:** for-orchestrator-synthesis

The test is the glob match `[[ "$IMPORTED_MAIN" == *$'\n'"$lp"$'\n'* ]]` (`scripts/lib/dev-cycle-read.sh:1759`). My benchmark of it was blocked by a Claude Code safety check before it ran, so neither figure was measured. To verify it, time that match against strings of 28 KB and of IMPORT_OUT_MAX bytes.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1759`

---

## Claim 5: "A malformed Paths: line shows only as the same reason on every non-own deny line, while --status still prints POLICY self-merge"

**Location:** `docs/reviews/override-log.md:612`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers srules' malformed branch and status_line's policy test. Does not establish what U3 or U4 will need.
**Legibility-target:** for-orchestrator-synthesis

The reason is set per path: `[[ -z "$PATHS_WHY" ]] || { DENY="the brief's Paths: line $PATHS_WHY, so only its own files land"; return 0; }` (`scripts/build-loop.sh:666`). status_line's policy depends only on Policy:, not Paths:: `[[ "$POLICY" == self-merge && "${BRIEF[policy]-}" == "Policy: self-merge" ]] && pol=self-merge` (`scripts/build-loop.sh:501`). The malformed-line test passes in E2 (`$S/full-build-loop-check.txt`).

**Evidence:** `scripts/build-loop.sh:501`, `scripts/build-loop.sh:658-670`, `test/scripts/build-loop-check.bats:1967-1978`, `$S/full-build-loop-check.txt`

---

## Claim 6: "The concrete slip (a failed re-read printed no path line) is fixed: it now lands only own files with every line printed."

**Location:** `docs/reviews/override-log.md:613`
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what --check does at 9e7c61c5 when the brief re-read fails. Does not establish the verdict-chain deferral the row records.
**Legibility-target:** for-author

The row describes d435100e. Commit 9e7c61c5 (C1) changed the behaviour, and the row was not amended. A failed re-read now sets a verdict refusal:

```
scripts/build-loop.sh:817
    if brief_fields "$a"; then read_paths; else PATHS=(); PATHS_WHY="could not be read again"; co="${co:-refuse $a: the brief could not be read again from the default branch}"; fi
```

So nothing lands. E4 (`$S/run-c1.txt`) prints `status=2` and `refuse …: the brief could not be read again from the default branch`, followed by a `path` line for the own file and a `deny` line for the listed one. "Every line printed" still holds; "lands only own files" does not. The row should read "refuses the verdict, every path line printed".

**Evidence:** `scripts/build-loop.sh:812-819`, `docs/reviews/override-log.md:613`, `$S/run-c1.txt`

---

## Claim 7: "The lib's caller contract item 5 and FLOOR_WHY's comment name build-loop.sh's nrules and srules"

**Location:** `docs/reviews/override-log.md:614`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the lib text names the caller's rules. Does not judge whether naming them is right (a matter of design).
**Legibility-target:** for-orchestrator-synthesis

Item 5 says "build-loop.sh's N rules apply them … and its S rules run floor only on a path they pass" (`scripts/lib/dev-cycle-read.sh:82-83`). FLOOR_WHY's comment says `# read by floor's caller (build-loop.sh srules)` (`:1825`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:76-85`, `scripts/lib/dev-cycle-read.sh:1825`

---

## Claim 8: "check_line's `local -x LC_ALL=C` is dynamic: status_line runs under C in --check but under the caller's locale in --status"

**Location:** `docs/reviews/override-log.md:615`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the locale scoping. Does not establish the row's reason that every regex in status_line is safe under any locale (only marker_kind's grep was read for that).
**Legibility-target:** for-orchestrator-synthesis

In --check, check_line sets `local -x LC_ALL=C` (`scripts/build-loop.sh:771`) and then runs `out="$(status_line "$a")"` (`:774`). In --status, the script calls `for a in "${ARGS[@]}"; do status_line "$a"; done` (`:843`) with no locale set. marker_kind's grep runs under `LC_ALL=C grep -qxE` (`:482`).

**Evidence:** `scripts/build-loop.sh:482`, `scripts/build-loop.sh:771-774`, `scripts/build-loop.sh:841-844`

---

## Claim 9: "list_entries now parses both Self-merge never: and Paths: (and Paths: takes "none" as the settings lists do). The lib's reader_settings keeps its own copy"

**Location:** `docs/reviews/override-log.md:616`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers list_entries' two callers and reader_settings' separate parser. Does not establish that the two grammars are identical.
**Legibility-target:** for-orchestrator-synthesis

The two callers are `list_entries "$t" "Self-merge never" glob globform` (`scripts/build-loop.sh:418`) and `list_entries "${BRIEF[paths]}" Paths path pathform` (`:630`). reader_settings still parses its own lines: `IFS=' ' read -ra ps <<<"$v"; i=0; rd_seen=()` and `elif [[ "$v" != none ]]; then` (lib reader_settings body, lines 24-25 of the function). list_entries reads `none` as the empty list: `[[ "$v" != none ]] || return 0` (`scripts/build-loop.sh:370`).

**Evidence:** `scripts/build-loop.sh:364-379`, `scripts/build-loop.sh:418`, `scripts/build-loop.sh:630`, `scripts/lib/dev-cycle-read.sh` (reader_settings)

---

## Claim 10: "list_entries depends on nothing in build-loop.sh (pathform, globform's NAMECHARS are the lib's)"

**Location:** `docs/reviews/override-log.md:617`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers list_entries' own body. Does not establish that its FORM argument `globform` could move with it, since globform is defined in build-loop.sh.
**Legibility-target:** for-orchestrator-synthesis

list_entries touches only its arguments and its own globals (`LIST`, `LIST_WHY`, `LIST_BAD`), and calls `"$4" "${e%/}"` (`scripts/build-loop.sh:374`). globform is `globform() {` at `scripts/build-loop.sh:382`, and it uses the lib's `$NAMECHARS` (`[[ "$1" =~ ^[*?$NAMECHARS]+$ …`, `:384`).

**Evidence:** `scripts/build-loop.sh:363-391`

---

## Claim 11: "`Paths: P…` (`Paths: none` or no line lists none; a malformed or duplicate entry lands only the brief's own files: U2c1)"

**Location:** `docs/working/plan-build-loop-handoff.md:238`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers read_paths, list_entries and srules for each case. Does not establish behaviour under review policy, where the S rules never run.
**Legibility-target:** for-orchestrator-synthesis

The cases map to code as follows:

- No line: `[[ -n "${BRIEF[paths]+set}" ]] || return 0` (`scripts/build-loop.sh:629`).
- `none`: `[[ "$v" != none ]] || return 0` (`:370`).
- A duplicate: `LIST_WHY="lists entry $i twice"` (`:375`).
- A malformed line: srules keeps own files (`! ownfile "$2" "$1" "$4" || return 0`, `:665`) before the PATHS_WHY refusal (`:666`).

All seven cases of the malformed-line test pass in E2.

**Evidence:** `scripts/build-loop.sh:364-379`, `scripts/build-loop.sh:627-632`, `scripts/build-loop.sh:658-670`, `test/scripts/build-loop-check.bats:1967-1978`, `$S/full-build-loop-check.txt`

---

## Claim 12: plan U2c1 bullet: floor "only when `co` is empty"; never glob "lower-cased; `*` and `?` match within one part"; "a malformed line lands only own files"; "an own file counts only when the diff spells it in lower case"; "check_line runs in the parent shell (output to a file) … (a test counts the worktree listings of two self-merge briefs), under `LC_ALL=C`"

**Location:** `docs/working/plan-build-loop-handoff.md:311`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed behaviour and the import_reset test. Does not establish the "Carried" rows' own past wording.
**Legibility-target:** for-orchestrator-synthesis

The code for each part:

- The floor runs only with an empty `co`: `if [[ -z "$5" ]] && floor "$2" "$1" "$4"; then` (`scripts/build-loop.sh:661`).
- check_line's output goes to a file: `check_line "$a" > "$GATE_TMP/line"` (`:858`).

Three mutations show the tests catch the rest:

- M1, without import_reset: the worktree-listing count fails, with one listing instead of two (`$S/run-m1.txt`).
- M2, without LC_ALL=C: the C.utf8 part fails (`$S/run-m2.txt`).
- The lower-case own-file rule: the malformed-line test denies `Docs/Working/Plan-2026-10-01-x.md` (E2).

**Evidence:** `scripts/build-loop.sh:658-670`, `scripts/build-loop.sh:769-772`, `scripts/build-loop.sh:855-860`, `test/scripts/build-loop-check.bats:2004-2016`, `$S/run-m1.txt`, `$S/run-m2.txt`

---

## Claim 13: U2c2 bullet: "floor's per-path cost: … (i1 performance: 6.4 ms per path, 400 paths 3.1 s against main's 0.3 s; the forks in lower and need_root, not row 470's membership test)"

**Location:** `docs/working/plan-build-loop-handoff.md:312`
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the per-path cost, the 400-path timing, and the claim that lower and need_root are the largest share. Does not establish the membership test's own cost (claim 4).
**Legibility-target:** for-orchestrator-synthesis

E5 measured 3.02–3.05 s on the branch against 0.33 s on main for 400 paths, about 6.4 ms per path. E3 measured floor at 6.6 ms, with two lower calls and four need_root calls taking about 4.4 ms of that. The bullet gives no count, so the miscount in claim 3a does not apply here.

**Evidence:** `$S/timing.out`, `$S/bench2.out`, `$S/count.out`

---

## Claim 14: "After an ok line, a K of N refusal or a checkout refusal, one line per path …" with "(… not run over a checkout refused above)"

**Location:** `scripts/build-loop.sh:155`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which verdict lines are followed by path lines, and when floor is skipped. Does not establish the refuse list's text at :114-116, whose "it … could not be read again" is pre-existing and ambiguous between the branch and the brief.
**Legibility-target:** for-author

The list leaves out C1's new refusal. When the brief re-read fails, `co` is set to `refuse $a: the brief could not be read again from the default branch` (`scripts/build-loop.sh:817`). check_line then prints the path and deny lines, and floor is skipped as it is for a refused checkout (`srules … "$co"`, `:833`; `[[ -z "$5" ]] && floor`, `:661`). E4 shows exactly this (`$S/run-c1.txt`). The sentence should read "an ok line, a K of N refusal, a checkout refusal or a brief re-read refusal". The floor clause at `:179` should also name the re-read refusal.

**Evidence:** `scripts/build-loop.sh:113-116`, `scripts/build-loop.sh:155`, `scripts/build-loop.sh:179`, `scripts/build-loop.sh:812-837`, `$S/run-c1.txt`

---

## Claim 15: N rules: "the dev cycle's own files (… anything under docs/working/briefs/ or docs/working/cycles/, or either as a file) and docs/constraints.md, or a path below one of those names"

**Location:** `scripts/build-loop.sh:167-172`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the regex arm and the parent-path loop, which tests the cycle, settings and user words. Does not establish that truthrule's earlier words (instr, dot) never hide a covered ancestor; none do today.
**Legibility-target:** for-orchestrator-synthesis

The regex arm is `^docs/working/(briefs|cycles)(/|$)` (`scripts/build-loop.sh:614`). The parent-path loop is:

```
scripts/build-loop.sh:616-619
    while [[ -z "$DENY" && "$d" == */* ]]; do
      d="${d%/*}"; truthrule "$d" || true
      [[ ! "$TRUTH_WHY" =~ ^(cycle|settings|user)$ ]] || DENY="a path below the name of one of the dev cycle's own files or the constraints doc"
    done
```

The loop covers exactly the names the cycle/settings/user arm covers. Anything under briefs/ or cycles/ is already caught by the regex arm. With the loop removed (M3), the row-523 test fails: `docs/roadmap.md/f`, `docs/constraints.md/f`, `Docs/Dev-Cycle.md/x` and `docs/working/questions.md/a/b` all print `path` (`$S/run-m3.txt`).

**Evidence:** `scripts/build-loop.sh:597-621`, `scripts/lib/dev-cycle-read.sh:1777-1787`, `$S/run-m3.txt`

---

## Claim 16: "Then the S rules, for a brief --status reads as self-merge, on each path the N rules pass but the brief's own file (first match): the self-merge floor (… instruction and prompt files and what they import with @, dot paths, the gate's own code, the user's and the cycle's records, a working doc or review that is not the brief's own …)"

**Location:** `scripts/build-loop.sh:173-179`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the call condition, the first-match order and floor's categories. Does not establish floor's failure words (a lower or walk failure refuses every path) beyond the readers line's mention of them.
**Legibility-target:** for-orchestrator-synthesis

The call condition is `[[ -n "$DENY" || "$pol" != self-merge || "$p" == "$a" ]] || srules …` (`scripts/build-loop.sh:833`). The order is floor, then the never loop, then ownfile, then PATHS (`:661-669`). floor's arms are instr, dot, user, record, cycle, GATE_CODE, docs/thoughts/, docs/working/ and docs/reviews/ not own, and truthwalk (`scripts/lib/dev-cycle-read.sh:1832-1849`). The T10 test exercises each category and passes in E2.

**Evidence:** `scripts/build-loop.sh:658-670`, `scripts/build-loop.sh:833`, `scripts/lib/dev-cycle-read.sh:1827-1850`, `test/scripts/build-loop-check.bats:1948-1965`

---

## Claim 17: "a glob of --settings' never line, compared lower-cased, * and ? within one part, matching the path or a directory above it"

**Location:** `scripts/build-loop.sh:179-181`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the regex built from every character globform admits (letters, digits, `. _ - / * ?`). Does not establish behaviour for a glob globform refuses, since read_settings turns self-merge off then.
**Legibility-target:** for-orchestrator-synthesis

never_res builds each regex as `case "$c" in '*') re+='[^/]*' ;; '?') re+='[^/]' ;; .) re+='\.' ;; *) re+="$c" ;; esac` and then `NEVER_RES+=("^$re(/|\$)")` (`scripts/build-loop.sh:644-646`), after `g="$(lower "${g%/}")"`. srules matches it against `$3`, the lower-cased path (`:663`). `-`, `_` and `/` are literal in an ERE outside a bracket. Checks that ran:

- T45 passes (E2).
- P1, extra cases (`$S/run-p1.txt`):
  - `docs/?.txt` denies `docs/a.txt` and passes `docs/ab.txt` and `docs/q/x.txt`;
  - `a-b_c.md` denies itself and passes `axb_c.md`.

**Evidence:** `scripts/build-loop.sh:633-647`, `scripts/build-loop.sh:662-664`, `test/scripts/build-loop-check.bats:1980-1991`, `$S/run-p1.txt`

---

## Claim 18: "a path neither listed in the brief's first "Paths:" line nor one of its own files (…; the allowlist takes these only in lower case, though the floor passes any case)"

**Location:** `scripts/build-loop.sh:181-186`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers srules calling ownfile with the path as spelled, and floor calling it lower-cased. Does not establish stems with upper case (SLUG admits none).
**Legibility-target:** for-orchestrator-synthesis

srules calls `! ownfile "$2" "$1" "$4"`, where `$2` is the path as spelled (`scripts/build-loop.sh:665`). floor calls `ownfile "$lp" "$2" "$3"` (`scripts/lib/dev-cycle-read.sh:1843-1844`). "First" holds because brief_fields records only the first match: `if (!(k in got))` (`scripts/lib/dev-cycle-read.sh:398`). E2 shows the malformed-line test denying `Docs/Working/Plan-2026-10-01-x.md` and passing the lower-case spelling.

**Evidence:** `scripts/build-loop.sh:665`, `scripts/lib/dev-cycle-read.sh:386-409`, `scripts/lib/dev-cycle-read.sh:1843-1844`, `test/scripts/build-loop-check.bats:1967-1978`

---

## Claim 19: ""Paths: P ..." lists paths pathform allows, with single spaces, each once, compared exactly (a trailing / makes a directory, matched at a part boundary; unlike a never glob, an entry without one matches that file alone); "Paths: none" or no line lists none; any other line is malformed, and only own files land."

**Location:** `scripts/build-loop.sh:186-191`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers list_entries' grammar and srules' match. Does not establish behaviour for a CR-ended line (brief_fields strips one CR first, `sub(/\r$/, "")`).
**Legibility-target:** for-orchestrator-synthesis

The match is `[[ "$2" != "$e" && ( "$e" != */ || "$2" != "$e"* ) ]] || return 0` (`scripts/build-loop.sh:668`). A bare `Paths:` fails `"$1" != "$2: "*` (`:369`). In T10, `docs/a` matches the file alone (`path … docs/a`) and `docs/ab.md` is denied. The malformed cases also pass: bare `Paths:`, a double space, `..`, a leading `/` and a duplicate (E2).

**Evidence:** `scripts/build-loop.sh:364-379`, `scripts/build-loop.sh:666-669`, `test/scripts/build-loop-check.bats:1948-1978`

---

## Claim 20: "A --check can also stop part way, after the lines of the briefs before, with 1 (need_root) or a failed command's own status: a caller reads any exit but 0 as nothing decided."

**Location:** `scripts/build-loop.sh:199-204`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers need_root's exit inside check_line, run in the parent shell. Does not establish a test for the failed-command branch; that rests on `set -euo pipefail` (`:206`) and a plain call of check_line.
**Legibility-target:** for-orchestrator-synthesis

M5 forces need_root to fail in brief y's floor. The run exits 1, prints only brief x's two lines, and writes `ROOT_REAL is not the current directory` to stderr (`$S/run-m5.txt`, ok). Brief y's partial lines went to `$GATE_TMP/line` and were never shown (`check_line "$a" > "$GATE_TMP/line"; cat "$GATE_TMP/line"`, `:858`).

**Evidence:** `scripts/build-loop.sh:199-206`, `scripts/build-loop.sh:852-861`, `scripts/lib/dev-cycle-read.sh:160-164`, `$S/run-m5.txt`

---

## Claim 21: "list_entries LINE KEY WORD FORM: … LINE is exactly "KEY: none" or "KEY: E ..." with single spaces …, and each E, a trailing / dropped, passes FORM … and is listed once. Sets LIST (the entries as written, a trailing / kept; empty for none) or LIST_WHY, and LIST_BAD to form (the line's shape) or entry (an entry), or empty."

**Location:** `scripts/build-loop.sh:357-362`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the whole function at `:364-379`. Does not establish callers' use beyond the two in claim 9.
**Legibility-target:** for-orchestrator-synthesis

The form branch is `LIST_WHY="is not exactly \"$2: ${3^^} ...\" with single spaces"; LIST_BAD=form; return 0` (`:369`). Each entry is checked with `"$4" "${e%/}"` and `seen[${e%/}]` (`:374-376`). On any entry error, `[[ -z "$LIST_WHY" ]] || { LIST=(); LIST_BAD=entry; }` (`:378`). LIST keeps the entries as written.

**Evidence:** `scripts/build-loop.sh:357-379`

---

## Claim 22: "The form reason comes first, then the next line, then the entries." (read_settings' never line, reasons and precedence unchanged)

**Location:** `scripts/build-loop.sh:419`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the order of reasons and NEVER/NEVER_LINE against main's elif chain. Does not establish anything new; the --settings text is unchanged.
**Legibility-target:** for-orchestrator-synthesis

The code is `why="$LIST_WHY"`, then `if [[ "$LIST_BAD" != form && "${next[never]}" != 1 ]]; then why="is followed by …"` (`:418-420`). So the next-line reason replaces an entry reason or `none`, but never the form reason. Main's chain had the same order (paraphrased — no quote available because it is the removed `-` block shown in `git diff main...HEAD -- scripts/build-loop.sh`). `${#LIST[@]} -eq 0` is reached only for `none` (`:422`). build-loop-read passes 20/20 (E2).

**Evidence:** `scripts/build-loop.sh:413-424`, `$S/full-build-loop-read.txt`

---

## Claim 23: nrules comment: "so does a path below one of those names (docs/roadmap.md/x, which main may lack, would keep the cycle from writing the file: row 523). srules adds the S rules."

**Location:** `scripts/build-loop.sh:593-595`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the parent-path loop (claim 15). Does not establish the consequence for the cycle.
**Legibility-target:** for-orchestrator-synthesis

The loop is quoted in claim 15 (`scripts/build-loop.sh:616-619`). M3 removes it and the test fails (`$S/run-m3.txt`).

**Evidence:** `scripts/build-loop.sh:586-621`, `$S/run-m3.txt`

---

## Claim 24: read_paths: "from BRIEF[paths] … "Paths: none", or no line, lists none. Sets PATHS or, for a malformed line, PATHS_WHY (which lands only the brief's own files)."

**Location:** `scripts/build-loop.sh:622-625`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the function at `:627-632`. Does not establish the re-read failure branch, where check_line sets PATHS itself (`:817`).
**Legibility-target:** for-orchestrator-synthesis

The function is `PATHS=(); PATHS_WHY=""`, then `[[ -n "${BRIEF[paths]+set}" ]] || return 0`, then `list_entries …; PATHS=("${LIST[@]}"); PATHS_WHY="$LIST_WHY"` (`:628-631`).

**Evidence:** `scripts/build-loop.sh:622-632`

---

## Claim 25: "NEVER's globs as regexes for a lower-cased path …: * and ? match within one part, and a glob matches the path or any directory above it (a trailing / changes nothing). Set once, after read_settings."

**Location:** `scripts/build-loop.sh:633-635`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers never_res and its single call site. Does not establish that `--status` builds it; it does not, and does not need it.
**Legibility-target:** for-orchestrator-synthesis

The trailing `/` is dropped by `g="$(lower "${g%/}")"` (`:643`). The only call site is `read_settings; never_res` (`:850`). P1 and T45 pass (claim 17).

**Evidence:** `scripts/build-loop.sh:636-647`, `scripts/build-loop.sh:850`, `$S/run-p1.txt`

---

## Claim 26: srules comment: "Sets DENY, first match winning: the floor (only when $5 is empty: it walks the checkout), a Self-merge never: glob, then the allowlist (Paths:, or ownfile). … ownfile gets the path as spelled, so an own file passes only when the diff spells it in lower case (ownfile folds nothing)."

**Location:** `scripts/build-loop.sh:649-657`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers srules at `:658-670`. Does not establish callers' arguments beyond `:833`.
**Legibility-target:** for-orchestrator-synthesis

Each step returns at its first match (`return 0` at `:661`, `:663`, `:665`, `:666`, `:668`). ownfile's patterns are lower-case literals: `^docs/working/(research|plan|checkpoint|handoff|test-strategy)-(.+)\.md$` (`scripts/lib/dev-cycle-read.sh:1809`).

**Evidence:** `scripts/build-loop.sh:649-670`, `scripts/build-loop.sh:833`, `scripts/lib/dev-cycle-read.sh:1806-1811`

---

## Claim 27: checkout_gate comment: "check_line calls it for each self-merge brief once the merge and its changed paths are read, before the N rules and the floor walk run per path"

**Location:** `scripts/build-loop.sh:677-679`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the order of calls in check_line. Does not establish checkout_gate's internals.
**Legibility-target:** for-orchestrator-synthesis

checkout_gate runs at `:811` (`co=""; if [[ "$pol" == self-merge ]] && ! checkout_gate; then …`), before the per-path loop at `:831-835`.

**Evidence:** `scripts/build-loop.sh:811`, `scripts/build-loop.sh:831-835`

---

## Claim 28: "It runs in the caller's shell, so an exit (need_root's) ends the run, and set -e applies to its own lines but not inside a helper called in a condition (floor and its walk, brief_fields, checkout_gate, nul_list) or in $(...), which refuse by their own guards."

**Location:** `scripts/build-loop.sh:761-764`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the call contexts of the four named helpers and bash's errexit rules without inherit_errexit. Does not establish that the named list is complete (srules, the last command after `||` at `:833`, does run under set -e).
**Legibility-target:** for-orchestrator-synthesis

All four helpers run as conditions:

- floor: `[[ -z "$5" ]] && floor …` inside `if` (`:661`);
- brief_fields: `if brief_fields "$a"` (`:817`);
- checkout_gate: `! checkout_gate` (`:811`);
- nul_list: `if ! nul_list lps …` (`:829`).

The scripts never enable inherit_errexit (paraphrased — no quote available because the claim is about absence: `rg -n "inherit_errexit|shopt"` over both scripts returns nothing). The exit path was run in M5 (claim 20).

**Evidence:** `scripts/build-loop.sh:811`, `scripts/build-loop.sh:817`, `scripts/build-loop.sh:829`, `scripts/build-loop.sh:661`, `$S/run-m5.txt`

---

## Claim 29: "Nothing but its locals and the walk caches it resets may carry from one brief to the next: each helper empties its own globals before use (DENY, PATHS and PATHS_WHY, LIST and LIST_WHY, BRIEF, CHECKOUT_WHY, FLOOR_WHY, TRUTH_WHY)."

**Location:** `scripts/build-loop.sh:765-768`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the reset at the top of each named helper. Does not establish lib globals outside the list (FILE_OUT, SKIPPED and the like), which this run did not audit.
**Legibility-target:** for-orchestrator-synthesis

The resets:

| Global | Reset | Location |
|---|---|---|
| DENY | `DENY=""` | nrules `:599`, srules `:660` |
| PATHS, PATHS_WHY | `PATHS=(); PATHS_WHY=""` | `:628` |
| LIST, LIST_WHY | `LIST=(); LIST_WHY=""; LIST_BAD=""` | `:367` |
| BRIEF | `BRIEF=(); BRIEF_ODD=""` | lib `:390` |
| FLOOR_WHY | `FLOOR_WHY=""` | lib `:1830` |
| TRUTH_WHY | `TRUTH_WHY=""` | lib `:1778` |
| CHECKOUT_WHY | `CHECKOUT_WHY=""` | checkout_gate's first statement |

A review brief can leave stale PATHS behind, but srules never runs for review (`"$pol" != self-merge`, `:833`). The walk caches are reset by `import_reset` (`:773`).

**Evidence:** `scripts/build-loop.sh:367`, `scripts/build-loop.sh:599`, `scripts/build-loop.sh:628`, `scripts/build-loop.sh:660`, `scripts/build-loop.sh:773`, `scripts/build-loop.sh:833`, `scripts/lib/dev-cycle-read.sh:390`, `scripts/lib/dev-cycle-read.sh:1778`, `scripts/lib/dev-cycle-read.sh:1830`

---

## Claim 30: "# Contract item 1 (the floor's walk); exported, so its children run under it too." `local -x LC_ALL=C`

**Location:** `scripts/build-loop.sh:770-771`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the C.utf8 case the test exercises (the `C.utf8` locale is installed here, per `locale -a`). Does not establish other locales.
**Legibility-target:** for-orchestrator-synthesis

With the line removed (M2), `LC_ALL=C.utf8 chk` gives status 2 with `the default branch's instruction files could not be walked for @ imports` (`$S/run-m2.txt`). With the line in place, it passes (E2).

**Evidence:** `scripts/build-loop.sh:769-773`, `test/scripts/build-loop-check.bats:2012-2015`, `$S/run-m2.txt`

---

## Claim 31: "A failed read refuses the verdict as a checkout refusal does (path lines still print, the floor does not run)."

**Location:** `scripts/build-loop.sh:814-815`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the forced re-read failure. Does not establish which real conditions cause one (only a transient git or awk failure).
**Legibility-target:** for-orchestrator-synthesis

E4 forces `if brief_fields "$a"` to `if false`. The output is: `status=2`, the `refuse …: the brief could not be read again from the default branch` line, `path … A docs/working/plan-2026-10-01-x.md`, and `deny … A work-feat-x.txt: the brief's Paths: line could not be read again, so only its own files land` (`$S/run-c1.txt`). The floor does not run because `co` is non-empty (`:661`).

**Evidence:** `scripts/build-loop.sh:812-819`, `scripts/build-loop.sh:661`, `$S/run-c1.txt`

---

## Claim 32: "In this shell, not $(...): the floor's need_root exit ends the run, and check_line's import_reset is what keeps one brief's walk from the next."

**Location:** `scripts/build-loop.sh:856-857`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers M1 and M5. Does not establish anything about --status, which has no walk.
**Legibility-target:** for-orchestrator-synthesis

M1 removes import_reset, and two self-merge briefs then list the worktrees once instead of twice (`$S/run-m1.txt`: one `worktree list` line). M5 shows the exit (claim 20).

**Evidence:** `scripts/build-loop.sh:855-860`, `$S/run-m1.txt`, `$S/run-m5.txt`

---

## Claim 33: "open_shared  # once, in this shell: status_line runs in a subshell"

**Location:** `scripts/build-loop.sh:851`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers where status_line runs. Does not establish open_shared's caching.
**Legibility-target:** for-orchestrator-synthesis

check_line runs `out="$(status_line "$a")"` (`:774`), a subshell, and status_line calls `open_shared` (`:487`).

**Evidence:** `scripts/build-loop.sh:485-488`, `scripts/build-loop.sh:774`, `scripts/build-loop.sh:851`

---

## Claim 34: lib header item 3: "(U2b2; its check_line runs the walk under item 1's LC_ALL=C)"

**Location:** `scripts/lib/dev-cycle-read.sh:63`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `local -x LC_ALL=C` in check_line. Does not establish other callers of the walk.
**Legibility-target:** for-orchestrator-synthesis

The line is `local -x LC_ALL=C` (`scripts/build-loop.sh:771`). M2 shows the test depends on it (claim 30).

**Evidence:** `scripts/build-loop.sh:771`, `$S/run-m2.txt`

---

## Claim 35: lib header item 5: "build-loop.sh reads diff-tree -r of main and the merge instead, where a symlink or gitlink above a path is a changed entry of its own. … its S rules run floor only on a path they pass"

**Location:** `scripts/lib/dev-cycle-read.sh:79-83`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the case where a directory is replaced by a symlink, on git 2.39.5. Does not establish a test for the gitlink variant (same tree rule: one name cannot be both a tree and a link).
**Legibility-target:** for-orchestrator-synthesis

E1's diff-tree probe replaces directory `a/` with a symlink `a`. The output is `:000000 120000 … A	a` and `:100644 000000 … D	a/x` (`$S/difftree.txt`). The link is its own A entry, and the N rules deny it by mode (`scripts/build-loop.sh:601`). srules runs only when DENY is empty (`:833`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:76-85`, `scripts/build-loop.sh:601`, `scripts/build-loop.sh:833`, `$S/difftree.txt`

---

## Claim 36: ownfile: "for a path $1 (it folds no case: floor passes it lower-cased, build-loop.sh srules as spelled)"

**Location:** `scripts/lib/dev-cycle-read.sh:1800-1801`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers ownfile's body and both callers. Does not establish callers outside these two scripts.
**Legibility-target:** for-orchestrator-synthesis

ownfile has no `lower` call (`:1806-1811`). The callers are floor, `ownfile "$lp" "$2" "$3"` (`:1843-1844`), and srules, `ownfile "$2" "$1" "$4"` (`scripts/build-loop.sh:665`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1806-1811`, `scripts/lib/dev-cycle-read.sh:1843-1844`, `scripts/build-loop.sh:665`

---

## Claim 37: "FLOOR_WHY=""  # read by floor's caller (build-loop.sh srules)"

**Location:** `scripts/lib/dev-cycle-read.sh:1825`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the reader in build-loop.sh. Does not establish readers in test code.
**Legibility-target:** for-orchestrator-synthesis

srules reads it: `DENY="$FLOOR_WHY"` (`scripts/build-loop.sh:661`).

**Evidence:** `scripts/build-loop.sh:661`

---

## Claim 38: test title "--check self-merges listed paths (exec bit, a directory entry), the brief's own working docs and added reviews, and its Status line (T9, U2c1)"

**Location:** `test/scripts/build-loop-check.bats:1938`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each part of the title against the test's assertions. Does not establish coverage of handoff- or test-strategy- docs.
**Legibility-target:** for-orchestrator-synthesis

The parts of the title map to the test as follows:

- Exec bit: `chmod +x scripts/other.sh`.
- Directory entries: `skills/x/` and `test/`.
- Own working docs: research, plan and checkpoint.
- Added reviews: `docs/reviews/2026-10-01-x.md` and `code-review-2026-10-01-x.md`.
- Status line: `has "path $B M $B"`.
- Line count: 13 lines (one verdict and 12 paths).

The test passes in E2.

**Evidence:** `test/scripts/build-loop-check.bats:1938-1946`, `$S/full-build-loop-check.txt`

---

## Claim 39: test title "--check refuses a self-merge path the floor names though Paths: lists it, a symlink at a listed path, and a path Paths: does not list exactly (T10, rows 349, 474, U2c1)"

**Location:** `test/scripts/build-loop-check.bats:1948`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the asserted deny lines. Does not establish a gitlink case (row 474 is named, but only the symlink is asserted).
**Legibility-target:** for-orchestrator-synthesis

The first 11 floor paths are listed (`${fl[*]:0:11}`), and the two reviews are covered by `docs/reviews/`. The listed symlink is denied by mode (`deny $B A scripts/link.sh: $NMODE`). `docs/ab.md`, `Hooks/x.sh` and `scripts/x.sh` are denied as not listed. The count is `nref 17 18`. The test passes in E2.

**Evidence:** `test/scripts/build-loop-check.bats:1948-1965`

---

## Claim 40: test title "--check: a malformed Paths: line lands only the brief's own files, spelled in lower case; Paths: none or no line lists nothing (T10, U2c1 i1)"

**Location:** `test/scripts/build-loop-check.bats:1967`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the seven cases. Does not establish a malformed line with an upper-case own file under a valid line.
**Legibility-target:** for-orchestrator-synthesis

Each case asserts `deny … docs/a`, `deny … Docs/Working/Plan-…` and `path … docs/working/plan-…`. For `Paths: none` and no line, the reason is `$NLIST`. The test passes in E2.

**Evidence:** `test/scripts/build-loop-check.bats:1967-1978`

---

## Claim 41: test title "--check: a Self-merge never: glob refuses a listed path under self-merge, by part and in any case; review ignores it (T45, U2c1)"

**Location:** `test/scripts/build-loop-check.bats:1980`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the asserted lines. Does not establish `?` (P1 covers it).
**Legibility-target:** for-orchestrator-synthesis

"In any case": `Workflows/Z.md` is denied. "By part": `docs/sub/n.txt` and `workflowsx.md` pass. Under review, status is 0 and 7 lines print. The test passes in E2.

**Evidence:** `test/scripts/build-loop-check.bats:1980-1991`

---

## Claim 42: test title "--check refuses a path below a cycle file's or the constraints doc's name, and cycles/ as a file (an N rule; row 523, U2c1)"

**Location:** `test/scripts/build-loop-check.bats:1993`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four parent-name cases and `docs/working/cycles` as a file. Does not establish `briefs` as a file (not in the title).
**Legibility-target:** for-orchestrator-synthesis

The test passes in E2, and fails with the loop removed (M3, `$S/run-m3.txt`).

**Evidence:** `test/scripts/build-loop-check.bats:1993-2002`, `$S/run-m3.txt`

---

## Claim 43: test title "--check walks once per self-merge decision (check_line's import_reset, in the parent shell) and under the C locale (contract items 1, 4; row 532, U2c1)"

**Location:** `test/scripts/build-loop-check.bats:2004`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the worktree-listing count (one per walk-registry read) and the C.utf8 case. Does not establish that every walk entry is counted; only `worktree list` calls are.
**Legibility-target:** for-orchestrator-synthesis

M1 (no import_reset) fails the count with 1 (`$S/run-m1.txt`). M2 (no LC_ALL=C) fails the C.utf8 part (`$S/run-m2.txt`). C.utf8 is installed, so the locale case is not vacuous.

**Evidence:** `test/scripts/build-loop-check.bats:2004-2016`, `$S/run-m1.txt`, `$S/run-m2.txt`

---

## Claim 44: commit eddfd5f9: ""Paths:" alone or no line lists none"

**Location:** commit `eddfd5f9` message
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the claim against HEAD. Does not establish anything about eddfd5f9's own code, where it held.
**Legibility-target:** for-author

Commit d435100e made a bare `Paths:` malformed: `[[ "$1" != "$2: "* || …` → `LIST_BAD=form` (`scripts/build-loop.sh:369`). The malformed-line test asserts `"Paths:|is not exactly \"Paths: PATH ...\" with single spaces"` (`test/scripts/build-loop-check.bats:1970`). The outcome is the same (only own files land), but the reason differs. The commit is immutable, so this needs an Accepted-immutable override row, or a note in the merge message.

**Evidence:** `scripts/build-loop.sh:369`, `test/scripts/build-loop-check.bats:1968-1971`

---

## Claim 45: commit eddfd5f9: "Tests: build-loop-check 138, build-loop-read 20, dev-cycle 79, fixture-git-env 2, fixture-hermeticity 2. 229 changed code lines."

**Location:** commit `eddfd5f9` message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the counts at HEAD (the same for build-loop-check at eddfd5f9) and eddfd5f9's numstat. Does not establish that the dev-cycle and fixture suites passed at eddfd5f9 (counted, not run here).
**Legibility-target:** for-orchestrator-synthesis

The test counts check out:

- `bats --count` gives 138, 20, 79, 2 and 2 (`$S/counts.txt`).
- `eddfd5f9:test/scripts/build-loop-check.bats` holds 138 `@test` lines.

The line count checks out too. `git diff --numstat` for eddfd5f9 against main gives build-loop.sh 105/15, the lib 12/9 and the bats file 87/1, a sum of 229, with the plan's 3/0 left out. This could be a repeat of the logged commit-tally patterns ("All 85 tests", "mode1-equiv 33"); it is not one, since every figure checks out.

**Evidence:** `$S/counts.txt`, `$S/full-summary.txt`

---

## Claim 46: commit eddfd5f9: "Timing on a 3,284-file clone: 3.6 s for 1 path, 6.1 s for 150, 7.6 s for 400."

**Location:** commit `eddfd5f9` message
**Type:** Performance
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers nothing about that clone. E5's 3,000-file fixture gives different absolute numbers (0.47/1.42/3.03 s) because its walk is smaller.
**Legibility-target:** for-orchestrator-synthesis

The named clone and briefs are not in the repo (paraphrased — no quote available because the claim concerns a measurement environment absent from the repository). Rubric B11 already records this.

**Evidence:** `$S/timing.out`

---

## Claim 47: commit 9e7c61c5: "C1: a failed brief re-read refuses the verdict (path lines still print)."

**Location:** commit `9e7c61c5` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers E4. Does not establish the rest of the message (C2–C5), which claims 21, 22, 36, 28 and 10 cover.
**Legibility-target:** for-orchestrator-synthesis

See claim 31 (`$S/run-c1.txt`).

**Evidence:** `scripts/build-loop.sh:817`, `$S/run-c1.txt`

---

## Claims Requiring Attention

### Incorrect
- **Claim 3a** (`docs/reviews/override-log.md:610`): one cached floor call runs need_root **4** times, not twice: floor, isimported and main_imports twice. Two lower calls and four need_root calls measure about 4.4 ms of floor's 6.6 ms, not 5.7 of 6.4. Correct the row in a new row, and make U2c2's "one root check per decision" cover all four calls.

### Stale
- **Claim 6** (`docs/reviews/override-log.md:613`): "it now lands only own files" predates C1. A failed re-read now refuses the verdict, with every line printed.
- **Claim 44** (commit eddfd5f9): "'Paths:' alone … lists none" was superseded by d435100e (bare `Paths:` is malformed). The commit is immutable, so this needs an Accepted-immutable row or a note in the merge message.

### Mostly Accurate
- **Claim 14** (`scripts/build-loop.sh:155`, also `:179`): the list of refusals followed by path lines, and the floor's "not run over a checkout refused above", both leave out C1's brief re-read refusal, which behaves the same way.

### Unverifiable
- **Claim 4** (`docs/reviews/override-log.md:611`): the glob-test timings. My benchmark was blocked by a Claude Code safety check. To check them, time the `*$'\n'"$lp"$'\n'*` match on strings of 28 KB and of IMPORT_OUT_MAX bytes.
- **Claim 46** (commit eddfd5f9): the timings need the 3,284-file clone, which is not in the repo.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the output path your dispatch names, structured per your skill, every finding with verbatim Evidence and a path:line.
- Answered: yes. All 7 claim groups in the final brief are checked, 27 of 48 claims by execution: both full suites, four mutations, two probes, timing and a call count.
- Out of scope: the review reports under docs/reviews/ (artifacts); dev-cycle and fixture suites were counted, not run, because the branch does not touch them.
- Escalate: claim 3a (the override-row count) and claim 6 (row 613, stale since C1) need new override rows. Claim 14 is a one-line --help fix.
- Decisions I made: I split row 610 into 3a (count and share, Incorrect) and 3b (the 400-path timing, Verified). I counted the --help path-line list's omission as Mostly accurate, not Incorrect, because the refusal it leaves out behaves exactly like one it names.
