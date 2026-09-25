Commit: d0fdd04

# Code Fact-Check Report

**Repository:** claude-workflows (worktree `/workspace/.claude/wt-copyinstall`, branch `ans/copy-install`)
**Scope:** diff `712c626..d0fdd04`: README.md, devcontainer-config/install.sh (whole file read, 464 lines), docs/decisions/037-bare-host-copy-install.md, guides/bare-host-hook-wiring.md, and the commit messages of 1514518, 6793b79, dcf4a6d and d0fdd04. The docs/working and docs/reviews files on the branch were read as context only. Decision 035's note and guides/README.md hold no executable claims beyond those covered here.
**Checked:** 2026-09-23
**Total claims checked:** 27
**Summary:** 18 verified, 5 mostly accurate, 0 stale, 2 incorrect, 2 unverifiable

Execution provenance. Every executed claim ran hermetically: HOME, CLAUDE_HOME_DIR, CLAUDE_DEVC_CONFIG_DIR, CLAUDE_DEVC_BIN_DIR and TMPDIR all sat under a scratch dir, CLAUDE_CONFIG_DIR was unset, and CLAUDECODE was unset for the child. The installer was a copy inside a throwaway git repo built by the same `fake_repo` recipe as `test/install-host.bats`. The y path ran through `script -qec CMD /dev/null`. Captured output, with bash's locale warnings stripped, is in `docs/reviews/execution-logs/cfc-copy-install-r3/`. The driver scripts (`probe.sh`, `probe9.sh`, `run-suites.sh`) are saved beside the logs.
- Probes: `bash probe.sh` then `bash probe9.sh`, cwd the scratch dir `…/scratchpad/cfc-r3`, both exit 0. Started 2026-09-23T23:32:30Z (`probe-timestamp.txt`). Output is in `probe.txt` and `probe9.txt`, one `######## Pn …` section per case, with each run's installer exit code printed as `[exit=N]`.
- Suites: `bash run-suites.sh`, exit 0, started 2026-09-23T23:32:30Z (`timestamp.txt`). It extracts `git archive d0fdd04` and `git archive dcf4a6d` into scratch trees and runs `bats` from each tree's root. `bats test/hooks/` ran at 2026-09-23T23:34Z (`hooks-timestamp.txt`), exit 0. Per-suite exit codes are in `exits.txt`.

Note for the orchestrator: sibling agents share `scratchpad/fc/`. My first draft of `fc/probe.sh` and `fc/run-suites.sh` collided with a sibling's files of the same names there: one of my Writes overwrote a pre-existing `fc/probe.sh`. All evidence below comes from the isolated `scratchpad/cfc-r3/` copies. A sibling that relied on `fc/probe.sh` may have run my content.

---

## Claim 1: "The `~/.claude` target only installs for a human at a terminal. It is skipped with `--yes`, from a script with no TTY, and inside a Claude Code session."

**Location:** `README.md:21-23`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three skip triggers (`--yes`, a non-TTY stdin, `CLAUDECODE` set) on HEAD; it does not establish that "only for a human" holds against an agent that fakes a pty and drops `CLAUDECODE` (Claim 5c shows it does not, as 037 itself says).

The code at `devcontainer-config/install.sh:293-304`:
```bash
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
Executed: P1a (stdin `/dev/null`) printed the TTY skip line. P1c (`--yes </dev/null`) printed the `--yes` skip line, and `ls -A $HOME` showed only `.config` and `.local`. P2 (a pty with `CLAUDECODE=1` and the answers `n,y`) printed the CLAUDECODE skip line.

**Evidence:** `devcontainer-config/install.sh:293-304`; `docs/reviews/execution-logs/cfc-copy-install-r3/probe.txt` (sections P1a, P1c, P2)
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 2a: "Its `~/.claude` review lists every symlink it will replace (`REPLACE symlink … with a copy`) and every file in those directories that the repo doesn't have (`MOVE to backup`)."

**Location:** `README.md:26-29`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the review's pre-pass for top-level links, per-file links and foreign files, including a foreign skill directory. It does not establish that the review completes when an install-owned directory holds a dangling symlink, which it does not.

The listing is real. In P3 the review printed a `REPLACE symlink` line for each of the six top-level links and for each per-file hook link, plus `MOVE to backup (not in the repo)` for `mine.sh`, `foreignlink.sh` and `dangling.sh`, with `<-- WIRED in settings` on `mine.sh`. The same P3 run then aborted before the prompt, because `diff -ruN` exits 2 on a dangling symlink nested inside an owned directory (probe.txt, P3):
```
diff: …/p3/home/.claude/hooks/dangling.sh: No such file or directory
ERROR: could not diff payload item 'hooks' (diff exit 2).
       The review diff is incomplete, so nothing was installed.
