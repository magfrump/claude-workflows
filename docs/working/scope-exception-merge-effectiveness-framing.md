# Scope Exception: merge-effectiveness-framing

## Out-of-scope changes from origin/feat/r8-merge-effectiveness-framing-replace

The source branch contains two changes outside the allowed file scope:

### 1. CLAUDE.md — removes "How workflows compose" section

The branch deletes the workflow composition guidance from CLAUDE.md (lines ~51–63).
This content was moved into a standalone guide (`guides/workflow-composition-guide.md`)
in a prior merge (commit 14e895f on main). The removal is correct but CLAUDE.md is
not in the file scope constraint for this task.

**Action needed:** Remove the duplicated "How workflows compose" section from CLAUDE.md
in a follow-up task, or verify it was already removed by the R7 merge.

### 2. docs/working/summary-plan-drift-checklist-item.md — deleted

The branch deletes this summary file. Deletion of files outside scope is not permitted.

**Action needed:** Evaluate in a follow-up whether this file should be cleaned up.
