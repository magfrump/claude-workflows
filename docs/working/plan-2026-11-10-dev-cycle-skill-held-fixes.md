# Plan: three small dev-cycle skill fixes that waited on the release

**Goal**: as the research doc.
**Project state**: as the research doc.
**Task status**: in-progress (review-fix loop: iteration 2 fixes applied, last confirming pass next)
Research: docs/working/research-2026-11-10-dev-cycle-skill-held-fixes.md

## Approach

Prose only, in `skills/dev-cycle/SKILL.md`: the identity check becomes the gate's own `git var` question (research, item 1), the release paste becomes the `rev-parse`-only test of main's tip and the PATHS entries (research, item 2, candidate 3), and step 8 with the record's `8.` line gain the free-slot clause (item 3). Each command the skill now names is run by a hermetic test that takes its text from the skill, so a later rewrite that breaks it fails a test.

## Steps

1. Tests, red first, in `test/scripts/build-loop-orchestrator.bats`: the identity cases, the paste's cases with planted git state, and the prose pins for items 2 and 3. About 60 lines.
2. Item 1: the Rules bullet "The orchestrator's git". About 4 lines changed.
3. Item 2: step 0.1's `image-off-main` option text, the paste line, and the sentences after it (what it refuses, the rerun after a step 7 merge, why `rev-parse`). About 12 lines changed.
4. Item 3: step 8's sentence and the record template's `8.` line. About 4 lines changed.
5. `docs/failure-patterns.md`: FP-177 and FP-178. Added during implementation: one registry line in `scripts/lib/migrations.sh` for the changed record template (the convention check demands it), and decision log row 86.
6. pr-prep's step 0 advisory and the review-fix loop; then the brief's Status line and the marker.

Implementation order: 1 → [2, 3, 4] → 5 → 6.

