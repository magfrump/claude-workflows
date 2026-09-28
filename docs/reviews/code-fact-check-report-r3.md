Commit: a42e37f

# Code Fact-Check Report

**Repository:** /workspace (branch integrate/q076-q080)
**Scope:** pass-1 diff `git diff main...a42e37f -- . ':!skills'` (excluding guides/skill-format-audit.md and docs/reviews/), plus commit messages f35381f, c3d9223, 0a4862b and 4435c73. Iteration 3 (final), replicate r3. All execution ran in a scratch clone checked out at a42e37f (`$SP/iter3-r3/repo`), with hermetic HOME and GIT_CONFIG_GLOBAL. Git 2.39.5, bats 1.8.2.
**Checked:** 2026-09-27
**Total claims checked:** 31 (Claims 1-30, with 14 split into 14a/14b)
**Summary:** 16 verified, 10 mostly accurate, 1 stale, 4 incorrect, 0 unverifiable

`$SP` = `/tmp/claude-1000/-workspace/dbfd30e0-d8d5-40c1-8bac-572239fc44fd/scratchpad`. Logs: `$SP/iter3-r3/*.log` and `$SP/iter3-r3/probes/*.log`. The probe scripts that wrote them sit next to them (`probes/p*.sh`, `nl.sh`, `relremote.sh`, `cond.sh`, `perf.sh`, `hookprobe.sh`).

Hallucination-pattern log: `docs/reviews/hallucination-patterns.md` was read. No claim below matches a logged pattern. None of the Incorrect verdicts is a fabricated symbol, so nothing is added to the log. This replicate also writes no file except this report.

## Headline results

