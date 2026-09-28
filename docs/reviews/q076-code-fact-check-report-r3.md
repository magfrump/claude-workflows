Commit: 61d801c

# Code Fact-Check Report

**Repository:** /workspace (scratch clone at 61d801c: /tmp/claude-1000/-workspace/dbfd30e0-d8d5-40c1-8bac-572239fc44fd/scratchpad/q076rev-r3/repo)
**Scope:** `git diff main...feat/q076-git-exit-scan` (cc-isolated.sh, cc-push.sh, install.sh, hooks/live-verify-gate.sh, guides/cc-isolated-usage.md, test/cc-isolated-functions.bats, test/cc-push.bats, test/install-host.bats) plus the branch's commit messages
**Checked:** 2026-09-27
**Total claims checked:** 17
**Summary:** 9 verified, 7 mostly accurate, 0 stale, 1 incorrect, 0 unverifiable

Logs: `/tmp/claude-1000/-workspace/dbfd30e0-d8d5-40c1-8bac-572239fc44fd/scratchpad/q076rev-r3/logs/`. All commands below ran with cwd set to the scratch clone (`.../q076rev-r3/repo`), or with the probe directory named in the log, on git 2.39.5.

Note on method: one probe I planned was not built. It would have tested whether a process still running in the container could change `.git` between cc-push's check and its fetch. Claim 3b reports that from reading the code only.

---

## Claim 1: "Exit codes: 0 pushed (or nothing to push); 1 error … (git's own exit status is never passed through); 2 declined at the prompt." / "the exit codes stay 0, 1 and 2"

**Location:** `devcontainer-config/cc-push.sh:20-22`, `:296-306`; guide `guides/cc-isolated-usage.md` (Exit codes paragraph)
**Type:** Behavioral / Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the error and decline paths and a SIGINT at the prompt. It does not establish the status for other signals (SIGTERM, SIGHUP), which I expect to behave like SIGINT.

Status mapping in the guard at `cc-push.sh:300-306`:
```bash
  ( set -e; main "$@" )
  rc=$?
  case "$rc" in
    0|1|2) exit "$rc" ;;
    *) echo "ERROR: cc-push stopped on an unexpected failure (status $rc)." >&2; exit 1 ;;
```
The mapping holds for failures. A Ctrl-C at the `[y/N]` prompt sends SIGINT to the whole process group, so the parent bash is killed along with the subshell and never reaches the `case`. I ran cc-push in its own process group with SIGINT at its default disposition and sent SIGINT at the prompt. It exited **130** and nothing was pushed: upstream `main` stayed at 4714b06 and the checkout stayed at 3f3af93. The precise wording is "0/1/2, or 128+N if killed by a signal (e.g. 130 on Ctrl-C at the prompt; nothing is pushed)".

Command: `python3 pgrun.py in bash repo/devcontainer-config/cc-push.sh --remote probeA/up.git probeA/co` followed by `kill -INT -- -<pgid>`. cwd: `.../q076rev-r3/probeA`. Exit code: 130. Time: 2026-09-28T01:4xZ.

**Evidence:** `devcontainer-config/cc-push.sh:278-286`, `devcontainer-config/cc-push.sh:299-306`, logs/probeA-ctrlc-prompt.log

---

## Claim 2: "upload-pack READS there: refs, objects and config … It runs no hook, no fsmonitor, no filter, and ignores uploadpack.packObjectsHook from repo config."

**Location:** `devcontainer-config/cc-push.sh:32-36`; guide "What `cc-push` does" step 1 and "Every git command it runs … (git 2.39)"
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5 with the plant set in test/cc-push.bats plus a partial-clone promisor remote whose `uploadpack` command was planted. It does not establish the same result on a git without the upload-pack "disable lazy-fetching" fix (2.39.4 and later, 2.45.1 and later); on such a git, upload-pack could lazily fetch through the checkout's planted promisor remote.

