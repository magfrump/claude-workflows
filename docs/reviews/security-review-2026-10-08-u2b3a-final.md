Commit: 3d2d8c44

# Security Review: feat/build-loop-u2b3a, final confirming pass

**Scope:** the full branch, `git diff main...HEAD -- scripts test` (`scripts/lib/dev-cycle-read.sh`, `test/scripts/build-loop-check.bats`, `test/scripts/dev-cycle.bats`). The plan's U2b3 bullet is in scope for claims only.
**Date:** 2026-10-08
**Based on:** `docs/reviews/code-fact-check-report-build-loop-u2b3a-final.md` (k=3, 0 Incorrect, 2 Mostly accurate, two escalations), rubric `code-review-rubric-2026-10-08-feat-build-loop-u2b3a.md` (iterations 1-2), my iteration-2 report `security-review-2026-10-08-u2b3a-i2.md`, shared brief `u2b3a-i3/shared.md`, and override rows 425, 431, 432, 437, 477 plus this branch's nine rows.
**Threat model (from the brief):** loops are honest. Hostile rewrites of shared git state, the worktree registry included, are the Q-103 residual. The walks are supersets that fail closed.

Probe: `scratchpad/u2b3a3-sec-p1.sh` is one `set -eu` script. It makes its own `mktemp -d /tmp/u2b3a3-sec-XXXX`, checks `pwd -P` before `git init` and `git worktree add`, runs each walk under `timeout 60`, and removes its dir on exit. I ran it against HEAD's lib (log `u2b3a3-sec-p1.log`) and against `git show main:scripts/lib/dev-cycle-read.sh` (log `u2b3a3-sec-p1-main.log`). I also ran `bats -f U2b3a test/scripts/build-loop-check.bats` with its own TMPDIR: 8 of 8 pass. Afterwards no `/tmp/u2b3a3-sec-*` dir or process was left.

## Trust Boundary Map

```
B1:         [git worktree registry, shared common dir]         → [import_readers: nul_list, /*, newline, "/" checks, realpath -mz, memo] → [IMPORT_ROOTS → awk pre[], dotnest, put projection]
B2:         [caller IMPORT_READER_ROOTS / _HOMES]               → [cleared on source (item 9); same checks as B1]                           → [IMPORT_ROOTS / IMPORT_HOMES]
B3:         [HOME env / passwd]                                 → [import_home; newline read as empty]                                     → [homes[1] exit-4 rule, ~/ joins]
B4:         [instruction-file text: checkout file or main blob] → [awk emit/put: lexical resolve, every-root projection less dotnest]       → [printed names → isimported → truthwalk → floor / check_fix]
B5:         [the set of start files a reading session loads]    → [tree_starts / main's isstart records + checkout_md, in ROOT_REAL only] → [walk seeds]
B6:         [IMPORT_READERS_DONE memo]                          → [import_readers_key compare]                                             → [one reader set per decision, until import_reset]
```

Input-source classification:

```
S1: git worktree list --porcelain -z   — runtime-mutable (any session sharing the common dir; prunable entries)
                                          — trusted to exist as listed (honest loops). For the projection sink it only
                                          adds names and hides dot-component spellings. Hostile rewrites are Q-103.
S2: IMPORT_READER_ROOTS / _HOMES        — caller-set after sourcing (contract item 9); cleared on source. Trusted to add
                                          names; UNTRUSTED for well-formedness (U2b3b will read them from a settings file).
S3: HOME / passwd                       — request-time — trusted for joins. A relative, empty or newline-holding own home
                                          fails only a ~/ name (exit 4).
S4: instruction-file text               — UNTRUSTED (all sinks); parsed as data. Main's start and imported texts reach main
                                          only through reviewed merges, since floor refuses them on a self-merge. The
                                          checkout's text is loop-written.
S5: ROOT_REAL                           — caller-set, pinned by need_root (non-empty, equal to pwd -P, top level) — trusted.
S6: untracked or branch-only start files in other registered checkouts
                                        — user- or loop-written, never reviewed — not read by either walk (Finding 1).
```

The branch adds two boundaries, B1 and B2: roots and homes now come from the registry and from the caller. It also changes B4's projection from one root to every root less dotnest. B5 does not change, but the branch's comment now describes it more broadly than the code does (Finding 1). Both walks call need_root before import_readers, so S5 is always non-empty and current when the reader set is computed.

## Focus answer

*Can any input the walks read (registry paths, the caller lists, HOME, file text, root spellings) make a walk drop a name a reading session imports, or make floor or check_fix answer not-imported for such a name?*

