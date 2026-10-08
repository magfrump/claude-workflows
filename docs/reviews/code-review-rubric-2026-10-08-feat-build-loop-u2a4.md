Commit: a3489c4f
Loop-pass short-circuit: used at 03be719e
# Code Review Rubric

**Branch:** `feat/build-loop-u2a4` (U2a4, the self-merge floor over one read-as-truth rule and one start predicate), on main 7afdb8d2. Iterations 1 and 2 are in `code-review-rubric-2026-10-07-feat-build-loop-u2a4.md`.
**Status: ⚠️ CONFIRMING PASS (Q-131 [1]) NOT CLEAN — one Medium security under-read (a regression in 2f9464d3) and Lows, all fixed (unreviewed but tested against the old lib); 599 code lines; landing goes back to the user per Q-131 (Q-132)** (single-sample review; absence of findings is not an attestation)

## Confirming pass after Q-131 [1] (Commit a3489c4f, scope 2b6f2f91..a3489c4f)

Q-131 [1] waived the size cap and asked for a k=1 fact-check plus the security critic over the final pass's unreviewed fixes (2f9464d3); a new finding goes back to the user. Delivery: self-read. The security critic used the installed Claude Code 2.1.293 binary as its oracle (its mention reader, regex `(^|[\s。、？！])@"([^"]+)"`, and file-name parser).

Reports (both `Commit: a3489c4f`):
- `code-fact-check-report-build-loop-u2a4-confirm.md`: 32 claims. 21 Verified, 8 Mostly accurate, 2 Stale, 0 Incorrect, 1 Unverifiable.
- `security-reviewer-review-2026-10-08-build-loop-u2a4-confirm.md`: 1 Medium, 4 Low, 2 Informational.

