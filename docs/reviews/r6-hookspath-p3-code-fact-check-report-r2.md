Commit: 28dfcd3b

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-2026-10-25-exit-scan-r6-hookspath (branch fix/exit-scan-r6-hookspath)
**Scope:** `git diff d40e4bae..28dfcd3b`: devcontainer-config/cc-exit-scan.sh, test/cc-isolated-functions.bats, guides/cc-isolated-usage.md, docs/working/research-2026-10-25-exit-scan-r6-hookspath.md, and the commit messages of cf15f4f9, e1d7d912, 28dfcd3b. Pass 3 (final confirming pass), replicate r2 of k=3.
**Checked:** 2026-10-25
**Total claims checked:** 31 (Claim 30 split into 30a/30b)
**Summary:** 25 verified, 6 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) read first. No claim here matches a logged pattern; every symbol named in scope (`_snap_cfg_hooks`, `_snap_cfg_hooks_file`, `_snap_entry_hooks`, `gitdir_common`, `_snap_tree_hooks` at cf15f4f9/e1d7d912) exists where claimed.

Execution environment for every `executed` claim: git 2.39.5, GNU bash 5.2.15, `GIT_CONFIG_NOSYSTEM=1`, an empty `GIT_CONFIG_GLOBAL`, `LC_ALL` unset. Captured outputs are in the scratch directory `/tmp/claude-1000/-workspace/89c2ddf7-2b6b-41d6-b07b-ae5871fb9429/scratchpad/2026-10-25-exit-scan-r6-hookspath/fc-p3-r2/` (referred to below as `$FC`). The variant trees `$FC/tree-<commit>` are `git archive 28dfcd3b devcontainer-config test` with `cc-exit-scan.sh` replaced by that commit's version, so the 28dfcd3b test file runs against each scan. Timestamps are UTC, taken 2026-10-26T01:07Z–01:15Z (2026-10-25 18:07–18:15 container local time).

Legibility-target names the reader each claim is written for: *maintainer* (someone editing cc-exit-scan.sh), *reviewer* (someone reading the commit log or research doc to judge the change), *user* (someone reading the guide to decide whether to trust the scan).

---

## Claim 1: "a hook planted at <worktree>/.husky/_ passed the scan (rc=0) and ran on the next host commit there" (cf15f4f9 commit message)

**Location:** commit cf15f4f9 (message body, paragraph 1)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers rc=0 from d40e4bae's scan with a relative repo `core.hooksPath` and a launch-time linked worktree, and the host commit running the hook; does not establish the same on a real host install (no host run).
**Legibility-target:** reviewer

Executed: `cd $FC/tree-d40e4bae && LC_ALL= timeout 300 bats -f PART test/cc-isolated-functions.bats` (2026-10-26T01:08:08Z). The scratch test PART1 copies the case's first block (`git -C "$SCAN_WS" config core.hooksPath .husky/_`, `std_wt agent-x`, plant `$STD_WT/.husky/_/pre-commit`). It printed `status=0` and failed `[ "$status" -eq 1 ]`. The case's final lines at HEAD, `git -C "$STD_WT" -c commit.gpgsign=false commit -q --allow-empty -m x` and `[ -e "$TEST_TMPDIR/ran/hook-pre-commit" ]` (`test/cc-isolated-functions.bats:3193-3194`), pass, so git runs the planted hook.

**Evidence:** `test/cc-isolated-functions.bats:3143-3154`, `test/cc-isolated-functions.bats:3193-3194`, `$FC/parts-d40e4bae.log` (exit 1, `not ok 1 PART1 direct`, `status=0`), `$FC/r6-head.log`

---

## Claim 2: "The working-tree .git loop now also reads the configs git uses for each entry's git dir (common config, config.worktree, includes) and walks a relative core.hooksPath at <entry dir>/<value> (_snap_entry_hooks, _snap_tree_hooks)" (cf15f4f9)

**Location:** commit cf15f4f9 (message body, paragraph 1)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the code as it stood at cf15f4f9; does not describe HEAD, where `_snap_tree_hooks` no longer exists and both gaps below are closed.
**Legibility-target:** reviewer

"includes" was not all includes at cf15f4f9. That version skipped every value starting `/` or `~/` before it dispatched on the key, so an absolute or `~/` `include.path` was never followed:

```bash
# git show cf15f4f9:devcontainer-config/cc-exit-scan.sh, _snap_tree_hooks
    case "$val" in ""|/*|"~/"*) continue ;; esac   # walked once, by _snap_config
    case "$key" in
      core.hookspath) _snap_hooks "$wt/$val" || return 1 ;;
      include.path|includeif.*.path)
```
(excerpt ends inside the read loop; enclosing `_snap_tree_hooks` continues to its `done < "$out"` — read)

It also capped the include depth at 10 beside a seen set (`[ "$depth" -le 10 ] || return 0`), the bug Claim 5 describes. The precise wording would be "includes with a relative path, to depth 10". e1d7d912's message records the first gap itself.

**Evidence:** `git show cf15f4f9:devcontainer-config/cc-exit-scan.sh` (`_snap_tree_hooks`, `_snap_entry_hooks`)

---

## Claim 3: "the first version skipped absolute and ~/ include paths … The abs/~ skip now applies to the hooksPath value only; the bats case covers an absolute include.path" (e1d7d912)

**Location:** commit e1d7d912 (message body, paragraph 1)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the abs/~ skip moving from all values to the hooksPath value, and the bats absolute-include part passing on e1d7d912 and failing on d40e4bae; does not establish the `~/` include form by execution (static only).
**Legibility-target:** reviewer

At e1d7d912 the skip sits inside the `core.hookspath` arm only:

```bash
# git show e1d7d912:devcontainer-config/cc-exit-scan.sh, _snap_tree_hooks
      core.hookspath)
        case "$val" in /*|"~/"*) ;; *) _snap_hooks "$wt/$val" || return 1 ;; esac ;;
      include.path|includeif.*.path)
        # Any include, absolute or not: its relative hooksPath still resolves in <wt>.
        _snap_tree_hooks "$(_snap_path "$val" "$(dirname -- "$f")")" "$wt" $((depth + 1)) || return 1 ;;
```

Executed: the scratch PART3 (absolute `include.path`) printed `status=1`, `ok`, on e1d7d912 and `status=0`, `not ok`, on d40e4bae (same command as Claim 1, 01:08:11Z and 01:08:08Z).

**Evidence:** `test/cc-isolated-functions.bats:3166-3175`, `$FC/parts-e1d7d912.log`, `$FC/parts-d40e4bae.log`

---

## Claim 4: "_snap_entry_hooks reads the common dir through cc-gitdir.sh's gitdir_common (git's reading, CR/LF trimmed) … an unreadable or empty commondir fails the snapshot" (e1d7d912)

**Location:** commit e1d7d912 (message body, paragraph 2)
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the empty and directory (non-regular) commondir cases failing the snapshot at HEAD, where git also dies; does not establish the over-4096-byte or permission-denied cases by execution (static only).
**Legibility-target:** reviewer

```bash
# devcontainer-config/cc-gitdir.sh:57-60
  if [ ! -e "$c" ] && [ ! -L "$c" ]; then printf '%s' "$d"; return 0; fi
  [ -f "$c" ] && [ -r "$c" ] || return 1
  s="$(stat -c %s -- "$c" 2>/dev/null)" || return 1
  [ "$s" -gt 0 ] && [ "$s" -le 4096 ] || return 1
```
(excerpt ends :60; enclosing `gitdir_common` continues to :69 with the CR/LF trim loop at :64-66 — read)

```bash
# devcontainer-config/cc-exit-scan.sh:714
  c="$(gitdir_common "$g")" || { _snap_fail 'cannot read the commondir file in %s' "$g"; return 1; }
```

Executed: `timeout 60 bash $FC/probe-cd.sh $FC/tree-<rev> $FC` (01:14Z), with an embedded repo whose `.git/commondir` is empty, then a directory. Git: `git status rc=128 fatal: failed to read …` in both cases. Snapshot: rc=0 on d40e4bae, rc=1 `cannot read the commondir file in …` on 28dfcd3b.

**Evidence:** `devcontainer-config/cc-gitdir.sh:50-69`, `devcontainer-config/cc-exit-scan.sh:712-722`, `$FC/probe-cd.sh`, `$FC/probe-cd.log`

---

## Claim 5: "a depth cap beside a seen set let a file first met at depth 10 of an includeIf chain git does not take hide its include from the plain include git does take (rc=0, hook ran)" (28dfcd3b)

**Location:** commit 28dfcd3b (message body, first bullet)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers rc=0 on e1d7d912 for the bats chain, and git taking the plain include; does not establish other chain shapes.
**Legibility-target:** reviewer

At e1d7d912 the cap check (`[ "$depth" -le 10 ] || return 0`) runs before the seen mark. In the bats chain, `x.cfg` is read and marked at depth 10 (config 0 → a1 … a9 → x). Its include `inc.cfg` would be depth 11 and is returned from unmarked. The later plain `include.path = x.cfg` then hits the seen key for `x.cfg` and stops. That is exactly "a file first met at depth 10 … hide its include". Executed: scratch PART4 printed `status=0`, `not ok`, on e1d7d912 and `status=1`, `ok`, on 28dfcd3b. Its own `[ "$(git -C "$STD_WT" config core.hooksPath)" = .inc-hooks ]` passed, and on 28dfcd3b the trailing host commit ran the hook.

**Evidence:** `git show e1d7d912:devcontainer-config/cc-exit-scan.sh` (`_snap_tree_hooks`), `test/cc-isolated-functions.bats:3176-3194`, `$FC/parts-e1d7d912.log`, `$FC/parts-28dfcd3b.log`

---

## Claim 6: "_snap_cfg_hooks now collects every core.hooksPath value of a config and its includes once per snapshot (cached by real path, no depth cap: git dies past 10, so deeper is an over-walk)" (28dfcd3b)

**Location:** commit 28dfcd3b (message body, paragraph 2)
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the cache key and lifetime, the absence of any depth check, and git 2.39.5 dying on an 11-deep include chain; does not establish that included files are read once across different top-level configs (they are read once per top-level config, see Claim 8).
**Legibility-target:** reviewer

```bash
# devcontainer-config/cc-exit-scan.sh:657-667
_snap_cfg_hooks() {
  local real
  real="$(realpath -m -- "$1" 2>/dev/null)" || real="$1"
  if [ -z "${_snap_rhc["$real"]:-}" ]; then
    local -A _snap_rhseen=()
    _snap_rhs=${#_snap_rhv[@]}
    _snap_cfg_hooks_file "$1" "$real" || return 1
    _snap_rhc["$real"]="$_snap_rhs $((${#_snap_rhv[@]} - _snap_rhs))"
  fi
  _snap_rhs="${_snap_rhc["$real"]% *}"; _snap_rhn="${_snap_rhc["$real"]#* }"
}
```

