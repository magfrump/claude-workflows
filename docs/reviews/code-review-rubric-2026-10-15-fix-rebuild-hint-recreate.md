Commit: 756c11f9
# Code Review Rubric

**Scope:** `fix/rebuild-hint-recreate` (`9660d4f6...HEAD`; base `merge/ready-2026-10-15`) | **Reviewed:** 2026-10-15 | **Status: ✅ PASSES REVIEW** — single-sample review; absence of findings is not an attestation. The loop closed at the 3-iteration cap: iteration 3's ambers (all wording, test comments and records) were fixed after the confirming pass in 756c11f9 and checked by a narrow fact-check (below)

Iteration 3 — final confirming pass over the whole unit at 2463017f: fact-check k=3 merged most-severe-wins (`code-fact-check-report-2026-10-15-rebuild-hint-final.md`; replicates `-final-r1/-r2/-r3.md`), security (`security-review-2026-10-15-rebuild-hint-final.md`), api-consistency (`api-consistency-review-2026-10-15-rebuild-hint-final.md`), Stage 2.5 submitted claims (`code-fact-check-submitted-claims-2026-10-15-rebuild-hint.md`, 4/4 Verified, executed). Narrow check of 756c11f9: `code-fact-check-report-2026-10-15-rebuild-hint-narrow.md` (k=1; 19 Verified, 1 Mostly accurate on the C4 row's provenance case, tightened in the record commit).
Iteration 2 (k=1, loop pass, cb56299c..980a9db4): `code-fact-check-report-2026-10-15-rebuild-hint-i2.md`, `security-review-2026-10-15-rebuild-hint-i2.md`, `api-consistency-review-2026-10-15-rebuild-hint-i2.md`. Iteration 1 (k=1, loop pass, 9660d4f6..cb56299c): `code-fact-check-report-2026-10-15-rebuild-hint.md`, `security-review-2026-10-15-rebuild-hint.md`, `api-consistency-review-2026-10-15-rebuild-hint.md`. Delivery mode: inline-diff-only (agents read skill files and enclosing files from the worktree themselves).

Review converged in 3 iterations; 0 Must Fix resolved, 13 Must Address resolved or acknowledged (10 fixed or corrected, 1 deferred with a revisit trigger, 2 Accepted-immutable/corrected commit bodies).

---

## 🔴 Must Fix

None.

---

## 🟡 Must Address

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | The copyable hint line ends in `# the supported path: ...`. Interactive zsh without `interactivecomments` passes those words as arguments, and `main()` keeps the last positional, so step 2 retargets to `./launches` (executed). Pre-existing form (old line ended `re-launches`). `devcontainer-config/cc-isolated.sh:564`, parser `:753` | Security | Medium | security-reviewer #1 | for-author | — | ✅ Fixed (980a9db4) | Explanation moved to its own line; bats pins line 1 to the command alone |
| A2 | Three texts still say a plain launch rebuilds: the unverified-config NOTE ("the container is rebuilt from it", `cc-isolated.sh:877-878`), the header paragraph `--help` prints (`:60-62`, "rebuilds the container"), and `guides/cc-isolated-usage.md:955` ("The launch rebuilds and verifies"). False in the fail-closed state (no receipt, matching hash, container reused); the NOTE and the new hint contradict each other in one run (executed) | API / Docs | Incorrect (high), message text → 🟡 under T; Inconsistent | Fact-check claim 6 + api-consistency F1 | for-author | A4 (this unit is its follow-up) | ✅ Fixed (980a9db4) | NOTE, header and guide :955 now say "recreated if it was built from another config"; fail-closed launch test asserts it |
| A3 | `cc-isolated --help` says `(re)build WS from the blessed config` (`cc-isolated.sh:13`); the guide's copy (`cc-isolated-usage.md:25`) now says RECREATE | API | Inconsistent | api-consistency F2 | for-author | C5 | ✅ Fixed (980a9db4) | --help says recreate |
| A4 | Commit cb56299c's Notes: the guide row quotes "Blessed config changed ... rebuilding" only up to "rebuilding" (not verbatim), and the next-launch recreate is caused by the blessed-hash change, not by init-firewall.sh being baked (fact-check claims 17, 18) | Docs (commit) | Mostly accurate | Fact-check | for-author | — | ✅ Corrected in 980a9db4's body | Local merge keeps history |
| A5 | The rebuild_hint test comment and 980a9db4's A1 paragraph overstate the zsh outcome ("retargeting the launch"): usually step 2 fails with "not a directory: launches"; it launches another repo only if that word names a git repo in the cwd (`test/cc-isolated-functions.bats:357-358`) | Docs | Mostly accurate | Fact-check i2 claims 9, 14 + security i2 #2 | for-author | — | ✅ Fixed (iteration-2 fix commit; body corrects 980a9db4) | — |
| A6 | 980a9db4's body calls the bless_manifest "Next:" line (`cc-isolated.sh:317`) the `--list` line | Docs (commit) | Mostly accurate | Fact-check i2 claim 16 | for-author | — | ✅ Corrected in the iteration-2 fix commit's body | — |
| A7 | Sibling copyable lines still end in `# ...` (same mechanism as A1, `<repo>` placeholder): `init-firewall.sh:349-350` (printed on the same fail-closed path; `./session` as a git repo would launch it), `cc-isolated.sh:317` (reaches only `--probe-only`), `install.sh:613-616` | Security / API | Medium (floor rule); Minor | security i2 #1 + api-consistency i2 F1 | for-author | — | ✅ Fixed for init-firewall.sh and cc-isolated.sh:317; install.sh deferred | install.sh's "Next steps" block is a list of placeholder commands with `#` notes, printed once at install; its `--probe-only` row also says "rebuilds". Revisit trigger: the next edit to install.sh's "Next steps" block, or a user report of a stray workspace argument; logged in override-log.md. Closing the class (main() rejecting a second positional) is a behaviour change, asked as a question in this unit's report |
| A8 | Final pass, fact-check wording (claims 3-12): test comment on the stray zsh word too narrow (a directory inside any git work tree launches that tree); stale "never start claude" test comment; 980a9db4 A2 overstated the NOTE test; --help omitted "on a pass"; C4 override row too narrow (plain launches loop too) and cited stale lines; "(cached image layers are reused)" unverifiable in a test comment | Docs / tests | Mostly accurate; Unverifiable | Fact-check final (k=3) | for-author | — | ✅ Fixed (756c11f9; C4 row tightened again after the narrow check) | — |
| A9 | Commit bodies: cb56299c Notes (verbatim quote, recreate cause), 980a9db4 Notes (C4 "already deferred"), 980a9db4/2463017f zsh-outcome wording, 980a9db4 "a test matches rebuilding" | Docs (commit) | Incorrect (high, commit body → 🟡 under T); Mostly accurate | Fact-check final claims 1, 2, 6, 9, 10 | for-author | — | ✅ Corrected in later bodies (980a9db4, 2463017f, 756c11f9); claim 1 logged Accepted-immutable in override-log.md | Local merge keeps history |

---

## 🟢 Consider

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | `--bless`/`--list` "Next:" line describes `--probe-only` as "rebuilds from it" (`cc-isolated.sh:316`) | api-consistency F3 | Minor | for-author | — | Fixed (980a9db4) |
| C2 | `guides/cc-isolated-usage.md:841` "it always rebuilds first" (means recreates) | api-consistency F4, fact-check claim 10 | Minor | for-author | C5 | Fixed (980a9db4) |
| C3 | No test pins `--probe-only`'s non-zero exit on a failed probe, which the `&&` relies on | security-reviewer #2 | Informational | for-author | — | Fixed (980a9db4); its can't-fail "no claude" assertion removed in iteration 2 (fact-check i2, security i2 #2) |
| C4 | Hint printed by a provenance/config-identity failure during a `--probe-only` run points back at `--probe-only`; the cause is the build (e.g. a shadowing `.devcontainer/Dockerfile`), so repeating loops. Pre-existing | fact-check claim 3, security #3, api-consistency F6 | Informational | for-author | — | Deferred: revisit trigger "a user reports a --probe-only loop on a provenance or config-identity failure, or the next change to probe_boundary's failure messages"; logged in override-log.md |
| C5 | init-firewall.sh prints the recipe as two lines without `&&`; safe because the plain launch re-probes | api-consistency F5 | Informational | for-orchestrator-synthesis | — | Won't-Fix (the plain launch re-probes) |
| C6 | Bats test name "--probe-only always rebuilds before probing" | api-consistency F7 | Informational | for-author | — | Fixed (980a9db4) |
| C7 | The NOTE under `--probe-only` describes only the conditional recreate, though that path always recreates (true, understated) | api-consistency i2 F2 | Informational | for-author | — | Won't-Fix (nothing false; the header states it) |
| C8 | The hint's explanation line has the by-hand continuation's indent; pasted along, it is "command not found: the" | api-consistency i2 F3, security i2 | Informational | for-orchestrator-synthesis | — | Won't-Fix (harmless, executed) |
| C9 | `--help` line :13 grew to 99 columns | api-consistency i2 F4 | Informational | for-author | — | Fixed (iteration-2 fix commit, rewrapped) |
| C11 | No test pinned the bless "Next:" line's layout | api-consistency final #1 | Informational | for-author | — | Fixed (756c11f9) |
| C12 | `--help` paragraph leaves a 66-column line (:64) | api-consistency final #3 | Informational | for-author | — | Won't-Fix (cosmetic) |
| C13 | init-firewall prints the recipe as two lines, not an `&&` line; pasting both runs step 2 after a failed step 1 | security final #1 | Informational | for-author | — | Won't-Fix (step 2 is a plain launch that re-probes; claude never starts on a failed probe) |
| C10 | A launch prints "rebuilding it." (:903) after a NOTE that says "recreated" | api-consistency i2 F5 | Informational | for-author | — | Won't-Fix (a guide row and a test match the line; carried from iteration 1) |

---

## ↩️ Considered Overrides

| Override (PR ref / Date) | Prior finding | Original → Override | Reason | This run's treatment |
|---|---|---|---|---|
| `fix/doc-drift-cycle1` / 2026-10-15 (A4) | rebuild_hint's first line contradicts the guides' two-step recipe | 🟡 Must Address → Defer | brief put scripts out of scope | Resolved by this unit (cb56299c); its revisit trigger fired. |
| `fix/doc-drift-cycle1` / 2026-10-15 (C4) | init-firewall.sh "rebuilds" at :346, :349 | 🟢 Consider → Defer | script out of scope | Resolved by this unit (cb56299c). |
| `fix/doc-drift-cycle1` / 2026-10-15 (C5) | cc-isolated-usage.md :25 and "which rebuilds with both set"; comment at cc-isolated.sh:883 | 🟢 Consider → Defer | outside the brief's lines | Resolved by this unit (cb56299c); A3/C2 extend it. |
| `fix/doc-drift-cycle1` / 2026-10-15 (security i2 #2) | no refresh path for the cached CC layer | 🟢 Consider → Defer | launcher change out of scope | Inherited, not re-flagged; out of this unit's scope too. |

---

## ✅ Confirmed Good

| Item | Verdict | Evidence | Source | Legibility-target |
|---|---|---|---|---|
| In the fail-closed state a plain launch reuses the container: no `--remove-existing-container`, no `claude`, exit non-zero, hint printed | ✅ Confirmed | `cc-isolated.sh:893-900` "if ! container_config_matches"; FC claim 1 (executed: stubbed launch log) | code-fact-check | for-orchestrator-synthesis |
| The three new/tightened tests fail on the 9660d4f6 scripts and pass on cb56299c | ✅ Confirmed | FC claim 19 (executed: tests 27, 102, 289 fail on old scripts; 289/289 pass on new) | code-fact-check | for-orchestrator-synthesis |
| The diff (9660d4f6..2463017f) changes no non-comment, non-echo line in either enforcement script | ✅ Confirmed | Submitted claim 15 (executed: 48 changed lines, filter leaves none, all read) | code-fact-check (security endorsement) | for-orchestrator-synthesis |
| `--probe-only` exits non-zero and writes no receipt on a failed probe, so the hint's `&&` never runs step 2 after one | ✅ Confirmed | Submitted claim 14 (executed; mutant `probe_boundary \|\| true` caught by the test) — `cc-isolated.sh:895` "probe_boundary \"$ws\"" | code-fact-check (security endorsement) | for-orchestrator-synthesis |
| The printed recipe passes a workspace path with space, `$(...)`, newline or `!` as one unexecuted argument in bash and zsh | ✅ Confirmed | Submitted claim 13 (executed: real rebuild_hint line 1, `bash -c`, `zsh -fc`, `zsh -fi`; scope excludes the user's own zsh options and fish) | code-fact-check (security endorsement) | for-orchestrator-synthesis |

---

## ⚠️ Unverified Findings

All findings' evidence resolved.

---

## ⏭️ Skipped Core Critics

| Critic | Reason | Signal |
|---|---|---|
| performance-reviewer (all three iterations) | No fact-check claim or diff hunk in its domain | `git diff --stat`: echo text, comments, guide prose, bats assertions and one stub case arm; no loop, query or dependency |

---

## 🧩 Composition check

| Cluster | File / lines | Fragments | Disposition |
|---|---|---|---|
| 1 | `cc-isolated.sh:557-571` | A1, C3, FC 2/3 | distinct defects: A1 is the copyable line's trailing comment, C3 a missing test of the exit status, FC 3 a pre-existing wrong remedy for build failures |
| 2 | `cc-isolated.sh:665-687` | C4 (FC 3, security #3, api F6) | distinct defects: one pre-existing issue reported three times, already one row |
| 3 | `cc-isolated.sh:875-880` / guide `:955` | A2 (FC 6, api F1) | distinct defects: one wording defect already stated in full by both sources |

---

To pass review: all 🔴 items must be resolved. All 🟡 items must be either fixed or
carry a qualifying author note (a discoverable TODO or a concrete revisit trigger; see
"Qualifying author note" in `skills/code-review/references/rubric.md`). 🟢 items are optional.
