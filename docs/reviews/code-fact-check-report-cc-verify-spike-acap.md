**Commit:** 2ea3498d
**Replication:** k=1 (A-cap narrow pass)

# Code Fact-Check Report

**Repository:** /workspace (worktree `/workspace/.claude/wt-branch-verify`, branch `docs/branch-verify-without-install`)
**Scope:** `git diff 53770142..2ea3498d -- docs/working/spike-cc-verify-q117.md` (the embedded host script and its prose), the 2ea3498d commit message, and the out-of-range code those fixes interact with (callers, shared variables, trap/exit paths, paste wrapper, verdict and exit-code flow). Role: code fact-check (k=1, decision 031), rubric row A-cap.
**Checked:** 2026-10-15
**Total claims checked:** 24
**Summary:** 17 verified, 3 mostly accurate, 0 stale, 4 incorrect, 0 unverifiable

Line numbers below are for `docs/working/spike-cc-verify-q117.md` at 2ea3498d. The embedded script starts at doc line 44, so script line N is doc line N+43. Before testing I confirmed that the doc's paste block is byte-identical to `final-block.txt`, and that the block's body is byte-identical to `spike-q117.v3.sh` (`cmp`, both identical).

**Harness.** I copied the stub harness into my own directory, `/home/node/.claude/jobs/00bcf178/tmp/acap-fc.RvMs/` (called `$W` below), and changed it in three ways: `setup-t.sh` points at `$W`; its `spike-q117.sh` copy line is dropped, because the script is never on disk; and `FAKE_HANG` is added to the fake devcontainer. For Claim 9b I also added `FAKE_RETAG` to `$W/t1/bin/devcontainer`: on `up`, it moves a named pre-existing tag onto the new image. `$W/run.sh` and `$W/run-path.sh <dir>` run the v3 script in the paste's form (`bash -c "$(cat spike-q117.v3.sh)" spike-q117 <arg>`) with the fake HOME, PATH and DSTATE. Everything ran under `timeout`. Processes were stopped by PID, taken from `/proc/<pid>/task/*/children`. Captured output is in `$W/logs/`. Nothing in `branch-verify/` (t1, v3 script, final block) was modified.

`docs/reviews/hallucination-patterns.md` was read. Its entries are fabricated counts. None of the claims below matches a logged pattern, and none of the Incorrects is a fabricated symbol, so the log needs no entry.

---

## Claim 1: "The paste hands the script to `bash -c` as text; it is never written to disk, so nothing can swap it between your paste and its run"

**Location:** `docs/working/spike-cc-verify-q117.md:13`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the paste wrapper: the script text reaches `bash -c` intact in bash, `bash -i`, `zsh -f` and `zsh -f -i` (also through a pty), `$0`=`spike-q117` and `$1`=the checkout, and no script file is created. Does not establish that the interactive shell's history file (`~/.zsh_history`, `~/.bash_history`) stays unwritten; it records the paste, though it is never executed from there. Also does not cover zsh in a non-UTF-8 locale (see the evidence below).
**Legibility-target:** the user pasting the block; the A-cap rubric reader

