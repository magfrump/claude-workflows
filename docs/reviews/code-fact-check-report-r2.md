Commit: d0fdd04

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-copyinstall (branch `ans/copy-install`)
**Scope:** diff `712c626..d0fdd04`: README.md, devcontainer-config/install.sh, docs/decisions/037-bare-host-copy-install.md, guides/bare-host-hook-wiring.md, test/install-host.bats, test/link-claude-home-wiring.bats, plus the commit messages of 1514518, dcf4a6d, 6793b79, d0fdd04. Working docs under `docs/working/` and the pre-mortem and architecture-review files were read as context only.
**Checked:** 2026-09-23
**Total claims checked:** 25 (including split sub-claims)
**Summary:** 17 verified, 7 mostly accurate, 0 stale, 0 incorrect, 1 unverifiable

Execution provenance for every `executed` claim below. All runs were hermetic: HOME, CLAUDE_HOME_DIR, CLAUDE_DEVC_CONFIG_DIR, CLAUDE_DEVC_BIN_DIR and TMPDIR all pointed under the session scratchpad or BATS_TEST_TMPDIR. CLAUDECODE and CLAUDE_CONFIG_DIR were unset for the child process. Nothing ran against the real `~/.claude`, `~/.config` or `~/.local`.

| Log (under `docs/reviews/execution-logs/copy-install-r2/`) | Command (script copied alongside) | cwd | Exit | UTC |
|---|---|---|---|---|
| `install-host-head.log` | `bats test/install-host.bats` (s2.sh) | worktree | 0 | 2026-09-23T23:30:47Z |
| `cc-isolated.log`, `link-wiring.log`, `hooks.log` | `bats test/cc-isolated-functions.bats`, `bats test/link-claude-home-wiring.bats`, `bats test/hooks/*.bats` (s2.sh) | worktree | 0, 0, 0 | 23:30:47–23:32:13Z |
| `install-host-old.log` | `bats test/install-host.bats` in a `git archive d0fdd04` copy with install.sh replaced by `712c626`'s (s2.sh) | `$TMPDIR/oldcopy` | 1 | ≤23:32:13Z |
| `experiments.log` | `bash s3.sh` (E1–E6) | /tmp | 0 | ends 23:33:20Z |
| `compare-1514518.log` | `bash s4.sh` (712c626 vs 1514518 argument handling) | /tmp | 1 (last `diff` differs, expected) | 23:34:08Z |
| `run-tests-fast.log` | `bash scripts/run-tests.sh --fast` | worktree | 0 | 23:34:17–23:35:48Z |

No entry in `docs/reviews/hallucination-patterns.md` matches any claim here.

---

## Claim 1: "The `~/.claude` target only installs for a human at a terminal. It is skipped with `--yes`, from a script with no TTY, and inside a Claude Code session."

**Location:** `README.md:22-23`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three skip conditions: `--yes`, a stdin that is not a TTY, and CLAUDECODE set. It does not establish "only installs for a human". A process that supplies a pty and unsets CLAUDECODE installs (Claim 5), and the README's own wording is "for a human at a terminal", which the code cannot check.
**Legibility-target:** for-orchestrator-synthesis

The three checks are the first thing `install_claude_home` does after choosing the destination:

```bash
# devcontainer-config/install.sh:293-304
  if [ "$ASSUME_YES" = "--yes" ]; then
    echo "Skipped host target (~/.claude): it never installs with --yes. ..."
    return 0
  fi
  if [ -n "${CLAUDECODE:-}" ]; then
    echo "Skipped host target (~/.claude): running inside a Claude Code session ..."
    return 0
  fi
  if [ ! -t 0 ]; then
    echo "Skipped host target (~/.claude): it needs an interactive terminal (stdin is not a TTY). ..."
    return 0
  fi
```

The tests for them all passed: T1 (closed stdin), T2 (piped answers), T3 (`--yes` without a TTY), T4 (`--yes` in a pty) and T22 (CLAUDECODE=1 in a pty). Each one confirms the destination snapshot did not change (`install-host-head.log`).

**Evidence:** `devcontainer-config/install.sh:293-304`, `test/install-host.bats` T1–T4 and T22, `docs/reviews/execution-logs/copy-install-r2/install-host-head.log`

---

## Claim 2a: "Its `~/.claude` review lists every symlink it will replace (`REPLACE symlink … with a copy`) and every file in those directories that the repo doesn't have (`MOVE to backup`). Check any line marked `WIRED in settings` … Your `settings.json`, memory, projects and logs are never touched."

**Location:** `README.md:26-33`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the REPLACE, MOVE and WIRED listing for top-level links, per-file links and foreign files and directories, and the byte-identity of settings.json, settings.local.json, projects, memory, logs and .credentials.json after a y. It does not establish that the review can always be completed: a dangling link aborts it (Claim 2b).
**Legibility-target:** for-orchestrator-synthesis

