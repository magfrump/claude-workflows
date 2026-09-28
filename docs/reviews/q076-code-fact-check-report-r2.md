Commit: 61d801c

# Code Fact-Check Report

**Repository:** /workspace (scratch clone at 61d801c)
**Scope:** `git diff main...feat/q076-git-exit-scan` — devcontainer-config/cc-isolated.sh, devcontainer-config/cc-push.sh, devcontainer-config/install.sh, hooks/live-verify-gate.sh, guides/cc-isolated-usage.md, test/cc-isolated-functions.bats, test/cc-push.bats, test/install-host.bats; commit messages main..feat/q076-git-exit-scan
**Checked:** 2026-09-27
**Total claims checked:** 16
**Summary:** 11 verified, 3 mostly accurate, 0 stale, 0 incorrect, 2 unverifiable

Method note: static reading of each enclosing function in full, plus benign execution of the project's own suites, shellcheck and `cc-push --help`. I did not build adversarial repositories to try to defeat cc-push's refusals or the exit scan (see Goal-Alignment Note). So every Verified verdict below covers the tested or read property only, and the bypass-resistance residue is stated in each Scope field.

Execution provenance (cwd = scratch clone `…/scratchpad/q076rev-r2/clone`):
- `LC_ALL=C.UTF-8 bats test/cc-push.bats test/cc-isolated-functions.bats test/install-host.bats test/hooks/live-verify-gate.bats test/fixture-hermeticity.bats test/hermeticity-lint.bats`: started 2026-09-28T01:40:06Z, exit 0, output `…/scratchpad/q076rev-r2/suite340.log` (`1..340`, 340 `ok`, 0 `not ok`).
- `LC_ALL=C.UTF-8 bats test/guide-index-sync.bats test/cross-reference-integrity.bats test/function-inventory.bats`: exit 0, output `…/suite12.log` (`1..12`, 12 `ok`).
- `shellcheck -x -e SC1091 -s bash -S warning` on the 7 changed .sh/.bats files: 2026-09-28T01:42:53Z, exit 0, output `…/shellcheck.log`.
- `./devcontainer-config/cc-push.sh --help`: exit 0, output `…/cc-push-help.log`.

---

## Claim 1: "Exit codes: 0 pushed (or nothing to push); 1 error … (git's own exit status is never passed through); 2 declined at the prompt."

**Location:** `devcontainer-config/cc-push.sh:20-22` (also `guides/cc-isolated-usage.md:199-201`)
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the status mapping of the main guard, `die`, the decline branch and the E5/unrelated-history test cases; does not establish the exit status when cc-push is sourced rather than executed, or when it is killed by a signal.

```bash
# devcontainer-config/cc-push.sh:299-306
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  set +e
  ( set -e; main "$@" )
  rc=$?
  case "$rc" in
    0|1|2) exit "$rc" ;;
    *) echo "ERROR: cc-push stopped on an unexpected failure (status $rc)." >&2; exit 1 ;;
  esac
fi
```
`die` ends with `exit 1` (`cc-push.sh:91-94`). The decline path is `*) echo "Not pushed."; exit 2 ;;` (`cc-push.sh:284`). Nothing to push is `exit 0` (`cc-push.sh:264`). The tests "E5: a git fatal … exits 1, never git's 128" and "unrelated history: … exits 1, not 128" pass in suite340.log.

**Evidence:** `devcontainer-config/cc-push.sh:91-94`, `devcontainer-config/cc-push.sh:264`, `devcontainer-config/cc-push.sh:284`, `devcontainer-config/cc-push.sh:299-306`, `test/cc-push.bats:359`, `test/cc-push.bats:369`, suite340.log

---

## Claim 2: "cc-push runs no git command in the checkout"

**Location:** `devcontainer-config/cc-push.sh:30`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that no git invocation takes the checkout as `-C`/cwd: every call is `hgit <clone>` or `ngit check-ref-format`, and the checkout appears only as a fetch/ls-remote URL argument. Does not establish what upload-pack, started by that fetch, reads or does inside the checkout (Claims 3–4).

