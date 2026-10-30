Commit: 28dfcd3b

# Code Fact-Check Report

**Repository:** claude-workflows (worktree `wt-2026-10-25-exit-scan-r6-hookspath`, branch `fix/exit-scan-r6-hookspath`)
**Scope:** `git diff d40e4bae..28dfcd3b`: `devcontainer-config/cc-exit-scan.sh`, `test/cc-isolated-functions.bats`, `guides/cc-isolated-usage.md`, `docs/working/research-2026-10-25-exit-scan-r6-hookspath.md`, commit messages cf15f4f9, e1d7d912, 28dfcd3b. Final confirming pass (p3), replicate r3.
**Checked:** 2026-10-25
**Total claims checked:** 34
**Summary:** 26 verified, 5 mostly accurate, 2 stale, 0 incorrect, 1 unverifiable

Execution provenance. All runs used git 2.39.5 and bash 5.2. Each run had `GIT_CONFIG_NOSYSTEM=1`, `GIT_CONFIG_GLOBAL` set to an empty scratch file, and `LC_ALL=` (unset). Every run was under `timeout`. Raw logs are in `$SCR` = `/tmp/claude-1000/-workspace/89c2ddf7-2b6b-41d6-b07b-ae5871fb9429/scratchpad/2026-10-25-exit-scan-r6-hookspath/fc-p3-r3/`:

| Log | Command (cwd) | Exit | Time (-07:00) |
|---|---|---|---|
| `bats-r6.log` | `LC_ALL= bats -f R6 test/cc-isolated-functions.bats` (worktree root) | 0 (1/1 ok) | 18:07:41 |
| `split-run.log` | `bash $SCR/split.sh`: the R6 case split into its four parts (`split.bats`), run against `git archive` exports of d40e4bae, e1d7d912 and 28dfcd3b | 0 (script) | 18:08:42 |
| `split-cf.log` | the same four parts against cf15f4f9 | 0 (script) | 18:08:58 |
| `gitprobe.log` | `bash $SCR/gitprobe.sh` (git behaviour probes) | 0 | 18:09:26 |
| `scanprobe-28dfcd3b.log`, `scanprobe-d40e4bae.log` | `bash $SCR/scanprobe.sh $SCR/<rev>` (scan probes P1-P5) | 0 | 18:10:22 |
| `r4probe.log` | `bash $SCR/r4probe.sh` | 0 | 18:11:03 |
| `a14probe.log` | `bash $SCR/a14probe.sh` | 0 | 18:11:30 |
| `cwprobe.log` | `bash $SCR/cwprobe.sh $SCR/28dfcd3b` | 0 | 18:11:53 |
| `perf/timing.log`, `perf/timing-e1d.log`, `perf/timing-hp.log` | `bash ./probe.sh $SCR/perf <inc\|emb\|hp> N M` (cwd `$SCR/perf`; a copy of the pass-2 performance harness) | 0 | 18:12:46-18:15:59 |
| `wttime.log` | `bash $SCR/wttime.sh` (100 linked worktrees) | 0 | 18:14:24 |

Load average during the timing runs was 2.1-3.1. Treat the timings as indicative (one or two runs each).

Hallucination-pattern log read. No claim here matches a logged pattern. The closest family, numeric tallies in commit messages, was checked by re-measuring (claims 4, 6).

---

## Claim 1: cf15f4f9 "a hook planted at <worktree>/.husky/_ passed the scan (rc=0) and ran on the next host commit there"

**Location:** `commit cf15f4f9` (message body)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers d40e4bae's scan with a direct relative `core.hooksPath` and an in-checkout linked worktree present at launch. Does not establish the host-installed launcher path (`cc-isolated` end to end), which the container cannot run.
**Legibility-target:** maintainer

On d40e4bae, split part 1 printed `status=0` and then `not ok 1 R6split1 direct` (split-run.log). HEAD's combined case ends with `git -C "$STD_WT" ... commit` and `[ -e "$TEST_TMPDIR/ran/hook-pre-commit" ]` (`test/cc-isolated-functions.bats:3194-3195`), and that passes (bats-r6.log). So a commit in the worktree does run the planted hook.

**Evidence:** `test/cc-isolated-functions.bats:3143-3196`; $SCR/split-run.log; $SCR/bats-r6.log

---

## Claim 2: cf15f4f9 "reads the configs git uses for each entry's git dir (common config, config.worktree, includes) ... (_snap_entry_hooks, _snap_tree_hooks)"; "R4, R5, A15 and T1 out and now listed as known routes in the guide"

**Location:** `commit cf15f4f9` (message body)
**Type:** Behavioral / Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the message read against HEAD. Does not establish more than "Mostly accurate at its own commit".
**Legibility-target:** reviewer

At cf15f4f9 the walk did not follow every include. It skipped absolute and `~/` include paths: `case "$val" in ""|/*|"~/"*) continue ;; esac   # walked once, by _snap_config` (cf15f4f9 `_snap_tree_hooks`). Split part 3 (absolute include) gave `status=0` on cf15f4f9 (split-cf.log).

