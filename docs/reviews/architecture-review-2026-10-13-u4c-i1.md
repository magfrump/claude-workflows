Commit: 1bc823ea

# Architecture Review — feat/build-loop-u4c (loop pass i1)

**Scope:** `git diff main...feat/build-loop-u4c` (one commit, 1bc823ea): `skills/dev-cycle/SKILL.md`, `test/lib/d6-snippet.bash` (deleted), `test/scripts/build-loop-orchestrator.bats`, `scripts/lib/dev-cycle-read.sh` (GATE_CODE comment), `scripts/build-loop.sh` (store_check comment), `docs/working/plan-build-loop-handoff.md`
**Date:** 2026-10-13
**Based on:** `docs/reviews/code-fact-check-report-2026-10-13-u4c-i1.md` (Stage 1, k=1); prior decisions in `docs/reviews/override-log.md` (2026-10-12 U3b3 D6 rows, rows 738/739/741/742, 775, 807-811)

Scope check: in scope. The diff moves a module (the D6 snippet leaves `test/lib/` and becomes a section of `skills/dev-cycle/SKILL.md`), widens its public surface (SCRIPT now also takes `questions.sh`), and changes a cross-cutting concern (which copy of the gate runs, and so when a merged gate change takes effect).

Trust-boundary cross-reference: the newest security review on disk is `docs/reviews/security-review-2026-10-13-u4b2-i2.md` (Commit: `adc8a176`). That review predates this diff, so its boundaries may be stale, and none of its labels B1-B7 covers the D6 image boundary. No finding below cites a label. The image boundary (the root-owned `/opt/claude-workflows` copy against everything the uid can write) is security-reviewer's to map. No recommendation here moves it.

## Dependency Map

Before U4c, the dependency on gate code in claude-workflows ran **main -> gate**. The snippet ran main's committed scripts through a hash-verified reader, so a reviewed `merge-gate-` merge was live at the next merge. Every other repository already ran the image copy.

After U4c, every repository runs **image -> gate**. The image is built from main (`/opt/claude-workflows/.manifest`, currently `774a0eef`), so the chain is now main -> (release you cut) -> image -> gate decisions about main. The same image also supplies the skill the orchestrator follows (`~/.claude/skills -> /opt/claude-workflows/skills`; the installed `dev-cycle/SKILL.md` there is pre-U4 and has no "The D6 block" section). As a result the D6 block an orchestrator pastes and the scripts that block runs now come from one build and are version-locked. The repo's `SKILL.md` is read by the tests and by reviewers. Its block reaches a session only through a release.

Inside the repo:
- `skills/dev-cycle/SKILL.md` "The D6 block" is the only canonical copy (a GATE_CODE path, so floor item 3 covers it).
- `test/scripts/build-loop-orchestrator.bats` pulls that copy out with awk (`d6_copy`). It sed-patches `D6_OPT`, and with `trust` it also patches `own()`, so the snippet can run against a uid-owned stand-in.
- The snippet's `G` and SKILL.md's `hg` each repeat the lib's `HARDEN` pairs and `git_harden`'s environment. One test pins both against the lib.
- Step 7's GT (a per-call detached worktree at main's commit) serves `build-loop.sh`'s `checkout_gate` (`build-loop.sh:1394`, lib contract item 2 at `dev-cycle-read.sh:71`). Its job does not depend on which copy of the script runs.

## Findings

#### 1. Nothing in the cycle signals or acts on "main's gate code is ahead of the image", and the plan's rollback still assumes a revert on main reverts the gate

**Severity:** Coupling
**Location:** `skills/dev-cycle/SKILL.md:40-43`; `docs/working/plan-build-loop-handoff.md:436-440` (Rollback 1); `docs/working/plan-build-loop-handoff.md:356`
**Move:** 1 (dependency direction), 7 (coupling surface)
**Confidence:** High on the facts, Medium on severity
**Legibility-target:** the plan's Risks and Rollback sections, and SKILL.md's close step

