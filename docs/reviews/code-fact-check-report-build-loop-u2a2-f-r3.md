Commit: 7697c6e6

# Code Fact-Check Report

**Commit:** 7697c6e6
**Replication:** k=3 (replicate)
**Repository:** /workspace/.claude/wt-build-loop-u2a2 (branch feat/build-loop-u2a2)
**Scope:** net diff `git diff main...HEAD` (main 20347279, HEAD 7697c6e6): scripts/lib/dev-cycle-read.sh, scripts/dev-cycle.sh, test/scripts/build-loop-check.bats, test/scripts/fixture-git-env.bats, test/scripts/dev-cycle.bats, docs/working/plan-build-loop-handoff.md, docs/working/questions.md, docs/reviews/override-log.md (appended rows), rubric B-row statuses; commit messages 39ed1d53, bff4ded2, 7697c6e6
**Checked:** 2026-10-06
**Total claims checked:** 30
**Summary:** 27 verified, 1 mostly accurate, 0 stale, 1 incorrect, 1 unverifiable

Hallucination pattern log read (`docs/reviews/hallucination-patterns.md`, 5 entries, all "measured value quoted from an artifact set that does not contain it"). Every count in this scope (2, 100, 105, 166, 26, ~400) was recomputed; none matches a logged pattern.

Execution provenance (applies to every `executed` claim below): cwd `/workspace/.claude/wt-build-loop-u2a2` unless stated, scratch `/tmp/u2a2f-fc3-ALNK`, runs 2026-10-06T21:06Z-21:12Z, captured output under `/tmp/u2a2f-fc3-ALNK/logs/`. Suite run: `TMPDIR=$(mktemp -d /tmp/u2a2f-x-XXXX) bats test/scripts/build-loop-check.bats test/scripts/dev-cycle.bats test/scripts/fixture-git-env.bats test/scripts/build-loop-read.bats test/fixture-hermeticity.bats`, exit 0, 100 `ok`, 0 `not ok` (`logs/tests.txt`). Mutants ran in `git archive HEAD` copies (`/tmp/u2a2f-fc3-ALNK/m*`, `mut1`). No process was left running.

---

## Claim 1: Rubric B1, B5 (tree half), B7, B9, B10 (inrepo_here), B13 marked fixed / override for U2a2

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a2.md:17-29`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the six rows whose Unit is U2a2; does not establish the U2a3 rows (B2-B4, B6, B8, B11, B12, B14), which are out of this unit's scope.

B1: `$'\xef\xbb\xbf'` is the last UNI_SPACES element (`scripts/lib/dev-cycle-read.sh:455`), and the U+FEFF mutant fails test 1 with `want: docs/bom.md: imported` (`logs/mfeff.txt`). B5 tree half: test 1's docs/c.md imports `@c.md` (itself) and `@../CLAUDE.md`; `imps` runs `timeout 60` (`test/scripts/build-loop-check.bats:19`); the seen-check mutant fails on status (`logs/mseen.txt`). B7: override row `docs/reviews/override-log.md:355`. B9: the token rules and "Every import walk shares these rules, so a change here changes --check-fix too" sit on `import_targets` (`scripts/lib/dev-cycle-read.sh:458-467`). B10: `# inrepo for a caller that has run need_root itself (a walk, per path); it has / # no need_root of its own.` (`:122-123`). B13: `for t in "$t" "$v"; do` (`:474`); the kept-name mutant fails with `want: docs/st.md.: imported` (`logs/mkept.txt`).

