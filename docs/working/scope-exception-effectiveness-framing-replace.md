# Scope Exception: effectiveness-framing-replace

## File: workflows/bug-diagnosis.md

**Reason:** Not listed in the file scope constraint for this task. The health-check's
`check_workflow_value_justification` will emit a warning for this file until
`value-justification` frontmatter is added in a separate change.

**Suggested frontmatter:**
```yaml
---
value-justification: "Replaces unstructured printf-debugging with a hypothesis-test loop that converges on root causes faster."
---
```
