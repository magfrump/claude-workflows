Commit: 2b6f2f91

# Security Review: feat/build-loop-u2a4 (U2a4, the self-merge floor), final confirming pass

**Scope:** `git diff main...HEAD` (main = 7afdb8d2, HEAD = 2b6f2f91). Files: `scripts/lib/dev-cycle-read.sh` (isstart, PROMPT_DIR, prompt_dir, prompt_bases, IMPORT_AWK scan/names/emit and IT_XDIRS, import_targets, instruction_names, both walks, import_reset, truthrule, truthwalk, ownfile, GATE_CODE, floor, the gate caller contract), `scripts/dev-cycle.sh` check_fix, known issues A2 and A5, and the override rows dated 2026-10-07.
**Date:** 2026-10-08
**Based on:** the Stage 1 summary for this pass (k=3; `docs/reviews/code-fact-check-report-build-loop-u2a4-final-r{1,2,3}.md`, 0 Incorrect), the iteration-1 security review (`security-reviewer-review-2026-10-07-build-loop-u2a4.md`, F1-F4), and the rubric and override rows for this branch.
**Probe provenance:** every probe ran under `timeout` with `LC_ALL=C`, `TMPDIR=/tmp/u2a4f-sec-3ZGL`, and a hermetic git env. Each fixture repo was built as `test/scripts/build-loop-check.bats`'s `floors`/`imps` helpers build theirs, and the lib was sourced the same way. Scripts are in the session scratchpad (`u2a4f-sec/h.sh`, `p1.sh`-`p4.sh`, `jfn.js`). `bats test/scripts/build-loop-check.bats`: 78 ok, 0 not ok. `build-loop-read.bats`: 19 ok. Nothing was left running (`ps` checked).

## Trust Boundary Map

```
B1:         [branch's changed paths, agent-authored]                → [floor: lower → truthrule → GATE_CODE / thoughts / ownfile → truthwalk main] → [self-merge lands the path (U2b/U2c callers)]
B2:         [start files on main + checkout-only starts]            → [isstart / prompt_dir / prompt_bases → import_targets (scan, names, emit)]  → [IMPORTED_MAIN / IMPORTED lists]
B3:         [in-cycle fix path, agent-chosen]                       → [check_fix: pathform → lower → truthrule → truthwalk tree]                    → [the dev cycle edits the file]
B4:         [the same files, as Claude Code reads them]             → [memory-import loader; prompt-mention attach (Jfn/Zfn → NPr → path.resolve)] → [a later session's instructions]
B5 (new):   [main's tree entries: a link or gitlink at a prompt or rules directory] → [main_imports' start listing (ls-tree -r, .md only)]       → [whether a directory's files are starts at all]
```

The gates hold only if B2 and B5 read at least what B4 reads. A B4 read that B2 or B5 misses is the failure class: floor answers 1, or --check-fix answers ok, for a path a session loads as instructions.

| Source | Mutability | Trust (per sink) |
|---|---|---|
| S1: changed path names on the branch | request-time (agent branch) | UNTRUSTED toward floor's refuse/pass decision |
| S2: main's start-file text (instruction files, rules, commands, agents, output-styles, skills) | runtime-mutable (any merge, including earlier self-merges) | trusted as content; UNTRUSTED toward parser completeness (its grammar is whatever the author wrote) |
| S3: main's tree shape (modes: a link at `.claude/commands`, `.claude`, `.claude/rules`) | runtime-mutable, but only through a reviewed merge (floor's dot rule refuses `.claude/...`) | UNTRUSTED toward start-set completeness |
| S4: checkout-only files (untracked/ignored starts, symlinks) | request-time | UNTRUSTED (all sinks) |
| S5: Claude Code 2.1.293's loaders (memory regex; `Jfn`/`Zfn`/`NPr` prompt-mention reader, extracted from `bin/claude.exe`) | deploy-time (upgrades) | the oracle B2 must superset; a correctness input, not attacker-controlled |
| S6: HOME, LC_ALL, git env | deploy-time | trusted; caller contract items 1-4 |

## Findings

#### F1: A start directory that main stores as a symlink takes its files out of the start set, so the floor lands a command's body (and anything it names)

