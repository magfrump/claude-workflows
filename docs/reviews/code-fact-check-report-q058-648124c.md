# Code Fact-Check Report

**Repository:** claude-workflows (worktree `/workspace/.claude/wt-copyinstall`, branch `ans/copy-install`)
**Scope:** commits `af17e86..648124c` (Q-058 no-agent gate, perl/vis hardening, claude-home no-follow rebuild, NUL refusal, decision 037 trust model, docker-stderr fix): `devcontainer-config/install.sh`, `README.md`, `guides/bare-host-hook-wiring.md`, `docs/decisions/037-bare-host-copy-install.md`, `docs/working/plan-copy-install-bare-host.md`, the tests, and the five commit messages
**Commit:** 648124c
**Replication:** k=1
**Checked:** 2026-09-23
**Total claims checked:** 30
**Summary:** 22 verified, 5 mostly accurate, 1 stale, 1 incorrect, 1 unverifiable

Execution logs and the probe scripts are in `docs/reviews/execution-logs/q058-648124c/`. Every probe was hermetic: temp `HOME`, `TMPDIR`, `CLAUDE_HOME_DIR`, `CLAUDE_DEVC_CONFIG_DIR`, `CLAUDE_DEVC_BIN_DIR`; `pgrep`/`docker`/`perl` stubbed on PATH where the gate ran; `CLAUDECODE` unset. The shell had `LC_ALL=en_US.UTF-8` set to an uninstalled locale throughout, which is the condition 648124c describes. The real `pgrep` was used read-only, to observe live process shapes and `exec -a`-renamed `sleep` dummies (killed by PID afterwards).

Hallucination-pattern log read (7 entries); none relates to these claims.

Suites (executed): `bats test/install-host.bats test/cc-isolated-functions.bats test/link-claude-home-wiring.bats test/hooks/*.bats`, cwd `/workspace/.claude/wt-copyinstall`, 2026-09-23T19:34:54-07:00, exit 0, **315/315 ok**. Output: `docs/reviews/execution-logs/q058-648124c/suites.log`.

---

## Claim 1: "Before it stages anything, and again after each y, it refuses while a Claude Code process of your uid or a running cc-isolated container ... is found, and names each one with how to stop it."

**Location:** `README.md:33-39`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the startup gate and the post-y gates of both targets, and that the refusal names each process/container plus a stop instruction. It does not establish that the probe finds every real agent (see Claims 12a/12b, 16).

`main` calls `agent_gate "Nothing was staged or installed."` (`devcontainer-config/install.sh:945`) before `install_devcontainer`/`install_claude_home` (`:951-952`). The post-y calls are at `:391` and `:695`. The refusal text includes `"Stop them: end each Claude Code session (/exit), or kill <PID>."` and `"Stop them: docker stop <name>"` (`:875`, `:880`). Tests T50, T51, T54 and T55 pass in the suite run.

**Evidence:** `devcontainer-config/install.sh:391`, `:695`, `:836-883`, `:945`; `docs/reviews/execution-logs/q058-648124c/suites.log`

---

## Claim 2: "...and so is a payload file holding a NUL byte (a binary the diff cannot show)."

**Location:** `devcontainer-config/install.sh:48-49`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers committed payload files of both targets. It does not cover destination-side NUL files. Those are reviewed as text rather than refused (Claim 7).

`extract_commit` exits when the perl scan finds a NUL: `print substr($_, 2), "\n" if defined $c && index($c, "\0") >= 0;` then `if [ -n "$nul" ]; then ... exit 1` (`:187-199`). T61 (both targets, before any `[y/N]`) passes.

**Evidence:** `devcontainer-config/install.sh:181-199`; `docs/reviews/execution-logs/q058-648124c/suites.log`

---

## Claim 3: "install.sh refuses, before it stages anything and again after each y ... Without pgrep it refuses; without a reachable docker it says so in one line and treats no container as running."

**Location:** `devcontainer-config/install.sh:51-58`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the missing-pgrep, missing-docker, failing-docker and hanging-docker paths. It does not establish what the one NOTE line contains (Claim 15).

