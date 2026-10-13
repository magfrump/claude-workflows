Commit: 4aad0f9c

# Architecture Review — feat/build-loop-u3c (final confirming pass, full branch)

**Scope:** `git diff main...HEAD` (main = dafc0e74, HEAD = 4aad0f9c): `scripts/build-loop.sh` (`--cycle-diff`, QKEYS_AWK, QDIFF_AWK, ROADMAP_AWK, cyc_blob, cycle_diff, raw_records, check_line and log_class on raw_records), `scripts/lib/dev-cycle-read.sh` (the ANSWER_AWK pointer comment), `scripts/health-check.sh` (take_lock), and the two test files and plan bullet as context.
**Date:** 2026-10-12
**Based on:** `docs/reviews/code-fact-check-report-2026-10-12-u3c-final-r{1,2,3}.md` (k=3 at ec9dace7; each found 1 Incorrect, claim 42, fixed in 4aad0f9c), the Stage-1 summary in the shared brief, and the prior pass `docs/reviews/architecture-review-2026-10-12-u3c-i2.md`. Behaviour verdicts are taken as given. I re-ran one probe, described under Finding 1.

Scope check: in scope. The diff adds a public CLI mode (`--cycle-diff`) whose contract U4 consumes. It also adds a shared reader (`raw_records`) for three existing callers, a hand copy of the questions-entry grammar, and a cross-cutting lock on the health gate.

## Dependency Map

- `scripts/build-loop.sh` sources `scripts/lib/dev-cycle-read.sh` (FENCE_AWK, ANSWER_AWK/check_answer, git_harden, and the rest). Dependencies run one way, from the script to the lib. The lib names build-loop.sh only in its pointer comment (`dev-cycle-read.sh:2055-2059`).
- `raw_records` (`build-loop.sh:973`) is the one `--raw -z` parser. check_line, log_class's chore and answers loops, and cycle_diff all call it. Since ec9dace7, `cyc_blob MODE ID OUT` (`:1802`) no longer reads the `RAW_*` globals. Only cycle_diff reads them by index, and nothing in cycle_diff lists again between its single call and its last use.
- cycle_diff composes the lib's FENCE_AWK with three local programs: QKEYS_AWK (`:1746`), QDIFF_AWK (`:1762`) and ROADMAP_AWK (`:1783`). QKEYS_AWK still depends on ANSWER_AWK's *meaning* rather than calling it. It copies the label regex, the heading match, the entry end and, since 4aad0f9c, the fenced-heading whole-file skip.
- ROADMAP_AWK re-encodes SKILL.md step 6. Its Done match now follows dev-cycle.sh's section reader, and the missing back-pointer is handed to U4 by an override row (the U3c rows dated 2026-10-12).
- `scripts/health-check.sh`'s take_lock (`:1104`) depends on flock(1) and git's common dir, and on nothing in the build-loop code.
- No cycles. No dependency direction is reversed.

