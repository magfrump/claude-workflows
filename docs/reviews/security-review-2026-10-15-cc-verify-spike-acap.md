Commit: 2ea3498d

# Security Review: Q-117 spike paste, fix range 53770142..2ea3498d (rubric row A-cap)

**Scope:** `git diff 53770142..2ea3498d -- docs/working/spike-cc-verify-q117.md` plus the 2ea3498d commit message. Out-of-range code was read only where a fix interacts with it.
**Date:** 2026-10-15
**Based on:** the embedded script (byte-identical to `spike-q117.v3.sh`, confirmed with `cmp`) and the paste block (byte-identical to `final-block.txt`, confirmed with `cmp` against the block extracted from `git show 2ea3498d:docs/working/spike-cc-verify-q117.md`). The stub harness ran in a private copy at `/home/node/.claude/jobs/00bcf178/tmp/acap-sec.meAZ/`.
**Line references:** `S:<n>` is a line of the script (spike-q117.v3.sh). `D:<n>` is a line of the doc at 2ea3498d. Script line n is doc line n+43.

> ⚠️ **No code fact-check report provided.** Claims about security properties in comments and documentation have not been independently verified. For full verification, run the `code-fact-check` skill first or use the code-review orchestrator. (This pass checked the range's own security claims itself, by execution where it could. Results are under Findings and Endorsement Claims.)

No HALT-pattern matched: no secrets, no disabled TLS, no injection from user-facing input.

## Trust Boundary Map

```
B1: paste text in docs/working/spike-cc-verify-q117.md (host checkout) → user's interactive bash/zsh, `bash -c "$(cat <<'CCVERIFY' …)"` → host bash process with docker access
B2 (moved): same-uid writer of ~/cc-verify (e.g. a sandboxed agent)  → path-based writes, reads and removals under ~/cc-verify/run-<RUN>.d, run-<RUN>.env, stage-<T8> → host files the writer could not reach directly
B3: branch code and container output (launcher --probe-only, devcontainer exec) → vis/relay → terminal and run-<RUN>.d/log.txt
B4 (moved): main's installed ~/.config/claude-devcontainer/devcontainer.json → `devcontainer exec --override-config` → environment and user of the exec'd process in the verify container
B5: the user's shell environment (CLAUDE_DEVC_BIN_DIR, SHELLOPTS) → script options and child processes (main's launcher)
B6: docker daemon listings (containers and images that other sessions change) → compare() → CHECK and NOTE lines, i.e. the run's verdict on "nothing else was touched"
```

Input sources:

```
S1: paste text (the script)            — code-constant once pasted; the doc it is copied from is
                                          runtime-mutable (the host checkout is a cc-isolated
                                          container's bind mount) — trusted only as the reviewed text
S2: entries under ~/cc-verify          — runtime-mutable (any same-uid process, including sandboxed
                                          agents that are allowed to write there) — UNTRUSTED for
                                          path-write, remove and exec sinks
S3: launcher and container output      — request-time, produced by branch code — UNTRUSTED for terminal
                                          and file sinks; its content is under the branch's control
S4: MAIN_CFG/devcontainer.json         — runtime-mutable host file (same uid); trusted as main's
                                          baseline toward the exec config, re-checked by the
                                          "main install untouched" CHECK only after the run
S5: CLAUDE_DEVC_BIN_DIR, SHELLOPTS     — deploy-time (the user's own shell) — trusted for all sinks;
                                          a robustness input, not an attack input
S6: docker ps / image ls output        — runtime-mutable (other sessions' launchers) — trusted for
                                          availability decisions, UNTRUSTED as attribution ("this
                                          script removed it")
S7: run-*.env contents                 — S2-derived, format-checked (RUN, T8 regexes) — UNTRUSTED
                                          until the format check passes
```

The range moves two boundaries. B2: the paste no longer writes a script file, and the per-run log and snapshots move into a fresh `mkdir`'d directory protected by `noclobber`. B4: step 8's exec now reads main's config file, not the stage's. The range's own security claim is that B2 is now closed against planted symlinks: "every write uses set -o noclobber, so planted symlinks fail the write instead of redirecting it" (2ea3498d message). Finding 1 shows that claim holds for `>` to regular files but not for the script's three `>>` sites. One of those sites carries branch-controlled output, so B2 and B3 combine.

## Findings

#### 1. `noclobber` does not cover `>>`: a planted symlink redirects launcher and container output to any file the user can write

**Severity:** Medium
**Location:** `S:330` (`D:373`), `S:253` (`D:296`), `S:113-119` (`D:156-162`). The claims are at `S:13-14`, `D:26` and in the 2ea3498d message (F2).
**Boundary:** B2, B3
**Move:** 11 (bypasses for a guardrail), 12 (sweep of the file-write primitive)
**Confidence:** High (executed)
**Legibility-target:** whoever fixes the paste next, and the user deciding whether the `denyWrite` recommendation (D:550) is optional
**Evidence:**
- Code, `S:316` then `S:330`: `CLAUDE_DEVC_CONFIG_DIR="$S" "$LAUNCHER" --register "$WS" --profile "$PROFILE" >"$LOG" 2>&1 </dev/null` … `CLAUDE_DEVC_CONFIG_DIR="$S" "$LAUNCHER" --probe-only "$WS" </dev/null 2>&1 | relay >> "$LOG" \`
- Claim, D:26: "Every `>` write in the script is exclusive (`set -o noclobber`), so a symlink planted at a predictable path makes the write fail instead of redirecting it". Commit message: "every write uses set -o noclobber, so planted symlinks fail the write instead of redirecting it."
- Execution (harness copy, `watch.sh`): a watcher waited for `run-<RUN>.d/log.txt` to appear, then replaced it with a symlink to `victim` while `--register` was running. The run still ended `RESULT Q-117 pass`, every `CHECK … ok`, `RESULT spike-q117 exit=0`. `victim` grew from 1 line to 17 and gained the probe's output (`WARNING: no ~/.ssh/canary on the host …`, `NOTE: blessed config 7cebcf213accf7b3 has NOT been verified …`).
- Execution (`watch2.sh`): swapping `run-<RUN>.env` for a symlink during step 1 appended `T8=65e65962` to `victim2`. The run passed, and teardown then removed only the symlink.

Bash's `noclobber` applies to `>` only. `>>` opens with `O_APPEND|O_CREAT` and no `O_EXCL`, so it follows a symlink. Each of the three append targets is first created exclusively. A same-uid writer of `~/cc-verify` only has to replace the file with a symlink between that create and the append. For `log.txt` the window is the whole of `--register` (seconds), and a polling loop won it on the first try. Step 7 then appends `relay`'s stdout there: launcher and container output, i.e. text that branch code chooses. `vis` keeps newlines, so whole lines reach the target. If the target is a shell rc file, an `authorized_keys` file or a hook script, branch-controlled lines land in a file that the writer of `~/cc-verify` could not write itself. This is the exact scenario F2 set out to close: an agent sandbox that may write `~/cc-verify` but not `~/.bashrc`, and the unsandboxed script doing the write for it. The other two append sites carry content the script fixes (`T8=<hex>`, hash lines), so through them an attacker controls only the destination: corruption, not injection.

The same class reaches past `>>`. I checked these two by execution: they are siblings of the guardrail, not part of the range.
- `>` follows a symlink whose target is not a regular file. bash's noclobber skips `O_EXCL` for existing non-regular files. A symlink to a FIFO made `echo x > lnk` block until `timeout` (rc 124). A symlink to `/dev/null` was written through. So `S:13`'s "every `>` creates its file exclusively (O_EXCL)" is inaccurate for non-regular targets. The impact is a hang, or output sent to a device or tty the user can open.
- Step 2's `cp -Rp` and `chmod +x` into the freshly made `$S` (`S:268-277`) follow planted symlinks. A demo wrote `BRANCH` into the target and made it executable. The window there is milliseconds (from `mkdir` to `cp`), so this one is hard to win.

**Recommendation:** Open each file once, exclusively, and write through a held descriptor instead of reopening it by path. For example: `exec 3>"$LOG"` before step 6, then `>&3 2>&1` for `--register` and `| relay >&3` for step 7. Write the run record through `exec 4>"$V/run-$RUN.env"` at `S:216` and later `printf … >&4`. Build snapshot `main` as one `{ …; } > "$d/main"` group. Then correct `S:13-14`, D:26 and the "Tested" line D:526 to say what noclobber does and does not cover. Until then, the `denyWrite` entry for `~/cc-verify` (D:550) is what actually closes F2, and the doc should present it as a precondition rather than an optional hardening step.

#### 2. In `--clean`, a malformed `run-*.env` (a dangling symlink or a directory) crashes the cleanup, so the run's fallback is a dead end

**Severity:** Low
**Location:** `S:180-186` (unchanged code); the claim it falsifies is at D:480 (in range)
**Boundary:** B2 (S7)
**Move:** 3 (error path)
**Confidence:** High (executed)
**Legibility-target:** the user following the `REFUSED … First re-paste … --clean` instruction
**Evidence:**
- Code, `S:184`: `RUN="$(sed -n 's/^RUN=\([0-9]*-[0-9]*\)$/\1/p' "$f" | head -1)"`, under `set -euo pipefail`
- Claim, D:480: "so a `2` only ever comes from the verdict (review API final F1)"
- Execution: with `run-1-1.env -> /nonexistent`, `--clean` printed `sed: can't read …` and exited **2**. With a directory named `run-2-2.env` it exited **4**. Neither reached the `skipping malformed … (remove it by hand)` branch. A normal run then refused with `First re-paste the block … with --clean`, which fails the same way.

The glob matches any directory entry, and `sed` fails before the format check that was meant to catch bad records. A same-uid writer can therefore block every future run, and the only guidance the user gets (re-run `--clean`) cannot succeed. The exit code 2 also contradicts the in-range claim. The `--clean` path runs without a trap, so on_exit's mapping never applies to it.

**Recommendation:** In `--clean`, skip anything that is not a regular, non-symlink file, and reuse the existing "malformed" message: `[ -f "$f" ] && [ ! -L "$f" ] || { echo "skipping malformed $f (remove it by hand)" >&2; rc=1; continue; }`. Also scope D:480's sentence to the started run.

#### 3. Inherited `noclobber` breaks main's launcher when the user's environment exports `SHELLOPTS`

**Severity:** Informational (fails closed; robustness only)
**Location:** `S:15`; the effect shows at `S:316`
**Boundary:** B5
**Move:** 3
**Confidence:** High (executed)
**Legibility-target:** whoever triages a host-run refusal
**Evidence:**
- Without `SHELLOPTS` in the environment, the child shell did not inherit noclobber (`child: braceexpand:hashall:interactive-comments`). With `SHELLOPTS=braceexpand` exported, it did (`…:noclobber`).
- Harness run with `SHELLOPTS` exported: `REFUSED: --register failed (log above).` The log shows `cc-isolated.sh: line 286: …/stage-65e65962/.manifest.AmCPz6: cannot overwrite existing file`. Exit 1, teardown and CHECKs ok.

In the default case the brief's concern does not apply, because noclobber stays inside the script. Only a user whose environment exports `SHELLOPTS` hits this, and the run then refuses safely. The same mechanism already propagated `errexit`, `nounset` and `pipefail` at 53770142.

**Recommendation:** Optional. Run the two launcher calls as `env -u SHELLOPTS -u BASHOPTS CLAUDE_DEVC_CONFIG_DIR="$S" "$LAUNCHER" …`.

#### 4. on_exit runs under `errexit`, so a failed write to the terminal skips teardown

**Severity:** Informational (D:429 already tells the user to re-paste with `--clean` after a closed terminal, and the next run refuses until they do)
**Location:** `S:147-173` (`say "teardown"` at `S:159` and the new REFUSED `printf` at `S:156`); the claim is at D:479 (in range)
**Boundary:** Internal, no boundary. This is the error-path state after an exit (move 3), not a trust crossing.
**Move:** 3
**Confidence:** Medium (shown with a closed descriptor, EBADF; a hung-up tty returns EIO, which was not run)
**Legibility-target:** the user reading the exit list
**Evidence:**
- Claim, D:479: "`130`: interrupted (Ctrl-C, TERM, HUP). The trap still tears down."
- Execution: `bash -c 'set -e; f(){ …; printf "== teardown\n"; echo "after-printf (teardown would run)" >&2; }; trap f EXIT; exit 130' >&-` printed `printf: write error: Bad file descriptor`, never reached the next line, and exited 1.

When the terminal closes, the script gets HUP and runs `exit 130`, and on_exit's first write to stdout fails. `errexit` then ends the handler before `teardown`. The range adds one more write that happens before teardown (the REFUSED line). Signals I sent to the process while its output went to a file (TERM and HUP) did tear down and gave exit 130.

**Recommendation:** Start on_exit with `set +e`, or make its writes `|| true`. Then reword D:479 so that HUP from a closed terminal points to D:429.

#### 5. The `--clean` fallback goes back to a doc that containers can write, with nothing that ties it to the reviewed text

**Severity:** Informational (the first paste has the same trust root, already reviewed at 53770142; the range only reroutes the fallback onto it)
**Location:** `S:53`, D:429
**Boundary:** B1
**Move:** 1
**Confidence:** Medium
**Legibility-target:** the user pasting the fallback days after a crash
**Evidence:**
- `S:53`: `REPASTE="re-paste the block from docs/working/spike-cc-verify-q117.md with --clean as its last argument"`
- D:429: "**re-paste the same block with `--clean` in place of the checkout path**"

The doc says "the same block", but nothing helps the user check that what they re-paste is the same: the doc in the host checkout may have changed in the meantime. A changed block could also differ in layout (for example where `snap-before` lives), and a `--clean` from a different version could then misjudge a leftover. The range does close a real gap. There is no longer a script file on disk to swap, so F1 stands.

**Recommendation:** At the start, print a fingerprint such as `printf %s "$BASH_EXECUTION_STRING" | sha256sum | cut -c1-16` and store it in `run-<RUN>.env`. Then `--clean` can warn when its own fingerprint differs, and the fallback message can name the fingerprint to look for.

#### 6. The step label and the REFUSED line miss some failures

**Severity:** Informational
**Location:** `S:52`, `S:153-157`, `S:365-381`
**Boundary:** Internal, no boundary (diagnostics only)
**Move:** 3
**Confidence:** High (read-static)
**Legibility-target:** the user pasting results back
**Evidence:**
- `case "$rc" in 0|1|2|130) ;; *) printf 'REFUSED: unexpected failure during step "%s" …`
- Step 9 has no `say`.

A command that fails with status 1 under `set -e` (for example `mkdir "$S.raw"` at `S:264`, or `docker ps`) exits 1 without any REFUSED line. The user then has only the tool's own stderr to paste back. A failure during the step-9 verdict is labelled with step 8's text. Neither causes a wrong verdict.

**Recommendation:** Add `say "9. verdict"` before `S:366`. Optionally, print the step for every non-zero exit that does not come from `die`, for example by setting a `DIED=1` flag in `die()`.

## Untested bypass candidates (move 11, guardrail: `mkdir run-<RUN>.d` plus `noclobber`)

Tested, with results under Finding 1: a dangling symlink at a `>` target is refused (commit claim, consistent with bash semantics). A live symlink to a regular file at a `>` target is refused. `>>` through a symlink is **bypassed** (run-env and log both executed). A `>` symlink to a FIFO or device is **followed** (executed). `cp -Rp` and `chmod` through a symlink are **followed** (executed).

Not tested:
- **Replacing `run-<RUN>.d` itself with a symlink after the `mkdir` (`S:215`).** Every later path goes through it. By reasoning, the exclusive creates then make *new* files (`log.txt`, `snap-*/…`) in a directory the attacker picks, and on_exit's `rm -rf -- "$V/run-$RUN.d/snap-before"` removes `<target>/snap-before`. Not run, because it needs a timed swap; the reach is limited to those fixed names.
- **Planting `run-<RUN>.d/snap-after` before compare.** `compare || crc=1` runs with errexit off. If `mkdir` and the exclusive writes fail, compare would go on to compare the planted files and could report `ok`. Not run. A same-uid writer can already forge any check result, so this adds no reach.
- **Hard link at a `>` target.** By reasoning it is refused: an existing regular file fails noclobber. Not run.

Because of these candidates, the noclobber guardrail is left out of Endorsement Claims.

## Endorsement Claims

- **Claim:** The paste block, typed into a pty, ran the script to `RESULT spike-q117 exit=0` with outer `$?` 0 under `bash --norc -i` (5.2.15), `zsh -f -i`, and `zsh -i` with an rc file (5.9; one rc empty, one with `interactive_comments extended_history hist_verify`). No history-expansion or parse error appeared.
  **Location:** D:42-284 (the block)
  **Evidence:** executed
  **Verified:** `script -qfc "<shell>"` fed `final-block.txt` line by line against the fake HOME, whose `~/claude-workflows` exists. The script has no `!` that triggers history expansion (grep for `![^ =(\t]` matched only `#!/usr/bin/env bash`, which caused no error), no tabs, and no use of `$0`. `spike-q117` lands in `$0` and the checkout in `$1`, and `[ $# -eq 1 ]` passed.
  **Not verified:** bracketed-paste from a real terminal emulator; bash < 5.2, whose different `$( … )` heredoc parser was not tried; a user rc that aliases `cat`.
  **route: code-fact-check**

- **Claim:** No file at 2ea3498d outside `docs/reviews` still mentions `cc-verify/spike-q117` or `spike-q117.sh`.
  **Location:** repository at 2ea3498d
  **Evidence:** executed
  **Verified:** `git grep -n 'cc-verify/spike-q117\|spike-q117\.sh' 2ea3498d -- . ':!docs/reviews'` printed nothing.
  **Not verified:** the review reports under `docs/reviews/` (historical by design).

- **Claim:** In the harness, the exit mapping kept the verdict's statuses and the interrupt status: no-rotation gave `RESULT Q-117 no-rotation` and exit 2; FAIL lines plus a non-rotating pool gave `RESULT Q-117 FAIL` and exit 1; TERM and HUP sent to the `bash -c` process during step 8 gave exit 130 with teardown, all CHECKs ok, and only the harness container left.
  **Location:** `S:147-173`, `S:377-381`
  **Evidence:** executed
  **Verified:** runs with `FAKE_POOL`, `FAKE_FAILS` and `FAKE_HANG`, signalled by PID. Also by reading: `NOROT=1` is set only right before `exit 2` (`S:379`), so any other status 2 becomes 99 and then 1.
  **Not verified:** Ctrl-C from a real terminal (in a non-interactive background job SIGINT is ignored, so that path could not be run); the commit's tar-exit-2 case, which this pass did not re-run.
  **route: code-fact-check**

- **Claim:** The run directory is made with plain `mkdir` before the run record and before the trap, and a refusal there creates nothing else. After a `kill -9` in step 8, the next run refused, and `--clean` removed the container, both volumes, the `vsc-verify-65e65962-abc` image, the stage, the workspace, the clone, the record and `snap-before`. The harness's container, volume and image survived, and `run-<RUN>.d/log.txt` stayed (by design).
  **Location:** `S:213-219`, `S:176-191`
  **Evidence:** executed
  **Verified:** harness run `k9.out`, then a refused run, then `--clean`, with docker state listed before and after.
  **Not verified:** real docker's `image rm` matching by tag (the fake matches by id only).
  **route: code-fact-check**

- **Claim:** The two CHECKs this range turned into NOTEs only ever reported removals this script cannot make. Its one container removal is `docker rm -f` on ids listed by `--filter "label=cc-project=$pid"`, where `pid` comes from `T8` and the physical `~/cc-verify` path. Its image removals are limited to ids missing from the before-snapshot (and, for `-f`, not used by any container) and to `vsc-verify-<T8>-*` tags. The volume CHECK is unchanged.
  **Location:** `S:63-105`, `S:122-145`
  **Evidence:** read-static
  **Verified:** whole `teardown()` and `compare()` read. `S:307` refuses a run whose label is already in use. An `image rm -f` on a new id would drop every tag on that id. Any pre-existing tag that had been moved onto that id would then appear only as a NOTE, and the commit names this case as a residual.
  **Not verified:** whether another session can, within the run, produce the verify image's id (it would need the stage's branch `init-firewall.sh` layers).

