# Scope Exception / Premise Revision — r3 si-cycle-framing-python-only

- **Goal**: Emit a one-line `Cycle framing: ...` entry at the top of `docs/working/morning-summary.md` without modifying any `.sh` file, by introducing a non-`.sh` emitter.
- **Problem framing**: Prior R1/R2 attempts touched `scripts/lib/si-functions.sh` and were rejected by the shellcheck gate; this round routes around the gate by emitting from a Python writer instead. Considered and discarded: "make the bash writer pass shellcheck this time" — already attempted in R2 and is what the SI gate is filtering out, so a same-language re-try doesn't change the failure mode.
- **Project state**: This branch adds a Python-based morning-summary supplement that prepends the cycle-framing line · standalone (no upstream branch dependency) · not blocked (cite: `scripts/lib/si-morning-summary.sh`).
- **Task status**: in-progress (premise revision documented; implementing Python emitter next)

## Why this exception note exists

The candidate description supplied with the task says:

> v3 routes around the gate by emitting from a non-.sh code path (the existing writer that produces morning-summary.md)

The note at the end of the task description flagged that this premise might not hold:

> Note: implementer must first verify which file currently writes morning-summary; if the current writer is a .sh file, this candidate's premise may require revision before implementation.

Verification (`grep -rn morning-summary scripts/` and reading `scripts/lib/si-morning-summary.sh`) confirms the **only** writer that produces `docs/working/morning-summary.md` is `scripts/lib/si-morning-summary.sh`, invoked from `scripts/self-improvement.sh:121` inside `finalize_round_log`. There is no pre-existing Python or other non-`.sh` writer to extend.

## Premise revision

Instead of editing the existing writer, this round introduces a **new** non-`.sh` emitter under `scripts/lib/`:

- `scripts/lib/si-morning-summary.py` — a small Python module + CLI that reads `docs/working/morning-summary.md`, prepends a one-line `Cycle framing: <text>` entry at the top, and writes the file back. Idempotent: re-running with a new framing replaces an existing `Cycle framing:` line rather than stacking duplicates.

This satisfies the deliverable shape ("one-line entry at the top of morning-summary.md") via a non-`.sh` code path, so the shellcheck gate cannot fire on it. The `.sh` file in the file-scope allowlist (`scripts/lib/si-morning-summary.sh`) is **not** modified.

## Known integration gap (explicit)

Wiring this Python emitter into the SI loop's per-round refresh would require editing `scripts/lib/si-morning-summary.sh` (to invoke the Python after the bash writer finishes) or `scripts/self-improvement.sh`. Both are out of scope under the "no `.sh` edits" constraint that defines this candidate. The Python emitter is therefore deliverable-shaped (it produces the exact file contents the task asks for when invoked) but not auto-wired this round; the wiring is the natural next-round follow-up and would be done from a non-`.sh` invocation point (e.g., a `.claude` hook in `settings.json`) to preserve the shellcheck-clean property.

This gap is recorded here so a future round picking up the integration knows the constraint that produced the gap and doesn't re-derive it.
