Commit: d7cdc1ea

# Security Review: feat/build-loop-u2a4 (U2a4, the self-merge floor), iteration 1

**Scope:** `git diff main...HEAD` (main = 7afdb8d2, HEAD = d7cdc1ea): `scripts/lib/dev-cycle-read.sh` (isstart, PROMPT_DIR, prompt_dir, IMPORT_AWK's extra base dirs, instruction_names, both walks, truthrule, truthwalk, ownfile, GATE_CODE, floor, the gate caller contract), `scripts/dev-cycle.sh` check_fix, and the docs rows that describe them
**Date:** 2026-10-07
**Based on:** `docs/reviews/code-fact-check-report-build-loop-u2a4.md` (30 claims; its Escalation 1 and Claims 3, 20, 24 are inputs here) and the shared brief for this pass
**Probe provenance:** every probe ran under `timeout`, `LC_ALL=C`, `TMPDIR=/tmp/u2a4-sec-Y9hX`, in fixture repos built the way `test/scripts/build-loop-check.bats`'s `floors`/`imps` helpers build them (scripts and logs: `/tmp/u2a4-sec-Y9hX/probe/p1.sh`, `p2.sh`, `p1.log`, `p2.log`). `bats test/scripts/build-loop-check.bats`: 75 ok, 0 not ok. Nothing left running (`ps` checked).

## Trust Boundary Map

```
B1 (new):   [branch's changed paths, agent-authored]        → [floor: lower → truthrule → GATE_CODE / docs/thoughts / ownfile → truthwalk main] → [self-merge lands the path (U2b/U2c callers)]
B2 (moved): [start files' text: main's blobs + checkout-only prompt files] → [isstart / prompt_dir → import_targets (IMPORT_AWK, IT_XDIRS)] → [IMPORTED_MAIN / IMPORTED membership lists]
B3 (moved): [in-cycle fix path, agent-chosen]                → [check_fix: pathform → lower → truthrule → truthwalk tree]                    → [the dev cycle edits the file]
B4:         [the same checkout files]                         → [Claude Code's loaders (memory imports; prompt-mention attachments for commands/skills)] → [a later session's instructions]
```

The gate is sound only if B2's parser and start rule read at least everything B4's loaders read; a B4 read that B2 misses is the failure class (floor answers 1 / --check-fix answers ok for a path a session loads as instructions).

| Source | Mutability | Trust (per sink) |
|---|---|---|
| S1: changed path names on the branch | request-time (agent branch) | UNTRUSTED toward the floor's refuse/pass decision |
| S2: main's start-file text (CLAUDE.md, rules, commands, skills) | runtime-mutable (any merge to main, including earlier self-merges) | trusted as content; UNTRUSTED toward completeness of the parser (its grammar is whatever the author wrote) |
| S3: checkout-only start files (untracked/ignored prompts) | request-time | UNTRUSTED (all sinks); walked as an append-only phase |
| S4: Claude Code's loader grammar (installed 2.1.293; traced at 2.1.292) | deploy-time (upgrades) | the oracle B2 must superset; drift is a correctness input, not attacker-controlled |
| S5: HOME, LC_ALL, git env | deploy-time | trusted; caller contract items 1-4 |

## Findings

#### F1: A command file's quoted mention `@"docs/q.md"` loads docs/q.md, but the parser never yields it, so floor passes and --check-fix answers ok

**Severity:** Medium
**Location:** `scripts/lib/dev-cycle-read.sh:649-660` (scan), `:613-627` (emit); start rule `:474-483`
**Boundary:** B2, B4 (consumed by B1 and B3)
**Move:** 11 (bypass enumeration), 2 (implicit sanitization assumption: one grammar assumed for all start files)
**Confidence:** Medium
**Legibility-target:** for-author

U2a4 makes `.claude/commands|agents|output-styles/*.md` starts and parses them with the same scanner, which models Claude Code's memory-import grammar. But the comment above isstart says a command's names load "when it runs, resolved against the session's directory" (U2a3b L2-confirm F2), which is how prompt mentions resolve, not memory imports. Claude Code's prompt-mention extractor (installed binary 2.1.293, `bin/claude.exe`) also accepts a quoted form:

```
function Jfn(e){let n=new RegExp(String.raw`(^|${JY})@"([^"]+)"`,"g"),r=[],s;while((s=n.exec(e))!==null)if(s[2]&&!s[2].endsWith(" (agent)"))r.push(s[2]);let g=Zfn(e,!1).filter((h)=>!h.startsWith('"'));return D([...r,...g])}
```

The scanner builds the name from the character after `@`, so every candidate keeps the leading quote. Executed (`p1.sh`): `printf '@"docs/q.md"\n' | import_targets ""` printed `"`, `"d` ... `"docs/q.md"`, never `docs/q.md`. Fixture with `.claude/commands/c.md` = `Review against @"docs/q.md" and @docs/plain.md` committed on main:

```
floor docs/q.md: - (passes)
floor docs/plain.md: an instruction file on the default branch imports it with @ (directly or through another import)
tree docs/q.md: -
ok docs/q.md
```

The same holds for an untracked command (`p2.sh` P5: `floor docs/q.md: - (passes)`). Attack: a self-merging branch (or an in-cycle fix) rewrites a doc that a quoted command mention names, and every later session that runs the command takes the new text as its prompt. The precondition is a command on main that quotes a space-free path. Paths with spaces are refused anyway: pathform's NAMECHARS has no space. Not traced: that the command-expansion path calls Jfn. I found the extractor, but the search for its callers was denied in this session. The inference rests on L2-confirm F2's session-directory resolution, which the memory resolver (`path.resolve(dirname(realpath(importer)), name)`) does not do. The parser comment's "superset of Claude Code's import grammar" is true of memory imports, and U2a4 now applies it to files that a different grammar reads.

**Recommendation:** In `scan`, when the character after `@` is `"`, also emit the candidates of the text up to the closing quote with the quote stripped, spaces included. Over-reading is the safe direction, so this can apply to every start, not only prompts. Add a build-loop-check case for `@"docs/q.md"` in a command, and re-derive the prompt grammar (Jfn, Zfn, NPr's `#L` stripping) into the A5 oracle note, next to the memory grammar.

