Commit: 90364c73 (main; delta 6f3d55e..5652d33f / 2fd9401..2da55741)

# Security Review — dev-cycle pass 38 (final k=1 delta, post-merge)

**Scope:** Partial. A: `git diff 6f3d55e..5652d33f -- . ':!docs/reviews'` (`scripts/dev-cycle.sh`). B: `git diff 2fd9401..2da55741 -- . ':!docs/reviews'` (`scripts/dev-cycle.sh`, `skills/dev-cycle/SKILL.md`, `test/scripts/dev-cycle.bats`). Code is identical at 90364c73, 2da55741 and HEAD dff7fe8b (`git diff --quiet 2da55741 HEAD -- scripts skills test`). Everything else is context only.
**Date:** 2026-10-02
**Based on:** `docs/reviews/code-fact-check-report-2026-10-02-digest-pass38.md` (Stage 1, 27 claims, 4 Incorrect) and its `security-reviewer` escalations; brief `/tmp/claude-1000/pass38-orchestrator/brief.md`.
**Reference behaviour:** Claude Code 2.1.288's memory loader. I read it statically from the installed bundle (`/usr/local/share/npm-global/lib/node_modules/@anthropic-ai/claude-code/bin/claude.exe`, functions `VWn`, `qJ`, `U$e`, and the project-dir walk) and did not run it.

## Trust Boundary Map

```
B1: [repo text: commit msgs, questions, briefs, ignored docs/working/]  → [cycle agent picks an in-cycle fix] → [--check-fix gate, check_fix() :449-464] → [edit to a docs/ or README.md file]
B2: [instruction files: tracked, untracked, ignored, incl. node_modules] → [imported_names() walk :425-447: grep IMPORT_RE, realpath -ms, inrepo] → [IMPORTED refusal set]
B3: [docs file the fix edited]                                         → [Claude Code @-import loader (VWn/qJ, depth ≤5)] → [instructions of every later session]
B4: [git ref names from `git branch --merged`]                         → [--check-branch form gate + SKILL.md:170-175 rule] → [`you: terminal` paste block run on the host]
B5: [default-branch tree entry at a brief path]                        → [check_brief() ls-tree mode gate :357-361] → [brief Status read / slot decision]
```

| Label | Source | Mutability | Trust per sink class |
|---|---|---|---|
| S1 | Repo text that steers which doc an in-cycle fix edits | runtime-mutable (anyone who commits, or writes an ignored `docs/working/` file) | UNTRUSTED toward edit sinks. This is the reason `--check-fix` exists. |
| S2 | Instruction-file content, including `.claude/rules/**/*.md` and third-party `node_modules/**/AGENTS.md` | runtime-mutable | Trusted as the author's statement of what is imported: it is the guard's own input, and over-reading it only over-refuses. UNTRUSTED toward file-read sinks, because the paths it names are read by `grep`. |
| S3 | Git ref names | runtime-mutable (any local branch) | UNTRUSTED toward shell text |
| S4 | Default-branch tree modes and blobs | committer-controlled | UNTRUSTED toward read and state sinks |
| S5 | Claude Code's loader semantics (2.1.288) | deploy-time (external) | Reference only. The guard must over-approximate it. |
| S6 | `IMPORT_RE`, `INSTRUCTION_FILE`, `NAMECHARS` | code-constant | trusted |

The delta strengthens B2 a great deal. It walks imports transitively, from untracked and ignored instruction files as well, resolves each path against the importing file's directory, and matches the full path. B4 and B5 are closed as their rules state. B2 is still narrower than B3: there are several shapes that Claude Code loads as instructions but the walk does not record. Each one leaves an imported file editable by an S1-steered fix (F1–F4). The acceptance bar counts every such miss as fail-open.

## Findings

#### F1. `IMPORT_RE` ends the token at `_`, so `@docs/CODING_STANDARDS.md` is recorded as `docs/coding` and the imported file prints `ok` (a regression in 5652d33f)

**Severity:** Medium. This defeats the full-review-1 A1 guard (Medium) by a concrete mechanism, in a reachable environment: an underscored doc name is ordinary. The floor rule applies.
**Location:** `scripts/dev-cycle.sh:423`
**Boundary:** B2 → B3
**Move:** 11 (bypass enumeration), 2 (assumed sanitization)
**Confidence:** High. The script side was executed. The Claude Code side was read statically and agrees with the fact-check's reading.
**Legibility-target:** for-author

