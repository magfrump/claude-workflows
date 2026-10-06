Commit: 7697c6e6

# Security Review — feat/build-loop-u2a2 (iteration 3, final confirming pass)

**Scope:** `git diff main...HEAD` (main 20347279, HEAD 7697c6e6). Code: `scripts/lib/dev-cycle-read.sh` (`import_targets`, `UNI_SPACES`, `IMPORT_RE`, `imported_names`, `isimported`, `inrepo_here`, `instruction_names`, `untracked_md`), `scripts/dev-cycle.sh` `check_fix`, and the three test files. Docs were read as context.
**Date:** 2026-10-06
**Based on:** Stage-1 summary of `code-fact-check-report-build-loop-u2a2-f-r{1,2,3}.md` (E1, E2, the `[` comment item), and the `docs/reviews/override-log.md` rows dated 2026-10-06 for `feat/build-loop-u2a`, `-u2a1` and `-u2a2`.

**Threat model (from the dispatch).** If Claude Code would load a file through an instruction file's `@`-import, `--check-fix` must refuse that file. U2a3's gate walk will inherit the same rule through the shared parser. The parser must fail closed.

**Reference used.** I used Claude Code 2.1.292's real loader rather than its documentation. Function `reo` was read from `/usr/local/share/npm-global/lib/node_modules/@anthropic-ai/claude-code/bin/claude.exe`. It lexes the file with the bundled marked (`new QM({gfm:!1}).lex(h)`) and skips `code`/`codespan` tokens. It skips `html` tokens unless they start with `<!--`. It runs `/(?:^|\s)@((?:[^\s\\]|\\ )+)/g` over each inline `text` token's `.text`, cuts at `#`, and replaces `\ ` with a space.

The marked lexer bytes (offsets 210313891–210341941, `function lw()` to `class dd`) were extracted and run in node. `reo` was transcribed around them to make a differential harness, and the branch's `import_targets` was run on the same inputs. The bundled `inlineText` returns `text: n[0]`, the raw text with no HTML escaping, which settles iteration 2's untested "marked HTML-escaping" candidate. The harness lives in scratch at `/tmp/u2a2f-sec-nefJ/{marked.js,cc.js,walk.sh}`. Probes ran under `timeout`, with `GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1`, and AGENTS.md as the start file.

Test suite at HEAD: 100 ok.

## Trust Boundary Map

```
B1: [instruction-file text in the checkout (S1)]          → [import_targets: IMPORT_RE, UNI_SPACES, strip]  → [IMPORTED set]
B2: [checkout file listing: tracked + untracked .md (S2)]  → [instruction_names, untracked_md, inrepo_here]   → [walk start set / queue]
B3 (moved): [--check-fix argument (S3)]                    → [check_fix → isimported tree]                    → [skip / check_path ok]
B4: [Claude Code's real grammar: marked lexer + reo (S5)]  → [IMPORT_RE / UNI_SPACES / token-end rules (S4)]   → [the walk's model of "loaded as instructions"]
B5 (new, consumer in U2a3): [main's blobs (S6)]            → [import_targets (shared)]                         → [IMPORTED_MAIN / floor]
```

| Label | Source | Mutability | Trust, by sink class |
|---|---|---|---|
| S1 | Instruction-file text, tracked or untracked, plus every file the walk reaches | runtime-mutable: any commit, or any same-uid process for untracked files | UNTRUSTED toward path construction and toward the imported/not-imported decision. Over-reading only over-refuses. |
| S2 | `git ls-files -z` and `untracked_md` listings | runtime-mutable | UNTRUSTED. Extra names add to the starts, which is safe. Missing names fail open. |
| S3 | The path asked about | request-time | UNTRUSTED. It has already passed `pathform` and the deny list before `isimported` lower-cases and compares it. |
| S4 | `IMPORT_RE`, `UNI_SPACES`, the strip set, `INSTRUCTION_FILE` | code-constant | Trusted only as far as it matches S5. Every token S5 yields that S4 misses is a fail-open. |
| S5 | Claude Code 2.1.292 loader (marked + `reo`) | external, version-dependent | The reference for B4. Executed from the shipped bytes. |
| S6 | main's committed blobs (U2a3) | runtime-mutable, every merge | As S1. Listed because the dispatch makes the parser's gaps U2a3's gaps too. |