T5 asserts a `REPLACE symlink <dest>/<n> -> ` line for `CLAUDE.md workflows skills patterns guides scripts hooks/h.sh`, all printed before the prompt. T13 asserts `MOVE to backup (not in the repo): …/skills/mine/SKILL.md`. T20 asserts `WIRED in settings` for a foreign hook named in settings.json. T7 compares sha256 sums of the user-state files before and after a y install. All of these pass (`install-host-head.log`). Experiment E2 (`experiments.log`) adds a foreign skill that is a *symlinked directory* (`skills/myskill -> other/myskill`). It prints both `REPLACE symlink …/skills/myskill -> …` and `MOVE to backup (not in the repo): …/skills/myskill`, and the diff shows its content as removed (`-mine`).

**Evidence:** `devcontainer-config/install.sh:345-369`, `test/install-host.bats` T5, T7, T13 and T20, `docs/reviews/execution-logs/copy-install-r2/install-host-head.log`, `docs/reviews/execution-logs/copy-install-r2/experiments.log` (E2)

---

## Claim 2b: "Everything replaced, including the old links, is moved to `~/.claude/.claude-workflows-backup/<UTC stamp>/`."

**Location:** `README.md:31-32`
**Type:** Behavioral / Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a run that reaches the swap: links are moved as links (T6) and foreign files are moved (T13). It does not cover two paths that migrating users can hit. (1) A dangling symlink inside an owned directory makes the review abort, so nothing is moved and the run exits 1. (2) A `mv` that fails partway through the backup step leaves the destination partly emptied (Claim 9).
**Legibility-target:** for-author

When an install completes, the statement holds. T6 checks `[ -L "$bk/skills" ]`, `[ -L "$bk/CLAUDE.md" ]` and `[ -L "$bk/hooks/h.sh" ]`. But the review diff runs `diff -ruN` over each owned directory:

```bash
# devcontainer-config/install.sh:145-151
    diff -ruN "$dest/$item" "$src/$item" || rc=$?
    case "$rc" in
      0) ;;
      1) changed=1 ;;
      *) echo "ERROR: could not diff payload item '$item' (diff exit $rc)." >&2
         echo "       The review diff is incomplete, so nothing was installed." >&2
         exit 1 ;;
```

In E2b, the destination held a dangling per-file link, `hooks/old.sh -> gone.sh`. The pre-pass printed `REPLACE symlink …/hooks/old.sh` and `MOVE to backup …/hooks/old.sh`. Then diff printed `diff: …/hooks/old.sh: No such file or directory`, followed by `ERROR: could not diff payload item 'hooks' (diff exit 2)`. Nothing was installed. The migration paragraph doesn't mention this case. The user has to delete the dangling link by hand before the migration can go ahead. All nine per-file hooks from the old README still exist at d0fdd04 (`compare-1514518.log`), so the user's current links should not be dangling.

**Evidence:** `devcontainer-config/install.sh:133-155`, `devcontainer-config/install.sh:372-374`, `docs/reviews/execution-logs/copy-install-r2/experiments.log` (E2b), `docs/reviews/execution-logs/copy-install-r2/compare-1514518.log`

---

## Claim 3: "Decision 037: a decline ends this target, not the run; the host target is still offered. The line keeps its old wording, and the run still exits 1 because something was declined."

**Location:** `devcontainer-config/install.sh:192-196`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the decline path's continuation, its exit status, and the wording of the "Aborted" line. It does not establish that output-matching callers are unaffected: the line now carries a suffix.
**Legibility-target:** for-author

The line gained a suffix:

```bash
# devcontainer-config/install.sh:195
      echo "Aborted. Nothing was changed. (devcontainer config)"
```

The old line was `echo "Aborted. Nothing was changed."; exit 1` (`712c626:devcontainer-config/install.sh:124`). E6 diffed the output of a closed-stdin run of each version:

```
< Install this config and bless it? [y/N] Aborted. Nothing was changed.
---
> Install this config and bless it? [y/N] Aborted. Nothing was changed. (devcontainer config)
> 
> Skipped host target (~/.claude): it needs an interactive terminal (stdin is not a TTY). ...
```

Both runs exit 1. The continuation and exit-1 parts are right (T5 and T17 reach the host prompt after `n`). "Keeps its old wording" is right for the prefix only. A substring match still passes; an exact line match does not.

**Evidence:** `devcontainer-config/install.sh:190-199`, `docs/reviews/execution-logs/copy-install-r2/experiments.log` (E6)

---

## Claim 4: "Skip rules come first: before this target reads or stages anything, so every non-interactive run (scripts, tests, --yes) is unchanged apart from this one line. A skip is not a decline and does not change the exit status."

**Location:** `devcontainer-config/install.sh:287-289`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the ordering: the only work before the skip checks is choosing `dest`, with no staging and no file reads. It also covers the unchanged exit status (T1: 1, T3: 0). It does not establish "unchanged apart from this one line". A non-interactive run without `--yes` also changes the Aborted line and adds a blank line.
**Legibility-target:** for-author

Before the checks, the function only picks `dest` and `label` from environment variables and prints a blank line (`echo` at `install.sh:286`). There are two claims here. "Before this target reads or stages anything" holds. "Unchanged apart from this one line" does not hold for the closed-stdin, no-`--yes` case: E6 shows three differing lines, namely the suffixed Aborted line (Claim 3), an empty line and the Skipped line. For `--yes` runs the delta is the blank line plus the Skipped line (T3 output). Decision 037 repeats this claim (Claim 17) and so does commit 6793b79 (Claim 21b).

