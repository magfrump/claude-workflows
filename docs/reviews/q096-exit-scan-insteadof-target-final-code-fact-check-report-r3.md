Commit: 03bc47c9
# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-q096 (branch fix/q096-exit-scan-insteadof-target)
**Scope:** full branch, `git diff main...HEAD -- . ':!docs/reviews'` at 03bc47c9 (cc-exit-scan.sh, guides/cc-isolated-usage.md, test/cc-isolated-functions.bats, the Q-096 brief, plan and research docs) plus the five commit messages `git log main..HEAD`; replicate r3 of the final confirming pass
**Checked:** 2026-10-15
**Total claims checked:** 41
**Summary:** 29 verified, 5 mostly accurate, 3 stale, 3 incorrect, 1 unverifiable

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) read first: it holds 8 entries, and no claim below matches one. None of the Incorrect verdicts here is a fabricated symbol, so the log needs no new entry.

**Legibility-target** (a field on every claim): the reader the text is written for. `maintainer` = a code comment; `user` = the guide; `reviewer` = plan, research or brief; `history` = a commit message (cannot be changed, so a wrong one can only be corrected in a later commit or a doc).

### Execution provenance (referenced from each executed claim)

All runs used probe dir `P=/home/node/.claude/jobs/00bcf178/tmp/q096/probe-code-fact-check-r3/`, `GIT_CONFIG_GLOBAL` pointed at a file inside it and `GIT_CONFIG_NOSYSTEM=1`. Every process ran under `timeout` of 600 s or less. All had exited before this report: `ps` showed nothing under the probe dir, and the background bats PID 3526137 was gone. The worktree's tracked files were never edited; `git status` was clean apart from this report.

| ID | Command | cwd | Exit | Time (UTC) | Output |
|---|---|---|---|---|---|
| E1 | `LC_ALL=C timeout 600 bats test/cc-isolated-functions.bats -f 'Q-096'` | /workspace/.claude/wt-q096 | 0 | 2026-10-15T08:36:53Z | `$P/bats-q096.log` (11/11 ok) |
| E2 | `LC_ALL=C timeout 600 bats test/cc-isolated-functions.bats` | /workspace/.claude/wt-q096 | 0 | started ~08:37Z | `$P/bats-full.log` (193 ok, 0 not ok) |
| E3 | `timeout 300 $P/git-semantics.sh $P/git` (real `git push` into bare repos with failing pre-receive hooks; git 2.39.5) | `$P/git` | 0 | 08:38:37Z | `$P/git-semantics.log` |
| E4 | on a copy at `$P/mut`: `sed -i '729s/while LC_ALL=C IFS= read/while IFS= read/' devcontainer-config/cc-exit-scan.sh; LC_ALL=C timeout 300 bats test/cc-isolated-functions.bats -f 'name ending mid-character'` | `$P/mut` | 1 (test fails) | 08:39:13Z | `$P/mut-legacy-read.log` |
| E5 | `timeout 300 bash $P/scan-probes.sh $P /workspace/.claude/wt-q096/devcontainer-config/cc-exit-scan.sh` (probes P1-P7) | `$P/scan` | 0 | 08:39:52Z | `$P/scan-probes.log` |
| E6 | `timeout 500 bash $P/timing-probe.sh $P <same script> 200` | `$P/timing` | 0 | 08:41:53Z | `$P/timing-probe.log` |
| E7 | bash `read` under C.utf8 vs C, with and without the `LC_ALL=C` prefix; `git config --list` key case | `$P` | 0 | 08:42:12Z | `$P/read-probe.log` |
| E8 | `git diff --numstat main...HEAD -- . ':!docs'`; `_snap_rnames` lines in the diff | /workspace/.claude/wt-q096 | 0 | 08:43:06Z | `$P/numstat.log` |

---

## Claim 1a: "git takes only the longest, the scan walks them all"

**Location:** `devcontainer-config/cc-exit-scan.sh:63-64`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers git 2.39.5's choice of the longest matching value and the scan walking both overlapping targets. Does not establish behaviour on other git versions.

E3 "longest prefix": with values `https://o.invalid/` (base `short-`) and `https://o.invalid/re` (base `long-`), git ran only `long-po`'s hook. The scan's matching loop has no "longest" selection. Every pair that matches is appended:

```bash
# devcontainer-config/cc-exit-scan.sh:448-455
    if [[ "$u" == "$p"* ]]; then
      if [ $((_snap_rwt + ${#_snap_hit_t[@]})) -ge "$GIT_EXIT_SCAN_MAX_REWRITE_TARGETS" ]; then
...
      _snap_hit_t+=("${_snap_rbases[ri]}${u:${#p}}"); _snap_hit_b+=("${_snap_ubases[ui]}")
    fi
```
(excerpt ends :455; enclosing `_snap_match` continues to :458 — read)

E1 test 3 ("overlapping prefixes") passed: the scan names both `short-repo` and `long-po`.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:444-458`, `$P/git-semantics.log`, `$P/bats-q096.log`

---

## Claim 1b: "Each of those URLs, and every remote.*.url/pushurl in your own config, is also rewritten by every url.<base>.insteadOf / pushInsteadOf rule whose value prefixes it"

**Location:** `devcontainer-config/cc-exit-scan.sh:58-65`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** maintainer
**Scope:** Covers which values go into the URL queue. Does not establish a route: git does not rewrite an insteadOf base either, so the imprecision hides no gap.

"Those URLs" points back to a list (`:58-60`) that includes "url.<base>.insteadOf bases". Bases are never queued as URLs. `_snap_config` walks them directly:

```bash
# devcontainer-config/cc-exit-scan.sh:518-519
        _snap_rule "$t" "$val" || return 1
        _snap_remote "$t" "$base" || return 1 ;;
