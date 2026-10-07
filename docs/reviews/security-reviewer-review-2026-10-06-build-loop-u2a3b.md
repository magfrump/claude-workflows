Commit: 7ddff454

# Security Review — feat/build-loop-u2a3b (iteration 2, loop pass)

**Scope:** `git diff 45ad17b0..7ddff454 -- scripts test`: `scripts/lib/dev-cycle-read.sh` (`IMPORT_RE`, `import_targets`, `instruction_names`, `imported_names`, the `main_imports` lower guard, `isimported`) and `test/scripts/build-loop-check.bats`. I read the enclosing functions in full (`dev-cycle-read.sh:440-650`) and their consumer, `check_fix` (`scripts/dev-cycle.sh:170-185`).
**Date:** 2026-10-06
**Based on:** `docs/reviews/code-fact-check-report-build-loop-u2a3b-i2.md` (0 Incorrect, 3 Mostly accurate) and iteration 1's `code-fact-check-report-build-loop-u2a3b.md`. Claude Code's grammar comes from `docs/reviews/security-reviewer-review-2026-10-06-final-build-loop-u2a2.md`.

**Threat model (from the dispatch).** The import walk decides which files an autonomous loop may edit (`--check-fix`, tree walk). From U2a4 it also decides the self-merge floor (main walk). Both walks share `import_targets`. A fail-open happens when Claude Code loads a file as instructions and the walk misses it. Over-reading only over-refuses.

**Method.** I reused U2a2's differential harness: the marked lexer extracted from Claude Code 2.1.292, with `reo` transcribed around it (`/tmp/u2a2f-sec-nefJ/{marked.js,cc.js}`, copied to `/tmp/u2a3b-sec-fQHv`). I ran it against `import_targets` at 45ad17b0, at 7ddff454 and on a candidate fix (`/tmp/u2a3b-sec-fQHv/diff.sh`). I also ran end-to-end fixture repos with `dev-cycle.sh --check-fix` and `isimported main` (`e2e.sh`). Every run used `GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 LC_ALL=C` under `timeout`, in a scratch copy made with `git archive`. No background processes were started.

## Trust Boundary Map

```
B1: [instruction-file / imported-file text (S1)]           → [import_targets: sed, IMPORT_RE, cut + strip] → [IMPORTED / IMPORTED_MAIN sets]
B2: [checkout listing: git ls-files + untracked_md (S2)]   → [instruction_names, rc sentinel, seen, inrepo_here] → [tree-walk start set / queue]
B3: [--check-fix argument (S3)]                             → [check_fix → isimported tree]                 → [skip / check_path ok → loop edits the file]
B4: [Claude Code 2.1.292 grammar: marked lexer + reo (S5)] → [the parser's model (S4)]                     → [what the walks call "loaded as instructions"]
B5: [main's blobs (S6)]                                     → [import_targets (shared)]                       → [IMPORTED_MAIN → U2a4 self-merge floor]
B6 (new): [host resources: TMPDIR or /tmp space, RLIMIT_FSIZE (S7)] → [bash here-string temp file] → [grep's exit status, read as "no match"]
```

| Label | Source | Mutability | Trust, by sink class |
|---|---|---|---|
| S1 | Text of every instruction file and imported file in the checkout | runtime-mutable (any commit; untracked files by any same-uid process) | UNTRUSTED toward path construction and toward the imported/not-imported decision |
| S2 | `git ls-files -z`, `untracked_md` listings (file names) | runtime-mutable (any commit can add a name, including one holding a newline) | UNTRUSTED. Extra starts are safe. Missing or colliding starts fail open. |
| S3 | The path passed to `--check-fix` | request-time | UNTRUSTED. Already passed `pathform` (letters, digits, `. _ - /`), so `_` names reach `isimported` |
| S4 | `IMPORT_RE`, `UNI_SPACES`, the cut set `[ ] ( ) < ! * _ \``, the strip set | code-constant | Trusted only as far as it is a superset of S5 |
| S5 | Claude Code 2.1.292 loader | external, version-dependent | The reference; executed from shipped bytes |
| S6 | main's committed blobs | runtime-mutable at every merge | As S1 |
| S7 | Temp-file space, file-size limit | deploy/host | Trusted for integrity. For availability it is fault-prone, and a fault must fail closed. |