- **Registry paths and root spellings (S1, S2): no fail-open within the threat model.** This range adds no root shape that can hide a non-dot spelling. Iteration 2 executed nine nesting shapes, and the U2b3a tests pass at HEAD. What closes the case is the predicate identity: dotnest withholds only a spelling with a `.`-led component, which is exactly truthrule's `dot` rule at `:1220`. The two now cross-reference each other at `:751` and `:1220`, and test 4 pins truthrule's answer. New this pass: a caller root that is a symlink to `/` fails both walks (C4), which closes iteration 2's "Not verified" hop. A root that is malformed but passes the checks, such as one with a trailing CR, adds nothing and hides nothing (Finding 3).
- **HOME (S3): no fail-open.** A relative, empty or newline-holding own home gives exit 4 on a `~/` name (test 6). A caller home that realpath reads as `/` is refused (test 5).
- **File text (S4): one pre-existing lexical gap, unchanged by the branch.** A spelling that reaches a root only through the kernel, such as `@/proc/self/cwd/docs/x.md`, is dropped by both walks on HEAD and on main (Finding 2). Adding such an import needs a reviewed merge.
- **Start files (S6): one pre-existing gap that the branch's comment now overstates.** A start file that exists only in another registered checkout is never walked, so floor and check_fix answer not-imported for what it imports (Finding 1). This is the same mechanism as fact-check escalation 2, extended from the ancestor checkout to siblings.
- **Memo (B6): no fail-open.** Iteration 2 showed a stale root only adds names, and a root added mid-decision is a contract-item-4 snapshot. The fallback in import_targets (`:933`, ROOT_REAL alone) is not reachable inside a walk. Each walk calls import_readers in the same shell immediately before its `$(...)` parser calls, and nothing between them changes ROOT_REAL, HOME or the caller lists.

## Findings

#### 1. Start files that exist only in another registered checkout are never walked, and the superset statement says "a session in any checkout is modelled"

**Severity:** Medium
**Location:** `scripts/lib/dev-cycle-read.sh:689-690` (the claim), `:612-614` and `:600-605` (the walks' "Not covered" lists, which omit it), `:1053` (tree_starts), `:1123` (checkout_md), both read in ROOT_REAL only
**Boundary:** B5 (S6 → walk seeds), then B4 → floor / check_fix
**Move:** 5 (invert the model: what does the reader set *not* cover?), 2 (implicit assumption)
**Confidence:** High for the mechanism (executed); Low for exposure today (no sibling checkout holds an untracked start file)
**Legibility-target:** for-orchestrator-synthesis

Evidence:

```
# scripts/lib/dev-cycle-read.sh:689-690
# every such path). A relative name is resolved against each root's copy of its
# directory, so a session in any checkout is modelled, and a ~/ name is joined
```
```
# scripts/lib/dev-cycle-read.sh:612-614
# Neither walk starts at an instruction file outside the repo, though Claude
# Code loads them and follows their imports into it: a parent directory's
# CLAUDE.md, the user's memory file (known issue A5; U2b3b's outside starts).
```
```bash
# scripts/lib/dev-cycle-read.sh:1053  (imported_names; read whole, :1045-1078)
  nul_list recs tree_starts || return 1
# scripts/lib/dev-cycle-read.sh:1123  (main_imports; read whole, :1094-1187)
  nul_list recs checkout_md || return 1
```

Probe C3 on HEAD's lib: a repo has worktrees `side` and `gate`, and `side/CLAUDE.local.md` (untracked) holds `See @docs/z.md`. From `gate`, both walks print `walk ok` and `docs/z.md: -`. From `side`, both print `docs/z.md: imported`. Main's lib gives the same answers, so this is not a regression.

A session started in `side` loads its `CLAUDE.local.md` and imports `docs/z.md`. A self-merge judged from the gate's worktree is let through for `docs/z.md`, and that session reads the changed file as instructions after it next takes main. The branch models such a session's *names*: its relative names resolve against `side/` and its absolute names project. It does not model the session's *starts*. Line 690's "a session in any checkout is modelled" says more than that. The "Not covered" lists, read by whoever builds U2c's floor caller or U2b3b, name outside-repo files and A5's shapes but not starts that exist only in another checkout.

U2b3b's plan bullet covers the ancestor case (the main checkout's working-tree files, "named exceptions: ... an ancestor checkout's working-tree instruction files"), and fact-check escalation 2 routes it there. Neither the bullet nor any override row names a sibling checkout's untracked start files (`CLAUDE.local.md`, ignored `.claude/rules/*.md`), or a sibling on another branch whose tracked starts differ from main. Exposure today: only `/workspace` holds untracked start-named files (`devcontainer-config/claude-home/**`, the ancestor case), and per fact-check r1 none of their names is a tracked path. No sibling worktree holds any. The mechanism needs only honest actions: a user or loop writing a `CLAUDE.local.md` in its own worktree.

