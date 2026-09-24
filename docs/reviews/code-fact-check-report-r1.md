Commit: d0fdd04

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-copyinstall (branch `ans/copy-install`)
**Scope:** diff `712c626..d0fdd04`: README.md, devcontainer-config/install.sh (read whole, 464 lines), docs/decisions/035 and 037, guides/README.md, guides/bare-host-hook-wiring.md, test/install-host.bats, test/link-claude-home-wiring.bats, plus the commit messages of the 9 commits. The docs/working and pre-mortem/architecture artifacts were used as context only.
**Checked:** 2026-09-23
**Total claims checked:** 24
**Summary:** 19 verified, 3 mostly accurate, 0 stale, 1 incorrect, 1 unverifiable

Execution provenance for every `executed` claim: raw output is in
`docs/reviews/execution-logs/cfc-copy-install-r1-d0fdd04/` (the directory also holds a few
older scratch files, such as `demo.txt` and `new.txt`, that this report does not cite). All
runs were hermetic. HOME, CLAUDE_HOME_DIR, CLAUDE_DEVC_CONFIG_DIR, CLAUDE_DEVC_BIN_DIR and
TMPDIR all pointed into a temp dir, CLAUDECODE was unset for the child, and install.sh ran
as a copy inside a throwaway git repo (`exp.sh`'s `fake_repo`, which mirrors the bats
`fake_repo`). Nothing touched the real `~/.claude`, `~/.config` or `~/.local`. Runs:

| Log | Command | cwd | Exit | UTC start |
|---|---|---|---|---|
| `bats-head.txt` | `env -u CLAUDECODE bats test/install-host.bats` | worktree | 0 | 2026-09-23T23:30:43Z |
| `bats-old.txt` | same, on `git archive dcf4a6d` (install.sh == 712c626's) | `$scratch/fc/old` | 1 | 23:31:07Z |
| `suites-summary.txt` + per-suite `*.bats.txt`, `hooks-suite.txt` | `run-suites.sh` | worktree | 0 each | 23:32:04Z |
| `run-tests-fast.txt` | `run-fast.sh` (`scripts/run-tests.sh --fast`) | worktree | 0 | 23:32:41Z |
| `exp-E1-E5-E6-E7.txt` | `bash exp.sh E1; E5; E6; E7` | `$scratch/fc` | 0 | 23:34:50Z |
| `exp-E2-E4.txt` | `bash exp.sh E2; E3; E3b; E3c; E4` | `$scratch/fc` | 0 | 23:34:57Z |
| `exp-E8-E9.txt` | `bash exp.sh E8; E9` | `$scratch/fc` | 0 | 23:35:53Z |

(`$scratch` = `/tmp/claude-1000/-workspace/d516ca2c-2abb-4732-a34a-041aa98280c8/scratchpad`.
`exp.sh`, `run-suites.sh` and `run-fast.sh` are copied into the log directory.)

Hallucination-pattern log: `docs/reviews/hallucination-patterns.md` was read. No logged
pattern matches any claim below.

---

## Claim 1: "It is skipped with `--yes`, from a script with no TTY, and inside a Claude Code session."

**Location:** `README.md:22-23`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three skip triggers (`--yes`, non-TTY stdin, CLAUDECODE set), each tested with a pty where relevant. Does not establish that a TTY or CLAUDECODE check distinguishes a human from an agent (Claim 2).
**Legibility-target:** for-orchestrator-synthesis

The three checks run first in `install_claude_home`, before any read:

```bash
# devcontainer-config/install.sh:293-304
  if [ "$ASSUME_YES" = "--yes" ]; then
    echo "Skipped host target (~/.claude): it never installs with --yes. ..."
    return 0
  fi
  if [ -n "${CLAUDECODE:-}" ]; then
    ...
    return 0
  fi
  if [ ! -t 0 ]; then
    ...
    return 0
  fi
```

(excerpt ends :304; enclosing `install_claude_home()` continues to :459 — read.)
T1–T4 and T22 pass at HEAD (`bats-head.txt`). T4 is `--yes` in a pty and T22 is CLAUDECODE=1
in a pty. E1 reproduces the non-TTY and `--yes` skip lines (`exp-E1-E5-E6-E7.txt`).

**Evidence:** `devcontainer-config/install.sh:293-304`; `test/install-host.bats` T1–T4, T22; `bats-head.txt`; `exp-E1-E5-E6-E7.txt`

---

## Claim 2: "The `~/.claude` target only installs for a human at a terminal." (also install.sh --help: "It only installs for a human at a terminal who read the diff.")

**Location:** `README.md:21-22`, `devcontainer-config/install.sh:42-43`
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers whether a non-human process can clear the skip rules and install. Does not establish whether the host's sandbox `denyWrite ~/.claude` would stop such a run on the user's machine (Claim 17).
**Legibility-target:** for-author

The guard is a TTY check plus a CLAUDECODE check (`install.sh:297`, `:301`: `if [ -n "${CLAUDECODE:-}" ]; then` / `if [ ! -t 0 ]; then`). Both can be defeated from an agent's Bash tool. E5, run from this agent session with no TTY (`[outside: not-tty]`), printed `stdin-is-tty` and `CLAUDECODE=unset` under `script -qec 'env -u CLAUDECODE bash -c …' /dev/null`. The hermetic suite is itself the proof. Every y-path test (T6, T7, T9, T10, T11, T13, T18, T24) was run from inside an agent session through `run_pty`, and each one installed:

```bash
# test/install-host.bats:104-108 (run_pty)
run_pty() {
  local input="$1"; shift
  run bash -c 'set -o pipefail; printf "%b" "$1" | env -u CLAUDECODE script -qec "$2" /dev/null | tr -d "\r"' \
      _ "$input" "$*"
}
```

The code comment and decision 037 both state the real property correctly. install.sh:290-292 says "Neither check stops an agent that sets out to fake a terminal … They stop the accidental run", and 037 says "The check stops accidents, not intent." The README and `--help` state it as an absolute, and that contradicts both. A reader relying on "only a human can install" would not add the sandbox backstop.

**Evidence:** `README.md:21-22`; `devcontainer-config/install.sh:42-43`, `:290-304`; `docs/decisions/037-bare-host-copy-install.md:50`; `test/install-host.bats:104-108`; `exp-E1-E5-E6-E7.txt` (E5); `bats-head.txt`

---

## Claim 3: "Its `~/.claude` review lists every symlink it will replace … and every file in those directories that the repo doesn't have (`MOVE to backup`). Check any line marked `WIRED in settings` … Everything replaced, including the old links, is moved to `~/.claude/.claude-workflows-backup/<UTC stamp>/`. … Your `settings.json`, memory, projects and logs are never touched." (same content as commit 6793b79's "lists every symlink it will replace (top-level and per-file), every foreign file it will move (flagging hooks wired in settings)")

**Location:** `README.md:26-33`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the top-level REPLACE lines, per-file REPLACE lines inside real directories (links into the checkout, links elsewhere, dangling links), MOVE lines for foreign files including a foreign skill dir, the WIRED flag for a foreign top-level hook, and byte-identity of settings, settings.local, projects, memory, logs and .credentials. Does not establish: that foreign *empty* directories are listed (the pre-pass finds only `-type f -o -type l`, so an empty foreign dir moves without a line); WIRED detection for foreign files in hooks subdirectories (it matches `hooks/$(basename "$f")`, so `hooks/lib/x.sh` is looked up as `hooks/x.sh`); or that the stamp dir is always exactly `<UTC stamp>` (a same-second rerun gets `<stamp>.<pid>`, Claim 12).
**Legibility-target:** for-orchestrator-synthesis

The pre-pass:

```bash
# devcontainer-config/install.sh:345-369
  for name in "${CLAUDE_HOME_NAMES[@]}"; do
    if [ -L "$dest/$name" ]; then
      echo "REPLACE symlink $dest/$name -> $(readlink "$dest/$name") with a copy"
      changed=1
    elif [ -d "$dest/$name" ]; then
      while IFS= read -r -d '' link; do
        echo "REPLACE symlink $link -> $(readlink "$link") with a copy"
        ...
      done < <(find "$dest/$name" -type l -print0 | sort -z)
      while IFS= read -r -d '' f; do
        rel="${f#"$dest/$name"/}"
        if [ -e "$stage/$name/$rel" ] || [ -L "$stage/$name/$rel" ]; then continue; fi
        ...
        line="MOVE to backup (not in the repo): $f"
        if [ "$name" = hooks ] && grep -qsF "hooks/$(basename "$f")" "$dest/settings.json" "$dest/settings.local.json"; then
          line="$line  <-- WIRED in settings: moving it breaks that hook"
        fi
        ...
      done < <(find "$dest/$name" \( -type f -o -type l \) -print0 | sort -z)
    fi
  done
```

T5 (REPLACE for all six top-level links and the per-file `hooks/h.sh`), T6 (links backed up as links, checkout unchanged), T7 (user state byte-identical), T13 (foreign skill dir moved) and T20 (WIRED) pass. E3 (`exp-E2-E4.txt`) shows a per-file hook link to a non-checkout file producing both a REPLACE line and a content diff (`-echo DIFFERENT` / `+exit 0`), and a foreign `skills/mine/SKILL.md` producing a MOVE line. E3c shows dangling top-level links (moved checkout) producing REPLACE lines and a full additive diff instead of an abort.

**Evidence:** `devcontainer-config/install.sh:345-378`, `:423-427`; `bats-head.txt` (T5, T6, T7, T13, T20); `exp-E2-E4.txt` (E3, E3c)

---

## Claim 4: "Exit status: 0 no target declined; 1 a target was declined, or an error; 2 bad arguments." and "Target 2 is SKIPPED, with a message and no effect on the exit status"

**Location:** `devcontainer-config/install.sh:40-49`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers exit 0 (`--yes`, host skipped), exit 1 (devcontainer decline, host decline, host refusal, a mid-install mv failure) and exit 2 (unknown argument). Does not establish the exit status when `cc-isolated.sh --bless` fails (not exercised, since it is a stub).
**Legibility-target:** for-orchestrator-synthesis

`install.sh:461-464` reads `DECLINED=0` / `install_devcontainer` / `install_claude_home` / `exit "$DECLINED"`. The skip branches `return 0` without setting DECLINED (Claim 1 quote). T3 (`--yes`, exit 0), T15 (exit 2), T17 and T19 (exit 1) and T14/T21 (refusal, exit 1) pass. E9 (`exp-E8-E9.txt`) prints `INSTALL_EXIT=1` after a mid-install failure.

**Evidence:** `devcontainer-config/install.sh:40-49`, `:461-464`; `bats-head.txt`; `exp-E8-E9.txt`

---

## Claim 5: "The line keeps its old wording, and the run still exits 1 because something was declined."

**Location:** `devcontainer-config/install.sh:192-195`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the text of the devcontainer decline line and the final exit status. Does not establish whether any external consumer matches the whole line exactly (none found in `test/`; T1 matches it as a substring).
**Legibility-target:** for-author

The old line was `*) echo "Aborted. Nothing was changed."; exit 1 ;;` (`git show 712c626:devcontainer-config/install.sh`, line 124). The new one is:

```bash
# devcontainer-config/install.sh:195
      echo "Aborted. Nothing was changed. (devcontainer config)"
```

E1 prints `Aborted. Nothing was changed. (devcontainer config)` for NEW and `Aborted. Nothing was changed.` for OLD. The old wording survives as a prefix, but it is not the same line. The exit-1 half is correct (E1 NEW closed: `[exit=1]`). A precise version: "the line keeps its old wording as a prefix."

**Evidence:** `devcontainer-config/install.sh:192-197`; `712c626:devcontainer-config/install.sh:124`; `exp-E1-E5-E6-E7.txt` (E1)

---

## Claim 6: "`diff` follows symlinks, so a migration from links to copies would review as "(none)". Hence the explicit REPLACE lines below." (with "`cp -r stage/skills ~/.claude/skills` writes INTO the checkout through the link")

**Location:** `devcontainer-config/install.sh:240-244`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers diff output through a per-file link into the checkout (empty) and through a link elsewhere (shows content). The cp/rm hazards were verified experimentally in the research doc, not re-run here. Does not establish that the installer never runs `cp` or `rm -rf` through a link (see Claim 9 for the guards).
**Legibility-target:** for-orchestrator-synthesis

In E3b a per-file `hooks/h.sh` link into the checkout produced a `REPLACE symlink …/hooks/h.sh` line and no `h.sh` hunk in the diff: only the files absent from the destination appear (`exp-E2-E4.txt`). In E3 the same link pointed at a different file, and a hunk appeared. The install path never calls `cp -r` onto a live name. It copies to `.cw-new.$name` and renames: `if ! cp -R "$stage/$name" "$dest/.cw-new.$name"; then ok=0; break; fi` (`install.sh:399`), then `mv "$dest/.cw-new.$name" "$dest/$name"` (`:436`).

**Evidence:** `devcontainer-config/install.sh:240-244`, `:399`, `:436`; `exp-E2-E4.txt` (E3, E3b)

---

## Claim 7: "The seven entry names, derived from CLAUDE_HOME_SRC so the host can never install a subset of the payload (FP-066)."

**Location:** `devcontainer-config/install.sh:246-250`
**Type:** Architectural / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the derivation, and that FP-066 exists in the failure-pattern library. Does not establish that FP-066's recorded symptom (a container session missing repo skills) is the same failure as a host subset install. It is analogous, not identical.
**Legibility-target:** for-orchestrator-synthesis

```bash
# devcontainer-config/install.sh:248-250
CLAUDE_HOME_NAMES=()
for _item in "${CLAUDE_HOME_SRC[@]}"; do CLAUDE_HOME_NAMES+=("$(basename "$_item")"); done
unset _item
```

Every host loop iterates `CLAUDE_HOME_NAMES`, and `assemble` exits on a missing source (`:115-119`). `docs/thoughts/failure-patterns.md:208` has `**FP-066** 2026-07-29 symptom:repo-skills-never-registered-in-any-container-session`.

**Evidence:** `devcontainer-config/install.sh:93`, `:248-250`, `:108-120`; `docs/thoughts/failure-patterns.md:208`

---

## Claim 8: "Skip rules come first: before this target reads or stages anything, so every non-interactive run (scripts, tests, --yes) is unchanged apart from this one line." (also 037: "every existing non-interactive devcontainer run is unchanged apart from one extra line" / "scripted callers see one extra line, not a new behavior"; and commit 6793b79: "Non-interactive devcontainer runs are otherwise unchanged")

**Location:** `devcontainer-config/install.sh:287-289`; `docs/decisions/037-bare-host-copy-install.md:33`, `:52`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the output and exit status of `</dev/null` and `--yes </dev/null` runs, old against new. Does not establish anything about runs with invalid arguments (Claim 21).
**Legibility-target:** for-author

The skip does come before any read or stage (Claim 1 quote). But the non-interactive output differs by more than one line. `install_claude_home` prints a blank line before the skip (`install.sh:286`: `  echo`), and the devcontainer decline line gained a suffix (Claim 5). E1 old vs new, `</dev/null`:

```
OLD: Install this config and bless it? [y/N] Aborted. Nothing was changed.
NEW: Install this config and bless it? [y/N] Aborted. Nothing was changed. (devcontainer config)
     <blank>
     Skipped host target (~/.claude): it needs an interactive terminal (stdin is not a TTY). ...
```

Exit status is unchanged (1 and 0). A precise version: "a blank line plus one skip line, and the decline line gains a ' (devcontainer config)' suffix."

**Evidence:** `devcontainer-config/install.sh:286-304`, `:195`; `exp-E1-E5-E6-E7.txt` (E1)

---

## Claim 9: "Neither check stops an agent that sets out to fake a terminal (`script` gives it a pty; `env -u` drops CLAUDECODE)." (037: "In this session the Bash tool has no TTY … util-linux `script` can wrap the installer in a pty")

**Location:** `devcontainer-config/install.sh:290-292`; `docs/decisions/037-bare-host-copy-install.md:50`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers util-linux `script` on this Linux sandbox. Does not establish availability on macOS (BSD `script` takes different arguments) or 037's specific "fd 0 is /dev/null" observation (only `[ -t 0 ]` was checked).
**Legibility-target:** for-orchestrator-synthesis

E5, run with `CLAUDECODE=1` set around the wrapper, printed `stdin-is-tty` and `CLAUDECODE=unset` inside `script -qec 'env -u CLAUDECODE bash -c …' /dev/null`, and `[outside: not-tty]` for the agent's own Bash tool.

**Evidence:** `devcontainer-config/install.sh:290-292`; `exp-E1-E5-E6-E7.txt` (E5)

---

## Claim 10: "Guards: nothing below may write through a link into the checkout." (commit 6793b79: "Refuses a destination, backup dir or .cw-new.* leftover that is a symlink into (or resolves inside) the checkout.")

**Location:** `devcontainer-config/install.sh:309-331`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a destination that is a symlink into the checkout, a dangling-link destination, a symlinked backup root, a backup root resolving inside the checkout, and `.cw-new.*` symlinks. Does not establish any refusal or notice for a destination that is a symlink to a non-checkout directory. That case is followed silently: E2 installed through `~/.claude -> elsewhere` into the target, and the review's `Destination:` line did not mention the link. It also does not establish that `.cw-new.*` real directories are preserved (they are `rm -rf`'d, `:398`).
**Legibility-target:** for-orchestrator-synthesis

