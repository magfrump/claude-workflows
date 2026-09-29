# Code Fact-Check Report

**Repository:** claude-workflows (worktree `/workspace/.claude/worktrees/agent-ab977469478643bc3`, branch q093-cc-push-self-commondir)
**Scope:** `git diff 2c8163f..b9f6cc4` (review pass 2, confirming): `devcontainer-config/cc-push.sh`, `docs/working/plan-q093-cc-push-self-commondir.md`, `test/cc-push.bats`, and the commit message of b9f6cc4. Earlier branch commits (dfe4c0d..2c8163f) are context only.
**Commit:** b9f6cc4
**Replication:** k=1 (loop pass, decision 031)
**Checked:** 2026-09-28
**Total claims checked:** 13
**Summary:** 12 verified, 1 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Hallucination pattern log (`docs/reviews/hallucination-patterns.md`) read first; no claim in this diff matches a logged pattern (the logged patterns are corpus statistics and test-count tallies; b9f6cc4's message makes no test-count claim).

Execution provenance: all runs 2026-09-28, local time -07:00, git 2.39.5, `LC_ALL=C` (the en_US locale is broken in this sandbox). Captured output is kept in the session scratchpad, `/tmp/claude-1000/-workspace/0d5be710-0e7c-4a4f-8e65-09d2e983c2f5/scratchpad/p2/` (abbreviated `$P` below), not `docs/reviews/execution-logs/`, because this pass may write only its report. The worktree was left unmodified (mutations ran on copies under `$P/m0`, `$P/m1`, `$P/base`).

| Log | Command | cwd | Exit | Time |
|---|---|---|---|---|
| `$P/bats.log` | `LC_ALL=C bats test/cc-push.bats` | worktree root | 0 (47/47 ok) | 18:15:04 |
| `$P/mut.log`, `$P/mut-{base,m1,m0}.log` | `bash $P/mut.sh` (copies repo files, applies mutations, runs `bats -f 'every other commondir'` per copy) | `$P/{base,m1,m0}` | script 0; base 0, m1 1, m0 0 | 18:15:45 |
| `$P/mut-m1-debug.log` | m1 copy with an `echo $status $output >&3` after the symlink run, `bats -f 'every other commondir'` | `$P/m1` | 1 | ~18:20 |
| `$P/toctou.log` | `LC_ALL=C bash $P/toctou.sh` | worktree root | 0 | 18:16:43 |
| `$P/spell.log` | `LC_ALL=C bash $P/spell.sh` | worktree root | 0 | 18:17:11 |
| `$P/b13.log` | `LC_ALL=C bash $P/b13.sh` | worktree root | 0 | 18:17:33 |
| `$P/b5.log` | `LC_ALL=C bash $P/b5.sh` | worktree root | 0 | 18:18:04 |

---

## Claim 1: "The type test comes before any read, so a FIFO is never opened (and the read is timed, should one be swapped in between)"

**Location:** `devcontainer-config/cc-push.sh:267-270`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers commondir_is_self's own read of a FIFO swapped in after the `-L`/`-f` test (bounded at ~5 s, then refused); does not establish anything about git's later read of the same file (the B11 residual, unchanged) or a FIFO whose writer supplies `.`.

The whole function (`devcontainer-config/cc-push.sh:271-279`) was read:

```bash
# devcontainer-config/cc-push.sh:273-276
  [ ! -L "$c" ] && [ -f "$c" ] || return 1
  s="$(stat -c %s -- "$c" 2>/dev/null)" || return 1
  case "$s" in 1|2) ;; *) return 1 ;; esac
  hex="$(timeout 5 head -c 2 -- "$c" 2>/dev/null | od -An -tx1)" || return 1
```

`toctou.sh` extracts the function verbatim from the shipped file, and overrides `stat` with a function that replaces the regular file with a writer-less FIFO and prints `1`, so the swap lands after the type test and the size check. Result: `RESULT: refused rc=1`, `elapsed: 5s`. The same `head` without `timeout` was still blocked when an outer `timeout 8` killed it (rc 124).

**Evidence:** `devcontainer-config/cc-push.sh:262-279`, `$P/toctou.log`, `$P/toctou.sh`

---

## Claim 2: (brief) "`timeout` is resolvable under cc-push's safe_path, and pipefail / `|| return 1` still fail closed on timeout (exit 124)"

**Location:** `devcontainer-config/cc-push.sh:276`
**Type:** Error-handling / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the fail-closed path in this sandbox (pipefail active, `/usr/bin/timeout` on an absolute PATH entry); does not establish `timeout`'s presence on the user's host beyond it being coreutils, like the `head`/`od`/`stat` the function already needs, and already used unconditionally at `:228`.

`set -euo pipefail` is set at `devcontainer-config/cc-push.sh:112` and `main` runs in `( set -e; main "$@" )` (`:519`), a subshell that inherits pipefail. `safe_path` (`:121-134`) drops only relative entries and entries inside the checkout (`case "$p" in /*) ;; *) continue ;; esac`), so `/usr/bin` stays. `command -v timeout` → `/usr/bin/timeout`. In `toctou.log`, the raw pipeline under pipefail gave `pipeline rc under pipefail: 124, hex=''`, and the function returned 1 via `|| return 1`. Prior art: `timeout 20 docker ps ...` at `devcontainer-config/cc-push.sh:228`.

**Evidence:** `devcontainer-config/cc-push.sh:112`, `devcontainer-config/cc-push.sh:121-135`, `devcontainer-config/cc-push.sh:228`, `devcontainer-config/cc-push.sh:276`, `devcontainer-config/cc-push.sh:519`, `$P/toctou.log`

---

## Claim 3: "it can name another repository, which git would read. (The only one accepted is a regular file holding exactly `.`, or `.` and a newline: .git itself.)"

**Location:** `devcontainer-config/cc-push.sh:295`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the accepted set (`2e`, `2e0a`, regular non-symlink file) and that both name .git itself in git 2.39.5; does not establish other git versions' parsing.

`[ "$hex" = 2e ] || [ "$hex" = 2e0a ]` (`devcontainer-config/cc-push.sh:278`) after `[ ! -L "$c" ] && [ -f "$c" ]` (`:273`). bats test 14 (accept `.` and `.\n`, push goes ahead) and test 15 (every other form refused with `commondir exists`) pass (`bats.log`). `spell.log`: git resolves both `.` (`bytes=[2e]`) and `.\n` (`bytes=[2e0a]`) to the gitdir (`=> SELF`), and `..` elsewhere (here: no repository), which supports "can name another repository".

**Evidence:** `devcontainer-config/cc-push.sh:271-279`, `devcontainer-config/cc-push.sh:293-296`, `test/cc-push.bats:267-311`, `$P/bats.log`, `$P/spell.log`

---

## Claim 4: "stays, with a note naming the one accepted form (as shipped: "it can name another repository … The only one accepted is a regular file holding exactly `.`, or `.` and a newline")"

**Location:** `docs/working/plan-q093-cc-push-self-commondir.md:50-53`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the quoted fragments matching the shipped die text; does not establish the plan's "one accepted form" wording beyond the quote (the quote itself names two byte strings, as the code does).

The shipped text: `die "$g/commondir exists (a linked worktree's layout): it can name another repository, which git would read. (The only one accepted is a regular file holding exactly \`.\`, or \`.\` and a newline: .git itself.) $run_main"` (`devcontainer-config/cc-push.sh:295`). Both quoted fragments appear verbatim; the ellipsis covers `, which git would read. (`.

**Evidence:** `docs/working/plan-q093-cc-push-self-commondir.md:50-53`, `devcontainer-config/cc-push.sh:295`

---

## Claim 5: B1 "tests for `..` and the absolute path (new), `../../elsewhere` (the existing http-alternates/commondir test)"

**Location:** `docs/working/plan-q093-cc-push-self-commondir.md:63`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the existence of the three named tests; does not establish that an absolute path git reads as *elsewhere* is tested; only the gitdir's own absolute path is.

`..` and `"$T/co/.git"` are in the loop at `test/cc-push.bats:288`, and `echo "../../elsewhere" > "$T/co/.git/commondir"` is in the pre-existing test at `test/cc-push.bats:255` (unchanged since dfe4c0d; `git diff --stat dfe4c0d HEAD` shows only additions to the bats file in the Q-093 block). But the B1 family is "bytes git reads as elsewhere", and the absolute path the test writes is the gitdir itself, which git reads as self (`spell.log`: `ABS ... => SELF`); that test is B10's. An absolute path to another repository is refused by the same hex compare but is not tested. Precise version: "tests for `..`, `../../elsewhere` (existing); the absolute-path test (B10) uses the gitdir's own path".

**Evidence:** `docs/working/plan-q093-cc-push-self-commondir.md:63`, `test/cc-push.bats:249-259`, `test/cc-push.bats:284-293`, `$P/spell.log`

---

## Claim 6: B5 "git resolves a relative commondir against the gitdir, not the link's directory, so this is defence in depth; the test uses a 1-byte link target so only the `-L` test refuses it, mutation-checked"

**Location:** `docs/working/plan-q093-cc-push-self-commondir.md:67`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5's resolution of a symlinked commondir with relative content, and the mutation sensitivity of the symlink case in test 15; does not establish that cc-push would push if the `-L` test were dropped (the later `find -P` scan still refuses it, see Claim 12).

`b5.log`: `.git/commondir` is a symlink to `far/sub/cd` holding `.`: `git rev-parse --git-common-dir` prints the gitdir. With the target changed to `other.git` (a bare repo that exists next to the target): `fatal: not a git repository`, so the content was resolved against the gitdir, not the target's directory. Mutation (`mut.log`): dropping `[ ! -L "$c" ] &&` from `:273` makes test 15 fail at `test/cc-push.bats:309` (m1 rc=1); unmutated copy passes (base rc=0).

**Evidence:** `docs/working/plan-q093-cc-push-self-commondir.md:67`, `devcontainer-config/cc-push.sh:273`, `test/cc-push.bats:304-310`, `$P/b5.log`, `$P/mut.log`, `$P/mut-m1.log`, `$P/mut-base.log`

---

## Claim 7: B11 "cc-push's own read of the file is bounded (`timeout 5 head -c 2`), so a FIFO swapped in after the type test cannot hang it"

**Location:** `docs/working/plan-q093-cc-push-self-commondir.md:73`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claims 1-2 (the helper's read only); does not establish that the config/config.worktree greps (`devcontainer-config/cc-push.sh:316-328`) are bounded, which they are not; the plan does not claim so and the commit message names it (Claim 13).

See Claim 1: `RESULT: refused rc=1`, `elapsed: 5s` (`toctou.log`) against `hex="$(timeout 5 head -c 2 -- "$c" 2>/dev/null | od -An -tx1)" || return 1` (`devcontainer-config/cc-push.sh:276`).

**Evidence:** `docs/working/plan-q093-cc-push-self-commondir.md:73`, `devcontainer-config/cc-push.sh:276`, `$P/toctou.log`

---

## Claim 8: B12 "`looks_like_gitdir` still refuses a root `commondir` that is a regular file (or a link to one), exactly as before"

**Location:** `docs/working/plan-q093-cc-push-self-commondir.md:74`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers looks_like_gitdir's commondir test and its call site; does not establish that a root commondir that is a directory, FIFO or dangling link is refused (it is not, by this test, and the wording correctly excludes those).

```bash
# devcontainer-config/cc-gitdir.sh:98-101
looks_like_gitdir() {
  local d="$1"
  { { [ -e "$d/HEAD" ] || [ -L "$d/HEAD" ]; } && [ -d "$d/objects" ]; } || [ -f "$d/commondir" ]
}
```

`[ -f ]` follows symlinks, so it is true for a regular file or a link to one. Called at `devcontainer-config/cc-push.sh:333` (`if looks_like_gitdir "$co"; then die ...`). "Exactly as before": `cc-gitdir.sh` is not in `git diff --stat dfe4c0d HEAD` (paraphrased — no quote available because the claim is about absence of changes: the stat lists nine files and cc-gitdir.sh is not among them).

**Evidence:** `devcontainer-config/cc-gitdir.sh:94-101`, `devcontainer-config/cc-push.sh:333-335`

---

## Claim 9: B13 "Verified after review (git 2.39.5, scratch repo with a linked worktree and `extensions.worktreeConfig=true`, `uploadpack.hideRefs` set per worktree): upload-pack --strict's ref advertisement, the `config.worktree` values read and HEAD are identical with commondir absent, `.` and `.\n`"

**Location:** `docs/working/plan-q093-cc-push-self-commondir.md:75`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5, protocol v0 ref advertisement from `upload-pack --strict` on both the main gitdir and the linked worktree's gitdir, per-worktree `uploadpack.hideRefs`, and HEAD, with main `.git/commondir` absent / `2e` / `2e0a`; does not establish protocol v2 `ls-refs`, other git versions, or the full fetch (pack) phase.

Reproduced independently (`b13.sh`): main repo with branches main/a/b/c, `git worktree add ../wt b`, `extensions.worktreeConfig true`, `git config --worktree uploadpack.hideRefs refs/heads/a` in main and `refs/heads/c` in wt. The experiment is discriminating: main's advertisement omits `refs/heads/a` and the wt gitdir's omits `refs/heads/c` (`b13.log`), so both config.worktree files are in effect. For each commondir state the script captured main's upload-pack advertisement, `config --show-scope` (`worktree	refs/heads/a`), main HEAD (`refs/heads/main`, same sha), wt config (`refs/heads/c`), wt HEAD (`refs/heads/b`) and the wt gitdir's advertisement. `diff` of the three outputs: `absent == '.'`, `absent == '.\n'`.

**Evidence:** `docs/working/plan-q093-cc-push-self-commondir.md:75`, `$P/b13.sh`, `$P/b13.log`, `$P/b13-absent.out`, `$P/b13-2e.out`, `$P/b13-2e0a.out`

---

## Claim 10: Step 3 "refuse `..`, `./`, ` .`, `.\n\n`, `.\r\n`, `.\0`, `.x`, the gitdir's absolute path, empty, a directory, a FIFO (under `timeout`), a symlink to a file holding `.`"

**Location:** `docs/working/plan-q093-cc-push-self-commondir.md:91-93`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers one-to-one correspondence between the listed cases and test 15; does not establish that `../../elsewhere`, dropped from this list, is untested (it is, at `test/cc-push.bats:255`, as B1 says).

```bash
# test/cc-push.bats:288
  for bytes in '..' './' ' .' '.\n\n' '.\r\n' '.\0' '.x' "$T/co/.git"; do
```

followed by `: > "$c"` (empty, `:294`), `mkdir "$c"` (directory, `:297`), `mkfifo "$c"` then `run timeout 30` (`:301-302`), and `ln -s d "$c"` (`:307`) (excerpt ends :288; enclosing test `test/cc-push.bats:284-311` — read). All pass (`bats.log`, test 15).

**Evidence:** `docs/working/plan-q093-cc-push-self-commondir.md:91-93`, `test/cc-push.bats:284-311`, `$P/bats.log`

---

## Claim 11: "Of the spellings refused below, git reads some as elsewhere or as no repository (`..`, ` .`, `.x`) and some as .git itself too (`./`, `.\n\n`, `.\r\n`, `.\0`, the absolute path)"

**Location:** `test/cc-push.bats:263-266`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5's reading of each listed byte string in a scratch repo with an ordinary checkout root; does not establish which of `..`'s two outcomes applies when the root holds a planted repository (it would then be "elsewhere"; the comment's "elsewhere or no repository" covers both).

`spell.log` (`git rev-parse --git-common-dir` resolved with `pwd -P`, plus `git rev-parse HEAD`): `..` (`2e2e`), ` .` (`202e`), `.x` (`2e78`) → `fatal: not a git repository` (NOT-SELF); `./` (`2e2f`), `.\n\n` (`2e0a0a`), `.\r\n` (`2e0d0a`), `.\0` (`2e00`) and the gitdir's absolute path → common dir resolves to the gitdir, HEAD readable (SELF). Every listed spelling falls in the group the comment names.

**Evidence:** `test/cc-push.bats:262-266`, `$P/spell.sh`, `$P/spell.log`

---

## Claim 12: "Its target name is 1 byte, so the link's own size (stat without -L) would pass the size check: only the helper's -L test refuses it."

**Location:** `test/cc-push.bats:304-306`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which test inside commondir_is_self refuses the link, and that test 15 detects the loss of `-L`; does not establish that cc-push as a whole would accept the link without `-L`: it still exits 1, via the `find -P` symlink scan, and the test catches the mutation only through its `commondir exists` message assertion.

`ln -s d "$c"` (`test/cc-push.bats:307`) makes a 1-byte link; `stat -c %s` (no `-L`, `devcontainer-config/cc-push.sh:274`) reports the link's length, so `case "$s" in 1|2)` passes, `head` follows the link and reads `.` → `2e`. With `-L` dropped (m1), `mut-m1-debug.log`: `M1STATUS=1 M1OUT=ERROR: .../co/.git/commondir is a symlink, FIFO, socket or device inside the checkout's .git`, so the test fails at `:309` on the message, not the status.

**Evidence:** `test/cc-push.bats:304-310`, `devcontainer-config/cc-push.sh:271-279`, `devcontainer-config/cc-push.sh:302-312`, `$P/mut-m1.log`, `$P/mut-m1-debug.log`

---

## Claim 13: commit b9f6cc4 message: "checked by mutation (dropping -L fails it). The old long-target link was refused by the size check anyway"; "the same unbounded window on the config greps is pre-existing"

**Location:** commit `b9f6cc4` (message body)
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the mutation result, the old test's insensitivity to it, and the greps' presence at the base commit; does not establish the other bullets, which are checked as Claims 1-12 (all consistent with the diff), nor the "Live-verified: no" line, which is a self-report.

`mut.sh`: m1 (drop `-L`) → test 15 rc=1; m0 (drop `-L` and restore the pre-b9f6cc4 line `rm "$c"; printf . > "$T/dot"; ln -s "$T/dot" "$c"`) → rc=0, i.e. the old long-target link was still refused with `commondir exists` without `-L`: its link size is the length of the absolute path, over 2, so `case "$s" in 1|2)` refused it. The config greps predate the branch: `git show dfe4c0d:devcontainer-config/cc-push.sh` has `for f in config config.worktree; do` at `:294` and both `LC_ALL=C grep -Eiq` lines at `:296` and `:302`. The other bullets (timeout read, refusal wording, test comment, plan rows B1/B5/B11/B12/B13, Step 3) describe edits present in `git diff 2c8163f..b9f6cc4`.

**Evidence:** `test/cc-push.bats:307`, `devcontainer-config/cc-push.sh:273-275`, `$P/mut.sh`, `$P/mut.log`, `$P/mut-m0.log`, `$P/mut-m1.log`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 5** (`docs/working/plan-q093-cc-push-self-commondir.md:63`): B1 counts "the absolute path" test as coverage for "bytes git reads as elsewhere", but the tested absolute path is the gitdir itself (git reads it as self, B10); no elsewhere-pointing absolute path is tested. Tighten the row or attribute that test to B10.

### Unverifiable
(none)
