Commit: b516af2

# Code Review Rubric

**Scope:** `review/q085` vs `main` (iteration 1 full branch; iteration 2 `--loop-pass --range 49a3dbb..b516af2`) | **Reviewed:** 2026-09-28 | **Status: 🟡 CONDITIONAL PASS** — 3 amber item(s) awaiting resolution or justification (iteration 2; fixed in the iteration-2 fix commit)

Naming: this is the canonical rubric `code-review-rubric-2026-09-28-review-q085.md`, prefixed `q085-` per the batch brief (four items reviewed in parallel). Loop ranges are therefore passed explicitly with `--range`, not computed from the canonical name. Delivery mode: self-read (the enclosing files, `docs/decisions/log.md` at 97 KB, exceed the 25k-token budget). Skill texts were given to sub-agents by absolute path with an instruction to read them in full, not pasted inline.

Iteration log:
- Iteration 1 (full scope, 49a3dbb): fact-check k=1 (20 claims: 0 Incorrect, 4 Stale, 3 Mostly accurate, 13 Verified); security and api-consistency ran; performance gated off. No behavioral red, so no short-circuit.
- Iteration 2 (incremental, 49a3dbb..b516af2): fact-check k=1 (17 claims: 0 Incorrect, 1 Stale, 2 Mostly accurate); security and api-consistency ran; performance gated off. Iteration-1 A1-A6 and C1-C4 verified resolved; no regressions except B-rows below. Fix-drift lite check on the iteration-1 fix: FINDINGS: NONE.

---

## 🔴 Must Fix

None.

---

