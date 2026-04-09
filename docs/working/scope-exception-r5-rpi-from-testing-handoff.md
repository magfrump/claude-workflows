# Scope Exception: r5-rpi-from-testing-handoff

## File that should be updated but is outside scope
`CLAUDE.md` — the "How workflows compose" section lists common composition paths (RPI ↔ DD, RPI ↔ Spike, etc.) but does not include Testing ↔ RPI. Adding a bullet like:

> - **User Testing → RPI**: When testing identifies a feature or bug, the findings report feeds into RPI research. The severity-rated issues and prioritization matrix replace broad exploration.

would make the composition visible in the decision-tree documentation, not just in the individual workflow files.

## Why not changed
File scope constraint limits changes to `workflows/research-plan-implement.md` and `docs/working/` files.
