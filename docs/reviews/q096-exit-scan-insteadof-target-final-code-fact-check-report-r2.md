Commit: 03bc47c9

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-q096 (branch fix/q096-exit-scan-insteadof-target)
**Scope:** full branch, `git diff main...HEAD -- . ':!docs/reviews'` at 03bc47c9 (devcontainer-config/cc-exit-scan.sh, guides/cc-isolated-usage.md, test/cc-isolated-functions.bats, docs/working/plan-q096-exit-scan-insteadof-target.md, docs/working/research-q096-exit-scan-insteadof-target.md, docs/working/briefs/2026-10-02-exit-scan-insteadof-target.md) plus the five commit messages `git log main..HEAD`
**Checked:** 2026-10-15
**Total claims checked:** 29
**Summary:** 21 verified, 3 mostly accurate, 2 stale, 3 incorrect, 0 unverifiable

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`): no claim below matches a logged pattern. None of the Incorrect verdicts is a fabrication (all are miscounts of a cap's unit or a superseded test-set statement), so the log is not appended.

Execution provenance. Every executed probe ran from `/home/node/.claude/jobs/00bcf178/tmp/q096/probe-code-fact-check-r2/` (abbreviated `$P` below) with `GIT_CONFIG_GLOBAL` pointed inside its own subdir and `GIT_CONFIG_NOSYSTEM=1`, under `timeout` ≤ 600, in the foreground; each finished before this report was written (no process of this review remains). Container: git 2.39.5, bash 5.2, kernel 6.18 WSL2. Captured outputs and timestamps:

| Log | Command (cwd) | Exit | UTC start |
|---|---|---|---|
| `$P/bats-q096.log` | `LC_ALL=C timeout 600 bats -f 'Q-096' test/cc-isolated-functions.bats` (worktree) | 0 (11/11) | 2026-10-15T08:37:49Z |
| `$P/bats-full.log` | `LC_ALL=C timeout 600 bats test/cc-isolated-functions.bats` (worktree) | 0 (193/193) | 2026-10-15T08:38:14Z |
| `$P/git-semantics.log` | `timeout 120 bash git-semantics.sh $P/git` (`$P`) | 0 | 2026-10-15T08:38:40Z |
| `$P/locale-probe.log` | `timeout 60 bash locale-probe.sh` (`$P`) | 0 | 2026-10-15T08:38:41Z |
| `$P/scan-probe.log` | `timeout 300 bash scan-probe.sh $P /workspace/.claude/wt-q096` (`$P`) | 0 | 2026-10-15T08:39:45Z |
| `$P/p3.log` | inline `timeout 60 bash -c '…'` glob-literal probe (`$P/p3`) | 0 | `$P/p3.ts` |
| `$P/timing-probe.log` | `timeout 600 bash timing-probe.sh $P /workspace/.claude/wt-q096 1999` (`$P`) | 0 | 2026-10-15T08:41:35Z |
| `$P/mut.log` | read at :729 without `LC_ALL=C`, `bats -f 'name ending mid-character'` (`$P/mut`, a copy) | 1 (fails, as claimed) | 2026-10-15T08:43:36Z |
| `$P/mut2.log` | `_snap_match` without `local LC_ALL=C`, `bats -f 'byte-wise'` (`$P/mut`) | 1 (fails) | 2026-10-15T08:43:46Z |
| `$P/mut3.log` | `_snap_key` without `local LC_ALL=C`, `bats -f 'characters, not bytes'` (`$P/mut`) | 1 (fails) | 2026-10-15T08:43:47Z |

---

## Claim 1: "Each of those URLs, and every remote.*.url/pushurl in your own config, is also rewritten by every url.<base>.insteadOf / pushInsteadOf rule whose value prefixes it (in any config read here, yours included; git takes only the longest, the scan walks them all), and the result walked the same way."

**Location:** `devcontainer-config/cc-exit-scan.sh:61-65`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer (header comment of an enforcement file)
**Scope:** Covers which URLs are queued for rewriting and that every matching rule is walked; does not establish rewrite semantics for URLs typed on the command line (none are seen).

The mechanism (every match walked, rules pooled from every config, yours included) is right, but the antecedent "those URLs" is the preceding list of "every remote that is a local path inside the checkout … url.<base>.insteadOf bases …" (`:57-61`), and the code differs from that list in two ways. (a) Non-local URLs are queued too — the main Q-096 case (`https://…` rewritten to a local path): `_snap_url` queues before `_snap_remote` decides locality:

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

(b) insteadOf bases are in the list but are never rewritten (correctly: git does not chain); a base goes straight to `_snap_remote`: `_snap_rule "$t" "$val" || return 1` / `_snap_remote "$t" "$base" || return 1` (`:521-522`). Executed: `$P/p3.log` shows a base walked alone (`…/ws/g-  missing`, `…/ws/q-  missing`) and no rewritten record. The precise version: "Every remote URL the scan meets, local or not (not the insteadOf bases), …". The guide's wording (`guides/cc-isolated-usage.md:322`, "local or not") already says (a).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:57-65`, `devcontainer-config/cc-exit-scan.sh:412-418`, `devcontainer-config/cc-exit-scan.sh:516-523`, `$P/p3.log`, `$P/bats-q096.log`

---

## Claim 2: "Only those three kinds of entry, your insteadOf rules and your remote URLs are followed in your own config; its entries are not recorded (the container cannot write it)."

