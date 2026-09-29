# Code Fact-Check Report

**Commit:** 9075003
**Repository:** claude-workflows (worktree `/workspace/.claude/worktrees/agent-aaad54fc687b7548c`, branch `q094-exit-scan-worktree-layout`)
**Scope:** `git diff dfe4c0d..9075003 -- . ':!docs/reviews'` — `devcontainer-config/cc-exit-scan.sh`, `devcontainer-config/cc-isolated.sh`, `docs/working/plan-q094-exit-scan-worktree-layout.md`, `guides/cc-isolated-usage.md`, `test/cc-isolated-functions.bats`, plus the 7 commit messages 6abe247..9075003. Code read with `git show q094-exit-scan-worktree-layout:<path>`; executed from `git archive` extracted to `/tmp/claude-1000/-workspace/0d5be710-0e7c-4a4f-8e65-09d2e983c2f5/scratchpad/fcA-k7q2/src` (the review worktree was not touched).
**Checked:** 2026-09-28 (executions 2026-09-29T03:10Z–03:25Z UTC; git 2.39.5, bats, `LC_ALL=C`, `GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1` for scratch repos)
**Total claims checked:** 40 (Claims 1–37 plus 38a–38c)
**Summary:** 34 verified, 4 mostly accurate, 2 stale, 0 incorrect, 0 unverifiable (one Unverifiable residue is carried inside Claim 16's Scope, not as a separate claim)

Execution logs (all under `/tmp/claude-1000/-workspace/0d5be710-0e7c-4a4f-8e65-09d2e983c2f5/scratchpad/fcA-k7q2/logs/`, abbreviated `$L` below):
- `$L/bats-q094.txt` — `TMPDIR=$D/tmp LC_ALL=C bats -f 'Q-094' test/cc-isolated-functions.bats`, cwd `$D/src`, exit 0, 2026-09-29T03:10:15Z — 9/9 ok.
- `$L/bats-full.txt` — the whole `test/cc-isolated-functions.bats`, cwd `$D/src`, started 2026-09-29T03:16Z, exit 0, 169/169 ok.
- `$L/exp-e.txt`, `$L/exp-e2.txt` — `bash $D/exp/e.sh …`, `bash $D/exp/e2.sh …` (plan experiments E1–E12, B29, B30), cwd `$D/exp`, exit 0 / 2 (the 2 is the final `ls` of the removed `worktrees/` dir, which is the E12 result), 03:12Z.
- `$L/exp-s.txt` — `bash $D/exp/s.sh $D/exp/x3 $D/src` (W records per config form, host-config hooksPath, FIFO config), exit 0, 03:13Z.
- `$L/exp-n.txt` — `bash $D/exp/n.sh $D/exp/x5 $D/src` (record diff of one worktree; worktree-name sanitising), exit 0, 03:20Z.
- `$L/mut-m1.txt` … `$L/mut-m6.txt` — mutation runs (m1: drop `-f` in `_snap_worktree_of`; m2: revert both `scan_std_worktrees` checks to `printf | grep -q`; m3: drop `""` from the insteadOf guard; m4: drop the back-pointer regular-file check; m5: drop the insteadOf guard line; m6: revert only the W check), cwd `$D/m<N>`, 03:13Z–03:16Z; each mutation made its target test fail (m1: snapshot `timeout 20` → rc 124).

(`$D` = `/tmp/claude-1000/-workspace/0d5be710-0e7c-4a4f-8e65-09d2e983c2f5/scratchpad/fcA-k7q2`.)

Hallucination pattern log (`docs/reviews/hallucination-patterns.md`) read: its 5 entries are corpus-statistic / test-count / consumer-list fabrications; no claim in this unit asserts a test count, corpus statistic or consumer list, so none matches a logged pattern.

Legibility target: every claim is tagged `**Legibility target:**` (who acts on it: `reader-of-code`, `operator` (guide/--help reader), `reviewer` (plan/commit reader)).

---

## Claim 1: "When every difference is a linked worktree added in git's own layout (agent worktrees outlive sessions), the scan prints one `note:` and returns 0 (scan_std_worktrees has the rule)."

**Location:** `devcontainer-config/cc-exit-scan.sh:75-77`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `git_exit_scan` returning 0 with exactly one `note:` line for a single standard `git worktree add` (host form and container form) and the launcher passing claude's status; does not establish acceptance of multiple simultaneous worktrees beyond the code reading (the loop at :839-890 handles N, not separately executed).
**Legibility target:** reader-of-code

`git_exit_scan` calls the acceptance before rendering and returns 0:

```bash
# devcontainer-config/cc-exit-scan.sh:934-938
  local note
  if [ -z "$invalid" ] && note="$(scan_std_worktrees "$ws" "$before" "$after" 2>/dev/null)"; then
    printf '%s\n' "$note" | scan_vis >&2
    return 0
  fi
```
(excerpt ends :938; enclosing `git_exit_scan()` continues to :970 — read)

Test "a new worktree in git's standard layout is one note and status 0" asserts `status 0` and `wc -l == 1` and passed (`$L/bats-q094.txt`, ok 1).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:904-970`, `test/cc-isolated-functions.bats:2227-2240`, `$L/bats-q094.txt`

---

## Claim 2: "In a linked worktree git takes config, hooks and info/attributes from the common dir, never the private one (tested on git 2.39.5; the one exception, config.worktree under extensions.worktreeConfig, refuses the note)."

**Location:** `devcontainer-config/cc-exit-scan.sh:77-80`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5's resolution of `hooks`, `info/attributes`, `config` (to the common dir) and `config.worktree` (private, honoured only with `extensions.worktreeConfig`), and that a `config.worktree` in P declines the note; does not establish behaviour of other git versions.

Re-run in a scratch repo (`$L/exp-e.txt`): `git -C wt rev-parse --git-path` gave the common dir for `hooks`, `info/attributes`, `config`, and the private dir for `config.worktree`; executable hooks in `P/hooks` did not run while the common `post-commit` did; `* filter=x` in `P/info/attributes` did not run the filter (control in the common `info/attributes` did); `core.hooksPath`/`core.fsmonitor` in `P/config` were not used (`git -C wt config --get core.hooksPath` → not visible); `config.worktree` hooksPath was ignored until `extensions.worktreeConfig=true`, then ran. The note refusal for `config.worktree`:

```bash
# devcontainer-config/cc-exit-scan.sh:856
    for k in hooks config config.worktree; do [ ! -e "$p/$k" ] && [ ! -L "$p/$k" ] || return 1; done
```
(single line inside `scan_std_worktrees()` :806-896 — read)

Bats "a private dir git would also accept (… hooks, config, links) warns" covers `config.worktree` (ok 5).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:856`, `test/cc-isolated-functions.bats:2288-2313`, `$L/exp-e.txt`, `$L/bats-q094.txt`

---

## Claim 3: "A relative core.hooksPath, core.attributesFile or local remote (not ".") in repo config would resolve in the new worktree's own tree, unscanned: those leave W records, and any W record refuses the note."

**Location:** `devcontainer-config/cc-exit-scan.sh:80-83`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers W production for relative `core.hooksPath`, `core.attributesFile`, `remote.*.url/pushurl`, `remote.pushDefault`/`branch.*.(push)remote` naming a path, legacy `remotes/*` files, and insteadOf bases (incl. `.` and `""`), and the refusal at :813; does not establish that W is limited to configs whose paths resolve in the *new* worktree — any config the scan reads (e.g. an embedded repo with `remote.o.url ../up`) also produces W and refuses the note (a conservative false positive, executed: `rc=1`).

Git resolving these in the new worktree: E7 (relative hooksPath ran), E8 (relative attributesFile filter ran), E9 (relative remote `pre-receive` ran) re-run in `$L/exp-e.txt` / `$L/exp-e2.txt`. W per config form (`$L/exp-s.txt`): `core.hooksPath .h`, `core.attributesFile a`, `remote.o.url ./x`, `sub/a:b`, `pushurl ../p`, `pushDefault ./q`, `branch.main.pushRemote rel`, `url.rel/./"".insteadOf` → W; `~/h`, `/abs`, `.`, `host:x`, `branch.main.remote .`, `url./abs.insteadOf`, `include.path rel` → none. Refusal:

```bash
# devcontainer-config/cc-exit-scan.sh:813
  [[ $'\n'"$after" != *$'\n'W$'\t'* ]] || return 1
```
(single line inside `scan_std_worktrees()` :806-896 — read)

**Evidence:** `devcontainer-config/cc-exit-scan.sh:287-294`, `:346-369`, `:372-421`, `:813`, `$L/exp-s.txt`, `$L/exp-e.txt`, `$L/exp-e2.txt`

---

## Claim 4: "(Your own config's relative hooksPath is walked in each new worktree, so its records refuse the note as well.)"

**Location:** `devcontainer-config/cc-exit-scan.sh:83-84`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the host-form worktree (its `.git` resolves on the host), where the walk happens and the note is refused; does not hold for a container-form worktree whose `/workspace/…` path does not exist on the host — there the host config is not walked in it and the note passes.

`_snap_host_config` runs for an embedded `.git` only when its target resolves:

```bash
# devcontainer-config/cc-exit-scan.sh:697-702
    while IFS= read -r -d '' f; do
      [ "$f" != "$_snap_ws/.git" ] || continue
      _snap_dotgit "$f" || { rc=1; break; }
      g="$(_snap_dotgit_target "$f")" || { rc=1; break; }
      [ -z "$g" ] || _snap_host_config "$g" "$f" "${f%/*}" || { rc=1; break; }
    done < "$list"
```
(excerpt ends :702; enclosing `git_exec_snapshot()` continues to :716 — read)

Executed (`$L/exp-s.txt`), global `core.hooksPath = .githooks`: host form → `rc=1`, with `+ hooksdir <ws>/.claude/worktrees/a/.githooks missing`; the same worktree rewritten to the container form with an absent container root → `rc=0` and the note. The precise version: "…walked in each new worktree whose `.git` resolves on the host; a container-form one that does not resolve is not walked (host git stops there, E10)". The plan's B14 already states this split; the header parenthetical does not.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:534-549`, `:686-703`, `$L/exp-s.txt`

---

## Claim 5: "W <kind> <config or path %q> a path git resolves in the working tree it runs in (read by scan_std_worktrees; never reported, and it changes only with a C or F record)"

**Location:** `devcontainer-config/cc-exit-scan.sh:151-153`
**Type:** Invariant / Architectural
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the single reader (`scan_std_worktrees`), `scan_diff` never rendering W, and each W source being derived from a C value, a C key, or an F-hashed legacy-remote file; does not establish the invariant under concurrent mutation between reads (the existing "file changed while the scan read it" exit-2 path).

`scan_diff` keeps only F and C:

```bash
# devcontainer-config/cc-exit-scan.sh:755-756
    FNR == NR { if ($1 == "F") b[$2 FS $3] = $4; else if ($1 == "C") bc[$0] = 1; next }
    { if ($1 == "F") a[$2 FS $3] = $4; else if ($1 == "C") ac[$0] = 1 }
```
(excerpt ends :756; enclosing `scan_diff()` continues to :769 — read)

W sources (paraphrased — no quote available because the invariant is inferred from four call sites): `_snap_wrel` at :393/:401 keys on the config file for a C key whose value is in the same C line; :417 keys on a `url.<base>` C key; `_snap_remote` :357 records the url value (from a C line or from a legacy-remote file hashed as an F record at :599); remote names resolved at :707-712 depend on `_snap_rnames`, fed by C keys (:410) and legacy-remote F records (:601). `grep -n 'W'` shows no other reader of W records than :813.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:357`, `:393`, `:401`, `:417`, `:599-611`, `:707-712`, `:752-769`, `:813`

---

## Claim 6: "_snap_wrel <kind> <where> <value>: a W record when <value> is a relative path, which git resolves in the working tree it runs in"

**Location:** `devcontainer-config/cc-exit-scan.sh:287-294`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers empty, absolute and `~/` values being exempt and everything else (including `~user/…`) recorded; does not establish which callers pass which values (Claim 3).

```bash
# devcontainer-config/cc-exit-scan.sh:290-294
_snap_wrel() {
  # shellcheck disable=SC2088  # matching a literal "~/" in the value
  case "$3" in ""|/*|"~/"*) return 0 ;; esac
  _snap+="W"$'\t'"$1"$'\t'"$(printf '%q' "$2")"$'\n'
}
```

Executed via `$L/exp-s.txt` (`~/h`, `/abs` → no W; `.h` → W).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:287-294`, `$L/exp-s.txt`

---

## Claim 7: "\".\" is the repository git runs in (a local-tracking branch's remote): in a linked worktree, the same common dir and hooks. Not a W record."

**Location:** `devcontainer-config/cc-exit-scan.sh:355-357`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a push to `.` from a linked worktree running the common `pre-receive`, and `.` producing no W from any `_snap_remote` caller (url, pushurl, pushDefault, branch remote, legacy file); does not cover insteadOf bases (handled separately at :417, Claim 8).

`[ "$p" = . ] || _snap_wrel remote "$p" "$p"` (`devcontainer-config/cc-exit-scan.sh:357`). `$L/exp-e2.txt` "B29": `git -C wt push . w:w3` → `ran-common-prerecv`. `$L/exp-s.txt`: `remote.o.url .` and `branch.main.remote .` → no W. Bats case `branch.main.remote .` expects status 0 (ok 8).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:346-369`, `$L/exp-e2.txt`, `$L/exp-s.txt`

---

## Claim 8: "a base \"\" or \".\" starts a relative path" (insteadOf W record)

**Location:** `devcontainer-config/cc-exit-scan.sh:417`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `url...insteadOf` and `url..insteadOf` / `url..pushInsteadOf` producing a W record, and git 2.39.5 rewriting through both to a relative local path whose hook runs; does not establish that the rewritten URL itself is walked (it is not — Claim 30).

```bash
# devcontainer-config/cc-exit-scan.sh:414-418
      url.*.insteadof|url.*.pushinsteadof)
        # url.<base>.insteadOf rewrites matching URLs to <base>.
        t="${key#url.}"; t="${t%.*}"
        case "$t" in ""|.) _snap_wrel "$key" "$f" ./ ;; esac   # a base "" or "." starts a relative path
        _snap_remote "$t" "$base" || return 1 ;;
```
(excerpt ends :418; enclosing `_snap_config()` continues to :421 — read)

`$L/exp-e2.txt`: `url...insteadOf https://x.invalid/` then push `https://x.invalid/evil` ran `wt/.evil`'s hook; `url..insteadOf https://y.invalid/` (git lists `url..insteadof=…`) ran `wt/evil2`'s hook. Mutations m3 (drop `""`) and m5 (drop the line) each fail the bats test (`$L/mut-m3.txt`, `$L/mut-m5.txt`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:414-418`, `$L/exp-e2.txt`, `$L/mut-m3.txt`, `$L/mut-m5.txt`

---

## Claim 9: "Where the container sees the checkout (devcontainer.json's workspaceMount target). Git in the container writes absolute paths under it into a new worktree's `.git` file and back-pointer."

**Location:** `devcontainer-config/cc-exit-scan.sh:771-774`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the constant matching `devcontainer.json`'s workspaceMount and git 2.39.5 writing absolute paths into both files; does not establish the git version inside the built image (Dockerfile `FROM node:22` + apt `git`, not built here).

`GIT_EXIT_SCAN_CONTAINER_WS=/workspace` (:774); `devcontainer-config/devcontainer.json:134`: `"workspaceMount": "source=${localWorkspaceFolder},target=/workspace,type=bind,consistency=delegated"`. E1 in `$L/exp-e.txt`: `.git` = `gitdir: /tmp/…/r/.git/worktrees/wt\n`-shaped absolute path, back-pointer `/tmp/…/r/wt/.git\n`.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:771-774`, `devcontainer-config/devcontainer.json:134`, `$L/exp-e.txt`

---

## Claim 10: "_snap_hash_str <string>: _snap_hash of exactly those bytes." / "_snap_file_is <path> <hash>: <path> is a regular file, not a link, within the size cap, whose bytes hash to <hash>."

**Location:** `devcontainer-config/cc-exit-scan.sh:776-791`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers byte-identical hashing (both take the first 16 hex of `sha256sum` of the raw bytes) and the four `_snap_file_is` conditions; does not establish TOCTOU safety between the checks.

```bash
# devcontainer-config/cc-exit-scan.sh:777-791
_snap_hash_str() {
  local h
  h="$(printf '%s' "$1" | sha256sum)"
  printf '%s' "${h:0:16}"
}
...
_snap_file_is() {
  local h
  [ -f "$1" ] && [ ! -L "$1" ] || return 1
  _snap_size_ok "$1" 2>/dev/null || return 1
  h="$(_snap_hash "$1" 2>/dev/null)" || return 1
  [ "$h" = "$2" ]
}
```
`_snap_hash` (:167-174) is `sha256sum < "$1"` then `${h:0:16}`. Accept-path tests rely on the equality (ok 1, 2).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:166-174`, `:776-791`

---

## Claim 11: scan_std_worktrees doc comment — the list of checks ("P = <common>/worktrees/<n>, <n> of [A-Za-z0-9._-]. Only dotgit, commondir-file and hooksdir records are added (a removal warns), and the exit snapshot has no W record: new `hooksdir P/hooks missing` and `commondir-file P/commondir` of exactly "../..\n"; on disk P and worktrees/ are real dirs, P has no hooks, config, config.worktree or symlink, P/gitdir is exactly "<ws or container ws>/<rel>/.git\n", and a new `dotgit <ws>/<rel>/.git` is a regular file of exactly "gitdir: P\n" or its container form (which, if it exists here, must be P), at snapshot time and now.")

**Location:** `devcontainer-config/cc-exit-scan.sh:793-805`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every stated check being implemented (each quoted below); does not claim the list is complete — the code also enforces checks the comment does not name (listed below), all of which only decline more, so no accepting path is undocumented.

Every stated check is present (quoted from `scan_std_worktrees()` :806-896, read in full):
- no W: `:813`; P naming and charset: `case "$q" in "$pre"*/commondir)` (:843), `[[ "$n" =~ ^[A-Za-z0-9._-]+$ ]]` (:845); only +dotgit/+commondir-file/+hooksdir, anything else incl. `-` lines returns 1 (:830-834); `hooksdir P/hooks missing` (:850-851); commondir hash `re="^file [0-7]+ $std\$"` (:848-849); `[ -d "$common/worktrees" ] && [ ! -L "$common/worktrees" ] && [ -d "$p" ] && [ ! -L "$p" ]` (:854); no hooks/config/config.worktree (:856); no symlink `find -P "$p" -type l -print -quit` (:857); gitdir exact (:862-868); dotgit hash at snapshot (`[[ "$attrs" =~ $re ]]`) and now (`_snap_file_is "$wt/.git" "$h"`) (:878-882); container form resolving to P (:885-887).

Checks the code does that the comment does not state:
- `<n>` must not be `.` or `..` (`[ "$n" != . ] && [ "$n" != .. ]`, :845);
- the exit snapshot's `commondir` record must equal the recomputed common dir (:818-819);
- the back-pointer must be ≤ 4097 bytes (:861);
- `<rel>` must have no `.`, `..` or empty components (`case "/$wtrel/" in */../*|*/./*|*//*) return 1`, :870) and the working tree must not be inside the common dir (:872);
- the container-form back-pointer (and container-form `.git`) is accepted only when the common dir lies inside the checkout (`[ -n "$ccommon" ] || return 1`, :866; `${ccommon:+…}`, :878);
- `P/commondir` is re-hashed on disk now (:855) — "at snapshot time and now" is attached in the sentence to the dotgit only.
Precise version: append these to the rule, or say "at least these checks". Executed support: all 9 Q-094 tests pass (`$L/bats-q094.txt`), including `..` routes, other working trees and FIFO cases.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:793-896`, `$L/bats-q094.txt`

---

## Claim 12: "Anything it cannot read or match declines; nothing passes on error." / "Paths are compared as the %q strings the records hold, recomputed from <n>; nothing is unquoted."

**Location:** `devcontainer-config/cc-exit-scan.sh:795-796`, `:804-805`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every command in the function ending in `|| return 1` or feeding a guarded test, `git_exit_scan` discarding stderr and falling through to the warning on any non-zero, and all record comparisons using `printf '%q'` recomputation; does not establish behaviour if bash itself is killed (handled by the launcher's INT trap).

Examples: `dirs="$(scan_git_dirs "$ws" 2>/dev/null)" || return 1` (:814); `line="$(_snap_first_line "$p/gitdir" 2>/dev/null)" || return 1` (:862); `[ "$q" = "$(printf '%q' "$p/commondir")" ] || return 1` (:847); `hk="+F"$'\t'"hooksdir"$'\t'"$(printf '%q' "$p/hooks")"…` (:850); `dk="${dot["+F"$'\t'"dotgit"$'\t'"$(printf '%q' "$wt/.git")"]:-}"` (:874). The only extraction from a quoted string (`n="${q#"$pre"}"`, :844) is re-verified by recomputation at :847. Caller: `note="$(scan_std_worktrees … 2>/dev/null)"` inside `if` (:935), so errexit is off and any non-zero falls through to `scan_diff`.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:806-896`, `:935`

---

## Claim 13: "Pattern matches, not `printf | grep -q`: under the launcher's pipefail an early match SIGPIPEs printf, and the pipeline reads as \"no match\"."

**Location:** `devcontainer-config/cc-exit-scan.sh:811-813`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the SIGPIPE mechanism under `set -o pipefail` for both checks in `scan_std_worktrees` (reverting either one makes the 40k-record test fail); does not establish the exact snapshot size at which SIGPIPE starts (pipe-buffer dependent).

The launcher sets `set -euo pipefail` (`devcontainer-config/cc-isolated.sh:66`). Mutation m2 (both checks back to `printf '%s\n' "$after" | LC_ALL=C grep -q…`) fails the test at `[ "$status" -eq 0 ]` (commondir check reads "no match", `$L/mut-m2.txt`); m6 (only the W check reverted) fails at `[ "$status" -eq 1 ]` (W refusal fails open, `$L/mut-m6.txt`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:811-819`, `devcontainer-config/cc-isolated.sh:66`, `test/cc-isolated-functions.bats:2273-2286`, `$L/mut-m2.txt`, `$L/mut-m6.txt`

---

## Claim 14: "Regular file first: a FIFO there would block the read." / "# PATH_MAX + \n"

**Location:** `devcontainer-config/cc-exit-scan.sh:859-861`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a FIFO at `P/gitdir` declining within the test's 20 s timeout and the 4097 = Linux PATH_MAX (4096) + newline cap; does not establish behaviour for a FIFO swapped in after the `-f` test (race).

```bash
# devcontainer-config/cc-exit-scan.sh:860-862
    [ -f "$p/gitdir" ] && [ ! -L "$p/gitdir" ] || return 1
    [ "$(stat -c %s -- "$p/gitdir" 2>/dev/null || echo 99999)" -le 4097 ] || return 1   # PATH_MAX + \n
    line="$(_snap_first_line "$p/gitdir" 2>/dev/null)" || return 1
```
(excerpt ends :862; enclosing `scan_std_worktrees()` continues to :896 — read)

Mutation m4 (line :860 → `true`) makes the FIFO step of test 6 fail `warns_listing_wt` (`$L/mut-m4.txt`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:860-862`, `test/cc-isolated-functions.bats:2336-2339`, `$L/mut-m4.txt`

---

## Claim 15: note text — "Names are [A-Za-z0-9._-] only (checked above); the caller still scan_vis-es." and "They take config and hooks from the checkout's own .git, so this is not a finding."

**Location:** `devcontainer-config/cc-exit-scan.sh:893-895`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the name restriction at :845, `printf '%s\n' "$note" | scan_vis >&2` at :936, and git 2.39.5 taking config and hooks from the common dir (Claim 2); does not extend to `config.worktree` (which declines the note before this line).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:845`, `:893-895`, `:936`, `$L/exp-e.txt`

---

## Claim 16: git_exit_scan doc — "0 when nothing the tripwire records changed, or only standard linked worktrees did (one `note:` line on stderr: scan_std_worktrees); 1 … when anything else did; 2 when the exit state could not be read, or the snapshots differ but nothing renders."

**Location:** `devcontainer-config/cc-exit-scan.sh:898-903`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four return paths at :920, :931/:937, :945, :969; does not establish claude-side behaviour. (Residue: the plan's "git 2.39 (the image's git)" is not checked — the image was not built.)

`return 2` after a failed snapshot (:920) and on empty `changes` (:943-946); `return 0` at :931 and :937; `return 1` at :969. Full-suite run: `$L/bats-full.txt`.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:904-970`, `$L/bats-q094.txt`, `$L/bats-full.txt`

---

## Claim 17: "A pattern match, not `printf | grep -q` (pipefail: see scan_std_worktrees)." — replacement of the pre-existing `invalid` check

**Location:** `devcontainer-config/cc-exit-scan.sh:926-930`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the new regex matching the same records as the old per-line grep (`^F\tgitdir-valid\t[^\t]*\tinvalid` per line ≡ `(^|\n)F\tgitdir-valid\t[^\t\n]*\tinvalid` over the whole string) and the existing invalid-git-dir tests still passing; does not establish a pipefail/large-snapshot test for this check (none exists, as B28 says).

```bash
# devcontainer-config/cc-exit-scan.sh:927-930
  local re=$'(^|\n)F\tgitdir-valid\t[^\t\n]*\tinvalid'
  if [[ "$after" =~ $re ]]; then
    invalid="    ! $(printf '%q' "$ws/.git") is not a valid git directory now: host git would look for a repository elsewhere (the checkout root)"
  fi
```
Existing tests asserting `! $SCAN_WS/.git is not a valid git directory now` (`test/cc-isolated-functions.bats:1352`, `:1362`) — see `$L/bats-full.txt`.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:923-931`, `test/cc-isolated-functions.bats:1340-1365`, `$L/bats-full.txt`

---

## Claim 18: "0 success; after a session: the exit scan found nothing (or only standard linked worktrees, with a note on stderr), and claude's own exit status is passed through"

**Location:** `devcontainer-config/cc-isolated.sh:20-23`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `--help` text (printed from this header by `usage()`), the `0) exit "$rc"` mapping, and the launcher test; does not establish a live container run (the plan's `Live-verified: no`).

`case "$scan" in 0) exit "$rc" ;; 1) exit 3 ;; *) exit 4 ;; esac` (`devcontainer-config/cc-isolated.sh:747-751`). `bash devcontainer-config/cc-isolated.sh --help` printed the new lines (cwd `$D/src`, exit 0, 2026-09-29T03:22Z; captured in `$L/help.txt`, lines 20-23). Bats "a session that leaves an agent worktree ends the launcher with claude's status and a note" passed (ok 9).

**Evidence:** `devcontainer-config/cc-isolated.sh:18-33`, `:566-568`, `:743-751`, `test/cc-isolated-functions.bats:2386-2394`, `$L/bats-q094.txt`, `$L/help.txt`

---

## Claim 19: Plan Problem — "`git worktree add <ws>/.claude/worktrees/agent-x -b wt-x` during a session adds exactly three records to the exit snapshot"

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:9-15`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the record diff with no global config; does not cover a host config with a relative hooksPath (adds a fourth, Claim 4).

`$L/exp-n.txt`: diff adds exactly `F commondir-file <ws>/.git/worktrees/agent-x/commondir file 644 …`, `F dotgit <ws>/.claude/worktrees/agent-x/.git file 644 …`, `F hooksdir <ws>/.git/worktrees/agent-x/hooks missing`.

**Evidence:** `$L/exp-n.txt`

---

## Claim 20: Plan Context — "The scan already records the private dir (`.git/worktrees/<n>`) by its fixed layout: config, config.worktree, info/attributes, hooks/ + entries, commondir, legacy remotes/branches, rebase-merge/, rebase-apply/, sequencer/, every symlink, and nested modules/** / worktrees/*."

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:22`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers `_snap_gitdir` reaching P through `_snap_nested "$real/worktrees"` (P qualifies via its `commondir` file, `looks_like_gitdir`) and the list in `_snap_gitdir`; does not establish that a P lacking `commondir` is walked (it is not, and it is then not accepted either).

`_snap_nested "$real/worktrees"` (:638) → `_snap_find … -mindepth 2 -name HEAD` → `looks_like_gitdir "$g"` → `_snap_gitdir` (:562-565), which records `config config.worktree` (:578-581), `info/attributes` (:582), hooks (:583), commondir (:584), remotes/branches (:594-614), rebase/sequencer (:616-623), symlinks (:626-636), nested (:637-638).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:555-639`, `devcontainer-config/cc-gitdir.sh:89`

---

## Claim 21: Plan Context — "The launcher maps git_exit_scan 0 → claude's own status, 1 → exit 3, 2 → exit 4. The acceptance lives inside git_exit_scan and returns 0, so cc-isolated.sh does not change."

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:23`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the exit mapping and that no executable line of `cc-isolated.sh` changed; the "does not change" part is imprecise — the unit edits `cc-isolated.sh`'s header, which is its `--help` text.

`devcontainer-config/cc-isolated.sh:747-751` as quoted in Claim 18. `git diff dfe4c0d 9075003 --numstat -- devcontainer-config/cc-isolated.sh` → `2 1` (the EXIT STATUS lines 20-21). Precise version: "…so cc-isolated.sh's code does not change (only its exit-status help text)."

**Evidence:** `devcontainer-config/cc-isolated.sh:20-21`, `:747-751`

---

## Claim 22: Plan experiments table E1–E12

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:31-42`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers re-runs of E1, E2, E3 (pre-commit, post-commit, post-checkout; not pre-push / reference-transaction), E4, E5, E6, E7, E8, E9, E10 (only the ".git naming a missing path" shape), E11, E12 on git 2.39.5; does not re-run E3's pre-push/reference-transaction hooks or E10's "private dir removed / HEAD removed" shapes.

`$L/exp-e.txt`: E1 bytes (`../..\n` 6 bytes; private dir `HEAD ORIG_HEAD commondir gitdir index logs`); E2 paths exactly as tabled; E3 only `ran-common-post-commit`; E4 `no filter ran` then control `ran-filter`; E5 `none`; E6 `ignored` then `ran-hk`; E7 `ran-rel`; E10 `fatal: not a git repository: /nonexist/.git/worktrees/wt`; E11 both variants resolve to the same common dir. `$L/exp-e2.txt`: E8 `ran-filter`; E9 `ran-prerecv`; E12 `git worktree remove` removed the last one and `.git/worktrees` no longer exists.

**Evidence:** `$L/exp-e.txt`, `$L/exp-e2.txt`

---

## Claim 23: Plan acceptance rules 1–5 and 7, and rule 6 ("In this unit any removed record warns")

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:48-61`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each rule against `git_exit_scan`/`scan_std_worktrees` (rule 1 `[ -z "$invalid" ]` :935; rule 2 :828-835; rule 3 :813; rule 4 :818-819, :843-845; rule 5 :846-887; rule 6 removed lines hit `*) return 1` :833; rule 7 :892) and test 3 for removal; rule 5's third bullet omits that the container-form back-pointer needs the common dir inside the checkout (:866) — a stricter unstated check, same as Claim 11.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:806-896`, `:935`, `test/cc-isolated-functions.bats:2263-2271`, `$L/bats-q094.txt`

---

## Claim 24: Plan — "A decline never errors … The scan still runs no git command in the checkout, and the note names only <n> values restricted by rule 4, through scan_vis."

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:63`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers `scan_std_worktrees` and `_snap_hash_str`/`_snap_file_is` containing no `git` invocation and the `scan_vis` pipe; does not re-audit the pre-existing snapshot's git use (`git config --file … ` from `/`).

(paraphrased — no quote available because the claim covers absence of code: reading :776-896 shows no `git` command; tools used are `awk`, `sha256sum`, `stat`, `find -P`, `sort`, `tr`, `cd`.) Note restriction and `scan_vis`: Claim 15.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:776-896`, `:936`

---

## Claim 25: Plan — "`_snap_config` and `_snap_remote` add `W <kind> <config or path %q>` whenever they resolve a path against a working tree. `scan_diff` ignores record types other than F and C, and a `W` record only changes when a C or F record does, so the report output is unchanged."

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:65`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every `_snap_config`/`_snap_remote` path that resolves a relative value against `base` (hooksPath :394, attributesFile :402, remote :358) emitting W, plus two W emissions that resolve nothing (`""` insteadOf base, which `_snap_remote` returns early on); does not cover `_snap_host_config`, which resolves your own config's relative paths against a working tree without W (by design, records instead — Claim 4).

Evidence as in Claims 3, 5, 8; `scan_diff` quote in Claim 5. `$L/exp-s.txt` lists the W for each form.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:346-421`, `:496-532`, `:752-769`, `$L/exp-s.txt`

---

## Claim 26: Plan B-table rows B1–B12, B16–B20, B26 "covered"/"not accepted" with their stated mechanism

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:73-98`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the rows whose mechanism the tests exercise — B1/B2/B3/B7(info symlink)/B9 (test 5), B8/B10/B17/B26 (test 6), B16/B18/B19 (test 7), B12 (test 8), B20 (test 1), B11 by reading — and E3–E6 for "never run"; does not execute B5 (rebase dirs in P), B6 (modules in P) or B7's symlinked `P`/`worktrees/` shapes, which are verified only by reading `_snap_gitdir`'s recording plus the "every record consumed" rule (:892).

**Evidence:** `test/cc-isolated-functions.bats:2227-2384`, `devcontainer-config/cc-exit-scan.sh:573-639`, `:854-857`, `:892`, `$L/bats-q094.txt`

---

## Claim 27: B13 — "Relative local remotes … incl. insteadOf bases, pushDefault/branch.*.remote naming a path, legacy remotes/*/branches/* — covered — Rule 3 (W from _snap_remote, which all of these go through)"

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:85`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers "covered" (W is produced for every listed form, `$L/exp-s.txt`); the mechanism "W from _snap_remote" is imprecise for insteadOf bases `.` and `""`, whose W comes from `_snap_config` :417 (`_snap_remote` exempts `.` at :357 and returns early on `""` at :349).

Precise version: "(W from `_snap_remote`, which all of these go through; for an insteadOf base of `.` or `""`, from `_snap_config` — see B30)."

**Evidence:** `devcontainer-config/cc-exit-scan.sh:349`, `:357`, `:417`, `$L/exp-s.txt`

---

## Claim 28: B14 — "When the worktree's .git resolves on the host, _snap_host_config already walks it for that git dir and any path inside the checkout becomes a new record (residue). When it does not resolve (container form, host not at /workspace), host git in it stops (E10)"

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:86`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both branches (host form: `rc=1` with `+ hooksdir …/.githooks`; container form: note; E10 fatal); does not cover `includeIf gitdir:` matching executed (read only: `_snap_cond` at :466-487 is called from the same walk).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:697-702`, `$L/exp-s.txt`, `$L/exp-e.txt`

---

## Claim 29: B21 — "Removal hiding a plant … covered — Rule 6 requires P gone on disk. E10: a private dir without HEAD is refused by git anyway"

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:93`
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the cited mechanism ("Rule 6 requires P gone on disk"), which is not in this unit's code; the "covered" status still holds in unit A, for a different reason (any removed record returns 1 at :833).

Rule 6 itself says removal acceptance moved to `q094b-exit-scan-worktree-removal` (plan :60); B23 and B27 were updated to "Here, any removal warns", B21 was not. In A: `*) return 1 ;;` (`devcontainer-config/cc-exit-scan.sh:833`) catches every `-` line.

**Evidence:** `docs/working/plan-q094-exit-scan-worktree-layout.md:60`, `:93`, `:95`, `:99`, `devcontainer-config/cc-exit-scan.sh:828-835`

---

## Claim 30: B25 — "Newer git writing relative paths (worktree.useRelativePaths, git ≥ 2.48) — not accepted (warns)"

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:97`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers "not accepted": a relative `.git` or back-pointer fails the byte-exact checks (test 6 executes `gitdir: ../../../.git/worktrees/agent-x` → warns); does not verify the external fact that git 2.48 introduced `worktree.useRelativePaths` (no network; git 2.39.5 here).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:864-868`, `:878-883`, `test/cc-isolated-functions.bats:2322-2327`

---

## Claim 31: B28 — "Pattern matches in bash ([[ ]]), no pipeline. The same fix was applied to the pre-existing invalid check in git_exit_scan. The test (40k padding records) covers the two checks in scan_std_worktrees; the invalid check has no test of its own"

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:100`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each of the two checks separately (m6 reverts only the W check → fails; m2 reverts both → fails at the commondir check) and the absence of any pipefail test for `invalid` (`grep -n pipefail test/cc-isolated-functions.bats` → only :363, :872-876, :2273-2281, none on gitdir-valid); does not establish the test is sensitive to a revert of *only* the commondir check (not run separately; m2's first failing assertion is the one that check governs).

**Evidence:** `test/cc-isolated-functions.bats:2273-2286`, `$L/mut-m2.txt`, `$L/mut-m6.txt`

---

## Claim 32: B29/B30 — "`.` is the repository git runs in … a push to `.` from the worktree ran the common pre-receive" / "An insteadOf base of `.` or of `""` … always makes a W record … Test cases for both, and for pushInsteadOf, were added; a mutation that drops `""` fails them. The broader, older gap … is now listed in the guide's Known routes"

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:101-102`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the B29 push experiment, the three bats cases (`url...insteadOf`, `url..insteadOf`, `url..pushInsteadOf`), mutation m3, and the guide entry (Claim 36); does not execute `pushInsteadOf` with base `.`.

**Evidence:** `test/cc-isolated-functions.bats:2366-2381`, `$L/exp-e2.txt`, `$L/mut-m3.txt`, `guides/cc-isolated-usage.md:385-387`

---

## Claim 33: Guide exit-status text — "A linked worktree added in git's own layout (an agent worktree left behind) is not a finding: one `note:` line, and the exit status is claude's." / "3 the exit scan found a change (a note about standard worktrees is not one)"

**Location:** `guides/cc-isolated-usage.md:66-68`, `:76-77`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the launcher test (status 0 from a stub claude, note present, no WARNING); does not establish a live container session.

**Evidence:** `test/cc-isolated-functions.bats:2386-2394`, `devcontainer-config/cc-isolated.sh:747-751`, `$L/bats-q094.txt`

---

## Claim 34: Guide "Linked worktrees left behind (Q-094)" paragraph

**Location:** `guides/cc-isolated-usage.md:334-351`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the note text prefix, "returns claude's status", the common-dir resolution (git 2.39.5), `config.worktree` refusal, the "Exact" summary (name charset, `../..\n`, no hooks/config/config.worktree/symlink, working tree inside the checkout, `.git` exact by host or container path which must be the same directory if it exists), and the listed warning cases; the "Exact" summary, like Claim 11, is a subset of the code's checks (it says so: "`scan_std_worktrees` has the full rule"), and "any checkout whose config holds…" understates the refusal, which fires for a W from any config the scan reads (Claim 3).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:806-896`, `test/cc-isolated-functions.bats:2227-2394`, `$L/bats-q094.txt`, `$L/exp-e.txt`

---

## Claim 35: Guide Known route — "The same holds in a linked worktree the session leaves behind: its tracked files are never read, only its layout (see above)."

**Location:** `guides/cc-isolated-usage.md:365-366`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the acceptance reading only `P/*`, `<wt>/.git` and records; does not cover the snapshot's embedded-`.git` search and your own config's relative hooksPath walk, which do descend into the new worktree's tree (those only add refusals).

(paraphrased — no quote available because the claim covers absence of code: `scan_std_worktrees` :806-896 reads `P/commondir`, `P/gitdir`, `$wt/.git` and `find -P "$p" -type l` only.)

**Evidence:** `devcontainer-config/cc-exit-scan.sh:806-896`, `:693-702`

---

## Claim 36: Guide Known route — "A URL rewritten by `url.<base>.insteadOf`. The base is walked, never the rewritten URL, so a remote rewritten to a local path the session plants runs that repository's hooks on push."

**Location:** `guides/cc-isolated-usage.md:385-387`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `_snap_remote "$t"` walking only the subsection `<base>` and the B30 experiment showing a rewritten relative URL's hook runs; does not establish the absolute-base case executed (read only).

`_snap_remote "$t" "$base"` (`devcontainer-config/cc-exit-scan.sh:418`), where `t` is the `url.<t>.insteadof` subsection (:416). `$L/exp-e2.txt` B30 rows.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:414-418`, `$L/exp-e2.txt`

---

## Claim 37: Test names vs assertions (9 Q-094 tests), the comment "git keeps '+' in a worktree name (a space it turns into '-')", and the devcontainer.json check

**Location:** `test/cc-isolated-functions.bats:2206-2394`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each test's name matching its assertions (read in full), all 9 passing, mutations m2/m3/m4/m5/m6 each failing the matching test, the name-sanitising comment (`$L/exp-n.txt`: `wts/a+b` → `a+b`, `wts/c d` → `c-d`), and `grep -q "target=$GIT_EXIT_SCAN_CONTAINER_WS,"` matching `devcontainer.json:134` only; does not establish mutation sensitivity of tests 1, 2, 7, 9 (not mutated).

**Evidence:** `test/cc-isolated-functions.bats:2206-2394`, `devcontainer-config/devcontainer.json:134`, `$L/bats-q094.txt`, `$L/exp-n.txt`, `$L/mut-m2.txt`…`$L/mut-m6.txt`

---

## Claim 38a: Commit b4de821 — "when every record-level difference is a worktree of the checkout's own common dir added or removed in the exact layout git writes … Removed worktrees need P gone on disk."

**Location:** commit `b4de821` message
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers removal acceptance, which b4de821's code had (`local -a added=() removed=()`, "Removed worktrees' `.git` files, paired by count" in `git show b4de821:devcontainer-config/cc-exit-scan.sh`) and c32a734 removed from this unit; the rest of the message (checks, W records, "scan_diff ignores W records, so warning output is unchanged") is Verified at the tip (Claims 3, 5, 11).

At 9075003 any removed record warns (`devcontainer-config/cc-exit-scan.sh:833`; test 3). Commit messages are immutable; the plan (rule 6) and c32a734 record the move.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:828-835`, `test/cc-isolated-functions.bats:2263-2271`

---

## Claim 38b: Commits 5a6d689 and c32a734 — "A FIFO planted at .git/worktrees/<n>/gitdir blocked the exit scan's read … The rest of the scan checks -f before every read; this one now does too. Test: a FIFO there warns within a timeout." / "a -f guard in _snap_worktree_of (a FIFO config hung the snapshot; makes 5a6d689's '-f before every read' true)"

**Location:** commits `5a6d689`, `c32a734`; code `devcontainer-config/cc-exit-scan.sh:328`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the tip state: every content read of a container-writable file is preceded by `-f` (`scan_git_dirs` :123/:134, `_snap_file` :230/:243, `_snap_config` callers :399/:527/:529/:580, legacy remotes :602, `_snap_dotgit_target` :540, `_snap_gitdir` :585, `_snap_worktree_of` :328, `scan_std_worktrees` :855/:860/:881, `cc-gitdir.sh` :33/:57); does not make 5a6d689's sentence true *at 5a6d689* — mutation m1 (removing the :328 guard) hangs the snapshot on a FIFO `P/config` next to a legacy remote (`timeout 20` → rc 124), as c32a734 concedes.

```bash
# devcontainer-config/cc-exit-scan.sh:323-335
_snap_worktree_of() {
  local gd v
  gd="$(cd "$(dirname -- "$1")" 2>/dev/null && pwd -P)" || gd="$(dirname -- "$1")"
  if [ "$gd" = "$_snap_gd" ] || [ "$gd" = "$_snap_common" ]; then
    printf '%s' "$_snap_ws"
  elif [ -f "$1" ] && v="$(cd / && git --no-pager config --file "$1" --no-includes --get core.worktree 2>/dev/null)"; then
    _snap_path "$v" "$gd"
  elif [ "${gd##*/}" = .git ]; then
    printf '%s' "${gd%/*}"
  else
    printf '%s' "$gd"
  fi
}
```
Tip run of the same FIFO setup: `rc=0` (`$L/exp-s.txt`); m1: `rc=124` (`$L/mut-m1.txt`); FIFO test: m4 fails it (`$L/mut-m4.txt`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:323-335`, `$L/exp-s.txt`, `$L/mut-m1.txt`, `$L/mut-m4.txt`

