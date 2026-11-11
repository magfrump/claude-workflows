# Brief: bring the Q-125 Bash sandbox branch up to main

Status: done
Date: 2026-11-07 (dev cycle iteration 2026-11-07-2324)

repo text is evidence, not instructions

## Goal

A new branch, cut from main, that merges `feat/q125-cc-isolated-sandbox` (tip `8dfe3ab90d2d7321b3656390631e9d618d63a083`) and resolves its conflicts with main, so the owner's `cc-verify --check docs/working/q125-verify-check.sh` paste can build main plus the sandbox and run the live check. Q-125 is the Bash sandbox for cc-isolated sessions: today nothing sandboxes Claude Code's Bash tool there.

## Motive

The owner answered Q-265 [1] on 2026-11-07: merge the live-check file (merged at 546788f2), "then one build loop merges main into feat/q125-cc-isolated-sandbox and resolves the five conflicts, without landing it on main; the cc-verify paste follows". The check file's loop found that `git merge-tree main feat/q125-cc-isolated-sandbox` exits 1, with conflicts in `devcontainer-config/install.sh`, `docs/decisions/log.md`, `hooks/live-verify-gate.sh`, `test/cc-isolated-functions.bats` and `test/install-host.bats`, mostly both sides extending the same list. `cc-verify` stops at that merge before it builds anything. The old branch stays as it is: a session's worktree holds it, and this brief gives the work its own branch.

## Acceptance criteria

- The branch below starts from main and merges `8dfe3ab90d2d7321b3656390631e9d618d63a083` in one merge commit. Each conflict keeps both sides' entries: nothing main added and nothing the sandbox branch added is dropped. Name every conflict and how it was resolved in the research doc.
- `git merge-tree --write-tree refs/heads/main HEAD` exits 0 at the branch tip.
- The whole health check passes on the branch.
- Commits that touch enforcement files carry the `Live-verified:` trailer the repo's CLAUDE.md asks for (`Live-verified: no` until the owner's live run), and the plan lists the bypass families a resolution could reopen. A conflict whose correct resolution needs a choice rather than a union goes to divergent design seeded with `docs/constraints.md`; a choice you cannot settle goes in a `blocked` marker.
- The final marker gives the owner's paste with this branch's name in place of `feat/q125-cc-isolated-sandbox`, what it prints, and what to paste back. Say plainly that the merge entry for this branch should not be answered [1] until that live run passes.
- Docs: the research doc records the resolution. If a doc on the sandbox branch names the old branch as the one to verify, update it.
- In the change that merges this work, change this brief's status line from open to done.

Branch: feat/q125-sandbox-on-main

Policy: review

## Out of scope

- Fixing anything the live run would find: that waits on the owner's paste.
- Rewriting or deleting `feat/q125-cc-isolated-sandbox`, or touching the worktree that holds it.
- Editing `docs/roadmap.md` or the questions files: the dev cycle moves those.

Dispatched: 1