The suite case "cc-push runs nothing planted in the checkout (full plant set)" passed; the same plants fire under a plain host `git status`. As an additional probe, I gave the checkout `extensions.partialClone=evil`, `remote.evil.promisor=true` and `remote.evil.uploadpack="touch …; git-upload-pack"`, then deleted a blob. The plant was live: a host `git cat-file` in the checkout created the marker. cc-push's fetch then printed `remote: warning: lazy fetching disabled` and failed, cc-push exited 1 with "could not fetch from …", and no marker was created.

Command: `bash probeB.sh` (cwd `.../q076rev-r3`). Exit code: cc-push rc=1. Time: 2026-09-28T01:53:55Z.

**Evidence:** `devcontainer-config/cc-push.sh:233-236`, `test/cc-push.bats:107-119`, logs/suite1.log, logs/probeB-promisor.log

---

## Claim 3a: "Before the fetch, with plain file tests (no git), cc-push refuses a checkout whose .git is not a real directory … or holds a commondir, objects/info/alternates or …http-alternates file, a symlink outside hooks/, a FIFO, socket or device …, or a config / config.worktree with an [include] or [includeIf] section"

**Location:** `devcontainer-config/cc-push.sh:45-54`, `:122-159`; guide "What it refuses"
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each refusal against a `.git` that is not changing while cc-push runs. It does not cover a `.git` that changes during the run (Claim 3b), and does not establish that the include regex matches every form git's parser accepts, beyond the forms tested and my reading of git's section-header parser.

The refusal tests in test/cc-push.bats pass: gitdir: file, symlinked .git, alternates, http-alternates plus commondir, symlinked objects, FIFO include outside and inside .git, includeIf / `[ Include ]` / `[user][include]` / config.worktree, FIFO packed-refs, and a newline in a name. A socket, which the suite does not test, is also refused:
```
ERROR: …/probeD/co/.git/sock is a symlink, FIFO, socket or device inside the checkout's .git: …
rc=1
```
Command: `bash cc-push.sh --remote probeD/up.git --yes probeD/co`. cwd: `.../probeD`. Exit code: 1. Time: 2026-09-28T01:54:31Z.

**Evidence:** `devcontainer-config/cc-push.sh:142-158`, `test/cc-push.bats:210-328`, logs/probeD-socket.log, logs/suite1.log

---

## Claim 3b: "Otherwise upload-pack could fetch history from another repository … and cc-push would offer it for push." (guide: "What remains is upload-pack reading the checkout's own refs, objects and (include-free) config.")

**Location:** `devcontainer-config/cc-push.sh:53-54`; guide "What it refuses", last sentence
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the ordering of the check and the fetch in `main`. It does not establish how practical it is to exploit the window, and I ran no probe of it.

The residual described is right only if `.git` does not change between the check and the fetch. The check runs once, and several host commands run before upload-pack opens the checkout:
```bash
  check_checkout "$co"
  local id name
  id="$(printf '%s' "$co" | sha256sum | cut -c1-12)"
```
(excerpt `cc-push.sh:188-191`; `main` continues through `run_vis ngit init`, three `hgit config` calls and the marker write, `:205-216`, to the fetch at `:233-236`, all read). Nothing re-checks `.git` after `:188`. The same guide says "The container keeps running when claude exits; a process the session left behind can plant after the scan. Only a stopped container (`docker stop`) cannot." The cc-push section, however, never tells the user to stop the container before running cc-push. A process left running could therefore add, after the check, an item cc-push refuses (for example `objects/info/alternates`). The precise version: the refusal set holds for a `.git` that nothing writes while cc-push runs. Stop the container (`docker stop`) before running cc-push.

**Evidence:** `devcontainer-config/cc-push.sh:185-236`, `guides/cc-isolated-usage.md` ("After the scan." bullet and "What it refuses")

---

## Claim 4: "Every git command cc-push runs passes core.hooksPath=/dev/null and core.fsmonitor=false"

**Location:** `devcontainer-config/cc-push.sh:41-43`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every `git` call in cc-push.sh. It does not establish that these two flags disable every hook mechanism of future git versions (for example config-defined `hook.<name>.command`, which is not in 2.39).

