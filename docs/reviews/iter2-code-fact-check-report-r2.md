Commit: 02d14b0

# Code Fact-Check Report

**Repository:** /workspace (branch integrate/q076-q080)
**Scope:** `git diff main...02d14b0 -- . ':!skills'` (pass-1 diff, iteration 2) plus commit messages d9a895d, a958372, df11830, 376a8a2; replicate r2
**Checked:** 2026-09-27
**Total claims checked:** 49
**Summary:** 28 verified, 10 mostly accurate, 0 stale, 8 incorrect, 3 unverifiable

Execution logs: `$SP/iter2-r2/` where `$SP=/tmp/claude-1000/-workspace/dbfd30e0-d8d5-40c1-8bac-572239fc44fd/scratchpad`. Everything ran in a scratch clone checked out at 02d14b0 (`$SP/iter2-r2/x`), on git 2.39.5, bash 5.2.15, mawk 1.3.4, as uid 1000 (not root). The probe files are `$SP/iter2-r2/x/test/zz-*.bats` (scratch only). Every timestamp is 2026-09-27 UTC.

**Iteration-1 Incorrect claims, re-checked:**
- Claims 2, 5, 9, 18, 21 and 24: resolved. All the iteration-1 reproductions now return 1 (finding) or 2 (fail closed). See Claim 3.
- Claim 64: resolved. Launch-time errors now go through `scan_vis` (see Claim 9).
- Claim 23 (the guide's limits list): still Incorrect, with a new set of omissions. See Claims 10 and 23.

**New gaps found this iteration (reproduced):**
- N1: a baseline hook that runs a checkout file.
- N2: a baseline `remote.pushDefault` that names a local path.
- N3: a relative remote path that contains a `:`.
- N4: a legacy `.git/remotes/<name>` file.
- N11: a relative global `core.hooksPath` inside a submodule's worktree.
- N12: an interactive rebase todo list with an `exec` line.
- N13: a forged line in the exit-4 warning, carried by a newline in a file name.
- N6 and N7: false-positive findings on an ordinary commit.
- N5: a launch is refused when a branch is named `config`.

---

## Claim 1: "Generated eval reports are committed (Q-071 [1]): the report and every sidecar the suites read to grade it … Anything else a run might leave in output/ stays ignored."

**Location:** `.gitignore:4-7`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the ignore rules for flat files in `test/skills/<skill>/output/`. It does not establish that any report is committed, and none is.
**Severity:** Low
**Legibility-target:** for-author

The rules admit the four suffixes and ignore everything else. Command: `git status --porcelain -uall` in a scratch repo holding this `.gitignore` (cwd `$SP/iter2-r2/gi`, exit 0). It lists `t.report.md`, `t.stamp`, `t.failed` and `t.transcript.jsonl` as untracked-but-visible, and hides `x.tmp` and `sub/t.report.md`.

"are committed" is not true yet. `git ls-files 'test/skills/*/output/*' | wc -l` prints `0` at 02d14b0. Commit 376a8a2 fixed the same wording in two other files ("No report is tracked yet; the wording claimed they were"), but left this line alone. Precise version: "are meant to be committed once generated".

**Evidence:** `.gitignore:4-12`; `$SP/iter2-r2/gitignore-check.log`

---

## Claim 2: "main() snapshots every file host git reads to decide what to run, before the session, and compares after claude exits; anything added, removed or changed is named, and the launcher exits 3 instead of 0."

**Location:** `devcontainer-config/cc-isolated.sh:542-545`
**Type:** Behavioral / Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers two files host git reads to decide what to run that the snapshot never records, both reproduced on a plain repo baseline (N12, N4). It does not establish a bypass of a plain host `git status` or `git push` to a configured remote on a vanilla baseline: none was found. The iteration-1 bypasses are resolved (Claim 3).

`_snap_gitdir` records only what this find selects:

```bash
# devcontainer-config/cc-isolated.sh:823-825
  _snap_find "$list" "$real" \( -type l -o -name config -o -name config.worktree \
    -o -name commondir -o -path '*/info/attributes' -o -name hooks -o -path '*/hooks/*' \) \
    ! -name '*.sample' || return 1
```

Two files outside that set make host git run a program:

- **N12 (rebase todo list).** The session starts `git rebase -i`, stops on an `edit`, and appends `exec touch …/ran/rebase-exec` to `.git/rebase-merge/git-rebase-todo`. `git_exit_scan` returns 0. A host `git rebase --continue` then runs the line (the marker exists).
- **N4 (legacy remotes file).** The session writes `.git/remotes/upstream` (`URL: ./.cache-b`) and builds a bare repo `.cache-b` with a `post-receive` hook. The bare repo has no `.git` entry, so the embedded-repo search skips it. The scan returns 0, and a host `git push upstream …` runs the hook. This needs the user to push to a remote name that is not in config.

Command: `bats -f 'N12' test/zz-r2-newprobes.bats` (cwd `$SP/iter2-r2/x`, exit 0, 22:47Z), and `bats test/zz-r2-newprobes.bats` for N4 (22:46Z). Both probes assert that the scan status is 0 and that the marker exists.

**Evidence:** `devcontainer-config/cc-isolated.sh:817-851`, `devcontainer-config/cc-isolated.sh:899-907`; `$SP/iter2-r2/newprobes.log` (N4), `$SP/iter2-r2/newprobes3.log` (N12)

---

## Claim 3: "a 3-replicate fact-check of the first, key-list version found four bypasses (remote.*.receivepack, a repointed pushurl, a submodule's config, a hooks dir made unlistable)"

**Location:** `devcontainer-config/cc-isolated.sh:548-551`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four named shapes, as reproduced by the iteration-1 probe files, against the redesigned scan. It does not establish that no other bypass exists (see Claim 2).

Iteration-1 report Claims 2, 5 and 9 list these four shapes (`docs/reviews/iter1-code-fact-check-report.md:31-33`). I re-ran the iteration-1 probes unchanged, except that `CONFIG_SRC` now points at the 02d14b0 clone. Each probe asserted scan status 0 (bypass), and each now fails that assertion:

- zz-factcheck-extra X3 (submodule fsmonitor): status 1.
- zz-factcheck-extra X4 (receivepack): status 1.
- zz-factcheck-extra2 X6 (0111 hooks dir): status 2, with "cannot list everything under …/.git: find: '…/.git/hooks': Permission denied".
- zz-factcheck-extra3 X7 (pushurl): status 1, naming the pushurl and `evil.git/hooks/post-receive`.
- r3-probe X4, X5 and X6: status 1.

Command: `timeout 300 bats test/<file>.bats` for each file (cwd `$SP/iter2-r2/x`, 22:45:16Z, each exit 1 because the old bypass assertions now fail).

**Evidence:** `docs/reviews/iter1-code-fact-check-report.md:31-37`; `$SP/iter2-r2/iter1probes/*.log`

---

## Claim 4: "Recorded, for the checkout's git dir and common dir and, recursively, every git dir inside them (.git/modules/**, .git/worktrees/*): every file named config, config.worktree or commondir; info/attributes; every hooks dir (mode) and every entry in it except *.sample; every symlink."

**Location:** `devcontainer-config/cc-isolated.sh:551-554`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that each named class is recorded. It does not establish that only these are recorded: the same find also records every ref, log, object and index file when a path component is named `hooks` (Claim 12), and a stray file named `config` fails the snapshot (N5).

The find at `:823-825` (quoted in Claim 2) selects each class, and the loop at `:826-850` records each match through `_snap_file`. The following suite cases pass at 02d14b0 (125/125): (c) submodule config/hooks/attributes, (c) nested `modules/a/modules/b`, the linked-worktree case, and (d) mode change, symlinked hooks dir and symlinked hook. Command: `bats test/cc-isolated-functions.bats` (cwd `$SP/iter2-r2/x`, exit 0, 22:45:00Z).

**Evidence:** `devcontainer-config/cc-isolated.sh:817-851`; `$SP/iter2-r2/bats-cc-isolated-functions.log`

---

## Claim 5a: "Plus: every nested `.git` in the working tree … every core.hooksPath dir, every include.path / includeIf.*.path target and core.attributesFile named by any of those configs"

**Location:** `devcontainer-config/cc-isolated.sh:555-558`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the embedded-`.git` walk and the hooksPath, include and attributesFile targets named by scanned configs. It does not establish that a relative core.attributesFile in a submodule config resolves correctly: it resolves against the top checkout (`_snap_path "$val" "$_snap_ws"`, `:785`), whereas git uses the submodule's working tree.

```bash
# devcontainer-config/cc-isolated.sh:776-785 (excerpt of the case in _snap_config; enclosing function continues to :790 — read)
    case "$key" in
      core.hookspath)
        [ -z "$val" ] || _snap_hooks "$(_snap_path "$val" "$(_snap_worktree_of "$f")")" || return 1 ;;
      include.path|includeif.*.path)
        ...
      core.attributesfile)
        [ -z "$val" ] || _snap_file attributes "$(_snap_path "$val" "$_snap_ws")" || return 1 ;;
```

The embedded-repo search is `_snap_find "$list" "$_snap_ws" -mindepth 2 -name .git` (`:901`). Suite cases (c) embedded repo and (e) attributesFile/include target pass.

**Evidence:** `devcontainer-config/cc-isolated.sh:760-790`, `devcontainer-config/cc-isolated.sh:899-907`; `$SP/iter2-r2/bats-cc-isolated-functions.log`

---

## Claim 5b: "and any local-path remote (url/pushurl) inside the checkout, walked as a git dir (a push to it runs its hooks)" / "URLs with a scheme or host:path are not local"

**Location:** `devcontainer-config/cc-isolated.sh:557-559`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers url/pushurl values that are relative paths containing a colon (N3). It does not cover remotes named by path through `remote.pushDefault` or `branch.*.pushRemote`: the claim scopes itself to url/pushurl, and those are listed under Claim 10.

`_snap_remote` treats any value containing `:` as not local, unless it starts with `/`, `./` or `../`:

```bash
# devcontainer-config/cc-isolated.sh:741-747 (excerpt; enclosing _snap_remote continues to :757 — read)
_snap_remote() {
  local p="$1"
  case "$p" in
    file://*) p="${p#file://}" ;;
    /*|./*|../*) ;;
    *:*|"") return 0 ;;
  esac
```

Git treats `sub/a:b` as a local path, because a slash comes before the colon. Probe N3 used a baseline `remote add r sub/a:b` (a bare repo in the checkout) and then planted `sub/a:b/hooks/post-receive`. The scan returned 0, and a host `git push r …` ran the hook. Command: `bats test/zz-r2-newprobes.bats` (cwd `$SP/iter2-r2/x`, 22:46Z). The practical exposure needs such a remote at baseline.

**Evidence:** `devcontainer-config/cc-isolated.sh:738-757`; `$SP/iter2-r2/newprobes.log` (N3)

---

## Claim 5c: "Also the hooks dir and attributes file your own global/system config names: a relative core.hooksPath there resolves inside the checkout."

**Location:** `devcontainer-config/cc-isolated.sh:559-561`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the top-level checkout. It does not cover the same relative global hooksPath inside each submodule or embedded repo's working tree, which git also resolves there.

```bash
# devcontainer-config/cc-isolated.sh:808
      core.hookspath)      _snap_hooks "$(_snap_path "$val" "$_snap_ws")" || return 1 ;;
```

The path resolves against `$_snap_ws` only. In probe N11 (global `core.hooksPath .githooks`, submodule `sm`), the session planted `sm/.githooks/pre-commit`. The scan returned 0, and a host commit inside `sm` ran it. Precise version: "…resolves inside the checkout (the top-level working tree only)". Suite case (e) global hooksPath passes for the top level.

**Evidence:** `devcontainer-config/cc-isolated.sh:796-812`; `$SP/iter2-r2/newprobes.log` (N11)

---

## Claim 6: "Any change to one of these is a finding, even an inert one such as user.name … The key list below only labels report lines."

**Location:** `devcontainer-config/cc-isolated.sh:562-564`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that a changed record yields status 1 and that `GIT_EXIT_SCAN_KEYS_RE` is used only in `note()`. It does not establish that every recorded file is one git reads to decide what to run (Claim 12).

The key regex is referenced only here:

```awk
function note(key) { return (tolower(key) ~ ENVIRON["SCAN_KEYS_RE"]) ? "   <- can run a program" : "" }
```

(`devcontainer-config/cc-isolated.sh:925`)

The status is decided by `[ "$before" != "$after" ] || return 0` (`:961`). Suite case (e) "even an inert config change (user.name) is reported" passes.

**Evidence:** `devcontainer-config/cc-isolated.sh:923-940`, `devcontainer-config/cc-isolated.sh:961-963`; `$SP/iter2-r2/bats-cc-isolated-functions.log`

---

## Claim 7: "A directory that cannot be listed, a file that cannot be read or a config git cannot parse makes the snapshot fail: at launch the launcher refuses to start, at exit it returns 4."

**Location:** `devcontainer-config/cc-isolated.sh:566-569`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers unlistable directories (in the hooks dir and anywhere in the working tree), unreadable hooks and unparseable config at exit and at launch. It does not establish behaviour when the scan hangs rather than fails; none was found (Claim 8).

The failure paths are as follows:
- `_snap_find` returns 1 on any find error (`:681-684`).
- `_snap_hash` returns 1 when a file is unreadable (`:634-637`).
- `_snap_config` returns 1 when `git config` fails (`:766-768`).
- `git_exit_scan` turns a failed snapshot into `return 2` (`:948-958`), which `main` maps to exit 4 (`*) exit 4 ;;`, `:1156`).
- At launch a failed snapshot gives `exit 1` (`:1081-1089`).

Executed checks:
- Iteration-1 X6 (0111 hooks dir) now gives status 2.
- r3-probe X2 gives exit 4.
- An unlistable `node_modules/private` anywhere in the checkout makes `git_exec_snapshot` fail with "cannot list everything under …" (`$SP/iter2-r2/unlistable.log`, 22:51:20Z, as uid 1000).
- A branch named `config` makes the snapshot fail on "bad config line 1 in file …/logs/refs/heads/config" (N5, `$SP/iter2-r2/n67.log`).

**Evidence:** `devcontainer-config/cc-isolated.sh:677-685`, `devcontainer-config/cc-isolated.sh:945-959`, `devcontainer-config/cc-isolated.sh:1078-1092`, `devcontainer-config/cc-isolated.sh:1151-1157`; `$SP/iter2-r2/iter1probes/zz-factcheck-extra2.log`, `$SP/iter2-r2/unlistable.log`, `$SP/iter2-r2/n67.log`

---

## Claim 8: "THE SCAN RUNS NOTHING FROM THE REPO … Config is read with `git config --file <f> --no-includes` from cwd / … Everything else is find, stat, readlink and sha256sum; find never follows symlinks (-P), and a symlink's target is hashed only when it is a regular file."

**Location:** `devcontainer-config/cc-isolated.sh:571-578`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that nothing from the checkout is executed, that find uses -P, and that link targets are hashed only when `-f`. It does not establish the literal tool list: the scan also runs host `realpath`, `cd`/`pwd -P`, `tr`, `sort`, `mktemp` and `awk`, and it enters symlinked directories on purpose to walk them.

What the scan runs:
- Config reads: `(cd / && git --no-pager config --file "$f" --no-includes --null --list)` at `:766`, and `git --no-pager config --file "$1" --no-includes --get core.worktree` at `:729`.
- The host's own config: `(cd / && git --no-pager config --null --list)` at `:798`, which follows includes, but only in the host's files.
- Link handling: a link is hashed only under `if [ -f "$p" ]` (`:652`), and a directory link is entered with `cd "$p" … pwd -P` (`:656`).

Probe N8 made the hook, a worktree config, a commondir file and an include target all symlinks to a FIFO. The scan returned status 1 inside `timeout 20` (no hang). Command: `bats test/zz-r2-newprobes.bats` (22:46Z).

Precise version: "…otherwise only host tools (find, stat, readlink, sha256sum, realpath, awk, sort, tr); directory symlinks are entered to be walked".

**Evidence:** `devcontainer-config/cc-isolated.sh:646-675`, `devcontainer-config/cc-isolated.sh:724-736`, `devcontainer-config/cc-isolated.sh:796-801`; `$SP/iter2-r2/newprobes.log` (N8)

---

## Claim 9: "EVERY CONTAINER-CHOSEN STRING (names, values, error text) reaches the terminal only through scan_vis, at launch and at exit." / scan_vis: "make control bytes visible as '?'"

**Location:** `devcontainer-config/cc-isolated.sh:580-581`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the routing: both the launch and exit outputs are piped through `scan_vis`, which resolves iteration-1 Claim 64. It does not establish that every control byte is neutralised: newline is kept.

```bash
# devcontainer-config/cc-isolated.sh:916-918
scan_vis() {
  LC_ALL=C tr -c '[:print:]\n' '?'
}
```

Paths in report records are `%q`-quoted, and config values have `\n` replaced (`:774`). The error strings do not: they print raw paths, for example `printf 'cannot read %s\n' "$1" >&2` (`:635`).

Probe N13: an unreadable hook named `x\n  NOTE: nothing else changed; git status is safe here.\ny` produced an exit-4 warning with that forged line on its own line. Command: `bats -f N13 test/zz-r2-newprobes.bats` (cwd `$SP/iter2-r2/x`, exit 0, 22:49Z). ESC bytes still render as `?` (suite cases (f) pass).

**Evidence:** `devcontainer-config/cc-isolated.sh:632-639`, `devcontainer-config/cc-isolated.sh:914-918`, `devcontainer-config/cc-isolated.sh:951-957`, `devcontainer-config/cc-isolated.sh:1082-1087`; `$SP/iter2-r2/newprobes4.log`

---

## Claim 10: "LIMITS (also in guides/cc-isolated-usage.md). … a process it left behind can plant after the scan … Whatever is present at launch is the baseline … A launcher killed before the scan … scans nothing. A config value that names a program by path inside the checkout … is recorded as a value, not followed"

**Location:** `devcontainer-config/cc-isolated.sh:583-589`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the completeness of the stated limits. Each of the four stated limits is true. The list omits reproduced ways a session leaves host git armed while the scan returns 0.

Omitted, each reproduced with scan status 0 and the marker created by a later host git command:
- **N1:** a baseline hook that runs a checkout file (`exec ./scripts/pc.sh`; the session edits `scripts/pc.sh`; a host `git commit` runs it). This is the husky (`core.hooksPath=.husky/_`) and pre-commit-framework shape.
- **N12:** the `git-rebase-todo` `exec` line (Claim 2).
- **N4:** a `.git/remotes/<name>` file (Claim 2).
- **N2:** a baseline `remote.pushDefault=./b.git` plus `push.default current`; the session plants `b.git/hooks/post-receive`; a plain host `git push` runs it. The value names a repo by path, not a program.
- **N3:** a colon remote path (Claim 5b).
- **N11:** a submodule global hooksPath (Claim 5c).

Command: `bats test/zz-r2-newprobes.bats` (cwd `$SP/iter2-r2/x`, 22:46Z; N2 re-run at 22:47Z after fixing the probe's push command).

**Evidence:** `devcontainer-config/cc-isolated.sh:583-589`; `$SP/iter2-r2/newprobes.log`, `$SP/iter2-r2/newprobes2.log`, `$SP/iter2-r2/newprobes3.log`

---

## Claim 11: "SIZE. This block brings cc-isolated.sh to about 1160 lines."

**Location:** `devcontainer-config/cc-isolated.sh:591`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the line count at 02d14b0. It does not cover the PAYLOAD rationale.

`wc -l devcontainer-config/cc-isolated.sh` prints `1163` (paraphrased — no quote available because the claim is about file size, not a snippet).

**Evidence:** `devcontainer-config/cc-isolated.sh:1-1163`

---

## Claim 12: "# A symlink (anything else the find matched is under a hooks dir). Git follows it, so a linked directory inside the checkout is walked too."

**Location:** `devcontainer-config/cc-isolated.sh:843-844`
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the else-branch of `_snap_gitdir`. It does not establish any false negative: the effect is false positives.

`-path '*/hooks/*'` matches against the full absolute path. When a directory above the git dir is named `hooks`, or a branch name has a `hooks` component, ordinary files reach this branch and are recorded as `link`:

- **N7 (checkout at `$T/hooks/proj`).** The baseline holds 37 records. After one normal commit the scan returns 1, listing `~ link …/.git/index`, `~ link …/.git/refs/heads/master`, `+ link …/.git/objects/0c/3a87…` and more. Every object in the repo is also hashed.
- **N6 (branch `feat/hooks/x`).** `~ hook …/.git/refs/heads/feat/hooks/x` is reported after a normal commit.

A user with such a path or branch gets exit 3 on every session that commits. Command: `bash $SP/iter2-r2/n67.sh` (cwd `$SP/iter2-r2`, exit 0, 22:50:17Z).

**Evidence:** `devcontainer-config/cc-isolated.sh:823-850`; `$SP/iter2-r2/n67.log`

---

## Claim 13: "git_exit_scan <ws> <launch snapshot>: 0 when nothing host git reads to decide what to run changed; 1 (warning on stderr, naming each item) when something did; 2 when the exit state could not be read."

**Location:** `devcontainer-config/cc-isolated.sh:942-944`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both directions of the 0/1 contract. The 2-on-unreadable part is Verified (Claim 7).

- **0 although something git reads to decide what to run changed:** N12 and N4 (Claim 2).
- **1 although nothing exec-relevant changed:** N6 and N7 (Claim 12).

I also checked the one other way status could come out 0 while the snapshots differ: an empty `scan_diff` (`[ -n "$changes" ] || return 0`, `:963`). A 3 MB planted config value still produced status 1 under mawk (N9, `bats -f 'N2|N9'`, 22:47Z).

**Evidence:** `devcontainer-config/cc-isolated.sh:945-984`; `$SP/iter2-r2/newprobes.log`, `$SP/iter2-r2/newprobes2.log`, `$SP/iter2-r2/newprobes3.log`, `$SP/iter2-r2/n67.log`

---

## Claim 14: "Safest: push from a separate host clone that fetches from this one; a fetch runs none of this checkout's hooks, fsmonitor, filters or remote settings. `git -c core.hooksPath=/dev/null -c core.fsmonitor=false push` covers hooks and fsmonitor ONLY: not remote.*.receivepack, a repointed remote, filters, includes, credential helpers or core.sshCommand."

**Location:** `devcontainer-config/cc-isolated.sh:976-980`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the fetch half and the receivepack and repointed-pushurl halves on git 2.39.5. It does not execute the filter, include, credential-helper and sshCommand items (they follow from the `-c` flags setting only two keys), and it does not establish that the separate clone's checkout of attacker-authored tracked content is inert under the user's global drivers.

Separate clone: the session planted 10 hooks (incl. pre/post-upload-pack), `core.fsmonitor`, `uploadpack.packObjectsHook` and a filter driver. `git -C hostclone fetch origin` then `merge --ff-only` created no marker. Command: see `$SP/iter2-r2/separate-clone.log` (exit 0, 22:49:33Z).

Hooks-only push to a repointed `pushurl` (`./evil.git`) ran `ran-post-receive`. Adding `-c protocol.file.allow=never` gave "fatal: transport 'file' not allowed" (exit 128) and no marker (`$SP/iter2-r2/hooksonly-pushurl.log`, 22:51:32Z). Suite case (a) pins the receivepack half.

**Evidence:** `devcontainer-config/cc-isolated.sh:976-981`; `$SP/iter2-r2/separate-clone.log`, `$SP/iter2-r2/hooksonly-pushurl.log`, `$SP/iter2-r2/bats-cc-isolated-functions.log`

---

## Claim 15: Exit contract: the baseline is taken "before the container is (re)started. A repo whose .git cannot be read here could not be scanned at exit either, so refuse." / `0) exit "$rc" ;; 1) exit 3 ;; *) exit 4 ;;`

**Location:** `devcontainer-config/cc-isolated.sh:1075-1077`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the order (snapshot before `devcontainer up`), the refusal (exit 1) and the 0/3/4 mapping. Exit 3 or 4 is not exclusive to the scan: a clean scan passes claude's own status through, so claude exiting 3 or 4 is indistinguishable.

```bash
# devcontainer-config/cc-isolated.sh:1151-1157
  local scan=0
  git_exit_scan "$ws" "$git_before" || scan=$?
  case "$scan" in
    0) exit "$rc" ;;
    1) exit 3 ;;   # the session planted something: never a clean exit
    *) exit 4 ;;   # the scan could not read .git
  esac
```

The snapshot at `:1081` precedes `devcontainer up` at `:1110`. r3-probe X1 (clean, claude 7 → 7), X2 (→ 4) and X3 (finding + claude 7 → 3) pass. The suite's "a launch refuses to start when .git cannot be snapshotted" passes.

**Evidence:** `devcontainer-config/cc-isolated.sh:1075-1092`, `devcontainer-config/cc-isolated.sh:1110`, `devcontainer-config/cc-isolated.sh:1147-1157`; `$SP/iter2-r2/iter1probes/zz-r3-probe.log`, `$SP/iter2-r2/bats-cc-isolated-functions.log`

---

## Claim 16a: "The INT trap keeps a Ctrl-C that ends the session from also killing the launcher before the scan"

**Location:** `devcontainer-config/cc-isolated.sh:1143-1146`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers SIGINT to the process group with a stubbed devcontainer CLI. It does not establish live-terminal behaviour.

r3-int X9 ("launcher survives and scans") passes. X10 reports status=130, claude's status passed through (that test ends in `false` by design, to print the status). Command: `bats test/zz-r3-int.bats` (cwd `$SP/iter2-r2/x`, 22:45Z).

**Evidence:** `devcontainer-config/cc-isolated.sh:1147-1150`; `$SP/iter2-r2/iter1probes/zz-r3-int.log`

---

## Claim 16b: "(a trapped signal, unlike an ignored one, is reset to its default in the child, so claude still gets its own Ctrl-C)"

**Location:** `devcontainer-config/cc-isolated.sh:1145-1146`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers nothing beyond iteration 1: this needs a live `devcontainer exec` session with a TTY.

This is unchanged since iteration-1 Claim 15 (paraphrased — no quote available because the claim concerns TTY signal delivery through `devcontainer exec`, which is not present in the sandbox).

**Evidence:** `devcontainer-config/cc-isolated.sh:1148-1149`

---

## Claim 17a: "in cc-isolated the sandbox was never there. The image has no bwrap or socat and the container refuses unprivileged user namespaces (`unshare -Ur` → EPERM) … the reviewer's `curl -d @…/.credentials.json` inside `$(( ))` was auto-approved (re-run first-hand: `allow`)."

**Location:** `docs/decisions/log.md:76`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers this container (baked config hash `63fa8fc01e97ca3e`) and the hook's decision with no Bash deny rule. It does not establish that Claude Code then executes the command.

`command -v bwrap` and `command -v socat` both return 1. `unshare -Ur true` prints "unshare failed: Operation not permitted" (`$SP/iter2-r2/sandbox-probe.log`, 22:50:41Z). The test "reproduction: with no Bash deny rule the $(( )) exfiltration is still approved" passes (`$SP/iter2-r2/bats-auto-approve-allowed-commands.log`).

**Evidence:** `docs/decisions/log.md:76`; `$SP/iter2-r2/sandbox-probe.log`, `$SP/iter2-r2/bats-auto-approve-allowed-commands.log`

---

## Claim 17b: "because a hook decision can override `permissions.deny` (#39344, shown for `ask`; not verified for `allow`)"

**Location:** `docs/decisions/log.md:76`
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers nothing: this needs the Claude Code issue tracker (no egress) and a live permission test. The same claim appears at `hooks/auto-approve-allowed-commands.sh:45-46` (Claim 28b).

Paraphrased — no quote available because the claim references an external issue tracker entry not present in the repo.

**Evidence:** `docs/decisions/log.md:76`

---

## Claim 17c: "That is a string match: a spelling without the literal name (`.cred""entials.json`, a glob such as `.cred*`, a variable whose value is not spelled out in the same command) still gets through; each of those three spellings is pinned by a test. In a deny rule only `*` is a wildcard, and a bare `Bash` deny rule blocks all approval."

**Location:** `docs/decisions/log.md:76`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the hook's behaviour. It does not cover Claude Code's own deny matcher. This resolves iteration-1 Claims 30 and 32.

The three "string-match limit" tests and the bare-Bash test exist and pass (21/21). Probe `$SP/iter2-r2/hookprobe.sh` (22:47:30Z) gives:
- No output (fall-through) for deny `Bash`, `Bash(*)` and `Bash(**)`.
- `allow` for `ls a` against `Bash(ls ?)`, and fall-through for the literal `ls ?`.
- Fall-through for `ls [x]` against `Bash(ls [x])`, and `allow` for `ls x`.

**Evidence:** `docs/decisions/log.md:76`, `test/auto-approve-allowed-commands.bats` (string-match tests); `$SP/iter2-r2/hookprobe.log`, `$SP/iter2-r2/bats-auto-approve-allowed-commands.log`

---

## Claim 18: "It never approves a command that matches a `Bash(...)` deny rule … That rule is a string match and misses obfuscated spellings … In a deny rule only `*` is a wildcard, and a bare `Bash` rule denies every command."

**Location:** `guides/bare-host-hook-wiring.md:151-156`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the hook's matching (raw string and extracted commands). "Denies every command" is true of Claude Code's rule; for the hook it means "never approves". The claim does not establish behaviour when a settings file is malformed: jq errors are discarded (`2>/dev/null`), so that file contributes no deny rules.

```bash
# hooks/auto-approve-allowed-commands.sh:119-122
deny_rules_to_globs() {
  sed -nE 's/^Bash$/*/p; s/^Bash\((.*)\)$/\1/p' \
    | sed -E 's/:\*$/*/; s/[^A-Za-z0-9*]/\\&/g'
}
```

Probe results match every sentence, including the extglob literal (`ls +(a)` is denied; `ls a` is allowed). Iteration-1 Claim 27 is resolved.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:113-170`, `hooks/auto-approve-allowed-commands.sh:260-266`, `hooks/auto-approve-allowed-commands.sh:313-316`; `$SP/iter2-r2/hookprobe.log`

---

## Claim 19a: "`devcontainer exec … claude`. Before step 4 the launcher snapshots … when claude exits it compares, and exits **3** … It exits 4 when the exit scan cannot list or read any of it, and refuses to launch when the baseline snapshot cannot be taken."

**Location:** `guides/cc-isolated-usage.md:50-57`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the order and the exit codes (same evidence as Claim 15). The "every file" coverage part is split out as Claim 19b.

This is the same code as Claim 15 (paraphrased — no quote available because the evidence is the `main()` sequence already quoted in Claim 15).

**Evidence:** `devcontainer-config/cc-isolated.sh:1078-1092`, `devcontainer-config/cc-isolated.sh:1151-1157`; `$SP/iter2-r2/iter1probes/zz-r3-probe.log`

---

## Claim 19b: "the launcher snapshots every file host git reads to decide what to run (hooks, configs, attributes, submodule and embedded git dirs, local remotes)"

**Location:** `guides/cc-isolated-usage.md:50-52`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claim 2. The rebase todo list and legacy remote files are read by git to decide what to run and are not snapshotted.

See Claim 2 (paraphrased — no quote available because this is the guide's restatement of the header claim verdicted there).

**Evidence:** `devcontainer-config/cc-isolated.sh:823-825`; `$SP/iter2-r2/newprobes.log`, `$SP/iter2-r2/newprobes3.log`

---

## Claim 20: "A plain host `git push` (or `git status`) runs any hooks, `core.fsmonitor`, filter drivers, `remote.*.receivepack` command or repointed remote planted there, as you and with your keys."

**Location:** `guides/cc-isolated-usage.md:165-168`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers these examples as reproduced (receivepack, repointed pushurl, fsmonitor through `git status` into a gitlink). It is not an exhaustive list (see Claim 23).

Suite case (a) runs `receivepack` through a push. `hooksonly-pushurl.log` shows the repointed-remote hook running. `gitlink-fsmonitor.log` shows a host `git status` running a gitlink repo's fsmonitor (`ran-gitlink-fsm`; exit 0, 22:51:51Z).

**Evidence:** `test/cc-isolated-functions.bats:1351-1373`; `$SP/iter2-r2/hooksonly-pushurl.log`, `$SP/iter2-r2/gitlink-fsmonitor.log`

---

## Claim 21: "`cc-isolated` snapshots, before the session, every file host git reads to decide what to run … What it covers: … and any local-path remote inside the checkout, walked as a git dir. … Then it exits 3, never 0."

**Location:** `guides/cc-isolated-usage.md:170-185`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the completeness claims:
- "every file": refuted by N12 and N4.
- "any local-path remote": refuted by N3.
- "the ones your own global config names": holds for the top level only (N11).

The enumerated classes themselves are recorded (Claims 4 and 5a). Iteration-1 Claims 18, 21 and 24 are resolved for their specific shapes.

See Claims 2, 5b and 5c (paraphrased — no quote available because the evidence is the scan code already quoted in those claims).

**Evidence:** `devcontainer-config/cc-isolated.sh:741-757`, `devcontainer-config/cc-isolated.sh:808`, `devcontainer-config/cc-isolated.sh:823-825`; `$SP/iter2-r2/newprobes.log`, `$SP/iter2-r2/newprobes3.log`

---

## Claim 22: "It fails closed … The scan runs nothing from the checkout … Every name, value and error it prints goes through a filter that shows control bytes as `?`."

**Location:** `guides/cc-isolated-usage.md:185-193`
**Type:** Error-handling / Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** The fail-closed and runs-nothing parts are as verified in Claims 7 and 8. The filter keeps newlines, so a container-chosen file name can add lines to the exit-4 warning (N13, Claim 9).

Precise version: "…shows control bytes other than newline as `?`; paths in error text are printed raw". `tr -c '[:print:]\n' '?'` (`devcontainer-config/cc-isolated.sh:917`).

**Evidence:** `devcontainer-config/cc-isolated.sh:914-918`; `$SP/iter2-r2/newprobes4.log`

---

## Claim 23: "Its limits:" (Baseline, not audit · After the scan · No scan · Outside `.git` · Programs named by path — "Hooks, hooks dirs, includes and attribute files are the exception: their contents are hashed.")

**Location:** `guides/cc-isolated-usage.md:193-209`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the completeness of the limits list. Each listed item is individually accurate.

The list omits the N1, N2, N3, N4, N11 and N12 shapes (Claim 10). The "exception" sentence implies a hook cannot be subverted without a finding, but N1 subverts a hashed hook by editing the checkout script it runs. That is the husky and pre-commit-framework layout. This carries forward iteration-1 Claim 23 with a new set of omissions.

**Evidence:** `guides/cc-isolated-usage.md:193-209`; `$SP/iter2-r2/newprobes.log` (N1)

---

## Claim 24: "**Outside `.git`.** Tracked files such as `.gitattributes` are not scanned; a tracked attribute only runs a driver that config defines, and that config is scanned."

**Location:** `guides/cc-isolated-usage.md:202-204`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers repo config. A driver defined in the host's global or system config is not scanned: the scan reads only its hooksPath and attributesFile (`:807-810`), so an attribute the session adds can select it. Git-lfs is the common case, and it runs a program the user installed.

```bash
# devcontainer-config/cc-isolated.sh:807-810
    case "$key" in
      core.hookspath)      _snap_hooks "$(_snap_path "$val" "$_snap_ws")" || return 1 ;;
      core.attributesfile) _snap_file attributes "$(_snap_path "$val" "$_snap_ws")" || return 1 ;;
    esac