```
(excerpt ends :519; enclosing `_snap_config` continues to :522 — read)

`_snap_url` is called only for `remote.*.url|pushurl` (`:511`), legacy files (`:725`, `:729`), unresolved names (`:840`) and your own remotes (`:616`). Precise version: "Each of those remote URLs (not the insteadOf bases), and every …".

**Evidence:** `devcontainer-config/cc-exit-scan.sh:58-65`, `devcontainer-config/cc-exit-scan.sh:505-519`, `devcontainer-config/cc-exit-scan.sh:612-617`, `devcontainer-config/cc-exit-scan.sh:724-730`, `devcontainer-config/cc-exit-scan.sh:840`

---

## Claim 2: "Only those three kinds of entry, your insteadOf rules and your remote URLs are followed in your own config; its entries are not recorded (the container cannot write it)."

**Location:** `devcontainer-config/cc-exit-scan.sh:70-72`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers which keys `_snap_host_config` acts on and that it writes no C record. Does not establish recording for an include target inside the checkout: that is read by `_snap_config` and recorded, as the function header says.

```bash
# devcontainer-config/cc-exit-scan.sh:612-617
    # Your rewrite rules apply to repo URLs, and any rule to your remotes' URLs.
    case "$key" in
      url.*.insteadof|url.*.pushinsteadof) t="${key#url.}"; _snap_rule "${t%.*}" "$val" || return 1 ;;
      remote.*.url|remote.*.pushurl) _snap_url "$val" "$wt" || return 1 ;;
    esac
```
(excerpt ends :617; enclosing `_snap_host_config` continues to :640 — read: the rest handles only core.hookspath, core.attributesfile and include/includeif, and never appends to `_snap`)

E5 P5 put a global config holding an empty-value rule, a remote and `user.name`. The snapshot had 0 records naming global.cfg, and the rewritten remote target `WS/h-mine` was walked (`F remote WS/h-mine dir 755`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:600-640`, `$P/scan-probes.log`

---

## Claim 3: "A relative core.hooksPath, core.attributesFile or local remote (… nor a remote any insteadOf rule rewrites to a relative path) … leave W records, and any W record refuses the note."

**Location:** `devcontainer-config/cc-exit-scan.sh:87-92`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers a relative rewritten target producing a W record through `_snap_remote`, and the note being refused. Does not establish anything for a target of exactly `.`, which by design gets no W record (`:377`).

Rewritten targets go through `_snap_remote`, which calls `[ "$p" = . ] || _snap_wrel remote "$p" "$p"` (`devcontainer-config/cc-exit-scan.sh:377`). `_snap_wrel` appends a W record for anything not empty, absolute or `~/` (`:309-313`). E1 test 6 passed: your rule `url.vendor/.insteadOf x:` plus a repo remote `x:r.git`, then a std worktree, gives `warns_listing_wt`.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:309-313`, `devcontainer-config/cc-exit-scan.sh:365-389`, `test/cc-isolated-functions.bats:674-690`, `$P/bats-q096.log`

---

## Claim 4: "an insteadOf pass too long or too large (_snap_key, _snap_pairs_ok, _snap_match) makes the snapshot fail: at launch the launcher refuses to start, at exit it returns 4."

**Location:** `devcontainer-config/cc-exit-scan.sh:95-99`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers all three caps making `git_exec_snapshot` return 1 (executed), `git_exit_scan` returning 2 (executed), and the launcher mapping (static for these caps; the generic snapshot-failure path at launch is executed by an existing test). Does not establish a launcher-level run that trips an insteadOf cap: the caps are script constants, not environment variables.

E5 P3 and P4: each cap gives `rc=1` with its reason. E1 test 11: `git_exit_scan` returns status 2 for each of the three caps. Launcher, `devcontainer-config/cc-isolated.sh:859-867`: `if ! git_before="$(git_exec_snapshot "$ws" "$lws" 2>"$snap_err")"; then … exit 1`. At exit, `devcontainer-config/cc-isolated.sh:932-937`: `git_exit_scan … || scan=$?` then `*) exit 4 ;;`. E2 includes "a launch refuses to start when .git cannot be snapshotted" (status 1), which passed.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:401-458`, `devcontainer-config/cc-exit-scan.sh:1104-1121`, `devcontainer-config/cc-isolated.sh:859-867`, `devcontainer-config/cc-isolated.sh:925-938`, `$P/scan-probes.log`, `$P/bats-q096.log`, `$P/bats-full.log`

---

## Claim 5: "EVERY `read` RUNS UNDER LC_ALL=C: in a UTF-8 locale it swallows a NUL or newline after an incomplete multibyte character, hiding the next entry from the scan."

**Location:** `devcontainer-config/cc-exit-scan.sh:123-124`
**Type:** Invariant / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers every `read` builtin in cc-exit-scan.sh (13 call sites), the stated bash mechanism, and the legacy here-string read in particular. Does not establish that nothing else in the file splits container bytes in a locale-dependent way; see Claim 31 for the legacy `[:space:]` trim, which is a listed known route.

`grep -n '\bread\b'` lists 13 `read` calls (`:232, :335, :487, :610` (two), `:686, :721, :729, :743, :751, :821, :997`), and every one has the `LC_ALL=C IFS= read` prefix. E7 under C.utf8: `printf 'a\xc3\0b\0c\0'` read with `-d ''` gave `$'a\303'`, then `c`, so `b` was lost. The newline form gave `$'a\303\nb'` (merged). Under C, or with the prefix, all entries were kept. E4: removing the prefix from the legacy here-string read (`:729`) fails the Q-096 test at `test/cc-isolated-functions.bats:2242`. Other splitting of container bytes: `_snap_remote`'s `${p%%:*}` gave the same result under C and C.utf8 for strings holding `\xc3` (E5 P6). `_snap_match` and `_snap_key` set `local LC_ALL=C`.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:232`, `devcontainer-config/cc-exit-scan.sh:729`, `devcontainer-config/cc-exit-scan.sh:997`, `$P/read-probe.log`, `$P/mut-legacy-read.log`, `$P/scan-probes.log`