`_snap_tree_hooks` no longer exists at HEAD. It was replaced by `_snap_cfg_hooks`/`_snap_cfg_hooks_file` (`devcontainer-config/cc-exit-scan.sh:657,670`).

The R5/A15 guide bullet was dropped in e1d7d912. That commit's message says so ("the R5/A15 bullet is dropped").

Commit messages cannot change. Later commits supersede this one explicitly, so no fix is needed.

**Evidence:** `git show cf15f4f9:devcontainer-config/cc-exit-scan.sh` (`_snap_tree_hooks`); `devcontainer-config/cc-exit-scan.sh:648-721`; $SCR/split-cf.log

---

## Claim 3: e1d7d912 "the first version skipped absolute and ~/ include paths, so a relative core.hooksPath set in an include named by an absolute path still passed the scan in a linked worktree (rc=0, hook ran)"; "an unreadable or empty commondir fails the snapshot"; gitdir_common is "git's reading, CR/LF trimmed"

**Location:** `commit e1d7d912` (message body)
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the absolute-include regression on cf15f4f9, the 0-byte commondir case, and the reader. Does not cover a commondir holding only a newline. That case does not fail the snapshot: `gitdir_common` returns `<dir>/`. Git rejects that repository too ("not a git repository", gitprobe.log (h)), so it is not a false clean.
**Legibility-target:** maintainer

- **Absolute include on cf15f4f9:** split part 3 gave `status=0` (split-cf.log).
- **Empty commondir:** scan probe P3 on HEAD gave `snap rc=1 err=cannot read the commondir file in ...` (scanprobe-28dfcd3b.log).
- **The reader:** `gitdir_common` trims trailing line breaks with `case "$line" in *$'\n'|*$'\r') line="${line%?}"` (`devcontainer-config/cc-gitdir.sh:64-66`). It refuses empty and unreadable files with `[ -f "$c" ] && [ -r "$c" ] || return 1` and `[ "$s" -gt 0 ] && [ "$s" -le 4096 ] || return 1` (`cc-gitdir.sh:58-60`).
- **Git's own behaviour:** git 2.39.5 dies on an empty commondir: `empty rc=128 fatal: failed to read ...commondir` (gitprobe.log (h)).

**Evidence:** `devcontainer-config/cc-gitdir.sh:55-69`; `devcontainer-config/cc-exit-scan.sh:712-714`; $SCR/split-cf.log; $SCR/scanprobe-28dfcd3b.log; $SCR/gitprobe.log

---

## Claim 4: e1d7d912 "The abs/~ skip now applies to the hooksPath value only"

**Location:** `commit e1d7d912` (message body)
**Type:** Behavioral / Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the claim against HEAD. It was accurate at e1d7d912: `case "$val" in /*|"~/"*) ;; *) _snap_hooks "$wt/$val"`.
**Legibility-target:** reviewer

At HEAD every value goes through `_snap_hooks "$(_snap_path "${_snap_rhv[k]}" "$wt")"` (`devcontainer-config/cc-exit-scan.sh:717`), so absolute and `~/` values are walked too. Scan probe P5 on HEAD walked an absolute value held in a container-form git dir: `hooksdir.*abs-hk` count 1. The count was 0 on d40e4bae. 28dfcd3b's message records this change ("absolute values included"), so the history is consistent.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:712-721`; $SCR/scanprobe-28dfcd3b.log; $SCR/scanprobe-d40e4bae.log

---

## Claim 5: 28dfcd3b "a depth cap beside a seen set let a file first met at depth 10 of an includeIf chain git does not take hide its include from the plain include git does take (rc=0, hook ran)"

**Location:** `commit 28dfcd3b` (message body)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers e1d7d912's scan with the bats chain shape. Does not establish other chain shapes.
**Legibility-target:** maintainer

On e1d7d912 the chain is `includeIf.gitdir:/nomatch/` to `a1..a9`, then `x.cfg`, then `inc.cfg`. Split part 4 gave `status=0`, then `not ok 4` (split-run.log), while parts 1-3 passed.

The mechanism, from reading e1d7d912's code: `x.cfg` is met at depth 10, which passes `[ "$depth" -le 10 ]`, and is marked seen. Its include `inc.cfg` would sit at depth 11, so the cap returns 0 for it. When the plain `include.path x.cfg` is reached later, `x.cfg` is already in `_snap_seen["t:$real:$wt"]` and is skipped. HEAD part 4 confirms the route is live: the host commit runs the hook.

**Evidence:** `git show e1d7d912:devcontainer-config/cc-exit-scan.sh` (`_snap_tree_hooks`); `test/cc-isolated-functions.bats:3176-3195`; $SCR/split-run.log

---

## Claim 6: 28dfcd3b timing figures: "100 entries x 100 includes: 46.6 s against 2.2 s"; "100 x 100 includes now 2.71 s; 100 embedded repos about 5 ms more each"

**Location:** `commit 28dfcd3b` (message body)
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers order of magnitude on this container under load 2-3, one or two runs per configuration. Does not establish host timings.
**Legibility-target:** maintainer

