Commit: a3489c4f

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u2a4 (branch feat/build-loop-u2a4)
**Scope:** `git diff 2b6f2f91..HEAD -- scripts/ test/ docs/working/` (commit 2f9464d3) plus the 2f9464d3 commit message; out-of-hunk comments in `scripts/lib/dev-cycle-read.sh` that the in-scope change made stale are included (Claims 15a-15c)
**Checked:** 2026-10-08
**Total claims checked:** 32
**Summary:** 21 verified, 8 mostly accurate, 2 stale, 0 incorrect, 1 unverifiable

Single replicate (k=1) confirming pass. `docs/reviews/hallucination-patterns.md` was read; no claim matched a logged pattern.

Execution provenance (all in working directory `/workspace/.claude/wt-build-loop-u2a4`, 2026-10-08 ~15:40-16:00 UTC, `LC_ALL=C`, bash run explicitly). Logs under `/tmp/claude-1000/-workspace/f0b98466-dcdf-4fba-b738-6bc01cfddae2/scratchpad/u2a4-confirm-fc/` (abbreviated `$S` below):

- E1 `bats test/scripts/build-loop-check.bats` exit 0, 78/78 ok: `$S/bats.log`
- E2 `bats` over `test/scripts/build-loop-read.bats` (19 ok), `test/scripts/dev-cycle.bats` (78 ok), `test/scripts/fixture-git-env.bats` (2), `test/fixture-hermeticity.bats` (2), `test/hermeticity-lint.bats` (53), each exit 0: `$S/<name>.log`; `shellcheck -S warning scripts/lib/dev-cycle-read.sh scripts/dev-cycle.sh scripts/build-loop.sh` exit 0: `$S/shellcheck.log`
- E3 `bats $S/probe.bats` exit 0 (fixture probes P1 link placements, P3 gitlinks, P4 checkout-only symlinked starts, P9 floor wording): `$S/probe.log`
- E4 `env LC_ALL=C HOME=$S bash $S/parser.sh` exit 0 (prompt_bases outputs, quoted-run parsing, work trailers, timing): `$S/parser.log`
- E5 `env LC_ALL=C HOME=$S bash $S/qopen.sh` exit 0 (unclosed `@"` vs `@` baseline timing; awk is `/usr/bin/mawk`): `$S/qopen.log`
- E6 `import_targets "" < $S/splice.md` exit 0 (quoted run that starts only after a comment splice): `$S/splice.log`

---

## Claim 1: "the instruction-file import walks, the read-as-truth rule and self-merge floor they serve"

**Location:** `scripts/lib/dev-cycle-read.sh:6-7`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the lib defines truthrule, truthwalk and floor alongside the walks; does not establish anything about callers outside the lib.