**Evidence:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a2.md:17,21,23,25,26,29`; `scripts/lib/dev-cycle-read.sh:122-124,453-482`; `logs/mfeff.txt`, `logs/mkept.txt`, `logs/mseen.txt`

---

## Claim 2: The four override rows dated 2026-10-06 for `feat/build-loop-u2a2`

**Location:** `docs/reviews/override-log.md:353-356`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers rows 354 (line refs), 355 (queue pop and lower-before-seen) and 356 (Claude Code's regex and the whole-plus-stripped fix); row 353 is Accepted-immutable about d8003fbf (main_imports, not here) and was not re-verdicted; does not establish the ~3 ms per edge timing.

Row 354: header lines 18 and 21 are still the short ones at HEAD (lengths 69 and 70, the rest 70-81; awk over `:10-33`). Row 355: `f="${queue[0]}"; queue=("${queue[@]:1}")` (`scripts/lib/dev-cycle-read.sh:501`) and `IMPORTED+="$(lower "$p")"$'\n'` (`:504`) precedes the seen test on `:505`. Row 356: the installed `claude --version` is `2.1.292 (Claude Code)`, and its bundled import function holds `let S=/(?:^|\s)@((?:[^\s\\]|\\ )+)/g` (`logs/cc-import-fn.txt`); node with that regex returns `["docs/st.md."]` for `@docs/st.md.` (`logs/node-regex.txt`). The fix it records is `:474` (Claim 13).

**Evidence:** `docs/reviews/override-log.md:353-356`; `scripts/lib/dev-cycle-read.sh:18,21,501-505`; `logs/cc-import-fn.txt`; `logs/node-regex.txt`

---

## Claim 3: Plan F10 "Floor item 4 keeps the docs `check_fix` denies (...) and adds `docs/thoughts/`, which `check_fix` still fixes (a living doc)"

**Location:** `docs/working/plan-build-loop-handoff.md:125`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers check_fix's deny regex against the listed dirs and docs/thoughts/; does not establish the floor's own list (U2a4) beyond plan :72, and the row omits docs/constraints.md from the "keeps" list (an omission, not an error).

`elif [[ ! "$lp" =~ ^docs/.*\.md$|^readme\.md$ || "$lp" =~ ^docs/(working|human-author|reviews|decisions)/ \ || "$lp" == docs/dev-cycle.md || "$lp" == docs/constraints.md ...` (`scripts/dev-cycle.sh:176-177`): thoughts/ is not denied; decisions/, human-author/ and working/ (other briefs' working docs) are; cycle files go to the `writable` arm (`:175`). Plan :72 lists `docs/thoughts/` in floor item 4.

**Evidence:** `scripts/dev-cycle.sh:170-183`; `docs/working/plan-build-loop-handoff.md:72,125`

---

## Claim 4: Plan F11 and step 5's U2a2/U2a3/U2a4 bullets

**Location:** `docs/working/plan-build-loop-handoff.md:126,275-277`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the U2a2 bullet against HEAD (import_targets, U+FEFF, kept and stripped name, `..x` followed, NUL read, `isimported tree` called by check_fix, C12-C14) and F11's statement that the floor's walk is U2a3's, not this branch's; does not establish U2a3's or U2a4's planned contents (U2a3's refusal list describes main_imports as of 7f295cdb, absent at HEAD; `feat/build-loop-u2a3` currently points at 7697c6e6 with no main_imports).

U2a2 bullet matches `:453-482` and `elif isimported tree "$lp"; then` (`scripts/dev-cycle.sh:181`). "UTF-8 spaces including U+FEFF end a token" holds for the token they follow; see Claim 9b for the token after one. `git show feat/build-loop-u2a3:scripts/lib/dev-cycle-read.sh | grep main_imports` finds nothing (paraphrased — no quote available because the claim covers absence of code).

**Evidence:** `docs/working/plan-build-loop-handoff.md:126,275-277`; `scripts/lib/dev-cycle-read.sh:458-482,509-521`; `scripts/dev-cycle.sh:181`

---

## Claim 5: Plan :273 "U2 carries 26 override rows"

**Location:** `docs/working/plan-build-loop-handoff.md:273`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the count under the filter prior reviews used (`grep -cE '\| Defer \|.*\bU2\b' docs/reviews/override-log.md`); "carries" fixes no filter, so other filters give other counts.

The filter gives 26 at HEAD and 26 at main (command run in this session; output `26` / `26`). Iteration 1's Claim 33 (`code-fact-check-report-build-loop-u2a2.md:606`) got the same.

**Evidence:** `docs/reviews/override-log.md`; `docs/working/plan-build-loop-handoff.md:273`

---

## Claim 6: Q-119 update "U2a2 (the floor plus the walk, 400 code lines before U2a1's carried rows) was split again, then once more at its review's iteration 2 (fixes and tests put it near 480 lines)"

**Location:** `docs/working/questions.md:392`
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the "400" (the floor-plus-walk commit 6c41aea2 measures 398 changed code lines against main by pr-prep 1a's numstat) and the U2a2/U2a3/U2a4 assignment; does not establish "near 480", a projection of fixes never committed together (the rubric states ~480).

`git diff --numstat 20347279 6c41aea2 -- ':(top)' ':(top,exclude)docs/'` sums to 398. The unit names match the plan bullets (Claim 4).

**Evidence:** `docs/working/questions.md:392`; `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a2.md:13`

---

## Claim 7: check_fix's behaviour vs main changes only toward refusing more

**Location:** `scripts/dev-cycle.sh:170-183`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the removed eager `imported_names` call, the `isimported tree` arm, refusal order, and the token-rule changes (kept name, `..x`, `grep -a`, UNI_SPACES) for pathform-legal paths; does not establish that the walk is complete (Claim 9b shows a path it still misses, which main also missed).

Main ran `imported_names` before every branch; now `elif isimported tree "$lp"; then` runs it only for paths past the writable and deny arms, which are skips either way, and `check_path` (the only `ok` source) still runs need_root via `inrepo`. Each token change adds names: the whole name beside the stripped one (`:474`), `[[ "$p" != .. && "$p" != ../* ]]` (`:477`) where main dropped `..*`, `grep -aoE` (`:482`) where main's `grep -oE` printed nothing for a file holding a NUL. UNI_SPACES truncation removes only suffixes holding non-ASCII bytes, which pathform's `NAMECHARS='abc...XYZ0123456789._/-'` (`scripts/lib/dev-cycle-read.sh:142`) already refuses. The whole suite passes unchanged (100 ok), so no existing --check-fix expectation moved.

**Evidence:** `scripts/dev-cycle.sh:170-183`; `scripts/lib/dev-cycle-read.sh:142,468-482`; `logs/tests.txt`

---

## Claim 8: Header need_root list "inrepo, dirok, skipped, check_brief, isimported and the walk (imported_names) exit 1 (need_root) unless ROOT_REAL is set ..." and Inputs "imported_names reads the working tree at ROOT_REAL"

**Location:** `scripts/lib/dev-cycle-read.sh:14-16,29-32`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two added/edited sentences for isimported, imported_names, inrepo_here (rightly absent) and import_targets (rightly absent: it uses ROOT_REAL but never exits); does not re-verify the list's older members.

`isimported() { local lp; need_root; ...` (`:514-516`), `imported_names() { ... need_root` (`:491-493`); `inrepo_here() { [[ -z "$(blocker "$1" file)" && -f "$1" ]]; }` (`:124`) has no need_root; import_targets reads `$ROOT_REAL` in `realpath` only (`:476`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:14-16,29-32,124,468-482,491-521`

---

## Claim 9a: UNI_SPACES "U+00A0, U+1680, U+2000-200A, U+2028/2029, U+202F, U+205F, U+3000 and U+FEFF (Claude Code's token ends at JavaScript's \s, which includes U+FEFF)"

**Location:** `scripts/lib/dev-cycle-read.sh:450-455`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the 19 byte sequences decoded one by one and their equality with JavaScript's non-ASCII `\s` set and Claude Code 2.1.292's regex; does not establish that a token after one of them is read (Claim 9b).

Decoding the array gives 19 entries: `U+00A0 U+1680 U+2000 ... U+200A U+2028 U+2029 U+202F U+205F U+3000 U+FEFF`; node's enumeration of non-ASCII code points matching `/\s/` gives `a0 1680 2000-200a 2028 2029 202f 205f 3000 feff`, the same 19. Claude Code's regex `[^\s\\]` ends the token at `\s` (`logs/cc-import-fn.txt`). ASCII `\v`, `\f`, `\r` are in `[:space:]` under LC_ALL=C (IMPORT_RE).

**Evidence:** `scripts/lib/dev-cycle-read.sh:450-456`; `logs/cc-import-fn.txt` (command: `bash -c 'source scripts/lib/dev-cycle-read.sh; for u in "${UNI_SPACES[@]}"; ...python3 decode'` and `node -e '.../\s/.test...'`, exit 0, output quoted above)

---

## Claim 9b: UNI_SPACES "end an import token, as a blank does" and import_targets "A token may follow any byte but a letter or digit"

**Location:** `scripts/lib/dev-cycle-read.sh:450,460-461`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers an `@` that directly follows a UNI_SPACES character (no ASCII blank between); does not establish anything for an `@` after an ASCII blank or after a UNI space plus other text (both read correctly).

After a blank, the next `@` starts a new token; after a UNI_SPACES character it does not. `grep -aoE "$IMPORT_RE"` (`:482`) uses `[^][:space:]\\#`()]+`, which under LC_ALL=C runs on through the UTF-8 bytes, so one match swallows the next `@token`; the loop then cuts at the space (`for u in "${UNI_SPACES[@]}"; do t="${t%%"$u"*}"; done`, `:472`) and the second import is gone:

```
printf '@a.md\xc2\xa0@b.md\n' | import_targets ""    ->  a.md          (b.md lost)
printf '@a.md\xc2\xa0x @b.md\n' | import_targets ""  ->  a.md, b.md
```

Claude Code reads both: its regex on `"See @docs/a.md @docs/b.md"` returns `["docs/a.md","docs/b.md"]`, and the same for U+FEFF (`logs/node-regex.txt`). End to end, an AGENTS.md holding `See @docs/a.md<NBSP>@docs/b.md and @docs/c.md<U+FEFF>@docs/d.md`: `isimported tree` answers `docs/b.md -` and `docs/d.md -`, and `dev-cycle.sh --check-fix docs/b.md docs/a.md docs/d.md` prints `ok docs/b.md`, a skip for docs/a.md, and `ok docs/d.md` (`logs/probe3.txt`, `logs/probe3-checkfix.txt`). So --check-fix passes an imported, pathform-legal file (fails open). Main also misses b.md (it had no UNI_SPACES at all), so this is not a regression. No settled row covers it: the A5 row (`override-log.md:350`) lists symlinked directories, case-insensitive names, absolute imports, and backslash or trailing-`_` forms. To be accurate, the comments must say a token right after a UNI space is not read. To make the code match the comments, change each UNI_SPACES sequence to an ASCII blank before the grep.

**Evidence:** `scripts/lib/dev-cycle-read.sh:450,460-461,468-482`; `logs/probe2.txt`; `logs/probe3.txt`; `logs/probe3-checkfix.txt`; `logs/node-regex.txt` (repo `/tmp/u2a2f-fc3-ALNK/repo2`, 2026-10-06T21:07:47Z, exit 0)

---

## Claim 10: Token end set "a blank, a UNI_SPACES space, \, #, a backtick, ( ) [ or ]" vs IMPORT_RE

**Location:** `scripts/lib/dev-cycle-read.sh:461-462`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the end of the token being read (IMPORT_RE's excluded class plus the UNI_SPACES cut); does not establish agreement with Claude Code, which ends only at `\s` and an unescaped backslash, truncates at `#`, and keeps `( ) [ ]` and backticks (parens and brackets fail pathform, so --check-fix is not exposed through them).

`IMPORT_RE='(^|[^[:alnum:]])@[^][:space:]\\#`()]+'` (`:456`). Probe: `(@p.md) [@q.md] \`@r.md\` #@s.md \@u.md` yields p.md, q.md, r.md, s.md, u.md, and `@a.md\ b.md` yields a.md (`logs/probe1.txt`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:456,472`; `logs/probe1.txt`

---

## Claim 11: "grep -a reads text holding a NUL"

**Location:** `scripts/lib/dev-cycle-read.sh:462-463`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers imports before and after a NUL; does not establish the reading of a NUL *inside* a token: `read` drops the byte and joins the parts (`@c.md\0z` reads `c.mdz`). Claude Code would read `c.md\0z`, which names no openable file.

`printf '@a.md\0 @b.md\n' | import_targets ""` gives `a.md` and `b.md`; leading NULs hide nothing (`e.md`) (`logs/probe2.txt`). Removing `-a` fails test 1 (`logs/mnula.txt`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:482`; `logs/probe2.txt`; `logs/mnula.txt`

---

## Claim 12: "Claude Code keeps trailing punctuation (@x.md. reads x.md.)"

**Location:** `scripts/lib/dev-cycle-read.sh:463`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers Claude Code 2.1.292's import regex and the code after it (no punctuation stripping before path resolution); does not establish other Claude Code versions.

The bundled function runs `S=/(?:^|\s)@((?:[^\s\\]|\\ )+)/g`, cuts at `#`, replaces `\ `, and resolves `H` with no strip (`logs/cc-import-fn.txt`). Node gives `["docs/st.md."]` (`logs/node-regex.txt`).

**Evidence:** `logs/cc-import-fn.txt`; `logs/node-regex.txt`

---

## Claim 13: "a token ending in . , ; : ! ? * _ or ~ yields both its whole and its stripped name"

**Location:** `scripts/lib/dev-cycle-read.sh:464-465`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers several trailing marks, all-mark tokens, `~` and `/` starts, and whole or stripped names that leave the repo; does not establish what happens to the root `.` (yielded for `@x/../...`'s stripped form; harmless, no file).

```
v="$t"; while [[ "$v" == *[.,\;:!?*_~] ]]; do v="${v%?}"; done
for t in "$t" "$v"; do
  [[ -n "$t" && "$t" != "~"* && "$t" != /* ]] || continue
  p="$(realpath -ms --relative-to="$ROOT_REAL" -- "$ROOT_REAL/${1:+$1/}$t" 2>/dev/null)" || continue
  [[ "$p" != .. && "$p" != ../* ]] || continue
  printf '%s\n' "$p"
  [[ "$v" != "$t" ]] || break
done
```
(`scripts/lib/dev-cycle-read.sh:473-480`; the enclosing `while` ends at `:482` — read.) Probes: `@x.md.,;:!?*_~` gives `x.md.,;:!?*_~` and `x.md`; `@...` gives `...` only (stripped empty); `@~/foo.md.`, `@/abs.md.`, `@../x.md.` give nothing; `**@docs/x.md**` gives `docs/x.md**` and `docs/x.md`; a token without a mark is printed once (the `break`) (`logs/probe1.txt`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:468-482`; `logs/probe1.txt`; `logs/mkept.txt`

---

## Claim 14: "~/ and absolute paths, and paths leaving the repo (.. or ../, not a ..x name), are dropped"

**Location:** `scripts/lib/dev-cycle-read.sh:466-467`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `~/`, `/`, `..`, `../`, `..x`, and `../` from a subdirectory back to the top level; does not establish the wider `~*` drop as a comment claim: the code drops every `~`-start (`@~foo.md`), which Claude Code never imports either (its start test needs `~/` or `[a-zA-Z0-9._-]`).

`@..x.md` gives `..x.md`; from `d`, `@../x.md` gives `x.md` and `@../../x.md` nothing; `@..` nothing; `@~foo.md` nothing (`logs/probe1.txt`). The `..*` mutant fails test 1 (`logs/mdotdot.txt`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:475-477`; `logs/probe1.txt`; `logs/mdotdot.txt`; `logs/cc-import-fn.txt`

---

## Claim 15: "Every import walk shares these rules, so a change here changes --check-fix too"

**Location:** `scripts/lib/dev-cycle-read.sh:459-460`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers HEAD's one walk (imported_names) and the chain check_fix → isimported tree → imported_names → import_targets; does not establish U2a3's main_imports, which is not on this branch.

`done < <(import_targets "$d" < "$f")` (`:506`) is the only caller (grep of scripts/); `tree) imported_names; ...` (`:519`); `elif isimported tree "$lp"; then` (`scripts/dev-cycle.sh:181`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:491-521`; `scripts/dev-cycle.sh:181`

---

## Claim 16: "Over-reading (a code span) only over-refuses."

**Location:** `scripts/lib/dev-cycle-read.sh:466`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the walk reading `@` inside backticks or fences, which Claude Code skips (`if(S.type==="code"||...` in its token loop); does not establish every Markdown construct Claude Code skips.

Claude Code's import function skips code tokens (`function g(h){for(let S of h){if(S.type==="code"||S.type==="` in `logs/cc-import-fn.txt`); the walk greps raw text, so a code-span name is added to IMPORTED, which check_fix only refuses on (`scripts/dev-cycle.sh:181`).

**Evidence:** `logs/cc-import-fn.txt`; `scripts/lib/dev-cycle-read.sh:482,504`; `scripts/dev-cycle.sh:181`

---

## Claim 17: inrepo_here "inrepo for a caller that has run need_root itself (a walk, per path); it has no need_root of its own"

**Location:** `scripts/lib/dev-cycle-read.sh:122-124`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the definition and its callers in imported_names (`:496,505`), both after `need_root` at `:493`; does not establish future callers.

`inrepo() { need_root; inrepo_here "$1"; }` (`:121`); `inrepo_here() { [[ -z "$(blocker "$1" file)" && -f "$1" ]]; }` (`:124`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:121-124,491-507`

---

## Claim 18: imported_names' comment (starts at every instruction file tracked or not, resolves against the importer's dir, reads each plain file once, cached per root)

**Location:** `scripts/lib/dev-cycle-read.sh:440-448`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the start listing (tracked + untracked + ignored .md through instruction_names), dir-relative resolution, the seen set, and the IMPORTED_DONE cache; does not establish the known A2/A3 gaps (settled).

An ignored `CLAUDE.local.md`, untracked `sub/AGENTS.MD` and `sub/Skill.md` are all listed (`logs/probe4.txt`). `if [[ "$f" == */* ]]; then d="${f%/*}"; else d=""; fi` (`:502`) feeds `import_targets "$d"`; the seen test (`:505`) is load-bearing (`logs/mseen.txt`); `[[ "$IMPORTED_DONE" == "$ROOT_REAL" ]] && return` (`:494`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:440-448,491-507`; `logs/probe4.txt`; `logs/mseen.txt`

---

## Claim 19: instruction_names "matches INSTRUCTION_FILE's names; the walk's own test stays the authority. LC_ALL=C makes -i ASCII-only"; untracked_md "--others without --exclude-standard already lists ignored files"

**Location:** `scripts/lib/dev-cycle-read.sh:483-490`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the grep's names vs INSTRUCTION_FILE (`:439`) and the ignored-file listing; does not establish non-ASCII case folding beyond LC_ALL=C.

`grep -zaiE '(^|/)((claude|agents?|gemini)(\.[a-z0-9_-]+)?|skill)\.md$'` (`:487`) spells `^(claude|agents?|gemini)(\.[a-z0-9_-]+)?\.md$|^skill\.md$` (`:439`) on the basename; `imported_names` re-tests with `$INSTRUCTION_FILE` (`:496`). Ignored `CLAUDE.local.md` appears in `untracked_md` output (`logs/probe4.txt`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:439,483-490,496`; `logs/probe4.txt`

---

## Claim 20a: isimported "tree ... A walk name it does not know answers imported (0), so a caller testing it with `if` refuses. Run it in the caller's shell: the walk exits through need_root and caches its result."

**Location:** `scripts/lib/dev-cycle-read.sh:509-513`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the tree arm, the `*) return 0` arm and the caller-shell note; does not establish an answer for an unknown word when ROOT_REAL is bad: isimported's own `need_root` (`:516`) exits first (fails closed).

```
isimported() {
  local lp
  need_root
  lp="$(lower "$2")"
  case "$1" in
    tree) imported_names; [[ "$IMPORTED" == *$'\n'"$lp"$'\n'* ]] ;;
    *) return 0 ;;
  esac
}
```
(`scripts/lib/dev-cycle-read.sh:514-521`). Test 2 passes (`bogus: imported`); check_fix calls it in the main shell's `elif` (`scripts/dev-cycle.sh:181`), so the cache survives across arguments.

**Evidence:** `scripts/lib/dev-cycle-read.sh:509-521`; `test/scripts/build-loop-check.bats:41-45`; `logs/tests.txt`

---

## Claim 20b: isimported "(U2a3 adds main, the walk over the default branch's commit)"

**Location:** `scripts/lib/dev-cycle-read.sh:509-510`
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the forward reference only; what U2a3 will contain cannot be checked at this HEAD.

`feat/build-loop-u2a3` points at 7697c6e6 and holds no main_imports (paraphrased — no quote available because the claim covers absence of code). The removed version is at 7f295cdb on this branch's history. To verify, read U2a3 after it is built.

**Evidence:** `scripts/lib/dev-cycle-read.sh:509-510`

---

## Claim 21: entry_why "$2 is the path asked about, or "" (or no $2) ... error and any other word end "for $2" unless it is "", and notdir names only the directory above it"

**Location:** `scripts/lib/dev-cycle-read.sh:284-289`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers all five arms with a path, with "" and (for error) with no $2; does not establish callers' choice of argument.

`local w="${1//$'\n'/ }" p="${2-}"` and `error) echo "the tree of the default branch could not be read${p:+ for $p}" ;;` (`:291,297`). The test's new `entry_why error` line expects `the tree of the default branch could not be read` and passes (`test/scripts/dev-cycle.bats:1342,1355`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:284-300`; `test/scripts/dev-cycle.bats:1338-1356`; `logs/tests.txt`

