# Scope Exception: ideas-txt-structured-replacement

## Exception: ideas.txt is gitignored, not tracked

The task specified deleting `ideas.txt`, but it is listed in `.gitignore` (line 18) and exists only as an untracked local file in the main worktree. It cannot be deleted via git commit — the user must delete it manually from their local filesystem.

## Exception: cannot modify .gitignore

The `.gitignore` entry for `ideas.txt` (line 18) should ideally be removed once the migration is complete, but `.gitignore` is outside the file scope constraint for this task.

## Action Taken

- Created `docs/working/ideas-backlog.md` with all 24 entries migrated from the local `ideas.txt`
- Marked 5 items as `done` (verified against git history), 3 as `stale`, 16 as `open`
- Did NOT delete `ideas.txt` (untracked file, not possible via git; user should delete manually)
- Did NOT modify `.gitignore` (out of file scope)