---

## Claim 6: "…share its locals …: … and the insteadOf pass's queues (_snap_urls/_snap_ubases, _snap_rbases/_snap_rpfx, _snap_hit_t/_snap_hit_b, _snap_rwseen, _snap_k, the _snap_rwn/_snap_rwt counters)"

**Location:** `devcontainer-config/cc-exit-scan.sh:158-163`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** maintainer
**Scope:** Covers each named variable being a local of `git_exec_snapshot`. Does not establish that no helper declares one of them locally in a way that shadows it (grep found none).

```bash
# devcontainer-config/cc-exit-scan.sh:782-786
  local _snap_bytes=0 _snap_rwn=0 _snap_rwt=0 _snap_k u r
  local -A _snap_seen=() _snap_rnames=() _snap_rwseen=()
  local -a _snap_names=() _snap_nbases=() _snap_urls=() _snap_ubases=() _snap_rbases=() _snap_rpfx=()
  local -a _snap_hit_t=() _snap_hit_b=()
```
(excerpt ends :786; enclosing `git_exec_snapshot` continues to :858 — read)

**Evidence:** `devcontainer-config/cc-exit-scan.sh:158-163`, `devcontainer-config/cc-exit-scan.sh:779-858`

---

## Claim 7: "Caps on the insteadOf pass …: bytes in one URL, rule base or value (_snap_key); pairs compared (_snap_pairs_ok); rewritten URLs to walk, each a few forks (_snap_match)."

**Location:** `devcontainer-config/cc-exit-scan.sh:390-393`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers what each cap measures. Does not establish whether a working-tree path over 4,096 bytes can actually occur on a host. It fails closed if it does.

The byte cap also applies to the URL's working tree. `_snap_url` calls `_snap_key "$1" "$2" check` with `$2` = the working tree (`:413`), and `_snap_key` checks both arguments (`:405`). E5 P3's reason names it: "a remote URL, its working tree or an insteadOf rule over 4096 bytes (4097 and 74)". The target cap counts matches (Claim 21), which "rewritten URLs to walk" leaves open. Precise version: "bytes in one URL, its working tree, a rule base or value".

**Evidence:** `devcontainer-config/cc-exit-scan.sh:401-414`, `$P/scan-probes.log`

---

## Claim 8: "_snap_k, a key for the pair prefixed by <a>'s length in bytes (LC_ALL=C; characters collide), so no byte can join two pairs. With <check>, fail when <a> or <b> is over GIT_EXIT_SCAN_MAX_REWRITE_BYTES."

**Location:** `devcontainer-config/cc-exit-scan.sh:398-400`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the key being collision-free (the decimal length up to the first `:` fixes where `<a>` ends), byte counting under a UTF-8 locale, and the strict `-gt` boundary (4,096 passes, 4,097 fails). Does not establish anything for keys built without `check` (rewritten targets in `_snap_walk_hits`), which are uncapped by design.

```bash
# devcontainer-config/cc-exit-scan.sh:401-408
_snap_key() {
  local LC_ALL=C
  _snap_k="${#1}:$1$2"
  [ -n "${3:-}" ] || return 0
  [ "${#1}" -gt "$GIT_EXIT_SCAN_MAX_REWRITE_BYTES" ] || [ "${#2}" -gt "$GIT_EXIT_SCAN_MAX_REWRITE_BYTES" ] || return 0
  _snap_fail '…over %s bytes (%s and %s)…' \
    "$GIT_EXIT_SCAN_MAX_REWRITE_BYTES" "${#1}" "${#2}"
}
```
E5 P3 under `LC_ALL=C.utf8`: a URL of 2,048 `é` (4,096 bytes) gave rc=0; with 4,097 bytes, rc=1. A 4,097-byte rule value gave rc=1. E1 tests 9 and 10 (tab keys; UTF-8 keys whose characters line up) passed.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:401-408`, `$P/scan-probes.log`, `$P/bats-q096.log`

---

## Claim 9: "_snap_url <url> <working tree>: a remote URL git may push to. Walked now (_snap_remote) and queued for the insteadOf rules (_snap_match), once each."

**Location:** `devcontainer-config/cc-exit-scan.sh:410-411`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** maintainer
**Scope:** Covers dedupe on (URL, working tree), queueing and walking. Does not establish that every URL source calls it (see Claim 1b for the list).

```bash
# devcontainer-config/cc-exit-scan.sh:412-418
_snap_url() {
  _snap_key "$1" "$2" check || return 1
  [ -z "${_snap_rwseen["u:$_snap_k"]:-}" ] || return 0
  _snap_rwseen["u:$_snap_k"]=1
  _snap_urls+=("$1"); _snap_ubases+=("$2")
  _snap_remote "$1" "$2"
}
```

**Evidence:** `devcontainer-config/cc-exit-scan.sh:412-418`

---

## Claim 10: "queue url.<base>.insteadOf (or pushInsteadOf) = <value>: git rewrites a URL starting with <value> to <base> + the rest."

**Location:** `devcontainer-config/cc-exit-scan.sh:420-421`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers git's rewrite form and the queueing with dedupe. Does not establish which rule git picks among several (Claim 1a).

E3: every rewrite that ran a hook ran `<base><rest>` (for example `url.$D/e-.insteadOf ""` with URL `x` ran `e-x`). `_snap_rule` (`:422-427`) checks the byte cap, dedupes on `r:` + key, and appends to `_snap_rbases`/`_snap_rpfx`.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:422-427`, `$P/git-semantics.log`

