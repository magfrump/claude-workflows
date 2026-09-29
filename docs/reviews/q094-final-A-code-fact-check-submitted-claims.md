Commit: 9075003

# Code Fact-Check Report

**Repository:** claude-workflows (`git archive 9075003` of `/workspace/.claude/worktrees/agent-aaad54fc687b7548c`, extracted to `/tmp/claude-1000/-workspace/0d5be710-0e7c-4a4f-8e65-09d2e983c2f5/scratchpad/s25-2763022088/A`)
**Scope:** Stage 2.5 submitted-claims pass only — four critic endorsements on Q-094 unit A (`devcontainer-config/cc-exit-scan.sh` at 9075003); no fresh harvesting
**Checked:** 2026-09-28
**Total claims checked:** 4
**Summary:** 4 verified, 0 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Hallucination pattern log (`docs/reviews/hallucination-patterns.md`, 5 entries) read: every logged pattern is a measured value quoted from an artifact set that does not contain it, or a symbol association not grepped. None of these four claims quotes a measured value or names an unchecked symbol; no logged pattern applies.

Execution environment for every executed claim: cwd `/tmp/claude-1000/-workspace/0d5be710-0e7c-4a4f-8e65-09d2e983c2f5/scratchpad/s25-2763022088`, GNU bash 5.2.15, host kernel 6.18.35.2-microsoft-standard-WSL2, `GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 LC_ALL=C`. Harness: `harnessA.sh` in that dir (sources the archived `A/devcontainer-config/cc-exit-scan.sh`, builds throwaway repos under `$TMPDIR` = that dir, removes them after). Counterfactuals use the pre-fix code at 5a6d689 (extracted to `.../s25-2763022088/pre`).

Command: `TMPDIR=$PWD bash harnessA.sh $PWD/A > logs/harnessA-9075003.txt 2>&1` — exit 0, started 2026-09-29T03:46:27Z (UTC). Output: `/tmp/claude-1000/-workspace/0d5be710-0e7c-4a4f-8e65-09d2e983c2f5/scratchpad/s25-2763022088/logs/harnessA-9075003.txt`.

---

## Submitted Claims

## Claim 1: "The `invalid` check in `git_exit_scan` no longer uses `printf | grep -q`, so pipefail cannot make an early match read as \"no match\"."

**Submitted by:** security-reviewer
**Location:** `devcontainer-config/cc-exit-scan.sh:927-929`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the `gitdir-valid … invalid` test in `git_exit_scan` (`:925-931`, read with the whole function `:904-970`) and the absence of any `| grep -q` pipeline in `git_exit_scan` and `scan_std_worktrees`; does not establish the absence of pipefail-sensitive pipelines in other files the launcher sources (only `cc-isolated.sh` was grepped for `| grep -q`, zero hits) or in functions the snapshot calls.

The check is a bash regex match on the variable, with no pipeline:

```bash
# devcontainer-config/cc-exit-scan.sh:925-931
  local invalid=""
  # A pattern match, not `printf | grep -q` (pipefail: see scan_std_worktrees).
  local re=$'(^|\n)F\tgitdir-valid\t[^\t\n]*\tinvalid'
  if [[ "$after" =~ $re ]]; then
    invalid="    ! $(printf '%q' "$ws/.git") is not a valid git directory now: host git would look for a repository elsewhere (the checkout root)"
  fi
  [ "$before" != "$after" ] || [ -n "$invalid" ] || return 0
```

The record it matches is written as `"F"$'\t'"gitdir-valid"$'\t'"$(printf '%q' "$ws/.git")"$'\t'"$i HEAD=…"` with `i` = `valid` or `invalid` (`devcontainer-config/cc-exit-scan.sh:681-682`); the path field is `%q`-quoted, so it holds no literal tab or newline for `[^\t\n]*` to trip on. The pre-fix line was `if printf '%s\n' "$after" | LC_ALL=C grep -q $'^F\tgitdir-valid\t[^\t]*\tinvalid'; then` (paraphrased — no quote available because the line is in 5a6d689, not the reviewed tree; seen in `git diff 5a6d689 c32a734 -- devcontainer-config/cc-exit-scan.sh`, hunk line 193).

