Commit: a42e37f

# Code Fact-Check Report

**Repository:** /workspace (branch integrate/q076-q080)
**Scope:** pass-1 diff `git diff main...a42e37f -- . ':!skills'` (partial — excludes skills/, guides/skill-format-audit.md, docs/reviews/), plus commit messages `git log main..a42e37f` (focus: f35381f, c3d9223, 0a4862b, 4435c73). Replicate r2, iteration 3 (final). All execution in a scratch clone at a42e37f (`$SP/iter3-r2/clone`), never in /workspace.
**Checked:** 2026-09-27
**Total claims checked:** 27 (Claims 1-26, with Claim 7 split into 7a/7b)
**Summary:** 11 verified, 13 mostly accurate, 0 stale, 3 incorrect, 0 unverifiable

`$SP` = `/tmp/claude-1000/-workspace/dbfd30e0-d8d5-40c1-8bac-572239fc44fd/scratchpad`. All logs cited below are under `$SP/iter3-r2/`. Git 2.39.5, bats, shellcheck in the review sandbox. The sandbox's `LC_ALL=en_US.UTF-8` is not installed; runs marked `LC_ALL=C` set it to avoid a `setlocale` warning that otherwise breaks one stub-output assertion (Claim 22).

---

## Claim 1: "The way to push is cc-push (cc-push.sh, next to this file): it fetches into a separate host-only clone and pushes from there, and runs nothing from the checkout."

**Location:** `devcontainer-config/cc-isolated.sh:542-544`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that no hook, fsmonitor, filter, pager, diff driver, credential helper, ssh command, receive/upload-pack command or packObjectsHook planted in the checkout ran during cc-push on git 2.39 (bats plant set and extra plants below); does not establish that git's upload-pack does not *read* container-written state (it reads the checkout's config, includes, gitdir and alternates by design), nor behavior on other git versions.

Same claim also appears in the exit-scan warning (`cc-isolated.sh:1167-1168`: "running nothing from this checkout") and is repeated for cc-push in Claims 8 and 24. Nothing ran in: `bats test/cc-push.bats` (9/9, incl. "cc-push runs nothing planted in the checkout (full plant set)"); an extra run from *inside* the planted checkout (default `$PWD` discovery) with hooks, `core.fsmonitor`, `alias.check-ref-format`, `safe.directory=*` planted — `markers:` empty, `rc=0`; and a run where the checkout is reached through a symlink and its `.git` is a `gitdir:` file naming a renamed git dir with hooks — no marker. Precise version: "runs nothing *from* the checkout; git's upload-pack reads the checkout's refs, objects and config."

**Evidence:** `devcontainer-config/cc-isolated.sh:542-544`, `devcontainer-config/cc-isolated.sh:1167-1168`, `devcontainer-config/cc-push.sh:146-147`; `$SP/iter3-r2/bats-cc-push.log` (cmd `bats test/cc-push.bats`, cwd scratch clone, exit 0, 2026-09-27T23:47:58Z); `$SP/iter3-r2/cc-push-from-inside-checkout.log` (exit 0); `$SP/iter3-r2/cc-push-hostglobal.log` (2026-09-28T00:01:03Z, exit 0)
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 2: "every git dir nested in one at modules/** or worktrees/*, found by its HEAD" / "each directory holding HEAD next to objects/ or a commondir file, at any depth"

**Location:** `devcontainer-config/cc-isolated.sh:553-554`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the detection rule in `_snap_nested` (`find … -mindepth 2 -name HEAD`, then `[ -d "$g/objects" ] || [ -f "$g/commondir" ]`); does not establish absence of false negatives beyond git's own `is_git_directory` shapes (the rule is a superset: it does not require `refs/`), and shows one false-positive shape.

```bash
# devcontainer-config/cc-isolated.sh:969-973
  _snap_find "$list" "$real" -mindepth 2 -name HEAD || return 1
  while IFS= read -r -d '' f; do
    g="${f%/*}"
    if [ -d "$g/objects" ] || [ -f "$g/commondir" ]; then _snap_gitdir "$g" || return 1; fi
  done < "$list"
```
(excerpt ends :973; enclosing `_snap_nested` ends :974 — read)

Because the find runs over the *whole* `modules/` tree, refs and reflogs are searched too. Executed: in a checkout with one submodule, a session that only ran `git -C sub branch x/HEAD` and `git -C sub branch x/objects/y` produced exit-scan status 1 with two findings, `+ hooksdir …/.git/modules/sub/refs/heads/x/hooks missing` and `+ hooksdir …/.git/modules/sub/logs/refs/heads/x/hooks missing` — `refs/heads/x` holds a `HEAD` file next to an `objects/` directory. Contrived branch names, false exit 3 only (safe direction). No false negative found.

**Evidence:** `devcontainer-config/cc-isolated.sh:959-974`; `$SP/iter3-r2/fp-submodule-branch.log` (cmd `bash $SP/iter3-r2/exp5/run.sh` sourcing cc-isolated.sh, exit 0 of script, scan=1 printed, ~2026-09-27T23:59Z)
**Legibility-target:** for-author

---

## Claim 3: "your own global/system config, read with its includes evaluated for each git dir (includeIf gitdir:/gitdir/i: matched here; onbranch:/hasconfig: taken as matching)"

