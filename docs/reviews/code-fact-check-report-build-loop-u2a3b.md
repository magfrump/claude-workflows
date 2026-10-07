Commit: 1ccc8b65

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u2a3b (branch feat/build-loop-u2a3b)
**Scope:** range 45ad17b0..1ccc8b65 (one commit): the comments 1ccc8b65 adds or changes in `scripts/lib/dev-cycle-read.sh` (import_targets, imported_names, main_imports, isimported, the header block at :443-480), the two new test names in `test/scripts/build-loop-check.bats`, and the commit message of 1ccc8b65
**Checked:** 2026-10-06
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 37
**Summary:** 24 verified, 8 mostly accurate, 0 stale, 5 incorrect, 0 unverifiable

**Execution provenance (applies to every `executed` claim).** All runs were made in a scratch copy of the worktree at HEAD 1ccc8b65 (`git archive HEAD | tar -x -C /tmp/u2a3b-factcheck-FQ0K`), between 2026-10-06T23:27Z and 23:35Z, with GNU sed 4.9 and GNU bash 5.2.15. Captured output is in `/tmp/u2a3b-factcheck-FQ0K/_logs/`, outside the worktree, because the dispatch allows exactly one file in the worktree. Claude Code's side of each comparison comes from two sources. The first is the import-scanning code read from the installed binary `/usr/local/share/npm-global/lib/node_modules/@anthropic-ai/claude-code/bin/claude.exe` (`claude.exe --version` → `2.1.292 (Claude Code)`). The second is the U2a2 security review's differential harness: its marked lexer bytes and `reo` transcription were copied read-only from `/tmp/u2a2f-sec-nefJ/{marked.js,cc.js}` to `/tmp/u2a3b-factcheck-FQ0K/_cc/` (sha256 `768166b0…` marked.js, `91c43dc7…` cc.js) and run with `node`. Mutants were applied one at a time to the scratch copy's lib, followed by `TMPDIR=$(mktemp -d /tmp/u2a3b-factcheck-tmp-XXXX) bats test/scripts/build-loop-check.bats`, and the original lib was restored after each one (`git diff --quiet` confirmed it was clean).

**Hallucination-pattern log:** read. Claim 31 (a line count in the commit message is wrong) looks like the logged pattern "All 85 tests across the code-review suites pass" … but the suites hold 97: a count in a commit message that the tree does not reproduce. Nothing qualifies as a fabrication. The dispatch forbids writing any other file, so the log is not updated.

---

## Claim 1a: "It returns 1, with IMPORTED set to "error", when a command it runs fails" (the parser, lower, and the start-file read)

**Location:** `scripts/lib/dev-cycle-read.sh:450-451`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the parser failing (`import_targets` returns 1), lower failing on a start-file name or on an imported path, and the `< "$f"` redirect failing on an unreadable start file. It also covers the cached call after a failure, which answers 1 again. It does not cover the start-file listing commands (git ls-files, untracked_md; see 1b) or inrepo_here failures, which by design read as "not a plain file".

The guards are:

```bash
# scripts/lib/dev-cycle-read.sh:528-530
  IMPORTED_DONE="$ROOT_REAL"; IMPORTED=error
  while IFS= read -r -d '' f; do
    lp="$(lower "${f##*/}")" || return 1
```
```bash
# scripts/lib/dev-cycle-read.sh:539-542
    out="$(import_targets "$d" < "$f")" || { IMPORTED=error; return 1; }
    while IFS= read -r p; do
      [[ -n "$p" ]] || continue
      lp="$(lower "$p")" || { IMPORTED=error; return 1; }; IMPORTED+="$lp"$'\n'
```
(excerpt ends :542; enclosing imported_names() continues to :546 — read)