**What crosses the boundaries.** S1 text becomes repo paths in `IMPORTED`. B3 lets a path through when it is absent from that set. Correctness therefore rests on B4: the walk's token set has to be a superset of the names Claude Code resolves.

**Where the superset holds.** It holds for blanks, `#`, backticks, `\`-escapes, code spans, HTML blocks, frontmatter, ASCII controls, U+0085, trailing punctuation (row B13's fix, confirmed below), and `..x` names.

**Where it fails.** It fails wherever marked ends an inline `text` token in the middle of what the walk reads as one token (F1), and after a UNI_SPACES character (E1, already filed).

## Findings

#### F1. Claude Code ends an import token where marked starts an inline HTML tag, link, image or emphasis. The walk reads past it, so the imported file passes `--check-fix`.

**Severity:** Medium
**Location:** `scripts/lib/dev-cycle-read.sh:456` (`IMPORT_RE`), `:468-482` (`import_targets`); consumed at `scripts/dev-cycle.sh:181`
**Boundary:** B4, B1 → B3 (and B5 once U2a3 lands)
**Move:** 11 (bypass enumeration), 2 (implicit sanitization assumption: "a token runs to the next blank")
**Confidence:** High. Both sides were executed: the extracted marked lexer with the transcribed `reo` on one side, and `dev-cycle.sh --check-fix` end to end on the other.
**Legibility-target:** the `import_targets` comment (`:459-467`), which lists where a token ends

Evidence (verbatim code): `IMPORT_RE='(^|[^[:alnum:]])@[^][:space:]\\#`()]+'`. The token runs through `<`, `>`, `[`, `!`, `*` and `_`. Only trailing `. , ; : ! ? * _ ~` get the whole-and-stripped treatment.

The bundled marked's non-gfm inline-text rule stops before ``[\\<!\[`*_]``. A following `<br>`, `</p>`, `<span>`, `<!-- -->`, `[x](y)`, `![i](x)` or `**bold**` becomes its own token, so `reo` sees `@docs/a.md` alone.