**Summary.** The range makes `import_targets` read UNI_SPACES and NUL as blanks before tokenizing, end tokens only at blanks, `\` and `#`, and add Markdown-cut prefixes. It also makes the tree walk check its start listing and fail closed. Within those rules the walk is safe only while S4 is a superset of S5 (B4). Two gaps remain there: the cut is taken only at the first cut character (F1), and comments are spliced inside an HTML block (F2). The new two-step sed/grep reads a here-string I/O failure as "no match" (F4, B6).

## Findings

#### F1. The Markdown cut is taken only at the first cut character, so a name holding `_` (or `( ) [ ] ! * <`) followed by a code span, `<br>`, a link or emphasis passes `--check-fix` and the main walk. For code spans this regresses from 45ad17b0.

**Severity:** Medium
**Location:** `scripts/lib/dev-cycle-read.sh:509`; consumed at `scripts/dev-cycle.sh:181` (tree) and `dev-cycle-read.sh:601/607` (main, the U2a4 floor)
**Boundary:** B4, B1 → B3, B5
**Move:** 11 (bypass enumeration of the new cut rule), 2 (implicit assumption that the first cut character is where Markdown ends the token)
**Confidence:** High. Both sides were executed: the extracted marked lexer with `reo`, and `dev-cycle.sh --check-fix` plus `isimported main` end to end.
**Legibility-target:** for-author (the `import_targets` comment at `:494-496`, "its part before the first of [ ] ( ) < ! * _ or a backtick", states the rule that is too narrow)

Evidence (verbatim, `:509`):
`    for c in "$t" "${t%%[][()<!*_"$b"]*}"; do  # b: a backtick, written as \x60`
(excerpt ends :509; enclosing import_targets() continues to :519 — read: `:510` strips trailing punctuation from each `c`, `:511-516` resolve and print each form.)

`%%` removes the longest suffix that starts at a cut character, which leaves only the prefix before the *first* one. Marked does not end a text token at every cut character. It stops before `_`, `*`, `!` and `[` and then tries the emphasis, image and link tokenizers. When none of them matches (`_notes.md` has no closing `_`), it merges the next text run into the same text token. So Claude Code's token ends at the first cut character that *starts a real non-text token*, and that can come after an earlier `_` in the name.

Differential (`bash /tmp/u2a3b-sec-fQHv/diff.sh`, CC = names Claude Code 2.1.292 resolves; "miss" = names CC resolves that the walk does not list):

| Input line | CC | 45ad17b0 | 7ddff454 |
|---|---|---|---|
| ``@docs/my_notes.md`code` `` | `docs/my_notes.md` | — | **miss** |
| `\| @docs/style_guide.md<br> \|` | `docs/style_guide.md` | miss | miss |
| `@docs/my_notes.md[x](y)` | `docs/my_notes.md` | miss | miss |
| `@docs/my_notes.md**bold**` | `docs/my_notes.md` | miss | miss |
| `@docs/a_b.md*y*` | `docs/a_b.md` | miss | miss |
| `@docs/x_y.md<!-- c -->` | `docs/x_y.md` | miss | miss |
| `@docs/e(f).md<br>`, `@docs/a!b.md<br>`, `@docs/a*b.md<br>`, `@docs/a[b.md<br>` | the whole name | miss | miss |

For the `_`-name cases, 7ddff454 yields only the whole token and `docs/my` (or `docs/style`, `docs/x`).

End to end (`/tmp/u2a3b-sec-fQHv/e2e.sh`): AGENTS.md is committed with ``Style: @docs/style_guide.md`code` and | @docs/my_notes.md<br> |`` and `Also @docs/x_y.md[link](u) and @docs/plain.md`, and `docs/x_y.md` holds `chain: @target.md`. `cc.js` resolves all five names (`docs/target.md` through `docs/x_y.md`).

