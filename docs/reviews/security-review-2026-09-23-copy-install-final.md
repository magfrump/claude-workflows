Commit: 9ae6e46

# Security Review — `ans/copy-install`, confirmation pass 3 (final)

**Scope:** `712c626..9ae6e46`, focused on the fix commits `f84336d..9ae6e46`. `devcontainer-config/install.sh` was read whole (808 lines). Every function named below was read in full before a verdict.
**Date:** 2026-09-23
**Based on:** my prior review `docs/reviews/security-review-2026-09-23-copy-install.md` (Commit d0fdd04), the rubric `docs/reviews/code-review-rubric-2026-09-23-ans-copy-install.md`, and the pass-2 fact-check `docs/reviews/code-fact-check-report-pass2-44c10f5.md`. Behavior that report already establishes by execution is cited by claim number, not re-run.
**Probe evidence:** `/tmp/claude-1000/-workspace/d516ca2c-2abb-4732-a34a-041aa98280c8/scratchpad/sec-final3/` (`lib.sh`, `p0`…`p10` scripts and their `.log` files). All probes were hermetic: HOME, CLAUDE_HOME_DIR, CLAUDE_DEVC_CONFIG_DIR, CLAUDE_DEVC_BIN_DIR and TMPDIR were under the probe dir; `GIT_CONFIG_GLOBAL=/dev/null`; CLAUDECODE was unset for the child; the pty came from `script -qec`; and the installer was a copy of the 9ae6e46 `install.sh` inside a throwaway git repo with the payload committed. Nothing touched the real `~/.claude`, `~/.config` or `~/.local`.

**Threat model** (unchanged from the prior review, and the one the diff states at `install.sh:13-24`): the attacker is a same-uid agent that can write the checkout, including by committing, and, where its sandbox allows, other paths outside `~/.claude`. It cannot write `~/.claude` directly, because the documented backstop is sandbox `denyWrite ~/.claude`. Because the agent can commit, "committed" content is not more trusted than the tree. The review diff is still the only gate. A finding means an agent-controlled change reaches the live config without appearing in the review, or the human's shell writes where the agent chose.

## Trust Boundary Map

```
B1:       [checkout HEAD: blobs, modes, names, links (S1)] → [git archive → extract_commit → stage] → [review_diff/mode_diff → human y]
B2 (moved): [host stage $TMPDIR/cw-host-stage.* (S3)] → [payload_hash at :521, BEFORE the review is printed] → [copies under $dest re-hashed after y → swap into live ~/.claude]
B2b (new): [devcontainer stage $TMPDIR/cw-devc-stage.* (S3)] → [nothing re-checks it after the review] → [cp -Rp into $DEST, then --bless]
B3:       [install.sh bytes (S2)] → [main() parsed whole, `main "$@"; exit $?`] → [human's unsandboxed shell]
B5:       [existing ~/.claude, backups, lock (S5)] → [guards :489-513, lock :628-638, transaction :669-698, prune :723-736] → [live ~/.claude + backup dir]
B6:       [staged bytes and names (S1/S3)] → [diff -ruN | vis (perl)] → [human's terminal and y/N]
B7 (new): [checkout path devcontainer-config/claude-home (S1)] → [rm -rf; cp -Rp mirror refresh :292-293, before any prompt] → [any dir the human can write]
B8:       [checkout .git/config, .git/info/attributes (S8)] → [git rev-parse / cat-file / archive / status] → [commands run as the human; staged bytes]
```

