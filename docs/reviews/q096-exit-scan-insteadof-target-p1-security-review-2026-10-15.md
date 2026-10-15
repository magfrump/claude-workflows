Commit: 5f754994

# Security Review — fix/q096-exit-scan-insteadof-target (Q-096, pass 1)

**Scope:** `git diff main...HEAD` (b279a2ba..5f754994); enclosing functions in `devcontainer-config/cc-exit-scan.sh` (`_snap_remote`, `_snap_url`, `_snap_rule`, `_snap_rewrite`, `_snap_config`, `_snap_host_config`, `_snap_gitdir`, `git_exec_snapshot`) read in full; `guides/cc-isolated-usage.md` "Known routes it does not see".
**Date:** 2026-10-15
**Based on:** docs/reviews/q096-exit-scan-insteadof-target-p1-code-fact-check-report.md (Stage 1, via shared brief); goal preamble supplied by the orchestrator.
**Experiments:** hermetic, git 2.39.5 / bash 5.2.15, under `/home/node/.claude/jobs/00bcf178/tmp/q096/probe-security/` (`e1.sh`, `e3.sh`, `e4.sh`, `e5.sh`; `GIT_CONFIG_GLOBAL` in that dir, `GIT_CONFIG_NOSYSTEM=1`, `HOME` in that dir). Each probe takes a snapshot, plants a bare repo with a `pre-receive` hook, snapshots again, diffs, then runs the real `git push`.

## Trust Boundary Map

```
B1: [container-written repo config / legacy remotes files / embedded repos] → [_snap_config, _snap_gitdir: URLs → _snap_url, rules → _snap_rule] → [worklist in git_exec_snapshot]
B2: [your global/system config (host-owned, read-only to the container)]   → [_snap_host_config: rules only → _snap_rule]                    → [worklist]
B3 (new): [worklist (URL, rule) pairs]                                       → [_snap_rewrite: bash prefix match + ${u:${#p}} + rwseen dedupe] → [_snap_remote walk → F/W records]
B4: [container-chosen paths/values in records]                               → [%q / _snap_fail / scan_vis]                                     → [your terminal]
B5: [snapshot before vs after]                                               → [scan_diff]                                                       → [finding / exit 3, or exit 4 on failure]
```

Input-source classification:

```
S1: repo config entries (checkout, includes, embedded repos, walked remotes) — runtime-mutable by the session — UNTRUSTED for path-construction/walk sinks and terminal output; any change is itself a C-record finding (B5), so S1 can only be abused without a finding through state already present at launch
S2: legacy remotes/* and branches/* file contents — runtime-mutable — UNTRUSTED (same as S1; files are F records)
S3: your global/system config (rules, remotes, includes) — host-owned, not container-writable — trusted as to provenance, but its values are NOT recorded, so a target it names is only seen if the scan walks it
S4: filesystem state at rewrite targets inside the checkout — runtime-mutable — UNTRUSTED; this is what the session plants
S5: locale (LC_ALL/LANG of your shell) — host-chosen, deploy-time — trusted, but changes bash's string semantics in B3
S6: GIT_EXIT_SCAN_MAX_REWRITES — code constant assigned at source time (env cannot override) — trusted
```

What crosses: URLs and rules from S1/S2/S3 meet in the worklist; every match yields a path the session may create (S4). The diff's safety claim is that every (URL, rule) pair git could apply is compared and every git-reachable rewritten target is walked. The attacker cannot add URLs or rules without a C/F finding, so the residual surface is (a) launch-time URLs/rules whose targets the scan computes differently from git, (b) URL sources git reads that the worklist never receives, and (c) making the scan stall or fail.

## Findings

#### 1. A remote defined in your own global/system config is never queued, so your own rule rewriting it into the checkout is unwalked — and the guide no longer lists the route

