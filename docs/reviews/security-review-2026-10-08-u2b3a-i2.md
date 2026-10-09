Commit: c9197fd2

# Security Review: feat/build-loop-u2b3a, iteration 2 (fix range)

**Scope:** partial, `git diff 5516c6e6..HEAD -- scripts test` (fix commits 4dba56dc, c9197fd2): `scripts/lib/dev-cycle-read.sh`, `test/scripts/build-loop-check.bats`, `test/scripts/dev-cycle.bats`
**Date:** 2026-10-08
**Based on:** `docs/reviews/code-fact-check-report-build-loop-u2b3a-i2.md` (Commit c9197fd2; 0 Incorrect, 1 Stale, 7 Mostly accurate), iteration-1 rubric `code-review-rubric-2026-10-08-feat-build-loop-u2b3a.md`, my iteration-1 report `security-review-2026-10-08-u2b3a.md`, shared brief `u2b3a-i2/shared.md`, override rows 425, 431, 432, 437, 477 and this branch's G8, G9, G11, G12 rows
**Threat model (from the brief):** loops are honest. Hostile rewrites of shared git state are the Q-103 residual. The walks are supersets that fail closed.

Probe: `scratchpad/u2b3a2-sec-p1.sh`, log `u2b3a2-sec-p1-head.log`, run against `git show HEAD:scripts/lib/dev-cycle-read.sh`. It is one `set -eu` script. It makes its own `mktemp -d /tmp/u2b3a2-sec-XXXX`, checks `pwd -P` before every `git init`/`worktree add`, runs each decision under `timeout 60`, and removes its dir. Afterwards no `/tmp/u2b3a2-sec-*` dir or process was left.

## Trust Boundary Map

```
B1:         [git worktree registry, shared common dir]       → [import_readers: nul_list, /*, newline, "/" checks, memo] → [IMPORT_ROOTS → awk pre[], dotnest, put projection]
B2 (moved): [caller IMPORT_READER_ROOTS / _HOMES]             → [cleared on source (item 9); import_readers checks]     → [IMPORT_ROOTS / IMPORT_HOMES]
B3:         [HOME env / passwd]                               → [import_home; newline → empty in import_readers]        → [homes[1] exit-4 rule, ~/ joins]
B4:         [instruction-file text: checkout file or main blob] → [awk emit/put: resolve, every-root projection less dotnest] → [printed names → isimported → truthwalk → floor]
B5 (new):   [IMPORT_READERS_DONE memo]                        → [readers_key compare]                                    → [reader set reused until import_reset]
```

Input-source classification:

```
S1: git worktree list --porcelain -z  — runtime-mutable (any session sharing the common dir; stale prunable entries)
                                         — trusted to exist as listed (honest loops). For the projection sink it now only
                                         adds names, and hides dot-component spellings only (executed below). Hostile
                                         rewrites are Q-103.
S2: IMPORT_READER_ROOTS / _HOMES       — caller-set after sourcing (contract item 9). Cleared on source, so the inherited
                                         environment no longer reaches them (fact-check Claim 2, 20). Trusted to add names.
S3: HOME / passwd                      — request-time — trusted for joins. A relative, empty or newline-holding home fails
                                         only a ~/ name (exit 4), closed.
S4: instruction-file text              — branch-writable — UNTRUSTED (all sinks); treated as data by the parser.
S5: ROOT_REAL                          — caller-set, pinned by need_root — trusted.
```

The fix range changes three things on these boundaries. B2 is cut from the environment. B4's projection is now every-root less dotnest, instead of longest-root. B5 adds a memo that fixes the S1 snapshot for a whole decision. The trust assumption that broke in iteration 1 (an unenforced "honest roots nest only under .claude/") has been replaced by a predicate, dotnest. It drops only spellings that truthrule refuses.

## Focus answers (summary)

