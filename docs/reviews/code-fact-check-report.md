Commit: 9ae6e46

# Code Fact-Check Report

**Commit:** 9ae6e46
**Replication:** k=1 (final confirmation pass)
**Repository:** claude-workflows, worktree `/workspace/.claude/wt-copyinstall`, branch `ans/copy-install`
**Scope:** `712c626..9ae6e46`, focused on the 9 fix commits `44c10f5..9ae6e46` that answer `docs/reviews/code-fact-check-report-pass2-44c10f5.md`: `devcontainer-config/install.sh` (all 808 lines read), `README.md`, `docs/decisions/037-bare-host-copy-install.md`, `docs/working/plan-copy-install-bare-host.md`, the fix-commit messages, `test/install-host.bats` (T41–T49), `test/cc-isolated-functions.bats`
**Checked:** 2026-09-23 (execution timestamps are UTC, 2026-09-24T01:42Z–01:47Z)
**Total claims checked:** 21
**Summary:** 12 verified, 3 mostly accurate, 3 stale, 3 incorrect, 0 unverifiable

Execution provenance. `$CFC` = `/tmp/claude-1000/-workspace/d516ca2c-2abb-4732-a34a-041aa98280c8/scratchpad/cfc-final3`. Each probe is a script `$CFC/<probe>.sh` that sources `$CFC/lib.sh`. The harness pins HOME, CLAUDE_HOME_DIR, CLAUDE_DEVC_CONFIG_DIR, CLAUDE_DEVC_BIN_DIR, TMPDIR and GIT_CONFIG_GLOBAL under `$CFC/run/<probe>/`, unsets CLAUDECODE and CLAUDE_CONFIG_DIR, and runs a copy of the 9ae6e46 `install.sh` in a throwaway git repo whose payload is committed. The y path runs under `script -qec … /dev/null`. No real `~/.claude`, `~/.config` or `~/.local` was touched. Every probe was run as `bash $CFC/<probe>.sh > $CFC/logs/<probe>.txt`, cwd `/workspace`, and exited 0. The logs are in the session scratchpad and are not committed. `setlocale: LC_ALL` warnings are environment noise.

The hallucination pattern log (`docs/reviews/hallucination-patterns.md`) was read first. No claim below matches a logged pattern or is a fabrication, so nothing was appended.

Rubric rows the fixes closed (claims 3, 4, 6, 9, 11b, 14, 17, 22, 24, 27, 2 of pass 2) are re-checked only where the fix itself is the subject. They are not re-reported as open unless a residue is shown below.

---

## Claim 1: "An entry `~/.claude` doesn't have yet is listed file by file, with its content shown only when it is 200 lines or fewer."