**Location:** `devcontainer-config/cc-exit-scan.sh:71-73`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer (header comment)
**Scope:** Covers that `_snap_host_config` follows hooksPath, attributesFile, includes, url.*.insteadof/pushinsteadof and remote.*.url/pushurl and emits no C record for your entries; does not establish that following your remote URLs records nothing (it emits F/W records for local targets: see Claim 3).

```bash
# devcontainer-config/cc-exit-scan.sh:614-619
    # Your rewrite rules apply to repo URLs, and any rule to your remotes' URLs.
    case "$key" in
      url.*.insteadof|url.*.pushinsteadof) t="${key#url.}"; _snap_rule "${t%.*}" "$val" || return 1 ;;
      remote.*.url|remote.*.pushurl) _snap_url "$val" "$wt" || return 1 ;;
    esac
    [ -n "$val" ] || continue
```

The remainder of the loop (`:620-639`, read) handles only `core.hookspath`, `core.attributesfile`, `include.path|includeif.*.path`; there is no `_snap+="C…"` in `_snap_host_config` (paraphrased — no quote available because the claim covers absence of code: the only C-record writer is `_snap_config:492`, reached from here only for an include target inside the checkout, as the function comment at `:597-599` states). Executed: `$P/scan-probe.log` P5 (a rule in one of your include files outside the checkout, rewriting a repo URL) → `status=1 FOUND`; bats test "YOUR global rule rewrites a repo URL; a repo rule rewrites YOUR own remote" passes (`$P/bats-q096.log`). Rules with empty values are collected before the `[ -n "$val" ] || continue` (quoted above).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:600-641`, `$P/scan-probe.log`, `$P/bats-q096.log`

---

## Claim 3: "A relative core.hooksPath, core.attributesFile or local remote (a remote of "." excepted, but not an insteadOf base of "." or "", nor a remote any insteadOf rule rewrites to a relative path) in repo config … leave W records … (Your own config's relative hooksPath is walked in each new worktree …; its records refuse the note too.)"

**Location:** `devcontainer-config/cc-exit-scan.sh:87-94`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer (header comment)
**Scope:** Covers the W record for a rewritten relative target and the enumerated sources; does not establish W behavior for `~/` targets (no W record, known route).

The new clause is right: a rewritten relative target goes through `_snap_remote`, whose `[ "$p" = . ] || _snap_wrel remote "$p" "$p"` (`:376`) writes the W record; bats "a non-local rewritten URL is not walked; a relative one refuses the worktree note" passes. But the list of W sources is now incomplete: this branch makes `_snap_host_config` call `_snap_url` on your own `remote.*.url` (`:617`), so a relative remote URL in YOUR config (not rewritten) also leaves a W record and refuses the note. Executed: `$P/scan-probe.log` P4 with `git config --global remote.mine.url sub/x` → `W	remote	sub/x`. The parenthetical names only your relative hooksPath. Fail-closed direction (more refusals, never fewer); the precise version adds "or a relative remote URL in your own config".

**Evidence:** `devcontainer-config/cc-exit-scan.sh:87-94`, `devcontainer-config/cc-exit-scan.sh:376`, `devcontainer-config/cc-exit-scan.sh:617`, `$P/scan-probe.log`

---

## Claim 4: "…or an insteadOf pass too long or too large (_snap_key, _snap_pairs_ok, _snap_match) makes the snapshot fail: at launch the launcher refuses to start, at exit it returns 4."

**Location:** `devcontainer-config/cc-exit-scan.sh:96-100`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer / user (header comment, mirrored in guide)
**Scope:** Covers the three cap failures' propagation: snapshot 1, `git_exit_scan` 2, launcher exit 4 at exit and exit 1 at launch; does not establish behavior on a Ctrl-C mid-pass beyond the existing trap.

Each cap returns 1 through `_snap_fail` (which ends `return 1`, `:182`); `_snap_key`'s last command is the `_snap_fail` call (`:406-407`), `_snap_pairs_ok` likewise (`:433-434`), `_snap_match` has an explicit `return 1` (`:452`). Callers: `_snap_url`/`_snap_rule` `|| return 1` (`:413`, `:423`), main loop `_snap_pairs_ok "$r" || { rc=1; break; }` and `_snap_match … && _snap_walk_hits || rc=1` (`:843-845`, `:849-851`), then `[ "$rc" -eq 0 ] || return 1` (`:858`). `git_exit_scan` maps a failed snapshot to `return 2` (`:1120`); the launcher: `*) exit 4 ;;   # the scan could not read .git` (`cc-isolated.sh:951`) and at launch `exit 1` after a failed `git_exec_snapshot` (`cc-isolated.sh:859-866`). Executed: bats cap test (status 2 for all three caps, `$P/bats-q096.log`); P6 (rule from YOUR config over 4,096 bytes) → `P6 snapshot status=1 : a remote URL, its working tree or an insteadOf rule over 4096 bytes (4097 and 2)`.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:176-183`, `devcontainer-config/cc-exit-scan.sh:401-458`, `devcontainer-config/cc-exit-scan.sh:834-858`, `devcontainer-config/cc-exit-scan.sh:1104-1121`, `devcontainer-config/cc-isolated.sh:859-866`, `devcontainer-config/cc-isolated.sh:932-952`, `$P/scan-probe.log`, `$P/bats-q096.log`

---

## Claim 5: "EVERY `read` RUNS UNDER LC_ALL=C: in a UTF-8 locale it swallows a NUL or newline after an incomplete multibyte character, hiding the next entry from the scan."

