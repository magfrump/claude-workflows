Commit: 5516c6e6

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u2b3a (branch feat/build-loop-u2b3a)
**Scope:** branch diff `git diff main...HEAD` (main e50aab35..5516c6e6): scripts/lib/dev-cycle-read.sh, test/scripts/build-loop-check.bats, commit messages 76a64fe8 and 5516c6e6
**Checked:** 2026-10-08
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 27
**Summary:** 22 verified, 3 mostly accurate, 1 stale, 0 incorrect, 1 unverifiable

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) read first. Claim 22b (the "129 names" count) is close to the logged "specific measured value quoted from an artifact set that does not contain it" class (the "All 85 tests" and "mode1-equiv 33" entries), but it is an off-by-one counting artifact on a real measurement, not a fabrication, so it gets Mostly accurate and no log entry.

Execution logs are in the review scratch dir (the brief allows writing only this report in the worktree): `/tmp/claude-1000/-workspace/53eaab1e-c162-42ac-afd9-547bb673cbb3/scratchpad/u2b3a-fc-logs/` (below, `LOGS/`). Probe scripts are beside it (`u2b3a-fc-*.sh`). Every probe used its own `mktemp -d /tmp/u2b3a-fc-XXXX` and checked `pwd -P` before running `git init` or `git commit`. Runs against `/workspace` only read (walks, `git worktree list`).

---

## Claim 1: "Call import_reset ... when IMPORT_OUT_MAX or IMPORT_WORK_MAX changes: neither walk's cache key holds them (both hold reader_set's roots and homes, so HOME and IMPORT_READER_* need no reset)"

**Location:** `scripts/lib/dev-cycle-read.sh:63-66`
**Type:** Invariant / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers both walks seeing a changed HOME, IMPORT_READER_ROOTS or IMPORT_READER_HOMES without import_reset, and the budgets missing from both keys. It does not establish that every caller's other state (the checkout, MAIN_SHA) is reset as items 1-3 and 5 require.

Both keys are built from reader_set's output, which runs before the check: `reader_set || { IMPORTED_DONE=""; IMPORTED=error; return 1; }` and `[[ "$IMPORTED_DONE" == "$IMPORT_ROOTS"$'\n\n'"$IMPORT_HOMES" ]]` (`scripts/lib/dev-cycle-read.sh:1000-1003`). The main walk does the same with `"$MAIN_SHA $MAIN_BY_NAME $IMPORT_ROOTS"$'\n\n'"$IMPORT_HOMES"` (`:1050-1052`). Neither key holds IMPORT_OUT_MAX or IMPORT_WORK_MAX. Executed: in one shell with no import_reset, `@~/cw/docs/h.md` read `-` under HOME=/nowhere, `imported` under HOME=parent, and `-` again under HOME=/nowhere, for both walks. Test 6 (`test/scripts/build-loop-check.bats:1777`) passes for IMPORT_READER_ROOTS and IMPORT_READER_HOMES.
- Commands: `bash u2b3a-fc-probe2.sh` (cwd a throwaway repo under /tmp/u2b3a-fc-*), exit 0, 2026-10-09T03:23:24Z. `bats -f U2b3a test/scripts/build-loop-check.bats` (cwd the worktree), exit 0, 2026-10-09T03:21Z.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1000-1003`, `scripts/lib/dev-cycle-read.sh:1050-1052`, `LOGS/probe2.txt`, `LOGS/head-u2b3a.txt`

---

## Claim 2: tree-walk header: "~/ against every reader home, and drops paths outside every reader root: reader_set ... It returns 1 ... when ... reader_set or the parser ... fails ... keyed on reader_set's roots (ROOT_REAL first) and homes; a call for another reader set recomputes it"

**Location:** `scripts/lib/dev-cycle-read.sh:562-569`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers imported_names' reader_set call, its failure return and its cache key. It does not establish that a reader_set failure is cached: it is not, because `IMPORTED_DONE=""` makes the next call walk again (and presumably fail again), which the header's "a cached error returns 1 again" does not contradict.

`reader_set || { IMPORTED_DONE=""; IMPORTED=error; return 1; }` (`:1000`). The former `import_home || return 1` after the start loop is gone; reader_set calls import_home (`:855`). Test 4 (failures) and test 6 (recompute) pass on HEAD.

**Evidence:** `scripts/lib/dev-cycle-read.sh:996-1029`, `scripts/lib/dev-cycle-read.sh:852-879`, `LOGS/head-u2b3a.txt`

---

## Claim 3: main-walk header: "cached for the commit, MAIN_BY_NAME and reader_set's roots and homes in IMPORTED_MAIN_DONE, never the checkout ..." and the return list "... reader_set, the parser ... or a lower fails"

**Location:** `scripts/lib/dev-cycle-read.sh:600-603`, `scripts/lib/dev-cycle-read.sh:1040`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the main walk's key and its reader_set failure return. It does not establish anything about the checkout-phase admission rules, which this diff leaves unchanged.

`IMPORTED_MAIN=error; IMPORTED_MAIN_DONE="$MAIN_SHA $MAIN_BY_NAME $IMPORT_ROOTS"$'\n\n'"$IMPORT_HOMES"` (`:1052`) and `reader_set || { IMPORTED_MAIN_DONE=""; IMPORTED_MAIN=error; return 1; }` (`:1050`). The old `import_home || return 1` before `IMPORTED_MAIN=$'\n'` is removed (diff hunk at `:1083`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1045-1086`