At :530, IMPORTED still holds `error` (set at :528), so a bare `return 1` there satisfies the claim. Executed: with AGENTS.md set to mode 000, the walk printed `line 539: AGENTS.md: Permission denied`, then `walk rc=1` and `IMPORTED=error`, and `isimported tree docs/a.md` answered imported. The cached path is `[[ "$IMPORTED_DONE" == "$ROOT_REAL" ]] && { [[ "$IMPORTED" != error ]]; return; }` (`:527`). After a failed first call, a second call with the file readable again also returned 1 (`2nd rc=1 (cached error)`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:524-546`; `/tmp/u2a3b-factcheck-FQ0K/_logs/probe-listing-failure.txt` (command `LC_ALL=C bash ../p4.sh <lib>`, cwd `/tmp/u2a3b-factcheck-FQ0K/_probe/r2`, exit 0, 2026-10-06T23:34:14Z); `/tmp/u2a3b-factcheck-FQ0K/_logs/probe-cached-error.txt` (`bash ../p6.sh <lib>`, same cwd, exit 0)
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 1b: "It returns 1, with IMPORTED set to "error", when a command it runs fails" (the start-file listing)

**Location:** `scripts/lib/dev-cycle-read.sh:450-451` (the listing is at `:534`)
**Type:** Error-handling
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `git ls-files -z` and `untracked_md` failing inside the process substitution that feeds the start-file loop. It does not establish how often those commands fail in practice.

```bash
# scripts/lib/dev-cycle-read.sh:529-535
  while IFS= read -r -d '' f; do
    lp="$(lower "${f##*/}")" || return 1
    if [[ ! "$lp" =~ $INSTRUCTION_FILE ]] || ! inrepo_here "$f"; then continue; fi
    [[ "$seen" == *$'\n'"$f"$'\n'* ]] && continue
    seen+="$f"$'\n'; queue+=("$f")
  done < <({ git ls-files -z; untracked_md; } | instruction_names)
  IMPORTED=$'\n'
```
(excerpt ends :535; enclosing imported_names() continues to :546 — read)

The status of the `< <(...)` process substitution is never observed. On top of that, `instruction_names` ends in `|| true` (`:520`: `instruction_names() { env LC_ALL=C grep -zaiE '…' || true; }`). If either listing command fails, the loop simply sees fewer names. :535 then sets IMPORTED to `$'\n'` and the walk returns 0. The `local -` / `set -o pipefail` added at :525 does not change this, because the only pipeline it could affect runs inside the unobserved substitution. In a direct check, `set -o pipefail; while read -r x; do :; done < <(false | true); echo $?` prints `0`. Its only other effect is on lower's `printf | tr`, where tr is already the last command.

Executed with a git shim whose `ls-files` exits 128:
- all ls-files calls failing gives `walk rc=0`, `IMPORTED=$'\n'` and `docs/a.md: -`, although tracked AGENTS.md imports docs/a.md;
- only the untracked listing failing gives `walk rc=0`, and the import `docs/p.md` from an untracked CLAUDE.local.md is lost (`docs/p.md: -`).

Defect class: **behavioral (fail-open)**. `--check-fix` reaches this walk through `elif isimported tree "$lp"` (`scripts/dev-cycle.sh:181`), so an imported doc would get `ok`. The listing line itself predates this commit, but the claim is new here and promises fail-closed behavior on every failing command. Confidence High.

**Evidence:** `scripts/lib/dev-cycle-read.sh:520-546`, `scripts/dev-cycle.sh:181`; `/tmp/u2a3b-factcheck-FQ0K/_logs/probe-listing-failure.txt` (command `FAILMODE={all,others} PATH=<shim>:$PATH LC_ALL=C bash ../p4.sh <lib>`, cwd `/tmp/u2a3b-factcheck-FQ0K/_probe/r2`, exit 0, 2026-10-06T23:34:14Z)
**Legibility-target:** for-author

---

## Claim 2: "(each call sits in an `if` or `||`, where set -e is off)"

**Location:** `scripts/lib/dev-cycle-read.sh:451`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the production call chain (`isimported` → `imported_names || return 0`, and `isimported tree` → `elif` in dev-cycle.sh). It does not cover test-only direct calls, which are bare (`test/scripts/dev-cycle.bats:1158`, `:1165`: `imported_names; echo walked`).

`tree) imported_names || return 0; …` (`scripts/lib/dev-cycle-read.sh:633`) and `elif isimported tree "$lp"; then` (`scripts/dev-cycle.sh:181`). An `rg` over the tree finds no other production caller (paraphrased — no quote available because the claim covers the absence of further callers in the grep output).

**Evidence:** `scripts/lib/dev-cycle-read.sh:627-636`, `scripts/dev-cycle.sh:181`, `test/scripts/dev-cycle.bats:1158-1166`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 3: "One result is cached, for the root in IMPORTED_DONE; a call for another ROOT_REAL recomputes it."

**Location:** `scripts/lib/dev-cycle-read.sh:451-453`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the cache key and the new rule that the cached error answers 1. It does not establish that a transient failure is ever retried for the same root (it is not: the error stays cached).

`[[ "$IMPORTED_DONE" == "$ROOT_REAL" ]] && { [[ "$IMPORTED" != error ]]; return; }` followed by `IMPORTED_DONE="$ROOT_REAL"; IMPORTED=error` (`:527-528`). Executed: the second call on the same root returned 1 from the cache. Mutant M16, which makes the cached path `return 0`, leaves all 16 tests passing, so no test pins the cached-error answer.

**Evidence:** `scripts/lib/dev-cycle-read.sh:527-528`; `/tmp/u2a3b-factcheck-FQ0K/_logs/probe-cached-error.txt`; `/tmp/u2a3b-factcheck-FQ0K/_logs/mut-M16-cached-error-return.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 4: "UTF-8 spaces that end an import token as a blank does (import_targets makes each one a blank before it matches tokens)"

**Location:** `scripts/lib/dev-cycle-read.sh:473-474`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers all 19 UNI_SPACES entries as sed substitutions that run before the grep. It does not cover other Unicode whitespace that JavaScript's `\s` also matches (U+0085 is read as part of a token on both sides, per the U2a2 review).

`for u in "${UNI_SPACES[@]}"; do s+=(-e "s/$u/ /g"); done` (`:498`), then `toks="$(env LC_ALL=C sed "${s[@]}")"` (`:500`) before the grep at `:501`. Executed: `@a.md<NBSP>@b.md` yields `a.md` and `b.md`, and `@a.md<U+3000>@b.md <U+FEFF>@c.md` yields all three. Mutant M1 (dropping :498) fails three tests.

**Evidence:** `scripts/lib/dev-cycle-read.sh:496-501`; `/tmp/u2a3b-factcheck-FQ0K/_logs/probe-import-targets.txt`, `probe-nul.txt`, `mut-M1-space-to-blank.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 5: "it ends at a blank, a UNI_SPACES space included, at a backslash or at #, as the import token of Claude Code does"

**Location:** `scripts/lib/dev-cycle-read.sh:485-487`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers where the parser's token ends and how Claude Code 2.1.292's regex and post-processing treat `#` and `\`. It does not cover Markdown token boundaries (Claims 7a/7b).

The parser's side is right: `IMPORT_RE='(^|[^[:alnum:]])@[^[:space:]\\#]+'` (`:480`). Executed, `@a.md#frag` → `a.md` and `@a\ b.md` → `a`.

The comparison is imprecise. Claude Code's regex, read from the binary, does **not** end the token at `#`. It cuts the captured name at `#` afterwards:

```
(?:^|\s)@((?:[^\s\\]|\\ )+)/g,w;while((w=S.exec(h))!==null){let H=w[1];if(!H)continue;let G=H.indexOf("#");if(G!==-1)H=H.substring(0,G);
```
(claude.exe 2.1.292, quoted from `grep -a` output; excerpt ends inside reo's scan function — the remainder, the path filter, is quoted in Claim 23b)

For the token itself the name read is the same. The difference is that the parser can start a new token after the `#`. For `@x.md#@y.md` the parser yields `x.md` and `y.md`, while Claude Code yields only `x.md`. That is an over-read, which refuses more, so it is safe. For backslashes, Claude Code continues through `\ ` (an escaped space) and the parser does not. That is the settled override-log row 350 / known issue A5 and is not re-filed. The precise wording would be: "it ends at a blank (UNI_SPACES included), a backslash or #. Claude Code also cuts its name at # and at a backslash not followed by a space."

**Evidence:** `scripts/lib/dev-cycle-read.sh:480`, `:501`; claude.exe 2.1.292; `/tmp/u2a3b-factcheck-FQ0K/_logs/probe-import-targets.txt`, `probe-old-vs-new.txt`, `cc-differential.txt` (command `node _cc/cc.js inN.md ""`, cwd `/tmp/u2a3b-factcheck-FQ0K/_ccin`, exit 0)
**Legibility-target:** for-author

---

## Claim 6: "That regex keeps brackets, parentheses, backticks and trailing punctuation in a name (@x.md. reads x.md.)"

**Location:** `scripts/lib/dev-cycle-read.sh:487-488`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers Claude Code's regex character class. It does not cover the Markdown lexer, which splits the text before the regex runs (Claim 7b).

The class is `[^\s\\]`, which excludes neither brackets, parentheses, backticks nor punctuation (binary quote in Claim 5). Executed through the harness: `@docs/e(f).md` → `docs/e(f).md`, `@docs/a.md(see)` → `docs/a.md(see)`, and `@docs/b.md,` → `docs/b.md,`.

**Evidence:** claude.exe 2.1.292; `/tmp/u2a3b-factcheck-FQ0K/_logs/cc-differential.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 7a: "each token yields its whole, its part before the first of [ ] ( ) < ! * _, and each of those with trailing . , ; : ! ? * _ ~ ) ] or backticks stripped"

**Location:** `scripts/lib/dev-cycle-read.sh:490-492`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the code yields for each token. It does not establish that this set covers every point where Claude Code's Markdown lexer ends a text token (7b).

```bash
# scripts/lib/dev-cycle-read.sh:505-507
    for c in "$t" "${t%%[][()<!*_]*}"; do
      v="$c"; while [[ "$v" == *[.,\;:!?*_~\)\]] || "$v" == *$'\x60' ]]; do v="${v%?}"; done  # \x60: a backtick
      for w in "$c" "$v"; do
```
(excerpt ends :507; enclosing import_targets() continues to :515 — read)

Executed: `@s.md.,;:!?*_~)]` yields `s.md.,;:!?*_~)]`, `s.md` and `s.md.,;:`. `[@x.md](y.md)` yields `x.md](y.md)`, `x.md](y.md` and `x.md`. `` `@t.md` `` yields `` t.md` `` and `t.md`. Mutant M2 (no cut) fails the new test. Mutants M13 (no `)`/`]` in the strip set) and M14 (no backtick strip) survive: no test pins those two strip characters.

**Evidence:** `scripts/lib/dev-cycle-read.sh:496-515`; `/tmp/u2a3b-factcheck-FQ0K/_logs/probe-import-targets.txt`, `mut-M2-cut-set.txt`, `mut-M13-strip-close-brackets.txt`, `mut-M14-strip-backtick.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 7b: "the Markdown around a token (emphasis, a link or image, inline HTML, a code span) may end it sooner, so each token yields … its part before the first of [ ] ( ) < ! * _"

**Location:** `scripts/lib/dev-cycle-read.sh:488-491`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the "code span" case the comment names. Emphasis, link, image and inline HTML are covered by the cut set and were executed correct (`**@docs/d.md**x`, `[@docs/l.md](u)` and `| @docs/c.md<br> |` all yield the short name). It does not establish other marked inline rules beyond those executed.

The comment names a code span as Markdown that ends the token sooner, but the cut set `[][()<!*_]` (`:505`) has no backtick. A backtick is only stripped when it is trailing (`:506`). The U2a2 security review records that marked's inline-text rule "stops before ``[\\<!\[`*_]``" (`docs/reviews/security-reviewer-review-2026-10-06-final-build-loop-u2a2.md`, F1). So a code span that opens directly after the name splits Claude Code's text token.

