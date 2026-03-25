# Subtraction Review Checklist

Manual checklist for reviewing skills and workflows for potential removal.
Run this after each self-improvement merge (Step 5) and before the completed-tasks update (Step 6).

## When to run

After merging approved features each round, review the repository for removal candidates. This keeps the repo lean by pruning skills and workflows that have outlived their usefulness.

## Evidence sources

Gather evidence from these three sources before evaluating candidates:

1. **completed-tasks.md** (`docs/working/completed-tasks.md`) — History of all approved work. Skills/workflows never referenced across multiple rounds may lack demonstrated value.
2. **hypothesis-log.md** (`docs/working/hypothesis-log.md`) — Check for REFUTED entries. If a skill's justification was a hypothesis that was later refuted, the skill is a removal candidate.
3. **health-check output** (`bash health-check.sh`) — Persistent failures (broken frontmatter, missing cross-references, shellcheck errors) signal rot.

## Removal criteria

A skill or workflow is a removal candidate if it meets **at least one** of:

### Low usage / no impact
- [ ] The file has never appeared in completed-tasks.md as something improved, used, or referenced across multiple rounds
- [ ] It was added but never validated by the self-improvement loop

### Refuted hypothesis
- [ ] hypothesis-log.md contains a REFUTED entry whose hypothesis was the justification for this file existing

### Health-check failure
- [ ] health-check.sh shows persistent errors related to this file (missing cross-references, broken YAML frontmatter, failed tests)

### Complexity budget violation
- [ ] The file substantially overlaps with another skill/workflow (per `docs/evaluation-rubric.md` dimension 1 — counterfactual gap)
- [ ] The overlap adds complexity without proportional value

## Procedure

1. List every file in `skills/` and `workflows/`
2. For each file, check the four criteria above against the three evidence sources
3. For each removal candidate, document:
   - **File**: path to the skill or workflow
   - **Evidence**: quote or cite the specific line/entry from evidence sources
   - **Rationale**: one-sentence explanation of why removal is warranted
4. Write proposals to `docs/working/subtraction-proposals-round-N.md`
5. If no candidates are found, note "No removal candidates identified this round" with a brief explanation

## Rules

- **No automatic deletions.** All proposals require human review before action.
- **Every proposal must cite specific evidence.** "Seems unused" is not sufficient.
- **Read the rubric first.** Check `docs/evaluation-rubric.md` for the counterfactual-gap framework before assessing overlap.

## Output format

Write `docs/working/subtraction-proposals-round-N.md` with:
- A heading per removal candidate (file path as heading)
- Evidence and rationale under each heading
- Or a single "No removal candidates" section if the review is clean

## Future automation

This checklist is intended to be automated as Step 5b in `self-improvement.sh` once shellcheck compliance can be verified in the CI environment. The function signature should be:

```bash
run_subtraction_review() {
    local round=$1
    local working_dir=$2
    local repo_dir=$3
    # ... gather evidence, invoke Claude, write proposals
}
```

Called between Step 5 (merge) and Step 6 (completed-tasks update).