**Evidence:** `devcontainer-config/install.sh:279-304`, `docs/reviews/execution-logs/copy-install-r2/experiments.log` (E6), `docs/reviews/execution-logs/copy-install-r2/install-host-head.log`

---

## Claim 5: "Neither check stops an agent that sets out to fake a terminal (`script` gives it a pty; `env -u` drops CLAUDECODE). They stop the accidental run and make the deliberate one conspicuous."

**Location:** `devcontainer-config/install.sh:290-292`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the bypass: from a Claude Code Bash tool where CLAUDECODE=1 and `tty` prints "not a tty", `printf 'n\ny\n' | env -u CLAUDECODE script -qec "bash install.sh" /dev/null` completes a host install. It does not establish "conspicuous". The only trace is the manifest's `installed_parent`, which is not reliably "script" (Claim 12b).
**Legibility-target:** for-orchestrator-synthesis

This session had `CLAUDECODE=1`, and `tty` printed `not a tty`. `script -qec 'tty; env -u CLAUDECODE sh -c …'` printed `/dev/pts/1` and `CC=unset`. Experiment E1 used that wrapper and ended with `Installed into …/home/.claude.` (`experiments.log`). The test suite drives every y-path test the same way (`run_pty` in `test/install-host.bats:101-104`).

**Evidence:** `devcontainer-config/install.sh:290-304`, `test/install-host.bats:101-104`, `docs/reviews/execution-logs/copy-install-r2/experiments.log` (E1)

---

## Claim 6: "Refuses a destination, backup dir or .cw-new.* leftover that is a symlink into (or resolves inside) the checkout." (commit 6793b79; comment "Guards: nothing below may write through a link into the checkout.")

**Location:** `devcontainer-config/install.sh:309-331`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers these cases: a destination symlinked into the checkout (T14), a symlinked backup root (T21), a `.cw-new.<name>` symlink with any target, a dangling destination symlink, and a destination that is not a directory. It does not refuse a destination symlinked to a real directory outside the checkout. That destination is followed and installed into, and the symlink itself is kept (E1). It also does not guard a pre-existing `.claude-workflows-backup/<stamp>` symlink. That case only triggers the `.$$` suffix, because `-e` follows links.
**Legibility-target:** for-orchestrator-synthesis

```bash
# devcontainer-config/install.sh:316-331
  if inside_repo "$(resolve_phys "$dest")"; then
    host_refuse "$dest resolves inside the repo checkout ($REPO_ROOT). ..."
  fi
  local bkroot="$dest/.claude-workflows-backup"
  if [ -L "$bkroot" ]; then
    host_refuse "$bkroot is a symlink ($(readlink "$bkroot")); ..."
  fi
  if [ -d "$bkroot" ] && inside_repo "$(resolve_phys "$bkroot")"; then
    host_refuse "$bkroot resolves inside the repo checkout."
  fi
  local name
  for name in "${CLAUDE_HOME_NAMES[@]}"; do
    if [ -L "$dest/.cw-new.$name" ]; then
      host_refuse "$dest/.cw-new.$name is a symlink left from elsewhere; remove it and rerun."
    fi
  done
```

`resolve_phys` resolves through `cd … && pwd -P`, so a `~/.claude` symlinked into the checkout is refused. T14 passes, and so does T21 (planted backup-root symlink): both leave the checkout snapshot unchanged. In E1, `~/.claude -> elsewhere` (outside the checkout) installed all seven entries into `elsewhere/`, and `home/.claude` was still a symlink afterwards. The brief asked specifically about a symlinked `~/.claude` that points outside the checkout. The code allows it, and nothing in the guard comment says it refuses it.

**Evidence:** `devcontainer-config/install.sh:255-277`, `devcontainer-config/install.sh:309-331`, `test/install-host.bats` T14 and T21, `docs/reviews/execution-logs/copy-install-r2/experiments.log` (E1)

---

## Claim 7: "The review lists every symlink it will replace (top-level and per-file), every foreign file it will move (flagging hooks wired in settings)" (commit 6793b79)

**Location:** `devcontainer-config/install.sh:342-368`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the top-level links, per-file links (`find -type l`, not followed), foreign regular files and foreign links, and the WIRED flag for a foreign hook named `hooks/<basename>` in settings.json or settings.local.json. It does not establish that the WIRED flag is precise, because it matches on basename. The residue is listed below.
**Legibility-target:** for-orchestrator-synthesis

```bash
# devcontainer-config/install.sh:361-364
        line="MOVE to backup (not in the repo): $f"
        if [ "$name" = hooks ] && grep -qsF "hooks/$(basename "$f")" "$dest/settings.json" "$dest/settings.local.json"; then
          line="$line  <-- WIRED in settings: moving it breaks that hook"
        fi
```

Tests T5, T13 and T20 and experiment E2 show the lines are printed (see Claim 2a). The WIRED test is a fixed-string grep for `hooks/<basename>`, so there are two limits. A foreign `hooks/lib/foo.sh` is flagged if settings mention some `hooks/foo.sh`. A hook wired by a path that doesn't contain `hooks/<basename>` (for example a variable or a different directory name) is not flagged. I inferred these limits from the grep pattern and did not execute a test for them. That is why confidence is Medium. A foreign *symlink* gets both a REPLACE and a MOVE line (E2).

