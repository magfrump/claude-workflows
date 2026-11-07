Commit: 4dd68cdc

# Security Review — refactor/d6-block-into-image

**Scope:** `git diff 5b20d4bd..HEAD -- . ':!docs/reviews'`, plus `scripts/lib/dev-cycle-read.sh` (`git_harden`, `scrub_reexec`, `floor`), `scripts/build-loop.sh` (`state_gate`, `caller_gate`, `default_gate`) and the installed image copy
**Date:** 2026-11-05
**Based on:** the iteration 1 fact-check summary in the review brief (its fixes are in HEAD); threat model from the brief's paste of `docs/constraints.md` on main (H1, S1), also read with `git show main:docs/constraints.md`

**Result:** no honest slip that the old block caught now reaches the gate unrefused. One Medium (a window the design already states, with a one-line way to close it) and one Low (a stale "covered" row). Neither is a merge blocker. No HALT pattern matched.

Answers to the brief's three questions:

- **Does any honest slip now reach the gate that the old block caught?** No. A replace ref is ignored by hardened git. A symbolic or tag default branch passes d6.sh but `--state` refuses it, and `--state` opens every iteration (probes 8 and 9). An honest graft is consistent history. The ownership walk's honest case, a misbuilt image, is pinned at the Dockerfile (`test/cc-isolated-functions.bats:778-785`).
- **Does sourcing the lib in d6.sh's subshell change anything for the exec'd script?** No. Nothing from `git_harden` reaches the child: its environment held no `GIT_*` variable, `HARDEN` or `CALLER_COUNT`, its cwd was unchanged, and pipefail was off (probe 1). The lib's top level runs no command substitution, trap, `set`, `shopt`, `cd` or `exec` (grep of column-0 statements).
- **Does the skill's call line let repo text choose anything?** No more than before. SCRIPT is matched exactly (`../build-loop.sh`, `'build-loop.sh '` and `*.sh` all exit 1), D6_OPT is assigned and never read, and an exported `D6_OPT` is overwritten. `ARG...` sat on the old `bash -s --` line in the same position, so what the orchestrator types there is unchanged.

## Trust Boundary Map

```
B1 (moved):  [orchestrator's call line, ARGs from repo text] → [d6.sh exact-match on SCRIPT, "$@" passed whole] → [image script]
B2 (moved):  [checkout's .git: refs, config]                 → [d6.sh hardened show-ref, exactly-one check]      → [decision to run the script]
B3 (moved):  [caller's environment]                          → [d6.sh `exec env -u ...`, </dev/null]             → [image script's process]
B4:          [loop's branch diff]                            → [image floor: GATE_CODE, Self-merge never]        → [main, then the next release]
B5 (removed): [filesystem under /opt]                        → [ownership walk, removed]                         → [image code]; now held by the Dockerfile's chown and chmod alone
```

```
S1: ARG... on the call line        — request-time    — UNTRUSTED for exec sinks; reaches only argv ("$@")
S2: SCRIPT (first argument)        — request-time    — UNTRUSTED for path construction; exact match on three names
S3: refs and config in .git        — runtime-mutable — UNTRUSTED as logic (H1); input to the exactly-one decision only
S4: caller environment             — runtime-mutable — UNTRUSTED for the child (six variables scrubbed);
                                                       PATH and exported functions are the stated same-uid residual
S5: D6_OPT                         — code-constant   — trusted (literal; caller's value overwritten, probe 2)
S6: /opt/claude-workflows payload  — deploy-time     — trusted, root-owned at build; 0555 dirs observed in this container
S7: brief's Paths: and branch diff — runtime-mutable — UNTRUSTED toward main; judged by the image's copy of the floor
```

Everything the block did crosses the same boundaries from a file instead of a paste. The one removed boundary is B5, and a check inside the image cannot vouch for the image it runs from, so that removal is sound. The only new exposure sits on B4, because the floor that guards the new file lives in an image built before it existed.

## Findings

#### 1. Between this merge and the next release, `scripts/d6.sh` is not gate code to the running gate

**Severity:** Medium
**Location:** `scripts/lib/dev-cycle-read.sh:1034` (HEAD) against `/opt/claude-workflows/scripts/lib/dev-cycle-read.sh:2017` (the image that decides); `docs/working/research-2026-11-05-d6-block-into-image.md`, Pre-mortem item 3
**Boundary:** B4
**Move:** 11 (enumerate bypasses for the guardrail)
**Confidence:** High on the mechanism (executed); Medium on it being hit, since it needs a brief that lists the file during the window
**Legibility-target:** for-author

**Evidence:**

```
GATE_CODE='^scripts/(build-loop|dev-cycle|questions)\.sh$|^scripts/lib/|^skills/dev-cycle/'     (image, line 2017)
GATE_CODE='^scripts/(build-loop|d6|dev-cycle|questions)\.sh$|^scripts/lib/|^skills/dev-cycle/'  (HEAD, line 1034)
```