| `--check-fix` / `isimported main` | 45ad17b0 | 7ddff454 |
|---|---|---|
| docs/style_guide.md | skip / imported | **ok / -** |
| docs/my_notes.md | ok / - | ok / - |
| docs/x_y.md | ok / - | ok / - |
| docs/target.md (imported through x_y.md) | ok / - | ok / - |
| docs/plain.md (control) | skip / imported | skip / imported |

So an in-cycle fix may edit a file every session loads, and from U2a4 a branch may self-merge a change to it. The chain row shows the miss also hides everything the missed file imports, whatever that file's name. `_` is a `pathform` character, and snake-case doc names are ordinary. This is the R1 fix's class one character over: R1 added the backtick to the cut set but still cuts only once. The regression row (code span after a `_` name) passed at 45ad17b0, because its regex stopped every token at a backtick.

**Recommendation:** Yield the prefix before *every* cut character, not just the first, plus the stripped form of each. I tested this candidate in `/tmp/u2a3b-sec-fQHv/fix/lib.sh`:
`cs=("$t"); r="$t"; k="[][()<!*_$b]"; while [[ "$r" == *$k* ]]; do r="${r%$k*}"; cs+=("$r"); done; for c in "${cs[@]}"; do`.
It closes every row above, the end-to-end AGENTS.md included, and `build-loop-check.bats` tests 16 and 17 still pass with it (the full-suite tally was not captured). Add `` @docs/my_notes.md`x` `` and `| @docs/style_guide.md<br> |` to the "both walks read what Claude Code reads" fixture (`test/scripts/build-loop-check.bats:292`).

#### F2. In a line that opens an HTML block with `<!--`, Claude Code deletes every comment and scans what is left, so a comment inside a name splices it (`@docs/sec<!-- x -->ret.md` loads `docs/secret.md`). No walk form yields the spliced name.

**Severity:** Medium
**Location:** `scripts/lib/dev-cycle-read.sh:500-519` (`import_targets`, no comment-removal pass); pre-existing (present at 45ad17b0)
**Boundary:** B4, B1 → B3, B5
**Move:** 11
**Confidence:** Medium. The mechanism was executed on both sides. Reaching it needs an instruction-file line written in this shape, by a human-reviewed commit or an untracked local file, since `--check-fix` itself refuses instruction files.
**Legibility-target:** for-author (the token comment `:487-499` says "Over-reading only over-refuses" but does not name this splice form)

