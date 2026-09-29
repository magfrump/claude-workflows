Commit: 5a6d689

# Code Fact-Check Report

**Repository:** /workspace (claude-workflows), branch q094-exit-scan-worktree-layout (worktree /workspace/.claude/worktrees/agent-aaad54fc687b7548c)
**Scope:** `git diff main...5a6d689` — `devcontainer-config/cc-exit-scan.sh`, `docs/working/plan-q094-exit-scan-worktree-layout.md`, `guides/cc-isolated-usage.md`, `test/cc-isolated-functions.bats` (new Q-094 section) — plus the commit messages of 6abe247, b4de821 and 5a6d689. Callers and producers read in full: `scan_git_dirs`, `_snap_first_line`, `_snap_file`, `_snap_wrel`, `_snap_remote`, `_snap_config`, `_snap_worktree_of`, `_snap_host_config`, `_snap_dotgit_target`, `_snap_nested`, `_snap_gitdir`, `_snap_dotgit`, `git_exec_snapshot`, `scan_diff`, `scan_std_worktrees`, `git_exit_scan` (cc-exit-scan.sh), `cc-gitdir.sh`, and `main`'s exit handling in `devcontainer-config/cc-isolated.sh:733-750`.
**Checked:** 2026-09-28
**Total claims checked:** 28
**Summary:** 21 verified, 6 mostly accurate, 0 stale, 1 incorrect, 0 unverifiable
**Commit:** 5a6d689
**Replication:** k=1 (loop pass, decision 031)

Execution provenance. `$SP` = `/tmp/claude-1000/-workspace/0d5be710-0e7c-4a4f-8e65-09d2e983c2f5/scratchpad/q094fcx`. Every experiment ran on the host sandbox's git 2.39.5 (`git --version` in `$SP/exp1.log`), in scratch repos under `$SP/e1`…`$SP/e5`, with `GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1` unless noted. Scripts are `$SP/exp1.sh`…`$SP/exp5.sh`; each takes the worktree path as `$1` where it sources the scan. Timestamps are UTC.

| Run | Command | cwd | Exit | Time (UTC) | Output |
|---|---|---|---|---|---|
| T0 | `bats --filter 'Q-094' test/cc-isolated-functions.bats` | worktree | 1 | 2026-09-29T01:29:11Z | `$SP/bats-q094.log` |
| T1 | `env LC_ALL=C.UTF-8 LANG=C.UTF-8 bats --filter 'Q-094' test/cc-isolated-functions.bats` | worktree | 0 | 2026-09-29T01:29:32Z | `$SP/bats-q094-c.log` |
| X1 | `bash $SP/exp1.sh` | worktree | 0 | 2026-09-29T01:30:15Z | `$SP/exp1.log` |
| X2 | `bash $SP/exp2.sh` | worktree | 0 | 2026-09-29T01:30:28Z | `$SP/exp2.log` |
| X3 | `bash $SP/exp3.sh <worktree>` | worktree | 0 | 2026-09-29T01:32:40Z | `$SP/exp3.log` |
| X4 | `bash $SP/exp4.sh <worktree>` | worktree | 0 | 2026-09-29T01:33:14Z | `$SP/exp4.log` |
| X5 | `bash $SP/exp5.sh` | worktree | 0 | 2026-09-29T01:34:14Z | `$SP/exp5.log` |

T0 fails test 1 only because this sandbox's `LC_ALL=en_US.UTF-8` is not installed, so bash prints `setlocale` warnings into `$output` and the `wc -l -eq 1` assertion sees extra lines. That is the environment, not the code. T1, with a valid locale, passes 8/8.

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) read first. No claim here matches a logged pattern: the logged entries are all specific measured values or file/symbol associations, and no such claim occurs in this diff.

---

## Claim 1: "In a linked worktree git takes config, hooks and info/attributes from the common dir, never the private one (tested on git 2.39.5)."

**Location:** `devcontainer-config/cc-exit-scan.sh:78-79`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the private dir's `config`, `hooks/` and `info/attributes` files on git 2.39.5, and `config.worktree` with `extensions.worktreeConfig` set; does not establish other git versions, or private-dir entries other than those four.
**Legibility-target:** for-author

X1 on git 2.39.5: `git rev-parse --git-path` in the worktree maps `hooks`, `config` and `info/attributes` to the common dir. An executable `post-commit` in `P/hooks/` did not run (`private hook not run`), and the control in the common `hooks/` did (`control: common hook RAN`). An alias in `P/config` was not read. `* filter=x` in `P/info/attributes` did not run the filter (`private attributes not read`), and X2's control with the same line in the common `info/attributes` did.

The word "never" is too strong for config. `config.worktree` lives in the private dir (`config.worktree -> …/main/.git/worktrees/wt/config.worktree`, X1), and git reads it once `extensions.worktreeConfig` is set in the common config. X2: `core.hooksPath` set in `P/config.worktree` was used for the worktree's commit (`hooksPath from private config.worktree USED`). The plan's E6 says the same. The code already covers this case: `scan_std_worktrees` declines when `P/config.worktree` exists:

```bash
# devcontainer-config/cc-exit-scan.sh:854-856
    for k in hooks config config.worktree; do
      [ ! -e "$p/$k" ] && [ ! -L "$p/$k" ] || return 1
    done
```