Executed, each lib sourced and `scripts/d6.sh` matched against its GATE_CODE:

```
/opt/claude-workflows/scripts/lib/dev-cycle-read.sh NOT gate
scripts/lib/dev-cycle-read.sh gate
```

Pre-mortem item 3 states the same thing: "After the merge and before the release, the image's floor does not list `scripts/d6.sh`, so a self-merge naming it in `Paths:` would pass unflagged."

An honest follow-up loop whose brief lists `scripts/d6.sh` in `Paths:` lands by self-merge during the window, though the plan's D5 item 3 says gate code "falls to review under a `merge-gate-` entry". The change is not live until the release, so H1 holds: the old image never runs d6.sh. The release entry also lists every path outside `docs/` and flags self-merge subjects (the image's skill carries that step), so the pre-mortem's bound is accurate. What is lost is the review route for the file that decides which gate runs, leaving only the release, which the plan itself calls a skim (F58).

This is a disclosed residual and S1 accepts a stated one. It is filed at Medium because the floor rule does not allow a named, reachable mechanism lower, and because closing it costs one line.

**Recommendation:** add `scripts/d6.sh` to the `Self-merge never:` line of `docs/dev-cycle.md` in this merge. The old image reads that line from main's commit and `build-loop.sh:1241` enforces it, so it closes the window with no image change; drop it after the release. I did not run that line through `--settings`, and a malformed never line turns self-merge off, so check it there first. The alternative is to accept the window and run the release before dispatching any brief that touches `scripts/d6.sh`.

#### 2. Plan row F39 still says "covered" by the ownership check this branch removes

**Severity:** Low
**Location:** `docs/working/plan-build-loop-handoff.md:167`
**Boundary:** B5
**Move:** 2 (implicit assumption)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**

```
| F39 | D6 copy choice by file existence; the installed copy reached through the uid-writable `~/.claude/scripts` | covered | `/opt/...` by absolute path with an ownership check, in every repository (Q-140 [1]; the root-commit choice is gone) (T37) |
```

The branch updated F38, T36 and T37 and the amendment says the ownership walk went, but F39 still credits a control that no longer exists. HEAD's commit message says those rows "say what is true now", and F39 was missed. The failure-mode table is what a later audit reads to decide what is covered, so a stale "covered" could stop someone re-examining the image's ownership. No security property is violated today: the absolute path still carries F39's real defence, and the Dockerfile holds ownership. T33's row has the same drift ("SKILL.md holds the block once").

**Recommendation:** reword F39 to name the absolute path and the Dockerfile's chown and chmod (pinned in `test/cc-isolated-functions.bats`), with "amended 2026-11-05, D6"; update T33's row in the same edit.

#### 3. Planted state now passes d6.sh

**Severity:** Informational
**Location:** `scripts/d6.sh:48-54`
**Boundary:** B2, B5
**Move:** 5 (invert the access control model)
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `git rev-parse main > .git/info/grafts; d6 build-loop.sh --settings; [ "$status" -eq 0 ]` (`test/scripts/build-loop-orchestrator.bats`, the dropped-checks test).

A planted `info/grafts` reaches `--main-log`, and a uid able to write `/opt` would no longer be noticed. Both need a deliberately hostile author, and the research doc states the first residual. Out of scope (constraints S1).

## Move 11: bypass candidates per guardrail

| Guardrail | Candidate | How tested | Outcome |
|---|---|---|---|
| SCRIPT match (`d6.sh:38`) | `../build-loop.sh`, `'build-loop.sh '`, `*.sh` | executed | exit 1, nothing ran |
| SCRIPT match | empty, `x` | bats | exit 1 |
| Exactly one default | both names; neither; `main` renamed | bats | refused |
| Exactly one default | `master` a symref to `main` (the rename alias) | executed | refused |
| Exactly one default | `main` symbolic, or a tag | executed | d6.sh passes; `--state` refuses; the digest and `--settings` read on (dropped by design) |
| Exactly one default | junk file at `refs/heads/master` beside a good `main`; dangling `master` symref | executed, old block against d6.sh | both pass, same as the old block: `show-ref` exits 1, read as absent |
| Exactly one default | stray `GIT_DIR` at a repo holding `main` | executed, old block against d6.sh | both reach `--state`, whose `caller_gate` refuses |
| Exactly one default | `GIT_CONFIG_COUNT=010` | executed | refused, with the real cause on stderr and the stdout line naming the default branch |
| Image files (`d6.sh:43-47`) | missing; directory; dangling link; link to a file | bats | refused |
| Scrub (`d6.sh:55`) | all six variables; piped stdin | bats | unset, empty |
| Scrub | exported `D6_OPT`; `BASH_ENV` | executed | `D6_OPT` overwritten with the literal; `BASH_ENV` runs for d6.sh itself (the stated same-uid residual, as under `bash -s`) and not for the child |

