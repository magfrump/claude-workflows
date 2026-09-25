Commit: b4fd792

# Code Fact-Check Report

**Repository:** claude-workflows, worktree `/workspace/.claude/wt-copyinstall`, branch `ans/copy-install` at `b4fd792`
**Scope:** commit range `9ae6e46..b4fd792` (8 commits), limited to `devcontainer-config/install.sh` (all 958 lines read), `test/install-host.bats`, `test/cc-isolated-functions.bats`, `README.md`, `docs/decisions/037-bare-host-copy-install.md`, `guides/bare-host-hook-wiring.md`, `docs/working/plan-copy-install-bare-host.md`, and the commit messages. `docs/reviews/` files are context only. Commit-message locations cite `review/log.txt:<line>`, meaning `/tmp/claude-1000/-workspace/7630264d-3947-4203-a0ec-b9ffcc3a4e06/scratchpad/review/log.txt`.
**Checked:** 2026-09-24 (the sandbox clock stamps the execution logs 2026-09-25 UTC)
**Total claims checked:** 32
**Summary:** 22 verified, 8 mostly accurate, 0 stale, 2 incorrect, 0 unverifiable

Hallucination-pattern log: read (`docs/reviews/hallucination-patterns.md`). Test-count claims fit the logged pattern "All 85 tests … pass but suites hold 97", so both test counts here were re-run: "315/315" (Claim 31) and "failed 53 tests" (Claim 31). Both hold. No other claim resembles a logged pattern.

Execution logs are under `docs/reviews/execution-logs/`, prefixed `q058-r1-`. The scratch bats file and the scripts that produced them are saved next to them (`q058-r1-scratch-experiments.bats`, `q058-r1-*.sh`). The scratch tests copy b4fd792's `install-host.bats` helpers (setup, stubs, `fake_repo`, `run_pty`) verbatim, then add experiments X1 to X4. Every run is hermetic: HOME, TMPDIR and all destinations sit inside `BATS_TEST_TMPDIR`, and the real `~/.claude` is never touched.

---

## Claim 1: "Before it stages anything, and again after each y, it refuses while a Claude Code process of your uid or a running cc-isolated container … is found, and names each one with how to stop it." / "the installer refuses to stage or install while either runs"

**Location:** `README.md:33-39`, `guides/bare-host-hook-wiring.md:17-20`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers where the gate is called and what its refusal message says. It does not establish that the probe finds every agent (see Claims 10 and 21), and it does not establish that anything runs between the calls: the gate takes a sample at three points and does not watch continuously (Claim 18).

The three call sites are quoted in Claim 9. The refusal names each process and container and says how to stop each one:

```bash
# devcontainer-config/install.sh:873-882
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
(excerpt ends :882; enclosing agent_gate() continues to :886 — read)
```

Executed: `bats test/install-host.bats`, cwd `/workspace/.claude/wt-copyinstall`, 2026-09-25T06:38:42Z, exit 0, 64/64 ok. T50 (refused at startup, with no `[y/N]`, no `Canonical` line and no mirror created), T51 (container named, `docker stop`), T54 and T55 (refused after each y) all pass.

**Evidence:** `devcontainer-config/install.sh:390-391`, `:694-695`, `:870-885`, `:947`; `test/install-host.bats:791-887`; `docs/reviews/execution-logs/q058-r1-install-host-bats.log`

---

## Claim 2: "and so is a payload file holding a NUL byte (a binary the diff cannot show)" / "extract_commit scans every staged file (both targets) and refuses, listing them through vis, any file holding a NUL, before any review or prompt"

**Location:** `devcontainer-config/install.sh:49`, `devcontainer-config/install.sh:181-199`, `review/log.txt:85-86`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the scan inside `extract_commit` and the fact that both targets reach it (via `assemble` at :219, and at :349 for the devcontainer items), before any review. It does not establish that the host target's own scan is exercised separately by a test: T61's first run is refused in the devcontainer target's `assemble`, which is the same function.

```bash
# devcontainer-config/install.sh:186-199
  if ! nul="$(cd "$dir" && find . -type f -print0 | LC_ALL=C sort -z | LC_ALL=C perl -0ne '
        chomp; open(my $f, "<:raw", $_) or die "$_: $!\n";
        my $c = do { local $/; <$f> };
        print substr($_, 2), "\n" if defined $c && index($c, "\0") >= 0;')"; then
    echo "ERROR: could not scan the staged payload for NUL bytes. Nothing was installed." >&2
    exit 1
  fi
  if [ -n "$nul" ]; then
    ...
    printf '%s\n' "$nul" | sed 's/^/         /' | vis >&2
    ...
    exit 1
  fi
}
```

`assemble` calls `extract_commit "$commit" "$stage" "${CLAUDE_HOME_SRC[@]}"` (`:219`). Both targets call `assemble` before their review: the devcontainer target at `:348`, followed by `extract_commit "$STAGED_COMMIT" "$stage" "${dc_paths[@]}"` at `:349`, and the host target at `:585`. T61 passes (64/64 log): it lists `hooks/blob.bin`, never prints `Binary files` or `[y/N]`, and on the second run lists `egress/x.bin`.

**Evidence:** `devcontainer-config/install.sh:181-200`, `:212-219`, `:348-349`, `:585`; `test/install-host.bats:954-975`; `docs/reviews/execution-logs/q058-r1-install-host-bats.log`

---

## Claim 3: "without a reachable docker it says so in one line and treats no container as running" / "If docker is missing or unreachable, one line says so and no container is assumed." / "No or unreachable docker: one NOTE line, treated as none running."

