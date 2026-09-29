# Code Fact-Check Report

**Repository:** claude-workflows (worktree `/workspace/.claude/worktrees/agent-aaad54fc687b7548c`), branch `q094-exit-scan-worktree-layout`
**Scope:** `git diff 5a6d689..HEAD` (review-fix loop iteration 2, review artifacts excluded): `devcontainer-config/cc-exit-scan.sh`, `devcontainer-config/cc-isolated.sh` (EXIT STATUS), `guides/cc-isolated-usage.md`, `test/cc-isolated-functions.bats` (Q-094 section), `docs/working/plan-q094-exit-scan-worktree-layout.md`, commit message of c32a734, and the iteration-1 rubric `docs/reviews/code-review-rubric-2026-09-28-q094-exit-scan-worktree-layout.md`. Commits dfe4c0d..5a6d689 are context only; the whole branch was read before anything was called missing or stale.
**Commit:** c32a734
**Replication:** k=1 (loop pass, decision 031)
**Checked:** 2026-09-28
**Total claims checked:** 36
**Summary:** 26 verified, 3 mostly accurate, 5 stale, 1 incorrect, 1 unverifiable

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) read first. No claim here matches a logged pattern: the logged entries are measured values quoted from artifact sets that do not contain them. The closest is Claim 29's "about 35 ms". It does come from a real measurement (performance review, `perf/measure.sh 50`), so it is not that pattern.

Execution environment: git 2.39.5, bats at `/usr/bin/bats`, run from the worktree or from the scratchpad. All execution logs are in `/tmp/claude-1000/-workspace/0d5be710-0e7c-4a4f-8e65-09d2e983c2f5/scratchpad/fc2/`, abbreviated `$FC2` below. The caller said not to edit other files, so the logs are not under `docs/reviews/execution-logs/`. The host's `LC_ALL=en_US.UTF-8` locale is not installed, and under it bats test 1 fails on the `setlocale` warning (see Claim 36). All runs below therefore use `LC_ALL=C.UTF-8 LANG=C.UTF-8`.

- **E1** `LC_ALL=C.UTF-8 LANG=C.UTF-8 bats -f 'Q-094' test/cc-isolated-functions.bats` in the worktree. Exit 0 at 2026-09-29T02:09:42Z, 9/9 ok. Log: `$FC2/q094-bats.txt`.
- **E2** Mutation runs. `$FC2/mut.py` rewrote copies of `devcontainer-config/` in three ways: `mW` puts back the old `printf | grep -q $'^W\t'`, `mC` puts back the old `printf | grep -qxF` commondir check, and `mBoth` puts back both. `m0` is an unmodified copy. Each ran `LC_ALL=C.UTF-8 LANG=C.UTF-8 bats -f 'large snapshots under pipefail' <m>/test/cc-isolated-functions.bats` in `$FC2`, finishing at 2026-09-29T02:12:16Z:
  - m0: exit 0.
  - mW: exit 1. `[ "$status" -eq 1 ]` failed at :2285, so the W refusal failed open.
  - mC: exit 1. `[ "$status" -eq 0 ]` failed at :2283, so the note was lost.
  - mBoth: exit 1 at :2283.
  - Logs: `$FC2/m0.log`, `$FC2/mW.log`, `$FC2/mC.log`, `$FC2/mBoth.log`.
- **E3** `$FC2/re.sh` compares the new `[[ ]]` matches with the old greps on crafted inputs. Exit 0 at 2026-09-29T02:12. Log: `$FC2/re.log`.
- **E4** `$FC2/dot.bats` tests pushes to `.`, `file://.` and `./` from a linked worktree, and which values make W records. `GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1`. Exit 0 at 2026-09-29T02:12:58Z, plus a rerun with stderr shown. Logs: `$FC2/dot.log`, `$FC2/dot2.log`.
- **E5** `$FC2/wt.bats` tests a global relative hooksPath against the note (plus an absolute-path control) and takes a first timing. Exit 0 at 2026-09-29T02:13:56Z. Log: `$FC2/wt.log`.
- **E6** `$FC2/tm.bats` times `scan_std_worktrees` against 1 to 40 new worktrees. Exit 0 at 2026-09-29T02:14:51Z. Log: `$FC2/tm.log`.

---

## Claim 1: "When every difference is a linked worktree added in git's own layout … the scan prints one `note:` and returns 0 … In a linked worktree git takes config, hooks and info/attributes from the common dir, never the private one (tested on git 2.39.5; the one exception, config.worktree under extensions.worktreeConfig, refuses the note)."

**Location:** `devcontainer-config/cc-exit-scan.sh:75-80`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers two things. First, the note-and-0 path for added worktrees. Second, that the code refuses any `P/config.worktree`. Git's per-path common/private split is taken from git's `path.c` common_list and is consistent with the plan's E3–E6 experiments; it was not re-run here. This claim does not cover private-dir contents other than hooks, config, config.worktree and symlinks. Those include `P/rebase-merge/`, which is recorded as `sequencer` records by `_snap_gitdir` and so refuses the note through the record-kind filter.

The code refuses the exception it names:

```bash
# devcontainer-config/cc-exit-scan.sh:855
for k in hooks config config.worktree; do [ ! -e "$p/$k" ] && [ ! -L "$p/$k" ] || return 1; done
```

