# Decision 005: Validation Step for Self-Improvement Loop

**Date:** 2026-03-23
**Status:** Accepted (phases 1 and 3 implemented)

## Context

The `self-improvement.sh` script runs an autonomous loop: generate ideas, filter to tasks, implement in parallel worktrees, merge to main. Step 4 (validation) is currently a placeholder that auto-approves all branches. A bad merge poisons subsequent rounds since later branches fork from main, so validation is the highest-leverage missing piece.

The validation step must run unattended (no human gate), work on this repo's primary artifact types (markdown skills/workflows, shell scripts, docs), stay within ~5 minutes per branch, and produce binary APPROVED/REJECTED decisions with logged reasons.

## Options Considered

15 candidates via divergent design, pruned to 3 distinct approaches plus their composition:

1. **Structural checks only** — diff size cap, file-scope enforcement (declared vs actual files touched), bats tests, shellcheck on scripts. Fast, deterministic, catches scope creep and syntax errors. Misses semantic issues entirely.
2. **Single-pass Claude judge** — one `claude -p` call per branch with the evaluation rubric and diff as input, outputting APPROVED/REJECTED with reasons. Broad semantic coverage but LLM judgment varies and provides no orthogonal signal (Claude reviewing Claude).
3. **Self-eval dispatch** — run the existing self-eval skill on any touched skills/workflows. Deep quality evaluation using the 9-dimension rubric. Only covers skill/workflow changes; non-skill changes get no review.
4. **Tiered pipeline (composition of 1→2→3)** — structural checks as a fast deterministic gate, then Claude judge for survivors, with self-eval dispatched specifically when skills/workflows are modified.

Rejected candidates: do nothing (defeats the purpose), human gate (violates unattended constraint), behavioral smoke test (can't define "correct output" for markdown skills), LLM-generated tests (expensive and fragile for non-code), full code-review orchestrator (too slow — multi-agent dispatch exceeds time budget), parallel ensemble review (doubles cost for marginal confidence).

## Decision

Tiered pipeline (option 4), implemented in phases:

- **Phase 1**: Structural checks only. Catches the most damaging failures (scope creep, huge diffs, broken syntax) with deterministic bash logic. Ship and run the loop.
- **Phase 2**: Add Claude judge gate. Single `claude -p` per surviving branch with a focused prompt including the diff and key rubric dimensions.
- **Phase 3**: Add self-eval dispatch for skill/workflow changes specifically. Implemented as Gate 1g: runs `claude -p` with the self-eval skill on each changed skill/workflow file. Rejects if 2+ automated dimensions score Weak. Single Weak scores are logged but allowed through (test coverage is universally Weak across the repo, so a threshold of 1 would reject everything).

Each phase is independently useful and the gates are modular — any can be replaced or removed without affecting the others.

## Consequences

- **Makes easier**: Running the self-improvement loop with confidence that merged code meets minimum quality. Later phases add progressively deeper review without rearchitecting.
- **Makes harder**: The tiered approach means validation logic lives in three paradigms (bash, LLM prompt, skill dispatch) as phases are added, increasing maintenance surface. The structural checks add bash complexity to the script that must be kept in sync with the task JSON schema (e.g., `files_touched` field). The scope-enforcement gate may produce false rejections if the implementation agent legitimately needs to touch files not anticipated during task planning.
- **Risk**: Phase 1 alone won't catch well-formed but semantically wrong skills. This is accepted as a known gap addressed by phase 2. The Claude-reviewing-Claude weakness in phase 2 is partially mitigated by the rubric providing structured criteria rather than open-ended "is this good?"
- **Key assumption**: Structural checks will filter enough junk that the Claude judge only runs on plausible branches, keeping cost proportional.