**Location:** `devcontainer-config/install.sh:56-57`, `docs/decisions/037-bare-host-copy-install.md:70`, `review/log.txt:26-27`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers how many NOTE lines are printed and what "unreachable" means. It does not establish how a real docker CLI or daemon behaves.

The NOTE is printed on every `agent_gate` call, not once per run:

```bash
# devcontainer-config/install.sh:853-854
  if ! command -v docker >/dev/null 2>&1; then
    echo "NOTE: docker not found: cc-isolated containers not checked, treated as none running."
```

Executed as scratch X3: `bats --show-output-of-passing-tests test/x.bats`, cwd scratch `x/`, 2026-09-25T06:41:02Z, exit 0. A `--yes` run with docker absent printed the NOTE twice (`NOTES=2`: once from the startup gate, once from the gate after target 1). An interactive run that answers y twice would print it three times. "Unreachable" also covers every non-zero exit from `timeout 20 docker ps …` (`:860-865`). That includes a docker that lists a container and then exits non-zero: its stdout is thrown away and the install goes ahead (executed, `q058-r1-gate-docker-fail.log`, 2026-09-25T06:51:27Z, exit 0: `gate returned 0`). A 20-second timeout counts as unreachable too. The precise version: "one NOTE line per check (up to three per run); any docker failure or timeout counts as no container running".

**Evidence:** `devcontainer-config/install.sh:853-868`; `docs/reviews/execution-logs/q058-r1-scratch-experiments.log` (X3, X4), `docs/reviews/execution-logs/q058-r1-gate-docker-fail.log`

---

## Claim 4: "Needs git, perl (the review's control-byte filter) and pgrep; refuses without them."

**Location:** `devcontainer-config/install.sh:66`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers refusal when perl (T57), pgrep (T53) or git is missing. It does not establish that the list is complete: `timeout` (`:860`) is also needed, and without it the docker probe fails open to "unreachable" instead of refusing (static reading: a command-not-found exit 127 is non-zero, so it takes the `:860` failure branch).

perl is checked at `:941-945` and pgrep at `:840-844`. Without git, `head_commit` refuses: `if ! git -C "$REPO_ROOT" rev-parse --verify -q 'HEAD^{commit}'; then … exit 1` (`:130-134`). T53 and T57 pass (64/64 log).

**Evidence:** `devcontainer-config/install.sh:129-135`, `:840-844`, `:860`, `:941-945`; `docs/reviews/execution-logs/q058-r1-install-host-bats.log`

---

## Claim 5: "vis: filter that makes control bytes visible (all but newline and tab; NUL included)" / "-a: a file with a NUL byte … is diffed as text, with vis showing each NUL as "?", rather than as "Binary files differ""

**Location:** `devcontainer-config/install.sh:110-111`, `devcontainer-config/install.sh:262-265`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers NUL handling in `vis` and in `review_diff`. It does not establish how `mode_diff` or the MOVE/ADD listings handle a NUL (they print path names, not contents).

`s/[\x00-\x08\x0b\x0c\x0e-\x1a\x1c-\x1f\x7f]/?/g;` (`:122`), and `diff -ruNa "$dest/$item" "$src/$item" 2>&1 | vis` (`:265`). T62 passes: the output holds `-bad?byte` and no `Binary files` (64/64 log).

**Evidence:** `devcontainer-config/install.sh:119-126`, `:247-281`; `test/install-host.bats:976-987`; `docs/reviews/execution-logs/q058-r1-install-host-bats.log`

---

## Claim 6: "review_diff checks vis's PIPESTATUS too; a non-zero vis aborts before the prompt like any other diff trouble (T58, which reached the prompt with an empty review before this fix)."

**Location:** `devcontainer-config/install.sh:259-271`, `review/log.txt:46-49`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers vis failure inside `review_diff`, both before and after the fix. It does not cover the other `| vis` sites (Claim 27).

```bash
# devcontainer-config/install.sh:265-271
    diff -ruNa "$dest/$item" "$src/$item" 2>&1 | vis && st=(0 0) || st=("${PIPESTATUS[@]}")
    rc="${st[0]}"
    if [ "${st[1]}" -ne 0 ]; then
      echo "ERROR: could not show the review of payload item '$item' (vis exit ${st[1]})." >&2
      echo "       The review diff is incomplete, so nothing was installed." >&2
      exit 1
    fi
(excerpt ends :271; enclosing review_diff() continues to :281 — read)
```

After a failed pipeline, `PIPESTATUS` still holds the `diff | vis` statuses when `st=` expands, because the `&& st=(0 0)` branch is skipped. T58 passes at b4fd792. The pre-fix half was replayed: b4fd792's T58 against ea2c8fb's install.sh, cwd scratch `tree-ea2c8fb`, `env LC_ALL=C … bats -f T58 test/t58.bats`, exit 1. It failed on `could not show the review`, and its output shows `=== Changes this install would make ===` with no diff lines, then `Install this config and bless it? [y/N]`. The first replay (2026-09-25T06:45:06Z) ran in this sandbox's broken-locale shell and failed earlier, on the pre-648124c docker bug. That result is inconclusive and is superseded by the `LC_ALL=C` rerun.

**Evidence:** `devcontainer-config/install.sh:247-281`; `test/install-host.bats:911-927`; `docs/reviews/execution-logs/q058-r1-install-host-bats.log`, `docs/reviews/execution-logs/q058-r1-prefix-replays.log`

---

## Claim 7: "A symlink at claude-home, or at any directory between the repo root and it, would send the rebuild's writes wherever it points …, so refuse one." / "each component from the repo root down to claude-home is checked with -L; a link is refused, named, and left in place (T59, T60)"

