Commit: 5516c6e6
# Code Review Rubric

**Branch:** `feat/build-loop-u2b3a` (U2b3a: the reader model's roots and homes in the import parser), on main e50aab35.
**Status: 🟡 ITERATION 1 — no red; three Must Address (a nested root at a non-dot path hides names, an executed fail-open; the caller's reader lists inherited from the environment; reader_set's per-call cost), all fixed after the pass with eleven of twelve Consider rows (unreviewed)**

## Iteration 1 (Commit 5516c6e6, `--loop-pass`, k=1, scope `main...HEAD`, full panel)

Delivery mode: inline-diff-only (the diff, log and matched override rows in a shared brief in the scratchpad; agents read the enclosing files). Reports: `code-fact-check-report-build-loop-u2b3a.md` (k=1: 27 claims, 22 Verified, 3 Mostly accurate, 1 Stale, 1 Unverifiable, 0 Incorrect), `security-review-2026-10-08-u2b3a.md`, `performance-review-2026-10-08-u2b3a.md`, `api-consistency-review-2026-10-08-u2b3a.md`, `architecture-review-2026-10-08-u2b3a.md`. Test-strategy not selected (the source change carries six tests). Stage 2.5 skipped (loop pass): security's three `route: code-fact-check` endorsements are pending execution verification.

### 🔴 Must Fix

None.

### 🟡 Must Address

| # | Finding | Severity | Source | Considered overrides | Status |
|---|---|---|---|---|---|
| A1 | The longest-root projection lets a root nested in another at a non-dot path take the names below it, so the outer repo path is never printed and floor would let a branch change it. Executed with honest inputs: a stale prunable registry entry (`git worktree add sub; rm -rf sub`) and `@/<repo>/sub/x.md` on main read `sub/x.md` as imported on main's lib and `-` on HEAD, in both walks; also via `IMPORT_READER_ROOTS=<repo>/sub` or a caller root symlinked into the repo. The comment's "honest roots nest only under .claude/" is not enforced. A regression from main. | Medium / Coupling | security 1; architecture F1 | rows 425, 432 | Fixed in the iteration-1 fix commit: a name prints under every root holding it but an outer root whose path down to the nested one has a dot component (dotnest); test with a prunable `sub/` entry and a caller root in the repo, red on 5516c6e6 |
| A2 | `IMPORT_READER_ROOTS` and `IMPORT_READER_HOMES` are read from whatever the process inherits (never initialised when the lib is sourced, unlike IMPORT_OUT_MAX), and the gate caller contract never defines them; until A1 is fixed they are the first inherited inputs that can remove names. | Coupling / Minor | architecture F2; api F6; security escalation | row 437 | Fixed: the lib clears both when sourced; contract item 9 defines them; test (inherited values ignored) red on 5516c6e6 |
| A3 | reader_set runs on every walk call, cache hits included (~27 forks: git worktree list, a realpath per root, two `$(printf)`): a cached truthwalk main went from 5.5 ms to 89 ms, so U2c's per-path floor loop would add ~2.7 s per 30 paths; and the cache key follows the live registry, so one decision can be judged against two root sets. | Medium / Informational | performance F1; architecture F6 | row 439 (cache per decision) | Fixed: import_readers memoizes until import_reset (key: ROOT_REAL, HOME, the caller lists) with one batched `realpath -mz`; a cached isimported over /workspace is back to 3 ms; test (a worktree added mid-decision is seen after import_reset) |

### 🟢 Consider

| # | Finding | Source | Status |
|---|---|---|---|
| G1 | import_targets picks the reader lists from a global whose freshness key ignores IMPORT_READER_*; only a standalone call after a walk can see a stale list (no caller does). | api F5; architecture F3; security 2 | Open (falls out of A3's memo key) |
| G2 | A HOME holding a newline now fails both walks even with no `~/` name, against the lazy rule for the process's own home and reader_set's own comment (fails closed). | fact-check E1, claim 18; api F3; security 3 | Fixed: a home holding a newline is read as empty (fails only a ~/ name); test red on 5516c6e6 |
| G3 | A caller home is checked for "/ alone" only as spelled (`/x/..` passes), while roots are also checked after realpath. | fact-check claim 18; api F4; security 3 | Fixed: roots and caller homes refused when realpath reads them as / (`/x/..`); test |
| G4 | Stale comments: "ROOT_REAL/DIR/name" (claim 5), "since the roots are real too" (claim 9), the per-file bound's "about 0.1-4 s" and the walks' "about 8,100 each" (honest work is now ~255,690: 31.5×). | fact-check claims 5, 9; performance F2, F3 | Fixed: comments corrected and re-measured (honest work ~330,600 over 24 roots; 8,600 with one) |
| G5 | The per-root projection loop in put is uncharged work: one spent IMPORT_WORK_MAX bound takes up to 7.1 s at 24 roots (3.0 s at 1). | performance F2 | Fixed: `work += nr` per projected spelling |
| G6 | Naming: `reader_set` drops the `import_` prefix the parser's helpers share; `IMPORT_READERS_FOR` plays a `*_DONE` key's role. | api F1, F2 | Fixed: `import_readers`, `IMPORT_READERS_DONE` |
| G7 | `IT_ROOT` is passed beside `IT_ROOTS` only for its empty check. | api F8; architecture F7 | Fixed: IT_ROOT dropped; the parser exits 2 on an empty first root |
| G8 | A caller's host alias does not re-spell the nested worktrees under it (`@/host/cw/.claude/wt-b/docs/n.md` reads as `.claude/wt-b/docs/n.md`); floor refuses the dot path, so it is a model gap, not a hole. | architecture F4 | Defer to U2b3b (override row) |
| G9 | The parser has one output channel (repo-relative names); U2b3b's outside-to-outside chains need an absolute-base mode and an output that does not clash with the `/N` trailer. | architecture F5 | Defer to U2b3b (override row) |
| G10 | dev-cycle.bats' sourced-definitions test does not list the new names (that list was already incomplete). | api F7 | Fixed: the new names added to the sourced-definitions test |
| G11 | isimported's answer for a `.claude/...` path now depends on the registry; both consumers refuse dot paths before asking. | api F9 | Won't-Fix (override row) |
| G12 | Commit 5516c6e6 says "main's 129 names": both walks give 128 distinct names (129 counts IMPORTED's newlines); its "1.33 s against 1.31 s" is within noise. | fact-check claims 22a-c | Accepted-immutable (override row); the merge message states 128 names |

### 🧩 Composition check

- `dev-cycle-read.sh:733-735, 838-841, 857-866` (security 1, architecture F1): one defect stated in full by both sources; merged as A1 (`distinct defects` does not apply: same mechanism, convergent).
- `dev-cycle-read.sh:869-874` (fact-check E1, api F3, F4, security 3): two defects, G2 (own HOME newline) and G3 (caller home spelling).
- `dev-cycle-read.sh:880-884` (api F5, architecture F3, security 2): one defect, G1.
- `dev-cycle-read.sh:1000, 1050` (performance F1, architecture F6): one root, A3 (reader_set per call: cost and a moving key).

### Considered overrides

Rows 425, 432 (this unit's target: other checkouts and homes), 437 (cache keys take the reader set; the host alias), 431 and 477 (outside-repo starts: U2b3b's, not re-flagged), 439 (walk cache cleared per decision).

### Tokens

fc 1×157k; critics 4× (security 156k, performance 141k, api 131k, architecture 147k) ≈ 730k total.