```

Precise version: "…that the repo's config defines (scanned) or your own global config defines (yours, not scanned)".

**Evidence:** `devcontainer-config/cc-isolated.sh:792-812`

---

## Claim 25: "push from a separate host clone … (checked on git 2.39). `git -c core.hooksPath=/dev/null -c core.fsmonitor=false push` covers hooks and fsmonitor **only** … Adding `-c protocol.file.allow=never` refuses a push to a local-path remote, which stops the receive-pack and repointed-bare-repo cases, but not the rest."

**Location:** `guides/cc-isolated-usage.md:210-219`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claim 14, on git 2.39.5. It does not cover an ssh or https remote (receivepack is then a remote-side command). This resolves iteration-1 Claims 12 and 25.

See Claim 14 (paraphrased — no quote available because the evidence is the logs cited there).

**Evidence:** `$SP/iter2-r2/separate-clone.log`, `$SP/iter2-r2/hooksonly-pushurl.log`, `test/cc-isolated-functions.bats:1351-1373`

---

## Claim 26: "writes … with a provenance `.stamp` (hashes of the skill directory, its `runner.bash` and the fixture, not the shared harness); reports and their sidecars are meant to be committed once generated (none are yet; `.gitignore` admits them), and a report whose stamp no longer matches fails its suite until regenerated."

**Location:** `guides/skill-creation.md:63`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the stamp inputs, the absence of tracked reports and the `.gitignore` admission. It does not re-verify the eval-suite wiring (iteration-1 Claim 1).

The stamp inputs are skill, runner and fixture:

```bash
# test/skills/runner-contract.bash:198-203
report_stamp() {
  local sk="$1" skill="$2" fixture="$3"
  printf 'skill %s\n' "$(_stamp_hash_path "$sk/../../skills/$skill")"
  printf 'runner %s\n' "$(_stamp_hash_path "$sk/$skill/runner.bash")"
  printf 'fixture %s\n' "$(_stamp_hash_path "$sk/$skill/fixtures/$fixture")"
}
```

`git ls-files` shows 0 tracked reports. The freshness suite passes 32/32.

**Evidence:** `test/skills/runner-contract.bash:198-203`; `$SP/iter2-r2/gitignore-check.log`, `$SP/iter2-r2/bats-eval-helpers-freshness.log`

---

## Claim 27: "F4 … Resolved for all 25 skills … runs 364–438 characters (was 951–2969)."

**Location:** `guides/skill-format-audit.md:20`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the description length (folded scalar, lines joined by single spaces) at 02d14b0 and at `origin/main` (ffb5f0d). It does not verify the "purpose within ~250 characters" ordering.

A python parser over `skills/*/SKILL.md` gives "count 25 min 364 max 438" at 02d14b0 and "count 25 min 951 max 2969" at main (22:53Z).

**Evidence:** `guides/skill-format-audit.md:18-20`; `$SP/iter2-r2/desc-lengths.log`

---

## Claim 28a: "The container has no Claude Code sandbox … So this hook reads the Bash deny rules itself and falls through, never 'allow', when the raw command or any extracted command matches one. Reproduced: … was approved; with the wired deny rule it falls through to the prompt. … The quote-split, glob and variable spellings are pinned by tests."

**Location:** `hooks/auto-approve-allowed-commands.sh:39-54`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the hook's decision, the sandbox facts (Claim 17a) and the pinned tests. It does not cover Claude Code's handling after fall-through. This resolves iteration-1 Claims 38 and 40.

```bash
# hooks/auto-approve-allowed-commands.sh:262-266
  mapfile -t deny_globs < <(get_deny_globs)
  debug "Loaded ${#deny_globs[@]} Bash deny rules"
  if matches_deny "$command" deny_globs; then
    debug "Decision: BLOCK (deny rule; falling through to normal permission check)"
    exit 0
```

The per-extracted-command check sits at `:313-316`. The tests "reproduction: the wired credentials deny rule makes the hook fall through" and the three string-match limits pass. The probe's same-command-assignment case falls through.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:260-266`, `hooks/auto-approve-allowed-commands.sh:310-320`; `$SP/iter2-r2/hookprobe.log`, `$SP/iter2-r2/bats-auto-approve-allowed-commands.log`

---

## Claim 28b: "A hook 'allow' is not trusted to leave those rules in force: a hook 'ask' overrides permissions.deny (Claude Code issue #39344)."

**Location:** `hooks/auto-approve-allowed-commands.sh:44-45`
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Same blocker as Claim 17b: there is no egress to the tracker and no live Claude Code permission test.

Paraphrased — no quote available because the claim concerns external Claude Code behaviour.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:44-45`

---

## Claim 29: "Rule syntax: only `*` (and the legacy trailing `:*`) is a wildcard, and a bare `Bash` deny rule denies everything. KNOWN DIVERGENCE: … Here it does not (`rm *` needs the space). … `Bash(rm:*)`, which matches `rm` alone but, as a plain prefix, also `rmdir`."

**Location:** `hooks/auto-approve-allowed-commands.sh:56-61`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the hook's matching. Whether Claude Code agrees is stated as unknown in the comment itself (iteration-1 Claim 42 stays open for Claude Code).

`hookprobe.log` results:
- Deny `Bash(rm *)`: `rm` gets `allow`, `rm x` falls through.
- Deny `Bash(rm:*)`: `rm` falls through, and so does `rmdir x`.
- Deny `Bash(ls ?)`: `ls a` gets `allow`.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:113-122`; `$SP/iter2-r2/hookprobe.log`

---

## Claim 30: "Only `*` is a wildcard in a rule; every other character is backslash-escaped so bash matches it literally." / matches_deny: "deny_rules_to_globs has already escaped everything but `*`, so `*` is the only live wildcard."

**Location:** `hooks/auto-approve-allowed-commands.sh:113-118`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers ASCII rules. It does not establish behaviour for non-ASCII rule characters under a non-UTF-8 sed locale (per-byte escaping), which was not tested.

`s/[^A-Za-z0-9*]/\\&/g` (`:121`). The probes for `?`, `[x]` and `+(a)` all match only literally. Three tests fail against the pre-df11830 hook (Claim 40).

**Evidence:** `hooks/auto-approve-allowed-commands.sh:119-122`, `hooks/auto-approve-allowed-commands.sh:151-167`; `$SP/iter2-r2/hookprobe.log`

---

## Claim 31: "without it `curl -d @$HOME/.claude/.credentials.json` nested where the auto-approve hook does not look (e.g. inside $(( ))) ran with no prompt. auto-approve-allowed-commands.sh reads Bash deny rules and never approves a match. It is a string match …"

**Location:** `hooks/wiring.json:38-44`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the hook's decision and that the rule ships in `permissions.deny`. "Ran" is inferred from the hook's `allow`; no live Claude Code run was made. This resolves iteration-1 Claims 46 and 47 (the example now uses `@$HOME`).

`"Bash(*.credentials.json*)",` (`hooks/wiring.json:131`). The tests "the credentials deny rule in hooks/wiring.json is one the hook honors" and "the merged settings carry the Bash deny rule" pass (link-claude-home-wiring 16/16).

**Evidence:** `hooks/wiring.json:38-44`, `hooks/wiring.json:131`; `$SP/iter2-r2/bats-auto-approve-allowed-commands.log`, `$SP/iter2-r2/bats-link-claude-home-wiring.log`

---

## Claim 32: "Generate reports with test/skills/generate-reports.bash <skill> and commit what it writes to output/ (reports are tracked; Q-071 [1])."

**Location:** `scripts/run-tests.sh:100-101`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the tracked state at 02d14b0. The instruction is sound. "are tracked" is policy: 0 files are tracked. The health-check warning ("then commit output/", `scripts/health-check.sh:407`) is consistent with that policy.

This is the same wording 376a8a2 corrected elsewhere. Precise version: "(reports are meant to be tracked)". `git ls-files 'test/skills/*/output/*'` prints nothing.

**Evidence:** `scripts/run-tests.sh:97-101`, `scripts/health-check.sh:407`; `$SP/iter2-r2/gitignore-check.log`

---

## Claim 33: "T3 … The shared runner-contract.bash is not stamped (Q-071 [1]), and the reports and their sidecars are tracked by git."

**Location:** `test/skills/eval-helpers-freshness.bats:6-9`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** The not-stamped half is Verified (test "editing the shared runner-contract.bash does not stale a report" passes). "Tracked by git" holds only as "not gitignored": the pinning test checks `check-ignore`, and no report is tracked.

The pinning test is `run git -C "$root" check-ignore -q "test/skills/code-review/output/tc-x.$f"` (`test/skills/eval-helpers-freshness.bats:114`).

**Evidence:** `test/skills/eval-helpers-freshness.bats:110-119`; `$SP/iter2-r2/bats-eval-helpers-freshness.log`

---

## Claim 34: "<fixture>.stamp — its provenance (hashes of the skill, its runner and the fixture …); written only for a run that succeeded … All of these are meant to be committed once generated (Q-071 [1]; .gitignore admits them)"

**Location:** `test/skills/generate-reports.bash:12-20`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the stamp inputs and the `.gitignore` admission. Iteration-1 Claim 52 is resolved by 376a8a2's wording. It does not re-trace the success-only write (iteration 1 verified it).

The `generate-reports.bats` test asserts the stamp names `"skill runner fixture "` and passes (49/49). `.gitignore` admits the four suffixes (Claim 1).

**Evidence:** `test/skills/generate-reports.bash:10-20`, `test/generate-reports.bats:371-377`; `$SP/iter2-r2/bats-generate-reports.log`, `$SP/iter2-r2/gitignore-check.log`

---

## Claim 35: "Only the skill's own inputs are stamped … Shared harness files are deliberately not stamped … A stamp in an older format (one that also stamped the contract) reads as stale: 'stamp format'."

**Location:** `test/skills/runner-contract.bash:189-210`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers an old stamp whose other three lines still match. When a skill, runner or fixture input also changed, the message names that input instead of "stamp format". It does not cover generate-reports.bash or transcript.jq edits, which are not stamped by design.

`check_report_stamp` derives `changed` from `<` lines only. An extra `contract` line appears only as `>`, so `changed` is empty and prints `${changed:-stamp format}` (`test/skills/runner-contract.bash:221-223`). The freshness test "an old-format stamp that also hashed the contract reads as stale" passes.

**Evidence:** `test/skills/runner-contract.bash:189-225`; `$SP/iter2-r2/bats-eval-helpers-freshness.log`

---

## Claim 36: "Tests: 16 new bats cases … Against the previous scan 14 of the 15 new (a)-(f) cases fail"

**Location:** commit `d9a895d` message
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count of new `@test`s and their result against the d9a895d^ scan. It does not establish why each case fails (some fail on the new report format rather than on detection).

`git diff d9a895d^ d9a895d -- test/cc-isolated-functions.bats | grep -c '^+@test'` gives 17: 16 new plus 1 retitled. All 16 are (a)-(f) cases. I ran the d9a895d test file against the d9a895d^ `cc-isolated.sh` (cwd `$SP/iter2-r2/old`, exit 1, `oldscan.ts`). **15 of 16** fail; only "(f) an unreadable hook with control bytes in its name" passes.

Precise version: "15 of the 16". This resembles the logged count-mismatch pattern ("mode1-equiv 33 claimed … but holds 25"), though it is a miscount, not a fabrication.

**Evidence:** `test/cc-isolated-functions.bats:1351-1592`; `$SP/iter2-r2/oldscan-newtests.log`

---

## Claim 37: "Suites: cc-isolated-functions 125/125, install-host 92/92, fixture-hermeticity 2/2, hermeticity-lint 53/53; shellcheck -S warning clean."

**Location:** commit `d9a895d` message
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the cc-isolated-functions count (125/125 at 02d14b0) and shellcheck. install-host, fixture-hermeticity and hermeticity-lint were not run.

At d9a895d, `shellcheck -S warning -s bash test/cc-isolated-functions.bats` exits 1 with two SC2155 warnings, at lines 1565 and 1581, the control-byte tests. `cc-isolated.sh` is clean. a958372 then fixes the two warnings; at 02d14b0 all three shell files are clean. "shellcheck clean" held for the script, not for its test file.

**Evidence:** `test/cc-isolated-functions.bats:1561-1592`; `$SP/iter2-r2/shellcheck.log`, `$SP/iter2-r2/bats-cc-isolated-functions.log`

---

## Claim 38: "host `git status` recurses into a gitlink's repo and runs its fsmonitor -- verified" / "a fetch from the checkout ran none of its hooks, fsmonitor, uploadpack.packObjectsHook or remote settings on git 2.39"

**Location:** commit `d9a895d` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5. It also shows that an untracked embedded repo (not a gitlink) did not run its fsmonitor under `git status`.

`gitlink-fsmonitor.log`: `160000 … lib`, then `ran-gitlink-fsm`, then "untracked embedded: none". For the fetch half, see `separate-clone.log` (Claim 14).

**Evidence:** `$SP/iter2-r2/gitlink-fsmonitor.log`, `$SP/iter2-r2/separate-clone.log`

---

## Claim 39: "against this one the fact-check's own probes (zz-factcheck-extra*.bats X3/X4/X6/X7, r3-probe X4/X5/X6) now see findings or fail-closed status."

**Location:** commit `d9a895d` message
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers those seven probes at 02d14b0.

See Claim 3. X3, X4 and X7 give status 1; X6 gives 2; r3 X4, X5 and X6 give 1 (paraphrased — no quote available because the evidence is probe output already cited in Claim 3).

**Evidence:** `$SP/iter2-r2/iter1probes/*.log`

---

## Claim 40: "Tests: 7 new bats cases; 3 of them fail against the previous hook."

**Location:** commit `df11830` message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the df11830 test file against the df11830^ hook.

`git diff df11830^ df11830` adds 7 `@test`s. Against the old hook (cwd `$SP/iter2-r2/old`, exit 1), exactly "glob metacharacters …", "? in a deny rule …" and "a bare Bash deny rule …" fail.

**Evidence:** `test/auto-approve-allowed-commands.bats` (df11830 additions); `$SP/iter2-r2/oldhook-newtests.log`

---

## Claim 41: "The health-check shellcheck gate failed on two control-byte tests added in d9a895d."

**Location:** commit `a958372` message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two SC2155 warnings, run with the same `-s bash -S warning` flags health-check uses (`scripts/health-check.sh:480`). The health-check script itself was not run.

The two warnings are at `test/cc-isolated-functions.bats:1565` and `:1581` in d9a895d, both in the (f) control-byte tests.

**Evidence:** `scripts/health-check.sh:480`; `$SP/iter2-r2/shellcheck.log`

---

## Claim 42: "No report is tracked yet; the wording claimed they were."

**Location:** commit `376a8a2` message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the fact, and the two files the commit changed. The same wording survives in `.gitignore:4`, `scripts/run-tests.sh:101` and `test/skills/eval-helpers-freshness.bats:9` (Claims 1, 32 and 33).

`git show --stat 376a8a2` lists `guides/skill-creation.md` and `test/skills/generate-reports.bash`. `git ls-files` shows 0 reports.

**Evidence:** `guides/skill-creation.md:63`, `test/skills/generate-reports.bash:17`; `$SP/iter2-r2/gitignore-check.log`

---

## Claims Requiring Attention

### Incorrect
- **Claim 2** (`devcontainer-config/cc-isolated.sh:542-545`): "every file host git reads to decide what to run" misses two files, each reproduced on a vanilla repo with the scan returning 0. `.git/rebase-merge/git-rebase-todo` `exec` lines run on a host `git rebase --continue` (N12). `.git/remotes/<name>` files run a hook on a push to that name (N4).
- **Claim 5b** (`devcontainer-config/cc-isolated.sh:557-559`, code `:746`): a relative remote path containing `:` (e.g. `sub/a:b`) is local to git but classified non-local, so its hooks are never walked (N3).
- **Claim 10** (`devcontainer-config/cc-isolated.sh:583-589`): the LIMITS omit six reproduced shapes: N1 (a hook that runs a checkout file: husky, pre-commit), N12, N4, N2 (path-valued `remote.pushDefault`), N3 and N11.
- **Claim 12** (`devcontainer-config/cc-isolated.sh:843-844`): "anything else … is under a hooks dir … a symlink" is false. `-path '*/hooks/*'` matches ancestor or branch components, so under `…/hooks/…` every ref, log, object and index file is recorded as `link`, and every committing session exits 3 (N6, N7).
- **Claim 13** (`devcontainer-config/cc-isolated.sh:942-944`): the 0/1 contract fails in both directions (N12/N4 give 0; N6/N7 give 1).
- **Claim 19b** (`guides/cc-isolated-usage.md:50-52`): the "every file" coverage has the same gap as Claim 2.
- **Claim 21** (`guides/cc-isolated-usage.md:170-185`): the coverage has the gaps of Claims 2, 5b and 5c.
- **Claim 23** (`guides/cc-isolated-usage.md:193-209`): the limits list has the omissions of Claim 10. "Hooks … are the exception" overstates, because a hashed hook can run a rewritten checkout script (N1).

### Stale
- None.

### Mostly Accurate
- **Claim 1** (`.gitignore:4-7`): "are committed" should read "are meant to be committed". 0 reports are tracked.
- **Claim 5c** (`devcontainer-config/cc-isolated.sh:559-561`): a relative global hooksPath is walked only in the top-level working tree, not in submodules (N11).
- **Claim 8** (`devcontainer-config/cc-isolated.sh:571-578`): the tool list is incomplete (realpath, awk, sort, tr), and directory symlinks are entered. "Nothing from the checkout runs" holds.
- **Claim 9** (`devcontainer-config/cc-isolated.sh:580-581`): `scan_vis` keeps `\n`, and error text prints raw paths, so a file name can forge lines in the exit-4 warning (N13).
- **Claim 22** (`guides/cc-isolated-usage.md:185-193`): the same newline caveat as Claim 9.
- **Claim 24** (`guides/cc-isolated-usage.md:202-204`): drivers defined in the host's global config are not scanned.
- **Claim 32** (`scripts/run-tests.sh:100-101`): "reports are tracked" should read "meant to be tracked".
- **Claim 33** (`test/skills/eval-helpers-freshness.bats:6-9`): "tracked by git" should read "not gitignored".
- **Claim 36** (commit `d9a895d`): "14 of the 15" should be 15 of the 16 new (a)-(f) cases failing on the old scan.
- **Claim 37** (commit `d9a895d`): "shellcheck -S warning clean" was false for `test/cc-isolated-functions.bats` (2 × SC2155; fixed in a958372).

### Unverifiable
- **Claim 16b** (`devcontainer-config/cc-isolated.sh:1145-1146`): whether claude gets its own Ctrl-C needs a live TTY session.
- **Claim 17b** (`docs/decisions/log.md:76`): the #39344 hook-over-deny behaviour needs the issue tracker and a live Claude Code test.
- **Claim 28b** (`hooks/auto-approve-allowed-commands.sh:44-45`): the same as 17b.

---

## Goal-Alignment Note

- **Success criterion (restated verbatim):** A code-fact-check report saved at the dispatch path in the skill's schema, covering the claims above, with a Goal-Alignment Note.
- **Answered:**
  - Every iteration-1 Incorrect was re-checked by re-running its probes. 2, 5, 9, 18, 21, 24 and 64 are resolved; 23 persists with new omissions.
  - The redesigned scan's "never runs anything", coverage, fail-closed, symlink/FIFO and sanitisation claims were checked.
  - New bypass hunt: 6 reproduced false negatives (N1–N4, N11, N12), 2 false-positive shapes (N6, N7), 1 launch-refusal shape (N5), 1 terminal-forgery shape (N13); no hang (N8) and no awk-crash-to-0 (N9).
  - The guide's safe-push advice was executed.
  - Hook deny semantics, the pinned bypass tests, the header, wiring.json, decision log 53 and bare-host-hook-wiring were checked.
  - Runner-contract, .gitignore, generate-reports, skill-creation, health-check, run-tests and skill-format-audit text was checked.
  - Commit tallies were checked against old code.
- **Out of scope:** Skill SKILL.md bodies (pass 2). The install-host, fixture-hermeticity and hermeticity-lint suites were not re-run. The iteration-1 Claim 11 remediation commands and Claim 50 test-comment accuracy were not re-verified.
- **Escalate:**
  - N1 (a baseline hook running a checkout file) affects the common husky and pre-commit-framework setups with no unusual baseline. The guide's limits text currently implies hooks are safe.
  - N7 makes every committing session exit 3 for any checkout under a directory named `hooks`.
  - Both are author decisions (a documented limit or a code change).
- **Decisions I made:**
  - I rated N2, N3 and N11 as real but baseline-dependent, and N4 and N12 as requiring a specific later host command. Each Scope field says so.
  - I did not append to `docs/reviews/hallucination-patterns.md`, since the dispatch forbids modifying other repo files. No Incorrect verdict here is a fabrication anyway.
