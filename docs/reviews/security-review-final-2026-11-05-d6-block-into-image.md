Commit: 48498ba6

# Security Review — refactor/d6-block-into-image (final pass)

**Scope:** `git diff 5b20d4bd..48498ba6 -- . ':!docs/reviews'`, plus `scripts/lib/dev-cycle-read.sh` (`git_harden`, `scrub_reexec`), `scripts/build-loop.sh` (`state_gate`, `default_gate`, `state_start`, the mode dispatch) and `devcontainer-config/Dockerfile`'s payload lines
**Date:** 2026-11-05
**Based on:** `docs/reviews/code-fact-check-report-final-2026-11-05-d6-block-into-image.md` (at 1c5fd04f; the one commit after it changes only comments and prose in `scripts/` and `skills/`) and my earlier report `docs/reviews/security-review-2026-11-05-d6-block-into-image.md`. Threat model: H1 and S1 from the brief, also read with `git show main:docs/constraints.md`

**Result:** no new findings. The two changes since the last pass, `harden` tried alone and the refusal for a lib that does not load, fail closed on every case I ran. No HALT pattern matched. The accepted release-window finding is not re-filed: its facts have not changed.

## What changed since the earlier pass

| Earlier item | State at 48498ba6 |
|---|---|
| 1. Release window, `scripts/d6.sh` not in the old image's GATE_CODE | Accepted and disclosed (research Pre-mortem item 3). The remedy is in `docs/dev-cycle.md`, which this branch may not edit. Not re-filed |
| 2. Plan F39 credits the removed ownership check | Fixed. `plan-build-loop-handoff.md:167` now reads "the image's own ownership, not a runtime check, since 2026-11-05 (D6)", and T33 (`:408`) no longer says SKILL.md holds the block |
| 3. Planted state passes d6.sh (Informational, out of scope, constraints S1) | Stands, already reported once. Its sentence that a graft reaches `--main-log` was wrong: my probe gave identical `--main-log` output with and without a graft that hid the commit asked about, while plain `git rev-list --count main` fell to 1. Research lines 105 and 117 now say so |
| Open item: exit 126 for `dev-cycle.sh` check modes | Closed. `bash` on a directory exits 126 with empty stdout (probed), and the paths rule opens a file only after an `ok <path>` line, so nothing opens |

## Trust Boundary Map

```
B1 (moved):  [orchestrator's call line, ARGs from repo text] → [d6.sh exact match on SCRIPT, "$@" passed whole]  → [image script]
B2 (moved):  [checkout's .git: refs, config]                 → [hardened show-ref, exactly-one check]            → [decision to run the script]
B3 (moved):  [caller's environment]                          → [`exec env -u ...`, </dev/null]                   → [image script's process]
B4:          [loop's branch diff]                            → [image floor: GATE_CODE, Self-merge never]        → [main, then the next release]
B5 (removed):[filesystem under /opt]                         → [ownership walk, removed]                         → [image code]; now the Dockerfile's chown and chmod alone
B6 (new):    [image lib load; caller's GIT_CONFIG_COUNT]     → [`( harden )`, d6.sh:52]                          → [the show-ref loop's exit codes]
```

```
S1: ARG... on the call line        — request-time    — UNTRUSTED for exec sinks; reaches only argv ("$@")
S2: SCRIPT (first argument)        — request-time    — UNTRUSTED for path construction; exact match on three names
S3: refs and config in .git        — runtime-mutable — UNTRUSTED as logic (H1); input to the exactly-one decision only
S4: caller environment             — runtime-mutable — UNTRUSTED for the child (six variables scrubbed); UNTRUSTED for
                                                       d6.sh's git (git_harden's pairs follow the caller's);
                                                       PATH and exported functions are the stated same-uid residual
S5: D6_OPT                         — code-constant   — trusted (literal, assigned and never read from outside)
S6: /opt/claude-workflows payload  — deploy-time     — trusted for exec and source, root-owned at build
S7: brief's Paths: and branch diff — runtime-mutable — UNTRUSTED toward main; judged by the image's copy of the floor
```

