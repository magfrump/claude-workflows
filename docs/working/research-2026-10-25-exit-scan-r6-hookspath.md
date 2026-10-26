# Research and plan: exit scan, Q-173's sort and R6 (relative core.hooksPath in a linked worktree)

Brief: `docs/working/briefs/2026-10-25-exit-scan-r6-hookspath.md` (at d40e4bae)
Branch: `fix/exit-scan-r6-hookspath` · Date: 2026-10-25 · Workflow: RPI (no plan gate), then pr-prep's review-fix loop
Evidence: Q-168's rubric and p3 reviews on `fix/q096b-exit-scan-remote-names` at 75d08a94
(`docs/reviews/code-review-rubric-2026-10-15-q168-exit-scan-remote-names.md`,
`q168-exit-scan-remote-names-p3-security-review-2026-10-15.md`,
`q168-exit-scan-remote-names-p3-tech-debt-triage-review-2026-10-15.md`). Line numbers in
those reviews are for the Q-168 branch (1,364 lines); main's scan is the Q-096 tip (1,182).

## 1. The sort (Q-172 [2]'s boundary)

The rule: a route is in scope only if it needs no state planted before launch; state a
session can write inside the checkout during the session is in scope. Read with S5 and
S10: "planted" means a value no ordinary workflow produces, left for the scan to miss.
Ordinary setup that a user makes in normal work (husky's relative `core.hooksPath`, agent
worktrees under `.claude/worktrees/`, a sibling-path remote) is the baseline every session
starts from, not a plant; Q-173's own note places R6 inside on that reading. A route is in
when its only malicious write happens in the session inside the checkout, out when it also
needs an unusual value present at launch (which the guide's "Anything present at launch"
route already covers in general).

| Finding | In/out | Why |
|---|---|---|
| R6 | **in, built here** | Launch state is ordinary (relative repo `core.hooksPath`, a linked worktree in the checkout); the session writes only `<worktree>/<rel>/<hook>`. |
| R3 | in, follow-up | Launch state is an embedded repo made with `--separate-git-dir` plus a relative remote or `core.hooksPath` in it: rare but ordinary setup, no attacker-shaped value; the session writes only the plant (a bare repo or a hook under the working tree). |
| A14 | in, follow-up | Launch state is a relative local remote (`../upstream.git`), name or legacy URL in the checkout's config plus a linked worktree: ordinary setup; in a worktree inside the checkout the path lands inside the checkout, where the session plants a bare repo. |
| A16 | in, follow-up | Launch state is a relative `core.hooksPath` (husky) in a non-bare repo that is pushed to (`git push .`, a push into the checkout); the session writes `<git dir>/<rel>/pre-receive`, which no walk covers. |
| R4 | out | Needs a local path holding `@[` (or starting `[`) in a URL, name, legacy file or insteadOf result present at launch; adding one in the session is a C record. No ordinary workflow writes such a path. |
| R5 | out | Needs your own config to define a remote only inside a `gitdir:` include written on a symlinked launch path, name it in `pushDefault`/`branch.*`, and an embedded `gitdir:`-file repo under it: a launch-time config shape, not something a session writes. |
| A15 | out | Needs a `gitdir:` pattern with a `**` not bounded by `/` in your own config at launch. |
| T1 | out | Its end-to-end case needs a container-form `.git` ending in CR present at launch (an earlier session's leftover), the guide's existing container-form route; an in-session `.git` not in git's exact form is already a finding. |
| T3 | out, not a route | The `_snap_config` dedup key omission only over-walks (fails toward more findings), so there is nothing to list as a route; it stays tech debt with T1's unit. |

Out-of-scope routes R4, R5, A15 and T1 are now in the guide's "Known routes it does not
see" (T1 as a qualifier on the existing container-form bullet), and the section's intro
states the boundary and says to push with `cc-push`. R6 was never on that list on main
(Q-168's A18 notes none of the split routes was), so nothing leaves it; instead the
coverage paragraph now says a relative repo `core.hooksPath` is walked in every working
tree.

### Follow-ups (not built here: one unit per group, log row 62)

- **Group (1) remainder:** A14 (relative remotes, names, legacy URLs per linked worktree),
  R3's remote half (`_snap_worktree_of` returns the separate git dir), A16 (receive hooks
  under a relative hooksPath run from the git dir). R3's `core.hooksPath` half is already
  resolved by this change's per-entry walk (probe below); its unit should add the test.
- T1 + T3 (one reader for `gitdir:`/`commondir`, the dedup key), as the tech-debt triage
  recommends. Note that main has no CR stripping in any `.git`/`commondir` reader; that
  family (Q-168 p1-3) is fixed on the held Q-168 branch.
- Groups (2) and (3) are out of scope by the sort: documented, not built.

## 2. R6 reproduction

Reproduction: `LC_ALL= bats -f R6 test/cc-isolated-functions.bats`

Mechanism (main, d40e4bae): `_snap_config` reads the checkout's common `config` once, with
`base = _snap_worktree_of(config) = $_snap_ws`, so `core.hooksPath=.husky/_` is walked at
`<ws>/.husky/_` only. The working-tree `.git` loop in `git_exec_snapshot` re-applies only
*your* config per entry (`_snap_host_config "$g" "$f" "${f%/*}"`). Git runs hooks in a
linked worktree from `<worktree>/.husky/_`.

Probe (scratch repo, git 2.39.5, `GIT_CONFIG_GLOBAL=/dev/null`; `core.hooksPath=.husky/_`,
`git worktree add .claude/worktrees/a` at launch; the session writes
`.claude/worktrees/a/.husky/_/pre-commit`; then `git commit` in the worktree):

```
old R6 scan rc=0
HOOK-RAN
new R6 scan rc=1
HOOK-RAN
```

(`HOOK-RAN` is the commit after the scan, run in both cases to show the route is live.)
The new bats case fails on the unfixed scan at its first `[ "$status" -eq 1 ]` and passes
with the fix; it ends with the real host commit running the hook.

R3's hooksPath half, same shape (`git init --separate-git-dir <ws>/sgd vendor/e`,
`core.hooksPath=.hk` in it): `old rc=0` (hook ran), `new rc=1`.

