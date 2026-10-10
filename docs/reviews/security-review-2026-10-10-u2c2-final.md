Commit: 8786f8fc

# Security Review — feat/build-loop-u2c2 final confirming pass (U2c2, the walk side)

**Scope:** full branch, `git diff main...HEAD -- scripts test` (3111ee9d, 07af69c0, 2be3db37). Functions read whole: floor, walk_why, walk_has, truthwalk, isimported, truthrule, readers_root, import_reset, import_home, import_readers(_key), main_imports, imported_names, outside_seeds, config_seeds, c1_seeds, root_copies, prompt_marks, import_outside, outside_proj, main_checkout, need_root; `scripts/build-loop.sh` srules, check_line, the dispatch at :860-875, and check_fix in `scripts/dev-cycle.sh`.
**Date:** 2026-10-10
**Based on:** Stage-1 summary `fc-final-summary.md` (k=3, r1-r3), shared brief `brief-final.md`, my iteration-1 report `docs/reviews/security-review-2026-10-10-u2c2.md`, rubric `docs/reviews/code-review-rubric-2026-10-10-feat-build-loop-u2c2.md` (A1-A17, B1-B7) and the last seven override rows.
**Probes:** `secf-probe1.sh`/`.log` (A-G), `secf-probe2.sh`/`.log` (D, H, I), `secf-bats.sh`/`.log` (11 floor/walk tests, serial, all ok), in `/tmp/claude-1000/-workspace/843b51ad-a12f-4e61-b040-53f5def15aef/scratchpad/u2c2-review/`. Each probe is one `set -eu` script with its own `secf-XXXX` dir, `HOME` inside it, a `pwd` guard before every git init/commit, a worktree removed in-script, and the dir removed at the end.

Threat model: `--check`'s floor must never pass a path that a session would load as instructions (fail-open). Fail-closed over-refusal is acceptable.

## Trust Boundary Map

```
B1: loop branch's merge result (changed paths)      → check_line lower_all → srules → floor($1, $4 lowered) → truthrule / ancestor rule / truthwalk → DENY or pass
B2: main's tree + the gate checkout's files          → readers_root (need_root unless both caches hold) → main_imports → IMPORTED_MAIN / IMPORTED_MAIN_WHY
B3: other worktrees, homes, config dirs              → import_readers (IMPORT_CONFIGS) → config_seeds + c1_seeds → walk queue
B4: live prompt link in another root or a config dir → prompt_marks realpath -e + below-a-root test → prompt marks on projected repo names
B5: IMPORTED_MAIN_WHY PATH (untrusted names)         → walk_why (NAMECHARS or ?) → FLOOR_WHY → deny row → scrub → reader of --check output
B6: environment (CLAUDE_CONFIG_DIR, HOME, cwd)       → import_readers_key / memo → both walks' cache keys
```

