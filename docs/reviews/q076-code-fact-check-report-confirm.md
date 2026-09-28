Commit: bfe8292

# Code Fact-Check Report

**Repository:** /workspace (scratch clone at bfe8292: /tmp/claude-1000/-workspace/dbfd30e0-d8d5-40c1-8bac-572239fc44fd/scratchpad/q076rev-confirm/repo)
**Commit:** bfe8292570e81f716025e3ef0dceaefea5a6e1d6 (tip of `feat/q076-git-exit-scan`)
**Replication:** k=1 (confirming pass)
**Scope:** claims added or changed by `git log 61d801c..feat/q076-git-exit-scan` (f511cc1, 9133e23, 41622c0, 6fc7b5a, bfe8292): comments and headers in devcontainer-config/cc-push.sh, cc-gitdir.sh, cc-exit-scan.sh, cc-isolated.sh; guides/cc-isolated-usage.md; guides/devcontainer-setup.md; docs/decisions/log.md row 58; test names; commit-message claims. Plus closure of the Incorrect claims in q076-code-fact-check-report-r1..r3.md.
**Checked:** 2026-09-27
**Total claims checked:** 28 (26 numbered; Claims 7 and 12 split into a/b)
**Summary:** 22 verified, 4 mostly accurate, 0 stale, 1 incorrect, 1 unverifiable

Method: every enclosing function cited was read in full at bfe8292. Executed claims ran in the scratch clone (or in per-commit worktrees beside it, `wt-<sha>` and `rb1..rb3`) on git 2.39.5, LC_ALL=C.UTF-8. Logs are under `/tmp/claude-1000/-workspace/dbfd30e0-d8d5-40c1-8bac-572239fc44fd/scratchpad/q076rev-confirm/logs/` (called `logs/` below). No docker and no devcontainer CLI in this sandbox; the container checks were exercised only through the suite's stubs.