The junk-ref row is not a finding: a broken name holds no commit to land on, and a repository with two good names was already refused. It does mean d6.sh's header, "a git read that fails", covers only exits above 1.

**Untested bypass candidates:** the real image copy of d6.sh, which does not exist yet (`ls` fails on `/opt/claude-workflows/scripts/d6.sh`). All probes ran the shipped file with its one literal changed. Exit 126 from a d6.sh that is not a file is not named in the Rules; a payload item cannot take that shape, and the Rules' "any other exit" covers `build-loop.sh`. This was not traced for `dev-cycle.sh` check modes.

## Endorsement Claims

- **Claim:** after d6.sh's git calls, the exec'd script starts with no `GIT_*` variable set by d6.sh and no d6.sh shell option.
  **Location:** `scripts/d6.sh:36,55`
  **Evidence:** executed
  **Verified:** probe 1, a stand-in image whose `questions.sh` printed its environment, cwd and pipefail state; also the T26 shim test in the diff.
  **Not verified:** the same run from the real `/opt` copy, which does not exist until the release.
  **route: code-fact-check**

- **Claim:** on a broken `master` ref, a dangling `master` symref and a stray `GIT_DIR`, d6.sh and the old block gave the same outcome.
  **Location:** `scripts/d6.sh:48-54`
  **Evidence:** executed
  **Verified:** the block extracted from `5b20d4bd:skills/dev-cycle/SKILL.md`, run unmodified against the real image, next to d6.sh against a HEAD stand-in, in one scratch repository.
  **Not verified:** other ref corruptions (a packed-refs error, a lock held by another process).
  **route: code-fact-check**

- **Claim:** `scripts/d6.sh` is gate code to HEAD's floor, and GATE_CODE's three restatements agree.
  **Location:** `scripts/lib/dev-cycle-read.sh:1034`, `skills/dev-cycle/SKILL.md:617`
  **Evidence:** executed
  **Verified:** the regex probe in finding 1; `git grep` shows the same regex in the lib, the skill and the test, and no other copy.
  **Not verified:** a full `--merge` refusal through the floor; the branch's `build-loop-check.bats` row covers it and I did not run it.

## Primitive sweep

Primitive: process exec / source

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/d6.sh:36` `source` | S5 | literal path, presence checked first | cleared |
| `scripts/d6.sh:36` `git "$@"` | code constants (`show-ref --verify -q refs/heads/$n`, `n` in main, master) | no outside text | cleared |
| `scripts/d6.sh:55` `exec env ... bash "$D6_OPT/scripts/$s" "$@"` | S2, S1, S5 | exact match on `$s`; `"$@"` stays argv | cleared |
| `skills/dev-cycle/SKILL.md:39` call line | S1, S2 | same position as the old `bash -s --` line | cleared, unchanged exposure |
| bats `bash -c '...' _ "$D6"` and the `read -r -a w` call | test fixtures | static shell body; values as `$1` | cleared, test-only |

No `eval`, `sh -c "$x"` or re-parsed string in the diff's shipped code. `scrub_reexec` re-runs the script with `"$@"` and is unchanged.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | `scripts/d6.sh` is self-mergeable until the release | Medium | B4 | `scripts/lib/dev-cycle-read.sh:1034` vs the image's `:2017` | High (mechanism) |
| 2 | Plan F39 credits the removed ownership check | Low | B5 | `docs/working/plan-build-loop-handoff.md:167` | High |
| 3 | Planted grafts or a writable `/opt` pass d6.sh, out of scope (constraints S1) | Informational | B2, B5 | `scripts/d6.sh:48-54` | High |

## Overall Assessment

The move holds up. The gate still runs from a literal image path, the narrowed checks are the ones with no in-scope threat, and nothing from the subshell reaches the script. Both findings fix in place with a line each, and neither points to an architectural problem. The most useful single action is the `Self-merge never:` line, or an explicit decision to accept the window. Every Endorsement Claim is executed with its `Not verified` hop named, so this is safe to merge on the code paths read, subject to the owner's call on finding 1.

## Goal-Alignment Note
- Success criterion (restated verbatim): a report saved to docs/reviews/security-review-2026-11-05-d6-block-into-image.md, first line `Commit: <HEAD short sha>`, each finding carrying Severity, Location, verbatim Evidence, Confidence and Legibility-target, ending with a Goal-Alignment Note (patterns/orchestrated-review.md). Edit nothing else; do not commit.
- Answered: yes; the brief's three questions are answered at the top.
- Out of scope: hostile-author mechanisms (finding 3, S1); non-security test quality; the bats suite was not run, only targeted probes.
- Escalate: finding 1's choice (add the never line or accept the window) is the owner's or the orchestrator's.
- Decisions I made: rated finding 1 Medium under the floor rule, though the design discloses it; the alternative was Informational as a stated S1 residual. Kept the junk-ref result in the bypass table, not as a finding, since the old block behaves the same.