Trust-boundary cross-reference: the most recent security review is `docs/reviews/security-review-2026-10-12-u3c-i2.md` (Commit: `74deb04e`). That review predates this diff, so its boundaries may be stale. Finding 1 sits on its `B1` (staged index → cyc_blob → QKEYS/QDIFF awk → ok/refuse) and feeds `B4` (main's questions files → check_answer → `--approved` / `Asked:`). Neither recommendation below moves either crossing. Both make the B1 reader take more of its rules from B4's reader.

## Findings

#### 1. The answer grammar's copy now spans four shared rules, but the pointer names three and the parity test pins one; the rule that just failed open is the one neither covers

**Severity:** Coupling
**Location:** `scripts/build-loop.sh:1746-1755` (QKEYS_AWK, esp. `:1748` and `:1755`), `scripts/lib/dev-cycle-read.sh:2055-2059` (pointer) and `:2082`, `:2108-2111` (ANSWER_AWK), `test/scripts/build-loop-orchestrator.bats:436-439` (parity test)
**Move:** 7 (coupling surface), 3 (module boundary)
**Confidence:** High
**Legibility-target:** for-author

The i2 resolution of this finding was pointer comments plus a label-regex parity test, without a shared lib prelude. That resolution was in place at ec9dace7, and the copy still lacked one of ANSWER_AWK's rules: the whole-file "quoted" skip. Two of three fact-check replicates found the gap only by running it (claim 42: skip became keep, a laundering path). It was not caught by the pointer, the parity test or the i2 critics. So the mechanism the i2 pass accepted as the minimum did not hold for the first rule outside its literal coverage.

4aad0f9c fixes the behaviour correctly: either side's quoted copy refuses, and T38 holds the base-side bypass. It does so by adding a fourth hand-copied rule. Here is what keeps the four rules in step today:

| Shared rule | Copy in QKEYS_AWK | Named in the lib pointer | Pinned by a test |
|---|---|---|---|
| Answer labels | `:1754` | yes | yes (regex parity) |
| `### Q-N` heading match | `:1750` | yes ("this heading rule") | no, only behaviourally in T38 |
| Entry end `^(#\|##\|###) ` | `:1751` | yes ("entry end") | no |
| Fenced-heading whole-file skip | `:1748`, `:1755` | **no** | only behaviourally in T38's two quoted cases |

The pointer was written at ec9dace7 and 4aad0f9c did not touch it, so it still lists "labels and the header line's Status field ... also this heading rule and entry end". The drift direction is the same as before, and the evidence now shows it. If ANSWER_AWK gains a skip, or widens a rule, and QKEYS_AWK is not updated, `--cycle-diff` passes an index that `--check-answer` reads as an answer. Whole-file skips are the easiest class to miss, because they live in ANSWER_AWK's END and its pre-fence line, away from the per-entry logic a maintainer would compare.

Evidence (verbatim):

```awk
# scripts/lib/dev-cycle-read.sh:2082 (ANSWER_AWK main rules; the program continues to :2112, read)
infence && /^### Q-[0123456789]+ / { if (!qline) qline = NR; inside = 0 }
# scripts/lib/dev-cycle-read.sh:2108-2111 (ANSWER_AWK END, first three branches; dup and the verdict follow at :2112-2113, read)
END {
  if (odd) print "odd " odd " " oddwhy
  else if (infence) print "unbalanced " fline
  else if (qline) print "quoted " qline
```
```awk
# scripts/build-loop.sh:1748 and :1755 (QKEYS_AWK; whole program :1746-1755 read)
infence && /^### Q-[0123456789]+ / { if (!q) q = NR }
END { if (odd) print "odd " odd " " oddwhy; else if (infence) print "unbalanced " fline; else if (q) print "quoted " q }'
```
```bash
# scripts/lib/dev-cycle-read.sh:2055-2059 (the pointer, whole)
# build-loop.sh's ANSWERS_AWK (--main-log's answers class), QKEYS_AWK and
# QDIFF_AWK (--cycle-diff: also this heading rule and entry end) copy these
# labels and the header line's Status field: change all of them together (a
# label read here but not there lets --cycle-diff pass an answer: i2
# architecture 1; build-loop-orchestrator.bats checks the label regex).
```

The whole-file verdict does not need to be copied. ANSWER_AWK prints `odd` / `unbalanced` / `quoted` from file-wide state, whatever `id` is. I ran the lib's own `$FENCE_AWK$ANSWER_AWK` with `-v id=Q-` (no such ID can be a heading under QKEYS_AWK's regex) on three fixtures and compared it with QKEYS_AWK's non-`Q-` line:

| Fixture | ANSWER_AWK | QKEYS_AWK |
|---|---|---|
| Fenced `### Q-006` heading | `quoted 3` | `quoted 3` |
| Clean file | nothing | nothing |
| Unclosed fence | `unbalanced 2` | `unbalanced 2` |

So cycle_diff can ask the canonical reader for the whole-file verdict and drop the copy. Probe: `scratchpad/arch-u3c-final/probe.sh`.