Evidence: SKILL.md:41-43: "it runs the root-owned image copy (Q-140 [1]), so nothing a build loop can write chooses or changes what runs as the gate, and a gate change merged here runs from the next image release." Rollback 1: "Each unit lands as its own `--no-ff` merge on main. Revert in reverse order: `git revert -m 1 <U5> <U4> …`".

Q-140 [1] inverts the dependency on purpose: the gate now depends on a release artifact, not on main. That is the right direction for a trust root. The cost is a new lag between the two, and nothing in the system watches it.
- A reviewed `merge-gate-` fix lands on main but does not protect anything until someone rebuilds the image. A floor or GATE_CODE hole closed on main stays open for every later self-merge, because the image's older rules keep deciding.
- The cycle has no step that compares main's gate code with the image's `.manifest` commit. `grep -i 'release\|manifest' skills/dev-cycle/SKILL.md` finds only the Rule line and the snippet header. The release entry is still a U5 bullet (plan:356).
- Rollback step 1 now restores main's text but not the gate that runs. Undoing a bad gate release needs an image rebuild, and the Rollback section never mentions one.
- The coupling that used to be "live at the next merge" is now "live at a release nobody is prompted to cut", which is an unobserved state.

**Recommendation:** Give the cycle one mechanical signal: at step 0 or in the digest, compare the GATE_CODE paths changed since the image's `.manifest` commit and, when there are any, file or refresh one `you: terminal` release entry, which is the release entry U5 already plans. Add "rebuild the image from the reverted main" to Rollback 1 for any unit that touched GATE_CODE. If the signal is deferred to U5, give U5's release-entry bullet that trigger now.

#### 2. Plan text and the floor's rationale still state the old "gate does not wait" coupling

**Severity:** Minor
**Location:** `docs/working/plan-build-loop-handoff.md:356`, `:432`, `:68-71`; `scripts/lib/dev-cycle-read.sh:1962-1968`
**Move:** 2 (responsibility boundaries)
**Confidence:** High
**Legibility-target:** the plan (D5 item 3, Risks, U5 release bullet) and the GATE_CODE comment

Evidence:
- plan:356: "One `you: terminal` release entry: rebuild and bless, so the image's dev-cycle skill carries this unit. The gate does not need it (D6), but the installed skill does."
- plan:432: "The image lags main. … The gate itself does not wait (D6)."
- plan:68: "**The floor** refuses … only paths that **take effect on merge with no later review**", whose item 3 is now "live at the next release".

Both :356 and :432 are now false. The gate waits too, and per the plan's own as-built note it needs this release specifically, because the image predates `--land-cycle`. The fact-check report flagged :432 but not :356. Floor item 3 also no longer meets its parent's criterion: gate code takes effect at a release, the same as the scripts D5 lets self-merge. The lib comment acknowledges this ("here the floor is stricter than D5"), but the plan still files the item under "take effect on merge".

Keeping gate code under `merge-gate-` review is still a sound policy, because a release review is a skim (F58), but its reason has changed and the plan should state the new one. Otherwise a later reader who applies D5's criterion literally could decide item 3 should go.

**Recommendation:** Fix :356 and :432. In floor item 3, say it is kept by choice, not by D5's on-merge criterion: gate code is the one release-gated path where a skimmed release is not enough review. Match the fact-check's stale items (:77, :157, :158, :394, :396) in the same edit.

