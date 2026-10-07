# Known issues: dev-cycle (`scripts/dev-cycle.sh`, `skills/dev-cycle/SKILL.md`)

**Opened:** 2026-10-02 · **Source:** pass 38, the final k=1 review of the merged branch
(`docs/reviews/code-review-rubric-2026-09-29-feat-dev-cycle-digest.md`, "Pass 38"; lane
reports `docs/reviews/*-2026-10-02-digest-pass38.md`).

Nothing below is red. The user sent `@`-import handling to this list for a future session.
R1 (the `_`/`*` token cut) and A4 (the `--check-fix` slowdown) were fixed on
`fix/dev-cycle-import-re`. Fixing R1 with the security lane's tested token rule also closed
amber A1's shapes (`#fragment`, link text, `~~`, NBSP, text after a code span).

## `@`-import handling (`imported_names()`)

| ID | Severity | Issue | Where to start |
|---|---|---|---|
| A2 | 🟡 Medium | The walk never starts from `.claude/rules/**/*.md`, which Claude Code loads as instructions, or from a symlinked instruction file (`inrepo` drops it). An import from either one passes `--check-fix`. | security pass38 F3; pass-37 fact-check 5b |
| A3 | 🟡 Medium (rare) | Imports through a symlinked file or directory print `ok`. The symlinked-directory case regressed from 6f3d55e. (Absolute-path imports into the repo are refused since U2a3b.) | security pass38 F4; fact-check pass38 6b, 7 |
| A5 | 🟡 Medium | The gate's walk (`main_imports`, U2a3) closes A2 and A3's symlinked-file half for the self-merge floor (symlinked start files and targets on main are followed, `.claude/rules/` at any depth starts, and odd names (a name listed twice or as both a file and a directory, a name holding a newline), link text that is empty, absolute, leaves the repo, holds a newline or NUL or has a `..` after a symlink, an imported path main lacks under a directory main stores as a symlink or gitlink fail it). Until U2a3c the walk reads main's commit only and fails closed on the checkout: a start file main lacks (untracked, ignored, or only in the checkout's index), a `..` after a checkout link in link text, or anything but a plain directory at an imported path main lacks fails the walk (so the floor refuses every path), and a path main lacks that the checkout does not hold is recorded but not walked. A developer checkout with ignored instruction files (here, `devcontainer-config/claude-home/`) therefore always fails it; the gate needs a fresh worktree until U2a3c. Not covered: start files under a symlinked directory or in a submodule or untracked nested repo (neither `ls-tree -r` nor `ls-files --others` enters one), other names one file has on a case-insensitive checkout, and checkout conversions that change the bytes git writes from the bytes main stores: a `working-tree-encoding`, `filter` or `ident` attribute (`ident` expands `$Id$`, so `@docs/x$Id$` is read as `docs/x$Id:`), whether set in main's `.gitattributes`, `$GIT_DIR/info/attributes` or `core.attributesFile`, and `core.symlinks=false`, which writes a link's text as the file (U2a3 L2 final security F2, F3; L3 fact-check r1 and security F1). TODO(U2b): refuse unless `git check-attr` in the gate checkout shows no such attribute on every path the walk reads and `core.symlinks` is true. Both walks share one token parser (`import_targets`) that reads a superset of Claude Code 2.1.292's import grammar (U2a3b, by the user's iteration-4 decision); the claim, its rules and its exceptions are stated once, in the comment above `import_targets` in `scripts/lib/dev-cycle-read.sh`. Its cost is false positives (none among this repo's tracked docs on 2026-10-06). The oracle it was checked against was Claude Code 2.1.292's import regex and Markdown lexer, extracted from the installed package into a scratch fuzzer by the U2a2 and U2a3b security reviews; that harness is not kept, so a revisit re-extracts it from the new version. `test/agents-gemini-sync.bats` holds a separate, older finder for where an import starts (v2.1.284), not these rules. Revisit trigger: a Claude Code upgrade that changes its import grammar. Traced in Claude Code 2.1.292 (U2a3b L2-i2 fact-check, from its resolver): a symlinked instruction file's imports resolve from its target's directory (`path.resolve(dirname(realpath(importer)), name)`), as the walk does, and an `@` token's `..` after a directory link is resolved lexically, as the walk does. Untraced (no host probe yet): whether `@` references in `.claude/commands/` files load. Not covered by either walk (U2a3b L2-final security F1, executed against Claude Code 2.1.292; pre-existing on main): instruction files outside the repo that a session loads, a parent directory's CLAUDE.md and the user's memory file, whose imports reach files in the repo; routed to U2b's reader model. | security U2a iteration 2 F3, F4; architecture U2a finding 7; fact-check U2a iteration 3; fact-check U2a2 i2 Claims 2b, 9, 10; fact-check U2a3 i1 Claims 2b, 11b; security U2a3 i2 F1-F3; U2a3 final rubric C1-C5 and the split |
| C2 | 🟢 | Each `@` token costs 3+ forks, and the `seen`/`queue` handling is quadratic. Not measurable at this repo's size. | performance pass38 F3, F4 |
| C3 | 🟢 | The help text and SKILL.md describe direct imports only, but transitive imports are refused too. This fails safe. | API pass38 finding 2 |
| C4 | 🟢 | The design comment above `check_fix` (the "An in-cycle fix edits documentation only" block) predates the walk. The Pass 37 rubric line says everything was "fixed in 5652d33f", but pass-37 API findings 3 and 6 are still open. | API pass38 finding 3 |
| C6 | 🟢 | 5652d33f's message says README.md is "no longer refused", but no committed version ever refused it. The claim can't be fixed (history), only noted. | fact-check pass38 19b |

## Other

| ID | Severity | Issue | Where to start |
|---|---|---|---|
| C5 | 🟢 | Branch names left out of the paste block go into the entry as plain text, with no "unusual characters" label, so bidi characters can appear in them. | security pass38 F6; `skills/dev-cycle/SKILL.md:170-175` |

Closed by `fix/dev-cycle-import-re`: R1, A1 (shapes listed above), A4, C1 (the redundant
third `git ls-files` producer).
