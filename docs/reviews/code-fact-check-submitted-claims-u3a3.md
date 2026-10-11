Commit: 01a2935f

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u3a3 (branch feat/build-loop-u3a3)
**Scope:** Submitted claims 7-11 from security-reviewer (final confirming pass), checked against `scripts/build-loop.sh` (srules, check_line, approval, land, merge arm) and `scripts/lib/dev-cycle-read.sh` (GATE_CODE, floor, floor_why, ANSWER_AWK, check_answer), with main's copy (4defd3fd) for claim 11
**Checked:** 2026-10-10
**Total claims checked:** 5
**Summary:** 4 verified, 1 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Line numbers are those of the worktree, whose uncommitted edits to `scripts/` are comment-only
(`git diff -U0 scripts/` shows no non-comment `+`/`-` line). Probes ran on a `git archive 01a2935f scripts`
copy (`headsrc/`) and a `git archive main scripts` copy (`mainsrc/`), in throwaway repos built
the way `test/lib/build-loop-fixtures.bash` builds them (hermetic git env, `GIT_CONFIG_GLOBAL=/dev/null`, own HOME).
Scratch dir and logs: `/tmp/claude-1000/-workspace/675070f9-0197-40a3-bd3c-520157521989/scratchpad/u3a3-final/submitted/`
(abbreviated `$S` below).

Executed runs (all exit 0, no process left running afterwards):
- P1: `timeout 300 bash probe.sh`, cwd `$S`, started 2026-10-11T00:17:09Z, exit 0, output `$S/logs/probe.out`.
- P2: `timeout 300 bash probe2.sh`, cwd `$S`, started 2026-10-11T00:17:35Z, exit 0, output `$S/logs/probe2.out`.
- B1: `TMPDIR=$S/bt timeout 900 bats test/scripts/build-loop-merge.bats` (serial), cwd the worktree, started 2026-10-11T00:17:45Z, exit 0 (12 of 12 ok), output `$S/logs/bats-merge.out`.

---

## Submitted Claims

## Claim 7: "`--merge` prints `merged` only when land returns 0; every policy, approval and land refusal prints refuse and exits 2"

