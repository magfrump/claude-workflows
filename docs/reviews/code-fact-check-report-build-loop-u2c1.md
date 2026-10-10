# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u2c1 (branch `feat/build-loop-u2c1`)
**Commit:** eddfd5f9
**Replication:** k=1 (loop pass, decision 031)
**Scope:** `git diff main...HEAD`: scripts/build-loop.sh, scripts/lib/dev-cycle-read.sh, test/scripts/build-loop-check.bats, docs/working/plan-build-loop-handoff.md, and the commit message of eddfd5f9
**Checked:** 2026-10-10
**Total claims checked:** 21
**Summary:** 18 verified, 1 mostly accurate, 1 stale, 0 incorrect, 1 unverifiable

Execution logs (scratch dir, captured output; cwd for every run is given per claim). `S=/tmp/claude-1000/-workspace/54247aa5-2a95-449b-b931-3ed456da322c/scratchpad/u2c1-i1-factcheck`:
- `$S/probe.sh` and `$S/probe2.sh`: extracted `git archive eddfd5f9 scripts test` into four copies under a fresh `mktemp -d /tmp/u2c1-factcheck-XXXX` (since removed): `base` (unchanged), `noreset` (check_line's `import_reset` line deleted), `nolcall` (check_line's `local -x LC_ALL=C` deleted), `probes` (three added FCPROBE tests, `$S/probe-tests.bats.part`). Each ran `LC_ALL=C TMPDIR=<own dir> timeout 900 bats -f 'U2c1' test/scripts/build-loop-check.bats` (probes: `-f FCPROBE`) from the copy's root, serially, started 2026-10-10T09:50:49Z. Exit codes: `$S/exits.txt` (base 0, noreset 1, nolcall 1, probes 0, difftree 0). Output: `$S/run-base.txt`, `$S/run-noreset.txt`, `$S/run-nolcall.txt`, `$S/run-probes.txt`, `$S/difftree.txt`.
- `$S/exitprobe.sh` (cwd `$S`, `LC_ALL=C bash exitprobe.sh`, 2026-10-10T09:52:47Z, exit 1): `$S/exitprobe.out`.
- `git diff --numstat main...HEAD` (cwd worktree, exit 0): `$S/numstat.txt`; `bats --count` per suite (cwd worktree, exit 0): `$S/counts.txt`.

Hallucination-pattern log read. Claim 18 matches the logged class "per-suite test counts in a commit message" (entries "All 85 tests…", first seen in commit 59ca38f, and "mode1-equiv 33…"); here the counts hold.

---

## Claim 1: "`Paths: P…` (a malformed or duplicate entry means no self-merge)"

**Location:** `docs/working/plan-build-loop-handoff.md:238`
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers what --check does for a self-merge brief whose Paths: line is malformed or lists an entry twice; does not establish whether "no self-merge" was meant to cover own files.

U2c1 made this line out of date. A malformed or duplicate line no longer turns self-merge off. The brief's own files still land:

```bash
# scripts/build-loop.sh:658-659
  ! ownfile "$3" "$1" "$4" || return 0
  [[ -z "$PATHS_WHY" ]] || { DENY="the brief's Paths: line $PATHS_WHY, so only its own files land"; return 0; }
```
(excerpt ends :659; enclosing srules() continues to :664 — read)

The executed test at `test/scripts/build-loop-check.bats:1967` passes (`$S/run-base.txt`, "ok 3"). For `"Paths: docs/a docs/a/"` it asserts `has "path $B A docs/working/plan-2026-10-01-x.md"`, so an own file lands. The U2c1 bullet at plan:311 records the new rule ("a malformed line lands only own files"). Line 238 still gives the old consequence.

**Evidence:** `docs/working/plan-build-loop-handoff.md:238`, `docs/working/plan-build-loop-handoff.md:311`, `scripts/build-loop.sh:651-664`, `test/scripts/build-loop-check.bats:1967-1978`, `$S/run-base.txt`

---

## Claim 2a: "`Paths: P …` (rev 2's grammar): single spaces, pathform entries compared exactly (an allowlist widens nothing by case)"

**Location:** `docs/working/plan-build-loop-handoff.md:311`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers how Paths: entries and own files compare case; does not establish anything about the floor or never globs, which fold case as documented.