---

## Claim 4: "reader_set's IMPORT_ROOTS and IMPORT_HOMES when IMPORT_READERS_FOR names this ROOT_REAL and HOME (else ROOT_REAL alone and import_home's home)" and "import_targets called on its own (a test) reads ROOT_REAL alone and import_home's home otherwise"

**Location:** `scripts/lib/dev-cycle-read.sh:641-643`, `scripts/lib/dev-cycle-read.sh:845-847`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the selection at `:881-884` and that a HOME change or a missing reader_set call falls back. It does not establish freshness against IMPORT_READER_ROOTS or IMPORT_READER_HOMES: a standalone import_targets call after reader_set uses the old lists when only those variables changed. This cannot happen inside a walk, because each walk calls reader_set first and import_targets runs in that walk's `$(...)`.

```bash
# scripts/lib/dev-cycle-read.sh:881-884
local u d toks x="" s=(-e 's/\x0/ /g') LC_ALL=C roots="${ROOT_REAL:-}" homes
import_home || return 1
homes="$IMPORT_HOME"$'\n'"$IMPORT_HOME_REAL"
[[ "$IMPORT_READERS_FOR" != "${ROOT_REAL:-}"$'\n'"$IMPORT_HOME_DONE" ]] || { roots="$IMPORT_ROOTS"; homes="$IMPORT_HOMES"; }
```
(excerpt ends :884; enclosing import_targets() continues to :906, read)

reader_set clears `IMPORT_READERS_FOR=""` first (`:854`) and sets it only on success (`:878`), so a failed reader_set leaves no matching stale list. Executed (probe P4): `@/host/cw/docs/a.md` printed nothing before any walk. After a walk with IMPORT_READER_ROOTS=/host/cw it printed `docs/a.md`. After setting IMPORT_READER_ROOTS=/other with no walk, `/host/cw` was still kept and `/other` was not (the residue named above). After HOME changed, it printed nothing (fallback).
- Command: `bash u2b3a-fc-probe.sh` (cwd /tmp/u2b3a-fc-*/repo), exit 0, 2026-10-09T03:22:58Z.

**Evidence:** `scripts/lib/dev-cycle-read.sh:852-906`, `LOGS/probe.txt`

---

## Claim 5: "made absolute (ROOT_REAL/DIR/name for $1 and each further directory, unless it starts with /)"

**Location:** `scripts/lib/dev-cycle-read.sh:667-668`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the description of how a relative candidate is made absolute. It does not establish that a reader is misled about the whole model: the same paragraph's later sentence (`:673-674`) gives the new rule.

