Commit: 2e711a7b
Loop-pass short-circuit: used at 224dd52d
# Code Review Rubric

**Scope:** full unit range `feat/build-loop-u1a...feat/build-loop-u1b` at 2e711a7b. The unit's own commits are 0797ed32, 224dd52d, 30676e57, 0ae7d801, 1d79ffef and 2e711a7b; af734e0f and 3b0adc25 hold review artifacts. The merges a091d8fa, 93f09654 and d06e61a6 bring in u1a's own fixes, which are reviewed on u1a, and the three-dot diff excludes them. The code diff is 417 changed lines in 3 new files (cap waived to ~420 by Q-113), plus override-log rows and this loop's review artifacts under `docs/reviews/`. | **Reviewed:** 2026-10-05 | **Status: 🔴 DOES NOT PASS** — 1 red item(s) unresolved

**Iteration 4 of 4** (the final confirming pass, authorized by Q-112 [1]): full panel, not a loop pass, fact-check k=3. Iteration 1 (at 224dd52d) short-circuited at the fact-check, and its marker above stays for the rest of the loop. Iterations 2, 3 and 4 ran every critic. The loop is not closed, because this pass is not clean: it found one new red, R5, which the A16 fix introduced.

Reports (all `Commit: 2e711a7b`):
- `code-fact-check-report-build-loop-u1b.md`: merged k=3 (58 claims; 81% verdict agreement, 47/58), with the Stage-2.5 submitted claims (55–58) appended. The replicates are `-r1.md`, `-r2.md` and `-r3.md`; the submitted-claims pass is `code-fact-check-submitted-claims-build-loop-u1b.md`.
- `security-reviewer-review-2026-10-05-build-loop-u1b.md`, `performance-reviewer-review-2026-10-05-build-loop-u1b.md`, `api-consistency-reviewer-review-2026-10-05-build-loop-u1b.md`.
- `architecture-review-review-2026-10-05-build-loop-u1b.md`: auto-selected because the diff adds a new module.
- `test-strategy-review-2026-10-05-build-loop-u1b.md`: kept from earlier panels, since the tests were reworked for A16, A18 and A19.

Execution logs are in `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b-i4/<agent>/`, because this pass may write only review reports. The orchestrator's own executions (git 2.39.5) are in `orch/`:
- 16:39:50Z: mutants for A16, A17, A18 and A19.
- 16:51:25Z: the caller `git -c` bypass, R5.
- 16:59:06Z: the G1 and G2 mutants.

Deviations from the skill:
- Agents read their skill files and the shared context block (`.../review-u1b-i4/shared.md` and `shared-stage2.md`, about 12k tokens) from disk; the block was not pasted inline.
- The Fact-Check Gate's pause on a high-confidence Incorrect was resolved as "Continue", because the caller asked for the full panel.
- The replicate merge was collated by a dedicated sub-agent under the skill's merge rules; the orchestrator appended the Stage-2.5 section.
- tech-debt-triage was not auto-selected: the diff exceeds 500 lines only because of review artifacts.

---

## Iteration-3 items, checked against 2e711a7b (rubric at 1d79ffef)