**Severity:** Medium
**Location:** `devcontainer-config/cc-exit-scan.sh:563-566` (`_snap_host_config`), `guides/cc-isolated-usage.md:411-416` (bullet removed after "A slow scan")
**Boundary:** B2, B3
**Move:** #11 (bypass enumeration), #1
**Confidence:** High (mechanism, experiment-confirmed); likelihood depends on your config defining `remote.*.url` globally
**Legibility-target:** guide "Known routes it does not see" (user); `_snap_host_config` header comment (maintainer)

Evidence (verbatim):
```
    # Your rewrite rules apply to the repo's URLs too (an empty value matches all).
    case "$key" in
      url.*.insteadof|url.*.pushinsteadof) t="${key#url.}"; _snap_rule "${t%.*}" "$val" ;;
    esac
```
`_snap_host_config` queues only rules; `remote.*.url`/`pushurl`, `remote.pushDefault` and `branch.*.remote|pushRemote` from your config never reach `_snap_url`/`_snap_names` (and `_snap_rnames` never learns host-defined remote names). The removed guide bullet ("A URL rewritten by `url.<base>.insteadOf` ... runs that repository's hooks on push") was the only place this residual was documented; the remaining list has no entry for host-defined remotes or URLs typed on the command line.

Experiment `e1.sh`: global config `remote.hostr.url = plant:` and `url.<ws>/evil.git.insteadOf = plant:`; snapshot; session plants `<ws>/evil.git` with a `pre-receive` hook; snapshot. Result: `E1 diff: (no diff)`, then `git push hostr master` printed `remote: E1-HOOK-RAN`. (Matches the Stage-1 fact-check "still open" note.)

**Recommendation:** Either queue `remote.*.url`/`pushurl` (and path-valued names) from `_snap_host_config` with the working tree `wt`, or restore a narrowed Known-routes bullet: "a remote defined in your own global/system config, or a URL you type on the command line, rewritten by an `insteadOf` rule to a path inside the checkout". The commit message and guide text should not read as closing the whole route.

#### 2. Under a UTF-8 locale the prefix match is character-wise, not byte-wise as git's: a rule whose value ends mid-character matches in git but not in the scan

**Severity:** Medium
**Location:** `devcontainer-config/cc-exit-scan.sh:414-416` (`_snap_rewrite`)
**Boundary:** B3 (S5 changes its semantics)
**Move:** #2, #11
**Confidence:** High that the mismatch exists (experiment); Low likelihood (needs a launch-time rule and URL with that byte shape; the session cannot add either without a C finding)
**Legibility-target:** `_snap_rewrite` comment "git's alias_url: plain, case-sensitive" (maintainer)

Evidence (verbatim):
```
  [[ "$u" == "$p"* ]] || return 0
  t="${_snap_rbases[$2]}${u:${#p}}"
```
`git_exec_snapshot` does not set `LC_ALL=C` (only `sort`, `tr`, `awk` get it), so bash matches and slices in the caller's locale. Experiment `e3.sh`: URL `$'\xc3\xa9vil'`, rule `url."./x".insteadOf = $'\xc3'`. Under `LC_ALL=C` the scan records `.../ws/./x\251vil` (correct); under `LC_ALL=C.utf8` it records only the unrewritten `.../ws/\303\251vil` and nothing under `./x…`. git (either locale) tries `fatal: './xM-)vil' does not appear to be a git repository` — i.e. pushes to the path the UTF-8 scan never walks. Typical hosts run `en_US.UTF-8`.

**Recommendation:** Make the comparison byte-wise: `local LC_ALL=C` at the top of `_snap_rewrite` (bash re-reads the locale on assignment), or compare `"${u:0:${#p}}" == "$p"` with both lengths taken under `LC_ALL=C`. Add a bats case with a split UTF-8 prefix run under `C.utf8`.

#### 3. Tab-joined dedupe keys collide: a second rule (or URL, or target) is silently dropped

**Severity:** Medium
**Location:** `devcontainer-config/cc-exit-scan.sh:384, 394, 416` (`_snap_url`, `_snap_rule`, `_snap_rewrite` keys)
**Boundary:** B1, B3
**Move:** #11
**Confidence:** High that the drop happens (experiment); Low likelihood (both colliding entries must be present at launch)
**Legibility-target:** `_snap_rule` / `_snap_url` comments ("once each") (maintainer)

