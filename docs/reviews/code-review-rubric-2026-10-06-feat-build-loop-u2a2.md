Commit: 7697c6e6
Loop closed at 7697c6e6
# Code Review Rubric

**Scope:** full branch `main...feat/build-loop-u2a2` at 7697c6e6 (final confirming pass; iterations 1 at 39ed1d53 and 2 at 7f295cdb below); 166 changed code lines by pr-prep 1a | **Reviewed:** 2026-10-06 | **Status: ✅ PASSES REVIEW, with one waived tier-T red that is not a regression (D1)** — single-sample review; absence of findings is not an attestation

## Iteration 3 of 3: final confirming pass (Commit 7697c6e6, full branch, k=3, full panel, Stage 2.5)

Review converged in 3 iterations, split twice for size (main_imports to U2a3, then U2a3's parser hardening to U2a3b). Iteration 1's A1-A5 and iteration 2's U2a2 rows (B1, B5 tree half, B9, B10, B13) are fixed; B7 is an override row; B2-B6, B8, B10-B12 and B14 went to U2a3.

Delivery mode: self-read. Critics: security, performance, api-consistency, architecture, test-strategy.

Reports (all `Commit: 7697c6e6`):
- `code-fact-check-report-build-loop-u2a2-final.md`, merged k=3 (replicates `-f-r1/-f-r2/-f-r3`: 41, 38, 30 claims), plus Stage 2.5 `code-fact-check-submitted-claims-build-loop-u2a2.md` (Claims 11-16: 4 Verified, 1 Mostly accurate, 1 Unverifiable).
- `security-reviewer-review-2026-10-06-final-build-loop-u2a2.md`: 1 Medium, 1 Low (run against Claude Code 2.1.292's own lexer and import function).
- `performance-reviewer-review-2026-10-06-final-build-loop-u2a2.md`: 1 Informational.
- `api-consistency-reviewer-review-2026-10-06-final-build-loop-u2a2.md`: 2 Minor, 3 Informational.
- `architecture-review-review-2026-10-06-final-build-loop-u2a2.md`: 0 Structural, 0 Coupling, 3 Minor, 2 Informational.
- `test-strategy-review-2026-10-06-final-build-loop-u2a2.md`: G1-G9, checked patches A and B.

Tests at 7697c6e6: 100/100 (dev-cycle 75, build-loop-read 19, build-loop-check 2, fixture-git-env 2, hermeticity 2); shellcheck clean.

| # | Finding | Severity | Source | Status | Author note |
|---|---|---|---|---|---|
| D1 | An @ right after a UNI_SPACES character is swallowed by the grep that splits tokens (`@a.md<NBSP>@b.md` reads only a.md; --check-fix says ok for b.md); the UNI_SPACES comment says "as a blank does" | Incorrect (behavioral) → 🔴 by tier T | fact-check Claim 1 (r1, r3), E1; security, architecture F1, api 2, test-strategy G9. Convergence | Waived (override row) | Not a regression: main misses b.md too, so this unit lands no worse than main. Fixed in U2a3b (3156b995), stacked and in its own loop. |
| D2 | Markdown ends Claude Code's token where the parser reads on (`<br>`, links, emphasis), and ( ) ] in a name end the parser's token early; the comment lists `[` | Medium; Incorrect (comment) | security final F1, fact-check Claim 2, E2 | 🟡 Acknowledged (override row) | Not a regression; fixed in U2a3b. |
| D3 | Tree walk failures hidden by `elif` (set -e off); grep errors swallowed; ROOT_REAL unchecked | Minor / Low | architecture F2-F3, security F2, api 1 | Deferred (override row) | Fixed in U2a3b. |
| D4 | bff4ded2's "never less" | Incorrect (commit message) | fact-check Claim 3 | Accepted-immutable | |
| D5 | questions.md:393 stale; header omits inrepo_here; test 1's NUL case not independent; `~x` dropped; imps' forward main arm | Stale / Mostly accurate | fact-check Claims 4-7, api I-1, I-3 | Deferred (override row) | Not edited after the confirming pass. |
| D6 | Untested guards G1-G8 | Low | test-strategy | Deferred (override row; Patch A) | |
| D7 | Double emission's extra probes per punctuation-ended token | Informational | performance F1 | Won't-Fix (override row) | |
| D8 | Instruction files in an untracked nested repo or submodule are not starts | Informational | security (candidate) | Deferred (override row) | U2a3's review. |
| D9 | instruction_names duplicates INSTRUCTION_FILE (on main already) | Informational | architecture F5 | No action | |

✅ Confirmed good (each backed by an executed verdict whose Scope covers the row):
- check_fix reaches the walk only through its last arm; an early-refused path costs 17-19 ms against 438-491 ms on main. Stage 2.5 Claim 11 (executed). Scope: check_fix's arm order.
- isimported answers imported for an unknown walk word and compares case-insensitively for tree. Stage 2.5 Claim 16 (executed probe of tree, bogus and '' against mixed-case paths). Scope: the two arms present in this unit.
- The tree walk starts once per process and later calls hit the cache. Stage 2.5 Claim 14 (xtrace of 10 arguments). Scope: one ROOT_REAL per process.
- UNI_SPACES holds exactly JavaScript's 19 non-ASCII \s code points. Fact-check Claim 8 (executed, all three replicates). Scope: the list, not how it is used (D1).
- The carried rows C12 and C13 bite: unsetting only GIT_DIR in either setup fails fixture-git-env via the index cmp; `p="$2"` fails entry_why's one-argument line. test-strategy final and fact-check r1/r3 (executed mutants). Scope: those two mutants.

Pending execution verification: Stage 2.5 Claim 12 (Claude Code's side of the security harness shapes; the binary read was refused).

Considered overrides: rows dated 2026-10-06 for `feat/build-loop-u2a`, `-u2a1`, `-u2a2` (A5 gaps, token forms, per-blob cost, walk naming, start-file rule, C12-C16, B7, B13). No critic re-filed one; B13's premise is confirmed (security final).

## 🧩 Composition check (iteration 3)
- lib:450-482 (fact-check Claim 1, security, architecture F1, api 2, test-strategy G9): one defect, stated whole with its fix by architecture F1; no composed row.
- lib:456-462 (fact-check Claim 2, E2, security F1): distinct defects (a comment's `[`; Markdown and ( ) ] token ends), each complete.
- lib:494-505 (architecture F2, F3; api 1; security F2): distinct defects (elif hides walk failures; grep status; ROOT_REAL contract), each complete.

## Iteration 2 of 3 (Commit 7f295cdb, full branch for critics, fix range for fact-check, --loop-pass, k=1, full panel)

Delivery mode: self-read. The short-circuit marker was used in iteration 1, so Stage 2 ran in full; the critics had never seen the branch, so they reviewed `main...HEAD` (fallback to full scope), and fact-check reviewed the fix range 39ed1d53..7f295cdb. Stage 2.5 skipped (loop pass). Fix-drift lite check on 39ed1d53..HEAD: no findings.

Reports (all `Commit: 7f295cdb`): `code-fact-check-report-build-loop-u2a2-i2.md` (22 claims: 18 Verified, 3 Incorrect (doc), 1 Unverifiable); `security-reviewer-review-2026-10-06-build-loop-u2a2.md` (2 Medium, 1 Informational); `performance-reviewer-review-2026-10-06-build-loop-u2a2.md` (1 Low, 2 Informational); `api-consistency-reviewer-review-2026-10-06-build-loop-u2a2.md` (1 Inconsistent, 3 Minor, 2 Informational); `architecture-review-review-2026-10-06-build-loop-u2a2.md` (1 Coupling, 1 Minor, 2 Informational); `test-strategy-review-2026-10-06-build-loop-u2a2.md` (F1-F4, checked patch in Appendix A). Prior iteration: A1-A5 verified fixed by fact-check i2.

**Split (pr-prep 1a size gate).** The fixes below plus the checked test patch would take the unit to ~480 code lines. It splits at a real seam: U2a2 keeps the shared token parser (`import_targets`, `UNI_SPACES`), `instruction_names`, `untracked_md`, `inrepo_here`, `isimported` (tree arm and the unknown-word arm), check_fix's call, the tree-walk test and U2a1's carried rows C12-C14; `main_imports` and `isimported main` move to U2a3 (`feat/build-loop-u2a3`, a fresh loop that starts with the B-rows marked U2a3); the floor becomes U2a4. Recorded under Q-119.

| # | Finding | Severity | Source | Unit | Status |
|---|---|---|---|---|---|
| B1 | U+FEFF ends Claude Code's token (JS `\s`) but not the walk's; `docs/bom.md` passes pathform (U2a F2's fix was incomplete) | Medium | security F1 (executed against the 2.1.292 regex) | U2a2 | ✅ Fixed (split commit) |
| B2 | `.claude/rules/` below the top level is not a start (`"$f" == .claude/rules/*.md`) | Medium | security F2 (executed) | U2a3 | Fix there |
| B3 | The checkout-file read at lib:561 has no failure guard (under `if` the walk continues and drops the file's imports); `tr` at :549 unchecked | Coupling / Inconsistent High / Informational | architecture F1, api F1, security F3, fact-check i2 E2. Convergence | U2a3 | Fix there |
| B4 | The narrowed "not covered" list (lib:463-466, known-issues A5, plan F11) omits start files under a symlinked directory present in the checkout | Incorrect (doc) | fact-check i2 Claims 2b, 9, 10, E1; api F4 | U2a3 | Fix there |
| B5 | Tests pass for the wrong reason (test 2's name check, test 6's walk result); no cycle fixture; six guards unprotected | Medium / Low-medium | test-strategy F1-F4 | U2a3 (the tree-walk cycle half: U2a2) | Tree-walk cycle: ✅ fixed (test 1; timeout in imps); the rest carried to U2a3 |
| B6 | main_imports checks every tree record in bash (~0.4 s here; ~2.1 s at 30k entries) where U2a filtered with one grep | Low | performance F1 | U2a3 | Decide there |
| B7 | The queue pop is O(q²) and each edge forks `lower` before the seen check | Informational | performance F2, F3 | U2a2 | Won't-Fix (override row) |
| B8 | `IMPORTED_MAIN=$'\n'` initially reads as a walk that succeeded | Minor | api F2 | U2a3 | Fix there |
| B9 | The token rules are described on the tree walk, not on the shared `import_targets`; the shared-parser contract (gate grammar fixes change --check-fix) is unstated | Minor / Informational | api F3, architecture F4 | U2a2 | ✅ Fixed (split commit) |
| B10 | The header omits `inrepo_here` (no need_root guard) and main_imports' resolve_main precondition | Minor | architecture F3 | U2a2 (inrepo_here); U2a3 (main) | ✅ Fixed here (inrepo_here); main half carried to U2a3 |
| B11 | The gate's verdict depends on more checkout state (targets main lacks, checkout symlinks) than plan F11 and the U2b bullet name | Informational | architecture F2 | U2a3 | Fix there (plan) |
| B12 | A main symlink whose text leaves the repo (`../shared/AGENTS.md`) is skipped and the walk succeeds; Claude Code would load it | Open question | test-strategy | U2a3 | Fix there (fail closed) |
| B13 | Claude Code keeps trailing punctuation (`@docs/style.md.` reads `docs/style.md.`); the walk records only the stripped name. New evidence on the settled `feat/build-loop-u2a` backslash/trailing-`_` row | Evidence on a settled row | security | U2a2 | ✅ Fixed (split commit) |
| B14 | Untested bypass candidates (.claude/commands and agents references, non-.md under .claude/rules, HTML escaping, a name stored as both tree and blob, `[`/`]` in a token) | Informational | security | U2a3 | Carry to U2a3's review |

Considered overrides: the `feat/build-loop-u2a` and `feat/build-loop-u2a1` rows dated 2026-10-06 (A5 gaps, per-blob cost, walk naming, start-file rule in both walks); critics did not re-file them. B13 reopens the backslash/trailing-`_` row's premise with executed evidence.

## 🧩 Composition check (iteration 2)

- lib:549-561 (architecture F1, api F1, security F3, fact-check E2): distinct statements of one defect, each complete (the missing guard and its fix); no composed row.
- lib:463-466 + known-issues :18 (fact-check i2 Claims 2b/9/10, api F4): one defect, stated whole by fact-check; no composed row.
- lib:469-473 UNI_SPACES (security F1) with api F3 (token-rule comment location): distinct defects (a missing code point; where the rules are written).

## Iteration 1 of 3 (Commit 39ed1d53, full branch, --loop-pass, k=1)

Delivery mode: self-read. Loop-pass short-circuit: behavioral 🔴 confirmed at fact-check (Claim 7) — critics skipped, returning to the loop for the fix. No enforcement file in the diff (hooks/live-verify-gate.sh regex), so mechanic 7 does not force security.

Reports: `code-fact-check-report-build-loop-u2a2.md` (k=1, 43 claims: 31 Verified, 6 Mostly accurate, 2 Stale, 4 Incorrect, 0 Unverifiable; probes in /tmp/u2a2-cfc-RrAi/).

Override-log scan: rows dated 2026-10-06 for `feat/build-loop-u2a` and `feat/build-loop-u2a1` matched (A5 gaps, walk naming, per-blob cost, start-file rule in both walks, C12-C16). Claim 7's two shapes are not among A5's settled gaps (fact-check E1), so they are not filtered.

## 🔴 Must Fix

| # | Finding | Severity | Source | Status | Author note |
|---|---|---|---|---|---|
| A1 | main_imports passes two shapes it does not model, against its "refuses what it does not model": a main symlink whose text holds a NUL (`$(...)` drops it, so the walk follows `docs/rules.mdzzz` while the checkout links `docs/rules.md`; executed) and a checkout symlink at an import target main lacks (`inrepo_here "$f" \|\| continue`, lib:555; executed). Imported files answer `-`. | Incorrect (behavioral) | fact-check Claim 7, E1 | ✅ Fixed (iteration-1 fix commit) | Checkout path that exists but is not plain fails the walk (a plain directory reads nothing); link text NULs counted before the read. Tests: build-loop-check.bats "...NUL, and on a checkout symlink..." |

## 🟡 Must Address

| # | Finding | Severity | Source | Status | Author note |
|---|---|---|---|---|---|
| A2 | A failing `git ls-tree` or `untracked_md` ends the process (errexit in `< <(...)`, then `${recs[-1]}` on an empty array) instead of returning 1 with IMPORTED_MAIN=error; isimported's "answers imported" and U2a3's worded refusal never happen there (lib:529-530, :539-540; executed) | Incorrect (contract; fails closed) | fact-check Claim 13a, E2 | ✅ Fixed | `cmd && printf rc=0 \|\| printf rc=1`, plus an empty-array guard; test "...returns, not exits..." |
| A3 | The symlink read's `if ! out="$(...; printf x)"` guard never fires (the status is printf's) | Verified-with-caveat | fact-check Claim 7 note | ✅ Fixed | `&& printf x` |
| A4 | main_imports' return-1 list omits main not found by name, the untracked listing failing, a record failing the regex, empty link text; "git would read the first copy" holds for lookups, while checkout keeps the last | Mostly accurate | fact-check | ✅ Fixed | comment lists every return-1 case |
| A5 | plan :275 still calls U2a2 "the floor" and says a `..` name is refused; no U2a3 entry | Stale | fact-check | ✅ Fixed | plan U2a2/U2a3 bullets; F11 and A5 updated too |
| A6 | Commit messages: d8003fbf's "53a6912b, kept on feat/build-loop-u2a2-full" (the branch holds its rebase 6c41aea2), "each command's exit status after its last NUL" (A2), the R2-R4 citation (R4 was fixed by following), "two listings both walks use" (only the tree walk uses instruction_names) | Incorrect / Mostly accurate (commit messages) | fact-check Claims 21, 22 | Accepted-immutable (override row) | |
| A7 | Override row at :339 cites `:13` and `:25`; at HEAD they are `:18` and `:21` | Stale | fact-check | Won't-Fix (override row; log is append-only) | |

## ⏭️ Skipped Core Critics

| Critic | Reason |
|---|---|
| security-reviewer, performance-reviewer, api-consistency-reviewer, architecture-review, test-strategy | loop-pass short-circuit (behavioral red confirmed) |

## 🧩 Composition check

No multi-source co-located clusters qualified (one source this pass).