`truthrule() {` at `:1019`, `truthwalk() {` at `:1036`, `floor() {` at `:1068`, and floor calls `truthwalk main "$lp"` (`:1086`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1019-1090`

---

## Claim 2: "8. Pass truthrule, isstart, ownfile, prompt_dir and prompt_bases a lower-cased path (floor, check_fix and the walks lower first; truthrule refuses an upper-case letter as case)."

**Location:** `scripts/lib/dev-cycle-read.sh:68-70`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that every caller lowers before these five; does not establish that prompt_dir/prompt_bases take only a lower-cased path.

The walks do lower first: `lp="$(lower "$f")" ... prompt_dir pdir "$lp" "$f"` (`:870-873`) and `prompt_dir pdir "$f" "${cand[i]:2}"` with `f="${low[i]:2}"` (`:936-938`); truthrule refuses upper case (`:1021`). But prompt_dir and prompt_bases take two paths, a lower-cased LP and PATH as spelled: `# prompt_dir MAP LP PATH: ... (LP lower-cased, PATH as spelled)` (`:490-491`), and prompt_bases returns slices of the spelled one, `pb_a+=("${3:0:n-1}")` (`:505`). Precise version: "pass ... prompt_dir and prompt_bases a lower-cased LP (and the path as spelled)".

**Evidence:** `scripts/lib/dev-cycle-read.sh:490-508`, `:870-873`, `:936-938`, `:1019-1022`

---

## Claim 3: "A start directory, or .claude itself, as main_imports refuses a link there."

**Location:** `scripts/lib/dev-cycle-read.sh:487-488`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what START_LINK matches; does not establish anything about non-start `.claude/` subdirectories (none matched, correctly).

`START_LINK='/\.claude(/(rules|commands|agents|output-styles|skills)(/.*)?)?$'` also matches every path below a start directory (`(/.*)?`), and main_imports applies it to every link (`:930`). E3 P1: a link at `.claude/commands/sub` fails the walk ("below: walk: failed"), a link at a non-start `.claude/hook` does not. The main_imports comment (`:925`) says "at or below"; this one says only "a start directory". Precise version: "A start directory, a path below one, or .claude itself".

**Evidence:** `scripts/lib/dev-cycle-read.sh:488`, `:929-930`; `$S/probe.log` (E3 P1)

---

## Claim 4a: "A link or gitlink at or below a .claude/ start directory (or .claude itself) ... not modelled, so it fails (U2a4 final security F1)"

**Location:** `scripts/lib/dev-cycle-read.sh:925-927`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers symlinks and gitlinks main stores at `.claude`, at a start directory (top-level and nested `a/.claude/rules`), below one, and case variants; does not establish checkout-only links (handled by main_checkout).

`[[ ! "${ent[$f]}" =~ ^1[26]0000$ ]] || links+=("$f")` (`:922`), then `for f in "${parts[@]}"; do [[ ! "/$f" =~ $START_LINK ]] || isstart "$f" || return 1; done` (`:930`) over the lower-cased list. E1 test 74 (`.claude/commands`, `.claude/Skills`, `.claude` as links: walk failed); E3 P1 below-link and nested `a/.claude/rules` link: walk failed; E3 P3 gitlink at `.claude/commands`: walk failed; non-start link: walk ok.

**Evidence:** `scripts/lib/dev-cycle-read.sh:916-930`; `test/scripts/build-loop-check.bats:1163-1171`; `$S/bats.log`, `$S/probe.log`

---

## Claim 4b: "unless the link is a start itself (a rules file is followed, a prompt fails in the read arm)"

**Location:** `scripts/lib/dev-cycle-read.sh:927-928`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers symlink starts (rules followed, prompt fails); does not hold for a gitlink start, which is neither.

For a symlink it holds: a rules link is followed (test 74's first case, walk ok, docs/x.md imported) and a prompt link fails at `[[ ${#xs[@]} -eq 0 ]] || { IMPORTED_MAIN=error; return 1; }` (`:957`). But the exemption also lets a gitlink start through, and its read arm is `160000) continue ;;  # a gitlink: its files are not main's` (`:976`): E3 P3, a gitlink at `.claude/commands/g.md` gives "gitlink prompt start: walk: ok", and at `.claude/rules/g.md` "walk: ok" — skipped, neither followed nor failed. (A gitlink checks out as a directory, so no session loads it as a file.) Precise version: "unless the link is a start itself (a rules symlink is followed, a prompt symlink fails in the read arm, a gitlink start is skipped)".

**Evidence:** `scripts/lib/dev-cycle-read.sh:930`, `:950-977`; `$S/probe.log` (E3 P3)

---

## Claim 5: prompt_bases: "the top level and the one holding each .claude/ in its path (a nested one too ...), as PATH spells them, once each" / "Whole components, so .claude/.claude/ keeps both bases and .claudex is none"

**Location:** `scripts/lib/dev-cycle-read.sh:494-498`, `:502`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the base list for top-level, doubled, nested and `.claudex` paths and spelled-case slicing; does not establish behavior for paths with empty components (repo-relative paths have none).

```bash
# scripts/lib/dev-cycle-read.sh:503-507
IFS=/ read -r -a parts <<<"$2"
for c in "${parts[@]}"; do
  [[ "$c" != .claude || $n -eq 0 ]] || pb_a+=("${3:0:n-1}")
  n=$(( n + ${#c} + 1 ))
done
```

E4: `c/.claude/.claude/commands/y.md -> [] [c] [c/.claude]`; `e/.claudex/.claude/commands/z.md -> [] [e/.claudex]`; `A/.claude/Commands/X.md -> [] [A]` (spelled case); `.claude/commands/x.md -> []`. Test 77's `e/.claudex/f.md` imported and `e/f.md` not (E1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:499-508`; `$S/parser.log`, `$S/bats.log`

---

## Claim 6: "A quoted text that spans lines can resolve to a name holding a newline, which no file a walk admits has (and a printed one would split in two)."

**Location:** `scripts/lib/dev-cycle-read.sh:666-668`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the drop in put and that both walks refuse newline names; does not establish Claude Code's handling of such names.

`if (index(out, "\n")) return` (`:668`). Walks refuse newline names: `[[ -z "${ent[$f]+set}" && "$f" != *$'\n'* ]] || return 1` (`:919`), `[[ "$f" != *$'\n'* ]] || return 1` (`:932`, `:869`). E4: `@"docs/m.md\n"` prints no `docs/m.md\n` line, while `@"x\n/../docs/m.md"` resolves to `docs/m.md` (the newline part is popped by `..`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:652-674`, `:869`, `:919`, `:932`; `$S/parser.log`

---

## Claim 7a: scan: "the run after the quote is read as an unquoted one, and the whole quoted text once, at its closing quote on this line or, when CARRY is set, a later one ... so prefixes never grow past a blank"

**Location:** `scripts/lib/dev-cycle-read.sh:675-680`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers names() with no quote mode, the one emit of the quoted text, and the qopen carry; does not establish the cost of the carry (Claim 7b).

`names(line, i + 2, L)` breaks at `ch == " " || ch == "\t" || ch == "\r"` (`:687`, `:699`); `if (k > 1) emit(substr(r, 1, k - 1))` / `else if (k == 0 && carry && r != "") qopen = r` (`:690-691`); the main rule closes qopen at the next `"` (`:720-723`). E4: `@"docs/a b.md"` prints prefixes only to `docs/a` then `docs/a b.md` once; across lines resolves `docs/m.md`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:681-702`, `:719-725`; `$S/parser.log`

---

## Claim 7b: "(qopen holds it meanwhile, charged as work)"

**Location:** `scripts/lib/dev-cycle-read.sh:679`
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that each line read while a quote is open is charged once; does not establish that the carry's cost is bounded by the charge.

Each held line is charged: `work += length($0); if (work > wmax) exit 3` (`:721`). But the held text is re-copied on every line, `else qopen = qopen "\n" $0` (`:722`), and that copy is not charged, so CPU is quadratic in held lines while the charge is linear. E5 (mawk): unclosed `x @"a` then 40,000 / 80,000 short lines took 3.98 s / 17.67 s with work trailers `/708911` / `/1428911` (under 3% of the 50,000,000 bound); the same input led by `x @a` took 0.33 s / 0.72 s. Precise version: "each held line is charged once; re-copying the held text is not charged".

**Evidence:** `scripts/lib/dev-cycle-read.sh:719-725`; `$S/qopen.log`, `$S/parser.log`

---

## Claim 8a: "After @" the quoted text is also read whole, to its closing quote on that line or a later one"

**Location:** `scripts/lib/dev-cycle-read.sh:602-604`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the unspliced read; does not hold for a quote that begins only in the comment-spliced read.

The spliced line is scanned with carry off: `scan($0, 1); if (index($0, "<!--")) scan(splice($0), 0)` (`:724`). E6: `run @<!-- c -->"x` / `/../docs/m.md" now` yields no `docs/m.md` (count 0, rc=0), since `@"` exists only after the splice. The scan comment states the CARRY qualifier; this "one statement" paragraph omits it. Whether Claude Code reads such a mention is untraced.

**Evidence:** `scripts/lib/dev-cycle-read.sh:724`; `$S/splice.log`

---

## Claim 8b: "the prompt-mention reader of Claude Code 2.1.293, @"([^"]+)", that a command's names go through"

**Location:** `scripts/lib/dev-cycle-read.sh:603-605`, `:676`
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers nothing about Claude Code's binary; the lib's own handling is Claims 7a/8a.

paraphrased — no quote available because the claim is about an external package's source, which this pass did not extract. Verifying needs the Claude Code 2.1.293 package's mention regex (prior passes traced it; not re-traced here).

**Evidence:** none in repo

---

## Claim 9: "made absolute (ROOT_REAL/DIR/name for $1 and each further directory, unless it starts with /)"

**Location:** `scripts/lib/dev-cycle-read.sh:610-611`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers emit's join; does not cover ~/ names (stated separately).

`if (substr(c, 1, 1) == "/") { put(c); return }` / `for (i = 0; i <= nd; i++) put(root "/" dirs[i] "/" c)` (`:649-650`), with `dirs[0] = ENVIRON["IT_DIR"]` (`:715`) and `IT_DIR="$1" IT_XDIRS="$x"` from `"${@:2}"` (`:749`, `:768`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:636-651`, `:712-718`, `:746-770`

---

## Claim 10: "Re-check the superset when Claude Code changes its import grammar or its prompt-mention reader, ..."

**Location:** `scripts/lib/dev-cycle-read.sh:629-631`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the trigger names the prompt-mention reader, and that the paragraph names the quoted run (`:602-605`) and further directories (`:610`), as the commit says; does not judge trigger sufficiency.

Text as quoted at `:629-631`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:595-633`

---

## Claim 11: "the result is cached for the commit, MAIN_BY_NAME and root in IMPORTED_MAIN_DONE, never the checkout, whose files it read, nor HOME, so a caller whose checkout or HOME may have changed calls import_reset (contract item 4)"

**Location:** `scripts/lib/dev-cycle-read.sh:548-551`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the main walk's cache key and import_reset; does not establish callers comply.

`[[ "$IMPORTED_MAIN_DONE" == "$MAIN_SHA $MAIN_BY_NAME $ROOT_REAL" ]]` (`:912`); `import_reset() { IMPORTED_DONE=""; IMPORTED_MAIN_DONE=""; }` (`:558`); contract item 4 names checkout changes and HOME (`:56-58`). Test 78 covers import_reset (E1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:56-58`, `:556-558`, `:912-913`

---

## Claim 12: "A caller that changes it calls import_reset." (IMPORT_OUT_MAX and IMPORT_WORK_MAX)

**Location:** `scripts/lib/dev-cycle-read.sh:563`, `:571-572`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that neither cache key holds the budgets; does not establish callers comply.

Keys are `"$ROOT_REAL"` (`:864-865`) and `"$MAIN_SHA $MAIN_BY_NAME $ROOT_REAL"` (`:912`); contract item 4 lists both budgets (`:57`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:57`, `:864-865`, `:912`

---

## Claim 13: "Returns 0 when the walk fails (TRUTH_WHY=walk) or reaches PATH or cannot lower-case it (TRUTH_WHY=imported), else 1 with TRUTH_WHY empty"

**Location:** `scripts/lib/dev-cycle-read.sh:1033-1035`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers truthwalk's three outcomes; does not cover need_root's exit.

`TRUTH_WHY=imported; isimported "$1" "$2" || { TRUTH_WHY=""; return 1; }` (`:1039`), and isimported's `lp="$(lower "$2")" || return 0` (`:1001`). Tests 71 and 78 pass (E1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:998-1007`, `:1036-1040`

---

## Claim 14: floor reason "an instruction or prompt file (on the default branch, or only in the checkout) imports it with @"

**Location:** `scripts/lib/dev-cycle-read.sh:1088`; `test/scripts/build-loop-check.bats:35`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a checkout-only prompt importer reaching this reason; does not cover other start types beyond the suite's.

E3 P9: an untracked `.claude/commands/u.md` with `run @docs/z.md` gives `docs/z.md: an instruction or prompt file (on the default branch, or only in the checkout) imports it with @ ...`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1086-1088`, `:935-942`; `$S/probe.log`

---

## Claim 15a: "(so a pathological file fails the walk rather than stalling it)"

**Location:** `scripts/lib/dev-cycle-read.sh:625-628` (outside the diff hunk; staled by the in-scope qopen change)
**Type:** Performance
**Verdict:** Stale
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the unclosed-quote carry path added in 2f9464d3; does not establish wall-clock at the 4 MiB read cap (not run; extrapolated).

The uncharged per-line copy of qopen (Claim 7b) lets a file under the 4 MiB read cap run long without nearing a work bound: E5 1.4 MB took 17.67 s at 1,428,911 work units. Doubling lines raised time about 4.4x (3.98 s to 17.67 s), so a ~4 MB file extrapolates to minutes while still far under IMPORT_WORK_MAX. Before 2f9464d3 there was no carry.

**Evidence:** `scripts/lib/dev-cycle-read.sh:625-628`, `:719-723`; `$S/qopen.log`

---

## Claim 15b: "reading, draining and the scan of @-less lines are not charged"

**Location:** `scripts/lib/dev-cycle-read.sh:569-570` (outside the diff hunk)
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers lines read with no quote open; does not hold for @-less lines read while a quote is open.

Since 2f9464d3 an @-less line read while qopen is set is charged its length: `if (qopen != "") { work += length($0); ...` (`:720-721`). E5's work trailer grows with @-less lines (`/708911` for 40,000 lines).

**Evidence:** `scripts/lib/dev-cycle-read.sh:569-570`, `:719-723`; `$S/qopen.log`

---

## Claim 15c: main_imports' refusal lists ("It refuses what it does not model ... fail the walk"; "returns 1 ... when ...")

**Location:** `scripts/lib/dev-cycle-read.sh:527-537`, `:893-904` (outside the diff hunks)
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the lists' completeness after START_LINK; does not re-verify their other items.

paraphrased — no quote available because the claim is an absence across two enumerations (rg for `START_LINK` and "start directory" in both blocks finds nothing). Both enumerate why the main walk fails (`:893-904` reads as complete: "...or the IMPORT_OUT_MAX or IMPORT_WORK_MAX budget is spent") but neither names the new refusal at `:929-930` (a link or gitlink at or below a start directory or at `.claude`). Known issue A2 and the in-function comment at `:925-928` do name it.

**Evidence:** `scripts/lib/dev-cycle-read.sh:527-537`, `:893-904`, `:925-930`

---

## Claim 16a: test comment "A start directory, or .claude itself, stored as a link lists its prompts under the target's path, which isstart does not know: the walk fails"

**Location:** `test/scripts/build-loop-check.bats:1163-1164`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three link placements the test makes; does not cover gitlink placements (E3 P3 checks those separately).

Test 74 passes (E1); the baseline before the loop is `want walk ok; want docs/q.md -` (`:1166`).

**Evidence:** `test/scripts/build-loop-check.bats:1157-1172`; `$S/bats.log`

---

## Claim 16b: "A quoted text that spans lines resolves across the break (U2a4 final security F2); a .claudex component is no session base (final fact-check 31)."

**Location:** `test/scripts/build-loop-check.bats:1197-1198`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both walks for these fixtures; nothing broader.

Test 77 passes with `docs/m.md` and `e/.claudex/f.md` imported and `e/f.md` not (`imps main e/f.md; want e/f.md -`).

**Evidence:** `test/scripts/build-loop-check.bats:1191-1213`; `$S/bats.log`

---

## Claim 16c: "Lines of 2,000 quotes after an @, and an unclosed @" before 3 KB of prose, in an instruction file and a prompt, cost little parser work: the walk passes"

**Location:** `test/scripts/build-loop-check.bats:1201-1202`
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the per-read work of both lines and that the walk passes; does not establish a numeric threshold the test asserts (it asserts only that the walk passes).

The walk passes (E1). The 3 KB line costs 3,086 work units per read (E4). The 2,000-quote line costs 8,017,995 per read (E4), 16% of IMPORT_WORK_MAX (50,000,000), quadratic in the run; "little" fits the 3 KB line, not that one. The 2,000-quote line is only in CLAUDE.md, the 3 KB line in both (`tee -a CLAUDE.md >> .claude/commands/q.md`).

**Evidence:** `test/scripts/build-loop-check.bats:1201-1204`; `$S/parser.log`

---

## Claim 17: Known issue A2: "the main walk follows a symlinked instruction file main stores, and fails on a checkout-only symlinked start and on a symlinked prompt ... A start directory (or .claude itself) that main stores as a link fails the main walk too"

**Location:** `docs/working/known-issues-dev-cycle.md:16`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers all four main-walk behaviors named; does not re-verify the tree-walk sentence (unchanged).

Test 74 (rules link followed, prompt link fails, start-dir links fail); E3 P4 an untracked `CLAUDE.md` symlink and an untracked `.claude/commands/u.md` symlink each give "walk: failed".

**Evidence:** `scripts/lib/dev-cycle-read.sh:929-930`, `:957`; `$S/bats.log`, `$S/probe.log`

---

## Claim 18: Known issue A5: "the lib header's numbered gate caller contract, U2a4, is the one statement of what a caller owes the walk and the floor"

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the header contract exists and calls itself the one statement; nothing else in A5 changed.

`# The gate caller contract, for floor and main_imports (the one statement of it; plan step 5's U2b bullet and known issue A5 point here ...)` (`scripts/lib/dev-cycle-read.sh:43-44`), items 1-8 follow.

**Evidence:** `scripts/lib/dev-cycle-read.sh:43-70`

---

## Claim 19a: "Tests: build-loop-check 78/78 ..., build-loop-read 19, dev-cycle 78, fixture-git-env 2, fixture-hermeticity 2, hermeticity-lint 53; shellcheck -S warning clean."

**Location:** commit 2f9464d3 message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers these counts at HEAD a3489c4f (its later commit touches only docs/reviews); does not cover other suites.

E1 and E2: all exit 0 with exactly these ok counts; shellcheck exit 0.

**Evidence:** `$S/bats.log`, `$S/build-loop-read.log`, `$S/dev-cycle.log`, `$S/fixture-git-env.log`, `$S/fixture-hermeticity.log`, `$S/hermeticity-lint.log`, `$S/shellcheck.log`

---

## Claim 19b: "(new cases in tests 6 and 9)"

**Location:** commit 2f9464d3 message
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the reading "the 6th and 9th of the unit's ten tests (bats 69-78)"; the numbering base is not stated in the message.

The changed tests are bats 74 (`:1157`) and 77 (`:1191`); the U2a4 tests are bats 69-78 (`$S/bats.log`), so 74 and 77 are the 6th and 9th.

**Evidence:** `test/scripts/build-loop-check.bats:1157`, `:1191`; `$S/bats.log`

---

## Claim 19c: "the unit is 540 code lines (cap 400)"

**Location:** commit 2f9464d3 message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count as insertions plus deletions over scripts/ and test/ against main; does not adjudicate the counting method.

`git diff main...HEAD --stat -- scripts test`: "3 files changed, 470 insertions(+), 70 deletions(-)" = 540. Override-log row added in 2f9464d3 says the same.

**Evidence:** `git diff main...HEAD --numstat -- scripts test` (10/12, 246/58, 214/0)

---

## Claim 19d: "override rows 463, 468 (security F4's wider trigger) and 477 corrected; rows for the declined findings and the size"

**Location:** commit 2f9464d3 message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which rows changed and that rows were added; does not re-verify the rows' content.

`git diff 2b6f2f91..2f9464d3 -- docs/reviews/override-log.md`: hunks change file lines 463, 468 and 477 and add six 2026-10-08 rows, the last for the 540-line size.

**Evidence:** `docs/reviews/override-log.md:463`, `:468`, `:477-486`

---

## Claim 19e: "Security F1: a link or gitlink main stores at or below a .claude/ start directory, or at .claude itself, fails the main walk (START_LINK), unless the link is itself a start (a rules file link is still followed)."

**Location:** commit 2f9464d3 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** As Claims 4a/4b; the message says "a rules file link", which is true for a symlink (a gitlink start is skipped, Claim 4b).

See Claims 4a, 4b.

**Evidence:** `scripts/lib/dev-cycle-read.sh:922-930`; `$S/probe.log`

---

## Claim 19f: "the whole quoted text once, at its closing quote on that line or a later one (qopen, charged as work), so a quoted mention spanning lines resolves and an unclosed @" before long prose no longer prints quadratic prefixes; put drops a resolved name holding a newline."

**Location:** commit 2f9464d3 message
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the single-line prose case (fixed) and the multi-line carry; the "charged as work" part carries the verdict.

The single-line case is fixed (E4: 3 KB unclosed line costs 3,086 and prints nothing). "charged as work" is partly true: the held lines are charged, the per-line re-copy is not, and the carry is quadratic in wall-clock (Claim 7b, E5).

**Evidence:** `scripts/lib/dev-cycle-read.sh:681-693`, `:719-725`; `$S/parser.log`, `$S/qopen.log`

---

## Claim 19g: "prompt_bases splits whole path components, so .claudex gives no base"; "floor's import reason names prompt and checkout-only importers"; "the cache comments point to import_reset"; "contract item 8 names prompt_dir and prompt_bases"; "truthwalk's lower-case failure"; "the lib summary names the floor"; "the parser's one-statement paragraph names the quoted run, the further base directories and the prompt-mention reader as a re-check trigger"

**Location:** commit 2f9464d3 message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that each named change is present in the diff; the accuracy of each changed text is verdicted in Claims 1, 2, 5, 10, 11, 13, 14.

Each is present in `git diff 2b6f2f91..HEAD -- scripts/lib/dev-cycle-read.sh` at `:6-7`, `:68-70`, `:499-508`, `:548-551`, `:563`, `:571-572`, `:602-611`, `:629-631`, `:1033-1034`, `:1088`.

**Evidence:** `scripts/lib/dev-cycle-read.sh` (lines above)
