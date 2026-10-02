Commit: 90364c73 (main; delta 6f3d55e..5652d33f / 2fd9401..2da55741)

# Code Fact-Check Report

**Repository:** claude-workflows (`/workspace`, read-only; code identical at main 90364c73 and branch tip 2da55741; HEAD dff7fe8b adds only `docs/reviews`)
**Scope:** Partial: pass 38's final k=1 delta. A: `git diff 6f3d55e..5652d33f -- . ':!docs/reviews'` (scripts/dev-cycle.sh). B: `git diff 2fd9401..2da55741 -- . ':!docs/reviews'` (scripts/dev-cycle.sh, skills/dev-cycle/SKILL.md, test/scripts/dev-cycle.bats), and the messages of 11714a3, b684ff2, 91b88d7, 6f3d55e, 2e65ad5 and 5652d33f. Everything else is context only.
**Checked:** 2026-10-02
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 27
**Summary:** 21 verified, 1 mostly accurate, 0 stale, 4 incorrect, 1 unverifiable

I read the hallucination pattern log (`docs/reviews/hallucination-patterns.md`, 5 patterns) before checking. No claim here matches a logged pattern. All four Incorrect verdicts are gaps in a mechanism, not fabricated symbols, so none of them belongs in the log. I did not write to the log anyway: my role instructions allow only this report.

Not re-filed: everything in the rubric's "Full review 1" and "Pass 37" sections, and the stale messages of fa2b9b3 and 2839cc4. Pass 37 API findings 3 (the `check_fix` block comment at `:404-408` lags the help) and 6 (the `*`/`_` asymmetry in answers) were not among 5652d33f's targets, and I do not re-file them. The pass-37 fact-check report (`docs/reviews/code-fact-check-report-digest-pass37.md`, committed at dff7fe8b after the rubric's Pass 37 section) was never read by the loop. Two of its findings survive 5652d33f, and I name them where they reappear (Claims 4a and 5).

## Headline

- **Incorrect, Medium severity, and a regression from 6f3d55e (Claim 4a, also 1b).** The import token now stops at `_` and `*` (`IMPORT_RE='(^|[[:space:](*_])@[^[:space:]`)*_]+'`, `scripts/dev-cycle.sh:423`). As a result, `@docs/my_notes.md` is recorded as `docs/my`, and `--check-fix docs/my_notes.md` prints `ok`.
  - 6f3d55e refused that file, because its token class allowed `_`.
  - Claude Code 2.1.288 reads the whole path. Its `@` regex is `[^\s\\]`, marked merges adjacent text tokens, and an intraword `_` cannot open emphasis.
  - Preconditions: an instruction file `@`-imports a `docs/**.md` file (or `README.md`) whose path contains `_`. Underscored doc names are common.
  - The failure direction is unsafe, which the acceptance bar counts as a finding: an in-cycle fix may edit a file Claude Code loads as instructions.
  - The same claim also fails for `#fragment` imports. That gap is the pass-37 fact-check's Claim 5a, still unfixed.
