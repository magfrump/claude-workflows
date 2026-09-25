# Code Fact-Check Report

Commit: b4fd792

**Repository:** /workspace (branch `ans/copy-install`, read from the worktree `/workspace/.claude/wt-copyinstall` at b4fd792)
**Scope:** commit range `9ae6e46..b4fd792` (8 commits), limited to `devcontainer-config/install.sh`, `test/install-host.bats`, `test/cc-isolated-functions.bats`, `README.md`, `docs/decisions/037-bare-host-copy-install.md`, `guides/bare-host-hook-wiring.md`, `docs/working/plan-copy-install-bare-host.md`, plus the commit messages. `docs/reviews/` files in the range were read as context only.
**Checked:** 2026-09-24
**Total claims checked:** 25
**Summary:** 15 verified, 6 mostly accurate, 0 stale, 2 incorrect, 2 unverifiable

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) read before checking. No claim matches a logged pattern: the four logged entries are measured values or file-to-symbol associations. The closest class is the test-count figure in Claim 24, which could not be tied to a named suite set. It is Unverifiable, not a confirmed fabrication.

Execution provenance: every executed claim cites a captured log under `docs/reviews/execution-logs/q058-r3-b4fd792/`. Each log starts with its UTC timestamp, cwd and exact command, and ends with `exit=`. All runs were hermetic. The bats suites pin HOME, CLAUDE_HOME_DIR, CLAUDE_DEVC_* and TMPDIR into BATS_TEST_TMPDIR and stub pgrep and docker on PATH. The pre-fix and probe runs used a `git archive` copy under the session scratchpad. No run touched the real `~/.claude`.

Main runs:
- `suites.log`: `bats test/install-host.bats test/cc-isolated-functions.bats`, cwd the worktree, 2026-09-25T06:39:02Z, 156/156 ok, exit 0.
- `regex-probe.log`: the real procps-ng 4.0.2 `pgrep` against synthetic command lines, 06:39:31Z, exit 0.
- `prefix-*.log`: b4fd792's tests run against older install.sh versions, 06:40:40Z to 06:41:19Z.
- `vis-paths.log`: probes X1 to X3, 06:41:43Z, exit 0.
- `payload-nul.log`: a NUL scan of the payload at b4fd792, 06:40:21Z, exit 0.

---

## Claim 1: "Before it stages anything, and again after each y, it refuses while a Claude Code process of your uid or a running cc-isolated container (it can write the checkout through its bind mount) is found, and names each one with how to stop it."

**Location:** `README.md:33-39`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the three gate call sites, the naming of each process or container, the stop hints, and the same statement in `guides/bare-host-hook-wiring.md:17-20` and `--help` (`install.sh:51-58`). It does not establish that the gate detects every real agent: see Claims 15 and 17 for the detector's blind spots, and note that the gate samples three moments rather than watching continuously.

The gate runs at `install.sh:947`, before `install_devcontainer`, and after each confirm (`:391` and `:695`, see Claim 10). Its refusal block names each item and how to stop it:

```bash
# devcontainer-config/install.sh:873-883
    if [ -n "$procs" ]; then
      echo "       Claude Code processes of uid $(id -u) (PID and command line):"
      printf '%s\n' "$procs" | sed 's/^/           /'
      echo "       Stop them: end each Claude Code session (/exit), or kill <PID>."
    fi
    if [ -n "$ctrs" ]; then
      echo "       Running cc-isolated containers (name and project id):"
      printf '%s\n' "$ctrs" | sed 's/^/           /'
      echo "       Stop them: docker stop <name>"
    fi
    echo "       Then rerun install.sh. $what"
```
(excerpt ends :883; the enclosing `agent_gate()` continues to :886 with `} | vis >&2` and `exit 1`, read)

T50, T51, T54 and T55 pass at b4fd792. T50 asserts that neither `Canonical` nor the mirror appears (refused before staging). T54 and T55 assert the refusal after the host y and after the devcontainer y.

**Evidence:** `devcontainer-config/install.sh:391`, `:695`, `:838-886`, `:947`; `guides/bare-host-hook-wiring.md:17-20`; `test/install-host.bats` T50, T51, T54, T55; `docs/reviews/execution-logs/q058-r3-b4fd792/suites.log`

---

## Claim 2: "extract_commit scans every staged file (both targets) and refuses, listing them through vis, any file holding a NUL, before any review or prompt (T61)." / "No allowlist: `git archive HEAD` of the payload paths holds no NUL today." / "the payload is ~125 small text files"

**Location:** `devcontainer-config/install.sh:181-199` (commit 8d9be0c)
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the scan inside `extract_commit` and its three call sites: `assemble` for both targets, and the devcontainer `dc_paths` call at `:349`. Also covers the no-NUL state of the b4fd792 payload (122 files, no symlinks). It does not establish the host-target call site by test: T61's two runs are both caught on the devcontainer side, since `hooks/` is also in the devcontainer's claude-home. The host site runs the same function via `assemble` (`:585`), established by reading the code only.