```bash
# devcontainer-config/install.sh:310-331
  if [ -L "$dest" ] && [ ! -d "$dest" ]; then
    host_refuse "$dest is a dangling symlink ..."
  fi
  if [ -e "$dest" ] && [ ! -d "$dest" ]; then
    host_refuse "$dest exists and is not a directory."
  fi
  if inside_repo "$(resolve_phys "$dest")"; then
    host_refuse "$dest resolves inside the repo checkout ..."
  fi
  local bkroot="$dest/.claude-workflows-backup"
  if [ -L "$bkroot" ]; then
    host_refuse "$bkroot is a symlink ..."
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

T14 (destination symlink into the checkout) and T21 (planted backup symlink) pass with the checkout snapshot unchanged. A pre-planted `$bkroot/<stamp>` is also safe (paraphrased — no quote available because this is inferred from the two branches at `:417-418`, not run). An existing target makes `[ -e ]` true, so the `.$$` suffix is taken. A dangling one makes `mkdir -p` fail, which removes the `.cw-new.*` copies and exits.

**Evidence:** `devcontainer-config/install.sh:255-277`, `:309-331`, `:416-422`; `bats-head.txt` (T14, T21); `exp-E2-E4.txt` (E2)

---

## Claim 11: "Content diff: the same review_diff the devcontainer target uses. Through a symlinked entry it compares the link's target (the checkout) with the stage."

**Location:** `devcontainer-config/install.sh:370-374`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers per-file links (E3, E3b) and dangling top-level links (E3c: they diff as absent, so the change shows as additions and does not abort). "(the checkout)" is the typical target, not the only one: a link elsewhere compares that target. Does not establish behavior for a link to an unreadable target (would be diff exit 2 and an abort, per `:149-151`).
**Legibility-target:** for-orchestrator-synthesis

`if ! review_diff "$dest" "$stage" "${CLAUDE_HOME_NAMES[@]}"; then` (`install.sh:372`) calls the same function as `install_devcontainer` (`:180`). The outputs are in Claims 3 and 6.

**Evidence:** `devcontainer-config/install.sh:133-155`, `:370-374`; `exp-E2-E4.txt`

---

## Claim 12: "Installs by copying to .cw-new.<name>, moving the old entries (links as links) to .claude-workflows-backup/<UTC stamp>/, then swapping in. A copy failure undoes itself before touching a live entry." (code: "1. Copy every entry beside its target. Any failure: undo and stop before a single live entry is touched.")

**Location:** `devcontainer-config/install.sh:392-437` (commit 6793b79)
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the step-1 copy-failure undo (T16), links moved as links (T6), and sequential same-second reruns (E7: the second run used `<stamp>.415425`). **Does not establish any recovery for a failure in step 2 or 3.** E4/E9 made `hooks` non-renamable. `CLAUDE.md, skills, workflows, guides, patterns` had already moved to the backup, the run died on the raw `mv: cannot move … Permission denied` with exit 1, and the destination was left without CLAUDE.md or skills and with all seven `.cw-new.*` directories beside it. No line names the backup dir or says how to finish or roll back. The claim is only about copy failures, so this residue is not a contradiction. Concurrent runs are also not covered: two runs in the same second can both pass `[ -e "$backup" ]` before either `mkdir -p` (not run).
**Legibility-target:** for-orchestrator-synthesis (the step-2/3 residue is a for-author item for the critics)

```bash
# devcontainer-config/install.sh:394-437
  local ok=1
  mkdir -p "$dest" 2>/dev/null || ok=0
  if [ "$ok" -eq 1 ]; then
    for name in "${CLAUDE_HOME_NAMES[@]}"; do
      rm -rf "$dest/.cw-new.$name"
      if ! cp -R "$stage/$name" "$dest/.cw-new.$name"; then ok=0; break; fi
    done
  fi
  if [ "$ok" -eq 0 ]; then
    for name in "${CLAUDE_HOME_NAMES[@]}"; do rm -rf "$dest/.cw-new.$name" 2>/dev/null || true; done
    echo "ERROR: could not copy the new files into $dest; nothing was replaced." >&2
    exit 1
  fi
  ...
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