**Location:** `devcontainer-config/cc-isolated.sh:564-567`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `_snap_cond` against git 2.39's own evaluation for 13 patterns × {gitdir, gitdir/i} (absolute, trailing `/`, `**`, `~/`, `./`, relative, `?`, `*`, case); does not establish Windows/`%(prefix)` forms or patterns with bracket expressions (those return "matching" by design).

```bash
# devcontainer-config/cc-isolated.sh:880-897
  case "$cond" in
    gitdir:*)   pat="${cond#gitdir:}" ;;
    gitdir/i:*) pat="${cond#gitdir/i:}"; icase=1 ;;
    *) return 0 ;;
  esac
  ...
  re="$(_snap_glob_re "$pat")" || return 0
```
(excerpt elides :885-894; enclosing `_snap_cond` continues to :898 — read)

Compared with `git config user.name` inside a repo under `$T/w/Proj A/x`: 24 of 26 cases agree. One over-match (safe): `gitdir:$T/w**` git=nomatch, snap=match (`**` not bounded by `/` is `*` under WM_PATHNAME, the ERE uses `.*`). One **under-match** (false negative): a backslash-escaped pattern `gitdir:$T/w/Proj\ A/` git=match, snap=nomatch — `_snap_glob_re` emits `[\]` for `\`, requiring a literal backslash (`cc-isolated.sh:867`: `*) re+="[$c]" ;;`). Host-owned config only; niche.

**Evidence:** `devcontainer-config/cc-isolated.sh:848-898`; `$SP/iter3-r2/includeif-compare.log` (compare loop, cwd repo, ~2026-09-28T00:00Z)
**Legibility-target:** for-author

---

## Claim 4: "THE SCAN RUNS NOTHING FROM THE REPO … Config is read with `git config --file <f> --no-includes` from cwd /, so no repo is discovered … Everything else is find, stat, readlink and sha256sum; find never follows symlinks (-P)"

**Location:** `devcontainer-config/cc-isolated.sh:576-583`
**Type:** Behavioral / Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that no program named or stored in the checkout is executed (all git calls are `(cd / && git … --file … --no-includes)`; `find -P`; only regular files hashed/read); does not establish the tool list, which also includes `realpath`, `cat`, `tr`, `awk`, `sort`, `cut`, `mktemp`, `dirname` (iteration-2 Claim 9a residue, unchanged).

```bash
# devcontainer-config/cc-isolated.sh:806
  if ! (cd / && git --no-pager config --file "$f" --no-includes --null --list) > "$out" 2> "$out.err"; then
# devcontainer-config/cc-isolated.sh:716
  if ! find -P "$@" -print0 > "$out" 2> "$out.err"; then
```
Every read of container content is gated by `[ -f … ]` (`:681`, `:813`, `:986`, `:1011`), so a FIFO is recorded as `other` rather than read. The "runs nothing" part holds; "Everything else is find, stat, readlink and sha256sum" is imprecise (paraphrased — no quote available because the omitted tools are spread across `_snap_inside_ws`, `_snap_fail`, `scan_diff`, `git_exec_snapshot`).

**Evidence:** `devcontainer-config/cc-isolated.sh:648-1101`
**Legibility-target:** for-author

---

## Claim 5: "EVERY CONTAINER-CHOSEN STRING (names, values, error text) is reduced to printable ASCII, newlines included, before it reaches the terminal"

**Location:** `devcontainer-config/cc-isolated.sh:585-588`
**Type:** Invariant / Error-handling
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the exit-4 path through `git_exec_snapshot`'s own `echo` errors (and, by the same code, the launch-refusal path); does not establish other forging routes beyond this one, and it establishes that `_snap_fail` and `%q` records do sanitize.

`git_exec_snapshot` prints two errors with container-chosen paths *raw*, not through `_snap_fail`:

```bash
# devcontainer-config/cc-isolated.sh:1065-1067
  if [ ! -f "$_snap_common/config" ]; then
    echo "no git config at $_snap_common/config" >&2
    return 1
```
and `git_exit_scan` passes that text through `scan_vis`, which keeps newlines:

```bash
# devcontainer-config/cc-isolated.sh:1108-1110
scan_vis() {
  LC_ALL=C tr -c '[:print:]\n' '?'
}
```
`_snap_common` comes from `cd "$common" && pwd -P` (`:631`), so a session that writes `.git/commondir` = `../evillink` with `evillink` → a directory whose name contains a newline yields, at exit:

```
    no git config at …/exp3/co/evil
    WARNING: forged line - all clear, safe to git push/config
