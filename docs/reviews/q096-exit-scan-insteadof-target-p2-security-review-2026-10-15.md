Commit: e4b29291

# Security Review: fix/q096-exit-scan-insteadof-target (Q-096, pass 2, full branch)

**Scope:** `git diff main...HEAD -- . ':!docs/reviews'` (b279a2ba..e4b29291). I read every enclosing function in `devcontainer-config/cc-exit-scan.sh` in full (`_snap_remote`, `_snap_url`, `_snap_rule`, `_snap_pairs`, `_snap_match`, `_snap_walk_hits`, `_snap_rewrite`, `_snap_config`, `_snap_host_config`, `_snap_gitdir`, `git_exec_snapshot`, `git_exit_scan`, `scan_std_worktrees`), plus the launcher's snapshot call (`cc-isolated.sh:859-867`), the guide diff and the Q-096 bats tests.
**Date:** 2026-10-15
**Based on:** the shared brief (goal preamble, claims 1-6). The pass-1 security report (`q096-exit-scan-insteadof-target-p1-security-review-2026-10-15.md`, on 5f754994) was used only as a list of earlier findings to re-check.
**Experiments:** all hermetic: git 2.39.5, bash 5.2. Scripts are in `/home/node/.claude/jobs/00bcf178/tmp/q096/probe-security-p2/` (`lib.sh`, `e1.sh`, `e2.sh`, `push.sh`, `e8.sh`, `e9.sh`), with `HOME` and `GIT_CONFIG_GLOBAL` inside that dir and `GIT_CONFIG_NOSYSTEM=1`. Each bypass probe does four things:
1. Puts the config and a bare target repo in place.
2. Takes the launch snapshot.
3. Plants a `pre-receive` hook in the target.
4. Runs `git_exit_scan`, then the real `git push`.

Every process ran in the foreground under `timeout` (at most 500 s). None was left running (checked with `ps`).

> ⚠️ **No code fact-check report provided for this pass.** Claims about security properties in comments and docs were checked against the code and by experiment, not by a separate fact-check run.

## Status of the pass-1 fixes

| Pass-1 finding | Fix in e4b29291 | Holds? |
|---|---|---|
| 1. Your own remotes were never queued | `_snap_host_config:615` queues `remote.*.url`/`pushurl` | Yes, for remotes defined in your config. Bats test 8 passes. Remote *names* in your config (`remote.pushDefault`, `branch.*.pushRemote`) are still not queued: see Untested bypass candidates. |
| 2. The UTF-8 match compared characters | `local LC_ALL=C` in `_snap_match` | Yes. Experiment e8: the match happens and the locale is restored after the call, whether the caller had `LC_ALL` unset or set. |
| 3. Tab-joined dedupe keys collided | Length-prefixed keys | **Partly.** The prefix is a character count, so rule keys still collide under a UTF-8 locale: Finding 1. |
| 4. The cap bounded comparisons, not time | 2,000-target cap; pair cap charged per batch | Forks are now bounded. Per-comparison cost grows with value length and is not bounded: Finding 4. |
| 5. A remote with no url was skipped | A name counts as defined only with `url`/`vcs` or a legacy URL line | Only for the tested shape. Findings 2 and 3 cover the shapes where the scan still counts a name as defined when git does not. |
| (new) `LC_ALL=C IFS= read` | Every `read` in the file | Yes. Experiment e8: a NUL after `\xc3` gives 2 entries with the prefix and 1 without it, and the shell's locale is unchanged afterwards. |

## Trust Boundary Map

```
B1: [container-written repo config, legacy remotes/branches files, embedded and walked repos] → [_snap_config / _snap_gitdir: URLs → _snap_url, rules → _snap_rule, names → _snap_names / _snap_rnames] → [worklist in git_exec_snapshot]
B2: [your global/system config (host-owned)]          → [_snap_host_config: rules → _snap_rule, remote urls → _snap_url (new)] → [worklist]
B3: [worklist (URL, rule) pairs and remote names]     → [dedupe keys (_snap_rwseen), _snap_rnames "defined" test, _snap_match under LC_ALL=C, caps] → [_snap_remote walk → F/W records]
B4: [URL string chosen for a walk]                     → [_snap_remote: scheme/ssh test, file:// strip, base join] → [filesystem path that gets walked]
B5: [container-chosen strings in records and errors]   → [%q / _snap_fail / scan_vis]                     → [your terminal]
B6: [launch snapshot vs exit snapshot]                 → [scan_diff / git_exit_scan]                      → [finding (1), clean (0), unreadable (2 → launcher exit 4)]
```