So the conclusion holds for every layout the rule accepts, but the sentence needs a qualifier: "…never the private one, except `config.worktree` when the common config sets `extensions.worktreeConfig` (the rule refuses a private dir that has one)."

**Evidence:** `devcontainer-config/cc-exit-scan.sh:78-79`, `devcontainer-config/cc-exit-scan.sh:854-856`, `$SP/exp1.log`, `$SP/exp2.log`

---

## Claim 2: "A relative core.hooksPath, core.attributesFile or local remote would resolve in the new worktree's own tree, unscanned: those leave W records, and any W record refuses the note."

**Location:** `devcontainer-config/cc-exit-scan.sh:79-81`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers these values in repo config that `_snap_config` reads (checkout, nested git dirs, in-checkout include targets) and in remotes that `_snap_remote` walks; does not establish that your own global/system config's relative values leave W records (they do not; see Claim 12, where the resulting F record declines instead).
**Legibility-target:** for-orchestrator-synthesis

Resolution: in X4, with `core.hooksPath = .githooks` in the common config, a hook at `<wt>/.githooks/post-commit` ran on a commit in the worktree (`E7: relative hooksPath resolved in the worktree (hook ran)`). W emission: `_snap_config` calls `_snap_wrel "$key" "$f" "$val"` for `core.hookspath` (`:388`) and `core.attributesfile` (`:396`). `_snap_remote` calls `_snap_wrel remote "$p" "$p"` (`:352`) after dropping `scheme://` and `host:path` forms. `_snap_wrel` skips empty, `/…` and `~/…` values:

```bash
# devcontainer-config/cc-exit-scan.sh:287-291
_snap_wrel() {
  # shellcheck disable=SC2088  # matching a literal "~/" in the value
  case "$3" in ""|/*|"~/"*) return 0 ;; esac
  _snap+="W"$'\t'"$1"$'\t'"$(printf '%q' "$2")"$'\n'
}
```

Refusal: `scan_std_worktrees` returns 1 before anything else if the exit snapshot has a W line (`:807`, `if printf '%s\n' "$after" | LC_ALL=C grep -q $'^W\t'; then return 1; fi`). Test 7 in T1 checks each of `core.hooksPath .husky/_`, `core.attributesFile .attrs`, `remote.loc.url ./sub.git` and `file://sub.git`, and passes. Each still warns, while the absolute-hooksPath control returns 0.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:287-291`, `:352`, `:388`, `:396`, `:807`, `test/cc-isolated-functions.bats:2369-2383`, `$SP/exp4.log`, `$SP/bats-q094-c.log`

---

## Claim 3: "W <kind> <config or path %q> … (read by scan_std_worktrees; never reported, and it changes only with a C or F record)"

**Location:** `devcontainer-config/cc-exit-scan.sh:148-150`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers every current W producer (`_snap_config` hooksPath/attributesFile, `_snap_remote` from config urls, insteadOf bases, legacy remotes/branches files and the end-of-snapshot remote-name loop) and `scan_diff`'s record filter; does not establish the invariant for W producers added later, or for two snapshots taken by different versions of the script.
**Legibility-target:** for-orchestrator-synthesis

Never reported: `scan_diff` only stores F and C lines. W lines match neither branch and are dropped:

```awk
# devcontainer-config/cc-exit-scan.sh:749-750
    FNR == NR { if ($1 == "F") b[$2 FS $3] = $4; else if ($1 == "C") bc[$0] = 1; next }
    { if ($1 == "F") a[$2 FS $3] = $4; else if ($1 == "C") ac[$0] = 1 }
```

Changes only with C or F (paraphrased — no quote available because the invariant is inferred from five call sites across `_snap_config`, `_snap_remote`, `_snap_gitdir` and `git_exec_snapshot`). Every W comes from the same pass that emits a C or F record for its source:

- In `_snap_config`, the W for hooksPath/attributesFile is written in the same loop iteration as that entry's C record (`:385`). The C record keeps the value's first byte (only `\n` and `\t` become `?`), so a value flipping between relative and absolute changes the C record too.
- Remote W records come from `remote.*.url`/`pushurl` and `url.*.insteadof` keys, which are C records. Legacy `remotes/`/`branches/` files are F `legacy-remote` records hashed by content (`:593`). Remote names resolved at the end of the snapshot (`:701-706`) depend on `branch.*`/`remote.pushdefault` C records and on `_snap_rnames`, which is filled from C keys and legacy-remote F paths.
- Whether a config is reached at all depends on F records (config file, include, link, remote, dotgit).

I found no path where a W differs while every C and F line is equal. So `git_exit_scan`'s "could not be shown" status-2 path (`:954-957`) cannot be reached through a W-only difference. Medium confidence, because this is a whole-program invariant read statically, not tested.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:148-150`, `:352`, `:380-414`, `:588-608`, `:701-706`, `:749-750`, `:954-957`

---

## Claim 4: "Where the container sees the checkout (devcontainer.json's workspaceMount target). Git in the container writes absolute paths under it into a new worktree's `.git` file and back-pointer."

**Location:** `devcontainer-config/cc-exit-scan.sh:765-768`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the mount target value and git 2.39.5 writing absolute paths in both files; does not establish the container image's git version (not checked here) or git ≥ 2.48 with `worktree.useRelativePaths` (plan B25: warns).
**Legibility-target:** for-orchestrator-synthesis