The note-and-0 path is `git_exit_scan` (`:932-935`): `if [ -z "$invalid" ] && note="$(scan_std_worktrees …)"; then printf '%s\n' "$note" | scan_vis >&2; return 0; fi`. E1 test 1 passes: status 0 and exactly one `note:` line.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:75-80`, `:855`, `:930-936`; `$FC2/q094-bats.txt`

---

## Claim 2: "A relative core.hooksPath, core.attributesFile or local remote in repo config would resolve in the new worktree's own tree, unscanned: those leave W records, and any W record refuses the note."

**Location:** `devcontainer-config/cc-exit-scan.sh:80-83`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the W-record rule for repo-config values. It does not describe the `.` exemption this iteration added.

A relative local remote no longer always leaves a W record. `.` is now exempt:

```bash
# devcontainer-config/cc-exit-scan.sh:355-357
  # "." is the repository git runs in (a local-tracking branch's remote): in a
  # linked worktree, the same common dir and hooks. Not a W record.
  [ "$p" = . ] || _snap_wrel remote "$p" "$p"
```

E4 counted the W records for each value:

- `remote.x.url=.`: 0
- `./`: 1
- `file://.`: 0
- `.git`: 1
- `./.git`: 1
- `branch.main.remote=.`: 0

The precise version: "…or a local remote other than `.` …". The guide (Claim 27) already says this. The "any W record refuses the note" half is exact (see Claim 7).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:80-83`, `:355-357`, `:290-294`; `$FC2/dot.log`

---

## Claim 3: "(Your own config's relative hooksPath is walked in each new worktree, so its records refuse the note as well.)"

**Location:** `devcontainer-config/cc-exit-scan.sh:83-84`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a global relative `core.hooksPath` when the new worktree's `.git` resolves on the host (the host form). The records that refuse the note are `hooksdir` F records, not W records: `_snap_host_config` calls no `_snap_wrel`. This claim does not cover the container form when `/workspace` does not resolve on the host; the plan's B14 row covers that case.

`_snap_host_config` walks the value against each working tree found by the embedded-repo search. This is the relevant branch of its key switch:

```bash
# devcontainer-config/cc-exit-scan.sh:514-516
      core.hookspath)
        t="$(_snap_path "$val" "$wt")"
        if _snap_inside_ws "$t"; then _snap_hooks "$t" || return 1; fi ;;
```

(excerpt ends :516; enclosing `_snap_host_config` continues to :531 — read)

In E5, with `GIT_CONFIG_GLOBAL` holding `hooksPath = .husky/_`, adding a worktree gave status 1 with `+ hooksdir …/.claude/worktrees/a/.husky/_  missing`, and the snapshot held 0 W records. The absolute-path control got status 0 and the note. The unmatched `+F hooksdir` record fails the final "every record used" loop (`:890`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:495-531`, `:690-701`, `:890`; `$FC2/wt.log`

---

## Claim 4: "a -f guard in _snap_worktree_of (a FIFO config hung the snapshot; makes 5a6d689's "-f before every read" true)"

**Location:** `devcontainer-config/cc-exit-scan.sh:328` (commit c32a734 body; rubric A1 "Fixed … so the claim now holds")
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers every file-content read in `cc-exit-scan.sh` and `cc-gitdir.sh` that a grep for `read`, `<`, `cat` and `config --file` finds. It does not cover a file swapped to a FIFO between the `-f` test and the read (TOCTOU). The FIFO hang itself was not re-run.

```bash
# devcontainer-config/cc-exit-scan.sh:328
  elif [ -f "$1" ] && v="$(cd / && git --no-pager config --file "$1" --no-includes --get core.worktree 2>/dev/null)"; then
```

The other reads are guarded as follows:

- `_snap_config` callers use `if [ -f … ]` (`:597`, `:579`).
- `_snap_host_config` recursion uses `if [ -f "$t" ]` (`:526`).
- `_snap_dotgit_target` uses `elif [ -f "$p" ]` (`:540`).
- The commondir read uses `if [ -f "$real/commondir" ]` (`:582`).
- Legacy remotes use `[ -f "$f" ] || continue` (`:602`).
- `_snap_file` hashes only under `if [ -f "$p" ]` (`:230`, `:243`).
- In cc-gitdir.sh: `[ -f "$h" ] && [ -r "$h" ]` (`cc-gitdir.sh:33`) and `[ -f "$c" ] && [ -r "$c" ]` (`cc-gitdir.sh:55`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:321-335`, `:230-245`, `:526`, `:540`, `:582`, `:602`; `devcontainer-config/cc-gitdir.sh:33`, `:55`

---

## Claim 5: "\".\" is the repository git runs in (a local-tracking branch's remote): in a linked worktree, the same common dir and hooks. Not a W record."

**Location:** `devcontainer-config/cc-exit-scan.sh:355-357` (also plan B29 at `docs/working/plan-q094-exit-scan-worktree-layout.md:101`, and rubric A5)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5 pushing to `.` from a linked worktree and from a subdirectory of it, and the W-record exemption. `file://.` is also exempt, because `p` becomes `.`. That is harmless: git rejects it ("fatal: no path specified"). `./`, `.git` and `./.git` still make W records, which gives false positives but no bypass. This claim does not cover git versions other than 2.39.5.

In E4, both the common `.git/hooks/pre-receive` and a `P/hooks/pre-receive` were installed. `git push . HEAD:refs/heads/t-1` from the worktree ran only the common one (`ran=…/r/.git/hooks`), and so did the same push from `wt/sub`. `branch.wtb.remote=.` made no W record (0). `git push file://. …` failed with `fatal: no path specified; see 'git help pull' for valid url syntax`. Walking `$base/.` still records the checkout's own git dir (`:358-367`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:344-368`; `$FC2/dot.log`, `$FC2/dot2.log`

---

## Claim 6: "…0 and one `note:` line when every difference is a linked worktree of the checkout's own common dir added in git's standard layout … Only dotgit, commondir-file and hooksdir records are added (a removal warns), and the exit snapshot has no W record …"

**Location:** `devcontainer-config/cc-exit-scan.sh:792-804`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the record-kind filter, the removal refusal and the "every record used" check. This claim does not cover the stacked removal unit, which does not exist (see Claim 18).

```bash
# devcontainer-config/cc-exit-scan.sh:827-836
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    case "$line" in
      +F$'\t'dotgit$'\t'*) left["$line"]=1; dot["${line%$'\t'*}"]="$line" ;;
      +F$'\t'commondir-file$'\t'*|+F$'\t'hooksdir$'\t'*) left["$line"]=1 ;;
      *) return 1 ;;
    esac
  done <<< "$diff"
  [ "${#left[@]}" -gt 0 ] || return 1
```

Any `-` line hits `*) return 1`. `:890` then checks that every kept record was used: `for rec in "${!left[@]}"; do [ -n "${used[$rec]:-}" ] || return 1; done`. E1 test 3 ("a worktree removed … still warns") passes with status 1 and `- commondir-file $STD_P/commondir`.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:792-895`; `$FC2/q094-bats.txt`

---

## Claim 7: "Pattern matches, not `printf | grep -q`: under the launcher's pipefail an early match SIGPIPEs printf, and the pipeline reads as \"no match\"." (and that the `[[ ]]` forms are equivalent to the old greps)

**Location:** `devcontainer-config/cc-exit-scan.sh:810-817`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers three things: the W check and the commondir check equal their greps on crafted inputs; the SIGPIPE failure mode as E2 reproduced it; and the launcher's `pipefail` (`cc-isolated.sh:66`, `set -euo pipefail`, which sources cc-exit-scan.sh at `:562`). This claim does not cover inputs with a NUL byte, which bash strings cannot hold anyway.

```bash
# devcontainer-config/cc-exit-scan.sh:812, :816-817
  [[ $'\n'"$after" != *$'\n'W$'\t'* ]] || return 1
  line="F"$'\t'"commondir"$'\t'"$(printf '%q' "$ws/.git")"$'\t'"$(printf '%q' "$common")"
  [[ $'\n'"$after"$'\n' == *$'\n'"$line"$'\n'* ]] || return 1
```

E3 compared the new matches with the old greps. They agreed on every case:

- W check: W on the first line, W mid-string, a `W` that is not at a line start, and a `W` with no tab.
- Commondir check: an exact line, a line mid-string, a prefix-only line, a suffix-only line, and `*` in the path. The quoted `"$line"` is literal inside `[[ == ]]`.

In E2, putting back either old grep makes the large-snapshot test fail. That proves the SIGPIPE mechanism on a real 40k-record input.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:810-817`; `devcontainer-config/cc-isolated.sh:66`, `:561-562`; `$FC2/re.log`, `$FC2/mW.log`, `$FC2/mC.log`

---

## Claim 8: "[ \"$(stat -c %s -- \"$p/gitdir\" …)\" -le 4097 ] || return 1   # PATH_MAX + \\n"

**Location:** `devcontainer-config/cc-exit-scan.sh:861`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the arithmetic (Linux `PATH_MAX` is 4096, plus 1 for the newline) and the fact that the cap comes before the read, failing closed when `stat` fails (`|| echo 99999`). `PATH_MAX` counts the terminating NUL, so the longest back-pointer git can write is 4095 + 1 = 4096 bytes. The cap is therefore one byte looser than needed. That does not matter for safety, but note that the neighbouring `gitdir_common` cap is 4096 (`cc-gitdir.sh:57`).

```bash
# devcontainer-config/cc-exit-scan.sh:859-862
    [ -f "$p/gitdir" ] && [ ! -L "$p/gitdir" ] || return 1
    [ "$(stat -c %s -- "$p/gitdir" 2>/dev/null || echo 99999)" -le 4097 ] || return 1   # PATH_MAX + \n
    line="$(_snap_first_line "$p/gitdir" 2>/dev/null)" || return 1
```

**Evidence:** `devcontainer-config/cc-exit-scan.sh:859-862`; `devcontainer-config/cc-gitdir.sh:57`

---

## Claim 9: "Its `.git` file: a new record, and the bytes git writes, then and now." (indexed `dot[]` lookup; commit: "indexed dotgit lookup (was O(n^2))")

**Location:** `devcontainer-config/cc-exit-scan.sh:872-874`
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the claim that the lookup key matches the key the old loop matched by prefix. Keys are `+F\tdotgit\t<%q path>`, and `%q` leaves no raw tab, so `${line%$'\t'*}` removes exactly the attributes field. The lookup is O(1) for each worktree. This claim does not cover the per-worktree process cost; see Claim 29.

```bash
# devcontainer-config/cc-exit-scan.sh:874
    dk="${dot["+F"$'\t'"dotgit"$'\t'"$(printf '%q' "$wt/.git")"]:-}"
```

The key is built at `:830`: `dot["${line%$'\t'*}"]="$line"`. E1 tests 1, 2 and 6 pass, and those tests depend on this lookup.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:830`, `:872-887`; `$FC2/q094-bats.txt`

---

## Claim 10: "git_exit_scan … 0 when nothing the tripwire records changed, or only standard linked worktrees did …; 1 … when anything else did; 2 when the exit state could not be read, or the snapshots differ but nothing renders."

**Location:** `devcontainer-config/cc-exit-scan.sh:897-901`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the return codes of `git_exit_scan`. This claim does not cover the launcher's mapping of those codes (Claim 15).

- `return 2` after a failed `git_exec_snapshot` (`:919`).
- `return 0` on the note path (`:935`).
- `if [ -z "$changes" ]; then echo "  the two snapshots differ …" >&2; return 2; fi` (`:941-944`).
- `return 1` after the warning (`:968`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:903-969`

---

## Claim 11: "A pattern match, not `printf | grep -q` (pipefail: see scan_std_worktrees)." — `re=$'(^|\n)F\tgitdir-valid\t[^\t\n]*\tinvalid'`

**Location:** `devcontainer-config/cc-exit-scan.sh:925-927`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the claim that the ERE matches the same snapshots as the old `grep -q $'^F\tgitdir-valid\t[^\t]*\tinvalid'` did line by line. This claim does not cover large-snapshot behaviour of this check under pipefail: no test exercises it (see Claim 21).

```bash
# devcontainer-config/cc-exit-scan.sh:926-927
  local re=$'(^|\n)F\tgitdir-valid\t[^\t\n]*\tinvalid'
  if [[ "$after" =~ $re ]]; then
```

In E3 the new form and the old grep agreed in all 7 cases:

- `invalid` on the first line or mid-string: both match.
- `valid`: neither matches.
- A record not at a line start: neither matches.
- A match that would need to span a newline: neither matches.
- `invalid` only inside the path: neither matches.
- `invalidX`: both match, the same as the old prefix match.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:922-929`; `$FC2/re.log`

---

## Claim 12: "Only linked worktrees added or removed in git's standard layout (STANDARD WORKTREES above): a note, not a finding."

**Location:** `devcontainer-config/cc-exit-scan.sh:931-932`
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers this call-site comment. This claim does not cover the header or the function comment; both were updated (Claims 1 and 6).

This iteration removed removal acceptance: `scan_std_worktrees` returns 1 on any `-` record (`:832`, `*) return 1 ;;`), and the header now says "added in git's own layout" (`:76`). The comment should say "added". E1 test 3 shows that a removal warns.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:931-932`, `:76`, `:827-834`