```
S1: repo config entries (checkout, includes, embedded repos, walked remotes) — runtime-mutable by the session — UNTRUSTED for the path-construction/walk sinks and for terminal output. Any change is itself a C finding (B6), so S1 is useful to an attacker only through state already present at launch, including state an earlier session planted and you left in place after its warning.
S2: legacy remotes/* and branches/* file contents — runtime-mutable — UNTRUSTED. The files are F records, so the same rule applies as for S1.
S3: your global/system config — host-owned — trusted as to where it came from. Its values are not recorded, so a target it names is only seen if the scan walks it.
S4: filesystem state at the targets of rewrites and names inside the checkout — runtime-mutable — UNTRUSTED. This is what the session plants, without a finding unless the target is walked.
S5: locale of your shell (LC_ALL/LANG) — host-chosen — trusted, but it changes how bash measures and matches strings in B3/B4.
S6: GIT_EXIT_SCAN_MAX_REWRITE_PAIRS / _TARGETS — code constants assigned at source time — trusted.
```

The threat model has three parts:
- The session can change the records only by producing a finding.
- A bypass therefore needs a URL, rule or name present at launch whose git-effective push target the scan never walks. The session then plants a repo at that target. It needs no new config, so the plant produces no record.
- Every confirmed bypass below has that shape: launch-time state, then a silent plant of S4, then the real `git push` runs the planted hook.

## Findings

#### 1. Under a UTF-8 locale the "length-prefixed" rule key counts characters, so two launch-time rules still collide and the second is dropped

**Severity:** Medium
**Location:** `devcontainer-config/cc-exit-scan.sh:404-409` (`_snap_rule`, key at `:405`)
**Boundary:** B3 (S5 changes how the key is built)
**Move:** #11 (bypass enumeration: encoding variants of the pass-1 fix)
**Confidence:** High that the mechanism is real (confirmed by experiment). Low likelihood: both rules must already exist at launch, with bases that split a UTF-8 character.
**Legibility-target:** the comment above `_snap_url` ("Length-prefixed keys: a tab-joined key would let a URL or base holding a tab collide…") and claim 3 in the commit message (maintainer)

Evidence (verbatim):
```
_snap_rule() {
  local k="r:${#1}:$1$2"
  [ -z "${_snap_rwseen["$k"]:-}" ] || return 0
  _snap_rwseen["$k"]=1
  _snap_rbases+=("$1"); _snap_rpfx+=("$2")
}
```
`_snap_rule` runs in the caller's locale. Only `_snap_match` sets `LC_ALL=C`. In UTF-8, bash counts the lone byte `\xc3` as one character and `\xc3\xa9` (é) also as one character, so these two rules get the same key:
- base `sub/a\xc3`, value `\xa9c`
- base `sub/a\xc3\xa9`, value `c`

Both keys are `r:6:sub/a\xc3\xa9c`.

Experiment `e1.sh` has remote `r = cEVIL` and both rules, with the target `sub/a\xc3\xa9EVIL` planted after the snapshot:
```
e1-C scan-status=1 (0=clean/no finding); lines naming pre-receive: 1
e1-C push: remote: E1-HOOK-RAN
e1-C.utf8 scan-status=0 (0=clean/no finding); lines naming pre-receive: 0
e1-C.utf8 push: remote: E1-HOOK-RAN
```
git picks the longest matching value, which is `c`, so it pushes into the planted repo. Under a UTF-8 locale (typical on hosts) the scan reports nothing.

The `u:` and `t:` keys stay collision-free. Their second part is a working-tree path, which always starts with `/`. Appending a `/` can never merge into the previous character, so equal character counts imply equal strings.

