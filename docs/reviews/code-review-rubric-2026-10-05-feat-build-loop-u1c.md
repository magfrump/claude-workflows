Commit: 4dc84ce4
# Code Review Rubric

**Scope:** full branch `main...feat/build-loop-u1c` at 4dc84ce4. U1a and U1b have landed on main, which is merged in at 48663245, so this diff is U1c's own work. Code: 433 changed lines in 5 files; the cap is waived to ~430 (Q-114); the docs/reviews artifacts are not under review. Iteration 3 of 3, final confirming pass (no `--loop-pass`), fact-check k=3. | **Reviewed:** 2026-10-05 | **Status: 🔴 DOES NOT PASS** — 1 red item(s) unresolved

Reports (all `Commit: 4dc84ce4`):
- `code-fact-check-report-build-loop-u1c.md`: k=3 merge (r1/r2/r3 alongside); 37 claims: 30 Verified, 2 Mostly accurate, 2 Incorrect, 3 Unverifiable; agreement 30/37.
  - Stage 2.5 appended Claims 36–43 from `code-fact-check-submitted-claims-build-loop-u1c.md`: 6 Verified, 3 Mostly accurate (40 is split into a/b).
- Core critics:
  - `security-reviewer-review-2026-10-05-final-build-loop-u1c.md`
  - `performance-reviewer-review-2026-10-05-final-build-loop-u1c.md`
  - `api-consistency-reviewer-review-2026-10-05-final-build-loop-u1c.md`
- `architecture-review-review-2026-10-05-final-build-loop-u1c.md`: auto-selected, because U2–U4 parse the public mode and output contracts.
- `test-strategy-review-2026-10-05-final-build-loop-u1c.md`: included because rows 246/291/295 defer test gaps, and the fix changed the F31 read path.

Probes and logs are in `/home/node/.claude/jobs/989f3e5a/tmp/review-u1c-i3/<agent>/`. Tests pass at HEAD: build-loop-read.bats 16/16 and dev-cycle.bats 68/68 (orchestrator run).

Deviations from the skill:
- Agents read their skill files and the shared block from disk instead of having them pasted in. The block is `.../review-u1c-i3/orch/shared.md`: about 21.5k tokens, inline mode, the lib trimmed to lines 91–160 and 240–432, and the bats file left to self-read. `shared-stage2.md` adds the fact-check summary.
- The Fact-Check Gate found 2 high-confidence Incorrect claims, but this pass ran as a subagent with no user to ask, so it continued to Stage 2 (the panel was required in any case).
- Critic reports keep the `-final-` infix (u0 precedent).
- The pass is not clean, so there is no `Loop closed at` marker.

---

## Iteration 2 items (rubric at c143b929), status at 4dc84ce4

