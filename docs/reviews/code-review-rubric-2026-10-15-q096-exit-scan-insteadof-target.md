Commit: 03bc47c9
Loop closed at 03bc47c9

# Code Review Rubric — fix/q096-exit-scan-insteadof-target (Q-096)

Iteration 1 of 3 (loop pass, k=1, full branch main...5f754994). Fixes in e4b29291.

Status: PASS — final confirming pass (full branch, k=3) at 03bc47c9: 0 🔴, every 🟡 resolved in the doc-only commit that follows 03bc47c9 or acknowledged with a revisit trigger. Single-sample review; absence of findings is not an attestation.

Reports: `q096-exit-scan-insteadof-target-p1-code-fact-check-report.md`, `…-p1-security-review-2026-10-15.md` (partial: its long probe was stopped by the coordinator before it reported; findings 1–5 were written), `…-p1-performance-review-2026-10-15.md`, `…-p1-api-consistency-review-2026-10-15.md`. Contextual critics: none triggered (tests changed; one module; under 500 lines).

Considered overrides: override-log row 134 (scan cost, documented limit) — matched; the new caps bound the new pass, long values left to the same route. Row 135 — matched by subsystem, not affected.

## 🔴 Must Fix

| # | Finding | Source | Location | Status |
|---|---|---|---|---|
| R1 | A remote in your own global/system config is never queued; a launch-time rule rewriting it to a planted target ran the hook unseen (experiment-confirmed) | fact-check C16, security 1, api-consistency F1 | `cc-exit-scan.sh` `_snap_host_config` | Fixed e4b29291 (+ test) |
| R2 | Tab-joined dedupe keys collide; a pair is dropped and its target's hook runs unseen (experiment-confirmed) | security 3 | `_snap_url`/`_snap_rule`/`_snap_rewrite` keys | Fixed e4b29291 (length-prefixed keys, + test) |
| R3 | Prefix match character-wise under UTF-8; git byte-wise (experiment-confirmed) | security 2 | `_snap_rewrite` match | Fixed e4b29291 (`_snap_match` under `LC_ALL=C`, + test) |
| R4 | A remote with no url is pushed to by name; the scan skipped the name (experiment-confirmed; pre-existing) | security 5 | `_snap_rnames` marking | Fixed e4b29291 (+ test) |

Found by the author while fixing R3: every `read` in the file swallowed a delimiter after an incomplete UTF-8 character, hiding the next entry (pre-existing). Fixed e4b29291 (+ test). For the iteration-2 reviewers to confirm.

## 🟡 Must Address

| # | Finding | Source | Status |
|---|---|---|---|
| A1 | The comparison cap does not bound cost (local matches fork; 10k matches 44 s); guide's "rather than stalling" false | performance 1, security 4 | Fixed: target cap 2,000; pair cap charged per batch |
| A2 | Guide "exit 4" only at session exit; launch refuses with exit 1 | fact-check C14, api F4 | Fixed |
| A3 | Command-line URL route unlisted after the bullet's removal | fact-check C16, api F1 | Fixed: "A URL you type" known route |
| A4 | Plan B15 names a mechanism the code does not use (doc-only Incorrect) | fact-check C11 | Fixed |
| A5 | New cap missing from header/guide fail-closed lists | api F2 | Fixed |

## 🟢 Consider

| # | Finding | Source | Status |
|---|---|---|---|
| C1 | Rename the cap to name its unit | api F3 | Done (`_MAX_REWRITE_PAIRS`) |
| C2 | Counts in the cap message | api F5 | Done |
| C3 | Test the cap via `git_exit_scan` status 2 | api F6 | Done |
| C4 | Shared-locals comment | api F7 | Done |
| C5 | Function call per pair | performance 2 | Done (inlined in `_snap_match`) |
| C6 | Long values slow each comparison | performance 3 | Acknowledged: guide "A slow scan" route (override-log row 134 family) |
| C7 | "`~` forms" should name rewritten URLs | security (untested candidates) | Done |

## 🧩 Composition check

R1 cluster (fact-check C16, security 1, api F1 at `_snap_host_config` / guide known routes): distinct sources state the same defect completely; `distinct defects` not applicable — one defect, stated by each, no composed row needed. A1 cluster (performance 1, security 4): same, fully stated by each.

---

## Iteration 2 of 3 (loop pass, k=1)

Scope: fact-check and performance/api-consistency on `5f754994..e4b29291`; security on the full branch at e4b29291 (it owed a full pass: the iteration-1 run was stopped). Reports: `q096-exit-scan-insteadof-target-p2-*.md`. The iteration-1 security report was finalised by its agent afterwards (N=316 now fails closed in 11.8 s at the target cap). Dispatch deviation: critics ran in parallel with the fact-check, without its summary.

### 🔴 Must Fix