`_snap_rhc` is declared per snapshot (`local -A _snap_rhc=(); local -a _snap_rhv=()`, `:865`). `_snap_cfg_hooks_file` (`:670-694`) has no depth parameter. Executed: `git config --file c0.cfg --includes --get core.hooksPath` on a 10-deep chain printed `deep`, rc=0. On an 11-deep chain: `fatal: exceeded maximum include depth (10) while including c11.cfg from c10.cfg`, rc=128 (`$FC/depth`, 01:09Z).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:657-694`, `devcontainer-config/cc-exit-scan.sh:865`; command output captured in this report (the depth probe printed to the terminal only, two lines per case, quoted verbatim above)

---

## Claim 7: "_snap_entry_hooks walks each value in the entry's directory, absolute values included (pass-2 fact-check: an absolute value in a config only this walk reads was not walked)" (28dfcd3b)

**Location:** commit 28dfcd3b (message body, paragraph 2)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers an absolute `core.hooksPath` in the `config.worktree` of a container-form `.git`'s git dir (a config only this walk reads), walked on 28dfcd3b and missed on e1d7d912; does not establish `~/` values by execution.
**Legibility-target:** reviewer

```bash
# devcontainer-config/cc-exit-scan.sh:715-720
  for cfg in "$c/config" "$g/config.worktree"; do
    _snap_cfg_hooks "$cfg" || return 1
    for ((k = _snap_rhs; k < _snap_rhs + _snap_rhn; k++)); do
      _snap_hooks "$(_snap_path "${_snap_rhv[k]}" "$wt")" || return 1
    done
  done
```

`_snap_path` returns `/…` values unchanged (`:305`). Executed: `timeout 120 bash $FC/probe-cf.sh $FC/tree-<rev> $FC`, case B (01:11Z). The probe's container-form `.git` names `/cws-none/tw`, a twin dir outside `.git/`. At launch, the twin's `config.worktree` holds `hooksPath = <ws>/abs-hk`. The session plants `abs-hk/pre-commit`. Result: 28dfcd3b rc=1 with `+ hook …/ws/abs-hk/pre-commit`; e1d7d912 rc=0.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:301-308`, `devcontainer-config/cc-exit-scan.sh:712-722`, `$FC/probe-cf.sh`, `$FC/probe-cf.log`

---

## Claim 8: "the walk re-read each include set once per .git entry (100 entries x 100 includes: 46.6 s against 2.2 s) … 100 x 100 includes now 2.71 s; 100 embedded repos about 5 ms more each" (28dfcd3b)

**Location:** commit 28dfcd3b (message body, first paragraph second bullet; paragraph 2)
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the 2.71 s and +5 ms/repo figures, reproduced within load noise with the pass-2 harness, and the per-entry seen key that caused the re-reads; does not re-run the 46.6 s e1d7d912 figure (taken from the pass-2 performance review, 46.57 s).
**Legibility-target:** reviewer

The e1d7d912 seen key was per (file, worktree): `_snap_seen["t:$real:$wt"]=1` (`git show e1d7d912:…`, `_snap_tree_hooks`), so each include was re-read once per entry. Executed: the pass-2 harness, copied to `$FC/perf/probe-noshim.sh` with old=d40e4bae and new=28dfcd3b (`timeout 280 bash probe-noshim.sh $FC/perf inc 100 100`, 01:14Z, load about 3). Result: `inc old … secs=2.00`, `inc new … secs=2.54`, against the message's 2.71 s. Embedded repos (`$FC/probe-time-run.sh`, 3 runs each): d40e4bae 2.36/2.36/2.32 s, 28dfcd3b 2.86/2.91/3.06 s for 100 repos, which is about 6.0 ms more each (python3 arithmetic).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:657-667`, `docs/reviews/r6-hookspath-p2-performance-review-2026-10-25.md:27`, `$FC/perf/perf.log`, `$FC/probe-time.log`

---

## Claim 9: "A relative core.hooksPath in repo config, set directly or through an include, is walked in each working tree that uses that config, every linked worktree and `.git` entry in the checkout included (_snap_entry_hooks)"

**Location:** `devcontainer-config/cc-exit-scan.sh:61-65`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers working trees found as a `.git` entry by the working-tree find (linked worktrees, embedded repos, `--separate-git-dir` repos, container-form `.git` twins), directly and through relative, absolute and deep includes; does not establish a working tree set by `core.worktree` in `config.worktree` (the guide lists it) or `.git` entries the find does not reach.
**Legibility-target:** maintainer

The call site sits in the `find … -name .git` loop:

```bash
# devcontainer-config/cc-exit-scan.sh:909-910
      # The repo's own relative hooksPath, as it applies in this working tree.
      [ -z "$g" ] || _snap_entry_hooks "$g" "${f%/*}" || { rc=1; break; }
```