| Label | Source | Mutability | Trust classification (per sink class) |
|---|---|---|---|
| S1 | Checkout content, including what the agent commits: blobs, modes, names, links | runtime-mutable (agent-writable, agent-committable) | UNTRUSTED toward install sinks (the review is the only gate), toward terminal output (control bytes, NUL), and toward path sinks (a link in the checkout is an arbitrary path) |
| S2 | `install.sh` itself | runtime-mutable | trusted to execute only via decision 035's commit gate; `main()` removes the mid-run rewrite window |
| S3 | Stage dirs `cw-host-stage.*`, `cw-devc-stage.*` under the human's `$TMPDIR` | runtime-mutable (0700, same uid) | UNTRUSTED toward install sinks after the review. Reachability by a sandboxed agent depends on its write allowlist covering the human's `$TMPDIR`, which is still not established |
| S4 | `HOME`, `CLAUDE_HOME_DIR`, `CLAUDE_CONFIG_DIR`, `CLAUDE_DEVC_*`, `TMPDIR`, `PATH` | deploy-time (the human's shell) | trusted for path choice; a control character is now refused (`:783-791`) |
| S5 | Existing `~/.claude` contents, backups, lock dir | runtime-mutable by the user only (under denyWrite) | trusted-with-guards for path sinks |
| S6 | `--yes`, `CLAUDECODE`, stdin-is-a-TTY | forgeable | an accident filter, not proof of a human; `--help` now says so (`:50-54`) |
| S8 | `.git/config`, `.git/info/attributes` in the checkout | runtime-mutable (writable by the agent if its sandbox allows writes under `.git`) | UNTRUSTED toward exec sinks: git runs `core.fsmonitor` and filter commands from them |

The C1 change moved the source from the working tree to `git archive HEAD`. That removes ignored junk and uncommitted drift. It does not change who controls the content, because the agent can commit. So the review diff must still be a faithful and final view of what is installed. The fixes made it final for the host target's seven entries after the y. They did not make it faithful during the review, and they did not extend finality to target 1. Two new write paths into the human's shell sit outside the review entirely: the mirror refresh (B7) and git's own config (B8).

## Prior findings 1–8: do the fixes hold at 9ae6e46?

| # (prior) | Status at 9ae6e46 | Evidence | Legibility-target |
|---|---|---|---|
| 1 Symlinks review as "(none)" and install as links | **Fixed.** `extract_commit` refuses any symlink in the extracted payload, for both targets, before either prompt (`install.sh:158-167`). Executed by the pass-2 fact-check (Claim 8). | `links="$(cd "$dir" && find . -type l \| sed 's\|^\./\|\|' \| LC_ALL=C sort)"` | for-orchestrator-synthesis |
| 2 Stage not re-checked after the prompt | **Partly fixed.** For the host target, a write after the review is caught (P2 control: `ERROR: stage changed after review`, CLAUDE.md stayed `old`). The manifest is now inside the hash (979428a). **Still open:** the hash is taken before the review is printed (new Finding 1), and target 1 has no re-check (new Finding 2). | `reviewed_hash="$(payload_hash "$stage" "" "$stage/.manifest")"` (`:521`) | for-author |
| 3 In-place edit of install.sh mid-prompt | **Fixed (static).** Top level holds only assignments and function definitions. The single call is `main "$@"; exit $?` on the last line (`:808`). Fact-check Claim 23 executed the rewrite probe. | `main "$@"; exit $?` | for-orchestrator-synthesis |
| 4 Control bytes in the review diff | **Fixed for C0, ESC, CR, DEL and raw or UTF-8 C1** (P10, executed). Residue: vis fails open when perl is absent (Finding 4), a NUL byte hides a whole file (Finding 5), and overlong encodings pass (see Untested bypass candidates). | `s/([\xc2-\xdf][\x80-\xbf]\|…)\|[\x80-\x9f]/defined $1 ? $1 : "?"/ge;` (`:111`) | for-author |
| 5 Mid-swap failure / concurrent run strips `~/.claude` | **Fixed.** Lock after the y (`:628-638`), copy-then-verify before any live entry moves, and `host_rollback`. P7: a move-aside that failed on `skills` after `CLAUDE.md` had moved was rolled back. `CLAUDE.md` read `old`, no backup dir, lock or `.cw-new.*` was left, and the message named the backup. | `mv "$dest/$name" "$backup/$name" \|\| host_rollback` (`:686`) | for-orchestrator-synthesis |
| 6 "Only a human" overclaimed | **Fixed (doc).** `--help` now says the skip rules stop "accidental runs, not a determined agent" and names the sandbox as the barrier (`:50-54`). `installed_parent` is labelled a hint (`:703-704`). | `The hard barrier is a sandbox that denies agents write access to ~/.claude.` | for-orchestrator-synthesis |
| 7 REPLACE mislabel, basename-only WIRED | **Fixed (static).** A foreign link is labelled `MOVE link …`, and WIRED matches `hooks/$rel` (`:548-556`). Fact-check Claim 15 executed. | `grep -qsF "hooks/$rel" "$dest/settings.json" "$dest/settings.local.json"` | for-orchestrator-synthesis |
| 8 Symlinked `~/.claude` written through without notice | **Not changed.** It is still rubric row C3 (🟢 Consider, open). Not re-reported. | `if [ -L "$dest" ] && [ ! -d "$dest" ]; then` (`:489`) | for-orchestrator-synthesis |

## Findings

#### 1. R2's hash is taken before the review is printed, so the reviewed bytes can differ from the installed bytes

**Severity:** High
**Location:** `devcontainer-config/install.sh:518-521` (hash), `:527-603` (the review reads the stage), `:658` (post-y comparison)
**Boundary:** B2, B6
**Move:** 4 (TOCTOU), 11 (guardrail bypass)
**Confidence:** Medium (the mechanism is executed; reachability, meaning a sandboxed agent writing the human's `$TMPDIR`, is the same open question R2 left)
**Legibility-target:** for-author
**Evidence:** `reviewed_hash="$(payload_hash "$stage" "" "$stage/.manifest")"` at `:521`, then `diff -ruN "$dest/$item" "$src/$item" 2>&1 | vis` (inside `review_diff`, `:228`), called at `:602`.

The post-y check at `:658` proves that the installed copies equal the stage **as hashed at `:521`**. The review renders the stage later, at `:527-603`. An agent commits malicious content. A racer swaps a benign version into the stage after the hash reads it and restores the original after the diff has printed. The human reviews benign text, the copies match the malicious hash, and the malicious content is installed with no error. P1 ran this with a `diff` shim standing in for the racer's timing. The review showed `+global instructions (benign)`, no line containing `MALICIOUS`, and the installed `CLAUDE.md` was `MALICIOUS: ignore all guard hooks` (`p1.log`). A real racer needs one inotify watch: `sha256sum` closes each file after hashing it. The prompt then gives it unlimited time to restore the original. Commit 979428a's Notes already record this residue ("The hash is still taken before the review is printed"). This report confirms it by execution and rates it: it recreates prior Finding 2's outcome, unreviewed content in live `~/.claude`, under a slightly narrower timing condition.

**Recommendation:** Render the review from bytes the agent cannot write. Copy the stage to `$dest/.cw-new.*` first, which sits behind `denyWrite ~/.claude`, then run the pre-pass, `mode_diff` and `review_diff` against those copies and swap exactly them in. The post-y hash then becomes a check against a same-uid writer of `~/.claude` only. The cheaper alternative, re-hashing after the review, leaves a render-time window open.

#### 2. Target 1 installs from its private stage with no post-y integrity check, and then blesses what it installed

**Severity:** High
**Location:** `devcontainer-config/install.sh:288-291` (stage), `:331-334` (install), `:342` (bless)
**Boundary:** B2b
**Move:** 4 (TOCTOU)
**Confidence:** Medium (executed; same `$TMPDIR` reachability caveat as Finding 1)
**Legibility-target:** for-author
**Evidence:** `cp -Rp "$stage/$item" "$DEST/$item"` (`:333`), followed by `CLAUDE_DEVC_CONFIG_DIR="$DEST" "$DEST/cc-isolated.sh" --bless` (`:342`).

Commit 942d5de moved target 1's source from the checkout, which is fully agent-writable, to a `mktemp -d` stage. That is a real narrowing. But R2's hash was never extended to this target. A same-uid write to `$TMPDIR/cw-devc-stage.*/config/egress/base.txt`, made after the review printed and before the y, installed `evil.attacker.example` into the egress allowlist. The review never showed that line, and the tampered config was then blessed (P2, `p2.log`: `BLESS-STUB --bless`, installed `base.txt` ends `evil.attacker.example`). The host target, run in the same probe with the same kind of write, correctly aborted. These files are the container boundary (firewall, launcher, egress lists), and `--bless` turns the unreviewed state into the trusted baseline that decision 016's bless check compares against.

**Recommendation:** Give target 1 the same treatment as the host target, and fix Finding 1's ordering at the same time. Stage into a sibling of `$DEST` that the agent's sandbox cannot write, review from there, and install by rename. Or at minimum hash the stage and compare the installed tree before `--bless`, refusing the bless on a mismatch.

#### 3. The mirror refresh writes the committed payload wherever an agent-planted link points, before any prompt

**Severity:** Medium
**Location:** `devcontainer-config/install.sh:292-293`
**Boundary:** B7
**Move:** 4 (TOCTOU), 12 (sweep of `rm -rf` + `cp` sites)
**Confidence:** Medium (the write is executed; which target dirs make it harmful is untested)
**Legibility-target:** for-author
**Evidence:** `rm -rf "$SRC/claude-home"` then `cp -Rp "$stage/claude-home" "$SRC/claude-home"`

`$SRC/claude-home` is inside the agent-writable checkout. If a racer re-creates it as a symlink to a directory X between the `rm` and the `cp`, then `cp` copies the payload into `X/claude-home`. This runs as the human, unsandboxed, before either prompt: it happens on a run the human declines, and with `--yes` too. P8 answered n to both prompts and the payload landed in the victim dir in 29 of 30 runs (`p8.log`). GNU `cp` refused to follow a second link planted at `X/claude-home` (P9, "cannot overwrite non-directory"), so the attacker cannot overwrite live `~/.claude` entries. The write is limited to creating a new `claude-home/` subtree of committed content under any directory the human can write, and that bypasses `denyWrite ~/.claude`. Whether such a subtree is ever loaded depends on the target: `~/.claude/commands/` and `~/.claude/agents/` are discovered by Claude Code, but whether their discovery recurses was not tested. The same race existed before this branch in a worse form (`mkdir -p "$STAGE"` followed by `cp -r` of each entry into it), and 942d5de rewrote these lines. So this is pre-existing and narrowed, not closed.

**Recommendation:** Stop writing into the checkout. The comment says nothing installs from the mirror (`:83-84`, `:283`). If the mirror is kept, create it with `mkdir` (which fails if anything was planted) and then `cp -Rp "$stage/claude-home/." "$SRC/claude-home/"`, or use `cp -T` (`--no-target-directory`) after a `[ -L ]` refusal.

#### 4. vis() fails open when perl is missing: an empty review still reaches the y/N prompt

**Severity:** Medium
**Location:** `devcontainer-config/install.sh:106-113` (vis), `:227-235` (review_diff exit handling)
**Boundary:** B6
**Move:** 3 (error path)
**Confidence:** Low (executed; it requires a host without perl on PATH, and WSL/Debian/macOS ship it per commit 1592d6b)
**Legibility-target:** for-author
**Evidence:** `diff -ruN "$dest/$item" "$src/$item" 2>&1 | vis || rc=${PIPESTATUS[0]}`

The rc handling takes only `diff`'s status, so a vis failure (127) is invisible to it. `mode_diff` and `review_diff` are called inside `||`/`if !` conditions, where `set -e` is off. With perl removed from PATH (P3), each item printed `perl: command not found` and no diff content. The run reached both prompts, and y installed the new egress line and the new CLAUDE.md line, neither of which was shown (`p3.log`: review mentions them 0 times). This breaks the invariant stated at `:223-225`: "a diff that could not be shown must never reach the [y/N] prompt". Commit 1592d6b introduced the dependency. Before it, vis was `sed`.

**Recommendation:** Check `command -v perl` in `main` and exit before either target if it is missing. Also treat a non-zero `PIPESTATUS[1]` in `review_diff` (and in the `| vis` sites of `mode_diff` and the pre-pass) as "could not show the review", which exits.

#### 5. One NUL byte turns a file's review into "Binary files … differ", and bash still runs it

**Severity:** Medium
**Location:** `devcontainer-config/install.sh:228` (`diff -ruN` without `-a`), both targets
**Boundary:** B1, B6
**Move:** 2 (implicit sanitization assumption), 11
**Confidence:** Medium (executed; it depends on the human missing one line)
**Legibility-target:** for-author
**Evidence:** `diff -ruN "$dest/$item" "$src/$item" 2>&1 | vis`

P4 committed `hooks/guard.sh` with a NUL in a comment line followed by a new command, and `skills/a/SKILL.md` with a NUL followed by an instruction. The review printed only `Binary files …/hooks/guard.sh and …/hooks/guard.sh differ` (and the same for SKILL.md). The installed hook, run with bash, executed the hidden line (`PAYLOAD-RAN`). The human sees that something changed but not what, so the diff stops being the gate for exactly the files an agent would target. The prior review listed this as an untested candidate. It is now executed.

**Recommendation:** Refuse any payload file containing NUL at `extract_commit` (nothing in the payload needs one), or diff with `-a` and map `\x00` to `?` in vis.

#### 6. git runs agent-written commands from the checkout's `.git/config` before any prompt

**Severity:** Medium
**Location:** `devcontainer-config/install.sh:117`, `:137`, `:149`, `:193-194` (every `git -C "$REPO_ROOT"` call)
**Boundary:** B8
**Move:** 1 (trust boundary), 12
**Confidence:** Low (executed in the probe repo; whether a sandboxed agent can write `.git/config` on the user's host was not established)
**Legibility-target:** for-author
**Evidence:** `git -C "$REPO_ROOT" -c tar.umask=022 archive --format=tar "$commit" -- "$@"`

P5 set `core.fsmonitor` and a `filter.x.smudge` command in the probe repo's `.git/config`, and `CLAUDE.md filter=x` in `.git/info/attributes`. One run answered n then y. The fsmonitor command ran eight times (from `git status`) and the smudge command ran twice (from `git archive`), both as the human and before any prompt. The installed `CLAUDE.md` read `global SMUDGED`, while the manifest still said `dirty=no` (`p5.log`). The review did show the smudged bytes, so the content path stays faithful. The problem is code execution. The class is pre-existing, because 712c626 already ran `git status` (`p0` output). The branch adds `git archive`, which also runs filters. It is out of this diff's power to close completely. It belongs next to the `denyWrite ~/.claude` backstop in the guide.

**Recommendation:** Pass `-c core.fsmonitor=false -c core.hooksPath=/dev/null` on every git call. Extract blobs with plumbing that applies no filters (`git ls-tree -r -z` plus `git cat-file blob`) instead of `git archive`. And have `guides/bare-host-hook-wiring.md` §3 name `.git/config` and `.git/info/` as paths the agent sandbox must not write.

#### 7. A new host entry over 200 lines is installed with its content unshown

**Severity:** Informational
**Location:** `devcontainer-config/install.sh:575-590`
**Boundary:** B6
**Move:** 11
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
**Evidence:** `echo "    (content not shown: $lines lines, over the $ADD_MAX_LINES-line limit for a new entry;"`

At HEAD, `hooks/` is 1705 lines and `global-instructions/CLAUDE.md` is 328 (`p0`). On a truly fresh host, neither entry's content is reviewed. The omission is announced on screen with the commit to read (06aa56b), and the header now says so (`:3-4`), so this is a disclosed tradeoff, not a hidden bypass. The user's plan-step-9 host run migrates an existing symlink layout, where each entry is diffed. Recorded so a fresh-host user knows the gate is "read it at the commit" for these two entries.

## Untested bypass candidates

- **vis, overlong UTF-8** (`e0 82 9b`, `f0 80 82 9b`): passed through raw by `:111` (P10, executed). Whether any terminal decodes them as C1 CSI was not tested; modern xterm and VTE reject overlong forms.
- **vis on an 8-bit (Latin-1) terminal**: a valid sequence like `c3 9b` is kept (P10), and its second byte is CSI on an 8-bit terminal. This is by design (commit 1592d6b Notes). Not tested on a real 8-bit terminal.
- **payload_hash, newline or tab in names written into the stage after the review**: the listing is line-based (`%P\t%y\t%m\t%l\n`, `:409`), so names containing `\n` can imitate listing lines. A collision also needs the ordered content-hash list to match, which limits the change to names, types and modes. It was not constructed. Moot if Finding 1's fix (review from `$dest` copies) lands.
- **Prune with a tab in a stamped backup's name**: `cut -f2` (`:736`) would truncate the name and `rm -rf` a different path. Only a writer of `~/.claude` can create that dir (S5), so this is out of model. Not run.

## Endorsement Claims

- **Claim:** A committed symlink anywhere in either target's staged payload aborts the run before any prompt.
  **Location:** `devcontainer-config/install.sh:158-167`
  **Evidence:** read-static
  **Verified:** read `extract_commit` whole. The `find . -type l` covers the whole stage dir, and both targets call it before their review.
  **Not verified:** a symlink inside a submodule gitlink path, since submodules export as empty dirs (fact-check Claim 7).
  **route: code-fact-check**
- **Claim:** For the host target, a write to the stage after the review has printed and before the y is detected, and nothing is replaced.
  **Location:** `devcontainer-config/install.sh:658-663`
  **Evidence:** executed (P2 control: `ERROR: stage changed after review`; installed `CLAUDE.md` stayed `old`)
  **Verified:** one appended line to `CLAUDE.md` after the last review diff call.
  **Not verified:** writes between `:521` and the render, which Finding 1 shows are not detected.
  **route: code-fact-check**
- **Claim:** A move-aside failure part-way through the swap restores the entries already moved, releases the lock, and leaves no `.cw-new.*` copies or empty backup dir.
  **Location:** `devcontainer-config/install.sh:443-460`, `:683-698`
  **Evidence:** executed (P7)
  **Verified:** a failure on the second entry (`skills`) after `CLAUDE.md` had moved.
  **Not verified:** a failure during swap-in (`:695`) after some new copies are in place, and SIGKILL mid-swap (the lock is then left stale, which fails closed with `lock_msg`).
  **route: code-fact-check**
- **Claim:** Backup pruning kept this run's backup and 2 others when earlier backups had names and epochs later than this run's, alongside an unstamped dir and a symlinked dir, with a trailing-slash destination.
  **Location:** `devcontainer-config/install.sh:723-737`
  **Evidence:** executed (P6: remaining `20260924T…`, `20980101…`, `20990101…`, `unstamped`, `zzlink`; the link target was intact)
  **Verified:** the one layout above, with 4 stamped earlier backups.
  **Not verified:** stamp files that are FIFOs or unreadable (S5, out of model).
  **route: code-fact-check**
- **Claim:** Destinations containing a C0 control, DEL or UTF-8 C1 are refused before either target runs.
  **Location:** `devcontainer-config/install.sh:749-754`, `:783-791`
  **Evidence:** read-static
  **Verified:** read `has_ctrl` and the loop over `DEST`, `BIN_DIR` and `HOST_DEST`.
  **Not verified:** a raw 8-bit C1 byte in a destination, which `has_ctrl` passes. The source is S4, the human's own environment.

## Primitive sweep

Primitive: recursive delete / copy / rename into a filesystem path

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `install.sh:145-157` `mkdir .extract`, `tar -x`, `mv`, `rm -rf` | S1 into S3 | private `mktemp -d` parent | cleared: git archive paths cannot escape the dir; links refused after |
| `install.sh:183-184` `rm -rf "$stage"; mkdir -p` | S3 | private parent | cleared |
| `install.sh:292-293` `rm -rf` + `cp -Rp` into the checkout | S1 (planted link) | none | **Finding 3** |
| `install.sh:332-333` `rm -rf "${DEST:?}/$item"` + `cp -Rp` | S3 | none after the review | **Finding 2** |
| `install.sh:338` `ln -sf` | S4 | none | cleared: S4 is deploy-time |
| `install.sh:591-596` `cp -RH`, `find -delete`, `chmod -R` in `$HOST_TMP/installed` | S5 | private parent | cleared |
| `install.sh:644-651` `rm -rf` + `cp -Rp` to `.cw-new.*` | S3 | `.cw-new` link refusal (`:506-510`); hash after | cleared for writes after the review; see Finding 1 for the render window |
| `install.sh:686`, `:695` `mv` swap | S3 (hashed), S5 | lock, reappearance check, rollback | cleared (P7) |
| `install.sh:445-447` rollback `rm -rf`/`mv` | S5 | `:?` | cleared within model |
| `install.sh:709-710` manifest `rm -f` + `mv` | S3 (hashed) | rename, not write-through | cleared |
| `install.sh:726` prune `rm -rf "${bkroot:?}/$old"` | S5 | skips this run's backup, links, unstamped dirs | cleared (P6); tab-in-name is listed under Untested bypass candidates |
| `install.sh:436-438` cleanup `rm -rf`/`rmdir` | S4 (mktemp) | none needed | cleared |

Primitive: process exec

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| every `git -C "$REPO_ROOT"` call (`:117`, `:137`, `:149`, `:193-194`) | S8 | none | **Finding 6** |
| `perl` in `vis` (`:107`) | S4 (PATH) | none | exec cleared (S4 trusted); its absence is **Finding 4** |
| `"$DEST/cc-isolated.sh" --bless` (`:342`) | S3 via the installed copy | the review | reached with unreviewed bytes by **Finding 2** |
| `ps -o comm=` (`:706`) | none | none needed | cleared |

Primitive: untrusted bytes to the terminal

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `review_diff` `:228` | S1/S3 | vis | **Findings 4, 5**; C0/C1 cleared (P10) |
| `mode_diff` `:256`, pre-pass `:532`, `:538`, `:557`, ADD `:578-579`, `:585`, dirty list `:199`, links list `:164` | S1/S3/S5 | vis | cleared for control bytes; each shares Finding 4's missing-perl behavior |
| `echo "Destination: $dest"` `:486`, `ERROR:` lines with `$dest` | S4 | `has_ctrl` refusal | cleared |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | R2 hash precedes the review render; reviewed ≠ installed | High | B2, B6 | `install.sh:521,527-603,658` | Medium |
| 2 | Target 1 has no post-y integrity check; tampered config is blessed | High | B2b | `install.sh:288-291,331-334,342` | Medium |
| 3 | Mirror refresh follows a planted link; writes before any prompt | Medium | B7 | `install.sh:292-293` | Medium |
| 4 | vis fails open without perl; empty review reaches y/N | Medium | B6 | `install.sh:106-113,227-235` | Low |
| 5 | NUL byte hides a file's diff; bash runs it | Medium | B1, B6 | `install.sh:228` | Medium |
| 6 | git runs agent-written fsmonitor/filter commands | Medium | B8 | `install.sh:117,137,149,193-194` | Low |
| 7 | New host entry over 200 lines installed unshown (disclosed) | Informational | B6 | `install.sh:575-590` | High |

## Overall Assessment

The fixes closed what they targeted. Symlinks are refused (1), the script cannot be rewritten mid-run (3), the swap is a locked transaction with a working rollback (5), labels and docs are accurate (6, 7), and pruning never removes this run's backup. R2 holds only after the y. The remaining problems are all the same kind: the review is still not a faithful view of what gets installed. The host hash is taken before the review is printed (Finding 1, executed). Target 1 was moved to a private stage but got no hash at all, and its tampered state is blessed (Finding 2, executed). vis fails open without perl (4), a NUL byte hides a file (5), and two paths write or execute in the human's shell outside any review (3, 6). All of them can be fixed in place without an architecture change. The single most important fix is to render the review from copies behind `denyWrite ~/.claude` (the `.cw-new.*` copies, and an equivalent for target 1), then install exactly those copies. That closes Findings 1 and 2 together and makes the payload hash a secondary check. Findings 1 and 2 share R2's unresolved reachability question: can a sandboxed agent write the human's `$TMPDIR`? If the user confirms it cannot, both drop to defense-in-depth. Not safe to merge as-is for the plan-step-9 host run unless that reachability is ruled out. Outside the findings: no findings within the code paths read; endorsement claims pending execution verification.

## Goal-Alignment Note
- **Success criterion (restated verbatim):** a markdown report saved at the output path your task names, structured per your skill, beginning with a `Commit: 9ae6e46` line.
- **Answered:** brief items 1 (C1 staging: security consequences, including attributes and filters via B8; detached HEAD, shallow clone and submodules deferred to fact-check Claim 7), 2 (R1–R5 re-verified; R2 partly), 3 (A4 vis and A6 pruning executed; A3 via claim 11b's control-character refusal, static), 4 (pruning, the manifest in the hash, target 1 staged from HEAD, control-character refusal, perl vis, and ADD ≤200 all examined, with regressions found in 2, 4 and 7).
- **Out of scope:** brief item 5 (test-count claims) is fact-check's; A1/A2/A5/A9/A10 doc text beyond security wording; macOS/BSD tools; real-terminal rendering of overlong UTF-8.
- **Escalate:** Findings 1 and 2 turn on whether the agent sandbox on the user's host can write the human's `$TMPDIR`, the same unanswered question as R2. The user should settle it before plan step 9, or the fix should make the answer irrelevant by reviewing and installing from copies under the destination.
