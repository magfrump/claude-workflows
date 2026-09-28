Commit: a42e37f

# Code Fact-Check Report

**Repository:** /workspace (branch integrate/q076-q080, checked at a42e37f in a scratch clone)
**Scope:** pass 1, iteration 3: `git diff main...a42e37f -- . ':!skills'` (excl. guides/skill-format-audit.md, docs/reviews/), plus commit messages f35381f, c3d9223, 0a4862b, 4435c73. Replicate r1.
**Checked:** 2026-09-27
**Total claims checked:** 45 (44 numbered; Claim 11 split into 11a/11b)
**Summary:** 24 verified, 12 mostly accurate, 0 stale, 9 incorrect, 0 unverifiable

Paths: `$SP` = `/tmp/claude-1000/-workspace/dbfd30e0-d8d5-40c1-8bac-572239fc44fd/scratchpad`. Every execution ran in the scratch clone `$SP/iter3-r1/clone` (checked out at a42e37f) or in hermetic temp repos under `$SP/iter3-r1/exp` (HOME, GIT_CONFIG_GLOBAL overridden, GIT_CONFIG_NOSYSTEM=1), git 2.39.5, between 2026-09-27T23:45Z and 2026-09-28T00:05Z. Experiment scripts sit next to their logs (`exp/eN.sh` → `exp/eN.log`, run as `bash eN.sh` from `$SP/iter3-r1/exp`, script exit 0). /workspace was not modified apart from this report.

Environment note: the sandbox sets `LC_ALL=en_US.UTF-8`, which is not installed, so bash prints a `setlocale` warning into captured output. That warning made `test/install-host.bats` T3 fail (142 of 307) because the test compares `$output` exactly. Re-running with `env -u LC_ALL LANG=C.UTF-8` passes 92/92. This is an environment artefact, not a code defect.

Hallucination-pattern log: compared. Several entries concern test counts in commit messages. Every count checked here matched (139, 9, 307, 14).

---

## Claim 1: "Generated eval reports are to be committed once generated (Q-071 [1]; none yet): the report and every sidecar … Anything else a run might leave in output/ stays ignored."

**Location:** `.gitignore:4-13`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which `test/skills/*/output/` files are ignored and that none is tracked now. It does not establish that generate-reports writes only these four suffixes.
**Legibility-target:** for-orchestrator-synthesis

Lines 10-13 re-include `.report.md`, `.stamp`, `.failed` and `.transcript.jsonl`, and line 9 (`test/skills/*/output/*`) ignores `scratch.tmp`. `git ls-files 'test/skills/*/output/*'` returns `tracked: 0`, so the new "none yet" wording fixes iteration 2's Claim 1.

**Evidence:** `.gitignore:4-13`; `$SP/iter3-r1/gitignore.log` (cwd clone, exit 0, 2026-09-28T00:02:28Z)

---

## Claim 2: "This scan is a TRIPWIRE: main() snapshots what host git reads … anything added, removed or changed is named, and the launcher exits 3 instead of 0. It catches the common plants."

**Location:** `devcontainer-config/cc-isolated.sh:544-548`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the name-and-return-1 contract on the bats plant set and on common benign git operations. It does not cover the routes in Claims 4, 7 and 8, and a clean scan still does not mean "safe", as the header itself says.
**Legibility-target:** for-orchestrator-synthesis

`test/cc-isolated-functions.bats` passes 139/139 at a42e37f. In a hermetic repo, commit, tag, stash, `gc`, `pack-refs` and a completed `rebase -x` on a branch named `feat/hooks/config` produce scan rc 0. `git worktree add` produces rc 1, because a new `worktrees/*` git dir is a recorded item by design (`exp/e10.log`). The exit mapping is quoted: `1) exit 3 ;;   # the session planted something` (`cc-isolated.sh:1351`; enclosing `main()` ends at `:1354`, read).

**Evidence:** `devcontainer-config/cc-isolated.sh:544-548,1347-1353`; `$SP/iter3-r1/bats-set.log`; `$SP/iter3-r1/exp/e10.log`

---

## Claim 3: WHAT IS SNAPSHOTTED — git dirs "nested … at modules/** or worktrees/*, found by its HEAD; every embedded `.git` …; every common dir a `commondir` file names; every local-path remote … by its fixed layout … the legacy remotes/* and branches/* files, the in-progress rebase-merge/, rebase-apply/ and sequencer/ state … remote.pushDefault, branch.*.remote/pushRemote naming a path, url.<base>.insteadOf bases"

**Location:** `devcontainer-config/cc-isolated.sh:550-564`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the enumerated record set and the iteration-2 gaps N2-N7, N11-N13, P1 and P6 as the new bats cases plant them. It does not establish completeness: see Claims 4 and 8 for gaps, and the header itself disclaims completeness.
**Legibility-target:** for-orchestrator-synthesis

The layout walk is `_snap_gitdir` (`:977-1040`, read in full). It covers config/config.worktree (`:982-985`), `info/attributes` (`:986`), hooks (`:987`), the commondir target inside the checkout (`:989-996`), `remotes`/`branches` (`:998-1015`), `rebase-merge rebase-apply sequencer` (`:1017-1024`), symlinks (`:1027-1037`) and `_snap_nested` over `modules` and `worktrees` (`:1038-1039`). Nested git dirs are detected by `if [ -d "$g/objects" ] || [ -f "$g/commondir" ]` (`:969`). All 14 cases added by f35381f fail against a958372's `cc-isolated.sh` (14/14 `not ok`) and pass at a42e37f. Iteration-2 Incorrect Claims 5 (colon path), 13 (hooks component) and 15 (the 0/1 contract in the false-positive direction) are resolved for their reproductions.

**Evidence:** `devcontainer-config/cc-isolated.sh:550-564,977-1040`; `$SP/iter3-r1/old-a958372-new14.log` (cwd `$SP/iter3-r1/old`, exit 1 as expected, 2026-09-27T23:5xZ); `$SP/iter3-r1/bats-set.log`

---

## Claim 4: "your own global/system config, read with its includes evaluated for each git dir (includeIf gitdir:/gitdir/i: matched here; onbranch:/hasconfig: taken as matching)"

**Location:** `devcontainer-config/cc-isolated.sh:565-568` (also `:893-896`: "as git would for a command run in <working tree>")
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers gitdir matching against the physical path only. The absolute, non-realpath form that git also tries is never tested, so a checkout reached through a symlinked path is missed. The other pattern forms tested agree with git.
**Legibility-target:** for-author

The scan passes the realpath git dir and `"$_snap_ws/.git"` as the two candidate texts (`:1077`: `_snap_host_config "$_snap_gd" "$_snap_ws/.git" "$_snap_ws"`), and `_snap_ws` is physical: `_snap_ws="$(cd "$ws" && pwd -P)"` (`:1064`). Git's `include_by_gitdir` matches the realpath and also the absolute non-real git dir, which is the logical path the user's shell is in.

