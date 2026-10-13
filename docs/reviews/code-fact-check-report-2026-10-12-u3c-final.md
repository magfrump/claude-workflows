# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u3c (branch `feat/build-loop-u3c`)
**Scope:** full branch diff `main...ec9dace7` (main = dafc0e74): `docs/reviews/override-log.md` (the eight rows this branch added, 745-752), `docs/working/plan-build-loop-handoff.md` (lines 104, 209, the U3c bullet 327-333), `scripts/build-loop.sh`, `scripts/health-check.sh`, `scripts/lib/dev-cycle-read.sh` (the ANSWER_AWK pointer comment), `test/scripts/build-loop-orchestrator.bats`, `test/scripts/health-check-lock.bats`, and the bodies of commits 6f347256, 3021d0a4, f34fceb0, 414c9295, d77dae74, ec9dace7. Merged from replicates r1, r2 and r3 (`code-fact-check-report-2026-10-12-u3c-final-r{1,2,3}.md`).
**Checked:** 2026-10-12
**Commit:** ec9dace7
**Replication:** k=3
**Total claims checked:** 59
**Summary:** 44 verified, 12 mostly accurate, 0 stale, 2 incorrect, 1 unverifiable

Note: the behavioral Incorrect (fenced question heading) was fixed in 4aad0f9c after this pass; wording items too.

**Merge notes.** This is mechanical collation per code-review SKILL.md "Merging replicate verdicts (most-severe-wins)": claims clustered on (file, ±5 lines, substance) at the finest granularity any replicate used; the most severe verdict wins; evidence and Scope come from the winning replicate (ties: most specific Scope, then lowest replicate number); annotations are the union, attributed. Three conventions are used in the `Replicate verdicts` lines:
- `(compound)`: the replicate verdicted a larger claim that contains this row.
- `(via multi-location Claim N)`: the replicate's claim listed this text as a secondary location beside its primary one.
- `(compound, apportioned)`: the replicate's compound verdict was not uniform. Its own Scope or prose confines the non-Verified part to a sibling row, so this row carries the verdict the replicate gave this part. This is used twice, on Claims 42 and 59. Both cases are stated in their annotations.

Replicate scratch dirs (execution logs live there, not in the repo; see Escalation E-4): S1 = `/tmp/claude-1000/-workspace/f335f5f6-1b17-4519-891d-602641cba507/scratchpad/fc-u3c-final-r1`, S2 = `.../fc-u3c-final-r2`, S3 = `.../fc-u3c-final-r3`. The execution provenance (commands, cwd, exit codes, UTC timestamps) is in each replicate report's provenance table. Run labels below are prefixed with the replicate: r1:E5 is r1's run E5, and so on.

---

## Claim 1: "Re-keys row 722 ... --cycle-diff judges only the questions files, the roadmap and the idea log; every other staged path is not judged"

