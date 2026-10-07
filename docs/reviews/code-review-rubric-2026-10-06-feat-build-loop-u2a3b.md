Commit: 98e3b1df
Loop-pass short-circuit: used at 1ccc8b65
# Code Review Rubric

**Scope:** iteration 3 (final confirming pass): `main...HEAD` at e48cf0f7 after the rebase onto main f6fdda68, no `--loop-pass`, k=3, full panel plus test-strategy, Stage 2.5; iteration 2: `45ad17b0..7ddff454` (full unit); iteration 1: `45ad17b0..1ccc8b65` | **Reviewed:** 2026-10-06 | **Status: 🔴 loop 2 iteration 1 did not pass at be94c871; its fixes are committed, pending iteration 2** (loop 1 ended at the iteration-4 gate below)

## Loop 2, iteration 2 of 3 (Commit 98e3b1df, be94c871..98e3b1df, --loop-pass, k=1, full panel)

Scope: the loop-pass default range from the rubric's stamp (be94c871), labelled partial: iteration 1's fixes dd51e9a7 and 98e3b1df. Delivery mode: self-read (shared brief in the session scratchpad). The short-circuit marker (used at 1ccc8b65) is on the file, so Stage 2 ran in full with amber collected. Stage 2.5 skipped (loop pass): routed endorsements stay *pending execution verification*. Considered overrides: the U2a3 and U2a3b rows (about lines 374-420 of the override log) were given to every critic; performance F3 found that line 386's revisit trigger fired (below).

Reports (`Commit: 98e3b1df`): `code-fact-check-report-build-loop-u2a3b-L2-i2.md` (42 claims: 31 Verified, 8 Mostly accurate, 3 Incorrect); `security-reviewer-review-2026-10-07-L2i2-build-loop-u2a3b.md` (2 Medium, 1 Informational); `performance-reviewer-review-2026-10-07-L2i2-build-loop-u2a3b.md` (3 Low, 1 Informational); `api-consistency-reviewer-review-2026-10-07-L2i2-build-loop-u2a3b.md` (1 Minor, 2 Informational); `architecture-review-review-2026-10-07-L2i2-build-loop-u2a3b.md` (1 Coupling, 3 Minor, 4 Informational); `test-strategy-review-2026-10-07-L2i2-build-loop-u2a3b.md` (F1-F9, 31 mutants, Appendix A tests, Appendix B fix sketch). Status at 98e3b1df: **🟡 does not pass** (2 Medium security ambers, 1 Coupling). All are fixed or routed in the follow-up commit, pending iteration 3.

### 🟡 Must Address (loop 2 iteration 2)

