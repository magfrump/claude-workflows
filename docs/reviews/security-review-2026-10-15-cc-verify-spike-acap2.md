Commit: ccd00518

# Security Review: Q-117 spike paste, fix range 2ea3498d..ccd00518 (A-cap fix check)

**Scope:** `git diff 2ea3498d..ccd00518 -- docs/working/spike-cc-verify-q117.md`, the ccd00518 commit message, and the code those changes interact with: the trap and exit paths, `--clean`, every file write, and the verdict and exit codes.
**Date:** 2026-10-15
**Based on:** the embedded script, byte-identical to `spike-q117.final4.sh`. I extracted it from `git show ccd00518:docs/working/spike-cc-verify-q117.md` and compared it with Python. The paste block is byte-identical to `final-block.txt` (sha256 `c761127d…`), and the A-cap reports are `security-review-2026-10-15-cc-verify-spike-acap.md` and `code-fact-check-report-cc-verify-spike-acap.md`.
**Line references:** `S:<n>` is a line of the script (spike-q117.final4.sh). `D:<n>` is a line of the doc at ccd00518. Script line n is doc line n+50.
**Probe dir:** `/home/node/.claude/jobs/00bcf178/tmp/acap2rev.nly1/` (called `$P` below). It holds a private copy of the harness with its paths repointed, and captured outputs are in `$P/logs/`.