| # | Status | How checked |
|---|---|---|
| A12 | ✅ Resolved for task boxes. `- [x] H2:`, `- [X]`, `* [x]`, `1. [x]`, `[x]H2:` and `- [ ]` all now print `constraints unreadable`. Residue covered by **row 290** (letter-prefix family under Q-112 [1]): `- [x ] H2:`, `- [ x] H2:`, `- [y] H2:`, `- [xx] H2:`, `- (x) H2:` and `x H2:` still give `ok` (r1, r2 and security place them there; r3 leaves the call to the orchestrator). Side effect: `- [x] S3 bucket moved` and `- [x] h2o` now make the file unreadable (fail-closed, C31). | FC Claim 4 (3/3, executed), Claim 27; security; api |
| A13 | ✅ Resolved. Help `:32-38` now says "#" heading, fences are skipped, and detection is best effort; each clause matched a probe. Residue covered by row 290. | FC Claims 3, 4, 14; api-consistency (A13 fixed) |
| A14 | ✅ Resolved for `status_line`: BRIEF holds the queried brief on every path, for any argument order. Residue: the fix is call order only (C29). | FC Claim 22 (3/3, executed), submitted 37 (executed); architecture F3 |
| A15 | ✅ Resolved. With 3 open briefs and 0/50/200/500/2000 closed, `--status` takes 0.06–0.18 s (c143b929: 0.07 / 0.34–0.44 / 2.1–2.4 / 8.7–10.7 s). Rows 266/267/269 hold again. | FC Claim 28 (3/3, executed); performance (measured); submitted 36 |
| X1 | ✅ Resolved in cost and ordering, **but the fix introduced R1** (the git grep is not colour-safe and swallows errors) **and A21** (a second read path outside the lib). | FC 20b, 12b; architecture F1 |
| A16 | ◐ Half resolved. The second-line rule is fixed ("a second line, if any, empty"; a whitespace-only second line skips: FC Claim 8). The 0-ahead half is **still open as A22**. | FC Claim 11 (Mostly accurate, 3/3); api-consistency F1 |
| A17 | ✅ Resolved ("for an open brief" matches `:333`; a done brief sharing the branch reads `ok`). | FC Claim 12a; submitted 39 (executed) |
| A18 | ◐ Half resolved. "the planned gate" is fixed. The `:202` SC2034 comment still says "POLICY and NEVER", though POLICY is read at `:332`; **still open as A23**. | FC Claim 33 (r1, executed shellcheck; r2 notes the same) |
| A19 | ✅ Resolved ("the planned --marker", matches plan :206). | FC Claim 26 |
| C16 | ✅ Fixed. The new T44 case catches deletion of the END nosuccess check (bats fails at :184). | FC Claim 25 (3/3, mutation) |
| C17, C18 | Row 291 (Defer to U1d). | test-strategy (row 291 noted) |
| C19 | **Still open, no override row** (G5–G7: 1-char stopped reason, `Dispatched: 99`/`0`, fenced `H2:` pinned as ok). Re-listed as C33. | test-strategy |
| C20 | Row 292 (Defer to U2): **premise changed**. git grep recurses, so `${f/closed\//}` no longer agrees with check_brief's rule; re-surfaced as C30. | architecture F2 |
| C21 | Row 293 (Won't-Fix): inherited. | security F2 note |
| C22, C24, C25 | Row 294 (Won't-Fix): inherited. | — |
| C23 | ✅ Fixed ("soft constraint(s)", dev-cycle.sh's `(s)` form). | FC; submitted 38 |
| C26 | Row 295 (Defer to U1d): inherited. | test-strategy |
| C27 | Row 296 (Won't-Fix): inherited. | — |

---

## 🔴 Must Fix

Issues that must be resolved before merge. Draft cannot pass review with any red items
unresolved.

| # | Finding | Domain | Severity | Source | Location | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|---|---|
| R1 | **F31's shared-branch skip silently turns off under a forced-colour git config or a failing git grep. This regression was introduced by 4dc84ce4.**<br><br>**Mechanism.** `list="$(git grep -l -E '^Status: open'$'\r''?$' "$MAIN_SHA" -- docs/working/briefs/ \|\| true)"` (`:306`), then `f="${f#"$MAIN_SHA":}"` and `isbrief` (`:308-309`).<br>- With `color.ui=always` or `color.grep=always` in the repo's `.git/config` or the user's global config, git grep wraps every name in ANSI escapes even when piped. The strip and `isbrief` then reject every name, and the set is empty.<br>- `\|\| true` turns a git grep failure (exit 128: `grep.patternType=bogus`, `grep.threads=-1`, `color.ui=bogus`) into the same empty set, with exit 0.<br><br>**Effect.** Two open briefs naming `feat/x` both print `ok … feat/x absent - - 0` (one can be `self-merge`) instead of the F31 skip. The help (`:68-69`) and the comment's "a superset" (`:304`) are false there. c143b929 still skipped under the same config.<br><br>**Why the tests miss it.** They set `GIT_CONFIG_GLOBAL=/dev/null`.<br><br>**Why no override row covers it.** Rows 276/280/281 trust the caller's environment, not repo or global config files; the script's own `:107-111` treats repo config as hostile. It is outside Q-112.<br><br>**Fix.**<br>- Use `git grep --no-color` (verified to beat both settings).<br>- Exit 0 means a list, 1 means no open brief, and anything else must fail closed (every open brief skips with a reason, or the run errors). Do not fall back to scanning every brief; performance F2 measured that at 10.7 s for 500 briefs.<br>- Add `git config color.ui always` to T28 (fails at HEAD, passes with the fix) and an exit-128 case.<br><br>**Convergence:** fact-check (3/3, executed) + security F1 (Medium, executed) + architecture F1 + test-strategy G1/G2 + api note + performance F2 + submitted 41/43 (only `:306` is colour-sensitive). | Correctness / Security | FC Incorrect (high, behavioral); security Medium | Fact-check Claims 20b, 12b (r1+r2+r3, executed); orchestrator probe (`orch/probe`: default → skip; `color.ui=always` → `ok`; `grep.patternType=bogus` → `ok`, exit 0) | `scripts/build-loop.sh:306` | for-author | Rows 276/280/281 (caller env trusted): not applicable to repo/global config (security) | 🔴 Unresolved |

---

## 🟡 Must Address

Issues that must be fixed or acknowledged by the author with justification for why they
stand. Each must carry a resolution or a **qualifying author note**: either (a) a
discoverable TODO, or (b) a concrete revisit trigger. A note with neither is not
qualifying.

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A20 | **Override rows 283, 284 and 287 (U1a, Defer) named "U1c's next fix commit" as their revisit trigger. 4dc84ce4 met it without the fixes.**<br>- Row 283 (🟡; four wording items A19–A22): "U1c's next fix commit fixes all four, and its next review checks them".<br>- Row 284: main_entry pathform guard "with A22".<br>- Row 287: the lib header's pipefail note.<br><br>4dc84ce4's Notes move U1a/U1b's deferred wording and test gaps to a follow-up unit U1d, and the user decision in force agrees. Rows 291 and 295 point at U1d, but no log row re-points 283/284/287. | Process / Docs | Deferral trigger met | Step 3.5 override scan | for-author | Rows 283, 284, 287: trigger met | 🟡 Noted | Qualifying (revisit trigger): 4dc84ce4 Notes "U1a and U1b's deferred wording and test gaps move to a small follow-up unit, U1d". To do: append rows re-pointing 283/284/287 to U1d. |
| A21 | **The F31 candidate set now comes from a second read path outside the lib.**<br>- `shared_branches` parses `git grep`'s `SHA:path` output in build-loop.sh (`:304-309`), beside the lib's `main_entry`/`brief_fields` readers.<br>- That brings a second "open" rule, which must stay a superset of brief_fields' rule.<br>- It also brings a dependence on git output config (R1), and `\|\| true` makes a git error look the same as "no open briefs".<br><br>Fix: move the enumeration into the lib next to `main_entry` (`--no-color --full-name`, exit-checked), so U2's floor and the gate share it. Fixing R1 in place leaves this open (architecture). | Architecture | Coupling (High) | architecture-review F1 | for-author | Row 229 (BRIEF global): not this | 🟡 Open | — |
| A22 | **The help's skip clause is still inexact for a branch level with main.** `:69-71`: "or the tip's subject … starts "handoff:" but it is not a marker" applies only on a branch at least one commit ahead (`:342-343`). A 0-ahead tip with a malformed `handoff:` subject (even `handoff: stopped: `) prints `working`, as T7 (`bats:295`) asserts. 4dc84ce4 lists A16 as fixed. Fix: add "on a branch at least one commit ahead". **Convergence:** fact-check (3/3) + api-consistency. | API contract / Docs | FC Mostly accurate; api Minor | FC Claim 11 + api-consistency F1 | for-author | — | 🟡 Open | — |
| A23 | `:202` `# shellcheck disable=SC2034  # POLICY and NEVER: see above`: POLICY is read at `:332`, and shellcheck with the directive removed reports only NEVER. Iteration 2's A18 named this half. Fix: "NEVER: see above". | Comment | FC Mostly accurate | FC Claim 33 (r1, executed; r2 notes it) | for-author | — | 🟡 Open | — |

---

## 🟢 Consider

Advisory findings from contextual critics, single-critic suggestions, and improvement
opportunities. Not required to pass review.

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C28 | Test gaps on the new F31 path. G1 (high) and G2 (medium) are R1's tests. **G3:** main with no open brief at all is untested; with `\|\| true` removed, `--status` prints nothing and exits 1, and the suite stays green. **G5 (low):** the `\r?` CRLF arm is untested. Proposed edit, checked in a scratch copy: colour line in T28 plus T8's "Not landed on main" block moved, net +4 lines. test-strategy places G1/G3/G4 in U1c, G5 in U1d. | test-strategy G1–G3, G5 (mutation runs) | high / medium / low | for-author | Rows 291, 295 (other gaps, U1d) | 🟢 Open |
| C29 | **A14 is fixed by call order only (G4).**<br>- After the guard at `:318`, BRIEF still holds another brief; nothing reads it there, and only the comment keeps it so.<br>- Moving the call after `brief_fields "$a"` passes the whole suite, because every first argument happens to be the last open brief alphabetically.<br>- U2's `--check` will be wrong on a run's first brief if it calls `shared_branches` after its own `brief_fields`.<br>- `:299` "no caller can skip it" holds only through `status_line`.<br><br>Fix (probe-verified): `local -A n=() BRIEF=()` in `shared_branches`, plus 3 lines in T28; or record the precondition for U2. | architecture F3 + test-strategy G4 | Minor / medium | for-author | Row 229: not this (a helper overwriting BRIEF with a brief its caller is not judging) | 🟢 Open |
| C30 | **Row 292's premise changed.** git grep recurses into subdirectories, which `ls-tree` did not. A file at `docs/working/briefs/2026-10-0closed/1-x.md` holding `Status: open`/`Branch: feat/a` makes the real brief `a` skip (`${f/closed\//}` maps it to a valid brief path), though check_brief calls it "not a build brief". It fails closed and needs a contrived path. Fix: one `(closed/)?` predicate in the lib. | architecture F2 | Minor | for-author | Row 292 (Defer to U2): premise changed | 🟢 Open |
| C31 | The task-box fold (`:175`) now refuses ordinary lines it read `ok` before: `- [x] S3 bucket moved`, `- [x] h2o`. This is fail-closed and consistent with the help's best-effort rule. | FC Claim 4 annotation (3/3), security | Informational | for-author | Row 290 | 🟢 Open |
| C32 | The nosuccess message (`:266`) still says "heading", while the help now says "#" heading. Optional; two T44 assertions quote it. | api-consistency F2 | Informational | for-author | — | 🟢 Open |
| C33 | Iteration 2's C19 (test-strategy G5–G7: 1-char stopped reason, `Dispatched: 99`/explicit `0`, a fenced `H2:` pinned as `ok`) is still open with no override row. Give it a Defer-to-U1d row. | test-strategy | low | for-author | — | 🟢 Open |
| C34 | Performance F1: each open candidate still costs one `brief_fields` (~15–21 ms; +500 open = 10.8 s, as at c143b929). Covered by row 266, whose ">50 briefs" trigger is now conservative. | performance F1 | Informational | for-orchestrator-synthesis | Row 266 holds | 🟢 Open |
| C35 | Submitted 40b (Mostly accurate): one `--status` skip reason changed since c143b929 ("the tree of the default branch could not be read"). It came from main's lib (`:337`) via the merge, not from 4dc84ce4; U2–U4 parsers that match skip text should take the new wording. Submitted 36 (Mostly accurate): timings are host-dependent (0.07–0.09 s here); closed briefs still marked `Status: open` cost ~10 ms each. | Stage 2.5 | Mostly accurate | for-orchestrator-synthesis | — | 🟢 Open |
| C36 | Unverifiable: Claim 5 ("Only ok lets the orchestrator dispatch", planned U3/U4); Claim 31 (aaae80c6's 79 ms, today 104–114 ms); Claim 35 (historical commits not re-run). | Fact-check | Unverifiable | for-orchestrator-synthesis | Row 275 (timing, U3/U4) | 🟢 Open |

---

## ↩️ Considered Overrides

| Override (PR ref / Date) | Prior finding | Original → Override | Reason | This run's treatment |
|---|---|---|---|---|
| `feat/build-loop-u1c` / 2026-10-05 (row 290) | Constraint IDs behind a prose word, in a fence, or a look-alike letter still give `ok` | 🟡 → Won't-Fix | Q-112 [1] best effort | **Inherited.** Bracketed non-task-box prefixes (`[x ]`, `[y]`, `[xx]`, `(x)`) are placed in this family. |
| `feat/build-loop-u1c` / 2026-10-05 (row 291) | NUL refusal and F31 open-only filter untested | 🟢 → Defer (U1d) | Size cap | Inherited. The filter can still be removed with the suite green. |
| `feat/build-loop-u1c` / 2026-10-05 (row 292) | closed/ path rule spelled three ways | 🟢 → Defer (U2) | — | **Premise changed** (git grep recurses): C30. |
| `feat/build-loop-u1c` / 2026-10-05 (rows 293, 294, 296) | C21; C22/C24/C25; C27 | 🟢 → Won't-Fix | as logged | Inherited. |
| `feat/build-loop-u1c` / 2026-10-05 (row 295), `u1b` (row 246) | U1b test gaps G7–G11 | 🟢 → Defer (U1d) | — | Inherited. |
| `feat/build-loop-u1c` / 2026-10-05 (rows 266, 267, 269) | shared_branches cost; repeated parses; one call per brief | 🟢 → Defer | Done briefs move to closed/ | Premise **holds again** (performance): cost now scales with open briefs only (C34). |
| `feat/build-loop-u1c` / 2026-10-05 (rows 265, 268, 270–275) | as logged | 🟢/🟡 → Defer / Won't-Fix | as logged | Inherited; row 275 covers C36's timing. |
| `feat/build-loop-u1a` / 2026-10-05 (row 229) | BRIEF as a global array | 🟢 → Won't-Fix | One parser | Inherited for the convention. C29 (a helper overwriting it) is outside it. |
| `feat/build-loop-u1a` / 2026-10-05 (rows 283, 284, 287) | U1a wording A19–A22; main_entry pathform guard; lib pipefail note | 🟡/🟢 → Defer (trigger: U1c's next fix commit) | U1a loop closed | **Trigger met, not fixed**: A20. Re-pointed to U1d only in 4dc84ce4's Notes. |
| `feat/build-loop-u1b` / 2026-10-05 (rows 276, 280, 281) | Caller's `git -c` / GIT_CONFIG_COUNT beats the guard; caller env trusted | 🔴/🟢 → Won't-Fix / Defer | Caller environment is trusted | **Departed from for R1**: repo and global config files are not the caller's environment, and `:107-111` treats repo config as hostile (security). |
| `feat/build-loop-u1a` / 2026-10-05 (row 252), `u1b` (row 259) | Readers follow refs/replace; replace-ref guard | 🟢 → Defer (U3b `--state`) | Planned | Inherited. Security suggests adding `color.*`/`grep.*` keys and `~/.gitconfig` to U3b's `--state` scope. |
| `feat/build-loop-u0b` + `u1b` / 2026-10-05 (rows 201, 209, 247) | `-G` walk per brief; origin/HEAD symref | 🟢 → Defer | as logged | Inherited. |

---

## ✅ Confirmed Good

| Item | Verdict | Evidence | Source | Legibility-target |
|---|---|---|---|---|
| `status_line` judges the queried brief's own Branch, Dispatched and Policy on every return path, for one or several arguments in any order | ✅ Confirmed (scoped: not the correctness of the shared set itself, which R1 breaks under forced colour) | `scripts/build-loop.sh:318`: `[[ -n "$SHARED_BRANCHES" ]] \|\| shared_branches  # first: it reads other briefs into BRIEF`. FC Claim 22 (3/3, executed), submitted 37 (executed) | Fact-check; architecture endorsement verified | for-orchestrator-synthesis |
| `--status` cost no longer grows with closed briefs: 0.06–0.18 s at 0–2000 closed (c143b929: ~10 s at 500) | ✅ Confirmed (scoped: the probe hosts; open briefs still cost ~15–21 ms each, C34) | `scripts/build-loop.sh:306` (git grep prefilter). FC Claim 28 (3/3, executed), performance measurements, submitted 36 (executed, Mostly accurate on the absolute figure) | Fact-check + performance | for-orchestrator-synthesis |
| Under each listed repo config key (grep.patternType fixed/perl, grep.fullName, grep.lineNumber, grep.column, core.quotePath, core.bigFileThreshold, submodule.recurse, grep.fallbackToNoIndex, color.grep.filename, core.attributesFile) and under textconv/binary attributes, the F31 skips still print | ✅ Confirmed (scoped: each key alone in `.git/config`, git 2.39.5; **not** `color.ui/color.grep=always` or a failing grep, which are R1) | `scripts/build-loop.sh:306`. Submitted 41, 42 (executed) | security endorsement verified | for-orchestrator-synthesis |
| Of the 20 git calls on the `--status` path, only the git grep at `:306` is colour-sensitive; marker reads print no ESC bytes under `color.ui=always` | ✅ Confirmed (enumeration: 20 invocations probed under color.ui/color.diff=always, log.decorate=full) | `scripts/build-loop.sh:276-296`, `:336-351`. Submitted 43 (executed) | security endorsement verified | for-orchestrator-synthesis |
| 4dc84ce4 changes no output format or field order; the only output changes are C23's wording and A12's reclassification | ✅ Confirmed (scoped to build-loop.sh's own strings; see C35 for a lib wording change via the merge) | `git diff c143b929 4dc84ce4 -- scripts/build-loop.sh`. Submitted 40a (executed) | api-consistency endorsement verified | for-orchestrator-synthesis |
| The new T44 case kills the END-nosuccess mutant | ✅ Confirmed | `test/scripts/build-loop-read.bats:183-184`: `constraints '- S1: a' '- H1: b'` …. FC Claim 25 (3/3, mutation run) | Fact-check | for-orchestrator-synthesis |

Cross-check: every row was checked against the merged report and r1–r3 (all `Commit: 4dc84ce4`).
- The first and third rows are narrowed because Claims 20b and 12b and submitted 37/41's scope clauses record the colour failure.
- The cost row is narrowed by submitted 36's Mostly-accurate verdict on the absolute figure.

---

## ⚠️ Unverified Findings

All findings' evidence resolved.

---

## ⏭️ Skipped Core Critics

All core critics ran; no skips applied.

---

## 🧩 Composition check

| Cluster | File / lines | Fragments | Disposition |
|---|---|---|---|
| 1 | `scripts/build-loop.sh:297-318` | FC 20b/12b/22/28, security F1, architecture F1/F2/F3, performance F1/F2, test-strategy G1–G5, api note, submitted 36/37/41/43 | Distinct defects. R1 states its own mechanism and fix (colour/exit). A21 is where the read lives, and fixing R1 in place leaves it. C29 (call order) and C30 (recursive path) are separate mechanisms. |
| 2 | `scripts/build-loop.sh:55-71`, `:342-343` | FC 11, api F1 | One finding (A22), convergent; nothing to compose. |
| 3 | `scripts/build-loop.sh:172-175` | FC 4, security (task-box), api | Distinct: residue inherited by row 290; fail-closed side effect C31. |

---

To pass review: all 🔴 items must be resolved. All 🟡 items must be either fixed or
carry a qualifying author note (a discoverable TODO or a concrete revisit trigger; see
"Qualifying author note" in `skills/code-review/references/rubric.md`). 🟢 items are optional.