| # | Finding | Source | Status |
|---|---|---|---|
| R5 | Dedupe keys length-prefixed in characters collide under UTF-8; a rule is dropped (experiment-confirmed) | fact-check 6b, security 1 | Fixed 4d7f966c (`_snap_key` under `LC_ALL=C`, + test failing on e4b29291) |
| R6 | Empty `branches/<name>` file marks the name defined; git pushes to the name (experiment-confirmed) | fact-check 13b, 17 | Split out (013f1b3d → q096b); guide known route |
| R7 | Legacy name with '/' marked defined though git never reads the file (experiment-confirmed) | security 2 | Split out; known route |
| R8 | One `_snap_rnames` table across repos (experiment-confirmed; pre-existing) | security 3 | Split out; known route |
| R9 | Legacy URLs untrimmed as git trims; U+3000 stripped under UTF-8 (experiment-confirmed; pre-existing) | fact-check 12, 14; security 6 | Split out; known route |
| R10 | `file://host/` and percent-encoding resolve elsewhere (experiment-confirmed; pre-existing) | security 5 | Split out; known route |

Early split: R6–R10 (and the partial B24 fix) are one pre-existing family, ≥75% of this iteration's Must Fix, separable from the insteadOf pass. Recorded in 4d7f966c/013f1b3d `Notes:`; interim (to file): listed known route until q096b lands.

### 🟡 Must Address

| # | Finding | Source | Status |
|---|---|---|---|
| A6 | Pair cap counts comparisons, not bytes: a 1 MiB URL ~20 min under the caps | security 4, performance 2 | Fixed: `GIT_EXIT_SCAN_MAX_REWRITE_BYTES` 4,096 |
| A7 | A batch builds up to 100,000 strings before the target cap trips (297 MB at 20k) | performance 1 | Fixed: per-hit check in `_snap_match` |
| A8 | `_snap_match` comment named the wrong mechanism (cut, not match) | fact-check 9b | Fixed |
| A9 | Header/guide "only three kinds" stale | fact-check 3, 21; security 7 | Fixed |
| A10 | Cap counts URL-and-working-tree targets; guide "A slow scan" silent on the pass | fact-check 7; performance 3; api 4 | Fixed |

### 🟢 Consider

| # | Finding | Source | Status |
|---|---|---|---|
| C8 | Target-cap message without counts; checker naming | api 1, 3 | Done (`_snap_pairs_ok`, counts) |
| C9 | Shared-locals comment misses `_snap_hit_*` | api 2 | Done |
| C10 | UTF-8 read test not tagged Q-096 | api 5 | Done |
| C11 | Per-read `LC_ALL=C` prefix ~3.5× slower per read | performance 4 | Acknowledged: <10 ms on real configs |
| C12 | A pushurl-only remote's name is now walked (W record) | fact-check escalation 4 | Moot here: B24 split out |
| C13 | Untested: your own `pushDefault`/`pushRemote` not queued; `config.worktree` remote names; another writable mount | security untested | Logged for q096b / Q-097 |

### 🧩 Composition check

R5 (fact-check 6b + security 1, `_snap_rule` key): one defect, fully stated by each — no composed row. A6 (security 4 + performance 2): same. R6–R10 cluster: distinct defects in one family, each stated with its own mechanism.

---

## Iteration 3 of 3 (loop pass, k=1, `e4b29291..013f1b3d`)

Reports: `q096-exit-scan-insteadof-target-p3-*.md`. Security: no route found in the insteadOf pass; all iteration-2 fixes experiment-confirmed; 013f1b3d restores main's `_snap_rnames` exactly. Fact-check: 25 Verified, 1 Mostly accurate, 3 Stale, 3 Incorrect (all doc or commit text).

### 🟡 Must Address

| # | Finding | Source | Status |
|---|---|---|---|
| A11 | Target cap counts URL-and-rule matches (before dedupe), not "one per URL and working tree" (guide; 4d7f966c message). Fails closed sooner; no security impact | fact-check 19b, 26; security 3; api 3 | Guide fixed ("one per URL-and-rule match"); the commit-message wording is corrected in the fix commit's body (unmerged branch history left as is) |
| A12 | 013f1b3d message: "the legacy-URL half proved the same read path" — false; the here-string read had no test | fact-check 28 | Fixed: legacy half restored in the read test (mutation: dropping `LC_ALL=C` from that read fails it); message corrected in the fix commit body |
| A13 | Stale `_snap_rewrite` references; test name "either cap" covers three | fact-check 11, 12b, 24; api 1, 4; security 2 | Fixed |
| A14 | "about 30 s" understated: 1,999 planted repos add ~77–90 s | fact-check 21; security 1; performance 2 | Fixed: "10-80 s (a WSL2 host; the most when each is a planted repository)" |

### 🟢 Consider

| # | Finding | Source | Status |
|---|---|---|---|
| C14 | Byte-cap message without length/where; blames rule when the working tree is long | api 2, 6 | Done: names URL, working tree or rule, with both lengths |
| C15 | `_MAX_REWRITE_BYTES` reads like a pass total | api 5 | Acknowledged: the comment says per string; rename left to avoid churn |
| C16 | Known-route bullet misses '/' legacy names and locale trimming; "(if present at launch)" placement | security 4; api 7 | Done |
| C17 | Many URLs with no rules: worklist adds time (40k remotes 55 s vs 30 s) | performance 1 | Acknowledged: override-log row 134 family (slow scan) |
| C18 | Your own `remote.pushDefault`/`pushRemote` not queued | fact-check (claim 5 gap) | Logged for the split unit (q096b) |

