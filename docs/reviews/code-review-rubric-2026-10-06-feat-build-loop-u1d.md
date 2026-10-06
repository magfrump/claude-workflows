Commit: 83cdb005
# Code Review Rubric

**Scope:** full branch `main...feat/build-loop-u1d` (one commit, 83cdb005; 5 files, 97+/21−, 118 changed code lines by pr-prep 1a) | **Reviewed:** 2026-10-06 | **Status: 🟡 CONDITIONAL PASS** — 11 amber item(s) awaiting resolution or justification

## Iteration 1 (Commit 83cdb005, full panel, not a loop pass)

Reports (all `Commit: 83cdb005`):
- `code-fact-check-report-build-loop-u1d.md`: merged, k=3. 29 claims: 18 Verified, 9 Mostly accurate, 2 Incorrect. Claims 26-29 are the Stage 2.5 submitted claims. Replicates `-r1/-r2/-r3`. Agreement 62.5% (15/24).
- `code-fact-check-submitted-claims-build-loop-u1d.md`: 4 claims, 4 Verified (executed).
- `security-reviewer-review-2026-10-06-build-loop-u1d.md`: 1 Low, 2 Informational, all outside the diff or for U2.
- `performance-reviewer-review-2026-10-06-build-loop-u1d.md`: 3 Informational (measured).
- `api-consistency-reviewer-review-2026-10-06-build-loop-u1d.md`: 3 Minor, 3 Informational.
- `architecture-review-review-2026-10-06-build-loop-u1d.md`: 1 Minor, 2 Informational.
- `test-strategy-review-2026-10-06-build-loop-u1d.md`: G1-G12 and a checked patch (`.../scratchpad/review-u1d/test/proposed.diff`).

Tests at 83cdb005 (orchestrator run): build-loop-read.bats 19/19, dev-cycle.bats 73/73.

Delivery mode: inline-diff-only (the enclosing files total ~206 KB). Deviation, as in U1c iterations 3-4: agents read the skill file and the shared block (`.../scratchpad/review-u1d/orch/shared.md`) from disk, not pasted. Fact-Check Gate: the 2 high-confidence Incorrect verdicts are on test comments and titles (doc-class, 🟡 under tier policy T), so the run continued to Stage 2. The user is away, and the gate's Continue option loses nothing.

---

## 🔴 Must Fix

None.

---