**Location:** `devcontainer-config/install.sh:331-345`, `review/log.txt:67-68`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the components below `REPO_ROOT` on the logical `SRC` path, checked once before staging. It does not cover the repo root itself or anything above it, and it does not establish that a link planted after this check and before the `rm` at `:353` is caught (Claim 8).

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

T59 and T60 pass at b4fd792 (64/64 log). The pre-fix half of dfa5791's T60 claim was replayed against fa69656's install.sh (cwd scratch `tree-fa69656`, 2026-09-25T06:50:55Z, exit 1). The install completed (`BLESS-STUB --bless`) instead of refusing, so it wrote through the symlinked `devcontainer-config`. This is consistent with "made the run create claude-home outside the repo".

**Evidence:** `devcontainer-config/install.sh:78`, `:85`, `:331-345`; `test/install-host.bats:928-953`; `docs/reviews/execution-logs/q058-r1-install-host-bats.log`, `docs/reviews/execution-logs/q058-r1-prefix-replays.log`

---

## Claim 8: "No-follow rebuild: rm of a path without a trailing slash removes a link itself, never its target; mkdir fails rather than follow anything that appeared since, so the copy lands in a directory this run just created."

**Location:** `devcontainer-config/install.sh:350-358`, `review/log.txt:69-71`
**Type:** Behavioral / Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the `rm` and `mkdir` of the last path component. It does not establish that the `cp` lands in the directory `mkdir` made when something writes concurrently, and it does not cover the parent components, which are only checked at `:334-345`.

```bash
# devcontainer-config/install.sh:353-358
  rm -rf "$SRC/claude-home"
  if ! mkdir "$SRC/claude-home"; then
    echo "ERROR: could not recreate $SRC/claude-home (something reappeared there). Nothing was installed." >&2
    exit 1
  fi
  cp -Rp "$stage/claude-home/." "$SRC/claude-home/"
```

The `rm` and `mkdir` steps are no-follow, as stated. The `cp` destination `"$SRC/claude-home/"` is resolved again when `cp` runs, through every parent component. So "the copy lands in a directory this run just created" holds only if nothing swaps that directory or a parent between `:354` and `:358` (or a parent between `:339` and `:353`). dfa5791's Notes name the mkdir-to-cp swap as a residual (Claim 28b). The parent components are not named there. The precise version: "…so, absent a concurrent writer, the copy lands in a directory this run just created".

**Evidence:** `devcontainer-config/install.sh:331-358`

---

## Claim 9: "agent_gate refuses … at startup, before either target stages anything; after the devcontainer y, before it writes; after the host y, right before the lock, copies and swap."

**Location:** `devcontainer-config/install.sh:390-391`, `:694-695`, `:947`, `:823-825`; `review/log.txt:17-21`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the three call sites and the fact that nothing writes between each y and its gate. It does not establish what happens between samples (Claim 18). With `--yes` there is no devcontainer y, but the post-target-1 gate still runs.

```bash
# devcontainer-config/install.sh:940-954 (main)
  if ! command -v perl >/dev/null 2>&1; then
    ...
  fi

  agent_gate "Nothing was staged or installed."

  HOST_TMP="" HOST_LOCK="" DC_TMP="" STAGED_COMMIT=""
  trap host_cleanup EXIT

  DECLINED=0
  install_devcontainer
  install_claude_home
(excerpt ends :954; enclosing main() continues to :956 — read)
```

Nothing in `main` before `:947` writes: arg parsing, `has_ctrl`, `CLAUDE_HOME_NAMES`, and the perl check. Target 1: `confirm` at `:380`, then `agent_gate "Nothing was installed. (devcontainer config)"` at `:391`, and the first write is `mkdir -p "$DEST" "$BIN_DIR"` at `:393`. Target 2: `confirm` at `:688`, then `agent_gate` at `:695`, then the lock `mkdir` at `:700-702`. No statement between each confirm and its gate writes. T50, T54 and T55 pass (64/64 log).

**Evidence:** `devcontainer-config/install.sh:379-393`, `:688-702`, `:902-956`; `test/install-host.bats:791-808`, `:860-887`; `docs/reviews/execution-logs/q058-r1-install-host-bats.log`

---

## Claim 10: "A Claude Code process is one of this uid's processes whose command line runs `claude` (the native binary, argv0 "claude" or ".../claude") or the npm package (`node .../bin/claude`, `.../@anthropic-ai/claude-code/...`)."

**Location:** `devcontainer-config/install.sh:827-829`, `:834`, `:845`; `docs/decisions/037-bare-host-copy-install.md:69`; `review/log.txt:23-25`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the command-line shapes the comment lists. It does not establish that these are all the shapes a real agent can have: two stock-adjacent shapes miss (below), and whether Claude Code is ever started under them on this host was not established.

`CLAUDE_PROC_RE='(^|/)claude(\.exe)?( |$)|/@anthropic-ai/claude-code/'` (`:834`), used by `pgrep -u "$(id -u)" -af -- "$CLAUDE_PROC_RE"` (`:845`). Executed with the real procps-ng 4.0.2 `pgrep`, cwd `/workspace`, 2026-09-25T06:40:22Z and 06:40:32Z, exit 0 (`q058-r1-probe-regex.log`). The following matched: this sandbox's live session `1750 claude`, a process with argv0 `claude`, and `node … /node_modules/@anthropic-ai/claude-code/cli.js`. The following did **not** match: argv0 `/home/u/.local/share/claude/versions/2.1.3` (the shape of the native installer's versioned binary when it is exec'd by its real path) and `node … /node_modules/@anthropic-ai/claude-agent-sdk/cli.js` (an Agent-SDK-bundled CLI). Static grep checks against the same regex: `claude-code`, `npx @anthropic-ai/claude-code` (the npx wrapper process; its node child matches) and a capitalised `Claude` also miss.

