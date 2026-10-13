Commit: 722c2e10

# Code Fact-Check Report

**Repository:** claude-workflows (worktree `/workspace/.claude/wt-build-loop-u4a`, branch `feat/build-loop-u4a`)
**Scope:** branch diff `main...feat/build-loop-u4a` (`scripts/build-loop.sh`, `scripts/lib/dev-cycle-read.sh`, `test/scripts/build-loop-orchestrator.bats`) plus commit message 722c2e10
**Checked:** 2026-10-13
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 30
**Summary:** 25 verified, 4 mostly accurate, 0 stale, 0 incorrect, 1 unverifiable

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`, 5 entries) read first. No claim here matches a logged pattern: every symbol the diff names (`isrecord`, `chore_record`, `cycle_rules`, `asked`, `land_cycle`, `GATE_CODE`, `FENCE_AWK`, `merge_result`, `store_check`, `land`) exists at the cited lines.

Execution runs (all exit 0; captured output files, which stay on the host's /tmp):
- **E1, the full suite:** `LC_ALL=C TMPDIR=/tmp/u4a-fc1-tests-auWc bats test/scripts/build-loop-orchestrator.bats`, run in `/workspace/.claude/wt-build-loop-u4a` at 2026-10-13T07:36:20Z. Exit 0, 27/27 ok. Output: `/tmp/u4a-fc1-tests-auWc/out.txt`.
- **E2, the hooks probe:** `bats --show-output-of-passing-tests .../scratchpad/u4a-fc1-probe.bats`, run in `/tmp/u4a-fc1-hooks-YxXp` at 2026-10-13T07:37:08Z. Exit 0. Output: `/tmp/u4a-fc1-hooks-YxXp/out.txt`. It installs reference-transaction, post-merge, post-commit, pre-merge-commit, post-checkout and post-rewrite hooks in the common git dir's `hooks/`, each appending its name to a marks file. It then runs one control `git update-ref`, a compare-and-swap land, a fast-forward land from a linked worktree, and a control `git merge --no-ff --no-edit`.
- **E3, the Asked: edge cases:** `bats --show-output-of-passing-tests .../scratchpad/u4a-fc1-probe2.bats`, run in `/tmp/u4a-fc1-asked-xCCb` at 2026-10-13T07:37:22Z. Exit 0. Output: `/tmp/u4a-fc1-asked-xCCb/out.txt`.
- **E4, two mutants** (the bats exit is 1 for each, as wanted), run at 2026-10-13T07:37:50Z with `bats --filter U4a test/scripts/build-loop-orchestrator.bats` in a copy of `scripts/` and `test/` under `/tmp/u4a-fc1-mut-5B9u/{key,judge}`:
  - Mutant "key" matches Asked: by full path instead of file name.
  - Mutant "judge" replaces `cycle_rules "$MAIN_SHA" || return 1` in `land_cycle` with a no-op.
  - Output: `/tmp/u4a-fc1-mut-5B9u/key.out` and `/tmp/u4a-fc1-mut-5B9u/judge.out`.

---

## Claim 1: "a cycle record the merge adds or changes (docs/working/cycles/cycle-YYYY-MM-DD.md, mode 100644) holding the line "Branch: B""

**Location:** `scripts/build-loop.sh:162-165`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the name, mode and status filter and the Branch: line test in `chore_record` as `log_class` calls it. It does not establish anything about subject parsing or `clean_merge`, which this diff did not change.

`log_class` now delegates to `chore_record`, which filters with `isrecord`:

```bash
# scripts/build-loop.sh:1720-1722 (excerpt; chore_record continues to :1726 — read)
isrecord "${RAW_P[i]}" && [[ "${RAW_NM[i]}" == 100644 && "${RAW_S[i]}" =~ ^[AM]$ ]] || continue
gate_git cat-file blob "${RAW_NO[i]}" | LC_ALL=C awk -v w="Branch: $1" '{ sub(/\r$/, "") } $0 == w { f = 1 } END { exit !f }' && return 0
```

`isrecord` is `^docs/working/cycles/cycle-$DIGIT{4}-$DIGIT{2}-$DIGIT{2}\.md$` (`scripts/lib/dev-cycle-read.sh:246`). E1 test 26's `--main-log` assertion reads a land as `chore`.

**Evidence:** `scripts/build-loop.sh:1716-1726`, `scripts/build-loop.sh:1751-1754`, `scripts/lib/dev-cycle-read.sh:246`

---

## Claim 2: "a path of the gate's own code (GATE_CODE, compared lower-cased) refuses"

**Location:** `scripts/build-loop.sh:216-217`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers every path in the listing, checked before the brief and questions branches, under both `--cycle-diff` and `--land-cycle`. It does not establish the contents of `GATE_CODE` beyond `^scripts/(build-loop|dev-cycle|questions)\.sh$|^scripts/lib/|^skills/dev-cycle/`.

```bash
# scripts/build-loop.sh:1877 (excerpt; cycle_rules continues to :1944 — read)
if [[ "$(lower "$p")" =~ $GATE_CODE ]]; then echo "refuse $p: the gate's own code; an in-cycle fix edits only docs --check-fix allows"; bad=1; continue; fi
```

E1 test 25 refuses `SKILLS/dev-cycle/x.md`, an upper-case path that matches only after lower-casing, and `scripts/lib/a.sh`. Run: E1, cwd `/workspace/.claude/wt-build-loop-u4a`, exit 0, 2026-10-13T07:36:20Z.

**Evidence:** `scripts/build-loop.sh:1877`, `scripts/lib/dev-cycle-read.sh:1965`, `/tmp/u4a-fc1-tests-auWc/out.txt`

---

## Claim 3: "a brief whose first unfenced "Asked:" line, matched by file name (a move to closed/ too), is neither as on BASE nor BASE's line followed by ", " and more (an ID dropped or changed) refuses"

**Location:** `scripts/build-loop.sh:217-220`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the comparison rule for a brief present on both sides, by base name, including the move to closed/. It does not establish the three free cases below, which the header's wording does not name.

The comparison only runs when BASE's line is non-empty and a new side exists:

```bash
# scripts/build-loop.sh:1902-1905 (excerpt; cycle_rules continues to :1944 — read)
for f in "${!ao[@]}"; do
  [[ -n "${ao[$f]}" && -n "${an[$f]+set}" ]] || continue
  [[ "${an[$f]}" == "${ao[$f]}" || "${an[$f]}" == "${ao[$f]}, "* ]] || { echo "refuse ${ap[$f]}: ..."; bad=1; }