**Evidence:** `devcontainer-config/install.sh:342-369`, `test/install-host.bats` T5, T13 and T20, `docs/reviews/execution-logs/copy-install-r2/experiments.log` (E2)

---

## Claim 8: "Content diff: the same review_diff the devcontainer target uses. Through a symlinked entry it compares the link's target (the checkout) with the stage."

**Location:** `devcontainer-config/install.sh:370-374`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what gets compared through a symlinked entry. For a link into the checkout, the diff prints nothing (T5 finds no `(none` only because the REPLACE lines set `changed`). For a per-file link to other content, it prints that content's diff. It does not establish that a dangling link can be diffed. Such a link makes `diff` exit 2 and aborts the host target (Claim 2b).
**Legibility-target:** for-orchestrator-synthesis

```bash
# devcontainer-config/install.sh:372-374
  if ! review_diff "$dest" "$stage" "${CLAUDE_HOME_NAMES[@]}"; then
    changed=1
  fi
```

In E2, `hooks/h.sh -> other/h.sh` held `echo OLD`. The review showed `-echo OLD` / `+exit 0` under the `diff -ruN …/hooks/h.sh` header, so the diff follows the link, as the comment says. So the brief's concern ("`diff -ruN` through a symlink prints nothing") applies only when the link target equals the stage. That is exactly the case of a link into the checkout, and the REPLACE line covers it.

**Evidence:** `devcontainer-config/install.sh:133-155`, `devcontainer-config/install.sh:370-377`, `docs/reviews/execution-logs/copy-install-r2/experiments.log` (E2, E2b)

---

## Claim 9: "1. Copy every entry beside its target. Any failure: undo and stop before a single live entry is touched." (commit: "A copy failure undoes itself before touching a live entry.")

**Location:** `devcontainer-config/install.sh:392-406`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers failures in step 1 (`mkdir -p "$dest"` or any `cp -R` into `.cw-new.<name>`). It does not cover failures in step 2 (moving to the backup) or step 3 (the swap). Those have no undo and no recovery message, and a step-2 failure leaves live entries missing (E4).
**Legibility-target:** for-author

Step 1 behaves as the comment says. T16 (a read-only destination) passes: exit 1, `nothing was replaced`, destination snapshot unchanged, no backup directory and no `.cw-new.*`. Steps 2 and 3 have no guard:

```bash
# devcontainer-config/install.sh:423-437
    for name in "${CLAUDE_HOME_NAMES[@]}"; do
      if [ -e "$dest/$name" ] || [ -L "$dest/$name" ]; then
        mv "$dest/$name" "$backup/$name"
      fi
    done
  fi

  # 3. Swap the new copies in.
  for name in "${CLAUDE_HOME_NAMES[@]}"; do
    if [ -e "$dest/$name" ] || [ -L "$dest/$name" ]; then
      echo "ERROR: $dest/$name reappeared during the install; the new copy is left at $dest/.cw-new.$name." >&2
      exit 1
    fi
    mv "$dest/.cw-new.$name" "$dest/$name"
  done
```

Experiment E4 made the real directory `workflows` non-writable, which makes a rename to a new parent fail with EACCES. The only output was `mv: cannot move '…/workflows' to '…/.claude-workflows-backup/20260923T233319Z/workflows': Permission denied`, and then `set -e` exited. The destination was left with `guides workflows` and all seven `.cw-new.*`, while `CLAUDE.md` and `skills` were in the backup. So a live `~/.claude` lost its CLAUDE.md and skills. No message named the backup directory or said how to recover (move the backup entries back, or rename the `.cw-new.*` entries). The step-3 ERROR message at `:433` names the `.cw-new` path for the one entry it stops on. It does not mention entries already swapped or where the old entries went.

**Evidence:** `devcontainer-config/install.sh:392-437`, `test/install-host.bats` T16, `docs/reviews/execution-logs/copy-install-r2/experiments.log` (E4)

---

## Claim 10: "Installs by copying to .cw-new.<name>, moving the old entries (links as links) to .claude-workflows-backup/<UTC stamp>/, then swapping in." (commit 6793b79; comment "into a fresh backup dir")

**Location:** `devcontainer-config/install.sh:408-428`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers one run at a time, including two sequential runs within the same second. The second run gets `<stamp>.<pid>`, so "fresh" holds. It does not establish safety for concurrent runs. Two concurrent runs share the `.cw-new.<name>` names, and in E5b the destination ended up with none of the seven entries.
**Legibility-target:** for-orchestrator-synthesis

```bash
# devcontainer-config/install.sh:411-417
  stamp="$(date -u +%Y%m%dT%H%M%SZ)"
  ...
    backup="$bkroot/$stamp"
    if [ -e "$backup" ]; then backup="$backup.$$"; fi
```

E5 ran two sequential y installs in the same second and produced `20260923T233319Z` and `20260923T233319Z.351261`, so there was no collision. E5b ran two installs at the same time. One failed with `mv: cannot stat '…/.cw-new.CLAUDE.md'`, and the destination was left holding only `.claude-workflows-backup` and `.claude-workflows-manifest`. All content was still recoverable from the two backup directories. Concurrent runs need two interactive terminals both answering y, so this is an edge case. It is recorded here because the brief asked about it.

