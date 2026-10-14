Commit: f2cc21e6

# Architecture Review — feat/build-loop-u4c (loop pass i2)

**Scope:** fix range `git diff 1bc823ea..f2cc21e6` (33ad1767, f2cc21e6): `skills/dev-cycle/SKILL.md` (Rules, D6 block header, own(), launch env, step 0.1, step 1), `docs/working/plan-build-loop-handoff.md` (D5 item 3, D6, F39/F40, U4c note, :356, T33, Risks, Rollback 1), `test/scripts/build-loop-orchestrator.bats` (d6_copy, T37), `docs/reviews/override-log.md` rows 812-817
**Date:** 2026-10-13
**Based on:** `docs/reviews/code-fact-check-report-2026-10-13-u4c-i2.md` (k=1; Claims 13, 25, 26) and its log `docs/reviews/execution-logs/u4c-i2-image-lag.log`; rubric `docs/reviews/code-review-rubric-2026-10-13-feat-build-loop-u4c.md` (B4); i1 report `docs/reviews/architecture-review-2026-10-13-u4c-i1.md`

Scope check: in scope. Step 0.1 adds a new cross-cutting control (a per-iteration comparison between the release artifact and main) and a third copy of the GATE_CODE path set. Decided items (i1 findings 3 to 5, rows 812-817) are not re-filed, because the fix range leaves their basis unchanged.

Trust-boundary cross-reference: the newest security review is `docs/reviews/security-review-2026-10-13-u4c-i1.md` (Commit: `1bc823ea`, the range's base, so it is current for the boundary). Its `B6 (new)` is "[main's reviewed gate code] → [image rebuild (manual, out of band)] → [/opt copy that runs]". Step 0.1 observes B6 and does not move it. No recommendation below relocates a crossing.

## Dependency Map

The chain from i1 is unchanged: main -> (release cut by hand) -> `/opt/claude-workflows` image -> the gate that runs. Step 0.1 adds an observer of the first arrow. It reads two inputs:
- the image side: the `commit=` line of `/opt/claude-workflows/.manifest`, a root-owned file written by the image build;
- the main side: `hg -C MAIN_WT diff --quiet C refs/heads/main -- <paths>`.

Its output is one `you: terminal` entry, `image-lag`, and never a stop. The path set it diffs is written in prose at `SKILL.md:286-287`. It is meant to equal the lib's `GATE_CODE` (`scripts/lib/dev-cycle-read.sh:1970`). The set now has four copies in total:
- the lib's GATE_CODE regex (the authority);
- the slug-rule line at `SKILL.md:570`, which a test pins byte-equal to the lib;
- build-loop.sh's header prose (`:412-415`), not pinned;
- step 0.1's pathspec, not pinned (new).

The plan's U5 release entry (`plan:356`, plus `:75` and F58 at `:176`) is a second, planned consumer of the same `.manifest` commit. It lists every commit and changed path since that commit and lives in "the skill's close step".

## Findings

#### 1. Step 0.1's pathspec is an unpinned prose copy of GATE_CODE that fails open on drift

**Severity:** Coupling
**Location:** `skills/dev-cycle/SKILL.md:285-287`; `scripts/lib/dev-cycle-read.sh:1970`; `test/scripts/build-loop-orchestrator.bats:347-351`
**Move:** 7 (coupling surface), 3 (module boundary)
**Confidence:** High
**Legibility-target:** step 0.1's text and the slug-rule test

Evidence: SKILL.md:285-287: "`hg -C MAIN_WT diff --quiet C` / `refs/heads/main -- scripts/build-loop.sh scripts/dev-cycle.sh scripts/questions.sh` / `scripts/lib/ skills/dev-cycle/` (GATE_CODE) exits 1". The lib has `GATE_CODE='^scripts/(build-loop|dev-cycle|questions)\.sh$|^scripts/lib/|^skills/dev-cycle/'`. The test reads `[ "$(grep -cxF "  $q$g$q" "$REPO_ROOT/skills/dev-cycle/SKILL.md")" -eq 1 ]`.

