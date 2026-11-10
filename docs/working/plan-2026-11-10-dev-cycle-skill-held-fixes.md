# Plan: three small dev-cycle skill fixes that waited on the release

**Goal**: as the research doc.
**Project state**: as the research doc.
**Task status**: in-progress (plan written; tests next)
Research: docs/working/research-2026-11-10-dev-cycle-skill-held-fixes.md

## Approach

Prose only, in `skills/dev-cycle/SKILL.md`: the identity check becomes the gate's own `git var` question (research, item 1), the release paste becomes the `rev-parse`-only test of main's tip and the PATHS entries (research, item 2, candidate 3), and step 8 with the record's `8.` line gain the free-slot clause (item 3). Each command the skill now names is run by a hermetic test that takes its text from the skill, so a later rewrite that breaks it fails a test.

## Steps

1. Tests, red first, in `test/scripts/build-loop-orchestrator.bats`: the identity cases, the paste's cases with planted git state, and the prose pins for items 2 and 3. About 60 lines.
2. Item 1: the Rules bullet "The orchestrator's git". About 4 lines changed.
3. Item 2: step 0.1's `image-off-main` option text, the paste line, and the sentences after it (what it refuses, the rerun after a step 7 merge, why `rev-parse`). About 12 lines changed.
4. Item 3: step 8's sentence and the record template's `8.` line. About 4 lines changed.
5. `docs/failure-patterns.md`: FP-177 and FP-178.
6. pr-prep's step 0 advisory and the review-fix loop; then the brief's Status line and the marker.

Implementation order: 1 → [2, 3, 4] → 5 → 6.

Size estimate: about 20 changed lines in the skill (913 lines, already past 500; it is one procedure read top to bottom and this change adds about 8 net) and about 60 in the test file (927 lines; the suite's other SKILL.md pins live there). Under the 400-line cap.

Estimated context cost: research ~110k, implementation ~30k, review ~40k.
Actual context cost (post-implementation): __

## Test specification

| Test case | Expected behavior | Level | Diagnostic expectation |
|---|---|---|---|
| Identity: neither source | both `git var` calls from the skill's text exit non-zero, "auto-detection is disabled" | integration | status and git's output |
| Identity: `EMAIL` only; author only | non-zero | integration | status and output |
| Identity: environment | exit 0, prints the environment's name and email for both roles | integration | the two lines |
| Identity: config | exit 0, prints the config's name and email | integration | the two lines |
| Paste: text | one line in the skill; every `git` in it is `$(git rev-parse` | unit | the offending text |
| Paste: at M; at main's tip after a docs-only commit | the stub installer runs | integration | status, output, marker |
| Paste: a branch checked out; detached at M behind main | "release refused: this checkout is not at main's tip", installer not run | integration | same |
| Paste: gate code changed after M | "release refused: scripts/lib/ is not as at M…", installer not run | integration | same |
| Paste: an M the clone lacks; a directory that is no repository | "release refused", installer not run | integration | same |
| Paste: planted hooks, fsmonitor and pager, output on a terminal | nothing planted runs; the same state does run under `git status` and `git log` (the control) | integration | the marker file's lines |
| Prose: item 2 | "a checkout to reach main's tip included", the rerun after a step 7 merge, the `image-off-main` option naming main's tip | unit | the missing string |
| Prose: item 3 | the template's `8.` line and step 8 both say "why each free slot stayed free" | unit | the missing string |

The `test-strategy` skill's gap list is folded in below once its run returns.

## Failure modes considered

| Failure mode | Guard |
|---|---|
| The paste fails open: a failed read on both sides compares equal and the installer runs | Test cases "M the clone lacks", "no repository" and "gate file missing" assert the refusal and the absent marker |
| The installer runs after a refusal (shell precedence) | Every refusal case asserts the stub's marker is absent |
| A later edit swaps `rev-parse` for a command that runs a planted hook or pager | The text test allows only `$(git rev-parse`; the planted-state case runs it, with a control showing the planted state is live |
| The identity check passes with a made-up identity | The `EMAIL`-only and neither cases assert a non-zero exit under `user.useConfigOnly` |
| The paste's PATHS drift from `GATE_CODE` | The existing pin test holds the PATHS line; the new test builds the paste from that same line and checks each entry exists in this repo |

`/pre-mortem`: not triggered. No enforcement-file pattern in `hooks/live-verify-gate.sh` matches `skills/dev-cycle/SKILL.md` or the test file, the change is one revert and under 500 lines. The bypass families the brief asks for are listed in the research doc, each marked covered or not. `/architecture-review`: not triggered. The paths are a skill's prose and the test that pins it; no module boundary, public interface or data shape changes.

Risks: the skill's sentences are long and pinned by several tests, so the orchestrator suite runs after each edit. The orchestrator copies a paste of about 400 characters from the skill; a wrong copy refuses. The host's git version is not known from here (research, Gotchas).

Checkpoint: none written. Implementation runs in this session, and this plan is the whole context an implementer needs (a recorded deviation from the workflow's checkpoint step).

## Rollback

`git revert -m 1` of this branch's merge commit on main. It touches no schema, data, service or installed state by itself: the skill reaches sessions only through the next release paste (`install.sh`), which carries the revert the same way. An `image-lag` entry already written with the new paste stays valid text; after a revert the next iteration rewrites it with the old one.