E4 left behind (`exp-E2-E4.txt`): dest `hooks scripts .cw-new.{all seven} .claude-workflows-backup`, and a backup holding `CLAUDE.md guides patterns skills workflows`.

**Evidence:** `devcontainer-config/install.sh:392-437`; `bats-head.txt` (T6, T16); `exp-E1-E5-E6-E7.txt` (E7); `exp-E2-E4.txt` (E4); `exp-E8-E9.txt` (E9)

---

## Claim 13: "Writes .claude-workflows-manifest (rm -f first) with installed_by, installed_parent and installed_at appended" (commit 6793b79 notes: "installed_parent records "script" when the installer ran under a pty wrapper"); code: "`rm -f` first so a planted symlink cannot redirect the write."

**Location:** `devcontainer-config/install.sh:439-447`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the manifest keys, the symlink-replacement guarantee, and `installed_parent=script` when run as `script -qec "bash install.sh"`. Does not establish that `installed_parent` is `script` under other wrappings. A wrapper that interposes a shell (`script -c "sh -c 'bash install.sh; …'"`) or `setsid` would record something else, so it is an audit trace, not a proof. `installed_by=host-tty` is a constant and asserts nothing measured.
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

E6 manifest: `commit=… dirty=no assembled_from=… installed_by=host-tty installed_parent=script installed_at=20260923T233450Z`. T6 plants a symlinked manifest and asserts `[ ! -L … ]` afterwards. T10 asserts the commit, source and installer keys.

