# PR Preparation Workflow

## When to use
Before opening any pull request, especially when the reviewer is in a different timezone or unfamiliar with the libraries used.

## Process

### 1. Clean up commit history

```bash
git rebase -i origin/main
```

Squash WIP commits into logical chunks. Each commit in the final history should represent one coherent change that could be reviewed independently. Good commit sequence for a feature:

1. `feat: add data model for X` (reviewable alone)
2. `feat: add API endpoint for X` (builds on 1, reviewable with context)
3. `feat: add UI for X` (builds on 1-2)
4. `test: add tests for X` (or interleaved with the above)

### 2. Self-review

Run through the diff as if you were the reviewer:

```bash
git diff origin/main...HEAD
```

Check for:
- Dead code, debugging artifacts, console.logs
- TODOs that should be resolved before merge
- Files that were changed but shouldn't have been (accidental reformatting, unrelated changes)
- Import ordering / style consistency with the rest of the project

### 3. Verify CI passes locally

Run whatever checks the project has: lint, build, tests. Fix anything broken. Do not leave this for the reviewer to discover.

### 4. Write the PR description

Structure:

```markdown
## What this does
[1-3 sentences: what changed and why]

## How it works
[Brief technical summary. Not a line-by-line walkthrough — describe the approach.]

## How to test
[Concrete steps the reviewer can follow to verify the change works]

## Areas of uncertainty
[Flag anything you're not confident about:
 - Libraries or patterns you haven't used before
 - Performance implications you haven't measured
 - Edge cases you thought of but didn't handle]

## Decisions made
[Link to any docs/decisions/ files created, or briefly note non-obvious choices]
```

### 5. Annotate the diff

If the PR includes code in languages or libraries the reviewer may not know well, add **PR comments on your own PR** explaining non-obvious sections. This is cheaper than back-and-forth across timezones.

### 6. Size check

If the PR exceeds ~500 lines changed, consider whether it can be split. Look for:
- A preparatory refactor that can land independently
- Infrastructure/model changes separate from UI changes
- A minimal first PR that adds the feature behind a flag, with polish in a follow-up

If it genuinely can't be split, note this in the PR description and suggest a review order for the files.