**Evidence:** `devcontainer-config/install.sh:408-437`, `test/install-host.bats` T6, `docs/reviews/execution-logs/copy-install-r2/experiments.log` (E5, E5b), `docs/reviews/execution-logs/copy-install-r2/compare-1514518.log` (e5b final dest)

---

## Claim 11: "Target 2 is SKIPPED, with a message and no effect on the exit status … Exit status: 0 no target declined; 1 a target was declined, or an error; 2 bad arguments."

**Location:** `devcontainer-config/install.sh:40-49`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the documented exit codes and skip behavior for the tested paths: T1 exits 1, T3 and T4 exit 0, T15 exits 2, T17 and T19 exit 1, and T12, T14, T16 and T21 exit 1 on error. It does not establish exit 1 for every error path, for example a `set -e` death in step 2 (E4 exited non-zero, but the log does not capture the exact code).
**Legibility-target:** for-orchestrator-synthesis

`exit "$DECLINED"` at `install.sh:464` is the normal exit. `host_refuse` and the copy and diff failures `exit 1`, and the argument loop does `exit 2` (`install.sh:58`). The tests listed in the Scope field all pass.

**Evidence:** `devcontainer-config/install.sh:40-61`, `devcontainer-config/install.sh:461-464`, `docs/reviews/execution-logs/copy-install-r2/install-host-head.log`

---

## Claim 12a: "Provenance, in link-claude-home's format plus additive keys. `rm -f` first so a planted symlink cannot redirect the write." (commit: "Writes .claude-workflows-manifest (rm -f first) with installed_by, installed_parent and installed_at appended")

**Location:** `devcontainer-config/install.sh:439-447`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the rm-then-cp sequence, which defeats a pre-planted symlink (T6), and the presence and values of `commit`, `assembled_from`, `installed_by=host-tty` and `installed_at=<stamp>`. It does not cover `installed_parent` (Claim 12b), or a symlink planted between the `rm -f` and the `cp`.
**Legibility-target:** for-orchestrator-synthesis

```bash
# devcontainer-config/install.sh:441-447
  rm -f "$dest/.claude-workflows-manifest"
  cp "$stage/.manifest" "$dest/.claude-workflows-manifest"
  {
    echo "installed_by=host-tty"
    echo "installed_parent=$(ps -o comm= -p "$PPID" 2>/dev/null | tr -d ' ' || echo unknown)"
    echo "installed_at=$stamp"
  } >> "$dest/.claude-workflows-manifest"
```

T6 plants `.claude-workflows-manifest -> checkout CLAUDE.md` and asserts `[ ! -L … ]` afterwards and an unchanged checkout. T10 checks `commit=`, `assembled_from=` and `installed_by=host-tty`. E3 shows `installed_at=20260923T233317Z`. `stamp` is always set at `:411`, before the `any` check.

**Evidence:** `devcontainer-config/install.sh:410-411`, `devcontainer-config/install.sh:439-447`, `test/install-host.bats` T6 and T10, `docs/reviews/execution-logs/copy-install-r2/experiments.log` (E3)

---

## Claim 12b: "installed_parent records \"script\" when the installer ran under a pty wrapper, which is an audit trace for the agent-bypass case the TTY rule cannot stop." (commit 6793b79 Notes)

**Location:** `devcontainer-config/install.sh:445`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what `ps -o comm= -p "$PPID"` records under `script -qec`. It does not establish that "script" appears whenever a pty wrapper was used, and it does not establish that a human run never shows it.
**Legibility-target:** for-author

The field records the name of the immediate parent. That parent is `script` only when the shell `script -c` launches execs the command directly. E3 (`experiments.log`) recorded:

```
SHELL=/bin/bash: installed_parent=script
SHELL=/bin/sh:   installed_parent=sh
SHELL=/usr/bin/zsh: installed_parent=script
```

A wrapper with `SHELL=/bin/sh` (dash), or any intermediate shell such as `script -qec 'bash -c "cd x; ./install.sh"'`, records a shell name. That is indistinguishable from a human's interactive shell. A more precise wording: "records the parent process name, which is `script` under `script -c` only when `$SHELL` execs the command directly (bash, zsh)".

**Evidence:** `devcontainer-config/install.sh:445`, `docs/reviews/execution-logs/copy-install-r2/experiments.log` (E3)

---

## Claim 13: "REMINDER: hooks/wiring.json changed (or was not installed before)." / guide: "it prints a `REMINDER` pointing here whenever the installed `hooks/wiring.json` is missing or differs from the repo's."

**Location:** `devcontainer-config/install.sh:381-384`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a completed install. The `cmp -s` runs before the prompt, and the reminder prints after the swap when `wiring.json` was missing or different. It does not cover a declined host prompt, where no reminder prints even if wiring.json differs. The guide's "whenever" is true only for installs that complete.
**Legibility-target:** for-orchestrator-synthesis

```bash
# devcontainer-config/install.sh:381-384
  local wiring_changed=0
  if ! cmp -s "$dest/hooks/wiring.json" "$stage/hooks/wiring.json"; then
    wiring_changed=1
  fi
```

T11 passes. The reminder appears on the first install, is absent on an unchanged rerun, and appears again after wiring.json is edited (`install-host-head.log`).

