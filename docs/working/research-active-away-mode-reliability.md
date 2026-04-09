# Research: Active/Away Mode Reliability

## Scope
Investigate why /active and /away mode switching is unreliable and identify fixable causes.

## What exists

The Operating Modes section in CLAUDE.md (lines 62-87) defines two modes:
- `/active` (default) — pause before commits, flag uncertainty, wait for approval
- `/away` — commit and push autonomously, open draft PRs without asking

The section also defines shared guardrails (never force-push, stop for failing tests) and an autonomous commit format.

## Root causes identified

### 1. Slash command ambiguity [observed]
Claude Code has built-in slash commands (`/help`, `/clear`, `/compact`, `/cost`, etc.). When a user types `/active` or `/away` as a standalone message, Claude Code's command parser may intercept it as an unrecognized command rather than passing it to the model. The user likely sees an error or no response, and the model never receives the mode-switch signal.

**This is a platform limitation.** CLAUDE.md cannot register custom slash commands. The fix must work within Claude Code's existing input handling.

### 2. No explicit recognition protocol [observed]
The current CLAUDE.md says "The user sets the current mode by typing `/active` or `/away`" but doesn't instruct Claude to:
- Acknowledge the mode switch explicitly
- State what behavioral changes are now in effect
- Repeat the current mode in subsequent messages as confirmation

Without explicit acknowledgment, the user has no way to confirm the mode was received.

### 3. Vague behavioral contracts [observed]
The `/active` description is three short phrases: "Pause before commits. Flag uncertainty. Wait for approval on plan steps before implementing." This leaves ambiguity about:
- What counts as "uncertainty" worth flagging?
- Which specific tool calls require user approval in /active vs /away?
- Does /active affect file reads, file edits, running tests, or only git operations?

The `/away` description is slightly better but still lacks specificity about what "each completed step" means.

### 4. No mode persistence signal [inferred]
When context gets compressed during long sessions, the mode-switch message may be dropped. There's no instruction for Claude to maintain mode awareness or re-check when uncertain.

## Invariants
- The two-mode system (/active and /away) must be preserved — the user relies on this for async workflows
- The guardrails (never force-push, stop for failing tests, etc.) must remain unchanged
- The autonomous commit format must remain unchanged
- Other sections of CLAUDE.md must not be affected

## Prior art
The system prompt already supports "You are in /away mode" as a preamble to user messages (visible in the current session). This means the mode can be set at session start via the user's message, not just as a standalone command.

## Gotchas
- We cannot modify Claude Code's command parser — only CLAUDE.md content
- We cannot add hooks or settings.json changes per the file scope constraint
- The `/` prefix is the most natural UX but conflicts with Claude Code's command namespace