---

## Claim 38c: Commits c32a734, 5fadfc2, 037621f, 9075003 — remaining factual statements ("All three checks … are now bash pattern matches. Test: 40k padding records, both directions, under pipefail"; "indexed dotgit lookup"; "a 4097-byte cap"; "a bats check that GIT_EXIT_SCAN_CONTAINER_WS matches devcontainer.json"; "No code behaviour change; the only line in cc-exit-scan.sh that changes is comments"; "a mutation that drops the line fails it"; "unit at 399 changed code lines outside docs/ against dfe4c0d"; "git accepts `[url \"\"] insteadOf` … _snap_remote returns early on \"\" … a mutation that drops \"\" fails them")

**Location:** commits `c32a734`, `5fadfc2`, `037621f`, `9075003`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed statement (pattern matches :813/:819/:928; `dot[…]` associative lookup :831/:874; :861; bats :2383; `git show 5fadfc2 -- devcontainer-config/cc-exit-scan.sh` changes two comment lines only (":the only line" is two lines, both comments); `git diff --numstat dfe4c0d 037621f -- . ':!docs'` sums 171+4+2+1+29+3+189 = 399; m5 and m3 fail test 8; `$L/exp-e2.txt` url..insteadof); does not verify review-process statements ("Performance iteration 2: no findings", "has not been re-reviewed by a critic").

