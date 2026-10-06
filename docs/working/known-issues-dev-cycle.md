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
| A3 | 🟡 Medium (rare) | Imports through a symlinked file or directory, and absolute-path imports into the repo, print `ok`. The symlinked-directory case regressed from 6f3d55e. | security pass38 F4; fact-check pass38 6b, 7 |
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
