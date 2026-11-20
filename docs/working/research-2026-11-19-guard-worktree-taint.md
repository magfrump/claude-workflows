# Research: the write guard and edits inside `.claude/` worktrees

Brief: `docs/working/briefs/2026-11-19-guard-worktree-taint.md` (at f5fbc9be).
Branch: `fix/guard-worktree-taint`. Date: 2026-11-19.

## Problem

`hooks/guard-trusted-writes.py` `classify_path` puts any file-tool path with a
`.claude` segment in SOFT, and SOFT asks whenever the session's web-taint marker
exists. One web fetch taints the whole session, so every Edit inside a worktree that
lives under `.claude/` (Claude Code's own `.claude/worktrees/<name>/`, this harness's
`.claude/wt-*/`) asked. The owner's math-research rewrite hit hundreds of asks.

Reproduction: `bats test/hooks/guard-trusted-writes.bats -f 'reproduction table'`
(hermetic: temp HOME, test taint marker, a real repo with two linked worktrees). Before
the fix: ask for `.claude/worktrees/foo/chapter3.md` and `.claude/wt-foo/chapter3.md`
when tainted, defer when clean, defer for `.worktrees/wt-x/chapter3.md` and the main
checkout. The case fails on the old hook (checked by running the new test file
against `git show f5fbc9be:hooks/guard-trusted-writes.py`: 7 of the first 12 new cases fail,
all on their "defer" assertions; the ask-side cases pass on both, pinning that the
change keeps them).

## What I read

- The guard header and `classify_path`; the HARD tier is checked first on three
  candidates (as given, `..`-folded, resolved), then SOFT on any of the three.
- `test/hooks/guard-trusted-writes.bats` 517-781: the Q-048 Bash cases. Q-048 [2]'s
  worktree exemption was for Bash text and was withdrawn after three review passes
  found bypasses (`docs/reviews/code-review-rubric-2026-09-23-ans-guard-q048-q050.md`):
  quote-split `..`, `cd ..`, brace expansion, `env -C`, link-creating tools. Every one
  of those comes from Bash's text being unresolvable. A file-tool path is a single
  string the hook can resolve, so those families do not carry over; what does carry
  over is symlinks, `..`, case folding and forged worktree metadata.
- `docs/working/research-2026-11-19-worktrees-outside-dot-claude.md` Question 2: moving
  worktrees out of `.claude/` would sidestep this, but Claude Code's own
  `.claude/worktrees/` cannot be moved, so the guard has to change.
- `docs/constraints.md` H2 (fail closed), S1 (proportionate; a relaxation that names
  its residual is valid).
- The hook's matcher in `hooks/wiring.json` is `Edit|Write|MultiEdit|Bash`. The brief
  names NotebookEdit, but the hook never sees it; wiring it is out of scope here.

## Gotchas

- Failure-pattern grep: FP-034, FP-073, FP-151 (see Prior failures)
- This branch adds FP-185 to `docs/failure-patterns.md` (an overbroad path-segment
  guard that caught whole checkouts).
- The guard blocks this session's own Bash heredocs that name a hook path together with
  `.claude` (that is the Bash tier working as designed); write files with Write/Edit.

### Prior failures

- FP-034 (symlink TOCTOU on a fixed tmp path): a path check and the write it guards can
  disagree when a symlink moves in between. Bounded here by S1 (same-uid honest slips)
  and by Bash already being able to make the same write; named as residual R3.
- FP-073 (a guard deferring to deny rules that were never wired): the HARD tier's
  defer depends on `permissions.deny`. This change does not touch HARD or its order.
- FP-151 (a path-keyed guard disarmed by a file move): a rule keyed on path shape can
  be steered by moving things. Here the shape only nominates a root; the root has to
  be verified from git's own files, and everything else stays on the old rule.

## Design choice: how to decide "inside a linked worktree" and where its root is

Divergent design, seeded with H1-H4, S1, S3, S8 and the brief.

| Option | What it does | Verdict |
|---|---|---|
| A. Segments alone | `.claude/wt-*/` or `.claude/worktrees/<n>/` prefix is the root, no filesystem check | Rejected: a plain directory with that name is exempted unverified, against H2 |
| B. Git's own files at the segment-shaped root (pick) | Root must be a non-symlink dir whose `.git` is a regular file `gitdir: G`, G inside a `worktrees/` dir, G/gitdir pointing back | Picked: two small file reads, no subprocess, fails closed on any error |
| C. `git worktree list` / `git rev-parse` | Ask git for the root | Rejected: a subprocess per Edit, and git runs in an agent-writable checkout whose config is input (H1); it reads the same forgeable files as B |
| D. Walk up to the nearest `.git` file anywhere | Root wherever a `.git` file is | Rejected: broader than the problem, could nominate a root at or above the config dir; no gain over B |

