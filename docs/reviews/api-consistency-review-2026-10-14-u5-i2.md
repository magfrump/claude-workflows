Commit: c63da94d

# API Consistency Review: feat/build-loop-u5, iteration 2 (fix range)

**Scope:** `git diff 42414307..c63da94d` (commits 771a5d02, 57e26f6b, 87ca421e, c63da94d). main..42414307 was read for context only.
**Date:** 2026-10-14
**Based on:** the iteration 2 code-fact-check results for the fix range (k=1), as summarised in the brief. The brief marks these as known, so they are not reported again here: dev-cycle.md:29-31 "filed as stopped, not as a merge entry" holds for review only; slots also cap dispatch, and the SKILL.md template says "live loops at once"; the paste's `global-instructions/` comparison; the questions.sh marker wording; commit-message wording. Iteration 1 report: `docs/reviews/api-consistency-review-2026-10-14-u5-i1.md`.

The "public surface" here is the settings-line grammar in `docs/dev-cycle.md`, which `build-loop.sh --settings` reads. It also covers the question-entry slugs that the orchestrator files, looks up and rewrites (`image-lag`, `constraints-doc-missing`, `merge-STEM-SHA12`), the step-0.1 release-entry contract (C, M, the commit list, the paste), and the policy terms the user reads to answer Q-103, Q-149 and Q-151.

## Baseline Conventions

- **Question slugs.** Lowercase, hyphenated, and unique within the questions files. A slug that the orchestrator must recognise later is fixed in SKILL.md (`image-lag`, `image-off-main-C12`, `merge-STEM-SHA12`, `blocked-/stopped-/capped-STEM-N`). The plan's C-series questions use `build-loop-cN-<topic>` (Q-150 to Q-152, archived Q-154).
- **Gate rule names.** `scripts/build-loop.sh:356` defines "The N rules, under either policy" and "the S rules, for a brief --status reads as self-merge". The plan (`plan-build-loop-handoff.md:112`) and Q-150 [2] ("`--marker`, `--cycle-diff` and the N rules change") use the same names.
- **Own files.** The script calls them "one of its own files" / "the brief's own file" (`build-loop.sh:378-382`), keyed on the brief's stem.
- **Slots.** In SKILL.md:647-652, "D9's loop slots" are kept separate from the Rules' "holds a slot" (`SKILL.md:160`).
- **Release entry.** In step 0.1 (`SKILL.md:285-310`), "M" is "main's commit". The commit list is `log --first-parent C..M`. The paste is `cd A && test "$(git rev-parse HEAD)" = M && ./devcontainer-config/install.sh`.
- **Answered entries.** `**Answer (DATE, source):** [N] …` (questions-archive Q-139 to Q-148).

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `self-merge-never-scope` (Q-149) | question slug | `self-merge-never-workflows` (old), `constraints-doc-missing`, `image-lag` | `docs/working/questions.md` headings | Consistent. Fits the widened question. No stale reference outside `docs/reviews/` (grep) |
| `build-loop-c4-merged-branch-deletion` (Q-153) | question slug | `build-loop-c1-questions-writer`, `build-loop-c2-blocked-slot`, `build-loop-c3-blocked-wait`, `build-loop-c5-cycle-cost` | `docs/working/questions.md`, `questions-archive.md` | Consistent. Fixes i1 F6. Index regenerated and `questions.sh check` passes |
| `constraints-doc-missing` (step 10) | orchestrator-filed slug | `image-lag`, `image-off-main-C12` | `skills/dev-cycle/SKILL.md:297-298` | Consistent. Matches Q-155's heading. Fixes i1 F5 |
| `Self-merge never: workflows/ … global-instructions/` | settings value | `Self-merge never: none` (template), test fixtures `workflows/ hooks/*.sh …` | `skills/dev-cycle/SKILL.md:110`, `test/scripts/build-loop-read.bats:113` | Consistent with the list grammar. The repo-file test passes (ran `bats -f "this repo"`) |
| "always-on rules" (Q-103 [1]) | policy term | "the N rules" | `scripts/build-loop.sh:356`, `docs/working/questions.md` Q-150 [2] | Inconsistent (F3) |
| "the brief's own files (named by its stem)" | policy term | "one of its own files", `ownfile` | `scripts/build-loop.sh:378-382`, `scripts/lib/dev-cycle-read.sh:1949` | Consistent. Fixes i1 F7 |
| "M" in Q-156 (a branch commit) | release-entry field | step 0.1's "M main's commit" | `skills/dev-cycle/SKILL.md:286-287` | Inconsistent (F2) |
| `(withheld: see SHA)` | entry placeholder | none | none (searched `skills/`, `scripts/`, `docs/working/` for "withheld") | New convention, set deliberately in step 0.1. Informational only; not expanded |
| Q-149 options `[1] Wide`, `[2] workflows/ only`, `[3] None` | option labels | Q-150 to Q-152 `[1] <default> (built)` | `docs/working/questions.md` | Consistent (the default is marked "as written") |