---

## Claim 11: "git's alias_url compares bytes (case-sensitive; an empty value matches every URL), so the match and the cut run under LC_ALL=C: in a UTF-8 locale ${#p} counts characters, and a value ending mid-character would cut the URL in the wrong place."

**Location:** `devcontainer-config/cc-exit-scan.sh:437-443`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers git 2.39.5's byte-wise, case-sensitive, empty-matches-all behaviour and the scan matching it under C.utf8. Does not establish a value-less `insteadOf` key, which git rejects ("missing value", fatal). The scan reads it as empty and over-walks, which is the fail-safe direction.

E3: `HTTPS://c.invalid/repo` was not rewritten by a value `https://c.invalid/` (no hook ran). The empty value rewrote `x`. The value `\xc3` rewrote `\xc3\xa9vil` to `b-\xa9vil` under C.utf8. `_snap_match` opens with `local LC_ALL=C ui="$1" …` (`:445`). E1 test 7 (byte-wise under C.utf8) passed. E5 P7 walked a target cut mid-character and holding `:` after `/`.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:444-458`, `$P/git-semantics.log`, `$P/scan-probes.log`, `$P/bats-q096.log`

---

## Claim 12: "_snap_walk_hits: walk each rewritten URL _snap_match found, like any remote, once; never queued as a URL (git rewrites once), and walking adds no hits."

**Location:** `devcontainer-config/cc-exit-scan.sh:460-461`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** maintainer
**Scope:** Covers dedupe on (target, working tree), no `_snap_url` call, and `_snap_hit_t` being appended only by `_snap_match`. Does not establish that `_snap_rwt` counts distinct targets: it counts every hit, duplicates included (Claim 21).

```bash
# devcontainer-config/cc-exit-scan.sh:462-471
_snap_walk_hits() {
  local h
  for ((h = 0; h < ${#_snap_hit_t[@]}; h++)); do
    _snap_rwt=$((_snap_rwt + 1))
    _snap_key "${_snap_hit_t[h]}" "${_snap_hit_b[h]}"
    [ -z "${_snap_rwseen["t:$_snap_k"]:-}" ] || continue
    _snap_rwseen["t:$_snap_k"]=1
    _snap_remote "${_snap_hit_t[h]}" "${_snap_hit_b[h]}" || return 1
  done
}
```
Nested walking can reach `_snap_config`, which overwrites `_snap_k`. That is harmless because `_snap_k` is used before `_snap_remote` runs. "No git chaining" was confirmed by E3: `a:x` rewritten to `mid-x` was not rewritten again by a rule on `mid-`.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:462-471`, `$P/git-semantics.log`

---

## Claim 13: "url.<base>.insteadOf rewrites matching URLs to <base>: the base alone here, every URL it rewrites in git_exec_snapshot (_snap_match)."

**Location:** `devcontainer-config/cc-exit-scan.sh:513-514`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** maintainer
**Scope:** Covers the split between walking the base in `_snap_config` and rewriting URLs in the closing loop. Does not establish the W record for a base of `""`/`.`, which happens only in repo config and not for your own rules (no route: a rewritten target from your own rule gets its own W record, Claim 3).

`_snap_rule "$t" "$val" || return 1` then `_snap_remote "$t" "$base" || return 1` (`devcontainer-config/cc-exit-scan.sh:518-519`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:512-519`

---

## Claim 14: "_snap_host_config …: your own global and system config … A relative core.hooksPath or core.attributesFile there resolves inside the checkout; walk those. Entries are not recorded …"

**Location:** `devcontainer-config/cc-exit-scan.sh:593-599`
**Type:** Staleness / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** maintainer
**Scope:** Covers the function header's list of what it follows. Does not establish anything misleading about recording, which is still correct.

The header was not updated on this branch. It names hooksPath, attributesFile and includes, but the function now also queues your rules and your remote URLs (`:612-617`, quoted in Claim 2). It does not claim to be exhaustive, so this is an omission, not a contradiction. The file header (`:70-72`) and the inline comment (`:612`) do state the new entries. Precise version: add "your insteadOf/pushInsteadOf rules and remote URLs are queued for the rewrite pass".

**Evidence:** `devcontainer-config/cc-exit-scan.sh:593-640`

---

## Claim 15: "Your rewrite rules apply to repo URLs, and any rule to your remotes' URLs."

**Location:** `devcontainer-config/cc-exit-scan.sh:612`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers your rule rewriting a repo URL, a repo rule rewriting your remote, and an empty-value rule from your config. Does not establish includeIf-gated rules on conditions other than gitdir (onbranch/hasconfig are taken as matching, per the header).

E1 test 5 passed: your `url.$WS/g-.insteadOf gh:` with repo remote `gh:repo`, and a repo rule rewriting your `remote.mine.url`. E5 P5: your empty-value rule rewrote your own remote `mine` to `WS/h-mine`, which was walked. Rule collection runs before `[ -n "$val" ] || continue` (`:618`), so empty values are kept.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:610-618`, `$P/bats-q096.log`, `$P/scan-probes.log`

---

## Claim 16: "Walking one can reach configs that name more, hence the growing indexes: a new URL meets the rules already seen, a new rule meets the URLs already seen, so each pair meets once."

**Location:** `devcontainer-config/cc-exit-scan.sh:830-833`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers completeness and uniqueness of (URL, rule) comparisons, including URLs and rules found while walking a rewritten target. Does not establish anything about cost (row 134, deferred).

URL `u` is compared with rules `0..r-1` and then `u++`. Rule `r` is compared with URLs `0..u-1` and then `r++`. Names are drained first on every iteration:

```bash
# devcontainer-config/cc-exit-scan.sh:841-851
    elif [ "$u" -lt "${#_snap_urls[@]}" ]; then
      # URL u against rules 0..r-1.
      _snap_pairs_ok "$r" || { rc=1; break; }
      _snap_hit_t=() _snap_hit_b=()
      _snap_match "$u" 0 "$r" 0 && _snap_walk_hits || rc=1
      u=$((u + 1))
    elif [ "$r" -lt "${#_snap_rbases[@]}" ]; then
      # Rule r against URLs 0..u-1.
      _snap_pairs_ok "$u" || { rc=1; break; }
      _snap_hit_t=() _snap_hit_b=()
      _snap_match 0 "$r" "$u" 1 && _snap_walk_hits || rc=1
```
(excerpt ends :851; enclosing loop continues to :856 and `git_exec_snapshot` to :858 — read)

E5 P1: a rule (`u-`) and a URL (`https://b.invalid/z`) that exist only in the rewritten target `t-r`'s config were both applied. `u-r` (new rule × old URL) and `v-z` (new URL × old rule) were walked.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:830-858`, `$P/scan-probes.log`

---

## Claim 17: "all failure paths fail closed" (brief claim 2; header "FAIL CLOSED")

**Location:** `devcontainer-config/cc-exit-scan.sh:833-858`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers every non-zero return in the insteadOf pass reaching `return 1` from `git_exec_snapshot`. Does not establish the fail-closed behaviour of walks unrelated to Q-096.

Paths traced:
- `_snap_url` failing in the names branch sets `rc=1` (`:840`).
- `_snap_pairs_ok` failing breaks with `rc=1`.
- `_snap_match` returns 1 on the target cap (`:452`). Otherwise its status is that of the final step assignment, so 0, and 0 for an empty batch.
- `_snap_walk_hits` returns 1 if `_snap_remote` fails.
- Nested `_snap_url`/`_snap_rule` failures in `_snap_config` and `_snap_host_config` propagate through `|| return 1`.
- After the loop: `[ "$rc" -eq 0 ] || return 1` (`:857`).

Executed: E5 P3 and P4 (rc=1 for each cap), E1 test 11 (status 2).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:430-458`, `devcontainer-config/cc-exit-scan.sh:833-858`, `$P/scan-probes.log`, `$P/bats-q096.log`

---

## Claim 18: "Status: done"

**Location:** `docs/working/briefs/2026-10-02-exit-scan-insteadof-target.md:3`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** reviewer
**Scope:** Covers the status line. Does not establish that every acceptance item in the brief is met beyond the claims in this report.

`Status: done` (`docs/working/briefs/2026-10-02-exit-scan-insteadof-target.md:3`).

**Evidence:** `docs/working/briefs/2026-10-02-exit-scan-insteadof-target.md:3`

---

## Claim 19: "B7 … `_snap_host_config` collects `url.*.insteadof`/`pushinsteadof`, empty values included"

**Location:** `docs/working/plan-q096-exit-scan-insteadof-target.md:20`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** reviewer
**Scope:** Covers collection of your rules with empty values. Does not establish includeIf-gated host rules under non-gitdir conditions.

See Claims 2 and 15 (E5 P5: the empty-value rule rewrote and walked).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:612-618`, `$P/scan-probes.log`

---

## Claim 20: "B10 Rule or URL found only inside a rewritten target's own config — covered — growing worklist"

**Location:** `docs/working/plan-q096-exit-scan-insteadof-target.md:23`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** reviewer
**Scope:** Same as Claim 16.

E5 P1: walked t-r, u-r and v-z.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:830-858`, `$P/scan-probes.log`

---

## Claim 21: "B14 … `GIT_EXIT_SCAN_MAX_REWRITE_TARGETS` (2,000 distinct rewritten URLs)"

**Location:** `docs/working/plan-q096-exit-scan-insteadof-target.md:27`
**Type:** Configuration
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** reviewer
**Scope:** Covers what the target cap counts. The rest of row B14 is verified: 100,000 comparisons, charged before each batch, exit 4 at exit and exit 1 at launch.

The cap counts URL-and-rule matches, duplicates included, not distinct rewritten URLs. `_snap_match` tests `_snap_rwt + ${#_snap_hit_t[@]}` (`:449`), and `_snap_walk_hits` adds 1 to `_snap_rwt` for every hit before its dedupe `continue` (`:465-467`). E5 P2: URL `ab` with rules (`WS/q`, `a`) and (`WS/qb`, `ab`). Both give the one target `WS/qb`, yet with the cap at 1 the snapshot fails: "more than 1 URLs rewritten by insteadOf rules to walk". Commit 03bc47c9 fixed this wording in the guide ("one per URL-and-rule match") but not in the plan row. Precise version: "2,000 URL-and-rule matches to walk". A reader sizing the cap from "distinct" would overestimate its headroom. The direction is fail-closed, so this hides no route.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:444-471`, `docs/working/plan-q096-exit-scan-insteadof-target.md:27`, `$P/scan-probes.log`

---

## Claim 22: "No uncovered family needs a design change" (with brief claim 7: no remaining way, in the insteadOf pass, to push to a session-controlled repository without a finding)

**Location:** `docs/working/plan-q096-exit-scan-insteadof-target.md:44`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** reviewer
**Scope:** Covers the families probed or traced in this pass. Does not establish completeness against git versions other than 2.39.5, or the split-out remote-name family (B29, a listed known route).

Families probed or traced:
- git's semantics: longest-match, empty, case, bytes, no chaining, pushInsteadOf vs pushurl (E3).
- Rules and URLs found during walks (E5 P1).
- Your rules and remotes (E1 test 5, E5 P5).
- UTF-8 cuts and reads (E1 tests 7-10, E4, E7).
- Byte, pair and target caps (E5 P2-P4).
- Rules in include targets: `_snap_config` reads every include target, whatever its condition (`:497-501`). `_snap_host_config` recurses into every include whose condition matches (`:630-638`).
- Rules in `config.worktree` and nested git dirs (`_snap_gitdir` `:700-703`, `_snap_nested`).
- `_snap_host_config` runs `git config --list` with no `--file` from `/`, so it reads system, global and XDG config like git does (paraphrased — no quote available because this is git's documented default scope set, inferred from the command at `:606`, not from code in this repo).

Any route found? No (paraphrased — no quote available because this claim covers the absence of any route across the traced paths).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:474-522`, `devcontainer-config/cc-exit-scan.sh:600-640`, `devcontainer-config/cc-exit-scan.sh:696-762`, `$P/git-semantics.log`, `$P/scan-probes.log`

---

## Claim 23: "Each new bats case plants a pre-receive hook … and `no_ran`. … The cap case sets `GIT_EXIT_SCAN_MAX_REWRITES` low and expects the snapshot to fail with "too many"."

**Location:** `docs/working/plan-q096-exit-scan-insteadof-target.md:75-77`
**Type:** Staleness / Reference
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Legibility-target:** reviewer
**Scope:** Covers the test-spec paragraph against the tests at HEAD. Does not establish the rest of the plan.

`GIT_EXIT_SCAN_MAX_REWRITES` does not exist at HEAD: grep found no hit outside docs/reviews except this plan line. It was split into `_PAIRS`/`_TARGETS`/`_BYTES` in e4b29291/4d7f966c. The cap test sets all three. It goes through `git_exit_scan` (status 2), not the snapshot. The byte-cap message says "too long", not "too many" (`test/cc-isolated-functions.bats:749-770`). Not every case plants a pre-receive hook and calls `no_ran`: the UTF-8 read, byte-wise and key-collision tests do not call `no_ran` (`test/cc-isolated-functions.bats:692-747`).

**Evidence:** `docs/working/plan-q096-exit-scan-insteadof-target.md:75-77`, `test/cc-isolated-functions.bats:692-770`

---

## Claim 24: "alias_url(url, rewrites): among every insteadOf value that is a prefix of url (plain starts_with, case-sensitive; an empty value matches everything), the longest wins … Applied once, never chained. … pushurl values are rewritten with insteadOf. When a remote has no pushurl, each remote.<n>.url is also rewritten with pushInsteadOf …"

**Location:** `docs/working/research-q096-exit-scan-insteadof-target.md:17-21`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** reviewer
**Scope:** Covers git 2.39.5 behaviour by experiment. Does not establish the remote.c function names (not read: git source is not in the sandbox).

E3: longest wins. Empty matches. Case-sensitive. No chaining. Without a pushurl, the pushInsteadOf target `pi-repo` ran rather than the insteadOf target. With a pushurl, the insteadOf target `ii-repo` ran.

**Evidence:** `$P/git-semantics.log`

---

## Claim 25: "`git config --list` lowercases section and key but keeps the subsection (the base)"

**Location:** `docs/working/research-q096-exit-scan-insteadof-target.md:44`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** reviewer
**Scope:** Covers git 2.39.5 output. Does not establish other versions.

E7: `[url "/Ab/X-"] InsteadOf = q` lists as `url./Ab/X-.insteadof`.

**Evidence:** `$P/read-probe.log`

---

## Claim 26a: "…is also rewritten by every url.<base>.insteadOf and pushInsteadOf rule whose value it starts with — from any config the scan reads, your own global and system config included — and the rewritten URL is walked the same way: git uses only the longest matching rule, the scan walks every match."

**Location:** `guides/cc-isolated-usage.md:321-326`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers rule sources, every-match walking and your own remotes. Does not establish anything about which values count as "those remote URLs" (Claim 26b).

E1 tests 1-5, E3 and E5 P1/P5 (see Claims 1a, 15, 16).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:444-471`, `devcontainer-config/cc-exit-scan.sh:830-858`, `$P/bats-q096.log`, `$P/git-semantics.log`

---

## Claim 26b: "Each of those remote URLs, local or not, and each remote.*.url/pushurl in your own config, is also rewritten…"

**Location:** `guides/cc-isolated-usage.md:321-323`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** user
**Scope:** Covers which values are queued. Does not establish a route: git does not rewrite bases either.

"Those" points back to a list (`guides/cc-isolated-usage.md:319-320`) that includes `url.<base>.insteadOf` bases, which are walked but never rewritten (Claim 1b). Precise version: "Each of those remote URLs (not the insteadOf bases)…".

**Evidence:** `guides/cc-isolated-usage.md:316-326`, `devcontainer-config/cc-exit-scan.sh:518-519`

---

## Claim 27: "Those, your insteadOf rules and your remote URLs are the only entries of your own config it follows; none is recorded."

**Location:** `guides/cc-isolated-usage.md:332-333`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Same as Claim 2.

E5 P5: 0 records naming global.cfg.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:600-640`, `$P/scan-probes.log`

---

## Claim 28: "…and so do a remote URL or insteadOf rule over 4,096 bytes, more than 100,000 URL-and-rule comparisons, or more than 2,000 rewritten URLs to walk (one per URL-and-rule match). (At launch any of these refuses the launch instead, exit 1.)"

**Location:** `guides/cc-isolated-usage.md:348-351`
**Type:** Configuration / Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers the three values, the strict boundaries, "one per match" and the exit codes. Does not establish that a working-tree path over 4,096 bytes occurs in practice.

Values and boundaries were executed:
- 4,096 bytes pass, 4,097 fail (E5 P3).
- A pair cap of 2 with exactly 2 pairs passes (E5 P4).
- The target cap fails on match N+1 (E5 P2, E1 test 11).

Exit 4 at exit and exit 1 at launch: Claim 4. The only imprecision is that the byte cap also covers the URL's working-tree path, which the reason names (Claim 7) and the guide omits.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:401-458`, `devcontainer-config/cc-isolated.sh:859-867`, `devcontainer-config/cc-isolated.sh:932-937`, `$P/scan-probes.log`, `$P/bats-q096.log`

---

## Claim 29: "(a remote of `.` is fine; an `insteadOf` base of `.` or `""` is not, nor a remote any `insteadOf` rule, yours included, rewrites to a relative path)"

**Location:** `guides/cc-isolated-usage.md:378-379`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Same as Claim 3.

E1 test 6 passed.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:377`, `test/cc-isolated-functions.bats:674-690`, `$P/bats-q096.log`

---

## Claim 30: "at the `insteadOf` caps, rewritten URLs alone add 10-80 s (a WSL2 host; the most when each is a planted repository)"

**Location:** `guides/cc-isolated-usage.md:418-419`
**Type:** Performance
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** user
**Scope:** Covers an order-of-magnitude check in the container (WSL2 kernel 6.18, 16 CPUs, load ~2.2). Does not establish the host figure the guide states.

E6 at 200 targets, against a 0.83 s no-match baseline: 200 missing targets took 1.49 s and 200 planted bare repos took 5.66 s. Extrapolating ×10 to 2,000 gives roughly 7 s and 48 s. That is the same order as 10-80 s and does not contradict it, but the guide's figure is a host measurement, and a full 2,000-target run was not made (small probes only, per the brief). Verifying it needs a host run at the caps.

**Evidence:** `$P/timing-probe.log`

---

## Claim 31: "Remote names and legacy remote files, read loosely. … a remote with no `url` (git pushes to its name), … a legacy file whose name holds a `/` …, a name defined in another repo of the checkout, a legacy URL's spaces or CR (trimmed differently, also by locale) …"

**Location:** `guides/cc-isolated-usage.md:421-427`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** user
**Scope:** Covers the code facts behind four atoms (no-url name, `/` names, one table across repos, locale trim). Does not establish git's side of each atom: that is the split unit's work.

`[ -z "$name" ] || _snap_rnames["$name"]=1` fires for any `remote.<name>.*` key (`devcontainer-config/cc-exit-scan.sh:505-507`). Legacy names: `name="${f#"$real/$d/"}"` from a recursive `find` (`:720-723`), so a nested file gives a name holding `/`. `_snap_rnames` is a single table across all git dirs (`:783`). The trim `${line#"${line%%[![:space:]]*}"}` (`:729`) is a bracket class that depends on the locale. E8: no `_snap_rnames` marking line changed against main, so this branch does not make the family worse.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:505-507`, `devcontainer-config/cc-exit-scan.sh:716-732`, `devcontainer-config/cc-exit-scan.sh:783`, `$P/numstat.log`

---

## Claim 32: "a `~` in a local remote URL (or one an `insteadOf` rule rewrites to) are taken as relative paths, not as git expands them."

**Location:** `guides/cc-isolated-usage.md:454-456`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** user
**Scope:** Covers `_snap_remote`'s handling of a leading `~`. Does not establish git's expansion rules.

Rewritten targets go through `_snap_remote`, where `case "$p" in /*) ;; *) p="$base/$p" ;; esac` (`devcontainer-config/cc-exit-scan.sh:378`) has no `~` branch.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:365-389`

---

## Claim 33: "`git push <url>` … uses a URL no config holds, and an `insteadOf` rule can rewrite it to a local path inside the checkout; the scan only sees URLs in config and legacy remotes files."

**Location:** `guides/cc-isolated-usage.md:457-459`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** user
**Scope:** Covers the URL sources of the scan. Does not establish anything about command-line usage.

The `_snap_url` call sites are config keys, legacy files, unresolved names and your config only (paraphrased — no quote available because this claim covers the absence of any other source; the call-site list is in Claim 1b).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:511`, `devcontainer-config/cc-exit-scan.sh:616`, `devcontainer-config/cc-exit-scan.sh:725-729`, `devcontainer-config/cc-exit-scan.sh:840`

---

## Claim 34: 03bc47c9: "dropping LC_ALL=C from that read fails it" · "193/193" · "Unit size 395 changed lines outside docs/"

**Location:** `git show 03bc47c9` (commit message body)
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** history
**Scope:** Covers the three checkable statements. Does not establish the iteration-3 review findings the message summarises.

E4: the mutated read fails the test. E2: 193 ok, 0 not ok. E8: numstat 156+34, 29+10 and 166+0, total 395.

**Evidence:** `$P/mut-legacy-read.log`, `$P/bats-full.log`, `$P/numstat.log`

---

## Claim 35: 013f1b3d: "_snap_rnames marking returns to main's rule (any remote.<name>.* key, any legacy file)"

**Location:** `git show 013f1b3d` (commit message body)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** history
**Scope:** Covers the marking lines at HEAD against main. Does not establish the stacked branch's content.

E8: the only `_snap_rnames` lines in the full diff are the comment, the `local -A` declaration and the closing-loop lookup. The marking lines at `:507` and `:723` are unchanged from main.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:505-507`, `devcontainer-config/cc-exit-scan.sh:723`, `$P/numstat.log`

---

## Claim 36: 4d7f966c: "the 2,000 cap counts URL-and-working-tree targets"

**Location:** `git show 4d7f966c` (commit message body)
**Type:** Configuration
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** history
**Scope:** Covers the target-cap semantics. Commit 03bc47c9 already records this correction.

The cap counts matches before dedupe (Claim 21, E5 P2). 03bc47c9 says so explicitly, so the record is already corrected.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:444-471`, `$P/scan-probes.log`

---

## Claim 37a: e4b29291: "GIT_EXIT_SCAN_MAX_REWRITE_TARGETS (2,000 distinct rewritten URLs)" · Notes: "The 2,000-target cap counts every distinct rewritten URL, local or not."

**Location:** `git show e4b29291` (commit message body)
**Type:** Configuration
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** history
**Scope:** Covers the target-cap semantics. Does not establish whether the code at e4b29291 differed: it counted per batch then, which is still per match and not distinct.

E5 P2 shows two matches with one distinct target tripping a cap of 1. 03bc47c9 corrects 4d7f966c's wording but does not name this commit. The plan row B14 still carries the same wording (Claim 21).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:444-471`, `$P/scan-probes.log`

---

## Claim 37b: e4b29291: "A name is now defined only by url/vcs or a URL read from the legacy file."

**Location:** `git show e4b29291` (commit message body)
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** history
**Scope:** Covers HEAD. The statement was true at e4b29291.

013f1b3d reverted it (Claim 35). At HEAD any `remote.<name>.*` key defines the name (`devcontainer-config/cc-exit-scan.sh:507`). The shared brief's summary of e4b29291 repeats the pre-revert rule.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:505-507`, `$P/numstat.log`

---

## Claim 38: 5f754994: "More than GIT_EXIT_SCAN_MAX_REWRITES (100,000) comparisons fails the snapshot closed."

**Location:** `git show 5f754994` (commit message body)
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Legibility-target:** history
**Scope:** Covers the variable name at HEAD. The value and behaviour survive as `GIT_EXIT_SCAN_MAX_REWRITE_PAIRS`.

Renamed in e4b29291: `GIT_EXIT_SCAN_MAX_REWRITE_PAIRS=100000` (`devcontainer-config/cc-exit-scan.sh:395`). The plan's test spec still uses the old name (Claim 23).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:394-396`

---

## Claims Requiring Attention

### Incorrect
- **Claim 21** (`docs/working/plan-q096-exit-scan-insteadof-target.md:27`): B14 says the target cap is "2,000 distinct rewritten URLs". It counts URL-and-rule matches, duplicates included. Change it to "2,000 URL-and-rule matches" to match the guide.
- **Claim 36** (commit 4d7f966c): "counts URL-and-working-tree targets" is wrong. Already corrected in 03bc47c9's message. History only.
- **Claim 37a** (commit e4b29291): "2,000 distinct rewritten URLs" is wrong in the same way. History only. The plan fix in Claim 21 is the place a correction can still land.

### Stale
- **Claim 23** (`docs/working/plan-q096-exit-scan-insteadof-target.md:75-77`): the test spec names the removed `GIT_EXIT_SCAN_MAX_REWRITES`, a single "too many" snapshot failure, and `no_ran` in every case. At HEAD there are three caps tested through `git_exit_scan` (status 2), and the byte cap message says "too long".
- **Claim 37b** (commit e4b29291): the "defined only by url/vcs" name rule was reverted by 013f1b3d. The shared brief's summary repeats it.
- **Claim 38** (commit 5f754994): `GIT_EXIT_SCAN_MAX_REWRITES` was renamed to `_PAIRS`.

### Mostly Accurate
- **Claim 1b** (`devcontainer-config/cc-exit-scan.sh:58-65`) and **Claim 26b** (`guides/cc-isolated-usage.md:321-323`): "each of those URLs" also covers insteadOf bases, which are walked but not rewritten. Say "(not the insteadOf bases)". No route: git does not rewrite bases either.
- **Claim 7** (`devcontainer-config/cc-exit-scan.sh:390-393`) and **Claim 28** (`guides/cc-isolated-usage.md:348-351`): the byte cap also covers the URL's working-tree path. The reason names it; these two texts omit it.
- **Claim 14** (`devcontainer-config/cc-exit-scan.sh:593-599`): `_snap_host_config`'s header does not mention that it now queues your rules and remote URLs.

### Unverifiable
- **Claim 30** (`guides/cc-isolated-usage.md:418-419`): 10-80 s at the caps is a host figure. Container extrapolation from 200 targets gives ~7 s / ~48 s, consistent in order. Verifying it needs a host run at 2,000 targets.

## Goal-Alignment Note

Goal: land Q-096 with 0 red and 0 unresolved amber, so that a session cannot repoint a push through an insteadOf rewrite the scan ignores.

Every claim about the enforcement mechanism holds by execution:
- git 2.39.5 rewrite semantics.
- Every (URL, rule) pair compared once, including rules and URLs found inside rewritten targets.
- Your own rules and remotes.
- Byte-wise matching and `LC_ALL=C` reads.
- Collision-free byte-counted keys.
- All three caps failing closed (snapshot 1, `git_exit_scan` 2, launcher 4 at exit and 1 at launch).

The Q-096 tests (11/11) and the full suite (193/193) pass. This pass found no route in the insteadOf pass (Claim 22).

What remains is documentation only, and none of it is a gap:
- The plan's B14 "distinct" wording (Incorrect) and its stale test-spec paragraph. Reviewer-facing; fix with a one-line edit each.
- Three Mostly-accurate comment and guide imprecisions, all on the fail-closed side or describing no route.
- Wrong historical commit-message wording, already partly corrected in 03bc47c9.

I see nothing here that needs escalating as a blocker. If the rubric treats reviewer-doc inaccuracies as amber, Claim 21 and Claim 23 are the two items to clear before merging. Both are text edits to docs/working/plan-q096-exit-scan-insteadof-target.md and do not change the code.
