Commit: 36b79f72

# Security Review — feat/build-loop-u2a (iteration 2)

**Scope:** `git diff main...HEAD` in the worktree `wt-build-loop-u2a` (HEAD 36b79f72). Code under review: `scripts/lib/dev-cycle-read.sh` (`floor`, `ownfile`, `isimported`, `main_imports`, `import_targets`, `instruction_names`, `untracked_md`, `main_entry`'s `badform`, `entry_why`, `isclosed`), `scripts/dev-cycle.sh` `check_fix`, `scripts/build-loop.sh` (`main_file`, `shared_branches`).
**Date:** 2026-10-06
**Based on:** `docs/reviews/code-fact-check-report-build-loop-u2a.md` (iteration 1; Claim 11a fixed in 36b79f72, Claim 16), `docs/reviews/override-log.md` rows 196-323, `docs/working/known-issues-dev-cycle.md` (A2, A3), `docs/reviews/security-review-2026-10-02-digest-pass38.md` (F2-F4).

All probes ran in throwaway repos under the session scratchpad (`review-u2a/sec/probe{,2,3}.sh`), each under `timeout`, with `GIT_CONFIG_GLOBAL=/dev/null`, `GIT_CONFIG_NOSYSTEM=1` and `GIT_DIR` unset. Nothing in `/workspace` was touched except this report.

## Trust Boundary Map

```
B1: loop branch's merge result (diff-tree paths)   → floor() (lower-cased denylist)        → self-merge decision (U2c --check)
B2: main's committed instruction files and trees    → main_imports / import_targets / main_entry → IMPORTED_MAIN refusal set (new)
B3: checkout's untracked/ignored *.md files         → untracked_md / plainfile                → extra walk start set (new)
B4: main's tree listing (crafted trees possible)    → record-shape and listed-twice checks     → walk proceeds or fails closed (new, fixed in 36b79f72)
B5: in-cycle fix path argument (dev-cycle --check-fix) → check_fix (constraints.md, isimported tree) → in-cycle edit allowed
```

| Label | Source | Mutability | Trust classification |
|---|---|---|---|
| S1 | changed path from the loop's merge result | request-time (the loop picks it) | UNTRUSTED for the floor decision (all sinks) |
| S2 | main's committed instruction files, import text, tree shape | runtime-mutable (any merge, including a reviewed one or a user commit) | UNTRUSTED for path construction and git reads; it is also the ground truth for "what Claude Code loads", so the walk must model it the way Claude Code does |
| S3 | the checkout's untracked files (`CLAUDE.local.md` and what it imports) | runtime-mutable, writable by any same-uid loop | UNTRUSTED; by design it may only add refusals |
| S4 | `MAIN_SHA`, refs, `.git/config` | runtime-mutable (shared `.git`) | UNTRUSTED toward git reads; hardening is U2b's state gate (F25), out of this diff |
| S5 | `ROOT_REAL`, cwd | set by the caller, checked by `need_root` | trusted after `need_root` |
| S6 | `INSTRUCTION_FILE`, `GATE_CODE`, `IMPORT_RE` | code constant | trusted |

What enters: S1 paths a loop chooses, and S2/S3 text that decides which of those paths are "instructions". The diff's central assumption is that the main walk (B2) finds every file Claude Code would load as instructions from main's commit; where that model is narrower than Claude Code's loader, `floor` fails open on B1.

## Findings

#### F1. The main walk follows an import only into a blob it can look up by pathform; the tree walk it replaces for the gate followed more

**Severity:** Medium
**Location:** `scripts/lib/dev-cycle-read.sh:529-535` (the `case "$e"` in `main_imports`), comment `:444-447`
**Boundary:** B2 (and B3 for the untracked chain)
**Move:** 11 (enumerate bypasses), 5 (invert the model)
**Confidence:** High (script side, executed); Medium for occurrence (needs such an import on main, which a loop cannot add itself because instruction files and dot-paths are floored)
**Legibility-target:** the walk's header comment and `build-loop-check.bats` T10

Evidence (verbatim):

```
      seen+="$p"$'\n'; e="$(main_entry "$p")"
      case "$e" in
        blob) queue+=("m:$p") ;;
        error) IMPORTED_MAIN=error; return 1 ;;
      esac
```

Every other word (`badform`, `absent`, `notfile`, `notdir`) lists the target but never reads it, so the target's own imports are never walked. `main_entry` answers `badform` for any name `pathform` refuses, which includes every `.git*` component (so all of `.github/`) and any name with a character outside `[A-Za-z0-9._/-]`. Executed:

- D2: `CLAUDE.md` = `@.github/instr.md`, `.github/instr.md` = `@../docs/g.md` → `docs/g.md: PASSES` (`.github/instr.md` itself is refused only by the dot rule).
- D1: `CLAUDE.md` = `@docs/a+b.md`, which imports `@deep.md` → `docs/deep.md: PASSES`. The working-tree walk (`isimported tree docs/deep.md`) answers imported for the same repo, so for the gate this is a regression from the walk the plan's F11 row reuses.
- C11: untracked `CLAUDE.local.md` = `@docs/local-notes.md` (untracked, so `absent` on main), which imports `@t.md` → `docs/t.md: PASSES`. The tree walk would follow the plain untracked file.

A loop whose brief lists `docs/g.md` (or `docs/deep.md`, `docs/t.md`) in `Paths:` self-merges it, and every later session loads its text as instructions: exactly D5 item 1. The comment at `:447` ("a target pathform refuses is listed, not followed") states the rule but not that the refusal set loses the target's imports.

**Recommendation:** For a `badform` target whose only defect is a `.git*`/dot component or an unusual character, read it anyway with a lookup that does not need pathform (`git ls-tree -z --full-tree MAIN -- <path>` gives one record to shape-check, then `cat-file blob`), or fail the walk closed for a `badform` target that is not itself floored. For an `absent` target reached from a `t:` start file, read the plain working-tree file the way the tree walk does (it can only add refusals). Add D1, D2 and C11 to T10.

#### F2. A token absorbs a trailing non-ASCII space, so the file Claude Code reads is not listed

**Severity:** Medium
**Location:** `scripts/lib/dev-cycle-read.sh:450` (`IMPORT_RE`), used by `import_targets` `:454-464`
**Boundary:** B2
**Move:** 2 (implicit sanitization assumption), 11
**Confidence:** High for the script (executed); Medium for Claude Code's side (its token end is read from the pass-38 static reading of its bundle, not re-verified here; JS `\s` matches U+00A0)
**Legibility-target:** `IMPORT_RE` comment `:438-441`

Evidence (verbatim): `IMPORT_RE='(^|[^[:alnum:]])@[^][:space:]\\#`()]+'` run under `LC_ALL=C`, where `[:space:]` is ASCII only. Executed (C6): `CLAUDE.md` = `See @docs/nb.md<U+00A0>for details` → the token is `docs/nb.md\xc2\xa0for`, `main_entry` answers `badform`, and `docs/nb.md: PASSES`. Pass 38 tested NBSP *before* `@` (closed by R1); this is the *after* case, which R1 did not close, and the same holds for U+2000-200A, U+3000 and U+FEFF. It predates the diff in `imported_names`, but the gate is a new consumer of the set (plan amendment 2026-10-05: "U2's ... security review confirms that rather than inheriting it").

