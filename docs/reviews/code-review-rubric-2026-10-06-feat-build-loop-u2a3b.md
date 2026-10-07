Commit: be94c871
Loop-pass short-circuit: used at 1ccc8b65
# Code Review Rubric

**Scope:** iteration 3 (final confirming pass): `main...HEAD` at e48cf0f7 after the rebase onto main f6fdda68, no `--loop-pass`, k=3, full panel plus test-strategy, Stage 2.5; iteration 2: `45ad17b0..7ddff454` (full unit); iteration 1: `45ad17b0..1ccc8b65` | **Reviewed:** 2026-10-06 | **Status: 🟡 CONDITIONAL PASS** — 0 red; 2 Medium security ambers and 8 Mostly-accurate wording ambers found at e48cf0f7, all fixed in 909de414 and its follow-up, not yet confirmed by a review pass (iteration-4 gate below)

## Loop 2, iteration 1 of 3 (Commit be94c871, main...HEAD, --loop-pass, k=1, full panel; PAUSED by the user before triage)

Loop 2 reviews the over-approximation redesign (be94c871) chosen at loop 1's iteration-4 gate. The user asked for a stopping point while the panel ran, so this iteration has no fixes yet. Status at pause: **🔴 DOES NOT PASS** (behavioral fact-check Incorrect: the parser is not yet a superset).

Reports (`Commit: be94c871`): `code-fact-check-report-build-loop-u2a3b-L2-i1.md` (42 claims: 27 Verified, 3 Mostly accurate, 2 Stale, 10 Incorrect); `api-consistency-reviewer-review-2026-10-06-L2-build-loop-u2a3b.md` (2 Minor, 2 Informational); `architecture-review-review-2026-10-06-L2-build-loop-u2a3b.md` (2 Coupling, 1 Minor, 2 Informational); `test-strategy-review-2026-10-06-L2-build-loop-u2a3b.md` (F1-F5, Appendix A tests, Appendix B fix sketch). Security and performance were still running at the pause; their reports (`security-reviewer-review-2026-10-06-L2-build-loop-u2a3b.md`, `performance-reviewer-review-2026-10-06-L2-build-loop-u2a3b.md`) will be untracked files in the worktree until the next session commits them.

Findings to triage on resume (not yet tiered):
- Behavioral (fact-check Claims 1, 10, 15, 16, 39; architecture Coupling 2; test-strategy F1): not a superset. `@../<repo>/docs/x.md` re-entry is dropped (`if (k == 0) return`), a fail-open regression from main at --check-fix; absolute spellings other than a literal ROOT_REAL prefix are dropped; mawk's `-v` escape processing mangles a dir or root holding a backslash; names over 4096 bytes that normalize short are cut. Agreed fix (architecture, tested 121/121; test-strategy Appendix B): resolve each candidate to an absolute path (root/dir/candidate, `..` clamped at /), keep it only under `root "/"`, pass dir and root through ENVIRON, drop the 4096 cap and rely on the work bound. Caveat: Appendix B drops every name when ROOT_REAL is /.
- splice is quadratic and outside the work bound (fact-check 18b, test-strategy F3): add its copying to `work`.
- main_imports fails the walk on prefix candidates the checkout holds as non-plain (architecture Coupling 1: `.git` in a linked worktree from `@.gitignore`; api 3: an ignored `.env` from `@.env.example`): fails closed, but U2b's fresh-worktree gate would refuse every path. Tested fix: skip `.git` and `.git/*` in main_imports; route the general prefix rule to U2a3c.
- import_targets returns awk's 3 or 2, not 1 (api 1, fact-check 18a): `|| return 1`.
- check_fix's skip wording claims an import for over-read names (api 2): "names it after an @ ... so it may be read as instructions", mirrored in the help text and the dev-cycle skill.
- The superset claim is stated three ways (architecture 3; fact-check 3, 4b, 5): state it once in the code comment with its exceptions; A5 and F11 point to it; restore non-literal absolute spellings to the gaps unless the resolution fix lands.
- Tests: test-strategy Appendix A (4 hole tests plus a --check-fix test, failing at be94c871; M21/M22 splice test; the blank-ends-a-candidate assertion); stale comments at build-loop-check.bats:341-342, :347; the over-read test's name and its two real imports (fact-check 29, test-strategy F5).