`if ! command -v pgrep ...; then ... exit 1` (`:838-842`). `"NOTE: docker not found: ... treated as none running."` (`:851`). A failed `timeout 20 docker ps ...` gives one `NOTE: docker is unreachable (...)` line and `ctrs=""` (`:857-862`). Executed: T52 and T53 pass. `esc.sh` ran agent_gate against a docker stub that sleeps 30 s: it printed one NOTE line and returned 0 after about 22 s (timeout 20). Run at 2026-09-23T19:42:29-07:00, cwd scratchpad, exit 0.

**Evidence:** `devcontainer-config/install.sh:836-866`; `docs/reviews/execution-logs/q058-648124c/esc.log`, `esc.sh`, `suites.log`

---

## Claim 4: "Needs git, perl (the review's control-byte filter) and pgrep; refuses without them."

**Location:** `devcontainer-config/install.sh:66`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers refusal without perl (T57), without pgrep (T53), and without git: `head_commit` fails, as a static read. It does not establish that these are the only tools required. `timeout` (coreutils) is also called unconditionally (`:857`) and is not named.

`if ! command -v perl >/dev/null 2>&1; then ... exit 1` (`:939-943`), which runs before `agent_gate` (`:945`).

**Evidence:** `devcontainer-config/install.sh:129-135`, `:838-842`, `:857`, `:939-945`; `docs/reviews/execution-logs/q058-648124c/suites.log`

---

## Claim 5: "vis: filter that makes control bytes visible (all but newline and tab; NUL included)"

**Location:** `devcontainer-config/install.sh:110-111`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the C0 class now starting at `\x00`. It does not re-verify the pre-existing C1/UTF-8 handling.

`s/[\x00-\x08\x0b\x0c\x0e-\x1a\x1c-\x1f\x7f]/?/g;` (`:122`). T62 asserts `-bad?byte` in the review, and it passes.

**Evidence:** `devcontainer-config/install.sh:119-125`; `docs/reviews/execution-logs/q058-648124c/suites.log`

---

## Claim 6: "diff reports such a file as 'Binary files ... differ' and shows none of its content ... The payload is text today (checked 2026-09-23: no committed payload file holds a NUL)"

**Location:** `devcontainer-config/install.sh:181-184`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers HEAD's `git archive` of the seven CLAUDE_HOME_SRC paths plus all of `devcontainer-config/` (a superset of PAYLOAD). It does not cover future commits.

`nul.sh` extracted `git archive HEAD -- global-instructions/CLAUDE.md skills workflows guides patterns hooks scripts devcontainer-config`: 123 files, none holding a NUL. Run at 2026-09-23T19:42:12-07:00, cwd scratchpad, exit 0.

**Evidence:** `devcontainer-config/install.sh:181-199`; `docs/reviews/execution-logs/q058-648124c/nul.log`, `nul.sh`

---

## Claim 7: "A vis failure is trouble too ... -a: a file with a NUL byte ... is diffed as text, with vis showing each NUL as '?'"

**Location:** `devcontainer-config/install.sh:259-265`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `review_diff`'s pipeline status handling. It does not cover the other `| vis` uses (MODE/MOVE/ADD lines), which fa69656's Notes say are unchecked.

```bash
# devcontainer-config/install.sh:265-271
diff -ruNa "$dest/$item" "$src/$item" 2>&1 | vis && st=(0 0) || st=("${PIPESTATUS[@]}")
rc="${st[0]}"
if [ "${st[1]}" -ne 0 ]; then
  echo "ERROR: could not show the review of payload item '$item' (vis exit ${st[1]})." >&2
```
(excerpt ends :268; enclosing review_diff() continues to :284 — read)

With `pipefail`, a diff exit of 1 sends control to the `||` branch, where PIPESTATUS still holds the pipeline's statuses. T58 (vis stub fails, aborts before `bless it?`) and T62 pass.

**Evidence:** `devcontainer-config/install.sh:247-284`; `docs/reviews/execution-logs/q058-648124c/suites.log`

---

## Claim 8: "A symlink at claude-home, or at any directory between the repo root and it, would send the rebuild's writes wherever it points ... so refuse one."

**Location:** `devcontainer-config/install.sh:331-333`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers components below `$REPO_ROOT`. It does not check `$REPO_ROOT` itself or its ancestors, and does not establish that the refusal message is escaped (see Claim 29).