`devcontainer-config/devcontainer.json:134` has `"workspaceMount": "source=${localWorkspaceFolder},target=/workspace,type=bind,consistency=delegated"`, which matches `GIT_EXIT_SCAN_CONTAINER_WS=/workspace` (`:768`). X1 shows that git 2.39.5 writes absolute paths: the back-pointer is `…/e1/wt/.git` and the `.git` file is `gitdir: …/e1/main/.git/worktrees/wt`.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:765-768`, `devcontainer-config/devcontainer.json:134`, `$SP/exp1.log`

---

## Claim 5: scan_std_worktrees contract — "Anything it cannot read or match declines; nothing passes on error. P = <common>/worktrees/<n>, <n> of [A-Za-z0-9._-]. Only dotgit, commondir-file and hooksdir records differ, and the exit snapshot has no W record. Added <n>: … Removed <n>: those two records gone, P gone on disk, and as many `dotgit … file` records gone. Paths are compared as the %q strings the records hold, recomputed from <n>; nothing is unquoted."

**Location:** `devcontainer-config/cc-exit-scan.sh:787-800`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each clause against `scan_std_worktrees` (`:801-909`), read in full, and T1 tests 1-7; does not establish that removed `dotgit` records belong to the removed worktrees (the pairing is by count, as the comment says), or behaviour when `<common>`'s `%q` form is not a prefix of its children's (such a checkout declines; no test covers it).
**Legibility-target:** for-orchestrator-synthesis

Clause by clause:
- No W: `:807`.
- Record kinds: any diff line other than `[+-]F dotgit|commondir-file|hooksdir` returns 1 (`:825-826`, `*) return 1 ;;`).
- Own common dir: the exit snapshot's `commondir` record must equal the recomputed common dir (`:812-813`).
- Name: `[[ "$n" =~ ^[A-Za-z0-9._-]+$ ]] && [ "$n" != . ] && [ "$n" != .. ] || return 1` (`:838`), and the `%q` path must equal `printf '%q' "$p/commondir"` (`:840`).
- commondir `../..\n` at snapshot time: `re="^file [0-7]+ $std\$"` against the record attributes (`:841-842`). On disk: `_snap_file_is "$p/commondir" "$std"` (`:853`).
- Paired `hooksdir P/hooks missing`: required, with the same sign (`:843-844`).
- Real directories: `:852`.
- No hooks/config/config.worktree: `:854-856`.
- No symlink under P: `find -P "$p" -type l -print -quit` must be empty (`:857-858`).
- Back-pointer: a regular file whose whole content is its first line plus `\n` (`:861-863`), of the form `"$wsp"/?*/.git` or `"$cws"/?*/.git`, with the container form only when `ccommon` is set (`:864-868`). `..`, `.` and `//` are refused (`:870`), and so is a working tree inside the common dir (`:872`).
- dotgit: a `+F dotgit <%q wt/.git>` record must exist (`:874-879`). Its attributes and the file on disk must both hash to `gitdir: P\n` or to the container form (`:882-886`). If the container form exists on the host, it must `cd` to `P` (`:889-891`).
- Removed: `P` must be gone (`:847`). Every leftover record must be a removed `dotgit … file` (`:897-902`), and their count must equal the number of removed worktrees (`:903`).

Every failure is `|| return 1`, and the caller discards stderr (`:946`). T1 tests 1-7 pass, covering the accepted forms, the host/container forms and the declining variants.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:787-909`, `:946`, `test/cc-isolated-functions.bats:2227-2383`, `$SP/bats-q094-c.log`

---

## Claim 6: "Regular file first: a FIFO there would block the read."

**Location:** `devcontainer-config/cc-exit-scan.sh:860`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the back-pointer `P/gitdir` read in `scan_std_worktrees`; does not establish that other reads in the scan are guarded (Claim 23 shows one that is not).
**Legibility-target:** for-orchestrator-synthesis

`[ -f "$p/gitdir" ] && [ ! -L "$p/gitdir" ] || return 1` (`:861`) runs before `_snap_first_line` (`:862`). `_snap_first_line` does `IFS= read -r line < "$1"` (`:210`), which blocks when the file is a FIFO with no writer. T1 test 5 replaces the back-pointer with a FIFO, runs `git_exit_scan` under `timeout 20`, and gets the warning (`test/cc-isolated-functions.bats:2336-2338`). It passes.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:210`, `:860-863`, `test/cc-isolated-functions.bats:2336-2338`, `$SP/bats-q094-c.log`

---

## Claim 7: "Removed worktrees' `.git` files, paired by count: git stops in a worktree whose private dir is gone, so a stale one runs nothing."

**Location:** `devcontainer-config/cc-exit-scan.sh:895-896`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5 refusing a worktree whose private dir or HEAD is gone, and the count pairing; does not establish which `.git` files the removed records were (the pairing does not tie them to the removed names).
**Legibility-target:** for-orchestrator-synthesis

X1: after deleting the private dir's `HEAD`, `git status` in the worktree exits 128 with `fatal: not a git repository: …/main/.git/worktrees/wt` and does not fall back to the parent. The pairing is by count only: `[ "$ndot" -eq "$nrm" ] || return 1` (`:903`), where `ndot` counts leftover records matching `^-F\tdotgit\t[^\t]*\tfile [0-7]+ [0-9a-f]{16}$` (`:899-901`). That is what "paired by count" says.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:895-903`, `$SP/exp1.log`