- **Incorrect, Low severity (Claim 6b).** `realpath -ms` keeps a symlink's own path, but Claude Code reads the symlink's target. With `@docs/link.md -> real.md` or `@lnk/y.md` (where `lnk -> docs`), the files `docs/real.md` and `docs/y.md` print `ok`. 6f3d55e refused `docs/y.md` by basename, so this is also a regression.
- **Incorrect, Low severity (Claim 7).** "~/ and absolute paths lead outside the repo": an absolute import that points inside the repo leads inside it. Claude Code loads such a file, but the script prints `ok docs/abs.md`.
- **Mostly accurate (Claim 5).** "every instruction file in the checkout, tracked or not" is true for tracked, untracked and gitignored files, including a root-level `AGENTS.local.md`. It is not true for a symlinked instruction file, which is never a starting point (the pass-37 fact-check's Claim 5b, now against the wider wording).
- **Escalation to performance-reviewer (no claim refuted).** The first `--check-fix` call forks `lower` (`printf | tr`) once per listed path, and both untracked producers list every ignored `*.md` (P5). With 4,000 ignored `.md` files under `node_modules/`, one `--check-fix` call went from 0.03 s at 6f3d55e to 9.7–11.5 s at 5652d33f. The producers themselves take 0.04 s.
- **Everything else verified.** This covers:
  - the transitive and relative-directory resolution;
  - the skip-reason wordings;
  - gitlink and tree briefs;
  - the `%cd` dates, including the quoted-name fallback;
  - the bold-label answer rule;
  - the help range;
  - the skill's paste-block rule, batching and "check 3";
  - both test names;
  - the gates: 51/51, shellcheck rc 0, hermeticity lint rc 0;
  - "README.md is still fixable in this repo".

## Execution provenance

Every probe is one script that starts with `set -eu`, creates its own `mktemp -d -p /tmp/claude-1000/pass38-fc` directory and checks `case "$PWD"` before any clone, `git init`, commit or write. Every process ran under `timeout`, in the foreground, and had finished before this report was written. Fixture instruction files use `GEMINI.md`/`AGENTS.md`, never `CLAUDE.md`, because a policy hook blocks Bash writes that name `CLAUDE.md`. The script's regex treats all of these names the same: `INSTRUCTION_FILE`, `:413`.

| Probe | Command (cwd `/tmp/claude-1000/pass38-fc`) | Exit | Start (UTC) | Captured output |
|---|---|---|---|---|
| P1 | `timeout 1200 bash p1.sh`: clone at 90364c73; bats count/run, shellcheck, hermeticity lint, `--help` tail, `--check-fix` over all 689 tracked `README.md`/`docs/**.md` at 2fd9401, 6f3d55e, 5652d33f | 0 | 2026-10-02T22:11:18Z | `tmp.0HPkrvw849/p1.log`, `bats.log`, `fix-*.txt` |
| P2 | `timeout 600 bash p2.sh`: synthetic repo; import forms, transitive, relative, symlinks, untracked/ignored instruction files; 5652d33f (`new`) vs 6f3d55e (`old`) | 0 | 2026-10-02T22:13:40Z | `tmp.gCuZGFJe0v/p2.log` |
| P3 | `timeout 900 bash p3.sh`: brief tree/100755/parent symlink, dotfile reason, `a$(id)`, eight answer-label shapes at 5652d33f, 6f3d55e, 2fd9401 | 0 | 2026-10-02T22:15:25Z | `tmp.YdnimfyRe0/p3.log` |
| P4 | `timeout 600 bash p4.sh`: gitlink brief; author 2020-01-01 vs committer 2026-09-30T23:30-0500 dates (decision records incl. a git-quoted name, roadmap); absolute in-repo import | 0 | 2026-10-02T22:15:49Z | `tmp.t0t6b3n0ax/p4.log` |
| P5 | `timeout 900 bash p5.sh`: 24,000 ignored files (4,000 `.md`) under `node_modules/`; `--check-fix` timing, old vs new, and producer timing | 0 | 2026-10-02T22:16:02Z | `tmp.P86UhZ0nFc/p5.log` |
| P6 | `timeout 700 bash p6.sh`: clone; `--check-answer` over all 103 IDs in `questions.md` + archive at 2fd9401 vs 90364c73 | 0 | 2026-10-02T22:16:50Z | `tmp.rNTARTCTEH/p6.log` |
| S1 | read-only in `/workspace`: the two untracked producers' pathspecs via `git ls-files`, instruction-name filter, `IMPORT_RE` grep | 0 | 2026-10-02T22:12Z | `ws-others.txt`, `ws-ign.txt`, `ws-instr.txt` |

The Claude Code reference behaviour is quoted from the installed bundle `/usr/local/share/npm-global/lib/node_modules/@anthropic-ai/claude-code/bin/claude.exe` (2.1.288). I read it statically with `grep -a -o`. I did not run Claude Code, because it would write session state outside the scratch dir.

---

## Claim 1a: help `--check-fix`: "a tracked .md file under docs/ (not the cycle's own files, working/, human-author/, reviews/, decisions/, dev-cycle.md, a dot-directory or dotfile, an instruction file …; compared ignoring case) or README.md"

**Location:** `scripts/dev-cycle.sh:50-55` (same list: `skills/dev-cycle/SKILL.md:72-76`; 11714a3 and 2e65ad5 messages)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers every exclusion in the list except the import clause (Claim 1b): the cycle's own files, the four directories, dev-cycle.md, dot-directories and dotfiles, instruction files, and the case folding. It does not establish the import clause.

The code tests each listed exclusion on the lower-cased path:

```bash
# scripts/dev-cycle.sh:457-461
  if writable "$a" || writable "$lp"; then echo "skip $a: one of the cycle's own files (use --check-write)"
  elif [[ ! "$lp" =~ ^docs/.*\.md$|^readme\.md$ || "$lp" =~ ^docs/(working|human-author|reviews|decisions)/ \
    || "$lp" == docs/dev-cycle.md || "$a" == */.* || "$low" =~ $INSTRUCTION_FILE ]]; then
    echo "skip $a: in-cycle fixes edit only tracked .md documentation under docs/ (not working/, …) and README.md; file it instead"
  elif [[ "$IMPORTED" == *$'\n'"$lp"$'\n'* ]]; then
```
(excerpt ends :461; enclosing `check_fix()` continues to :464 `else check_path "$a"; fi` — read)

Results:
- P1: bats test 50 passes. It covers `docs/Working/notes.md` and `docs/Dev-Cycle.md`, and both print skips.
- P3: `docs/.x.md` and `docs/.hid/a.md` both get the generic skip.
- P1: across all 689 tracked `README.md`/`docs/**.md` files, 14 print `ok`, the same 14 at 2fd9401, 6f3d55e and 5652d33f.

**Evidence:** `scripts/dev-cycle.sh:449-464`; `skills/dev-cycle/SKILL.md:72-76`; P1 `tmp.0HPkrvw849/bats.log`, `fix-5652d33f.txt`; P3 `tmp.YdnimfyRe0/p3.log`

---

## Claim 1b: help and skill: "…or a file an instruction file imports with @…"

**Location:** `scripts/dev-cycle.sh:53-54`; `skills/dev-cycle/SKILL.md:74-75` (2e65ad5: "The in-cycle fix scope names … files an instruction file imports with @ … as --check-fix now does")
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers which imported files `--check-fix` refuses, measured against what Claude Code 2.1.288 loads. It does not establish behaviour for other harnesses that read `GEMINI.md`/`AGENTS.md`.

The skill tells the cycle agent that the refusal set includes every file an instruction file imports. P2 shows `ok` for several files that Claude Code loads through an `@` import:
- `docs/my_notes.md`, imported as `@docs/my_notes.md` (Claim 4a);
- `docs/q.md`, imported as `@docs/q.md#intro` (Claim 4a);
- `docs/real.md`, through the symlink `@docs/link.md`, and `docs/y.md`, through the symlinked directory `@lnk/y.md` (Claim 6b);
- `docs/viasym.md`, imported by a symlinked instruction file (Claim 5).

P4 adds `docs/abs.md`, imported by its absolute in-repo path (Claim 7). Quoted P2 output:

```
ok docs/my_notes.md
ok docs/q.md
ok docs/real.md
ok docs/y.md
ok docs/viasym.md
```

The skill reads this list as the complete refusal set (`SKILL.md:71-77`: "edits only a file that `--check-fix '<path>'` prints `ok` for"). A file in any of these shapes is therefore editable while the docs say it is not. This is a safety control (the rubric's full review 1, finding A1, rated Medium), and the misses fail open.

**Evidence:** `scripts/dev-cycle.sh:53-54,423-447`; `skills/dev-cycle/SKILL.md:71-77`; P2 `tmp.gCuZGFJe0v/p2.log`; P4 `tmp.t0t6b3n0ax/p4.log`

---

## Claim 2: `-h|--help) sed -n '2,77p'` prints the whole header (11714a3: "Help range moved")

**Location:** `scripts/dev-cycle.sh:141`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the range end at 90364c73. It does not establish that the range stays right after later header edits.

Line 77 is `# default branch (for the digest, --check-brief and --check-branch); a failed step exits non-zero mid-digest. Printed repo text is data.`, and line 78 is blank. P1's `--help | tail -3` ends with that sentence.

**Evidence:** `scripts/dev-cycle.sh:76-78,141`; P1 `tmp.0HPkrvw849/p1.log`

---

## Claim 3: "Only a regular file counts: a symlink's blob is its target text, not a brief, and a gitlink or tree is not a brief either." (5652d33f: "A gitlink or tree at a brief path is a skip, not 'new' (mode read before the blob test)")

**Location:** `scripts/dev-cycle.sh:355-361`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers gitlink, tree, symlink, 100755, absent, and a path whose parent is a symlink on the default branch. It does not establish behaviour for a working-tree path that `blocker` refuses first (unchanged by this delta).

```bash
# scripts/dev-cycle.sh:357-361
  case "$(git ls-tree "$MAIN_SHA" -- "$a" | cut -c1-6)" in
    '') echo "ok $a new"; return ;;
    100644|100755) ;;
    *) echo "skip $a: not a regular file on the default branch"; return ;;
  esac
```
(excerpt ends :361; enclosing `check_brief()` continues to :384 — read: the blob is read only after this gate)

Results:
- Gitlink on main (P4): `skip docs/working/briefs/2026-01-01-gl.md: not a regular file on the default branch`. The base version, 2fd9401, printed `ok … new`.
- Tree, with a directory named `2026-01-02-tr.md` on main (P3): the same skip. 2fd9401 printed `ok … new`.
- 100755 brief: `ok … open <sha>`.
- Brief under a `closed/` that is a symlink on main: `ok … new`. `ls-tree` does not traverse a symlink, so main holds no file at that path, which matches the help's "when the default branch has no file there".

**Evidence:** `scripts/dev-cycle.sh:348-384`; P3 `tmp.YdnimfyRe0/p3.log`; P4 `tmp.t0t6b3n0ax/p4.log`

---

## Claim 4a: "Paths, lower-cased, that instruction files pull in with an @ import (Claude Code's "@path" syntax)" (5652d33f: "walks imports the way Claude Code reads them")

**Location:** `scripts/dev-cycle.sh:414-415,423`; 5652d33f body, first bullet
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers how a single `@` token is cut, measured against Claude Code 2.1.288's parser: `_` and `*` inside a path, and a `#fragment`. It does not establish symlink resolution (Claim 6b) or absolute paths (Claim 7).

The token class excludes `_` and `*`, so a token ends at the first `_`. No step drops a `#fragment`:

```bash
# scripts/dev-cycle.sh:423
IMPORT_RE='(^|[[:space:](*_])@[^[:space:]`)*_]+'
# scripts/dev-cycle.sh:439-442
      t="${t#*@}"
      while [[ "$t" == *[.,\;:!?] ]]; do t="${t%?}"; done
      [[ -n "$t" && "$t" != "~"* && "$t" != /* ]] || continue
      p="$(realpath -ms --relative-to="$ROOT_REAL" -- "$ROOT_REAL/${d:+$d/}$t" 2>/dev/null)" || continue
```
(excerpt ends :442; enclosing `imported_names()` continues to :447 — read)

Claude Code's parser, from the installed bundle (function `VWn`), keeps `_` and cuts at `#`:

```js
let S=/(?:^|\s)@((?:[^\s\\]|\\ )+)/g … let B=w[1]; … let H=B.indexOf("#");if(H!==-1)B=B.substring(0,H);
```

Its markdown lexer keeps `my_notes` in one text token. It merges adjacent text tokens (`let x=n.at(-1);if(x?.type==="text")x.raw+=S.raw,x.text+=S.text`). Its `emStrong` also returns early for a `_` that follows a letter (`if(s[3]&&r.match(this.rules.other.unicodeAlphaNumeric))return;`).

P2, with a `GEMINI.md` line `Read @docs/my_notes.md and @docs/q.md#intro.`, gave this at 5652d33f:

```
ok docs/my_notes.md
ok docs/my.md
ok docs/q.md
```

At 6f3d55e it gave `skip docs/my_notes.md: <IMPORT>`. `docs/my.md` prints `ok` in both versions because the token resolves to `docs/my`, with no extension, and so matches nothing.

So the underscore case is a regression introduced by 5652d33f. The fragment case is the pass-37 fact-check's Claim 5a, still open.

**Severity:** Medium for `_`, Low for `#`.
- The `_` precondition is ordinary: an instruction file imports a doc whose path has an underscore, such as `@docs/CODING_STANDARDS.md`.
- Failure direction: fail-open on a safety control.

The other half of the 5652d33f bullet, "Tokens after emphasis marks … count", is right (Claim 9). It is the token's end, not its start, that is wrong.

**Evidence:** `scripts/dev-cycle.sh:414-447`; installed bundle `claude.exe` 2.1.288 (`VWn`, marked `inlineTokens` and `emStrong`); P2 `tmp.gCuZGFJe0v/p2.log`

---

## Claim 4b: "…followed transitively: such a file is read as instructions"

**Location:** `scripts/dev-cycle.sh:415-416`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers chains of plain `.md` files, three hops deep, with relative paths at each hop. It does not establish depth parity with Claude Code: the script follows without limit and Claude Code stops at `YWn=5`. That difference over-refuses and fails safe.

The queue appends every newly seen plain file (`if [[ "$seen" != *$'\n'"$p"$'\n'* ]] && inrepo "$p"; then seen+="$p"$'\n'; queue+=("$p"); fi`, `:445`).

P2 results:
- `GEMINI.md` imports `@docs/a.md`, which imports `@n.md` and `@../docs/n2.md`. `docs/n.md` imports `@deep.md`. `docs/n.md`, `docs/n2.md` and `docs/deep.md` all print `skip …: <IMPORT>`. At 6f3d55e all three printed `ok`.
- `docs/a.md` also writes `@docs/notrel.md`, which resolves to `docs/docs/notrel.md`. `docs/notrel.md` stays `ok`, which is correct.

**Evidence:** `scripts/dev-cycle.sh:435-447`; bundle `var YWn=5`, `qJ` (`s>=YWn` return); P2 `tmp.gCuZGFJe0v/p2.log`

---

## Claim 5: "The walk starts at every instruction file in the checkout, tracked or not (CLAUDE.local.md is usually gitignored)" (5652d33f: "from every instruction file in the checkout, tracked or not (a gitignored CLAUDE.local.md counts)")

**Location:** `scripts/dev-cycle.sh:416-418,428-434`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers tracked, untracked-unignored and gitignored instruction files, including root-level and nested ignored ones, and the NUL-separated producers. It does not establish symlinked instruction files, which are excluded, or instruction files inside a nested git repository, which `ls-files` does not enter.

```bash
# scripts/dev-cycle.sh:428-434
  while IFS= read -r -d '' f; do
    if [[ ! "$(lower "${f##*/}")" =~ $INSTRUCTION_FILE ]] || ! inrepo "$f"; then continue; fi
    [[ "$seen" == *$'\n'"$f"$'\n'* ]] && continue
    seen+="$f"$'\n'; queue+=("$f")
  done < <(git ls-files -z
           GIT_LITERAL_PATHSPECS=0 git ls-files -z --others -- ':(glob,icase)**/*.md'
           GIT_LITERAL_PATHSPECS=0 git ls-files -z --others --ignored --exclude-standard -- ':(glob,icase)**/*.md')