- **cc-push runs nothing from the checkout.** I re-ran the bats plant set and added these plants: alternates with `core.alternateRefsCommand`, a `gitdir:` file, a FIFO include, a symlinked checkout, a C1 branch name, and host-global pager, gpg, textconv, `diff.external`, hooksPath and fsmonitor. Across all of them, no planted or host-global program fired in the clone or the checkout. Two things do run: hooks on a *local* origin (the user's own upstream) and upload-pack in the checkout.
- **It does read beyond the checkout.** upload-pack follows the checkout's `objects/info/alternates` and a `.git` `gitdir:` file to any host path. A commit that exists only in another host repo was fetched into the clone and pushed to origin (P2a). The docs say only "reads its refs, objects and config" (Claim 14b).
- **New exit-scan gap.** A relative local remote in an **embedded repo's** config is resolved against the top-level checkout, not the embedded working tree. After a planted hook, the scan returned 0 and a host `git push` inside the embedded repo ran it (Claim 3).
- **Newline sanitisation is still incomplete in one path.** A common dir reached through a symlink whose target name contains a newline forges a line in the exit-4 warning (Claim 7).
- **The iteration-2 Incorrects are resolved or listed as limits.** All 14 new bats cases fail against a958372 and pass at a42e37f. The husky/pre-commit route is now in LIMITS and in the guide.
- **Commit-message numbers reproduce.** 139/139, 9/9, 307/307, 14 fail on a958372, shellcheck `-S warning` clean, and the live-verify-gate test fails before 4435c73. No commit in `main..a42e37f` claims "401/401" (see the Goal-Alignment Note).

---

## Claim 1: ".gitignore: Generated eval reports are to be committed once generated (Q-071 [1]; none yet) … Anything else a run might leave in output/ stays ignored."

**Location:** `.gitignore:4-13`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which flat `output/` files are ignored or admitted, and that none is tracked. It does not establish nested paths under `output/`.
**Legibility-target:** for-orchestrator-synthesis

`git check-ignore -v --no-index` (cwd `$SP/iter3-r3/repo`, 2026-09-28T00:00:33Z, exit 0) reports `.report.md`, `.stamp`, `.failed` and `.transcript.jsonl` as re-included by `.gitignore:10-13` (`!test/skills/*/output/*.report.md` …). It reports `scratch.tmp` as ignored by `.gitignore:9` (`test/skills/*/output/*`). `git ls-files 'test/skills/*/output/*' | wc -l` prints `0`, which matches "none yet". This resolves iteration-2 Claim 1. `scripts/run-tests.sh:100-101` ("reports are trackable once generated") and `test/skills/eval-helpers-freshness.bats:8-9` ("not ignored by git, so they can be committed") were corrected the same way.

**Evidence:** `.gitignore:4-13`; `scripts/run-tests.sh:100-101`; `test/skills/eval-helpers-freshness.bats:8-9`; `$SP/iter3-r3/gitignore.log`

---

## Claim 2: "The way to push is cc-push (cc-push.sh, next to this file): it fetches into a separate host-only clone and pushes from there, and runs nothing from the checkout."

**Location:** `devcontainer-config/cc-isolated.sh:542-544` (also the warnings at `:1149-1150`, `:1166-1168`)
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers "runs nothing" for every plant listed in the Headline results, on git 2.39. It does not establish that cc-push *reads* nothing outside the checkout (it does, see Claim 14b). "Next to this file" rests on install.sh putting both files in `$DEST` (Claim 22).
**Legibility-target:** for-orchestrator-synthesis

`bats test/cc-push.bats` passes 9/9 (cwd `$SP/iter3-r3/repo`, 2026-09-27T23:49:03Z, exit 0). Its `plant_all` (`test/cc-push.bats:46-86`) plants 17 hook names, a husky hooksPath, fsmonitor, clean/smudge/process filters, receivepack/uploadpack, packObjectsHook, alternateRefsCommand, sshCommand, gitProxy, askPass, pager, credential helper, `diff.external`, include/includeIf, a legacy remotes file and a repointed origin. Case 2 asserts `[ -z "$(markers)" ]` after cc-push, then shows the plants are live under a plain `git status`. My extra probes also fire no planted marker:

- P2a: `objects/info/alternates` plus `core.alternateRefsCommand`, so the command is reachable. Result: `markers=[]`.
- P4a: a `gitdir:` file.
- P4c: a symlinked checkout.
- P1: host-global `core.pager`, `pager.log`, `pager.diff`, `log.showSignature` with `gpg.program`, `diff.external`, `diff.x.textconv`/`command` with a global attributesFile, `core.fsmonitor` and `core.hooksPath`. Only `g-hook-post-update` and `g-hook-reference-transaction` fired. They are the *local upstream's* receive-side hooks, which read the user's global hooksPath (`-c` does not cross a local transport). They are not the clone's hooks or the checkout's.

**Evidence:** `devcontainer-config/cc-isolated.sh:542-544`; `devcontainer-config/cc-push.sh:146-147,163,178-179,197`; `test/cc-push.bats:46-116`; `$SP/iter3-r3/cc-push-bats.log`, `probes/p1.log` (23:55:29Z, exit 0), `probes/p2.log`, `probes/p4.log`

---

## Claim 3: "Recorded, for every git dir reached (… every local-path remote) … every remote that is a local path inside the checkout (remote.*.url/pushurl, remote.pushDefault, branch.*.remote/pushRemote naming a path, url.<base>.insteadOf bases, legacy remotes files), walked as a git dir: a push to it runs its hooks."

**Location:** `devcontainer-config/cc-isolated.sh:550-564` (implementation `:771-798`; guide `guides/cc-isolated-usage.md:218-226`)
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers one reproduced miss: a relative remote in an embedded repo's config. The same resolution also applies to `.git/modules/*` configs, legacy remotes files and insteadOf bases read from nested repos. This was inferred from the code and not run. The verdict does not rate likelihood: it needs an embedded repo with a relative local remote at launch, and a host push run inside that repo.
**Legibility-target:** for-author

`_snap_remote` resolves every relative path against the top-level checkout, whichever config named it:

```bash
# devcontainer-config/cc-isolated.sh:786-787
  if [[ "$p" == *:* ]] && [[ "${p%%:*}" != */* ]]; then return 0; fi
  case "$p" in /*) ;; *) p="$_snap_ws/$p" ;; esac
(excerpt ends :787; enclosing _snap_remote() continues to :798 — read)
```

Git instead resolves a relative remote against the working tree of the repo whose config holds it. `relremote.sh` (cwd `$SP/iter3-r3`, 2026-09-27T23:59:49Z, exit 0) sets up an embedded repo `co/sub` with `remote.origin.url=./hooked.git` and a bare repo at `co/sub/hooked.git`, all at baseline. The session plants `co/sub/hooked.git/hooks/post-receive`. Output: `scan status=0`, then `host push from sub ran planted hook: YES`. The scan walked `co/hooked.git`, which does not exist, and never looked at `co/sub/hooked.git`. That bare repo is not named `.git`, so the working-tree `-name .git` find misses it too. This is not in LIMITS (`:590-603`) or the guide's limits list. The fix is to pass the owning working tree (`_snap_worktree_of "$f"`) into `_snap_remote` for relative paths.

**Evidence:** `devcontainer-config/cc-isolated.sh:550-564`, `:771-798`, `:831-840`, `:1080-1089`; `guides/cc-isolated-usage.md:218-226`; `$SP/iter3-r3/relremote.log`

---

## Claim 4: "every git dir nested in one at modules/** or worktrees/*, found by its HEAD … each directory holding HEAD next to objects/ or a commondir file, at any depth"

**Location:** `devcontainer-config/cc-isolated.sh:552-555`, `:956-971`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers submodule git dirs, linked-worktree git dirs, and not mistaking refs, logs or a branch named `hooks`/`config` for git files. It does not establish that no contrived ref layout could create a false git dir, and it does not cover git dirs outside `modules/` and `worktrees/` that no `.git` entry names.
**Legibility-target:** for-orchestrator-synthesis

```bash
# devcontainer-config/cc-isolated.sh:966-970
  _snap_find "$list" "$real" -mindepth 2 -name HEAD || return 1
  while IFS= read -r -d '' f; do
    g="${f%/*}"
    if [ -d "$g/objects" ] || [ -f "$g/commondir" ]; then _snap_gitdir "$g" || return 1; fi
  done < "$list"
```

`logs/HEAD` is filtered out because its parent has neither `objects/` nor `commondir`. The bats cases N5, N6, N7 and P6 pass at a42e37f and fail against a958372's scan (Claim 29). No false negative turned up: a real git dir always has `objects/` (or `commondir` in a linked worktree).

A theoretical false positive exists, inferred from the code and not run: branches `x/HEAD` and `x/objects/y` inside a *submodule* make `modules/<n>/refs/heads/x/` look like a git dir. Its missing hooks dir would then be recorded as a new item, giving a false exit 3. That needs deliberately named refs.

**Evidence:** `devcontainer-config/cc-isolated.sh:956-971`, `:977-1040`; `test/cc-isolated-functions.bats` (N5, N6, N7, P6); `$SP/iter3-r3/cci-bats.log`, `old-a958372.log`

---

## Claim 5: "your own global/system config, read with its includes evaluated for each git dir (includeIf gitdir:/gitdir/i: matched here; onbranch:/hasconfig: taken as matching)"

**Location:** `devcontainer-config/cc-isolated.sh:564-568`, `:845-891`, `:893-936`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers 23 `gitdir:`/`gitdir/i:`/`onbranch:` patterns against a top-level repo and a linked worktree, compared with git 2.39's own `includeIf` evaluation. It does not establish agreement for gitdir paths through symlinks, for embedded repos whose `.git` is a `gitdir:` file (there `lgd` is the file path, not git's logical gitdir), or for backslash escapes in patterns.
**Legibility-target:** for-orchestrator-synthesis

`cond.sh` (cwd `$SP/iter3-r3`, 2026-09-27T23:59:13Z, exit 0) sets each pattern as the host global `includeIf`. It then compares `git -C <repo> config x.y` with `_snap_cond`. Every row is `OK` or `over-walk`, and none is a miss where git includes and the scan does not. The rows cover:

- trailing `/`, no trailing `/`, `/.git`
- relative `co/`, `**/co/**`, `*`, `?`, and `[c]o` (bracket, so treated as matching)
- `gitdir/i:` uppercase against `gitdir:` uppercase
- `~/../`, `./../`
- `<ws>/.git/worktrees/`

The over-walks are `onbranch:main` (by design), and `gitdir:$B/par/wt/` and `gitdir:wt/` for the linked worktree. In that case `lgd` is the worktree's `.git` *file* path (`_snap_host_config "$_snap_gd" "$_snap_ws/.git" …`, `:1077`), which git does not match against. The docs call over-walking harmless.

**Evidence:** `devcontainer-config/cc-isolated.sh:873-891`, `:1077`, `:1088`; `$SP/iter3-r3/cond.log`, `cond.sh`

---

## Claim 6: "THE SCAN RUNS NOTHING FROM THE REPO … Config is read with `git config --file <f> --no-includes` from cwd /, so no repo is discovered … Everything else is find, stat, readlink and sha256sum; find never follows symlinks (-P), and a symlink's target is hashed only when it is a regular file."

**Location:** `devcontainer-config/cc-isolated.sh:577-583` (guide `guides/cc-isolated-usage.md:230-232`)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers which programs the scan starts and that none comes from the checkout. It does not establish bounded run time (see Claim 30).
**Legibility-target:** for-author

