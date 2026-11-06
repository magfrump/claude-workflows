Commit: 48498ba6

# Architecture Review (final pass) — refactor/d6-block-into-image

**Scope:** `git diff 5b20d4bd..48498ba6 -- . ':!docs/reviews'` (9 files, eight commits); read around it: `scripts/d6.sh` whole, the lib's top level, `git_harden` and `scrub_reexec`, the d6 tests and fixtures in `test/scripts/build-loop-orchestrator.bats`, SKILL Rules and step 0.1, the research doc, `docs/constraints.md`
**Date:** 2026-11-05
**Based on:** `docs/reviews/code-fact-check-report-final-r1-2026-11-05-d6-block-into-image.md`, `-r2-` and `-r3-` (Commit: 1c5fd04f, one commit behind; 48498ba6 changes 14 lines of prose and comments, re-read here) and `docs/reviews/architecture-review-2026-11-05-d6-block-into-image.md` (Commit: 4dd68cdc)

**Verdict: the fixes hold and the structure is sound. One new Minor finding, in the test fixture the finding 2 fix changed. Nothing blocks the merge.** Scope check: in scope under module structure (a new script) and cross-cutting concerns (the gate's entry path).

## Dependency Map

```
SKILL.md (image) --one line, absolute path--> /opt/.../scripts/d6.sh
d6.sh --source, in subshells, for git_harden only--> scripts/lib/dev-cycle-read.sh
d6.sh --exec--> build-loop.sh | dev-cycle.sh | questions.sh
build-loop.sh, dev-cycle.sh --source--> scripts/lib/dev-cycle-read.sh
dev-cycle.sh --runs--> questions.sh
```

Unchanged since the earlier pass, and there is no cycle: nothing calls d6.sh, and the lib and build-loop.sh only name it in comments. The presence loop (`scripts/d6.sh:45-49`) still comes before the first source (`:52`). The lib's top level is assignments and function definitions only, so sourcing it under `set -u` without `-e` runs nothing that depends on the caller.

Trust-boundary cross-reference: the most recent security review is `docs/reviews/security-review-2026-11-05-d6-block-into-image.md` (Commit: `4dd68cdc` — security review predates this diff; boundary may be stale). The `( harden )` line added after it sits inside B2 and moves no crossing. The finding below touches B5 only in that a test can write under `/opt`; its recommendation moves no boundary.

## Earlier findings, re-checked

| # | Earlier finding | Status | Check |
|---|---|---|---|
| 1 | Lib or `git_harden` failure read as "ref absent" | **Fixed** | `scripts/d6.sh:52` tries `harden` alone before the loop. P2 below: all four failure shapes now name the lib, never the branch. T36 has both cases the report asked for (`return 1`, `GIT_CONFIG_COUNT=010`), and `d6_is` asserts an empty stderr for the first. |
| 2 | No test runs d6.sh from `D6_OPT/scripts/` | **Fixed**, with a side effect (finding 1 below) | `d6_copy` places the copy at `$U/scripts/d6.sh`, so every stand-in case runs from the real position, and T37 takes `$O/scripts/d6.sh` when the image has one. That branch waits on the release: this image has no d6.sh, so T37 ran the copy here. |
| 3 | Three readers of the default-branch rule | **Open, Consider** (as agreed) | P2's last case reproduces it: `--state` refuses `main` with `origin/HEAD` at `trunk`, and nothing has changed. Bounded as before by `--state` opening every iteration. Not refiled. |
| 4 | `git_harden`'s comment lists two callers | **Comment fixed** | `scripts/lib/dev-cycle-read.sh:310-312` names d6.sh. The whole-lib dependency stays, as recommended. |

The fix also needed no new concept: `harden` is one line shared by the pre-check and `g`, so there is one definition of what d6.sh loads. The lib is now sourced three times a call, which the rubric's C6 already weighed and left.

## Probes

All ran under `timeout` at 48498ba6 in `/tmp/claude-1000/-workspace/47403b7b-5fcb-4e13-8807-c539081df064/scratchpad/2026-11-05-d6-block-into-image/arch3/` (`bats.log`, `probe.log`). No process remains.

| Id | What | Result |
|---|---|---|
| P1 | `bats -f 'd6\|GATE_CODE\|git_harden' test/scripts/build-loop-orchestrator.bats` | 15 of 15 ok |
| P2 | `git archive 48498ba6` of the scripts into a stand-in, d6.sh run from `$U/scripts/` | pass path ok; `GIT_CONFIG_COUNT=010`, a lib ending `return 1`, an unset variable at the lib's top level and a lib with no `git_harden` each give exit 2 and the `did not load` line; both names and a non-repository give their own refusals; `questions.sh` refuses the same way |
| P3 | `shellcheck scripts/d6.sh` | clean |
| P4 | `d6_copy` lifted from the bats file, against a target `scripts/` that is writable and already holds a d6.sh | see finding 1 |
| P5 | The same fixture with `scripts/` at 0555, as uid 1000 | target untouched; the copy goes to the temp path |
| P6 | `unshare -r`, to run P4 as uid 0 | refused here (`Operation not permitted`), so no run as root was observed |

## Findings

#### 1. `d6_copy` chooses where to write by testing writability, and T37 hands it the real image path

**Severity:** Minor
**Location:** `test/scripts/build-loop-orchestrator.bats:252-256`, `:396`
**Move:** 7 (coupling surface), 1 (dependency direction)
**Confidence:** Medium (the mechanism is shown by P4 and P5; a run as root was not possible here)
**Legibility-target:** for-author

**Evidence:**

```bash
# test/scripts/build-loop-orchestrator.bats:253-255
    # In its real place beside the scripts, where the stand-in can hold it.
    D6="$BATS_TEST_TMPDIR/d6.bash"; [[ ! -w "$1/scripts" ]] || D6="$1/scripts/d6.sh"
    cp "$REPO_ROOT/scripts/d6.sh" "$D6"
# :396
    d6_copy "$O"; [[ ! -f "$O/scripts/d6.sh" ]] || D6="$O/scripts/d6.sh"; d6 build-loop.sh --help
```

P4 output, with the target already holding a file whose first line is `# the image copy`:

```
d6_copy rc=0 D6=image/scripts/d6.sh
line 1 of the target now: #!/bin/bash
```

The fixture now tells "a stand-in I own" from "the image" by `-w`, which is a property of the caller's uid, not of the target. T37 passes it `/opt/claude-workflows` with a guard that only checks the directory is root-owned. Run as uid 1000 the test is safe, which is every normal run: `-w` is false and the copy goes to the temp path. Run as real root, `-w` is true, so `cp` writes the working tree's d6.sh over the image's gate file, or creates one in `/opt`, and `sed -i` edits it. Line 396 then runs that file, so T37 passes while pinning the working tree's bytes rather than the image's, which is the opposite of what the finding 2 fix added it for.

Before this branch's last round the helper only wrote to the temp path, so this write path is new. The suite does expect root runs (`test/scripts/build-loop-check.bats:103`, `:210`, `:305` branch on `id -u`), and the research doc counts "a run as root" among the things the ownership walk used to refuse. The reach is narrow: root can already write `/opt`, nothing in the repo runs bats as real root, and `scripts/confine-tests.sh`'s `unshare -r` path shows `/opt` as an unmapped owner, so T37 skips there. A second, smaller effect of the same line: a read-only stand-in drops silently to the temp path instead of failing, so a future case could lose the real position without any signal.

**Recommendation:** Key on the target, not on the uid: `[[ "$1" == /opt/claude-workflows ]] || D6="$1/scripts/d6.sh"`. That is one line, it never writes under `/opt`, and a stand-in that cannot hold the copy then fails at `cp` instead of falling back. Fine to take as a Consider if this branch is otherwise closed; the file is test-only and not gate code.

## What Looks Good

- **The finding 1 fix sits at the right boundary.** It separates "the lib failed" from "git answered" in one line, instead of decoding exit codes or moving the check into the lib. `g`'s status can now only be git's, unless the lib changes between two reads inside one call.
- **The comment at `scripts/d6.sh:50-51` and the header say what exit 1 covers.** A ref git cannot use counts as absent, as it did in the block. That is stated in the file and in pre-mortem 5, not implied.
- **The skill points at d6.sh's header for the refusal list** (`skills/dev-cycle/SKILL.md:46`) rather than restating it, so the new refusal needed no second edit (S3). Step 0.1 now separates exit 127 (an older image) from a missing-file refusal (a partial image), which matches how the two states arise.
- **GATE_CODE's restatements are complete.** `rg` over scripts, skills and tests finds the lib's one definition, step 0.1's PATHS line and the slug rule (both test-pinned), `build-loop.sh`'s header, and the floor test's row. No live instruction still says "D6 block" or `bash -s`; the remaining uses are history and the test that forbids them.
- **Release ordering and `D6_OPT` as a literal** are unchanged from the earlier pass, and they still hold.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | `d6_copy` picks its write target by `-w`; as root, T37 would overwrite the image's d6.sh and pin the wrong bytes | Minor | `test/scripts/build-loop-orchestrator.bats:252-256,396` | Medium |

## Overall Assessment

This change improves the structure and is ready on this lens. A pasted block is now a small file with a correct dependency on the lib, one hardening list and a release story resting on one commit. Finding 1 of the earlier pass, the only place the diff added a failure mode, is closed and tested in every shape I could produce. The one new item is in a test helper, needs a run as real root to matter, and has a one-line fix. Nothing here needs restructuring.

## Goal-Alignment Note
- Success criterion (restated verbatim): a report saved to docs/reviews/architecture-review-final-2026-11-05-d6-block-into-image.md, first line `Commit: 48498ba6`, each finding with Severity, Location, verbatim Evidence, Confidence and Legibility-target, ending with a Goal-Alignment Note (patterns/orchestrated-review.md).
- Answered: yes; findings 1, 2 and 4's comment confirmed fixed, 3 confirmed open and unchanged, one new Minor finding.
- Out of scope: the whole test suite and health check; a built image; a run as root (refused in this sandbox); hostile-author readings (S1).
- Escalate: the research doc's owner question (the brief's Goal says the block's checks keep running, the branch narrows them) is still not in `docs/working/questions.md` on this branch, which the brief leaves to the cycle, so it needs to reach the owner at landing.
- Decisions I made: Kept the carried default-branch finding in the re-check table rather than refiling it, since you stated it stays open; refiling would be defensible. Rated the new finding Minor rather than Informational because the fixture can overwrite a gate file, though only as real root.