**Recommendation:** End a token at any UTF-8 space-class sequence too (`\xc2\xa0`, `\xe2\x80[\x80-\x8a\xa8\xa9\xaf]`, `\xe3\x80\x80`, `\xef\xbb\xbf`), or, simpler and fail-closed, also list every pathform prefix of a token that `pathform` refuses. Add C6 to T10.

#### F3. Known gaps A2/A3 carry into the gate unchanged, and one is now pinned by a test

**Severity:** Medium
**Location:** `scripts/lib/dev-cycle-read.sh:515` (start set: mode 100644/100755 only), `:518` (untracked start: `plainfile`), `:459` (absolute and `~` tokens skipped), `:531-534` (symlink targets not followed); `test/scripts/build-loop-check.bats:98-101`
**Boundary:** B2, B3
**Move:** 5, 11
**Confidence:** High (script, executed); Medium for Claude Code (absolute imports are documented; the symlink and `.claude/rules/` behaviour is from the pass-38 bundle reading)
**Legibility-target:** plan F11 row and `known-issues-dev-cycle.md` A2/A3

This is not new: plan F11 says the gate inherits A2/A3 ("partly"), and the amendment asked this review to confirm it. Confirmed by execution against `floor`:

- C3: `CLAUDE.md -> docs/ai-rules.md` (symlink on main), which imports `@docs/sub.md` → both `docs/ai-rules.md` and `docs/sub.md` PASS. `CLAUDE.md` pointing at a shared doc is a common pattern.
- D4: untracked `CLAUDE.local.md -> docs/mine-untracked.md` importing `@m2.md` → `docs/m2.md: PASSES`.
- C9: `.claude/rules/style.md` importing `@../../docs/r.md` → `docs/r.md: PASSES`.
- C4/C5: an import of `docs/link.md` (a symlink to `real.md`) or `lib/x.md` (`lib` a symlinked directory) refuses the link path but `docs/real.md` / `real/x.md` PASS.
- C1: `CLAUDE.md` = `@<abs repo root>/docs/abs.md` → `docs/abs.md: PASSES`. The comment `:436-437` says "~/ and absolute paths lead outside the repo"; an absolute path can name the repo itself.