**Recommendation:** Build every dedupe key under `LC_ALL=C`, for example with `local LC_ALL=C` at the top of `_snap_url`, `_snap_rule` and `_snap_rewrite`, or use a separator byte git forbids in names and values (NUL is impossible in bash; `\n` is not allowed in a subsection name). Add the e1 pair to the "tabs" bats test, run under `C.utf8`.

#### 2. A legacy remotes/branches file marks a remote name as defined in cases where git never reads that file, so a push to the name as a path is unwalked

**Severity:** Medium
**Location:** `devcontainer-config/cc-exit-scan.sh:715-737` (`_snap_gitdir` legacy loop; `:730` and `:734`), with the worklist test at `:840`
**Boundary:** B1, B3
**Move:** #5 (invert: which names does "defined" cover that git does not?)
**Confidence:** High (both variants confirmed by experiment). Low likelihood: needs that legacy file and that name at launch.
**Legibility-target:** the comment "The name counts as defined only once a URL is read from the file" (`:721-722`), the guide's "naming a path or a remote with no `url`", and claim 4 in the commit message (maintainer and user)

Evidence (verbatim):
```
      name="${f#"$real/$d/"}"
...
        if [ "$d" = branches ]; then
          _snap_rnames["$name"]=1
          _snap_url "${line%%#*}" "$(_snap_worktree_of "$real/config")" || return 1
          break
        fi
        case "$line" in URL:*) _snap_rnames["$name"]=1; line="${line#URL:}"; ...
```
git 2.39 (`remote.c`, `remotes_remote_get_1`) reads a legacy file only when two things hold:
- the name passes `valid_remote_nick`, meaning it is not empty, `.` or `..`, and has no `/`;
- the config has not already made the remote valid.

Within a branches file git takes only a non-empty, whitespace-trimmed first line. The scan departs from this in two ways:
- **(a)** It marks names containing `/` (from `remotes/sub/x`, which `find` returns) as defined. git ignores such files, so it uses the name as a URL.
- **(b)** It marks a branches file as defining the name even when the first line is empty. The here-string makes `read` succeed once, which sets `_snap_rnames` before the empty URL is skipped. git returns without defining a URL and pushes to the name.

