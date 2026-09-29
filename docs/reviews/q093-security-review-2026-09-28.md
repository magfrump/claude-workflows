# Security Review — branch q093-cc-push-self-commondir

Commit: 2c8163f
**Scope:** `git diff dfe4c0d..HEAD` (cc-push.sh `commondir_is_self` + `check_checkout`, cc-isolated-usage.md, test/cc-push.bats, plan doc); context read in full: `check_checkout`, `find_checkout`, `check_no_container`, `safe_path`, `main`'s check order (cc-push.sh), all of `devcontainer-config/cc-gitdir.sh`, the commondir paths of `cc-exit-scan.sh`.
**Date:** 2026-09-28
**Based on:** orchestrator's Stage-1 code-fact-check summary (dispatch preamble), plan `docs/working/plan-q093-cc-push-self-commondir.md`

## Trust Boundary Map

```
B1 (modified): [session-written .git/commondir: type + bytes] → [commondir_is_self in check_checkout] → [host git-upload-pack --strict resolving the common dir]
B2:            [session-written .git/* other files]           → [find -P scan, include/promisor grep, gitdir_valid, looks_like_gitdir] → [upload-pack reads refs/objects/config]
B3:            [container liveness between check and fetch]    → [check_no_container (docker ps), --allow-running override] → [fetch runs on what was checked]
B4:            [host $PATH]                                     → [safe_path (absolute, not inside checkout)] → [exec of stat / head / od in the helper]
```

Input sources:

```
S1: <co>/.git/commondir (type, size, bytes) — request-time (session writes it while the container runs) — UNTRUSTED for path-resolution / file-read sinks
S2: <co>/.git/* other entries               — request-time — UNTRUSTED (all sinks); unchanged by this diff
S3: host $PATH after safe_path              — deploy-time (user's env) — trusted for exec of coreutils
S4: docker ps result                        — host-authoritative — trusted for the "container stopped" availability decision; overridable by --allow-running
S5: git 2.39.5 setup.c get_common_dir_noenv — code-constant (external) — trusted; behaviour verified empirically by Stage 1
```

The diff narrows B1 from "refuse any commondir" to "refuse any commondir except a regular, non-symlink, 1-2-byte file whose bytes are `2e` or `2e0a`". Everything downstream of B1 (B2 checks, gitdir_valid, looks_like_gitdir) is unchanged and still runs after the helper. The attacker model (session writes anything in the checkout; container stopped before cc-push) is unchanged; the relaxation is sound only if a `.`/`.\n` commondir makes git read exactly what it reads with no commondir.

## Bypass enumeration (move #11) — `commondir_is_self`

Probe: `commondir_is_self` copied verbatim from HEAD into a scratch script (plus a variant with `[ ! -L "$c" ] &&` removed), run against scratch files; no git involved. `bats -f Q-093 test/cc-push.bats`: both tests pass.

