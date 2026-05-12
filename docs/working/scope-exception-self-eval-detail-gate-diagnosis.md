# Scope Exception: self-eval-detail-gate-diagnosis

**Task**: Diagnose why self_eval_detail and verdict_detail gates ran 0/2 successfully.

## Declared scope

```
scripts/si/, skills/self-eval.md, docs/working/morning-summary.md, docs/decisions/log.md
```

## Issue

The path `scripts/si/` does not exist in this repository. The SI scripts live at:

- `scripts/self-improvement.sh` (top-level loop entry point)
- `scripts/lib/si-functions.sh` (helpers, including `print_gate_stats`)
- `scripts/lib/si-input.sh`
- `scripts/lib/si-morning-summary.sh` (morning summary generator)

The intent of the declared scope is unambiguously "SI-related scripts". The fix
for the reported `self_eval_detail 0/2 pass` symptom lives in
`scripts/lib/si-functions.sh` (the `print_gate_stats` jq query treats
object-typed `_detail` records as if they were gate verdicts). Surfacing a
cause-of-skip line in the morning summary requires touching
`scripts/lib/si-morning-summary.sh` (the generator), not the rendered
`docs/working/morning-summary.md` output, which is overwritten on every run.

## Files actually modified

- `scripts/lib/si-functions.sh` — filter non-string values out of `print_gate_stats`
- `scripts/lib/si-morning-summary.sh` — add per-task cause-of-skip subsection
- `docs/decisions/log.md` — record the diagnosis and the fix
- `docs/working/scope-exception-self-eval-detail-gate-diagnosis.md` — this file

`skills/self-eval.md` was reviewed but not modified: the skill produces correct
output. The bug is in how the SI loop *aggregates* gate results for reporting,
not in the skill itself.
