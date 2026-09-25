Commit: b4fd792

# Code Fact-Check Report

**Repository:** claude-workflows, worktree `/workspace/.claude/wt-copyinstall`, branch `ans/copy-install` at b4fd792
**Scope:** commit range `9ae6e46..b4fd792` (8 commits), limited to `devcontainer-config/install.sh` (all 958 lines read), `test/install-host.bats`, `test/cc-isolated-functions.bats`, `README.md`, `docs/decisions/037-bare-host-copy-install.md`, `guides/bare-host-hook-wiring.md`, `docs/working/plan-copy-install-bare-host.md`, and the commit messages. `docs/reviews/` files in the range were read as context only. The Q-058 restart re-review after the user answered Q-058 [2].
**Checked:** 2026-09-24
**Total claims checked:** 31
**Summary:** 22 verified, 8 mostly accurate, 0 stale, 1 incorrect, 0 unverifiable

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`): no claim below matches a logged pattern. The one Incorrect verdict is a reasoning error, not a fabricated symbol, so nothing is appended to the log.

**Execution notes.** Every executed probe was hermetic. The suites and probes pin `HOME`, `TMPDIR`, `CLAUDE_HOME_DIR`, `CLAUDE_DEVC_CONFIG_DIR` and `CLAUDE_DEVC_BIN_DIR` into a bats temp dir, stub `pgrep` and `docker` on PATH, and unset `CLAUDECODE`. The installer under test is a copy of b4fd792's `install.sh` inside a throwaway fake repo. The probe suites (`probe.bats`, `probe5.bats`) are the first 171 lines of `test/install-host.bats` (setup, stubs and helpers, unchanged) plus the probe tests. They ran from the scratchpad `probe/test/`, with `probe/devcontainer-config` symlinked to the worktree's, so `fake_repo` copies b4fd792's `install.sh`. The process-shape probe used real `pgrep` (procps-ng 4.0.2) read-only, against `perl` dummies that set `$0`. The dummies were killed by PID afterwards. The shell had `LC_ALL=en_US.UTF-8`, an uninstalled locale, so every log carries `setlocale` warnings. All logs are under `docs/reviews/execution-logs/q058-b4fd792-r2/`.

| Run | Command | cwd | Exit | UTC |
|---|---|---|---|---|
| S1 | `bats test/install-host.bats` → `install-host.bats.log` | `/workspace/.claude/wt-copyinstall` | 0 (64/64) | 2026-09-25T06:38:15Z |
| S2 | `bats test/cc-isolated-functions.bats` → `cc-isolated-functions.bats.log` | same | 0 (92/92) | 2026-09-25T06:39:39Z |
| S3 | `bash run-other-suites.sh <worktree>` (link-claude-home-wiring, test/hooks) → `other-suites.log` | same | 0 (14/14, 145/145) | 2026-09-25T06:44:16Z |
| E1 | `LC_ALL=C bash proc-shape-probe.sh <worktree>/devcontainer-config/install.sh` → `proc-shape-probe.log` | `/workspace` | 0 | 2026-09-25T06:41:01Z |
| E2 | `bats test/probe.bats` (P1–P4) → `probe.bats.log`; again with `--show-output-of-passing-tests` → `probe.bats.verbose.log` | scratchpad `probe/` | 0 (4/4) | 2026-09-25T06:42:17Z / 06:42:32Z |
| E3 | `bats --show-output-of-passing-tests test/probe5.bats` (P5) → `probe5.bats.log` | scratchpad `probe/` | 0 (1/1) | 2026-09-25T06:43:41Z |
| E4 | `bash nul-scan-payload.sh <worktree> <scratch>` → `nul-scan-payload.log` | `/workspace` | 0 | 2026-09-25T06:44:00Z |
| E5 | `grep -E "$CLAUDE_PROC_RE"` over four installer command lines → `self-match-regex.log` | `/workspace` | 0 | 2026-09-25T06:44:44Z |
| E6 | `git show <c>:devcontainer-config/install.sh \| wc -l` for 9ae6e46, 66891a7, 648124c, b4fd792 → `line-counts.log` | `/workspace` | 0 | 2026-09-25T06:47:00Z |

In E2 and E3 a probe "passes" when its assertions confirm the behaviour named in its title, including the unwanted behaviours (P3, P4, P5).

---

## Claim 1: "Before it stages anything, and again after each y, it refuses while a Claude Code process of your uid or a running cc-isolated container (it can write the checkout through its bind mount) is found, and names each one with how to stop it."

**Location:** `README.md:33-39`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the three check points (startup, after the devcontainer y, after the host y) and the refusal message naming each process or container with its stop command. It does not establish continuous coverage between check points (see Claims 17, 20 and 24), and it does not establish that every real agent process is detected (Claims 9 and 20).

The call sites are `agent_gate "Nothing was staged or installed."` (`devcontainer-config/install.sh:947`), `agent_gate "Nothing was installed. (devcontainer config)"` (`:391`) and `agent_gate "Nothing was installed into the host target."` (`:695`). The message names each process (`echo "       Stop them: end each Claude Code session (/exit), or kill <PID>."`, `:876`) and each container (`echo "       Stop them: docker stop <name>"`, `:881`). T50, T51, T54 and T55 passed in S1. The README's wording is precise: "is found" at a check point. Unlike the guide (Claim 24), it does not claim continuous refusal.

**Evidence:** `devcontainer-config/install.sh:391`, `:695`, `:838-886`, `:947`; `test/install-host.bats:791-887`; `docs/reviews/execution-logs/q058-b4fd792-r2/install-host.bats.log`

---

## Claim 2: "install.sh refuses, before it stages anything and again after each y, while any agent can run: a Claude Code process of your uid (pgrep on the command line), or a running cc-isolated container (docker ps, label cc-project). It names each one and how to stop it. Without pgrep it refuses; without a reachable docker it says so in one line and treats no container as running."

**Location:** `devcontainer-config/install.sh:51-58`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the check points, the two detectors as named, the pgrep-missing refusal and the one-line docker NOTE. It does not establish that "while any agent can run" holds between check points or for processes the regex misses (the next sentences of `--help` define "agent" as exactly the two detectors, which is what was verified).

The detectors are `pgrep -u "$(id -u)" -af -- "$CLAUDE_PROC_RE"` (`:845`) and `timeout 20 docker ps --filter label=cc-project` (`:860`). With no pgrep, the gate refuses: `echo "ERROR: pgrep is not installed, so install.sh cannot check that no Claude Code" >&2` … `exit 1` (`:840-844`). With docker absent or failing, one NOTE line is printed (`:854` or `:863`). In S1, T52 (docker unreachable and docker absent → one NOTE line, install proceeds), T53 (no pgrep → status 1), T56 (`--help` mentions both detectors) and T64 passed.

**Evidence:** `devcontainer-config/install.sh:838-886`; `test/install-host.bats:822-899`; `docs/reviews/execution-logs/q058-b4fd792-r2/install-host.bats.log`

---

## Claim 3: "Needs git, perl (the review's control-byte filter) and pgrep; refuses without them."

**Location:** `devcontainer-config/install.sh:66`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers refusal when perl (T57) or pgrep (T53) is missing, and when git is missing (by reading the code). It does not establish that the list is complete: `timeout` (coreutils) is also used, by the docker probe, and a missing `timeout` is not refused. It is reported as "docker is unreachable" and the container check is skipped (fail-open for that detector).

Without perl, `main` refuses before the gate: `if ! command -v perl >/dev/null 2>&1; then echo "ERROR: perl is not installed. …" >&2 … exit 1` (`:941-945`). Without git, `head_commit` fails at `if ! git -C "$REPO_ROOT" rev-parse --verify -q 'HEAD^{commit}'; then … exit 1` (`:130-133`). The message there says "no readable HEAD commit", not "git is missing", but the run is refused. For `timeout`: `if ! ctrs="$(timeout 20 docker ps … 2>"$errf")"; then … echo "NOTE: docker is unreachable ($err): cc-isolated containers not checked, treated as none running." | vis` (`:860-864`). The "command not found" from a missing `timeout` goes to `$errf` and yields this NOTE (paraphrased — no quote available because this is bash's standard behaviour for a missing command under a `2>` redirect, not code in the file). T57 and T53 passed in S1.

**Evidence:** `devcontainer-config/install.sh:129-135`, `:840-844`, `:853-868`, `:940-945`; `docs/reviews/execution-logs/q058-b4fd792-r2/install-host.bats.log`

---

## Claim 4: "vis: filter that makes control bytes visible (all but newline and tab; NUL included)" / "-a: a file with a NUL byte (only ever on the destination side; the stage has none, see extract_commit) is diffed as text, with vis showing each NUL as "?""

**Location:** `devcontainer-config/install.sh:110-111`, `:262-264`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers NUL → `?` in `vis` and `diff -a` in `review_diff` for both targets. It does not establish how the terminal renders other multi-byte sequences (not part of this change).

`s/[\x00-\x08\x0b\x0c\x0e-\x1a\x1c-\x1f\x7f]/?/g;` (`:122`) now starts the class at `\x00`. `diff -ruNa "$dest/$item" "$src/$item" 2>&1 | vis && st=(0 0) || st=("${PIPESTATUS[@]}")` (`:265`; excerpt ends :265, enclosing `review_diff()` continues to :281, read). T62 installs a destination `hooks/h.sh` holding `bad\0byte` and asserts the review shows `-bad?byte` and never `Binary files`. It passed in S1. "Only ever on the destination side" holds because `extract_commit` refuses any staged NUL file (Claim 5).

**Evidence:** `devcontainer-config/install.sh:119-126`, `:247-281`; `test/install-host.bats:976-987`; `docs/reviews/execution-logs/q058-b4fd792-r2/install-host.bats.log`

---

## Claim 5: "No NUL bytes. diff reports such a file as "Binary files ... differ" … The payload is text today (checked 2026-09-23: no committed payload file holds a NUL), so there is no allowlist"

**Location:** `devcontainer-config/install.sh:181-184`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the scan of every regular file in each staged dir, for both targets, before any review or prompt, and the fact that b4fd792's committed payload holds no NUL. It does not establish that future commits stay NUL-free.

`nul="$(cd "$dir" && find . -type f -print0 | LC_ALL=C sort -z | LC_ALL=C perl -0ne '… print substr($_, 2), "\n" if defined $c && index($c, "\0") >= 0;')"` (`:186-189`). A scan failure is fatal (`:190-191`). A hit is listed through `vis` and refused: `printf '%s\n' "$nul" | sed 's/^/         /' | vis >&2` … `exit 1` (`:196-198`). `extract_commit` runs in `assemble` (`:219`) for both targets, and again for the devcontainer items (`:349`), in each case before the review. E4 extracted every payload path of both targets at b4fd792 with the same `git archive` call: `files=122`, `nul_files:` (empty), `scan_exit=0`. T61 (host payload `hooks/blob.bin`, then devcontainer `egress/x.bin`) passed in S1.

**Evidence:** `devcontainer-config/install.sh:140-200`, `:212-219`, `:348-349`; `test/install-host.bats:954-975`; `docs/reviews/execution-logs/q058-b4fd792-r2/nul-scan-payload.log`, `nul-scan-payload.sh`, `install-host.bats.log`

---

## Claim 6: "A vis failure is trouble too: its output is the review, so a failed vis over a differing item read as an empty diff that still reached [y/N]." (and fa69656: "review_diff checks vis's PIPESTATUS too; a non-zero vis aborts before the prompt like any other diff trouble")

**Location:** `devcontainer-config/install.sh:259-271`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers `review_diff`'s handling of a vis failure on every call path, including the host ADD path's `review_diff … || true` (the explicit `exit 1` ignores the `||`). It does not cover the other `| vis` sites (Claim 27).

`… | vis && st=(0 0) || st=("${PIPESTATUS[@]}")`, `rc="${st[0]}"`, `if [ "${st[1]}" -ne 0 ]; then echo "ERROR: could not show the review of payload item '$item' (vis exit ${st[1]})." >&2 … exit 1` (`:265-270`). When the pipeline fails, `st=(0 0)` does not run, so `PIPESTATUS` still holds the `diff | vis` statuses. T58 passed in S1. Probe P2 (E2) had a mode-only change and vis failing. It printed `ERROR: could not show the review of payload item 'devcontainer.json' (vis exit 1).` and no `bless it?`.

**Evidence:** `devcontainer-config/install.sh:247-281`, `:650`; `test/install-host.bats:911-927`; `docs/reviews/execution-logs/q058-b4fd792-r2/install-host.bats.log`, `probe.bats.verbose.log`

---

## Claim 7: "each component from the repo root down to claude-home is checked with -L; a link is refused, named, and left in place" / "No-follow rebuild: rm of a path without a trailing slash removes a link itself, never its target; mkdir fails rather than follow anything that appeared since, so the copy lands in a directory this run just created."

**Location:** `devcontainer-config/install.sh:331-358`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the components below `REPO_ROOT` on the logical path (`devcontainer-config`, `devcontainer-config/claude-home`) and the rm → mkdir → copy-contents sequence. It does not establish anything about `REPO_ROOT` itself or its ancestors (not claimed), about a script invoked through a different physical path (the chain is built from the logical `SRC`), or about a swap between the check and the rebuild (Claim 28).

`IFS=/ read -ra comps <<< "${SRC#"$REPO_ROOT"/}/claude-home"`, then for each component `p="$p/$comp"; if [ -L "$p" ]; then echo "ERROR: $p is a symlink ($(readlink "$p")). …" | vis >&2 … exit 1` (`:336-344`). The rebuild is `rm -rf "$SRC/claude-home"`, `if ! mkdir "$SRC/claude-home"; then … exit 1`, `cp -Rp "$stage/claude-home/." "$SRC/claude-home/"` (`:353-358`). b4fd792 put the `readlink` output through `vis` (`:340`). T59 (link at claude-home: refused, the link and its target untouched) and T60 (symlinked `devcontainer-config`: refused, nothing created in the target) passed in S1.

**Evidence:** `devcontainer-config/install.sh:321-358`; `test/install-host.bats:928-953`; `docs/reviews/execution-logs/q058-b4fd792-r2/install-host.bats.log`

---

## Claim 8: "agent_gate refuses … at startup, before either target stages anything; after the devcontainer y, before it writes; after the host y, right before the lock, copies and swap." (ea2c8fb; also the `install.sh:819-825` comment)

**Location:** `devcontainer-config/install.sh:390-391`, `:694-695`, `:819-825`, `:947`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the order of calls in `main` and in both targets, and that nothing writes between each y and its gate. It does not establish coverage between check points. The host target stages after the devcontainer prompt without a fresh check (P4), and the devcontainer stage is not re-checked for content after y (P3; see Claims 17 and 20).

`main`: the perl check (`:941-945`), then `agent_gate "Nothing was staged or installed."` (`:947`), then `trap host_cleanup EXIT` (`:950`), `install_devcontainer` and `install_claude_home` (`:953-954`). Devcontainer: `if ! confirm 'Install this config and bless it?'; then … return 0; fi` (`:380-387`), then `agent_gate …` (`:391`), then `mkdir -p "$DEST" "$BIN_DIR"` (`:393`). No write sits between them. With `--yes`, the gate still runs, because `:391` is outside the `if`. Host: `if ! confirm "Install these files into $dest?"; then … fi` (`:688-692`), then `agent_gate …` (`:695`), then the lock `mkdir -p "$dest"` … `mkdir "$dest/.claude-workflows-lock"` (`:700-702`). In S1, T50 (startup: no `Canonical`, no claude-home mirror, no `[y/N]`), T54 (host: no lock, no `.cw-new.*`) and T55 (devcontainer: no `$CLAUDE_DEVC_CONFIG_DIR`) passed.

**Evidence:** `devcontainer-config/install.sh:379-393`, `:688-702`, `:902-956`; `test/install-host.bats:791-808`, `:860-887`; `docs/reviews/execution-logs/q058-b4fd792-r2/install-host.bats.log`, `probe.bats.verbose.log`

---

## Claim 9: "A Claude Code process is one of this uid's processes whose command line runs `claude` (the native binary, argv0 "claude" or ".../claude") or the npm package (`node .../bin/claude`, `.../@anthropic-ai/claude-code/...`)."

**Location:** `devcontainer-config/install.sh:827-829`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the shapes the comment lists (they all match under the real pgrep) and the one live Claude Code process on this machine. It does not establish that every real Claude Code launch uses one of these shapes. E1 shows misses for a versioned native path (`…/.local/share/claude/versions/2.0.14 --resume`), `node cli.js` run from the package directory, the Agent SDK's bundled CLI (`…/@anthropic-ai/claude-agent-sdk/cli.js`) and argv0 `claude-code`. Whether any shipped Claude Code build presents those shapes was not observable here.

`CLAUDE_PROC_RE='(^|/)claude(\.exe)?( |$)|/@anthropic-ai/claude-code/'` (`:834`), used as `pgrep -u "$(id -u)" -af -- "$CLAUDE_PROC_RE"` (`:845`). E1 result: MATCH for `claude`, `/usr/local/bin/claude --resume`, `node /usr/local/bin/claude --resume`, `node …/@anthropic-ai/claude-code/cli.js -p x` and `…/resources/native-binary/claude`. It missed the four shapes named in Scope. The live session process on this host (PID 1750) has cmdline `claude` and exe `…/@anthropic-ai/claude-code/bin/claude.exe`. It matches (paraphrased — no quote available because this was read from `/proc/1750/cmdline` and `/proc/1750/exe` at run time, not from a file in the repo).

**Evidence:** `devcontainer-config/install.sh:827-850`; `docs/reviews/execution-logs/q058-b4fd792-r2/proc-shape-probe.log`, `proc-shape-probe.sh`

---

## Claim 10: "pgrep never lists itself and this script's own command line does not match; $$ is dropped only as a belt-and-braces guard."

**Location:** `devcontainer-config/install.sh:829-831`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the installer's own command line under the usual checkout paths, and the `$$` filter. It does not establish the parent processes' command lines (a `script -qec …` wrapper around a checkout path like the one below would also match, and `$$` does not filter it).

The script's own command line does match when the checkout path holds `/claude` followed by a space. E5: `bash /home/u/claude code/devcontainer-config/install.sh` → MATCH, while `bash ./devcontainer-config/install.sh` and `bash /home/u/claude/devcontainer-config/install.sh` miss. In that case the `$$` filter is what removes it: `procs="$(printf '%s\n' "$procs" | awk -v self="$$" 'NF && $1 != self')"` (`:850`). The precise version: "this script's own command line does not match unless the checkout path contains `/claude ` (a directory named `claude <something>`); `$$` is dropped for that case." The conclusion (no self-refusal) holds.

**Evidence:** `devcontainer-config/install.sh:834`, `:845-850`; `docs/reviews/execution-logs/q058-b4fd792-r2/self-match-regex.log`

---

## Claim 11: "A command line with a `.../claude` argument (`vim ./claude`, `tail -f /var/log/claude`) also matches: the install is refused, and the message names the process."

**Location:** `devcontainer-config/install.sh:831-833`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the fail-closed false match and the message naming the process. It does not establish how often such false matches occur on the user's host.

E1: `vim ./claude` → MATCH. The refusal lists each process line: `printf '%s\n' "$procs" | sed 's/^/           /'` inside the `{ … } | vis >&2; exit 1` block (`:875`, `:884-885`). While running E1, the review session's own zsh (its command line held the regex text) also matched, which is another fail-closed false match of the same kind (paraphrased — no quote available because this is transient `pgrep` output seen in this session, not a repo file).

**Evidence:** `devcontainer-config/install.sh:831-834`, `:869-886`; `docs/reviews/execution-logs/q058-b4fd792-r2/proc-shape-probe.log`

---

## Claim 12: "No pgrep: refuse." / pgrep failure refuses

**Location:** `devcontainer-config/install.sh:840-849`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers a missing pgrep (T53) and a pgrep exit above 1 (by reading the code). It does not establish pgrep's behaviour on non-procps implementations (such as a BSD pgrep).

`if ! command -v pgrep …; then … exit 1; fi` (`:840-844`); `procs="$(pgrep …)" || rc=$?`; `if [ "$rc" -gt 1 ]; then echo "ERROR: pgrep failed (exit $rc) …" >&2; exit 1` (`:845-849`). Exit 1 (no match) is the only non-zero exit accepted. T53 passed in S1.

**Evidence:** `devcontainer-config/install.sh:838-850`; `test/install-host.bats:849-859`; `docs/reviews/execution-logs/q058-b4fd792-r2/install-host.bats.log`

---

## Claim 13: "cc-isolated's containers carry the label cc-project=<id> (its --id-label)."

**Location:** `devcontainer-config/install.sh:851`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the label the launcher passes on both of its `devcontainer` invocation paths. It does not establish that docker lists containers from another docker context or runtime (a residual in decision 037).

In the launcher: `local dc=(--workspace-folder "$ws" --override-config "$(config_dir)/devcontainer.json" --id-label "cc-project=$pid")` (`devcontainer-config/cc-isolated.sh:410-412`, and again at `:621-623`). The gate filters on the key: `docker ps --filter label=cc-project` (`install.sh:860`).

**Evidence:** `devcontainer-config/cc-isolated.sh:410-412`, `:621-623`; `devcontainer-config/install.sh:851-861`

---

## Claim 14: "No or unreachable docker: one NOTE line, treated as none running." / 648124c: "stderr now goes to a temp file, shown only when docker fails, and blank lines are dropped from the list."

**Location:** `devcontainer-config/install.sh:853-868`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the missing-docker and failing-docker paths, stdout-only capture and blank-line removal. It does not establish that the one stderr line shown is docker's own error rather than an earlier warning (`head -n 1`), or behaviour when `docker ps` hangs past 20 s (it is treated as unreachable, which is fail-open).

`echo "NOTE: docker not found: …"` (`:854`); `if ! ctrs="$(timeout 20 docker ps … 2>"$errf")"; then err="$(head -n 1 "$errf" 2>/dev/null)"; echo "NOTE: docker is unreachable ($err): …" | vis; ctrs=""; fi; rm -f "$errf"; ctrs="$(printf '%s\n' "$ctrs" | awk 'NF')"` (`:860-867`). T52 and T64 passed in S1. The suite as a whole also passed with `LC_ALL` set to an uninstalled locale, which is the condition 648124c describes.

**Evidence:** `devcontainer-config/install.sh:852-869`; `test/install-host.bats:822-848`; `docs/reviews/execution-logs/q058-b4fd792-r2/install-host.bats.log`

---

## Claim 15: "main refuses at startup when `command -v perl` fails, before the gate or any staging (T57)."

**Location:** `devcontainer-config/install.sh:940-945`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the order (perl check, then gate, then staging). It does not establish that perl works, only that it is on PATH (a broken perl is covered by Claims 6 and 27).

The perl check (`:941-945`) comes before `agent_gate` (`:947`) and `install_devcontainer` (`:953`). T57 (no perl → status 1, no claude-home mirror) passed in S1.

**Evidence:** `devcontainer-config/install.sh:940-954`; `test/install-host.bats:900-910`; `docs/reviews/execution-logs/q058-b4fd792-r2/install-host.bats.log`

---

## Claim 16: "A cc-isolated container writes the checkout, `.git` included, through its bind mount, whatever uid it runs as."

**Location:** `docs/decisions/037-bare-host-copy-install.md:64`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the read-write workspace bind mount. It does not establish write access for an arbitrary uid: a bind mount enforces host permissions, so a non-root container uid that differs from the owner cannot write the user's 0644/0755 files.

`"remoteUser": "node"` (`devcontainer-config/devcontainer.json:71`) and `"workspaceMount": "source=${localWorkspaceFolder},target=/workspace,type=bind,consistency=delegated"` (`:134`). The mount is read-write. The container user writes it when its uid matches the host owner's (devcontainer's default UID sync), or as root. The precise version: "writes the checkout through its bind mount (its user is mapped to your uid), which is why the container check is not uid-scoped." The practical point, that the docker probe must not filter by uid, is right.

**Evidence:** `devcontainer-config/devcontainer.json:71`, `:134`

---

## Claim 17: "The hash check (R2) catches a stage edited while the prompt waits."

**Location:** `docs/decisions/037-bare-host-copy-install.md:66`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the host target's stage (hashed before review, re-hashed on the copies after y). It does not establish anything for the devcontainer target, whose stage has no hash. An edit to it while the prompt waits, by a process gone (or undetected) at y, is installed and blessed.

Host: `reviewed_hash="$(payload_hash "$stage" "" "$stage/.manifest")"` (`install.sh:589`), and after the copies `if [ "$(payload_hash "$dest" .cw-new. "$dest/.cw-new.manifest")" != "$reviewed_hash" ]; then … echo "ERROR: stage changed after review …"` (`:729-733`). The existing host tamper tests (e.g. T43) passed in S1. Devcontainer: after y and the gate, `for item in "${PAYLOAD[@]}"; do rm -rf "${DEST:?}/$item"; cp -Rp "$stage/$item" "$DEST/$item"; done` (`:399-402`) copies from `$DC_TMP/config` with no content check (excerpt ends :402; enclosing `install_devcontainer()` continues to :424, read, with no hash). Probe P3 (E2) reviewed `+{"v":2}`. While the prompt waited it wrote `TAMPERED` into `$TMPDIR/cw-devc-stage.*/config/devcontainer.json`, with the pgrep stub reporting no agent, and answered y. The output shows `BLESS-STUB --bless`, and the installed file reads `installed: TAMPERED`. The precise version: "The host target's hash check (R2) catches its stage edited while the prompt waits; the devcontainer target has no such check and relies on the gate alone."

**Evidence:** `devcontainer-config/install.sh:321-424`, `:583-589`, `:729-734`; `docs/reviews/execution-logs/q058-b4fd792-r2/probe.bats`, `probe.bats.verbose.log`, `install-host.bats.log`

---

## Claim 18: "`install.sh` refuses to run while an agent can run, and names each agent with how to stop it. It checks at startup, before either target stages anything, and again after each y, before that target writes to its destination. (The devcontainer target rebuilds its `claude-home` mirror inside the checkout before its prompt; that is a staging copy, not an install.)" plus the two detector bullets

**Location:** `docs/decisions/037-bare-host-copy-install.md:68-70`
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the check points, the detectors as described, the pgrep refusal, the one-line docker NOTE and the mirror rebuild before the prompt. It does not establish the headline "refuses to run while an agent can run" as continuous: the checks are at three points (see Claims 17, 20 and 24).

The same call sites as Claim 8 (`install.sh:391`, `:695`, `:947`). The mirror rebuild (`:353-358`) comes before the review and prompt (`:364-388`). Detectors: `:845` and `:860` match the bullets, and `--id-label` matches `cc-isolated.sh:412`. T50–T55 passed in S1.

**Evidence:** `devcontainer-config/install.sh:353-393`, `:688-702`, `:838-886`, `:947`; `devcontainer-config/cc-isolated.sh:412`; `docs/reviews/execution-logs/q058-b4fd792-r2/install-host.bats.log`

---

## Claim 19a: "Both need a crafted name, which needs an agent, which the gate refuses."

**Location:** `docs/decisions/037-bare-host-copy-install.md:73`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the TAB mis-prune residual (A4) when the crafted name was planted before the run. It does not separately execute the newline-cwd residual (A5), whose crafted directory is persistent state in the same way.

The gate checks for *running* processes at three points during one run (`install.sh:391`, `:695`, `:947`). A crafted name is persistent filesystem state, which an agent can plant in an earlier session, long before the install. The gate never looks for it. The prune loop still truncates a TAB name at `cut -f2`: `printf '%s\t%s\n' "$e" "${d##*/}"` … `| LC_ALL=C sort -t "$(printf '\t')" -k1,1nr -k2,2r | tail -n +3 | cut -f2)` (`:806-807`), feeding `rm -rf "${bkroot:?}/$old"` (`:797`). Probe P5 (E3) planted `20200101T000000Z<TAB>junk` (epoch 100) next to real backups `20200101T000000Z` (200) and `20200102T000000Z` (300) before running. The pgrep stub reported no agent, so every gate passed, and the run printed `Installed into …` and `(1 older removed)`. The listing afterwards shows `20200101T000000Z	junk`, `20200102T000000Z` and this run's backup: the real `20200101T000000Z`, which should have been kept, was deleted, and the planted one survived. The precise version: "Both need a crafted name. The gate does not stop a name planted before the run; these residuals rest on nothing but their exotic-input rarity."

**Evidence:** `devcontainer-config/install.sh:784-809`, `:838-886`; `docs/reviews/execution-logs/q058-b4fd792-r2/probe5.bats`, `probe5.bats.log`

---

## Claim 19b: "(fact-check final Claims 4 and 6; rubric A4, A5, parked)" / "Review record: code-review-rubric-2026-09-23-ans-copy-install-final.md"

**Location:** `docs/decisions/037-bare-host-copy-install.md:73`, `:77`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that the cited report claims and rubric rows exist and describe these residuals. It does not establish their verdicts beyond what those files say.

The final (pass-3, 9ae6e46) fact-check report is `docs/reviews/code-fact-check-report.md` at b4fd792. Its `## Claim 4:` (`:95`) is the backup-pruning claim and its `## Claim 6:` (`:152`) is the newline-destination `read` claim. The rubric has `| A4 | A TAB in a backup dir's name makes \`cut -f2\` prune the wrong dir …` (`docs/reviews/code-review-rubric-2026-09-23-ans-copy-install-final.md:29`) and `| A5 | A relative \`CLAUDE_HOME_DIR\` from a working dir whose name contains a newline …` (`:30`). The linked file exists.

