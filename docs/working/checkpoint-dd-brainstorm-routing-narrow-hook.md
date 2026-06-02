# Checkpoint: dd-brainstorm-routing-narrow-hook
Date: 2026-06-02
Branch: feat/r2-dd-brainstorm-routing-narrow-hook
Research: docs/working/research-dd-brainstorm-routing-narrow-hook.md
Plan: docs/working/plan-dd-brainstorm-routing-narrow-hook.md

## Project state
- **Branch purpose**: Escalate the CLAUDE.md "DD supersedes brainstorming" precedence note from skimmable prose to a harness-executed UserPromptSubmit hook.
- **Position in larger initiative**: Round-2 follow-up to the r1 DD-supersedes-brainstorming routing change.
- **Blocked on**: nothing.

## Key findings
- Existing hooks (`hooks/log-usage.sh`) are the prior-art contract: stdin JSON via jq, passthrough, always `exit 0`. Mirror it.
- `/home/magfrump/.claude/settings.json` is a real file; its `hooks` object has PreToolUse/PostToolUse but **no UserPromptSubmit**. Command convention: `bash $HOME/.claude/hooks/<script>.sh`.
- Seed phrasings live in `workflows/divergent-design.md` line 16. Narrow the allowlist to four explicit comparison phrasings; exclude broad keywords ("architecture", "tradeoff") that would over-fire (C9 mitigation).
- UserPromptSubmit blocks only on exit 2; stdout is injected as context. Always exit 0.
- Deployed `$HOME/.claude/hooks/<script>` are per-script symlinks to the main checkout — creating the new one is an out-of-scope deploy step (documented, not performed).

## Plan
1. Create `hooks/dd-routing-reminder.sh` (passthrough, narrow allowlist, one-line stdout, exit 0).
2. Add additive `UserPromptSubmit` key to settings.json.
3. Verify via stdin payloads (match/no-match/malformed) + JSON validity.
4. Document the symlink deploy step in a scope-exception doc.

## Invariants
- Never block prompt submission (exit 0 always; no block decision).
- Additive only — preserve existing PreToolUse/PostToolUse arrays.
- Narrow allowlist — no firing on ordinary creative prompts.

## File map
- `hooks/dd-routing-reminder.sh` — new hook script (steps 1, 3)
- `/home/magfrump/.claude/settings.json` — add UserPromptSubmit key (steps 2, 3)
- `docs/working/scope-exception-dd-brainstorm-routing-narrow-hook.md` — symlink deploy note (step 4)

## Open questions
- Regex breadth is a judgment call; under-firing chosen as the safe direction. Widen later if usage shows misses.
