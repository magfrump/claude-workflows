# Research: remove the cycle's worktrees from a shell parked in its own call

Brief: `docs/working/briefs/2026-11-20-remove-worktrees-parked-shell.md` (at 10566f38).
Branch: fix/remove-worktrees-from-parked-shell. Dispatch 1. Policy: review.

Failure-pattern grep: FP-046, FP-068

(Terms: cwd, working directory, worktree remove, removed, shell, lag. No entry describes a
removed working directory refusing a later call. FP-046, "shell state not persistent across
bash calls", is the nearest mechanism; FP-068, "gate artifacts deleted with the worktree", the
nearest removal. Neither changes the design.)

Failure-pattern skip: the branch's fix commit applies a fix already diagnosed and recorded in `docs/working/research-2026-11-20-loop-start-dir-research.md` (herald F-008); its prediction is not yet observed, so it is a watch, not a confirmed pattern.

## Read (acceptance 1)

- The predecessor research in full: subagents' Bash calls run in the main shell's cwd, lagging
  by up to one command; 37 removals paired with 17 refusals; R1 (park and remove in one command)
  refuted at 23:29:50Z; R2 (park in its own call, then remove) picked, option 2 (defer each
  removal to the next iteration) its fallback.
- `skills/dev-cycle/SKILL.md`: the Rules' D13 bullet, the stop bullet's `--force` WT removal,
  step 0.3's WT removal, step 1's HC paragraph (its removal, its stop's `--force` removal, the
  leftover HC), step 1's `--free-worktrees`, step 7's GT line and step 10's "Then remove WT".
- `scripts/build-loop.sh` `loop_prompt()` (the `--start`/`--prompt` print) and
  `test/scripts/build-loop-dispatch.bats`, whose two pins quote "start every command with" but
  not "outside any checkout".
- `docs/constraints.md`: S3 (one source of truth), S6 (an observable), S8, H3.

## Context

- Invariants: no `build-loop.sh` behaviour but the prompt line; `--force` stays only on the
  stop paths (`test/scripts/build-loop-orchestrator.bats`' count of 2 is kept by writing
  "forced" in step 0.3's new text); step 1's pin "removed as step 0.3 removes WT once the check
  exits" kept.
- The orchestrator's directory `dev-cycle-orchestrator/` still exists (step 1 puts HC's log
  there), so D13 keeps it as where files go and drops only the false claim about the shell.

## Design notes (one line each; no choice had 3+ viable options)

- Removal form: R2, as picked by the predecessor research (Path A there); option 2 out of scope.
- Where it is stated: once, in step 0.3 (the brief's acceptance 2); the stop bullet, HC, GT and
  step 10 each point to "step 0.3's two calls" or "step 0.3's form" (S3).
- `--free-worktrees`: covered without a park, since it runs from WT and never from a worktree it
  frees, and nothing follows it in its command; said in step 0.3.
- D13 wording: says where the shell is (the last successful `cd`'s directory, WT after
  `cd WT && …`) and that loops' calls run there; drops "stays in", "not a git checkout" and the
  "not a git repository" safety the platform does not give.
- Prompt line: "Your shell runs where the orchestrator's does, a checkout that is not yours:
  start every command with "cd DIR &&"." (the predecessor's wording).
- Tests: the skill pins join `test/scripts/build-loop-orchestrator.bats`, home of the other
  SKILL.md pins; the prompt pins are the two existing ones in `build-loop-dispatch.bats`,
  updated, plus a negative for the old sentence.

## Records outside this brief's paths (wording they need)

- Decision-log row 72 and plan D13 (`docs/decisions/log.md`,
  `docs/working/plan-build-loop-handoff.md`): where they say the orchestrator's shell stays in a
  non-checkout temp directory so a misplaced command fails with "not a git repository", they
  should read: "the orchestrator's files live in its temp directory; its shell sits where the
  last successful `cd` took it, loops' calls run there, so every command names its checkout and
  worktrees are removed from WTB in a call of their own (2026-11-20 research)".

## Observable for the cycle's watch (S6)

From the predecessor research: in the next sessions' orchestrator transcripts, pair each
worktree removal made after a bare `cd WTB` call with the loops' refusals "no longer exists,
so this command was not run" within minutes of it. Negative if any appears: then option 2
(move each removal to the next iteration) replaces R2.

## Verification

- `bats test/scripts/build-loop-dispatch.bats test/scripts/build-loop-orchestrator.bats`: pass.
- `scripts/hermeticity-lint --root .`: pass.
- `scripts/health-check.sh` at 70cebc49: "All checks passed." (exit 0).
- Review: round 1 (code-fact-check and clarity) found four ambers, fixed in 70cebc49; round 2 clean.