Reproduction (`exp/e8.log`). The host global config has `includeIf "gitdir:~/lnk/ws/"` → `core.hooksPath = .hk`, where `~/lnk` is a symlink to the checkout's parent. Host git run from `~/lnk/ws` reports `core.hooksPath` = `.hk`, while `git_exec_snapshot` records no `.hk` hooksdir (`scan-walks: 0`). A hook the session plants in `ws/.hk/` is therefore not a finding, and `git commit` run from the symlinked path runs it.

Nine other forms matched git: exact, trailing `/`, relative, `**`, single `*`, `?`, `gitdir/i:` upper-case, `onbranch:` and `hasconfig:`. The last is over-walked by design.

This is the residue of iteration-2 Claim 6. It is not listed in LIMITS or in the guide.

**Evidence:** `devcontainer-config/cc-isolated.sh:873-891,900-936,1064,1077`; `$SP/iter3-r1/exp/e8.log`

---

## Claim 5: "FAIL CLOSED. A directory that cannot be listed, a file that cannot be read or a config git cannot parse makes the snapshot fail: at launch the launcher refuses to start, at exit it returns 4."

**Location:** `devcontainer-config/cc-isolated.sh:572-575`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `_snap_find`, `_snap_hash` and `_snap_config` failure propagation, the launch refusal and exit 4. It does not establish a time bound: see Claim 10.
**Legibility-target:** for-orchestrator-synthesis

`_snap_find` fails on any find error: `if ! find -P "$@" -print0 > "$out" 2> "$out.err"; then … return 1` (`:714-716`). `_snap_hash` fails on an unreadable file: `if [ ! -r "$1" ] || ! h="$(sha256sum < "$1" …)"` (`:660`). The launch path runs `exit 1` after the ERROR block (`:1277-1286`), and `*) exit 4 ;;` handles exit (`:1352`).

Where a `.git` file is unreadable, `_snap_dotgit` hashes the entry (`:1045`) before `_snap_dotgit_target`'s `read … || true` (`:946`) can swallow the error, so the failure is not lost. A `.git/commondir` repointed to a directory with no config gave scan rc 2 in `exp/e6.log`. The bats unlistable-dir and unreadable cases pass.

**Evidence:** `devcontainer-config/cc-isolated.sh:648-665,712-718,1043-1048,1137-1154,1274-1288`; `$SP/iter3-r1/exp/e6.log`; `$SP/iter3-r1/bats-set.log`

---

## Claim 6: "THE SCAN RUNS NOTHING FROM THE REPO. … Config is read with `git config --file <f> --no-includes` from cwd /, … Everything else is find, stat, readlink and sha256sum; find never follows symlinks (-P)"

**Location:** `devcontainer-config/cc-isolated.sh:577-583`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the scan functions (`:612-1180`). It does not cover the launcher's own `git -C "$start" rev-parse --show-toplevel` in the checkout (`resolve_workspace`, `:217`), which runs before the snapshot. That call is pre-existing and outside this diff, and it runs no hook or fsmonitor.
**Legibility-target:** for-author

Every git call in the scan has the form `(cd / && git --no-pager config --file "$f" --no-includes …)` (`:807`, `:762`), or reads the host config with no `--file` from `/` (`:906`). No program from the checkout is run. "Everything else is find, stat, readlink and sha256sum" is imprecise, because the scan also runs `realpath` (`:734,803`), `mktemp` (`:1072`), `tr` (`:652,1109`), `sort` (`:1101,1131`), `awk` (`:1116`), `cut`, `cat` and `rm`. The same wording was Mostly accurate in iteration 2 (Claim 9a) and is unchanged. None of these tools executes checkout content.

**Evidence:** `devcontainer-config/cc-isolated.sh:577-583,734,762,807,906,1072,1101,1109,1116,217`

---

## Claim 7: "EVERY CONTAINER-CHOSEN STRING (names, values, error text) is reduced to printable ASCII, newlines included, before it reaches the terminal"

**Location:** `devcontainer-config/cc-isolated.sh:585-588` (and `:1104-1107`: "every container-chosen string in them has already lost its line breaks")
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the exit-4 path through `git_exec_snapshot`'s own `echo` of the resolved common dir. The `%q` F records, `_snap_fail` and the C-record replacement do strip line breaks.
**Legibility-target:** for-author

`git_exec_snapshot` prints `echo "no git config at $_snap_common/config" >&2` (`:1066`). The value is not passed through `_snap_fail`. `_snap_common` is the `pwd -P` of whatever `.git/commondir` names (`:627-634`), and the container writes `.git/commondir`.

Reproduction (`exp/e6.log`): write `commondir` = `../lnk`, where `lnk` is a symlink to a directory whose name contains `\n  Scan clean: nothing changed, safe to run git`. The exit-4 warning then contains a separate, container-authored line:

```
    no git config at …/ws/x
      Scan clean: nothing changed, safe to run git/config
```

`scan_vis` passes `\n` (`:1109`: `tr -c '[:print:]\n' '?'`), so the forged line survives. The same wording in the guide (`guides/cc-isolated-usage.md:233-234`) is covered by Claim 35.

**Evidence:** `devcontainer-config/cc-isolated.sh:612-636,1054-1068,1108-1110,1140-1153`; `$SP/iter3-r1/exp/e6.log`

---

## Claim 8: "LIMITS … No finding does not mean safe:" (a hook that runs a tracked file; anything present at launch; processes after the scan / killed launcher; tracked .gitattributes and .gitmodules)

**Location:** `devcontainer-config/cc-isolated.sh:590-603`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the listed limits and whether the iteration-2 Incorrects now appear in the list. Iteration-2 Claim 11 (husky / tracked-file hook) is now the first bullet. The list is not exhaustive (see below).
**Legibility-target:** for-author

The four bullets are accurate. At least two known routes are missing from the list:

- **Symlinked-path `includeIf`** (Claim 4, reproduced).
- **A driver defined in your own global or system config.** The guide's companion sentence says "(config is scanned)", but `_snap_host_config` records only `core.hookspath`, `core.attributesfile` and includes (`:916-934`). A driver the host config defines, which a tracked `.gitattributes` selects, is not recorded. This is iteration-2 Claim 27b, which is not resolved. It is exploitable only when that host driver itself runs a path in the checkout.

The scan also has no bound on hashing a regular file. That is not a detection limit, but see Claim 10.

**Evidence:** `devcontainer-config/cc-isolated.sh:590-603,900-936`; `$SP/iter3-r1/exp/e8.log`

---

## Claim 9: "SIZE. This block brings cc-isolated.sh to about 1360 lines."

**Location:** `devcontainer-config/cc-isolated.sh:605` (also commit 0a4862b: "corrects the SIZE note … (about 1360 lines)")
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the line count at a42e37f. It does not establish the stated reason for keeping the block inline.
**Legibility-target:** for-orchestrator-synthesis

`wc -l devcontainer-config/cc-isolated.sh` reports 1359 (paraphrased — no quote available because the claim is about file length, not a snippet).

**Evidence:** `devcontainer-config/cc-isolated.sh:605`

---

## Claim 10: "git_exit_scan <ws> <launch snapshot>: 0 when nothing the tripwire records changed; 1 … when something did; 2 when the exit state could not be read." (with f35381f: "Snapshot of /workspace (with 5 linked worktrees) takes about 5 s.")

