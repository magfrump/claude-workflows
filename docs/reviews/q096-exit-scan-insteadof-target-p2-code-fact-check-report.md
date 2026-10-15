Commit: e4b29291

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-q096 (branch fix/q096-exit-scan-insteadof-target)
**Scope:** iteration-2 partial scope `git diff 5f754994..e4b29291 -- . ':!docs/reviews'`: devcontainer-config/cc-exit-scan.sh, docs/working/plan-q096-exit-scan-insteadof-target.md, guides/cc-isolated-usage.md, test/cc-isolated-functions.bats, plus the e4b29291 commit message. Unchanged text that the diff made true or false is in scope too (Claims 3 and 21). 5f754994 is context only.
**Checked:** 2026-10-15
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 29
**Summary:** 16 verified, 5 mostly accurate, 2 stale, 6 incorrect, 0 unverifiable

I read the hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) before checking. Its entries are count and denominator claims plus one consumer reference. The one count claim here, "195/195" (Claim 26), was checked against that pattern by running the suite. It holds. None of the Incorrect verdicts below is a fabricated symbol or API. Claim 9b is a false claim about how bash behaves, which may count as a log candidate: see the Goal-Alignment Note.

**Execution environment.** git 2.39.5, bash 5.2.15, bats, locales C and C.utf8. Probe scripts and captured output are in `/home/node/.claude/jobs/00bcf178/tmp/q096/probe-codefc-p2/`, called `$PC` below. Every probe ran with `GIT_CONFIG_GLOBAL=$PC/global.gitconfig` and `GIT_CONFIG_NOSYSTEM=1`. Each one sources `devcontainer-config/cc-isolated.sh` from the worktree (the same way the bats suite does) and then runs `set +eu`. Every process ran in the foreground under `timeout` of 600 s or less and exited on its own. I started no background processes, and `ps` afterwards showed none of mine.

| Run | Command (cwd `$PC` unless noted) | Exit | Timestamp (UTC) | Output |
|---|---|---|---|---|
| R1 locale semantics | `timeout 60 bash locale.sh` | 0 | 2026-10-15T08:07:36Z | `$PC/locale.out` |
| R2 match vs cut | `timeout 60 bash match.sh` | 0 | 2026-10-15T08:07:36Z | `$PC/match.out` |
| R3 key collision | `timeout 120 bash collide.sh` | 0 | 2026-10-15T08:07:43Z | `$PC/collide.out` |
| R4 legacy files vs git | `timeout 300 bash legacy.sh` | 0 | 2026-10-15T08:05:19Z | `$PC/legacy.out` |
| R5 `[:space:]` strip | `timeout 120 bash space.sh` | 0 | 2026-10-15T08:06:13Z | `$PC/space.out` |
| R6 pair coverage | `timeout 120 bash pairs.sh` | 1 (the trailing `grep -o` summary line matched nothing; the instrumented snapshot itself logged `snapshot rc=0`) | 2026-10-15T08:07:09Z | `$PC/pairs.out`, `$PC/pairs.log`, `$PC/pairs.snap` |
| R7 full suite at HEAD | cwd worktree: `LC_ALL=C timeout 600 bats test/cc-isolated-functions.bats` | 0 | 2026-10-15T08:03:34Z | `$PC/bats-full.out` |
| R8 new tests on the pre-fix scan | cwd `$PC/prefix-tree` (copy of HEAD's `devcontainer-config/` and test file, with `cc-exit-scan.sh` = `git show 5f754994:devcontainer-config/cc-exit-scan.sh`): `LC_ALL=C timeout 600 bats -f 'own remote\|byte-wise\|does not hide the next entry\|holding tabs\|no url is pushed\|either insteadOf cap' test/cc-isolated-functions.bats` | 1 | 2026-10-15T08:04:49Z | `$PC/bats-prefix.out` |

---

## Claim 1: "every remote that is a local path inside the checkout (remote.*.url/pushurl, remote.pushDefault, branch.*.remote/pushRemote naming a path, ...)"

**Location:** `devcontainer-config/cc-exit-scan.sh:57-61`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the header's list of name sources that are followed. It does not establish behaviour for names that come from the command line.
**Legibility-target:** for-author

Since e4b29291, a `remote.pushDefault` / `branch.*.remote` / `branch.*.pushRemote` value is also queued as a URL when it names a remote that has no `url` or `vcs`. This is not limited to values that are paths:

```bash
# devcontainer-config/cc-exit-scan.sh:840
      [ -z "$f" ] || [ -n "${_snap_rnames["$f"]:-}" ] || _snap_url "$f" "$g" || rc=1
```

```bash
# devcontainer-config/cc-exit-scan.sh:509
        case "$key" in remote.*.url|remote.*.vcs) [ -z "$name" ] || _snap_rnames["$name"]=1 ;; esac
```

The guide was updated with this case ("naming a path or a remote with no `url`", `guides/cc-isolated-usage.md:320`). The header still says only "naming a path". The commit says "Header ... updated", but this sentence was not. The precise form is: "naming a path, or a remote with no url/vcs (git pushes to the name)".

**Evidence:** `devcontainer-config/cc-exit-scan.sh:57-61`, `devcontainer-config/cc-exit-scan.sh:505-512`, `devcontainer-config/cc-exit-scan.sh:836-840`, `guides/cc-isolated-usage.md:319-321`

---

## Claim 2: "Each of those URLs, and every remote.*.url/pushurl in your own config, is also rewritten by every url.<base>.insteadOf / pushInsteadOf rule whose value prefixes it ... and the result walked the same way."

**Location:** `devcontainer-config/cc-exit-scan.sh:61-65`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers your own `remote.*.url`/`pushurl` being queued into the URL × rule worklist, and the rewritten targets being walked, including against rules found only inside a walked target. It does not establish walking under a non-C locale, where some rules can be dropped (Claim 6b).

e4b29291 adds the host-config queueing:

```bash
# devcontainer-config/cc-exit-scan.sh:613-616
    case "$key" in
      url.*.insteadof|url.*.pushinsteadof) t="${key#url.}"; _snap_rule "${t%.*}" "$val" ;;
      remote.*.url|remote.*.pushurl) _snap_url "$val" "$wt" || return 1 ;;
    esac
```

This runs before the `[ -n "$val" ] || continue` at `:617`, so an empty value is queued too. In R6, a global `remote.mine.url https://mine.invalid/x` was rewritten by a `pushInsteadOf` rule that exists only in the config of a walked rewrite target (`t1-repo`). The snapshot then holds `remote $P/pairs-ws/t3-x missing` (`$PC/pairs.out`). The new bats test "YOUR own remote ... is walked" passes at HEAD (R7) and fails on the pre-fix scan (R8, at `rewrite_plant`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:597-639`, `$PC/pairs.out`, `$PC/bats-full.out`, `$PC/bats-prefix.out`, `test/cc-isolated-functions.bats:2216-2222`

---

## Claim 3: "Only those three kinds of entry are followed in your own config; its other entries are not recorded"

**Location:** `devcontainer-config/cc-exit-scan.sh:71-72`
**Type:** Behavioral / Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers which keys `_snap_host_config` acts on. It does not establish whether those entries are recorded as C records (they are not, which matches the second half of the sentence).

`_snap_host_config` now acts on five kinds of key in your own config. Two are the insteadOf rules (5f754994) and your remote URLs (e4b29291). The other three are the ones the header counts: `core.hookspath`, `core.attributesfile`, and the include keys.

```bash
# devcontainer-config/cc-exit-scan.sh:613-626 (excerpt ends :626; enclosing _snap_host_config continues to :639 — read)
    case "$key" in
      url.*.insteadof|url.*.pushinsteadof) t="${key#url.}"; _snap_rule "${t%.*}" "$val" ;;
      remote.*.url|remote.*.pushurl) _snap_url "$val" "$wt" || return 1 ;;
    esac
    [ -n "$val" ] || continue
    origin="${origin#file:}"
    case "$key" in
      core.hookspath)
      ...
      core.attributesfile)
      ...
      include.path|includeif.*.path)
