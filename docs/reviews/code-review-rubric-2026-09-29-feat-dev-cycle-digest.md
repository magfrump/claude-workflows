Commit: de53069

# Code Review Rubric

**Scope:** feat/dev-cycle-digest vs main (scripts/dev-cycle.sh, test/scripts/dev-cycle.bats): the lower unit of the size-gate split of feat/dev-cycle | **Reviewed:** 2026-09-29 | **Status: 🟡 HELD — review cap reached (3 iterations); gate decision: escalate to the user.** Final pass 2 found Incorrects, fixed in baa46e3 and verified by tests (each new test fails on the previous script) and the fix-drift check, but not by a fourth full pass.

Loop:
1. **Iteration 1:** pass 1 on the combined unit (89a3d3b); rubric `code-review-rubric-2026-09-29-feat-dev-cycle.md`.
2. **Iteration 2, final pass 1 on 3aee138:** k=3 fact-check, security, performance, api-consistency. Architecture-review was not run (a single script, no module structure).

Considered overrides: no prior overrides matched this diff.

---

## 🔴 Must Fix

None. Security confirmed the option-name fix complete: 7 bypass shapes, no execution or write.

## 🟡 Must Address

| # | Finding | Source | Status |
|---|---|---|---|
| A1 | "Changed since" used HEAD's commit date: a record committed on a branch before the window, merged inside it, was carried forward though no cycle judged it. Uncommitted records were also carried | fact-check r3 (Incorrect), r1, r2; api F2 | ✅ Fixed: first-parent history of the default branch, plus `git status` for uncommitted records; test |
| A2 | With an explicit `--since`, the digest said "No earlier cycle record" | fact-check r1, r2, r3 (Incorrect) | ✅ Fixed; test |
| A3 | "(last changed )" / "last changed ." for uncommitted files; the fallback never fired | fact-check r1, r3; api F2 | ✅ Fixed ("never: uncommitted") |
| A4 | SIGPIPE: `printf \| head -30` exits 141 mid-digest with ~1,000+ merges | fact-check r1 | ✅ Fixed (`sed -n '1,30p'`); untested (override log) |
| A5 | Header says "on `main`", but triggers and roadmap come from the working tree | api F1 | ✅ Fixed (the Window line states both sources) |
| A6 | Carry-forward is file-level, so the digest barely shrinks at the skill's cadence | performance final #1 (Medium) | 🟡 Deferred (override log; revisit trigger; roadmap Ideas). The unit is at the 400-line cap |

## 🟢 Consider

| # | Finding | Status |
|---|---|---|
| C1 | `--since=2026-13-45` accepted | ✅ Fixed (real date required); test |
| C2 | `DEV_CYCLE_TODAY` did not pin the 14-day default | ✅ Fixed |
| C3 | "writes nothing" / exit-code list incomplete; seed comment overclaimed | ✅ Fixed (wording) |
| C4 | Record/roadmap text could imitate digest headings | ✅ Fixed (quoted with `> `) |
| C5 | Terminal control codes in merge subjects | ✅ Fixed (stripped) |
| C6 | Future-dated cycle record would carry every trigger | ✅ Fixed (ignored); test |
| C7 | `--sample=0` said "No merges in the window" | ✅ Fixed |
| C8 | Untested: capitalised-Revisit preference; row dated exactly on SINCE | ✅ Fixed (tests extended) |
| C9 | Option-name test needs both defences removed to fail; carried list not machine-splittable; symlinked roadmap followed | 🟢 Won't-Fix (override log / informational) |

Size: the unit stays ≤400 changed code lines (396) after the fixes. Comments and section echoes were compressed; output is unchanged apart from the fixes.

---

## Final pass 2 (iteration 3, on de53069)

| # | Finding | Source | Status |
|---|---|---|---|
| F1 | Records reaching main by fast-forward, or existing only on the checked-out branch, were carried forward unjudged | api final2 F1 (High); fact-check r1, r2, r3 | ✅ Fixed (baa46e3): compare the trigger section at the recorded window start ("Main at:") with the working tree; tests |
| F2 | `git status` rewrote .git/index (lock contention in the shared checkout; "writes nothing" false) | security final2 #2; fact-check r2 (Incorrect), r1, r3 | ✅ Fixed (no git status call) |
| F3 | Control codes stripped only from merge subjects; rubric C5 had claimed fixed | security final2 #1 (Medium) | ✅ Fixed (one filter on all output); test |
| F4 | Header: failed step "exits 1" (it exits with the command's code) | fact-check r1 (Incorrect) | ✅ Fixed (wording) |
| F5 | File names as pathspec wildcards; newline in a file name forges a line | security final2 #3, #4 | ✅ Fixed (literal pathspecs; newline replaced) |
| F6 | Two spellings of "uncommitted"; Window line imprecise; "last committed" reads the current branch | api final2 F2; fact-check | ✅ Fixed (one spelling; labelled "on this branch") |
| F7 | File-level carry-forward cost (earlier deferral) | performance | ✅ Resolved by F1's design |
| F8 | TAB kept by the control filter; `--since` with no value prints bash's message; DEV_CYCLE_TODAY not in --help | fact-check, api | 🟢 Won't-Fix (tab is layout; exit code correct; test hook) |

**Gate (review-fix-loop hard cap): escalate.** The unit changed after its last full pass. It is held unmerged, with Q-100 in docs/working/questions.md on feat/dev-cycle. That entry offers two choices: a fourth full pass, or merge on the evidence above.