**Location:** `devcontainer-config/cc-isolated.sh:1134-1136`; commit f35381f
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the 0/1/2 contract and the timing on /workspace. It does not establish a time bound when the container is adversarial: scan time grows linearly with file size, and a sparse file costs the container nothing to create.
**Legibility-target:** for-orchestrator-synthesis

**Timing.** `git_exec_snapshot /workspace` (6 worktrees listed, 570 records) took 3.24 s wall time (`perf-workspace.log`), consistent with "about 5 s".

**Contract.** rc values are covered by the bats suite (0, 1 and 2) and by `e6`/`e10`.

**Pathology.** The container can run `truncate -s 4G .git/hooks/pre-push`, which completes in 0 s and uses 0 bytes on disk. `_snap_hash` then runs `sha256sum` over 4 GiB of zeros, and the exit scan took 18 s (rc 1, `exp/e7.log`). At that rate a `truncate -s 1T` plant would take about 77 minutes, and a larger one longer still. `_snap_hash` has no size cap: `h="$(sha256sum < "$1" 2>/dev/null)"` (`:660`). The result is still a finding; only the delay is a problem.

**Evidence:** `devcontainer-config/cc-isolated.sh:657-665,1134-1180`; `$SP/iter3-r1/perf-workspace.log` (cwd `/`, exit 0, 2026-09-27T23:59:45Z); `$SP/iter3-r1/exp/e7.log`

---

## Claim 11a: "`git -c core.hooksPath=/dev/null -c core.fsmonitor=false push` is NOT a safe alternative: it still runs remote.*.receivepack"

**Location:** `devcontainer-config/cc-isolated.sh:1174-1175`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers receivepack with a local remote. It does not cover the other items in the same sentence (Claim 11b).
**Legibility-target:** for-orchestrator-synthesis

With hooks off, a planted `remote.origin.receivepack = "touch …/receivepack; git-receive-pack"` fired on push (`markers …: receivepack`, `exp/e11.log`).

**Evidence:** `devcontainer-config/cc-isolated.sh:1174-1176`; `$SP/iter3-r1/exp/e11.log` (exit 0, 2026-09-28T00:03:45Z)

---

## Claim 11b: "… it still runs … filters, includes, credential helpers and core.sshCommand."

**Location:** `devcontainer-config/cc-isolated.sh:1175-1176`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the "filters" atom for `git push`. The conclusion ("not a safe alternative") holds on receivepack alone. sshCommand and credential helpers do apply to ssh and https remotes and were not exercised here.
**Legibility-target:** for-author

Planted `filter.x.clean`/`smudge`/`process`, with `* filter=x` in `info/attributes` and a stat-dirty file, fired nothing on `git -c core.hooksPath=/dev/null -c core.fsmonitor=false push` (`markers after hooks-off push with planted filters:` empty, `exp/e11.log`). Push does not refresh the index or convert content, so no filter runs. "Includes" are config reads, not programs. The error errs toward caution, but the stated mechanism is wrong. The guide says the same at `guides/cc-isolated-usage.md:169-170` (Claim 30).

**Evidence:** `devcontainer-config/cc-isolated.sh:1174-1176`; `$SP/iter3-r1/exp/e11.log`

---

## Claim 12: "cc-push — push the commits a cc-isolated session made, without running anything the session could have planted in the checkout" / "cc-push never runs git in the checkout."

**Location:** `devcontainer-config/cc-push.sh:2-3,25`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers code execution from planted checkout content. The plants tested were the bats set, plus: early-config and pager discovery from a cwd inside the checkout; `init.templateDir`; `core.alternateRefsCommand` with a real `objects/info/alternates`; `uploadpack.packObjectsHook`; and host-global diff, textconv, pager and gpg settings.

It does not establish:
- that cc-push reads nothing but the named checkout: upload-pack follows `.git` gitdir redirects and includes (Claim 15);
- that cc-push always terminates: a FIFO include blocks it forever (Claim 15).

"Never runs git in the checkout" is contradicted by the same comment's own step 1, where upload-pack runs in the checkout.
**Legibility-target:** for-orchestrator-synthesis

Results:
- The full plant set fired no marker (bats `cc-push runs nothing planted…`, 9/9 pass).
- A first run from `cwd` inside a checkout carrying `core.fsmonitor`, `core.pager`, `pager.init`, `pager.check-ref-format`, `init.templateDir` and `core.hooksPath` plants fired nothing (`exp/e1.log`).
- The two git calls that run with the caller's cwd (`git init -q --bare "$clone"` `:124` and `git check-ref-format` `:157`) do not read the checkout's config. With a FIFO include in the cwd repo's config, both returned immediately while `git status` timed out (`crf=0 init=0 status=124`, run inline). This is a paraphrase — no quote available because it was an inline shell probe whose output is quoted here verbatim, not a log file.
- Alternates plus `alternateRefsCommand` fired nothing (`e2b`/`e2` E2a).
- A signed commit with host `log.showSignature=true` and a fake `gpg.program` fired nothing, while plain `git log` in the checkout did (`exp/e3b.log`).

**Evidence:** `devcontainer-config/cc-push.sh:1-204` (read in full); `test/cc-push.bats:44-116`; `$SP/iter3-r1/bats-set.log`; `$SP/iter3-r1/exp/e1.log`, `e2.log`, `e3.log`, `e3b.log`

---

## Claim 13: "--remote URL   the real remote, stored in the host-only clone (never read from the checkout)." / "2. `git fetch origin` — the real remote, as configured in the clone."

**Location:** `devcontainer-config/cc-push.sh:12-13,30`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers remote URL provenance. It does not establish that the refs fetched from "the checkout" come from the checkout's own object store (Claim 15).
**Legibility-target:** for-orchestrator-synthesis

The URL is written only by `hgit "$clone" config remote.origin.url "$remote"` (`:126`, `:135`) and read back from the clone (`:139`). With `remote.origin.url`, `remote.pushDefault` and `remotes/upstream` planted to point at `evil.git`, the suite asserts `for-each-ref` on `evil.git` is empty (`test/cc-push.bats:112`), and the test passes.

**Evidence:** `devcontainer-config/cc-push.sh:117-139`; `test/cc-push.bats:104-116`; `$SP/iter3-r1/bats-set.log`

---

## Claim 14: "--clone DIR    the host-only clone (default: $CC_PUSH_CLONES_DIR/<name>-<id>, CC_PUSH_CLONES_DIR defaulting to ~/.local/share/cc-isolated/clones)."

**Location:** `devcontainer-config/cc-push.sh:15-16`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the default-path expression. It does not cover `--clone` semantics.
**Legibility-target:** for-author

The code is `clone="${CC_PUSH_CLONES_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/cc-isolated/clones}/$name-$id"` (`:109`). When `XDG_DATA_HOME` is set, the default is `$XDG_DATA_HOME/cc-isolated/clones`, which neither the usage text nor the guide mentions (`guides/cc-isolated-usage.md:173`).

**Evidence:** `devcontainer-config/cc-push.sh:105-110`

---