| ID | Finding | Source | Severity | Disposition |
|---|---|---|---|---|
| L2-I2-A1 | `@~/<path into the repo>` is a real import (Claude Code joins ~/ to the home directory); both walks dropped every ~/ name | security F1 (executed, 13 ~/ fragments); fact-check Claim 9; test-strategy F2 | Medium | ✅ Fixed: emit joins ~/ to import_home's HOME (as Node reads it: unset or empty uses the passwd entry), also through its real path; a ~/ name with a relative home fails the parser. Tests: repo under HOME, HOME a symlink, a relative home; each mutant fails |
| L2-I2-A2 | Skipping `.git/*` lets a file under .git, imported by an instruction file on main, hide its own imports (a regression from the refusal at be94c871) | security F2 (executed) | Medium | ✅ Fixed: only a bare `.git` component (top level or nested, architecture F3) is skipped; test-strategy's `@.git/HEAD` pass test replaced by a fail-closed test; the old-skip mutant fails |
| L2-I2-A3 | The superset is computed against the gate's one root and home, not the reading session's: an absolute name into another checkout, or a ~/ name under another HOME, is missed | architecture F1 (executed with a gate-worktree root) | Coupling | Routed to U2b (plan step 5's U2b bullet; override row 2026-10-07); named in the superset statement's exceptions |

### 🟢 Consider (loop 2 iteration 2)

| ID | Finding | Source | Disposition |
|---|---|---|---|
| L2-I2-C1 | python3 forks for every non-ASCII file (42 of 45; none changed): +0.33 s on --check-fix | performance F1; fact-check Claim 36b | Fixed: an awk ERE for well-formed UTF-8 gates the fork (it agreed with python3 on 20,013 cases); the gate mutant fails |
| L2-I2-C2 | A 9,990-byte `a/` run takes 10 s before the walk fails: the output bound is checked only after awk returns | performance F2 | Fixed: the walks pass IMPORT_LEFT and awk stops there (1.0 s); direct parser test; mutant fails |
| L2-I2-C3 | Override-log line 386's revisit trigger fired: the parent-link loop is O(L × depth) (a 2,820-byte deep token: 16.6 s, succeeds) | performance F3 | Fixed: parents already checked are memoized (1.0 s); the memo mutant survives (time only; override row) |
| L2-I2-C4 | The lib header does not name the python3 dependency | api F1; architecture F7 | Fixed: header clause |
| L2-I2-C5 | IMPORT_OUT_MAX: whether callers may change it; "bytes" vs characters; "about 2 KB" | api F2; fact-check Claim 7; test-strategy F9 | Fixed: the comment says characters, "more than", both figures, and that a caller clears the DONE caches |
| L2-I2-C6 | An unset ROOT_REAL aborts import_targets under set -u | api F3 | Fixed: `${ROOT_REAL:-}` |
| L2-I2-C7 | The single statement: ~/ missing, the symlinked-directory exception is not one, the case-insensitive and external-includes residues not named; two of A5's "untraced" items are traced | fact-check Claims 9, 11, 13; architecture F4; security F3 | Fixed: the statement names the five real exceptions; A5 records the traced items |
| L2-I2-C8 | Items routed out of iteration 1 were recorded only in the rubric | architecture F2 | Fixed: plan step 5's U2a3c and U2b bullets carry them; override rows 2026-10-07 |
| L2-I2-C9 | Untested: python3 failure, ROOT_REAL / and empty, the .. clamp at /, a file of exactly 4 MiB, the walk-wide budget boundary; the trim test mislabelled | test-strategy F1, F3-F7 | Fixed: test-strategy Appendix A applied (its `@.git/HEAD` test inverted, above) |
| L2-I2-C10 | The main walk reads blobs whole | architecture F5 | Deferred to U2a3c (one capped, drained reader); override row |
| L2-I2-C11 | Commit-message figures (timing, 941 paths) | fact-check Claims 36b, 38c, 35 | Accepted-immutable (override row) |

Size: 679 changed code lines against main (525 at 98e3b1df), under Q-104 [2]'s ~800 tolerance.

Verification: 143/143. --check-fix over 942 paths is identical to main; 3 interleaved runs: main 2.39-2.76 s, this branch 2.63-2.77 s. The long `a/` run fails in 1.0 s; the 2,820-byte deep token succeeds in 1.0 s.

### 🧩 Composition check (loop 2 iteration 2)

| # | Location | Fragments | Disposition |
|---|---|---|---|
| 1 | lib emit (~/ branch) | security F1, fact-check Claim 9, test-strategy F2, architecture F1 | composed: one root defect, the parser resolves names against one fixed reader (one root, no home); U2a3b adds the home, U2b the root set (L2-I2-A1 with A3) |
| 2 | main_imports .git skip | security F2, architecture F3, test-strategy F8 | distinct defects (security: the skip is too wide; architecture: too shallow); one rule fixes both |

Next: iteration 3, the final confirming pass (no `--loop-pass`, k=3, full panel over main...HEAD, Stage 2.5).

## Loop 2, iteration 1 of 3 (Commit be94c871, main...HEAD, --loop-pass, k=1, full panel)

Loop 2 reviews the over-approximation redesign (be94c871) chosen at loop 1's iteration-4 gate. The user paused the session while the panel ran; triage and fixes ran on resume (2026-10-07). Status: **🔴 DOES NOT PASS at be94c871** (behavioral fact-check Incorrect: not yet a superset; security F1). All findings below are fixed in dd51e9a7 and its follow-up, pending iteration 2.

Reports (`Commit: be94c871`): `code-fact-check-report-build-loop-u2a3b-L2-i1.md` (42 claims: 27 Verified, 3 Mostly accurate, 2 Stale, 10 Incorrect); `api-consistency-reviewer-review-2026-10-06-L2-build-loop-u2a3b.md` (2 Minor, 2 Informational); `architecture-review-review-2026-10-06-L2-build-loop-u2a3b.md` (2 Coupling, 1 Minor, 2 Informational); `test-strategy-review-2026-10-06-L2-build-loop-u2a3b.md` (F1-F5, Appendix A tests, Appendix B fix sketch); `performance-reviewer-review-2026-10-06-L2-build-loop-u2a3b.md` (3 Medium, 1 Low, 1 Informational); `security-reviewer-review-2026-10-06-L2-build-loop-u2a3b.md` (re-run on resume: 1 Medium, 1 Low; harness rebuilt from the installed 2.1.292 binary, 19,000 fuzz documents, be94c871 missed 453 of 6,751 names, all F1-shaped; none with F1's fix).

### 🔴 Must Fix (loop 2 iteration 1)

| ID | Finding | Source | Disposition |
|---|---|---|---|
| L2-R1 | Not a superset: `@../<repo>/docs/x.md` re-entry dropped (a fail-open regression from main at --check-fix), absolute spellings other than a literal ROOT_REAL prefix dropped, a backslash in dir/root mangled by `awk -v`, names over 4096 bytes that normalize short cut | fact-check Claims 1, 10, 15, 16, 39; architecture Coupling 2; test-strategy F1 | ✅ Fixed (dd51e9a7): candidates made absolute, `..` clamped at /, kept only below ROOT_REAL; dir and root through ENVIRON; no name cap; a root of / keeps every path, an empty root fails. Tests: Appendix A's four hole tests and its --check-fix test |

### 🟡 Must Address (loop 2 iteration 1)

| ID | Finding | Source | Severity | Disposition |
|---|---|---|---|---|
| L2-A1 | Claude Code decodes files as UTF-8 and turns invalid bytes into U+FFFD; the bytewise parser never yields that spelling (`@docs/\xff.md` reaching `docs/\xef\xbf\xbd.md`); pre-existing on main | security F1 (executed) | Medium | ✅ Fixed: text holding a byte above 0x7f is also read decoded by python3 (`decode("utf-8","replace")`, byte-identical to Claude Code's per the critic). Tests in both suites; the no-decode mutant fails. The LC_ALL=C guard's mutant survives (bash's range matches the byte under C.utf8 too): defence in depth |
| L2-A2 | ~~Claude Code trims the name, so `@\ docs/x.md` loads docs/x.md~~ Refuted at iteration 2 (fact-check Claim 31b): its name filter rejects a leading space before the resolver trims, so the trim only over-reads | security (transcription of the resolver) | ~~Medium~~ none | Kept as an over-read (harmless); test moved to the over-read test; override row 2026-10-07 |
| L2-A3 | splice is quadratic and outside the work bound | fact-check 18b; performance F1; test-strategy F3 | Medium | ✅ Fixed: its copying is charged to the bound; Appendix A test; mutant fails |
| L2-A4 | The work bound is per file; the bash side has no walk-wide limit | performance F2 | Medium | ✅ Fixed: IMPORT_OUT_MAX fails either walk. Iteration 2 (test-strategy F3): the test could not tell walk-wide from per-file; replaced by a two-file test with the exact-limit boundary, and awk now stops at the remaining budget (IMPORT_LEFT) |
| L2-A5 | main_imports forks lower per candidate | performance F3 | Medium | ✅ Fixed: once per file, as the tree walk |
| L2-A6 | A `.git` prefix candidate (from `@.gitignore`) fails the main walk in a linked worktree | architecture Coupling 1; api 3 | Coupling | ✅ Fixed at iteration 2: skipping `.git/*` hid the own imports of a file under .git (security L2-i2 F2, a regression from the refusal at be94c871); now only a bare `.git` component, at any depth, is skipped; tests for both. The general prefix-meets-checkout-file rule (an ignored `.env` beside `@.env.example`) is routed to U2a3c |

### 🟢 Consider (loop 2 iteration 1)

| ID | Finding | Source | Disposition |
|---|---|---|---|
| L2-C1 | import_targets returns awk's 3 or 2, not 1 | api 1; fact-check 18a | Fixed: `\|\| return 1`; the bound test asserts status 1 |
| L2-C2 | --check-fix says "imports it" for names only over-read | api 2 | Fixed: "names it after an @ ... so it may be read as instructions", in the help, the skill and the tests |
| L2-C3 | The superset claim is stated three ways | architecture 3; fact-check 3, 4b, 5 | Fixed: stated once above import_targets with its exceptions; A5 and F11 point to it; A5 records where the oracle came from |
| L2-C4 | Stale test comments (cut marks, "one grep match"); the over-read test holds two real imports | fact-check 27, 28, 29; test-strategy F5 | Fixed: comments rewritten; escaped-space and absolute cases moved into the superset test; the over-read test records the decision |
| L2-C5 | A large file a prefix candidate names stalls the tree walk (80 MB: 47 s) | security F2 (executed) | Fixed: the tree walk reads at most 4 MiB + 1 bytes (Claude Code skips larger files, so this only over-reads); tested with a sparse 300 MB file; mutant fails. The main walk still reads a blob whole (main's content, reviewed): deferred |
| L2-C6 | blocker forks per directory-prefix candidate | performance F4 | Deferred (Low; a U2a3c design question) |
| L2-C7 | scan visits every byte of @-less lines | performance F5 | Deferred (Informational) |

Size: 525 changed code lines against main after the fixes (350 at be94c871), past row 62's 400-line entry cap. Q-104 was answered [2] on 2026-10-06 (re-check per iteration, growth to ~800 tolerated), so the loop continues without a split. Most of the growth is reviewer-requested tests.

Verification: 133/133 (build-loop-check, dev-cycle, build-loop-read, fixture-git-env, hermeticity). `--check-fix` over 941 tracked `docs/*.md` and README.md is identical to main's output (wording aside); 3.25 s against main's 4.0 s.

Next: fix-drift over the fix commits, then iteration 2 (`--loop-pass`, k=1, full panel over main...HEAD).

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
