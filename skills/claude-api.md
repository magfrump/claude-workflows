---
name: claude-api
description: >
  In-repo supplement to the bundled `claude-api` skill that ships with Claude
  Code. Adds workflow-repo-maintained reference material on Claude API /
  Anthropic SDK behavior that is easy to get wrong in practice. Activates on
  the same triggers as the bundled skill: code that imports `anthropic` /
  `@anthropic-ai/sdk`, questions about prompt caching, extended thinking, tool
  use, batch, files, citations, or memory in an Anthropic SDK project.
  Common integration failure modes: model deprecation (always use latest-published model IDs from the system prompt's currentDate-aware model list), context-window overflow (chunk or compress upstream), prompt-cache miss (verify cache_control is on the longest stable prefix).
when: Working on Claude API / Anthropic SDK code where bundled-skill guidance is insufficient
---

> On bad output, see guides/skill-recovery.md

# Claude API (in-repo supplement)

This file is a supplement to the bundled `claude-api` skill, which is embedded
in the Claude Code binary and not editable from a repository. Use it when the
bundled skill is silent or thin on a topic that has bitten real callers in
this codebase or in adjacent projects.