Every `git` call is `(cd / && git --no-pager config --file … --no-includes …)` or the global/system read from `/` (`:762`, `:807`, `:906`). `_snap_find` runs `find -P` (`:714`). `_snap_file` hashes only when `[ -f "$p" ]` (`:678`, `:690`). All of that matches the comment. The list "find, stat, readlink and sha256sum" is incomplete: the scan also starts `realpath` (`:734`, `:803`), `mktemp`, `cat`, `dirname`, `sort` (`:1101`), `awk`, `cut` and `tr` (`:1116-1131`, `:652`). All of them are host binaries. The precise version is "every other process is a standard host utility (find, stat, readlink, sha256sum, realpath, sort, awk …)". This is iteration-2 Claim 9a, still unchanged.

**Evidence:** `devcontainer-config/cc-isolated.sh:577-583`, `:652`, `:714`, `:734`, `:762`, `:807`, `:906`, `:1101`, `:1116-1131`

---

## Claim 7: "EVERY CONTAINER-CHOSEN STRING (names, values, error text) is reduced to printable ASCII, newlines included, before it reaches the terminal"

**Location:** `devcontainer-config/cc-isolated.sh:585-588`, `:1104-1107` (guide `guides/cc-isolated-usage.md:232-234`)
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `no git config at …` error path. It does not establish any other unsanitised path: `_snap_fail`, the %q report records and the C-record replacement were read and hold.
**Legibility-target:** for-author

This message is written with a bare `echo` and bypasses `_snap_fail`:

```bash
# devcontainer-config/cc-isolated.sh:1065-1068
  if [ ! -f "$_snap_common/config" ]; then
    echo "no git config at $_snap_common/config" >&2
    return 1
  fi
(excerpt ends :1068; enclosing git_exec_snapshot() continues to :1102 — read)
```

`_snap_common` is `pwd -P` of whatever `commondir` names, so a symlink can make it resolve to a directory whose name holds a newline. The exit path prints the reason through `sed 's/^/    /'` and then `scan_vis`, which keeps `\n` (`:1109`). `nl.sh` (cwd `$SP/iter3-r3`, 2026-09-27T23:58:45Z, exit 0) plants `.git/commondir` = `lnk`, where `lnk` points at `x\n  FORGED: nothing changed, the scan found no problems`. The warning prints that text as its own line:

```
    no git config at …/co/.git/x
      FORGED: nothing changed, the scan found no problems/config
```

The status is still 2 (exit 4), so the outcome is not hidden. The launch path has the same exposure (`:1279`). Iteration-2 Claim 10 is therefore only partly resolved. The fix is to route this echo, and the one at `:1059`, through `_snap_fail`.

**Evidence:** `devcontainer-config/cc-isolated.sh:585-588`, `:1065-1068`, `:1104-1110`, `:1141-1152`, `:1277-1283`; `$SP/iter3-r3/nl.log`, `nl.sh`

---

## Claim 8: LIMITS "No finding does not mean safe: a hook present at launch that runs a tracked file …; anything present at launch is the baseline …; the container keeps running after claude exits …; tracked .gitattributes and .gitmodules are not scanned"

