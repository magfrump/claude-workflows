Commit: 61d801c

# Code Fact-Check Report

**Repository:** /workspace (branch `feat/q076-git-exit-scan` @ 61d801c)
**Scope:** branch diff `origin/main...61d801c` — devcontainer-config/cc-push.sh, devcontainer-config/cc-isolated.sh, devcontainer-config/install.sh, hooks/live-verify-gate.sh, guides/cc-isolated-usage.md, test/{cc-push,cc-isolated-functions,install-host}.bats; plus commit messages (`git log origin/main..61d801c`).
**Checked:** 2026-09-27
**Total claims checked:** 20
**Summary:** 14 verified, 2 mostly accurate, 0 stale, 2 incorrect, 2 unverifiable

Method: read at 61d801c in a scratch clone (`git clone -q /workspace $D && git -C $D checkout -q 61d801c`). Executed claims ran in the scratch clone; logs under `/tmp/claude-1000/-workspace/dbfd30e0-d8d5-40c1-8bac-572239fc44fd/scratchpad/q076rev-r1/`. This is defensive verification of a security tool; I attempted to defeat the two central guarantees per the brief. Two attempts succeeded and are the headline findings (Claim 1, Claim 9); they share one root cause — git's repository-discovery fallback when `.git` is made invalid.

No `docs/reviews/hallucination-patterns.md` exists at this commit; none of the findings below is a fabricated-symbol pattern (they are missing-coverage gaps, not invented APIs), so nothing is appended there.

---

## Claim 1: cc-push "refuses a checkout whose .git ... holds ... objects/info/alternates ... Otherwise upload-pack could fetch history from another repository you can read and cc-push would offer it for push."

**Location:** `devcontainer-config/cc-push.sh:45-54` (header), enforced at `devcontainer-config/cc-push.sh:122-159` (`check_checkout`), fetch at `devcontainer-config/cc-push.sh:233-236`
**Type:** Error-handling / Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the reachability of another host repo's history through an alternates file placed at the checkout root when `.git` is invalidated; does not establish that the in-`.git` alternates refusal (which works) can be bypassed, nor that any *hook* runs (none does — this is a read/exfiltration bypass, not code execution).

`check_checkout` inspects only paths under `$co/.git`:

```bash
# devcontainer-config/cc-push.sh:123-138
check_checkout() {
  local co="$1" g="$1/.git" f odd
  ...
  for f in objects/info/alternates objects/info/http-alternates; do
    if [ -e "$g/$f" ] || [ -L "$g/$f" ]; then
      die "$g/$f exists: ..."
```

The fetch targets the checkout directory, not `$co/.git`:

```bash
# devcontainer-config/cc-push.sh:233-234
if ! run_vis hgit "$clone" -c protocol.file.allow=always fetch -q --no-tags --no-recurse-submodules \
       --no-write-fetch-head --prune "$co" '+refs/heads/*:refs/cc/heads/*' >&2; then
```

Git resolves the repo at `$co` via `enter_repo`, which tries `$co/.git` and then `$co` itself. A session (which owns the bind-mounted checkout, `.git` included) can remove `$co/.git/HEAD` (invalidating `.git`) and lay the checkout *root* out as a bare repo whose `objects/info/alternates` names another host repository — none of that is under `$co/.git`, so `check_checkout` passes. upload-pack then serves the other repo's objects, and cc-push previews and pushes them. Executed probe (planted a second repo with a private commit, invalidated `.git`, placed alternates + a hand-written ref at the checkout root): cc-push printed `Created the host-only clone ...`, `OTHER-REPO-PRIVATE`, and `Pushed main to origin`; the other repo's private commit landed on origin.

- command: `TMPDIR=$PWD/probes probes/p1-enter-repo-fallback.sh $PWD/clone/devcontainer-config/cc-push.sh`
- cwd: `/tmp/claude-1000/-workspace/dbfd30e0-d8d5-40c1-8bac-572239fc44fd/scratchpad/q076rev-r1`
- exit code of probe: 0 (cc-push itself exited 0); result line `RESULT: OTHER REPO'S PRIVATE COMMIT PUSHED`
- timestamp: 2026-09-28T01:50:43Z
- git version: 2.39.5

The guarantee as written — that a checkout able to make upload-pack read another repository is refused — does not hold for the enter_repo fallback path. `check_checkout` guards `.git`; it does not guard the case where git ignores `.git` and treats the checkout root (or an ancestor) as the repository. A reader relying on "cc-push cannot exfiltrate another repo's history" is misled.