| # | Iteration-3 finding | Status at 2e711a7b | Evidence (executed) |
|---|---|---|---|
| R4 | Markup that adds letters hides a copy of a key | ↩️ Override-log row 256 (Q-112 [1]) | Settled. The rule the row relies on holds: across 17 file shapes, no input gives `policy self-merge set` without an exact policy line and an exact, valid never line. Submitted Claim 56 (executed), security (9 hidden-never, 5 continuation and 2 hidden-policy shapes), all three FC replicates. A hidden copy beside an exact line is skipped, and the exact line governs (the row's accepted residue). |
| A16 | `core.useReplaceRefs=true` in `.git/config` overrode `GIT_NO_REPLACE_OBJECTS=1` | ✅ Resolved for repo config; residue is R5 | With repo config and a live replace ref, the output is `policy review set` (Submitted Claim 55; security). Mutant A16noguard (drop the config pair) fails test 5 (orchestrator, 16:39:50Z; test-strategy). The caller-environment route is new: R5. |
| A17 | A sole never line hidden in markup read `never none` with self-merge on | ✅ Resolved | `:179` now needs `never_ok`. Security ran 9 sole-hidden shapes, and every one gave `policy review unset`. Test `build-loop-read.bats:118` pins the `- [x]` shape. Mutants A17nonever and A17gate fail test 7 (orchestrator). |
| A18 | No test asserted that self-merge goes off with two never lines | ✅ Resolved | `:129` asserts `$no`. Mutant A18dupopen (`never_ok=1` on the duplicate arm) fails test 7 (orchestrator, test-strategy, FC). |
| A19 | The G20 worktree was created at main, so a `HEAD:$f` mutant passed test 9 | ✅ Resolved | `:180` commits in the worktree. Mutant A19head fails tests 5, 7 and 9 (orchestrator; test-strategy at `:184`). |
| A20 | Header said a second copy or a refused file "leaves the default" | ✅ Resolved | `:11-12` "gives review, 3 and malformed (WHY says which)" (FC Claim 1, Verified; api F3 fixed). |
| A21 | "The line after" meant the next unfenced line; WHY overclaimed | ⚠️ Partly resolved | The header (`:21-23`) and the WHY (`:159`) are fixed. The SETTINGS_AWK comment at `:99-100` was not changed: A26. |
| A22 | T45 comment overclaimed "a link" | ✅ Resolved | `:130` "some markup, a table, a link label" (FC). |
| A23 | 1d79ffef message claims | ↩️ Override-log row 257 | Settled. The row's own quote is A28. |
| C1, C2, C4, C5, C6, C8, C9 | Advisory rows | ↩️ Override-log rows 258, 259, 260, 261, 262, 263, 264 | Inherited; premises re-checked by FC (rows 256, 259–262 and 264 hold; row 258's timing measured at 10.3 s and 22.2 s, same order). |
| C3 | The replace guard was untested | ✅ Resolved | Test 5 (`:82-84`) plants a replace ref with `core.useReplaceRefs true`; the guard-drop mutant fails it. |
| C7 | The usage suffix goes stale when U1c adds `--status` | ⏭️ Deferred to U1c, fixed there | U1c (c143b929) prints `(usage: build-loop.sh --settings \| --status BRIEF...)` (api). |

---

## 🔴 Must Fix

Issues that must be resolved before merge. Draft cannot pass review with any red items
unresolved.

| # | Finding | Domain | Severity | Source | Location | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|---|---|
| R1–R4 | Iterations 1–3, above. | — | — | — | — | — | — | ✅ Fixed (R1–R3); ↩️ R4 row 256 |
| R5 | The A16 guard's comment says the config pair is added "after any the caller passed", but a caller's `git -c` / `GIT_CONFIG_PARAMETERS` is applied after the `GIT_CONFIG_COUNT` pairs. A caller's `core.useReplaceRefs=true` therefore re-enables replace refs, and a replace blob on main's `docs/dev-cycle.md` prints `policy self-merge set` where main reads `review` (executed by FC r1, r2 and r3, security, test-strategy G4, and the orchestrator at 16:51:25Z). Zero-padded counts also defeat the pair, provided the caller supplies matching KEY pairs: `010` is read as octal, and `08` raises an arithmetic error that skips the export, after which the script still exits 0 (FC r1 and r3, api F1, security). Only the orchestrator's own environment can trigger it, and every shape also needs a replace ref, which U3b's `--state` will refuse. Security therefore rates the exposure Low. The tier comes from the comment, not the exposure: the comment states a security rationale that U3b's gate (D6) would rely on, and the code does not deliver it, so decision 031 keeps a high-confidence Incorrect red. Fix, 1 line, either way: (a) security's mutant-verified fix, `export GIT_CONFIG_PARAMETERS="${GIT_CONFIG_PARAMETERS:+$GIT_CONFIG_PARAMETERS }'core.usereplacerefs'='false'"` in place of the COUNT pair, which held review on every probed shape and removes the octal problem; or (b) narrow the comment to "after any GIT_CONFIG_COUNT pair a caller passed; the caller's environment is trusted" and log the caller route with C18's U3b trigger. A G1-style test pins (a): a caller pair or `GIT_CONFIG_PARAMETERS` setting `core.useReplaceRefs=true` must still give `policy review set` (test-strategy G1). Convergence: fact-check (Claim 16b) + security F1 + api F1 + test-strategy G1/G4 + architecture I1; corroborated by execution. | Security / contract | Incorrect (high, executed); security Low; api Minor | Fact-check (Claim 16b: r1 Incorrect, r2 Incorrect, r3 Mostly accurate) + security-reviewer F1 + api-consistency F1 + test-strategy G1, G4 | `scripts/build-loop.sh:67-68` — `# core.useReplaceRefs in the repo's config would override the variable: add a` / `# command-line config pair after any the caller passed.`; mechanism `:69` — `cfg="${GIT_CONFIG_COUNT:-0}"; export "GIT_CONFIG_KEY_$cfg=core.useReplaceRefs" "GIT_CONFIG_VALUE_$cfg=false" GIT_CONFIG_COUNT=$((cfg + 1))` | for-author | `feat/build-loop-u1b` C18 row 247 (Defer U3b; origin/HEAD symref): same actor class, separate mechanism, and this comment's claim is new at 2e711a7b. Row 259 (dev-cycle.sh readers have no guard) does not cover build-loop.sh's own guard. | 🔴 Unresolved |

---

## 🟡 Must Address

Issues that must be fixed or acknowledged by the author with justification for why they
stand. Each must carry a resolution or a **qualifying author note**: either (a) a
discoverable TODO, or (b) a concrete revisit trigger. A note with neither is not
qualifying.

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1–A23 | Iterations 1–3, above. | — | — | — | — | — | See the iteration-3 table | — |
| A24 | Commit 2e711a7b's A16 bullet repeats R5's claim: "A GIT_CONFIG_COUNT pair, appended after any the caller passed, sets it false". The commit is unmerged, so amend it with R5's fix or record a Won't-Fix row. | Commit record | Incorrect (high), message only | Fact-check (Claim 40: r1 Incorrect, r2 Incorrect, r3 Mostly accurate (compound)) | for-author | Row 235/257 class (message claims), not this message | 🟡 Open | — |
| A25 | The header at `:16-17`, "Self-merge also needs a valid never line, so a list hidden in markup turns it off rather than being skipped", the test comment at `build-loop-read.bats:117` and the commit's Q-112 bullet hold only when the hidden list is the only never-like line. Beside an exact never line the hidden copy is skipped and the exact line governs; that behaviour is settled by row 256, so only the wording is off. Suggested wording: "a never list hidden in markup, with no exact line beside it, turns it off". | Docs | Mostly accurate; api Minor | Fact-check (Claims 4b, 33, 39) + api-consistency F3 | for-author | Row 256 settles the behaviour, not this wording | 🟡 Open | — |
| A26 | SETTINGS_AWK comment `:99-100`, "whether the line after the first is blank (NEXT 1) or not": the code measures the next line outside a fence, counts a whitespace-only line as blank, and gives 1 at end of file (`:105-107`, `:112`). This is A21's leftover; the header and WHY were fixed. | Docs | Mostly accurate | Fact-check (Claim 19; r1, r2 and r3) | for-author | — | 🟡 Open | — |
| A27 | `:57` "the header, to its first non-comment line", and the commit's --help bullet: the sed range `2,/^[^#]/` ends at the first line that starts with a character other than `#`. An empty line (such as `:39`) does not end it. Today's output equals header lines 2–38 exactly. Reword, for example "to the first line starting with a character other than #". | Docs | Mostly accurate | Fact-check (Claims 15, 43; r1) | for-author | Row 239 is about the old fixed range | 🟡 Open | — |
| A28 | Override-log row 257 shows "any link" as a quote of 1d79ffef; the message says "a link … so any of them". Fix the row's wording; it is in this diff. | Docs (override log) | Mostly accurate | Fact-check (Claim 48; r1, r3) | for-author | Row 257 itself | 🟡 Open | — |
| A29 | Override-log row 239 (C5, "--help prints a fixed line range … each edit re-derives the range") is stale: `:57` now prints the header without a fixed range, as `dev-cycle.sh:112` does. Mark the row resolved with a `~` strikethrough per the log's rules. | Docs (override log) | Stale | Fact-check (Claim 46; r3, single-replicate) + api F4 + architecture note | for-author | Row 239 itself (premise changed in the item's favour) | 🟡 Open | — |

---

## 🟢 Consider

Advisory findings from contextual critics, single-critic suggestions, and improvement
opportunities. Not required to pass review.

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1–C9 | Iteration 3, above. | — | — | — | — | See the iteration-3 table |
| C10 | No test passes a caller's `GIT_CONFIG_COUNT`. A mutant that exports the guard pair only when `GIT_CONFIG_COUNT` is unset survives 9/9 (orchestrator, 16:59:06Z; test-strategy). With a caller pair `core.useReplaceRefs=true` and a replace ref, that mutant prints `policy self-merge set` where the base prints `policy review set`. Add the case to test 5 while the replace ref is live; it pairs with R5's fix. | test-strategy G1 (executed) | medium | for-author | — | 🟢 Open |
| C11 | The "next line outside a fence" rule is untested. Mutant `fence($0) { pk = ""; next }` survives 9/9 (orchestrator, test-strategy). On `never: a/`, then a fenced block, then `b/`, the base gives `never malformed` and review, and the mutant gives `never a/ set` with self-merge. The base matches the header (`:22`) and fails closed. Markdown would not join `b/` after a fence, so the mutant is not a fail-open in rendering terms, but the documented rule is not pinned. Mutant B (the `pk` update moved above the fence check) also survives and fails closed. | test-strategy G2 (executed) | medium | for-author | — | 🟢 Open |
| C12 | The blank test at `:107` (`/^[ \t]*$/`) can be narrowed to `/^$/` without failing a test (fails closed only). One case pins it: a whitespace-only line after the never line must still give `never a/ set`. | test-strategy G3 | low | for-author | — | 🟢 Open |
| C13 | A malformed `GIT_CONFIG_COUNT` (`abc`, `-1`, or `08`/`010` with no keys) exits 1 with "Not inside a git repository": git rejects the count, and `:62`'s `2>/dev/null` hides why. It fails closed, and `dev-cycle.sh:118` gives the same message. R5's fix (a) removes the arithmetic; validating the count before `:62` would name the reason. | api-consistency F2 (fact-check E2) | Informational | for-author | — | 🟢 Open |
| C14 | The guard is now two mechanisms inline in the caller (an environment variable plus a config pair built by arithmetic on a caller value). When U3b acts on row 259, it should make one named lib function used by both scripts, and say whether the caller's git environment is trusted, as the lib does for `DEV_CYCLE_SCRUBBED`. U3b's gate refuses replace refs (plan `:78`), while U1b ignores them; the two strategies should be documented side by side. | architecture-review I1 | Informational | for-orchestrator-synthesis | Row 259 (Defer U3b): premise unchanged; this adds a design note for the same trigger | 🟢 Open |
| C15 | Plan-level, outside this unit: `~/.zshrc` is uid-owned 0644, so the orchestrator's shell starts from a file a loop's uid can write, which conflicts with D6's "never trusts a file the uid can write". Separately, `GIT_REPLACE_REF_BASE` moves replace refs outside `refs/replace/`, where T42's `for-each-ref refs/replace/` check would miss them. Route both to U3b. | security-reviewer F2 | Informational | for-author | Related to rows 247 and 259 (U3b) | 🟢 Open |
| C16 | Submitted Claim 57: "a fixed 6 git process calls" holds for a `main` default branch with the file present. It is 5 with no settings file, 7 with `master` and 8 when origin/HEAD names a branch with no local copy. The count is still independent of file size and never-list length. | Fact-check (submitted Claim 57, Mostly accurate, executed) | Informational | for-orchestrator-synthesis | — | 🟢 Open |
| C17 | Unverifiable: `:130-131` "POLICY and NEVER are for the modes that judge a brief (--status, then the gate)", because neither mode is built (Claim 22b). Override row 258's "a scrub-cut line is at most 4 KB": the cut applies only to printed output, and globform reads the full line (Claim 49). | Fact-check (Claims 22b, 49; r2) | Unverifiable (no blocking failure mode) | for-orchestrator-synthesis | Row 258 (Won't-Fix): its cost premise holds; only the stated reason is loose | 🟢 Open |