B dominates on fail-closed behaviour at trivial cost (Path A: decided).

Other choices, one line each:

- Which policy files stay SOFT inside a worktree: the old SOFT rules applied to the
  path relative to the root, plus `hooks/`, `settings*.json` and `.git` at the root
  only (this repo's checkouts hold the harness's own hooks and settings there; `.git`
  redirects git's hook dir). Deeper `src/hooks/` or `.vscode/settings.json` get no
  opinion, as in the main checkout (review A1). The relative path is judged both as
  written and resolved, so a symlinked `CLAUDE.md`, `hooks/` or `.claude/` keeps its
  ask (review R1).
- Nested `.claude/` worktrees: the innermost root is judged; if it fails verification
  the whole path falls back to the old rule (it holds `.claude`, so SOFT).
- Root shape is matched case-sensitively (`.claude`, `wt-`, `worktrees`): a case variant
  is no root and keeps the old case-folded SOFT.
- A verified root in, at or holding the config dir (either form), or at or holding
  home, is refused, so a forged `.git` cannot uncover `~/.claude`'s memories and
  skills. A worktree deeper under home (`~/proj/.claude/wt-x`) is allowed; `~/CLAUDE.md`
  is HARD and decided first.
- Each of the four SOFT candidates (as given, `..`-folded, resolved, unresolved
  absolute) is judged on its own and any SOFT wins; for a candidate
  under a root, its resolved path must lie under the root's real path, so a symlink or
  `..` that leaves the worktree keeps the ask.
- A relative file path as written is never a worktree root. Its resolved form and
  its unresolved absolute form (both anchored at the hook's cwd) are judged like any
  absolute path. The absolute form is a SOFT-only candidate, added in pass 2 (review
  A6) so a symlinked root `settings.json` reached by a relative path keeps its ask.
  Because any SOFT wins, a relative spelling that itself names `.claude/wt-*/` or
  `.claude/worktrees/<n>/` (typed from the repo root) still asks where its absolute
  spelling does not: extra friction, never a lost ask. If the cwd is gone, abspath
  cannot anchor the path, so it is SOFT (pass 3, review M1).
- A worktree named after a policy word (`.claude/worktrees/skills/x.md`) is relaxed
  like any other: the word is its root's name, not a folder above it, and Claude
  Code loads no skills from there.
- A worktree with a skills/agents/commands/memories folder (any case) above its root
  gets no relaxation, so nesting one in a policy folder keeps that folder's ask
  (review C7).
- Any exception inside the worktree judgement (e.g. a symlink chain too deep for
  realpath) returns SOFT (review C1); G/gitdir gets the same regular-file and size
  check as `.git` (review C2).

## Plan (done)

1. `hooks/guard-trusted-writes.py`: `_worktree_root`, `_verified_worktree`,
   `_is_soft_rel`, `_is_soft_path`, `_is_soft_parts` (the old SOFT name rules, now one
   function used by both paths); `classify_path`'s SOFT loop calls `_is_soft_path`. Header
   SOFT paragraph and the Bash "no worktree exemption" line updated.
2. Tests: 12 new cases (17 after review) in `test/hooks/guard-trusted-writes.bats` (reproduction table,
   own policy files, HARD unchanged incl. resolved-deny through a worktree link,
   symlinks, `..`, fail-closed roots, unreadable `.git`, config-dir containment, case
   variants, relative gitdir pointers, Write/MultiEdit/`path` key, Bash unchanged).

## Pre-mortem (enforcement file)

Assume this shipped and a write to a real policy file went through with no ask in a
tainted session. The ways it could happen, and what bounds each:

1. **A symlink inside the worktree leads out** (to `~/.claude`, the project's
   `.claude/`). Bounded: the resolved candidate is judged by itself, and a lexical
   candidate's resolved path must sit under the root's real path. Tests: `cfg`,
   `proj` links.
2. **`..` out of the worktree.** Bounded the same way (resolution plus the
   relative-to-root check). Tests: four `..` spellings.
3. **A symlinked root** (`.claude/wt-alias -> elsewhere`, `.claude/wt-x -> ~/.claude`).
   Bounded: `islink(root)` refuses; containment refuses a root at the config dir.
4. **Case folding** (`.Claude/wt-x`, `.claude/WT-x`). Bounded: root shape is exact-case;
   variants keep the case-folded SOFT.
5. **A forged worktree**: a plain `.claude/wt-x/` given a hand-written `.git` file and a
   matching gitdir back-pointer. Not fully bounded: a Bash-capable session can write
   both (Bash writes naming no policy file get no opinion). Gain: only ordinary-named
   files under that dir lose the ask; the worktree-relative policy names still ask,
   the ordinary files that lose it are the ones the main checkout leaves ungated
   (R2: e.g. `.mcp.json`, files a CLAUDE.md `@`-imports), and the forger can write
   those same files through Bash with no opinion already (S1). Forging at or holding
   the config dir or home is refused. Residual R1.
6. **A policy-relevant file the relative list misses** (`.mcp.json`, `.envrc`, build
   scripts, `package.json` scripts). The worktree is now treated like the main
   checkout, where these get no opinion today. Residual R2.
7. **Swap between check and write** (a symlink planted after the hook ran). Same-uid
   race, honest-slip threat model (S1); Bash can make the write directly. Residual R3.
8. **HARD regressed.** Bounded: the HARD and resolved-HARD checks run first and are
   untouched; tests pin defer for the four HARD entries and deny for a worktree link
   onto `~/.claude/settings.json` and `~/.claude/hooks`.
9. **Config dir set inside a worktree** (`CLAUDE_CONFIG_DIR` under `.claude/wt-x/`).
   Bounded: containment refuses that root. Test included.

### Residual risk

- **R1 forged-worktree-ordinary-files**: a session that can run Bash can make a plain
  `.claude/wt-*` dir look like a linked worktree, after which ordinary-named files
  there are edited with no ask. Those files are the kind the main checkout leaves
  ungated (R2), and Bash could write them anyway.
- **R2 worktree-equals-checkout**: files that are policy-shaped but not on the SOFT
  list (`.mcp.json`, files a CLAUDE.md `@`-imports, `hooks/` or `settings*.json`
  below the root, a nested repo's `.git/hooks`, and similar) get no opinion in a
  worktree, exactly as in the main checkout today. Where they asked before this change
  (inside `.claude/` worktrees), they no longer do.
- **R3 check-then-write race**: as for every path check in this hook.

## Review-fix loop

- Pass 1 (rubric at f2829bcf, `docs/reviews/code-review-rubric-2026-11-19-guard-worktree-taint-pass1.md`):
  R1 (symlinked policy names lost the ask) fixed by judging the as-written relative
  path too; A1 (hooks/settings at any depth) narrowed to the root; A2-A5 wording fixed
  here and in the hook; C1 (deep symlink chain raised and exited 1) and C2 (FIFO
  gitdir) fixed; C4 functions renamed (`_verified_worktree`, `_is_soft_path`). A2's
  commit-body wording in f2829bcf is immutable. C3 (re-verification per candidate,
  about 0.8 ms) and C6 left as is; C5 (roadmap item) is the cycle's to close.
- Three new cases (R1, A1, C1) fail on f2829bcf and pass now.
- Pass 2 (rubric at 881d87a9, `docs/reviews/code-review-rubric-2026-11-19-guard-worktree-taint-pass2.md`):
  no red. A6 (relative path to a symlinked root settings.json/hooks lost the ask)
  fixed with a SOFT-only absolute candidate; C7 (worktree nested in a policy folder)
  fixed in `_worktree_root`; A7-A11 wording fixed in the hook header, `_is_soft_rel`
  and here. Two new cases (A6, C7) fail on 881d87a9 and pass now. C8 (pre-existing
  fail-opens in `main()`, outside the diff), C9 (follows the documented rule), C3,
  C11-C13 left as is.
- Pass 3, the final pass (rubric at 98d78d32,
  `docs/reviews/code-review-rubric-2026-11-19-fix-guard-worktree-taint.md`, full
  branch, k=3 fact-check): one red, R1. Pass 2's abspath candidate crashed the hook
  when the cwd was gone (exit 1, so the edit got no ask). Fixed in 5070403e: abspath
  failing is SOFT. A1-A3 wording also fixed there. Two new cases: M1 fails on
  98d78d32, M2 pins the relative `.claude/wt-x` spelling. At the 3-iteration cap the
  fix was checked by tests and a fix-drift pass, not a fourth full pass.

## Verification

- `bats test/hooks/guard-trusted-writes.bats`: 107/107 (88 before, 19 new).
- `bats test/hooks/`: 227/227. `scripts/hermeticity-lint --root .`: pass.
- Live check (not runnable in this sandbox): in a web-tainted session, an Edit to an
  ordinary file inside a `.claude/worktrees/` worktree applies with no ask, and an
  Edit to that worktree's `CLAUDE.md` still asks.