**Location:** `devcontainer-config/cc-exit-scan.sh:123-124`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer (header comment)
**Scope:** Covers every `read` builtin in cc-exit-scan.sh and the stated mechanism for the legacy here-string read; does not establish locale-independence of non-read pattern expansions (the legacy-URL whitespace trim at `:734` differs by locale: Claim 22's known route).

`grep -n '\bread\b'` over the file, minus comments and the `LC_ALL=C IFS= read` form, leaves only message strings and `readlink`/`cat` (`:189`, `:228`, `:247`, `:484`, `:607`, `:728`, `:880`, `:1111`); no `mapfile`/`readarray` exists (paraphrased — no quote available because the claim covers absence of code: grep results listed in the run, no matching lines). Every reader has the form `while LC_ALL=C IFS= read -r -d '' f; do` (e.g. `:335`, `:487`, `:610`, `:686`, `:721`, `:729`, `:743`, `:751`, `:821`) or `{ LC_ALL=C IFS= read -r line < "$1"; }` (`:232`). Mechanism executed: removing `LC_ALL=C` from `:729` makes "under a UTF-8 locale a name ending mid-character does not hide the next entry" fail at line 2242 (`$P/mut.log`). `local LC_ALL=C` inside a function is restored on return under both `LC_ALL=C.utf8` and `LANG=C.utf8` (`$P/locale-probe.log`, "after f: 1").

**Evidence:** `devcontainer-config/cc-exit-scan.sh:232`, `devcontainer-config/cc-exit-scan.sh:335`, `devcontainer-config/cc-exit-scan.sh:487`, `devcontainer-config/cc-exit-scan.sh:610`, `devcontainer-config/cc-exit-scan.sh:729`, `$P/mut.log`, `$P/locale-probe.log`

---

## Claim 6: "…and the insteadOf pass's queues (_snap_urls/_snap_ubases, _snap_rbases/_snap_rpfx, _snap_hit_t/_snap_hit_b, _snap_rwseen, _snap_k, the _snap_rwn/_snap_rwt counters)" are git_exec_snapshot locals shared by dynamic scoping.

**Location:** `devcontainer-config/cc-exit-scan.sh:158-163`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** maintainer (header comment)
**Scope:** Covers that each named variable is declared local in `git_exec_snapshot`; does not establish absence of clobbering by every helper in cc-gitdir.sh (only the cc-exit-scan.sh helpers' `local` lists were read).

```bash
# devcontainer-config/cc-exit-scan.sh:781-784
  local _snap_bytes=0 _snap_rwn=0 _snap_rwt=0 _snap_k u r
  local -A _snap_seen=() _snap_rnames=() _snap_rwseen=()
  local -a _snap_names=() _snap_nbases=() _snap_urls=() _snap_ubases=() _snap_rbases=() _snap_rpfx=()
  local -a _snap_hit_t=() _snap_hit_b=()
```

The loop counters `i u r f g` are also locals of `git_exec_snapshot`; every helper reachable from the walk that uses those names declares its own (`_snap_config: local f …`, `_snap_gitdir: local real list f …`, `_snap_nested: local d real list f g`, `_snap_glob_re: local … i …`, `_snap_match: local … k u p`, `_snap_inside_ws: local r`), so the walk cannot move the worklist's indexes (paraphrased — no quote available because invariant inferred from the `local` lines of eleven functions).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:158-163`, `devcontainer-config/cc-exit-scan.sh:318`, `devcontainer-config/cc-exit-scan.sh:445`, `devcontainer-config/cc-exit-scan.sh:475`, `devcontainer-config/cc-exit-scan.sh:531`, `devcontainer-config/cc-exit-scan.sh:679`, `devcontainer-config/cc-exit-scan.sh:697`, `devcontainer-config/cc-exit-scan.sh:780-784`

---

## Claim 7: "Caps on the insteadOf pass …: bytes in one URL, rule base or value (_snap_key); pairs compared (_snap_pairs_ok); rewritten URLs to walk, each a few forks (_snap_match). Over any of them the snapshot fails (fail closed)." with values 4096 / 100000 / 2000.

**Location:** `devcontainer-config/cc-exit-scan.sh:390-396`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer (code comment)
**Scope:** Covers the constants and which function enforces each; does not establish that the per-string byte cap also applies to rewritten targets (it does not; they can reach base + rest, ≤ 8,192 bytes, unchecked by design).

```bash
# devcontainer-config/cc-exit-scan.sh:394-396
GIT_EXIT_SCAN_MAX_REWRITE_BYTES=4096
GIT_EXIT_SCAN_MAX_REWRITE_PAIRS=100000
GIT_EXIT_SCAN_MAX_REWRITE_TARGETS=2000
```

`_snap_key … check` also caps the URL's working tree (`"${#2}"` is the working tree for `_snap_url`, `:405`), which the message names. Executed via the bats cap test and P6/P7 (`$P/scan-probe.log`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:390-408`, `devcontainer-config/cc-exit-scan.sh:429-458`, `$P/scan-probe.log`, `$P/bats-q096.log`

---

## Claim 8: "_snap_key <a> <b> [check]: _snap_k, a key for the pair prefixed by <a>'s length in bytes (LC_ALL=C; characters collide), so no byte can join two pairs. With <check>, fail when <a> or <b> is over GIT_EXIT_SCAN_MAX_REWRITE_BYTES."

**Location:** `devcontainer-config/cc-exit-scan.sh:398-408`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer (code comment)
**Scope:** Covers collision-freedom of `<len(a)>:<a><b>` within one tag (u:, r:, t:) and the byte measure; does not establish anything about keys across tags (they are prefixed, `:414`, `:424`, `:467`).

```bash
# devcontainer-config/cc-exit-scan.sh:401-408
_snap_key() {
  local LC_ALL=C
  _snap_k="${#1}:$1$2"
  [ -n "${3:-}" ] || return 0
  [ "${#1}" -gt "$GIT_EXIT_SCAN_MAX_REWRITE_BYTES" ] || [ "${#2}" -gt "$GIT_EXIT_SCAN_MAX_REWRITE_BYTES" ] || return 0
  _snap_fail 'a remote URL, its working tree or an insteadOf rule over %s bytes (%s and %s): too long to compare, treat the checkout as unsafe' \
    "$GIT_EXIT_SCAN_MAX_REWRITE_BYTES" "${#1}" "${#2}"
}
```

Given the byte length of `<a>`, `<a>` and `<b>` are recovered uniquely, so distinct pairs give distinct keys. Executed: removing `local LC_ALL=C` makes "rules whose characters, not bytes, line up are kept apart" fail (`$P/mut3.log`); the tab test passes (`$P/bats-q096.log`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:398-408`, `$P/mut3.log`, `$P/bats-q096.log`

---

## Claim 9: "_snap_url <url> <working tree>: a remote URL git may push to. Walked now (_snap_remote) and queued for the insteadOf rules (_snap_match), once each." / "_snap_rule … git rewrites a URL starting with <value> to <base> + the rest."

**Location:** `devcontainer-config/cc-exit-scan.sh:410-427`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** maintainer (code comment)
**Scope:** Covers dedupe on (url, working tree) and (base, value) and the walk-then-queue order; does not establish that git would push to every queued URL (pooled across repos, over-approximate by design).

Quoted in Claim 1 (`:412-418`); `_snap_rule` dedupes on `r:$_snap_k` and appends to `_snap_rbases`/`_snap_rpfx` (`:422-427`). The rewrite `<base> + rest` is done at `_snap_hit_t+=("${_snap_rbases[ri]}${u:${#p}}")` (`:454`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:410-427`, `devcontainer-config/cc-exit-scan.sh:454`

---

## Claim 10: "git's alias_url compares bytes (case-sensitive; an empty value matches every URL), so the match and the cut run under LC_ALL=C: in a UTF-8 locale ${#p} counts characters, and a value ending mid-character would cut the URL in the wrong place."

**Location:** `devcontainer-config/cc-exit-scan.sh:437-458`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer (code comment)
**Scope:** Covers git's byte-wise, case-sensitive, empty-matches-all prefix test and the scan's equivalent; does not establish git's longest-match selection (the scan deliberately walks all: Claim 13).

```bash
# devcontainer-config/cc-exit-scan.sh:444-458
_snap_match() {
  local LC_ALL=C ui="$1" ri="$2" n="$3" k u p
  for ((k = 0; k < n; k++)); do
    u="${_snap_urls[ui]}"; p="${_snap_rpfx[ri]}"
    if [[ "$u" == "$p"* ]]; then
      if [ $((_snap_rwt + ${#_snap_hit_t[@]})) -ge "$GIT_EXIT_SCAN_MAX_REWRITE_TARGETS" ]; then
        _snap_fail '…' …
        return 1
      fi
      _snap_hit_t+=("${_snap_rbases[ri]}${u:${#p}}"); _snap_hit_b+=("${_snap_ubases[ui]}")
    fi
    if [ "$4" = 0 ]; then ri=$((ri + 1)); else ui=$((ui + 1)); fi
  done
}
```

Executed against git 2.39.5 (`$P/git-semantics.log`): case 2, empty value matched `zz/x` (hook `x` under `e-zz/` ran); case 4, `HTTPS://` rule left `https://cs.invalid/repo` unchanged; P8 (`$P/scan-probe.log`), under `LC_ALL=C.utf8` git's push URL for `\xc3\xa9vil` with value `\xc3` is `…/x-\251vil` (cut after the byte). The quoted `"$p"` makes glob characters literal: rule values `*` and `?b` did not rewrite `abc` (`$P/p3.log`). Mutation: dropping `LC_ALL=C` here fails the byte-wise test (`$P/mut2.log`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:437-458`, `$P/git-semantics.log`, `$P/scan-probe.log`, `$P/p3.log`, `$P/mut2.log`

---

## Claim 11: "_snap_walk_hits: walk each rewritten URL _snap_match found, like any remote, once; never queued as a URL (git rewrites once), and walking adds no hits."

**Location:** `devcontainer-config/cc-exit-scan.sh:460-471`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer (code comment)
**Scope:** Covers dedupe on (target, working tree), no re-queue, and that the walk's callees never append to `_snap_hit_t`; does not establish that `_snap_rwt` counts distinct targets (it counts every hit: Claim 15).

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

Only the main loop assigns `_snap_hit_t` (`:454` append inside `_snap_match`, `:844`/`:850` reset); the walk can add URLs and rules (through `_snap_gitdir` → `_snap_config` → `_snap_url`/`_snap_rule`) but no hits (paraphrased — no quote available because the claim covers absence of other writers: grep of `_snap_hit_t` gives only those lines). Git does not chain: `$P/git-semantics.log` case 3, `aa:x` → `$W/b-x` with a rule mapping `$W/b-` onward, only `b-x`'s hook ran.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:460-471`, `devcontainer-config/cc-exit-scan.sh:844-851`, `$P/git-semantics.log`

---

## Claim 12: "Walking one can reach configs that name more, hence the growing indexes: a new URL meets the rules already seen, a new rule meets the URLs already seen, so each pair meets once."

**Location:** `devcontainer-config/cc-exit-scan.sh:830-856`
**Type:** Invariant / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer (code comment)
**Scope:** Covers exactly-once comparison of every (URL, rule) pair including those found while walking, and fail-closed exits; does not establish that the host config is read for git dirs reached only by walking a remote (pre-existing: it is read for the checkout and embedded `.git` entries, `:814`, `:827`).

```bash
# devcontainer-config/cc-exit-scan.sh:834-856
  i=0 u=0 r=0
  while [ "$rc" -eq 0 ]; do
    if [ "$i" -lt "${#_snap_names[@]}" ]; then
      …
      [ -z "$f" ] || [ -n "${_snap_rnames["$f"]:-}" ] || _snap_url "$f" "$g" || rc=1
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
    else
      break
    fi
  done
```

(excerpt elides `:837-839`, the name/base fetch — read.) Invariant: the compared set is always [0,u) × [0,r); the URL step adds {u} × [0,r), the rule step [0,u) × {r}, so no pair is compared twice or skipped, and the loop ends only when u and r reach the (grown) array lengths. Executed (`$P/scan-probe.log`): P1, a rule found only in a rewritten target's config applied to the earlier URL → `status=1 FOUND`; P2, a URL found only in a rewritten target met the earlier rule → `status=1 FOUND`. Pair charging: in the bats cap test (1 URL, 2 rules, cap 1) the third batch trips at 2 (`$P/bats-q096.log`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:830-858`, `$P/scan-probe.log`, `$P/bats-q096.log`

---

## Claim 13: "alias_url(url, rewrites): among every insteadOf value that is a prefix of url (plain starts_with, case-sensitive; an empty value matches everything), the longest wins … Applied once, never chained. remote.<n>.pushurl values are rewritten with insteadOf. When a remote has no pushurl, each remote.<n>.url is also rewritten with pushInsteadOf into an implicit pushurl." (also the plan's B2/B3/B4/B16 and the guide's "git uses only the longest matching rule")

**Location:** `docs/working/research-q096-exit-scan-insteadof-target.md:20-23`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** next agent / reviewer (research doc), user (guide `:326`)
**Scope:** Covers git 2.39.5's push behavior for longest prefix, empty value, case, no chaining, pushInsteadOf vs pushurl; does not establish other git versions' behavior.

`$P/git-semantics.log` (git 2.39.5): case 1 `HOOK:long-po` only (longest wins); case 3 `HOOK:b-x` (no chaining); case 4 URL unchanged (case-sensitive); case 5a `HOOK:pi-repo` (pushInsteadOf on url without pushurl); case 5b with a pushurl `HOOK:pu-repo` and the pushInsteadOf rule matching the pushurl not applied; case 6 `HOOK:io-repo` (insteadOf on url when no pushurl and no pushInsteadOf); case 8 when both kinds match a url without pushurl, push went to `bothP-repo`. The scan applies both kinds to every URL (`:516-521`, `:616`), a superset of each case.

**Evidence:** `docs/working/research-q096-exit-scan-insteadof-target.md:20-26`, `devcontainer-config/cc-exit-scan.sh:516-522`, `$P/git-semantics.log`

---

## Claim 14: "Status: done"

**Location:** `docs/working/briefs/2026-10-02-exit-scan-insteadof-target.md:3`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** dev-cycle orchestrator (brief)
**Scope:** Covers the status line; does not establish that the brief's every acceptance item is met beyond the claims in this report.

`Status: done` at `:3` (grep output).

**Evidence:** `docs/working/briefs/2026-10-02-exit-scan-insteadof-target.md:3`

---

## Claim 15: "GIT_EXIT_SCAN_MAX_REWRITE_TARGETS (2,000 distinct rewritten URLs)"

**Location:** `docs/working/plan-q096-exit-scan-insteadof-target.md:27`
**Type:** Configuration
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** next agent / reviewer (plan doc, bypass row B14)
**Scope:** Covers what the target cap counts; does not establish any bypass (counting more than distinct only fails closed earlier).

The cap counts every URL-and-rule match before dedupe: `_snap_match` checks `_snap_rwt + ${#_snap_hit_t[@]}` per hit (`:449`) and `_snap_walk_hits` increments `_snap_rwt=$((_snap_rwt + 1))` before the `t:` dedupe check (`:465-467`). Executed: P7 (`$P/scan-probe.log`), two URLs `a:x`, `b:x` and two rules both rewriting to the one target `$WS/T-x`, cap 1 → `more than 1 URLs rewritten by insteadOf rules to walk (2 URLs, 2 rules so far)`: one distinct target, refused. The guide (`guides/cc-isolated-usage.md:349-350`, "one per URL-and-rule match") and 03bc47c9's message are right; this plan row was not updated. Fix: "2,000 URL-and-rule matches (before dedupe)".

**Evidence:** `docs/working/plan-q096-exit-scan-insteadof-target.md:27`, `devcontainer-config/cc-exit-scan.sh:449`, `devcontainer-config/cc-exit-scan.sh:465-467`, `$P/scan-probe.log`

---

## Claim 16: "an empty prefix is a match" (B15), "every `read` in `cc-exit-scan.sh` runs as `LC_ALL=C IFS= read`" (B25), "`_snap_match` checks the target cap per hit" (B28)

**Location:** `docs/working/plan-q096-exit-scan-insteadof-target.md:28-40`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** next agent / reviewer (plan doc)
**Scope:** Covers rows B15, B22, B23, B25, B26, B27, B28 against HEAD; does not establish rows B24/B29 (split to fix/q096b-exit-scan-remote-names, not re-checked here).

The per-hit check is inside the `[[ "$u" == "$p"* ]]` branch (Claim 10's quote, `:448-453`); empty prefix and byte-wise behavior executed in Claim 10; reads in Claim 5; keys in Claim 8; the byte cap in Claim 4 (P6).

**Evidence:** `docs/working/plan-q096-exit-scan-insteadof-target.md:28-40`, `devcontainer-config/cc-exit-scan.sh:444-458`, `$P/mut.log`, `$P/mut2.log`, `$P/mut3.log`

---

## Claim 17: "No uncovered family needs a design change" and the bypass table's "covered" rows (brief claim 7: no remaining way, in the insteadOf pass, for a hostile session to make host git push to a repository it controls without a finding)

**Location:** `docs/working/plan-q096-exit-scan-insteadof-target.md:44`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** reviewer / user (plan pre-mortem)
**Scope:** Covers the insteadOf pass for the families probed (B1-B16, B21-B23, B25-B28 plus discovery-order P1/P2, glob literals, your include files, and a valueless `insteadOf` key which the scan treats as an empty value, a superset of git, which refuses that config); does not establish the split remote-name family (B29, a listed known route), URLs typed on the command line (B20, listed), `~` targets (B18, listed), or exhaustiveness against unprobed git features.

No route found. Every family named was either executed (bats 11/11, `$P/scan-probe.log` P1-P8, `$P/p3.log`) or traced statically to an over-approximating rule: every URL × every rule from every config read (paraphrased — no quote available because the conclusion spans `_snap_config`, `_snap_host_config`, `_snap_gitdir` and the main loop, quoted in Claims 1, 2, 10, 12).

**Evidence:** `docs/working/plan-q096-exit-scan-insteadof-target.md:12-44`, `devcontainer-config/cc-exit-scan.sh:412-471`, `devcontainer-config/cc-exit-scan.sh:830-858`, `$P/scan-probe.log`, `$P/bats-q096.log`

---

## Claim 18: "The cap case sets `GIT_EXIT_SCAN_MAX_REWRITES` low and expects the snapshot to fail with "too many"."

**Location:** `docs/working/plan-q096-exit-scan-insteadof-target.md:77`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Legibility-target:** next agent (plan test specification)
**Scope:** Covers the variable name and expected outcome in the test spec; does not establish anything else in that paragraph (the hook/`no_ran` shape is still right).

`GIT_EXIT_SCAN_MAX_REWRITES` no longer exists (renamed in e4b29291; grep of the script and test finds only `_REWRITE_BYTES`, `_REWRITE_PAIRS`, `_REWRITE_TARGETS`, `:394-396`). The test sets all three and checks `git_exit_scan` status 2, with the byte cap's message "too long to compare", not "too many" (`test/cc-isolated-functions.bats:2270-2291`, quoted in the diff: `GIT_EXIT_SCAN_MAX_REWRITE_PAIRS=1` … `[ "$status" -eq 2 ]` … `*"an insteadOf rule over 10 bytes ("*"): too long to compare"*`).

**Evidence:** `docs/working/plan-q096-exit-scan-insteadof-target.md:77`, `devcontainer-config/cc-exit-scan.sh:394-396`, `test/cc-isolated-functions.bats:2270-2291`

---

## Claim 19: "Each of those remote URLs, local or not, and each remote.*.url/pushurl in your own config, is also rewritten by every url.<base>.insteadOf and pushInsteadOf rule whose value it starts with — from any config the scan reads, your own global and system config included — and the rewritten URL is walked the same way: git uses only the longest matching rule, the scan walks every match."

**Location:** `guides/cc-isolated-usage.md:321-326`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user (guide)
**Scope:** Covers remote URLs (config, legacy files, path-valued names) and your remote URLs against every rule; does not establish that the insteadOf bases in the preceding list are rewritten (they are not, matching git's no-chaining).

Executed by the bats tests (overlapping prefixes walk both; your global rule; your own remote rewritten by a repo rule; embedded repo) in `$P/bats-q096.log`, and Claims 1, 12, 13. Legacy remotes URLs are queued too (`_snap_url` at `:731`, `:734`), which the sentence's list does not name but the follow list's own scope leaves implicit.

**Evidence:** `guides/cc-isolated-usage.md:318-326`, `devcontainer-config/cc-exit-scan.sh:731-734`, `$P/bats-q096.log`

---

## Claim 20: "Those, your insteadOf rules and your remote URLs are the only entries of your own config it follows; none is recorded."

**Location:** `guides/cc-isolated-usage.md:332-333`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user (guide)
**Scope:** Same as Claim 2 (no C records for your entries); does not establish that a walked local target of your remote URL leaves no F/W record (it does: Claim 21).

See Claim 2's quote of `:614-619` and P5.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:600-641`, `$P/scan-probe.log`

---

## Claim 21: "…and so do a remote URL or insteadOf rule over 4,096 bytes, more than 100,000 URL-and-rule comparisons, or more than 2,000 rewritten URLs to walk (one per URL-and-rule match). (At launch any of these refuses the launch instead, exit 1.)"

**Location:** `guides/cc-isolated-usage.md:346-350`
**Type:** Configuration / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user (guide)
**Scope:** Covers the three caps, their units and exit statuses (exit 4 at exit via the paragraph's "fails the scan (exit 4…)", exit 1 at launch); does not establish the working-tree half of the byte cap (a working tree over 4,096 bytes also fails; the message names it, the guide does not).

Units verified in Claims 7, 12, 15 (P7: one per match); exit statuses in Claim 4.

**Evidence:** `guides/cc-isolated-usage.md:342-350`, `devcontainer-config/cc-exit-scan.sh:401-458`, `devcontainer-config/cc-isolated.sh:932-952`, `$P/scan-probe.log`, `$P/bats-q096.log`

---

## Claim 22: "…a relative local remote (a remote of `.` is fine; an `insteadOf` base of `.` or `""` is not, nor a remote any `insteadOf` rule, yours included, rewrites to a relative path), which git would resolve in the new worktree's tree, unscanned."

**Location:** `guides/cc-isolated-usage.md:376-381`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user (guide)
**Scope:** Covers the W-record sources the guide lists for the worktree note; does not establish other refusals.

Right for the listed sources (bats "a relative one refuses the worktree note"). Missing the same source as Claim 3: a relative `remote.*.url` in your own config (new on this branch, `:617`) also refuses the note (P4, `W	remote	sub/x`). The paragraph names only your relative `core.hooksPath`/`core.attributesFile` for your own config (`:381-383`).

**Evidence:** `guides/cc-isolated-usage.md:374-384`, `devcontainer-config/cc-exit-scan.sh:376`, `devcontainer-config/cc-exit-scan.sh:617`, `$P/scan-probe.log`

---

## Claim 23: "…at the `insteadOf` caps, rewritten URLs alone add 10-80 s (a WSL2 host; the most when each is a planted repository)."

**Location:** `guides/cc-isolated-usage.md:418-420`
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** user (guide)
**Scope:** Covers the order of magnitude at the target cap on this WSL2-kernel container; does not establish timings on other hosts or under load (load average ~1.9-2.4 during the run).

`$P/timing-probe.log` (1,999 https remotes, 16 CPUs): no rule 1.23 s; one rule rewriting each to a missing local target 9.95 s (+8.7 s); each target a planted bare repo 60.35 s (+59.1 s). Both within 10-80 s (the low end is just under 10 s added; "10" is a fair rounding).

**Evidence:** `guides/cc-isolated-usage.md:414-420`, `$P/timing-probe.log`

---

## Claim 24: "Remote names and legacy remote files, read loosely. … a legacy URL's spaces or CR (trimmed differently, also by locale) …"

**Location:** `guides/cc-isolated-usage.md:421-427`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** user (guide, known route)
**Scope:** Covers the "also by locale" trim (executed) and that the family is listed; does not re-check the family's other items (split unit, not re-filed per the brief).

`$P/locale-probe.log`: the trim `"${line#"${line%%[![:space:]]*}"}"` (`:734`) strips U+2028 and U+00A0 under `C.utf8` but not under `C` (`legacy=x` vs `legacy=$'\342\200\250x'`); git's own trim is ASCII-only. Values change, entries are not dropped or merged. This is the only locale-dependent slicing of container bytes found outside `read`; the rule-base and remote-name cuts (`${t%.*}`, `${key#url.}`) gave identical results under both locales for the invalid-UTF-8 cases probed.

**Evidence:** `guides/cc-isolated-usage.md:421-427`, `devcontainer-config/cc-exit-scan.sh:734`, `$P/locale-probe.log`

---

## Claim 25: "`~` forms … a `~` in a local remote URL (or one an `insteadOf` rule rewrites to) are taken as relative paths" / "A URL you type … the scan only sees URLs in config and legacy remotes files."

**Location:** `guides/cc-isolated-usage.md:453-459`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** user (guide, known routes)
**Scope:** Covers `_snap_remote`'s handling of a `~` target and the sources of queued URLs; does not establish git's own `~` expansion details.

`_snap_remote` has no `~` case: `case "$p" in /*) ;; *) p="$base/$p" ;; esac` (`:377`). URL sources are only `_snap_url` callers at `:514`, `:617`, `:731`, `:734`, `:840` (paraphrased — no quote available because grep of `_snap_url "` lists those five call sites).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:365-388`, `devcontainer-config/cc-exit-scan.sh:514`, `devcontainer-config/cc-exit-scan.sh:617`, `devcontainer-config/cc-exit-scan.sh:731-734`, `devcontainer-config/cc-exit-scan.sh:840`

---

## Claim 26: "More than GIT_EXIT_SCAN_MAX_REWRITES (100,000) comparisons fails the snapshot closed." (commit 5f754994)

**Location:** commit 5f754994 message
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Legibility-target:** reviewer (commit history)
**Scope:** Covers the variable name at HEAD; does not establish the rest of 5f754994's message (its test list and "All eight fail on the pre-fix scan" were not re-run).

Renamed to `GIT_EXIT_SCAN_MAX_REWRITE_PAIRS` and joined by two caps (`:394-396`); e4b29291's message records the rename. Historical message; no action.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:394-396`

---

## Claim 27: "New GIT_EXIT_SCAN_MAX_REWRITE_TARGETS (2,000 distinct rewritten URLs)" and "The 2,000-target cap counts every distinct rewritten URL, local or not." (commit e4b29291)

**Location:** commit e4b29291 message
**Type:** Configuration
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** reviewer (commit history)
**Scope:** Covers the cap's unit; does not establish the rest of e4b29291 (its B24 no-url fix was later removed by 013f1b3d, which says so).

Same mechanism as Claim 15 (counts matches before dedupe, P7). 03bc47c9 corrects the same error in 4d7f966c by name but not this message's "distinct"; the plan row (Claim 15) carries it forward. Historical message; the live fix is the plan row.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:449`, `devcontainer-config/cc-exit-scan.sh:465-467`, `$P/scan-probe.log`

---

## Claim 28: "the 2,000 cap counts URL-and-working-tree targets" (commit 4d7f966c) and "the legacy-URL half proved the same read path" (commit 013f1b3d)

**Location:** commits 4d7f966c and 013f1b3d messages
**Type:** Configuration / Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** reviewer (commit history)
**Scope:** Covers the two statements at the commits that made them; does not establish anything about HEAD's test set beyond Claim 29 (both are already acknowledged as wrong in 03bc47c9).

Both are refuted and both are named as wrong in 03bc47c9's own message. The first: P7 (Claim 15). The second: the here-string read at `:729` is a different read than the hook-list read; with the legacy half restored, removing its `LC_ALL=C` fails the test (`$P/mut.log`), so the hook half alone did not prove it. Historical; already corrected.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:729`, `$P/mut.log`, `$P/scan-probe.log`

---

## Claim 29: "193/193", "Unit size 395 changed lines outside docs/", and "dropping LC_ALL=C from that read fails it" (commit 03bc47c9)

**Location:** commit 03bc47c9 message
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** reviewer (commit history)
**Scope:** Covers the test count, the line count outside docs/ and the mutation statement; does not establish the "40k remotes: 55 s vs 30 s" timing (not re-run).

`$P/bats-full.log`: `1..193`, 193 `ok`, exit 0. `git diff --stat main...HEAD -- . ':!docs/reviews'`: cc-exit-scan.sh 190 + guide 39 + test 166 = 395 outside docs/. Mutation: `$P/mut.log` (fails at line 2242).

**Evidence:** `$P/bats-full.log`, `$P/mut.log`, `devcontainer-config/cc-exit-scan.sh:729`

---

## Claims Requiring Attention

### Incorrect
- **Claim 15** (`docs/working/plan-q096-exit-scan-insteadof-target.md:27`): B14 says the target cap is "2,000 distinct rewritten URLs"; it counts URL-and-rule matches before dedupe (P7: one distinct target refused at cap 1). Change to "2,000 URL-and-rule matches". The only live (fixable) Incorrect.
- **Claim 27** (commit e4b29291): "distinct rewritten URLs" — same miscount; historical, not corrected by name in 03bc47c9.
- **Claim 28** (commits 4d7f966c, 013f1b3d): cap unit and "legacy-URL half proved the same read path" — both already named as wrong in 03bc47c9; no action.

### Stale
- **Claim 18** (`docs/working/plan-q096-exit-scan-insteadof-target.md:77`): test spec names `GIT_EXIT_SCAN_MAX_REWRITES` and "snapshot fails with too many"; the test sets three `_REWRITE_*` caps and checks `git_exit_scan` status 2, one message "too long".
- **Claim 26** (commit 5f754994): `GIT_EXIT_SCAN_MAX_REWRITES` renamed in e4b29291; historical.

### Mostly Accurate
- **Claim 1** (`devcontainer-config/cc-exit-scan.sh:61-65`): "Each of those URLs" points at the local-path list, which includes insteadOf bases (never rewritten) and excludes non-local URLs (the main case, which is queued). Say "every remote URL the scan meets, local or not (not the insteadOf bases)".
- **Claim 3** (`devcontainer-config/cc-exit-scan.sh:87-94`): W-record sources omit a relative `remote.*.url` in your own config, which this branch now walks and which refuses the worktree note (P4).
- **Claim 22** (`guides/cc-isolated-usage.md:376-381`): same omission as Claim 3 in the guide.

### Unverifiable
- None.

---

## Goal-Alignment Note

Goal: the exit scan must walk the URL an `insteadOf`/`pushInsteadOf` rule rewrites a remote to, so a session cannot repoint a push through a rewrite the scan ignores. The code at 03bc47c9 does this, executed against git 2.39.5: every URL the scan meets (config, legacy files, path-valued names, your own remotes) meets every rule from every config it reads, exactly once, including URLs and rules found only while walking a rewritten target (P1, P2); every match is walked (a superset of git's longest match and of its pushInsteadOf/pushurl choice); matching is byte-wise and case-sensitive like git's; keys are collision-free; all three caps and every new failure path fail closed (snapshot 1 → `git_exit_scan` 2 → launcher 4; launch 1). No route was found in the insteadOf pass (Claim 17). Nothing here blocks the goal: the one live Incorrect (Claim 15) and the Stale test spec (Claim 18) are plan-doc text, and the three Mostly-accurate items are wording; Claims 3/22 describe a fail-closed refusal the docs leave out, not a gap. Escalations: none.