```
(excerpt ends :434; the queue walk follows at :435-446 — read)

What holds:
- P2: a gitignored root `AGENTS.local.md`, an untracked `GEMINI.local.md` and an ignored `node_modules/pkg/AGENTS.md` each get their imports refused (`skip docs/loc.md`, `skip docs/unt.md`, `skip docs/nm.md`; all three printed `ok` at 6f3d55e).
- `:(glob,icase)**/*.md` matches root-level files.
- All three producers emit NUL-separated paths.
- `--others` without `--exclude-standard` already lists ignored files: S1 found all 487 of its paths among the third producer's 525. So the third producer adds only nested-repository directory entries such as `external/SWRBench2/`, which the name filter drops.

What does not hold:
- `inrepo` requires a plain regular file (`inrepo() { [[ -z "$(blocker "$1" file)" && -f "$1" ]]; }`, `:179`). A tracked `tools/AGENTS.md -> ../notes/real-instr.md` holding `@../docs/viasym.md` is therefore never a starting point, and P2 prints `ok docs/viasym.md`.
- Claude Code loads symlinked memory files. Its `So` returns `isCanonical:!0` after a successful `realpathSync`, and `N$` skips only non-canonical links.
- The precise wording is "every plain (non-symlink) instruction file".
- The common `CLAUDE.md -> AGENTS.md` link is still covered, because its target is itself a plain instruction file in the same directory. That is why this is Mostly accurate and not Incorrect.

This is the pass-37 fact-check's Claim 5b, now against the wider "every … in the checkout" wording.

**Evidence:** `scripts/dev-cycle.sh:179,416-434`; bundle `So`, `N$`, `qJ`; P2 `tmp.gCuZGFJe0v/p2.log`; S1 `ws-others.txt`, `ws-ign.txt`

---

## Claim 6a: "resolves each @path against the importing file's directory as Claude Code does" (5652d33f: "resolving each @path against the importing file's directory"): relative resolution

**Location:** `scripts/dev-cycle.sh:418-419,437,442`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers `./`, `../`, bare relative paths and nested directories for plain (non-symlink) paths. It does not establish symlinked paths (6b), absolute paths (Claim 7) or case differences. A case difference over-refuses, because both sides are lower-cased, and a wrongly cased path is not followed on a case-sensitive filesystem, where Claude Code would not load it either.

`if [[ "$f" == */* ]]; then d="${f%/*}"; else d=""; fi` (`:437`) feeds `"$ROOT_REAL/${d:+$d/}$t"` (`:442`). Claude Code also resolves against the importing file's directory: `let V=it(B,fv(n));r.add(V)`, where `fv` is the directory name.

P2 results:
- `sub/AGENTS.md` with `@../docs/c.md` gives `skip docs/c.md`.
- `docs/guides/AGENTS.md` with `@g2.md` gives `skip docs/guides/g2.md` and `ok docs/g2.md`. At 6f3d55e, `docs/g2.md` was over-refused by basename.
- `@./docs/b.md` gives a skip.
- `@../outside.md` is dropped by `[[ "$p" != ..* ]]`.

**Evidence:** `scripts/dev-cycle.sh:435-446`; bundle `VWn`; P2 `tmp.gCuZGFJe0v/p2.log`

---

## Claim 6b: the same "as Claude Code does", for a path through a symlink

**Location:** `scripts/dev-cycle.sh:418-419,442,444-445`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the script's side, run against a committed file symlink and a committed directory symlink. Claude Code's side is read statically from the bundle, not run, hence Medium. It does not establish behaviour for symlinks pointing outside the project, which Claude Code rejects at depth > 0 unless external includes are allowed.

`realpath -ms` (`-s`: do not expand symlinks) records the link's own path. `inrepo "$p"` then refuses to queue the link, so neither the target nor the target's own imports are ever reached:

```bash
# scripts/dev-cycle.sh:442-445
      p="$(realpath -ms --relative-to="$ROOT_REAL" -- "$ROOT_REAL/${d:+$d/}$t" 2>/dev/null)" || continue
      [[ "$p" != ..* ]] || continue
      IMPORTED+="$(lower "$p")"$'\n'
      if [[ "$seen" != *$'\n'"$p"$'\n'* ]] && inrepo "$p"; then seen+="$p"$'\n'; queue+=("$p"); fi