**Evidence:** `devcontainer-config/install.sh:827-850`; `docs/reviews/execution-logs/q058-r1-probe-regex.log`

---

## Claim 11: "pgrep never lists itself and this script's own command line does not match; $$ is dropped only as a belt-and-braces guard."

**Location:** `devcontainer-config/install.sh:829-831`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers pgrep's self-exclusion and the script's normal command line (`bash …/devcontainer-config/install.sh [--yes]`). It does not cover a checkout path with a component that is exactly `claude` followed by a space, which cannot occur in a path that goes on to `/devcontainer-config/…`.

In the executed probe, pgrep's own PID never appeared. Only the calling shell (whose command line contained the pattern text) and real matches were listed (`q058-r1-probe-regex.log`). The filter is `awk -v self="$$" 'NF && $1 != self'` (`:850`). For the regex to match, `claude` must be followed by a space or the end of the line. In a path such as `/x/claude/devcontainer-config/install.sh` it is followed by `/`, so the script never matches itself (static).

**Evidence:** `devcontainer-config/install.sh:834`, `:845-850`; `docs/reviews/execution-logs/q058-r1-probe-regex.log`

---

## Claim 12: "A command line with a `.../claude` argument (`vim ./claude`, `tail -f /var/log/claude`) also matches: the install is refused, and the message names the process."

**Location:** `devcontainer-config/install.sh:831-833`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers these false positives. It does not claim that every argument containing `claude` matches: `man claude` (preceded by a space, not `/`) does not.

In the probe log, `grep -E` with the regex printed `MATCH vim ./claude`. `/var/log/claude` matches through `/claude$`. A match fills `procs`, and the message prints each one (`:873-876`).

**Evidence:** `devcontainer-config/install.sh:834`, `:869-886`; `docs/reviews/execution-logs/q058-r1-probe-regex.log`

---

## Claim 13: "cc-isolated's containers carry the label cc-project=<id> (its --id-label)."

**Location:** `devcontainer-config/install.sh:851`, `:860-861`; `docs/decisions/037-bare-host-copy-install.md:70`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the fact that cc-isolated passes `--id-label cc-project=<pid>` on both of its `devcontainer` invocation paths. It does not establish, by execution, that the devcontainer CLI turns an id-label into a docker container label (no docker in this sandbox), although decision 016 relies on exactly that for container reuse.

`--id-label "cc-project=$pid")` appears at `devcontainer-config/cc-isolated.sh:412` and `:623`, and install.sh filters `docker ps --filter label=cc-project` (`:860`). `docker ps` without `-a` lists only running containers.

**Evidence:** `devcontainer-config/cc-isolated.sh:410-412`, `:621-623`; `devcontainer-config/install.sh:851-868`; `docs/decisions/016-multi-project-devcontainer-central-config.md:98-101`

---

## Claim 14: "Only stdout is the container list. stderr … is kept apart and shown only when the call fails." / "blank lines are dropped from the list" (T64)