`IFS=/ read -ra comps <<< "${SRC#"$REPO_ROOT"/}/claude-home"` then `if [ -L "$p" ]; then ... exit 1` (`:336-344`), before `mktemp`/`assemble` (`:346-349`). T59 and T60 pass.

**Evidence:** `devcontainer-config/install.sh:331-345`; `docs/reviews/execution-logs/q058-648124c/suites.log`

---

## Claim 9: "No-follow rebuild: rm of a path without a trailing slash removes a link itself, never its target; mkdir fails rather than follow anything that appeared since, so the copy lands in a directory this run just created."

**Location:** `devcontainer-config/install.sh:350-352`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers `rm -rf "$SRC/claude-home"` (no slash) and `mkdir` failing with EEXIST on anything present. It does not cover a swap between `mkdir` and `cp -Rp ... "$SRC/claude-home/"`: the trailing slash would follow a link planted there. dfa5791's Notes name this residual.

`rm -rf "$SRC/claude-home"`, `if ! mkdir "$SRC/claude-home"; then ... exit 1`, `cp -Rp "$stage/claude-home/." "$SRC/claude-home/"` (`:353-358`). The rm/mkdir semantics are paraphrased — no quote available because they come from coreutils behaviour, not repo code.

**Evidence:** `devcontainer-config/install.sh:350-358`

---

## Claim 10: "Q-058: an agent may have started while the prompt waited." / "...while the review and prompt waited." (a gate after each y, before that target's writes)

**Location:** `devcontainer-config/install.sh:390-391`, `:694-695`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the gate sitting after `confirm` and before `mkdir -p "$DEST" "$BIN_DIR"` (devcontainer) and before the lock `mkdir` (host). It does not cover the devcontainer target's checkout-mirror rebuild, which runs before its prompt (Claim 18). With `--yes` there is no y, but the `:391` gate still runs because it sits outside the `if`.

`agent_gate "Nothing was installed. (devcontainer config)"` then `mkdir -p "$DEST" "$BIN_DIR"` (`:391-393`). The host target has `confirm` (`:688`), then `agent_gate` (`:695`), then the lock (`:700-702`). T54 (host tree unchanged, no `.cw-new.*`, no lock) and T55 (no `$CLAUDE_DEVC_CONFIG_DIR`, no bless) pass.

**Evidence:** `devcontainer-config/install.sh:379-393`, `:688-702`; `docs/reviews/execution-logs/q058-648124c/suites.log`

---

## Claim 11: "So the install is refused while either runs: at startup, before anything is staged, and again after each y, right before that target writes."

**Location:** `devcontainer-config/install.sh:820-825`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the startup ordering: the gate runs before the trap, the staging and the mirror rebuild. The "right before that target writes" part carries the same devcontainer-mirror caveat as Claim 18.

`agent_gate "Nothing was staged or installed."` (`:945`) precedes `install_devcontainer` (`:951`). T50 asserts no `Canonical`, no `claude-home` mirror, no `$CLAUDE_DEVC_CONFIG_DIR`, and passes.

**Evidence:** `devcontainer-config/install.sh:945-952`; `docs/reviews/execution-logs/q058-648124c/suites.log`

---

## Claim 12a: "command line runs `claude` (the native binary, argv0 'claude' or '.../claude') or the npm package (`node .../bin/claude`, `.../@anthropic-ai/claude-code/...`)" — the named shapes are matched

**Location:** `devcontainer-config/install.sh:827-829`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the named shapes plus the live Claude Code process in this container. It does not establish matching of the VS Code extension's process, which is not in this sandbox. A native-binary path under `.../native-binary/claude` matches as a string. An older extension shape (`node .../anthropic.claude-code-X/.../cli.js`) and a version-named native binary invoked directly (`.../share/claude/versions/2.1.3`) do NOT match. Those two are covered only if Claude Code rewrites its process title to `claude`, which was not verified.

`CLAUDE_PROC_RE='(^|/)claude(\.exe)?( |$)|/@anthropic-ai/claude-code/'` (`:833`). Executed (`regex.sh`, 2026-09-23T19:34:38-07:00, cwd scratchpad, exit 0):
- These strings match: `claude`, `claude --resume`, `/home/u/.local/bin/claude -p hi`, `node /usr/local/bin/claude --resume`, `node .../@anthropic-ai/claude-code/cli.js`, and `.../native-binary/claude(.exe) ...`.
- The real `pgrep -u 1000 -af` found the live session: `/proc/68025/exe` is `.../@anthropic-ai/claude-code/bin/claude.exe` and its cmdline is `claude`.