Evidence (Claude Code 2.1.292's `reo`, as transcribed in the harness): `if(S.type==="html"){let w=S.raw||"",H=w.trimStart();if(H.startsWith("<!--")&&H.includes("-->")){let z=w.replace(/<!--[\s\S]*?-->/g,"");if(z.trim().length>0)s(z)}continue}`. The parser's token for the same line is `docs/sec<!--` with its cut prefix `docs/sec` (`:503-509`).

Executed (`diff.sh cases/h*.md`): `<!-- note --> See @docs/sec<!-- x -->ret.md` resolves to `docs/secret.md` in CC. 45ad17b0, 7ddff454 and the F1 candidate fix all miss it. Inside a paragraph (`text <!-- x --> @docs/sec<!-- y -->ret.md`) the comment is an inline token, and CC reads `docs/sec`, which the walk has. Only the HTML-block form splices.

This is a deliberate-obfuscation channel rather than an accident: the line reads as a comment to a reviewer, and the hidden target then passes both `--check-fix` and the U2a4 floor.

**Recommendation:** For a line whose first non-blank characters (up to 3 spaces of indent) are `<!--`, also tokenize the line with every `<!--…-->` removed (for example, a second sed copy of such lines). Or record the shape under known issue A5 with the escaped-space form. Over-reading only over-refuses.

#### F3. A start file under a directory whose name holds a newline can make the tree walk's `seen` string match a different start, so `b/CLAUDE.md` is never walked and its imports pass `--check-fix`

**Severity:** Medium
**Location:** `scripts/lib/dev-cycle-read.sh:539` (in the start loop this range rewrote; the `seen` scheme predates it)
**Boundary:** B2 → B3
**Move:** 5 (invert the model: what the newline-separated `seen` list cannot represent), 11
**Confidence:** Medium. The mechanism was executed. It needs a committed or untracked path holding a newline. The main walk refuses such names (`:580`, `:585`), so only the tree walk is affected. `--check-fix` is the tree walk's only consumer, and the U2a4 floor (main) fails closed.
**Legibility-target:** for-orchestrator-synthesis

Evidence (verbatim, `:539`): `    [[ "$seen" == *$'\n'"$f"$'\n'* ]] && continue`. The list ``seen`` is newline-separated, and `f` comes from a NUL-separated listing that may hold a newline. After `a<NL>b/CLAUDE.md` (listed first, since `a` sorts before `b`) is added, `seen` contains `\nb/CLAUDE.md\n`, and the real `b/CLAUDE.md` is skipped as already seen.

Executed: in a fixture, `b/CLAUDE.md` holds `see @../docs/t.md` and `a<NL>b/CLAUDE.md` holds `nothing`, both committed. `dev-cycle.sh --check-fix docs/t.md` prints `ok docs/t.md` at both 45ad17b0 and 7ddff454. `isimported main docs/t.md` answers `imported` (the walk failed closed). `cc.js b/CLAUDE.md b` resolves `docs/t.md`. The same collision can also hide an imported target at `:550`, where a target `b/CLAUDE.md` is tested against the same `seen`.

**Recommendation:** Fail the tree walk (return 1, `IMPORTED=error`) on any listed name holding a newline, as `main_imports` does at `:585`. This fits the R2 fix's shape: one check in the new `for f in "${recs[@]:0:...}"` loop.

#### F4. When bash cannot create the here-string's temp file (text over 64 KiB with TMPDIR or /tmp full or unwritable, or a file-size limit), grep is not run, the status 1 is read as "no match", and the file reads as importing nothing

**Severity:** Low
**Location:** `scripts/lib/dev-cycle-read.sh:505`; the same unchecked here-string feeds the walk loops at `:551` (tree) and `:626` (main, U2a3 code (context))
**Boundary:** B6 → B1 → B3, B5
**Move:** 3 (error path)
**Confidence:** High (executed)
**Legibility-target:** for-author (the comment at `:499` says the parser "returns 1 when sed or grep fails", but this failure returns 0)

Evidence (verbatim, `:505`): `  toks="$(env LC_ALL=C grep -aoE "$IMPORT_RE" <<<"$toks")" || [[ $? -eq 1 ]] || return 1`. Bash 5.2 sends a here-string through a pipe when it fits the pipe buffer, and through a temp file otherwise. A redirection failure gives status 1, the same as grep's "no match".

Executed (`/tmp/u2a3b-sec-fQHv/hs.sh`, bash 5.2.15, `trap '' XFSZ; ulimit -f 0` to make temp-file writes fail):
- `import_targets "" < big/big.md` (an `@docs/a.md` line plus 100,000 bytes) prints `line 505: cannot create temp file for here-document: File too large` and returns `rc=0 out=[]`.
- The size threshold lies between 60,000 bytes (read correctly) and 66,000 bytes (empty).
- End to end, with that file committed as AGENTS.md, `isimported tree docs/a.md` and `isimported main docs/a.md` both answer `-`. Without the limit, both answer `imported`.

This is not a regression. 45ad17b0's `< <(grep … || true)` hid every grep error. But the range's stated contract (F2 of U2a2's final review: "the parser must fail closed") does not hold for this I/O fault. The trigger is a host resource fault, not attacker input, so it is Low under the floor rule's host-control exemption. The `:551` and `:626` loops fail open the same way when one file's target list exceeds the buffer.

**Recommendation:** Do not let a here-string sit on the fail-closed path. Feed grep through a pipe whose status is checked separately (for example `printf '%s\n' "$toks" | grep …` with `PIPESTATUS`), or check the walk loops' status (`done <<<"$out" || { IMPORTED=error; return 1; }`).

## New evidence on settled or prior items (not re-filed)

- **R1 (iteration 1).** Fixed for a plain name followed by a code span, as the fact-check's Claim 15 shows. It is incomplete for a name that holds an earlier cut character, which is F1.
- **R2 (iteration 1).** The start-list sentinel at `:534-535` fails closed for a corrupt index (re-executed as the fact-check's Claim 14). It does not cover F3's newline-name collision, which reads as a success.
- **U2a2 final F2 (parser status).** Closed for sed and grep errors that grep itself reports (the `import_targets "" < docs` test at `build-loop-check.bats:315`). The residue is F4.
- **Fact-check Claim 16b (`instruction_names` returns 1, not grep's 2).** No security impact: the only caller (`:534`) tests success or failure, and both of the function's failure paths are non-zero.

## Untested bypass candidates

- **Claude Code versions other than 2.1.292, or a marked upgrade or gfm toggle.** This would change the cut set (S5 is version-dependent). Not testable here.
- **Reference-style links and autolinks after a `_` name** (``@docs/a_b.md[r]`` with a `[r]:` definition, `@docs/a_b.md<http://x>`). These belong to F1's class and would be closed by its fix. I did not run them separately.
- **Block-level shapes (setext headings, nested blockquotes, lazy continuation) around a `_` name.** Not run. I expect the same inline result, but did not confirm it.
- **Instruction files inside nested repositories or submodules.** Carried from U2a2 final. Still untested on Claude Code's side.

## Endorsement Claims

- **Claim:** For a corrupt index, a failing `git ls-files`, a failing `untracked_md` or a grep error in `instruction_names`, `imported_names` returns 1 with `IMPORTED=error` on the first and second calls, and `isimported tree` then answers imported.
  **Location:** `scripts/lib/dev-cycle-read.sh:531-535`, `:637-641`
  **Evidence:** executed
  **Verified:** the fact-check's Claim 1 table (shims for each listing component), and my corrupt-index rerun through `build-loop-check.bats` test 17.
  **Not verified:** a listing that succeeds but holds a newline-named path (F3), and a `printf` failure inside the substitution.
  **route: code-fact-check**
- **Claim:** On a direct target whose name holds no cut character, the parser at 7ddff454 yields every name CC 2.1.292 resolves for the shapes in U2a2's 27-line corpus plus `<br>`, `<!-- -->`, `[x](y)`, `**b**`, a closed code span and an `@` after each of the 19 UNI_SPACES characters.
  **Location:** `scripts/lib/dev-cycle-read.sh:500-519`
  **Evidence:** executed (the `diff.sh` rows `See @docs/a.md<br> x` and `@docs/a.md`, the fact-check's Claims 4, 10 and 11, and tests 1, 2 and 16)
  **Verified:** the rows listed, against `cc.js`.
  **Not verified:** names with an interior cut character (F1), HTML-block comment splices (F2), and block-level shapes beyond paragraphs and lists.
  **route: code-fact-check**

## Primitive sweep

Primitive: path construction from untrusted text (`realpath -ms`)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/lib/dev-cycle-read.sh:513` | S1, S6 | `~/` and `/` skipped; `..`/`../*` dropped; lexical `-ms` | Cleared for resolution. The token set feeding it is F1 and F2. |
| `scripts/lib/dev-cycle-read.sh:615` (main's symlink text) | S6 | empty/absolute/newline/NUL/`..` refused | Not changed in range. U2a3 code (context), cleared by U2a3's own review. |

Primitive: file read of a checkout path, and its status

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `:546` `import_targets "$d" < "$f"` (tree) | S1, S2 | `inrepo_here` at queue time; status checked | Open or read errors fail closed; a temp-file fault inside is F4 |
| `:601` (main, checkout arm) | S1, S2 | `inrepo_here`; status checked | As `:546` (U2a3 code (context)) |
| `:607` (main, blob) | S6 | pipefail + status | As `:546`; F4 applies (U2a3 code (context)) |

Primitive: git listing

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `:534` (tree start list) | S2 | `rc=0` sentinel under pipefail (new) | Cleared for command failure; a newline-name collision is F3 |
| `:573`, `:583` (main) | S2, S6 | `rc=0` sentinel; newline names refused | Cleared (U2a3 code (context)) |

Primitive: bash here-string (temp file on large input)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `:505` | S1/S6 text via S7 | status 1 read as "no match" | F4 |
| `:518` | grep output | the loop's status is the function's return status | Cleared: a redirection failure returns 1 |
| `:551` | parser output | none | F4 (tree) |
| `:626` | parser output | none | F4 (main, U2a3 code (context)) |
| `:280`, `:340`, `:369`, `:747` | not import-walk code | — | Not analyzed: outside the range and the walk |

No exec, eval, deserialization or network primitive is in scope.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| F1 | Cut only at the first cut character: a `_` name followed by a code span, `<br>`, a link or emphasis is missed by both walks (code-span case regressed from 45ad17b0) | Medium | B4, B1→B3, B5 | `scripts/lib/dev-cycle-read.sh:509` | High |
| F2 | An HTML-block line's comment splices a name (`@docs/sec<!-- x -->ret.md` → `docs/secret.md`); no walk form yields it | Medium | B4, B1→B3, B5 | `scripts/lib/dev-cycle-read.sh:500-519` | Medium |
| F3 | A newline-named directory makes the tree walk's newline-separated `seen` skip a real start file | Medium | B2→B3 | `scripts/lib/dev-cycle-read.sh:539` | Medium |
| F4 | A here-string temp-file failure (text over 64 KiB) reads as grep's "no match"; both walks see no imports | Low | B6→B1 | `scripts/lib/dev-cycle-read.sh:505` (also `:551`, `:626`) | High |

## Overall Assessment

The range moves the parser and the tree walk toward failing closed. The UNI_SPACES, NUL and Markdown-cut changes close U2a2's D1 and most of D2. The new start-list sentinel and the error caching close D3 and R2 for command failures. But B4 is still not a superset. The most important item is F1: cutting only at the first cut character misses ordinary snake-case names followed by `<br>`, a link, emphasis or a code span. For the code-span case, 7ddff454 lets `--check-fix` say `ok` for a file that 45ad17b0 refused. It reaches the main walk, and so the U2a4 self-merge floor. The fix is a few lines in the same over-reading style (tested above). F2 and F3 are pre-existing, crafted-input gaps that can be fixed in place or recorded under A5. F4 is a host-fault residue of U2a2's F2 contract. None of these is architectural. No findings beyond these within the code paths read; the endorsement claims are pending execution verification.

## Goal-Alignment Note

- **Success criterion (restated verbatim):** A markdown report saved at the output path named in your role section below, structured per your skill, with a `Commit: 7ddff454` line at the top.
- **Answered:** a security review of `45ad17b0..7ddff454` under the dispatch's threat model. It found three Medium fail-opens: F1, a partial regression in this range's cut rule; F2, pre-existing, a comment splice; F3, pre-existing, in the start loop this range rewrote. It also found one Low fail-closed contract residue (F4). Each finding was executed against Claude Code 2.1.292's extracted lexer and end to end. F1 has a tested candidate fix.
- **Out of scope:** main_imports' own lines beyond the `:622` guard, marked "U2a3 code (context)" where touched (F4's `:626`); `pathform`; the settled override rows 346/350/355/363.
- **Escalate:** F1 to this unit's fix loop. It is a regression against the R1 fix and reaches the U2a4 floor. F2/F3 need a fix-or-defer call (A5).