```

A queued own-config remote URL is also walked directly. `_snap_url` calls `_snap_remote` (`:399`), and that can emit a W record that refuses the worktree note. The sentence should name all five kinds.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:66-72`, `devcontainer-config/cc-exit-scan.sh:392-400`, `devcontainer-config/cc-exit-scan.sh:597-639`

---

## Claim 4: "... or too many insteadOf comparisons or rewritten URLs (_snap_pairs, _snap_rewrite) makes the snapshot fail: at launch the launcher refuses to start, at exit it returns 4."

**Location:** `devcontainer-config/cc-exit-scan.sh:95-99`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the failure path from both caps up through `git_exec_snapshot` (1), `git_exit_scan` (2) and the launcher (4 at exit, 1 at launch). It does not establish anything about the wording of the launch-time message.

Both caps return 1 through `_snap_fail`. The worklist sets `rc=1` and `git_exec_snapshot` then returns 1 (`:843`, `:846`, `:860`). `git_exit_scan` turns a failed snapshot into `return 2` (`:1109-1122`). The launcher maps that status:

```bash
# devcontainer-config/cc-isolated.sh:933-938
  case "$scan" in
    0) exit "$rc" ;;
    1) exit 3 ;;   # the session planted something: never a clean exit
    *) exit 4 ;;   # the scan could not read .git
  esac
```

At launch, `if ! git_before="$(git_exec_snapshot ...)"; then ... exit 1` (`devcontainer-config/cc-isolated.sh:859-867`). The bats cap test passes at HEAD and asserts `[ "$status" -eq 2 ]` from `git_exit_scan` for each cap (R7).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:418-466`, `devcontainer-config/cc-exit-scan.sh:835-861`, `devcontainer-config/cc-exit-scan.sh:1106-1123`, `devcontainer-config/cc-isolated.sh:859-867`, `devcontainer-config/cc-isolated.sh:929-938`, `$PC/bats-full.out`

---

## Claim 5: "EVERY `read` RUNS UNDER LC_ALL=C. In a UTF-8 locale bash's read swallows a delimiter (NUL or newline) that follows an incomplete multibyte character, so a file or value ending in such a byte would merge with the next entry"

**Location:** `devcontainer-config/cc-exit-scan.sh:122-125` (the same claim is in the commit message: "Every read in cc-exit-scan.sh now runs as LC_ALL=C IFS= read")
**Type:** Invariant / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every `read` builtin in `cc-exit-scan.sh`, the swallowed-delimiter mechanism on bash 5.2.15, and the restoration of the caller's locale after a `LC_ALL=C read` prefix. It does not establish that other locale-sensitive operations in the file are safe (they are not: Claims 6b and 14), and it does not cover `cc-gitdir.sh`'s two whole-file reads, which the commit notes are out of scope.

A grep for `read`/`mapfile`/`readarray` that excludes `LC_ALL=C IFS= read` returns nothing (paraphrased — no quote available because the claim covers the absence of code: the grep returned no matching lines). There are 13 read sites, `:232`, `:335`, `:482`, `:607` (two reads), `:684`, `:719`, `:728`, `:743`, `:751`, `:821` and `:999`, and all of them carry the prefix, for example:

```bash
# devcontainer-config/cc-exit-scan.sh:607
  while LC_ALL=C IFS= read -r -d '' origin && LC_ALL=C IFS= read -r -d '' rec; do