Measured with the pass-2 harness copy:

| Case | Old (d40e4bae) | New | Claimed |
|---|---|---|---|
| inc N=M=100, e1d7d912 | 0.89 s | 51.86 s | 46.6 s vs 2.2 s |
| inc N=M=100, HEAD | 2.04 s and 0.86 s | 2.62 s and 2.68 s | 2.71 s |
| emb N=100, HEAD | 2.30-2.31 s | 2.66-2.73 s | about 5 ms more each |

The emb rows work out to +3.6 to +4.3 ms per repo; the research doc measured +5.3 ms. Both fit "about 5 ms".

**Evidence:** $SCR/perf/timing.log; $SCR/perf/timing-e1d.log

---

## Claim 7: 28dfcd3b "_snap_cfg_hooks now collects every core.hooksPath value of a config and its includes once per snapshot (cached by real path, no depth cap: git dies past 10, so deeper is an over-walk), and _snap_entry_hooks walks each value in the entry's directory, absolute values included"

**Location:** `commit 28dfcd3b` (message body)
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the cache for the top-level config. Does not cover include files reached from two different top-level configs: `_snap_rhseen` is local to each top-level build, so such a file is read once per top-level config.
**Legibility-target:** maintainer

- **Cache:** probe P4 counted `git config` calls naming `inc.cfg`. It was 2 with one linked worktree and 2 with six (one read by `_snap_config`, one by the cache), against 1 and 1 on d40e4bae.
- **Git dies past 10:** git 2.39.5 accepts a 10-file chain (`N=10 rc=0 out=deep10`) and dies on 11 (`fatal: exceeded maximum include depth (10)`, rc 128).
- **An untaken deeper chain does not die:** a 12-deep `includeIf.gitdir:/nomatch/` chain gave `rc=1 out=[]`.
- **Absolute values:** probe P5 (claim 4).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:657-667,712-721`; $SCR/scanprobe-28dfcd3b.log; $SCR/gitprobe.log

---

## Claim 8: Header "A relative core.hooksPath in repo config, set directly or through an include, is walked in each working tree that uses that config, every linked worktree and `.git` entry in the checkout included (_snap_entry_hooks)"

**Location:** `devcontainer-config/cc-exit-scan.sh:61-65`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `.git` entries found by `_snap_find "$list" "$_snap_ws" -mindepth 2 -name .git` (`:892`) and the main tree via `_snap_config`. Two things are outside it. First, a working tree whose `core.worktree` names another directory (claim 25 and the guide's route). Second, linked worktrees outside the checkout, which the comment's "in the checkout" excludes. Absolute values are also walked; the comment is silent on them, which is harmless.
**Legibility-target:** maintainer

The loop calls `[ -z "$g" ] || _snap_entry_hooks "$g" "${f%/*}"` (`:910`) for each found entry. Bats parts 1-4 pass at HEAD for direct, relative-include, absolute-include and deep-chain values.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:859-912`; $SCR/split-run.log

---

## Claim 9: `_snap_cfg_hooks` "sets _snap_rhs and _snap_rhn ... Each config's set is read once per snapshot and cached by its real path in _snap_rhc, so N worktrees sharing one config cost one read, not N"

**Location:** `devcontainer-config/cc-exit-scan.sh:648-651`
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers top-level config caching keyed by `realpath -m`. Does not cover shared include files under different top-level configs (claim 7's scope).
**Legibility-target:** maintainer

The cache works as described: `real="$(realpath -m -- "$1" ...)"; if [ -z "${_snap_rhc["$real"]:-}" ]; then ... _snap_rhc["$real"]="$_snap_rhs $((${#_snap_rhv[@]} - _snap_rhs))"` (`:658-664`). A missing file still caches as `"<s> 0"`, which is non-empty.

The slice is contiguous. Paraphrased — no quote available because this follows from the absence of any nested `_snap_cfg_hooks` call inside `_snap_cfg_hooks_file` (checked by reading `:670-694`). P4 read counts are in claim 7.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:657-694`; $SCR/scanprobe-28dfcd3b.log

---

## Claim 10: `_snap_cfg_hooks` "Every value and every include is kept: includeIf conditions are not evaluated, all values are kept though git takes the last, and there is no depth cap (git dies past 10, so deeper is only an over-walk); a depth cap beside the seen set could drop a file first met deep in a chain git does not take. Records nothing"

**Location:** `devcontainer-config/cc-exit-scan.sh:652-656`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the include and value handling. Duplicate values within one set are dropped (`[ "${_snap_rhv[k]}" != "$val" ] || continue 2`, `:686`), which is harmless.
**Legibility-target:** maintainer

- **Includes:** `include.path|includeif.*.path)` recurses for any existing target, with no condition check (`:688-691`).
- **Git takes the last value:** `get: [second]`, and `RAN-second` ran on a commit (gitprobe.log (g)).
- **Depth claims:** claims 5 and 7.
- **Records nothing:** the function only writes temp files under `$_snap_tmp/t.*`; it never appends to `$_snap` (`:670-694`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:670-694`; $SCR/gitprobe.log