Every call goes through `ngit` (`cc-push.sh:97-99`: `git -c core.hooksPath=/dev/null -c core.fsmonitor=false "$@"`) or `hgit` (`:102-105`, which calls ngit). A grep found no bare `git` invocation elsewhere in the file (paraphrased — no quote available because the claim is the absence of any other call site).

**Evidence:** `devcontainer-config/cc-push.sh:96-105`, `:210-291`

---

## Claim 5: "EVERY STRING FROM THE CHECKOUT (branch names, commit text, git's messages) is printed through vis"

**Location:** `devcontainer-config/cc-push.sh:56-57`; guide step 3
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the say/die/run_vis paths (tested by the E4 cases). It does not establish that the unfiltered stderr paths can be triggered with checkout-chosen text.

say, die and run_vis all go through vis, and the E4 tests pass. A few git calls leave stderr unfiltered:
```bash
    commits="$(hgit "$clone" rev-list "$range")" || die "could not list the commits in $range"
```
(`cc-push.sh:261`). The same is true of `hgit … config` at `:211-213`, `:222` and `:226`. The config calls only carry the host clone path and remote URL. rev-list's error text would carry the checkout's branch name, which `check-ref-format` allows to contain bytes 0x80 and above, but only when rev-list fails after both refs were verified. The precise version: every string cc-push prints itself goes through vis, and a failing `rev-list` or `config` call's stderr does not.

**Evidence:** `devcontainer-config/cc-push.sh:86-94`, `:161-166`, `:211-226`, `:261`

---

## Claim 6: "--help prints the whole header (awk to the first non-comment line), exit codes included"; default clone location "$XDG_DATA_HOME/cc-isolated/clones … ~/.local/share/cc-isolated/clones when XDG_DATA_HOME is unset"

**Location:** `devcontainer-config/cc-push.sh:71-75`, `:15-17`, `:194`; commit 0566bc0
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the help output and the default-path expression. It does not establish behaviour when `XDG_DATA_HOME` is set to a relative path.

The test "--help prints the whole header, exit codes included" passed. The default path is built as `"${CC_PUSH_CLONES_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/cc-isolated/clones}/$name-$id"` (`:194`).

**Evidence:** `test/cc-push.bats:381-387`, `devcontainer-config/cc-push.sh:194`, logs/suite1.log

---

## Claim 7: "every error reason is written by _snap_fail (tools' own error text is dropped: it would quote a path raw)"

**Location:** `devcontainer-config/cc-isolated.sh:613-617`
**Type:** Error-handling
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** The verdict applies to the parenthetical "tools' own error text is dropped". The first half (every reason goes through `_snap_fail` and becomes one printable-ASCII line) is confirmed. It does not establish that a container-chosen name inside that single line cannot mislead a reader.

For `find` and `git config`, the tool's own error text is kept (sanitized) inside the reason, not dropped:
```bash
    _snap_fail 'cannot list everything under %s: %s' "$1" "$(cat "$out.err")"
```
(`cc-isolated.sh:783`; likewise `:881` and `:999` for `git config`). Probe output:
```
cannot list everything under …/probeE/ws: find: ???…/probeE/ws/a/locked???: Permission denied
```
The line breaks are gone (the E6 goal holds), but find's own text quoting the path is still present. The accurate wording: read, readlink, stat and cd errors are dropped; find and git config errors are kept, reduced to one line of printable ASCII.

Command: `bash -c "source cc-isolated.sh; git_exec_snapshot probeE/ws"`. cwd: `.../probeE`. Exit code: 1. Time: 2026-09-28T01:54:31Z.

**Evidence:** `devcontainer-config/cc-isolated.sh:685-692`, `:780-786`, `:880-882`, `:998-1000`, logs/probeE-finderr.log

---

## Claim 8: "The rest is host tools reading files: find, stat, readlink, realpath, sha256sum, cat, tr, sort, awk, cut, mktemp, dirname and rm" (guide list omits dirname and rm; commit 61d801c: "tool list completed")