## Claim 15: "1. `git fetch <checkout>` — git runs upload-pack in the checkout, which reads its refs, objects and config but runs no hook, no fsmonitor, no filter, and ignores uploadpack.packObjectsHook from repo config. Nothing is checked out."

**Location:** `devcontainer-config/cc-push.sh:27-29`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers "runs no hook/fsmonitor/filter/packObjectsHook" on git 2.39.5. It does not establish:
- that the refs and objects come from the checkout's own repository: a container-written `.git` gitdir file (or alternates) points upload-pack at any repository on the host the user can read, and cc-push then offers that repository's history for push;
- that the fetch terminates: an `include.path` naming a FIFO blocks upload-pack, and cc-push has no timeout.
**Legibility-target:** for-author

**No execution.** Covered by Claim 12 and bats.

**Gitdir redirect (E2c, `exp/e2b.log`).** Replacing `co/.git` with `gitdir: $T/other.git` made cc-push preview and push `6bdcbf0 …: OTHER REPO COMMIT` to origin, with exit 0 under `--yes`. The container needs only a path to redirect the fetch. The commit message of c3d9223 records this as a known limit ("upload-pack still parses the checkout's config and follows its .git/gitdir/alternates (reads only …)"), but neither the script header nor the guide mentions it.

**FIFO include (E2b).** `include.path = fifo` in the checkout's config made `timeout 15 cc-push --yes` end with 124 after 17 s. This is a denial of service, not execution.

**Evidence:** `devcontainer-config/cc-push.sh:141-149`; `$SP/iter3-r1/exp/e2b.log`

---

## Claim 16: "Every git call here passes core.hooksPath=/dev/null and core.fsmonitor=false, so your own global config cannot point hooks at anything either."

**Location:** `devcontainer-config/cc-push.sh:33-34`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the git invocations in cc-push.sh. The conclusion (no hooks run) holds, and neither bypassing call runs a hook.
**Legibility-target:** for-author

Most calls go through `hgit()`: `git -C "$c" -c core.hooksPath=/dev/null -c core.fsmonitor=false "$@"` (`:67-70`). Two calls do not: `git init -q --bare "$clone"` (`:124`) and `git check-ref-format "refs/heads/$branch"` (`:157`). Neither reads a repository or runs a hook (Claim 12 probe; `exp/e1.log`). The precise version is "every git call that touches a repository". Guide `:194-195` repeats the claim (Claim 34).

**Evidence:** `devcontainer-config/cc-push.sh:65-70,124,157`; `$SP/iter3-r1/exp/e1.log`

---

## Claim 17: "Exit codes: 0 pushed (or nothing to push), 1 usage or setup error, 2 declined."

**Location:** `devcontainer-config/cc-push.sh:42`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers exit statuses reachable under `set -euo pipefail`. Where 0, 1 and 2 are produced, they carry the stated meanings.
**Legibility-target:** for-author

Failing git commands that are not wrapped in `|| die` exit with git's own status:
- A clone path whose parent is unwritable makes `git init` (`:124`) fail with `fatal: cannot mkdir …` and **exit 128** (E5d).
- A push the remote rejects (pre-receive refusal, unwritable object store, or non-fast-forward) exits 1 from `hgit … push` (`:197`). The code is 1, but the cause is neither a usage nor a setup error (E5a, E5b).

A script branching on these codes would misclassify both.

**Evidence:** `devcontainer-config/cc-push.sh:42,44,119-128,197`; `$SP/iter3-r1/exp/e5.log`

---

## Claim 18: "Whatever the caller's environment points git at, cc-push chooses the repos."

**Location:** `devcontainer-config/cc-push.sh:46-48`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the repository-selecting variables: `GIT_DIR`, `GIT_WORK_TREE`, `GIT_COMMON_DIR`, `GIT_INDEX_FILE`, `GIT_OBJECT_DIRECTORY`, `GIT_ALTERNATE_OBJECT_DIRECTORIES`, `GIT_NAMESPACE` and `GIT_CEILING_DIRECTORIES`. It does not cover other `GIT_*` variables in the user's shell: `GIT_SSH_COMMAND`, `GIT_CONFIG_PARAMETERS`/`COUNT`, `GIT_EXEC_PATH`, `GIT_PAGER`. These are the user's own, not container-set, and `GIT_EXTERNAL_DIFF` is neutralised by `--no-ext-diff`.
**Legibility-target:** for-orchestrator-synthesis

The unset list is at `:47-48` (quoted in scope). With `GIT_EXTERNAL_DIFF="touch …/envextdiff; true"` exported, the preview fired no marker (`exp/e3.log`).

**Evidence:** `devcontainer-config/cc-push.sh:46-48`; `$SP/iter3-r1/exp/e3.log`

---

## Claim 19: "vis: control bytes (and anything outside printable ASCII) as '?', so a commit message or branch name the session wrote cannot rewrite the terminal."

**Location:** `devcontainer-config/cc-push.sh:54-58`
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every print of the session-chosen branch name. Commit subjects and author names in the log lines, and the diff stat, do pass through `vis`.
**Legibility-target:** for-author

The branch defaults to the checkout's HEAD symref (`:151-156`), which the container controls. It is validated only by `git check-ref-format` (`:157`), which accepts bytes ≥ 0x80. Three places print it without `vis`:

- `echo "Push $src ($co)"` and `echo "  to origin ($remote) as $branch."` (`:169-170`);
- `echo "origin has no branch $branch; …"` (`:181`);
- git's own push report from `hgit "$clone" push …` (`:197`).

Reproduction (`exp/e4.log`): a branch `feat\xc2\x9b31mX\xe2\x80\xaeevil`, i.e. U+009B C1 CSI followed by `31m`, then U+202E RLO. `check-ref-format rc=0`. The raw bytes reached the output: `od` shows `f e a t 302 233 3 1 m X 342 200 256 e v i l` on the "Push" and "as" lines and in `* [new branch] refs/cc/heads/feat…`. Only the final `Pushed feat??31mX???evil` line was filtered.

**Evidence:** `devcontainer-config/cc-push.sh:54-58,151-157,168-183,197-198`; `$SP/iter3-r1/exp/e4.log`

---

## Claim 20: refusal of a clone "inside the checkout, which the container can write"

**Location:** `devcontainer-config/cc-push.sh:111-115`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `--clone` and default paths that resolve inside the physical checkout path, symlinks included (`realpath -m`). It does not cover a clone inside a linked worktree's git dir that lives outside the checkout.
**Legibility-target:** for-orchestrator-synthesis

The check is `clone_real="$(realpath -m -- "$clone")"; case "$clone_real/" in "$co"/*) die …`, with `$co` from `pwd -P` (`:76`). The bats case refuses `--clone "$T/co/sub/clone"` with status 1 and creates nothing.

**Evidence:** `devcontainer-config/cc-push.sh:74-82,111-115`; `test/cc-push.bats:145-154`; `$SP/iter3-r1/bats-set.log`

---

## Claim 21: "The clone: created here, bare, marked with the checkout it serves. A directory cc-push did not create is never used (it could be a working tree with hooks)."

