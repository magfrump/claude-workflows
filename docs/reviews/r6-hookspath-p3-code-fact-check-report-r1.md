Commit: 28dfcd3b

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-2026-10-25-exit-scan-r6-hookspath (branch fix/exit-scan-r6-hookspath)
**Scope:** `git diff d40e4bae..HEAD` (HEAD 28dfcd3b): commit messages cf15f4f9, e1d7d912, 28dfcd3b; `devcontainer-config/cc-exit-scan.sh`; `docs/working/research-2026-10-25-exit-scan-r6-hookspath.md`; `guides/cc-isolated-usage.md`; `test/cc-isolated-functions.bats` (R6 case). Review reports and the rubric are inputs, not claim sources.
**Checked:** 2026-10-25 (replicate r1 of 3, final confirming pass)
**Total claims checked:** 34
**Summary:** 27 verified, 7 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Hallucination pattern log (`docs/reviews/hallucination-patterns.md`) read first. No claim matches a logged pattern. Every symbol named in the claims (`_snap_cfg_hooks`, `_snap_cfg_hooks_file`, `_snap_entry_hooks`, `gitdir_common`, `_snap_worktree_of`, `_snap_first_line`, `_snap_path`, `_snap_hooks`, override-log rows 134/135, Q-172 [2], Q-168 rubric R3/R4/R6/A14/A16/A18) exists.

Execution provenance (all runs: cwd as named, git 2.39.5, bash 5.2, `GIT_CONFIG_NOSYSTEM=1`, `GIT_CONFIG_GLOBAL` a scratch file or `/dev/null`, `LC_ALL` unset). Scratch dir `S=/tmp/claude-1000/-workspace/89c2ddf7-2b6b-41d6-b07b-ae5871fb9429/scratchpad/2026-10-25-exit-scan-r6-hookspath/fc-p3-r1`:

- **E1** `LC_ALL= timeout 300 bats -f R6 test/cc-isolated-functions.bats`, cwd the worktree, 2026-10-26T01:07:07Z, exit 0 (`ok 1`). Output: `$S/bats-r6-head.log`.
- **E2** `timeout 900 bash $S/run-split.sh`: the R6 case split into four independent cases (`$S/split-tests.bats.part`: direct, relative include, absolute include, includeIf chain), each run against copies of the scan at d40e4bae, e1d7d912 and 28dfcd3b (`$S/t-<rev>/`); plus the same against cf15f4f9. Started 2026-10-26T01:08Z; exit 1 by design (the old revisions fail). Output: `$S/bats-split-{d40e4bae,e1d7d912,28dfcd3b,cf15f4f9}.log`. Result: d40e4bae parts 1-4 all `status=0` (fail); cf15f4f9 parts 1-2 pass, 3-4 `status=0`; e1d7d912 parts 1-3 pass, part 4 `status=0`; 28dfcd3b parts 1-4 pass. An extra case R6p5 (a git depth probe that is not an assertion) recorded `fatal: exceeded maximum include depth (10)` for the plain chain a1..a9 -> x -> inc.
- **E3** `timeout 300 bash $S/probes.sh`, cwd `$S`, 2026-10-26T01:11Z, exit 0. Output: `$S/probes.log`. P1 R3 hooksPath half (old rc=0, HOOK-RAN; new rc=1); P2 core.worktree elsewhere (new rc=0, HOOK-RAN); P3 config.worktree read only with extensions.worktreeConfig; P4 container-form git dir changed in session (rc=1, `+ hooksdir .../vendor/e/.b`, `+ hook .../vendor/e/.b/pre-commit`).
- **E4** timing `timeout 1200 bash $S/timing.sh` (2026-10-26T01:09Z-01:10Z, load 1.9) -> `$S/timing.log`; `timeout 600 bash $S/timing-inc.sh` (01:13:14Z, load 2-3) -> `$S/timing-inc.log`; `timeout 600 bash $S/timing-val.sh` (01:15:12Z, load 2.7) -> `$S/timing-val.log`. All exit 0. Other replicates ran concurrently; figures are indicative.
- **E5** git behavior probes inline (no script file), 2026-10-26T01:11-01:17Z, exit 0: `git ls-remote './decoy@[x]plant'` under GIT_TRACE ran `git upload-pack ']plant'`; `git push -q . HEAD:refs/heads/other` in a non-bare repo with `core.hooksPath=.hk` printed `remote: GITDIR-PRERECEIVE-RAN` (the `.git/.hk` hook, not `.hk`); `git status` with an empty `commondir` rc=128. Output captured in this session's transcript only (inline commands); scratch dirs `$S/r4`, `$S/a16`, `$S/cd`.

No process I started is still running (checked with `ps` at 01:17:13Z).

---

## Claim 1: "a hook planted at <worktree>/.husky/_ passed the scan (rc=0) and ran on the next host commit there. The working-tree .git loop now also reads the configs git uses for each entry's git dir ... and walks a relative core.hooksPath at <entry dir>/<value>"

**Location:** `commit:cf15f4f9` (message body, para 1)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the rc=0 on d40e4bae and rc=1 after the change for a direct relative `core.hooksPath` with a linked worktree present at launch, and that host git runs the hook; does not establish cf15f4f9's include handling (Claim 2).
**Legibility-target:** maintainer reading branch history