```
(excerpt ends :445; the read loop closes at :446 and the function at :447 — read)

Claude Code resolves the link and reads the target: `K=So(ie(),e),{resolvedPath:V,isSymlink:he}=K; … await Rmt(e,n,V,S)` in `qJ`, where `So` calls `realpathSync`. It requires only that the target is inside the project (`!oO(V)`).

P2 results:
- `@docs/link.md`, where `docs/link.md -> real.md`, gives `skip docs/link.md` but `ok docs/real.md`.
- `@lnk/y.md`, where `lnk -> docs`, gives `ok docs/y.md`. 6f3d55e refused `docs/y.md` by basename, so this case is a regression.

Severity Low:
- Precondition: a committed symlink on an import path.
- Failure direction: fail-open.

**Evidence:** `scripts/dev-cycle.sh:150,179,442-445`; bundle `qJ`, `So`; P2 `tmp.gCuZGFJe0v/p2.log`

---

## Claim 7: "(~/ and absolute paths lead outside the repo and are not followed)"

**Location:** `scripts/dev-cycle.sh:419-420,441`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers an absolute import whose target is inside the checkout. It does not establish a `~/` path into the checkout, which needs the repo under `$HOME`. That case follows the same `"~"*` skip, so it is the same by reading.

`[[ -n "$t" && "$t" != "~"* && "$t" != /* ]] || continue` (`:441`) drops every absolute or `~` token without checking where it leads. Claude Code accepts `B.startsWith("/")&&B!=="/"` and loads the target when it is inside the project (`if(g>0&&!H&&!oO(V))return[]` only drops targets outside it). P4, with a `GEMINI.md` line `@<repo realpath>/docs/abs.md`: `ok docs/abs.md`.

Severity Low:
- Absolute imports are machine-specific. The likeliest place for one is a personal, gitignored `CLAUDE.local.md`, which the walk now reads.
- Failure direction: fail-open.

The precise wording would be: "~/ and absolute paths are not followed (one that points into the repo is missed)". Alternatively, resolve them and keep any that land inside `$ROOT_REAL`.

**Evidence:** `scripts/dev-cycle.sh:441`; bundle `VWn`, `qJ`; P4 `tmp.t0t6b3n0ax/p4.log`

---

## Claim 8: "reads each plain file it reaches once" / "Computed once" (5652d33f: "following each plain file it reaches once")

**Location:** `scripts/dev-cycle.sh:420-421,427,445`
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers deduplication by exact path and the once-per-process memo. It does not establish parity with Claude Code's text-extension filter: the script also follows non-`.md` files, such as `@notes.txt` → `skip docs/t.md`, which over-refuses and fails safe. It also does not cover cost (see the Goal-Alignment Note).

`seen` gates both the starting set (`:430`) and the queue (`:445`), and `[[ -n "$IMPORTED_DONE" ]] && return; IMPORTED_DONE=1` (`:427`) makes the whole walk run once for all `--check-fix` arguments. P2 passed 32 arguments in one call, and all of them were answered from one walk.

**Evidence:** `scripts/dev-cycle.sh:425-447`; P2 `tmp.gCuZGFJe0v/p2.log`

---

## Claim 9: "A token may sit after a blank, ( or emphasis marks, and loses trailing punctuation." (5652d33f: "Tokens after emphasis marks and with trailing punctuation count.")

**Location:** `scripts/dev-cycle.sh:420-421,423,440`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the token's left context and the trailing `.,;:!?` strip. It does not establish where the token ends (Claim 4a).

Left context `(^|[[:space:](*_])` (`:423`), and the strip `while [[ "$t" == *[.,\;:!?] ]]; do t="${t%?}"; done` (`:440`). P2 shows that `_@docs/e1.md_`, `*@docs/e2.md*`, `**@docs/g.md**`, `@docs/p.md.` and `(@docs/paren.md)` all print `skip …: <IMPORT>`.

These match or exceed Claude Code:
- Claude Code recurses into `strong`/`em` tokens, whose inner text starts with `@`, so it does load the emphasis cases.
- It does not load `(@…)`, and it keeps trailing punctuation in the path, so it loads nothing for `docs/p.md.`. Refusing those cases is fail-safe.
- An inline code span `` `@docs/span.md` `` is not refused (`ok docs/span.md`), matching Claude Code's `codespan` skip.
- A fenced `@docs/fenced.md` is refused, which over-refuses and fails safe.

**Evidence:** `scripts/dev-cycle.sh:423,438-446`; bundle `VWn`; P2 `tmp.gCuZGFJe0v/p2.log`

---

## Claim 10: "Compared lower-cased: on a case-insensitive filesystem docs/Working/ is docs/working/."

**Location:** `scripts/dev-cycle.sh:453-455,461`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the exclusions and the import match. For brief item 3 it also covers this: `lp` and `IMPORTED` entries compare in the same normal form for every path `pathform` accepts. It does not establish anything about a case-insensitive filesystem, which was not available.

`lp="$(printf '%s' "$a" | tr 'ABC…' 'abc…')"` (`:454`) feeds `writable "$lp"`, every exclusion except the case-free dot test, and the import match `"$IMPORTED" == *$'\n'"$lp"$'\n'*` (`:461`).

`pathform` rejects empty, `.` and `..` components and a leading `/` (`[[ -n "$c" && "$c" != "." && "$c" != ".." && … ]] || return 1`, `:210`). So `lp` is always the normalized relative form that `realpath -m --relative-to` produces, and the two sides differ only in case, which both lower-case.

P2: `skip DOCS/MIXED.MD: <IMPORT>` and `skip docs/Mixed.md: <IMPORT>` for an `@docs/Mixed.md` import. Bats test 50 covers `docs/Working/notes.md` and `docs/Dev-Cycle.md`.

**Evidence:** `scripts/dev-cycle.sh:203-212,449-464`; P1 `bats.log`; P2 `tmp.gCuZGFJe0v/p2.log`

---

## Claim 11: skip reason "(not working/, human-author/, reviews/, decisions/, dev-cycle.md, dot-directories or dotfiles, or instruction files)" (5652d33f: "The skip reason says 'dot-directories or dotfiles' like the help.")

**Location:** `scripts/dev-cycle.sh:460`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the wording against the branch it reports, for a dotfile and a dot-directory. It does not establish that it names the cycle's own files, which have their own reason at `:457`.

P3: `skip docs/.x.md: in-cycle fixes edit only tracked .md documentation under docs/ (not working/, human-author/, reviews/, decisions/, dev-cycle.md, dot-directories or dotfiles, or instruction files) and README.md; file it instead`. `docs/.hid/a.md` gets the same line. This closes pass-37 API finding 1.

**Evidence:** `scripts/dev-cycle.sh:458-460`; P3 `tmp.YdnimfyRe0/p3.log`

---

## Claim 12: skip reason "an instruction file imports it with @ (directly or through another import), so it is read as instructions"

**Location:** `scripts/dev-cycle.sh:462`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the reason being printed for both direct and transitive imports. It does not establish that every imported file gets it (Claims 1b, 4a, 6b, 7).

P2 shows the reason for `docs/a.md` (direct) and for `docs/n.md` and `docs/deep.md` (through `docs/a.md`).

**Evidence:** `scripts/dev-cycle.sh:461-462`; P2 `tmp.gCuZGFJe0v/p2.log`

---

## Claim 13: ANSWER_AWK: "…and then ends at the bold's close if it opened inside the bold … (a word must be followed by the end, punctuation or a dash)"; inline "is the bold of the label still open at ': '?" (6f3d55e: "…no longer cut at the next **, and a word followed by * counts (**drop** because)")

**Location:** `scripts/dev-cycle.sh:485-489,499,532-534`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers eight label shapes and all 103 real IDs. It does not establish CommonMark parity for a label whose bold opens again after the colon. `**Answer: **keep**` reads `unrecognized`, where CommonMark renders "keep" in bold. That case fails safe, because the user is asked again, and so it sits under the acceptance bar's "design's cost".

```awk
# scripts/dev-cycle.sh:531-534
  } else if ((c = index(rest, ": ")) > 0) {
    e = index(rest, "**"); inbold = !(e > 0 && e < c)   # is the bold of the label still open at ": "?
    rest = substr(rest, c + 2)
    if (inbold && (e = index(rest, "**")) > 0) rest = substr(rest, 1, e - 1)
```
(excerpt ends :534; the rule continues to :536 `result = option(rest); done = 1` — read)

P3 results (5652d33f / 2fd9401):

| Label | 5652d33f | 2fd9401 |
|---|---|---|
| `**Answer (2026-10-02)**: **[2]**` | `drop` | `unrecognized` |
| `**Answer:** **keep**.` | `keep` | `unrecognized` |
| `**Answer (d)**: **drop** because` | `drop` | `unrecognized` |
| `**Answer:** drop*` | `drop` | `unrecognized` |
| `**Answer (d)**: drop **because** x` | `unrecognized` | `drop` |

The last row is the documented hedge rule. 6f3d55e and 5652d33f agree on all eight shapes.

**Evidence:** `scripts/dev-cycle.sh:476-541`; P3 `tmp.YdnimfyRe0/p3.log`; P6 `tmp.rNTARTCTEH/p6.log`; bats test 51

---

## Claim 14: "last committed" dates use the committer date, as the window does (6f3d55e: "'last committed' dates (decision records, roadmap) use the committer date, as the window does")

**Location:** `scripts/dev-cycle.sh:680,695,779`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the map path, the per-file fallback for a git-quoted name, the roadmap, and a non-UTC committer zone. It does not establish the merge sample's display date (`:652` still prints `%ad`), which the message does not claim.

P4 used a commit with author date 2020-01-01 and committer date 2026-09-30T23:30-0500. For it, `%cs=2026-09-30  %cd-short=2026-09-30  %ad-short=2020-01-01`, and the digest printed:

```
### docs/decisions/001-r.md (last committed on this branch: 2026-09-30)
### docs/decisions/002-q"x.md (last committed on this branch: 2026-09-30)
docs/roadmap.md last committed on this branch: 2026-09-30. Its Next section:
```

2fd9401 printed 2020-01-01 for all three. `002-q"x.md` takes the `:695` fallback, because git quotes the name and the map misses it.

**Evidence:** `scripts/dev-cycle.sh:651-655,676-698,778-780`; P4 `tmp.t0t6b3n0ax/p4.log`

---

## Claim 15: "Every mode takes many arguments: batch a step's values into one call per mode." (91b88d7)

**Location:** `skills/dev-cycle/SKILL.md:101-102`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers all six check modes. It does not establish that output order equals argument order for globbed `--check-path` arguments, which can expand to many lines.

Every usage line ends in `...` (`:9-14`). The dispatcher loops `for a in "${CHECK_ARGS[@]}"; do` (`:595`). P2 ran `--check-fix` with 32 arguments, P3 ran `--check-brief` with 5 and `--check-answer` with 8, and P6 ran `--check-answer` with 103.

**Evidence:** `scripts/dev-cycle.sh:9-14,135-140,595`; P2, P3, P6 logs

---

## Claim 16: "Only a name that `--check-branch` prints `ok` for goes into that entry's paste block (git allows names such as `a$(id)`, which a paste would run)" (2e65ad5)

**Location:** `skills/dev-cycle/SKILL.md:170-175`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers git's acceptance of the example and the check's refusal of it. It does not establish that every `ok` name is inert in every shell. Names are limited to `[$NAMECHARS]` (letters, digits, `. _ - /`) and cannot start with `-`, so I know of no metacharacter that gets through.

P3 results:
- `git check-ref-format --branch 'a$(id)'` prints `a$(id)`, with exit 0.
- `--check-branch 'a$(id)' feat/x` prints `skip a$(id): not an allowed branch name` and `absent feat/x`.

`check_branch` emits `ok` only after `[[ ! "$a" =~ ^[$NAMECHARS]+$ || "$a" == -* ]]` fails (`:394`).

**Evidence:** `scripts/dev-cycle.sh:202,393-405`; P3 `tmp.YdnimfyRe0/p3.log`

---

## Claim 17: "`Asked:` line (check 3 below writes them…)" and "keep-or-drop entry, which check 3 files" (b684ff2)

**Location:** `skills/dev-cycle/SKILL.md:290,299`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the two edited references. It does not establish every other "step N" reference in the skill.

In flight's item 3 (`SKILL.md:304-311`) files the `you: judgment` keep-or-drop entry and "add[s] its ID to `Asked:`". "Step 3" is the Flow's watched-questions step ("3 watched questions (step 3)", `:138`). The b684ff2 message's "called checks elsewhere" matches `:91` ("In flight's check 1") and `:274` ("so check 1 can close it").

**Evidence:** `skills/dev-cycle/SKILL.md:91,138,274,290,299,304-311`

---

## Claim 18: test names "--check-fix refuses files an instruction file imports, and compares paths ignoring case" and "--check-brief refuses a brief that is a symlink on the default branch; a bold-closed label answer is read"

**Location:** `test/scripts/dev-cycle.bats:966,980`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers what each test asserts: direct imports from a tracked `GEMINI.md`, and two case skips; a symlinked brief, and two bold-closed labels. It does not establish coverage of 5652d33f's new behaviour. No test exercises a transitive import, an untracked or ignored instruction file, relative resolution, a gitlink or tree brief, or the `_` case of Claim 4a. That is a test-strategy note, not a wording issue.

Both tests pass in P1 (`ok 50 …`, `ok 51 …`). The bodies assert exactly what the names say (`:967-977`, `:981-990`).

**Evidence:** `test/scripts/dev-cycle.bats:966-990`; P1 `tmp.0HPkrvw849/bats.log`

---

## Claim 19a: 5652d33f: "It matches the full resolved path, not the basename"

**Location:** 5652d33f body, first bullet; `scripts/dev-cycle.sh:444,461`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the match key. It does not establish what the resolved path is for symlinks (Claim 6b).

`IMPORTED+="$(lower "$p")"$'\n'` (`:444`) stores the whole relative path. P2 results:
- `docs/g2.md` prints `ok` while `docs/guides/g2.md` is refused. 6f3d55e refused both.
- `docs/my.md` is not refused by a `docs/my` token.

**Evidence:** `scripts/dev-cycle.sh:444,461`; P2 `tmp.gCuZGFJe0v/p2.log`

---

## Claim 19b: 5652d33f: "…so prose mentions in review records no longer refuse README.md"

**Location:** 5652d33f body, first bullet
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers committed history at 6f3d55e and the current walk. It does not establish what an uncommitted intermediate version did.

No committed version refused `README.md` in this repo:
- At 6f3d55e, 5652d33f and 2da55741, the only `@` token in any tracked instruction file is `skills/dependency-upgrade/SKILL.md:175: @org/migrate"}`, from `git show <rev>:<file> | grep` over every instruction-named path.
- P1: `ok README.md` at 2fd9401, 6f3d55e and 5652d33f.
- Review records are not instruction files, so no committed walk scans them.

The "no longer" most likely describes a state during 5652d33f's development. That cannot be checked from history. It is harmless either way: the current behaviour is right (Claim 20).

**Evidence:** P1 `tmp.0HPkrvw849/fix-*.txt`; `git show` loop over `git ls-tree -r` at the three revisions (read-only)

---

## Claim 20: 5652d33f: "51/51; shellcheck and the hermeticity lint clean; README.md is still fixable in this repo."

**Location:** 5652d33f body, last bullet
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the clone at 90364c73 and, read-only, `/workspace`'s untracked and ignored instruction files. It does not establish `README.md` in the other sessions' worktrees, which I did not read.

P1 results:
- `bats --count` prints 51, the run is rc 0, and 51 lines start `ok `.
- `shellcheck scripts/dev-cycle.sh` rc 0.
- `hermeticity-lint: 126 test file(s) checked, no unstubbed network spawns`, rc 0.
- `ok README.md`.

S1: `/workspace` has 34 untracked or ignored instruction files (`devcontainer-config/claude-home/**`). Their only `@` token is `@org/migrate"}`, which resolves under `devcontainer-config/claude-home/skills/dependency-upgrade/` and not to `README.md`.

**Evidence:** P1 `tmp.0HPkrvw849/p1.log`, `bats.log`; S1 `ws-instr.txt`

---

## Claim 21: 6f3d55e: "all 103 real IDs read as before"

**Location:** 6f3d55e body
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the questions files committed at 90364c73. It does not establish the files in other worktrees.

P6: 103 IDs; 2fd9401 and 90364c73 give identical output (`3 done 19 drop 26 keep 13 open 42 unrecognized`), and `diff` printed nothing.

**Evidence:** P6 `tmp.rNTARTCTEH/p6.log`

---

## Claim 22: 91b88d7: "a cycle made about 18 single-item check calls where about 7 batched calls carry the same inputs"

**Location:** 91b88d7 body
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers faithful citation of the full-review performance report. It does not establish a measured call count from a real cycle.

The performance report says "about 18 calls per cycle where about 7 would do". Its derivation is one glob call, four calls for each of three briefs, and about four write calls: 1 + 12 + 4 = 17 ("roughly 18").

**Evidence:** `docs/reviews/performance-review-2026-10-02-devcycle-fullreview.md:67,78,141`

---

## Claim 23: b684ff2: "'step 3' is also the Watched questions step; the In flight sub-items are called checks elsewhere in the skill."

**Location:** b684ff2 body
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Same evidence as Claim 17. It does not establish a skill-wide audit of the "step"/"check" naming.

`SKILL.md:138` "3 watched questions (step 3)"; `:91` "In flight's check 1"; `:274` "so check 1 can close it".

**Evidence:** `skills/dev-cycle/SKILL.md:91,138,274`

---

## Claims Requiring Attention

### Incorrect
- **Claim 1b** (`scripts/dev-cycle.sh:53-54`, `skills/dev-cycle/SKILL.md:74-75`): "or a file an instruction file imports with @". Files that Claude Code loads still print `ok`: `_` paths, `#fragment` imports, symlink targets, imports in symlinked instruction files, and absolute in-repo paths. Either fix the walk or narrow the wording.
- **Claim 4a** (`scripts/dev-cycle.sh:414-415,423`; 5652d33f "the way Claude Code reads them"): the token stops at `_`/`*` and keeps `#…`, so `@docs/my_notes.md` and `@docs/q.md#intro` leave their targets fixable. The `_` case is a regression from 6f3d55e (Medium, fail-open). Drop `*_` from the token class, keep them only in the left context, and cut at `#`.
- **Claim 6b** (`scripts/dev-cycle.sh:418-419,442-445`): "as Claude Code does". `realpath -s` records the symlink, while Claude Code loads its target, so `docs/real.md` and `docs/y.md` stay fixable. `docs/y.md` is a regression from 6f3d55e (Low).
- **Claim 7** (`scripts/dev-cycle.sh:419-420,441`): "absolute paths lead outside the repo". An absolute path into the checkout is skipped, but Claude Code loads its target (Low).

### Stale
- None.

### Mostly Accurate
- **Claim 5** (`scripts/dev-cycle.sh:416-418`): "every instruction file in the checkout" should say "every plain (non-symlink) instruction file". A symlinked instruction file's imports are not walked (`ok docs/viasym.md`).

### Unverifiable
- **Claim 19b** (5652d33f body): "prose mentions in review records no longer refuse README.md". No committed version refused it. Checking the claim would need the uncommitted intermediate state it describes.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the path your role instructions give, structured per your skill file.
- Answered: This report is saved at `/workspace/docs/reviews/code-fact-check-report-2026-10-02-digest-pass38.md`, with the required first line and replication header, and is not committed.
  - It verdicts 27 claims from the A/B delta's comments, help, skill prose, test names and commit messages. All six "claims that particularly need checking" in the brief are covered:
    - 1 → Claims 4a, 4b, 5, 6a, 6b, 7, 8, 9, 19, 20;
    - 2 → Claim 5, plus cost below;
    - 3 → Claim 10;
    - 4 → Claim 3;
    - 5 → Claims 13, 14, 21;
    - 6 → Claims 1a, 11, 15, 16.
  - Rules I checked and found correct and complete: the relative and transitive resolution for plain paths, the gitlink/tree/symlink brief gate, the `lp`-vs-`IMPORTED` normal form, the dotfile wording, the bold-label cut for every documented label shape, the `%cd` dates, and the paste-block rule.
  - The pass does not come out clean on the import refusal: one Medium regression (Claim 4a, `_`) and three Low fail-open gaps (Claims 4a `#`, 6b, 7).
- Out of scope:
  - Running Claude Code itself. Its behaviour is read statically from the installed 2.1.288 bundle.
  - Other harnesses' import syntax for `GEMINI.md`/`AGENTS.md`.
  - The other sessions' worktrees.
  - Pass-37 API findings 3 and 6, which were not fix targets.
  - The hallucination-pattern log update: none qualifies, and my role allows writing only this file.
- Escalate:
  - **security-reviewer**:
    - `scripts/dev-cycle.sh:423` (`IMPORT_RE` token class drops `_`/`*`: `@docs/my_notes.md` is not refused; a regression of full-review A1's fix; Medium, fail-open);
    - `scripts/dev-cycle.sh:439-442` (no `#fragment` cut; `~`/absolute tokens dropped without checking whether they land in the repo);
    - `scripts/dev-cycle.sh:442-445` (`realpath -s` plus `inrepo` leave symlink targets and symlinked-directory paths fixable);
    - `scripts/dev-cycle.sh:429` (symlinked instruction files are not walked).
  - **performance-reviewer**: `scripts/dev-cycle.sh:428-434`.
    - The first `--check-fix` call forks `lower` (`printf | tr`) once per path from all three producers.
    - The two untracked producers each list every ignored `*.md` (`--others` without `--exclude-standard` already includes ignored files, so the third producer duplicates the second).
    - P5: 4,000 ignored `.md` files under `node_modules/` took one `--check-fix` call from 0.03 s (6f3d55e) to 9.7–11.5 s, while the producers themselves took 0.04 s.
    - The per-tracked-file fork predates this delta.
  - **api-consistency-reviewer**: none new. `scripts/dev-cycle.sh:53-54` and `skills/dev-cycle/SKILL.md:74-75` overstate the refusal set (Claim 1b), but that is the same defect as the security item, not a naming issue.
