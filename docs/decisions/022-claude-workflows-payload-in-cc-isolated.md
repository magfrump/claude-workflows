# 022: Bake the claude-workflows payload into the cc-isolated image

**Date:** 2026-07-29 · **Status:** Accepted (pending host `install.sh` + bless + rebuild)

## Context

`cc-isolated` mounts `/home/node/.claude` as a **per-project Docker volume** (decision 016
H6: one volume per project, so a compromised session cannot read another project's
credentials or history). A fresh volume is empty, and nothing ever populated it with this
repo's skills, workflows, guides, patterns, or global `CLAUDE.md`.

Consequence, verified empirically in a live cc-isolated session on 2026-07-29:

```
$ ls ~/.claude/skills ~/.claude/CLAUDE.md ~/.claude/workflows
(none exist)
$ echo "list your skills" | claude -p
dataviz, update-config, keybindings-help, simplify, ..., review, security-review
```

Those are Claude Code **built-ins**. None of the repo's 25 skills were registered — not
`code-review`, not `security-reviewer`, none. The routing table in `CLAUDE.md`, the
workflow decision tree, the critic panel: absent from every cc-isolated session the repo
has ever run.

Two things disguised this:

1. The built-in skill list contains `review` and `security-review`, which read like the
   repo's `code-review` and `security-reviewer` but are unrelated.
2. `skills/code-review/SKILL.md` instructs the orchestrator to **read critic skill files
   by path** and paste their contents into sub-agent prompts. That works from `$PWD`
   whenever the session happens to be editing claude-workflows itself — so the pipeline
   appeared to function in exactly the sessions where this repo was developed, and
   silently did nothing everywhere else.

## Decision

Bake the payload into the image at `/opt/claude-workflows` (root-owned, `0555`) and
symlink it into the per-project volume at container start.

- **`install.sh`** assembles `devcontainer-config/claude-home/` from the repo root
  (`CLAUDE.md`, `skills/`, `workflows/`, `guides/`, `patterns/`, `hooks/`) on every run,
  plus a `.manifest` recording the source commit. The staged dir is gitignored and shows
  up in install.sh's existing diff-and-approve gate.
- **Dockerfile** copies it to `/opt/claude-workflows`, root-owned, dirs `0555`, files
  `0444` (`.sh`/`.py` `0555` so hooks stay runnable).
- **`link-claude-home.sh`** (new, runs unprivileged at `postStartCommand` after the
  firewall) symlinks each entry into `~/.claude/`. Idempotent; refreshes its own symlinks;
  never clobbers a real file already in the volume.

### Why symlinks into a volume, not a bake at `/home/node/.claude`

A volume mount shadows whatever the image has at that path. Docker's populate-on-first-use
would seed an empty volume once and then never update — every existing project would be
frozen at whatever the payload was the day its volume was created, with no signal. The
symlink indirection means an image rebuild takes effect on next start, everywhere.

### Why root-owned and read-only

`node` (the agent) cannot edit `/opt/claude-workflows`. Landing a change requires a human
on the host: edit the repo → `install.sh` → read the diff → bless → rebuild. This is the
same boundary the devcontainer config itself uses.

This is deliberately *stronger* than the naive fix. A writable `~/.claude/skills` would
let a session rewrite the critics that review it — the identical failure mode found in
Gate 1h, where the reviewer was pointed at the skill file inside the branch under review.
Gate 1h now reads `/opt/claude-workflows/skills/code-review/SKILL.md` instead, and warns
loudly when it has to fall back to the branch copy.

### Hooks are shipped but NOT wired

`hooks/` is linked so the scripts are present, but nothing is written to `settings.json`.
Hook wiring changes session behavior — the `PreToolUse` guards can block tool calls — and
that should be a human opt-in, not something an image rebuild switches on silently.
Wiring the two non-blocking `UserPromptSubmit` reminders is a reasonable follow-up.

## Consequences

- **Easier:** every cc-isolated session, in any repo, gets the full process. The
  measurement program's premise (that these skills are what run) becomes true for the
  first time.
- **Harder:** the payload is frozen at image-build time. Editing `skills/` in the
  claude-workflows repo does not affect other projects until install + bless + rebuild.
  The `.manifest` commit stamp exists so a session can detect staleness; surfacing it in
  `health-check.sh` is a follow-up.
- **Duplication:** when the target repo *is* claude-workflows, `CLAUDE.md` is loaded twice
  (project + user scope). Harmless, mildly redundant.
- **Invalidates prior measurements' framing.** Every experiment in
  `docs/working/experiment-results-code-review-2026-07-29.md` ran with repo skills
  unregistered — sub-agents worked only because prompts pasted skill file contents
  explicitly. The findings about prompt-vs-model effects stand (the prompts were pasted
  verbatim either way), but any claim about "what a default session does" was measuring
  a session without this repo's process installed.