```
(status 2 → launcher exit 4). The forged line is indented four spaces by the `sed` at `:1145` but otherwise free text. The launch path (`:1279`, `$(cat "$snap_err")` into `scan_vis`) has the same shape for a plant left by an earlier session. Precise version: route `git_exec_snapshot`'s two `echo` errors through `_snap_fail`.

**Evidence:** `devcontainer-config/cc-isolated.sh:1054-1101`, `:1108-1110`, `:1137-1153`, `:1275-1286`; `$SP/iter3-r2/forge-commondir.log` (cmd `bash $SP/iter3-r2/exp3/run.sh`, ~2026-09-27T23:55Z)
**Legibility-target:** for-author

---

## Claim 6: "LIMITS (also in guides/cc-isolated-usage.md). No finding does not mean safe: [hook running a tracked file; anything present at launch; container keeps running / launcher killed before the scan; tracked .gitattributes and .gitmodules]"

**Location:** `devcontainer-config/cc-isolated.sh:590-605`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers that each iteration-2 Incorrect is now either fixed (tests pass) or listed here; does not establish completeness, and names two residues not listed.

The iteration-2 blocking omission (a baseline hook that runs a tracked file) is now listed (`:591-593`). The list does not say "complete". Two residues found:
- **Scan stall.** `_snap_hash` hashes every hook file in full (`sha256sum < "$1"`, `:661`). A 4 GiB *sparse* hook (0 bytes on disk, `truncate -s 4G`) made one snapshot take 32 s; a sparse file of a few TB costs the session nothing and stalls the exit scan for hours. The INT trap is cleared before the scan (`:1346` `trap - INT`), so a user who Ctrl-Cs the stalled scan gets no finding. The LIMITS bullet covers "a launcher killed before the scan"; one the session can *induce* to be killed during the scan is not mentioned.
- **Forged warning lines** (Claim 5).

**Evidence:** `devcontainer-config/cc-isolated.sh:590-605`, `:658-666`, `:1343-1353`; `$SP/iter3-r2/perf-sparse-hook.log` (cmd `bash -c "source …/cc-isolated.sh; git_exec_snapshot $T/co"`, cwd `/`, exit 0, 2026-09-27T23:59:36Z, `real 31.953`)
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 7a: "`git -c core.hooksPath=/dev/null -c core.fsmonitor=false push` is NOT a safe alternative: it still runs remote.*.receivepack, a repointed remote's hooks …"

**Location:** `devcontainer-config/cc-isolated.sh:1174-1176`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `remote.origin.receivepack` running under that command on git 2.39; does not establish the credential-helper and sshCommand items (not exercised; they need an https/ssh remote).

Planted `remote.origin.receivepack = "touch $M/receivepack; git-receive-pack"`; running the exact command in the checkout left marker `receivepack`, `rc=0`. Same text in `guides/cc-isolated-usage.md:167-170`.

**Evidence:** `devcontainer-config/cc-isolated.sh:1174-1176`; `guides/cc-isolated-usage.md:167-170`; `$SP/iter3-r2/unsafe-push-filters.log` (~2026-09-28T00:02Z, rc=0, markers listed)
**Legibility-target:** for-author

---

## Claim 7b: "… uses planted filters …" (the same sentence's filter item)

**Location:** `devcontainer-config/cc-isolated.sh:1175-1176`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers `git push` with planted `filter.x.clean/smudge/process` + `info/attributes` `* filter=x` and a dirty working tree, git 2.39; does not establish that no pre-push step in other setups refreshes the index (with hooks off, none does here).

With the planted filters and a modified tracked file, the push fired only `receivepack`; no `clean`, `smudge` or `process` marker. `git push` does not refresh the index, so filters are not run by the push itself. Guide `:169-170` repeats "uses planted filters". Low severity — the conclusion ("not a safe alternative") holds on the other items; the filter item overstates. Precise version: drop "filters" (or say "reads planted includes").

**Evidence:** `devcontainer-config/cc-isolated.sh:1175-1176`; `guides/cc-isolated-usage.md:169-170`; `$SP/iter3-r2/unsafe-push-filters.log`
**Legibility-target:** for-author

---

## Claim 8: "cc-push never runs git in the checkout. It keeps a BARE clone that only the host writes"

**Location:** `devcontainer-config/cc-push.sh:25-26`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every git invocation in cc-push.sh (none uses the checkout as cwd-discovered repo; `find_checkout` is plain file tests); does not establish that no git process opens the checkout — `fetch` and `ls-remote` spawn upload-pack there by design, as step 1 two lines later says.

```bash
# devcontainer-config/cc-push.sh:146-147
  if ! hgit "$clone" -c protocol.file.allow=always fetch -q --no-tags --no-recurse-submodules \
         --no-write-fetch-head --prune "$co" '+refs/heads/*:refs/cc/heads/*'; then
```
The two calls without `-C "$clone"` — `git init -q --bare "$clone"` (`:124`) and `git check-ref-format` (`:157`) — run in the caller's cwd, which by default is inside the checkout. `GIT_TRACE2_EVENT` for both, run from inside a planted checkout, shows no repo discovery (no `def_repo`/`worktree` event), and no marker fired. The same "never runs git in the checkout" wording is in `guides/cc-isolated-usage.md:174` and commit c3d9223 ("No git command runs in the checkout"). Precise version: "never runs git with the checkout as its repository, except the upload-pack that `git fetch`/`ls-remote` start there, which reads refs, objects and config."

**Evidence:** `devcontainer-config/cc-push.sh:72-82`, `:119-160`; `$SP/iter3-r2/tr2.json`, `$SP/iter3-r2/tr3.json` (trace2 of check-ref-format / init, cwd planted checkout, ~2026-09-27T23:53Z); `$SP/iter3-r2/cc-push-from-inside-checkout.log`
**Legibility-target:** for-author

---

## Claim 9: "`git fetch <checkout>` — git runs upload-pack in the checkout, which reads its refs, objects and config but runs no hook, no fsmonitor, no filter, and ignores uploadpack.packObjectsHook from repo config. Nothing is checked out."

**Location:** `devcontainer-config/cc-push.sh:27-29`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5 with the bats plant set (18 hook names, husky hooksPath, fsmonitor, filters+attributes, receivepack/uploadpack, packObjectsHook, alternateRefsCommand, sshCommand, gitProxy, askPass, pager, credential.helper, diff.external, include/includeIf, legacy remotes, repointed origin) plus a gitfile/symlinked checkout; does not establish other git versions, nor denial-of-service shapes (e.g. an `include.path` naming a FIFO would block upload-pack; not tested).

`plant_all` (`test/cc-push.bats:46-86`) plants `uploadpack.packObjectsHook "touch $M/packobjectshook"`; the test "cc-push runs nothing planted…" asserts `[ -z "$(markers)" ]` and that plain `git status` in the checkout *does* fire a marker (plants are live). Passed.

**Evidence:** `devcontainer-config/cc-push.sh:27-29`, `:141-149`; `test/cc-push.bats:104-116`; `$SP/iter3-r2/bats-cc-push.log`; `$SP/iter3-r2/cc-push-hostglobal.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 10: "Every git call here passes core.hooksPath=/dev/null and core.fsmonitor=false, so your own global config cannot point hooks at anything either."