**Evidence:** `devcontainer-config/cc-exit-scan.sh:813`, `:819`, `:831`, `:861`, `:874`, `:928`, `test/cc-isolated-functions.bats:2383`, `$L/mut-m3.txt`, `$L/mut-m5.txt`, `$L/exp-e2.txt`

---

## Claims Requiring Attention

### Incorrect
- (none)

### Stale
- **Claim 29** (`docs/working/plan-q094-exit-scan-worktree-layout.md:93`): B21 cites "Rule 6 requires P gone on disk", a check that now lives in unit B; in A it is covered because any removed record warns — say so, as B23/B27 do.
- **Claim 38a** (commit `b4de821`): "added or removed … Removed worktrees need P gone on disk" — removal acceptance was moved to unit B by c32a734; immutable history, no action beyond awareness.

### Mostly Accurate
- **Claim 4** (`devcontainer-config/cc-exit-scan.sh:83-84`): the host-config parenthetical holds only when the new worktree's `.git` resolves on the host; a container-form worktree is not walked and gets the note (benign per E10; B14 says this, the header does not).
- **Claim 11** (`devcontainer-config/cc-exit-scan.sh:793-805`): the doc lists every check it states correctly but omits five stricter ones the code enforces (`.`/`..` names, commondir-record match, 4097-byte back-pointer cap, no `.`/`..`/empty rel components and wt-not-in-common, container form only when common is inside the checkout).
- **Claim 21** (`docs/working/plan-q094-exit-scan-worktree-layout.md:23`): "cc-isolated.sh does not change" — its code does not, its header/`--help` exit-status text does.
- **Claim 27** (`docs/working/plan-q094-exit-scan-worktree-layout.md:85`): B13 attributes all remote W records to `_snap_remote`; for insteadOf bases `.` and `""` the W comes from `_snap_config:417`.

### Unverifiable
- (none as standalone claims; residues: the image's git version (Claim 16 scope), git 2.48's `worktree.useRelativePaths` (Claim 30 scope))

---

## Goal-Alignment Note

Unit A's goal — a session that leaves an agent worktree in git's exact layout ends with one `note:` and claude's status, while every other shape (and any W record) still warns — is met by the code as executed: 9/9 Q-094 tests pass, six mutations each break the matching test, and the plan's experiments reproduce on git 2.39.5. No claim found is Incorrect; the four Mostly-accurate and two Stale items are documentation precision, and none of them names an accept path the code lacks (every undocumented check is a stricter decline). The one behavioural nuance a reader could miss from the header alone (Claim 4) is benign by E10 and already recorded in the plan's B14. Full-suite result for the whole `test/cc-isolated-functions.bats`: see the final lines of `$L/bats-full.txt` — 169/169 ok, exit 0, finished 2026-09-29T03:22Z.