Read narrowly, the parenthetical is true: Paths: entries compare byte for byte (`[[ "$2" != "$e" && ( "$e" != */ || "$2" != "$e"* ) ]] || return 0`, `scripts/build-loop.sh:661`). The allowlist's other half does not compare exactly, though. `ownfile` gets the lower-cased spelling: `! ownfile "$3" "$1" "$4"` (`scripts/build-loop.sh:658`, where `$3` is `${lps[$i]}` per `:815`). So an own file in another case lands. Probe FCPROBE 1 (`$S/run-probes.txt`, "ok 1") has brief `2026-10-01-x` with `Paths: docs/a`. It asserts and passes `has "path $B A Docs/Working/Plan-2026-10-01-x.md"`. Precise version: "Paths: entries compare exactly; own files compare lower-cased."

**Evidence:** `scripts/build-loop.sh:658-661`, `scripts/build-loop.sh:815`, `scripts/lib/dev-cycle-read.sh:1805-1810`, `$S/probe-tests.bats.part`, `$S/run-probes.txt`

---

## Claim 2b: U2c1 bullet: S rules for self-merge briefs, floor only when `co` is empty, never globs, allowlist; check_line in the parent shell under LC_ALL=C; "a test counts the worktree listings of two self-merge briefs"

**Location:** `docs/working/plan-build-loop-handoff.md:311`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the bullet's description of build-loop.sh's behaviour and of the new test; does not establish the U2c2 routing decisions (planning, not checkable).

The gate is `[[ -n "$DENY" || "$pol" != self-merge || "$p" == "$a" ]] || srules "$stem" "$p" "${lps[$i]}" "${ss[$i]}" "$co"` (`scripts/build-loop.sh:815`). srules runs `floor` only under `[[ -z "$5" ]]` (`:654`). The listing test is at `test/scripts/build-loop-check.bats:2010` (`grep -c '^worktree list' … -eq 2`). The rest is covered by Claims 4, 10 and 12.

**Evidence:** `scripts/build-loop.sh:651-664`, `scripts/build-loop.sh:755-819`, `test/scripts/build-loop-check.bats:2003-2015`, `$S/run-base.txt`

---

## Claim 3: --help N rules: "anything under docs/working/briefs/ or docs/working/cycles/, or either as a file) and docs/constraints.md, or a path below one of those names"

**Location:** `scripts/build-loop.sh:167-172`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the briefs/cycles regex and the prefix loop over cycle, settings and user names; does not establish an executed briefs-as-a-file case, which a fixture with an open brief cannot build without a directory/file conflict.

```bash
# scripts/build-loop.sh:599-604
      *) [[ ! "$7" =~ ^docs/working/(briefs|cycles)(/|$) ]] || DENY="one of the dev cycle's own files" ;;
    esac
    while [[ -z "$DENY" && "$d" == */* ]]; do
      d="${d%/*}"; truthrule "$d" || true
      [[ ! "$TRUTH_WHY" =~ ^(cycle|settings|user)$ ]] || DENY="a path below the name of one of the dev cycle's own files or the constraints doc"
    done
```
(excerpt ends :604; enclosing nrules() closes at :606 — read)

Test `build-loop-check.bats:1992` passed in the base run ("ok 5"). It covers docs/roadmap.md/f, docs/constraints.md/f, Docs/Dev-Cycle.md/x, docs/working/questions.md/a/b, and docs/working/cycles as a file. For briefs as a file the evidence is static only: the `(/|$)` alternative.

**Evidence:** `scripts/build-loop.sh:167-172`, `scripts/build-loop.sh:582-606`, `test/scripts/build-loop-check.bats:1992-2001`, `$S/run-base.txt`

---

## Claim 4: --help S rules: "(first match): the self-merge floor … not run over a checkout refused above; a glob of --settings' never line, compared lower-cased, * and ? within one part, matching the path or a directory above it; and a path neither listed … nor one of its own files"

**Location:** `scripts/build-loop.sh:173-183`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the order floor → never → allowlist, the co guard, and the never-glob matching; does not establish the floor's full refusal list (lib floor, unchanged here). The help's floor summary ("other briefs' … reviews") leaves out that floor also refuses a *modified* review in this brief's own stem, but the own-files clause ("an added docs/reviews/STEM.md") is consistent with that.

```bash
# scripts/build-loop.sh:654-657
  if [[ -z "$5" ]] && floor "$2" "$1" "$4"; then DENY="$FLOOR_WHY"; return 0; fi
  for re in "${NEVER_RES[@]}"; do
    [[ ! "$3" =~ $re ]] || { DENY="a Self-merge never: glob in docs/dev-cycle.md matches it"; return 0; }
  done
```
(excerpt ends :657; srules() continues to :664 with ownfile, PATHS_WHY, the Paths loop and the final deny — read)

