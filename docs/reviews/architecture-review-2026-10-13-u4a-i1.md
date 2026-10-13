Commit: 722c2e10

# Architecture Review: feat/build-loop-u4a, iteration 1 (full branch vs main)

**Scope:** `git diff main...HEAD` at 722c2e10: `scripts/build-loop.sh`, `scripts/lib/dev-cycle-read.sh`, `test/scripts/build-loop-orchestrator.bats`. Plan D7/D11/D13 and step 10's U4a bullet were read as context.
**Date:** 2026-10-13
**Based on:** `docs/reviews/code-fact-check-report-2026-10-13-u4a-i1.md` (25 verified, 4 mostly accurate, 0 incorrect). Trust Boundary Map from `docs/reviews/security-review-2026-10-12-u3c-i2.md` (Commit: `74deb04e`). That security review predates this diff, so its boundaries may be stale.

Scope check: in scope. The diff adds a public mode (`--land-cycle`) and a third `land()` authority (`cycle`). It splits `cycle_diff` into a shared `cycle_rules BASE`, extracts `chore_record` shared by two callers, and adds a lib predicate (`isrecord`) to `dev-cycle-read.sh`'s surface.

Complete-unit reading: I read every function this review cites whole: `land`, `land_cycle`, `cycle_diff`, `cycle_rules`, `chore_record`, `log_class`, `check_line`, `merge_result`, `store_check`, `gate_msg`, `state_start` and the mode dispatch `case`. I also read `scripts/dev-cycle.sh:200-232`. The only probe was the bash `set -u` check in finding 4: it ran `bash -c` on a literal and touched no repository.

## Dependency Map