[exit=1]
```
The abort comes from `review_diff`'s `*)` branch (`devcontainer-config/install.sh:149-151`), which `install_claude_home` calls at `:372`. The error names `hooks` but not the dangling path; the only pointer to the file is diff's own stderr line. A migrating user with one stale per-file link (a removed hook, a hand-made link, or a checkout that moved while the hooks dir was real) cannot complete the migration until they find and delete it by hand. The README gives them no guidance for that. A dangling top-level link does not trigger the abort. P9 (`probe9.txt`) had `CLAUDE.md` dangling: it reviewed as `REPLACE symlink`, installed, and moved the link to the backup, because `-N` treats an unreadable top-level operand as absent. The review also mislabels foreign per-file links (see Claim 7).

**Evidence:** `README.md:26-29`; `devcontainer-config/install.sh:145-151`, `:345-374`; `docs/reviews/execution-logs/cfc-copy-install-r3/probe.txt` (P3), `probe9.txt` (P9)
**Legibility-target:** for-author

---

## Claim 2b: "Everything replaced, including the old links, is moved to `~/.claude/.claude-workflows-backup/<UTC stamp>/`. … Your `settings.json`, memory, projects and logs are never touched."

**Location:** `README.md:31-33`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the seven install-owned names moving to the backup and the untouched host-state paths on a successful install. It does not establish the state after a failure between move-aside and swap-in (see Claim 10).

Only the seven names are moved (`devcontainer-config/install.sh:423-427`: `for name in "${CLAUDE_HOME_NAMES[@]}"; do … mv "$dest/$name" "$backup/$name"`). Besides them, the installer writes only `.cw-new.*`, the backup and `.claude-workflows-manifest` (`:398-399`, `:418`, `:441-447`). Executed: `test/install-host.bats` T6 ("links backed up as links") and T7 ("user state in the destination is byte-identical after an install") both pass at HEAD. In P9 the dangling `CLAUDE.md` link was moved to `.claude-workflows-backup/20260923T233418Z`.

**Evidence:** `devcontainer-config/install.sh:398-447`; `docs/reviews/execution-logs/cfc-copy-install-r3/head-install-host.txt` (ok 6, ok 7), `probe9.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 3: "The line keeps its old wording, and the run still exits 1 because something was declined."