**Location:** `devcontainer-config/cc-isolated.sh:606-608`; guide "The exit scan is a tripwire"
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the external commands used by the scan functions. It does not establish anything about the launcher's other git calls (resolve_workspace is acknowledged at `:610-611`).

`git_exit_scan` also runs `sed`:
```bash
    printf '%s\n' "$reason" | sed 's/^/    /'
```
(`cc-isolated.sh:1249`). The guide's list further omits `dirname` and `rm`. None of these runs anything from the checkout, so the conclusion stands; the list is still incomplete.

**Evidence:** `devcontainer-config/cc-isolated.sh:1201`, `:1242-1258`

---

## Claim 9: Fail closed — "a file too large to hash (over 64 MiB, or past 1 GiB in all) makes the snapshot fail … A Ctrl-C during the exit scan also exits 4"

**Location:** `devcontainer-config/cc-isolated.sh:595-600`, `:704-726`, `:1459-1471`; guide "A slow scan" / "No scan"
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the size caps (apparent size via `stat -L`) and SIGINT during the scan. It does not cover other signals (Ctrl-\ / SIGQUIT, SIGTERM), which the LIMITS "killed" item covers.

The size-cap and Ctrl-C cases passed at 61d801c and failed against 4435c73's script (Claim 15).

**Evidence:** `devcontainer-config/cc-isolated.sh:710-726`, `:1285-1294`, logs/old9.log, logs/suite1.log

---

## Claim 10: LIMITS "No finding does not mean safe:" list and the guide's "Known routes it does not see"

**Location:** `devcontainer-config/cc-isolated.sh:619-639`; guide bullets under "It **cannot** be complete"
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the routes I identified by reading the code. It does not establish that the list is otherwise complete, and I did not demonstrate these routes with execution.

The listed items are accurate. At least these routes are unlisted:

(a) **A bare-layout git dir inside the working tree, not named `.git`.** A directory holding HEAD, objects/ and refs/ plus a config is discovered by git as the repository when git runs inside that directory. The scan finds embedded repos only by `.git` entries:
```bash
    _snap_find "$list" "$_snap_ws" -mindepth 2 -name .git
```
(`cc-isolated.sh:1182`). HEAD-based discovery is used only under modules/ and worktrees/ and in linked dirs (`:1051-1063`). A host git command run from inside such a subdirectory reads config the scan never recorded. This is paraphrased — no quote available because it depends on git's setup.c discovery order, which I did not run here.

(b) **`~user/` paths, and `~/` in remote URLs.** `_snap_path` handles only `~/`:
```bash
    "~/"*) printf '%s' "$HOME/${1#"~/"}" ;;
```
(`cc-isolated.sh:792`). A baseline `include.path` or `core.hooksPath` written as `~<user>/…` resolves elsewhere in the scan than in git. A remote URL written `~/…` goes through `_snap_remote`, which treats it as relative (`:857`), while receive-pack expands it. So a target inside the checkout that such a baseline value names is not watched. Adding the value itself is still a finding, because the config file is hashed. This falls under the "anything present at launch" item only loosely.

(c) cc-push's upload-pack protection against lazy fetch depends on the git version (Claim 2 scope).

**Evidence:** `devcontainer-config/cc-isolated.sh:619-639`, `:788-796`, `:848-868`, `:1051-1063`, `:1174-1191`

---

## Claim 11: Guide step 7: "exits **3** naming anything the session added, removed or changed. It exits 4 when the exit scan cannot list or read any of it"

**Location:** `guides/cc-isolated-usage.md` (launch step 7 and "The exit scan is a tripwire"); `devcontainer-config/cc-isolated.sh:1467-1471`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the mapping from scan result to exit status. It does not establish how the user interprets 3 or 4.

Findings always give 3 and an unreadable scan always gives 4:
```bash
  case "$scan" in
    0) exit "$rc" ;;
    1) exit 3 ;;   # the session planted something: never a clean exit
    *) exit 4 ;;   # the scan could not read .git
```
On a clean scan, though, the launcher returns claude's own status (`rc` from `devcontainer exec`), which the session can make 3 or 4. So 3 and 4 are not exclusive to the scan; only the printed WARNING is. This can produce false alarms but never a false clean result.