## Findings

#### F1. Q-151 option [1] still says "Only a live loop holds a slot" (i1 F2, half-fixed)

**Severity:** Minor
**Location:** `docs/working/questions.md:405` (Q-151 [1])
**Move:** 2 (naming against the grain)
**Confidence:** High
**Legibility-target:** the user answering Q-151; the orchestrator reading the Rules and the entry together

Precedent: "A brief holds a slot" (a brief whose branch is kept out of cleanup), set apart from "D9's loop slots, not the Rules' 'holds a slot'" in `skills/dev-cycle/SKILL.md:160` and `:647-649`.

Evidence (Q-151 [1]): "Only a live loop holds a slot; a blocked item re-enters the queue on its existing branch once answered". Evidence (dev-cycle.md:54-57, fixed): "how many briefs the queue holds for build loops at once … a blocked, stopped or ready-for-review one waits on you and is not counted."

Iteration 1 asked for the fix in "both places". The settings file was fixed. Q-151 still uses the Rules' term with D9's meaning, so the entry and SKILL.md's Rules give opposite answers to "does a blocked brief hold a slot?". (Plan D9, `plan-build-loop-handoff.md:94`, uses the same phrase, but the plan is design history and the entry's Read line points to it.)

**Recommendation:** In Q-151 [1], replace the phrase with "a blocked item is not counted against `Build-loop slots:`", which is the wording dev-cycle.md now uses. If you want Q-151's "Holds the slot" heading to match as well, reword [2] to "Counts against the slots".

#### F2. Q-156's M is a branch commit, while step 0.1 (which owns the slug) defines M as main's commit, and the entry's own commit list does not match its M

**Severity:** Minor
**Location:** `docs/working/questions.md` Q-156 (the M paragraph, the "First-parent commits after C" list, the paste); `skills/dev-cycle/SKILL.md:286-287, 299-306`
**Move:** 3 (consumer contract), 2 (a field name reused with a new meaning)
**Confidence:** High
**Legibility-target:** the user pasting on the host; the next cycle's step 0.1, which "has its body rewritten"

Precedent: "C and A are the `commit=` and `assembled_from=` lines … M main's commit" and "every first-parent commit after C as a list item (`hg -C MAIN_WT log --first-parent --format='%h %s' C..M`" in `skills/dev-cycle/SKILL.md:286-301`.

Evidence (Q-156): "M is `771a5d028e8ef8a61253ad2f167ab421225d5af2`, the last commit on `feat/build-loop-u5` that changes anything the release installs". That list's last item is "the merge of `feat/build-loop-u5`". But `git log --first-parent 8d0e660e..771a5d02` lists the branch's own commits (771a5d02, 42414307, 2846f9fa, 92fa6e52) and then main's. It does not include the merge, which comes after M. The paste now compares released directory trees at HEAD against M. That is a third paste form, alongside step 0.1's `test HEAD = M` and iteration 1's form.

Behaviourally, the paste is sound, and stronger than before. It refuses when HEAD is not main, and it refuses when any released directory differs from M's tree. That fixes i1 F3's unpinned paste. The inconsistency is in the contract. The entry says its slug is step 0.1's, but it uses "M" and "C..M" with a different meaning. When step 0.1 next rewrites the body, M becomes main's tip and the paste reverts to `test HEAD = M`, which refuses on any later docs-only commit to main that this entry's tree check would accept. So the two forms disagree on when a release is allowed.