`$5` is `$co` (`:815`), and `$3` is the lower-cased path. Executed: T45 test `:1980` ("ok 4": Workflows/Z.md denied by `workflows/`, docs/sub/n.txt not matched by `docs/*.txt`) and T10 test `:1948` ("ok 2": floor denials though listed).

**Evidence:** `scripts/build-loop.sh:173-183`, `scripts/build-loop.sh:633-664`, `test/scripts/build-loop-check.bats:1948-1990`, `$S/run-base.txt`

---

## Claim 5: --help Paths: grammar: "lists paths pathform allows, with single spaces, each once, compared exactly (a trailing / makes a directory, matched at a part boundary); "Paths:" alone or no line lists none; any other line is malformed, and only own files land"

**Location:** `scripts/build-loop.sh:183-189`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers paths_read's grammar and srules' comparison; does not establish that own files compare exactly (they compare lower-cased: Claim 2a). "Only own files land" also still passes own files through floor and the never globs first.

```bash
# scripts/build-loop.sh:614-620
  local t="${BRIEF[paths]-Paths:}" v e i=0
  local -A seen=()
  PATHS=(); PATHS_WHY=""
  [[ "$t" != "Paths:" ]] || return 0
  v="${t#Paths: }"
  if [[ "$t" != "Paths: "* || ! "$v" =~ ^[^\ ]+(\ [^\ ]+)*$ ]]; then PATHS_WHY='is not exactly "Paths: PATH ..." with single spaces'; return 0; fi
  IFS=' ' read -ra PATHS <<<"$v"  # not a bare $v: the shell would expand * and ? against files
```
(excerpt ends :620; paths_read() continues to :628 with the pathform and duplicate checks on `${e%/}` — read)

Executed: the malformed test `:1967` ("ok 3"), with a duplicate, a double space, `..`, a leading `/`, `Paths:` alone and no line. The part boundary is checked in the T10 test (`docs/a` listed, `docs/ab.md` denied).

**Evidence:** `scripts/build-loop.sh:183-189`, `scripts/build-loop.sh:607-628`, `scripts/build-loop.sh:661`, `test/scripts/build-loop-check.bats:1967-1978`, `$S/run-base.txt`

---

## Claim 6: nrules comment: "so does a path below one of those names (docs/roadmap.md/x, which main may lack, would keep the cycle from writing the file: row 523)"

**Location:** `scripts/build-loop.sh:578-580`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that the prefix loop catches every name that truthrule's cycle, settings and user words cover, plus briefs/ and cycles/ through the regex, and nothing else. Does not establish the design rationale (row 523).

The loop at `:601-604` (quoted in Claim 3) tests every proper prefix with `truthrule` and denies only on `^(cycle|settings|user)$`. The paths below briefs/ and cycles/ are already denied by `^docs/working/(briefs|cycles)(/|$)` at `:599`. The "nothing else" half: the instr, dot and record words never deny in the loop. The reason a cycle name cannot be masked by an earlier word in a prefix is paraphrased — no quote available because it is an invariant inferred from truthrule's order at `scripts/lib/dev-cycle-read.sh:1777-1787`: no cycle, settings or user name has a dot part or is an instruction file, and `$7` is lower-cased so `case` cannot fire. Executed in test `:1992` ("ok 5").

**Evidence:** `scripts/build-loop.sh:575-606`, `scripts/lib/dev-cycle-read.sh:1777-1787`, `scripts/lib/dev-cycle-read.sh:233-236`, `$S/run-base.txt`

---

## Claim 7: paths_read comment: "Sets PATHS (the entries as written) or, for a malformed line, PATHS_WHY (which lands only the brief's own files)"

**Location:** `scripts/build-loop.sh:607-611`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers paths_read's outputs and that PATHS is emptied on malformed input (`[[ -z "$PATHS_WHY" ]] || PATHS=()`, `:628`); does not establish what BRIEF[paths] holds beyond brief_fields' "first line outside a fence … whole, after one trailing CR is dropped" (`scripts/lib/dev-cycle-read.sh:373-375`).

`PATHS` holds the entries as written, trailing `/` kept, because `${e%/}` is used only for the checks: `if ! pathform "${e%/}"` and `seen[${e%/}]=1` (`:624-626`). Executed: see Claim 5.

