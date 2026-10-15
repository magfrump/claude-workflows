Commit: 013f1b3d

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-q096 (branch fix/q096-exit-scan-insteadof-target)
**Scope:** iteration-3 partial scope `git diff e4b29291..013f1b3d -- . ':!docs/reviews'` (commits 4d7f966c and 013f1b3d): devcontainer-config/cc-exit-scan.sh, docs/working/plan-q096-exit-scan-insteadof-target.md, guides/cc-isolated-usage.md, test/cc-isolated-functions.bats, plus the two commit messages. Unchanged text in the touched files is in scope where the diff made it true or false (Claims 11, 12b). 5f754994 and e4b29291 are context only, except for brief claim 5 (Claim 20), which asks about the whole insteadOf pass.
**Checked:** 2026-10-15
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 32 (30 numbered, two of them split into a/b)
**Summary:** 25 verified, 1 mostly accurate, 3 stale, 3 incorrect, 0 unverifiable

I read the hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) before checking. Its entries include commit-message test tallies that turned out wrong. The tallies here, "195/195" (Claim 30) and "400 changed lines" (Claim 29), were checked against that pattern by running the suite and `git diff --numstat`. Both hold. None of the Incorrect verdicts below is a fabricated symbol or API. The two Stale ones name `_snap_rewrite`, a function that was removed (not invented), so nothing goes into the log.

**Execution environment.** git 2.39.5, bash 5.2, bats, locales C and C.utf8. Probe scripts and captured output are in `/home/node/.claude/jobs/00bcf178/tmp/q096/probe-factcheck-p3/`, called `$P` below (logs in `$P/logs/`). Every probe that runs the scan sets `GIT_CONFIG_GLOBAL` to a file in `$P` and `GIT_CONFIG_NOSYSTEM=1`, and sources `devcontainer-config/cc-exit-scan.sh` from the worktree. The old-scan copy is in `$P/old/` (from `git show e4b29291:…`). The mutant is in `$P/mut/` and `$P/mutrepo/`. Every process ran under `timeout` of 600 s or less and exited on its own. The one background run (the full bats suite) finished with exit 0 before I wrote this report, and `ps -u node` afterwards showed none of my processes.

| Run | Command (cwd `$P` unless noted) | Exit | Timestamp (UTC) | Output |
|---|---|---|---|---|
| R1 key bytes / collisions / length cap | `LC_ALL=C timeout 60 bash p1-key.sh` | 0 | 2026-10-15T08:21:58Z | `$P/logs/p1-key.log` |
| R2 snapshot-level caps, pair count | `LC_ALL=C timeout 300 bash p2-snapshot.sh` | 0 | 2026-10-15T08:22:27Z | `$P/logs/p2-snapshot.log` |
| R3 batch bound, duplicate targets, walk failure | `LC_ALL=C timeout 300 bash p3-batch.sh` | 0 | 2026-10-15T08:22:50Z | `$P/logs/p3-batch.log` |
| R4 UTF-8 key test, old vs new scan | `timeout 300 bash run-p4.sh` (each scan under `timeout 120`) | 0 / 0 | 2026-10-15T08:23:32Z | `$P/logs/p4-utf8.log` |
| R5 timing at the target cap | `LC_ALL=C timeout 600 bash p5-timing.sh` | 0 | 2026-10-15T08:25:40Z | `$P/logs/p5-timing.log` |
| R6 bats, Q-096 subset | `LC_ALL=C timeout 600 bats -f 'Q-096' test/cc-isolated-functions.bats` (cwd worktree) | 0 | 2026-10-15T08:25:59Z | `$P/logs/bats-q096.log` |
| R7 bats, full suite | `LC_ALL=C timeout 600 bats test/cc-isolated-functions.bats` (cwd worktree) | 0 | 2026-10-15T08:26:52Z | `$P/logs/bats-full.log` |
| R8 match vs cut under UTF-8 | `timeout 30 bash p6-match-mech.sh` | 0 | 2026-10-15T08:26:59Z | `$P/logs/p6-p7.log` |
| R9 read coverage, real scan and :729 mutant | `LC_ALL=C timeout 120 bash p7-read-coverage.sh <scan>` | 0 / 0 | 2026-10-15T08:26:59Z | `$P/logs/p6-p7.log` |
| R10 exit-scan tests against the :729 mutant | `LC_ALL=C timeout 600 bats -f 'exit scan' test/cc-isolated-functions.bats` (cwd `$P/mutrepo`) | 0 | 2026-10-15T08:27:50Z | `$P/logs/bats-mut729.log` |

---

## Claim 1: "Only those three kinds of entry, your insteadOf rules and your remote URLs are followed in your own config; its entries are not recorded (the container cannot write it)."

**Location:** `devcontainer-config/cc-exit-scan.sh:71-73`
**Type:** Behavioral
**Legibility-target:** for-orchestrator-synthesis
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers which of your own config's keys `_snap_host_config` acts on, and that it appends no record; does not establish that records are absent for an include target inside the checkout, which is walked by `_snap_config` and recorded there (the function's own header says so at `:598-599`).

`_snap_host_config` (read in full, `:600-641`) acts on the rule and URL keys, then on three more:

```bash
# devcontainer-config/cc-exit-scan.sh:615-618
    case "$key" in
      url.*.insteadof|url.*.pushinsteadof) t="${key#url.}"; _snap_rule "${t%.*}" "$val" || return 1 ;;
      remote.*.url|remote.*.pushurl) _snap_url "$val" "$wt" || return 1 ;;
    esac
```