**Evidence:** `devcontainer-config/install.sh:439-447`; `bats-head.txt` (T6, T10); `exp-E1-E5-E6-E7.txt` (E6)

---

## Claim 14: "Destination: $CLAUDE_HOME_DIR, else $CLAUDE_CONFIG_DIR, else ~/.claude; the review names which variable chose it." (README: "`~/.claude` (or `$CLAUDE_CONFIG_DIR` if you set it)")

**Location:** `devcontainer-config/install.sh:281-284`, `:307`; `README.md:19`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the precedence and the `Destination: … (chosen by …)` line. The README omits `CLAUDE_HOME_DIR` precedence, which is harmless for users who don't set it. Does not establish that Claude Code itself reads `$CLAUDE_CONFIG_DIR` as its config root.
**Legibility-target:** for-orchestrator-synthesis

`if [ -n "${CLAUDE_HOME_DIR:-}" ]; then dest="$CLAUDE_HOME_DIR"; label='$CLAUDE_HOME_DIR'` / `elif [ -n "${CLAUDE_CONFIG_DIR:-}" ]; …` (`install.sh:281-282`). T24 passes (CLAUDE_CONFIG_DIR chooses the destination, and HOME/.claude stays absent).

**Evidence:** `devcontainer-config/install.sh:281-284`, `:307`; `bats-head.txt` (T24)

