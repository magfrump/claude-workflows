# Plan: Add Subtraction Phase to Self-Improvement Loop

## Goal
Add Step 5b (subtraction review) between Step 5 (merge) and Step 6 (completed-tasks update) in self-improvement.sh. Claude reviews existing skills and workflows for removal candidates, citing evidence from completed-tasks.md, hypothesis-log.md, and health-check output. Proposals logged to `docs/working/subtraction-proposals-round-N.md` for human review — no automatic deletions.

## Design

### Insertion point
Line 733 in self-improvement.sh, after the Step 5 merge loop ends and before Step 6.

### Evidence gathering
1. Read `$WORKING_DIR/completed-tasks.md` — shows what tasks have been completed, revealing which skills/workflows are being actively improved vs. ignored
2. Read `$WORKING_DIR/hypothesis-log.md` — REFUTED hypotheses are direct evidence for removal
3. Run `bash health-check.sh 2>&1` — failures indicate broken/inconsistent items

### Claude prompt design
- Use heredoc pattern (`read -r -d '' ... <<'EOF'`) for the static instruction body
- Prepend dynamic evidence (completed-tasks content, hypothesis-log content, health-check output)
- Direct output to `$WORKING_DIR/subtraction-proposals-round-$ROUND.md`
- Prompt instructs Claude to:
  - List all skills (`skills/*.md`) and workflows (`workflows/*.md`)
  - Cross-reference against evidence sources
  - For each removal candidate: name, evidence citation, rationale
  - If no candidates found, write "No removal candidates identified" with brief explanation
  - Use evaluation rubric dimension 1 (counterfactual gap) as the primary lens

### Safety
- No files are deleted or modified (proposals only)
- Output is a markdown file for human review
- Step logs to stdout like other steps
- Errors suppressed with `2>/dev/null || true` pattern (non-critical step)

## Implementation steps
1. Insert Step 5b block at line 733
2. Write summary file