Evidence (verbatim, the test that pins C3's shape):

```
@test "floor: a name the tree lists twice, or one holding a newline, fails the walk; a symlinked instruction file on main starts nothing (U2a)" {
    printf 'imports @docs/b.md\n' > real.md && ln -s real.md CLAUDE.md && commit_all link
    floors 2026-10-01-x M docs/b.md
    want docs/b.md -
```

Asserting `docs/b.md -` locks in a fail-open of D5 item 1 as contract: a later fix that starts from the symlink target would have to break this test.

**Recommendation:** Keep the deferral if the plan's Q-103 still lists F11 as "partly", but reword the test as a known-gap marker (comment it as A2, or assert only that the walk does not fail) rather than a contract. When fixing: start from an in-repo symlink target (`git ls-tree` gives the target text; resolve it lexically against the link's directory), add `.claude/rules/**/*.md` to the start set, and keep an absolute token when it resolves under `ROOT_REAL`.

#### F4. Where the gate's untracked start set comes from is not yet pinned

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:517-518`; plan F11 row (unchanged by this diff)
**Boundary:** B3
**Move:** 1
**Confidence:** Medium

`untracked_md` lists the untracked files of the checkout at `ROOT_REAL`. The amendment (plan :192) requires U2 to "add the orchestrator checkout's local instruction files to the gate's start set or record the gap in F11, and test it". U2a reads the current checkout only, which covers the orchestrator's `CLAUDE.local.md` only if the gate runs with `ROOT_REAL=/workspace`; a gate in a clean worktree at `MAIN_SHA` gets none. No mechanism is reachable in this diff (no gate mode exists yet), so this is a dependency note for U2c/U3: either the gate runs at the orchestrator's top level, or F11 records the gap.

## Untested bypass candidates

- Case-insensitive checkout (C8, script side executed): `@Docs/Guide.md` with main storing `docs/guide.md` that imports `deep.md` → `docs/guide.md` refuses, `docs/deep.md` PASSES. On a case-insensitive filesystem Claude Code would read both. No such filesystem available here.
- `..` through a symlinked directory on main (C10): `@sub/../docs/n.md` with `sub -> other` refuses `docs/n.md` (lexical); `other/docs/n.md` PASSES. Safe if Claude Code resolves lexically (`path.resolve`), a gap if it resolves physically. Claude Code's side not verified.
- Trailing `_` / `.` (C7): `@docs/notes_` lists `docs/notes`; `docs/notes_` PASSES. Whether Claude Code strips a trailing `_` is unverified; it matters only for a target whose name ends that way.
- A backslash import (`@docs\x.md`) read by a Windows-side Claude Code over the WSL share: not tested.
- Changed-path spelling on B1: `floor` itself runs no `pathform`; names with spaces, `+` or non-ASCII must be refused by U2b's per-path `pathform` before `floor` is asked. Not testable until U2b.
- `untracked_md` failing inside the process substitution at `:518` drops the untracked start set silently (only refusals are lost). Not induced.
- Replace refs or a planted config changing what `git ls-tree`/`cat-file` return inside `main_imports`: `build-loop.sh:117-118` exports `core.useReplaceRefs=false` and `GIT_NO_REPLACE_OBJECTS=1`; the rest is U2b's state gate (F25). Not exercised here.

## Endorsement Claims

- **Claim:** A tree naming `x` as both a symlink and a directory (fact-check Claim 16) makes `floor` refuse every path with the walk-failure reason.
  **Location:** `scripts/lib/dev-cycle-read.sh:509-524`
  **Evidence:** executed
  **Verified:** probe3: `ls-tree -r` listed `120000 x` and `100644 x/CLAUDE.md`; `cat-file blob MAIN:x/CLAUDE.md` failed; `floor docs/q.md` and `floor docs/other.md` both printed "the default branch's instruction files could not be walked for @ imports".
  **Not verified:** the order variant with the tree entry sorted before the symlink entry.
  **route: code-fact-check**
- **Claim:** The walk's cache re-walks when `MAIN_SHA` changes within one process.
  **Location:** `scripts/lib/dev-cycle-read.sh:499-500`
  **Evidence:** executed
  **Verified:** probe2 D5: `floor docs/a.md` passed, a new main commit added `@docs/a.md` to `CLAUDE.md`, `resolve_main` re-ran, and `floor docs/a.md` refused.
  **Not verified:** two `ROOT_REAL`s with the same `MAIN_SHA` in one process (the untracked start set is not part of the cache key).
- **Claim:** An import through a dot-directory file that `pathform` accepts (`.claude/rules.md`) is followed, and its own import is refused.
  **Location:** `scripts/lib/dev-cycle-read.sh:529-535`
  **Evidence:** executed
  **Verified:** probe C2: `docs/style.md` refused with the import reason.
  **Not verified:** `.git*` components (F1 covers that they are not followed).
- **Claim:** `check_fix` prints `skip` for `docs/constraints.md` in any case spelling, before the import check.
  **Location:** `scripts/dev-cycle.sh:180-182`
  **Evidence:** read-static
  **Verified:** the condition compares the lower-cased `$lp` with `docs/constraints.md` inside the first skip arm.
  **Not verified:** the bats row that exercises it.

## Primitive sweep

Primitive: git object read / path construction from repo text

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/lib/dev-cycle-read.sh:509` `git ls-tree -r -z` | S2, S4 | record-shape regex, listed-twice check, pipefail | cleared (B4 fails closed: probe3, fact-check 11a fix) |
| `scripts/lib/dev-cycle-read.sh:525` `git cat-file blob "$MAIN_SHA:$f"` | S2 | start-set filter / `main_entry blob` | cleared; failure → walk error |
| `scripts/lib/dev-cycle-read.sh:526` `import_targets < "$f"` (working tree) | S3 | `plainfile` at enqueue | cleared for reads (symlinks refused); F3 for the symlink-start gap |
| `scripts/lib/dev-cycle-read.sh:460` `realpath -ms` on `ROOT_REAL/dir/token` | S2, S3 | `..*` result skipped; `-s` lexical | F3 (absolute tokens skipped at `:459`), C10 untested |
| `scripts/lib/dev-cycle-read.sh:271` `main_entry` `git ls-tree -t` | S2 | pathform first (`badform`), dup → error | cleared for reads; F1 for what `badform` drops |
| `scripts/lib/dev-cycle-read.sh:500-519` `untracked_md` / `git ls-files --others` | S3 | `plainfile`, INSTRUCTION_FILE | cleared (adds only); untested failure path |
| `scripts/build-loop.sh:135` `main_file` `cat-file blob` after `main_entry` | S2 | `main_entry blob` only; other words → `entry_why` skip | cleared (refactor only) |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Main walk does not follow `badform` or untracked-only targets; their imports self-merge | Medium | B2, B3 | `scripts/lib/dev-cycle-read.sh:529-535` | High |
| 2 | Token absorbs a trailing NBSP/Unicode space; the real target is not listed | Medium | B2 | `scripts/lib/dev-cycle-read.sh:450` | High (script) / Medium (CC) |
| 3 | Known A2/A3 (symlinked start, `.claude/rules/`, symlink targets, absolute imports) carried into the gate; C3 pinned by a test | Medium | B2, B3 | `scripts/lib/dev-cycle-read.sh:459,515,518`; `test/scripts/build-loop-check.bats:98-101` | High (script) / Medium (CC) |
| 4 | Gate's untracked start set depends on where U2c/U3 run it | Informational | B3 | `scripts/lib/dev-cycle-read.sh:517-518` | Medium |

