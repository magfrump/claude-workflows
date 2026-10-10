Commit: 1c820663

# Security Review — feat/build-loop-u2b3b2b (iteration 1)

**Scope:** `git diff main...HEAD` (5 files): `scripts/lib/dev-cycle-read.sh` (`outside_seeds`, `outside_proj`, `MANAGED_DIR`, both walks' seed hooks, walk header), the test fixtures, and the plan paragraph. Enclosing code read in full: `imported_names`, `main_imports`, `import_outside`, `import_file`, `outside_ok`, `import_readers`, `import_targets`, IMPORT_AWK's `put`/`emit`, `nul_list`, `need_root`, `blocker`/`inrepo_here`, the gate caller contract (lib header items 1-9).
**Date:** 2026-10-09
**Based on:** shared brief `u2b3b2b-i1/shared.md`. The code-fact-check runs in parallel and was not available to this review.

> **No code fact-check report provided.** Claims about security properties in comments and documentation have not been independently verified by a fact-check. This review read the code and ran probes against it (below).

Probe harness: `/tmp/claude-1000/-workspace/7705a73b-d526-48c8-9948-70a1335d5801/scratchpad/u2b3b2b-sec-probe1.sh` (sources the branch lib in throwaway repos under `/tmp/u2b3b2b-sec-*`, `HOME` in the temp dir, `CLAUDE_CONFIG_DIR` unset, `MANAGED_DIR=/nonexistent/managed`, `LC_ALL=C`; same shape as the suite's `imps`).

## Trust Boundary Map

The floor fails open when a walk misses a file a session loads as instructions: a self-merge can then change a main file that file imports. Missing a seed is the fail-open direction. Extra seeds, and walk failures, push toward refusing (fail-closed).

```
B1 (new): [other reader roots' working trees (find -P)]   → [isstart + same-bytes skip + outside_ok] → [walk seeds (C1)]
B2 (new): [config dirs: homes' .claude, $CLAUDE_CONFIG_DIR, MANAGED_DIR, ancestors] → [find -L / find -H -xtype f + isstart] → [walk seeds]
B3 (new): [installed_plugins.json]                        → [python3 -I json parse, abs+dir guard]   → [find -L argv (plugin dirs)]
B4 (new): [// names the parser prints from file text]     → [outside_ok reject → realpath -m]       → [IMPORT_WHOLE projection into OUT]
B5:       [a seed's text in the walk]                       → [parser: relative names resolve to repo paths] → [main's blob / ROOT_REAL checkout read, not the seed's own root]
```

Input-source classification:

```
S1: other worktrees' files (loop worktrees, /workspace main checkout) — request-time (a loop writes its own worktree at will)
      — UNTRUSTED for exec/argv/read-blocking sinks; for the floor's purpose, a loop's own imports only add refusals,
        so S1 is trusted-toward-fail-closed and untrusted toward availability (a loop can fail or stall every walk)
S2: ~/.claude, $CLAUDE_CONFIG_DIR, /etc/claude-code, ancestor dirs — runtime-mutable (same uid as loops)
      — hostile rewrite is the Q-103 residual (out of scope); honest content is the fail-open concern
S3: installed_plugins.json — runtime-mutable (same uid) — UNTRUSTED for argv construction (find), parse (python3)
S4: CLAUDE_CONFIG_DIR / HOME env of the gate process — deploy-time for the gate's caller — trusted for availability;
      env only adds config dirs (HOME also selects ~/.claude; pre-existing)
S5: worktree registry (IMPORT_ROOTS) — runtime-mutable (Q-103 residual) — roots are checked absolute before reaching find argv
S6: // names from parsed file text — request-time (any seed's text) — UNTRUSTED for realpath argv
S7: MANAGED_DIR constant — code-constant — trusted
```

The diff adds the gate's first reads of other worktrees' files (B1) and of the user's config tree (B2, B3). Those reads go through `find`, `realpath`, `sha1sum` and `python3` with paths from S1-S6. Argument construction holds: every path reaching those argv is absolute or follows `--`. The open gaps are omissions: files a session in another root loads that the seed rules never list.

## Findings

#### F1. C1 reads another root's start files, but resolves their imports to main's or ROOT_REAL's copy, never to that root's own copy; a divergent intermediate file in that root is never read

**Severity:** Medium
**Location:** `scripts/lib/dev-cycle-read.sh:1264-1282` (C1 listing), with `1405-1414` (tree walk) and `1520-1530` (main walk) consuming the seed's output
**Boundary:** B1, B5
**Move:** 2 (implicit assumption), 5 (invert the model)
**Confidence:** High (executed)
**Legibility-target:** walk header (lines 744-752) and the `outside_seeds` comment (lines 1199-1214)

The seed text for C1 is read from the other root W. Each relative name it yields then prints repo-relative, and the walks read *main's blob* (main walk) or *ROOT_REAL's checkout* (tree walk) at that path. Neither walk reads W's copy. So the chain stops at any file W holds differently: an untracked or ignored non-start file in W, or a tracked one W's branch changed. That is the same class of gap C1 exists to close (a session in W loads W's files), one hop further in. The removed parser exception ("a start file only another reader root's checkout holds") is not replaced by a named exception for this case.

Evidence (executed, both walks, `walk: ok`):
```
== P1: other worktree's untracked non-start file imported by its CLAUDE.local.md, importing a main file
walk: ok
docs/notes.md: imported
docs/bar.md: -
== P2: other worktree's tracked non-start file modified there (differs from main), importing a main file
walk: ok
docs/foo.md: imported
docs/bar.md: -
```
(P1: W/CLAUDE.local.md `see @docs/notes.md`, W/docs/notes.md untracked `and @docs/bar.md`. P2: main's AGENTS.md `@docs/foo.md`, W's modified docs/foo.md `now @docs/bar.md`.)

Attack: a session in /workspace's main checkout (on a feature branch, as other sessions leave it) loads CLAUDE.md, then an edited docs/foo.md, then docs/bar.md. A loop self-merges a change to main's docs/bar.md, which the floor passes. The text reaches that session's instructions once its checkout takes main.

**Recommendation:** Pick one: read an imported repo path from every root that holds a copy differing from ROOT_REAL's (the same `find`/`sha1sum` comparison C1 already uses), or name this case as an exception in the walk header beside the C1 one. Either way, add P1/P2 as tests.

#### F2. C1's `find -P` does not descend a symlinked directory in another root: a symlinked `.claude/rules` (or a linked subtree holding a nested CLAUDE.md) is silently skipped

**Severity:** Medium
**Location:** `scripts/lib/dev-cycle-read.sh:1264`
**Boundary:** B1
**Move:** 11 (bypasses of the listing guard), 3 (asymmetric error path)
**Confidence:** High (executed); Medium that the configuration occurs honestly (Claude Code documents symlinked rules directories for sharing rules across projects)
**Legibility-target:** `outside_seeds` comment, line 1210 ("Roots are listed from the file system (find -P, .git pruned)")

Evidence:
```
nul_list fl find -P "$r" -name .git -prune -o '(' -type f -o -type l ')' -iname '*.md' -printf '%P\0' || return 1
```
```
== P3: other worktree's .claude/rules is a symlink to a directory (Claude Code follows symlinked rules)
walk: ok
docs/bar.md: -
-- control: a symlinked rules FILE
walk: ok
docs/bar.md: imported
== P4: a symlinked directory holding a nested CLAUDE.md in another worktree
walk: ok
docs/bar.md: -
```
The walks treat the two cases unequally. In ROOT_REAL, a link at `.claude/rules` *fails* the main walk (`START_LINK`, fail-closed). In another root the same link is *skipped* and the walk reports ok (fail-open). The config-dir listing (B2) uses `find -L` for exactly this reason ("the user's skills link into /opt"). A5's "start files under a symlinked directory" exception is stated for the gate's own checkout. The comment does not extend it to C1.

**Recommendation:** List other roots with `find -L`, or at least follow links at and below `.claude/` start directories. If loops are a risk (B1 is loop-writable), fail closed on a link to a directory there, as START_LINK does for ROOT_REAL. Otherwise, name this exception in the header.

#### F3. Any unlistable directory or symlink loop in any other worktree, or in a config dir's linked trees, fails every walk: one loop can block all self-merges

**Severity:** Low
**Location:** `scripts/lib/dev-cycle-read.sh:1247-1250, 1256, 1264`
**Boundary:** B1, B2
**Move:** 8 (what if there are a million of these), 3 (error path)
**Confidence:** High (executed)
**Legibility-target:** walk header, the "Named exceptions" sentence (line 748: "an ancestor or config dir find cannot list, which fails the walk")

Evidence:
```
== P5: an unreadable directory anywhere in another worktree (a loop's) fails every walk
find: '/tmp/u2b3b2b-sec-hOI7/p5side/junk/locked': Permission denied
walk: failed
docs/unrelated.md: imported
== P6: symlink loop under ~/.claude/skills (find -L)
find: File system loop detected; ...
walk: failed
```
This is fail-closed and the right direction for the floor. The new risk is availability: before this unit a loop's worktree could not affect another loop's gate decision. Now `mkdir x && chmod 000 x` in any registered worktree, or an honest root-owned build directory, refuses every self-merge repo-wide. The header names only "an ancestor or config dir". It does not name another root's subtree, which is the broader and loop-writable case. A FIFO swapped in after `outside_ok` (line 1277) also stalls `sha1sum` at line 1280, a new spot for the existing FIFO-stall exception.

**Recommendation:** Name "any directory in another root that find cannot list" in the header's exceptions. Consider making the floor's refusal say *which* root failed, so an operator can find the blocking worktree.

#### F4. Same-bytes skip assumes ROOT_REAL's copy is a walk start; an untracked nested repo in ROOT_REAL breaks that

**Severity:** Low
**Location:** `scripts/lib/dev-cycle-read.sh:1270-1282`
**Boundary:** B1
**Move:** 2 (implicit assumption)
**Confidence:** Medium. It is reachable only when the gate's checkout holds an untracked nested repository, which contract item 2's "clean worktree at MAIN_SHA" likely excludes; that depends on checkout_gate's clean test, which this review did not read.
**Legibility-target:** the comment at lines 1270-1274 ("the walks read that file as a start already")

Evidence:
```
if [[ -n "$q" && -f "$d" ]] && isstart "${lo[i]:${#lo[i]}-${#d}}" && outside_ok "${abs[i]}"; then sp+=(...); ...
```
```
== P8: nested untracked repo in ROOT_REAL with same-bytes copy in other worktree
walk: ok
docs/bar.md: -
-- control: other worktree's copy differs
walk: ok
docs/bar.md: imported
```
`-f "$d"` tests that the file *exists* in ROOT_REAL. It does not test that a walk *starts* there. Git does not list files inside a nested repo, so neither walk starts at ROOT_REAL's `sub/CLAUDE.md`, and the skip then also drops W's identical copy. The tree walk has the same assumption for a ROOT_REAL copy that `inrepo_here` refuses (a symlink); the header's "checkout that is not clean" exception covers that case.

**Recommendation:** Skip only when ROOT_REAL's copy is in the walk's own start set (the tree walk's `seen`, or the main walk's `ent`/`tq`). Or state the nested-repo case in the comment.

#### F5. python3's traceback reaches the walk's stderr when installed_plugins.json has another schema

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:1240-1246`
**Boundary:** B3
**Move:** 7 (serialization boundary)
**Confidence:** High (executed)
**Legibility-target:** the plugin comment at lines 1237-1239

Evidence (schema v1, `plugins` values as objects):
```
TypeError: string indices must be integers, not 'str'
walk: ok
docs/o.md: imported
```
The fallback works: the whole cache is seeded. But the stderr text gets through, and the suite's own tests assert `[ -z "$stderr" ]` on honest walks. No security effect. Route it to `2>/dev/null` on the python3 call, or note it.

### Untested bypass candidates

- A session whose `CLAUDE_CONFIG_DIR` differs from the gate process's (for example, a host session started with a custom config dir). Not tested: the gate reads only its own environment (line 1222), and in cc-isolated `CLAUDE_CONFIG_DIR` equals `$HOME/.claude`. This would sit under the A3 class (a reader this container cannot see).
- Auto memory moved by an `autoMemoryDirectory`-style setting, or `--add-dir` CLAUDE.md loading. Not tested: these depend on Claude Code settings outside the modeled set.
- A TOCTOU swap of an other-root file to a FIFO between `outside_ok` (1277) and `sha1sum` (1280). Traced by reading only. The effect is a stall (fail-closed), covered under F3.

## Endorsement Claims

- **Claim:** An `installPath` from installed_plugins.json reaches `find`'s argv only when it starts with `/` and names an existing directory, so `-exec`/`-delete` style values do not become find expressions.
  **Location:** `scripts/lib/dev-cycle-read.sh:1244`
  **Evidence:** executed
  **Verified:** P7: JSON `{"installPath": "-exec"}, {"installPath": "-delete"}` with a `./-exec` dir present gave `walk: ok` and no find error. Read: `[[ "$d" != /* || ! -d "$d" ]] || pr+=("$d")`.
  **Not verified:** the fallback branch's `${d%/*}/cache` (line 1246), whose `d` comes from `pj` (absolute config dirs), not from JSON.
  **route: code-fact-check**
- **Claim:** The plugin parse runs `python3 -I` with a fixed program and file names as argv only, so neither the JSON content nor the cwd can supply code.
  **Location:** `scripts/lib/dev-cycle-read.sh:1240-1243`
  **Evidence:** read-static
  **Verified:** the program text is a literal; `-I` drops PYTHON* env, user site and the script dir/cwd from sys.path; `json.load` builds plain types.
  **Not verified:** the python3 binary resolved from PATH (the gate caller's PATH).
- **Claim:** A failed `find` in any seed listing fails both walks, and `isimported` then answers imported.
  **Location:** `scripts/lib/dev-cycle-read.sh:1247-1264, 1392, 1473`
  **Evidence:** executed
  **Verified:** P5 (mode-000 dir in another worktree) and P6 (symlink loop under `~/.claude/skills`): `walk: failed`, `docs/unrelated.md: imported` for tree and main.
  **Not verified:** a `find` that exits 0 after a partial listing (`nul_list` requires a trailing `rc=0`; a find that drops entries without error was not constructed).
  **route: code-fact-check**
- **Claim:** The C1 same-bytes skip reads another root's start file when its bytes differ from ROOT_REAL's copy.
  **Location:** `scripts/lib/dev-cycle-read.sh:1277-1282`
  **Evidence:** executed
  **Verified:** P8 control (one trailing space of difference): `docs/bar.md: imported` in both walks.
  **Not verified:** a root whose innermost-root `q` differs from the listing root `r` (nested non-ROOT_REAL roots).
- Scoped prose: every path passed to `realpath`/`sha1sum`/`find` in the new code is absolute or follows `--` (lines 1191, 1256-1264, 1280). Roots and config dirs are checked `/*` first (import_readers line 1084; `outside_seeds` 1221-1222). Read-static.

## Primitive sweep

Primitive: process exec with path arguments (argv option injection / blocking reads)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `dev-cycle-read.sh:1191` realpath -mz (outside_proj) | S6 | `--`, names start `/` | cleared; newline real path returns 1 (1192) |
| `dev-cycle-read.sh:1240` python3 -I | S3 | fixed program, `-I` | cleared (endorsement) |
| `dev-cycle-read.sh:1247` find -L rules | S2 | dirs absolute | F3 (fail-closed availability) |
| `dev-cycle-read.sh:1248` find -L prompts/plugins | S2, S3 | abs + `-d` guard on installPath | cleared for argv; F3 for loops |
| `dev-cycle-read.sh:1250` find -L projects | S2 | absolute | cleared |
| `dev-cycle-read.sh:1256` find -H tops -xtype f | S2, S5 | absolute | cleared; F3 |
| `dev-cycle-read.sh:1258` realpath -mz roots | S5 | absolute checked in import_readers | cleared |
| `dev-cycle-read.sh:1264` find -P other roots | S1, S5 | absolute; never git -C | F2 (links), F3 (availability) |
| `dev-cycle-read.sh:1280` sha1sum -z | S1 | `--`; `outside_ok` before | F3 (FIFO TOCTOU stall); F4 (skip premise) |
| `dev-cycle-read.sh:1201` import_targets IMPORT_WHOLE (outside_proj) | S6 | work budget passed | cleared |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | C1 seed's imports read main's/ROOT_REAL's copy, not the other root's divergent intermediate file | Medium | B1, B5 | `dev-cycle-read.sh:1264-1282` | High |
| 2 | find -P skips symlinked dirs (e.g. `.claude/rules`) in other roots; ROOT_REAL fails closed on the same | Medium | B1 | `dev-cycle-read.sh:1264` | High |
| 3 | Any unlistable dir/loop in any worktree fails every walk (loop-triggered DoS of all self-merges) | Low | B1, B2 | `dev-cycle-read.sh:1247-1264` | High |
| 4 | Same-bytes skip assumes ROOT_REAL's copy is a start (nested untracked repo) | Low | B1 | `dev-cycle-read.sh:1270-1282` | Medium |
| 5 | python3 traceback on stderr on another JSON schema | Informational | B3 | `dev-cycle-read.sh:1240-1246` | High |

## Overall Assessment

No code execution or argv-injection surface was found in the new reads. Plugin paths are filtered to absolute directories. python3 runs isolated. Every path reaches find, realpath and sha1sum absolute or after `--`. Listing failures fail both walks closed. The two Medium findings are fail-open omissions in C1. Both follow from C1's premise (a session in another root loads that root's own files) applied only partly: F1, one import hop past the start file; F2, through a directory link that `find -P` will not follow. Neither needs a hostile actor: an honest edit or a symlinked rules dir in /workspace's main checkout is enough. Both can be fixed in place, or named as exceptions in the header. F1 matters most because it is the natural next step of the threat C1 targets. No findings within the code paths read beyond these; endorsement claims marked `route: code-fact-check` are pending execution verification.

## Goal-Alignment Note

The unit's goal: make both walks start at every outside instruction file a session loads, so the floor stops failing open on imports from the user's config tree, ancestors and other worktrees. The config-dir, ancestor, plugin and `outside_proj` parts meet that goal as probed. C1 meets it for start files only. F1 and F2 are the remaining fail-open paths inside C1's own threat model. Fix them, or name them in the walk header before this unit lands. F3-F5 do not block the goal. F3 is worth a sentence in the header, because this unit creates a cross-worktree availability coupling that did not exist before.