**Location:** `devcontainer-config/cc-push.sh:33-34`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every git call in cc-push.sh; does not establish any harm from the two exceptions (neither runs hooks).

`hgit` adds both flags (`:69`: `git -C "$c" -c core.hooksPath=/dev/null -c core.fsmonitor=false "$@"`), but two calls bypass it:

```bash
# devcontainer-config/cc-push.sh:124
    git init -q --bare "$clone"
# devcontainer-config/cc-push.sh:157
  git check-ref-format "refs/heads/$branch" || die "not a valid branch name: $branch"
```
Neither runs hooks (Claim 8 trace). `git init` does copy `init.templateDir` hooks from your global config into the clone, which `core.hooksPath /dev/null` in the clone's config (`:125`) and on every later call then disables. Same "Every git call it makes" wording in `guides/cc-isolated-usage.md:194-195` and commit c3d9223. Precise version: "every git call on the clone".

**Evidence:** `devcontainer-config/cc-push.sh:65-70`, `:119-160`
**Legibility-target:** for-author

---

## Claim 11: "Exit codes: 0 pushed (or nothing to push), 1 usage or setup error, 2 declined."

**Location:** `devcontainer-config/cc-push.sh:42`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the die/decline/success paths and two push-failure shapes; does not establish every git failure's code.

The push is not guarded (`:197` `hgit "$clone" push origin "$src:refs/heads/$branch"`), so under `set -e` cc-push exits with git's status: a non-fast-forward rejection gave `rc=1` (not a "usage or setup error"), and a push to a nonexistent pushurl gave `rc=128`, outside the documented set. Precise version: "… 2 declined; otherwise git's own status when the push fails (1 rejected, 128 fatal)."

**Evidence:** `devcontainer-config/cc-push.sh:195-198`; `$SP/iter3-r2/cc-push-nonff-rc.log` (rc=1), `$SP/iter3-r2/cc-push-fatal-rc.log` (rc=128), both ~2026-09-28T00:03Z, cwd `$SP/iter3-r2/exp7/co`
**Legibility-target:** for-author

---

## Claim 12: "Whatever the caller's environment points git at, cc-push chooses the repos."

**Location:** `devcontainer-config/cc-push.sh:46-48`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the repository-selecting variables (`GIT_DIR GIT_WORK_TREE GIT_COMMON_DIR GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_NAMESPACE GIT_CEILING_DIRECTORIES`); does not establish that other inherited `GIT_*` (`GIT_CONFIG_PARAMETERS`, `GIT_SSH_COMMAND`, `GIT_PAGER`, `GIT_EXTERNAL_DIFF`) are cleared — they are the user's own and `--no-pager`/`--no-ext-diff` neutralise the latter two.

```bash
# devcontainer-config/cc-push.sh:47-48
unset GIT_DIR GIT_WORK_TREE GIT_COMMON_DIR GIT_INDEX_FILE GIT_OBJECT_DIRECTORY \
      GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_NAMESPACE GIT_CEILING_DIRECTORIES
```

**Evidence:** `devcontainer-config/cc-push.sh:46-48`
**Legibility-target:** for-author

---

## Claim 13: "vis: control bytes (and anything outside printable ASCII) as '?', so a commit message or branch name the session wrote cannot rewrite the terminal."

**Location:** `devcontainer-config/cc-push.sh:54-55`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what reaches the terminal for a session-chosen branch name; does not establish terminal behavior for C1 bytes (depends on the emulator).