**Location:** `devcontainer-config/cc-push.sh:117-118,131-133`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the reuse check. It does not establish creation provenance.
**Legibility-target:** for-author

The test is the marker file, not creation: `[ -f "$clone/cc-push-checkout" ] || die …` and `[ "$(cat "$clone/cc-push-checkout")" = "$co" ]` (`:131-133`). Any existing directory holding a file named `cc-push-checkout` with the right path is used. A precise version is "a directory without cc-push's marker for this checkout is never used". The container cannot write outside the checkout, so this matters only for host-side mistakes. The bats case confirms a plain `git init` directory is refused.

**Evidence:** `devcontainer-config/cc-push.sh:117-138`; `test/cc-push.bats:150-153`

---

## Claim 22: "A local-path fetch: git runs upload-pack there and copies refs and objects; no submodules, no tags, no checkout. refs/cc/heads/* mirrors the checkout's branches (pruned)."

**Location:** `devcontainer-config/cc-push.sh:141-143`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the fetch flags and refspec. It does not cover the provenance caveat in Claim 15.
**Legibility-target:** for-orchestrator-synthesis

The fetch is `fetch -q --no-tags --no-recurse-submodules --no-write-fetch-head --prune "$co" '+refs/heads/*:refs/cc/heads/*'` (`:146-147`) into a bare clone. The destination prefix is fixed, so checkout refs cannot overwrite `refs/remotes/origin/*`, which the preview uses as its base.

**Evidence:** `devcontainer-config/cc-push.sh:146-149`; `$SP/iter3-r1/bats-set.log`

---

## Claim 23: "protocol.file.allow=always: a global "never" (which the guide suggests for other pushes) would refuse this one fetch that has to be local."

**Location:** `devcontainer-config/cc-push.sh:144-145`
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the parenthetical cross-reference. The override itself is present at `:146` and `:153`.
**Legibility-target:** for-author

No guide suggests it. `grep -rln 'protocol\.file\|protocol\.allow' . --include='*.md'` over the repo at a42e37f returns nothing. The only matches anywhere are `cc-push.sh:144,146,153` (paraphrased — no quote available because the claim covers the absence of a reference, established by a grep with no matching results).

**Evidence:** `devcontainer-config/cc-push.sh:144-146`

---

## Claim 24: "--no-ext-diff/--no-textconv: no diff program runs on the session's files; --no-show-signature: no gpg on its signatures"

**Location:** `devcontainer-config/cc-push.sh:166-167`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers program execution during the preview. The same comment's "output is plain text" is contradicted for the branch name (Claim 19).
**Legibility-target:** for-orchestrator-synthesis

The host global config was set up as follows:
- `core.attributesFile` → `* diff=x`;
- `diff.x.textconv`, `diff.x.command`, `diff.external`;
- `core.pager`, `pager.log`, `pager.diff`;
- `filter.x.*`;
- `log.showSignature=true` and `gpg.program`.

The fetched tree carried a tracked `.gitattributes` with `* diff=x filter=x`. A cc-push run fired no marker (`exp/e3.log`). A commit with a `gpgsig` header fired the fake gpg under plain `git log` in the checkout, but not under cc-push (`exp/e3b.log`). The calls are `log --no-show-signature` (`:178,182`) and `diff --no-ext-diff --no-textconv --stat` (`:179`), all under `--no-pager`.

**Evidence:** `devcontainer-config/cc-push.sh:166-183`; `$SP/iter3-r1/exp/e3.log`, `$SP/iter3-r1/exp/e3b.log`

---

## Claim 25: "4. From the clone, with your credentials; hooks off. A non-fast-forward is refused by the remote as usual: cc-push never forces."

**Location:** `devcontainer-config/cc-push.sh:195-197`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the refspec (no `+`) and remote rejection. The pushed ref is the same `refs/cc/heads/$branch` the preview read, and it is host-only, so the push matches the preview. It does not cover the remote moving between preview and push.
**Legibility-target:** for-orchestrator-synthesis

The call is `hgit "$clone" push origin "$src:refs/heads/$branch"` (`:197`). The bats "never forces" case passes: status ≠ 0, and the remote is unchanged.

**Evidence:** `devcontainer-config/cc-push.sh:185-198`; `test/cc-push.bats:177-184`; `$SP/iter3-r1/bats-set.log`

---

## Claim 26: install.sh usage "cc-isolated and cc-push linked into $CLAUDE_DEVC_BIN_DIR" and "The manifest hashes it like the launcher."

**Location:** `devcontainer-config/install.sh:35-36,596-603`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers shipping (PAYLOAD), chmod, the link and manifest hashing. The manifest is checked only by `cc-isolated` (`check_manifest`), so a rewritten cc-push.sh blocks the next launch but still runs when invoked directly: cc-push has no self-check.
**Legibility-target:** for-orchestrator-synthesis

The code has `PAYLOAD=(… cc-isolated.sh cc-push.sh …)`, `chmod +x … "$DEST/cc-push.sh"` and `ln -sf "$DEST/cc-push.sh" "$BIN_DIR/cc-push"`. `enforcement_files` echoes `cc-push.sh` (`cc-isolated.sh:117`). The results:
- `install-host.bats` passes 92/92 in a working locale;
- a blessed test config lists `cc-push.sh` once in the manifest;
- appending one line to cc-push.sh makes `check_manifest` print `ERROR: installed config changed since last bless — refusing to build/launch.` (`exp/e9.log`).

**Evidence:** `devcontainer-config/install.sh:110,596-603`; `devcontainer-config/cc-isolated.sh:108-132,134-208`; `$SP/iter3-r1/install-host-rerun.log` (exit 0); `$SP/iter3-r1/exp/e9.log` (2026-09-28T00:02:56Z)

---

## Claim 27: decision log row 53 amendment: "the hook reads Bash deny rules itself and never approves a match … a spelling without the literal name …, a glob …, a variable whose value is not spelled out in the same command still gets through; each of those three spellings is pinned by a test. In a deny rule only `*` is a wildcard, and a bare `Bash` deny rule blocks all approval."

**Location:** `docs/decisions/log.md:76`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers hook behaviour and the three pinned tests. Hook and wiring are unchanged since 02d14b0 (`git diff --stat 02d14b0 a42e37f` lists neither). It does not establish the #39344 upstream claim, which was Unverifiable in iteration 2.
**Legibility-target:** for-orchestrator-synthesis

Three tests pin the spellings: `string-match limit: a spelling without the literal name …` (`test/auto-approve-allowed-commands.bats:179`), `… a glob spelling …` (`:189`) and `… a variable set by an earlier command …` (`:197`). A fourth, `glob metacharacters other than * in a deny rule match literally`, is at `:216`. The auto-approve, link-claude-home-wiring, generate-reports and eval-helpers-freshness suites pass 118/118.

**Evidence:** `docs/decisions/log.md:76`; `hooks/auto-approve-allowed-commands.sh:113-160,260-266`; `$SP/iter3-r1/hook-runner.log` (exit 0)

---

## Claim 28: "It never approves a command that matches a `Bash(...)` deny rule … In a deny rule only `*` is a wildcard, and a bare `Bash` rule denies every command."