---

## Claim 13: "note: exit scan: only linked worktrees in git's standard layout changed (added: …). They take config and hooks from the checkout's own .git, so this is not a finding."

**Location:** `devcontainer-config/cc-exit-scan.sh:893-894`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the note text and the fact that `added` is never empty when it prints. Reaching `:893` requires at least one used `commondir-file` record. This claim does not cover the grammar when no worktree is listed, which cannot happen.

```bash
# devcontainer-config/cc-exit-scan.sh:893
  line="added: $(printf '%s\n' "${added[@]}" | LC_ALL=C sort | tr '\n' ' ')"
```

E1 test 1 matches the text `(added: agent-x).`.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:888-895`; `$FC2/q094-bats.txt`

---

## Claim 14: "the one exception … refuses the note" / "P has no hooks, config, config.worktree or symlink"

**Location:** `devcontainer-config/cc-exit-scan.sh:798-799`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the on-disk checks as refactored this iteration: the loop joined onto one line, and `find … && [ -z "$lnk" ] || return 1`. This claim does not cover symlinks created after the check (TOCTOU, plan B24).

```bash
# devcontainer-config/cc-exit-scan.sh:855-856
    for k in hooks config config.worktree; do [ ! -e "$p/$k" ] && [ ! -L "$p/$k" ] || return 1; done
    lnk="$(find -P "$p" -type l -print -quit 2>/dev/null)" && [ -z "$lnk" ] || return 1
```

`A && B || return 1` returns 1 when find fails or when it finds a link, so the refactor keeps the old behaviour. E1 test 5 ("hooks, config, links … warns") passes.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:852-856`; `$FC2/q094-bats.txt`

---

## Claim 15: "0  success; after a session: the exit scan found nothing (or only standard linked worktrees, with a note on stderr), and claude's own exit status is passed through"

**Location:** `devcontainer-config/cc-isolated.sh:20-23`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the launcher's mapping of `git_exit_scan` 0. This claim does not cover code 2 from the "differ but nothing renders" case, which maps to 4. That code 4 is described there as "could not read everything", which is close enough and not changed in this diff.

```bash
# devcontainer-config/cc-isolated.sh:745-750
  git_exit_scan "$ws" "$git_before" "$lws" || scan=$?
  trap - INT
  case "$scan" in
    0) exit "$rc" ;;
    1) exit 3 ;;   # the session planted something: never a clean exit
    *) exit 4 ;;   # the scan could not read .git
```

E1 test 9 ("ends the launcher with claude's status and a note") passes.

