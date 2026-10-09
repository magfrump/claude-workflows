Commit: 5516c6e6

# Security Review: feat/build-loop-u2b3a (U2b3a reader roots and homes)

**Scope:** branch diff `git diff main...HEAD` (e50aab35..5516c6e6): `scripts/lib/dev-cycle-read.sh`, `test/scripts/build-loop-check.bats`
**Date:** 2026-10-08
**Based on:** `docs/reviews/code-fact-check-report.md` (Commit 5516c6e6; 0 Incorrect, 1 Stale, 3 Mostly accurate), shared brief `u2b3a-i1/shared.md`, override rows 425, 431, 432, 437, 477
**Threat model (from the brief):** loops are honest. A hostile loop that rewrites git state shared across worktrees is the named Q-103 residual. The walks must fail closed: when a walk fails, every path reads as imported.

Probe scripts and logs are in the session scratchpad (`u2b3a-sec-p1.sh`/`.log`, `u2b3a-sec-p2.sh`/`.log`). Each probe ran `set -eu` with its own `mktemp -d /tmp/u2b3a-sec-XXXX` and checked `pwd -P` before running `git init`, `commit` or `worktree add`. The probes only read `/workspace`.

## Trust Boundary Map

```
B1 (new):   [git worktree registry, shared common dir]  → [reader_set: nul_list, /*, newline, "/" checks]   → [IMPORT_ROOTS → awk pre[] longest-root projection]
B2 (new):   [caller env IMPORT_READER_ROOTS / _HOMES]    → [reader_set: mapfile, blank skip, /*, "/" checks] → [IMPORT_ROOTS / IMPORT_HOMES]
B3 (moved): [HOME env / passwd entry]                    → [import_home, now called inside reader_set]      → [homes[1] exit-4 rule, ~/ joins]
B4:         [instruction-file text: checkout file or main blob] → [awk emit/put: resolve, keep, project]     → [printed names → isimported → truthwalk → floor]
B5:         [walk cache globals IMPORTED_DONE / IMPORTED_MAIN_DONE] → [key compare after reader_set]         → [cached walk result reused]
```

Input-source classification:

```
S1: git worktree list --porcelain -z   — runtime-mutable (any session sharing the common dir, plus stale prunable
                                          entries) — trusted to EXIST as listed (honest loops), UNTRUSTED as a shape
                                          for the projection sink: an honest entry can sit anywhere, including at a
                                          non-dot path inside another root (Finding 1); hostile rewrites are Q-103
S2: IMPORT_READER_ROOTS / _HOMES       — request-time (the --check caller's inherited env; U2b3b's settings line
                                          will set it) — trusted for adding names; UNTRUSTED toward the projection
                                          sink, since a nested root removes names (Finding 1). build-loop.sh does not
                                          scrub or log it (checkout_gate scans only git's local env vars)
S3: HOME / passwd                      — request-time — trusted for joins; a relative or empty value fails closed
                                          (exit 4); a newline in it fails the walk closed
S4: instruction-file text              — branch-writable — UNTRUSTED (all sinks); the parser treats it as data only
S5: ROOT_REAL                          — caller-set, checked by need_root (equals pwd -P, holds .git) — trusted
```

