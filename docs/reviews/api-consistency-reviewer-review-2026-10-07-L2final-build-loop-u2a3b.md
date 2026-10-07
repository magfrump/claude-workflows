Commit: e1654266

# API Consistency Review — feat/build-loop-u2a3b, loop 2 final confirming pass

**Scope:** `git diff main...e1654266 -- . ':!docs/reviews'` (the full unit): the reader lib's public surface (`scripts/lib/dev-cycle-read.sh`), `--check-fix`'s output contract (`scripts/dev-cycle.sh`, `skills/dev-cycle/SKILL.md`), the sourcing inventory (`test/scripts/dev-cycle.bats`), known issue A3/A5 and plan F11.
**Date:** 2026-10-07
**Based on:** Stage 1 summary `u2a3b-L2final-stage1.md` (code-fact-check r1-r3 at e1654266); rubric `code-review-rubric-2026-10-06-feat-build-loop-u2a3b.md`; override log rows from line 374.

Executed probes ran on a `git archive e1654266` copy in `/tmp/u2a3bapifin-umnN` (each under `timeout`; no process left running).

## Baseline Conventions

- **Globals in the lib** are ALL-CAPS. Regex and pattern constants are named for what they match, not as predicates: `INSTRUCTION_FILE` (:446), `DIGIT`, `SLUG` (:165-166), `NAMECHARS` (:149); awk programs end in `_AWK` (`FENCE_AWK` :196, `ANSWER_AWK` :808). A real path carries a `_REAL` suffix (`ROOT_REAL`, :98-106 and every caller). A walk's cache key is a `*_DONE` global (`IMPORTED_DONE`, `IMPORTED_MAIN_DONE`, :483).
- **Functions** are lower snake_case. Functions that print output are nouns (`import_targets`, `instruction_names`, `untracked_md`, `tree_starts`), predicates are bare (`inrepo`, `isbrief`, `main_by_name`), and setters of globals use a verb (`resolve_main` sets `MAIN`/`MAIN_SHA`).
- **Per-call options are positional** (`blocker $1 $2`, `skipped "$1" "${2:-file}"`, `nul_list NAME CMD...`). Values passed into awk go through `-v` or, when backslashes matter, through `ENVIRON` with a short prefix (`PQ_WANT` in `scripts/paper-queue.sh:212`).
- **Errors**: walks return 1 and set their list to `error`, check modes print `skip <path>: <reason>` and exit 0, and a hard runtime dependency is named in the script's Exit paragraph and checked up front (`command -v perl`, `scripts/dev-cycle.sh:80,85`, `scripts/build-loop.sh:87`).

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `IMPORT_OUT_MAX` | global (limit) | `MAX_ROUNDS`, `MAX_DIFF_LINES`; check_path's local `max` | `scripts/self-improvement.sh:434,1180`; `scripts/dev-cycle.sh:~150` | Consistent enough: the lib has no other limit global. `IMPORT_` prefix matches its family; the `_MAX` suffix is new to the lib (others put `MAX_` first) |
| `IMPORT_LEFT` | env parameter to `import_targets` | positional options (`blocker $2`, `skipped ${2:-file}`) | `scripts/lib/dev-cycle-read.sh:114,135` | Inconsistent (contract, not name): the lib's first per-call ALL-CAPS dynamic-scope parameter, undeclared at source time (F3) |
| `IMPORT_HOME` | global (state) | `MAIN`, `MAIN_SHA`, `ROOT_REAL` | lib :256, :98 | Consistent |
| `IMPORT_HOMER` | global (state, real path) | `ROOT_REAL` | lib :98-106 | Inconsistent: the real-path suffix is `_REAL` (F1) |
| `IMPORT_HOME_KEY` | global (cache key) | `IMPORTED_DONE`, `IMPORTED_MAIN_DONE` | lib :483 | Inconsistent: cache keys are `*_DONE` (F1) |
| `UTF8_OK` | global (regex) | `INSTRUCTION_FILE`, `DIGIT`, `SLUG`, (removed) `IMPORT_RE` | lib :446, :165-166 | Inconsistent: reads as a boolean, not a pattern (F2) |
| `IMPORT_AWK` | global (awk program) | `FENCE_AWK`, `ANSWER_AWK` | lib :196, :808 | Consistent |
| `IT_DIR`, `IT_ROOT`, `IT_HOME`, `IT_HOMER`, `IT_LEFT` | awk ENVIRON names | `PQ_WANT` | `scripts/paper-queue.sh:212` | Consistent: a short owner prefix. `IT_HOMER` carries F1 |
| `import_home` | function (sets globals) | `resolve_main` (setter), `import_targets` / `tree_starts` (print) | lib :420, :611, :647 | Minor drift: a noun name for a setter. Informational only, folded into F1's recommendation |
| `tree_starts` | function (prints NUL list) | `untracked_md`, `instruction_names` | lib :639-642 | Consistent |
| `--check-fix` new skip reason | output line | other `skip <path>: <reason>; file it instead` lines | `scripts/dev-cycle.sh:179-184` | Consistent |

