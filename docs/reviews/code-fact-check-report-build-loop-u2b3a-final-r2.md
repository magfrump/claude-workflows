Commit: 3d2d8c44
# Code Fact-Check Report

**Repository:** /workspace (worktree `/workspace/.claude/wt-build-loop-u2b3a`, branch `feat/build-loop-u2b3a`)
**Scope:** `git diff main...HEAD -- scripts test` (main e50aab35, HEAD 3d2d8c44): `scripts/lib/dev-cycle-read.sh`, `test/scripts/build-loop-check.bats`, `test/scripts/dev-cycle.bats`; plus claims in plan step 5's U2b3 bullet (`docs/working/plan-build-loop-handoff.md:285-299`) and commit 3d2d8c44's message. Final confirming pass, replicate r2 of k=3.
**Checked:** 2026-10-08
**Total claims checked:** 30
**Summary:** 30 verified, 0 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Hallucination log (`docs/reviews/hallucination-patterns.md`) read first. No claim matches a logged pattern; every symbol the comments name (`import_readers`, `import_readers_key`, `IMPORT_READERS_DONE`, `dotnest`, `truthrule`, `floor`, `check_fix`, Q-103, Q-121, Q-123) exists.

Settled items not re-filed: override rows 425, 431, 432, 437, 477 and this branch's nine rows (`overrides.txt`), which include the 5516c6e6 and 4dba56dc commit-message figures (Accepted-immutable). Rubric iterations 1-2 items marked fixed were re-checked: A1, A2, A3, G2, G3, G4, G5, G7, G10, B1, B2, H1 and H3 all hold at 3d2d8c44.

## Execution provenance

All probes are single scripts that start `set -eu`, create their own `mktemp -d /tmp/u2b3a3-fc2-XXXX` directory and check `pwd -P` before running anything. None ran `git init`, `git commit` or `git worktree add` outside a bats fixture. All were invoked with `bash <script>` from cwd `/workspace/.claude/wt-build-loop-u2b3a`. The walk probes `cd /workspace` (main checkout, on main e50aab35) because need_root requires cwd = ROOT_REAL. They read only.
`$L` = `/tmp/claude-1000/-workspace/53eaab1e-c162-42ac-afd9-547bb673cbb3/scratchpad/u2b3a3-fc2/logs`; scripts are in `$L/..`.

| ID | Command | Started (UTC) | Exit | Output |
|---|---|---|---|---|
| E1 | `bash probe-tests.sh`: archives HEAD; runs `bats -f U2b3a test/scripts/build-loop-check.bats` with the lib swapped for HEAD, 5516c6e6, 4dba56dc, c9197fd2 and main e50aab35; runs dev-cycle.bats' sourced-definitions test with HEAD's lib and main's | 2026-10-09T04:20Z | 0 | `$L/tests-meta.txt`, `$L/bats-lib-{HEAD,5516c6e6,4dba56dc,c9197fd2,e50aab35}.txt`, `$L/bats-devcycle-sourced-{HEAD,mainlib}.txt` |
| E2 | `bash probe-walk.sh <HEAD lib> $L/walk`: both walks over /workspace (24 reader roots), charged work, cached isimported timing; then IMPORT_ROOTS forced to ROOT_REAL alone | 2026-10-09T04:21:05Z | 0 | `$L/walk-head.txt`, `$L/walk/names-{tree,main}.txt` (wall times blank: `bc` is not installed) |
| E3 | `bash probe-mainlib.sh $L/walk`: main's lib walks the same checkout; the name sets are compared with E2's | 2026-10-09T04:21:22Z | 0 | `$L/mainlib-compare.txt` |
| E4 | `bash probe-bound.sh`: time to spend one parser bound on three 4 MiB shapes at 24 and 1 roots | 2026-10-09T04:21:44Z | 0 | `$L/bound.txt` |
| E5 | `bash probe-bound2.sh`: shape A with no output cap at 1 and 24 roots | 2026-10-09T04:22:16Z | 0 | `$L/bound2.txt` |
| E6 | `bash probe-roots.sh`: honest tree walk over /workspace at 24/200/540/560/580/600 roots (synthetic roots appended under /workspace/.claude/) | 2026-10-09T04:22:41Z | 0 | `$L/roots.txt` |
| E7 | `bash probe-misc.sh`: 24 realpath forks against one batched call; import_targets outside and inside a walk's memo with a newline HOME; exit 2 on an empty first root; dotnest over /workspace's roots | 2026-10-09T04:24:13Z | 0 | `$L/misc.txt` |

Load average was 0.4-0.5 during the timed runs.

---

## Claim 1: "Both walks also read the repository's worktree registry (import_readers)."