What enters from outside: B1 and B2 are new. They decide the set of prefixes (`pre[]`) a resolved name must lie under, and the root it is printed relative to. Until now that set was ROOT_REAL alone. The diff assumes that every root nested inside another sits under a dot directory (`reader_set`'s comment at `:838-840`). Nothing enforces this, and it is the assumption that breaks.

## Findings

#### 1. Longest-root projection drops a main path below a root registered at a non-dot path (fail-open, regression from main)

**Severity:** Medium
**Location:** `scripts/lib/dev-cycle-read.sh:733-735` (projection), `:857-866` (reader_set accepts the nested root), `:838-840` (the unenforced "honest ones nest only under .claude/" assumption)
**Boundary:** B1, B2 → B4
**Move:** 11 (enumerate bypasses), 2 (implicit sanitization assumption)
**Confidence:** High for the mechanism (executed). Medium for reachability: it needs a registry entry or caller root at a non-dot path inside another root. /workspace has none today (22 nested entries, all under `.claude/`).
**Legibility-target:** for-orchestrator-synthesis
**Rests on Q-103?** No. The executed case is an honest `git worktree add sub` followed by `rm -rf sub` without `git worktree prune`. That leaves a prunable entry, and reader_set includes prunable entries on purpose (`:831`). The same mechanism fires from a live honest worktree at a non-dot path, from a misconfigured `IMPORT_READER_ROOTS`, and from a caller root that is a symlink into the repo.

Evidence (verbatim):

```awk
# scripts/lib/dev-cycle-read.sh:733-735
  k = 0; for (i = 1; i <= nr; i++) if (index(out, pre[i]) == 1 && length(out) > length(pre[i]) && length(pre[i]) > k) k = length(pre[i])
  if (!k) return
  out = substr(out, k + 1)
```
(excerpt ends :735; enclosing put() continues to :740 (the seen/budget/print lines). Read in full: the name is printed once, relative to the longest root only.)

```bash
# scripts/lib/dev-cycle-read.sh:857, :863-864
  rs_r=("$ROOT_REAL"); for p in "${rs_l[@]}"; do [[ "$p" != "worktree "* ]] || rs_r+=("${p#worktree }"); done
    [[ "$p" == /* && "$p" != *$'\n'* && -n "${p//\//}" ]] || return 1
    r="$(realpath -m -- "$p")" && [[ -n "${r//\//}" ]] || return 1
```
(excerpt ends :864; enclosing reader_set() continues to :879. Read in full: no check compares one root against another.)

```
# scripts/lib/dev-cycle-read.sh:838-840
# The parser prints a name relative to the longest root holding it, so a root
# nested in another takes the names below it: the honest ones nest only under
# .claude/ (a dot path the floor refuses whole), ...
```

Mechanism: main's `AGENTS.md` holds `@/<repo>/sub/x.md`. The resolved name lies under both ROOT_REAL and a registered root `<repo>/sub`. The longer root wins, so the parser prints `x.md`, and `sub/x.md` (the path main stores, and the file a session reads once no worktree occupies `sub/`) is never printed. `isimported main sub/x.md` then answers not-imported. truthwalk (`:1184-1188`) passes that answer on, so `floor` lets a branch change `sub/x.md`. truthrule gives no other refusal for that path (`:1167-1177`). Relative names are unaffected, because the every-root pass also resolves them against the nested root (`<repo>/sub/sub/y.md` projects to `sub/y.md`). Absolute names and `~/` names have no such second spelling.

Executed (`u2b3a-sec-p1.log`, throwaway repo):

```
registry:
worktree /tmp/u2b3a-sec-Zd9D/repo
worktree /tmp/u2b3a-sec-Zd9D/repo/sub
prunable gitdir file points to non-existent location
A stale non-dot registry entry, main lib:
  tree sub/x.md: imported
  main sub/x.md: imported
A stale non-dot registry entry, HEAD lib:
  tree sub/x.md: -
  tree sub/y.md: imported
  main sub/x.md: -
  main sub/y.md: imported
B caller root /tmp/u2b3a-sec-Zd9D/repo/sub, HEAD lib:
  main sub/x.md: -
C caller root via symlink into repo, HEAD lib:
  main sub/x.md: -
```

Main's lib imports `sub/x.md`. HEAD drops it in both walks. So the diff turns a correct answer into a fail-open. The commit chose longest-root projection over every-root to avoid a 37x output cost (fact-check Claims 17, 23). That reasoning holds for `.claude/` nesting, where the dropped outer spelling is a dot path the floor refuses whole. It does not hold for a nested root at a non-dot path. The comment states the dot-path condition as a property of honest loops, but nothing enforces it.

**Recommendation:** Fail closed in reader_set. After the lists are built, `return 1` when any root lies strictly below another root and the first component of the remainder does not start with `.` (compare the realpath forms and the spelled forms alike). This keeps the cheap longest-root projection where it is sound. The alternative is for `put` to also print the name relative to each containing root whose remainder's first component is not a dot, which also costs nothing for `.claude/` nesting. Add a test with a pruned-by-`rm -rf` worktree at `sub/` and an absolute import of `sub/x.md`, run on both walks. Also reword `:838-840` from a claim about honest loops into the rule the code enforces.

#### 2. import_targets outside a walk can use a stale root list (unreachable from scripts/)

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:884`, `:878`
**Boundary:** B1, B2 → B4
**Move:** 4 (TOCTOU, cached check)
**Confidence:** High (fact-check Claim 4, executed)
**Legibility-target:** for-author

```bash
# scripts/lib/dev-cycle-read.sh:884
  [[ "$IMPORT_READERS_FOR" != "${ROOT_REAL:-}"$'\n'"$IMPORT_HOME_DONE" ]] || { roots="$IMPORT_ROOTS"; homes="$IMPORT_HOMES"; }
```

`IMPORT_READERS_FOR` records ROOT_REAL and HOME only. If import_targets is called on its own after a walk, it uses the old roots even though `IMPORT_READER_ROOTS` or the registry has changed since. A newly registered nested root would then be missing, and the names it should take would project under the outer root instead. Today the cache compares fail toward imported here, because a missing nested root prints the outer spelling. A dropped name happens only when a root has been removed and its spelling is still in the stale list. The only callers in `scripts/` are the two walks (`:1018`, `:1093`, `:1095`), and each calls reader_set first in the same shell (`:1000`, `:1050`), so no production path reaches this.

**Recommendation:** None needed for the gate. Optionally, add `IMPORT_READER_ROOTS`/`_HOMES` to `IMPORT_READERS_FOR`, or note on import_targets that its lists are only as fresh as the last reader_set call.

#### 3. Fail-closed over-refusals and an asymmetric "/" check on caller homes

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:869-874`
**Boundary:** B2, B3
**Move:** 3 (error path)
**Confidence:** High (fact-check Claim 18, executed)
**Legibility-target:** for-author

```bash
# scripts/lib/dev-cycle-read.sh:869-874
    if [[ $i -ge 2 ]]; then
      [[ -n "$p" ]] || continue
      [[ "$p" == /* && -n "${p//\//}" ]] || return 1
    fi
    [[ "$p" != *$'\n'* ]] || return 1
    r="$p"; [[ $i -lt 2 ]] || r="$(realpath -m -- "$p")" || return 1
```

If HOME holds a newline, both walks now fail even when no `~/` name exists. A caller home of `/x/..` is accepted (its realpath is `/`), while a literal `/` is refused. Neither is a fail-open. Homes are joined, not prefix-matched, so a home of `/` only adds names (`~/workspace/docs/x.md` → `/workspace/docs/x.md`, kept as a superset). The newline refusal fails closed. These are availability and consistency points only. The fact-check escalation is answered here: the change is fail-closed and has no security impact.

**Recommendation:** Optional. Either drop the "/ alone" refusal for homes (it protects nothing) or apply it after realpath as roots do, and word the comment to match.

## Untested bypass candidates

- **Case-insensitive host spelling of a root** (for example `@/Users/X/claude-workflows/...` against a root spelled `/users/x/...` on a macOS host, U2b3b's territory). `index(out, pre[i])` is case-sensitive, so the name would be dropped. Not tested: the probe host is Linux, and this falls in the stated case-insensitive exception (override-log line 350).
- **Unicode-normalization variants of a host root path** (NFC vs NFD on macOS). Not tested, for the same reason.
- **A registry change during a walk** (another honest session runs `git worktree add` or `remove` between reader_set and the parser runs). Reasoned only. reader_set reads the registry once per walk and the next gate decision recomputes it (the key holds the roots, `:1002`, `:1051`). A root added mid-walk can only drop a name by nesting at a non-dot path, which is Finding 1's mechanism. A root removed mid-walk adds names.

## Endorsement Claims

- **Claim:** Each new reader_set failure (import_home, a failed `git worktree list`, a relative, newline-holding or `/` root, a relative or `/` caller home, a newline home) makes both walks return 1 with their result set to `error`, and isimported then answers imported.
  **Location:** `scripts/lib/dev-cycle-read.sh:1000`, `:1050`, `:1144-1153`
  **Evidence:** executed
  **Verified:** U2b3a tests 4 and 5 pass on HEAD and fail on main (fact-check Claims 24, 25). Each `want walk failed` case also checks `docs/other.md imported`. `reader_set || { IMPORTED_DONE=""; IMPORTED=error; return 1; }` read in full.
  **Not verified:** the floor's wording for a reader_set failure through truthwalk (`:1185-1186`). It is read, not run with a failing reader_set.
  **route: code-fact-check**

- **Claim:** The walk cache keys cannot collide across distinct (roots, homes) pairs. IMPORT_ROOTS never holds an empty line, so the first `\n\n` in the key is the separator.
  **Location:** `scripts/lib/dev-cycle-read.sh:862-863`, `:877`, `:1002-1003`, `:1051-1052`
  **Evidence:** read-static
  **Verified:** blank caller roots are skipped (`:862`), index 0 must match `/*` (`:863`), worktree records are `worktree <path>` with a non-empty path, and `$(printf ...)` strips trailing newlines from IMPORT_ROOTS.
  **Not verified:** a run that builds two (roots, homes) pairs differing only in where an empty own-home line falls and compares their keys.
  **route: code-fact-check**

- **Claim:** A relative import of a non-dot repo path P is still printed as P when a registered root is nested at P's leading component, because the every-root pass resolves it against the nested root too.
  **Location:** `scripts/lib/dev-cycle-read.sh:713`
  **Evidence:** executed
  **Verified:** `u2b3a-sec-p1.log`: `@sub/y.md` reads `imported` in both walks under the stale nested root `sub/`, with main's lib and with HEAD.
  **Not verified:** two levels of non-dot nesting (a root nested inside a nested root at the same subpath).
  **route: code-fact-check**

- **Claim:** The every-root parser keeps more than 100x headroom under IMPORT_WORK_MAX over /workspace's 24 worktrees, so the added work cannot exhaust the budget there.
  **Location:** `scripts/lib/dev-cycle-read.sh:713`, `:718`, `:628`
  **Evidence:** executed
  **Verified:** `u2b3a-sec-p2.log`: HEAD's walks pass at IMPORT_WORK_MAX=500000 and fail at 250000 (main's lib passes at 250000), against the default of 50000000.
  **Not verified:** the per-file bound for one large instruction file at the default wmax with many roots.

## Primitive sweep

Primitive: path join and lexical resolution (the name a walk keeps or drops)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/lib/dev-cycle-read.sh:707` (`~/` join per home) | S3, S2, S4 | exit 4 on a non-absolute `homes[1]`; reader_set's home checks | cleared: additive per home; Finding 3 (consistency only) |
| `scripts/lib/dev-cycle-read.sh:710` (absolute name) | S4 | projection at `:733` | Finding 1 (nested non-dot root drops it) |
| `scripts/lib/dev-cycle-read.sh:713` (relative name per root and directory) | S4, S1, S2 | projection at `:733` | cleared for non-dot P (executed, endorsement 3) |
| `scripts/lib/dev-cycle-read.sh:733-735` (longest-root projection) | S1, S2, S5 | none between roots | Finding 1 |
| `scripts/lib/dev-cycle-read.sh:864` (`realpath -m` of a root) | S1, S2 | `/` refused after realpath | cleared; also the path by which a symlinked caller root lands inside the repo (Finding 1, case C) |
| `scripts/lib/dev-cycle-read.sh:874` (`realpath -m` of a caller home) | S2 | `/` checked on the spelling only | Finding 3 |

Primitive: process exec

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/lib/dev-cycle-read.sh:856` (`git worktree list --porcelain -z`) | S5 (cwd) | fixed argv; nul_list fails on a nonzero exit or unterminated output; need_root pins the cwd | cleared: no injected argument, fails closed (test 4's shim) |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Longest-root projection drops a main path below a root registered at a non-dot path (fail-open, regression) | Medium | B1, B2 → B4 | `scripts/lib/dev-cycle-read.sh:733-735`, `:857-866`, `:838-840` | High (mechanism), Medium (reachability) |
| 2 | import_targets outside a walk can use a stale root list (unreachable from scripts/) | Informational | B1, B2 → B4 | `scripts/lib/dev-cycle-read.sh:884` | High |
| 3 | Fail-closed over-refusals (HOME newline) and an asymmetric "/" check on caller homes | Informational | B2, B3 | `scripts/lib/dev-cycle-read.sh:869-874` | High |

## Overall Assessment

The unit does what row 425/432/437 asked. Absolute names into other worktrees, relative names re-entering sibling and nested worktrees, and the caller's host roots and homes are now modelled. Every new failure in reader_set fails both walks closed, the cache keys hold the reader set, and the work budget keeps wide headroom. One real fail-open was found, in the longest-root projection, and it rests on an assumption rather than a check. A root nested at a non-dot path inside another root takes the absolute and `~/` names below it. The executed honest case is a worktree removed with `rm -rf`, whose prunable entry stays in the registry. A misconfigured or symlinked `IMPORT_READER_ROOTS` does the same, and it does not rest on Q-103. Main's lib imports the path that HEAD drops, so this is a regression. It can be fixed in place: refuse such nesting in reader_set (fail closed), or print the extra spelling only for non-dot nesting. Addressing Finding 1 is the most important thing to do before merge. With no other findings within the code paths read, the endorsement claims marked `route: code-fact-check` are pending execution verification.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to /workspace/.claude/wt-build-loop-u2b3a/docs/reviews/security-review-2026-10-08-u2b3a.md, structured per the security-reviewer skill, with `Commit: 5516c6e6` as its first line.
- Answered: yes
- Out of scope: outside-repo starts and the host settings line (override rows 431, 477; U2b3b), not re-flagged; hostile registry rewrites (Q-103 residual, named in reader_set's comment), not filed; performance and wording points the fact-check already carries (Claims 5, 9, 18, 22b, 22c).
- Escalate: Finding 1 is a fail-open regression from main with honest inputs (a stale prunable worktree entry at a non-dot path); the fix and its test belong in this unit, not U2b3b. Also: `IMPORT_READER_ROOTS`/`_HOMES` are the first inherited env inputs that can remove names (until Finding 1 is fixed), and build-loop.sh neither scrubs nor logs them; U2b3b's settings line should set them explicitly rather than inherit them.
- Decisions I made: scored Finding 1 Medium under the floor rule (concrete mechanism, reachable with honest inputs), with reachability carried in Confidence; folded the env-source point into Finding 1 and the Escalate line rather than filing it separately, since fixing Finding 1 leaves a caller root able only to add names.