## 🟡 Must Address

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | `guides/pr-prep-quick-ref.md:11` and `guides/completion-signals.md:82` still state the old ~500-line advisory with an agent-granted "unsplittable / documented why not" escape | Consistency | Stale; Inconsistent (High) | Fact-check C6, C7; api-consistency 1; security 3 | for-author | — | Fixed (iter-1 fix commit) | — |
| A2 | code-review's "split PR" next action (`skills/code-review/references/chat-synthesis.md:140`) counts the whole diff, review artifacts included, against 500 | Consistency | Stale; Inconsistent (Medium) | Fact-check C10; api-consistency 2; security 3 | for-author | — | Fixed | — |
| A3 | Step 0's comment (`workflows/pr-prep.md:43`) says its total feeds step 1a; step 1a now runs its own count (15 vs 12 on this branch) | Consistency | Stale | Fact-check C11; api-consistency 4 | for-author | — | Fixed | — |
| A4 | The /away split record in 1a and row 62 omits the commit-body `Notes:` line that `review-fix-loop.md:52` requires | Consistency | Mostly accurate | Fact-check C14; api-consistency 5 | for-author | — | Fixed | — |
| A5 | Row 62 quotes the old step 1a text as "~500 lines, consider splitting", which is not verbatim | Docs | Mostly accurate | Fact-check C1 | for-author | — | Fixed | — |
| A7 | Empty, unset, invalid or option-shaped `BASE` (or `BASE=HEAD`) makes the gate print 0 and pass; the harness does not keep shell variables between calls (`workflows/pr-prep.md:89-91`, executed) | Security | Low (regression of C1's class) | security iter2 F1 | for-author | — | Fixed (one command: `rev-parse --verify --end-of-options`, not-HEAD check, loud error; executed from root and `skills/`) | Tiered 🟡 though Low: it is a silent fail-open of the gate |
| A8 | `chat-synthesis.md:128` still names `git diff --stat` as the next-action ladder's size input, while rule 2 uses step 1a's count | Consistency | Stale; Minor | FC iter2; api iter2 1; security iter2 F3 | for-author | — | Fixed | — |
| A9 | The waiver must cite "the `questions.md` entry … ANSWERED", but answered entries are archived to `questions-archive.md`; the quick-ref omits the citation; the entry is agent-editable | Consistency | Mostly accurate; Minor; Informational | FC iter2; api iter2 2, 3; security iter2 F2 | for-author | — | Fixed (cite by `Q-NNN` in either file, quote the user's answer verbatim; quick-ref and row 62 aligned) | — |
| A6 | Row 62's "+3,613 code lines" does not reproduce under the new counting rule (3,593 insertions / 3,628 added+removed outside `docs/`) | Docs | Mostly accurate | Fact-check C3 | for-author | — | Fixed (~+3,600) | — |

---

## 🟢 Consider

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | The gate's pathspec `-- . ':(exclude)docs/'` is cwd-relative: prints 12 from the root, 0 from `skills/`, so the cap silently passes from a subdirectory (executed) | security 1 | Low | for-author | — | Fixed (`':(top)' ':(top,exclude)docs/'`, verified 12 from root and `skills/`) |
| C2 | The waiver is proved only by the PR description the gated agent writes itself | security 2 | Low | for-author | — | Fixed (waiver must cite its ANSWERED `Q-NNN`) |
| C3 | The gate always counts against `main`, but 1b lets a unit open stacked before the one below merges, so the upper unit double-counts and re-splits | api-consistency 3 | Minor | for-author | — | Fixed (`BASE` variable; 1b points to it) |
| C4 | "hard cap: ~400" has no exact trigger | api-consistency 6 | Informational | for-author | — | Fixed (gate fires above 400; "~" marks a round number) |
| C5 | Row 61 still says A4 "awaits the user's number" with no pointer to row 62 | api-consistency 7 | Informational | for-author | — | Won't-Fix (override-log row) |
| C7 | Commit b516af2's `Notes:` says "Deletions still count, as the user's rule says; raised as a question": counting deletions is the agent's reading, and no `Q-NNN` was filed | FC iter2 (Mostly accurate) | Mostly accurate | for-author | — | Won't-Fix (override-log row; corrected in the next commit's body) |
| C6 | Excluding all of `docs/` also drops non-markdown files there (`docs/human-author/prompts.ts`, `docs/working/scratch/*.py`) from the count | security 4 | Informational | for-author | — | Won't-Fix (override-log row) |

---

## ↩️ Considered Overrides

No prior overrides matched this diff.

---

## ✅ Confirmed Good

| Item | Verdict | Evidence | Source | Legibility-target |
|---|---|---|---|---|
| Gate command counts added+removed lines outside top-level `docs/`, binaries as 0, renames by changed lines | ✅ Confirmed | executed in worktree: prints 12 = `9 3 workflows/pr-prep.md`; scratch-repo edge cases (fact-check C12, `executed`) | Fact-check C12 | for-orchestrator-synthesis |

The security critic's routed endorsement (enforcement files all sit under `devcontainer-config/`, so the `docs/` exclusion cannot hide one) is *pending execution verification*: Stage 2.5 is skipped on a `--loop-pass`.

---

## ⚠️ Unverified Findings

All findings' evidence resolved.

---

## ⏭️ Skipped Core Critics

| Critic | Reason | Signal |
|---|---|---|
| performance-reviewer | No fact-check claims or diff content in domain | Diff is 3 markdown files; the only executable content is one `git diff --numstat | awk` sum run once per unit |

Contextual critics: none selected (no module-structure change, no manifest, no UI, 3 files / 15 lines).

---

## 🧩 Composition check

| Cluster | File / lines | Fragments | Disposition |
|---|---|---|---|
| 1 | `workflows/pr-prep.md:86-92` | FC C12, security 1, api 3, api 6 | distinct defects: cwd dependence, base choice and threshold wording each state their own mechanism and fix |
| 2 | `guides/*`, `chat-synthesis.md:140` | FC C6/C7/C10, api 1/2, security 3 | distinct defects: one stale statement per file, each fixed in place |

---

To pass review: all 🔴 items must be resolved. All 🟡 items must be either fixed or
carry a qualifying author note (a discoverable TODO or a concrete revisit trigger; see
"Qualifying author note" in `skills/code-review/references/rubric.md`). 🟢 items are optional.

## Escalations (orchestrator)

- Q-085 is still OPEN in `docs/working/questions.md` on this branch; it is ANSWERED only on `answers-2026-09-28`. Row 62 and the proposal note depend on that branch merging. Not fixed here (another unit owns `questions.md`).
- User judgment: whether deletions should count toward the cap (a pure dead-code deletion counts in full). Raised by api-consistency as a question; the rule is unchanged.
