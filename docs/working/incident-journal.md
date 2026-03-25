# Failure Incident Journal

**Last verified:** 2026-03-24
**Relevant paths:** guides/skill-recovery.md, skills/

Tracks real-world skill and workflow failures observed during actual use. Unlike test fixtures and self-eval (which operate on synthetic inputs), this journal captures failures from production runs with real content.

**Value is cumulative.** After ~10 entries, patterns should emerge — repeated failure modes, skills that struggle with specific input shapes, workflows that break under certain conditions. Use those patterns to inform targeted fixture creation or skill prompt updates.

**When to log:** After reaching Tier 3 (Skip) in the [skill recovery guide](../../guides/skill-recovery.md), add an entry here. Also log any surprising failure even if recovery succeeded at Tier 1 or 2 — if the failure was unexpected, it's worth recording.

| Date | Skill / Workflow | Input description | Failure mode | Recovery attempted | Root cause (if known) | Follow-up action taken |
|------|-----------------|-------------------|--------------|--------------------|-----------------------|------------------------|
