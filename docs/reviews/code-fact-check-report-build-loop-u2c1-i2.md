# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u2c1 (branch `feat/build-loop-u2c1`)
**Commit:** cf7dd447
**Replication:** k=1 (loop pass, decision 031)
**Scope:** partial (review iteration 2): `git diff eddfd5f9..HEAD -- scripts test` (scripts/build-loop.sh, test/scripts/build-loop-check.bats), the plan text changed in that range (`docs/working/plan-build-loop-handoff.md` :238, :311, :312), the commit message of d435100e, and the override rows d435100e appended (`docs/reviews/override-log.md` :608-616)
**Checked:** 2026-10-10
**Total claims checked:** 20
**Summary:** 17 verified, 3 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Execution logs (scratch dir; `S=/tmp/claude-1000/-workspace/54247aa5-2a95-449b-b931-3ed456da322c/scratchpad/u2c1-i2-factcheck`). Every probe script starts `set -eu`, makes its own `mktemp -d /tmp/u2c1-factcheck-XXXX` dir, cds into it and removes it at the end. No git write command ran anywhere.
- `$S/diffprobe.sh` (cwd `$S`, `bash diffprobe.sh`, 2026-10-10T10:25:53Z, exit 0), output `$S/diffprobe.out`. It is a differential test. It extracts `globform`, `list_entries`, `read_paths` from `git show cf7dd447:scripts/build-loop.sh`, `paths_read` from eddfd5f9 and `pathform` from the lib. eddfd5f9's never-line branch of read_settings is transcribed from the diff as `old_never`, and HEAD's is copied as `new_never`. Both run over 22 never lines x 2 next-line values (44 cases), and the old and new Paths: readers run over 11 Paths: lines. It also has an errexit-context probe (`ee.sh`) and a set -e exit-status probe (`st.sh`).
- `bats test/scripts/build-loop-read.bats` (cwd worktree, `LC_ALL=C TMPDIR=<own mktemp dir>`, 2026-10-10T10:26:13Z, exit 0): `$S/run-read.txt` (20/20 ok). `bats -f 'U2c1' test/scripts/build-loop-check.bats` (same cwd and env, exit 0): `$S/run-u2c1.txt` (6/6 ok). Exits: `$S/exits.txt`.
- `$S/mutprobe.sh` (cwd `$S`, 2026-10-10T10:27:04Z, exit 0), stdout in `$S/mutprobe.out`. It ran two things. First, B1 reverted (srules' `ownfile "$2"` back to `ownfile "$3"`) in a `git archive cf7dd447` copy, with `bats -f 'U2c1 i1'`. That exited 1, output `$S/run-mut-b1.txt`. Second, the full `build-loop-check.bats` on the worktree. That exited 0 with 138/138 ok, output `$S/run-check-full.txt`.
- `$S/caseprobe.sh` (cwd `$S`, 2026-10-10T10:28:49Z, exit 0), stdout in `$S/caseprobe.out`. It runs FCPROBE 1 (`$S/probe-tests.bats.part`) in an archive copy, output `$S/run-probe.txt`.
- `$S/b5probe.sh` (cwd `$S`, 2026-10-10T10:29:26Z, exit 0), stdout in `$S/b5probe.out`. It runs FCPROBE 2 (`$S/probe-b5.bats.part`) in an archive copy where check_line's re-read is forced to fail (`if brief_fields "$a"` → `if false`), output `$S/run-probe-b5.txt`.

I read the hallucination-pattern log. No claim in scope matches a logged pattern. The one nearby class, per-suite counts in a commit message, does not apply because d435100e's message gives no counts.

---

## Claim 1: override rows for every deferred iteration-1 item (B3, B4, B5's chain, B9, B10, A1's lib copy), dated 2026-10-10

**Location:** `docs/reviews/override-log.md:608-616`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that a row exists for each item the rubric marks Defer or Won't-Fix; does not judge whether the deferral reasons are sound.

Each deferred rubric item has a dated row. B3 is `:608` ("A directory at an instruction-file name or an @-import target lands under self-merge … Defer"). B4 is `:610` ("floor forks twice per path … Defer (routed)"). B5's chain is `:613` ("check_line's verdict chain grows again (row 530's trigger …) … Defer"). B9 is `:612` ("A malformed Paths: line shows only as the same reason on every non-own deny line … Defer"). B10's four parts are `:609` (security 4, "Won't-Fix"), `:611` (performance 2, "Defer"), `:614` (architecture 5, "Won't-Fix") and `:615` (architecture 6, "Won't-Fix"). A1's lib copy is `:616` ("Fixed in part; rest Defer … The lib's reader_settings keeps its own copy"). Every row starts `| 2026-10-10 | \`feat/build-loop-u2c1\` |`.

**Evidence:** `docs/reviews/override-log.md:608-616`, `docs/reviews/code-review-rubric-2026-10-10-feat-build-loop-u2c1.md`

---

## Claim 2: "`Paths: P…` (`Paths: none` or no line lists none; a malformed or duplicate entry lands only the brief's own files: U2c1)"

**Location:** `docs/working/plan-build-loop-handoff.md:238`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers --check's outcome for a self-merge brief with `Paths: none`, no Paths: line, a malformed line and a duplicate entry; does not establish --status's view of such a brief (row 612: it still prints self-merge).

The iteration-1 Stale finding (B2) is fixed. `test/scripts/build-loop-check.bats:1967-1978` passes (`$S/run-u2c1.txt`, "ok 3"). Its loop covers `"Paths: docs/a docs/a/|lists entry 2 twice"`, `"Paths: none|"` and `"-|"` (no line). For each it asserts `has "path $B A docs/working/plan-2026-10-01-x.md"` and denies `docs/a`. The code path is `scripts/build-loop.sh:663-664`:

```bash
  ! ownfile "$2" "$1" "$4" || return 0
  [[ -z "$PATHS_WHY" ]] || { DENY="the brief's Paths: line $PATHS_WHY, so only its own files land"; return 0; }
```
(excerpt ends :664; enclosing srules() continues to :669 — read)

**Evidence:** `docs/working/plan-build-loop-handoff.md:238`, `scripts/build-loop.sh:656-669`, `test/scripts/build-loop-check.bats:1967-1978`, `$S/run-u2c1.txt`

---

## Claim 3: U2c1 bullet: "`Paths: none` or no line meaning none (as the settings lists spell it; one parser, `list_entries`, for both …); … an own file counts only when the diff spells it in lower case, as ownfile's patterns are (i1 security 2)"

**Location:** `docs/working/plan-build-loop-handoff.md:311`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the one shared parser and the lower-case rule for an own file landing through the allowlist; does not establish that the floor compares own files case-sensitively (it folds case, Claim 5), nor that the lib's reader_settings shares the parser (it does not, row 616).

The two callers are `list_entries "$t" "Self-merge never" glob globform` (`scripts/build-loop.sh:416`) and `list_entries "${BRIEF[paths]}" Paths path pathform` (`scripts/build-loop.sh:628`). No other parser of either line remains (paraphrased — no quote available because the claim is about absence: `grep -rn paths_read scripts test` returns nothing). The lower-case rule: lib ownfile compares against literal lower-case patterns, `^docs/working/(research|plan|checkpoint|handoff|test-strategy)-(.+)\.md$` (`scripts/lib/dev-cycle-read.sh:1808`). STEM is lower case by construction: `SLUG='[abcdefghijklmnopqrstuvwxyz0123456789-]+'` (`scripts/lib/dev-cycle-read.sh:229`). In test 3, `Docs/Working/Plan-2026-10-01-x.md` is denied (`has "deny $B A Docs/Working/Plan-2026-10-01-x.md: $w"`, `:1975`). With B1 reverted, test 3 fails (`$S/run-mut-b1.txt`, "not ok 1").

**Evidence:** `docs/working/plan-build-loop-handoff.md:311`, `scripts/build-loop.sh:416`, `scripts/build-loop.sh:628`, `scripts/lib/dev-cycle-read.sh:229`, `scripts/lib/dev-cycle-read.sh:1805-1810`, `test/scripts/build-loop-check.bats:1975`, `$S/run-mut-b1.txt`

---

## Claim 4: U2c2 bullet: "floor's per-path cost: U2c1's measurement asks for it (i1 performance: 6.4 ms per path, 400 paths 3.1 s against main's 0.3 s; the forks in lower and need_root, not row 470's membership test)"

**Location:** `docs/working/plan-build-loop-handoff.md:312`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that the plan quotes the iteration-1 performance report correctly; does not re-measure.

The report reads: "eddfd5f9 adds about 6.4 ms per path ((3.13 − 0.57) / 399), almost all of it inside `floor`" (`docs/reviews/performance-review-2026-10-10-u2c1.md:24`). Its table has `| 400 | 0.33 s, 0.33 s | 3.16 s, 3.13 s |` (`:17`). Its finding heading is "floor re-lowers each path with two forks and checks the root twice" (`:28`).

**Evidence:** `docs/reviews/performance-review-2026-10-10-u2c1.md:15-28`

---

## Claim 5: --help: the floor refuses "a working doc or review that is not the brief's own", and own files are "docs/working/{research,plan,checkpoint,handoff,test-strategy}-STEM.md, an added docs/reviews/STEM.md or NAME-STEM.md, in lower case"

**Location:** `scripts/build-loop.sh:175-185`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the floor's working-doc and review arms and the help's definition of own files; does not establish the floor's other arms (unchanged from eddfd5f9).

The floor arm and the allowlist arm are each described correctly. The help applies "in lower case" to own files as one definition, though, and the floor does not use it. The floor lower-cases the path before it asks ownfile:

```bash
# scripts/lib/dev-cycle-read.sh:1830, :1842-1843
  lp="$(lower "$1")" || { FLOOR_WHY="the path could not be lower-cased"; return 0; }
  elif [[ "$lp" == docs/working/* ]] && ! ownfile "$lp" "$2" "$3"; then FLOOR_WHY="a working file that is not this brief's own (they carry its full stem)"
  elif [[ "$lp" == docs/reviews/* ]] && ! ownfile "$lp" "$2" "$3"; then FLOOR_WHY="a review record (only an added review named STEM.md or NAME-STEM.md lands)"
```
(excerpt ends :1843; enclosing floor() continues to :1849 — read)

So `Docs/Working/Plan-STEM.md` passes the floor as the brief's own. It then lands if `Paths:` lists it exactly. Probe FCPROBE 1 (`$S/run-probe.txt`, "ok 1") uses brief x with `Paths: Docs/Working/Plan-2026-10-01-x.md`. It asserts `has "path $B A Docs/Working/Plan-2026-10-01-x.md"` and `has "deny $B A Docs/Working/Plan-2026-10-02-y.md: $WORK"`, and both pass. A reader of the help would expect the floor to refuse the first path even when it is listed. Precise version: the floor refuses a working doc or review whose lower-cased path is not an own file; "in lower case" is the allowlist's rule.

**Evidence:** `scripts/build-loop.sh:175-185`, `scripts/lib/dev-cycle-read.sh:1826-1849`, `$S/probe-tests.bats.part`, `$S/run-probe.txt`

---

## Claim 6: --help: "Paths: P ..." … "compared exactly (a trailing / makes a directory, matched at a part boundary; unlike a never glob, an entry without one matches that file alone); "Paths: none" or no line lists none; any other line is malformed, and only own files land."

**Location:** `scripts/build-loop.sh:185-190`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the Paths: grammar and the match rule, and the contrast with never globs; does not establish behaviour for entries pathform refuses beyond the tested ones.

The match is `[[ "$2" != "$e" && ( "$e" != */ || "$2" != "$e"* ) ]] || return 0` (`scripts/build-loop.sh:666`). An entry without a trailing / matches only on equality. A never regex ends `"^$re(/|\$)"` (`scripts/build-loop.sh:644`), so it matches below as well. In diffprobe (`$S/diffprobe.out`), an unset key gives `same [UNSET] [|]`, `Paths: none` gives empty PATHS with no reason, and bare `Paths:` gives `is not exactly "Paths: PATH ..." with single spaces`. Test 3 asserts those reasons on deny lines and passes.

**Evidence:** `scripts/build-loop.sh:185-190`, `scripts/build-loop.sh:633-646`, `scripts/build-loop.sh:665-668`, `$S/diffprobe.out`, `$S/run-u2c1.txt`

---

## Claim 7: Exit: "1 … a --check that stopped part way after the lines of the briefs before (a failed command or check; a caller reads any exit but 0 as nothing decided)"

**Location:** `scripts/build-loop.sh:198-203`
**Type:** Behavioral / Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the exit status and printed lines of a --check that stops mid-run; does not establish that any unguarded command in check_line fails in practice.

"After the lines of the briefs before" holds. Each brief's lines go to a file that is printed only once check_line returns: `check_line "$a" > "$GATE_TMP/line"; cat "$GATE_TMP/line"` (`scripts/build-loop.sh:849`). The EXIT trap removes GATE_TMP (`:843`). The named check, need_root, exits 1: `… >&2; exit 1; }` (`scripts/lib/dev-cycle-read.sh:161-163`).

A stop caused by "a failed command" is different. Under `set -euo pipefail` (`scripts/build-loop.sh:205`) bash exits with that command's own status, and nothing maps it to 1. There is no ERR trap (paraphrased — no quote available because the claim covers absence of code: `grep -n trap scripts/build-loop.sh` shows only the EXIT trap at :843). Probe `st.sh` in `$S/diffprobe.out` makes a git command fail under set -e, and the script exits `st exit=128`. A failure returning 2 would also collide with the "2 any --check verdict line … not ok" bucket. The parenthetical "a caller reads any exit but 0 as nothing decided" keeps the caller safe. Precise version: "1 … need_root's stop; a failed command stops it with that command's status".

**Evidence:** `scripts/build-loop.sh:198-205`, `scripts/build-loop.sh:841-853`, `scripts/lib/dev-cycle-read.sh:160-164`, `$S/diffprobe.sh`, `$S/diffprobe.out`

---

## Claim 8: list_entries comment: "LINE is exactly "KEY: none" or "KEY: E ..." with single spaces (WORD names E in the reason), and each E, a trailing / dropped, passes FORM (globform or pathform) and is listed once. Sets LIST (the entries as written, a trailing / kept; empty for none) or LIST_WHY." and "Split on single spaces only; FORM then refuses any other blank in an entry."

**Location:** `scripts/build-loop.sh:356-366`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers list_entries' grammar, outputs and reset; does not establish callers' use of LIST beyond read_settings and read_paths.

The code matches the comment:

```bash
# scripts/build-loop.sh:362-377
list_entries() {
  local v="${1#"$2": }" e i=0
  local -A seen=()
  LIST=(); LIST_WHY=""
  # Split on single spaces only; FORM then refuses any other blank in an entry.
  if [[ "$1" != "$2: "* || ! "$v" =~ ^[^\ ]+(\ [^\ ]+)*$ ]]; then LIST_WHY="is not exactly \"$2: ${3^^} ...\" with single spaces"; return 0; fi
  [[ "$v" != none ]] || return 0
  IFS=' ' read -ra LIST <<<"$v"  # not a bare $v: the shell would expand * and ? against files
  for e in "${LIST[@]}"; do
    i=$((i + 1))
    if ! "$4" "${e%/}"; then LIST_WHY="lists entry $i, which is not an allowed $3 form"; break; fi
    if [[ -n "${seen[${e%/}]-}" ]]; then LIST_WHY="lists entry $i twice"; break; fi
    seen[${e%/}]=1
  done
  [[ -z "$LIST_WHY" ]] || LIST=()
}
```

In diffprobe the never lines with a tab (`a<TAB>b`) give the same malformed reason before and after. `Paths: Docs/A sub/` keeps `sub/` with its slash.

**Evidence:** `scripts/build-loop.sh:356-377`, `$S/diffprobe.out`

---

## Claim 9: brief claim 2: `${3^^}`, calling FORM by name as `"$4" "${e%/}"`, and `${1#"$2": }` with KEY "Self-merge never" behave under set -u/-e

**Location:** `scripts/build-loop.sh:363-373`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers these expansions under bash 5.2.15 with `set -eu`, for the 44 never and 11 Paths: inputs probed; does not establish bash versions older than 4.4, where `"${LIST[@]}"` of an empty array fails under set -u.

diffprobe.sh runs under `set -eu` and calls the extracted list_entries directly. It exits 0 (`$S/diffprobe.out`). The upper-cased word yields the exact old strings: `is not exactly "Paths: PATH ..." with single spaces` for Paths, and `GLOB` in the never-line reason, compared byte for byte against the transcribed old code with 0 differences. `${1#"$2": }` strips the quoted KEY and then the literal ": ". `"Self-merge never: workflows/ docs/*.txt"` gives `set workflows/ docs/*.txt` in both versions. FORM by name: `if ! "$4" "${e%/}"` sits in an `if` condition, so a FORM refusal never trips errexit. The function's last command, `[[ -z "$LIST_WHY" ]] || LIST=()`, returns 0 either way. Bash on the host: `GNU bash, version 5.2.15(1)-release`.

**Evidence:** `scripts/build-loop.sh:362-377`, `$S/diffprobe.sh`, `$S/diffprobe.out`

---

## Claim 10: read_settings' never line keeps its reasons and order: "The form reason comes first, then the next line, then the entries."

**Location:** `scripts/build-loop.sh:413-421`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers every reason string and its precedence for the 44 probed inputs (form errors, the next-line rule, none, globform refusals, duplicates, trailing /, tabs, "none none", "none/"), plus build-loop-read.bats' never tests; does not establish inputs outside those classes.

```bash
# scripts/build-loop.sh:415-418
      t="${text[never]}"; v="${t#Self-merge never: }"
      list_entries "$t" "Self-merge never" glob globform; why="$LIST_WHY"
      # The form reason comes first, then the next line, then the entries.
      if [[ "$why" != "is not exactly"* && "${next[never]}" != 1 ]]; then why="is followed by a non-blank line outside a fence (it may continue the list)"; fi
```
(excerpt ends :418; enclosing read_settings() continues to :460 — read through the never branch's end at :421 and the policy branch that reads never_ok)

The old code tested form, then the next line, then none, then entries, as an elif chain. The new code lets the next-line reason override any reason except the form one, which gives the same precedence. diffprobe reports `never cases: 44, differences: 0`. `build-loop-read.bats` passes 20/20 (`$S/run-read.txt`). That includes "ok 7 --settings: Self-merge never: is one line of allowed globs; anything else is malformed and turns self-merge off (T45)" and "ok 17 … the next-line rule …".

**Evidence:** `scripts/build-loop.sh:392-421`, `$S/diffprobe.out`, `$S/run-read.txt`, `test/scripts/build-loop-read.bats:109-152`

---

## Claim 11: read_paths comment: "from BRIEF[paths]: as list_entries reads "Paths: PATH ...", each entry pathform's, a trailing / making it a directory; "Paths: none", or no line, lists none. Sets PATHS or, for a malformed line, PATHS_WHY"

**Location:** `scripts/build-loop.sh:620-623`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers read_paths and its use of BRIEF[paths]; does not establish what brief_fields stores beyond the "unset when no line" contract.

`[[ -n "${BRIEF[paths]+set}" ]] || return 0` (`scripts/build-loop.sh:627`) relies on brief_fields leaving a missing key unset. The lib's contract says so ("a key with no such line stays unset", `scripts/lib/dev-cycle-read.sh:377`), and the code does it: `BRIEF=()` (`:390`), then only `*) BRIEF["${l%%$'\t'*}"]="${l#*$'\t'}" ;;` for keys awk printed (`:404`). diffprobe's results on HEAD: UNSET gives `[|]`, `Paths: none` gives `[|]`, and malformed lines give a reason with PATHS empty.

**Evidence:** `scripts/build-loop.sh:620-629`, `scripts/lib/dev-cycle-read.sh:372-407`, `$S/diffprobe.out`

---

## Claim 12: srules comment: "The allowlist widens nothing by case: Paths: entries compare exactly, and ownfile gets the path as spelled, so an own file passes only when the diff spells it in lower case (ownfile folds nothing)."

**Location:** `scripts/build-loop.sh:652-655`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers srules' allowlist arm; does not establish that the floor arm compares case-sensitively (it folds, Claim 5).

srules' ownfile call is `! ownfile "$2" "$1" "$4" || return 0` (`scripts/build-loop.sh:663`), with `$2` the path as spelled. ownfile has no lowering: `local b="${1#docs/reviews/}"` … `[[ "$3" == A && "$1" == docs/reviews/* …` (`scripts/lib/dev-cycle-read.sh:1806-1809`). With `ownfile "$3"` restored, test 3 fails on its first case (`$S/run-mut-b1.txt`, "not ok 1 … line: Paths: docs/a docs/a/|lists entry 2 twice").

**Evidence:** `scripts/build-loop.sh:649-669`, `scripts/lib/dev-cycle-read.sh:1805-1810`, `$S/mutprobe.sh`, `$S/run-mut-b1.txt`

---

## Claim 13: B8: a never deny reads "matched by GLOB in the Self-merge never: line of docs/dev-cycle.md", GLOB as written

**Location:** `scripts/build-loop.sh:660-662`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the deny text and that NEVER and NEVER_RES indexes correspond; does not establish anything about the regex construction (unchanged; checked in iteration 1).

```bash
# scripts/build-loop.sh:660-662
  for i in "${!NEVER_RES[@]}"; do
    [[ ! "$3" =~ ${NEVER_RES[$i]} ]] || { DENY="matched by ${NEVER[$i]} in the Self-merge never: line of docs/dev-cycle.md"; return 0; }
  done
```

never_res resets the array and appends exactly one regex per NEVER entry, in order: `NEVER_RES=()` … `for g in "${NEVER[@]}"` … `NEVER_RES+=("^$re(/|\$)")` (`scripts/build-loop.sh:636-646`), so the indexes match. NEVER holds `"${LIST[@]}"`, the entries as written (`:421`). Test 4 asserts `matched by workflows/ in …` with the trailing slash, and `matched by docs/*.txt in …` (`test/scripts/build-loop-check.bats:1985-1986`). It passes (`$S/run-u2c1.txt`, "ok 4").

**Evidence:** `scripts/build-loop.sh:633-646`, `scripts/build-loop.sh:660-662`, `test/scripts/build-loop-check.bats:1980-1992`, `$S/run-u2c1.txt`

---

## Claim 14a: check_line comment: "It runs in the caller's shell (set -e applies; an exit ends the run)"

**Location:** `scripts/build-loop.sh:759-760`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers where errexit is in force during check_line; does not establish whether any command in the suspended regions fails in practice.

"An exit ends the run" holds. check_line runs as a plain command, `check_line "$a" > "$GATE_TMP/line"` (`:849`), so need_root's `exit 1` inside floor ends the script. "set -e applies" holds for check_line's own body and for helpers it calls as plain commands or as the last command of a `||` list: nrules (`:823`) and srules (`:824`). Bash suspends errexit inside any function called in an `if`/`&&`-condition. That covers floor (`if [[ -z "$5" ]] && floor "$2" "$1" "$4"; then`, `:659`) and so the whole import walk. It also covers `brief_fields` (`if brief_fields "$a"; then`, `:809`), `checkout_gate` (`&& ! checkout_gate; then`, `:805`) and `nul_list` (`:820`). Errexit is also off inside every `$(...)`, such as `out="$(status_line "$a")"`, because `inherit_errexit` is not set (paraphrased — no quote available because the claim covers absence of code: `grep -n "inherit_errexit\|shopt"` over build-loop.sh and the lib returns nothing). Probe `ee.sh` (`$S/diffprobe.out`) shows a function whose `false` is skipped when it is called inside `if` ("inner continued past false"). The same function ends the script when called as the last command of a `||` list ("ee exit=1"). Precise version: "set -e applies to its own lines and to nrules/srules, but not inside floor's walk or the helpers it tests in conditions".

**Evidence:** `scripts/build-loop.sh:756-828`, `scripts/build-loop.sh:656-669`, `$S/diffprobe.sh`, `$S/diffprobe.out`

---

## Claim 14b: check_line comment: "each helper it calls empties its own globals (DENY, PATHS, BRIEF, CHECKOUT_WHY, FLOOR_WHY)"

**Location:** `scripts/build-loop.sh:760-762`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the five named globals; does not audit other globals check_line's helpers set (PATHS_WHY, LIST, LIST_WHY, TRUTH_WHY, IMPORT_READER_WHY), though PATHS_WHY is reset with PATHS on both branches at :809.

nrules starts `DENY=""` (`scripts/build-loop.sh:597`) and srules starts `DENY=""` (`:658`). read_paths starts `PATHS=(); PATHS_WHY=""` (`:626`). brief_fields does `BRIEF=(); BRIEF_ODD=""` (`scripts/lib/dev-cycle-read.sh:390`). checkout_gate does `CHECKOUT_WHY=""` (`scripts/build-loop.sh:692`). floor does `FLOOR_WHY=""` (`scripts/lib/dev-cycle-read.sh:1829`). On a failed re-read, check_line resets PATHS itself, not through a helper: `else PATHS=(); PATHS_WHY="could not be read again"; fi` (`scripts/build-loop.sh:809`). PATHS and BRIEF are read only under self-merge, where one of those two branches always runs first.

**Evidence:** `scripts/build-loop.sh:597`, `scripts/build-loop.sh:626`, `scripts/build-loop.sh:658`, `scripts/build-loop.sh:692`, `scripts/build-loop.sh:809`, `scripts/lib/dev-cycle-read.sh:390`, `scripts/lib/dev-cycle-read.sh:1829`

---

## Claim 15: "A failed read lands only own files, with every path line still printed."

**Location:** `scripts/build-loop.sh:808-809`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers check_line's handling of a failed brief_fields re-read (forced in a copy); does not establish what makes the re-read fail in practice (same MAIN_SHA as status_line's read), and no shipped test triggers it.

```bash
# scripts/build-loop.sh:809
  if [[ "$pol" == self-merge ]]; then if brief_fields "$a"; then read_paths; else PATHS=(); PATHS_WHY="could not be read again"; fi; fi
```

FCPROBE 2 replaces `if brief_fields "$a"` with `if false` in an archive copy (`$S/b5probe.sh`) and passes (`$S/run-probe-b5.txt`, "ok 1"). It asserts status 2 and `$(nref 2 3)`, all 4 lines, `deny … docs/a` and `deny … docs/b` with "the brief's Paths: line could not be read again, so only its own files land", and `path … docs/working/plan-2026-10-01-x.md`. So a listed path is denied too, as "only own files" says.

**Evidence:** `scripts/build-loop.sh:808-828`, `$S/probe-b5.bats.part`, `$S/b5probe.sh`, `$S/run-probe-b5.txt`

---

## Claim 16: test title "--check: a malformed Paths: line lands only the brief's own files, spelled in lower case; Paths: none or no line lists nothing (T10, U2c1 i1)"

**Location:** `test/scripts/build-loop-check.bats:1967`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each title clause against the assertions and one mutation; does not cover a case-variant own review (only a working doc is tested).

The loop runs seven Paths: lines, including bare `Paths:` as malformed, `Paths: none` and no line. For each it asserts `has "deny $B A Docs/Working/Plan-2026-10-01-x.md: $w"` and `has "path $B A docs/working/plan-2026-10-01-x.md"` (`:1975-1976`). For none and no line, `w` is `$NLIST`. The test passes on HEAD and fails with B1 reverted (`$S/run-mut-b1.txt`).

**Evidence:** `test/scripts/build-loop-check.bats:1967-1978`, `$S/run-u2c1.txt`, `$S/run-mut-b1.txt`

---

## Claim 17: test 4's glob-named deny assertions ("by part and in any case")

**Location:** `test/scripts/build-loop-check.bats:1980-1992`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the B8 assertions added at :1985-1986; the rest of the test is unchanged since iteration 1.

The test asserts `for f in workflows/x.md workflows/sub/y.md Workflows/Z.md; do has "deny $B A $f: matched by workflows/ in the Self-merge never: line of docs/dev-cycle.md"; done` and `has "deny $B A docs/n.txt: matched by docs/*.txt in …"` (`:1985-1986`). "In any case" is `Workflows/Z.md`. The test passes (`$S/run-u2c1.txt`, "ok 4").

**Evidence:** `test/scripts/build-loop-check.bats:1980-1992`, `$S/run-u2c1.txt`

---

## Claim 18: the help's last line is pinned by a test ("… or no default branch found by name.")

**Location:** `test/scripts/build-loop-read.bats:445-450`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that the rewritten Exit: block still ends the header with the pinned text; does not check help content in between.

The test asserts `[[ "${lines[${#lines[@]}-1]}" == *"or no default branch found by name." ]]` (`test/scripts/build-loop-read.bats:448`). The Exit: block still ends `# decided), or no default branch found by name.` (`scripts/build-loop.sh:203`). The help is printed by `sed -n '2,/^[^#]/{/^#/p}' "$0"` (`:236`). The test passes (`$S/run-read.txt`, "ok 18").

**Evidence:** `test/scripts/build-loop-read.bats:445-450`, `scripts/build-loop.sh:198-203`, `scripts/build-loop.sh:236`, `$S/run-read.txt`

---

## Claim 19: commit d435100e: "Making bare "Paths:" malformed changes no outcome (both land only own files) and matches the settings lists' "none" spelling."

**Location:** `scripts/build-loop.sh:625-629` (commit d435100e message)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers which paths land and which are denied for bare "Paths:" before and after; does not cover the deny reason, which does change (from the not-listed text to the malformed text).

eddfd5f9's paths_read treated bare `Paths:` as none. HEAD's read_paths makes it malformed (diffprobe: `DIFF [Paths:] old=[|] new=[|is not exactly "Paths: PATH ..." with single spaces]`). In both versions PATHS is empty, so no non-own path matches. srules lands only own files (`:663`) and denies the rest (`:664` or `:668`). The outcome is the same and only the reason text differs. Test 3's `"Paths:|is not exactly …"` case asserts this and passes. The second diffprobe difference, `Paths: none` (old: one entry `none`; new: empty), is the intended spelling change.

**Evidence:** `scripts/build-loop.sh:625-629`, `scripts/build-loop.sh:656-669`, `$S/diffprobe.out`, `$S/run-u2c1.txt`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 5** (`scripts/build-loop.sh:175-185`): --help's "in lower case" for own files does not hold for the floor arm. The floor lower-cases before ownfile (lib :1830, :1842), so `Docs/Working/Plan-STEM.md` passes the floor and lands when `Paths:` lists it (FCPROBE 1). Say that the floor compares lower-cased and that "in lower case" is the allowlist's rule.
- **Claim 7** (`scripts/build-loop.sh:198-203`): a stopped --check exits 1 only through need_root. Under set -e a failed command's own status is the exit status (128 for git in probe `st.sh`; 2 would collide with the verdict bucket).
- **Claim 14a** (`scripts/build-loop.sh:759-760`): "set -e applies" holds for check_line's own lines and for nrules/srules. Errexit is suspended inside floor and its walk (called in an `if` condition at :659), inside brief_fields, checkout_gate and nul_list (conditions), and inside every `$(...)`, since inherit_errexit is not set.

### Unverifiable
(none)

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the output path your dispatch names, structured per your skill, every finding with verbatim Evidence and a path:line.
- Answered: yes. I checked all 5 claim groups in the i2 brief. 15 of 20 claims were checked by execution: a 44-case differential of the never line, the build-loop-read suite (20/20), the full build-loop-check suite (138/138), the B1 mutation, and two FCPROBE tests (a case-variant own file; a forced re-read failure).
- Out of scope: eddfd5f9's own code (iteration 1); the lib's reader_settings copy (row 616); other suites (dev-cycle, fixture-*).
- Escalate: Claim 5 shows the floor and the allowlist disagree on case for own files. A case-variant own working doc passes the floor and lands if Paths: lists it exactly. Nothing lands unlisted, so this is a help-text precision issue unless the author wants the floor to refuse it.
- Decisions I made: execution logs stayed in my scratch dir rather than docs/reviews/execution-logs/, per the dispatch rule to write only my report. B10 was counted as four rows (`:609`, `:611`, `:614`, `:615`).
