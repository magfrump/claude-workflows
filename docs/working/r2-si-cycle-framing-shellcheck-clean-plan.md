# SI Cycle Framing — Shellcheck-Clean Re-attempt

## Problem

The SI loop generates ideas without an explicit problem-side anchor for each
round. The prior r1 attempt (`feat/r1-si-cycle-framing-record`, commit
`8d9487b`) added a one-shot framing for the whole run but did not survive the
shellcheck gate. This re-attempt makes a per-cycle framing and is written to
pass shellcheck on first try.

## Goal

At the start of every SI round (a "cycle"), emit a one-paragraph
`docs/working/cycle-framing.md` naming the cycle's focus, and inject that
framing into the round's idea-generation prompt. The file is overwritten each
cycle.

## Design

- **"Cycle" = one SI round.** Each iteration of the `for ROUND in $(seq ...)`
  loop emits a fresh `docs/working/cycle-framing.md`. Earlier rounds' framings
  are not preserved (they are visible in the round report log if needed).
- **Function placement.** New `emit_cycle_framing` lives in
  `scripts/lib/si-functions.sh` so the call site in `self-improvement.sh`
  stays small (one line + context-read), and so the function is unit-testable
  in isolation.
- **Call site.** Right after `init_round_log "$ROUND"` and before the
  `PRIOR_CONTEXT` assembly. The framing only needs the round number, working
  dir, and the user-input context block; it doesn't depend on prior-round
  parsing.
- **Injection.** The script reads the emitted file with `$(<"$file")` (not
  `cat`) and injects the content into the idea-generation prompt next to
  `PRIOR_CONTEXT`, `SEED_CONTEXT`, `USER_INPUT_CONTEXT`. Without injection
  the framing is decorative; the point is to anchor idea generation.
- **Failure handling.** `claude -p` is non-fatal: the function uses
  `|| true` and checks `[ -f "$file" ]` afterward. If the file is missing,
  `CYCLE_FRAMING_CONTEXT` stays empty and idea generation proceeds as before.
  Cycle framing is advisory, not a gate.

## Shellcheck discipline

The previous attempt likely tripped on:
- `$(cat "$FILE")` — SC2002 ("useless use of cat"). Replaced with `$(<"$file")`.
- Unquoted command substitutions and variable expansions.

This implementation:
- Both files keep `set -euo pipefail` (self-improvement) /
  source-only guard (si-functions).
- All variable expansions are double-quoted.
- File reads use `$(<"$file")`.
- The function uses `local` for all internals so nothing leaks into callers.

## Files

- `scripts/lib/si-functions.sh` — add `emit_cycle_framing` near the other
  helpers.
- `scripts/self-improvement.sh` — call the function at the start of each
  round; read the result into `CYCLE_FRAMING_CONTEXT`; inject into the
  idea-generation prompt.
- `docs/working/cycle-framing.md` — emitted at runtime; not committed.

## Verification checklist

- [x] `set -euo pipefail` present in `scripts/self-improvement.sh`.
- [x] Sourced lib `scripts/lib/si-functions.sh` does not need its own set
      options (it's sourced into a shell that already has them) but its
      direct-execution guard remains.
- [x] All variable expansions in new code are quoted (`"$var"`).
- [x] No unquoted command substitutions; file reads use `$(<"$file")`.
- [x] `shellcheck scripts/self-improvement.sh scripts/lib/si-functions.sh`
      passes with the project `.shellcheckrc` (only `SC1091` suppressed).
- [x] Manual review: the function is exit-clean — `claude -p` failures and
      missing files are handled and do not terminate the script.