**Recommendation (this unit, within the 6 lines left under the cap):** pick one.
- **(a) Preferred, about +1 to +3 net lines.** Delete QKEYS_AWK's `:1748` line and its END. In cycle_diff's per-copy loop, run `LC_ALL=C awk -v id=Q- "$FENCE_AWK$ANSWER_AWK"` on `$t.$p`, and refuse when its first line matches `^(odd|unbalanced|quoted) `. That reuses the existing refusal text. Every current and future whole-file skip then comes from ANSWER_AWK itself, and this copy leaves the table.
- **(b) Minimum, 2 lines.** Add "and its fenced-heading skip" to the lib pointer. Extend the parity test with `grep -cF 'infence && /^### Q-[0123456789]+ /'`, expecting 1 in the lib and 1 in build-loop.sh.

**Override row:** defer the shared predicate prelude (`QGRAMMAR_AWK`: heading id, entry end, label) with a revisit trigger at the next edit to ANSWER_AWK's heading, entry-end or label rules, or at U4's step 9 text, whichever comes first. With (a) done, the prelude covers only the three per-line rules, and that is a reasonable deferral.

#### 2. cycle_diff still addresses raw_records' globals by index across its body (residual of i2 Finding 2)

**Severity:** Informational
**Location:** `scripts/build-loop.sh:1807-1870` (cycle_diff: `qi`, `RAW_*[k]` in the questions loop)
**Move:** 7 (coupling)
**Confidence:** Medium
**Legibility-target:** for-author

ec9dace7 fixed the part that mattered. `cyc_blob` now takes `MODE ID OUT`, so its signature no longer hides a global read. The unchanged-file branch also reads through one `ls-tree -z` that refuses on failure (the old inline reader is gone, i2 Finding 3). cycle_diff itself still keeps record indices in `qi` and reads `RAW_P[i]`, `RAW_OM[k]` and the rest after other git calls. That is safe today, because no second `raw_records` call happens inside cycle_diff. It would break silently only if someone added one.

Evidence (verbatim):

```bash
# scripts/build-loop.sh (cycle_diff, questions loop; the loop continues through the awk passes, read)
    k=""; for i in "${qi[@]}"; do [[ "${RAW_P[i]}" != "$f" ]] || k="$i"; done
    if [[ -n "$k" ]]; then
      cyc_blob "${RAW_OM[k]}" "${RAW_OO[k]}" "$t.o" && cyc_blob "${RAW_NM[k]}" "${RAW_NO[k]}" "$t.n" || { echo "refuse $f: a side is not a regular file (mode 100644), or could not be read"; return 1; }
```

**Recommendation:** No change in this unit. If cycle_diff ever lists again, copy the arrays into locals first, as check_line does.

#### 3. The "main moved since the fork" guard is keyed to the questions files only; the asymmetry is justified, but no decision reader currently consumes the merged roadmap

**Severity:** Informational
**Location:** `scripts/build-loop.sh:1839-1842` (the ls-tree comparison in cycle_diff), header `:199-201`
**Move:** 2 (responsibility boundaries)
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

This answers the r2 escalation from the structural side. The guard exists because the chore branch lands as a merge, and the questions files' downstream reader (check_answer → `--approved`, `Asked:`) decides from the merged file. The roadmap and idea log have no such decision reader.
- A clean merge cannot drop a brief line unless one side dropped it, and the chore side's drop is what ROADMAP_AWK judges.
- Concurrent idea-log appends at the end of the file conflict, and U4's land takes no hand-resolved conflict (U3b2 override).