The second `case` (`:621-639`) handles only `core.hookspath`, `core.attributesfile` and `include.path|includeif.*.path`. There is no `_snap+=` anywhere in the function (paraphrased — no quote available because the claim is about the absence of code: `rg '_snap\+=' ` finds no hit in `:600-641`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:600-641`

---

## Claim 2: "an insteadOf pass too long or too large (_snap_key, _snap_pairs_ok, _snap_match) makes the snapshot fail: at launch the launcher refuses to start, at exit it returns 4."

**Location:** `devcontainer-config/cc-exit-scan.sh:97-100`
**Type:** Error-handling
**Legibility-target:** for-orchestrator-synthesis
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers all three caps failing `git_exec_snapshot` (rc 1) and `git_exit_scan` (rc 2), and the launcher's mapping of those to exit 1 and exit 4; does not establish the launcher end to end (that needs Docker, so the mapping is read, not run). "Returns 4" is loose: `git_exit_scan` returns 2 and the launcher exits 4.

R2 case A: a 4,097-byte remote URL gives `snapshot rc=1` and `git_exit_scan rc=2`. R3 case B: past the target cap, `snapshot rc=1`. The bats test "past either insteadOf cap" (R6, test 13) asserts `status -eq 2` for each of the three caps. The launcher maps these results as follows:

```bash
# devcontainer-config/cc-isolated.sh:859,867  (launch)
    if ! git_before="$(git_exec_snapshot "$ws" "$lws" 2>"$snap_err")"; then
      exit 1
# devcontainer-config/cc-isolated.sh:932-937  (exit)
  git_exit_scan "$ws" "$git_before" "$lws" || scan=$?
  case "$scan" in
    0) exit "$rc" ;;
    1) exit 3 ;;
    *) exit 4 ;;
```

(The second excerpt ends at `:937`. The enclosing `case` closes at `:938` (read).)

**Evidence:** `devcontainer-config/cc-exit-scan.sh:401-408`, `devcontainer-config/cc-exit-scan.sh:430-435`, `devcontainer-config/cc-exit-scan.sh:444-458`, `devcontainer-config/cc-isolated.sh:859-867`, `devcontainer-config/cc-isolated.sh:926-938`, `$P/logs/p2-snapshot.log`, `$P/logs/p3-batch.log`, `$P/logs/bats-q096.log`

---

## Claim 3: "EVERY `read` RUNS UNDER LC_ALL=C: in a UTF-8 locale it swallows a NUL or newline after an incomplete multibyte character, hiding the next entry from the scan." (also plan row B25: "every `read` in `cc-exit-scan.sh` runs as `LC_ALL=C IFS= read`")

**Location:** `devcontainer-config/cc-exit-scan.sh:123-124`
**Type:** Invariant / Behavioral
**Legibility-target:** for-orchestrator-synthesis
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every `read` builtin in the file at 013f1b3d, and the swallowed-newline mechanism for the legacy-remotes reader (`:729`); does not establish that the test suite still guards each read site (it no longer guards `:729`: see Claim 28).

`rg -n '\bread\b'` over the file, with comments and `LC_ALL=C IFS= read` lines filtered out, leaves only `_snap_fail` message strings, `readlink`, and `cat` lines (paraphrased — no quote available because the claim covers the absence of any other `read`). R9 shows the mechanism. A legacy remotes file `URL: x\xc3\nURL: ./leg.git` under `LC_ALL=C.utf8` gives "legacy half: FOUND" with the real scan, and "legacy half: MISSED" with `:729` changed to a bare `IFS= read`:

```bash
# devcontainer-config/cc-exit-scan.sh:729
      while LC_ALL=C IFS= read -r line || [ -n "$line" ]; do
```

**Evidence:** `devcontainer-config/cc-exit-scan.sh:123-124`, `devcontainer-config/cc-exit-scan.sh:729`, `docs/working/plan-q096-exit-scan-insteadof-target.md:37`, `$P/logs/p6-p7.log`

---

## Claim 4: "the insteadOf pass's queues (_snap_urls/_snap_ubases, _snap_rbases/_snap_rpfx, _snap_hit_t/_snap_hit_b, _snap_rwseen, _snap_k, the _snap_rwn/_snap_rwt counters)" are declared by git_exec_snapshot

**Location:** `devcontainer-config/cc-exit-scan.sh:160-163`
**Type:** Architectural
**Legibility-target:** for-orchestrator-synthesis
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the declarations; does not establish that no helper uses an undeclared global (only the insteadOf helpers were read for this).

```bash
# devcontainer-config/cc-exit-scan.sh:781-784
  local _snap_bytes=0 _snap_rwn=0 _snap_rwt=0 _snap_k u r
  local -A _snap_seen=() _snap_rnames=() _snap_rwseen=()
  local -a _snap_names=() _snap_nbases=() _snap_urls=() _snap_ubases=() _snap_rbases=() _snap_rpfx=()
  local -a _snap_hit_t=() _snap_hit_b=()
```

**Evidence:** `devcontainer-config/cc-exit-scan.sh:779-784`

---

## Claim 5: "Caps on the insteadOf pass ... bytes in one URL, rule base or value (_snap_key); pairs compared (_snap_pairs_ok); rewritten URLs to walk, each a few forks (_snap_match). Over any of them the snapshot fails (fail closed)." with constants 4096 / 100000 / 2000

**Location:** `devcontainer-config/cc-exit-scan.sh:390-396`
**Type:** Configuration / Error-handling
**Legibility-target:** for-orchestrator-synthesis
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three constants, which function enforces each, and that each fails the snapshot; does not establish the per-target cost ("a few forks"): R5 measured about 4.5 ms for a target that does not exist and about 39 ms for one that is a bare repo, which is a full git-dir walk, not a few forks.

```bash
# devcontainer-config/cc-exit-scan.sh:394-396
GIT_EXIT_SCAN_MAX_REWRITE_BYTES=4096
GIT_EXIT_SCAN_MAX_REWRITE_PAIRS=100000
GIT_EXIT_SCAN_MAX_REWRITE_TARGETS=2000
```

R1 (bytes), R2 case A (bytes, end to end), R3 case B (targets) and bats test 13 (all three) each fail closed.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:390-458`, `$P/logs/p1-key.log`, `$P/logs/p2-snapshot.log`, `$P/logs/p3-batch.log`, `$P/logs/p5-timing.log`

---