Size estimate: about 20 changed lines in the skill (913 lines, already past 500; it is one procedure read top to bottom and this change adds about 8 net) and about 60 in the test file (927 lines; the suite's other SKILL.md pins live there). Under the 400-line cap. Actual after review: about 20 net lines in the skill and about 125 in the test file; the count outside `docs/` is in the fix commits' `Size:` lines.

Estimated context cost: research ~110k, implementation ~30k, review ~40k.
Actual context cost (post-implementation): __

## Test specification

| Test case | Expected behavior | Level | Diagnostic expectation |
|---|---|---|---|
| Identity: neither source | both `git var` calls from the skill's text exit non-zero, "auto-detection is disabled" | integration | status and git's output |
| Identity: `EMAIL` only; author only | non-zero | integration | status and output |
| Identity: environment | exit 0, prints the environment's name and email for both roles | integration | the two lines |
| Identity: config | exit 0, prints the config's name and email | integration | the two lines |
| Paste: text | one line in the skill, one single-quoted word for `sh -c`; every `git` in it is `$(git rev-parse`; no `exit` or `exec`; the installer last, behind a count of every check | unit | the offending text |
| Paste: at M; at main's tip after a docs-only commit | the stub installer runs | integration | status, output, marker |
| Paste: a branch checked out; detached at M behind main | "release refused: this checkout is not at the tip of main", installer not run | integration | same |
| Paste: gate code changed after M, each path in turn | "release refused: PATH changed after M: run the dev cycle for a new paste", installer not run | integration | same |
| Paste: an M the clone lacks; a directory that is no repository; an A that is not there | a refusal for every check that could not be made, installer not run | integration | same |
| Paste: planted hooks and fsmonitor | nothing planted runs; the same state does run under `git status` and a checkout (the control). The pager is left to the text check, since git pages only to a terminal | integration | the marker file's lines |
| Paste: the installer changed after M | "release refused: devcontainer-config/install.sh changed after M…", installer not run | integration | status, output, marker |
| Paste: broken into lines (a break before each word; folded at 40 to 240 columns), typed into an interactive bash sitting in the checkout | the installer never runs from a refusing checkout | integration | the break or width that installed |
| Prose: item 2 | "a checkout to reach main's tip included", the rerun after a step 7 merge, the `image-off-main` option naming main's tip | unit | the missing string |
| Prose: item 3 | the template's `8.` line and step 8 both say "why each free slot stayed free" | unit | the missing string |

The `test-strategy` skill ran as a read-only subagent (its report came back as text; it wrote no file). Its gaps, and where each landed:

| Gap | What | Outcome |
|---|---|---|
| G1-G3 | identity: environment-only passes; a guessed identity stops; the committer call; a config name with no email | test 1. The `EMAIL` case now sets the names, so it fails if the flag goes (plain `git var` is shown to pass there) |
| G4, G16, G17 | old wordings stay gone; the prose that moves with the paste; the free-slot clause in both places | tests 1 and 3 |
| G5, G6, G8 | the paste at M and at main's tip; off the tip; failed reads | test 2 |
| G7 | each of the six PATHS entries refuses, so a loop that stops early shows | test 2, one case per entry |
| G9 | an empty path list passes | closed by the count: a short list leaves it under nine; the test pins the count against the list |
| G10 | `exit 1` must end only the `( … )` | gone with the subshell: the paste has no `exit`, and test 2 refuses one |
| G11 | bash, sh and zsh | test 2 runs each case under all three (zsh where installed) |
| G12 | no planted hook or fsmonitor runs | test 2, with a control showing the planted state is live |
| G13 | a pager needs a terminal, so a bats control would be vacuous | left to the text check: every git call is `$(git rev-parse` |
| G14 | a planted promisor remote runs its program when M is absent | confirmed by probe; out of scope under S1, recorded in the research doc's bypass table, no test |
| G15 | a mode-only change to a file entry passes | recorded as harmless in the bypass table, no test |

## Failure modes considered

| Failure mode | Guard |
|---|---|
| The paste fails open: a failed read on both sides compares equal and the installer runs | Test cases "M the clone lacks", "no repository", "gate file gone" and "gone on both sides" assert the refusal and the absent marker; both `x="$(…)" &&` forms are covered: without the loop's, the no-repository case counts seven path checks in silence and its expected refusals are missing |
| The installer runs after a refusal (shell precedence, or a copy broken into lines) | Every refusal case asserts the stub's marker is absent; the broken-line cases type the paste into an interactive shell in the checkout |
| A later edit swaps `rev-parse` for a command that runs a planted hook or pager | The text test allows only `$(git rev-parse`; the planted-state case runs it, with a control showing the planted state is live |
| The identity check passes with a made-up identity | The `EMAIL`-only and neither cases assert a non-zero exit under `user.useConfigOnly` |
| The paste's PATHS drift from `GATE_CODE` | The existing pin test holds the PATHS line; the new test builds the paste from that same line and checks each entry exists in this repo |

`/pre-mortem`: not triggered. No enforcement-file pattern in `hooks/live-verify-gate.sh` matches `skills/dev-cycle/SKILL.md` or the test file, the change is one revert and under 500 lines. The bypass families the brief asks for are listed in the research doc, each marked covered or not. `/architecture-review`: not triggered. The paths are a skill's prose and the test that pins it; no module boundary, public interface or data shape changes.

Risks: the skill's sentences are long and pinned by several tests, so the orchestrator suite runs after each edit. The orchestrator copies a paste of about 460 characters (about 700 written out) from the skill; a wrong copy refuses. The host's git version is not known from here (research, Gotchas).

Checkpoint: none written. Implementation runs in this session, and this plan is the whole context an implementer needs (a recorded deviation from the workflow's checkpoint step).

## Rollback

`git revert -m 1` of this branch's merge commit on main. It touches no schema, data, service or installed state by itself: the skill reaches sessions only through the next release paste (`install.sh`), which carries the revert the same way. An `image-lag` entry already written with the new paste stays valid text; after a revert the next iteration rewrites it with the old one.