**Evidence:** `scripts/build-loop.sh:607-628`, `scripts/lib/dev-cycle-read.sh:372-408`, `$S/run-base.txt`

---

## Claim 8: never_res: "* and ? match within one part, and a glob matches the path or any directory above it (a trailing / changes nothing). Set once, after read_settings." Regex escaping for every globform character

**Location:** `scripts/build-loop.sh:629-645`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the regex built for every character globform admits (letters, digits, `. _ - / * ?`); does not establish behaviour for characters globform refuses, which never reach NEVER.

```bash
# scripts/build-loop.sh:640-642
      case "$c" in '*') re+='[^/]*' ;; '?') re+='[^/]' ;; .) re+='\.' ;; *) re+="$c" ;; esac
    done
    NEVER_RES+=("^$re(/|\$)")
```
(excerpt ends :642; never_res() closes at :644 — read)

globform admits `^[*?$NAMECHARS]+$` (`:357`). Of those characters, only `.` is special in an ERE outside brackets, and it is escaped. `-`, `_` and `/` are literal. `read_settings; never_res` is at `:832`. Probe FCPROBE 3 ("ok 3") used glob `a.b_c-d/e?f*g`. It denies `a.b_c-d/exfZZg/k` (a directory above matches), passes `aXb_c-d/exfZZg` (the `.` is literal) and passes `a.b_c-d/exxfg` (`?` matches one character).

**Evidence:** `scripts/build-loop.sh:355-362`, `scripts/build-loop.sh:629-645`, `scripts/build-loop.sh:832`, `$S/probe-tests.bats.part`, `$S/run-probes.txt`

---

## Claim 9: srules comment: "Sets DENY, first match winning: the floor (only when $5 is empty: it walks the checkout), a Self-merge never: glob, then the allowlist (Paths:, or ownfile)"

**Location:** `scripts/build-loop.sh:646-650`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers srules' order and arguments; does not establish that the code checks ownfile before Paths: (it does; the outcome is the same either way).

`if [[ -z "$5" ]] && floor "$2" "$1" "$4"; then DENY="$FLOOR_WHY"; return 0; fi` (`:654`). Then the never loop (`:655-657`), `! ownfile … || return 0` (`:658`), the PATHS_WHY deny (`:659`), the Paths loop (`:660-662`) and `DENY="neither listed…"` (`:663`). The arguments match the comment: the call at `:815` passes `"$stem" "$p" "${lps[$i]}" "${ss[$i]}" "$co"`. This also follows from the executed Claims 4 and 5.

**Evidence:** `scripts/build-loop.sh:646-664`, `scripts/build-loop.sh:815`

---

## Claim 10: check_line: "Contract item 1 (the floor's walk); exported, so its children run under it too." / lib item 3: "its check_line runs the walk under item 1's LC_ALL=C"