## Claim 6: "_snap_key <a> <b> [check]: _snap_k, a key for the pair prefixed by <a>'s length in bytes (LC_ALL=C; characters collide), so no byte can join two pairs. With <check>, fail when <a> or <b> is over GIT_EXIT_SCAN_MAX_REWRITE_BYTES." (brief claim 1)

**Location:** `devcontainer-config/cc-exit-scan.sh:398-408`
**Type:** Behavioral / Invariant
**Legibility-target:** for-orchestrator-synthesis
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers byte-length prefixes and injectivity for the `u:`, `r:` and `t:` keys in C and C.utf8, the restoring of the caller's locale, and the fail-closed check at 4,096 bytes; does not establish locales other than C/C.utf8. It also does not cover the case where the check fires on `<b>` being a working-tree path, not a URL, in `_snap_url`. That would give a mislabelled message, but only for a path over 4,096 bytes.

```bash
# devcontainer-config/cc-exit-scan.sh:401-408
_snap_key() {
  local LC_ALL=C
  _snap_k="${#1}:$1$2"
  [ -n "${3:-}" ] || return 0
  [ "${#1}" -gt "$GIT_EXIT_SCAN_MAX_REWRITE_BYTES" ] || [ "${#2}" -gt "$GIT_EXIT_SCAN_MAX_REWRITE_BYTES" ] || return 0
  _snap_fail 'a remote URL or insteadOf rule over %s bytes: too long to compare, treat the checkout as unsafe' \
    "$GIT_EXIT_SCAN_MAX_REWRITE_BYTES"
}
```

R1 under `LC_ALL=C.utf8` gave these results:
- `a\xc3\xa9` is 2 characters but gets the key `3:aéx`.
- The pairs (`sub/a\xc3`, `\xa9c`) and (`sub/a\xc3\xa9`, `c`) get keys `6:` and `7:`, so they stay distinct.
- All 11 splits of a mixed multibyte string give 0 collisions.
- `LC_ALL` is still `C.utf8` after the call.
- 4,096 bytes passes and 4,097 fails, for `<a>` and for `<b>`.
- A URL of 2,058 characters but 4,098 bytes fails, so the check counts bytes, not characters.

The key is `<len(a)>:<a><b>`. With `<a>`'s byte length fixed, the pair can be read back from the key unambiguously, so keys are collision-free. On whether 4,096 is safe for legitimate configs: R1 accepted a 2,748-byte https URL, and R2 case A2 accepted a rule value of exactly 4,096 bytes. A local base longer than Linux PATH_MAX (4,096) cannot be used as a path anyway. A real URL over 4 KiB is very unlikely but possible, for example a long token in a query string. If one sits in *your own* global config, every launch refuses (exit 1). That is fail-closed, not a bypass.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:398-427`, `devcontainer-config/cc-exit-scan.sh:466`, `$P/logs/p1-key.log`, `$P/logs/p2-snapshot.log`

---

## Claim 7: "_snap_url <url> <working tree>: a remote URL git may push to. Walked now (_snap_remote) and queued for the insteadOf rules (_snap_match), once each."