## Overall Assessment

The 36b79f72 fix holds: split and doubled start files, and the symlink-and-directory tree, all fail the walk closed, and a failed walk makes `floor` refuse everything. The rest of `floor` (dot, gate code, cycle files, records, `ownfile`) read and probed as specified. The remaining problem is coverage, not a fail-open in the error path: the main walk's model of "what Claude Code loads" is narrower than Claude Code, and in one respect (F1) narrower than the working-tree walk it replaces for the gate. All three findings need an import shape already on main, which a loop cannot add by self-merge, so none is urgent, but D5 item 1 promises that such paths never self-merge. F1 is fixable in place and is the most important: follow `badform` and untracked targets (or fail closed on them). F2 is a small token-rule change, and F3 is the existing A2/A3 deferral, apart from rewording the test that pins it. There are no findings in the code paths read beyond these; the endorsement claims are pending execution verification where they are marked read-static.

## Goal-Alignment Note

The PR's goal is a floor that fails closed: a loop must never self-merge a path that takes effect on merge. The error path now meets that (B4). The success path does not yet cover every path Claude Code loads as instructions from main: F1 (new in this diff's walk), F2 (an import-token variant pass 38 did not close) and F3 (known, accepted under F11 "partly"). U2c is the first caller that acts on `floor`, so F1 and F2 should land before or with U2c, and Q-103's F11 text should name F3's shapes, including absolute imports.
