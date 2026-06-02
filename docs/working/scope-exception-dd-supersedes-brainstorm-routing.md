# Scope note: which CLAUDE.md is the in-scope routing surface

## Discovery

The file scope lists `/home/magfrump/.claude/CLAUDE.md` as editable. During implementation I found that path is a **symlink**:

```
/home/magfrump/.claude/CLAUDE.md -> /home/magfrump/claude-workflows/CLAUDE.md
```

`/home/magfrump/claude-workflows` is the **main checkout** of this same repo; this session runs in the worktree `/home/magfrump/wt-dd-supersedes-brainstorm-routing`, which has its own branch-tracked `CLAUDE.md` (content-identical to the symlink target).

## Why I edited the worktree `CLAUDE.md` rather than the symlink path

1. **Branch correctness.** Writing through the symlink modifies the *main* checkout's working tree as an uncommitted change on the wrong branch. The task requires committing and pushing the routing change on `feat/r1-dd-supersedes-brainstorm-routing` and using the final commit as the round summary — only the worktree-tracked `CLAUDE.md` is on this branch.
2. **Same logical file.** The worktree `CLAUDE.md` is the branch representation of the exact file the scope names (the symlink resolves to the repo's tracked `CLAUDE.md`). This is not an unlisted third file — it is the in-scope file accessed via the branch-correct path.
3. **Sensitive-file guard.** Direct edits to `/home/magfrump/.claude/CLAUDE.md` are blocked by the harness as a sensitive file and cannot be applied autonomously.

This is a path-resolution clarification, not a true scope expansion: the only routing surface modified is the repo-tracked `CLAUDE.md` decision tree that the scope intended.