**Evidence:** `devcontainer-config/cc-isolated.sh:19-32`, `:743-751`; `$FC2/q094-bats.txt`

---

## Claim 16: "no repo config the scan reads (your own global config is covered by B14 instead) has a relative `core.hooksPath` …"

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:52`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers two things: B14 exists and says what the reference implies, and the host-form behaviour (E5). This claim does not re-test B14's container-form half ("host git in it stops (E10)").

B14 (`plan:86`) reads: "`_snap_host_config` already walks it for that git dir and any path inside the checkout becomes a new record (residue)". E5 confirms this: a global `hooksPath = .husky/_` gives a new `hooksdir` record and status 1.

**Evidence:** `docs/working/plan-q094-exit-scan-worktree-layout.md:52`, `:86`; `$FC2/wt.log`

---

## Claim 17: "6. Removed worktree `<n>`: split into the stacked unit … In this unit any removed record warns."

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:60`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the "in this unit any removed record warns" part only. The stacked unit's existence and design are Claim 18. The "447 lines" figure is Claim 19.

See Claim 6. `-` lines hit `*) return 1 ;;` (`cc-exit-scan.sh:832`), and E1 test 3 passes.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:827-834`; `$FC2/q094-bats.txt`

---

## Claim 18: "The stacked unit accepts a removal when … one removed `dotgit` record held exactly `gitdir: P\n` … Pairing is now by content." — with plan B27 (`:99`) "It is fixed there by pairing on content", rubric R2 "Fixed by content pairing … moved to the stacked unit `q094b-exit-scan-worktree-removal`", and commit c32a734 "Removal acceptance moves to a stacked unit … with content pairing" / "Notes: … the stacked unit is q094b-exit-scan-worktree-removal"

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:60`, `:99`; `docs/reviews/code-review-rubric-2026-09-28-q094-exit-scan-worktree-layout.md:14`; commit c32a734 body
**Type:** Reference / Behavioral
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers every ref in this repository, all worktrees, and the stash list, as of this run. This claim does not cover work held outside the repo, or a unit the orchestrator means to create next. If that is the intent, the wording should be future tense ("will pair by content").

No ref, branch, worktree or commit holds the stacked unit or any content-pairing code (paraphrased — no quote available because the claim covers absence):

- `git branch -a --list '*q094b*'` returns nothing.
- `git for-each-ref | grep -i q094` returns only `refs/heads/q094-exit-scan-worktree-layout`.
- `git log --all --grep=q094b` returns only c32a734 itself.
- `git worktree list` shows no q094b worktree.
- `git stash list` holds one unrelated entry.
- `q094b` appears nowhere in `docs/working/*.md` except this plan line.

Three statements are therefore present-tense claims about code that does not exist: "Pairing is now by content", "It is fixed there", and "Fixed by content pairing". Decision-log row 62 also asks for the /away split to be recorded as an interim in `questions.md`, and no q094b entry is there. That is noted here only as corroboration that the unit was not created.

**Evidence:** `docs/working/plan-q094-exit-scan-worktree-layout.md:60`, `:99`; `docs/reviews/code-review-rubric-2026-09-28-q094-exit-scan-worktree-layout.md:14`; `docs/decisions/log.md:85`

---

## Claim 19: "(decision log row 62 size cap; this unit came to 447 lines with it)"

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:60`
**Type:** Configuration
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the counts of the committed states. This claim does not cover the uncommitted with-removal version the number describes.

No committed state contains removal acceptance together with the iteration-1 fixes, so 447 cannot be recounted. The committed states, counting outside `docs/`, are:

- `git diff --stat dfe4c0d 5a6d689 -- . ':!docs'`: 391 insertions and 3 deletions, 394 in total. That is before the iteration-1 fixes and still includes count-pairing removal.
- `git diff --shortstat dfe4c0d HEAD -- . ':!docs'`: 388 insertions and 9 deletions, 397 in total, under the 400 cap.

The row-62 cap itself is "~400 changed code lines, counted outside `docs/`" (`docs/decisions/log.md:85`). 447 is plausible for the with-removal version, but verifying it needs that version.

**Evidence:** `docs/decisions/log.md:85`; commands above, run in the worktree at 2026-09-29T02:1x (output inline in this session)

---

## Claim 20: "7. Every record in the difference is consumed by 5 or 6."

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:61`
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers rule 7 against this unit's code. This claim does not cover the stacked unit.

Rule 6 no longer consumes anything in this unit. The code consumes only added records (rule 5), and any other record declines (`cc-exit-scan.sh:832`, `:890`). The rule should read "consumed by 5".

**Evidence:** `docs/working/plan-q094-exit-scan-worktree-layout.md:60-61`; `devcontainer-config/cc-exit-scan.sh:827-834`, `:890`

---

## Claim 21: "B28 … covered | Pattern matches in bash (`[[ ]]`), no pipeline. The same fix was applied to the pre-existing `invalid` check in `git_exit_scan`. Test: 40k padding records" — and commit c32a734 "All three checks, including the older `invalid` check …, are now bash pattern matches. Test: 40k padding records, both directions, under pipefail."

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:100`; commit c32a734 body (R1)
**Type:** Behavioral / Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three conversions and what the one new test exercises. This claim does not cover a large-snapshot test of the `invalid` check.

All three checks are `[[ ]]` matches (Claims 7 and 11). The 40k-record test calls `scan_std_worktrees` directly:

```bash
# test/cc-isolated-functions.bats:2281-2282
  set -o pipefail
  run scan_std_worktrees "$SCAN_WS" "$before"$'\n'"$pad" "$after"$'\n'"$pad"