Evidence (verbatim):
```
  local k="r:$1"$'\t'"$2"
  [ -z "${_snap_rwseen["$k"]:-}" ] || return 0
```
(also `local k="u:$1"$'\t'"$2"` and `k="t:$t"$'\t'"${_snap_ubases[$1]}"`). git allows a tab in a subsection name and in a value, so base `a\tb` + value `c` and base `a` + value `b\tc` share the key `r:a\tb\tc`. Experiment `e5.sh`: `remote.r.url = "b\tcEVIL"`, `url."sub/a\tb".insteadOf = c`, `url."sub/a".insteadOf = "b\tc"`; records naming `sub/aEVIL`: `0`; after planting `sub/aEVIL` with a hook: `E5 diff: (no diff)`; `git push r master` printed `remote: E5-HOOK-RAN`.

**Recommendation:** Use an unambiguous key, e.g. length-prefixed: `k="r:${#1}:$1$2"` (and the same for `u:`/`t:`). Cheap and removes the class.

#### 4. The 100,000-comparison cap bounds comparisons, not cost: a session can make the exit scan run for many minutes before it fails or finishes

**Severity:** Medium
**Location:** `devcontainer-config/cc-exit-scan.sh:400-420` (`_snap_rewrite`); `guides/cc-isolated-usage.md:326-327`
**Boundary:** B1, B3, B5
**Move:** #8
**Confidence:** High (timed)
**Legibility-target:** guide sentence "fails the scan (exit 4) rather than stalling it" (user); header "A slow scan" bullet

Evidence (verbatim):
```
# queued as a URL: git rewrites once. Past GIT_EXIT_SCAN_MAX_REWRITES comparisons
# the snapshot fails (a session can plant thousands of URLs and rules to stall it).
```
and guide: "More than 100,000 URL-and-rule comparisons fails the scan (exit 4) rather than stalling it."
Every matching pair with a distinct target runs `_snap_remote`, which forks `realpath` twice (`_snap_inside_ws`) plus record appends. Experiment `e4.sh` (N empty-value rules `url."./b$i/".insteadOf =` × N URLs, all matching, all distinct targets, all under the cap): N=100 (10,000 matches) took 47.5 s for one snapshot; N=316 (~99,856 matches, still under the cap, so the scan does not fail) did not finish within 580 s and was killed by `timeout` (run against the 5f754994 file extracted to `probe-security/old/`, since the worktree had moved on; no probe process left running). The plant is itself a C-record finding, but only once the scan finishes; a user who stops it gets exit 4 / "treat as unscanned", so this is an availability lever, consistent in kind with the existing "A slow scan" route but contradicting the guide's "rather than stalling it".

**Recommendation:** Cap matches walked (e.g. a few thousand distinct rewrite targets) rather than or in addition to comparisons, and/or do a pure-bash lexical inside-checkout pre-check before forking `realpath`. Reword the guide sentence and add rewrite rules/URLs to the "A slow scan" bullet.

#### 5. (Adjacent, pre-existing) A remote section with no `url` makes git use the remote NAME as the push URL; the scan skips that name

**Severity:** Medium
**Location:** `devcontainer-config/cc-exit-scan.sh:460-461` (`_snap_rnames` set for any `remote.<name>.*`), `:787` (worklist skips names in `_snap_rnames`)
**Boundary:** B1
**Move:** #5 (invert: which names does "defined" fail to cover?)
**Confidence:** High (experiment); Low likelihood (needs that config shape at launch); not introduced by this diff, but it sits in the worklist the diff rewrites and defeats Q-096's walk the same way
**Legibility-target:** worklist comment "Remote names that no remote defines are URLs or paths to git (remote.c)" (maintainer)

