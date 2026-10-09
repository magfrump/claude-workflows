Commit: c9197fd2
# Code Fact-Check Report

**Repository:** /workspace (worktree `/workspace/.claude/wt-build-loop-u2b3a`, branch `feat/build-loop-u2b3a`)
**Scope:** partial, `git diff 5516c6e6..HEAD -- scripts test` (fix commits 4dba56dc and c9197fd2), plus the commit messages in that range; iteration-1 rubric items A1-A3, G1-G7, G10 checked against it
**Checked:** 2026-10-08
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 33
**Summary:** 24 verified, 7 mostly accurate, 1 stale, 0 incorrect, 1 unverifiable

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`, 5 entries). No claim below matches a logged fabrication. The measured-value mismatches in Claims 7b and 26d resemble the logged "measured value quoted from an artifact set that does not contain it" class, but they are near misses, so they are verdicted Mostly accurate, not Incorrect. The log is not updated.

### Probe log (executed provenance)

Every probe is one `set -eu` script that makes its own `mktemp -d /tmp/u2b3a2-fc-*` dir and removes it. Scripts and captured output are in `/tmp/claude-1000/-workspace/53eaab1e-c162-42ac-afd9-547bb673cbb3/scratchpad/u2b3a2-fc/` (`$S` below; logs in `$S/logs/`). `lib-head.sh`, `lib-5516.sh` and `lib-main.sh` are `git show` copies of `scripts/lib/dev-cycle-read.sh` at c9197fd2, 5516c6e6 and main (e50aab35). After the runs, no `/tmp/u2b3a2-fc-*` dir, worktree or process was left.

| ID | Command | cwd | Exit | Time (2026-10-08, -07:00) | Output |
|---|---|---|---|---|---|
| P1 | `bash $S/p1.sh $S/lib-{head,5516,main}.sh` (both walks over /workspace: distinct names, summed work trailers, cached isimported ×10) | /workspace (read-only) | 0 | 20:49-20:50:22 | `$S/logs/p1-{head,5516,main}.log` |
| P2 | `bash $S/p2.sh <lib> <label> <one-root>` (work with HEAD's parser forced to one root; cached truthwalk ×20) | /workspace (read-only) | 0 | 20:50:39-20:50:52 | `$S/logs/p2.log` |
| P3 | `bash $S/p3.sh $S/lib-head.sh` and `bash $S/p3-5516.sh $S/lib-5516.sh` (time to spend one 50,000,000 bound, 1 and 24 synthetic roots, adapted from `u2b3a-perf-p3.sh`) | temp dir | 0 | 20:51:35-20:52:58 | `$S/logs/p3.log`, `p3-head-rerun.log`, `p3-5516.log` |
| P4 | `bash $S/p4.sh $S/lib-main.sh` (main's parser, the same shapes) | temp dir | 0 | 20:53:20 | `$S/logs/p4.log` |
| P5 | `bats -f U2b3a test/scripts/build-loop-check.bats` with HEAD's test file copied into a detached worktree at 5516c6e6 | temp worktree at 5516c6e6 | 1 (5 of 8 red) | 20:53:47 | `$S/logs/p5-old.log` |
| P6 | `bats test/scripts/build-loop-check.bats test/scripts/dev-cycle.bats`; `bats --count` per suite | worktree (HEAD c9197fd2) | 0 (192/192 ok) | 20:54:22-20:55:20 | `$S/logs/p6-head.log`, `p6-count.log` |
| P7 | `bash $S/p7.sh $S/lib-head.sh` (import_readers, import_targets and dotnest edge cases in a throwaway repo with worktrees at `.claude/wt-a` and a sibling `r2`, a git shim counting calls) | temp repo | 0 | 20:54:48 | `$S/logs/p7.log` |
| P8 | `bash $S/p8.sh $S/lib-{head,main}.sh` (both walks' sorted name sets over /workspace) | /workspace (read-only) | 0 | ~20:55 | `$S/logs/p8-{head,main}.{tree,main}` |
| P9 | `bash $S/p9.sh $S/lib-head.sh` (24 realpath forks against one `realpath -mz`; awk exit code on an empty or blank first root) | temp dir | 0 | 20:55:38 | `$S/logs/p9.log` |
| P10 | `bash $S/p10.sh` (`$BASHPID` inside `$(pwd -P ...)` against the outer one) | temp dir | 0 | 20:56:49 | `$S/logs/p10.log` |

---

## Claim 1: "Call import_reset ... neither walk's cache key holds them (both hold import_readers' roots and homes, so HOME and IMPORT_READER_* need no reset, but the worktree registry is read again only after a reset)."

**Location:** `scripts/lib/dev-cycle-read.sh:64-67`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers when import_readers re-reads `git worktree list`. Does not establish anything about IMPORT_OUT_MAX/IMPORT_WORK_MAX, which are correctly outside the key.

The registry is also re-read whenever the memo key changes, not only after a reset. The key holds ROOT_REAL, HOME's key and the caller's two lists:

```bash
# scripts/lib/dev-cycle-read.sh:878-879
  local a="${ROOT_REAL:-}" b="$IMPORT_HOME_DONE" c="$IMPORT_READER_ROOTS" d="$IMPORT_READER_HOMES"
  READERS_KEY="${#a}:$a ${#b}:$b ${#c}:$c ${#d}:$d"