**Evidence:** `docs/reviews/code-fact-check-report.md:95`, `:152`; `docs/reviews/code-review-rubric-2026-09-23-ans-copy-install-final.md:29-30`

---

## Claim 20: "A process the probe misses: an agent on another host or in another container runtime writing the checkout (a network or shared mount), a renamed or wrapped binary whose command line does not end in `claude`, one running under another uid, or a docker the user's uid cannot reach."

**Location:** `docs/decisions/037-bare-host-copy-install.md:75`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers each listed residual (each one is real). It does not establish that the list is complete: three executed miss classes are not named (below).

Unnamed residuals, each executed:
(i) **Between check points.** The gate samples at three moments. P3 (E2): a devcontainer-stage edit made while the prompt waits, by a process not present at y, is installed and blessed. P4 (E2): an agent visible only during the devcontainer prompt, when that prompt is answered n, lets the host target stage and review while it runs. The output shows `Install these files` and never `779 claude`, and the host install completes.
(ii) **Same-uid processes that are not Claude Code.** For example, a loop an agent left detached before exiting. E1: `bash -c while sleep 1; do cp evil /tmp/cw-host-stage.X/payload/hooks/h.sh; done` → miss. The listed "renamed or wrapped binary" does not describe this.
(iii) **Regex-level misses of plausible Claude Code shapes** (Claim 9): a versioned native path, `node cli.js`, the Agent SDK's `claude-agent-sdk/cli.js`.
Also, "command line does not end in `claude`" misstates the regex. `(^|/)claude(\.exe)?( |$)` (`install.sh:834`) matches `claude` followed by a space anywhere after `^` or `/`, so `/usr/local/bin/claude --resume` matches even though it does not end in `claude` (E1).