---

## Claim 8: note text — "They take config and hooks from the checkout's own .git, so this is not a finding."

**Location:** `devcontainer-config/cc-exit-scan.sh:908`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the worktrees the rule accepts, which have no `P/config.worktree`, `P/config` or `P/hooks`; does not establish the claim for private dirs in general (see Claim 1), or that the worktree's tracked files are safe (guide "A hook that runs a tracked file").
**Legibility-target:** for-orchestrator-synthesis

The note is printed only after `:854-856` has confirmed that `hooks`, `config` and `config.worktree` are absent from `P`. With those absent, X1/X2 show hooks and config coming from the common dir. X4's control run printed exactly this line with status 0.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:854-856`, `:908`, `$SP/exp4.log`

---

## Claim 9a: "0 when nothing the tripwire records changed, or only standard linked worktrees did (one `note:` line on stderr: scan_std_worktrees); 1 (warning on stderr, naming each item) when anything else did"

**Location:** `devcontainer-config/cc-exit-scan.sh:911-914`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the new 0 branch and its single stderr line; does not establish the pre-existing "1 when … changed" wording's edge case (an invalid git dir that was already invalid at launch also returns 1, `:939-942`).
**Legibility-target:** for-orchestrator-synthesis

```bash
# devcontainer-config/cc-exit-scan.sh:946-949
  if [ -z "$invalid" ] && note="$(scan_std_worktrees "$ws" "$before" "$after" 2>/dev/null)"; then
    printf '%s\n' "$note" | scan_vis >&2
    return 0
  fi
```

`scan_std_worktrees` echoes a single line (`:908`). T1 test 1 asserts `wc -l` is 1 and status 0.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:908`, `:911-914`, `:939-949`, `$SP/bats-q094-c.log`

---

## Claim 9b: "2 when the exit state could not be read."

**Location:** `devcontainer-config/cc-exit-scan.sh:914-915`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every `return 2` in `git_exit_scan`; does not establish reachability of the second path (Claim 3 argues a W-only difference cannot reach it).
**Legibility-target:** for-author

Status 2 comes from two places. One is a failed exit snapshot (`:920-934`). The other is snapshots that differ with nothing rendered:

```bash
# devcontainer-config/cc-exit-scan.sh:954-957
  if [ -z "$changes" ]; then
    echo "  the two snapshots differ but the difference could not be shown; treat the checkout as unsafe" >&2
    return 2
  fi
```

The docstring names only the first. The omission predates this branch (main's docstring said the same). It is included because this diff rewrote the comment and the new W record type bears on the second path. Precise version: "2 when the exit state could not be read, or the snapshots differ in a way that cannot be shown."

**Evidence:** `devcontainer-config/cc-exit-scan.sh:914-915`, `:920-934`, `:954-957`

---

## Claim 10: "The launcher maps `git_exit_scan` 0 → claude's own status, 1 → exit 3, 2 → exit 4. The acceptance lives inside `git_exit_scan` and returns 0, so `cc-isolated.sh` does not change."

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:23`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `main`'s exit mapping and the absence of any `cc-isolated.sh` change in the diff; does not establish behaviour when claude itself exits non-zero (passed through unchanged, not specifically tested here).
**Legibility-target:** for-orchestrator-synthesis

```bash
# devcontainer-config/cc-isolated.sh:744-749
  git_exit_scan "$ws" "$git_before" "$lws" || scan=$?
  trap - INT
  case "$scan" in
    0) exit "$rc" ;;
    1) exit 3 ;;   # the session planted something: never a clean exit
    *) exit 4 ;;   # the scan could not read .git
```

`rc` is claude's status (`:739`). `git diff main...HEAD --stat` lists no change to `cc-isolated.sh`. T1 test 8 runs the launcher with a session stub that adds a worktree and gets status 0 with the note.

**Evidence:** `devcontainer-config/cc-isolated.sh:737-749`, `test/cc-isolated-functions.bats:2385-2393`, `$SP/bats-q094-c.log`

---

## Claim 11: Experiment table E1-E12 (git 2.39.5)

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:29-42`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers E1, E2, E4, E5, E6 (in its hooksPath form), E7, E10 and E11 re-run here, E3 for `post-commit` only, and E12 for the private dir's removal (T1 test 3); does not establish E8, E9, E3's other hooks, or E12's "`worktrees/` when it empties", which were not re-run.
**Legibility-target:** for-orchestrator-synthesis

Re-run results:
- E1 (X1): `commondir` is `. . / . . \n` (6 bytes), the back-pointer is `<abs wt>/.git`, and `.git` is `gitdir: <abs P>`.
- E2 (X1): `hooks`, `config` and `info/attributes` map to the common dir. `config.worktree`, `index`, `HEAD` and `info/sparse-checkout` map to the private dir.
- E3/E4/E5 (X1/X2): private hook, private attributes and private config are not used; the controls are.
- E6 (X2): `core.hooksPath` in `config.worktree` was used with `extensions.worktreeConfig` and format v1.
- E7 (X4): the relative hooksPath resolved in the worktree.
- E10 (X1): no HEAD in the private dir gives `fatal`.
- E11 (X4): absolute and `../../` commondir both give rc 0.

Observation: an alias in `config.worktree` did not run in X2 even with the extension set, while the hooksPath from the same file did. E6's claim is about hooksPath, so this does not contradict it.

**Evidence:** `docs/working/plan-q094-exit-scan-worktree-layout.md:29-42`, `$SP/exp1.log`, `$SP/exp2.log`, `$SP/exp4.log`, `$SP/bats-q094-c.log`

---

## Claim 12: Rule 3 — "The exit snapshot holds no working-tree-relative path (a new `W` record, see below): no config the scan reads has a relative `core.hooksPath` or `core.attributesFile`, or a remote … that is a relative local path (E7–E9)."

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:52`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which configs produce W records; does not establish that host-config relative values are unhandled (they are handled, by an F record; B14 and X4).
**Legibility-target:** for-author

