Commit: 3d2d8c44

# Code Fact-Check Report

**Repository:** /workspace (worktree `/workspace/.claude/wt-build-loop-u2b3a`, branch `feat/build-loop-u2b3a`)
**Scope:** `git diff main...HEAD -- scripts test` (full branch, final confirming pass, replicate r1 of k=3), plus plan step 5's U2b3a bullet and HEAD's commit message for claims
**Checked:** 2026-10-08
**Total claims checked:** 34
**Summary:** 33 verified, 1 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Execution logs (scratch, bare paths; `S=/tmp/claude-1000/-workspace/53eaab1e-c162-42ac-afd9-547bb673cbb3/scratchpad/u2b3a3-fc1`):
- P1 `$S/p1-tests.sh` → `$S/p1-tests.log`: HEAD's U2b3a tests and dev-cycle.bats' sourced-definitions test against the lib at HEAD, main (e50aab35), 5516c6e6 and 4dba56dc (in a `git archive` copy under `/tmp/u2b3a3-fc1-*`; cwd that copy; exit 0 overall; 2026-10-09T04:21Z).
- P2 `$S/p2-walks.sh` → `$S/p2-walks.log`: walks from this worktree and a 1-root clone (exit 0; 04:22Z).
- P3 `$S/p3-walks-ws.sh` → `$S/p3-walks-ws.log`: walks over `/workspace` (main e50aab35, 24 roots), forced to one root, and with 24/72/176 fake caller roots; registry-read counts through a logging `git` shim (cwd `/workspace`; exit 0; 04:23Z).
- P5 `$S/p5-bound-capped.sh` → `$S/p5-bound-capped.log`: time to spend the per-file work bound, four shapes, 1 and 24 roots, input capped at 4 MB as capped_read does (cwd `/workspace`; exit 0; 04:25Z). (P4, the uncapped run, is superseded: its 7.7 s short-token figure was sed on a 150 MB file.)
- P6 `$S/p6-units.sh` + `$S/p6-inner.sh` → `$S/p6-units.log`: dotnest projection, homes, exit codes, memo hit with PATH emptied, refusals, fork cost (cwd a fresh repo under `/tmp/u2b3a3-fc1-*`; exit 0; 04:26Z).

Hallucination log (`docs/reviews/hallucination-patterns.md`) read first. Its entries are mostly miscounted figures in docs and commits. Every figure below was re-measured. None matches a logged pattern.

---

## Claim 1: plan step 5's U2b3a bullet: "it fails the walk on a listing failure, a path holding a newline, a relative path, or `/` ... prints it relative to each root holding it, but an outer root whose path down to a nested holding root has a dot component ... The reader set is memoized until import_reset (one registry read per decision); sourcing the lib clears the caller lists"

**Location:** `docs/working/plan-build-loop-handoff.md:289-292`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator
**Scope:** Covers the bullet's refusals, dotnest projection, memo and clearing as the lib implements them, and its "renamed at review" history. It does not establish the U2b3b sub-bullet's future design.

The refusals are at `scripts/lib/dev-cycle-read.sh:898` (`nul_list rs_l git worktree list --porcelain -z || return 1`), `:906` (`[[ "$p" == /* && "$p" != *$'\n'* && -n "${p//\//}" ]] || return 1`) and `:913` (the realpath form). P6 shows `/`, `//`, `/x/..`, `rel` and a newline list each give rc=1. The dotnest rule is at `:822-823` and `:756-759`. P6 prints `docs/n.md`, not `.claude/wt/docs/n.md`, for a name under a root at `.claude/wt`. The memo and clearing are at `:895` and `:883`, and P3 counts one registry read per decision. "Built as `reader_set`, renamed at review" matches rubric row G6.

**Evidence:** `docs/working/plan-build-loop-handoff.md:289-292`; `scripts/lib/dev-cycle-read.sh:883`, `:895-913`, `:756-759`, `:822-823`; `$S/p6-units.log`; `$S/p3-walks-ws.log`; `docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b3a.md` (G6)

---

## Claim 2: "Both walks also read the repository's worktree registry (import_readers)."

**Location:** `scripts/lib/dev-cycle-read.sh:42`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers imported_names and main_imports calling import_readers before their cache checks. It does not establish what other lib functions read.

