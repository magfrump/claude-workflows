# Research and plan: exit scan, Q-173 group 1 remainder (A14, R3's remote half, A16)

Brief: `docs/working/briefs/2026-10-28-exit-scan-group1-remainder.md` (at 4b04a1eb)
Branch: `fix/exit-scan-group1-remainder` · Date: 2026-10-28 · Workflow: RPI (no plan gate), then pr-prep's review-fix loop
Prior art: `docs/working/research-2026-10-25-exit-scan-r6-hookspath.md` (the sort, section 1;
option B, section 3; the follow-ups). Scope stays inside the sort: all three routes need
only ordinary launch state (a sibling-path remote, husky, agent worktrees, an embedded
repo made with `--separate-git-dir`) plus a plant the session writes in the checkout.

## 1. Reproduction and git's behaviour

Reproduction: `LC_ALL= bats -f 'A14|R3:|A16' test/cc-isolated-functions.bats` (the new
cases, run against main's `cc-exit-scan.sh` at 4b04a1eb: each fails at its first
`[ "$status" -eq 1 ]`, i.e. main's scan returns 0; on this branch each passes and ends
with host git running the planted hook).

Probe (scratch repo, git 2.39.5, `GIT_CONFIG_GLOBAL=/dev/null`), confirming where git
resolves each value:

| Route | Launch state | Session plant | Git runs |
|---|---|---|---|
| A14 URL | `remote.up.url=../up.git`, a linked worktree `<ws>/agents/wt/a` | bare repo at `<ws>/agents/wt/up.git` | its `post-receive` on `git push up` from the worktree (cwd = that repo) |
| A14 name | `remote.pushDefault=../pd.git` (no such remote) | `<ws>/agents/wt/pd.git` | its hook on `git push` from the worktree |
| A14 legacy | `.git/remotes/old` = `URL: ../leg.git` | `<ws>/agents/wt/leg.git` | its hook on `git push old` |
| R3 remote | `git init --separate-git-dir <ws>/sgd vendor/e` (no `core.worktree` is written), `remote.o.url=./r3.git` | `vendor/e/r3.git` | its hook; main walked `<ws>/sgd/r3.git` |
| A16 | `core.hooksPath=.husky/_` | `<ws>/.git/.husky/_/pre-receive` | it, on `git push .` or a push into `<ws>` (receive-pack cwd = `<ws>/.git`) |
| A16, worktree | same, plus a linked worktree | `<ws>/.git/worktrees/a/.husky/_/pre-receive` | it, on `git push .` from the worktree or a push to the worktree's path (cwd = the private git dir) |
| A16, sgd | embedded `--separate-git-dir` repo with `core.hooksPath=.hk` | `<ws>/sgd/.hk/pre-receive` | it, on a push into `vendor/e` |

## 2. Design (divergent design, seeded with H1-H4, S1-S11 and the brief)

Motive (S5): the brief and Q-172 [2] put the three routes inside the boundary; agent
worktrees plus a sibling remote or husky is this project's own workflow. Status quo leaves
three listed live routes. The brief's binding extra constraint: the insteadOf pair and
target caps (H2: over a cap the launch is refused) must not fail a launch for a user with
many agent worktrees.

