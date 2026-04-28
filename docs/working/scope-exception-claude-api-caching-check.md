# Scope Exception: claude-api skill is binary-embedded, not file-editable

## Context
Task asked to add a checklist item to the bundled `claude-api` skill enforcing
prompt-caching verification (verify long-lived content has a
`cache_control: {type: "ephemeral"}` breakpoint; flag if missing).

The task description acknowledged uncertainty: *"Marked UNCERTAIN in the
tradeoff matrix because skill structure is unknown — implementer should read
first and adjust insertion point."* and directed the implementer to look under
`~/.claude/plugins/` or marketplace paths.

## What I found
The `claude-api` skill is **not a file**. Its content is embedded as a string
literal inside the Claude Code binary at
`/home/magfrump/.local/share/claude/versions/2.1.121` (a 247 MB ELF
executable). I confirmed this by:

1. Searching `~/.claude/plugins/`, `~/.claude/skills/`, `~/.claude/agents/`,
   and the entire `~/.claude/` tree — no `claude-api.md` or
   `claude-api/SKILL.md` exists.
2. Searching `~/.local/share/claude/` — only the binary and version dirs.
3. Searching every `SKILL.md` (68 files) under `~/.claude/plugins/` for
   `claude-api` content — no matches; only Vercel-namespaced and
   plugin-namespaced skills exist as files.
4. `strings` on the binary returned the full skill body (system prompt,
   language docs, cache_control guidance) inline, confirming it ships baked
   into the executable.

## Why this can't proceed under the file-scope constraint
- The skill is shipped by Anthropic inside Claude Code. The only "file" is the
  binary, which is not editable in any meaningful sense (it would also be
  overwritten on the next Claude Code update).
- There is no marketplace or plugin source we can patch.
- Creating an override at `~/.claude/skills/claude-api.md` would be outside
  the file-scope constraint (which named "the claude-api skill file (location
  TBD)" — implying a real bundled file). It is also unclear whether a user
  skill of the same name overrides a built-in, or how Claude Code's loader
  resolves the conflict; that is a separate spike, not this task.

## What the skill already says about caching
The embedded skill content already references prompt caching extensively
(language-specific cache_control guidance, ttl options, `usage.cache_*_tokens`
verification). The proposed checklist item — "verify long-lived content has a
`cache_control: ephemeral` breakpoint; flag if missing" — duplicates guidance
that is already present, just not framed as a review-checklist bullet.

## Recommended follow-ups (out of scope here)
1. **File the request upstream.** This change belongs in Anthropic's source
   for the bundled skill. A GitHub issue against the appropriate Claude Code
   / skills repo would be the right channel.
2. **If a user-level override is desired**, run a small spike first to confirm
   override behavior, then create `~/.claude/skills/claude-api.md` as a
   supplemental skill (different name to avoid collision, e.g.
   `claude-api-caching-review`) that activates on the same triggers and
   adds the explicit checklist.
3. **Cross-reference from the workflow repo's `code-review.md` or
   `api-consistency-reviewer.md`** — those *are* in this repo's scope and
   could pick up the caching-verification rule for Anthropic SDK diffs
   without needing to touch the bundled skill. This is a cleaner path and
   should be considered for a future round.

## Files NOT modified
- The bundled `claude-api` skill (binary-embedded — unmodifiable).
- No user override created (out of scope, and override semantics unverified).