**Recommendation:** Do not block the merge on code. Reword `:689-690` to "so a listed checkout's relative names are modelled (its start files are the gate checkout's and main's only)". Add "start files that exist only in another registered checkout (untracked, ignored, or on its branch)" to the "Not covered" list at `:600-605` or `:612-614`. Then either record a Defer row routing the sibling case to U2b3b beside the ancestor case, or name it there as an exception.

#### 2. A spelling that reaches a root only through the kernel (`/proc/self/cwd/...`, `/proc/self/root/...`, an outside symlink into the repo) is dropped

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:684-686` (kept only below a reader root), `:756` (holder test, lexical)
**Boundary:** B4
**Move:** 11 (bypass candidates for the projection guard)
**Confidence:** High that the walk drops it (executed); Low on whether Claude Code imports it without the external-include approval (untraced)
**Legibility-target:** for-author

Evidence:

```awk
# scripts/lib/dev-cycle-read.sh:756  (put, read whole :731-761)
  nho = 0; for (i = 1; i <= nr; i++) if (index(out, pre[i]) == 1 && length(out) > length(pre[i])) h[++nho] = i
```

Probe C1: `AGENTS.md` holds `See @/proc/self/cwd/docs/x.md`, and both walks answer `docs/x.md: -` on HEAD and on main. The kernel resolves the name into the session's working directory. If Claude Code classifies external includes by realpath, it would load the file. If it classifies lexically, the name is an external include and falls under the named exception "Claude Code's approved external includes".

This is rated Informational, not Medium, because the walk-relevant text is not reachable by a self-merge. Adding an import to a file a session loads means editing a start or imported file, and floor refuses both, so the spelling can land on main only through a reviewed merge. The tree walk reads loop-written checkout text, and honest loops do not write `/proc` paths. The gap is pre-existing.

**Recommendation:** None for this branch. If U2b3b revisits the superset statement, name "a spelling that reaches a root only through a symlink outside every root, such as /proc/self/cwd" beside the approved-external-includes exception.

#### 3. A caller root or home holding a CR or another control byte passes import_readers and silently matches nothing

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:906`, `:913`
**Boundary:** B2
**Move:** 2 (format-checked, not content-checked)
**Confidence:** High (executed)
**Legibility-target:** for-author (forward to U2b3b)

Evidence:

```bash
# scripts/lib/dev-cycle-read.sh:906  (import_readers, read whole :891-927)
    [[ "$p" == /* && "$p" != *$'\n'* && -n "${p//\//}" ]] || return 1
```

Probe C2: with `IMPORT_READER_ROOTS=/host/cw`, both walks read `@/host/cw/docs/y.md` as `docs/y.md: imported`. With `$'/host/cw\r'` they answer `walk ok`, `docs/y.md: -`. Today no caller sets the lists, so a bad root is no worse than no root: it is the status quo before U2b3b, and nothing opens. When U2b3b reads `Reader roots:` from docs/dev-cycle.md, a CRLF line or a trailing tab would silently drop the host alias instead of failing the walk. That contradicts the fail-closed rule the other malformed roots follow (test 5).

**Recommendation:** In U2b3b, refuse a root or home holding any C0 control byte (`*[[:cntrl:]]*` under LC_ALL=C) in the same test at `:906`, or strip a trailing CR in the settings reader, and add a test row.

#### 4. import_readers accepts an empty ROOT_REAL and memoizes a reader set whose first root is another worktree

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:899`, `:904-905`, `:909`
**Boundary:** B1 / B6
**Move:** 3 (error path)
**Confidence:** High (fact-check r3 probe P5, executed). Unreachable from both walks, since need_root at `:1048` and `:1098` exits first.
**Legibility-target:** for-author

Evidence:

```bash
# scripts/lib/dev-cycle-read.sh:899
  rs_r=("$ROOT_REAL"); for p in "${rs_l[@]}"; do [[ "$p" != "worktree "* ]] || rs_r+=("${p#worktree }"); done
# scripts/lib/dev-cycle-read.sh:904-905
  for p in "${rs_r[@]}" "${rs_h[@]}"; do
    [[ -n "$p" ]] || continue