**Location:** `guides/bare-host-hook-wiring.md:151-156`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claim 27. "Denies every command" means the hook never approves (it falls through to the prompt), not that Claude Code denies.
**Legibility-target:** for-orchestrator-synthesis

See Claim 27; the same suite passes.

**Evidence:** `guides/bare-host-hook-wiring.md:151-156`; `$SP/iter3-r1/hook-runner.log`

---

## Claim 29: step 7: "Before step 4 the launcher snapshots what host git reads … exits **3** … It exits 4 when the exit scan cannot list or read any of it, and refuses to launch when the baseline snapshot cannot be taken."

**Location:** `guides/cc-isolated-usage.md:52-59`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers ordering and exit codes. It carries the same completeness residue as Claims 4 and 8.
**Legibility-target:** for-orchestrator-synthesis

The snapshot at `cc-isolated.sh:1274-1288` precedes `devcontainer up` (`:1306`), which is step 4 in the guide. Exit mapping is `:1349-1353`, and bats covers 3, 4 and launch refusal.

**Evidence:** `devcontainer-config/cc-isolated.sh:1274-1306,1347-1353`; `$SP/iter3-r1/bats-set.log`

---

## Claim 30: "`git -c core.hooksPath=/dev/null -c core.fsmonitor=false push` is **not** a safe alternative: it still runs a planted `remote.*.receivepack`, pushes to a repointed `remote.*.url`/`pushurl` …, and uses planted filters, includes, credential helpers and `core.sshCommand`."

**Location:** `guides/cc-isolated-usage.md:167-170`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the "filters" atom only. The receivepack atom is verified (Claim 11a), and the conclusion stands.
**Legibility-target:** for-author

The same finding as Claim 11b applies: planted clean/smudge/process filters fired nothing on a hooks-off push (`exp/e11.log`).

**Evidence:** `guides/cc-isolated-usage.md:167-170`; `$SP/iter3-r1/exp/e11.log`

---

## Claim 31: "It keeps a separate, bare clone that only the host writes (default `~/.local/share/cc-isolated/clones/<repo>-<id>`; override with `--clone` or `CC_PUSH_CLONES_DIR`)"

**Location:** `guides/cc-isolated-usage.md:172-174`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Same as Claim 14.
**Legibility-target:** for-author

The guide omits the `XDG_DATA_HOME` fallback at `cc-push.sh:109`.

**Evidence:** `devcontainer-config/cc-push.sh:109`

---

## Claim 32: "1. `git fetch <checkout>` into the clone … Git runs upload-pack in the checkout, which reads its refs, objects and config but runs no hook, fsmonitor or filter; nothing is checked out, no submodule is fetched." / "2. … Remotes are never read from the checkout."

**Location:** `guides/cc-isolated-usage.md:182-187`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claims 13 and 15. The guide does not disclose that a container-written `.git` gitdir or alternates can make cc-push fetch, and offer to push, another host repository's history, or that a FIFO include hangs it.
**Legibility-target:** for-author

See Claims 13, 15 and 22.

**Evidence:** `guides/cc-isolated-usage.md:182-187`; `$SP/iter3-r1/exp/e2b.log`

---

## Claim 33: "3. Prints the commits and diff stat the push adds (control bytes as `?`, no external diff or textconv, no signature check)"

**Location:** `guides/cc-isolated-usage.md:188-190`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the "control bytes as ?" atom. "No external diff or textconv, no signature check" is verified (Claim 24).
**Legibility-target:** for-author

The session-chosen branch name is printed raw in three lines plus git's push report (Claim 19, `exp/e4.log`). A minor imprecision as well: the diff stat is printed only when origin already has the branch (`:171-179`). For a new branch only the log is shown (`:181-182`).

**Evidence:** `devcontainer-config/cc-push.sh:168-183`; `$SP/iter3-r1/exp/e4.log`

---

## Claim 34: "Every git call it makes passes `core.hooksPath=/dev/null` and `core.fsmonitor=false`. `test/cc-push.bats` plants hooks (every name), fsmonitor, … and asserts that a `cc-push` fires none of them and pushes the fetched commit (git 2.39)."

**Location:** `guides/cc-isolated-usage.md:194-200` (also commit c3d9223: "the full plant set (every hook name, …)")
**Type:** Behavioral / Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the plant list against `test/cc-push.bats:46-86` and the assertions. The planted `core.alternateRefsCommand` has no `objects/info/alternates` in the suite, so it could not fire anyway; E2a added alternates, and still no marker fired.
**Legibility-target:** for-author

**"Every git call".** See Claim 16: `git init` and `git check-ref-format` bypass `hgit`, and neither is harmful.

**"Hooks (every name)".** The plant loop names 18 files: `pre-push … pre-upload upload-pack` (`:48-50`). It omits real hook names such as `commit-msg`, `prepare-commit-msg`, `pre-rebase`, `applypatch-msg`, `pre-merge-commit`, `proc-receive`, `sendemail-validate` and `p4-*`. The "fires none" and "pushes the fetched commit" assertions pass (`:110`, `:109`).

**Evidence:** `test/cc-push.bats:44-116`; `$SP/iter3-r1/bats-set.log`; `$SP/iter3-r1/exp/e2.log`

---

## Claim 35: exit-scan paragraph: "Your own global and system config is read with its includes evaluated for each git dir (`includeIf "gitdir:…"` and `gitdir/i:` matched …) … and every name, value and error it prints is reduced to printable ASCII, line breaks included."

**Location:** `guides/cc-isolated-usage.md:227-234`
**Type:** Behavioral / Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two atoms named. The recorded-set enumeration in the same paragraph (`:216-226`) is verified (Claim 3), and "runs nothing from the checkout" is covered by Claim 6.
**Legibility-target:** for-author

The `gitdir:` atom misses a symlinked logical path (Claim 4, `exp/e8.log`). The "line breaks included" atom is refuted by the unfiltered `_snap_common` echo (Claim 7, `exp/e6.log`).

**Evidence:** `guides/cc-isolated-usage.md:227-234`; `$SP/iter3-r1/exp/e6.log`, `$SP/iter3-r1/exp/e8.log`

---

## Claim 36: "It **cannot** be complete, so a clean exit is not permission to run git in the checkout. Known routes it does not see:" (tracked-file hook; anything present at launch; after the scan; no scan; tracked .gitattributes/.gitmodules; host programs)

**Location:** `guides/cc-isolated-usage.md:236-257`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the listed routes (accurate) and known omissions. The framing ("cannot be complete") does not claim exhaustiveness.
**Legibility-target:** for-author

Every listed route matches the code. Iteration-2 Incorrect 27a (the husky omission) is now the first bullet, and the "Hooks … are the exception" wording is gone. The list omits two routes: the symlinked-path `includeIf` (Claim 4, reproduced) and host-config-defined drivers (Claim 37).

**Evidence:** `guides/cc-isolated-usage.md:236-257`; `$SP/iter3-r1/exp/e8.log`

---

## Claim 37: "**Tracked `.gitattributes` and `.gitmodules`.** Not scanned. An attribute selects a driver that config defines (config is scanned)"