**Evidence (verbatim).** Code: `IMPORT_RE='(^|[[:space:](*_])@[^[:space:]`)*_]+'`. The enclosing `imported_names()` (`:425-447`) uses the token after `t="${t#*@}"` and the trailing-punctuation strip, with no other reassembly. Claude Code: `let S=/(?:^|\s)@((?:[^\s\\]|\\ )+)/g` keeps `_`, and marked merges the intraword `_` back into one text token (fact-check Claim 4a). Probe P1 (`tmp.ZIO1xKh58I`), with a `GEMINI.md` line `Underscore @docs/my_notes.md here.`:
```
ok docs/my_notes.md
```
At 6f3d55e the token class `[^[:space:]`)]` kept `_`, and the file was refused (fact-check P2).

**Scenario:** A project's `CLAUDE.md` says `Follow @docs/CODING_STANDARDS.md`. A questions entry or commit message (S1) points the cycle at a "typo" in that file. `--check-fix docs/CODING_STANDARDS.md` prints `ok`, and the edit lands through step 7 (merged without the user in /away mode). Every later session then loads the changed text as project instructions.

**Recommendation:** See F2. A fix to the token class has to keep both `_` inside the path and the emphasis cases that the `*_` exclusion was added for. P2 shows that the obvious fix loses the emphasis cases.

#### F2. Markdown contexts the walk does not read as Claude Code does: `#fragment`, link text, after an inline token, strikethrough, and NBSP

**Severity:** Medium. Each item is a concrete mechanism around the same guard, and the floor rule applies. How often these shapes occur goes in Confidence.
**Location:** `scripts/dev-cycle.sh:423` (left context and token class), `:439-441` (no `#` cut)
**Boundary:** B2 → B3
**Move:** 11
**Confidence:** High for the script side (executed). Medium for the Claude Code side (read statically: `VWn` scans every `text` token and recurses into every token's `.tokens`/`.items`, so the text of links, strong, em and del is scanned, and each text token's start counts as `^`). Occurrence: Medium for `#fragment` and link-text imports, Low for the rest.
**Legibility-target:** for-author

**Evidence (verbatim).** Claude Code: `let H=B.indexOf("#");if(H!==-1)B=B.substring(0,H);` and `if(S.type==="text")s(S.text||"");if(S.tokens)g(S.tokens);if(S.items)g(S.items)`. The script's left context is `(^|[[:space:](*_])`, which takes ASCII blanks only (the grep runs under `LC_ALL=C`). There is no `#` cut between `:439` and `:442`. Probe P1, one `GEMINI.md` line per case:
```
Fragment @docs/q.md#intro here.                         → ok docs/q.md
Link text [@docs/linktext.md](docs/linktext.md) here.   → ok docs/linktext.md
After code `x`@docs/aftercode.md here.                  → ok docs/aftercode.md
NBSP before<U+00A0>@docs/nbsp.md here.                  → ok docs/nbsp.md
Strike ~~@docs/del.md~~ here.                           → ok docs/del.md
Plain @docs/plain.md here.                              → skip docs/plain.md: an instruction file imports it …
```
6f3d55e had the same left context without `*_`, so none of these is a regression from it. The `#fragment` case is pass-37 fact-check Claim 5a, still open.

**Scenario:** `AGENTS.md` lists `- [@docs/review-checklist.md](docs/review-checklist.md)`, or `See @docs/style.md#naming`. Claude Code loads the target into every session, but `--check-fix` prints `ok` for it, and an S1-steered fix can edit it, as in F1.

**Recommendation (tested in a scratch clone, not committed).** Widen the left context to any non-alphanumeric byte, stop the token at blank, `\`, `#`, `` ` ``, `(`, `)`, `[`, `]`, and strip trailing `*`, `_` and `~` along with the punctuation:
```bash
IMPORT_RE='(^|[^[:alnum:]])@[^][:space:]\\#`()]+'
      while [[ "$t" == *[.,\;:!?*_~] ]]; do t="${t%?}"; done
