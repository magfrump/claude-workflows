Commit: 7f295cdb

# Security Review — feat/build-loop-u2a2 (iteration 2, first critic pass)

**Scope:** `git diff main...HEAD` (main 20347279, HEAD 7f295cdb): `scripts/lib/dev-cycle-read.sh` (`main_imports`, `isimported`, `import_targets`, `instruction_names`, `untracked_md`, `inrepo_here`, `imported_names`), `scripts/dev-cycle.sh` `check_fix`, the three test files, plan F10/F11 and U2 split, known-issues A5, Q-119, override-log rows.
**Date:** 2026-10-06
**Based on:** `docs/reviews/code-fact-check-report-build-loop-u2a2.md` (iteration 1), `docs/reviews/code-fact-check-report-build-loop-u2a2-i2.md` (fix range, via the Stage-1 summary), `docs/reviews/override-log.md` rows dated 2026-10-06 for `feat/build-loop-u2a`, `-u2a1`, `-u2a2`.

Threat model (from the dispatch): a build loop's branch is attacker-influenced; it must not get a file that sessions load as instructions past the self-merge gate, and `main_imports` must answer "imported" for anything it cannot model. Reference for "what sessions load": the installed Claude Code, 2.1.292, whose loader was read from strings in `/usr/local/share/npm-global/lib/node_modules/@anthropic-ai/claude-code/bin/claude.exe` (import regex `/(?:^|\s)@((?:[^\s\\]|\\ )+)/g`, `#` cut, no trailing-punctuation strip; markdown lexed with `gfm:false`, code and codespan tokens skipped; imports resolved from the resolved path's directory; per-directory loading of `CLAUDE.md`, `.claude/CLAUDE.md`, `.claude/rules`, `CLAUDE.local.md`). The regex was run in node on the probe strings below. Probes ran in throwaway repos under `/tmp/u2a2-sec-*`, under `timeout`, with `GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1`. AGENTS.md stood in for CLAUDE.md as the start file, because a hook blocks shell writes to files named CLAUDE.md. Test suite at HEAD: 107 ok, 0 not ok.

## Trust Boundary Map

```
B1: [main's instruction blobs + symlink text (S1)]     → [import_targets / main_imports' 120000 arm] → [IMPORTED_MAIN set]
B2: [checkout's untracked files and paths (S2)]        → [untracked_md, inrepo_here, blocker]        → [IMPORTED_MAIN set]
B3 (new): [branch's changed path (S3), from U2a3]     → [isimported main]                            → [floor allow/refuse]
B4: [Claude Code's real import grammar + start set (S6)] → [IMPORT_RE, UNI_SPACES, start rule (S4)]  → [the walk's model of "loaded as instructions"]
B5 (moved): [working tree (S2)]                        → [imported_names via isimported tree]         → [check_fix skip decision]
```