#### 3. The snippet's repository checks are now its only reason to run git, and so its only reason to carry a third HARDEN copy

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:219-234` (G and the replace-ref, grafts and default-branch checks), `skills/dev-cycle/SKILL.md:66` (hg); `test/scripts/build-loop-orchestrator.bats:338-342`
**Move:** 2 (responsibility boundaries), 7 (coupling)
**Confidence:** Medium
**Legibility-target:** the snippet header and the git_harden test

Evidence: snippet header: "These checks come before, not instead of, build-loop.sh's own state and default-branch gates in its gated modes (dev-cycle.sh, questions.sh and the read modes have none: row 548)." And the test now asserts `[ "$(grep -c '^  G=(env ' "$REPO_ROOT/skills/dev-cycle/SKILL.md")" -eq 1 ]` next to the `hg` count.

Before U4c, the replace-ref and grafts checks guarded the snippet's own reads of MAIN_SHA. Those reads are gone. The checks now act as a pre-gate on repository state for the image scripts, which partly duplicates `build-loop.sh`'s gated modes and partly stands in for gates that `dev-cycle.sh` and `questions.sh` lack. That is a policy job living in a launcher. It is also the only reason `G` exists, which means SKILL.md carries two copies of HARDEN (`G` and `hg`). The test holds both to the lib, so drift is caught, but each HARDEN change edits three places.

Moving the checks into the scripts has a real cost: standalone `dev-cycle.sh` users and the loops' advisory `--check` runs would start refusing too. Keeping them where they are is defensible.

**Recommendation:** Decide this on purpose rather than by inheritance. Either record in the header that the snippet is the repository-state gate for `dev-cycle.sh` and `questions.sh` (so a later edit does not drop the checks as vestigial), or open a roadmap item to move them into those scripts' lib entry point. That would leave the snippet as a pure verify-image-and-exec launcher with no git and no `G`. No change is needed in this unit.

#### 4. The awk seam is sound and fails closed; its remaining coupling is to three exact line shapes

**Severity:** Informational
**Location:** `test/scripts/build-loop-orchestrator.bats:233-238` (d6_copy), `:254-259` (T33)
**Move:** 3 (module boundary), 7 (coupling)
**Confidence:** High
**Legibility-target:** the d6_copy comment

Evidence: `awk '/^## The D6 block$/ { s = 1 } s && b && /^D6$/ { exit } b { print } s && /^cd WT && bash -s -- SCRIPT ARG\.\.\. <<.D6.$/ { b = 1 }'`

Here is what each change to SKILL.md would do:
- **Renamed heading, or a changed call line.** The extract comes out empty, `grep -qxF '  D6_OPT=/opt/claude-workflows'` fails, `d6_copy` returns 1, and the test fails.
- **A stray bare `D6` line inside the body.** The extract is cut short, and T33's last-line check (`d6 "$@" </dev/null`) plus the file-wide `^D6$` count of 1 catch it.
- **A second column-0 call line, such as an example placed before the real one.** T33's count of 1 catches it.
- **The `D6_OPT=` and `own()` patches.** Each is guarded by a `grep -qxF` of its result.
- **Prose before, after or around the section.** It can change freely without breaking anything.

The leftover coupling is between the tests and three exact lines: the heading, the call line, and the `  D6_OPT=` and `  own() { ` shapes. That coupling is intended, and every break shows up as a failure, never as a silent pass. One gap is outside architecture: the `trust` stub means the ownership walk over the directories above the image files runs unpatched only in the `/opt` success case (fact-check, Tests).

**Recommendation:** None required. Optionally add one line to the d6_copy comment that names the three line shapes, so an editor of SKILL.md knows which lines the tests key on.

#### 5. Step 7's GT is not dead weight

**Severity:** Informational
**Location:** `skills/dev-cycle/SKILL.md:536-545`; `scripts/build-loop.sh:1394`; `scripts/lib/dev-cycle-read.sh:71`
**Move:** 1
**Confidence:** High
**Legibility-target:** none (confirmation)

Evidence: `build-loop.sh:1394`: "refuse $a: a self-merge brief needs --check run from a clean checkout of the default branch's commit; $CHECKOUT_WHY".

GT exists because `checkout_gate` requires the gate's cwd to be a clean checkout at MAIN_SHA, which the floor's import walk reads. WT stops meeting that once the iteration edits it. None of this depended on running main's copy of the scripts, so U4c leaves GT's purpose intact. Nothing else built only for runs of main's copy survives: the reader, D6_ROOT, the temp dir, the EXIT trap and the SHA-1 branch were all removed, along with the five tests that exercised them. The `--state` from MAIN_WT before the GT add is still needed, because the worktree add copies MAIN_WT's config. The one leftover is the snippet's repository checks, covered in finding 3.

**Recommendation:** None. The fact-check already notes that the header line "each step names MAIN_WT or WT" omits GT. Fix it there.

## What Looks Good

- **One copy, inside the floor.** The canonical snippet used to live in `test/lib/`, which is not in GATE_CODE, with a pending byte-equality test against SKILL.md. Now the only copy is in `skills/dev-cycle/`, where GATE_CODE covers it, and the two-copy drift problem (rows 738/739) is gone instead of tested for.
- **The skill and the gate are version-locked.** The block the orchestrator pastes and the scripts it runs now ship in the same image, so protocol skew between SKILL.md's call forms and `build-loop.sh`'s modes can arise only across a release boundary. The plan names that boundary for `--land-cycle`.
- **The trust root no longer depends on repository data.** The run choice no longer reads anything a loop can write, which closes Q-140's forged-main and gitfile routes by construction instead of by checks.
- **A large deletion with a small surface change.** About 60 lines of perl and branch logic and five tests are gone. The only widening is a third value in the closed SCRIPT allowlist, which row 775 asked for.
- **Test-only injection.** The ownership stub is a sed patch applied to the test's copy, not a production knob, so the shipped snippet has no bypass parameter.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | No signal or action when main's gate code is ahead of the image; Rollback assumes a revert reverts the gate | Coupling | `skills/dev-cycle/SKILL.md:40-43`, plan:436-440, :356 | High / Medium |
| 2 | Plan :356, :432 and floor item 3's placement still state "gate does not wait" | Minor | plan:356, :432, :68-71; `dev-cycle-read.sh:1962-1968` | High |
| 3 | The snippet's repository checks are its only git use and the reason for a third HARDEN copy | Minor | `skills/dev-cycle/SKILL.md:219-234` | Medium |
| 4 | The awk extraction is sound and fails closed; it is keyed to three line shapes | Informational | `build-loop-orchestrator.bats:233-259` | High |
| 5 | Step 7's GT still serves checkout_gate; not dead weight | Informational | `skills/dev-cycle/SKILL.md:536-545` | High |

## Overall Assessment

U4c improves the structure. It removes a second canonical copy, puts the only copy under the floor, ties the skill to the gate by shipping both in one build, and moves the trust root off data a loop can write. All of this comes from deleting code rather than adding it. Every issue can be fixed in place, and none calls for restructuring. The most important concern is finding 1. The dependency now runs main -> release -> gate, yet the plan, the rollback and the cycle still treat a reviewed gate merge as live once it merges, and nothing reports when main's gate code has moved past the image. That leaves a gate fix in a state no step watches. A step-0 or digest check against the image `.manifest`, feeding the release entry U5 already plans, closes it. Findings 2 and 3 are wording and placement: state why gate code stays under `merge-gate-` review now that it no longer takes effect on merge, and decide on purpose whether the snippet stays the repository-state gate for `dev-cycle.sh` and `questions.sh`.

## Goal-Alignment Note
- Success criterion (restated verbatim): a report saved to /workspace/.claude/wt-build-loop-u4c/docs/reviews/architecture-review-2026-10-13-u4c-i1.md (first line `Commit: 1bc823ea`), structured per the skill.
- Answered:
  - The SKILL.md-as-canonical seam and what breaks when the surrounding text changes: finding 4. The seam is sound and fails closed.
  - What still assumes the repo -> gate "live at next merge" coupling: findings 1 and 2, covering the plan :356, :432 and Rollback 1, floor item 3's placement, and the cycle's missing image-lag signal.
  - GT and leftover machinery: finding 5 (GT is still needed; everything else was removed) and finding 3 (the leftover repository checks).
  - HARDEN in SKILL.md twice: finding 3. The duplication is held by one test and forced by the paste-to-run model only while the snippet keeps its git checks.
- Out of scope: exploitability of the PATH-resolved binaries and the -w-as-root claim (security-reviewer; fact-check items); test coverage of writable or symlinked parent directories (test-strategy); the decided D6 override rows, whose basis this diff discharges (741, 742) or leaves unchanged.
- Escalate: none blocking. Finding 1's signal could be routed to U5's release-entry bullet rather than this unit; that routing is the loop's call.