**Location:** `devcontainer-config/cc-exit-scan.sh:410-411`
**Type:** Behavioral
**Legibility-target:** for-orchestrator-synthesis
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that each (URL, working tree) pair is queued and walked once; does not establish that every URL source calls `_snap_url` (a `remote.pushDefault` set in *your own* config is not followed: see Claim 20's residue).

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

## Claim 8: "git's alias_url compares bytes ... so the match and the cut run under LC_ALL=C: in a UTF-8 locale ${#p} counts characters, and a value ending mid-character would cut the URL in the wrong place." (also plan row B22, "mechanism corrected")

**Location:** `devcontainer-config/cc-exit-scan.sh:437-443`
**Type:** Behavioral
**Legibility-target:** for-orchestrator-synthesis
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the cut mechanism for a value ending mid-character in bash 5.2 / C.utf8; does not establish git's own byte comparison by reading remote.c (no source offline), which is taken from git behaviour as covered by bats test 9.

R8 used `p=$'a\xc3'` and `u=$'a\xc3\xa9x'`. Under C.utf8 the result was `match=yes`, `${#p}=2` and `cut=x`, which is wrong. Under C it was `match=yes` and `cut=$'\251x'`, which is right. So the match succeeds in both locales and only the cut goes wrong, which is what the corrected comment says. `_snap_match` declares `local LC_ALL=C` at `:445`.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:444-458`, `docs/working/plan-q096-exit-scan-insteadof-target.md:34`, `$P/logs/p6-p7.log`

---

## Claim 9: `_snap_match`'s per-hit target-cap check bounds the batch's memory (commit 4d7f966c: "_snap_match now checks the target cap per hit"; plan row B28) (brief claim 2, first part)

**Location:** `devcontainer-config/cc-exit-scan.sh:444-458`
**Type:** Performance / Error-handling
**Legibility-target:** for-orchestrator-synthesis
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that `_snap_hit_t` never holds more than `GIT_EXIT_SCAN_MAX_REWRITE_TARGETS − _snap_rwt` entries. That puts the worst case at about 2,000 strings of up to about 8 KiB each (base plus URL rest, each capped at 4,096). It does not establish what the cap counts (every matching pair, not distinct targets: see Claim 19b).

```bash
# devcontainer-config/cc-exit-scan.sh:448-454
    if [[ "$u" == "$p"* ]]; then
      if [ $((_snap_rwt + ${#_snap_hit_t[@]})) -ge "$GIT_EXIT_SCAN_MAX_REWRITE_TARGETS" ]; then
        _snap_fail 'more than %s URLs rewritten by insteadOf rules to walk (%s URLs, %s rules so far): too many, treat the checkout as unsafe' \
          "$GIT_EXIT_SCAN_MAX_REWRITE_TARGETS" "${#_snap_urls[@]}" "${#_snap_rbases[@]}"
        return 1
      fi
      _snap_hit_t+=("${_snap_rbases[ri]}${u:${#p}}"); _snap_hit_b+=("${_snap_ubases[ui]}")
```

(The excerpt ends at `:454`. The enclosing `_snap_match` continues to `:458` (read).) In R3 case B, one rule was matched against 200 URLs in a single batch of n=200. With cap 7, `_snap_match` returned 1 holding `hits_held=7`. With cap 200, all 200 hits passed.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:444-458`, `docs/working/plan-q096-exit-scan-insteadof-target.md:40`, `$P/logs/p3-batch.log`

---

## Claim 10: "_snap_walk_hits: walk each rewritten URL _snap_match found, like any remote, once; never queued as a URL (git rewrites once), and walking adds no hits."

**Location:** `devcontainer-config/cc-exit-scan.sh:460-461`
**Type:** Behavioral
**Legibility-target:** for-orchestrator-synthesis
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers dedupe of the walk by (target, working tree), that the target is not added to `_snap_urls`, and that nothing under `_snap_remote` appends to `_snap_hit_t`; does not establish that the target-cap *count* is deduped (it is not: `_snap_rwt` increments before the dedupe check, see Claim 19b).

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

`_snap_match` is called only from the main loop (`:845`, `:851`), so walking cannot add hits (paraphrased — no quote available because this rests on a grep of call sites: `rg -n '_snap_match "'` finds only those two lines). In R2 case D, walking target `m-x` added its config's URL `q` (U went from 2 to 3) but not the target itself, which ended with U=3 for URLs o, p and q.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:462-471`, `devcontainer-config/cc-exit-scan.sh:845`, `devcontainer-config/cc-exit-scan.sh:851`, `$P/logs/p2-snapshot.log`

---

## Claim 11: "url.<base>.insteadOf rewrites matching URLs to <base>: the base alone here, every URL it rewrites in git_exec_snapshot (_snap_rewrite)."

**Location:** `devcontainer-config/cc-exit-scan.sh:517-518`
**Type:** Staleness
**Legibility-target:** for-author
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the symbol reference only; the behaviour described (base walked here, rewritten URLs in the main loop) is right.

4d7f966c removed `_snap_rewrite`. Its work moved into `_snap_match` and `_snap_walk_hits` (`:444-471`). `rg -n '_snap_rewrite'` outside docs/reviews now finds only this comment and `:831` (paraphrased — no quote available because the claim covers the absence of a definition). The comment should name `_snap_match`/`_snap_walk_hits`.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:517-518`, `devcontainer-config/cc-exit-scan.sh:444-471`

---

## Claim 12a: "a new URL meets the rules already seen, a new rule meets the URLs already seen, so each pair meets once." (brief claim 2, last part)

**Location:** `devcontainer-config/cc-exit-scan.sh:830-833`
**Type:** Invariant
**Legibility-target:** for-orchestrator-synthesis
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers exactly-once comparison when walking adds URLs and rules mid-loop (one instrumented case, plus the index argument); does not establish termination bounds beyond the caps.

```bash
# devcontainer-config/cc-exit-scan.sh:841-852
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
      r=$((r + 1))
```

(The excerpt ends at `:852`. The loop continues to `:856`, the function to `:860` (read).) In R2 case D the queues grew mid-loop: the walked target's config added one URL and one rule. The pair charges were 0, 0, 2, 1 and 3, totalling `rwn=6`, which is U×R for U=3 and R=2.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:834-856`, `$P/logs/p2-snapshot.log`

---

## Claim 12b: "every URL meets every insteadOf rule (_snap_rewrite)"

**Location:** `devcontainer-config/cc-exit-scan.sh:831`
**Type:** Staleness
**Legibility-target:** for-author
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the symbol reference only.

This has the same cause as Claim 11. `_snap_rewrite` no longer exists, and the loop beneath this comment calls `_snap_match` and `_snap_walk_hits` (quoted in Claim 12a, `:845`, `:851`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:831`, `devcontainer-config/cc-exit-scan.sh:845`, `devcontainer-config/cc-exit-scan.sh:851`

---

## Claim 13: `_snap_match ... && _snap_walk_hits || rc=1` fails closed on either failure (commit 4d7f966c) (brief claim 2, middle part)

**Location:** `devcontainer-config/cc-exit-scan.sh:845`
**Type:** Error-handling
**Legibility-target:** for-orchestrator-synthesis
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both the `_snap_match` failure (target cap) and a `_snap_remote` failure inside `_snap_walk_hits`, each ending the loop and failing the snapshot. It does not establish a natural (unmocked) walk-only failure. R2 case C tried an unenterable target and was caught earlier by the tree `find`, so the walk path was tested with a mocked `_snap_remote`.

When `_snap_match` returns 1, the `&&` skips the walk and `|| rc=1` fires. When the walk returns 1, `|| rc=1` fires. The loop guard `while [ "$rc" -eq 0 ]` (`:835`) then ends the loop, and `[ "$rc" -eq 0 ] || return 1` (`:858`) fails the snapshot. R3 case B shows the target cap gives `snapshot rc=1`. R3 case C uses a mocked `_snap_remote` that fails on `evil-x`, and also gives `snapshot rc=1`.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:835`, `devcontainer-config/cc-exit-scan.sh:845`, `devcontainer-config/cc-exit-scan.sh:851`, `devcontainer-config/cc-exit-scan.sh:858`, `$P/logs/p3-batch.log`

---

## Claim 14: "_snap_rnames marking returns to main's rule (any remote.<name>.* key, any legacy file)" (commit 013f1b3d; brief claim 3)

**Location:** `devcontainer-config/cc-exit-scan.sh:512`
**Type:** Behavioral
**Legibility-target:** for-orchestrator-synthesis
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the `_snap_rnames` writes and the lookup. It does not establish identical *downstream* behaviour for an undefined name. That now goes through `_snap_url`, not `_snap_remote`, so it is also queued for insteadOf rules and subject to the 4,096-byte cap, which is this unit's purpose and not a remote-name change.

`git diff -U0 main..013f1b3d` holds no `+`/`-` line that writes `_snap_rnames`. The only changed lines that mention it are the header comment, the `local -A` declaration (which adds `_snap_rwseen`), and the lookup line, whose tail changed from `_snap_remote` to `_snap_url`. The writes are unchanged except for their line numbers. On main they are `[ -z "$name" ] || _snap_rnames["$name"]=1` at `:416` and `_snap_rnames["$name"]=1` at `:621`. At 013f1b3d they are:

```bash
# devcontainer-config/cc-exit-scan.sh:512
        [ -z "$name" ] || _snap_rnames["$name"]=1
# devcontainer-config/cc-exit-scan.sh:724
      _snap_rnames["$name"]=1
# devcontainer-config/cc-exit-scan.sh:840
      [ -z "$f" ] || [ -n "${_snap_rnames["$f"]:-}" ] || _snap_url "$f" "$g" || rc=1
```

The no-url test is gone from the bats file, and main's guide never had the "remote with no `url`" phrase (it does not appear in `git diff main..013f1b3d -- guides/`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:510-515`, `devcontainer-config/cc-exit-scan.sh:721-736`, `devcontainer-config/cc-exit-scan.sh:840`, `git show main:devcontainer-config/cc-exit-scan.sh` (`:416`, `:621`, `:733`)

---

## Claim 15: Plan row B22: "bash in a UTF-8 locale counts `${#p}` in characters and cuts the URL in the wrong place ... `_snap_match` matches and cuts under `local LC_ALL=C`"

**Location:** `docs/working/plan-q096-exit-scan-insteadof-target.md:34`
**Type:** Behavioral
**Legibility-target:** for-orchestrator-synthesis
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claim 8.

R8 output: `utf8: ${#p}=2` and `utf8: cut=x`, against `C: cut=$'\251x'`. `local LC_ALL=C ui="$1" ...` is at `devcontainer-config/cc-exit-scan.sh:445`.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:445`, `$P/logs/p6-p7.log`

---

## Claim 16: Plan rows B24 / B29: "not covered here: split to its own unit after iteration 2 ... moved to the stacked branch `fix/q096b-exit-scan-remote-names`; the guide lists the family as a known route"

**Location:** `docs/working/plan-q096-exit-scan-insteadof-target.md:36`
**Type:** Reference
**Legibility-target:** for-orchestrator-synthesis
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the branch existing and the guide bullet existing; does not review the stacked branch's content (unreviewed, as 013f1b3d's Notes say).

`git branch -a` lists `fix/q096b-exit-scan-remote-names`. The guide carries "**Remote names and legacy remote files, read loosely.**" at `guides/cc-isolated-usage.md:420`.

**Evidence:** `docs/working/plan-q096-exit-scan-insteadof-target.md:36`, `docs/working/plan-q096-exit-scan-insteadof-target.md:41`, `guides/cc-isolated-usage.md:420-425`

---

## Claim 17: Plan rows B26–B28: "`_snap_key` measures under `LC_ALL=C`"; "`GIT_EXIT_SCAN_MAX_REWRITE_BYTES` (4,096) fails closed"; "`_snap_match` checks the target cap per hit"

**Location:** `docs/working/plan-q096-exit-scan-insteadof-target.md:38-40`
**Type:** Behavioral
**Legibility-target:** for-orchestrator-synthesis
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three mechanisms named; see Claims 6 and 9 for their limits.

`local LC_ALL=C` appears at `devcontainer-config/cc-exit-scan.sh:402`, `GIT_EXIT_SCAN_MAX_REWRITE_BYTES=4096` at `:394`, and the per-hit check at `:449`. R1, R2 and R3 exercised all three.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:394`, `devcontainer-config/cc-exit-scan.sh:402`, `devcontainer-config/cc-exit-scan.sh:449`, `$P/logs/p1-key.log`, `$P/logs/p3-batch.log`

---

## Claim 18: "Those, your `insteadOf` rules and your remote URLs are the only entries of your own config it follows; none is recorded."

**Location:** `guides/cc-isolated-usage.md:332-333`
**Type:** Behavioral
**Legibility-target:** for-orchestrator-synthesis
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Same as Claim 1. ("None" means the entries of your own config files, not the entries of an include target inside the checkout, which `_snap_config` records.)

This is the same code as Claim 1 (`devcontainer-config/cc-exit-scan.sh:615-618`, `:621-639`, and no `_snap+=` in `_snap_host_config`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:600-641`

---

## Claim 19a: "so do a remote URL or `insteadOf` rule over 4,096 bytes, more than 100,000 URL-and-rule comparisons, or more than 2,000 rewritten URLs to walk ... (At launch any of these refuses the launch instead, exit 1.)"

**Location:** `guides/cc-isolated-usage.md:348-351`
**Type:** Configuration / Error-handling
**Legibility-target:** for-orchestrator-synthesis
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three thresholds and the exit-4 and exit-1 mapping (mapping read, not run, as in Claim 2). It does not establish the counting unit given in the parenthetical (Claim 19b). Also, the byte cap applies to a working-tree path too, not only to "a remote URL or rule".

These are the constants at `devcontainer-config/cc-exit-scan.sh:394-396` (quoted in Claim 5). R1 showed the check is `>` at 4,096 bytes, R2 that 4,096 passes and 4,097 fails. The pairs check is `[ "$_snap_rwn" -gt ... ]` (`:432`). For targets, R3 showed "more than N", that is N passes and N+1 fails.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:394-458`, `devcontainer-config/cc-isolated.sh:859-867`, `devcontainer-config/cc-isolated.sh:932-937`, `$P/logs/p1-key.log`, `$P/logs/p2-snapshot.log`, `$P/logs/p3-batch.log`

---

## Claim 19b: "more than 2,000 rewritten URLs to walk (one per URL and working tree)"

**Location:** `guides/cc-isolated-usage.md:349-350`
**Type:** Configuration
**Legibility-target:** for-author
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the target cap counts. It does not establish any security effect. The cap counts *more* than the guide says, so it trips earlier and still fails closed. The impact is only that a reader cannot predict when a legitimate config trips.

The cap counts every matching (URL, rule) pair. Duplicates are included, because `_snap_rwt` increments before the dedupe check:

```bash
# devcontainer-config/cc-exit-scan.sh:465-467
    _snap_rwt=$((_snap_rwt + 1))
    _snap_key "${_snap_hit_t[h]}" "${_snap_hit_b[h]}"
    [ -z "${_snap_rwseen["t:$_snap_k"]:-}" ] || continue
```

(The excerpt ends at `:467`. The enclosing `_snap_walk_hits` continues to `:471` (read).) `_snap_match` checks `_snap_rwt + ${#_snap_hit_t[@]}`, a count of pairs, at `:449`. R3 case B2 used rules `…/s` ← `https://o.invalid/` and `…/sx` ← `https://o.invalid/x` on one URL, which gives two hits but one distinct target and working tree (`…/sx`). With `GIT_EXIT_SCAN_MAX_REWRITE_TARGETS=1` it failed with "more than 1 URLs rewritten by insteadOf rules to walk", even though only one URL was rewritten. e4b29291's `_snap_rewrite` incremented after its dedupe check, so it counted distinct targets. 4d7f966c moved the increment ahead of the check. The precise text would be "more than 2,000 URL-and-rule matches to walk". The other option is to count after the dedupe in `_snap_walk_hits` and in `_snap_match`'s check.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:449`, `devcontainer-config/cc-exit-scan.sh:462-471`, `$P/logs/p3-batch.log`

---

## Claim 20: "Each of those remote URLs, local or not, and each `remote.*.url`/`pushurl` in your own config, is also rewritten by every `url.<base>.insteadOf` and `pushInsteadOf` rule whose value it starts with — from any config the scan reads ... and the rewritten URL is walked the same way: git uses only the longest matching rule, the scan walks every match." (brief claim 5: any remaining route in the insteadOf pass)

**Location:** `guides/cc-isolated-usage.md:321-326`
**Type:** Behavioral
**Legibility-target:** for-orchestrator-synthesis
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the URL sources the guide lists (checkout and embedded-repo `remote.*.url`/`pushurl`, `remote.pushDefault`, `branch.*.remote`/`pushRemote` names that resolve to URLs, legacy files, your own `remote.*.url`/`pushurl`) meeting rules from every config read, with all matches walked, and the caps failing closed. It does not establish four things: (a) a URL your *own* config names through `remote.pushDefault` or `branch.*.pushRemote`, which `_snap_host_config` does not queue, an unusual but pre-existing gap outside this diff; (b) the remote-name/legacy-file family, split out and listed as a known route; (c) `~` bases (B18) or command-line URLs (B20), already known routes; (d) host bash versions other than 5.2.

Mechanism: every rule from `_snap_config` (`:521`) and `_snap_host_config` (`:616`) and every URL from `_snap_url` meets once (Claim 12a). Every prefix match is walked with the URL's working tree (Claims 9, 10). Within this scope I found no way to leave a match unwalked. Overlong inputs fail at the byte cap (Claim 6), large sets fail at the pair and target caps (Claims 9, 13), dedupe keys are injective in bytes (Claim 6), and the match and cut are byte-wise (Claim 8). The caps give a hostile session a denial-of-service (exit 4), which is fail-closed and documented (override-log row 134), not a silent pass. R6 ran all 13 Q-096 bats tests, which cover pushInsteadOf, pushurl, overlapping prefixes, path-valued pushRemote, embedded repos, your own global rule, your own remote, byte-wise UTF-8 matching, tabs, key collision and the caps: 13/13 ok. R4 shows the iteration-2 key collision bypass is closed.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:410-471`, `devcontainer-config/cc-exit-scan.sh:510-523`, `devcontainer-config/cc-exit-scan.sh:610-618`, `devcontainer-config/cc-exit-scan.sh:834-856`, `$P/logs/bats-q096.log`, `$P/logs/p4-utf8.log`

---

## Claim 21: "at the `insteadOf` caps, rewritten URLs alone add about 30 s."

**Location:** `guides/cc-isolated-usage.md:418-419`
**Type:** Performance
**Legibility-target:** for-author
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers one snapshot on this machine, with load average 1–3 from other sessions, for 1,999 rewritten local targets that either do not exist or are bare repos. It does not establish host timings or targets larger than an empty bare repo, and it is per snapshot, so the scan pays it at launch and again at exit.

R5 used 1,999 https remotes. With no rule the snapshot took 1.35 s. With one rule rewriting all of them to absent local paths it took 10.3 s, about 9 s added. With the same rule and each target an empty bare repo it took 78.9 s, about 77 s added, or roughly 39 ms per target. That is close to the guide's own "about 29 ms more for each embedded repository" (`guides/cc-isolated-usage.md:413-414`) × 2,000, about 58 s. The mechanism (walking each target costs forks, bounded by the 2,000 cap) is right. The figure sits between the two cases and understates the planted-repo case, which is the one a hostile session controls. A more precise text: "about 10 s, or about a minute when each target is a git dir".

**Evidence:** `devcontainer-config/cc-exit-scan.sh:356-388`, `devcontainer-config/cc-exit-scan.sh:462-471`, `$P/logs/p5-timing.log`

---

## Claim 22: Known route "Remote names and legacy remote files, read loosely": "a remote with no `url` (git pushes to its name), an empty `branches` file, a name defined in another repo of the checkout, untrimmed spaces or a CR in a legacy URL, and `file://host/` or percent-encoded `file://` URLs can each name a path the scan does not walk (if present at launch)."

**Location:** `guides/cc-isolated-usage.md:420-425`
**Type:** Behavioral
**Legibility-target:** for-orchestrator-synthesis
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the scan side of each item at 013f1b3d. The git side (remote.c `valid_remote`/`add_url_alias`, `read_branches_file` trimming, `file://host/` handling) rests on git 2.39 behaviour as recalled and as iteration 2 probed it. remote.c was not readable offline. "(if present at launch)" is terse. Its meaning, that the loosely-read entry must already be in config at launch because adding it later is a config finding, is right but takes some decoding.

These are the scan-side mechanisms (paraphrased — no quote available because they span four sites already quoted above):
- Any `remote.<name>.*` key marks the name as defined (`:512`), so a fetch-only remote marks it too.
- A legacy file marks its name before its body is read (`:724`). An empty `branches` file then sends the URL `""`, which `_snap_remote` drops (`:368`).
- A single `_snap_rnames` table serves every repo, because it is declared once at `:782`.
- `branches` lines are cut at `#` with no trim (`:731`), and `URL:` lines are trimmed on the left only (`:734`).
- `_snap_remote` strips `file://` and treats `host/…` as a relative path (`:370`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:365-388`, `devcontainer-config/cc-exit-scan.sh:510-515`, `devcontainer-config/cc-exit-scan.sh:717-737`, `devcontainer-config/cc-exit-scan.sh:782`

---

## Claim 23: "Same character count and joined bytes, split differently: one key per rule."

**Location:** `test/cc-isolated-functions.bats:2264`
**Type:** Behavioral
**Legibility-target:** for-orchestrator-synthesis
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test's two rules having the same character-counted key prefix (6) and the same joined bytes under C.utf8, with distinct byte-counted keys; does not establish other collision shapes beyond R1's split enumeration.

R1 gives `k1=6:sub/aéc` and `k2=7:sub/aéc`, distinct, where a character count would give 6 for both. R4 replays the test: e4b29291's scan prints `rc=0 MISSED` and 013f1b3d's prints `rc=1 FOUND`.

**Evidence:** `test/cc-isolated-functions.bats:2261-2275`, `$P/logs/p1-key.log`, `$P/logs/p4-utf8.log`

---

## Claim 24: Test name "exit scan Q-096: past either insteadOf cap, the exit scan fails as unsafe"

**Location:** `test/cc-isolated-functions.bats:2277`
**Type:** Staleness
**Legibility-target:** for-author
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the test name only; the test body passes (R6 test 13).

4d7f966c added a third cap to the body without renaming the test:

```bash
# test/cc-isolated-functions.bats:2293-2297
  GIT_EXIT_SCAN_MAX_REWRITE_TARGETS=2000 GIT_EXIT_SCAN_MAX_REWRITE_BYTES=10
  run git_exit_scan "$SCAN_WS" "$before"
  [ "$status" -eq 2 ]
  [[ "$output" == *"a remote URL or insteadOf rule over 10 bytes: too long to compare"* ]]
}
```

So "either" (two) no longer matches the three caps tested. "Past any insteadOf cap" would be accurate.

**Evidence:** `test/cc-isolated-functions.bats:2277-2297`

---

## Claim 25: "Tests: a UTF-8 key collision (fails on e4b29291's scan), the length cap"

**Location:** commit 4d7f966c message
**Type:** Reference / Behavioral
**Legibility-target:** for-orchestrator-synthesis
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the collision test failing on e4b29291's scan and passing on 013f1b3d's, and the length-cap assertion being present; does not establish the commit's measured timings (the "~20 min" and "297 MB" figures were not rerun).

R4: `old/cc-exit-scan.sh` (e4b29291) gives `rc=0 MISSED`, and the worktree scan gives `rc=1 FOUND`. The length-cap assertion is quoted in Claim 24.

**Evidence:** `test/cc-isolated-functions.bats:2261-2275`, `test/cc-isolated-functions.bats:2293-2296`, `$P/logs/p4-utf8.log`

---

## Claim 26: "the 2,000 cap counts URL-and-working-tree targets"

**Location:** commit 4d7f966c message
**Type:** Configuration
**Legibility-target:** for-author
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claim 19b.

The same commit moved `_snap_rwt=$((_snap_rwt + 1))` ahead of the `t:` dedupe check (`devcontainer-config/cc-exit-scan.sh:465-467`, quoted in Claim 19b), so the cap counts matching pairs, not distinct (URL, working tree) targets. R3 case B2 shows one distinct target tripping a cap of 1.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:449`, `devcontainer-config/cc-exit-scan.sh:465-467`, `$P/logs/p3-batch.log`

---

## Claim 27: "_snap_match now checks the target cap per hit; the walk and dedupe of hits moved into _snap_walk_hits. The cap checker is _snap_pairs_ok, and the target-cap message carries counts."

**Location:** commit 4d7f966c message
**Type:** Architectural
**Legibility-target:** for-orchestrator-synthesis
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the function moves and the message format; does not establish what the count means (Claims 19b, 26).

The per-hit check is at `devcontainer-config/cc-exit-scan.sh:449` and the walk and dedupe at `:462-471` (both quoted above). `_snap_pairs_ok()` is at `:430`. The message `'more than %s URLs rewritten by insteadOf rules to walk (%s URLs, %s rules so far)…'` is at `:450`.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:430-471`

---

## Claim 28: "the UTF-8 read test keeps only its hook half (the legacy-URL half proved the same read path)."

**Location:** commit 013f1b3d message
**Type:** Behavioral
**Legibility-target:** for-author
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers whether the remaining hook half exercises the legacy-remotes read at `:729`. It does not establish whether `:729`'s guard needs a test in this unit or in the split unit (the reader lives in the split-out legacy-file family, but the B25 read fix stays here).

The two halves exercise different `read` sites. The hook half plants a hook named `a\xc3`, which goes through the NUL-delimited `find`-list reads (`read -r -d ''`). The removed legacy half went through the newline-delimited here-string read of a legacy file's body:

```bash
# devcontainer-config/cc-exit-scan.sh:728-729
      body="$(cat -- "$f" 2>/dev/null)" || { _snap_fail 'cannot read %s' "$f"; return 1; }
      while LC_ALL=C IFS= read -r line || [ -n "$line" ]; do
```

(The excerpt ends at `:729`. The enclosing loop continues to `:735` and `_snap_gitdir` to `:762` (read).) To test this I made a mutant with `:729` changed to bare `IFS= read` and nothing else (`diff` shows one line).
- R9: the removed legacy half reports MISSED on the mutant and FOUND on the real scan. The kept hook half reports FOUND on both.
- R10: all 86 `exit scan` bats tests pass against the mutant (`1..86`, 86 ok, exit 0).

So no remaining test guards `:729`. The legacy-URL half was the only test that guarded it.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:721-736`, `test/cc-isolated-functions.bats:2240-2250`, `$P/logs/p6-p7.log`, `$P/logs/bats-mut729.log`

---

## Claim 29: "Unit size after this commit: 400 changed lines outside docs/."

**Location:** commit 013f1b3d message
**Type:** Configuration
**Legibility-target:** for-orchestrator-synthesis
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `git diff --numstat main..013f1b3d -- . ':!docs'`; does not establish that guides/ belongs inside the decision-log row 62 counting rule (it is counted here, as the commit does).

The numstat output was `cc-exit-scan.sh 156/34`, `guides/cc-isolated-usage.md 27/10` and `test/cc-isolated-functions.bats 173/0`, for a total of 400 (356 added, 44 deleted). Command run in the worktree at 2026-10-15T08:21Z, exit 0. The output is inline here because it is three lines (paraphrased — no quote available because this is command output, not source).

**Evidence:** `devcontainer-config/cc-exit-scan.sh`, `guides/cc-isolated-usage.md`, `test/cc-isolated-functions.bats`

---

## Claim 30: "bats test/cc-isolated-functions.bats: 195/195."

**Location:** commit 013f1b3d message
**Type:** Reference
**Legibility-target:** for-orchestrator-synthesis
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the container (git 2.39.5, bash 5.2, LC_ALL=C); does not establish the host (the commit's own `Host-tool-tested: no` says so).

R7 printed `1..195` and 195 lines starting with `ok`, with no `not ok`, and exited 0 (2026-10-15T08:26:03Z to 08:26:52Z).

**Evidence:** `test/cc-isolated-functions.bats`, `$P/logs/bats-full.log`

---

## Claims Requiring Attention

### Incorrect
- **Claim 19b** (`guides/cc-isolated-usage.md:349-350`): "(one per URL and working tree)" is wrong. The 2,000 cap counts every matching URL-and-rule pair, duplicates included (`_snap_rwt` increments before the `t:` dedupe at `cc-exit-scan.sh:465-467`). Reword it, or move the increment after the dedupe and count distinct targets in `_snap_match`'s check. This fails closed, so there is no security impact.
- **Claim 26** (commit 4d7f966c message): "the 2,000 cap counts URL-and-working-tree targets". Same mismatch as 19b.
- **Claim 28** (commit 013f1b3d message): "the legacy-URL half proved the same read path" is wrong. It guarded a different read (`cc-exit-scan.sh:729`), and after its removal a mutant without `LC_ALL=C` at `:729` passes all 86 exit-scan tests. Restore the half (it costs 9 lines against the 400-line cap) or move it to the split unit.

### Stale
- **Claim 11** (`devcontainer-config/cc-exit-scan.sh:518`): names the removed `_snap_rewrite`. It should be `_snap_match`/`_snap_walk_hits`.
- **Claim 12b** (`devcontainer-config/cc-exit-scan.sh:831`): names the removed `_snap_rewrite`. Same fix.
- **Claim 24** (`test/cc-isolated-functions.bats:2277`): the test is named "past either insteadOf cap" but now tests three caps.

### Mostly Accurate
- **Claim 21** (`guides/cc-isolated-usage.md:418-419`): "about 30 s" measured at about 9 s when the targets are absent and about 77 s when each is a bare repo (about 39 ms each, in line with the guide's 29 ms per embedded repo). Say "about 10 s, or about a minute when the targets are git dirs".

### Unverifiable
- None.

---

## Goal-Alignment Note

- Success criterion (restated verbatim): A markdown report saved to /workspace/.claude/wt-q096/docs/reviews/q096-exit-scan-insteadof-target-p3-code-fact-check-report.md, structured per the code-fact-check skill, first line `Commit: 013f1b3d`, header field `**Replication:** k=1 (loop pass, decision 031)`.
- Answered: yes. All five brief claims are verdicted, and claims 1–3 are verified by execution where they could be run.
  - Brief claim 1 (keys and the 4,096 cap) is verified (Claim 6). Keys count bytes and are injective in C and C.utf8. The cap is checked in bytes, and it fails closed at snapshot (1), at git_exit_scan (2) and at launch (exit 1, read from the code). 4,096 is safe for any realistic URL and equals PATH_MAX for a path base. An over-cap URL in your own config would refuse every launch, which is fail-closed.
  - Brief claim 2 is verified (Claims 9, 10, 12a, 13). The batch is bounded by the per-hit check. The `&&`/`||` chain fails closed on either failure. Each pair is compared exactly once (instrumented: rwn=6=U×R with queues growing mid-loop). One caveat is that the target cap counts pairs, not distinct targets (19b/26).
  - Brief claim 3 is verified (Claim 14). The `_snap_rnames` writes are byte-identical to main.
  - Brief claim 4 holds mostly. The caps sentence's parenthetical is wrong (19b). "A slow scan" understates the planted-repo case (21). Two comments name the removed `_snap_rewrite` (11, 12b). The known-route bullet is accurate (22). "Unit size ... 400" checks out (29).
  - Brief claim 5: no bypass found in the insteadOf pass (Claim 20). The residue is a `remote.pushDefault`/`branch.*.pushRemote` URL set in *your own* config, which is not queued. It is pre-existing, outside this diff and unusual.
- Out of scope: 5f754994 and e4b29291's own text, the stacked branch fix/q096b-exit-scan-remote-names, the 4d7f966c timing and memory figures (not rerun), and host bash or git versions. remote.c was not readable offline (Claim 22's git side).
- Escalate: none blocking. No exit-scan bypass was found. The one coverage regression is Claim 28: the B25 read fix at `:729` has lost its only test, so a future edit could silently reopen the iteration-1 UTF-8 read bypass for legacy remotes files. That one is for the author.