Next on resume: loop 2 iteration 1's triage and fixes from the list above (plus the security and performance reports), tests, fix-drift, then iteration 2.

## Iteration-4 gate (cap reached)

Iteration 3 was the last pass the cap allows, and it did not close clean: it found ambers (security F1 and F2, both fail-open; F1 regresses from main), so `Loop closed at` is not written. Its fixes are committed (909de414 plus the shim fix), tests are 120/120, and fix-drift found nothing, but no review pass has seen them. Decision: **escalate**, taken by the user in session on 2026-10-06 (relayed by the coordinator), with a design change: **over-approximate**. `import_targets` stops reproducing Claude Code's lexer shape by shape and reads a superset of what Claude Code could import, failing toward "imported". Because this is a design change, loop 1 ends here and a fresh loop (loop 2, new counter) reviews the redesign; its iterations are recorded above this section. Recommended: **escalate**, authorizing one more confirming pass (no `--loop-pass`, k=3, full panel, Stage 2.5) over `main...HEAD`: the fixes are local to import_targets and the tests, the unit is 286 code lines against main (inside the cap), and each fix follows a critic's tested candidate.

## Iteration 3 of 3: final confirming pass (Commit e48cf0f7, main...HEAD, k=3, full panel, Stage 2.5)

Rebase: onto main f6fdda68 (U2a3 merged at 97aa2d35 after its split). The lib merged without conflicts (fact-check replayed it); tests and the override log were resolved by keeping both sides. Post-rebase commit e48cf0f7 adopted nul_list (tree_starts), set IMPORTED=error, wrote the grammar trigger into A5 and F11, and closed the three rows routed to U2a3 (fixed there in c42f017f), I2-C5 and I2-A6's second half. The rebase changed little code, so no extra loop-pass iteration was run.

Delivery mode: self-read. Reports (all `Commit: e48cf0f7`):
- `code-fact-check-report-build-loop-u2a3b-final.md`: merged k=3 (replicates `-final-r1/-r2/-r3`: 36, 40, 45 claims) into 51 claims, 43 Verified, 8 Mostly accurate, 0 Incorrect; agreement 46/51 (90.2%); plus Stage 2.5 (`code-fact-check-submitted-claims-build-loop-u2a3b.md`, Claims 52-66b: 15 Verified, 1 Mostly accurate, all executed).
- `security-reviewer-review-2026-10-06-final-build-loop-u2a3b.md`: 2 Medium, 1 Low (context). Fuzz: about 15,000 documents against Claude Code 2.1.292's extracted lexer; main misses about half of its names, e48cf0f7 about 1%.
- `performance-reviewer-review-2026-10-06-final-build-loop-u2a3b.md`: 2 Low.
- `api-consistency-reviewer-review-2026-10-06-final-build-loop-u2a3b.md`: 2 Minor, 2 Informational.
- `architecture-review-review-2026-10-06-final-build-loop-u2a3b.md`: 0 Structural, 0 Coupling, 1 Minor, 2 Informational.
- `test-strategy-review-2026-10-06-final-build-loop-u2a3b.md`: G1-G7 (28 mutants, 14 survived, 5 equivalent), checked patch.