---

## ↩️ Considered Overrides

| Override (PR ref / Date) | Prior finding | Original → Override | Reason | This run's treatment |
|---|---|---|---|---|
| `feat/build-loop-u1b` / 2026-10-05 (row 256) | Markup that adds letters hides a copy of a key (R4) | 🔴 → Won't-Fix | Q-112 [1]: detection is best effort, and self-merge needs a valid exact never line. | Inherited. Its rule is verified by execution (Submitted Claim 56; security). A25 is wording only. |
| `feat/build-loop-u1b` / 2026-10-05 (row 257) | 1d79ffef message claims (A23) | 🟡 → Won't-Fix | History only. | Inherited. The row's own quote is A28. |
| `feat/build-loop-u1b` / 2026-10-05 (rows 258–264) | Iteration 3's C1, C2, C4, C5, C6, C8, C9 | 🟢 → Won't-Fix / Defer | See log | Inherited; premises hold (FC). C14 adds a design note under row 259's U3b trigger. |
| `feat/build-loop-u1b` / 2026-10-05 (row 247) | origin/HEAD symref (C18) | 🟢 → Defer U3b | U3b's --state | Inherited. R5 is the same actor class through a separate mechanism, and the comment's claim is new; not a re-raise. |
| `feat/build-loop-u1b` / 2026-10-05 (row 248) | Entity or zero-width copies (C19) | 🟢 → Won't-Fix | Cannot raise the policy | Inherited. Under Q-112 the premise holds again, because a sole hidden never line now turns self-merge off. |
| `feat/build-loop-u1b` / 2026-10-05 (row 239) | --help prints a fixed range (C5) | 🟢 → Won't-Fix | Same as dev-cycle.sh | **Premise changed**, in the item's favour: the range is gone. A29. |
| `feat/build-loop-u1b` / 2026-10-05 (rows 222–246) | Earlier message claims, test gaps (246), C1–C17 | various | See log | Inherited; not re-raised. |
| `feat/build-loop-u1a` / 2026-10-05 | lib rows, including refs/replace (U3b) | various | See log | Inherited; consistent. |
| `feat/build-loop-u0a/u0b/u0c` / 2026-10-05 | D6 lib hash-check (U3b); need_root forks | Defer / Won't-Fix | See log | Inherited. |