**Location:** `devcontainer-config/install.sh:856-867`, `review/log.txt:124-127`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers stderr separation and blank-line filtering. It does not establish that the failure message is useful: the NOTE shows only the first stderr line (`head -n 1`), which in a shell with a broken locale is the bash `setlocale` warning, not docker's error.

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
(excerpt ends :867; enclosing agent_gate() continues to :886 — read)
```

T64 passes. The full 315-test run also passed in this sandbox's shell, which emits a locale warning on every bash start (Claim 31).

**Evidence:** `devcontainer-config/install.sh:838-886`; `test/install-host.bats:837-848`; `docs/reviews/execution-logs/q058-r1-install-host-bats.log`, `docs/reviews/execution-logs/q058-r1-four-suites.log`

---

## Claim 15: "main refuses at startup when `command -v perl` fails, before the gate or any staging (T57)."

**Location:** `devcontainer-config/install.sh:940-947`, `review/log.txt:45-46`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the order of the perl check, the gate and staging. It does not cover perl that is present but broken (that case is caught by the vis status checks, Claims 6 and 27).

`if ! command -v perl >/dev/null 2>&1; then … exit 1; fi` (`:941-945`) comes before `agent_gate` (`:947`) and `install_devcontainer` (`:953`). T57 passes (64/64 log).

**Evidence:** `devcontainer-config/install.sh:940-954`; `test/install-host.bats:900-910`; `docs/reviews/execution-logs/q058-r1-install-host-bats.log`

---

## Claim 16: "A cc-isolated container writes the checkout, `.git` included, through its bind mount, whatever uid it runs as."

**Location:** `docs/decisions/037-bare-host-copy-install.md:64`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the workspace bind mount configuration. It does not establish file-permission outcomes for a container uid other than the owner's. "Whatever uid" is read as "the mount itself is read-write".

`"workspaceMount": "source=${localWorkspaceFolder},target=/workspace,type=bind,consistency=delegated",` (`devcontainer-config/devcontainer.json:134`). There is no `,readonly` flag, and no separate `.git` mount appears among the `mounts` (`:77`ff; a grep for `\.git`, `:ro` or `readonly` in `devcontainer.json` and `cc-isolated.sh` finds none).

**Evidence:** `devcontainer-config/devcontainer.json:77`, `:134`

---

## Claim 17: "The hash check (R2) catches a stage edited while the prompt waits."

**Location:** `docs/decisions/037-bare-host-copy-install.md:66`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers which targets have a post-prompt hash check. It does not assess whether the gate alone protects target 1.

The R2 hash exists only in the host target: `reviewed_hash="$(payload_hash "$stage" "" "$stage/.manifest")"` (`:589`), checked after the copy at `:729`. The devcontainer target installs straight from `$DC_TMP` with `cp -Rp "$stage/$item" "$DEST/$item"` (`:399-402`) and has no hash check. There, only the gate sampled at `:391` protects a stage edited during the prompt, which is prior-review R1's point about target 1. The precise version: "The hash check (R2) catches a **host-target** stage edited while the prompt waits. The devcontainer target has only the gate."

**Evidence:** `devcontainer-config/install.sh:399-402`, `:586-589`, `:729-734`

---

## Claim 18: "`install.sh` refuses to run while an agent can run … It checks at startup, before either target stages anything, and again after each y, before that target writes to its destination. (The devcontainer target rebuilds its `claude-home` mirror inside the checkout before its prompt; that is a staging copy, not an install.)"

**Location:** `docs/decisions/037-bare-host-copy-install.md:68`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the gate's sampling behaviour against the guarantee as stated at `:66` ("no agent runs from the start of the install to the end of the swap"). The call sites and the mirror parenthetical are accurate (Claim 9).

The gate samples at three instants (`:947`, `:391`, `:695`). It does not watch the whole interval. An agent (or a scheduled `claude -p`) that starts after the startup check and exits before the post-y check is never seen. For target 1 this means an edit to `$DC_TMP/config` made during the review installs without detection, because target 1 has no hash check (Claim 17). For target 2, an agent that starts after `:695` can edit the `.cw-new.*` copies between the hash at `:729` and the `mv` at `:766`. Both need the agent to be absent at every sample. The sentence "refuses to run while an agent can run" reads as continuous enforcement. The precise version: "refuses if an agent is found at startup or after either y".

**Evidence:** `devcontainer-config/install.sh:390-402`, `:694-695`, `:729-768`, `:947`

---

## Claim 19: "File or directory names holding a TAB or newline … Both need a crafted name, which needs an agent, which the gate refuses."

**Location:** `docs/decisions/037-bare-host-copy-install.md:73`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers whether the gate stops the two named residuals (A4, a TAB-named backup dir that mis-prunes; A5, a newline-named working directory). It does not re-verify the underlying A4/A5 behaviour, which the pass-3 fact-check Claims 4 and 6 established.

The gate refuses only agents **running during the install** (Claims 9 and 18). The crafted names persist on disk. An agent can create them at any earlier time, while no install is running:

```bash
# devcontainer-config/install.sh:798-807 (prune candidates)
      for d in "$bkroot"/*/; do
        d="${d%/}"
        case "$d" in *$'\n'*) continue ;; esac
        if [ "$d" = "$backup" ] || [ -L "$d" ] || [ -L "$d/.install-stamp" ]; then continue; fi
        [ -f "$d/.install-stamp" ] || continue
        e="$(sed -n 's/^installed_epoch=\([0-9][0-9]*\)$/\1/p' "$d/.install-stamp")"
        [ -n "$e" ] || continue
        printf '%s\t%s\n' "$e" "${d##*/}"
      done | LC_ALL=C sort -t "$(printf '\t')" -k1,1nr -k2,2r | tail -n +3 | cut -f2)