Tests at e48cf0f7: 119/119. After the iteration-3 fixes: 120/120 (five suites), shellcheck clean, 286 changed code lines against main. Fix-drift (on a code-only commit object, since the reports exceed the script's diff limit): no findings.

### 🟡 Must Address (iteration 3)

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| F3-A1 | One grep match runs through a link, code span, `<br>`, emphasis, autolink or image into a second @, so the second import is never read (`[@docs/a.md](u)/[@docs/b.md](v)`, `` @a`x`@b ``); the link and code-span shapes regress from main, in both walks (executed end to end) | Security | Medium | security F1; Stage 2.5 Claim 52 (35 F1-class misses in the corpus) | for-author | — | Fixed in 909de414, pending confirmation: each token also yields every suffix after an @ that follows a non-alphanumeric byte; tests la/lb, ca/cb; the no-suffix mutant fails | Divergence note: the third finding at import_targets' token rules (R1, I2-A1, now F3-A1); each widened the read set, and this one closes the swallowed-@ class the fuzzer found |
| F3-A2 | The comment splice paired comments across the whole file, so a stray earlier `<!--` (in a fence, a code span, text) shifted it and the spliced name followed an alphanumeric byte; an unclosed comment's tail was dropped | Security | Medium | security F2 (executed) | for-author | — | Fixed in 909de414, pending confirmation: per-line splice in one awk pass, unclosed comment kept; test docs/hidden.md; the no-copy mutant fails | |
| F3-A3 | Wording: the splice sentence, "test/agents-gemini-sync.bats pins another copy of the regex" (code and A5), the U2a2-only citation, "each call sits in an if or \|\|", two "(U2a3)" test tags, the cached-error test that cannot tell a cache from a recompute | Docs / tests | Mostly accurate | fact-check Claims 2, 3, 8, 19, 25, 26, 39, 41 | for-author | — | Fixed (comments, A5, tags; the test-strategy patch runs the second call with the real tr) | |
| F3-A4 | The grep shim exits without reading its input, so instruction_names' status mutant (M26) survives about 1 run in 3 under load | Tests | Mostly accurate | Stage 2.5 Claim 66b (executed, 200 runs) | for-author | — | Fixed: the shim drains its input; the mutant fails 5 of 5 | |

### 🟢 Consider (iteration 3)

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| F3-C1 | The HTML pass's `${x#*'<!--'}` is quadratic: dev-cycle SKILL.md 2 ms to 105 ms per walk; 200 KB 10.3 s | performance F1 | Low | for-author | override-log lines 412-413 | Fixed (one awk pass: 200 KB with an unclosed comment 28 ms) |
| F3-C2 | Per-token dedup strings make work cubic in cut marks (1,000 marks 29.8 s) | performance F2 | Low | for-author | row 363 | Fixed (associative arrays, x-prefixed keys: 2.35 s); residue Won't-Fix (override row) |
| F3-C3 | The walk's read/parser-failure arm, both lower guards, isimported's lower, the cached error and tree_starts' && are untested (mutants M01, M08-M13, M19 survive; M08/M09 fail open) | test-strategy G1-G6 (High/Medium/Low); fact-check escalations E1, E2; supersedes the C1 Defer row's "fails earlier" reason | High / Medium / Low | for-author | C1 row (iteration 1) | Fixed (checked patch; Stage 2.5 Claims 64-65) |
| F3-C4 | Root change within one process keeps a stale list (M03) | test-strategy G7 | Low | for-author | — | Won't-Fix (override row) |
| F3-C5 | dev-cycle.sh's --check-fix paragraph and the dev-cycle skill omit the walk-failed refusal; tree_starts missing from dev-cycle.bats' inventory; the header's pipefail list | api-consistency 1, 2, 3 | Minor / Informational | for-author | — | Fixed |
| F3-C6 | Raw reads of IMPORTED see "not imported" | api-consistency 4 | Informational | for-orchestrator-synthesis | — | Won't-Fix (override row) |
| F3-C7 | The grammar trigger is not where the digest reads; U2a4's predicate should own walk-then-isimported | architecture 1, 3 | Minor / Informational | for-author | I2-A6 rows | Deferred (override rows: U5, U2a4) |
| F3-C8 | main_imports' batch lower checks only the record count (a truncated last name drops a start) | security N1 (U2a3 code, context) | Low | for-author | — | Deferred: routed to U2a3c (override row) |
| F3-C9 | With a failing tr, --check-fix exits 1 with no output before the walk-failed wording (check_fix's own lower) | fact-check escalation E3; security disposition | Low | for-orchestrator-synthesis | — | Won't-Fix (override row; fails closed) |
| F3-C10 | A mutant dropping an unclosed comment's tail from the splice copy survives | iteration-3 fix mutants | Low | for-author | — | Won't-Fix (override row; only names holding <!--, which pathform refuses) |

### ↩️ Considered Overrides (iteration 3)

Rows 346, 347, 350, 355, 363 (U2a, U2a2), the U2a3b iteration-2 rows on per-file substitution and sed cost (override-log lines 412-413 at e48cf0f7) and this unit's rows dated 2026-10-06 matched. Inherited without re-flagging: 350 (the escaped space is the only fuzz miss left after the fixes), 346/355/363 and lines 412-413 (performance cited them and filed only the new quadratic and cubic costs), 347. Departed: the iteration-1 C1 Defer row's reason ("a failing tr fails earlier") is superseded by test-strategy's marker-tr shim (F3-C3); the routed-to-U2a3 rows are closed by main's c42f017f.

### ✅ Confirmed Good (iteration 3)

| Item | Verdict | Evidence | Source | Legibility-target |
|---|---|---|---|---|
| imported_names returns 1 with IMPORTED=error, cached, for a failing ls-files, untracked_md, grep -z, tr, sed, parser grep, unreadable file and newline start name | ✅ Confirmed | `nul_list recs tree_starts \|\| return 1`; merged fact-check (all three replicates executed); Stage 2.5 Claim 55 (executed) | Fact-check | for-orchestrator-synthesis |
| check_fix prints the walk-failed reason, before isimported, for every failure kind except a failing tr (F3-C9) | ✅ Confirmed | `elif ! imported_names; then`; Stage 2.5 Claim 60 (executed) | Fact-check | for-orchestrator-synthesis |
| At e48cf0f7 the parser's misses against Claude Code 2.1.292 in the 9-seed corpus are F1-class (35) and escaped-space (9) only; with the F1/F2 candidates only escaped-space remains | ✅ Confirmed (at e48cf0f7 and the critic's candidate, not the committed awk variant) | Stage 2.5 Claims 52, 53 (executed) | Fact-check | for-orchestrator-synthesis |

Pending execution verification: none routed; 909de414's awk splice has not been run through the security fuzz corpus (only the handcrafted cases and the suites).

### ⏭️ Skipped Core Critics (iteration 3)

All core critics ran; no skips applied.

### 🧩 Composition check (iteration 3)

| Cluster | File / lines | Fragments | Disposition |
|---|---|---|---|
| 1 | lib import_targets :519-526 | security F2, performance F1, fact-check Claim 19 | distinct defects (misaligned splice; quadratic cost; wording), one rewrite fixes all three |
| 2 | lib import_targets :529-547 | security F1, performance F2, fact-check Claims 10, 54 | distinct defects (swallowed @; cubic dedup) |
| 3 | lib imported_names :566-584, build-loop-check :357-378 | test-strategy G1, G2, G5, G6, fact-check Claims 8, 41, Stage 2.5 66b | distinct test gaps, each complete |

## Iteration 2 of 3 (Commit 7ddff454, range 45ad17b0..7ddff454, full unit scope, --loop-pass, k=1, full panel)

Scope: full unit, not the fix-only delta `1ccc8b65..7ddff454`, because the critics were short-circuited in iteration 1 and had never seen the unit (pr-prep 3d's fallback to a full re-review). Delivery mode: self-read. The short-circuit was already used (marker above), so Stage 2 ran in full with amber collected. Stage 2.5 skipped (loop pass): routed endorsement claims in the security and performance reports stay *pending execution verification*. Prior iteration: R1 and R2 verified fixed by fact-check i2 (each failure component executed); security F1 shows R1 held only for a name with no earlier cut mark (I2-A1).

Reports (all `Commit: 7ddff454`):
- `code-fact-check-report-build-loop-u2a3b-i2.md` (k=1, opus): 25 claims, 22 Verified, 3 Mostly accurate, 0 Incorrect; escalation to test-strategy (two unpinned controls).
- `security-reviewer-review-2026-10-06-build-loop-u2a3b.md`: 3 Medium, 1 Low (executed against Claude Code 2.1.292's extracted lexer).
- `performance-reviewer-review-2026-10-06-build-loop-u2a3b.md`: 3 Informational (walk 478 ms to 643 ms median here).
- `api-consistency-reviewer-review-2026-10-06-build-loop-u2a3b.md`: 1 Inconsistent, 3 Minor, 2 Informational.
- `architecture-review-review-2026-10-06-build-loop-u2a3b.md`: 0 Structural, 1 Coupling, 2 Minor, 2 Informational.

Tests at 7ddff454: 115/115. After the iteration-2 fix commit: 116/116 (five suites), shellcheck clean on the lib and dev-cycle.sh, 225 changed code lines against 45ad17b0. Mutants of each iteration-2 fix (first cut only, no comment pass, no newline check, instruction_names `|| true`, no sed g flag, here-string grep, no walk-failed reason) each fail a test.

### 🟡 Must Address (iteration 2)

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| I2-A1 | `${t%%cut*}` cuts only at the first cut mark, so a name holding `_` (or ( ) [ ] ! * <) followed by a code span, `<br>`, a link or emphasis is missed by both walks (``@docs/my_notes.md`code` `` regressed from 45ad17b0); R1's fix was incomplete | Security | Medium | security F1 (executed both sides) | for-author | row 358 | ✅ Fixed: each token yields its prefix before every cut mark; candidates are deduped before realpath (also performance F1). Test: my_notes + code span, s_g + `<br>`, k_l + `**b**`. Divergence note: R1 re-fired at the same site (iteration 1's fix targeted the backtick symptom; the root was first-mark-only cutting). |
| I2-A2 | In an HTML block opened by `<!--`, Claude Code deletes every comment and scans the rest, so `@docs/sec<!-- x -->ret.md` loads docs/secret.md, which no walk form yields (pre-existing) | Security | Medium | security F2 (executed) | for-author | — | ✅ Fixed: text holding `<!--` is read once more with every closed comment removed (an over-read elsewhere). Test: docs/secret.md. |
| I2-A3 | The tree walk's newline-separated `seen` list: a start under `a<NL>b/` makes `b/X.md` read as seen, so its imports pass --check-fix (pre-existing; main fails closed) | Security | Medium | security F3 (executed) | for-author | — | ✅ Fixed: a start name holding a newline fails the walk. Test in the tr test. |
| I2-A4 | A failed tree walk makes check_fix print "an instruction file imports it with @" for every path (a false reason; refusing is right); isimported's header tells only main's callers how to word a failed walk | API | Inconsistent | api-consistency 1, architecture 2 (both executed). Convergence | for-author | — | ✅ Fixed: check_fix runs imported_names under `if !` and prints "the instruction-file import walk failed"; isimported's header names both walks. Test in dev-cycle.bats. |
| I2-A5 | Comments and names: "a backslash-escaped space is known issue A5" (A5's text does not say so); the tr test name claims both walks meet a failing listing | Docs / tests | Mostly accurate | fact-check i2 | for-author | row 350 | ✅ Fixed (comment says the gap is deferred with A5's; test renamed). |
| I2-A6 | The parser copies Claude Code 2.1.292's grammar with no version or revisit trigger in the code, plan F11 or known issues; test/agents-gemini-sync.bats pins another copy | Architecture | Coupling | architecture 1 | for-author | — | ✅ Code half fixed (comment names the version, the source and the trigger, and points to the other copy); plan and known-issues half: Defer (override row; revisit trigger U5 or the first commit after rebase). |
| I2-A7 | `instruction_names returns grep's error status` in 7ddff454's message: it returns 1 | Docs (commit message) | Mostly accurate | fact-check i2 | for-author | — | Accepted-immutable (override row); the function's comment states it. |

### 🟢 Consider (iteration 2)

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| I2-C1 | Here-strings past ~64 KiB go to a temp file; a failed write reads as "no match" (import_targets' grep and loop, imported_names' loop) | security F4 (executed, ulimit -f 0) | Low | for-author | — | Fixed (pipe and process substitution; test with ulimit -f 0) |
| I2-C2 | main_imports' header omits the new lower guard, the parser, the candidate tr and the cached error | api-consistency 2 | Minor | for-author | — | Deferred: routed to U2a3 (override row) |
| I2-C3 | Three copies of the rc=0 listing check, two marker-drop styles, unstated record rules | architecture 3 | Minor | for-author | — | Deferred: routed to U2a3 (override row) |
| I2-C4 | main_imports' own here-string (`done <<<"$out"`) has I2-C1's failure | security F4 (U2a3 code) | Low | for-author | — | Deferred: routed to U2a3 (override row) |
| I2-C5 | IMPORTED starts as $'\n' (a successful empty walk), IMPORTED_MAIN as error | api-consistency 3 | Minor | for-author | — | Deferred (override row; the line abuts U2a3's edits) |
| I2-C6 | inrepo_here failing skips a path in the tree walk, fails main's | architecture 4 | Informational | for-orchestrator-synthesis | row 347 | Won't-Fix (override row) |
| I2-C7 | Two substitutions per walked file (+2 ms each) | performance F2 | Informational | for-author | rows 346, 355 | Won't-Fix (override row) |
| I2-C8 | Whole file in a variable through a 20-expression sed (5 MB: 189 ms, 28.8 MB) | performance F3 | Informational | for-author | — | Won't-Fix (override row) |
| I2-C9 | Every token paid 4 realpath forks, dedup only after the fork (200 plain tokens: 932 ms against 271 ms) | performance F1 | Informational | for-author | row 363 | Fixed with I2-A1 (dedup before the fork) |
| I2-C10 | isimported's header omits the failed-lower case; instruction_names' inverted status unstated; the lib header does not say the walks return 1 and need if or \|\| | api-consistency 4, 5, 6 | Minor / Informational | for-author | — | Fixed (comments) |
| I2-C11 | The imps helper always printed "walk: ok" for tree, so tests caught a failed tree walk only through a negative check | architecture 5 | Informational | for-author | — | Fixed (imps reports imported_names' return; the tr test asserts the tree walk fails) |
| I2-C12 | instruction_names' error status and the sed `g` flag were unpinned (mutants survive) | fact-check i2 escalation (test-strategy) | Low | for-author | — | Fixed (grep -z shim case; p/q/r NBSP case) |

### ↩️ Considered Overrides (iteration 2)

Rows 346, 347, 350, 355, 358, 359, 363 (U2a, U2a2) and this loop's two iteration-1 rows matched. Inherited: 346/355/363 (batching; performance cited them, I2-C9 was filed as broader), 347 (the walks differ on purpose; I2-C6), 350 (escaped space; I2-A5). Departed: none; 358's fix was incomplete (I2-A1) and is completed.

### ✅ Confirmed Good (iteration 2)

| Item | Verdict | Evidence | Source | Legibility-target |
|---|---|---|---|---|
| The start-list check returns 1 for each component failing (corrupt index, ls-files, untracked_md, grep exit 2, an unreadable start file, a failing tr), first call and cached | ✅ Confirmed | `[[ ${#recs[@]} -gt 0 && "${recs[-1]}" == rc=0 ]] \|\| return 1`; fact-check i2 focus 1 (executed) | Fact-check | for-orchestrator-synthesis |
| No caller breaks on instruction_names' new status (only imported_names calls it) | ✅ Confirmed | `rg -n instruction_names` across scripts and tests; fact-check i2 focus 2 (enumerated) | Fact-check | for-orchestrator-synthesis |

### ⏭️ Skipped Core Critics (iteration 2)

All core critics ran; no skips applied.

### 🧩 Composition check (iteration 2)

| Cluster | File / lines | Fragments | Disposition |
|---|---|---|---|
| 1 | `scripts/dev-cycle.sh:181`, lib isimported | api-consistency 1, architecture 2 | distinct statements of one defect, each complete (I2-A4); no composed row |
| 2 | lib import_targets :500-519 | security F1, F2, F4; performance F1-F3; fact-check i2 (g flag) | distinct defects (cut position, HTML comment splice, temp-file here-string, fork count, substitution cost, memory); no composed row |
| 3 | lib imported_names start loop | security F3, architecture 3, 4; fact-check i2 focus 1 | distinct defects (newline seen list, duplicated marker check, inrepo_here asymmetry) |

## Iteration 1 of 3 (Commit 1ccc8b65, range 45ad17b0..1ccc8b65, --loop-pass, k=1)

Delivery mode: self-read (each agent read the shared block from the session scratchpad, its skill file and the diff itself). Loop-pass short-circuit: a behavioral 🔴 was confirmed at fact-check (Claim 7b), so the critics were skipped and the pass went back to the loop for the fix. No enforcement file is in the diff (hooks/live-verify-gate.sh regex), so mechanic 7 does not force security.

Reports: `code-fact-check-report-build-loop-u2a3b.md` (k=1, opus, 37 claims: 24 Verified, 8 Mostly accurate, 5 Incorrect, 0 Stale, 0 Unverifiable; probes and mutant logs in /tmp/u2a3b-factcheck-FQ0K/_logs/).

Tests at 1ccc8b65: 114/114 (five suites); shellcheck clean. After the fix: 115/115 (Patch A adds one test); shellcheck clean; 155 changed code lines against 45ad17b0 by pr-prep 1a.

## 🔴 Must Fix

| # | Finding | Domain | Severity | Source | Location | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|---|---|
| R1 | The comment names a code span among the Markdown that ends a token sooner, but the cut set `[][()<!*_]` has no backtick. For ``Read @docs/a.md`x` first.``, `--check-fix docs/a.md` was `skip` at 45ad17b0 and is `ok` at 1ccc8b65, while Claude Code 2.1.292 imports docs/a.md. Fail-open regression (executed end to end). | Correctness (gate) | Incorrect (high), behavioral | Fact-check Claim 7b | `scripts/lib/dev-cycle-read.sh` import_targets | for-author | — (row 358's fix, now completed) | ✅ Fixed: the cut set holds a backtick (`b=$'\x60'`, quoted in the pattern); the parser test reads `@docs/j.md` followed by a closed code span. Mutant (no backtick in the cut) fails it. |
| R2 | imported_names' new header says it "returns 1 ... when a command it runs fails", but the start listing `< <({ git ls-files -z; untracked_md; } \| instruction_names)` is never checked and instruction_names ends in `\|\| true`: with ls-files failing the walk returns 0 with an empty IMPORTED and a tracked import answers "not imported". The `local -; set -o pipefail` does not reach the process substitution. Fail-open (executed). | Correctness (gate) | Incorrect (high), behavioral | Fact-check Claim 1b | `scripts/lib/dev-cycle-read.sh` imported_names | for-author | — (row 359's fix, now completed) | ✅ Fixed: the listing ends with `rc=0` only when both listings and the filter succeed (main_imports' pattern), checked before the loop; instruction_names returns grep's error status; the comment lists the failures that return 1. Test: a corrupt index gives `walk failed` and `isimported tree` answers imported. Mutant (no rc check) fails it. |

## 🟡 Must Address

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | Claude Code's regex does not end a token at `#`; it cuts the captured name at `#` afterwards (so `@x.md#@y.md` over-reads y.md, safe) | Docs | Mostly accurate | Fact-check Claims 5, 22 | for-author | row 350 (escaped space) | ✅ Fixed (comment) | |
| A2 | Test name "read what Claude Code reads ... ~x": Claude Code never loads `@~g.md` | Tests | Incorrect (test name) | Fact-check Claim 17b | for-author | — | ✅ Fixed: "~x is over-read, ~/ dropped"; the test now also checks `@~/x.md` is dropped (the bare ~/ exclusion mutant survived before) | |
| A3 | The tr test's imps loop passes through isimported's own lower guard, so neither walk's guards are exercised there; `walk: failed` is never asserted | Tests | Mostly accurate | Fact-check Claims 18, 19 | for-author | — | ✅ Fixed (partly): `walk failed` asserted for main; the direct calls check imported_names' start-file guard and its cached error (mutant fails). Residue in C1. | |
| A4 | Commit 1ccc8b65's message: `@~g.md` "names a file"; "the one way it refuses less" misses the code span; plus five Mostly accurate statements | Docs (commit message) | Incorrect / Mostly accurate | Fact-check Claims 20, 22, 23b, 29b, 30, 31, 32 | for-author | — | Accepted-immutable (override row) | The branch is not rebased; the fix commit states the corrected facts. |

## 🟢 Consider

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | Surviving mutants: the grep status-2 guard, the ) ] and backtick strips, per-token dedup, imported_names' per-path lower guard, main_imports' lower guard (a failing tr fails main_imports earlier) | Fact-check Claim 18 | Low | for-author | — | Deferred (override row) |
| C2 | test-strategy final Patch A (U2a2): two NBSPs in a run, a target only after a NUL, a missing directory, mixed-case queries, isimported's need_root, all 19 Unicode spaces, a SKILL.md start, an untracked .MD start | Override row 362 trigger | Low | for-author | row 362 | Fixed: applied as checked; its new test runs over both walks (the report's coverage gap 3) |

## ↩️ Considered Overrides

| Override (PR ref / Date) | Prior finding | Original → Override | Reason | This run's treatment |
|---|---|---|---|---|
| `feat/build-loop-u2a2` / 2026-10-06 (row 357) | @ after a UNI_SPACES character swallowed | Fact-check Incorrect → Defer | fixed in U2a3b | Verified fixed by fact-check (space-to-blank mutant fails). |
| `feat/build-loop-u2a2` / 2026-10-06 (row 358) | Markdown ends Claude Code's token; ( ) ] in a name | 🟡 → Defer | fixed in U2a3b | Fix incomplete at 1ccc8b65 (R1, code span); completed in the fix commit. |
| `feat/build-loop-u2a2` / 2026-10-06 (row 359) | Tree walk failures hidden; grep errors swallowed; ROOT_REAL unchecked | 🟢 → Defer | fixed in U2a3b | Fix incomplete at 1ccc8b65 (R2, start listing); completed in the fix commit. |
| `feat/build-loop-u2a2` / 2026-10-06 (rows 361, 362) | `~x` dropped; test 1's NUL case; untested guards G1-G8 | Stale / 🟢 → Defer | U2a3b's review applies Patch A | `~x` now over-read; Patch A applied (C2). |
| `feat/build-loop-u2a` / 2026-10-06 (row 350) | Backslash-escaped space and other A5 gaps | 🟡 → Defer | known issue A5 | Inherited; Claim 5 notes `\ ` again, not re-flagged. |
| `feat/build-loop-u2a2` / 2026-10-06 (rows 346, 355, 363) | Per-blob reads, O(q²) queue, extra probes | 🟢 → Won't-Fix / Defer | batching rework | Inherited; not re-flagged (no critics ran). |

## ✅ Confirmed Good

| Item | Verdict | Evidence | Source | Legibility-target |
|---|---|---|---|---|
| A NUL becomes a blank under GNU sed 4.9 with no "ignored null byte" warning | ✅ Confirmed | `scripts/lib/dev-cycle-read.sh` import_targets — `s=(-e 's/\x0/ /g')`; FC (executed) | Fact-check | for-orchestrator-synthesis |
| grep's no-match (1) is not a parser failure; its error status (2) returns 1 | ✅ Confirmed | `toks="$(env LC_ALL=C grep -aoE "$IMPORT_RE" <<<"$toks")" \|\| [[ $? -eq 1 ]] \|\| return 1`; FC (executed) | Fact-check | for-orchestrator-synthesis |
| `i` is local in main_imports | ✅ Confirmed | `local - rec f d p src i out ...`; FC | Fact-check | for-orchestrator-synthesis |

## ⚠️ Unverified Findings

All findings' evidence resolved.

## ⏭️ Skipped Core Critics

| Critic | Reason | Signal |
|---|---|---|
| security-reviewer, performance-reviewer, api-consistency-reviewer, architecture-review | loop-pass short-circuit (behavioral red confirmed) | Fact-check Claim 7b (executed regression) |

## 🧩 Composition check

No multi-source co-located clusters qualified (one source this pass).

---

To pass review: all 🔴 items must be resolved. All 🟡 items must be either fixed or carry a qualifying author note (a discoverable TODO or a concrete revisit trigger; see "Qualifying author note" in `skills/code-review/references/rubric.md`). 🟢 items are optional.