So guarding only the questions files keeps a guard exactly where a reader of merged content decides something. The header states why. If a later unit makes a gate decide from roadmap content (a brief's status read from the roadmap, say), the same merge-result question reopens for that file.

**Recommendation:** No change. Optionally, U4's step 9 text could say that the guard follows the decision readers, so a new reader of merged content gets the same check.

## Prior findings (i2), status at 4aad0f9c

| i2 # | Status | Where |
|---|---|---|
| 1 Coupling (grammar copies) | Partly resolved (pointer and label test), and widened by 4aad0f9c's fourth rule. Carried forward as Finding 1 above. | ec9dace7, 4aad0f9c |
| 2 Minor (cyc_blob reads globals) | Fixed: `cyc_blob MODE ID OUT`. The residual is Finding 2 (Informational). | ec9dace7 |
| 3 Minor (second inline BASE reader) | Fixed: one `ls-tree -z` read, and a failed read refuses. | ec9dace7 |
| 4 Minor (ROADMAP_AWK vs SKILL.md step 6, Done match) | Done match fixed to dev-cycle.sh's form. The back-pointer and preamble are deferred to U4 by override row. Adequate. | ec9dace7, override-log |
| 5 Informational (HEALTH_CHECK_LOCK_HELD) | The header now says any caller setting it skips the lock, and the test is `!= 1`. The `$REPO_ROOT` re-run spelling is unchanged and harmless. | ec9dace7 |

## What Looks Good

- **The 4aad0f9c fix is placed correctly.** It refuses at the copy level, on either side, rather than trying to model which fenced lines are free. That matches check_answer's own choice to distrust the whole file. T38 pins both directions, and the base-side case is the bypass itself.
- **Row 724 stays discharged.** raw_records is the single parser for every `--raw -z` listing. The one behaviour change (an unparsed chore record now makes the commit other) moves toward the stricter side.
- **`--cycle-diff` fits the existing mode contract.** It runs `state_start`, then prints `ok` or `refuse PATH: WHY` with exit 2, so U4 parses one more mode of a familiar shape.
- **The fork-point base and the index-only read are sound.** Duties that only U4 can discharge are recorded as override rows (commit takes the index, land from the checked MAIN_SHA, `--answered` recording) rather than left implicit.
- **The health-check lock is self-contained.** It is keyed on the common dir and held in flock's own process with `-o`, and it has no dependency on build-loop code.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Answer grammar copied as four rules. The pointer names three and the test pins one. The fenced-heading skip, the rule that just failed open, has neither. | Coupling | `scripts/build-loop.sh:1746-1755`, `scripts/lib/dev-cycle-read.sh:2055-2059` | High |
| 2 | cycle_diff reads `RAW_*` by index across its body (residual of i2 #2) | Informational | `scripts/build-loop.sh:1807-1870` | Medium |
| 3 | The main-moved guard covers questions only. This is justified by the decision readers and would reopen if a gate ever reads merged roadmap content. | Informational | `scripts/build-loop.sh:1839-1842` | Medium |

Rubric mapping: 1 → 🟡 Must Address; 2–3 → 🟢 Consider.

## Overall Assessment

The branch keeps the system's structure intact. It retires row 724's three parsers, adds a mode in the existing dispatch shape, and keeps the lock independent. ec9dace7 resolved i2's Minors 2–4 in code. The single remaining structural concern is the one the i2 pass rated Coupling, and its accepted resolution has now been tested by events: the pointer and the label-parity test were in place, and the copy still missed ANSWER_AWK's whole-file skip until the fact-check executed it. 4aad0f9c closes that hole by adding a fourth copied rule that neither the pointer nor the test covers. I recommend fixing this in this unit rather than by override row alone, because the remedy is small. Option (a) asks ANSWER_AWK itself for the whole-file verdict (verified equivalent on three fixtures, about +1–3 net lines), which removes the copy that fails open most quietly. Option (b) is 2 lines: the pointer names the skip, and the parity test greps its regex. Either fits the 6 lines left under the 400-line cap. The full shared-predicate prelude belongs in an override row with the revisit trigger named in Finding 1. Findings 2 and 3 need no change.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the exact path your tail names, structured per your skill, with a `Commit: <HEAD short sha>` first line.
- Answered: yes. The report judges the i2 Coupling resolution after 4aad0f9c's fourth rule (not adequate as it stands; a 2-line or about-3-line fix in this unit, with the prelude deferred by override row), re-checks i2 Minors 2–5 against the code, and gives a structural view on the r2 roadmap/idea-log escalation.
- Out of scope: whether each rule is correct (the fact-check executed them), how exploitable the quoted bypass was (the security reviewer's), and refusal wording.
- Escalate: Finding 1 is 🟡. If neither (a) nor (b) lands in this unit, the override row should cite claim 42 as the evidence that pointer comments alone did not hold, and name the revisit trigger.
- Decisions I made:
  - Kept Finding 1 at Coupling rather than downgrading it to Minor after the pointer and test landed, because the drift direction still fails open and one drift has already happened in practice.
  - Preferred (a) over (b) because it removes a copy rather than guarding it. The cost is one extra awk run per questions copy (four per call), which is negligible.