Executed for `` @docs/a.md`x` ``:
- Claude Code (harness): `docs/a.md`;
- import_targets at 1ccc8b65: `` docs/a.md`x` `` and `` docs/a.md`x `` only;
- import_targets at 45ad17b0, whose grep stopped at a backtick: `docs/a.md`.

End to end in a fixture repo whose AGENTS.md reads ``Read @docs/a.md`x` first.``, `bash scripts/dev-cycle.sh --check-fix docs/a.md` prints `skip docs/a.md: an instruction file imports it …` at 45ad17b0 and `ok docs/a.md` at 1ccc8b65. A lone backtick with no closing one (`` see @docs/a.md`s and ``) is merged back into one text token by marked, and both sides read `` docs/a.md`s ``, so only the closed code span diverges.

Defect class: **behavioral (fail-open regression against 45ad17b0)**: a file Claude Code imports gets `ok` from --check-fix. Confidence High: both sides were executed, and the end-to-end check ran.

**Evidence:** `scripts/lib/dev-cycle-read.sh:505-506`; `/tmp/u2a3b-factcheck-FQ0K/_logs/probe-old-vs-new.txt` (command `LC_ALL=C bash ../p5.sh <lib>` for both libs, cwd `/tmp/u2a3b-factcheck-FQ0K/_probe/r`, exit 0); `/tmp/u2a3b-factcheck-FQ0K/_logs/e2e-backtick.txt` (command `timeout 60 bash <ver>/scripts/dev-cycle.sh --check-fix docs/a.md`, cwd `/tmp/u2a3b-factcheck-FQ0K/_e2e`, exit 0 both, 2026-10-06T23:31Z); `/tmp/u2a3b-factcheck-FQ0K/_logs/cc-differential.txt`
**Legibility-target:** for-author

---

## Claim 8: "each path once"

**Location:** `scripts/lib/dev-cycle-read.sh:492`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers one token, since the dedup set `n` is reset for each token at :504. It does not cover a file: `@a.md @a.md` prints `a.md` twice, and the walks' own `seen` handles that.

`t="${t#*@}"; n=$'\n'` (`:504`) and `[[ … && "$n" != *$'\n'"$p"$'\n'* ]] || continue` / `n+="$p"$'\n'` (`:510-511`). Executed: `dup` prints `a.md` twice, and the stripped duplicate of a cut part (`q.md` from `@q.md.(x)`) is printed once. Mutant M15 (no dedup) survives.

**Evidence:** `scripts/lib/dev-cycle-read.sh:502-514`; `/tmp/u2a3b-factcheck-FQ0K/_logs/probe-import-targets.txt`, `mut-M15-dedup.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 9: "A NUL counts as a blank."