**Location:** `devcontainer-config/install.sh:192-195`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the devcontainer decline message and the exit code for a declined run. It does not establish anything about a caller that matches the whole line exactly (none in the repo's tests; `test/cc-isolated-functions.bats:640` does a substring match).

The line gained a suffix (`:195`: `echo "Aborted. Nothing was changed. (devcontainer config)"`). The old script printed `Aborted. Nothing was changed.` (`git show 712c626:devcontainer-config/install.sh`, the `*) echo "Aborted. Nothing was changed."; exit 1 ;;` arm). Executed: P1a (HEAD) printed `… Aborted. Nothing was changed. (devcontainer config)` then `[exit=1]`; P1b (712c626) printed `… Aborted. Nothing was changed.` then `[exit=1]`. The exit-1 half holds; "keeps its old wording" is true only of the prefix. A more precise comment would say: the old wording plus a ` (devcontainer config)` suffix.

**Evidence:** `devcontainer-config/install.sh:190-198`; `test/cc-isolated-functions.bats:640`; `docs/reviews/execution-logs/cfc-copy-install-r3/probe.txt` (P1a, P1b)
**Legibility-target:** for-author

---

## Claim 4: "`diff` follows symlinks, so a migration from links to copies would review as '(none)'. Hence the explicit REPLACE lines below."

**Location:** `devcontainer-config/install.sh:243-244`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers GNU diff dereferencing top-level and nested symlinks, and the REPLACE lines filling the gap. It does not establish the same behavior for BSD/macOS diff (not run; the commit's Notes flag macOS as untested).

In P3 the content diff printed no hunks for the five top-level directory links or `CLAUDE.md`, all of which point into the checkout. The only hunks were for files absent from one side. The six `REPLACE symlink … with a copy` lines appeared first. P3b shows the dereference in the other direction: a per-file link `skills/a/SKILL.md -> old-skill.md` produced `-OLD CONTENT` / `+skill a`, so diff compared the link's target content.

**Evidence:** `devcontainer-config/install.sh:240-244`, `:345-353`, `:370-374`; `docs/reviews/execution-logs/cfc-copy-install-r3/probe.txt` (P3, P3b)
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 5a: "Skip rules come first: before this target reads or stages anything … A skip is not a decline and does not change the exit status."

**Location:** `devcontainer-config/install.sh:287-289` (same claim: `docs/decisions/037-bare-host-copy-install.md:33-34`, commit 6793b79 body)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the ordering (skip checks at `:293-304` come before the guards at `:310+`, `mktemp` at `:333` and `assemble` at `:335`) and the exit status on a skip. It does not establish the claim that output is unchanged (Claim 5b).

Before the skip checks, `install_claude_home` only picks `dest`/`label` from environment variables and runs `echo` (`:280-286`). The skip branches `return 0` without setting `DECLINED`. Executed: P1c (`--yes`, the devcontainer target accepted, the host skipped) exited `[exit=0]`.

**Evidence:** `devcontainer-config/install.sh:279-304`, `:461-464`; `docs/reviews/execution-logs/cfc-copy-install-r3/probe.txt` (P1c)
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 5b: "so every non-interactive run (scripts, tests, --yes) is unchanged apart from this one line."

**Location:** `devcontainer-config/install.sh:287-289` (also `docs/decisions/037-bare-host-copy-install.md:33` "one extra line", `:52` "scripted callers see one extra line", and 6793b79 "Non-interactive devcontainer runs are otherwise unchanged")
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers stdout of a non-interactive run, HEAD against 712c626. It does not establish anything about callers' parsing of that output.

A non-interactive run gains two lines, not one: `install_claude_home` prints a blank line (`:286`: `  echo`) before the skip message. A declined non-interactive run also sees the abort line's new suffix (Claim 3). Executed: P1a (HEAD, stdin `/dev/null`) ends `Aborted. Nothing was changed. (devcontainer config)` / (blank) / `Skipped host target …` / `[exit=1]`; P1b (712c626) ends `Aborted. Nothing was changed.` / `[exit=1]`. The exit status and the files written are unchanged.

**Evidence:** `devcontainer-config/install.sh:286-304`, `:195`; `docs/reviews/execution-logs/cfc-copy-install-r3/probe.txt` (P1a, P1b)
**Legibility-target:** for-author

---

## Claim 5c: "Neither check stops an agent that sets out to fake a terminal (`script` gives it a pty; `env -u` drops CLAUDECODE)."

**Location:** `devcontainer-config/install.sh:290-291` (same claim: `docs/decisions/037-bare-host-copy-install.md:50`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers util-linux `script` and `env -u CLAUDECODE` defeating the TTY and CLAUDECODE checks in this sandbox. It does not establish whether a host sandbox `denyWrite` would then stop the writes (Claim 15).

Executed from this agent's Bash tool, which has no TTY (Claim 14): `printf 'n\ny\n' | script -qec "env -u CLAUDECODE $INSTALL" /dev/null` completed the host install in P4, P7, P8 and P9, e.g. P9: `Installed into …/p9/home/.claude.`

**Evidence:** `devcontainer-config/install.sh:290-304`; `docs/reviews/execution-logs/cfc-copy-install-r3/probe.txt` (P4, P8), `probe9.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 6: "Refuses a destination, backup dir or .cw-new.* leftover that is a symlink into (or resolves inside) the checkout." (commit 6793b79; comment "nothing below may write through a link into the checkout")

**Location:** `devcontainer-config/install.sh:309-331`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a destination symlinked into the checkout (refused), a destination symlinked to a real non-checkout directory (installs through the link into that directory), a symlinked `.claude-workflows-backup` (refused, T21), and a `.cw-new.*` symlink (refused on `-L`, whatever its target). It does not establish time-of-check/time-of-use safety between these checks and the writes at `:395-447`, and it does not establish a guard on a per-stamp backup subdirectory beyond the `-e` test at `:417`.

```bash
# devcontainer-config/install.sh:316-318
  if inside_repo "$(resolve_phys "$dest")"; then
    host_refuse "$dest resolves inside the repo checkout ($REPO_ROOT). Installing there would edit the repo, not install a copy."
  fi
```
Executed: P5 (`~/.claude -> repo`) printed `ERROR: … resolves inside the repo checkout …` and `[exit=1]`; `git status --porcelain` in the fake repo printed nothing. P4 (`~/.claude -> realclaude`, outside the repo) installed all seven entries and the manifest into `realclaude` and left the link intact. T14 and T21 pass at HEAD.

**Evidence:** `devcontainer-config/install.sh:255-331`; `docs/reviews/execution-logs/cfc-copy-install-r3/probe.txt` (P4, P5), `head-install-host.txt` (ok 14, ok 21)
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 7: "REPLACE symlink $link -> $(readlink "$link") with a copy" (the per-file review line; 6793b79: "The review lists every symlink it will replace (top-level and per-file)")

**Location:** `devcontainer-config/install.sh:350-353`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the per-file REPLACE line for a symlink the repo has no counterpart for. It does not affect per-file links whose name exists in the repo (those are correctly labelled).

```bash
# devcontainer-config/install.sh:350-353
      while IFS= read -r -d '' link; do
        echo "REPLACE symlink $link -> $(readlink "$link") with a copy"
        changed=1
      done < <(find "$dest/$name" -type l -print0 | sort -z)
```
The loop prints a REPLACE line for every symlink found, without checking that the stage has the path. A foreign per-file link gets no copy; it is only moved to the backup. The review therefore contradicts itself. In P3, `hooks/foreignlink.sh -> …/other.sh` and `hooks/dangling.sh -> …/elsewhere.sh` each printed `REPLACE symlink … with a copy` and then, a few lines later, `MOVE to backup (not in the repo): …`. A reader who stops at the REPLACE line expects that hook to keep working as a copy. What the code actually does: it moves the link, and nothing replaces it.

**Evidence:** `devcontainer-config/install.sh:345-368`; `docs/reviews/execution-logs/cfc-copy-install-r3/probe.txt` (P3)
**Legibility-target:** for-author

---

## Claim 8: "Content diff: the same review_diff the devcontainer target uses. Through a symlinked entry it compares the link's target (the checkout) with the stage."

**Location:** `devcontainer-config/install.sh:370-371`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers review_diff being shared and dereferencing links. It does not establish that the target is the checkout; the parenthetical assumes the README's old install.

The mechanism holds (`:372`: `if ! review_diff "$dest" "$stage" "${CLAUDE_HOME_NAMES[@]}"; then`). The parenthetical "(the checkout)" holds only for the README's links. P3c had `~/.claude/skills -> …/myskills`, a non-checkout directory holding `zzz/SKILL.md`. There the diff compared that directory with the stage and showed `-mine` for `skills/zzz/SKILL.md`, which was not listed as MOVE because the entry is a link (`:346-348` takes the REPLACE branch only). Nothing is lost: the link is moved and its target is left in place. A more precise comment would read: "compares the link's target (the checkout, for the README's old install) with the stage."

**Evidence:** `devcontainer-config/install.sh:345-374`; `docs/reviews/execution-logs/cfc-copy-install-r3/probe.txt` (P3c)
**Legibility-target:** for-author

---

## Claim 9: "1. Copy every entry beside its target. Any failure: undo and stop before a single live entry is touched." (6793b79: "A copy failure undoes itself before touching a live entry.")

**Location:** `devcontainer-config/install.sh:392-406`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers failures of `mkdir -p "$dest"` and of `cp -R` into `.cw-new.<name>`. It does not establish recovery from failures in step 2 (move-aside) or step 3 (swap-in); see Claim 10.

```bash
# devcontainer-config/install.sh:402-406
  if [ "$ok" -eq 0 ]; then
    for name in "${CLAUDE_HOME_NAMES[@]}"; do rm -rf "$dest/.cw-new.$name" 2>/dev/null || true; done
    echo "ERROR: could not copy the new files into $dest; nothing was replaced." >&2
    exit 1
  fi
```
Executed: T16 ("a copy failure swaps nothing and leaves no backup") passes at HEAD.

**Evidence:** `devcontainer-config/install.sh:392-406`; `docs/reviews/execution-logs/cfc-copy-install-r3/head-install-host.txt` (ok 16)
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 10: "copies to `.cw-new.<name>`, moves the old entry (link or dir, never with a trailing slash) to the backup, and only then moves the new copy into place."

**Location:** `docs/decisions/037-bare-host-copy-install.md:51` (the code is `devcontainer-config/install.sh:408-437`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the order of operations. It does not establish recoverability or a recovery message when step 2 or step 3 fails partway, and no doc claims either.

The order is as stated (`:423-427` moves to `$backup`, then `:431-437` does `mv "$dest/.cw-new.$name" "$dest/$name"`). Neither step 2's nor step 3's `mv` has error handling; `set -e` stops the script at the first failure. Executed failure: P6 made `workflows/` read-only, so renaming it to a new parent fails. The run printed only mv's own error, `mv: cannot move '…/.claude/workflows' to '…/.claude-workflows-backup/20260923T233237Z/workflows': Permission denied`, then `[exit=1]`. It left `CLAUDE.md` and `skills` in the backup and absent from `~/.claude`, `workflows` in place, and all seven `.cw-new.*` staged copies beside them. No line tells the user that the live `~/.claude` is missing its CLAUDE.md and skills, where they went, or how to finish or undo. The only step-3 message (`:433`) names the `.cw-new` path but not the backup dir. This is outside the claim, reported because the brief asked.

**Evidence:** `devcontainer-config/install.sh:408-437`; `docs/reviews/execution-logs/cfc-copy-install-r3/probe.txt` (P6)
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 11: "2. Move whatever is there now … into a fresh backup dir."

**Location:** `devcontainer-config/install.sh:408-418`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers sequential reruns within the same UTC second. It does not establish freshness for two concurrent runs, where both could pass the `-e` test before either `mkdir -p`.

```bash
# devcontainer-config/install.sh:416-417
    backup="$bkroot/$stamp"
    if [ -e "$backup" ]; then backup="$backup.$$"; fi
```
Executed: in P7, three back-to-back installs produced `20260923T233238Z` and `20260923T233238Z.333103`. The third run landed in a different second, so the `.$$` fallback was exercised once. In the concurrent case `mkdir -p` succeeds on an existing dir, and a second `mv skills <existing>/skills` would nest the entry (`<backup>/skills/skills`) rather than overwrite it. That is inferred, not run.

**Evidence:** `devcontainer-config/install.sh:410-428`; `docs/reviews/execution-logs/cfc-copy-install-r3/probe.txt` (P7)
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 12: "Provenance … `rm -f` first so a planted symlink cannot redirect the write." (6793b79: "Writes .claude-workflows-manifest (rm -f first) with installed_by, installed_parent and installed_at appended")

**Location:** `devcontainer-config/install.sh:439-447`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the rm-then-copy order and the three appended keys. It does not establish what `installed_parent` records under a given wrapper (Claim 21).

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
Executed: in P8 the manifest held `installed_by=host-tty`, `installed_parent=…` and `installed_at=20260923T233239Z`. T10 passes at HEAD.

**Evidence:** `devcontainer-config/install.sh:439-447`; `docs/reviews/execution-logs/cfc-copy-install-r3/probe.txt` (P8), `head-install-host.txt` (ok 10)
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 13: "Target 2 is SKIPPED, with a message and no effect on the exit status … Exit status: 0 no target declined; 1 a target was declined, or an error; 2 bad arguments."

**Location:** `devcontainer-config/install.sh:40-49`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers exit codes 0 (P1c), 1 (P1a, P2), 0 for `-h` (P1e), and 2 for an unknown argument (T15). It does not establish exit codes on other error paths.

The final line is `exit "$DECLINED"` (`:464`), and the argument loop exits 2 on anything unrecognized (`:58`). The outcomes are listed in the Scope line above.

**Evidence:** `devcontainer-config/install.sh:53-61`, `:461-464`; `docs/reviews/execution-logs/cfc-copy-install-r3/probe.txt` (P1a, P1c, P1e, P2), `head-install-host.txt` (ok 15)
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 14: "In this session the Bash tool has no TTY (verified 2026-09-23: fd 0 is `/dev/null` and `tty` prints "not a tty")."

**Location:** `docs/decisions/037-bare-host-copy-install.md:50`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers this reviewer's Bash tool on 2026-09-23. It does not establish behavior of other harnesses or of the user's host shell.

Command `bash scratchpad/cfc-r3/misc.sh` (cwd the scratchpad; exit 0; 2026-09-23T23:33Z). It printed `not a tty` and `/proc/self/fd/0 -> /dev/null`. This output was read in the terminal and not captured to a file. That is a provenance gap, because the command is a two-liner whose result is shown verbatim here.

**Evidence:** `docs/decisions/037-bare-host-copy-install.md:50`; `/tmp/claude-1000/-workspace/d516ca2c-2abb-4732-a34a-041aa98280c8/scratchpad/cfc-r3/misc.sh`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 15: "The check stops accidents, not intent. The backstop is sandbox `denyWrite ~/.claude` (guide §3)."

**Location:** `docs/decisions/037-bare-host-copy-install.md:50` (plan Risks, line 216: "A host without that sandbox setting has no hard barrier")
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers guide §3 recommending `denyWrite` on `~/.claude` (`guides/bare-host-hook-wiring.md:74-77`). It does not establish that the user's host has it set, or that it holds against an agent Bash call with `dangerouslyDisableSandbox`, which prompts the user rather than being denied.

Paraphrased — no quote available because the claim concerns host settings.json and Claude Code sandbox semantics outside this repo. Every write the installer makes to `$dest` goes through Bash (`cp`, `mv`, `rm`), so a Bash-level denyWrite on `~/.claude` would make the copy step fail and self-undo (Claim 9). To verify, run the host's sandbox with `denyWrite ~/.claude` and the `script` wrapper from a session. That cannot be done in this sandbox.

**Evidence:** `docs/decisions/037-bare-host-copy-install.md:50`; `guides/bare-host-hook-wiring.md:74-77`; `docs/working/plan-copy-install-bare-host.md:216`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 16: "copies the whole `hooks/` directory (including `hooks/lib/`) and the whole `scripts/` directory, so hooks that find their helpers by their own path (`log-usage.sh` → `lib/usage-common.sh` and `../scripts/lib/`; `claude-config-audit.sh` → `../scripts/claude_config_audit.py`) keep working."

**Location:** `guides/bare-host-hook-wiring.md:17-21`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two named hooks' helper lookups and T9's log-usage smoke test. It does not establish the other hooks' runtime behavior after install.

`hooks/log-usage.sh:11`: `source "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/lib/usage-common.sh"`, and `:14` sources `…/../scripts/lib/skill-paths.sh`. `hooks/claude-config-audit.sh:48`: `AUDIT_SCRIPT="$HOOK_DIR/../scripts/claude_config_audit.py"`. `CLAUDE_HOME_SRC` includes `hooks` and `scripts` (`devcontainer-config/install.sh:93`). T9 ("installed hooks still find lib/ and ../scripts") passes at HEAD.

**Evidence:** `hooks/log-usage.sh:11-14`; `hooks/claude-config-audit.sh:43-49`; `devcontainer-config/install.sh:93`; `docs/reviews/execution-logs/cfc-copy-install-r3/head-install-host.txt` (ok 9)
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 17: "`install.sh` does not write `settings.json`, but it prints a `REMINDER` pointing here whenever the installed `hooks/wiring.json` is missing or differs from the repo's."

**Location:** `guides/bare-host-hook-wiring.md:62-64`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the missing and changed cases on an accepted install. It does not establish a reminder on a declined install, where none prints, as expected.

```bash
# devcontainer-config/install.sh:381-384
  local wiring_changed=0
  if ! cmp -s "$dest/hooks/wiring.json" "$stage/hooks/wiring.json"; then
    wiring_changed=1
  fi
```
`cmp` exits 2 on a missing file, so a missing file counts as changed. Executed: P4 and P9 (first installs) printed `REMINDER: hooks/wiring.json changed (or was not installed before).` T11 (first install, unchanged, changed) passes. No code path in the installer writes `settings.json` (it appears only in the grep at `:362`).

**Evidence:** `devcontainer-config/install.sh:362`, `:381-384`, `:453-458`; `docs/reviews/execution-logs/cfc-copy-install-r3/probe.txt` (P4), `probe9.txt`, `head-install-host.txt` (ok 11)
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 18: "`claude-config-audit.sh` looks for the auditor at `CLAUDE_CONFIG_AUDIT_SCRIPT`, then `<hook dir>/../scripts/`, then `~/private_reviews/`. If it finds none, the hook does nothing."

**Location:** `guides/bare-host-hook-wiring.md:82-84`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the resolution order. It does not establish the "does nothing" branch (not read past `:49`) or sandbox coverage of the installed path.

```bash
# hooks/claude-config-audit.sh:43-49
if [[ -n "${CLAUDE_CONFIG_AUDIT_SCRIPT:-}" ]]; then
  AUDIT_SCRIPT="$CLAUDE_CONFIG_AUDIT_SCRIPT"
…
  HOOK_DIR=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
…
  [[ -f "$AUDIT_SCRIPT" ]] || AUDIT_SCRIPT="$HOME/private_reviews/claude_config_audit.py"
```
(excerpt shows `:43-49` with elisions; the enclosing top-level block continues. Only the lookup was read for this claim.) The hook's own comment at `:31` gives the same order.

**Evidence:** `hooks/claude-config-audit.sh:31-49`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 19: "exit 2 for an unknown argument is the only observable change, and only for invalid input."

**Location:** commit 1514518 message (Notes); code at `devcontainer-config/install.sh:53-61` as of 1514518
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers 1514518 against 712c626 for argument handling and the devcontainer flow. It does not cover later commits.

The line-by-line diff of `git show 712c626:…/install.sh` against `git show 1514518:…/install.sh` shows only extraction into functions, apart from the new argument loop. The loop also added `-h|--help) usage; exit 0 ;;`. Under 712c626, `ASSUME_YES="${1:-}"` treated `-h` as an ordinary interactive run. Executed: P1d (712c626, `-h </dev/null`) ran the install flow to `Aborted. Nothing was changed.` and `[exit=1]`. P1e (HEAD, `-h`) printed usage and `[exit=0]`. So `-h`/`--help`, which was valid input before, changed too. The precise version: "exit 2 for an unknown argument and a new `-h/--help` are the only observable changes."

**Evidence:** `devcontainer-config/install.sh:53-61`; `docs/reviews/execution-logs/cfc-copy-install-r3/probe.txt` (P1d, P1e)
**Legibility-target:** for-author

---

## Claim 20: "Declining the devcontainer target now continues to the host target; the run still exits 1 when anything was declined."

**Location:** commit 6793b79 message; code at `devcontainer-config/install.sh:190-198`, `:461-464`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both declines setting `DECLINED=1` and the run continuing. It does not establish output wording (Claims 3 and 5b).

`:196-197`: `DECLINED=1` / `return 0`; `:388`: `DECLINED=1` for the host decline. Executed: P3b and P3c answered `n,n` and showed the host review after the devcontainer decline, then `[exit=1]`. P9 answered `n,y`, installed the host target, and still ended `[exit=1]`.

**Evidence:** `devcontainer-config/install.sh:190-198`, `:386-390`, `:461-464`; `docs/reviews/execution-logs/cfc-copy-install-r3/probe.txt` (P3b, P3c), `probe9.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 21: "installed_parent records "script" when the installer ran under a pty wrapper, which is an audit trace for the agent-bypass case the TTY rule cannot stop."

**Location:** commit 6793b79 message (Notes); code at `devcontainer-config/install.sh:445`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what `installed_parent` records under three `script -qec` command strings. It does not establish values on macOS `script`, whose argument syntax differs.

`:445` records the comm of `$PPID`, the installer's immediate parent. That parent is `script` only when `script`'s `$SHELL -c` execs the command directly, i.e. a single simple command. Executed, P8: `script -qec "env -u CLAUDECODE $INSTALL"` recorded `installed_parent=script`, and `script -qec "cd $ROOT && env -u CLAUDECODE ./devcontainer-config/install.sh"` also recorded `script`. But `script -qec "bash -c 'env -u CLAUDECODE $INSTALL; echo done'"` recorded `installed_parent=bash`, the same value a human's interactive bash would leave. The pty-wrapped install succeeded without a trace. An agent trying to bypass the rule needs only a compound command. So the key is not a reliable audit trace, and the decision's revisit trigger (`037:64`, "backup stamp with no human at the terminal") cannot rely on it.

**Evidence:** `devcontainer-config/install.sh:445`; `docs/reviews/execution-logs/cfc-copy-install-r3/probe.txt` (P8)
**Legibility-target:** for-author

---

## Claim 22: "All 24 fail against the current install.sh (T7 and T16 were tightened so they cannot pass when nothing is installed)."

**Location:** commit dcf4a6d message
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `bats test/install-host.bats` run from the `git archive dcf4a6d` tree, where install.sh is still 712c626's. It does not establish why each test fails (not inspected per test).

Command: `bats test/install-host.bats`, cwd `…/cfc-r3/tree-dcf4a6d`, exit 1. Output: `ok=0 notok=24`, `not ok 1 T1 …` through `not ok 24 T24 …`.

**Evidence:** `docs/reviews/execution-logs/cfc-copy-install-r3/dcf4a6d-install-host.txt`, `exits.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 23a: "test/install-host.bats 24/24 · test/cc-isolated-functions.bats 90/90 (unmodified) · test/link-claude-home-wiring.bats 14/14 · test/hooks/*.bats 144/144 (6 files)"

**Location:** commit d0fdd04 message (also 6793b79 and 1514518 for 24/24 and 90/90)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers these four suites on the `git archive d0fdd04` tree in this sandbox. It does not establish results on the user's host or on macOS. The "(unmodified)" part was not rechecked by diff.

Commands run from `…/cfc-r3/tree-d0fdd04`, all exit 0: `bats test/install-host.bats` 24 ok, 0 not ok; `bats test/cc-isolated-functions.bats` 90/0; `bats test/link-claude-home-wiring.bats` 14/0; `bats test/hooks/` 144/0 over 6 files. Hallucination-pattern check: the log holds a prior entry for a commit that misstated test counts ("All 85 tests … but the suites hold 97"). The counts here match.

**Evidence:** `docs/reviews/execution-logs/cfc-copy-install-r3/head-install-host.txt`, `head-ccif.txt`, `head-lchw.txt`, `head-hooks.txt`, `exits.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 23b: "test/guide-index-sync.bats, test/cross-reference-integrity.bats, test/fixture-hermeticity.bats pass · scripts/run-tests.sh --fast: 864 ok, 0 not ok (1m23s)"

**Location:** commit d0fdd04 message
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Not run. It does not establish anything about these suites.

Paraphrased — no quote available because this is an unexecuted test-count claim. Execution is required to verdict it. It was not run within this pass's budget; the fast suite is about 1.5 minutes plus three more files. Verify by running `scripts/run-tests.sh --fast` and the three named bats files from the d0fdd04 tree.

**Evidence:** commit d0fdd04 message
**Legibility-target:** for-orchestrator-synthesis

---

## Claims Requiring Attention

### Incorrect
- **Claim 7** (`devcontainer-config/install.sh:350-353`): the review prints `REPLACE symlink … with a copy` for foreign per-file links, which get no copy and are only moved. Print REPLACE only when the stage has the path.
- **Claim 21** (commit 6793b79, `devcontainer-config/install.sh:445`): `installed_parent` is `bash`, not `script`, when the pty wrapper runs a compound command, so it is not a reliable audit trace for the agent-bypass case.

### Mostly Accurate
- **Claim 2a** (`README.md:26-29`): the migration review aborts with `could not diff payload item 'hooks' (diff exit 2)` when an owned dir holds a dangling symlink. The error does not name the path, and the README gives no recovery step.
- **Claim 3** (`devcontainer-config/install.sh:192-195`): the abort line has a new ` (devcontainer config)` suffix; only the prefix is the old wording.
- **Claim 5b** (`install.sh:287-289`, `037:33`, `037:52`, 6793b79): a non-interactive run gains two lines (a blank and the skip), plus the abort-line suffix, not one line.
- **Claim 8** (`devcontainer-config/install.sh:370-371`): "(the checkout)" holds only for the README's old links; a link to another directory is diffed against that directory.
- **Claim 19** (commit 1514518): `-h/--help` is also a new observable change (it used to start an interactive run).

### Unverifiable
- **Claim 15** (`docs/decisions/037-bare-host-copy-install.md:50`): the sandbox `denyWrite ~/.claude` backstop depends on host settings; test it on the host with the `script` wrapper from a session.
- **Claim 23b** (commit d0fdd04): the 864-ok fast suite and three named bats files were not run; run them from the d0fdd04 tree.

Additional brief item (not a claim contradiction, reported under Claim 10): a failure in the move-aside step leaves the live `~/.claude` missing entries that are already in the backup, with the `.cw-new.*` copies staged. The script prints only mv's own error, with no recovery instructions (P6).

No hallucination-pattern entries added: both Incorrect verdicts are behavioral mismatches, not fabricated symbols.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the output path your task names, structured per your skill, beginning with a `Commit: d0fdd04` line.
- Answered: yes. All 8 brief items were checked, most by hermetic execution.
- Out of scope: the 864-test fast suite and three docs bats files (not run); macOS behavior; concurrent-run races (inferred only).
- Escalate: Claim 21 (the audit trace the TTY residual relies on can be dodged with a compound command). Also the shared `scratchpad/fc/` collision with a sibling agent, noted in the header.