---

## Claim 22: build-loop-check.bats header "the reader lib's import walks (... isimported, import_targets; main_imports from U2a3)" and imps' "walk: ok or walk: failed (main_imports' return; tree always reads ok)"

**Location:** `test/scripts/build-loop-check.bats:3-5,14-16`
**Type:** Staleness
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the comment against HEAD; does not establish U2a3's helper behaviour.

The header marks main_imports as U2a3's, but imps' comment and `if [[ "$w" != main ]] || main_imports; then` (`:21`) name a function absent at HEAD; `imps main` would print `walk: failed` by command-not-found under `if`, not by a walk return. To be precise, the imps comment should mark the main arm as U2a3's. No test calls `imps main`, and no test checks the `walk:` line here.

**Evidence:** `test/scripts/build-loop-check.bats:3-5,14-25`

---

## Claim 23: Test 1's name "Unicode spaces end a token, punctuation is read kept and stripped, a ..x name is followed, a NUL hides no import, a cycle ends" vs its assertions

**Location:** `test/scripts/build-loop-check.bats:27-39`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each named property against a mutant that removes it (U+FEFF, the whole UNI_SPACES cut, the kept name, `..x`, `-a`, the seen check: all six fail test 1); does not establish the Claim 9b case (no fixture has an `@` right after a UNI space), and docs/a.md (the token before the NUL) is not asserted.