**Location:** `devcontainer-config/cc-isolated.sh:590-603` (guide `guides/cc-isolated-usage.md:236-257`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers that every iteration-2 Incorrect is now either fixed (bats, Claim 29) or named here: the husky/pre-commit/`exec ./scripts/check.sh` route and host-config drivers selected by tracked attributes. It does not establish completeness. The embedded-repo relative remote (Claim 3) and time-based denial of service (Claim 30) are not listed. The guide frames its list as "Known routes", so the omission is not an overclaim.
**Legibility-target:** for-orchestrator-synthesis

The comment now opens "No finding does not mean safe:" and names the tracked-file hook route: "(husky's core.hooksPath=.husky/_, the pre-commit framework, `exec ./scripts/check.sh`)" (`:591-593`). It also names baseline plants, post-scan processes and a killed launcher. The header calls the scan a TRIPWIRE: "It cannot be complete (see LIMITS): a clean scan is not permission to run git in the checkout" (`:547-548`). The guide mirrors this and adds "Host programs pointed at the checkout" (`:255-257`), which also covers `.lfsconfig` read by a git-lfs hook that was present at launch. That lfs route is inferred and was not run.

**Evidence:** `devcontainer-config/cc-isolated.sh:544-548`, `:590-603`; `guides/cc-isolated-usage.md:236-257`

---

## Claim 9: "SIZE. This block brings cc-isolated.sh to about 1360 lines."

**Location:** `devcontainer-config/cc-isolated.sh:605`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the line count at a42e37f. It does not establish the stated reason for keeping the block inline.
**Legibility-target:** for-orchestrator-synthesis

`wc -l devcontainer-config/cc-isolated.sh` prints `1359` (cwd `$SP/iter3-r3/repo`, 2026-09-27T23:47Z, exit 0). f35381f's note "~1370 lines" is slightly high, and 0a4862b corrected the comment.

**Evidence:** `devcontainer-config/cc-isolated.sh:605`; the command output is recorded in this report only, because the `wc` call had no separate log

---

## Claim 10: "`git -c core.hooksPath=/dev/null -c core.fsmonitor=false push` is NOT a safe alternative: it still runs remote.*.receivepack, a repointed remote's hooks, filters, includes, credential helpers and core.sshCommand."

**Location:** `devcontainer-config/cc-isolated.sh:1174-1176`; `guides/cc-isolated-usage.md:167-170`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the "filters" atom only. A push ran no planted clean, smudge or process filter. The conclusion ("not a safe alternative") and the receivepack, repointed-remote and sshCommand atoms are not re-tested here. The error is in the cautious direction.
**Legibility-target:** for-author

`probes/p5.sh` (cwd `$SP/iter3-r3/probes`, 2026-09-28T00:02:06Z, exit 0) plants `filter.x.clean`, `filter.x.smudge` and `filter.x.process`, plus `* filter=x` in `info/attributes`. It then runs exactly `git -c core.hooksPath=/dev/null -c core.fsmonitor=false push -q up main` against a local bare repo. Result: `push rc=0 markers=[]`. The same `-c` flags on `git status` gave `markers=[process ]`. Push does not touch the working tree, so it runs no filter. "includes" is a config source, not a program. The precise wording would drop "filters" and say "planted includes can supply any of these".

**Evidence:** `devcontainer-config/cc-isolated.sh:1174-1176`; `guides/cc-isolated-usage.md:167-170`; `$SP/iter3-r3/probes/p5.log`, `probes/p5.sh`

---

## Claim 11: "cc-push never runs git in the checkout." (header "cc-push never runs git in the checkout. It keeps a BARE clone …"; guide "and never runs git in the checkout")

**Location:** `devcontainer-config/cc-push.sh:25-26`; `guides/cc-isolated-usage.md:172-174`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that no git *command* is started with the checkout as its repo or cwd. It does not establish that git reads nothing there: upload-pack does (Claim 14b), and both documents say so in the next step.
**Legibility-target:** for-author

cc-push's own git calls are `hgit "$clone" …` (`git -C "$c"`, `:69`), plus `git init -q --bare "$clone"` (`:124`) and `git check-ref-format` (`:157`). The checkout is found by plain `[ -e "$d/.git" ]` tests (`:78`). `probes/p3b.sh` (2026-09-27T23:56:10Z, exit 0) breaks the checkout's config (`git status in broken checkout rc=128`). With cwd inside the checkout, `git check-ref-format` still returns `rc=0` and `git init --bare` returns `rc=0`, so neither discovers or reads the checkout. The fetch (`:146-147`) and `ls-remote` (`:153`), however, make git start `git-upload-pack` *in* the checkout, as step 1 of the same comment says (`:27-29`). The precise version is "cc-push starts no git command in the checkout. Its fetch has git run upload-pack there, which only reads."

**Evidence:** `devcontainer-config/cc-push.sh:25-29`, `:69`, `:74-82`, `:124`, `:146-157`; `$SP/iter3-r3/probes/p3b.log`

---

## Claim 12: "Whatever the caller's environment points git at, cc-push chooses the repos." (`unset GIT_DIR GIT_WORK_TREE GIT_COMMON_DIR GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_NAMESPACE GIT_CEILING_DIRECTORIES`)

**Location:** `devcontainer-config/cc-push.sh:46-48`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the repository-selecting variables. It does not cover GIT_CONFIG_PARAMETERS/COUNT, GIT_CONFIG_GLOBAL, GIT_SSH_COMMAND or GIT_EXEC_PATH, which stay in force. Those are the host user's own environment, which the container cannot set.
**Legibility-target:** for-orchestrator-synthesis

```bash
# devcontainer-config/cc-push.sh:47-48
unset GIT_DIR GIT_WORK_TREE GIT_COMMON_DIR GIT_INDEX_FILE GIT_OBJECT_DIRECTORY \
      GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_NAMESPACE GIT_CEILING_DIRECTORIES
```

Every later call names its repo explicitly: `git -C "$c"` or `git init --bare "$clone"`.

**Evidence:** `devcontainer-config/cc-push.sh:46-48`, `:67-70`, `:124`

---

## Claim 13: "Every git call here passes core.hooksPath=/dev/null and core.fsmonitor=false, so your own global config cannot point hooks at anything either."

**Location:** `devcontainer-config/cc-push.sh:33-34`; `guides/cc-isolated-usage.md:194-195`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the calls cc-push makes itself. It does not reach the processes git starts on the far side of a local transport: upload-pack in the checkout, or receive-pack on a local-path origin.
**Legibility-target:** for-author

Two calls skip `hgit`: `git init -q --bare "$clone"` (`:124`) and `git check-ref-format "refs/heads/$branch"` (`:157`). Neither runs hooks or fsmonitor. p3b shows neither reads the checkout (Claim 11), and hooksPath is written into the clone's own config right after init (`:125`). The `-c` values also do not cross a local transport. In P1, with the user's global `core.hooksPath` set, the local upstream's `post-update` and `reference-transaction` hooks fired during `hgit … push` (`markers=[g-hook-post-update g-hook-reference-transaction ]`). They did not fire in the clone. With a real remote (ssh/https) those are server-side hooks. The precise version is "every git call that touches the clone …".

**Evidence:** `devcontainer-config/cc-push.sh:33-34`, `:67-70`, `:124-127`, `:157`, `:197`; `$SP/iter3-r3/probes/p1.log`, `probes/p3b.log`

---

## Claim 14a: "`git fetch <checkout>` — git runs upload-pack in the checkout, which … runs no hook, no fsmonitor, no filter, and ignores uploadpack.packObjectsHook from repo config. Nothing is checked out."

**Location:** `devcontainer-config/cc-push.sh:27-29`; `guides/cc-isolated-usage.md:182-185`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5 with the bats plant set, plus alternates with alternateRefsCommand, a `gitdir:` file and a symlinked checkout. It does not establish other git versions.
**Legibility-target:** for-orchestrator-synthesis

The command is `hgit "$clone" -c protocol.file.allow=always fetch -q --no-tags --no-recurse-submodules --no-write-fetch-head --prune "$co" '+refs/heads/*:refs/cc/heads/*'` (`:146-147`), into a bare clone. bats case 2 (with `uploadpack.packObjectsHook "touch $M/packobjectshook"`, `test/cc-push.bats:68`) passes with no marker. P2a adds alternates so that `core.alternateRefsCommand` is reachable: `markers=[]`.

**Evidence:** `devcontainer-config/cc-push.sh:141-149`; `test/cc-push.bats:46-116`; `$SP/iter3-r3/cc-push-bats.log`, `probes/p2.log`, `probes/p4.log`

---

## Claim 14b: "upload-pack … reads its refs, objects and config" (and guide "reads its refs, objects and config but runs no hook")

**Location:** `devcontainer-config/cc-push.sh:27-28`; `guides/cc-isolated-usage.md:182-184`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what upload-pack reads and how far that reach goes. It does not rate the likelihood of the exfiltration shape: the container must know the host path and the object ID. It also does not establish other blocking file types.
**Legibility-target:** for-author

upload-pack also follows the checkout's `objects/info/alternates` and a `.git` `gitdir:` file to **any host path**. Objects found there are fetched into the clone and can be pushed:

- **P2a** (2026-09-27T23:55:44Z, exit 0). The checkout's alternates name a host-only repo `$T/secret`, and a hand-written `refs/heads/leak` names its commit. cc-push then prints `origin has no branch leak; commits not on any origin branch: 9c106fd …: host secret` and pushes it: `upstream has secret commit: commit`.
- **P4a** (2026-09-27T23:56:59Z). The checkout's `.git` is replaced by `gitdir: $T/other/.git`. cc-push previews `other host repo` from that unrelated repo, then dies at the diff stat (Claim 17).
- **P4b.** `include.path` names a FIFO in the checkout's `.git`, and cc-push hangs until `timeout 10` (`rc=124`).

c3d9223's Notes record the gitdir/alternates reading ("reads only"). Neither document mentions it. The preview (and the prompt when `--yes` is not given) is the only guard. The precise version is "reads its refs, objects and config, and any object store or git dir its `.git` file or alternates name, anywhere on the host".

**Evidence:** `devcontainer-config/cc-push.sh:27-29`, `:146-147`; `guides/cc-isolated-usage.md:182-185`; `$SP/iter3-r3/probes/p2.log`, `probes/p4.log`

---

## Claim 15: "vis: control bytes (and anything outside printable ASCII) as '?', so a commit message or branch name the session wrote cannot rewrite the terminal."

**Location:** `devcontainer-config/cc-push.sh:54-58` (guide `guides/cc-isolated-usage.md:188`, "control bytes as `?`")
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers commit subjects and author names, which are always piped through `vis`. It does not cover the branch name on four unsanitised lines, or git push's own output.
**Legibility-target:** for-author

The `log` and `diff --stat` output is piped through `vis` (`:178-179`, `:182`), and bats case 7 shows ESC appearing as `?`. The branch name, which `ls-remote --symref` takes from the container's HEAD, is printed raw here:

```bash
# devcontainer-config/cc-push.sh:169-170
  echo "Push $src ($co)"
  echo "  to origin ($remote) as $branch."
```

It is also printed raw at `:177` and `:181`. `check-ref-format` rejects bytes below 0x20 and DEL, but not 0x80-0xFF. p3c under `LC_ALL=C` (2026-09-27T23:56:24Z, exit 0) uses a branch `x\2332Jy` (0x9b is the C1 CSI byte). Its output shows `Push refs/cc/heads/xM-^[2Jy` raw, while the final `vis`'d line reads `Pushed x?2Jy`. Under a UTF-8 locale, the `sed` at `:153` drops such a name and cc-push stops with "detached?" (p3b). Only terminals that act on 8-bit C1 controls are affected.

**Evidence:** `devcontainer-config/cc-push.sh:54-58`, `:153`, `:169-182`; `test/cc-push.bats:156-163`; `$SP/iter3-r3/probes/p3c.log`, `probes/p3b.log`

---

## Claim 16: "--clone DIR the host-only clone (default: $CC_PUSH_CLONES_DIR/<name>-<id>, CC_PUSH_CLONES_DIR defaulting to ~/.local/share/cc-isolated/clones)"

**Location:** `devcontainer-config/cc-push.sh:15-16`; `guides/cc-isolated-usage.md:172-174`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the default path computation. It does not establish anything about the clone's contents.
**Legibility-target:** for-author

```bash
# devcontainer-config/cc-push.sh:109
    clone="${CC_PUSH_CLONES_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/cc-isolated/clones}/$name-$id"
```

When `XDG_DATA_HOME` is set, the default is `$XDG_DATA_HOME/cc-isolated/clones`, not `~/.local/share/…`.

**Evidence:** `devcontainer-config/cc-push.sh:15-16`, `:105-110`

---

## Claim 17: "Exit codes: 0 pushed (or nothing to push), 1 usage or setup error, 2 declined."

**Location:** `devcontainer-config/cc-push.sh:42`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the paths exercised below. It does not enumerate every git failure under `set -e`.
**Legibility-target:** for-author

Confirmed outcomes:

- 0 on a push (bats 1).
- 2 on a decline (bats 5).
- 1 for missing `--remote` (bats 4) and for a bad origin (p3 `bad-origin rc=1`).

The list leaves out or mislabels two cases:

- **Remote refusal.** A remote-rejected push returns 1 (p3c `non-ff rc=1`; p3d `push-failure rc=1`, `! [remote rejected]`). That is a refusal, not a "usage or setup error".
- **Git failure under `set -e`.** An unhandled git failure exits with git's own code: P4a unrelated histories give `fatal: … no merge base` and `rc=128` from `diff --stat "$base...$src"` (`:179`). The same applies to failures at `:124-127`.

The header's exit-code line is also not in `--help`, because `usage` prints only lines 2-38 (`sed -n '2,38p'`, `:51`). That output stops mid-sentence at ":38 … there, the fetched" (p3 `grep -c 'Exit codes'` → `0`).

**Evidence:** `devcontainer-config/cc-push.sh:42`, `:50-52`, `:179`, `:197`; `test/cc-push.bats:131-143`; `$SP/iter3-r3/probes/p3.log`, `probes/p3d.log`, `probes/p4.log`

---

## Claim 18: "The clone: created here, bare, marked with the checkout it serves. A directory cc-push did not create is never used (it could be a working tree with hooks)." / clone inside the checkout refused

**Location:** `devcontainer-config/cc-push.sh:111-138`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the inside-checkout refusal (realpath, so symlinks are resolved) and refusal of a directory that has no marker. It does not establish provenance: the test is the marker file's content, not who created the directory.
**Legibility-target:** for-author

```bash
# devcontainer-config/cc-push.sh:131-133
    [ -f "$clone/cc-push-checkout" ] || die "$clone exists but was not made by cc-push; pick another --clone"
    [ "$(cat "$clone/cc-push-checkout")" = "$co" ] \
      || die "$clone serves $(cat "$clone/cc-push-checkout"), not $co; pick another --clone"
(excerpt ends :133; enclosing main() continues to :199 — read)
```

bats 6 passes: "inside the checkout" gives exit 1, and a foreign `git init` directory gives "not made by cc-push". Any existing directory whose `cc-push-checkout` file holds the checkout path is used, whether or not cc-push made it. The default location is host-only, so the practical exposure is low. The precise version is "a directory without cc-push's marker for this checkout is never used".

**Evidence:** `devcontainer-config/cc-push.sh:111-138`; `test/cc-push.bats:145-154`; `$SP/iter3-r3/cc-push-bats.log`

---

## Claim 19: "protocol.file.allow=always: a global 'never' (which the guide suggests for other pushes) would refuse this one fetch that has to be local."

**Location:** `devcontainer-config/cc-push.sh:144-145`
**Type:** Reference
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the parenthetical reference to the guide. It does not question the override's function.
**Legibility-target:** for-author

`grep -rn 'protocol.file' guides/ devcontainer-config/ docs/decisions/` at a42e37f hits only cc-push.sh. The guide at 02d14b0 had "Adding `-c protocol.file.allow=never` refuses a push to a local-path remote …" (`guides/cc-isolated-usage.md:217` at 02d14b0). 0a4862b removed it, and it was a per-command `-c`, not a global setting.

**Evidence:** `devcontainer-config/cc-push.sh:144-145`; `git show 02d14b0:guides/cc-isolated-usage.md` (`:217`); `git show 0a4862b -- guides/cc-isolated-usage.md`

---

## Claim 20: "Preview. --no-ext-diff/--no-textconv: no diff program runs on the session's files; --no-show-signature: no gpg on its signatures; output is plain text." / cc-push pushes what it showed

**Location:** `devcontainer-config/cc-push.sh:166-199`; `guides/cc-isolated-usage.md:188-192`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers host-global pager, gpg, textconv, external diff and attributes during the preview, and that the pushed ref is the one previewed. It does not cover git ≥2.42's `attr.tree` default. That was inferred as inert, because the clone's HEAD stays unborn under both refspecs.
**Legibility-target:** for-orchestrator-synthesis

P1 sets host-global `core.pager`, `pager.log`, `pager.diff`, `log.showSignature`+`gpg.program`, `diff.external`, and `diff.x.textconv`/`command` with a global `core.attributesFile` of `* diff=x`. None of those markers fired. The preview calls are `hgit "$clone" --no-pager log --no-show-signature --format=…` and `--no-pager diff --no-ext-diff --no-textconv --stat` (`:178-179`).

Nothing touches `refs/cc/heads/$branch` between the preview and `hgit "$clone" push origin "$src:refs/heads/$branch"` (`:197`). The only fetches, at `:146` and `:163`, both happen earlier, so the push sends the previewed ref. It never forces: the refspec has no `+` and there is no `-f`. bats 9 and p3c pass.

**Evidence:** `devcontainer-config/cc-push.sh:163-199`; `test/cc-push.bats:177-184`; `$SP/iter3-r3/probes/p1.log`, `probes/p3.log`

---

## Claim 21: "the real remote, stored in the host-only clone (never read from the checkout). Needed the first time; given again, it replaces it." / "cc-push never reads remotes from the checkout"

**Location:** `devcontainer-config/cc-push.sh:12-13`, `:120-122`; `guides/cc-isolated-usage.md:186-187`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers cc-push's choice of push and fetch targets. It does not claim that upload-pack leaves the checkout's `remote.*` config unparsed; it parses it but uses none of it.
**Legibility-target:** for-orchestrator-synthesis

The URL comes only from `--remote` into `hgit "$clone" config remote.origin.url` (`:126`, `:135`) and is read back from the clone (`:139`). The checkout is addressed by path (`"$co"`, `:147`, `:153`). bats 2 repoints the checkout's origin at `evil.git` and asserts `[ "$(git -C "$T/evil.git" for-each-ref | wc -l)" -eq 0 ]`. bats 4 (no `--remote` on first use) gives exit 1 and creates nothing.

**Evidence:** `devcontainer-config/cc-push.sh:119-139`; `test/cc-push.bats:104-116`, `:131-136`; `$SP/iter3-r3/cc-push-bats.log`

---

## Claim 22: install.sh: "cc-isolated and cc-push linked into $CLAUDE_DEVC_BIN_DIR"; "The manifest hashes it like the launcher."

**Location:** `devcontainer-config/install.sh:35-36`, `:110`, `:596-603`
**Type:** Configuration / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers PAYLOAD membership, chmod, the link, and enforcement_files hashing. It does not establish a live install on a real host.
**Legibility-target:** for-orchestrator-synthesis

`PAYLOAD=(… cc-isolated.sh cc-push.sh …)` (`:110`). The install step runs `ln -sf "$DEST/cc-push.sh" "$BIN_DIR/cc-push"` (`:602`). `enforcement_files` echoes `"cc-push.sh"` (`devcontainer-config/cc-isolated.sh:117`). `test/install-host.bats:207-211` asserts the link, its target and `-x`. The cc-isolated-functions case "every regular file in install.sh's PAYLOAD is hashed by enforcement_files" passes. The combined set run (2026-09-27T23:53:46Z, exit 0) is 307/307.

**Evidence:** `devcontainer-config/install.sh:35-36`, `:110`, `:596-603`; `devcontainer-config/cc-isolated.sh:108-117`; `test/install-host.bats:207-213`; `$SP/iter3-r3/set307.log`

---

## Claim 23: decision log 53 amendment: "hooks/wiring.json adds Bash(*.credentials.json*), and the hook reads Bash deny rules itself and never approves a match … a spelling without the literal name … still gets through; each of those three spellings is pinned by a test. In a deny rule only * is a wildcard, and a bare Bash deny rule blocks all approval."

**Location:** `docs/decisions/log.md:76` (also `guides/bare-host-hook-wiring.md:151-156`, `hooks/wiring.json:37-44`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the hook's deny matching: no regression since iteration 2 (the hook is byte-identical between 02d14b0 and a42e37f). It does not verify Claude Code's own handling of deny rules or #39344.
**Legibility-target:** for-orchestrator-synthesis

`hookprobe.sh` (2026-09-28T00:00:22Z, exit 0) runs with `Bash(echo:*)` and `Bash(cat:*)` allowed:

- `$(( ))` credential exfiltration with the deny rule → falls through (empty decision); without the rule → `allow`.
- `Bash(cat notes[1].txt)` blocks the literal command, so `[` is not a glob.
- `Bash(cat notes?.txt)` leaves `notesX.txt` → `allow`, so `?` is literal.
- A bare `Bash` rule → falls through.
- The quote-split spelling → `allow` (the documented bypass).

The three spelling tests are `test/auto-approve-allowed-commands.bats:178`, `:189` and `:197`. The hook suites pass 58/58 (2026-09-27T23:54:00Z, exit 0).

**Evidence:** `docs/decisions/log.md:76`; `hooks/auto-approve-allowed-commands.sh:113-167`, `:260-267`; `test/auto-approve-allowed-commands.bats:120-245`; `$SP/iter3-r3/hookprobe.log`, `hooks.log`

---

## Claim 24: "What a launch does, in order … 7. … Before step 4 the launcher snapshots what host git reads to decide what to run (…); when claude exits it compares, and exits 3 naming anything … It exits 4 when the exit scan cannot list or read any of it, and refuses to launch when the baseline snapshot cannot be taken. The scan is a tripwire, not a guarantee"

**Location:** `guides/cc-isolated-usage.md:52-59`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers ordering, the 3/4/refuse mapping and the tripwire framing. It does not establish the completeness of "what host git reads" (Claim 3).
**Legibility-target:** for-orchestrator-synthesis

The snapshot at `devcontainer-config/cc-isolated.sh:1271-1288` runs before `devcontainer up` (`:1306`). `case "$scan" in 0) exit "$rc" ;; 1) exit 3 ;; *) exit 4 ;; esac` is at `:1349-1353`. The launch refusal is `exit 1` at `:1285`. The bats launcher cases pass (139/139).

**Evidence:** `guides/cc-isolated-usage.md:52-59`; `devcontainer-config/cc-isolated.sh:1271-1288`, `:1343-1353`; `$SP/iter3-r3/cci-bats.log`

---

## Claim 25: "`test/cc-push.bats` plants hooks (every name), fsmonitor, clean/smudge/process filters, receive-pack and upload-pack commands, uploadpack.packObjectsHook, core.alternateRefsCommand, core.sshCommand, core.gitProxy, a credential helper, includes, a legacy remotes file and a repointed origin in the checkout, and asserts that a cc-push fires none of them and pushes the fetched commit (git 2.39)."

**Location:** `guides/cc-isolated-usage.md:195-200`
**Type:** Reference / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the test plants and asserts. It does not establish anything about other git versions.
**Legibility-target:** for-author

Every listed item is in `plant_all` (`test/cc-push.bats:46-86`), case 2 asserts no markers and the pushed SHA, and the local git is 2.39.5. "Every name" overstates the hook list. It has 17 names (`pre-push pre-commit post-checkout … pre-upload upload-pack`, `:48-50`) and leaves out, for example, `commit-msg`, `prepare-commit-msg`, `pre-rebase`, `pre-merge-commit`, `applypatch-msg`, `sendemail-validate` and `proc-receive`. None of those runs on fetch or push, so the practical conclusion holds. As planted, `alternateRefsCommand` is inert because there are no alternates. P2a covers the live form.

**Evidence:** `guides/cc-isolated-usage.md:195-200`; `test/cc-push.bats:46-86`, `:104-116`; `$SP/iter3-r3/cc-push-bats.log`, `probes/p2.log`

---

## Claim 26: "It records, for every git dir it reaches … every local-path remote … It follows what those configs name: … local-path remotes inside the checkout (`remote.*.url`/`pushurl`, …, `file://localhost/`, relative paths such as `sub/a:b`)."

**Location:** `guides/cc-isolated-usage.md:216-226`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the relative-remote atom for embedded repos, which is the same defect as Claim 3. The iteration-2 shapes (pushRemote, insteadOf, `file://localhost/`, `sub/a:b`, legacy remotes) are covered and pass: N2, N3 and N4 fail on a958372 and pass now.
**Legibility-target:** for-author

This is the guide's copy of the code comment in Claim 3. `relremote.log`: an embedded repo's `./hooked.git` is resolved against the top-level checkout, the scan gives `status=0`, and the hook runs on a host push from `sub`.

**Evidence:** `guides/cc-isolated-usage.md:216-226`; `devcontainer-config/cc-isolated.sh:786-787`; `$SP/iter3-r3/relremote.log`, `old-a958372.log`

---

## Claim 27: "Tracked `.gitattributes` and `.gitmodules`. Not scanned. An attribute selects a driver that config defines (config is scanned)"

**Location:** `guides/cc-isolated-usage.md:252-254` (also `devcontainer-config/cc-isolated.sh:601-603`)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers which config the "(config is scanned)" clause covers. It does not assess whether a host-defined driver can be abused.
**Legibility-target:** for-author

Repo configs are hashed, but host global/system config entries are **not recorded**. The code comment says so: "Entries are not recorded (the container cannot write these files …)" (`devcontainer-config/cc-isolated.sh:897-899`). So a tracked attribute that selects a driver defined only in the host's global config, such as `filter.lfs.*`, runs that host-defined command on session-written content with no scan finding. This is iteration-2 Claim 27b, now reduced to a qualifier. The precise version is "(repo config is scanned; your global config is yours)".

**Evidence:** `guides/cc-isolated-usage.md:252-254`; `devcontainer-config/cc-isolated.sh:893-936`

---

## Claim 28: live-verify-gate: "The enforcement set: what cc-isolated.sh's enforcement_files() hashes, as repo paths. Keep in step with that function." + 4435c73 "the gate's path regex was not kept in step, so … 'every manifest-hashed file is in the enforcement set' failed on the integration branch"

**Location:** `hooks/live-verify-gate.sh:70-73`; commit 4435c73
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers cc-push.sh membership and the test's failure before the fix. It does not establish the gate's live behavior in Claude Code.
**Legibility-target:** for-orchestrator-synthesis

At a42e37f, `bats test/hooks/live-verify-gate.bats` passes. That run is part of the 58/58 hook suites. With `hooks/live-verify-gate.sh` swapped for `4435c73^` in a scratch clone (2026-09-28T00:02:39Z, exit 1), the output is `not ok 8 every manifest-hashed file is in the enforcement set`.

**Evidence:** `hooks/live-verify-gate.sh:70-73`; `devcontainer-config/cc-isolated.sh:117`; `$SP/iter3-r3/gate-pre4435c73.log`, `hooks.log`

---

## Claim 29: Commit messages f35381f and c3d9223: "14 new bats cases … All 14 fail against a958372's cc-isolated.sh and pass here; the 125 existing cases still pass. cc-isolated-functions 139/139; with install-host, fixture-hermeticity, hermeticity-lint, cc-push, guide-index-sync, cross-reference-integrity, function-inventory: 307/307. shellcheck -S warning clean." / "test/cc-push.bats (9 cases)"

**Location:** commits `f35381f`, `c3d9223`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the counts and shellcheck on the named files at a42e37f. It does not re-run the suite at each commit's own tree.
**Legibility-target:** for-orchestrator-synthesis

The runs, with cwd `$SP/iter3-r3/repo` unless noted:

- `bats test/cc-isolated-functions.bats`: 139 ok, exit 0.
- `bats test/cc-push.bats`: 9 ok.
- The eight-suite set: `1..307`, 307 ok, exit 0.
- `shellcheck -S warning` on `devcontainer-config/cc-push.sh`, `devcontainer-config/cc-isolated.sh`, `test/cc-push.bats` and `test/cc-isolated-functions.bats`: each exit 0. The full default-severity run exits 1 with info/style notes only, such as SC2016, SC2015 and SC2317.
- With a958372's `cc-isolated.sh` in a scratch clone (`$SP/iter3-r3/old`, 2026-09-27T23:54:38Z): exactly the 14 new cases fail (N2×2, N3, N4, N5, N6, N7, N11, N12, N13, P1×2, P6, working-tree unlistable). The `diff` of `@test` names from a958372 to f35381f shows the same 14. One more case fails there: case 72, the PAYLOAD check. That is an artifact of combining the old launcher with the newer install.sh, not a regression.

**Evidence:** `$SP/iter3-r3/cci-bats.log`, `cc-push-bats.log`, `set307.log`, `shellcheck.log`, `old-a958372.log`

---

## Claim 30: f35381f "Snapshot of /workspace (with 5 linked worktrees) takes about 5 s."

**Location:** commit `f35381f`
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers /workspace as it is now. It does not bound adversarial checkouts: run time grows with the number of embedded repos and the size of hashed files, both of which the container chooses.
**Legibility-target:** for-author

`git -C /workspace worktree list` shows 6 entries (main plus 5). `perf.sh` (`git_exec_snapshot /workspace`, 2026-09-27T23:58:20Z, rc 0, 570 records) took 4.20 s and then 2.38 s.

The pathological cases, inferred from these measurements and not run at full scale:

- **Embedded repos.** 300 embedded repos took 8.66 s (`many.log`, about 27 ms each), so 10,000 would take about 5 minutes.
- **Large hashed file.** `sha256sum` reads a 2 GB sparse file in 6.57 s (`sparse.log`). A sparse 1 TB file planted as a hook or config (`_snap_hash`, `:660`) would take about 55 minutes at session exit and again at the next launch.

The scan has no timeout. This is a denial-of-service shape, not a bypass, and it is not in LIMITS.

**Evidence:** `devcontainer-config/cc-isolated.sh:657-665`, `:1080-1089`; `$SP/iter3-r3/perf.log`, `many.log`, `sparse.log`

---

## Claims Requiring Attention

### Incorrect
- **Claim 3** (`devcontainer-config/cc-isolated.sh:550-564`, `:786-787`): a relative local remote in an embedded repo's config is resolved against the top-level checkout. After a planted hook the scan returned 0, and a host push inside the embedded repo ran the hook. Fix: resolve against the owning working tree.
- **Claim 7** (`devcontainer-config/cc-isolated.sh:585-588`, `:1066`): `echo "no git config at $_snap_common/config"` bypasses `_snap_fail`. A symlinked common dir whose name holds a newline forged a line in the exit-4 warning, and the launch path has the same exposure.
- **Claim 10** (`devcontainer-config/cc-isolated.sh:1174-1176`, `guides/cc-isolated-usage.md:167-170`): a hooks-off `git push` ran no planted filter. Drop "filters". The warning's conclusion stands.
- **Claim 26** (`guides/cc-isolated-usage.md:216-226`): the guide's "every local-path remote" has the Claim 3 gap.

### Stale
- **Claim 19** (`devcontainer-config/cc-push.sh:144-145`): "(which the guide suggests for other pushes)". 0a4862b removed that guide text, and it was a per-command `-c`, not a global setting.

### Mostly Accurate
- **Claim 6** (`cc-isolated.sh:577-583`): the scan also runs realpath, sort, awk, tr, cut, mktemp, cat and dirname. All are host binaries.
- **Claim 11** (`cc-push.sh:25`, guide `:172-174`): "never runs git in the checkout". Its fetch has git run upload-pack there.
- **Claim 13** (`cc-push.sh:33-34`, guide `:194`): `git init` and `git check-ref-format` skip `hgit`, and the `-c` values do not reach upload-pack or a local origin's receive-pack.
- **Claim 14b** (`cc-push.sh:27-28`, guide `:182-184`): upload-pack also follows the checkout's alternates and `gitdir:` file to any host path. A host-only commit was fetched and pushed, and a FIFO include hangs cc-push. Say so in the guide.
- **Claim 15** (`cc-push.sh:54-55`): the branch name is printed without `vis` at `:169-170`, `:177` and `:181`, and a C1 byte (0x9b) reaches the terminal under `LC_ALL=C`.
- **Claim 16** (`cc-push.sh:15-16`): the default clone directory honors `XDG_DATA_HOME`.
- **Claim 17** (`cc-push.sh:42`): a remote refusal returns 1, and git failures under `set -e` return 128 (unrelated histories at `:179`). `--help` omits the exit codes and truncates mid-sentence.
- **Claim 18** (`cc-push.sh:117-118`): the directory check is marker-based, not provenance-based.
- **Claim 25** (guide `:195`): "hooks (every name)" is 17 names.
- **Claim 27** (guide `:252-254`): "(config is scanned)". Host global config entries are not recorded.

### Unverifiable
- None.

---

## Goal-Alignment Note

- **Success criterion (restated verbatim):** A code-fact-check report saved at the dispatch path in the skill's schema, covering the claims above, with a Goal-Alignment Note.
- **Answered:**
  - **cc-push.** No planted or host-global exec vector fired: bats plus P1-P4 cover the brief's list, namely upload-pack config, alternates, `.git` file, symlinked checkout, `protocol.file.allow`, GIT_* environment, host global pager/gpg/textconv/diff.external/hooksPath, and a C1/`-` branch name. Remotes are never read from the checkout, and the push sends exactly what was previewed.
  - **cc-push defects.** It *reads* host repos named by the checkout's alternates or `gitdir:` file and can push their objects. A FIFO include hangs it. The exit-code list, the stale guide reference and the `vis` gaps are in Claims 15-19.
  - **install, manifest and gate.** Verified.
  - **Exit scan.** The iteration-2 Incorrects are resolved or listed as limits. The includeIf evaluation matches git in 23 patterns with no misses. There is one new bypass (Claim 3) and one newline-forging path (Claim 7), and run time is unbounded on adversarial input.
  - **Regressions.** None in hook deny matching, decision log 53 or the `.gitignore`/runner wording.
  - **Commit numbers.** All reproduce.
- **Out of scope:** `skills/*/SKILL.md` (pass 2). Git versions other than 2.39.5, including 2.42+ `attr.tree`, which was reasoned about but not run. A live container: whether Ctrl-C reaches claude through `devcontainer exec` is still unverified, as in iteration 2.
- **Escalate:**
  1. For security-reviewer: Claim 14b. cc-push can carry objects from other host repos into a push through the checkout's alternates or `gitdir:`. It is low-likelihood, since the container needs the host path and the object ID, and the preview shows the commits. It could be closed by refusing a checkout whose `.git` is a file or whose `objects/info/alternates` exists, checked with plain file tests.
  2. Claim 3, the new scan bypass (embedded-repo relative remote).
- **Questions I would have asked:** The brief mentions "401/401 set", but no commit in `main..a42e37f` states 401. The commits state 307/307, which reproduces. I assume 401 was the orchestrator's own run.
- **Decisions I made:**
  - Logs are under `$SP/iter3-r3/`, not `docs/reviews/execution-logs/`, per the brief's "never modify /workspace except your report".
  - I did not append to `docs/reviews/hallucination-patterns.md`, for the same reason. No fabrication was found anyway.