E2: `d40e4bae ... not ok 1 R6p1 direct / # status=0`; cf15f4f9 and later `ok 1 R6p1 direct / # status=1`. E1's case ends with `git -C "$STD_WT" -c commit.gpgsign=false commit -q --allow-empty -m x` then `[ -e "$TEST_TMPDIR/ran/hook-pre-commit" ]` (`test/cc-isolated-functions.bats:3194-3195`), which passed.

**Evidence:** `$S/bats-split-d40e4bae.log`, `$S/bats-split-cf15f4f9.log`, `test/cc-isolated-functions.bats:3143-3195`

---

## Claim 2: "reads the configs git uses for each entry's git dir (common config, config.worktree, includes)"

**Location:** `commit:cf15f4f9` (message body, para 1)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers include following as built at cf15f4f9; does not bear on HEAD, where e1d7d912 and 28dfcd3b changed it.
**Legibility-target:** maintainer reading branch history

At cf15f4f9 every value starting `/` or `~/`, include paths included, was skipped before dispatch: `case "$val" in ""|/*|"~/"*) continue ;; esac   # walked once, by _snap_config` (cf15f4f9 `_snap_tree_hooks`). So "includes" held for relative include paths only; E2 shows cf15f4f9 `not ok 3 R6p3 include absolute / # status=0`. The next commit (e1d7d912) states and fixes this. The precise version: "includes named by a relative path".

**Evidence:** `git show cf15f4f9:devcontainer-config/cc-exit-scan.sh` (`_snap_tree_hooks`), `$S/bats-split-cf15f4f9.log`

---

## Claim 3: "R4, R5, A15 and T1 out and now listed as known routes in the guide ... Path A of four options (per-entry hooksPath walk) dominated"

**Location:** `commit:cf15f4f9` (message body, para 2 and Notes)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the guide and research doc as of cf15f4f9; does not establish HEAD's guide, where e1d7d912 dropped the R5/A15 bullet (disclosed in e1d7d912's message and research row 30).
**Legibility-target:** maintainer reading branch history

`git show cf15f4f9:guides/cc-isolated-usage.md` lines 463-464 hold "an embedded repo reached through a `gitdir:` file (R5), or a `**` not bounded by `/` on both sides, which git treats as `*` (A15)" and line 485 the T1 qualifier. The research doc's design table has four options, A-D (`docs/working/research-2026-10-25-exit-scan-r6-hookspath.md:90-95`), and "A dominates: Path A, decide and continue." (`:97`).

**Evidence:** `git show cf15f4f9:guides/cc-isolated-usage.md:463-485`, `docs/working/research-2026-10-25-exit-scan-r6-hookspath.md:90-97`

---

## Claim 4: "the first version skipped absolute and ~/ include paths, so a relative core.hooksPath set in an include named by an absolute path still passed the scan in a linked worktree (rc=0, hook ran). The abs/~ skip now applies to the hooksPath value only; the bats case covers an absolute include.path. _snap_entry_hooks reads the common dir through cc-gitdir.sh's gitdir_common ... an unreadable or empty commondir fails the snapshot."

**Location:** `commit:e1d7d912` (message body, paras 1-2)
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the cf15f4f9 rc=0 for an absolute include, the e1d7d912 code shape, the bats coverage and the commondir failure path; "hook ran" for the absolute-include layout rests on git resolving the same relative value (shown end to end in the includeIf part), not a separate commit in that layout.
**Legibility-target:** maintainer reading branch history

E2: cf15f4f9 `not ok 3 R6p3 include absolute / # status=0`; e1d7d912 `ok 3`. At e1d7d912 the skip sits on the value: `case "$val" in /*|"~/"*) ;; *) _snap_hooks "$wt/$val" || return 1 ;; esac ;;` and includes always recurse: `# Any include, absolute or not: its relative hooksPath still resolves in <wt>.` The bats case sets `git -C "$SCAN_WS" config include.path "$SCAN_WS/.git/inc.cfg"` (`test/cc-isolated-functions.bats:3170`). At HEAD: `c="$(gitdir_common "$g")" || { _snap_fail 'cannot read the commondir file in %s' "$g"; return 1; }` (`devcontainer-config/cc-exit-scan.sh:714`), and `gitdir_common` returns 1 for `[ "$s" -gt 0 ] && [ "$s" -le 4096 ] || return 1` and `[ -f "$c" ] && [ -r "$c" ] || return 1` (`devcontainer-config/cc-gitdir.sh:58-60`). Git itself dies on an empty commondir (E5: rc=128).

**Evidence:** `$S/bats-split-cf15f4f9.log`, `$S/bats-split-e1d7d912.log`, `devcontainer-config/cc-exit-scan.sh:712-721`, `devcontainer-config/cc-gitdir.sh:50-69`, `test/cc-isolated-functions.bats:3165-3174`

---

## Claim 5: "on main your own pushDefault names are not walked, the existing bullet"

**Location:** `commit:e1d7d912` (message body, para 3)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers `_snap_host_config`'s dispatch at HEAD (unchanged from d40e4bae); does not establish the Q-168 branch's behavior.
**Legibility-target:** maintainer