**Evidence:** `devcontainer-config/install.sh:827-833`; `docs/reviews/execution-logs/q058-648124c/regex.log`, `regex.sh`

---

## Claim 12b: "A Claude Code process is one of this uid's processes whose command line runs `claude` (... argv0 ...)" — the definition vs. what the regex matches

**Location:** `devcontainer-config/install.sh:827-829`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the regex actually selects. It does not establish how often such false matches occur on the user's host.

The regex is unanchored to argv0. It matches any argument whose last path segment is `claude` followed by a space or the end of the line, so non-agent processes are classified as Claude Code. Executed string results (`regex.log`):
- These match: `vim ./claude`, `vim /tmp/claude`, `tail -f /var/log/claude`, `git -C /home/u/src/claude status`.
- These do not match: `vim claude`, `less CLAUDE.md`, `less ~/claude-workflows/README.md`, `cd /workspace/claude-workflows`, `bash /home/u/claude/devcontainer-config/install.sh`.
- Real processes agree: dummies `exec -a 'vim /tmp/cfcprobe/claude' sleep` and `exec -a cfcprobe/claude sleep` were listed by the real `pgrep -af` with this pattern; `less CLAUDE.md` and `/w/claude-workflows/cfcprobe` were not.

Precise version: "any command line with an argument `claude` at the start or `.../claude` anywhere." The effect is fail-closed: the refusal names the process.

**Evidence:** `devcontainer-config/install.sh:833`; `docs/reviews/execution-logs/q058-648124c/regex.log`

---

## Claim 13: "pgrep never lists itself; this script's own command line does not match"

**Location:** `devcontainer-config/install.sh:829-830`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers install.sh invoked as `bash <path>`, directly via shebang, and as `./devcontainer-config/install.sh`, including from a checkout whose path ends in `/claude`. It does not cover a copy of the script renamed to `claude`.

`self.sh` (2026-09-23T19:43:57-07:00, cwd scratchpad, exit 0) ran a stand-in at `.../co/claude/devcontainer-config/install.sh` in all three invocation forms. `pgrep -af -- "$RE"` listed none of them. The real Claude session was the only match in `regex.log`, so pgrep did not list itself.

**Evidence:** `devcontainer-config/install.sh:829-846`; `docs/reviews/execution-logs/q058-648124c/self.log`, `self.sh`, `regex.log`

---

## Claim 14: "...and $$ is dropped in case the checkout's path ends in /claude."

**Location:** `devcontainer-config/install.sh:830-831`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the stated reason for the `$$` filter. It does not claim the filter is harmful: it is a harmless no-op.

A checkout path ending in `/claude` yields command lines like `bash /x/claude/devcontainer-config/install.sh`. In those, `claude` is followed by `/`, not by a space or the end of the line, so they never match (`self.log`: zero matches in all three invocation forms). The case the comment guards against does not arise. The filter `awk -v self="$$" 'NF && $1 != self'` (`:847`) only matters if the script file itself is named `claude`. Consequence: none at runtime. A maintainer reading this would think the `$$` filter guards a real self-match, and might miss that the self-match question is settled by the `/` rule.

**Evidence:** `devcontainer-config/install.sh:847`; `docs/reviews/execution-logs/q058-648124c/self.log`

---

## Claim 15: "Only stdout is the container list. stderr carries warnings ... so it is kept apart and shown only when the call fails."

**Location:** `devcontainer-config/install.sh:853-856`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers stdout/stderr separation, blank-line dropping, and what the failure NOTE shows. It does not cover docker output formats beyond `--format`.

stderr goes to `$errf`, and only `head -n 1` of it is shown (`err="$(head -n 1 "$errf" 2>/dev/null)"`, `:859`). So "shown" means the first stderr line only, and that line may be an unrelated warning rather than the failure. Executed (`esc.log` line 26): with a docker stub that fails, the NOTE read `docker is unreachable (/bin/bash: warning: setlocale: LC_ALL: cannot change locale ...)`, not the stub's error. With LC_ALL unset it showed the real first line. Precise version: "kept apart; its first line is shown only when the call fails."