> ⚠️ **No code fact-check report provided.** Claims about security properties in comments and documentation have not been independently verified. For full verification, run the `code-fact-check` skill first or use the code-review orchestrator. (This pass checks the range's own claims itself, by execution where possible. See "Claims checked" at the end.)

No HALT pattern matched: no secrets, no disabled TLS, no injection from user-facing input.

## Trust Boundary Map

```
B1: paste text (doc in the host checkout)          → `bash -c "$(cat <<'CCVERIFY' …)"`, fingerprint line        → host bash with docker access
B2 (moved): same-uid writer of ~/cc-verify          → name resolution of run-<RUN>.d/…, run-<RUN>.env, stage-<T8>{,.raw}/…
                                                       (xwrite's mktemp + `>>` + `mv -fT`, stage `mv -T`, `rm -rf`, `tail`)  → host files outside ~/cc-verify
B3: branch code / container output                  → relay (vis) → fd 3 (log), terminal                          → log file, terminal
B4 (new): the script's open descriptors (fd 3, xwrite's {fd})  → inherited across exec                              → launcher, devcontainer CLI, docker CLI, git, cat, mv
B5: user's shell environment (SHELLOPTS)            → `export -n SHELLOPTS`                                         → main's launcher options
B6: docker listings (image tags other sessions move) → step-7 RETAG scan, compare()                                 → CHECK lines, exit code
```

| Source | Mutability | Trust per sink class |
|---|---|---|
| S1 paste text (the script) | code-constant once pasted; the doc is runtime-mutable | trusted only as the reviewed text. The fingerprint is self-reported, so it detects staleness, not tampering. |
| S2 entries and names under `~/cc-verify` (files, **directories**, links, hard links, FIFOs) | runtime-mutable by any same-uid process, including sandboxed agents allowed to write there | UNTRUSTED for path-write, rename, remove and read-to-terminal sinks, for **every component** of a path, not only the last |
| S3 launcher and container output | request-time, branch-controlled | UNTRUSTED for terminal and file sinks |
| S4 inherited fds | code-constant (opened by the script) | trusted toward host children (main's launcher, the devcontainer CLI); container processes do not receive them (docker forwards only stdio; not verified against real docker) |
| S5 SHELLOPTS | deploy-time (the user's own shell) | trusted; a robustness input |
| S6 `docker image ls` / `image inspect` tags | runtime-mutable (other sessions) | trusted for availability, UNTRUSTED as attribution ("the build moved this tag") |
| S7 `run-*.env` contents | S2-derived, format-checked | UNTRUSTED until the RUN/T8 regexes pass |

The range's security claim is that B2 is closed for writes: "Nothing is written by reopening a predictable path" (D:28), and a swap in the mktemp window costs "a failed run, not a misdirected write" (D:632). xwrite and openlog do close the **last** path component: a link, FIFO or directory planted at the destination is replaced or refused (executed), and fd 3 keeps log writes in the original file. But every write still resolves its **parent directories** by name. Under that threat model, `run-<RUN>.d`, `run-<RUN>.d/snap-after`, `stage-<T8>` and `stage-<T8>.raw/devcontainer-config` are all names an S2 writer can repoint (Findings 1 and 2). The switch from `cp` to `mv` turns the source side of the stage assembly into a move, and a move out of a repointed directory deletes files there.

## Findings

#### 1. A `snap-after` symlink planted at any time during the run makes teardown overwrite files in any directory, and the run still reports exit 0

**Severity:** Medium
**Location:** `S:151-158` (snapshot), `S:162` (compare → `snapshot after`), `S:193` (`set +e` in on_exit), `S:51-59` (xwrite)
**Boundary:** B2
**Move:** 3 (error path), 4 (TOCTOU), 12 (sweep of `xwrite` call sites)
**Confidence:** High (executed)
**Legibility-target:** the script's author, plus the doc's residual list (D:629-634)

Evidence (whole functions read):

```
snapshot() {   # snapshot <before|after>, inside the run's own directory
  local d="$V/run-$RUN.d/snap-$1"
  mkdir "$d"
  docker ps -a --no-trunc --format '{{.ID}} {{.Names}}' </dev/null | sort | xwrite "$d/containers"
  …
  main_state | xwrite "$d/main"
}
```
```
  t="$(mktemp "$(dirname "$1")/.xw.XXXXXX")" || die "could not create a temp file beside $1"
  …
  mv -fT -- "$t" "$1" || die "could not put $1 in place."
```

`snap-after` does not exist until teardown, and `run-<RUN>.d` is writable by any S2 writer. So the writer can run `ln -s <victim-dir> ~/cc-verify/run-<RUN>.d/snap-after` at any point in the run's hour; no race is needed. At teardown, `mkdir "$d"` fails and nothing stops the function. errexit is off in on_exit (`S:193`), and bash ignores it inside a function called as `compare || crc=1` anyway. Each `xwrite` then runs `mktemp` and `mv -fT` *inside the victim directory*, because `dirname` resolves through the link. The renames **replace** any existing `containers`, `volumes`, `images` and `main` there. compare then reads `$a/main` back through the same link, so every CHECK reports ok. Probe `snapafter`: a victim directory holding `main` and `images` containing `precious` ended with docker listings in all four names, and the run printed `RESULT spike-q117 exit=0` with five CHECK ok. A concrete target is `<any repo>/.git/refs/heads`, whose loose `main` ref would be replaced with `main_state` text. Before ccd00518, the same writes were `sort > "$d/…"` under noclobber, which could create these names but not replace existing files. ccd00518's rename is what makes this a replacement.

**Recommendation:** Do not reuse a name the writer can pre-plant. Create the after-snapshot with `mktemp -d`, or `mkdir "$d" || return 1` with an explicit check (errexit does not apply inside `compare || …`). Better, make all run-directory writes relative to a directory held as the cwd: `cd -P` once, verify `pwd -P`, then use relative names. And list the `denyWrite` entry as a precondition, not a recommendation (see Finding 2).

#### 2. Stage assembly follows a swapped `stage-<T8>` or `stage-<T8>.raw/devcontainer-config`: `mv` moves (deletes) files out of any directory, or drops merged-tree files into one

**Severity:** Medium
**Location:** `S:315-331`
**Boundary:** B2
**Move:** 4 (TOCTOU), 11 (bypass of the post-assembly symlink check), 12
**Confidence:** High (executed; both variants won on the first attempt in the harness)
**Legibility-target:** the script's author; the doc's claims at D:28-31, D:567 and the S:321 comment

Evidence:

```
mkdir "$S" "$S/claude-home"
chmod +x "$S.raw/devcontainer-config/cc-isolated.sh" …
# mv -T renames; it never follows a link planted at the destination (cp would copy into it).
for i in "${DC_ITEMS[@]}"; do
  [ -e "$S.raw/devcontainer-config/$i" ] || die "devcontainer-config/$i is missing from the merged tree."
  mv -T -- "$S.raw/devcontainer-config/$i" "$S/$i"
done
…
rm -rf -- "$S.raw"
[ -z "$(find "$S" -type l -print -quit)" ] || die "a symlink appeared in the stage while it was assembled."
```

`mv -T` refuses to follow a link at the *last* component only. Both parents are resolved by name on every call.

- **Source side (new in ccd00518).** Probe `srcprobe.sh` watched for `stage-*/claude-home`, then atomically exchanged `stage-*.raw/devcontainer-config` with a symlink to a victim directory (`renameat2(RENAME_EXCHANGE)`). All ten DC items moved *out of* the victim into the stage. Teardown then deleted the stage, and the victim kept only `claude-home host-tools.sha256 manifest.sha256`. The run printed `RESULT Q-117 pass` with exit 0, because it had verified the victim's files instead of the merged tree. With the victim set to `~/.config/claude-devcontainer`, main's install loses those ten items. Step 3 then refuses with a misleading "differs from main's installed copy", and no CHECK runs, because SNAP=0 at step 2. After that, every project's launcher refuses at `check_manifest` until a reinstall. `cp -Rp` only read the source, so the delete-elsewhere capability came with the switch to `mv`. GNU mv falls back to copy-then-unlink across filesystems, so the delete should work there too (not tested).
- **Destination side (pre-existing class, claimed closed).** Probe `stagedst` renamed `stage-*` away right after `mkdir` and put a symlink to a victim in its place. The victim's `devcontainer.json` and `claude-home/CLAUDE.md` were replaced with the merged tree's, and all DC items landed there, including the branch's `init-firewall.sh`. The post-assembly `find` then refused, but only after the writes. Teardown's `rm -rf "$V/stage-$T8"` removed only the link. Pointed at main's config dir, this writes branch code into main's install, which the spike promises never to touch (S:10-11). `check_manifest` would then block launches until someone re-blesses.

The window is roughly 17 process spawns (tens of milliseconds). An inotify or busy-polling watcher won it on the first try. The doc's residual list (D:629-632) names the `tar -x` and `chmod` windows but not these. It describes the windows as costing a failed run, but here the cost is moved or deleted host files.

**Recommendation:** Hold the directories, not their names. Extract into `$S.raw`, `cd -P` into it and check `pwd -P`. Assemble with relative paths inside one held directory, for example by extracting straight into the stage layout under a held cwd, then do a single rename of the finished directory. Or move the whole working root to a path no sandbox may write, and make the `denyWrite` entry (or an equivalent check the script can make) a stated precondition of the run, not a recommendation. Then correct D:28, D:567, D:632 and the S:321 comment.

#### 3. xwrite's descriptor check passes a hard link, and a swapped-in symlink still gets `O_CREAT`

**Severity:** Medium
**Location:** `S:53-55`, `S:63-65`
**Boundary:** B2
**Move:** 11
**Confidence:** Low for impact (see below); High for the mechanism (executed)
**Legibility-target:** the script's author; D:632

Evidence:

```
  exec {fd}>>"$t"
  if [ -L "$t" ] || [ ! -f "$t" ] || [ ! "$t" -ef "/proc/self/fd/$fd" ]; then exec {fd}>&-; die "$t changed under the script."; fi
```

The check itself is sound inside bash. `[` is the builtin, and in the pipeline subshell `/proc/self` is that subshell, the same process that opened `{fd}` (executed: the subshell's BASHPID differs from `$$` and `-ef` holds). But a **hard link** to a victim, swapped in between `mktemp` and `exec`, satisfies all three tests: it is not a link, it is a regular file, and it is the same inode. In `$P/logs/unit-probe.out` P1a, the data was appended to the victim with rc 0. A symlink swapped in is refused, but `>>` has already opened through it with `O_CREAT`. P1c shows the script creating an empty file at the link's target. D:632 says "A swap there makes the check refuse, so the cost is a failed run, not a misdirected write", which is false for the hard link. Impact is limited. A sandboxed agent's `link(2)` to a file outside its writable bind mounts should fail with EXDEV (not verified here), and the symlink variant creates only empty files. Refusals also leave `.xw.*` temp files behind (3 in P1), and nothing cleans those in `~/cc-verify`.

**Recommendation:** Replace `mktemp` + `>>` with an atomic exclusive create of an unguessable name under noclobber: `exec {fd}>"$dir/.xw.$SRANDOM$SRANDOM"` (bash ≥ 5.1), or `$RANDOM$RANDOM$$` otherwise. bash opens a missing file with `O_CREAT|O_EXCL`, which refuses hard links, existing files and symlinks (dangling or not) in one syscall. Keep the `-f`/`-ef` check for the FIFO case. Correct D:632.

#### 4. The `--register` failure path reads the log by name, so a swapped `log.txt` shows another file's tail on the terminal

**Severity:** Low
**Location:** `S:369-370`
**Boundary:** B2
**Move:** 2, 4
**Confidence:** Medium (read-static; `tail` follows links)
**Legibility-target:** the script's author

Evidence: `|| { tail -n 20 "$LOG" | vis | sed 's/^/  | /' >&2; die "--register failed (log above)."; }`

Writes go to fd 3, but this read re-resolves `$LOG`. An S2 writer can make `--register` fail (it can corrupt the stage after step 3) and point `log.txt` at, say, a private key. The last 20 lines then appear on the user's terminal, indented. The doc asks for output to be pasted back. Rated Low rather than Medium because the attacker receives nothing unless the user copies those lines out (the paste-back list names only the `REFUSED:` line). The script by itself delivers nothing.

**Recommendation:** `tail -n 20 /dev/fd/3`. On Linux this reopens the log's own inode read-only through the magic link.

#### 5. fd 3 and xwrite's named fd are inherited by every child

**Severity:** Informational
**Location:** `S:54`, `S:64`, and every child after `S:270`
**Boundary:** B4
**Move:** 6
**Confidence:** High (executed)
**Legibility-target:** the script's author

The `fds` probe shows fd 3 → `run-<RUN>.d/log.txt` open in the fake `devcontainer` for both `up` and every `exec`. The unit probe's fdinfo flags `0102001` lack `O_CLOEXEC`. Every inheritor is trusted host code (main's launcher, the devcontainer and docker CLIs, git, cat, mv), and each could write that file by path anyway. Container processes are started by the daemon with only the exec's stdio, so branch code cannot reach fd 3. That last point is reasoned, not observed against real docker. The one effect is that a long-lived helper spawned by the launcher or CLI keeps the log open after the run. Optional hardening: `3>&-` on children that are not meant to log. No change is needed for safety.

#### 6. The RETAG CHECK reports a reused image's own tag as a moved tag and turns a pass into exit 1

**Severity:** Informational
**Location:** `S:390-396`, `S:175-178`
**Boundary:** B6
**Move:** 5 (invert the check: what does it count that it should not?)
**Confidence:** High (executed)
**Legibility-target:** the doc's verdict reader

Evidence: `if awk -v t="$t" '$1 == t { f = 1 } END { exit !f }' "$V/run-$RUN.d/snap-before/images"; then RETAG="$RETAG $t"; fi`

The awk match is exact and correct for "this tag existed before". But it also counts a tag that already named **the same** image id before the run, for example when a build cache hit yields an image that already existed (`new: no`). Probe `reuse`: `image aaa9402664f1 (new: no)`, `RESULT Q-117 pass`, then `CHECK verify image carried no pre-existing tag: FAIL (refutes the research §7 image-naming claim …)` and exit 1, although no tag moved. Teardown was correct: the image was kept because the snapshot lists it. Only the label and exit code are wrong. IMGTAGS_CHECKED and RETAG are set only on the step-7 success path and read only in compare. That part is right.

**Recommendation:** Count a tag only if its before-snapshot id differs: `awk -v t="$t" -v i="$img" '$1 == t && $2 != i {f=1} END {exit !f}'`.

#### 7. A `die` inside xwrite's pipeline subshell prints a second, misleading REFUSED line

**Severity:** Informational
**Location:** `S:47`, `S:51-59`, `S:201-203`
**Boundary:** Internal (no boundary): exit-status legibility, no input crossing
**Move:** 3
**Confidence:** High (executed)
**Legibility-target:** the user reading the refusal

Every xwrite call is `… | xwrite`, so `die` runs in a subshell. It prints its REFUSED line and exits 1, and `DIED=1` is lost. pipefail and errexit stop the parent with status 1, and on_exit then adds `REFUSED: unexpected failure during step …`. Probe `xwdie` (an mktemp shim that fails for `snap-before`) showed both lines, then teardown and `RESULT spike-q117 exit=1`. The run does stop, the exit code is right, and teardown runs. Only the second line is noise. During teardown (errexit off), an xwrite die inside `snapshot after` does not stop compare. The missing `$a/main` then gives `CHECK main install untouched: FAIL`, which fails closed. Fix: write the die marker to a file descriptor or a flag file the parent checks, or call xwrite outside pipelines (`xwrite path < <(…)` still forks, so use a temp variable).

#### 8. "on_exit runs without errexit, so a failed write cannot skip teardown" holds for write errors, not for SIGPIPE or a second Ctrl-C

**Severity:** Informational
**Location:** `S:189-193`, D:548
**Boundary:** Internal (no boundary): availability of teardown, no input crossing
**Move:** 3
**Confidence:** High (executed for SIGPIPE; read-static for the second signal)
**Legibility-target:** D:548

With stdout piped to a reader that exits (`| head -c 1`), bash was killed by SIGPIPE before the trap could run, leaving `run-<RUN>.d` and `run-<RUN>.env` behind (`$P/logs/misc.out`). on_exit also resets INT/TERM/HUP to their defaults (`trap - EXIT INT TERM HUP`), so a second Ctrl-C during teardown kills it. That line predates this commit. Both cases leave a run record, so the next run refuses and `--clean` recovers. Suggest wording D:548 as "a failed write (EIO, ENOSPC)", and either ignore INT/HUP/PIPE inside on_exit (`trap '' INT HUP PIPE`) or say that a second Ctrl-C needs `--clean`.

## Untested bypass candidates

Guardrails: xwrite/openlog, the post-assembly `find`, the RETAG scan, `--clean`'s regular-file skip, and `export -n SHELLOPTS`.

- `link(2)` from inside a bwrap sandbox to a file outside its writable binds. I expect EXDEV, which would make Finding 3's hard-link variant unreachable for sandboxed agents. There is no bwrap in this sandbox to test it.
- GNU `mv` source-side delete across filesystems (copy-then-unlink fallback) for Finding 2. Not run, because the harness lives on one filesystem.
- A `$S` swap after step 3: the launcher then writes `projects/`, `manifest.sha256` and `verified-live.sha256` into the target by name (S:369, S:383). This is pre-existing and outside the range. The "main install untouched" CHECK would see it after the fact if the target is main's config.
- `git clone` into a `$W` that was swapped for a link to an empty directory between S:302 and S:353. Pre-existing, outside the range. The toplevel check at S:355 refuses afterwards.
- An exported `BASHOPTS` (shopt options reaching the launcher). Not tested, and not touched by the range.
- WSL1's emulated `/proc/self/fd` with the `-ef` test. The host is WSL2, a real kernel, so this was not tested.
- `--clean`'s skip at S:230 versus a swap to a symlink before the `sed` reads. The reads only parse format-checked values, so I did not test it.

## Endorsement Claims

- **Claim:** After openlog, launcher and relay output written to fd 3 stays in the original log inode when `log.txt` (and the run record) are swapped for symlinks mid-run.
  **Location:** `S:61-67`, `S:369`, `S:383`
  **Evidence:** executed
  **Verified:** matrix case `log+record-swap` (victims untouched, rc 0) and the `fds` probe (fd 3 → log in the CLI's children).
  **Not verified:** the read at S:370 (Finding 4), and a swap of `run-<RUN>.d` itself before openlog (a parent-component swap, the Finding 1 class).
  **route: code-fact-check**
- **Claim:** A symlink, FIFO or directory planted at xwrite's *final* path component is replaced (link, FIFO) or refused (directory). It is never written through.
  **Location:** `S:51-59`
  **Evidence:** executed
  **Verified:** `$P/logs/unit-probe.out`, section "destinations".
  **Not verified:** parent components (Findings 1 and 2) and the mktemp→exec window (Finding 3).
- **Claim:** `export -n SHELLOPTS` is what keeps the script's options from reaching main's launcher.
  **Location:** `S:14`
  **Evidence:** executed
  **Verified:** with the line, matrix `exported-SHELLOPTS` passes. With the line deleted, the same setup gives `REFUSED: --register failed` (probe `shellopts`). So the test discriminates.
  **Not verified:** an exported `BASHOPTS`.
  **route: code-fact-check**
- **Claim:** In the paths read, teardown removes images only without `-f`, untags only `vsc-verify-<T8>` names, and keeps an id that carries any other tag.
  **Location:** `S:104-132`
  **Evidence:** read-static, plus matrix `retag` (the pre-existing tag kept, `TEARDOWN: kept image`, rc 1)
  **Verified:** the whole of `teardown()` read; the case patterns at S:113 and S:128.
  **Not verified:** that real docker's `image rm <id>` without `-f` refuses an id with several tags (the fake emulates it; D:613 lists it as not verified).
- **Claim:** The fingerprint line prints `cad246995be322c6` for the reviewed block under `bash --norc`, `bash --norc -i`, `zsh -f` and `zsh -f -i`.
  **Location:** `S:243`, D:47, D:503
  **Evidence:** executed
  **Verified:** probe `paste` plus `$P/logs/misc.out` (bash -i), and the Python hash of the extracted script with its trailing newline stripped.
  **Not verified:** a real terminal paste with readline or bracketed paste.

## Primitive sweep

Primitive: path-based create/write/rename/remove under `~/cc-verify` (S2-named paths)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `S:54` / `S:64` mktemp + `exec >>` | S2 (parent dir name) | `-L`/`-f`/`-ef` | Finding 3 (hard link, O_CREAT); parents unguarded (Finding 1) |
| `S:58` / `S:66` `mv -fT` temp → dest | S2 | final component replaced, not followed | cleared for the final component; parent → Findings 1 and 2 |
| `S:153` `mkdir "$d"` (snap-before) | S2 | errexit at top level | cleared: a pre-planted name refuses the run |
| `S:153` `mkdir "$d"` (snap-after, from on_exit) | S2 | none (errexit off) | Finding 1 |
| `S:154-157` xwrite of the snapshots | S2 | xwrite | Finding 1 (snap-after); snap-before needs a millisecond swap after mkdir (Finding 1 class) |
| `S:266`, `S:304` xwrite of the run record | S2 | xwrite | cleared for the final component (matrix `log+record-swap`); `$V` itself is the user's `~/cc-verify` |
| `S:265` `mkdir run-<RUN>.d` | S2 | mkdir fails on an existing name | cleared |
| `S:315-317` `mkdir $S.raw`, `tar -x` | S2 | none | pre-existing residual (D:630) |
| `S:320` `chmod +x` in raw | S2 | none | pre-existing residual (D:631) |
| `S:324`, `S:326`, `S:327` `mv -T` raw → stage | S2 (both parents) | final component only; `find` afterwards | Finding 2 |
| `S:329` xwrite of `.manifest` | S2 (`$S/claude-home`) | xwrite | Finding 2 class (parent swap) |
| `S:330` `rm -rf $S.raw` | S2 | rm does not follow the operand link | cleared |
| `S:133`, `S:136` `rm -rf` stage/VERIFY/clone | S2 | operand link removed, not followed | cleared |
| `S:185` `rm -rf "$a"` | S2 | operand link removed | cleared |
| `S:213`, `S:235` `rm -rf run-<RUN>.d/snap-*` | S2 / S7 | none for the middle component | Claim 12b (deletes `snap-before`/`snap-after` under any directory a linked `run-<RUN>.d` names; executed, fixed names) |
| `S:370` `tail "$LOG"` | S2 | none | Finding 4 |
| `S:369`, `S:383` launcher writes into `$S` | S2 | none (pre-existing) | Untested bypass candidates (outside the range) |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Planted `snap-after` link: teardown replaces `containers`/`volumes`/`images`/`main` in any directory, no race, exit 0 | Medium | B2 | `S:151-158`, `S:162`, `S:193` | High |
| 2 | Stage `mv -T` follows a swapped parent: deletes files from any directory (source side, new) or writes merged-tree files into one (destination side) | Medium | B2 | `S:315-331` | High |
| 3 | xwrite check passes a hard link; a symlink still gets O_CREAT; D:632 is wrong | Medium | B2 | `S:53-55`, `S:63-65` | Low (impact) |
| 4 | `tail "$LOG"` follows a swapped log on a `--register` failure | Low | B2 | `S:370` | Medium |
| 5 | fd 3 / named fd not close-on-exec | Informational | B4 | `S:54`, `S:64` | High |
| 6 | RETAG counts a reused image's own tag; pass → exit 1 | Informational | B6 | `S:390-396` | High |
| 7 | xwrite die in a subshell → double REFUSED | Informational | Internal | `S:47`, `S:201-203` | High |
| 8 | Teardown skipped on SIGPIPE or a second Ctrl-C | Informational | Internal | `S:189-193`, D:548 | High |

## Overall Assessment

The A-cap fixes do what the matrix tests. These all held under execution in my copy:
- the log on fd 3;
- the atomic record and snapshot writes against a final-component link;
- tag-aware teardown;
- `--clean`'s skip;
- `export -n SHELLOPTS`, which the test genuinely discriminates;
- the status-1 REFUSED line;
- the fingerprint, whose value is correct under all four shells.

The matrix passes 24/24. The range's broader claim, "Nothing is written by reopening a predictable path", does not hold. Every write still resolves its parent directories by name, and the switch from `cp` to `mv` makes the stage assembly's source side destructive. Finding 1 needs no race at all: a link planted any time in the hour makes teardown replace four fixed-name files in any directory, and the run reports exit 0. Finding 2 is a tens-of-milliseconds race that a watcher won on the first try. It can delete main's installed config, or write the branch's `init-firewall.sh` into it, which is exactly what the spike promises never to do. The issues are fixable in place. The robust fixes are to hold directories (cwd, or a single final rename) instead of re-resolving names, or to move the working root somewhere no sandbox may write. The single most important change is to stop treating `denyWrite` for `~/cc-verify` as optional. Until the script holds its directories, that entry (or a check the script can make for it) should be a stated precondition of the host run. Status: three Medium findings to address before this paste is called write-safe. Apart from them, there are no findings in the code paths read, and the endorsement claims marked `route: code-fact-check` are pending execution verification.

## Claims checked

Format follows code-fact-check (verdicts: Verified, Mostly accurate, Stale, Incorrect, Unverifiable). Executed provenance: all commands ran with cwd `$P` = `/home/node/.claude/jobs/00bcf178/tmp/acap2rev.nly1`, all exited 0, and captured output is in `$P/logs/`:
- `BLOCK=$P/final-block.txt timeout 600 bash matrix.sh $P/spike-q117.final4.sh` → `matrix.out` (2026-10-15T10:07Z)
- `timeout 590 bash harness-probe.sh snapafter xwdie fds shellopts reuse paste stagedst stagesrc` → `harness-probes.out` (10:12Z)
- `timeout 60 bash unit-probe.sh` → `unit-probe.out` (10:15:53Z)
- `timeout 590 bash srcprobe.sh` → `srcprobe.out` (10:15:58Z)
- `timeout 590 bash miscprobe.sh` → `misc.out` (10:16Z)

The probe scripts are in `$P`.

**Total claims checked:** 17
**Summary:** 8 verified, 5 mostly accurate, 0 stale, 4 incorrect (1a, 4b, 12b, 13), 0 unverifiable. Sub-parts I could not check (real docker, the previous-version watcher run, the host) are named in each claim's Scope line.

### Claim 1a: "Nothing is written by reopening a predictable path" (D:28); "write stdin to <path> without following anything planted there" (S:48)
**Location:** D:28, S:48 · **Type:** Invariant · **Verdict:** Incorrect · **Confidence:** High · **Verification mode:** executed
**Scope:** Covers parent-directory resolution in xwrite and the stage `mv`s. It does not cover the final component, which is Claim 1b.
**Evidence:** `harness-probes.out` (snapafter, stagedst), `srcprobe.out`, `unit-probe.out` ("dirname component is followed"). The parent path is re-resolved on every write. See Findings 1 and 2.

### Claim 1b: "A rename replaces a planted link instead of following it" (D:29, commit)
**Location:** D:29, S:50, commit · **Type:** Behavioral · **Verdict:** Verified · **Confidence:** High · **Verification mode:** executed
**Scope:** Covers a link, FIFO or directory at the final component. It does not cover the parent components or the mktemp→exec window.
**Evidence:** `unit-probe.out` "destinations": the link and the FIFO were replaced by a regular file and the link target was untouched. A directory gave "cannot overwrite directory", REFUSED.

### Claim 2: "The log is created the same way and then kept open on fd 3, so every later log write lands in that file even if its path is swapped" (D:30, commit)
**Location:** D:30, S:60-67 · **Type:** Behavioral · **Verdict:** Verified · **Confidence:** High · **Verification mode:** executed
**Scope:** Covers writes at S:369 and S:383. It does not cover the read at S:370 (Finding 4).
**Evidence:** `matrix.out` `log+record-swap`; `harness-probes.out` `fds`.

### Claim 3: "The stage is assembled by `mv -T`, not `cp`, and must hold no symlink afterwards" (D:31, commit); "mv -T renames; it never follows a link planted at the destination" (S:321); "`mv -T` renames over it, and fails for a directory" (D:567)
**Location:** D:31, D:567, S:321 · **Type:** Behavioral · **Verdict:** Mostly accurate · **Confidence:** High · **Verification mode:** executed
**Scope:** Covers the final-component behaviour and the existence of the check. It does not establish that the assembly is safe: the check runs after the writes, and parent swaps are followed (Finding 2).
**Evidence:** `srcprobe.out`, `harness-probes.out` stagedst. A directory moved onto an empty planted directory succeeds (`mv -T src1 emptyd` rc 0, a sandbox check run inline), so "fails for a directory" holds only for a file onto a directory and a directory onto a non-empty directory or a link.

### Claim 4a: "Images are never removed with -f now: only vsc-verify-<T8> names are untagged, and the id goes only if no other tag remains" (commit, D:20, D:580)
**Location:** S:104-132 · **Type:** Behavioral · **Verdict:** Verified · **Confidence:** Medium · **Verification mode:** executed
**Scope:** Covers the script's logic against the fake docker. It does not establish real docker's no-`-f` refusal for multi-tag ids. Containers are still `rm -f`, as documented.
**Evidence:** `matrix.out` `retag`; whole-function read.

### Claim 4b: "Step 7 records any pre-existing tag on the verify image, and teardown reports it as `CHECK verify image carried no pre-existing tag: FAIL`, refuting the research §7 image-naming claim" (commit, D:580)
**Location:** S:390-396, S:175-178 · **Type:** Behavioral · **Verdict:** Incorrect (the "refuting" part) · **Confidence:** High · **Verification mode:** executed
**Scope:** The recording and the report are correct. The refutation is not: a tag that already named the same reused image also triggers FAIL. The report comes from compare(), not teardown.
**Evidence:** `harness-probes.out` `reuse` (Finding 6).

### Claim 5: "on_exit runs without errexit, so a failed write (e.g. a closed terminal) cannot skip teardown" (commit, D:548)
**Location:** S:193 · **Type:** Error-handling · **Verdict:** Mostly accurate · **Confidence:** High · **Verification mode:** executed
**Scope:** Holds for write errors (EIO, ENOSPC). It does not cover SIGPIPE (teardown skipped; `misc.out`) or a second signal after the trap reset.
**Evidence:** `misc.out`; Finding 8.

### Claim 6: "A status-1 failure that came from neither die nor the verdict also gets a REFUSED line naming the step" (commit); "every 1 carries a `REFUSED:` line or a verdict line" (D:549)
**Location:** S:201-203, D:549 · **Type:** Behavioral · **Verdict:** Mostly accurate · **Confidence:** High · **Verification mode:** executed
**Scope:** Every exit-1 path I traced carries one. A die inside xwrite's subshell is wrongly treated as "neither die nor verdict" and gets a second line.
**Evidence:** `harness-probes.out` `xwdie`; `matrix.out` `tar-exit-2`, `fail`.

### Claim 7: "Step 9 is labelled" (commit)
**Location:** S:425 · **Type:** Reference · **Verdict:** Verified · **Confidence:** High · **Verification mode:** static
**Scope:** The label exists. Its effect on REFUSED step names was not run.
**Evidence:** `say "9. verdict"` at S:425.

### Claim 8: "--clean skips a run-*.env that is a symlink or not a regular file, instead of crashing" (commit)
**Location:** S:230 · **Type:** Error-handling · **Verdict:** Verified · **Confidence:** High · **Verification mode:** executed
**Scope:** Covers a dangling link. A directory and a FIFO follow from `! -f` (read). A swap after the test was not tested.
**Evidence:** `matrix.out` `clean-dangling-record`.

### Claim 9: "`export -n SHELLOPTS`, so noclobber never reaches main's launcher" (commit, D:569)
**Location:** S:14 · **Type:** Behavioral · **Verdict:** Verified · **Confidence:** High · **Verification mode:** executed
**Scope:** Covers an exported SHELLOPTS. It does not cover BASHOPTS.
**Evidence:** `matrix.out` `exported-SHELLOPTS`; `harness-probes.out` `shellopts`: with the line removed, `REFUSED: --register failed`.

### Claim 10: "The script prints `script sha256 <16 hex>`, and the doc gives the expected value (cad246995be322c6), so a stale or edited paste is visible" (commit, D:47, D:503)
**Location:** S:243 · **Type:** Behavioral · **Verdict:** Mostly accurate · **Confidence:** High · **Verification mode:** executed
**Scope:** The value is correct under four shells, and an accidental edit changes it. A deliberate edit can print the expected value, because the check is self-reported, so "edited" holds only for accidental edits. `BASH_EXECUTION_STRING` is the `-c` text without its trailing newline (the heredoc command substitution strips it), and that matches the doc's value.
**Evidence:** `harness-probes.out` `paste`, `misc.out`, `matrix.out` `fingerprint`.

### Claim 11: "Recommended before you run it: add `~/cc-verify` to your agents' sandbox `denyWrite`. Without that, a same-uid agent can still race the script's millisecond windows" (D:47); "Adding `~/cc-verify` to the agents' sandbox `denyWrite` closes all of these" (D:634)
**Location:** D:47, D:634 · **Type:** Invariant · **Verdict:** Mostly accurate · **Confidence:** Medium · **Verification mode:** static
**Scope:** "Closes" holds in principle, because the entry removes the S2 writer. The precise version is "without it, a same-uid agent can overwrite or delete host files, one way without any race (Finding 1)". Whether the sandbox's denyWrite also blocks rename, symlink and link inside the path was not verified.
**Evidence:** Finding 1.

### Claim 12a: A planted record plus snapshot "can make `--clean` … untag `vsc-verify-<8 hex>-…` names, and remove an *untagged* image that a `VERIFY-<8 hex>`-labelled container ran (never with `-f`)" (D:628)
**Location:** D:628, S:104-132 · **Type:** Behavioral · **Verdict:** Verified · **Confidence:** Medium · **Verification mode:** static
**Scope:** Covers the image and container sinks. The next part, 12b, covers the remaining sinks.
**Evidence:** whole `teardown()` read.

### Claim 12b: "It can do nothing else" (D:628)
**Location:** D:628, S:235, S:213 · **Type:** Invariant · **Verdict:** Incorrect · **Confidence:** High · **Verification mode:** executed
**Scope:** A symlinked `run-<RUN>.d` also makes `--clean` (and on_exit) `rm -rf` the `snap-before`/`snap-after` directories under any directory it names. The names are fixed.
**Evidence:** `misc.out` "clean through a symlinked run-<RUN>.d": the victim's `snap-before/keep` and `snap-after` were deleted, rc 0.

### Claim 13: "the gap between `mktemp` and the descriptor check … A swap there makes the check refuse, so the cost is a failed run, not a misdirected write" (D:632)
**Location:** D:632 · **Type:** Invariant · **Verdict:** Incorrect · **Confidence:** High · **Verification mode:** executed
**Scope:** A hard link passes the check and the data is appended to the victim. A symlink is refused but has already created its target. Reachability from a bwrap sandbox is not established.
**Evidence:** `unit-probe.out` P1a, P1c; Finding 3.

### Claim 14: Commit Notes: "the stub-harness matrix (24 cases) passes on the final script … the same watcher wrote both victim files on the previous version … The block changed; its sha256 is c761127d…"
**Location:** commit body · **Type:** Behavioral · **Verdict:** Verified · **Confidence:** High · **Verification mode:** executed
**Scope:** Covers the final script and block. "Wrote both victims on the previous version" and "Nothing ran on the host" are unverified here.
**Evidence:** `matrix.out`; `sha256sum final-block.txt` = `c761127dcd7e70949afe8732c79d838a10c7764ab30202f80e401e32c096c056`.

Also checked: D:567's "normalizes the payload's modes (:517-520)", which is Mostly accurate. The chmods are at Dockerfile:518-520 and :517 is the `chown -R`, so the substance holds and the line range is one line wide.

## Goal-Alignment Note

The user goal is "a reviewed, safe one-paste host spike that live-verifies a branch without installing it". ccd00518 closes the reproduced A-cap case and cleans up the exit, tag and `--clean` paths. But "safe" still depends on the `~/cc-verify` `denyWrite` entry. Finding 1 needs no race, and Finding 2 can write into main's install or delete from it, which is the "without installing it" half of the goal. So the doc should make that entry a precondition until the script holds its directories. The harness runs in this review used the actual paste block and script. They do not cover real docker, the devcontainer CLI or a bwrap sandbox, which only the host or a sandbox test can show.

Success criterion (verbatim): "a markdown report saved to /workspace/.claude/wt-branch-verify/docs/reviews/security-review-2026-10-15-cc-verify-spike-acap2.md, structured per the security-reviewer skill, with `Commit: ccd00518` as its first line. Also add a "Claims checked" section in code-fact-check style (verdict, evidence, verification mode) for the commit message's and doc's claims about the fix."

Probe hygiene: every process ran under `timeout` (at most 600 s). Watchers were stopped by their PIDs (`kill "$WP"`), and no pkill or pgrep patterns were used. All execution stayed inside `$P`. The shared `branch-verify/t1/`, `spike-q117.final4.sh` and `final-block.txt` were not modified. After the probes, `ps` showed no leftover probe processes.