**Evidence:** `devcontainer-config/cc-isolated.sh:1458-1471`

---

## Claim 12: install.sh ships, chmods and links cc-push; "The manifest hashes it like the launcher"; the gate treats cc-push.sh as an enforcement file

**Location:** `devcontainer-config/install.sh:110`, `:596-603`; `devcontainer-config/cc-isolated.sh:108-116`; `hooks/live-verify-gate.sh:73`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers install into the stubbed fixture, manifest membership, and the gate regex. It does not establish that cc-push checks the manifest at run time; it does not, and the claim only says the next cc-isolated launch is blocked.

`enforcement_files` echoes `"cc-push.sh"` (`cc-isolated.sh:116`). The gate regex includes `cc-push\.sh` (`live-verify-gate.sh:73`). install-host T3 (link, target, executable) and live-verify-gate "every manifest-hashed file is in the enforcement set" passed.

**Evidence:** logs/suite1.log, `test/install-host.bats:204-215`

---

## Claim 13: Guide: "`test/cc-push.bats` plants every hook `githooks(5)` lists, … and asserts that a `cc-push` fires none of them …; it also covers each refusal above."

**Location:** `guides/cc-isolated-usage.md` ("Every git command it runs …" paragraph)
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what the test file contains. It does not establish runtime results; for those see Claims 2 and 3a.

The 28 githooks(5) names at 2.39 plus 2 non-hooks are planted (`test/cc-push.bats:50-58`). The refusal tests do not include a socket or a device (`:210-328`). The socket refusal does work (Claim 3a probe). "Each refusal" should read "each refusal except socket/device".

**Evidence:** `test/cc-push.bats:46-89`, `:210-328`

---

## Claim 14: Commit messages: "LC_ALL=C.UTF-8 bats cc-push, cc-isolated-functions, install-host, hooks/live-verify-gate, fixture-hermeticity, hermeticity-lint: 340/340; guide-index-sync, cross-reference-integrity, function-inventory: 12/12. shellcheck … clean"

**Location:** commit 61d801c message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers these suites at 61d801c in this sandbox. It does not establish the other commits' counts (307/307 at c3d9223 and f35381f), which are superseded.

The first run gave 339/340: install-host T33 failed only because an unrelated process belonging to another agent tripped install.sh's agent-process guard. T33 passed when rerun alone. The second group gave 1..12 with exit 0. shellcheck over the 7 changed .sh/.bats files exited 0.

Commands: `LC_ALL=C.UTF-8 bats <6 files>`; `bats -f T33 test/install-host.bats`; `LC_ALL=C.UTF-8 bats <3 files>`; `shellcheck -x -e SC1091 -s bash -S warning …`. cwd: scratch repo. Exit codes: 1 (the T33 flake), 0, 0, 0. Started 2026-09-28T01:42:37Z; shellcheck ran at 01:52:46Z.

**Evidence:** logs/suite1.log, logs/suite-T33-rerun.log, logs/suite2.log, logs/shellcheck.log

---

## Claim 15: "All 9 new cc-isolated cases fail against 4435c73's cc-isolated.sh and pass here."

**Location:** commit 61d801c message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the 9 cases added in 61d801c. It does not establish that each case fails for the reason it names.

The 9 cases were run twice with `bats -f 'E6|E8|logical_workspace|relremote|size cap|Ctrl-C during the exit scan'`. With 4435c73's cc-isolated.sh swapped into a copy, all 9 were "not ok" (exit 1, logged at old9.ts). At 61d801c all 9 were ok.

**Evidence:** logs/old9.log, logs/old9.ts

---

## Claim 16: Iteration-3 findings closed (E2b FIFO include, E2c/P2a wrong-repo fetch, E4 terminal bytes, E5 exit codes, E6 forged lines, E8 symlinked includeIf, relremote, size cap, Ctrl-C)