Differential results (CC = Claude Code's resolved name; WALK = `import_targets` output):

| Input line | CC | WALK |
|---|---|---|
| `See @docs/a.md<br> x` | `docs/a.md` | `docs/a.md<br>` |
| `@docs/a.md<!-- note -->` | `docs/a.md` | `docs/a.md<!--` |
| `@docs/a.md</p>` / `<span>` | `docs/a.md` | `docs/a.md</p>` / `docs/a.md<span>` |
| `@docs/a.md[x](y)` | `docs/a.md` | `docs/a.md[x` |
| `@docs/a.md![i](x)` | `docs/a.md` | `docs/a.md![i` |
| `@docs/a.md**bold** text` | `docs/a.md` | `docs/a.md**bold`, `docs/a.md**bold**` |
| `\| @docs/a.md<br> \| x \|` (a table row, a common place for `<br>`) | `docs/a.md` | `docs/a.md<br>` |

I ran this end to end in a throwaway repo. AGENTS.md was committed with `Style: @docs/a.md<br>`, `Also @docs/b.md[link](x) and @docs/c.md**now**` and `Read @docs/d.md<!-- why -->`. The branch's `dev-cycle.sh --check-fix` then printed `ok docs/a.md`, `ok docs/b.md`, `ok docs/c.md` and `ok docs/d.md`. A control line, `Plain @docs/g.md`, was refused.

So an in-cycle fix may rewrite a file every session loads as instructions. Through `import_targets`, U2a3's floor would let a branch change it too.

This is not a regression: main's `--check-fix` prints the same four `ok` lines. It is also not in a settled row. The `feat/build-loop-u2a` Defer row lists symlinked directories, case-insensitive names, absolute imports, and the backslash and trailing-`_` forms. The fact-check's `[` item (r1 Claim 21) flags only the comment's accuracy, not this fail-open. E2 covers `(`/`)`/`]` inside intermediate names that `pathform` would refuse as direct targets.

The difference here is that `docs/a.md` is a plain, `pathform`-allowed name. The bypass works on a direct target, and the text that triggers it (`<br>` after a path in a table cell, a `<!-- -->` note, a link right after the path) is ordinary Markdown.

**Recommendation:** Fail closed the same way B13 did. For each token, also yield its prefix before each `<`, `[`, `!`, `*` and `_` (the marked inline-text stop set). Over-reading only over-refuses. For example, `docs/my_notes.md` would also yield `docs/my`, which is not a `.md` name. Add the `<br>`, `<!-- -->`, `[x](y)` and `**b**` lines to the "tree walk shares the token rules" test (`test/scripts/build-loop-check.bats:98`). Fix it in the shared parser before U2a3 consumes it, or record it under A5/Q-103 with the same Defer trigger.

#### F2. `import_targets` reports success when its grep cannot read the text, so no caller can fail closed on a read error

**Severity:** Low
**Location:** `scripts/lib/dev-cycle-read.sh:481`
**Boundary:** B1, B5
**Move:** 3 (error path)
**Confidence:** High (executed)
**Legibility-target:** the `import_targets` comment, which states no failure contract

Evidence (verbatim): `done < <(env LC_ALL=C grep -aoE "$IMPORT_RE" || true)`. The `|| true` treats grep's exit 2 (error) like exit 1 (no match). The function's status is that of its `while` loop, which is always 0.

Executed:
- `import_targets "" < docs` (a directory on stdin) printed `grep: (standard input): Is a directory` and then `rc=0`, with no targets.
- `out="$(import_targets "" < /nonexistent)"` returns 1 only because the redirect fails. Any error after the open (EIO, a TOCTOU swap to a directory, grep memory exhaustion on a huge line) looks like "imports nothing".

Today's tree walk discards the status anyway (`done < <(import_targets "$d" < "$f")`, `:506`), so it skips the file. Iteration 2's F3 had the same shape on main_imports' checkout arm.

This is not attacker-reachable as found. Every trigger needs a same-uid writer or a host I/O fault, and the same fault usually stops Claude Code reading the file too. It is rated Low under the floor rule's host-control exemption. It matters because the dispatch states "the parser must fail closed", and U2a3 will call `import_targets` in `$(...)` expecting a status.

**Recommendation:** Distinguish the two exits, for example `env LC_ALL=C grep -aoE "$IMPORT_RE"; [[ $? -le 1 ]]` inside the substitution, plus a sentinel line the caller checks. Alternatively, have the parser print an error marker that both walks map to "walk failed, refuse". Even a one-line comment, "a read error looks like no imports; callers must check readability first", would make the contract explicit for U2a3.

## New evidence on filed or settled items (not re-filed)

- **Fact-check E1 (an `@` right after a UNI_SPACES character).** Confirmed with the extracted lexer: `@docs/a.md<NBSP>@docs/b.md` gives `docs/a.md docs/b.md` for CC and only `docs/a.md` for the walk. End to end, `See @docs/e.md\xc2\xa0@docs/f.md` in AGENTS.md makes `--check-fix docs/f.md` print `ok` at HEAD, while `docs/e.md` is refused. Main prints `ok` for both: main had no UNI_SPACES cut, so E1 is a residue of an improvement, not a regression. A fix that splits the grep match at each UNI_SPACES sequence and re-scans the remainder for `@` closes it. It composes with F1's prefix rule.
- **Override row `feat/build-loop-u2a2` B13 (trailing punctuation, "Fixed (partly)").** Confirmed. `@docs/a.md:<NBSP>x` yields `docs/a.md:` (CC), and the walk yields both `docs/a.md:` and `docs/a.md`. `@docs/a.md_` behaves the same way. The `\ ` residue still holds: `@docs/my\ notes.md` gives CC `docs/my notes.md` and the walk `docs/my`. That stays under the `feat/build-loop-u2a` Defer row and its trigger, which has not fired.
- **Iteration 2's untested "marked HTML-escaping text tokens" candidate.** Settled as not an issue for 2.1.292: the bundled `inlineText` sets `text: n[0]` (raw), and `@docs/a.md&nbsp;` reads the same on both sides.
- **Fact-check E2 (`(`, `)`, `]` inside a name).** One more data point: `@docs/a.md)` gives CC `docs/a.md)` and the walk `docs/a.md`, and `(@docs/a.md)` gives CC nothing and the walk `docs/a.md`. The first only matters for intermediate files, because `pathform` refuses `)` in a direct target.

## Untested bypass candidates

- **An instruction file inside an untracked nested repository or a submodule** (`nest/AGENTS.md` importing `@../docs/h.md`). Walk side executed: `git ls-files --others` does not descend into a nested repo, so it is not a start, and `--check-fix docs/h.md` printed `ok`. Not tested: whether Claude Code 2.1.292 loads a nested-repo or submodule instruction file when a session works under it. The loader's per-directory list suggests it does, but I did not trace where it stops at a repository boundary. Creating the nested repo needs a same-uid writer, and main behaves the same.
- **Autolinks and reference links** (`@docs/a.md<http://x>`, or `@docs/a.md[ref]` with a `[ref]:` definition). These belong to F1's class and would be closed by its fix. Not run separately.
- **Claude Code versions other than 2.1.292.** The grammar is version-dependent (S5). A marked upgrade or a gfm toggle would change the stop set.

## Endorsement Claims

- **Claim:** For any walk name other than `tree`, `isimported` returns 0 (imported) under `if`. With `tree`, it returns 0 exactly when the lower-cased path is a line of `IMPORTED`.
  **Location:** `scripts/lib/dev-cycle-read.sh:514-522`
  **Evidence:** executed
  **Verified:** I read `isimported` in full, and the `build-loop-check.bats` test "isimported answers imported under if for a walk name it does not know" passes (suite 100/100).
  **Not verified:** U2a3's `main` arm and its `floor` caller, which are not on this branch.
  **route: code-fact-check**
- **Claim:** In the shapes executed, `import_targets` yields every name Claude Code 2.1.292 resolves for: blanks, CR, VT, `#` fragments, backtick code spans, `\_` escapes, trailing `. , ; : ! ? * _ ~`, the 19 UNI_SPACES characters ending a token, ASCII controls and U+0085 (read as part of a token on both sides), and `..x` names. The exceptions are F1's inline-token stops, E1 and the deferred `\ `.
  **Location:** `scripts/lib/dev-cycle-read.sh:452-482`
  **Evidence:** executed (differential harness over 27 lines, plus the bats test at `test/scripts/build-loop-check.bats:98`)
  **Verified:** each listed line's CC set was a subset of the walk's set, apart from the named exceptions.
  **Not verified:** block-level shapes beyond lists and paragraphs (blockquotes, setext headings and nested lists were not in this run), and frontmatter, which Claude Code strips before lexing (`p8n`). Frontmatter can only make the walk over-read.
  **route: code-fact-check**
- **Claim:** In `check_fix`, the switch from an unconditional `imported_names` plus `$IMPORTED` to `elif isimported tree "$lp"` refuses at least the same paths as main.
  **Location:** `scripts/dev-cycle.sh:177-183`
  **Evidence:** executed
  **Verified:** on the F1/E1 fixture, HEAD refused `docs/e.md` and `docs/g.md` where main refused only `docs/g.md`. Fact-check r2 Claim 24b records the one documented corner (a Unicode-space-named intermediate file) as a model fix, not a weakening toward Claude Code.
  **Not verified:** whether errexit matters. The walk now runs inside an `elif` condition, so errexit is off within it, and a failing `$(lower ...)` assignment at `:504` would append an empty line rather than abort. That needs a fork failure, and I did not test it.

## Primitive sweep

Primitive: path construction from untrusted text (`realpath -ms`)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/lib/dev-cycle-read.sh:476` | S1 (S6 from U2a3) | `~`/`/` skipped; `..` and `../*` dropped; `-s` lexical, matching Claude Code's `path.resolve`; failure → `continue` | Tokenizer gaps are F1 and E1. Lexical resolution cleared. `realpath -ms` succeeded on a 300-byte component (executed), so `continue` needs a path Claude Code cannot open either. |

Primitive: file read of a checkout path

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/lib/dev-cycle-read.sh:506` (`import_targets "$d" < "$f"`) | S1, S2 | `inrepo_here` (blocker + `-f`) at queue time | F2: a read error after the open is silent. A TOCTOU swap needs a same-uid writer. |
| `scripts/lib/dev-cycle-read.sh:496` (start check) | S2 | `inrepo_here`, `INSTRUCTION_FILE` | Cleared for this unit. Symlinked starts and `.claude/rules/` starts are settled under A2 and the A5 row. |

Primitive: git listing

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/lib/dev-cycle-read.sh:500` (`git ls-files -z; untracked_md`) | S2 | none: the process-substitution status is discarded | Cleared for `--check-fix`. A failing `git ls-files` (for example a corrupt index) empties the starts, but `check_path`'s `matches` reads the same index and then refuses ("no tracked file ... matches"). The nested-repo case is listed above. |

There is no exec, eval, deserialization or network primitive in scope.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Inline `<tag>`, `<!-- -->`, `[link]`, `![img]` or `**em**` right after an import ends Claude Code's token, but the walk reads one longer token, so `--check-fix` prints ok for a loaded file | Medium | B4, B1→B3 (B5) | `scripts/lib/dev-cycle-read.sh:456, 468-482` | High |
| 2 | `import_targets` returns 0 on a grep read error (`\|\| true`), so no caller can fail closed | Low | B1, B5 | `scripts/lib/dev-cycle-read.sh:481` | High |

## Overall Assessment

The unit does what it says. Extracting the parser and adding `isimported tree` changes `--check-fix` only toward refusing more (UNI_SPACES, whole-and-stripped punctuation, `..x` names, NUL text), and `isimported` fails closed on unknown walk names.

The remaining risk sits at B4, the parser's model of Claude Code's grammar. Executing Claude Code's own bundled marked lexer shows a class the earlier passes missed (F1): an import directly followed by an inline HTML tag, a link or image, or emphasis. Claude Code resolves the plain path in each of these cases, and the walk does not. One case is `| @docs/style.md<br> |` in a table.

It is pre-existing on main, so it does not block this unit on regression grounds. But the walk becomes U2a3's gate parser, the bypass reaches a `pathform`-allowed direct target, and the fix is a few lines of over-reading in the B13 style. It should be fixed in `import_targets` before U2a3 builds on it, or explicitly added to the A5/Q-103 Defer row. F2 is a contract gap to close, or at least document, for U2a3's sake.

No other findings within the code paths read. The executed endorsement claims are scoped by their Not-verified hops, and the routed claims are pending execution verification.

## Goal-Alignment Note

- **Success criterion (verbatim):** "a markdown report saved at the path given in your tail, structured per your skill, with `Commit: 7697c6e6` as its first line."
- **Answered:** a security review of the net branch diff against the dispatch's threat model. It has one Medium fail-open (F1, new class, executed against Claude Code's own lexer and end to end) and one Low fail-closed contract gap (F2). It adds new evidence for fact-check E1 and E2, for override row B13, and for iteration 2's untested escaping candidate, plus untested candidates, routed endorsements and a primitive sweep.
- **Out of scope:** main_imports and the floor (U2a3/U2a4), iteration-2 rows routed to U2a3 (B2-B6, B8, B10-B12, B14), the settled A2/A3/A5 shapes, and `pathform` application (U2b).
- **Escalate:** F1, to decide whether it is fixed in this unit's shared parser or recorded under the A5/Q-103 Defer row with its trigger. Either way, U2a3 inherits it unless the fix lands first.
- **Questions / Decisions:** whether instruction files inside nested repositories or submodules count as starts (untested candidate 1) is a scoping call for plan F11.