**Location:** `scripts/lib/dev-cycle-read.sh:492`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers GNU sed 4.9 under LC_ALL=C and the absence of bash's "ignored null byte" warning. It does not establish non-GNU seds, nor any claim that Claude Code treats NUL as a blank (the harness shows it does not: it reads `docs/h.md\0@docs/i.md` as one name, so the parser over-reads here).

`s=(-e 's/\x0/ /g')` (`:497`). Executed: `printf 'a\0b\n' | LC_ALL=C sed -e 's/\x0/ /g' | od -c` shows `a   b \n`. `printf '@h.md\0@i.md' | import_targets ""` yields `h.md` and `i.md` with nothing on stderr, and the bats test requires `[ -z "$stderr" ]` and passes. Mutant M5 fails two tests.

**Evidence:** `scripts/lib/dev-cycle-read.sh:497`; `/tmp/u2a3b-factcheck-FQ0K/_logs/probe-nul.txt`, `mut-M5-nul-transform.txt`, `cc-differential.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 10: "Over-reading only over-refuses."

**Location:** `scripts/lib/dev-cycle-read.sh:492-493`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the direction of an extra yielded path: membership in IMPORTED and isimported answering imported, which makes check_fix skip. It does not establish that the parser never under-reads (it does: Claim 7b).

`IMPORTED+="$lp"$'\n'` (`:542`), `[[ "$IMPORTED" == *$'\n'"$lp"$'\n'* ]]` (`:633`), and `elif isimported tree "$lp"; then echo "skip $a: …"` (`scripts/dev-cycle.sh:181-182`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:542`, `:633`; `scripts/dev-cycle.sh:181-182`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 11: "~/ and absolute paths, and paths leaving the repo (.. or ../, not a ..x name), are dropped."

**Location:** `scripts/lib/dev-cycle-read.sh:493-494`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the parser's drop rules. It does not establish that this matches Claude Code for `~x` (Claim 23b).

`[[ -n "$w" && "$w" != \~/* && "$w" != /* ]] || continue` and `[[ "$p" != .. && "$p" != ../* && … ]] || continue` (`:508`, `:510`). Executed: `@~g.md @~/h.md @/abs.md @../up.md @..x.md @a/../../z.md` yields `~g.md` and `..x.md` only.

**Evidence:** `scripts/lib/dev-cycle-read.sh:508-510`; `/tmp/u2a3b-factcheck-FQ0K/_logs/probe-import-targets.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 12: "It reads ROOT_REAL without checking it (the caller has run need_root)"

**Location:** `scripts/lib/dev-cycle-read.sh:494-495`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers both production callers. It does not cover tests that call import_targets directly (`test/scripts/build-loop-check.bats:287`, which sets ROOT_REAL itself).

The callers are imported_names (`need_root` at `:526`, call at `:539`) and main_imports (`need_root` at `:562`, calls at `:594` and `:600`). import_targets itself only uses `"$ROOT_REAL"` at `:509`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:509`, `:526`, `:539`, `:562`, `:594`, `:600`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 13: "and returns 1 when sed or grep fails"

**Location:** `scripts/lib/dev-cycle-read.sh:495`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers sed exiting non-zero, grep status 2 (failure) and grep status 1 (no match, which counts as success). It does not cover realpath failures, which skip the candidate by design (`:509 || continue`).

`toks="$(env LC_ALL=C sed "${s[@]}")" || return 1` and `toks="$(env LC_ALL=C grep -aoE "$IMPORT_RE" <<<"$toks")" || [[ $? -eq 1 ]] || return 1` (`:500-501`). Executed with PATH shims: grep exiting 1 gives `rc=0`, grep exiting 2 gives `rc=1`, and sed exiting 4 gives `rc=1`. With the real tools, input with no imports gives `rc=0` and a directory as stdin gives `sed: read error on stdin: Is a directory` and `rc=1`. Mutant M4 (sed guard) fails the new test. Mutant M11 (grep guard → `|| true`) survives: no test drives grep to status 2.

