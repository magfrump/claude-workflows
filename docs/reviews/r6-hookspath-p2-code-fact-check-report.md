Commit: e1d7d912

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-2026-10-25-exit-scan-r6-hookspath (branch `fix/exit-scan-r6-hookspath`)
**Scope:** `git diff cf15f4f9..HEAD` (commit e1d7d912): `devcontainer-config/cc-exit-scan.sh`, `guides/cc-isolated-usage.md`, `docs/working/research-2026-10-25-exit-scan-r6-hookspath.md`, `test/cc-isolated-functions.bats`, and e1d7d912's commit message. cf15f4f9 is context only; it was checked in pass 1 (`docs/reviews/r6-hookspath-p1-code-fact-check-report.md`).
**Checked:** 2026-10-25
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 17
**Summary:** 14 verified, 3 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Hallucination pattern log (`docs/reviews/hallucination-patterns.md`) read first. No claim in scope matches a logged pattern: every symbol named (`gitdir_common`, `_snap_first_line`, `_snap_gitdir`, override-log row 135, the guide's `pushDefault` bullet) exists.

Execution environment: git 2.39.5, bash 5.2, bats, uid 1000. Every probe ran from a scratch dir with `GIT_CONFIG_NOSYSTEM=1`, `GIT_CONFIG_GLOBAL=<scratch file>` and `LC_ALL=` set, under `timeout`. Captured output is in the scratch dir `S=/tmp/claude-1000/-workspace/89c2ddf7-2b6b-41d6-b07b-ae5871fb9429/scratchpad/2026-10-25-exit-scan-r6-hookspath/fc-p2/` (`bats-r6-head.log`, `bats-r6-oldscan-newtest.log`, `probe1.log`–`probe4.log`, scripts `probe1.sh`–`probe4.sh`). The brief allowed edits to this report only, so nothing was copied to `docs/reviews/execution-logs/`. All probes ran in the foreground and exited; no process was left running (checked with `ps`).

---

## Claim 1: "a relative core.hooksPath set in an include named by an absolute path still passed the scan in a linked worktree (rc=0, hook ran). The abs/~ skip now applies to the hooksPath value only; the bats case covers an absolute include.path."

**Location:** commit e1d7d912 message, paragraph 1
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers an absolute `include.path` in the common config, with a hook planted in a standard linked worktree: cf15f4f9's scan misses it and e1d7d912's catches it. Does not establish the `~/` include form (not tested; `_snap_path` expands it to `$HOME`) or an `includeIf.*.path` with an absolute target. The `rc=0, hook ran` part was established in pass 1. Here the old scan was shown only to fail the `status -eq 1` assertion.

The new code applies the skip inside the `core.hookspath` arm only, and every include recurses:

```bash
# devcontainer-config/cc-exit-scan.sh:674-683
    [ -n "$val" ] || continue
    case "$key" in
      core.hookspath)
        # An absolute or ~/ value names one dir for every tree: _snap_config walks it.
        # shellcheck disable=SC2088  # matching a literal "~/" in the value
        case "$val" in /*|"~/"*) ;; *) _snap_hooks "$wt/$val" || return 1 ;; esac ;;
      include.path|includeif.*.path)
        # Any include, absolute or not: its relative hooksPath still resolves in <wt>.
        _snap_tree_hooks "$(_snap_path "$val" "$(dirname -- "$f")")" "$wt" $((depth + 1)) || return 1 ;;
    esac
```
(excerpt ends :683; enclosing `_snap_tree_hooks()` continues to :685 — read)

The new bats block sets `git -C "$SCAN_WS" config include.path "$SCAN_WS/.git/inc.cfg"` and asserts `[ "$status" -eq 1 ]` (`test/cc-isolated-functions.bats:3168-3173`).

Executed:
- `cd <worktree> && LC_ALL= timeout 600 bats -f R6 test/cc-isolated-functions.bats`. Run at 2026-10-26T00:52:06Z, exit 0, `ok 1 exit scan R6: …`.
- e1d7d912's test file run against cf15f4f9's `devcontainer-config/` (both extracted with `git archive cf15f4f9` into `$S/old`). Command: `cd $S/old && LC_ALL= timeout 600 bats -f R6 test/cc-isolated-functions.bats`, run at 2026-10-26T00:52:16Z, exit 1, `not ok 1 … (in test file test/cc-isolated-functions.bats, line 3173) [ "$status" -eq 1 ]' failed`. Line 3173 is the absolute-include assertion. `CONFIG_SRC="$BATS_TEST_DIRNAME/../devcontainer-config"` (`test/cc-isolated-functions.bats:16`), so that run sourced the old scan.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:659-685`, `test/cc-isolated-functions.bats:3143-3178`, `$S/bats-r6-head.log`, `$S/bats-r6-oldscan-newtest.log`

---

## Claim 2: "_snap_entry_hooks reads the common dir through cc-gitdir.sh's gitdir_common (git's reading, CR/LF trimmed) instead of adding another raw commondir reader (override-log row 135); an unreadable or empty commondir fails the snapshot."

**Location:** commit e1d7d912 message, paragraph 2
**Type:** Behavioral / Error-handling / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers CRLF, 0-byte and mode-000 `commondir` in a linked worktree's private dir, and the row-135 reference. Does not establish failure for a `commondir` that holds only a newline. That file is not "empty" by size, the snapshot passes on it, and git then rejects the dir as "not a git repository", so it is harmless. An unreadable file fails through an earlier reader before `gitdir_common` is reached.

```bash
# devcontainer-config/cc-exit-scan.sh:693-697
_snap_entry_hooks() {
  local g="$1" wt="$2" c
  c="$(gitdir_common "$g")" || { _snap_fail 'cannot read the commondir file in %s' "$g"; return 1; }
  _snap_tree_hooks "$c/config" "$wt" && _snap_tree_hooks "$g/config.worktree" "$wt"
}
```

```bash
# devcontainer-config/cc-gitdir.sh:57-68
  if [ ! -e "$c" ] && [ ! -L "$c" ]; then printf '%s' "$d"; return 0; fi
  [ -f "$c" ] && [ -r "$c" ] || return 1
  s="$(stat -c %s -- "$c" 2>/dev/null)" || return 1
  [ "$s" -gt 0 ] && [ "$s" -le 4096 ] || return 1
  ...
      case "$line" in *$'\n'|*$'\r') line="${line%?}" ;; *) break ;; esac
  ...
  case "$line" in /*) printf '%s' "$line" ;; *) printf '%s/%s' "$d" "$line" ;; esac
```
(excerpt elides :61-63 and :66-67; enclosing `gitdir_common()` :55-69 — read)

Override-log row 135 is `docs/reviews/override-log.md:135`: "The scan reads `commondir`'s first line itself instead of via cc-gitdir.sh … fold into cc-gitdir.sh at the next scan change." The reference is accurate.

Executed with `probe2.sh`: `cd $S/p2 && LC_ALL= timeout 120 bash $S/probe2.sh $S/p2 <worktree>`, run at 2026-10-26T00:53:45Z, exit 0.
- **CRLF** `commondir` (`../..\r\n`) with `core.hooksPath .husky/_` in the common config: snapshot rc=0. Planting `<wt>/.husky/_/pre-commit` gives scan rc=1 with `+ hook …/.husky/_/pre-commit`. Git itself resolves the common dir to `ws/.git`.
- **0-byte**: snapshot rc=1, `cannot read the commondir file in …/worktrees/x` (the new message). Git: `fatal: failed to read …/commondir`. `probe3.sh` ran the same case against cf15f4f9's scan: `old snap rc=0`. This is a real behavior change.
- **mode 000**: snapshot rc=1, `cannot read …/commondir`. That message comes from an earlier reader (`_snap_fail 'cannot read %s'`, `cc-exit-scan.sh:193`), so the failure is reached before `gitdir_common`.
- **newline-only**: snapshot rc=0, and git reports `not a git repository`.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:693-697`, `devcontainer-config/cc-gitdir.sh:50-69`, `docs/reviews/override-log.md:135`, `$S/probe2.log`, `$S/probe3.log`

---

## Claim 3: "the R5/A15 bullet is dropped (that mechanism exists only on the held Q-168 branch; on main your own pushDefault names are not walked, the existing bullet)"

**Location:** commit e1d7d912 message, paragraph 3
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what main does with `remote.pushDefault`/`branch.*` in your own config (no arm, so nothing is queued) and that the guide bullet exists. Does not re-run pass 1's executed probe (`a15c/p.sh`, p1 report :608-617). That probe is relied on as recorded.

`_snap_host_config` has no names arm. Its only `case` arms are `url.*.insteadof|url.*.pushinsteadof`, `remote.*.url|remote.*.pushurl`, `core.hookspath`, `core.attributesfile` and `include.path|includeif.*.path` (paraphrased — no quote available because the claim is the absence of an arm across `devcontainer-config/cc-exit-scan.sh:615-640`). Names are queued only in the repo-config reader:

```bash
# devcontainer-config/cc-exit-scan.sh:509-513 (_snap_config)
      remote.pushdefault|branch.*.remote|branch.*.pushremote)
        ...
        _snap_names+=("$val")
        _snap_nbases+=("$base") ;;
```
(excerpt from `_snap_config()` :477-~560 — read through :520)

The guide still carries "a path-valued `pushRemote`/`pushDefault` in your own config" (`guides/cc-isolated-usage.md:453-454`), and the old R5/A15 bullet is gone from :460.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:477-520`, `devcontainer-config/cc-exit-scan.sh:604-645`, `guides/cc-isolated-usage.md:447-455`, `docs/reviews/r6-hookspath-p1-code-fact-check-report.md:596-617`

---

## Claim 4: "A relative core.hooksPath in repo config, set directly or through an include, is walked in each working tree that uses that config, every linked worktree and `.git` entry in the checkout included (_snap_entry_hooks)."

**Location:** `devcontainer-config/cc-exit-scan.sh:61-65`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers standard linked worktrees (bats: direct, relative include, absolute include) and a container-form `.git` (probe1 case A). Does not establish `.git` entries the embedded-repo find does not reach (existing guide routes), or the top-level tree, which `_snap_config` walks because the loop skips `$_snap_ws/.git`.

Each `.git` entry found under the checkout, other than the root's, gets the walk:

```bash
# devcontainer-config/cc-exit-scan.sh:877-886
    while LC_ALL=C IFS= read -r -d '' f; do
      [ "$f" != "$_snap_ws/.git" ] || continue
      _snap_dotgit "$f" || { rc=1; break; }
      g="$(_snap_dotgit_target "$f")" || { rc=1; break; }
      # A container-form .git: walk your config as it will apply after a repair.
      [ -n "$g" ] || g="$(_snap_container_target "$f")" || { rc=1; break; }
      [ -z "$g" ] || _snap_host_config "$g" "$f" "${f%/*}" || { rc=1; break; }
      # The repo's own relative hooksPath, as it applies in this working tree.
      [ -z "$g" ] || _snap_entry_hooks "$g" "${f%/*}" || { rc=1; break; }
    done < "$list"
```

Executed: the bats R6 case from Claim 1 passes (all three variants). In `probe1.sh` case A, a relative `core.hooksPath h` set in the git dir of a container-form `.git`, with a hook planted at `sub/h`, gives scan rc=1 with `+ hook …/sub/h/pre-commit`. Run: `cd $S/p1 && LC_ALL= timeout 120 bash $S/probe1.sh $S/p1 <worktree>` at 2026-10-26T00:53:19Z, exit 0.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:877-886`, `devcontainer-config/cc-exit-scan.sh:659-697`, `$S/bats-r6-head.log`, `$S/probe1.log`

---

## Claim 5: "It records only what _snap_hooks records (the dir and its hooks), not the configs it reads: those are recorded wherever _snap_config reaches them, and where it does not (a container-form .git's git dir, a commondir outside the checkout), a changed hooksPath still shows as a hooks dir the launch snapshot did not walk."

**Location:** `devcontainer-config/cc-exit-scan.sh:653-657`
**Type:** Behavioral / Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the walk records (hooks only), that a container-form git dir's config is not recorded, and a changed *relative* hooksPath in that config. Does not hold for a hooksPath changed to an *absolute* value in such an unrecorded config. Neither walk sees that one, so it does not "show".

`_snap_tree_hooks` writes no `C`/`F` record of its own. Its only recording call is `_snap_hooks "$wt/$val"` (`:679`, quoted in Claim 1).

Executed with `probe1.sh`. The fixture is an embedded `sub/` whose `.git` reads `gitdir: $GIT_EXIT_SCAN_CONTAINER_WS/gd`, with the git dir at `<ws>/gd`, inside the checkout but outside `.git/`.
- case 0, an unrelated key `foo.bar` written to `gd/config`: scan rc=0. The config is not recorded, as the comment says.
- case A, relative `core.hooksPath h` plus a hook in `sub/h`: rc=1, `+ hooksdir …/sub/h` and `+ hook …/sub/h/pre-commit`. This is the "shows as a hooks dir" path.
- case B, `core.hooksPath <ws>/abs-h` (absolute, inside the checkout) plus `abs-h/pre-commit`: **rc=0, no finding**.

The precise version is "a changed *relative* hooksPath still shows …". An absolute one in a config `_snap_config` never reads is unseen. The guide's container-form bullet ("not the git dir itself", `guides/cc-isolated-usage.md:486-495`) already lists that route.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:648-685`, `$S/probe1.log`, `$S/probe1.sh`

---

## Claim 6: "An absolute or ~/ value names one dir for every tree: _snap_config walks it."

**Location:** `devcontainer-config/cc-exit-scan.sh:677`
**Type:** Behavioral / Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** True for every config `_snap_config` reads, since its `core.hookspath` arm walks any value through `_snap_path`. Does not hold for configs it never reads, which are the ones Claim 5's comment names (a container-form `.git`'s git dir outside `.git/`). There the skipped value is walked by nothing.

```bash
# devcontainer-config/cc-exit-scan.sh:497-500 (_snap_config)
      core.hookspath)
        ...
        [ -z "$val" ] || _snap_hooks "$(_snap_path "$val" "$base")" || return 1 ;;
```
(excerpt from `_snap_config()` — read)

`probe1.sh` case B (Claim 5) is the counterexample: an absolute value in `gd/config` gives scan rc=0 with a planted hook. The precise version is "_snap_config walks it wherever it reads this config".

**Evidence:** `devcontainer-config/cc-exit-scan.sh:494-500`, `devcontainer-config/cc-exit-scan.sh:677-679`, `$S/probe1.log`

---

## Claim 7: "Any include, absolute or not: its relative hooksPath still resolves in <wt>."

**Location:** `devcontainer-config/cc-exit-scan.sh:681`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `include.path` (relative and absolute, executed) and `includeIf.*.path` (same arm, conditions not evaluated, static). Does not establish includes past depth 10 (`[ "$depth" -le 10 ] || return 0`, `:661`, git's limit) or `~/` includes (static only).

The code is the `include.path|includeif.*.path` arm quoted in Claim 1 (`:680-682`). It recurses with the same `$wt`, so a nested `core.hooksPath` resolves as `$wt/$val`. Git 2.39 resolves a relative hooksPath against the working tree whatever file set it: the bats absolute-include variant ends with host git running `<wt>/.inc-hooks/pre-commit` (`test/cc-isolated-functions.bats:3176-3177`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:659-685`, `test/cc-isolated-functions.bats:3166-3177`, `$S/bats-r6-head.log`

---

## Claim 8: "its config.worktree (git reads that only under extensions.worktreeConfig; reading it always is an over-walk). The common dir comes from cc-gitdir.sh's gitdir_common, git's reading of the file; one it cannot read safely fails the snapshot."

**Location:** `devcontainer-config/cc-exit-scan.sh:687-692`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5's gating of `config.worktree` and that `_snap_entry_hooks` reads it unconditionally. The `gitdir_common` half has the same scope as Claim 2.

`_snap_entry_hooks` calls `_snap_tree_hooks "$g/config.worktree" "$wt"` with no extension check (`:696`, quoted in Claim 2).

Executed (`probe2.sh`, last case). With `core.hooksPath wth` in `<private dir>/config.worktree`, `git -C <wt> config core.hooksPath` printed `''` with the extension off and `'wth'` after `extensions.worktreeConfig true`.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:687-697`, `$S/probe2.log`

---

## Claim 9: "R5 | out, not reachable on main | … on main your own `pushDefault` names are never walked at all (pass-1 fact-check, executed), which the guide's existing … bullet already lists." / "A15 | … like R5 it hides a name only through Q-168's counting, so on main it is covered by the same existing bullet."

**Location:** `docs/working/research-2026-10-25-exit-scan-r6-hookspath.md:30-31`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers main's lack of a names arm in `_snap_host_config` and the pass-1 executed record. Does not re-execute pass 1's probe, or verify the Q-168 branch's counting at 75d08a94.

The evidence is the same as Claim 3. The pass-1 report records the executed probe: "The outcome is the same without any include, so the gap is the existing bullet 'a path-valued `pushRemote`/`pushDefault` in your own config'" (`docs/reviews/r6-hookspath-p1-code-fact-check-report.md:617`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:604-645`, `docs/reviews/r6-hookspath-p1-code-fact-check-report.md:606-617`, `guides/cc-isolated-usage.md:453-454`

---

## Claim 10: "Note that the scan's own `.git`/`commondir` readers on main strip no CR (`cc-gitdir.sh`'s `gitdir_common` does, and this change uses it)"

**Location:** `docs/working/research-2026-10-25-exit-scan-r6-hookspath.md:52-54`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every `_snap_first_line` reader of `.git`/`commondir`/`gitdir` in `cc-exit-scan.sh` (`:143, :153, :706, :723, :767, :1113`). Does not cover cc-push.sh's `commondir_is_self`.

```bash
# devcontainer-config/cc-exit-scan.sh:236-237 (_snap_first_line)
  { LC_ALL=C IFS= read -r line < "$1"; } 2>/dev/null || true
  printf '%s' "$line"
```
(excerpt ends :237; enclosing `_snap_first_line()` :228-238 — read)

`read -r` drops the newline but keeps a trailing `\r`. `gitdir_common` trims both (Claim 2).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:228-238`, `devcontainer-config/cc-gitdir.sh:64-66`

---

## Claim 11: "Covered: every include is followed, whatever form its path takes (conditions not evaluated: over-walk). Pass 1 found the first version skipped absolute and `~/` include paths (rc=0, hook ran); fixed, and tested for relative and absolute `include.path`."

**Location:** `docs/working/research-2026-10-25-exit-scan-r6-hookspath.md:118`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claims 1 and 7. The `~/` include is fixed by the same arm but not tested.

See Claim 1 for the code and both executed runs.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:680-682`, `test/cc-isolated-functions.bats:3156-3173`, `$S/bats-r6-head.log`, `$S/bats-r6-oldscan-newtest.log`

---

## Claim 12: "Covered for this walk: it reads the common dir through `gitdir_common` (git's reading; an unreadable or empty file fails the snapshot), not a fifth raw reader (override-log row 135). `_snap_gitdir`'s own reader is unchanged: T1's unit."

**Location:** `docs/working/research-2026-10-25-exit-scan-r6-hookspath.md:122`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the CR case for this walk (executed), the failure cases (Claim 2), and that `_snap_gitdir`'s reader is unchanged (`:767` still `_snap_first_line`). The word "fifth" is not established exactly. Counting commondir readers across the host tools, `scan_git_dirs`, `_snap_gitdir`, `gitdir_common` and cc-push's `commondir_is_self` make four, so cf15f4f9's would be the fifth. But `gitdir_common` is not "raw", so the count depends on the reading. Medium confidence for that reason only.

See Claim 2 (CRLF case: scan rc=1 on the plant). `_snap_gitdir` still has `line="$(_snap_first_line "$real/commondir")" || return 1` (`devcontainer-config/cc-exit-scan.sh:767`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:153`, `devcontainer-config/cc-exit-scan.sh:767`, `devcontainer-config/cc-gitdir.sh:55`, `devcontainer-config/cc-push.sh:347`, `$S/probe2.log`

---

## Claim 13: "Cost: one extra `git config` fork per config file read per `.git` entry (the common config, plus each include). 100 embedded repos: old 2.83 s / 2.87 s, new 2.77 s / 2.81 s (noise), so the guide's timing is unchanged."

**Location:** `docs/working/research-2026-10-25-exit-scan-r6-hookspath.md:127-129`
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the fork count from the code. The parenthetical leaves out `config.worktree`, which is a further fork when the file exists. The timings were not re-measured for e1d7d912, and nothing here establishes that they were taken on e1d7d912's code.

`_snap_tree_hooks` forks one `git config --file "$f" --no-includes --null --list` per file it reads (`:666`). It returns early with no fork when the file is missing (`[ -f "$f" ] || return 0`, `:662`). `_snap_entry_hooks` calls it for `$c/config` and `$g/config.worktree` (`:696`), and each include recurses. The precise list is "the common config, `config.worktree` when present, plus each include". `gitdir_common` adds one `stat` fork, only when a `commondir` exists (`cc-gitdir.sh:57-59`), so embedded repos with no commondir add nothing there.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:659-697`, `devcontainer-config/cc-gitdir.sh:55-69`

---

## Claim 14: "A relative `core.hooksPath` in a repo's config (husky's `.husky/_`), set there or in a file it includes, is walked in every working tree that uses that config: the repo's own and each linked worktree or other `.git` entry in the checkout"

**Location:** `guides/cc-isolated-usage.md:337-342`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claim 4. The "repo's own" tree is walked by `_snap_config`'s `core.hookspath` arm with `base` from `_snap_worktree_of`, which was not re-probed here.

See Claim 4.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:877-886`, `$S/bats-r6-head.log`, `$S/probe1.log`

---

## Claim 15: "The boundary (Q-172 [2]): a route that needs only ordinary setup plus what a session can write in the checkout is one to close, and stays listed here until it is; a route that needs some unusual state present at launch stays here by design."

**Location:** `guides/cc-isolated-usage.md:416-419`
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers agreement with Q-172 [2] as recorded and with the research doc's reading of "planted". Also covers that the open in-scope routes (A14, R3's remote half, A16) are now listed. Does not establish that the "ordinary setup" gloss is the author's own wording. Q-172 says "need no state planted before launch", and the gloss comes from research §1 (S5/S10 reading) and the 2026-10-23 note.

Q-172 [2]: "Close only routes that need no state planted before launch; list the rest as known routes; the guide says to push with cc-push" (`docs/working/questions-archive.md:4209`). The Q-173 note reads it as "R6 … needs only state a session can write in the checkout, so it is inside the boundary" (`docs/working/questions.md:162`). Research §1 defines "planted" as "a value no ordinary workflow produces" (`docs/working/research-2026-10-25-exit-scan-r6-hookspath.md:16-17`). The listing half holds, per Claim 16.

**Evidence:** `docs/working/questions-archive.md:4196-4215`, `docs/working/questions.md:162`, `docs/working/research-2026-10-25-exit-scan-r6-hookspath.md:12-21`

---

## Claim 16: "Relative remotes and receive hooks resolved against one base (not closed yet). A relative local remote, undefined remote name or legacy URL in a repo's config is walked only in that repo's main working tree, but a push from a linked worktree inside the checkout goes to `<worktree>/<path>` …; in an embedded repo made with `--separate-git-dir`, such paths are resolved inside its git dir rather than its working tree; and receive hooks under a relative `core.hooksPath` run from the pushed repo's git dir (`<repo>/.git/<path>`, `git push .` included), which is not walked (Q-168 rubric A14, R3, A16)."

**Location:** `guides/cc-isolated-usage.md:460-469`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers all three mechanisms end to end for a relative `remote.origin.url`, and for `git push .` into a non-bare repo. Does not execute the undefined-remote-name or legacy-URL variants of A14. Those were checked statically: they resolve through the same single base, `_snap_worktree_of`.

The scan resolves relative paths against one base per config:

```bash
# devcontainer-config/cc-exit-scan.sh:346-357
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

A separate git dir not named `.git`, with no `core.worktree`, falls to `printf '%s' "$gd"`, which is the git dir.

Executed with `probe4.sh`: `cd $S/p4 && LC_ALL= timeout 180 bash $S/probe4.sh $S/p4 <worktree>` at 2026-10-26T00:55:23Z, exit 0.
- **A14**: `origin = ../up.git`, linked worktree `ws/wts/x`, session plants a bare `ws/wts/up.git` with `pre-receive`. Scan rc=0, then `git -C ws/wts/x push origin wx` ran the hook.
- **R3**: `sub/` made with `--separate-git-dir ws/sgd`, remote `./r.git`, session plants `sub/r.git`. Scan rc=0, then `git -C sub push` ran the hook.
- **A16**: `core.hooksPath h`, session plants `ws/.git/h/pre-receive`. Scan rc=0, then `git -C ws push . HEAD:refs/heads/n` ran the hook.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:344-357`, `devcontainer-config/cc-exit-scan.sh:477-482`, `$S/probe4.log`, `$S/probe4.sh`

---

## Claim 17: "the scan maps it to `<checkout>/<path>` and walks only your own config there and that git dir's relative `core.hooksPath` in the worktree, not the git dir itself (and nothing at all when the line ends in a CR …)"

**Location:** `guides/cc-isolated-usage.md:486-491`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a mapped git dir outside `.git/`: the relative hooksPath is walked, other config changes are not recorded, and an absolute hooksPath is not seen, which is consistent with "not the git dir itself". "That git dir's" config here means its common dir's config plus its `config.worktree`. Does not execute the CR case. Statically, `_snap_container_target` keeps the `\r`, the `[ -d "$g" ]` test fails, and `g` stays empty, so neither walk runs. A mapped git dir under `.git/worktrees/` is walked by the fixed layout anyway, so "not the git dir itself" describes only the other case. That wording predates e1d7d912.

`[ -z "$g" ] || _snap_entry_hooks "$g" "${f%/*}"` runs on the mapped `g` (`devcontainer-config/cc-exit-scan.sh:882-885`). `_snap_container_target` reads the line raw (`:723`) and returns nothing unless `[ -d "$g" ]` (`:726`). probe1 cases 0, A and B are as in Claim 5.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:720-728`, `devcontainer-config/cc-exit-scan.sh:877-886`, `$S/probe1.log`

---

## Claims Requiring Attention

### Incorrect
- None.

### Stale
- None.

### Mostly Accurate
- **Claim 5** (`devcontainer-config/cc-exit-scan.sh:656-657`): "a changed hooksPath still shows as a hooks dir the launch snapshot did not walk" holds only for a *relative* value. An absolute hooksPath written to a container-form git dir's unrecorded config passes the scan (probe1 case B, rc=0). Fix: say "a changed relative hooksPath".
- **Claim 6** (`devcontainer-config/cc-exit-scan.sh:677`): "_snap_config walks it" holds only for configs `_snap_config` reads. Fix: "wherever _snap_config reads this config" (same counterexample).
- **Claim 13** (`docs/working/research-2026-10-25-exit-scan-r6-hookspath.md:127-128`): the fork list leaves out `config.worktree` when present. The timings were not re-measured for e1d7d912.

### Unverifiable
- None.

---

## Goal-Alignment Note

The goal is to close Q-168 R6 (a relative repo `core.hooksPath` in every linked worktree) and fix pass 1's findings. e1d7d912 does that.
- The absolute-include gap is closed and tested, and the old scan fails the new assertion.
- The common dir comes from `gitdir_common`, so a CRLF `commondir` now works and a 0-byte one now fails closed, which it did not on cf15f4f9.
- The guide no longer implies A14, R3's remote half or A16 are closed. All three were reproduced end to end here (scan rc=0, hook ran) and are correctly listed as open.
- R5/A15 are correctly recorded as not reachable on main.

The one residue is Claims 5 and 6: the new comments overstate coverage for an absolute hooksPath in a container-form git dir's config. The gap is not new. The guide's container-form route ("not the git dir itself") already discloses it, so no new route needs listing, only the comment wording. A newline-only `commondir` does not fail the snapshot, but git then rejects the dir, so no hook can run from it.

Escalations: none. No hallucination-pattern entries: there are no Incorrect verdicts.