| Label | Source | Mutability | Trust, by sink class |
|---|---|---|---|
| S1 | main's tree, instruction blobs, symlink text | runtime-mutable (every merge to main, including earlier self-merges) | UNTRUSTED toward path construction and toward the imported/not-imported decision; trusted as "what main holds" (it is the post-merge state sessions load) |
| S2 | checkout untracked `.md` files, checkout paths main lacks | runtime-mutable (any process with the uid, the loop's own session included) | UNTRUSTED. Reading it can only add to the set, so S2 is trusted to over-refuse. A read failure has to fail the walk (F3) |
| S3 | path a branch changes (`isimported main "$2"`) | request-time (branch) | UNTRUSTED; only compared, lower-cased, against the set |
| S4 | `INSTRUCTION_FILE`, `IMPORT_RE`, `UNI_SPACES`, the `.claude/rules/*.md` rule | code-constant | trusted, but only as good as its match to S6 (F1, F2) |
| S5 | `MAIN_SHA`, `ROOT_REAL` (resolve_main, caller) | runtime (refs) | trusted after `main_by_name` and `need_root`; a non-name default fails the walk |
| S6 | Claude Code 2.1.292's loader | external, version-dependent | the reference for B4; read from the shipped binary, not documentation |

What crosses: S1 and S2 text becomes paths in `IMPORTED_MAIN`, and B3 lets a branch path through when the path is missing from that set. Every gap at B4 therefore becomes a fail-open: the floor will allow a file Claude Code loads. The diff assumes the walk's grammar is a superset of Claude Code's. In the token cases this review tested, it mostly is (the walk over-reads code spans, HTML comments, frontmatter and non-text includes). F1, F2 and the settled row-20 shape are the exceptions found.

## Findings

#### F1. A U+FEFF after an import ends Claude Code's token but not the walk's, so the loaded file is not listed

**Severity:** Medium
**Location:** `scripts/lib/dev-cycle-read.sh:469-473` (`UNI_SPACES` and its comment), used at `:481`
**Boundary:** B4, B1 → B3
**Move:** 11 (bypass enumeration), 2
**Confidence:** High (both sides executed)
**Legibility-target:** the `UNI_SPACES` comment (`:469-470`)

Evidence (verbatim): `UNI_SPACES=($'\xc2\xa0' $'\xe1\x9a\x80' ... $'\xe2\x81\x9f' $'\xe3\x80\x80')`, which holds 18 sequences: Unicode Zs plus U+2028/2029. Claude Code's token is `(?:[^\s\\]|\\ )+`, and JS `\s` also matches U+FEFF. Executed: a committed AGENTS.md line `See @docs/bom.md<U+FEFF>now`. In node, Claude Code's regex yields `"docs/bom.md"`. The walk prints `walk: ok` and `docs/bom.md: -`, because it records `docs/bom.md\xef\xbb\xbfnow`. `docs/bom.md` passes `pathform`, so once U2a3 consumes `isimported main`, a branch that adds or edits `docs/bom.md` gets through the floor, and every session then loads it as an import of AGENTS.md. U+FEFF is invisible in editors and survives copy-paste, so an earlier change could plant one without anyone noticing. The U2a security review's F2 recommendation listed `\xef\xbb\xbf` explicitly. Rubric `code-review-rubric-2026-10-06-feat-build-loop-u2a.md` row A6 marks that finding "Fixed" with 18 sequences, and no override row defers U+FEFF. So this is an incomplete fix, not a settled gap.

**Recommendation:** Add `$'\xef\xbb\xbf'` to `UNI_SPACES`, and reword its comment as "what JS `\s` matches beyond ASCII, as Claude Code's import regex uses". Add the U+FEFF case to the "Unicode space" tests (build-loop-check.bats:91 and :151).

#### F2. A `.claude/rules/` directory below the top level is not a start, though Claude Code loads it per directory

**Severity:** Medium
**Location:** `scripts/lib/dev-cycle-read.sh:552`
**Boundary:** B4, B1 → B3
**Move:** 5 (invert the model: what does the start rule leave out), 11
**Confidence:** High for the walk (executed); Medium-High for Claude Code (read-static from the 2.1.292 binary)
**Legibility-target:** the `main_imports` header comment ("every .md under .claude/rules/") and known-issues A5

Evidence (verbatim): `if [[ "${f##*/}" =~ $INSTRUCTION_FILE || "$f" == .claude/rules/*.md ]]; then`. Here `f` is the full lower-cased repo path, so only the root `.claude/rules/` matches. Executed: main stores `pkg/.claude/rules/style.md` = `Use @../../../docs/nested.md`, alongside `.claude/rules/a.md` = `Use @../../docs/top.md`. Result: `docs/top.md: imported`, `docs/nested.md: -`, `walk: ok`. On Claude Code's side, the loader loops over directories (`for(let Xn of AOe())`) and loads `Mm(Xn,"CLAUDE.md")`, `Mm(Xn,".claude","CLAUDE.md")`, `Mm(Xn,".claude","rules")` and `CLAUDE.local.md` from each one. Its own `claudeMdExcludes` help gives `"**/some-dir/.claude/rules/**"` as an example, and its directory list `[["CLAUDE.md"],["CLAUDE.local.md"],["AGENTS.md"],[".claude","CLAUDE.md"],[".claude","AGENTS.md"],[".claude","rules"]]` is applied within and above each directory. A session working under `pkg/` therefore loads `docs/nested.md`, and a branch editing it passes the floor. Nested CLAUDE.md files are already starts (by basename). Their sibling rules directory is not. No override row or known issue names nested rules directories: A5 counts ".claude/rules/ starts" as closed.

**Recommendation:** Start at `*/.claude/rules/*.md` too, e.g. `"$f" == .claude/rules/*.md || "$f" == */.claude/rules/*.md`. Add a nested-rules case to the "follows what Claude Code loads" test. The tree walk's A2 has the same shape and can share the rule.

#### F3. A checkout start file that cannot be read is skipped rather than failing the walk

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:561` (also `:582`)
**Boundary:** B2
**Move:** 3 (error path)
**Confidence:** High (executed)
**Legibility-target:** `main_imports`' return-1 comment ("a blob cannot be read")

Evidence (verbatim): `if inrepo_here "$f"; then out="$(import_targets "$d" < "$f")"`. There is no `|| { IMPORTED_MAIN=error; return 1; }` like the one on the blob arm at `:567`. `isimported` calls `main_imports || return 0`, and a function called on the left of `||` runs with errexit off. Executed: an untracked `AGENTS.local.md` (mode 000) importing `@docs/p.md` gives `Permission denied` on stderr, then `walk: ok`, `docs/p.md: -`, rc 0. The fact-check's E2 found the same. It is not exploitable as found: a session under the same uid gets EACCES on that file too, and Claude Code skips it (`tengu_claude_md_permission_error`). So nothing is loaded that the walk missed. `:582` has the same pattern: if the `lower` fork fails, an empty line is appended in place of the path. That needs fork exhaustion, which an attacker cannot reach. Both contradict the walk's stated rule, "a caller refuses rather than reading a partial list".

**Recommendation:** Give `:561` the same `|| { IMPORTED_MAIN=error; return 1; }` as `:567`. Optionally guard `:582` the same way. Two lines; it keeps the fail-closed contract literal.

## Settled rows: new evidence (not re-filed)

- **Override row `feat/build-loop-u2a`, "a backslash or trailing-`_` token form" (🟡 Must Address, Defer; self-merge stays off until Q-103).** The U2a review listed this as untested candidate C7 (trailing `_` or `.`): "Whether Claude Code strips a trailing `_` is unverified." It is now verified: Claude Code 2.1.292 strips nothing after the token. In node, `Follow @docs/style.md.` yields `"docs/style.md."`. The walk strips `[.,;:!?*_~]` (`:483`) and records only `docs/style.md`. Executed: `docs/style.md.: -`. `docs/style.md.` passes `pathform` (NAMECHARS allows `.` and `_`), so the realistic form is an import that ends a sentence, not just a file named with a trailing `_`. The other kept characters (`,;:!?*~`, plus `()[]` inside a token, e.g. `docs/a(b).md: -` and `docs/paren.md): -`) give names that `pathform` refuses. They are safe only if U2b applies `pathform` to every changed path, as the plan says it will. The row's revisit trigger (Q-103 re-route, or turning self-merge on) has not fired. I do not claim the row is wrong. But the fix is cheap and fails closed: record the unstripped token as well as the stripped one. It could be done before U2a3 rather than left for Q-103.
- A5 under-statement (fact-check i2 E1: start files under a directory that is a symlink in the checkout): already escalated by the fact-check, and under the A5 row. Not re-filed.

## Untested bypass candidates

- **`.claude/commands/*.md`, `.claude/agents/*.md`, output styles.** These are not starts. Slash-command files can include file contents with `@`. Whether that counts as "loaded as instructions" here, and whether agent and output-style files expand `@`, was not checked in the binary. Matters in target repos that track `.claude/commands/` (this repo ignores `.claude/`).
- **Non-`.md` files under `.claude/rules/`.** The walk only takes `*.md`. Claude Code's rules regex `[\\/]\.claude[\\/]rules[\\/]([^\\/]+)$` is not extension-specific. The extension filter in `_se` was not located.
- **marked HTML-escaping text tokens** (`<` to `&lt;`, quotes to `&quot;`/`&#39;`), which would make Claude Code's token differ from the raw bytes. Not checked against the bundled marked version. The resulting names hold `&`/`;`, which `pathform` refuses.
- **A crafted main tree holding one name as both a tree and a blob or symlink** (e.g. `link` as 120000 and `link/x.md`). `ls-tree -r` lists two different full paths, so the doubled-name check (`:540`) does not fire, and which entry a checkout keeps is unverified. Needs such a tree already on main. F7 refuses symlink additions from a branch.
- **`[`/`]` inside a token** under marked's `gfm:false` link and reference parsing. Not traced.

## Endorsement Claims

- **Claim:** `isimported main P` returns 0 (imported) when `main_imports` returns 1 and when the walk name is neither `tree` nor `main`.
  **Location:** `scripts/lib/dev-cycle-read.sh:594-603`
  **Evidence:** executed
  **Verified:** build-loop-check.bats test at :137 and :43 pass at HEAD (107/0). Read `isimported` in full: `main) main_imports || return 0; ...`, `*) return 0`.
  **Not verified:** U2a3's `floor` caller, which is not on this branch. That it calls `isimported main` in the caller's shell (not `$(...)`) is one hop away.
  **route: code-fact-check**
- **Claim:** `main_imports` reads instruction text from main's committed blobs, so a working-tree edit to a tracked instruction file neither adds nor removes imports.
  **Location:** `scripts/lib/dev-cycle-read.sh:534-541, 565-567`
  **Evidence:** executed
  **Verified:** test at :26 (`docs/wt-only.md: -` after an uncommitted edit; main's imports listed).
  **Not verified:** a checkout whose `.git` is a gitfile worktree with a different object store (alternates).
  **route: code-fact-check**
- **Claim:** In the shapes the tests build, symlink text on main that is empty, absolute, or holds a newline or NUL fails the walk, as does a checkout path it would read that is a symlink or lies under one; a symlink on main with ordinary relative text is followed.
  **Location:** `scripts/lib/dev-cycle-read.sh:557-564, 568-577`
  **Evidence:** executed
  **Verified:** tests at :91, :113, :162 pass at HEAD.
  **Not verified:** a directory main stores as a symlink that the checkout lacks (A5, settled); start files under a directory that is a symlink in the checkout (fact-check i2 E1).
  **route: code-fact-check**
- **Claim:** A failed tree or untracked listing makes `main_imports` return 1 instead of exiting.
  **Location:** `scripts/lib/dev-cycle-read.sh:534-536, 544-546`
  **Evidence:** executed
  **Verified:** test at :188.
  **Not verified:** a `git ls-tree` that succeeds but writes a truncated record set. The `rc=0` marker trusts git's exit status.
  **route: code-fact-check**
- **Claim:** Imports in a file reached through a symlink resolve from the target's directory, which matches Claude Code 2.1.292.
  **Location:** `scripts/lib/dev-cycle-read.sh:558-559` (d from the target path)
  **Evidence:** read-static
  **Verified:** In the binary, `EF` calls `kOe(e,n,he,S)` with `he` = resolvedPath, and `ZMe` passes it to `reo(G,s)`, which resolves each token against it.
  **Not verified:** other Claude Code versions; the `iH` symlink-canonical early return.
- **Claim:** `check_fix`'s switch from `imported_names` + `$IMPORTED` to `isimported tree "$lp"` compares the same lower-cased set, now reached only in the elif arm.
  **Location:** `scripts/dev-cycle.sh:181`; lib `:594-603`
  **Evidence:** read-static (plus dev-cycle.bats passing)
  **Verified:** read both bodies: `imported_names; [[ "$IMPORTED" == *$'\n'"$lp"$'\n'* ]]`.
  **Not verified:** `need_root` now runs later in `check_fix` (after `writable`). Whether an earlier exit mattered for any caller was not traced.

## Primitive sweep

Primitive: path construction from untrusted text (`realpath -ms` / lookups)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/lib/dev-cycle-read.sh:485` (import token) | S1, S2 | `~`/`/` skipped; `..`/`../*` dropped; `-s` lexical | F1, row-20 note (tokenizer gaps); lexical resolution matches Claude Code's resolvedPath base (endorsement 5) |
| `scripts/lib/dev-cycle-read.sh:575` (symlink text) | S1 | empty/absolute/newline/NUL → fail; outside → continue | cleared: outside the repo, a branch cannot change it |

Primitive: file read of a checkout path

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/lib/dev-cycle-read.sh:561` | S2 | `inrepo_here` (blocker + `-f`); non-plain → fail | F3 (a read error is skipped) |
| `scripts/lib/dev-cycle-read.sh:513` (tree walk) | S2 | `inrepo_here` | cleared: check_fix's walk; same skip-on-error, out of the gate path |

Primitive: git object read from a tree-derived path

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/lib/dev-cycle-read.sh:567` | S1 | pipefail; failure → error | cleared |
| `scripts/lib/dev-cycle-read.sh:571-572` | S1 | NUL count, `x` sentinel, failure → error | cleared |
| `scripts/lib/dev-cycle-read.sh:534`, `:497` | S5, constant pathspec | `rc=` marker | cleared |

No exec, eval, deserialization or network primitive in scope.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | U+FEFF missing from UNI_SPACES; Claude Code ends the token there, so the walk misses the target | Medium | B4, B1→B3 | `scripts/lib/dev-cycle-read.sh:469-473` | High |
| 2 | Nested `.claude/rules/` is not a start; Claude Code loads it per directory | Medium | B4, B1→B3 | `scripts/lib/dev-cycle-read.sh:552` | High (walk) / Medium-High (CC) |
| 3 | Unreadable checkout start file is skipped, not a walk failure | Informational | B2 | `scripts/lib/dev-cycle-read.sh:561` | High |

## Overall Assessment

The walk is built the right way: it reads main's commit, its listings are NUL-safe and checked, link and name shapes it does not model fail it, and `isimported` defaults to imported. The fix commit's fail-closed shapes hold under the tests. The weak point is boundary B4: the walk's model of Claude Code's grammar and start set. Two concrete gaps there fail open once U2a3's floor consumes the walk. U+FEFF (F1) is one sequence missing from a fix that was meant to close it. Nested rules directories (F2) is a one-pattern start rule. Both can be fixed in place in a line or two, with a test each, and neither indicates an architectural problem. The cheap fix for the settled trailing-punctuation row (also record the unstripped token) is worth folding in at the same time, now that Claude Code's behaviour is verified. Most important: fix F1 and F2 before U2a3 builds the floor on this walk. No findings beyond these within the code paths read; endorsement claims pending execution verification.

## Goal-Alignment Note

- **Success criterion (verbatim):** "a markdown report saved at the path given in your tail, structured per your skill, with `Commit: 7f295cdb` as its first line."
- **Answered:** a security review of the full branch against the stated threat model: three findings (two Medium fail-opens at B4, one Informational), new evidence on one settled row, untested candidates, routed endorsements, primitive sweep.
- **Out of scope:** the floor itself (U2a3), `pathform` application (U2b), the release-gated surfaces (plan D6/F57). The prior U2a review artifacts were read as context only.
- **Escalate:** F1 and F2 should be fixed in U2a2 before U2a3 consumes the walk. The row-20 evidence goes to whoever owns Q-103.
- **Questions / Decisions:** whether `.claude/commands/` `@` references count as "loaded as instructions" for target repos (untested candidate 1) is a scoping call for the plan's F11 row.
