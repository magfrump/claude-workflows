Commit: 1d79ffef
Loop-pass short-circuit: used at 224dd52d
# Code Review Rubric

**Scope:** full unit range `feat/build-loop-u1a...feat/build-loop-u1b` at 1d79ffef. The unit's commits are 0797ed32, 224dd52d, 30676e57, 0ae7d801 and 1d79ffef; af734e0f holds review artifacts. The merges a091d8fa and 93f09654 bring in u1a's own fixes and are context only. The diff is 400 changed code lines in 3 new files, plus this loop's review artifacts under `docs/reviews/`. Iteration 3 is the final confirming pass: full panel, not a loop pass, fact-check k=3. | **Reviewed:** 2026-10-05 | **Status: 🔴 DOES NOT PASS** — 1 red item(s) unresolved

Iteration 1 (at 224dd52d) short-circuited at the fact-check, and its marker above stays for the rest of the loop. Iteration 2 (at 0ae7d801) and this pass ran every critic. The loop is not closed, because this pass is not clean.

Reports (all `Commit: 1d79ffef`):
- `code-fact-check-report-build-loop-u1b.md`: merged k=3 (47 claims, 82% verdict agreement), with the Stage-2.5 submitted claims (46, 47) appended. The replicates are `-r1.md`, `-r2.md` and `-r3.md`; the submitted-claims pass is `code-fact-check-submitted-claims-build-loop-u1b.md`.
- `security-reviewer-review-2026-10-05-build-loop-u1b.md`, `performance-reviewer-review-2026-10-05-build-loop-u1b.md`, `api-consistency-reviewer-review-2026-10-05-build-loop-u1b.md`.
- `architecture-review-review-2026-10-05-build-loop-u1b.md`: auto-selected because the diff adds a new module.
- `test-strategy-review-2026-10-05-build-loop-u1b.md`: kept from iteration 2's panel, since the tests were reworked and fact-check escalations E2 and E4 name it.

Execution logs are in `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b-i3/<agent>/`, because this pass may write only review reports. The orchestrator's own executions are in `orch-g1/` (A18) and `orch-a6/` (A16, A17).

Deviations from the skill:
- Agents read their skill files and the shared context block (`.../review-u1b-i3/shared.md` and `shared-stage2.md`, about 18k tokens each) from disk; the block was not pasted inline.
- The Fact-Check Gate's pause on high-confidence Incorrects was resolved as "Continue", because the caller asked for the full panel.
- tech-debt-triage was not auto-selected: the diff exceeds 500 lines only because of review artifacts, and the code is 400 lines.

---

## Iteration-2 items, checked against 1d79ffef (rubric at 0ae7d801)