`for p in "${ps[@]}"; do want "$p" imported; done` plus `want docs/other.md -; want docs/nb.md. -` (`:37-38`); `want` matches whole lines with `grep -qxF` (`:25`). Mutant results: `logs/mfeff.txt`, `logs/mnbspend.txt`, `logs/mkept.txt`, `logs/mdotdot.txt`, `logs/mnula.txt`, `logs/mseen.txt` (each `not ok 1`, `ok 2`; `bats test/scripts/build-loop-check.bats` in `/tmp/u2a2f-fc3-ALNK/m<name>`, exit 1).

**Evidence:** `test/scripts/build-loop-check.bats:17-39`; `logs/m*.txt`

---

## Claim 24: Test 2 "isimported answers imported under if for a walk name it does not know"

**Location:** `test/scripts/build-loop-check.bats:41-45`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the assertion `[ "$output" = "bogus: imported" ]`, which `*) return 1` would fail (no output); does not establish the bad-ROOT_REAL path.

`if isimported bogus docs/z.md; then echo "bogus: imported"; fi` (`:43`) under `set -euo pipefail`.

**Evidence:** `test/scripts/build-loop-check.bats:41-45`; `scripts/lib/dev-cycle-read.sh:520`

---

## Claim 25: fixture-git-env.bats "This suite's own fixture must stay out of an inherited GIT_DIR too" and "The inner runs name the victim's index too: it must come out byte for byte"