## Findings

#### F1. Real-path and cache-key globals break the lib's `_REAL` / `_DONE` naming

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:603-609` (also `IT_HOMER` :631 and awk `homer` :589)
**Move:** 2 (naming)
**Confidence:** High

Precedent: `ROOT_REAL` (real path) and `IMPORTED_DONE` / `IMPORTED_MAIN_DONE` (cache key) used in `scripts/lib/dev-cycle-read.sh:98-106,483`

```
IMPORT_HOME=""; IMPORT_HOMER=""; IMPORT_HOME_KEY=""
...
  IMPORT_HOME="$h"; IMPORT_HOMER="${hr:-$h}"; IMPORT_HOME_KEY="x$h"
```

`IMPORT_HOMER` holds `realpath -m` of the home, which the lib spells `ROOT_REAL` for the root. `HOMER` reads as a word rather than "home, real". `IMPORT_HOME_KEY` is a cache key, which the two walks spell `*_DONE`. A reader working from the root/real pair or the walk caches has to learn two new spellings for the same two roles. Separately, `import_home` is a setter with a noun name. The lib's setter (`resolve_main`) uses a verb.

**Recommendation:** Rename to `IMPORT_HOME_REAL` / `IT_HOME_REAL` and `IMPORT_HOME_DONE`, a mechanical change limited to the lib and `build-loop-check.bats`. Renaming `import_home` is optional.
Executed vs reasoned: reasoned (grep of the lib's globals). Legibility-target: for-author.

#### F2. `UTF8_OK` names a regex like a boolean flag

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:597`
**Move:** 2 (naming)
**Confidence:** Medium

Precedent: pattern globals named for what they match, `INSTRUCTION_FILE`, `DIGIT`, `SLUG`, `NAMECHARS`, used in `scripts/lib/dev-cycle-read.sh:149,165-166,446` (and `IMPORT_RE`, which this unit removes)

```
UTF8_OK='^([\001-\177]|[\302-\337][\200-\277]|...)*$'
```

Elsewhere in the lib a `_OK`-shaped name is a predicate (`dirok`, :134). `UTF8_OK` is an awk ERE passed as `-v ok=` (:622), so a reader could take `[[ -n $UTF8_OK ]]` or `$UTF8_OK` as a flag.

**Recommendation:** Name it for what it matches, for example `UTF8_TEXT` or `WELL_FORMED_UTF8`.
Executed vs reasoned: reasoned. Legibility-target: for-author.