| # | Iteration-2 finding | Status at 1d79ffef | Evidence (executed) |
|---|---|---|---|
| R2 | `settings_like A && settings_like B` never failed T4/T45 | ✅ Resolved | FC Claim 31. Every helper pair is joined with `;`, and a failing helper inside a `for` body fails the test. Bogus first operands are killed by test 5 at `:81` and test 7 at `:130`. The pathform (A4-regression) mutant is killed at `:130` (test-strategy, architecture, all three FC replicates). |
| R3 | Copies with markup closing before the colon were hidden | ✅ Resolved for its shapes; residue is R4 | `**Build-loop policy**: review`, `*…*:`, `` `…`: ``, tables, links around the whole key and `Self-merge never :` are counted (FC Claims 7, 28; T2 and T45 loops; security). Markup that adds letters still hides a copy: R4. |
| A5 | (1) A wrapped never line drops globs; (2) near-miss keys are classed absent | ⚠️ Partly resolved | (1) Resolved: a non-blank next line makes the line malformed (FC 33, submitted 47; T45 `:131-133`). (2) Resolved for iteration 2's shapes (security). Still open for letter-bearing markup and homoglyph keys on a sole never line, which reads `never none` with self-merge on: A17. |
| A6 | `--settings` honoured `refs/replace` | ⚠️ Partly resolved | `GIT_NO_REPLACE_OBJECTS=1` works with no repo config (FC Claim 12, all three replicates). It is bypassed when `.git/config` sets `core.useReplaceRefs=true`; the orchestrator reproduced this at 2026-10-05T12:01:38Z on git 2.39.5 (`orch-a6`). Carried as A16. |
| A7 | main_file's catch-all mislabelled main_entry's `error` | ✅ Resolved | `error)` arm at `:79`, failed-read arm at `:82-83`. A real deleted tree object and a deleted blob each reach their wording (FC Claim 13; architecture). The arms are untested: C4 below. |
| A8 | NEVER exported as the raw joined line | ✅ Resolved in code | `NEVER=([0]="a/" [1]="h*/x?.md" [2]=".github/")` (architecture, FC Claim 18). The plan's ":74 pathform globs" wording remains: C6. |
| A9, A10 | Commit-message claims (0ae7d801, 30676e57) | ↩️ Override-log row (u1b, Won't-Fix) | Inherited. |
| A11 | Fixture comment on `settings` with no lines | ✅ Resolved | `printf '%s\n'` with no arguments writes one `\n` (1 byte), so "one empty line" at `build-loop-fixtures.bash:25` is right (FC Claim 23, all three replicates). |
| A12 | Exit line omitted help | ✅ Resolved | `:33`, "0 every line printed (or help)" (FC Claim 10; api). |
| A13 | T45 copy comment held only for colon-inside markup | ⚠️ Partly resolved | The `:122` comment now holds for its eight listed shapes, but not for "a link" in general: A22. |
| A14 | Subdirectory/worktree test could not tell main from the working tree or the worktree HEAD | ⚠️ Half resolved | The working-tree half holds (the worktree-reading mutant is killed at `:176`). The worktree-HEAD half is still open: the `HEAD:$f` mutant passes test 9. A19. |
| A15 | No test told main's commit from HEAD's | ✅ Resolved | The `HEAD:$f` and `MAIN_SHA=HEAD` mutants are killed by test 5 at `:84` and test 7 at `:140` (FC Claim 35; test-strategy). |
| C3 | read_settings did not reset POLICY/NEVER | ✅ Resolved | `:130`; a second in-process call gives `POLICY=review` and an empty NEVER (FC Claim 18; architecture). |
| C12 | `unknown option` wording | ✅ Resolved | `:55`, `Unknown option: $1` (api). |
| C13 | The no-echo check missed tabs | ✅ Resolved | Mutant mC13 is killed at `:118` (test-strategy). |
| C1, C2, C4–C11, C14–C19 | Advisory rows | ↩️ Override-log rows | Inherited. C19's premise changed: see Considered Overrides. |

---

## 🔴 Must Fix

Issues that must be resolved before merge. Draft cannot pass review with any red items
unresolved.

| # | Finding | Domain | Severity | Source | Location | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|---|---|
| R1–R3 | Iterations 1–2, above. | — | — | — | — | — | — | ✅ Fixed (R3 residue is R4) |
| R4 | The header and the SETTINGS_AWK comment say markup "cannot hide" a copy of a key. Markup that adds letters before or inside the key does hide one, because the letters-only match keeps those letters. Shapes: a checked task item `- [x] …` / `- [X] …`; inline HTML not at column 0, such as `Build-loop <span>policy</span>: review` or `Self-<b>merge</b> never: b/`; a link that closes inside the key, `[Build-loop](x) policy: review`. With an exact `Self-merge never: a/` line first, a second `- [x] Self-merge never: b/` leaves `never a/ set` and `policy self-merge set`, with no "more than one line" warning (executed by FC r1 and r3, security, api, test-strategy, and the orchestrator). This is the same contract iteration 2's R3 held red: U2 will rely on the header's fail-closed rationale (decision 031). Security rates the second-copy exposure Low (F3); the sole-line case is A17. Fix either way: strip `[x]`/`[X]` boxes, tags and link destinations before the letters pass (this closes most of A17 too), or narrow `:25-27`, `:90-92` and the `:122` comment to "markup without letters" and log the residue. The 0-line test pin is to add the `- [x]` shape to the copy lists at `build-loop-read.bats:33` and `:123` (test-strategy G5). Convergence: fact-check (Claims 8, 14) + security F3 + api-consistency F1 (Inconsistent) + test-strategy G5. | Security / contract | Incorrect (high, executed); security Low; api Inconsistent | Fact-check (Claims 8, 14; r1 Incorrect, r3 Mostly accurate, r2 did not probe these shapes) + security-reviewer F3 + api-consistency F1 + test-strategy G5 | `scripts/build-loop.sh:26-27` — `start with the key's ("buildlooppolicy"), so markup, a table or` / `a misplaced colon cannot hide one.`; mechanism `:101` — `s = tolower($0); gsub(/[^a-z]/, "", s); k = ""` | for-author | `feat/build-loop-u1b` C19 row (Won't-Fix; entity and zero-width): does not cover these shapes, and its "does not render as the key" premise fails for them. See Considered Overrides. | 🔴 Unresolved |

---

## 🟡 Must Address

Issues that must be fixed or acknowledged by the author with justification for why they
stand. Each must carry a resolution or a **qualifying author note**: either (a) a
discoverable TODO, or (b) a concrete revisit trigger. A note with neither is not
qualifying.

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1–A15 | Iterations 1–2, above. | — | — | — | — | — | See the iteration-2 table | — |
| A16 | The A6 replace-ref guard can be bypassed. `core.useReplaceRefs=true` in `.git/config` overrides `GIT_NO_REPLACE_OBJECTS=1` on git 2.39.5. With a blob replace on main's `docs/dev-cycle.md` and that config line, `--settings` prints `policy self-merge set: line 1 of docs/dev-cycle.md on the default branch` where main reads `review`. The orchestrator executed this at 2026-10-05T12:01:38Z (`orch-a6`); security reproduced it for a commit replace as well. The actor is the same as C18's (a uid that can write `.git/`), and D6's gate is unaffected because it refuses any `refs/replace/` entry. Fix, 1 line: also export `GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=core.useReplaceRefs GIT_CONFIG_VALUE_0=false`, or log it as a C18 extension with U3b's trigger. Related: architecture M1 (C2 below) notes that dev-cycle.sh's lib readers carry no guard at all, and test-strategy G2 (C3 below) notes that the guard is untested. | Security | Medium | security-reviewer F1 (executed; orchestrator re-executed) | for-author | `feat/build-loop-u1b` C18 row (Defer U3b): same actor, separate mechanism; not covered as written | 🟡 Open | — |
| A17 | A sole never line hidden by a letter-changing shape fails open. If the only `Self-merge never:` line is `- [x] Self-merge never: workflows/`, `Self-<b>merge</b> never: …`, `[Self-merge](x) never …`, an entity (`n&#101;ver`) or a homoglyph (Cyrillic е), the output is `never none: no line starts "Self-merge never:"` with `policy self-merge set`. The protection is silently dropped. The orchestrator executed the `- [x]` and `<b>` shapes. For the never key, absence is the permissive state, so C19's premise ("the hidden copy cannot raise the policy") does not hold there. Policy and slots fail closed. Options: (a) under self-merge policy, require a never line, so `never none` also turns self-merge off (closes every shape); (b) strip as in R4, and log entity and homoglyph shapes as a corrected C19. Intent `:23-24` "Malformed (or a file not read) turns self-merge off" vs mechanism `:145` `never none`. Iteration 2's A5 residue. | Security | Medium | security-reviewer F2 (executed; orchestrator re-executed) | for-author | `feat/build-loop-u1b` C19 row (Won't-Fix): **premise changed** for the never key | 🟡 Open | — |
| A18 | No test asserts the policy line when there are two never lines. Mutant mDupOpen drops `never_ok=""` at `:146` and survives 9/9. With it, the script prints `policy self-merge set` next to `never malformed: more than one line starts "Self-merge never:" (lines 2 and 4)`, which fails open. The orchestrator executed it at 2026-10-05T12:00:33Z (`orch-g1`, a scratch copy of scripts/, test/ and docs/dev-cycle.md). Fix, 0 net lines: append `; settings_like policy "policy review unset: line 1 reads self-merge"` to `test/scripts/build-loop-read.bats:121`; test-strategy confirmed it kills the mutant. | Tests | Executable-defect (test-strategy high → 🟡) | Executable-defect channel (found by test-strategy G1, executed) | for-author | — | 🟡 Open | — |
| A19 | Commit 1d79ffef's A14/A15 bullet says the subdirectory and worktree runs "now have a … checked-out branch that differ[s] from main; a mutant reading HEAD fails them". They do not: `wt` is created at main (`build-loop-read.bats:171`, `git worktree add -q -b wt "$BATS_TEST_TMPDIR/wt" main`), and the subdirectory run is on main. The `HEAD:$f` mutant passes test 9, and the `:169` comment "reads the same main" promises more than test 9 checks. No coverage is lost overall, because T4 and T45 kill the mutant (A15). Fix, 0 lines: append `; git -C "$BATS_TEST_TMPDIR/wt" commit -qam lower` to `:172` (test-strategy G3 confirmed it kills the mutant at `:177`), or amend the message, since the commit is unmerged. | Tests / commit record | Incorrect (high, executed), message and comment only | Fact-check (Claim 36, r1+r2+r3 Incorrect; Claim 30) + test-strategy G3 (low) | for-author | — | 🟡 Open | — |
| A20 | The header says "a second copy, or a file the lib's FENCE_AWK refuses, leaves the default", but for the never line both print `never malformed`, not the default `none`. This fails closed. Reword (0 lines). | Docs | Mostly accurate; api Minor | Fact-check (Claim 2, all three replicates) + api-consistency F3 | for-author | — | 🟡 Open | — |
| A21 | The never line's "then a blank line or the end" (`:20`), NEXT "the line after the first" (`:92-93`) and the WHY "(Markdown would join it as more globs)" (`:152`, also in 1d79ffef's message) all describe the next line FENCE_AWK reads, not the next physical line. A fence directly after the line is accepted, and the WHY fires falsely for a heading, a `- item`, a one-line `<!-- -->` or a text line after a fenced block. This fails closed. Reword, for example "the next line outside a fence is blank, or there is none" and "(Markdown may join it…)". | Docs | Mostly accurate | Fact-check (Claims 5, 15, 16) | for-author | — | 🟡 Open | — |
| A22 | T45 comment `build-loop-read.bats:122`, "Copies in markup, a table, a link or with a misplaced colon count as second lines too", holds for its eight listed shapes, but not for a link closing inside the key or for markup with letters. Same root as R4; it resolves with R4's choice. | Tests / comment | Mostly accurate | Fact-check (Claim 28; r1) | for-author | — | 🟡 Open | — |
| A23 | Commit 1d79ffef's message: "any of them [a link] is a second line" holds only for a link around the whole key (FC 32), and the Notes' "T3's real-file test would catch one" holds only for the policy key. A prose `Self-merge never …` or `Build-loop slots …` line in docs/dev-cycle.md would make the never line malformed or drop slots to 3, and test 4 passes it (FC 39, executed). The commit is unmerged, so amend it or record a Won't-Fix row. | Commit record | Mostly accurate | Fact-check (Claims 32, 39) | for-author | `feat/build-loop-u1b` A9/A10 row: same class (message claims), not this message | 🟡 Open | — |

---

## 🟢 Consider

Advisory findings from contextual critics, single-critic suggestions, and improvement
opportunities. Not required to pass review.

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | `globform` (`:114-121`) is quadratic in one entry's part count, because `${rest%%/*}` and `${rest#*/}` rescan the remainder: 10 KB entry 0.2 s, 40 KB 3.1 s, 80 KB 11.2 s. It is cold-path and fails closed. `IFS=/ read -ra` takes 29 ms on 20k parts. | performance-reviewer F1 | Low | for-author | C1 row (entry count) does not cover it; fits C4's U2 trigger | 🟢 Open |
| C2 | `GIT_NO_REPLACE_OBJECTS=1` is set only in build-loop.sh. The lib's main readers are shared with dev-cycle.sh, where a blob replace turns `--check-answer Q-001` from `open` to `keep` (executed). The lib header's list of caller settings omits it. Fix in the lib (1 line) or defer to U1c with row 242. | architecture-review M1 | Minor | for-author | Related to A16 | 🟢 Open |
| C3 | The replace guard has no test: mutant mNoReplace survives 9/9. Fix (+1 line, or 0 if appended to `:87`): a `git replace` at the end of T4, then `settings_like slots "slots 7 set:"`. | test-strategy G2 (fact-check E4) | medium | for-author | — | 🟢 Open |
| C4 | main_file's `error` and failed-read arms are untested (mutants mErrAbsent and mReadFail survive). Policy stays review either way; only the never word changes. Defer to U2. | test-strategy G4 (fact-check E4) | low | for-author | C14–C17 row covers other gaps, not these | 🟢 Open |
| C5 | An empty `NEVER=()` means "no line", "malformed" or "not read" alike. It is safe only because those cases leave POLICY at review, and the interface comment (`:122-125`) does not tell consumers to judge POLICY first. | api-consistency F5 + architecture I1 | Informational | for-author | — | 🟢 Open |
| C6 | The plan (`docs/working/plan-build-loop-handoff.md:74`) still calls never entries "pathform globs", but globform allows `.git*` parts. If U2 re-checks NEVER with pathform, it will refuse `.github/`. Fix in U2's brief. | api-consistency F2 + architecture I3 | Minor | for-author | — | 🟢 Open |
| C7 | The usage suffix `(usage: build-loop.sh --settings)` (`:49`) goes stale when U1c adds `--status`, and no sibling script uses one. | api-consistency F4 | Informational | for-author | — | 🟢 Open |
| C8 | `read_settings` mixes parsing, the policy decision and the WHY text. U1c's constraints line should be a separate reader on `main_file`. | architecture-review I2 | Informational | for-orchestrator-synthesis | — | 🟢 Open |
| C9 | The next-line rule applies only to the never key. `Build-loop policy: self-merge` followed by `except on Fridays` prints `policy self-merge set`, and `Build-loop slots: 4` followed by `more` prints `slots 4 set`, though Markdown renders each as one paragraph (`nx` is computed for every key but read only for never, `:100`, `:105`, `:152`). | Fact-check submitted-claims observation (Claim 47 note, executed) | Informational (no native level) | for-author | — | 🟢 Open |

---

## ↩️ Considered Overrides

| Override (PR ref / Date) | Prior finding | Original → Override | Reason | This run's treatment |
|---|---|---|---|---|
| `feat/build-loop-u1b` / 2026-10-05 | An HTML entity or zero-width characters in a key copy stay hidden (C19) | 🟢 → Won't-Fix | "Such a copy does not render as the key either, and only an exact line sets anything; the hidden copy cannot raise the policy." | **Premise changed.** (1) The zero-width half no longer applies; such copies are now counted (security). (2) For the never key, a hidden sole line drops protection, so "cannot raise the policy" does not hold (A17). (3) Letter-bearing markup and homoglyphs render as the key (R4, A17). Not re-tiered as C19 itself; the new shapes are R4 and A17. |
| `feat/build-loop-u1b` / 2026-10-05 | origin/HEAD symref to a loop's branch (C18) | 🟢 → Defer | U3b's --state | Inherited; premise holds (security re-probed). A16 is the same actor through a separate mechanism, not a re-raise. |
| `feat/build-loop-u1b` / 2026-10-05 | 0ae7d801 / 30676e57 message claims (A9, A10) | 🟡 → Won't-Fix | History not rewritten | Inherited. A19 and A23 are 1d79ffef's own claims, not covered. |
| `feat/build-loop-u1b` / 2026-10-05 | C1 entry limit; C2 4096-byte cut; C4 globform copy; C5 help range; C6 fixture env; C7 copy models; C8; C9; C10 docs text; C11 status word; C14–C17 test gaps | various → Won't-Fix / Defer | See log | Inherited; not re-raised. Performance C1 (quadratic per entry) is a new axis, and can defer with C4. |
| `feat/build-loop-u1b` / 2026-10-05 | 224dd52d "byte-exact"; no `git log --graph`; `-h extra` exits 0 | 🟢 → Won't-Fix / Defer | See log | Inherited. |
| `feat/build-loop-u1a` / 2026-10-05 | main_entry ls-tree cost; T34; FENCE_AWK `\0`; case blocks per caller (row 228) | various | See log | Inherited; architecture confirms row 228's premise holds for main_file. |
| `feat/build-loop-u0a/u0b/u0c` / 2026-10-05 | D6 lib hash-check (U3b); need_root forks; U3 --merge checks main_by_name; lib called directly | Defer / Won't-Fix | See log | Inherited; consistent. |

---

## ✅ Confirmed Good

| Item | Verdict | Evidence | Source | Legibility-target |
|---|---|---|---|---|
| The policy and slots lines print only fixed text, line numbers and captured fixed alternatives; the never line prints its value only after every entry passes globform (scoped to the 21 hostile probes run) | ✅ Confirmed | `scripts/build-loop.sh:164` — `else NEVER=("${parts[@]}"); NEVER_LINE="never $v set: line ${first[never]} $where"; fi`. Submitted Claim 46 (executed: ESC/OSC, `$(...)`, backticks, U+202E, 6000-byte lines, refused files; an echo mutant fails T45 at `:118`). | security-reviewer endorsement, verified by fact-check | for-orchestrator-synthesis |
| A never line followed by a non-blank line outside a fence is malformed and turns self-merge off | ✅ Confirmed | `scripts/build-loop.sh:152` — `elif [[ "${next[never]}" != 1 ]]; then why="is followed by a non-blank line (Markdown would join it as more globs)"`. Submitted Claim 47 (executed: text, indented, list, heading, comment, FF, slots and policy lines). | security-reviewer endorsement, verified by fact-check | for-orchestrator-synthesis |
| T4 and T45 now enforce each check; the pathform and HEAD-reading mutants fail them | ✅ Confirmed | `test/scripts/build-loop-read.bats:81` — `settings_like policy "policy review set:"; settings_like slots "slots 3 default:"`. FC Claims 31, 35 (executed, mutant logs in all three replicates). | Fact-check | for-orchestrator-synthesis |
| `NEVER` is an array of the checked entries, and `read_settings` resets POLICY and NEVER on each call | ✅ Confirmed | `scripts/build-loop.sh:130` — `POLICY=review; NEVER=()`. FC Claim 18 (executed). | Fact-check | for-orchestrator-synthesis |
| `--settings` writes nothing, and the lib is sourced from the script's own directory | ✅ Confirmed | `scripts/build-loop.sh:39` — `SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"`. FC Claims 9, 11 (executed). | Fact-check | for-orchestrator-synthesis |

Dropped by the cross-check:
- "A replace ref cannot swap in another settings blob" (FC Claim 12, executed) holds only with no repo config, because security F1 shows `core.useReplaceRefs=true` overrides it. It is not published as ✅; see A16.
- "Markup cannot hide a copy" (FC Claim 7's scope) is contradicted by R4.

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
| 1 | `scripts/build-loop.sh:25-27`, `:90-92`, `:101-105`, `:145` | FC 7/8/14, R4, A17, A22, security F2/F3, api F1, test G5 | distinct defects: security F2 already states the shared root (the letters-only match keeps letters that markup adds) and the strip fix. R4 (the second copy is uncounted; the contract claim) and A17 (a sole hidden line reads `none`; the fail-open) are separate consequences with a partly shared fix. |
| 2 | `scripts/build-loop.sh:62-63` | FC 12, A16, C2, C3 | distinct defects: a config override (A16), the guard missing from the other caller (C2), the guard untested (C3). |
| 3 | `scripts/build-loop.sh:122-125`, `:146`, `:163-171` | A18, C5 | distinct defects: an untested fail-closed step (A18) vs an undocumented consumer rule (C5). |
| 4 | `scripts/build-loop.sh:20`, `:92-93`, `:100-105`, `:152` | FC 5/15/16, A21, C9, submitted 47 | distinct defects: wording (A21) vs the rule's key scope (C9). |
| 5 | `test/scripts/build-loop-read.bats:169-178` | FC 30/36, test G3 | merged into A19. |
| 6 | `scripts/build-loop.sh:11-12` | FC 2, api F3 | merged into A20. |

---

To pass review: all 🔴 items must be resolved. All 🟡 items must be either fixed or
carry a qualifying author note (a discoverable TODO or a concrete revisit trigger; see
"Qualifying author note" in `skills/code-review/references/rubric.md`). 🟢 items are optional.

---

## Iteration-4 gate decision (2026-10-05): escalate

Decision: `escalate`. Iteration 3's red R4 re-fires iteration 2's R3 (a markup copy of a settings key stays hidden) in shapes the letters-only fix did not reach: `- [x]` task items, inline HTML, and a link closing inside the key. That is the divergence signal. Recognising copies heuristically is the weak point, so a fourth fix pass would chase shapes. The open question is a design choice, filed as Q-112 (`you: judgment`). U1b and U1c do not land until it is answered.

## Iterations (3 completed)
1. `--loop-pass`, short-circuited at the fact-check: 1 red (a tab passed the single-space rule). Fixed in 30676e57, with the cap trim in 0ae7d801.
2. Full panel at 0ae7d801: 2 reds (`&&`-joined checks that could never fail a test; markup copies hidden) and A5–A15. Fixed in 1d79ffef (letters-only match, never line must end at a blank line, no replace refs, NEVER as an array).
3. Full panel at 1d79ffef: R4 and A16–A23. Iteration 2's items are resolved or partly resolved by execution.

## Remaining Must Fix
- R4 `scripts/build-loop.sh:26-27, 90-92`: markup that adds letters hides a copy of a key (`- [x] Self-merge never: b/` after an exact line leaves `never a/ set`, with no warning).

## Remaining Must Address
- A16: `core.useReplaceRefs=true` in `.git/config` overrides `GIT_NO_REPLACE_OBJECTS=1`.
- A17: a sole never line hidden by markup reads `never none` while self-merge stays on.
- A18: a mutant dropping `never_ok=""` on a duplicate never line survives the tests (0-line test fix).
- A19: the worktree half of the G20 test does not test what 1d79ffef says (0-line fix).
- A20–A23: wording (the never line reads `malformed`, not the default; "the line after" means the next unfenced line; the link and real-file claims).

## Convergence diagnosis (one sentence)
The mechanical findings converge, but finding hidden copies by a letters-only heuristic does not: each fix narrows the hidden shapes without closing them, because the reader does not model Markdown inline syntax and cannot.

## Recommended action (ship-with-issues / split-PR / pause for redesign)
Pause for a small redesign of the copy rule (Q-112), then one more iteration for it plus A16–A23.
