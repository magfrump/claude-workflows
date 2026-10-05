Commit: 0ae7d801
Loop-pass short-circuit: used at 224dd52d
# Code Review Rubric

**Scope:** full unit range `feat/build-loop-u1a...feat/build-loop-u1b` at 0ae7d801 (unit commits 0797ed32, 224dd52d, 30676e57, 0ae7d801; merge a091d8fa brings in u1a's fix and is context only). 398 changed code lines in 3 new files, plus this loop's review artifacts under `docs/reviews/`. Iteration 2: full panel, not a loop pass, fact-check k=3. | **Reviewed:** 2026-10-05 | **Status: 🔴 DOES NOT PASS** — 2 red item(s) unresolved

Iteration 1 (at 224dd52d) short-circuited at the fact-check; its marker above stays for the rest of the loop. This pass ran every critic.

Reports (all `Commit: 0ae7d801`):
- `code-fact-check-report-build-loop-u1b.md`: merged k=3, with the Stage-2.5 submitted claims appended. Replicates are `-r1.md`, `-r2.md`, `-r3.md`; the submitted-claims pass is `code-fact-check-submitted-claims-build-loop-u1b.md`.
- `security-reviewer-review-2026-10-05-build-loop-u1b.md`, `performance-reviewer-review-2026-10-05-build-loop-u1b.md`, `api-consistency-reviewer-review-2026-10-05-build-loop-u1b.md`
- `architecture-review-review-2026-10-05-build-loop-u1b.md`: auto-selected because the diff adds a new module.
- `test-strategy-review-2026-10-05-build-loop-u1b.md`: included because fact-check escalation E2 names it.

Execution logs are in `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b-i2/<agent>/`, because this pass may write only review reports.

Deviations from the skill:
- Agents read their skill files and the shared context block (`.../review-u1b-i2/shared.md` and `shared-stage2.md`, about 17k tokens each) from disk; the block was not pasted inline.
- The Fact-Check Gate's pause on high-confidence Incorrects was resolved as "Continue", because the caller asked for the full panel.
- tech-debt-triage was not auto-selected: the diff exceeds 500 lines only because of review artifacts, and the code is 398 lines.

---

## Iteration 1 items, checked against 0ae7d801

| # | Iteration-1 finding | Status at 0ae7d801 | Evidence |
|---|---|---|---|
| R1 | A tab separator passed `Self-merge never:` | ✅ Resolved (30676e57) | FC Claim 18 (executed), submitted Claim 43a (executed); security confirms R1/A1 closed. The commit's CR wording is wrong; see A10. |
| A1 | Security escalation, same as R1 | ✅ Resolved | Same as R1. |
| A2 | Rendered copies of a key were hidden, not counted | ⚠️ Partly resolved, still open | Copies with the colon inside the markup are now counted (FC Claim 36). Copies with the colon outside the markup, task items, tables, links, NBSP and wrapped lines are still hidden. Carried as R3 and A5. |
| A3 | The no-echo test discriminated only on `\xc3` | ✅ Resolved | FC Claim 28 (`build-loop-read.bats:114-115` also checks the ASCII entries). The tab-echo residue is C13. |
| A4 | `.github/` made the never line malformed | ✅ Resolved in code (globform, FC Claim 15) | Its regression check at `build-loop-read.bats:126` is no longer enforced; see R2. |
| FC 4c | Header "no .git" understated the rule | ✅ Resolved | Header rewritten, and globform allows `.git*` parts (FC Claims 3, 15). |
| FC 7 | Untrusted-file list needed qualifiers | ✅ Resolved | The header now points at FENCE_AWK's list (FC Claim 6). |
| FC 9 | Scrub note vs the pre-scrub errors | ✅ Resolved | FC Claim 9 Verified. |
| FC 24 | 0797ed32's "never echoed" was weakly tested | ✅ Resolved | The A3 test fix makes it true at HEAD (FC Claims 28, 31). |
| FC 25 | 224dd52d "byte-exact" | ↩️ Override-log row (u1b, Won't-Fix) | Inherited. |
| note | `-h` not in Usage | ✅ Resolved | The Usage line lists `-h \| --help`. |
| note | `-h extra` exits 0 | ↩️ Override-log row (u1b, Won't-Fix) | Inherited. |
| note | No `git log --graph` on failure | ↩️ Override-log row (u1b, Defer to U2) | Inherited. |
| note | `a` and `a/` both pass "none twice" | ✅ Resolved | FC Claim 20 (executed). |
| note | Empty parts refused but not documented | ✅ Resolved | The header now says "no empty, . or .. part" (FC Claim 3). |

---

## 🔴 Must Fix

Issues that must be resolved before merge. Draft cannot pass review with any red items
unresolved.

| # | Finding | Domain | Severity | Source | Location | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|---|---|
| R1 | Iteration 1, above. | — | — | — | — | — | — | ✅ Fixed (30676e57) |
| R2 | The 0ae7d801 refactor turned two guarded pairs into `settings_like A && settings_like B`. When the left operand of a non-final `&&` fails, bats does not fail the test. T4's working-tree policy check (`:80`) and T45's `.github/ .gitignore` check (`:126`, the A4 regression test) therefore never fail. Executed: with A4 reverted (globform swapped for pathform), T45 passes (FC r2 M1, test-strategy m1); with bogus first operands, T4 and T45 pass (FC r1 m4, r3). The commit message's "No assertion was dropped" is false in effect. Fix, 0 lines: change ` && ` to `; ` on both lines, or add `\|\| return 1`. Convergence: fact-check + architecture (M4) + test-strategy (G1); corroborated by execution. | Tests / behavioral | Incorrect (high, executed) | Fact-check (Claim 38; r1, r2 Incorrect, r3 Mostly accurate) + architecture-review M4 + test-strategy G1 | `test/scripts/build-loop-read.bats:80` — `settings_like policy "policy review set:" && settings_like slots "slots 3 default:"`; `:126` — `settings_like never "never .github/ .gitignore set:" && settings_like policy "policy self-merge set:"` | for-author | — | 🔴 Unresolved |
| R3 | The header states a security property the code does not have: a "bold … copy is a second line, not a hidden one". A copy whose markup closes before the colon is not counted: `**Build-loop policy**: review`, `*…*:`, `` `…`: ``, `__…__:`, `**Self-merge never**: b/`, and `**Build-loop slots**: 2`. So an exact `Build-loop policy: self-merge` line wins, with no "more than one line" warning. Commit 30676e57's A2 bullet makes the same claim (FC Claim 34). Executed by r3, security, api-consistency and test-strategy. Security rates the underlying exposure Low: a hidden line can only fail to lower the policy, and loops cannot write `docs/dev-cycle.md` (F12/F56). It stays red because the header documents a fail-closed rationale that U2 would rely on (decision 031). Either fix discharges it: the letters-only key match in A5 (closes this and most of A5), or narrowing the header (and the 30676e57 wording) to "colon inside the markup" and filing the residue. | Security / contract | Incorrect (high, executed); security Low; api Inconsistent | Fact-check (Claims 5b, 34; r3) + security-reviewer F2 + api-consistency F1 + test-strategy G4 | `scripts/build-loop.sh:30-31` — `markers, # * _ \` ~ and byte-order marks, so a quoted, bold,` / `heading or indented copy is a second line, not a hidden one. A`; mechanism `:108` — `if (index(s, "build-loop policy:") == 1) k = "policy"` | for-author | — | 🔴 Unresolved |

---

## 🟡 Must Address

Issues that must be fixed or acknowledged by the author with justification for why they
stand. Each must carry a resolution or a **qualifying author note**: either (a) a
discoverable TODO, or (b) a concrete revisit trigger. A note with neither is not
qualifying.

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1–A4 | Iteration 1, above. | — | — | — | — | — | ✅ A1, A3, A4 resolved; A2 carried as R3/A5 | — |
| A5 | A wrapped or near-miss `Self-merge never:` line drops protections while `policy self-merge set` stays on. (1) If the line wraps onto a second line (`docs/dev-cycle.md` is hard-wrapped prose), the second line's globs are lost silently: `Self-merge never: docs/` with `scripts/` on the next line prints `never docs/ set`. (2) A near-miss key is classed as absent (`never none`), not malformed: `**Self-merge never**:`, `Self-merge never :`, a hyphen or NBSP in the key, a task item, a table cell, link text, `\#`. Header intent (`:26-27`, "A malformed line … turns self-merge off") vs mechanism (`:152`, `never none: no line starts`). This is a runtime contradiction, so it carries Contested-Soundness. Fix: match the key on its letters only after the strip, and treat a continuation line as malformed. | Security | Medium; Contested-Soundness | security-reviewer F1 (+ Soundness cross-check) | for-author | — | 🟡 Open | — |
| A6 | `--settings` honours `refs/replace`. A replace ref on main's blob turned `review` into `policy self-merge set … on the default branch` (executed). The plan treats this capability as in-model (F38) but guards it only inside D6's gate snippet, while `--settings`/`--status` also run on the dispatch and collect paths. Fix, 1 line: `export GIT_NO_REPLACE_OBJECTS=1` beside `:69`. | Security | Medium | security-reviewer F3 | for-orchestrator-synthesis | Related to `feat/build-loop-u0a` D6 row (Defer to U3b); this is a separate guard, not a re-raise | 🟡 Open | — |
| A7 | `main_file`'s catch-all `*)` (`:87`) also catches main_entry's `error`, which means ls-tree failed or there is no default branch by name, and reports it as "is not a regular file on the default branch". It fails closed, but the reason is wrong, and the comment (`:73-77`) omits the case. Cause: `main_file` is a hand copy of the lib's main_entry → cat-file → FENCE_AWK sequence, the only copy outside the lib, and it reads the lib's awk variables. U1c's constraints line will be its second user. Fix now: an `error)` arm with the lib's wording. Later: move it into the lib (U1c). Convergence: fact-check (Claim 13, all three Mostly accurate) + architecture C1 + api-consistency F5 + submitted Claim 42's note. | Architecture / API | Coupling; Mostly accurate; Minor | architecture-review C1 + Fact-check Claim 13 + api-consistency F5 | for-author | `feat/build-loop-u0c` perf I1 row: consistent (sources the lib, no subprocess) | 🟡 Open | — |
| A8 | `NEVER` reaches U1c/U2 as the raw space-joined line, holding `*` and `?`, with trailing `/` unstripped. The gate must split it again (with `read -ra`, never unquoted, or it globs against a loop-writable checkout), strip again, and must not re-validate with `pathform` (the plan's `:74` still says "pathform globs"). Fix: export a normalised array (for example `NEVER_GLOBS`), or document the format at `:130-132` and in U2's brief. Convergence: architecture C2 + security F4 + api-consistency F4. | Architecture | Coupling | architecture-review C2 + security-reviewer F4 (Informational) + api-consistency F4 (Minor) | for-author | — | 🟡 Open | — |
| A9 | Commit 0ae7d801's mutation claim does not reproduce. Removing only `IFS=' '` leaves T45 passing, and so does removing only the explicit tab test; T45 fails only with both removed. The roles are reversed: `:157` is the first guard. Neither guard is pinned on its own. Test-strategy G3 adds a +1-line assertion of the full reason that pins `:157`. The commit is unmerged, so it can be amended. | Commit record / tests | Incorrect (high, executed), message only | Fact-check (Claim 39; r1, r2, r3) + test-strategy G3 | for-author | — | 🟡 Open | — |
| A10 | Commit 30676e57 says "A tab, VT, FF or CR in the value is now malformed". A trailing CR is stripped before any check (`Self-merge never: a\r` → `never a set`), and any other CR makes FENCE_AWK refuse the whole file. So the `\r` at `:157` can never be reached. No security impact. Fix the message, or drop `\r` from `:157`. | Commit record | Incorrect (high, executed) | security-reviewer endorsement, refuted by fact-check (submitted Claim 43b) | for-author | — | 🟡 Open | — |
| A11 | Fixture comment "Pass no lines for an empty file": `printf '%s\n'` with no arguments writes one newline. No caller depends on it. Reword (0 lines). | Tests / comment | Incorrect (high), comment only | Fact-check (Claim 23; r1, r3) + test-strategy G10 | for-author | — | 🟡 Open | — |
| A12 | The header's Exit line omits `-h`/`--help`'s exit 0. api-consistency notes `dev-cycle.sh:78-80` omits it the same way. | Docs | Mostly accurate | Fact-check (Claim 10) + api-consistency F7 (Informational) | for-author | `feat/build-loop-u1b` `-h extra` row: separate point (that row covers extra arguments) | 🟡 Open | — |
| A13 | T45 comment "Bold, heading and emphasis copies count as second lines too" (`build-loop-read.bats:119`) holds only for colon-inside markup. Same root as R3. | Tests / comment | Mostly accurate | Fact-check (Claim 29) | for-author | — | 🟡 Open | — |
| A14 | The subdirectory and linked-worktree test (`build-loop-read.bats:160-167`) cannot tell main from the working tree or the worktree's HEAD, because all of them hold the same content. Fix (+1 or 0 lines): give the working trees and the `wt` branch `review`. | Tests | Mostly accurate; test-strategy low | Fact-check (Claim 30) + test-strategy G5 | for-author | — | 🟡 Open | — |
| A15 | No test distinguishes main's commit from HEAD's. Every `--settings` run happens with HEAD at main's commit (`:81` and `:130` check out main first; `lower` and `wt` sit at main), so a script that reads `HEAD:docs/dev-cycle.md` passes all 9 tests. Executed by the orchestrator: mutant `git cat-file blob "HEAD:$f"` passed 9/9 (2026-10-05T11:28:56Z, scratch `orch-g2`). The test-strategy critic got the same result (m8). Fix, 0 net lines: run T4 and T45 with the `loop` branch checked out. | Tests | Executable-defect (test-strategy high → 🟡) | Executable-defect channel (found by test-strategy G2, executed) | for-author | — | 🟡 Open | — |

---

## 🟢 Consider

Advisory findings from contextual critics, single-critic suggestions, and improvement
opportunities. Not required to pass review.

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | The never list has no entry limit. Validation costs about 24 µs per entry and grows linearly (42 ms at 1k, 2.4 s at 100k), with no fork. Recorded so U2's gate starts from the right number. | performance-reviewer | Informational | for-orchestrator-synthesis | — | 🟢 Open |
| C2 | A never line printed past 4,096 bytes (about 700 short globs) is cut by the lib's scrub (`[line cut at 4096 bytes]`) and loses its `set: line N of …` ending, while `NEVER` in-process holds the full list. | performance-reviewer escalation (api domain) | Informational | for-author | — | 🟢 Open |
| C3 | `read_settings` never resets `POLICY` or `NEVER` when it starts (they are set once at `:133`). A second failing call in one process would keep stale values while the printed line says review. Calling it once per process is a correctness requirement for U1c/U2, not just a speed one (submitted Claim 44b, Unverifiable for future code). | architecture-review M1 + performance escalation + submitted 44b | Minor | for-author | — | 🟢 Open |
| C4 | `globform` duplicates the lib's `pathform` outside the lib; the lib header says pathform is the rule for settings rows. Make it a pathform mode in the lib. | architecture-review M2 | Minor | for-author | — | 🟢 Open |
| C5 | `-h` prints a fixed range (`sed -n '2,41p'`), and the usage string names only `--settings`. U1c's header growth will cut the help silently. | architecture-review M3 | Minor | for-author | — | 🟢 Open |
| C6 | The fixture copies dev-cycle.bats' git-env block instead of using `test/lib/hermetic-env.bash`, and `LIB` is set but unused (`build-loop-fixtures.bash:11-15`). | architecture-review M5 | Minor | for-author | `feat/build-loop-u0a` I2 row: premise still holds | 🟢 Open |
| C7 | The settings reader (`:106`) and the lib's `brief_fields` (`lib:289-290`) disagree on what counts as a second copy of a key line, and U2 combines their policies. Pick one model before U2. | architecture-review I1 | Informational | for-orchestrator-synthesis | — | 🟢 Open |
| C8 | The lib header still calls build-loop.sh "planned" (`scripts/lib/dev-cycle-read.sh:2-3`, outside this diff). | architecture-review I2 | Informational | for-author | — | 🟢 Open |
| C9 | `many()` is defined inside `read_settings`; bash makes it global and bound to that function's local arrays. | architecture-review I3 | Informational | for-author | — | 🟢 Open |
| C10 | `docs/dev-cycle.md:9`, `:17-19` describe the old rule ("exactly one line reading exactly"), omit slots, never and the unread-file cases, and say "not built yet". The plan gives the rewrite to U5. | api-consistency F2 | Minor | for-author | — | 🟢 Open |
| C11 | The never line's status word has no fixed position: `Self-merge never: none` prints `never none set: …`, so a prefix reader matching `never none` sees no list. Settle before the skill or U2 parses the line: status first, or document "the word before the first `:`". | api-consistency F3 | Minor | for-author | — | 🟢 Open |
| C12 | `unknown option: X (usage: build-loop.sh --settings)`, where the four sibling scripts print `Unknown option: X`. | api-consistency F6 | Minor | for-author | — | 🟢 Open |
| C13 | The no-echo check does not catch an echoed tab entry. Add `&& "$output" != *$'\t'*` (0 lines). | test-strategy G6 | low | for-author | — | 🟢 Open |
| C14 | The reasons "not an allowed glob form" and "twice" are never asserted (mutant m5 passes). | test-strategy G7 | low | for-author | — | 🟢 Open |
| C15 | No test runs a `review` policy with a malformed never line (`:176-178` else arm). | test-strategy G8 | low | for-author | — | 🟢 Open |
| C16 | The slots line for an absent or unread file is never asserted (`:141`). | test-strategy G9 | low | for-author | — | 🟢 Open |
| C17 | `-h`/`--help` is untested. | test-strategy G11 | low | for-author | — | 🟢 Open |
| C18 | Override row 209's premise has changed. Pointing `origin/HEAD` at a loop's branch (`git symbolic-ref`, no remote needed) now reproduces: `--settings` prints `policy self-merge set` and `slots 9 set`, labelled "on the default branch". U1b is the first caller that reads policy through resolve_main. Decide whether the row's revisit trigger moves from U2/U3 to U1c's `--status`. | security-reviewer (settled-row note) | Informational (no native level) | for-orchestrator-synthesis | `feat/build-loop-u0b` row 209 (Defer): premise changed, see Considered Overrides | 🟢 Open |
| C19 | Shapes that even A5's letters-only match would miss: `&#66;uild-loop policy:` (entity) and zero-width characters in the key stay hidden. | Fact-check E3 + security (untested list) | Informational | for-author | — | 🟢 Open |

---

## ↩️ Considered Overrides

| Override (PR ref / Date) | Prior finding | Original → Override | Reason | This run's treatment |
|---|---|---|---|---|
| `feat/build-loop-u1b` / 2026-10-05 | 224dd52d "byte-exact" (FC 25) | 🟢 → Won't-Fix | Header and tests state the CR rule | Inherited; not re-flagged. |
| `feat/build-loop-u1b` / 2026-10-05 | No `git log --graph` on test failure | 🟢 → Defer | U2's build-loop-check.bats | Inherited. |
| `feat/build-loop-u1b` / 2026-10-05 | `-h extra` exits 0 | 🟢 → Won't-Fix | Same as dev-cycle.sh | Inherited. A12 is a separate point: the Exit line omits help's exit 0. |
| `feat/build-loop-u1a` / 2026-10-05 | main_entry's ls-tree cost | 🟡 → Won't-Fix | 49 entries measured | Inherited; performance did not re-raise it. |
| `feat/build-loop-u1a` / 2026-10-05 | T34's build-loop.sh side | 🟢 → Defer | U3/U3b | Not applicable (no answer mode in U1b). |
| `feat/build-loop-u0a` / 2026-10-05 | A test should source the lib from build-loop.sh's side (arch I2) | 🟢 → Defer | Until U1 | Revisit trigger met. Architecture confirms the goal is met through the script subprocess. |
| `feat/build-loop-u0a` / 2026-10-05 | D6 must hash-check the sourced lib | 🟢 → Defer | U3b's T33 | Inherited. A6 (replace refs) is a separate guard the script itself can carry, not a re-raise. |
| `feat/build-loop-u0a` / 2026-10-05 | need_root's pwd -P fork | 🟢 → Won't-Fix | Within noise | Inherited. |
| `feat/build-loop-u0b` / 2026-10-05 | origin/HEAD naming a loop's branch is an untested candidate (row 209) | 🟢 → Defer | U2/U3 gate tests | **Premise changed.** Security reproduced it, and U1b is the first policy reader through resolve_main. Not re-tiered: surfaced as C18 for a decision on moving the trigger to U1c. |
| `feat/build-loop-u0b` / 2026-10-05 | U3's --merge must check main_by_name | 🟢 → Defer | U3 | Consistent: `:70-71` call `resolve_main \|\| true`, then gate on main_by_name. |
| `feat/build-loop-u0c` / 2026-10-05 | build-loop.sh calls the lib directly, not dev-cycle.sh per path | 🟢 → Defer | U1/U2 review | Consistent (A7 notes the in-script copy of one lib sequence). |

---

## ✅ Confirmed Good

| Item | Verdict | Evidence | Source | Legibility-target |
|---|---|---|---|---|
| A tab, VT or FF in the never value makes the line malformed and turns self-merge off (iteration-1 R1) | ✅ Confirmed | `scripts/build-loop.sh:157`: `"$v" == *[$'\t\v\f\r']*`. Submitted Claim 43a (executed) and FC Claim 18 (executed): T45 rows `a\tb`, `\ta`, `a\t`, `a \tb` print `never malformed`. | security-reviewer endorsement, verified by fact-check | for-orchestrator-synthesis |
| The policy and slots lines print only fixed text, line numbers or the matched word; the never value prints only after every entry passes globform | ✅ Confirmed (scoped to the probes run) | `scripts/build-loop.sh:170`: `else NEVER="$v"; NEVER_LINE="never $v set: …"`. Submitted Claim 42 (executed: ESC and `$(...)` payloads, duplicate keys, refused files, hostile and non-ASCII entries). | security-reviewer endorsement, verified by fact-check | for-orchestrator-synthesis |
| `--settings` writes nothing to the tree or `.git` | ✅ Confirmed | FC Claim 8 (executed, all three replicates: tree and `.git` snapshot unchanged) | Fact-check | for-orchestrator-synthesis |
| The lib is sourced from the script's own directory, and a missing lib exits 1 | ✅ Confirmed | `scripts/build-loop.sh:46`: `SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"`. FC Claim 11 (executed; `build-loop-read.bats:152-158`). | Fact-check | for-orchestrator-synthesis |

Dropped by the cross-check: "a malformed line turns self-merge off" (FC Claim 4, executed) holds for lines the code recognises, but security F1 shows that near-miss and wrapped lines fail open, so it is not published as ✅ (see A5).

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
| 1 | `scripts/build-loop.sh:26-31`, `:101-112`, `:152` | FC 5a/5b/14/34, R3, A5, A13, api F1, test G4, arch I1, C19 | distinct defects: security F1 already states the shared root (exact contiguous key prefix; variants classed absent) and its fix (letters-only key match), so no fragment-only root exists. |
| 2 | `scripts/build-loop.sh:150-170` | FC 18/39, submitted 43b, A8, A9, A10, C1, C3, C11 | distinct defects: separate mechanisms (guard pinning, dead `\r`, export shape, status-word position). |
| 3 | `scripts/build-loop.sh:73-94` | FC 13, arch C1, api F5, submitted 42 note | merged into one row (A7), since it is one finding with a cause (copy outside the lib) and a symptom (wrong label); no composed row needed. |
| 4 | `test/scripts/build-loop-read.bats:77-85`, `:124-130` | FC 27/38, R2, A15, arch M4, test G1/G2 | distinct defects: unenforced `&&` operands (R2) vs every run having HEAD at main (A15). |
| 5 | `test/scripts/build-loop-read.bats:160-167` | FC 30, test G5 | merged into A14. |

---

To pass review: all 🔴 items must be resolved. All 🟡 items must be either fixed or
carry a qualifying author note (a discoverable TODO or a concrete revisit trigger; see
"Qualifying author note" in `skills/code-review/references/rubric.md`). 🟢 items are optional.