**Evidence:** `devcontainer-config/install.sh:853-866`; `docs/reviews/execution-logs/q058-648124c/esc.log`

---

## Claim 16: "A cc-isolated container runs as another uid, but it writes the checkout ... through its bind mount."

**Location:** `docs/decisions/037-bare-host-copy-install.md:64`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers what the repo config shows. It does not establish the container's runtime uid, which needs a host with docker.

`"remoteUser": "node",` (`devcontainer-config/devcontainer.json:71`). Whether node's uid differs from the host user's uid depends on the host. The devcontainer CLI's default `updateRemoteUserUID` remaps the remote user to the host uid on Linux (paraphrased — no quote available because this is external devcontainer-CLI behaviour, not repo code). If so, the container's processes share the user's uid and would also be visible to `pgrep -u <uid>` on the host. That would make the gate stricter, not weaker. Needed to verify: `ps -o uid,cmd` on the host with a cc-isolated container running.

**Evidence:** `devcontainer-config/devcontainer.json:71`

---

## Claim 17: "The hash check (R2) catches a stage edited while the prompt waits."

**Location:** `docs/decisions/037-bare-host-copy-install.md:66`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the host target only. The devcontainer target has no stage hash.

`reviewed_hash="$(payload_hash "$stage" "" "$stage/.manifest")"` (`install.sh:589`) and `if [ "$(payload_hash "$dest" .cw-new. "$dest/.cw-new.manifest")" != "$reviewed_hash" ]` (`install.sh:729`).

**Evidence:** `devcontainer-config/install.sh:589`, `:729`

---

## Claim 18: "It checks at startup, before either target stages anything, and again after each y, before that target writes"

**Location:** `docs/decisions/037-bare-host-copy-install.md:68`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the order of gate calls against each target's writes.

The devcontainer target writes before its y: it rebuilds the checkout mirror (`rm -rf "$SRC/claude-home"`, `mkdir`, `cp -Rp ...`, `install.sh:353-358`) before `confirm` (`:380`), and so before the post-y gate (`:391`). Only the startup gate precedes that write. The installed-destination writes (`$DEST`, `$BIN_DIR`, bless) do follow the post-y gate. Precise version: "...again after each y, before that target writes its destination."

**Evidence:** `devcontainer-config/install.sh:353-393`, `:945`

---

## Claim 19: "`pgrep -u <uid> -af` for a command line that runs `claude` ... Without `pgrep` the install is refused. ... `docker ps --filter label=cc-project` (cc-isolated's `--id-label`). If docker is missing or unreachable, one line says so and no container is assumed."

**Location:** `docs/decisions/037-bare-host-copy-install.md:69-70`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the probe commands and the docker fallback. The pattern's breadth is Claim 12b.

`pgrep -u "$(id -u)" -af -- "$CLAUDE_PROC_RE"` (`install.sh:843`). `docker ps --filter label=cc-project` (`:857`). cc-isolated passes `--id-label "cc-project=$pid"` (`devcontainer-config/cc-isolated.sh:412`, `:623`). T50-T53 pass, and `esc.log` covers docker failing and hanging.

**Evidence:** `devcontainer-config/install.sh:843-866`; `devcontainer-config/cc-isolated.sh:412`; `docs/reviews/execution-logs/q058-648124c/esc.log`

---

## Claim 20: "A process the probe misses: ... a renamed or wrapped binary whose command line does not end in `claude`"

**Location:** `docs/decisions/037-bare-host-copy-install.md:74`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the residual's description of the matcher.

The matcher does not need the command line to *end* in `claude`. `claude --resume` and `/x/claude -p hi` match (`regex.log`). A version-named native binary run directly (`.../share/claude/versions/2.1.3`) does not match, which is a concrete "renamed" miss. Precise version: "...whose command line has no `claude` or `.../claude` word and no `@anthropic-ai/claude-code/` path."

**Evidence:** `devcontainer-config/install.sh:833`; `docs/reviews/execution-logs/q058-648124c/regex.log`

---