### 🧩 Composition check

A11 cluster (fact-check 19b/26, security 3, api 3 at the target cap): one defect, stated by each. No other multi-source cluster at 🔴/🟡.

---

## Final confirming pass (full branch `main...03bc47c9`, k=3, no `--loop-pass`)

Reports: `q096-exit-scan-insteadof-target-final-code-fact-check-report-r{1,2,3}.md` (merged below; no separate merged file was written — see note), `…-final-security-review-2026-10-15.md`, `…-final-performance-review-2026-10-15.md`, `…-final-api-consistency-review-2026-10-15.md`. Dispatch: all five agents in parallel (critics without the fact-check summary), as in iterations 2–3.

Fact-check, merged most-severe-wins across r1 (38 claims), r2 (29), r3 (41): no code claim Incorrect. Every replicate confirmed by execution: git 2.39.5 rewrite semantics (longest prefix, empty value, byte-wise, case-sensitive, no chaining, pushInsteadOf vs pushurl), each pair compared once incl. mid-walk discoveries, every cap fails closed (snapshot 1, git_exit_scan 2, launch 1), `LC_ALL=C` on every read and in `_snap_key`/`_snap_match` (removing any one fails a test), 193/193 and 11/11 bats, 395 lines. Verdict stability: the three replicates agreed on every cluster below except where noted.

### 🔴 Must Fix

None.

### 🟡 Must Address

| # | Finding | Source | Status |
|---|---|---|---|
| F1 | Plan row B14 "2,000 distinct rewritten URLs" — counts matches before dedupe (doc-only Incorrect; r1 Stale, r2/r3 Incorrect) | fact-check r1 18, r2 15, r3 21 | Fixed (doc-only commit after 03bc47c9) |
| F2 | Plan test specification names the renamed `GIT_EXIT_SCAN_MAX_REWRITES` | fact-check r1 21, r2 18, r3 23; api 1 | Fixed |
| F3 | Header and guide "each of those URLs" takes in insteadOf bases and (header) omits non-local URLs; guide omits legacy URLs | fact-check r1 1b/23, r2 1, r3 1b/26b; api 2 | Fixed |
| F4 | Your own relative `remote.*.url` now leaves a W record; not in the note-blocker lists | security 2; fact-check r2 3/22 | Fixed (header and guide) |
| F5 | A local remote that is a `gitdir:` file: git follows it, the scan records only the file (experiment-confirmed; pre-existing on main for plain remotes, not widened) | security 1 | Acknowledged: added to the guide's known route "Remote names and legacy remote files, read loosely"; revisit trigger: the q096b remote-names unit (or Q-097) takes it |
| F6 | Path-valued `pushRemote`/`pushDefault` in your own config not queued (pre-existing) | fact-check r1 escalation, r3 claim 5 | Acknowledged: same known route; revisit with q096b |
| F7 | Commit-message errors in 5f754994 (old cap name), e4b29291 ("distinct", url/vcs rule since reverted), 4d7f966c, 013f1b3d | fact-check r1 31a–34, r2 26–28, r3 36–37 | Accepted-immutable (branch history is not rewritten); 03bc47c9 and the doc-only commit record the corrections |

### 🟢 Consider

| # | Finding | Source | Status |
|---|---|---|---|
| C19 | Byte-cap comment/guide omit the working tree; "(%s and %s)" unlabelled | fact-check r3 7/28; api 3 | Comment and guide fixed; message labelling left |
| C20 | `_snap_host_config` header silent on queued rules/URLs | fact-check r3 14 | Fixed |
| C21 | Cap comment "a few forks" stale (a planted repo is a git-dir walk, ~25 ms) | performance 3 | Fixed |
| C22 | 10k remotes, no rules: 7.5–8.5 s vs 5.7–6.1 s on main (fork cost grows with memory) | performance 1 | Acknowledged: override-log row 134 family; `printf -v` for the existing per-entry fork is the lever |
| C23 | Your own remotes queued once per git dir (pairs = remotes × repos × rules) | performance 2 | Acknowledged: fails closed past 100,000 |
| C24 | Helper `rewrite_plant` noun-first | api 4 | Left |
| C25 | "10-80 s" measured on one WSL2 host; container scaling agrees | fact-check r1 36 / r3 30 (Unverifiable) | Left as stated (host named) |

Note: no merged `code-fact-check-report.md` was written; the replicate reports are the record and the table above is the merge. Composition check: F1/F2 (plan) and F3 (header/guide) are distinct doc defects; F5/F6 distinct pre-existing routes. No composed row.

Loop closed at 03bc47c9 (doc-only fixes after it: comments, guide and plan; no code line changed, `git diff 03bc47c9.. -- devcontainer-config/` touches only `#` lines).