"No config the scan reads" is broader than the implementation. The scan also reads your global/system config in `_snap_host_config`, and that function resolves a relative `core.hooksPath`/`core.attributesFile` against the working tree without calling `_snap_wrel`:

```bash
# devcontainer-config/cc-exit-scan.sh:507-512
      core.hookspath)
        t="$(_snap_path "$val" "$wt")"
        if _snap_inside_ws "$t"; then _snap_hooks "$t" || return 1; fi ;;
      core.attributesfile)
        t="$(_snap_path "$val" "$wt")"
        if _snap_inside_ws "$t"; then _snap_file attributes "$t" || return 1; fi ;;
```

The acceptance still declines, for another reason. X4, with `GIT_CONFIG_GLOBAL` holding `core.hooksPath = .ghooks`: the new worktree's `.git` is found by `find -mindepth 2 -name .git` and walked by `_snap_host_config` (`:688-696`). That adds `+ hooksdir …/agent-x/.ghooks missing`, which is not consumed, so the result is status 1. The control without the global value gives status 0. Precise version: "no repo config (checkout, nested git dirs, in-checkout includes) has …; your own config's relative values are resolved in the worktree and show up as F records (B14)."

**Evidence:** `docs/working/plan-q094-exit-scan-worktree-layout.md:52`, `devcontainer-config/cc-exit-scan.sh:507-512`, `:688-696`, `$SP/exp4.log`

---

## Claim 13: "`_snap_config` and `_snap_remote` add `W <kind> <config or path %q>` whenever they resolve a path against a working tree. `scan_diff` ignores record types other than F and C, and a `W` record only changes when a C or F record does, so the report output is unchanged."

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:65`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers `_snap_config` (hooksPath, attributesFile) and `_snap_remote`; does not establish W for `_snap_host_config`'s working-tree resolution (it adds none, which is correct for this sentence, since it names only the two functions) or for `_snap_worktree_of`-derived bases.
**Legibility-target:** for-orchestrator-synthesis

The same evidence as Claims 2 and 3 applies: `_snap_wrel` is called at `:352`, `:388` and `:396`, and `scan_diff` handles only F/C (`:749-750`). Relative `include.path` values are resolved against the config's directory, not a working tree (`:392`, `_snap_path "$val" "$(dirname -- "$f")"`), so it is correct that they have no W.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:352`, `:388`, `:392`, `:396`, `:749-750`

---

## Claim 14: B11 — "The private `index` has the same standing as the main checkout's `index`, which the scan never recorded (parity, no new route)"

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:83`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the scan not recording any `index` file; does not establish that an index cannot influence what git runs (the header's `:97` says the scan never refreshes one; that is a claim about the scan, not about host git).
**Legibility-target:** for-orchestrator-synthesis

`grep -n index devcontainer-config/cc-exit-scan.sh` finds only `:97` ("Nothing refreshes an index…"), `:699` (an array index) and `:759` (awk `index()`). No `_snap_*` call records an index (paraphrased — no quote available because the claim is about absence of code: no matching grep results). `_snap_gitdir`'s fixed layout list (`:572-632`) has no `index`.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:97`, `:572-632`

---

## Claim 15: B14 — "When the worktree's `.git` resolves on the host, `_snap_host_config` already walks it for that git dir and any path inside the checkout becomes a new record (residue). When it does not resolve (container form, host not at `/workspace`), host git in it stops (E10)"

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:86`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a global relative `core.hooksPath` with a host-form worktree, and git stopping on a missing private dir; does not establish the `includeIf gitdir:` sub-case by execution (read statically: `_snap_cond` gets the worktree's git dir as `$g`, `:695`).
**Legibility-target:** for-orchestrator-synthesis

```bash
# devcontainer-config/cc-exit-scan.sh:691-696
    while IFS= read -r -d '' f; do
      [ "$f" != "$_snap_ws/.git" ] || continue
      _snap_dotgit "$f" || { rc=1; break; }
      g="$(_snap_dotgit_target "$f")" || { rc=1; break; }
      [ -z "$g" ] || _snap_host_config "$g" "$f" "${f%/*}" || { rc=1; break; }
    done < "$list"
```

`_snap_dotgit_target` returns empty when the named dir does not exist (`:541`), which is the container-form case. X4 gives status 1 with `+ hooksdir …/agent-x/.ghooks missing`. X1 (E10) shows git stopping.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:530-543`, `:691-696`, `$SP/exp4.log`, `$SP/exp1.log`