**Location:** commits 0566bc0, 61d801c
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the regression cases for each finding, all passing. It does not cover the variants noted in Claims 1 (a signal gives status 130), 3b (race with a running process) and 7 (tools' error text is kept), which are narrower than the original findings.

The listed cases in test/cc-push.bats (`:210-379`) and cc-isolated-functions.bats pass (logs/suite1.log). I found none of the iteration-3 reproductions open again.

**Evidence:** logs/suite1.log, logs/old9.log

---

## Claim 17: "(The launcher's own resolve_workspace runs `git rev-parse --show-toplevel` in the checkout before the baseline; that runs no hook or fsmonitor.)"

**Location:** `devcontainer-config/cc-isolated.sh:610-611`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the git calls the launcher makes in the checkout. It does not establish hang behaviour for a planted include FIFO.

`resolve_workspace` (`:217`) is not the launcher's only git call in the checkout. `ws_fingerprint`, used by the probe, also runs `git -C "$ws" rev-parse HEAD` and `git -C "$ws" config --get remote.origin.url` (`:255-256`), and `config --get` follows includes. None of these runs hooks or fsmonitor, but the parenthetical names only one call.

**Evidence:** `devcontainer-config/cc-isolated.sh:211-224`, `:253-258`

---

## Claims Requiring Attention

### Incorrect
- **Claim 7** (`devcontainer-config/cc-isolated.sh:613-617`): find and git config error text is kept (sanitized to one line) in `_snap_fail` reasons, not dropped. Reword the comment, or drop `$(cat "$out.err")` at :783, :881 and :999.

### Mostly Accurate
- **Claim 1** (`cc-push.sh:20-22`, `:296-298`): Ctrl-C at the prompt exits 130, not 0/1/2. Nothing is pushed.
- **Claim 3b** (`cc-push.sh:53-54`, guide "What it refuses"): the check and the fetch are not atomic, and a container process still running can change `.git` between `:188` and `:233`. Tell the user to stop the container (`docker stop`) before running cc-push, or re-check `.git` after the fetch.
- **Claim 5** (`cc-push.sh:56-57`): stderr from rev-list (`:261`) and from `config` (`:211-226`) is not passed through vis.
- **Claim 8** (`cc-isolated.sh:606-608`, guide): the tool list omits `sed`, and the guide also omits dirname and rm.
- **Claim 10** (`cc-isolated.sh:619-639`, guide): unlisted uncovered routes are a bare-layout git dir in a working-tree subdirectory, `~user/` and `~/` path forms, and cc-push's dependence on git ≥ 2.39.4 for the lazy-fetch fix.
- **Claim 11** (guide step 7): on a clean scan the launcher passes claude's own exit status through, so 3 or 4 does not always mean the scan fired.
- **Claim 13** (guide): the tests do not cover the socket and device refusals.
- **Claim 17** (`cc-isolated.sh:610-611`): the launcher also runs `ws_fingerprint`'s git calls in the checkout.

### Unverifiable
- (none)

---

## Goal-Alignment Note

- **Success criterion (verbatim):** A code-fact-check report saved at /workspace/docs/reviews/q076-code-fact-check-report-r3.md in the skill's schema, with a Goal-Alignment Note.
- **Answered:** All nine iteration-3 findings are closed. The suite and commit-message counts were reproduced (340/340 once the environmental T33 failure was rerun, 12/12, 9/9 fail at 4435c73 and pass at 61d801c, shellcheck clean). cc-push's "runs nothing" held against the full plant set and against a planted promisor-remote lazy fetch on git 2.39.5. Each refusal held, including a socket. Seven claims need rewording and one comment is incorrect (Claim 7).
- **Out of scope:** I did not build or run the planned race probe of cc-push's check and fetch (Claim 3b is from reading only). I did not execute bare-subdirectory discovery or the `~user/` resolution (Claim 10). I did not test git versions other than 2.39.5, or cc-push against an LFS repository; cc-push's hooks-off push skips git-lfs's pre-push upload, which no claim addresses.
- **Escalate:** Claim 3b. The guide should say whether the container must be stopped before running cc-push, since the scan section already states that processes can keep running after claude exits.