#### F2: SKILL.md bodies under `.claude/skills/` are starts but get no session-directory base, so a skill's `@docs/k.md` passes floor and --check-fix

**Severity:** Medium
**Location:** `scripts/lib/dev-cycle-read.sh:482` (PROMPT_DIR), `:490` (prompt_dir), `:739` (instruction_names)
**Boundary:** B2, B4
**Move:** 11, 5 (invert the model: what the start rule's base-directory list leaves out)
**Confidence:** Low
**Legibility-target:** for-author

`PROMPT_DIR='^(.*/)?\.claude/(commands|agents|output-styles)/'` gives session-directory bases to commands, agents and output-styles. It includes agents/ and output-styles/ "as an untraced superset" (A5), but leaves out `.claude/skills/`. Skills are the closest sibling of commands: Claude Code now lists commands and skills together, and a skill is invoked the way a command is. A SKILL.md is a start by basename, but its names resolve only against its own directory. Executed (`p2.sh` P4), with `.claude/skills/rev/SKILL.md` = `Apply @docs/k.md` on main:

```
floor docs/k.md: - (passes)
floor .claude/skills/rev/docs/k.md: a dotfile or a path under a dot-directory
tree docs/k.md: -
ok docs/k.md
```

If an invoked skill body's `@` names expand from the session directory, as a command's do, then docs/k.md is instruction text that both gates pass. The Severity floor rule does not bind here. That rule needs a mechanism, and whether Claude Code expands `@` in a skill body has not been traced, so confidence is Low. The asymmetry is still unjustified: an agent definition is read as a superset, and a skill is not.

**Recommendation:** Add `skills` to PROMPT_DIR, and add `skills` to the `.claude/(...)` alternation in instruction_names so the prefilter stays a superset. Or record in A5, with a reason, that skills are excluded, and queue an L2-confirm-style probe of a skill body's `@` resolution.

#### F3: prompt_dir's greedy `(.*/)?` picks the innermost `.claude/`, so a nested command's names never resolve against the outer session directory (fact-check Escalation 1)

**Severity:** Low
**Location:** `scripts/lib/dev-cycle-read.sh:482`, `:490`
**Boundary:** B2, B4
**Move:** 11
**Confidence:** Low
**Legibility-target:** for-orchestrator-synthesis

Executed (`p1.sh` P2), with `a/.claude/commands/b/.claude/commands/x.md` = `run @docs/n.md` on main:

```
floor a/docs/n.md: - (passes)
main a/docs/n.md: -
main a/.claude/commands/b/docs/n.md: imported
main docs/n.md: imported
```

A session started in `a/` that loads x.md, as a namespaced command under `a/.claude/commands/`, reads `a/docs/n.md`. It is Low, not Medium: whether Claude Code registers a command from a `.claude/` nested inside a commands directory is untraced, so the mechanism itself is unestablished. Also, floor's dot rule refuses adding such a file, so it must already be on main. The comment's "the directory holding its .claude/" reads as unique, and the code takes the innermost one (fact-check Claim 20).

**Recommendation:** Have prompt_dir record the parent of every `.claude/` component in the path (a short loop over the match), which is cheap and only over-reads. Or name the nested case in A5's "Not covered" list.

#### F4: The tree walk still skips a symlinked prompt start, so --check-fix answers ok for what it names; A2's text is stale and does not name prompt files

**Severity:** Low
**Location:** `scripts/lib/dev-cycle-read.sh:824` (`if ! isstart "$lp" || ! inrepo_here "$f"; then continue; fi`); `docs/working/known-issues-dev-cycle.md:16`
**Boundary:** B3, B4
**Move:** 3 (error/skip path), 11
**Confidence:** High (behaviour executed); the session-side load of a symlinked command is inferred
**Legibility-target:** for-author

Executed (`p1.sh` P3), with `.claude/commands/l.md -> ../../prompts/l.md` and prompts/l.md = `run @docs/l.md`:

```
tree docs/l.md: -
main walk: failed
ok docs/l.md
floor docs/l.md: the default branch's instruction files could not be walked for @ imports
```

The floor fails closed, which is good. --check-fix, the other fail-closed gate, answers ok. This is A2's known class (a symlinked start that inrepo drops), and it predates this unit, but U2a4 widens it to prompt files. For a prompt, the link's target directory does not even matter: names resolve against the session. A2 still reads "The walk never starts from `.claude/rules/**/*.md` ... or from a symlinked instruction file". Its first half is false since U2a4 (the tree walk now starts there), and its second half does not mention prompt files. That leaves the residual misdescribed exactly where the under-read is. Override-log row 463 already says the tree walk "skips" (fact-check Claim 3), so this is a doc gap, not a settled decision.

**Recommendation:** Rewrite A2 to say that the tree walk now starts at rules and prompt files, and that a symlinked instruction or prompt start is still skipped by the tree walk (--check-fix) and fails the main walk (floor). Optionally, the tree walk could read a symlinked prompt start whose realpath stays in the repo against its pdir bases, since the target directory is irrelevant for prompts.

## Untested bypass candidates

- **A session started in a subdirectory that loads a parent's `.claude/commands/`.** Names would resolve against `sub/`, which neither prompt_dir base covers. Not tested: documented as U2b's reader model (`:484-489`, A5), and it would need Claude Code's command-discovery walk traced.
- **Transitive `@` names inside a file that a command attaches.** The walk resolves them against that file's own directory. If Claude Code expanded them against the session directory, that is an under-read. Not tested: the attach path in the binary is untraced (see F1's denied caller search).
- **Unicode case folding on a case-insensitive checkout** (for example U+212A KELVIN SIGN for `k`). `lower` is ASCII-only `tr`. Not tested: already in A5's "other names one file has on a case-insensitive checkout".
- **A `.claude` directory that main stores as a symlink** (for example `.claude -> cfg`). `ls-tree -r` lists `cfg/commands/x.md`, which is not a start. Not tested: A5's "start files under a symlinked directory".
- **The repo used as a plugin directory** (top-level `commands/`, `agents/`, `skills/` without `.claude/`). Not tested: whether any session loads this checkout as a plugin root is a deployment question. In this sandbox `~/.claude/{skills,hooks,workflows}` link to `/opt/claude-workflows`, an install copy, not the checkout.
- **Grammar drift.** Installed Claude Code is 2.1.293, and A5's oracle was 2.1.292 (A5's revisit trigger). The memory regex seen in the binary, `(?:^|\s)@((?:[^\s\\]|\\ )+)`, looks unchanged. A full re-diff was not run.