**Evidence:** `devcontainer-config/cc-push.sh:122-159`, `devcontainer-config/cc-push.sh:233-236`; probe log `/tmp/claude-1000/-workspace/dbfd30e0-d8d5-40c1-8bac-572239fc44fd/scratchpad/q076rev-r1/probes/p1.log`

---

## Claim 2: cc-push "runs no git command in the checkout: it keeps a BARE clone that only the host writes ... `git fetch <checkout>` — for a local path git starts upload-pack in the checkout's .git. upload-pack READS there ... It runs no hook, no fsmonitor, no filter, and ignores uploadpack.packObjectsHook from repo config."

**Location:** `devcontainer-config/cc-push.sh:30-40`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that no hook/fsmonitor/filter/packObjectsHook fires when cc-push fetches from a normal checkout with those planted (git 2.39); does not establish confinement of upload-pack's *reads* (see Claim 1 for the alternates-at-root read bypass), and does not cover git versions other than 2.39.
**route:** code-fact-check

`test/cc-push.bats` (24 cases) plants every `githooks(5)` hook name, a husky-style `core.hooksPath`, fsmonitor, clean/smudge/process filters, receive-pack/upload-pack commands, `uploadpack.packObjectsHook`, `core.alternateRefsCommand`, `core.sshCommand`, `core.gitProxy`, `core.askPass`, a credential helper, `diff.external`, include/includeIf, a legacy remotes file, and a repointed origin, and asserts that a marker fires for none while a plain `git status` in the checkout does fire it, and that the fetched commit still pushes (paraphrased — no quote available because the plant set spans ~120 lines of the fixture `plant_all`). Executed: `env -u LC_ALL LANG=C.UTF-8 bats test/cc-push.bats` → 24/24 ok.

- command: `bats test/cc-push.bats`; cwd: scratch clone; exit 0; 2026-09-28T01:40:26Z
- log: `/tmp/claude-1000/-workspace/dbfd30e0-d8d5-40c1-8bac-572239fc44fd/scratchpad/q076rev-r1/bats-cc-push.log`

The narrow claim (no hook/fsmonitor/filter executes; `ngit` at `:97-99` passes `core.hooksPath=/dev/null core.fsmonitor=false`) holds. Note the header itself already scopes "runs no git *command* in the checkout" as distinct from upload-pack reads — that distinction is accurate.

**Evidence:** `devcontainer-config/cc-push.sh:96-99`, `test/cc-push.bats` (plant_all fixture + assertions); log `bats-cc-push.log`

---

## Claim 3: cc-push refusal set — ".git ... a `gitdir:` file or a symlink ... a commondir, objects/info/alternates or objects/info/http-alternates file ... a symlink outside hooks/, a FIFO, socket or device ... a config / config.worktree with an [include] or [includeIf] section."

**Location:** `devcontainer-config/cc-push.sh:45-54`, enforced `devcontainer-config/cc-push.sh:125-158`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that each named `.git` shape is refused (die, exit 1) as documented; does not establish coverage of the checkout-root fallback (Claim 1), and "symlink outside hooks/" is enforced via `find -P ... -path "$g/hooks" -prune` so a symlink *inside* hooks/ is deliberately allowed (also documented).
**route:** code-fact-check

Each listed shape maps to a guard: symlink `.git` (`:125-127`), non-directory `.git` (`:128-130`), `commondir` (`:131-133`), `objects/info/alternates`+`http-alternates` (`:134-138`), symlink/FIFO/socket/device outside hooks (`:142-148`), `[include]`/`[includeIf]` in config/config.worktree via `grep -Eiq '\[[[:space:]]*include'` (`:153-158`). `test/cc-push.bats` cases E2c, symlinked `.git`, P2a alternates, http-alternates+commondir, symlinked object store, symlinked-hook-allowed, E2b include FIFO, uppercase `[ Include ]`/config.worktree, FIFO packed-refs, newline-forge — all pass (part of the 24/24 run above).

**Evidence:** `devcontainer-config/cc-push.sh:125-158`; log `bats-cc-push.log`

---

## Claim 4: cc-push exit codes — "0 pushed (or nothing to push); 1 error ... (git's own exit status is never passed through); 2 declined at the prompt", and "main runs in a subshell ... so 128 never leaks."

**Location:** `devcontainer-config/cc-push.sh:20-22`, `devcontainer-config/cc-push.sh:296-307`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the 0/1/2 mapping and the 128→1 remap through the outer `case`; does not establish behavior under signals other than the tested decline path.
**route:** code-fact-check

```bash
# devcontainer-config/cc-push.sh:299-306
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  set +e
  ( set -e; main "$@" )
  rc=$?
  case "$rc" in
    0|1|2) exit "$rc" ;;
    *) echo "ERROR: cc-push stopped on an unexpected failure (status $rc)." >&2; exit 1 ;;
```