## 🟡 Must Address

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | The --status U1d test title says "F31's open-only filter" and its step offers a done brief sharing o's branch, but git grep never lists that brief, so the loop's filter (`build-loop.sh:315`) is never reached. Mutant m7, with the filter removed, passes the whole suite. Fix: give brief d a later `Status: open` line (test-strategy R2). | Tests | Incorrect (high), doc-class | Fact-check Claim 17 (r2; r1/r3 Mostly accurate) + test-strategy G2 | for-author | row 291 (C18): still open | ✅ Fixed (6c83af2a) | — |
| A2 | The CRLF step's comment says "the queried brief keeps its own Dispatched value whatever F31 read", but that step asserts a skip line, and p's Dispatched line was overwritten. The property is asserted only at `build-loop-read.bats:454-457`. | Tests | Incorrect (high), doc-class | Fact-check Claim 18 | for-author | — | ✅ Fixed (6c83af2a) | — |
| A3 | `build-loop.sh:17-18`: "a never list hidden in markup, with no exact never line beside it, turns it off" implies an exact line rescues self-merge for any markup copy. That holds only when the markup hides the copy from the count. A counted copy (`**Self-merge never:**`) plus an exact line makes two copies, so self-merge stays off. It fails closed. | Docs | Mostly accurate / Minor | Fact-check Claim 1 (3/3) + api F4. Convergence: fact-check + api-consistency | for-author | row 278 (A25): landed as asked; the residue is the asked wording itself | ✅ Fixed (6c83af2a) | — |
| A4 | `build-loop.sh:68-72`: adding "or the open briefs on main could not be listed" put an "or" inside the "for an open brief" clause, so the marker skip reads as open-only. The code applies it to done briefs too. Move the open-only clauses last. | Docs | Mostly accurate / Minor | Fact-check Claim 3 (r3) + api F3. Convergence | for-author | row 303 (A24, C37): landed; residue | ✅ Fixed (6c83af2a) | — |
| A5 | `build-loop.sh:309`: "A brief git grep cannot read is not counted" holds for a missing object (warns, exits 0/1). A corrupt object exits 128 and fails closed for every open brief. Say "a brief whose object is missing". | Docs | Mostly accurate | Fact-check Claim 7 (r2) | for-author | row 303 (A25) | ✅ Fixed (6c83af2a) | — |
| A6 | `build-loop-read.bats:420`: "A caller's own GIT_CONFIG_COUNT pairs stay" is not asserted; a mutant that overwrites the caller's pair survives. Assert it (test-strategy R6) or reword. | Tests | Mostly accurate | Fact-check Claim 14 (3/3) + test-strategy G10 | for-author | row 279 | ✅ Fixed (6c83af2a) | — |
| A7 | `build-loop-read.bats:428`: the --help test title says "the whole header", but it checks only the first and last lines. It also never runs `-h`, which row 246 named (test-strategy G4). | Tests | Mostly accurate | Fact-check Claims 15, 24 + api F6 + test-strategy G4 | for-author | row 246 (-h): open | ✅ Fixed (6c83af2a) | — |
| A8 | `build-loop-read.bats:436`: the "no open brief (git grep exits 1)" step cannot catch exit 1 being treated as an error. Done briefs never consult SHARED_BRANCHES, and with exit 1 there is no open brief to query, so it is unobservable through --status. Reword the comment, which already holds for "a done brief reads normally". | Tests | Mostly accurate | Fact-check Claim 16 | for-author | row 299 | ✅ Fixed (6c83af2a) | — |
| A9 | `dev-cycle.bats:1328`: the title's "before any read" is not asserted; a mutant that checks pathform after ls-tree passes. Retitle "main_entry answers error for a path pathform refuses". | Tests | Mostly accurate | Fact-check Claim 21 (3/3) + test-strategy G11 | for-author | row 284 | ✅ Fixed (6c83af2a) | — |
| A10 | The commit's Tests bullet counts C26 (row 246) as resolved. The slots line for an *unread* file and `-h` are still untested (a mutant on the unread slots line survives). | Tests | Mostly accurate | Fact-check Claim 24 + test-strategy G3, G4 | for-author | rows 246, 295 | ✅ Fixed (6c83af2a) | — |
| A11 | Row 291's C17 NUL refusal is still open: `marker_kind`'s commit-NUL check (`build-loop.sh:284`) can be deleted with the suite green, and `handoff: ready\n\n\0x` then reads `ready`. The U1d NUL step tests FENCE_AWK's brief-file NUL, which dev-cycle.bats:1223 already covered. The commit's Wording/Tests bullets present row 291 as closed. | Tests | Mostly accurate (commit claim) | test-strategy G1 (Medium) + fact-check Claim 25 | for-author | row 291 (C17): still open | ✅ Fixed (6c83af2a) | — |

A11's tier: test-strategy is contextual, so its G1 alone is 🟢. The row is 🟡 because the commit message claims row 291 is resolved, which is fact-check Claim 25's Mostly-accurate class.

---