Executed under `set -o pipefail`, with `git_exec_snapshot` wrapped to append 40,000 `F\tzz\t…` records (sorted after `gitdir-valid`) and the checkout's `.git/HEAD` removed:
- HEAD removed during the session: `RESULT S1-changed: status=1 1 invalid-lines`, and the warning carries `~ gitdir-valid …/.git  invalid HEAD=invalid`.
- Invalid at launch and at exit, snapshots otherwise identical: `RESULT S1-unchanged-invalid: status=1 1 invalid-lines`, so the `|| [ -n "$invalid" ]` branch keeps it a finding.
- Control (HEAD restored): `RESULT S1-valid-control: status=0 out=[]`, so the regex does not fire on a `valid` record.
- Counterfactual, the pre-fix pipeline on the same padded snapshot: `nomatch` under pipefail, `match` without it. The test tells the two implementations apart, and the pre-fix bug was real.
- `declare -f git_exit_scan scan_std_worktrees | grep 'grep -q'` → `none`.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:904-931`, `devcontainer-config/cc-exit-scan.sh:681-682`, `devcontainer-config/cc-isolated.sh:66` (`set -euo pipefail`), `devcontainer-config/cc-isolated.sh:745` (the call site), `logs/harnessA-9075003.txt` (the `== S1` block)

---

## Claim 2: "`_snap_worktree_of` does not open a non-regular config path with `git config --file` (the FIFO guard)."

**Submitted by:** security-reviewer
**Location:** `devcontainer-config/cc-exit-scan.sh:328`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers `_snap_worktree_of` (`:323-335`, the whole function) for a FIFO and a symlink to a FIFO at the time of the test; does not establish safety against the path being swapped for a FIFO between the `[ -f ]` test and git's open (a check-then-use gap; at exit the container has stopped, so no container writer is expected to be running), and does not cover `git config --file` in `_snap_config` (`:381`), whose three callers (`:399`, `:527`, `:580`) each apply their own `[ -f … ]` guard before calling it.

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

`[ -f "$1" ]` is false for a FIFO, and for a symlink to a FIFO (`test -f` follows the link and tests the target), so the `&&` short-circuits before `git config` runs. The only other exit from the function before that branch is the `$_snap_gd`/`$_snap_common` branch, which prints and runs no git command.

Executed (under `timeout 10`): a FIFO named `config` → `status=0`, printing its directory; a symlink `lcfg` to that FIFO → `status=0`, same. Counterfactual: the same function with `[ -f "$1" ] && ` removed, run on the FIFO → `status=124` (timed out, blocked opening the FIFO). Control: a regular config holding `core.worktree=/abs/wt` → `out=/abs/wt`, so the guard does not disable the normal branch.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:323-335`, `devcontainer-config/cc-exit-scan.sh:376`, `devcontainer-config/cc-exit-scan.sh:381`, `devcontainer-config/cc-exit-scan.sh:399`, `devcontainer-config/cc-exit-scan.sh:527`, `devcontainer-config/cc-exit-scan.sh:580`, `devcontainer-config/cc-exit-scan.sh:608-611`, `logs/harnessA-9075003.txt` (the `== S2` block)

---

## Claim 3: "A difference that includes any record other than `+F dotgit`, `+F commondir-file` or `+F hooksdir`, or any W record in the exit snapshot, makes `scan_std_worktrees` return 1."

**Submitted by:** security-reviewer
**Location:** `devcontainer-config/cc-exit-scan.sh:813-835`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the record-kind filter (`:825-835`) and the W refusal (`:813`) of `scan_std_worktrees` (read `:806-896` in full), for differences computed as a set difference of snapshot lines; does not establish which `+F dotgit` / `+F commondir-file` / `+F hooksdir` records are then accepted (that is the per-worktree matching at `:839-892`, not verdicted here, though executed probes of off-pattern records of those three kinds all returned 1), and does not establish that the snapshot records everything host git would read (LIMITS).

The W refusal runs first and looks at the whole exit snapshot, not the difference:

```bash
# devcontainer-config/cc-exit-scan.sh:811-813
  # Pattern matches, not `printf | grep -q`: under the launcher's pipefail an
  # early match SIGPIPEs printf, and the pipeline reads as "no match".
  [[ $'\n'"$after" != *$'\n'W$'\t'* ]] || return 1
```

The difference is a line-level set difference, and every line not of the three `+F` kinds returns 1:

```bash
# devcontainer-config/cc-exit-scan.sh:825-835
  diff="$(LC_ALL=C awk 'FNR == NR { b[$0] = 1; next } { a[$0] = 1 }
    END { for (k in a) if (!(k in b)) print "+" k; for (k in b) if (!(k in a)) print "-" k }' \
    <(printf '%s\n' "$before") <(printf '%s\n' "$after"))" || return 1
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    case "$line" in
      +F$'\t'dotgit$'\t'*) left["$line"]=1; dot["${line%$'\t'*}"]="$line" ;;
      +F$'\t'commondir-file$'\t'*|+F$'\t'hooksdir$'\t'*) left["$line"]=1 ;;
      *) return 1 ;;
    esac
  done <<< "$diff"
```

Every `-` (removed) line falls to `*) return 1`. Record kinds are `F`, `C` and `W` (paraphrased — no quote available because the kinds are defined across the format comment at `:148-153` and the three emitters `:257`, `:390`, `:293`); snapshots are `sort -u`'d (`:715`), so the set difference loses no duplicates.