(excerpt starts :798 inside install_claude_home(), which runs :530-816 — read)
```

A directory under `~/.claude/.claude-workflows-backup/` whose name holds a TAB, with a forged `.install-stamp`, can be created by any same-uid agent days before the install. The gate never sees that agent. The same is true of a newline-named directory in the checkout from which the user later runs with a relative `CLAUDE_HOME_DIR`. dfa5791 handles the analogous planted-in-advance case (a symlink at `claude-home`) with an explicit on-disk check (Claim 7), not with the gate. The stated mechanism, "the gate refuses [the agent that crafts the name]", does not hold. A reader would take A4 and A5 as closed by Q-058 when they are not.

**Evidence:** `devcontainer-config/install.sh:794-808`, `:838-886`; `docs/reviews/code-review-rubric-2026-09-23-ans-copy-install-final.md:29-30`

---

## Claim 20: "git obeys the checkout's `.git/config` (hooks paths, `core.fsmonitor`, filters) when `install.sh` runs `git archive` and `git status`."

**Location:** `docs/decisions/037-bare-host-copy-install.md:74`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers which git commands install.sh runs in the checkout. It does not establish which config keys each subcommand honours.

install.sh also runs `git -C "$REPO_ROOT" rev-parse --verify -q 'HEAD^{commit}'` (`:130`) and `git -C "$REPO_ROOT" cat-file -e "$commit:$item"` (`:150`), in addition to `archive` (`:162`) and `status` (`:225-226`). The list should read "every git command it runs (`rev-parse`, `cat-file`, `archive`, `status`)". The residual's conclusion (the same exposure as any user git command) is unaffected. As in Claim 19, a `.git/config` edit can also be planted before the install, when the gate is not running.

**Evidence:** `devcontainer-config/install.sh:130`, `:150`, `:162`, `:225-226`

---

## Claim 21: "A process the probe misses: an agent on another host or in another container runtime writing the checkout …, a renamed or wrapped binary whose command line does not end in `claude`, one running under another uid, or a docker the user's uid cannot reach."

**Location:** `docs/decisions/037-bare-host-copy-install.md:75`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers whether the listed residual categories match the probe's real misses. It does not establish whether any stock Claude Code launcher (VS Code extension, auto-updater restart) starts the CLI under a non-matching argv0. b4fd792's Notes leave that unverified.

The four categories are real. The list leaves out misses that are neither "renamed" nor "wrapped" by the user. (a) The native installer's own file name is a version string (`…/share/claude/versions/<ver>`), and a process exec'd by that path does not match (executed, Claim 10). (b) An Agent-SDK-bundled CLI (`…/@anthropic-ai/claude-agent-sdk/cli.js`) does not match (executed, Claim 10). (c) Any agent absent at the three sample instants is missed, including a short-lived one (Claim 18). (d) Any docker failure or a 20-second timeout counts as "cannot reach", including a docker that listed a container and then exited non-zero (Claim 3, X4). The revisit trigger at `:83` covers (a) and (b) only if someone notices the process shape changed.

**Evidence:** `docs/decisions/037-bare-host-copy-install.md:75`, `:83`; `devcontainer-config/install.sh:834`, `:860-865`; `docs/reviews/execution-logs/q058-r1-probe-regex.log`, `docs/reviews/execution-logs/q058-r1-gate-docker-fail.log`

---

## Claim 22: Plan Risks: "(T50-T56)" for the gate; "perl is required at startup and a `vis` failure aborts the review (T57, T58); the `claude-home` mirror is never rebuilt through a symlink (T59, T60); payload files holding a NUL byte are refused, and the review diffs as text (T61, T62)"; "install.sh is 958 lines … (808 before Q-058)"

**Location:** `docs/working/plan-copy-install-bare-host.md:244-245`, `:248`
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the test IDs and line counts. It does not endorse the Risks line's residual list, which repeats decision 037 (Claims 19 and 21). "some unrelated command line ends in `/claude`" is a slight understatement: any argument ending in `/claude` matches (Claim 12).

`wc -l` on the worktree's install.sh gives 958. `git show 9ae6e46:devcontainer-config/install.sh | wc -l` gives 808. T50 to T62 exist at `test/install-host.bats:791-987` and pass (64/64 log).

**Evidence:** `devcontainer-config/install.sh:958`; `test/install-host.bats:791-987`; `docs/reviews/execution-logs/q058-r1-install-host-bats.log`

---

## Claim 23: T50–T64 exist and assert what their commits say (ea2c8fb T50–T56, fa69656 T57–T58, dfa5791 T59–T60, 8d9be0c T61–T62 and T9, 66891a7 T63, 648124c T64)

**Location:** `test/install-host.bats:278-288`, `:791-1000`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the existence of each test, what it asserts, and that it passes at b4fd792. It does not establish that each test fails before its fix except T58 and T60 (replayed, Claims 6 and 7) and T64 (the commit itself says it was not replayed).

Each test was read in full, and each asserts what its commit claims. T50 checks no `[y/N]`, no `Canonical`, no mirror, and `pgrep -u $(id -u) -af` in `probe.log`. T51 checks the container name and `docker stop`. T52 checks the unreachable and missing-docker NOTEs and that the install goes ahead. T53 refuses without pgrep. T54 and T55 cover an agent appearing during each prompt. T56 checks the docs grep. T57 and T58 cover perl and vis. T59 and T60 cover the symlinks. T61 and T62 cover NUL. T63 checks the 037 section and the plan's Risks. T64 covers docker stderr. T9 now uses `git -C "$CONFIG_SRC/.." archive HEAD hooks scripts | tar -xf - -C "$ROOT"` (`:283`). Executed: `bats test/install-host.bats`, 64/64, exit 0.

**Evidence:** `test/install-host.bats:32-72`, `:278-288`, `:791-1000`; `docs/reviews/execution-logs/q058-r1-install-host-bats.log`

---

## Claim 24: "install.sh's no-agent gate (Q-058) asks pgrep and docker what runs; the session running these tests is a Claude Code process, so both report none."

**Location:** `test/cc-isolated-functions.bats:44-48`, `review/log.txt:28-29`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the premise (a live claude process of this uid exists) and the stubs in the two suites that run install.sh. It does not cover other suites, which only grep install.sh and never run it (`link-claude-home-wiring.bats:270`, `hooks/claude-config-audit.bats:231`, `hooks/live-verify-gate.bats:74`).

The real `pgrep` with the gate's regex lists `1750 claude` in this sandbox (`q058-r1-probe-regex.log`). Without the stubs, the gate would refuse every run. The stubs `printf '#!/usr/bin/env bash\nexit 1\n' > "$TEST_TMPDIR/bin/pgrep"` (`:46`) and `stub_pgrep 'exit 1'` (`install-host.bats:39`) make it report nothing.

**Evidence:** `test/cc-isolated-functions.bats:41-49`; `test/install-host.bats:35-42`; `docs/reviews/execution-logs/q058-r1-probe-regex.log`

---

## Claim 25: "No env override for the probes: tests use PATH stubs, so the gate has no bypass beyond what PATH already allows."

**Location:** `review/log.txt:34-35`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers install.sh's own code and the documented behaviour of the tools it calls. It does not cover editing install.sh itself, which decision 035 covers.

install.sh reads no environment variable in `agent_gate` apart from `TMPDIR` for the stderr temp file (`:859`). That half is true. But the container probe fails open on any docker failure or timeout (Claim 3), and the docker CLI picks its daemon from its own environment and config (`DOCKER_HOST`, `DOCKER_CONTEXT`, `~/.docker/config.json`; paraphrased — no quote available because this is the docker CLI's documented behaviour, external to the repo). So pointing either at a dead socket turns the container check into "treated as none running" without touching PATH. It does print the NOTE. The accurate version: "no bypass beyond PATH, or anything that makes docker fail, which is announced by a NOTE and treated as no container". Decision 037's residual "a docker the user's uid cannot reach" covers the outcome but not this route to it.

**Evidence:** `devcontainer-config/install.sh:838-868`; `docs/reviews/execution-logs/q058-r1-gate-docker-fail.log`

---

## Claim 26: "T58, which reached the prompt with an empty review before this fix"

**Location:** `review/log.txt:48-49`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the pre-fix behaviour at ea2c8fb (the parent of fa69656), run with `LC_ALL=C` so the separate pre-648124c docker bug does not fire. It does not cover "an unchanged one read as (none)", which was not replayed.

See Claim 6 for the command and output. The pre-fix run printed an empty `=== Changes … ===` block and then `Install this config and bless it? [y/N]`.

**Evidence:** `docs/reviews/execution-logs/q058-r1-prefix-replays.log`, `docs/reviews/execution-logs/q058-r1-prefix.sh`

---

## Claim 27: "other `| vis` uses (MODE, MOVE, ADD lines) are not individually checked; perl missing is now refused up front, and a vis that fails there fails in review_diff too, which aborts."

**Location:** `review/log.txt:53-55`
**Type:** Error-handling
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the stated mechanism at the host target's MOVE, REPLACE and ADD sites. The practical conclusion (no prompt is reached) holds. It does not cover a vis that fails only on some inputs, which a fixed perl regex does not do.

The mechanism is wrong for the host target. There, `review_diff` is never reached. The script dies at the first `echo … | vis` under `set -euo pipefail` (`:26`), silently, with exit 1 and no error message:

```bash
# devcontainer-config/install.sh:598-601 (install_claude_home, called plainly from main :954)
  for name in "${CLAUDE_HOME_NAMES[@]}"; do
    if [ -L "$dest/$name" ]; then
      echo "REPLACE symlink $dest/$name -> $(readlink "$dest/$name") with a copy" | vis
      changed=1