| Label | Source | Mutability | Trust classification |
|---|---|---|---|
| S1 | changed paths of the merge | request-time (the loop writes them) | UNTRUSTED for the floor decision and printing (check_line prints `?` outside NAMECHARS) |
| S2 | main's tree names and blobs | runtime-mutable (earlier merges) | UNTRUSTED for printing and parsing; trusted as "what main holds" |
| S3 | names, contents and links in other registered worktrees (the loop's own among them) and homes | runtime-mutable (the loop writes its own worktree) | UNTRUSTED for printing, parsing and path sinks |
| S4 | the gate checkout's untracked .md names | runtime-mutable | UNTRUSTED for printing and parsing |
| S5 | CLAUDE_CONFIG_DIR, HOME, cwd, TMPDIR | deploy-time (the gate caller's environment) | trusted for availability; CLAUDE_CONFIG_DIR checked absolute and newline-free before any path sink |
| S6 | `$4`, lower_all output at the same index as `$1` | derived from S1 in-process | trusted only as lower(S1) |
| S7 | IMPORT_MANAGED_DIR, NAMECHARS, START_LINK, INSTRUCTION_FILE | code-constant | trusted |

Untrusted names enter from S1-S4. Inside the decision they are compared, never executed. Any name that gets printed passes through the NAMECHARS-or-`?` rule (walk_why `:811`, check_line `:842`) and then through scrub. The diff's new decision-side code only refuses (the ancestor rule) or adds reads (prompt_marks' live branch, config-dir keys). The pass-side changes are truthwalk's direct membership test, the readers_root skip and the cache keys. A defect in any of those three could turn a refusal into a pass, so I probed each one by execution.

## Findings

No findings.

I checked every area the task names. None yields a fail-open or a reachable output-channel defect at 8786f8fc. The results follow, so a reader can see what was looked at.

- **readers_root (`:833`).** It skips need_root only when ROOT_REAL is set and import_readers' memo holds a non-empty result for the current key. That key leads with ROOT_REAL and includes HOME's key, both reader lists, IMPORT_READER_WHY, CLAUDE_CONFIG_DIR (set or unset, and its value) and IMPORT_MANAGED_DIR. Every walk still runs need_root below its own cache check (`:1630`, `:1706`), so a checkout read always follows a root check. I executed this from a wrong cwd after one walk (probe D):
  - A double hit answers from ROOT_REAL's cached walk (`docs/a.md` imported, the right answer for that root).
  - A walk-cache miss, a CLAUDE_CONFIG_DIR change and a HOME change each exit 1 with "ROOT_REAL is not the current directory".
  - An unset ROOT_REAL exits 1.
  - From a subdirectory of the root, a walk miss exits 1 (probe H).
  - Changing ROOT_REAL to another repository while keeping the first repository's MAIN_SHA refused through a failed walk (`fatal: not a tree object`, floor returned 0): fail-closed, and a contract item 9 breach anyway.
  - No cached state answered for a root other than ROOT_REAL.
- **walk_has and truthwalk (`:1844-1847`, `:1881-1887`).** The pattern operand is quoted, so it matches literally (probe B):
  - `*`, `docs/a.m?`, `[d]ocs/a.md`, `ocs/a.md`, `docs/a.md/` and `''` all miss.
  - `docs/a.md\nclaude.md` matches two adjacent list entries. That is an over-refusal only: a name holding a newline is never a list entry, so it can never hide one.
  - truthwalk answers imported for any upper-case letter. Both callers lower first (floor via `$4` or lower; check_fix via lower), and truthrule's `case` arm runs earlier.
- **floor's `$4` and the .md-ancestor rule (`:1927-1951`).** Probe C ran 12 paths with and without `$4`, and every answer was the same. Refused paths:
  - `docs/new.md/x` and `docs/NEW.md/x`
  - `Docs/Up.md/y` and `docs/up.md/z`, where the import is spelled `@Docs/Up.md`
  - `src/claude.md/a/b`, `src/Skill.md/x` and `a b/claude.md/x`

  Passed paths: `notes/plan/x` (a non-.md import: settled Won't-Fix row), `docs/new.md./x` (a different name on Linux), `docs/new.mdx/y` and `docs/x.txt`. The ancestor rule reads IMPORTED_MAIN only after truthwalk returned 1, so only after the walk succeeded.
- **IMPORT_CONFIGS in the keys (`:1146`, `:1198-1199`, `:1629-1631`, `:1704-1707`).** config_seeds now reads config dirs only from IMPORT_CONFIGS (`:1453`). No other lib code reads CLAUDE_CONFIG_DIR. In probe E, both walks re-walked without import_reset after a HOME change (a new `~/.claude/CLAUDE.md` import became visible) and after an IMPORT_MANAGED_DIR change. The bats test covers CLAUDE_CONFIG_DIR. The walk keys join ROOTS, HOMES and CONFIGS with blank lines and carry no length prefix, but they cannot be ambiguous: ROOTS and CONFIGS never hold a blank line or start with one, and HOMES' only possible blank line is its first entry. Ancestor `.claude` dirs derive from IMPORT_ROOTS, which is already in the key.
- **prompt_marks (`:1390-1405`).** The live and `//` branches close F3:
  - In probe A, with root `$T/a/b`, a link into `$T/a/bc` was not marked, and a link into `$T/a/b/docs` was marked.
  - With a reader root literally named `$T/g/r*`, a link into `$T/g/rX` was not marked: the root is quoted, so it matches literally.
  - Probe G1 (a two-hop link chain in another worktree, `.claude/commands/k.md → ../../docs/l.md → t.md`) and probe G2 (a config-dir command linking into ROOT_REAL's `docs/t.md`) both gave `top.md` imported, by both walks.
  - realpath failure returns 1, and the walk fails.
  - A `/` alone or an empty line in IMPORT_ROOTS would make `"$p"/*` match everything, but that is only an over-read, and import_readers refuses both.
- **config_seeds and c1_seeds (`:1450-1529`).** The split keeps both keep-rules and the newline scan over the whole array (`:1446`). config_seeds clears the array before c1_seeds appends to it. Neither function declares `sd`, so both namerefs reach the walks' array (row 589's note, settled).
- **walk_why (`:808-826`).** Every crafted PATH outside NAMECHARS prints as `?` (probe I: a space, a tab, a space inside a `//` path). An unknown KIND prints in a generic sentence, and KINDs are lib-internal (B6, settled). Absolute host paths and `-rf` or `../../etc/passwd` print as text. Those characters pass NAMECHARS and are inert in a row (B6, settled). The row then goes through scrub (unchanged).
- **Escalation from Stage 1: early-rule refusals do not exit on an unset ROOT_REAL.** No caller relies on the exit. build-loop.sh sets ROOT_REAL at `:329`, after `cd "$ROOT"` and before any check_line. dev-cycle.sh sets it at `:126`. Floor's early rules (truthrule, GATE_CODE, docs/thoughts, docs/working, docs/reviews) do no I/O and refuse, which is fail-closed. A path that reaches the walk still exits through readers_root/need_root (probe D: "unset root: exit 1"; the bats test at `:673`). The comment at build-loop.sh:867, "the floor's need_root exit ends the run", stays true for every path that reaches the walk. The Stage-1 "mostly accurate" verdict on the header (`:18-21`) is the right one, and it is not a security defect.
- **Here-string reads (`:1395`, `:1453`).** If a here-string failed silently, the prompt_marks loop or config_seeds' `mapfile` would see nothing, and seeds or marks would drop. Probe F ran under bash 5.2.15 with `TMPDIR=/nonexistent/tmp`. A 200 000-byte here-string and a small one both read one line, with exit status 0. The case is not reachable here, and TMPDIR is S5 (deploy-time) anyway.

## Endorsement Claims

- **Claim:** prompt_marks' live branch marks a live absolute prompt entry's names only when its real path lies strictly below a reader root, with the root compared as a literal whole-component prefix (`/a/b` does not take `/a/bc`, and a root holding `*` matches only itself).
  **Location:** `scripts/lib/dev-cycle-read.sh:1392-1396`
  **Evidence:** executed (probe A). The bats test "prompt_marks marks a live prompt link's names only when…" also passed (secf-bats.log, ok 2).
  **Verified:** l1 (into `$T/a/bc`) → none; l2 (into `$T/a/b/docs`) → `docs/a.md`; l3 (into `$T/g/rX`, root `$T/g/r*`) → none.
  **Not verified:** a root spelled with a trailing slash in IMPORT_READER_ROOTS. Its written spelling would never match, so only its realpath spelling would, and both are in IMPORT_ROOTS.
  **route: code-fact-check**

- **Claim:** F3 is closed for a two-hop link chain inside another worktree and for a config-dir command linking into ROOT_REAL. Both walks report the prompt-resolved import (`top.md`).
  **Location:** `scripts/lib/dev-cycle-read.sh:1390-1405`, call sites `:1663`, `:1800`
  **Evidence:** executed (probe G1, G2. The suite's F3 test passed, secf-bats.log ok 1).
  **Verified:** G1 main and tree: imported. G2 main and tree: imported.
  **Not verified:** a link under a symlinked directory in another root, which `find -P` does not enter (known issue A5, settled).
  **route: code-fact-check**

- **Claim:** readers_root never lets a walk read the checkout or list the registry from an unchecked cwd. A wrong cwd is tolerated only when both caches answer, and then the answer belongs to ROOT_REAL's own cached walk.
  **Location:** `scripts/lib/dev-cycle-read.sh:833`, `:1626-1631`, `:1702-1706`
  **Evidence:** executed (probes D, H).
  **Verified:** each of the following exited 1 with need_root's message from a wrong cwd: a walk miss, a CLAUDE_CONFIG_DIR change, a HOME change, an unset ROOT_REAL, and a walk miss from a subdirectory. A double hit returned ROOT_REAL's answer.
  **Not verified:** an IMPORT_READER_ROOTS/HOMES change mid-decision from a wrong cwd (static: both are in the key, so the same miss path applies).
  **route: code-fact-check**

- **Claim:** floor gives the same answer with and without `$4` when `$4` is lower($1), for the ancestor rule, the import rule and the early rules.
  **Location:** `scripts/lib/dev-cycle-read.sh:1925-1952`; `scripts/build-loop.sh:671`, `:843-844`
  **Evidence:** executed (probe C, 12 paths, all "same").
  **Verified:** the paths listed under Findings above.
  **Not verified:** a future caller passing a `$4` other than lower($1) (A13, documented).
  **route: code-fact-check**

- **Claim:** walk_has matches its LP literally. Glob metacharacters in a changed path never widen a match, and a newline in LP can only over-match (refuse).
  **Location:** `scripts/lib/dev-cycle-read.sh:1844-1847`
  **Evidence:** executed (probe B).
  **Verified:** the 8 inputs listed under Findings.
  **Not verified:** the tree arm, via check_fix's pathform-checked path (pathform already refuses `*`, `?` and newlines there).
  **route: code-fact-check**

- **Claim:** both walks re-walk without import_reset when HOME or IMPORT_MANAGED_DIR changes, so a config dir added that way is seen.
  **Location:** `scripts/lib/dev-cycle-read.sh:1144-1147`, `:1198-1199`, `:1629`, `:1704`
  **Evidence:** executed (probe E).
  **Verified:** main and tree: `h1 e: -` became `h2 e: imported`, and `m before: -` became `m after: imported`.
  **Not verified:** a change to a config dir's contents within one decision. That is not in any key; contract item 4's import_reset per decision covers it (pre-existing).
  **route: code-fact-check**

- **Claim:** no gate caller depends on floor's need_root exit for a path the early rules refuse. ROOT_REAL is set, and cwd is the root, before the first check_line.
  **Location:** `scripts/build-loop.sh:326-329`, `:860-870`; `scripts/dev-cycle.sh:126`
  **Evidence:** read-static, plus executed probe D ("early rule: an instruction or prompt file…" from a wrong cwd, no exit).
  **Verified:** `ROOT="$(git rev-parse --show-toplevel …)"`, `cd "$ROOT"`, then `ROOT_REAL="$(pwd -P)"`, before any mode runs.
  **Not verified:** a future U3 caller of floor (`--merge`).
  **route: code-fact-check**

- walk_why prints a PATH only when every character is in NAMECHARS (probe I). I am not routing this as a Confirmed-Good row, because the residual host-path disclosure is settled B6.

## Untested bypass candidates

- The ancestor rule on a case-insensitive or Unicode-folding checkout (`ſkill.md/x`, a Kelvin sign, trailing-dot stripping on Windows): not tested, because the fixture is Linux-only. This predates the diff and applies equally to truthrule's isstart.
- A config dir reached through a bind-mount alias of a reader root (the same directory under two non-symlink paths), so that realpath lands outside every root: not tested, because it needs mount privileges. It would leave the target's names read plain, as before F3, and the parser's projection uses the same root strings, so the two stay consistent.

## Primitive sweep

Primitive: untrusted text interpolated into gate output (B5)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `dev-cycle-read.sh:817` walk_why `link $d` | S2 | NAMECHARS or `?` (`:811`), scrub | cleared (probe I) |
| `dev-cycle-read.sh:819` walk_why `start/admit $d` | S2/S3/S4 | same | cleared (probe I) |
| `dev-cycle-read.sh:822` walk_why `read $d` | S2/S3/S4, `//` absolute | same; `//` → absolute | cleared (host path: settled B6) |
| `dev-cycle-read.sh:824` walk_why `*) $k` | lib-internal KIND (S7) | none | cleared: every KIND assigned in main_imports is a fixed word |
| `dev-cycle-read.sh:813` `$IMPORT_READER_WHY` | main's settings (S2) | scrub | cleared: predates the diff |
| `build-loop.sh:842` `$shown` | S1 | NAMECHARS or `?` | cleared |

Primitive: path resolution (realpath)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `dev-cycle-read.sh:1394` prompt_marks `realpath -e -- "$l"` | S3 (an admitted absolute entry) | `--`; failure → the walk fails | cleared: fail-closed |

Primitive: shell glob matching on untrusted strings

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `dev-cycle-read.sh:1846` walk_has `*$'\n'"$2"$'\n'*` | S1 via S6 | quoted operand | cleared (probe B) |
| `dev-cycle-read.sh:1395` `"$b" != "$p"/*` | S3 real path vs S5/S3 roots | quoted operand | cleared (probe A, `r*` root) |
| `dev-cycle-read.sh:1885` `*[A-Z]*` class | S6 | fixed class | cleared |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| — | No findings | — | — | — | — |

## Overall Assessment

I found nothing within the code paths I read and executed. Each probed redraw of the branch fails closed:
- the readers_root skip
- truthwalk/walk_has
- floor's `$4` and the .md-ancestor rule
- IMPORT_CONFIGS in the readers memo and both walk keys
- prompt_marks' live and `//` branches (F3 and B1's root-prefix test)
- the config_seeds/c1_seeds split
- walk_why's output rule

Iteration 1's Medium (untrusted names in deny rows) stays fixed. Stage 1's escalation (early-rule refusals without the root exit) is not a defect: no caller depends on it, and the refusal is fail-closed. The executed endorsement claims are routed to code-fact-check, and the one read-static entry names its unread hop. The fit-to-merge statement is therefore scoped to those paths and is not a categorical all-clear.

## Goal-Alignment Note

The goal is to land U2c2 after a clean review-fix loop. In the security domain this pass is clean: the walk-side changes add refusals and reads, close F3 (executed for the suite's case and two further link shapes), and keep untrusted names out of the deny rows. Nothing here blocks the merge. The open residuals (A5, case-folding file systems, a non-.md import name's directory, host paths in reasons) are already settled rows or predate the diff.
