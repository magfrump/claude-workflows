# Dev Branch Workflow

## When to use
When working on a project with multiple concurrent feature branches that need to be tested together before merging to main.

## Branch structure

```
main          ← stable, production-ready
  └── dev     ← integration branch, all features merged here
        ├── feat/feature-a   (branched off main)
        ├── feat/feature-b   (branched off main)
        └── fix/bugfix-c     (branched off main)
```

## Rules

1. **Feature branches always branch off `main`**, not `dev`. This keeps them independent and reviewable.
2. **Never commit directly to `dev`** — only merge feature branches in.
3. **Resolve conflicts on `dev`**, not on feature branches. Feature branches stay clean.
4. **`dev` is disposable.** If it gets too messy, delete and recreate it from `main` + re-merge all active feature branches.
5. **Merge `main` into `dev`** periodically to keep it current after PRs land on main.

## Setting up a dev branch

```bash
# Create from main
git checkout main
git pull
git checkout -b dev

# Merge each feature branch
git merge feat/feature-a --no-edit
git merge feat/feature-b --no-edit
# Resolve conflicts at each step if needed
```

If a feature branch has conflicts with dev, resolve them during the merge into dev. The feature branch itself stays untouched.

## After a feature merges to main

```bash
# Update dev to include the newly landed code
git checkout dev
git merge main --no-edit

# The merged feature branch can now be deleted
git branch -d feat/landed-feature
```

## When dev gets stale or broken

Rather than trying to fix a messy dev branch, recreate it:

```bash
git branch -D dev
git checkout main
git checkout -b dev

# Re-merge only the branches that are still active
git merge feat/still-active-a --no-edit
git merge feat/still-active-b --no-edit
```

## Relationship to PRs

- PRs are opened from **feature branches to `main`**, not from dev.
- `dev` is for local/team integration testing only — it is not a PR target.
- Once a feature branch's PR is approved and merged to main, merge main back into dev.

## Tips

- Before merging a feature into dev, check for subset relationships. If branch A contains all of branch B's commits, you only need to merge A.
- Use `git merge-base --is-ancestor <branch-a> <branch-b>` to check if one branch is a subset of another.
- If two feature branches have the same fix as independent commits (cherry-picks or parallel implementations), pick one and only merge that branch. The duplicate will auto-resolve.