**Location:** `test/scripts/fixture-git-env.bats:11-13,18-19,26`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the setup unset, the index snapshot and cmp, and the inner dev-cycle test staging (`git add -A` at `test/scripts/dev-cycle.bats:1209`); does not establish the build-loop-read inner test's staging.

Commenting out dev-cycle.bats' `unset $(git rev-parse --local-env-vars)` (line 13) in a copy makes test 1 fail in `victim_unchanged` with the victim gaining commits `feature 1` ... and refs `f1`-`f3`, `trunk` (`logs/mut1.txt`; `bats -f 'dev-cycle.bats fixtures' test/scripts/fixture-git-env.bats` in `/tmp/u2a2f-fc3-ALNK/mut1`, 2026-10-06T21:09:30Z, exit 1). The inner filter selects one test (`1..1` asserted at `:23`).

**Evidence:** `test/scripts/fixture-git-env.bats:9-39`; `test/scripts/dev-cycle.bats:1207-1212`; `logs/mut1.txt`

---

## Claim 26: Commit 39ed1d53 (C12-C14 patches "as written", C16 "its trigger is an edit of one of row 327's suites, and none is edited here", "Tests: 105 across ... five")

**Location:** `39ed1d53` (commit message)
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the patch application, the C16 reasoning, and the 105 count at that commit; does not re-check its plan edits beyond Claims 3 and 5.