**Recommendation:** Pick one of two fixes. You can give Q-156's commit a distinct name ("R, the last branch commit that changes a released path") and say the tree check stands in for step 0.1's `HEAD = M` test until the next rewrite. Or you can fill in M after the merge, as the merge commit on main, so the list and the paste match step 0.1. Either way, make the list's endpoint agree with the SHA the entry names.

#### F3. "always-on rules" in Q-103 [1] coins a third name for the N rules

**Severity:** Minor
**Location:** `docs/working/questions.md:121` (Q-103 [1]); compare `docs/dev-cycle.md:29` ("Under both policies") and `workflows/codebase-onboarding.md:453` ("stopped under either policy")
**Move:** 2
**Confidence:** High
**Legibility-target:** the user reading Q-103 next to Q-150 and `--check`'s output

Precedent: "The N rules, under either policy" used in `scripts/build-loop.sh:356`. The same term appears in `docs/working/questions.md` Q-150 [2] ("`--marker`, `--cycle-diff` and the N rules change") and in `docs/working/plan-build-loop-handoff.md:112`.

Evidence (Q-103 [1]): "Every `ready` branch the always-on rules pass gets one merge entry". A reader of the open entries meets "N rules" in Q-150 and "always-on rules" in Q-103, two entries apart, with nothing to say they are the same set. The prose forms in dev-cycle.md and onboarding ("under both/either policy") are descriptions rather than names, and they are fine.

**Recommendation:** Write "the N rules (applied under either policy)", or keep the descriptive wording and drop the coined name: "Every `ready` branch `--check` does not refuse under either policy".

#### F4. The prose lists of what both policies refuse do not match the N rules or each other

**Severity:** Minor
**Location:** `docs/dev-cycle.md:29-31`; `workflows/codebase-onboarding.md:453`
**Move:** 3 (documentation drift; residue of i1 F4)
**Confidence:** High
**Legibility-target:** a project owner predicting which branches come to them as stopped rather than as merge entries

Evidence (script, `build-loop.sh:362-366`): "the dev cycle's own files (the roadmap, the questions files, the idea log, docs/dev-cycle.md, anything under docs/working/briefs/ or docs/working/cycles/ …) and docs/constraints.md". Evidence (dev-cycle.md): "a change to `docs/constraints.md`, this file, the questions files, the roadmap or another brief is refused". Evidence (onboarding): "a branch that changes the cycle's own files is stopped under either policy".

dev-cycle.md reads as a complete list but leaves out the idea log and `docs/working/cycles/`. It also says "another brief" when the rule covers the brief's own file too (only its Status line may change, open to done). Onboarding says "the cycle's own files" and leaves out `docs/constraints.md`, which the script lists separately. These are two lists of the same rule, each incomplete in a different way. The core contract (refused under either policy) is now stated in both documents, which resolves i1 F4's main point.

**Recommendation:** In dev-cycle.md, say "the cycle's own files (the questions files, the roadmap, the idea log, this file, the briefs and cycle records) or `docs/constraints.md`". In onboarding, add "or `docs/constraints.md`".

#### F5. Plan D5 "In this repo", F57 and step 11 still state the `workflows/`-only interim with no pointer to the as-built note

**Severity:** Informational
**Location:** `docs/working/plan-build-loop-handoff.md:75` (D5), `:175` (F57), `:346`, `:354` (step 11 bullets)
**Move:** 3 (documentation drift)
**Confidence:** Medium. The plan is a design record, and Q-149's body says "The plan assumed …"
**Legibility-target:** a reader who follows Q-149's Read line ("plan D5 'In this repo' and F57")

Evidence (D5): "The interim is `Self-merge never: workflows/` in this repo's settings". Evidence (F57): "`Self-merge never:` (interim `workflows/` in this repo; entry in U5)". Evidence (as-built note, `:358`): "supersedes steps 11-13 where they differ". That note covers the step 11 bullets but not D5 or F57. Q-149 sends readers to D5 and F57 first. Q-149's own body corrects them, so the drift is bounded.

**Recommendation:** Optionally append "(widened in U5: see step 13's as-built note and Q-149)" to D5's "In this repo" bullet and to F57's mitigation cell. Leaving them as written is defensible for a dated design record.

## Iteration 1 findings: status