**Location:** `scripts/build-loop.sh:1218-1230` (merge arm)
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the merge arm's verdict choice after check_line printed ok (the policy refusal, approval's refusals, land's refusals, and `merged` only on land's 0); does not establish the output of refusals made before that point (check_line's own non-ok line, which may be a `skip` line from status_fields and is printed as-is with exit 2; gate_start's `refuse state` lines; a failed mktemp's exit 1), which the claim does not name.

```bash
# scripts/build-loop.sh:1224-1229
    if [[ -z "${VERDICT[tree]-}" ]]; then cat "$GATE_TMP/line"; exit 2; fi
    if [[ "$AUTH" == self-merge && "${VERDICT[policy]}" != self-merge ]]; then v="refuse $a: the brief's policy is review; --merge lands it only with --approved Q-NNN"
    elif [[ "$AUTH" == approved ]] && ! approval "$APPROVED"; then v="refuse $a: $MERGE_WHY"
    elif land "$AUTH" "$APPROVED"; then v="merged $a ${VERDICT[tip]} ${VERDICT[tree]} $NEW"; else v="refuse $a: $MERGE_WHY"; fi
    { echo "$v"; tail -n +2 "$GATE_TMP/line"; }
    [[ "$v" == merged* ]] || exit 2
```

`v` takes a `merged` value in exactly one place, the `elif land ...` branch, which runs only when land returns 0. Every other assignment starts `refuse $a: `, and the last line exits 2 for anything that is not `merged*`. approval and land run as `if`/`elif` conditions, so `set -euo pipefail` (`scripts/build-loop.sh:294`) cannot abort inside them before a line is printed. Neither reaches an `exit`: approval runs only check_answer, which reads git objects and never calls need_root (`scripts/lib/dev-cycle-read.sh:2086-2113`, read), and land's state_gate/default_gate return a status and do not exit (`scripts/build-loop.sh:375-416`, read). Executed: B1's tests 3 and 8-12 (policy refusal, approval refusals for [2]/[3]/unrecognized/open/working-tree-only/no entry/wrong heading, land refusals, merges) all pass. P1's C8/C9 cases each print `refuse ...` with rc=2 and main unmoved, or `merged ...` with rc=0. P2's C10 case is a land refusal after the commit was written: `refuse ...: the default branch moved after the check`, rc=2.

**Evidence:** `scripts/build-loop.sh:294`, `:1218-1230`, `:1078-1094`, `:1110-1196`; `$S/logs/bats-merge.out`, `$S/logs/probe.out`, `$S/logs/probe2.out`

---

## Claim 8: "approval returns 0 only on an exact `keep Q-NNN` read at MAIN_SHA plus a byte-exact heading `Q-NNN · merge[-gate]-STEM-TIP12`, with `-gate` exactly when VERDICT[gate] is set; including when check_answer's result is odd/unbalanced/quoted"

**Location:** `scripts/build-loop.sh:1078-1094` (approval); `scripts/lib/dev-cycle-read.sh:2043`, `:2068-2073`, `:2086-2113`
**Type:** Behavioral / Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers approval's case on check_answer's line, the exact-equality heading test, the `-gate` selection, and the odd/unbalanced/quoted/dup files (each a refusal); does not establish what a heading line ending in CR does beyond the probe shown (one trailing CR is dropped before the comparison, so "byte-exact" holds for the heading after that drop, not for the raw line), nor the questions-archive file's paths, which go through the same code but were not probed.

```bash
# scripts/build-loop.sh:1079-1093
  local r s="merge-" g=""
  [[ -z "${VERDICT[gate]}" ]] || { s="merge-gate-"; g=" (the merge changes the gate's own code)"; }
  s+="${VERDICT[stem]}-${VERDICT[tip]:0:12}"
  # In this shell, to a file: ANSWER_HEADING would not leave a $(...).
  check_answer "$1" > "$GATE_TMP/answer"; r="$(< "$GATE_TMP/answer")"
  case "$r" in
    "keep $1") ;;
    ...
    *) MERGE_WHY="$1 does not approve this merge: its answer on the default branch is not read as an option ([1], 1 or keep approve)"; return 1 ;;
  esac
  [[ "$ANSWER_HEADING" == "$1 · $s" ]] \
    || { MERGE_WHY="$1 approves no merge of this tip: its heading must read \"$1 · $s\"$g"; return 1; }
```
(excerpt ends :1093; enclosing approval() continues to :1094, read)

The only branch that falls through to the heading test is the quoted pattern `"keep $1"`. The right-hand side of `==` is quoted, so the test is literal string equality, not a glob. check_answer turns every odd/unbalanced/quoted/dup awk result into a `skip $a: ...` line and returns before setting ANSWER_HEADING (`scripts/lib/dev-cycle-read.sh:2101-2104`, read). approval's `"skip $1: "*` arm then refuses. The heading is the line after `### `, with the CR dropped by the awk's `{ sub(/\r$/, "") }` (`:2042`), captured only for the first matching entry (`heading($0) { ...; if (inside) head = substr($0, 5); next }`, `:2043`) and printed only in the single-entry END branch (`:2072`). Executed (P1, `headsrc`):
- unbalanced fence after a good entry: refuse, "the code fence opened at line 8 ... is never closed".
- quoted heading before a good entry: refuse, "line 2 ... is a question heading inside a code fence".
- dup entry: refuse, "more than one entry with this heading".
- odd fence line: refuse, "line 1 ... is a fence-like line".
- heading using `-` for the middle dot, or with two spaces: refuse, "its heading must read".
- `Q-001: keep`: merged.
- a heading line ending in `\r`: **merged**.

The last case is why the verdict is Mostly accurate: the comparison is byte-exact against the heading with one trailing CR dropped, as the lib's own comment says ("CR dropped"). This is not a bypass, because the answer must still sit on main and the visible text is identical. The `-gate` half: B1 test 11 and P1's C9 cases show a gate change refused under `merge-` and landed under `merge-gate-`. B1 test 10 shows a non-gate change refused under `merge-gate-`.

**Evidence:** `scripts/build-loop.sh:1078-1094`; `scripts/lib/dev-cycle-read.sh:2042-2043`, `:2068-2073`, `:2086-2113`; `$S/logs/probe.out` (C8 and C9 sections), `$S/logs/bats-merge.out` (tests 10, 11)

---

## Claim 9: "VERDICT[gate] is set for any diff-tree record (D and T included) whose lower-cased path matches GATE_CODE, and the floor refuses the same paths"

**Location:** `scripts/build-loop.sh:1049`; `scripts/lib/dev-cycle-read.sh:1926`, `:1953-1971`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers gc being set per record with no condition on status or DENY, GATE_CODE tested on the lower-cased path, a deletion-only gate change under `--approved` (merge- refused, merge-gate- landed, capitalised path included), and floor returning 0 for every GATE_CODE path; does not establish a T record's effect on the heading, because the mode rule refuses every T record before VERDICT is filled (only an ok line fills it), and floor may give some gate paths an earlier word (e.g. `instr` for skills/dev-cycle/SKILL.md) rather than `gate`.

```bash
# scripts/build-loop.sh:1048-1050
    nrules "$a" "${oms[$i]}" "${nms[$i]}" "${nos[$i]}" "${ss[$i]}" "$p" "${lps[$i]}"
    [[ ! "${lps[$i]}" =~ $GATE_CODE ]] || gc=1
    [[ -n "$DENY" || -z "$sm" || "$p" == "$a" ]] || srules "$stem" "$p" "${lps[$i]}" "${ss[$i]}" "$co"
```
(excerpt from check_line, `:981-1055`, read whole)

Line 1049 runs for every record the loop reads, whatever its status letter (`[AMDT]`, `:1007`) or DENY. `lps` is the lower-cased path list (`:1045`). In floor, the first branch refuses every truthrule hit, and the next branch refuses every remaining `$lp =~ $GATE_CODE` (`scripts/lib/dev-cycle-read.sh:1957-1958`: `if truthrule "$lp"; then FLOOR_WHY="$TRUTH_WHY"; ... elif [[ "$lp" =~ $GATE_CODE ]]; then FLOOR_WHY=gate`). So every GATE_CODE path returns 0, given the same `$4` that srules passes (`scripts/build-loop.sh:839`). Executed (P1, `headsrc`):
- deleting `scripts/lib/x.sh` under `--approved` with heading merge-: refuse, "must read \"Q-001 · merge-gate-...\" (the merge changes the gate's own code)".
- the same with heading merge-gate-: merged.
- deleting `Skills/Dev-Cycle/SKILL.md` with heading merge-: refuse, needing merge-gate-.
- a T record (file to symlink) on `scripts/lib/x.sh`: refused by the mode rule.
- self-merge `--check` deleting `scripts/dev-cycle.sh` and `scripts/lib/x.sh`, both listed under `Paths: scripts/`: both denied, "the gate's own code".

**Evidence:** `scripts/build-loop.sh:839`, `:981-1055`; `scripts/lib/dev-cycle-read.sh:1926`, `:1953-1971`; `$S/logs/probe.out` (C9 sections)

---

## Claim 10: "The answer is read from the same MAIN_SHA that is commit-tree's first parent and update-ref's old value"

**Location:** `scripts/lib/dev-cycle-read.sh:2099`; `scripts/build-loop.sh:1180`, `:1186`, `:425`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the one MAIN_SHA value used by check_answer's blob read, commit-tree's `-p` and update-ref's old value on the compare-and-swap path, and a race in which main moves to a commit whose answer is [2] right as the answer is read; does not establish the fast-forward path's equivalent guard (merge --ff-only in W, guarded by land's checks that W's HEAD is MAIN_SHA, `:1156-1159`, and by the post-merge `rev-parse` check), which was not raced here.

```bash
# scripts/lib/dev-cycle-read.sh:2099
    r="$(git cat-file blob "$MAIN_SHA:$f" | env LC_ALL=C awk -v id="$a" "$FENCE_AWK$ANSWER_AWK")" \
# scripts/build-loop.sh:1180
    && x="$(gate_git commit-tree --no-gpg-sign -p "$MAIN_SHA" -p "${VERDICT[tip]}" "${VERDICT[tree]}" < "$GATE_TMP/msg")" \
# scripts/build-loop.sh:1186
    git update-ref --no-deref -m "$msg" "refs/heads/$MAIN" "$NEW" "$MAIN_SHA" 2>/dev/null \
```

MAIN_SHA is assigned only in resolve_main (`scripts/lib/dev-cycle-read.sh:531`, `:541`, `:547`; the `:330` line initialises it). resolve_main is called once, at top level (`scripts/build-loop.sh:425`); `grep -n "MAIN_SHA="` across the script and lib finds no other assignment. Executed (P2, C10, `headsrc`): a git shim moves main to a commit whose answer reads `[2]` just before check_answer's `cat-file` of `$M:docs/working/questions.md`. Result: rc=2, `refuse ...: the default branch moved after the check, or could not be updated; it was left as it is`, and main stays at the moved commit. The answer read at M approved, and the swap from M then failed.

**Evidence:** `scripts/build-loop.sh:425`, `:1110-1196`; `scripts/lib/dev-cycle-read.sh:529-548`, `:2086-2113`; `$S/logs/probe2.out` (C10 section)

---

## Claim 11: "After the floor-word refactor, floor refuses the same paths as before (beyond the intended skills/dev-cycle/ widening) and srules' DENY is non-empty for every refusal"

**Location:** `scripts/lib/dev-cycle-read.sh:1953-1990` (floor, floor_why) vs main's floor; `scripts/build-loop.sh:839`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers floor's return value on every branch (unchanged; only FLOOR_WHY's value changed from sentence to word), the word-to-sentence mapping for every word truthrule and floor can set, and an executed main-vs-HEAD differential over 19 paths reaching every floor word except walk and case; does not establish the walk-failure sentence by execution (static: TRUTH_WHERE is `walk_why "$IMPORTED_MAIN_WHY"`, the same expression main's floor used) or the case word, which check_line cannot reach because it passes an already lower-cased `$4`.

The diff `main...HEAD` of floor changes only the right-hand sides of FLOOR_WHY assignments. Every `if`/`elif` test and every `return` is unchanged (paraphrased — no quote available because the claim is about the whole function diff, shown in `git diff main...HEAD -- scripts/lib/dev-cycle-read.sh`). truthrule sets only case, instr, dot, cycle, settings, user and record (`scripts/lib/dev-cycle-read.sh:1875-1881`). Main mapped settings and cycle to the "dev cycle's own files" sentence through `*)`. HEAD maps `settings` to `cycle` (`:1957`), and floor_why words every one of these, plus gate/working/review/walk/imported/below, with main's exact sentences (`:1977-1988`). floor_why's default arm also prints non-empty text: `*) echo "refused by the self-merge floor (${1:-no reason recorded})"` (`:1989`). srules uses it as `DENY="$(floor_why "$FLOOR_WHY")"` (`scripts/build-loop.sh:839`), so DENY is never empty after a floor refusal. Executed (P1 C11): one self-merge brief changes 19 paths, with every path listed in Paths:. The paths reach dot, below (twice), record (four ways, case-folded included), gate (five, case-folded included), imported, review, working, instr and three allowed paths. main's and HEAD's `--check` outputs are identical (`diff rc=0`), and HEAD prints no deny line with an empty reason. P2 C11b: the only difference is the intended widening. `skills/dev-cycle/references/x.md` and `skills/dev-cycle/x.txt` pass on main and are denied on HEAD as "the gate's own code". (`skills/dev-cycle/SKILL.md` was already refused on main as an instruction file.)

**Evidence:** `scripts/lib/dev-cycle-read.sh:1873-1881`, `:1953-1990`; `scripts/build-loop.sh:836-849`; `$S/logs/probe.out` (C11), `$S/logs/probe2.out` (C11b)

---

## Goal-Alignment Note

Success criterion (verbatim): "a report saved to /workspace/.claude/wt-build-loop-u3a3/docs/reviews/code-fact-check-submitted-claims-u3a3.md with `Commit: 01a2935f` at the top, verdicting ONLY the submitted list below, claims numbered from 7."

This report verdicts only submitted claims 7-11, numbered from 7, under `Commit: 01a2935f`. It harvests no claims of its own. Nothing was committed, and every probe wrote only under `$S`. One residual for the security reviewer's wording: claim 8's "byte-exact" holds after one trailing CR is dropped from the heading line, which is documented behaviour and not a bypass.
