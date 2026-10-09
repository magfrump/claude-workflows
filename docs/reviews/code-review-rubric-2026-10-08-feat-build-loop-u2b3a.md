Commit: c9197fd2
# Code Review Rubric

**Branch:** `feat/build-loop-u2b3a` (U2b3a: the reader model's roots and homes in the import parser), on main e50aab35.
**Status: 🟡 ITERATION 1 — no red; three Must Address (a nested root at a non-dot path hides names, an executed fail-open; the caller's reader lists inherited from the environment; reader_set's per-call cost), all fixed; ITERATION 2 — no red; every iteration-1 fix holds; two text ambers (a stale superset sentence, inexact figures and a test row) fixed after the pass (unreviewed)**

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

### Fix-commit drift check (lite, 84e597ae..4dba56dc)

One finding, refuted: "the HOME-newline test expects docs/other.md imported in its second loop" (Medium, test-prose-mismatch). That loop's walk fails, and a failed walk answers imported for every path, the suite's fail-closed convention; a comment saying so was added to the test.

### 🧩 Composition check

- `dev-cycle-read.sh:733-735, 838-841, 857-866` (security 1, architecture F1): one defect stated in full by both sources; merged as A1 (`distinct defects` does not apply: same mechanism, convergent).
- `dev-cycle-read.sh:869-874` (fact-check E1, api F3, F4, security 3): two defects, G2 (own HOME newline) and G3 (caller home spelling).
- `dev-cycle-read.sh:880-884` (api F5, architecture F3, security 2): one defect, G1.
- `dev-cycle-read.sh:1000, 1050` (performance F1, architecture F6): one root, A3 (reader_set per call: cost and a moving key).

### Considered overrides

Rows 425, 432 (this unit's target: other checkouts and homes), 437 (cache keys take the reader set; the host alias), 431 and 477 (outside-repo starts: U2b3b's, not re-flagged), 439 (walk cache cleared per decision).

### Tokens

fc 1×157k; critics 4× (security 156k, performance 141k, api 131k, architecture 147k) ≈ 730k total.

## Iteration 2 (Commit c9197fd2, `--loop-pass`, k=1, scope `5516c6e6..c9197fd2` (scripts, test), full panel)

Delivery mode: inline-diff-only (shared brief with the partial-scope label). Reports: `code-fact-check-report-build-loop-u2b3a-i2.md` (33 claims: 24 Verified, 7 Mostly accurate, 1 Stale, 1 Unverifiable, 0 Incorrect), `security-review-2026-10-08-u2b3a-i2.md`, `performance-review-2026-10-08-u2b3a-i2.md`, `api-consistency-review-2026-10-08-u2b3a-i2.md`, `architecture-review-2026-10-08-u2b3a-i2.md`. Iteration 1: A1, A2, A3, G1-G3, G5-G7, G10 verified resolved (security ran nine nesting shapes; architecture judged dotnest better than its own i1 suggestion, which would have failed every walk while a stale entry stayed registered); G4 partial (see B1, B2).

### 🔴 Must Fix

None.

### 🟡 Must Address

| # | Finding | Severity | Source | Status |
|---|---|---|---|---|
| B1 | The superset statement still says names print "relative to the longest one holding it", the rule A1 replaced; and dotnest is safe only because truthrule's dot word refuses every omitted spelling, which neither comment said (a narrowed truthrule would reopen A1 with no test red). | Stale (doc) / Minor | fact-check i2 claim 9; api N1; architecture N1; security 2 | Fixed: the statement names dotnest; put's comment and truthrule's dot line cross-reference each other; a test pins truthrule's dot answer for two dot-nested spellings |
| B2 | Inexact text: contract item 4's "read again only after a reset" (a memo-key change also re-reads); "0.1-4 s"/"about 7 s" (5.1 s and 8.8 s measured); "8,600 with one" (8,240); "a cached walk costs no fork" (need_root forks); the nested-root test's caller-root row did not nest over the name. | Mostly accurate | fact-check i2 claims 1, 6, 7b, 15b, 21; api N3; architecture N4; security 1 | Fixed: wording and figures corrected; item 9 says to set the lists before a decision's first walk; the test now runs a caller root at `sub/`, as written and through a symlink, after pruning the stale entry |

### 🟢 Consider

| # | Finding | Source | Status |
|---|---|---|---|
| H1 | Charged work now grows with the square of the root count: the honest walks reach the 50M bound near 570 roots (24 today) and then fail closed. | performance i2 F1 | Fixed (documented in the IMPORT_WORK_MAX comment, with `git worktree prune` as the remedy) |
| H2 | The dotnest table is rebuilt in every parser process (~8 ms per walk at 24 roots). | performance i2 F2 | Defer (override row) |
| H3 | `readers_key`/`READERS_KEY` lacked the `import_` prefix; the Inputs paragraph did not name the registry read. | api N2, N4 | Fixed (`import_readers_key`, `IMPORT_READERS_KEY`; Inputs line added) |
| H4 | check_fix has no settings reader to set the lists contract item 9 asks for. | architecture N2 | Defer to U2b3b (override row, plan sub-bullet) |
| H5 | import_targets falls back to ROOT_REAL alone without a current memo. | architecture N3 | Defer to U2b3b (override row) |
| H6 | `T_READER_*` is honoured only by imps. | api N5 | Defer to U2c (override row) |
| H7 | Commit 4dba56dc's figures (89 ms, 8,600, 324 lines). | fact-check i2 claims 26c-f | Accepted-immutable (override row); the merge message re-states them |

### 🧩 Composition check

- `dev-cycle-read.sh:679, 738-751, 1210` (fact-check 9, api N1, architecture N1, security 2): one root, B1 (the dotnest rule and the truthrule invariant it leans on, stated nowhere).
- `dev-cycle-read.sh:64-67, 83-86` (fact-check 1, api N3, architecture N4): one root, folded into B2.

### Tokens

fc 1×189k; critics 4× (security 159k, performance 137k, api 134k, architecture 160k) ≈ 780k total.
