Commit: 2da477b7
Loop-pass short-circuit: used at c8435580
# Code Review Rubric

**Scope:** `main...feat/build-loop-u1a` (full branch: d6426e3e, c8435580, 2da477b7; 312 changed lines outside `docs/`), iteration 2, final confirming full-panel pass (no `--loop-pass`, k=3) | **Reviewed:** 2026-10-05 | **Status: 🔴 DOES NOT PASS** — 1 red item(s) unresolved

Reports: `code-fact-check-report-build-loop-u1a.md` (merged k=3 from `-r1/-r2/-r3.md`, plus Stage 2.5's `code-fact-check-submitted-claims-build-loop-u1a.md` appended as claims 44-52), `security-reviewer-review-2026-10-05-build-loop-u1a.md`, `performance-reviewer-review-2026-10-05-build-loop-u1a.md`, `api-consistency-reviewer-review-2026-10-05-build-loop-u1a.md`, `architecture-review-review-2026-10-05-build-loop-u1a.md`. bats `test/scripts/dev-cycle.bats` 66/66 at 2da477b7. Delivery mode: inline-diff-only via a shared file (diff 31 KB in budget; enclosing files ~166 KB over). Deviation from the skill, as in iteration 1: agents read their skill files and the shared block from disk instead of having them pasted. Fact-Check Gate: high-confidence Incorrects existed (claims 23, 37, test comment and commit message); the caller asked for the full panel, so the pass continued.

---

## 🔴 Must Fix

| # | Finding | Domain | Severity | Source | Location | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|---|---|
| R1 | (iteration 1) brief_fields captured awk's output through `$(...)`, which drops NUL bytes, so `Status: op<NUL>en` read as `open` | Correctness / input handling | Incorrect (high), behavioral, executed | Fact-check | `scripts/lib/dev-cycle-read.sh:216` (fix), `:286` | for-author | — | ✅ Resolved at 2da477b7: FENCE_AWK refuses any NUL line (`if (index(l, "\0")) { refuse("nul"); return 1 }`); test 64 passes at HEAD and fails against c8435580's lib (all 3 replicates, executed); values come back byte-identical for bytes 0x01-0xFF except LF/CR (r1, r2 executed). The `:264-265` "whole" comment that a fix-drift lite review called contradicted by R1 now reads (`:275-277`) "a NUL byte is refused too, so each value is the line as stored": verified by execution, Mostly accurate only for the documented trailing-CR drop (A7). |
| R2 | A failed `git cat-file` is swallowed by both main readers. check_answer's `r="$(git cat-file blob "$MAIN_SHA:$f" \| … awk …)"` followed by `[[ -n "$r" ]] \|\| continue`: under the lib header's own `out="$(check_answer …)"` pattern errexit is off, so when questions.md's blob cannot be read the reader moves on to the archive and the "entry … in both" refusal never fires: Q-1 OPEN in questions.md + ANSWERED [1] in the archive, questions.md's blob deleted → `keep Q-1` instead of a skip (fail-open on the answer U3's `--approved` will read). brief_fields' `out="$(git cat-file … \| awk …)"` under `if !` returns 0 with no keys and empty BRIEF_ODD, indistinguishable from a brief with no machine lines (check_brief still fails closed, with a wrong reason). Fix (security): test the assignment, `r="$(…)" \|\| { echo "skip $a: $f could not be read from the default branch"; return; }` and `out="$(…)" \|\| { BRIEF=(); BRIEF_ODD=error; return 1; }` with an `error)` arm in check_brief; add a bats case deleting a blob. **Convergence:** security + architecture + api-consistency (+ fact-check escalation 3). **Escalated 🟡 → 🔴** under the Escalation Rule: corroboration is executed evidence (security repro; orchestrator re-run 2026-10-05T11:16:47Z in `review-u1a-i2/orch/`: intact → `skip Q-1: an entry with this heading in both …`, blob missing → `fatal: … bad file` then `out=[keep Q-1]`, exit 0; api and architecture each executed the brief_fields half: `rc=0 keys=0 odd=[]`) | Security / error handling | security Medium · architecture Coupling · api-consistency Minor (escalated) | security-reviewer F2 + architecture F1 + api-consistency F1, Escalation Rule (executed) | `scripts/lib/dev-cycle-read.sh:547-548` (check_answer), `:286-299` (brief_fields) | for-author | Related: row 216 (U1's check_answer should accept only a positive line; `--approved` reads it); row 215 (three guard channels) | 🔴 Unresolved |

---

## 🟡 Must Address

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | (iteration 1) NUL bytes dropped from BRIEF values reaching U1b consumers (`scripts/lib/dev-cycle-read.sh:279-292`) | Security | Unrouted-Escalation | fact-check escalation | for-author | — | ✅ Resolved at 2da477b7 | Subsumed by R1's fix; claim 48 (executed): both FENCE_AWK readers refuse NUL at line start, mid-file, in a fence, on an unterminated last line. |
| A2 | (iteration 1) main_entry printed `absent` when ls-tree failed, and check_brief read it as `ok … new` (`:255`) | Security / API | Unrouted-Escalation | fact-check escalation | for-author | Row 208 (different failure) | ✅ Resolved at 2da477b7 | main_entry prints `error` for no default branch by name, unset MAIN_BY_NAME, unknown/short/blob SHA (ls-tree exit 128); both callers skip, no other caller (claims 14, 47 executed). |
| A3 | (iteration 1) main_entry's ls-tree lists each named directory's children (`:255`) | Performance | Unrouted-Escalation | fact-check escalation | for-author | Row 220 | ✅ Resolved (Won't-Fix) | Override row 220: 49 entries re-measured by r1/r3; revisit trigger there (docs/ with thousands of entries, or U2's floor calling it per changed path). |
| A4 | (iteration 1, **still open**) test 63's `skipped=0` assertion cannot fail. The second `check_answer` runs after `cd docs` with ROOT_REAL unset, so a working-tree reader finds no `docs/docs/working/…` paths; two SKIPPED-appending mutants of HEAD's check_answer pass the test (r1, executed). The test fails against main's reader only at need_root, with or without the symlink. So the comment "# A symlinked archive on main: the working-tree reader added it to SKIPPED." (`test/scripts/dev-cycle.bats:1163`) and 2da477b7's A4 bullet are Incorrect (claims 23, 37; high, executed, r1; r2/r3 Verified, but r2's probe set ROOT_REAL, which the test does not). Fix: make the call from the root with ROOT_REAL set (or assert with a mutant-style check), and correct the comment | Tests | Incorrect (high) on a test comment and commit message, executed (→ 🟡 under decision 031) | Fact-check (claims 23, 37) | for-author | Row 217 (the SKIPPED side effect it is meant to prove gone) | 🟡 Open | — |
| A5 | Lib header "A change here runs under both callers' suites (test/scripts/dev-cycle.bats, and build-loop.sh's suites …)" while only one caller exists (`scripts/lib/dev-cycle-read.sh:10-12`) | Docs | Mostly accurate | Fact-check (claim 6, r1) | for-author | Row 197 | 🟡 Open | — |
| A6 | FENCE_AWK header lists the NUL byte (and CR, BOM) under "outside a fence", but fence() refuses them anywhere, inside fences too (`odd 2 nul` between fence lines) (`scripts/lib/dev-cycle-read.sh:174-176`) | Docs | Mostly accurate | Fact-check (claim 10, r2) | for-author | — | 🟡 Open | — |
| A7 | brief_fields comment: "each value is the line as stored" omits the one dropped trailing CR (stated earlier in the same comment), and the NUL clause sits inside the "unbalanced N" parenthetical though it concerns `odd N nul` (`scripts/lib/dev-cycle-read.sh:275-277`) | Docs | Mostly accurate | Fact-check (claim 17, r3) | for-author | — | 🟡 Open | — |
| A8 | SKILL.md keeps "once step 1 has archived an entry, `questions-archive.md`", which no longer matches: an entry archived this cycle is still read from main's questions.md until the cycle lands, and main's archive is read whenever it exists there (`skills/dev-cycle/SKILL.md:292-293`) | Docs | Mostly accurate | Fact-check (claim 21, r2) | for-author | — | 🟡 Open | — |
| A9 | Test 65 "a brief written from the skill's template parses … (T31)" and 2da477b7's T31 bullet: the fixture copies real briefs (Date line) and has no Motive section, which the template lists; it still parses (`test/scripts/dev-cycle.bats:1192`) | Tests / docs | Mostly accurate | Fact-check (claims 25, 38) | for-author | Row 221 (T34 parts deferred; T31 separate) | 🟡 Open | — |
| A10 | c8435580's Notes say a working-tree-only answer reads `open`; an entry absent from main reads `skip … no such entry` (both fail closed; help and SKILL.md already fixed) | Docs (commit message) | Mostly accurate | Fact-check (claim 33, r1) | for-author | — | 🟡 Open | Fixable only by rewriting the unmerged branch's history, or by acknowledging it here. |
| A11 | 2da477b7's "every reader skips such a file": only the FENCE_AWK readers do; the digest's questions readers (via `scripts/questions.sh`, `scripts/dev-cycle.sh:263`, `:328-361`, `:382`) list a questions.md holding a NUL instead of skipping it (r3 probe), so the two questions.md parsers now diverge further | Docs / consistency | Mostly accurate | Fact-check (claim 35, r1+r3; escalation 4) · architecture I5 (convergence) | for-author | — | 🟡 Open | — |
| A12 | main_entry keeps the **last** ls-tree line per path (`m["$path"]=…`), while `git cat-file blob SHA:path` resolves the **first**. A duplicate-entry tree listing `120000 questions.md` (symlink blob holding an ANSWERED entry) before `100644 questions.md` gives `entry=blob` and `keep Q-1`: the symlink's target text is read, defeating main_entry's "never a symlink's target text". Such trees come from `hash-object --literally`; `git fsck` flags them, local fast-forward/update-ref/commit-tree do not. Same for brief_fields. Fix: `error` when ls-tree prints a path twice; bats case with a `--literally` tree (security, executed) | Security | Medium | security-reviewer F1 | for-author | Row 208 (different failure) | 🟡 Open | — |
| A13 | brief_fields has three outcomes (read / refused / unreadable) but two signals, and leaves its preconditions (main_by_name, pathform, main_entry == blob) to callers, so each U1b/U3 consumer must copy check_brief's guard block (`:309-333`); with an empty MAIN_SHA it would read the index's copy (`:<path>`, claim 52 residue). Recommendation: brief_fields calls main_entry itself and reports absent/notdir/error through BRIEF_ODD with a non-zero return. Signal half converges with R2 | Architecture | Coupling | architecture-review F1 | for-author | Row 215 (extends, does not contradict) | 🟡 Open | — |

---

## 🟢 Consider

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | --check-answer help gives a closed list of skip reasons and omits the new "the default branch's tree could not be read" (`scripts/dev-cycle.sh:62-70` vs `scripts/lib/dev-cycle-read.sh:544`) | api-consistency-reviewer F2 | Minor | for-author | — | 🟢 Open |
| C2 | `"\0"` in FENCE_AWK assumes an awk whose strings hold NUL: under BWK/one-true-awk or busybox it may be `""` and every non-empty line would be refused as "holds a NUL byte" (fails closed, misleading). No supported platform is affected (the lib already needs GNU realpath and bash 4); optional BEGIN self-check `length("\0") == 1` or a comment naming the assumption (`scripts/lib/dev-cycle-read.sh:216`) | api-consistency-reviewer F3 + fact-check claim 11b (Unverifiable, all three replicates) | Informational / Unverifiable | for-author | — | 🟢 Open |
| C3 | Each caller maps main_entry's words to skip text with its own copied case block, wording already drifting; a `main_why` helper before U1b adds more copies (`:320-326`, `:539-545`) | architecture-review F2 | Minor | for-author | — | 🟢 Open |
| C4 | BRIEF stores whole lines (`Branch: feat/f`) in one global slot; consumers strip the key and copy values before the next call; consider a `brief_value` accessor at the second consumer (`:280`, `:346`) | architecture-review F3 | Informational | for-author | — | 🟢 Open |
| C5 | check_answer reads main's commit while the skill still writes answers to the working tree until U4 (documented, fails closed) (`:528-533`, `SKILL.md:291-294`) | architecture-review F4 | Informational | for-orchestrator-synthesis | Row 206 | 🟢 Open |
| C6 | check_answer re-lists and re-reads both questions files per ID (2 ls-tree, 2 cat-file, 2 awk over ~222 KB); no regression (20 IDs 0.230 s vs 0.242 s on main); forward note for U1c `--status` (`:538-547`) | performance-reviewer F1 | Informational | for-orchestrator-synthesis | Row 201 | 🟢 Open |
| C7 | check_brief ~2 ms more per brief (main_entry subshell + brief_fields loop); identical output (`:320`, `:286-299`) | performance-reviewer F2 | Informational | for-orchestrator-synthesis | Row 213 | 🟢 Open |
| C8 | Untested bypass candidates for main_entry's guard, traced only: a gitlink at the path or a parent, quoting under `core.quotePath`, a `./x` path from a future caller | security-reviewer (untested candidates) | Informational | for-author | — | 🟢 Open |
| C9 | ls-tree's `fatal:` message reaches stderr unscrubbed when main_entry prints `error` | Fact-check (claim 47 residue) | Informational | for-author | — | 🟢 Open |
| C10 | Review tooling: architecture-review's security cross-reference globs `docs/reviews/security-review-*.md`, which misses this initiative's `security-reviewer-review-*.md` (`skills/architecture-review/SKILL.md`) | architecture-review F6 | Informational | for-orchestrator-synthesis | — | 🟢 Open |

---

## ↩️ Considered Overrides

| Override (PR ref / Date) | Prior finding | Original → Override | Reason | This run's treatment |
|---|---|---|---|---|
| `feat/build-loop-u0c` / 2026-10-05 (row 206) | check_answer reads questions.md from the working tree (F28) | 🟢 → Defer to U1 | U1 moves it to main's commit | Discharged (claim 45a executed; claim 51 executed: with the working tree's docs/working at mode 000 it still reads main). |
| `feat/build-loop-u0c` / 2026-10-05 (row 216) | check_answer print-only; U1 should accept only a positive line and add main_by_name | 🟢 → Defer to U1 | Header names the safe capture pattern | Partly discharged (claim 45b Mostly accurate): main_by_name added, no need_root exit; the positive-line part is U3's `--approved`. R2 shows that pattern can return a positive line (`keep`) when questions.md's blob is unreadable. |
| `feat/build-loop-u0c` / 2026-10-05 (row 217) | check_answer appends to SKIPPED | 🟢 → Defer to U1 | U1 rewrites check_answer | Discharged in the code (claim 45a executed); the test meant to prove it still cannot fail (A4). |
| `feat/build-loop-u0a` / 2026-10-05 (row 197) | Lib header lacks the both-suites note | 🟢 → Defer to U1 | U1 adds the suite and the note | Note reworded to "as they land"; still says "both" with one caller (A5). |
| `feat/build-loop-u0a` / 2026-10-05 (row 196) | A test should source the lib from build-loop.sh's side | 🟢 → Defer to U1 | U1's test unit | Not applicable to U1a; still U1b's. |
| `feat/build-loop-u0b` / 2026-10-05 (row 201) | check_brief's `git log -G` walk per brief | 🟢 → Defer to U1 | Measure in U1's `--status` | Inherited; performance measured no regression; C6 adds the per-ID re-read to the same U1c measurement. |
| `feat/build-loop-u0b` / 2026-10-05 (row 208) | main_by_name passes for a MAIN_SHA from another repo | 🟢 → Won't-Fix | No two-repo caller | Inherited; R2 and A12 are different failures (unreadable blob; duplicate tree entries). |
| `feat/build-loop-u0b` / 2026-10-05 (rows 213, 215) | check_brief's need_root fork; three guard channels / U3 must check main_by_name | 🟢 → Won't-Fix / Defer | Small cost; recorded for U3 | Inherited. A13 extends row 215 (brief_fields' preconditions) without contradicting it. |
| `feat/build-loop-u1a` / 2026-10-05 (row 220) | main_entry's ls-tree lists each directory's children | 🟡 → Won't-Fix | 49 entries; per-component calls cost more | Inherited, not re-raised (closes A3). |
| `feat/build-loop-u1a` / 2026-10-05 (row 221) | T34's build-loop.sh side and E2/`--marker` fixture missing | 🟢 → Defer | No answer mode in build-loop.sh until U3 | Inherited, not re-raised. |

---

## ✅ Confirmed Good

| Item | Verdict | Evidence | Source | Legibility-target |
|---|---|---|---|---|
| Under mawk 1.3.4 (the installed awk), FENCE_AWK refuses a line holding a NUL byte anywhere in a file and never refuses a NUL-free line, so the two FENCE_AWK readers (check_brief/brief_fields, check_answer) skip such files | ✅ Confirmed (mawk only; see C2) | `scripts/lib/dev-cycle-read.sh:216` — `if (index(l, "\0")) { refuse("nul"); return 1 }`; FC claim 11a (executed, k=3 unanimous) and claim 48 (executed: line start, mid-file, in a fence, unterminated last line, NUL runs) | Fact-check | for-orchestrator-synthesis |
| main_entry prints `error`, never `absent`, with no default branch by name or a failing ls-tree, and both callers skip on it | ✅ Confirmed | `scripts/lib/dev-cycle-read.sh:259-261` — `main_by_name \|\| { echo error; return; }` … `\|\| { echo error; return; }`; FC claims 14 (executed, k=3) and 47 (executed: unset MAIN_BY_NAME, unknown/short/blob SHA; `rg` finds only the two callers) | Fact-check (submitted by architecture, api-consistency, security) | for-orchestrator-synthesis |
| check_answer reads only `MAIN_SHA:<constant path>` objects, never a working-tree path (scope excludes `refs/replace/` substitution) | ✅ Confirmed | `scripts/lib/dev-cycle-read.sh:547` — `r="$(git cat-file blob "$MAIN_SHA:$f" \| …`; FC claim 51 (executed: working tree's docs/working at mode 000) | Fact-check (submitted by security) | for-orchestrator-synthesis |
| On the repo's three real briefs, the branch's `--check-brief` output is byte-identical to main's, and `--check-brief`/`--check-answer` run within ±15% of main's time | ✅ Confirmed (three open briefs, small sample) | FC claim 44 (executed, 2×15 runs: +2% to +9% / −3% to −4%) | Fact-check (submitted by performance) | for-orchestrator-synthesis |

---

## ⚠️ Unverified Findings

All findings' evidence resolved.

---

## ⏭️ Skipped Core Critics

All core critics ran; no skips applied. (architecture-review auto-selected and ran; no contextual critic selected: the diff has test changes, ≤10 files and ≤500 code lines, no manifests or UI.)

---

## 🧩 Composition check

| Cluster | File / lines | Fragments | Disposition |
|---|---|---|---|
| 1 | `scripts/lib/dev-cycle-read.sh:275-300` (+ `:547`) | FC claim 17 / escalation 3, security F2, api-consistency F1, architecture F1 | distinct defects: security F2 states the full root and fix; recorded as convergence on R2. A7 (comment wording) and A13 (precondition coupling) are separate defects. |
| 2 | `scripts/lib/dev-cycle-read.sh:247-267` | FC claims 13-15, 47 (Verified), security F1 | distinct defects: FC verifies the error path; F1 is duplicate-entry resolution order (A12). |
| 3 | `skills/dev-cycle/SKILL.md:291-294` (+ lib `:528-533`) | FC claim 21, architecture F4, FC claim 50 | distinct defects: A8 is stale wording; C5 is a documented design gap until U4. |

---

To pass review: all 🔴 items must be resolved. All 🟡 items must be either fixed or
carry a qualifying author note (a discoverable TODO or a concrete revisit trigger; see
"Qualifying author note" in `skills/code-review/references/rubric.md`). 🟢 items are optional.
