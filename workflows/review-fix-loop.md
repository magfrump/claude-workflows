# Review → Fix → Revalidate Loop

## When to use
- After completing a feature branch and wanting to harden it before merge
- When skill-generated review artifacts (code review, self-eval, fact-check) exist for your work
- As a final polish pass that catches issues automated tests miss
- When you want structured, converging quality improvement rather than ad-hoc cleanup

This workflow is a complement to Research → Plan → Implement. RPI gets you to a working feature; this loop gets the feature from "works" to "passes review."

## Prerequisites

- A feature branch with committed work
- At least one review skill available (code-review, self-eval, fact-check, etc.)
- BATS test infrastructure if the project has structural output tests

## Process

### 1. Generate initial reviews

Run the relevant review skills against the current state of the branch. For a typical feature branch this means:

- **Code review** (`/code-review`) — multi-critic structural review of the diff vs main
- **Self-eval** (`/self-eval <target>`) — rubric assessment of any new or modified skills/workflows

Run these in parallel when possible. They produce artifacts in `docs/reviews/`.

### 2. Triage findings

Read each review artifact and categorize findings by tier:

| Tier | Meaning | Action |
|------|---------|--------|
| Must Fix | Correctness bugs, false passes, wrong behavior | Fix before proceeding |
| Must Address | Fragility, inconsistency, misleading tests | Fix or explicitly acknowledge |
| Consider | Style, duplication, future-proofing | Fix if cheap, otherwise note for later |

Mark any findings that are already fixed (from prior iterations or parallel work) so you don't re-investigate them.

### 3. Fix point by point

Work through findings in tier order (Must Fix → Must Address → Consider). For each finding:

1. Read the relevant code to confirm the finding is real (reviews can hallucinate)
2. Make the fix
3. If the fix is mechanical (rename, tighten a regex), apply it directly
4. If the fix requires judgment (restructure a helper, change scoping strategy), think through edge cases before editing

Commit after completing a coherent batch of fixes (e.g., all findings from one review, or all Must Fix items). Use conventional commit messages that reference the review finding IDs:

```
fix: Address code review findings A2-A5
```

### 4. Run tests and fix breakage

After fixing review findings, run the relevant test suite:

```bash
bats test/skills/*-format.bats
```

Review findings sometimes reveal latent bugs that the tests themselves have (e.g., a regex that works in `grep -E` but not in `sed` without `-E`). Fix these as separate commits — they're distinct from the review-driven fixes.

This step is where the loop earns its keep: fixing one issue often surfaces another. A tightened assertion may expose a bug in the helper it calls. A scoping fix may reveal that the test was silently passing for the wrong reason.

### 5. Commit and push

Commit all fixes. Push to the remote branch so the next review iteration sees the updated code.

### 6. Re-run reviews

Run the same review skills again against the updated branch. This is the revalidation step.

Compare the new review artifacts against the previous ones:
- Are the prior findings resolved?
- Did any fixes introduce new findings?
- Did the reviewers surface issues that were hidden by the bugs you just fixed?

### 7. Repeat or exit

**Exit when:** The review comes back clean (no Must Fix, no Must Address items you disagree with, Consider items are acknowledged or deferred).

**Repeat when:** New findings appear, especially if they were masked by issues you fixed in the previous iteration. Each loop should be strictly smaller than the last — if the finding count isn't converging, step back and reconsider the approach.

Typical feature branches converge in 2-3 loops.

## Loop dynamics

The key insight is that each iteration operates on a higher-quality baseline:

```
Loop 1: Fix obvious issues (wrong field names, broken regexes, UUOC)
Loop 2: Fix subtle issues revealed by Loop 1 fixes (scoping bugs, false passes)
Loop 3: Fix consistency issues across the now-correct test suite
```

Reviews get more useful as the code gets cleaner — early reviews are dominated by surface issues that mask deeper ones. This is why a single review pass is often insufficient.

## Anti-patterns

- **Fixing Consider items before Must Fix items.** Tier order exists for a reason — fixing a style issue in code that has a correctness bug is wasted work.
- **Skipping the test run between fix and re-review.** The test run is where you catch issues the review didn't anticipate. Skipping it means the re-review may pass on code that doesn't actually work.
- **Treating review findings as infallible.** Always read the code to confirm. Reviews can misidentify field names, miscount sections, or flag correct code as buggy.
- **Running more than 3-4 loops.** If findings aren't converging, the problem is architectural, not incremental. Step back and use a different workflow (divergent-design, RPI).

## Artifacts

This workflow doesn't produce its own working documents. It operates on and updates:

- `docs/reviews/*.md` — review artifacts (overwritten each loop)
- Test files — fixed as findings are addressed
- The feature branch itself — commits accumulate naturally

The commit history serves as the audit trail for what was found and fixed in each loop.