---

## Claim 11: `_snap_entry_hooks` "walked as git resolves them for a command run in <working tree> (a relative one: <working tree>/<value>) ... a linked worktree ... shares that config but runs hooks from its own tree"

**Location:** `devcontainer-config/cc-exit-scan.sh:697-702`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers linked worktrees with no `core.worktree`.
**Legibility-target:** maintainer

With `core.hooksPath .hk` set in the main repo, a commit in a linked worktree printed `RAN-wt-hk` from `../wt/.hk/pre-commit` (gitprobe.log (i)). The code resolves values with `_snap_path "${_snap_rhv[k]}" "$wt"` (`:717`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:301-308,712-721`; $SCR/gitprobe.log

---

## Claim 12: "a linked worktree's private dir has none of its own" config; "config.worktree (git reads that only under extensions.worktreeConfig; reading it always is an over-walk)"

**Location:** `devcontainer-config/cc-exit-scan.sh:703-705`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5.
**Legibility-target:** maintainer

- **Private-dir config:** a `config` file planted in `.git/worktrees/wt/` was ignored: `private config: []`.
- **config.worktree:** `ext off: []`, then `ext on: [fromcw]`.

**Evidence:** $SCR/gitprobe.log (b), (d)

---

## Claim 13: "The common dir comes from cc-gitdir.sh's gitdir_common, git's reading of the file; one it cannot read safely fails the snapshot"

**Location:** `devcontainer-config/cc-exit-scan.sh:705-707`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the 0-byte case. Unreadable, non-regular and oversized files fail per `cc-gitdir.sh:58-60`, checked statically. A newline-only file is the claim 3 residue.
**Legibility-target:** maintainer

`c="$(gitdir_common "$g")" || { _snap_fail 'cannot read the commondir file in %s' "$g"; return 1; }` (`:714`). The observer is `git_exec_snapshot`'s `|| { rc=1; break; }` (`:910`), so the snapshot returns 1. P3 output: `snap rc=1`.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:714,910,968`; $SCR/scanprobe-28dfcd3b.log

---

## Claim 14: "where it does not (a container-form .git's git dir, a commondir outside the checkout), a value changed in the session names a hooks dir the launch snapshot did not walk, which is a finding"

**Location:** `devcontainer-config/cc-exit-scan.sh:708-711`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a value changed to a new path. Not covered: a value changed to exactly the path string of a hooks dir already walked at launch. That names a walked dir whose contents are snapshotted, so a plant there is still a finding; the sentence's "did not walk" is just not universal.
**Legibility-target:** maintainer

Probe P2 used a container-form `sub/.git` mapping to `$ws/cgd`, a git dir that `_snap_gitdir` never walks. At launch the value was `.hk`; the session changed it to `.hk2` and planted a hook. HEAD gave `scan rc=1` with `+ hooksdir .../sub/.hk2` and `+ hook .../sub/.hk2/pre-commit`. d40e4bae gave `scan rc=0`.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:329-343,744-753`; $SCR/scanprobe-28dfcd3b.log; $SCR/scanprobe-d40e4bae.log

---

## Claim 15: "A core.worktree elsewhere is not followed"

**Location:** `devcontainer-config/cc-exit-scan.sh:711`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers `_snap_entry_hooks`. Does not cover `_snap_config`, which does follow `core.worktree` for an embedded repo's own config (claim 25).
**Legibility-target:** maintainer

The base is always the entry's directory: `_snap_entry_hooks "$g" "${f%/*}"` (`:910`). `_snap_entry_hooks` reads no `core.worktree` (`:712-721`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:712-721,910`

---

## Claim 16: Bats "Q-168 rubric R6: husky's .husky/_ with an agent worktree already in the checkout; git runs <worktree>/.husky/_/pre-commit on a commit there"

**Location:** `test/cc-isolated-functions.bats:3144-3145`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5.
**Legibility-target:** maintainer

See gitprobe.log (i) and the passing final commit in bats-r6.log. `std_wt` adds the worktree under `.claude/worktrees/` (`:2853-2857`).

**Evidence:** `test/cc-isolated-functions.bats:2853-2857,3143-3196`; $SCR/bats-r6.log

---

## Claim 17: The R6 case's four parts each fail on d40e4bae's scan, and the includeIf-chain part on e1d7d912's

**Location:** `test/cc-isolated-functions.bats:3143-3196`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Each part was run independently (`split.bats`, same launch state and assertions as the combined case). The combined case stops at its first failure, so it cannot show this per part.
**Legibility-target:** reviewer

| Revision | Part 1 | Part 2 | Part 3 | Part 4 |
|---|---|---|---|---|
| d40e4bae | status=0, fail | status=0, fail | status=0, fail | status=0, fail |
| cf15f4f9 | pass | pass | fail | fail |
| e1d7d912 | pass | pass | pass | fail |
| 28dfcd3b | pass | pass | pass | pass |

The combined case passes at HEAD (`ok 1`).

**Evidence:** $SCR/split.bats; $SCR/split-run.log; $SCR/split-cf.log; $SCR/bats-r6.log

---

## Claim 18: Bats "An include named by an absolute path: its relative hooksPath still resolves in the worktree"

**Location:** `test/cc-isolated-functions.bats:3166-3167`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the scan's walk. It does not run host git for this part; claim 1 covers git's resolution in general.
**Legibility-target:** maintainer

Part 3 passes at HEAD with `+ hook $STD_WT/.inc-hooks/pre-commit`.

**Evidence:** $SCR/split-run.log

---

## Claim 19: Bats "The file that sets it is first met at depth 10 of an includeIf chain git does not take, then through a plain include git does take."

**Location:** `test/cc-isolated-functions.bats:3176-3177`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers which file sits at which depth. The test itself is correct (claim 17).
**Legibility-target:** maintainer

The chain is `config` to `a1` (depth 1) through `a9` (9), then `x.cfg` (10), then `inc.cfg` (11) (`:3179-3181`). The file that sets `hooksPath` is `inc.cfg` (`printf '[core]\n\thooksPath = .inc-hooks\n' > "$SCAN_WS/.git/inc.cfg"`, `:3161`), and it sits at depth 11. The file met at depth 10 is `x.cfg`, which includes it. 28dfcd3b's message says this precisely ("a file first met at depth 10 ... hide its include"). A precise comment would be: "the file that includes it is first met at depth 10 of an includeIf chain ...".

**Evidence:** `test/cc-isolated-functions.bats:3161,3176-3185`

---

## Claim 20: Bats "What a clean scan would have let through: host git runs the hook there."

**Location:** `test/cc-isolated-functions.bats:3193`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5 in the container.
**Legibility-target:** maintainer

The marker assertion passes (bats-r6.log; split part 4 at HEAD).

**Evidence:** `test/cc-isolated-functions.bats:3194-3195`; $SCR/bats-r6.log

---

## Claim 21: Guide coverage sentence: "A relative `core.hooksPath` in a repo's config (husky's `.husky/_`), set there or in a file it includes, is walked in every working tree that uses that config: the repo's own and each linked worktree or other `.git` entry in the checkout"

**Location:** `guides/cc-isolated-usage.md:337-342`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same scope as claim 8. The `core.worktree` exception is listed in the same guide (`:470-474`).
**Legibility-target:** user

Bats parts 1-4 pass at HEAD. Probe P1 shows the same for a `--separate-git-dir` embedded repo (claim 30).

**Evidence:** $SCR/split-run.log; $SCR/scanprobe-28dfcd3b.log

---

## Claim 22: Guide boundary paragraph "The boundary (Q-172 [2]): a route that needs only ordinary setup plus what a session can write in the checkout is one to close, and stays listed here until it is; a route that needs some unusual state present at launch stays here by design. Push with `cc-push`..."

**Location:** `guides/cc-isolated-usage.md:416-420`
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers that Q-172 was answered [2] and that the paraphrase matches the research doc's documented reading of it. Not established: that Q-172's own text says "unusual". It says "need no state planted before launch". The gloss "planted = unusual" is the research doc's reading (§1, `:13-21`), not Q-172's wording.
**Legibility-target:** user

The archive records `**Answered (docs/human-author/answers-10-22-26.txt): [2], set a boundary.**`, with option [2] defined as `Close only routes that need no state planted before launch; list the rest as known routes; the guide says to push with cc-push` (`docs/working/questions-archive.md:4199,4209`). The in-scope open routes (A14, R3's remote half, A16) are listed at `:460-469`, which matches "stays listed here until it is".

**Evidence:** `docs/working/questions-archive.md:4196-4214`; `guides/cc-isolated-usage.md:460-469`

---

## Claim 23: Guide "A slow scan ... about 30 ms more for each embedded repository or linked worktree"

**Location:** `guides/cc-isolated-usage.md:439-441`
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers this container under load 2-3. Does not establish host (WSL2 host) timings.
**Legibility-target:** user

| Case | Old | HEAD | Per entry at HEAD |
|---|---|---|---|
| 100 embedded repos | 2.30 s | 2.66-2.73 s | about 27 ms |
| 100 in-checkout linked worktrees, with a relative hooksPath | 2.50-2.65 s | 3.11-3.35 s | about 31-33 ms |

**Evidence:** $SCR/perf/timing.log; $SCR/wttime.log

---

## Claim 24: Guide R4 bullet "Git cuts such a path at the `]` (`./decoy@[x]plant` pushes to `./]plant`) ... a remote URL, an undefined remote name, a legacy remotes file and an `insteadOf` result"

**Location:** `guides/cc-isolated-usage.md:456-459`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** The cut itself was checked for a pushed URL (`./decoy@[x]plant` and `[x]plant2`). Taken from Q-168 rubric R4 without re-running: the name, legacy-file and insteadOf forms, and that the scan "walks the path as written".
**Legibility-target:** user

| Push target | Hook that ran |
|---|---|
| `./decoy@[x]plant` | `PRE-RECEIVE in ]plant` |
| `[x]plant2` | `PRE-RECEIVE in ]plant2` |
| `./[x]plant2` (control) | `PRE-RECEIVE in [x]plant2` (not cut) |

**Evidence:** $SCR/r4probe.log; `docs/reviews/code-review-rubric-2026-10-15-q168-exit-scan-remote-names.md:20` (at 75d08a94)

---

## Claim 25: Guide "A `core.worktree` elsewhere ... a repo or linked worktree whose `core.worktree` (in `config.worktree`, say) names another directory runs hooks from `<that directory>/<path>`, which is not walked."

**Location:** `guides/cc-isolated-usage.md:470-474`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** True for a linked worktree, and for the checkout's own repo. Overbroad for an embedded repo whose own config holds both `core.worktree` and `core.hooksPath`. Mixed-file shapes, such as hooksPath in an include, inherit the including file's base and were not probed separately.
**Legibility-target:** user

The overbroad case is walked. `_snap_worktree_of` reads that file's `core.worktree` (`elif [ -f "$1" ] && v="$(cd / && git --no-pager config --file "$1" --no-includes --get core.worktree ...)"; then _snap_path "$v" "$gd"`, `devcontainer-config/cc-exit-scan.sh:349-350`), and `_snap_config` walks the value there. Probe C1 (embedded `vendor/e` with `core.worktree ../../other`, `core.hooksPath .hk`, plant at `vendor/other/.hk/pre-commit`) gave `scan rc=1`, with the hook named.

The checkout's own repo ignores `core.worktree`: `if [ "$gd" = "$_snap_gd" ] || [ "$gd" = "$_snap_common" ]; then printf '%s' "$_snap_ws"` (`:347-348`).

This errs toward listing more than is open, never toward a false clean. A precise version would be: "a linked worktree whose `core.worktree` (in `config.worktree`), or the checkout itself, names another directory ...".

**Evidence:** `devcontainer-config/cc-exit-scan.sh:343-357,478-482`; $SCR/cwprobe.log

---

## Claim 26: Guide "not closed yet" bullet: relative remotes walked only in the main working tree, a push from a linked worktree goes to `<worktree>/<path>`, `--separate-git-dir` paths resolved inside its git dir, receive hooks under a relative hooksPath run from `<repo>/.git/<path>` (`git push .` included)

**Location:** `guides/cc-isolated-usage.md:460-469`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the git-side behaviour (A14, A16) and the scan-side base. The worded item "legacy URL in a repo's config" is really a legacy remotes file. It is resolved the same way (`_snap_worktree_of "$real/config"`, `:597-600`).
**Legibility-target:** user

- **A14:** with `origin = ../up.git`, a push from `wts/a` ran `PRE-RECEIVE-in-checkout` from `wts/up.git`.
- **A16:** `git push .` with `core.hooksPath .hk` ran `PRE-RECEIVE-from-gitdir` (`.git/.hk`), not the worktree's `.hk`.
- **Scan base:** remotes use `base = _snap_worktree_of "$f"` (`:481`). That function returns the git dir itself for a non-`.git`-named git dir with no `core.worktree` (`:354-355`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:343-357,478-482`; $SCR/a14probe.log

---

## Claim 27: Guide container-form bullet: "walks only your own config there and that git dir's relative `core.hooksPath` in the worktree, not the git dir itself (and nothing at all when the line ends in a CR, which git strips: Q-168 tech-debt T1)"

**Location:** `guides/cc-isolated-usage.md:491-496`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the walk. Absolute values are walked too (claim 4), which the bullet does not mention; that is harmless. "Nothing at all" excludes the `dotgit` record of the file itself (`_snap_dotgit`, `:851-856`).
**Legibility-target:** user

- **The walk:** P2 walked `sub/.hk` at launch (count 1) and found the in-session change (claim 14).
- **The CR case:** `_snap_first_line` keeps a trailing CR (`IFS= read -r line`, `:236`). `g="$_snap_ws/${line#...}"` then ends in CR and `[ -d "$g" ] || return 0` (`:751`) yields nothing.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:228-238,744-753,905-910`; $SCR/scanprobe-28dfcd3b.log

---

## Claim 28: Research sort table: launch states for R6, R3, A14, A16, R4; "on main your own `pushDefault` names are never walked at all"

**Location:** `docs/working/research-2026-10-25-exit-scan-r6-hookspath.md:25-31`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the factual launch-state and mechanism parts. The in/out classification is judgment under Q-172 [2] and is not verdicted.
**Legibility-target:** reviewer

- **R6:** claim 17.
- **R3:** P1 (claim 30).
- **A14 and A16:** claim 26.
- **R4:** claim 24.
- **pushDefault:** `_snap_host_config`'s `case "$key"` handles only `url.*.insteadof|url.*.pushinsteadof`, `remote.*.url|remote.*.pushurl`, `core.hookspath`, `core.attributesfile` and includes. There is no `remote.pushdefault` or `branch.*` branch (`devcontainer-config/cc-exit-scan.sh:620-643`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:605-646`; $SCR/split-run.log; $SCR/a14probe.log; $SCR/r4probe.log

---

## Claim 29: Research T3 row "The `_snap_config` dedup key omission only over-walks (fails toward more findings), so there is nothing to list as a route"

**Location:** `docs/working/research-2026-10-25-exit-scan-r6-hookspath.md:33`
**Type:** Reference / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what T3 is. Not established: whether main's `_snap_config` key (`c:$real`, base omitted) has an unrelated under-walk. That is out of this change's scope.
**Legibility-target:** reviewer

T3 is about `_snap_drid`: "The `_snap_config` dedup key omits `_snap_drid`" (Q-168 tech-debt review at 75d08a94, line 110). `_snap_drid` does not exist on this branch: `grep -c _snap_drid devcontainer-config/cc-exit-scan.sh` gives `0`. The R5 and A15 rows say "not reachable on main". The T3 row does not, so a reader may look for the omission in main's `_snap_config` and find a different key. A precise row would say "(Q-168 branch only: `_snap_drid`)".

**Evidence:** `devcontainer-config/cc-exit-scan.sh:478-487`; `git show 75d08a94:docs/reviews/q168-exit-scan-remote-names-p3-tech-debt-triage-review-2026-10-15.md` (line 110)

---

## Claim 30: Research "R3's `core.hooksPath` half is already resolved by this change's per-entry walk"; "R3's hooksPath half, same shape ...: `old rc=0` (hook ran), `new rc=1`"

**Location:** `docs/working/research-2026-10-25-exit-scan-r6-hookspath.md:49-50,82-83`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a `--separate-git-dir` embedded repo with a relative hooksPath in its own config. R3's remote half stays open.
**Legibility-target:** reviewer

Probe P1: HEAD gave `scan rc=1` with the hook named (count 1). d40e4bae gave `scan rc=0` (count 0). Both runs then printed `HOOK-RAN` on a commit in `vendor/e`.

**Evidence:** $SCR/scanprobe-28dfcd3b.log; $SCR/scanprobe-d40e4bae.log

---

## Claim 31: Research "The new bats case fails on the unfixed scan at its first `[ "$status" -eq 1 ]` and passes with the fix; it ends with the real host commit running the hook"

**Location:** `docs/working/research-2026-10-25-exit-scan-r6-hookspath.md:79-80`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers d40e4bae and HEAD.
**Legibility-target:** reviewer

See claim 17. Part 1 fails at its status assertion on d40e4bae (`status=0`), and the combined case passes at HEAD.

**Evidence:** $SCR/split-run.log; $SCR/bats-r6.log

---

## Claim 32: Research pre-mortem row 1 "Hooks base differs from the `.git` entry's dir (`core.worktree` set in the config) | Not covered ... The main working tree already ignored `core.worktree`"

**Location:** `docs/working/research-2026-10-25-exit-scan-r6-hookspath.md:123`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Same split as claim 25: right for linked worktrees and the main tree, overbroad for an embedded repo's own config.
**Legibility-target:** reviewer

The main-tree clause is right (`:347-348`). For an embedded repo whose own config sets both values, the family is covered (cwprobe.log, `scan rc=1`). "Not covered" fits the probed shape (`core.worktree` via `config.worktree`), not the whole family as titled.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:343-357`; $SCR/cwprobe.log

---

## Claim 33: Research pre-mortem rows 2-7 (new worktree covered by W records plus hook records; includes followed in any form with no depth cap; config.worktree walked; unreadable config fails the snapshot; symlinked or unlistable hooks dir handled by `_snap_hooks`; commondir via `gitdir_common`, "an unreadable or empty file fails the snapshot"); section 5 "an empty or non-regular `commondir` in an embedded repo now refuses the launch (git dies there too, rc=128)"

**Location:** `docs/working/research-2026-10-25-exit-scan-r6-hookspath.md:124-129,143-144`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Executed: rows 3, 4 and 7, and the empty-commondir case. Static: rows 2, 5 and 6 and the non-regular case.
**Legibility-target:** reviewer

- **Row 3:** claim 17.
- **Row 4:** `for cfg in "$c/config" "$g/config.worktree"` (`:715`).
- **Row 5:** `_snap_fail 'could not read config %s: %s'` then `return 1` (`:679-682`).
- **Row 6:** `_snap_hooks` follows `_snap_linkdir` and `_snap_find` fails closed (`:329-343,290-298`).
- **Row 7 and section 5:** P3 `snap rc=1`; git `empty rc=128`.
- **Non-regular file:** refused by `[ -f "$c" ] && [ -r "$c" ] || return 1` (`cc-gitdir.sh:58`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:670-721`; `devcontainer-config/cc-gitdir.sh:55-69`; $SCR/scanprobe-28dfcd3b.log; $SCR/gitprobe.log

---

## Claim 34a: Research section 5 cost numbers: "100 entries x 100 includes. 46.6 s vs 2.2 s"; "100 entries x 100 values, 11.3 s vs 1.3 s"; "100 embedded repos 2.32 s -> 2.85 s ... about 5 ms more per repo"; "100 entries x 100 includes 2.06 s -> 2.71 s"; "100 entries x 100 lines naming one include 1.82 s -> 2.23 s"

**Location:** `docs/working/research-2026-10-25-exit-scan-r6-hookspath.md:145-159`
**Type:** Performance
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Four of the five figures reproduced to within noise (below). Not re-run: the "lines naming one include" case (1.82 s -> 2.23 s). This verdict stands only for that residue; the other four are confirmed.
**Legibility-target:** reviewer

| Figure | Measured | Note |
|---|---|---|
| 46.6 s | 51.86 s | e1d7d912 |
| 11.3 s vs 1.3 s | HEAD 10.99 s vs 1.33 s | e1d7d912 measured 7.65 s, so 11.3 s is a HEAD figure; the doc files it under pass-2 L1 without saying so |
| 2.85 s | 2.66-2.73 s | |
| 2.71 s | 2.62-2.68 s | |

**Evidence:** $SCR/perf/timing.log; $SCR/perf/timing-e1d.log; $SCR/perf/timing-hp.log

---

## Claim 34b: Research "The guide's per-repo figure moves from about 29 ms to about 30 ms"

**Location:** `docs/working/research-2026-10-25-exit-scan-r6-hookspath.md:159-161`
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers internal consistency, and the absolute per-repo cost on this container.
**Legibility-target:** reviewer

The same paragraph reports "about 5 ms more per repo" ((2.85 - 2.32) / 100 = 5.3 ms, computed). Adding that to 29 ms gives about 34 ms, not 30. The "30 ms" matches the absolute per-entry cost measured here: about 27 ms per embedded repo and 31-33 ms per linked worktree (claim 23). So the guide figure is fine, but "moves from 29 to 30" does not follow from the +5 ms stated beside it. A precise version would say "about 30 ms measured per entry (the old 29 ms was an earlier host figure)".

**Evidence:** $SCR/perf/timing.log; $SCR/wttime.log

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
- **Claim 2** (`commit cf15f4f9`): "includes" were not all followed (absolute and `~/` skipped; part 3 status=0 on cf15f4f9). `_snap_tree_hooks` is gone. R5/A15 were later dropped from the guide. Superseded by e1d7d912 and 28dfcd3b; informational only.
- **Claim 4** (`commit e1d7d912`): "the abs/~ skip now applies to the hooksPath value only". At HEAD, absolute values are walked (`cc-exit-scan.sh:717`). Superseded by 28dfcd3b; informational only.

### Mostly Accurate
- **Claim 19** (`test/cc-isolated-functions.bats:3176`): the file met at depth 10 is `x.cfg`, which includes the setter. `inc.cfg` (the setter) sits at depth 11.
- **Claim 25** (`guides/cc-isolated-usage.md:470-474`): "which is not walked" is overbroad. An embedded repo whose own config sets both `core.worktree` and `core.hooksPath` is walked via `_snap_worktree_of` (`cc-exit-scan.sh:349-350`; probe C1 rc=1). The route is open for linked worktrees and the checkout itself.
- **Claim 29** (`docs/working/research-2026-10-25-exit-scan-r6-hookspath.md:33`): T3 concerns `_snap_drid`, which has 0 occurrences on this branch. The row should say it is Q-168-branch only, as the R5/A15 rows do.
- **Claim 32** (`docs/working/research-2026-10-25-exit-scan-r6-hookspath.md:123`): pre-mortem row 1 "Not covered" is overbroad in the same way as claim 25.
- **Claim 34b** (`docs/working/research-2026-10-25-exit-scan-r6-hookspath.md:159-161`): "29 -> 30 ms" does not follow from the "+5 ms per repo" in the same paragraph. 30 ms matches the absolute measurement, not 29 + 5.

### Unverifiable
- **Claim 34a** (`docs/working/research-2026-10-25-exit-scan-r6-hookspath.md:158-159`): only the "100 lines naming one include, 1.82 -> 2.23 s" figure was not re-run. The other four cost figures reproduced.

---

## Goal-Alignment Note

- **Success criterion (verbatim):** "A markdown report saved to docs/reviews/r6-hookspath-p3-code-fact-check-report-r3.md in the worktree, structured per the code-fact-check skill, `Commit: 28dfcd3b` first line."
- **Answered:** All five requested areas were checked: the three commit messages, the comments on the three functions and the header, the R6 bats case (every part fails on d40e4bae, part 4 on e1d7d912, parts 3-4 on cf15f4f9), the guide edits, and the research doc's sort, R3 claim, pre-mortem and section 5. Nothing is Incorrect. The code's comments on the new functions are accurate. The Mostly-accurate findings are wording: one bats comment, and two over-listings of the `core.worktree` route that err toward caution and never toward a false clean.
- **Out of scope:** A14, R3's remote half, A16, R4 and `core.worktree` as routes (not filed; only the doc wording was checked). Performance and security judgments.
- **Escalate:** None. No claim misleads toward a false clean scan.
- **Questions/Decisions:** Optional doc-only tightenings: claims 19, 25, 29, 32 and 34b.