**Evidence:** `scripts/lib/dev-cycle-read.sh:500-501`; `/tmp/u2a3b-factcheck-FQ0K/_logs/probe-grep-sed-status.txt` (command `LC_ALL=C bash ../p3.sh <lib> <shimdir>`, cwd `/tmp/u2a3b-factcheck-FQ0K/_probe/r`, exit 0), `probe-nul.txt`, `mut-M4-sed-guard.txt`, `mut-M11-grep-status-guard.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 14: "Two steps, not a pipe: under pipefail grep's "no match" would hide a sed failure."

**Location:** `scripts/lib/dev-cycle-read.sh:499`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bash's pipefail status rule, under which the rightmost non-zero status wins. It does not cover anything outside this function.

`bash -c 'set -o pipefail; (exit 4) | (exit 1); echo "status=$?"'` prints `status=1`, which `|| [[ $? -eq 1 ]]` would have accepted as "no match".

**Evidence:** `scripts/lib/dev-cycle-read.sh:499-501`; command run in `/tmp/u2a3b-factcheck-FQ0K/_ccin`, exit 0, 2026-10-06T23:34:02Z, output captured inline in the session (single-line `status=1`; the command is reproducible as quoted)
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 15: "A failed walk, or a walk name that is neither, answers imported (0)"

**Location:** `scripts/lib/dev-cycle-read.sh:623-624`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers walks that return 1 and the new failed-lower guard on the argument. It does not establish that every failure becomes a failed walk: a failed tree listing returns 0 and answers "not imported" (Claim 1b).

```bash
# scripts/lib/dev-cycle-read.sh:630-634
  lp="$(lower "$2")" || return 0
  case "$1" in
    main) main_imports || return 0; [[ "$IMPORTED_MAIN" == *$'\n'"$lp"$'\n'* ]] ;;
    tree) imported_names || return 0; [[ "$IMPORTED" == *$'\n'"$lp"$'\n'* ]] ;;
    *) return 0 ;;
```
(excerpt ends :634; enclosing isimported() continues to :636 — read)

Executed: after an unreadable start file, `isimported tree docs/a.md` gives `imported`. The bogus walk name is pinned by the existing test at `test/scripts/build-loop-check.bats:40`. Mutants M7 (tree guard) and M12 (own-lower guard) each survive alone, while M7+M12 together fail the tr test (Claim 19).

**Evidence:** `scripts/lib/dev-cycle-read.sh:627-636`; `/tmp/u2a3b-factcheck-FQ0K/_logs/probe-listing-failure.txt`, `mut-M7-isimported-tree-guard.txt`, `mut-M12-isimported-lower-guard.txt`, `mut-M7+M12.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 16: `main_imports`' new guard `i="$(lower "$p")" || { IMPORTED_MAIN=error; return 1; }` (implicit: `i` is safe to assign here)

**Location:** `scripts/lib/dev-cycle-read.sh:615`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `i` being local, so it neither leaks nor clobbers a global, and the guard setting IMPORTED_MAIN=error. It does not establish that any test reaches this guard (none does).