1. **Does dotnest close iteration-1 Finding 1 for every non-dot nesting?** Yes, in every shape I executed. A nested root at a non-dot path never enters `dotnest`, so both the outer and the inner spellings are printed. Executed on both walks: a stale registry entry (fact-check P5/P6, test 110), a caller root at `$r/sub` with no registry entry (C1), the same with a trailing slash (C2), a caller root symlinked from outside the repo into `$r/sub` (C3), spelled `$r/sub/..` and `$r/./sub` (C4), a caller root at a dot path `$r/.claude` (C5), a repo that itself sits under a dot directory with a stale `sub` entry (C8), and two-level non-dot nesting `sub` and `sub/in`, absolute and relative (C9). Case-only differences are not modelled at all (case-sensitive `index`), which is the stated case-insensitive exception (override-log line 350). They are listed under untested candidates.
2. **Can any root shape make dotnest drop a non-dot name?** No. Let O be an outer holder and N a nested holder. For O's spelling X = out − pre[O] to be dropped, dotnest[O, N] must hold, where pre[N] = pre[O] R and `"/" R` contains `"/."`. Because N holds `out`, X = R + rest, so `"/" X` contains `"/."`. That is exactly truthrule's `dot` test (`"/$1" == */.*`, `:1210`), and both floor and check_fix apply it before the walk. So every dropped spelling is one the floor refuses whole. This holds for a dot component anywhere in R, not only the first (C10: a worktree at `docs/.wt/a` drops `docs/.wt/a/q.md`, and `truthrule` refuses it as `dot`). Each special shape:
   - **A dot component above the nesting.** dotnest reads only R, the part below O (C8).
   - **`/` as a root.** import_readers refuses it as written or as realpath reads it (C7, walk fails closed). Even at `pre = "/"`, the dropped spelling would be a full path holding the nested root's dot component.
   - **Equal spellings.** Strict `>` keeps them out of dotnest, and `rs_seen` de-duplicates them.
   - **Spellings with `..`, `.` or a trailing `/`.** These can enter `dotnest` as nested roots (for example `sub/../`), but they are never holders: `out` is lexical and holds no `.`, `..` or `//` component (fact-check Claim 13). Their realpath forms are added too and behave as plain roots.
3. **Does the memo let one decision see a stale reader set in a way that drops a name?** Not through a root that is present. A root kept in the memo after an honest `git worktree remove` only keeps adding names (C11: `sub/x.md` still imported, before and after reset). A root added mid-decision is missing until `import_reset` (C12: `x.md` reads `-` until the reset, while `sub/x.md` stays imported). That is the decision's snapshot, and contract item 4 bounds it. It opens nothing a worktree added just after the decision would not, and both walks now see the same set. A failed import_readers leaves `IMPORT_READERS_DONE` empty, which matches no key (`READERS_KEY` always holds `0:` parts), so a failure is never cached as a success.

## Findings

#### 1. The A1 test's caller-root half does not nest a caller root over the imported name

