Commit: 5f754994

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-q096 (branch fix/q096-exit-scan-insteadof-target)
**Scope:** branch diff `git diff main...HEAD` (main b279a2ba .. HEAD 5f754994): devcontainer-config/cc-exit-scan.sh, docs/working/plan-q096-exit-scan-insteadof-target.md, docs/working/research-q096-exit-scan-insteadof-target.md, guides/cc-isolated-usage.md, test/cc-isolated-functions.bats, plus the HEAD commit message
**Checked:** 2026-10-15
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 19
**Summary:** 16 verified, 2 mostly accurate, 0 stale, 1 incorrect, 0 unverifiable

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) read before checking. Its five entries are all count or denominator claims (test tallies, corpus sizes, golden counts) plus one consumer-reference entry. The one test-count claim here (Claim 17, "All eight") was checked against that pattern by running it. It holds: the suite has eight new tests and all eight fail on the pre-fix scan.

Execution environment for every `executed` claim: git 2.39.5, bash, bats. Each run was hermetic, with `GIT_CONFIG_GLOBAL` pointed at a file in the probe dir and `GIT_CONFIG_NOSYSTEM=1`. Scratch repos are under `/home/node/.claude/jobs/00bcf178/tmp/q096/probe-factcheck/`, which is called `$PF` below. Captured output is in `$PF/logs/`. No background processes were started.

Probe runs (cwd `$PF` unless noted):