**Prior Incorrect claims: all closed.** r1 Claim 1 (cc-push fell back to a repository planted at the checkout root): closed, see Claim 14. r1 Claim 9 (the exit scan missed root promotion): closed, see Claims 1 and 7a/7b. r3 Claim 7 (the comment said tools' error text was dropped): closed, see Claim 3.

---

## Claim 1: "Also whether git would accept the git dir at all (gitdir_valid, and HEAD's kind) and whether the checkout root looks like a git dir (looks_like_gitdir) ... An invalid git dir at exit is a finding even if it was invalid at launch."

**Location:** `devcontainer-config/cc-exit-scan.sh:68-71`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the gitdir-valid and root-repo records in `git_exec_snapshot` and the invalid-at-exit rule in `git_exit_scan`, for the fixture plants in the suite; does not establish that other layouts git accepts (e.g. under a git other than 2.39) are recorded.

The snapshot records both facts:

```bash
# devcontainer-config/cc-exit-scan.sh:652-655
  if gitdir_valid "$_snap_gd"; then i=valid; else i=invalid; fi
  _snap+="F"$'\t'"gitdir-valid"$'\t'"$(printf '%q' "$ws/.git")"$'\t'"$i HEAD=$(gitdir_head_kind "$_snap_gd")"$'\n'
  if looks_like_gitdir "$_snap_ws"; then i="looks like a git dir"; else i="not a git dir"; fi
  _snap+="F"$'\t'"root-repo"$'\t'"$(printf '%q' "$_snap_ws")"$'\t'"$i"$'\n'
```

`git_exit_scan` (read in full, `:746-798`) treats an invalid record at exit as a finding even when the before and after snapshots are equal:

```bash
# devcontainer-config/cc-exit-scan.sh:767-770
  local invalid=""
  if printf '%s\n' "$after" | LC_ALL=C grep -q $'^F\tgitdir-valid\t[^\t]*\tinvalid'; then
    invalid="    ! $(printf '%q' "$ws/.git") is not a valid git directory now: ..."
  fi
```
(excerpt ends :770; enclosing git_exit_scan continues to :798 — read)

Executed: `LC_ALL=C.UTF-8 bats test/cc-push.bats test/cc-isolated-functions.bats test/install-host.bats test/hooks/live-verify-gate.bats test/fixture-hermeticity.bats test/hermeticity-lint.bats`, cwd = scratch clone, 2026-09-28T03:2xZ, exit 0, 371/371. Tests 150-153 and 157-158 cover this: HEAD removed during the session, invalid at launch and still invalid at exit, root repository, root commondir, branch switch clean, and launcher exit 3.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:644-655`, `devcontainer-config/cc-exit-scan.sh:746-798`, `logs/bats-tip.log`

---

## Claim 2: "The rest is host tools reading files: find, stat, readlink, realpath, sha256sum, cat, tr, sort, awk, sed, cut, mktemp, dirname and rm" (and the same list in the guide)

**Location:** `devcontainer-config/cc-exit-scan.sh:86-87`, `guides/cc-isolated-usage.md:320-323`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the set of external commands in cc-exit-scan.sh and cc-gitdir.sh; does not establish anything about the launcher's own git calls outside the scan.

`sed`, `dirname` and `rm` were added (r3 Claim 8 is closed). 9133e23 added a `grep` that the list omits:

```bash
# devcontainer-config/cc-exit-scan.sh:768
  if printf '%s\n' "$after" | LC_ALL=C grep -q $'^F\tgitdir-valid\t[^\t]*\tinvalid'; then
```

It reads the scan's own snapshot string, not a checkout file, and runs nothing, so the list's point still holds. A word-boundary grep of both files found no other command missing from the list (paraphrased — no quote available because the claim is about the absence of other commands, established by a command-name grep over both files).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:86-87`, `devcontainer-config/cc-exit-scan.sh:768`, `guides/cc-isolated-usage.md:320-323`

---

## Claim 3: "The error text of read, readlink, stat and cd is dropped (the reason names the path itself); find's and git config's own error text is kept inside the reason, reduced to that one printable line."

**Location:** `devcontainer-config/cc-exit-scan.sh:93-99`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers `_snap_fail` and the find / git config call sites in cc-exit-scan.sh, and the stat/readlink calls in cc-gitdir.sh; does not establish that every report line elsewhere is %q-quoted.

This closes r3 Claim 7. The text of find and git config errors is passed into `_snap_fail`:

```bash
# devcontainer-config/cc-exit-scan.sh:257-258
  if ! find -P "$@" -print0 > "$out" 2> "$out.err"; then
    _snap_fail 'cannot list everything under %s: %s' "$1" "$(cat "$out.err")"
```

`_snap_fail` reduces it to a single printable line:

```bash
# devcontainer-config/cc-exit-scan.sh:146-148
  m="$(printf "$@")"
  printf '%s' "$m" | LC_ALL=C tr -c '[:print:]' '?' >&2
  echo >&2
```

The same pattern appears at `:355-356` and `:473-474` (git config). stat, readlink and read go to `2>/dev/null`, as in `_snap_first_line` (`:192`, `:198`) and cc-gitdir.sh (`:28`, `:34`, `:58`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:143-150`, `:257-258`, `:355-356`, `:473-474`, `:189-201`, `devcontainer-config/cc-gitdir.sh:28-38`

---

## Claim 4: "LIMITS: what a clean scan does not rule out is listed once, in guides/cc-isolated-usage.md, 'Known routes it does not see'" (and cc-push.sh:94-96, cc-isolated.sh:30-31)

**Location:** `devcontainer-config/cc-exit-scan.sh:101-104`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the existence of the heading and the removal of the second copy; does not establish that the list is complete (see Claim 22).

The heading exists: `guides/cc-isolated-usage.md:334` reads `#### Known routes it does not see`. The old in-file LIMITS bullets were removed in 6fc7b5a (paraphrased — no quote available because the claim is about removed text, visible in `git diff f511cc1..bfe8292 -- devcontainer-config/cc-exit-scan.sh`).

**Evidence:** `guides/cc-isolated-usage.md:334-338`, `devcontainer-config/cc-exit-scan.sh:101-104`

---

## Claim 5: "It ships with the launcher: install.sh's PAYLOAD installs it, enforcement_files() hashes it into the trust manifest, and hooks/live-verify-gate.sh gates commits to it." (cc-gitdir.sh and cc-exit-scan.sh headers, and devcontainer-setup's enforcement list)

**Location:** `devcontainer-config/cc-gitdir.sh:3-5`, `devcontainer-config/cc-exit-scan.sh:3-5`, `guides/devcontainer-setup.md:262-266`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three lists and the tests that pin them; does not establish an install to a real host (install.sh was run only against the suite's fake repo).

```bash
# devcontainer-config/install.sh:110
PAYLOAD=(devcontainer.json Dockerfile init-firewall.sh cc-sni-proxy.py cc-isolated.sh cc-exit-scan.sh cc-gitdir.sh cc-push.sh link-claude-home.sh egress claude-home)
# devcontainer-config/cc-isolated.sh:134-136
  echo "cc-exit-scan.sh"
  echo "cc-gitdir.sh"
  echo "cc-push.sh"
# hooks/live-verify-gate.sh:73
enforcement='^devcontainer-config/(...|cc-isolated\.sh|cc-exit-scan\.sh|cc-gitdir\.sh|cc-push\.sh|install\.sh$|egress/)'
```

install.sh chmods and links only cc-isolated.sh and cc-push.sh (`:596`, `:602`), which fits "sourced, not run". The list-pinning tests (live-verify-gate "every manifest-hashed file is in the enforcement set", and install-host) pass in `logs/bats-tip.log`.

**Evidence:** `devcontainer-config/install.sh:110`, `:596-603`, `devcontainer-config/cc-isolated.sh:125-150`, `hooks/live-verify-gate.sh:73`, `logs/bats-tip.log`

---

## Claim 6: gitdir_head_kind / gitdir_valid model "git 2.39's validate_headref ... is_git_directory"; commit 9133e23: "gitdir_valid is cross-checked against git-upload-pack --strict itself on 21 fixtures"

**Location:** `devcontainer-config/cc-gitdir.sh:16-81`, commit 9133e23 message
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers agreement with `git-upload-pack --strict` on git 2.39.5 over the test's fixtures plus one oversize-HEAD probe; does not establish agreement on other git versions or on layouts outside the fixture set. The "Mostly" is only the fixture count.

The behavior is verified. An instrumented copy of the test printed one line per fixture, and all 22 agreed with git:

```
# logs/xcheck.log (run 2026-09-28T03:34:43Z, cwd scratch clone, exit 0)
XCHECK nohead gitdir_valid=invalid git=invalid want=invalid
XCHECK linkhead gitdir_valid=valid git=valid want=valid
... (22 XCHECK lines, all three columns equal)
```

The test has **22** fixtures, not 21: 15 `gd` copies, the in-place `worktrees/wt`, and 6 `wtgd` copies (`test/cc-push.bats:429-464`; 22 at 9133e23 as well). This resembles the logged pattern class "a specific count quoted from an artifact set that does not contain it" (hallucination-patterns.md, "All 85 tests…" entry), but it is off by one and the behavior holds, so it is not logged. The documented strictness was also confirmed: git accepts a HEAD over 255 bytes and `gitdir_valid` rejects it (`logs/bighead.log`: `git-rc=0`, `gitdir_valid-rc=1`, kind `invalid`).

**Evidence:** `devcontainer-config/cc-gitdir.sh:24-81`, `test/cc-push.bats:429-464`, `logs/xcheck.log`, `logs/bighead.log`

---

## Claim 7a: cc-isolated EXIT STATUS: "1 an error, including a launch refused because the scan's baseline could not be taken (the checkout's .git unreadable, ...) — 1 at launch, where the same failure at exit is 4"

**Location:** `devcontainer-config/cc-isolated.sh:23-26`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the *unreadable* case only; the other two cases in the same sentence are Claim 7b.

When the snapshot fails, `git_exit_scan` returns 2 (`cc-exit-scan.sh:749-762`), and the launcher maps that to exit 4:

```bash
# devcontainer-config/cc-isolated.sh:745-749
  case "$scan" in
    0) exit "$rc" ;;
    1) exit 3 ;;   # the session planted something: never a clean exit
    *) exit 4 ;;   # the scan could not read .git
  esac
```

At launch, a snapshot failure exits 1 (`cc-isolated.sh:671-679`). The tests "exit scan: an unreadable .git is reported (status 2)" and the launch refusals pass (`logs/bats-tip.log`).

**Evidence:** `devcontainer-config/cc-isolated.sh:655-681`, `:737-749`, `logs/bats-tip.log`

---

## Claim 7b: same sentence, for "not a git dir git accepts, or the root already looking like one": "— 1 at launch, where the same failure at exit is 4" (also commit 6fc7b5a: "a refused baseline at launch is 1; the same failure at exit is 4")

**Location:** `devcontainer-config/cc-isolated.sh:23-26`, commit 6fc7b5a message
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the exit status for an invalid `.git` or a root repository at session exit; does not question the launch-time exit 1 (Verified, see Claim 7a).

At exit these two states are not snapshot failures. They are findings: `git_exit_scan` returns 1 (Claim 1), and the launcher maps 1 to **exit 3**, not 4 (`cc-isolated.sh:747`). The suite asserts exactly that:

```bash
# test/cc-isolated-functions.bats:1427-1434
@test "exit scan gitdir: a session that makes .git invalid ends the launcher with exit 3" {
  ...
  session_stub "$ws" "rm '$ws/.git/HEAD'"
  run bash "$CONFIG_SRC/cc-isolated.sh" "$TEST_TMPDIR/proj"
  [ "$status" -eq 3 ]
```

It passes at the tip (test 158, `logs/bats-tip.log`). A root repository planted during the session is likewise a finding (test 152). The guide's own paragraph (`guides/cc-isolated-usage.md:62-64`) narrows the 1-then-4 rule to ".git cannot be read", which is correct. The `--help` header, which prints this sentence, reads broader. A script author would expect 4 where the launcher gives 3. The fix is to limit "the same failure at exit is 4" to the unreadable case, and to say that an invalid `.git` or a root repository at exit is 3.

**Evidence:** `devcontainer-config/cc-isolated.sh:23-26`, `:745-749`, `devcontainer-config/cc-exit-scan.sh:765-775`, `test/cc-isolated-functions.bats:1427-1435`, `logs/bats-tip.log`, `logs/iso-help.out`

---

## Claim 8: "readlink -f: the command on PATH is a symlink to the installed copy" (the sourcing of cc-exit-scan.sh / cc-gitdir.sh)

**Location:** `devcontainer-config/cc-isolated.sh:556-560`, `devcontainer-config/cc-push.sh:114-117`, `devcontainer-config/cc-exit-scan.sh:8-11`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers running through a symlink in another directory; does not establish the installed layout written by a real install.sh run.

`source "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/cc-exit-scan.sh"` (`cc-isolated.sh:560`). Executed at 2026-09-28T03:36:41Z, cwd scratchpad: `bin/cc-isolated --help` via a symlink gave rc 0, and `bin/cc-push --help` gave rc 0. A control copy of cc-push.sh with no sibling cc-gitdir.sh failed with "cc-gitdir.sh: No such file" (rc 1). So the sibling lookup is real.

**Evidence:** `devcontainer-config/cc-isolated.sh:556-560`, `logs/symlink-source.log`

---

## Claim 9: cc-push exit codes: "0 pushed, or nothing to push; 1 an error ... or declined at the prompt (n, or Ctrl-C); 2 bad usage (an unknown flag, a flag without its value, two checkouts)"; "One checkout at a time: a second one, before or after `--`, is a usage error."

**Location:** `devcontainer-config/cc-push.sh:25-32`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers usage parsing, decline, Ctrl-C at the prompt, and the guard's mapping; does not establish Ctrl-C at other points against a live terminal.

Manual runs at 2026-09-28T03:35:10Z, cwd scratch clone: `--bogus`, `a b`, `a -- b`, `-- a b` and `--remote` (no value) each exited 2 (`logs/`: printed inline in the session, same run as `push-help.out`). The guard maps any other status to 1:

```bash
# devcontainer-config/cc-push.sh:472-476
  case "$rc" in
    0|1|2) exit "$rc" ;;
    130) echo "ERROR: cc-push was interrupted." >&2; exit 1 ;;
    *) echo "ERROR: cc-push stopped on an unexpected failure (status $rc)." >&2; exit 1 ;;
  esac
```

Tests "cc-push declined at the prompt pushes nothing and exits 1", "Ctrl-C at the prompt is a decline: exit 1, not 130" and "usage errors exit 2" pass (`logs/bats-tip.log`). This closes r3 Claim 1.

**Evidence:** `devcontainer-config/cc-push.sh:311-330`, `:441-452`, `:467-477`, `logs/bats-tip.log`

---

## Claim 10: "--strict makes it use exactly that directory or fail (it never tries <dir>/.git or another repository instead)"

**Location:** `devcontainer-config/cc-push.sh:44-49`, `guides/cc-isolated-usage.md:263-265`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5's upload-pack on a working-tree dir, a valid .git, and an invalid .git with a bare layout planted at the root; does not establish other git versions.

Probe (`logs/strict-probe.log`, 2026-09-28T03:36:24Z, cwd scratchpad). Without `--strict`, `ls-remote strict/w` resolved to `w/.git` (rc 0). With `--strict`, the same path failed: `'strict/w' does not appear to be a git repository` (rc 128). With `--strict`, `strict/w/.git` succeeded (rc 0). After HEAD was removed and a bare layout planted at `w/`, `--strict` on `w/.git` failed (rc 128), while plain `ls-remote strict/w` fell back to the root repository (rc 0). All three cc-push calls pass `"${upl[@]}"` and `"$co/.git"` (`cc-push.sh:389`, `:398`, `:405-407`), and the argv test (`test/cc-push.bats:536`) passes.

**Evidence:** `devcontainer-config/cc-push.sh:385-411`, `logs/strict-probe.log`, `logs/bats-tip.log`

---

## Claim 11: "Every git command cc-push runs passes core.hooksPath=/dev/null and core.fsmonitor=false" (and guide: "Every git command it runs passes ...")

**Location:** `devcontainer-config/cc-push.sh:57-58`, `guides/cc-isolated-usage.md:272-273`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every `git` invocation in cc-push.sh; does not establish anything about what git-upload-pack inherits beyond the `-c` parameters.

Every repository-touching call goes through `ngit`/`hgit` (`:152-160`). One call does not:

```bash
# devcontainer-config/cc-push.sh:189
  v="$(git --version 2>/dev/null)" || die "cannot run git --version"
```

`git --version` reads no repository and runs no hook, so the claim holds for the property it protects. The precise wording is "every git command that reads a repository".

**Evidence:** `devcontainer-config/cc-push.sh:152-160`, `:187-191`

---

## Claim 12a: git_version_ok refuses "a git older than ... 2.39.4, 2.40.2, 2.41.1, 2.42.2, 2.43.4, 2.44.1, 2.45.1, or any 2.46 and later"

**Location:** `devcontainer-config/cc-push.sh:63-67`, `:169-184`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the code implementing the stated list; does not establish that the list matches git's release history (Claim 12b).

```bash
# devcontainer-config/cc-push.sh:178-183
  case "$min" in
    39) need=4 ;; 40) need=2 ;; 41) need=1 ;; 42) need=2 ;;
    43) need=4 ;; 44) need=1 ;; 45) need=1 ;;
    *)  return 1 ;;   # before 2.39: no fixed release in that series
  esac
  [ "$pat" -ge "$need" ]
```

The test "git_version_ok: the May 2024 fixed releases and later pass, earlier ones do not" passes. The sandbox's 2.39.5 passes the check.

**Evidence:** `devcontainer-config/cc-push.sh:169-191`, `logs/bats-tip.log`

---

## Claim 12b: that those versions are "the fixed releases of the May 2024 git security update"

**Location:** `devcontainer-config/cc-push.sh:63-67`, `guides/cc-isolated-usage.md:237-241`
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers nothing external; the text itself says "as recalled, not checked against them offline".

This needs git's release notes or the 2024-05-14 security announcement, and the sandbox has no egress. This reviewer's own recollection matches the list (2.39.4 through 2.45.1), but that is not evidence (paraphrased — no quote available because the source is external release notes that cannot be reached). To verify: read Documentation/RelNotes/2.39.4.txt … 2.45.1.txt in git.git.

**Evidence:** `devcontainer-config/cc-push.sh:63-67`

---

## Claim 13: "A running cc-isolated container for this checkout (docker ps, label cc-project=<id>, the id cc-isolated.sh's project_id gives) ... Without docker, or when docker does not answer, cc-push ... refuses as well. --allow-running overrides both, with a warning." / project_id "The same logic as cc-isolated.sh's project_id (test/cc-push.bats pins that they agree)"

**Location:** `devcontainer-config/cc-push.sh:68-72`, `:162-167`, `:193-225`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the logic against a stubbed docker and the id function's agreement; does not establish behavior against a real docker daemon (none in the sandbox).

Both files compute `printf '%s' "$1" | sha256sum | cut -c1-12` (`cc-push.sh:166`, `cc-isolated.sh:248-250`). cc-isolated labels containers `--id-label "cc-project=$pid"` (`cc-isolated.sh:647`). Both key on the physical path. A symlinked checkout gave the same `.../pid/real` from `git rev-parse --show-toplevel` (cc-isolated's resolve_workspace) and from `pwd -P` (cc-push's find_checkout), checked in this session. Tests 33-37 (project_id agreement, running container refused, --allow-running, docker not answering, no docker) pass. Medium confidence because docker is stubbed.

**Evidence:** `devcontainer-config/cc-push.sh:162-225`, `devcontainer-config/cc-isolated.sh:230-250`, `:645-647`, `logs/bats-tip.log`

---

## Claim 14: cc-push refuses unless "<checkout>/.git is a directory git accepts as a git directory ... and that the checkout root itself does not look like a git directory ... When .git is not valid, git's discovery falls back to treating the root as a bare repository"

**Location:** `devcontainer-config/cc-push.sh:73-90`, `:285-292`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the route of r1 Claim 1 (invalid .git plus a repository planted at the root) and the refusal set as coded; does not establish resistance to layouts git versions other than 2.39 accept.

This closes r1 Claim 1:

```bash
# devcontainer-config/cc-push.sh:287-292
  if ! gitdir_valid "$g"; then
    die "$g is not a valid git directory ..."
  fi
  if looks_like_gitdir "$co"; then
    die "$co itself looks like a git directory ..."
  fi
```
(excerpt ends :292; enclosing check_checkout spans :242-293 — read)

Red then green. With 9133e23's tests run against f511cc1's code (`rb1` worktree), "cc-push refuses a .git without HEAD, and does not fall back to a repository planted at the root" failed with `# Pushed main to origin.` in its output. It passes at the tip. The root-fallback mechanism was also reproduced directly: `git -C bare/co/sub rev-parse --git-dir` → `.`, `--is-bare-repository` → `true` (`logs/bare-subdir.log`).

**Evidence:** `devcontainer-config/cc-push.sh:242-293`, `logs/redgreen-9133e23-on-f511cc1.log`, `logs/bats-tip.log`, `logs/strict-probe.log`

---

## Claim 15: "EVERY STRING FROM THE CHECKOUT (branch names, commit text, git's messages, including the stderr of every git call that can name a checkout ref) is printed through vis"

**Location:** `devcontainer-config/cc-push.sh:98-100`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every git call in main() (read `:311-460`); does not establish terminal behavior for bytes vis maps (tested in earlier rounds).

The wording is now limited to strings from the checkout (r1 Claim 5 is closed). rev-list and config stderr go through `err_vis` (`:363-365`, `:374`, `:378`, `:398`, `:424`), which closes r3 Claim 5. The remaining calls either route through `run_vis`/`vis` or discard stderr: `ls-remote --symref ... 2>/dev/null` (`:389`), `rev-parse -q --verify ... >/dev/null` (`:410`, `:422`), and `diff ... 2>/dev/null | vis` (`:433`).

**Evidence:** `devcontainer-config/cc-push.sh:295-309`, `:353-459`

---

## Claim 16: Decision log #58: "cc-push moves to it (declined was 2 and usage was 1; Ctrl-C at the prompt was 130), and cc-isolated's usage errors move from 1 to 2 ... After a clean scan it still passes claude's own exit status through"

**Location:** `docs/decisions/log.md:81`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the before (9133e23) and after (bfe8292) codes; does not establish that no external caller branches on them.

At 9133e23, cc-push had `*) echo "Not pushed."; exit 2 ;;` (declined 2) and `die` exiting 1 for usage. The guard had no INT trap, so a Ctrl-C killed the parent with 130. cc-isolated had `-*) echo "ERROR: unknown flag: $1" >&2; usage >&2; exit 1 ;;`. At the tip the codes are 1 for declined and 2 for usage (Claim 9; cc-isolated `--bogus` and `--profile` with no value both exit 2, run in this session). Pass-through: `0) exit "$rc" ;;` (`cc-isolated.sh:746`). install.sh's contract, "Exit status: 0 no target declined; 1 a target was declined, or an error" (`install.sh:98`) with `exit 2` on an unknown argument (`install.sh:1304`), matches.

**Evidence:** `docs/decisions/log.md:81`, `devcontainer-config/install.sh:98`, `:1304`, `devcontainer-config/cc-isolated.sh:567-582`, `:745-749`

---

## Claim 17: Guide command reference: "`cc-push` takes one checkout (`cc-push A B` and `cc-push A -- B` are usage errors). Both tools follow install.sh's exit-status convention (decision log #58): 1 for an error, or for a prompt you declined; 2 for bad usage."

**Location:** `guides/cc-isolated-usage.md:28-40`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the listed forms and codes; does not establish each listed flag's full semantics beyond parsing (covered by the suite).

Every listed flag appears in cc-push's parser (`cc-push.sh:314-323`). The usage-error runs are in Claim 9. `--remote` is sticky: `config remote.origin.url "$remote"` in the existing-clone branch (`cc-push.sh:373-376`).

**Evidence:** `devcontainer-config/cc-push.sh:311-330`, `:369-378`

---

## Claim 18: Guide "Exit status" paragraph: "a checkout whose `.git` cannot be read exits 1 at launch ... but 4 at exit"; step 7: "refuses to launch (exit 1) ... also when `.git` is already not a git directory git accepts, or the checkout root already looks like one"

**Location:** `guides/cc-isolated-usage.md:46-64`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the launch refusal and the unreadable-at-exit case; does not cover `--probe-only`, which takes no baseline (the commit says so).

`launch_gitdir_ok` (`cc-exit-scan.sh:695-710`) is called before the baseline, and a failure exits 1 (`cc-isolated.sh:659-669`). Tests 154-156 (launch_gitdir_ok, root repository refused, HEAD over 255 bytes refused) pass. Unlike the header (Claim 7b), the guide limits the 4-at-exit rule to "cannot be read".

**Evidence:** `devcontainer-config/cc-isolated.sh:655-681`, `devcontainer-config/cc-exit-scan.sh:689-710`, `logs/bats-tip.log`

---

## Claim 19: "`test/cc-push.bats` plants every hook ... and asserts that a `cc-push` fires none of them ...; it also covers each refusal above."

**Location:** `guides/cc-isolated-usage.md:273-279`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers which refusals have tests; this text did not change in range and is carried forward from r3 Claim 13.

The new refusals (git version, running container, no docker, partial clone, invalid .git, root repository, root commondir) each have a test. The socket and device refusals still do not: the only special files `test/cc-push.bats` creates are `mkfifo` (`:283`, `:292`, `:320`, `:328`, `:474`). A grep for socket or device creation found nothing (paraphrased — no quote available because the claim concerns absence of matching grep results).

**Evidence:** `test/cc-push.bats:260-330`, `guides/cc-isolated-usage.md:273-279`

---

## Claim 20: "A slow scan. ... about 2–4 s per snapshot on a ~400k-file repository, and about 29 ms more for each embedded repository (the tree walk itself is ~0.05 s per 100k files)"

**Location:** `guides/cc-isolated-usage.md:356-361`
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the per-snapshot figure on /workspace (warm cache) and the review's own numbers; does not re-measure the 29 ms-per-repo or tree-walk figures (quoted from the performance review, as the commit says).

Executed at 2026-09-28T03:37:00Z, cwd /workspace (read-only): `git_exec_snapshot "$PWD"` from the tip's scripts took 2.27 s and 2.16 s, rc 0. /workspace holds about 398k files. The 29 ms and 0.05 s figures appear verbatim in `docs/reviews/q076-performance-review-2026-09-27.md:13` and `:64`.

**Evidence:** `logs/scan-time-workspace.log`, `docs/reviews/q076-performance-review-2026-09-27.md:13`, `:64`, `:126`

---

## Claim 21: "A repository in a working-tree directory not named `.git`. ... A bare-layout directory (`HEAD`, `objects/`, `refs/`) under another name is not walked; host git run *inside* that directory would use it and run its hooks. (Only the checkout root is checked for that layout.)"

**Location:** `guides/cc-isolated-usage.md:367-371`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers discovery on git 2.39.5 with default safe.bareRepository; does not establish behavior with `safe.bareRepository=explicit`.

A `git init --bare` inside a checkout's subdirectory is discovered from inside it: `git -C bare/co/sub rev-parse --git-dir --is-bare-repository` printed `.` and `true` (`logs/bare-subdir.log`, 2026-09-28T03:38:32Z, rc 0). Only the root gets `looks_like_gitdir` (`cc-exit-scan.sh:654`, `cc-push.sh:290`). This closes the r2 Claim 11 and r3 Claim 10 gap: the route is now listed.

**Evidence:** `logs/bare-subdir.log`, `devcontainer-config/cc-exit-scan.sh:654`

---

## Claim 22: The single list gained the routes earlier rounds found unlisted: "`~` forms ... `~user/…`, a bare `~`, and a `~` in a local remote URL are taken as relative paths"; "Another git version"; "After the scan ... `cc-push` refuses while the container runs"; "What `cc-push` still trusts"

**Location:** `guides/cc-isolated-usage.md:350-399`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the entries asked for in r1 Claim 10, r2 Claim 11 and r3 Claims 3b and 10, checked against the code; does not establish that the list is complete (no adversarial enumeration in this pass).

The `~` handling expands only `"~/"*`:

```bash
# devcontainer-config/cc-exit-scan.sh:267
    "~/"*) printf '%s' "$HOME/${1#"~/"}" ;;
# devcontainer-config/cc-exit-scan.sh:448
    "~/"*) pat="$HOME/${pat#"~/"}" ;;
```

A grep found no `~` handling in the remote-path code (paraphrased — no quote available because the claim concerns absence of matching grep results). The container refusal is Claim 13. r1 Claim 10's root-promotion route is now refused at launch and reported at exit, rather than listed.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:262-268`, `:444-450`, `guides/cc-isolated-usage.md:334-399`

---

## Claim 23: Commit f511cc1: "the old cc-isolated.sh lines 554-1294 ... and logical_workspace (old 226-241), byte for byte, under a short header ... diffs against the new file only by the header, one blank line and the removed SIZE paragraph."

**Location:** commit f511cc1 message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the moved text and the launcher's other changes in f511cc1; does not cover later edits to the moved file (Claims 1-3).

`git show f511cc1~1:devcontainer-config/cc-isolated.sh | sed -n '226,241p;554,1294p'`, diffed against `git show f511cc1:devcontainer-config/cc-exit-scan.sh` (cwd /workspace, exit 1 = differences), shows exactly: the 7-line header added (`0a1,7`), one blank line (`16a24`), and the 4-line SIZE paragraph removed (`103,106d110`). The launcher's other additions in that commit are the `echo "cc-exit-scan.sh"` line and the 5-line source block.

**Evidence:** `logs/extraction.diff`, `logs/old-block.sh`, `logs/new-scan-f511.sh`

---

## Claim 24: Commit-message test counts: f511cc1 "352/352"; 9133e23 "355/355; ... 12/12"; 41622c0 "cc-push.bats 44/44"; 6fc7b5a "Suite 159/159"; plus "shellcheck ... clean"

**Location:** commits f511cc1, 9133e23, 41622c0, 6fc7b5a
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each count at its own commit with the suite list the message names; does not cover a "388" figure, which no commit message in range contains.

Each suite list was run in a worktree at its commit, LC_ALL=C.UTF-8, all exit 0. f511cc1, nine files: `1..352`. 9133e23, six files: `1..355`, plus three docs files: `1..12`. 41622c0, cc-push.bats: `1..44`. 6fc7b5a, cc-isolated-functions.bats: `1..159`. At the tip the six-file set is 371/371 and the docs set 12/12 (383 in all). shellcheck at the tip (`-x -e SC1091 -s bash -S warning`, nine changed .sh/.bats files) exited 0 with empty output. `git log 61d801c..bfe8292 | grep 388` returns nothing.

**Evidence:** `logs/bats-f511cc1.log`, `logs/bats-9133e23.log`, `logs/bats-9133e23-docs.log`, `logs/bats-41622c0-push.log`, `logs/bats-6fc7b5a-iso.log`, `logs/bats-tip.log`, `logs/bats-tip-docs.log`, `logs/shellcheck-tip.log`

---

## Claim 25: Red-before-green claims: 9133e23 "All five cc-push behaviour tests and all six scan gitdir tests fail on f511cc1 ...; the sparse-gitfile test hangs there"; 41622c0 "12 new ... (all fail against 9133e23)"; 6fc7b5a "all 6 touched tests fail against 9133e23"

**Location:** commits 9133e23, 41622c0, 6fc7b5a
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the named tests run at the old code with the new test file; does not establish why each failed beyond spot checks.

Each run put the newer test file into a worktree at the older code (for rb1, `cc-gitdir.sh` too, so the file could be sourced):

- **rb1** (9133e23's tests on f511cc1's code): 5 cc-push and 6 exit-scan-gitdir tests, 11/11 `not ok`. Test 10 (branch switch) failed only on the new record assertion, as the message says. `bats -f sparse` under `timeout 60` gave rc 124 (a hang).
- **rb2** (41622c0's cc-push.bats on 9133e23's code): tests 33-44, the 12 new ones, are all `not ok`. So are the three updated tests (5, 24, 32).
- **rb3** (6fc7b5a's cc-isolated-functions.bats on 9133e23's code): exactly 6 `not ok` (26, 28, 29, 110, 111, 112), the touched set.

**Evidence:** `logs/redgreen-9133e23-on-f511cc1.log`, `logs/redgreen-sparse-on-f511cc1.log`, `logs/redgreen-41622c0-on-9133e23.log`, `logs/redgreen-6fc7b5a-on-9133e23.log`

---

## Claim 26: Test name "launch: a .git git accepts but the tools do not (HEAD over 255 bytes) refuses the launch (exit 1)" and cc-gitdir.sh:22-23 "Stricter than git in one way: a regular HEAD over 255 bytes is invalid (git reads only the first 255 ...)"

**Location:** `test/cc-isolated-functions.bats` (test 156), `devcontainer-config/cc-gitdir.sh:22-23`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5 accepting a `ref: refs/heads/<b>\n` + 300-byte HEAD and gitdir_valid rejecting it; does not establish other git versions.

`logs/bighead.log` (2026-09-28T03:37:25Z, cwd scratchpad) shows `git ls-remote --upload-pack='git-upload-pack --strict' big/w/.git` rc 0 (git accepts), `gitdir_valid` rc 1, and `gitdir_head_kind` `invalid`. The test passes at the tip.

**Evidence:** `devcontainer-config/cc-gitdir.sh:33-35`, `logs/bighead.log`, `logs/bats-tip.log`

---

## Claims Requiring Attention

### Incorrect
- **Claim 7b** (`devcontainer-config/cc-isolated.sh:23-26`, also the 6fc7b5a message): "1 at launch, where the same failure at exit is 4" is wrong for an invalid `.git` or a root that looks like a repository. At exit those are findings and the launcher exits **3** (the suite asserts it: "a session that makes .git invalid ends the launcher with exit 3"). Limit the "4 at exit" to the unreadable case, as the guide's Exit-status paragraph already does. This text is printed by `--help`.

### Stale
- (none)

### Mostly Accurate
- **Claim 2** (`cc-exit-scan.sh:86-87`, guide `:320-323`): the tool list omits `grep`, added at `:768` (it reads only the snapshot string).
- **Claim 6** (commit 9133e23): the cross-check has 22 fixtures, not 21. All 22 agree with `git-upload-pack --strict`.
- **Claim 11** (`cc-push.sh:57-58`, guide `:272-273`): `git --version` (`:189`) runs without the `-c` pair. It is inert, so the precise wording is "every git command that reads a repository".
- **Claim 19** (guide `:273-279`): "covers each refusal above" still excludes the socket and device refusals (carried from r3 Claim 13; text unchanged in range).

### Unverifiable
- **Claim 12b** (`cc-push.sh:63-67`, guide `:237-241`): whether 2.39.4 … 2.45.1 are the May 2024 fixed releases needs git's release notes, and the sandbox has no egress. The text says as much, and the code implements the stated list (Claim 12a).

---

## Goal-Alignment Note

- **Success criterion (verbatim):** A code-fact-check report saved at /workspace/docs/reviews/q076-code-fact-check-report-confirm.md in the skill's schema, with a Goal-Alignment Note.
- **Answered:**
  - The report is saved at that path with `**Commit:** bfe8292…` and `**Replication:** k=1 (confirming pass)` in the header.
  - All prior Incorrect claims are closed: r1 Claim 1 (Claim 14, red at f511cc1 and green at tip), r1 Claim 9 (Claims 1 and 7), r3 Claim 7 (Claim 3). Several prior Mostly-accurate items are also fixed (r1 C5, r2 C10/C12, r3 C1/C3b/C5/C8/C10/C11).
  - Every commit-message count reproduces at its own commit (352, 355, 12, 44, 159).
  - Every red-before-green claim reproduces, including the sparse-file hang.
  - The f511cc1 extraction is byte for byte, as stated.
  - `gitdir_valid` agrees with `git-upload-pack --strict` on every fixture, but there are 22, not 21.
  - The `--strict` no-fallback behavior was confirmed by a direct probe.
  - No commit in range states "388". At the tip the named suites total 371 + 12 = 383.
- **Out of scope:**
  - No real docker daemon or devcontainer runtime (container checks only via the suite's stubs).
  - Git versions other than 2.39.5.
  - An adversarial enumeration to prove the "Known routes" list complete.
  - External verification of the git release list.
  - r3 Claim 17 (ws_fingerprint's git calls in the checkout, near the moved comment at `cc-exit-scan.sh:90-91`) was not rechecked. That text moved byte for byte and was not in this range's changes.
- **Escalate:** Claim 7b only. It is a one-line wording fix in cc-isolated.sh's header, which `--help` prints: a script reading the documented codes would expect 4 where the launcher exits 3. It does not affect safety (both are non-zero, and the scan reports the finding by name). Nothing found in this pass blocks the merge.