(excerpt ends :601; enclosing install_claude_home() continues to :816 — read)
```

Executed as scratch X1 and X2 (`bats --show-output-of-passing-tests test/x.bats`, cwd scratch `x/`, 2026-09-25T06:41:02Z, exit 0), with T58's stub, which fails only `perl -pe`. X1 (a first install with a 300-line CLAUDE.md, so ADD lines): `STATUS=1`, the output stops at `=== Changes this install would make ===`, no prompt, and no error text. X2 (a symlink install, so REPLACE and MOVE lines): the same. For a new entry over 200 lines, `review_diff` is not called at all (`:649-655`). The MODE lines differ: `mode_diff` runs in an `||` / `if !` context (`:367`, `:668`), where `set -e` is suspended, so a failing vis there is ignored. There the claimed mechanism (the next `review_diff` aborts) does apply. The precise version: "MODE lines rely on the following review_diff; MOVE, REPLACE and ADD lines abort through set -e/pipefail, with no message."

**Evidence:** `devcontainer-config/install.sh:26`, `:283-305`, `:367-368`, `:598-671`; `docs/reviews/execution-logs/q058-r1-scratch-experiments.log`, `docs/reviews/execution-logs/q058-r1-scratch-experiments.bats`

---

## Claim 28a: "(T60: a symlinked devcontainer-config made the run create claude-home outside the repo)"

**Location:** `review/log.txt:64-65`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the fact that pre-fix install.sh (fa69656) completes through a symlinked `devcontainer-config`. It does not re-check the created path directly, because the replayed T60 stops at its first assertion (status).

See Claim 7. At fa69656 the run finished with `BLESS-STUB --bless` and exit 0, so the mirror rebuild went through the link to `$S/realdc`.

**Evidence:** `docs/reviews/execution-logs/q058-r1-prefix-replays.log`, `docs/reviews/execution-logs/q058-r1-t60.sh`

---

## Claim 28b: "a swap of the fresh directory for a link between mkdir and cp is a residual; it needs an agent running during the install, which the Q-058 gate refuses."

**Location:** `review/log.txt:74-76`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the timing of the mirror rebuild against the gate's samples. It does not assess how likely such a race is.

The mirror `cp` (`:358`) runs **before** the devcontainer prompt. The gate is sampled at `:947` (before) and `:391` (after the prompt). An agent that starts after the startup gate and wins the `mkdir`→`cp` race has its redirected write done before any later gate refuses the install. The gate then refuses the install, not the write that already happened. The precise version: "needs an agent running during the install; the gate refuses one that is running at startup".

**Evidence:** `devcontainer-config/install.sh:353-358`, `:380-391`, `:947`

---

## Claim 29: "No allowlist: `git archive HEAD` of the payload paths holds no NUL today." / "the payload is ~125 small text files" / T9's `__pycache__/*.pyc` rationale

**Location:** `devcontainer-config/install.sh:182-184`, `review/log.txt:87`, `:91-93`, `:96-97`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the committed payload at b4fd792 (122 files). It does not cover future commits.

Executed: `bash q058-r1-nulscan.sh`, running `git -C /workspace archive b4fd792 -- <CLAUDE_HOME_SRC + devcontainer-config PAYLOAD items> | tar -x` and then the same perl NUL scan. Result at 2026-09-25T06:49:58Z: `files: 122`, no `NUL:` lines, scan exit 0. 122 fits "~125".

**Evidence:** `docs/reviews/execution-logs/q058-r1-nul-scan.log`, `docs/reviews/execution-logs/q058-r1-nulscan.sh`

---

## Claim 30: "The plan's Risks record the gate, the post-review hardening (T57-T62) and install.sh's new length (948 lines). T63 pins the section and the Risks line."

**Location:** `review/log.txt:112-114`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the count at 66891a7 itself (b4fd792 later updated the plan to 958, Claim 22) and what T63 asserts. It does not establish that T63 pins the line count (it does not; it greps `Q-058` in Risks).

`git show 66891a7:devcontainer-config/install.sh | wc -l` gives 948. T63 greps `^## Trust model (Q-058)`, the residual keywords, and `Q-058` in the plan's Risks (`test/install-host.bats:988-999`).

**Evidence:** `test/install-host.bats:988-999`

---

## Claim 31: "The suite passed where the shell printed no warning and failed 53 tests where it did." / "All suites: 315/315." (also b4fd792: "Suites 315/315")

**Location:** `review/log.txt:122-123`, `:127`, `:146-147`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** "The suite" is `install-host.bats` (53 failures). The same pre-fix run also failed 8 tests in `cc-isolated-functions.bats` (61 in all), which the message does not mention. "All suites" is the four-suite set used by the Q-058 reports, not all 1,599 tests in the repo.

Pre-fix: the four suites at 66891a7, in this shell with `LC_ALL=en_US.UTF-8` uninstalled (a warning on every bash start), 1..314, exit 1. There were 53 `not ok` in `install-host.bats` (numbers ≤63) and 8 in `cc-isolated-functions.bats`. Post-fix: `bats test/install-host.bats test/cc-isolated-functions.bats test/link-claude-home-wiring.bats test/hooks/*.bats`, cwd `/workspace/.claude/wt-copyinstall` (b4fd792), 2026-09-25T06:43:07Z, exit 0, 1..315 and 315 `ok`.

**Evidence:** `docs/reviews/execution-logs/q058-r1-prefix-replays.log`, `docs/reviews/execution-logs/q058-r1-four-suites.log`, `docs/reviews/execution-logs/q058-r1-four-suites.log.ts`, `docs/reviews/execution-logs/q058-r1-run4.sh`

---

## Claims Requiring Attention

### Incorrect
- **Claim 19** (`docs/decisions/037-bare-host-copy-install.md:73`): the gate does not close the TAB and newline residuals (A4, A5). A crafted name can be planted by an agent at any time before the install, and the gate only refuses agents running during it. Drop "which the gate refuses", or add an on-disk check like dfa5791's symlink check.
- **Claim 27** (fa69656 Notes, `review/log.txt:53-55`): on the host target, a failing vis at a MOVE, REPLACE or ADD line aborts through `set -e`/pipefail, silently (exit 1, no message), not "in review_diff too". Only the MODE lines rely on review_diff. The fail-closed conclusion holds.

### Mostly Accurate
- **Claim 3** (`install.sh:56-57`, `037:70`): the NOTE prints once per gate call (2 in a `--yes` run, up to 3), and any docker failure or timeout, even after it listed a container, counts as none running.
- **Claim 8** (`install.sh:350-358`): "the copy lands in a directory this run just created" holds only with no concurrent writer. Parent components are not re-checked after `:334-345`.
- **Claim 17** (`037:66`): the R2 hash check covers the host target only. The devcontainer target has only the gate.
- **Claim 18** (`037:68`): the gate samples at three instants and does not watch continuously. An agent absent at each sample can still edit target 1's stage or target 2's `.cw-new.*` copies.
- **Claim 20** (`037:74`): install.sh also runs `git rev-parse` and `git cat-file` in the checkout.
- **Claim 21** (`037:75`): the residual list leaves out the native versioned-path argv0, the Agent-SDK `cli.js` path (both verified misses), agents that come and go between samples, and "docker exited non-zero after listing".
- **Claim 25** (ea2c8fb Notes): docker's own environment and config (`DOCKER_HOST`, `DOCKER_CONTEXT`) can switch off the container probe without PATH. It is announced by a NOTE.
- **Claim 28b** (dfa5791 Notes): the mirror `cp` runs before the post-prompt gate, so the gate refuses the install only after a racing agent's redirected write.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report in the code-fact-check skill's format, saved to the output path named at the end of this prompt.
- Answered: yes. 32 verdicts, saved to `/workspace/docs/reviews/code-fact-check-report-r1.md`.
- Out of scope: whether the Q-058 design is sufficient to merge (critics' call); the `docs/reviews/` files in the range (context only); live behaviour of real docker and devcontainer CLIs (no docker in the sandbox); the process shape of the VS Code extension or the native launcher on the user's host.
- Escalate: the prior R1 (target 1 installs whatever is in its stage) is now covered only by point-in-time sampling (Claims 17, 18, 21). A persistent Claude session is caught, but an agent absent at all three samples, the Agent-SDK CLI, or a native binary exec'd by its versioned path is not. Decision 037 does not list these as accepted residuals, and its TAB/newline rationale (Claim 19) is wrong. Whether that is acceptable is the user's call on Q-058's reading, not a fact-check verdict.
- Questions I would have asked: is `@anthropic-ai/claude-agent-sdk` (or any SDK-driven agent) in use on the bare host? If so, Claim 10's miss is not hypothetical.
- Decisions I made: I treated "All suites" as the four-suite set the earlier Q-058 report defined. I split dfa5791's Notes into 28a and 28b because their verdicts differ. The replays of T58 and T60 at pre-fix commits ran with `LC_ALL=C` to keep the separate pre-648124c docker-stderr bug out of the result. The first T58 replay without it is logged as inconclusive.