**Location:** `guides/cc-isolated-usage.md:252-254`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what "config is scanned" means. Repository configs (every git dir walked) are hashed in full; the user's global and system config is read only for hooksPath, attributesFile and includes, and is not recorded.
**Legibility-target:** for-author

`_snap_host_config` acts only on `core.hookspath`, `core.attributesfile` and `include.path|includeif.*.path` (`cc-isolated.sh:916-934`). Its header states the rest is not recorded: "Entries are not recorded (the container cannot write these files …)" (`:897-899`). A tracked attribute can therefore select a driver from your global config without any recorded change. This is iteration-2 Claim 27b, still unqualified here. The container cannot change that driver, so it matters only when the driver runs a path in the checkout.

**Evidence:** `devcontainer-config/cc-isolated.sh:893-936`; `guides/cc-isolated-usage.md:252-254`

---

## Claim 38: "Decision 034 set "the host never reads a container-written `.git`" for the benchmark harness; `cc-push` applies the same rule to pushing."

**Location:** `guides/cc-isolated-usage.md:259-261`
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the decision reference. "Applies the same rule" is an approximation: cc-push's upload-pack does read the container-written `.git` (refs, objects, config). What it avoids is executing anything from it.
**Legibility-target:** for-orchestrator-synthesis

`docs/decisions/034-crb-egress-allowlist-and-disposable-clones.md:34` reads `**1. The host never reads a container-written `.git`.**`.

**Evidence:** `docs/decisions/034-crb-egress-allowlist-and-disposable-clones.md:34`

---

## Claim 39: "The enforcement set: what cc-isolated.sh's enforcement_files() hashes, as repo paths. Keep in step with that function."

**Location:** `hooks/live-verify-gate.sh:70-73`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers cc-push.sh's presence in the regex and the in-step test. It does not re-check the gate's other behaviour beyond its suite passing (21/21).
**Legibility-target:** for-orchestrator-synthesis

The regex now contains `cc-push\.sh`. `test/hooks/live-verify-gate.bats` passes 21/21 at a42e37f. With the pre-4435c73 gate, its "every manifest-hashed file is in the enforcement set" test fails with `not gated: cc-push.sh` (`gate-before-4435c73.log`).

**Evidence:** `hooks/live-verify-gate.sh:73`; `$SP/iter3-r1/gate-sc.log` (exit 0); `$SP/iter3-r1/gate-before-4435c73.log` (2026-09-28T00:04:31Z, exit 1 as expected)

---

## Claim 40: "Stamping this file made every edit to it stale every skill's reports, which kept the committed reports red under this repo's editing rate."

**Location:** `test/skills/runner-contract.bash:192-194`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the "committed reports" noun. The stamp now covers skill, runner and fixture only (`:198-203`), and the eval-helpers-freshness suite passes.
**Legibility-target:** for-author

`report_stamp` stamps only `skill`, `runner` and `fixture` (`:198-203`). No report is committed (`tracked: 0`, `gitignore.log`), so "kept the committed reports red" describes reports that do not exist. The precise version is "would keep committed reports red". This is the same wording family that 376a8a2 and 7dc7843 corrected elsewhere.

**Evidence:** `test/skills/runner-contract.bash:181-203`; `$SP/iter3-r1/gitignore.log`; `$SP/iter3-r1/hook-runner.log`

---

## Claim 41: commit f35381f: "Tests: 14 new bats cases … All 14 fail against a958372's cc-isolated.sh and pass here; the 125 existing cases still pass. cc-isolated-functions 139/139; with install-host, fixture-hermeticity, hermeticity-lint, cc-push, guide-index-sync, cross-reference-integrity, function-inventory: 307/307. shellcheck -S warning clean."

**Location:** commit `f35381f` message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the counts and outcomes at a42e37f, and shellcheck on the touched shell files. Install-host needs a working locale to reach 92/92 (see the environment note). Whether all 14 old-code failures are for the intended reason was not examined case by case.
**Legibility-target:** for-orchestrator-synthesis

The results:
- `grep -c '^@test'` gives 139 for cc-isolated-functions and 9 for cc-push.
- The 8-suite run gives `1..307`, with 306 ok and the one locale-caused failure; that failure passes on re-run (92/92).
- The 14 new cases give 14/14 `not ok` with a958372's `cc-isolated.sh`.
- `shellcheck -S warning` on `cc-push.sh`, `cc-isolated.sh`, `test/cc-push.bats`, `test/cc-isolated-functions.bats`, `live-verify-gate.sh` and `auto-approve-allowed-commands.sh` gives `SC EXIT 0`.

No "401/401" figure appears in any commit message in `main..a42e37f`. That grep found nothing, so it is not verdicted.

**Evidence:** `$SP/iter3-r1/bats-set.log` (started 2026-09-27T23:49:15Z); `$SP/iter3-r1/install-host-rerun.log`; `$SP/iter3-r1/old-a958372-new14.log`; `$SP/iter3-r1/gate-sc.log`

---

## Claim 42: commit c3d9223: "Tests: test/cc-push.bats (9 cases) … No git command runs in the checkout; the checkout is found by plain `.git` tests." and "Known limit: upload-pack still parses the checkout's config and follows its .git/gitdir/alternates (reads only; verified no marker fires on git 2.39)."

**Location:** commit `c3d9223` message
**Type:** Reference / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count, the "no git command in the checkout" sentence and the known-limit note.
**Legibility-target:** for-author

The claims check out against the code:
- There are 9 cases, all passing.
- `find_checkout` uses plain tests: `if [ -e "$d/.git" ] || [ -L "$d/.git" ]` (`cc-push.sh:78`).
- "No git command runs in the checkout" is contradicted by the message's own step 1: upload-pack runs there.
- The known-limit note is accurate: E2c reproduced the gitdir follow.

The note's consequence is left out of the header and the guide: the followed repository's history is offered for push to origin.

**Evidence:** `devcontainer-config/cc-push.sh:72-82,141-149`; `$SP/iter3-r1/exp/e2b.log`; `$SP/iter3-r1/bats-set.log`

---

## Claim 43: commit 4435c73: "c3d9223 added cc-push.sh to cc-isolated.sh's enforcement_files() …, but the gate's path regex was not kept in step, so test/hooks/live-verify-gate.bats "every manifest-hashed file is in the enforcement set" failed on the integration branch."

**Location:** commit `4435c73` message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the named test failing before and passing after. It does not establish when on the branch the failure was first observed.
**Legibility-target:** for-orchestrator-synthesis

See Claim 39: `not gated: cc-push.sh` with the old gate; 21/21 with the new one.

**Evidence:** `$SP/iter3-r1/gate-before-4435c73.log`; `$SP/iter3-r1/gate-sc.log`

---

## Claim 44: commit f35381f: "P1: your global/system config is read with --show-origin and its include/includeIf followed by the scan, evaluating gitdir:/gitdir/i: against the git dir … No git runs in the checkout."

**Location:** commit `f35381f` message
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the P1 mechanism as the commit states it. "Against the git dir" is literally what the code does; git also evaluates against the logical path.
**Legibility-target:** for-author