#### F3. `import_targets`' contract: the environment it reads and the globals it writes are not stated together

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:498-533` (header), `:611-633` (body)
**Move:** 3 (consumer contract) / 7 (asymmetry)
**Confidence:** High

The header's lead says the function reads "the text on stdin, for a file in directory $1". Its other inputs are scattered:
- `ROOT_REAL` appears in the superset paragraph.
- HOME is read via `import_home`.
- `IMPORT_LEFT` appears only in the return list ("print past IMPORT_LEFT") and in a body comment ("IMPORT_LEFT, set by a walk ...").
- Its default is visible only in code: `IT_LEFT="${IMPORT_LEFT:-$IMPORT_OUT_MAX}"`.

`IMPORT_LEFT` is never declared, so the sourcing inventory cannot list it. It is also the lib's only per-call option passed by dynamic scope rather than positionally (precedent: `blocker $1 $2`, `skipped "$1" "${2:-file}"`).

Two behaviours, executed on the archive copy:
- **Called in the caller's shell rather than in a pipeline**, `import_targets` mutates caller globals through `import_home`. Output: `rc=0 (pipeline) HOME=[]` then `rc=0 (direct) HOME=[/home/node] KEY=[x/home/node]`. No comment says this, and the `import_home` comment's "A walk calls it once, so the parser's $(...) calls inherit it" implies the parser does not call it itself. It does (`import_home || return 1`, :613).
- **A non-numeric `IMPORT_LEFT`** (`IMPORT_LEFT=abc`) yields `rc=1`. This fails closed, which is right, but it is undocumented.

No caller outside the two walks exists today (`git grep import_targets -- scripts/`), so nothing breaks. U2a3c and U2a4 are the next consumers.

**Recommendation:** Add one "Reads:" line to the header naming ROOT_REAL, HOME (unset or empty: the passwd entry), IMPORT_LEFT (default IMPORT_OUT_MAX; non-numeric reads as 0) and the IMPORT_HOME* globals it may set. Alternatively take the budget as `$2`.
Executed vs reasoned: executed (two behaviours above), reasoned (precedent). Legibility-target: for-author.

#### F4. The walks' failure lists omit arms this unit added; override row 41's "Fixed" for I2-C2 does not hold for main_imports

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:452-458` (imported_names header) and `:679-691` (main_imports header); arms at `:662`, `:671`, `:720`, `:726`, `:735-737`
**Move:** 3 (documentation drift) / 4 (error contract)
**Confidence:** High

- **imported_names' list** reads "the start listing (git ls-files, untracked_md, instruction_names), lower, a file read or the parser fails, or a start file's name holds a newline". It omits `import_home || return 1` (:662) and the budget arm `(( (used += ${#out}) <= IMPORT_OUT_MAX )) || { IMPORTED=error; return 1; }` (:671).
- **main_imports' list** ("... a blob cannot be read, symlink text it follows is empty ...") omits:
  - `import_home || return 1` (:720)
  - the parser failing in `git cat-file blob ... | IMPORT_LEFT=... import_targets "$d"` (:726)
  - the same IMPORT_OUT_MAX arm
  - the per-file `i="$(lower "$out")" || { IMPORTED_MAIN=error; return 1; }`

  Only the start list's lower is named ("the lower-cased start list comes back short").

Override row 41 records I2-C2 (main_imports' header omits the lower guard and the parser) as "Fixed (on main)" by U2a3's c42f017f. At e1654266 the parser and the import-loop lower are still absent from that header. This is new evidence against the row, not a re-raise of a waived item. Stage 1 reports the same omission (r1 12/26, r2 14/15, r3 12/25).

Consumer impact: none at runtime, because every arm fails closed. U2a4's floor is the first caller that must word a failure (override row 3's revisit trigger), and it will read these lists.

**Recommendation:** Append "import_home fails, the walk's output passes IMPORT_OUT_MAX" to both lists, and add "the parser or a lower fails" to main_imports'. Correct row 41's scope in a new override row.
Executed vs reasoned: reasoned (read both functions whole, signature to last line). Legibility-target: for-author.

#### F5. Known issue A3 still says absolute-path imports into the repo print `ok`