---

## Claim 16: B21 — "Rule 6 requires `P` gone on disk. E10: a private dir without HEAD is refused by git anyway"

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:93`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the HEAD-removed and HEAD+commondir-removed shapes; does not establish other ways of hiding a private dir from `_snap_nested` (e.g. an unreadable dir, which fails the snapshot, exit 4).
**Legibility-target:** for-orchestrator-synthesis

`[ ! -e "$p" ] && [ ! -L "$p" ] || return 1` (`:847`). T1 test 3 removes `HEAD` and `commondir` from `agent-x`'s private dir and gets status 1, then `rm -rf` of the private dir gives 0 (`test/cc-isolated-functions.bats:2279-2287`). X1: no HEAD gives `fatal: not a git repository`.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:847`, `test/cc-isolated-functions.bats:2279-2287`, `$SP/exp1.log`, `$SP/bats-q094-c.log`

---

## Claim 17: B24 — "Rule 5 checks the snapshot-time hashes and the disk"

**Location:** `docs/working/plan-q094-exit-scan-worktree-layout.md:96`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers `commondir` and the worktree `.git` file (record hash and disk); does not establish a snapshot-time check of the back-pointer `P/gitdir` or of P's absent entries (disk only, since the snapshot does not record them), or anything changed after the check ("covered as far as the scan can").
**Legibility-target:** for-orchestrator-synthesis