| # | Candidate | Dispatch | Result |
|---|---|---|---|
| C1 | `..`, ` .`, `\n.`, `.\n\n`, `.\r`, `./`, `.\0` | Tested (executed) | all `ref` (refused) |
| C2 | `.`, `.\n` | Tested (executed) | `acc` — the intended set |
| C3 | Symlink `commondir -> d` (1-byte relative target; `d` holds `.`) | Tested (executed) | real helper `ref`; **no-`-L` variant `acc`** (see Finding 1) |
| C4 | Symlink with long absolute target (the bats test's shape) | Tested (executed) | real `ref`, no-`-L` variant also `ref` (size of the link > 2) |
| C5 | Hard link to a file holding `.` | Tested (executed) | `acc` — harmless: git reads the same bytes `.`, which name the gitdir regardless of the other link name |
| C6 | FIFO | Tested (executed, `timeout 5`) | `ref`, returned without blocking (`-f` false before any open) |
| C7 | Directory / missing / mode-000 file (uid 1000) | Tested (executed) | all `ref` |
| C8 | Helper called under `set -euo pipefail` | Tested (executed) + read | In `check_checkout` it is called as `! commondir_is_self`, so errexit is suspended inside; every step has an explicit `|| return 1`; a bare call in a `set -e` subshell also returned without aborting. `head` failure propagates through `pipefail` → `return 1`. Fail-closed. |
| C9 | Non-GNU `stat` (macOS host: `stat -c` unsupported) | Read-static | `stat` fails → `return 1` → refused (fail-closed; same dependency as cc-gitdir.sh:34,58) |
| C10 | `stat`/`head`/`od` resolved from a session-planted binary | Read-static | `safe_path "$co"` runs in `main` (cc-push.sh:383) before `check_checkout` (:389); drops relative entries and any inside the checkout. Same trust as the pre-existing `stat`, `find`, `grep`, `realpath` uses. |
| C11 | TOCTOU: file grows / is swapped after `stat`, before `head` or git's read | Read-static | Not covered by the helper; see Finding 2 |
| C12 | A self-commondir changing what else git reads (plan B13) | **Untested** | listed below |
| C13 | Case-insensitive host FS (`COMMONDIR`) | **Untested** | listed below |

### Untested bypass candidates

- **C12 / plan B13 — git's `different_commondir` flag.** In git, `get_common_dir_noenv` returns 1 whenever the commondir *file exists*, which sets `repo->different_commondir` even though the resolved common dir equals the gitdir. Read-static expectation: its consumer (path.c `update_common_dir`) rewrites common paths to `repo->commondir`, which is `realpath(<gitdir>/.)` = the same directory, since `.git` itself cannot be a symlink (cc-push.sh:287-289). Not executed: the sandbox refuses git outside this worktree, and git's source is not available offline. The plan's claim "worktreeConfig behaviour does not depend on commondir" matches my recollection of config.c (`config.worktree` is read via `git_pathdup`, per-gitdir) but is unverified. Stage 1 did confirm upload-pack --strict succeeds with `.`, which covers the refs/objects path but not a differential on `worktrees/`, `config.worktree` or per-worktree refs.
- **C13 — case-insensitive FS.** On macOS the shell test `-e "$g/commondir"` and git's `open("commondir")` both match `COMMONDIR`, so the helper and git see the same file; not executed (no such FS here).

## Findings

#### 1. The symlink test does not pin the helper's own `-L` refusal

**Severity:** Low
**Location:** `test/cc-push.bats:302-305` (the helper line is `devcontainer-config/cc-push.sh:273`)
**Boundary:** B1
**Move:** #11 (bypass enumeration)
**Confidence:** High
**Legibility-target:** for-author

Evidence (test, verbatim):

```
  # A symlink to a file holding exactly `.` is refused by the helper itself.
  rm "$c"; printf . > "$T/dot"; ln -s "$T/dot" "$c"
```

Evidence (probe output, executed): `cl2 real=ref noL=ref` for this shape vs. `cl real=ref noL=acc` for `ln -s d commondir`. `stat -c %s` without `-L` reports the link's own size (the length of `$T/dot`, far over 2), so the size gate refuses it whether or not `[ ! -L "$c" ]` is present; the comment "refused by the helper itself" is true only by accident of path length. Not a live bypass: the later `find -P ... -type l` scan (cc-push.sh:305) still refuses any symlink, and git would resolve a relative `.` against the gitdir, not the link's directory. But a regression that drops `-L` would ship green.

**Recommendation:** Use a 1-byte relative target (`printf . > "$T/co/.git/d"; ln -s d "$c"`) and keep the `*"commondir exists"*` assertion; with `-L` removed, the find scan's different message would then fail the test.

#### 2. Check-then-read window: `head -c 2` reads a prefix after `stat`, and git re-reads later

**Severity:** Informational
**Location:** `devcontainer-config/cc-push.sh:272-279` (whole helper), caller `:294`
**Boundary:** B1, B3
**Move:** #4 (TOCTOU)
**Confidence:** High

Evidence (verbatim, complete function):

```
commondir_is_self() {
  local c="$1" s hex
  [ ! -L "$c" ] && [ -f "$c" ] || return 1
  s="$(stat -c %s -- "$c" 2>/dev/null)" || return 1
  case "$s" in 1|2) ;; *) return 1 ;; esac
  hex="$(head -c 2 -- "$c" 2>/dev/null | od -An -tx1)" || return 1
  hex="${hex//[[:space:]]/}"
  [ "$hex" = 2e ] || [ "$hex" = 2e0a ]
}
```

Flow to first use: the same path is read again by `gitdir_common` (cc-gitdir.sh:57-61, `read -r -d '' line < "$c"`) and finally by upload-pack. A writer active during the run can (a) swap the file for a FIFO between `-f` and `head` (hang, not bypass), or (b) append after `stat` so `head -c 2` sees `.\n` while git later reads the whole file `.\n../x` (it trims only trailing CR/LF) as a path. Both need a live writer, i.e. `--allow-running` or docker lying; with the container stopped (`check_no_container`, :388, runs before `check_checkout`, :389) there is none. The diff does not widen the window: before it, a live writer could equally create a commondir after the existence check. This is plan B11, correctly marked residual.

**Legibility-target:** for-orchestrator-synthesis

**Recommendation:** None required. If the helper is ever reused where no container gate precedes it, read once (`head -c 3`) and require exactly the accepted bytes with no third byte, instead of trusting the earlier `stat`.

#### 3. Wording and plan drift around the accepted set

**Severity:** Informational
**Location:** `devcontainer-config/cc-push.sh:295`; plan `docs/working/plan-q093-cc-push-self-commondir.md` rows B2, B5 and Step 3
**Boundary:** B1
**Move:** #2 (implicit assumption in the stated guard)
**Confidence:** High
**Legibility-target:** for-author

Evidence (verbatim): `(Only a regular file holding just \`.\`, a self-reference, is accepted.)`. The helper also accepts `.\n` (probe: `.\n real=acc`), which is the form `echo .` writes; a user reading the message may not realise a trailing newline is fine. Plan drift: B5's rationale ("points elsewhere by being read relative to another dir") is not how git works (a relative commondir is always resolved against the gitdir), so the `-L` refusal is defence in depth rather than the only barrier; B2's "tests for `./`, ` .`" and Step 3's `../../elsewhere` case: the bats loop covers `./` and ` .` but has no `../../elsewhere` (only `..`). No bypass follows from any of these.

**Recommendation:** Say "holding just `.` (optionally followed by one newline)" in the die text, as guides/cc-isolated-usage.md already does; add `'../../x'` to the refused-bytes loop or drop it from the plan.

## Endorsement Claims

None for the guardrail itself: `commondir_is_self` has untested bypass candidates (C12, C13), so per move #11 it may not appear here. Its executed results are in the bypass table above and stand as observations, not a certification.

- **Claim:** In `main`, `safe_path "$co"` and `check_no_container` both run before `check_checkout`, so the helper's `stat`/`head`/`od` are resolved from a PATH with no entry inside the checkout, and a stopped container is required before the helper runs (unless `--allow-running`).
  **Location:** `devcontainer-config/cc-push.sh:383-389`
  **Evidence:** read-static
  **Verified:** read `main` lines 354-389 and `safe_path` 121-134.
  **Not verified:** whether the host user's own absolute PATH entries (e.g. `~/bin`) are writable by anything the container can reach through other bind mounts.
- **Claim:** The root-level `commondir` refusal (`looks_like_gitdir`, bare-repo fallback) is unchanged by this diff.
  **Location:** `devcontainer-config/cc-gitdir.sh:87-90`; `cc-push.sh:333-335`
  **Evidence:** read-static
  **Verified:** diff touches neither; read both.
  **Not verified:** cc-exit-scan.sh's own root-commondir check (line 707) was not re-traced.

## Primitive sweep

Primitive: open/read of a session-controlled path (blocking read of a FIFO; content drives path resolution)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `cc-push.sh:274` `stat -c %s` on commondir | S1 | `! -L && -f` first | cleared — lstat-level, no open |
| `cc-push.sh:276` `head -c 2` on commondir | S1 | `! -L && -f`, size 1-2 | cleared (stopped container); Finding 2 for the live-writer window |
| `cc-gitdir.sh:57-61` `read < "$c"` in `gitdir_common` | S1 | `-f && -r`, size 1-4096 | cleared — only reached after the helper accepted, resolves to `<g>/.` |
| `cc-gitdir.sh:89` `-f "$d/commondir"` at checkout root | S2 | test only, no read | cleared — unchanged |
| `cc-exit-scan.sh:123-126, 555-560` `_snap_first_line` of commondir | S1 | `-f` | cleared — unchanged by the diff; `.` normalises to the gitdir via `cd && pwd -P` |
| git-upload-pack `--strict` reading `<co>/.git/commondir` | S1 | all of `check_checkout` | Untested candidate C12 (different_commondir side effects) |

Primitive: process exec by name

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `cc-push.sh:274,276` `stat`, `head`, `od` | S3 | `safe_path "$co"` (:383) | cleared — same resolution as pre-existing coreutils calls |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Symlink test does not pin the helper's `-L` check | Low | B1 | `test/cc-push.bats:302-305` | High |
| 2 | Check-then-read window (needs a live writer; not widened) | Informational | B1, B3 | `cc-push.sh:272-279` | High |
| 3 | Die text omits `.\n`; plan B5 rationale and Step 3 test list drift | Informational | B1 | `cc-push.sh:295`, plan | High |

## Overall Assessment

The relaxation is narrow and fail-closed: type before read, exact byte compare via hex (so `.\0` and `.\n\n` cannot collapse to `.`), size cap before read, explicit `|| return 1` on every step, and every other `check_checkout` guard still runs afterwards. Across 13 probed candidates I found no input the helper accepts that git would resolve anywhere but the gitdir; the only accepted inputs are `.`, `.\n` and hard links to them. The TOCTOU residual is the existing one, gated by `check_no_container`. The one actionable item is Finding 1: the symlink test would stay green if the helper's `-L` test were removed, and the fix is one line. The open question is C12 (plan B13): whether git setting `different_commondir` for a file that names itself changes any read upload-pack makes. It is plausibly a no-op but has not been run. Verdict: *no findings within the code paths read; endorsement claims pending execution verification*. Mergeable after Finding 1's test fix, with C12 ideally checked on the host by an upload-pack ref-advertisement diff (`.git/commondir` = `.` vs absent, with a `worktrees/x/` entry and `extensions.worktreeConfig=true`).

## Goal-Alignment Note
- Success criterion (restated verbatim): a report saved to /workspace/.claude/worktrees/agent-ab977469478643bc3/docs/reviews/q093-security-review-2026-09-28.md, structured per the security-reviewer skill.
- Answered: yes. Every requested consideration is covered: TOCTOU, hard links, PATH resolution, set -euo pipefail, B13 and cc-exit-scan interplay.
- Out of scope: running git experiments outside the worktree (the sandbox refused), so C12/B13 stays untested.
- Escalate: Finding 1 (one-line test fix); a host-side check of C12 before calling B13 "covered".
- Decisions I made: I rated the weak symlink test Low, not Informational, because it is a regression gap in an enforcement file (the alternative was Informational, since the find scan still catches symlinks). I did not treat the two failing suite tests (28, 46) as findings: both pass under `LC_ALL=C`, and the failure is this container's missing en_US.UTF-8 locale.