This sentence was not edited in this diff, and it still names ROOT_REAL as the only base. The parser now joins every root: `for (r = 1; r <= nr; r++) for (i = 0; i <= nd; i++) put(roots[r] "/" dirs[i] "/" c)` (`:713`). The precise version: "made absolute (ROOT/DIR/name for each reader root, for $1 and each further directory, unless it starts with /)".

**Evidence:** `scripts/lib/dev-cycle-read.sh:667-674`, `scripts/lib/dev-cycle-read.sh:713`

---

## Claim 6: superset text: "it is kept only when it lies below a reader root (reader_set: ROOT_REAL, every registered worktree, the caller's IMPORT_READER_ROOTS), and printed relative to the longest one holding it. A relative name is resolved against each root's copy of its directory ... a ~/ name is joined to each reader home (this process's and IMPORT_READER_HOMES), in spelled and real forms"

**Location:** `scripts/lib/dev-cycle-read.sh:670-676`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers keep, projection and join for the root and home lists reader_set builds. It does not establish the superset against Claude Code itself (unchanged prior claims), nor names under homes or checkouts reader_set does not list (the stated exception).

`for (i = 1; i <= nh; i++) if (homes[i] != "") put(homes[i] "/" substr(c, 3))` (`:707`), the every-root join at `:713`, and the longest-root selection at `:733-735`. Executed: tests 1-3 pass on HEAD and fail on main's lib. Probe P6 with roots `/w` and `/w/.claude/n` printed `docs/b.md` for `@/w/.claude/n/docs/b.md` (the nested root wins), `docs/c.md` for `/w/docs/c.md`, nothing for `/w2/docs/a.md` (boundary at `/`), and nothing for `/w` itself.

**Evidence:** `scripts/lib/dev-cycle-read.sh:696-740`, `LOGS/head-u2b3a.txt`, `LOGS/mainlib-u2b3a.txt`, `LOGS/probe.txt`

---

## Claim 7: exceptions: "a session in a checkout or under a home reader_set does not list (U2b3b's settings line names the host's)"

**Location:** `scripts/lib/dev-cycle-read.sh:676-679`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the fact that the removed exceptions (another home, another checkout) are now modelled for listed readers and the residual is stated, and that U2b3b is the plan's named owner. It does not establish that U2b3b's settings line exists yet (it is future work).

The old text "a session whose home differs from this process's ... a session in another checkout of the repo" was replaced (diff hunk at `:668`). The lists come only from ROOT_REAL, `git worktree list`, and the caller's variables (`:856-860`). Nothing in the lib sets IMPORT_READER_ROOTS or IMPORT_READER_HOMES (paraphrased, no quote available because this is an absence: `rg IMPORT_READER scripts` finds only the lib's reads, and `test/` holds the only writers). That matches the commit body's "U2b3b's settings line sets them".

**Evidence:** `scripts/lib/dev-cycle-read.sh:856-860`, `test/scripts/build-loop-check.bats:1743`

---

## Claim 8: "It returns 1 when sed, python3, awk or import_home fails, when ROOT_REAL is empty, when a ~/ name appears and the home is not absolute"