**Evidence:** `devcontainer-config/install.sh:834`, `:845`, `:391`, `:695`, `:947`; `docs/reviews/execution-logs/q058-b4fd792-r2/proc-shape-probe.log`, `probe.bats`, `probe.bats.verbose.log`

---

## Claim 21: "`install.sh` now refuses at startup and again after each y while a Claude Code process of the user's uid (`pgrep -af`) or a running cc-isolated container … is found (T50-T56). Residuals accepted in decision 037 … The probe is also a new way for the install to be refused on a host where some unrelated command line ends in `/claude`; the message names the process."

**Location:** `docs/working/plan-copy-install-bare-host.md:244`
**Type:** Behavioral / Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the check points, the T50–T56 mapping and the false-match note. It does not establish that the residual list is complete (it mirrors 037's list; see Claims 19a and 20).

The check points and tests hold (Claims 8 and 25). The false-match note is too narrow. An unrelated command line matches whenever `/claude` is followed by a space, not only at its end. E1 shows `vim ./claude` matching, and E5 shows `bash /home/u/claude code/…` matching (`CLAUDE_PROC_RE='(^|/)claude(\.exe)?( |$)|…'`, `install.sh:834`). The precise version: "…where some unrelated command line holds a `/claude` word (`vim ./claude`, a path through a `claude …` directory)."

**Evidence:** `devcontainer-config/install.sh:834`; `test/install-host.bats:791-899`; `docs/reviews/execution-logs/q058-b4fd792-r2/proc-shape-probe.log`, `self-match-regex.log`

---

## Claim 22: "Hardening after the final review (2026-09-23): perl is required at startup and a `vis` failure aborts the review (T57, T58); the `claude-home` mirror is never rebuilt through a symlink (T59, T60); payload files holding a NUL byte are refused, and the review diffs as text (T61, T62)."

**Location:** `docs/working/plan-copy-install-bare-host.md:245`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the test-to-fix mapping and that each named test passes. "Never rebuilt through a symlink" holds for links present at check time (Claim 7); it does not establish anything for a swap during the run (Claim 28).

The tests exist at `test/install-host.bats:900`, `:911`, `:928`, `:942`, `:954` and `:976`, with titles matching the fixes, and all passed in S1. Behaviour: Claims 4–7 and 15.

**Evidence:** `test/install-host.bats:900-987`; `docs/reviews/execution-logs/q058-b4fd792-r2/install-host.bats.log`

---

## Claim 23: "install.sh is 958 lines after the review, fact-check and Q-058 fixes (808 before Q-058)"

**Location:** `docs/working/plan-copy-install-bare-host.md:248`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the line counts at 9ae6e46 and b4fd792. It does not establish counts at later commits.

E6: `9ae6e46 808`, `66891a7 948`, `648124c 956`, `b4fd792 958`. The 948 in 66891a7's message was right for that commit. The plan was corrected to 958 in b4fd792.

**Evidence:** `docs/reviews/execution-logs/q058-b4fd792-r2/line-counts.log`

---

## Claim 24: "First close every Claude Code session and stop every cc-isolated container: the installer refuses to stage or install while either runs (Q-058; see `install.sh --help` and decision 037, "Trust model"), since a running agent could change what you review before it is installed."

**Location:** `guides/bare-host-hook-wiring.md:17-20`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers what happens when an agent is present at one of the three check points. It does not establish "refuses to stage … while either runs" for an agent that appears after the startup check. The host target stages with no fresh check.

Probe P4 (E2): the pgrep stub reported `779 claude` from the moment the devcontainer prompt was up until after the host stage was built. The user answered n to the devcontainer target. The host target then staged and printed its full review, including `Install these files`, with no refusal. The agent was gone by the host y, and the install completed. Staging is gated only by the startup check: `agent_gate "Nothing was staged or installed."` (`install.sh:947`). `install_claude_home` calls `assemble "$stage"` (`:585`) with no gate before it. The precise version: "…refuses at startup, before anything is staged, and again after each y, while either runs."

**Evidence:** `devcontainer-config/install.sh:530-695`, `:947`; `docs/reviews/execution-logs/q058-b4fd792-r2/probe.bats`, `probe.bats.verbose.log`

---

## Claim 25: T50–T64 exist and assert what their commits say

**Location:** `test/install-host.bats:791-998`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the existence of the tests, their assertions against the commit descriptions, and that they pass. It does not establish that T64 fails on pre-648124c code (648124c itself says it was not run there), or live-host behaviour ("Live-verified: no" on every commit).

Each test is present with the assertions its commit names. T50: `[[ "$output" != *'Canonical'* ]]`, `[ ! -e "$ROOT/devcontainer-config/claude-home" ]` and `grep -q -- "pgrep -u $(id -u) -af"`. T51: `*'docker stop'*` and `grep -q 'docker ps --filter label=cc-project'`. T54: `[ ! -e "$CLAUDE_HOME_DIR/.claude-workflows-lock" ]`. T55: `[ ! -e "$CLAUDE_DEVC_CONFIG_DIR" ]`. T61: `*'NUL'*'hooks/blob.bin'*`, then `*'NUL'*'egress/x.bin'*`. T62: `*'-bad?byte'*`. T63: greps `^## Trust model (Q-058)` and the residual words `TAB`, `.git/config`, `another host` and `renamed`. T64 uses a docker stub warning on stderr and exiting 0, and asserts the install proceeds. S1 ran 64/64 ok, with T50–T64 at ok 49–63.

**Evidence:** `test/install-host.bats:791-998`; `docs/reviews/execution-logs/q058-b4fd792-r2/install-host.bats.log`

---

## Claim 26: "Tests stub pgrep and docker on PATH (T50-T56); the existing suites stub them to "none", because the session running them is itself a claude process." / "No env override for the probes: tests use PATH stubs, so the gate has no bypass beyond what PATH already allows."

**Location:** `commit ea2c8fb` (message); `test/install-host.bats:35-55`; `test/cc-isolated-functions.bats:44-48`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the absence of any environment or flag override of the gate, and the stubs in both suites. It does not establish that the detectors are complete (Claims 9 and 20). The misses there are blind spots, not bypass knobs.

`CLAUDE_PROC_RE` is assigned unconditionally at top level (`install.sh:834`), so an exported variable of that name is overwritten. `agent_gate` reads no environment variable except `TMPDIR`, which it uses for its temp file (`:859`), and `main` accepts only `--yes` and `-h/--help` (`:904-911`). Stubs: `stub_pgrep 'exit 1'` and `stub_docker 'exit 0'` with `export PATH="$STUB:$PATH"` (`test/install-host.bats:39-41`); `printf '#!/usr/bin/env bash\nexit 1\n' > "$TEST_TMPDIR/bin/pgrep"` and the docker equivalent (`test/cc-isolated-functions.bats:46-47`).

**Evidence:** `devcontainer-config/install.sh:834-886`, `:902-911`; `test/install-host.bats:35-55`; `test/cc-isolated-functions.bats:44-48`

---

## Claim 27: "other `| vis` uses (MODE, MOVE, ADD lines) are not individually checked; perl missing is now refused up front, and a vis that fails there fails in review_diff too, which aborts."

**Location:** `commit fa69656` (message)
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers every other `| vis` site. It does not establish behaviour for a vis that fails only some of the time (both paths assume a failure that repeats).

The conclusion holds: no prompt is reached with a failed vis. The stated route ("fails in review_diff too") is only one of two:
- **MODE lines** (`install.sh:299`). `mode_diff` is called as `mode_diff … || same=0` (`:367`) and `if ! mode_diff …` (`:668`), which turns off errexit inside it, so a failed MODE line is silently dropped. `review_diff` runs right after on the same items (`:368`, `:670`) and aborts. P2 (E2) showed this: `ERROR: could not show the review of payload item 'devcontainer.json' (vis exit 1).`
- **Host MOVE/REPLACE/ADD lines** (`:600`, `:606`, `:625`, `:646-647`, `:653`). These run with errexit and pipefail on, in `install_claude_home`, which `main` calls outside any condition. A vis failure kills the script at that line with no ERROR message, before `review_diff` is reached. On a first install whose entries are all over 200 lines, `review_diff` never runs at all. P1 (E2) had the host first install with vis failing. The output stops at `=== Changes this install would make ===`, status 1, with no ERROR line and no `Install these files`.
The precise version: "MODE lines are covered by review_diff, which follows on the same items; the host pre-pass lines are covered by set -e/pipefail, which exits there without a message."

**Evidence:** `devcontainer-config/install.sh:26`, `:283-305`, `:364-371`, `:593-671`; `docs/reviews/execution-logs/q058-b4fd792-r2/probe.bats`, `probe.bats.verbose.log`

---

## Claim 28: "a swap of the fresh directory for a link between mkdir and cp is a residual; it needs an agent running during the install, which the Q-058 gate refuses."

**Location:** `commit dfa5791` (message)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the gate calls around the rebuild. It does not establish refusal of a process that is not Claude Code, or one started after the startup check.

The rebuild (`install.sh:353-358`) runs after only the startup check (`:947`). No gate runs between that check and the rebuild. The gate refuses only a process matching `CLAUDE_PROC_RE`, or a labelled container, present at that moment (`:845`, `:860`). A same-uid process an agent left running (E1: a `bash -c while …` loop → miss), or one started after `:947`, is not refused. The precise version: "…it needs a process racing the install; the gate refuses only a Claude Code process or cc-isolated container present at startup." The race window is short (staging time), which bounds the practical risk.

**Evidence:** `devcontainer-config/install.sh:346-358`, `:845`, `:947`; `docs/reviews/execution-logs/q058-b4fd792-r2/proc-shape-probe.log`

---

## Claim 29: "T9 now copies the committed hooks/scripts (git archive) instead of the tree … T58's perl stub fails vis only, so the NUL scan runs real perl." / "the payload is ~125 small text files"

**Location:** `commit 8d9be0c` (message); `test/install-host.bats:278-284`, `:911-927`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the T9 change, T58's stub dispatch and the payload file count. It does not establish scan timing ("well under a second" was not timed).

T9: `git -C "$CONFIG_SRC/.." archive HEAD hooks scripts | tar -xf - -C "$ROOT"` (`test/install-host.bats:283`). T58's stub: `case "$1" in -pe) cat >/dev/null; exit 1 ;; esac\nexec %s "$@"` (`:917`). `vis` calls `perl -pe` (`install.sh:120`), while the NUL scan calls `perl -0ne` (`:186`), which falls through to the real perl. E4 counted `files=122`, which is roughly 125. T9 and T58 passed in S1.

**Evidence:** `test/install-host.bats:278-290`, `:911-927`; `devcontainer-config/install.sh:120`, `:186`; `docs/reviews/execution-logs/q058-b4fd792-r2/nul-scan-payload.log`, `install-host.bats.log`

---

## Claim 30: "All suites: 315/315." (648124c) / "Suites 315/315." (b4fd792)

**Location:** `commit 648124c` (message); `commit b4fd792` (message)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the four suites named in the final rubric's count (install-host, cc-isolated-functions, link-claude-home-wiring, test/hooks) at b4fd792, in this sandbox. It does not establish the count at 648124c (not re-run) or on the bare host.

S1: 64/64. S2: 92/92. S3: `1..14` rc=0 and `1..145` rc=0. 64 + 92 + 14 + 145 = 315, all passing.

**Evidence:** `docs/reviews/execution-logs/q058-b4fd792-r2/install-host.bats.log`, `cc-isolated-functions.bats.log`, `other-suites.log`, `run-other-suites.sh`

---

## Claims Requiring Attention

### Incorrect
- **Claim 19a** (`docs/decisions/037-bare-host-copy-install.md:73`): the claim is that crafted TAB or newline names "need an agent, which the gate refuses". The gate checks for running processes only. A name planted in an earlier session survives into the run and still mis-prunes a kept backup (P5, executed). Drop "which the gate refuses", or check the backup names.

### Mostly Accurate
- **Claim 10** (`devcontainer-config/install.sh:829-831`): the script's own command line does match when the checkout path holds `/claude ` (a directory named `claude <x>`). `$$` then does the work.
- **Claim 16** (`docs/decisions/037-bare-host-copy-install.md:64`): "whatever uid it runs as" is too strong. The container writes the checkout because its user is mapped to the user's uid (or is root).
- **Claim 17** (`docs/decisions/037-bare-host-copy-install.md:66`): the R2 hash covers the host target only. A devcontainer stage edited while its prompt waits is installed and blessed (P3).
- **Claim 20** (`docs/decisions/037-bare-host-copy-install.md:75`): the residual list omits three executed classes: agents active only between check points (P3, P4), non-Claude same-uid processes such as detached leftovers, and regex misses (a versioned native path, `node cli.js`, the claude-agent-sdk CLI). "Does not end in `claude`" also misdescribes the regex.
- **Claim 21** (`docs/working/plan-copy-install-bare-host.md:244`): false matches come from any `/claude` word, not only a command line ending in `/claude`.
- **Claim 24** (`guides/bare-host-hook-wiring.md:17-20`): "refuses to stage … while either runs" is too broad. The host target stages with no fresh check after the startup gate (P4).
- **Claim 27** (`commit fa69656`): the host MOVE/REPLACE/ADD lines are stopped by set -e and pipefail, silently and before `review_diff`, not by `review_diff`. MODE lines are dropped and then caught by `review_diff`.
- **Claim 28** (`commit dfa5791`): the gate does not refuse a racing process that is not Claude Code, or one started after the startup check.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report in the code-fact-check skill's format, saved to the output path named at the end of this prompt.
- Answered: yes. The report is saved to `/workspace/docs/reviews/code-fact-check-report-r2.md`.
- Out of scope: whether the gate design is enough to merge. That is a security or synthesis judgment; this report only checks claims against code. Live-host behaviour (every commit says "Live-verified: no") is also out of scope.
- Escalate: (1) **The R1 target-1 half is closed only against agents present at the devcontainer y.** The devcontainer stage has no content check after review. P3 installed and blessed a stage edited while the prompt waited, with no process detected at y. Decision 037:66 implies the R2 hash covers it (Claim 17). (2) **The gate samples; it does not cover the run.** P4: the host target stages and reviews while an agent runs, provided the agent is gone at the host y. Non-Claude same-uid processes (such as detached leftovers) are never detected (Claims 20, 24, 28). (3) **037's TAB/newline residual rationale is refuted** (Claim 19a, the one Incorrect). A pre-planted name bypasses the gate.
- Questions I would have asked: Should a pre-existing detached process from an earlier agent session count as "an agent" under Q-058 [2]? If yes, a Claude-process probe cannot enforce the answer, and a named residual (or a different mechanism) is needed.
- Decisions I made: I wrote probe suites built from `install-host.bats`'s own setup and helpers, instead of editing the worktree's tests. I checked "every real Claude Code shape" only against the one live process and regex-level shapes, and scoped Claim 9 as Verified with the misses named in its Scope, not as Unverifiable. I split 037:73 into 19a (Incorrect) and 19b (Verified reference) because their verdicts diverge. I added no hallucination-log entry (no fabricated symbol).
