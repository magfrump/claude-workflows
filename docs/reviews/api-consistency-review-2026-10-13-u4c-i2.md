Commit: f2cc21e6

# API Consistency Review: feat/build-loop-u4c (U4c, loop pass i2)

**Scope:** fix range `git diff 1bc823ea..f2cc21e6`: `skills/dev-cycle/SKILL.md` (Rules, the D6 block, step 0.1's image-lag check, step 1), `test/scripts/build-loop-orchestrator.bats`, `docs/working/plan-build-loop-handoff.md`, override-log rows 812-817
**Date:** 2026-10-13
**Based on:** docs/reviews/code-fact-check-report-2026-10-13-u4c-i2.md; i1 report docs/reviews/api-consistency-review-2026-10-13-u4c-i1.md; rubric docs/reviews/code-review-rubric-2026-10-13-feat-build-loop-u4c.md

## Baseline Conventions

- **Snippet contract** (unchanged since i1): exit 2 plus one `refuse d6: WHY` line on stdout, nothing run; exit 1 plus the usage line on stderr; otherwise the script's own status. The Rules (`SKILL.md:36-61`) say a `refuse d6:` line is a stop, filed in the `you: judgment` entry the step names, or else in one `agent` entry.
- **Orchestrator-filed `you: terminal` entries.** The only existing one is step 1's merged-branch list (`SKILL.md:379-386`). It has a paste block whose contents are checked (only names `--check-branch` prints `ok` for), and "an open one is updated in place, not filed again". Its slug is not named. Keyed slugs (`other-commit-SHA12`, `main-log-refused-MAIN12`, `merge-gate-STEM-SHA12`, `blocked-STEM-N`) are reserved for entries that `--check-answer`/`--approved` look up by heading.
- **Global questions grammar** (`global-instructions/CLAUDE.md:265-277`): "A `you: terminal` entry carries **one copy-pasteable block** in place of the table: the whole command, runnable as-is, with the interim line saying what holds until it runs. Several terminal entries collect into a single paste". Also: "Never close an entry by inference when its own closure criterion names an observation."
- **GATE_CODE copies in SKILL.md:** the one at `:569-570` is quoted verbatim from the lib and pinned by a test (`bats:347`).

## i1 closure check

| i1 | Claimed | Verdict |
|---|---|---|
| F1 | Fixed (B5) | **Mostly closed.** The Rule now says "Every `build-loop.sh`, `dev-cycle.sh` and `questions.sh` call" and "a call of any script". Step 1 adds "(a `refuse d6:` line or a timed-out call is still a stop, as the Rules say)". Step 9 (`:702-703`, "after `questions.sh index` and `check` in WT") still does not say what an exit 1 from `check` means. The Rules' "any other exit (1 included) … means nothing was decided" sentence is scoped to `build-loop.sh` answers, so the case is still undefined. See F5 below. |
| F2 | Fixed (B3) | **Closed.** `:77` is now "runs from the root-owned image copy (Q-140 [1]; first written as …)"; F39/F40 rows rewritten; T33 row "as built, U4c"; `:432` "Since Q-140 [1] the gate waits too"; step 12 "The gate needs it too". |
| F3 | Fixed (C2) | **Closed.** `own()` now refuses `"$1 is missing"` first (`SKILL.md:228`). The header names "missing (an image older than this skill)". The trust stub uses the same words. T37 runs the real snippet on a removed file (`bats:324`). The execution log `u4c-i2-own.log` shows absent → `is missing`, and dangling link → `not root-owned…`. |
| F5 | Fixed (C5) | **Closed.** `[[ "${2:-}" != trust ]] ||` (`bats:238`). Any other value now leaves the real check in place, which fails closed on a uid-owned stand-in. That is equivalent to the "fail" asked for. |
| F4, F6 | Won't-Fix (row 816) | Basis unchanged. The new Rule text "(a uid-owned link; its own hints still print that path)" agrees with the row. |

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `refuse d6: X is missing` | refusal line | `refuse d6: X is not a regular file`, `refuse $a: its branch $br does not exist` | `SKILL.md:244`; `scripts/build-loop.sh:1360` | Consistent: `refuse <producer>: <subject> <state>`; the header lists it |
| `image-lag` | questions slug | merged-branch `you: terminal` entry (unnamed slug); `other-commit-SHA12`, `merge-gate-STEM-SHA12` | `SKILL.md:379-386`, `:311-312`, `:567-568` | Consistent as a bare kebab slug for a single-instance entry; keyed slugs are only for heading lookups. Entry *shape* gaps in F1-F3 |
| `-u QUESTIONS_LIVE -u QUESTIONS_ARCHIVE` | launch env | `-u BASH_ENV -u ENV -u DEV_CYCLE_SCRUBBED` | `SKILL.md:247` | Consistent; variable names match `scripts/questions.sh:85-86` |
| `d6_copy OPT [trust]` (literal) | test helper flag | `*_is WANT` helpers | `bats:234-246` | Consistent (i1 F5 closed) |
| step 0.1 pathspec list `(GATE_CODE)` | doc copy of a lib constant | GATE_CODE quoted at `SKILL.md:570` | `scripts/lib/dev-cycle-read.sh:1970` | Second, unpinned copy. See F4 |

## Findings

#### F1. The image-lag entry has no closure: nothing says what happens to an open `image-lag` once the image catches up

**Severity:** Inconsistent
**Location:** `skills/dev-cycle/SKILL.md:283-290`
**Move:** 3 (consumer contract), 7 (asymmetry: file/update with no close)
**Confidence:** High
**Legibility-target:** the orchestrator on the first iteration after a release

Evidence: "exits 1, the gate that runs is older than main's: file or update one `you: terminal` entry `image-lag` (… the next sandbox launch rebuilds the image), and go on. No `.manifest`, no `commit=` line or any other exit: note it in the record and go on."

The check covers exit 1 (file or update) and errors (note). It says nothing for exit 0, which is the observation that discharges the entry. After the user runs the release, the entry stays OPEN, and every later cycle and the final message's list keep showing a done chore. The global rule forbids closing it by inference, and here the closure criterion is exactly what this check observes, so the step is the natural place to state it. Its sibling, the merged-branch entry, says how an open entry is reused ("updated in place, not filed again"). image-lag copies that half and leaves out the other.

**Recommendation:** Add: "exit 0 with an open `image-lag` entry: set it ANSWERED, recording C and main's commit as the observation, and let step 1's `archive` move it."

#### F2. The entry is described by its remedy, not by the grammar's paste block and interim

**Severity:** Inconsistent
**Location:** `skills/dev-cycle/SKILL.md:288-289`
**Move:** 3 (contract against the global grammar)
**Confidence:** High
**Legibility-target:** the user acting on the entry (`you: terminal` must be answerable by one paste)

Evidence: "(the release: the host's `./devcontainer-config/install.sh`, then the next sandbox launch rebuilds the image)". The grammar says: "one copy-pasteable block … the whole command, runnable as-is, with the interim line saying what holds until it runs."

`./devcontainer-config/install.sh` is relative to the host checkout. The manifest's `assembled_from=` line names that checkout, but the step never says to use it. So the orchestrator has to invent the `cd` and the interim line ("the image's gate at C runs; gate changes since C are inert"). "Update" is also unspecified: does it refresh C, main's commit, or the changed-path list? The merged-branch entry, by contrast, defines what goes into its paste block. The plan's release entry (step 12, `plan:356`; F58 at `plan:176`) promises "every commit and changed path since the image's `.manifest` commit, flagging self-merged ones". That is the same remedy and the same window, but the image-lag spec does not mention it. The result is two terminal entries for one rebuild, which also cuts against "Several terminal entries collect into a single paste".

**Recommendation:** Name the body: the paste block (`cd <assembled_from> && ./devcontainer-config/install.sh`, plus "then relaunch"), an Interim line, and the GATE_CODE paths changed since C as data. Either make image-lag *the* release entry that F58 describes, or say that the step 12 entry supersedes it.

#### F3. An image old enough to lack a file is refused as a stop and filed elsewhere, before the image-lag check can run

**Severity:** Inconsistent
**Location:** `skills/dev-cycle/SKILL.md:211-214` (header), `:228` (own), `:277-283` (step 0.1 order), `:51-56` (Rules' filing)
**Move:** 4 (error consistency: one condition, two routes)
**Confidence:** Medium
**Legibility-target:** the orchestrator filing step 0.1's outcome; the user reading the queue

Evidence: header "an image-copy file that is missing (an image older than this skill)". Step 0.1: "`--state` … refuse lines … are a stop, quoted in one `you: judgment` entry … Then the image lag". Rules: "a `refuse d6:` line, are stops too … filed once: in the `you: judgment` entry the step names".

The new refusal string names the condition (an old image) and points at the same remedy as image-lag, a release. But `--state` runs first, so the `is missing` refusal stops the iteration before the lag check. The condition then lands as a `you: judgment` entry, or an `agent` entry, quoting the line; neither carries the release paste. A lagging image gets the `you: terminal` route, while a *more* lagging image gets a judgment stop. That is defensible as a stop, since nothing can run. The routing is still inconsistent, and it spends the judgment budget on a machine chore. Today all four files are present at 774a0eef (checked under `/opt`), so the case is latent.

**Recommendation:** In step 0.1, say that a `refuse d6: … is missing` line is filed or updated as the `image-lag` entry (still a stop), not as a judgment entry. Alternatively, run the lag check before the stop's filing, so the entry exists when the iteration ends.

#### F4. Step 0.1's GATE_CODE pathspecs are a second, untested copy, and case-sensitive where GATE_CODE is not

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:285-287`
**Move:** 2 (naming a lib constant), 3
**Confidence:** Medium
**Legibility-target:** the next editor of GATE_CODE

Precedent: GATE_CODE quoted once and test-pinned, used in `skills/dev-cycle/SKILL.md:569-570` (`bats:347`)

Evidence: "`-- scripts/build-loop.sh scripts/dev-cycle.sh scripts/questions.sh scripts/lib/ skills/dev-cycle/` (GATE_CODE)" against the lib "`GATE_CODE='^scripts/(build-loop|dev-cycle|questions)\.sh$|^scripts/lib/|^skills/dev-cycle/'`", which `:568` matches on the PATH "lower-cased".

The two lists agree today. A GATE_CODE change would fail the pinned copy's test and pass this one silently. Also, because the pathspecs are literal (`GIT_LITERAL_PATHSPECS=1`), a path such as `Skills/Dev-Cycle/x` counts as gate code for the merge floor but not for the lag check.

**Recommendation:** Extend the `bats:347` test to the step 0.1 line, or derive the list from the pinned copy. Optionally note that the check is case-sensitive.

#### F5. Step 9 still leaves a `questions.sh check` exit 1 undefined (i1 F1 residual)

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:702-703`; Rules `:46-51`
**Move:** 4
**Confidence:** High
**Legibility-target:** the orchestrator at land time

Evidence: "after `questions.sh index` and `check` in WT when this iteration filed or edited entries". Rules: "A `build-loop.sh` answer is exit 0, or exit 2 …; any other exit (1 included) … means nothing was decided".

The Rules' widened sentences cover timeouts and `refuse d6:` for questions.sh. A `check` failure (exit 1, `✗ questions.sh: …`) is neither of those, and the exit-code sentence names only build-loop.sh. Step 1 defines its failure ("note it in the record and go on"); step 9 does not. A malformed entry the orchestrator just wrote could be landed. i1 recommended this third clause, and B5's fix did not take it up.

**Recommendation:** One clause, for example: "`check` failing: fix the entries and re-run before staging; a second failure is a stop (`agent`)."

#### F6. Step 0.1 names `refs/heads/main` and leaves the normal non-claude-workflows outcome to "any other exit"

**Severity:** Informational
**Location:** `skills/dev-cycle/SKILL.md:284-290`
**Move:** 3
**Confidence:** Medium
**Legibility-target:** the orchestrator in another repository

Precedent: "`refs/heads/main` (or master)" used in `skills/dev-cycle/SKILL.md:706`

Evidence: "when `hg -C MAIN_WT cat-file -e 'C^{commit}'` succeeds … and `… diff --quiet C refs/heads/main …` exits 1 … No `.manifest`, no `commit=` line or any other exit: note it in the record and go on."

In every other repository, `cat-file -e` fails with exit 128, because the repository does not hold the image's commit. The "when … succeeds" condition implies the check is skipped then, but "any other exit: note it" can be read to cover that failure, which would note it every cycle in every repo. The block accepts `master`, while this step hard-codes `main`. Both matter only outside claude-workflows, where a lag check means nothing anyway.

**Recommendation:** Add "(cat-file failing: not this image's repository; skip silently)", and add "(or master)" as `:706` does.

## What Looks Good

- **The refusal set and the header agree again.** Each header case now has one distinct string: missing, not a regular file, not root-owned, the git cases. Each string has a test using the snippet's own wording. The stub and the real `own()` share "is missing", so the test text is no longer stub-only.
- **The `-u` list** extends an existing pattern with the exact variable names questions.sh reads. `u4c-i2-questions-env.log` shows the block ignoring `QUESTIONS_LIVE=fake` (`Q-144` against `Q-001` for a direct call).
- **questions.sh mentions are coherent.** The Rules name it in the call form. The block's usage line, header, and SKILL.md's section intro (`:192-193`) list the same three scripts. The "never as `~/.claude/scripts/questions.sh`" sentence now admits the script's own hints (row 816). Step 1 states its stop exceptions.
- **The plan text now matches Q-140 [1]** throughout (D6 heading, F39/F40, T33, risks, rollback, step 12).
- bats `test/scripts/build-loop-orchestrator.bats`: 25/25 pass at f2cc21e6.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| F1 | image-lag has file/update but no close on exit 0 | Inconsistent | `SKILL.md:283-290` | High |
| F2 | Entry spec gives a remedy, not the grammar's paste block or interim; overlaps the plan's F58 release entry | Inconsistent | `SKILL.md:288-289`; `plan:356` | High |
| F3 | An image missing a file → `--state` stop filed as judgment/agent, never as image-lag | Inconsistent | `SKILL.md:211-214,228,277-283` | Medium |
| F4 | Step 0.1 GATE_CODE pathspecs are unpinned and case-sensitive | Minor | `SKILL.md:285-287` | Medium |
| F5 | Step 9 `questions.sh check` exit 1 still undefined (i1 F1 residual) | Minor | `SKILL.md:702-703` | High |
| F6 | `refs/heads/main` only; cat-file failure elsewhere reads as "note it" | Informational | `SKILL.md:284-290` | Medium |

## Overall Assessment

i1's F2, F3 and F5 are closed. F1 is closed except for step 9's `check` exit (F5 here). The new `is missing` string fits the refusal grammar and the header, and the questions.sh mentions are now consistent. The remaining inconsistencies are in the new image-lag entry. It is specified by its trigger and remedy only. It has no close on exit 0, no paste block or interim as the `you: terminal` grammar requires, and no defined relation to the plan's release entry. The one condition its own refusal text names, an image missing a file, goes by a different route. All of these are text fixes inside step 0.1. Consumer impact: a stale OPEN entry after every release, and the orchestrator improvising the paste. Nothing becomes unsafe, because every path either goes on or stops.

## Goal-Alignment Note
- Success criterion (restated verbatim): a report saved to /workspace/.claude/wt-build-loop-u4c/docs/reviews/api-consistency-review-2026-10-13-u4c-i2.md (first line `Commit: f2cc21e6`), per the skill.
- Answered: i1 F1-F3, F5 closure (F2, F3, F5 closed; F1 mostly, residual F5). The image-lag entry's shape against SKILL.md's merged-branch `you: terminal` entry and the global grammar (slug: fine; paste/interim: F2; one per condition: fine, but overlaps the release entry and the old-image refusal, F2/F3; closing: F1). The "is missing" string against the header and the Rules' refuse d6 handling (consistent; routing gap F3). questions.sh mentions (consistent; step 9 residual F5).
- Out of scope: the trust wording and same-uid residual (security). The narrowed diff's correctness beyond naming (fact-check i2). Override rows 812-817 were not re-litigated.
- Escalate: none; F1-F3 are text fixes in step 0.1 within U4c's scope.