commondir: record regex `:841-842`, then disk `_snap_file_is "$p/commondir" "$std"` (`:853`). `.git`: `[[ "$attrs" =~ $re ]] && _snap_file_is "$wt/.git" "$h"` (`:885`). The back-pointer and the absence of hooks/config are disk-only (`:854-863`). That is consistent with "as far as the scan can", because the snapshot has no record for them beyond `hooksdir … missing`.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:841-863`, `:885`

---

## Claim 18: "A linked worktree added or removed in git's own layout (an agent worktree left behind) is not a finding: one `note:` line, and the exit status is claude's."

**Location:** `guides/cc-isolated-usage.md:66-68`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the launcher's status and output for a session that adds a standard worktree; does not establish a live host session (commit trailer: `Live-verified: no`).
**Legibility-target:** for-orchestrator-synthesis

T1 test 8 runs `cc-isolated.sh` with a stubbed session that runs `git worktree add`. It gets status 0, the note, and no `WARNING` (`test/cc-isolated-functions.bats:2385-2393`). The mapping is `0) exit "$rc"` (`devcontainer-config/cc-isolated.sh:747`).

**Evidence:** `guides/cc-isolated-usage.md:66-68`, `devcontainer-config/cc-isolated.sh:747`, `$SP/bats-q094-c.log`

---

## Claim 19a: "A linked worktree takes its config, hooks and `info/attributes` from the checkout's own `.git`, never from its private dir (tested on git 2.39.5)."

**Location:** `guides/cc-isolated-usage.md:338-339`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claim 1; does not establish other git versions.
**Legibility-target:** for-author

This is the same sentence as Claim 1, with the same gap. X2 shows `P/config.worktree` is read once `extensions.worktreeConfig` is set. The rule's own list a few lines later already names `config.worktree` as refused, so a precise wording could say "…never from its private dir, except `config.worktree` (which the rule refuses)."

**Evidence:** `guides/cc-isolated-usage.md:338-339`, `$SP/exp2.log`

---

## Claim 19b: "'Exact' (`scan_std_worktrees` has the full rule): the private dir is the checkout's own `.git/worktrees/<name>` … Anything else warns as before, worktree lines included — also any other change in the session, a working tree deleted without a prune, and any checkout whose config holds a relative `core.hooksPath` or `core.attributesFile` (husky's `.husky/_`) or a relative local remote, which git would resolve in the new worktree's tree, unscanned."

**Location:** `guides/cc-isolated-usage.md:340-350`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every listed condition against `scan_std_worktrees` and T1 tests 1-7; does not establish the guide's "checkout's own `.git/worktrees`" wording for a checkout that is itself a linked worktree (the common dir is then elsewhere; the code uses `<common>/worktrees`).
**Legibility-target:** for-orchestrator-synthesis

Each clause maps to code already quoted in Claim 5 (`:838` name, `:841-842`/`:853` commondir, `:854-858` hooks/config/config.worktree/symlink, `:864-872` inside the checkout, `:882-891` `.git` and container form). T1 tests cover: plant + worktree lists both (test 1); deleted without prune gives `- dotgit` and status 1 (test 3); relative hooksPath/attributesFile/remote warns (test 7); container form resolving elsewhere warns (test 2).

**Evidence:** `guides/cc-isolated-usage.md:340-350`, `devcontainer-config/cc-exit-scan.sh:838-891`, `$SP/bats-q094-c.log`

---

## Claim 20: "The same holds in a linked worktree the session leaves behind: its files are never read, only its layout (see above)."

**Location:** `guides/cc-isolated-usage.md:364-365`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what the scan reads inside a new worktree's working tree; does not establish anything about host git's behaviour there.
**Legibility-target:** for-author

The point is right: tracked files in the new worktree (a `scripts/check.sh` a common hook runs) are not hashed. But "its files are never read" is too broad. The scan reads the worktree's `.git` file (hash, `_snap_file_is "$wt/.git"`, `:885`). It searches the whole tree for embedded `.git` entries (`_snap_find "$list" "$_snap_ws" -mindepth 2 -name .git`, `:688`, which is how plan B16's "an embedded `.git` inside the new worktree's tree" is covered and how T1 test 6's `inner` repo warns). It also resolves your own config's relative hooksPath/attributesFile in it (`:695`, X4). Precise version: "its tracked files are never read; only its layout, its `.git` file and any git dirs inside it."

**Evidence:** `guides/cc-isolated-usage.md:364-365`, `devcontainer-config/cc-exit-scan.sh:688-696`, `:885`, `test/cc-isolated-functions.bats:2346-2352`

---

## Claim 21: The eight Q-094 test names match what the tests assert

**Location:** `test/cc-isolated-functions.bats:2227-2393`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each `@test` name against its assertions, and that all eight pass with a valid locale; does not establish robustness of test 1's `wc -l -eq 1` against stderr noise (it fails when bash emits `setlocale` warnings, T0).
**Legibility-target:** for-orchestrator-synthesis

(paraphrased — no quote available because the claim spans eight test bodies, each quoted by line range in Evidence)
- Test 1: asserts status 0, one line and the note, then status 1 with both the dotgit and hook lines after a plant.
- Test 2: host dir absent gives 0, a symlink to ws gives 0, another dir gives the warning.
- Test 3: removed gives `(removed: agent-y)`, then add+remove, then a half-removal warns.
- Test 4: commondir variants, hooks, config, config.worktree and an `info` symlink each warn, and the restored layout gives 0.
- Test 5: `.git` variants, back-pointer variants and the FIFO warn, and a directory `.git` warns.
- Test 6: embedded repo, `+` name and nested bare repo's worktree warn.
- Test 7: relatives warn, the absolute control gives 0.
- Test 8: launcher status 0 with the note.

T1: `ok 1`…`ok 8`.

**Evidence:** `test/cc-isolated-functions.bats:2227-2393`, `$SP/bats-q094-c.log`, `$SP/bats-q094.log`

---

## Claim 22: "git keeps '+' in a worktree name (a space it turns into '-')."

**Location:** `test/cc-isolated-functions.bats:2356`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5's private-dir naming for `agent+x` and `a b`; does not establish other characters.
**Legibility-target:** for-orchestrator-synthesis

X5: after `git worktree add …/wts/agent+x` and `…/wts/a b`, `ls .git/worktrees` prints `a-b` and `agent+x`.

**Evidence:** `test/cc-isolated-functions.bats:2356`, `$SP/exp5.log`

---

## Claim 23: "The rest of the scan checks -f before every read; this one now does too."

**Location:** commit 5a6d689 message (body, line 3)
**Type:** Invariant / Error-handling
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `_snap_worktree_of`'s unguarded `git config --file` read, reached from `_snap_gitdir`'s legacy remotes/branches loop; does not establish whether other unguarded reads exist (only this one was found and executed).
**Legibility-target:** for-author

`_snap_worktree_of` reads the config file it is given with no `-f` test:

```bash
# devcontainer-config/cc-exit-scan.sh:320-331
_snap_worktree_of() {
  local gd v
  gd="$(cd "$(dirname -- "$1")" 2>/dev/null && pwd -P)" || gd="$(dirname -- "$1")"
  if [ "$gd" = "$_snap_gd" ] || [ "$gd" = "$_snap_common" ]; then
    printf '%s' "$_snap_ws"
  elif v="$(cd / && git --no-pager config --file "$1" --no-includes --get core.worktree 2>/dev/null)"; then
    _snap_path "$v" "$gd"
  elif [ "${gd##*/}" = .git ]; then
    printf '%s' "${gd%/*}"
  else
    printf '%s' "$gd"
  fi
}
```

`_snap_gitdir` calls it with `"$real/config"` for every legacy `remotes/`/`branches/` file, whether or not `config` is a regular file (`:602`, `:605`). The earlier `if [ -f "$real/$f" ]` at `:574` guards only `_snap_config`. X3: a worktree private dir `P` with `P/remotes/foo` (`URL: /nowhere`) and a FIFO at `P/config`. `timeout 10` around `git_exec_snapshot` exits 124 (hung). Removing the FIFO gives 0. Keeping the FIFO but removing `remotes/` gives 0, so the hang is on that path. In a real session this is the same outcome the commit fixed for `gitdir`: a hang, then Ctrl-C and exit 4, never a pass. The code is pre-existing; what is wrong is the sentence's "every read" claim. Not logged as a hallucination pattern: it is an over-generalised invariant, not a fabricated symbol or API.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:320-331`, `:572-575`, `:588-608`, `$SP/exp3.sh`, `$SP/exp3.log`

---

## Claim 24: "A FIFO planted at .git/worktrees/<n>/gitdir blocked the exit scan's read in scan_std_worktrees (a hang, then Ctrl-C and exit 4). … Test: a FIFO there warns within a timeout."

**Location:** commit 5a6d689 message (body, lines 1-4)
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the pre-fix read (static, at b4de821) and the new test (executed); does not establish the pre-fix hang by execution at b4de821.
**Legibility-target:** for-orchestrator-synthesis