```
```bash
# scripts/lib/dev-cycle-read.sh:884-888
  readers_key
  [[ "$IMPORT_READERS_DONE" != "$READERS_KEY" ]] || return 0
  k="$READERS_KEY"
  IMPORT_READERS_DONE=""
  nul_list rs_l git worktree list --porcelain -z || return 1
```
(excerpt ends :888; enclosing import_readers() continues to :917, read)

P7's git shim counted 1 call for three import_readers calls under one key, 2 after `import_reset`, and 3 after `IMPORT_READER_ROOTS=/zz` with no reset. A more precise wording: "is read again only after a reset or a change to ROOT_REAL, HOME or the caller's lists". The practical rule (reset per decision) holds.

**Evidence:** `scripts/lib/dev-cycle-read.sh:64-67`, `:877-888`; `$S/logs/p7.log` ("git calls ..." lines)

---

## Claim 2: "Set IMPORT_READER_ROOTS and IMPORT_READER_HOMES after sourcing the lib (which clears them) ... each is newline-separated absolute paths"

**Location:** `scripts/lib/dev-cycle-read.sh:83-86`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator
**Scope:** Covers the clearing on source and the refusal of non-absolute entries. Does not establish U2b3b's future reading of the values from the default branch's settings, which does not exist yet.

```bash
# scripts/lib/dev-cycle-read.sh:873
IMPORT_ROOTS=""; IMPORT_HOMES=""; IMPORT_READERS_DONE=""; IMPORT_READER_ROOTS=""; IMPORT_READER_HOMES=""
```
HEAD's test 109 (`build-loop-check.bats:1751-1752`, inherited values give `-`) passes (P6) and is red on 5516c6e6 (P5: "docs/h.md: imported" where `-` is wanted). Relative entries are refused by `:896` (`[[ "$p" == /* && ...`), as test 111 shows (P6).

**Evidence:** `scripts/lib/dev-cycle-read.sh:83-86`, `:873`, `:894-898`; `test/scripts/build-loop-check.bats:1741-1754`; `$S/logs/p5-old.log`, `$S/logs/p6-head.log`

---

## Claim 3: "One result is cached, for the root in IMPORTED_DONE, keyed on import_readers's roots (ROOT_REAL first) and homes; a call for another reader set recomputes it"

**Location:** `scripts/lib/dev-cycle-read.sh:572-574` (and `:604-606` for IMPORTED_MAIN_DONE)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers both walks' cache keys after the rename. Does not establish that the key tracks registry changes inside one decision (by design it does not: Claim 15a).

```bash
# scripts/lib/dev-cycle-read.sh:1039-1042
  import_readers || { IMPORTED_DONE=""; IMPORTED=error; return 1; }
  # The roots never hold an empty line, so the blank line ends them.
  [[ "$IMPORTED_DONE" == "$IMPORT_ROOTS"$'\n\n'"$IMPORT_HOMES" ]] && { [[ "$IMPORTED" != error ]]; return; }
  IMPORTED_DONE="$IMPORT_ROOTS"$'\n\n'"$IMPORT_HOMES"; IMPORTED=error
```
(excerpt ends :1042; enclosing imported_names() continues to :1068, read). main_imports at `:1089-1091` keys on `"$MAIN_SHA $MAIN_BY_NAME $IMPORT_ROOTS"$'\n\n'"$IMPORT_HOMES"`. Test 114's a0→a1 and h1→h2 rows (a changed caller list walks again without a reset) pass at HEAD (P6).

**Evidence:** `scripts/lib/dev-cycle-read.sh:572-574`, `:604-606`, `:1035-1068`, `:1084-1091`; `$S/logs/p6-head.log`

---

## Claim 4: "import_reset: the next call of either walk walks again"

**Location:** `scripts/lib/dev-cycle-read.sh:614-615`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the clearing of both walk keys and the reader memo. Does not establish the clearing of import_home's memo (keyed on HOME itself, so it needs none).

```bash
# scripts/lib/dev-cycle-read.sh:615
import_reset() { IMPORTED_DONE=""; IMPORTED_MAIN_DONE=""; IMPORT_READERS_DONE=""; }
```
P7: the git call count rose from 1 to 2 after `import_reset`. Test 114's w2 rows (a worktree added mid-decision is seen after the reset) pass (P6).

**Evidence:** `scripts/lib/dev-cycle-read.sh:615`; `$S/logs/p7.log`; `test/scripts/build-loop-check.bats:1824-1832`

---

## Claim 5: "the parser's work (... each resolved spelling it joins ... and one unit per reader root for each spelling it projects ...)"

**Location:** `scripts/lib/dev-cycle-read.sh:622-627`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the charge in put(). Does not establish what the charge costs in time (Claim 6).

```awk
# scripts/lib/dev-cycle-read.sh:725-727, 745
  work += length(c); if (work > wmax) exit 3
  if (c in tried) return
  tried[c] = 1
  ...
  work += nr; if (work > wmax) exit 3
```
(excerpt from put() :722-751, read whole). Each distinct resolved spelling that passes the `tried` and newline checks is charged `nr` before the projection loop at `:746-750`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:722-751`

---

## Claim 6: "the unit of its per-file bound of 50,000,000, about 0.1-4 s here with one root and up to about 7 s with 24, by the name's shape"

**Location:** `scripts/lib/dev-cycle-read.sh:625-627`
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** Medium (wall time depends on the machine; load average was 0.2-0.4 during the runs)
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the time to spend one bound on four adversarial shapes at 1 and 24 synthetic roots. Does not establish shapes worse than those four, or timings under load.

The worst shape measured (`@q<N>/x/x/...`, 1,500 characters a line) spent the bound in 5.1 s at one root and 8.8 s at 24 roots with HEAD's parser (P3; the rerun gave 4.9 s and 8.8 s). Main's parser takes 4.9 s at one root on the same shape (P4), so the "0.1-4 s" upper end was already exceeded before this branch. The "7 s with 24" is i1 performance F2's pre-fix figure (7.1 s). On this shape the G5 charge barely changes the time: 8.8 s at HEAD against 8.9 s at 5516c6e6 (P3), because `length(c)` (about 1,500) dwarfs the added `nr` (24). Other shapes at 24 roots: 3.5 s (root-like), 2.9 s (`a`), 1.2 s (short tokens). A precise wording: "about 1-5 s here with one root and up to about 9 s with 24".

**Evidence:** `scripts/lib/dev-cycle-read.sh:622-629`, `:745`; `$S/logs/p3.log`, `$S/logs/p3-head-rerun.log`, `$S/logs/p3-5516.log`, `$S/logs/p4.log`; `docs/reviews/performance-review-2026-10-08-u2b3a.md:88`, `:109-113`

---

## Claim 7a: "/workspace's walks spend about 330,600 each over its 24 reader roots ... (2026-10-08)"

**Location:** `scripts/lib/dev-cycle-read.sh:629`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers /workspace as of this run (24 roots, main e50aab35). Does not establish the figure as worktrees are added or removed.

P1 at HEAD: "head tree: ... distinct names 128; work 330570" and "head main: ... work 330570", with "roots: 24".

**Evidence:** `scripts/lib/dev-cycle-read.sh:629`; `$S/logs/p1-head.log`

---

## Claim 7b: "(8,600 with one; 2026-10-08)"

**Location:** `scripts/lib/dev-cycle-read.sh:629`
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** Medium (the comment does not say how "one" was configured)
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers HEAD's parser forced to `IMPORT_ROOTS=$ROOT_REAL` over /workspace, and main's parser. Does not establish whatever configuration produced 8,600.

HEAD's parser with one root spends 8,240 per walk (P2: "head one=1 tree: names 128; work 8240"). Main's parser spends 8,110 (P1: "main tree: ... work 8110"), the old comment's "about 8,100". Neither is 8,600, though both are within about 6% of it. Precise version: "8,240 with one".

**Evidence:** `scripts/lib/dev-cycle-read.sh:629`; `$S/logs/p2.log`, `$S/logs/p1-main.log`

---

## Claim 8: "import_readers' IMPORT_ROOTS and IMPORT_HOMES when its memo key is current (else ROOT_REAL alone and import_home's home: a call outside a walk)"

**Location:** `scripts/lib/dev-cycle-read.sh:648-650`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers import_targets' choice of lists (rubric G1). Does not establish anything about callers, since only the walks and tests call it.

```bash
# scripts/lib/dev-cycle-read.sh:919-923
  local u d toks x="" s=(-e 's/\x0/ /g') LC_ALL=C roots="${ROOT_REAL:-}" homes
  import_home || return 1
  homes="$IMPORT_HOME"$'\n'"$IMPORT_HOME_REAL"
  readers_key
  [[ -z "$IMPORT_READERS_DONE" || "$IMPORT_READERS_DONE" != "$READERS_KEY" ]] || { roots="$IMPORT_ROOTS"; homes="$IMPORT_HOMES"; }
```
(excerpt ends :923; enclosing import_targets() continues to :945, read). In P7, the sibling worktree's `@<T>/r2/docs/q.md` printed nothing before import_readers ran, `docs/q.md` while the key was current, nothing again once `IMPORT_READER_ROOTS` changed with no re-run, and nothing after a refused import_readers (IMPORT_READERS_DONE left empty).

**Evidence:** `scripts/lib/dev-cycle-read.sh:918-945`; `$S/logs/p7.log` ("(f)" lines, "after a refusal")

---

## Claim 9: "it is kept only when it lies below a reader root (import_readers: ROOT_REAL, every registered worktree, the caller's IMPORT_READER_ROOTS), and printed relative to the longest one holding it."

**Location:** `scripts/lib/dev-cycle-read.sh:677-680`
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the projection rule stated in the superset statement. Does not establish the "kept only when it lies below a reader root" half, which still holds.

This was true at 5516c6e6. The fix for A1 replaced the longest-root rule, but this sentence, the lib's one statement of the superset claim, was only renamed (`reader_set` → `import_readers`). put() now prints a name relative to every holding root except a dot-nested outer one:

```awk
# scripts/lib/dev-cycle-read.sh:746-750
  nho = 0; for (i = 1; i <= nr; i++) if (index(out, pre[i]) == 1 && length(out) > length(pre[i])) h[++nho] = i
  for (i = 1; i <= nho; i++) {
    for (j = 1; j <= nho; j++) if ((h[i], h[j]) in dotnest) break
    if (j > nho) show(substr(out, length(pre[h[i]]) + 1))
  }
```
(excerpt from put() :722-751, read whole). Test 110 shows the difference: one import yields both `sub/x.md` and `x.md` (P6 pass; P5 at 5516c6e6: "sub/x.md: -", "x.md: imported"). `rg -n longest scripts/lib/dev-cycle-read.sh` hits only `:679`. A matching wording: "printed relative to every root holding it but an outer one whose path down to a nested holding root has a dot component (put)".

**Evidence:** `scripts/lib/dev-cycle-read.sh:677-683`, `:738-751`; `test/scripts/build-loop-check.bats:1756-1768`; `$S/logs/p5-old.log`, `$S/logs/p6-head.log`

---

## Claim 10: "for each reader home (the home of this process first), each in its spelled and real forms, since a root may be spelled either way."

**Location:** `scripts/lib/dev-cycle-read.sh:709-714`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the home list's contents and order. Does not establish that every spelling a session uses is among them (U2b3b's host HOME).

With HOME a symlink, P7 printed homes `.../hlink` then `.../hreal`. A caller home equal to the real spelling is not repeated, and the caller's `/h1` follows own homes (P7 "(d)", "(e)"). The parser joins every non-empty home at `:714`: `for (i = 1; i <= nh; i++) if (homes[i] != "") put(homes[i] "/" substr(c, 3))`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:703-721`, `:910-915`; `$S/logs/p7.log`

---

## Claim 11: "Relative to every root holding it, but an outer root whose path down to a nested root holding it has a dot component (dotnest): a session in a worktree under /workspace/.claude/ reads the file there as a path of that worktree ... while a root nested at any other path (a stale registry entry at sub/) must not take the outer path from the walk"

**Location:** `scripts/lib/dev-cycle-read.sh:738-744`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-reviewer
**Scope:** Covers the honest /workspace layout (24 roots, all worktrees under `.claude/` or outside), a stale `sub/` entry, and a `.claude/wt-a` nested worktree. Does not establish layouts with a non-dot nested worktree that is live, or a root nested under a dot path in a caller-supplied host alias (override row G8).

P8: HEAD's and main's sorted name sets are identical for both walks over /workspace (128 each, `diff` empty, "SAME"), so the honest layout gives main's output (rubric A1's goal). In P7, `@<T>/r/.claude/wt-a/docs/n.md` printed `docs/n.md` but not `.claude/wt-a/docs/n.md`, and `.claude/wt-a` itself (held only by the outer root) was printed. Test 110 (the stale `sub/` entry keeps `sub/x.md`) passes at HEAD and is red at 5516c6e6 (P5, P6).

**Evidence:** `scripts/lib/dev-cycle-read.sh:738-751`, `:812-813`; `$S/logs/p8-head.tree`, `$S/logs/p8-main.tree`, `$S/logs/p8-head.main`, `$S/logs/p8-main.main`, `$S/logs/p7.log`, `$S/logs/p5-old.log`

---

## Claim 12: "IT_ROOTS ... ROOT_REAL ... first" with `exit 2` when the first root is empty (rubric G7: IT_ROOT dropped)

**Location:** `scripts/lib/dev-cycle-read.sh:809-810`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the parser's empty-root exit and the removal of IT_ROOT. Does not establish callers' handling beyond import_targets' `|| return 1`.

```awk
# scripts/lib/dev-cycle-read.sh:810
  nr = split(ENVIRON["IT_ROOTS"], roots, "\n"); if (nr == 0 || roots[1] == "") exit 2
```
P9: "awk exit on empty IT_ROOTS: 2", "awk exit on blank first root: 2". P7 (g): `ROOT_REAL=""` makes import_targets return 1. `rg 'IT_ROOT\b' scripts test` finds nothing.

**Evidence:** `scripts/lib/dev-cycle-read.sh:805-817`, `:943-944`; `$S/logs/p9.log`, `$S/logs/p7.log`

---

## Claim 13: the dotnest table holds only for a strictly longer root under another's `/`-bounded prefix whose remainder has a dot-led component

**Location:** `scripts/lib/dev-cycle-read.sh:811-813`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-reviewer
**Scope:** Covers equal roots, prefixes with no `/` boundary, and the dot test. Does not establish behaviour for a root of `/`, which import_readers refuses (Claim 14), so only a standalone import_targets with `ROOT_REAL=/` could hit it.

```awk
# scripts/lib/dev-cycle-read.sh:811-813
  for (i = 1; i <= nr; i++) pre[i] = (roots[i] == "/") ? "/" : roots[i] "/"
  for (i = 1; i <= nr; i++) for (j = 1; j <= nr; j++)
    if (length(pre[j]) > length(pre[i]) && index(pre[j], pre[i]) == 1 && index("/" substr(pre[j], length(pre[i]) + 1), "/.")) dotnest[i, j] = 1
```
Equal roots never qualify (strict `>`), and import_readers de-duplicates them anyway (`:906`). The trailing `/` in `pre` gives a boundary: in P7 `@<T>/r22/docs/p.md` was not printed under root `<T>/r`. A spelled root holding `..` (accepted when realpath does not read it as `/`) can enter the table, but put() never counts it as a holder, because put()'s `out` is lexically resolved and has no `..`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:805-817`, `:746-750`; `$S/logs/p7.log`

---

## Claim 14: "It returns 1 when import_home or the listing fails, or a root or a caller's home is not absolute, holds a newline, or is / alone as written or as realpath reads it ... This process's own home is kept as the parser takes it (a relative one fails only a ~/ name), but one holding a newline is read as empty, which fails only a ~/ name too."

**Location:** `scripts/lib/dev-cycle-read.sh:861-866`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-reviewer
**Scope:** Covers each refusal named and the own-home handling (rubric G2, G3). Does not establish a realpath that prints fewer entries than it was given, which `:901` refuses but no probe triggered.

```bash
# scripts/lib/dev-cycle-read.sh:894-903
  for p in "${rs_r[@]}" "${rs_h[@]}"; do
    [[ -n "$p" ]] || continue
    [[ "$p" == /* && "$p" != *$'\n'* && -n "${p//\//}" ]] || return 1
    rs_x+=("$p")
  done
  n=${#rs_r[@]}; for p in "${rs_r[@]}"; do [[ -n "$p" ]] || n=$((n - 1)); done
  nul_list rs_real realpath -mz -- "${rs_x[@]}" || return 1
  [[ ${#rs_real[@]} -eq ${#rs_x[@]} ]] || return 1
  for i in "${!rs_x[@]}"; do
    [[ -n "${rs_real[i]//\//}" && "${rs_real[i]}" != *$'\n'* ]] || return 1
```
(excerpt ends :903; enclosing import_readers() continues to :917, read). Test 111 (with `T_READER_ROOTS=/x/..` and `T_READER_HOMES=/x/..` new) and test 112 (HOME holding a newline) pass at HEAD (P6). Both are red at 5516c6e6 (P5). P7: a relative HOME gives `IMPORT_HOMES=[relhome]`, a relative name still resolves, and `@~/k.md` stops the parser at the `~/` prefix. A newline HOME gives `[]` (or `[\n/hh]` with a caller home), and the parser's `substr(homes[1], 1, 1) != "/"` exit 4 at `:713` fails only a `~/` name.

**Evidence:** `scripts/lib/dev-cycle-read.sh:861-866`, `:881-917`, `:713`; `test/scripts/build-loop-check.bats:1770-1801`; `$S/logs/p7.log`, `$S/logs/p5-old.log`, `$S/logs/p6-head.log`

---

## Claim 15a: "The result is memoized in IMPORT_READERS_DONE, keyed on ROOT_REAL, HOME and the caller's two lists, until import_reset (contract item 4): the registry is read once per decision, so one decision sees one root set"

**Location:** `scripts/lib/dev-cycle-read.sh:867-869`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the memo and its key (rubric A3). Does not establish "once per decision" when a caller changes ROOT_REAL, HOME or its lists mid-decision, which re-reads the registry (Claim 1).

P7: one git call across three import_readers calls under one key. Test 114's "tree w1 -" (a worktree added mid-decision is not seen until the reset) passes at HEAD and is red at 5516c6e6 ("tree w1: imported", P5).

**Evidence:** `scripts/lib/dev-cycle-read.sh:867-870`, `:877-888`, `:916`; `$S/logs/p7.log`, `$S/logs/p5-old.log`

---

## Claim 15b: "and a cached walk costs no fork"

**Location:** `scripts/lib/dev-cycle-read.sh:869-870`
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the fork count of a cached imported_names/main_imports call. Does not establish isimported's own `lower` fork, which is outside the walk.

On a memo hit import_readers adds no fork: import_home and readers_key are pure bash, and `:885` returns. But each walk call, cached or not, first runs need_root, which forks for a command substitution:

```bash
# scripts/lib/dev-cycle-read.sh:147
  [[ "$ROOT_REAL" == "$(pwd -P)" ]] || { echo "dev-cycle-read.sh: ROOT_REAL is not the current directory; the caller cds to the root it names" >&2; exit 1; }
```
(excerpt from need_root() :145-149, read whole). P10 shows bash 5.2 runs `$(pwd -P ...)` in a child (outer `$BASHPID` 3306045, inside 3306046). This fork predates the branch. Precise version: "a cached walk adds no fork" (the measured cost: cached isimported 2-3 ms, P1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:145-149`, `:881-885`, `:1035-1042`; `$S/logs/p10.log`, `$S/logs/p1-head.log`

---

## Claim 16: "readers_key: READERS_KEY, the key import_readers memoizes on (after import_home), each part led by its length so no part can run into the next."

**Location:** `scripts/lib/dev-cycle-read.sh:874-880`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the key's four parts and their length prefixes. Does not establish that `${#x}` counts bytes, which it does under the walks' LC_ALL=C and counts characters otherwise; either way the parse is unambiguous because the same shell computes and compares it.

```bash
# scripts/lib/dev-cycle-read.sh:878-879
  local a="${ROOT_REAL:-}" b="$IMPORT_HOME_DONE" c="$IMPORT_READER_ROOTS" d="$IMPORT_READER_HOMES"
  READERS_KEY="${#a}:$a ${#b}:$b ${#c}:$c ${#d}:$d"
```
P7 printed `24:/tmp/u2b3a2-fc-p7-VaaH/r 33:xset:/tmp/u2b3a2-fc-p7-VaaH/hreal 3:/zz 0:`. Both callers run import_home before readers_key (`:883-884`, `:920-922`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:874-885`, `:918-923`; `$S/logs/p7.log`

---

## Claim 17: "resolved in one realpath call (a fork per root cost 14 ms over 24 roots)"

**Location:** `scripts/lib/dev-cycle-read.sh:892-893`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers /workspace's 24 registered paths on this machine. Does not establish the cost under load.

P9: "per-root forks 13855 us; one batched call 1268 us" (three runs: 13.5-14.0 ms against 1.2-1.3 ms).

**Evidence:** `scripts/lib/dev-cycle-read.sh:892-900`; `$S/logs/p9.log`

---

## Claim 18: the r/h tagging index `n` counts only non-blank roots, so blank caller lines are skipped without shifting homes into roots

**Location:** `scripts/lib/dev-cycle-read.sh:899-904`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-reviewer
**Scope:** Covers blank lines in IMPORT_READER_ROOTS and IMPORT_READER_HOMES. Does not establish a blank ROOT_REAL, which need_root exits on before import_readers runs.

```bash
# scripts/lib/dev-cycle-read.sh:899
  n=${#rs_r[@]}; for p in "${rs_r[@]}"; do [[ -n "$p" ]] || n=$((n - 1)); done
```
`rs_x` takes the non-blank roots, then the non-blank homes (`:894-898`), so the first `n` entries are roots. P7 with `IMPORT_READER_ROOTS=$'\n/a\n\n/b'` and `IMPORT_READER_HOMES=$'\n/h1\n'`: roots end `/a`, `/b`, and homes end `/h1`. Test 111's `$'/a\n\n/b\n'` row passes (P6).

**Evidence:** `scripts/lib/dev-cycle-read.sh:889-909`; `$S/logs/p7.log`

---

## Claim 19: "This process's own homes come first, kept as the parser reads them."

**Location:** `scripts/lib/dev-cycle-read.sh:910-915`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers order, newline→empty, spelled/real de-duplication and caller-home de-duplication against own homes. Does not establish de-duplication of a caller home against a different spelling of the same directory beyond realpath's.

```bash
# scripts/lib/dev-cycle-read.sh:911-913
  rs_h=(); for p in "$IMPORT_HOME" "$IMPORT_HOME_REAL"; do [[ "$p" != *$'\n'* ]] || p=""; rs_h+=("$p"); done
  [[ "${rs_h[1]}" != "${rs_h[0]}" ]] || unset 'rs_h[1]'
  for p in "${rs_ho[@]}"; do [[ "$p" == "${rs_h[0]}" || "$p" == "${rs_h[1]-}" ]] || rs_h+=("$p"); done
```
P7: a real HOME gives one entry, `[.../hreal]`. A symlinked HOME gives two, and a caller home equal to the real one adds none.

**Evidence:** `scripts/lib/dev-cycle-read.sh:910-917`; `$S/logs/p7.log`

---

## Claim 20: test "the caller's reader roots and homes add the host checkout's spellings, and the environment does not set them"

**Location:** `test/scripts/build-loop-check.bats:1741-1754`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-reviewer
**Scope:** Covers both walks with caller-set and inherited values. Does not establish U2b3b's settings-sourced values.

The imps helper sets the caller lists after sourcing (`:354-355`: `[[ -z "${T_READER_ROOTS+set}" ]] || IMPORT_READER_ROOTS="$T_READER_ROOTS"`). The inherited row (`:1751-1752`) wants `-`. It passes at HEAD (P6, ok 109) and is red at 5516c6e6 (P5, `docs/h.md: imported`).

**Evidence:** `test/scripts/build-loop-check.bats:349-358`, `:1741-1754`; `$S/logs/p5-old.log`, `$S/logs/p6-head.log`

---

## Claim 21: test "a root nested in another at a non-dot path keeps the outer path's names: a stale registry entry or a caller root inside the repo"

**Location:** `test/scripts/build-loop-check.bats:1756-1768`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the stale-entry half, which is executed and red on 5516c6e6. Does not establish the caller-root half: the only caller root tried does not hold the imported name.

```bash
# test/scripts/build-loop-check.bats:1758, 1766
    printf 'See @%s/sub/x.md\n' "$r" > AGENTS.md; commit_all nest
        T_READER_ROOTS="$r/docs" imps "$w" sub/x.md; want walk ok; want sub/x.md imported
```
(excerpts inside the test body :1756-1768, read whole). `<r>/sub/x.md` is not below `<r>/docs/`, so the `T_READER_ROOTS` row never nests a caller root over the name. That row also runs with the stale `sub/` entry still registered, so it adds no case the first row lacks. A caller root at `$r/sub` (with the stale entry pruned) would test the named case. The stale-entry rows pass at HEAD (P6, ok 110) and are red at 5516c6e6 (P5: `sub/x.md: -`).

**Evidence:** `test/scripts/build-loop-check.bats:1756-1768`; `$S/logs/p5-old.log`, `$S/logs/p6-head.log`

---

## Claim 22: test "both walks fail closed on a reader root or home they cannot model, and when git worktree list fails"

**Location:** `test/scripts/build-loop-check.bats:1770-1787`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-reviewer
**Scope:** Covers the eight listed values, blank lines and a failing `git worktree`. Does not establish which listed value made the 5516c6e6 run red, because bats stops at the first failing `want`.

Passes at HEAD (P6, ok 111). Red at 5516c6e6 (P5: "want: walk: failed / walk: ok"), consistent with rubric G3's newly refused `/x/..` home.

**Evidence:** `test/scripts/build-loop-check.bats:1770-1787`; `$S/logs/p5-old.log`, `$S/logs/p6-head.log`

---

## Claim 23: test "a HOME holding a newline fails a walk only when a ~/ name needs it", and c9197fd2's comment "The walk fails, and a failed walk answers imported for every path (fail closed)."

**Location:** `test/scripts/build-loop-check.bats:1789-1801` (comment `:1796`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-reviewer
**Scope:** Covers both walks and the comment's fail-closed reading. Does not establish a HOME holding other control characters.

```bash
# scripts/lib/dev-cycle-read.sh:1188-1189
    main) main_imports || return 0; [[ "$IMPORTED_MAIN" == *$'\n'"$lp"$'\n'* ]] ;;
    tree) imported_names || return 0; [[ "$IMPORTED" == *$'\n'"$lp"$'\n'* ]] ;;
```
(excerpt from isimported() :1183-1192, read whole). Passes at HEAD (P6, ok 112). Red at 5516c6e6, whose walk failed with no `~/` name (P5: "want: walk: ok / walk: failed").

**Evidence:** `test/scripts/build-loop-check.bats:1789-1801`; `scripts/lib/dev-cycle-read.sh:1183-1192`; `$S/logs/p5-old.log`, `$S/logs/p6-head.log`

---

## Claim 24: test "both walk caches key on the reader set, which is read once until import_reset"

**Location:** `test/scripts/build-loop-check.bats:1812-1833`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-reviewer
**Scope:** Covers the tree walk's mid-decision registry change and both walks' post-reset view. Does not establish the main walk's mid-decision case: the worktree is added only in the tree iteration, so "main w1" is unchecked by design.

`want "tree w1" -` at `:1832` tells the memo apart from a live registry read. It passes at HEAD (P6, ok 114) and fails at 5516c6e6 (P5: "tree w1: imported").

**Evidence:** `test/scripts/build-loop-check.bats:1812-1833`; `$S/logs/p5-old.log`, `$S/logs/p6-head.log`

---

## Claim 25: the sourced-definitions test lists the new names (rubric G10)

**Location:** `test/scripts/dev-cycle.bats:1107-1110`
**Type:** Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers `import_readers`, `readers_key` and the five globals added to the lists. Does not establish that the list is complete for older names (the rubric notes it was already incomplete).

```bash
# test/scripts/dev-cycle.bats:1108-1110 (diff +lines)
... import_work import_readers readers_key; do
... IMPORT_ROOTS IMPORT_HOMES IMPORT_READERS_DONE IMPORT_READER_ROOTS IMPORT_READER_HOMES BRIEF BRIEF_ODD; do
```
P6: "ok 175 sourcing the reader lib defines its functions and calls neither git nor perl".

**Evidence:** `test/scripts/dev-cycle.bats:1107-1114`; `$S/logs/p6-head.log`

---

## Claim 26a: commit 4dba56dc, "a stale registry entry at sub/ no longer takes sub/x.md from the walk (test red on 5516c6e6)"

**Location:** commit 4dba56dc message, paragraph 1
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator
**Scope:** Covers the A1 test's red/green. Does not establish the caller-root half of that test's name (Claim 21).

P5: test 4 "not ok" at 5516c6e6 with `sub/x.md: -`. P6: ok 110 at HEAD.

**Evidence:** `test/scripts/build-loop-check.bats:1756-1768`; `$S/logs/p5-old.log`, `$S/logs/p6-head.log`

---

## Claim 26b: commit 4dba56dc, "Over /workspace both walks give main's 128 names"

**Location:** commit 4dba56dc message, paragraph 2
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator
**Scope:** Covers /workspace at main e50aab35 with its 24 roots. Does not establish other checkouts.

P8: the sets are identical, 128 lines each, for both walks and both libs.

**Evidence:** `$S/logs/p8-head.tree`, `$S/logs/p8-main.tree`, `$S/logs/p8-head.main`, `$S/logs/p8-main.main`

---

## Claim 26c: commit 4dba56dc, "a cached isimported takes 3 ms (89 ms at 5516c6e6)"

**Location:** commit 4dba56dc message, paragraph 2
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** Medium (machine timing)
**Verification mode:** executed
**Legibility-target:** for-orchestrator
**Scope:** Covers cached isimported and truthwalk over /workspace on this machine at low load. Does not establish the 89 ms run's conditions.

At HEAD a cached isimported averages 2 ms (tree) and 3 ms (main) (P1). At 5516c6e6 it averages 23 ms and 35 ms (P1). Cached truthwalk, which runs the walk and then isimported (two reader-set computations at 5516c6e6), averages 47 ms and 69 ms there (P2). The 89 ms is the rubric's A3 figure for a cached truthwalk main, not isimported. The improvement holds. Precise version: "3 ms (about 35 ms at 5516c6e6; 70-89 ms for truthwalk main)".

**Evidence:** `$S/logs/p1-head.log`, `$S/logs/p1-5516.log`, `$S/logs/p2.log`; `docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b3a.md` (A3 row)

---

## Claim 26d: commit 4dba56dc, "honest work is about 330,600 per walk (8,600 on main), under the 50,000,000 bound"

**Location:** commit 4dba56dc message, paragraph 2
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator
**Scope:** Covers /workspace's walks with HEAD's and main's libs. Does not establish the configuration behind 8,600.

330,570 at HEAD (P1). Main's lib spends 8,110 per walk (P1), not 8,600. HEAD's parser with one root spends 8,240 (P2). The comment at `:629` says "8,600 with one", so commit and comment disagree on what the figure measures, and neither value reproduces.

**Evidence:** `$S/logs/p1-head.log`, `$S/logs/p1-main.log`, `$S/logs/p2.log`

---

## Claim 26e: commit 4dba56dc, "Suites 114/19/78/2/2/53"

**Location:** commit 4dba56dc message, Notes
**Type:** Configuration
**Verdict:** Verified
**Confidence:** Medium (the suites are not named; matched by count)
**Verification mode:** executed
**Legibility-target:** for-orchestrator
**Scope:** Covers the test counts; build-loop-check (114) and dev-cycle (78) were also run and pass. Does not establish passing for build-loop-read (19), fixture-git-env (2), utility-smoke (2) or hermeticity-lint (53), which were counted but not run.

`bats --count`: 114 build-loop-check, 19 build-loop-read, 78 dev-cycle, 2 fixture-git-env, 2 utility-smoke (P6), and 53 `test/hermeticity-lint.bats`. P6 ran 192/192 ok (114 + 78).

**Evidence:** `$S/logs/p6-count.log`, `$S/logs/p6-head.log`

---

## Claim 26f: commit 4dba56dc, "324 code lines against main"

**Location:** commit 4dba56dc message, Notes
**Type:** Configuration
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Legibility-target:** for-orchestrator
**Scope:** Covers nothing beyond the numstat below. Does not establish the metric the figure counts.

The message does not define "code lines". `git diff --numstat main...HEAD -- scripts test` gives 153+/43- (lib), 125+/0- (build-loop-check.bats) and 2+/2- (dev-cycle.bats): 280 insertions, 325 changed lines. No natural count gives 324 (paraphrased — no quote available because the claim names an undefined metric). To verify, name the counting command.

**Evidence:** `scripts/lib/dev-cycle-read.sh`, `test/scripts/build-loop-check.bats`, `test/scripts/dev-cycle.bats` (numstat)

---

## Iteration-1 items against the fix range

- **A1** resolved: Claims 9 (stale wording only), 11, 26a.
- **A2** resolved: Claims 2, 20.
- **A3** resolved: Claims 15a, 26c.
- **G1** holds: Claim 8.
- **G2** holds: Claims 14, 23.
- **G3** holds: Claims 14, 22.
- **G4** partially: comments re-measured, but `:679` still says "longest" (Claim 9), and the timing figures were not re-measured after G5 (Claims 6, 7b).
- **G5** holds as a charge (Claim 5), but it does not materially cut the worst shape's time (Claim 6).
- **G6** and **G7** hold: no `reader_set`, `IMPORT_READERS_FOR` or `IT_ROOT` remains (Claim 12).
- **G10** holds: Claim 25.
- No regression found. Main's name sets are reproduced exactly over /workspace (Claim 26b).

## Claims Requiring Attention

### Incorrect
None.

### Stale
- **Claim 9** (`scripts/lib/dev-cycle-read.sh:679`): the superset statement still says a name is "printed relative to the longest one holding it". put() now prints it under every holding root but a dot-nested outer one.

### Mostly Accurate
- **Claim 1** (`scripts/lib/dev-cycle-read.sh:66-67`): the registry is re-read after a reset or a change to the memo key (ROOT_REAL, HOME, caller lists), not "only after a reset".
- **Claim 6** (`scripts/lib/dev-cycle-read.sh:626`): one bound measured 5.1 s at one root (main's parser: 4.9 s) and 8.8 s at 24. "0.1-4 s ... about 7 s" are i1's pre-G5 figures, and G5 changed the worst shape's time by under 2%.
- **Claim 7b** (`scripts/lib/dev-cycle-read.sh:629`): "8,600 with one" measures 8,240 (HEAD's parser, one root) and 8,110 on main.
- **Claim 15b** (`scripts/lib/dev-cycle-read.sh:869-870`): a cached walk still forks once in need_root's `$(pwd -P)` (`:147`). import_readers adds none.
- **Claim 21** (`test/scripts/build-loop-check.bats:1756`, `:1766`): the test name's "a caller root inside the repo" is not exercised, because `$r/docs` does not hold `sub/x.md`.
- **Claim 26c** (commit 4dba56dc): the 89 ms is the cached truthwalk main figure. A cached isimported at 5516c6e6 measures 23-35 ms.
- **Claim 26d** (commit 4dba56dc): "8,600 on main" measures 8,110 on main.

### Unverifiable
- **Claim 26f** (commit 4dba56dc): "324 code lines against main" names no metric. Numstat gives 280 insertions or 325 changed lines.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to /workspace/.claude/wt-build-loop-u2b3a/docs/reviews/code-fact-check-report-build-loop-u2b3a-i2.md, structured per the code-fact-check skill, with `Commit: c9197fd2` as its first line and `**Replication:** k=1 (loop pass, decision 031)` in its header.
- Answered: yes
- Out of scope: the commits before 5516c6e6..HEAD (context only). Override rows G8, G9, G11 and G12 (not re-flagged). Running the four suites only counted in Claim 26e.
- Escalate: Claim 9's stale superset sentence at `:679` is the lib's single statement of the superset claim (known issue A5 and plan F11 point there), so the fix should reword it before merge. Commit 4dba56dc's figures (Claims 26c, 26d) are immutable, so the merge message should carry the corrected figures, as row G12 did for 5516c6e6.
- Decisions I made: I split Claims 7, 15 and 26 where verdicts diverged. I timed the work bound on a 40,000-line file, with the shapes taken from i1's perf probe. Logs stay in the scratch dir, because the brief allows writing only this report.