```
P3 (`tmp.QTKgLakpNh`) shows this variant refuses all 11 shapes: F1, F2, `**@x**`, `_@x_`, `*@x*`, `(@x)` and a trailing `.`. It still prints `ok` for `user@docs/email.md`. P5 (`tmp.B4OalH48jN`) shows bats 51/51 and shellcheck rc 0. P6 (`tmp.mo8t5Pc13o`) runs it over this repo's 690 `README.md`/`docs/**.md` paths, and the output is identical to the merged script: 14 `ok`, 0 import skips, and `ok README.md`. The variant refuses `` `@docs/span.md` `` code spans too, which Claude Code skips. That is fail-safe over-refusal.

#### F3. Instruction files that Claude Code loads but the walk never starts from: `.claude/rules/**/*.md` and symlinked instruction files

**Severity:** Medium (floor rule; this is a mechanism around the same guard).
**Location:** `scripts/dev-cycle.sh:428-434`, start filter `:429`
**Boundary:** B2 → B3
**Move:** 5 (what the guard does not cover), 11
**Confidence:** High for the script side (executed). Medium for the Claude Code side (read statically). Occurrence: Medium for rules files, which are a documented Claude Code feature. Low for symlinked instruction files whose target is not itself an instruction file.
**Legibility-target:** for-author

**Evidence (verbatim).** Start filter: `if [[ ! "$(lower "${f##*/}")" =~ $INSTRUCTION_FILE ]] || ! inrepo "$f"; then continue; fi`. A file under `.claude/rules/` has a free-form basename, so it never matches. `inrepo` (`:179`) refuses any symlink. Claude Code walks the project's rules directory, `let oo=Lp(vn,".claude","rules");if(H.push(...await U$e({rulesDir:oo,type:"Project",…`. `U$e` reads every `*.md` in it, recursively, through `qJ` (`else if(wn&&Qe.name.endsWith(".md")){… await qJ(Ot,n,r,s,0,…`), and `qJ` follows `includePaths` (`for(let Ce of be){… await qJ(Ce,n,r,s,g+1,e,…`). Probe P1, a tracked `.claude/rules/style.md` holding `Style rules: @docs/ruled.md`:
```
ok docs/ruled.md
```
The `.claude/rules/style.md` file itself is protected, because `--check-fix` refuses dot-directories. Only its imports are not. The symlinked-instruction-file case was confirmed in P2 (`tmp.CDdWBpHlZA`): `tools/AGENTS.md -> ../notes/real-instr.md` holding `@../docs/viasym.md` → `ok docs/viasym.md`. That is pass-37 fact-check Claim 5b, still open. The comment's "The walk starts at every instruction file in the checkout" (`:416-417`) overstates the start set for both cases.

**Scenario:** A project keeps its conventions in `.claude/rules/docs.md` = `Write docs per @docs/writing-guide.md`. An S1-steered "mechanical fix" edits `docs/writing-guide.md`, which every session then loads.

**Recommendation:** Add every `*.md` under any `.claude/rules/` directory (tracked or not) to the start set. For a symlinked instruction file inside the repo, start from its `realpath -e` target when that target is in the repo. Add both cases to the bats import test.

#### F4. Import resolution differs from Claude Code for symlink targets, symlinked directories and absolute in-repo paths

**Severity:** Medium under this skill's floor rule. The fact-check rated 6b and 7 Low, which is its own scale. All three are named mechanisms in a reachable environment, so Severity stays at Medium and their rarity goes in Confidence.
**Location:** `scripts/dev-cycle.sh:441-445`
**Boundary:** B2 → B3
**Move:** 11, 4 (the check resolves the link's text, while the use reads its target)
**Confidence:** High for the script side (executed). Medium for Claude Code (read statically). Occurrence: Low. Each case needs a committed symlink on an import path, or an absolute import, which in practice sits in a personal `CLAUDE.local.md`.
**Legibility-target:** for-author

**Evidence (verbatim).**
```bash
      [[ -n "$t" && "$t" != "~"* && "$t" != /* ]] || continue
      p="$(realpath -ms --relative-to="$ROOT_REAL" -- "$ROOT_REAL/${d:+$d/}$t" 2>/dev/null)" || continue
      [[ "$p" != ..* ]] || continue
      IMPORTED+="$(lower "$p")"$'\n'
      if [[ "$seen" != *$'\n'"$p"$'\n'* ]] && inrepo "$p"; then seen+="$p"$'\n'; queue+=("$p"); fi
```
(The excerpt ends at `:445`. The read loop closes at `:446` and the function at `:447`; I read both.) Claude Code: `K=So(ie(),e),{resolvedPath:V,isSymlink:he}=K; … await Rmt(e,n,V,S)`, which reads the realpath target, and `B.startsWith("/")&&B!=="/"`, which accepts absolute paths. Probe P2 (`tmp.CDdWBpHlZA`), at 90364c73:
```
ok docs/abs.md        (GEMINI.md: @<repo realpath>/docs/abs.md)
ok docs/real.md       (@docs/link.md, docs/link.md -> real.md)
ok docs/y.md          (@lnk/y.md, lnk -> docs)
```
6f3d55e refused `docs/y.md` by basename, so that case is a regression (fact-check Claim 6b).

**Recommendation:** Record both the `realpath -ms` form and the `realpath -m` (symlinks expanded) form of each token, and queue the expanded form when it lies in the repo. For a `/` or `~/` token, resolve it and keep it when it lands under `$ROOT_REAL`.

#### F5. The fact-check's suggested fix for F1 re-opens the emphasis cases that 5652d33f closed

**Severity:** Informational. This is guidance for the fix round, not a defect in the code under review.
**Location:** `docs/reviews/code-fact-check-report-2026-10-02-digest-pass38.md` ("Claims Requiring Attention", Claim 4a: "Drop `*_` from the token class, keep them only in the left context, and cut at `#`")
**Boundary:** B2
**Move:** 11
**Confidence:** High (executed)
**Legibility-target:** for-orchestrator-synthesis

**Evidence (verbatim).** Probe P2 patched a scratch copy to `IMPORT_RE='(^|[[:space:](*_])@[^[:space:]`)]+'` plus `t="${t%%#*}"`. It fixed `my_notes` and `q.md#intro`, but printed `ok docs/g.md`, `ok docs/e1.md` and `ok docs/e2.md` for `**@docs/g.md**`, `_@docs/e1.md_` and `*@docs/e2.md*`. The token keeps the closing marks (`docs/g.md**`), and the trailing strip `[.,\;:!?]` does not remove them. The merged script refuses all three.

**Recommendation:** Use F2's tested variant, which also strips trailing `*_~`, rather than the fact-check's one-liner. Add `**@x**`, `_@x_`, `@x_y.md`, `@x.md#h`, `[@x](x)` and NBSP to the bats import test.

#### F6. Branch names the paste block leaves out go into the entry as plain text, with no warning

**Severity:** Informational (hardening). The property the rule promises holds: the paste block holds only `--check-branch` `ok` names.
**Location:** `skills/dev-cycle/SKILL.md:170-175`
**Boundary:** B4
**Move:** 5
**Confidence:** Medium
**Legibility-target:** for-author

**Evidence (verbatim).** "Only a name that `--check-branch` prints `ok` for goes into that entry's paste block (git allows names such as `a$(id)`, which a paste would run); list any other name as plain text outside the block, for the user to handle." The full-review F2 recommendation also asked for the label "not put in the command: unusual characters". The fix does not carry that label. Ref names may hold bidi controls (U+202E), which `check-ref-format` allows, and the questions file is not scrubbed. So a listed name can display as something else. A user who copies a plain-text name into `git branch -d` by hand runs it unquoted.

**Recommendation:** Have the rule say that each plain-text name is listed with "not in the command: unusual characters, delete by hand with care", or shown in escaped form (`printf %q`).

## Untested bypass candidates

- `.claude/CLAUDE.md` with an import. Not tested: a policy hook blocks Bash writes that name `CLAUDE.md`. By reading, the basename matches `INSTRUCTION_FILE`, `ls-files` lists it and `inrepo` passes, so it is walked.
- A `~/` import that lands in the repo (the repo under `$HOME`). Not tested; it takes the same `"~"*` skip as F4's absolute case.
- User-level `~/.claude/CLAUDE.md`, `~/.claude/rules/` or managed memory importing a project doc by absolute path. These are outside the checkout, so the script cannot see them. Out of scope by design; noted for the help text.
- Conditional rules (`paths:`/`globs:` frontmatter) under `.claude/rules/`. Claude Code loads them when a matching file is touched (`Bee`). Same start-set gap as F3. Not separately probed.
- An HTML block that holds a comment plus text (`<div>@docs/x.md</div><!-- c -->`). Claude Code scans the comment-stripped remainder; the script greps the raw line. Not probed. A leading `>`/`<` is non-blank, so it would be a miss under the current left context and a hit under F2's variant.
- Instruction files inside a nested git repository or submodule. `ls-files` does not enter them, but files inside are not tracked by the parent either, so `check_path` refuses them. Not probed.
- Case-insensitive filesystem behaviour of the import match. Both sides are lower-cased (fact-check Claim 10). No such filesystem was available.

## Endorsement Claims

- **Claim:** `check_brief` reaches the blob read only for mode `100644`/`100755`. A symlink (`120000`), gitlink (`160000`) or tree (`040000`) at the brief path on the default branch prints `skip …: not a regular file on the default branch`.
  **Location:** `scripts/dev-cycle.sh:357-366`
  **Evidence:** read-static (I read the whole of `check_brief()`, `:348-384`). The fact-check executed it (P3, P4), and bats test 51 covers the symlink.
  **Verified:** that the `case` on `git ls-tree "$MAIN_SHA" -- "$a" | cut -c1-6` returns before `git cat-file blob` for every mode other than the two regular ones; that `isbrief` limits `$a` to `[a-z0-9-]` slugs, so `ls-tree` prints at most one entry.
  **Not verified:** a failing `git ls-tree` (for example, a corrupt object), which yields `''` and so `ok … new`. That matches the old `cat-file -t` failure mode, but I did not exercise it.
  **route: code-fact-check**
- **Claim:** A name for which `--check-branch` prints `ok` matches `^[a-zA-Z0-9._/-]+$`, does not start with `-`, and passes `git check-ref-format --branch`. No character in that set is a metacharacter in bash or zsh outside quotes.
  **Location:** `scripts/dev-cycle.sh:393-405`; `skills/dev-cycle/SKILL.md:170-175`
  **Evidence:** read-static. The fact-check executed it (P3: `skip a$(id): not an allowed branch name`).
  **Verified:** that `check_branch()` prints `ok` only after the `NAMECHARS` and `-*` test fails, plus both `check-ref-format` calls and the `HEAD`/`refs/*`/default-branch exclusions; that the skill's pre-filter (`:101-103`) stops other values from reaching the check at all.
  **Not verified:** the agent's compliance when it assembles the `you: terminal` block, which is prose, not code.
  **route: code-fact-check**
- **Claim:** `imported_names()` reads (`grep -- "$f"`) only paths that `inrepo` accepts (a regular file reached through no symlink, inside `$ROOT_REAL`), after dropping `..`-relative, `/` and `~` tokens. An instruction file naming `@/dev/zero`, `@../../etc/x` or a symlink therefore does not make the walk read outside the checkout.
  **Location:** `scripts/dev-cycle.sh:429,441-446`
  **Evidence:** read-static
  **Verified:** that every `queue+=` site is guarded by `inrepo` (`:429`, `:445`); that `realpath -m` reads nothing; that `[[ "$p" != ..* ]]` runs before `IMPORTED+=`.
  **Not verified:** reads of in-repo `.git/` files named by an import (`@.git/config`). By reading, these only add refusal entries and print nothing, but I did not execute it.
  **route: code-fact-check**
- **Claim:** `lp` and the `IMPORTED` entries are compared literally (both quoted inside `*$'\n'"…"$'\n'*`), so glob characters in a recorded import path cannot widen or narrow the match.
  **Location:** `scripts/dev-cycle.sh:430,445,461`
  **Evidence:** read-static
  **Verified:** that every pattern operand is double-quoted, and that `pathform` rejects `*?` in `lp` before the match.
  **Not verified:** a recorded path containing a newline. `grep -o` output is line-based, so none can occur, but I did not execute it.

The `@`-import refusal itself does not appear here: it has findings (F1–F4) and untested bypass candidates.

## Primitive sweep

Primitive: file edit (in-cycle fix) gated by `--check-fix`
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `SKILL.md:71-77` in-cycle fix edits | S1 | `check_fix()` `:449-464` | **F1–F4** (imported files print `ok`). Exclusions and the case fold are cleared (fact-check Claims 10, 11). |

Primitive: file read by a repo-named path
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `dev-cycle.sh:446` `grep -oE … -- "$f"` | S2 | `inrepo` at `:429`/`:445`, `..*` at `:443` | cleared (Endorsement 3) |
| `dev-cycle.sh:442` `realpath -ms` | S2 | `-m`: no read | cleared |
| `dev-cycle.sh:432-434` three `git ls-files` producers | S2 (tree listing) | NUL-separated; name filter | cleared for security; cost is the performance lane's (fact-check P5) |
| `dev-cycle.sh:365` `git cat-file blob "$MAIN_SHA:$a"` | S4 | mode gate `:357-361` | cleared (Endorsement 1) |

Primitive: shell text built from repo data
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `SKILL.md:170-175` merged branches → `you: terminal` paste block | S3 | `--check-branch` `ok` only | cleared for the block (Endorsement 2); F6 for the plain-text list |
| `dev-cycle.sh:442` `realpath … -- "$ROOT_REAL/…$t"` | S2 | argument after `--`, quoted | cleared: no shell evaluation |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| F1 | `IMPORT_RE` cuts at `_`: `@docs/my_notes.md` → `ok` (regression from 6f3d55e) | Medium | B2→B3 | `scripts/dev-cycle.sh:423` | High |
| F2 | `#fragment`, `[@x](…)`, after an inline token, `~~@x~~`, NBSP → `ok` | Medium | B2→B3 | `scripts/dev-cycle.sh:423,439-441` | High (script) / Medium (CC) |
| F3 | `.claude/rules/**/*.md` and symlinked instruction files never start the walk | Medium | B2→B3 | `scripts/dev-cycle.sh:428-434` | High (script) / Medium (CC) |
| F4 | Symlink targets, symlinked dirs, absolute in-repo imports → `ok` | Medium | B2→B3 | `scripts/dev-cycle.sh:441-445` | High (script) / Medium (CC); occurrence Low |
| F5 | The fact-check's suggested fix re-opens `**@x**`/`_@x_`/`*@x*` | Informational | B2 | fact-check report, Claim 4a | High |
| F6 | Plain-text branch names listed with no warning | Informational | B4 | `skills/dev-cycle/SKILL.md:170-175` | Medium |

## Overall Assessment

The delta closes what it set out to close in B4 (paste block) and B5 (brief modes), and the walk is a large step up from basename matching. The `@`-import refusal still fails open, though, so by the brief's acceptance bar this pass is not clean on it. There is one Medium regression (F1, `_`). Three Medium gaps remain against Claude Code's actual loader: F2 (markdown context and `#`), F3 (the start set: `.claude/rules/` is new here, and symlinked instruction files) and F4 (symlinks and absolute paths). F4's cases are rare. All of them can be fixed in place in `imported_names()` and need no architectural change. The single most important fix is the tokenizer (F1 + F2). F2's variant is tested: it refuses every probed shape, passes 51/51 and shellcheck, and leaves this repo's fixable set unchanged. It should not be replaced by the fact-check's one-liner (F5). After that, add the `.claude/rules/` start set (F3). Within the code paths read, there are no findings beyond these. The endorsement claims are pending execution verification.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the path your role instructions give, structured per your skill file.
- Answered:
  - Saved at `/workspace/docs/reviews/security-review-2026-10-02-digest-pass38.md` with the required first line, structured per `skills/security-reviewer/SKILL.md`. Not committed.
  - Every fact-check escalation is graded under this skill's severity scale and floor rule, with preconditions and a scenario: `_` → F1; `#`, absolute/`~`, symlink targets and symlinked dirs, symlinked instruction files → F2/F3/F4.
  - Three further fail-open shapes were found and executed: link text, after an inline token or `~~`, NBSP (F2). So was a new start-set gap, `.claude/rules/` (F3).
  - The step-1 paste-block rule and the `check_brief()` mode change are reviewed. Both are correct for their stated property (Endorsements 1–2), plus one hardening note (F6).
- Out of scope:
  - Running Claude Code; its behaviour is read statically.
  - Other harnesses' import syntax.
  - The cost of the three producers (performance lane).
  - Anything in the rubric's Full review 1 / Pass 37 sections.
  - Fixing anything.
- Escalate:
  - **fix round / orchestrator:**
    - F1+F2 together, using the tested variant in F2, not the fact-check's one-liner (F5);
    - F3 (`.claude/rules/` start set);
    - F4.
  - **code-fact-check:** Endorsements 1–3 (`route: code-fact-check`).
  - **api-consistency-reviewer:** none; the `:416-420` comment's overstatement is the same defect as F3/F4.