**Severity:** Minor
**Location:** `docs/working/known-issues-dev-cycle.md:17` (row A3)
**Move:** 3 (documentation drift of `--check-fix`'s contract)
**Confidence:** High

```
| A3 | 🟡 Medium (rare) | Imports through a symlinked file or directory, and absolute-path imports into the repo, print `ok`. ...
```

This unit removed "absolute imports" from A5, F11 and main_imports' not-covered list, but A3 still lists them. Executed at e1654266: `AGENTS.md` holding `See @<repo>/docs/abs.md` printed `skip docs/abs.md: an instruction file names it after an @ ...`, and `ok docs/n.md` for the control. A3 is the consumer-facing list of what `--check-fix` gets wrong, so it now overstates a gap. Stage 1 reports the same (r1 1, r2 1).

**Recommendation:** Drop "and absolute-path imports into the repo" from A3 (they are refused since U2a3b) and keep the symlink half.
Executed vs reasoned: executed. Legibility-target: for-author.

#### F6. The python3 dependency is documented only in the lib header, and that header scopes it to instruction files

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:12-13`; `scripts/dev-cycle.sh:79-80`
**Move:** 4 (error consistency)
**Confidence:** High

```
# The import walks also need python3 when an instruction file holds text that
# is not well-formed UTF-8; without it they fail closed.
```

python3 runs for any walked file whose text fails `UTF8_OK`, which includes imported non-instruction docs (Stage 1 r2 12), not only instruction files. The script-level dependency convention names perl in dev-cycle.sh's Exit paragraph and checks it up front (`command -v perl ... "dev-cycle.sh needs perl"`, :80, :85; build-loop.sh:87). python3 appears in neither script's header, `--check-fix`'s help paragraph or the skill.

A conditional dependency rightly has no up-front check: it fails closed only when reached. The result is that the refusal does not name its cause. Executed with a `python3` shim exiting 1 and `AGENTS.md` holding `@docs/\xff.md`, the output was `skip docs/n.md: the instruction-file import walk failed, ...` and the same for README.md, with exit 0 and no cause on stdout. A real absent python3 does put bash's `command not found` on stderr. This keeps the lib's "fail closed, no reason" walk contract (override row 3, deferred to U2a4), so the item is Informational.

**Recommendation:** Say "a walked file" in the lib header, and add "python3 when a walked file is not well-formed UTF-8 (the walk fails closed without it)" to dev-cycle.sh's Exit/dependency paragraph.
Executed vs reasoned: executed. Legibility-target: for-author.

## Prior dispositions checked (API rows)

- **L2-I2-C4** (lib header names python3): holds, with F6's wording caveat.
- **L2-I2-C5** (IMPORT_OUT_MAX comment says characters, "more than", both figures, callers clear the DONE caches): holds (:484-490).
- **L2-I2-C6** (`${ROOT_REAL:-}`): holds. Executed: an empty ROOT_REAL gives `rc=1`, not a set -u abort.
- **L2-C1** (`|| return 1`): holds. Executed: awk's exit 3 path returns 1.
- **L2-C2** ("names it after an @"): holds in the help (:53-55), the skill (:75-76), the script (:184) and the tests.
- **F3-C5** (tree_starts in the inventory; walk-failed refusal in help and skill): holds. The inventory still omits `import_home`, `IMPORT_OUT_MAX`, `UTF8_OK` and `IMPORT_HOME*`. Executed: all are defined after sourcing. Pre-existing constants (`NAMECHARS`, `DIGIT`, `SLUG`) are also absent, so the list was never exhaustive. Informational; no finding filed.

## What Looks Good

- `--check-fix`'s output contract is coherent across the help, the skill and the code. The walk-failed reason is a distinct `skip <path>: ...; file it instead` line, exit status stays 0 (a skip is an answer), and non-doc paths keep their own reason first. [unverified — submitted as claim] Location: `scripts/dev-cycle.sh:51-55,179-185`; `skills/dev-cycle/SKILL.md:72-77`.
- `isimported tree` now mirrors `isimported main`: a failed walk answers imported (0), so the two walks share one failure shape. [unverified — submitted as claim] Location: `scripts/lib/dev-cycle-read.sh:772-780`.
- `IMPORTED` now starts as `error`, matching `IMPORTED_MAIN`, and a cached error returns 1 again in both walks. [unverified — submitted as claim] Location: `scripts/lib/dev-cycle-read.sh:483,651,714`.
- `IMPORT_AWK` and the `IT_*` ENVIRON names follow the `_AWK` and owner-prefix conventions, and passing paths through ENVIRON avoids `-v` escape reading. [unverified — submitted as claim] Location: `scripts/lib/dev-cycle-read.sh:534,589-590,628-632`.
- `instruction_names` and `tree_starts` now state their return codes, closing the earlier inverted-status gap. [unverified — submitted as claim] Location: `scripts/lib/dev-cycle-read.sh:634-647`.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---|---|---|---|
| F1 | `IMPORT_HOMER` / `IMPORT_HOME_KEY` break the `_REAL` / `_DONE` naming | Minor | `scripts/lib/dev-cycle-read.sh:603-609` | High |
| F2 | `UTF8_OK` names a regex like a flag | Minor | `scripts/lib/dev-cycle-read.sh:597` | Medium |
| F3 | import_targets' environment inputs and global side effect not stated together; `IMPORT_LEFT` undeclared and dynamically scoped | Minor | `scripts/lib/dev-cycle-read.sh:498-533,611-633` | High |
| F4 | Walk failure lists omit new arms; override row 41's I2-C2 "Fixed" does not hold | Minor | `scripts/lib/dev-cycle-read.sh:452-458,679-691` | High |
| F5 | Known issue A3 still says absolute imports print ok | Minor | `docs/working/known-issues-dev-cycle.md:17` | High |
| F6 | python3 dependency documented only in the lib header and scoped to instruction files | Informational | `scripts/lib/dev-cycle-read.sh:12-13`; `scripts/dev-cycle.sh:79-80` | High |

## Overall Assessment

The unit's consumer-facing contract is consistent. `--check-fix` keeps its `ok` / `skip <path>: <reason>` grammar and its exit-0-on-skip rule, the help and the skill state the broadened reading and the walk-failed refusal the same way, and the two walks now share one failure shape. Nothing breaks an existing consumer: the only callers are `check_fix` and `isimported`. All findings are Minor or Informational and can be fixed in place in comments and names:
- two naming drifts against the lib's own `_REAL` / `_DONE` / pattern-noun conventions (F1, F2)
- a scattered parser contract (F3)
- failure lists and a known-issue row behind the code (F4, F5)
- the conditional python3 dependency's documentation (F6)

None blocks merge from an API standpoint. F4 and F5 are the ones U2a4's floor will lean on.

## Goal-Alignment Note

- **Success criterion (restated verbatim):** A markdown report saved at the output path named in your role section, structured per your skill, with a `Commit: e1654266` line at the top.
- **Answered:**
  - new globals and functions audited against the lib's conventions and the sourcing inventory (F1, F2, Prior dispositions)
  - import_targets' input, output, return codes and environment, documented vs implemented (F3)
  - the walks' failure lists vs their arms (F4)
  - `--check-fix`'s output contract and help/skill wording (What Looks Good; F5)
  - the python3 dependency as documented (F6)
- **Out of scope:**
  - E1 (instruction files outside the repo as walk starts), routed to security and architecture
  - the import_home Node/Bun attribution and the stale test comments, which are fact-check items with no contract change
- **Escalate:** none.
- **Decisions I made:**
  - Treated `IMPORT_LEFT` as a contract issue (F3), not a naming one: its name fits the family.
  - Did not file the sourcing inventory's omissions as a finding, because the list was never exhaustive.
  - Filed F4 as new evidence against override row 41, not as a re-raise.