Tested and cleared, besides F1-F4: an untracked plain-form command (test 73 passes), mixed-case `.Claude/Commands/` (fact-check p3), `.github/x.yml` (dot, fact-check p1), and a tr failure (both callers refuse, fact-check Claim 4). A path with a trailing newline is cleared statically: `lower`'s `$(...)` strips the newline, but contract item 5 runs pathform after floor, and pathform refuses newlines, so the branch is still refused.

## Endorsement Claims

(Per move 11, floor and --check-fix have untested bypass candidates above, so neither appears here as a guardrail. The claims below are scoped to the refactor's equivalence and to single mechanisms.)

- **Claim:** check_fix's refactor refuses every path main's check_fix refused. Each old condition maps to a new one: `writable "$a" || writable "$lp"` maps to truthrule `cycle`, because writable's patterns are lower-case-only, so `writable "$a"` implies `$a == $lp`. `"$a" == */.*` maps to `dot` on `"/$lp"`. The basename INSTRUCTION_FILE test maps to `instr` (isstart, a superset). The `working|human-author|reviews|decisions` test maps to `record` plus check_fix's own `^docs/(working|reviews)/`. The walk calls map to `truthwalk "$lp" tree`. A failed `lower` now refuses, where main had no check.
  **Location:** `scripts/dev-cycle.sh:171-185`, `scripts/lib/dev-cycle-read.sh:965-985`
  **Evidence:** executed (fact-check Claim 2a: byte-identical output over 3,097 tracked paths plus 20 synthetic) and read-static (the mapping above)
  **Verified:** identical output over that path set, and the static mapping
  **Not verified:** a repo that tracks `.claude/{commands,agents,output-styles}` files (none here), where the branch is meant to differ by refusing more
  **route: code-fact-check**
- **Claim:** truthwalk returns 0 (refuse) when the named walk fails, and for an unknown walk name. It returns 1 only after the walk succeeds and isimported's membership test misses.
  **Location:** `scripts/lib/dev-cycle-read.sh:980-984`, `:944-953`
  **Evidence:** read-static (the full function bodies)
  **Verified:** both function bodies, and floor's and check_fix's use of the return value under `elif`
  **Not verified:** U2b/U2c's future callers, which must call truthwalk in the caller's shell, as contract item 6 says
  **route: code-fact-check**
- **Claim:** floor's refusal set is a superset of the pre-split ancestor's (`feat/build-loop-u2a2-full` floor at its line 617). Reordering the walk to run last changes only the FLOOR_WHY wording, not whether a path is refused.
  **Location:** `scripts/lib/dev-cycle-read.sh:1011-1032`
  **Evidence:** read-static (both functions, rule by rule)
  **Verified:** each ancestor arm has a new counterpart (instr ⊆ isstart, dot, GATE_CODE, walk, writable/settings, user, decisions/thoughts/human-author, working, reviews)
  **Not verified:** the ancestor was itself never a merged gate, so this is not a claim of completeness (see F1-F3)

## Primitive sweep

Primitive: file read / path construction from parsed text (sink: what the walks read and record)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `dev-cycle-read.sh:834` tree walk `capped_read < "$f"` | S2, S3 (starts, imports) | isstart + inrepo_here (rawfile, no symlink part) | cleared for reads; F4 for the skipped symlink start |
| `dev-cycle-read.sh:897` main walk checkout arm `capped_read < "$f"` | S3 | main_checkout (plain file, plain searchable ancestors) | cleared |
| `dev-cycle-read.sh:899` main walk blob arm `git cat-file blob "$MAIN_SHA:$f"` | S2 | `ent[$f]` mode 100644/100755 | cleared |
| `dev-cycle-read.sh:627` `put(root "/" dirs[i] "/" c)` | S2/S3 names; prompt_dir bases | lexical normalisation, `pre` prefix check, work and print budgets | cleared for traversal; F1-F3 are completeness gaps, not traversal |
| `dev-cycle-read.sh:702` `IT_XDIRS` via `env` (not `awk -v`) | prompt_dir values (repo paths, no newline: the walks refuse one) | ENVIRON, so no escape processing | cleared |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| F1 | Quoted prompt mention `@"docs/q.md"` is never yielded; floor passes, --check-fix ok | Medium | B2, B4 | `dev-cycle-read.sh:649-660`, `:613-627` | Medium |
| F2 | `.claude/skills/` SKILL.md gets no session-dir base; a skill's `@docs/k.md` passes both gates | Medium | B2, B4 | `dev-cycle-read.sh:482`, `:490`, `:739` | Low |
| F3 | prompt_dir takes the innermost `.claude/`; nested command's outer base missed (Escalation 1) | Low | B2, B4 | `dev-cycle-read.sh:482`, `:490` | Low |
| F4 | Tree walk skips a symlinked prompt start (--check-fix ok); A2 text stale | Low | B3, B4 | `dev-cycle-read.sh:824`; `known-issues-dev-cycle.md:16` | High |

## Overall Assessment

The refactor preserves every refusal the old code made: check_fix's answers match main's, truthwalk fails closed, floor refuses at least the ancestor's set, and the main walk fails closed on a symlinked prompt. The new start rule's coverage of what Claude Code reads is the weak point. U2a4 applies the memory-import parser to prompt files, which Claude Code reads with a different grammar (F1: the quoted form), and its prompt-directory list leaves out the nearest sibling of commands (F2: skills). These are fixable in place, with a `"`-stripping emit in `scan` and a PROMPT_DIR entry, each with one fixture test. They are not architectural. The most important thing is F1, because the extractor's quoted grammar is in the installed binary and the parser demonstrably never yields the path. Its remaining doubt is one untraced hop: which extractor the command expansion calls. No findings beyond these within the code paths read. Endorsement claims are pending execution verification.

## Goal-Alignment Note

- Success criterion (restated verbatim): your report saved at the path your task names, structured per your skill, with every finding grounded in verbatim evidence.
- Answered: yes. All seven focus areas were checked: isstart/instruction_names (prefilter superset per fact-check; F2), prompt_dir (F3, Escalation 1 executed), IMPORT_AWK base dirs (F1; encoding cleared), truthrule ordering (no refusal lost; endorsement 3), truthwalk returns (endorsement 2), check_fix's refactor (endorsement 1), and floor's lower-case arm (cleared via fact-check Claim 4). The findings come from executed fixture probes.
- Out of scope / not done: tracing which Claude Code function expands a command's `@` names. The binary search for Jfn's callers was denied by the session's permission classifier, so I stopped rather than work around it. Whether skill bodies expand `@` names, and whether nested `.claude/` commands register, are also untraced.
- Escalate: F1's grammar mismatch is the failure class the brief names (an under-read in a fail-closed gate) and should be fixed or explicitly routed before U2b/U2c give floor a caller. The F1 and F2 premises both want one L2-confirm-style executed probe against Claude Code 2.1.293 (a command with `@"docs/q.md"`, and a skill with `@docs/k.md`).
- Decisions I made: F2 is Medium severity with Low confidence (the start-rule asymmetry is concrete; the loader behaviour is untraced). F3 is Low, not Medium, because the mechanism's existence (not just its likelihood) is unestablished. F4 is Low because the under-read is A2's known class and the new part is the stale record.
