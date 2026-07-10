#!/usr/bin/env bash
# UserPromptSubmit hook: batch-feedback → parallel-subagent routing reminder.
#
# Fires when a prompt looks like it bundles 2+ INDEPENDENT tasks (the common
# case being a batch of end-user feedback), and injects a single one-line,
# non-blocking reminder suggesting the work be split and fanned out to parallel
# subagents (one Agent-tool dispatch per item, with git-worktree isolation for
# items that implement) rather than ground through sequentially.
#
# This escalates decision-tree row 2 ("Message bundles 2+ independent tasks")
# from skimmable prose to a harness-executed interception — the same pattern as
# the sibling dd-routing-reminder.sh. It exists because the documented routing
# gets skipped: the observed failure is collapsing a multi-item batch into one
# sequential pass instead of fanning out.
#
# Mandatory mitigations (mirrors dd-routing-reminder.sh):
#   - Narrow detection: fires only on (a) >=2 numbered list items, (b) >=2
#     bullet list items, or (c) an explicit multi-item enumeration phrasing.
#     A single task, however it's phrased, must not match.
#   - Non-blocking: always exits 0 and never emits a block decision, so prompt
#     submission is never interrupted.
#   - Additive: a standalone script wired as an *additional* UserPromptSubmit
#     hook in settings.json; it does not replace existing hooks.
#
# Design note — fires on ALL UserPromptSubmit events, BY INTENT. The reminder
# is injected for the *model*, not shown to the human, so there is no human
# alert-fatigue path. It consequently also fires on agent/tool completion
# notifications (whose result text often carries bullet/numbered lists), not
# only human prompts. That breadth is deliberate: a non-human submit that
# enumerates several independent results can itself be a legitimate fan-out
# point. Cost is ~85 tokens per firing (one stdout line) — negligible against
# session context — so broad firing is preferred over adding submit-source
# detection to suppress it. Do not "narrow" this to human prompts without a new
# decision. (Reviewed 2026-06-23; see docs/reviews/override-log.md.)
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

emit() {
  printf '%s\n' "💡 Routing reminder: this reads as multiple independent tasks — consider splitting them and dispatching one parallel subagent per item, with git-worktree isolation for any that implement, instead of working through them sequentially. See decision-tree row 2 / \"Batch fan-out\". (Non-blocking suggestion.)"
  exit 0
}

# (a) Numbered list: >=2 lines beginning (after optional whitespace) with a
#     number followed by '.' or ')' and a space — "1. ", "2) ", "  3. ".
numbered=$(printf '%s\n' "$PROMPT" | grep -cE '^[[:space:]]*[0-9]+[.)][[:space:]]')
[[ "$numbered" -ge 2 ]] && emit

# (b) Bullet list: >=2 lines beginning with '-', '*', or '•' and a space.
bullets=$(printf '%s\n' "$PROMPT" | grep -cE '^[[:space:]]*([-*•])[[:space:]]')
[[ "$bullets" -ge 2 ]] && emit

# (c) Explicit multi-item enumeration phrasings (case-insensitive). Each is
#     deliberately specific to "several distinct asks" so single-task prompts do
#     not match. A bare "fix this" or "add a button" matches none of these.
ENUM='\b(a few|a couple of|a number of|several|multiple) (things|items|issues|bugs|problems|requests|fixes|changes|tasks|asks)\b'
ENUM+='|\b(two|three|four|five|2|3|4|5) (things|items|issues|bugs|problems|requests|fixes|changes|tasks)\b'
ENUM+='|\bhere(?:'"'"'s| is| are)\b.{0,20}\b(the )?(feedback|bugs|issues|list)\b'
ENUM+='|\bthe following\b.{0,20}\b(feedback|bugs|issues|items|changes|tasks|requests)\b'
ENUM+='|\b(batch|list|round) of (feedback|bugs|issues|fixes|changes|tasks|requests)\b'

# Prefer grep -P so the non-capturing '(?:...)' groups in ENUM work as written.
# Fall back to grep -E only when -P is UNAVAILABLE — grep exits 2 on an
# unsupported/errored -P, versus 1 for a clean no-match. Gate the fallback on
# that error code, NOT on "didn't match": a plain no-match (exit 1) must not
# trigger a redundant second scan of the same prompt.
#
# COUPLING NOTE: the "${ENUM//(\?:/(}" rewrite turns each '(?:' into a plain '('
# so the pattern is valid ERE (which has no non-capturing groups). It assumes
# every non-capturing group in ENUM is written exactly as '(?:'. If you add
# another '(?:...)' group to ENUM, keep that spelling or this ERE fallback will
# silently misparse on -P-less systems.
printf '%s' "$PROMPT" | grep -iqP "$ENUM" 2>/dev/null
pcre_rc=$?
if [[ "$pcre_rc" -eq 0 ]]; then
  emit
elif [[ "$pcre_rc" -ge 2 ]]; then
  printf '%s' "$PROMPT" | grep -iqE "${ENUM//(\?:/(}" 2>/dev/null && emit
fi

exit 0
