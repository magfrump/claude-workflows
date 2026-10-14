Commit: 43b8d7ed

# Architecture Review — feat/build-loop-u4c (final confirming pass)

**Scope:** full branch `git diff main...feat/build-loop-u4c` (HEAD 43b8d7ed): `skills/dev-cycle/SKILL.md` (Rules, The D6 block, step 0.1, step 9.1), `scripts/lib/dev-cycle-read.sh` (GATE_CODE comment), `scripts/build-loop.sh` (store_check comment), `test/lib/d6-snippet.bash` (deleted), `test/scripts/build-loop-orchestrator.bats`, `docs/working/plan-build-loop-handoff.md`, override-log rows 812-819
**Date:** 2026-10-13
**Based on:** `docs/reviews/code-fact-check-report-2026-10-13-u4c-final.md` (k=3; Claims 1, 6, 7); rubric `docs/reviews/code-review-rubric-2026-10-13-feat-build-loop-u4c.md` (B1-B5, C1-C11, D1-D9); `architecture-review-2026-10-13-u4c-i1.md`, `-u4c-i2.md`

Scope check: in scope. The branch changes a cross-cutting concern (which copy of the gate runs, for every repository) and module structure (the canonical D6 copy moves from `test/lib/d6-snippet.bash` into SKILL.md; the tests extract it), and adds a per-iteration observer (step 0.1) with two new entry slugs. Decided items are not re-filed: i1 findings 3-5 (C6 Deferred; awk seam; GT), i2 findings 1-4 (D2, D3, D4 Fixed; D8, D9 Won't-Fix). Their basis is unchanged at 43b8d7ed except where noted below.

Trust-boundary cross-reference: newest security review is `docs/reviews/security-review-2026-10-13-u4c-i2.md` (Commit: `f2cc21e6` — security review predates this diff's last commit; boundary may be stale for 43b8d7ed's `merge-base` branch, though no boundary moves). Its B6 (`.manifest` commit= → step 0.1 → entry or note), B7 (MAIN_WT main → `hg diff --quiet` → entry or note) and B8 (host HEAD → install.sh → image) bracket step 0.1. No recommendation below moves a crossing.

## Dependency Map

- **Gate selection (cross-cutting):** before the branch, claude-workflows ran main -> (hash-verified reader) -> gate; now every repository runs main -> (release cut by hand via install.sh, B8) -> `/opt/claude-workflows` image -> gate. The installed skill comes from the same image, so the D6 block an orchestrator pastes and the scripts it runs are version-locked. The dependency points at a root-owned release artifact, never at repository data, which is the right direction for a trust root.
- **The D6 block (module structure):** one canonical copy in `SKILL.md` "The D6 block". `build-loop-orchestrator.bats` `d6_copy` extracts it with awk and patches only `D6_OPT` and (with literal `trust`) `own()`. `test/lib/d6-snippet.bash` and `build-loop.sh`'s pointer to it are gone; no remaining reference (grep of `d6-snippet` in scripts/ and test/ is empty).
- **GATE_CODE path set:** authority in the lib (`dev-cycle-read.sh:1970`); slug-rule line in SKILL.md (pinned byte-equal); step 0.1's PATHS line (pinned by a literal of GATE_CODE plus a one-line `grep -cxF`, new in 43b8d7ed); `build-loop.sh` header prose (unpinned, behaviour-free).
- **Step 0.1 observer:** reads the root-owned `.manifest` (C, A) and MAIN_WT's `refs/heads/main` (M) through `hg`; writes only questions entries (`image-off-main` you: judgment, `image-lag` you: terminal) or a record note; never a stop. Nothing in the gate depends on it. install.sh writes `dirty=no` always ("the payload is exactly the commit's content", `install.sh:355`), so C fully identifies the image and the observer's single-field read is sufficient.
- **Plan coupling:** plan :356 now makes U5's release entry the `image-lag` entry's body ("one slug, one paste"), closing i2 finding 2's overlap.

## Findings

#### 1. `image-off-main` has no close rule and its "keep" option is not durable

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:288-290`
**Move:** 2 (responsibility boundaries), 8 (extension points)
**Confidence:** Medium
**Legibility-target:** step 0.1's `image-off-main` sentence
**Introduced by this branch:** yes (43b8d7ed)

Evidence: "if `hg -C MAIN_WT merge-base --is-ancestor C M` exits 1, the gate that runs was built off main: file one `you: judgment` entry `image-off-main` naming C, unless one is open (options: rebuild from main, the paste below; or keep)." Compare `image-lag`: "Exit 0: an open `image-lag` entry is answered `done: the image holds main's gate code` (this diff is the observation)."

The fix for i2 finding 2 (D3) gave `image-lag` a lifecycle: file, rewrite, close on observation. The sibling slug added in the same commit has only "file unless open". Two consequences:
- After a rebuild from main, the next iteration takes the is-ancestor-exit-0 branch and never touches `image-off-main`, so an OPEN entry keeps saying the gate is off main when it is not. That is the same stale-entry state i2 finding 2 flagged for `image-lag`.
- If the user answers "keep", step 1's `questions.sh archive` moves it out; the next iteration finds none open and re-files it, every iteration, for the same C. A `you: judgment` entry is the scarcest attention route, and "keep" here costs the user one re-answer per cycle.

Advisory only, never a stop, so the harm is attention and a misleading open entry, not a wrong gate.

**Recommendation:** Key the entry on C: file only when no entry (open, or answered "keep") names this C; and on is-ancestor exit 0, answer an open `image-off-main` `done: the image's commit is on main` by the same observation rule `image-lag` uses.

#### 2. Outcome order makes "a missing `.manifest` or line: note it" unreachable, so the observer's own input fault reads as "not this repository"

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:286-288`, `:298-299`
**Move:** 2 (responsibility boundaries)
**Confidence:** High
**Legibility-target:** step 0.1's first test
**Introduced by this branch:** yes (the split, 43b8d7ed, D4)

Evidence: "C and A are the `commit=` and `assembled_from=` lines of `/opt/claude-workflows/.manifest`, M main's commit. If `hg -C MAIN_WT cat-file -e 'C^{commit}'` fails, the image was not built here: skip silently." … "A missing `.manifest` or line, or any other exit: note it in the record." Executed here: `git cat-file -e '^{commit}'` (C empty) → "fatal: Not a valid object name ^{commit}", exit 128 — the skip branch (fact-check Claim 6, r1).

D4 correctly split "not the image's repository" (expected) from faults, but the fault test now runs after the skip test, so an empty C always skips silently. In claude-workflows, an image with no manifest (or a manifest without `commit=`) is then indistinguishable from running in another repository, and the lag check silently stops observing. This is the fail-open-to-unobserved pattern i1 finding 1 was about, narrowed to a malformed image.

**Recommendation:** Test the manifest first: no `.manifest` or no `commit=` line → note it in the record; only then apply the `cat-file -e` skip. One clause reorder.

#### 3. The PATHS pin is closed only through a literal of GATE_CODE

**Severity:** Informational
**Location:** `test/scripts/build-loop-orchestrator.bats:347-354`
**Move:** 7 (coupling surface)
**Confidence:** High
**Legibility-target:** the test's failure message
**Introduced by this branch:** yes (43b8d7ed)

Evidence: `[ "$g" = '^scripts/(build-loop|dev-cycle|questions)\.sh$|^scripts/lib/|^skills/dev-cycle/' ] || { echo "GATE_CODE changed: update step 0.1's PATHS line and this test: $g"; return 1; }` and `for p in $P; do [[ "$p" =~ $g || "${p}x" =~ $g ]] || …`.

D2 is resolved: a GATE_CODE change fails this test, so the copy now fails closed. The loop checks P ⊆ GATE_CODE, not the reverse; the converse is held only by an editor who updates the literal also updating P, which the failure message asks for (fact-check Claim 7's mutation: widening both GATE_CODE and the literal passes with PATHS unchanged). That is acceptable for a three-alternative regex.

**Recommendation:** None required. Optionally assert each GATE_CODE alternative is matched by some P entry, which would make the pin two-directional without the literal.

#### 4. Step 0.1 is now a small decision procedure in prose inside a GATE_CODE path

**Severity:** Informational
**Location:** `skills/dev-cycle/SKILL.md:285-299`; plan `:356`
**Move:** 2 (responsibility boundaries)
**Confidence:** Medium
**Legibility-target:** plan U5 step 11
**Introduced by this branch:** yes

Evidence: three ordered tests (`cat-file -e`, `merge-base --is-ancestor`, `diff --quiet`), two slugs on two routes, one paste, one close rule, one note path — in 14 wrapped lines. Plan :356: "U5 makes the release entry the `image-lag` entry's body (one slug, one paste)", which will add the F58 commit-and-path listing to it.

i2 finding 1 already weighed making this a script mode and rejected it (run through D6, it would use the image's stale logic exactly when it matters); that reasoning holds, so prose is the right home. The cost is that each widening (U5's F58 listing; findings 1-2 here) is edited and reviewed as prose, and only the PATHS line is mechanically pinned.

**Recommendation:** When U5 widens the body, consider listing the step 0.1 outcomes as a short enumerated list (condition → entry/note), so each outcome's lifecycle (file, rewrite, close) is visible at a glance and asymmetries like finding 1 show.

#### 5. Prior Coupling findings are resolved

**Severity:** Informational
**Location:** `skills/dev-cycle/SKILL.md:42-43`, `:286-299`; plan `:356`, `:432`, `:441`; bats `:347-354`
**Move:** 1, 7
**Confidence:** High
**Legibility-target:** none (confirmation)
**Introduced by this branch:** n/a

Evidence: plan :356 "Since U4c, step 0.1's `image-lag` entry is that release entry's trigger … not a second entry"; SKILL.md "`scripts/build-loop.sh scripts/dev-cycle.sh scripts/questions.sh scripts/lib/ skills/dev-cycle/`" on its own line, pinned; "Exit 1: the gate that runs differs from main's".

i1 Coupling 1 (no lag signal; Rollback) — resolved in i2 and still holds. i2 Coupling 1 (unpinned PATHS) — resolved (finding 3). i2 Coupling 2 (two entries for one action; no body; no close) — resolved for `image-lag` (body, paste, interim, close; plan :356 joins U5); the sibling slug's lifecycle is finding 1. i2 Minor 3 ("older") and 4 (skip vs fault) — fixed in wording; finding 2 is the ordering residue of 4. The fact-check's Claim 1 (row 819 / D9 wording) is a documentation inaccuracy with no structural consequence; it is the orchestrator's to amend.

**Recommendation:** None.

## What Looks Good

- **One canonical copy, extracted, not mirrored.** Deleting `test/lib/d6-snippet.bash` and extracting the block from SKILL.md removes a two-copy sync obligation; the extraction fails closed on every shape change (i1 finding 4).
- **The trust root points at a release artifact.** No repository data chooses the script; the residual (same-uid shell) is named rather than claimed away.
- **The observer stays an observer.** Step 0.1 never stops, never changes which script runs, and writes only triage — consistent with "attention is the budget".
- **`image-off-main` before `image-lag`.** Checking ancestry first keeps the lag diff from prescribing a rebuild for an image built off main (D1), and the paste's `test "$(git rev-parse HEAD)" = M` binds the release to main at the host.
- **`.manifest`'s C is sufficient.** install.sh always writes `dirty=no` from a `git archive`-style payload, so the one-field read is a faithful image identity.
- **Tests:** bats `build-loop-orchestrator.bats` 26/26 at 43b8d7ed (run in this pass).

## Summary Table

| # | Finding | Severity | Location | Confidence | Introduced here |
|---|---------|----------|----------|------------|-----------------|
| 1 | `image-off-main` has no close rule; "keep" is re-filed every iteration | Minor | `SKILL.md:288-290` | Medium | yes |
| 2 | Missing-manifest fault is unreachable: empty C skips silently as "not this repository" | Minor | `SKILL.md:286-288`, `:298-299` | High | yes |
| 3 | PATHS pin is one-directional, closed via a GATE_CODE literal | Informational | bats `:347-354` | High | yes |
| 4 | Step 0.1 is a prose decision procedure; enumerate outcomes when U5 widens it | Informational | `SKILL.md:285-299`; plan `:356` | Medium | yes |
| 5 | i1/i2 Coupling findings resolved | Informational | as listed | High | n/a |

## Overall Assessment

The branch improves structural integrity: the gate's trust root moves from repository data to a root-owned release artifact, the D6 block has one canonical copy that tests extract rather than mirror, and the lag that inversion creates now has a mechanical, non-blocking observer keyed to a pinned copy of GATE_CODE and joined to U5's release entry. **No finding is Structural or Coupling, introduced by this branch or otherwise.** The two Minor findings are lifecycle and ordering gaps in step 0.1's newest text (43b8d7ed): `image-off-main` lacks the close-on-observation rule its sibling got, and the manifest-fault branch is shadowed by the not-this-repository skip. Both are one-sentence fixes in place and both are advisory-path only. The most important remaining concern is finding 2, because it is the one path by which the observer silently stops observing in claude-workflows.

## Goal-Alignment Note
- Success criterion (restated verbatim): a report saved to /workspace/.claude/wt-build-loop-u4c/docs/reviews/architecture-review-2026-10-13-u4c-final.md (first line `Commit: 43b8d7ed`), per the skill.
- Answered: yes. No Structural or Coupling finding, introduced by this branch or otherwise; 2 Minor (both introduced by 43b8d7ed), 3 Informational. Prior Coupling findings (i1 1, i2 1, i2 2) confirmed resolved.
- Out of scope: the row 819 / D9 wording inaccuracy (fact-check Claim 1; documentation, orchestrator's to amend); root and host runs (Claim 9); security of `.manifest` and the host checkout (B6, B8; security-reviewer's); decided items i1 3-5, D8, D9.
- Escalate: none blocking. Findings 1 and 2 are the loop's call to fix here or defer by override row.