`imported_names` runs `import_readers || { IMPORTED_DONE=""; IMPORTED=error; return 1; }` (`:1049`), and `main_imports` runs `import_readers || { IMPORTED_MAIN_DONE=""; IMPORTED_MAIN=error; return 1; }` (`:1099`). P3's `git` shim logged the `worktree` call for both walks. P1's test 5 makes `git worktree` fail and gets "walk failed" in both walks.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1049`, `:1099`, `:898`; `$S/p3-walks-ws.log`; `$S/p1-tests.log`

---

## Claim 3: contract item 4: "neither walk's cache key holds them (both hold import_readers' roots and homes, so HOME and IMPORT_READER_* need no reset; the worktree registry is read again after a reset or when one of those changes, so set them before a decision's first walk: item 9)"

**Location:** `scripts/lib/dev-cycle-read.sh:64-69`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the memo key (ROOT_REAL, HOME, both caller lists) and the walk keys (IMPORT_ROOTS, IMPORT_HOMES). It does not establish behavior when IMPORT_OUT_MAX or IMPORT_WORK_MAX changes without a reset; the item already tells the caller to reset then.

The memo key is `IMPORT_READERS_KEY="${#a}:$a ${#b}:$b ${#c}:$c ${#d}:$d"` over `a="${ROOT_REAL:-}" b="$IMPORT_HOME_DONE" c="$IMPORT_READER_ROOTS" d="$IMPORT_READER_HOMES"` (`:888-889`). `IMPORT_HOME_DONE` is HOME's key (`key="x${HOME+set}:${HOME-}"`, `:852`). The walk keys hold the resulting lists (`:1051`, `:1101`). In P6, changing `IMPORT_READER_ROOTS` alone recomputed the set, and `/host/cw` appeared in IMPORT_ROOTS. In P3, `import_reset` and two walks made a second registry read. Test 8 (h1 `-`, then h2 `imported` after only `IMPORT_READER_HOMES` changed) passes at HEAD.

**Evidence:** `scripts/lib/dev-cycle-read.sh:852`, `:887-895`, `:1051`, `:1101`; `$S/p6-units.log`; `$S/p3-walks-ws.log`; `test/scripts/build-loop-check.bats:1824-1845`

---

## Claim 4: contract item 9: "Set IMPORT_READER_ROOTS and IMPORT_READER_HOMES after sourcing the lib (which clears them) ... each is newline-separated absolute paths"

**Location:** `scripts/lib/dev-cycle-read.sh:85-89`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the clearing on source and the newline-separated absolute format import_readers enforces. It does not establish U2b3b's settings source. No script sets the lists yet (`rg IMPORT_READER scripts/*.sh` finds none).

The source-time line is `IMPORT_ROOTS=""; IMPORT_HOMES=""; IMPORT_READERS_DONE=""; IMPORT_READER_ROOTS=""; IMPORT_READER_HOMES=""` (`:883`). In test 3, values inherited from the environment give `docs/h.md -` and `docs/a.md -`. It passes at HEAD and fails at 5516c6e6 on exactly that assertion (`want: docs/h.md: -` / got `imported`, P1). Relative entries are refused (Claim 21).

**Evidence:** `scripts/lib/dev-cycle-read.sh:883`, `:906`; `test/scripts/build-loop-check.bats:1741-1754`; `$S/p1-tests.log`

---

## Claim 5: imported_names: "~/ against every reader home, and drops paths outside every reader root: import_readers ... import_readers or the parser ... fails ... One result is cached ... keyed on import_readers's roots (ROOT_REAL first) and homes; a call for another reader set recomputes it, and a cached error returns 1 again."

**Location:** `scripts/lib/dev-cycle-read.sh:569-577`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the cache key and the import_readers failure path. A failed import_readers is not cached (it clears IMPORTED_DONE and is retried); this does not contradict "a cached error returns 1 again", which concerns errors from the walk body.

The key is `IMPORTED_DONE="$IMPORT_ROOTS"$'\n\n'"$IMPORT_HOMES"` (`:1052`). ROOT_REAL comes first because `rs_r=("$ROOT_REAL")` precedes the registry paths (`:899`). need_root (`:149`) makes ROOT_REAL non-empty in a walk. Test 8's tree rows (a0 `-`, a1 `imported`, h1 `-`, h2 `imported`) pass at HEAD (P1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:149`, `:899`, `:1045-1053`; `test/scripts/build-loop-check.bats:1824-1845`; `$S/p1-tests.log`

---

## Claim 6: main_imports: "the result is cached for the commit, MAIN_BY_NAME and import_readers's roots and homes in IMPORTED_MAIN_DONE, never the checkout"

**Location:** `scripts/lib/dev-cycle-read.sh:607-611`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the key's parts. It does not establish freshness against checkout changes; the comment assigns that to import_reset.

The key is `IMPORTED_MAIN_DONE="$MAIN_SHA $MAIN_BY_NAME $IMPORT_ROOTS"$'\n\n'"$IMPORT_HOMES"` (`:1101`). Test 8's main rows pass at HEAD (P1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1099-1101`; `$S/p1-tests.log`

---

## Claim 7a: "the unit of its per-file bound of 50,000,000, about 0.1-5 s here with one root and about 9 s with 24, by the name's shape" (upper ends)

**Location:** `scripts/lib/dev-cycle-read.sh:628-630`
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium (machine timing; shapes are a sample)
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the time to spend one per-file bound on four shapes at 1 and 24 roots, with input capped at 4 MB. It does not establish that no shape is slower, or timings under load.

P5 at one root: 1.0 s (`@q<N>/x/x/...`), 1.7 s (short tokens), 0.03 s (one long run), 1.0 s (absolute). At 24 roots: 7.8 s, 0.4 s, 0.3 s, 1.4 s. Every run returned 1, so the bound was hit. The i2 fact-check measured 5.1 s and 8.8 s on its worst shape, and nothing measured here exceeds "about 5" or "about 9".

**Evidence:** `scripts/lib/dev-cycle-read.sh:628-630`; `$S/p5-bound-capped.log`; `docs/reviews/code-fact-check-report-build-loop-u2b3a-i2.md` (Claim 6)

---

## Claim 7b: "about 0.1-5 s" (lower end)

**Location:** `scripts/lib/dev-cycle-read.sh:629`
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** Medium (machine timing)
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the low end of the range. The "0.1" text is carried unchanged from main's "about 0.1-4 s" (diff line `-# per-file bound of 50,000,000, about 0.1-4 s here`). It does not establish any effect on a caller, since only the upper end bounds cost.

A single line of `@` followed by 20,000 `a`s spends the bound in 28 ms at one root (P5: `roots=1 shape=aaa.md rc=1 ms=28`), below "about 0.1 s". A tighter wording would be "about 0.03-5 s". This is low-stakes and pre-existing: the lower end bounds nothing.

**Evidence:** `scripts/lib/dev-cycle-read.sh:629`; `$S/p5-bound-capped.log`

---

## Claim 8: "/workspace's walks spend about 330,600 each over its 24 reader roots (8,200 with one; 2026-10-08)."

**Location:** `scripts/lib/dev-cycle-read.sh:632`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers /workspace at main e50aab35 with its 24 registered roots, and the same walks forced to `IMPORT_ROOTS=$ROOT_REAL`. It does not establish the figure from another checkout. From this branch's worktree the walks spend 146,085, because that checkout lacks /workspace's ignored `devcontainer-config/claude-home/CLAUDE.md` start file.

P3 output: `main work=330570`, `tree work=330570`, `roots=24`; forced to one root, `work=8240` for both walks.

**Evidence:** `scripts/lib/dev-cycle-read.sh:632`; `$S/p3-walks-ws.log`; `$S/p2-walks.log`

---

## Claim 9: "That work grows with the square of the root count (each relative name is joined once per root, and each join is projected against every root), so the honest walks spend this bound near 570 roots and then fail closed"

**Location:** `scripts/lib/dev-cycle-read.sh:633-636`
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium (extrapolated; the fake roots are about as long as the real ones)
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers /workspace's walks at 24, 48, 96 and 200 roots and a quadratic fit of them. It does not establish the crossing for roots of very different length. At today's 24 roots the linear term dominates (about 290k of 330k).

The mechanism is in the code: `for (r = 1; r <= nr; r++) for (i = 0; i <= nd; i++) put(...)` (`:729`), and in put `work += nr` plus a loop over every `pre[i]` (`:755-756`). P3 measured 330,570, 844,890, 2,322,810 and 7,580,010 work at 24, 48, 96 and 200 roots. All four lie exactly on W = 130R² + 12,070R − 33,990, which reaches 50,000,000 at R ≈ 576.

**Evidence:** `scripts/lib/dev-cycle-read.sh:729`, `:755-756`; `$S/p3-walks-ws.log`

---

## Claim 10: import_targets "reads ... import_readers' IMPORT_ROOTS and IMPORT_HOMES when its memo key is current (else ROOT_REAL alone and import_home's home: a call outside a walk)"

**Location:** `scripts/lib/dev-cycle-read.sh:654-657`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the selection at `:929-933`. It does not establish fallback behavior for an own HOME holding a newline: in the fallback, `homes="$IMPORT_HOME"$'\n'"$IMPORT_HOME_REAL"` splits such a home, and no caller reaches that path (override row, i2 N3).

```bash
# scripts/lib/dev-cycle-read.sh:929-933
  local u d toks x="" s=(-e 's/\x0/ /g') LC_ALL=C roots="${ROOT_REAL:-}" homes
  import_home || return 1
  homes="$IMPORT_HOME"$'\n'"$IMPORT_HOME_REAL"
  import_readers_key
  [[ -z "$IMPORT_READERS_DONE" || "$IMPORT_READERS_DONE" != "$IMPORT_READERS_KEY" ]] || { roots="$IMPORT_ROOTS"; homes="$IMPORT_HOMES"; }
```
(excerpt ends :933; enclosing import_targets() continues to :955 — read)

The only callers are the two walks (`:1067`, `:1142`, `:1144`), and both call import_readers first.

**Evidence:** `scripts/lib/dev-cycle-read.sh:928-955`, `:1067`, `:1142-1144`

---

## Claim 11: superset statement: "made absolute (ROOT/DIR/name for each reader root ...) ... kept only when it lies below a reader root (import_readers: ROOT_REAL, every registered worktree, the caller's IMPORT_READER_ROOTS), and printed relative to each root holding it but an outer one whose path down to a nested root holding it has a dot component ... a ~/ name is joined to each reader home ... in spelled and real forms"

**Location:** `scripts/lib/dev-cycle-read.sh:681-692`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the projection and dotnest rule on the probed shapes (roots at R, R/.claude/wt, R/sub, R/a/.x/b) and the U2b3a tests. It does not establish Claude Code's own resolution beyond what earlier units traced.

P6 printed `docs/n.md` but not `.claude/wt/docs/n.md`, both `sub/x.md` and `x.md`, `q.md` but not `a/.x/b/q.md`, and `.claude/wt2/z.md`, which is not a root. Tests 1, 2 and 4 pass at HEAD. Test 4 fails at 5516c6e6, where only the longest root printed (P1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:756-759`, `:822-823`; `$S/p6-units.log`; `$S/p1-tests.log`

---

## Claim 12: "Known exceptions ...: a session in a checkout or under a home import_readers does not list (U2b3b's settings line names the host's), names that differ only in case ..., Claude Code's approved external includes, and any further decoding"

**Location:** `scripts/lib/dev-cycle-read.sh:692-698`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** Medium (completeness against Claude Code is not re-traced here)
**Verification mode:** static
**Legibility-target:** for-orchestrator
**Scope:** Covers the removal of the two exceptions this branch models: other checkouts (absolute names and relative re-entry) and other homes, which the caller supplies. It does not establish that the list is complete. Start files only another checkout's working tree holds are the outside-starts gap, stated at `:612-614` and in override rows 431/477, which defer it to U2b3b.

The "another checkout" exception from main is gone. Tests 1 and 2 show both walks model it. Homes not listed remain an exception until U2b3b supplies them.

**Evidence:** `scripts/lib/dev-cycle-read.sh:612-614`, `:692-698`; `test/scripts/build-loop-check.bats:1717-1739`

---

## Claim 13: "It returns 1 when ... ROOT_REAL is empty, when a ~/ name appears and the home is not absolute"

**Location:** `scripts/lib/dev-cycle-read.sh:701-702`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers an empty first root (the fallback with ROOT_REAL empty, or an empty IMPORT_ROOTS) and a relative own home with a ~/ name. It does not cover one edge: a memo built by a direct import_readers call with ROOT_REAL empty would lead with a registered path instead. The walks cannot build such a memo, because need_root exits first (`:149`).

The parser runs `nr = split(ENVIRON["IT_ROOTS"], roots, "\n"); if (nr == 0 || roots[1] == "") exit 2` (`:820`) and `if (substr(homes[1], 1, 1) != "/") exit 4` (`:722`). P6: empty first root rc=1; own home `rel` with caller home `/host` and a ~/ name rc=1; the same without a ~/ name rc=0.

**Evidence:** `scripts/lib/dev-cycle-read.sh:149`, `:722`, `:820`, `:954`; `$S/p6-units.log`

---

## Claim 14: "~/ joins the home directory ..., for each reader home (the home of this process first), each in its spelled and real forms"

**Location:** `scripts/lib/dev-cycle-read.sh:718-725`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the loop over homes and their order. It does not establish how Claude Code reads an unset HOME (`:844-849`, unchanged).

`for (i = 1; i <= nh; i++) if (homes[i] != "") put(homes[i] "/" substr(c, 3))` (`:723`). The own homes come first (`:921-923`), and each caller home appears spelled and real (`:915-917`). In P6, `@~/cw/docs/h.md` with homes (own, `/host`) and root `/host/cw` printed `docs/h.md`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:721-725`, `:915-923`; `$S/p6-units.log`

---

## Claim 15: "A session in any checkout resolves the name against its own copy of the directory, so a .. can re-enter a sibling or nested worktree"

**Location:** `scripts/lib/dev-cycle-read.sh:727-729`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers resolution against each root and each directory. It does not establish relative re-entry through a root that is not listed.

Test 2 (`@.claude/wt-b/docs/n.md and @../side/docs/s.md`, gate in `../gate`) passes at HEAD for both walks and fails on main (P1). In P6, `@../k.md` from `docs` yields `k.md` and `sub/k.md`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:729`; `test/scripts/build-loop-check.bats:1728-1739`; `$S/p1-tests.log`; `$S/p6-units.log`

---

## Claim 16: put: "Relative to every root holding it, but an outer root whose path down to a nested root holding it has a dot component (dotnest) ... a root nested at any other path (a stale registry entry at sub/) must not take the outer path from the walk ... The loop over the roots is charged as work too"

**Location:** `scripts/lib/dev-cycle-read.sh:747-755`
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the projection loop and its charge. It does not establish dotnest's correctness for roots that differ only through symlinks; each spelling is a separate root.

`work += nr; if (work > wmax) exit 3` (`:755`) precedes the loop. Test 4 (a prunable `sub/` entry, then a caller root at `sub/` as written and through a symlink) passes at HEAD and fails at 5516c6e6 (P1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:731-761`; `test/scripts/build-loop-check.bats:1756-1780`; `$S/p1-tests.log`

---

## Claim 17: "IT_ROOTS and IT_HOMES: newline-separated, ROOT_REAL and the home of this process first (import_readers)."

**Location:** `scripts/lib/dev-cycle-read.sh:819-820`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers both sources (the memo and the fallback). It does not cover the unreachable empty-ROOT_REAL memo edge (Claim 13).

The order comes from `rs_r=("$ROOT_REAL")` (`:899`) and from the own homes put first (`:921`). The fallback is `roots="${ROOT_REAL:-}"`, `homes="$IMPORT_HOME"$'\n'"$IMPORT_HOME_REAL"` (`:929-931`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:819-824`, `:899`, `:921-925`, `:929-933`

---

## Claim 18: import_readers: "IMPORT_ROOTS holds ROOT_REAL, every path git worktree list registers for this repository (prunable ones too: a host path such as /home/magfrump/cw-egress-verify) and IMPORT_READER_ROOTS; IMPORT_HOMES holds import_home's two spellings and IMPORT_READER_HOMES. Each ... lists every entry as written and as realpath -m reads it, once."

**Location:** `scripts/lib/dev-cycle-read.sh:858-865`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the list's sources and deduplication. "Two spellings" collapses to one when the home is already real (`:922`). It does not establish behavior for a bare repository.

`git worktree list` shows `/home/magfrump/cw-egress-verify ... prunable`. P3 counts `roots=24` over /workspace. The dedup is `[[ -z "${rs_seen[$t$p]+set}" ]] || continue` over `"${rs_x[i]}" "${rs_real[i]}"` (`:915-917`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:891-927`; `$S/p3-walks-ws.log`

---

## Claim 19: "IMPORT_READER_ROOTS and IMPORT_READER_HOMES are the caller's (contract item 9): newline-separated absolute paths, blank lines skipped, for the host checkout Q-123 names and the host HOME ... Sourcing the lib clears them"

**Location:** `scripts/lib/dev-cycle-read.sh:865-869`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers blank-line skipping, the clearing, and the Q-123 reference. It does not establish the host path itself, which U2b3b supplies.

`[[ -n "$p" ]] || continue` (`:905`). Test 5's `T_READER_ROOTS=$'/a\n\n/b\n'` gives walk ok (P1). Q-123 (`docs/working/questions-archive.md:2084-2087`) says `~/claude-workflows` is the same repository, and U2b's root set takes `/home/magfrump/claude-workflows`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:883`, `:905`; `docs/working/questions-archive.md:2084-2087`; `$S/p1-tests.log`

---

## Claim 20: "The parser prints a name relative to every root holding it but a dot-nested outer one ..., so a root can add names and hide only dot paths."

**Location:** `scripts/lib/dev-cycle-read.sh:869-871`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** Medium (a structural argument plus probes, not an exhaustive search)
**Verification mode:** executed
**Legibility-target:** for-orchestrator
**Scope:** Covers projection: an omitted spelling is the outer root's relative path through the dotted segment between the two roots, so it has a `/.` component. A root can still fail a walk through the work or output bound (fail closed), which is not "hiding".

The dotnest condition is `index("/" substr(pre[j], length(pre[i]) + 1), "/.")` (`:823`), the same shape as truthrule's `[[ "/$1" == */.* ]]` (`:1220`). Test 4's final block pins `dot` for `.claude/wt-a/sub/y.md` and `docs/.wt/a/q.md`. In P6, a root at a non-dot path (`sub`) added `x.md` and kept `sub/x.md`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:756-759`, `:823`, `:1220`; `test/scripts/build-loop-check.bats:1777-1779`; `$S/p6-units.log`