Evidence (verbatim):
```
        name="${key#remote.}"; name="${name%.*}"
        [ -z "$name" ] || _snap_rnames["$name"]=1
```
```
      [ -z "$f" ] || [ -n "${_snap_rnames["$f"]:-}" ] || _snap_url "$f" "$g" || rc=1
```
git 2.39 `remote.c` adds the name as a URL alias whenever the named remote is not `valid_remote` (no `url`), not only when no remote section exists. Experiment (second half of `e1.sh`): `remote.sub/evil.fetch = ...`, `branch.master.pushRemote = sub/evil`; plant bare `sub/evil` with a hook: `E2 diff: (no diff)`; both `git push` and `git push sub/evil master` printed `remote: E2-HOOK-RAN`. Same for a legacy `remotes/<name>` file with no `URL:` line (name marked defined at `_snap_gitdir`).

**Recommendation:** Mark a name defined only when it has a `url` (or `vcs`); queue the rest as URLs. Can be a follow-up unit (Q-097 is on the same file).

## Untested bypass candidates

- **URL typed on the command line** (`git push ../x` or `git push plant:` with a rule): not snapshot-able by design; untested because nothing in config carries it. Should be named in Known routes (see Finding 1).
- **`~` in a rewritten target** (`url."~/src/".insteadOf`): git's non-strict `enter_repo` expands `~/`; the scan resolves it relative to the working tree. Not tested; already covered in prose by the existing "`~` forms" bullet ("a `~` in a local remote URL"), which arguably includes rewritten URLs — worth one word ("or rewritten") there.
- **Rewrite target reaching a container-writable dir outside the checkout** (another mount): `_snap_inside_ws` excludes it by design; inherits the existing "symlink to a directory outside the checkout" assumption. Not tested.

## Endorsement Claims

- **Claim:** The worklist compares every queued URL with every queued rule exactly once, including URLs and rules discovered while walking a rewritten target or a path-valued name.
  **Location:** `devcontainer-config/cc-exit-scan.sh:777-797`
  **Evidence:** read-static (plus Stage-1 executed verdict)
  **Verified:** read the full loop: the invariant "all pairs (x<u, y<r) compared" holds on each `u++`/`r++` step; new entries land at indexes ≥ the cursor; a failing `_snap_rewrite` sets rc=1 and the outer `while` exits before `printf`, so the snapshot fails closed.
  **Not verified:** pairs whose dedupe key collides (Finding 3) — those are dropped before they are queued.
  **route: code-fact-check**
- **Claim:** The cap fails closed (exit 4 at session exit, launch refusal at start) and cannot be raised from the environment.
  **Location:** `devcontainer-config/cc-exit-scan.sh:405-412`
  **Evidence:** read-static (assignment is unconditional at source time); Stage-1 executed the exit/launch codes
  **Verified:** `GIT_EXIT_SCAN_MAX_REWRITES=100000` assigned when sourced; `_snap_rewrite` returns 1 past it, propagated as above.
  **Not verified:** how long a run under the cap takes (Finding 4).
- **Claim:** New container-chosen strings (rewrite targets) reach output only as `%q`-quoted F/W record paths; the new `_snap_fail` message interpolates only the numeric cap.
  **Location:** `devcontainer-config/cc-exit-scan.sh:410-411`, `_snap_file`, `_snap_wrel`
  **Evidence:** executed (records from e3/e5 printed as `$'...\t...'` / `\251`)
  **Verified:** record format in probe output; `scan_vis` (`LC_ALL=C tr -c '[:print:]\n' '?'`) on the report path.
  **Not verified:** scan_diff's rendering of very long target strings in the terminal (width, not escapes).

## Primitive sweep