```

That test exercises only the W check and the commondir check. `grep -n pipefail test/cc-isolated-functions.bats` finds no other pipefail test touching the `invalid` check. The precise version: "Test: 40k padding records, both directions, for the two checks in scan_std_worktrees".

**Evidence:** `test/cc-isolated-functions.bats:2273-2286`; `devcontainer-config/cc-exit-scan.sh:925-927`; `$FC2/m0.log`

---

## Claim 22: "B23 | Remove-and-re-add at the same path (dotgit changed) | covered | The added side is verified by rule 5; the removed `dotgit` is paired by count"

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:95`
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers this unit's handling of the remove-and-re-add case. This claim does not cover the (absent) stacked unit.

Count pairing no longer exists. A remove-and-re-add at the same path gives both a `-F dotgit` and a `+F dotgit` record, and the `-` record declines (`cc-exit-scan.sh:832`). The case now warns: a false positive, not a bypass. The row's "How" column describes removed code.

**Evidence:** `docs/working/plan-q094-exit-scan-worktree-layout.md:95`; `devcontainer-config/cc-exit-scan.sh:827-834`

---

## Claim 23: "B27 … not accepted (warns) | Only the `dotgit` record goes. Here, any removal warns."

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:99`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the "Here, any removal warns" part: an `rm -rf` without a prune leaves a lone `-F dotgit` record, which declines. The "fixed there by pairing on content" part is Claim 18. This claim does not cover a test of this exact `rm -rf` shape. The old test for it was removed this iteration, and test 3 uses `git worktree remove`.

Any `-` record declines through `*) return 1 ;;` (`cc-exit-scan.sh:832`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:827-834`; `test/cc-isolated-functions.bats:2263-2270`

---

## Claim 24: "3. `test/cc-isolated-functions.bats`: new standard … → 0 + note; removed standard → 0 + note; … private dir left behind after removal … → 1"

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:109`
**Type:** Reference
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the plan's test list against the test file at HEAD. This claim does not cover other plan steps.

The removed-standard test is now "a worktree removed during the session still warns" and asserts `[ "$status" -eq 1 ]` (`test/cc-isolated-functions.bats:2263-2270`). The "private dir left behind after removal" case was deleted from the test in this diff.

**Evidence:** `docs/working/plan-q094-exit-scan-worktree-layout.md:109`; `test/cc-isolated-functions.bats:2263-2270`

---

## Claim 25: "A linked worktree added or removed in git's own layout (an agent worktree left behind) is not a finding: one `note:` line, and the exit status is claude's."

**Location:** `guides/cc-isolated-usage.md:66-68`
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the "or removed" part. The added part is right. This claim does not cover other sections of the guide.

A removal now warns (exit 3). E1 test 3 shows this, and the same guide says so at `:347-348` ("Anything else warns … a worktree removed during it"). The guide therefore contradicts itself. The sentence should say "added". A reader who relies on it would take a warning after `git worktree remove` for a regression.

**Evidence:** `guides/cc-isolated-usage.md:66-68`, `:347-348`; `devcontainer-config/cc-exit-scan.sh:832`; `$FC2/q094-bats.txt`

---

## Claim 26: "3 the exit scan found a change (a note about standard worktrees is not one)"

**Location:** `guides/cc-isolated-usage.md:76-77`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the note path mapping to claude's status. This claim does not cover the rest of the exit-status paragraph, which is unchanged.

`git_exit_scan` returns 0 on the note path (`cc-exit-scan.sh:935`), and the launcher's `0) exit "$rc"` passes claude's status through (`cc-isolated.sh:748`). E1 test 9 passes.

**Evidence:** `guides/cc-isolated-usage.md:75-78`; `devcontainer-config/cc-isolated.sh:747-750`; `$FC2/q094-bats.txt`

---

## Claim 27: "When the only differences are worktrees added … in the exact layout git writes … note … A linked worktree takes its config, hooks and `info/attributes` from the checkout's own `.git` … except `config.worktree`, which refuses the note. … Anything else warns … a worktree removed during it, and any checkout whose config holds a relative `core.hooksPath` or `core.attributesFile` … or a relative local remote other than `.` …"

**Location:** `guides/cc-isolated-usage.md:334-351`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the Q-094 paragraph as edited. "Relative local remote other than `.`" is exact for the values tested in E4 (`./`, `.git` and `./.git` still warn). This claim does not cover global-config cases, which are Claim 3.

The paragraph's claims are confirmed by these tests:

- E1 test 1: the note.
- E1 test 3: a removal warns.
- E1 test 5: `config.worktree`, hooks and symlinks warn.
- E1 test 8: a relative hooksPath, attributesFile or `./sub.git` warns, while `branch.main.remote .` and an absolute hooksPath give 0.
- E4: `.` is exempt.

The case at `test/cc-isolated-functions.bats:2378` is `*abs-hooks|*" .") [ "$status" -eq 0 ] ;; *) warns_listing_wt ;;`.

**Evidence:** `guides/cc-isolated-usage.md:334-351`; `test/cc-isolated-functions.bats:2367-2383`; `$FC2/q094-bats.txt`, `$FC2/dot.log`

---

## Claim 28: "The same holds in a linked worktree the session leaves behind: its tracked files are never read, only its layout (see above)."

**Location:** `guides/cc-isolated-usage.md:365-366`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers what the snapshot reads inside a new worktree's tree: its `.git` entry, found by `find -name .git`, and paths your own config names there, such as a relative hooksPath or attributesFile. Those paths refuse the note anyway (Claim 3). This claim does not cover whether a hook present at launch runs tracked files in the worktree. That is the route the bullet describes.

The embedded-repo loop reads only each `.git` entry and the host config applied at that working tree:

```bash
# devcontainer-config/cc-exit-scan.sh:696-700
    while IFS= read -r -d '' f; do
      [ "$f" != "$_snap_ws/.git" ] || continue
      _snap_dotgit "$f" || { rc=1; break; }
      g="$(_snap_dotgit_target "$f")" || { rc=1; break; }
      [ -z "$g" ] || _snap_host_config "$g" "$f" "${f%/*}" || { rc=1; break; }