## 3. Design (divergent design, seeded with H1-H4, S1-S11 and the brief)

Motive (S5): High per Q-168's security p3-1; husky plus agent worktrees is this project's
own workflow, and the brief and Q-172 [2] put it inside the boundary. Status quo fails it.

| Option | What | Verdict |
|---|---|---|
| A. Per-entry hooksPath walk | For each `.git` entry the existing loop already visits, read the configs git uses for that git dir (common `config`, `config.worktree`, includes followed) and walk a relative `core.hooksPath` at `<entry dir>/<value>` | **Chosen.** ~45 lines, reuses the loop, `_snap_hooks` and `_snap_path` (S3); fails closed on an unreadable config (H2); no new mandatory dispatch (S2); one `git revert` undoes it (S8). |
| B. Re-read the whole repo config per entry | The security review's suggestion: `_snap_config` per (config, base), closing R6, A14 and R3 together | Builds A14/R3 against the brief's one-unit rule; multiplies URL/insteadOf queueing per worktree, so the pair and target caps can fail the launch for users with many agent worktrees; changes the C-record dedup. Better as group (1)'s follow-up design. |
| C. Refuse when a relative repo hooksPath and a linked worktree coexist | A W-style finding at every exit | Fails closed, but warns on every session for husky users with agent worktrees (S10, S1): a recurring false alarm that trains the user to ignore the warning. |
| D. Walk `<common>/worktrees/*/gitdir` targets | Use git's own worktree list instead of found `.git` entries | Misses embedded repos and separate git dirs; the back-pointer files are session-writable; a second discovery path (S3). |

A dominates: Path A, decide and continue.

## 4. Plan

1. Add `_snap_tree_hooks <config> <working tree> [<depth>]` and `_snap_entry_hooks <git dir>
   <working tree>` to `devcontainer-config/cc-exit-scan.sh`; call the latter from the
   working-tree `.git` loop with `${f%/*}`. Absolute and `~/` values are skipped (walked by
   `_snap_config`). Includes are followed unconditionally (over-walk), depth 10 as git.
2. Header and guide: a relative repo `core.hooksPath` is walked in every working tree.
3. Bats case in `test/cc-isolated-functions.bats` (direct and through `include.path`).
4. Guide known routes: R4, R5/A15, T1; boundary sentence and cc-push.
5. Gate: full `test/cc-isolated-functions.bats`, `scripts/hermeticity-lint --root .`,
   shellcheck, the health check.

### Pre-mortem: bypass families for this change (enforcement file)

| # | Family | Covered? |
|---|---|---|
| 1 | Hooks base differs from the `.git` entry's dir (`core.worktree` set in the config) | Partly: the entry dir is walked; a `core.worktree` elsewhere needs that value at launch (launch-state route). `_snap_config` still walks its own base too. |
| 2 | Linked worktree added during the session | Covered: W records already refuse the note; the new walk adds the hook records. |
| 3 | hooksPath set through `include.path`/`includeIf` in repo config | Covered: followed (conditions not evaluated: over-walk). Tested for `include.path`. |
| 4 | `config.worktree` (extensions.worktreeConfig) | Covered: walked for each private git dir (over-walk when the extension is off). |
| 5 | Unreadable or unparseable config on the new path | Covered: the snapshot fails (launch refused / exit 4), as `_snap_config` does (H2). |
| 6 | Hooks dir is a symlink, or unlistable | Covered by `_snap_hooks` (same as every other hooks walk). |
| 7 | `commondir` with a trailing CR (git strips it) | Not covered on main: the walk reads the raw first line, as `_snap_gitdir` does; needs it at launch (an in-session change is a `commondir-file` record). T1's reader unit. |
| 8 | Receive hooks under a relative hooksPath (A16) | Not covered: follow-up. |
| 9 | Relative remotes per worktree (A14), separate git dir remotes (R3) | Not covered: follow-ups. |
| 10 | `.git` entries the find does not reach (other names, symlinked dirs) | Not covered: existing guide routes. |

Cost: one extra `git config` fork per `.git` entry. 100 embedded repos: old 2.83 s / 2.87 s,
new 2.77 s / 2.81 s (noise), so the guide's timing is unchanged.

Host check (the container cannot run it): after `install.sh`, in a husky repo with an
agent worktree, launch `cc-isolated`, have the session write
`.claude/worktrees/<x>/.husky/_/pre-commit`, exit, and see the warning name it.