`test/cc-push.bats` "E5: a git fatal (unwritable clone parent) exits 1, never git's 128", "unrelated history ... rejected push exits 1, not 128", decline path exit 2 — all pass. `die()` exits 1 (`:91-94`); decline exits 2 (`:284`).

**Evidence:** `devcontainer-config/cc-push.sh:91-94,284,299-306`; log `bats-cc-push.log`

---

## Claim 5: cc-push sanitizing — "EVERY STRING FROM THE CHECKOUT ... is printed through vis: anything but printable ASCII shows as '?'" (byte-wise LC_ALL=C; C0/C1, bidi overrides neutralised).

**Location:** `devcontainer-config/cc-push.sh:56-57`, `devcontainer-config/cc-push.sh:77-89`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that branch names, commit text and git/remote messages routed through `say`/`run_vis` are byte-filtered to printable ASCII+newline; does not establish that the interactive prompt string `Push these? [y/N] ` (printed with a bare `printf` at `:280`) carries container data — it does not, so that bare printf is not a gap.
**route:** code-fact-check

`vis()` is `LC_ALL=C tr -c '[:print:]\n' '?'` (`:82-84`); previews use `run_vis`/`say` (`:267,270,274,291,293`). "EVERY STRING" is very slightly over-broad: `printf 'Push these? [y/N] '` at `:280` and the `read` reply are not passed through vis, but neither contains checkout-controlled bytes, so nothing container-chosen escapes. `test/cc-push.bats` E4 (U+009B, raw 0x9b, U+202E in a branch name; a remote rejection echoing the ref) pass — none of those bytes reach the terminal. Precise statement: every *container-controlled* string is vis-filtered.

**Evidence:** `devcontainer-config/cc-push.sh:82-84,267-293`; log `bats-cc-push.log`

---

## Claim 6: cc-push "--branch NAME the branch to push (default: the one the checkout's HEAD names)" via `ls-remote --symref`, refusing detached HEAD.

**Location:** `devcontainer-config/cc-push.sh:238-248`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers HEAD-symref resolution and the detached-HEAD die; does not establish behavior for a branch name that is valid to git but rejected by `check-ref-format`.
**route:** code-fact-check

```bash
# devcontainer-config/cc-push.sh:241-243
sym="$(hgit "$clone" -c protocol.file.allow=always ls-remote --symref "$co" HEAD 2>/dev/null | LC_ALL=C sed -n 's/^ref: refs\/heads\/\(.*\)\tHEAD$/\1/p')" || true
[ -n "$sym" ] || die "the checkout's HEAD names no branch (detached?); pass --branch <name>"
```

`LC_ALL=C` on the sed matches the header's E4 note ("a non-UTF-8 branch name reads as detached" without it). `check-ref-format` validates before use (`:245`). Bats `--branch` case passes.

**Evidence:** `devcontainer-config/cc-push.sh:238-248`

---

## Claim 7: cc-push preview uses "--no-ext-diff/--no-textconv ... --no-show-signature", and "It never forces."

**Location:** `devcontainer-config/cc-push.sh:254-292`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the diff/log/push flags on the preview and push; does not establish that a global `pager.*` or textconv in the *host* global config is neutralised for the diff (it is `--no-pager` + `--no-textconv` + `--no-ext-diff`, which covers it).
**route:** code-fact-check

`--no-pager log --no-show-signature` (`:267,274`); `diff --no-ext-diff --no-textconv --stat` (`:270`); push is `"$src:refs/heads/$branch"` with no `+`/`--force` (`:291`). Bats "no force" and "unrelated history" cover this.

**Evidence:** `devcontainer-config/cc-push.sh:267,270,274,291`

---

## Claim 8: cc-push clone default — "$CC_PUSH_CLONES_DIR/<name>-<id>, CC_PUSH_CLONES_DIR defaulting to $XDG_DATA_HOME/cc-isolated/clones, or ~/.local/share/cc-isolated/clones when XDG_DATA_HOME is unset"; refuses a clone path inside the checkout and a dir without its marker.

**Location:** `devcontainer-config/cc-push.sh:14-17`, `devcontainer-config/cc-push.sh:193-220`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the default-path precedence and the two refusals; does not establish behaviour when `--clone` names an existing non-git directory that happens to hold a matching marker file.
**route:** code-fact-check

```bash
# devcontainer-config/cc-push.sh:194
clone="${CC_PUSH_CLONES_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/cc-isolated/clones}/$name-$id"
```