## 🟢 Consider

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | `lib:252-255`: main_entry's list of `error` causes still names three; the pathform cause is a separate sentence. Follow brief_fields' comment pattern. | api F1; fact-check Claim 12 annotation; security F2 | Minor | for-author | row 283 (A22): landed | Fixed |
| C2 | `error` now also means "refused path form", but callers' error arms say "could not be read" (`lib:339`, `:559`, `build-loop.sh:129`). Unreachable today; U2's floor passes changed paths (`.gitattributes`, `.github/x.yml` read `blob` on main, `error` now). Give it its own word (`badform`) or document form-first. | architecture F1; api F2; security F2 | Minor | for-author | row 228 (shared mapping, trigger U2) | Deferred |
| C3 | Out of the diff: under a broken git config (`grep.patternType bogus`, `log.date bogus`), `git log` fails inside echo's arguments and inside `$(...)` in check_branch (`lib:382`) and marker_kind (`build-loop.sh:282`). A valid `ready` tip reads `working`, a malformed marker reads `ok … working` instead of skipping, and DATE goes missing. That breaks the header contract that a non-positive line is a refusal. Nothing moves toward merge (Low). Mechanism corrected from the fact-check escalation: `rev-list` works, `git log` fails. | security F1 (executed); fact-check escalation (r3) | Low | for-author | — | Deferred |
| C4 | U2 must treat main_entry `error` as a refusal of that path, never `continue` past it as shared_branches does for unreadable briefs. Run pathform first with a reason that does not echo the name (F17). | security F2 | Informational | for-author | — | Deferred |
| C5 | pathform now runs twice per brief (`lib:296`, `:327` and `:263`); +33 µs per call, wall +1.6% (noise). The `:296` check is now redundant (Claim 29 Verified, executed). `:327` must stay for its specific reason. | performance F1; architecture F2 | Informational | for-author | — | Won't-Fix |
| C6 | U2's --check will cost ~2 ms per changed path (ls-tree + subshell). One ls-tree for all paths, if diffs get large. | performance F2 | Informational | for-author | row 220 (trigger: U2's floor per changed path) | Deferred |
| C7 | The two scripts' help-range comments describe the same sed command in different words (`build-loop.sh:99`, `dev-cycle.sh:111`). | api F5 | Informational | for-author | — | Fixed |
| C8 | `lib:22-24`: the resolve_main sentence names only three functions; main_entry and brief_fields also refuse without it (pre-existing). | architecture F3 | Informational | for-author | — | Fixed |
| C9 | Test gaps G5-G9: a bare `success:` line (row 291), 1-char stopped reason, `Dispatched: 0`/`99`, fenced `H2:` (row 299's C19 trio), tab-only blank line. All in test-strategy's checked patch. | test-strategy G5-G9 | Low/Medium | for-author | rows 291, 299 | Fixed |
| C10 | `build-loop.sh:113` `GIT_NO_REPLACE_OBJECTS=1` can be dropped with no test failing (the config pair carries the guard). | Stage 2.5 Claim 28 residue | Informational | for-author | rows 276, 281 (trigger U3b) | Deferred |
| C11 | Dropping only the local `BRIEF=()` is unobservable through the CLI; a lib-level test belongs with U2's in-process calls. | test-strategy G12 | Low | for-orchestrator-synthesis | row 304 | Deferred |
| C12 | The four new tests add ~0.72 s (~3% of the suite). | performance F3 | Informational | for-orchestrator-synthesis | — | Won't-Fix |

---

## ↩️ Considered Overrides

| Override (PR ref / Date) | Prior finding | Original → Override | Reason | This run's treatment |
|---|---|---|---|---|
| `feat/build-loop-u1b` / 2026-10-05 (row 246) | Test gaps: glob-form and "twice" reasons, review with malformed never, slots line for an absent or unread file, `-h` | 🟢 → Defer (U1c/U2) | Unit at cap | Partly closed: reasons, review and absent landed; unread slots and `-h` still open → A7, A10. |
| `feat/build-loop-u1b` / 2026-10-05 (row 278) | Never-line, NEXT and help-range wording (A25-A27) | 🟡 → Defer (U1c next fix) | U1b loop closed | Landed as asked. The A25 wording is itself imprecise → A3. |
| `feat/build-loop-u1b` / 2026-10-05 (row 279) | GIT_CONFIG_COUNT test, fence half, whitespace-only line | 🟢 → Defer | — | Guard half and fence half closed; "pairs stay" unasserted → A6; tab-only → C9. |
| `feat/build-loop-u1a` / 2026-10-05 (row 283) | Test title, "until committed", help-range comment, main_entry comment (A19-A22) | 🟡 → Defer | U1a loop closed | Landed (fact-check Claims 9, 10, 12, 20). |
| `feat/build-loop-u1a` / 2026-10-05 (row 284) | main_entry does not run pathform itself | 🟢 → Defer | — | Closed (Claims 12, 26, 27). Title overclaims "before any read" → A9. |
| `feat/build-loop-u1a` / 2026-10-05 (row 287) | Lib header's pipefail note | 🟢 → Defer | — | Closed (Claim 11). |
| `feat/build-loop-u1c` / 2026-10-05 (row 291) | NUL refusal and F31 open-only filter untested | 🟢 → Defer (U1d) | Size cap | **Departs: still open.** Both gaps survive mutants → A1, A11. |
| `feat/build-loop-u1c` / 2026-10-05 (row 295) | Row 246's G7-G11 | 🟢 → Defer (U1d) | — | As row 246 → A7, A10. |
| `feat/build-loop-u1c` / 2026-10-05 (row 297) | Re-pointing U1a/U1b deferrals to U1d | 🟡 → Defer | — | Honoured: all re-pointed items appear in 83cdb005; residues above. |
| `feat/build-loop-u1c` / 2026-10-05 (row 299) | No open brief, CRLF arm, C19 G5-G7 | 🟢 → Defer | — | No-open-brief and CRLF landed (A8 wording residue); C19 trio still open → C9. |
| `feat/build-loop-u1c` / 2026-10-05 (row 303) | Skip-clause wording, F31 comment, help skip list, "(git grep failed)" | 🟡 → Defer | U1c loop ended | Landed; the new clause's placement → A4; the row-293 sentence → A5. |
| `feat/build-loop-u1c` / 2026-10-05 (row 304) | No regression tests for C29/C30 | 🟢 → Defer | — | Closed for the moved-call and closed/ mutants (Claim 22); local-only residue → C11. |

---

## ✅ Confirmed Good

| Item | Verdict | Evidence | Source | Legibility-target |
|---|---|---|---|---|
| main_entry's guard changes no current caller's output | ✅ Confirmed | `scripts/lib/dev-cycle-read.sh:263` — "if ! main_by_name \|\| ! pathform "$1"; then echo error; return; fi". Enumeration `rg main_entry scripts/` → brief_fields (:296, pathform first), check_brief (:327 before :334), check_answer (fixed names), main_file (fixed names); all four fixed names pass pathform. FC Claims 12 and 26 (executed) | fact-check + security | for-orchestrator-synthesis |
| The guard closes a fail-open for quoted names: `docs/é.md`, `docs/a*` and `:(top)…` read `absent` on main's lib and `error` at 83cdb005 | ✅ Confirmed | `scripts/lib/dev-cycle-read.sh:263`; security F2 probe (executed). Scoped to those three inputs | security | for-orchestrator-synthesis |
| The main_entry test fails if the guard is removed | ✅ Confirmed | `test/scripts/dev-cycle.bats:1328`; FC Claim 27 (executed: `absent/error/absent/absent`) | Stage 2.5 | for-orchestrator-synthesis |
| The GIT_CONFIG_COUNT step fails if the replace-ref config pair is lost | ✅ Confirmed | `test/scripts/build-loop-read.bats:425`; FC Claim 28 (executed, three mutants). Scope: the config pair, not line 113 (C10) | Stage 2.5 | for-orchestrator-synthesis |
| NEXT comment matches the awk (fences, space/tab lines, EOF) | ✅ Confirmed | `scripts/build-loop.sh:143-145`; FC Claim 5 (executed, 3/3) | fact-check | for-orchestrator-synthesis |
| Both help-range comments match the sed | ✅ Confirmed | `scripts/build-loop.sh:99`, `scripts/dev-cycle.sh:111`; FC Claims 4, 10 (executed) | fact-check | for-orchestrator-synthesis |

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
| 1 | `scripts/build-loop.sh:16-18` | FC1, api F4 | distinct defects: not composed; both state the same mechanism completely (convergence on A3) |
| 2 | `scripts/build-loop.sh:64-72` | FC3, api F3 | distinct defects: same as cluster 1 (A4) |
| 3 | `scripts/lib/dev-cycle-read.sh:251-263` | FC12 annotation, api F1, api F2, arch F1, security F2 | distinct defects: the comment list (C1) and the error-word conflation (C2) each state their own mechanism and fix; security F2 is the U2 consumer rule (C4) |
| 4 | `test/scripts/build-loop-read.bats:434-461` | FC16, FC17, FC18, FC19, test G1/G2/G12 | distinct defects: each step's gap is stated with its own mutant |

---

To pass review: all 🔴 items must be resolved. All 🟡 items must be either fixed or carry a qualifying author note (a discoverable TODO or a concrete revisit trigger; see "Qualifying author note" in `skills/code-review/references/rubric.md`). 🟢 items are optional.