done
```

Read literally, the header would refuse three cases that E3 shows pass with `ok`:

- **(a)** A brief with no Asked: line on BASE that gains one. The new line is not "as on BASE".
- **(b)** A new brief.
- **(c)** A brief deleted outright, with no closed/ copy. Its IDs are dropped, but there is no new side to compare.

E3 does confirm that a removed Asked: line refuses, an append without ", " refuses, and an Asked: line inside a fence is ignored. The precise version would read something like: "a brief that had an unfenced Asked: line on BASE and still exists (by file name)...". Case (a) is the intended behaviour per the brief (claim 7 there); (c) is a residue a reader of "(an ID dropped...)" could assume is caught. Run: E3, cwd `/tmp/u4a-fc1-asked-xCCb`, exit 0, 2026-10-13T07:37:22Z.

**Evidence:** `scripts/build-loop.sh:1878-1884`, `scripts/build-loop.sh:1902-1905`, `/tmp/u4a-fc1-asked-xCCb/out.txt`

---

## Claim 4: "after --state's gate but its caller check: HEAD must be on chore/dev-cycle-DATE or chore/dev-cycle-DATE-HHMM, the index as its commit, and --expect the default branch's commit"

**Location:** `scripts/build-loop.sh:223-228`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that `state_start` runs without `caller_gate`, plus the branch regex, the `EXPECT == MAIN_SHA` check and the `diff-index --cached` check. It does not establish that EXPECT really is the commit `--cycle-diff` checked; that is the caller's duty.

- `land-cycle) state_start; land_cycle || exit 2 ;;` (`scripts/build-loop.sh:1996-1999`). `caller_gate` runs only for `--state`: `if [[ "$MODE" == state ]]; then caller_gate || exit 2; fi` (`scripts/build-loop.sh:685`).
- `land_cycle` checks the branch with `^refs/heads/(chore/dev-cycle-$DIGIT{4}-$DIGIT{2}-$DIGIT{2}(-$DIGIT{4})?)$` (`:1952`).
- It then checks `[[ "$EXPECT" == "$MAIN_SHA" ]]` (`:1954`) and `git diff-index --cached --quiet --ignore-submodules=none "$h" --` (`:1957`).
- The argument parser requires `--expect`, once, as a full id (`:520-529`).

E1 test 26 covers the wrong branch, a moved main and staged changes, each with its exact refusal text.

**Evidence:** `scripts/build-loop.sh:520-529`, `scripts/build-loop.sh:685`, `scripts/build-loop.sh:1949-1959`, `scripts/build-loop.sh:1996-1999`, `/tmp/u4a-fc1-tests-auWc/out.txt`

---

## Claim 5: "The merge of HEAD into main, as --check's (merge-tree, no repo config), is judged against main by --cycle-diff's rules with these --answered IDs (what lands: a rename git pairs into a questions file, or a fence pair that captures main's answer, shows here)"

**Location:** `scripts/build-loop.sh:228-232`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that R comes from `merge_result` (run in the gate repository), that the listing is `diff-tree MAIN_SHA R`, that `cycle_rules` judges it with the global ANSWERED, and the rename case, by execution. The fence-pair case was not executed; that part rests on reading `cycle_rules`, which reads the merged file's entries against main's.

```bash
# scripts/build-loop.sh:1961, 1970-1972 (excerpt; land_cycle continues to :1977 — read)
rc=0; r="$(merge_result "$h")" || rc=$?
gate_git diff-tree -r --no-renames --raw -z --ignore-submodules=none "$MAIN_SHA" "$r" > "$GATE_TMP/diff" && raw_records "$GATE_TMP/diff" \
cycle_rules "$MAIN_SHA" || return 1
```

`merge_result` runs `gate_git merge-tree --write-tree --no-messages "$MAIN_SHA" "$1"` (`:1090`). `gate_git` runs in a scratch GIT_DIR whose config is written fresh (`:983-1001`). E1 test 27 shows `--cycle-diff` printing `ok` while `--land-cycle` refuses the same rename. Under E4's "judge" mutant, tests 26 and 27 fail.

**Evidence:** `scripts/build-loop.sh:983-1001`, `scripts/build-loop.sh:1084-1094`, `scripts/build-loop.sh:1961-1972`, `/tmp/u4a-fc1-tests-auWc/out.txt`, `/tmp/u4a-fc1-mut-5B9u/judge.out`

---

## Claim 6: "and must add or change a cycle record holding "Branch: B" (--main-log's chore)"

**Location:** `scripts/build-loop.sh:232-233`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that `land_cycle` calls the same `chore_record` that `log_class` uses, over the MAIN-vs-merge listing. It does not establish that `cycle_rules` leaves RAW_* untouched in every path; by reading, it does not reassign them.

`chore_record "$b" || { echo "refuse HEAD: the merge adds or changes no cycle record ...` (`scripts/build-loop.sh:1973`). E1 test 26 refuses a record holding another branch's line.

**Evidence:** `scripts/build-loop.sh:1716-1726`, `scripts/build-loop.sh:1973`, `/tmp/u4a-fc1-tests-auWc/out.txt`

---

## Claim 7: "Then it writes the merge with the message "Merge branch 'B'" and moves the default branch as --merge does (a compare-and-swap from that commit, or a fast-forward in the worktree that has it checked out; no hooks run)"

**Location:** `scripts/build-loop.sh:233-237`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the message bytes, the parents and tree, the update-ref CAS path, the `merge --ff-only` path, and no hook firing on either path in git 2.39.5. It does not establish behaviour against a hook source that HARDEN's `core.hooksPath=/dev/null` does not cover in later git versions.

```bash
# scripts/build-loop.sh:1531-1532 (excerpt; land continues to :1548 — read)
{ if [[ "$1" == cycle ]]; then printf "Merge branch '%s'\n" "${VERDICT[branch]}"; else gate_msg ...; fi; } > "$GATE_TMP/msg" \
  && x="$(gate_git commit-tree --no-gpg-sign -p "$MAIN_SHA" -p "${VERDICT[tip]}" "${VERDICT[tree]}" < "$GATE_TMP/msg")" \
```

Then `git update-ref --no-deref ... "$NEW" "$MAIN_SHA"` (`:1538`), or `git -C "$w" ... merge --ff-only -q "$NEW"` (`:1544`). Every git call inherits `core.hooksPath=/dev/null` from `git_harden`'s exported pairs (`scripts/lib/dev-cycle-read.sh:352,366`; called at `scripts/build-loop.sh:572`). Results:

- **E2 control:** `git update-ref` fired reference-transaction, and `git merge` fired pre-merge-commit, post-merge and reference-transaction.
- **E2 compare-and-swap land:** marks `[]`.
- **E2 fast-forward land:** marks `[]`.
- **Message:** `Merge branch 'chore/dev-cycle-2026-10-12'`.

Run: E2, cwd `/tmp/u4a-fc1-hooks-YxXp`, exit 0, 2026-10-13T07:37:08Z.

**Evidence:** `scripts/build-loop.sh:1531-1547`, `scripts/lib/dev-cycle-read.sh:352-368`, `/tmp/u4a-fc1-hooks-YxXp/out.txt`

---

## Claim 8: "Prints landed B HEAD TREE NEW — NEW: the merge commit, now the default branch's."

**Location:** `scripts/build-loop.sh:237-239`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the output line's fields and that main reads NEW after the land. It does not establish NEW's reachability after a refusal that comes after the write (see `land`'s own comment).

`echo "landed $b $h $r $NEW"` (`scripts/build-loop.sh:1976`). E1 test 26 asserts `landed $B $H $T $(git rev-parse main)`, with `main^1 = N2`, `main^2 = H` and `main^{tree} = T`.

**Evidence:** `scripts/build-loop.sh:1974-1976`, `/tmp/u4a-fc1-tests-auWc/out.txt`

---

## Claim 9: "or refuse lines and exit 2: --cycle-diff's (PATH a file), or refuse HEAD: WHY — Not on such a branch; the default branch moved ...; staged changes; nothing the default branch lacks; a conflict; an object that does not hash or has two copies; no such record; or --merge's own refusals of the move."

**Location:** `scripts/build-loop.sh:240-245`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the refusal kinds `land_cycle` and `cycle_rules` can print. It does not establish exact wording.

Two qualifiers are missing:

- `cycle_rules` can print `refuse index: the questions files could not be listed` (`scripts/build-loop.sh:1915`) under `--land-cycle`, so PATH is not always a file.
- `land_cycle` has read-failure WHYs the list omits: `its commit could not be read` (`:1955`), `its merge into the default branch could not be computed` (`:1965`) and `the paths its merge changes could not be listed` (`:1971`).

The list's "staged changes" and "nothing the default branch lacks" also cover "or could not be read" variants (`:1958`, `:1960`). The documented kinds are all present.

**Evidence:** `scripts/build-loop.sh:1949-1977`, `scripts/build-loop.sh:1914-1916`

---

## Claim 10: "and --land-cycle's (AUTHORITY cycle, VERDICT and CHANGED set by land_cycle; the message git merge writes, "Merge branch 'B'", which --main-log reads as chore)"

**Location:** `scripts/build-loop.sh:1447-1449`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that `land_cycle` sets VERDICT (tip, tree, branch, stem) and CHANGED before `land cycle`, and that git's default merge into main writes the same subject. It does not establish git's message for a non-main default branch name.

`VERDICT=([tip]="$h" [tree]="$r" [branch]="$b" [stem]="$b"); CHANGED=()` and `land cycle` (`scripts/build-loop.sh:1974-1976`). The E2 control's `git merge --no-ff --no-edit side` on main wrote `Merge branch 'side'`.

**Evidence:** `scripts/build-loop.sh:1462-1466`, `scripts/build-loop.sh:1974-1976`, `/tmp/u4a-fc1-hooks-YxXp/out.txt`

---

## Claim 11: "chore_record B: a cycle record among RAW_* (isrecord, added or changed, mode 100644) holds the line "Branch: B" (a trailing CR dropped) ... Returns 1 when none does or a read fails."

**Location:** `scripts/build-loop.sh:1712-1715`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the filter, the CR strip and the failed-read path. That path depends on `set -euo pipefail` at `:497` and on gate_git returning 3 when it writes to stderr. It does not establish behaviour if a caller turned pipefail off.

`set -euo pipefail` (`scripts/build-loop.sh:497`). The awk runs `sub(/\r$/, "")` before an exact compare (`:1722`). The loop falls through to `return 1` (`:1725`).

**Evidence:** `scripts/build-loop.sh:497`, `scripts/build-loop.sh:996-1001`, `scripts/build-loop.sh:1716-1726`

---

## Claim 12: (diff/brief) log_class's chore class is unchanged by the refactor except the record name narrowing to cycle-YYYY-MM-DD.md

**Location:** `scripts/build-loop.sh:1751-1754`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the old inline loop against `chore_record`. It does not establish that no record named otherwise exists on any real main (such a record now reads as `other`).

Old: `[[ "${RAW_P[i]}" =~ ^docs/working/cycles/cycle-[^/]+\.md$ && ... ]] || continue; ... && { CLASS=chore; return 0; }` (main's `scripts/build-loop.sh:1706-1708`). New: `! chore_record "$b" || CLASS=chore` (`:1754`), followed by the function's `return 0`. Same mode, status, awk and pipefail; only the name test differs.

**Evidence:** `scripts/build-loop.sh:1734-1766`, `scripts/build-loop.sh:1716-1726`, diff hunk `@@ -1702,11 +1752,7 @@`

---

## Claim 13: "asked FILE: a brief's first "Asked:" line outside a fence (as brief_fields reads it, a trailing CR dropped), or nothing."

**Location:** `scripts/build-loop.sh:1864-1865`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers a well-formed brief, where `asked` and `brief_fields` read the same first unfenced, case-sensitive `^Asked:` line after the same CR strip. It does not cover a brief FENCE_AWK refuses after the Asked: line, or one with an unbalanced fence: `brief_fields` reads no field from such a file, while `asked` still prints the line.

`asked() { LC_ALL=C awk "$FENCE_AWK"'{ sub(/\r$/, "") } fence($0) { next } /^Asked:/ { print; exit }' "$1"; }` (`scripts/build-loop.sh:1867`). By contrast, `brief_fields` prints only `odd ...` or `unbalanced ...` when either is set, with no fields: `END { if (odd) print "odd " ...; else if (infence) print "unbalanced " fline; else for ...` (`scripts/lib/dev-cycle-read.sh:449`).

E3's case "html after Asked" appends `<div>` after `Asked: Q-001@abc`. `--cycle-diff` printed `ok`, because the line was read as equal, whereas `brief_fields` would read that brief as `odd`. The precise version: "as brief_fields reads a well-formed brief". Run: E3, exit 0, 2026-10-13T07:37:22Z.

**Evidence:** `scripts/build-loop.sh:1867`, `scripts/lib/dev-cycle-read.sh:435-460`, `/tmp/u4a-fc1-asked-xCCb/out.txt`

---

## Claim 14: "cycle_rules BASE: the cycle's rules over RAW_* (raw_records of a listing against BASE): --cycle-diff's (BASE the merge base, the listing the index) and --land-cycle's (BASE main's commit, the listing the merge it writes)."

**Location:** `scripts/build-loop.sh:1868-1871`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers both call sites and their BASE and listing. It does not establish that the listing's tree R is the tree `land` writes; Claim 7 shows it is, through `VERDICT[tree]=r`.

`cycle_diff` calls `cycle_rules "$base"` after `git diff-index --cached ... "$base"` (`:1856-1861`). `land_cycle` calls `cycle_rules "$MAIN_SHA"` after `diff-tree "$MAIN_SHA" "$r"` (`:1970-1972`). `VERDICT[tree]="$r"` is what `commit-tree` writes (`:1974`, `:1532`).

**Evidence:** `scripts/build-loop.sh:1852-1862`, `scripts/build-loop.sh:1970-1974`, `scripts/build-loop.sh:1532`

---

## Claim 15: "So the questions files must be as on main: merge the default branch into HEAD first (always so for --land-cycle, which judges the merge itself)."

**Location:** `scripts/build-loop.sh:1911-1913`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that with BASE = MAIN_SHA both `ls-tree` listings name the same commit, so the guard never fires under `--land-cycle`. It does not establish whether the guard's refusal text ("stage again") would suit `--land-cycle`, since that text is unreachable there.

```bash
# scripts/build-loop.sh:1914-1916 (excerpt; cycle_rules continues to :1944 — read)
gate_git ls-tree -z "$base" -- docs/working/questions.md docs/working/questions-archive.md > "$t.lb" \
  && gate_git ls-tree -z "$MAIN_SHA" -- docs/working/questions.md docs/working/questions-archive.md > "$t.lm" || { ...; return 1; }
cmp -s "$t.lb" "$t.lm" || { echo "refuse docs/working/questions.md: the default branch changed ..."; return 1; }
```

Under `--land-cycle`, `base` is `$MAIN_SHA` (`:1972`), so the two commands are identical.

**Evidence:** `scripts/build-loop.sh:1914-1916`, `scripts/build-loop.sh:1972`

---

## Claim 16: "land_cycle: --land-cycle's lines: HEAD's chore branch lands on the default branch as a merge --main-log reads as chore (D13; rows 719, 749, 752, 753). Prints "landed BRANCH HEAD TREE NEW", or refuse lines; returns 1 on any."

**Location:** `scripts/build-loop.sh:1946-1948`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the output contract and the chore reading by `--main-log`. The row list is a cross-reference, checked in Claim 24b.

E1 test 26 lands, then runs `--main-log`, whose `lines[1]` is `chore <main> Merge branch '$B'`.

**Evidence:** `scripts/build-loop.sh:1949-1977`, `/tmp/u4a-fc1-tests-auWc/out.txt`

---

## Claim 17: "The land takes HEAD's commit, never the index: anything staged would stay behind."

**Location:** `scripts/build-loop.sh:1956`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that the tip is `HEAD^{commit}`, that staged changes refuse, and that the index plays no part in R. It does not establish anything about untracked or worktree-only files, which are neither checked nor relevant.

`h="$(git rev-parse --verify -q 'HEAD^{commit}')"` (`:1955`), then `git diff-index --cached --quiet ... "$h"` (`:1957`). E1 test 26 stages `o.md` and gets `refuse HEAD: the index holds changes its commit lacks...`.

**Evidence:** `scripts/build-loop.sh:1955-1958`, `/tmp/u4a-fc1-tests-auWc/out.txt`

---

## Claim 18: "The merge as it lands, against main: rename pairing and a fence pair that captures main's answer show here, not in --cycle-diff's index (row 753)."

**Location:** `scripts/build-loop.sh:1968-1969`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** The rename case is executed. The fence-pair case is static: the merged questions file is read whole against main's copy by QKEYS/QDIFF. That case is not executed.

E1 test 27 runs `cd_is ok`, then `lc_is "refuse docs/working/questions.md: Q-001 is a new entry filed answered ..."` on the same HEAD. E4's "judge" mutant fails test 27.

**Evidence:** `scripts/build-loop.sh:1968-1972`, `scripts/build-loop.sh:1917-1943`, `/tmp/u4a-fc1-tests-auWc/out.txt`, `/tmp/u4a-fc1-mut-5B9u/judge.out`

---

## Claim 19a: "build-loop.sh's --main-log and --land-cycle read its Branch: lines" / "dev-cycle.sh reads the window from these names"

**Location:** `scripts/lib/dev-cycle-read.sh:243-245`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the two `chore_record` callers and dev-cycle.sh's name glob. dev-cycle.sh uses its own glob, `cycle-[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9].md` (`scripts/dev-cycle.sh:225`), not `isrecord`.

The `chore_record` callers are `scripts/build-loop.sh:1754` and `:1973`. dev-cycle.sh's window reader is `for f in docs/working/cycles/cycle-[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9].md; do` (`scripts/dev-cycle.sh:225`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:246`, `scripts/build-loop.sh:1754`, `scripts/build-loop.sh:1973`, `scripts/dev-cycle.sh:225`

---

## Claim 19b: "A cycle record: one per day, updated in place by each iteration"

**Location:** `scripts/lib/dev-cycle-read.sh:243`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** The name form allows one file per date. That each iteration updates the same file in place is the orchestrator's (skill's) behaviour, which U4b writes and no code in this diff enforces.

Paraphrased (no quote available because the claim covers orchestrator behaviour that no code in scope implements): `isrecord` admits exactly one name per date. Nothing in the diff writes records.

**Evidence:** `scripts/lib/dev-cycle-read.sh:243-246`

---

## Claim 20: test "--cycle-diff refuses the gate's own code and a brief's Asked: line other than extended, matched by name across a move to closed/ (row 745, U4a)"

**Location:** `test/scripts/build-loop-orchestrator.bats:466`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that the test passes on HEAD and fails under E4's "key" (full-path) mutant. Pre-change code would print `ok` for each refusal. It does not pin the free cases noted in Claim 3.

E1 marks it ok. E4 "key" marks it `not ok 1`.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:466-476`, `/tmp/u4a-fc1-tests-auWc/out.txt`, `/tmp/u4a-fc1-mut-5B9u/key.out`

---

## Claim 21: test "--land-cycle lands HEAD's chore branch as the merge --main-log reads as chore, by compare-and-swap or a fast-forward where main is checked out (D13, rows 719, 749, 752, U4a)"

**Location:** `test/scripts/build-loop-orchestrator.bats:482`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers both move paths, the parents, the tree, the message and the `--main-log` chore reading. It does not exercise the CAS losing a race (main moving between check and update-ref), nor hooks (E2 covers hooks).

The test passes in E1. It fails under E4's "judge" mutant, because the answered-questions refusal no longer fires.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:482-504`, `/tmp/u4a-fc1-tests-auWc/out.txt`, `/tmp/u4a-fc1-mut-5B9u/judge.out`

---

## Claim 22: test "--land-cycle judges the merge, not the index: a rename git pairs into a new questions file carries main's answer, and a conflict refuses (row 753, U4a)"

**Location:** `test/scripts/build-loop-orchestrator.bats:506`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the rename case and a conflict refusal. It does not cover the fence-pair case named in the header.

The test asserts that the merged tree holds `Q-001: [1]`, then expects the refusal. It passes in E1 and fails under E4's "judge" mutant.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:506-515`, `/tmp/u4a-fc1-mut-5B9u/judge.out`

---

## Claim 23: "--cycle-diff's guard compares the questions files' listings, which neither side has on the base (U3c's confirming pass)."

**Location:** `test/scripts/build-loop-orchestrator.bats:510`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers this fixture, where neither the base nor main has `docs/working/questions.md`. The `ls-tree` listings are both empty, so `cmp` passes. It does not establish the general case.

`cd_is ok` on the following line passes in E1. The guard is at `scripts/build-loop.sh:1914-1916`.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:507-511`, `scripts/build-loop.sh:1914-1916`

---

## Claim 24a: commit 722c2e10: "then commit-tree with "Merge branch 'B'" and land's compare-and-swap or fast-forward (no hooks run ...)"

**Location:** commit 722c2e10 message, paragraph 2
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Same scope and evidence as Claim 7.

E2: both land paths left the marks file empty, while plain git fired the hooks.

**Evidence:** `scripts/build-loop.sh:1531-1547`, `/tmp/u4a-fc1-hooks-YxXp/out.txt`

---

## Claim 24b: commit 722c2e10: "(no hooks run: rows 719, 749, 752)"

**Location:** commit 722c2e10 message, paragraph 2
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the mapping of the land's properties to the cited override rows. It does not establish whether the orchestrator's own chore commit runs hooks; that commit is outside this diff.

Row 749 (`docs/reviews/override-log.md:749`) concerns "The orchestrator's commit runs the common dir's hooks after --cycle-diff passed; a planted pre-commit hook could re-stage files". Its trigger asks to "commit with core.hooksPath=/dev/null (or commit-tree from `git write-tree`) and check the new commit's tree against the index --cycle-diff read".

The land's no-hooks property does not address the chore commit's hooks. What covers 749's risk is that `--land-cycle` re-judges HEAD's commit (merged) with `cycle_rules`, so a re-staged file is judged at land time. The rows are answered, but the parenthetical ties 749 to the wrong mechanism. Paraphrased (no quote available because the claim is a cross-reference to a log row, quoted above).

**Evidence:** `docs/reviews/override-log.md:749`, `scripts/build-loop.sh:1955-1972`

---

## Claim 25: commit 722c2e10: "a brief's first Asked: line other than extended refuses, matched by file name across a move to closed/"

**Location:** commit 722c2e10 message, paragraph 3
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the base-name keying across the D and A sides of a move. Claim 3's free cases apply here too (no Asked: on the old side, a new brief, a deletion without a copy).

`ao[${p##*/}]` and `an[${p##*/}]` are keyed by base name (`scripts/build-loop.sh:1881-1882`). E1 test 25 renames into closed/ and changes the line, which refuses. E4's "key" mutant fails it.

**Evidence:** `scripts/build-loop.sh:1878-1884`, `/tmp/u4a-fc1-mut-5B9u/key.out`

---

## Claim 26: commit 722c2e10: "isrecord is the one record-name predicate (row 725; the record stays cycle-YYYY-MM-DD.md, so dev-cycle.sh's window reader is unchanged)"

**Location:** commit 722c2e10 message, paragraph 3
**Type:** Architectural / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the fact that `writable` and `chore_record` both use `isrecord`, and that `scripts/dev-cycle.sh` is not in the diff. It does not establish a single matcher repo-wide, since dev-cycle.sh keeps its own equivalent glob; the parenthetical acknowledges that.

`writable() { [[ ... ]] || isrecord "$1" || anybrief "$1"; }` (`scripts/lib/dev-cycle-read.sh:248`). `git diff --name-only main...HEAD` lists no `scripts/dev-cycle.sh`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:246-249`, `scripts/build-loop.sh:1721`, `scripts/dev-cycle.sh:225`

---

## Claim 27: commit 722c2e10: "A deleted roadmap now reads "it is deleted""

**Location:** commit 722c2e10 message, Notes
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the roadmap and idea-log D branch of `cycle_rules`.

`if [[ "${RAW_S[i]}" == D ]]; then echo "refuse $p: it is deleted"; bad=1` (`scripts/build-loop.sh:1891`). In E1, test 24's updated expectation passes.

**Evidence:** `scripts/build-loop.sh:1891`, `test/scripts/build-loop-orchestrator.bats:459`, `/tmp/u4a-fc1-tests-auWc/out.txt`

---

## Claim 28: commit 722c2e10: "from the main commit --cycle-diff checked (a moved main refuses), HEAD's commit only (staged changes refuse), merge-tree's clean merge judged against main by --cycle-diff's rules ..., a cycle record holding "Branch: B" required"

**Location:** commit 722c2e10 message, paragraph 1
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Same coverage as Claims 4, 5, 6 and 17. That `--expect` really is the commit `--cycle-diff` checked is a caller duty, not verified.

E1 tests 26 and 27 exercise each refusal named here.

**Evidence:** `scripts/build-loop.sh:1949-1977`, `/tmp/u4a-fc1-tests-auWc/out.txt`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 3** (`scripts/build-loop.sh:217-220`): the header implies every Asked: change refuses. A brief with no Asked: on BASE, a new brief, and a brief deleted outright (IDs dropped, no closed/ copy) are all free (E3). Narrow the wording to "a brief that held an Asked: line on BASE and still exists by file name".
- **Claim 9** (`scripts/build-loop.sh:240-245`): the refusal list omits the read-failure WHYs (`:1955`, `:1965`, `:1971`). It also omits `refuse index:` from `cycle_rules` (`:1915`), which is not "PATH a file".
- **Claim 13** (`scripts/build-loop.sh:1864-1865`): "as brief_fields reads it" holds only for a well-formed brief. For a brief FENCE_AWK refuses after its Asked: line, or one with an unbalanced fence, brief_fields reads nothing while `asked` prints the line (E3 "html after Asked" passed `ok`).
- **Claim 24b** (commit 722c2e10): "(no hooks run: rows 719, 749, 752)". Row 749 is about the orchestrator's chore commit's hooks. The land answers it by re-judging HEAD's commit, not by running no hooks.

### Unverifiable
- **Claim 19b** (`scripts/lib/dev-cycle-read.sh:243`): "one per day, updated in place by each iteration" is orchestrator behaviour (U4b's skill), not code in scope.

---

## Goal-Alignment Note

- **User goal:** land unit U4a of the build-loop handoff once its review-fix loop is clean.
- **Current task:** fact-check the comments, header text, test names and commit message of `feat/build-loop-u4a` vs main (722c2e10) against the code, by execution where possible.
- **Success criterion:** a markdown report saved at the exact path your own prompt names, structured per your skill.
- **Alignment:** the report is at `docs/reviews/code-fact-check-report-2026-10-13-u4a-i1.md`, with the required header and seven fields per claim plus a Legibility-target. All eight brief focus items are covered: header (1-9), no hooks (7, 24), judged tree and parents (5, 7, 14), the questions guard (15), the commit message (24-28), log_class (12), the Asked: rule (3, 13) and the tests (20-23, with mutants). No Incorrect claim. The four Mostly-accurate items are comment and doc wording only; none is a behavioural defect in the code's stated contract. Of the residues, Claim 3's free deletion is the one a security reader may want to weigh. Probes ran only under `/tmp/u4a-fc1-*` and the session scratchpad; nothing in /workspace or the worktree was written except this report.