**Severity:** Informational
**Location:** `test/scripts/build-loop-check.bats:1756`, `:1766`
**Boundary:** B2 → B4
**Move:** 11 (enumerate bypasses: the guard's test coverage)
**Confidence:** High (executed; agrees with fact-check Claim 21)
**Legibility-target:** for-author

Evidence:

```bash
# test/scripts/build-loop-check.bats:1756
@test "a root nested in another at a non-dot path keeps the outer path's names: a stale registry entry or a caller root inside the repo (U2b3a i1 security 1, architecture F1)" {
# test/scripts/build-loop-check.bats:1766
        T_READER_ROOTS="$r/docs" imps "$w" sub/x.md; want walk ok; want sub/x.md imported
```
(excerpts inside the test body `:1756-1768`, read whole; the stale `sub/` entry is still registered when `:1766` runs.)

Iteration 1's Finding 1 named three routes to the fail-open: a stale entry, a caller root inside the repo, and a caller root symlinked into the repo. The test pins only the first. `$r/docs` does not hold `$r/sub/x.md`, so the caller-root row exercises nothing the stale row lacks. The code is right: probe C1 (caller root `$r/sub`, no registry entry) and C3 (caller root `$T/lnk -> $r/sub`) both read `sub/x.md: imported` on both walks. The gap is that a future regression in the caller-root route would pass the suite.

**Recommendation:** Change `:1766` to `T_READER_ROOTS="$r/sub"`, run it after `git worktree prune` so the registry no longer supplies the root, and add a row whose caller root is a symlink from `$BATS_TEST_TMPDIR` to `$r/sub`.

#### 2. dotnest's soundness rests on truthrule's any-component dot rule, and neither side names the coupling

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:738-751` (put), `:813` (dotnest), `:1210` (truthrule), `:679` (superset statement)
**Boundary:** B4 → floor (via isimported/truthwalk)
**Move:** 2 (implicit sanitization assumption)
**Confidence:** High (the predicate identity is read-static; C10 executed)
**Legibility-target:** for-author

Evidence:

```awk
# scripts/lib/dev-cycle-read.sh:813
    if (length(pre[j]) > length(pre[i]) && index(pre[j], pre[i]) == 1 && index("/" substr(pre[j], length(pre[i]) + 1), "/.")) dotnest[i, j] = 1
```
```bash
# scripts/lib/dev-cycle-read.sh:1210
  elif [[ "/$1" == */.* ]]; then TRUTH_WHY="dot"
```
```
# scripts/lib/dev-cycle-read.sh:738-741
  # Relative to every root holding it, but an outer root whose path down to a
  # nested root holding it has a dot component (dotnest): a session in a
  # worktree under /workspace/.claude/ reads the file there as a path of that
  # worktree, and the outer spelling is a dot path the floor refuses whole,
```
(excerpt ends :741; put() continues to :751, read whole.)

A name hidden by the walk is safe only because the floor refuses it whole by another rule. That holds today because both predicates are the same test, "a component led by `.`", anywhere in the path. If truthrule were narrowed (to `.claude/` only, or to a top-level dot), dotnest would hide `docs/.wt/a/q.md` (C10) from a floor that no longer refuses it. That would reopen iteration 1's fail-open with no test going red. The put comment says "a dot path the floor refuses whole" but does not point at truthrule. The superset statement at `:679` still says "printed relative to the longest one holding it" (fact-check Claim 9, Stale), and that is the line a later editor of the floor would read. Nothing is exploitable now.

**Recommendation:** Reword `:679` (the fact-check gives the wording). In put's comment, name truthrule's `dot` rule as the condition dotnest relies on, and in truthrule's comment add "dotnest in IMPORT_AWK hides only names this rule refuses". Optionally, add a test that a worktree at a deep dot path (`docs/.wt/a`) leaves `floor docs/.wt/a/q.md` refused.

## Iteration-1 items (security view)

- **i1 Finding 1 / A1:** closed. See Focus answers 1-2, test 110, and probes C1-C10.
- **i1 escalation / A2** (the environment can remove names): closed twice over. Sourcing clears the lists (fact-check Claim 2), and after A1's fix a root can no longer remove a non-dot name.
- **i1 Finding 2 / G1** (a stale list in standalone import_targets): holds. The lists are used only under a current memo key (fact-check Claim 8). Even a stale list now only adds names or hides dot spellings.
- **i1 Finding 3 / G2, G3:** hold. A newline HOME fails only a `~/` name (test 112). `/x/..` is refused as a root and as a caller home (test 111, C7).
- **A3 memo:** no fail-open (Focus answer 3).

## Untested bypass candidates

- **A host alias spelled in a different case** (`/Users/X/...` against `/users/x/...` on a case-insensitive host). `index` is case-sensitive, so the alias spelling is not matched. This is additive-only (a missing alias name, never a hidden one) and it is U2b3b's host-alias territory (override row G8 / line 350). Not tested: the probe host is Linux.
- **Unicode-normalization variants of a root path** (NFC/NFD). Not tested, for the same reason.
- **A symlinked directory inside the repo between an outer and a nested root** (for example an untracked `.claude` that is a symlink to `sub`). The parser is lexical, so it would hide `.claude/wt-a/x.md` while the real file is main's `sub/wt-a/x.md`. Main's lib projects the same lexical spelling and does not follow the link either, so this is not introduced by the fix range. Reasoned only, not executed.
- **Hostile registry rewrites** (Q-103 residual, named in import_readers' comment). Not tested, by the threat model.

## Endorsement Claims

- **Claim:** In both walks, a root nested at a non-dot path, whether it comes from a stale registry entry, a caller root, a trailing-slash spelling, a `..`/`.` spelling or an outside symlink into the repo, keeps the outer repo path `sub/x.md` imported and adds `x.md`.
  **Location:** `scripts/lib/dev-cycle-read.sh:745-750`, `:811-813`
  **Evidence:** executed
  **Verified:** `u2b3a2-sec-p1-head.log` C1-C4, C8, C9 (tree and main walks, HEAD lib); fact-check P5/P6 for the stale entry (red on 5516c6e6).
  **Not verified:** the floor's refusal message for such a path through `--check`. isimported was run, `floor` was not.
  **route: code-fact-check**

- **Claim:** Every spelling put() withholds because of dotnest contains a component led by `.`, so truthrule's `dot` rule refuses it before the walk is asked.
  **Location:** `scripts/lib/dev-cycle-read.sh:748-749`, `:813`, `:1210`
  **Evidence:** read-static (plus C10 executed for one deep-dot shape)
  **Verified:** the derivation in Focus answer 2. C10: a worktree at `docs/.wt/a` withholds `docs/.wt/a/q.md` and `docs/.wt/a/s/t.md`, and `truthrule docs/.wt/a/q.md` returns `dot`.
  **Not verified:** a run that compares, over a generated set of nested root shapes, the names withheld against truthrule's verdict on each.
  **route: code-fact-check**

- **Claim:** A root kept in the memo after an honest `git worktree remove` mid-decision does not remove a name. A root added mid-decision is seen after `import_reset`.
  **Location:** `scripts/lib/dev-cycle-read.sh:881-888`, `:615`
  **Evidence:** executed
  **Verified:** C11 (`sub/x.md` imported before, after the remove, and after the reset) and C12 (`x.md` `-` under the memo, imported after the reset), on the main walk; test 114 for the tree walk.
  **Not verified:** the C11/C12 sequence on the tree walk.

- **Claim:** A `/` root (as written, or `/x/..`) fails both walks, and a failed walk answers imported for every path.
  **Location:** `scripts/lib/dev-cycle-read.sh:896`, `:902`, `:1188-1189`
  **Evidence:** executed
  **Verified:** C7 on both walks; test 111.
  **Not verified:** a root that realpath reads as `/` through a symlink to `/` (for example `$T/rootlink -> /`). Its realpath form is checked at `:902`, but no probe ran it.

## Primitive sweep

Primitive: path join and lexical resolution (the names a walk keeps or withholds)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/lib/dev-cycle-read.sh:714` (`~/` join per home) | S3, S2, S4 | exit 4 on a non-absolute `homes[1]`; newline home read as empty | cleared: additive per home (C6) |
| `scripts/lib/dev-cycle-read.sh:716` (absolute name) | S4 | every-root projection at `:746-750` | cleared: i1 Finding 1 closed (C1-C4, C8, C9) |
| `scripts/lib/dev-cycle-read.sh:719` (relative name per root and directory) | S4, S1, S2 | same projection | cleared (C9 relative row) |
| `scripts/lib/dev-cycle-read.sh:746-750` (projection less dotnest) | S1, S2, S5 | dotnest ⊆ truthrule `dot` | cleared; Finding 2 (coupling unnamed) |
| `scripts/lib/dev-cycle-read.sh:811-813` (pre[], dotnest table) | S1, S2 | strict length, `/` boundary | cleared (equal, `/`, unbounded-prefix and `..` spellings: Focus answer 2) |
| `scripts/lib/dev-cycle-read.sh:900` (`realpath -mz` batch) | S1, S2 | count check `:901`; `/` and newline checks `:903` | cleared |

Primitive: process exec

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/lib/dev-cycle-read.sh:888` (`git worktree list --porcelain -z`) | S5 (cwd) | fixed argv; nul_list; need_root | cleared (unchanged from i1) |
| `scripts/lib/dev-cycle-read.sh:900` (`realpath -mz -- …`) | S1, S2 | `--` ends options; entries must start with `/` | cleared: no option injection |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | The A1 test's caller-root half does not nest a caller root over the imported name | Informational | B2 → B4 | `test/scripts/build-loop-check.bats:1756`, `:1766` | High |
| 2 | dotnest's soundness rests on truthrule's any-component dot rule, coupling unnamed (and `:679` still says "longest") | Informational | B4 → floor | `scripts/lib/dev-cycle-read.sh:738-751`, `:813`, `:1210`, `:679` | High |

## Overall Assessment

The fix range closes iteration 1's only real finding, and the fix does not move the fail-open elsewhere. Under every-root projection less dotnest, a nested root can add names. It can withhold only spellings that hold a dot-led component, which is the same predicate truthrule's `dot` rule refuses. This holds for stale entries, caller roots, symlinked, trailing-slash and `..` spellings, repos under dot directories, and multi-level nesting (executed on both walks). The memo freezes the registry for one decision. A root kept after removal only adds names, and a root missing until reset is the decision's ordinary snapshot. The caller lists no longer come from the environment. Both findings are Informational and can be fixed in place: pin the caller-root route in the A1 test, and name the dotnest/truthrule coupling (rewording the stale `:679` superset sentence). No findings above Informational within the code paths read. The executed endorsement claims are scoped by their `Not verified` hops, and the read-static one is pending execution verification.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to /workspace/.claude/wt-build-loop-u2b3a/docs/reviews/security-review-2026-10-08-u2b3a-i2.md, structured per the security-reviewer skill, with `Commit: c9197fd2` as its first line.
- Answered: yes
- Out of scope: commits before 5516c6e6 (context only); override rows G8, G9, G11, G12, 431, 477 (not re-flagged); the fact-check's figure and wording points (Claims 1, 6, 7b, 15b, 26c-f), which are not security matters; hostile registry rewrites (Q-103).
- Escalate: nothing blocking. Fold Finding 2's comment cross-reference into the same fix that rewords the fact-check's Stale Claim 9 at `:679`.
- Decisions I made: rated both findings Informational, since neither names a reachable mechanism that violates a property today; treated the mid-decision missing root (C12) as the contract-item-4 snapshot rather than a finding, because a worktree added just after the decision has the same effect.