**Evidence:** `devcontainer-config/install.sh:381-384`, `devcontainer-config/install.sh:453-458`, `guides/bare-host-hook-wiring.md:61-64`, `test/install-host.bats` T11

---

## Claim 14: "The seven entry names, derived from CLAUDE_HOME_SRC so the host can never install a subset of the payload (FP-066)."

**Location:** `devcontainer-config/install.sh:246-250`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the derivation of the names and T18's check that all seven entries are installed. It does not establish behavior if CLAUDE_HOME_SRC ever contains two entries with the same basename.
**Legibility-target:** for-orchestrator-synthesis

```bash
# devcontainer-config/install.sh:248-249
CLAUDE_HOME_NAMES=()
for _item in "${CLAUDE_HOME_SRC[@]}"; do CLAUDE_HOME_NAMES+=("$(basename "$_item")"); done
```

T18 asserts that all seven exist after a first install and passes.

**Evidence:** `devcontainer-config/install.sh:93`, `devcontainer-config/install.sh:246-250`, `test/install-host.bats` T18

---

## Claim 15: "Every existing non-interactive devcontainer run is unchanged apart from one extra line." (and the sub-decision list: "It is skipped, with a message, when `--yes` is given or stdin is not a TTY.")

**Location:** `docs/decisions/037-bare-host-copy-install.md:31-33`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the delta in non-interactive output. It does not establish that the skip list is complete, because the code also skips on CLAUDECODE, which this bullet omits.
**Legibility-target:** for-author

This is the same finding as Claim 4. E6 shows the Aborted-line suffix `(devcontainer config)` and a blank line in addition to the Skipped line, so the delta is more than one extra line. The skip list in this bullet leaves out the third condition, which the code implements at `install.sh:297-300` and which README.md:22-23, the `--help` text and the commit all name.

**Evidence:** `docs/decisions/037-bare-host-copy-install.md:31-33`, `devcontainer-config/install.sh:293-304`, `docs/reviews/execution-logs/copy-install-r2/experiments.log` (E6)

---

## Claim 16a: "In this session the Bash tool has no TTY … But util-linux `script` can wrap the installer in a pty, which is how the tests drive it. The check stops accidents, not intent."

**Location:** `docs/decisions/037-bare-host-copy-install.md:50`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the claims that the agent Bash tool has no TTY, that `script` provides one, and that an install goes through. It does not establish the parenthetical "fd 0 is `/dev/null`". In this session fd 0 was a socket (`/proc/$$/fd/0 -> socket:[…]`). That is a different session and does not contradict the dated observation, but the detail does not reproduce.
**Legibility-target:** for-orchestrator-synthesis

See Claim 5: `tty` printed "not a tty"; under `script -qec` it printed `/dev/pts/1`, and E1 installed. The command's output is not in a captured log. I ran it inline at about 23:35Z:

```
CLAUDECODE=1
not a tty
/proc/458271/fd/0 -> socket:[158109687]
/dev/pts/1
CC=unset
```

**Evidence:** `docs/decisions/037-bare-host-copy-install.md:50`, `test/install-host.bats:101-104`, `docs/reviews/execution-logs/copy-install-r2/experiments.log` (E1)

---

## Claim 16b: "The backstop is sandbox `denyWrite ~/.claude` (guide §3)."

**Location:** `docs/decisions/037-bare-host-copy-install.md:50`
**Type:** Architectural
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the guide text that recommends it (`guides/bare-host-hook-wiring.md:74-77`). It does not establish that the user's host sandbox sets it, or that the sandbox confines a `script`-wrapped child process (execution required, blocker: host settings and a live bare-host sandbox are not available here). It also does not cover the devcontainer target's write to `~/.config/claude-devcontainer`, which denyWrite `~/.claude` does not cover. Decision 037 itself says "~/.config is agent-writable on a bare host".
**Legibility-target:** for-orchestrator-synthesis

The guide recommends `denyWrite` to `~/.claude`, `~/CLAUDE.md` and the auditor script (`guides/bare-host-hook-wiring.md:74-77`). The brief described the claim as "the only hard barrier". I did not find that phrasing in the changed files (paraphrased — no quote available because the claim covers absence of text: grep for `hard barrier` over README.md, the guide and 037 returned nothing). The guide's accepted-gaps list names two backstops, sandbox denyWrite and the PostToolUse config audit (`guides/bare-host-hook-wiring.md:122-124`).

**Evidence:** `docs/decisions/037-bare-host-copy-install.md:50`, `guides/bare-host-hook-wiring.md:74-77`, `guides/bare-host-hook-wiring.md:122-124`

---

## Claim 17: "The installer copies the whole `hooks/` directory (including `hooks/lib/`) and the whole `scripts/` directory, so hooks that find their helpers by their own path (`log-usage.sh` → `lib/usage-common.sh` and `../scripts/lib/`; `claude-config-audit.sh` → `../scripts/claude_config_audit.py`) keep working."

**Location:** `guides/bare-host-hook-wiring.md:16-22`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers log-usage.sh's two relative sources, which were exercised end to end by T9, and claude-config-audit.sh's resolution path, which was read. It does not establish that claude-config-audit.sh runs successfully from an installed copy, because that was not executed.
**Legibility-target:** for-orchestrator-synthesis