**Location:** `scripts/lib/dev-cycle-read.sh:42`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-reviewer
**Scope:** Covers that both walks call import_readers, which runs `git worktree list`. Does not establish anything about other functions in the Inputs paragraph.

Both walks call import_readers right after need_root: `import_readers || { IMPORTED_DONE=""; IMPORTED=error; return 1; }` (`:1049`) and `import_readers || { IMPORTED_MAIN_DONE=""; IMPORTED_MAIN=error; return 1; }` (`:1099`). import_readers runs `nul_list rs_l git worktree list --porcelain -z || return 1` (`:898`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:42`, `:898`, `:1049`, `:1099`

---

## Claim 2: Contract item 4: "neither walk's cache key holds them (both hold import_readers' roots and homes, so HOME and IMPORT_READER_* need no reset; the worktree registry is read again after a reset or when one of those changes, so set them before a decision's first walk: item 9)"

**Location:** `scripts/lib/dev-cycle-read.sh:64-69`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-caller
**Scope:** Covers both walk cache keys, the memo key's parts (ROOT_REAL, HOME through IMPORT_HOME_DONE, both caller lists), and import_reset clearing the memo. Does not establish behaviour when a caller changes IMPORT_OUT_MAX or IMPORT_WORK_MAX without a reset (the item tells the caller to reset).

The walk keys are `"$IMPORT_ROOTS"$'\n\n'"$IMPORT_HOMES"` (`:1051-1052`) and `"$MAIN_SHA $MAIN_BY_NAME $IMPORT_ROOTS"$'\n\n'"$IMPORT_HOMES"` (`:1100-1101`). Neither holds IMPORT_OUT_MAX or IMPORT_WORK_MAX. The memo key is `local a="${ROOT_REAL:-}" b="$IMPORT_HOME_DONE" c="$IMPORT_READER_ROOTS" d="$IMPORT_READER_HOMES"` (`:888`), and `IMPORT_HOME_DONE` is `key="x${HOME+set}:${HOME-}"` (`:852`). A change to HOME or either list therefore misses the memo, and the registry is read again (`:895-898`). `import_reset() { IMPORTED_DONE=""; IMPORTED_MAIN_DONE=""; IMPORT_READERS_DONE=""; }` (`:618`). E1: the test at build-loop-check.bats:1824 passes at HEAD. It asserts a1/h2 imported after changing the lists without a reset, and w1 `-` then w2 imported around import_reset.

**Evidence:** `scripts/lib/dev-cycle-read.sh:64-69`, `:618`, `:852`, `:886-898`, `:1051-1052`, `:1100-1101`; `$L/bats-lib-HEAD.txt` (ok 8)

---

## Claim 3: Contract item 9: "Set IMPORT_READER_ROOTS and IMPORT_READER_HOMES after sourcing the lib (which clears them) ... never from the environment: each is newline-separated absolute paths"

**Location:** `scripts/lib/dev-cycle-read.sh:85-89`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-caller
**Scope:** Covers the clear on source and that the lib refuses non-absolute entries. Does not establish U2b3b's settings reader, which does not exist yet: no script outside the lib sets either variable (`grep -rn IMPORT_READER_ scripts`: no hits outside the lib).

The variables are cleared at source time: `IMPORT_ROOTS=""; IMPORT_HOMES=""; IMPORT_READERS_DONE=""; IMPORT_READER_ROOTS=""; IMPORT_READER_HOMES=""` (`:883`). E1: test :1741 passes at HEAD and fails at 5516c6e6 (`not ok 3`). That test's inherited `IMPORT_READER_ROOTS=/host/cw IMPORT_READER_HOMES=/host` rows expect `-`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:85-89`, `:883`; `test/scripts/build-loop-check.bats:1741-1754`; `$L/bats-lib-HEAD.txt`, `$L/bats-lib-5516c6e6.txt`

---

## Claim 4: imported_names: "~/ against every reader home, and drops paths outside every reader root ... returns 1 ... when ... import_readers ... fails ... One result is cached ... keyed on import_readers's roots (ROOT_REAL first) and homes; a call for another reader set recomputes it, and a cached error returns 1 again."

**Location:** `scripts/lib/dev-cycle-read.sh:569-577`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-reviewer
**Scope:** Covers the failure on import_readers, the cache key and the cached-error return for imported_names (read to `:1083`). Does not establish the unchanged start-listing failures.

`import_readers || { IMPORTED_DONE=""; IMPORTED=error; return 1; }` (`:1049`). `[[ "$IMPORTED_DONE" == "$IMPORT_ROOTS"$'\n\n'"$IMPORT_HOMES" ]] && { [[ "$IMPORTED" != error ]]; return; }` (`:1051`) returns 1 on a cached error. E1 tests :1782 (fail closed on bad roots, homes and a failing `git worktree list`) and :1824 (key) pass at HEAD.

**Evidence:** `scripts/lib/dev-cycle-read.sh:569-577`, `:1045-1083`; `$L/bats-lib-HEAD.txt`

---

## Claim 5: main_imports: "the result is cached for the commit, MAIN_BY_NAME and import_readers's roots and homes in IMPORTED_MAIN_DONE, never the checkout"

**Location:** `scripts/lib/dev-cycle-read.sh:607-611`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-reviewer
**Scope:** Covers the key string. Does not establish phase 2's checkout handling (unchanged).

`IMPORTED_MAIN=error; IMPORTED_MAIN_DONE="$MAIN_SHA $MAIN_BY_NAME $IMPORT_ROOTS"$'\n\n'"$IMPORT_HOMES"` (`:1101`). No checkout state enters it.

**Evidence:** `scripts/lib/dev-cycle-read.sh:607-611`, `:1094-1101`

---

## Claim 6: IMPORT_WORK_MAX: the charged work is "the candidate and comment-splice characters it scans, each resolved spelling it joins, which for a relative name carries a root ... and one unit per reader root for each spelling it projects"

**Location:** `scripts/lib/dev-cycle-read.sh:626-629`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-reviewer
**Scope:** Covers the three charges in emit and put. Does not re-verify the unchanged splice charge.

emit charges `work += length(c)` (`:713`). put charges `work += length(c)` for the joined spelling (`:734`) and `work += nr; if (work > wmax) exit 3` per projection (`:755`). The relative join is `put(roots[r] "/" dirs[i] "/" c)` (`:729`), so the root's length is in `c`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:714-760`

---

## Claim 7: "the unit of its per-file bound of 50,000,000, about 0.1-5 s here with one root and about 9 s with 24, by the name's shape"

**Location:** `scripts/lib/dev-cycle-read.sh:629-630`
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium (wall time depends on machine and load; the upper figures rest partly on iteration 2's synthetic-root runs)
**Verification mode:** executed
**Legibility-target:** for-reviewer
**Scope:** Covers one spent bound on three shapes against /workspace's real 24 roots and ROOT_REAL alone. Does not establish a worst case over all shapes, or timings under load.

E4/E5 used /workspace's real roots. An unclosed quote spent the bound in 0.18 s at 1 root and 0.19 s at 24. Short tokens took 0.44 s at 24 roots. The `@q<N>/x/x/...` shape, at about 1,500 characters a line, took 2.85 s at 1 root and 7.1-7.5 s at 24. Iteration 2's report measured 5.1 s and 8.8 s on the same shape with synthetic roots (`docs/reviews/code-fact-check-report-build-loop-u2b3a-i2.md:162`). These runs are inside "about 0.1-5 s" and "about 9 s".

**Evidence:** `scripts/lib/dev-cycle-read.sh:629-630`, `:642`; `$L/bound.txt`, `$L/bound2.txt`

---

## Claim 8: "/workspace's walks spend about 330,600 each over its 24 reader roots (8,200 with one; 2026-10-08)."

**Location:** `scripts/lib/dev-cycle-read.sh:632`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-reviewer
**Scope:** Covers both walks over /workspace at main e50aab35 with today's 24 registered worktrees. Does not establish the figure after the registry or main changes.

E2 printed `tree: ... work 330570`, `main: ... work 330570`, `one-root tree: ... work 8240` and `one-root main: ... work 8240`. The IMPORT_ROOTS listing has 24 lines; every spelled path equals its real path.

**Evidence:** `scripts/lib/dev-cycle-read.sh:632`; `$L/walk-head.txt`

---

## Claim 9: "That work grows with the square of the root count (each relative name is joined once per root, and each join is projected against every root), so the honest walks spend this bound near 570 roots and then fail closed"

**Location:** `scripts/lib/dev-cycle-read.sh:633-636`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-reviewer
**Scope:** Covers the tree walk over /workspace with synthetic roots appended under `/workspace/.claude/`. Does not establish the exact crossing for other root lengths or for the main walk, which E2 shows charges the same work at 24 roots.

The mechanism is in the code: the root loop `for (r = 1; r <= nr; r++) for (i = 0; i <= nd; i++) put(...)` (`:729`) calls put once per root, and each put charges `work += nr` (`:755`). E6 printed: 24 roots, ok, 330,570; 200, ok, 7,364,210; 540, ok, 43,778,210; 560, ok, 46,856,210; 580, failed; 600, failed. The bound is crossed between 560 and 580. The growth is a linear term plus a square term, and the square term dominates from a few hundred roots.

**Evidence:** `scripts/lib/dev-cycle-read.sh:633-636`, `:729`, `:755`; `$L/roots.txt`

---

## Claim 10: import_targets reads "import_readers' IMPORT_ROOTS and IMPORT_HOMES when its memo key is current (else ROOT_REAL alone and import_home's home: a call outside a walk)"

**Location:** `scripts/lib/dev-cycle-read.sh:655-657`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-caller
**Scope:** Covers the selection between the two lists. Does not establish that the fallback applies import_readers' newline-home rule, and it does not (see below; no caller reaches it).

The defaults are `roots="${ROOT_REAL:-}"` and `homes="$IMPORT_HOME"$'\n'"$IMPORT_HOME_REAL"` (`:929-931`), and `[[ -z "$IMPORT_READERS_DONE" || "$IMPORT_READERS_DONE" != "$IMPORT_READERS_KEY" ]] || { roots="$IMPORT_ROOTS"; homes="$IMPORT_HOMES"; }` (`:933`). E7 ran with `HOME=<dir>$'\n'x` and `@~/x.md`. A bare import_targets call exits 0, because the raw home splits into an absolute first line. After import_readers it exits 1, because the home is read as empty and the parser exits 4. This matches the comment ("import_home's home"). It is the override row's out-of-walk fallback (architecture i2 N3), not a contradiction.

**Evidence:** `scripts/lib/dev-cycle-read.sh:655-657`, `:928-957`; `$L/misc.txt`

---

## Claim 11: Superset statement: a name is "kept only when it lies below a reader root (import_readers: ROOT_REAL, every registered worktree, the caller's IMPORT_READER_ROOTS), and printed relative to each root holding it but an outer one whose path down to a nested root holding it has a dot component (the parser's dotnest ...). A relative name is resolved against each root's copy of its directory ... a ~/ name is joined to each reader home ... in spelled and real forms."

**Location:** `scripts/lib/dev-cycle-read.sh:684-695`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-reviewer
**Scope:** Covers the keep, projection and resolution rules as put and emit implement them. Does not establish the listed known exceptions (case, approved external includes, further decoding), which are unchanged.

put keeps a name only under some `pre[i]` and prints it relative to each holding root unless a dotnest pair exists: `for (j = 1; j <= nho; j++) if ((h[i], h[j]) in dotnest) break; if (j > nho) show(substr(out, length(pre[h[i]]) + 1))` (`:756-759`). E7 fed `@/workspace/.claude/wt-build-loop-u2b2/docs/n.md` over /workspace's roots. The parser printed `docs/n.md` and not the outer `.claude/wt-build-loop-u2b2/docs/n.md`. E1 tests :1717, :1728 and :1756 pass at HEAD and fail on main's lib.

**Evidence:** `scripts/lib/dev-cycle-read.sh:684-695`, `:741-760`; `$L/misc.txt`; `$L/bats-lib-HEAD.txt`, `$L/bats-lib-e50aab35.txt`

---

## Claim 12: emit: "~/ ... for each reader home (the home of this process first), each in its spelled and real forms", with exit 4 when the first home is not absolute

**Location:** `scripts/lib/dev-cycle-read.sh:719-724`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-reviewer
**Scope:** Covers the join over IT_HOMES and the exit 4 rule on `homes[1]`. Does not establish that a caller home is tried when this process's home is relative (it is not: exit 4 comes first, as the comment orders).

The code is `if (substr(homes[1], 1, 1) != "/") exit 4` then `for (i = 1; i <= nh; i++) if (homes[i] != "") put(homes[i] "/" substr(c, 3))` (`:722-723`). import_readers lists this process's home first, then `IMPORT_HOME_REAL` and the caller homes in both spellings (`:920-923`). E1 tests :1741 (`@~/cw/docs/h.md` imported only with `T_READER_HOMES=/host`) and :1801 pass.

**Evidence:** `scripts/lib/dev-cycle-read.sh:714-730`, `:920-923`; `$L/bats-lib-HEAD.txt`

---

## Claim 13: "A session in any checkout resolves the name against its own copy of the directory, so a .. can re-enter a sibling or nested worktree (U2b3a)."

**Location:** `scripts/lib/dev-cycle-read.sh:727-729`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-reviewer
**Scope:** Covers registered and caller roots. Does not establish that the walk reads each checkout's file content; it reads ROOT_REAL's checkout and main.

`for (r = 1; r <= nr; r++) for (i = 0; i <= nd; i++) put(roots[r] "/" dirs[i] "/" c)` (`:729`). E1 test :1728 passes at HEAD and fails on main's lib. It covers `@.claude/wt-b/docs/n.md` and `@../side/docs/s.md`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:727-729`; `$L/bats-lib-HEAD.txt`, `$L/bats-lib-e50aab35.txt`

---

## Claim 14: put: "Relative to every root holding it, but an outer root whose path down to a nested root holding it has a dot component (dotnest) ... the outer spelling is a dot path the floor refuses whole ... while a root nested at any other path (a stale registry entry at sub/) must not take the outer path from the walk ... The loop over the roots is charged as work too"

**Location:** `scripts/lib/dev-cycle-read.sh:747-760`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-reviewer
**Scope:** Covers the projection, the charge, and the claim that both consumers refuse dot paths before the walk. Does not establish U2c's caller of floor.

floor runs `if truthrule "$lp"; then ... dot) FLOOR_WHY="a dotfile or a path under a dot-directory"` before `truthwalk main` (`:1270-1287`). check_fix also tests truthrule before `truthwalk tree`: `elif [[ -n "$TRUTH_WHY" || ...` (`scripts/dev-cycle.sh:178-180`). E1 test :1756 (a stale `sub/` entry, then a caller root at `sub/` as written and through a symlink) passes at HEAD and fails at 5516c6e6. The charge is `work += nr` (`:755`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:741-760`, `:1265-1290`; `scripts/dev-cycle.sh:172-184`; `$L/bats-lib-HEAD.txt`, `$L/bats-lib-5516c6e6.txt`

---

## Claim 15: BEGIN: "IT_ROOTS and IT_HOMES: newline-separated, ROOT_REAL and the home of this process first (import_readers)", exit 2 on an empty first root

**Location:** `scripts/lib/dev-cycle-read.sh:819-823`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-reviewer
**Scope:** Covers the ordering import_readers produces and the exit 2 check. Does not establish the fallback's ordering of a newline-split home (Claim 10).

The check is `nr = split(ENVIRON["IT_ROOTS"], roots, "\n"); if (nr == 0 || roots[1] == "") exit 2` (`:820`). E7 ran the awk program directly with `IT_ROOTS=` and got `awk rc=2`. Through import_targets with ROOT_REAL unset it returned `rc=1`. import_readers puts ROOT_REAL first: `rs_r=("$ROOT_REAL")` (`:899`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:815-826`, `:899`; `$L/misc.txt`

---

## Claim 16: dotnest table built in BEGIN holds only for a strictly longer root under another's `/`-bounded prefix whose remainder has a dot-led component

**Location:** `scripts/lib/dev-cycle-read.sh:821-823`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-reviewer
**Scope:** Covers the condition text. Does not establish behaviour for spelled roots holding `..`; put's output is lexically normalized, so such a spelling never prefixes it and only matters as a dead entry.

The condition is `length(pre[j]) > length(pre[i]) && index(pre[j], pre[i]) == 1 && index("/" substr(pre[j], length(pre[i]) + 1), "/.")` (`:823`). `pre[i]` ends in `/` (`:821`), so the prefix test is component-bounded.

**Evidence:** `scripts/lib/dev-cycle-read.sh:819-824`

---

## Claim 17: import_readers' list contents: "ROOT_REAL, every path git worktree list registers for this repository (prunable ones too: a host path such as /home/magfrump/cw-egress-verify) and IMPORT_READER_ROOTS; IMPORT_HOMES holds import_home's two spellings and IMPORT_READER_HOMES. Each is newline-separated, ROOT_REAL or this process's home first, and lists every entry as written and as realpath -m reads it, once."

**Location:** `scripts/lib/dev-cycle-read.sh:858-865`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-reviewer
**Scope:** Covers the root and home lists' construction and dedup. Does not establish dedup across kinds (a path can be both a root and a home, by design).

Every `worktree ` record is taken: `for p in "${rs_l[@]}"; do [[ "$p" != "worktree "* ]] || rs_r+=("${p#worktree }"); done` (`:899`). Prunable entries are not filtered. Dedup is per kind: `[[ -z "${rs_seen[$t$p]+set}" ]] || continue` (`:916`). `git worktree list --porcelain` at /workspace lists `worktree /home/magfrump/cw-egress-verify ... prunable gitdir file points to non-existent location`. E2's IMPORT_ROOTS has 24 lines for the 24 registered worktrees.

**Evidence:** `scripts/lib/dev-cycle-read.sh:858-865`, `:891-926`; `$L/walk-head.txt`

---

## Claim 18: "IMPORT_READER_ROOTS and IMPORT_READER_HOMES are the caller's (contract item 9): newline-separated absolute paths, blank lines skipped ... Sourcing the lib clears them, so the environment never sets them."

**Location:** `scripts/lib/dev-cycle-read.sh:865-869`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-caller
**Scope:** Covers blank-line skipping, the role tagging that keeps blank root lines from shifting homes into roots, and the clear on source. Does not establish U2b3b's reader.

Blank entries are skipped with `[[ -n "$p" ]] || continue` (`:905`), and `n=${#rs_r[@]}; for p in "${rs_r[@]}"; do [[ -n "$p" ]] || n=$((n - 1)); done` (`:909`) counts only non-blank roots. E1 test :1782's row `T_READER_ROOTS=$'/a\n\n/b\n'` gives `walk ok`. Test :1741's inherited row gives `-`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:865-869`, `:883`, `:899-909`; `$L/bats-lib-HEAD.txt`

---

## Claim 19: "It returns 1 when import_home or the listing fails, or a root or a caller's home is not absolute, holds a newline, or is / alone as written or as realpath reads it ... This process's own home is kept as the parser takes it (a relative one fails only a ~/ name), but one holding a newline is read as empty, which fails only a ~/ name too."

**Location:** `scripts/lib/dev-cycle-read.sh:871-876`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-reviewer
**Scope:** Covers each refusal and the own-home handling within walks. Does not establish the out-of-walk fallback (Claim 10).

The refusals are `[[ "$p" == /* && "$p" != *$'\n'* && -n "${p//\//}" ]] || return 1` (`:906`) and `[[ -n "${rs_real[i]//\//}" && "${rs_real[i]}" != *$'\n'* ]] || return 1` (`:913`). This process's homes go through `[[ "$p" != *$'\n'* ]] || p=""` (`:921`) only. E1: test :1782 (`rel/cw`, `/`, `//`, `/x/..`, `rel`, a relative second line, and a git shim failing `worktree`) gives `walk failed` in both walks. Test :1801 (newline HOME, walk ok without `~/`, failed with it) and test :1815 (a registry path holding a newline; not skipped) pass. The older test at build-loop-check.bats:697 covers the relative-home exit.

**Evidence:** `scripts/lib/dev-cycle-read.sh:871-876`, `:893-924`; `test/scripts/build-loop-check.bats:697-701`; `$L/bats-lib-HEAD.txt`

---

## Claim 20: "The result is memoized in IMPORT_READERS_DONE, keyed on ROOT_REAL, HOME and the caller's two lists, until import_reset (contract item 4): the registry is read once per decision, so one decision sees one root set and a cache hit forks nothing here"

**Location:** `scripts/lib/dev-cycle-read.sh:877-880`
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-reviewer
**Scope:** Covers the memo and its key, and the absence of forks on a hit inside import_readers. Does not establish fork-freedom of the walk's other cache-hit steps (need_root forks `pwd -P`; isimported forks `lower`).

On a hit, import_home returns with `[[ "$IMPORT_HOME_DONE" != "$key" ]] || return 0` (`:853`), import_readers_key is pure bash (`:887-890`), and the check is `[[ "$IMPORT_READERS_DONE" != "$IMPORT_READERS_KEY" ]] || return 0` (`:895`). E1 test :1824 (`tree w1: -`, then imported after import_reset) passes at HEAD and fails at 5516c6e6. E2 measured a cached isimported at 3.2 ms (main) and 3.0 ms (tree).

**Evidence:** `scripts/lib/dev-cycle-read.sh:851-856`, `:877-896`; `$L/bats-lib-HEAD.txt`, `$L/bats-lib-5516c6e6.txt`, `$L/walk-head.txt`

---

## Claim 21: "Not covered: a hostile loop can rewrite the worktree registry in the shared common dir, dropping a root (a Q-103 residual)."

**Location:** `scripts/lib/dev-cycle-read.sh:881-882`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-reviewer
**Scope:** Covers that Q-103 exists and that the registry is read from git's shared state with no integrity check. Does not establish the residual's severity.

`### Q-103 · dev-cycle-build-loop-policy` is OPEN in `docs/working/questions.md:131`. The registry is read only through `git worktree list --porcelain -z` (`:898`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:881-882`, `:898`; `docs/working/questions.md:131-134`

---

## Claim 22: "import_readers_key: IMPORT_READERS_KEY, the key import_readers memoizes on (after import_home), each part led by its length so no part can run into the next."

**Location:** `scripts/lib/dev-cycle-read.sh:884-890`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-reviewer
**Scope:** Covers the encoding. Does not establish anything beyond the four parts.

The key is `IMPORT_READERS_KEY="${#a}:$a ${#b}:$b ${#c}:$c ${#d}:$d"` (`:889`), so each part's length fixes its end.

**Evidence:** `scripts/lib/dev-cycle-read.sh:884-890`

---

## Claim 23: "resolved in one realpath call (a fork per root cost 14 ms over 24 roots)"

**Location:** `scripts/lib/dev-cycle-read.sh:902-903`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-reviewer
**Scope:** Covers 24 `realpath -m` forks on this machine. Does not establish other machines.

The single call is `nul_list rs_real realpath -mz -- "${rs_x[@]}" || return 1` (`:910`). In E7, 24 forks took 11.8-13.6 ms over five runs, and one batched call took 1.0-1.2 ms.

**Evidence:** `scripts/lib/dev-cycle-read.sh:902-910`; `$L/misc.txt`

---

## Claim 24: "This process's own homes come first, kept as the parser reads them." and "The roots never hold an empty line, so the blank line ends them."

**Location:** `scripts/lib/dev-cycle-read.sh:920`, `:1050`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-reviewer
**Scope:** Covers both invariants as the code builds them. Does not establish anything about IMPORT_HOMES holding an empty first line (it can, when HOME holds a newline, but it sits after the separator).

`rs_h=(); for p in "$IMPORT_HOME" "$IMPORT_HOME_REAL"; ...` precedes the caller homes (`:921-923`). Root entries come from `rs_x`, which is non-blank (`:905`), and `rs_real`, which is checked by `-n "${rs_real[i]//\//}"` (`:913`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:905-924`, `:1050-1052`

---

## Claim 25: truthrule: "the parser's dotnest omits only such paths: keep the two equal"

**Location:** `scripts/lib/dev-cycle-read.sh:1220`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-maintainer
**Scope:** Covers the claim that every spelling dotnest omits matches `"/$1" == */.*`. Does not establish the reverse: truthrule refuses dot paths dotnest never sees.

The omitted spelling is the outer-relative path, which starts with the nested root's relative path. That path contains a `/`-led dot component by dotnest's condition (`:823`), so `"/$1"` contains `/.`. E1: test :1756's pinned rows (`.claude/wt-a/sub/y.md dot`, `docs/.wt/a/q.md dot`) pass.

**Evidence:** `scripts/lib/dev-cycle-read.sh:823`, `:1216-1226`; `$L/bats-lib-HEAD.txt`

---

## Claim 26: imps helper: "T_READER_ROOTS and T_READER_HOMES, when set, become the caller's IMPORT_READER_ROOTS and IMPORT_READER_HOMES after the lib is sourced (it clears them)."

**Location:** `test/scripts/build-loop-check.bats:16-17`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-maintainer
**Scope:** Covers imps only. Other helpers (floors) do not honour them; that is a deferred override row.

The assignments run after `source "$1"`: `[[ -z "${T_READER_ROOTS+set}" ]] || IMPORT_READER_ROOTS="$T_READER_ROOTS"` (`:21-22`).

**Evidence:** `test/scripts/build-loop-check.bats:13-24`

---

## Claim 27: The eight "U2b3a" tests each test what their names say, and each would have failed on the code it guards

**Location:** `test/scripts/build-loop-check.bats:1717-1845`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-reviewer
**Scope:** Covers each test's assertions against its name, and red/green runs of HEAD's tests against five lib versions. Does not establish coverage of behaviour no test names (the out-of-walk fallback, Claim 10).

E1 ran the tests against several lib versions:
- HEAD's lib: 8/8 ok.
- Main's lib (e50aab35): 8/8 not ok.
- 5516c6e6's lib: tests 3, 4, 5, 6 and 8 not ok, and tests 1, 2 and 7 ok. This matches the rubric: A1 (test 4), A2 (test 3), G2 (test 6) and G3 (test 5) were red on 5516c6e6, and so was test 8 (A3).
- 4dba56dc's and c9197fd2's libs: 8/8 ok, as expected for text-only fixes after them.

Each test's assertions match its name:
- Test 1: `docs/abs.md imported`, `docs/other.md -`, from a sibling `../gate` worktree.
- Test 2: nested and sibling re-entry.
- Test 3: caller lists add names, and inherited lists are ignored.
- Test 4: a stale `sub/` entry, then a caller root as written and through a symlink, plus the truthrule pin.
- Test 5: eight refused root and home spellings, blank-line skipping, and a failing `git worktree list`.
- Test 6: a newline HOME fails only with a `~/` name. Its "as a relative HOME does" is the comparison to test :697.
- Test 7: a newline registry path. It ran rather than skipped.
- Test 8: the memo and the key.

**Evidence:** `test/scripts/build-loop-check.bats:1717-1845`; `$L/tests-meta.txt`, `$L/bats-lib-HEAD.txt`, `$L/bats-lib-e50aab35.txt`, `$L/bats-lib-5516c6e6.txt`, `$L/bats-lib-4dba56dc.txt`, `$L/bats-lib-c9197fd2.txt`

---

## Claim 28: dev-cycle.bats' sourced-definitions test lists the new functions and globals

**Location:** `test/scripts/dev-cycle.bats:1110-1113`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-maintainer
**Scope:** Covers `import_readers`, `import_readers_key`, `IMPORT_ROOTS`, `IMPORT_HOMES`, `IMPORT_READERS_DONE`, `IMPORT_READER_ROOTS` and `IMPORT_READER_HOMES`. It does not list `IMPORT_READERS_KEY`, and the claim makes no completeness promise.

E1: the test passes with HEAD's lib and fails with main's lib (`not ok 1`).

**Evidence:** `test/scripts/dev-cycle.bats:1104-1117`; `$L/bats-devcycle-sourced-HEAD.txt`, `$L/bats-devcycle-sourced-mainlib.txt`

---

## Claim 29: Plan U2b3 bullet: "git worktree list holds 23 paths, one of them a host path" (observed 2026-10-08); U2b3a sub-bullet: import_readers "(built as reader_set, renamed at review) ... fails the walk on a listing failure, a path holding a newline, a relative path, or /"; "Printing only the longest root's spelling let a stale registry entry at sub/ hide sub/x.md (review iteration 1, security 1)"

**Location:** `docs/working/plan-build-loop-handoff.md:288-292`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-planner
**Scope:** Covers the observation as of its commit, the rename and the refusals. Does not establish the registry count today, which is 24.

The observation count holds for its time. The registry now holds 24 paths, and the extra one is this worktree, whose `.git/worktrees/wt-build-loop-u2b3a` was born at 19:54:29, eleven seconds before the plan commit e50aab35 (19:54:40), after the observation was made. `/home/magfrump/cw-egress-verify` is the host path. `git show 5516c6e6` contains `reader_set` 17 times. The refusals are Claim 19's. The longest-root defect is test 4, red at 5516c6e6 (E1).

**Evidence:** `docs/working/plan-build-loop-handoff.md:285-299`; `$L/bats-lib-5516c6e6.txt`; `git worktree list` (24 entries, 2026-10-08)

---

## Claim 30: Brief claim 5 and commit 3d2d8c44: "Over this repo (24 registered roots) both walks give main's 128 names; a cached isimported takes about 3 ms"; "about 9 s with 24 roots, 8,200 with one ... fails closed near 570"

**Location:** commit 3d2d8c44 message; `scripts/lib/dev-cycle-read.sh:629-636`
**Type:** Performance / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-reviewer
**Scope:** Covers both walks over /workspace at main e50aab35 against main's own lib. Does not establish the wall time of an uncached walk (E2's timer failed: `bc` missing; iteration 2 measured 1.13-1.48 s).

E2 gave `tree: lines 128 distinct 128` and `main: lines 128 distinct 128`. E3 found `tree: HEAD names == main-lib names` and `main: HEAD names == main-lib names`, at 128 names each. A cached isimported took 3.2 ms (main) and 3.0 ms (tree). The 9 s, 8,200 and 570 figures are Claims 7-9.

**Evidence:** `$L/walk-head.txt`, `$L/mainlib-compare.txt`, `$L/roots.txt`; `git log -1 3d2d8c44`

---

## Claims Requiring Attention

### Incorrect
None.

### Stale
None.

### Mostly Accurate
None.

### Unverifiable
None.

Observation (no verdict; covered by the deferred override row "import_targets falls back to ROOT_REAL alone", architecture i2 N3): outside a walk, import_targets passes import_home's raw home, so a HOME holding a newline splits into an absolute first line, and a `~/` name resolves under it instead of failing (E7: rc 0 outside the memo, rc 1 inside it). No caller reaches this path today. U2b3b's outside-seed caller should run import_readers first, as the row already says.

## Goal-Alignment Note

- **Success criterion (verbatim):** A markdown report saved to the output path below, structured per the code-fact-check skill, with `Commit: 3d2d8c44` as its first line.
- **Answered:** The report is at `/workspace/.claude/wt-build-loop-u2b3a/docs/reviews/code-fact-check-report-build-loop-u2b3a-final-r2.md`. It checks 30 claims, all Verified, 24 of them by execution. All five brief focus areas are covered: import_readers, the parser, the lib header and figures, the U2b3a tests (red/green against five lib versions), and the /workspace walk figures.
- **Out of scope:** U2b3b and U2c behaviour; override-row items, which were not re-flagged; prose quality.
- **Escalate:** Nothing blocking. The out-of-walk newline-home observation above belongs to the existing N3 deferral.
- **Decisions I made:** Shape-based bound timings used /workspace's real roots rather than iteration 2's synthetic roots. The root-scaling probe appended synthetic roots under `/workspace/.claude/`, a realistic dot-nested shape. No hallucination-log entry was added, since there were no Incorrect verdicts.