| # | Finding | Severity | Source | Status |
|---|---|---|---|---|
| CP1 | A quoted mention with a `#L5`/`#section` suffix and a blank in its name is no longer read (Claude Code's file-name parser drops the suffix; the pre-2f9464d3 prefix reader caught it): the floor would pass the file | 🟡 Medium (regression) | security F1 (executed) | Fixed: `quoted` also reads the text before its first `#` |
| CP2 | A `@"` at the end of a line was not carried | 🟢 Low | security F2 | Fixed: an explicit open-quote flag `qo` |
| CP3 | A start-named link to a directory (`.claude/rules/r.md -> ../../p`) passed START_LINK and was then dropped | 🟢 Low | security F3 | Fixed: a link to a directory or gitlink fails the main walk; a gitlink start at a START_LINK path fails too (fact-check 4b) |
| CP4 | `qopen` re-copied the held text per line uncharged: an unclosed quote over many lines ran quadratic time (193 s at 4 MB) instead of failing the bound | 🟢 Low | security F4, fact-check Stale 15a, Mostly 7b, 19f | Fixed: each copy is charged; a new test fails both walks on it |
| CP5 | A quoted name holding a UNI_SPACES character is read with a blank (sed runs first) | 🟢 Low (pre-existing) | security F5 | Deferred: override row, known issue A5 |
| CP6 | A quote opened only in the comment-spliced line was not carried; a quoted name was only read trimmed | Informational | security notes, fact-check Mostly 8a | Fixed (over-read): the spliced scan carries when the raw one did not; quoted names are read trimmed and as written |
| CP7 | main_imports' two failure lists omitted START_LINK; START_LINK's comment, contract item 8, IMPORT_WORK_MAX's "uncharged" note and a test comment were imprecise | 🟢 | fact-check Stale 15c, Mostly 2, 3, 15b, 16c | Fixed |
| CP8 | The Claude Code 2.1.293 regex | — | fact-check Unverifiable 8b | The security critic read it from the installed binary |

Tests after the fixes: build-loop-check 79/79 (the new cases in tests 74 and 77 and the new test 78 fail on the pre-fix lib), build-loop-read 19, dev-cycle 78, fixture-git-env 2, fixture-hermeticity 2, hermeticity-lint 53; shellcheck clean; `--check-fix` gives main's answers over all tracked paths; both walks pass on this repo and /workspace (about 1.4 s). `scripts/health-check.sh` passed at a3489c4f.

## Iteration 3 of 3: final confirming pass (Commit 2b6f2f91, k=3, full panel, Stage 2.5)

Scope: full branch `main...HEAD`. Delivery mode: self-read. Panel: security, performance, api-consistency, architecture. The critics got Stage 1's attention list and escalations as an inline summary (the canonical merge ran in parallel with them; no claim was Incorrect, so no gate was skipped).

Reports (all `Commit: 2b6f2f91`):
- `code-fact-check-report-build-loop-u2a4-final.md` (merged from `-final-r1..r3`): k=3, 58 claims. 43 Verified, 12 Mostly accurate, 1 Stale, 0 Incorrect, 2 Unverifiable; verdict agreement 84.4% (38/45 multi-replicate clusters). Stage 2.5's submitted claims 60-68 are appended: 8 Verified, 1 Mostly accurate.
- `security-reviewer-review-2026-10-08-build-loop-u2a4-final.md`: 2 Medium, 2 Low.
- `performance-reviewer-review-2026-10-08-build-loop-u2a4-final.md`: 1 Low, 1 Informational.
- `api-consistency-reviewer-review-2026-10-08-build-loop-u2a4-final.md`: 3 Minor, 3 Informational. Nothing Breaking.
- `architecture-review-review-2026-10-08-build-loop-u2a4-final.md`: 2 Minor, 3 Informational. Nothing Structural.
- `code-fact-check-submitted-claims-build-loop-u2a4.md`: Stage 2.5 (claims 60-68).

Tests after the fixes (2f9464d3): build-loop-check 78/78, build-loop-read 19/19, dev-cycle 78/78, fixture-git-env 2/2, fixture-hermeticity 2/2, hermeticity-lint 53/53; shellcheck -S warning clean; the fix-drift lite check over 2f9464d3 found nothing.

### 🔴 Must Fix

None.

### 🟡 Must Address

| # | Finding | Severity | Source | Status | Author note |
|---|---|---|---|---|---|
| F1 | A prompt directory main stores as a link (`.claude/commands -> ../prompts`, or `.claude -> cfg`) lists its prompts under the target's path, which isstart does not match, so the command body itself passes the floor. Before U2a4's directory rule, this gap only lost a resolution base. | Medium | security F1 (executed; re-opens override row 350's class with new cost) | Fixed (2f9464d3, unreviewed) | main_imports fails on a link or gitlink at or below a `.claude/` start directory, or at `.claude` itself, unless the link is itself a start (a rules file link is still followed). Tested (`.claude/commands`, `.claude/Skills`, `.claude`). |
| F2 | A quoted mention spanning a line break (`@"x⏎/../docs/q.md"`) was never read. The binary's `@"([^"]+)"` spans lines; the parser read one line at a time. | Medium (Low confidence) | security F2 (executed) | Fixed (2f9464d3, unreviewed) | The whole quoted text is read once at its closing quote, on that line or a later one. The carry is charged as work, and a resolved name holding a newline is dropped. Tested. |

### 🟢 Consider

| # | Finding | Source | Status |
|---|---|---|---|
| G1 | An unclosed `@"` before about 3 KB of prose printed about 4 MB of prefixes, so both walks failed closed (a regression from main) | performance F1 | Fixed with F2: the quoted run adds no prefixes past a blank. Tested in an instruction file and a prompt |
| G2 | The parser's "one statement" paragraph omitted the quoted run, the further base directories and the prompt-mention reader | fact-check Claim 36 (Stale, r1), security F3, architecture F2, api 3 | Fixed |
| G3 | prompt_bases added a base for a `.claudex` component (over-read) | fact-check Claim 31 (all three), architecture F3 | Fixed: it splits whole components. Tested |
| G4 | floor's import reason named only instruction files on the default branch | api 1, fact-check Claim 50 | Fixed (it names prompt and checkout-only importers) |
| G5 | Cache comments still said to clear variables by name, and A5 restated the contract | api 2, architecture F1, fact-check Claim 15 | Fixed (they point to import_reset and to the contract) |
| G6 | Contract item 8 omitted prompt_dir and prompt_bases | api 4 | Fixed |
| G7 | truthwalk's comment omitted the lower-case failure arm | fact-check Claim 46 | Fixed |
| G8 | The lib summary did not mention the floor | architecture F4, api 6 | Fixed; the sourcing-test half is Won't-Fix (override row) |
| G9 | Known issue A2 missed the checkout-only symlinked start | fact-check Claim 13 | Fixed |
| G10 | Override rows 463 (skills/ untraced), 468 (trigger too narrow) and 477 (overstated seam) | fact-check Claim 6, security F4, architecture F5 | Rows corrected |
| G11 | IT_XDIRS fails `env` at about 256 nested `.claude/` levels (fail-closed) | performance F2 | Won't-Fix (override row) |
| G12 | PROMPT_DIR and prompt_dir differ only in case | api 5 | Won't-Fix (override row) |
| G13 | A start removed from the index and edited is read from main's copy | fact-check escalation (r3) | Routed to U2b's clean-worktree check (override row) |
| G14 | In a prompt, a blank-free run of about 2,000 characters prints past IMPORT_OUT_MAX once per base (fail-closed); A7's "walks ok" holds only for instruction files | fact-check Claim 2 (r2) | Won't-Fix (override row); the test now covers the prompt case for the quoted run |
| G15 | Size: 540 code lines against main (381 at step 1a) | process | Routed: Q-131 |
| G16 | Commit-message counts and bases (c934adbc, a5ad8c08) | fact-check Claims 51, 52 | Accepted-immutable row |
| G17 | Claude Code's command expansion calling the quoted-mention reader; c934adbc's health check | fact-check Claims 42, 58 (Unverifiable) | The first needs the binary (no egress here); the step 5a gate re-runs the second |

### ✅ Confirmed Good

| Claim | Evidence | Backing |
|---|---|---|
| floor's only `return 1` is its final else: every path no earlier arm refuses reaches `truthwalk main`, a brief's own working and review files included | `scripts/lib/dev-cycle-read.sh` floor (at 2b6f2f91 :1039-1061) | Stage 2.5 Claim 61, Verified (executed) |
| truthwalk returns 0 when its walk fails or the walk name is unknown, and 1 with TRUTH_WHY empty only after a successful walk misses (a failed lower answers 0, `imported`) | truthwalk, isimported | Stage 2.5 Claim 62, Verified (executed) |
| check_fix refuses every path main's check_fix refused: byte-identical output over all 3,104 tracked paths; on 37 synthetic paths it refuses only more | `scripts/dev-cycle.sh` check_fix | Stage 2.5 Claim 63, Verified (executed); Stage 1 replicates |
| floor refuses every path the pre-split ancestor (`feat/build-loop-u2a2-full`) refused: 6,320 path × status-letter pairs | floor vs the ancestor | Stage 1 r2, Verified (executed) |
| The index pop removes a super-linear term (main walk N=3000/N=1000: about x3.3 at HEAD against about x4.7 with main's lib) | main_imports, imported_names | Stage 2.5 Claim 64, Verified (executed, Medium) |
| The quoted run's work charge bounds it: a 200,000-character run fails closed in under 0.4 s; doubling the run multiplies work by 3.96 (quadratic) | IMPORT_AWK | Stage 2.5 Claims 66, 68, Verified (executed) at 2b6f2f91. 2f9464d3 then narrowed the run further, unreviewed |

### 🧩 Composition check

- IMPORT_AWK scan/names (security F2, performance F1, fact-check Claim 36): one root, composed. The quoted run read prefixes across blanks and only within a line; reading the whole quoted text once at its closing quote (on any line) and adding no prefixes past a blank closes both. Each fragment's own text names a half of it; no tier lift.
- prompt_bases (fact-check Claim 31, architecture F3, Stage 2.5 Claim 60's note): one fix (whole components).
- Cache comments / contract (api 2, architecture F1, fact-check Claim 15): one doc fix.

### ⏭️ Skipped Core Critics

None.

### Considered overrides

Matched: this unit's rows dated 2026-10-07 and 2026-10-08 for `feat/build-loop-u2a4`, and rows 350 (start files under a symlinked directory: re-opened by security F1 with new cost, now fixed for start directories) and 469 (output budget binds for prompt starts: covers G14). No other finding re-opened a settled row.