```

R1 under `LC_ALL=C.utf8`, with the input `a\xc3\0b\0`: a plain `read -d ''` gives `utf8 entries=1`, and the `LC_ALL=C` prefix gives `C entries=2`. Newline-delimited input behaves the same way (`utf8 newline entries=1` vs `C newline entries=2`). After the prefixed read, `${#s}` for `aé` is still 2 and `LC_ALL=C.utf8` (`$PC/locale.out`), so the caller's locale is restored. The new bats test "a name ending mid-character does not hide the next entry" passes at HEAD and fails on the pre-fix scan (R7, R8).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:122-125`, `devcontainer-config/cc-exit-scan.sh:232`, `devcontainer-config/cc-exit-scan.sh:607`, `devcontainer-config/cc-exit-scan.sh:728`, `$PC/locale.out`, `$PC/bats-prefix.out`

---

## Claim 6a: "Length-prefixed keys: a tab-joined key would let a URL or base holding a tab collide with another pair and be dropped." (u: and t: keys)

**Location:** `devcontainer-config/cc-exit-scan.sh:393-395`, `devcontainer-config/cc-exit-scan.sh:456`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers collision-freedom of `u:${#1}:$1$2` and `t:${#1}:$1$2` when `$2` (the working tree) is an absolute path, which every caller passes. This holds in C and in UTF-8 locales. It does not establish anything for the `r:` key (Claim 6b), and it does not cover a hypothetical caller that passes a relative or empty working tree.

```bash
# devcontainer-config/cc-exit-scan.sh:395
  local k="u:${#1}:$1$2"
```

For two pairs to collide, one URL must be a byte prefix of the other, and the remainder X must begin the first pair's working tree. Every working tree passed here starts with `/`: it comes from `_snap_worktree_of` (`cd … && pwd -P` or an absolute config path), `$_snap_ws`, or `${f%/*}` of an absolute `find` path (paraphrased — no quote available because the claim is an invariant inferred from the call sites at `:473`, `:511`, `:615`, `:731`, `:734`, `:827` and `:840`). So X starts with `/`. `/` is an ASCII byte that never continues a multibyte sequence. Adding X therefore adds at least one character in any locale, and the two `${#1}` values cannot be equal. The bats test "rules and URLs holding tabs are not merged" passes at HEAD and fails pre-fix (R7, R8).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:392-400`, `devcontainer-config/cc-exit-scan.sh:455-466`, `devcontainer-config/cc-exit-scan.sh:342-354`, `$PC/bats-prefix.out`

---

## Claim 6b: Length-prefixed keys are collision-free (the `r:` rule key; the commit message says "Tab-joined dedupe keys let a pair holding a tab collide with another and be dropped; keys are now length-prefixed")

**Location:** `devcontainer-config/cc-exit-scan.sh:405`
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `r:${#1}:$1$2` rule key when the scan runs in a UTF-8 locale (the launcher runs it in your own locale; `cc-isolated.sh` sets no `LC_ALL`). It does not establish a collision in the C locale, where none is possible.

```bash
# devcontainer-config/cc-exit-scan.sh:404-409
_snap_rule() {
  local k="r:${#1}:$1$2"
  [ -z "${_snap_rwseen["$k"]:-}" ] || return 0
  _snap_rwseen["$k"]=1
  _snap_rbases+=("$1"); _snap_rpfx+=("$2")
}
```

`${#1}` counts characters in the caller's locale. The rule base and the rule value are both container-chosen, and the value is not anchored by a `/`. Bash counts each invalid byte as one character (R2: `${#p}` of `\xe2\x82` is 2), and a completed `€` counts as one. So `b1 = W/e\xe2\x82` (k+2 characters) and `b2 = W/e€c` (k+2 characters) have equal lengths. With `v1 = \xacc` + V and `v2 = V`, the bytes `b1 v1` equal `b2 v2` and the keys are identical. The second rule is silently never queued.

In R3, the repo has remote `o = https://o.invalid/repo`, `url.<b1>.insteadOf = \xacchttps://o.invalid/`, and `url.<b2>.insteadOf = https://o.invalid/`. git resolves the push URL to `<W>/e€crepo` (`[C.utf8] ... /e\342\202\254crepo`). A pre-receive hook was planted there after the launch snapshot. Results:

```
[C] git_exit_scan rc=1 (1 = planted hook reported)
[C.utf8] git_exit_scan rc=0 (1 = planted hook reported)
```

Under `C.utf8` the exit scan reports a clean checkout while a push runs the planted hook. The tab collision is fixed, but the dedupe key is still not collision-free. To fix it, compute the length under `LC_ALL=C` (or prefix both components).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:402-409`, `devcontainer-config/cc-exit-scan.sh:513-519`, `devcontainer-config/cc-exit-scan.sh:614`, `$PC/collide.sh`, `$PC/collide.out`, `$PC/match.out`

---

## Claim 7: "distinct rewritten URLs walked" / "GIT_EXIT_SCAN_MAX_REWRITE_TARGETS (2,000 distinct rewritten URLs)" / "The 2,000-target cap counts every distinct rewritten URL, local or not."

**Location:** `devcontainer-config/cc-exit-scan.sh:411-416` (also `guides/cc-isolated-usage.md:350`, plan B14 at `docs/working/plan-q096-exit-scan-insteadof-target.md:27`, and the commit message)
**Type:** Configuration / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what `_snap_rwt` counts. It does not establish the cost of each walk.

The counter is charged once for each distinct (rewritten URL, working tree) pair, not once for each distinct URL. The dedupe key includes the working tree, and the counter increments before `_snap_remote` whether or not the URL is local:

```bash
# devcontainer-config/cc-exit-scan.sh:455-466
_snap_rewrite() {
  local t="$1" k="t:${#1}:$1$2"
  [ -z "${_snap_rwseen["$k"]:-}" ] || return 0
  _snap_rwseen["$k"]=1
  _snap_rwt=$((_snap_rwt + 1))
  if [ "$_snap_rwt" -gt "$GIT_EXIT_SCAN_MAX_REWRITE_TARGETS" ]; then
    ...
    return 1
  fi
  _snap_remote "$t" "$2"
}
```

"Local or not" is right. "Distinct rewritten URL" should say "distinct rewritten URL per working tree": the same target reached from two embedded repos counts twice. The cap value and its fail-closed behaviour are as stated.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:411-416`, `devcontainer-config/cc-exit-scan.sh:455-466`, `guides/cc-isolated-usage.md:349-351`

---

## Claim 8: "URL-and-rule pairs compared, checked before each batch (_snap_pairs)"; "_snap_pairs <n>: count <n> more comparisons against the pair cap."

**Location:** `devcontainer-config/cc-exit-scan.sh:411-424`
**Type:** Configuration / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the charge-before-work order, the 100,000 value, the message text and the fail path. It does not establish the wall-clock cost of 100,000 comparisons (a performance concern).

```bash
# devcontainer-config/cc-exit-scan.sh:419-424
_snap_pairs() {
  _snap_rwn=$((_snap_rwn + $1))
  [ "$_snap_rwn" -gt "$GIT_EXIT_SCAN_MAX_REWRITE_PAIRS" ] || return 0
  _snap_fail 'more than %s remote URL and insteadOf rule pairs to compare (%s URLs, %s rules so far): too many, treat the checkout as unsafe' \
    "$GIT_EXIT_SCAN_MAX_REWRITE_PAIRS" "${#_snap_urls[@]}" "${#_snap_rbases[@]}"
}
```

Both batch branches call it before `_snap_match`: `_snap_pairs "$r" || { rc=1; break; }` (`:843`) and `_snap_pairs "$u" || { rc=1; break; }` (`:850`). The bats test asserts the message `(1 URLs, 2 rules so far)` and status 2, and it passes (R7).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:418-424`, `devcontainer-config/cc-exit-scan.sh:841-854`, `test/cc-isolated-functions.bats:2287-2299`, `$PC/bats-full.out`

---

## Claim 9a: "so the match and the cut run under LC_ALL=C" (`local LC_ALL=C` in `_snap_match`)

**Location:** `devcontainer-config/cc-exit-scan.sh:430-434`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers byte semantics inside `_snap_match` for the `[[ == "$p"* ]]` test, `${#p}` and `${u:n}`, and restoration of the caller's locale on return (bash 5.2.15). It does not establish byte semantics for operations outside `_snap_match` (Claims 6b and 14).

```bash
# devcontainer-config/cc-exit-scan.sh:433-442
_snap_match() {
  local LC_ALL=C ui="$1" ri="$2" n="$3" k u p
  for ((k = 0; k < n; k++)); do
    u="${_snap_urls[ui]}"; p="${_snap_rpfx[ri]}"
    if [[ "$u" == "$p"* ]]; then
      _snap_hit_t+=("${_snap_rbases[ri]}${u:${#p}}"); _snap_hit_b+=("${_snap_ubases[ui]}")
    fi
    if [ "$4" = 0 ]; then ri=$((ri + 1)); else ui=$((ui + 1)); fi
  done
}
```

R1: inside a function with `local LC_ALL=C`, `${#s}` of `aé` is 3. After the function returns it is 2 again, and `LC_ALL=C.utf8` is back. R2: under C, the cut of `\xc3\xa9vil` by the prefix `\xc3` is `\251vil`. The bats byte-wise test passes at HEAD and fails pre-fix (R7, R8).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:426-442`, `$PC/locale.out`, `$PC/match.out`, `$PC/bats-prefix.out`

---

## Claim 9b: "in a UTF-8 locale bash would compare characters, and a value ending mid-character would never match."

**Location:** `devcontainer-config/cc-exit-scan.sh:431-432`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bash 5.2.15's `[[ "$u" == "$p"* ]]` and `${u:${#p}}` under `C.utf8` for values that end mid-character. It does not establish behaviour on other bash versions, such as a host's bash.

On bash 5.2.15, a value that ends mid-character does match. The step that goes wrong is the cut. R2 output:

```
utf8 match: yes
utf8 cut: vil
C cut: $'\251vil'
p=$'\342\202' u=€zz utf8 match=yes cut=z
```

With the old character-wise code, the match succeeds. `${#p}` then counts the dangling byte as one character, and `${u:1}` removes the whole `é`. The scan therefore walks `x-vil` instead of git's `x-\xa9vil`, and in the `€` case it drops a following byte as well. The fix (`local LC_ALL=C`) is correct. The stated failure mechanism ("would never match") is not, and a reader who relies on it would look for a missing match instead of a wrong target. The comment should say: in a UTF-8 locale `${#p}` and `${u:n}` count characters, so the rewritten URL is cut at the wrong place.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:426-438`, `$PC/match.sh`, `$PC/match.out`

---

## Claim 10: "Walking can queue more URLs and rules, never more hits." / "a new URL meets the rules already seen, a new rule meets the URLs already seen, so each pair meets once."

**Location:** `devcontainer-config/cc-exit-scan.sh:444-451`, `devcontainer-config/cc-exit-scan.sh:830-858`
**Type:** Invariant / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers exactly-once comparison of every (URL, rule) pair, including URLs and rules first found inside walked targets and your own remotes. It also covers stability of the hit lists and fail-closed `rc` propagation from `_snap_pairs`, `_snap_walk_hits` and `_snap_url`. It does not establish correctness of the comparison itself under non-C locales beyond `_snap_match` (Claim 6b: a dropped rule never enters the worklist).

```bash
# devcontainer-config/cc-exit-scan.sh:841-854 (excerpt ends :854; enclosing while loop continues to :858 and git_exec_snapshot to :862 — read)
    elif [ "$u" -lt "${#_snap_urls[@]}" ]; then
      # URL u against rules 0..r-1.
      _snap_pairs "$r" || { rc=1; break; }
      _snap_hit_t=() _snap_hit_b=()
      _snap_match "$u" 0 "$r" 0
      _snap_walk_hits || rc=1
      u=$((u + 1))
    elif [ "$r" -lt "${#_snap_rbases[@]}" ]; then
      # Rule r against URLs 0..u-1.
      _snap_pairs "$u" || { rc=1; break; }
      _snap_hit_t=() _snap_hit_b=()
      _snap_match 0 "$r" "$u" 1
      _snap_walk_hits || rc=1
```

`_snap_match` is called only from these two lines. Walking only appends to `_snap_urls`/`_snap_rbases`, so the existing indexes and the computed hits stay valid. The loop's guard `while [ "$rc" -eq 0 ]` (`:835`) ends it after `_snap_walk_hits || rc=1`, and `:860` returns 1.

R6 wrapped `_snap_match` to log every pair. The setup had 2 repo URLs, 1 own-config URL, 1 URL found in walked target `t1-repo` and 1 in `t2-z` (5 URLs). It also had 1 own rule, 1 repo rule, 2 rules in `t1-repo` and 1 in `t2-z` (5 rules). The run logged 25 distinct pairs with no duplicates, and indexes 0-4 on both axes (`$PC/pairs.log`). `t4-repo`, from a rule two walks deep applied to the first URL, appears in the snapshot.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:426-466`, `devcontainer-config/cc-exit-scan.sh:830-861`, `$PC/pairs.sh`, `$PC/pairs.out`, `$PC/pairs.log`

---

## Claim 11: "A remote git counts as defined (remote.c, valid_remote) has a url or vcs; with neither, git pushes to its NAME as a URL"

**Location:** `devcontainer-config/cc-exit-scan.sh:506-509`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers config-defined remotes (`remote.<n>.url` / `remote.<n>.vcs` mark the name defined; `pushurl` or `fetch` alone do not) and git 2.39.5 pushing to the name when the remote has no url. It does not establish (a) the remote.c source text, which is not available offline, (b) legacy files (Claims 13a/13b), or (c) the case where a pushurl-only remote's name is now also walked, which can leave a W record that refuses the worktree note.

```bash
# devcontainer-config/cc-exit-scan.sh:505-512
      remote.*.*)
        # A remote git counts as defined (remote.c, valid_remote) has a url or
        # vcs; with neither, git pushes to its NAME as a URL (worklist below).
        name="${key#remote.}"; name="${name%.*}"
        case "$key" in remote.*.url|remote.*.vcs) [ -z "$name" ] || _snap_rnames["$name"]=1 ;; esac
        case "$key" in
          remote.*.url|remote.*.pushurl) _snap_url "$val" "$base" || return 1 ;;
        esac ;;
```

The bats test "a remote with no url is pushed to by its name" sets only `remote.sub/evil.fetch` plus `branch.<b>.pushRemote sub/evil`. It passes at HEAD and fails pre-fix (R7, R8). My recollection of git 2.39's `valid_remote` (`!!remote->url || !!remote->foreign_vcs`) agrees with the code, but I did not read the source.

A side effect, paraphrased — no quote available because it follows from the walk and the note rule together: a remote with only a `pushurl` is now also walked by its name. git pushes to the pushurl in that case, so this walk is a superset of what git does. A relative name gets a W record from `_snap_wrel` (`:376`), and any W record refuses the Q-094 worktree note (`:984`). Neither the guide nor the header mentions this.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:505-512`, `devcontainer-config/cc-exit-scan.sh:365-388`, `devcontainer-config/cc-exit-scan.sh:984`, `test/cc-isolated-functions.bats:2270-2281`, `$PC/bats-prefix.out`

---

## Claim 12: "Legacy remotes: remotes/<name> ("URL: <url>" lines), branches/<name> ("<url>#<branch>"), a relative path resolved in this git dir's working tree, as git would."

**Location:** `devcontainer-config/cc-exit-scan.sh:713-714`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers how a URL is extracted from a legacy file compared with git 2.39.5, for leading and trailing ASCII whitespace. This is a pre-existing gap (not introduced by e4b29291) inside the claim-4 area. It does not establish other differences in the parser.

git trims whitespace: around the first line of a branches file, and at the end of a remotes-file line after `URL:`. The scan does neither:

```bash
# devcontainer-config/cc-exit-scan.sh:729-734
        if [ "$d" = branches ]; then
          _snap_rnames["$name"]=1
          _snap_url "${line%%#*}" "$(_snap_worktree_of "$real/config")" || return 1
          break
        fi
        case "$line" in URL:*) _snap_rnames["$name"]=1; line="${line#URL:}"; _snap_url "${line#"${line%%[![:space:]]*}"}" "$(_snap_worktree_of "$real/config")" || return 1 ;; esac
```

In R4 (C locale, `remote.pushDefault` naming the legacy remote, hook planted after launch, then `git push`), git ran the hook in both cases and the scan saw nothing:

```
[branches-lead-sp] scan rc=0 (1=reported)  git push rc=0  hook ran=yes
[remotes-trail-sp] scan rc=0 (1=reported)  git push rc=0  hook ran=yes
```

The scan walks `<wt>/  sub/evil` and `<wt>/sub/evil   `. git uses `sub/evil`.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:713-737`, `$PC/legacy.sh`, `$PC/legacy.out`

---

## Claim 13a: "The name counts as defined only once a URL is read from the file; a file with none leaves git pushing to the name itself" (remotes/ files)

**Location:** `devcontainer-config/cc-exit-scan.sh:721-722`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `remotes/<name>` files with and without `URL:` lines. It does not cover `branches/<name>` files (Claim 13b).

`_snap_rnames["$name"]=1` is set only in the `URL:*` arm (`:734`, quoted under Claim 12). In R4, a `remotes/sub/evil` file holding only `Push: refs/heads/*` gives `[remotes-nourl-branches] scan rc=1 ... hook ran=yes`: git pushed to the name, and the scan walked it. `[remotes-url-ok] scan rc=1` is the control case.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:719-736`, `$PC/legacy.out`

---

## Claim 13b: "The name counts as defined only once a URL is read from the file" (branches/ files)

**Location:** `devcontainer-config/cc-exit-scan.sh:729-731`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers an empty `branches/<name>` file, or one whose first line is empty. It does not establish behaviour for branches files that hold a URL.

The branches arm marks the name defined before it looks at the line. An empty file still produces one empty `line` from `<<< "$body"`, so the name is marked defined and `_snap_url ""` walks nothing (`_snap_remote` returns at `""`, `:368`):

```bash
# devcontainer-config/cc-exit-scan.sh:728-732 (excerpt ends :732; enclosing _snap_gitdir continues to :762 — read)
      while LC_ALL=C IFS= read -r line || [ -n "$line" ]; do
        if [ "$d" = branches ]; then
          _snap_rnames["$name"]=1
          _snap_url "${line%%#*}" "$(_snap_worktree_of "$real/config")" || return 1
          break
```

git 2.39.5 treats such a remote as having no URL and pushes to the name. R4, with an empty `branches/sub/evil` and `remote.pushDefault sub/evil`:

```
[branches-empty] scan rc=0 (1=reported)  git push rc=0  hook ran=yes
```

This is the B24 route left open for branches files. Set the name only when the trimmed line is non-empty.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:715-737`, `devcontainer-config/cc-exit-scan.sh:365-368`, `$PC/legacy.out`

---

## Claim 14: Brief claim 1, "nothing else in the file still splits, slices, or pattern-matches container bytes in a way that drops or merges entries under a UTF-8 locale"

**Location:** `devcontainer-config/cc-exit-scan.sh:734`
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers two locale-dependent operations on container bytes outside `_snap_match` and `read`: the `[:space:]` strip at `:734` and the `${#1}` rule key at `:405`. Other pattern operations probed in R1 behave the same in both locales: the `${rec%%$'\n'*}` key split with an invalid byte, and `${line%%#*}`. It does not establish that no third such operation exists.

The legacy remotes-file strip `${line#"${line%%[![:space:]]*}"}` (`:734`, quoted under Claim 12) runs in the caller's locale. In UTF-8, `[:space:]` matches U+3000 and other non-ASCII spaces. git skips ASCII spaces only. R1: `utf8 strip: sub/evil` vs `C strip: $'\343\200\200sub/evil'`. End to end, in R5, with `URL:<U+3000>evil` and a hook planted in `<wt>/<U+3000>evil` after launch:

```
[C] scan rc=1 (1=reported)  git push rc=0  hook ran=yes
[C.utf8] scan rc=0 (1=reported)  git push rc=0  hook ran=yes
```

Claim 6b's collision is the second instance. Both bypasses depend on the locale the launcher inherits.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:405`, `devcontainer-config/cc-exit-scan.sh:734`, `$PC/space.sh`, `$PC/space.out`, `$PC/locale.out`, `$PC/collide.out`

---

## Claim 15: Plan B14, "`GIT_EXIT_SCAN_MAX_REWRITE_PAIRS` (100,000 comparisons, checked before each batch) and `GIT_EXIT_SCAN_MAX_REWRITE_TARGETS` (2,000 distinct rewritten URLs); over either the snapshot fails closed (exit 4 at exit, exit 1 at launch)"

**Location:** `docs/working/plan-q096-exit-scan-insteadof-target.md:27`
**Type:** Configuration / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the values, the batch-time check and the exit statuses. The "distinct" qualifier is handled in Claim 7.

`GIT_EXIT_SCAN_MAX_REWRITE_PAIRS=100000` and `GIT_EXIT_SCAN_MAX_REWRITE_TARGETS=2000` are at `devcontainer-config/cc-exit-scan.sh:415-416`. The exit statuses are traced in Claim 4, and the bats cap test passes (R7).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:415-416`, `devcontainer-config/cc-isolated.sh:859-867`, `devcontainer-config/cc-isolated.sh:933-938`, `$PC/bats-full.out`

---

## Claim 16: Plan B22, "A rule value ending mid-UTF-8-character: git compares bytes, bash in a UTF-8 locale compares characters ... covered ... `_snap_match` matches and cuts under `local LC_ALL=C`"

**Location:** `docs/working/plan-q096-exit-scan-insteadof-target.md:34`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the B22 row's description of the failure and of the fix. It does not cover other locale-dependent sites (Claim 14).

The fix and "covered" hold (Claim 9a). The failure was the character-counted cut, not the comparison: in R2 the prefix test matched under UTF-8 and `${u:${#p}}` sliced at the wrong place. The row should name the cut as the failure.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:433-442`, `$PC/match.out`

---

## Claim 17: Plan B24, "a name counts as defined only with `url`/`vcs`, or once a legacy file yields a URL" — covered (iteration 1)

**Location:** `docs/working/plan-q096-exit-scan-insteadof-target.md:36`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the "covered" status for the legacy-file half. The config half holds (Claim 11).

An empty `branches/<name>` file marks the name defined without producing a URL. git pushes to the name, and the scan reports a clean checkout (Claim 13b, R4 `[branches-empty] scan rc=0 ... hook ran=yes`). For branches files, B24 is not covered.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:729-731`, `$PC/legacy.out`

---

## Claim 18: Plan B25, "every `read` in `cc-exit-scan.sh` runs as `LC_ALL=C IFS= read`"

**Location:** `docs/working/plan-q096-exit-scan-insteadof-target.md:37`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every `read` builtin in the file. It does not cover non-read locale sites (Claim 14).

This is the same check as Claim 5: the grep found no unprefixed `read`, and the R1 mechanism test passed.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:232`, `devcontainer-config/cc-exit-scan.sh:999`, `$PC/locale.out`

---

## Claim 19: Plan B21, "`_snap_host_config` queues your `remote.*.url`/`pushurl` with `_snap_url`"

**Location:** `docs/working/plan-q096-exit-scan-insteadof-target.md:38`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the queueing and its effect on the worklist. It does not cover own-config remote names used as `branch.*.remote` values, because `_snap_rnames` is not set from host config. That is pre-existing.

`remote.*.url|remote.*.pushurl) _snap_url "$val" "$wt" || return 1 ;;` (`devcontainer-config/cc-exit-scan.sh:615`). R6 shows the own remote rewritten and walked (Claim 2).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:613-616`, `$PC/pairs.out`

---

## Claim 20: "`branch.*.remote`/`pushRemote` naming a path or a remote with no `url`, which git pushes to by name"

**Location:** `guides/cc-isolated-usage.md:319-321`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which unnamed or url-less remotes the guide says are followed. It does not establish anything about command-line names.

The code applies this to `remote.pushDefault` as well, and "no `url`" means no `url` and no `vcs` (`devcontainer-config/cc-exit-scan.sh:509`, `:500-504`). One remote with no url is still not followed: one whose only source is an empty `branches/<name>` file (Claim 13b, R4). Precise form: "`remote.pushDefault` or `branch.*.remote`/`pushRemote` naming a path or a remote with no `url`/`vcs` (an empty `branches/` file excepted)". The better fix is the code change from Claim 13b.

**Evidence:** `guides/cc-isolated-usage.md:319-321`, `devcontainer-config/cc-exit-scan.sh:500-512`, `$PC/legacy.out`

---

## Claim 21: "Those are the only entries of your own config it follows; the rest is not recorded."

**Location:** `guides/cc-isolated-usage.md:333-334`
**Type:** Behavioral / Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the "only entries ... it follows" half. "Not recorded" still holds.

This is the guide counterpart of Claim 3. Your own `url.*.insteadOf`/`pushInsteadOf` rules and `remote.*.url`/`pushurl` are now also followed (`devcontainer-config/cc-exit-scan.sh:613-616`). The same paragraph says so a few lines earlier (`guides/cc-isolated-usage.md:322-326`), so the sentence now contradicts the text above it.

**Evidence:** `guides/cc-isolated-usage.md:322-335`, `devcontainer-config/cc-exit-scan.sh:613-616`

---

## Claim 22: "... and so do more than 100,000 URL-and-rule comparisons or more than 2,000 distinct rewritten URLs to walk. (At launch any of these refuses the launch instead, exit 1.)" with "(4 when it cannot read something; it refuses to launch, exit 1, ...)"

**Location:** `guides/cc-isolated-usage.md:349-351`
**Type:** Configuration / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the thresholds and the exit statuses 4 and 1. The per-working-tree counting qualifier is Claim 7.

This is traced in Claim 4: `*) exit 4 ;;` at `devcontainer-config/cc-isolated.sh:937` and `exit 1` at `:867`. The bats cap test passes (R7).

**Evidence:** `guides/cc-isolated-usage.md:304-307`, `guides/cc-isolated-usage.md:345-351`, `devcontainer-config/cc-isolated.sh:859-867`, `devcontainer-config/cc-isolated.sh:933-938`

---

## Claim 23: "a `~` in a local remote URL (or one an `insteadOf` rule rewrites to) are taken as relative paths"; "A URL you type ... the scan only sees URLs in config and legacy remotes files."

**Location:** `guides/cc-isolated-usage.md:443-450`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers `_snap_remote`'s treatment of a rewritten `~...` target and the absence of any command-line URL source. It does not establish how git expands `~` (taken as given by the existing known route).

`_snap_rewrite` hands the target to `_snap_remote "$t" "$2"` (`:465`), and that function has no `~` case: `case "$p" in /*) ;; *) p="$base/$p" ;; esac` (`devcontainer-config/cc-exit-scan.sh:377`). URLs are queued only from config entries, legacy files and config-named remote names (`:511`, `:615`, `:731`, `:734`, `:840`). The scan therefore has no command-line source (paraphrased — no quote available because the claim covers absence: no other `_snap_url` caller exists). "Legacy remotes files" leaves out `branches/` files, a trivial omission.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:365-388`, `devcontainer-config/cc-exit-scan.sh:455-466`, `guides/cc-isolated-usage.md:443-450`

---

## Claim 24: Commit e4b29291, "Matching was character-wise under a UTF-8 locale; git's is byte-wise. _snap_match matches and cuts under local LC_ALL=C."

**Location:** commit e4b29291 message (bullet 3)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the description of the iteration-1 defect and of the fix. Other locale sites are Claim 14.

The fix is accurate (Claim 9a). The visible defect was the character-counted cut, not a failed match. Under `C.utf8` the old `[[ == "$p"* ]]` matched a value that ends mid-character (R2). See Claim 9b for the code comment that turns this into an incorrect mechanism.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:433-442`, `$PC/match.out`

---

## Claim 25: Commit e4b29291, "New tests: own remote, byte-wise match, UTF-8 read, tabbed keys, no-url remote, both caps; each new behaviour test fails on the pre-fix scan."

**Location:** commit e4b29291 message; `test/cc-isolated-functions.bats:2216-2299`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the six new or renamed tests run against 5f754994's `cc-exit-scan.sh`. It does not establish that each test fails for the stated reason beyond the failing assertion line. The cap test fails on the variable rename and the exit status, as a non-behaviour test would be expected to.

R8 output: `1..6`, and all six are `not ok`. The failing lines are `rewrite_plant` (own remote, tabbed keys, no-url remote), `[ "$status" -eq 1 ]` (byte-wise), the hook loop (UTF-8 read), and `[ "$status" -eq 2 ]` (caps) (`$PC/bats-prefix.out`).

**Evidence:** `test/cc-isolated-functions.bats:2216-2299`, `$PC/bats-prefix.out`

---

## Claim 26: Commit e4b29291, "bats test/cc-isolated-functions.bats: 195/195."

**Location:** commit e4b29291 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the suite at e4b29291 in this container (git 2.39.5, bash 5.2, LC_ALL=C). It does not establish a host run, which the commit's own trailer marks as not done.

R7: `1..195`, 195 `ok` lines, no `not ok`, exit 0 (`$PC/bats-full.out`). This was checked against the hallucination-log pattern for test counts, and the claim holds.

**Evidence:** `$PC/bats-full.out`

---

## Claims Requiring Attention

### Incorrect
- **Claim 6b** (`devcontainer-config/cc-exit-scan.sh:405`): the `r:${#1}:$1$2` key counts characters in the caller's locale. Under UTF-8, two rules with different bases and values collide and the second is dropped, so the exit scan returns 0 while a planted hook runs on push (R3). Compute the length under `LC_ALL=C`.
- **Claim 9b** (`devcontainer-config/cc-exit-scan.sh:431-432`): "a value ending mid-character would never match" is false on bash 5.2.15, where the match succeeds and the cut (`${#p}`, `${u:n}`) is what goes wrong. Reword the comment.
- **Claim 12** (`devcontainer-config/cc-exit-scan.sh:713-714`): "as git would" is false for whitespace. git trims a branches line and right-trims a remotes `URL:` line, and the scan does neither, so a planted hook goes unseen (R4; pre-existing).
- **Claim 13b** (`devcontainer-config/cc-exit-scan.sh:729-731`): an empty `branches/<name>` marks the name defined without a URL. git pushes to the name, and the scan returns 0 (R4).
- **Claim 14** (`devcontainer-config/cc-exit-scan.sh:734`): the `[:space:]` strip runs in the caller's locale. U+3000 is stripped under UTF-8 but not by git, which gives a bypass (R5). Run it under `LC_ALL=C` (or strip only ASCII space and tab).
- **Claim 17** (`docs/working/plan-q096-exit-scan-insteadof-target.md:36`): B24 "covered" does not hold for branches files (see 13b).

### Stale
- **Claim 3** (`devcontainer-config/cc-exit-scan.sh:71-72`): "Only those three kinds of entry are followed in your own config". insteadOf rules and remote URLs are now followed too.
- **Claim 21** (`guides/cc-isolated-usage.md:333-334`): "Those are the only entries of your own config it follows" now contradicts the lines above it.

### Mostly Accurate
- **Claim 1** (`devcontainer-config/cc-exit-scan.sh:57-61`): add "or a remote with no url/vcs" (as the guide does), and include `remote.pushDefault`.
- **Claim 7** (`devcontainer-config/cc-exit-scan.sh:411-416`, guide `:350`, commit): the target cap counts distinct (URL, working tree) pairs, not distinct URLs.
- **Claim 16** (`docs/working/plan-q096-exit-scan-insteadof-target.md:34`): B22's failure was the character-counted cut, not the comparison.
- **Claim 20** (`guides/cc-isolated-usage.md:319-321`): "no `url`" means no url and no vcs, and it also applies to `remote.pushDefault`. The empty-branches-file case is not followed.
- **Claim 24** (commit e4b29291, bullet 3): same mechanism point as Claim 16.

### Unverifiable
- None.

## Goal-Alignment Note

- Success criterion (restated verbatim): A markdown report saved to /workspace/.claude/wt-q096/docs/reviews/q096-exit-scan-insteadof-target-p2-code-fact-check-report.md, structured per the code-fact-check skill, first line `Commit: e4b29291`, header field `**Replication:** k=1 (loop pass, decision 031)`.
- Answered: yes. Brief claims 1-6 are all verdicted, and claims 1-4 are verified by execution.
  - Claim 1 (locale) is split. The `local LC_ALL=C` and `LC_ALL=C read` work and are restored (Claims 5, 9a). But "nothing else ... under UTF-8" is refuted twice (6b, 14), and the comment's mechanism is wrong (9b).
  - Claim 2 (worklist exactly-once, hits, fail-closed) is verified (Claim 10, instrumented 5×5 run).
  - Claim 3 (keys) holds for u:/t: and is refuted for r: with an end-to-end bypass (6a/6b).
  - Claim 4 (url/vcs) holds for config and remotes files. It is refuted for empty branches files (13b), and the pre-existing whitespace trimming differs from git (12).
  - Claims 5 and 6 are verified, apart from the stale "only entries" sentences (3, 21) and the minor qualifiers in 1, 7, 16, 20 and 24.
- Out of scope: 5f754994's own text, except where e4b29291 made it stale. The remote.c source was not readable offline, so Claim 11 rests on git 2.39.5 behaviour plus recollection. A host bash other than 5.2.15 was not tested.
- Escalate: three exit-scan bypasses, all with end-to-end probes where the scan reports clean and git runs the planted hook.
  - (a) Under a UTF-8 host locale, the `r:` dedupe-key collision (6b) and the `[:space:]` strip (14).
  - (b) In any locale, an empty `branches/<name>` file (13b), which contradicts the commit's B24 "covered".
  - (c) Pre-existing, any locale: legacy-file whitespace trimming (12).
  - (a) and (b) fall within this unit's stated goal of not letting a session repoint a push through something the scan ignores. Running the whole snapshot under `LC_ALL=C` would close both (a) items at once.
- Decisions I made:
  - I treated the brief's claim-1 residue as a harvested claim (14), located at the code that refutes it.
  - I did not append Claim 9b to `docs/reviews/hallucination-patterns.md`, because the brief limits writes to this report. The orchestrator may add "bash UTF-8 prefix match claimed to fail on a mid-character value" if it counts behaviour misclaims as log entries.
  - Probe logs live in `$PC`, not in `docs/reviews/execution-logs/`, for the same reason.