`_snap_host_config` acts only on `url.*.insteadof|url.*.pushinsteadof`, `remote.*.url|remote.*.pushurl`, `core.hookspath`, `core.attributesfile` and `include.path|includeif.*.path` (`devcontainer-config/cc-exit-scan.sh:620-644`); no `remote.pushdefault`/`branch.*` arm. The guide's bullet lists "a path-valued `pushRemote`/`pushDefault` in your own config" (`guides/cc-isolated-usage.md:454`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:605-646`, `guides/cc-isolated-usage.md:453-455`

---

## Claim 6: "a depth cap beside a seen set let a file first met at depth 10 of an includeIf chain git does not take hide its include from the plain include git does take (rc=0, hook ran)"

**Location:** `commit:28dfcd3b` (message body, para 1)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers e1d7d912's behavior on the bats layout (x.cfg read at depth 10 and marked seen, its include inc.cfg refused at 11, x.cfg then skipped on the plain include); does not establish other chain shapes.
**Legibility-target:** maintainer reading branch history

e1d7d912's `_snap_tree_hooks` had `[ "$depth" -le 10 ] || return 0` before `_snap_seen["t:$real:$wt"]=1`. E2: e1d7d912 `not ok 4 R6p4 includeIf chain / # status=0`; 28dfcd3b `ok 4` including the host commit that runs the hook.

**Evidence:** `git show e1d7d912:devcontainer-config/cc-exit-scan.sh` (`_snap_tree_hooks`), `$S/bats-split-e1d7d912.log`, `$S/bats-split-28dfcd3b.log`

---

## Claim 7: "the walk re-read each include set once per .git entry (100 entries x 100 includes: 46.6 s against 2.2 s) ... 100 x 100 includes now 2.71 s; 100 embedded repos about 5 ms more each."

**Location:** `commit:28dfcd3b` (message body, paras 1-2)
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the order of magnitude and the per-repo increment; does not reproduce the exact seconds (different tree shape and host load here).
**Legibility-target:** maintainer

E4, 100 linked worktrees sharing a config with 100 includes: d40e4bae 2079/3294/3274 ms, e1d7d912 54042 ms, 28dfcd3b 4054/4154/4081 ms (load 2-3; the pass-2 harness used N `.git` files naming one git dir at load 0.4-0.9). The multiplicative cost is gone; HEAD is ~1.3-2x the old scan, not ~20x. 100 embedded repos: d40e4bae 2436/2330/2367 ms, 28dfcd3b 2884/2828/2894 ms, about 5 ms more each.

**Evidence:** `$S/timing-inc.log`, `$S/timing.log`, `docs/reviews/r6-hookspath-p2-performance-review-2026-10-25.md:23-27`

---

## Claim 8: "_snap_cfg_hooks now collects every core.hooksPath value of a config and its includes once per snapshot (cached by real path, no depth cap: git dies past 10, so deeper is an over-walk), and _snap_entry_hooks walks each value in the entry's directory, absolute values included ... performance p2-2 ... kept as an availability-only cost under override-log row 134."

**Location:** `commit:28dfcd3b` (message body, para 2 and Notes)
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the cache, the absent cap, git's include-depth death, absolute-value walking and the override-log row's existence; does not establish that row 134 was written for this N x V shape (it was written for per-repo cost).
**Legibility-target:** maintainer

Cache: `if [ -z "${_snap_rhc["$real"]:-}" ]; then` ... `_snap_rhc["$real"]="$_snap_rhs $((${#_snap_rhv[@]} - _snap_rhs))"` (`devcontainer-config/cc-exit-scan.sh:660-664`), declared once per snapshot `local -A _snap_rhc=()` (`:865`). No depth variable in `_snap_cfg_hooks_file` (`:670-702`). Git: E2's R6p5 `fatal: exceeded maximum include depth (10) while including`. Absolute values: `_snap_hooks "$(_snap_path "${_snap_rhv[k]}" "$wt")"` (`:718`), with `_snap_path` returning `/*` and `~/` values as absolute (`:301-309`). Override log row 134: "Scan cost grows with embedded repos/hooks (~29 ms each) ... Defer (documented limit)" (`docs/reviews/override-log.md:134`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:657-721,865`, `docs/reviews/override-log.md:134`, `$S/bats-split-28dfcd3b.log`

---

## Claim 9: "A relative core.hooksPath in repo config, set directly or through an include, is walked in each working tree that uses that config, every linked worktree and `.git` entry in the checkout included (_snap_entry_hooks)."

**Location:** `devcontainer-config/cc-exit-scan.sh:61-65`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the main tree (via `_snap_config`) and every `.git` entry the working-tree find reaches (direct, relative include, absolute include, untaken-includeIf chain); does not establish a working tree that `core.worktree` puts elsewhere (a listed guide route, Claim 19) or `.git` entries the find does not reach.
**Legibility-target:** maintainer