**Location:** `README.md:23-24` (also `devcontainer-config/install.sh:3-4`, `:562-567`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers a new entry's file listing, the content shown for an entry of at most 200 lines, and the omission message above 200. It does not establish that the limit bounds screen output: the count is `wc -l` over the concatenated files, so one very long line counts as one line.

The code counts and branches as documented:

```bash
# devcontainer-config/install.sh:580-586
      lines="$(find "$stage/$name" -type f -exec cat {} + | wc -l)"
      if [ "$lines" -le "$ADD_MAX_LINES" ]; then
        review_diff "$view" "$stage" "$name" || true   # $view/$name is absent: all "+" lines
      else
        for src in "${CLAUDE_HOME_SRC[@]}"; do [ "$(basename "$src")" = "$name" ] && break; done
        echo "    (content not shown: $lines lines, over the $ADD_MAX_LINES-line limit for a new entry;" \
             "it is $src at commit ${STAGED_COMMIT:0:12})" | vis
```
(excerpt ends :586; enclosing `install_claude_home()` continues to :745 — read)

On a first install (`pA`), each one-line entry printed its file list and then `+global instructions`, `+skill a` and so on. A 250-line CLAUDE.md (`pF` F4) printed `(content not shown: 250 lines, over the 200-line limit for a new entry; it is global-instructions/CLAUDE.md at commit f62077b53b42)`.

**Evidence:** `devcontainer-config/install.sh:562-590`, `README.md:23-24`; commands `bash $CFC/pA.sh` (2026-09-24T01:42:51Z, exit 0) and `bash $CFC/pF.sh` (01:45:44Z, exit 0); output `$CFC/logs/pA.txt`, `$CFC/logs/pF.txt`

---

## Claim 2: "Both targets install only **committed** content (the devcontainer config's files as well as those seven): uncommitted changes under those paths are listed as NOT included"

**Location:** `README.md:25-28` (also `devcontainer-config/install.sh:45-47`, `:279-283`; commit 942d5de)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers unstaged, staged-only and untracked changes under both targets' payload paths, a detached HEAD and a depth-1 shallow clone. It does not establish content fidelity for a submodule path (Claim 11). It does not cover `install.sh` itself, which runs from the tree, as its header says.

Target 1 now stages every PAYLOAD item from `STAGED_COMMIT` into a private temp dir:

```bash
# devcontainer-config/install.sh:288-293
  DC_TMP="$(mktemp -d "${TMPDIR:-/tmp}/cw-devc-stage.XXXXXX")"
  local stage="$DC_TMP/config"
  assemble "$stage/claude-home" "${dc_paths[@]}"
  extract_commit "$STAGED_COMMIT" "$stage" "${dc_paths[@]}"
  rm -rf "$SRC/claude-home"
  cp -Rp "$stage/claude-home" "$SRC/claude-home"
```

`pF` F1 made an unstaged edit to `devcontainer.json`, a staged-only edit to `egress/base.txt`, an untracked `egress/new.txt` and an untracked `skills/a/extra.md`, then ran `--yes`. All four were listed under `WARNING: … They are NOT included`, and none was installed: `installed devcontainer.json: stub devcontainer.json`, and `base.txt` held only `api.anthropic.com`. A detached HEAD (F5) installed with `commit=` equal to `git rev-parse HEAD`. A shallow clone (F6) installed with exit 0.

**Evidence:** `devcontainer-config/install.sh:278-293`, `:180-210`; `bash $CFC/pF.sh` (2026-09-24T01:45:44Z, exit 0), output `$CFC/logs/pF.txt`

---

## Claim 3: "That stops accidental runs, not a determined agent (a pty wrapper and unsetting `CLAUDECODE` get past it)"

**Location:** `README.md:28-30`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the pass-2 claim 2 wording fix: both measures are needed and together they reach the y prompt from inside this Claude Code session. It does not establish anything about a sandbox that denies `~/.claude` writes.

The two checks are `[ -n "${CLAUDECODE:-}" ]` (`devcontainer-config/install.sh:476`) and `[ ! -t 0 ]` (`:480`). Every y-path probe in this pass ran from inside a Claude Code session as `env -u CLAUDECODE script -qec "$INSTALL" /dev/null` (`$CFC/lib.sh`, `run_pty`), and it reached `Install these files into …? [y/N]` and installed (`pA`).

**Evidence:** `devcontainer-config/install.sh:472-483`, `README.md:28-30`; `bash $CFC/pA.sh` (2026-09-24T01:42:51Z, exit 0), output `$CFC/logs/pA.txt`

---

## Claim 4: "The backups of the last 3 installs are kept (the current run's is never removed)." / "this run's backup is never a candidate … a directory without that stamp … is never removed."

**Location:** `README.md:40-41` (also `devcontainer-config/install.sh:41-42`, `:715-736`; `docs/decisions/037-bare-host-copy-install.md:35`; commit 354b3fd)
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the prune loop with ordinary names, which works, and with a backup-dir name containing a TAB, which breaks both "never" guarantees. It does not establish how likely such a name is. It needs a same-uid write into `.claude-workflows-backup/`, and anyone who can do that could also delete the backup directly.

The candidate list is tab-separated, and names are filtered for newlines only:

```bash
# devcontainer-config/install.sh:728-736
      for d in "$bkroot"/*/; do
        d="${d%/}"
        case "$d" in *$'\n'*) continue ;; esac
        if [ "$d" = "$backup" ] || [ -L "$d" ] || [ -L "$d/.install-stamp" ]; then continue; fi
        [ -f "$d/.install-stamp" ] || continue
        e="$(sed -n 's/^installed_epoch=\([0-9][0-9]*\)$/\1/p' "$d/.install-stamp")"
        [ -n "$e" ] || continue
        printf '%s\t%s\n' "$e" "${d##*/}"
      done | LC_ALL=C sort -t "$(printf '\t')" -k1,1nr -k2,2r | tail -n +3 | cut -f2)
```

A stamped dir named `A<TAB>B` is emitted as `e<TAB>A<TAB>B`. `cut -f2` yields `A`, and `rm -rf "$bkroot/A"` removes a different directory.
- `pB`: an unstamped dir `zz` was deleted through a stamped low-epoch dir `zz<TAB>victim` (before: `zz$`, `zz^Ivictim$`; after: only `zz^Ivictim$`). The ordinary cases behaved correctly: this run's backup was kept, as were the two highest-epoch earlier ones, even though their names (`29990101…`) sort after it.
- `pB2`: stamped dirs named `<UTC stamp for each of the next 60 s><TAB>x` were planted. This run's backup was deleted right after it was announced: `CURRENT BACKUP …/20260924T014338Z IS GONE`, with `Backups: … (61 older removed)`. The planted dirs themselves survive, so the "removed" count is also wrong.

Fix shape: skip names containing a tab (as newlines are skipped), or carry names NUL-delimited.

**Evidence:** `devcontainer-config/install.sh:715-737`; `bash $CFC/pB.sh` (2026-09-24T01:43:18Z, exit 0) and `bash $CFC/pB2.sh` (01:43:38Z, exit 0), output `$CFC/logs/pB.txt`, `$CFC/logs/pB2.txt`

---

## Claim 5: "A destination path holding a newline or other control character is refused." / has_ctrl: "C0 (newline and tab included), DEL, or a UTF-8-encoded C1"

**Location:** `devcontainer-config/install.sh:48` (also `:747-754`, `:779-791`; commit 780d045)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the literal strings in DEST, BIN_DIR and the host destination, from all four variables and HOME, including under `--yes`. It does not establish that the resolved path is control-free, because a relative destination inherits `$PWD` (Claim 6). A raw single byte 0x80–0x9f is accepted, as commit 780d045's note says.

```bash
# devcontainer-config/install.sh:752-753
  [ "$(printf '%s' "$1" | LC_ALL=C tr -d '\001-\037\177')" != "$1" ] && return 0
  printf '%s' "$1" | LC_ALL=C grep -q $'\xc2[\x80-\x9f]'
```

In `pC`, each of the following exited 1 with a `%q`-quoted `ERROR: a destination contains a newline or other control character`: a newline in CLAUDE_HOME_DIR, a tab in CLAUDE_DEVC_CONFIG_DIR, DEL in CLAUDE_DEVC_BIN_DIR, `c2 9b` in CLAUDE_HOME_DIR, a trailing newline alone, and a newline in CLAUDE_CONFIG_DIR. Each run had `--yes` and nothing was installed (`devc-exists=no`). An em dash and a raw 0x9b passed the check.

**Evidence:** `devcontainer-config/install.sh:747-754`, `:779-791`; `bash $CFC/pC.sh` (2026-09-24T01:43:52Z, exit 0), output `$CFC/logs/pC.txt`

---

## Claim 6: "`read` splits only the first line; main refuses any destination holding a newline or other control character before this runs (claim 11b)."

**Location:** `devcontainer-config/install.sh:373-374`
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers a relative destination resolved against a `$PWD` that contains a newline. This is a residue of pass-2 claim 11b. It does not establish how likely the trigger is: the human must run from a cwd whose name holds a newline, and the prompt shows the relative `Destination:` line.

`resolve_phys` prefixes `$PWD` to a relative path before the first-line split, and `main` checks only the destination string:

```bash
# devcontainer-config/install.sh:376-378
  local p="$1" cur="/" comp parts
  case "$p" in /*) ;; *) p="$PWD/$p" ;; esac
  IFS=/ read -ra parts <<< "$p"
```

In `pG`, the cwd was `$'…/run/pG/nl\n'` and CLAUDE_HOME_DIR was `../repo/inside` (no control character, so `has_ctrl` passes it). The guard resolved only `…/nl`. The run printed `Installed into ../repo/inside.`, and the repo's `git status` then showed `?? inside/`, which held all seven entries and the manifest. Controls: the absolute path to the same place, and `../repo/inside3` from a normal cwd, were both refused with `resolves inside the repo checkout`.

Fix shape: also refuse control characters in `$PWD` when the destination is relative, or resolve relative paths with `cd -P` before `read`.

**Evidence:** `devcontainer-config/install.sh:369-395`, `:495`; `bash $CFC/pG.sh` (2026-09-24T01:46:32Z, exit 0), output `$CFC/logs/pG.txt`

---

## Claim 7: vis "makes control bytes visible (all but newline and tab)"; raw C1 bytes are escaped "only outside a well-formed UTF-8 sequence"

**Location:** `devcontainer-config/install.sh:98-113` (commit 1592d6b)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the fix for pass-2 claim 6: raw 0x9b and UTF-8 `c2 9b` become `?`, and an em dash survives. It does not establish the two absolute words: NUL passes through, and the "well-formed" pattern also keeps malformed sequences.

```perl
# devcontainer-config/install.sh:109-111
    s/[\x01-\x08\x0b\x0c\x0e-\x1a\x1c-\x1f\x7f]/?/g;
    s/\xc2[\x80-\x9f]/?/g;
    s/([\xc2-\xdf][\x80-\xbf]|[\xe0-\xef][\x80-\xbf]{2}|[\xf0-\xf4][\x80-\xbf]{3})|[\x80-\x9f]/defined $1 ? $1 : "?"/ge;
```

In `pD`, `61 9b 62` became `61 3f 62`, `c2 9b` became `?`, ESC became `^[`, CR became `^M`, a tab was kept, and `e2 80 94` was kept. The following passed through unchanged:
- `00` (NUL; the class starts at `\x01`)
- the overlong `e0 80 9b`, the surrogate `ed a0 9b`, and the above-U+10FFFF `f4 90 80 9b`, all malformed UTF-8 that keep a raw 0x9b

The precise wording is: "all but NUL, newline and tab", and "outside a byte pattern shaped like UTF-8". The practical effect is small. Paths cannot hold NUL, a file with NUL diffs as binary, and a UTF-8 terminal renders the malformed sequences as replacement characters.

**Evidence:** `devcontainer-config/install.sh:98-113`; `bash $CFC/pD.sh` (2026-09-24T01:44:46Z, exit 0), output `$CFC/logs/pD.txt`

---

## Claim 8: "Modes are the commit's … tar.umask=022 … tar -p keeps them" and mode_diff prints "a MODE line for each regular file present in both trees whose permission bits differ … Returns 1 when any mode differs."

**Location:** `devcontainer-config/install.sh:146-150`, `:240-262` (commit b01aadb)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers extraction modes, the host MODE line, the installed mode and the no-op check after a mode-only commit. It does not establish mode reporting for directories or destination-only empty dirs, which the commit note excludes. On target 1, `chmod +x` on cc-isolated.sh and init-firewall.sh (`:336`) makes a MODE line appear on every run if either is committed 644. The fixture shows this: `init-firewall.sh: 755 -> 644`. The real repo commits both 100755, so it does not arise there.

In `pA`, a first install produced 644 for `hooks/h.sh` and CLAUDE.md, and 755 for `cc-isolated.sh` and `init-firewall.sh`. The fixture's hook stub was committed 644, so 644 is correct for it. After `chmod +x hooks/lib/x.sh` was committed, the host review printed only `MODE …/.claude/hooks/lib/x.sh: 644 -> 755`, the install ran, and `stat` showed 755. The next run printed `(none — the destination already matches the repo)` and `Nothing to install`.

**Evidence:** `devcontainer-config/install.sh:146-150`, `:240-262`, `:600`, `:646`; `bash $CFC/pA.sh` (2026-09-24T01:42:51Z, exit 0), output `$CFC/logs/pA.txt`; `git ls-files -s devcontainer-config` (`$CFC/q1.sh`)

---

## Claim 9: "Symlink refusal now also covers target 1's items" (942d5de note); "No symlinks (review R1)"

**Location:** `devcontainer-config/install.sh:158-167`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers a committed symlink under `devcontainer-config/egress` with `--yes`. It does not re-test R1 on the claude-home paths, which pass 2 verified and which this pass leaves unchanged.

`pF` F2 committed `egress/link.txt -> base.txt`. The `--yes` run printed `ERROR: the committed payload contains symlinks, which install.sh never installs:` followed by `egress/link.txt`, exited 1, and left the installed `egress/` unchanged (`before=[base.txt ] after=[base.txt ]`).

**Evidence:** `devcontainer-config/install.sh:158-167`; `bash $CFC/pF.sh` (2026-09-24T01:45:44Z, exit 0), output `$CFC/logs/pF.txt`

---

## Claim 10: "core.quotePath=true makes git C-quote every control or non-ASCII byte … so each entry is one line; the listing also goes through vis."

**Location:** `devcontainer-config/install.sh:188-199` (commit d91e8de)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the WARNING listing for both status calls. It does not establish anything about other git output.

```bash
# devcontainer-config/install.sh:193, :199
  dirty="$(git -C "$REPO_ROOT" -c core.quotePath=true status --porcelain --untracked-files=all -- "${CLAUDE_HOME_SRC[@]}" "$@")"
    printf '%s\n' "$dirty" | sed 's/^/           /' | vis
```

T48, which sets `core.quotePath=false` and a U+009B file name, fails on 44c10f5 and passes on 9ae6e46 (Claim 19). `pF` F1 shows the listing format.

**Evidence:** `devcontainer-config/install.sh:188-200`; `bash $CFC/redgreen.sh` (2026-09-24T01:44:18Z, exit 0), output `$CFC/logs/redgreen.txt`

---

## Claim 11: "dirty=no always: the payload is exactly the commit's content."

**Location:** `devcontainer-config/install.sh:203`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers ordinary blobs and a submodule gitlink. It does not re-test `export-ignore`/`export-subst` attributes, which pass 2 (claim 7) found with the same effect.

`extract_commit` checks existence with `git cat-file -e "$commit:$item"` (`:137`), which a gitlink satisfies, and `git archive` writes a submodule as an empty directory. In `pH`, `skills/sub` was committed as mode `160000`. The `--yes` run exited 0 with no ERROR or payload WARNING, and the installed `claude-home/skills/sub` was empty: `[]`. The precise version is: "exactly the commit's blobs; a submodule arrives empty and export attributes apply". Neither case arises in today's repo.

**Evidence:** `devcontainer-config/install.sh:124-168`, `:201-209`; `bash $CFC/pH.sh` (2026-09-24T01:47:21Z, exit 0), output `$CFC/logs/pH.txt`

---

## Claim 12: "the manifest's uncommitted_excluded still counts the seven only" (942d5de note)

**Location:** `devcontainer-config/install.sh:207`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the count when devcontainer-config and claude-home paths are both dirty. It does not establish that the count is meaningful in the target-1 manifest, where the WARNING lists more entries than it counts.

`home_dirty` is taken over `"${CLAUDE_HOME_SRC[@]}"` only (`:194`), and `:207` counts its lines. In `pF` F1, four entries were listed (three under `devcontainer-config/`, one under `skills/`), and the installed manifest read `uncommitted_excluded=1`.

**Evidence:** `devcontainer-config/install.sh:193-207`; `bash $CFC/pF.sh` (2026-09-24T01:45:44Z, exit 0), output `$CFC/logs/pF.txt`

---

## Claim 13: "this diff is the review gate, so a diff that could not be shown must never reach the [y/N] prompt."

**Location:** `devcontainer-config/install.sh:219-237` (with the perl `vis()` of commit 1592d6b)
**Type:** Error-handling
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the case where the display filter, not diff, fails. perl missing from PATH is the new failure mode introduced by the fix for pass-2 claim 6. It does not establish that any real host lacks perl: Debian, Ubuntu and WSL ship perl-base, and macOS ships perl. The `diff` exit >1 branch still aborts as written.

```bash
# devcontainer-config/install.sh:227-231
    rc=0
    diff -ruN "$dest/$item" "$src/$item" 2>&1 | vis || rc=${PIPESTATUS[0]}
    case "$rc" in
      0) ;;
      1) changed=1 ;;
```

Only diff's status is inspected. When `vis` fails, the diff text is lost, but diff's exit 1 still counts as "changed". In `pD`, the run used a PATH that had every tool except perl. The host review between the `===` rules consisted only of seven lines of `install.sh: line 107: perl: command not found`: the MODE, MOVE, ADD and diff lines were all gone. It still reached `Install these files into …? [y/N]`. A y would have installed content the human never saw. Fix shape: check `${PIPESTATUS[1]}` (and the other `| vis` sites), or test for perl in `main` before either target.

**Evidence:** `devcontainer-config/install.sh:106-113`, `:215-238`; `bash $CFC/pD.sh` (2026-09-24T01:44:46Z, exit 0), output `$CFC/logs/pD.txt`

---

## Claim 14: payload_hash covers "the provenance manifest's bytes … so its commit= stamp cannot be forged at the prompt either (fact-check claim 14)."

**Location:** `devcontainer-config/install.sh:397-415`, `:649-663`, `:705-710` (commit 979428a)
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers writes made to the host stage's manifest, a file mode, or file content while the host prompt waits. It does not cover a write landing between the hash (`:521`) and the review display, which commit 979428a's note discloses. It also does not cover target 1, which has no hash (Claim 18).

In `pE`, each tamper was applied at the host prompt: `sed … commit=FORGED` on the stage's `.manifest`, `chmod 755` on the stage's CLAUDE.md, and `echo evil >>` on a skill. Each printed `ERROR: stage changed after review … Nothing was replaced.` and exited 1. The installed manifest kept the real commit, the mode stayed 644, and `evil` was absent. No `.cw-new.*` or lock was left behind.

**Evidence:** `devcontainer-config/install.sh:397-421`, `:518-521`, `:640-663`; `bash $CFC/pE.sh` (2026-09-24T01:45:19Z, exit 0), output `$CFC/logs/pE.txt`

---

## Claim 15: "rm_new_copies replaces the four cleanup loops so every failure path also removes .cw-new.manifest" (979428a)

**Location:** `devcontainer-config/install.sh:417-421`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the four pre-rename failure paths and `host_rollback`. It does not establish cleanup after a `set -e` failure in the post-swap manifest append or rename (`:705-710`), where the seven entries are already installed.

```bash
# devcontainer-config/install.sh:418-421
rm_new_copies() {
  local n
  for n in "${CLAUDE_HOME_NAMES[@]}" manifest; do rm -rf "${1:?}/.cw-new.$n" 2>/dev/null || true; done
}
```

It is called at `:449` (`host_rollback`), `:654` (copy failure), `:659` (hash mismatch) and `:678` (backup mkdir failure). `pE` shows the hash-mismatch path leaves no `.cw-new.*` behind.

**Evidence:** `devcontainer-config/install.sh:417-421`, `:449`, `:653-663`, `:677-681`

---

## Claim 16a: "every non-interactive run (scripts, tests, --yes) is unchanged apart from a blank line and the skip line" / "every existing non-interactive devcontainer run is unchanged apart from two extra lines"

**Location:** `devcontainer-config/install.sh:466-468` (also `docs/decisions/037-bare-host-copy-install.md:33`)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** True for the host target's own contribution. As a statement about the run it is false, because target 1 changed under C1 and claim 4: `pF` F1 shows it installing committed content only and printing the NOT-included WARNING under `--yes`, and `pC` shows a control-character path now exiting 1. Pass-2 claim 13 carried over. 9ae6e46 updated the plan's Risks but not these two lines.

The skip lines return before any staging (`:472-483`). The precise wording is: "the host target adds only a blank line and the skip line; target 1's own output and behavior changed with committed-only staging (see Risks)".

**Evidence:** `devcontainer-config/install.sh:465-483`; `docs/decisions/037-bare-host-copy-install.md:33`; `$CFC/logs/pF.txt`, `$CFC/logs/pC.txt`

---

## Claim 16b: "The devcontainer target is unchanged for non-interactive runs. A plain run with closed stdin, or with `--yes`, still does exactly what it does today for the devcontainer config."

**Location:** `docs/working/plan-copy-install-bare-host.md:16`
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the plan's Revision section as a description of the current code. It does not dispute that the line was true when the user's answers were recorded.

After 942d5de and 780d045, a `--yes` run does not install an uncommitted `devcontainer.json` or egress edit (`pF` F1). It refuses committed symlinks (F2), refuses control-character destinations (`pC`), and needs a readable HEAD (`devcontainer-config/install.sh:117-121`). The line should point to the Risks entry that now records this.

**Evidence:** `docs/working/plan-copy-install-bare-host.md:16`, `:250`; `$CFC/logs/pF.txt`, `$CFC/logs/pC.txt`

---

## Claim 17: "**GNU tools assumed** by the review fixes: `find -printf`, `head -n -3`, GNU `sed` `\xHH`, `diff`/`sort -z`; and `perl` for `vis()`"

**Location:** `docs/working/plan-copy-install-bare-host.md:247`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the tool list against the 808-line install.sh. It does not audit macOS compatibility.

`head -n -3` was replaced by `tail -n +3` in the prune (`devcontainer-config/install.sh:736`). The sed `\xHH` expressions were replaced by perl (`:107-112`). Neither appears in the script (paraphrased — no quote available because the claim is about absence: install.sh's `sed` calls are only `:161`, `:164`, `:199`, `:522`, `:579`, `:733`, none with `\x`, and there is no `head`). The list omits GNU-only `xargs -r` (`:410`). The precise list is: `find -printf`, `sort -z`, `xargs -r`, `diff`, and `perl`.

**Evidence:** `docs/working/plan-copy-install-bare-host.md:247`; `devcontainer-config/install.sh:107-112`, `:161`, `:410`, `:736`

---

## Claim 18: "The devcontainer stage in `$SRC/claude-home` keeps its old exposure; its bless hashes the installed files."

**Location:** `docs/working/plan-copy-install-bare-host.md:254`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers where target 1 stages and whether a write made while its prompt waits is installed. It does not establish what the real `cc-isolated.sh --bless` hashes; the fixture uses a stub.

Since 942d5de, target 1 stages the whole payload in `$DC_TMP/config` (`devcontainer-config/install.sh:288-289`). `$SRC/claude-home` is only a mirror. The exposure itself remains and now covers every PAYLOAD item. In `pF` F3, `EVIL.example.com` was appended to the staged `egress/base.txt` while the target-1 prompt waited. After y, the installed `base.txt` ended with `EVIL.example.com`, and the stub printed `BLESS-STUB --bless`. The line should name `$DC_TMP` and say that the exposure covers the egress lists and the firewall.

**Evidence:** `docs/working/plan-copy-install-bare-host.md:254`; `devcontainer-config/install.sh:288-342`; `bash $CFC/pF.sh` (2026-09-24T01:45:44Z, exit 0), output `$CFC/logs/pF.txt`

---

## Claim 19: "one commit per fix, each test-first", with each fix commit stating that its test "failed before" (T41–T49)

**Location:** `docs/working/plan-copy-install-bare-host.md:231-239` (commit bodies 354b3fd, b01aadb, 979428a, 942d5de, 780d045, 1592d6b, d91e8de, 06aa56b)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each new test failing against 44c10f5's install.sh and passing against 9ae6e46's, using 9ae6e46's tests. It does not establish that each test fails for the specific defect named rather than for another pre-fix difference.

The 9ae6e46 tree was extracted with 44c10f5's `install.sh` substituted, and `bats --filter 'T4[1-9] '` printed `not ok` for all nine (T41–T49). The same tests with 9ae6e46's install.sh printed `ok` for all nine.

**Evidence:** `bash $CFC/redgreen.sh` (cwd `/workspace`, 2026-09-24T01:44:18Z, exit 0), output `$CFC/logs/redgreen.txt`

---

## Claim 20: Test counts: install-host, cc-isolated-functions, link-claude-home-wiring, hooks (brief: 40/40, 92/92, 14/14, 145/145)

**Location:** `test/install-host.bats:1`, `test/cc-isolated-functions.bats:1`, `test/link-claude-home-wiring.bats:1`, `test/hooks/`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers these four suites at 9ae6e46. It does not cover `scripts/run-tests.sh --fast`. No fix commit in `44c10f5..9ae6e46` states a count. The brief's 40/40 is pass 2's figure at 44c10f5; T41–T49 have been added since.

At 9ae6e46 (`bats --tap`, TMPDIR under `$CFC`, 01:42:38Z–01:43:51Z, every suite exit 0), the results were: install-host **49/49** (`grep -c '^@test'` = 49), cc-isolated-functions **92/92**, link-claude-home-wiring **14/14**, `test/hooks/*.bats` **145/145**, with 0 `not ok`.

**Evidence:** `bash $CFC/suites.sh` (cwd `/workspace`, exit 0); output `$CFC/logs/suites-meta.txt` and `$CFC/logs/{install-host,cc-isolated-functions,link-claude-home-wiring,hooks}.tap`

---

## Claims Requiring Attention

### Incorrect
- **Claim 4** (`devcontainer-config/install.sh:728-736`; README `:40-41`; help `:41-42`; 037 `:35`): a backup-dir name containing a TAB makes `cut -f2` target a different dir. This run's backup was deleted (`pB2`), and so was an unstamped dir (`pB`). Skip tab names, or go NUL-delimited.
- **Claim 6** (`devcontainer-config/install.sh:373-378`): a relative destination is resolved against `$PWD`, which is not checked for control characters. From a newline-named cwd, `../repo/inside` passed the guard and installed into the checkout (`pG`).
- **Claim 13** (`devcontainer-config/install.sh:227-231`): a failing `vis` (perl missing) drops the whole review, and the prompt is still reached with content counted as changed. Check `PIPESTATUS[1]`, or require perl before either target.

### Stale
- **Claim 16b** (`docs/working/plan-copy-install-bare-host.md:16`): "still does exactly what it does today" no longer holds for target 1.
- **Claim 17** (`docs/working/plan-copy-install-bare-host.md:247`): `head -n -3` and sed `\xHH` are gone and `xargs -r` is missing from the list.
- **Claim 18** (`docs/working/plan-copy-install-bare-host.md:254`): target 1 stages in `$DC_TMP`, not `$SRC/claude-home`. The unhashed exposure remains and covers the whole payload (`pF` F3).

### Mostly Accurate
- **Claim 7** (`devcontainer-config/install.sh:98-105`): NUL passes, and malformed UTF-8-shaped sequences keep raw 0x9b. Reword "all" and "well-formed".
- **Claim 11** (`devcontainer-config/install.sh:203`): a submodule path installs as an empty dir, silently.
- **Claim 16a** (`devcontainer-config/install.sh:466-468`; 037 `:33`): "unchanged" is true only of the host target's contribution. Target 1 changed under C1.

### Unverifiable
- None.

---

## Goal-Alignment Note

- **Success criterion (verbatim):** "a markdown report saved at the output path your task names, structured per your skill, beginning with a `Commit: 9ae6e46` line."
- **Answered:** All five brief items.
  - (1) C1 on both targets: unstaged, staged and untracked changes; manifest fields; detached HEAD; shallow clone; submodule.
  - (2)–(4) Every second-round fix was executed, and three regressions or residues were found: Claims 4, 6 and 13.
  - (5) Test counts were executed, and so were the "failed before" claims for T41–T49.
- **Out of scope:** R3/R4 lock and signal behavior, re-verified in pass 2 and unchanged by these commits except `rm_new_copies` (Claim 15). Also out of scope: `scripts/run-tests.sh --fast`; the real `cc-isolated.sh --bless`; macOS.
- **Escalate:** Before the live run (plan step 9), weigh Claim 13 (a review can be silently empty at the prompt if perl is absent; very unlikely on WSL) and Claim 18 (target 1's staged egress lists and firewall can be rewritten by the same uid while its prompt waits, and are then blessed). Claims 4 and 6 need a planted tab-named backup dir or a newline-named cwd. Both are narrow, but each refutes a guarantee stated in the docs.