---

## Claim 15: "Until it lands, every install.sh commit still carries a `Live-verified:` trailer by hand."

**Location:** `docs/decisions/035-install-sh-gating.md:86-92`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two commits in this range that touch install.sh (1514518, 6793b79). Does not establish anything about commits outside the range, or whether either trailer's host check has been done (both say `Live-verified: no`).
**Legibility-target:** for-orchestrator-synthesis

1514518: `Live-verified: no — run ./devcontainer-config/install.sh on the host and confirm the devcontainer diff, prompt and bless behave as before (plan step 9)`. 6793b79: `Live-verified: no — on the host run ./devcontainer-config/install.sh, read the ~/.claude review …` (from `git log --format=%B 712c626..d0fdd04`).

**Evidence:** `docs/decisions/035-install-sh-gating.md:86-92`; commits 1514518, 6793b79

---

## Claim 16: "Provenance is `~/.claude/.claude-workflows-manifest`, in the same format link-claude-home writes."

**Location:** `docs/decisions/037-bare-host-copy-install.md:38`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the file name and base keys. The host version adds three keys (`installed_by/parent/at`). Does not establish that any consumer (health-check) tolerates the extra keys.
**Legibility-target:** for-orchestrator-synthesis

`devcontainer-config/link-claude-home.sh:70-71`: `if [ -f "$SRC/.manifest" ]; then` / `cp -f "$SRC/.manifest" "$DEST/.claude-workflows-manifest" 2>/dev/null || true`. The host target copies the same `assemble`-written `.manifest` to the same name (`install.sh:442`), then appends (Claim 13).

**Evidence:** `devcontainer-config/link-claude-home.sh:70-71`; `devcontainer-config/install.sh:121-127`, `:441-447`

---

## Claim 17: "The check stops accidents, not intent. The backstop is sandbox `denyWrite ~/.claude` (guide §3)."

**Location:** `docs/decisions/037-bare-host-copy-install.md:50`
**Type:** Invariant
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers only that guide §3 recommends `denyWrite` on `~/.claude`. Does not establish: that the user's host has it set; that it applies to an installer launched via `script` from the sandboxed Bash tool (it should, as a child of the sandboxed process, but this was not run); or that an agent can't reach install.sh unsandboxed (`dangerouslyDisableSandbox`, excluded commands). The "first part" ("stops accidents, not intent") is established by Claim 9.
**Legibility-target:** for-orchestrator-synthesis

`guides/bare-host-hook-wiring.md:74-76`: "`denyWrite` to `~/.claude`, `~/CLAUDE.md` and the auditor script. … Bash sees `~/.claude` as read-only." Execution required: a sandboxed agent Bash call on the user's host running `script -qec 'env -u CLAUDECODE ./devcontainer-config/install.sh' /dev/null` against a canary CLAUDE_CONFIG_DIR under `~/.claude`. That is blocked here because it would need the host's settings.json sandbox block and the real `~/.claude`.

**Evidence:** `docs/decisions/037-bare-host-copy-install.md:50`; `guides/bare-host-hook-wiring.md:74-76`

---

## Claim 18: "The installer copies the whole `hooks/` directory (including `hooks/lib/`) and the whole `scripts/` directory, so hooks that find their helpers by their own path (`log-usage.sh` → `lib/usage-common.sh` and `../scripts/lib/`; `claude-config-audit.sh` → `../scripts/claude_config_audit.py`) keep working."

**Location:** `guides/bare-host-hook-wiring.md:16-21`
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers log-usage.sh end to end (T9 with the real hooks/ and scripts/) and the static paths of claude-config-audit.sh. Does not establish a run of claude-config-audit.sh from the installed copy. "Every hook is a copy" holds because the repo's payload dirs contain no symlinks today (`find skills workflows guides patterns hooks scripts -type l` returned nothing). `cp -r` would copy a future in-repo symlink as a link.
**Legibility-target:** for-orchestrator-synthesis

`hooks/log-usage.sh:11`: `source "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/lib/usage-common.sh"`, and `:14`: `…/../scripts/lib/skill-paths.sh"`. `hooks/claude-config-audit.sh:47-48`: `HOOK_DIR=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")` / `AUDIT_SCRIPT="$HOOK_DIR/../scripts/claude_config_audit.py"`. T9 passes: the installed `log-usage.sh` exits 0 and writes `"smoke"` to the hermetic usage log.

