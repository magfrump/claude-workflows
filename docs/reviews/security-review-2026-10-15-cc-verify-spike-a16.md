Commit: da700fa5

# Security Review — cc-verify spike paste, A16 structural fix (da700fa5)

**Scope:** `git diff 5a745059..da700fa5 -- docs/working/spike-cc-verify-q117.md` (embedded script and prose), the da700fa5 commit message, and what the change reaches elsewhere in the script: trap and exit paths, `--clean`, every create/write/delete, external-tool calls, verdict and exit codes.
**Date:** 2026-10-15
**Based on:** `docs/reviews/security-review-2026-10-15-cc-verify-spike-acap2.md` (F1-F8; this commit targets F2 and F3). No separate code-fact-check report was supplied for this commit. The "Claims checked" section below does that job for the commit's claims, and most verdicts there are executed.

> ⚠️ **No code fact-check report provided.** Claims about security properties in comments and documentation have not been independently verified by a code-fact-check pass. For full verification, run the `code-fact-check` skill first or use the code-review orchestrator. (Partly offset here: the "Claims checked" section verifies the commit's own claims, most of them by execution.)

Line references: `S:n` is a line of the embedded script (byte-identical to `spike-q117.final6.sh`). `D:n` is a line of `docs/working/spike-cc-verify-q117.md` at da700fa5, and `D:n = S:(n-50)` inside the block. The paste block in the doc is byte-identical to `final-block.txt`, and its fingerprint is `a65f4c30ba1b8907` (checked).

## Trust Boundary Map

```
B1: [same-uid writer of ~/cc-verify (bare-host agent, sandbox may allow it)] → [run dir: mkdir -m 700, cd -P, dev:ino held; in_dir/child_dir/rm_inside checks] → [script's creates/deletes by relative path]
B2: [same-uid writer, directories created by tar/git under the held dir]      → [none: tar -U and git resolve multi-component paths from the cwd]      → [files written/unlinked wherever those components point] (new: exposed by the move to in-place extraction)
B3: [same-uid writer, absolute <run dir> path]                                → [path_ok (realpath + dev:ino) once per call]                         → [main's launcher / devcontainer CLI re-resolving <run dir>/stage, VERIFY-<T8>]
B4: [planted run-*.d / record / snap-* (same-uid)]                            → [--clean: name regex, -L/-d, cd -P self-check, record regular-file check] → [teardown: docker rm/volume rm/image rm, rm_inside]
B5: [merged tree (main by name + pinned branch)]                              → [5-path rule, step-3 pins, post-extraction `find -type l`]           → [stage → docker build context]
```

Input-source classification:

```
S1: contents/entries of ~/cc-verify/run-<RUN>.d during the run — request-time (racy) — UNTRUSTED for path-resolution and file-write sinks;
                                                                  trusted for nothing beyond availability (DoS accepted)
S2: names created inside the run dir by tar (stage/egress, stage/claude-home/{skills,…,scripts}/…) and git (src.git/*, VERIFY-<T8>/*)
                                                                — request-time — UNTRUSTED as path components (swappable once created)
S3: $RDP absolute path (VP/run-<RUN>.d)                          — request-time — UNTRUSTED toward the launcher/CLI path lookups
S4: planted run-*.d, record (T8), snap-images                    — runtime-mutable (persists) — UNTRUSTED for docker rm / image rm / rm sinks
S5: merged tree content (git archive)                            — deploy-time (pinned branch; main by name) — trusted as file content;
                                                                  member *names* are fixed by the tree
S6: $RANDOM-derived temp names (.xw.<pid>.<n>)                   — code-derived — not secret, not relied on (O_EXCL is)
```

The commit moves the defence from "check the path, then use it" to "hold the directory (cwd plus dev:ino), then use relative names". That closes the swaps at the run-directory level that F2 described: the matrix and the F2 stage-swap case pass. But a relative path with more than one component still resolves through whatever a racer puts at each component. GNU tar resolves `skills/x/SKILL.md` from the cwd that way, and so does git when it writes into `src.git/` and `VERIFY-<T8>/`. B2 is that remaining boundary.

## Findings

#### 1. tar follows a swap of a directory it has just created: the stage extraction writes and unlinks files outside the run directory, and a racer that swaps back leaves a clean exit 0

**Severity:** Medium
**Location:** `S:373-375` (D:423-425), `S:380` (D:430); claims at D:31 and D:692; code comment `S:367-369`
**Boundary:** B2
**Move:** 4 (TOCTOU), 11 (bypass enumeration)
**Confidence:** High (executed against the real script)
**Legibility-target:** the doc's residual list (D:692, "not a misdirected write") and D:31/commit message ("-U replaces a planted link instead of writing through it")

`in_dir` holds the cwd for the top level only. Inside it, `tar -x -U` creates `skills/`, `scripts/`, `egress/` and their subdirectories, and then opens each later member by a path relative to the cwd (`scripts/questions.sh`), following whatever is at `scripts` now. `-U` handles a link already present at a member's own path (executed: a symlink planted at `d` before extraction is replaced by a real directory, victim untouched). It does nothing about a directory tar created earlier in the same run and that was then renamed away and replaced by a symlink. Each later member under it is unlinked and recreated in the target.

Evidence (executed). Stub harness, real script, a polling racer (`race.py`) that renames `run-*.d/stage/claude-home/scripts` as soon as it appears and puts a symlink to a victim directory in its place. The victim held `run-tests.sh`, `self-improvement.sh`, `skill-usage-report.sh` = `keep`:
```
== restore=0
swapped …/run-1792061024-1760859.d/stage/claude-home/scripts
script rc=1
REFUSED: a symlink is in the stage (in the merged tree, or planted).
victim:
  claude_config_audit.py: #!/usr/bin/env python3
  … (the whole scripts/ subtree, incl. dirs hermeticity/ and lib/)
  run-tests.sh: #!/usr/bin/env bash
  self-improvement.sh: #!/bin/bash
  skill-usage-report.sh: #!/usr/bin/env bash
```
The racer won 4 of 4 runs. A variant that renames the real directory back once the last member has landed in the victim passed 2 of 3 runs:
```
== restore=1
restored
script rc=0
RESULT Q-117 pass (tree 65e65962b12e40d59c586aa429e580388e051cd9, config b16ed1d32c36cd06)
CHECK main install untouched: ok
…
RESULT spike-q117 exit=0
  run-tests.sh: #!/usr/bin/env bash
```
The post-extraction `find stage -xdev -type l` (S:380) runs after the writes, so it can only report them, and a swap-back removes even that report.

Impact: a writer confined to `~/cc-verify` gets the unsandboxed script to unlink and recreate files, and create directories, in **any directory the user can write**, including `~/.claude/…` under the documented `denyWrite ~/.claude`. The names are fixed (members of the six claude-home dirs or `egress/`, at any subtree depth the racer picks). The content is the merged tree's (main's, apart from the branch's five paths, none of which are in these subtrees), and modes come from the archive. No staged basename is security-sensitive (`settings.json`, dotfiles and the like are absent: checked against tree `65e65962`). So this is a `denyWrite` bypass that can destroy same-named local files and plant repo files, not attacker-chosen content. It refutes the residual list's claim that the tar gap costs "a failed or hung run, not a misdirected write" (D:692).

**Recommendation:** Either (a) extract with a no-follow writer: walk each member with `os.open(..., dir_fd=…, O_NOFOLLOW|O_DIRECTORY)` / `mkdir(dir_fd=…)` / `O_CREAT|O_EXCL|O_NOFOLLOW` (e.g. `python3 -I` reading the `git archive` stream with `tarfile`, regular files and directories only), which actually holds every component; or (b) keep tar, correct D:31/D:692 and the commit's claim, and make `~/cc-verify` in `denyWrite` a stated precondition rather than "Recommended" (D:47). Option (a) is the structural fix A16 asked for. Option (b) is the honest residual.

#### 2. The `path_ok` residual is described as a "small window" before "the tool's own lookup"; the launcher re-resolves the stage path for its whole run

**Severity:** Low
**Location:** `S:90-95` (D:140-145), calls at `S:418-419`, `S:433-434`, `S:468-472`; prose D:33, D:691
**Boundary:** B3
**Move:** 4
**Confidence:** High (read: main's `cc-isolated.sh`)
**Legibility-target:** D:33 ("a small window remains"), D:691 ("only the window between that check and the tool's own lookup remains")

`path_ok` runs once per external call. Main's launcher then calls `config_dir()` (= `$CLAUDE_DEVC_CONFIG_DIR`, re-read each time) at many points across a run that includes the image build: `manifest_file` (:77), `verified_file` (:81), `enforcement_files`/`host_tool_files` (:130, :156, :214-216), the egress check (:440-443), `CC_CONFIG_DIR` as the build context (:820), and `--override-config "$(config_dir)/devcontainer.json"` (:835) for `devcontainer up` (:883) after `check_manifest` (:828). A rename-and-link swap of `<run dir>` at any point in those minutes redirects every later lookup. It needs no race against a single lookup. This grants nothing beyond the accepted D:690 residual (the same writer can edit the stage in place), which is why it is rated Low. But the doc presents path_ok as narrowing the exposure to a sliver, and it does not.

**Recommendation:** Reword D:33/D:691: path_ok proves the path at each call's start only; the launcher and CLI re-resolve it for their full run (minutes, including the build), so this residual is the same as "write inside the run directory".

#### 3. The residual list equates in-place stage edits with "the swap window decision 037 accepts" without naming the worst case (pre-existing, not introduced here)

**Severity:** Medium
**Location:** D:685, D:690, D:47; launcher `check_manifest` (:828) → `devcontainer up --override-config "$(config_dir)/devcontainer.json"` (:835, :883)
**Boundary:** B1, B3
**Move:** 1, 4
**Confidence:** Low (escalation exists only where the writer can write `~/cc-verify` but not `~/.config/claude-devcontainer`)
**Legibility-target:** the residual list (D:685, D:690) and the "Recommended" wording at D:47

Evidence: D:690 reads "It can alter staged files between the script's checks and the launcher's reads. That is bounded by the step-3 pins, the post-bless manifest check and `check_manifest`; what is left is the swap window decision 037 accepts." The window after `check_manifest` is exactly where the CLI reads `stage/devcontainer.json`. An edit there (an `initializeCommand`, or `--privileged` and a `/` mount in `runArgs`) runs host code as the user or gets a root-equivalent container. Decision 037 accepts its target-1 window behind the agent gate ("holds only when no agent runs", 037:66), and it justifies leaving `~/.config/claude-devcontainer` out of `denyWrite` because such a writer "can already edit the installed config and re-bless it" (037:68). The spike runs alongside agents with no gate. So the equivalence holds only if the writer of `~/cc-verify` can also write `~/.config/claude-devcontainer`. In the documented sandbox config both are writable, so nothing escalates (hence Low confidence). A setup that allowlists `~/cc-verify` for writes, which the threat model names, does escalate.

**Recommendation:** Name the worst case in the residual (host code execution through `devcontainer up` reading an edited stage config), and state the equivalence condition: `~/cc-verify` must be no more writable than `~/.config/claude-devcontainer`. Or make `denyWrite ~/cc-verify` a precondition. One sentence in each place.

#### 4. The F2 raw-source matrix case is vacuous on this script, and the exported-SHELLOPTS case does not set the SHELLOPTS it names

**Severity:** Informational
**Location:** `f2cases.sh` (SWAP_RAW case), `matrix6.sh:114`; commit message "27/27"
**Boundary:** Internal — no boundary (test evidence quality, not code behaviour)
**Move:** 11
**Confidence:** High (executed)
**Legibility-target:** commit message and D:655-659

Evidence: `MATRIX F2 raw source swapped for a link   ok (victim untouched; swap happened: no; rc 0)`. No raw directory exists any more, so the case passes without exercising anything. The doc says so ("now there is no raw directory to swap"), but it is counted in the 27. `matrix6.sh: line 114: SHELLOPTS: readonly variable`: the prefix assignment fails, so the case exports the harness shell's own SHELLOPTS, not `braceexpand:hashall:interactive-comments`. It still shows that an exported SHELLOPTS does not reach the launcher, but not with the value written in the case. Neither case covers the B2 leading-directory swap (Finding 1).

**Recommendation:** Count the raw-source case as "N/A on this design", and add a case that swaps a tar-created subdirectory (race.py's shape). Set SHELLOPTS via `bash -o … -c 'export SHELLOPTS; …'`, not via a prefix assignment.

## Untested bypass candidates

- **git's own leading-directory resolution** (S:331 `git clone --bare … src.git`, S:402 `git clone … "VERIFY-$T8"`): the same B2 class as Finding 1. git creates `src.git/objects/…`, `VERIFY-<T8>/.git/…` and the work tree by relative multi-component paths. Its work-tree writes use `O_EXCL` and a cached leading-symlink check, and its `.git` files use lockfile plus `rename` (which replaces a same-named target). A swapped component could therefore create files, or replace `config`/`HEAD`/`index`-named files, in another directory. Not tested: it needs a timed race inside git, and git's lstat cache behaviour was not probed.
- **Run-directory adoption** (S:317-320): a racer that predicts `RUN=$(date +%s)-$$` can swap in its own empty mode-700 directory between `mkdir` and `cd -P`. The check passes it (same uid, 700, empty). Reasoned harmless (the racer could already write the real one, and the dir must sit at the same physical path), but a default ACL on the adopted directory was not tested.
- **Noclobber on a non-regular temp name**: bash opens an existing non-regular file with `O_CREAT` and no `O_EXCL`. A symlink at the temp name to a device with open side effects (e.g. a tape device) would be opened once before the `-L`/`-f` checks refuse. Tested with `/dev/null` only (refused, rc 97). The name is unguessable without the RNG state.

## Endorsement Claims

- **Claim:** A symlink, hard link, FIFO or regular file already at xwrite's temp name makes xwrite refuse (rc 97) without writing the victim; a hard link or symlink at the final name is replaced by rename, victim untouched.
  **Location:** `S:57-67`
  **Evidence:** executed
  **Verified:** functions extracted verbatim from S:47-75, run with a seeded `RANDOM` to collide names: hard link at the temp name → `cannot overwrite existing file`, rc 97, victim `keep`; FIFO with a reader → `changed under the script`, rc 97, reader got nothing; symlink → regular file → rc 97, victim `keep`; symlink → `/dev/null` → rc 97; hard link and symlink at the final name → victim `keep`, link count 1.
  **Not verified:** openlog (S:69-75) under the same collisions. It is the same code shape with `die`, read only.
  **route: code-fact-check**
- **Claim:** `rm_inside` removed a link to an outside directory as a link, removed a hard link without changing the victim, deleted a directory holding an outward symlink without following it, and refused (rc 1) from a cwd other than the run directory.
  **Location:** `S:117-128`
  **Evidence:** executed
  **Verified:** extracted-function probe (`rm L`, `rm H`, `rm D`, wrong-cwd case); the matrix's F2 stage-swap case (`ok (victim untouched; swap happened: yes; rc 1)`).
  **Not verified:** a directory renamed in from outside the run directory between S:126 and S:127 (needs write access outside `~/cc-verify`, beyond B1's writer).
  **route: code-fact-check**
- **Claim:** `--clean` over planted run directories left all victims untouched: a `run-*.d` symlink was skipped; a `record` symlink was refused; a planted dir with `stage`/`VERIFY-deadbeef`/`.xw.*`/`snap-main` symlinks and a `src.git/` holding an outward link had only those links removed.
  **Location:** `S:268-290`
  **Evidence:** executed
  **Verified:** stub-harness `--clean` run with those plants; the victims' `k` files stayed `keep` and the planted dir was emptied.
  **Not verified:** an image-removal path driven by a planted `snap-images` against real docker (the residual at D:688 covers it).
- **Claim:** The trap's exit mapping holds on this script: subshell refusals (97) map to 1 with one REFUSED line, and a tar exit 2 maps to 1 with the named step.
  **Location:** `S:234-265`, `S:370`, `S:373-377`
  **Evidence:** executed
  **Verified:** matrix `tar-exit-2 ok`, `F2 stage swapped … rc 1` (an in_dir xdie path), and the fail/no-rotation/pass rc cases. Bash semantics of the fixed bug confirmed: `f(){ true; return; }` called from an EXIT trap after `exit 3` returns 3.
  **Not verified:** a `git archive` exit 128 together with an in_dir 97 in the same pipeline (pipefail returns the rightmost non-zero, so 97 is expected, but this was read, not run).

## Primitive sweep

Primitive: path-resolving file create/write/unlink (multi-component relative or absolute paths)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `S:317-322` mkdir/cd -P run dir | S1, S3 | physical path, owner, mode, empty, dev:ino | cleared (adoption harmless; untested ACL candidate) |
| `S:325`, `S:354` xwrite record | S1, S6 | O_EXCL, -f, nlink, -ef, rename | cleared (executed) |
| `S:327` openlog log.txt | S1, S6 | same as xwrite | cleared (read; same shape) |
| `S:331` git clone → `src.git` | S2 | none per component | untested candidate (git leading-dir) |
| `S:370` child_dir stage | S1 | mkdir -m 700, parent dev:ino | cleared |
| `S:371` mkdir stage/claude-home | S1 | cd -P + dev:ino both sides | cleared |
| `S:373` tar into stage (egress/ subtree) | S2 | in_dir top-level dev:ino only | **Finding 1** |
| `S:374` tar CLAUDE.md into claude-home | S1 | in_dir dev:ino; single-component member | cleared (top-level member, cwd held) |
| `S:375` tar six dirs into claude-home | S2 | in_dir top-level dev:ino only | **Finding 1** (executed) |
| `S:377` xwrite .manifest in claude-home | S1 | in_dir + xwrite | cleared |
| `S:197-200` xwrite snap-* | S1 | xwrite | cleared (matrix planted-snap-link) |
| `S:402` git clone → `VERIFY-<T8>` | S2 | none per component | untested candidate |
| `S:419`, `S:434` launcher with `$S` | S3 | path_ok once | Finding 2, Finding 3 (accepted residual) |
| `S:472` devcontainer exec `$WS` | S3 | path_ok once; config is main's | cleared (override-config is main's file) |
| `S:176-182`, `S:259`, `S:285` rm_inside | S1, S4 | cwd dev:ino, realpath, parent dev:ino, `--one-file-system` | cleared (executed) |

Primitive: process exec with attacker-influenced arguments: none new in this diff. `docker` calls take `$pid` (hash of an in-run path), `$img` (regex-checked), and tags matching `vsc-verify-<8 hex>`. Unchanged from the prior review.

## Claims checked

| # | Claim (source) | Verdict | Evidence | Mode |
|---|---|---|---|---|
| 1 | Run dir created `mkdir -m 700`, entered `cd -P`, checked (physical path, owner, mode 700, empty), dev:ino recorded (commit; D:15) | Confirmed | S:317-322 | read |
| 2 | Every create, write and delete after that is by relative path from it (commit; D:15) | Confirmed as worded; the implied "cannot be redirected" does not follow | All in-script creates are relative (S:325-402); tar's and git's multi-component paths follow swapped components (Finding 1) | read + executed |
| 3 | `-U` replaces a planted link instead of writing through it (commit; D:31 "GNU tar 1.34, tested") | Partly true | True for a link already at a member's path (pre-plant probe: victim untouched). False for a tar-created directory swapped mid-extraction (race: victim files replaced, 4/4) | executed |
| 4 | Nothing runs chmod; committed modes are checked (commit; D:31) | Confirmed | no `chmod` in the script; S:379 `-x` checks | read |
| 5 | xwrite/openlog: O_EXCL temp, regular file, one link, same inode; F3 hard links closed (commit; D:30) | Confirmed for xwrite | collision probes (Endorsement 1); openlog read only | executed (xwrite), read (openlog) |
| 6 | rm_inside removes a link itself; deletes a dir only if realpath and parent dev:ino are the run dir's (commit; D:32) | Confirmed | Endorsement 2 | executed |
| 7 | path_ok re-checks the absolute path before each launcher and devcontainer call (commit; D:33) | Confirmed (S:418, S:433, S:468) | read | read |
| 8 | "a small window remains" / "only the window between that check and the tool's own lookup" (D:33, D:691) | Inaccurate | the launcher re-resolves `config_dir` across its run (Finding 2) | read |
| 9 | Teardown and --clean run inside the run directory; project id from `<run dir>/VERIFY-<T8>` (commit; D:632) | Confirmed | S:111-113, S:280-286; planted --clean probe | executed |
| 10 | A bare `return` inside the EXIT trap returned the exiting status (commit) | Confirmed | `f(){ true; return; }` in an EXIT trap after `exit 3` → `f returned 3` | executed |
| 11 | Matrix 27/27 on this script; the two F2 swaps fail on 5a745059 (commit) | Confirmed 27/27 here; caveats | private copy: 25 matrix + 2 F2 lines all `ok`. Raw-source case vacuous ("swap happened: no"); SHELLOPTS case runs with a readonly warning (Finding 4). 5a745059 runs not repeated | executed |
| 12 | "Teardown cannot delete outside the run directory" (D:632) | Confirmed within what was tested | rm_inside and --clean probes; extraction (not teardown) can unlink outside (Finding 1) | executed |
| 13 | tar -U gap and FIFO "cost a failed or hung run, not a misdirected write" (D:692) | Refuted for tar | Finding 1; the FIFO half holds (probe: refused, no write) | executed |
| 14 | `denyWrite ~/cc-verify` "closes all of these" (D:695) | Confirmed for sandboxed agents | it removes B1/B2's writer; it does not cover unsandboxed same-uid processes, which the doc does not claim | read |
| 15 | Paste block is the reviewed script; fingerprint `a65f4c30ba1b8907` (D:47) | Confirmed | doc block = `final-block.txt`; embedded script = `final6.sh`; hash matches | executed |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | tar follows a swapped tar-created directory: writes/unlinks outside the run dir (incl. `~/.claude`); swap-back gives a clean exit 0 | Medium | B2 | `S:373-375`, `S:380`; D:31, D:692 | High |
| 3 | Residual equates in-place stage edits with 037's window without naming host code execution or the writability condition (pre-existing) | Medium | B1, B3 | D:685, D:690, D:47 | Low |
| 2 | path_ok window described as small; the launcher re-resolves the stage for its whole run | Low | B3 | `S:90-95`; D:33, D:691 | High |
| 4 | F2 raw-source case vacuous; SHELLOPTS case does not set its named value | Informational | Internal | `f2cases.sh`, `matrix6.sh:114` | High |

## Overall Assessment

The A16 change does what F2 and F3 asked at the level they were filed. Run-directory swaps are refused (matrix F2 stage case), every xwrite collision refuses without writing (executed), teardown and `--clean` deleted nothing outside the run directory in any probe, and the bare-`return` fix is correct. The exit mapping holds, and the matrix passes 27/27 on a private copy. The remaining problem is the same class one level down. Holding the cwd protects the top-level names only. tar, and very probably git, resolve multi-component paths through directories they have just created, and a same-uid racer swaps those. That was executed against the real script: a confined writer replaced files in an arbitrary directory, and with a swap-back the run still reported `RESULT Q-117 pass` and exit 0. The impact is bounded: fixed names, merged-tree content, no sensitive basenames. But it bypasses `denyWrite ~/.claude`, and it contradicts the doc's statement that the tar gap cannot misdirect a write. The single most important thing is to either extract with a per-component no-follow writer (Finding 1, option a) or make `denyWrite ~/cc-verify` a stated precondition and correct D:31, D:692 and the commit's `-U` claim. Within the code paths read and executed beyond that, there are no further findings. Endorsement claims are execution-backed except where marked read.

## Goal-Alignment Note

Success criterion (verbatim): "a markdown report saved to /workspace/.claude/wt-branch-verify/docs/reviews/security-review-2026-10-15-cc-verify-spike-a16.md, structured per the security-reviewer skill, with `Commit: da700fa5` as its first line, plus a short "Claims checked" section (verdict, evidence, verification mode) for the commit message's and the doc's claims about the new design."

This report serves the user goal ("a reviewed, safe one-paste host spike that live-verifies a branch without installing it") by testing whether the structural fix makes the paste safe against the stated same-uid writer. It mostly does, with one executed bypass (Finding 1) that needs either a code change or an honest precondition before the paste can be called safe without `denyWrite`. Probes ran only in `/home/node/.claude/jobs/00bcf178/tmp/secA16.IF26/` (harness copied and repointed; the original `t1/`, `spike-q117.final6.sh` and `final-block.txt` were not modified). No docker, devcontainer, install.sh or cc-isolated ran for real.