Today the five pathspecs match GATE_CODE's three alternatives exactly. The i2 log confirms that the narrowed diff no longer counts `health-check.sh`. Two things make this copy riskier than the others:
- **No test pins it.** The slug-rule test holds only the backticked regex line at `:570`. The pathspec is spread over three wrapped prose lines, so no line-anchored grep could pin it as written.
- **Drift fails open.** Suppose GATE_CODE gains a path, such as a new gate script or `skills/build-loop/`. The slug-rule test then fails and forces an edit to `:570`, and the `merge-gate-` rule and `--approved` both follow the lib. Step 0.1 keeps the old list and silently files no `image-lag` entry for a change to the new path. This is the "unobserved state" i1 finding 1 was about, now limited to the paths added after this unit.

The other copies fail closed or do not matter. A stale slug line fails the test. A stale build-loop.sh header comment changes no behaviour.

**Recommendation:** Put the pathspec on one line of its own (for example, an indented code line `scripts/build-loop.sh scripts/dev-cycle.sh scripts/questions.sh scripts/lib/ skills/dev-cycle/`). Extend the slug-rule test (row 674) to derive the expected pathspec from `$GATE_CODE` and assert that line, so a GATE_CODE change fails one test for both copies. A cheap version is an explicit `GATE_PATHS` string in the lib next to GATE_CODE, with one test that holds the regex and the string equal and another that holds SKILL.md to the string. An alternative is to make the check a script mode, which would read GATE_CODE directly. Run through D6, though, it would use the image's GATE_CODE, which is stale exactly when the check matters. That makes it worse, so the prose-plus-pin route is the right one.

#### 2. Step 0.1's `image-lag` entry and U5's planned release entry are two entries for one action, and the plan does not join them

**Severity:** Coupling
**Location:** `skills/dev-cycle/SKILL.md:288-290`; `docs/working/plan-build-loop-handoff.md:356`, `:75`, `:176` (F58), `:432`
**Move:** 2 (responsibility boundaries), 8 (extension points)
**Confidence:** High on the gap, Medium on severity
**Legibility-target:** plan U5 step 11 (:356) and step 0.1's entry text

Evidence:
- SKILL.md:288-289: "file or update one `you: terminal` entry `image-lag` (the release: the host's `./devcontainer-config/install.sh`, then the next sandbox launch rebuilds the image), and go on".
- plan:356: "One `you: terminal` release entry: rebuild and bless … Release entries list every commit and changed path since the image's `.manifest` commit, flagging self-merged ones (F58); the skill's close step says so for future releases."

Both entries share the same trigger source (the `.manifest` commit against main) and the same user action (run install.sh on the host). They differ in two ways:
- **Trigger scope.** The release entry fires for any path. `image-lag` fires for GATE_CODE paths only.
- **Body.** The release entry must list commits and paths and flag self-merges (F58: "Your release review is the gate"). `image-lag`'s body is unspecified. "Update" names no field it refreshes: not C, not main's commit, not the changed paths.

As written, U5 would add a second release-shaped entry in a different step (the close step). The two would overlap whenever gate code changed. That breaks the questions-doc rule that terminal entries collect into one paste, and it leaves two places to edit when the release procedure changes. The Risks line (:432) names `image-lag` but :356 does not, so the U5 author has no pointer.

The `image-lag` entry also has no closing rule. When the image catches up, `diff --quiet` exits 0, and the step then neither files nor closes. An entry left OPEN after the release says the gate lags when it does not.