**Evidence:** `guides/bare-host-hook-wiring.md:16-21`; `hooks/log-usage.sh:11-14`; `hooks/claude-config-audit.sh:43-49`; `bats-head.txt` (T9)

---

## Claim 19: "`install.sh` does not write `settings.json`, but it prints a `REMINDER` pointing here whenever the installed `hooks/wiring.json` is missing or differs from the repo's."

**Location:** `guides/bare-host-hook-wiring.md:61-63`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the missing, unchanged and changed cases after a y. Does not establish a reminder when the user declines (none is printed) or whether the reminder names the correct §2 anchor text.
**Legibility-target:** for-orchestrator-synthesis

`if ! cmp -s "$dest/hooks/wiring.json" "$stage/hooks/wiring.json"; then` / `wiring_changed=1` (`install.sh:382-383`). The REMINDER is printed at `:453-458`. No path in the function writes `settings.json` (it is only read by `grep` at `:362`). T7 (settings byte-identical) and T11 pass.

**Evidence:** `devcontainer-config/install.sh:381-384`, `:453-458`; `bats-head.txt` (T7, T11)

---

## Claim 20: "`claude-config-audit.sh` looks for the auditor at `CLAUDE_CONFIG_AUDIT_SCRIPT`, then `<hook dir>/../scripts/`, then `~/private_reviews/`. … With the `install.sh` copy, the second of those is `~/.claude/scripts/claude_config_audit.py`"

**Location:** `guides/bare-host-hook-wiring.md:82-85`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the resolution order. Does not establish the "If it finds none, the hook does nothing" branch (not re-read past `:49`).
**Legibility-target:** for-orchestrator-synthesis

`hooks/claude-config-audit.sh:43-49`: `if [[ -n "${CLAUDE_CONFIG_AUDIT_SCRIPT:-}" ]]; then` … `AUDIT_SCRIPT="$HOOK_DIR/../scripts/claude_config_audit.py"` / `[[ -f "$AUDIT_SCRIPT" ]] || AUDIT_SCRIPT="$HOME/private_reviews/claude_config_audit.py"`. With the hook copied to `~/.claude/hooks`, `readlink -f` resolves to itself, so `HOOK_DIR/..` is `~/.claude`.

**Evidence:** `hooks/claude-config-audit.sh:43-49`; `guides/bare-host-hook-wiring.md:82-87`

---

## Claim 21: "exit 2 for an unknown argument is the only observable change, and only for invalid input."

**Location:** commit 1514518 (message body); `devcontainer-config/install.sh:53-61`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers argument handling old vs new, and line-by-line equivalence of the refactored devcontainer flow at 1514518 (`git diff 712c626 1514518`: the diff, prompt, copy, chmod, link and bless code is moved into functions unchanged). Does not establish anything about the later 6793b79 changes (Claims 5 and 8).
**Legibility-target:** for-author

The old code was `ASSUME_YES="${1:-}"`, so any argument other than `--yes` fell through to the normal prompting run. The new loop:

```bash
# devcontainer-config/install.sh:54-61
while [ $# -gt 0 ]; do
  case "$1" in
    --yes) ASSUME_YES="--yes" ;;
    -h|--help) usage; exit 0 ;;
    *) echo "install.sh: unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done
```

`-h/--help` is a second observable change. E8: OLD `-h` assembled the payload and started the review (`Canonical (repo): …`). NEW `-h` prints `Usage:` and exits 0 having done nothing. Also, `--yes extra` used to install (OLD `[exit=0] devc installed? yes`) and now exits 2 (NEW `[exit=2] devc installed? no`). That one is covered by "unknown argument". A precise version: "unknown arguments exit 2, and -h/--help print usage; both only for arguments the old script ignored."

**Evidence:** `devcontainer-config/install.sh:53-61`; `712c626:devcontainer-config/install.sh` (`ASSUME_YES="${1:-}"`); `exp-E8-E9.txt` (E8)

---

## Claim 22: "Declining the devcontainer target now continues to the host target; the run still exits 1 when anything was declined."

**Location:** commit 6793b79; `devcontainer-config/install.sh:190-198`, `:461-464`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers devcontainer-n then host-n (exit 1), devcontainer-y then host-n (exit 1), and devcontainer-n then host-y (DECLINED stays 1, so exit 1: static from `:196` and `:464`). Does not establish the n/y exit status under test (T6 does not assert status).
**Legibility-target:** for-orchestrator-synthesis

`echo "Aborted. Nothing was changed. (devcontainer config)"` / `DECLINED=1` / `return 0` (`install.sh:195-197`). T5 and T17 (`n\nn\n`) reach the host prompt. T17 and T19 assert `status -eq 1`.

**Evidence:** `devcontainer-config/install.sh:190-198`, `:386-390`, `:461-464`; `bats-head.txt` (T5, T17, T19)