The two Appendix patches from `docs/reviews/test-strategy-review-2026-10-06-i3-build-loop-u2a1.md:110-142,148-171` apply to main with `git apply`, and the result is byte-identical to HEAD's fixture-git-env.bats; dev-cycle.bats differs only by bff4ded2's inventory lines (1086, 1089). Row 327's suites (merge-safety, cc-push, archive-working-docs, si-clean-state, cc-isolated-functions) are untouched (`git show --stat 39ed1d53`). `bats --count` over the five suites at 39ed1d53 gives 105.

**Evidence:** `docs/reviews/override-log.md:327`; `/tmp/u2a2f-fc3-ALNK/papply`, `/tmp/u2a2f-fc3-ALNK/c39`

---

## Claim 27: Commit bff4ded2 ("build-loop-check.bats 2", "mutants of U+FEFF, the kept name and the tree walk's seen check each fail", "100 across the five suites", "166 changed code lines against main", what moved to U2a3, "refuse slightly more (never less)")

**Location:** `bff4ded2` (commit message)
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the counts, the three named mutants, the move list against HEAD, and the refuse-more note (Claim 7); does not establish "near 480" (a projection), and "B13's evidence recorded on the settled token-form row" was recorded as a new row (356) that cites it, since the log is append-only.

`bats --count test/scripts/build-loop-check.bats` gives 2; the suite run gives 100 ok; `git diff --numstat main...HEAD -- ':(top)' ':(top,exclude)docs/'` gives 1+2, 71+29, 45+0, 6+4, 7+1 = 166. The three mutants fail (Claim 23). No main_imports, `isimported main` or known issue A5 at HEAD (paraphrased — no quote available because the claim covers absence of code).