```bash
# devcontainer-config/cc-push.sh:97-105
ngit() {
  git -c core.hooksPath=/dev/null -c core.fsmonitor=false "$@"
}
hgit() {
  local c="$1"; shift
  ngit -C "$c" "$@"
}
```
The only uses of `$co` as a git argument are the fetch URL (`cc-push.sh:233-234`, `… --prune "$co" '+refs/heads/*:refs/cc/heads/*'`) and `ls-remote --symref "$co" HEAD` (`cc-push.sh:241`). Both run with `-C "$clone"`. `find_checkout` and `check_checkout` use only file tests, `find` and `grep` (`cc-push.sh:109-159`). Note that `ls-remote` is a second upload-pack contact. The guide's "its one contact with it is the fetch in step 1" (`guides/cc-isolated-usage.md`) is therefore off by one call, though that call is the same kind of read.

**Evidence:** `devcontainer-config/cc-push.sh:97-105`, `devcontainer-config/cc-push.sh:109-159`, `devcontainer-config/cc-push.sh:233-241`

---

## Claim 3: "upload-pack READS there … It runs no hook, no fsmonitor, no filter, and ignores uploadpack.packObjectsHook from repo config." / guide: a cc-push "fires none of them"

**Location:** `devcontainer-config/cc-push.sh:32-36`; `guides/cc-isolated-usage.md:187`, `:220-226`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the plant set in `plant_all` on git 2.39.5: 30 hook names, a husky hooksPath, fsmonitor, clean/smudge/process filters with attributes, ssh/proxy/askpass/pager, alternateRefsCommand, packObjectsHook, a credential helper, diff.external, receive/upload-pack, a repointed origin with a hook, pushDefault and a legacy remotes file. Does not establish the absence of other upload-pack-triggered execution routes, behaviour on other git versions, or resistance to plants outside this set; I did no adversarial probing.

The test "cc-push runs nothing planted in the checkout (full plant set)" (`test/cc-push.bats:107`) passes in suite340.log. The plant list is quoted from `test/cc-push.bats:48-89` (paraphrased — no quote available because the plant list is 40 lines of `git config --file` calls; each key named in the Scope is present there).

**Evidence:** `test/cc-push.bats:48-89`, `test/cc-push.bats:107-120`, suite340.log

---

## Claim 4: "WHAT UPLOAD-PACK WOULD READ BEYOND THE CHECKOUT, AND SO IS REFUSED … a `.git` that is not a real directory …, commondir, objects/info/alternates or http-alternates, a symlink outside hooks/, a FIFO, socket or device, or … an [include] or [includeIf] section"

**Location:** `devcontainer-config/cc-push.sh:45-54` (also `guides/cc-isolated-usage.md` "What it refuses")
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers that `check_checkout` tests exactly the listed conditions and that each tested refusal exits 1 without fetching (the E2c/P2a/E2b and related tests). Does not establish that this list is every way upload-pack can be made to read outside `$co/.git`: I did not examine how upload-pack locates a repository from the given path, and did no adversarial probing. The header's "Otherwise upload-pack could fetch history…" is an implied completeness claim that this report does not clear.

```bash
# devcontainer-config/cc-push.sh:125-158 (excerpt; enclosing check_checkout runs :122-159 — read)
if [ -L "$g" ]; then die "…symlink…"; fi
if [ ! -d "$g" ]; then die "…not a directory…"; fi
if [ -e "$g/commondir" ] || [ -L "$g/commondir" ]; then die …
for f in objects/info/alternates objects/info/http-alternates; do …
if ! odd="$(find -P "$g" -path "$g/hooks" -prune -o \( -type l -o ! -type f ! -type d \) -printf '%p' -quit 2>&1)"; then
…
if LC_ALL=C grep -Eiq '\[[[:space:]]*include' "$g/$f"; then
```
All 10 refusal tests (`test/cc-push.bats:210-321`) pass in suite340.log.

**Evidence:** `devcontainer-config/cc-push.sh:122-159`, `test/cc-push.bats:210-321`, suite340.log

---

## Claim 5: "EVERY STRING FROM THE CHECKOUT (branch names, commit text, git's messages) is printed through vis"