| Run | Command | Exit | Timestamp (UTC) | Output |
|---|---|---|---|---|
| R1 git semantics | `bash exp-git.sh "$PWD/exp-git"` | 0 | 2026-10-15T07:28:12Z | `$PF/logs/exp-git.log` |
| R2 bats post-fix | `cd postfix && LC_ALL=C timeout 600 bats -f 'Q-096' test/cc-isolated-functions.bats` (postfix = copy of the worktree's devcontainer-config/ and test/) | 0 | 2026-10-15T07:28:40Z | `$PF/logs/bats-postfix.log` |
| R3 bats pre-fix | same, in `prefix/` with `cc-exit-scan.sh` = `git show main:devcontainer-config/cc-exit-scan.sh` (diff-checked) | 1 | 2026-10-15T07:28:40Z | `$PF/logs/bats-prefix.log` |
| R4 worklist/host/cap | `LC_ALL=C timeout 300 bash exp-worklist.sh "$PWD/exp-worklist" "$PWD/postfix/devcontainer-config/cc-exit-scan.sh"` | 0 | 2026-10-15T07:29:18Z | `$PF/logs/exp-worklist.log` |
| R5 host-defined remote (git side) | `bash exp-hostremote.sh "$PWD/exp-worklist"` | 0 | ~2026-10-15T07:30Z | `$PF/logs/exp-hostremote.log` |
| R6 live-verify-gate | `bash run-lvg.sh` (runs `bats -f 'host-tool commit needs Host-tool-tested' test/hooks/live-verify-gate.bats`) | 0 | 2026-10-15T07:30:35Z | `$PF/logs/bats-lvg.log` |
| R7 pushRemote | `bash exp-pushremote.sh "$PWD/exp-pushremote"` | 0 | 2026-10-15T07:31:12Z | `$PF/logs/exp-pushremote.log` |

---

## Claim 1: "Each of those URLs is also rewritten by every url.<base>.insteadOf / pushInsteadOf rule whose value prefixes it (in any config read here, yours included ...), and the result walked the same way."

**Location:** `devcontainer-config/cc-exit-scan.sh:60-64`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers remote.*.url/pushurl, legacy remotes/branches URLs and path-valued branch/pushDefault names in any repo config the scan reads, rewritten by rules from repo configs, includes, embedded repos and your global config; does not establish that remotes defined in YOUR global/system config are rewritten (they are not: see Claim 16), nor that git would apply each pooled rule to that URL.

Every URL source now goes through `_snap_url`: `remote.*.url|remote.*.pushurl) _snap_url "$val" "$base" || return 1 ;;` (`cc-exit-scan.sh:463`), the legacy files at `cc-exit-scan.sh:679` and `:682` (`_snap_url "${line%%#*}" ...`, `_snap_url "${line#...}" ...`), and unresolved names at `cc-exit-scan.sh:787` (`... || _snap_url "$f" "$g" || rc=1`). Rules come from `_snap_config` (`_snap_rule "$t" "$val"`, `:469`) and `_snap_host_config` (`url.*.insteadof|url.*.pushinsteadof) t="${key#url.}"; _snap_rule "${t%.*}" "$val" ;;`, `:564-565`). Each match is walked with `_snap_remote "$t" "${_snap_ubases[$1]}"` (`:420`). R2 ran all eight Q-096 bats tests against the post-fix scan and all passed. They cover a top-level rewrite, pushInsteadOf, a pushurl rewritten by insteadOf, overlapping prefixes, a path-valued pushRemote, an embedded repo and a global rule. R4 W4 shows a rule from the global config being applied.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:383-421`, `:463`, `:465-471`, `:563-566`, `:679-682`, `:777-798`; `$PF/logs/bats-postfix.log`; `$PF/logs/exp-worklist.log`

---

## Claim 2: "git takes only the longest, the scan walks them all"

**Location:** `devcontainer-config/cc-exit-scan.sh:63-64`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers git 2.39.5's longest-prefix choice among matching insteadOf values and the scan walking every matching rule; does not establish git's tie-break between equal-length values (R1 E12: the rule configured first wins), which the scan makes moot by walking both.

R1 E2 set up overlapping rules `https://ex.invalid/` (two bases) and `https://ex.invalid/re` on remote `https://ex.invalid/repo`. git ran only `long-po`'s pre-receive hook (`ran: long-po`). On the scan side, `_snap_rewrite` is called for every (URL, rule) pair and walks every match: `[[ "$u" == "$p"* ]] || return 0` (`cc-exit-scan.sh:414`), then `_snap_remote` (`:420`). There is no longest-match selection anywhere. Bats test "overlapping prefixes" (R2 ok 3) requires both `short-repo` and `long-po` hooks to be reported, and it fails pre-fix (R3 not ok 3).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:406-421`; `$PF/logs/exp-git.log` (E2, E12); `$PF/logs/bats-postfix.log`; `$PF/logs/bats-prefix.log`

---

## Claim 3: "A relative core.hooksPath, core.attributesFile or local remote (a remote of "." excepted, but not an insteadOf base of "." or "", nor a remote any insteadOf rule rewrites to a relative path) in repo config ... leave W records, and any W record refuses the note."

**Location:** `devcontainer-config/cc-exit-scan.sh:85-91`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers a rewritten target that is relative (not `.`, not absolute, not `~/`), whether from a repo rule or your global rule, leaving a `W remote` record that refuses the standard-worktree note; does not establish behaviour for a rewritten target of exactly `.` (no W, matching the stated "remote of "." excepted") or a target beginning `~/` (excluded by `_snap_wrel`).

The rewritten target goes through `_snap_remote`, which runs `[ "$p" = . ] || _snap_wrel remote "$p" "$p"` (`cc-exit-scan.sh:367`). `_snap_wrel` returns early only for `""|/*|"~/"*` (`:302`). R4 W9 used repo rule `url.sub/.insteadOf https://a.invalid/` and got both `W	remote	sub/` (from the base) and `W	remote	sub/x` (from the rewritten target). Bats test 7 (R2 ok 7) used your global rule `url.vendor/.insteadOf x:` with remote `x:r.git` plus a new standard worktree, and got the full warning instead of the note (`warns_listing_wt`). Pre-fix that same assertion fails (R3: `warns_listing_wt' failed`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:300-305`, `:356-381`, `:420`; `$PF/logs/exp-worklist.log` (W9); `$PF/logs/bats-postfix.log`; `$PF/logs/bats-prefix.log`

---

## Claim 4: "_snap_url <url> <working tree>: a remote URL git may push to. Walked now (_snap_remote) and queued for the insteadOf rules (_snap_rewrite), once each."

**Location:** `devcontainer-config/cc-exit-scan.sh:381-382`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers deduplication per (URL, working tree) pair and the immediate `_snap_remote` walk; does not establish that the same URL string is walked only once across different working trees (it is walked once per tree, which is intended).

```bash
# devcontainer-config/cc-exit-scan.sh:383-389
_snap_url() {
  local k="u:$1"$'\t'"$2"
  [ -z "${_snap_rwseen["$k"]:-}" ] || return 0
  _snap_rwseen["$k"]=1
  _snap_urls+=("$1"); _snap_ubases+=("$2")
  _snap_remote "$1" "$2"
}
```

The function returns `_snap_remote`'s status, and every caller checks it with `|| return 1` or `|| rc=1`.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:383-389`, `:463`, `:679`, `:682`, `:787`

---

## Claim 5: "when the rule's value prefixes the URL (git's alias_url: plain, case-sensitive; an empty value matches every URL)"

**Location:** `devcontainer-config/cc-exit-scan.sh:399-401`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers git 2.39.5's plain, case-sensitive prefix match, the empty value matching (repo config and global config), and the scan's matching `[[ ... == "$p"* ]]`; does not establish behaviour under a shell with `nocasematch` set (the sourcing launcher does not set it, which was not exhaustively checked).

On the git side, R1 E7 used rule value `HTTPS://C.INVALID/` against URL `https://c.invalid/repo` and nothing ran. R1 E3 used rule value `""`, and `git remote get-url --push o` printed `<P>/empty-https://ex.invalid/repo`, so the empty value rewrote the URL (git then rejected the result as an unsupported protocol). On the scan side, `[[ "$u" == "$p"* ]] || return 0` (`cc-exit-scan.sh:414`) is a quoted literal prefix test, so an empty `$p` always matches. R4 W4 used global `[url "<W>/e-"] insteadOf =` with remote `hx:repo` and got record `remote <W>/e-hx:repo`.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:406-421`; `$PF/logs/exp-git.log` (E3, E7); `$PF/logs/exp-worklist.log` (W4)

---

## Claim 6: "A rewritten URL is never queued as a URL: git rewrites once."

**Location:** `devcontainer-config/cc-exit-scan.sh:402-403`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers a chain of two rules (a to b, then b to local) on a remote URL, for git and for the scan; does not establish whether git re-aliases URLs typed on the command line (not config, outside the scan).

R1 E4 set up `url.https://b.invalid/.insteadOf https://a.invalid/` and `url.<P>/chainB-.insteadOf https://b.invalid/` on remote `https://a.invalid/repo`. git ran no hook, so it did not chain. On the scan side, `_snap_rewrite` hands the target only to `_snap_remote` (`cc-exit-scan.sh:420`) and never appends it to `_snap_urls`. R4 W5 used the same chain and got `NO : remote <W>/c-x`.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:406-421`; `$PF/logs/exp-git.log` (E4); `$PF/logs/exp-worklist.log` (W5)

---

## Claim 7: "Past GIT_EXIT_SCAN_MAX_REWRITES comparisons the snapshot fails (a session can plant thousands of URLs and rules to stall it)."

**Location:** `devcontainer-config/cc-exit-scan.sh:403-405`
**Type:** Configuration / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the comparison counter (one count per URL-rule pair, matching or not), failure on the comparison after the cap, `git_exec_snapshot` returning 1, and `git_exit_scan` returning 2; does not establish an environment override (the constant is set when the file is sourced, so an exported value is overwritten, as R4 W7 shows; nothing claims otherwise).

The counter and fail path:

```bash
# devcontainer-config/cc-exit-scan.sh:408-413
  _snap_rwn=$((_snap_rwn + 1))
  if [ "$_snap_rwn" -gt "$GIT_EXIT_SCAN_MAX_REWRITES" ]; then
    _snap_fail 'more than %s remote URL and insteadOf rule pairs to compare: too many, treat the checkout as unsafe' \
      "$GIT_EXIT_SCAN_MAX_REWRITES"
    return 1
  fi
```

(excerpt ends :413; enclosing `_snap_rewrite` continues to :421 — read)

R4 W6 used 1 URL and 2 rules (2 comparisons). With cap=1 the result was rc=1 and the message `more than 1 remote URL`. With cap=2 and cap=3 the result was rc=0. R4 W8: `git_exit_scan` status=2 when the cap trips at exit. The launcher maps status 2 to `*) exit 4 ;;` (`cc-isolated.sh:937`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:405-421`, `:1048-1061`; `devcontainer-config/cc-isolated.sh:932-938`; `$PF/logs/exp-worklist.log` (W6, W7, W8)

---

## Claim 8: "url.<base>.insteadOf rewrites matching URLs to <base>: the base alone here, every URL it rewrites in git_exec_snapshot (_snap_rewrite)."

**Location:** `devcontainer-config/cc-exit-scan.sh:466-467`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers what `_snap_config`'s insteadOf branch does (queue the rule, walk the base); does not establish that the base walk itself is necessary.

```bash
# devcontainer-config/cc-exit-scan.sh:468-471
        t="${key#url.}"; t="${t%.*}"
        case "$t" in ""|.) _snap_wrel "$key" "$f" ./ ;; esac   # a base "" or "." starts a relative path
        _snap_rule "$t" "$val"
        _snap_remote "$t" "$base" || return 1 ;;
```

The pairs are compared only in `git_exec_snapshot`'s closing loop (`cc-exit-scan.sh:788-795`).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:465-471`, `:777-798`

---

## Claim 9: "Your rewrite rules apply to the repo's URLs too (an empty value matches all)." Brief: rules from your global/system config are collected in `_snap_host_config`, empty values included, and the change is safe (no new reads, nothing run).

**Location:** `devcontainer-config/cc-exit-scan.sh:563-566`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers collection from the global config and its include targets (only conditional includes `_snap_cond` accepts), empty values included, and that the added lines run no command; does not establish collection of `remote.*.url` from your own config (not collected: Claim 16), nor a check on the system config (the probes used `GIT_CONFIG_NOSYSTEM=1`; it goes through the same `git config --list` loop).

```bash
# devcontainer-config/cc-exit-scan.sh:563-567
    # Your rewrite rules apply to the repo's URLs too (an empty value matches all).
    case "$key" in
      url.*.insteadof|url.*.pushinsteadof) t="${key#url.}"; _snap_rule "${t%.*}" "$val" ;;
    esac
    [ -n "$val" ] || continue
```

(excerpt ends :567; enclosing `_snap_host_config` continues to :590 — read)

The rule is queued before the empty-value `continue`, so empty values are kept. The added lines are parameter expansions plus an array append (`_snap_rule`, `:393-399`). They read no new file and start no process. The config listing was already produced by the existing `git config ... --no-includes --show-origin --null --list` from `/` (`:555`). R4 W4 shows an empty-valued global rule matching. R1 E11 shows git applying a global rule to a repo-config URL. Bats test 6 (R2 ok 6, R3 not ok 6) checks the same end to end.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:549-590`, `:393-399`; `$PF/logs/exp-worklist.log` (W4); `$PF/logs/exp-git.log` (E11); `$PF/logs/bats-postfix.log`

---

## Claim 10: "Walking one can reach configs that name more, hence the growing indexes: a new URL meets the rules already seen, a new rule meets the URLs already seen, so each pair meets once."

**Location:** `devcontainer-config/cc-exit-scan.sh:777-780`
**Type:** Invariant / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers completeness and uniqueness of (URL index, rule index) comparisons, including URLs, rules and path-valued names found only inside a rewritten target's config; does not establish that `_snap_rnames` entries added during the closing loop retroactively un-queue a name that was already treated as a URL (pre-existing behaviour, in the over-walking direction).

```bash
# devcontainer-config/cc-exit-scan.sh:781-797
  i=0 u=0 r=0
  while [ "$rc" -eq 0 ]; do
    if [ "$i" -lt "${#_snap_names[@]}" ]; then
      ...
    elif [ "$u" -lt "${#_snap_urls[@]}" ]; then
      for ((j = 0; j < r; j++)); do _snap_rewrite "$u" "$j" || { rc=1; break; }; done
      u=$((u + 1))
    elif [ "$r" -lt "${#_snap_rbases[@]}" ]; then
      for ((j = 0; j < u; j++)); do _snap_rewrite "$j" "$r" || { rc=1; break; }; done
      r=$((r + 1))
    else
      break
    fi
  done
```

Loop invariant (paraphrased — no quote available because it is inferred from the two branches together): exactly the pairs `{(u', r') : u' < u, r' < r}` have been compared. The URL branch adds `{(u, r') : r' < r}` and the rule branch adds `{(u', r) : u' < u}`, so the two sets never overlap. `u` and `r` do not change inside the inner loops, and new entries are only appended at higher indexes. The loop exits only when `i`, `u` and `r` have all reached their array lengths, so every pair has been compared. R4 W6 counted exactly 2 comparisons for 1 URL and 2 rules (cap=2 passes, cap=1 fails), with no duplicates. R4 W1 covered a rule found only in a target's config: `t2-x` was walked for an earlier URL. R4 W2 covered a URL found only in a target's config: `z-y` was walked with an earlier rule. R4 W3 covered a path-valued pushRemote found only in a target's config: `n-q` was walked.

**Evidence:** `devcontainer-config/cc-exit-scan.sh:777-798`, `:406-421`; `$PF/logs/exp-worklist.log` (W1, W2, W3, W6)

---

## Claim 11: "B15 | Empty `insteadOf` value (matches every URL) | covered | an empty prefix is a match (bash `${u#""}`)"

**Location:** `docs/working/plan-q096-exit-scan-insteadof-target.md:28`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the named mechanism `${u#""}`; does not dispute the conclusion that an empty value is a match, which is Verified in Claim 5.

The code has no `${u#""}`, or any `${u#...}` expansion, in the match path. The match is `[[ "$u" == "$p"* ]] || return 0` (`cc-exit-scan.sh:414`) and the remainder is `t="${_snap_rbases[$2]}${u:${#p}}"` (`cc-exit-scan.sh:415`). A grep for `${u#` in `devcontainer-config/cc-exit-scan.sh` returns no match (paraphrased — no quote available because the claim is about absence of code). Under the compound-claims rule, a mechanism the code refutes is not Mostly accurate. Fix: cite `[[ "$u" == "$p"* ]]` (an empty pattern prefix matches every string). Low stakes: this is a working doc and the coverage it asserts holds.

**Evidence:** `docs/working/plan-q096-exit-scan-insteadof-target.md:28`; `devcontainer-config/cc-exit-scan.sh:414-415`

---

## Claim 12: Research "Git's rule": "the longest wins ... Applied once, never chained. remote.<n>.pushurl values are rewritten with insteadOf. When a remote has no pushurl, each remote.<n>.url is also rewritten with pushInsteadOf into an implicit pushurl. A remote name no remote defines (path-valued branch.*.remote, pushRemote, remote.pushDefault) and legacy remotes files go through the same aliasing."

**Location:** `docs/working/research-q096-exit-scan-insteadof-target.md:19-22`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers longest-wins (E2), no chaining (E4), pushInsteadOf on url without pushurl (E5), pushurl rewritten by insteadOf and not by pushInsteadOf, url's pushInsteadOf ignored once pushurl is set (E6), legacy remotes and branches files (E9, E10), a path-valued pushRemote (R7), and the research's experiment line (`:25`); does not establish `remote.pushDefault` or `branch.*.remote` separately (they share the name path in remote.c and were not run individually).

R1 results were E2 `ran: long-po`, E4 `ran:` (nothing), E5 `ran: pm-repo`, E6 `ran: puI-repo` (not `pu-repo`, not `up-repo`), E9 `ran: leg-repo` and E10 `ran: legb-repo`. R7: with `branch.main.pushRemote alias/b` and rule `url.<P>/br-.insteadOf alias/`, a plain `git push` under `push.default=current` printed `remote: ran-br-b`. Under the default `push.default=simple` with no upstream, git refused (`has no upstream branch`) before resolving a URL. The research's experiment line does not say which push form it used, so this caveat is noted here and is not verdicted against it.

**Evidence:** `docs/working/research-q096-exit-scan-insteadof-target.md:19-25`; `$PF/logs/exp-git.log`; `$PF/logs/exp-pushremote.log`

---

## Claim 13: "Each of those remote URLs, local or not, is also rewritten by every url.<base>.insteadOf and pushInsteadOf rule whose value it starts with — from any config the scan reads, your own global and system config included — and the rewritten URL is walked the same way: git uses only the longest matching rule, the scan walks every match."

**Location:** `guides/cc-isolated-usage.md:321-326`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the remotes in the guide's preceding list (repo-config remote.*.url/pushurl, pushDefault, branch remote/pushRemote, legacy files) rewritten by pooled rules; does not establish rewriting of remotes defined in your own config (Claim 16).

The text says the same thing as the header in Claims 1 and 2, and the same evidence applies. "Local or not" matches the code: `_snap_url` queues the URL before `_snap_remote` filters out non-local forms (`_snap_urls+=("$1"); ... _snap_remote "$1" "$2"`, `cc-exit-scan.sh:387-388`). Bats test 1 (R2 ok 1) rewrites an `https://` remote to a local target.

**Evidence:** `guides/cc-isolated-usage.md:318-327`; `devcontainer-config/cc-exit-scan.sh:383-389`; `$PF/logs/bats-postfix.log`; `$PF/logs/exp-git.log`

---

## Claim 14: "More than 100,000 URL-and-rule comparisons fails the scan (exit 4) rather than stalling it."

**Location:** `guides/cc-isolated-usage.md:326-327`
**Type:** Configuration / Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the 100,000 threshold ("more than" is exact: the 100,001st comparison fails) and exit 4 at session exit; does not hold for the launch snapshot, where the same failure makes the launcher refuse with exit 1.

The threshold is `GIT_EXIT_SCAN_MAX_REWRITES=100000` (`cc-exit-scan.sh:405`) with a `-gt` test (`:409`). At exit, R4 W8 showed `git_exit_scan` returning status 2, which the launcher maps to `*) exit 4 ;;` (`cc-isolated.sh:937`). At launch, the snapshot failure path is `if ! git_before="$(git_exec_snapshot "$ws" "$lws" 2>"$snap_err")"; then ... exit 1` (`cc-isolated.sh:859-867`), not exit 4. The brief's claim 5 states both outcomes. The guide sentence states only exit 4. The guide's own hash-cap sentence (`:347`) has the same imprecision, while the "One unlistable directory" bullet (`:420`) states both: "refuses the launch (exit 1) or, at exit, reports exit 4". Tighten to: "fails the scan: the launch refuses (exit 1), or at exit it reports exit 4".

**Evidence:** `guides/cc-isolated-usage.md:326-327`, `:347`, `:420`; `devcontainer-config/cc-exit-scan.sh:405-413`; `devcontainer-config/cc-isolated.sh:859-867`, `:932-938`; `$PF/logs/exp-worklist.log` (W8)

---

## Claim 15: "(a remote of `.` is fine; an `insteadOf` base of `.` or `""` is not, nor a remote any `insteadOf` rule, yours included, rewrites to a relative path), which git would resolve in the new worktree's tree, unscanned."

**Location:** `guides/cc-isolated-usage.md:376-378`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the note being refused when a remote rewrites to a relative target, from a repo rule (W9) or your global rule (bats 7); does not establish refusal for a rewrite whose result is exactly `.` (excepted, as for a plain `.` remote).

This is the same mechanism as Claim 3: `_snap_wrel remote "$p" "$p"` on the rewritten target (`cc-exit-scan.sh:367`). Bats test 7 (R2 ok 7) uses "yours included" with a global `url.vendor/.insteadOf x:` and gets the warning that lists the worktree.

**Evidence:** `guides/cc-isolated-usage.md:373-379`; `devcontainer-config/cc-exit-scan.sh:367`, `:420`; `$PF/logs/bats-postfix.log`; `$PF/logs/exp-worklist.log` (W9)

---

## Claim 16: Removal of the known-route bullet "A URL rewritten by `url.<base>.insteadOf`. The base is walked, never the rewritten URL, so a remote rewritten to a local path the session plants runs that repository's hooks on push." (the route is implied closed)

**Location:** `guides/cc-isolated-usage.md:414` (removed lines; old `guides/cc-isolated-usage.md:410-412` on main)
**Type:** Behavioral / Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the route for every remote defined in repo config (the checkout's, includes, embedded repos), legacy remote files and path-valued names, which is now closed; does not cover a remote defined in YOUR global/system config, or a URL typed on the command line, rewritten by an insteadOf rule already present at launch to a target the session plants. That residual is still open and no longer listed.

For repo-config remotes the route is closed (Claims 1, 10; R3 shows all eight tests failing pre-fix). A residual remains. `_snap_host_config` follows only `core.hookspath`, `core.attributesfile`, includes and, now, url rules (`cc-exit-scan.sh:563-589`). It never queues `remote.*.url` from your own config (paraphrased — no quote available because the claim is about the absence of a `remote.*` case in `_snap_host_config`'s `case "$key"`). On the git side, R5 defined `remote.hostonly.url https://h.invalid/x` in the global config, with repo rule `url.<W>/h-.insteadOf https://h.invalid/`. `git push hostonly` then ran `<W>/h-x`'s pre-receive (`remote: ran-h`). On the scan side, R4 W10 produced no `remote <W>/h-x` record. The plan lists command-line URLs as B20 "not covered". A new rule added mid-session is already a C-record finding, so the residual needs a rule already in the baseline. The likely fix is a qualifier on the removed bullet (or a narrower replacement bullet). Whether to close the residual in code is a scope call for the orchestrator.

**Evidence:** `guides/cc-isolated-usage.md:388-420`; `devcontainer-config/cc-exit-scan.sh:549-590`; `docs/working/plan-q096-exit-scan-insteadof-target.md:33`; `$PF/logs/exp-hostremote.log`; `$PF/logs/exp-worklist.log` (W10)

---

## Claim 17: "Tests: top-level rewrite (also a target created in the session), pushInsteadOf and a pushurl rewritten by insteadOf, overlapping prefixes, a rewritten path-valued pushRemote, a rewrite in an embedded repo, your global rule, a non-local target, a relative target refusing the worktree note, and the cap. All eight fail on the pre-fix scan."

**Location:** commit 5f754994 message body (`git log -1 --format=%B`), "Tests:" paragraph
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that the diff adds exactly eight `Q-096` bats tests matching the listed topics (the non-local and relative cases share one test, and so do pushInsteadOf and pushurl), that all eight pass post-fix, and that all eight fail with main's `cc-exit-scan.sh`; does not establish that the non-local half of test 7 is what fails pre-fix (it is the relative/W half, at `warns_listing_wt`).

R2: `ok 1`..`ok 8`. R3: `not ok 1`..`not ok 8`. In the pre-fix run, test 7 fails at `warns_listing_wt` and test 8 at `[ "$status" -eq 1 ]`. The test count matches the eight `@test "exit scan Q-096: ..."` blocks in the diff (`test/cc-isolated-functions.bats:2141-2226`). Checked against hallucination-log test-tally entries ("All 85 tests ... but the suites hold 97", "mode1-equiv 33 ... holds 25"): this claim does not repeat that pattern.

**Evidence:** `test/cc-isolated-functions.bats:2127-2226`; `$PF/logs/bats-postfix.log`; `$PF/logs/bats-prefix.log`

---

## Claim 18: "Every remote URL the scan meets (...) is now queued with its working tree, local or not, and every insteadOf/pushInsteadOf rule from any config the scan reads (...) is queued too. A growing worklist meets each URL with each rule once; every match (not only git's longest) is walked with _snap_remote. Rewritten URLs are never re-queued (git rewrites once). More than GIT_EXIT_SCAN_MAX_REWRITES (100,000) comparisons fails the snapshot closed."

**Location:** commit 5f754994 message body, second paragraph
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each atom as verified in Claims 1, 2, 5, 6, 7 and 10; "every remote URL the scan meets" is accurate because the scan does not meet remotes defined in your own config (Claim 16 residual); does not establish anything about host-side runs (the commit's own trailer says none ran).

Each atom maps to a verified claim. Queuing is at `cc-exit-scan.sh:383-389` and `:393-399`, the worklist at `:781-797`, every match at `:414-420`, no re-queue at `:420` (R4 W5), and the cap at `:405-413` (R4 W6/W8).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:383-421`, `:777-798`; `$PF/logs/exp-worklist.log`; `$PF/logs/bats-postfix.log`

---

## Claim 19: "Used the Host-tool-tested trailer, not Live-verified: since Q-089 unit B (decision log row 71) live-verify-gate.sh requires Host-tool-tested for cc-exit-scan.sh and Live-verified does not satisfy it"

**Location:** commit 5f754994 message, `Notes:` trailer
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the gate's host-tool set including `cc-exit-scan.sh` and the requirement that only `Host-tool-tested:` satisfies it (unless the diff is comment-only); does not establish the decision-log row number's content beyond the gate's own header citing "decision log row 71".

The gate's file pattern is `host_tools='^devcontainer-config/(cc-exit-scan\.sh|cc-gitdir\.sh|cc-push\.sh)'` (`hooks/live-verify-gate.sh:91`). Its requirement is `if [ -n "$host_touched" ] && ! comment_only_diff "$host_touched"; then need+=("Host-tool-tested"); fi` (`:163`). Its header says `` `Live-verified:` trailer does not satisfy them `` (`:26`). R6 ran the gate's test "a host-tool commit needs Host-tool-tested, and Live-verified alone does not do" and it passed (`ok 1`). The commit carries `Host-tool-tested: no — bats only in the container ...`. The gate accepts the `no — <reason>` form (`:209`).

**Evidence:** `hooks/live-verify-gate.sh:23-27`, `:91`, `:160-180`, `:207-209`; `$PF/logs/bats-lvg.log`

---

## Claims Requiring Attention

### Incorrect
- **Claim 11** (`docs/working/plan-q096-exit-scan-insteadof-target.md:28`): B15 names the mechanism `${u#""}`, which the code never uses. The match is `[[ "$u" == "$p"* ]]` (`cc-exit-scan.sh:414`). Cite that. The conclusion (an empty value matches) holds.

### Stale
- (none)

### Mostly Accurate
- **Claim 14** (`guides/cc-isolated-usage.md:326-327`): "fails the scan (exit 4)" is true only at exit. At launch the launcher refuses with exit 1. State both, as the guide's "One unlistable directory" bullet does at `:420`.
- **Claim 16** (`guides/cc-isolated-usage.md:414`, removed bullet): the route is closed for repo-config remotes. It is still open for a remote defined in YOUR global/system config, or a command-line URL, rewritten by a baseline insteadOf rule to a target the session plants (R5/W10: git runs the hook, the scan has no record). Keep a narrowed known-route bullet, or close it in code.

### Unverifiable
- (none)

---

## Goal-Alignment Note

**Success criterion (restated verbatim):** A markdown report saved to /workspace/.claude/wt-q096/docs/reviews/q096-exit-scan-insteadof-target-p1-code-fact-check-report.md, structured per the code-fact-check skill, with first line `Commit: 5f754994` and header field `**Replication:** k=1 (loop pass, decision 031)`.

**Answered:** Brief claims 1–7 are all verdicted.
- 1 (git semantics): verified by experiment on git 2.39.5. Claims 2, 5, 6 and 12.
- 2 ("each pair meets once"): verified by loop invariant plus executed probes for rules, URLs and names found inside rewritten targets. Claim 10. No missed pair.
- 3 (host rules, empty values, safety): verified. Claim 9.
- 4 (relative-target W record): verified. Claims 3 and 15.
- 5 (cap): verified in code. The guide's "exit 4" omits the launch-time exit 1 (Claim 14).
- 6 (guide and header match the code): verified, except that the removed known-route bullet leaves the host-defined-remote and command-line URL residual unlisted (Claim 16).
- 7 (commit message): "All eight fail on the pre-fix scan" was verified by running them, and the trailer choice was verified against the gate (Claims 17–19).

**Out of scope:** Code quality, performance of the quadratic worklist beyond the cap's existence, and whether pooled rules over-refuse the worktree note (security, performance and architecture critics own those). Host-side behaviour: the commit records `Host-tool-tested: no`. The docs/working research and plan prose were checked only for the git-semantics and mechanism claims.

**Escalate:**
- Claim 16 residual (for the orchestrator or security critic). A session-planted target reached through a remote that YOUR global/system config defines, rewritten by an insteadOf rule already present at launch, still runs that repo's hooks on push, and the scan does not see it. The same applies to a command-line URL. Low likelihood, because a new rule mid-session is already a C-record finding, so the rule must be in the baseline. The open decision is whether to list it as a known route or queue `remote.*.url`/`pushurl` from `_snap_host_config` as URLs.
- The hallucination-pattern log was not updated. Claim 11 is a plan-versus-code mechanism drift, not a fabricated API. The brief also forbids editing tracked files other than this report.
- Captured execution logs are in `$PF/logs/` (outside the repo) instead of `docs/reviews/execution-logs/`, per the brief's no-tracked-edits rule.

**Questions / Decisions:** none.