**Location:** `scripts/lib/dev-cycle-read.sh:685-686`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the exit-4 rule surviving the move from `home` to `homes[1]`, on both the standalone and the walk paths. It does not establish behavior when only a caller home (not this process's) is relative: reader_set refuses that before the parser runs.

`if (substr(homes[1], 1, 1) != "/") exit 4` (`:706`). With reader_set, homes[1] is still this process's spelled home, because rs_h starts `("$IMPORT_HOME" "$IMPORT_HOME_REAL")` and the own-home entries are not skipped when blank (`:859`, `:867-875`). Executed: the existing test at `test/scripts/build-loop-check.bats:693` passes (`plain=0`, `tilde=1`). Probe P7, with HOME=rel and IMPORT_READER_HOMES=/host, gave `homes=[rel|/host]` and both walks failed. With HOME=/abs both walks were ok.
- Commands: full `bats test/scripts/build-loop-check.bats` (cwd the worktree), 112/112 ok, exit 0, 2026-10-09T03:24Z. `bash u2b3a-fc-probe3.sh`, exit 0, 2026-10-09T03:25:46Z.

**Evidence:** `scripts/lib/dev-cycle-read.sh:706`, `scripts/lib/dev-cycle-read.sh:859-876`, `LOGS/full-suite.txt`, `LOGS/probe3.txt`

---

## Claim 9: "for each reader home (the home of this process first), each also spelled through its real path, since the roots are real too"

**Location:** `scripts/lib/dev-cycle-read.sh:702-704`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the order and the spelled/real pair for homes. It does not establish anything beyond the stated reason.

The mechanism holds: homes hold each entry spelled and real, with this process's first (`:859`, `:874-875`). The stated reason, "since the roots are real too", is imprecise. Roots are now listed "as written and as realpath -m reads it" (`:834-835`, `:865`), so they hold spelled forms too, such as a caller's `/host/x/../cw`. The precise reason: a real root only matches a real home spelling, so both spellings are tried.

**Evidence:** `scripts/lib/dev-cycle-read.sh:702-707`, `scripts/lib/dev-cycle-read.sh:861-866`

---

## Claim 10: "IT_ROOTS and IT_HOMES: newline-separated, ROOT_REAL and the home of this process first (reader_set)"

**Location:** `scripts/lib/dev-cycle-read.sh:792`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the order of both lists, whether they come from reader_set or the fallback. It does not establish that IT_ROOT (still read, `:791`) equals roots[1]. It does, because ROOT_REAL is real and is listed first.

`rs_r=("$ROOT_REAL")` before the worktree paths (`:857`) and `rs_h=("$IMPORT_HOME" "$IMPORT_HOME_REAL")` (`:859`). The fallback is `roots="${ROOT_REAL:-}"` and `homes="$IMPORT_HOME"$'\n'"$IMPORT_HOME_REAL"` (`:881-883`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:788-797`, `scripts/lib/dev-cycle-read.sh:857-859`, `scripts/lib/dev-cycle-read.sh:881-883`

---

## Claim 11: "Relative to the longest root holding it: worktrees nest in /workspace" (awk) and the root `/` handling `pre[i] = (roots[i] == "/") ? "/" : roots[i] "/"`

**Location:** `scripts/lib/dev-cycle-read.sh:731-735`, `scripts/lib/dev-cycle-read.sh:793`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the longest-prefix choice, the `/` boundary, and the root itself not being printed. It does not establish a reachable root `/` through the walks: reader_set refuses it (`:863-864`), so only a standalone import_targets with ROOT_REAL=/ reaches the `/` arm.

`k = 0; for (i = 1; i <= nr; i++) if (index(out, pre[i]) == 1 && length(out) > length(pre[i]) && length(pre[i]) > k) k = length(pre[i])` then `if (!k) return` (`:733-734`). Probe P6 results are as in Claim 6.

**Evidence:** `scripts/lib/dev-cycle-read.sh:715-740`, `LOGS/probe.txt`

---

## Claim 12: "reader_set: the reader model's roots and homes ..., which both walks compute before their cache check and key on"

**Location:** `scripts/lib/dev-cycle-read.sh:828-829`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers both walks. It does not establish that other callers of import_targets (dev-cycle.bats' function list, --check-fix through the tree walk) call reader_set directly: they reach it only through the walks.

reader_set runs at `:1000` and `:1050`, before the key comparisons at `:1002` and `:1051`. `rg reader_set scripts` shows no other caller (paraphrased, no quote available because this is an absence of other call sites).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1000-1003`, `scripts/lib/dev-cycle-read.sh:1050-1052`

---

## Claim 13: "every path git worktree list registers for this repository (prunable ones too: a host path such as /home/magfrump/cw-egress-verify)"

**Location:** `scripts/lib/dev-cycle-read.sh:830-831`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers /workspace's registry as of the run. It does not establish behavior for a registry entry git prints without a `worktree ` line. There is none in porcelain format.

`nul_list rs_l git worktree list --porcelain -z || return 1` then `[[ "$p" != "worktree "* ]] || rs_r+=("${p#worktree }")` (`:856-857`). There is no prunable filter. Executed in /workspace: `git worktree list --porcelain` lists `worktree /home/magfrump/cw-egress-verify` with `prunable gitdir file points to non-existent location`, and reader_set's IMPORT_ROOTS holds `/home/magfrump/cw-egress-verify` second.
- Command: `reader_set; printf "%s\n" "$IMPORT_ROOTS"` (cwd /workspace), exit 0, 2026-10-09T03:24:21Z.

**Evidence:** `scripts/lib/dev-cycle-read.sh:856-857`, `LOGS/reader-set-workspace.txt`

---

## Claim 14: "Each is newline-separated, ROOT_REAL or this process's home first, and lists every entry as written and as realpath -m reads it, once"

**Location:** `scripts/lib/dev-cycle-read.sh:833-835`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers dedup and the spelled/real pairs. It does not establish that this process's two home entries get a fresh realpath: they are import_home's own pair, already spelled and real (`:825-826`), so the result is the same.

`for p in "$p" "$r"; do [[ -n "${rs_seen[r$p]+set}" ]] || { rs_seen[r$p]=1; rs_ro+=("$p"); }; done` (`:865`), with separate `h` keys for homes (`:875`). `r="$p"; [[ $i -lt 2 ]] || r="$(realpath -m -- "$p")" || return 1` (`:874`). Executed (P5): `/host/cw/` and `/host/x/../cw` both project `@/host/cw/docs/a.md` to `docs/a.md` through their realpath forms.

**Evidence:** `scripts/lib/dev-cycle-read.sh:861-877`, `LOGS/probe.txt`

---

## Claim 15: "The caller's lists are newline-separated absolute paths (the host checkout Q-123 names and the host HOME ...), and blank lines are skipped"

**Location:** `scripts/lib/dev-cycle-read.sh:835-837`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers splitting, blank-line skipping and the Q-123 reference. It does not establish that the host HOME value will be correct (it is U2b3b's settings line).

`mapfile -t -O "${#rs_r[@]}" rs_r <<<"$IMPORT_READER_ROOTS"` and `p="${rs_r[i]}"; [[ -n "$p" || $i -eq 0 ]] || continue` (`:858`, `:862`). For homes: `[[ -n "$p" ]] || continue` for `i -ge 2` (`:870`). Test 4's `IMPORT_READER_ROOTS=$'/a\n\n/b\n' ... want walk ok` passes (`test/scripts/build-loop-check.bats:1758`). Q-123 exists in `docs/working/questions-archive.md:2084`: "U2b's root set takes `/home/magfrump/claude-workflows` as the host spelling of ROOT_REAL".

**Evidence:** `scripts/lib/dev-cycle-read.sh:858-870`, `docs/working/questions-archive.md:2084-2087`, `LOGS/head-u2b3a.txt`

---

## Claim 16: "a root nested in another takes the names below it: the honest ones nest only under .claude/ (a dot path the floor refuses whole)"

**Location:** `scripts/lib/dev-cycle-read.sh:838-840`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers /workspace's 24 registered worktrees as of 2026-10-09T03:24Z and truthrule's dot word. It does not establish that this holds for future worktrees: nothing in the lib enforces it, and the hostile case is Claim 18's residual.

The /workspace registry holds `/workspace`, `/home/magfrump/cw-egress-verify` (not nested), and 22 paths under `/workspace/.claude/` (`LOGS/reader-set-workspace.txt`). The floor's shared rule: `elif [[ "/$1" == */.* ]]; then TRUTH_WHY="dot"` (`:1171`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1167-1177`, `LOGS/reader-set-workspace.txt`

---

## Claim 17: "printing the outer spelling too cost /workspace's walks 37 times the output (2026-10-08)"

**Location:** `scripts/lib/dev-cycle-read.sh:840-841`
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the output size of an every-root variant built from HEAD's lib (put prints the name relative to every root holding it) against HEAD, over /workspace with 24 worktrees. It does not establish the author's exact variant or worktree count on 2026-10-08.

Executed: HEAD gives 5607 bytes in both walks. The every-root variant (the awk `put` patched to print one name per matching root) gives 211499 bytes in both walks: 37.7 times (2944 lines against 128).
- Command: `bash u2b3a-fc-measure.sh` (walks cwd /workspace), exit 0, 2026-10-09T03:22:12Z.

**Evidence:** `scripts/lib/dev-cycle-read.sh:731-739`, `LOGS/measure.txt`

---

## Claim 18: "It returns 1 when import_home or the listing fails, or a root or home (but this process's own home, which the parser already refuses to join when it is relative) is not absolute, holds a newline, or is / alone (every path would project into the repo)"

**Location:** `scripts/lib/dev-cycle-read.sh:842-845`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers every refusal path in reader_set, executed. It does not establish whether refusing these forms is the right policy (a critic's call).

Each listed refusal exists and was executed: test 4 (`rel/cw`, `/`, `//`, `rel`, mixed lists, a failing `git worktree list`) and test 5 (a worktree path holding a newline) pass on HEAD. Two imprecisions:
- **The own-home exemption is narrower than written.** It covers "not absolute" and "/ alone" but not "holds a newline". `[[ "$p" != *$'\n'* ]] || return 1` sits outside the `i -ge 2` block (`:869-873`). Executed (P2): HOME=$'/h\nx' fails both walks, even with no `~/` name in the repo. HOME=/ is accepted (P3: `HOME=/ tree ok`).
- **For caller homes, "/ alone" is tested on the spelling only.** `[[ "$p" == /* && -n "${p//\//}" ]]` (`:871`) rejects `/` but accepts `/x/..`. Its realpath `/` is not rechecked, while roots recheck it: `r="$(realpath -m -- "$p")" && [[ -n "${r//\//}" ]] || return 1` (`:864`). Executed (P3): `IMPORT_READER_HOMES=/x/..` gave ok, `IMPORT_READER_ROOTS=/x/..` gave failed. The parenthetical reason ("every path would project into the repo") applies to roots, not homes.

Precise version: "... or a root, or a caller's home, is not absolute or is / alone (a root also after realpath), or any root or home holds a newline".

**Evidence:** `scripts/lib/dev-cycle-read.sh:861-876`, `LOGS/probe.txt`, `LOGS/head-u2b3a.txt`

---

## Claim 19: "Not covered: a hostile loop can rewrite the worktree registry in the shared common dir, dropping a root or registering one at a path main stores, which then takes that path's names (a Q-103 residual)"

**Location:** `scripts/lib/dev-cycle-read.sh:848-850`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the mechanism (a nested root takes the names below it and so renames them) and the use of "Q-103 residual" as the project's term for a hostile-loop path. It does not establish an end-to-end attack against the floor. The registry rewrite itself was not performed.

The mechanism holds through the longest-root rule (`:733`). P6 shows a nested root `/w/.claude/n` turning `/w/.claude/n/docs/b.md` into `docs/b.md`. A root registered at `ROOT_REAL/docs` would likewise print `/ROOT/docs/x.md` as `x.md`, losing `docs/x.md` (paraphrased, no quote available because it is inferred from the same rule, not separately run). "Q-103 residual" is the established term: `docs/reviews/override-log.md:509` "Decided at U2b1b iteration 1 ...: Q-103 residual".

**Evidence:** `scripts/lib/dev-cycle-read.sh:733-735`, `docs/reviews/override-log.md:509`, `LOGS/probe.txt`

---

## Claim 20: "The roots never hold an empty line, so the blank line ends them."

**Location:** `scripts/lib/dev-cycle-read.sh:1001`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers IMPORT_ROOTS from a successful reader_set. It does not establish the same for IMPORT_HOMES, which can start with an empty line (an empty own home). That is harmless, because the separator is defined by the roots side.

Blank caller roots are skipped and index 0 (ROOT_REAL) must match `/*` (`:862-863`). need_root guarantees a nonempty ROOT_REAL (`:141`). Worktree paths come from `worktree <path>` records, which are never empty.

**Evidence:** `scripts/lib/dev-cycle-read.sh:140-144`, `scripts/lib/dev-cycle-read.sh:861-866`

---

## Claim 21: commit 5516c6e6: "Both walks call reader_set before their cache check and key on its lists (override row 437), so HOME no longer needs import_reset (contract item 4)"

**Location:** commit 5516c6e6 (message body)
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the same as Claims 1 and 12. It does not establish that row 437's other half (IMPORT_OUT_MAX in the key) is done: it is not, and contract item 4 still asks for a reset there.

Same evidence as Claim 1. Row 437 (`overrides.txt`) asked that "the walk caches ... must take the reader set into their key". Both keys do (`:1003`, `:1052`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1000-1003`, `scripts/lib/dev-cycle-read.sh:1050-1052`, `LOGS/probe2.txt`

---

## Claim 22a: commit 5516c6e6: "Over /workspace both walks give main's ... names"

**Location:** commit 5516c6e6 (message body)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the name sets as of 2026-10-09T03:22Z (main e50aab35, 24 worktrees). It does not establish equality for other checkout states.

Executed: sorted name lists from main's lib and HEAD's lib are byte-identical for both the tree and main walks (`tree: head names == main names`, `main: head names == main names`).
- Command: `bash u2b3a-fc-measure.sh`, exit 0, 2026-10-09T03:22:12Z.

**Evidence:** `LOGS/measure.txt`

## Claim 22b: commit 5516c6e6: "main's 129 names"

**Location:** commit 5516c6e6 (message body)
**Type:** Configuration (measured value)
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the count as of this run. It does not establish the checkout's untracked state at the author's run, which could have held one more start or import.

Both walks give 128 distinct names (0 duplicates). `printf "%s" "$IMPORTED" | wc -l` gives 129, because IMPORTED starts with a newline (`IMPORTED=$'\n'`, `:1013`) and ends each name with one. The likeliest reading is that 129 counts newlines, not names. Precise: "128 names".

**Evidence:** `scripts/lib/dev-cycle-read.sh:1013`, `scripts/lib/dev-cycle-read.sh:1023`, `LOGS/measure.txt`

## Claim 22c: commit 5516c6e6: "in 1.33 s against 1.31 s"

**Location:** commit 5516c6e6 (message body)
**Type:** Performance
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the order of magnitude and the "roughly equal" conclusion. It does not establish the exact figures, which depend on machine load and on which walk(s) were timed.

Three runs of both walks each, over /workspace: main's lib 2402, 2350 and 2491 ms; HEAD 2370, 2630 and 2586 ms (median about 2.40 s against 2.59 s, +8%). Single-walk runs ranged 1.09-1.68 s. That is consistent with "about the same, slightly slower", but the 1.33/1.31 pair cannot be reproduced at this noise level. Reproducing it would need a quiesced host and the author's timing method.

**Evidence:** `LOGS/timing.txt`, `LOGS/measure.txt`

---

## Claim 23: commit 5516c6e6: "every-root cost /workspace's walks 37 times the output (5.6 KB to 211 KB, growing per nested worktree)"

**Location:** commit 5516c6e6 (message body)
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the same measurement as Claim 17 (5607 to 211499 bytes, 37.7 times). It does not establish the "growing per nested worktree" scaling beyond the one point measured, though it follows from one output name per matching nested root.

See Claim 17.

**Evidence:** `LOGS/measure.txt`

---

## Claim 24: commit 76a64fe8: "Six tests ... all six fail on main's lib"

**Location:** commit 76a64fe8 (message body)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the six `U2b3a` tests against `git show main:scripts/lib/dev-cycle-read.sh`, with HEAD's tests and the rest of the tree. It does not establish that each test fails only on its intended assertion. The first failing `want` is shown below, and each is the U2b3a assertion.

On a copy of the worktree's `scripts/` and `test/` with main's lib swapped in, all six are `not ok`, failing on `want: docs/abs.md: imported`, `docs/n.md: imported`, `docs/h.md: imported`, `walk: failed` (tests 4, 5) and `tree a1: imported`. On HEAD all six are `ok`, and the full file is 112/112.
- Commands: `bats -f U2b3a test/scripts/build-loop-check.bats` (cwd the worktree, then cwd /tmp/u2b3a-fc-*/copy), exit 0 and 1, 2026-10-09T03:21:27Z.

**Evidence:** `test/scripts/build-loop-check.bats:1713-1792`, `LOGS/head-u2b3a.txt`, `LOGS/mainlib-u2b3a.txt`, `LOGS/full-suite.txt`

---

## Claim 25: the six test names (absolute name into another worktree; relative name re-entering a nested or sibling worktree; caller's roots and homes; fail closed on unmodelable roots/homes and failed `git worktree list`; newline worktree path; caches keyed on the reader set)

**Location:** `test/scripts/build-loop-check.bats:1713`, `test/scripts/build-loop-check.bats:1724`, `test/scripts/build-loop-check.bats:1737`, `test/scripts/build-loop-check.bats:1749`, `test/scripts/build-loop-check.bats:1768`, `test/scripts/build-loop-check.bats:1777`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each body testing what its name says, on both walks. It does not establish coverage of HOME itself changing (test 6 changes IMPORT_READER_HOMES, not HOME; Claim 1's probe covered HOME), nor of an own HOME holding a newline (Claim 18).

Test 1 commits `@<main>/docs/abs.md` and runs from `../gate`. Test 2 uses `@.claude/wt-b/docs/n.md` (nested, read from the main root) and `@../side/docs/s.md` (sibling, read from wt-b's root). Test 3 checks `-` without the caller lists, then `imported` with `IMPORT_READER_ROOTS=/host/cw IMPORT_READER_HOMES=/host`. Test 4 covers six refused forms, a blank-line list accepted, and a `git` shim exiting 1 on `worktree`. Test 5 skips if git refuses the path. Test 6 runs in one shell with no import_reset. Each `want walk failed` case also checks `docs/other.md imported` (fail closed).

**Evidence:** `test/scripts/build-loop-check.bats:1713-1792`, `LOGS/head-u2b3a.txt`

---

## Claims Requiring Attention

### Incorrect
- None.

### Stale
- **Claim 5** (`scripts/lib/dev-cycle-read.sh:667-668`): it still says relative names are made absolute as "ROOT_REAL/DIR/name". They are now joined to every reader root (`:713`). Say "each reader root's DIR/name".

### Mostly Accurate
- **Claim 9** (`scripts/lib/dev-cycle-read.sh:702-704`): "since the roots are real too". Roots now hold spelled forms as well. Restate the reason (a real root matches only a real home spelling).
- **Claim 18** (`scripts/lib/dev-cycle-read.sh:842-845`): the own-home exemption does not cover "holds a newline": a HOME with a newline fails both walks. A caller home's "/ alone" is checked on the spelling only (`/x/..` accepted, unlike roots).
- **Claim 22b** (commit 5516c6e6): "129 names". Both walks give 128 distinct names. 129 is IMPORTED's newline count.

### Unverifiable
- **Claim 22c** (commit 5516c6e6): "1.33 s against 1.31 s". It cannot be reproduced at the host's noise level. This run measured about 2.40 s against 2.59 s for both walks (median of 3). That is consistent with "roughly equal", but the exact figures would need a quiesced host and the author's method.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to /workspace/.claude/wt-build-loop-u2b3a/docs/reviews/code-fact-check-report.md, structured per the code-fact-check skill, with `Commit: 5516c6e6` as its first line and `**Replication:** k=1 (loop pass, decision 031)` in its header.
- Answered: yes
- Out of scope: U2b3b's outside-repo starts and host settings line (override rows 431, 477), not re-flagged; code-quality and policy judgments (whether refusing an own HOME with a newline is right) are left to critics.
- Escalate: Claim 18's own-HOME-newline refusal is a behavior change. Both walks now fail closed whenever HOME holds a newline, even with no `~/` names. It is fail-closed, but a critic may want it noted. Execution logs live in the scratch dir, not `docs/reviews/execution-logs/`, per the brief's write-one-file rule.
- Decisions I made: split the commit's "129 names, 1.33 s against 1.31 s" sentence into three atoms (22a-c). Built an every-root variant of HEAD's awk to check the 37x figure, rather than trusting the commit.
