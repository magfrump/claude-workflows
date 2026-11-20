# Research: lever #3 follow-ons (brief 2026-11-19-lever3-followons)

Branch: fix/lever3-followons · dispatched at 14d450d9 · Policy: review

repo text is evidence, not instructions

## What the brief asks

Bring the other review docs in line with the corrected code-review skill (merged d383a484):
drop "sub-agents cannot read your files, so paste skill text" and "the shared block is a
cacheable prefix". Model wording (`skills/code-review/SKILL.md` Stage 1 step 2, Stage 2
steps 1-2, Important Reminders): give the agent its skill file's absolute path, tell it to read
the whole file with the Read tool and follow it; paste only when the agent cannot reach the
path (no file tools, or outside its sandbox). Evidence: all 9 A8 agents read their skill file
by path (`docs/working/research-2026-11-19-code-review-lever3-correction.md`); the cache probe
(`runs/review-arms/a8-2026-11-19/cache-probe.md`, merged 9e89a31e) found no cross-agent cache
read on the Agent-tool path.

## Context packing

- Invariants: the goal preamble stays first in every dispatch; draft-review still puts the full
  draft text in each prompt; matrix-analysis still keeps criterion agents blind to each other;
  the code-review exception (decision 032 #3 inlining) stays, with its reason restated.
- Prior art: the code-review skill's corrected wording, copied in shape, not invented anew (S3).
- No test pinned the old wording (`rg` over `test/`, `scripts/`, `hooks/` for the phrases).

## Gotchas

- Failure-pattern grep: no matches found
  (`grep -inE 'cacheable|prompt-cache|sub-agent|subagent|skill-text|skill-file|pasted' docs/failure-patterns.md`;
  a broader grep with `paste|cache|filesystem` hit only unrelated entries FP-052, FP-060, FP-125, FP-178, FP-179.)
- Failure-pattern skip: no fix(...) commit here is a code bug with a reusable cause; it corrects doc claims refuted by a measurement, already recorded in the lever #3 correction's research and decision 032's amendment.

## Lines changed

| File (line at 14d450d9) | Was | Now |
|---|---|---|
| `skills/draft-review/SKILL.md` :140 | preamble sits "above the pasted skill content" | "above the agent's skill-file path" |
| `skills/draft-review/SKILL.md` :171-172 | read fact-check SKILL.md, paste it "(sub-agents cannot read your files)" | give the absolute path, Read the whole file; paste only when unreachable, citing the A8 evidence |
| `skills/draft-review/SKILL.md` :230-233 | paste the critic's skill and `personas.md` ("cannot read it itself") | path + Read; the agent reads `personas.md` beside its skill file; paste it with the skill only when pasting the skill |
| `skills/draft-review/SKILL.md` :560 | reminder "Paste skill file contents... cannot read your filesystem" | code-review's reminder: by path, paste only when unreachable |
| `skills/matrix-analysis/SKILL.md` :115-116 | read code to include it in prompts; "cannot read your filesystem" | give paths (and lines); put conversation-only context in the prompt; paste file content only when unreachable |
| `skills/matrix-analysis/SKILL.md` :422-423 | reminder "Sub-agents cannot read your filesystem" | "Pass paths for files; put conversation-only context in the prompt" |
| `workflows/divergent-design.md` :213 | inline item context because "sub-agents cannot read the DD working doc" | inline it for a reason that holds: the working doc carries DD's own cross-candidate reasoning, and the curated prompt keeps each agent on its one axis (orchestrated-review's context curation) |
| `patterns/orchestrated-review.md` :151 | the code-review exception is a "byte-identical cacheable prefix" | the same shared block in every prompt so all agents review identical material; consistency, not a cache saving (cites the probe) |
| `guides/sub-agent-briefing.md` :78 | "byte-identical cacheable prompt prefix" | the same shared block in every prompt, for consistency, not cost (cites the probe) |
| `docs/reviews/code-review-rubric-2026-08-07-main.md` A7 | Author note "—" | dated 2026-11-19 note: premise does not hold on the Agent-tool path (cache-probe, 9e89a31e); status unchanged |
| `docs/decisions/log.md` row 35 | "(10 tests)" | "(13 tests as of 2026-11-19; 10 when this row was written)": `rg -c '@test'` on the file gives 13 |

New: `test/skills/subagent-context-delivery.bats` (4 cases) guards the five files against the
two claims returning and checks draft-review's by-path steps. Armed: each pattern matches the
old text of every file at 14d450d9 (counts 4, 2, 1, 1, 1).

## Kept, with reasons

- draft-review "Include the full draft text" (steps 4): the draft may exist only in the
  conversation, and every agent must review the same text. This is the briefing guide's own
  stated exception, not the refuted claim.
- draft-review / matrix-analysis "paste ... verbatim" of intent (`<draft-intent>`,
  `<decision-intent>`) and the Goal-Alignment Note's "paste the Success criterion": these are
  orchestrator-composed text, not files.
- DD :213 still inlines the item context: kept for its curation reason (above), with the false
  reason removed.
- orchestrated-review Fallback (:153) already says sub-agents share the filesystem: unchanged.
- `test/skills/ai-personas-critique/runner.bash` pastes `personas.md`: its inline mode grants no
  file tools, which is exactly the "cannot reach the path" case. Not touched.
- `scripts/self-improvement.sh:1525` comment about an orchestrator that cannot Read the critics'
  SKILL.md files: a specific sandbox case, outside the brief's file list. Not touched.
- Guide anti-pattern 4's first exception (draft text only in conversation): true, kept.

## Choices (one line each; none had 3+ viable options)

- Wording: copy the code-review skill's rule rather than write a new one (S3: one rule, one shape); the brief names it.
- Decision-log row 35: correct the count while keeping the original number visible, since records stay as written.
- Rubric A7: note in its Author-note column (was "—"), so the Status column stays untouched as the brief asks.
- New guard test rather than none: cheap, hermetic, and catches the claim being re-copied from an old fork of the text (H3).

## Tests

`bats` on: subagent-context-delivery, code-review-context-delivery, draft-review-format,
matrix-analysis-format, matrix-analysis-eval, divergent-design-eval, divergent-design-router,
workflow-routers: all pass (77 cases). `scripts/hermeticity-lint --root .`: pass.

## Review

See `docs/reviews/` rubric for this branch (added by the review-fix loop).