`vis` is applied to log/diff output and die messages, but the branch name (taken from the checkout's HEAD symref at `:153`) is printed raw by `:169-170`, `:177`, `:181`, and by git push's own ref-update line (`:197`, not piped). `git check-ref-format` (`:157`) rejects C0 and DEL (ESC name → rc=1) but accepts bytes ≥0x80: a branch `x\302\2332J` (UTF-8 C1 CSI) passed and appeared byte-for-byte four times in cc-push output. ESC-based rewriting is blocked; 8-bit/C1 sequences are not. The commit-subject test (`test/cc-push.bats:156-163`) passes. Guide `:188` "control bytes as `?`" has the same residue.

**Evidence:** `devcontainer-config/cc-push.sh:54-58`, `:151-157`, `:169-182`, `:197`; `$SP/iter3-r2/c1-branch.log` (cmd `bash cc-push.sh --remote … --yes $T/co`, ~2026-09-27T23:50Z; `od -c` shows `302 233` on four lines)
**Legibility-target:** for-author

---

## Claim 14: "The clone … A directory cc-push did not create is never used" / clone inside the checkout refused

**Location:** `devcontainer-config/cc-push.sh:111-133`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the realpath check against the checkout and the `cc-push-checkout` marker (existence + content equality); does not establish freedom from a race where a container-controlled symlink in `--clone` is repointed between the check at `:112-115` and later uses of the unresolved `$clone` path.

```bash
# devcontainer-config/cc-push.sh:112-115
  clone_real="$(realpath -m -- "$clone")"
  case "$clone_real/" in
    "$co"/*) die "the clone $clone is inside the checkout $co, which the container can write" ;;
  esac
```
Bats test "refuses a clone inside the checkout, or a directory it did not create" passes. Extra: `--clone $co/link/clone` with `link` → outside was accepted (resolves outside); after the "session" repointed `link` into the checkout and planted `remote.origin.uploadpack` in a copied clone, the next run was refused ("is inside the checkout"), no marker. Only a concurrent repoint during a run remains (not tested).

**Evidence:** `devcontainer-config/cc-push.sh:108-138`; `test/cc-push.bats:145-154`; `$SP/iter3-r2/cc-push-clone-via-link.log`, `$SP/iter3-r2/cc-push-clone-link-repointed.log` (~2026-09-28T00:04Z)
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 15: "A local-path fetch … no submodules, no tags, no checkout. refs/cc/heads/* mirrors the checkout's branches (pruned)."

**Location:** `devcontainer-config/cc-push.sh:141-149`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the flags on the fetch; does not establish upload-pack's read-side behavior (Claim 9).

```bash
# devcontainer-config/cc-push.sh:146-147
  if ! hgit "$clone" -c protocol.file.allow=always fetch -q --no-tags --no-recurse-submodules \
         --no-write-fetch-head --prune "$co" '+refs/heads/*:refs/cc/heads/*'; then
```
The clone is bare (`:124`), so nothing can be checked out.

**Evidence:** `devcontainer-config/cc-push.sh:124`, `:141-149`
**Legibility-target:** for-author

---

## Claim 16: "Preview. --no-ext-diff/--no-textconv: no diff program runs on the session's files; --no-show-signature: no gpg on its signatures; output is plain text."

**Location:** `devcontainer-config/cc-push.sh:166-167`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers host global `diff.external`, `diff.x.textconv`/`command` via a global `core.attributesFile` `* diff=x`, `core.pager`, `pager.log`, `pager.diff`, `log.showSignature`, `gpg.program`; does not establish gpg behavior on a *signed* session commit (the commits were unsigned; `--no-show-signature` is on the log calls at `:178`, `:182`).

With all of those set in the host global config, a full cc-push run fired none of the `gpager`, `pagerlog`, `pagerdiff`, `g-gpg`, `g-ext`, `g-tc` markers. `--no-pager` is on each log/diff call (`:178-182`). A bare clone in git 2.39 does not read `.gitattributes` from the tree.

**Evidence:** `devcontainer-config/cc-push.sh:166-183`; `$SP/iter3-r2/cc-push-hostglobal.log` (2026-09-28T00:01:03Z, rc=0, `markers:` empty)
**Legibility-target:** for-author

---

## Claim 17: "A non-fast-forward is refused by the remote as usual: cc-push never forces." (and the push is what the preview showed)

**Location:** `devcontainer-config/cc-push.sh:195-197`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the push refspec (no `+`, no `--force`) and that no fetch runs between the preview and the push, so `$src` in the host-only clone is the ref previewed; does not establish that origin did not move between the preview fetch and the push (the remote then rejects or accepts as usual).

```bash
# devcontainer-config/cc-push.sh:197
  hgit "$clone" push origin "$src:refs/heads/$branch"
```
Bats "cc-push never forces" passes; independent re-run: rejected, `rc=1`.

**Evidence:** `devcontainer-config/cc-push.sh:162-198`; `test/cc-push.bats:177-184`; `$SP/iter3-r2/cc-push-nonff-rc.log`
**Legibility-target:** for-author

---

## Claim 18: guide launch step 7 — "Before step 4 the launcher snapshots … when claude exits it compares, and exits **3** … exits 4 when the exit scan cannot list or read any of it, and refuses to launch when the baseline snapshot cannot be taken. The scan is a tripwire, not a guarantee"

**Location:** `guides/cc-isolated-usage.md:51-59`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the control flow in `main()` and its bats coverage (139/139); does not establish the Ctrl-C claim in the LIMITS list (needs a live container) or completeness (Claims 6, 21).

```bash
# devcontainer-config/cc-isolated.sh:1348-1353
  git_exit_scan "$ws" "$git_before" || scan=$?
  case "$scan" in
    0) exit "$rc" ;;
    1) exit 3 ;;   # the session planted something: never a clean exit
    *) exit 4 ;;   # the scan could not read .git
  esac
```
(excerpt ends :1353; enclosing `main` ends :1354 — read). Baseline refusal at `:1277-1285` (`exit 1`).

**Evidence:** `devcontainer-config/cc-isolated.sh:1271-1354`; `$SP/iter3-r2/bats-cc-isolated.log` (cmd `bats test/cc-isolated-functions.bats`, cwd scratch clone, exit 0, 139 ok, ~2026-09-27T23:48Z)
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 19: "`test/cc-push.bats` plants hooks (every name), fsmonitor, clean/smudge/process filters, receive-pack and upload-pack commands, `uploadpack.packObjectsHook`, … and asserts that a `cc-push` fires none of them and pushes the fetched commit (git 2.39)."

**Location:** `guides/cc-isolated-usage.md:195-200`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the list against `plant_all`; does not establish anything about hooks not planted.

Every listed plant is in `plant_all` (`test/cc-push.bats:57-80`). "every name" is not literal: the loop plants 18 names

```bash
# test/cc-push.bats:48-50
  for h in pre-push pre-commit post-checkout post-merge post-commit reference-transaction \
           post-update pre-receive update post-receive push-to-checkout pre-auto-gc \
           post-rewrite post-index-change fsmonitor-watchman pre-upload upload-pack; do
```
— omitting e.g. `commit-msg`, `prepare-commit-msg`, `pre-rebase`, `pre-merge-commit`, `applypatch-msg`, `proc-receive` (and `pre-upload`/`upload-pack` are not git hook names). None of the omitted would plausibly run on fetch/push. Commit c3d9223 says "every hook name" too.

**Evidence:** `test/cc-push.bats:44-86`
**Legibility-target:** for-author

---

## Claim 20: guide exit-scan section — "It runs nothing from the checkout (…), and every name, value and error it prints is reduced to printable ASCII, line breaks included."

**Location:** `guides/cc-isolated-usage.md:230-234`
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the sanitisation half (same reproduction as Claim 5); the "runs nothing from the checkout" half is Verified per Claim 4.

A newline in a container-chosen common-dir path reaches the exit-4 warning as a free-standing line (Claim 5). Split not needed: the runs-nothing half is covered by Claim 4; this claim carries the sanitisation atom.

**Evidence:** `guides/cc-isolated-usage.md:230-234`; `devcontainer-config/cc-isolated.sh:1065-1067`, `:1108-1110`; `$SP/iter3-r2/forge-commondir.log`
**Legibility-target:** for-author

---

## Claim 21: guide "It catches the common plants. It **cannot** be complete … Known routes it does not see: [six bullets]"

**Location:** `guides/cc-isolated-usage.md:236-257`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the six bullets against code and the iteration-2 Incorrect list; does not establish completeness (explicitly disclaimed).

Mirrors LIMITS (Claim 6) plus "Host programs pointed at the checkout". Residues as Claim 6: induced stall (a sparse multi-TB hook) and forged warning lines. The tracked-`.gitattributes` bullet says "An attribute selects a driver that config defines (config is scanned)" — the repo's config is recorded, but the host's global config is read only for includes/hooksPath/attributesFile and its entries are not recorded (`cc-isolated.sh:903-905`: "Entries are not recorded (the container cannot write these files…)"), so a driver defined only in host config is outside the tripwire (it is the user's own program; iteration-2 Claim 27b residue, low).

**Evidence:** `guides/cc-isolated-usage.md:236-257`; `devcontainer-config/cc-isolated.sh:900-938`; `$SP/iter3-r2/perf-sparse-hook.log`
**Legibility-target:** for-author

---

## Claim 22: install.sh ships, chmods and links cc-push; the trust manifest hashes it; the live-verify gate treats it as an enforcement file (install.sh usage "cc-isolated and cc-push linked into $CLAUDE_DEVC_BIN_DIR"; c3d9223 "enforcement_files hashes it, so a rewritten cc-push.sh blocks the next cc-isolated launch"; 4435c73 "the gate's path regex was not kept in step, so … 'every manifest-hashed file is in the enforcement set' failed")

**Location:** `devcontainer-config/install.sh:35-36`
**Type:** Architectural / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers PAYLOAD membership (`install.sh:110`), `chmod +x` and `ln -sf` (`:596-603`), `enforcement_files` (`cc-isolated.sh:117`), the gate regex (`hooks/live-verify-gate.sh:73`); does not establish that cc-push itself checks the manifest (it does not; only cc-isolated's launch does).

```bash
# devcontainer-config/cc-isolated.sh:116-117
  echo "cc-isolated.sh"
  echo "cc-push.sh"
```
`bats test/install-host.bats` with `LC_ALL=C`: 92/92 (T3 asserts the link, target, `-x` and stub run). Without `LC_ALL=C` T3 fails in this sandbox only because a `setlocale` warning is prepended to the stub's output — environment artifact. `test/cc-isolated-functions.bats` 72 "every regular file in install.sh's PAYLOAD is hashed" passes. With the pre-4435c73 gate restored, `bats test/hooks/live-verify-gate.bats` fails exactly test 8 "every manifest-hashed file is in the enforcement set"; at a42e37f it passes (21/21).

**Evidence:** `devcontainer-config/install.sh:110`, `:596-603`; `devcontainer-config/cc-isolated.sh:108-132`; `hooks/live-verify-gate.sh:73`; `$SP/iter3-r2/bats-install-host-LCC.log` (exit 0); `$SP/iter3-r2/bats-set-a42e37f.log` (11 suites, 364/365, the one failure the locale artifact, ~2026-09-27T23:49:59Z); `$SP/iter3-r2/bats-lvg-pre4435.log` (exit 1, `not ok 8`)
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 23: "Bash(*.credentials.json*) is the Bash backstop for the credentials file … It is a string match: any spelling that does not contain the literal name (quotes split in it, a glob, a variable …) gets past."

**Location:** `hooks/wiring.json:38-45`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the hook's fall-through on the reproduction and the stated literal-match limit (regression re-check only); does not establish how Claude Code itself interprets the rule (#39344, override-log row 81).

`bats test/auto-approve-allowed-commands.bats` (in the 11-suite run) 21/21, including "reproduction: the wired credentials deny rule makes the hook fall through" and "the credentials deny rule in hooks/wiring.json is one the hook honors". The limitation text is honest: a glob such as `~/.claude/.cred*` would not contain the literal (paraphrased — no quote available because this is a consequence of the pattern, not a code line).

**Evidence:** `hooks/wiring.json:38-45`, `:130-131`; `test/auto-approve-allowed-commands.bats:115-175`; `$SP/iter3-r2/bats-set-a42e37f.log`
**Legibility-target:** for-author

---

## Claim 24: "Stamping this file made every edit to it stale every skill's reports, which kept the committed reports red"

**Location:** `test/skills/runner-contract.bash:192-194`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the word "committed" and the stamp inputs; does not establish the historical "kept … red" narrative.

`report_stamp` now prints only `skill`, `runner`, `fixture` (`:200-202`). "the committed reports" describes reports as committed; `git ls-files 'test/skills/*/output/*'` returns 0 — the same wording iteration 2 flagged elsewhere and 7dc7843 fixed in three other files. `.gitignore:4-13` now reads "are to be committed once generated (…; none yet)" and `git check-ignore -v --no-index` confirms `.report.md/.stamp/.failed/.transcript.jsonl` re-included and `scratch.tmp` ignored (Verified).

**Evidence:** `test/skills/runner-contract.bash:188-203`; `.gitignore:4-13`; `$SP/iter3-r2/gitignore-check.log`
**Legibility-target:** for-author

---

## Claim 25: Commit f35381f — "14 new bats cases … All 14 fail against a958372's cc-isolated.sh and pass here; the 125 existing cases still pass. cc-isolated-functions 139/139; with install-host, … function-inventory: 307/307. shellcheck -S warning clean. Snapshot of /workspace (with 5 linked worktrees) takes about 5 s."

**Location:** `git show f35381f` (commit message)
**Type:** Reference / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the counts, the a958372 regression, shellcheck at a42e37f and the /workspace timing; does not establish timing on pathological checkouts (300 synthetic embedded repos: 7.7 s; one 4 GiB sparse hook: 32 s — scan cost is linear in embedded repos and in hook-file size).

At f35381f's tests with a958372's cc-isolated.sh: 15 `not ok` — tests 123-136 (the 14 new: N5, N6, N7, N13, unlistable-dir wording, P1×2, P6, N2×2, N3, N4, N11, N12) plus test 72 (PAYLOAD hashing, failing only because a958372 predates c3d9223's `cc-push.sh` line; it is one of the 125 existing cases, which pass at f35381f). Suite counts (`bats --count`): 139+92+2+53+9+1+1+10 = 307 at both f35381f and a42e37f; all pass (Claim 22 note on locale). `shellcheck -S warning` on cc-push.sh, cc-isolated.sh, install.sh, the two hooks and both bats files: exit 0. `git_exec_snapshot /workspace` (6 worktree-list entries = main + 5 linked): `real 2.345` s, rc=0.

**Evidence:** `$SP/iter3-r2/bats-f35-vs-a958372.log` (cwd `$SP/iter3-r2/clone-f35`, exit 1, 124 ok / 15 not ok); `$SP/iter3-r2/shellcheck.log` (exit 0); `$SP/iter3-r2/perf-workspace.log` (cwd `/`, 2026-09-27T23:58:20Z); `$SP/iter3-r2/perf-300embedded.log` (2026-09-27T23:58:30Z)
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 26: Commit c3d9223 — "Tests: test/cc-push.bats (9 cases) … Suites … 307/307; shellcheck -S warning clean." plus "Every git call passes core.hooksPath=/dev/null and core.fsmonitor=false … No git command runs in the checkout"; commit 0a4862b "about 1360 lines"; commit 4435c73 (gate)

**Location:** `git show c3d9223` (commit message)
**Type:** Reference / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the counts (9 cases pass; 307 set) and the behavioral sentences; 0a4862b's line count (1359 at 0a4862b and a42e37f) and 4435c73 (Claim 22) are Verified; does not establish the "Live-verified: no" follow-up.

Counts hold. The two behavioral sentences carry the Claim 8 and Claim 10 imprecisions (`git init`/`check-ref-format` without the flags; upload-pack runs in the checkout — the commit's own Notes say so: "upload-pack still parses the checkout's config and follows its .git/gitdir/alternates"). "every hook name" per Claim 19. No commit message on the branch contains a "401/401" count (grep of `git log main..a42e37f` finds only 307/307).

**Evidence:** `$SP/iter3-r2/bats-cc-push.log`; `devcontainer-config/cc-push.sh:124`, `:157`; `git show 0a4862b:devcontainer-config/cc-isolated.sh | wc -l` = 1359
**Legibility-target:** for-orchestrator-synthesis

---

## Iteration-2 resolution (Claims Requiring Attention in `docs/reviews/iter2-code-fact-check-report.md`)

- **2b / 22b / 24 / 44e (universality):** resolved — the text now says tripwire, lists what it records, and disclaims completeness (Claims 6, 18, 21). Reproduced routes N2, N3, N4, N11, N12, P1, P6 are each a passing test that fails on a958372 (Claim 25).
- **5 / 25c (colon path, file://localhost):** fixed in `_snap_remote` (`cc-isolated.sh:778-799`); test N3 / N2 pass.
- **6 / 25b (host includeIf; submodule global hooksPath):** fixed (`_snap_host_config`, per embedded repo); residue: backslash-escaped patterns (Claim 3).
- **11 / 27a (hook runs tracked file):** now listed in LIMITS and guide; routed to cc-push.
- **13 / 15 (hooks-path false positive):** fixed (fixed layout); N6/N7 pass. New, narrower false positive (Claim 2).
- **27b (driver in host global config):** residue unchanged, low (Claim 21).
- **10 / 26c (newline forging):** *not* fully resolved — `_snap_fail` fixed the error paths it covers, but `git_exec_snapshot`'s two raw `echo` errors still forge (Claims 5, 20).
- **9a / 26b (tool list):** unchanged imprecision (Claim 4).
- **16 (wording "under $ws/.git"):** fixed (`:1142` "everything it checks in $ws").

---

## Claims Requiring Attention

### Incorrect
- **Claim 5** (`devcontainer-config/cc-isolated.sh:585-588`): a newline in a container-chosen common-dir path (via a `commondir` → symlink → newline-named dir) forges a line in the exit-4 warning; `git_exec_snapshot`'s `echo "no git config at …"` / `"cannot locate …"` bypass `_snap_fail`, and `scan_vis` keeps newlines. Route those through `_snap_fail`.
- **Claim 7b** (`devcontainer-config/cc-isolated.sh:1175-1176`, guide `:169-170`): `git push` with hooks/fsmonitor off did not run planted filters; drop "filters" from the not-safe list (the other items stand).
- **Claim 20** (`guides/cc-isolated-usage.md:232-234`): "every … error it prints is reduced to printable ASCII, line breaks included" — same forging as Claim 5.

### Stale
- None.

### Mostly Accurate
- **Claim 1** (`cc-isolated.sh:542-544`) / **Claim 8** (`cc-push.sh:25`, guide `:174`): "runs nothing from"/"never runs git in" the checkout — nothing executed, but upload-pack runs there and reads its config; say so.
- **Claim 2** (`cc-isolated.sh:553-554`): `HEAD` next to `objects/` anywhere under `modules/**` includes submodule refs/logs — branches `x/HEAD` + `x/objects/y` give a false exit 3.
- **Claim 3** (`cc-isolated.sh:564-567`): includeIf `gitdir:` patterns with a backslash escape under-match (false negative); `**` without slashes over-matches.
- **Claim 4** (`cc-isolated.sh:576-583`): tool list omits realpath/cat/tr/awk/sort/mktemp.
- **Claim 6** (`cc-isolated.sh:590-605`) / **Claim 21** (guide `:236-257`): unlisted residues — a session-induced multi-hour stall (sparse huge hook file) that a user will kill (no scan), and forged lines; host-config drivers not recorded.
- **Claim 10** (`cc-push.sh:33-34`): `git init` and `git check-ref-format` do not carry the flags (benign; "every git call on the clone").
- **Claim 11** (`cc-push.sh:42`): push failures exit with git's status (1 rejected, 128 fatal).
- **Claim 13** (`cc-push.sh:54-55`): branch name printed raw on 4 echo lines and in git push output; bytes ≥0x80 (C1) pass check-ref-format.
- **Claim 19** (guide `:195-200`): "hooks (every name)" is 18 names.
- **Claim 24** (`test/skills/runner-contract.bash:192-194`): "the committed reports" — none is committed.
- **Claim 26** (commit c3d9223): inherits Claims 8/10/19 wording.

### Unverifiable
- None (Ctrl-C-still-scans in the guide was not re-checked; needs a live container, as in iteration 2).

---

## Goal-Alignment Note
- **Success criterion (restated verbatim):** A code-fact-check report saved at the dispatch path in the skill's schema, covering the claims above, with a Goal-Alignment Note.
- **Answered:** cc-push's no-execution, no-remote-read, flags, clone refusal, marker, `--remote` storage, preview sanitisation, no-force and exit codes (planted-checkout runs from inside the checkout, via gitfile/symlink, with host-global pager/diff/textconv/gpg config); install/manifest/gate wiring (incl. the pre-4435c73 failure); exit-scan layout detection (one false positive), includeIf evaluation vs real git (one false negative), sanitisation (one forging route), fail-closed/no-exec, performance and two pathological cases; iteration-2 Incorrects each resolved or listed except newline forging; commit counts (14 new fail on a958372, 139, 9, 307, shellcheck).
- **Out of scope:** skills/*/SKILL.md (pass 2); live container behavior (Ctrl-C, devcontainer exec).
- **Escalate:** Claim 5/20 (forged exit-warning lines) and the induced-stall residue in Claim 6 are the two items that bear on the tripwire's trustworthiness; both are low-cost fixes or LIMITS additions.
- **Questions I would have asked:** The brief names a "401/401 set" commit claim; no commit on `main..a42e37f` states 401 (only 307/307) — was a different commit meant?
- **Decisions I made:** Treated the install-host T3 failure as a sandbox locale artifact after it passed 92/92 under `LC_ALL=C`; did not test alternates-based object exfiltration or FIFO-include hangs in upload-pack (DoS/read-side, no claim covers them).
