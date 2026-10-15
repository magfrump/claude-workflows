Commit: 03bc47c9

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-q096 (branch fix/q096-exit-scan-insteadof-target)
**Scope:** full branch, `git diff main...HEAD -- . ':!docs/reviews'` at 03bc47c9 (cc-exit-scan.sh, guides/cc-isolated-usage.md, plan, research, brief, bats suite) plus the five commit messages `git log main..HEAD`
**Checked:** 2026-10-15
**Total claims checked:** 38
**Summary:** 28 verified, 3 mostly accurate, 4 stale, 2 incorrect, 1 unverifiable

Replicate r1, final confirming pass. Every claim carries a `Legibility-target` field naming the reader the text is written for: **user** (the guide), **maintainer** (code comments and in-file docs), **reviewer** (plan, research, brief, commit messages).

Probe directory (all executed evidence): `/home/node/.claude/jobs/00bcf178/tmp/q096/probe-code-fact-check-r1/` (written below as `$PR`). Scripts are in `$PR/scripts/`, captured output in `$PR/logs/`. Every probe ran under `timeout` of at most 600 s with `GIT_CONFIG_GLOBAL` set to a file inside the probe dir and `GIT_CONFIG_NOSYSTEM=1`. The container runs git 2.39.5 and bash 5.2. `ps` showed no probe process still running before this report was written.

Executed runs (all cwd `/workspace/.claude/wt-q096` unless noted; timestamps are in the `.ts` files):
- E1 `LC_ALL=C timeout 600 bats test/cc-isolated-functions.bats -f 'Q-096'`: exit 0, 11/11 (2026-10-15T01:38). Log: `$PR/logs/bats-q096.out`.
- E2 `LC_ALL=C timeout 600 bats test/cc-isolated-functions.bats`: exit 0, `1..193`, 193 ok, 0 not ok (started 2026-10-15T01:38:33). Log: `$PR/logs/bats-full.out`.
- E3 `timeout 300 bash $PR/scripts/gitsem.sh`: exit 0 (2026-10-15T01:39:08). Hermetic git 2.39.5 push probes of the rewrite semantics. Log: `$PR/logs/gitsem.out`.
- E4 `timeout 60 bash $PR/scripts/utf8ops.sh $PR/u8`: exit 0. Checks under C.utf8 that every non-read split and slice keeps its bytes. Log: `$PR/logs/utf8ops.out`.
- E5 mutation runs: four copies of devcontainer-config/ and test/ at `$PR/mut-{herestr,key,match,hostread}`, each with one `LC_ALL=C` removed, each run with `bats -f 'Q-096'` from the copy (2026-10-15T01:39:49 to 01:40:09). Each copy exits 1 and kills a test: herestr kills #8, key kills #10, match kills #7, hostread kills #8. Logs: `$PR/logs/mut-*.out`, `$PR/logs/mut-summary.out`.
- E6 `timeout 300 bash $PR/scripts/worklist.sh`: exit 0 (2026-10-15T01:40:40). Sources the HEAD scan and logs every pair `_snap_match` compares. Log: `$PR/logs/worklist.out`.
- E7 `timeout 600 bash $PR/scripts/timing2.sh`: exit 0 (2026-10-15T01:41:16). Times 200 rewritten targets, missing and then planted, on this WSL2 machine with 16 CPUs and load about 2. Log: `$PR/logs/timing2.out`.
- E8 main's `cc-exit-scan.sh` and `cc-gitdir.sh` copied into `$PR/mut-main`, then `bats -f 'Q-096'`: exit 1, all 11 not ok (2026-10-15T01:42:19). Log: `$PR/logs/mut-main.out`, `$PR/logs/mut-main.ts`.

Hallucination pattern log read (`docs/reviews/hallucination-patterns.md`). The only relevant pattern family is test-count claims in commit messages (lines 28 and 30). Claim 35's "193/193" was checked against it and holds (E2).

---

## Claim 1a: "git takes only the longest, the scan walks them all" (rewrite semantics in the header)

**Location:** `devcontainer-config/cc-exit-scan.sh:61-65`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5's choice of the longest matching value, and the scan walking every matching rule's target; does not establish behavior on other git versions.
**Legibility-target:** maintainer

The header says the URLs are "rewritten by every url.<base>.insteadOf / pushInsteadOf rule whose value prefixes it (in any config read here, yours included; git takes only the longest, the scan walks them all)" (`cc-exit-scan.sh:62-64`). In E3 probe 1 git ran only `long-po`'s hook when both `https://o.invalid/` and `https://o.invalid/re` matched (`1 longest prefix (expect long-po) -> ran: long-po`). The scan adds every match to `_snap_hit_t`:

```bash
# devcontainer-config/cc-exit-scan.sh:448-454
    if [[ "$u" == "$p"* ]]; then
      if [ $((_snap_rwt + ${#_snap_hit_t[@]})) -ge "$GIT_EXIT_SCAN_MAX_REWRITE_TARGETS" ]; then
        ...
      fi
      _snap_hit_t+=("${_snap_rbases[ri]}${u:${#p}}"); _snap_hit_b+=("${_snap_ubases[ui]}")
    fi
```
(excerpt ends :454; enclosing `_snap_match` continues to :458 — read). Bats test 3 (overlapping prefixes) passes on HEAD (E1) and fails on main (E8).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:61-65`, `devcontainer-config/cc-exit-scan.sh:444-458`, `$PR/logs/gitsem.out`, `$PR/logs/bats-q096.out`, `$PR/logs/mut-main.out`

---

## Claim 1b: "Each of those URLs ... is also rewritten by every url.<base>.insteadOf / pushInsteadOf rule"

**Location:** `devcontainer-config/cc-exit-scan.sh:58-65`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers which values reach `_snap_url`, the rewrite queue; does not establish anything about how the rewritten targets are walked (Claims 12 and 13).
**Legibility-target:** maintainer

"Those URLs" points back to a list that includes "url.<base>.insteadOf bases" (`:60`). Bases are not queued for rewriting. `_snap_config` walks a base with `_snap_remote` and only queues it as a rule:

```bash
# devcontainer-config/cc-exit-scan.sh:519-522
        t="${key#url.}"; t="${t%.*}"
        case "$t" in ""|.) _snap_wrel "$key" "$f" ./ ;; esac
        _snap_rule "$t" "$val" || return 1
        _snap_remote "$t" "$base" || return 1 ;;