```bash
# hooks/log-usage.sh:11,14
source "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/lib/usage-common.sh"
source "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../scripts/lib/skill-paths.sh"
# hooks/claude-config-audit.sh:43-49
if [[ -n "${CLAUDE_CONFIG_AUDIT_SCRIPT:-}" ]]; then
  AUDIT_SCRIPT="$CLAUDE_CONFIG_AUDIT_SCRIPT"
...
  HOOK_DIR=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
  AUDIT_SCRIPT="$HOOK_DIR/../scripts/claude_config_audit.py"
  [[ -f "$AUDIT_SCRIPT" ]] || AUDIT_SCRIPT="$HOME/private_reviews/claude_config_audit.py"
```

T9 installs the real hooks and scripts and then runs the installed `log-usage.sh`, which writes `"smoke"` to `usage.jsonl`. It passes. The same excerpt also confirms the §3 resolution order (`guides/bare-host-hook-wiring.md:82-84`). `~/.claude/scripts/…` is inside the `~/.claude` subtree that §3's denyWrite covers, so that is a statement about paths and holds.

**Evidence:** `hooks/log-usage.sh:10-14`, `hooks/claude-config-audit.sh:31-49`, `guides/bare-host-hook-wiring.md:82-88`, `test/install-host.bats` T9

---

## Claim 18: "Notes: exit 2 for an unknown argument is the only observable change, and only for invalid input." (with "The devcontainer flow is otherwise unchanged: test/cc-isolated-functions.bats passes unmodified (90/90)")

**Location:** `devcontainer-config/install.sh:53-61` (commit 1514518)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the output and exit code of 712c626 and of 1514518 for no arguments, `--yes`, `--help` and `--yes extra`. It does not establish identical behavior for inputs outside those four.
**Legibility-target:** for-author

`compare-1514518.log` shows the flow with no arguments and with `--yes` is `SAME`, and cc-isolated-functions.bats passes 90/90. But `--help` is also an observable change. Before, it prompted and exited 1 (`Install this config and bless it? [y/N] Aborted. Nothing was changed.`, `rc=1`). Now it prints usage and exits 0 (`rc=0`). `--help` was not invalid input under the old parser: `ASSUME_YES="${1:-}"` (`712c626:devcontainer-config/install.sh:21`) treated it as "not --yes". The same commit body's first paragraph describes `-h/--help`, so only the Notes line is imprecise. Another difference: `install.sh --yes extra` used to install (extra arguments were ignored) and now exits 2. That falls under "unknown argument", but it was a working invocation before.

**Evidence:** `devcontainer-config/install.sh:53-61`, `docs/reviews/execution-logs/copy-install-r2/compare-1514518.log`, `docs/reviews/execution-logs/copy-install-r2/cc-isolated.log`

---

## Claim 19: "All 24 fail against the current install.sh (T7 and T16 were tightened so they cannot pass when nothing is installed)." (commit dcf4a6d)

**Location:** `test/install-host.bats:106-391`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count (0 ok, 24 not ok) when the suite runs against 712c626's install.sh. It does not establish that each test fails for its intended reason. The tightening lines are present (T7 asserts a real `skills` directory, and T16 asserts `nothing was replaced`), but I did not check the reason for each failure.
**Legibility-target:** for-orchestrator-synthesis

`install-host-old.log`: every test T1–T24 reports `not ok`, and bats exits 1. T7 contains `[ -d "$CLAUDE_HOME_DIR/skills" ] && [ ! -L "$CLAUDE_HOME_DIR/skills" ]   # the install ran`, and T16 contains `[[ "$output" == *'nothing was replaced'* ]]`.

**Evidence:** `test/install-host.bats` T7 and T16, `docs/reviews/execution-logs/copy-install-r2/install-host-old.log`

---

## Claim 20: "Verification on this branch: test/install-host.bats 24/24; test/cc-isolated-functions.bats 90/90 (unmodified); test/link-claude-home-wiring.bats 14/14; test/hooks/*.bats 144/144 (6 files); … scripts/run-tests.sh --fast: 864 ok, 0 not ok" (commit d0fdd04)

**Location:** `test/link-claude-home-wiring.bats:256-272`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every count listed. It does not independently cover guide-index-sync, cross-reference-integrity and fixture-hermeticity, which I assume are inside the 864-test fast run (not checked file by file). It also does not establish that the edited test 14 still catches its stated mutations.
**Legibility-target:** for-orchestrator-synthesis

I reproduced the counts: install-host 24 ok / 0 not ok, cc-isolated 90/0, link-claude-home-wiring 14/0, `test/hooks/*.bats` 144/0 across 6 files, and `run-tests.sh --fast` 864 ok / 0 not ok (exit 0, 1m31s). The rewritten test-14 assertions are `grep -qE '^CLAUDE_HOME_SRC=\(.* scripts( |\))' …install.sh` and `grep -qE '^\./devcontainer-config/install\.sh' …README.md`.