- **Claim:** Pointing step 8 at main's config leaves the values exec resolves the same. The build and workspace values in devcontainer.json are anchored to `${localEnv:CC_CONFIG_DIR}` (still exported as `$S`) and `${localWorkspaceFolder}`, not to the config file's own directory, and the container is found by `--id-label` as before.
  **Location:** `S:358-363`; main's `devcontainer.json:22-28, 71, 78-79, 134`; `cc-isolated.sh` dc args
  **Evidence:** read-static
  **Verified:** main's devcontainer.json `dockerfile`, `context`, `remoteUser`, mounts and `workspaceMount` lines; the launcher's `dc=(--workspace-folder … --override-config "$(config_dir)/devcontainer.json" --id-label …)`.
  **Not verified:** the real devcontainer CLI's exec (the fake ignores `--override-config`). Whether the CLI compares the config path with the container's `devcontainer.config_file` label is still covered only by Not-verified #3 (D:533).
  **route: code-fact-check**

- **Claim:** With no `SHELLOPTS` in the environment, `noclobber` stays in the script process. Main's launcher and every redirect to `/dev/null` work, and the harness pass run ended `exit=0`.
  **Location:** `S:15`
  **Evidence:** executed
  **Verified:** the propagation probe and the pass run (`pass.out`).
  **Not verified:** an exported `SHELLOPTS` (Finding 3).