```

The list itself is introduced as "every remote that is a local path inside the checkout". Yet `_snap_url` queues every URL, local or not, before `_snap_remote` drops the non-local ones (`:412-418`: `_snap_urls+=("$1"); _snap_ubases+=("$2")` runs before `_snap_remote "$1" "$2"`). The mechanism and the conclusion are both right. Precise version: "every remote URL (local or not, but not an insteadOf base) ...". Neither gap opens a route: git does not rewrite a base, and walking the non-local URLs over-covers.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:58-65`, `devcontainer-config/cc-exit-scan.sh:412-418`, `devcontainer-config/cc-exit-scan.sh:516-522`

---

## Claim 2: "...nor a remote any insteadOf rule rewrites to a relative path ... those leave W records, and any W record refuses the note"

**Location:** `devcontainer-config/cc-exit-scan.sh:86-92`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a relative rewritten target leaving a W record that refuses the worktree note, including one rewritten by your own rule; does not establish handling of `~` targets (a listed known route).
**Legibility-target:** maintainer

Every rewritten target goes through `_snap_remote`, which writes a W record for any relative path other than `.`: `[ "$p" = . ] || _snap_wrel remote "$p" "$p"` (`cc-exit-scan.sh:376`). Bats test 6 ("a relative one refuses the worktree note") uses your global rule `url.vendor/.insteadOf x:` and expects `warns_listing_wt`. It passes on HEAD (E1) and fails on main (E8).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:86-92`, `devcontainer-config/cc-exit-scan.sh:365-388`, `test/cc-isolated-functions.bats:2195-2211`, `$PR/logs/bats-q096.out`

---

## Claim 3: "Only those three kinds of entry, your insteadOf rules and your remote URLs are followed in your own config; its entries are not recorded"

**Location:** `devcontainer-config/cc-exit-scan.sh:91-93`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `_snap_host_config` queuing your rules and remote URLs and emitting no C record for your entries; does not establish behavior for your include targets inside the checkout (read by `_snap_config` as checkout files, a pre-existing exception documented at `:597-598`).
**Legibility-target:** maintainer

```bash
# devcontainer-config/cc-exit-scan.sh:614-618
    # Your rewrite rules apply to repo URLs, and any rule to your remotes' URLs.
    case "$key" in
      url.*.insteadof|url.*.pushinsteadof) t="${key#url.}"; _snap_rule "${t%.*}" "$val" || return 1 ;;
      remote.*.url|remote.*.pushurl) _snap_url "$val" "$wt" || return 1 ;;
    esac
```
(excerpt ends :618; enclosing `_snap_host_config` continues to :641 — read). The rest of the function adds no `C` line to `_snap` (paraphrased — no quote available because the claim is the absence of a `_snap+="C..."` statement in :600-641, confirmed by reading the whole function). In E6 your `remote.mine.url`, rewritten by a repo rule, was walked (`own remote rewritten: walked`). Grepping the snapshot for your entries (`global.gitconfig`, `probe-name`, `m.invalid/r`, `own-`) found 0 records.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:91-93`, `devcontainer-config/cc-exit-scan.sh:600-641`, `$PR/logs/worklist.out`

---

## Claim 4: "...or an insteadOf pass too long or too large (_snap_key, _snap_pairs_ok, _snap_match) makes the snapshot fail: at launch the launcher refuses to start, at exit it returns 4"

**Location:** `devcontainer-config/cc-exit-scan.sh:96-99`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers all three caps failing `git_exec_snapshot` (status 1), `git_exit_scan` returning 2 and the launcher mapping that to exit 4 or, at launch, exit 1; does not establish an end-to-end launcher run (not run, since it needs a container).
**Legibility-target:** maintainer

In E6 each cap made `git_exec_snapshot` return 1 with its message: `targets cap rc=1`, `pairs cap rc=1`, `bytes cap rc=1`. In bats test 11 `git_exit_scan` returns `[ "$status" -eq 2 ]` for all three (E1). The launcher's mapping:

```bash
# devcontainer-config/cc-isolated.sh:934-938
  case "$scan" in
    0) exit "$rc" ;;
    1) exit 3 ;;   # the session planted something: never a clean exit
    *) exit 4 ;;   # the scan could not read .git
  esac
```
At launch a failing snapshot runs `exit 1` (`cc-isolated.sh:859-867`). The failure is observed by whoever ran the launcher, through stderr and the exit status.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:96-99`, `devcontainer-config/cc-exit-scan.sh:1104-1121`, `devcontainer-config/cc-isolated.sh:859-867`, `devcontainer-config/cc-isolated.sh:932-938`, `$PR/logs/worklist.out`, `$PR/logs/bats-q096.out`

---

## Claim 5: "EVERY `read` RUNS UNDER LC_ALL=C: in a UTF-8 locale it swallows a NUL or newline after an incomplete multibyte character, hiding the next entry"

**Location:** `devcontainer-config/cc-exit-scan.sh:123-124`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every `read` in cc-exit-scan.sh, the mechanism for NUL, the mechanism for newline through the here-string legacy read, and every non-read split or slice of container bytes; does not establish anything about cc-gitdir.sh's two whole-file reads (not in this diff; e4b29291 notes them).
**Legibility-target:** maintainer

Grepping for `read ` lines that lack `LC_ALL=C IFS= read`, and for `mapfile|readarray|read -`, finds no read call. Only comments and `_snap_fail` strings match (paraphrased — no quote available because the claim is the absence of matching lines). The mechanism, from E4: under C.utf8, `printf 'a\xc3\0b\0'` read with `IFS= read -r -d ''` gives `utf8 read entries: 1`, and with the `LC_ALL=C` prefix `C read entries: 2`. The locale goes back to C.utf8 after the builtin (`after read LC_ALL=C.utf8`). In E5, removing `LC_ALL=C` from the here-string read alone (`:729`) kills test 8, and removing it from the NUL reads kills test 8 as well.

The second half of the brief's claim 5 ("nothing else that splits or slices container bytes drops or merges entries") also holds. E4 ran every non-read split on invalid UTF-8 bytes under C.utf8: `${rec%%$'\n'*}`, `${rec#*$'\n'}`, the `remote.*.*` / `remote.*.url` / `url.*.insteadof` case patterns, `${t%.*}`, `${line%%#*}`, the `[![:space:]]` trim, the `host:path` test and `${f#...}`. Each matched and kept the exact bytes (for example `base:  73 75 62 2f 61 c3`, `val3:  c3 78`). `_snap_key` and `_snap_match` set `local LC_ALL=C`, and E4 shows the locale is restored on return (`after fn LC_ALL=C.utf8 len=1`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:123-124`, `devcontainer-config/cc-exit-scan.sh:232`, `devcontainer-config/cc-exit-scan.sh:335`, `devcontainer-config/cc-exit-scan.sh:487`, `devcontainer-config/cc-exit-scan.sh:610`, `devcontainer-config/cc-exit-scan.sh:729`, `$PR/logs/utf8ops.out`, `$PR/logs/mut-summary.out`

---

## Claim 6: "...and the insteadOf pass's queues (_snap_urls/_snap_ubases, _snap_rbases/_snap_rpfx, _snap_hit_t/_snap_hit_b, _snap_rwseen, _snap_k, the _snap_rwn/_snap_rwt counters)" are git_exec_snapshot locals

**Location:** `devcontainer-config/cc-exit-scan.sh:158-163`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the declaration of every named variable as a local of `git_exec_snapshot`; does not establish that no helper is called outside that function (the bats probes call the helpers only through it).
**Legibility-target:** maintainer

```bash
# devcontainer-config/cc-exit-scan.sh:781-784
  local _snap_bytes=0 _snap_rwn=0 _snap_rwt=0 _snap_k u r
  local -A _snap_seen=() _snap_rnames=() _snap_rwseen=()
  local -a _snap_names=() _snap_nbases=() _snap_urls=() _snap_ubases=() _snap_rbases=() _snap_rpfx=()
  local -a _snap_hit_t=() _snap_hit_b=()
```
(excerpt ends :784; enclosing `git_exec_snapshot` continues to :860 — read)

**Evidence:** `devcontainer-config/cc-exit-scan.sh:158-163`, `devcontainer-config/cc-exit-scan.sh:779-860`

---

## Claim 7: "Caps ...: bytes in one URL, rule base or value (_snap_key); pairs compared (_snap_pairs_ok); rewritten URLs to walk ... (_snap_match). Over any of them the snapshot fails" (constants 4096 / 100000 / 2000)

**Location:** `devcontainer-config/cc-exit-scan.sh:390-396`
**Type:** Configuration / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three constants, where each is enforced, and the exact 4096/4097 boundary; does not establish a check on a URL's working tree, which `_snap_key` also tests but the comment does not list (the error message does name it), nor a length cap on rewritten targets, which have none.
**Legibility-target:** maintainer

`GIT_EXIT_SCAN_MAX_REWRITE_BYTES=4096`, `..._PAIRS=100000` and `..._TARGETS=2000` (`:394-396`). In E6 a 4096-byte URL passed (`4096-byte URL rc=0 (len 4096)`) and a 4097-byte one failed. At cap 20 the 72-byte working tree tripped it: `over 20 bytes (19 and 72)`. That is the residue named in the scope: `_snap_url` calls `_snap_key "$1" "$2" check` with the working tree as `<b>` (`:413`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:390-396`, `devcontainer-config/cc-exit-scan.sh:401-409`, `devcontainer-config/cc-exit-scan.sh:413`, `$PR/logs/worklist.out`

---

## Claim 8: "_snap_key ...: a key for the pair prefixed by <a>'s length in bytes (LC_ALL=C; characters collide), so no byte can join two pairs"

**Location:** `devcontainer-config/cc-exit-scan.sh:398-400`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers byte-counted, uniquely decodable `len:a b` keys inside each `u:`/`r:`/`t:` namespace; does not establish anything about the associative-array lookups, which run in the caller's locale and are byte-exact by bash's string hashing (not separately probed).
**Legibility-target:** maintainer

```bash
# devcontainer-config/cc-exit-scan.sh:401-403
_snap_key() {
  local LC_ALL=C
  _snap_k="${#1}:$1$2"
```
(excerpt ends :403; enclosing `_snap_key` continues to :409 — read). With `<a>`'s byte length as a decimal prefix, the key decodes to exactly one `(a, b)`. In E5, swapping `local LC_ALL=C` for an inert local kills test 10, where the UTF-8 character and byte splits differ.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:398-409`, `$PR/logs/mut-key.out`

---

## Claim 9: "_snap_url <url> <working tree>: ... Walked now (_snap_remote) and queued for the insteadOf rules (_snap_match), once each."

**Location:** `devcontainer-config/cc-exit-scan.sh:410-411`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers walking and queuing each distinct (URL, working tree) once; does not establish deduplication across different working trees, which is deliberately per tree.
**Legibility-target:** maintainer

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
In E6 2 distinct URLs were compared (`urls: 2`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:410-418`, `$PR/logs/worklist.out`

---

## Claim 10: "git rewrites a URL starting with <value> to <base> + the rest"

**Location:** `devcontainer-config/cc-exit-scan.sh:420-421`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5's prefix-to-base rewrite, applied once; does not establish behavior on other git versions.
**Legibility-target:** maintainer

E3 probes 1, 2, 3, 5 and 6 each ran the hook at `<base><rest>`. For example, probe 3 ran `x-\251vil` for the URL `\xc3\xa9vil` and the value `\xc3`.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:420-427`, `$PR/scripts/gitsem.sh`, `$PR/logs/gitsem.out`

---

## Claim 11: "_snap_pairs_ok <n>: charge <n> more comparisons to the pair cap."

**Location:** `devcontainer-config/cc-exit-scan.sh:429`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers charging per batch, before the batch, failing when the total is more than the cap; does not establish anything beyond the comparison count (cost per comparison is capped by Claim 7).
**Legibility-target:** maintainer

`_snap_rwn=$((_snap_rwn + $1))` then `[ "$_snap_rwn" -gt "$GIT_EXIT_SCAN_MAX_REWRITE_PAIRS" ] || return 0` (`:431-432`). The closing loop calls it before each `_snap_match` (`:843`, `:849`). In bats test 11 cap 1 fails with "(1 URLs, 2 rules so far)", and in E6 cap 2 fails, both at the expected batch.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:429-435`, `devcontainer-config/cc-exit-scan.sh:835-856`, `$PR/logs/bats-q096.out`, `$PR/logs/worklist.out`

---

## Claim 12: "git's alias_url compares bytes (case-sensitive; an empty value matches every URL), so the match and the cut run under LC_ALL=C: in a UTF-8 locale ${#p} counts characters, and a value ending mid-character would cut the URL in the wrong place."

**Location:** `devcontainer-config/cc-exit-scan.sh:437-443`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git's byte-wise, case-sensitive, empty-matches-all prefix test and the scan's cut under C; does not establish behavior on git versions other than 2.39.5.
**Legibility-target:** maintainer

E3: probe 2 (empty value) ran `e-repo`. Probe 3 (value `\xc3`, URL `\xc3\xa9vil`) ran `x-` + `\251vil`, so git cuts after the byte. Probe 7 (`HTTPS://` against `https://`) ran nothing. E4 shows `${#s}` is 1 for `\xc3\xa9` under C.utf8 and 2 under C. In E5, dropping `LC_ALL=C` from `_snap_match`'s `local` kills test 7.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:437-458`, `$PR/logs/gitsem.out`, `$PR/logs/utf8ops.out`, `$PR/logs/mut-match.out`

---

## Claim 13: "_snap_walk_hits: walk each rewritten URL _snap_match found, like any remote, once; never queued as a URL (git rewrites once), and walking adds no hits."

**Location:** `devcontainer-config/cc-exit-scan.sh:459-460`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers once-per-(target, tree) walking, no re-queue, and no chaining in git; does not establish that `_snap_rwt` counts distinct targets (it counts every match before dedupe: see Claims 18, 32 and 33).
**Legibility-target:** maintainer

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
Only `_snap_match` appends to `_snap_hit_t`, and `_snap_match` is called only from the closing loop (paraphrased — no quote available because the claim covers absence of other callers, confirmed by grep). E3 probe 4 (rule 1 rewrites to `chain:`, rule 2 rewrites `chain:` to a local repo) ran nothing, so git does not chain.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:459-471`, `devcontainer-config/cc-exit-scan.sh:835-856`, `$PR/logs/gitsem.out`

---

## Claim 14: "url.<base>.insteadOf rewrites matching URLs to <base>: the base alone here, every URL it rewrites in git_exec_snapshot (_snap_match)."

**Location:** `devcontainer-config/cc-exit-scan.sh:517-518`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers `_snap_config` queuing the rule and walking only the base; does not establish anything about the rewritten URLs themselves (Claims 12, 13 and 16).
**Legibility-target:** maintainer

Quoted in Claim 1b (`:519-522`): `_snap_rule "$t" "$val"` then `_snap_remote "$t" "$base"`.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:516-522`

---

## Claim 15: "Your rewrite rules apply to repo URLs, and any rule to your remotes' URLs."

**Location:** `devcontainer-config/cc-exit-scan.sh:614`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers your rules (empty values included, since queuing runs before `[ -n "$val" ] || continue`) and your remote URLs entering the shared queues; does not establish that your `branch.*.remote`, `pushRemote` or `remote.pushDefault` are queued (they are not: see Claim 30's residue).
**Legibility-target:** maintainer

Quoted in Claim 3 (`:614-618`). Bats test 5 ("YOUR global rule rewrites a repo URL; a repo rule rewrites YOUR own remote") passes on HEAD and fails on main (E1, E8). E6 shows the same: `own remote rewritten: walked`.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:614-619`, `test/cc-isolated-functions.bats:2185-2193`, `$PR/logs/worklist.out`

---

## Claim 16: "a new URL meets the rules already seen, a new rule meets the URLs already seen, so each pair meets once."

**Location:** `devcontainer-config/cc-exit-scan.sh:830-833`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers exactly-once comparison of every (URL, rule) pair, including URLs and rules first found inside a rewritten target, and the loop ending only when names, URLs and rules are all exhausted, or when rc≠0 (fail closed); does not establish ordering effects on the target cap's count (that count only decides when the scan fails closed).
**Legibility-target:** maintainer

```bash
# devcontainer-config/cc-exit-scan.sh:834-856
  i=0 u=0 r=0
  while [ "$rc" -eq 0 ]; do
    if [ "$i" -lt "${#_snap_names[@]}" ]; then
      ...
    elif [ "$u" -lt "${#_snap_urls[@]}" ]; then
      # URL u against rules 0..r-1.
      _snap_pairs_ok "$r" || { rc=1; break; }
      _snap_hit_t=() _snap_hit_b=()
      _snap_match "$u" 0 "$r" 0 && _snap_walk_hits || rc=1
      u=$((u + 1))
    elif [ "$r" -lt "${#_snap_rbases[@]}" ]; then
      # Rule r against URLs 0..u-1.
      ...
    else
      break
    fi
  done
```
(excerpt ends :856; enclosing `git_exec_snapshot` continues to :860 — read: `rm -rf`, `[ "$rc" -eq 0 ] || return 1`, sorted output). The E6 setup puts one rule (t2) and one URL (`https://b.invalid/y`) only inside the rewritten target `t1-x`'s config. All three targets were walked (`walked t1-x`, `walked t2-`, `walked t3-y`), and the logged comparisons were `pairs compared: 6, distinct: 6` for 2 URLs × 3 rules. In the same run an unreadable config inside a rewritten target failed the snapshot (`unreadable target config rc=1`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:830-860`, `$PR/scripts/worklist.sh`, `$PR/logs/worklist.out`

---

## Claim 17: "Status: done"

**Location:** `docs/working/briefs/2026-10-02-exit-scan-insteadof-target.md:3`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the brief's status line; does not establish that the brief's acceptance items are met beyond what the other claims verify.
**Legibility-target:** reviewer

`Status: done` (`briefs/2026-10-02-exit-scan-insteadof-target.md:3`).

**Evidence:** `docs/working/briefs/2026-10-02-exit-scan-insteadof-target.md:3`

---

## Claim 18: B14 — "`GIT_EXIT_SCAN_MAX_REWRITE_TARGETS` (2,000 distinct rewritten URLs)"

**Location:** `docs/working/plan-q096-exit-scan-insteadof-target.md:27`
**Type:** Configuration
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the target cap counts at HEAD; does not dispute the rest of row B14 (the pair cap checked before each batch, exit 4 / exit 1), which is verified.
**Legibility-target:** reviewer

At e4b29291 the counter went up only after the dedupe check (`git show e4b29291:...:456-459`: `[ -z "${_snap_rwseen["$k"]:-}" ] || return 0` ... `_snap_rwt=$((_snap_rwt + 1))`). Since 4d7f966c it goes up before the dedupe: `_snap_rwt=$((_snap_rwt + 1))` comes before `[ -z "${_snap_rwseen["t:$_snap_k"]:-}" ] || continue` (`cc-exit-scan.sh:465-467`). `_snap_match` also counts the current batch's undeduplicated hits (`:449`). The cap therefore counts URL-and-rule matches, as the guide (`:349-350`) and 03bc47c9 now say. Fix: "2,000 rewritten URLs (one per URL-and-rule match, before dedupe)". The same stale wording appears in this pass's shared brief (`What this PR is trying to accomplish`).

**Evidence:** `docs/working/plan-q096-exit-scan-insteadof-target.md:27`, `devcontainer-config/cc-exit-scan.sh:449`, `devcontainer-config/cc-exit-scan.sh:465-467`, `$PR/logs/worklist.out`

---

## Claim 19: Pre-mortem rows marked "covered" (B1–B13, B15, B16, B21, B22, B25–B28) and their "How" mechanisms

**Location:** `docs/working/plan-q096-exit-scan-insteadof-target.md:14-42`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the stated mechanism of each covered row except B14's "distinct" (Claim 18); does not establish the not-covered rows (B17–B20, B24, B29), which are not claims of coverage.
**Legibility-target:** reviewer

The rows' mechanisms are exercised by bats tests 1–11, which all pass on HEAD (E1) and all fail on main (E8). B1, B2, B3 and B8 are tests 1–2. B4 is test 3. B6 is test 4. B7 and B21 are test 5. B11 is test 6. B12 is the second half of test 1. B22 is test 7. B23 is test 9. B25 is test 8. B26 is test 10. B27 and B28 are test 11. Further evidence: B10 in E6 (a rule and a URL found inside a target), B15 and B16 in E3 probes 2 and 7, the B22/B25/B26 fixes in E5 mutations, and B27's boundary in E6. B5 is static: `_snap_config "$t" "$base"` recurses into include targets, which run the same `case` (`cc-exit-scan.sh:501`). B13 is static: `_snap_remote`'s `file://` handling and `_snap_inside_ws`'s `realpath -m` (`:367-372`, `:317-322`) — paraphrased — no quote available because the handling spans two helpers.

**Evidence:** `docs/working/plan-q096-exit-scan-insteadof-target.md:14-42`, `test/cc-isolated-functions.bats:2130-2291`, `$PR/logs/bats-q096.out`, `$PR/logs/mut-main.out`, `$PR/logs/worklist.out`, `$PR/logs/gitsem.out`

---

## Claim 20: "No uncovered family needs a design change: B17–B20 are outside what a config scan can or must see, and B18 stays a listed known route."

**Location:** `docs/working/plan-q096-exit-scan-insteadof-target.md:44`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the plan's own list of uncovered rows; does not establish whether the split family needs a design change (that is the stacked branch's question).
**Legibility-target:** reviewer

Rows B24 and B29 are also uncovered ("not covered here: split to its own unit", "not covered: split unit", `plan:35`, `plan:40`), but the sentence names only B17–B20. Precise version: "...B17–B20 are outside ...; B24/B29 moved to fix/q096b-exit-scan-remote-names and are a listed known route meanwhile." The guide does list that route (`guides/cc-isolated-usage.md:421-427`).

**Evidence:** `docs/working/plan-q096-exit-scan-insteadof-target.md:35`, `docs/working/plan-q096-exit-scan-insteadof-target.md:40`, `docs/working/plan-q096-exit-scan-insteadof-target.md:44`, `guides/cc-isolated-usage.md:421-427`

---

## Claim 21: Test specification — "The cap case sets `GIT_EXIT_SCAN_MAX_REWRITES` low and expects the snapshot to fail with \"too many\"" (and "Each new bats case plants a pre-receive hook ... expects `git_exit_scan` status 1")

**Location:** `docs/working/plan-q096-exit-scan-insteadof-target.md:77`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the variable name, the expected message and the per-case shape against the tests at HEAD; does not dispute the test commands named, which E1 and E2 ran.
**Legibility-target:** reviewer

`GIT_EXIT_SCAN_MAX_REWRITES` does not exist at HEAD. e4b29291 replaced it with `_PAIRS` and `_TARGETS`, and 4d7f966c added `_BYTES` (`cc-exit-scan.sh:394-396`). The cap test sets all three and expects `git_exit_scan` status 2. Its byte-cap case expects "too long to compare", not "too many" (`test/cc-isolated-functions.bats:2277-2290`). Not every case expects status 1 with a hook: test 6 checks a W-record warning, and test 11 checks status 2.

**Evidence:** `docs/working/plan-q096-exit-scan-insteadof-target.md:77`, `devcontainer-config/cc-exit-scan.sh:394-396`, `test/cc-isolated-functions.bats:2195-2211`, `test/cc-isolated-functions.bats:2270-2291`

---

## Claim 22: "alias_url ...: among every insteadOf value that is a prefix of url (plain starts_with, case-sensitive; an empty value matches everything), the longest wins ... Applied once, never chained." / "pushurl values are rewritten with insteadOf. When a remote has no pushurl, each remote.<n>.url is also rewritten with pushInsteadOf into an implicit pushurl."

**Location:** `docs/working/research-q096-exit-scan-insteadof-target.md:19-20`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5 push behavior for each stated rule; does not establish fetch-side behavior or other git versions.
**Legibility-target:** reviewer

E3 confirms each rule. Longest wins (probe 1). Empty value matches (probe 2). Byte-wise matching (probe 3). No chaining (probe 4). With no pushurl, pushInsteadOf beats insteadOf (probe 5: `pi-repo`). A pushurl is rewritten by insteadOf, not pushInsteadOf (probe 6: `pu-repo`; probe 8: nothing). pushInsteadOf on the url is ignored once a pushurl exists (probe 9: `pw-repo` only). Matching is case-sensitive (probe 7).

**Evidence:** `docs/working/research-q096-exit-scan-insteadof-target.md:17-23`, `$PR/scripts/gitsem.sh`, `$PR/logs/gitsem.out`

---

## Claim 23: "Each of those remote URLs, local or not, and each remote.*.url/pushurl in your own config, is also rewritten by every url.<base>.insteadOf and pushInsteadOf rule whose value it starts with ... git uses only the longest matching rule, the scan walks every match."

**Location:** `guides/cc-isolated-usage.md:321-326`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which values are rewritten and that every match is walked; does not establish anything about a walk beyond inside-the-checkout targets (non-local rewritten URLs are dropped, as `_snap_remote` drops any non-local URL).
**Legibility-target:** user

The semantics and the every-match walk are verified (Claims 1a, 12 and 16; E3; bats tests 1–5). One imprecision, the same as Claim 1b: "those remote URLs" refers back to a list (`:319-320`) that includes `url.<base>.insteadOf`. Bases are not rewritten, only walked and queued as rules (`cc-exit-scan.sh:521-522`, quoted in Claim 1b). Precise version: "Each of those remote URLs (not an insteadOf base) ...". This opens no route, since git does not rewrite a base.

**Evidence:** `guides/cc-isolated-usage.md:317-326`, `devcontainer-config/cc-exit-scan.sh:516-522`, `$PR/logs/bats-q096.out`

---

## Claim 24: "Those, your insteadOf rules and your remote URLs are the only entries of your own config it follows; none is recorded."

**Location:** `guides/cc-isolated-usage.md:332-333`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claim 3; does not establish anything about your include targets inside the checkout, which are recorded as checkout files.
**Legibility-target:** user

Same code and E6 result as Claim 3 (`records naming own config entries: 0`; `cc-exit-scan.sh:614-618`).

**Evidence:** `guides/cc-isolated-usage.md:332-333`, `devcontainer-config/cc-exit-scan.sh:600-641`, `$PR/logs/worklist.out`

---

## Claim 25: "...and so do a remote URL or insteadOf rule over 4,096 bytes, more than 100,000 URL-and-rule comparisons, or more than 2,000 rewritten URLs to walk (one per URL-and-rule match). (At launch any of these refuses the launch instead, exit 1.)"

**Location:** `guides/cc-isolated-usage.md:348-351`
**Type:** Configuration / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three thresholds (at 4096 and 4097 bytes, the more-than semantics of both count caps), match-counting before dedupe, and exit 4 / exit 1; does not establish the byte cap on a URL's working tree, which the guide omits (residue, as in Claim 7).
**Legibility-target:** user

The pair cap fails only above the limit (`-gt`, `:432`). The target cap refuses the (MAX+1)th match (`-ge` on the count before adding, `:449`), which is "more than 2,000". Test 11 with cap 1 fails on the second match. Byte boundary and exit statuses: Claims 4 and 7 (E1, E6).

**Evidence:** `guides/cc-isolated-usage.md:344-351`, `devcontainer-config/cc-exit-scan.sh:430-435`, `devcontainer-config/cc-exit-scan.sh:444-458`, `devcontainer-config/cc-isolated.sh:932-938`, `$PR/logs/worklist.out`, `$PR/logs/bats-q096.out`

---

## Claim 26: "(a remote of `.` is fine; an insteadOf base of `.` or `""` is not, nor a remote any insteadOf rule, yours included, rewrites to a relative path)"

**Location:** `guides/cc-isolated-usage.md:378-379`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claim 2; does not establish anything about `~` targets.
**Legibility-target:** user

Bats test 6 rewrites a repo URL to a relative path with your global rule and expects the worktree warning. It passes (E1). `_snap_remote` writes the W record (`cc-exit-scan.sh:375`).

**Evidence:** `guides/cc-isolated-usage.md:375-380`, `devcontainer-config/cc-exit-scan.sh:375`, `test/cc-isolated-functions.bats:2195-2211`, `$PR/logs/bats-q096.out`

---

## Claim 27: "at the insteadOf caps, rewritten URLs alone add 10-80 s (a WSL2 host; the most when each is a planted repository)"

**Location:** `guides/cc-isolated-usage.md:418-419`
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the order of magnitude on this WSL2 container, extrapolated linearly from 200 targets to the 2,000 cap; does not establish a measurement at the full cap, on the user's host itself, or with long URLs.
**Legibility-target:** user

E7 at N=200: missing targets took 1.50 s (1.52 s on a repeat), and planted bare repos took 5.67 s. Linear ×10 gives about 15 s and about 57 s, which is inside 10–80 s, with planted repos the slow end. Medium confidence: linear extrapolation at one-tenth scale, on a container on a WSL2 kernel (load about 2), not the user's host.

**Evidence:** `guides/cc-isolated-usage.md:414-420`, `$PR/scripts/timing2.sh`, `$PR/logs/timing2.out`

---

## Claim 28: "`~user/…`, a bare `~`, and a `~` in a local remote URL (or one an insteadOf rule rewrites to) are taken as relative paths"

**Location:** `guides/cc-isolated-usage.md:452-456`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers rewritten targets reaching `_snap_remote`, which has no `~` expansion; does not establish how git expands them (a listed known route).
**Legibility-target:** user

`_snap_remote` prefixes any path not starting with `/` with the base: `case "$p" in /*) ;; *) p="$base/$p" ;; esac` (`cc-exit-scan.sh:377`). It has no `~` branch. Rewritten targets reach it through `_snap_walk_hits` (`:469`).

**Evidence:** `guides/cc-isolated-usage.md:452-456`, `devcontainer-config/cc-exit-scan.sh:365-388`, `devcontainer-config/cc-exit-scan.sh:469`

---

## Claim 29: "A URL you type. `git push <url>` ... uses a URL no config holds, and an insteadOf rule can rewrite it to a local path inside the checkout; the scan only sees URLs in config and legacy remotes files."

**Location:** `guides/cc-isolated-usage.md:457-459`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the sources of `_snap_url` calls; does not establish git's command-line rewrite, which follows from alias_url applying to any URL (consistent with E3, not separately probed).
**Legibility-target:** user

`_snap_url` is called only from `_snap_config` (`:514`), `_snap_host_config` (`:617`), the legacy loop (`:731`, `:734`) and the closing loop's names branch (`:840`) (paraphrased — no quote available because the claim covers the full call-site set, found by grep).

**Evidence:** `guides/cc-isolated-usage.md:457-459`, `devcontainer-config/cc-exit-scan.sh:514`, `devcontainer-config/cc-exit-scan.sh:617`, `devcontainer-config/cc-exit-scan.sh:731-734`, `devcontainer-config/cc-exit-scan.sh:840`

---

## Claim 30: Removal of the known route "A URL rewritten by url.<base>.insteadOf" — implicitly, the scan now sees a push repointed through a rewrite (the brief's claim 7)

**Location:** `guides/cc-isolated-usage.md:414-428`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers rewrite routes where the rule and the URL are in any config the scan reads (repo, include, embedded repo, rewritten target, your own) and the target is inside the checkout: every (URL, rule) pair compared, every match walked, caps failing closed. It does not establish routes that stay listed (a typed URL, `~` forms, the loose remote-name family B29, a slow scan). It also does not establish the following residue: a path-valued `branch.*.remote`, `branch.*.pushRemote` or `remote.pushDefault` in YOUR global config. `_snap_host_config` queues only your url/pushurl and rules, never those names. So a name of yours that no remote defines (git then pushes to it as a path, possibly rewritten by a repo rule) is not walked. This is pre-existing (main does not walk those names either), not made worse by this branch, and needs that value in your own config.
**Legibility-target:** user

Evidence for the covered scope: Claims 1a, 12, 13, 15 and 16; bats tests 1–11 (E1) all failing on main (E8); E6's discovery inside a target; E3's git semantics, where the scan's every-rule-every-URL set is a superset of git's choices (pushInsteadOf vs pushurl, longest match). The residue comes from reading `_snap_host_config`'s `case` (`:615-618`, `:621-639`): it has no `remote.pushdefault|branch.*.remote|branch.*.pushremote` arm, unlike `_snap_config` (`:505-509`).

**Evidence:** `guides/cc-isolated-usage.md:414-428`, `devcontainer-config/cc-exit-scan.sh:505-509`, `devcontainer-config/cc-exit-scan.sh:600-641`, `$PR/logs/mut-main.out`, `$PR/logs/worklist.out`

---

## Claim 31a: 5f754994 — "More than GIT_EXIT_SCAN_MAX_REWRITES (100,000) comparisons fails the snapshot closed."

**Location:** `git log 5f754994` (commit message body)
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the variable name at HEAD; does not dispute the value 100,000, which `_PAIRS` keeps.
**Legibility-target:** reviewer

At HEAD the cap is `GIT_EXIT_SCAN_MAX_REWRITE_PAIRS=100000` (`cc-exit-scan.sh:395`). e4b29291 records the rename ("the pair cap, renamed GIT_EXIT_SCAN_MAX_REWRITE_PAIRS").

**Evidence:** `devcontainer-config/cc-exit-scan.sh:394-396`

---

## Claim 31b: 5f754994 — "All eight fail on the pre-fix scan."

**Location:** `git log 5f754994` (commit message body)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every Q-096 test at HEAD (11, including the merged descendants of the original eight) failing against main's scan; does not establish the original eight test bodies at 5f754994, which were since merged.
**Legibility-target:** reviewer

E8: main's `cc-exit-scan.sh` and `cc-gitdir.sh` with the HEAD tests give 11/11 `not ok`.

**Evidence:** `$PR/logs/mut-main.out`, `$PR/logs/mut-main.ts`

---

## Claim 32: e4b29291 — "New GIT_EXIT_SCAN_MAX_REWRITE_TARGETS (2,000 distinct rewritten URLs)" / "The 2,000-target cap counts every distinct rewritten URL" / "A name is now defined only by url/vcs or a URL read from the legacy file."

**Location:** `git log e4b29291` (commit message body)
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers both statements against HEAD; does not dispute that they were true at e4b29291.
**Legibility-target:** reviewer

Both were true at e4b29291 and are superseded. The target counter now counts before dedupe (Claim 18, `cc-exit-scan.sh:465-467`). The name rule went back to main's "any remote.<name>.* key" in 013f1b3d: `name="${key#remote.}"; name="${name%.*}"` / `[ -z "$name" ] || _snap_rnames["$name"]=1` (`cc-exit-scan.sh:510-512`). 013f1b3d records the name revert, but no later message corrects e4b29291's "distinct" (03bc47c9 corrects only 4d7f966c's wording).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:465-467`, `devcontainer-config/cc-exit-scan.sh:509-515`

---

## Claim 33: 4d7f966c — "the 2,000 cap counts URL-and-working-tree targets"

**Location:** `git log 4d7f966c` (commit message body)
**Type:** Configuration
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers 4d7f966c's and HEAD's counter; does not affect the code, and 03bc47c9 already records the error.
**Legibility-target:** reviewer

At 4d7f966c `_snap_walk_hits` already increments `_snap_rwt` before the dedupe check (`git show 4d7f966c:devcontainer-config/cc-exit-scan.sh:471-473`, the same lines as HEAD `:465-467`). So the cap counts URL-and-rule matches, not deduplicated (target, working tree) pairs. 03bc47c9 says so: "(The 4d7f966c message's 'counts URL-and-working-tree targets' is wrong in the same way.)"

**Evidence:** `devcontainer-config/cc-exit-scan.sh:462-471`

---

## Claim 34: 013f1b3d — "the UTF-8 read test keeps only its hook half (the legacy-URL half proved the same read path)"

**Location:** `git log 013f1b3d` (commit message body)
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the read paths: the hook half exercises a NUL-delimited `read -d ''`, the legacy half the here-string newline `read`; does not affect HEAD, which restored the legacy half (03bc47c9 records the error).
**Legibility-target:** reviewer

The hook reads are `while LC_ALL=C IFS= read -r -d '' f` (`:335`). The legacy read is `while LC_ALL=C IFS= read -r line || [ -n "$line" ]; do ... done <<< "$body"` (`:729-735`), a different read call and delimiter. In E5 the herestr mutant changes only `:729` and still fails test 8 at HEAD, and only through its legacy half (the hook reads were untouched). The legacy half is therefore the only coverage of that read.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:335`, `devcontainer-config/cc-exit-scan.sh:729-735`, `test/cc-isolated-functions.bats:2229-2243`, `$PR/logs/mut-herestr.out`

---

## Claim 35: 03bc47c9 — "193/193", "Unit size 395 changed lines outside docs/", "dropping LC_ALL=C from that read fails it", "The byte-cap message names URL, working tree or rule and both lengths."

**Location:** `git log 03bc47c9` (commit message body)
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the suite count and pass rate in this container, the line count from `git diff --stat`, the here-string mutation and the message text; does not establish the host probe ("Host-tool-tested: no", as the trailer says).
**Legibility-target:** reviewer

E2: `1..193`, 193 ok. `git diff --stat main...HEAD -- . ':!docs/reviews'` gives 190 (cc-exit-scan.sh) + 39 (guide) + 166 (bats) = 395 outside `docs/`. E5 herestr mutant: test 8 fails. The message is `'a remote URL, its working tree or an insteadOf rule over %s bytes (%s and %s): too long to compare, ...'` (`:406`). Checked against the hallucination-log test-count pattern (lines 28 and 30): it holds.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:406-407`, `$PR/logs/bats-full.out`, `$PR/logs/bats-full.ts`, `$PR/logs/mut-herestr.out`

---

## Claim 36: 03bc47c9 — "Many remotes with no rules make the worklist slower (40k remotes: 55 s vs 30 s)"

**Location:** `git log 03bc47c9` (commit message Notes)
**Type:** Performance
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers nothing beyond noting that the mechanism is plausible: each remote URL is now keyed, deduplicated and queued, and with r=0 its batch charges 0 pairs; does not establish the timings.
**Legibility-target:** reviewer

Not run. A 40k-remote probe is well beyond the brief's "small probes" rule, and the figure is advisory (override-log row 134's documented slow-scan family). Verifying it would take a timed snapshot of a checkout with 40,000 `remote.*.url` entries on HEAD and on main.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:412-418`, `devcontainer-config/cc-exit-scan.sh:835-846`

---

## Claims Requiring Attention

### Incorrect
- **Claim 33** (`git log 4d7f966c`): the target cap never counted URL-and-working-tree targets; it counts matches before dedupe. Already recorded in 03bc47c9, so no code or doc fix is needed.
- **Claim 34** (`git log 013f1b3d`): the hook half does not exercise the here-string read. Already recorded and fixed in 03bc47c9 (the legacy half is restored, and E5 kills its mutant).

### Stale
- **Claim 18** (`docs/working/plan-q096-exit-scan-insteadof-target.md:27`): B14 says "2,000 distinct rewritten URLs". Should be "one per URL-and-rule match, before dedupe".
- **Claim 21** (`docs/working/plan-q096-exit-scan-insteadof-target.md:77`): the test spec names the removed `GIT_EXIT_SCAN_MAX_REWRITES`, a "too many" message (the byte cap says "too long") and a single test shape.
- **Claim 31a** (`git log 5f754994`): `GIT_EXIT_SCAN_MAX_REWRITES` was renamed to `_PAIRS` (recorded in e4b29291).
- **Claim 32** (`git log e4b29291`): "distinct" target counting and the url/vcs name rule are both superseded. The name rule's revert is recorded in 013f1b3d; "distinct" is corrected nowhere in the log (only the plan and guide could carry it).

### Mostly Accurate
- **Claim 1b** (`devcontainer-config/cc-exit-scan.sh:58-65`): "Each of those URLs" includes insteadOf bases, which are not rewritten, and the list's "local path" framing hides that non-local URLs are queued too.
- **Claim 20** (`docs/working/plan-q096-exit-scan-insteadof-target.md:44`): the uncovered list omits B24/B29 (split).
- **Claim 23** (`guides/cc-isolated-usage.md:321-326`): "those remote URLs" includes `url.<base>.insteadOf`, whose bases are walked but not rewritten.

### Unverifiable
- **Claim 36** (`git log 03bc47c9`): verifying "40k remotes: 55 s vs 30 s" needs a large timed probe on HEAD and main.

## Escalations

- None blocking. No finding shows a rewrite route the scan misses within this branch's scope. Every Incorrect and Stale item is in a commit message or the plan, not in code or the user guide.
- Residue noted in Claim 30 (pre-existing, not made worse here): a path-valued `branch.*.remote`, `branch.*.pushRemote` or `remote.pushDefault` in YOUR global or system config is not queued by `_snap_host_config`. It is not walked directly or through a rewrite. The guide's "Known routes" does not name it. Route it to the security reviewer or the q096b remote-names unit to decide whether it belongs to the B29 family.

## Goal-Alignment Note

The user goal is that the exit scan walks the URL an insteadOf or pushInsteadOf rule rewrites a remote to, so a session cannot repoint a push through an ignored rewrite. The code that does this checks out. Git 2.39.5's rewrite semantics were confirmed by hermetic pushes (E3). The worklist compares every (URL, rule) pair exactly once, including pairs found inside rewritten targets (E6). The three caps and every failure path fail closed with the documented statuses (E1, E6). The `LC_ALL=C` reads, key and match are each pinned by a test that kills its mutant (E5). The Q-096 tests all fail on main (E8), and the full suite passes 193/193 (E2). The remaining drift is documentation for reviewers: the plan's B14 and test spec, and older commit messages. Plus two imprecise "each of those URLs" sentences (header and guide) that over-state coverage in a harmless direction. None of these changes the 0-red merge decision. A doc-only touch-up of plan rows B14 and :77 (and optionally the two "those URLs" sentences) would leave no stale reviewer-facing text. The Claim 30 residue is outside this unit's change and should go to the split family rather than block this merge.