---

## Claim 23: "All 24 fail against the current install.sh (T7 and T16 were tightened so they cannot pass when nothing is installed)."

**Location:** commit dcf4a6d
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers dcf4a6d's tree, whose install.sh is byte-identical to 712c626's (`diff` printed `same`). Does not establish why each test fails (for example, T15 fails on exit status, not on a host-target assertion).
**Legibility-target:** for-orchestrator-synthesis

`bats-old.txt`: `not ok 1` through `not ok 24`, exit=1. T7 and T16 carry the tightening guards `[ -d "$CLAUDE_HOME_DIR/skills" ] && [ ! -L "$CLAUDE_HOME_DIR/skills" ]   # the install ran` and `[[ "$output" == *'nothing was replaced'* ]]` (`test/install-host.bats`, T7 and T16 bodies).

**Evidence:** `test/install-host.bats` (T7, T16); `bats-old.txt`

---

## Claim 24: "test/install-host.bats 24/24 · test/cc-isolated-functions.bats 90/90 (unmodified) · test/link-claude-home-wiring.bats 14/14 · test/hooks/*.bats 144/144 (6 files) · guide-index-sync, cross-reference-integrity, fixture-hermeticity pass · scripts/run-tests.sh --fast: 864 ok, 0 not ok"

**Location:** commit d0fdd04 (also 1514518's and 6793b79's "90/90" and "24/24")
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every listed number at HEAD d0fdd04 in this Linux sandbox. Does not establish the counts at the intermediate commits 1514518 and 6793b79, or macOS behavior.
**Legibility-target:** for-orchestrator-synthesis

The runs gave: install-host 24 ok and 0 not ok (`bats-head.txt`); cc-isolated-functions 90/0, link-claude-home-wiring 14/0, guide-index-sync 1/0, cross-reference-integrity 1/0, fixture-hermeticity 2/0, test/hooks 144/0 across 6 files (`suites-summary.txt`); run-tests.sh --fast 864/0, exit 0 (`run-tests-fast.txt`). `git diff 712c626..d0fdd04 --stat -- test/cc-isolated-functions.bats` is empty, so that file is unmodified.

**Evidence:** `bats-head.txt`; `suites-summary.txt`; `run-tests-fast.txt`

---

## Claims Requiring Attention

### Incorrect
- **Claim 2** (`README.md:21-22`, `devcontainer-config/install.sh:42-43`): "only installs for a human at a terminal" is false. An agent's Bash tool clears both checks with `env -u CLAUDECODE script -qec … /dev/null`, and this branch's own test suite does it. Reword to match install.sh:290-292 and 037 ("stops the accidental run, not a deliberate one; the backstop is sandbox denyWrite ~/.claude").

### Mostly Accurate
- **Claim 5** (`devcontainer-config/install.sh:192-195`): the decline line keeps its old wording only as a prefix. It now ends with " (devcontainer config)".
- **Claim 8** (`devcontainer-config/install.sh:287-289`, `docs/decisions/037-bare-host-copy-install.md:33,52`, commit 6793b79): non-interactive output changes by a blank line plus the skip line, and the decline line is reworded. It is not "one extra line".
- **Claim 21** (commit 1514518): `-h/--help` is a second observable change. It used to run the installer and now prints usage and exits 0.

### Unverifiable
- **Claim 17** (`docs/decisions/037-bare-host-copy-install.md:50`): that sandbox `denyWrite ~/.claude` backstops a `script`-wrapped agent run needs a sandboxed agent run on the user's host against a canary dir.

### Residues on Verified claims (the verdict holds for the scoped property; the adjacent behavior is unguarded)
- **Claim 12**: a failure after the first move-aside (step 2/3) leaves the destination partial. The first 1–6 entries are in the backup, the rest are live, and the `.cw-new.*` copies sit beside them. The only message is the raw `mv` error, with no backup path and no recovery instruction (E4/E9, exit 1). Concurrent same-second runs can share a stamp dir (static).
- **Claim 10**: a destination that is a symlink to a non-checkout directory is written through silently, and the review does not say the destination is a link (E2).
- **Claim 3**: foreign empty directories move without a MOVE line. WIRED detection uses the basename only, so a nested foreign `hooks/lib/x.sh` is checked as `hooks/x.sh`.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the output path your task names, structured per your skill, beginning with a `Commit: d0fdd04` line.
- Answered: yes. All eight brief claim groups are verdicted, seven of them by hermetic execution.
- Out of scope: macOS behavior (BSD `script`, `sort -z`); the host's live sandbox settings; code-quality judgments on the residues (left to the critics).
- Escalate: Claim 2 (README and `--help` overstate the TTY guard as human-only), and Claim 12's residue (no recovery message for a mid-swap failure on the user's live `~/.claude`), before the plan-step-9 host run.