**Location:** `devcontainer-config/cc-push.sh:56-57`, `:77-84`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `say`, `die` and `run_vis` (fetch, log, push output) and the `diff --stat` pipe, all of which pipe through `LC_ALL=C tr -c '[:print:]\n' '?'`, plus the E4 tests. Does not establish anything about the lines that print no checkout-derived text (`printf 'Push these? [y/N] '`, `echo "Not pushed."`, the guard's `echo` at :305).

```bash
# devcontainer-config/cc-push.sh:82-94
vis() {
  LC_ALL=C tr -c '[:print:]\n' '?'
}
say() {
  printf '%s\n' "$*" | vis
}
die() {
  printf 'ERROR: %s\n' "$*" | vis >&2
  exit 1
}
```
The diff stat is `… --stat "$base...$src" 2>/dev/null | vis` (`cc-push.sh:270`). The E4 tests (`test/cc-push.bats:330`, `:346`) pass.

**Evidence:** `devcontainer-config/cc-push.sh:82-94`, `devcontainer-config/cc-push.sh:161-166`, `devcontainer-config/cc-push.sh:270`, `test/cc-push.bats:330-358`, suite340.log

---

## Claim 6: "--help prints the whole header, exit codes included" (0566bc0) / usage "from line 2 to the first line that is not a comment"

**Location:** `devcontainer-config/cc-push.sh:71-75`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `--help` output at 61d801c; does not establish behaviour if a blank non-comment line is inserted into the header.

`awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }'` (`cc-push.sh:74`). Running `--help` exits 0. Its output ends with the "KEEP THE CLONE HOOK-FREE" paragraph (header line 63) and contains "Exit codes:" at output line 20.

**Evidence:** `devcontainer-config/cc-push.sh:71-75`, cc-push-help.log

---

## Claim 7: "every error reason is written by _snap_fail (tools' own error text is dropped: it would quote a path raw)"

**Location:** `devcontainer-config/cc-isolated.sh:613-617`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every `_snap_fail` call site in the scan helpers. Does not establish anything about output outside the snapshot (the launcher's own `devcontainer` messages).

Every reason does go through `_snap_fail`, which maps all non-printable bytes, line breaks included, to `?` (`cc-isolated.sh:685-692`). But tool error text is not always dropped. `find`'s and `git config`'s stderr are included, sanitized:

```bash
# devcontainer-config/cc-isolated.sh:782-783 (enclosing _snap_find :780-786 — read)
if ! find -P "$@" -print0 > "$out" 2> "$out.err"; then
  _snap_fail 'cannot list everything under %s: %s' "$1" "$(cat "$out.err")"
```
The same pattern appears at `cc-isolated.sh:881` (`_snap_config`) and `:999` (`_snap_host_config`). A precise version would read "tools' own error text is dropped or passed through _snap_fail". The sanitizing conclusion holds.

**Evidence:** `devcontainer-config/cc-isolated.sh:685-692`, `devcontainer-config/cc-isolated.sh:780-786`, `devcontainer-config/cc-isolated.sh:880-882`, `devcontainer-config/cc-isolated.sh:998-1000`

---

## Claim 8: "a file too large to hash (over 64 MiB, or past 1 GiB in all: _snap_size_ok) makes the snapshot fail" / 61d801c "Size cap: a file over 64 MiB … fails the snapshot … instead of stalling it"

**Location:** `devcontainer-config/cc-isolated.sh:595-598`, `:704-726`; `guides/cc-isolated-usage.md:261-264`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers files recorded through `_snap_file`, which calls `_snap_size_ok` before `_snap_hash` (`cc-isolated.sh:742`, `:755`), and the two size-cap tests. Does not establish a cap on reads that bypass `_snap_file`: `scan_git_dirs` reads the top-level `.git` file's and `commondir`'s first line with `read` before any size check (`cc-isolated.sh:655`, `:666`), and `git config --file` parses configs that are only per-file-capped. "Instead of stalling it" is established for hashed files only.

```bash
# devcontainer-config/cc-isolated.sh:754-756 (enclosing _snap_file :733-769 — read)
  elif [ -f "$p" ]; then
    _snap_size_ok "$p" || return 1
    h="$(_snap_hash "$p")" || return 1
```
Both size-cap tests pass in suite340.log.

**Evidence:** `devcontainer-config/cc-isolated.sh:648-673`, `devcontainer-config/cc-isolated.sh:704-769`, suite340.log

---

## Claim 9: "A Ctrl-C during the exit scan also exits 4, saying the scan did not finish."

**Location:** `devcontainer-config/cc-isolated.sh:599-600`, `:1285-1294`, `:1459-1466`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers SIGINT delivered while `git_exit_scan` runs (trap installed at :1463, removed at :1466) and the test "a Ctrl-C during the exit scan exits 4". Does not establish behaviour for SIGTERM/SIGHUP (documented as "scans nothing"), or for an INT arriving between `devcontainer exec` returning and the trap swap.

```bash
# devcontainer-config/cc-isolated.sh:1463-1466 (enclosing main continues to :1472 — read)
  trap scan_interrupted INT
  local scan=0
  git_exit_scan "$ws" "$git_before" "$lws" || scan=$?
  trap - INT
```
**Evidence:** `devcontainer-config/cc-isolated.sh:1285-1294`, `devcontainer-config/cc-isolated.sh:1454-1471`, suite340.log

---

## Claim 10: "exits **3** naming anything the session added, removed or changed. It exits 4 when the exit scan cannot list or read any of it"

**Location:** `guides/cc-isolated-usage.md:55-57` (also `:235-237`)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the exit mapping in `main`; does not establish that exit 3 or 4 always means a scan result.

```bash
# devcontainer-config/cc-isolated.sh:1467-1471
  case "$scan" in
    0) exit "$rc" ;;
    1) exit 3 ;;
    *) exit 4 ;;
  esac
```
On a clean scan the launcher exits with `claude`'s (via `devcontainer exec`) own status `rc`. If that is 3 or 4, it is indistinguishable from a scan result. Precise version: 3/4 on a finding/failed scan; otherwise `devcontainer exec … claude`'s status.

**Evidence:** `devcontainer-config/cc-isolated.sh:1458-1471`

---

## Claim 11: LIMITS / guide "Known routes it does not see" list the uncovered routes

**Location:** `devcontainer-config/cc-isolated.sh:619-639`; `guides/cc-isolated-usage.md` (list after "It catches the common plants")
**Type:** Invariant
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers one structural observation about which working-tree git dirs the scan discovers; does not establish whether the list is complete. That would need an adversarial enumeration of host-git execution routes, which I did not do.

Discovery of git dirs in the working tree is by the name `.git` only:
```bash
# devcontainer-config/cc-isolated.sh:1181-1182 (enclosing git_exec_snapshot :1153-1204 — read)
    list="$_snap_tmp/worktree" &&
    _snap_find "$list" "$_snap_ws" -mindepth 2 -name .git
```
A directory in the working tree laid out as a bare repository, and not named by a remote, `commondir` or a symlink, is not walked. Host git can use such a directory as a repository when run from inside it: git 2.39's `safe.bareRepository` defaults to `all` (paraphrased — no quote available because this is git's documented default, not code in this repo; not executed here). Neither LIMITS nor the guide names this case. Only "Host programs pointed at the checkout" is close, and it names editors and tools, not git. This is a documentation gap to confirm, not a verified bypass.

**Evidence:** `devcontainer-config/cc-isolated.sh:619-639`, `devcontainer-config/cc-isolated.sh:1048-1063`, `devcontainer-config/cc-isolated.sh:1181-1191`

---

## Claim 12: tool list "find, stat, readlink, realpath, sha256sum, cat, tr, sort, awk, cut, mktemp, dirname and rm"

**Location:** `devcontainer-config/cc-isolated.sh:606-608`; `guides/cc-isolated-usage.md:~258-260`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the header list against the scan helpers; does not establish anything about the tools the launcher uses outside the scan.

The header list matches the helpers read (`sha256sum` :697, `stat` :714, `readlink` :739, `realpath` :802, `mktemp` :1173, `rm` :1201, `sort` :1203, `awk`/`cut` :1218-1233). The scan also runs `git config` (stated separately) and `sed` (`cc-isolated.sh:1249`, in the report printer). The guide's copy omits `dirname` and `rm`.

**Evidence:** `devcontainer-config/cc-isolated.sh:695-702`, `devcontainer-config/cc-isolated.sh:1173-1203`, `devcontainer-config/cc-isolated.sh:1218-1249`

---

## Claim 13: install.sh ships, chmods and links cc-push; enforcement_files hashes it; the gate covers it

**Location:** `devcontainer-config/install.sh:110`, `:596-603`; `devcontainer-config/cc-isolated.sh:117`; `hooks/live-verify-gate.sh:73`
**Type:** Configuration / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the PAYLOAD entry, chmod, `ln -sf` to `$BIN_DIR/cc-push`, the `echo "cc-push.sh"` in `enforcement_files`, and the gate regex, via install-host T3 and live-verify-gate "every manifest-hashed file is in the enforcement set". Does not establish a real (non-stub) install on the host.

`PAYLOAD=(… cc-isolated.sh cc-push.sh link-claude-home.sh …)`, `ln -sf "$DEST/cc-push.sh" "$BIN_DIR/cc-push"`, `echo "cc-push.sh"`, gate `…|cc-isolated\.sh|cc-push\.sh|install\.sh$|…`. The install-host and gate suites pass in suite340.log.

**Evidence:** `devcontainer-config/install.sh:110`, `devcontainer-config/install.sh:596-603`, `devcontainer-config/cc-isolated.sh:108-132`, `hooks/live-verify-gate.sh:73`, `test/install-host.bats:204-215`, suite340.log

---

## Claim 14: 61d801c "340/340; … 12/12. shellcheck … clean"; "All 9 new cc-isolated cases fail against 4435c73's cc-isolated.sh and pass here"

**Location:** commit 61d801c message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the 340/12 counts, the shellcheck result and the existence and passing of exactly 9 new cc-isolated cases. Does not establish the "fail against 4435c73" half, which I did not run (see Claim 15).

The suites give 340 ok of 340 and 12 ok of 12, and shellcheck exits 0. `git diff 0566bc0 61d801c -- test/cc-isolated-functions.bats | grep '^+@test'` lists 9 cases (E6×2, logical_workspace, E8×2, relremote, size cap×2, Ctrl-C).

**Evidence:** suite340.log, suite12.log, shellcheck.log, `test/cc-isolated-functions.bats`

---

## Claim 15: "All 9 new cc-isolated cases fail against 4435c73's cc-isolated.sh"

**Location:** commit 61d801c message
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers nothing beyond noting the claim; does not establish the red-before-green property of the new tests.

Execution required but not done: it would need running the 9 cases against `git show 4435c73:devcontainer-config/cc-isolated.sh`. I left this out to keep within the benign-execution scope and the time budget.

**Evidence:** commit 61d801c message

---

## Claim 16: 0566bc0 "plant_all now plants every githooks(5) name (30 incl. 2 non-hooks)"

**Location:** `test/cc-push.bats:48-58`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the count and the two non-hook names; does not establish that the list matches githooks(5) for git versions other than 2.39.

The loop lists 30 names, ending `… post-index-change pre-upload upload-pack; do`. The comment says "plus two names that are not hooks (pre-upload, upload-pack)".

**Evidence:** `test/cc-push.bats:48-58`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 7** (`devcontainer-config/cc-isolated.sh:613-617`): find/git-config stderr is kept, sanitized via `_snap_fail`, not dropped. Reword.
- **Claim 10** (`guides/cc-isolated-usage.md:55-57`): on a clean scan the launcher passes through claude's own status, so 3/4 are not exclusively scan results.
- **Claim 12** (`devcontainer-config/cc-isolated.sh:606-608`): the guide's tool list omits `dirname`/`rm`. The scan's report also uses `sed`.

### Unverifiable
- **Claim 11** (`devcontainer-config/cc-isolated.sh:619-639`): LIMITS completeness needs an adversarial enumeration. One candidate gap to confirm: a bare-repo-shaped directory in the working tree is not discovered and is not listed as a limit.
- **Claim 15** (commit 61d801c): run the 9 new cases against 4435c73's cc-isolated.sh.

Scope residues to carry forward (Verified but narrow): Claims 3–4 (cc-push "runs nothing" and the refusal set) are cleared only for the tested plant and refusal sets, not for bypass resistance. Claim 8's size cap does not cover the `read` of `.git`/`commondir` in `scan_git_dirs`.

## Goal-Alignment Note

- **Success criterion (verbatim):** A code-fact-check report saved at /workspace/docs/reviews/q076-code-fact-check-report-r2.md in the skill's schema, with a Goal-Alignment Note.
- **Answered:** exit codes, vis sanitizing, "no git in the checkout", the refusal set as coded, exit-scan fail-closed/size-cap/Ctrl-C/sanitizing claims, install/manifest/gate wiring, test counts and shellcheck (executed), iteration-3 closures to the extent the new tests exercise them (E2b, E2c/P2a, E4, E5, E6, E8, relremote, size cap, Ctrl-C all have passing tests).
- **Out of scope:** I did not construct adversarial checkouts to try to defeat cc-push's refusals or the exit scan (planted config/hooks/filters, ref or symlink tricks, host-global settings). A previous attempt in this session to go further in that direction was stopped by a safety classifier. The bypass-resistance questions therefore remain open, and every related Verified is scoped to tested inputs. Also not run: the red-before-green check against 4435c73.
- **Escalate:** (1) Whether "cc-push reads nothing beyond the checkout" (Claim 4's implied completeness) holds needs a dedicated security review. (2) Claim 11's candidate LIMITS gap (bare-repo-shaped working-tree dir). (3) Claim 8's unchecked `read` of `.git`/`commondir`.
