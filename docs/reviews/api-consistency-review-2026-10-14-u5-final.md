Commit: b5eaedf6

# API Consistency Review: feat/build-loop-u5, final confirming pass (full branch)

**Scope:** `git diff main...HEAD` (main b279a2ba, HEAD b5eaedf6; 9 commits, 20 files)
**Date:** 2026-10-14
**Based on:** the final code-fact-check (k=3) results as summarised in the brief. These are known and not reported again here: Q-156's graft parenthetical; a commit-body miscount; "only docs, README.md, runs/ and archive/" omitting new top-level names; Q-103 [2] omitting own files and non-path refusals; Q-149's "one-line edit"; the slots wording (step 10 subtracts this session's loops, and step 8 leaves capped or stalled briefs uncounted); Q-151 [2]'s remedy naming only step 10; Q-156's "If the paste refuses" naming one cause (its content); the rubric marking A10 fixed although it was deferred. Prior reports: `docs/reviews/api-consistency-review-2026-10-14-u5-i1.md`, `-i2.md`; rubric `docs/reviews/code-review-rubric-2026-10-14-feat-build-loop-u5.md`.

The public surface here is the following: the settings-line grammar in `docs/dev-cycle.md`, which `scripts/build-loop.sh --settings` reads; the question slugs the orchestrator files, looks up and rewrites (`image-lag`, `constraints-doc-missing`, `merge-STEM-SHA12`); the step 0.1 release-entry contract; the questions-entry grammar from the global instructions; and the policy vocabulary (N rules, floor, never line, slots, own files) that the user reads to answer Q-103 and Q-149 to Q-156.

## Baseline Conventions

- **Settings lines.** `Key: value`, one copy outside code blocks, read from the default branch's commit (`scripts/build-loop.sh:19-60`). The skill's template (`skills/dev-cycle/SKILL.md:101-123`) and the repo file agree on the keys: policy, slots, never, and the reader roots and homes.
- **Gate rule names.** "The N rules, under either policy" and "the S rules, for a brief --status reads as self-merge" (`scripts/build-loop.sh:356-384`). The N rules include the mode check, which allows only 100644 and 100755 (`nrules`, `scripts/build-loop.sh:1145`). The floor is `floor()` in `scripts/lib/dev-cycle-read.sh:1997-2012`, which uses truthrule (instruction, dot, cycle, settings, user and record files), GATE_CODE, `docs/thoughts/`, and `docs/working/` and `docs/reviews/` files that are not the brief's own.
- **Dedupe predicates for orchestrator-filed entries** (`skills/dev-cycle/SKILL.md`). There are two forms. "unless an open one ..." is used at :282 (a quoted state refusal) and :368 (an `agent` entry). "unless WT's questions files hold one" is used at :293 (`image-off-main-C12`, which offers a lasting `[2] keep this image`) and :790 (`capped-STEM-N`, which offers `[1] keep`). The second form covers the archive, so a lasting answer is never asked again.
- **Questions grammar.** `### Q-NNN · slug`; Needs/Opened/Status; an options table; Blocks, Interim, and "If the answer differs". `you: terminal` entries carry a paste block. Precedent: Q-084 (`docs/working/questions.md`), which has both Interim and "If the answer differs".
- **Answered entries.** `**Answer (DATE, source):** [N] …` (questions-archive Q-139 to Q-148).

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `Build-loop slots: 3` | settings line | `Build-loop policy:`, `Self-merge never:`, template `Build-loop slots: 3` | `skills/dev-cycle/SKILL.md:106-110`; `scripts/build-loop.sh:31-32` | Consistent. The repo test asserts it (`build-loop-read.bats:81`; ran it, passes) |
| `Self-merge never: workflows/ … global-instructions/` | settings value | template `Self-merge never: none`; fixtures | `skills/dev-cycle/SKILL.md:110`; `scripts/build-loop.sh:33-39` | Consistent with the glob grammar. The test passes |
| `constraints-doc-missing` (step 10, Q-155) | orchestrator-filed slug | `image-lag`, `image-off-main-C12`, `capped-STEM-N` | `skills/dev-cycle/SKILL.md:293, 298, 790` | The name is consistent. Its dedupe predicate is not (F1) |
| `image-lag` as release entry (Q-156) | orchestrator-filed slug | step 0.1's `image-lag` | `skills/dev-cycle/SKILL.md:297-312` | Consistent. Q-156 now says that its M differs from step 0.1's (i2 F2 fixed) |
| `self-merge-never-scope` (Q-149) | question slug | `constraints-doc-missing`, `image-lag` | `docs/working/questions.md` | Consistent |
| `build-loop-c1…c5-*` (Q-150 to Q-154) | question slugs | each other | `docs/working/questions.md`, `questions-archive.md` | Consistent. `questions.sh check` passes (ran it) |
| "If the paste refuses:" (Q-156) | entry field label | "If the answer differs:" (Q-084, also `you: terminal`) | `docs/working/questions.md` Q-084 | Inconsistent (F3) |
| "the N rules (both policies)" (Q-103 [1]) | policy term | "The N rules, under either policy" | `scripts/build-loop.sh:356` | Consistent (i2 F3 fixed) |
| "counts against the slots" (Q-151) | policy term | dev-cycle.md "is not counted"; Rules' "holds a slot" | `docs/dev-cycle.md:40-44`; `skills/dev-cycle/SKILL.md:160` | Consistent (i2 F1 fixed). Option [2]'s heading "Holds the slot" remains, but its body says "counts against" |
| `(withheld: see SHA)` | entry placeholder | none | none (searched `skills/`, `scripts/`, `docs/working/` for "withheld") | New convention, set in step 0.1. Informational; not expanded |

## Findings

#### F1. Step 10 dedupes `constraints-doc-missing` on "an open one", so answering Q-155 [2] causes the entry to be filed again

**Severity:** Inconsistent
**Location:** `skills/dev-cycle/SKILL.md:770-772` (step 10); `docs/working/questions.md` Q-155 (option [2], Interim)
**Move:** 9 (idempotency), 3 (consumer contract)
**Confidence:** Medium-High. The predicate's text is unambiguous. I did not execute an orchestrator iteration.
**Legibility-target:** the user answering Q-155; the orchestrator at step 10 in later iterations

Evidence (step 10): "else one `you: judgment` entry, slug `constraints-doc-missing`, asking for `docs/constraints.md`, unless an open one with that slug exists". Evidence (Q-155 [2]): "**[2] Wait for the process** | Dispatch stays off until the roadmap item yields a way to write one". Evidence (Q-155 Interim): "step 10 files nothing more while this entry is open".

[2] is offered as a lasting answer. But once the user answers it (Status: ANSWERED, later archived), no open entry with that slug remains, `--settings` still prints `constraints missing`, and the next iteration's step 10 files a fresh `constraints-doc-missing` entry. That entry re-asks the answered question and reuses an archived slug. `questions.sh` does not check slug uniqueness, so nothing catches it. The skill already solves this for entries that offer a lasting "keep" answer. `image-off-main-C12` (`[2] keep this image`, :293) and `capped-STEM-N` (`[1] keep`, :790) both dedupe on "unless WT's questions files hold one", which covers the archive.

**Recommendation:** Use the same predicate as the other entries with a lasting answer: "unless WT's questions files hold one with that slug (open or answered)". Alternatively, reword Q-155 [2] to say that the entry is re-filed each time it is answered.

#### F2. The settings prose files symlinks and gitlinks under the self-merge floor, and leaves them out of the "under both policies" list, but the script refuses them under both policies

**Severity:** Minor
**Location:** `docs/dev-cycle.md:23-32` (Policy note); `docs/decisions/log.md` row 72 (D5); `workflows/codebase-onboarding.md:453`
**Move:** 3 (documentation drift)
**Confidence:** High
**Legibility-target:** a project owner on `review` predicting which branches reach them as merge entries and which end stopped

Evidence (dev-cycle.md): "none is on the gate's fixed floor (instruction files … files later runs read as truth such as `docs/decisions/` and `docs/constraints.md`, symlinks and gitlinks)". Later: "Under both policies the N rules refuse a change to `docs/constraints.md`, this file, the cycle's own files (…) or any brief beyond the brief's own Status line: under review such a branch is filed as stopped". Evidence (script, `scripts/build-loop.sh:356-359` and `nrules` :1145): "The N rules, under either policy: a path pathform refuses (a part starting .git, any case: .github/); a mode other than 100644 or 100755 on either side (a symlink or gitlink)". Evidence (SKILL.md :600-601, the review path): "A `refuse` verdict is filed as `stopped`".

Under `review`, a branch that adds a symlink, a gitlink or a `.git*` path is refused by `--check` and filed as stopped. dev-cycle.md lists those entries only as part of the floor, which is a self-merge rule, and its list of both-policy refusals reads as complete. A review-policy owner would therefore expect a merge entry. This is the same kind of drift as i2 F4: that fix completed the list of file names but not the list of entry kinds. The plan places symlinks in the floor (D5 item 5, and the lib comment "floor item 5 … is the caller's mode"), so row 72 matches the design but not where the rule is enforced.

**Recommendation:** In dev-cycle.md's "Under both policies" sentence, add "a symlink, gitlink or `.git*` path". Row 72 and onboarding can stay as they are, or take the same clause.

#### F3. Q-156 replaces "If the answer differs:" with "If the paste refuses:"

**Severity:** Minor
**Location:** `docs/working/questions.md` Q-156, last bullet
**Move:** 2 (naming against the grain)
**Confidence:** High
**Legibility-target:** the user scanning entries; any later tool or reader that keys on the grammar's bullet names

Precedent: `- **If the answer differs:**` used in `docs/working/questions.md` Q-084 (the other open `you: terminal` entry) and in every other open entry, following the global instructions' entry grammar.

Evidence: "- **If the paste refuses:** main changed a released path after M. …". `questions.sh check` passes, because it does not check bullet labels, so the deviation is purely one of convention. The content is useful (its incompleteness is a known fact-check item). Only the label departs from the grammar. Q-084 shows that a terminal entry can keep the standard label and put its failure handling in the body.

**Recommendation:** Rename the bullet to "**If the answer differs:** if the paste refuses, main changed …". Step 0.1 rewrites this body later, so no other text depends on the new label.

#### F4. The never-line prose says that "docs" can self-merge, but the floor refuses most of `docs/`

**Severity:** Informational
**Location:** `docs/dev-cycle.md:54-55`; echoed in Q-149 [1], Q-103 [2] and the plan's as-built note
**Move:** 3
**Confidence:** Medium. The sentence is qualified by "off the floor", and the brief's known item about omitted top-level names is a different gap.
**Legibility-target:** the user weighing Q-149 and Q-103 [2]

Evidence: "So in this repo self-merge can land only files outside those directories and off the floor: docs, `README.md`, `runs/` and `archive/`." Evidence (`floor()`, `scripts/lib/dev-cycle-read.sh:2001-2005`): it refuses `docs/decisions/`, `docs/human-author/`, `docs/thoughts/`, the cycle files, and every `docs/working/` and `docs/reviews/` path that is not the brief's own. The floor list in the Policy note names only `docs/decisions/` and `docs/constraints.md` ("such as"). A reader of Q-149 [1] ("self-merge lands only docs …") could therefore take "docs" to mean all of `docs/`, when it means `docs/` minus those areas, plus the brief's own working and review files.

**Recommendation:** Optionally write "other docs (not `docs/working/`, `docs/reviews/`, `docs/thoughts/` or the records, except the brief's own files)". Leaving it as written is defensible, because "off the floor" is already stated.

## Iteration 2 findings: status

| i2 | Status | Evidence |
|---|---|---|
| F1 Q-151 [1] "holds a slot" | Resolved | "Only a live or queued loop counts against the slots" |
| F2 Q-156's M vs step 0.1's M | Resolved | "(Step 0.1's own rewrite of this entry uses main's commit as M.)". `git diff --stat 659a1c61 b5eaedf6` touches only `docs/`, so "the merge's released trees equal M's" holds at HEAD. The gate-code list matches `git diff --name-only 8d0e660e 659a1c61 -- <GATE_CODE paths>` (3 files), as do the 28 non-docs paths |
| F3 "always-on rules" | Resolved | Q-103 [1] "the N rules (both policies)" |
| F4 both-policy refusal lists | Resolved for file names | dev-cycle.md lists constraints, settings, cycle files and briefs; onboarding adds `docs/constraints.md`. Entry kinds remain (F2 above) |
| F5 plan D5/F57 | Resolved | As-built note: "supersedes steps 11-13, and D5's 'In this repo' interim and F57's `workflows/`, where they differ" |

The iteration 1 fixes (onboarding never-line requirement, the step 10 slug, Q-153's prefix, "brief's own files", and Q-154's answer handle) still hold at HEAD.

## What Looks Good

- The settings file and the script agree. The repo-file `--settings` test passes (ran `bats -f "this repo"`), and the prose's glob rules (one path part, directory above, lower-cased), the malformed-turns-off rule and the 1-9 range for slots match `scripts/build-loop.sh:31-39`.
- Every CLI flag the docs and row 72 cite (`--start`, `--prompt --steal`, `--merge --approved`, `--check`, `--marker`, `--cycle-diff`, `--land-cycle`, `--state`, `--main-log`, `--settings`) is in the script's usage block.
- The D4 "pull-request route is not built" statement is now consistent in all three places: dev-cycle.md ("Review handoff. No line."), SKILL.md :600-601 and row 72. No stale "not built yet" or "planned unit" text remains outside `docs/reviews/` and the superseded seed (searched with rg).
- Onboarding's step 13 reference in dev-cycle.md and SKILL.md resolves to `### 13. Gate`. The new constraints-doc ask uses the same `H1:`/`success:`/`S1:` form as the `--settings` header and SKILL.md "Constraints".
- Q-149 to Q-156 follow the grammar: heading, Needs/Opened/Status, a four-column options table, and Interim. The index has been regenerated. Q-154 was archived with a well-formed Answer line.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Step 10 dedupes `constraints-doc-missing` on open entries only; answering Q-155 [2] re-files it | Inconsistent | `skills/dev-cycle/SKILL.md:770-772`; Q-155 | Medium-High |
| 2 | Symlinks, gitlinks and `.git*` paths are refused under both policies but documented only as floor | Minor | `docs/dev-cycle.md:23-32` | High |
| 3 | Q-156 "If the paste refuses:" vs the grammar's "If the answer differs:" | Minor | `docs/working/questions.md` Q-156 | High |
| 4 | "docs" called self-mergeable; the floor refuses most of `docs/` | Informational | `docs/dev-cycle.md:54-55` | Medium |

## Overall Assessment

The branch is consistent with the codebase's conventions on everything the two earlier iterations raised. The settings grammar, slugs, rule names and release-entry contract now match the script and SKILL.md, and the repo's own settings parse as intended under test. One contract inconsistency remains (F1). The step 10 slug added in this unit uses the "open entry" dedupe predicate, while the skill's other entries with a lasting answer use "held in the questions files". As a result, answering Q-155 [2] ("wait") will re-file the question every time, at a cost to the user's attention. It can be fixed in place in one clause. F2 and F3 are doc wording fixes of one line each, and F4 is optional. None of them changes what a script reads, and none blocks landing under the `review` interim.

## Goal-Alignment Note

The goal is for U5's docs to match the built code. They now do for the settings lines, flags, slugs and rule names. F2 is the one remaining doc-to-code gap: the both-policy refusals the script enforces are documented in less detail than the script applies them. F1 is a spec defect in SKILL.md text that this unit wrote, which interacts with an option this unit offered (Q-155 [2]). It is worth fixing before the orchestrator first runs here, which happens after Q-156's release.
