Commit: 1c820663
# Code Review Rubric

**Branch:** `feat/build-loop-u2b3b2b` (U2b3b2b: both import walks start at outside seeds — config dirs, ancestors, other worktrees' start files — and project rejected `//` names), on main 07fe578b.
**Status: 🟡 ITERATION 1 (loop pass over 1c820663, k=1, full panel) — no behavioral red; Must Address fixed or routed in the fix commit after 1c820663 (unreviewed until iteration 2).**

## Iteration 1 (Commit 1c820663, `--loop-pass`, k=1, scope `main...HEAD`, full panel)

Delivery mode: self-read. The fact-check (`code-fact-check-report-build-loop-u2b3b2b.md`: 24 claims, 16 Verified, 3 Incorrect, 1 Stale, 3 Mostly accurate, 1 Unverifiable) and the four critics ran in parallel, as in earlier build-loop units: `security-review-2026-10-09-u2b3b2b.md`, `performance-review-2026-10-09-u2b3b2b.md`, `api-consistency-review-2026-10-09-u2b3b2b.md`, `architecture-review-2026-10-09-u2b3b2b.md`. Contextual critics: architecture-review (new lib functions, the walks' contract). Stage 2.5 skipped (loop pass); security's two routed endorsements stay pending execution verification.

### 🔴 Must Fix

None. The fact-check's Incorrect claims are a narrow tree-walk gap (19b, tiered 🟡 below) and two comments (10, 16).

### 🟡 Must Address

| # | Finding | Severity | Source | Status |
|---|---|---|---|---|
| A1 | The C1 same-bytes skip tested only `-f` on ROOT_REAL's copy, so a copy the tree walk does not start at (a symlinked CLAUDE.md, executed) dropped the other root's matching start. | Medium | fact-check 19b; architecture 1; security F4 | Fixed: the skip needs `rawfile` and a non-link seed; links are always seeds; contract item 2 named (test: C1 test's symlinked CLAUDE.md). |
| A2 | An import a start in another root reaches through a file that root holds with other bytes, or alone, is read from ROOT_REAL or main instead (executed). Not a regression. | Medium | security F1 | Routed: U2b3b2c (name-driven reads of other roots' differing copies); named in the walk header and outside_seeds; override row. A first fix seeding every @-bearing .md in other roots gave 6,720 seeds over /workspace's untracked clones and failed both walks. |
| A3 | `find -P` does not enter a symlinked directory in another root. | Medium | security F2 | Acknowledged: named exception (known issue A5, as in the tree walk); override row. |
| A4 | Prompt seeds passed prompt_bases the path as spelled, not lower-cased (contract item 8); a `.CLAUDE` prompt in another root lost its base (executed). | Medium | api F1; architecture 5 | Fixed (lower; test: `.CLAUDE` prompt in the C1 test). |
| A5 | CLAUDE_CONFIG_DIR and MANAGED_DIR feed the walks but sit outside their cache keys and contract item 4. | Medium | api F2; architecture 3 | Fixed: contract item 4 lists both; moving config dirs into import_readers' key deferred (override row). |
| A6 | 73% of walk time read seeds holding no @; 1.1 s of bash ran over 24,663 names. | Medium | performance F1, F2 | Fixed: an @ filter (xargs grep) drops @-free seeds not reached through a link; C1 uses instruction_names before isstart. Walks: 7 s → 3 to 3.5 s. |

### 🟢 Consider

| # | Finding | Source | Status |
|---|---|---|---|
| K1 | C1 header's "listed once" and the nested-root comment were wrong for a root below ROOT_REAL. | fact-check 10, 16 | Fixed (comments). |
| K2 | Plan says "K5, pinned by a test"; none exists. | fact-check 1 (Stale) | Fixed: plan text. |
| K3 | Walk header's exceptions, plugins wording, returns-1 list incomplete; timings unverifiable. | fact-check 3, 7, 13, 4 | Fixed; re-measured over 8 worktrees. |
| K4 | Header Inputs paragraph omitted the new reads. | api F3 | Fixed. |
| K5 | MANAGED_DIR lacked the IMPORT_ prefix. | api F4 | Fixed: IMPORT_MANAGED_DIR. |
| K6 | A relative CLAUDE_CONFIG_DIR was silently skipped. | api F5 | Fixed: fails the walk (test). |
| K7 | Seed tags differ from main_imports' m:/t:; partial array on failure. | api F6 | Won't-Fix: override row. |
| K8 | One unreadable directory in any worktree fails every walk; a FIFO seed stalls. | security F3 | Acknowledged: named in the walk header (fail-closed). |
| K9 | Plugin JSON traceback on stderr. | security F5; fact-check | Fixed (2>/dev/null; test asserts empty stderr). |
| K10 | outside_proj forked on every file. | performance F3 | Fixed (guard). |
| K11 | E2BIG on a single sha1sum/grep argument list. | performance F4 | Fixed (xargs). |
| K12 | outside_seeds is one long function; the admission rule repeats in four loops. | architecture 4, 5 | Defer: override row (U2c). |
| K13 | "Outside" now covers files in other roots. | architecture 2 | Fixed: import_outside and outside_ok headers. |
| K14 | Seeds recomputed per walk call. | architecture 7 | Defer: override row (no caller runs two walks). |

### 🧩 Composition check

- outside_seeds C1 skip (fact-check 19b, architecture 1, security F4): one root (the skip trusts a copy the walk may not start at), A1; no further composition.
- Contract item 4 (api F2, architecture 3): same defect, A5.
- Prompt LP (api F1, architecture 5): same defect, A4.

### Considered overrides

Rows 558 (A3 host home, kept an exception), 561, 571 (settled), 573 (S1: fixed here by outside_proj), 575 (K4: `//` lines ~83 KB, still deferred), 576 (K5: no observable test; plan corrected), 578 (bind-mount alias: still untested), 550, 554 (U2b3b1; seeds do not multiply by re-spelling since C1 dedupes real paths).

Single-sample review; absence of findings is not an attestation.