- **Claim:** `MAIN_BIN` matches install.sh's default, `BIN_DIR="${CLAUDE_DEVC_BIN_DIR:-$HOME/.local/bin}"`, at main's `install.sh:1311`, as the comment cites.
  **Location:** `S:22`
  **Evidence:** read-static
  **Verified:** `git show main:devcontainer-config/install.sh` lines 1305-1315.
  **Not verified:** whether the user's current shell still exports the value install.sh saw.

- **Claim:** `shellcheck -S warning` and `bash -n` report nothing on the script.
  **Location:** whole script
  **Evidence:** executed
  **Verified:** both returned 0 on `spike-q117.v3.sh`.
  **Not verified:** none needed.

## Primitive sweep

Primitive: path-based file writes under `~/cc-verify` (redirection, `cp`, `chmod`), the sink class for B2

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `S:110-112` `> "$d/containers"`, `volumes`, `images` | S2 path, S6 content | fresh `mkdir "$d"` plus noclobber | cleared: exclusive create of a regular file (FIFO caveat, Finding 1) |
| `S:113` `: > "$d/main"` | S2 path | noclobber | cleared, as above |
| `S:115-119` `>> "$d/main"` | S2 path, hash content | none (append) | Finding 1 (destination only) |
| `S:216` `> "$V/run-$RUN.env"` | S2 path | noclobber | cleared |
| `S:253` `>> "$V/run-$RUN.env"` | S2 path, fixed `T8=` content | none (append) | Finding 1 (executed) |
| `S:276` `> "$S/claude-home/.manifest"` | S2 path | fresh `mkdir "$S" …` plus noclobber | cleared (exclusive) |
| `S:316` `>"$LOG"` | S2 path, S3 content | noclobber | cleared (exclusive) |
| `S:330` `relay >> "$LOG"` | S2 path, S3 content | none (append) | **Finding 1 (executed, branch-controlled content)** |
| `S:271, 273, 274` `cp -Rp … "$S/…"` | S2 path, S3-class content (merged tree) | fresh `mkdir`; none at the file | Finding 1 sibling (out of range; narrow window; executed primitive) |
| `S:277` `chmod +x "$S/…"` | S2 path | none | Finding 1 sibling (out of range; executed primitive) |
| `S:265-266` `tar -x -C "$S.raw"` | S2 path, merged tree | fresh `mkdir "$S.raw"`; GNU tar's handling of planted symlinks | not analyzed (out of range, unchanged) |
| `S:224, 300` `git clone … "$SRCGIT"`, `"$W"` | S2 path | clone refuses a non-empty destination | cleared, not analyzed further (unchanged) |