## Claim 21: "The probe is also a new way for the install to be refused on a host where some unrelated command line ends in `/claude`"

**Location:** `docs/working/plan-copy-install-bare-host.md:244`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the false-positive shape.

Any argument ending in `/claude` and followed by a space matches too, not only one at the end of the line: `git -C /home/u/src/claude status` matches (`regex.log`).

**Evidence:** `docs/working/plan-copy-install-bare-host.md:244`; `docs/reviews/execution-logs/q058-648124c/regex.log`

---

## Claim 22: "install.sh is 948 lines after the review, fact-check and Q-058 fixes (808 before Q-058)"

**Location:** `docs/working/plan-copy-install-bare-host.md:248`
**Type:** Configuration
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the line count only.

The file was 948 lines at 66891a7, where this line was written (`git show 66891a7:devcontainer-config/install.sh | wc -l` → 948). 648124c added 8 lines, so it is now 956 (`wc -l` → 956). Paraphrased — no quote available because the claim is a line count, not a snippet.

**Evidence:** `devcontainer-config/install.sh:1-956`

---

## Claim 23: "First close every Claude Code session and stop every cc-isolated container: the installer refuses to stage or install while either runs (Q-058 ...)"

**Location:** `guides/bare-host-hook-wiring.md:17-20`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same coverage and limits as Claim 1.

This rests on the same code and tests as Claim 1 (`install.sh:391`, `:695`, `:945`; T50-T55 pass).

**Evidence:** `devcontainer-config/install.sh:945`; `docs/reviews/execution-logs/q058-648124c/suites.log`

---

## Claim 24: "Tests stub pgrep and docker on PATH (T50-T56); the existing suites stub them to 'none', because the session running them is itself a claude process."

**Location:** commit `ea2c8fb` message
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two suites that run install.sh. `link-claude-home-wiring.bats` and `test/hooks/*.bats` only grep install.sh and never run it, so they need no stub.

`stub_pgrep 'exit 1'` / `stub_docker 'exit 0'` (`test/install-host.bats:41-42`). `printf '#!/usr/bin/env bash\nexit 1\n' > "$TEST_TMPDIR/bin/pgrep"` (`test/cc-isolated-functions.bats:46`). All four suites pass in this Claude session (`suites.log`).

**Evidence:** `test/install-host.bats:35-54`; `test/cc-isolated-functions.bats:44-48`; `test/link-claude-home-wiring.bats:270`; `docs/reviews/execution-logs/q058-648124c/suites.log`

---

## Claim 25: "No env override for the probes: tests use PATH stubs, so the gate has no bypass beyond what PATH already allows."

**Location:** commit `ea2c8fb` message (Notes)
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers `agent_gate`'s inputs. It does not treat PATH control itself as an attack surface.

`agent_gate` reads no environment variable except `TMPDIR` (for the stderr temp file): `errf="$(mktemp "${TMPDIR:-/tmp}/cw-docker-err.XXXXXX")"` (`install.sh:856`). The pattern is the constant `CLAUDE_PROC_RE` (`:833`).

**Evidence:** `devcontainer-config/install.sh:833-883`

---

## Claim 26: "Without perl, or when vis failed, review_diff read only diff's exit status: a changed item showed an empty review and still reached [y/N] ... main refuses at startup when `command -v perl` fails, before the gate or any staging"

**Location:** commit `fa69656` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** The pre-fix behaviour is read from the old code. The post-fix behaviour is executed (T57, T58).

Old code: `diff -ruN "$dest/$item" "$src/$item" 2>&1 | vis || rc=${PIPESTATUS[0]}` (af17e86 `install.sh`, `review_diff`). Only diff's status is kept, so a failed vis over a differing item returned rc 1, changed=1, and an empty review. New code: `:939-943` runs before `agent_gate` at `:945`.

**Evidence:** `devcontainer-config/install.sh:265-271`, `:939-945`; `docs/reviews/execution-logs/q058-648124c/suites.log`

---

## Claim 27: "extract_commit scans every staged file (both targets) and refuses, listing them through vis, any file holding a NUL, before any review or prompt ... No allowlist: `git archive HEAD` of the payload paths holds no NUL today."

**Location:** commit `8d9be0c` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both targets' staging paths. Both call `extract_commit` via `assemble`, and the devcontainer target also calls it directly.