At b4de821 the back-pointer was read directly: `line="$(_snap_first_line "$p/gitdir" 2>/dev/null)" || return 1` (`git show b4de821:devcontainer-config/cc-exit-scan.sh`, line 860), with no `-f` check, and `_snap_first_line`'s `read` (`:210`) blocks on a FIFO. Ctrl-C then triggers `scan_interrupted`, which exits 4 (`:984-992`). The test is `test/cc-isolated-functions.bats:2336-2338` and passes (T1).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:210`, `:984-992`, `test/cc-isolated-functions.bats:2336-2338`, `$SP/bats-q094-c.log`

---

## Claim 25: b4de821 message — rule summary; "(the launcher passes claude's status through)"; "git resolves them in the new worktree's own tree (verified in a scratch repo), so any W record declines the note. scan_diff ignores W records, so warning output is unchanged."

**Location:** commit b4de821 message (body)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the rule summary against `scan_std_worktrees`, the launcher mapping, E7 and `scan_diff`'s F/C filter; does not establish the "Live-verified: no" live check (open by the author's own statement).
**Legibility-target:** for-orchestrator-synthesis

The rule summary ("commondir is exactly "../..\n"; the .git file is exactly "gitdir: P\n" by host path or by the container's /workspace path (which must be P if it exists on the host); … names of [A-Za-z0-9._-] only. Removed worktrees need P gone on disk.") matches `:838-903` (Claim 5). The status pass-through is `devcontainer-config/cc-isolated.sh:747` (Claim 10). E7 was re-run in X4. The W filter is at `:749-750` (Claim 3).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:749-750`, `:838-903`, `devcontainer-config/cc-isolated.sh:747`, `$SP/exp4.log`

---

## Claim 26: 6abe247 message — "per-worktree hooks, info/attributes and config are never read"

**Location:** commit 6abe247 message (body)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the private dir's `hooks/`, `info/attributes`, `config` and `config.worktree` on git 2.39.5; does not establish other versions.
**Legibility-target:** for-author

The claim is true for `P/hooks`, `P/info/attributes` and `P/config` (X1). "Per-worktree config" is also git's own name for `config.worktree`, and that file is read when the common config sets `extensions.worktreeConfig` (X2). The plan body's E6 says the same, so the commit summary is looser than the plan it introduces. The code refuses a private dir with `config.worktree` (`:854-856`), so no bypass follows.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:854-856`, `docs/working/plan-q094-exit-scan-worktree-layout.md:36`, `$SP/exp1.log`, `$SP/exp2.log`

---

## Claims Requiring Attention

### Incorrect
- **Claim 23** (commit 5a6d689): "The rest of the scan checks -f before every read" is false. `_snap_worktree_of` (`devcontainer-config/cc-exit-scan.sh:325`) runs `git config --file "$real/config"` unguarded from the legacy remotes/branches loop (`:602`, `:605`). A FIFO `config` in a git dir with a `remotes/` file hangs the snapshot (X3, timeout 124). Either reword the message or add the `-f` guard in `_snap_worktree_of`.

### Mostly Accurate
- **Claim 1** (`devcontainer-config/cc-exit-scan.sh:78-79`): "never the private one" needs "except `config.worktree` under `extensions.worktreeConfig` (refused by the rule)".
- **Claim 9b** (`devcontainer-config/cc-exit-scan.sh:914-915`): status 2 also covers "snapshots differ but nothing rendered" (`:954-957`). Pre-existing wording.
- **Claim 12** (`docs/working/plan-q094-exit-scan-worktree-layout.md:52`): "no config the scan reads" should be "no repo config". Host-config relative values give F records (still declining), not W.
- **Claim 19a** (`guides/cc-isolated-usage.md:338-339`): the same `config.worktree` qualifier as Claim 1.
- **Claim 20** (`guides/cc-isolated-usage.md:364-365`): "its files are never read" should be "its tracked files". The scan reads its `.git` file and searches its tree for git dirs.
- **Claim 26** (commit 6abe247): "per-worktree … config are never read" is contradicted for `config.worktree` with the extension. The plan's E6 says so.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to docs/reviews/code-fact-check-report.md (in the worktree), structured per the code-fact-check skill, with `**Commit:** 5a6d689` and `**Replication:** k=1 (loop pass, decision 031)` in the header.
- Answered: yes. All 8 requested claim areas were checked; items 1, 6, 7 and 8 were executed in scratch repos and bats.
- Out of scope: the plan's pre-mortem rows other than B11/B14/B21/B24 (read, not verdicted individually); E8, E9 and E12's `worktrees/` removal (not re-run); the container image's git version (a shell check was blocked by a classifier error).
- Escalate: Claim 23 is a real (pre-existing) FIFO hang in `_snap_worktree_of`: fail-closed (exit 4 after Ctrl-C), not a bypass, but it contradicts the commit message the fix rests on. Also, bats test 1 fails under a broken `LC_ALL` because it counts output lines.
- Decisions I made: verdicted the `config.worktree` omission as Mostly accurate rather than Incorrect, because the rule explicitly refuses `config.worktree` so no reader acting on the sentence is led into a bypass; overwrote the tracked prior report at this path as the success criterion requires; did not append to `hallucination-patterns.md` (the Incorrect is an over-generalised invariant, not a fabrication, and edits outside the report were not permitted).