**Evidence:** `logs/tests.txt`; `logs/mfeff.txt`; `logs/mkept.txt`; `logs/mseen.txt`; `docs/working/known-issues-dev-cycle.md`

---

## Claim 28: Commit 7697c6e6 "F11 names U2a3's main_imports as the floor's walk"

**Location:** `7697c6e6` (commit message)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the plan's F11 row text; does not establish U2a3's content.

`Floor item 1 walks main's commit with main_imports (U2a3, stacked on U2a2's shared token parser)` (`docs/working/plan-build-loop-handoff.md:126`).

**Evidence:** `docs/working/plan-build-loop-handoff.md:126`

---

## Claims Requiring Attention

### Incorrect
- **Claim 9b** (`scripts/lib/dev-cycle-read.sh:450,460-461`): an `@` right after a UNI_SPACES character is not read (grep's match runs through it), so `@docs/a.md<NBSP>@docs/b.md` imports b.md in Claude Code but --check-fix prints `ok docs/b.md`. Change the comments, or turn each UNI space into a blank before the grep.

### Mostly Accurate
- **Claim 22** (`test/scripts/build-loop-check.bats:14-16,21`): imps' comment and main arm name main_imports, absent until U2a3.

### Unverifiable
- **Claim 20b** (`scripts/lib/dev-cycle-read.sh:509-510`): "U2a3 adds main" is a forward reference; check it when U2a3 is built.

## Escalations

- **E1 (Medium, fails open, not a regression):** Claim 9b's shape is a --check-fix bypass by a pathform-legal path, executed end to end (`logs/probe3-checkfix.txt`). It is outside every settled row: the A5 row (`docs/reviews/override-log.md:350`) lists symlinked directories, case-insensitive names, absolute imports, and backslash or trailing-`_` forms. B1's fix (U+FEFF) is complete for the token it ends, but no fixture puts an `@` right after a UNI space. U2a3's main_imports will share import_targets, so the gate inherits the gap. Legibility-target: for-orchestrator-synthesis.

## Goal-Alignment Note

- **Success criterion (verbatim):** "a markdown report saved at the path given in your tail, structured per your skill, with `Commit: 7697c6e6` as its first line."
- **Answered:** brief items 1-9. Every count checks out (2, 100, 105, 166, 26, 398≈400). The token rules hold, with one exception: Claim 9b, an `@` right after a UNI space. The comments, tests, fixture-git-env patches, plan bullets, Q-119, the four U2a2 override rows and the U2a2 rubric rows are accurate. Each test assertion has a mutant that kills it.
- **Out of scope:** main_imports and the U2a3 rubric rows (B2-B4, B6, B8, B11, B12, B14); d8003fbf/7f295cdb commit messages (row 353).
- **Escalate:** E1.
- **Decisions:** probe logs are kept in `/tmp/u2a2f-fc3-ALNK/logs/` rather than `docs/reviews/execution-logs/`, per the shared rule to write nothing in the repo but this report. No hallucination pattern qualifies (the one Incorrect is a behaviour gap, not a fabricated symbol), so `docs/reviews/hallucination-patterns.md` is unchanged.