**Location:** `docs/reviews/override-log.md:745`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which staged paths cycle_diff reads; does not establish anything about how U4 commits the other paths (the row's own deferral).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "does not establish that a mode or 100644 check applies to other paths (none does), and it does not cover the state gate that runs before cycle_diff" · r3: "does not establish anything about how U4 will list the unjudged paths"

```bash
# scripts/build-loop.sh:1813-1817
    case "$p" in
      docs/working/questions.md|docs/working/questions-archive.md) qi+=("$i"); continue ;;
      docs/roadmap.md|docs/working/idea-log.md) ;;
      *) continue ;;
    esac
```
(excerpt ends inside the loop; cycle_diff continues to :1866 — read). Test 24 stages `other.md` with the cycle's rewrites and gets `ok` (r1:E2).

**Evidence:** `scripts/build-loop.sh:1811-1829`, `test/scripts/build-loop-orchestrator.bats` test 24, `S1/logs/blo.log`

---

## Claim 2: "Row 724 discharged: one `raw_records` reads every `--raw -z` listing whole ... Equivalent to the three old readers, but log_class's chore loop now reads a commit with an unparsed or incomplete record as other instead of skipping the record"

**Location:** `docs/reviews/override-log.md:746`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers acceptance of check_line's and log_class's answers loop (unchanged) and the chore loop's one change; does not establish timing (Claim 57) and was not run against a malformed listing (git does not print one).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: Claim 2 also lists f34fceb0's body and `docs/working/plan-build-loop-handoff.md:331` as locations; "does not establish timing, beyond confirming that raw_records forks nothing"; r2 grep found four `--raw` listings (`:1312`, `:1701`, `:1708`, `:1807`) and ran the full check, merge, read and orchestrator suites green (r2:E1, r2:E5) · r3: "does not establish behaviour for raw listings outside build-loop.sh (none in the diff)"; full check, merge and orchestrator suites green (r3:E5)

The old check_line read `while IFS= read -r -d '' meta && IFS= read -r -d '' p` with the same regex, then refused unless the NUL count was `2 * ${#ps[@]}`. The new code is `raw_records "$GATE_TMP/diff" || { echo "refuse $a: the paths the merge of $br changes could not be read"; return; }` (`scripts/build-loop.sh:1316`), with the same text. raw_records returns 1 on a half record (`IFS= read -r -d '' p || return 1`, :975) or an unparsed meta (:976). The answers loop keeps `[[ ${#RAW_P[@]} -gt 0 ]]` and the same `100644 100644 M` + path test (:1706-1709). The chore loop now ends with `raw_records "$GATE_TMP/d" || return 0` (:1701), so CLASS stays other.

**Evidence:** `scripts/build-loop.sh:965-980`, `scripts/build-loop.sh:1316-1318`, `scripts/build-loop.sh:1700-1710`

---

## Claim 3: "The orchestrator's chore commit must take the index as --cycle-diff read it ... --cycle-diff reads the index only"

**Location:** `docs/reviews/override-log.md:747`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the fact that cycle_diff reads only the index (diff-index --cached) and never the work tree. The U4 duty itself is not yet built, so it is not verified here.
**Replicate verdicts:** r1=— · r2=Verified · r3=Verified
**Replicate annotations:** r2: Claim 3 also lists `docs/working/plan-build-loop-handoff.md:329` (the same U4 duty) as a location · r3: "does not establish that the later `git commit` takes that index (the row's U4 duty)"

```bash
# scripts/build-loop.sh:1807
  if ! git diff-index --cached --raw -z --no-renames --ignore-submodules=none "$base" > "$t.raw" 2>"$GATE_TMP/err" \
```
(excerpt ends :1807; the condition continues to :1810 — read) Blobs are then read by id through cyc_blob, which uses gate_git cat-file (`:1798-1801`).

**Evidence:** `scripts/build-loop.sh:1798-1810`

---

## Claim 4: "`--answered` is the orchestrator's own claim and is never recorded"

**Location:** `docs/reviews/override-log.md:748`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the fact that ANSWERED feeds QDIFF_AWK's `ok[]` exemption and nothing else, with no output naming the listed IDs. It does not cover U4's future recording.
**Replicate verdicts:** r1=— · r2=Verified · r3=Verified
**Replicate annotations:** r3: "does not establish what U4 will record"

The IDs are only appended (`ANSWERED+=("$2")`, `scripts/build-loop.sh:491`) and passed as `-v ids="${ANSWERED[*]}"` (`:1859`). In QDIFF_AWK, `!(id in ok)` guards both refusals (`:1770-1771`). On success the only output is `echo ok` (`:1885`).

**Evidence:** `scripts/build-loop.sh:486-491`, `scripts/build-loop.sh:1758-1775`, `scripts/build-loop.sh:1859`, `scripts/build-loop.sh:1882-1886`

---

## Claim 5: "The orchestrator's commit runs the common dir's hooks after --cycle-diff passed; a planted pre-commit hook could re-stage files"

**Location:** `docs/reviews/override-log.md:749`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the fact that --cycle-diff neither commits nor pins the tree it checked. It does not establish U4's commit command (not built); that a pre-commit hook can change what gets committed is git's documented behaviour, not re-executed.
**Replicate verdicts:** r1=— · r2=Verified · r3=— · single-replicate detection
**Replicate annotations:** none

cycle_diff ends with `return "$bad"` (`scripts/build-loop.sh:1866`), and the mode prints `ok` (`:1885`) without recording a tree id (paraphrased — no quote available because the claim covers absence of code: no write-tree or tree output in cycle_diff or the mode's case arm).

**Evidence:** `scripts/build-loop.sh:1803-1867`, `scripts/build-loop.sh:1882-1886`

---

## Claim 6: "health-check.sh's wait for the lock is unbounded ...; a FIFO swapped in between the plain-file test and flock's open hangs instead of refusing; flock missing exits with flock's own status ... every failure exits non-zero"

**Location:** `docs/reviews/override-log.md:750`
**Type:** Behavioral / Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the unbounded wait (the second flock has no `-w`), the window between the type test and the open, and the non-zero exit when flock is missing. It does not establish the FIFO hang by execution (only the type test's refusal was executed, in T43).
**Replicate verdicts:** r1=Verified · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r1 (cites the row as :749): executed both halves. `timeout 3 flock -n "$T/fifo" true` gave rc 124 (it blocked in open, not a lock conflict). Missing flock gave rc 127, which take_lock passes to `exit "$rc"`. r1 reads "flock's own status" as "the status of the flock command line, 127". It "does not establish the race window itself (not raced)" · r2+r3: "flock missing" is bash's command-not-found 127, not a status flock produces; "every failure exits non-zero" holds; r3's precise text is "flock missing exits 127 (the shell's not-found status)" · r3: the FIFO race "needs a same-uid swap mid-call" to execute

```bash
# scripts/health-check.sh:1109-1118
    if [[ -L "$lk" || ( -e "$lk" && ! -f "$lk" ) ]]; then
        red "health-check.lock in $d is not a plain file"; exit 1
    fi
    export HEALTH_CHECK_LOCK_HELD=1
    flock -n -E 75 -o "$lk" bash "$REPO_ROOT/scripts/health-check.sh" "$@" || rc=$?
    if [[ "$rc" -eq 75 ]]; then
        yellow "waiting for another health check in this repository (health-check.lock)"
        rc=0; flock -o "$lk" bash "$REPO_ROOT/scripts/health-check.sh" "$@" || rc=$?
    fi
    exit "$rc"
```
There is no `-w` timeout, so the wait is unbounded. The imprecision is "exits with flock's own status": when flock is absent, bash returns 127 (command not found), `rc=127`, and the script exits 127, which is non-zero but not a status flock produces.

**Evidence:** `scripts/health-check.sh:1104-1119`

---

## Claim 7: "the live roadmap's preamble holds a dated 're-checked' line ... the Done match now follows dev-cycle.sh"

**Location:** `docs/reviews/override-log.md:751`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers main's docs/roadmap.md preamble and the Done-match expression; does not establish that dev-cycle.sh reads a Done section (it matches Now, In flight and Next with the same rule).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: also covers "the rule copies SKILL.md step 6's prose, which does not point back to it" (grep for `cycle-diff` in `skills/dev-cycle/SKILL.md` finds nothing) and lists ec9dace7 B5 as a location; "does not establish that either predicate accepts a tab after 'Done': neither does, since the 'blank' in the header means a space" · r3: "does not establish that dev-cycle.sh reads a Done section anywhere (it reads Next and named sections with the same predicate)"

`git show main:docs/roadmap.md` preamble: "Seeded 2026-09-29 by hand; first re-checked by the dev cycle on 2026-10-02". ROADMAP_AWK: `done[s] = (d == "## done" || index(d, "## done ") == 1 || index(d, "## done(") == 1)` (`scripts/build-loop.sh:1781`); dev-cycle.sh: `t == g || index(t, g " ") == 1 || index(t, g "(") == 1` (`scripts/dev-cycle.sh:490`).

**Evidence:** `scripts/build-loop.sh:1779-1794`, `scripts/dev-cycle.sh:442`, `scripts/dev-cycle.sh:490`

---

## Claim 8: "--cycle-diff now refuses a questions change while main has changed the questions files since the fork point"

**Location:** `docs/reviews/override-log.md:752`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the refusal when either questions file differs between base and MAIN_SHA and the index changes a questions file; does not establish anything about a main that moves after the check (the row's U4 duty).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1 cites the row as :751 · r2: Claim 8 also lists plan :104, :328, header :197-200 and ec9dace7 B1. Its scope "does not apply this guard to the roadmap or the idea log, which have none (see Escalations)" (E-3). r2's P3 shows that main changing questions.md with the index untouched gives `ok` · r3: "does not establish a check when the index changes neither (then the merge takes main's copy, nothing to capture)"; r3 P4b gives the same `ok` result

```bash
# scripts/build-loop.sh:1835-1838
  if ! gate_git ls-tree -z "$base" -- docs/working/questions.md docs/working/questions-archive.md > "$t.lb" \
    || ! gate_git ls-tree -z "$MAIN_SHA" -- docs/working/questions.md docs/working/questions-archive.md > "$t.lm" || ! cmp -s "$t.lb" "$t.lm"; then
    echo "refuse docs/working/questions.md: the default branch changed the questions files since the fork point $base, ..."; return 1
  fi
```
r1:E3 P2a: main changed only the archive, index edited a questions.md body line → exit 2 with this line. T38's case passes (r1:E2) and is red with the block deleted (r1:E6 b).

**Evidence:** `scripts/build-loop.sh:1830-1838`, `S1/logs/probe.log`, `S1/m-SN14/b.log`

---

## Claim 9: "compares the staged files with the fork point of HEAD and MAIN_SHA ..., and refuses a questions change while main has changed the questions files since then"

**Location:** `docs/working/plan-build-loop-handoff.md:104`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the base and the main-changed rule as written at :104; does not establish the "roadmap or idea-log line removed or edited other than by the cycle's own documented moves" beyond the interim reading (Claim 13).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (via multi-location Claim 8) · r3=Verified
**Replicate annotations:** r1: its Claim 6 covers :104 and :209 together · r3: "does not establish the detail limits recorded in Claims 11, 14 and 17" of r3 (merged Claims 12, 17, 22)

`base="$(git merge-base HEAD "$MAIN_SHA" 2>/dev/null)"` (`scripts/build-loop.sh:1805`); diff-index against `$base` (:1807); main-changed rule per Claim 8.

**Evidence:** `docs/working/plan-build-loop-handoff.md:104`, `scripts/build-loop.sh:1803-1866`, `S1/logs/blo.log`

---

## Claim 10: "`--cycle-diff [--answered Q-…]` → `ok`, or `refuse PATH: why` (exit 2); run in the orchestrator's worktree against the fork point of HEAD and `MAIN_SHA`"

**Location:** `docs/working/plan-build-loop-handoff.md:209`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the output shape and the base. It does not cover state-gate refusals, which print `refuse state ...` lines, also with exit 2; those are documented in the Exit paragraph (Claim 25).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r3: "does not cover the `refuse state …` lines state_gate/state_start print first (exit 2)" (same residue as the winner's)

The mode arm is `state_start; cycle_diff || exit 2; echo ok` (`scripts/build-loop.sh:1882-1886`), and the base is `git merge-base HEAD "$MAIN_SHA"` (`:1805`). T38 asserts these exact lines and statuses (r2:E1).

**Evidence:** `scripts/build-loop.sh:1805`, `scripts/build-loop.sh:1882-1886`, `S2/logs/orch.txt`

---

## Claim 11: "the index is compared with `git merge-base HEAD MAIN_SHA` (MAIN_SHA itself when main has not moved) ... No merge base (HEAD unborn or unrelated) refuses"

**Location:** `docs/working/plan-build-loop-handoff.md:328`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers unborn HEAD, HEAD on main, detached HEAD at main and a chore branch with main moved; does not establish behaviour with several merge bases (git prints one) or an unrelated history with commits (static only: merge-base exits 1, same refusal).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2+r3: executed the committed unrelated history (r2 P4, r3 P7: `refuse HEAD`) and an earlier chore-branch commit that flips an answer (r2 P5, r3 P3: refused), closing r1's static-only clause · r2: "does not establish ... BASE's object integrity, which is documented as not re-hashed"; Claim 10 also lists the header at `scripts/build-loop.sh:185-189` and the 6f347256 and f34fceb0 Notes · r2+r3: criss-cross histories not established

T38 test 24's `git checkout -q --orphan lone; cd_is "refuse HEAD: it shares no commit ..."` passes (r1:E2). r1:E3 P2b (on main) and P2c (detached at main) print `ok`. With the base mutated to MAIN_SHA, T38 fails at `onmain docs/roadmap.md "# R"; cd_is ok --answered Q-001` (r1:E7).

**Evidence:** `scripts/build-loop.sh:1805`, `S1/logs/probe.log`, `S1/m2-iiWd/base.log`

---

## Claim 12: "each entry as `--check-answer` delimits it (FENCE_AWK first; a refused file refuses), its key lines are its heading, its `**Needs:**` lines and its answer lines"

**Location:** `docs/working/plan-build-loop-handoff.md:330`
**Type:** Behavioral / Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers heading match, entry end, fence tracking, CR handling and the key-line set; does not hold for ANSWER_AWK's "quoted" whole-file skip (a `### Q-` heading inside a fence), which QKEYS_AWK does not model (Claim 17).
**Replicate verdicts:** r1=Mostly accurate · r2=Verified · r3=Mostly accurate
**Replicate annotations:** r2: verdict Verified, but its Scope says "It does not establish parity for ANSWER_AWK's two whole-file skips that QKEYS_AWK lacks, `quoted` ... and `dup`; see the residue under Escalations. It also does not establish parity for a heading form outside `### Q-<digits>`." Claim 11 also lists the header :190-197 and commits f34fceb0 and d77dae74. Its P1, P10 and P11 executed the dup-heading, filed-answered and exact-ID cases · r3: precise version "FENCE_AWK first; a file FENCE_AWK refuses refuses; a fenced question heading does not"

Same residue as Claim 17: QKEYS_AWK skips a fenced heading as fenced content, while ANSWER_AWK skips the whole file (`infence && /^### Q-[0123456789]+ / { if (!qline) qline = NR; inside = 0 }`, `scripts/lib/dev-cycle-read.sh:2082`). r1's precise version: "delimited as --check-answer delimits one, except that a fenced `### Q-` heading, which makes --check-answer skip the whole file, is not refused".

**Evidence:** `scripts/build-loop.sh:1743-1751`, `scripts/lib/dev-cycle-read.sh:2061-2120`, `S1/logs/probe3.log`

---

## Claim 13: roadmap and idea-log interim rule (idea log append-only; preamble and `## ` lines fixed; a brief named outside Done never dropped; every other path not judged)

**Location:** `docs/working/plan-build-loop-handoff.md:331`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three refusals and the closed/ rename; does not establish that SKILL.md step 6 only performs moves this rule passes (U4's text).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "does not establish that a brief named only on a `## ` heading line or in the preamble is tracked (it is not; both are frozen instead). It also does not cover CR-only edits, which are invisible because `sub(/\r$/, "")` runs first"; Claim 12 also lists header :200-209 and f34fceb0 · r3: "does not establish detection of a brief named under a subdirectory of `briefs/` other than `closed/` (not matched: P12), nor of a brief named only in the preamble"; P10 (empty base idea log, appended) passes

Test 24 (r1:E2) covers each refusal and the cycle's rewrites. r1:E3 also ran three probes, each giving `ok`: P3a (a brief dropped from plain Done), P3c (`a.md` → `closed/a.md`) and P3d (a new idea log).

**Evidence:** `scripts/build-loop.sh:1779-1794`, `scripts/build-loop.sh:1820-1828`, `S1/logs/blo.log`, `S1/logs/probe.log`

---

## Claim 14: "takes flock on `$(git rev-parse --git-common-dir)/health-check.lock` (plain file only, as the dispatch lock), printing one line when it waits; a run inside a run ... is exempt through an exported variable"

**Location:** `docs/working/plan-build-loop-handoff.md:333`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers take_lock in one repository; does not establish behaviour across linked worktrees beyond the common dir (static: `--git-common-dir` is shared).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "does not cover a bounded wait (there is none)"; the plain-file test is "the same predicate as the dispatch lock's at `scripts/build-loop.sh:1926`" · r3: "does not compare it with the dispatch lock's own rule ('as the dispatch lock')"

`lk="$d/health-check.lock"` with `d` from `--git-common-dir` (`scripts/health-check.sh:1107-1108`); plain-file test (:1109-1111), as dispatch's "Only a plain file is opened (a FIFO would block)" (`scripts/build-loop.sh:1923`); one `yellow "waiting for another health check ..."` (:1115); `export HEALTH_CHECK_LOCK_HELD=1` (:1112). T43 passes (r1:E1); dropping the exemption deadlocks T43 (r1:E7).

**Evidence:** `scripts/health-check.sh:1104-1119`, `S1/logs/hcl.log`, `S1/logs/mutants2.log`

---

## Claim 15: "after --state's gate but its caller check: the index against BASE, git merge-base of HEAD and main's commit"

**Location:** `scripts/build-loop.sh:183-188`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the startup order for MODE cycle-diff; does not establish what state_gate checks (prior units).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "It does not establish what a caller's environment can redirect without caller_gate: for example, GIT_INDEX_FILE would redirect the index that diff-index reads. That consequence is not documented here." · r3: "does not cover the D6 snippet that U4 will run around it"

```bash
# scripts/build-loop.sh:646-649
GATED=""; [[ "$MODE" =~ ^(settings|status|marker)$ ]] || GATED=1
# The caller's environment first: it can point the state gate's own reads elsewhere.
if [[ "$MODE" == state ]]; then caller_gate || exit 2; fi
if [[ -n "$GATED" ]]; then state_gate || exit 2; fi
```
Then `cycle-diff) state_start; cycle_diff || exit 2; echo ok` (:1882-1885).

**Evidence:** `scripts/build-loop.sh:646-656`, `scripts/build-loop.sh:1256-1262`, `scripts/build-loop.sh:1882-1885`

---

## Claim 16: "PATH is HEAD (no merge base), index (not listed) or the file."

**Location:** `scripts/build-loop.sh:189-190`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every refuse line cycle_diff prints. It does not cover state-gate lines.
**Replicate verdicts:** r1=Verified · r2=Mostly accurate · r3=—
**Replicate annotations:** r1: verdict Verified, but its Scope says it "does not establish that 'the file' is the file main changed (the main-changed refusal names questions.md even when only the archive changed, E3 P2a; its WHY says 'the questions files')"

Two refusals that concern both questions files always name `docs/working/questions.md`:
```bash
# scripts/build-loop.sh:1837
    echo "refuse docs/working/questions.md: the default branch changed the questions files since the fork point $base, ..."; return 1
# scripts/build-loop.sh:1860
    || { echo "refuse docs/working/questions.md: the entries could not be compared"; return 1; }
```
In r2's P2 only the archive changed on main, and the line named questions.md. Precise wording: "or the file (questions.md for a refusal about both questions files)".

**Evidence:** `scripts/build-loop.sh:1837`, `scripts/build-loop.sh:1859-1860`, `S2/logs/probe1.txt`

---

## Claim 17: "The questions files, read together (an entry may move between them, delimited as --check-answer reads them; a copy FENCE_AWK refuses refuses)"

**Location:** `scripts/build-loop.sh:190-193`
**Type:** Behavioral / Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers reading both files together, entry moves, FENCE_AWK refusals and delimitation for every shape --check-answer reads; does not hold for a base copy --check-answer skips as "quoted", where --cycle-diff passes an index that makes the file readable and turns an entry's --check-answer result from skip into keep with no --answered.
**Replicate verdicts:** r1=Mostly accurate · r2=Verified (via multi-location Claim 11) · r3=Mostly accurate
**Replicate annotations:** r2: its Claim 11 excludes the `quoted` and `dup` whole-file skips (Escalations) · r3: "does not hold for --check-answer's 'quoted' whole-file skip, which a free body-line edit can lift without changing any key line". r3:E4 reproduced this independently: a stray fence pair hides Q-002's heading, the fenced heading line is deleted, `--cycle-diff` gives `ok`, and after the merge the result is `keep Q-001`. Precondition: "main already holds a fenced question heading (the lib says no real file has one)"

Heading rule, entry end, fence handling and CR drop match ANSWER_AWK. QKEYS_AWK uses `/^### Q-[0123456789]+([ \t]|$)/`, `/^(#|##|###) / { id = ""; next }`, `{ sub(/\r$/, "") }` and `fence($0) { next }` (`scripts/build-loop.sh:1744-1747`), against the same shapes in `scripts/lib/dev-cycle-read.sh:2080-2087`. ANSWER_AWK's "quoted" refusal (`infence && /^### Q-[0123456789]+ / { if (!qline) qline = NR; inside = 0 }`, :2082) has no counterpart in QKEYS_AWK. r1:E5 P5 ran the shape in four steps:
- On main, `--check-answer Q-001` printed `skip Q-001: line 7 of docs/working/questions.md is a question heading inside a code fence ...`.
- The chore index deleted only that fence block.
- `--cycle-diff` printed `ok`.
- After a `--no-ff` land, `--check-answer Q-001` printed `keep Q-001`.

The answer line was already on the base.

**Evidence:** `scripts/build-loop.sh:1737-1751`, `scripts/build-loop.sh:1841-1858`, `scripts/lib/dev-cycle-read.sh:2061-2120`, `S1/logs/probe3.log`

---

## Claim 18: "an entry on BASE whose heading, **Needs:** or answer lines (--main-log's labels, any ID) differ in the index, in order, or are gone; a new entry filed answered (Status ANSWERED or an answer line); WHY starts with its ID"

**Location:** `scripts/build-loop.sh:193-195`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers QDIFF_AWK's two refusal kinds and the --answered match; does not establish the quoted-file residue (Claim 17).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (via multi-location Claim 11) · r3=Verified (compound)
**Replicate annotations:** r1: `answered()` flags any Needs field equal to `**Status:** ANSWERED`, "a superset of ANSWER_AWK's last-Status-field rule (E3 P4a: `ANSWERED · OPEN` fields refuse)" · r3: its Claim 15 covers the header 183-213. It reads the deletion sentence as scoped to the roadmap and idea log; see Claim 23

Labels: QKEYS_AWK `t ~ /^Q-[0123456789]+:/ || tolower(t) ~ /^\*\*answer(:|ed| \()/` (:1750) equals ANSWERS_AWK's (:1657). T38 test 22 (r1:E2) covers these cases: a flip, an answer added, a deleted entry, swapped answers, a route change, a removed answer, a deleted archive, body edits, an open new entry and a pre-answered new entry.

**Evidence:** `scripts/build-loop.sh:1752-1772`, `scripts/build-loop.sh:1859-1865`, `S1/logs/blo.log`, `S1/logs/probe.log`

---

## Claim 19: "Except IDs given with --answered (…; exact IDs, Q-14 is not Q-014; a repeat or an unused one is ignored). Other entry lines are free."

**Location:** `scripts/build-loop.sh:195-198`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers QDIFF_AWK's `ok[]` lookup; does not establish argument parsing beyond `^Q-[0-9]+$`.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (via multi-location Claim 11) · r3=Verified
**Replicate annotations:** r2: P11 executed: `--answered Q-001` does not exempt `Q-1`

```awk
# scripts/build-loop.sh:1765 (QDIFF_AWK)
BEGIN { n = split(ids, x, " "); for (i = 1; i <= n; i++) ok[x[i]] = 1 }
```
String keys (exact), a set (repeats collapse), consulted only for IDs present (`!(id in ok)`, `:1770-1771`).

**Evidence:** `scripts/build-loop.sh:1758-1772`

---

## Claim 20: "A questions change while main has changed those files since BASE refuses (--check-answer reads the merge, where a free fence pair can capture main's newer answer): merge main into HEAD first."

**Location:** `scripts/build-loop.sh:200-203`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the refusal and its recovery (merge main, then base = MAIN_SHA); does not establish the fence-capture mechanism itself (executed by i2 security F1, not re-run here).
**Replicate verdicts:** r1=Verified · r2=Verified (via multi-location Claim 8) · r3=—
**Replicate annotations:** r2: cites the header text as :197-200 · r3: its Claim 15 (header compound, Verified) lists main-changed among the refusals it covers

See Claim 8. T38's last lines merge main and get `ok` (r1:E2).

**Evidence:** `scripts/build-loop.sh:1830-1838`, `S1/logs/blo.log`, `S1/m-SN14/b.log`

---

## Claim 21: "docs/working/idea-log.md other than appended to (BASE's bytes start the index's)."

**Location:** `scripts/build-loop.sh:203-204`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a modified idea log; a new idea log is not judged (Claim 23) and a deleted one refuses.
**Replicate verdicts:** r1=Verified · r2=Verified (via multi-location Claim 12) · r3=—
**Replicate annotations:** r3: its Claim 15 (header compound, Verified) lists the idea-log refusal. r3 P10 (an empty base idea log, then appended) passes with `cmp -n 0`

```bash
# scripts/build-loop.sh:1823-1824
      k="$(wc -c < "$t.o")"
      [[ "$(wc -c < "$t.n")" -ge "$k" ]] && cmp -s -n "$k" "$t.o" "$t.n" || { echo "refuse $p: edited other than by appending"; bad=1; }
```
Test 24 (`s/i1/i0/` refused, an appended line passes; r1:E2).

**Evidence:** `scripts/build-loop.sh:1821-1824`, `S1/logs/blo.log`

---

## Claim 22: "docs/roadmap.md: ... (Done as dev-cycle.sh reads a section: "## Done", any case, alone or before a blank or "(")"

**Location:** `scripts/build-loop.sh:204-210`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three refusals and the Done match for a space or "(" after "## Done"; "a blank" is a space only: a tab after "## Done" makes the section not Done.
**Replicate verdicts:** r1=Mostly accurate · r2=Verified (via multi-location Claim 12) · r3=Mostly accurate
**Replicate annotations:** r2: its Claim 7 notes that neither predicate accepts a tab, "since the 'blank' in the header means a space" (wording read as intended) · r3: precise wording "alone or before a space or '('"; fails closed, same as dev-cycle.sh (P11)

`index(d, "## done ") == 1 || index(d, "## done(") == 1` (:1781) tests a space, not a tab. r1:E3 P3b used a base heading `## Done<TAB>(x)`. That heading is not Done, so dropping its brief line refuses. dev-cycle.sh's section rule behaves the same way, so the failure is closed. The precise version would say "before a space".

**Evidence:** `scripts/build-loop.sh:1779-1794`, `scripts/dev-cycle.sh:490`, `S1/logs/probe.log`

---

## Claim 23: "A deletion, a side not a regular 100644 file, or a failed read refuses; a new roadmap or idea log, and every other path, is not judged."

**Location:** `scripts/build-loop.sh:209-212`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the roadmap and the idea log, where the sentence is exact for deletions and modes. It does not cover two edges the sentence implies otherwise: a deleted questions file and a new roadmap's mode.
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Verified (compound)
**Replicate annotations:** r1: "a questions file's deletion is not refused as a deletion: it refuses only through its entries' key lines going away". r1 P1a (deleting an entry-less questions.md) gives `ok`, and so does P1b (moving the archive's only entry, then deleting the archive). "Neither changes what --check-answer reads" · r3: Verified, "read as scoped to the roadmap and idea log (where it sits)"; deleting a questions file whose IDs are all in `--answered` or that holds no entry passes (P1); P13 (questions.md made 100755) refuses

For the roadmap and the idea log, `if [[ "${RAW_S[i]}" == D ]]; then echo "refuse $p: the index deletes it"` (`:1820`) and the cyc_blob mode test (`:1818`) behave as stated. Two imprecisions:
- (a) A deleted questions file is not refused as a deletion. It is judged through its entries, so deleting a questions file that holds no `### Q-` entry passes (r2 P8, `ok`, exit 0).
- (b) "A new roadmap ... is not judged" leaves out one check. A new roadmap's index side must still be mode 100644, because both sides go through cyc_blob before the `000000` skip (`:1818-1819`). r2's P9 added a symlink roadmap, and the result was `refuse docs/roadmap.md: a side is not a regular file`.

Neither edge lets an answer through.

**Evidence:** `scripts/build-loop.sh:1818-1828`, `S2/logs/probe1.txt`

---

## Claim 24: "As --main-log, BASE's objects are not re-hashed: it catches the orchestrator's own slip, not a forged commit."

**Location:** `scripts/build-loop.sh:212-214`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers which objects store_check re-hashes for this mode (MAIN_SHA's commit and tree only); does not establish that the index's blobs are re-hashed (they are not either).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "It does not establish the threat model." · r3: "BASE equals MAIN_SHA only when main has not moved"

state_start: `store_check --main "$MAIN_SHA"` (:1260); cycle_diff reads base and index blobs through `gate_git cat-file blob` / `ls-tree` (:1798-1801, :1835, :1847) with no store_check call.

**Evidence:** `scripts/build-loop.sh:1256-1262`, `scripts/build-loop.sh:1795-1866`

---

## Claim 25: Exit paragraph: "for --cycle-diff ok" (0), "a --cycle-diff refuse line" (2), "a failed mktemp (... --cycle-diff ...; no line printed)" (1)

**Location:** `scripts/build-loop.sh:452-462`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers exit 0, 2 and usage 1 (executed by test 24) and mktemp 1 (static: `GATE_TMP="$(mktemp -d)"` under `set -e`); does not establish exits from a write failure inside cycle_diff (it runs in a `||` list, where set -e is off).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "does not establish the status a failing helper command would return outside these paths" · r3: same set -e-off residue as the winner

`cycle_diff || exit 2; echo ok` (:1883-1884); usage → exit 1 (test 24's three usage cases, r1:E2).

**Evidence:** `scripts/build-loop.sh:452-462`, `scripts/build-loop.sh:1258`, `scripts/build-loop.sh:1882-1885`, `S1/logs/blo.log`

---

## Claim 26: "raw_records FILE: ... Returns 1 when a record does not parse or lacks its path (a half record; bytes after the last NUL are not read ...). Fork-free: --main-log runs it per commit"

**Location:** `scripts/build-loop.sh:965-971`
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers return codes, field order and the absence of a subshell or external command; does not establish the timing figure in ec9dace7 (Claim 57).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none beyond the winner's (all three exclude the timing figure)

```bash
# scripts/build-loop.sh:972-980
raw_records() {
  local meta p
  RAW_OM=(); RAW_NM=(); RAW_OO=(); RAW_NO=(); RAW_S=(); RAW_P=()
  while IFS= read -r -d '' meta; do
    IFS= read -r -d '' p || return 1
    [[ "$meta" =~ ^:([01234567]{6})\ ([01234567]{6})\ ([0123456789abcdef]+)\ ([0123456789abcdef]+)\ ([AMDT])$ ]] || return 1
    ...
  done < "$1"
}
```
A trailing fragment without NUL makes `read` fail and ends the loop unread. Only builtins and a redirect: no fork.

**Evidence:** `scripts/build-loop.sh:965-980`

---

## Claim 27: QKEYS_AWK comment: "per key line of an entry, as --check-answer delimits one ... Then "odd" or "unbalanced" when FENCE_AWK refuses the file."

**Location:** `scripts/build-loop.sh:1736-1741`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Same residue as Claim 17: "as --check-answer delimits one" does not cover ANSWER_AWK's quoted-heading whole-file skip; the odd/unbalanced END line is verified (test 22's `unbalanced 12`).
**Replicate verdicts:** r1=Mostly accurate · r2=Verified · r3=Verified
**Replicate annotations:** r2: Verified, but "It does not cover ANSWER_AWK's `quoted` and `dup` whole-file results, which QKEYS does not emit (Escalations)"; the caller treats any non-`Q-` line as a refusal (`:1855`) · r3: Verified; "the 'as --check-answer delimits one' residue is Claim 14's" (merged Claim 17)

`END { if (odd) print "odd " odd " " oddwhy; else if (infence) print "unbalanced " fline }` (:1751). The delimitation phrase carries the quoted-heading residue described under Claim 17.

**Evidence:** `scripts/build-loop.sh:1737-1751`, `S1/logs/probe3.log`, `S1/logs/blo.log`

---

## Claim 28: "An entry's key lines are compared in file order ... and without F, so an archive move is no change."

**Location:** `scripts/build-loop.sh:1752-1757`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a whole entry moving between files and in-entry order; does not establish order independence for an ID split across both files (the concatenation is questions.md then archive, so such a split can differ; --check-answer skips an ID found in both files anyway).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "It does not establish the claim in d77dae74 that the swap test was red on the old sorting code (not re-run)"; also lists d77dae74 as a location · r3: order-independence across entries holds because each ID is compared separately (P2); mutant MC (sorted sides) fails at the swap line

`o[id] = o[id] "\n" k l` / `nw[id] = nw[id] "\n" k l` (:1767-1768), with `$2` (F) kept only for the message. Test 22's swap refuses and its Q-003 archive move passes (r1:E2).

**Evidence:** `scripts/build-loop.sh:1752-1772`, `scripts/build-loop.sh:1840-1858`, `S1/logs/blo.log`

---

## Claim 29: ROADMAP_AWK comment: "The lines above the first '## ' heading and the heading lines stay; a brief file a line outside '## Done' names on the base is named on some line of the index."

**Location:** `scripts/build-loop.sh:1773-1777`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three checks; "some line of the index" includes Done lines and excludes the preamble (preamble lines go to `p[s]` and are not scanned), which the frozen preamble makes moot.
**Replicate verdicts:** r1=— · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r2: its Claim 22 covers the ROADMAP_AWK and cyc_blob comments together

```awk
# scripts/build-loop.sh:1782-1789 (ROADMAP_AWK; continues to :1794 — read)
!in2[s] { p[s] = p[s] "\n" $0; next }
{
  r = $0
  while (match(r, /docs\/working\/briefs\/(closed\/)?[A-Za-z0-9._-]+\.md/)) {
    b = substr(r, RSTART, RLENGTH); sub(/.*\//, "", b); r = substr(r, RSTART + RLENGTH)
    if (s == 2) named[b] = 1; else if (!done[1]) need[b] = 1
  }
}
```

**Evidence:** `scripts/build-loop.sh:1773-1794`, `S3/logs/bats-orch.log`

---

## Claim 30: ROADMAP_AWK comment: "A heading is Done as dev-cycle.sh reads its sections ("## Done", any case, alone or before a blank or "(")."

**Location:** `scripts/build-loop.sh:1773-1777`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** As Claim 22: "a blank" is a space only.
**Replicate verdicts:** r1=Mostly accurate · r2=Verified (compound) · r3=—
**Replicate annotations:** r2: its Claim 7 notes the "blank" means a space in both predicates

See Claim 22 (r1:E3 P3b): `index(d, "## done ") == 1` (:1781) matches a space, not a tab.

**Evidence:** `scripts/build-loop.sh:1781`, `S1/logs/probe.log`

---

## Claim 31: "cyc_blob MODE ID OUT: ... an absent side (MODE 000000) is an empty file. Returns non-zero when MODE is neither 000000 nor 100644 (a symlink, an executable), or the read fails."

**Location:** `scripts/build-loop.sh:1795-1797`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three mode cases; does not establish read-failure detection beyond gate_git's status-or-stderr rule.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r2: "a read that writes to stderr yet exits 0 ... gate_git turns into status 3, so it also fails" · r3: "does not establish that a read failure is distinguishable from a mode refusal (both give the same message)"; P13 (100755) refuses

```bash
# scripts/build-loop.sh:1798-1801
cyc_blob() {
  if [[ "$1" == 000000 ]]; then : > "$3"; return 0; fi
  [[ "$1" == 100644 ]] && gate_git cat-file blob "$2" > "$3"
}
```
Test 24's symlinked idea log refuses "a side is not a regular file (mode 100644)" (r1:E2).

**Evidence:** `scripts/build-loop.sh:1795-1801`, `scripts/build-loop.sh:959-964`, `S1/logs/blo.log`

---

## Claim 32: "The checkout's own git, for its index (state_gate has run on it)."

**Location:** `scripts/build-loop.sh:1806`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that diff-index uses plain `git` after the top-level state_gate; does not establish that caller_gate ran (it does not: Claim 15).
**Replicate verdicts:** r1=— · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r2: its Claim 23 covers the inline comments at :1806, :1838 and :1846 together

`git diff-index --cached …` (`:1807`) is plain `git`, not `gate_git`; state_gate ran at `:649`.

**Evidence:** `scripts/build-loop.sh:649`, `scripts/build-loop.sh:1806-1810`

---

## Claim 33: "The chore branch lands as a merge, and --check-answer reads the merged file: lines judged free here ... can capture an answer main gained since the fork ... So the questions files must be as on main"

**Location:** `scripts/build-loop.sh:1831-1834`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers that the rule enforces "as on main" (ls-tree entries equal at base and MAIN_SHA) and that T38 needs it; the capture mechanism was executed by i2 security F1, not re-run here.
**Replicate verdicts:** r1=Verified · r2=— · r3=Verified
**Replicate annotations:** r3 (High confidence): check_answer reads `git cat-file blob "$MAIN_SHA:$f"` (`scripts/lib/dev-cycle-read.sh:2140`), i.e. the landed merge; the capture shape is "taken from the i2 security report", not freshly executed

Equal ls-tree output for both paths at base and MAIN_SHA means the merge takes the index's copy unchanged (paraphrased — no quote available because this is r1's inference from the ls-tree comparison quoted under Claim 8). Mutant (b) (block deleted) fails T38 at the main-changed line (r1:E6).

**Evidence:** `scripts/build-loop.sh:1830-1838`, `S1/m-SN14/b.log`

---

## Claim 34: "Both questions files on each side, the unchanged one included"

**Location:** `scripts/build-loop.sh:1838`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both branches of the unchanged-file read: a file absent on the base is skipped, and an ls-tree failure or a non-100644 entry refuses. It does not cover a base where `docs/working` is not a tree; ls-tree would then list nothing and the file would be skipped.
**Replicate verdicts:** r1=— · r2=Verified (compound) · r3=— · single-replicate detection
**Replicate annotations:** none

r2's P1 shows the unchanged archive is really read: `Q-000 ... gone` is refused against questions-archive.md (r2:E2). The loop is `for f in docs/working/questions.md docs/working/questions-archive.md` (`:1841`).

**Evidence:** `scripts/build-loop.sh:1838-1858`, `S2/logs/probe1.txt`

---

## Claim 35: "Unchanged in the index: the base's copy on both sides; no entry, no copy (fact-check i2 claim 15: a failed read refuses)."

**Location:** `scripts/build-loop.sh:1846`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers a failed ls-tree, an absent file and a failed or non-100644 read; does not establish a failed `cp` (unguarded, in a set -e-off context).
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r2: "does not cover a base where `docs/working` is not a tree" (see Claim 34) · r3: the `cp` "is a copy, not a read"

```bash
# scripts/build-loop.sh:1847-1850
      gate_git ls-tree -z "$base" -- "$f" > "$t.lt" || { echo "refuse $f: it could not be listed on the base"; return 1; }
      [[ -s "$t.lt" ]] || continue
      IFS=$' \t' read -r -d '' md _ id _ < "$t.lt" && cyc_blob "$md" "$id" "$t.o" || { echo "refuse $f: not a regular file (mode 100644) on the base, or could not be read"; return 1; }
      cp "$t.o" "$t.n"
```

**Evidence:** `scripts/build-loop.sh:1840-1858`

---

## Claim 36: "HEALTH_CHECK_LOCK_HELD When 1, takes no lock ... so a run it starts never waits on it. Not only a test seam: any caller setting it skips the lock."

**Location:** `scripts/health-check.sh:27-31`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the value 1 only (`!= 1`); other values take the lock.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "It does not establish that every nested path keeps the variable: run-tests.sh unsets only PARALLEL and PARALLEL_CSH (`scripts/run-tests.sh:414`)"; health-check-lock.bats unsets it only in its own throwaway repos · r3: "does not establish that every nested launcher preserves the environment (bats and run-tests.sh do in practice)"; mutant MF hangs T43

`[[ "${HEALTH_CHECK_LOCK_HELD:-}" != 1 ]] || return 0` (:1106). T43 test 2's nested run with the lock held elsewhere does not wait (r1:E1); without the line, T43 deadlocks (r1:E7).

**Evidence:** `scripts/health-check.sh:1104-1119`, `S1/logs/hcl.log`, `S1/logs/mutants2.log`

---

## Claim 37: "flock(1) holds it and re-runs this script as its child with the descriptor closed (-o), so nothing a suite leaves running keeps it ... The child, and a run inside it (check 5 runs health-check.bats), get HEALTH_CHECK_LOCK_HELD=1 and take no lock."

**Location:** `scripts/health-check.sh:1096-1103`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the hold, the leftover-process case, exit passthrough and the nested run; does not establish behaviour when `$REPO_ROOT/scripts/health-check.sh` is not the script that ran (the re-run uses that path, not `$0`; REPO_ROOT is the script's own parent, :51).
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r2: its Claim 25 covers the whole take_lock comment; "The no-repository branch (`|| return 0`, `:1107`) was read but not executed" · r3: its Claim 30a covers the mechanism plus the plain-file and no-repo sentences; "does not establish the FIFO-swap race (override row) or behaviour when flock is absent"; `main "$@"` passes arguments through (`:1153`)

T43 test 2's leftover `sleep 5` does not hold the lock (r1:E1). It does hold it on f34fceb0's `exec 8>>` version (r1:E6 a, red at line 38). r1:E4: a failing runner exits 1 through flock, both with no holder and after waiting. Check 5 runs `--slow` (:402), and health-check.bats runs `bash "$SCRIPT"` (`test/scripts/health-check.bats:29`) with the exported variable inherited.

**Evidence:** `scripts/health-check.sh:51`, `scripts/health-check.sh:386-402`, `scripts/health-check.sh:1104-1119`, `test/scripts/health-check.bats:13-30`, `S1/logs/hcl.log`, `S1/m-SN14/a.log`, `S1/logs/probe2.log`

---

## Claim 38: "-E 75 marks "held elsewhere" (this script exits 0 or 1)."

**Location:** `scripts/health-check.sh:1099-1100`
**Type:** Behavioral / Invariant
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the script's explicit exits (`exit "$FAIL"`, FAIL 0 or 1; `exit 1`); does not hold for an unplanned failure under `set -euo pipefail` (:49), which exits with the failing command's status, so a child exiting 75 would be read as "held elsewhere" and re-run.
**Replicate verdicts:** r1=Mostly accurate · r2=Verified (compound) · r3=Mostly accurate
**Replicate annotations:** r2: Verified, but its Scope says "It does not establish that `set -e` can never end the child with another status" · r3: precise version "this script's own exits are 0 or 1"; a child exiting 75 would be "rerun once"

`fail() { ...; FAIL=1; }` (:70), `exit "$FAIL"` (:1148), `exit 1` (:1110); `set -euo pipefail` (:49). Precise version: "this script's own exits are 0 or 1".

**Evidence:** `scripts/health-check.sh:49`, `scripts/health-check.sh:60`, `scripts/health-check.sh:70`, `scripts/health-check.sh:1110`, `scripts/health-check.sh:1113-1118`, `scripts/health-check.sh:1148`

---

## Claim 39: "Only a plain file is locked (a FIFO would block); outside a git repository there is nothing to share."

**Location:** `scripts/health-check.sh:1102-1103`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a FIFO, a symlink (static) and a non-repo; does not cover a swap after the test (Claim 6).
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r2: no-repo branch read, not executed (r1 executed it)

T43's FIFO case exits 1 with "not a plain file" (r1:E1); `flock -n` on a FIFO blocks (r1:E7); r1:E4 case 2: outside a repo the script ran its checks with no lock file.

**Evidence:** `scripts/health-check.sh:1107-1111`, `S1/logs/hcl.log`, `S1/logs/probe2.log`, `S1/logs/mutants2.log`

---

## Claim 40: "build-loop.sh's ANSWERS_AWK ..., QKEYS_AWK and QDIFF_AWK (--cycle-diff: also this heading rule and entry end) copy these labels and the header line's Status field ... build-loop-orchestrator.bats checks the label regex"

**Location:** `scripts/lib/dev-cycle-read.sh:2055-2059`
**Type:** Architectural / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the label regex in three readers and the Status rule in QDIFF_AWK (a superset: any field of any Needs line); does not establish that the `Q-NNN:` label or the Status rule is pinned by a test (only the bold-label regex is).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: read as a set (QKEYS copies labels, heading rule and entry end; QDIFF's `answered()` copies the Status field, `:1762`) · r3: "does not establish exact Status-rule parity (QDIFF_AWK's `answered()` accepts any `**Status:** ANSWERED` field on any Needs line, stricter than the lib's last-field-of-first-line rule, and applies only to new entries)"

`grep -nF '/^\*\*answer(:|ed| \()/'` finds lib :2097, build-loop.sh :1657 (ANSWERS_AWK) and :1750 (QKEYS_AWK). Test 23 passes (r1:E2).

**Evidence:** `scripts/lib/dev-cycle-read.sh:2097`, `scripts/build-loop.sh:1657`, `scripts/build-loop.sh:1750`, `scripts/build-loop.sh:1759-1764`, `S1/logs/blo.log`

---

## Claim 41: test helper comment: "cd_is WANT [ARG...]: --cycle-diff ARG... printed exactly WANT, exit 0 for 'ok' and 2 otherwise. onmain PATH TEXT: main moves by one commit setting PATH to TEXT, the checkout untouched. qa: the questions files on main, then a chore branch."

**Location:** `test/scripts/build-loop-orchestrator.bats:391-399`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the three helpers; cd_is also requires empty stderr (not stated).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r1: its Claim 33 covers the helper comments with test 22's name and comments · r2: its Claim 27 covers helpers, test 22's name and comments together

onmain builds the commit in a temporary index (`GIT_INDEX_FILE="$x" git read-tree main`) and moves only `refs/heads/main` with update-ref (`:394-395`), leaving the checkout and its index alone.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:391-399`

---

## Claim 42: test 22's name and case comments ("refuses an entry's header or answer changed or gone without --answered, and passes body edits, an open new entry and an archive move"; the case comments other than :427's)

**Location:** `test/scripts/build-loop-orchestrator.bats:400-431`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the name and the case comments but :427's (Claim 43).
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified (compound, apportioned)
**Replicate annotations:** r3: its Claim 33 is Mostly accurate as a compound. Its prose says "The name and the other comments match their assertions"; the Mostly-accurate residue is the :427 comment only (Claim 43). r2: the sed lines at `:408-413` delete Q-001's entry, swap the archive's two answer lines, change both routes, delete the Q-003 answer and `git rm` the archive, in the order the comment gives

Each comment's case is asserted by a `cd_is` line (r1 read them in full); the test passes (r1:E2).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:390-431`, `S1/logs/blo.log`

---

## Claim 43: "A user's answer on main meanwhile: the merge could fence it off (i2 security F1), so main is merged first."

**Location:** `test/scripts/build-loop-orchestrator.bats:427`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the refusal the case asserts; the fixture's main change is not an answer.
**Replicate verdicts:** r1=Mostly accurate · r2=Verified (compound) · r3=Mostly accurate (compound)
**Replicate annotations:** r2: Verified, but its Scope says "It does not establish that the 'user's answer on main' case uses an answer: it writes `# Q` ... the comment describes the motive, not the fixture" · r3: precise version "main changes the questions files meanwhile (a user's answer, say)"

`onmain docs/working/questions.md "# Q"` replaces main's questions.md with one line, deleting its entries. The assertion holds for any change, so the case tests the rule. The comment's "a user's answer" describes the motive, not the fixture.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:427-429`

---

## Claim 44: "the answer label regex is the same in the lib's ANSWER_AWK, ANSWERS_AWK and QKEYS_AWK"

**Location:** `test/scripts/build-loop-orchestrator.bats:432-435`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the assertion checks. It does not establish which awk program holds each copy, or parity of the `Q-NNN:` form and the `- ` strip.
**Replicate verdicts:** r1=Verified · r2=Mostly accurate · r3=—
**Replicate annotations:** r1: Verified, but its Scope says "the assertion counts occurrences per file (1 in the lib, 2 in build-loop.sh), so it would not catch a copy moved from one build-loop.sh reader to another" · r3: quotes the test under its lib Claim 31 (merged Claim 40) without verdicting the name

```bash
# test/scripts/build-loop-orchestrator.bats:433-434
    r='/^\*\*answer(:|ed| \()/'
    [ "$(grep -cF "$r" "$REPO_ROOT/scripts/lib/dev-cycle-read.sh")" -eq 1 ] && [ "$(grep -cF "$r" "$BL")" -eq 2 ]
```
The test counts the literal per file and does not tie each count to a named program. A more precise name would be: "the answer label regex appears once in the lib and twice in build-loop.sh".

**Evidence:** `test/scripts/build-loop-orchestrator.bats:432-435`, `scripts/build-loop.sh:1657`, `scripts/build-loop.sh:1750`, `scripts/lib/dev-cycle-read.sh:2097`

---

## Claim 45: test 24's name and comments (roadmap preamble, heading, dropped brief, idea-log edit refused; "Step 6's rewrites ... pass"; "No merge base; usage.")

**Location:** `test/scripts/build-loop-orchestrator.bats:437-456`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each named case; the "X moved to Done at closed/" line is appended at the file's end, which is inside `## Done (last cycle)`.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "It does not cover the Ideas move: check 1's move to Ideas is not exercised" · r3: "the 'No merge base' case is an unborn orphan HEAD, not a committed unrelated history (that one checked in E2 P7)"

Test passes (r1:E2; paraphrased — no quote available because r1's verification is the passing run of the whole test).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:437-456`, `S1/logs/blo.log`

---

## Claim 46: health-check-lock.bats header ("copies the script and the libs it sources ... with check 5's runner stubbed, so no real suite runs") and its two test names

**Location:** `test/scripts/health-check-lock.bats:1-42`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the copied libs (health-check.sh sources exactly log-format, md-utils and skill-paths, :63-67) and both names; the "says it waits" check accepts the line in either run's output.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "It does not establish that the nested run in test 2 was actually blocked without the exemption; that rests on commit 3021d0a4's mutant note, not re-run here" · r3: "test 1's 'says it waits' is timing-dependent (a 1 s stub makes overlap likely, not certain)"

Both pass (r1:E1); with no `take_lock` call both fail (r1:E7).

**Evidence:** `test/scripts/health-check-lock.bats:1-42`, `scripts/health-check.sh:63-67`, `S1/logs/hcl.log`, `S1/m2-iiWd/nolock.log`

---

## Claim 47: 6f347256 body: "interim /away reading of 'the cycle's own documented moves' for the roadmap ...; the base is the fork point rather than MAIN_SHA because step 7 merges move main mid-iteration"

**Location:** `6f347256` (commit body)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement between the body and the plan bullet and code; does not judge the reading.
**Replicate verdicts:** r1=— · r2=Verified (via multi-location Claim 10) · r3=Verified
**Replicate annotations:** none

The body agrees with the plan bullet and with `scripts/build-loop.sh:1805`'s merge-base (paraphrased — no quote available because r3 recorded only the agreement, with evidence pointers).

**Evidence:** `docs/working/plan-build-loop-handoff.md:327-333`, `scripts/build-loop.sh:1805`

---

## Claim 48: 3021d0a4 body: the T38/T43 case list

**Location:** `3021d0a4` (commit body)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the listed cases as present in HEAD's tests; later commits added cases (swap, deleted entry, main-changed questions, regex parity).
**Replicate verdicts:** r1=Verified (compound) · r2=— · r3=Verified
**Replicate annotations:** r1: its Claim 38 covers the case list and the mutants note together; "Re-run on HEAD's tests, not 3021d0a4's"

The listed cases are present in HEAD's tests and pass (paraphrased — no quote available because r3 recorded the check by evidence pointer only).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:400-456`, `test/scripts/health-check-lock.bats:15-41`, `S3/logs/bats-orch.log`

---

## Claim 49: 3021d0a4 Notes: "mutants run: base = MAIN_SHA fails T38 at the main-moved line; no take_lock and no nested-run exemption each fail T43."

**Location:** `3021d0a4` (commit body)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three mutants on HEAD's tests; "fail" for the nested-run mutant is a hang (a deadlock), red only under a timeout.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Mostly accurate
**Replicate annotations:** r1: Verified, but its Scope says "'fail' for the exemption mutant is a deadlock (bats killed by timeout), not an assertion failure"; no-exemption timed out at 300 s · r2 (Medium): "It does not establish the two T43 mutants, which were not re-run"; mutant A fails at `build-loop-orchestrator.bats:426`

r3:E3 ran the three mutants:
- MB fails T38 test 1 at line 426 (`onmain docs/roadmap.md "# R"; cd_is ok --answered Q-001`).
- ME fails both T43 tests (lines 24, 41).
- MF never completes: bats was killed by `timeout` after 60 s with only `1..2` printed (exit 124, `S3/logs/mf.log`).

Precise version: "no nested-run exemption hangs T43 (the child waits on its own parent's lock)".

**Evidence:** `S3/logs/mutants.log`, `S3/logs/mf.log`

---

## Claim 50: f34fceb0 body (the --cycle-diff rules, raw_records' four users, the flock, the interim readings, row 722 re-keyed)

**Location:** `f34fceb0` (commit body)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Checked against HEAD; the body predates the main-changed rule and the take_lock rework, which it does not mention.
**Replicate verdicts:** r1=Verified · r2=Verified (via multi-location Claims 2, 10, 11, 12, 13) · r3=Verified
**Replicate annotations:** r3: "does not carry the Claim 14 residue, because the body states the key-line rule, which holds literally in E4 (no key line changed)"

As Claims 1, 8-14, 18 and 26 (r1:E1-E3; paraphrased — no quote available because r1 verified the body by reference to its other claims).

**Evidence:** `scripts/build-loop.sh:965-980`, `scripts/build-loop.sh:1803-1866`, `scripts/health-check.sh:1104-1119`

---

## Claim 51: 414c9295 body: "With exec 8>> every suite and any process a test left running inherited the lock's descriptor ... T43 gains the leftover-process case (red on the exec version)"

**Location:** `414c9295` (commit body)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the red-on-old claim with HEAD's T43 run against f34fceb0's health-check.sh.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r2: its Claim 33 covers d77dae74 and 414c9295 together (Medium); mutant C fails at `:38` · r3: "does not establish the -E 75 / child-75 collision beyond Claim 30b" (merged Claim 38)

r1:E6 (a): test 2 fails at line 38 (`[[ "$output" != *waiting* ]] && grep -qx "out q"`), the run printing "waiting for another health check".

**Evidence:** `S1/m-SN14/a.log`, `S1/logs/mutants.log`

---

## Claim 52: d77dae74 A1: "Sorting each side's key lines lost their order ... The sides are now compared as read ... T38 gains the swap and a deleted-entry case (the swap is red on the sorting code)"

**Location:** `d77dae74` (commit body)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the swap case red under sorting; the sorting mutant is a re-insertion of f34fceb0's `sort -o` of each side before QDIFF_AWK, not the f34fceb0 file itself.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r1: "does not cover A6" (Claim 53) · r2: "It does not establish d77dae74's claim that the swap was red on the sorting code: the pre-fix QDIFF was not re-run" (r3 re-ran it)

f34fceb0 had `LC_ALL=C sort -o "$t.qo" "$t.qo" && LC_ALL=C sort -o "$t.qn" "$t.qn"` (its line 1848). r3:E3 mutant MC fails T38 at line 409, the swap (`sed -i '/^- \*\*Answer/{h;d}; /^Q-000/G' …`).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:407-409`, `S3/logs/mutants.log`

---

## Claim 53: "A6 (QKEYS_AWK lacks ANSWER_AWK's whole-file refusals) left as is: it fails safe."

**Location:** `d77dae74` (commit body)
**Type:** Error-handling / Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the quoted-heading refusal on the base side; it holds on the index side (an index copy --check-answer skips passes --cycle-diff but unblocks nothing), and the dup case is caught by key lines.
**Replicate verdicts:** r1=Incorrect · r2=— · r3=Incorrect
**Replicate annotations:** r2: no verdict on the note. Its Escalation 1 describes the same shape as "not purely fail-safe" (static, Medium, not executed) and also names `dup` as missing · r3: "the 'dup' and 'both files' refusals do fail safe (removing a duplicate changes the key-line sequence and refuses), and 'odd'/'unbalanced' are reproduced by QKEYS_AWK"; fix: "QKEYS_AWK can print `quoted N` for a fenced `### Q-NNN ` heading, as ANSWER_AWK does"; precondition: main already holds a stray fence pair around a question heading · r1+r3: escalated (E-1)

When the base copy is one --check-answer skips as "quoted" and the index removes the fenced heading block, --cycle-diff prints `ok` and --check-answer moves from skip to `keep` for an entry not in --answered (r1:E5 P5; see Claim 17). The missing refusal can therefore unblock `--approved`/`Asked:` for an answer the reader had refused to trust. The answer line itself was already on the base, which limits the impact. The skip comes from `infence && /^### Q-[0123456789]+ / { if (!qline) qline = NR; inside = 0 }` (`scripts/lib/dev-cycle-read.sh:2082`), which QKEYS_AWK's `fence($0) { next }` (`scripts/build-loop.sh:1745`) does not reproduce.

**Evidence:** `scripts/lib/dev-cycle-read.sh:2082`, `scripts/lib/dev-cycle-read.sh:2111`, `scripts/build-loop.sh:1743-1751`, `S1/logs/probe3.log`, `S3/logs/probe2.log`

---

## Claim 54: ec9dace7 B1: "A questions change now refuses while main's questions files differ from the fork point's (an ls-tree comparison in the gate repository ...): merge main into HEAD first. T38 case; red without the rule."

**Location:** `ec9dace7` (commit body)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the rule, its use of gate_git ls-tree, and the red mutant. It does not cover the parenthetical reason given for choosing ls-tree (Claim 55).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1: its Claim 42a covers B1-B5 and B7-B10 together

See Claim 8: r2's P2 (main changed only the archive; refused, exit 2) and P3 (index untouched; `ok`), and mutant B failing at `build-loop-orchestrator.bats:428` (r2:E4).

**Evidence:** `scripts/build-loop.sh:1834-1837`, `S2/logs/probe3.txt`, `S2/logs/probe1.txt`

---

## Claim 55: ec9dace7 B1 aside: "(an ls-tree comparison in the gate repository; diff-tree's pathspec misread there)"

**Location:** `ec9dace7` (commit body)
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers diff-tree with a pathspec, run in a repository shaped like gate_repo's (GIT_DIR with no work tree, GIT_OBJECT_DIRECTORY set, cwd an empty directory, git 2.39.5), in recursive, `--quiet` and `--exit-code` forms. It does not reproduce the exact command the author tried, which is not recorded.
**Replicate verdicts:** r1=Unverifiable · r2=Incorrect · r3=Unverifiable
**Replicate annotations:** r1 (Unverifiable, Low, executed): its E4 case 3 ran `git diff-tree -r ... A B -- docs/working/questions.md` in a gate-like repository, also with GIT_LITERAL_PATHSPECS=1. It "listed the path correctly on git 2.39.5". "Needed: the exact diff-tree command that misread." · r3 (Unverifiable, Low, static): "This replicate did not run it"; verifying needs a `gate_git diff-tree <base> <main> -- docs/working/questions.md` run in a gate repository set up as gate_repo does · r2: "The code choice (ls-tree) is sound; the stated reason is not borne out"; commit-message-only, no code impact

In r2's probe2 (r2:E3), every recursive form read the pathspec correctly:
- `diff-tree --quiet B M -- docs/working/questions.md docs/working/questions-archive.md` exits 1 when the archive changed and 0 when only another path changed.
- `diff-tree -r --name-only --exit-code` prints `docs/working/questions-archive.md`.
- P12 (r2:E2) also printed `docs/working/questions.md` for a gate-repository `diff-tree -r --name-only B M -- docs/working/questions.md`.

The only output that looks like a misread is from the non-recursive form, which prints `docs`. That is diff-tree's documented behaviour without `-r`, not a pathspec misread.

**Evidence:** `S2/logs/probe2.txt`, `S2/logs/probe1.txt`, `scripts/build-loop.sh:1834-1835`

---

## Claim 56: ec9dace7 B2-B5, B7-B10 (the remaining iteration-2 fixes, e.g. "Done is matched as dev-cycle.sh matches a section", `HEALTH_CHECK_LOCK_HELD == 1`)

**Location:** `ec9dace7` (commit body)
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers B1-B5 and B7-B10 as they read at HEAD; B6's figure and the diff-tree aside are Claims 55 and 57.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (via multi-location Claim 7) · r3=Verified (compound)
**Replicate annotations:** r2: its Claim 7 covers B5 only · r3: its Claim 45 covers B5/B9/B10 and the plan-lines note; "does not re-check B7's Exit paragraph beyond Claim 20" (merged Claim 25)

B3/B4 per Claims 31 and 35; B5 per Claim 7; B8 per Claim 36 (HEALTH_CHECK_LOCK_HELD `!= 1`, `scripts/health-check.sh:1106`). Mutant (b) red (r1:E6).

**Evidence:** `S1/m-SN14/b.log`, `scripts/build-loop.sh:1795-1858`, `scripts/health-check.sh:1106`

---

## Claim 57: "B6 (performance 1): raw_records is fork-free (--main-log over 1,100 commits had grown 4.3 s)"

**Location:** `ec9dace7` (commit body)
**Type:** Performance
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers "fork-free" (Verified statically, Claim 26). The verdict is Unverifiable only for the "4.3 s over 1,100 commits" figure, which is a timing of an intermediate, unreleased version that was not re-measured.
**Replicate verdicts:** r1=Unverifiable · r2=Unverifiable (compound) · r3=Unverifiable
**Replicate annotations:** r1 (Low): "Needed: timing --main-log over a 1,100-commit history on the f34fceb0 and HEAD readers" · r2: its Claim 34 covers B6 and the 386 note together · r3: needs "a timed `--main-log` run over a history of about 1,100 commits with the i1 raw_records, which used `tr | wc` forks, against HEAD's version"

The 4.3 s figure would need the pre-B6 build and a 1,100-commit fixture to verify (paraphrased — no quote available because the claim is a past timing, not code).

**Evidence:** `scripts/build-loop.sh:965-981`

---

## Claim 58: ec9dace7: "plan lines 104/209"

**Location:** `ec9dace7` (commit body)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the plan diff's hunks land at lines 104 and 209; does not judge the bullets' content (Claims 9, 10).
**Replicate verdicts:** r1=Verified (compound) · r2=— · r3=Verified (compound)
**Replicate annotations:** r1: its Claim 42d covers this with the 386 note · r3: its Claim 45 covers this with B5/B9/B10

The plan diff's hunks land at lines 104 and 209 (`@@ -101,7 +101,7 @@`, `@@ -206,7 +206,7 @@` in `git diff main...HEAD -- docs/working/plan-build-loop-handoff.md`, per r3).

**Evidence:** `docs/working/plan-build-loop-handoff.md:104`, `docs/working/plan-build-loop-handoff.md:209`

---

## Claim 59: ec9dace7 Notes: "unit at 386 code lines after compressing two comment blocks"

**Location:** `ec9dace7` (commit body)
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Counts added plus deleted lines outside docs/ against main, per decision-log row 62.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound, apportioned) · r3=Verified
**Replicate annotations:** r2: its Claim 34 is Unverifiable as a compound, but its Scope says "The verdict is Unverifiable only for the '4.3 s over 1,100 commits' figure"; r2 counted 355 + 31 = 386 · r3: "It does not count non-comment lines alone, which come to 261"

`git diff --numstat main...ec9dace7 -- . ':!docs'` sums to 355 + 31 = 386 (r1); r2 and r3 got the same total over `-- scripts test`.

**Evidence:** `docs/decisions/log.md:85`

---

## Claims Requiring Attention

### Incorrect
- **Claim 53** (`d77dae74` body): "A6 ... it fails safe" is false for the "quoted" refusal. A base questions file that --check-answer skips as "quoted" can be made readable by the index with no key-line change, and an existing answer then reads `keep` with no --answered (executed by r1 and r3). Fixed in 4aad0f9c.
- **Claim 55** (`ec9dace7` body): "diff-tree's pathspec misread there" is not reproduced by r2. Recursive, `--quiet` and `--exit-code` forms read the pathspec correctly in a gate-shaped repository. The ls-tree choice stands; the stated reason does not. This is commit-message-only (r1 and r3: Unverifiable).

### Stale
- (none)

### Mostly Accurate
- **Claim 6** (`docs/reviews/override-log.md:750`): "flock missing exits with flock's own status": it is bash's 127.
- **Claim 12** (`docs/working/plan-build-loop-handoff.md:330`): "as --check-answer delimits it" leaves out the quoted-heading whole-file skip.
- **Claim 16** (`scripts/build-loop.sh:189-190`): "or the file": the both-files refusals always name questions.md.
- **Claim 17** (`scripts/build-loop.sh:190-193`): "delimited as --check-answer reads them" omits the quoted whole-file skip.
- **Claim 22** (`scripts/build-loop.sh:204-210`): "before a blank" means a space only (fails closed).
- **Claim 23** (`scripts/build-loop.sh:209-212`): the deletion sentence covers only the roadmap and idea log, and a new roadmap is still mode-checked.
- **Claim 27** (`scripts/build-loop.sh:1736-1741`): QKEYS_AWK's "as --check-answer delimits one": same residue as Claim 17.
- **Claim 30** (`scripts/build-loop.sh:1773-1777`): ROADMAP_AWK's "a blank" means a space only.
- **Claim 38** (`scripts/health-check.sh:1099-1100`): "this script exits 0 or 1" holds for its own exits only.
- **Claim 43** (`test/scripts/build-loop-orchestrator.bats:427`): the fixture plants "# Q", not an answer.
- **Claim 44** (`test/scripts/build-loop-orchestrator.bats:432-435`): the test counts the literal per file; it does not tie copies to named programs.
- **Claim 49** (`3021d0a4` Notes): the no-exemption mutant hangs T43 (deadlock under timeout) rather than failing it.

### Unverifiable
- **Claim 57** (`ec9dace7` body): the 4.3 s / 1,100-commit timing needs the pre-B6 build and a fixture to re-measure.

## Escalations

1. **E-1: the quoted-heading gap.** `scripts/build-loop.sh:1743-1751` (QKEYS_AWK), `scripts/lib/dev-cycle-read.sh:2082` and `:2111`, and the `d77dae74` A6 note. Raised by r1 (E-1, executed), r2 (Escalation 1, static, Medium) and r3 (Escalation 1, executed). **Addressee:** orchestrator. r1: "Severity is for the panel to judge". r2: "Route: an advisory note for the rubric, or an override row". r3: "Severity is low because of the precondition".
   - **The shape.** A base questions file holds a `### Q-NNN` heading inside a fence, so --check-answer skips the whole file. The chore index can delete that fenced line, which is a free body line to QKEYS_AWK, and --cycle-diff passes with no `--answered`. After the land, --check-answer reads `keep` for an entry it had skipped, which can unblock `--approved` or a brief's `Asked:`.
   - **Not a fabricated answer.** The answer text was already on main (r1, r2).
   - **The fix.** r3 proposes it, and r1 also offers it as an option: QKEYS_AWK emits a `quoted N` refusal line, as ANSWER_AWK does. r1's other option is to name the exception in the docs.
   - **dup.** r2 also lists `dup` as missing. r3 says dup fails safe, because key lines change.
   - Fixed in 4aad0f9c.
2. **E-2: wording-only items.** `scripts/build-loop.sh:204-210`, `scripts/build-loop.sh:1773-1777` and `scripts/build-loop.sh:209-212`. Raised by r1 (E-2). **Addressee:** orchestrator. Claims 22/30 (a tab after "## Done") and 23 (deletion scope) either fail closed or are harmless; they are listed for wording only. Wording items were addressed in 4aad0f9c.
3. **E-3: the roadmap and idea log have no main-moved guard.** `scripts/build-loop.sh:1830-1838` (the guard covers the questions files only) and `scripts/build-loop.sh:1820-1828`. Raised by r2 (Escalation 2; also referenced in r2 Claim 8's Scope). **Addressee:** orchestrator (panel to confirm).
   - **What r2 checked.** A clean three-way merge drops only lines one side dropped. Concurrent idea-log appends conflict, and U4 forbids hand-resolving them.
   - **Result.** r2 found no merge shape that drops a brief or rewrites the idea log past the rule. "No finding; listed so the panel can confirm." Static reading, Medium confidence.
4. **E-4: execution logs are outside the repo.** The skill expects them in `docs/reviews/execution-logs/`; they are in the replicate scratch dirs S1/S2/S3. Raised by r2 (Escalation 3). r1's and r3's provenance sections record the same placement, for the same reason: the brief limited each replicate to its report file. **Addressee:** orchestrator ("may copy them if the rubric needs them in the repo").
5. **Non-actionable.** r3's Escalation 2 states that the rest of its checklist held under execution: the merge-base shapes, main changing only the archive, raw_records parity and the take_lock exit and exemption paths. r1's and r2's goal-alignment notes say the same and point to E-1 as the one item to weigh. **Addressee:** orchestrator, no action.

## Verdict stability

- **Total clusters:** 59.
- **Agreed:** 46, meaning every replicate that reported the cluster gave the same verdict. Two of these are single-replicate detections, Claims 5 and 34.
- **Disagreed:** 13.
- **Agreement rate:** 46/59 = 78.0%. Over the 57 clusters reported by two or more replicates, it is 44/57 = 77.2%.

Compound and multi-location verdicts count at the row level, as SKILL.md step 1 requires. Six of the 13 disagreements come from a replicate's broader claim being Verified while another replicate verdicted the atomic row: Claims 17, 22, 23, 30, 38 and 43.

| Claim | Location | r1 | r2 | r3 | Merged |
|---|---|---|---|---|---|
| 6 | `docs/reviews/override-log.md:750` | Verified | Mostly accurate | Mostly accurate | Mostly accurate |
| 12 | `docs/working/plan-build-loop-handoff.md:330` | Mostly accurate | Verified | Mostly accurate | Mostly accurate |
| 16 | `scripts/build-loop.sh:189-190` | Verified | Mostly accurate | — | Mostly accurate |
| 17 | `scripts/build-loop.sh:190-193` | Mostly accurate | Verified (multi-location) | Mostly accurate | Mostly accurate |
| 22 | `scripts/build-loop.sh:204-210` | Mostly accurate | Verified (multi-location) | Mostly accurate | Mostly accurate |
| 23 | `scripts/build-loop.sh:209-212` | Mostly accurate | Mostly accurate | Verified (compound) | Mostly accurate |
| 27 | `scripts/build-loop.sh:1736-1741` | Mostly accurate | Verified | Verified | Mostly accurate |
| 30 | `scripts/build-loop.sh:1773-1777` | Mostly accurate | Verified (compound) | — | Mostly accurate |
| 38 | `scripts/health-check.sh:1099-1100` | Mostly accurate | Verified (compound) | Mostly accurate | Mostly accurate |
| 43 | `test/scripts/build-loop-orchestrator.bats:427` | Mostly accurate | Verified (compound) | Mostly accurate (compound) | Mostly accurate |
| 44 | `test/scripts/build-loop-orchestrator.bats:432-435` | Verified | Mostly accurate | — | Mostly accurate |
| 49 | `3021d0a4` Notes | Verified (compound) | Verified | Mostly accurate | Mostly accurate |
| 55 | `ec9dace7` B1 aside | Unverifiable | Incorrect | Unverifiable | Incorrect |

The Incorrect on Claim 53 was agreed (r1 and r3, both High; r2 did not verdict it but escalated the same shape). The Incorrect on Claim 55 is a single-replicate verdict (r2, Medium) that won over two Unverifiables under most-severe-wins.
