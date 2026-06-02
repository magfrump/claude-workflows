#!/usr/bin/env bash
# UserPromptSubmit hook: divergent-design (DD) routing reminder.
#
# Fires ONLY on explicit comparison/decision phrasings (a tight allowlist — NOT
# every creative prompt) and injects a single one-line, non-blocking reminder
# suggesting the divergent-design workflow over open-ended brainstorming. This
# escalates the CLAUDE.md precedence note ("DD supersedes brainstorming for
# decisions with 3+ tradeoff-bearing options") from skimmable prose to a
# harness-executed interception.
#
# Mandatory mitigations (C9):
#   - Narrow allowlist: matches only the four seeded comparison phrasings,
#     never broad single keywords ("architecture", "tradeoff") that would fire
#     on ordinary creative prompts.
#   - Non-blocking: always exits 0 and never emits a block decision, so prompt
#     submission is never interrupted.
#   - Additive: a standalone script wired as an *additional* UserPromptSubmit
#     hook in settings.json; it does not replace existing hooks.
#
# Input:  JSON on stdin (UserPromptSubmit payload; .prompt holds the text).
# Output: at most one reminder line on stdout (added to context). Exit 0 always.

# Deliberately do NOT use `set -e`: any internal failure must fall through to a
# clean exit 0 with no output rather than abort and surface a prompt error.
INPUT=$(cat)

# Extract the submitted prompt. Prefer jq (the parser sibling hooks use); if jq
# is unavailable or the payload is malformed, stay silent rather than block.
if command -v jq >/dev/null 2>&1; then
  PROMPT=$(printf '%s' "$INPUT" | jq -r '.prompt // ""' 2>/dev/null)
else
  PROMPT=""
fi

[[ -z "$PROMPT" ]] && exit 0

# Tight allowlist of explicit comparison phrasings, seeded from the user's own
# DD trigger phrasings (workflows/divergent-design.md). Each alternative is
# deliberately specific so ordinary creative prompts do not match. The broad
# single keywords from that seed list (e.g. "architecture", "tradeoff",
# "design choice") are intentionally EXCLUDED — they would over-fire. Matched
# case-insensitively (grep -i):
#   1. "X vs Y" / "X versus Y"
#   2. "which approach/option/alternative"
#   3. "compare ... options/approaches/alternatives"
#   4. "should we/i/you use ... or ..."
ALLOWLIST='(\bvs\.?\b|\bversus\b)'
ALLOWLIST+='|\bwhich (approach|option|alternative)'
ALLOWLIST+='|\bcompare\b.{0,15}\b(option|approach|alternative)'
ALLOWLIST+='|\bshould (we|i|you) use\b.{0,40}\bor\b'

if printf '%s' "$PROMPT" | grep -iqE "$ALLOWLIST"; then
  printf '%s\n' "💡 Routing reminder: this reads as a decision among multiple options — consider the divergent-design workflow (~/.claude/workflows/divergent-design.md) for its tradeoff-matrix treatment rather than open-ended brainstorming. (Non-blocking suggestion.)"
fi

exit 0