**Recommendation:** In plan :356 (U5), state that the release entry absorbs `image-lag`. Use one slug, filed by step 0.1's check, widened in U5 to the full `.manifest`..main listing F58 needs. Gate-code paths would be flagged inside it, not given their own entry. Alternatively, state that U5 retires `image-lag` in favour of the close step's entry. In this unit, add two things to step 0.1: what the entry's body carries (C, main's commit, `diff --name-only` of the same pathspec), and that a clean diff closes an open `image-lag` entry (`Status: ANSWERED`, archived by step 1's `questions.sh archive`).

#### 3. "The gate that runs is older than main's" assumes main is ahead, but the test is "differs", and Rollback 1 is the case where it is not

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:287-288`; `docs/working/plan-build-loop-handoff.md:441` (Rollback 1)
**Move:** 1 (dependency direction)
**Confidence:** High
**Legibility-target:** step 0.1's wording

Evidence: SKILL.md:287-288: "exits 1, the gate that runs is older than main's". Rollback 1: "a revert of gate code takes effect only after the image is rebuilt from the reverted main (the host's `./devcontainer-config/install.sh`, then the next sandbox launch)".

Rollback 1 now resolves i1 finding 1's rollback half. It names the rebuild and the same two-step release that step 0.1 names, and it is scoped to gate-code reverts. The two texts also compose. After a revert of gate code, C still holds the reverted code, so `diff --quiet C main` exits 1 and step 0.1 files `image-lag`, which prompts the rebuild Rollback 1 requires. In that case, though, the image's gate is newer than main's (it still holds the reverted change), and the text calls it "older". The i2 fact-check (Claim 13) already noted "detects 'differs', not 'ahead'". The fix range kept "older". The effect is wording only, because the action (rebuild) is the same in both directions.

**Recommendation:** Say "differs from main's" instead of "is older than main's". Optionally, add a pointer in Rollback 1 that step 0.1 files the rebuild entry after the revert.

#### 4. Placement: step 0.1 after `--state` is the right point; in other repositories the check notes a non-event every iteration

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:283-290`
**Move:** 2 (responsibility boundaries)
**Confidence:** Medium
**Legibility-target:** step 0.1's last sentence

Evidence: "when `hg -C MAIN_WT cat-file -e 'C^{commit}'` succeeds (this repository holds the image's commit) … No `.manifest`, no `commit=` line or any other exit: note it in the record and go on."

The placement is sound for three reasons:
- It runs after `--state` has refused planted `.git` state, so the `hg` reads sit behind the same gate as everything else in step 0.
- It runs from MAIN_WT at `refs/heads/main`, which is what the image is built from, never from WT.
- It is never a stop. A lagging image should not block a cycle that lands only non-gate work.

The new check copies its timing from the existing step 0.1 judgment entries, which the i2 fact-check (Claim 25) noted: the entry is filed before step 0.3 creates WT, and a later step 0 stop drops it. That is harmless here, because the next iteration recomputes the entry.

The sentence that structures it causes a problem. "Any other exit" can be read as covering `cat-file -e` failing. That failure is the normal result in every repository other than claude-workflows: the log shows exit 128 for an absent object. On that reading, every iteration in every other repository writes a record note about an expected non-event. The condition "holds the image's commit" serves as an "is this claude-workflows" test, which is right. But its failure branch is grouped with real errors.

**Recommendation:** Split the outcomes:
- `cat-file -e` failing means this is not the image's repository: skip silently.
- A missing `.manifest`, a missing `commit=` line, or `diff` exiting other than 0 or 1 is a fault: note it in the record.

#### 5. i1 Coupling finding 1 is resolved in substance

**Severity:** Informational
**Location:** `skills/dev-cycle/SKILL.md:45`, `:283-290`; plan `:71`, `:356`, `:432`, `:441`
**Move:** 1
**Confidence:** High
**Legibility-target:** none (confirmation)

Evidence: Rule `:45`: "a gate change merged here runs from the next image release (step 0.1 checks the lag)". Risks `:432`: "Since Q-140 [1] the gate waits too (D6 runs the image copy); step 0.1 files an `image-lag` entry when main's GATE_CODE paths differ from the image's `.manifest` commit."

i1 finding 1 asked for three things. All three are now addressed:
- **A mechanical signal at step 0.** Step 0.1 compares GATE_CODE paths against `.manifest`, which the i2 log executed (exit 1 today: build-loop.sh, the lib and SKILL.md differ).
- **A `you: terminal` release prompt.** The `image-lag` entry provides it.
- **A rebuild step in Rollback 1.** It is added and scoped to gate-code reverts.

i1 finding 2's text items (:356, :432, D5 item 3 "kept by choice") are fixed too. The dependency direction is unchanged: the check reads the release artifact and main, and writes only a questions entry. Nothing in the gate now depends on the check, which is correct for an observer. What remains is that the check is not durable: findings 1 and 2 cover drift in its path copy and its overlap with U5.

**Recommendation:** None beyond findings 1 to 4.

## What Looks Good

- **An observer, not a gate.** Step 0.1 never stops the cycle and changes nothing about which script runs. The image lag becomes triage (one `you: terminal` paste) instead of a block, which fits the attention budget.
- **Keyed to GATE_CODE, not to `scripts/`.** f2cc21e6 narrowed the diff to the floor's own definition of gate code, so the entry no longer fires on `health-check.sh`. The trigger now means what the Rule says.
- **The check reads `refs/heads/main` from MAIN_WT under `hg`.** It uses the same hardened environment and the same ref the image is built from, never the iteration's worktree.
- **Rollback 1 and step 0.1 compose.** A gate-code revert is itself detected as lag, so the rebuild Rollback 1 requires is prompted by the cycle rather than remembered.
- **own()'s missing-file split** separates "an older image" from "tampering" at the boundary (B2), and T37 runs the real snippet on the missing-file case.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Step 0.1's pathspec is an unpinned prose copy of GATE_CODE; a GATE_CODE addition silently escapes the lag check | Coupling | `SKILL.md:285-287`; `dev-cycle-read.sh:1970`; bats `:347-351` | High |
| 2 | `image-lag` and U5's release entry are two entries for one action; plan :356 does not join them; the entry has no body spec and no closing rule | Coupling | `SKILL.md:288-290`; plan `:356`, `:75`, `:176` | High / Medium |
| 3 | "older than main's" is wrong in the revert case Rollback 1 creates; the test is "differs" | Minor | `SKILL.md:287-288`; plan `:441` | High |
| 4 | Placement sound; "any other exit" groups the normal not-this-repository case with faults, so other repositories get a record note every iteration | Minor | `SKILL.md:283-290` | Medium |
| 5 | i1 finding 1 (signal, prompt, Rollback 1) and finding 2's text items are resolved | Informational | `SKILL.md:45`, `:283-290`; plan `:356`, `:432`, `:441` | High |

## Overall Assessment

The fix range resolves i1 Coupling finding 1 in substance. Step 0.1 gives the main -> release -> gate chain a mechanical, non-blocking observer keyed to GATE_CODE. Rollback 1 names the rebuild, and the two compose, because a revert shows up as lag. The plan text no longer claims the gate "does not wait". The observer is not yet durable, for two reasons. First, its path list is a fourth, unpinned copy of GATE_CODE in wrapped prose, and it fails open, so a later gate path would escape the check silently (finding 1). Second, it overlaps U5's planned release entry: same trigger source, same action, no body spec and no closing rule, and plan :356 does not say the two merge (finding 2). Both can be fixed in place and are small: put the pathspec on one line pinned by the row-674 test, and add one sentence each to :356 and step 0.1. The single most important concern is finding 1, because it is the one that fails toward the unobserved state i1 flagged.

## Goal-Alignment Note
- Success criterion (restated verbatim): a report saved to /workspace/.claude/wt-build-loop-u4c/docs/reviews/architecture-review-2026-10-13-u4c-i2.md (first line `Commit: f2cc21e6`), per the skill.
- Answered:
  - Does step 0.1 resolve i1 finding 1? Yes in substance (finding 5).
  - Placement: sound, with one outcome-grouping wording fix (finding 4).
  - The path list's drift risk against the lib's GATE_CODE and the pinned slug-rule test: unpinned, and fails open (finding 1).
  - The interaction with U5's release entry (plan step 11, :356): two entries for one action, not joined (finding 2).
  - Rollback 1: resolved; composes with step 0.1; "older" wording (finding 3).
- Out of scope: whether `.manifest` itself can be trusted as the image's commit (security, B6); the cost of the extra git calls per iteration (performance; two cheap reads); decided items i1 3 to 5 and rows 812-817, whose basis is unchanged.
- Escalate: none blocking. Whether finding 2's merge happens here or in U5 is the loop's call. Finding 1's pin is cheapest in this unit, while the pathspec is fresh.
