Commit: c143b929
# Code Review Rubric

**Scope:** unit range `feat/build-loop-u1b...feat/build-loop-u1c` at c143b929 (unit commits 859e29e8, aaae80c6, 553a50d5, c143b929; merges 121aa63e, 83b9fd49 and 176a5fcc bring in u1b and are context only). 426 changed code lines in 5 files (cap waived to ~430, Q-114). Iteration 2, final confirming pass (no `--loop-pass`), fact-check k=3. | **Reviewed:** 2026-10-05 | **Status: 🟡 CONDITIONAL PASS** — 9 amber item(s) awaiting resolution or justification

Reports (all `Commit: c143b929`):
- `code-fact-check-report-build-loop-u1c.md`: k=3 merged (r1/r2/r3 alongside), 44 claims: 32 Verified, 10 Mostly accurate, 2 Unverifiable; verdict agreement 32/44. Stage 2.5 appended Claims 45a–47 from `code-fact-check-submitted-claims-build-loop-u1c.md`.
- `security-reviewer-review-2026-10-05-final-build-loop-u1c.md`, `performance-reviewer-review-2026-10-05-final-build-loop-u1c.md`, `api-consistency-reviewer-review-2026-10-05-final-build-loop-u1c.md`
- `architecture-review-review-2026-10-05-final-build-loop-u1c.md` (auto-selected: public mode and output contracts U2–U4 parse)
- `test-strategy-review-2026-10-05-final-build-loop-u1c.md` (included: override row 246's revisit trigger names U1c)

Execution logs and probes are in `/home/node/.claude/jobs/989f3e5a/tmp/review-u1c-i2/<agent>/`, because this pass writes only review reports.

Deviations from the skill:
- Scope came from the caller's explicit three-dot range, not `main...HEAD` (that would include u1a and u1b).
- Agents read their skill files and the shared context block from disk (`.../review-u1c-i2/orch/shared.md`, about 19k tokens, inline mode with the lib trimmed to lines 245–390 and the bats file left to self-read; `shared-stage2.md` adds the fact-check summary).
- Critic reports use the `-final-` infix (u0 precedent) so iteration 1's reports stay on disk.
- Not clean, so no `Loop closed at` marker.

---

## Iteration 1 items (rubric at 553a50d5), status at c143b929

| # | Status | How checked |
|---|---|---|
| R1 | ✅ Resolved for the shapes the fix targets: every ASCII near-miss iteration 1 listed (`* H2:`, `1. H2:`, two spaces, tab, indent, `h2:`, `**H2:**`, `### H2:`, `> H2:`, `H10 :`, table row, `H01:`) now prints `constraints unreadable`, and a `success:` under a later `#` heading no longer satisfies H1. Residue, re-tiered under Q-112 [1] as A12/A13: the Cyrillic `Н2:` from iteration 1's own list, fullwidth `Ｈ2:`, `H²:`, fenced lines, letter-prefixed lines (`- [x] H2:`), and non-`#` headings still leave `constraints ok`. | Orchestrator probe (18 shapes) + FC Claims 5–8 (all 3 replicates, executed) + security F1/F2 + api F1/F4 |
| A1 | ✅ Resolved. Two-tree, parent-after-author, duplicate-parent, NUL and whitespace-second-line objects all skip; a non-hex parent object cannot be put on a ref. (The two-tree skip's reason reads "it has no parent": C13.) | Orchestrator probe + FC Claims 22, 36c, submitted 45a (executed) |
| A2 | ✅ Resolved. The help now defines the subject as "its message's first line" (`:67-68`); a leading-blank message reads `working` (fail-closed), consistent with that definition. | FC Claim 16a/14 + submitted 45c (executed) |
| A3 | ✅ Resolved (`:60-61` "or 0 without one"; `:63-65` "missing or malformed or its Dispatched: line malformed"). | FC Claims 15, 16a |
| A4 | ✅ Resolved in behaviour: an open brief in `closed/` makes a same-branch brief skip. The lib still has no single `(closed/)?` predicate (C2). | Orchestrator probe + FC 24, submitted 46 (executed) + architecture F2 |
| A5 | ✅ Resolved for `--status` (`:326` computes the set on first use). The fix adds a new coupling (A14), and a direct reader of `SHARED_BRANCHES` still sees "nothing shared". | FC 24 + architecture F1 |
| A6 | ✅ Resolved: `:42-44` says the path must be plain in the working tree. The lite drift check's "unenforced" claim is refuted by running: `check_brief`'s `blocker` (lib `:333`) skips a symlinked brief ("reached through a symlink, or not a regular file"); `shared_branches` reads other briefs from main through `brief_fields`, which calls `main_entry` itself (lib `:294`), and the help claims nothing about their working-tree copies. | Orchestrator probe + FC Claim 10 (all 3 replicates, executed) |
| A7 | ✅ Resolved (the comment no longer says `--status` reads NEVER). Its new wording reads as if the gate exists: A17. | FC Claim 20 |
| A8 | ✅ Resolved: the stopped-reason grep runs with `LC_ALL=C`; under an uninstalled caller locale only bash's two start-up warnings remain (3 at 553a50d5). | Orchestrator probe + FC 23, 36e (executed) |
| A9 | ✅ Resolved (fixture `tip` says "MESSAGE and a newline"). | FC Claim 28 |
| A10 | ✅ Resolved (T7 renamed "spoofed markers are skips or read as working"). | FC Claim 29 |
| A11 | Covered by override row 265 (Won't-Fix). | — |
| C1 | Row 266 (Defer): **premise changed** — its rationale "Done briefs move to closed/" no longer holds now that `closed/` is scanned. Re-surfaced as A15. | performance F1 |
| C2, C4 | Row 267 (Defer): inherited. | — |
| C3 | Row 268 (Won't-Fix): inherited. | — |
| C5 | Row 269 (Defer): inherited; A15 makes it weigh more. | performance F1 |
| C6 | Row 270 (Defer): inherited. | — |
| C7 | ✅ Fixed ("planned" dropped from the lib and dev-cycle.sh). | FC Claim 25 |
| C8 | Row 271 (Won't-Fix): inherited. | — |
| C9 | ✅ Fixed (the `*)` arm now renders the near-miss message, which is CONSTRAINTS_AWK's only other output). | FC Claim 19 |
| C10 | Row 272 (Won't-Fix): inherited. | — |
| C11 | Row 273 (Defer): inherited. | — |
| C12 | Row 274 (Defer): inherited. | — |
| C13 | Row 275 (Won't-Fix): inherited. | — |
| C14 | ✅ Fixed (`status_of` removed). | FC Claim 36f |
| C15 | ✅ Resolved by A1/A2's fix (tree, parents and message now come from git). | FC 22 |

---

## 🔴 Must Fix

Issues that must be resolved before merge. Draft cannot pass review with any red items
unresolved.

No red items. (Iteration 1's R1 is resolved above; its residue is amber, see A12/A13 for why it was not re-escalated.)

---

## 🟡 Must Address

Issues that must be fixed or acknowledged by the author with justification for why they
stand. Each must carry a resolution or a **qualifying author note**: either (a) a
discoverable TODO, or (b) a concrete revisit trigger. A note with neither is not
qualifying.

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A12 | **A ticked task box or a short letter label hides a hard constraint while the line reads `constraints ok`.** The near-miss rule folds from the line's first ASCII letter (`:172` `sub(/^[^a-zA-Z]*/, "", s)`), so `- [x] H2:`, `- [X] H2:`, `a. H2:`, `i. H2:`, `Hard H2:`, `**Hard:** H2:` and `Note - H2:` all give `constraints ok 1-hard 0-soft` with H2 uncounted and its `success:` check skipped; an unticked `- [ ] H2:` is refused, so ticking the box turns a refused line into an uncounted one. The help states this first-letter rule correctly, so it is a design gap, not a doc error. This is the case Q-112 [1] asked to have reported (a hard constraint silently dropped under `ok`). The line still reaches the loop prompt verbatim, and no loop can write the file. Fix: strip a task box and short list labels before folding, and add the two shapes to T44; or record them in the help as accepted best effort. Not escalated: one core critic (fact-check r1 notes the same shapes as matching the literal rule). | Security | Medium | security-reviewer F1 (executed) | for-author | Q-112 [1] (best effort; asks for this report) | 🟡 Open | — |
| A13 | **The constraints help promises more than CONSTRAINTS_AWK enforces.** `:35-37` "Any other line whose letters and digits, from its first letter, start like h1 or s1 makes the file unreadable" holds only for ASCII outside code fences: a fenced `H2:` (skipped by `fence($0) { next }`, `:163`), Cyrillic `Н2:`, fullwidth `Ｈ2:`, `H²:`, `H٢:` and `&#72;2:` all give `constraints ok` with the line uncounted. `:33-35` "before the next constraint or heading" means a line starting `#` at column 0 (`:174` `/^#/`): a Setext heading or an indented `  ## Other` does not end a pending hard constraint, so a `success:` line from another section still satisfies it (and a `#tag` line does end one). Fence-skipping is the plan's grammar (plan `:204` reads the file "under FENCE_AWK") and look-alikes are Q-112's accepted best effort, so the fix is wording: "outside a code fence", "ASCII letters and digits, best effort", "a line starting #", plus a T44 case pinning the fenced line as `ok`. **Convergence:** fact-check (all 3 replicates) + api-consistency + security. Not escalated to 🔴: the executed corroboration shows the intended grammar, and the defect is the help's wording, which decision 031 caps at 🟡. | API contract / Docs | api Inconsistent; FC Mostly accurate; security Low | FC Claims 6, 8, 36a, 36b + api-consistency F1, F4 + security F2 (executed) | for-author | Q-112 [1] | 🟡 Open | — |
| A14 | **The lazy `shared_branches` call clobbers `BRIEF` mid-judgement.** `status_line` reads the queried brief with `brief_fields "$a"` (`:316`), then on the first call runs `shared_branches` (`:326`), which calls `brief_fields` on every brief on main (`:303`) and leaves the global `BRIEF` holding the last one (an instrumented copy showed `BRIEF[branch]` = `Branch: feat/z` while judging brief a). Output is correct today because nothing reads `BRIEF` after `:326`; U2's `--check` plans to run F31 and then read `BRIEF[paths]`. New with c143b929, so outside row 229's premise. Fix: a `branch_shared NAME` predicate computed before `brief_fields`, which also closes A5's remaining fail-open global. Convergence: security noted the same overwrite (not a regression today). Composed into X1. | Architecture | Coupling (High confidence) | architecture-review F1 (+ security note) | for-author | Row 229 (BRIEF global, Won't-Fix): premise changed | 🟡 Open | — |
| A15 | **`--status` now costs O(all briefs ever closed) per run.** c143b929's `shared_branches` reads every brief in `closed/` as well as `briefs/`, each through one `ls-tree -t` (which lists the whole directory) plus one `cat-file \| awk`. One argument, 3 open briefs and N closed: 553a50d5 ~70 ms at every N; c143b929 63, 346, 1,910 and 8,084 ms at N = 0, 50, 200, 500. The dev cycle moves every finished brief into `closed/` and nothing removes them (`skills/dev-cycle/SKILL.md:284`), so row 266's trigger ("more than 50 briefs on main") is reached in ordinary use and its rationale no longer holds. Fix: one `ls-tree -r` piped into one `cat-file --batch` (probe: 24 ms for 503 briefs), or re-defer with a trigger on the closed-brief count. Composed into X1. | Performance | Medium | performance-reviewer F1 (executed) | for-author | Row 266 (Defer): **premise changed** | 🟡 Open | — |
| X1 | **Composed root of A14 and A15:** `shared_branches` reads every brief through `brief_fields` (`:303` `if ! isbrief "${f/closed\//}" \|\| ! brief_fields "$f"; then continue; fi`), which sets the global `BRIEF` (architecture F1: "overwrites the global BRIEF with the last brief on main") and costs one `ls-tree -t` per brief (performance F1: "Each brief costs one ls-tree -t, and that listing grows with the brief count"). One batch read of all briefs into a local map, computed before `status_line`'s own `brief_fields`, fixes both. | Architecture / Performance | Composed (inherits Coupling / Medium) | Composition cross-check (fragments: A14, A15) | for-author | Rows 229, 266 | 🟡 Open | — |
| A16 | The `--status` marker help overlaps its skip clause. `:59-60` "Any other tip is working" omits that a `handoff:`-prefixed non-marker is a skip (`:340`; stated only at `:67-69`), and the skip clause omits that it applies only when the branch is at least one commit ahead (a 0-ahead `handoff:` tip prints `working`). `:58-59` "alone on its first line" omits that a whitespace-only second line is refused ("runs onto a second line") though git's subject is `handoff: ready`. All fail closed; U3's loop prompt should say to leave a truly empty line after the subject. | API contract / Docs | FC Mostly accurate; api Minor / Informational | FC Claim 14 (r3) + api-consistency F2, F5 | for-author | — | 🟡 Open | — |
| A17 | `:66-67` lists "another open brief … names the same branch" as a skip cause, but the skip applies only when the queried brief is itself open (`:327` `[[ "$st" == open && …`); a done or dropped brief sharing an open brief's branch prints `ok` (T28 asserts this). Fix: "for an open brief". | API contract / Docs | FC Mostly accurate (3/3); api Minor | FC Claim 16b + api-consistency F3 | for-author | — | 🟡 Open | — |
| A18 | The read_settings comment (`:196-197`) "POLICY is for --status and the gate, NEVER for the gate" reads as if the gate exists; it is planned (U2), so NEVER has no reader yet, and the `:199` SC2034 disable now also covers POLICY, which is read. Fix: "the planned gate". | Comment | FC Mostly accurate | FC Claim 20 (r3) | for-author | — | 🟡 Open | — |
| A19 | The bats comment "A ready marker's body is not read here (--marker reads blocked and stopped bodies)" (`test/scripts/build-loop-read.bats:254`) names `--marker`, a planned U3b mode not in the script. Fix: "the planned --marker". | Tests / comment | FC Mostly accurate | FC Claim 30 (r3) | for-author | — | 🟡 Open | — |

---

## 🟢 Consider

Advisory findings from contextual critics, single-critic suggestions, and improvement
opportunities. Not required to pass review.

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C16 | **Test gap G1 (high):** nothing tests the END `nosuccess` check (`:177-181`). Deleting it makes `- S1: a` / `- H1: b` read `constraints ok 1-hard 1-soft` with the suite green: a silent `ok` for a hard constraint with no success line. G3 (medium): a bare `success:` must not satisfy H1. Proposed: one T44 case `constraints '- S1: a' '- H1: b' '  success:'` closes both. | test-strategy G1, G3 (mutation run) | high / medium | for-author | Q-112 [1] report condition (applied to tests) | 🟢 Open |
| C17 | Test gap G2 (medium): the NUL-byte refusal (`:279`) is untested; without it `handoff: ready\n\0x` reads ready because `%B` truncates at the NUL. Proposed: a hash-object NUL marker in T7. | test-strategy G2 | medium | for-author | — | 🟢 Open |
| C18 | Test gap G4 (medium): F31's open-only filter (`:304`) is untested; removing it would skip an open brief whenever a done or dropped brief once named its branch. Proposed: edit T28's brief e to `Branch: feat/d` (no new lines). The proposed G1–G4 patch is +4 lines / 2 edited (426 → 430, at the Q-114 cap) and was checked against the four mutants. | test-strategy G4 | medium | for-author | — | 🟢 Open |
| C19 | Test gaps G5–G7 (low): the 1-character stopped reason, `Dispatched: 99` / explicit `0`, and a fenced `H2:` pinned as `ok` (ties to A13). | test-strategy G5–G7 | low | for-author | — | 🟢 Open |
| C20 | "a brief path, optionally under closed/" is spelled three ways (`:303` `${f/closed\//}`, lib `:161` and `:326` regexes). If they drift, `check_brief` fails toward a skip but `shared_branches` fails toward not counting a brief (fail-open for F31). One `(closed/)?` predicate in the lib. | architecture F2 | Minor | for-author | — | 🟢 Open |
| C21 | `shared_branches` skips any brief `brief_fields` cannot read (`:303`): an open brief whose blob is missing from the object store is not counted, so a same-branch brief prints `ok`. Needs object-store write access (outside the threat model); U2 should decide it on purpose and the help (`:66`) could say "readable". | architecture F3 + security F3 | Informational | for-author | — | 🟢 Open |
| C22 | `marker_kind` now forks more per marked tip (~6.8 ms vs 2.2 ms; ~2.5 ms for an ordinary tip); ≤40 ms per run at 9 loops. Pays for A1. | performance F2 | Informational | for-orchestrator-synthesis | — | 🟢 Open |
| C23 | The none-hard WHY reads "has 1 soft constraints" (`:262`). | api-consistency F6 | Informational | for-author | — | 🟢 Open |
| C24 | The two-tree object's skip reason is "it has no parent" (git stops parsing at the second `tree` line), not a reason naming the malformed header. Fails closed; the T7 comment explains it. | FC Claim 36c annotation, submitted 45a | Informational | for-author | — | 🟢 Open |
| C25 | Refuted endorsement (submitted Claim 45c, Incorrect, executed): security's "a leading-blank message reads working because marker_kind reads the subject as git does" is wrong on mechanism: git's `%s` is `handoff: ready`, the script takes `%B`'s empty first line. Outcome (`working`, fail-safe) and help (`:67-68`) agree; no code or doc change. Also 45b (Mostly accurate): an encoding header over an ASCII subject reads ready, matching what git prints. | Stage 2.5 (security endorsement, refuted by fact-check) | Incorrect (endorsement only) | for-orchestrator-synthesis | — | 🟢 Open |
| C26 | Override row 246's U1b test gaps (glob-form/"twice" reasons, review policy with a malformed never line, slots line for an absent/unread file, `-h`) are all still open at c143b929; the revisit trigger (U1c touches the file) is met. test-strategy recommends keeping them deferred with the trigger moved to U2's tests. | test-strategy G8–G11 | low | for-author | Row 246 (Defer): trigger met; needs a new trigger | 🟢 Open |
| C27 | Commit-message imprecisions in c143b929: the R1 bullet's near-miss sentence has A13's ASCII/fence gap (36a) and its heading sentence A13's `#`-only gap (36b); the A1 bullet says "instead of reading the raw object" though `cat-file commit` still reads it for the NUL check (36c). | FC Claims 36a–36c | Mostly accurate | for-author | Row 265 class (history only): inherited | 🟢 Open |

---

## ↩️ Considered Overrides

| Override (PR ref / Date) | Prior finding | Original → Override | Reason | This run's treatment |
|---|---|---|---|---|
| `feat/build-loop-u1c` / 2026-10-05 (row 266) | shared_branches quadratic in brief count (C1) | 🟢 → Defer (trigger: >50 briefs on main) | "Done briefs move to closed/" | **Premise changed**: closed/ is now scanned. Re-surfaced as A15 (Medium). |
| `feat/build-loop-u1a` / 2026-10-05 (row 229) | BRIEF as a global array | 🟢 → Won't-Fix | One parser | **Premise changed** for one use: the lazy call now overwrites BRIEF mid-judgement (A14). |
| `feat/build-loop-u1b` / 2026-10-05 (row 246) | Test gaps G7, G8, G9, G11 | 🟢 → Defer (trigger: U1c or U2 touching build-loop-read.bats) | 400-line cap | Trigger met; gaps still open (C26). |
| `feat/build-loop-u1c` / 2026-10-05 (rows 267, 268, 269, 270, 271, 272, 273, 274) | C2–C6, C8, C10–C12 | 🟢 → Defer / Won't-Fix | as logged | Inherited; premises unchanged (performance, api-consistency, security). Row 269 weighs more given A15. |
| `feat/build-loop-u1c` / 2026-10-05 (row 265) | Commit-message imprecisions (A11) | 🟡 → Won't-Fix | History only | Inherited; applied by substance to c143b929's own bullets (C27). |
| `feat/build-loop-u1c` / 2026-10-05 (row 275) | Unverifiable U3/U4 claim and timing | 🟢 → Won't-Fix | Load-dependent; checked in U3/U4 | Inherited: FC Claims 4, 9 (Unverifiable) and 34b ("about 1 ms", measured 1.4–3 ms). |
| `feat/build-loop-u0b` + `u1b` / 2026-10-05 (rows 209, 247) | origin/HEAD or symref naming a loop's branch | 🟢 → Defer (U3b `--state`) | Every resolve_main reader | Inherited; not re-tested (security). |
| `feat/build-loop-u1a` / 2026-10-05 (row 228) | case-block copies for main_entry's result words | 🟢 → Defer (U2's fourth caller) | Two callers | Inherited. |
| `feat/build-loop-u1b` / 2026-10-05 (rows 239, 240, 245, 256) | `--help` range; fixture git env; never-line status word; exact never line governs | 🟢 → Won't-Fix | as logged | Inherited. Security distinguishes row 256 from A12 (an uncounted line removes a check). |
| `feat/build-loop-u0b` / 2026-10-05 (row 201), `u0a` (row 212) | `-G` walk per brief; `pwd -P` per check | 🟢 → Defer / Won't-Fix | Within noise | Inherited. |

---

## ✅ Confirmed Good

| Item | Verdict | Evidence | Source | Legibility-target |
|---|---|---|---|---|
| For the crafted tips tested (duplicate parent, two trees, orphan, merge, non-empty, NUL in body or subject), `marker_kind` skips, and every parent count it reports matches `git rev-list --parents` | ✅ Confirmed (scoped: not grafts, shallow repos, or repo-local `i18n.logOutputEncoding`) | `scripts/build-loop.sh:276`: `read -ra p <<<"$(git rev-list --parents -n 1 "$1")"`. Submitted Claim 45a (executed) | security endorsement, verified by fact-check | for-orchestrator-synthesis |
| An open brief in `closed/` naming the same branch (case-folded) makes a `briefs/` brief skip, within one `--status` run with no separate setup call | ✅ Confirmed (scoped: readable brief-form files directly in `closed/`; not non-ASCII case folding) | `scripts/build-loop.sh:326`: `[[ -n "$SHARED_BRANCHES" ]] \|\| shared_branches`. Submitted Claim 46 (executed) | security endorsement, verified by fact-check | for-orchestrator-synthesis |
| The printed stopped reason is 1–120 bytes of 0x20–0x7E with no blank at either end, under caller locales C and C.UTF-8 | ✅ Confirmed | `scripts/build-loop.sh:291`: `LC_ALL=C grep -qxE '[!-~]([ -~]{0,118}[!-~])?'`. Submitted Claim 47 (executed) | security endorsement, verified by fact-check | for-orchestrator-synthesis |
| `--status` refuses a brief whose working-tree path is a symlink (or under a symlinked `briefs/`), per the help's "the path must also be plain in the working tree" | ✅ Confirmed (scoped: the argument path) | `scripts/build-loop.sh:43-44`: "the path must also be plain in the working tree, as --check-brief". FC Claim 10 (executed, 3/3) | Fact-check | for-orchestrator-synthesis |
| `--status` and `--settings` write nothing to the working tree or `.git` | ✅ Confirmed (scoped to the runs probed) | `scripts/build-loop.sh:72`: "Read-only: writes nothing". FC Claim 17 (executed: before/after hash of files and refs) | Fact-check | for-orchestrator-synthesis |

Cross-check: the closed/ row is narrowed to readable briefs because C21 (security F3, architecture F3) records that an unreadable open brief is not counted. The A14 overwrite does not contradict it (output unaffected today).

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
| 1 | `scripts/build-loop.sh:33-37`, `:161-183` | FC 6/8/36a/36b, security F1/F2, api F1/F4, test-strategy G1/G3/G7 | distinct defects: A12 (first-letter folding, design) and A13 (help wording for fences, ASCII, headings) are separate mechanisms; the test gaps are coverage, not root. |
| 2 | `scripts/build-loop.sh:298-329` | architecture F1/F2/F3, performance F1, security F3, FC 16b/24, api F3, test-strategy G4 | composed → X1 (A14 + A15 share the per-brief `brief_fields` read). C20, C21, A17, C18 are distinct. |
| 3 | `scripts/build-loop.sh:54-69`, `:270-293` | FC 14/22/36c, api F2/F5, security E1, submitted 45a–45c, performance F2 | distinct defects: wording (A16), reason text (C24), cost (C22), refuted endorsement (C25). |

---

To pass review: all 🔴 items must be resolved. All 🟡 items must be either fixed or
carry a qualifying author note (a discoverable TODO or a concrete revisit trigger; see
"Qualifying author note" in `skills/code-review/references/rubric.md`). 🟢 items are optional.