**Evidence:** `test/link-claude-home-wiring.bats:270-271`, `docs/reviews/execution-logs/copy-install-r2/install-host-head.log`, `docs/reviews/execution-logs/copy-install-r2/cc-isolated.log`, `docs/reviews/execution-logs/copy-install-r2/link-wiring.log`, `docs/reviews/execution-logs/copy-install-r2/hooks.log`, `docs/reviews/execution-logs/copy-install-r2/run-tests-fast.log`

---

## Claim 21a: "Skipped, before reading or staging anything and without affecting the exit status, on --yes, when CLAUDECODE is set, or when stdin is not a TTY." / "Declining the devcontainer target now continues to the host target; the run still exits 1 when anything was declined." (commit 6793b79)

**Location:** `devcontainer-config/install.sh:190-199`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the skip conditions and their ordering (Claims 1 and 4), and continuation with exit 1 after a devcontainer decline (T5 and T17 reach the host prompt after `n`; T17 exits 1). It also covers exit 1 when the devcontainer target is accepted and the host target declined (T19). It does not cover the "otherwise unchanged" part, which is Claim 21b.
**Legibility-target:** for-orchestrator-synthesis

`DECLINED=1; return 0` at `install.sh:196-197` and `exit "$DECLINED"` at `:464` implement it. The listed tests pass.

**Evidence:** `devcontainer-config/install.sh:190-199`, `devcontainer-config/install.sh:386-390`, `devcontainer-config/install.sh:461-464`, `docs/reviews/execution-logs/copy-install-r2/install-host-head.log`

---

## Claim 21b: "Non-interactive devcontainer runs are otherwise unchanged." (commit 6793b79)

**Location:** `devcontainer-config/install.sh:195`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers exit codes and the effects on the devcontainer install, which are unchanged. It does not cover output text: the closed-stdin decline line gained ` (devcontainer config)`.
**Legibility-target:** for-author

The finding is the same as Claims 3 and 4. The `echo "Aborted. Nothing was changed. (devcontainer config)"` at `install.sh:195` differs from the old `echo "Aborted. Nothing was changed."`, and E6 records it.

**Evidence:** `devcontainer-config/install.sh:195`, `docs/reviews/execution-logs/copy-install-r2/experiments.log` (E6)

---

## Claims Requiring Attention

### Incorrect
- none

### Stale
- none

### Mostly Accurate
- **Claim 2b** (`README.md:31-32`): "Everything replaced … is moved" holds only when the run reaches the swap. A dangling per-file link aborts the review with `could not diff` (E2b), and the migration paragraph doesn't say so.
- **Claim 3** (`devcontainer-config/install.sh:192-196`): "keeps its old wording". The Aborted line gained a ` (devcontainer config)` suffix.
- **Claim 4** (`devcontainer-config/install.sh:287-289`): "unchanged apart from this one line". A non-`--yes` non-interactive run also changes the Aborted line and adds a blank line.
- **Claim 12b** (`devcontainer-config/install.sh:445`, commit 6793b79): `installed_parent` is "script" under `script -c` only when `$SHELL` execs directly. Under `SHELL=/bin/sh` it records `sh`, so as an audit trace it can be evaded.
- **Claim 15** (`docs/decisions/037-bare-host-copy-install.md:31-33`): "one extra line" is really three changed lines. The skip list also omits CLAUDECODE.
- **Claim 18** (`devcontainer-config/install.sh:53-61`, commit 1514518): "the only observable change" leaves out `--help`/`-h`, which went from prompt + exit 1 to usage + exit 0. Also `--yes extra` previously installed and now exits 2.
- **Claim 21b** (`devcontainer-config/install.sh:195`, commit 6793b79): "otherwise unchanged" leaves out the Aborted-line suffix.

### Unverifiable
- **Claim 16b** (`docs/decisions/037-bare-host-copy-install.md:50`): the denyWrite `~/.claude` backstop depends on the user's host sandbox settings, and on bwrap confining a `script`-wrapped child. Verifying it needs a live bare-host sandbox. It does not cover the devcontainer target's `~/.config` writes.

### Residuals recorded in Verified claims' Scope fields (for synthesis)
- **Claim 9:** a failure in step 2 (moving to the backup) or step 3 (the swap) has no undo and no recovery message. E4 left a live destination without CLAUDE.md and skills, with those entries in the backup and all `.cw-new.*` stranded. The only output was `mv: … Permission denied`.
- **Claim 10:** two sequential runs in the same second get distinct backup directories (`.PID` suffix). Two concurrent runs collide on `.cw-new.*`, and in E5b the destination ended with none of the seven entries.
- **Claim 6:** a `~/.claude` symlinked to a directory outside the checkout is followed and installed into (E1). That is not refused, and the guard comment does not claim to refuse it.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the output path your task names, structured per your skill, beginning with a `Commit: d0fdd04` line.
- Answered: yes. All 8 brief items were checked, 24 of 25 claims by hermetic execution.
- Out of scope: running install.sh against the real host (plan step 9), and macOS behavior (`find -print0` / `sort -z` untested there). The brief's phrase "denyWrite ~/.claude is the only hard barrier" does not appear in the changed files. Claim 16b verdicts the nearest actual text.
- Escalate: Claim 9's residual. A partial failure in step 2 empties part of the live `~/.claude` with no recovery message, and this lands on the user's real host in plan step 9. Also Claim 2b: a dangling per-file link blocks the migration with only a `could not diff` error.