Experiment `e2.sh` / `push.sh`:
```
e3 scan-status=0 ...; lines naming pre-receive: 0      (remotes/sub/x "URL: https://x.invalid/r", remote.pushDefault sub/x, planted <ws>/sub/x)
remote: E3-HOOK-RAN   (git push sub/x master)
e4 scan-status=0 ...; lines naming pre-receive: 0      (empty branches/plant, branch.master.pushRemote plant, planted <ws>/plant)
remote: E4-HOOK-RAN   (git push plant master)
```
(Plain `git push` stopped at push.default=simple's "no upstream" error. With an upstream set or `push.default=current`, the same name is used.)

**Recommendation:** Set `_snap_rnames` from a legacy file only for a name with no `/` (and not `.`/`..`), and for branches files only when the trimmed first line is non-empty. Better still, see Finding 3: decide "defined" per repository rather than globally.

#### 3. A remote name defined in ANY repo the scan reads counts as defined for every repo, so the checkout's push to that name as a path is unwalked

**Severity:** Medium
**Location:** `devcontainer-config/cc-exit-scan.sh:505-512` (`_snap_config` sets `_snap_rnames` for every config read), `:734`, `:730` (legacy), `:840` (worklist test)
**Boundary:** B1, B3
**Move:** #5, #11
**Confidence:** High (confirmed by experiment). Low likelihood: needs a launch-time `pushRemote`/`remote`/`pushDefault` naming a remote the checkout does not define, plus another repo inside the checkout that does define it. This was already true on main; the branch rewrote the "defined" rule and claims it matches remote.c.
**Legibility-target:** the comment "A remote git counts as defined (remote.c, valid_remote) has a url or vcs" (maintainer); commit claim 4

Evidence (verbatim):
```
        name="${key#remote.}"; name="${name%.*}"
        case "$key" in remote.*.url|remote.*.vcs) [ -z "$name" ] || _snap_rnames["$name"]=1 ;; esac
```
```
      [ -z "$f" ] || [ -n "${_snap_rnames["$f"]:-}" ] || _snap_url "$f" "$g" || rc=1
```
`_snap_rnames` is a single table for the whole snapshot. It gets filled from the checkout's config, every embedded repo's config, every walked local remote's config, every nested git dir, and their legacy files. git only consults the config of the repo it runs in.

Experiment `e2.sh` sets up `branch.master.pushRemote = plant` in the checkout and `remote.plant.url = https://x.invalid/r` in the embedded repo `vendor/e`, then plants `<ws>/plant` after the snapshot:
```
e2 scan-status=0 (0=clean/no finding); lines naming pre-receive: 0
remote: E2-HOOK-RAN   (git push plant master)
```

**Recommendation:** Key the table by repository: store `_snap_rnames["<git dir or working tree>\n<name>"]` and keep each queued name's working tree (already in `_snap_nbases`), so a name is skipped only if the repo whose config names it defines it. Over-walking is cheap. Under-walking is the bypass.

#### 4. The pair cap counts comparisons, not bytes: one long URL makes each comparison cost ~13 ms, so the scan can run for many minutes while staying under both caps

**Severity:** Medium (availability only; fails safe if you stop it)
**Location:** `devcontainer-config/cc-exit-scan.sh:411-424` (caps, `_snap_pairs`), `:433-442` (`_snap_match`); `guides/cc-isolated-usage.md:346-351`
**Boundary:** B1, B3, B6
**Move:** #8
**Confidence:** High (timed)
**Legibility-target:** the guide sentence "…and so do more than 100,000 URL-and-rule comparisons or more than 2,000 distinct rewritten URLs to walk", which follows "fails the scan … rather than stalling it" (user); the guide's "A slow scan" bullet, which names only files and embedded repos

Evidence (verbatim):
```
  for ((k = 0; k < n; k++)); do
    u="${_snap_urls[ui]}"; p="${_snap_rpfx[ri]}"
    if [[ "$u" == "$p"* ]]; then
```
Each comparison copies the whole URL. Experiment `e9.sh` used one remote URL of 1 MiB plus R non-matching rules. One snapshot took 0.84 s at R=50 and 2.78 s at R=200, about 13 ms per comparison. At 100,000 comparisons, which is under the pair cap, that is roughly 21 minutes per snapshot. The file's own limits allow far longer values: a 64 MiB config, and `_snap_size_ok` caps per file, not per value.

The plant is a C finding, but it only appears once the scan finishes. If you stop the scan you get exit 4 ("treat as unscanned"), which is safe but no scan. The commit notes say so ("Long values still slow each comparison: the guide's 'A slow scan' route"), but that guide bullet does not mention rules or URLs.

**Recommendation:** Charge `_snap_pairs` by bytes, for example add `${#u}` per URL batch, or cap the total bytes across `_snap_urls` and `_snap_rpfx`. Alternatively, skip the copy and test `${#_snap_urls[ui]}`/prefix length first. At minimum, add long URLs and rules to the guide's "A slow scan" bullet and drop the "rather than stalling it" reading for these caps.

#### 5. (Pre-existing, in the walk the rewrites now feed) `file://<host>/path` and percent-encoded `file://` URLs resolve differently in git and in `_snap_remote`

**Severity:** Medium
**Location:** `devcontainer-config/cc-exit-scan.sh:365-377` (`_snap_remote`)
**Boundary:** B4
**Move:** #2, #11
**Confidence:** High (confirmed by experiment). Low likelihood: needs a launch-time URL, or a rule's base, of that shape. Not introduced by this branch, but every rewritten target now goes through this function, and a rule base such as `file://h/<ws>/` reaches it.
**Legibility-target:** the `_snap_remote` header comment's account of git's URL rules (maintainer)

Evidence (verbatim):
```
    file://localhost/*) p="${p#file://localhost}" ;;
    file://*) p="${p#file://}" ;;
```
git's `connect.c` `parse_connect_url` percent-decodes URLs that have a scheme, and for `file://` takes the path from the first `/` after the host, whatever the host is. The scan instead strips the prefix literally: it turns `file://evilhost/<ws>/t1.git` into the relative path `evilhost/<ws>/t1.git` and leaves `%74%32` encoded.

Experiment `e2.sh`:
```
e5a scan-status=0 ...; lines naming pre-receive: 0     (remote file://evilhost<ws>/t1.git, planted <ws>/t1.git)
  push o master: remote: E5a-HOOK-RAN
e5b scan-status=0 ...; lines naming pre-receive: 0     (remote file://<ws>/%74%32.git, planted <ws>/t2.git)
  push o master: remote: E5b-HOOK-RAN
```

**Recommendation:** For `file://` URLs, percent-decode, then drop everything up to the first `/` after `file://` (any host). Walk both the decoded form and the literal one; walking extra paths is cheap.

#### 6. (Pre-existing parsing, lines touched by this branch) Legacy URLs are not trimmed the way git trims them, and the UTF-8 `[:space:]` strip trims more than git does

**Severity:** Medium
**Location:** `devcontainer-config/cc-exit-scan.sh:728-735`
**Boundary:** B1, B4
**Move:** #2
**Confidence:** High (confirmed by experiment). Low likelihood: needs that legacy file at launch.
**Legibility-target:** the comment `remotes/<name> ("URL: <url>" lines), branches/<name> ("<url>#<branch>")` (maintainer)

Evidence (verbatim):
```
          _snap_url "${line%%#*}" "$(_snap_worktree_of "$real/config")" || return 1
...
        case "$line" in URL:*) _snap_rnames["$name"]=1; line="${line#URL:}"; _snap_url "${line#"${line%%[![:space:]]*}"}" ...
```
git trims differently from the scan:
- `read_remotes_file` applies `strbuf_rtrim` and `skip_spaces`, which skip only ASCII whitespace.
- `read_branches_file` applies `strbuf_trim`.
- `strbuf_getline` drops a trailing CR.

The scan keeps trailing spaces and CR, keeps leading and trailing space in branches files, and under a UTF-8 locale strips leading U+3000 (e8: `$'URL:\xe3\x80\x80./t'` → `./t`, while git keeps the U+3000). Experiment `e2.sh`:
```
e6 scan-status=0 ...; lines naming pre-receive: 0      (remotes/up "URL: ./t3  \r")
  push up master: remote: E6-HOOK-RAN
e7 scan-status=0 ...; lines naming pre-receive: 0      (branches/bb "  ./t4  ")
  push bb master: remote: E7-HOOK-RAN
```

**Recommendation:** Parse legacy files under `LC_ALL=C`. Strip a trailing `\r`. Strip trailing ` \t\r\n` (remotes) and both ends (branches) with explicit ASCII classes, then queue the trimmed URL; queue the raw form too if you want to over-approximate.

#### 7. The header still says only three kinds of entry in your own config are followed

**Severity:** Informational
**Location:** `devcontainer-config/cc-exit-scan.sh:62-72`
**Boundary:** B2
**Move:** #1
**Confidence:** High (read-static)
**Legibility-target:** the header's WHAT IS SNAPSHOTTED paragraph (maintainer)

Evidence (verbatim): `# embedded repo. Only those three kinds of entry are followed in your own config;`. Since e4b29291, `_snap_host_config` also follows your `url.*.insteadOf`/`pushInsteadOf` rules and walks your `remote.*.url`/`pushurl` values directly through `_snap_url` → `_snap_remote`, not only "rewritten", as lines 62-63 put it.

**Recommendation:** Say "core.hooksPath, core.attributesFile, includes, insteadOf rules and remote URLs".

## Untested bypass candidates

- **Remote names in your own config.** `remote.pushDefault` and `branch.*.remote`/`pushRemote` in your global config are not queued (`_snap_host_config:613-616` handles only rules and urls). If one names a remote no repo defines, git pushes to the name as a path inside the checkout. Not tested: it needs an unusual config of yours, and the header's "only … followed" sentence arguably documents it.
- **`config.worktree` remotes.** A remote defined in a linked worktree's `config.worktree` marks the name defined for every repo (a variant of Finding 3). Not tested separately; same mechanism and fix as Finding 3.
- **`~` in a rewritten target.** Documented in the guide's "`~` forms" bullet ("or one an `insteadOf` rule rewrites to"). Not re-tested.
- **Target cap reached by a benign setup.** Your rule (for example `git@github.com:` ↔ `https://github.com/`) times many embedded repos with GitHub remotes. Each one is a distinct `t:` key because the working tree is part of the key, so roughly 2,000 such repos refuse the launch. This fails closed (a usability issue, not a bypass). Not measured.

## Endorsement Claims

- **Claim:** `local LC_ALL=C` in `_snap_match` makes the prefix test and the cut byte-wise, and the caller's locale is back in force after the call, both when `LC_ALL` was unset (LANG=C.utf8) and when it was set.
  **Location:** `devcontainer-config/cc-exit-scan.sh:433-442`
  **Evidence:** executed (e8: hit `$'B\251'`; `${#x}` is 1 before and after; `LC_ALL` unset/`C.utf8` restored)
  **Verified:** bash 5.2.15 in the container, both caller-locale cases.
  **Not verified:** dedupe keys built outside `_snap_match` (Finding 1); other host bash versions.
  **route: code-fact-check**
- **Claim:** `LC_ALL=C IFS= read -r -d ''` reads a NUL after an incomplete multibyte character as a delimiter, and the shell's locale is unchanged after the loop.
  **Location:** every `read` in `cc-exit-scan.sh` (e.g. `:335`, `:482`, `:607`, `:719`, `:728`, `:821`)
  **Evidence:** executed (e8: 2 entries with the prefix, 1 without; `LC_ALL` still `C.utf8`)
  **Verified:** NUL-delimited reads; bats test "under a UTF-8 locale a name ending mid-character…" passes.
  **Not verified:** the `[:space:]` strip after the read (Finding 6).
- **Claim:** The worklist compares each queued (URL, rule) pair once. Hits are rebuilt before every batch. A failing `_snap_url`/`_snap_rewrite`/cap sets `rc=1`, which ends the loop before `printf`, so the snapshot returns 1 (launch exit 1 at `cc-isolated.sh:859-867`; `git_exit_scan` returns 2).
  **Location:** `devcontainer-config/cc-exit-scan.sh:834-861`, `:446-451`
  **Evidence:** read-static, plus bats test 13 executed (status 2 for both caps)
  **Verified:** the full loop body; `_snap_hit_t`/`_snap_hit_b` reset at `:844`/`:851`; nothing inside `_snap_walk_hits` resets or appends to them.
  **Not verified:** pairs whose rule was dropped by a key collision (Finding 1), which never enter the worklist.
  **route: code-fact-check**
- **Claim:** The new error strings interpolate only numbers. New container-chosen strings (rewritten targets) reach the terminal only as `%q`-quoted F/W record paths.
  **Location:** `devcontainer-config/cc-exit-scan.sh:422-423`, `:461-462`, `_snap_file:276`, `_snap_wrel:312`
  **Evidence:** read-static (plus `$'…\251…'` records seen in e1/e8 output)
  **Verified:** both `_snap_fail` calls; the record builders.
  **Not verified:** how terminal width handles very long `%q` paths.

## Primitive sweep

Primitive: path construction → filesystem walk (`_snap_remote` on a URL, name or rewritten target)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `cc-exit-scan.sh:399` `_snap_url` → `_snap_remote` | S1, S2, S3 | `u:` key | cleared for keys (working tree starts with `/`); Finding 5 for `file://` forms |
| `cc-exit-scan.sh:465` `_snap_rewrite` → `_snap_remote` | S1, S2, S3 | `t:` key, target cap | cleared for keys; Finding 4 (cost); Finding 5 (`file://` bases) |
| `cc-exit-scan.sh:405` rule queue (feeds `:438`) | S1, S3 | `r:` key | Finding 1 |
| `cc-exit-scan.sh:519` `_snap_remote "$t" "$base"` (rule base alone) | S1 | none needed | cleared (pre-existing, unchanged) |
| `cc-exit-scan.sh:615` your `remote.*.url` → `_snap_url` | S3 | `u:` key | cleared (pass-1 F1 fixed) |
| `cc-exit-scan.sh:731,734` legacy files → `_snap_url` | S2 | none | Findings 2, 6 |
| `cc-exit-scan.sh:840` names → `_snap_url` | S1 | `_snap_rnames` | Findings 2, 3 |
| your `remote.pushDefault` / `branch.*.pushRemote` | S3 | — | not reached: Untested bypass candidates |

Primitive: process exec. The diff adds no `git`, `eval` or constructed command. `realpath`/`stat`/`readlink` take paths after `--`. Cleared.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | UTF-8: rule keys measure characters, so two launch-time rules collide and one is dropped (exp.) | Medium | B3 | `cc-exit-scan.sh:405` | High mechanism / Low likelihood |
| 2 | Legacy file marks a name defined where git never reads it: name with `/`, empty branches file (exp.) | Medium | B1, B3 | `cc-exit-scan.sh:723-734,840` | High / Low likelihood |
| 3 | Remote names count as defined across all repos read, not per repo (exp.) | Medium | B1, B3 | `cc-exit-scan.sh:509,840` | High / Low likelihood |
| 4 | Pair cap counts comparisons, not bytes: ~13 ms per comparison with a 1 MiB URL, ~21 min under the cap (timed) | Medium | B1, B3, B6 | `cc-exit-scan.sh:411-442`, guide `:346-351` | High |
| 5 | (Pre-existing) `file://host/…` and `%XX` resolve differently in git and in the scan (exp.) | Medium | B4 | `cc-exit-scan.sh:367-372` | High / Low likelihood |
| 6 | (Pre-existing) Legacy URL trimming differs from git (CR, spaces, UTF-8 `[:space:]`) (exp.) | Medium | B1, B4 | `cc-exit-scan.sh:728-735` | High / Low likelihood |
| 7 | Header: "only three kinds of entry followed in your own config" is stale | Informational | B2 | `cc-exit-scan.sh:62-72` | High |

## Overall Assessment

No HALT-level issue, and no new exec or terminal-injection surface. The iteration-1 fixes mostly hold:
- your own remotes are walked;
- matching is byte-wise and the locale is restored;
- reads are byte-safe;
- forks are capped;
- every failure path fails closed with the documented statuses.

What remains is the same kind of problem as before: places where the scan's model of git differs from git, each confirmed with a real `git push` running a planted hook while the scan reported nothing:
- Finding 1: the new key scheme is length-prefixed in characters, not bytes. A one-line `local LC_ALL=C` fixes it.
- Findings 2 and 3: the "defined remote" rule that commit claim 4 says matches remote.c does not. It ignores `valid_remote_nick` and empty branches files (Finding 2), and it treats remote names as global across repos (Finding 3).
- Findings 5 and 6: `file://` and legacy-file parsing (pre-existing).

All of these need launch-time state, so their likelihood is low, but under the threat model that state includes what an earlier session planted and you left in place after its warning. The most important thing to address is Findings 1-3, because they sit in code this branch wrote or rewrote and they contradict its own claims. Finding 4 is availability only and fails safe; a byte-charged cap or a guide edit fixes it. Endorsement claims are scoped above; this is no categorical all-clear.

## Goal-Alignment Note

The goal is that a session cannot repoint a push through an `insteadOf`/`pushInsteadOf` rewrite the scan ignores. Findings 1-6 by scope:
- **Finding 1** is exactly that class, surviving in the dedupe the branch added to close it. It is in scope for Q-096 and is a one-line fix.
- **Findings 2 and 3** are in the name-as-URL path this branch rewrote (and which feeds the rewrite worklist), and they make commit claim 4 inaccurate. Fix them here, or at least narrow the claim and the guide's "a remote with no `url`" sentence and hand them to Q-097, which edits the same file.
- **Findings 5 and 6** predate the branch. Rewrites now route through `_snap_remote`, but neither is a rewrite-specific gap. They are good Q-097 material.
- **Finding 4** needs the guide reworded now; a byte-based cap can follow.
- **Finding 7** is a one-line header fix.
