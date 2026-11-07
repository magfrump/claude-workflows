Commit: 4dd68cdc

# Architecture Review — refactor/d6-block-into-image

**Scope:** `git diff 5b20d4bd..HEAD -- . ':!docs/reviews'` (9 files, five commits); read around it: `scripts/d6.sh` whole, `git_harden`, `resolve_main`, `default_gate`, `install.sh` staging, `link-claude-home.sh`, the Dockerfile payload lines, SKILL step 0.1
**Date:** 2026-11-05
**Based on:** `docs/reviews/code-fact-check-report-2026-11-05-d6-block-into-image.md` (Commit: 9f80368a, one commit behind HEAD; 4dd68cdc fixed its Incorrect and Stale items in d6.sh's comment, the tests, the plan rows and the research doc, re-read here)

**Verdict: the structure is sound and the release-ordering argument holds. One Coupling finding (a one-line fix plus two bats cases), three lower ones.** Scope check: in scope under module structure (a new script) and cross-cutting concerns (the gate's entry path).

## Dependency Map

```
SKILL.md (image) --one line, absolute path--> /opt/.../scripts/d6.sh
d6.sh --source, in a subshell, for git_harden only--> scripts/lib/dev-cycle-read.sh
d6.sh --exec--> build-loop.sh | dev-cycle.sh | questions.sh
build-loop.sh, dev-cycle.sh --source--> scripts/lib/dev-cycle-read.sh
dev-cycle.sh --runs--> questions.sh
```

Dependencies run from the entry point toward the library. There is no cycle: nothing calls d6.sh, and the lib and build-loop.sh only name it in comments. d6.sh checks the lib's presence (`scripts/d6.sh:43-47`) before its first source (`:50`), so the order is right.

Trust-boundary cross-reference: the most recent security review is `docs/reviews/security-review-q092b-pass2-2026-10-15.md` (Commit: `c9ff3e84` — security review predates this diff; boundary may be stale). Its B1 to B4 cover the permission hook and settings, and none coincides with a finding below. No security review of this branch exists yet.

## Probes

All ran under `timeout` at 4dd68cdc in `/tmp/claude-1000/-workspace/47403b7b-5fcb-4e13-8807-c539081df064/scratchpad/2026-11-05-d6-block-into-image/arch1/` (`probe.log`, `bats.log`). No process remains.

| Id | What | Result |
|---|---|---|
| P1 | `bats -f 'd6\|GATE_CODE\|git_harden' test/scripts/build-loop-orchestrator.bats` | 15 of 15 ok |
| P2 | `git archive HEAD scripts skills` into a stand-in with the Dockerfile's modes, D6_OPT changed in place, the skill's call shape run against `$U/scripts/d6.sh`, also from zsh | `--state` ok, `--settings` ok, `--check-path` ok; `questions.sh open` reached its own missing-file error |
| P3 | Lib and `git_harden` failures through d6.sh | see finding 1 |
| P4 | A repo with `main` and `origin/HEAD` at `trunk` | see finding 3 |

## Findings

#### 1. A lib or `git_harden` failure is read as git's "ref absent", so the refusal names the wrong cause

**Severity:** Coupling
**Location:** `scripts/d6.sh:36`, `scripts/d6.sh:50-54`
**Move:** 7 (coupling surface), 3 (module boundary)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**

```bash
# scripts/d6.sh:36
g() { ( source "$D6_OPT/scripts/lib/dev-cycle-read.sh" && git_harden && git "$@" ); }
# scripts/d6.sh:50-51
  rc=0; g show-ref --verify -q "refs/heads/$n" || rc=$?
  [[ "$rc" -le 1 ]] || no "refs/heads/$n could not be read"
```

Research line 104: `exit 1 reads as absent for both names, and any other exit as "could not be read", so the line can name the wrong cause`. P3 output, repo with one plain `main`:

```
-- caller GIT_CONFIG_COUNT=010
d6.sh: GIT_CONFIG_COUNT is not a plain decimal count
d6.sh: GIT_CONFIG_COUNT is not a plain decimal count
refuse d6: the default branch is not exactly one of main and master
-- lib last line: return 1
refuse d6: the default branch is not exactly one of main and master
```

An unset variable at the lib's top level gives the same `refuse d6:` line, and a lib with no `git_harden` gives `refuse d6: refs/heads/main could not be read`.

`g` puts three failure sources behind one status, and `show-ref`'s exit 1 means "no such ref". This failure path is new: the old block's git came from a literal list and could not fail in the lib. It fails closed in every shape, so nothing unsafe runs. But the `refuse d6:` line is what the skill files, and here it states a false fact about the repository, with nothing on stderr in the `return 1` case. That sends the owner to inspect branches for an image or environment fault. H2 requires a refusal to name what went unenforced, and its success line requires a bats case for each new failure path. T36 has no broken-lib or bad-count case (`rg 'broken|fails to source'` over the bats file finds none). The research doc accepts the wrong cause; H2 is a hard line, so I do not think a pre-mortem note discharges it.

**Recommendation:** Probe the lib once before the loop, so a status from `g` can only be git's: `( source "$D6_OPT/scripts/lib/dev-cycle-read.sh" && git_harden ) || no "the image lib or git_harden failed"`. `git_harden`'s own `exit 1` ends that subshell, so it is caught too. Add two T36 cases: a lib ending `return 1`, and `GIT_CONFIG_COUNT=010`.

#### 2. No test runs d6.sh from `D6_OPT/scripts/`, and the stand-in image does not hold it

**Severity:** Minor
**Location:** `test/scripts/build-loop-orchestrator.bats:252-257`, `:285-286`, `:389-392`
**Move:** 1 (dependency direction; the dispatch's real-position check)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**

```bash
# test/scripts/build-loop-orchestrator.bats:254
    cp "$REPO_ROOT/scripts/d6.sh" "$D6"
# :257
opt_copy() { mkdir -p "$1/scripts/lib" && cp "$REPO_ROOT"/scripts/{build-loop,dev-cycle,questions}.sh "$1/scripts/" && cp "$REPO_ROOT/scripts/lib/dev-cycle-read.sh" "$1/scripts/lib/"; }
# :391
    d6_copy "$O"; d6 build-loop.sh --help
```

The answer to "do the tests pin the shipped file in its real position" is: its content yes, its position no. `d6_copy` runs the shipped bytes with one literal changed, which is a real gain over the awk extraction and the old `own()` substitution. But the copy sits at `$BATS_TEST_TMPDIR/d6.bash`, and `opt_copy` leaves d6.sh out of the stand-in, so the skill's call line is only ever run on the path where d6.sh is missing (exit 127). The route into the image is pinned by grepping `CLAUDE_HOME_SRC` and the Dockerfile's `find` line. T37, the one case that touches the real `/opt`, runs the repo's copy rather than the image's. So the first run of `/opt/claude-workflows/scripts/d6.sh` is the first real cycle after the release.

The risk today is small. d6.sh cannot depend on its own path (the test forbids `BASH_SOURCE`, `$0` and `dirname`), P2 passed from the real position, and a failure there is a loud stop. This is a gap in the pin, not a defect found.

**Recommendation:** In T37, when `$O/scripts/d6.sh` exists, run that file with no copy and no literal change; its existing skip covers images without it. Add d6.sh to `opt_copy` and run the skill's line once on the positive path. The first change gives the release a test of the real image file at no host cost.

#### 3. The default-branch rule has three readers that can disagree, and d6.sh's copy no longer has its reason to stand apart

**Severity:** Minor
**Location:** `scripts/d6.sh:48-54`, `scripts/build-loop.sh:764-770`, `scripts/lib/dev-cycle-read.sh:547-556`
**Move:** 2 (responsibility), S3 (one source of truth per rule)
**Confidence:** Medium (facts High; whether to unify is a judgment)
**Legibility-target:** for-author

**Evidence:**

```bash
# scripts/d6.sh:49
for n in main master; do
# scripts/lib/dev-cycle-read.sh:552 (after origin/HEAD's target)
  candidates+=(main master)
# scripts/build-loop.sh:770
  [[ "$MAIN" == main || "$MAIN" == master ]] || { echo "refuse state default-branch: the default branch taken is $MAIN, not main or master"; bad=1; }
```

P4, `main` plus `origin/HEAD` at `trunk`: d6.sh passes, `--state` prints `refuse state default-branch: the default branch taken is trunk, not main or master`, and the digest through d6.sh reports `0 merge(s) on `trunk`'s first-parent line`.

Research line 65 keeps d6.sh's check as `the only such check `dev-cycle.sh` and `questions.sh` have`, but it vets `main` while `dev-cycle.sh` reads whatever `resolve_main` picks. In a cycle `--state` runs first and stops this, so the effect is bounded, and the block had the same split: it is carried over, not introduced. What changed is the premise. Research line 28 gives "cannot source the lib" as the reason for repeating a list, and that no longer holds. The branch removed the repeated HARDEN list but left this restated rule, and a change to the rule must now touch three places, one of them only linked by a comment (`scripts/build-loop.sh:760`).

**Recommendation:** Not a merge blocker. Either file a follow-up for one lib predicate that d6.sh and `default_gate` share, or add a clause to d6.sh's header that it checks the two names only and that `--state` owns the origin/HEAD case.

#### 4. d6.sh takes the whole 1,226-line lib for one function; `git_harden`'s comment still lists two callers

**Severity:** Informational
**Location:** `scripts/d6.sh:36`, `scripts/lib/dev-cycle-read.sh:13-14`, `:309-311`
**Move:** 1 (dependency direction), 7 (coupling surface)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**

```bash
# scripts/lib/dev-cycle-read.sh:13-14
# scripts/d6.sh is the exception to what follows: it sources the image copy in
# a subshell for git_harden alone, with no -e and no ROOT_REAL.
# scripts/lib/dev-cycle-read.sh:309-311
# (merge_ident reads the caller's global config); build-loop.sh and
# dev-cycle.sh call it once, after scrub_reexec and before their first git
# call (D6 runs both as gate code: rows 281, 495). Each pin keeps the gate's
```

The direction is right and reusing `git_harden` is what S3 asks for: this is a net removal of a pinned duplicate. The coupling is data-level, one function with no arguments. The cost is breadth: every top-level line of a library that changes often now also has to source cleanly under d6.sh's `set -u` without `-e`, and a fault there stops `questions.sh`, which uses nothing from the lib. The lib's header already had to gain an exception for this caller. At this scale that is acceptable, and I would not split the file for it. Moving `git_harden` to its own small file under `scripts/lib/` would narrow the dependency if the lib's top level ever grows; GATE_CODE already covers that directory.

**Recommendation:** Leave the structure. Add d6.sh to the comment at line 309 next time that area is touched.

## What Looks Good

- **Release ordering: holds.** `extract_commit "$commit" "$stage" "${CLAUDE_HOME_SRC[@]}"` stages skill, scripts and lib from one commit (`devcontainer-config/install.sh:348`), and `~/.claude/skills` and `~/.claude/scripts` are symlinks into that same `/opt` tree, refreshed at each container start. So in a running container the installed skill and d6.sh are one filesystem image, not two things that must be kept in step. d6.sh's dependence on `git_harden` has the same guarantee. The two exceptions both land on rows the research table already covers: a genuine non-symlink `skills` entry, which `link-claude-home.sh` leaves alone, and a project-level skill in another repo (the fact-check's Claim 10 scope limit). A stale skill with a new image works, and a new skill with an old image is the exit 127 stop. The gap where the old image's floor does not list `scripts/d6.sh` is real but is stated in pre-mortem item 3, bounded by the release and listed in `image-lag`.
- **`D6_OPT` stays a literal**, with the test forbidding path derivation. This is what makes a working-tree copy harmless, and it keeps H1 independent of how the file is reached.
- **The subshell in `g`** keeps hardening out of the child's environment, so the script's own `git_harden` does not count d6.sh's pairs as the caller's. It is a small structure that removes a real ordering hazard, and test 8 pins it.
- **`scripts/d6.sh` over `bin/d6`**: no enforcement-file change, no `install.sh` growth (S8), and the file enters GATE_CODE with every restatement updated and test-pinned where the old copies were.
- **The skill loses its 67-line block section** and the awk read-back of its own text. S4 is served, and the tests now execute a file rather than extract prose.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Lib or `git_harden` failure read as "ref absent"; wrong cause, no H2 bats case | Coupling | `scripts/d6.sh:36,50-54` | High |
| 2 | No test runs d6.sh from `D6_OPT/scripts/`; stand-in omits it | Minor | `test/scripts/build-loop-orchestrator.bats:252-257,389-392` | High |
| 3 | Three readers of the default branch can disagree | Minor | `scripts/d6.sh:48-54` | Medium |
| 4 | Whole-lib dependency for one function; stale caller comment | Informational | `scripts/lib/dev-cycle-read.sh:309-311` | High |

## Overall Assessment

This change improves the structure. A pasted, test-extracted block becomes a small file with a correct dependency on the lib, one hardening list instead of two, and a release story that rests on one commit and one filesystem tree rather than on discipline. Everything found is fixable in place and nothing needs restructuring. The most important concern is finding 1: it is the only place this diff adds a failure mode, and that mode reports a false reason to the owner, though it never lets anything through.

## Goal-Alignment Note
- Success criterion (restated verbatim): a report saved to docs/reviews/architecture-review-2026-11-05-d6-block-into-image.md, first line `Commit: <HEAD short sha>`, each finding carrying Severity, Location, verbatim Evidence, Confidence and Legibility-target, ending with a Goal-Alignment Note (patterns/orchestrated-review.md).
- Answered: yes; all three named checks covered (release ordering holds; d6.sh to lib direction is right, finding 1 is at its boundary; tests pin content, not position, finding 2).
- Out of scope: the whole test suite and health check; a built image; correctness of dropping the R6c to R6e checks (security and owner call); hostile-author readings (S1).
- Escalate: the research doc's owner question (brief Goal says the block's checks keep running, the branch narrows them) is not in `docs/working/questions.md` on this branch, so it needs to reach the owner at landing; no security review of this branch exists yet.
- Decisions I made: Rated finding 1 Coupling rather than Minor because it misses H2's stated bats case, though it fails closed; Minor is defensible given how rare the trigger is. Treated finding 3 as Minor although it predates the branch, because the branch removed the premise for the restatement; it could be left out as pre-existing.