**Severity:** Medium
**Location:** `scripts/lib/dev-cycle-read.sh:893-913` (main_imports' start listing: `[[ "$f" != *.[mM][dD] ]] || cand+=("m:$f")` and `if isstart "$f"; then`), `:484-485` (isstart), `:844-852` (imported_names' starts); known issue A5's "Not covered: start files under a symlinked directory" (`docs/working/known-issues-dev-cycle.md:18`); override row 350
**Boundary:** B5, B4 (consumed by B1 and B3)
**Move:** 11 (bypass enumeration), 5 (what the start rule does not cover)
**Confidence:** Medium. The walk behaviour is executed. That Claude Code follows a symlinked `.claude/commands/` directory is inferred, not traced.
**Legibility-target:** for-author

U2a4 makes starts out of *directories* (`.claude/{commands,agents,output-styles,skills}/`, plus `.claude/rules/` in the tree walk). The older starts were defined by *basename*. When main stores a start directory as a symlink, `ls-tree -r` lists the link (mode 120000, not `.md`) and the target's files under their real paths. isstart does not match those paths, so neither the command file nor the doc it names is walked or refused. Executed (`p4.sh`), with `.claude/commands -> ../prompts` and `prompts/c.md` = `run @docs/q.md` on main:

```
120000 blob 0cec306e...	.claude/commands
100644 blob e2e5fbd0...	prompts/c.md
floor prompts/c.md: -
floor docs/q.md: -
```

With a real directory instead (`p4.sh` P14), the same layout gives `floor docs/q.md: an instruction file on the default branch imports it with @ ...`. When the link targets `docs/` (`.claude/commands -> ../docs/prompts`, P12), --check-fix also answers `ok docs/prompts/c.md` and `ok docs/q.md`. A symlinked `.claude` itself (`.claude -> cfg`, P13) gives `floor cfg/commands/c.md: -`.

A5 lists "start files under a symlinked directory" as not covered, and row 350 defers the whole symlinked-directory class. The new evidence is about cost. Under a basename rule the gap lost only a resolution base: `x/CLAUDE.md` behind a directory link is still a start at its real path, because its basename makes it one. Under a directory rule the gap loses the file itself, so the floor lands the **command body**, which is instruction text, as a plain doc. U2a4 quadrupled that directory-defined start set. Sharing commands through a symlinked `.claude/commands/` (or `.claude/skills/`) is also a common, benign layout that a reviewer would approve. Precondition: the link is on main. The floor's dot rule keeps a self-merge from adding it, so the agent's part is then to self-merge `prompts/c.md`.

**Recommendation:** In main_imports' record loop, fail the walk when main stores a link or gitlink at a path whose lower-case form matches `(^|/)\.claude(/(rules|commands|agents|output-styles|skills))?$` or lies below one. That is fail-closed, matches the existing rule for a symlinked prompt start (`:928`), and costs one regex per record. Alternatively, follow the link and treat the target's `.md` files as prompt starts with the link's prompt_bases. Then either narrow A5's sentence to say directory-defined starts now fail the walk, or record the new evidence against row 350.

#### F2: A quoted mention that spans a line break is not yielded: `@"x⏎/../docs/q.md"` loads docs/q.md in Claude Code's reader, but the line-based scanner never sees it

**Severity:** Medium
**Location:** `scripts/lib/dev-cycle-read.sh:664-686` (scan, names: `if (q) { if (ch == "\"") break }` inside a per-record loop), `:703` (`{ scan($0); ... }`: one awk record per line); comment `:669-673` ("up to the closing quote, blanks included")
**Boundary:** B2, B4
**Move:** 11, 2 (an implicit assumption that a name never crosses a line)
**Confidence:** Low. The scanner side is executed. The reader side is the extracted `Jfn` regex, run in node. Whether a command's expansion is passed through `Jfn` stays the untraced hop (Stage 1: Unverifiable). The shape is also unlikely in a reviewed command.
**Legibility-target:** for-author

Claude Code 2.1.293's quoted-mention regex is applied to the whole prompt text, and `[^"]` matches a newline:

```
function Jfn(e){let n=new RegExp(String.raw`(^|${JY})@"([^"]+)"`,"g"),r=[],s;while((s=n.exec(e))!==null)if(s[2]&&!s[2].endsWith(" (agent)"))r.push(s[2]);...
```

NPr's `^([^#]+)` also crosses newlines, and `path.resolve` removes a component that holds a newline once a `..` follows it. The awk scanner reads one record per line, so the quoted run ends at end-of-line. Executed (`p2.sh` P5), with `.claude/commands/c.md` on main = `Review @"x\n/../docs/q.md" ...`:

```
floor docs/q.md: -
tree docs/q.md: -
main docs/q.md: -
ok docs/q.md
```

The node emulation of `Jfn` + `NPr` + `path.resolve` (`jfn.js`) gives `"x\n/../docs/q.md" -> docs/q.md`. The same miss happens for an untracked command in the checkout phase (P11). A break *after* the name is covered: with no closing quote on its line, the run reads to end-of-line and emits every prefix, so `@"docs/q.md⏎"` is yielded. Only a name whose resolved path survives a line break plus `..` escapes. The shape has to be crafted into a reviewed `.claude/` file (the dot rule blocks a self-merge from adding it), which is why confidence is Low. Severity stays at the Medium floor because the mechanism is named and executed.

**Recommendation:** When a quoted run reaches end-of-record without its closing quote, continue the run into the following records, joining with `\n` and charging work as now. Alternatively, run the quoted pass over the whole file as one record (`RS` set to a byte that cannot occur, under the existing caps). Add a test with `@"x\n/../docs/q.md"` in a command.

#### F3: The superset statement and its revisit trigger name only the memory-import grammar, while the parser now also models a second reader (prompt mentions)

**Severity:** Low
**Location:** `scripts/lib/dev-cycle-read.sh:593-625` (the superset paragraph, "the one statement"; revisit trigger at `:622-625`); A5's revisit trigger (`known-issues-dev-cycle.md:18`)
**Boundary:** B2, B4
**Move:** 2
**Confidence:** High (read-static; Stage 1 r1 rates the paragraph Stale)
**Legibility-target:** for-author

The paragraph that A5 and F11 point to as "the one statement" says names are made absolute as `ROOT_REAL/$1/name`, and that each candidate runs "up to the first blank". It omits the extra base directories and the quoted run. Its revisit trigger reads "Re-check the superset when Claude Code changes its import grammar, how its runtime reads an empty or unset HOME, or how it decodes invalid UTF-8". The prompt-mention reader (`Jfn`, `Zfn`, `NPr`'s `#L` stripping, session-directory resolution) is a separate grammar in the binary that the parser now claims to superset. No trigger names it, so a Claude Code upgrade that changes only that reader would not prompt a re-derivation. F2 is that kind of grammar difference, missed because only the memory grammar's line-bounded shape was modelled.

**Recommendation:** Add the quoted run, the extra bases, and the prompt-mention reader (with 2.1.293 as its oracle version) to the superset paragraph. Name "the prompt-mention reader" in both revisit triggers.

#### F4 (re-check of iteration-1 F4): the deferral row still holds, but its revisit trigger misses the common untracked case

**Severity:** Low
**Location:** `docs/reviews/override-log.md:468` (row "The tree walk skips a symlinked prompt start"); `scripts/lib/dev-cycle-read.sh:849`
**Boundary:** B3, B4
**Move:** 3, 11
**Confidence:** High (executed)
**Legibility-target:** for-orchestrator-synthesis

Iteration-1 F4 still reproduces as deferred. With `.claude/commands/l.md -> ../../prompts/l.md` (`p1.sh` P4), `floor docs/l.md` refuses as a walk failure, and `tree docs/l.md: -` with `ok docs/l.md`. The row's premise is still true: `git ls-files` at HEAD lists no `.claude/` file, and `/workspace/.claude/commands` and `agents` are empty and ignored. Its revisit trigger is "a tracked `.claude/` prompt file". The tree walk deliberately starts from untracked and ignored files, though, and the usual per-user setup is an *ignored* command symlinked to a dotfiles directory. Executed (P9), with `.claude/` gitignored and `.claude/commands/c.md -> $TMPDIR/outside/c.md` holding `run @docs/q.md`:

```
floor docs/q.md: the default branch's instruction files could not be walked for @ imports
tree docs/q.md: -
ok docs/q.md
```

The floor fails closed, but --check-fix passes, and the row's trigger would not fire.

**Recommendation:** Widen the row's revisit trigger to "a tracked, untracked or ignored `.claude/` prompt file that is a symlink in a checkout the dev cycle runs in". Alternatively, have the tree walk fail (answer `skip` for every path) on a symlinked start, as the main walk does.

## Untested bypass candidates

- **Claude Code following a symlinked prompt directory** (F1's premise). Not executed: there is no authenticated headless run in this sandbox. Readdir-with-follow is the expected behaviour.
- **Command expansion passing through `Jfn`/`hPr`** (F2's hop, and iteration 1's). `hPr(e,…)` calls `Jfn(e)` on the turn's input. Whether a slash command's body is that input is not traced.
- **A session started in a subdirectory of a prompt's enclosing directory.** Names would resolve against `a/b/`, which no base covers. Not tested; U2b's reader model, as documented.
- **Transitive `@` names in a file a command attaches.** The walk resolves them against the attached file's directory. Not tested; the attach path's recursion is untraced.
- **Unicode case folding on a case-insensitive checkout** (`lower` is ASCII `tr`). Already in A5.
- **The repo loaded as a plugin root** (top-level `commands/`, `agents/`). A deployment question, not tested.

Tested and cleared on this pass, besides the findings:

- Iteration-1 F1-F3 fixtures: a quoted `@"docs/q.md"` and `@"docs/s p.md"` in a command, a skill body's `@docs/k.md`, a nested `a/.claude/commands/b/.claude/commands/x.md`, and a doubled `c/.claude/.claude/commands/y.md`. Each is refused by floor and imported by the tree walk (`p1.sh` P1-P3).
- A mixed-case `Sub/.Claude/Commands/X.MD` (refused under both spellings, P6).
- An untracked nested command in the checkout phase (P7).
- `.claudex` over-read (P8: both bases imported, which is the safe direction).
- Zfn's unquoted grammar, statically: it splits on JS `\s`, its name is `s.slice(g+1,S)`, a prefix of the run after `@`, and the scanner emits every prefix of every `@` run.
- NBSP inside a quoted run (sed maps it to a space). This changes no `..` decision, and a name that keeps one fails pathform.

## Endorsement Claims

(Per move 11, floor and --check-fix as guardrails have findings and untested candidates above, so neither is endorsed. The claims below are scoped to single mechanisms.)

- **Claim:** At 2b6f2f91, the fixtures for iteration-1 F1 (quoted mention), F2 (skill body) and F3 (nested and doubled `.claude/`) are refused by floor with the `imported` reason, and are imported by the tree walk (--check-fix answers skip).
  **Location:** `scripts/lib/dev-cycle-read.sh:495-503`, `:664-686`, `:484`
  **Evidence:** executed
  **Verified:** `p1.sh` P1-P3 output (quoted above in "Tested and cleared"), and build-loop-check test 77 passing
  **Not verified:** the same fixtures with the prompt directory itself stored as a symlink (F1 shows they pass then)
  **route: code-fact-check**
- **Claim:** In floor, every path that no earlier arm refuses reaches `truthwalk main`, including a brief's own working or review file (the `docs/working/*` and `docs/reviews/*` arms fall through when ownfile holds), and the function's only `return 1` is the final `else`.
  **Location:** `scripts/lib/dev-cycle-read.sh:1039-1061`
  **Evidence:** read-static (the whole function, and ownfile `:1018-1023`)
  **Verified:** each `elif` condition, and that a true ownfile makes the compound test false
  **Not verified:** U2c's composed per-path entry, which must call floor before pathform and main_entry (contract item 5)
  **route: code-fact-check**
- **Claim:** truthwalk returns 0 with `TRUTH_WHY=walk` when its walk fails or the walk name is unknown. It returns 1, with TRUTH_WHY empty, only after a successful walk whose membership test misses.
  **Location:** `scripts/lib/dev-cycle-read.sh:1007-1011`, `:969-978`
  **Evidence:** executed (build-loop-check test 78) and read-static (both bodies)
  **Verified:** test 78 passing at HEAD, and the two function bodies
  **Not verified:** a caller running truthwalk in a subshell, which would lose the cache and TRUTH_WHY (contract items 5 and 6 forbid it; no caller exists yet)
  **route: code-fact-check**
- **Claim:** check_fix's refactor refuses every path main's check_fix refused (Stage 1: byte-identical --check-fix output over all 3,104 tracked paths; a failed `lower` now refuses where main had no check).
  **Location:** `scripts/dev-cycle.sh:171-183`
  **Evidence:** executed (Stage 1 replicates)
  **Verified:** Stage 1's comparison, and the static mapping of each old condition to a truthrule word in iteration 1
  **Not verified:** a repo that tracks prompt files, where the branch is meant to refuse more
  **route: code-fact-check**

## Primitive sweep

Primitive: file read and path construction from parsed text (sink: what the walks read and record)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `dev-cycle-read.sh:859` tree walk `capped_read < "$f"` | S2, S4 | isstart + inrepo_here | cleared for reads; F4 (symlinked start skipped) |
| `dev-cycle-read.sh:922` main walk checkout arm | S4 | main_checkout (plain file, plain searchable ancestors) | cleared; P9 fails closed |
| `dev-cycle-read.sh:924` main walk blob arm `git cat-file blob` | S2 | `ent[$f]` 100644/100755 | cleared |
| `dev-cycle-read.sh:926-946` main walk 120000 arm | S2, S3 | prompt start refused (`:928`); link text checks | cleared for start links; F1 for a linked *directory*, which never reaches this arm |
| `dev-cycle-read.sh:893-899` `ls-tree -r` start listing | S3 | `.md` name filter + isstart | F1 |
| `dev-cycle-read.sh:642` `put(root "/" dirs[i] "/" c)` | S2/S4 names; prompt_bases | lexical normalisation, `pre` prefix, budgets | cleared for traversal; F2 is a completeness gap |
| `dev-cycle-read.sh:746` IT_XDIRS via `env` | prompt_bases values (no newline: the walks refuse one) | ENVIRON, x-prefix encoding | cleared |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| F1 | A symlinked start directory (`.claude/commands -> ../prompts`, `.claude -> cfg`) drops its files from the start set; floor lands the command body and what it names | Medium | B5, B4 | `dev-cycle-read.sh:893-913`, `:484-485`; A5; row 350 | Medium |
| F2 | A quoted mention spanning a line break (`@"x⏎/../docs/q.md"`) is never yielded; floor and --check-fix pass | Medium | B2, B4 | `dev-cycle-read.sh:664-686`, `:703` | Low |
| F3 | The superset paragraph and revisit triggers name only the memory grammar, not the prompt-mention reader the parser now models | Low | B2, B4 | `dev-cycle-read.sh:593-625`; A5 | High |
| F4 | Iteration-1 F4's deferral holds, but its trigger misses an ignored symlinked command in the checkout (--check-fix ok) | Low | B3, B4 | `override-log.md:468`; `dev-cycle-read.sh:849` | High |

## Overall Assessment

The iteration-1 fixes hold. The quoted run, the skill base and every enclosing `.claude/` are now read, and the refactor keeps every refusal main made. Floor's arm order and truthwalk fail closed. The remaining weak point is still the start rule's coverage, from two new directions.

First, U2a4 made starts out of directories, but the walks enumerate files by real path. A prompt directory stored as a link therefore takes its command bodies out of both walks and out of the floor's own `instr`/`dot` refusal (F1). This is the most important item: it is a natural layout, and it lands instruction text directly, not just a doc that text names. The fail-closed fix is one regex in the record loop.

Second, the quoted-mention grammar crosses lines and the scanner does not (F2). This is narrow and crafted, but it is a gap against the reader the parser itself claims to model.

Both are fixable in place, and neither is architectural. No findings beyond these within the code paths read. The endorsement claims are pending execution verification.

## Goal-Alignment Note

- Success criterion (restated verbatim): "your report saved at the path your task names, structured per your skill, with every finding grounded in verbatim evidence."
- Answered: yes. Every focus area was checked:
  - isstart/instruction_names: Stage 1 shows them equal, and F1 covers what neither lists.
  - prompt_dir/prompt_bases: P3, P6, P7, P8.
  - The parser's extra bases and quoted run: P1, plus F2 for the line-spanning case.
  - truthrule ordering against floor's own rules, and floor's fall-through: endorsement 2.
  - truthwalk: endorsement 3.
  - check_fix's refactor: endorsement 4.
  - floor's lower-case arms: they refuse on a tr failure and on `case`, and pathform runs after floor per contract item 5.
  - import_reset: test 78.
  - Iteration-1 F1-F4: F1-F3 hold, and F4's row is right but its trigger is narrow.
- Out of scope / not done: an executed Claude Code run, since there is no authenticated headless session here. F1's premise (a symlinked commands directory is followed) and F2's hop (command expansion goes through `Jfn`) stay untraced.
- Escalate: F1 revisits a deferred row (350) with new evidence. The orchestrator should decide whether the one-regex fail-closed fix goes into this unit or is routed with the row, before U2b/U2c give floor a caller. Self-merge stays off until Q-103 either way.
- Decisions I made: F1 is filed as a finding rather than left settled, because the cost of the A5 gap changed with directory-defined starts. F2 is held at the Medium floor with Low confidence, because the mechanism is named and executed but the shape is crafted and the hop is untraced. F4 is filed as a trigger refinement, not as a reopened deferral.