**Location:** `scripts/build-loop.sh:756-757`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that the walk runs under C whatever the caller's locale, and that the test catches the line's removal. Does not establish whether status_line now running under C (it used to run under the caller's locale) changes any skip text; no difference showed in the suite run.

In the `nolcall` copy, `local -x LC_ALL=C` was deleted. With that change, the test at `:2003` fails at its `LC_ALL=C.utf8 chk "$x"` step (`$S/run-nolcall.txt`: "status 2", "deny … work-feat-x.txt: the default branch's instruction files could not be walked for @ imports"). The unchanged copy passes ("ok 6"). The lib header at `scripts/lib/dev-cycle-read.sh:63` states the same thing.

**Evidence:** `scripts/build-loop.sh:755-760`, `scripts/lib/dev-cycle-read.sh:59-68`, `test/scripts/build-loop-check.bats:2011-2014`, `$S/run-nolcall.txt`, `$S/run-base.txt`, `$S/exits.txt`

---

## Claim 11: "The S rules' inputs, read again from main's commit (status_line read them in a subshell)."

**Location:** `scripts/build-loop.sh:798-800`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that BRIEF is re-read from MAIN_SHA in the parent shell for self-merge briefs; does not establish anything about a brief that changes on main between the two reads (both read the same MAIN_SHA).

`out="$(status_line "$a")"` (`:760`) runs in a subshell. `brief_fields` reads `git cat-file blob "$MAIN_SHA:$1"` (`scripts/lib/dev-cycle-read.sh:393`) and starts with `BRIEF=(); BRIEF_ODD=""` (`:389`), so no earlier brief's BRIEF survives.

**Evidence:** `scripts/build-loop.sh:760`, `scripts/build-loop.sh:798-800`, `scripts/lib/dev-cycle-read.sh:386-408`

---

## Claim 12: "In this shell, not $(...): the floor's need_root exit ends the run, and check_line's import_reset is what keeps one brief's walk from the next."

**Location:** `scripts/build-loop.sh:838-840`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the exit path (`f > file` runs in the current shell, and an `exit` inside an `if` condition still ends it) and import_reset's observable effect. Does not establish the run's stdout when need_root fires mid-brief: that brief's partial line is lost when the EXIT trap removes GATE_TMP before `cat`. This matches the plan's "no line for that brief".

Executed analog (`$S/exitprobe.out`): a function calling `exit 1` from inside `if fl; then` within `cl "$a" > "$T/line"` ended the whole script, exit 1, with no further output. Mutation: deleting `import_reset` (`:759`) makes test `:2003` fail with one `worktree list` instead of two (`$S/run-noreset.txt`).

set -e now applies inside check_line (it used to run in `$(...)`, which drops errexit unless inherit_errexit is set; `grep inherit_errexit` finds nothing). A static read found no unguarded command that can fail: every `return` follows an `echo`, srules and paths_read end in assignments or `||` lists, and nrules' loop body ends in `[[ … ]] || DENY=…` (`:603`). Paraphrased — no quote available because the finding covers the absence of failing statements across check_line, nrules, srules and paths_read (`:582-664`, `:755-819`). The per-brief globals are reset before use: DENY (`:584`, `:653`), PATHS/PATHS_WHY (`:616`), FLOOR_WHY (lib `:1829`), BRIEF (lib `:389`). CHECKOUT_WHY is read only after checkout_gate fails in the same brief.

**Evidence:** `scripts/build-loop.sh:755-819`, `scripts/build-loop.sh:830-844`, `scripts/lib/dev-cycle-read.sh:160-164`, `$S/exitprobe.sh`, `$S/exitprobe.out`, `$S/run-noreset.txt`

---

## Claim 13: "open_shared  # once, in this shell: status_line runs in a subshell"

**Location:** `scripts/build-loop.sh:833`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that check_line calls status_line through `$(...)`; does not establish open_shared's caching (unchanged).

`out="$(status_line "$a")"` (`scripts/build-loop.sh:760`), and status_line calls `open_shared` itself (`:472`).

**Evidence:** `scripts/build-loop.sh:470-473`, `scripts/build-loop.sh:760`, `scripts/build-loop.sh:833`

---

## Claim 14: lib item 5: "build-loop.sh reads diff-tree -r of main and the merge instead, where a symlink or gitlink above a path is a changed entry of its own … its S rules run floor only on a path they pass"

**Location:** `scripts/lib/dev-cycle-read.sh:76-85`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers diff-tree -r showing a symlink or gitlink that replaces a directory as its own A (or, when main had it, D) entry, which the N rules' mode check refuses. Does not establish main_entry callers other than build-loop.sh.

Executed (`$S/difftree.txt`): a directory `a/` replaced by a symlink and `g/` replaced by a gitlink gives
```
:000000 120000 … A	a
:100644 000000 … D	a/x
:000000 160000 … A	g
```
nrules refuses either side's non-file mode (`[[ ! "$2 $3" =~ ^(000000|100644|100755)\ (000000|100644|100755)$ ]]`, `scripts/build-loop.sh:587`). srules runs only when `-z "$DENY"` (`:815`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:76-85`, `scripts/build-loop.sh:587`, `scripts/build-loop.sh:815`, `$S/probe2.sh`, `$S/difftree.txt`

---

## Claim 15: "FLOOR_WHY=""  # read by floor's caller (build-loop.sh srules)"

**Location:** `scripts/lib/dev-cycle-read.sh:1824`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the scripts/ callers; does not establish callers outside scripts/ (tests read it through their own harness).

`rg FLOOR_WHY scripts/` outside the lib finds only `DENY="$FLOOR_WHY"` at `scripts/build-loop.sh:654`, inside srules.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1824`, `scripts/build-loop.sh:654`

---

## Claim 16: commit message: "check_line now runs in the parent shell under LC_ALL=C … a test counts one worktree listing per self-merge decision"

**Location:** commit eddfd5f9 message (body ¶2); `test/scripts/build-loop-check.bats:2010`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the test's count and that it detects import_reset's removal; does not establish that git worktree list is the walk's only once-per-decision call.

`[ "$(grep -c '^worktree list' "$BATS_TEST_TMPDIR/calls")" -eq 2 ]` (`:2010`), for two self-merge briefs. It passes on base and fails on the noreset mutation (Claim 12).

**Evidence:** `test/scripts/build-loop-check.bats:2003-2015`, `$S/run-base.txt`, `$S/run-noreset.txt`

---

## Claim 17: commit message: "229 changed code lines"

**Location:** commit eddfd5f9 message (last body ¶ before Confidence)
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers added plus deleted lines outside docs/ (the plan's row-62 measure); does not establish a comment/code split.

`git diff --numstat main...HEAD`: build-loop.sh 105/15, dev-cycle-read.sh 12/9, build-loop-check.bats 87/1, which sums to 229 (the plan doc's 3/0 excluded).

**Evidence:** `$S/numstat.txt`

---

## Claim 18: commit message: "Tests: build-loop-check 138, build-loop-read 20, dev-cycle 79, fixture-git-env 2, fixture-hermeticity 2."

**Location:** commit eddfd5f9 message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the per-suite test counts; does not establish that every suite is green (only the six U2c1 tests were run here, all passing).

`bats --count` gives 138, 20, 79, 2 and 2 (`$S/counts.txt`). Matches prior pattern: per-suite commit-message tallies ("All 85 tests…", 59ca38f; "mode1-equiv 33", 37c5ea9); not a recurrence here.

**Evidence:** `$S/counts.txt`, `test/scripts/build-loop-check.bats:1938-2015`

---

## Claim 19: commit message: "Timing on a 3,284-file clone: 3.6 s for 1 path, 6.1 s for 150, 7.6 s for 400."

**Location:** commit eddfd5f9 message
**Type:** Performance
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers nothing about the figures; does not establish or refute them.

Execution required: the 3,284-file clone and the briefs used are not named anywhere in the diff. Paraphrased — no quote available because the claim concerns a measurement environment absent from the repo.

**Evidence:** `scripts/build-loop.sh:755-819`

---

## Claim 20: U2c1 test titles (T9, T10, malformed Paths:, T45, row 523, import_reset/C locale) assert what they name

**Location:** `test/scripts/build-loop-check.bats:1938-2015`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each title against its assertions and the two mutations; does not establish coverage of briefs-as-a-file or of case-variant own files (no test, Claim 2a).

All six pass on base (`$S/run-base.txt`). "review ignores it" is asserted by `[ "$status" -eq 0 ] && [ "${#lines[@]}" -eq 7 ]` after `settings "Build-loop policy: review" …` (`:1988-1989`). "by part" is `has "path $B A docs/sub/n.txt"` (`:1987`). "a symlink at a listed path" is `has "deny $B A scripts/link.sh: $NMODE"` (`:1964`). The last title's two halves each fail under their mutation (Claims 10 and 12).

**Evidence:** `test/scripts/build-loop-check.bats:1938-2015`, `$S/run-base.txt`, `$S/run-noreset.txt`, `$S/run-nolcall.txt`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
- **Claim 1** (`docs/working/plan-build-loop-handoff.md:238`): still says a malformed or duplicate Paths: entry "means no self-merge". Since U2c1 the brief's own files still land (srules `:658-659`).

### Mostly Accurate
- **Claim 2a** (`docs/working/plan-build-loop-handoff.md:311`): "an allowlist widens nothing by case" holds for Paths: entries only. ownfile compares lower-cased, so `Docs/Working/Plan-STEM.md` lands (FCPROBE 1).

### Unverifiable
- **Claim 19** (commit eddfd5f9 message): the timings need the named 3,284-file clone, which is not in the repo.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the output path your dispatch names, structured per your skill, every finding with verbatim Evidence and a path:line.
- Answered: yes. All 8 brief claim groups were checked, 16 of 21 claims by execution (mutation runs for import_reset and LC_ALL, and probes for the glob regex, case-variant own files and diff-tree).
- Out of scope: running the full suites (only the U2c1 tests ran); the commit's timing figures.
- Escalate: Claim 2a's case-folded own files may be a design question (does a case variant of an own file landing matter?) rather than only a doc fix.
- Decisions I made: execution logs stayed in my scratch dir rather than docs/reviews/execution-logs/, per the dispatch rule to write only my report.