Primitive: path-based removal (`rm -rf`)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `S:98, 101, 102` teardown removals | S7 (format-checked RUN and T8) | regexes | cleared: unchanged since 53770142 |
| `S:143` `rm -rf -- "$a"` (snap-after) | S2 path | none | untested candidate (directory swapped for a symlink), fixed name |
| `S:167` and `S:188` `rm -rf … run-$RUN.d/snap-before` (`snap-after`) | S2 and S7 path | RUN regex | untested candidate (directory swapped for a symlink), fixed names only |

The sweep is partial at one row, `tar -x` (not analyzed, outside the range).

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | `>>` (and `cp`/`chmod`, and FIFO targets) bypass noclobber; branch output can be appended to any user-writable file | Medium | B2, B3 | `S:330`, `S:253`, `S:115-119`; claims `S:13`, D:26, commit msg | High |
| 2 | `--clean` crashes (exit 2 or 4) on a malformed `run-*.env`; the fallback is a dead end; contradicts D:480 | Low | B2 | `S:180-186`, D:480 | High |
| 3 | An exported `SHELLOPTS` passes noclobber to the launcher; `--register` refuses | Informational | B5 | `S:15`, `S:316` | High |
| 4 | on_exit under errexit: a failed terminal write skips teardown; D:479 overstates HUP | Informational | Internal | `S:147-173`, D:479 | Medium |
| 5 | The re-paste fallback inherits the doc's mutable trust root; nothing checks that the version matches | Informational | B1 | `S:53`, D:429 | Medium |
| 6 | Step 9 is labelled as step 8; status-1 set -e failures print no REFUSED line | Informational | Internal | `S:52`, `S:153-157`, `S:365` | High |

