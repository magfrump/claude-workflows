Commit: 013f1b3d

# Code Review Rubric — fix/q096-exit-scan-insteadof-target (Q-096)

Iteration 1 of 3 (loop pass, k=1, full branch main...5f754994). Fixes in e4b29291.

Status: iteration 2 — 5 Must Fix fixed in this unit (4d7f966c), the remote-name family split out (013f1b3d → `fix/q096b-exit-scan-remote-names`); iteration 3 — no code Must Fix; doc/test fixes in the following commit; final confirming pass pending.

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
