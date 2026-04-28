# Plan: RPI ← From Divergent Design pivot

## Scope

See `research-r1-rpi-back-from-dd-pivot.md`. Add a `← From Divergent Design` entry to RPI's "When to pivot" section, capturing the implementation-time path back to DD.

## Approach

Insert a single new bullet immediately after the existing `→ Divergent Design` line (line 18) so the forward and back paths between RPI and DD sit next to each other. Use the user-supplied wording verbatim, prefixed with the existing `← From {Workflow}` naming convention. No other edits to the file.

## Steps

1. Edit `workflows/research-plan-implement.md`: insert a new bullet after the `→ Divergent Design` line. Wording: `**← From Divergent Design**: When implementation reveals a hard constraint that invalidates the DD-chosen approach (perf wall, missed integration constraint, infrastructure assumption that did not hold), pause implementation, append the new constraint to the decision record's Consequences section, and re-invoke DD with the augmented constraint set. This is for genuine constraint discovery, not for relitigating decisions that feel harder than expected.`
   - Size: ~1 line addition.

## Test specification

This is a documentation edit; no automated tests apply. Verification:

| Check | Expected | Level |
|-------|----------|-------|
| The new bullet exists immediately after `→ Divergent Design` | Visible in the file at the chosen position | manual read |
| Existing entries are unchanged | `git diff` shows only an insertion, no other modifications | manual diff |
| Wording matches the user's specification verbatim (apart from the `← From Divergent Design` prefix) | Exact string match | manual read |

## Risks

- Wording drift: the user's text is precise and the "genuine constraint discovery" guard must survive. Mitigation: copy verbatim.
- Misplacement: putting the entry far from the forward DD entry would scatter related guidance. Mitigation: insert immediately after line 18.