## Overall Assessment

Most of the range does what it claims, confirmed by execution. Taking the script off the disk removes the swap-the-script attack (F1 at 53770142). The paste parses and runs under bash and zsh, interactive included. The exit mapping keeps 0, 1, 2 (verdict only) and 130, and maps the rest to 1. `run-<RUN>.d` is made before the trap and survives a crash followed by `--clean`. Turning the container and image disappearances into NOTEs loses nothing this script itself can remove. Step 8's switch to main's config resolves the same values, though only by reading, since the real CLI is unverified. The exception is the range's main hardening claim, that every write refuses a planted symlink. It is false for the three `>>` sites, and one of them appends branch-controlled output with a window of seconds, which I exploited first try in the harness. That reopens the F2 scenario, a sandboxed `~/cc-verify` writer reaching files outside its sandbox. The fix stays local to the script: hold exclusively opened descriptors instead of reopening by path, then correct the comment, doc and commit text. It is the single most important thing to address before rubric row A-cap can close. Until then, the `denyWrite` entry for `~/cc-verify` should be a stated precondition of the host run. The other items are Low or Informational. Status: one Medium finding to fix. Apart from it, there are no findings within the code paths read, and the endorsement claims marked `route: code-fact-check` are pending execution verification.

## Goal-Alignment Note

The user goal is "a reviewed, safe one-paste host spike that live-verifies a branch without installing it". The range moves the paste closer to it: there is no script file on disk, the exit codes are cleaner, and other sessions' rebuilds no longer cause spurious CHECK failures. But Finding 1 means "safe" currently depends on a settings change outside the paste. The harness work and the pty tests both point at the actual paste, so the claims above apply to what the user would run. They do not cover the real docker daemon or the devcontainer CLI, which only the host run can test.

Success criterion (verbatim): "a markdown report saved to the path named at the end of this prompt, structured per your role's skill, with `Commit: 2ea3498d` as its first line."

Probe hygiene: every process ran under `timeout` (at most 300 s), signals went by PID, and all execution stayed inside `/home/node/.claude/jobs/00bcf178/tmp/acap-sec.meAZ/`. The shared `t1/`, `spike-q117.v3.sh` and `final-block.txt` were not modified. One stray `sleep` (PID 1039116, parent 1) was seen during the probes. Its owner was unclear, so I left it running; it ends by itself.