---

## Claim 21: "It returns 1 when import_home or the listing fails, or a root or a caller's home is not absolute, holds a newline, or is / alone as written or as realpath reads it ... This process's own home is kept as the parser takes it (a relative one fails only a ~/ name), but one holding a newline is read as empty, which fails only a ~/ name too."

**Location:** `scripts/lib/dev-cycle-read.sh:871-876`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers each listed refusal, and own-home handling for relative and newline homes. It does not establish refusal of a caller home given as a symlink to `/`. Line `:913` does refuse that, since it checks the realpath.

P6: roots `/`, `//`, `/x/..`, `rel`, `/a\nrel` and homes `/`, `/x/..`, `rel` each give rc=1. `HOME=relhome` gives rc=0 with `homes=[relhome]`. A HOME holding a newline gives rc=0, with IMPORT_HOMES `\n/host` (empty first). Tests 5, 6 and 7 pass at HEAD. Tests 5 and 6 fail at 5516c6e6, and test 7 fails on main (P1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:893`, `:898`, `:904-913`, `:921`; `$S/p6-units.log`; `$S/p1-tests.log`

---

## Claim 22: "The result is memoized in IMPORT_READERS_DONE, keyed on ROOT_REAL, HOME and the caller's two lists, until import_reset (contract item 4): the registry is read once per decision, so one decision sees one root set and a cache hit forks nothing here"

**Location:** `scripts/lib/dev-cycle-read.sh:877-880`
**Type:** Performance / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the key's parts, the count of registry reads, and no external command on a hit. "Forks nothing" rests on reading `:851-853` and `:887-895` (no `$(...)` on the hit path) plus the PATH-emptied run. It does not measure subshell forks directly.

P3 (logging shim): 1 registry read for both walks plus 200 cached isimported calls; 2 after an `import_reset`. P6: with `PATH=/nonexistent`, a second import_readers returns 0. Test 8's "worktree added mid-decision is seen only after import_reset" passes at HEAD and fails at 5516c6e6 (`want: tree w1: -`, P1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:618`, `:851-853`, `:887-897`; `$S/p3-walks-ws.log`; `$S/p6-units.log`; `$S/p1-tests.log`

---

## Claim 23: "Not covered: a hostile loop can rewrite the worktree registry in the shared common dir, dropping a root (a Q-103 residual)."

**Location:** `scripts/lib/dev-cycle-read.sh:881-882`
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium (the threat-model term is project convention)
**Verification mode:** static
**Legibility-target:** for-orchestrator
**Scope:** Covers the source of the list (`git worktree list` reads the common dir's registry) and the term's use elsewhere for hostile shared-state cases (override row 509, merge-msg-build-loop-u2b1b). It does not decide the threat scope.

The list comes from `nul_list rs_l git worktree list --porcelain -z` (`:898`), and the registry lives under the common dir's `worktrees/` (`/workspace/.git/worktrees/*`). Q-103 is the build-loop policy question (`docs/working/questions.md:131`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:898`; `docs/working/questions.md:131`; `docs/working/merge-msg-build-loop-u2b1b.md:18`

---

## Claim 24: "import_readers_key: IMPORT_READERS_KEY, the key import_readers memoizes on (after import_home), each part led by its length so no part can run into the next."

**Location:** `scripts/lib/dev-cycle-read.sh:884-885`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers unambiguity of the encoding. It does not establish that HOME is fully represented beyond IMPORT_HOME_DONE's `x${HOME+set}:${HOME-}`, which is.

`IMPORT_READERS_KEY="${#a}:$a ${#b}:$b ${#c}:$c ${#d}:$d"` (`:889`). Each length prefix fixes where its part ends.

**Evidence:** `scripts/lib/dev-cycle-read.sh:852`, `:887-890`

---

## Claim 25: "resolved in one realpath call (a fork per root cost 14 ms over 24 roots)"

**Location:** `scripts/lib/dev-cycle-read.sh:902-903`
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium (machine timing)
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers 24 `$(realpath -m)` forks against one `realpath -mz` with 24 arguments on this machine. It does not establish load-dependent variance.

P6: `24 forks avg ms=17`, `one call avg ms=1`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:910`; `$S/p6-units.log`

---

## Claim 26: "The roots never hold an empty line, so the blank line ends them."

**Location:** `scripts/lib/dev-cycle-read.sh:1050`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers IMPORT_ROOTS as import_readers builds it. A memo built with an empty ROOT_REAL still has no empty line, since the empty entry is skipped. It does not cover IMPORT_HOMES, which may lead with an empty line; that is harmless after the separator.

Entries come from `rs_x` (non-empty, `:905`) and `rs_real` (non-empty, `:913`). The two cache keys (`:1051`, `:1101`) therefore split uniquely at the first `\n\n`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:905`, `:913`, `:924`, `:1050-1052`

---

## Claim 27: truthrule: "the parser's dotnest omits only such paths: keep the two equal"

**Location:** `scripts/lib/dev-cycle-read.sh:1220`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the agreement of dotnest's `/.` test (`:823`) with truthrule's `*/.*`. It does not establish which truthrule word fires first: case or instr may pre-empt dot, and either still refuses.

Test 4's last block passes at HEAD (P1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:823`, `:1216-1222`; `test/scripts/build-loop-check.bats:1777-1779`; `$S/p1-tests.log`

---

## Claim 28: the U2b3a feature tests (absolute name into another worktree; relative name against every worktree's directory; a worktree path holding a newline) test what their names say and are red without the change

**Location:** `test/scripts/build-loop-check.bats:1717`, `:1728`, `:1815`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator
**Scope:** Covers each test's body against its name, and red/green at main, 5516c6e6 and HEAD. It does not establish coverage of shapes beyond those in the bodies.

P1: all three fail with main's lib and pass at 5516c6e6, 4dba56dc and HEAD. Each body asserts both walks (`for w in tree main`).

**Evidence:** `test/scripts/build-loop-check.bats:1717-1739`, `:1815-1822`; `$S/p1-tests.log`

---

## Claim 29: the U2b3a fix tests (caller lists and environment; nested non-dot root; fail-closed refusals; HOME newline; cache key and memo) were red on 5516c6e6, as the rubric says

**Location:** `test/scripts/build-loop-check.bats:1741`, `:1756`, `:1782`, `:1801`, `:1824`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator
**Scope:** Covers red at 5516c6e6, green at HEAD, and the failing assertion each time (P1 shows the `want:` line). It does not establish that each would fail on every possible regression of its fix.

At 5516c6e6, test 3 fails at the inherited-environment assertion (A2), test 4 at the nested root (A1), test 5 at a refusal (G3), test 6 at the no-`~/` newline HOME (G2), and test 8 at `tree w1` (A3). All pass at HEAD. Test 6's "as a relative HOME does" refers to the existing relative-HOME test (`:698`), not to its own body.

**Evidence:** `test/scripts/build-loop-check.bats:698`, `:1741-1845`; `$S/p1-tests.log`; `docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b3a.md` (A1-A3, G2, G3)

---

## Claim 30: test name "both walk caches key on the reader set, which is read once until import_reset"

**Location:** `test/scripts/build-loop-check.bats:1824`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the key half for both walks (a0, a1, h1, h2, w2) and the read-once half through the tree walk only (`want "tree w1" -`). The main iteration's w1 is not asserted, because the worktree was already added. The memo is shared by both walks (one `import_readers`), so the single assertion covers the shared reader set.

Passes at HEAD; fails at 5516c6e6 on `tree w1` (P1).

**Evidence:** `test/scripts/build-loop-check.bats:1824-1845`; `$S/p1-tests.log`

---

## Claim 31: dev-cycle.bats' sourced-definitions test lists import_readers, import_readers_key and the five new globals

**Location:** `test/scripts/dev-cycle.bats:1110`, `:1114`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers definition at source time. It does not establish that the list names every lib function, which was already incomplete (rubric G10).

P1: it passes at HEAD and fails with main's, 5516c6e6's and 4dba56dc's libs (the last because `readers_key` was renamed in 3d2d8c44).

**Evidence:** `test/scripts/dev-cycle.bats:1101-1118`; `$S/p1-tests.log`

---

## Claim 32: commit 3d2d8c44: "the work-bound figures (about 9 s with 24 roots, 8,200 with one) ... work grows with the square of the root count (fails closed near 570) ... Notes: text and test changes only, besides the rename."

**Location:** commit 3d2d8c44 message
**Type:** Reference / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator
**Scope:** Covers the figures (Claims 7a, 8, 9) and the code-line diff. It does not re-verify the i2 rubric's descriptions of B1/B2.

The non-comment lines that 3d2d8c44 changes in the lib are only the `readers_key`→`import_readers_key` / `READERS_KEY`→`IMPORT_READERS_KEY` rename and a trailing comment on truthrule's dot line (`git show 3d2d8c44 -- scripts/lib/dev-cycle-read.sh | grep '^[-+]' | grep -v '^[-+]\s*#'`). No stale `readers_key`, `reader_set`, `IT_ROOT` or `homereal` remains in scripts/ or test/ (`rg`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:884-890`, `:1220`; `$S/p3-walks-ws.log`; `$S/p5-bound-capped.log`

---

## Claim 33: brief claim 5: "Over this repo (/workspace, 24 registered roots) both walks give main's 128 names; a cached isimported takes about 3 ms."

**Location:** shared brief, claim 5 (applies to `scripts/lib/dev-cycle-read.sh:1045-1078`, `:1193-1202`)
**Type:** Performance / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator
**Scope:** Covers /workspace at main e50aab35. It does not establish the count from a gate worktree. From this branch's worktree (and a fresh clone) both walks give 64 names, all of them shared with /workspace's. The other 64 lie under /workspace's ignored `devcontainer-config/claude-home/`, whose `CLAUDE.md` is a start file only in that checkout. That is the outside/other-checkout start gap deferred to U2b3b (rows 431/477), and none of those 64 names is a tracked path.

P3: `names main=128 (distinct 128) tree=128 (distinct 128) same=yes`, `roots=24`, and cached isimported averages 3.5 ms (200 calls).

**Evidence:** `$S/p3-walks-ws.log`; `$S/p2-walks.log`; `$S/names-workspace.txt`, `$S/names-wt-build-loop-u2b3a.txt`

---

## Claims Requiring Attention

### Incorrect
None.

### Stale
None.

### Mostly Accurate
- **Claim 7b** (`scripts/lib/dev-cycle-read.sh:629`): the per-file bound's lower end "about 0.1 s" measures 0.03 s for a single long `@` run. The text is carried unchanged from main's "0.1-4 s", and only the upper end bounds cost (informational).

### Unverifiable
None.

---

## Goal-Alignment Note

**Success criterion (verbatim):** A markdown report saved to the output path below, structured per the code-fact-check skill, with `Commit: 3d2d8c44` as its first line.

**Answered:** All five brief claim groups were checked against the code and by execution: import_readers (Claims 18-25), the parser (11-17, 20, 27), the lib header and IMPORT_WORK_MAX figures (2-4, 7a-9), the U2b3a tests red/green at main, 5516c6e6 and HEAD (28-31), and /workspace's 128 names and 3 ms (33). Every iteration-1/2 fix the rubric lists as fixed holds (A1-A3, G2, G3, G5-G7, G10, B1, B2, H1, H3). Count: 33 Verified, 1 Mostly accurate (pre-existing low-end text).

**Out of scope:** Override-row items (U2b3b host alias and outside starts, U2c floor, dotnest rebuild cost, Accepted-immutable commit figures). Code quality and design.

**Escalate:** None blocking. One observation for the synthesis: walks from a gate worktree give 64 names where /workspace gives 128. The difference is /workspace's ignored `devcontainer-config/claude-home/CLAUDE.md`, a start file only that checkout holds. None of the names it adds is tracked, and the gap belongs to U2b3b's outside starts (rows 431/477). It is not a new defect of this branch.

**Decisions I made:** I split the IMPORT_WORK_MAX per-file timing into upper ends (Verified) and lower end (Mostly accurate) rather than folding a pre-existing imprecision into a Verified. I measured /workspace's figures from `/workspace` itself, read-only, as the claims name it. I added no worktrees to the shared registry, so other agents' root counts were not disturbed. I did not edit the hallucination log: there is no Incorrect fabrication.