The loop: `[ -z "$g" ] || _snap_entry_hooks "$g" "${f%/*}" || { rc=1; break; }` (`devcontainer-config/cc-exit-scan.sh:910`) inside `while ... read -r -d '' f; do [ "$f" != "$_snap_ws/.git" ] || continue` over `_snap_find "$list" "$_snap_ws" -mindepth 2 -name .git` (`:898-901`). E1/E2 pass all four layouts at HEAD.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:892-912`, `$S/bats-r6-head.log`, `$S/bats-split-28dfcd3b.log`

---

## Claim 10: "sets _snap_rhs and _snap_rhn, where in _snap_rhv the core.hooksPath values of <config> and every file it includes start, and how many there are. Each config's set is read once per snapshot and cached by its real path in _snap_rhc, so N worktrees sharing one config cost one read, not N."

**Location:** `devcontainer-config/cc-exit-scan.sh:648-651`
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the cache keyed by the top-level config's real path; does not establish that an include shared by two different top-level configs is read once (it is read once per top-level config, since `_snap_rhseen` is local to each fill), and the `realpath` fork still runs per call.
**Legibility-target:** maintainer

```
devcontainer-config/cc-exit-scan.sh:657-667
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

`_snap_rhv` is only appended to (`_snap_rhv+=("$val")`, `:692`), so a cached start index stays valid. An empty set caches as `"<s> 0"`, a non-empty string, so it is not re-read. E4's 100-worktree x 100-include run (4.1 s vs 54 s at e1d7d912) is consistent with one read per config.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:657-702`, `$S/timing-inc.log`

---

## Claim 11: "Every value and every include is kept: includeIf conditions are not evaluated, all values are kept though git takes the last"

**Location:** `devcontainer-config/cc-exit-scan.sh:652-653`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the dispatch in `_snap_cfg_hooks_file`; "every value" excludes exact duplicates within one config's set (dropped, harmless) and empty values; an include target that is not a regular file is skipped (git reads nothing there either).
**Legibility-target:** maintainer

```
devcontainer-config/cc-exit-scan.sh:689-697
    case "$key" in
      core.hookspath)
        for ((k = _snap_rhs; k < ${#_snap_rhv[@]}; k++)); do [ "${_snap_rhv[k]}" != "$val" ] || continue 2; done
        _snap_rhv+=("$val") ;;
      include.path|includeif.*.path)
        t="$(_snap_path "$val" "$(dirname -- "$f")")"
        [ -f "$t" ] || continue
        _snap_cfg_hooks_file "$t" "$(realpath -m -- "$t" 2>/dev/null || printf '%s' "$t")" || return 1 ;;
    esac
```

(excerpt ends :697; enclosing `_snap_cfg_hooks_file` continues to :702 — read.)

**Evidence:** `devcontainer-config/cc-exit-scan.sh:670-702`

---

## Claim 12: "there is no depth cap (git dies past 10, so deeper is only an over-walk); a depth cap beside the seen set could drop a file first met deep in a chain git does not take."

**Location:** `devcontainer-config/cc-exit-scan.sh:653-656`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5's include-depth death and the e1d7d912 regression shape; cycles are bounded by `_snap_rhseen`, not checked for pathological DAG cost here.
**Legibility-target:** maintainer