The boundaries are the ones the block crossed, moved into a file. B6 is the only addition. It separates "the lib or the environment is bad" from "git says the ref is absent", so a harden failure cannot be read as a missing branch. The diff makes one trust assumption of note: the image lib is sourced before any check of the repository, which is sound because it is S6, a literal path, and its presence is checked first.

## Findings

No findings.

## Move 11: bypass candidates per guardrail

The earlier report's table still holds for the code that did not change (SCRIPT match, scrub, exactly-one shapes). These rows cover what is new, and the reads the earlier pass left open. All probes ran the shipped `scripts/d6.sh` with its one literal changed, from a stand-in image in scratch.

| Guardrail | Candidate | How tested | Outcome |
|---|---|---|---|
| `( harden )` (`d6.sh:52`) | syntax error at the lib's tail | executed | exit 2, the "did not load" line, nothing ran |
| `( harden )` | lib that defines no `git_harden` | executed | exit 2, same line |
| `( harden )` | lib unreadable (mode 000) | executed | exit 2, same line, nothing ran |
| `( harden )` | `GIT_CONFIG_COUNT=010` | executed, and bats | exit 2, same line; `git_harden`'s `exit 1` stays in the subshell |
| `( harden )` | lib that `exit 0`s at load, so `harden` "passes" and git never runs | executed | exit 2: `g` returns 0 for both names, so `have` holds both and exactly-one refuses. Closed, with the wrong reason named; the real lib has no such line, and it would be image code |
| `( harden )` | lib that prints on load, against the first-line contract | executed | the stand-in's noise came before the script's output. The real lib printed nothing at load (base probe's only output was the script's) |
| show-ref's exit 1 read as absent | `git` not on PATH | executed | exit 127 is above 1: exit 2, `refs/heads/main could not be read` |
| show-ref's exit 1 read as absent | `GIT_CONFIG_COUNT=1` with no key | executed | git exits 128: same refusal, cause on stderr |
| show-ref's exit 1 read as absent | `harden` failing inside the loop after passing alone | read | needs the lib or environment to change between two calls in one process; the image is read-only. Were it to happen, that name counts as absent: no second name means a refusal, and only a failure for `master` alone would pass, leaving `main` the sole name |
| Pairs not leaking to the child | `harden`'s exports | bats (T26 case) | `GIT_CONFIG_COUNT` unset in the script |
| Lib names shadowing d6.sh's | a lib `g`, `no`, `harden`, `git`, or `s`, `x`, `f`, `n`, `rc`, `have` | grep of the lib's column-0 definitions | none, and each load is in a subshell, so nothing could reach d6.sh's own shell |
| Pins against the caller | `GIT_CONFIG_PARAMETERS` (the old block's `-c` came after it, `git_harden`'s pairs come before it) | executed, read | the caller's pair now outranks a pin here, as the lib's header states. It reaches only `show-ref`, which runs no hook, filter or fsmonitor, and the child hardens itself. No effect |
| Dropped symbolic and non-commit checks | a mode that writes without `default_gate` | read: the dispatch at `build-loop.sh:2315-2370` | `state`, `main-log`, `cycle-diff`, `land-cycle`, `check`, `merge`, `start`, `prompt` all call `state_start` or `gate_start`, and `state_start` runs `default_gate`. Only `marker`, `status` and `settings` skip it, and they are the read modes the header names. `--check-constraints` is handled at `:680`, before any gate; the script's header says it reads no repo |
| Refusal read as a pass | stderr ahead of `refuse d6:` in the Bash tool's merged output | read | git's or the lib's line can be the first line shown, so "first line" is not literally `refuse d6:` there. The header says so, the status is 2, and no `ok` or `merged` line follows, so it still reads as a stop |
| GATE_CODE | `scripts/d6.sh`, any case | bats (the floor row in `build-loop-check.bats`) | refused as gate code at HEAD |

**Untested bypass candidates:** none. The nearest gap is not a candidate input but a hop: the real image copy of d6.sh does not exist until the release (`/opt/claude-workflows/scripts/` has no `d6.sh`), so nothing ran from a root-owned path.

## Endorsement Claims

