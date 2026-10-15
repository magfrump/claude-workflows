Commit: 03bc47c9

# Security Review — Q-096 exit scan, insteadOf targets (final confirming pass, full branch)

**Scope:** `git diff main...03bc47c9 -- . ':!docs/reviews'` on `fix/q096-exit-scan-insteadof-target` (five commits, 5f754994..03bc47c9). I read the whole post-change `devcontainer-config/cc-exit-scan.sh` (1-1181), plus the launcher's snapshot and exit-scan call sites (`cc-isolated.sh:850-940`) and the guide's scan and known-routes sections (`guides/cc-isolated-usage.md:300-470`).
**Date:** 2026-10-15
**Based on:** shared brief (final); prior security reports p1-p3 (advisory). The orchestrator supplied the goal preamble.

> ⚠️ **No code fact-check report provided for this pass.** Claims about security properties in comments and documentation have not been independently verified by code-fact-check. I checked the security-relevant ones myself, by experiment where marked.

Probes are in `/home/node/.claude/jobs/00bcf178/tmp/q096/probe-security-final/` (`common.sh`, `e1.sh`, `e1b.sh`, `e2.sh`, `e3.sh`). Each sets `HOME`, `GIT_CONFIG_GLOBAL` (a file in the probe dir) and `GIT_CONFIG_NOSYSTEM=1`, and sources either the branch's scan or main's (`main-scan.sh`, extracted with `git show main:`). Every hook writes only to `$P/marker`. Each run was in the foreground under `timeout 300` and exited. Afterwards `ps` showed no probe or bats process. `LC_ALL=C bats -f 'Q-096' test/cc-isolated-functions.bats`: 11/11 ok.

## Trust Boundary Map

```
B1: [checkout .git configs, legacy remote files, embedded / walked-remote / rewritten-target repo configs (container-writable)] → [_snap_config, _snap_gitdir → _snap_url, _snap_rule (_snap_key byte cap, u:/r: dedupe)] → [insteadOf worklist queues]
B2: [your global/system config + includes (host-owned)]          → [_snap_host_config → _snap_rule, _snap_url]                                  → [insteadOf worklist queues]
B3: [queued URL × queued rule]                                    → [_snap_pairs_ok, _snap_match (LC_ALL=C prefix test, per-hit target cap)]      → [_snap_hit_t / _snap_hit_b]
B4: [rewritten target string + filesystem at that path (S3)]      → [_snap_walk_hits (t: dedupe) → _snap_remote (scheme/ssh test, base join, inside-ws, .git/HEAD test)] → [git dir walked, F/C/W records]
B5: [snapshot success / failure]                                  → [git_exec_snapshot rc → git_exit_scan (0/1/2) → launcher]                    → [exit 0/3/4; launch refused, exit 1]
```

| Label | Source | Mutability | Trust (per sink) |
|---|---|---|---|
| S1 | repo config entries (`remote.*.url`/`pushurl`, `url.*.insteadOf`/`pushInsteadOf`, remote names) in any config the scan reads inside the checkout | runtime-mutable (the session writes it) | UNTRUSTED for path construction, walk decisions and cost. A change is itself a finding (C/F records), so a bypass needs launch-time config plus a plant at a path the scan does not compute or follow |
| S2 | your global/system config | deploy-time for the session (container cannot write) | trusted not to be hostile; still feeds path construction (its rules and remote URLs can point into the checkout) |
| S3 | filesystem state at rewritten targets (planted repos, gitfiles, hooks) | runtime-mutable | UNTRUSTED for everything; what the scan must record or follow |
| S4 | `GIT_EXIT_SCAN_MAX_REWRITE_*` | code-constant | trusted |

The branch adds B3 and the B4 path for rewritten targets, and it widens B2: your own rules and remote URLs now feed the worklist. Container strings from S1 and S2 are keyed, capped and batched, then turned into paths in `_snap_remote`. Whether a target is walked, and how far, depends on the S3 state at that path.

## Findings

#### 1. A `gitdir:` file at a rewritten (or plain local) remote path is not followed; a repo planted where it points runs its hooks on push with no finding

