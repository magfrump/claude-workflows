Commit: 722884c7
Loop-pass short-circuit: used at c8435580
# Code Review Rubric

**Scope:** `main...feat/build-loop-u1a` (full branch: d6426e3e, c8435580, 2da477b7, 78703f22, 722884c7; 4 code files, 304+/56- outside `docs/reviews/`), iteration 3, final confirming full-panel pass (no `--loop-pass`, k=3) | **Reviewed:** 2026-10-05 | **Status: 🔴 DOES NOT PASS** — 1 red item(s) unresolved

Reports: `code-fact-check-report-build-loop-u1a.md` (merged k=3 from `-r1/-r2/-r3.md`, 55 claims; Stage 2.5's `code-fact-check-submitted-claims-build-loop-u1a.md` appended as claims 56-63), `security-reviewer-review-2026-10-05-build-loop-u1a.md`, `performance-reviewer-review-2026-10-05-build-loop-u1a.md`, `api-consistency-reviewer-review-2026-10-05-build-loop-u1a.md`, `architecture-review-review-2026-10-05-build-loop-u1a.md`, all `Commit: 722884c7`. bats `test/scripts/dev-cycle.bats` 67/67 at 722884c7 with TMPDIR unset. Under a TMPDIR with a `.`-led component (`/home/node/.claude/...`), test 21 fails because git refuses the ref name. That test is outside the diff. Delivery mode: inline-diff-only via a shared file (diff 35 KB, within budget; enclosing files ~169 KB, over). Deviations, as in iterations 1-2: agents read their skill files and the shared block from disk instead of having them pasted, and a sub-agent did the mechanical k=3 merge under the skill's merge rules. Fact-Check Gate: a high-confidence Incorrect existed (claim 6). This is the requested full-panel terminal pass, so it continued. The format gate `test/skills/code-fact-check-format.bats` passes 25/25 on the merged report.

---

## 🔴 Must Fix

| # | Finding | Domain | Severity | Source | Location | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|---|---|
| R1 | (iteration 1) brief_fields captured awk's output through `$(...)`, which drops NUL bytes | Correctness / input handling | Incorrect (high), behavioral, executed | Fact-check | `scripts/lib/dev-cycle-read.sh` FENCE_AWK | for-author | — | ✅ Resolved at 2da477b7 (re-confirmed: FC claims on FENCE_AWK Verified, A6 probes refuse NUL inside a fence too) |
| R2 | (iteration 2) A failed `git cat-file` was swallowed by both main readers: check_answer fell through to the archive (`keep Q-1`), brief_fields returned 0 with no keys | Security / error handling | security Medium · architecture Coupling · api Minor (escalated, executed) | security F2 + architecture F1 + api F1 | `scripts/lib/dev-cycle-read.sh:559-560`, `:295-302` | for-author | Rows 215, 216 | ✅ Resolved at 78703f22. Executed by all three FC replicates, security, architecture, api, and Stage 2.5 claim 57. Deleting questions.md's or the archive's blob gives `skip Q-1: docs/working/questions.md could not be read from the default branch`, with no fall-through. Deleting a brief's blob gives `rc=1 BRIEF_ODD=error`, and check_brief prints `skip …: the brief could not be read from the default branch`. Test 67 fails against 2da477b7 on all three assertions, and mutants with either read check removed fail it. Under `set -euo pipefail` only; the residue outside that contract is A17. |
| R3 | **New (regression from 78703f22's C1 fix).** `--help` cuts off the header's last line. `-h\|--help) sed -n '2,80p' "$0"` was not moved when C1 added a help line, and the header now ends at :81. Help stops mid-sentence at "…no perl or lib/dev-cycle-read.sh, or no". That drops the Exit line's no-default-branch clause (which this branch extended to `--check-answer`) and "Printed repo text is data." main (`2,77p`) and 2da477b7 printed the whole header. No bats test covers `--help`. Fix: `2,81p`, or end the range at the first non-comment line as `scripts/run-tests.sh:153` does. A test asserting the last header line appears in `--help` would stop this recurring. **Convergence:** fact-check (k=3 unanimous) + api-consistency F1 | Correctness / CLI contract | Incorrect (high), behavioral, executed · api-consistency Minor | Fact-check claim 6 (r1+r2+r3) + api-consistency-reviewer F1 | `scripts/dev-cycle.sh:111` | for-author | — | 🔴 Unresolved. Orchestrator re-ran `bash scripts/dev-cycle.sh --help \| tail -2` and confirmed the output ends at "…or no". |

---

## 🟡 Must Address

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | (iteration 1) NUL bytes dropped from BRIEF values | Security | Unrouted-Escalation | fact-check escalation | for-author | — | ✅ Resolved at 2da477b7 | — |
| A2 | (iteration 1) main_entry printed `absent` when ls-tree failed | Security / API | Unrouted-Escalation | fact-check escalation | for-author | Row 208 | ✅ Resolved at 2da477b7 | — |
| A3 | (iteration 1) main_entry's ls-tree lists each named directory's children | Performance | Unrouted-Escalation | fact-check escalation | for-author | Row 220 | ✅ Resolved (Won't-Fix, row 220) | — |
| A4 | (iteration 2) test 63's `skipped=0` assertion could not fail (`test/scripts/dev-cycle.bats:1160`) | Tests | Incorrect (high) on a test comment | Fact-check | for-author | Row 217 | ✅ Resolved at 78703f22. The call now runs with ROOT_REAL set at the top level. Main's reader gives `skipped=1` on the fixture, and SKIPPED-appending mutants of both HEAD's and 2da477b7's lib fail test 63 (r1, r2, r3 executed). | — |
| A5 | (iteration 2) Lib header named both callers' suites with one caller (`scripts/lib/dev-cycle-read.sh:10-12`) | Docs | Mostly accurate | Fact-check | for-author | Row 197 | ✅ Resolved at 78703f22 ("once that second caller lands"; build-loop.sh absent, k=3 Verified) | — |
| A6 | (iteration 2) FENCE_AWK header put NUL/CR/BOM under "outside a fence" (`:170-178`) | Docs | Mostly accurate | Fact-check | for-author | — | ✅ Resolved at 78703f22. Executed: CR and NUL inside a fence give `odd 3 cr` / `odd 3 nul`. `<`, `<!--` and link-reference lines inside a fence are read. | — |
| A7 | (iteration 2) brief_fields "line as stored" omitted the dropped CR (`:277-287`) | Docs | Mostly accurate | Fact-check | for-author | — | ✅ Resolved at 78703f22 (executed: trailing CR dropped, embedded tab kept) | — |
| A8 | (iteration 2) SKILL.md "once step 1 has archived an entry" (`skills/dev-cycle/SKILL.md:292-293`) | Docs | Mostly accurate | Fact-check | for-author | — | ✅ Resolved at 78703f22. The new wording leaves a residue, A14. | — |
| A9 | (iteration 2) Test 65 "written from the skill's template", fixture lacked Motive (`test/scripts/dev-cycle.bats:1195`) | Tests / docs | Mostly accurate | Fact-check | for-author | Row 221 | ✅ Resolved at 78703f22 (renamed "shaped like"; fixture has every template section, k=3) | — |
| A10 | (iteration 2) c8435580's Notes: a working-tree-only answer reads `open` | Docs (commit message) | Mostly accurate | Fact-check | for-author | Row 222 | ✅ Resolved (Won't-Fix, override row 222) | Row exists (`docs/reviews/override-log.md:222`). |
| A11 | (iteration 2) 2da477b7's "every reader skips" a NUL file; questions.sh's readers do not | Docs / consistency | Mostly accurate | Fact-check · architecture I5 | for-author | Row 223 | ✅ Resolved (Won't-Fix, override row 223) | Row 223 carries the revisit trigger (a decision reading questions.sh output as an answer). |
| A12 | (iteration 2) main_entry kept the LAST ls-tree line per path while `cat-file SHA:path` reads the FIRST; a duplicate-entry tree read a symlink's target as `keep Q-1` | Security | Medium | security-reviewer F1 | for-author | Row 208 (different failure) | ✅ Resolved at 78703f22. A name listed twice gives `error`. Executed by security (8 shapes: every leaf mode pairing, `working` duplicated, a `working/questions.md` entry name colliding), by FC r1-r3 (`docs` tree+blob both orders, two `working` trees), and Stage 2.5 claim 56. A mutant without dup detection fails test 67's last assertion. | — |
| A13 | (iteration 2) brief_fields left its preconditions to callers; an empty MAIN_SHA read the index's copy | Architecture | Coupling | architecture-review F1 | for-author | Row 215 | ✅ Resolved at 78703f22. These now all return 1 with `BRIEF_ODD=error` and no keys set: no main by name, empty MAIN_SHA, a pathform refusal, absent, notfile, notdir, symlink, and an unreadable blob. Executed by architecture, FC k=3 and Stage 2.5 claim 59. | — |
| A14 | **New.** SKILL.md "(it reads `open`, or no such entry)" is incomplete. If an archive move is made only in the working tree and main already has the answer, it reads main's answer (`drop Q-1` / `keep Q-1`, executed). Re-answering an already-ANSWERED entry reads the old answer. A working-tree answer to an entry that main marks ANSWERED with no answer line reads `unrecognized`. All of these fail safe, because what is read is main's state. Suggested: "(it reads what main's copy says: usually `open`, or no such entry)" (`skills/dev-cycle/SKILL.md:292-295`) | Docs | Mostly accurate (k=3 unanimous, executed) | Fact-check claim 28 | for-author | Row 222 covers c8435580's Notes, not this text | 🟡 Open | — |
| A15 | **New.** The `--check-answer` help says "an answer only in the working tree reads open, or no such entry", but the same case can read `unrecognized` (executed) (`scripts/dev-cycle.sh:56-59`) | Docs | Mostly accurate (r1; r2, r3 Verified) | Fact-check claim 2 | for-author | Row 222 (same wording, different artifact) | 🟡 Open | — |
| A16 | **New (in an edited hunk; omission predates the branch).** The `--check-answer` skip-reason list leaves out "not a question ID". The "entry with this heading in both files" skip is covered only loosely by "a duplicate heading" (`scripts/dev-cycle.sh:60-71`) | Docs | Mostly accurate (r2; r1, r3 Verified) | Fact-check claim 3 | for-author | — | 🟡 Open | — |
| A17 | **New (convergence, escalated 🟢 → 🟡).** R2's skip, and brief_fields' `\|\| { BRIEF_ODD=error; return 1; }`, fire only under `pipefail`. Under `set -eu` alone, a deleted questions.md blob still gives `keep Q-1` from the archive, and brief_fields returns 0 with no keys. This is the only precondition brief_fields does not check itself. The lib header's caller contract requires `-euo pipefail` and dev-cycle.sh sets it at `:83`, so nothing hits it today. U3's `--approved` will consume check_answer. Fix (security and architecture agree, executed on bash 5.2): put `local -; set -o pipefail` at the top of check_answer and brief_fields; the caller's options are restored on return. Corroboration is executed evidence (FC r1/r2/r3, security F1, architecture F1 `nopipefail rc0 keys=0 odd=[]`) (`scripts/lib/dev-cycle-read.sh:295-302`, `:559-560`) | Security / architecture | security Informational · architecture Minor (escalated, executed) | security-reviewer F1 + architecture-review F1 + fact-check annotations (R2 residue) | for-author | Rows 215, 216 (U3 must check main_by_name; positive-line acceptance) | 🟡 Open | Architecture says it may land with U1b. A qualifying note needs a TODO or override row naming U1b/U3 as the trigger. |
| A18 | **New.** 78703f22's R2 bullet: "check_answer fell through to the archive and answered `keep`" held only inside `out="$(check_answer …)"`. Through dev-cycle.sh, 2da477b7 exited 128 instead. Its fix sentence carries r1's compound verdict. History only (`git show 78703f22`) | Docs (commit message) | Mostly accurate (claims 44, 45) | Fact-check | for-author | Row 222 precedent (Notes line on an unmerged branch) | 🟡 Open | Fixable only by rewriting unmerged history, or by an override row like row 222. |

---

## 🟢 Consider

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | --check-answer help omitted the unreadable-tree skip | api-consistency (iteration 2) F2 | Minor | for-author | — | Fixed at 78703f22 (its edit caused R3) |
| C2 | `"\0"` in FENCE_AWK assumes an awk whose strings hold NUL | api F3 / FC 11b | Informational | for-author | Row 224 | Won't-Fix (row 224) |
| C3 | Copied main_entry case blocks per caller | architecture F2 | Minor | for-author | Row 225 | Deferred (row 225) |
| C4 | BRIEF holds whole lines in one global slot | architecture F3 | Informational | for-author | Row 226 | Won't-Fix (row 226) |
| C5 | check_answer reads main while the skill writes answers to the working tree until U4 | architecture F4 | Informational | for-orchestrator-synthesis | Row 227 | Deferred (row 227) |
| C6 | Both questions files re-read per ID | performance F1 | Informational | for-orchestrator-synthesis | Row 228 | Won't-Fix (row 228) |
| C7 | check_brief ~2 ms more per brief (iteration-2 delta) | performance F2 | Informational | for-orchestrator-synthesis | Row 229 | Won't-Fix (row 229) |
| C8 | Untested main_entry bypass candidates (gitlink, quotePath, `./x`) | security | Informational | for-author | Row 230 | Deferred (row 230). Security now tested the gitlink: `notfile` at the file, `notdir docs/working` above it. |
| C9 | ls-tree's `fatal:` reached stderr unscrubbed | Fact-check (iteration 2) | Informational | for-author | — | Partly fixed at 78703f22: ls-tree stderr is dropped, but cat-file's `fatal:` line still reaches stderr on an unreadable blob (claim 57 residue) |
| C10 | architecture-review's security glob misses `security-reviewer-review-*.md` | architecture F6 | Informational | for-orchestrator-synthesis | Row 231 | Deferred (row 231) |
| C11 | **New.** check_brief now classifies each brief twice: its own pathform + `main_entry == blob`, then brief_fields repeats both (A13's fix). That is 2 `git ls-tree` per brief instead of 1. 50 calls take 850-889 ms against 626-637 ms at 2da477b7, ~17 ms vs ~11 ms per brief on main. Not covered by row 229, which measured the iteration-2 delta. Option: an unguarded internal parser that check_brief calls directly, if U1c's `--status` needs the time (`scripts/lib/dev-cycle-read.sh:292`, `:330-338`) | performance-reviewer F1 (+ Stage 2.5 claim 62c, executed) | Informational | for-orchestrator-synthesis | Row 201 (U1c `--status` measurement), row 229 | 🟢 Open |
| C12 | **New.** brief_fields reports absent, notfile/notdir and an unreadable blob all as the single word `error`. A consumer that must tell "new on main" from a refusal, or name the reason, has to call main_entry first, as check_brief does. Contract note for U1c's `--status`/`--start` (`scripts/lib/dev-cycle-read.sh:292`, `:330-338`) | architecture-review F2 | Informational | for-author | Row 215 | 🟢 Open |
| C13 | **New.** The readers follow `refs/replace`. A replace ref on questions.md's blob makes check_answer return `keep Q-1` while main's blob says OPEN; `GIT_NO_REPLACE_OBJECTS=1` gives `open Q-1`. The plan already covers this in F25/F51/T42 (`--state` refuses `refs/replace/`), and U3's T35/T42 should include the case (`scripts/lib/dev-cycle-read.sh:263`, `:295`, `:559`) | security-reviewer F2 (executed) | Informational | for-author | — | 🟢 Open |
| C14 | **New (mechanism floor).** A `docs` tree holding an entry literally named `working/…` (slash in the name) with no `working` tree makes main_entry answer `absent` while `git cat-file SHA:path` reads it as a blob. check_answer then fails closed, but check_brief prints `ok … new` for such a brief path. The tree fails `git fsck` (`scripts/lib/dev-cycle-read.sh:258-274`) | Stage 2.5 claim 56 residue (executed) | Informational | for-author | Row 208 (different failure) | 🟢 Open |
| C15 | 78703f22 Notes ("routed R2, A12 and A13 to you: judgment") and 722884c7 Notes ("Run on a code-only commit object") cannot be checked from the repo. The committed iteration-2 rubric tags those rows `for-author` | Fact-check claims 53, 55 | Unverifiable | for-orchestrator-synthesis | — | 🟢 Open |

---

## ↩️ Considered Overrides

| Override (PR ref / Date) | Prior finding | Original → Override | Reason | This run's treatment |
|---|---|---|---|---|
| `feat/build-loop-u0c` / 2026-10-05 (row 206) | check_answer reads questions.md from the working tree (F28) | 🟢 → Defer to U1 | U1 moves it to main | Discharged (Stage 2.5 claims 58, 61 executed). |
| `feat/build-loop-u0c` / 2026-10-05 (row 216) | check_answer print-only; U1 should accept only a positive line | 🟢 → Defer to U1 | Header names the safe capture pattern | Inherited; positive-line part is U3's. A17 is the pipefail precondition of the same capture pattern. |
| `feat/build-loop-u0c` / 2026-10-05 (row 217) | check_answer appends to SKIPPED | 🟢 → Defer to U1 | U1 rewrites it | Discharged in code and test (A4 resolved; claim 61 executed). |
| `feat/build-loop-u0a` / 2026-10-05 (rows 196, 197) | Lib from build-loop.sh's side; both-suites note | 🟢 → Defer to U1 | U1's test unit | 197 discharged (A5); 196 still U1b's. |
| `feat/build-loop-u0b` / 2026-10-05 (row 201) | check_brief's `git log -G` walk per brief | 🟢 → Defer | Measure in U1c `--status` | Inherited; C11 adds the double ls-tree to that measurement. |
| `feat/build-loop-u0b` / 2026-10-05 (row 208) | main_by_name for a MAIN_SHA from another repo | 🟢 → Won't-Fix | No two-repo caller | Inherited; C14 is a different failure. |
| `feat/build-loop-u0b` / 2026-10-05 (rows 213, 215) | need_root fork; three guard channels | 🟢 → Won't-Fix / Defer | Recorded for U3 | Inherited; A17 and C12 extend row 215 without contradicting it. |
| `feat/build-loop-u1a` / 2026-10-05 (rows 220, 221) | ls-tree lists children; T34 build-loop.sh side | 🟡 → Won't-Fix; 🟢 → Defer | Measured; U3 | Inherited, not re-raised. |
| `feat/build-loop-u1a` / 2026-10-05 (rows 222, 223) | c8435580 Notes; "every reader skips" | 🟡 → Won't-Fix | Fail closed; display only | Inherited (A10, A11 closed). A14/A15 are the same outcome set in other text and are not covered. A18 is a sibling commit-message case. |
| `feat/build-loop-u1a` / 2026-10-05 (rows 224-231) | C2-C8, C10 | 🟢 → Won't-Fix / Defer | See rows | Inherited, not re-raised. Row 229 departs only for the new delta (C11). |

---

## ✅ Confirmed Good

| Item | Verdict | Evidence | Source | Legibility-target |
|---|---|---|---|---|
| Under `set -euo pipefail`, an unreadable questions.md or archive blob is a skip in check_answer (no fall-through), and an unreadable brief blob gives brief_fields rc 1 with `BRIEF_ODD=error` | ✅ Confirmed (pipefail callers only; see A17) | `scripts/lib/dev-cycle-read.sh:559-560`: `\|\| { echo "skip $a: $f could not be read from the default branch"; return; }`. FC claim 57 (executed) and k=3 R2 probes | Fact-check (submitted by security) | for-orchestrator-synthesis |
| main_entry answers `error` for every duplicate-name tree probed (leaf in each mode pairing and order, `docs` as tree+blob, `working` duplicated), and both callers skip on it | ✅ Confirmed (shapes probed; git 2.39.5; see C14) | `scripts/lib/dev-cycle-read.sh:264-269`: `[[ -z "${m[$path]+set}" ]] \|\| dup=1` … `[[ -z "$dup" ]] \|\| { echo error; return; }`. FC claim 56 (executed), security F1 probes | Fact-check (submitted by security) | for-orchestrator-synthesis |
| check_answer opens no working-tree path: its reads are `main_entry "$f"` and `git cat-file blob "$MAIN_SHA:$f"` over a two-element constant list (excludes `refs/replace`, C13) | ✅ Confirmed | `scripts/lib/dev-cycle-read.sh:559`: `r="$(git cat-file blob "$MAIN_SHA:$f" \| …`. FC claim 58 (executed), claim 61 (executed: no need_root/skipped) | Fact-check (submitted by security, architecture) | for-orchestrator-synthesis |
| brief_fields checks its own preconditions (main by name, MAIN_SHA, pathform, main_entry == blob) and sets no key on refusal | ✅ Confirmed | `scripts/lib/dev-cycle-read.sh:292`: `if ! pathform "$1" \|\| [[ "$(main_entry "$1")" != blob ]]; then BRIEF_ODD=error; return 1; fi`. FC claim 59 (executed) | Fact-check (submitted by architecture) | for-orchestrator-synthesis |
| check_brief and brief_fields agree on both T31 fixtures | ✅ Confirmed (two fixtures) | `test/scripts/dev-cycle.bats:1195`, `:1210`. FC claim 60b (executed) | Fact-check (submitted by architecture) | for-orchestrator-synthesis |

(Narrowed or dropped by the cross-check: claim 60a "check_brief reads a brief only through brief_fields" is Mostly accurate. The commit field comes from `git log -G'^Status: '`, which matches fenced lines, documented at `:354`. Claim 62a's "within 5%" is Mostly accurate: 5.2-6.7% slower with no isolated cause. Claim 62c's "2 ls-tree, 1 cat-file, 1 log" holds only for briefs answering `ok`. None of these became a ✅ row.)

---

## ⚠️ Unverified Findings

All findings' evidence resolved.

---

## ⏭️ Skipped Core Critics

All core critics ran; no skips applied. (architecture-review auto-selected and ran; no other contextual critic selected: the diff has test changes, ≤10 files and ≤500 code lines, no manifests or UI.)

---

## 🧩 Composition check

| Cluster | File / lines | Fragments | Disposition |
|---|---|---|---|
| 1 | `scripts/dev-cycle.sh:111` (+ header `:56-81`) | FC claim 6, api-consistency F1, FC claims 2, 3 | distinct defects: claim 6 and api F1 state the same root and fix (convergence on R3); A15/A16 are help wording, separate from the range. |
| 2 | `scripts/lib/dev-cycle-read.sh:292-302`, `:330-338`, `:559-560` | security F1, architecture F1/F2, performance F1, FC R2 annotations, claim 57 | distinct defects: the pipefail precondition is stated whole by security F1 and architecture F1 (convergence on A17). C11 (double classification) and C12 (single error word) are separate effects of A13's fix. |
| 3 | `skills/dev-cycle/SKILL.md:292-295` (+ `scripts/dev-cycle.sh:56-59`) | FC claims 28, 2 | distinct defects: the same outcome-set gap in two artifacts (A14, A15), each with its own fix text. |

---

To pass review: all 🔴 items must be resolved. All 🟡 items must be either fixed or
carry a qualifying author note (a discoverable TODO or a concrete revisit trigger; see
"Qualifying author note" in `skills/code-review/references/rubric.md`). 🟢 items are optional.

---

## Iteration-4 gate decision (2026-10-05): escalate

Decision: `escalate`. The unit has no natural split: the open red is a one-line regression from iteration 2's help-text fix, and the ambers are wording plus one contract hardening. Splitting interleaved commits would also force U1b and U1c to re-base. Filed as Q-111 (`you: judgment`); U1a does not land until it is answered. U1b and U1c keep running their own loops in the meantime.

## Iterations (3 completed)
1. `--loop-pass`, short-circuited at the fact-check: 1 red (NUL bytes dropped by `$(...)`). Fixed in 2da477b7.
2. Full panel at 2da477b7: 1 red (a failed `cat-file` ignored) and ambers A4–A13. Fixed in 78703f22 and 722884c7, with rows for A10, A11, C2–C8 and C10.
3. Full panel at 722884c7: 1 new red (R3) and ambers A14–A18. Every iteration-2 item is resolved by execution.

## Remaining Must Fix
- R3 `scripts/dev-cycle.sh:111`: `--help` prints `2,80p`, but the header now ends at line 81, so help stops mid-sentence. Fix: `2,81p`, or end the range at the first non-comment line, plus a test that help ends with the header's last line.

## Remaining Must Address
- A14 `skills/dev-cycle/SKILL.md:292-295` and A15 `scripts/dev-cycle.sh:56-59`: "reads `open`, or no such entry" leaves out other outcomes (main's old answer, `unrecognized`). Suggested wording: "reads what main's copy says".
- A16 `scripts/dev-cycle.sh:60-71`: the skip-reason list leaves out "not a question ID" and names "entry in both files" loosely.
- A17 `scripts/lib/dev-cycle-read.sh` check_answer and brief_fields: the read checks work only under `pipefail`. Fix: `local -; set -o pipefail` in each function.
- A18: commit 78703f22's R2 bullet overstates where the fall-through happened. History only.

## Convergence diagnosis (one sentence)
The loop converges. Each iteration's red was smaller than the last, and iteration 3's red is a regression introduced by a one-line documentation fix, not a structural problem.

## Recommended action (ship-with-issues / split-PR / pause for redesign)
Neither ship-with-issues nor a split. Authorize one more iteration: fix R3 and A14–A17 (about 10 lines plus a help test), add a row for A18, then run one full confirmation pass.
