# Research: the import walk reads plain `@path` imports only (restriction audit unit 6)

Brief: `docs/working/briefs/2026-11-03-import-walk-plain.md` (policy review, branch `refactor/import-walk-plain`, dispatched at ed6b0be2).

Failure-pattern grep: fail-open, fail-closed, import, pipefail (docs/failure-patterns.md: FP-079 and FP-129, grep's no-match exit 1 under pipefail read as a failure or swallowed; FP-118, a pipeline status under errexit. The new walk reads git's exit status apart from its listings and never pipes a grep into a status test.)

Failure-pattern skip: no fix(...) commit is planned; if the review-fix loop adds one, it fixes a slip in this branch's own new code, which has no earlier occurrence to record.

## Motive

The owner's restriction audit (2026-11-01) asks to drop every restriction that does not answer an in-scope threat; S1 puts a hostile loop, branch or author out of scope. The import walk is about 794 code lines and 2 to 3.5 s per walk, and most of it models an import obfuscated or planted on purpose: the outside seeds, the reader roots and homes, the superset parser, the budgets and the link and name modelling. An unreadable directory in any registered worktree fails every walk, so it holds every self-merge back (S1: no restriction may stop all self-merges). The owner call G55 (keep a walk at all) is open with the interim "keep a plain-`@path` walk": this unit follows it.

The in-scope threat the walk keeps answering is an honest slip: `CLAUDE.md` says `@docs/conventions.md`, a loop edits `docs/conventions.md`, and with no owner review it becomes instructions for every session. That threat needs only what a session in this checkout loads: plain `@path` tokens in the start files the checkout holds.

## Rows G55-G62 against today's code (ed6b0be2)

The audit's line numbers predate units 1-5; today's are below (`scripts/lib/dev-cycle-read.sh` unless named).