Executed on a real repo with one `git worktree add` (baseline `status=0`, added records exactly one each of `F commondir-file`, `F dotgit`, `F hooksdir`), then each of these added to the exit snapshot → `status=1`: `+F hook`, `+C … core.fsmonitor x`, `+F link` in P, `+F config` (P/config.worktree); one `F config` line removed from the exit snapshot (`-F config`) → 1; a `W` record present in **both** snapshots, so absent from the difference → 1; a `W` record in the exit snapshot only → 1. Off-pattern records of the three allowed kinds (another P's `hooksdir`, a `dotgit` elsewhere, a `commondir-file` outside `<common>/worktrees/`) also → 1, through the later matching and the all-consumed check at `:892`.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:806-896`, `devcontainer-config/cc-exit-scan.sh:148-153`, `devcontainer-config/cc-exit-scan.sh:257`, `devcontainer-config/cc-exit-scan.sh:293`, `devcontainer-config/cc-exit-scan.sh:390`, `devcontainer-config/cc-exit-scan.sh:715`, `logs/harnessA-9075003.txt` (the `== S3` block)

---

## Claim 4: "The per-worktree `find -P \"$p\" -type l -print -quit` walks a subset of what the exit snapshot already walked, and stops at the first link, so a large or hostile P cannot cost the check more than it already cost the snapshot."

**Submitted by:** performance-reviewer
**Location:** `devcontainer-config/cc-exit-scan.sh:857`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the cost of the `find` at `:857` relative to the exit snapshot's own walks of the same common dir; does not establish a bound on the other per-worktree work in the loop (hashing, `stat`, subshells: that cost is what Claim 3 of the unit-B report measures), or on P changing between the exit snapshot and the check (only possible if a writer is still running after the container exits).

The check:

```bash
# devcontainer-config/cc-exit-scan.sh:854-857
    [ -d "$common/worktrees" ] && [ ! -L "$common/worktrees" ] && [ -d "$p" ] && [ ! -L "$p" ] || return 1
    _snap_file_is "$p/commondir" "$std" || return 1
    for k in hooks config config.worktree; do [ ! -e "$p/$k" ] && [ ! -L "$p/$k" ] || return 1; done
    lnk="$(find -P "$p" -type l -print -quit 2>/dev/null)" && [ -z "$lnk" ] || return 1
```

`p="$common/worktrees/$n"` (`:846`), and `$common` is pinned to the common dir the exit snapshot recorded (`:818-819`). The exit snapshot walks that common dir with an unbounded link search and a HEAD search under `worktrees/`:

```bash
# devcontainer-config/cc-exit-scan.sh:626-638
  list="$_snap_tmp/l.${#_snap_seen[@]}"
  _snap_find "$list" "$real" -type l || return 1
  while IFS= read -r -d '' f; do
    [ "${f%/*}" != "$real/hooks" ] || continue
    _snap_file link "$f" || return 1
    if [ -n "$_snap_linkdir" ] && _snap_inside_ws "$_snap_linkdir"; then
      c="$_snap_linkdir"
      if [ -e "$c/HEAD" ]; then _snap_gitdir "$c" || return 1; fi
      _snap_nested "$c" || return 1
    fi
  done < "$list"
  _snap_nested "$real/modules" || return 1
  _snap_nested "$real/worktrees"
}
```

(excerpt ends `:639`, the end of `_snap_gitdir` — read.) `_snap_gitdir "$_snap_common"` is called for every snapshot (`:689`), and `_snap_find` is `find -P "$@" -print0` with no `-quit` or prune (`:271`). P lies inside `$real`, so the snapshot's walk of P is complete, and a failure to list it fails the snapshot before the check runs. Each P in the loop is distinct: `n` comes from distinct `left` keys, and those keys are distinct `commondir-file` paths (`:839-846`). So the checks together walk at most the `worktrees/` subtree once.

Executed: a symlink placed at `P/deep/zlink` appears in the exit snapshot as an `F link …/worktrees/agent-x/deep/zlink` record, and `scan_std_worktrees` then returns 1. Timing with 60,000 entries in P (no links): full exit snapshot 0.331 s; a `find -P .git -type l` like the snapshot's 0.028 s; the check's `find` over P 0.029 s. With one link added, the check's `find` over P takes 0.004 s (`-quit`). These are one run each on a warm cache: the numbers support "no more than", not a precise ratio.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:839-857`, `devcontainer-config/cc-exit-scan.sh:818-819`, `devcontainer-config/cc-exit-scan.sh:269-275`, `devcontainer-config/cc-exit-scan.sh:573-639`, `devcontainer-config/cc-exit-scan.sh:686-689`, `logs/harnessA-9075003.txt` (the `== S4` block)

---

## Claims Requiring Attention

### Incorrect
- None.

### Stale
- None.

### Mostly Accurate
- None.

### Unverifiable
- None.

## Goal-Alignment Note
- Success criterion (restated verbatim): two reports saved at the paths below, each a `## Submitted Claims` section in code-fact-check schema (seven bolded fields per claim, Verification mode, Scope line, Legibility-target), plus a Goal-Alignment Note.
- Answered: yes. All four unit-A submitted claims are verdicted (4 Verified, all executed), with pre-fix counterfactuals for Claims 1 and 2.
- Out of scope: no fresh harvesting. Other per-worktree costs in the added-path loop are out of scope for Claim 4. The FIFO swap race between the `-f` test and git's open (Claim 2) is named in Scope and was not tested.
- Escalate: nothing.
- Decisions I made: the unit-A code was the `git archive` of 9075003, not the live worktree. For Claim 3 I read "W record in the exit snapshot" literally, so a W present in both snapshots also counts, and I tested that case.