`local - rec f d p src i out queue=() …` (`:560`). `i` is also the candidate index at `:583` and the NUL count at `:604`. Those uses are done before the loop at :613, so reusing it is harmless. Mutant M8 (guard → `|| true`) survives the whole build-loop-check suite. In the tr test the main walk fails earlier, at the candidate-count check `[[ ${#low[@]} -eq ${#cand[@]} ]] || return 1` (`:582`), because tr also lower-cases the candidates (`:581`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:559-621`; `/tmp/u2a3b-factcheck-FQ0K/_logs/mut-M8-main-loop-lower-guard.txt`, `mut-M12+M582.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 17a: test name "both walks read what Claude Code reads: an @ after a Unicode space, Markdown around a token, ( ) in a name"

**Location:** `test/scripts/build-loop-check.bats:268`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers docs/a.md through docs/e(f).md, which Claude Code (harness) reads from the test's own AGENTS.md line and which the test asserts for both walks. It does not cover docs/h.md and docs/i.md: Claude Code reads `docs/h.md\0@docs/i.md` as one name, so the walks over-read there.

On the test's exact line the harness prints `docs/a.md`, `docs/b.md,`, `docs/c.md`, `docs/d.md` and `docs/e(f).md,`, plus the NUL-joined name. The bats test passes at HEAD (114/114).

**Evidence:** `test/scripts/build-loop-check.bats:268-277`; `/tmp/u2a3b-factcheck-FQ0K/_logs/baseline.txt`; harness run on `_ccin/testline.md` (session output, 2026-10-06T23:34Z)
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 17b: test name "both walks read what Claude Code reads: … ~x"

**Location:** `test/scripts/build-loop-check.bats:268`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers whether Claude Code 2.1.292 loads `@~g.md`. It does not establish any older or newer Claude Code version.

Claude Code's filter, read from the binary, only accepts names that start with `./`, `~/` or `/`, or that match `^[a-zA-Z0-9._-]` (quoted in Claim 23b). `~g.md` matches none of these, so Claude Code does not read it, and the harness's output for the test line has no `~g.md`. The walks read it, which the test asserts with `want '~g.md' imported`. Defect class: **test name / comment only**. The behavior over-reads, which refuses more, so it is safe.

**Evidence:** `test/scripts/build-loop-check.bats:270-276`; claude.exe 2.1.292; `/tmp/u2a3b-factcheck-FQ0K/_logs/cc-differential.txt` (`@~g.md and @~/h.md` → CC `~/h.md` only)
**Legibility-target:** for-author

---

## Claim 18: test body "PATH=… imps "$w" docs/z.md; … want docs/z.md imported" exercises the walks' lower guards

**Location:** `test/scripts/build-loop-check.bats:282-285`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which guard makes the imps loop pass. It does not judge test adequacy beyond the claim that the name makes.

For both `tree` and `main`, `isimported` runs `lp="$(lower "$2")" || return 0` (`:630`) before either walk runs. With tr failing, the loop's assertion is met by that guard alone. Deleting walk-side guards one at a time gives:

| Mutant | Result |
|---|---|
| M3, start-file lower `:530` | fails, through the direct `imported_names` call at `:288` |
| M7, `:633` | survives |
| M8, `:615` | survives |
| M9, `:542` | survives |
| M10, `:539` | survives |
| M12, `:630` | survives, because the walks' own failure then answers imported |

M7+M12 together fail, and so do M12 plus removing `:582`. In the main loop, `imps` prints `walk: failed` (from `:582`), but the test never asserts it. Of the walk-side guards, only `:530` is tested.

**Evidence:** `test/scripts/build-loop-check.bats:280-291`; `/tmp/u2a3b-factcheck-FQ0K/_logs/mut-M3-*.txt`, `mut-M7-*.txt`, `mut-M8-*.txt`, `mut-M9-*.txt`, `mut-M10-*.txt`, `mut-M12-*.txt`, `mut-M7+M12.txt`, `mut-M12+M582.txt`
**Legibility-target:** for-author

---

## Claim 19: test name "both walks fail closed when tr fails, and the parser returns 1 when it cannot read its input"

**Location:** `test/scripts/build-loop-check.bats:280`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the asserted behavior. Answers are fail-closed, imported_names returns 1, and import_targets returns 1 on `< docs`. It does not establish that each walk's own new guard is what produces that behavior (Claim 18).

The behavior the name states holds: the test passes, and the parser half is pinned by M4. As Claim 18 shows, though, the "both walks" half passes through isimported's own guard. Neither walk's failure is asserted in the loop. The precise version: "isimported answers imported when tr fails; the tree walk returns 1 on a failed start-file lower; the parser returns 1 when it cannot read its input."

**Evidence:** `test/scripts/build-loop-check.bats:280-291`; `/tmp/u2a3b-factcheck-FQ0K/_logs/baseline.txt`, `mut-*.txt`
**Legibility-target:** for-author

---

## Claim 20: commit "Carries U2a2's final-pass findings on the shared parser (fact-check E1 and E2, security final F1 and F2, architecture final F1-F3, api final 1), each a gap main already had"

**Location:** commit 1ccc8b65 message, para 2
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the citation list against the override-log rows for E1, E2 and D3. It does not cover re-reading each cited finding in full.

The override-log row for E1 cites "final fact-check Claim 1, E1; security final; architecture final F1; **api final 2**; test-strategy final G9". The D3 row cites "architecture final F2, F3; security final F2; api final 1". The api final review's finding 2 is "The shared parser's comments still describe two token rules the code does not follow" (`docs/reviews/api-consistency-reviewer-review-2026-10-06-final-build-loop-u2a2.md:55`), and this commit rewrites those comments. The list omits api final 2. "A gap main already had" matches the rows' "Not a regression (main prints the same)".

**Evidence:** `docs/reviews/override-log.md` (the three feat/build-loop-u2a2 Defer rows naming U2a3b), `docs/reviews/api-consistency-reviewer-review-2026-10-06-final-build-loop-u2a2.md:34`, `:55`
**Legibility-target:** for-author

---

## Claim 21: commit "import_targets now turns every UNI_SPACES character, and a NUL, into a blank before it matches (`@a.md<NBSP>@b.md` reads both)"

**Location:** commit 1ccc8b65 message, bullet 1
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claims 4 and 9. It does not establish Claude Code's NUL handling.

Executed: `@a.md<NBSP>@b.md` gives `a.md` and `b.md`, which matches the harness's `docs/a.md docs/b.md` for the docs/ variant.

**Evidence:** `scripts/lib/dev-cycle-read.sh:497-501`; `/tmp/u2a3b-factcheck-FQ0K/_logs/probe-import-targets.txt`, `cc-differential.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 22: commit "Claude Code's import regex ends a token only at a blank, a backslash or #; ( ) [ ] and backticks stay in a name, while the Markdown around a token (… a code span) can end it sooner. Each token now yields its whole, its part before the first of [ ] ( ) < ! * _, and each of those stripped …: `docs/e(f).md` and `| @docs/c.md<br> |` are read."

**Location:** commit 1ccc8b65 message, bullet 2
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the regex description and the two named examples. The code-span gap is verdicted once, at Claim 7b, and not double-counted here.

Both examples are read: `docs/e(f).md` and `docs/c.md`. As in Claim 5, the regex does not end at `#`. Claude Code cuts the name at `#` after the match, and it continues through `\ `.

**Evidence:** claude.exe 2.1.292; `/tmp/u2a3b-factcheck-FQ0K/_logs/probe-import-targets.txt`, `cc-differential.txt`
**Legibility-target:** for-author

---

## Claim 23a: commit "Only ~/ is dropped"

**Location:** commit 1ccc8b65 message, bullet 3
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the tilde rule at :508, meaning that among `~` forms only `~/` is dropped (absolute and leaving-the-repo paths are dropped too, per Claim 11). It does not establish Claude Code parity.

`"$w" != \~/*` (`:508`). Executed: `~g.md` is kept and `~/h.md` is dropped.

**Evidence:** `scripts/lib/dev-cycle-read.sh:508`; `/tmp/u2a3b-factcheck-FQ0K/_logs/probe-import-targets.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 23b: commit "`@~g.md` names a file (it was dropped as home)"

**Location:** commit 1ccc8b65 message, bullet 3
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers Claude Code 2.1.292. It does not establish other versions.

From the binary:

```
if(!EP(H)&&(H.startsWith("./")||H.startsWith("~/")||H.startsWith("/")&&H!=="/"||!H.startsWith("@")&&!H.match(/^[#%^&*()]+/)&&H.match(/^[a-zA-Z0-9._-]/))){let Y=Ye(H,FT(n));r.add(Y)}
```
(claude.exe 2.1.292, quoted from `grep -a` output; excerpt is the path filter inside reo's scan loop, which continues into `function g(h)`, the token walker — read)

`~g.md` fails every branch, so Claude Code does not import it. Defect class: **commit message only**. The new behavior over-reads, which is safe. The parser's previous drop of `~g.md` already matched Claude Code.

**Evidence:** claude.exe 2.1.292; `/tmp/u2a3b-factcheck-FQ0K/_logs/cc-differential.txt`
**Legibility-target:** for-author

---

## Claim 24: commit "The parser returns 1 when sed or grep fails (two steps, not a pipe: under pipefail grep's "no match" hid a sed failure)"

**Location:** commit 1ccc8b65 message, bullet 4
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claims 13 and 14.

See Claims 13 and 14 (paraphrased — no quote available because the evidence is the same executed shims and pipefail check, cited there).

**Evidence:** `scripts/lib/dev-cycle-read.sh:499-501`; `/tmp/u2a3b-factcheck-FQ0K/_logs/probe-grep-sed-status.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 25: commit "imported_names returns 1 with IMPORTED=error when the parser or lower fails (it runs inside `elif isimported tree`, where set -e is off)"

**Location:** commit 1ccc8b65 message, bullet 4
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the parser and lower failing, as stated. It does not cover the listing failures that the lib comment's broader wording promises (Claim 1b): the commit message names only "the parser or lower".

See Claims 1a and 2.

**Evidence:** `scripts/lib/dev-cycle-read.sh:528-542`, `scripts/dev-cycle.sh:181`; `/tmp/u2a3b-factcheck-FQ0K/_logs/probe-listing-failure.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 26: commit "isimported answers imported for a failed tree walk or a failed lower of its own argument; main_imports guards its lower too"

**Location:** commit 1ccc8b65 message, bullet 4
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the code at `:615`, `:630` and `:633`, with `i` local. It does not establish test coverage of the `:615` and `:633` guards, which are untested (M7 and M8 survive).

See Claims 15 and 16.

**Evidence:** `scripts/lib/dev-cycle-read.sh:560`, `:615`, `:630-633`; `/tmp/u2a3b-factcheck-FQ0K/_logs/mut-M7-*.txt`, `mut-M8-*.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 27: commit "The strip set's backtick is written $'\x60' (a literal one made the hermeticity lint read the rest of the file as a command substitution)"

**Location:** commit 1ccc8b65 message, bullet 5
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers a literal backtick inside the bracket class (`*[.,\;:!?*_~\)\]\`]`). That form makes `scripts/hermeticity-lint` report `can spawn \`claude\` (via scripts/lib/dev-cycle-read.sh)`. It does not cover every literal form: a single-quoted `'`'` passes the lint.

Executed: the bracket-class mutant gives `not ok 1 no test file can spawn a network-capable binary …`, while the `*'`'` mutant gives `ok 1`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:506`; `/tmp/u2a3b-factcheck-FQ0K/_logs/mut-literal-backtick-class.txt`, `mut-literal-backtick.txt` (command `TMPDIR=… bats test/fixture-hermeticity.bats`, cwd `/tmp/u2a3b-factcheck-FQ0K`)
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 28: commit "Tests: two new in build-loop-check.bats …; 114 across the five suites."

**Location:** commit 1ccc8b65 message, Tests paragraph
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count and that all pass at 1ccc8b65. It does not establish other suites.

`git diff 45ad17b0..1ccc8b65` adds two `@test` blocks (`:268`, `:280`). The five suites print `ok 1` through `ok 114`, with no `not ok` and exit 0.

**Evidence:** `test/scripts/build-loop-check.bats:268`, `:280`; `/tmp/u2a3b-factcheck-FQ0K/_logs/baseline.txt` (command `TMPDIR=… bats test/scripts/build-loop-check.bats test/scripts/build-loop-read.bats test/scripts/dev-cycle.bats test/scripts/fixture-git-env.bats test/fixture-hermeticity.bats`, cwd `/tmp/u2a3b-factcheck-FQ0K`, exit 0, 2026-10-06T23:27:13Z)
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 29a: commit "Mutants of the space-to-blank transform, the cut set, the tree walk's start-file lower guard, the sed guard [and] the NUL transform … each fail."

**Location:** commit 1ccc8b65 message, Tests paragraph
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers one natural mutant each. It does not establish that every mutant of these sites fails.

| Mutant | Failing tests |
|---|---|
| M1 (drop :498) | 3 tests fail |
| M2 (no cut) | 1 |
| M3 (`:530 || true`) | 1 |
| M4 (`:500 || true`) | 1 |
| M5 (`s=()`) | 2 |

**Evidence:** `/tmp/u2a3b-factcheck-FQ0K/_logs/mut-M1-space-to-blank.txt`, `mut-M2-cut-set.txt`, `mut-M3-tree-startfile-lower-guard.txt`, `mut-M4-sed-guard.txt`, `mut-M5-nul-transform.txt` (command `_probe/runmut.sh NAME OLD NEW`, cwd `/tmp/u2a3b-factcheck-FQ0K`, 2026-10-06T23:29Z)
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 29b: commit "Mutants of … the ~/ rule each fail."

**Location:** commit 1ccc8b65 message, Tests paragraph
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers two mutants of `:508`'s tilde test. It does not cover other mutants.

Reverting to the old rule (`\~*`) fails the new test (M6a), because `~g.md` is then dropped. Deleting the `~/` exclusion entirely (M6b) **survives**: no test asserts that `@~/x` is dropped. The precise version is "reverting the ~/ rule to the old ~ rule fails".

**Evidence:** `scripts/lib/dev-cycle-read.sh:508`; `/tmp/u2a3b-factcheck-FQ0K/_logs/mut-M6a-tilde-rule-old.txt`, `mut-M6b-tilde-rule-removed.txt`
**Legibility-target:** for-author

---

## Claim 30: commit "split from U2a3 for size (U2a3 + this was 442 lines); the walk in U2a3 is unchanged."

**Location:** commit 1ccc8b65 message, Notes
**Type:** Configuration / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the 442 count, with pr-prep 1a's command against merge-base 62d366a7, and the diff of main_imports. It does not cover U2a3's own review.

`git diff --numstat 62d366a7...1ccc8b65 -- ':(top)' ':(top,exclude)docs/' | awk …` prints `442`, so that part is Verified. "The walk in U2a3 is unchanged" is imprecise: this commit changes one line of main_imports, `:615` (the new lower guard). The precise version is "unchanged but for its lower guard".

**Evidence:** `scripts/lib/dev-cycle-read.sh:615`; `workflows/pr-prep.md:91`; command run in `/workspace/.claude/wt-build-loop-u2a3b`, exit 0, 2026-10-06T23:33Z (output `442`, captured in session)
**Legibility-target:** for-author

---

## Claim 31: commit "98 changed code lines against U2a3."

**Location:** commit 1ccc8b65 message, Tests paragraph
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers pr-prep 1a's count with BASE=45ad17b0 (U2a3's tip). It does not establish how 98 was derived.

`git diff --numstat 45ad17b0...1ccc8b65 -- ':(top)' ':(top,exclude)docs/' | awk '{ n += $1 + $2 } END { print n+0 }'` gives **102** (47+30 in the lib, 25+0 in the test). 98 equals 442 − 344, U2a3's own count, which is a subtraction and not 1a's method. Both figures are far under the 400 cap, so no decision changes.

**Evidence:** `workflows/pr-prep.md:91`; command run in `/workspace/.claude/wt-build-loop-u2a3b`, exit 0, 2026-10-06T23:33Z (outputs `102` and `344`, captured in session)
**Legibility-target:** for-author

---

## Claim 32: commit "Over-reading only adds candidate paths, so --check-fix refuses more; the one way it refuses less is a token the old grep split at ( ) [ ] that Claude Code reads whole."

**Location:** commit 1ccc8b65 message, Notes
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers old-versus-new parser output and Claude Code for the backtick case. It does not enumerate every other input class.

The old grep also split at a backtick: `IMPORT_RE='(^|[^[:alnum:]])@[^][:space:]\\#`()]+'` (45ad17b0). The new parser does not cut there (Claim 7b). For `` @docs/a.md`x` ``, the old parser yields `docs/a.md`, the new one does not, and Claude Code reads `docs/a.md`. That is not "a token Claude Code reads whole". End to end, `--check-fix docs/a.md` goes from `skip` to `ok`. So a second refuses-less case exists, and in that case Claude Code reads the short name, which makes it fail-open. Defect class: **behavioral** (the regression of Claim 7b); the sentence is commit-message only. Confidence High.

**Evidence:** `/tmp/u2a3b-factcheck-FQ0K/_logs/probe-old-vs-new.txt`, `e2e-backtick.txt`, `cc-differential.txt`; `/tmp/u2a3b-factcheck-FQ0K/_logs/lib.45ad17b0`
**Legibility-target:** for-author

---

## Claims Requiring Attention

### Incorrect
- **Claim 1b** (`scripts/lib/dev-cycle-read.sh:450-451`, listing at `:534`): a failing `git ls-files` or `untracked_md` returns 0 with a short IMPORTED, which is fail-open. Behavioral. The process substitution's status is never checked, and `local -`/`pipefail` does not reach it.
- **Claim 7b** (`scripts/lib/dev-cycle-read.sh:488-491`, `:505`): the comment names a code span among the things handled, but the cut set has no backtick. `` @docs/a.md`x` `` is now missed: --check-fix says ok where 45ad17b0 said skip, while Claude Code imports docs/a.md. Behavioral, fail-open regression.
- **Claim 17b** (`test/scripts/build-loop-check.bats:268`): "what Claude Code reads … ~x". Claude Code 2.1.292 does not load `@~g.md`. Test name only; safe over-read.
- **Claim 23b** (commit 1ccc8b65, bullet 3): "`@~g.md` names a file" is wrong for Claude Code 2.1.292. Commit message only; safe over-read.
- **Claim 32** (commit 1ccc8b65, Notes): "the one way it refuses less is ( ) [ ]". The backtick case also refuses less, and there Claude Code reads the short name. Commit message only; the defect behind it is Claim 7b.

### Stale
- none

### Mostly Accurate
- **Claim 5** (`scripts/lib/dev-cycle-read.sh:485-487`): Claude Code's regex does not end at `#`; it cuts the name at `#` afterwards, and it continues through `\ `.
- **Claim 18** (`test/scripts/build-loop-check.bats:282-285`): the imps loop passes through isimported's own lower guard. Walk guards :539, :542, :615 and :633 are untested.
- **Claim 19** (`test/scripts/build-loop-check.bats:280`): the behavior the test name states holds, but the "both walks" half is not what the loop asserts.
- **Claim 20** (commit, para 2): the citation list omits api final 2.
- **Claim 22** (commit, bullet 2): the same `#`/`\ ` imprecision as Claim 5.
- **Claim 29b** (commit, Tests): only the revert-to-`~*` mutant fails; deleting the `~/` exclusion survives.
- **Claim 30** (commit, Notes): main_imports changes at :615, so the walk is not wholly unchanged.
- **Claim 31** (commit, Tests): pr-prep 1a's count is 102, not 98.

### Unverifiable
- none

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved at the output path named in your role section below, structured per your skill, with a `Commit: 1ccc8b65` line at the top.
- Answered: yes. All nine dispatch focus items were checked, with execution and mutants for each.
- Out of scope: the hallucination-pattern log update (the dispatch allows only this file in the worktree). Execution logs live in /tmp/u2a3b-factcheck-FQ0K/_logs/ for the same reason.
- Escalate: Claim 7b/32, the backtick-adjacent code span. It is a fail-open regression against 45ad17b0 that the U2a3b loop should fix (add a backtick to the cut set, or an equivalent) together with a test. Claim 1b, the tree walk's listing failure, is fail-open. The line predates this commit, but the new comment promises otherwise.
- Decisions I made: I used the U2a2 security review's extracted marked harness (copied read-only) as Claude Code's side for the Markdown cases, and confirmed the regex and path filter directly from the 2.1.292 binary. I counted Claim 31 with BASE=45ad17b0, per pr-prep 1b's stacked-unit rule. I rated the 98-vs-102 count Mostly accurate rather than Incorrect because no decision depends on it.
