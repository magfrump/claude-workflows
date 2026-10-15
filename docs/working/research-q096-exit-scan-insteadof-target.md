# Research: Q-096 — the exit scan follows insteadOf targets

**Goal**: The cc-isolated exit scan walks the URL a `url.<base>.insteadOf` / `pushInsteadOf` rule rewrites a remote to, so a session cannot repoint a push through a rewrite the scan ignores (closes Q-096).
**Problem framing**: The scan already walks each insteadOf *base* but never `<base><rest of the remote URL>`, the path git actually pushes to. Considered and discarded: "the scan must refuse any insteadOf rule in repo config", which would turn common, inert rewrites (`git@github.com:` for `https://github.com/`) into findings without a route to show for it.
**Project state**: one enforcement unit on `fix/q096-exit-scan-insteadof-target` · standalone (Q-097 follows on the same file) · not blocked (cite: docs/working/briefs/2026-10-02-exit-scan-insteadof-target.md)
**Task status**: complete (research done; plan in `plan-q096-exit-scan-insteadof-target.md`)

## What exists

- `devcontainer-config/cc-exit-scan.sh` (host tool, enforcement file). `git_exec_snapshot` walks every git dir it reaches; `_snap_config` reads one config (`git config --file --no-includes --null --list` from `/`) and, per key, follows hooksPath, includes, attributesFile, remote URLs (`_snap_remote`), and records remote names that may be paths (`_snap_names`/`_snap_nbases`, resolved after all configs are read in the closing `while` loop of `git_exec_snapshot`). For `url.*.insteadof|pushinsteadof` it calls `_snap_remote "<base>"` only (line ~420), plus a W record for a base of `""` or `.` (Q-094 R3/R4).
- `_snap_remote <url> [<wt>]`: drops `scheme://` (except `file://`) and ssh-style `host:path`; a relative path resolves in `<wt>`; walks `<p>` and `<p>.git` if inside the checkout (`_snap_inside_ws`, `realpath -m`), recording a missing target as `missing` so creating it later is a change. Adds a W record for a relative path (not `.`).
- `_snap_host_config`: your global/system config, includes evaluated per git dir; only hooksPath, attributesFile and includes are followed. URL rules there are not collected today.
- Legacy `remotes/*` (`URL:` lines) and `branches/*` (`<url>#<branch>`) are read in `_snap_gitdir` and passed to `_snap_remote`.
- Tests: `test/cc-isolated-functions.bats`, "exit scan N2" tests (~2093–2125) are the shape to follow (`scan_repo`, `plant_hook`, `git_exit_scan`, `no_ran`). Line ~2704 covers W records for `url...insteadOf` / `url..insteadOf`.
- Guide: `guides/cc-isolated-usage.md` "Known routes it does not see" has the bullet "A URL rewritten by `url.<base>.insteadOf`" (~line 410) and the follow list at ~line 320.

## Git's rule (remote.c, git 2.39; confirmed by experiment below)

- `alias_url(url, rewrites)`: among every `insteadOf` value that is a prefix of `url` (plain `starts_with`, case-sensitive; an empty value matches everything), the longest wins; the result is `<base>` + the rest of `url`. Applied once, never chained.
- `remote.<n>.pushurl` values are rewritten with `insteadOf`. When a remote has no pushurl, each `remote.<n>.url` is also rewritten with `pushInsteadOf` into an implicit pushurl. A remote name no remote defines (path-valued `branch.*.remote`, `pushRemote`, `remote.pushDefault`) and legacy remotes files go through the same aliasing (`add_url_alias`).
- Rules come from every config git reads for that command: system, global, the repo's config and its includes.

Experiment (`$SCRATCH/exp.sh`, `GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1`, git 2.39.5): a top-level `insteadOf` to `<ws>/t1-` ran `t1-repo`'s pre-receive; adding a longer prefix moved the push to the longer rule's target; `pushInsteadOf` ran its target's hook; `branch.main.pushRemote = alias/b` rewritten by `url.<ws>/br-.insteadOf alias/` ran `br-b`'s hook; with a `pushurl` set, its `insteadOf` target ran and its `pushInsteadOf` target did not.

## Invariants

- The scan runs nothing from the repo; config is read only by `git config --file --no-includes` from `/`.
- Fail closed: anything unreadable or too large makes the snapshot fail.
- Deterministic records: the same state yields the same sorted snapshot at launch and exit.
- Container-chosen strings reach the terminal only %q-quoted or through `_snap_fail`/`scan_vis`.
- W records refuse the standard-worktree note; a relative rewritten target must leave one (it resolves in a new worktree's tree).
- Records' format (F/C/W) and `scan_diff` stay unchanged.

## Prior art

The `_snap_names` loop: values only resolvable once every config is read are queued and resolved after the walk, with a growing index because walking can add more. The rewrite pass uses the same deferred, growing-worklist shape.

## Gotchas

- A rewritten target must not itself be rewritten (git does not chain); recording targets as URLs would also loop forever on a rule like `url.a.insteadOf ""`.
- Non-local URLs (`https://…`) must be collected too: they are what a rule rewrites into a local path. `_snap_remote` drops them, so collect before calling it.
- Rules found later (in a repo reached by walking a target) must also apply to URLs found earlier.
- URL × rule pairs are quadratic; a session can plant thousands of each. Needs a cap that fails closed.
- `git config --list` lowercases section and key but keeps the subsection (the base), so `${key#url.}` / `${t%.*}` give the base verbatim.

## Files read

Last verified: 2026-10-15
devcontainer-config/cc-exit-scan.sh
test/cc-isolated-functions.bats
guides/cc-isolated-usage.md
docs/working/briefs/2026-10-02-exit-scan-insteadof-target.md
docs/working/questions.md
docs/reviews/code-review-rubric-2026-09-28-q094-exit-scan-worktree-layout.md
docs/decisions/log.md
workflows/research-plan-implement.md