The wrapper, quoted:
```
# docs/working/spike-cc-verify-q117.md:43, :425-426
bash -c "$(cat <<'CCVERIFY'
...
CCVERIFY
)" spike-q117 ~/claude-workflows
```
I swapped `bash -c` for `printf "%s\n"` into a file and fed the block through a pty (`script -qec`). Under `bash --norc -i` the result was byte-identical to `spike-q117.v3.sh`. Under `zsh -f -i` with `LC_ALL=C.UTF-8` it was also byte-identical. Under zsh in the sandbox's broken `C` locale, the one non-ASCII byte pair (the `§` in script line 136, doc :179, a message string) came back as `??`. Nothing else changed, and the run still passed. The script never references `$0`, and `[ $# -eq 1 ]` (doc :237) sees the checkout as `$1`. A `grep '![^ =(]'` over the body finds only `#!/usr/bin/env bash`, where `#` begins a word and stops history expansion. No `bash ~/cc-verify/spike-q117.sh` or `cc-verify/spike` text remains in the doc, and `git grep 'spike-q117\.sh' 2ea3498d -- ':!docs/reviews'` returns nothing.

Executed: `env … HOME=$W/t1/home … script -qec "<sh>" /dev/null < $W/rt.txt` for sh ∈ {`zsh -f -i`, `bash --norc -i`}, cwd `$W`, exit 0, 2026-10-15 ≈09:48:40-09:49:10Z. Full runs of the real block: `env … <sh> < $W/paste.txt`, 09:48:07-09:48:15Z, exit 0 for bash, `bash -i`, `zsh -f` and `zsh -f -i`; also through a pty at 09:48:25-29Z, exit 0, with `RESULT spike-q117 exit=0` and `OUTER-RC=0`.

**Evidence:** `docs/working/spike-cc-verify-q117.md:13`, `:43-426`; `$W/roundtrip-bash.txt`, `$W/roundtrip-zsh.txt`, `$W/logs/paste-bash.out`, `$W/logs/paste-bashi.out`, `$W/logs/paste-zshf.out`, `$W/logs/paste-zshfi.out`, `$W/logs/pty-zshfi.out`, `$W/logs/pty-bashnorci.out`

---

## Claim 2: "`~/cc-verify/run-<RUN>.d/` (created with `mkdir`, which fails if anything is already at that path)"

**Location:** `docs/working/spike-cc-verify-q117.md:26`; code `:257-258`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers creation of the run directory, which happens before the trap and refuses an existing path, including a dangling symlink. Does not establish that its contents stay unplanted afterwards: a same-uid writer of `~/cc-verify` can write inside the directory once it exists (Claims 3b and 3c).
**Legibility-target:** security reviewer of F2

```
# docs/working/spike-cc-verify-q117.md:258-262
mkdir "$V/run-$RUN.d" || die "could not create $V/run-$RUN.d (something is already there)."
printf 'RUN=%s\n' "$RUN" > "$V/run-$RUN.env"
trap on_exit EXIT
trap 'exit 130' INT TERM HUP
LOG="$V/run-$RUN.d/log.txt"
```
The directory is created before `trap on_exit EXIT`, so a failed `mkdir` exits through `die` with nothing to tear down. Executed: `mkdir mk/run-1.d` over a dangling symlink printed `mkdir: cannot create directory 'mk/run-1.d': File exists`, exit 1, cwd `$W`, 2026-10-15T09:50:51Z. After the pass, FAIL and no-rotation runs, each `run-*.d` held only `log.txt` (listing in the 09:45:21Z run). The leftover check still globs only `run-*.env` (doc :252), which is unchanged.

**Evidence:** `docs/working/spike-cc-verify-q117.md:251-262`; `$W/logs/mkdir-symlink.out`, `$W/logs/pass.out`

---

## Claim 3a: "a symlink planted at a predictable path makes the write fail instead of redirecting it" (symlink to a regular file, or dangling)

**Location:** `docs/working/spike-cc-verify-q117.md:26`, `:56-58`, `:526`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `>` redirections under bash 5.2 `noclobber` where the target is a symlink to an existing regular file, or a dangling symlink. Does not establish the claim for symlinks to non-regular files (3b), or for `>>` appends (3c).
**Legibility-target:** security reviewer of F2

Under `set -o noclobber`, `echo X > reg` (reg → regular file) printed `reg: cannot overwrite existing file`, exit 1, target unchanged. `echo X > dl` (dl → nonexistent) printed `dl: cannot overwrite existing file`, exit 1, and no target was created. Command `bash nc-test.sh $W/nc`, cwd `$W`, exit 0, 2026-10-15 ≈09:46Z.

**Evidence:** `docs/working/spike-cc-verify-q117.md:56-58`; `$W/nc/nc-test.sh`, `$W/logs/noclobber.out`

---

## Claim 3b: "noclobber: every `>` creates its file exclusively (O_EXCL), so a symlink planted at a predictable path cannot redirect a write" / "`set -o noclobber` refuses a write through a planted symlink, dangling or not"

**Location:** `docs/working/spike-cc-verify-q117.md:56-57` (code comment), `:526` (doc)
**Type:** Behavioral
**Verdict:** Incorrect
**Severity:** Medium (the mechanism is misstated; the practical gap is a FIFO or device target)
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bash `noclobber` semantics for `>` onto an existing non-regular target. Does not establish that any specific `>` in this script is reachable by a planter in practice. The targets inside the fresh `run-<RUN>.d` and `$V/run-$RUN.env` would need a same-uid write after `mkdir` (`:258`) or a guessed `RUN`.

```
# docs/working/spike-cc-verify-q117.md:56-58
# noclobber: every `>` creates its file exclusively (O_EXCL), so a symlink planted at a
# predictable path cannot redirect a write (review security final F2).
set -o noclobber
```
Bash's noclobber refuses only an existing *regular* file. When the path resolves to an existing non-regular file, bash opens it without `O_EXCL` and writes through. Executed in the same test as 3a: a symlink `lfifo → fifo` accepted `echo SECRET > lfifo` (exit 0), and the reader on the FIFO received `SECRET`. A symlink to `/dev/null` also accepted the write (exit 0). Applied to this script: a `log.txt` symlink to a FIFO, planted in `run-<RUN>.d` before `:359` (`>"$LOG"`), would receive the `--register` output, or block the run until a reader opens the FIFO. The precise version: "`>` refuses an existing regular file and a dangling symlink; it still writes through a symlink to a FIFO or device."

**Evidence:** `docs/working/spike-cc-verify-q117.md:56-58`, `:359`, `:526`; `$W/logs/noclobber.out` (lines "symlink->fifo rc=0", "fifo reader got: SECRET", "symlink->/dev/null rc=0")

---

## Claim 3c: "`set -o noclobber` for every write | so no write follows a planted symlink"

**Location:** `docs/working/spike-cc-verify-q117.md:491` (step table, preflight row)
**Type:** Behavioral
**Verdict:** Incorrect
**Severity:** Medium (container-controlled output appended through a planted symlink is the redirect F2 was meant to close)
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the script's `>>` appends. Does not establish how wide the race window is in practice (between `:359` creating `log.txt` and `:373` re-opening it; between `:259` and `:296` for the run record).

noclobber does not apply to `>>`, and the script appends in four places:
```
# docs/working/spike-cc-verify-q117.md:296
printf 'T8=%s\n' "$T8" >> "$V/run-$RUN.env"
# :373
CLAUDE_DEVC_CONFIG_DIR="$S" "$LAUNCHER" --probe-only "$WS" </dev/null 2>&1 | relay >> "$LOG" \
```
(The snapshot appends at `:158-161`, `>> "$d/main"`, are the other two sites. They go into a directory created moments earlier by `mkdir "$d"` at `:152`.) Executed in the same test as 3a: `echo X >> reg`, with reg a symlink to a regular file, exited 0 and appended (`tgt=orig|X|`). If `log.txt` is replaced by a symlink to a regular file between `:359` and `:373`, step 7's launcher and container output, which branch code produces, is appended to that file. `relay`/`vis` strip control bytes but keep newlines. The doc's own row at `:26` scopes the claim correctly to "Every `>` write". This row's "every write" and "no write follows a planted symlink" do not hold.

**Evidence:** `docs/working/spike-cc-verify-q117.md:26`, `:152-161`, `:296`, `:359`, `:373`, `:491`; `$W/logs/noclobber.out` (line "append through symlink rc=0")

---

## Claim 4: "`MAIN_BIN="${CLAUDE_DEVC_BIN_DIR:-$HOME/.local/bin}"   # install.sh:1311`"

**Location:** `docs/working/spike-cc-verify-q117.md:65`
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the default and the variable name matching install.sh's. Does not establish that the preflight PATH check (`:245-246`), which still resolves `cc-isolated` from PATH, uses `MAIN_BIN`. It does not: `MAIN_BIN` is read only by the snapshot (`:161`).

```
# devcontainer-config/install.sh:1311 (at 2ea3498d)
  BIN_DIR="${CLAUDE_DEVC_BIN_DIR:-$HOME/.local/bin}"
```
The doc row at `:490` says the bin dir *checked* honours the variable. That holds for the bin-link snapshot line (`:161`, `readlink -f "$MAIN_BIN/$f"`).

**Evidence:** `devcontainer-config/install.sh:1310-1311`; `docs/working/spike-cc-verify-q117.md:65`, `:161`, `:245-246`, `:490`

---

## Claim 5: "This script's only `docker rm` targets label cc-project=<PID>, fresh at step 4" (containers)

**Location:** `docs/working/spike-cc-verify-q117.md:173-177`, `:474`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers container removal by this script (teardown) and by main's launcher (`--remove-existing-container` with `--id-label cc-project=$pid`). Does not cover image removals, which are Claim 9b. Does not cover a run that aborts after step 1 but before step 4's freshness check: there, teardown's `docker rm` runs on the `verify_pid(T8)` label before freshness was proven, though `compare` does not run because `SNAP=0`.

```
# docs/working/spike-cc-verify-q117.md:110-113
    for c in $(docker ps -aq --no-trunc --filter "label=cc-project=$pid" </dev/null); do
      img="$(docker inspect -f '{{.Image}}' "$c" </dev/null 2>/dev/null || true)"
      if [[ "$img" =~ ^sha256:[0-9a-f]{64}$ ]]; then imgs="$imgs $img"; fi
      docker rm -f "$c" >/dev/null </dev/null || { echo "TEARDOWN: could not remove container $c" >&2; fail=1; }
```
(excerpt ends :113; enclosing teardown() continues to :148 — read) `pid` is `verify_pid "$T8"` (`:109`), the same value as `PID` (`:346`). Step 4 refuses an existing labelled container (`:350`). The container-gone CHECK stays (`:182`).

**Evidence:** `docs/working/spike-cc-verify-q117.md:106-148`, `:346`, `:350`, `:173-177`; `devcontainer-config/cc-isolated.sh:835-836`, `:883`, `:895`

---

## Claim 6: "Only 0, 1, 130 and the verdict's own 2 are meaningful; any other status … becomes 1 with a named step" / "so a `2` only ever comes from the verdict"

**Location:** `docs/working/spike-cc-verify-q117.md:194-200` (code), `:480` (doc)
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers exits after the trap is installed: the verdict's 0/1/2, a die's 1, 130 from the INT/TERM/HUP trap, and a `set -e` failure with status 2. Does not establish a named step for a `set -e` failure with status 1 (`cp`, `mkdir`, `chmod`). That exits 1 with no `REFUSED:` line, which the doc's wording ("some other status") does not promise. Does not cover a child that itself exits 130, which is read as an interrupt.

```
# docs/working/spike-cc-verify-q117.md:196-200
  if [ "$rc" = 2 ] && [ "$NOROT" != 1 ]; then rc=99; fi
  case "$rc" in
    0|1|2|130) ;;
    *) printf 'REFUSED: unexpected failure during step "%s" (status %s).\n' "$STEP" "$orig" >&2; rc=1 ;;
  esac
```
(excerpt ends :200; enclosing on_exit() continues to :216 — read) `NOROT=1` is set only on the line that runs `exit 2` (`:422`). Executed, cwd `$W`:
- `./run.sh <checkout>` at 2026-10-15T09:45:21Z gave exit 0 (pass). With `FAKE_FAILS=3` it gave exit 1 and `RESULT Q-117 FAIL`. With `FAKE_POOL="142.250.1.1 "` it gave exit 2 and `RESULT Q-117 no-rotation`.
- `./run-path.sh $W/tarbin <checkout>`, with a tar that exits 2, at 09:46:35Z: exit 1, `REFUSED: unexpected failure during step "2. stage -> …/stage-65e65962" (status 2).`, then `== teardown` and `RESULT spike-q117 exit=1`.

`STEP` is the failing step's `say` text, because the `REFUSED` printf runs before `say "teardown"` overwrites it.

**Evidence:** `docs/working/spike-cc-verify-q117.md:94-95`, `:190-216`, `:418-424`, `:480`; `$W/logs/pass.out`, `$W/logs/fail.out`, `$W/logs/norot.out`, `$W/logs/tar2.out`

---

## Claim 7: step 8 uses "main's installed copy, which step 3 proved byte-identical, so a stage edit since the launcher's check_manifest cannot change what exec reads"; "the launcher's `dc` args (:834-836), except that the config path is main's installed copy"

**Location:** `docs/working/spike-cc-verify-q117.md:402-406` (code), `:507` (doc)
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers which devcontainer.json file `exec` is given, the identity proofs (step 3 `cmp`, plus the post-bless manifest check), and the line citation. Does not establish how the devcontainer CLI merges that file with the container's `devcontainer.metadata` label at exec, or whether `--id-label` alone selects the container whatever the config path. Neither can be run here (no real CLI; Not-verified #3 already lists it).

```
# docs/working/spike-cc-verify-q117.md:404-406
out="$(devcontainer exec --workspace-folder "$WS" --override-config "$MAIN_CFG/devcontainer.json" \
         --id-label "cc-project=$PID" bash -c "$Q117" </dev/null 2>&1 | relay)" \
  || die "devcontainer exec of the Q-117 block failed."
```
Step 3 refuses unless `cmp -s "$MAIN_CFG/$i" "$S/$i"` for both pinned files (`:329`), and step 6 re-checks the blessed hashes against main's copies (`:365-369`). The launcher's args at 2ea3498d, quoted:
```
# devcontainer-config/cc-isolated.sh:834-836
  local dc=(--workspace-folder "$ws"
            --override-config "$(config_dir)/devcontainer.json"
            --id-label "cc-project=$pid")
```
Every path in devcontainer.json comes from `${localEnv:…}` (devcontainer.json:22-28, :78-79), so the file's location does not change what it resolves to. `CC_CONFIG_DIR` is still exported as the stage (`:401`), but only the build reads it, and exec does not build. The fake devcontainer ignores `--override-config`, so the harness passes are not evidence for this claim.

**Evidence:** `docs/working/spike-cc-verify-q117.md:329`, `:365-369`, `:401-406`, `:507`; `devcontainer-config/cc-isolated.sh:815-820`, `:834-836`; `devcontainer-config/devcontainer.json:22-28`, `:71`, `:78-79`

---

## Claim 8: "re-paste the same block with `--clean` in place of the checkout path … The next run refuses to start until you have."

**Location:** `docs/working/spike-cc-verify-q117.md:429`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a `kill -9` during step 8, the refusal that follows, and `--clean` removing that run's leftovers (it leaves `run-<RUN>.d/log.txt` by design). Does not establish `--clean` with real docker image semantics: the fake's `image rm` matches by id only.

Executed, cwd `$W`, 2026-10-15T09:47:43Z: `FAKE_HANG=60 timeout 120 ./run-path.sh /nonexistent <checkout>`, then `kill -9` of the bash PID and of its descendants by PID. Exit 137. Left behind: `VERIFY-65e65962`, `run-…-1038284.env`, `src-….git`, `stage-65e65962`, `run-….d/{log.txt,snap-before}`, plus the fake container, both volumes and the image. The next `./run.sh <checkout>` exited 1 with `REFUSED: a previous run left state (…run-1792057663-1038284.env). First re-paste the block from docs/working/spike-cc-verify-q117.md with --clean as its last argument.` Then `./run.sh --clean` exited 0 with `cleaning run 1792057663-1038284 (tree 65e65962, project ddf6ebf1233e)`. Only `log.txt` remained in the run directory, and only the harness's container, volume and image remained in the fake state.

**Evidence:** `docs/working/spike-cc-verify-q117.md:219-234`, `:254`, `:429`; `$W/logs/crash.out`, `$W/logs/after-crash.out`, `$W/logs/clean.out`

---

## Claim 9a: "Ctrl-C acts at once. A `kill` of the script itself waits for the running step to return, up to the 45-minute wait in step 8 (bash runs a trap only between commands)."

**Location:** `docs/working/spike-cc-verify-q117.md:479`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the fake step-8 exec: SIGINT to the process group, and SIGTERM to the script's PID alone. Does not establish that the real devcontainer CLI or docker exec dies on SIGINT the way the fake's `sleep` does.

Executed, cwd `$W`:
- 2026-10-15T09:47:12Z: `FAKE_HANG=20 timeout 120 ./run-path.sh /nonexistent <checkout>`, with `kill -TERM <bash pid>` once `== 8` appeared. Exit 130 after 19 s (the remainder of the 20 s hang). Every CHECK was ok, then `RESULT spike-q117 exit=130`.
- 09:50:20Z: the same command under `setsid` with `FAKE_HANG=40`, and `kill -INT -- -<pgid>`. Exit 130 after 0 s, with full teardown.

**Evidence:** `docs/working/spike-cc-verify-q117.md:261`, `:479`; `$W/logs/term.out`, `$W/logs/int.out`

---

## Claim 9b: "Containers and image tags also change when another session's launcher recreates its container … so a disappearance is reported, not failed. This script's only `docker rm` targets label cc-project=<PID>" (image tags); NOTE text "a vsc-verify-* one would refute the research §7 image-naming claim"; doc "this script's only `docker rm` targets its own fresh label. A `vsc-verify-*` tag among them would refute the image-naming claim."

**Location:** `docs/working/spike-cc-verify-q117.md:173-175`, `:179` (code); `:474`, `:530` (doc)
**Type:** Behavioral / Invariant
**Verdict:** Incorrect
**Severity:** Medium (a refutation of the unverified naming claim that used to fail the run now exits 0, and the script itself deletes the moved tag)
**Confidence:** High for the mechanism; Low that the real CLI ever retags
**Verification mode:** executed
**Scope:** Covers the image-tag half of the downgrade: the build moves a pre-existing tag that is not `vsc-verify-*` onto this run's new image. Does not establish that the real devcontainer CLI does this. That is exactly the unverified research §7 claim.

The reasoning, "this script's only removal is label-scoped, so a vanished tag is another session's", does not cover the script's id-based image removal:
```
# docs/working/spike-cc-verify-q117.md:124-129
    for img in $imgs; do
      if [ ! -f "$before" ]; then echo "TEARDOWN: kept image $img (no before-snapshot proves it new; remove it by hand if it is the verify build)" >&2; continue; fi
      if grep -q " $img\$" "$before"; then continue; fi
      if [ -n "$(docker ps -aq --filter "ancestor=$img" </dev/null)" ]; then echo "TEARDOWN: image $img still in use; not removed" >&2; continue; fi
      docker image rm -f "$img" >/dev/null </dev/null || { echo "TEARDOWN: could not remove image $img" >&2; fail=1; }
    done
```
(excerpt ends :129; enclosing teardown() continues to :148 — read) `docker image rm -f <id>` drops every tag on that id. Executed, cwd `$W`, 2026-10-15T09:49:36Z: `FAKE_RETAG=vsc-claude-workflows-xyz:latest timeout 300 ./run.sh <checkout>`, exit 0. The fake build moved the harness's pre-existing tag onto the verify image. Teardown then removed that image, tag included, and the run printed only:
```
NOTE pre-existing image tags moved or gone (another session's rebuild; a vsc-verify-* one would refute the research §7 image-naming claim):
  vsc-claude-workflows-xyz:latest sha256:aaa94026…
RESULT spike-q117 exit=0
```
At 53770142 the same event failed `CHECK no pre-existing image tag moved or removed`, and the old Not-verified #1 said: "If the CLI *retags* an image that existed before, `CHECK … ` fails. That would be the claim refuted." In this case the moved tag's name is not `vsc-verify-*`, the NOTE blames another session, and the tag is gone after teardown. (In real docker the old image would remain as `<none>`; the fake does not model that.) The precise version: "a NOTE line naming a tag that is not `vsc-verify-*` can also be this run's build retagging a pre-existing image, which teardown then untags with `-f`".

**Evidence:** `docs/working/spike-cc-verify-q117.md:124-129`, `:170-179`, `:474`, `:530`; `$W/t1/bin/devcontainer` (FAKE_RETAG line), `$W/logs/retag.out`; 53770142 doc text for Not-verified #1 (diff hunk at `@@ -521`)

---

## Claim 10: "Another session's launcher recreates its container when its blessed config changed and on every `--probe-only` (cc-isolated.sh:883, :895)"

**Location:** `docs/working/spike-cc-verify-q117.md:474` (also code comment `:173-174`)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two line citations and both triggers. Does not establish that recreating a container moves its image tag. That is CLI behaviour, not observed.

```
# devcontainer-config/cc-isolated.sh:883 (probe action)
    devcontainer up --remove-existing-container "${dc[@]}"
# devcontainer-config/cc-isolated.sh:893-895 (config changed)
  if ! container_config_matches "${dc[@]}"; then
    echo "Blessed config changed since this container was built — rebuilding it."
    devcontainer up --remove-existing-container "${dc[@]}"
```
The doc lists the triggers in the opposite order to the line numbers. Both are correct.

**Evidence:** `devcontainer-config/cc-isolated.sh:878-896`

---

## Claim 11: "The paste block itself was executed under bash and `zsh -f` against the fake HOME, and gave the same pass."

**Location:** `docs/working/spike-cc-verify-q117.md:526`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the block exactly as in the doc (last line `~/claude-workflows`, which resolves in the fake HOME). Does not cover a user's zsh with its own rc options, or a non-UTF-8 locale under zle (Claim 1).

Reproduced as part of Claim 1: bash, `bash -i`, `zsh -f` and `zsh -f -i` on stdin, plus pty-driven `zsh -f -i` and `bash --norc -i`. All exited 0 with `RESULT Q-117 pass` and `RESULT spike-q117 exit=0`, 2026-10-15T09:48:07-09:48:29Z, cwd `$W`.

**Evidence:** `$W/logs/paste-*.out`, `$W/logs/pty-*.out`

---

## Claim 12: Not-verified #1: "The trap removes the image the verify container ran, if the before-snapshot proves it new and no other container uses it. It also untags, by name and without `-f`, any `vsc-verify-<TREE8>-…` tag whose id is new since the snapshot."

**Location:** `docs/working/spike-cc-verify-q117.md:530`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two removal rules. Does not cover the paragraph's last sentence (Claim 9b), or the detail that the case pattern also matches `vsc-verify-<T8>:<tag>` with no dash (harmless).

```
# docs/working/spike-cc-verify-q117.md:136-138
        case "$tags" in vsc-verify-"$T8"-*|vsc-verify-"$T8":*) ;; *) continue ;; esac
        if grep -q " $i\$" "$before"; then continue; fi
        docker image rm "$tags" >/dev/null </dev/null || { echo "TEARDOWN: could not untag $tags" >&2; fail=1; }
```
(excerpt ends :138; enclosing teardown() continues to :148 — read) The container-image rule is quoted in Claim 9b (`:124-129`).

**Evidence:** `docs/working/spike-cc-verify-q117.md:120-140`

---

## Claim 13: Not-verified #12: "The build arguments the launcher passes, including `TZ` (Dockerfile:16-17), must match main's … Teardown removes the verify images but not BuildKit's build cache … (pruning is global, so the script does not)."

**Location:** `docs/working/spike-cc-verify-q117.md:541`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the Dockerfile citation and the absence of any prune. Does not establish the cache-hit sizes ("a few MB", "multi-GB"), which need the host run. Also does not cover the source of TZ: devcontainer.json's `${localEnv:TZ:America/Los_Angeles}`, which is the user's shell value rather than something the launcher chooses.

```
# devcontainer-config/Dockerfile:16-17
ARG TZ
ENV TZ="$TZ"
```
The script contains no `prune` (paraphrased — no quote available because the claim covers absence of code: `grep -n prune` over `spike-q117.v3.sh` returns nothing).

**Evidence:** `devcontainer-config/Dockerfile:14-17`; `devcontainer-config/devcontainer.json:28`; `docs/working/spike-cc-verify-q117.md:541`

---

## Claim 14: residual: "A planted run record together with a planted before-snapshot … can make `--clean` untag an image named `vsc-verify-<8 hex>-…`, and nothing else: it cannot reach other projects' containers or volumes, or other image names"

**Location:** `docs/working/spike-cc-verify-q117.md:550`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers what `--clean`'s teardown can reach from a planted `run-<RUN>.env` and `run-<RUN>.d/snap-before`. Does not establish that the residue below occurs, since it needs a live `VERIFY-<T8>` container.

Teardown also removes, with `-f` and by id, the image of any container labelled `verify_pid(T8)` whose id the planted snapshot omits (`:124-129`, quoted in Claim 9b). Through that path, if a `VERIFY-<T8>` container from another verify run is alive, the image it ran loses every tag, whatever the names. The tighter statement: "only `VERIFY-<8 hex>` projects' containers, volumes and images, and `vsc-verify-<8 hex>` tags". Other projects stay unreachable, as claimed.

**Evidence:** `docs/working/spike-cc-verify-q117.md:106-140`, `:219-234`, `:550`

---

## Claim 15: "exit codes should follow decision log row 58 (2 = bad usage, tool codes above 2, interrupt → 1)"

**Location:** `docs/working/spike-cc-verify-q117.md:558`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the summary of row 58 and API F2. Does not take a position on what the tool should choose.

Row 58, quoted: "0 success; 1 an error *or* a prompt the user declined (`n`, or Ctrl-C at the prompt); 2 bad usage … `cc-isolated` keeps two codes of its own on top: 3 … 4" (`docs/decisions/log.md:81`). Row 58 maps only Ctrl-C *at a prompt* to 1. API F2 leaves the interrupt code open: "must decide 130 versus 1 against row 58" (`docs/reviews/api-consistency-review-2026-10-15-cc-verify-spike.md:94`). The precise version: "interrupt: decide 130 vs 1 against row 58".

**Evidence:** `docs/decisions/log.md:81`; `docs/reviews/api-consistency-review-2026-10-15-cc-verify-spike.md:74-94`

---

## Claim 16: "These are in `docs/reviews/api-consistency-review-2026-10-15-cc-verify-spike.md` (F2-F6, F9)"

**Location:** `docs/working/spike-cc-verify-q117.md:565`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the file exists and that its F2-F6 and F9 headings match the six bullets. Does not judge whether F4 and F6, partly fixed in this commit, should still be listed. Each bullet names the part that remains (both variables plus an override; one line grammar).

The headings in the file: `#### F2. The exit-code set reuses row 58's …` (:74), `F3. No --help` (:96), `F4. Env overrides` (:110), `F5. Message prefixes` (:130), `F6. Verdict casing … a second shape` (:146), `F9. Files under ~/cc-verify have no override` (:191).

**Evidence:** `docs/reviews/api-consistency-review-2026-10-15-cc-verify-spike.md:74`, `:96`, `:110`, `:130`, `:146`, `:191`

---

## Claim 17: "- `130`: interrupted (Ctrl-C, TERM, HUP). The trap still tears down."

**Location:** `docs/working/spike-cc-verify-q117.md:479`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers what `set -e` does inside `on_exit` when a write fails. Does not establish, by execution, that a write to a hung-up controlling tty returns an error. That is standard tty behaviour (EIO), but it was not run here.

`errexit` stays on inside the EXIT trap. `teardown` and `compare` run in `||` lists, so errexit is suppressed inside them. The bare commands in `on_exit` (`printf 'REFUSED…' >&2`, `say "teardown"`, `echo "TEARDOWN INCOMPLETE…"`, `rm -rf … snap-before`) abort the trap if they fail:
```
# docs/working/spike-cc-verify-q117.md:201-203
  if [ -n "$RUN" ]; then
    say "teardown"
    teardown || trc=1
```
(excerpt ends :203; enclosing on_exit() continues to :216 — read) Executed: `bash -c 'set -euo pipefail; on_exit(){ …; printf "== teardown\n"; echo "TEARDOWN-RAN rc=$rc" >&2; }; trap on_exit EXIT; exit 130' >/dev/full`, cwd `$W`, ≈09:46Z, outer exit 1. Stderr held only `printf: write error: No space left on device`, and `TEARDOWN-RAN` never printed. So a HUP caused by closing the terminal can end the trap at `say "teardown"`, with no teardown and no RESULT line. The doc's `:429` already routes "a closed terminal" to `--clean`, so the guidance is safe. The 130 line needs the qualifier "if the terminal is still open".

**Evidence:** `docs/working/spike-cc-verify-q117.md:190-216`, `:429`, `:479`; `$W/logs/seterr.out`

---

## Claim 18: commit 2ea3498d: "F2: the log and snapshots live in run-<RUN>.d (plain mkdir), and every write uses set -o noclobber, so planted symlinks fail the write instead of redirecting it."

**Location:** commit `2ea3498d` message, bullet "F2"
**Type:** Behavioral
**Verdict:** Incorrect
**Severity:** Low as text (commit messages are immutable; the fix belongs in the doc rows of Claims 3b and 3c), Medium as the defect it describes
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the "every write" and "planted symlinks fail" parts. The "run-<RUN>.d (plain mkdir)" part is Verified (Claim 2).

`>>` appends (`:158-161`, `:296`, `:373`) are not under noclobber and follow symlinks (Claim 3c). `>` writes through a symlink to a FIFO or device (Claim 3b). The commit's own test note, "noclobber against dangling and live symlinks", matches 3a's live-to-regular case only.

**Evidence:** commit `2ea3498d`; `$W/logs/noclobber.out`; `docs/working/spike-cc-verify-q117.md:158-161`, `:296`, `:373`

---

## Claim 19: commit 2ea3498d: "API F1: any exit status other than 0/1/130 or the verdict's own 2 is reported as an unexpected failure naming the step, and becomes 1."

**Location:** commit `2ea3498d` message, bullet "API F1"
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claim 6 (whose executed runs this rests on). It does not cover a `set -e` failure with status 1, which gets no named step.

See Claim 6: tar exit 2 gave `REFUSED: unexpected failure during step "2. stage -> …" (status 2)` and exit 1, at 2026-10-15T09:46:35Z.

**Evidence:** `$W/logs/tar2.out`; `docs/working/spike-cc-verify-q117.md:194-200`

---

## Claim 20: commit 2ea3498d: "Performance F1: pre-existing containers or image tags that disappear (other sessions' rebuilds) are NOTEs, not failed CHECKs."

**Location:** commit `2ea3498d` message, bullet "Performance F1"
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the change as described, CHECK to NOTE. The parenthetical attribution to other sessions is not always right for image tags (Claim 9b).

`$W/logs/retag.out` (09:49:36Z, exit 0) shows a vanished pre-existing tag reported as `NOTE …` with no CHECK line for it. The volume CHECK remains: `CHECK no pre-existing volume removed: ok`.

**Evidence:** `docs/working/spike-cc-verify-q117.md:170-179`; `$W/logs/retag.out`

---

## Claim 21: commit 2ea3498d: "F4: step 8's exec reads main's installed devcontainer.json (proven identical in step 3)."

**Location:** commit `2ea3498d` message, bullet "F4"
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Same as Claim 7.

`--override-config "$MAIN_CFG/devcontainer.json"` (`:404`), `cmp -s "$MAIN_CFG/$i" "$S/$i"` (`:329`).

**Evidence:** `docs/working/spike-cc-verify-q117.md:329`, `:404`

---

## Claim 22: commit 2ea3498d: "F3: grep -q for initializeCommand." / doc "refuses (with `grep -q`, so no staged line reaches the terminal)"

**Location:** commit `2ea3498d` message, bullet "F3"; `docs/working/spike-cc-verify-q117.md:325`, `:500`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the initializeCommand check. Does not cover the `diff -u` that follows it, which shows staged lines on purpose, through `vis` (`:330`).

```
# docs/working/spike-cc-verify-q117.md:325-326
if grep -q 'initializeCommand' "$S/devcontainer.json"; then
  die "the staged devcontainer.json names initializeCommand, which runs ON THE HOST."
```

**Evidence:** `docs/working/spike-cc-verify-q117.md:325-333`

---

## Claim 23: commit 2ea3498d: "API F6: the verdict FAIL is upper-case."

**Location:** commit `2ea3498d` message, bullet "API F6"; `docs/working/spike-cc-verify-q117.md:412-416`, `:519`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the RESULT verdict token. Does not cover the second line shape `RESULT spike-q117 exit=<n>`, which is unchanged (API F6's other half, carried into "Toward the cc-verify tool").

`$W/logs/fail.out` (09:45:21Z batch, exit 1): `RESULT Q-117 FAIL (tree 65e65962…, config a1f292d5cb3f3bfd)`.

**Evidence:** `docs/working/spike-cc-verify-q117.md:412-424`; `$W/logs/fail.out`

---

## Claim 24: commit 2ea3498d: "Re-tested in the stub harness: … FAIL and no-rotation paths; tar exiting 2 → exit 1 with a named step; … crash, then the pasted --clean, removing exactly the run's leftovers. shellcheck is clean."

**Location:** commit `2ea3498d` message, "Notes" block
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the listed outcomes, reproduced in my own copy. The "noclobber against dangling and live symlinks" item is verdicted in Claim 18, and "planted record + planted snapshot" was not re-run here (its residual is Claim 14).

The FAIL and no-rotation runs are in Claim 6, and the crash plus `--clean` in Claim 8. `shellcheck -S warning spike-q117.v3.sh` and `bash -n spike-q117.v3.sh` both exited 0, cwd `$W`, 2026-10-15T09:50:51Z.

**Evidence:** `$W/logs/shellcheck.out`, `$W/logs/bash-n.out`, `$W/logs/fail.out`, `$W/logs/norot.out`, `$W/logs/tar2.out`, `$W/logs/clean.out`

---

## Answers to the brief's specific checks

- **noclobber and the launcher:** it does not propagate. A child `bash -c` under a noclobber parent reported `child SHELLOPTS=braceexpand:hashall:interactive-comments`, `child-noclobber-off`, and the parent exports no `SHELLOPTS` (`$W/logs/noclobber.out`). Every `>` in the script targets a path inside a freshly made directory, or a new file. The pass, FAIL, no-rotation, TERM and INT runs hit no clobber errors. The gaps are `>>` (Claim 3c) and non-regular targets (Claim 3b). Here-strings (`<<<`) and `$(…)` are unaffected.
- **Paste wrapper:** works in bash, bash -i, zsh -f and zsh -f -i, on stdin and through a pty (Claim 1). The `case … )` patterns, `$`, quotes and backslashes in the body survive byte for byte. No stale `bash ~/cc-verify/spike-q117.sh` text remains in the branch outside `docs/reviews`.
- **Exit-code mapping:** verdict 2, 130, a die's 1 and an unexpected 2 all map as claimed. `STEP` names the failing step. `set -e` stays active in `on_exit` (Claim 17).
- **run-<RUN>.d:** created before the trap. `--clean` still globs only `run-*.env`. Pass, FAIL and `--clean` leave only `log.txt`, and an incomplete teardown leaves `snap-before` (Claim 8).
- **Step 8:** static only; the CLI's exec semantics are unverifiable here (Claim 7). The stage path is still needed as `CC_CONFIG_DIR` for the build, not for exec.
- **compare():** containers are fine (Claim 5). For image tags, a refuting retag is now silent: exit 0 with a NOTE, and the script's `image rm -f` deletes the moved tag (Claim 9b).

## Claims Requiring Attention

### Incorrect
- **Claim 3b** (`docs/working/spike-cc-verify-q117.md:56-57`, `:526`): noclobber is not O_EXCL on existing non-regular targets, and a symlink to a FIFO or device is written through. Say "refuses an existing regular file or dangling symlink".
- **Claim 3c** (`docs/working/spike-cc-verify-q117.md:491`): "set -o noclobber for every write … no write follows a planted symlink" is false for the `>>` appends at `:158-161`, `:296` and `:373`. The `relay >> "$LOG"` append can follow a symlink planted between `:359` and `:373`.
- **Claim 9b** (`docs/working/spike-cc-verify-q117.md:173-179`, `:474`, `:530`): a pre-existing tag moved onto this run's image by the build (the retag that refutes research §7) now gives exit 0 and a NOTE blaming another session, and teardown's `docker image rm -f <id>` deletes it. The "only `docker rm` is label-scoped" reasoning does not cover image removal.
- **Claim 18** (commit 2ea3498d, F2 bullet): "every write uses set -o noclobber, so planted symlinks fail the write". Same defect as 3b and 3c. The commit is immutable, so correct it in the doc and record it in the override log.

### Mostly Accurate
- **Claim 14** (`docs/working/spike-cc-verify-q117.md:550`): "and nothing else" leaves out that a live `VERIFY-<T8>` container's image can be removed by id with `-f`, all tags included.
- **Claim 15** (`docs/working/spike-cc-verify-q117.md:558`): row 58 maps only Ctrl-C at a prompt to 1, and API F2 leaves 130 vs 1 open.
- **Claim 17** (`docs/working/spike-cc-verify-q117.md:479`): "The trap still tears down" for HUP needs "if the terminal is still open". `set -e` aborts `on_exit` on a failed write.

### Unverifiable
- (none as verdicts; Claim 7's residue, the CLI's exec merge and container selection under `--override-config` of main's path, needs the host run, as Not-verified #3 already says)

## Goal-Alignment Note

Success criterion, verbatim: "a markdown report saved to the path named at the end of this prompt, structured per your role's skill, with `Commit: 2ea3498d` as its first line." This report is saved at `/workspace/.claude/wt-branch-verify/docs/reviews/code-fact-check-report-cc-verify-spike-acap.md`. It opens with `**Commit:** 2ea3498d` and follows `skills/code-fact-check/SKILL.md`'s structure. The user goal is "a reviewed, safe one-paste host spike that live-verifies a branch without installing it". Against it, the range's main fix holds under execution: the script is never on disk, and the fallback is a re-paste. The exit-code mapping, upper-case FAIL, BIN_DIR, `grep -q` and the run directory also hold. A-cap should not close clean. Two of the range's own claims are wrong in ways that touch "safe": noclobber does not cover the `>>` log append (3c), and the image-tag CHECK became a NOTE that hides a refuting retag (9b). Choosing the fixes is left to the sibling critics and the author.