| Option | What | H1-H4 | Soft | Verdict |
|---|---|---|---|---|
| A. Per-entry relative values only | Extend R6's cached per-config reader to collect the *relative* remote values (URLs, names that may be paths, legacy URLs); for each `.git` entry queue them with the entry's working tree as base. A16: walk relative hooksPath values in every git dir `_snap_gitdir` walks. R3 falls out of A (a separate git dir's `.git` file is an entry) | pass: same fail-closed reads; hermetic tests | S3 reuses the R6 cache and `_snap_url`; S8 about 90 code lines; per-tree URL count grows only by relative remotes | **Chosen** |
| B. Re-read the whole repo config per entry (`_snap_config` per (config, base)) | The pass-2 security suggestion | pass | Every absolute URL is queued once per tree (the pair key includes the base): 500 worktrees x 3 URLs x 50 rules = 75,000 pairs, and a rule matching origin makes 500 targets per URL, so the 2,000-target cap refuses the launch: violates the brief's cap constraint (H2 makes it a refusal). Duplicates C records. | Rejected |
| C. B with absolute URLs deduplicated | B, but key absolute URLs without the base | pass | Still re-reads and re-records every config per tree (C-record dedup by real path then hides the second read, or it double-records); more code than A for the same coverage | Dominated by A |
| D. Fix `_snap_worktree_of` for R3 only, and a W-style refusal for A14/A16 | Find the `.git` file that points at a separate git dir; warn when relative remotes and worktrees coexist | pass | A warning at every exit for users with a sibling remote and agent worktrees (S10, S1: trains the user to ignore it); a reverse lookup is a second discovery path (S3) | Rejected |

A dominates (Path A): decide and continue.

Cap arithmetic under A: pairs = (URLs) x (rules), where URLs = absolute remotes once +
relative remotes x (entries + 1). A user with 500 agent worktrees, one relative remote and
50 rules: about 25,000 pairs (cap 100,000). Targets grow per tree only when a rule's
value prefixes a relative path (no ordinary rule does). The new cap case pins this at a
small scale with lowered caps: 20 worktrees, 10 rules: 220 pairs, 1 target, passing at
caps 300 and 5 where B would need 420 and 21; and at 200 the cap is shown live.

## 3. Plan (as built)

1. `devcontainer-config/cc-exit-scan.sh`:
   - `_snap_relurl <value>`: `_snap_remote`'s local-path rule, relative only, `.` excluded
     (the repository git runs in: its receive hooks are A16's walk of its git dir).
   - `_snap_cfg_hooks(_file)`: also collect relative `remote.*.url`/`pushurl` ("u") and
     `remote.pushDefault`/`branch.*.remote`/`pushRemote` ("n") values, cached per config
     with the hooksPath values.
   - `_snap_legacy_body` (one parser for the legacy grammar, used by `_snap_gitdir` and
     `_snap_legacy`) and `_snap_legacy <git dir>` (cached relative legacy URLs).
   - `_snap_entry_hooks <g> <wt> [hooks-only]`: per entry, queue the relative URLs with
     `_snap_url`, names into `_snap_names` (resolved against defined names at the end,
     as before), legacy URLs; ranges copied to locals because each walk recurses.
   - `_snap_gitdir`: `_snap_entry_hooks "$real" "$real" hooks-only` (A16).
2. Bats: A14 (URL, `pushRemote` name, legacy), R3 (remote half alone, then the hooksPath
   half), A16 (checkout git dir and a worktree's private git dir), the cap case.
3. Guide: coverage paragraph says what is now walked; the "not closed yet" bullet is
   dropped; the `core.worktree` bullet now covers remotes too.

### Pre-mortem: bypass families (enforcement file)

| # | Family | Covered? |
|---|---|---|
| 1 | Relative URL / pushurl in the common config or an include of it, per linked worktree or `.git` entry | Covered (A14 case) |
| 2 | Relative undefined remote name (`pushDefault`, `branch.*.remote`/`pushRemote`) | Covered (A14 case); a name defined only in another repo of the checkout still counts as defined: existing loosely-read bullet |
| 3 | Legacy `remotes/`/`branches/` relative URL in the common dir | Covered (A14 case); loosely-read grammar unchanged (existing bullet) |
| 4 | Remote values in `config.worktree` (per-worktree) | Covered: read for each private git dir, as R6 does for hooksPath |
| 5 | Separate git dir: remote resolved in the git dir instead of the working tree (R3) | Covered (R3 case); the old git-dir resolution is still walked too (over-walk) |
| 6 | Receive hooks under a relative hooksPath, checkout / linked worktree / embedded / bare remote | Covered: every git dir `_snap_gitdir` walks (A16 case for the first two; bare was already covered) |
| 7 | A relative URL rewritten by an `insteadOf` rule | Covered: per-entry URLs go through `_snap_url`, so they meet every rule |
| 8 | A relative remote *added* in the session, or a new worktree | Already a finding: C records and W records refuse the note |
| 9 | A `core.worktree` elsewhere for the checkout or a linked worktree | Not covered, launch-state: existing guide bullet, extended to remotes |
| 10 | Absolute values queued per tree to exhaust the caps (availability) | Avoided by design: only relative values are per tree; pinned by the cap case |
| 11 | A container-form `.git` (path under `/workspace`) | Covered for hooksPath and remotes once repaired: the entry loop already passes the host twin; the common dir's config is read by `gitdir_common` |
| 12 | An empty or unreadable `commondir` in any walked git dir | Fails the snapshot (H2); git dies there too. Wider than before (R6 failed only for `.git` entries): availability, never a false clean |
| 13 | `.git` entries the find does not reach (other names, symlinked dirs) | Not covered: existing guide routes |

## 4. Cost

Harness (`perf.sh` in the scratchpad: 100 embedded repos each with a relative remote,
20 linked worktrees, husky hooksPath and a relative remote in the checkout), host load 5-11
from other sessions, so noisy: main 4.7-6.6 s (median about 5.25 s), this branch 5.6-7.9 s
(median about 6.1 s) per snapshot: about 7 ms more per entry (one `gitdir_common`, one
legacy-dir check, a walk of each relative remote). The guide's "about 30 ms more for each
embedded repository or linked worktree" stays an honest figure.

## 5. Size

Diff before review: about 240 lines added across three files (code about 95, tests about
115, guide), under the row 62 cap; no split.

## Host check (the container cannot run it)

After `install.sh`, in a repo with `remote.up.url=../up.git` and an agent worktree,
launch `cc-isolated`, have the session `git init --bare .claude/worktrees/up.git` and add
a `post-receive`, exit, and see the warning name it.