The main tree is still covered by `_snap_config` (base `_snap_ws`, `:349-350`). Executed: the full R6 case passes at HEAD (`$FC/r6-head.log`, `ok 1`, exit 0). The R3 `--separate-git-dir` probe (Claim 26) and the container-form probe (Claim 16) show other `.git` entry kinds.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:61-65`, `devcontainer-config/cc-exit-scan.sh:346-358`, `devcontainer-config/cc-exit-scan.sh:899-912`, `$FC/r6-head.log`

---

## Claim 10: "sets _snap_rhs and _snap_rhn, where in _snap_rhv the core.hooksPath values of <config> and every file it includes start, and how many there are. Each config's set is read once per snapshot and cached by its real path in _snap_rhc, so N worktrees sharing one config cost one read, not N."

**Location:** `devcontainer-config/cc-exit-scan.sh:648-651`
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the outputs, the cache key (the top-level config's `realpath -m`), its per-snapshot lifetime, and contiguity of each cached range; does not cover forks other than the `git config` read (one `realpath` per call remains, and an included file is read again under each distinct top-level config).
**Legibility-target:** maintainer

See the `_snap_cfg_hooks` body quoted in Claim 6 (`:657-667`). Values are appended only inside `_snap_cfg_hooks_file`, and only during the top-level call that set `_snap_rhs`, so each range is contiguous:

```bash
# devcontainer-config/cc-exit-scan.sh:685-687
      core.hookspath)
        for ((k = _snap_rhs; k < ${#_snap_rhv[@]}; k++)); do [ "${_snap_rhv[k]}" != "$val" ] || continue 2; done
        _snap_rhv+=("$val") ;;
```

A cached entry is never empty (`"<start> <count>"`), so the `-z` test cannot cause a re-read. `_snap_rhseen` is `local` to each top-level call (`:661`) (paraphrased — no quote available because the claim's residue is the absence of a cross-config include cache, which is the absence of code).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:648-694`, `devcontainer-config/cc-exit-scan.sh:865`

---

## Claim 11: "Every value and every include is kept: includeIf conditions are not evaluated, all values are kept though git takes the last, and there is no depth cap (git dies past 10, so deeper is only an over-walk); a depth cap beside the seen set could drop a file first met deep in a chain git does not take."

**Location:** `devcontainer-config/cc-exit-scan.sh:652-655`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers includeIf not evaluated, all distinct non-empty values kept, no depth cap, and git's die past depth 10; does not cover empty values or include targets missing at launch, which are skipped (`[ -n "$val" ] || continue`, `[ -f "$t" ] || continue`).
**Legibility-target:** maintainer

```bash
# devcontainer-config/cc-exit-scan.sh:688-691
      include.path|includeif.*.path)
        t="$(_snap_path "$val" "$(dirname -- "$f")")"
        [ -f "$t" ] || continue
        _snap_cfg_hooks_file "$t" "$(realpath -m -- "$t" 2>/dev/null || printf '%s' "$t")" || return 1 ;;
```

No condition is parsed, and there is no depth variable. Git's die past 10 was executed (Claim 6). The deep-chain hazard was executed (Claim 5). A missing include created during the session is a new value, which becomes a new hooks-dir record (Claim 16), so the skip does not hide it.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:670-694`, `$FC/parts-e1d7d912.log`

---

## Claim 12: "Records nothing: _snap_entry_hooks walks the values."

**Location:** `devcontainer-config/cc-exit-scan.sh:655-656`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers `_snap_cfg_hooks` and `_snap_cfg_hooks_file` appending nothing to `_snap`; does not cover `_snap_fail`, which writes a reason to stderr on a read error.
**Legibility-target:** maintainer

Neither function contains a `_snap+=` line; their only side effects are `_snap_rhv`, `_snap_rhc`, `_snap_rhseen`, temp files and `_snap_fail 'could not read config %s: %s'` (`:680`). The records come from `_snap_hooks` via `_snap_entry_hooks` (`:718`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:657-694`, `devcontainer-config/cc-exit-scan.sh:712-722`

---

## Claim 13: "the core.hooksPath values of the configs git reads for that git dir, walked as git resolves them for a command run in <working tree> (a relative one: <working tree>/<value>). _snap_config walks a repo's values in one working tree per repo"

**Location:** `devcontainer-config/cc-exit-scan.sh:697-700`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers relative values resolved at `<wt>/<value>` (`_snap_path`) with `wt` the `.git` entry's directory, and `_snap_config` using one base per config; does not establish resolution when `core.worktree` moves the working tree (Claim 21).
**Legibility-target:** maintainer

`_snap_hooks "$(_snap_path "${_snap_rhv[k]}" "$wt")"` (`:718`). `_snap_path` gives `"$2/$1"` for a relative value (`:306`). `_snap_config` takes a single base, `[ -n "$base" ] || base="$(_snap_worktree_of "$f")"` (`:482`). Executed: the planted `<worktree>/.husky/_/pre-commit` ran on a host commit in the worktree (Claim 1).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:301-308`, `devcontainer-config/cc-exit-scan.sh:478-490`, `devcontainer-config/cc-exit-scan.sh:712-722`

---

## Claim 14: "The configs are its common dir's config (a linked worktree's private dir has none of its own) and its config.worktree (git reads that only under extensions.worktreeConfig; reading it always is an over-walk)."

**Location:** `devcontainer-config/cc-exit-scan.sh:702-705`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5 ignoring a `config` file in a linked worktree's private dir, and reading `config.worktree` only with `extensions.worktreeConfig`; does not cover other git versions.
**Legibility-target:** maintainer

Executed (`$FC/wtp`, 01:09Z, `git -C wt config core.hooksPath` after each step):
```
private config read? none
config.worktree w/o ext: none
config.worktree with ext: wtcfg
```
The loop reads exactly `"$c/config" "$g/config.worktree"` (`:715`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:712-722`; probe output captured verbatim above (printed to the terminal only)

---

## Claim 15: "The common dir comes from cc-gitdir.sh's gitdir_common, git's reading of the file; one it cannot read safely fails the snapshot."

**Location:** `devcontainer-config/cc-exit-scan.sh:705-707`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same coverage as Claim 4 (empty and non-regular commondir executed); does not establish the size and permission cases by execution.
**Legibility-target:** maintainer

`c="$(gitdir_common "$g")" || { _snap_fail …; return 1; }` (`:714`). The `return 1` propagates through `{ rc=1; break; }` (`:910`) to `[ "$rc" -eq 0 ] || return 1` (`:943`). The probe in Claim 4 showed snapshot rc=1.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:714`, `devcontainer-config/cc-exit-scan.sh:910`, `devcontainer-config/cc-exit-scan.sh:942-944`, `$FC/probe-cd.log`

---

## Claim 16: "The configs read here are recorded wherever _snap_config reaches them; where it does not (a container-form .git's git dir, a commondir outside the checkout), a value changed in the session names a hooks dir the launch snapshot did not walk, which is a finding."

**Location:** `devcontainer-config/cc-exit-scan.sh:707-710`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a container-form `.git`'s twin outside `.git/` whose `config.worktree` the session adds: no config record exists, but the new value's `hooksdir` record is a finding. Does not cover a changed value that resolves to a path string already recorded (no new record, but that dir was already walked), nor a commondir outside the checkout (not session-writable, so not probed).
**Legibility-target:** maintainer

Executed: `$FC/probe-cf.sh`, case A (01:11Z). The session writes `[core] hooksPath = hk` into the twin's `config.worktree` and plants `sub/e/hk/pre-commit`. 28dfcd3b gave rc=1, and the only changed records were `+ hooksdir …/ws/sub/e/hk  dir 755` and `+ hook …/ws/sub/e/hk/pre-commit` (no config line), so the finding comes from the hooks-dir record alone, as the comment says. `_snap_hooks` records the dir even when missing (`_snap_file hooksdir "$d"`, `:331`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:329-344`, `devcontainer-config/cc-exit-scan.sh:744-754`, `$FC/probe-cf.sh`, `$FC/probe-cf.log`

---

## Claim 17: "A core.worktree elsewhere is not followed (guide, \"Known routes it does not see\")."

**Location:** `devcontainer-config/cc-exit-scan.sh:710-711`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers `_snap_entry_hooks` (it never reads `core.worktree`) and the guide bullet's existence; does not say that `_snap_config` ignores `core.worktree` (it honours one in the same file, Claim 21).
**Legibility-target:** maintainer

`_snap_entry_hooks` uses only `"$wt"` = `${f%/*}` as the base (`:718`, `:910`). The guide bullet exists at `guides/cc-isolated-usage.md:470`.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:712-722`, `guides/cc-isolated-usage.md:470-474`

---

## Claim 18: "The file that sets it is first met at depth 10 of an includeIf chain git does not take, then through a plain include git does take."

**Location:** `test/cc-isolated-functions.bats:3176-3177`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the depth arithmetic of the chain the test builds; does not affect the test's effectiveness, which is executed in Claim 19.
**Legibility-target:** maintainer

The file that sets the value is `inc.cfg` (`printf '[core]\n\thooksPath = .inc-hooks\n' > "$SCAN_WS/.git/inc.cfg"`, `:3159`). The chain is `includeIf → a1.cfg` … `a9.cfg → x.cfg → inc.cfg`:

```bash
# test/cc-isolated-functions.bats:3180-3182
  for i in 1 2 3 4 5 6 7 8; do printf '[include]\n\tpath = a%d.cfg\n' $((i + 1)) > "$SCAN_WS/.git/a$i.cfg"; done
  printf '[include]\n\tpath = x.cfg\n' > "$SCAN_WS/.git/a9.cfg"
  printf '[include]\n\tpath = inc.cfg\n' > "$SCAN_WS/.git/x.cfg"
```

So `x.cfg` sits at depth 10 and `inc.cfg` at 11. The plain include also names `x.cfg`, not `inc.cfg` (`:3185`). The commit message (Claim 5) says it precisely: the depth-10 file is the one that *includes* the setter. Precise version: "The file that includes it is first met at depth 10 …".

**Evidence:** `test/cc-isolated-functions.bats:3159`, `test/cc-isolated-functions.bats:3176-3186`

---

## Claim 19: "The new bats case fails on the unfixed scan at its first [ \"$status\" -eq 1 ] and passes with the fix"; each part covers a distinct route (research §2, plan step 3)

**Location:** `docs/working/research-2026-10-25-exit-scan-r6-hookspath.md:79-80` (case at `test/cc-isolated-functions.bats:3143-3195`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the full case at HEAD (pass) and on d40e4bae and e1d7d912 (fail), plus each of its four parts run independently; does not cover cf15f4f9's scan.
**Legibility-target:** reviewer

Executed:
- `cd /workspace/.claude/wt-2026-10-25-exit-scan-r6-hookspath && LC_ALL= timeout 300 bats -f R6 test/cc-isolated-functions.bats` at 01:07:47Z: `ok 1 …`, exit 0.
- The full case on `$FC/tree-d40e4bae` failed at `line 3152` (the first `[ "$status" -eq 1 ]`). On `$FC/tree-e1d7d912` it failed at `line 3190` (the includeIf-chain part's status check).
- Parts run independently (`$FC/parts.bats.tail`, each from a fresh repo): d40e4bae gave `status=0` for all four parts (direct, relative include, absolute include, includeIf chain). e1d7d912 gave `status=1` for parts 1-3 and `status=0` for part 4. 28dfcd3b gave `status=1` for all four, and part 4's host commit ran the hook.

So each part would fail on d40e4bae's scan, and the includeIf-chain part fails on e1d7d912's.

**Evidence:** `test/cc-isolated-functions.bats:3143-3195`, `$FC/r6-head.log`, `$FC/full-d40e4bae.log`, `$FC/full-e1d7d912.log`, `$FC/parts-d40e4bae.log`, `$FC/parts-e1d7d912.log`, `$FC/parts-28dfcd3b.log`, `$FC/parts.bats.tail`

---

## Claim 20: Coverage sentence: "A relative `core.hooksPath` in a repo's config (husky's `.husky/_`), set there or in a file it includes, is walked in every working tree that uses that config: the repo's own and each linked worktree or other `.git` entry in the checkout (an agent worktree runs `<worktree>/.husky/_`)."

**Location:** `guides/cc-isolated-usage.md:337-342`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same coverage and residue as Claim 9 (the `core.worktree`-elsewhere and unfound-`.git` cases are listed separately in the guide).
**Legibility-target:** user

The quoted sentence matches the code path quoted in Claim 9 (`cc-exit-scan.sh:909-910`) and the executed cases in Claims 19, 16 and 26.

**Evidence:** `guides/cc-isolated-usage.md:337-342`, `devcontainer-config/cc-exit-scan.sh:909-910`, `$FC/parts-28dfcd3b.log`

---

## Claim 21: "A relative `core.hooksPath` is walked in the directory holding each `.git` entry; a repo or linked worktree whose `core.worktree` (in `config.worktree`, say) names another directory runs hooks from `<that directory>/<path>`, which is not walked."

**Location:** `guides/cc-isolated-usage.md:470-474`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the gap for the per-entry walk and for the checkout's own repo. Does not hold for an embedded repo whose `core.worktree` sits in the same `config` as its `core.hooksPath`: there `_snap_config` walks `<core.worktree>/<path>`.
**Legibility-target:** user

`_snap_worktree_of` honours a `core.worktree` read from the same config file, except for the checkout's own git and common dir:

```bash
# devcontainer-config/cc-exit-scan.sh:349-353
  if [ "$gd" = "$_snap_gd" ] || [ "$gd" = "$_snap_common" ]; then
    printf '%s' "$_snap_ws"
  elif [ -f "$1" ] && v="$(cd / && git --no-pager config --file "$1" --no-includes --get core.worktree 2>/dev/null)"; then
    _snap_path "$v" "$gd"
```
(excerpt ends :353; enclosing `_snap_worktree_of` continues to :358 — read)

Executed: `timeout 120 bash $FC/probe-cwt.sh $FC/tree-28dfcd3b $FC` (01:13Z). An embedded `ws/emb` has `core.worktree ../../other` and `core.hooksPath .hk` in `.git/config`. The session plants `ws/other/.hk/pre-commit`. Result: scan rc=1 naming it, and the host commit printed `HOOK-RAN`. So the bullet over-states the gap; it errs toward listing more as unseen. Its "(in `config.worktree`, say)" names the case that is really open. Precise version: "…whose `core.worktree` is set in `config.worktree`, or for the checkout itself, …".

**Evidence:** `devcontainer-config/cc-exit-scan.sh:346-358`, `guides/cc-isolated-usage.md:470-474`, `$FC/probe-cwt.sh`, `$FC/probe-cwt.log`

---

## Claim 22: The boundary paragraph: "The boundary (Q-172 [2]): a route that needs only ordinary setup plus what a session can write in the checkout is one to close, and stays listed here until it is; a route that needs some unusual state present at launch stays here by design. Push with `cc-push`, which runs no git in the checkout, whatever the scan says."

**Location:** `guides/cc-isolated-usage.md:416-420`
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers consistency with Q-172 [2] ("Close only routes that need no state planted before launch; list the rest as known routes; the guide says to push with cc-push") under the research doc's stated reading of "planted" as unusual; does not establish that the author endorses that reading (it is the research doc's interpretation, §1).
**Legibility-target:** user

Q-172's option [2]: `| **[2] Set a boundary** | Close only routes that need no state planted before launch; list the rest as known routes; the guide says to push with cc-push |` (`docs/working/questions-archive.md:4209`). The answer file says only `Q-172: [2]` (`docs/human-author/answers-10-22-26.txt:1`). Q-173's note uses the same reading for R6: "needs only state a session can write in the checkout, so it is inside the boundary" (`docs/working/questions.md:162`).

**Evidence:** `docs/working/questions-archive.md:4196-4214`, `docs/working/questions.md:155-163`, `docs/working/research-2026-10-25-exit-scan-r6-hookspath.md:13-21`

---

## Claim 23: "**A local path holding `@[`, or starting with `[`, present at launch.** Git cuts such a path at the `]` (`./decoy@[x]plant` pushes to `./]plant`); the scan walks the path as written. This holds for a remote URL, an undefined remote name, a legacy remotes file and an `insteadOf` result (Q-168 rubric R4)."

**Location:** `guides/cc-isolated-usage.md:456-459`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers git 2.39.5 pushing `./decoy@[x]plant` (as a URL and as a remote's URL) to `./]plant`. Does not re-execute the undefined-name, legacy-file and insteadOf forms, or the scan's literal walk (both rest on Q-168 rubric R4, which records them end to end).
**Legibility-target:** user

Executed (`$FC/r4`, 01:15Z, both `./]plant` and `./decoy@[x]plant` as bare repos, only `]plant` with a pre-receive hook): `git push './decoy@[x]plant' HEAD:refs/heads/t` printed `remote: PLANT-HOOK-RAN`. A remote `r` with that URL did the same. Q-168 rubric: "git runs `host_end` on plain local paths: `./decoy@[x]plant` pushes to `./]plant`; the scan walks the literal string (rc=0, hook ran; via url, name, legacy URL, insteadOf)" (`git show 75d08a94:docs/reviews/code-review-rubric-2026-10-15-q168-exit-scan-remote-names.md`, row R4).

**Evidence:** `guides/cc-isolated-usage.md:456-459`; probe output quoted above (terminal only); Q-168 rubric row R4 at 75d08a94

---

## Claim 24: "**Relative remotes and receive hooks resolved against one base (not closed yet).**" (A14, R3, A16)

**Location:** `guides/cc-isolated-usage.md:460-469`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git pushing `origin = ../up.git` from a linked worktree to `<worktree>/../up.git` (A14), git running a receive hook from `<repo>/.git/<rel>` on `git push .` (A16), and the scan resolving a `--separate-git-dir` repo's paths in its git dir (R3, static). Does not re-execute the undefined-name and legacy-URL forms of A14.
**Legibility-target:** user

- A14, executed (`$FC/a14`, 01:15Z): a repo with a worktree `wts/a` and `origin = ../up.git`. `git push origin` from `wts/a` printed `remote: WT-RELATIVE-REMOTE-HOOK` from `wts/up.git`.
- A16, executed (`$FC/r4/w`): `core.hooksPath .hk`, with hooks at both `.git/.hk/pre-receive` and `.hk/pre-receive`. `git push . HEAD:refs/heads/z` printed `remote: GITDIR-HK-RAN`. `_snap_config` resolves the value only at `base` (`:494`).
- R3, static: for a separate git dir `gd` not named `.git` with no `core.worktree`, `_snap_worktree_of` falls to `printf '%s' "$gd"` (`:357`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:346-358`, `devcontainer-config/cc-exit-scan.sh:492-494`; probe outputs quoted above (terminal only)

---

## Claim 25: Container-form bullet: "the scan maps it to `<checkout>/<path>` and walks only your own config there and that git dir's relative `core.hooksPath` in the worktree, not the git dir itself (and nothing at all when the line ends in a CR, which git strips: Q-168 tech-debt T1)"

**Location:** `guides/cc-isolated-usage.md:491-496`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what is walked for a container-form `.git` and the CR case. "relative" understates it: absolute (and `~/`) values in that git dir's configs are walked too since 28dfcd3b. Does not cover the repaired state.
**Legibility-target:** user

The per-entry walk runs every value, not only relative ones (`:715-720`, quoted in Claim 7). Case B of `$FC/probe-cf.sh` showed an absolute value in the twin's `config.worktree` walked (rc=1). The CR clause holds: `_snap_container_target` builds `g="$_snap_ws/${line#…}"` from `_snap_first_line`, which keeps a trailing CR. With the CR, `[ -d "$g" ] || return 0` leaves `g` empty, and both `_snap_host_config` and `_snap_entry_hooks` are skipped (`[ -z "$g" ] || …`, `:908-910`). Precise version: "…and that git dir's `core.hooksPath` values (a relative one in the worktree)…".

**Evidence:** `devcontainer-config/cc-exit-scan.sh:228-238`, `devcontainer-config/cc-exit-scan.sh:744-754`, `devcontainer-config/cc-exit-scan.sh:905-910`, `$FC/probe-cf.log`

---

## Claim 26: "R3's `core.hooksPath` half is already resolved by this change's per-entry walk (probe below)" / "R3's hooksPath half, same shape … `old rc=0` (hook ran), `new rc=1`."

**Location:** `docs/working/research-2026-10-25-exit-scan-r6-hookspath.md:49-50`, `:82-83`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a `--separate-git-dir` embedded repo with a relative `core.hooksPath`; does not cover R3's remote half (still open, as stated).
**Legibility-target:** reviewer

Executed: `timeout 120 bash $FC/probe-r3.sh $FC/tree-<rev> $FC` (01:13Z). Setup: `git init --separate-git-dir <ws>/sgd ws/vendor/e`, `core.hooksPath .hk`, plant `vendor/e/.hk/pre-commit`. d40e4bae: `scan rc=0`, 0 mentions, `HOOK-RAN`. 28dfcd3b: `scan rc=1`, 1 mention, `HOOK-RAN`.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:909-910`, `$FC/probe-r3.sh`, `$FC/probe-r3.log`

---

## Claim 27: Sort table and its notes (R6/R3/A14/A16 in; R4, T1 out; R5/A15 "not reachable on main"; T3 not a route; "R6 was never on that list on main")

**Location:** `docs/working/research-2026-10-25-exit-scan-r6-hookspath.md:23-43`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers each row's factual premise against the code and Q-168's rubric rows, R5's "your own `pushDefault` names are never walked" on main, and R6's absence from d40e4bae's known-routes list; does not verdict the in/out judgments themselves (design rationale).
**Legibility-target:** reviewer

`_snap_host_config` dispatches only `url.*.insteadof|url.*.pushinsteadof`, `remote.*.url|remote.*.pushurl`, `core.hookspath`, `core.attributesfile` and includes (`:620-645`), so an own-config `remote.pushdefault` is never walked. The rubric rows match the table's descriptions (R3, R4, R6, A14, A16, A18 at 75d08a94). A18 says "none of the split routes is in the guide's known routes". Line 40 rests on that row (paraphrased — no quote available because the claim is the absence of an R6 bullet in d40e4bae's known-routes list; grep of `git show d40e4bae:guides/cc-isolated-usage.md` for "hooksPath" and "worktree" finds no such route). The guide's new bullets match the table's "now in the guide" sentence (`guides/cc-isolated-usage.md:456-474`, `:491-496`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:605-646`, `docs/working/research-2026-10-25-exit-scan-r6-hookspath.md:23-43`, Q-168 rubric at 75d08a94 rows R3-R6, A14-A18

---

## Claim 28: Pre-mortem rows 1, 3, 4, 5 and 7

**Location:** `docs/working/research-2026-10-25-exit-scan-r6-hookspath.md:123-129`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Row 1 ("The main working tree already ignored core.worktree") holds by `_snap_worktree_of` returning `_snap_ws` for the checkout's git/common dir. Rows 4, 5 and 7 hold. Row 3's wording "dropped a file first met at depth 10" is imprecise (see below). Does not re-verify row 1's pass-2 end-to-end probe.
**Legibility-target:** reviewer

Row 3 says the depth cap "dropped a file first met at depth 10 of an untaken `includeIf` chain". The dropped file was `inc.cfg` at depth 11. The depth-10 file `x.cfg` was read and marked seen, which then blocked the plain include (Claim 5, executed). The same imprecision recurs in §5 "dropped a deep-first file" (`:139-140`). Row 4: `"$g/config.worktree"` is read for each entry (`:715`). Row 5: read failures call `_snap_fail` and return 1 (`:679-682`). Row 7: Claim 4, executed.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:346-353`, `devcontainer-config/cc-exit-scan.sh:670-722`, `docs/working/research-2026-10-25-exit-scan-r6-hookspath.md:123-140`, `$FC/parts-e1d7d912.log`, `$FC/probe-cd.log`

---

## Claim 29: §5 review-loop changes, including "an empty or non-regular `commondir` in an embedded repo now refuses the launch (git dies there too, rc=128)" and "100 entries x 100 values, 11.3 s vs 1.3 s"

**Location:** `docs/working/research-2026-10-25-exit-scan-r6-hookspath.md:134-153`
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the commondir refusal (executed), the L1 value-walk cost (re-run: 1.52 s vs 13.35 s at load about 3, so 11.3 s vs 1.3 s is the same order), and the absolute-value fix (Claim 7). Does not reconcile 11.3 s with the pass-2 review's own L1 baseline (5.99 s, shim, measured on e1d7d912's code, not 28dfcd3b's).
**Legibility-target:** reviewer

Executed: `timeout 280 bash $FC/perf/probe-noshim.sh $FC/perf hp 100 100` gave `hp old … lines=312 … secs=1.52`, `hp new … lines=10312 … secs=13.35`. Commondir: Claim 4.

**Evidence:** `$FC/perf/perf.log`, `$FC/probe-cd.log`, `docs/reviews/r6-hookspath-p2-performance-review-2026-10-25.md:29`

---

## Claim 30a: Guide timing: "about 30 ms more for each embedded repository or linked worktree"

**Location:** `guides/cc-isolated-usage.md:440-441`
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the per-entry cost at 28dfcd3b in this WSL2 container (about 29.4 ms per embedded repo, about 29.4 ms per linked worktree with a relative repo `core.hooksPath`); does not measure a host.
**Legibility-target:** user

Executed: `timeout 300 bash $FC/probe-time-run.sh $FC/tree-<rev> $FC` (01:12Z, load about 2.6), with 100 embedded repos (`ws-emb`) and 100 linked worktrees (`ws-wt`):
```
tree-28dfcd3b ws-emb 2.863 / 2.906 / 3.056
tree-28dfcd3b ws-wt  2.908 / 1.875 / 2.971
```
The mean is 29.4 ms per entry in both cases (python3; the 1.875 ws-wt outlier excluded).

**Evidence:** `$FC/probe-time.sh`, `$FC/probe-time-run.sh`, `$FC/probe-time.log`

## Claim 30b: Research cost paragraph: "100 embedded repos 2.32 s -> 2.85 s … about 5 ms more per repo … 100 entries x 100 includes 2.06 s -> 2.71 s … The guide's per-repo figure moves from about 29 ms to about 30 ms"

**Location:** `docs/working/research-2026-10-25-exit-scan-r6-hookspath.md:155-161`
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** The measured pairs reproduce (2.34 → 2.94 s, +6.0 ms/repo; 2.00 → 2.54 s), and the new 30 ms matches a fresh measurement. Does not reconcile the old 29 ms with the measured baseline.
**Legibility-target:** reviewer

The per-repo baseline measured here on d40e4bae is 23.4 ms, not 29 ms. 29 ms is the guide's figure from bfe82925 (2026-09-27, an older scan). The measured increase is about 25% (ratio 1.255, python3). Applied to the old 29 ms that would be about 36 ms; applied to the current baseline it gives about 29-30 ms. So "29 → 30" mixes a stale baseline with a fresh total and reads as a +1 ms change when the change is about +5-6 ms. The resulting guide figure (Claim 30a) is right. Precise version: "the per-entry cost is now about 30 ms (about 23 ms before; the old 29 ms figure predates this measurement)".

**Evidence:** `$FC/probe-time.log`, `$FC/perf/perf.log`; `git log -S'about 29 ms' -- guides/cc-isolated-usage.md` (bfe82925, 28dfcd3b)

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 2** (commit cf15f4f9): "includes" at cf15f4f9 skipped absolute/`~/` include paths and was depth-capped; fixed in e1d7d912/28dfcd3b (historical message, nothing to edit).
- **Claim 18** (`test/cc-isolated-functions.bats:3176`): the depth-10 file is `x.cfg`, which *includes* the setter `inc.cfg` (depth 11). Say "The file that includes it".
- **Claim 21** (`guides/cc-isolated-usage.md:470-474`): an embedded repo whose `core.worktree` is in the same `config` as its hooksPath *is* walked (`_snap_worktree_of`; probe rc=1). The open case is `core.worktree` in `config.worktree` (or the checkout itself).
- **Claim 25** (`guides/cc-isolated-usage.md:494`): "that git dir's relative `core.hooksPath`" — since 28dfcd3b absolute/`~/` values there are walked too.
- **Claim 28** (`docs/working/research-2026-10-25-exit-scan-r6-hookspath.md:125`, also `:139-140`): the depth cap dropped the depth-11 include of a file first met at depth 10, not the depth-10 file.
- **Claim 30b** (`docs/working/research-2026-10-25-exit-scan-r6-hookspath.md:160-161`): "29 ms → 30 ms" pairs a stale September baseline with a fresh total; the measured change is about +5-6 ms on about 23 ms.

### Unverifiable
(none; the host check named in every commit's `Host-tool-tested: no` trailer remains un-run and is out of this pass's reach)

---

## Goal-Alignment Note

- **Success criterion (verbatim):** "A markdown report saved to docs/reviews/r6-hookspath-p3-code-fact-check-report-r2.md in the worktree, structured per the code-fact-check skill, `Commit: 28dfcd3b` first line."
- **Answered:** All five requested claim groups were checked. Commit messages: Claims 1-8. Code comments: Claims 9-17. The bats case, executed per part on d40e4bae, e1d7d912 and 28dfcd3b: Claims 18-19. Guide edits: Claims 20-25 and 30a. Research doc: Claims 19 and 26-30b. No Incorrect or Stale claim; six Mostly accurate, all imprecise wording, none hiding a route (Claims 21 and 25 err toward under-claiming coverage).
- **Out of scope:** A14, R3's remote half, A16, R4 and a `core.worktree` elsewhere as unbuilt routes (the change does not make them worse); the host check; code-quality judgments.
- **Escalate:** none.
- **Questions/Decisions:** none. Hallucination-pattern log: no fabrication found, no entry appended.
