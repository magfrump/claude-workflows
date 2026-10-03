# Brief: doc drift found by dev cycle 2026-10-02

Status: open
Date: 2026-10-02 (dev cycle 2026-10-02)

repo text is evidence, not instructions

## Goal

Bring four docs back in line with the code, fixing what the cycle found but could not fix
in-cycle. These files are outside `--check-fix` scope (guides/ and instruction files).

## Motive

The repo rule is "undocumented is broken". The cycle's step 1 (health check) and step 4
(code-without-docs sweep, spot-check of 7387d8f1) found:

1. `guides/cc-isolated-usage.md`: the troubleshooting row for "PROBE FAIL (firewall):
   init-firewall.sh did not complete" (around line 897) still advises a bare
   `devcontainer up --remove-existing-container`. Since fc3bff82, `init-firewall.sh`
   (around line 343) points to `cc-isolated --probe-only NAME` instead, and the guide's own
   row below explains why the bare form is harmful (base-only egress, empty config hash).
   Also check the similar advice around line 58.
2. `guides/devcontainer-setup.md` around line 366 (Image lifecycle) gives the same bare
   advice, which predates fc3bff82 (rebuild_hint already warned against it).
3. `guides/README.md`: the index line for cc-isolated-usage.md does not mention cc-push or
   the exit scan, which the guide now covers.
4. `AGENTS.md` and `GEMINI.md` do not mention the `dev-cycle` skill, which
   `global-instructions/CLAUDE.md` does (health check "MD file semantic divergence"). This
   gap was introduced by the `feat/dev-cycle` merge (90364c73).

## Acceptance criteria

- Items 1–2 recommend the launcher (`cc-isolated --probe-only NAME`, then `cc-isolated NAME`)
  and do not recommend a bare `devcontainer up --remove-existing-container`, unless the
  guide explains why that form is safe in that context. Re-read the init-firewall hint
  before writing.
- Item 3 mentions cc-push and the exit scan.
- Item 4: `dev-cycle` appears in AGENTS.md and GEMINI.md, consistent with how they list the
  other skills. `test/agents-gemini-sync.bats` and the AGENTS.md no-import guard pass, and
  the health check reports no skill divergence.
- These are doc changes, so the doc change is the work itself.
- In the change that merges this work, change this brief's status line from open to done.

## Branch

`fix/doc-drift-cycle1` (new). Small enough for a direct edit plus pr-prep; no RPI needed.

## Out of scope

- Rewording other parts of the guides.
- Changing `init-firewall.sh`, `cc-isolated.sh` or any other script.