- **Mode dispatch → mode functions.** `--land-cycle` runs `state_start`, then `land_cycle`. `--cycle-diff` runs `state_start`, then `cycle_diff`. `--merge` runs `gate_start`, `check_line`, the authority check inside the dispatch `case`, then `land`.
- **`land_cycle`** calls `merge_result`, `store_check`, `gate_git diff-tree`, `raw_records`, `cycle_rules "$MAIN_SHA"`, `chore_record "$b"` and then `land cycle`. Before `land` runs, it fills the globals `VERDICT` and `CHANGED`.
- **`cycle_diff`** calls `git diff-index --cached`, then `raw_records`, then `cycle_rules "$base"`. Both callers now share one rule set over the `RAW_*` globals, each with a different BASE and a different listing.
- **`land`** is the one D7 move: commit-tree, then a CAS or `merge --ff-only` in W. It now has three authorities: `self-merge` and `approved` (message from `gate_msg`), and `cycle` (an inline `printf "Merge branch '%s'"`).
- **`chore_record`** reads `RAW_*`, `isrecord` (lib) and `gate_git`. Its callers are `log_class` (the `--main-log` reader) and `land_cycle` (the writer's pre-check). The writer and reader of the chore class therefore share one record test. They do not share the message definition (finding 3).
- **The lib** (`dev-cycle-read.sh`) gains `isrecord`, used by `writable` and `chore_record`. `scripts/dev-cycle.sh:225` sources the lib but keeps its own glob.

Dependency direction holds: the scripts depend on the lib, and the lib depends on nothing in them. No cycle is introduced.

## Findings

#### 1. `land_cycle` re-implements `check_line`'s D7 compute-and-list front half, and the copies already differ

**Severity:** Minor
**Location:** `scripts/build-loop.sh:1961-1971` (land_cycle) vs `scripts/build-loop.sh:1342-1368` (check_line)
**Move:** 2 (responsibility boundaries) / 7 (coupling)
**Confidence:** Medium
**Legibility-target:** for-author

**Evidence (verbatim):**

```bash
# scripts/build-loop.sh land_cycle (excerpt; land_cycle continues to :1977 — read)
rc=0; r="$(merge_result "$h")" || rc=$?
case "$rc" in
  0) ;;
  1) echo "refuse HEAD: it conflicts with the default branch; ..."; return 1 ;;
  *) echo "refuse HEAD: its merge into the default branch could not be computed"; return 1 ;;
esac
store_check "$h" "$r" || { echo "refuse HEAD: an object of HEAD or of the merge ..."; return 1; }
gate_git diff-tree -r --no-renames --raw -z --ignore-submodules=none "$MAIN_SHA" "$r" > "$GATE_TMP/diff" && raw_records "$GATE_TMP/diff" \
```

`check_line` runs the same sequence: `merge_result`, the same `rc` case, `diff-tree` with the same options, `raw_records` and `store_check`. It also has a missing-blob batch check ("merge-tree passes a side's unchanged blob by id without reading it, so a blob the store lacks would land unseen"), which `land_cycle` does not have.

By reading `store_check`, I found the omission is not a gap. It walks `ls-tree -r -t` of R, and a `missing` line from `cat-file --batch` fails its regex. But nothing in `land_cycle` says so. A reader cannot tell whether the omission is deliberate, and the next D7 hardening added to `check_line` has no pointer to its second copy. This is D7's one pipeline ("merge-tree → diff-tree rules → commit-tree → CAS") written twice, with a third derivation in `clean_merge`, which is already a deferred row.

**Recommendation:** Factor the shared part into one helper, e.g. `merge_listing TIP`, which sets R and `RAW_*` or a WHY code that each caller words. At minimum, add a one-line comment in `land_cycle` saying why `store_check` covers the missing-blob case.

#### 2. `cycle_rules`' refusal texts keep `--cycle-diff`'s vocabulary under `--land-cycle`

**Severity:** Minor
**Location:** `scripts/build-loop.sh:1915`, `:1916`, `:1932-1933`
**Move:** 3 (module boundary: a shared unit's output contract)
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

**Evidence (verbatim):**

```bash
... > "$t.lm" || { echo "refuse index: the questions files could not be listed"; return 1; }
cmp -s "$t.lb" "$t.lm" || { echo "refuse docs/working/questions.md: ... merge it into HEAD, then stage again"; return 1; }
k=base; [[ "$p" == o ]] || k=index; md="$(LC_ALL=C awk -v id=Q- "$FENCE_AWK$ANSWER_AWK" "$t.$p")" || md="unread"
[[ -z "$md" ]] || { echo "refuse $f: --check-answer refuses its $k copy whole ($md)"; return 1; }
```

Under `--land-cycle`, the "index" copy is the merge R and the "base" is main's commit. So a land refusal can say "refuses its index copy whole" about a file that is not in any index. It can also print `refuse index:`, which is not the "PATH a file" that the header promises (fact-check Claim 9). The "stage again" text cannot be reached there.

When the function was split, its inputs became parameters (BASE, the listing), but its output vocabulary was not. U4b's SKILL.md will parse and quote these lines for both modes.

**Recommendation:** Pass the side labels in, e.g. `cycle_rules BASE OLD NEW`, with `base index` from `cycle_diff` and `main merge` from `land_cycle`. Or use neutral words ("its old copy", "its new copy") and a path subject in place of `index`.

#### 3. The chore merge message has two literals (land's writer, log_class's reader), and `land` now branches on authority in two places

**Severity:** Minor
**Location:** `scripts/build-loop.sh:1531` (writer), `:1751` (reader), `:1463-1466` (the `what` switch)
**Move:** 8 (extension points) / 7 (coupling)
**Confidence:** High
**Legibility-target:** for-author

**Evidence (verbatim):**

```bash
# land (excerpt; land continues to :1548 — read)
[[ "$1" != cycle ]] || what="cycle land"
...
{ if [[ "$1" == cycle ]]; then printf "Merge branch '%s'\n" "${VERDICT[branch]}"; else gate_msg "${VERDICT[branch]}" "$what" "${VERDICT[stem]}" "${2-}"; fi; } > "$GATE_TMP/msg" \
```

```bash
# log_class (excerpt; log_class continues to :1766 — read)
elif [[ ${#ps[@]} -eq 2 && "$SUBJ" =~ ^Merge\ branch\ \'(chore/dev-cycle-...)\'($|\ into\ |:) ]]; then
```

Row 662 made `gate_msg` "the one definition of the merge message land writes and --main-log reads as gate". The new chore message does not follow that discipline: the writer is a `printf` inside `land`, and the reader is a regex in `log_class`. Neither cites the other. Drift fails closed: the land would read as `other` and stop dispatch. Test 26 pins it end to end through `--main-log`.

`land`'s message is also a concern of its caller, not of the move. Each new authority adds a branch to two switches in `land`, which is the move every authority shares.

**Recommendation:** Add a `chore_msg B` beside `gate_msg`, commented as the form `log_class`' chore regex must accept. Or have the caller write `$GATE_TMP/msg` and pass `land` only the reflog label, so `land` stays the authority-blind move that D7 describes.

#### 4. The VERDICT/CHANGED contract now has two producers with different key sets

**Severity:** Minor
**Location:** `scripts/build-loop.sh:1974-1975` (land_cycle) vs `:1316-1322` and `verdict_ok` in check_line, and `land`'s header comment at `:1444-1449`
**Move:** 6 (substitutability) / 7 (coupling through globals)
**Confidence:** Medium
**Legibility-target:** for-author

**Evidence (verbatim):**

```bash
VERDICT=([tip]="$h" [tree]="$r" [branch]="$b" [stem]="$b"); CHANGED=()
for i in "${!RAW_P[@]}"; do CHANGED[${RAW_P[i]}]="${RAW_S[i]}"; done
```

`check_line`'s documented contract is: "VERDICT holds tip, tree, policy, branch, stem and gate". `land_cycle` sets four of those six keys, with no `policy` and no `gate`. `land` reads only the four today.

The script runs `set -euo pipefail`. Under bash 5.2 `set -u`, reading an unset associative key aborts the run: a probe printed `V[b]: unbound variable` with exit 127. So a later edit to `land` that reads `${VERDICT[gate]}`, as `approval` already does, would kill `--land-cycle` mid-run instead of refusing.

A second implicit ordering contract sits beside this one. `land_cycle` relies on `cycle_rules` never re-filling `RAW_*` between `raw_records` and `chore_record` and the `CHANGED` loop. That holds today by reading, but nothing states it.

**Recommendation:** State in `land`'s header which VERDICT keys it may read (tip, tree, branch, stem), and have `land_cycle` set `[policy]= [gate]=` empty for parity. Add a line in `cycle_rules`' header saying it reads `RAW_*` and never re-lists.

#### 5. `isrecord` is one predicate for build-loop.sh, but dev-cycle.sh keeps an unpinned equivalent glob, and the lib comment names its consumers' modes

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:243-246`; `scripts/dev-cycle.sh:225`
**Move:** 3 (module boundary)
**Confidence:** High
**Legibility-target:** for-author

**Evidence (verbatim):**

```bash
# A cycle record: one per day, updated in place by each iteration (dev-cycle.sh
# reads the window from these names; build-loop.sh's --main-log and
# --land-cycle read its Branch: lines).
isrecord() { [[ "$1" =~ ^docs/working/cycles/cycle-$DIGIT{4}-$DIGIT{2}-$DIGIT{2}\.md$ ]]; }
```

```bash
for f in docs/working/cycles/cycle-[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9].md; do
```

Row 725 asked for "one isrecord predicate in the lib". Inside build-loop.sh it is now one: `writable` and `chore_record` share it, and the `log_class` narrowing (`cycle-*.md` to `cycle-YYYY-MM-DD.md`) closes row 725's three-way mismatch.

dev-cycle.sh sources the same lib but enumerates with its own glob, and no test pins the two as equal. The lib comment also lists consumer modes by name ("--main-log and --land-cycle"), a reference from the lib up to its callers that goes stale silently.

This crosses no labelled trust boundary in the security map (`docs/reviews/security-review-2026-10-12-u3c-i2.md`, Commit: `74deb04e`; security review predates this diff; boundary may be stale).

**Recommendation:** In dev-cycle.sh, filter a broad glob with `isrecord`: `for f in docs/working/cycles/cycle-*.md; do isrecord "$f" || continue`. Or add a one-line test that pins the two. Describe the record format in the lib comment rather than its callers.

#### 6. `cycle_rules`' questions guard is a `--cycle-diff`-only precondition inside the shared rule set

**Severity:** Informational
**Location:** `scripts/build-loop.sh:1909-1916`
**Move:** 2 (responsibility boundaries)
**Confidence:** High
**Legibility-target:** for-author

**Evidence (verbatim):**

```bash
# must be as on main: merge the default branch into HEAD first (always so
# for --land-cycle, which judges the merge itself).
gate_git ls-tree -z "$base" -- docs/working/questions.md docs/working/questions-archive.md > "$t.lb" \
  && gate_git ls-tree -z "$MAIN_SHA" -- docs/working/questions.md docs/working/questions-archive.md > "$t.lm" || ...
```

With `BASE=MAIN_SHA`, the compare is equal by construction (fact-check Claim 15), so for one of the two callers the shared function carries a guard that is dead in all but its read-failure path. This is the only rule in `cycle_rules` that is about the caller's listing (index vs fork point) rather than about the change. That is the kind of difference the split was meant to put in the callers.

This bears on `B4` from `docs/reviews/security-review-2026-10-12-u3c-i2.md` (Commit: `74deb04e`; security review predates this diff; boundary may be stale): "[chore branch + main's concurrent commits] → [3-way merge at land: NOT re-checked]". `--land-cycle` now re-checks at that crossing. That is a strengthening, so moving the guard would not relocate the boundary: `--land-cycle` judges the merge itself.

**Recommendation:** Optional. Move the guard into `cycle_diff`, run when `RAW_P` holds a questions path, so `cycle_rules` judges a listing and nothing else. Or leave it, given the comment already names the tautology.

#### 7. The plan's decision text (D7, D13, script interface) does not yet name the cycle land; the fit itself is good

**Severity:** Informational
**Location:** `docs/working/plan-build-loop-handoff.md:84` (D7), `:97-103` (D13), `:206-215` (script interface); `skills/dev-cycle/SKILL.md:387`
**Move:** 4 (layers: decision record vs as-built)
**Confidence:** High
**Legibility-target:** for-plan

**Evidence (verbatim):**

- D7: "then `commit-tree R -p MAIN -p TIP` with a `Build-loop-gate: <stem>` trailer, and a CAS on main."
- SKILL.md:387: "land `chore/dev-cycle-<date>` on the default branch through `pr-prep`".

**On fit:** moving the chore land from a hand `git merge` (through pr-prep) into a gated script mode matches D7 well.

- **D7's sequence is kept:** merge-tree, then rules on `diff-tree MAIN R`, then commit-tree, then CAS or a hardened `--ff-only`. The fact-check executed this (Claims 5, 7, 14), and the result is R as written with parents MAIN_SHA and HEAD.
- **Rows 719 and 752 are removed:** a hand merge runs hooks and reads repo merge config. The gated mode does neither.
- **D13 holds:**
  - The chore class `--main-log` reads is written by the same `chore_record` test that reads it.
  - Dispatch's `merge-base --is-ancestor <chore tip> main` holds, because the tip is parent 2.
  - D11 is unaffected, because the orchestrator stays the only questions writer.

What lags is the decision text. D7 describes only the trailer-bearing gate message. D13 and the script interface do not list `--land-cycle`, so step 10's U4a bullet is the only description of the mode. SKILL.md is U4b's to rewrite.

**Recommendation:** In U4a's as-built note, amend D7 ("the cycle authority writes git's own `Merge branch 'B'` and no trailer, so `--main-log` reads it as chore") and D13 ("the chore branch lands by `--land-cycle --expect` the MAIN_SHA `--cycle-diff` checked"). Add the mode to the script interface list.

## What Looks Good

- **`cycle_rules BASE` as the shared rule set.** It is parameterised by base, and the listing comes in through `RAW_*`. The land therefore judges what lands (merge vs main), while `--cycle-diff` keeps judging the index. This answers row 753 structurally, not with a second rule copy.
- **`chore_record` shared by `log_class` and `land_cycle`.** The writer's pre-check and the reader's classification cannot disagree on what a record is. The `log_class` refactor is behaviour-preserving apart from the intended name narrowing (fact-check Claim 12).
- **`land_cycle` reuses `land` for the move.** It does not write a third CAS or fast-forward path, so all of W's guards (worktree scan, state gate re-run, untracked collision via CHANGED) apply to the chore land unchanged.
- **The authority check for `cycle` lives in `land_cycle`**, next to the code that computes the verdict. The new mode needs no `gate_start` (settings and floor), which is correct, because it applies `cycle_rules` and not the N/S rules.
- **Dependency direction is clean:** `isrecord` lives in the lib, and both scripts depend downward on it.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | land_cycle duplicates check_line's D7 compute-and-list; copies already differ (missing-blob check) | Minor | `scripts/build-loop.sh:1961-1971` | Medium |
| 2 | cycle_rules' refusal texts say "index"/"stage again" under --land-cycle | Minor | `scripts/build-loop.sh:1915-1916, 1932-1933` | High |
| 3 | Chore message: two literals (land printf, log_class regex); land branches on authority twice | Minor | `scripts/build-loop.sh:1531, 1751, 1465` | High |
| 4 | VERDICT has two producers with different keys; set -u abort risk; RAW_* ordering unstated | Minor | `scripts/build-loop.sh:1974-1975` | Medium |
| 5 | isrecord vs dev-cycle.sh's own glob, unpinned; lib comment names callers | Informational | `scripts/lib/dev-cycle-read.sh:243-246`, `scripts/dev-cycle.sh:225` | High |
| 6 | Questions guard is a --cycle-diff-only precondition inside shared cycle_rules | Informational | `scripts/build-loop.sh:1909-1916` | High |
| 7 | D7/D13/script-interface text does not name the cycle land (fit itself good) | Informational | `docs/working/plan-build-loop-handoff.md:84, 97-103` | High |

## Overall Assessment

The change keeps the system's structural integrity and improves it in the area under review. The cycle land goes through D7's computed path and `land`'s single move rather than a hand merge. The rules are shared through one parameterised function, and the chore class has one record test for its writer and its reader. Nothing is Structural or Coupling-grade. Every issue can be fixed in place.

The most important concern is the output contract of the newly shared units (findings 2 and 4). `cycle_rules` and the VERDICT globals now serve two callers whose vocabularies and key sets differ. U4b's SKILL.md will parse both modes' refusal lines, so wording that names the index under `--land-cycle` is the issue most likely to cost later. Finding 1's duplication is the one most likely to drift silently on the next D7 hardening.

## Goal-Alignment Note

- **User goal:** land unit U4a of the build-loop handoff (claude-workflows) once its review-fix loop is clean.
- **Current task:** architecture review of `feat/build-loop-u4a` vs main at 722c2e10, focused on the `cycle_rules` split, `land()`'s third authority, `chore_record`, `isrecord`, and fit with plan D7/D13.
- **Success criterion (verbatim):** "a markdown report saved at the exact path your own prompt names, structured per your skill."
- **Alignment:**
  - **Saved where named:** `docs/reviews/architecture-review-2026-10-13-u4a-i1.md`, first line `Commit: 722c2e10`, structured per the architecture-review skill.
  - **Per-finding fields:** each finding carries Severity, Location, verbatim Evidence, Confidence and Legibility-target.
  - **Focus items:** all five are covered: the split (2, 6), the third authority and its message branch (3, 4), `chore_record` (4 and What Looks Good), `isrecord` (5), and D7/D13 fit (7).
  - **Blocking:** no finding blocks landing.