```

The blank skip meant for the caller's lists also skips an empty ROOT_REAL, so the parser's empty-first-root exit 2 (`:820`) can no longer fire after import_readers. No walk reaches this. The first caller that could is U2b3b's outside-seed path, which the deferred row (architecture i2 N3) already says must run after import_readers. For that caller, an empty ROOT_REAL would silently model the gate as some other worktree.

**Recommendation:** Add `[[ -n "${ROOT_REAL:-}" ]] || return 1` at the top of import_readers (fail closed), or carry it in U2b3b's bullet beside N3. This matches the fact-check r3 annotation.

## Untested bypass candidates

- **Case-variant or Unicode-normalized spellings of a root** (`/Workspace/...`, NFD) on a case-insensitive host. The probe host is Linux. This falls under the named case exception (override-log line 350).
- **Hostile registry rewrites** dropping a root (Q-103 residual, named at `:881-882`). Out of the threat model.
- **A sibling checkout on another branch whose *tracked* start files differ from main.** This is the tracked analogue of Finding 1. It was reasoned about but not run: the tree walk lists only ROOT_REAL's `git ls-files`, so by reading it has the same outcome as C3.
- **Claude Code's own classification of `/proc/self/cwd` names** (lexical or realpath external-include check). Untraced in the binary (Finding 2).

## Endorsement Claims

- **Claim:** A caller root that is a symlink to `/` fails both walks, and every path then answers imported.
  **Location:** `scripts/lib/dev-cycle-read.sh:910-913`
  **Evidence:** executed
  **Verified:** probe C4 (`$T/rootlink -> /` as IMPORT_READER_ROOTS), tree and main walks on HEAD: `walk failed`, `docs/x.md` and `docs/other.md` imported.
  **Not verified:** a registered worktree path whose directory was later replaced by a symlink to `/`. It takes the same `rs_real` check, but no probe ran it.
  **route: code-fact-check**

- **Claim:** Every spelling put() withholds because of dotnest has a component led by `.`, so truthrule's `dot` rule refuses it before floor or check_fix asks the walk. The two predicates now cite each other.
  **Location:** `scripts/lib/dev-cycle-read.sh:747-760`, `:822-823`, `:1220`
  **Evidence:** read-static, plus the bats test 4 tail (`truthrule` on `.claude/wt-a/sub/y.md` and `docs/.wt/a/q.md` gives `dot`), executed this pass
  **Verified:** the derivation in iteration 2's Focus answer 2, re-read against HEAD's lines. Test 4 passes at 3d2d8c44.
  **Not verified:** a generated sweep comparing withheld spellings with truthrule's verdict over many root shapes.
  **route: code-fact-check**

- **Claim:** In both walks, an absolute name into another registered worktree, a relative name that re-enters a nested or sibling worktree, a caller host root and home, and a stale non-dot nested root each read as the repo path imported. Malformed roots and homes, a failed `git worktree list`, and a newline worktree path fail the walk.
  **Location:** `test/scripts/build-loop-check.bats` U2b3a tests 1-8
  **Evidence:** executed (`bats -f U2b3a`, 8/8 ok at 3d2d8c44)
  **Verified:** the suite's assertions as written.
  **Not verified:** which of these were red on 5516c6e6. The rubric and fact-check report it (test 7 also passes on 5516c6e6 and guards only against a regression to main).
  **route: code-fact-check**

- **Claim:** The `import_targets` fallback to ROOT_REAL alone (`:933`) is not taken inside either walk.
  **Location:** `scripts/lib/dev-cycle-read.sh:929-933`, `:1049`, `:1099`
  **Evidence:** read-static
  **Verified:** each walk runs `import_readers` in its own shell before its parser calls. The parser's `$(...)` subshells recompute the same key, because ROOT_REAL, HOME (IMPORT_HOME_DONE) and the caller lists are not changed in between in `:1045-1078` or `:1094-1187`.
  **Not verified:** a caller that wraps a walk call in a temporary assignment to IMPORT_READER_* or HOME, such as `HOME=x imported_names`. The key would still match inside the call, but no probe ran it.

## Primitive sweep

Primitive: path join and lexical resolution (which names a walk keeps or withholds)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/lib/dev-cycle-read.sh:721-724` (`~/` join per home) | S3, S2, S4 | exit 4 on a non-absolute `homes[1]`; empty homes skipped | cleared (test 6); Finding 3 for control bytes in a caller home |
| `scripts/lib/dev-cycle-read.sh:726` (absolute name) | S4 | every-root projection `:756-760` | cleared within roots; Finding 2 (kernel aliases) |
| `scripts/lib/dev-cycle-read.sh:729` (relative name per root and directory) | S4, S1, S2 | same projection | cleared (test 2) |
| `scripts/lib/dev-cycle-read.sh:756-760` (projection less dotnest) | S1, S2, S5 | dotnest equals truthrule `dot` | cleared (test 4, iteration-2 shapes) |
| `scripts/lib/dev-cycle-read.sh:821-823` (pre[], dotnest table) | S1, S2 | strict length, `/` boundary | cleared |
| `scripts/lib/dev-cycle-read.sh:910` (`realpath -mz` batch) | S1, S2 | count check `:911`; `/` and newline checks `:913` | cleared (C4); Finding 3 (CR passes) |

