Commit: 42414307

# API Consistency Review — feat/build-loop-u5 (U5: docs, settings, questions), iteration 1

**Scope:** `git diff main...HEAD` on `feat/build-loop-u5` (12 files: `docs/dev-cycle.md`, `docs/decisions/log.md` row 72, `docs/roadmap.md`, `docs/working/questions.md`, `docs/working/questions-archive.md`, brief/plan/research/seed status lines, `skills/dev-cycle/SKILL.md` step 0.1, `workflows/codebase-onboarding.md` step 13, `test/scripts/build-loop-read.bats`)
**Date:** 2026-10-14
**Based on:** Stage 1 code-fact-check (k=1) summarised in the brief. Its Incorrect and Mostly-accurate items (scripts reaching sessions only through a release, the row 70/72 mismatch in the plan, Q-103's R8 list and "also routed here" list, "only through --settings", "refused self-merge falls through", slot counting in step 8, the F37 detail) are known and are not reported again here.

## Baseline Conventions

The consumer-facing contracts in this diff are text grammars rather than code APIs. Their owners:

- **Settings keys** in `docs/dev-cycle.md`. The grammar is owned by `scripts/build-loop.sh`'s header (lines 19-73) and `read_settings` (lines 785-842). A value counts only from an exact line: `Build-loop policy: self-merge|review`, `Build-loop slots: [1-9]`, `Self-merge never: GLOB ...|none`, `Reader roots:`/`Reader homes:`. Copies are detected by case-folded letters. Self-merge also requires a valid never line (`build-loop.sh:818-819`). `skills/dev-cycle/SKILL.md:101-124` ("Project settings") carries a template that includes `Self-merge never: none`.
- **Gate rules.** The N rules apply under both policies (`build-loop.sh:355-367`, `nrules` at 1141-1166) and refuse the cycle's own files and `docs/constraints.md`. The S rules apply to self-merge only (`srules`, 1203-1215): floor, then never globs, then the allowlist of `Paths:` plus the brief's own files (`ownfile`, lib `dev-cycle-read.sh:1949-1956`, "A brief's own files").
- **Questions entries.** The global grammar is `### Q-NNN · slug`, the Needs/Opened/Status line, the four-column options table, then Blocks / Interim / If the answer differs. A `you: terminal` entry carries one paste block. Slugs are lower-case hyphen runs, and series often share a prefix (`u4a-…`, `u4b1-…`, `q089-…`). Machine-pinned slugs are `image-lag`, `image-off-main-C12`, `merge-`/`merge-gate-STEM-SHA12`, and `blocked-`/`stopped-`/`capped-STEM-N` (SKILL.md steps 0.1 and 7). Answered entries open with `**Answer (DATE, source):** [N] …`.
- **Terminology.** SKILL.md separates D9's *loop slots* from the Rules' *"A brief holds a slot"* (SKILL.md:160-163, 645-646).

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `Build-loop slots: 3` | settings line | `Build-loop policy:`, `Reader roots:`; template `Build-loop slots: 3` | `scripts/build-loop.sh:35-36,822-825`; `skills/dev-cycle/SKILL.md:108` | Consistent. `--settings` prints `slots 3 set` (bats test passes) |
| `Self-merge never: workflows/` | settings line | template `Self-merge never: none`; header grammar | `scripts/build-loop.sh:37-44`; `SKILL.md:110` | Consistent. `globform` accepts it and prints `never workflows/ set` |
| "Review handoff" (bullet, no line) | settings key (documented absent) | SKILL.md:595 "`Review handoff: pull request` route is not built"; plan:59 | `skills/dev-cycle/SKILL.md:595`; plan as-built :358 | Consistent. All three say it is not built |
| "holds a slot" (Slots bullet; Q-151 [1]) | term | SKILL.md "**A brief holds a slot**" (Rules); "D9's loop slots, not the Rules' 'holds a slot'" | `skills/dev-cycle/SKILL.md:160,645-646` | Inconsistent. Reuses the Rules' term for D9's meaning (F2) |
| "the loop's own files" | term | "one of its own files" / "A brief's own files" | `scripts/build-loop.sh:382,1214`; `scripts/lib/dev-cycle-read.sh:1949` | Inconsistent. Owner is the brief, not the loop (F7) |
| `merge-STEM-SHA12` / `merge-gate-STEM-SHA12` (dev-cycle.md, Q-103, row 72) | slug | the same in step 7 | `skills/dev-cycle/SKILL.md:587-588` | Consistent |
| `[1] merge` | option label | **[1] merge**, **[2] drop**, **[3] changes needed** | `SKILL.md:593` | Consistent |
| `image-lag` (Q-156) | slug | step 0.1 `image-lag` | `SKILL.md:298` | Consistent: same slug, same Needs (`you: terminal`), so step 0.1 rewrites rather than duplicates. The paste deviates (F3) |
| `self-merge-never-workflows` (Q-149) | slug | `dev-cycle-build-loop-policy`, `q089-escalate-merge` | `docs/working/questions.md` | Consistent |
| `build-loop-c1-questions-writer`, `-c2-blocked-slot`, `-c3-blocked-wait`, `-c5-cycle-cost` | slug | `u4a-asked-binding-residue`, `u4b1-stop-path-worktree-remove` (series prefix) | `docs/working/questions.md`, `questions-archive.md` | Consistent among themselves |
| `merged-branch-deletion-rule` (Q-153, plan C4) | slug | its C-series siblings `build-loop-cN-…` | `docs/working/questions.md` (Q-150..152), archive Q-154 | Inconsistent. Drops the series prefix (F6) |
| `constraints-doc-missing` (Q-155) | slug | step 10's "one `you: judgment` entry asking for `docs/constraints.md`, unless an open one does" | `SKILL.md:765-766` | No pinned slug to match (F5) |
| "release entry" | term | step 0.1 "which is also the release entry" | `SKILL.md:298-299`; Q-103 F58; plan:346 | Consistent |
| "never line" | term | header "valid never line", SKILL.md:123 "A malformed never line" | `build-loop.sh:24-25`; `SKILL.md:123` | Consistent |
| `docs/constraints.md` `H1:`/`S1:`/`success:` (onboarding, Q-155) | file grammar | `CONSTRAINTS_AWK` / header "constraints" | `build-loop.sh:45-53,722-744`; `SKILL.md:126-129` | Consistent |

## Findings

#### F1. Onboarding step 13 does not say that self-merge needs a valid `Self-merge never:` line

**Severity:** Inconsistent
**Location:** `workflows/codebase-onboarding.md:453`
**Move:** 3 (consumer contract / documentation drift)
**Confidence:** High
**Legibility-target:** a user or agent onboarding a project whose `docs/dev-cycle.md` predates the template

Evidence (onboarding): "may the autonomous build loops … merge on their own (`self-merge`; it covers only paths a brief lists that are outside …, plus any the project adds to `Self-merge never:`) … Record it as `Build-loop policy: <value>` in `docs/dev-cycle.md`, creating the file from the template … if missing."
Evidence (script, `build-loop.sh:818-819`): `POLICY_LINE="policy review unset: line ${first[policy]} reads self-merge, but there is no valid Self-merge never: line (\"Self-merge never: none\" for an empty list), so self-merge is off"`

The onboarding text presents the never line as optional ("any the project adds"). The template supplies `Self-merge never: none` only when the file is created. A project that already has a `docs/dev-cycle.md` without the line, such as every project onboarded before U5, gets `review`, and nothing in the onboarding text says why. `docs/dev-cycle.md:29-30` does state the requirement ("`self-merge` also needs a valid never line"), so the two documents disagree.

**Recommendation:** In step 13, add that `self-merge` also needs a `Self-merge never:` line (`none` for an empty list), and that the setter should add one if the file lacks it.

#### F2. "holds a slot" reuses the Rules' term with D9's meaning

**Severity:** Minor
**Location:** `docs/dev-cycle.md:30-32`; `docs/working/questions.md` Q-151 option [1]
**Move:** 2 (naming against the grain)
**Confidence:** High
**Legibility-target:** the orchestrator reading SKILL.md and the settings file together; the user answering Q-151

Precedent: "A brief holds a slot" (an open brief whose branch is kept out of cleanup), set apart from D9's loop slots in `skills/dev-cycle/SKILL.md:160-163` and `:645-646` ("D9's loop slots, not the Rules' 'holds a slot'").

Evidence (dev-cycle.md): "Only a live dispatched loop holds a slot; a blocked, stopped or ready-for-review one does not." Evidence (Q-151 [1]): "Only a live loop holds a slot". In SKILL.md's Rules, a blocked or ready brief does hold a slot, because its branch stays out of cleanup. A reader who takes the settings file at its word and then reads the Rules gets two answers to "does a blocked brief hold a slot?"

**Recommendation:** Say "uses one of the loop slots" or "counts against `Build-loop slots:`" in both places, which is the phrasing SKILL.md:645 uses.

#### F3. Q-156's paste departs from step 0.1's pinned paste form

**Severity:** Minor
**Location:** `docs/working/questions.md` Q-156, the bash block
**Move:** 3 (consumer contract)
**Confidence:** High
**Legibility-target:** the user pasting on the host; the next cycle's step 0.1, which rewrites this body

Evidence (Q-156): `test "$(git rev-parse HEAD)" = "$(git rev-parse refs/heads/main)"`
Evidence (step 0.1, `SKILL.md:303`): "the paste `cd A && test "$(git rev-parse HEAD)" = M && ./devcontainer-config/install.sh`", with M a literal SHA.

Step 0.1 pins M so the paste refuses at any commit other than the one the entry lists. Q-156 checks only that HEAD equals the host's local main. If the user pastes before `feat/build-loop-u5` has merged, or before the host's main has it, the test still passes and the image ships without U5. Only prose guards that order ("once `feat/build-loop-u5` has merged"). The body acknowledges that main may move on, and the next cycle rewrites the entry, so the impact is bounded. Even so, the one hand-written `image-lag` body is the one that differs from the form the orchestrator writes. Both git calls are still `rev-parse`, so step 0.1's hook-safety claim holds.

**Recommendation:** Do one of two things. Either fill in M as a literal SHA after the merge (the merge commit is known when the entry lands on main), or keep the dynamic form and add a check that the U5 merge is an ancestor, such as `git merge-base --is-ancestor <u5-tip> HEAD`. Note that this adds a git call other than `rev-parse`, so weigh it against step 0.1's hook-safety note. If neither fits, state in the entry that the paste is unpinned.

#### F4. `docs/constraints.md` and the cycle's files are refused under both policies, but the docs describe them as self-merge-only, and "every ready branch gets a merge entry" is too broad

**Severity:** Minor
**Location:** `docs/dev-cycle.md:19-27`; Q-103 option [1]; `workflows/codebase-onboarding.md:453` ("one 'merge?' entry in the questions doc per finished branch")
**Move:** 3 (documentation drift), 7 (asymmetry between the policies)
**Confidence:** High
**Legibility-target:** the user deciding Q-103; a project owner expecting a loop to edit `docs/constraints.md` under review

Evidence (dev-cycle.md): "none is on the gate's fixed floor (… files later runs read as truth such as `docs/decisions/` and `docs/constraints.md`, …)". Under `review`, the orchestrator "merges only on your `[1] merge`."
Evidence (script header, `build-loop.sh:355-367`): "The N rules, under either policy: … the dev cycle's own files (the roadmap, the questions files, the idea log, docs/dev-cycle.md, … docs/working/briefs/ or docs/working/cycles/ …) and docs/constraints.md". SKILL.md:594-595: "A `refuse` verdict is filed as `stopped`".
Evidence (Q-103 [1]): "Every `ready` branch gets one merge entry".

`docs/constraints.md` and the cycle's own files are refused by an always-on N rule, not by the self-merge floor. A branch that touches them gets a `refuse` from `--check` and is filed as `stopped-STEM-N`, not as a merge entry, under `review` too. As written, the settings file and Q-103 tell the user that review can land anything after `[1] merge`. (This is not the known fact-check item about refused self-merges falling through. That item concerns S-rule refusals under self-merge; this one concerns N-rule refusals under review.)

**Recommendation:** In the Policy bullet, add one sentence saying that under either policy the gate never lands the cycle's own files or `docs/constraints.md`, and that such a branch is filed as stopped. Change Q-103 [1] and the onboarding text to "every `ready` branch `--check` passes".

#### F5. Step 10's constraints entry has no pinned slug, so Q-155 may not be recognised as "an open one"

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:765-766`; `docs/working/questions.md` Q-155
**Move:** 2 (naming), 3 (contract)
**Confidence:** Medium
**Legibility-target:** later orchestrator iterations, which deduplicate by reading the questions files

No existing precedent in `skills/dev-cycle/SKILL.md` step 10 (searched for a slug for the constraints entry). Peer entries that the orchestrator must recognise are slug-pinned: `image-lag`, `image-off-main-C12`, `merge-…`, `blocked-/stopped-/capped-STEM-N`.

Evidence (step 10): "(else one `you: judgment` entry asking for `docs/constraints.md`, unless an open one does: D2)". Evidence (Q-155 Interim): "step 10 files nothing more while this entry is open."

Q-155's own interim depends on step 10 recognising `constraints-doc-missing` as the open entry, and step 10 names no slug to match. Every other entry the orchestrator files and later looks up is identified by a fixed slug. This one relies on judgment, so a later iteration could file a duplicate. (Severity is Minor after the one-tier no-precedent downgrade from Inconsistent.)

**Recommendation:** Name the slug in step 10 (`constraints-doc-missing`, matching Q-155) the way step 0.1 names `image-lag`.

#### F6. Q-153 drops the `build-loop-cN-` prefix its C-series siblings share

**Severity:** Minor
**Location:** `docs/working/questions.md` heading `### Q-153 · merged-branch-deletion-rule`
**Move:** 2
**Confidence:** Medium (the change of prefix may be deliberate, since C4 changes a global instruction rather than the build loop)
**Legibility-target:** a reader grepping `build-loop-c` for the plan's C1-C5

Precedent: `build-loop-cN-<topic>` used in `docs/working/questions.md` (Q-150 `build-loop-c1-questions-writer`, Q-151 `build-loop-c2-blocked-slot`, Q-152 `build-loop-c3-blocked-wait`) and `docs/working/questions-archive.md` (Q-154 `build-loop-c5-cycle-cost`).

Evidence: "### Q-153 · merged-branch-deletion-rule … (Plan C4.)". Four of the five plan C-questions can be found with `build-loop-c`; C4 cannot.

**Recommendation:** Rename it to `build-loop-c4-merged-branch-deletion` (the index regenerates), or leave it and accept a C-series that the slug alone cannot find.

#### F7. "the loop's own files" vs the established "brief's own files"

**Severity:** Minor
**Location:** `docs/dev-cycle.md:20-21`
**Move:** 2
**Confidence:** High
**Legibility-target:** a reader matching the settings prose to `--check`'s deny reasons

Precedent: "its own files" / "A brief's own files" used in `scripts/build-loop.sh:382,1210,1214` ("neither listed in the brief's Paths: line nor one of its own files") and `scripts/lib/dev-cycle-read.sh:1949` (`ownfile`, keyed on the brief's stem).

Evidence: "only when every changed path is listed in the brief's `Paths:` line or is one of the loop's own files". The files are keyed on the brief's stem (`docs/working/{research,plan,…}-STEM.md`), not on the loop. A re-dispatched brief (up to 4 dispatches) has several loops but one set of own files.

**Recommendation:** Say "one of the brief's own files (its working docs and added reviews, named by its stem)".

#### F8. Q-154's answer line lacks the `[N]` handle, and its dates read backwards

**Severity:** Informational
**Location:** `docs/working/questions-archive.md` Q-154
**Move:** 2 (convention of answered entries)
**Confidence:** High
**Legibility-target:** the user and the archive's readers

Precedent: `**Answer (DATE, source):** [N] …` used in `docs/working/questions-archive.md` (Q-139…Q-148 answers, e.g. lines 2567, 2588, 2594, 2616).

Evidence: "**Opened:** 2026-10-14 · **Status:** ANSWERED" followed by "**Answer (2026-10-04, in session; plan D12):** a full cycle every iteration for now; …". The option number appears only in Interim ("[1], answered."). The answer predates the opening, which the body explains ("Filed answered in U5"), but a date-sorted reader sees an inversion. `questions.sh check` passes.

**Recommendation:** Start the answer with `[1]`, for example `**Answer (2026-10-04, in session; plan D12):** [1] a full cycle …`.

## What Looks Good

- The two new settings lines match the script's grammar and SKILL.md's template exactly. The added bats assertions (`line never`, `line slots`) run against a copy of this file and pass at 42414307, so the prose bullets were checked and are not read as extra copies.
- The `image-lag` slug and `you: terminal` route in Q-156 equal step 0.1's, so the orchestrator will rewrite the entry rather than add a second one. Its C, gate-code names, first-parent list and outside-`docs/` path list match `git diff`/`git log --first-parent` from `8d0e660e` exactly (3 gate paths, 11 commits, 28 paths, 501 under `docs/`).
- The merge slug grammar (`merge-`/`merge-gate-STEM-SHA12`) and the `[1] merge` label read the same in dev-cycle.md, Q-103, decision-log row 72 and SKILL.md step 7.
- "Review handoff" is treated the same way in all three places: dev-cycle.md documents its absence, SKILL.md:595 says the route is not built, and the plan's as-built note explains why no line was added. Nothing invites a user to write a key that nothing reads.
- The new questions entries follow the global grammar: heading, Needs/Opened/Status, the four-column table, Blocks/Interim/If the answer differs, and one paste block for the terminal entry. `questions.sh check` reports the structure as valid and the indexes as current.
- The onboarding constraints text matches the `H<n>:`/`S<n>:`/`success:` grammar in the script header and SKILL.md "Constraints".

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Onboarding omits that self-merge needs a never line | Inconsistent | `workflows/codebase-onboarding.md:453` | High |
| 2 | "holds a slot" collides with the Rules' term | Minor | `docs/dev-cycle.md:30-32`; Q-151 | High |
| 3 | Q-156 paste unpinned vs step 0.1's `= M` | Minor | `docs/working/questions.md` Q-156 | High |
| 4 | N-rule paths described as self-merge-only; "every ready branch" too broad | Minor | `docs/dev-cycle.md:19-27`; Q-103 [1]; onboarding:453 | High |
| 5 | Step 10's constraints entry has no pinned slug | Minor | `SKILL.md:765-766`; Q-155 | Medium |
| 6 | Q-153 slug breaks the `build-loop-cN-` series | Minor | `docs/working/questions.md` Q-153 | Medium |
| 7 | "loop's own files" vs "brief's own files" | Minor | `docs/dev-cycle.md:20-21` | High |
| 8 | Q-154 answer lacks `[N]`; date inversion | Informational | `questions-archive.md` Q-154 | High |

## Overall Assessment

U5's documentation is mostly consistent with the built contracts. The settings lines, the merge and `image-lag` slugs, the option labels and the questions grammar all match their owners (`build-loop.sh`'s header and `read_settings`, and SKILL.md steps 0.1 and 7), and the one new test confirms the settings file parses as documented. Nothing here breaks a consumer. The issues can all be fixed in place:

- One consumer-visible gap: onboarding does not say that self-merge needs a never line, so a pre-U5 project that sets `self-merge` silently stays on `review`.
- Two places where the prose blurs which rules apply under which policy or who owns a file (F4, F7).
- One term collision (F2).
- One hand-written entry that departs from the form the orchestrator writes (F3).
- Two cases of slug discipline (F5, F6).

None of these suggests the author skipped the existing conventions. Each is a phrase that drifted from a precise owner text.

## Goal-Alignment Note

The PR's goal is that the docs describe the build-loop handoff as built. Against that goal, F1, F4 and F2 matter most, because each tells the user something the code contradicts: that self-merge can be set without a never line, that review can land `docs/constraints.md`, and what "holds a slot" means. F3 concerns the one hand-written body of a machine-owned entry, and the next cycle self-corrects it. F5 to F8 are hygiene items and do not block the goal. The fact-check's known items were not re-reported. If they are fixed together with F1, F2 and F4, the settings file, onboarding and Q-103 will agree with the script header.