| Row | Today | Verdict | What this unit does |
|---|---|---|---|
| G55 | `main_imports` 1792-1922, floor via `truthwalk` 1985-1995, `floor` 2044 | NARROW | Keep a main-tree walk over the start files main stores, plain imports, failing closed on a read it cannot make (H2). |
| G56 | `main_checkout` 1689-1716, `checkout_md` 1671, phase 2 in `main_imports` 1824-1836, 1854-1916 | NARROW | Keep reading the checkout's untracked start files and the imported files main lacks, as plain files; skip other shapes (a link, a FIFO, a directory) among untracked starts instead of refusing; drop the ancestor and searchability modelling. |
| G57 | `outside_seeds` 1497, `config_seeds` 1507, `top_files` 1589, `c1_seeds` 1601, `outside_proj` 1336, `outside_ok` 1327, `with_at` 1356, `root_starts` 1350 | REMOVE | Gone: config dirs, managed policy, ancestors' instruction files, other worktrees' starts, `installed_plugins.json` (the walk's only python3 use besides decoding). |
| G58 | `root_copies` 1391, `prompt_marks` 1443, `import_readers` 1201 with `import_readers_key` 1196, `readers_root` 884 | REMOVE | Gone: the worktree registry read, reader roots and homes, dotnest, other roots' copies. |
| G20 | `reader_settings` 648, `SETTINGS_AWK`'s roots/homes keys 611 | REMOVE (same code as G58) | `reader_settings` no longer sets reader lists or fails the walks; `--settings` prints one `readers` line saying the legacy lines are ignored. `readerform` stays: `build-loop.sh` uses it for `--dir` and worktree paths. |
| G59 | `IMPORT_AWK` 987-1125, `import_targets` 1260, `UNI_SPACES` 916, `UTF8_WELL_FORMED` 1130, python3 decode 1277 | NARROW | A new small parser: an `@` token read to ASCII whitespace, resolved against the importing file's directory (`~/` against HOME), a file that is not valid UTF-8 refused. No python3. |
| G60 | `IMPORT_OUT_MAX` 892, `IMPORT_WORK_MAX` 912, `import_work` 1632, `capped_read` 1664 | REMOVE budgets; keep a cap | One per-file size cap (4 MiB, Claude Code's own limit) that refuses. |
| G61 | `main_imports` 1805-1823, 1866-1890 (`START_LINK`, link text) | NARROW | No symlink is followed: a start or import target main stores as a symlink, or a checkout path that is or lies under a link, refuses (H2). Duplicate-name and file-and-directory checks go. |
| G62 | `PROMPT_DIR` 703, `isstart` 707, `prompt_bases` 717, `instruction_names` 1643 | NARROW | Keep the starts (`isstart`, `instruction_names`); a prompt start's names resolve against its own directory and the repo root only. |

### Restrictions the audit's REMOVE verdicts would drop that an in-scope threat still needs

- **A read failure of any file the walk reaches refuses every path** (H2; the audit keeps it). Kept: an unreadable blob, an unreadable checkout file, one over the cap or not valid UTF-8.
- **A failed listing refuses** (main's tree, the checkout's untracked `.md` list). Kept: this is a crash or a broken repository, not a hostile shape; reading a partial list would answer "not imported" wrongly. Stderr warnings from `git ls-files --others` no longer refuse: an unreadable directory there is skipped (G56: other shapes skipped), as the audit asks.
- **Cache and `import_reset`** (contract item 4): concurrency, kept; the key drops the reader set and keeps the commit, main-by-name, `ROOT_REAL` and HOME.
- **The `need_root` exits**: honest slip (a caller outside the repo root), kept.
- Nothing else in G56-G62 answers an honest slip, concurrency or a crash that the plain walk does not already cover.

### The two stale lines unit 3 left

Both were already reworded by 61443d9f (brief 2026-11-02-relax-grammar-and-loop-prompt): the lib's `git_harden` comment no longer names "SKILL.md's hg" (it now reads "the gate's own merge commit also passes --no-gpg-sign"), and plan D13's `--state` bullet (line 107) already lists what today's `state_gate`, `caller_gate` and `default_gate` refuse. Checked against the code; no change is needed, and none is made.

## Design choices

**Where an `@` starts a token** (three options; divergent design, Path A).

| Option | Over-read | Under-read vs Claude Code | Cost |
|---|---|---|---|
| [1] every `@` starts a token | emails, `a@b` | none for plain imports | none |
| [2] only at line start or after ASCII whitespace (Claude Code's rule) | none | none for plain imports | one test |
| [3] [2] plus Markdown awareness (skip code spans and fences) | none | none | a lexer: the superset parser again |

[3] fails S3/S8's spirit (the parser this unit removes). [1] and [2] both survive; [1] over-reads only names that floor then refuses (an email's domain read as a path), which costs nothing in an honest repository and needs no claim about Claude Code's start rule, whose trace this unit no longer keeps (H4: no claim to re-check). Pick [1], dominant on simplicity at no in-scope cost. A token also counts with trailing punctuation (`.,;:!?)]}>` and quotes, backticks, asterisks) stripped, so `see @docs/a.md.` is read as `docs/a.md` (a false negative there would let an honest import's target self-merge).

**Escaped spaces, quoted `@"..."` mentions, HTML-comment splicing, Unicode spaces, invalid-UTF-8 decoding**: dropped (G59: hostile-only shapes). A file that is not valid UTF-8 refuses instead (H2).

**A `~/` token with HOME unset, empty or relative**: the walk refuses (H2: it cannot resolve what it needs). One-line note: the passwd fallback goes; a session's HOME is set.

**Which untracked start files count** (G56 "at the checkout root"): every untracked or ignored start file `git ls-files --others` lists from the checkout's top level, not only top-level files: `CLAUDE.local.md` may sit in a subdirectory, the listing is one git call either way, and a wider start set only refuses more. Only plain regular files are read; others are skipped.

**Prompt starts**: their names resolve against the file's own directory and the repo root (G62). Files a prompt imports resolve against their own directory.

**Tree walk (`--check-fix`)**: the same rules over the checkout (tracked and untracked start files), reading only the checkout. It no longer needs main found by name (that came from `reader_settings`).

**`--settings`'s `readers` line** (two options, one-line note): keep a fifth line always (`readers none: ...` or `readers ignored: ...`), so the five-line shape the orchestrator and tests read is unchanged; the alternative, printing it only when legacy lines exist, changes the shape for no benefit.

**Size cap**: 4 MiB (4194304 bytes), Claude Code's own; a larger file refuses rather than being read in part (H2).

## Pre-mortem (enforcement file: the self-merge floor's walk)

Bypass families an honest slip could take, and what catches each:

1. An import written `@path` after punctuation (`(@docs/a.md)`): option [1] reads every `@`.
2. An import with trailing punctuation: the stripped form is read too.
3. An import through `..` or an absolute path into the repo: resolved lexically against `ROOT_REAL`, and an absolute one also against the main worktree's path.
4. A transitive import: the queue follows every reached file.
5. An imported file the walk cannot read (permissions, a directory it cannot search, non-UTF-8, over 4 MiB): refuses every path (H2).
6. A symlinked start or target: refuses (H2), never followed.
7. An untracked `CLAUDE.local.md`: read when it is a plain file.
8. Out of scope (S1, residuals stated): an import obfuscated on purpose (escaped space, quoted mention, Unicode space, comment splice), an instruction file outside the checkout (`~/.claude/CLAUDE.md`, an ancestor's, another worktree's, a plugin's) importing a repo doc, and a host session spelling the repo another way.

## Plan

1. Lib: replace the walk (`import_targets`, `imported_names`, `main_imports`, their helpers) with the plain walk; strip `reader_settings` to the legacy-line notice; update the header contract (items 4 and 9) and `walk_why`.
2. `build-loop.sh`: `reader_settings` runs only for `--settings`; header's `readers` text. `dev-cycle.sh`: drop the call and the header text.
3. Tests: drop the removed rules' cases (`build-loop-check.bats`, `build-loop-read.bats`, `dev-cycle.bats`); add plain-walk cases (direct and transitive import refused, unreadable and non-UTF-8 import refusing every path, symlinked target refusing, legacy Reader line ignored).
4. Docs: SKILL.md (Project settings, `--check-fix`'s text, step 0.3's reader-set note), plan D5 amendment (and F11, U2b3 and `--settings` pointers), decision-log row 83, a supersession note on known issue A5 (`docs/working/known-issues-dev-cycle.md`).

Review iteration 1 (a general-purpose review of afa1c15a) found two in-scope gaps, both fixed: an imported name below a directory the walk cannot search read as absent (a fail-open, H2), and now fails the walk; and an absolute import spelled under the main worktree (`@/workspace/docs/x.md`, read by every session in the main checkout) was dropped by a gate running in its own worktree, and is now a repo path (the main worktree's real path, the parent of the common `.git`; one `git rev-parse`, no registry). Its stale contract item 2 and known issue C2 were reworded.

As built, one more change from the design above: a token is also cut before its first `#` or `]` (an anchor, the text of a Markdown link), and `_` joins the stripped punctuation, so `@docs/a.md#intro`, `[@docs/a.md](x)` and `_@docs/a.md_` each read `docs/a.md` (the existing `--check-fix` case for these honest spellings).

## Verification

`bats` over the touched suites, then `scripts/health-check.sh`; `scripts/hermeticity-lint --root .`.
