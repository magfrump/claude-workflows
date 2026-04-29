---
name: claude-api
description: >
  In-repo supplement to the bundled `claude-api` skill that ships with Claude
  Code. Adds workflow-repo-maintained reference material on Claude API /
  Anthropic SDK behavior that is easy to get wrong in practice — streaming
  semantics, multi-turn invariants, and other details where the bundled skill
  is light. Activates on the same triggers as the bundled skill: code that
  imports `anthropic` / `@anthropic-ai/sdk`, questions about prompt caching,
  extended thinking, tool use, batch, files, citations, or memory in an
  Anthropic SDK project. Treat this file as a complement, not a replacement —
  the bundled skill remains the primary source for setup and language-level
  guidance.
when: Working on Claude API / Anthropic SDK code where bundled-skill guidance is insufficient
---

> On bad output, see guides/skill-recovery.md

# Claude API (in-repo supplement)

This file is a supplement to the bundled `claude-api` skill, which is embedded
in the Claude Code binary and not editable from a repository (see
`docs/working/scope-exception-claude-api-caching-check.md` for the binary-
embedded finding). Use it when the bundled skill is silent or thin on a topic
that has bitten real callers in this codebase or in adjacent projects.

## Streaming + extended thinking

When a streamed response has extended thinking enabled, the API emits
**thinking blocks before content blocks** within a single message. Block
ordering inside the message is stable:

1. `thinking` (and any `redacted_thinking`) blocks — block indices `0, 1, …`.
2. `text` and/or `tool_use` blocks — later block indices.

Each block is bracketed by a `content_block_start` / `content_block_stop`
pair, with `content_block_delta` events in between. Inside a thinking block
you'll see one or more `thinking_delta` events (the reasoning text) followed
by a `signature_delta` event before the closing `content_block_stop`. The
signature must be preserved with the thinking block if you ever echo the
assistant turn back to the API on a later turn.

### Routing block types

Consume the stream once and switch on the block type at `content_block_start`,
then on the delta's own type inside `content_block_delta`. Don't try to
infer block type from delta shape — the SDK already gives you the explicit
type, and inference will break the moment a new delta type ships.

```python
import anthropic

client = anthropic.Anthropic()

with client.messages.stream(
    model="claude-opus-4-7",
    max_tokens=16000,
    thinking={"type": "enabled", "budget_tokens": 10000},
    messages=[{"role": "user", "content": "..."}],
) as stream:
    for event in stream:
        if event.type == "content_block_start":
            block = event.content_block
            # block.type ∈ {"thinking", "redacted_thinking", "text", "tool_use", ...}
            on_block_start(event.index, block)

        elif event.type == "content_block_delta":
            d = event.delta
            if d.type == "thinking_delta":
                on_thinking_text(event.index, d.thinking)
            elif d.type == "signature_delta":
                # Persist with the thinking block — required for multi-turn replay.
                on_thinking_signature(event.index, d.signature)
            elif d.type == "text_delta":
                on_text(event.index, d.text)
            elif d.type == "input_json_delta":
                on_tool_input(event.index, d.partial_json)

        elif event.type == "content_block_stop":
            on_block_stop(event.index)

    final_message = stream.get_final_message()  # full Message with all blocks
```

The high-level helper `stream.text_stream` yields only visible text. It is
fine for one-shot completions where you don't need to retain the thinking
blocks, but **don't use it on any code path that may replay the assistant
turn** (multi-turn tool use, audit logging, transcripts) — you'll discard
the thinking blocks and their signatures and the next turn will fail
validation.

### Common pitfalls

- **Ignoring thinking events.** UIs that render only `text_delta` look frozen
  during the thinking phase, which can be many seconds. Surface a
  "thinking…" affordance, or stream `thinking_delta` text into a collapsible
  region. Silence is the worst option.
- **Dropping the signature.** Persisting thinking text without the
  `signature_delta` makes the block unusable on the next turn. The API
  rejects assistant turns whose thinking blocks are missing or whose
  signatures have been altered. Treat the signature as part of the block,
  not metadata you can shed when serializing.
- **Reordering on resume.** When echoing a prior assistant turn back to the
  API (typically after a `tool_result`), preserve the original block order:
  thinking blocks first, content blocks after, in the indices you received.
  Don't "tidy up" by moving thinking to the end, deduplicating it, or
  stripping it to save tokens — the validator requires the original layout.
- **Conflating thinking with visible output.** `thinking_delta` is the
  model's internal reasoning, not assistant output. Don't pipe it into the
  same buffer as `text_delta`; route by block type so downstream rendering
  can decide whether (and how) to surface it.
- **Stopping on the first visible token.** Breaking out of the loop the
  moment you see `text_delta` skips the closing `content_block_stop`,
  `message_delta` (which carries `stop_reason` and final `usage`), and
  `message_stop`. The accumulator on `stream` will be half-built and
  `get_final_message()` may return an incomplete message. Drain the stream.