---

## ✅ Confirmed Good

| Item | Verdict | Evidence | Source | Legibility-target |
|---|---|---|---|---|
| `policy self-merge set` is printed only with an exact policy line and an exact, single, valid never line (single as the best-effort count sees it); a sole never line hidden in markup gives `policy review unset` | ✅ Confirmed | `scripts/build-loop.sh:179` — `if [[ "$v" == self-merge && -z "$never_ok" ]]; then`; `never_ok=1` only at `:172-173`. Submitted Claim 56 (executed; 17 shapes, scope: every POLICY_LINE assignment). Mutants A17nonever, A17gate and A18dupopen fail test 7. | security-reviewer endorsement, verified by fact-check | for-orchestrator-synthesis |
| With `core.useReplaceRefs=true` in the repo's own `.git/config`, `--settings` reads main's original blob (scope: repo config and caller COUNT pairs with a decimal count; **not** caller `GIT_CONFIG_PARAMETERS`, see R5) | ✅ Confirmed | `scripts/build-loop.sh:69` — `cfg="${GIT_CONFIG_COUNT:-0}"; export "GIT_CONFIG_KEY_$cfg=core.useReplaceRefs" ...`. Submitted Claim 55 (executed); the guard-drop mutant fails test 5. | security-reviewer endorsement, verified by fact-check | for-orchestrator-synthesis |
| The settings file is read by one awk process per run, and wall time is linear in file size (~15 ms/MB) | ✅ Confirmed | `scripts/build-loop.sh:89` — `FILE_OUT="$(git cat-file blob "$MAIN_SHA:$f" \| env LC_ALL=C awk "$FENCE_AWK$2")"`. Submitted Claim 58 (executed; awk wrapper log, medians to 17.8 MB). | performance-reviewer endorsement, verified by fact-check | for-orchestrator-synthesis |
| The tests kill the iteration-3 mutants: guard drop (test 5), `HEAD:$f` (tests 5, 7, 9), `never_ok` on the duplicate arm (test 7 `:129`), the never_ok gate (test 7) | ✅ Confirmed | `test/scripts/build-loop-read.bats:129` — `settings_is never 'never malformed: more than one line starts "Self-merge never:" (lines 2 and 3)'; settings_is policy "$no"`. Orchestrator mutants (16:39:50Z) and FC r1–r3 and test-strategy, all executed. | Fact-check + orchestrator execution | for-orchestrator-synthesis |
| `--help` prints exactly header lines 2–38, the same idiom as dev-cycle.sh | ✅ Confirmed | `scripts/build-loop.sh:57` — `-h\|--help) sed -n '2,/^[^#]/{/^#/p}' "$0" \| sed 's/^# \{0,1\}//'; exit 0 ;;`. FC Claim 15 (executed by all three; the wording is A27). | Fact-check | for-orchestrator-synthesis |

