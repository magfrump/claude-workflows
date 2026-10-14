Commit: c39a9692
Loop-pass short-circuit: used at 9777c1ff

# Code Review Rubric: feat/build-loop-u4b2

**Scope:** `main...HEAD` (full branch, first pass of the loop) · **Delivery mode:** self-read ·
**Fact-check:** k=1 (loop pass, decision 031) ·
`docs/reviews/code-fact-check-report-2026-10-13-u4b2-i1.md`

## Iteration 1 (9777c1ff): short-circuited at fact-check

Fact-check: 27 claims; 20 Verified, 1 Mostly accurate, 2 Stale, 4 Incorrect (all executed but 23).
Behavioural reds confirmed at Stage 1, so the critic panel was skipped this pass
(decision 032 #4; first use in this loop).

## 🔴 Must Fix

| ID | Finding | Location | Source | Status |
|---|---|---|---|---|
| A1 | A working brief with no live loop (an ended subagent, a stalled loop stopped by step 7) was re-dispatched with `--prompt` and no `--steal`, which refuses "a live loop may hold it" (neither retryable text): it became an agent entry and never re-dispatched (executed, P3) | `skills/dev-cycle/SKILL.md` step 7 working, step 10 | fact-check claim 7b | Fixed in the fix commit: every non-marker tip goes `--prompt --steal` |
| A2 | A self-merge `--merge` run from WT refuses for the checkout (WT is edited by step 7, and an earlier merge moves main), so self-merge never lands (executed, P1) | step 7 ready/self-merge | fact-check claim 8b | Fixed: one detached gate worktree GT at main's commit per call |
| A3 | On the self-merge fall-through the floor prints gate code as a `deny` line; the heading rule read `path` lines only, so it filed `merge-` where `--approved` requires `merge-gate-` (executed, P3/P4) | step 7 merge-entry heading | fact-check claim 9b | Fixed: `path` or `deny` lines |
| A4 | "A stop here loses only those lines; the next iteration writes them": nothing rewrites a lost `Dispatched:` line (static) | step 10 second land | fact-check claim 23 | Fixed: the session keeps N; a session that ends first loses it (Q-103 residual, stated) |

## 🟡 Must Address

| ID | Finding | Location | Source | Status |
|---|---|---|---|---|
| A5 | Rules still say "every build brief (step 6)" | Rules | claim 1 (Stale) | Fixed |
| A6 | "check 1" names a numbered check that no longer exists | Rules, step 6 | claim 2 (Stale) | Fixed |
| A7 | Step 9.3's list of `--cycle-diff` refusals omits several (deletion, non-regular side, refuse index, Asked: deleted/renamed, same-name brief paths, prompt files) | step 9.3 | claim 20 (Mostly accurate; the orchestrator reads it) | Fixed: completed, and pointed at the header |

## ⏭️ Skipped Core Critics

security-reviewer, performance-reviewer, api-consistency-reviewer, architecture-review: loop-pass short-circuit (behavioral red confirmed).

## Considered overrides

The rows this unit discharges (266, 269, 623, 673, 674, 680, 683, 701, 706, 714, 719-731, 745-761, 764, 769, 771, 772, 776, 777, 781, 784) were the brief's spec; none was contradicted.


## Iteration 2 (adc8a176): fact-check k=1 over 9777c1ff..adc8a176; full panel (security, api-consistency, architecture, performance) over the full branch

Reports: `code-fact-check-report-2026-10-13-u4b2-i2.md` (14 claims: 9 Verified, 3 Mostly accurate, 1 Stale, 1 Incorrect; A1-A3, A5, A6 verified fixed by execution), `security-review-2026-10-13-u4b2-i2.md` (6 Medium, 3 Low), `api-consistency-review-2026-10-13-u4b2-i2.md` (1 Breaking, 4 Inconsistent, 4 Minor, 3 Informational), `architecture-review-2026-10-13-u4b2-i2.md` (6 Coupling, 3 Minor, 2 Informational), `performance-review-2026-10-13-u4b2-i2.md` (1 High, 3 Medium, 1 Informational). Critics and fact-check ran in parallel this pass (critics read i1's fact-check report).

### 🔴 Must Fix

| ID | Finding | Source | Status |
|---|---|---|---|
| B1 | A blocked entry answered past [3] or with a fact reads `unrecognized` and was never re-dispatched (D2's async Path B never resumed; executed by api-consistency) | api-consistency 1 (Breaking), architecture 1, security note | Fixed: any answer but open/skip re-dispatches a blocked brief |
| B2 | The Rules said every script call runs from WT, contradicting step 7's gate checkout (following the Rules recreates A2) | fact-check claim 4 (Stale, behavioural) | Fixed: the D6 Rule names GT |

### 🟡 Must Address

| ID | Finding | Source | Status |
|---|---|---|---|
| B3 | A stopped REASON written raw into an entry can hold `<!--`, which questions.sh reads as its index marker and drops later entries (executed) | security F1 | Fixed: REASON on a `> ` line, `<!--` withheld |
| B4 | Answers read from main's live commit were acted on before the commit carrying them was classified | security F2 | Fixed: `--main-log MAIN` again before acting; an other line defers all answers |
| B5 | GT's worktree add and the merge of main into WT ran with no `--state` since step 0.1 (a planted filter ran; executed); a `refuse state` from --merge was filed as a loop's stop | security F3 | Fixed: --state before each; refuse state is a stop |
| B6 | Loop reports and task notifications were not listed as data; --answered could be taken from them or for a merge entry | security F4 | Fixed: Rules and step 9.3 |
| B7 | Dispatch read only step 0.2's --main-log; an other commit merged into WT mid-iteration fed the loops | security F5 | Fixed: --main-log MAIN again before dispatch |
| B8 | Self-merge refusals from rules every merge applies became merge entries that can never land | fact-check 5b, api-consistency 4 | Fixed in text: the entry says so; --approved's refusal files it stopped |
| B9 | A re-dispatched loop ending with no commit, or a retryable dispatch refusal after Applied: was written, was never routed again | fact-check E2, E3 | Fixed: an applied, unowned brief goes back to step 10; every re-dispatch uses --prompt --steal |
| B10 | "Slot" meant two things | api-consistency 3 | Fixed: D9's loop slots named apart from the Rules' "holds a slot" |
| B11 | A failed land's entries are re-derived next iteration; a stalled loop could then be re-dispatched unasked | architecture 3, api-consistency 6 | Fixed: the session keeps a stalled brief out of step 10 until its entry is answered |
| B12 | Step 1 filed a new `you: terminal` branch list every iteration | performance 1 | Fixed: the open entry is updated in place |
| B13 | Wakes and health checks wasted on unchanged main and on retries refused for two hours | performance 2 | Fixed: health check skipped when MAIN already passed; a retry wakes when its wait runs out |
| B14 | Step 9.3's refusal list still missed the whole-file questions refusal; `refuse index` is no slip | fact-check claim 7 | Fixed |
| B15 | The late Dispatched: lines' landing, the record's 9. line, the second land's own Paths landed, capped `@-`, `@TIP` stripped for --check-answer, `unrecognized`/`done` on stopped entries, the PR route unstated | fact-check 10, api-consistency 2, 7, 8, 11, 12 | Fixed |
| B16 | DISPATCH_CAP and STEAL_AGE copied with no pin | architecture 8 | Fixed: the GATE_CODE test also pins both |

Deferred or Won't-Fix (override rows dated 2026-10-13 for `feat/build-loop-u4b2`): architecture 2, 4, 5 (in part), 6, 7, 11; api-consistency 5, 9, 10; performance 3, 4 (in part); security F6, F8, F9. Informational, stated in step 9.5: architecture 10 (MAIN_WT's tracked edits stop each land). Security F7 fixed with B13 (step 4 runs no repo test after an other line).


## Iteration 3, final pass (c39a9692): fact-check k=3 over the full branch

Replicates: `code-fact-check-report-2026-10-13-u4b2-final-r{1,2,3}.md` (r1 40 claims, 6 Incorrect; r2 37 claims, 5 Incorrect; r3 30 claims, 1 Incorrect; most probes executed). Merged most-severe-wins in this table (no separate merged report: the canonical `code-fact-check-report.md` belongs to earlier units). Every replicate verdicted the answer-grammar sentence Incorrect; the `<!--` replacement text was Incorrect in r1 and r2 (r3: Mostly accurate, doc-only); the merge-in path (r1) and the health-check skip (r2) are single-replicate detections, both executed or traced. Verdict agreement on the clusters below: 4 of 9 unanimous.

Fact-Check Gate: high-confidence behavioural Incorrects. /away interim call (the U3c precedent): **fix first**, so the critic panel reviews the fixed HEAD.

### 🔴 Must Fix

| ID | Finding | Replicates | Status |
|---|---|---|---|
| C1 | Step 9's "merge main in and go back" fails with the iteration's edits staged (`git merge` refuses; `merge --abort` then fails), so any answer the user commits mid-iteration ended it (executed) | r1 claim 22 (Incorrect) | Fixed: commit first (tree checked), then --cycle-diff over HEAD's index; merge-in leaves WT clean |
| C2 | The replacement text for a REASON holding `<!--` itself holds `<!--`; FENCE_AWK refuses the questions file and every land stalls (executed) | r1 9a, r2 14a (Incorrect); r3 Mostly accurate | Fixed: wording without it; the reason names --check-answer |
| C3 | A stopped REASON starting `[` with `]:` or an open `[` breaks the questions file even behind `> ` (executed) | r1 9c (Incorrect) | Fixed: written as `> Reason: REASON` |
| C4 | The B13 health-check skip ("MAIN is the commit a check passed on") can never fire: each land makes a new main | r2 claim 4 (Incorrect) | Fixed: skipped when only `chore` lines moved main since a passing check |

### 🟡 Must Address

| ID | Finding | Replicates | Status |
|---|---|---|---|
| C5 | Environment refusals of `--merge` (no identity, MAIN_WT's state, a moved main) were routed to a user merge entry | r1 4b (Incorrect), r3 (Mostly accurate) | Fixed: only path refusals fall through; environment refusals retry |
| C6 | The answer grammar was stated wrongly (bare 1-3 and keep/drop/done read as options) | r1 10, r2 15b, r3 (Incorrect, doc-only in effect) | Fixed |
| C7 | The re-dispatch-on-Applied rule also caught briefs merged or dropped that iteration | r2 7b (Incorrect, fails closed) | Fixed: last applied answer asked for a re-dispatch, brief open |
| C8 | A [3] merge answer's note had no path to the loop | r1 claim 28 | Fixed: the merge entry's ID joins "Answered for you" |
| C9 | IDs filed this iteration read as skipped; --marker skips passed on from --status were filed as stopped | r2 E4, r1 claim 6 | Fixed |
| C10 | Commit messages adc8a176 and c39a9692 overstate (A2's cause, "refusals completed", "<!-- withheld", B13) | r1 35a, r2 32a/32b, r3 | Won't-Fix (override row): unmerged branch history, corrected by this commit's message |

Not fixed, stated: the `--cycle-diff` "regular 100644 file" refusal applies to the judged files only (r3, doc-only; the Rules already say a symlink fix passes); row 731's decision-log row for the reused `Main at:` name (r2 E5) is left to U5's decision-log pass.