Primitive: process exec

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/lib/dev-cycle-read.sh:898` (`git worktree list --porcelain -z`) | S5 (cwd) | fixed argv; nul_list; need_root first | cleared |
| `scripts/lib/dev-cycle-read.sh:910` (`realpath -mz -- …`) | S1, S2 | `--` ends options; entries start with `/` | cleared: no option injection |
| `scripts/lib/dev-cycle-read.sh:953-954` (`awk "$IMPORT_AWK"`) | S1, S2, S3 via env | values passed through the environment, not `-v`; IMPORT_AWK holds no `'` (checked `:711-838`) | cleared |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Start files that exist only in another registered checkout are never walked; the superset statement says "a session in any checkout is modelled" (pre-existing; comment overclaim new) | Medium | B5 → B4 | `scripts/lib/dev-cycle-read.sh:689-690`, `:612-614`, `:1053`, `:1123` | High (mechanism) / Low (exposure) |
| 2 | Kernel or symlink aliases into a root (`/proc/self/cwd/...`) are dropped (pre-existing) | Informational | B4 | `scripts/lib/dev-cycle-read.sh:684-686`, `:756` | High / Low (Claude Code side) |
| 3 | A caller root or home with a CR passes import_readers and silently matches nothing | Informational | B2 | `scripts/lib/dev-cycle-read.sh:906`, `:913` | High |
| 4 | import_readers accepts an empty ROOT_REAL and memoizes another worktree as the first root (unreachable from the walks) | Informational | B1 / B6 | `scripts/lib/dev-cycle-read.sh:899`, `:904-905`, `:909` | High |

## Overall Assessment

The branch's new mechanism holds up in this pass. Registry and caller roots only add names, and they withhold only dot spellings that truthrule refuses. Malformed roots and homes fail closed, including a symlink to `/`, which was newly executed. The memo gives one reader set per decision, and the parser's fallback is unreachable inside a walk. Iterations 1-2's security items stay fixed: A1, A2 and B1 hold, and test 4 now pins the caller-root route and the truthrule coupling. No regression from main was found.

Finding 1 is a pre-existing gap: start files that exist only in another checkout. The branch makes it more visible, because its comment now claims sessions in any checkout are modelled. It is Medium under the floor rule, since an honest `CLAUDE.local.md` in a sibling worktree is enough, but there is no exposure today. The fix is in place, in text: reword `:689-690`, add the case to the "Not covered" list, and record a Defer row to U2b3b beside the ancestor case that the fact-check already escalated. Findings 2-4 are Informational forward notes. The single most important action is to correct the "any checkout is modelled" sentence before U2c and U2b3b build on it. This pass found no other findings in the code paths it read; two endorsement claims rest on executed runs and one rests on read-static evidence, and the three routed claims await execution verification by code-fact-check.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to /workspace/.claude/wt-build-loop-u2b3a/docs/reviews/security-review-2026-10-08-u2b3a-final.md, structured per the security-reviewer skill, with `Commit: 3d2d8c44` as its first line.
- Answered: yes
- Out of scope: U2b3b (outside-repo starts, the settings line, the host alias), U2c (the floor's caller), settled override rows (425, 431, 432, 437, 477 and this branch's nine rows, not re-flagged), hostile registry rewrites (Q-103), and the fact-check's figure and wording points.
- Escalate: Finding 1. It is Medium, pre-existing, with no exposure today. It needs either the comment fix plus a Defer row to U2b3b, or a decision that sibling-checkout starts are a named exception. It is the same mechanism as fact-check escalation 2, extended from the ancestor checkout to siblings. Fact-check escalation 1 (empty ROOT_REAL) has a security disposition: Informational and unreachable (Finding 4).
- Decisions I made: rated Finding 1 Medium under the skill's floor rule (honest actions suffice) and not as a regression, since main's lib gives the same answers. Rated Finding 2 Informational because adding such an import needs a reviewed merge (floor refuses start and imported files), so a self-merge cannot reach it. Did not re-run iteration 2's nine nesting shapes; I relied on the U2b3a tests (8/8 at HEAD) and re-read the dotnest/truthrule identity against HEAD's lines.