Clone-inside-checkout refused (`:198-200`); missing/foreign marker refused (`:218-220`). Bats "clone-inside-checkout and foreign dir refused", "reuse on a second run", "no --remote refuses and creates nothing" pass.

**Evidence:** `devcontainer-config/cc-push.sh:194,198-220`

---

## Claim 9 (exit scan): "main() snapshots what host git reads to decide what to run ... anything added, removed or changed is named ... The resolved dirs are records too: repointing `.git` or `commondir` shows up."

**Location:** `devcontainer-config/cc-isolated.sh:556-566`, `devcontainer-config/cc-isolated.sh:648-660` (`scan_git_dirs`), `devcontainer-config/cc-isolated.sh:1206-1214` (resolved-dir records)
**Type:** Behavioral / Error-handling
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the specific escape where `.git` is invalidated so host git discovers the checkout *root* as its git dir; does not refute the scan's guarantee for a *repointed* (still-valid) `.git`/`commondir` (that case is recorded and works), and does not claim the LIMITS list is wrong for the routes it does enumerate.

`scan_git_dirs` locates the git dir from `$ws/.git`, requiring it to be a directory (or a `gitdir:` file) with a readable `config`:

```bash
# devcontainer-config/cc-isolated.sh:648-660 (scan_git_dirs)
g="$ws/.git"
if [ -f "$g" ]; then ... fi
[ -d "$g" ] || return 1
```

A session can remove `$ws/.git/HEAD` (leaving `.git/config` present, so `scan_git_dirs` still resolves `.git` and finds no exec-relevant change — HEAD/refs/objects are not recorded) and lay the checkout *root* out as a bare repo with a `pre-push` hook. Host git, finding `.git` invalid (no HEAD), ascends and treats the checkout root as the git dir; the exit scan never examines the root as a git dir (the embedded-repo search is `find ... -mindepth 2 -name .git` at `:1224-1225`, and the root git dir has no `.git` entry), so it returns 0 (clean, exit code 0). Executed probe: `git_exit_scan` returned status 0; `git rev-parse --git-dir` in the checkout returned `.`; `git push origin main` ran the planted hook (`RESULT: planted hook RAN on host push`).

- command: `TMPDIR=$PWD/probes probes/p2-scan-root-bare.sh $PWD/clone/devcontainer-config/cc-isolated.sh`
- cwd: `/tmp/claude-1000/-workspace/dbfd30e0-d8d5-40c1-8bac-572239fc44fd/scratchpad/q076rev-r1`; exit 0; 2026-09-28T01:51:31Z; git 2.39.5
- log: `/tmp/claude-1000/-workspace/dbfd30e0-d8d5-40c1-8bac-572239fc44fd/scratchpad/q076rev-r1/probes/p2.log`

This is the exit-scan counterpart of Claim 1: the scan trusts that `$ws/.git` is the git dir git will use, whereas git's discovery falls back to an ancestor when `.git` is invalid. This route yields a clean exit 0 (the silent-pass mode) and is **not** in the LIMITS comment (`:626-651`) or the guide's "Known routes it does not see" list. Since the header frames the scan as a TRIPWIRE that "catches the common plants" (not a guarantee), this does not refute a completeness guarantee — but the specific assertion "snapshots what host git reads to decide what to run" and "repointing `.git` ... shows up" is refuted for the invalidate-and-promote-root case, so I record it Incorrect rather than as a mere additional limit. See Claim 10 for the LIMITS-completeness reading.

**Evidence:** `devcontainer-config/cc-isolated.sh:648-660,1206-1225`; probe log `probes/p2.log`

---

## Claim 10 (LIMITS/guide completeness): the LIMITS comment and guide list the routes still uncovered ("Known routes it does not see").

**Location:** `devcontainer-config/cc-isolated.sh:626-651`; `guides/cc-isolated-usage.md` "The exit scan is a tripwire" list
**Type:** Behavioral (documentation completeness)
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers whether the enumerated routes are real and whether the enumeration is exhaustive; does not establish that no further routes beyond Claim 9 exist (I found one; there may be others).

The enumerated routes (hook running a tracked file; launch-time baseline; process after scan; killed launcher; tracked `.gitattributes`/`.gitmodules`; host-global filter drivers; another symlinked route; slow scan) are all accurate and correctly framed. The list is explicitly non-exhaustive ("It cannot be complete"), so it is not falsified by an additional route. But the `.git`-invalidation → root-git-dir-promotion route (Claim 9) is a materially different escape that produces a *clean exit 0*, and it is absent from both lists. A reader treating the LIMITS list as "these are the ways a clean scan can still be unsafe" is missing the most consequential one. Recommend adding it. Marked Mostly accurate (the enumeration is honest and non-exhaustive by its own words) rather than Incorrect.