E2 R6p5: `plain-include chain: status=128 out=fatal: exceeded maximum include depth (10) while including`. E2 R6p4 failed on e1d7d912 (capped) and passes at HEAD (uncapped). Cycle guard: `[ -z "${_snap_rhseen["$real"]:-}" ] || return 0` (`:673`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:670-675`, `$S/bats-split-e1d7d912.log`, `$S/bats-split-28dfcd3b.log`

---

## Claim 13: "Records nothing: _snap_entry_hooks walks the values."

**Location:** `devcontainer-config/cc-exit-scan.sh:656-657`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers `_snap_cfg_hooks` and `_snap_cfg_hooks_file`; records come only from `_snap_hooks` called in `_snap_entry_hooks`.
**Legibility-target:** maintainer

Neither function appends to `_snap` (paraphrased — no quote available because the claim covers absence of code: no `_snap+=` in `:657-702`); failures go through `_snap_fail 'could not read config %s: %s'` (`:679`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:657-702`

---

## Claim 14: "the core.hooksPath values of the configs git reads for that git dir, walked as git resolves them for a command run in <working tree> (a relative one: <working tree>/<value>). _snap_config walks a repo's values in one working tree per repo"

**Location:** `devcontainer-config/cc-exit-scan.sh:697-700`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers resolution via `_snap_path` against `${f%/*}` and `_snap_config`'s single base; the `core.worktree` exception is stated in the same comment (Claim 17).
**Legibility-target:** maintainer

`_snap_hooks "$(_snap_path "${_snap_rhv[k]}" "$wt")"` (`:718`); `_snap_config` dedups by file alone, `[ -z "${_snap_seen["c:$real"]:-}" ] || return 0` (`:483`), with `base="$(_snap_worktree_of "$f")"` (`:481`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:478-485,712-721`

---

## Claim 15: "The configs are its common dir's config (a linked worktree's private dir has none of its own) and its config.worktree (git reads that only under extensions.worktreeConfig; reading it always is an over-walk). The common dir comes from cc-gitdir.sh's gitdir_common, git's reading of the file; one it cannot read safely fails the snapshot."

**Location:** `devcontainer-config/cc-exit-scan.sh:702-706`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5's config.worktree gating and the commondir failure path; does not establish git's behavior for a `config` file planted in a private dir (the scan records it via `_snap_gitdir` regardless).
**Legibility-target:** maintainer

E3 P3: `ext off: unset`, `ext on:  .wch`. Code: `for cfg in "$c/config" "$g/config.worktree"; do` (`:715`). `gitdir_common` trims trailing CR/LF as git does (`case "$line" in *$'\n'|*$'\r') line="${line%?}"`, `cc-gitdir.sh:65`) and returns 1 when unreadable (Claim 4); the caller fails with `_snap_fail 'cannot read the commondir file in %s'` (`:714`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:712-721`, `devcontainer-config/cc-gitdir.sh:50-69`, `$S/probes.log`

---

## Claim 16: "The configs read here are recorded wherever _snap_config reaches them; where it does not (a container-form .git's git dir, a commondir outside the checkout), a value changed in the session names a hooks dir the launch snapshot did not walk, which is a finding."

**Location:** `devcontainer-config/cc-exit-scan.sh:706-710`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a container-form git dir outside `.git/` whose config's `core.hooksPath` is changed in the session; the claim is as narrow as written: a change to a value naming a dir the launch snapshot did walk produces no hooksdir record (a plant inside such a dir is still recorded).
**Legibility-target:** maintainer

E3 P4: launch records naming `zz-nonexist-q7/gd/config`: 0; one record for `vendor/e/.a`; after `git config --file .../gd/config core.hooksPath .b` and a plant, `git_exit_scan` printed `+ hooksdir .../vendor/e/.b  dir 755` and `+ hook .../vendor/e/.b/pre-commit ...` with rc=1.

**Evidence:** `$S/probes.log`, `devcontainer-config/cc-exit-scan.sh:744-756,906-910`

---

## Claim 17: "A core.worktree elsewhere is not followed (guide, "Known routes it does not see")."

**Location:** `devcontainer-config/cc-exit-scan.sh:710-711`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a linked worktree with `core.worktree` in `config.worktree`; the guide bullet exists (Claim 30).
**Legibility-target:** maintainer

E3 P2: `28dfcd3b scan rc=0` then `HOOK-RAN .../cw/other/.hk`.

**Evidence:** `$S/probes.log`, `guides/cc-isolated-usage.md:470-474`

---

## Claim 18: Sort table rows R6, A14, A16, R4 (launch state and what the session writes)

**Location:** `docs/working/research-2026-10-25-exit-scan-r6-hookspath.md:25-29`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers git's behavior for A16 (receive hook from the git dir) and R4 (`./decoy@[x]plant` -> `]plant`) and the R6 route; A14's end-to-end route was not re-run here (Q-168 rubric A14, static `_snap_worktree_of`), nor the R4 "adding one in the session is a C record" clause.
**Legibility-target:** maintainer

A16: E5 `remote: GITDIR-PRERECEIVE-RAN` (the hook at `.git/.hk/pre-receive` ran, the one at `.hk/pre-receive` did not). R4: E5 `git upload-pack ']plant'`. R6: Claim 1.

**Evidence:** `docs/working/research-2026-10-25-exit-scan-r6-hookspath.md:25-29`, `git show 75d08a94:docs/reviews/code-review-rubric-2026-10-15-q168-exit-scan-remote-names.md:20,43,45`

---

## Claim 19: "R3 | in, follow-up | Launch state is an embedded repo made with `--separate-git-dir` plus a relative remote or `core.hooksPath` in it"

**Location:** `docs/working/research-2026-10-25-exit-scan-r6-hookspath.md:26`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the row's follow-up classification against what this change closes; does not establish the remote half (not re-probed).
**Legibility-target:** next implementer of the group (1) follow-up

The row lists `core.hooksPath` as part of a follow-up, but this change already closes that half (E3 P1: `d40e4bae scan rc=0`, `28dfcd3b scan rc=1`), as the same doc says at `:49-50` ("R3's `core.hooksPath` half is already resolved by this change's per-entry walk"). Tighten the row to "a relative remote, name or legacy URL in it (the hooksPath half closed here)".

**Evidence:** `docs/working/research-2026-10-25-exit-scan-r6-hookspath.md:26,47-50,82-83`, `$S/probes.log`

---

## Claim 20: "R3's hooksPath half, same shape ... `old rc=0` (hook ran), `new rc=1`." / "R3's remote half (`_snap_worktree_of` returns the separate git dir)"

**Location:** `docs/working/research-2026-10-25-exit-scan-r6-hookspath.md:49-50,82-83`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the hooksPath half end to end and the `_snap_worktree_of` mechanism for a git dir not named `.git` with no `core.worktree`; does not run the remote half end to end.
**Legibility-target:** next implementer of the group (1) follow-up

E3 P1: `d40e4bae scan rc=0` / `HOOK-RAN .../vendor/e/.hk`; `28dfcd3b scan rc=1`. `_snap_worktree_of` falls through to `printf '%s' "$gd"` when the dir is not `.git` and no `core.worktree` is set (`devcontainer-config/cc-exit-scan.sh:357-361`).

**Evidence:** `$S/probes.log`, `devcontainer-config/cc-exit-scan.sh:346-362`

---

## Claim 21: "The new bats case fails on the unfixed scan at its first `[ "$status" -eq 1 ]` and passes with the fix; it ends with the real host commit running the hook."

**Location:** `docs/working/research-2026-10-25-exit-scan-r6-hookspath.md:79-80`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers d40e4bae and HEAD; per-part failure on intermediate revisions is Claim 31.
**Legibility-target:** maintainer

E2 d40e4bae part 1 `# status=0` (first status assertion); E1 passes at HEAD; last lines `git -C "$STD_WT" ... commit` and `[ -e "$TEST_TMPDIR/ran/hook-pre-commit" ]` (`test/cc-isolated-functions.bats:3194-3195`).

**Evidence:** `$S/bats-split-d40e4bae.log`, `$S/bats-r6-head.log`

---

## Claim 22: Pre-mortem row 1: "pass-2 security probed it end to end (per-worktree `core.worktree` via `config.worktree`, rc=0, hook ran) ... The main working tree already ignored `core.worktree` (not a regression)."

**Location:** `docs/working/research-2026-10-25-exit-scan-r6-hookspath.md:123`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the linked-worktree case and `_snap_worktree_of`'s main-tree branch; does not probe the main tree's `core.worktree` end to end.
**Legibility-target:** maintainer

E3 P2 reproduces rc=0 and the hook running. Main tree: `if [ "$gd" = "$_snap_gd" ] || [ "$gd" = "$_snap_common" ]; then printf '%s' "$_snap_ws"` comes before the `core.worktree` branch (`devcontainer-config/cc-exit-scan.sh:350-353`).

**Evidence:** `$S/probes.log`, `devcontainer-config/cc-exit-scan.sh:346-362`

---

## Claim 23: Pre-mortem row 3: "pass 2 found a depth cap beside the seen set dropped a file first met at depth 10 of an untaken `includeIf` chain (both rc=0, hook ran)"

**Location:** `docs/working/research-2026-10-25-exit-scan-r6-hookspath.md:125`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the depth arithmetic of the bats layout under e1d7d912's cap; the rc=0 and fix are Verified (Claims 6, 12).
**Legibility-target:** maintainer

Off by one on which file: in the layout, x.cfg is first met at depth 10 (config 0, a1..a9 at 1-9, x.cfg at 10) and is read and marked seen; the dropped file is inc.cfg at depth 11 (`[ "$depth" -le 10 ] || return 0` in e1d7d912). 28dfcd3b's commit message has it right ("a file first met at depth 10 ... hide its include"). Precise version: "a file first met at depth 10 of an untaken includeIf chain hid its include".

**Evidence:** `test/cc-isolated-functions.bats:3176-3184`, `git show e1d7d912:devcontainer-config/cc-exit-scan.sh` (`_snap_tree_hooks`), `$S/bats-split-e1d7d912.log`

---

## Claim 24: Pre-mortem rows 2, 4, 5, 6, 7 ("Covered: ...")

**Location:** `docs/working/research-2026-10-25-exit-scan-r6-hookspath.md:124,126-129`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the code paths each row names; row 2 (worktree added in session) and row 6 (symlinked or unlistable hooks dir) were not executed here.
**Legibility-target:** maintainer

Row 2: the exit snapshot's find reaches a new `.git` and calls `_snap_entry_hooks` (`:910`); `_snap_wrel` still emits W records (`:494`). Row 4: `"$g/config.worktree"` (`:715`). Row 5: `_snap_fail 'could not read config %s: %s'` (`:679`). Row 6: `_snap_hooks` follows `_snap_linkdir` and fails on `cannot enter` (`:331-336`). Row 7: `gitdir_common` (`:714`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:329-344,670-721,898-912`

---

## Claim 25: "Pass 2 security, informational: an empty or non-regular `commondir` in an embedded repo now refuses the launch (git dies there too, rc=128)"

**Location:** `docs/working/research-2026-10-25-exit-scan-r6-hookspath.md:143-144`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the empty case on both sides; the non-regular case is static only.
**Legibility-target:** maintainer

E5: `git status` with an empty `commondir` rc=128 (`fatal: failed to read .../commondir`). Scan: `[ -f "$c" ] && [ -r "$c" ] || return 1` (`cc-gitdir.sh:58`) then `_snap_fail` (`cc-exit-scan.sh:714`).

**Evidence:** `devcontainer-config/cc-gitdir.sh:55-69`, `devcontainer-config/cc-exit-scan.sh:714`

---

## Claim 26: "Pass 2 performance M1 ... (100 entries x 100 includes: 46.6 s vs 2.2 s). Fixed by caching each config's value set once per snapshot."

**Location:** `docs/working/research-2026-10-25-exit-scan-r6-hookspath.md:145-147`
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** As Claim 7.
**Legibility-target:** maintainer

E4: e1d7d912 54042 ms vs 28dfcd3b ~4.1 s vs d40e4bae 2.1-3.3 s on 100 linked worktrees x 100 includes. The perf review records 46.57 s vs 2.18 s (`r6-hookspath-p2-performance-review-2026-10-25.md:27`).

**Evidence:** `$S/timing-inc.log`

---

## Claim 27: "Pass 2 performance L1: every value is walked in every worktree (git takes the last): 100 entries x 100 values, 11.3 s vs 1.3 s."

**Location:** `docs/working/research-2026-10-25-exit-scan-r6-hookspath.md:148-149`
**Type:** Performance / Reference
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the figure's source and order of magnitude; the "kept" rationale is not checked.
**Legibility-target:** maintainer

The bullet is attributed to Pass 2 performance L1, whose figure is "5.99 s and 10,312 snapshot lines, against 1.31 s" (`docs/reviews/r6-hookspath-p2-performance-review-2026-10-25.md:79`), measured on e1d7d912. 11.3 s is a later number with no cited source (same in the rubric's C1 row). E4 at HEAD: 13403/12736/14005 ms vs d40e4bae 2369-2499 ms, 10512 lines. So 11.3 s is plausible for HEAD, but it is not the review's figure. Say "re-measured at HEAD: 11.3 s vs 1.3 s (the review measured 6.0 s on e1d7d912)".

**Evidence:** `$S/timing-val.log`, `docs/reviews/r6-hookspath-p2-performance-review-2026-10-25.md:29,79`

---

## Claim 28: Section 5 cost numbers: "100 embedded repos 2.32 s -> 2.85 s (3 runs each; about 5 ms more per repo ...); 100 entries x 100 includes 2.06 s -> 2.71 s ... The guide's per-repo figure moves from about 29 ms to about 30 ms and now names linked worktrees."

**Location:** `docs/working/research-2026-10-25-exit-scan-r6-hookspath.md:155-161`
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** The embedded-repo numbers and the "about 5 ms more" are verified; the include figure is reproduced only in order of magnitude (Claim 7); the "29 -> 30 ms" step is the imprecise part.
**Legibility-target:** maintainer, user reading the guide

E4: 100 embedded repos 2436/2330/2367 ms -> 2884/2828/2894 ms (matches 2.32 -> 2.85). The same paragraph measures +5 ms per repo, yet calls the guide's change "from about 29 ms to about 30 ms" (+1 ms). On this host the per-repo total is ~28 ms at HEAD (~23 ms at d40e4bae), so "about 30 ms" is right as an absolute figure, but the old guide's 29 came from a different host and the move is closer to +20% than +3%. Precise version: "the per-entry cost rises about 5 ms (~20%); the guide's rounded 'about 30 ms' still holds".

**Evidence:** `$S/timing.log`, `docs/reviews/r6-hookspath-p2-performance-review-2026-10-25.md:103,114`

---

## Claim 29: "A relative `core.hooksPath` in a repo's config (husky's `.husky/_`), set there or in a file it includes, is walked in every working tree that uses that config: the repo's own and each linked worktree or other `.git` entry in the checkout (an agent worktree runs `<worktree>/.husky/_`)."

**Location:** `guides/cc-isolated-usage.md:337-342`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** As Claim 9; a working tree moved by `core.worktree` is excluded and listed at `:470-474`.
**Legibility-target:** user reading the guide

E1/E2 (all four layouts at HEAD), E3 P1 (embedded separate-git-dir repo).

**Evidence:** `$S/bats-split-28dfcd3b.log`, `$S/probes.log`

---

## Claim 30: "The boundary (Q-172 [2]): a route that needs only ordinary setup plus what a session can write in the checkout is one to close, and stays listed here until it is; a route that needs some unusual state present at launch stays here by design. Push with `cc-push`, which runs no git in the checkout"

**Location:** `guides/cc-isolated-usage.md:416-420`
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers consistency with Q-172 [2] and the research doc's reading; the wording is the research doc's reading of "planted", not Q-172's literal text; cc-push's "runs no git in the checkout" is taken from Q-172's own read-list, not re-verified in `cc-push.sh`.
**Legibility-target:** user reading the guide

Q-172 [2]: "Close only routes that need no state planted before launch; list the rest as known routes; the guide says to push with cc-push" (`docs/working/questions-archive.md:4209`). The research doc defines "planted" as "a value no ordinary workflow produces" (`research...md:15`). The guide sentence matches that reading.

**Evidence:** `docs/working/questions-archive.md:4196-4214`, `docs/working/research-2026-10-25-exit-scan-r6-hookspath.md:13-21`

---

## Claim 31: "about 2–4 s per snapshot on a ~400k-file repository, and about 30 ms more for each embedded repository or linked worktree"

**Location:** `guides/cc-isolated-usage.md:439-441`
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the per-entry figure for plain embedded repos and plain linked worktrees on this host; the 400k-file figure was not re-measured; include-heavy or many-value configs cost more (research section 5; the "A slow scan" route covers planted volume).
**Legibility-target:** user reading the guide

E4: base repo 35-37 ms; 100 linked worktrees 2981/2850/2778 ms (~28 ms each); 100 embedded repos 2884/2828/2894 ms (~28 ms each).

**Evidence:** `$S/timing.log`

---

## Claim 32: R4 bullet, "not closed yet" bullet and core.worktree bullet

**Location:** `guides/cc-isolated-usage.md:456-474`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git's `]plant` cut, the A16 git-dir receive hook, R3's base (`_snap_worktree_of`), and the core.worktree route end to end; A14's `../up.git` landing is path arithmetic (`<ws>/.claude/worktrees/a/../up.git` is inside the checkout), not run.
**Legibility-target:** user reading the guide

R4: E5 `git upload-pack ']plant'`. A16: E5 `remote: GITDIR-PRERECEIVE-RAN`. R3 remote base: Claim 20. core.worktree: E3 P2 rc=0, HOOK-RAN. The R4 bullet's "remote URL, an undefined remote name, a legacy remotes file and an `insteadOf` result" matches Q-168 rubric R4 "(rc=0, hook ran; via url, name, legacy URL, insteadOf)".

**Evidence:** `$S/probes.log`, `git show 75d08a94:docs/reviews/code-review-rubric-2026-10-15-q168-exit-scan-remote-names.md:20`

---

## Claim 33: "the scan maps it to `<checkout>/<path>` and walks only your own config there and that git dir's relative `core.hooksPath` in the worktree, not the git dir itself (and nothing at all when the line ends in a CR, which git strips: Q-168 tech-debt T1)"

**Location:** `guides/cc-isolated-usage.md:493-497`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what is walked for a container-form `.git` at HEAD; the CR clause is static.
**Legibility-target:** user reading the guide

"Not the git dir itself" holds: E3 P4 found 0 launch records naming the twin's `gd/config`. But since 28dfcd3b the walk takes every `core.hooksPath` value, absolute and `~/` included (`_snap_hooks "$(_snap_path "${_snap_rhv[k]}" "$wt")"`, `devcontainer-config/cc-exit-scan.sh:718`), so "only ... relative `core.hooksPath`" understates it. Precise version: "that git dir's `core.hooksPath` values (relative ones in the worktree)". CR clause: `_snap_first_line` keeps a trailing CR (`LC_ALL=C IFS= read -r line < "$1"`, `:236`), so `_snap_container_target`'s `[ -d "$g" ] || return 0` (`:754`) returns nothing.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:228-238,744-756,712-721`, `$S/probes.log`

---

## Claim 34: R6 bats case: each part would fail on d40e4bae, the includeIf-chain part on e1d7d912; and its comment "The file that sets it is first met at depth 10 of an includeIf chain git does not take, then through a plain include git does take."

**Location:** `test/cc-isolated-functions.bats:3143-3196` (comment `:3176-3177`)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** The per-part failures are verified (all four parts fail on d40e4bae, part 4 on e1d7d912, parts 3-4 on cf15f4f9, all pass at HEAD). The comment's depth is the imprecise part. Run as independent cases, not in the combined case's state order.
**Legibility-target:** maintainer reading the test

E2 results as listed in the provenance. The comment: inc.cfg (the file that sets `core.hooksPath`) is named by x.cfg, which sits at depth 10; inc.cfg itself would be read at depth 11 (git dies on the same chain when taken: E2 R6p5). Precise version: "The file that includes it is first met at depth 10 ...". This is the only part not Verified.

**Evidence:** `$S/bats-split-d40e4bae.log`, `$S/bats-split-cf15f4f9.log`, `$S/bats-split-e1d7d912.log`, `$S/bats-split-28dfcd3b.log`, `test/cc-isolated-functions.bats:3174-3196`

---

## Claims Requiring Attention

### Incorrect
None.

### Stale
None.

### Mostly Accurate
- **Claim 2** (`commit:cf15f4f9`): "includes" covered only relative include paths at cf15f4f9; disclosed and fixed in e1d7d912 (history, nothing to edit).
- **Claim 19** (`docs/working/research-2026-10-25-exit-scan-r6-hookspath.md:26`): the R3 row lists `core.hooksPath` as a follow-up, but this change closes that half (the doc's `:49-50` says so); limit the row to the remote half.
- **Claim 23** (`docs/working/research-2026-10-25-exit-scan-r6-hookspath.md:125`): the file "first met at depth 10" (x.cfg) was read; the one dropped was its include (inc.cfg, depth 11).
- **Claim 27** (`docs/working/research-2026-10-25-exit-scan-r6-hookspath.md:148-149`): 11.3 s is not the pass-2 L1 figure (5.99 s on e1d7d912); it fits a HEAD re-measure (12.7-14.0 s here), so label it that way.
- **Claim 28** (`docs/working/research-2026-10-25-exit-scan-r6-hookspath.md:160-161`): "29 ms to about 30 ms" reads as +1 ms; the same paragraph measures +5 ms (~20%). The absolute "about 30 ms" holds.
- **Claim 33** (`guides/cc-isolated-usage.md:493-495`): the container-form walk now includes absolute/`~/` `core.hooksPath` values too, not only relative ones.
- **Claim 34** (`test/cc-isolated-functions.bats:3176`): "the file that sets it is first met at depth 10" should be "the file that includes it"; inc.cfg is at depth 11.

### Unverifiable
None.

## Goal-Alignment Note

- **Success criterion (verbatim):** "A markdown report saved to docs/reviews/r6-hookspath-p3-code-fact-check-report-r1.md in the worktree, structured per the code-fact-check skill, `Commit: 28dfcd3b` first line."
- **Answered:** All five named claim groups were checked against the code and against git 2.39.5. The R6 bats case passes. Each of its parts fails on d40e4bae, and the includeIf part fails on e1d7d912. No claim is Incorrect or Stale. Seven are Mostly accurate: wording and number precision only. None changes the security reading of the change.
- **Out of scope:** A14/R3-remote/A16/R4/core.worktree as findings (listed routes, not regressions). The Q-168 T3 row (`research...md:33`) concerns the held branch's `_snap_drid` key and was not re-verified on main. The 400k-file timing was not re-measured. The pass-2 performance harness was not re-run (to avoid loading the host during sibling replicates); my own harness reproduced the shapes.
- **Escalate:** None. The host check (`Live-verified: no`) is still outstanding, as the commits themselves state.
