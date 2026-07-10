# 014 — Secure-tool guidance: instruction layer + fixture lint + confinement spike

- **Goal**: Decide how to guide agents toward allowed/secure tools where they would otherwise reach for denylisted or prompt-generating ones, without expanding the security surface.
- **Project state**: claude-workflows main · follows the 2026-07-09 permissions/sandbox hardening · not blocked
- **Task status**: complete (decision made; implementation not started)

## Context

The 2026-07-09 hardening removed arbitrary-execution-capable prefixes from
`permissions.allow` (`find`, `fd`, `wsl`, `hyperfine`, `sed -n`, `terraform
plan`), enabled the bwrap sandbox, and wired guard-trusted-writes over Bash.
Agents now burn tokens on calls that fail against the denylist, surface
permission prompts on routine work (two user-facing prompt bursts in the week
before this decision, including the `claude -p`-in-tests incident fixed in
4d39475), and occasionally trip known guard false positives (heredoc commit
trailers). Goals: fewer failing calls, fewer prompts, security surface not
expanded; stretch goal: test fixtures with provably limited scope so suites
can run without being able to hide arbitrary code execution.

Full DD analysis (15 candidates, constraint matrix, stress tests):
`docs/working/dd-secure-tool-guidance.md`.

## Options considered

Fifteen candidates across instructions, hooks, infrastructure, tests, and
memory. Survivors scored in step 4:

| Approach | Effort | Risk | Coverage | Key downside |
|----------|--------|------|----------|--------------|
| Instruction layer (CLAUDE.md section + guide + drift test) | ~2h | low | broad, but recall-dependent | agents may not recall mid-task |
| Post-failure hint hook | ~4h | low-med | just-in-time, drift-proof | Claude-Code-only; hook sprawl |
| Fixture hermeticity lint | ~3h | low | prevents 4d39475-class recurrence | convention, not proof |
| Capability-manifest harness | days | high (WSL2 nested bwrap) | the actual provable-scope ideal | may be infeasible on this platform |

## Decision and rationale

Adopt three layers (user-selected 2026-07-09, from the DD Path-B consult):

1. **Instruction layer**: a ≤25-line "prefer allowed tools" section in global
   CLAUDE.md (principles + known substitutions: Read/Edit/Write/Glob over
   cat/sed -i/shell-redirect/find; `rg --files -g` for file search;
   `git commit -F` for trailer-bearing messages; stub network-capable
   binaries in test `setup()`; `$TMPDIR` over `/tmp`; on denial, consult the
   guide — never retry verbatim, never reach for sandbox-disable first),
   backed by `guides/sandbox-tool-map.md` with the full mapping and a bats
   drift test comparing the guide's substitution rows to live
   `~/.claude/settings.json`.
2. **Fixture hermeticity lint**: a static bats suite failing any test file
   that invokes network-capable binaries (`claude`, `curl`, `gh`, `wget`)
   without a `setup()` stub — generalizing the 4d39475 stub fix into an
   enforced convention.
3. **Capability-manifest spike**: 1-day timeboxed spike on running a bats
   suite under a nested bwrap profile (`network: none`, writes confined) on
   this WSL2 host. Outcome either seeds an RPI for per-suite confinement or
   records infeasibility with a revisit trigger.

The **post-failure hint hook was deferred** (not rejected): it scored well on
just-in-time delivery, but the instruction layer must exist first to have
content to hint with, and the user chose not to add another deployed-copy
hook this round. Revive if repeat-denials persist after the instruction
layer's 2-week evaluation window.

Rationale: instructions are portable (Claude Code, Gemini, AGENTS.md
consumers), cheap, and attack the known recurring denial classes; the lint
mechanically prevents the one incident class actually observed; the spike
resolves the stretch goal's feasibility question before any build investment.
Ordering came from the organizational-survival stress test (instructions
outlive hook wiring).

See alternatives considered → **Pruned candidates and why** below.

## Pruned candidates and why

How to read: each entry is `[candidate-ID]: one-line reason for discard`
(IDs from the DD working doc). Future DDs in adjacent areas can grep this
section to avoid regenerating already-pruned approaches.
[1 do-nothing]: is the status quo being fixed. [4 deny-with-guidance hook]: dominated by the post-failure hint hook — predicting denials duplicates settings; reacting doesn't. [5 auto-approve safe forms]: re-opens surface the 2026-07-09 hardening deliberately closed. [7 allowlisted repo wrappers]: an allowlisted executable in an agent-writable repo is arbitrary execution (copy-not-symlink argument). [8 skill]: skills trigger on intent, not tool failure. [9 UserPromptSubmit reminder]: wrong timing, token cost on every prompt. [13 full allowlist in CLAUDE.md]: hundreds of always-loaded lines, stale on every settings edit. [14 memory accretion]: no mechanism, relies on recall of recall. [15 nested per-command sandboxes for re-allowlisting]: WSL2 nested-bwrap fragility + widens surface; the spike (layer 3) tests the same primitive for the narrower fixture-confinement use.
Prior pruning grep: no matches found for [denylist, allowlist, sandbox, permission, tool selection].

## Stress-test mitigations

- How to read: *Boring alternative* mitigation — scoped the deferred hint
  hook to sandbox/permission-denial signatures only (not general command
  failure), after the move showed the instruction layer alone covers known
  classes and only failure-triggered delivery generalizes to novel ones.
- How to read: *Invert the thesis* mitigation — demoted the
  capability-manifest harness from "build" to "timeboxed spike": no observed
  incident involved a fixture *deliberately* hiding execution, so it is
  insurance, not an active bleed.
- How to read: *Failure-driven* mitigation — any future hint-hook content
  must ship inside the deployed hook copy, not be read live from the
  agent-writable repo (guidance content is itself trusted policy); the
  drift-test digest lists only command-prefix substitutions, not the full
  allowlist.

## Consequences

Easier: routine sessions stop re-discovering the denylist by trial and error;
test suites get a mechanical guard against live-binary reach-through; the
provable-fixtures question gets a cheap yes/no. Harder: CLAUDE.md gains
another always-loaded section (bounded ≤25 lines); the drift test introduces
an environment dependency on `~/.claude/settings.json` (must skip cleanly on
machines without it); the lint's grep heuristics will need tuning on false
positives.

## Revisit triggers

How to read: each entry is a concrete, observable condition that should
prompt re-evaluating this decision. Future readers can grep this section when
their context changes.
if same-session repeat denials for table-listed tools persist in ≥2 sessions after 2 weeks → revive the post-failure hint hook. if another 4d39475-class incident occurs in a suite the lint passed → escalate lint to the capability-manifest harness. if the spike shows nested bwrap works on WSL2 → open an RPI for per-suite confinement (and reconsider pruned candidate 15). if the allowlist gains/loses >5 prefixes in one edit → re-run the drift test and re-check the CLAUDE.md table. if Claude Code ships native denial-message customization → the deferred hint hook becomes a config entry, not a hook.