**Severity:** Medium (floor rule: a concrete, experiment-confirmed mechanism). **Pre-existing on main** for plain local remotes. The branch extends the scan to rewritten targets and inherits the gap there. It does not widen it relative to main, because main did not walk rewritten targets at all.
**Location:** `devcontainer-config/cc-exit-scan.sh:378-387` (`_snap_remote`, the per-candidate walk)
**Boundary:** B4
**Move:** 11 (bypass enumeration), 2 (implicit assumption: "a remote path is a repo dir or holds `.git`")
**Confidence:** High that the mechanism works (e1, e1b: real `git push` ran the planted hook). Low-to-medium on likelihood, because the gitfile must already be at the remote path at launch: a session that creates it is reported (the path's F record changes).
**Legibility-target:** the guide's "Known routes it does not see" list (`guides/cc-isolated-usage.md:396-470`), the one place the header's LIMITS points to.

Evidence (the complete per-candidate loop; the function ends at `:388` with `}`):
```
  for c in "$p" "$p.git"; do
    _snap_inside_ws "$c" || continue
    _snap_file remote "$c" || return 1
    [ -z "$_snap_linkdir" ] || c="$_snap_linkdir"
    if [ -e "$c/.git" ] || [ -L "$c/.git" ]; then
      _snap_dotgit "$c/.git" || return 1
    elif [ -e "$c/HEAD" ]; then
      _snap_gitdir "$c" || return 1
    fi
  done
```
When `$c` is a regular file, `_snap_file` records its hash and nothing follows it. git's `enter_repo` accepts a regular file at `<p>` (suffix `""`) and follows it with `read_gitfile`. e1 (branch): remote `o` = `https://o.invalid/r`, rule `url.<ws>/m-.insteadOf = https://o.invalid/`, and at launch `<ws>/m-r` holds `gitdir: <ws>/hidden/evil.git` (missing). Then a bare repo with a `pre-receive` hook was planted at `<ws>/hidden/evil.git`:
```
records naming m-r: 2
scan rc=0
marker: HOOKRAN
```
e1b used the same gitfile behind a plain `remote.o.url = <ws>/m-r`, with no rewrite. Both branch and main print `scan rc=0` / `marker: HOOKRAN`. The embedded-repo search does not find `hidden/evil.git`, because it is not named `.git`. The guide's "A repository in a working-tree directory not named `.git`" bullet covers running git *inside* such a directory, not pushing to it through a gitfile.

**Recommendation:** This is not a regression and should not block Q-096. Route it to a follow-up (it fits next to Q-097 on the same file): in `_snap_remote`, when `$c` is a regular file, follow it the way `_snap_dotgit` does (`_snap_dotgit "$c"` already records the file and walks its `gitdir:` target). Until then, add a known-route line: "a local remote path (or rewritten target) that is a `gitdir:` file present at launch".

#### 2. A relative `remote.*.url` in your own config now adds W records, which refuse the linked-worktree note; the guide and header do not say so

**Severity:** Informational (fail-closed direction: more warnings, never fewer)
**Location:** `devcontainer-config/cc-exit-scan.sh:617` → `:417` → `:376`; `guides/cc-isolated-usage.md:375-379`; header `:86-94`
**Boundary:** B2
**Move:** 5 (what the rule does not cover, inverted: what it now refuses)
**Confidence:** High (read-static: the full `_snap_host_config`, `_snap_url` and `_snap_remote` functions)
**Legibility-target:** the guide's "Linked worktrees left behind" paragraph, so a user can tell why adding a worktree always warns

Evidence:
```
      remote.*.url|remote.*.pushurl) _snap_url "$val" "$wt" || return 1 ;;
  _snap_remote "$1" "$2"
  [ "$p" = . ] || _snap_wrel remote "$p" "$p"
```
The guide lists which settings refuse the note: "a relative local remote" in the checkout's config, "an `insteadOf` base of `.` or `""`", and "a remote any `insteadOf` rule, yours included, rewrites to a relative path". It does not list a relative remote URL in your own global config, which the branch now walks and which therefore emits a W record in every snapshot. The effect is safe (git would resolve that URL in the new worktree, so refusing the note is correct). Only the documented list is incomplete.

**Recommendation:** Add "or a relative remote URL in your own config" to the guide's parenthesis and to the header's STANDARD WORKTREES list.

## Untested bypass candidates

- **Many embedded repos multiplying your own remote URLs into the pair cap.** `_snap_host_config` runs once per embedded repo and queues each of your remote URLs once per working tree (key = URL + working tree). A session that plants N embedded repos makes H×N URLs, and each meets every rule. This can push the exit scan over the 100,000-pair cap, giving exit 4. That direction is fail-closed (a visible "treat the checkout as unsafe"), so it is DoS, not a bypass. Not timed. Its benign side (a launch refused on a checkout with very many embedded repos and several of your own remotes and rules) is a performance and usability question, not a security one.
- **Per-entry base walks without dedupe** (`_snap_config:522`: `_snap_remote "$t"` runs for every insteadOf entry even when `_snap_rule` deduped it). This is a pre-existing stall shape that main has too. Override-log row 134 defers it. Not timed.

## Tested bypass candidates (no finding)

| Candidate | How | Result |
|---|---|---|
| A remote name defined only in a rewritten target's config hiding the checkout's path-valued `pushRemote` (would make the split-out family worse than main) | e2, run against the branch and against main | **Not a route.** Branch: `scan rc=1`, `~ remote <ws>/evilname dir 755`, `+ hook …/evilname/hooks/pre-receive`. The worklist loop handles names first (`:836-840`), and rewritten targets are walked only later, in `_snap_walk_hits`. So a target's config cannot mark a checkout name as defined before that name is resolved. Main gives the same rc=1. Not worse than main. |
| A rule base ending mid-character under `LC_ALL=C.utf8` (`url.<ws>/x\xc3.insteadOf = gh:`, remote `gh:\xa9r`) | e3 | Caught: `+ hooksdir <ws>/x??r/hooks`, rc=1. The `${rec%%$'\n'*}` / `${t%.*}` splits in `_snap_config` keep the byte (bash falls back to byte matching on invalid sequences) |
| Pair accounting with URLs and rules found mid-walk | read `:834-856` (whole loop) | Each pair meets once. URL i compares with rules `0..R_i-1`. A rule j ≥ R_i is processed after `u` has passed i, so it compares with URL i then |
| `_snap_match` / `_snap_walk_hits` failing open | read both functions whole | Only the cap branch returns 1, and it prints a reason first. `_snap_remote` failures propagate. `&& … \|\| rc=1` ends the loop. Launcher: snapshot failure at launch gives exit 1, `git_exit_scan` 2 gives exit 4 (`cc-isolated.sh:859-866,932-937`) |
| `~/…` rewritten target | guide `:452-456` | Listed known route ("a `~` in a local remote URL (or one an `insteadOf` rule rewrites to)") |
| `file://host/` or percent-encoded target | guide `:421-427` | Split-out family, listed. The branch adds no new resolution path for it |
| `://` after a non-scheme character, `ext::` / `<scheme>::` helper targets | read `_snap_remote:367-373` against git's `transport_get` / `parse_connect_url` (p3 e1 executed the `://` case) | git refuses `<non-scheme>://`. `ext::` is a helper (protocol.allow-gated), not a local repo, so it falls outside what this walk is for |
| A target that is a plain dir at launch and is given HEAD/hooks during the session | read `:378-387` | The exit walk adds config, hooksdir and hook records, so the change shows up as `+` lines |
| A FIFO at a target, its `.git` or its HEAD | read `_snap_file`, `_snap_dotgit_target`, `_snap_gitdir` | Every read is gated by `-f`. Neither stat nor `-e` opens the FIFO |
| Terminal escapes in the new messages | read `:406-407,433-434,450-451`; scan_vis `:889-891` | The new messages print only numbers. Paths go through `%q` and `scan_vis`, or through `_snap_fail`'s `tr -c '[:print:]'` |
| Key collision across namespaces / metacharacters | p3 e2 (executed), unchanged since | Holds |

## Endorsement Claims

- **Claim:** A launch-time rule rewriting a remote to an in-checkout path is reported when a session plants a repo there, also when the rule base ends mid-UTF-8-character in a UTF-8 locale.
  **Location:** `devcontainer-config/cc-exit-scan.sh:487-522,444-471`
  **Evidence:** executed
  **Verified:** e3, plus bats Q-096 tests 1-11 (11/11 ok, LC_ALL=C runner).
  **Not verified:** a host bash other than 5.2, or git other than 2.39.5 (the commit's own `Host-tool-tested: no`).
  **route: code-fact-check**
- **Claim:** A name defined only in a rewritten target's config does not hide the checkout's path-valued pushRemote of that name.
  **Location:** `devcontainer-config/cc-exit-scan.sh:834-856`
  **Evidence:** executed
  **Verified:** e2 on the branch and on main (both rc=1, hook named).
  **Not verified:** names queued from configs walked inside the loop (they belong to repos host git does not push from; not exercised).
- **Claim:** Every failure inside the insteadOf pass reaches a non-zero snapshot status and the launcher's exit 1 (launch) / exit 4 (exit).
  **Location:** `devcontainer-config/cc-exit-scan.sh:835-858`; `cc-isolated.sh:859-866,932-937`
  **Evidence:** read-static (bats test 11 executes the exit-side cap paths)
  **Verified:** the whole loop and both launcher call sites read; bats test 11 shows status 2 for each cap.
  **Not verified:** the launch-side refusal under a cap (no test drives `main` that far).
  **route: code-fact-check**

## Primitive sweep

Primitive: path construction from container strings → `_snap_remote` walk (filesystem traversal decision)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `cc-exit-scan.sh:417` `_snap_url` → `_snap_remote` | S1, S2 | `u:` key, byte cap | cleared for keying. Gitfile at the path: Finding 1 |
| `cc-exit-scan.sh:469` `_snap_walk_hits` → `_snap_remote` | S1, S2, S3 | `t:` key, per-hit target cap | cleared for matching (e3, bats). Gitfile at the target: Finding 1 (e1) |
| `cc-exit-scan.sh:522` rule base → `_snap_remote` | S1 | byte cap (via `_snap_rule`) | cleared. Per-entry walk cost is pre-existing (untested list) |
| `cc-exit-scan.sh:617` your remote URL → `_snap_url` | S2 | byte cap | cleared. W record: Finding 2 |
| `cc-exit-scan.sh:840` undefined name → `_snap_url` | S1 | `_snap_rnames` (main's rule) | split family. Not worsened (e2) |
| `cc-exit-scan.sh:731,734` legacy URL → `_snap_url` | S1 | byte cap | split family, listed in the guide |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | A `gitdir:` file at a (rewritten or plain) local remote path is not followed; planted repo's hook runs, scan clean. Pre-existing on main; not a regression | Medium | B4 | `cc-exit-scan.sh:378-387` | High mechanism (e1, e1b); low-medium likelihood (needs launch-time gitfile) |
| 2 | Your own relative remote URL now refuses the worktree note; guide/header lists omit it (fail-closed) | Informational | B2 | `cc-exit-scan.sh:617,376`; guide `:375-379` | High (read) |

## Overall Assessment

The insteadOf mechanism the branch adds holds up. Every (URL, rule) pair meets once, including URLs and rules found mid-walk. Matching and cutting are byte-wise in a UTF-8 locale, also for the rule base (e3). Every cap and every failure fails closed, through to the launcher's exit 1 or exit 4. The new messages carry no container bytes to the terminal. The worry that walking rewritten targets would let their configs hide a checkout remote name, making the split-out family worse than main, does not hold: names are resolved before any target is walked (e2). I found one route that ends at a rewritten target: a `gitdir:` file present at launch at the remote path, pointing at a repo the session plants (Finding 1). It is not caused by this branch. Main has the same gap for every plain local remote (e1b), and main did not walk rewritten targets at all. So it does not block a 0-red/0-unresolved-amber merge of Q-096 as long as it is either listed as a known route or queued as its own fix. That disposition is the single most important item. Finding 2 is a one-line documentation addition. Within the code paths read and the probes run, there are no findings that block this unit. The endorsement claims marked read-static are pending execution verification.

## Goal-Alignment Note

The user's goal is that a session cannot repoint a host push through an `insteadOf`/`pushInsteadOf` rewrite the scan ignores. At 03bc47c9 the scan no longer ignores rewrites. Every matching rule's target is walked under bounded, fail-closed caps, and the probes and the 11 Q-096 bats tests confirm it. The one confirmed push route that ends at a rewritten target (Finding 1) goes through a gitfile at the end of the path, not through the rewrite. It already exists for plain local remotes on main, so it belongs to a follow-up on `_snap_remote` (next to Q-097), not to this unit. Landing Q-096 with Finding 1 listed or queued, and Finding 2's sentence added, serves the goal without another code round.