```

(excerpt ends :700; enclosing loop continues to :701 — read)

**Evidence:** `devcontainer-config/cc-exit-scan.sh:686-701`, `:495-531`

---

## Claim 29: "Each new worktree adds about 35 ms more to the check that allows the note."

**Location:** `guides/cc-isolated-usage.md:384-385`
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the linear per-worktree shape and the magnitude on this host. This claim does not settle the figure on another host or under different load; this sandbox may have been loaded by parallel agents.

The source is the performance review: "`perf/measure.sh 50` … 1,749 ms for 50 added worktrees (≈35 ms each)". That was measured before this iteration's `dot[]` index. E6 on this host, timing `scan_std_worktrees` averaged over 3 runs:

| New worktrees | Time |
|---|---|
| 1 | 125 ms |
| 2 | 244 ms |
| 5 | 476 ms |
| 10 | 1,077 ms |
| 20 | 1,890 ms |
| 40 | 3,853 ms |

That is linear, at about 95 ms per worktree. An earlier E5 run gave 134 ms, 901 ms and 2,741 ms for 1, 10 and 20. The mechanism (a linear per-worktree cost) holds. The figure is host-dependent: it is about 2.7× higher here. The precise version names the measurement, for example "tens of milliseconds (35 ms measured …)".

**Evidence:** `docs/reviews/performance-review-2026-09-28-q094.md:83`; `devcontainer-config/cc-exit-scan.sh:837-887`; `$FC2/tm.log`, `$FC2/wt.log`

---

## Claim 30: `@test "exit scan Q-094: a worktree removed during the session still warns"`

**Location:** `test/cc-isolated-functions.bats:2263`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the claim that the test name matches its assertions: `git worktree remove` gives status 1 and lists the removed `commondir-file`. This claim does not cover the unpruned `rm -rf` removal (B27), which no longer has a test.

```bash
# test/cc-isolated-functions.bats:2264-2269
  scan_repo
  std_wt agent-x
  local before; before="$(git_exec_snapshot "$SCAN_WS")"
  git -C "$SCAN_WS" worktree remove "$STD_WT"
  run git_exit_scan "$SCAN_WS" "$before"
  [ "$status" -eq 1 ]
```

(excerpt ends :2269; test continues to :2271 with `[[ "$output" == *"- commondir-file $STD_P/commondir "* ]]` — read)

**Evidence:** `test/cc-isolated-functions.bats:2263-2271`; `$FC2/q094-bats.txt`

---

## Claim 31: `@test "exit scan Q-094: large snapshots under pipefail neither lose the note nor skip the W refusal"` — with "Records sorted after the ones matched, in both snapshots, well past a pipe buffer."

**Location:** `test/cc-isolated-functions.bats:2273-2286`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the claim that each direction catches its own regression (E2). This claim does not cover the `invalid` check (Claim 21), or whether the W direction alone catches a regression when both checks are reverted.

E2 results:

- Reverting only the W check fails at `:2285`: `[ "$status" -eq 1 ]`, because the note was returned.
- Reverting only the commondir check fails at `:2283`: `[ "$status" -eq 0 ]`.
- Reverting both fails at `:2283`.

Because the W regression shows only once the commondir check is fixed, the commit's "hidden only by the next check failing the same way" also holds. The padding is 40,000 records of `F\tzz\t/p/<i>\tmissing\n`, about 0.88 MB, well past a 64 KiB pipe buffer. The records begin with `zz`, so they sort after `commondir`.

**Evidence:** `test/cc-isolated-functions.bats:2273-2286`; `$FC2/m0.log`, `$FC2/mW.log`, `$FC2/mC.log`, `$FC2/mBoth.log`

---

## Claim 32: "The container path the scan accepts is where devcontainer.json mounts the checkout." (commit: "a bats check that GIT_EXIT_SCAN_CONTAINER_WS matches devcontainer.json"; rubric C2)

**Location:** `test/cc-isolated-functions.bats:2381-2382`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the claim that `target=/workspace,` occurs in devcontainer.json, only in `workspaceMount`. This claim does not cover a check that the match is the `workspaceMount` key rather than some other mount.

`devcontainer-config/devcontainer.json:134` contains `"workspaceMount": "source=${localWorkspaceFolder},target=/workspace,type=bind,consistency=delegated",`, and `cc-exit-scan.sh:772` sets `GIT_EXIT_SCAN_CONTAINER_WS=/workspace`. E1 test 8 passes.

**Evidence:** `devcontainer-config/devcontainer.json:134`; `devcontainer-config/cc-exit-scan.sh:772`; `$FC2/q094-bats.txt`

---

## Claim 33: rubric R1 "Fixed: `[[ ]]` pattern matches; test with 40k padding records, under pipefail, in both directions (a mutation reverting either check fails it)"

**Location:** `docs/reviews/code-review-rubric-2026-09-28-q094-exit-scan-worktree-layout.md:13`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the W and commondir checks and the parenthetical mutation claim. The `:939` `invalid` check is converted (Claim 11) but is not in the test (Claim 21).

E2: `mW` and `mC` each fail the test, and `m0` passes.

**Evidence:** `$FC2/mW.log`, `$FC2/mC.log`, `$FC2/m0.log`

---

## Claim 34: rubric A2 / A3 "Fixed: records indexed once (`dot[]`)" / "Fixed: size cap of 4097 bytes before the read"

**Location:** `docs/reviews/code-review-rubric-2026-09-28-q094-exit-scan-worktree-layout.md:21-22`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the presence and ordering of both fixes. This claim does not cover performance at thousands of worktrees.

See Claims 8 and 9. The `stat` cap at `:861` comes before `_snap_first_line` at `:862`, and `dot[]` is built at `:830`.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:830`, `:861-862`, `:874`