**Evidence:** `devcontainer-config/cc-isolated.sh:626-651`; probe log `probes/p2.log`

---

## Claim 11 (exit scan): "THE SCAN RUNS NOTHING FROM THE REPO" — git dir located by plain file reads; config read `--file <f> --no-includes` from `/`; only host tools (find -P, stat, readlink, realpath, sha256sum, cat, tr, sort, awk, cut, mktemp, dirname, rm).

**Location:** `devcontainer-config/cc-isolated.sh:606-618`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the snapshot invokes no git operation that discovers the checkout repo (no `git -C <checkout>`; `git config --file ... --no-includes` runs from `cd /`); does not establish that `git config --file` on a hostile config file cannot itself misbehave (git parses config as data — no exec).
**route:** code-fact-check

`_snap_config` and `_snap_host_config` both run `(cd / && git --no-pager config --file "$f" --no-includes ...)` (`:874-875`, `:993-996`); git-dir location is by `read`/`cd`/`pwd -P` in `scan_git_dirs` (`:648-673`) and `_snap_dotgit_target` (`:1027-1043`); `find -P` never follows symlinks (`:816-820`). No `git rev-parse`/`status`/`fetch` runs in the checkout during the snapshot. (The launcher's own `resolve_workspace` runs `git rev-parse --show-toplevel` before the baseline — acknowledged at `:611-612` — which runs no hook.)

**Evidence:** `devcontainer-config/cc-isolated.sh:648-673,816-820,874-875,993-996`

---

## Claim 12 (exit scan): "FAIL CLOSED. A directory that cannot be listed, a file that cannot be read, a config git cannot parse, or a file too large to hash ... makes the snapshot fail: at launch the launcher refuses to start, at exit it returns 4."

**Location:** `devcontainer-config/cc-isolated.sh:620-625`, `devcontainer-config/cc-isolated.sh:812-820` (`_snap_find`), `:1288-1293` (launch refusal), `:1466-1471` (exit code mapping)
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers unlistable-dir and too-large-file → snapshot failure → launch refusal / exit 4; does not independently re-verify every individual unreadable-file path (covered by the passing suite).
**route:** code-fact-check

`_snap_find` fails the snapshot when `find` cannot list (`:815-819`); a failed baseline exits the launcher 1 (`:1288-1294`); a failed exit snapshot returns 2 from `git_exit_scan` mapped to `*) exit 4` (`:1466-1471`). Suite cases "exit scan size cap: a huge (sparse) planted hook fails the scan fast as unsafe" and "past the total to hash, the scan fails as unsafe" pass (cc-isolated-functions 148/148). Historic unlistable-hooks-dir cases (0311/0111) remain in the suite.

- log: `/tmp/claude-1000/-workspace/dbfd30e0-d8d5-40c1-8bac-572239fc44fd/scratchpad/q076rev-r1/bats-cc-isolated-functions.log`

**Evidence:** `devcontainer-config/cc-isolated.sh:815-819,1288-1294,1460-1471`; log `bats-cc-isolated-functions.log`

---

## Claim 13 (exit scan): size cap — "a file too large to hash (over 64 MiB, or past 1 GiB in all: _snap_size_ok)"; "The size is stat's apparent size (a sparse file counts in full)."

**Location:** `devcontainer-config/cc-isolated.sh:735-758`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the per-file 64 MiB and total 1 GiB caps and the apparent-size (`stat -L -c %s`) basis; does not establish wall-clock bounds under an adversarial file count (the scan can still be made slow — a documented limit).
**route:** code-fact-check

```bash
# devcontainer-config/cc-isolated.sh:743-744
GIT_EXIT_SCAN_MAX_FILE_BYTES=$((64 * 1024 * 1024))
GIT_EXIT_SCAN_MAX_TOTAL_BYTES=$((1024 * 1024 * 1024))
```

`stat -L -c %s` (`:747`) is apparent size, so a sparse hook counts in full; per-file check `:748-752`, running total `:753-757`. Suite "huge (sparse) planted hook fails ... fast" passes (a 100 GiB sparse hook, per the commit message, in well under 20 s).

**Evidence:** `devcontainer-config/cc-isolated.sh:743-757`; log `bats-cc-isolated-functions.log`

---

## Claim 14 (exit scan): Ctrl-C — "A Ctrl-C during the exit scan also exits 4, saying the scan did not finish."

**Location:** `devcontainer-config/cc-isolated.sh:1256-1264` (`scan_interrupted`), `:1452-1462` (trap wiring)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the INT trap installed for the duration of the scan and its `exit 4`; does not establish behaviour for signals other than INT (SIGTERM → no scan is a documented limit).
**route:** code-fact-check

```bash
# devcontainer-config/cc-isolated.sh:1454-1459
trap ':' INT
devcontainer exec "${dc[@]}" claude || rc=$?
trap scan_interrupted INT
...
git_exit_scan "$ws" "$git_before" "$lws" || scan=$?
trap - INT
```

`scan_interrupted` prints "the exit scan was interrupted, so it checked nothing" and `exit 4` (`:1257-1264`). Suite "a Ctrl-C during the exit scan exits 4, saying the scan did not finish" passes.

**Evidence:** `devcontainer-config/cc-isolated.sh:1256-1264,1454-1462`; log `bats-cc-isolated-functions.log`

---

## Claim 15 (exit scan): sanitizing — "EVERY CONTAINER-CHOSEN STRING ... is reduced to printable ASCII, newlines included, before it reaches the terminal" (%q-quote, _snap_fail, C-record replacement, scan_vis).

**Location:** `devcontainer-config/cc-isolated.sh:619-624`, `:681-689` (`_snap_fail`), `:1229-1235` (`scan_vis`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four sanitizing channels for container-chosen names/values/error text; does not establish that the fixed English scaffolding text (which contains no container data) is filtered — it need not be.
**route:** code-fact-check

`_snap_fail` does `LC_ALL=C tr -c '[:print:]' '?'` on tool-error reasons (`:684-687`); F/C records `%q`-quote paths and replace tabs/newlines in values (`:790,912-914`); `scan_vis` is `LC_ALL=C tr -c '[:print:]\n' '?'` on whole messages (`:1234`). E6 cases ("a newline in a repointed common dir's name cannot forge a line", "an unreadable .git file's read error is not printed raw") pass.

**Evidence:** `devcontainer-config/cc-isolated.sh:684-687,1234`; log `bats-cc-isolated-functions.log`

---

## Claim 16 (install/manifest/gate): install.sh ships and links cc-push, chmods it, and enforcement_files()/live-verify-gate hash it.

**Location:** `devcontainer-config/install.sh:110` (PAYLOAD), `:596,599-602` (chmod+link), `devcontainer-config/cc-isolated.sh:117` (enforcement_files), `hooks/live-verify-gate.sh:73` (gate regex)
**Type:** Configuration / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers cc-push.sh presence in PAYLOAD, the chmod+symlink, its inclusion in enforcement_files, and the gate regex alternative; does not re-derive the full manifest hash pipeline (covered by the passing live-verify-gate suite).
**route:** code-fact-check

`PAYLOAD=( ... cc-push.sh ... )` (`install.sh:110`); `chmod +x "$DEST/cc-isolated.sh" "$DEST/cc-push.sh" ...` and `ln -sf "$DEST/cc-push.sh" "$BIN_DIR/cc-push"` (`install.sh:596,601`); `echo "cc-push.sh"` in `enforcement_files` (`cc-isolated.sh:117`); gate regex adds `cc-push\.sh` (`live-verify-gate.sh:73`). install-host T3 (link exists, executable, on PATH) passes under `LANG=C.UTF-8`; live-verify-gate 21/21 (incl. "every manifest-hashed file is in the enforcement set", the 4435c73 fix). fixture-hermeticity and hermeticity-lint also updated with the cc-push stub, 2/2 and 53/53.

- logs: `bats-install-T3-clocale.log`, `bats2-live-verify-gate.log`

**Evidence:** `devcontainer-config/install.sh:110,596,601`, `devcontainer-config/cc-isolated.sh:117`, `hooks/live-verify-gate.sh:73`; logs above

---

## Claim 17 (commit 61d801c): "All 9 new cc-isolated cases fail against 4435c73's cc-isolated.sh and pass here." and totals "cc-push, cc-isolated-functions, install-host, hooks/live-verify-gate, fixture-hermeticity, hermeticity-lint: 340/340; guide-index-sync, cross-reference-integrity, function-inventory: 12/12."

**Location:** commit message 61d801c
**Type:** Reference (test counts)
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the +9 delta, the fail-against-4435c73 assertion, and both pass totals; does not cover shellcheck cleanliness (not re-run here).
**route:** code-fact-check

`cc-isolated-functions.bats` grew 139→148 (+9). The 9 new names (E6 x2, logical_workspace, E8 x2, relremote, size cap x2, Ctrl-C) all fail against 4435c73's `cc-isolated.sh` (executed: 9/9 `not ok`, log `old-scan-9new.log`) and pass here. Executed totals at 61d801c: cc-push 24 + cc-isolated-functions 148 + install-host 92 (under `C.UTF-8`) + live-verify-gate 21 + fixture-hermeticity 2 + hermeticity-lint 53 = **340/340**; guide-index-sync 1 + cross-reference-integrity 1 + function-inventory 10 = **12/12**. Both match exactly.

- logs: `bats-cc-push.log`, `bats-cc-isolated-functions.log`, `bats-install-T3-clocale.log`, `bats2-*.log`, `old-scan-9new.log`

**Evidence:** all logs under `/tmp/claude-1000/-workspace/dbfd30e0-d8d5-40c1-8bac-572239fc44fd/scratchpad/q076rev-r1/`

---

## Claim 18 (commit c3d9223 / 0566bc0 / f35381f / d9a895d / 37cae85): the "N new bats cases" counts.

**Location:** commit messages c3d9223, 0566bc0, f35381f, d9a895d, 37cae85
**Type:** Reference (test counts)
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the per-commit new-case deltas against each parent tree; does not re-verify the "14 of 15 fail against previous scan" claim in d9a895d (not independently reproduced — see Claim 20).
**route:** code-fact-check

Measured `@test` counts per commit tree: 37cae85 cc-isolated-functions 92→109 (+17, claim "17 new" ✓); d9a895d 109→125 (+16, "16 new" ✓); c3d9223 cc-push 0→9 ("9 cases" ✓); f35381f 125→139 (+14, "14 new" ✓); 0566bc0 cc-push 9→24 (+15; commit lists 15 added cases ✓). f35381f's "307/307" across its 8 listed suites = 139+92+2+53+9+1+1+10 = 307 ✓. (paraphrased — no quote available because the counts are grep aggregates across many `@test` lines in 9 files.)

**Evidence:** `git show <commit>:test/*.bats | grep -c '^@test'` for each commit (recorded in `/tmp/.../q076rev-r1` session log)

---

## Claim 19 (commit c3d9223): "Suites (at the final commit of this branch): ... 307/307".

**Location:** commit message c3d9223
**Type:** Reference (test counts)
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers whether "307/307 at the final commit of this branch" holds at 61d801c; does not dispute that 307 was the total at the time c3d9223 was written.

c3d9223 attributes "307/307" to "the final commit of this branch," but at the actual final commit (61d801c) the same 8-suite total is 148+92+2+53+24+1+1+10 = 331, and the headline six-suite total the final commit reports is 340. 307 was correct at f35381f (an intermediate commit), not at 61d801c. The phrase "final commit of this branch" is therefore imprecise — it names a forward total that was superseded by two later commits (0566bc0 +15 cc-push, 61d801c +9 cc-isolated). This is an intermediate-commit-message imprecision, not a defect in shipped code; the final commit's own totals (Claim 17) are correct.

**Evidence:** per-commit `@test` counts (session log); Claim 17 totals

---

## Claim 20 (iteration-3 closure): commit messages assert the a42e37f iteration-3 findings (E2c wrong-repo fetch, E2b FIFO hang, E4 unsanitized names, E5 exit codes, E6 forged lines, E8 includeIf via symlink, relremote embedded relative remote, size cap, Ctrl-C) are closed.

**Location:** commit messages 0566bc0, 61d801c; enforced across cc-push.sh and cc-isolated.sh
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers that each named iteration-3 finding has a corresponding guard + passing test at 61d801c; does not establish that the guards are *complete* — Claims 1 and 9 show the E2c/wrong-repo and .git-integrity families have an unclosed sibling route (the enter_repo/root-promotion fallback), which the iteration-3 reports did not name.
**route:** code-fact-check

Each iteration-3 item maps to a guard and a passing test: E2c/P2a (check_checkout alternates/gitdir/symlink refusals, Claim 3); E2b (include-section refusal, Claim 3); E4 (vis, Claim 5); E5 (exit-code subshell, Claim 4); E6 (_snap_fail, Claim 15); E8 (logical_workspace + `_snap_cond` logical match, cc-isolated.sh:236-247,948-984 — bats E8 cases pass); relremote (`_snap_remote` base = including repo's worktree, `:828-863` — bats relremote passes); size cap (Claim 13); Ctrl-C (Claim 14). All corresponding suites pass at 61d801c. The closures are real for the exact findings reported. Caveat (not a re-report of a closed item): the wrong-repository-fetch family (E2c) and the `.git`-integrity family are closed only for the in-`.git` shapes the iteration-3 reports enumerated; the root-promotion fallback (Claims 1, 9) is a new, distinct route in the same families, not previously reported.

**Evidence:** `devcontainer-config/cc-push.sh:125-158`, `devcontainer-config/cc-isolated.sh:236-247,828-863,948-984`; logs `bats-cc-push.log`, `bats-cc-isolated-functions.log`

---

## Claims Requiring Attention

### Incorrect
- **Claim 1** (`devcontainer-config/cc-push.sh:45-54,122-159`): `check_checkout` guards only `$co/.git`; a session that invalidates `.git` and lays the checkout *root* out as a bare repo with `objects/info/alternates` reaches upload-pack's enter_repo fallback, so cc-push fetched and pushed another host repo's private history (executed, git 2.39). The "objects/info/alternates ... AND SO IS REFUSED" guarantee has an unrefused path. Fix: also test the checkout-root layout (or refuse a checkout whose `.git` is not a valid git dir — i.e. reject when `git rev-parse --git-dir`, run hooks-off from the checkout, does not resolve to `<co>/.git`), and/or fetch from `$co/.git` explicitly rather than `$co`.
- **Claim 9** (`devcontainer-config/cc-isolated.sh:648-660,1206-1225`): the exit scan snapshots `$ws/.git`; invalidating `.git` so host git discovers the checkout root as its git dir escapes the scan with a clean exit 0, and host `git push` then runs a hook planted at the root (executed). "Snapshots what host git reads to decide what to run" / "repointing .git ... shows up" is refuted for this case. Fix: snapshot the git dir git *actually* discovers (e.g. resolve via a hooks-off `git rev-parse --git-dir` and record any divergence from `<ws>/.git`), and treat an invalid `<ws>/.git` as a finding.

### Mostly Accurate
- **Claim 5** (`devcontainer-config/cc-push.sh:56-57`): "EVERY STRING" is slightly over-broad — the fixed prompt `Push these? [y/N] ` is not vis-filtered, but it carries no container data; precise wording is "every container-controlled string."
- **Claim 10** (`devcontainer-config/cc-isolated.sh:626-651`): LIMITS/guide enumeration is honest and self-declared non-exhaustive, but omits the clean-exit-0 root-promotion route (Claim 9), the most consequential missing entry. Add it.
- **Claim 19** (commit c3d9223): "307/307 at the final commit of this branch" was true at intermediate f35381f, not at 61d801c (where the totals are 340 / 331); intermediate-message imprecision only.

### Unverifiable
- The commit messages' repeated "Live-verified: no — the user will run a live session..." items (live container launch, planting a hook through a symlinked route, Ctrl-C during a real scan) require a running devcontainer/kernel and are out of sandbox reach — execution required, blocked (no devcontainer runtime here). Consistent with the authors' own "Live-verified: no" notes.
- **Claim 18's** d9a895d sub-claim "14 of the 15 new (a)-(f) cases fail against the previous scan" was not independently reproduced (I reproduced the 61d801c +9 and the 4435c73 comparison, not the a958372 15-case split); the delta counts themselves are verified.

---

## Goal-Alignment Note

**Success criterion (verbatim):** A code-fact-check report saved at /workspace/docs/reviews/q076-code-fact-check-report-r1.md in the skill's schema, with a Goal-Alignment Note.

**Answered:** Report saved at the required path in the skill's schema (first line `Commit: 61d801c`, header fields, per-claim seven mandatory fields, Claims-Requiring-Attention section). Fact-checked cc-push's refusal set / "runs nothing"/exit-code/sanitizing claims (Claims 1-8), the exit scan's coverage / fail-closed / size-cap / Ctrl-C / sanitizing / LIMITS-completeness claims (Claims 9-15), install/manifest/gate claims (Claim 16), iteration-3 closure (Claim 20), and commit-message test counts (Claims 17-19). Per the brief I attempted to defeat both central guarantees; two attempts succeeded (Claims 1 and 9), sharing one root cause — git's repository-discovery fallback when `.git` is made invalid, which neither `check_checkout` nor `scan_git_dirs` anticipates. Executed verdicts have logs under the scratchpad `q076rev-r1/` dir. The a42e37f iteration-3 findings are genuinely closed for the exact routes reported; I did not re-report any closed item as new.

**Out of scope (per skill non-goals):** Code-quality/refactor judgments and the fix designs beyond what a verdict needs (sketched only). Live-container behaviour (no devcontainer runtime) — left Unverifiable, matching the authors' own "Live-verified: no" notes.

**Escalate:** Claims 1 and 9 are within the stated threat model (a container that writes `.git`) and defeat the two headline guarantees (cc-push cannot exfiltrate another repo; the exit scan sees what host git will run). They are not in LIMITS. A downstream security-reviewer should weigh whether these block merge, since they turn "clean exit 0 / successful push" into a false-safe signal. Both trace to one fix: verify the git dir git will actually discover, rather than assuming it is `<checkout>/.git`.