`--show-origin` and scan-side include following are as described (`cc-isolated.sh:906-934`). "Against the git dir" matches the realpath, which is narrower than git's rule, so the symlinked route is missed (Claim 4). "No git runs in the checkout" holds for the scan (Claim 6).

**Evidence:** `devcontainer-config/cc-isolated.sh:873-936,1077`; `$SP/iter3-r1/exp/e8.log`

---

## Claims Requiring Attention

### Incorrect
- **Claim 4** (`devcontainer-config/cc-isolated.sh:565-568`): host `includeIf gitdir:` is matched only against physical paths. Host git run from a symlinked path to the checkout matches, and runs a `.hk` hook the scan never walks. This is not in LIMITS.
- **Claim 7** (`devcontainer-config/cc-isolated.sh:585-588`): `echo "no git config at $_snap_common/config"` (`:1066`) prints a container-chosen path unfiltered for newlines. A `commondir` → symlink → newline-named directory forges a line in the exit-4 warning.
- **Claim 11b** (`devcontainer-config/cc-isolated.sh:1175-1176`): a hooks-off `git push` runs no clean/smudge/process filter. Drop "filters" (and "includes") from the list of what push runs.
- **Claim 17** (`devcontainer-config/cc-push.sh:42`): exit 128 on a git fatal (e.g. `git init` of an unwritable clone path), and exit 1 on a remote-rejected push. List both, or wrap the calls.
- **Claim 19** (`devcontainer-config/cc-push.sh:54-58`): the session-chosen branch name (C1 CSI U+009B, RLO U+202E pass `check-ref-format`) is printed raw at `:169-170`, `:181` and in git's push report.
- **Claim 23** (`devcontainer-config/cc-push.sh:144-145`): no guide suggests `protocol.file.allow=never`.
- **Claim 30** (`guides/cc-isolated-usage.md:167-170`): same as 11b.
- **Claim 33** (`guides/cc-isolated-usage.md:188-190`): "control bytes as `?`" is false for the branch name (Claim 19). The diff stat is shown only when origin has the branch.
- **Claim 35** (`guides/cc-isolated-usage.md:227-234`): the gitdir-matching atom (Claim 4) and the "line breaks included" atom (Claim 7).

### Stale
- None.

### Mostly Accurate
- **Claim 6** (`cc-isolated.sh:577-583`): the scan's tool list omits realpath, mktemp, tr, sort, awk, cut, cat and rm. None runs checkout content.
- **Claim 8** (`cc-isolated.sh:590-603`): LIMITS omits the symlinked-path includeIf route and host-config-defined drivers (iteration-2 27b).
- **Claim 14** (`cc-push.sh:15-16`): the default clone dir also honours `XDG_DATA_HOME`.
- **Claim 16** (`cc-push.sh:33-34`): `git init` (`:124`) and `git check-ref-format` (`:157`) bypass `hgit`. Both are inert.
- **Claim 21** (`cc-push.sh:117-118`): reuse is gated by the marker file's content, not by creation.
- **Claim 31** (`guides/cc-isolated-usage.md:172-174`): the `XDG_DATA_HOME` default is not mentioned.
- **Claim 34** (`guides/cc-isolated-usage.md:194-200`, c3d9223): "every hook name" is 18 names, and "every git call" has two exceptions.
- **Claim 36** (`guides/cc-isolated-usage.md:236-257`): same omissions as Claim 8.
- **Claim 37** (`guides/cc-isolated-usage.md:252-254`): "(config is scanned)". The global/system config is not recorded.
- **Claim 40** (`test/skills/runner-contract.bash:192-194`): "kept the committed reports red", but no report is committed.
- **Claim 42** (commit c3d9223): "No git command runs in the checkout" contradicts its own step 1. The gitdir-follow limit is accurate but absent from the header and the guide.
- **Claim 44** (commit f35381f): gitdir is evaluated against the realpath only.

### Unverifiable
- None. The #39344 upstream claim was left out of scope; it is unchanged since iteration 2, where it was Unverifiable.

### Verified with a residue the synthesis should carry
- **Claims 12, 15, 32** (`cc-push.sh:2-3,25,27-29`; guide `:182-187`): cc-push executes nothing from the checkout on git 2.39.5 across every plant tried. The residue:
  - a container-written `.git` gitdir file makes cc-push fetch another host repository and offer its history for push; under `--yes` it pushes it (E2c);
  - a FIFO `include.path` hangs cc-push indefinitely (E2b).
- **Claim 10** (`cc-isolated.sh:1134-1136`): a sparse file planted as a hook makes the exit scan hash it at about 4.4 s/GiB, with no cap (E7).

---

## Goal-Alignment Note
- **Success criterion (restated verbatim):** A code-fact-check report saved at the dispatch path in the skill's schema, covering the claims above, with a Goal-Alignment Note.
- **Answered:**
  - **cc-push** (all brief bullets):
    - never runs code from the checkout: yes on 2.39.5 across the bats plants plus early-config, templateDir, alternates + alternateRefsCommand, host-global diff/textconv/pager/gpg, and `GIT_EXTERNAL_DIFF`;
    - never reads the checkout's remotes: yes;
    - reads other host repos through a planted gitdir: yes (new, reproduced);
    - hangs on a FIFO include: yes;
    - every call hooks-off: two inert exceptions;
    - fetch flags, clone refusal and marker semantics: checked (Claims 20-22);
    - preview sanitisation fails for branch names (new, reproduced);
    - exit codes wrong (128);
    - pushes exactly what it showed: yes;
    - never forces: yes.
  - **install.sh, the trust manifest and the gate**: verified. The pre-fix gate failure was reproduced.
  - **Exit scan**:
    - iteration-2 Incorrects 5, 13 and 15 (false-positive direction) are fixed, and 11 and 27a are now listed;
    - 6 is partly fixed, with a symlink-path residue that is new and reproduced;
    - 27b is still unqualified;
    - 10 has a new newline-forging path, reproduced;
    - the layout detection gave no false positives on benign operations;
    - performance is 3.2 s on /workspace, with a sparse-file pathology.
  - **Hook, decision 53, .gitignore and runner-contract**: no regression. Tests pass, and one "committed reports" wording is left.
  - **Commit claims**: counts verified. "401/401" appears nowhere in the commits.
- **Out of scope:** skills/*/SKILL.md (pass 2); live container behaviour (Ctrl-C, `docker stop`); ssh/https remote paths for sshCommand and credential helpers; the `~user/` form of include and hooksPath paths (not exercised).
- **Escalate:**
  - Claim 15's gitdir redirect: `cc-push --yes` can publish a private host repository's history to the session's remote. The prompt shows it, but `--yes` does not stop for it. Decide whether cc-push should refuse a checkout whose `.git` is not a directory, or whose `gitdir:` or `objects/info/alternates` points outside the checkout.
  - Claim 19: the branch name reaches the terminal raw.
- **Decisions I made:**
  - The environment-caused install-host T3 failure is not charged to the code.
  - "filters" in the not-safe-alternative list is verdicted Incorrect under the compound-claim rule, even though it errs toward caution.
  - The FIFO hang and the sparse-file delay are treated as residues of Verified claims, not as Incorrect.
