# Subtraction Checklist

A manual review process for identifying skills, workflows, and other artifacts that should be considered for removal after each self-improvement round.

**When to run:** After merging an implementation branch (Step 5 of the self-improvement loop), before updating completed-tasks documentation.

**Goal:** Propose removal candidates with cited evidence. No file is deleted during this process — proposals go to a tracking document for human review.

---

## Evidence sources

The checklist draws on three concrete sources. Gather output from all three before evaluating candidates.

### 1. Hypothesis log (`docs/working/hypothesis-log.md`)

Each task in the self-improvement loop is created with a falsifiable hypothesis. When a hypothesis is **refuted**, the feature it justified may not be earning its keep.

**How to check:**

```bash
# Show refuted hypotheses
grep -i 'refuted\|falsified' docs/working/hypothesis-log.md
```

Look at the "Outcome" column for entries marked refuted. For each, identify which skill or workflow the originating task created or modified. That artifact is a removal candidate.

**Judgment call:** A refuted hypothesis does not mean automatic removal. The feature may have value beyond its original justification. But it does mean the original rationale no longer holds, and the artifact needs a new justification or should be proposed for removal.

### 2. Health-check complexity warnings (`health-check.sh`, check 7)

The repo health check flags workflows that exceed soft budgets:

- **>200 lines** — workflow is likely doing too much
- **>15 sections** (### headers) — workflow may have accumulated scope creep

**How to check:**

```bash
bash health-check.sh 2>&1 | grep -A2 'Workflow complexity'
```

Any workflow that triggers a WARN is a candidate for either:
- **Section removal** — identify and propose specific sections that could be cut
- **Split** — break the workflow into two focused workflows
- **Full removal** — if the workflow duplicates another or is never used

### 3. Skill usage report (`scripts/skill-usage-report.sh`)

The usage report shows invocation counts and recency for all known skills and workflows. Items listed under "Never invoked" after N rounds of active use are candidates for removal.

**How to check:**

```bash
bash scripts/skill-usage-report.sh
```

Focus on the "Never invoked" section at the bottom. Cross-reference with the round number — a skill that has never been invoked after 3+ rounds of active use is a stronger candidate than one added last round.

**Judgment call:** Some skills are intentionally low-frequency (e.g., `codebase-onboarding` runs once per project). Zero invocations alone is not sufficient — check whether the skill's use case has plausibly arisen and been skipped.

---

## Procedure

Run through these steps after each round's merge:

### Step 1: Gather evidence

Collect output from all three sources above. Copy or note the relevant lines.

### Step 2: Build candidate list

For each artifact flagged by any source, create an entry with:

| Field | Description |
|-------|-------------|
| **File** | Path to the skill, workflow, or guide |
| **Source** | Which evidence source flagged it (hypothesis / complexity / usage) |
| **Evidence** | The specific data point (e.g., "0 invocations over 4 rounds", "hypothesis H3 refuted in round 5", "287 lines, 18 sections") |
| **Recommendation** | Remove / trim sections / split / keep with new justification |
| **Notes** | Any mitigating factors or context |

### Step 3: Check for corroborating signals

An artifact flagged by multiple sources is a stronger candidate:

- Never used **and** its hypothesis was refuted — strong removal signal
- Over complexity budget **and** never used — strong removal signal
- Over complexity budget **but** actively used — trim, don't remove

Also check:
- `docs/working/incident-journal.md` — has the artifact caused failures?
- `guides/skill-recovery.md` — has the artifact needed repeated recovery?

### Step 4: Write proposals

Write findings to `docs/working/subtraction-proposals-round-N.md` (where N is the current round number). Use this format:

```markdown
# Subtraction Proposals — Round N

Date: YYYY-MM-DD

## Candidates

### [filename]
- **Source:** hypothesis-log / complexity / usage
- **Evidence:** [specific data]
- **Recommendation:** remove / trim / split / keep
- **Notes:** [context]

## No action needed
[List artifacts that were reviewed but don't warrant changes, with brief reasoning]
```

### Step 5: Flag for human review

Subtraction proposals require human approval before any file is deleted or modified. Leave the proposals document in `docs/working/` for review in the next active session.

---

## Rules

1. **No automatic deletions.** This checklist produces proposals, never removals.
2. **Cite evidence.** Every proposal must reference at least one of the three evidence sources with specific data.
3. **Preserve the log.** Even after removal, keep a record of what was removed and why in the round's proposal document.
4. **One round of grace.** Don't propose removal for artifacts added in the current round — they haven't had time to prove value.
5. **Check dependencies first.** Before proposing removal, grep for references to the artifact across the repo. A skill referenced by a workflow or guide needs those references updated too.

---

## Quick reference

```
After merge:
  1. grep hypothesis-log.md for refuted hypotheses
  2. run health-check.sh, note complexity warnings
  3. run skill-usage-report.sh, note never-invoked items
  4. cross-reference: multiple signals = stronger candidate
  5. write proposals to docs/working/subtraction-proposals-round-N.md
  6. flag for human review
```