- **Claim:** at 48498ba6, a lib that fails to load or a `git_harden` that refuses gave exit 2 with the named refusal and ran no script, in each failing shape probed.
  **Location:** `scripts/d6.sh:37,52`
  **Evidence:** executed
  **Verified:** four shapes in the Move 11 table against a stand-in image whose `questions.sh` prints `RAN`; bats cases 1 to 15 of the `d6.sh|GATE_CODE|git_harden` filter of `build-loop-orchestrator.bats`, all ok.
  **Not verified:** the same run from the real `/opt` copy, which does not exist until the release.
  **route: code-fact-check**

- **Claim:** a planted `info/grafts` left `--main-log`'s output unchanged for a commit it hides.
  **Location:** `docs/working/research-2026-11-05-d6-block-into-image.md:105`
  **Evidence:** executed
  **Verified:** three commits, a graft cutting the tip from its parent; the same two output lines and exit status with and without the graft.
  **Not verified:** `--main-log` on a merge history, where `log_class` reads more of the tree.

- **Claim:** every arm of `build-loop.sh`'s mode `case` outside `marker`, `status` and `settings` calls `state_start` or `gate_start` before its work, as d6.sh's header says of the gated modes.
  **Location:** `scripts/build-loop.sh:1292-1300`, `:2315-2370`; `scripts/d6.sh:27-29`
  **Evidence:** read-static
  **Verified:** each arm of the mode `case` and the bodies of `state_start` and `gate_start`; the bats case pinning two refused shapes through `--state`. `--check-constraints` has no arm: it is handled at `:680`.
  **Not verified:** what the `:680` branch reads past its first lines; that it reads no repo is the script's header at `:540`.

## Primitive sweep

Primitive: process exec / source

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/d6.sh:37` `source` | S5 | literal path, presence and regular-file check first | cleared |
| `scripts/d6.sh:38` `git "$@"` | code constants (`show-ref --verify -q refs/heads/$n`, `n` in main, master) | no outside text; `harden` first | cleared |
| `scripts/d6.sh:52` `( harden )` | S5, S4 | subshell; only its status is read | cleared |
| `scripts/d6.sh:60` `exec env ... bash "$D6_OPT/scripts/$s" "$@"` | S2, S1, S5 | exact match on `$s`; `"$@"` stays argv | cleared |
| `skills/dev-cycle/SKILL.md:39` call line | S1, S2 | same position as the old `bash -s --` line | cleared, unchanged exposure |
| bats `bash -c '...' _ "$D6"` and the `read -r -a w` call | test fixtures | static shell body; values as `$1` | cleared, test-only |

No `eval`, `sh -c "$x"` or re-parsed string in the diff's shipped code.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| — | No findings | — | — | — | — |

## Overall Assessment

The posture is unchanged from the last pass, and the new refusal improves it: a broken lib or a refused environment now names itself instead of reading as an absent branch, and the one state that could make `harden` pass without running (a lib that exits 0) still refuses. One open item remains, the accepted release window, whose remedy goes to the cycle through the ready marker. Safe to merge on the code paths read: the executed claims name their `Not verified` hop, and the one read-static claim names its hop too.

## Goal-Alignment Note
- Success criterion (restated verbatim): a report saved to docs/reviews/security-review-final-2026-11-05-d6-block-into-image.md, first line `Commit: 48498ba6`, each finding with Severity, Location, verbatim Evidence, Confidence and Legibility-target, ending with a Goal-Alignment Note (patterns/orchestrated-review.md). Edit nothing else; do not commit.
- Answered: yes; no new findings, so the per-finding fields have nothing to attach to.
- Out of scope: hostile-author mechanisms (S1, reported once in the earlier pass); the release window (accepted, facts unchanged); the full bats suite (16 targeted cases run, all ok).
- Escalate: nothing new. The release-window remedy stays with the cycle through the ready marker, as the brief says.
- Decisions I made: did not re-file the graft and writable-`/opt` note, since S1's rule is to report it once; the alternative was repeating it as Informational. Treated the absent real image copy as a `Not verified` hop, not an untested bypass candidate as the earlier report listed it, because it is no input a caller can send.
