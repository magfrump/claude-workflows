# Research: bring the Q-125 Bash sandbox branch up to main

Brief: `docs/working/briefs/2026-11-07-q125-sandbox-on-main.md` (at f93c043c)
Branch: `feat/q125-sandbox-on-main`, cut at main f93c043c
Merged: `feat/q125-cc-isolated-sandbox` at 8dfe3ab90d2d7321b3656390631e9d618d63a083 (merge base 7ea99d96)
Date: 2026-11-07

Failure-pattern grep: FP-012, FP-015, FP-029, FP-145, FP-158 (keywords merge, conflict, payload, enforcement; none has this shape: every hit is a merge-tool or install-path failure, not two branches extending the same file list)

Failure-pattern skip: the branch's fix(...) commits (785a8104, 8dfe3ab9) come from feat/q125-cc-isolated-sandbox, where they were diagnosed and reviewed; this branch makes no new diagnosis and has no fix of its own

## What the merge is

The sandbox branch (Q-125: Claude Code's Bash sandbox in cc-isolated) adds three boundary files under `devcontainer-config/`: `seccomp-cc-sandbox.json`, `managed-settings.json` and `cc-sandbox-settings.sh`. It adds them to every list that names the boundary: `install.sh` PAYLOAD, `cc-isolated.sh` `enforcement_files()`, the `hooks/live-verify-gate.sh` regex, and the test fixtures that stub the payload. Since the merge base, main added `cc-verify.sh` (a host tool) to the same lists and split the host tools out of the gate's `enforcement` regex into their own `host_tools` regex with a `Host-tool-tested:` trailer (decision log row 71). Both sides also amended decision log row 53. So all five conflicts are two sides changing the same line.

`cc-isolated.sh`, `Dockerfile` and `devcontainer.json` merged without conflicts. I checked `enforcement_files()` after the merge: it lists the three new files, and `host_tool_files()` is main's four.

## Conflicts and how each was resolved

All five are resolved as unions. The script that did it is mechanical: it asserts that each conflict has the shape expected below and fails otherwise.

1. **`devcontainer-config/install.sh`, PAYLOAD.** Main added `cc-verify.sh`. The sandbox branch added the three new files after `Dockerfile`. Resolved: main's line with the three files inserted after `Dockerfile`. Result: `devcontainer.json Dockerfile seccomp-cc-sandbox.json managed-settings.json cc-sandbox-settings.sh init-firewall.sh cc-sni-proxy.py cc-isolated.sh cc-exit-scan.sh cc-gitdir.sh cc-push.sh cc-verify.sh link-claude-home.sh egress claude-home`.
2. **`test/cc-isolated-functions.bats`, two hunks** (`fake_install_repo`, `fake_payload_and_dest`). Same lists as PAYLOAD, resolved the same way: main's `cc-verify.sh` stays, and the three new files go after `Dockerfile`.
3. **`test/install-host.bats`, `fake_repo`.** Main added `cc-verify.sh`. The sandbox branch added the three files. Resolved: main's list with the three inserted after `Dockerfile`. Neither side lists `cc-push.sh` here, and that is left as it was.
4. **`hooks/live-verify-gate.sh`, the enforcement set.** This is the one conflict that is more than a list. Main replaced the single `enforcement` regex with `enforcement` (boundary files) plus `host_tools` (`cc-exit-scan.sh`, `cc-gitdir.sh`, `cc-push.sh`, `cc-verify.sh`), each needing its own trailer. The sandbox side, based on the older single regex, added the three new files to it. That regex still held the three older host tools. Resolved: main's structure kept whole, with the three new files added to main's `enforcement` regex (they are hashed by `enforcement_files()`, so they are boundary files, not host tools). The sandbox side's copies of `cc-exit-scan`, `cc-gitdir` and `cc-push` in `enforcement` are not carried over. They are still gated, through main's `host_tools` and its `Host-tool-tested:` trailer, which is what row 71 decided. Keeping them in `enforcement` as well would let a `Live-verified:` trailer satisfy a host-tool change, which row 71 removed. So the union is of what each side gates, not of the regex text. This is the only option that drops nothing either side gates and keeps row 71, so it needs no divergent design.
5. **`docs/decisions/log.md`, row 53.** Both sides appended amendments after the shared text that ends with "its removal is Q-092." Main added the 2026-10-15 (Q-092) and 2026-10-20 (Q-176, Q-177) amendments. The sandbox branch added the 2026-10-07 (Q-124 [1], Q-125) amendment. Resolved: all three amendments, in date order (10-07, 10-15, 10-20). One sentence existed in two wordings: "The sandbox half of Q-070 [1] is not built: … (Q-081)". The sandbox side kept it before its amendment. Main rewrote it and moved it into the 10-15 amendment ("first asked as Q-081 (answered) and now built but unmerged as Q-125"). Main's newer wording is kept, and the older duplicate is not. The amendments' text is unchanged. One known inconsistency is left as history: the 10-07 amendment says the hook's deny check "is no longer the only line" once live-verified, but the 10-15 amendment removed that deny check. Amendments record what was true when they were written, so this needs no rewrite. A post-live-run amendment can say it.

## Bypass families a resolution could reopen (pre-mortem for the enforcement-file change)

| Family | How a wrong resolution reopens it | Guard on this branch |
|---|---|---|
| Ungated boundary file | One of the three new files missing from the gate's `enforcement` regex: a commit changing the sandbox's seccomp profile or managed settings needs no `Live-verified:` | The three are in main's `enforcement` regex. The bats test that pins the gate against `enforcement_files()` / `host_tool_files()` in both directions passes |
| Installed but unhashed | A file in PAYLOAD but not in `enforcement_files()` ∪ `host_tool_files()`, so nobody blessed it | `enforcement_files()` auto-merged with the three. The PAYLOAD ⊆ hashed-set bats test passes |
| Hashed but not installed | A file in `enforcement_files()` but missing from PAYLOAD: the launcher refuses ("enforcement file missing") or blesses a stale copy | PAYLOAD holds all three. `install.sh` fails closed on a missing source (FP-158) |
| Trailer confusion | Host tools left in `enforcement` as well: a `Live-verified:` trailer would satisfy a host-tool change, reopening what row 71 closed | Host tools are only in `host_tools` |
| Lost host tool | `cc-verify.sh` dropped (taking the sandbox side's list): the host tool stops being installed and gated | `cc-verify.sh` is kept in every list |
| Lost record | A row-53 amendment dropped: its residuals and live-run unknowns are no longer on record | All three amendments are present |

## Other choices (one-line notes; none has 3+ viable options)

- One merge commit, from main into this branch, with the conflicts resolved in it, as the brief asks. A rebase or squash is ruled out because it would rewrite the sandbox history the old branch keeps.
- `docs/working/q125-verify-check.sh` (on main) names `feat/q125-cc-isolated-sandbox` in its RUN line as the branch to verify. Updated to `feat/q125-sandbox-on-main`, as the brief's Docs item asks. Comment-only.
- `docs/working/checkpoint-q125-cc-isolated-sandbox.md` (from the sandbox branch) gets a one-line note that the live run now verifies this branch. Its historical Branch line stays.
- `docs/working/probe-q125-bwrap.sh` defaults to the old branch. That probe already ran (Q-126 passed), and it checks the host kernel rather than this branch's files, so it is left unchanged.
- Decision-log rows and closed briefs that name the old branch are history and are left unchanged.

## Verification

- `git merge-tree --write-tree refs/heads/main HEAD` exits 0 at the tip (recorded in the marker).
- Affected suites, then the whole `scripts/health-check.sh` (results below).
- Live: not run. This sandbox has no Docker. `Live-verified: no` until the owner's cc-verify paste.

## Results

- Affected suites on the merge (cc-isolated-functions, install-host, hooks/live-verify-gate, seccomp-cc-sandbox, cc-sandbox-settings, q125-verify-check, cc-verify): 387/387 pass.
- First full `scripts/health-check.sh`: failed on two things main added since the sandbox branch was cut. The two sandbox suites had no `# @category` tag, and SC2088 fired on a deliberately literal `'~/.elan/bin'` in cc-sandbox-settings.bats. Fixed in 1c6a3652 (both tagged `fast`, about 10 s together; SC2088 disabled on that one line). Rerun at 1c6a3652: exit 0, "All checks passed."
- `git merge-tree --write-tree refs/heads/main HEAD`: exit 0.
- Independent review (one reviewer, given the code rather than this doc): 0 Critical/High/Medium, 5 Low. Fixed: the wrong merge-base hash here, the guide's enforcement-file list missing the three sandbox files (`guides/devcontainer-setup.md`), and this section and the skip line not yet committed. Left for later: row 53's "built but unmerged as Q-125" and its Q-126/Q-127 and deny-check sentences, which a post-live-run amendment should settle. Also, main's copy of `q125-verify-check.sh` still names the old branch, so the owner's paste must name this branch explicitly (it does).