| i1 | Status | Evidence |
|---|---|---|
| F1 onboarding omits the never-line requirement | Resolved | onboarding:453 "its `Self-merge never:` line, which self-merge requires: `Self-merge never: none` for an empty list" |
| F2 "holds a slot" reused | Partly resolved | dev-cycle.md:54-57 fixed; Q-151 [1] unchanged (F1 above) |
| F3 Q-156 paste unpinned | Resolved in behaviour | M pinned to a literal SHA, plus a per-directory tree check. The contract mismatch is in F2 above |
| F4 both-policy refusals undocumented | Resolved (core) | dev-cycle.md:29-31, Q-103 [1], onboarding. Lists still differ (F4 above); "filed as stopped" for review only is a known fact-check item |
| F5 step 10 slug | Resolved | SKILL.md:768-770 "slug `constraints-doc-missing` … unless an open one with that slug exists" |
| F6 Q-153 prefix | Resolved | `### Q-153 · build-loop-c4-merged-branch-deletion`; index updated; `questions.sh check` passes |
| F7 "loop's own files" | Resolved | dev-cycle.md:25-26 "one of the brief's own files (named by its stem)" |
| F8 Q-154 answer handle | Resolved | "**Answer (2026-10-04, in session; plan D12; filed 2026-10-14):** [1], a full cycle …" |

## What Looks Good

- The never line, its test assertion (`build-loop-read.bats:90`), Q-149's options, the plan's as-built note and Q-103 [2]'s cost column all name the same ten directories and the same remainder ("docs, `README.md`, `runs/` and `archive/`"). The repo-file `--settings` test passes against the new line.
- Slug renames are complete. `self-merge-never-workflows` and `merged-branch-deletion-rule` no longer appear anywhere outside `docs/reviews/`. Roadmap lines 61, 64 and 124 and decision-log row 72 refer to entries by ID only, and row 72 describes the never line generically ("plus a per-project `Self-merge never:` line"), so nothing there went stale.
- The settings paragraph now separates who reads the lines (the scripts, from main's commit) from how the orchestrator reads them (through `--settings`), which matches the script.
- Splitting refusals into three outcomes (path refusal falls to review, conflict is filed as stopped, environment refusal is retried) matches SKILL.md's verdict handling.
- Q-149's "If the answer differs" now names both places to edit (the settings line and its bats assertion), which matches the test it would otherwise break.
- Step 0.1's withheld rule fixes the placeholder form once, so later rewrites of `image-lag` stay parseable.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Q-151 [1] still uses "holds a slot" with D9's meaning | Minor | `docs/working/questions.md:405` | High |
| 2 | Q-156's M is a branch commit; step 0.1's M is main; the list ends past M | Minor | `docs/working/questions.md` Q-156; `skills/dev-cycle/SKILL.md:286-306` | High |
| 3 | "always-on rules" vs the established "N rules" | Minor | `docs/working/questions.md:121` | High |
| 4 | Both-policy refusal lists incomplete and mutually different | Minor | `docs/dev-cycle.md:29-31`; `workflows/codebase-onboarding.md:453` | High |
| 5 | Plan D5/F57 still say interim `workflows/` | Informational | `docs/working/plan-build-loop-handoff.md:75,175` | Medium |

## Overall Assessment

The fix range is consistent with the codebase's conventions on everything iteration 1 raised at Inconsistent severity. The onboarding contract and slug pinning are fixed, both renames are complete with no stale references, and the widened never line agrees across the settings file, its test, Q-149, Q-103 and the plan's as-built note. What remains is four Minor wording residues and one Informational. Each can be fixed in place with a sentence or two, and none changes what any script reads. The one with real consumer impact is F2. Q-156 now uses "M" differently from the step that owns and rewrites the entry, so the release allowed by this hand-written body and the one allowed by the next orchestrator rewrite differ. Fixing F1 and F3 would make the open questions use the same vocabulary as SKILL.md and the script.

## Goal-Alignment Note

The goal is for U5's docs to match the built code. The fix range moves the docs closer to the code: the never line, the own-files wording, the refusal outcomes and the step 10 slug now match `build-loop.sh`. The findings above are doc-to-doc and doc-to-skill drift, not doc-to-code drift, except that F4 lists fewer N-rule paths than the script enforces. None blocks landing under the `review` interim.