Dropped or narrowed by the cross-check:
- Submitted Claim 57 ("fixed 6 git calls") was not published as ✅, because it is Mostly accurate: C16.
- Submitted Claim 55 is narrowed to the scope its verdict covers; the caller `GIT_CONFIG_PARAMETERS` route is R5.

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
| 1 | `scripts/build-loop.sh:62-70` | FC 16b/40, security F1, api F1/F2, architecture I1, test G1/G4 | distinct defects: security F1 already states the shared root and the fix (a caller's later config wins; append a `GIT_CONFIG_PARAMETERS` pair). That root is R5. The others are its pieces: the commit claim (A24), the error message (C13), the test gap (C10), the design note (C14). |
| 2 | `scripts/build-loop.sh:15-17`, `build-loop-read.bats:117` | FC 4b/33/39, api F3 | merged into A25. |
| 3 | `scripts/build-loop.sh:99-112` | FC 19, test G2/G3 | distinct defects: comment wording (A26) vs an untested rule (C11, C12). |
| 4 | `docs/reviews/override-log.md:239` | FC 46, api F4, architecture note | merged into A29. |

---

To pass review: all 🔴 items must be resolved. All 🟡 items must be either fixed or
carry a qualifying author note (a discoverable TODO or a concrete revisit trigger; see
"Qualifying author note" in `skills/code-review/references/rubric.md`). 🟢 items are optional.

---

## Iterations (4 completed; the bound granted by Q-112)
1. `--loop-pass`, short-circuited at the fact-check: 1 red (a tab passed the single-space rule). Fixed in 30676e57, with the cap trim in 0ae7d801.
2. Full panel at 0ae7d801: 2 reds (`&&`-joined checks; markup copies hidden) and A5–A15. Fixed in 1d79ffef.
3. Full panel at 1d79ffef: R4 and A16–A23. The gate escalated (Q-112); the user chose [1].
4. Full panel at 2e711a7b (this pass): iteration 3's items are resolved, settled or partly resolved by execution. New: R5 (the guard's caller-environment gap, introduced by the A16 fix) and A24–A29 (wording and override-log rows).

## Remaining Must Fix
- R5 `scripts/build-loop.sh:67-69`: the replace-ref guard does not hold against a caller's `git -c core.useReplaceRefs=true` or a zero-padded `GIT_CONFIG_COUNT`, though its comment says it is added "after any the caller passed". This is a 1-line fix either way.

## Remaining Must Address
- A24: commit 2e711a7b's A16 bullet (same claim as R5).
- A25: "a list hidden in markup turns it off" needs "with no exact line beside it".
- A26: the SETTINGS_AWK comment's "the line after the first" (A21 leftover).
- A27: `--help` "to its first non-comment line" wording.
- A28, A29: override-log rows 257 (quote) and 239 (stale premise).