```bash
# devcontainer-config/install.sh:186-189
  if ! nul="$(cd "$dir" && find . -type f -print0 | LC_ALL=C sort -z | LC_ALL=C perl -0ne '
        chomp; open(my $f, "<:raw", $_) or die "$_: $!\n";
        my $c = do { local $/; <$f> };
        print substr($_, 2), "\n" if defined $c && index($c, "\0") >= 0;')"; then
```
(excerpt ends :189; the enclosing `extract_commit()` continues to :200 with the error exit and the vis'd listing at :196, read)

The listing goes through vis: `printf '%s\n' "$nul" | sed 's/^/         /' | vis >&2` (`:196`). The scan fails closed, because under `pipefail` a perl `die` makes the `if !` branch exit. Callers: `assemble` → `extract_commit` at `:219`, used by both targets (`:348`, `:585`), plus `:349`. All run before the reviews at `:364-377` and `:593-675`. Test T61 passes. The payload scan counted 122 files, no NUL files and 0 symlinks.

**Evidence:** `devcontainer-config/install.sh:181-200`, `:219`, `:348-349`, `:585`; `test/install-host.bats` T61; `docs/reviews/execution-logs/q058-r3-b4fd792/payload-nul.log`, `payload-nul.sh`, `suites.log`

---

## Claim 3: "Without pgrep it refuses; without a reachable docker it says so in one line and treats no container as running."

**Location:** `devcontainer-config/install.sh:56-57`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers missing pgrep, pgrep exit >1, missing docker, and docker exiting non-zero. It does not establish the case where docker hangs past 20 s. That case is also treated as unreachable (`timeout 20` exits 124), so it fails open with the same NOTE. Nor does it establish a docker that answers from a different daemon than cc-isolated's: that returns an empty list with no NOTE.

```bash
# devcontainer-config/install.sh:840-849
  if ! command -v pgrep >/dev/null 2>&1; then
    echo "ERROR: pgrep is not installed, so install.sh cannot check that no Claude Code" >&2
    echo "       session is running (Q-058). Install procps and rerun. $what" >&2
    exit 1
  fi
  procs="$(pgrep -u "$(id -u)" -af -- "$CLAUDE_PROC_RE")" || rc=$?
  if [ "$rc" -gt 1 ]; then
    echo "ERROR: pgrep failed (exit $rc) while checking for Claude Code sessions (Q-058). $what" >&2
    exit 1
  fi
```
(excerpt ends :849; the enclosing `agent_gate()` continues to :886, read)

`:853-854` prints one `NOTE: docker not found…` line. `:860-865` prints one `NOTE: docker is unreachable ($err)…` line, where `$err` is `head -n 1` of stderr, and sets `ctrs=""`. Tests T52 (both docker cases) and T53 pass.

**Evidence:** `devcontainer-config/install.sh:838-886`; `test/install-host.bats` T52, T53; `docs/reviews/execution-logs/q058-r3-b4fd792/suites.log`

---

## Claim 4: "Needs git, perl (the review's control-byte filter) and pgrep; refuses without them."

**Location:** `devcontainer-config/install.sh:66`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers refusal without perl (T57) or pgrep (T53), both executed, and without git, read only. It does not establish that these are the only required tools: `timeout`, GNU find, sort and diff are also used, and a missing `timeout` reads as "docker is unreachable" and fails open. Nor does it establish that the no-git refusal message is accurate.

The perl check is at `main` `:941-945`, before the gate at `:947`. With no git, `head_commit` (`:130`, `if ! git -C "$REPO_ROOT" rev-parse …`) exits with "no readable HEAD commit". That message names HEAD, not git, and it comes only after `mktemp -d` of DC_TMP (paraphrased, no quote available because the no-git path was traced by reading, not run).

**Evidence:** `devcontainer-config/install.sh:129-135`, `:941-947`; `test/install-host.bats` T53, T57; `docs/reviews/execution-logs/q058-r3-b4fd792/suites.log`

---

## Claim 5: "review_diff runs `diff -a`, and vis now maps NUL to "?", so a destination file holding a NUL is reviewed as text, never as "Binary files differ" (T62)."

**Location:** `devcontainer-config/install.sh:122`, `:262-265` (commit 8d9be0c)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the vis character class and the `-a` flag in `review_diff`. It does not establish the output of `mode_diff` or `payload_hash`, which do not print file content.

```bash
# devcontainer-config/install.sh:122
    s/[\x00-\x08\x0b\x0c\x0e-\x1a\x1c-\x1f\x7f]/?/g;
# devcontainer-config/install.sh:265
    diff -ruNa "$dest/$item" "$src/$item" 2>&1 | vis && st=(0 0) || st=("${PIPESTATUS[@]}")
```

T62 passes. It asserts `-bad?byte` in the output and no `Binary files` line.

**Evidence:** `devcontainer-config/install.sh:119-126`, `:247-281`; `test/install-host.bats` T62; `docs/reviews/execution-logs/q058-r3-b4fd792/suites.log`

---

## Claim 6: "review_diff checks vis's PIPESTATUS too; a non-zero vis aborts before the prompt like any other diff trouble (T58, which reached the prompt with an empty review before this fix)."

**Location:** `devcontainer-config/install.sh:259-271` (commit fa69656)
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers `review_diff`'s handling of a vis failure and the pre-fix behavior. It does not establish vis failures on the lines outside `review_diff` (see Claims 7a and 7b).

```bash
# devcontainer-config/install.sh:265-271
    diff -ruNa "$dest/$item" "$src/$item" 2>&1 | vis && st=(0 0) || st=("${PIPESTATUS[@]}")
    rc="${st[0]}"
    if [ "${st[1]}" -ne 0 ]; then
      echo "ERROR: could not show the review of payload item '$item' (vis exit ${st[1]})." >&2
      echo "       The review diff is incomplete, so nothing was installed." >&2
      exit 1
    fi
```
(excerpt ends :271; the enclosing `review_diff()` continues to :281 with the `case "$rc"` handling and `return "$changed"`, read)

When the pipeline fails, `st=(0 0)` is skipped, so `PIPESTATUS` still holds the `diff | vis` statuses.

T58 passes at b4fd792. The same T58 against ea2c8fb's install.sh (the parent of fa69656), with `LC_ALL=C`, fails. Its output shows an empty review block followed by `Install this config and bless it? [y/N]`, which is the pre-fix behavior the commit describes. The first pre-fix attempt without `LC_ALL=C` failed earlier, on T58's setup. The bash docker stub printed a setlocale warning, which ea2c8fb's `2>&1` capture counted as a container. That is the bug 648124c fixed (Claim 12).

**Evidence:** `devcontainer-config/install.sh:247-281`; `docs/reviews/execution-logs/q058-r3-b4fd792/prefix-ea2c8fb-T58-LC_C.log`, `prefix-ea2c8fb-T58.log`, `prefix.sh`, `suites.log`

---

## Claim 7a: "other `| vis` uses (MODE …) are not individually checked; … a vis that fails there fails in review_diff too, which aborts."

**Location:** `devcontainer-config/install.sh:299` (commit fa69656, Notes line)
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers MODE lines on both targets. `mode_diff` is always followed by `review_diff` over the same items (`:367-368`, `:668-670`). It does not establish a vis that fails only on some inputs.

`mode_diff` is called in a `||` or `if !` context, so `set -e` is off inside it. A failed `echo "MODE …" | vis` (`:299`) prints nothing and does not stop the run. Probe X1 committed a mode-only change to `devcontainer.json` with a vis-only-failing perl stub. The output shows no MODE line, then `ERROR: could not show the review of payload item 'devcontainer.json' (vis exit 1).` and exit 1, before the prompt. This is the mechanism the note states.

**Evidence:** `devcontainer-config/install.sh:287-305`, `:367-368`, `:668-670`; `docs/reviews/execution-logs/q058-r3-b4fd792/vis-paths.log`, `vis-paths.sh`, `vis-paths.bats.append`

---

## Claim 7b: "other `| vis` uses (… MOVE, ADD lines) are not individually checked; … a vis that fails there fails in review_diff too, which aborts."

**Location:** `devcontainer-config/install.sh:600`, `:606`, `:625`, `:646-654` (commit fa69656, Notes line)
**Type:** Error-handling
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the REPLACE, MOVE and ADD lines of the host target. It establishes that these fail closed, but through a different mechanism than the note states, and with no error message. It does not establish that `set -e` and `pipefail` stay in force: they are what carry the refusal.

These lines are in `install_claude_home`, which `main` calls outside any `||` or `if` context, so `set -euo pipefail` (`:26`) applies. The first failing `echo … | vis` ends the script there. `review_diff` is never reached:

```bash
# devcontainer-config/install.sh:646-647
      echo "ADD $dest/$name (new, $n file(s)):" | vis
      (cd "$stage" && find "$name" -type f | LC_ALL=C sort) | sed 's/^/    /' | vis
```
(excerpt ends :647; the enclosing `install_claude_home()` continues to :816, read)

Probes X2 (first install, ADD lines only) and X3 (symlink migration, REPLACE and MOVE lines) both exit 1. The output stops right after `=== Changes this install would make ===`, with no error line and no prompt, and the destination is unchanged. The conclusion (it never reaches `[y/N]`) holds. The stated mechanism ("fails in review_diff too") is refuted: the abort is `set -e`, and it is silent.

**Evidence:** `devcontainer-config/install.sh:26`, `:593-675`; `docs/reviews/execution-logs/q058-r3-b4fd792/vis-paths.log`

---

## Claim 8: "Before staging, each component from the repo root down to claude-home is checked with -L; a link is refused, named, and left in place (T59, T60)." / "The claude-home symlink error now passes readlink's output through vis."

**Location:** `devcontainer-config/install.sh:331-345` (commits dfa5791, b4fd792)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers every component below `$REPO_ROOT` (`devcontainer-config`, `claude-home`) at check time, and the vis'd message. It does not establish `$REPO_ROOT` itself, which is never tested with `-L`, or anything that changes after the check (see Claim 9).

```bash
# devcontainer-config/install.sh:334-345
  local p="$REPO_ROOT" comp
  local -a comps
  IFS=/ read -ra comps <<< "${SRC#"$REPO_ROOT"/}/claude-home"
  for comp in "${comps[@]}"; do
    p="$p/$comp"
    if [ -L "$p" ]; then
      echo "ERROR: $p is a symlink ($(readlink "$p")). install.sh rebuilds" | vis >&2
      ...
      exit 1
    fi
  done
```
(excerpt ends :345, with lines :341-342 elided as `...`; the enclosing `install_devcontainer()` continues to :424, read)

`SRC` and `REPO_ROOT` are logical `pwd` paths (`:78`, `:85`), so a symlinked `devcontainer-config` shows up as a component. The check runs before `mktemp` and `assemble` (`:346-348`). T59 and T60 pass. T60 asserts that `$S/realdc/claude-home` is not created.

**Evidence:** `devcontainer-config/install.sh:78`, `:85`, `:321-358`; `test/install-host.bats` T59, T60; `docs/reviews/execution-logs/q058-r3-b4fd792/suites.log`

---

## Claim 9: "The rebuild is no-follow: rm without a trailing slash, then `mkdir` (which fails rather than follow anything that reappeared) and a copy of the stage's contents into the directory this run just made."

**Location:** `devcontainer-config/install.sh:350-358` (commit dfa5791)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the final path component, `claude-home`. It does not establish that intermediate components cannot be followed.

```bash
# devcontainer-config/install.sh:353-358
  rm -rf "$SRC/claude-home"
  if ! mkdir "$SRC/claude-home"; then
    echo "ERROR: could not recreate $SRC/claude-home (something reappeared there). Nothing was installed." >&2
    exit 1
  fi
  cp -Rp "$stage/claude-home/." "$SRC/claude-home/"
```

For the last component, this is right: `rm` removes a link rather than its target, and `mkdir` refuses an existing name. But `rm`, `mkdir` and `cp` all resolve `$SRC` itself, and `devcontainer-config` is checked only once, at `:339`. That is before `assemble` and `extract_commit` run `git archive` (`:348-349`). A directory swapped for a link in that window is followed. The commit names only the `mkdir`→`cp` window as a residual. A precise version: "no-follow at `claude-home`; the directories above it are checked once, before staging."

**Evidence:** `devcontainer-config/install.sh:334-358`

---

## Claim 10: "agent_gate refuses … at startup, before either target stages anything; after the devcontainer y, before it writes; after the host y, right before the lock, copies and swap."

**Location:** `devcontainer-config/install.sh:947`, `:390-391`, `:694-695` (commit ea2c8fb)
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the three call sites and the absence of writes between each y and its gate. It does not establish detection between the samples: an agent that starts after one gate and exits before the next is not seen. Nor does it establish the pre-prompt mirror rebuild, which decision 037:68 calls a staging copy.

```bash
# devcontainer-config/install.sh:379-393
  if [ "$ASSUME_YES" != "--yes" ]; then
    if ! confirm 'Install this config and bless it?'; then
      ...
      return 0
    fi
  fi

  # Q-058: an agent may have started while the prompt waited.
  agent_gate "Nothing was installed. (devcontainer config)"

  mkdir -p "$DEST" "$BIN_DIR"
```
(excerpt ends :393, with lines :381-386 elided as `...`; the enclosing `install_devcontainer()` continues to :424, read)

```bash
# devcontainer-config/install.sh:688-702
  if ! confirm "Install these files into $dest?"; then
    ...
  fi

  # Q-058: an agent may have started while the review and prompt waited.
  agent_gate "Nothing was installed into the host target."
  ...
    if mkdir "$dest/.claude-workflows-lock" 2>/dev/null; then
```
(excerpt ends :702, with elisions marked `...`; the enclosing `install_claude_home()` continues to :816, read)

The startup gate at `:947` precedes `trap` (`:950`) and `install_devcontainer` (`:953`). Nothing between `main`'s argument parsing and `:947` writes anything. T50 (startup), T54 (host y) and T55 (devcontainer y) pass.

**Evidence:** `devcontainer-config/install.sh:379-393`, `:688-702`, `:902-956`; `test/install-host.bats` T50, T54, T55; `docs/reviews/execution-logs/q058-r3-b4fd792/suites.log`

---

## Claim 11: "pgrep never lists itself and this script's own command line does not match; $$ is dropped only as a belt-and-braces guard. A command line with a `.../claude` argument (`vim ./claude`, `tail -f /var/log/claude`) also matches"

**Location:** `devcontainer-config/install.sh:827-834`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers how `CLAUDE_PROC_RE` matches the shapes tested with the real pgrep. It does not establish which shapes real Claude Code launchers produce (see Claim 15).

```bash
# devcontainer-config/install.sh:834
CLAUDE_PROC_RE='(^|/)claude(\.exe)?( |$)|/@anthropic-ai/claude-code/'
```

The real `pgrep -u 1000 -af` with this regex, run against synthetic command lines, gave these results:
- MATCH: `claude`, `claude --resume`, `/usr/local/bin/claude --resume`, `node /usr/local/bin/claude --resume`, `node …/@anthropic-ai/claude-code/cli.js`, `…/claude-code/bin/claude.exe -p hi`, `bun …/@anthropic-ai/claude-code/cli.js`, `…/native-binary/claude --output-format stream-json`, `vim ./claude`.
- miss: `bash /home/u/claude-workflows/devcontainer-config/install.sh`, `bash /home/u/claude/devcontainer-config/install.sh`, `vim claude`, `claude-code --resume`, `npx @anthropic-ai/claude-code`, `…/.local/share/claude/versions/2.0.14 [--resume]`, `python3 -m claude_agent_sdk`.

The `awk -v self="$$" 'NF && $1 != self'` filter is at `:850`.

**Evidence:** `devcontainer-config/install.sh:827-850`; `docs/reviews/execution-logs/q058-r3-b4fd792/regex-probe.log`, `regex-probe.sh`

---

## Claim 12: "`docker ps --filter label=cc-project` (cc-isolated's --id-label)" / "stderr now goes to a temp file, shown only when docker fails, and blank lines are dropped from the list" (T64)

**Location:** `devcontainer-config/install.sh:851-868` (commits ea2c8fb, 648124c)
**Type:** Configuration / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the label key's match with cc-isolated's launcher, the separation of stderr, the removal of blank lines, and T64 as a regression test. It does not establish, by a live run, that the devcontainer CLI applies `--id-label` as a docker container label: that is the CLI's documented behavior, and no docker daemon was reachable here.

```bash
# devcontainer-config/install.sh:859-867
    errf="$(mktemp "${TMPDIR:-/tmp}/cw-docker-err.XXXXXX")"
    if ! ctrs="$(timeout 20 docker ps --filter label=cc-project \
                   --format '{{.Names}} cc-project={{.Label "cc-project"}}' 2>"$errf")"; then
      err="$(head -n 1 "$errf" 2>/dev/null)"
      echo "NOTE: docker is unreachable ($err): cc-isolated containers not checked, treated as none running." | vis
      ctrs=""
    fi
    rm -f "$errf"
    ctrs="$(printf '%s\n' "$ctrs" | awk 'NF')"
```
(excerpt ends :867; the enclosing `agent_gate()` continues to :886, read)

The launcher uses `--id-label "cc-project=$pid"` at `cc-isolated.sh:412` and `:623`. These are the only two id-label sites.

T64 passes at b4fd792. Against 66891a7's install.sh (the parent of 648124c), T64 fails, and its output lists `WARNING: some docker CLI notice` under "Running cc-isolated containers". That confirms T64 catches the regression the commit describes. The commit said T64 had not been run against the pre-fix code; that run is now done. The "failed 53 tests" figure matches the 53 `not ok` lines in the context log `execution-logs/q058-648124c/ih-66891a7.log`.

**Evidence:** `devcontainer-config/install.sh:851-868`; `devcontainer-config/cc-isolated.sh:410-413`, `:621-624`; `docs/reviews/execution-logs/q058-r3-b4fd792/prefix-66891a7-T64.log`, `suites.log`

---

## Claim 13: "A cc-isolated container writes the checkout, `.git` included, through its bind mount, whatever uid it runs as."

**Location:** `docs/decisions/037-bare-host-copy-install.md:64`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the read-write workspace bind mount of an ordinary checkout. It does not establish a linked worktree checkout, whose `.git` data sits outside the mounted folder. Nor does it establish container-side permission details (uid mapping), which were not read.

```jsonc
// devcontainer-config/devcontainer.json:134
  "workspaceMount": "source=${localWorkspaceFolder},target=/workspace,type=bind,consistency=delegated",
```

**Evidence:** `devcontainer-config/devcontainer.json:134`

---

## Claim 14: "The hash check (R2) catches a stage edited while the prompt waits."

**Location:** `docs/decisions/037-bare-host-copy-install.md:66`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the host target. It does not establish anything for the devcontainer target, which has no hash check.

The only `payload_hash` comparison is in `install_claude_home`:

```bash
# devcontainer-config/install.sh:729
  if [ "$(payload_hash "$dest" .cw-new. "$dest/.cw-new.manifest")" != "$reviewed_hash" ]; then
```

`install_devcontainer` copies `$stage/$item` straight to `$DEST` after its gate (`:399-402`) with no comparison (the prior rubric's R1). The sentence sits in a section about both targets. The precise version: "The hash check (R2) catches a host-target stage edited while the prompt waits; the devcontainer target relies on the gate alone."

**Evidence:** `devcontainer-config/install.sh:586-589`, `:729-734`, `:390-402`

---

## Claim 15: "a Claude Code process of the user's uid: `pgrep -u <uid> -af` for a command line that runs `claude` (argv0 `claude` or `…/claude`, the native binary) or the npm package"

**Location:** `docs/decisions/037-bare-host-copy-install.md:69` (also commit ea2c8fb, "matches the claude CLI's command-line shape")
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the regex matching the described shapes (executed, Claim 11) and one live process. It does not establish that every real launcher produces these shapes: native versioned installs, IDE extensions and SDK wrappers were not observed.

In this sandbox, the only live Claude Code process is PID 1750. Its cmdline is `claude` and its comm is `claude`. It is an npm global install whose `bin/claude` links to `@anthropic-ai/claude-code/bin/claude.exe`. The real pgrep matched it. Two nearby shapes miss:
- The native installer's versioned binary, `…/.local/share/claude/versions/<ver>`, when exec'd by absolute path.
- An argv0 of `claude-code`.

No native install or IDE extension was available to observe. b4fd792's notes also call the VS Code extension's shape unverified. To verify, the probe needs to run on the bare host with each launcher in use: the native install, the VS Code extension, and the SDK.

**Evidence:** `devcontainer-config/install.sh:834`; `docs/reviews/execution-logs/q058-r3-b4fd792/regex-probe.log`; `ps -o pid,comm,args -p 1750` (paraphrased, no quote available because the command was run interactively and not captured to a file; output `1750 claude claude`)

---

## Claim 16: "Both need a crafted name, which needs an agent, which the gate refuses."

**Location:** `docs/decisions/037-bare-host-copy-install.md:73`
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers what the gate can observe. It does not establish whether an agent can write `~/.claude/.claude-workflows-backup` on a given host: that depends on the sandbox denyWrite setting.

The gate only looks at processes and containers running at three moments (`:947`, `:391`, `:695`): `pgrep -u "$(id -u)" -af` and `docker ps` (`install.sh:845`, `:860`). A crafted name is a file-system object, and it outlives the agent that made it. Two examples:
- A backup directory whose name holds a TAB, planted by an earlier session.
- A newline-named directory that the user later runs install.sh from.

Both persist after the agent exits, and the gate never inspects them. The TAB mis-prune path is still live at `:806-807` (`printf '%s\t%s\n' "$e" "${d##*/}"` … `| cut -f2`). Only newlines are skipped, at `:801`. The residual can reasonably still be accepted, since writing either name needs write access that already allows worse. But the stated reason, "the gate refuses", is not the mechanism.

**Evidence:** `devcontainer-config/install.sh:796-807`, `:838-886`, `:443-456`

---

## Claim 17: "A process the probe misses: an agent on another host or in another container runtime writing the checkout (a network or shared mount), a renamed or wrapped binary whose command line does not end in `claude`, one running under another uid, or a docker the user's uid cannot reach."

**Location:** `docs/decisions/037-bare-host-copy-install.md:75`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the listed categories, all of which are real misses. It does not establish that the list is complete.

The umbrella ("a process the probe misses") is right. The listed examples leave out three misses that the code shows:
- (i) An agent that starts after one gate and exits before the next. The gate samples three moments (Claim 10).
- (ii) A non-Claude process of the user's uid left behind by an earlier session, such as a background shell job. The probe matches only Claude command lines (`CLAUDE_PROC_RE`, `install.sh:834`).
- (iii) The native versioned binary path, which is not "renamed" (Claim 15; probe miss logged).

The phrase "command line does not end in `claude`" is also imprecise. The regex matches any `/claude` or `claude.exe` token followed by a space or the end of the line, an argv0 of `claude`, or the npm package path anywhere in the line. The execution log shows `…/claude --output-format stream-json` matching.

**Evidence:** `devcontainer-config/install.sh:834`, `:845`; `docs/reviews/execution-logs/q058-r3-b4fd792/regex-probe.log`

---

## Claim 18: "The probe is also a new way for the install to be refused on a host where some unrelated command line ends in `/claude`; the message names the process."

**Location:** `docs/working/plan-copy-install-bare-host.md:244`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the false-positive classes seen with the real pgrep. It does not establish how often they occur on the user's host.

A false positive does not need the `/claude` at the end of the line. `vim ./claude` matched, and `(^|/)claude(\.exe)?( |$)` also matches a `/claude` token followed by more arguments (for example `vim ./claude notes.txt`), a bare argv0 of `claude`, or any line containing `/@anthropic-ai/claude-code/`. In an earlier interactive pgrep run in this review, the review shell's own command line matched too, because the text of that command contained the regex (paraphrased, no quote available because that run was interactive and not captured to a file). The precise version: "…where some unrelated command line has a `/claude` token or an argv0 of `claude`." The second half ("the message names the process") is verified (`install.sh:874-875`).

**Evidence:** `devcontainer-config/install.sh:834`, `:873-876`; `docs/reviews/execution-logs/q058-r3-b4fd792/regex-probe.log`

---

## Claim 19: The named tests T50–T64 exist and assert what their commits say (plan: "(T50-T56)", "(T57, T58) … (T59, T60) … (T61, T62)"; T63 "pins the section and the Risks line"; T64)

**Location:** `docs/working/plan-copy-install-bare-host.md:244-245`; `test/install-host.bats` T50–T64
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the existence and pass status of all 15 tests, and whether their assertions match each commit's description. It does not establish that T61 tests the host-target NUL scan separately (Claim 2), or that T57 asserts ordering before the gate (the ordering was established by reading `:941-947`).

`suites.log` shows `ok` for T50, T51, T52, T53, T54, T55, T56, T57, T58, T59, T60, T61, T62, T63 and T64, and all 156 tests in the two suites. Checks against the commit descriptions:
- T50 asserts no `[y/N]`, no `Canonical`, no mirror and an unchanged snapshot.
- T54's feed answers n to the devcontainer target, then creates the agent marker while the host prompt waits. It asserts `Install these files` and `777 claude`, and that no `.cw-new.*` or lock is left.
- T55 creates the marker after the mirror's `.manifest` appears.
- T63 greps `^## Trust model (Q-058)`, the rubric link, the four residual keywords, and `Q-058` in the plan's Risks section.

**Evidence:** `test/install-host.bats` T50–T64 (diff lines 415–623 of `diff.patch`); `docs/reviews/execution-logs/q058-r3-b4fd792/suites.log`

---

## Claim 20: "install.sh is 958 lines after the review, fact-check and Q-058 fixes (808 before Q-058)"

**Location:** `docs/working/plan-copy-install-bare-host.md:248`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers line counts at b4fd792 and at 9ae6e46. It does not establish anything past b4fd792.

`wc -l` gives 958 at b4fd792 and 808 at 9ae6e46. It gives 948 at 66891a7, which matches that commit's own figure, since corrected by b4fd792.

**Evidence:** `devcontainer-config/install.sh:958` (last line, `main "$@"; exit $?`); `git show 9ae6e46:devcontainer-config/install.sh | wc -l` → 808 (paraphrased, no quote available because this was an interactive count not captured to a file)

---

## Claim 21: "the existing suites stub them to "none", because the session running them is itself a claude process" / "the session running these tests is a Claude Code process, so both report none."

**Location:** `test/cc-isolated-functions.bats:44-48`; `test/install-host.bats:35-41` (commit ea2c8fb)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the two suites that run install.sh. `link-claude-home-wiring.bats` and the two `test/hooks` suites only mention install.sh; they do not run it. It does not establish that the docker stub is harmless to the cc-isolated tests beyond this run.

```bash
# test/cc-isolated-functions.bats:46-47
  printf '#!/usr/bin/env bash\nexit 1\n' > "$TEST_TMPDIR/bin/pgrep"
  printf '#!/usr/bin/env bash\nexit 0\n' > "$TEST_TMPDIR/bin/docker"
```

The real pgrep with install.sh's regex lists `1750 claude` in this session, so an unstubbed suite would be refused. Both suites pass, 156/156.

**Evidence:** `test/cc-isolated-functions.bats:41-49`; `test/install-host.bats:35-41`, `:369-377`; `docs/reviews/execution-logs/q058-r3-b4fd792/suites.log`, `regex-probe.log`

---

## Claim 22: "No env override for the probes: tests use PATH stubs, so the gate has no bypass beyond what PATH already allows."

**Location:** commit ea2c8fb (Notes line); `devcontainer-config/install.sh:834-868`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the knobs install.sh itself defines. It does not establish anything about environment variables read by the probed tools.

install.sh defines no override: `CLAUDE_PROC_RE` is assigned unconditionally at the top level (`:834`), so an exported value is overwritten, and `agent_gate` reads no other variable except `TMPDIR` for its temp file. But docker's own environment (`DOCKER_HOST`, `DOCKER_CONTEXT`) chooses which daemon `docker ps` asks. A daemon that is unreachable fails open with one NOTE (`:860-865`). A reachable, different daemon returns an empty list silently. Decision 037 accepts "a docker the user's uid cannot reach" but not a different daemon. The precise version: "install.sh adds no override; PATH and docker's own daemon-selection variables can still blind the probes."

**Evidence:** `devcontainer-config/install.sh:834`, `:838-868`

---

## Claim 23: "T9 now copies the committed hooks/scripts (git archive) instead of the tree, whose ignored __pycache__/*.pyc the new check refuses; T58's perl stub fails vis only, so the NUL scan runs real perl."

**Location:** `test/install-host.bats` T9 and T58 (commit 8d9be0c)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the T9 fixture change and T58's stub dispatch. It does not establish that `__pycache__` holds NUL bytes in every checkout (it is git-ignored and local).

```bash
# test/install-host.bats (T9)
  git -C "$CONFIG_SRC/.." archive HEAD hooks scripts | tar -xf - -C "$ROOT"
# test/install-host.bats (T58)
  printf '#!/bin/bash\ncase "$1" in -pe) cat >/dev/null; exit 1 ;; esac\nexec %s "$@"\n' \
```

vis calls `perl -pe` (`install.sh:120`), so `$1` is `-pe`. The NUL scan calls `perl -0ne` (`:186`), which falls through to the real perl. T9 and T58 pass.

**Evidence:** `devcontainer-config/install.sh:120`, `:186`; `test/install-host.bats` T9, T58; `docs/reviews/execution-logs/q058-r3-b4fd792/suites.log`

---

## Claim 24: "All suites: 315/315." (648124c) / "Suites 315/315." (b4fd792)

**Location:** commits 648124c and b4fd792 (message bodies)
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the two suites that run install.sh (156/156, run here). It does not establish which suite set totals 315.

The context log `execution-logs/q058-648124c/suites.log` shows `1..315`, but neither commit names the suites. `bats --count` gives 689 for all of `test/*.bats`, and 208 for the five files that mention install.sh (170 + 20 + 18) (paraphrased, no quote available because the counts were interactive and not captured). To verify, the commit needs to name the suite list.

**Evidence:** `docs/reviews/execution-logs/q058-r3-b4fd792/suites.log`; `docs/reviews/execution-logs/q058-648124c/suites.log` (context)

---

## Claim 25: "There is one convention … First close every Claude Code session and stop every cc-isolated container: the installer refuses to stage or install while either runs (Q-058; see `install.sh --help` and decision 037, "Trust model")"

**Location:** `guides/bare-host-hook-wiring.md:17-20`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the refusal behavior and the two cross-references (the `--help` text at `install.sh:51-58`, and decision 037's `## Trust model (Q-058)` at line 60). It does not establish the detector's completeness (Claims 15 and 17).

T56 greps this guide for `Q-058` and `cc-isolated container` and passes. The behavior is the same as in Claim 1.

**Evidence:** `guides/bare-host-hook-wiring.md:17-20`; `devcontainer-config/install.sh:51-58`; `docs/decisions/037-bare-host-copy-install.md:60`; `docs/reviews/execution-logs/q058-r3-b4fd792/suites.log`

---

## Claims Requiring Attention

### Incorrect
- **Claim 7b** (commit fa69656 Notes; `install.sh:600-654`): a vis failure on the host target's REPLACE, MOVE or ADD lines never reaches `review_diff`. `set -e` and `pipefail` end the run at the first `| vis`, silently (exit 1, no error line). Fail-closed, but the note's mechanism is wrong. Say so, or make those pipes report.
- **Claim 16** (`docs/decisions/037-bare-host-copy-install.md:73`): the gate sees only agents running at its three probe moments. A crafted TAB or newline name planted by an earlier session persists, so "which the gate refuses" does not cover these residuals. Restate why they are accepted.

### Stale
- none

### Mostly Accurate
- **Claim 9** (`install.sh:350-358`): no-follow only at `claude-home`. The directories above are checked once, before `git archive`, and followed afterwards.
- **Claim 14** (`037:66`): the R2 hash check covers the host target only. The devcontainer target has none.
- **Claim 17** (`037:75`): the residual list omits agents that run between probes, leftover non-Claude processes, and the native versioned-binary path. "Does not end in `claude`" misdescribes the regex.
- **Claim 18** (`plan:244`): false positives are any `/claude` token or an argv0 of `claude`, not only lines ending in `/claude`.
- **Claim 22** (commit ea2c8fb Notes): install.sh adds no override, but docker's `DOCKER_HOST`/`DOCKER_CONTEXT` still choose the daemon the container probe asks.

### Unverifiable
- **Claim 15** (`037:69`): whether every real Claude Code launcher (native versioned install, VS Code extension) produces an argv0 of `claude` or `…/claude`. This needs a pgrep probe on the bare host with each launcher.
- **Claim 24** (commits 648124c, b4fd792): "315/315". The suite set is not named. The two install.sh suites pass 156/156.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report in the code-fact-check skill's format, saved to the output path named at the end of this prompt.
- Answered: yes. 25 claims, all with executed or static evidence. The report is saved to `/workspace/docs/reviews/code-fact-check-report-r3.md`.
- Out of scope: whether the gate's point sampling is an adequate design, as against a continuous check. That is for the security critic. This report only notes that the docs' residual list omits it (Claim 17).
- Escalate: Claim 16. Decision 037 accepts the A4/A5 residuals on the grounds that "the gate refuses" the agent, but the gate cannot see a name planted by an earlier session. The residual may still be acceptable, but its stated reason is false, and the user's Q-058 answer relied on the decision text.
- Questions I would have asked: which suites make up "315/315"?
- Decisions I made: I split fa69656's `| vis` note into 7a (MODE, Verified) and 7b (MOVE/ADD, Incorrect), because the two parts diverge in mechanism. I ran T58 before the fix with `LC_ALL=C`, because the sandbox's broken locale triggers the separate bug 648124c fixed. I did not add to `hallucination-patterns.md`: neither Incorrect claim is a fabricated symbol or API.