`assemble` calls `extract_commit "$commit" "$stage" "${CLAUDE_HOME_SRC[@]}"` (`install.sh:220`). `install_devcontainer` calls `extract_commit "$STAGED_COMMIT" "$stage" "${dc_paths[@]}"` (`:349`). The list goes through `printf '%s\n' "$nul" | sed 's/^/         /' | vis >&2` (`:196`). T61 and `nul.log` confirm.

**Evidence:** `devcontainer-config/install.sh:196`, `:220`, `:349`; `docs/reviews/execution-logs/q058-648124c/nul.log`, `suites.log`

---

## Claim 28: "The suite passed where the shell printed no warning and failed 53 tests where it did ... All suites: 315/315."

**Location:** commit `648124c` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `test/install-host.bats` at 66891a7 vs 648124c, run in fresh clones with `LC_ALL=en_US.UTF-8` (uninstalled locale), and the four-suite total at 648124c.

`prefix.sh` (2026-09-23T19:36:48-07:00, cwd per-commit clone under the scratchpad):
- 66891a7: exit 1, **53 not ok**, 10 ok.
- 648124c: exit 0, 64 ok.

The four-suite run at 648124c: exit 0, 315 ok.

**Evidence:** `docs/reviews/execution-logs/q058-648124c/ih-66891a7.log`, `ih-648124c.log`, `suites.log`, `prefix.sh`

---

## Submitted Claims

## Claim 29: "Nothing the gate prints reaches the terminal unescaped."

**Submitted by:** orchestrator (task brief)
**Location:** `devcontainer-config/install.sh:836-883`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every line `agent_gate` prints. It does not cover output outside the gate. dfa5791's symlink refusal prints the attacker-plantable `$(readlink "$p")` raw to stderr: `echo "ERROR: $p is a symlink ($(readlink "$p")). install.sh rebuilds" >&2` (`:340`), with no `vis`. The `mkdir` failure message (`:355`) is also raw.

The refusal block ends `} | vis >&2` (`:882`), and the docker NOTE ends `| vis` (`:860`). The other gate messages are fixed text plus `$what`, which callers pass as literals. Executed (`esc.sh`): an ESC in the pgrep command line printed as `99 /x/claude ^[[2J`; an ESC in a container name as `evil^[[31m cc-project=1`; an ESC in docker's stderr as `(line1 ^[[31mred)`. The raw-ESC count in the first case was 0.

**Evidence:** `devcontainer-config/install.sh:340`, `:855-882`; `docs/reviews/execution-logs/q058-648124c/esc.log`, `esc.sh`

---

## Claims Requiring Attention

### Incorrect
- **Claim 14** (`devcontainer-config/install.sh:830-831`): a checkout path ending in `/claude` never self-matches (the next character is `/`), so the `$$` filter guards nothing the comment names. Say it guards a script file named `claude`, or drop the rationale.

### Stale
- **Claim 22** (`docs/working/plan-copy-install-bare-host.md:248`): install.sh is 956 lines at 648124c, not 948.

### Mostly Accurate
- **Claim 12b** (`devcontainer-config/install.sh:827-829`): the regex matches any `.../claude` argument, not just argv0 (`vim ./claude`, `tail -f /var/log/claude`, `git -C ~/src/claude status`). This fails closed.
- **Claim 15** (`devcontainer-config/install.sh:853-856`): only the first stderr line is shown, and it can be an unrelated warning instead of docker's error.
- **Claim 18** (`docs/decisions/037-bare-host-copy-install.md:68`): the devcontainer target rebuilds the checkout mirror before its y; only the destination writes follow the post-y gate.
- **Claim 20** (`docs/decisions/037-bare-host-copy-install.md:74`): the matcher does not require the command line to end in `claude`; a version-named native binary run directly is a concrete miss.
- **Claim 21** (`docs/working/plan-copy-install-bare-host.md:244`): any `/claude` argument followed by a space matches, not only one at the end.

### Unverifiable
- **Claim 16** (`docs/decisions/037-bare-host-copy-install.md:64`): whether a cc-isolated container runs as another uid needs `ps` on a host with a running container. devcontainer's `updateRemoteUserUID` default suggests the same uid.