---

## Claim 35: rubric A4 "Fixed" (doc accuracy: config.worktree exception, "repo config" in rule 3, "tracked files", the return-2 doc, the exit-status text in `cc-isolated.sh` and the guide, the stray line break)

**Location:** `docs/reviews/code-review-rubric-2026-09-28-q094-exit-scan-worktree-layout.md:23`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each listed item: Claims 1, 16, 28, 10, 15 and 26, and the `git_exit_scan` header now reads as one sentence at `:899-900`. This claim does not cover the new staleness the R2 change created (Claims 12, 20, 22, 24 and 25). A4 did not list those, but they are the same kind of doc drift.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:75-84`, `:897-901`; `devcontainer-config/cc-isolated.sh:20-23`; `guides/cc-isolated-usage.md:76-77`, `:365-366`; `docs/working/plan-q094-exit-scan-worktree-layout.md:52`

---

## Claim 36: rubric C4 "bats test 1 counts output lines, so it is sensitive to locale warnings on stderr (environmental)"

**Location:** `docs/reviews/code-review-rubric-2026-09-28-q094-exit-scan-worktree-layout.md:33`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the reproduction in this sandbox. This claim does not settle whether the host or CI has a working locale.

`bats -f 'Q-094' test/cc-isolated-functions.bats` run under the ambient `LC_ALL=en_US.UTF-8`, which is not installed, gave `not ok 1 … [ "$(printf '%s\n' "$output" | wc -l)" -eq 1 ]' failed`. The cause was `cc-exit-scan.sh: line 681: warning: setlocale: LC_ALL: cannot change locale`. With `LC_ALL=C.UTF-8`, E1 gives 9/9.

**Evidence:** `test/cc-isolated-functions.bats:2233`; `$FC2/q094-bats.txt`

---

## Claims Requiring Attention

### Incorrect
- **Claim 18** (`docs/working/plan-q094-exit-scan-worktree-layout.md:60`, `:99`; rubric R2 `:14`; commit c32a734): these say, in the present tense, that a stacked unit `q094b-exit-scan-worktree-removal` exists and pairs removals by content ("Pairing is now by content", "It is fixed there", "Fixed by content pairing"). No ref, worktree or stash holds it. Either create the unit or change the wording to future or planned. (One claim; it appears in three places: the plan, the rubric and the commit.)

### Stale
- **Claim 12** (`devcontainer-config/cc-exit-scan.sh:931`): the call-site comment says "added or removed". Only added worktrees get the note.
- **Claim 25** (`guides/cc-isolated-usage.md:66-68`): says "added or removed … is not a finding", which contradicts `:348` and the code. A removal warns.
- **Claim 20** (plan `:61`): rule 7 says "consumed by 5 or 6". Only rule 5 consumes records in this unit.
- **Claim 22** (plan `:95`, B23): still describes count pairing. Remove-and-re-add now warns.
- **Claim 24** (plan `:109`, step 3): still lists "removed standard → 0 + note" and the "private dir left behind after removal" test.

### Mostly Accurate
- **Claim 2** (`cc-exit-scan.sh:80-83`): "local remote … leave W records". `.` is now exempt; add "other than `.`".
- **Claim 21** (plan B28 `:100`; commit R1 text): the 40k test covers the two `scan_std_worktrees` checks, not the converted `invalid` check.
- **Claim 29** (`guides/cc-isolated-usage.md:384-385`): "about 35 ms" is host-dependent. It measured about 95 ms per worktree here, linear.

### Unverifiable
- **Claim 19** (plan `:60`): "447 lines with it". No committed state has removal plus the fixes to count. The committed unit is 397 lines outside `docs/`.

Note: the caller said not to edit other files, so `docs/reviews/hallucination-patterns.md` was not changed. Claim 18 is the only candidate for it: code claimed to exist in a named branch that does not exist. It is closer to a plan stated as done than to a fabricated API. The caller can decide whether to log it.