Primitive: path construction → filesystem walk (`_snap_remote` on a computed target)
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `cc-exit-scan.sh:419` `_snap_remote "$t" ...` (rewritten target) | S1, S2, S3 | prefix match, rwseen dedupe, cap | Findings 2, 3, 4 |
| `cc-exit-scan.sh:389` `_snap_url` → `_snap_remote` (raw URL) | S1, S2 | rwseen dedupe | Finding 3 (key collision); cleared otherwise |
| `cc-exit-scan.sh:471` `_snap_remote "$t" "$base"` (rule base alone) | S1 | none needed (base walked as before) | cleared — pre-existing behaviour, unchanged |
| `cc-exit-scan.sh:679,682` legacy files → `_snap_url` | S2 | — | cleared — now also rewritten; Finding 5 for URL-less legacy remotes |
| `cc-exit-scan.sh:787` names → `_snap_url` | S1 | `_snap_rnames` | Finding 5 |
| host config remotes | S3 | — | not reached at all — Finding 1 |

Primitive: process exec — the diff adds none (no new `git`, `eval`, or command built from a value); `_snap_remote`'s `realpath` takes the target as an argument after `--`. Cleared.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Host-defined remote rewritten by your rule: unwalked; guide no longer lists it | Medium | B2, B3 | `cc-exit-scan.sh:563-566`, guide `:411-416` (bullet removed after "A slow scan") | High (exp.) |
| 2 | UTF-8 locale: char-wise prefix match diverges from git's byte-wise match | Medium | B3 | `cc-exit-scan.sh:414-416` | High mechanism / Low likelihood (exp.) |
| 3 | Tab-joined dedupe keys collide, dropping a rule/URL/target | Medium | B1, B3 | `cc-exit-scan.sh:384,394,418` | High mechanism / Low likelihood (exp.) |
| 4 | Cap bounds comparisons, not time; many-minute stall under the cap | Medium | B1, B3, B5 | `cc-exit-scan.sh:400-420`, guide `:326-327` | High (timed) |
| 5 | (Pre-existing) URL-less remote section: git uses the name as URL; scan skips it | Medium | B1 | `cc-exit-scan.sh:460-461,787` | High mechanism / Low likelihood (exp.) |

## Overall Assessment

The change closes the route it targets for the common shape (a launch-time repo URL rewritten by a launch-time repo or host rule into a path the session plants): the worklist logic is sound and fails closed, and no new exec or terminal-injection surface is added. No HALT-level issue. The residuals are where the scan's model of git diverges: one documentation-level gap that the guide edit made invisible (Finding 1, the most important to address — either queue host-config remotes or restore a narrowed Known-routes bullet), two small fidelity bugs fixable in a line each (byte-wise matching under `LC_ALL=C`, length-prefixed dedupe keys), and a cap that bounds work count but not wall time, which contradicts the guide's "rather than stalling it". Findings 2, 3 and 5 need launch-time state the session cannot plant unseen, which is why their likelihood is low; all five are fixable in place, none is architectural. Endorsement claims above are scoped; no categorical all-clear.

## Goal-Alignment Note

The user goal is that a session cannot repoint a push through an `insteadOf`/`pushInsteadOf` rewrite the scan ignores. Against that goal the diff delivers for repo-defined URLs, and Findings 2 and 3 are exactly the "rewrite the scan ignores" class surviving in edge encodings — fixing them is in scope for Q-096. Finding 1 is in scope as legibility at minimum: the guide edit removed the only documentation of a residual rewrite route, so either the code or the Known-routes list should change before landing. Finding 4 is an availability concern the diff introduced while trying to bound it; rewording the guide is in scope, a tighter cap can follow. Finding 5 is pre-existing and adjacent: a good candidate for Q-097 or a separate unit rather than a blocker here.

## Addendum (written after the probes finished)

This review covers 5f754994. While it ran, the branch moved to e4b29291 ("Q-096 review iteration 1"), which says it addresses Findings 1–5, using an earlier copy of this report that still had the N=316 timing missing. Those fixes were **not** re-reviewed here. One side observation: running `e4.sh 316` against the e4b29291 worktree file failed closed in 11.8 s with `more than 2000 distinct URLs rewritten by insteadOf rules to walk: too many, treat the checkout as unsafe` (rc=1, no records). That fits the new target cap, but the cap was not otherwise probed.
