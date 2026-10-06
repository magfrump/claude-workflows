Commit: 7697c6e6

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u2a2 (branch feat/build-loop-u2a2)
**Scope:** full branch, net diff `git diff main...HEAD` (main 20347279, HEAD 7697c6e6): scripts/lib/dev-cycle-read.sh, scripts/dev-cycle.sh, test/scripts/build-loop-check.bats, test/scripts/fixture-git-env.bats, test/scripts/dev-cycle.bats, docs/working/plan-build-loop-handoff.md, docs/working/questions.md, the appended docs/reviews/override-log.md rows, the iteration-2 rubric's B-row statuses, and commit messages 39ed1d53, bff4ded2, 7697c6e6. The other review files and d8003fbf/7f295cdb are context only.
**Commit:** 7697c6e6
**Replication:** k=3 (replicate)
**Checked:** 2026-10-06
**Total claims checked:** 38
**Summary:** 28 verified, 6 mostly accurate, 0 stale, 2 incorrect, 2 unverifiable

The hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) was read first. The only logged pattern near this scope is a wrong test count in a commit message (the "All 85 tests" and "mode1-equiv 33" entries). Every count here was executed and none matches that pattern (Claims 23, 24a).

Execution provenance. Repo commands ran with cwd `/workspace/.claude/wt-build-loop-u2a2`. Probes and mutants ran in `git archive` copies under `/tmp/u2a2f-fc3-YhOO/`. shared3.md forbids repo writes beyond this report, so the skill's `docs/reviews/execution-logs/` was not used. Captured output and the probe scripts are in `/tmp/u2a2f-fc3-YhOO/logs/`. Versions: bash 5.2.15, GNU grep 3.8 (`/usr/bin/grep`, the binary non-interactive bash uses), git 2.39.5, node v22.23.2. All processes ran under `timeout` and have exited.

- **X1** (2026-10-06T21:06:33Z, exit 0): `TMPDIR=$(mktemp -d /tmp/u2a2f-x-XXXX) bats test/scripts/build-loop-check.bats test/scripts/dev-cycle.bats test/scripts/fixture-git-env.bats test/scripts/build-loop-read.bats test/fixture-hermeticity.bats` printed `1..100` with 100 `ok` lines and no `not ok`. Log: `logs/tests.log`.
- **X2** (21:08:04Z and 21:08:24Z, exit 0): `bash probe.sh LIB` and `bash probe2.sh LIB`, run in an empty `git init` repo, fed token shapes to `import_targets` through a file. Logs: `logs/probe.out` and `logs/probe2.out`.
- **X3** (21:09:41Z, exit 0): `bash corner.sh SCRATCH` built the same fixture repo twice and ran `dev-cycle.sh --check-fix` from main's `scripts/` (a `git archive main scripts` copy) and from HEAD's. Log: `logs/corner.out`.
- **X4** (21:11:31Z, exit 0): `bash mut.sh SCRATCH` ran `bats test/scripts/build-loop-check.bats` against seven one-edit mutants, each in its own archive copy. Logs: `logs/mut.out` and `logs/m-*.log`.
- **X5** (21:11:58Z, exit 0): `bash untr.sh LIB` exercised `untracked_md` and `instruction_names` in a throwaway repo. Log: `logs/untr.out`.
- **X6** (21:13:08Z, exit 1 as expected): in an archive copy, dev-cycle.bats:13's unset was replaced by `unset GIT_DIR`, then `bats -f 'dev-cycle.bats fixtures' test/scripts/fixture-git-env.bats` ran. Log: `logs/m-idx.log`.
- **X7** (21:13:59Z, exit 0): the same five suites ran in a `git archive 39ed1d53` copy and printed `1..105` with 105 `ok`. Log: `logs/at39.log`.
- **X8** (21:14:19Z, exit 0): node enumerated every BMP code point that matches `/\s/`, and bash decoded each `UNI_SPACES` element through `iconv -t UTF-32BE`. Logs: `logs/node-ws.out` and `logs/unispaces.out`.
- **Blocked:** reading Claude Code 2.1.292's bundled import code (`claude.exe`) was denied by the permission classifier. Every claim about Claude Code's own rule is therefore Unverifiable in this replicate, and it rests on the security reviewer's executed evidence recorded at override-log.md:356.

---

## Claim 1a: Rubric B1, B5 (tree half), B7, B9 and B13 statuses ("✅ Fixed", "Won't-Fix (override row)")

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a2.md:18-30`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each named fix at HEAD and its mutant (X4). It does not cover the B rows routed to U2a3, which are outside this unit.
**Legibility-target:** for-orchestrator-synthesis

- **B1:** `$'\xef\xbb\xbf'` is the last `UNI_SPACES` element (`scripts/lib/dev-cycle-read.sh:455`). The `feff` mutant that removes it fails test 1.
- **B13:** `for t in "$t" "$v"; do` (`:472`) yields the whole name and then the stripped one. The `nokept` mutant fails.
- **B9:** the rules now sit on `import_targets` (`:458-467`), and that comment includes "Every import walk shares these rules, so a change here changes --check-fix too".
- **B5, tree half:** `docs/c.md` imports itself, `@b.md` and `@../CLAUDE.md` (`test/scripts/build-loop-check.bats:31`), and `imps` runs `timeout 60` (`:19`). The `noseen` mutant fails test 1.
- **B7:** the row is at `docs/reviews/override-log.md:355`, marked "Won't-Fix".

**Evidence:** `scripts/lib/dev-cycle-read.sh:450-482`, `test/scripts/build-loop-check.bats:17-39`, `docs/reviews/override-log.md:355`, `/tmp/u2a2f-fc3-YhOO/logs/mut.out`

---

## Claim 1b: Rubric B10 "✅ Fixed here (inrepo_here)" for "The header omits `inrepo_here` (no need_root guard)"

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a2.md:27`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers where the inrepo_here contract is now written. It does not judge whether the header needs it.
**Legibility-target:** for-author

The fix is a comment beside the function: `# inrepo for a caller that has run need_root itself (a walk, per path); it has` / `# no need_root of its own.` (`scripts/lib/dev-cycle-read.sh:122-123`). The header the finding names still lists only `check_brief, isimported and the walk (imported_names) exit 1 (need_root)` (`:15`) and does not name inrepo_here. The precise status would be: "fixed beside the function; the header still omits it".

**Evidence:** `scripts/lib/dev-cycle-read.sh:12-32`, `:121-124`

---

## Claim 2: The four `feat/build-loop-u2a2` override rows dated 2026-10-06 (shared3.md says three)

**Location:** `docs/reviews/override-log.md:353-356`
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the row count, row 354's line numbers at 39ed1d53, row 355's "q is ~45" and row 356's statement of what import_targets now does. It does not establish row 355's millisecond figures (not re-timed) or row 356's Claude Code regex (see Claim 14i).
**Legibility-target:** for-orchestrator-synthesis

`grep -c '| \`feat/build-loop-u2a2\` |'` gives 4 rows at HEAD and 0 on main, so the brief's "three" is off by one. Row 354 says the short header lines are at `:18` and `:21` at 39ed1d53. There those lines are 69 and 70 characters long, against 79-80 around them (awk length over `git show 39ed1d53:scripts/lib/dev-cycle-read.sh`). Row 355's "q is ~45" matches the 45 start files that `{ git ls-files -z; untracked_md; } | instruction_names` lists in this worktree (executed, 21:14Z). Row 356's "import_targets now yields a punctuation-ended token's whole name as well as its stripped one" matches X2: `@a.md.` gives `a.md.` and then `a.md`.

**Evidence:** `docs/reviews/override-log.md:353-356`, `/tmp/u2a2f-fc3-YhOO/logs/probe.out`

---

## Claim 3: Plan F10: "keeps the docs `check_fix` denies (`docs/decisions/`, `docs/human-author/`, other briefs' working docs, cycle files) and adds `docs/thoughts/`, which `check_fix` still fixes"

**Location:** `docs/working/plan-build-loop-handoff.md:125`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers check_fix's denials against the listed docs and the thoughts/ claim. It does not cover the floor's own list (U2a4, not yet written).
**Legibility-target:** for-orchestrator-synthesis

check_fix denies `"$lp" =~ ^docs/(working|human-author|reviews|decisions)/` plus `docs/dev-cycle.md` and `docs/constraints.md` (`scripts/dev-cycle.sh:177-178`). Nothing there matches `docs/thoughts/`, so a `.md` file under it passes the `^docs/.*\.md$` allowlist. The parenthetical names the subset the floor keeps. The two lists differ on purpose (reviews/, constraints.md), which the settled row at `docs/reviews/override-log.md:348` and plan :192 already record.

**Evidence:** `scripts/dev-cycle.sh:170-183`, `docs/working/plan-build-loop-handoff.md:192`

---

## Claim 4: Plan F11: "Floor item 1 walks main's commit with `main_imports` (U2a3, stacked on U2a2's shared token parser), not `check_fix`'s working-tree walk, whose known issues A2/A3 remain"

**Location:** `docs/working/plan-build-loop-handoff.md:126`
**Type:** Architectural / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers U2a3's stacking on the shared parser and the A2/A3 entries. It does not verify U2a3's modelling claims, which belong to its own review.
**Legibility-target:** for-orchestrator-synthesis

On `feat/build-loop-u2a3`, main_imports calls the shared parser: `out="$(git cat-file blob "$MAIN_SHA:$f" | import_targets "$d")"` (`git show feat/build-loop-u2a3:scripts/lib/dev-cycle-read.sh`, line 583). The known-issues table still holds `| A2 | 🟡 Medium | The walk never starts from \`.claude/rules/**/*.md\`` and `| A3 | 🟡 Medium (rare) |` (`docs/working/known-issues-dev-cycle.md:16-17`). At bff4ded2, F11 was main's text (no diff), so 7697c6e6 is the only F11 edit.

**Evidence:** `docs/working/known-issues-dev-cycle.md:16-17`, `feat/build-loop-u2a3:scripts/lib/dev-cycle-read.sh:577-583`

---

## Claim 5: "U2 carries 26 override rows"

**Location:** `docs/working/plan-build-loop-handoff.md:273`
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the count under the grep U2a1's fact-check used. It does not establish which rows the author meant, and other reasonable greps give 30-37.
**Legibility-target:** for-orchestrator-synthesis

`LC_ALL=C grep -cE '\| Defer \|.*\bU2\b' docs/reviews/override-log.md` gives 26 on main, at 900c47d0 and at HEAD. This is the definition in `docs/reviews/code-fact-check-report-build-loop-u2a1-r1.md:877` ("26 Defer rows on main name U2"). Broader patterns give other totals, for example 30 for `\bU2\b` in any column.

**Evidence:** `docs/reviews/override-log.md`, `docs/reviews/code-fact-check-report-build-loop-u2a1-r1.md:344-358`

---

## Claim 6: Plan U2a2 bullet: "`import_targets` (UTF-8 spaces including U+FEFF end a token; a token ending in punctuation yields its whole and its stripped name; a `..x` name is followed; text holding a NUL is read), `isimported tree`, which `check_fix` calls, and U2a1's carried rows C12-C14"

**Location:** `docs/working/plan-build-loop-handoff.md:275`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed element at HEAD. "Punctuation" means only the nine marks in `*[.,\;:!?*_~]`: other punctuation such as `)` ends the token instead.
**Legibility-target:** for-orchestrator-synthesis

Each part was checked:

- X2 gives `nb.md`, `bom.md`, `ls.md` and `ideo.md` for the four Unicode-space cases.
- `@a.md.` yields both names.
- `@..x.md` from `docs` gives `docs/..x.md`.
- `@docs/a.md\0 then @docs/b.md` yields both names (probe2).
- `elif isimported tree "$lp"; then` is at `scripts/dev-cycle.sh:181`.
- For C12-C14, see Claims 22 and 21.

**Evidence:** `scripts/lib/dev-cycle-read.sh:468-482`, `scripts/dev-cycle.sh:181`, `/tmp/u2a2f-fc3-YhOO/logs/probe.out`, `/tmp/u2a2f-fc3-YhOO/logs/probe2.out`

---

## Claim 7: Q-119 update: "U2a2 (the floor plus the walk, 400 code lines before U2a1's carried rows) was split again, then once more at its review's iteration 2 (fixes and tests put it near 480 lines) ... Under [3], U2a3 is the unit replaced."

**Location:** `docs/working/questions.md:392`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers "near 480" against the rubric and the unit names against the plan. It does not establish the "400 code lines" figure (no artifact), and it notes a contradiction with the unchanged line below.
**Legibility-target:** for-author

The rubric says "~480 code lines" (`code-review-rubric-2026-10-06-feat-build-loop-u2a2.md:12`), and the U2a2/U2a3/U2a4 names match plan :275-277. The next line, which this branch did not edit, still says `[3] replaces U2a2's walk.` (`docs/working/questions.md:393`). That contradicts the update's "Under [3], U2a3 is the unit replaced." A reader of the entry's "If the answer differs" line gets the old unit. The precise version would update :393 to name U2a3.

**Evidence:** `docs/working/questions.md:392-393`, `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a2.md:12`

---

## Claim 8: check_fix's behaviour is unchanged from main except the eager `imported_names` call is gone and `isimported tree` replaces the cache read; no existing --check-fix test expectation changed

**Location:** `scripts/dev-cycle.sh:174-182`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the refusal order, the need_root timing and the unchanged test expectations. It does not cover the token-rule change's effect on which paths are imported, which is Claim 24b.
**Legibility-target:** for-orchestrator-synthesis

The diff removes one line, `imported_names`, before `if writable "$a" || writable "$lp"`, and turns `elif [[ "$IMPORTED" == *$'\n'"$lp"$'\n'* ]]` into `elif isimported tree "$lp"; then` (`scripts/dev-cycle.sh:181`). isimported runs `need_root` and then `imported_names; [[ "$IMPORTED" == *$'\n'"$lp"$'\n'* ]]` (`scripts/lib/dev-cycle-read.sh:514-521`), which is the same membership test on the same cache.

On main the walk ran before the writable and allowlist branches, so a failing need_root exited even for a path those branches skip. dev-cycle.sh sets `ROOT_REAL="$(pwd -P)"` right after `cd "$ROOT"` (`scripts/dev-cycle.sh:119-121`), so need_root cannot fail there and the order change is not observable.

check_fix runs in the script's own shell (`--check-fix) check_fix "$a" ;;`, `:200`), so need_root's exit and the cache both hold. The dev-cycle.bats diff touches only the inventory (`:1086`, `:1089`) and the entry_why test. All 100 tests pass (X1).

**Evidence:** `scripts/dev-cycle.sh:119-121`, `:170-183`, `:194-203`, `scripts/lib/dev-cycle-read.sh:491-521`, `/tmp/u2a2f-fc3-YhOO/logs/tests.log`

---

## Claim 9: Lib header: "check_brief, isimported and the walk (imported_names) exit 1 (need_root) unless ROOT_REAL is set ..."; Inputs: "imported_names reads the working tree at ROOT_REAL"

**Location:** `scripts/lib/dev-cycle-read.sh:14-17`, `:29-32`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers isimported's and imported_names' need_root calls and the walk's inputs. It does not cover inrepo_here, which has no guard and is not listed (Claim 1b).
**Legibility-target:** for-orchestrator-synthesis

isimported starts with `local lp` / `need_root` (`:515-516`), and imported_names calls `need_root` at `:493`. The walk reads `git ls-files` output and files under the cwd (`done < <(import_targets "$d" < "$f")`, `:506`), never a commit.

**Evidence:** `scripts/lib/dev-cycle-read.sh:91-95`, `:491-521`

---

## Claim 10: "inrepo for a caller that has run need_root itself (a walk, per path); it has no need_root of its own."

**Location:** `scripts/lib/dev-cycle-read.sh:122-123`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers inrepo_here's body and its callers on this branch. It does not cover U2a3's call sites.
**Legibility-target:** for-orchestrator-synthesis

The body is `inrepo_here() { [[ -z "$(blocker "$1" file)" && -f "$1" ]]; }` (`:124`) and has no need_root. Its callers are `inrepo` (`:121`, after `need_root`) and imported_names (`:497` and `:505`), which runs `need_root` at `:493` first. Neither the scripts nor the tests have any other caller (grep).

**Evidence:** `scripts/lib/dev-cycle-read.sh:121-124`, `:491-508`

---

## Claim 11: entry_why: "$2 is the path asked about, or "" (or no $2) ... error and any other word end "for $2" unless it is """

**Location:** `scripts/lib/dev-cycle-read.sh:284-289`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the one-argument call and the error and default arms. Other words were already pinned by U2a1.
**Legibility-target:** for-orchestrator-synthesis

The function reads `local w="${1//$'\n'/ }" p="${2-}"` (`:291`) and `error) echo "the tree of the default branch could not be read${p:+ for $p}" ;;` (`:297`). The dev-cycle.bats test adds `entry_why error` with no `$2` and expects `the tree of the default branch could not be read`. That test passes in X1.

**Evidence:** `scripts/lib/dev-cycle-read.sh:290-300`, `test/scripts/dev-cycle.bats:1339-1356`, `/tmp/u2a2f-fc3-YhOO/logs/tests.log`

---

## Claim 12: imported_names' comment: the walk "resolves each @path against the importing file's directory as Claude Code does (~/ and absolute paths lead outside the repo and are not followed), and reads each plain file it reaches once (import_targets has the token rules). One result is cached, for the root in IMPORTED_DONE"

**Location:** `scripts/lib/dev-cycle-read.sh:440-448`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers resolution against the importer's directory, the once-per-file read and the cache. "As Claude Code does" is Unverifiable here (binary read blocked). The ~ rule is broader than "~/" (Claim 14f).
**Legibility-target:** for-orchestrator-synthesis

Resolution: `if [[ "$f" == */* ]]; then d="${f%/*}"; else d=""; fi` feeds `import_targets "$d"` (`:503-506`). X2 shows `@../CLAUDE.md` from `docs` giving `CLAUDE.md`.

Once per file: `if [[ "$seen" != *$'\n'"$p"$'\n'* ]] && inrepo_here "$p"; then seen+=...; queue+=...` (`:505`). The `noseen` mutant makes test 1 fail by timeout (X4).

Cache: `[[ "$IMPORTED_DONE" == "$ROOT_REAL" ]] && return; IMPORTED_DONE="$ROOT_REAL"` (`:494`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:491-508`, `/tmp/u2a2f-fc3-YhOO/logs/m-noseen.log`

---

## Claim 13: UNI_SPACES: "U+00A0, U+1680, U+2000-200A, U+2028/2029, U+202F, U+205F, U+3000 and U+FEFF (Claude Code's token ends at JavaScript's \s, which includes U+FEFF)"

**Location:** `scripts/lib/dev-cycle-read.sh:450-455`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the bytes against the comment and against JavaScript's `\s`. It does not establish that Claude Code's token rule is `\s` (Claim 14i).
**Legibility-target:** for-orchestrator-synthesis

The 19 elements decode (X8) to `a0 1680 2000-200a 2028 2029 202f 205f 3000 feff`, which matches the comment exactly. Node's `/\s/` matches 25 BMP code points: `0009 000a 000b 000c 000d 0020` plus exactly those 19. The six ASCII ones fall in `[:space:]` under LC_ALL=C in IMPORT_RE (`:456`), so the lib's end set covers all of JavaScript's `\s`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:450-456`, `/tmp/u2a2f-fc3-YhOO/logs/node-ws.out`, `/tmp/u2a2f-fc3-YhOO/logs/unispaces.out`

---

## Claim 14a: "A token may follow any byte but a letter or digit (so user@host is not one)"

**Location:** `scripts/lib/dev-cycle-read.sh:460-461`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers ASCII letters and digits, and non-ASCII bytes under the forced C locale. It does not compare this with Claude Code's whitespace-only start.
**Legibility-target:** for-orchestrator-synthesis

IMPORT_RE is `'(^|[^[:alnum:]])@...'` (`:456`), run as `env LC_ALL=C grep -aoE "$IMPORT_RE"` (`:481`). In X2, `user@host.md` yields nothing, and `é@e.md` yields `e.md` because a UTF-8 lead byte is not `[:alnum:]` in C.

**Evidence:** `scripts/lib/dev-cycle-read.sh:456`, `:481`, `/tmp/u2a2f-fc3-YhOO/logs/probe.out`

---

## Claim 14b: "it ends at a blank, a UNI_SPACES space, \, #, a backtick, ( ) ... or ]"

**Location:** `scripts/lib/dev-cycle-read.sh:461-462`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed end except `[` (Claim 14c). "A blank" is narrower than the code, which also ends at `\v`, `\f` and `\r` (`[:space:]`), and every token also ends at a newline (grep reads lines).
**Legibility-target:** for-orchestrator-synthesis

The bracket `[^][:space:]\\#\`()]` (`:456`) excludes `]`, the `[:space:]` class, `\`, `#`, the backtick, `(` and `)`. `for u in "${UNI_SPACES[@]}"; do t="${t%%"$u"*}"; done` (`:471`) cuts at each Unicode space. X2 results:

- `@a.md#frag` gives `a.md`.
- `@b(1).md` gives `b`.
- `` @d`e `` gives `d`.
- `@f\ g.md` gives `f`.
- `@a.md\vx`, `@b.md\fy`, `@c.md\rz` and `@d.md\tq` give `a.md` through `d.md`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:456`, `:468-482`, `/tmp/u2a2f-fc3-YhOO/logs/probe.out`

---

## Claim 14c: "... ( ) [ or ]": `[` ends a token

**Location:** `scripts/lib/dev-cycle-read.sh:462`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the lib's regex. It does not establish what Claude Code reads for `[` (routed to U2a3 as B14's "`[`/`]` in a token").
**Legibility-target:** for-author

In `[^][:space:]\\#\`()]` (`:456`), the only `[` is the opening of the `[:space:]` class, so a literal `[` is not excluded. In X2, `@c[x].md` yields `c[x`, not `c`. The token ends at `]`, not at `[`. The precise comment would be "( ) or ]" (the same wording stood in main's tree-walk comment and moved here). The practical effect is small: neither the lib (`c[x`) nor a `\s`-only rule (`c[x].md`) reads `c`. But a reader extending the end set from the comment would model the wrong regex.

**Evidence:** `scripts/lib/dev-cycle-read.sh:456`, `/tmp/u2a2f-fc3-YhOO/logs/probe.out`

---

## Claim 14d: "grep -a reads text holding a NUL."

**Location:** `scripts/lib/dev-cycle-read.sh:462-463`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers NUL bytes between tokens. It does not establish handling of a NUL inside a token: grep's bracket matches the NUL and bash's `read` drops it, so `@a.md\0x` is read as `a.mdx`. That is harmless, because a name holding a NUL cannot exist.
**Legibility-target:** for-orchestrator-synthesis

The command is `env LC_ALL=C grep -aoE "$IMPORT_RE"` (`:481`). In probe2:

- `x\0y @after.md` yields `after.md`.
- `@docs/a.md\0 then @docs/b.md` yields both names.
- `@a.md\0x then @n2.md\0 y` yields `a.mdx` and `n2.md`.
- Without `-a`, GNU grep 3.8 prints `grep: ../in2.txt: binary file matches` and no token.

X3 shows the same thing through the CLI. Main's walk printed `grep: docs/AGENTS.md: binary file matches` and passed `docs/n.md`. HEAD refuses it.

**Evidence:** `scripts/lib/dev-cycle-read.sh:481`, `/tmp/u2a2f-fc3-YhOO/logs/probe2.out`, `/tmp/u2a2f-fc3-YhOO/logs/corner.out`

---

## Claim 14e: "a token ending in . , ; : ! ? * _ or ~ yields both its whole and its stripped name"

**Location:** `scripts/lib/dev-cycle-read.sh:464-465`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers tokens that end in one or several marks. "Stripped" means every trailing mark removed, so `x.md.;!?` gives `x.md.;!?` and `x.md`, with no intermediate forms. A token that is all marks, or whose stripped name is dropped, yields only its whole name: `@...` gives `...`, and `@..;` gives `..;` because its stripped `..` leaves the repo.
**Legibility-target:** for-orchestrator-synthesis

The loop is `v="$t"; while [[ "$v" == *[.,\;:!?*_~] ]]; do v="${v%?}"; done` followed by `for t in "$t" "$v"; do ... printf '%s\n' "$p"; [[ "$v" != "$t" ]] || break; done` (`:472-479`). X2 results:

- `@a.md.` gives `a.md.` and `a.md`.
- `**@docs/x.md**` gives `docs/x.md**` and `docs/x.md`.
- `@x.md_` gives `x.md_` and `x.md`.
- `@a.md` gives only `a.md`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:468-482`, `/tmp/u2a2f-fc3-YhOO/logs/probe.out`

---

## Claim 14f: "~/ and absolute paths ... are dropped"

**Location:** `scripts/lib/dev-cycle-read.sh:466-467`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the drop rule. It does not establish whether Claude Code reads `@~x.md` as a relative name.
**Legibility-target:** for-author

The guard is `[[ -n "$t" && "$t" != "~"* && "$t" != /* ]] || continue` (`:473`). It drops every token that starts with `~`, not only `~/`. In X2, `@~x.md` yields nothing, the same as `@~/x.md` and `@/etc/x.md.`. The precise version would say "tokens starting with ~ or /". Main's walk had the same guard, so this does not change behaviour on this branch.

**Evidence:** `scripts/lib/dev-cycle-read.sh:473`, `/tmp/u2a2f-fc3-YhOO/logs/probe.out`

---

## Claim 14g: "paths leaving the repo (.. or ../, not a ..x name), are dropped"; "one repo-relative path per line, case kept"

**Location:** `scripts/lib/dev-cycle-read.sh:458-459`, `:467`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the leave-the-repo test after `realpath -ms`. A token that resolves to the root itself prints `.` (`@.`, and `@x/..` gives `.` and `x`), which is repo-relative but not a file. No caller asks about `.`.
**Legibility-target:** for-orchestrator-synthesis

The code is `p="$(realpath -ms --relative-to="$ROOT_REAL" -- "$ROOT_REAL/${1:+$1/}$t" 2>/dev/null)"` followed by `[[ "$p" != .. && "$p" != ../* ]] || continue` (`:474-475`). In X2, from `docs`, `@../CLAUDE.md @..x.md @../../out.md` gives `CLAUDE.md` and `docs/..x.md`, and `out` is dropped. `@../x.md.` gives nothing. Case is kept: the output is `CLAUDE.md`. The `dotdot` mutant, which restores main's `!= ..*`, fails test 1 (X4).

**Evidence:** `scripts/lib/dev-cycle-read.sh:474-476`, `/tmp/u2a2f-fc3-YhOO/logs/probe.out`, `/tmp/u2a2f-fc3-YhOO/logs/m-dotdot.log`

---

## Claim 14h: "Every import walk shares these rules, so a change here changes --check-fix too."

**Location:** `scripts/lib/dev-cycle-read.sh:459-460`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the one walk on this branch and U2a3's two calls. It does not cover any later walk.
**Legibility-target:** for-orchestrator-synthesis

On this branch the only caller is `done < <(import_targets "$d" < "$f")` in imported_names (`:506`). Its chain is imported_names, then isimported tree (`:519`), then check_fix (`scripts/dev-cycle.sh:181`). On `feat/build-loop-u2a3`, main_imports calls it at lines 577 and 583.

**Evidence:** `scripts/lib/dev-cycle-read.sh:506`, `:519`, `scripts/dev-cycle.sh:181`

---

## Claim 14i: "Claude Code keeps trailing punctuation (@x.md. reads x.md.)"; "Claude Code's token ends at JavaScript's \s"

**Location:** `scripts/lib/dev-cycle-read.sh:452`, `:463`
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers nothing about Claude Code itself in this replicate. The lib's own behaviour under this premise is Claims 13 and 14e.
**Legibility-target:** for-orchestrator-synthesis

Reading the bundled `claude.exe` (2.1.292) was denied by the permission classifier. The claim rests on the security reviewer's executed check of the regex `/(?:^|\s)@((?:[^\s\\]|\\ )+)/g` (paraphrased — no quote available because that execution lives in `docs/reviews/security-reviewer-review-2026-10-06-build-loop-u2a2.md` and `override-log.md:356`, not in code). To verify it, a reviewer allowed to read the Claude Code bundle, or to run Claude Code on a fixture, would be needed.

**Evidence:** `docs/reviews/override-log.md:356`

---

## Claim 15: instruction_names: "It matches INSTRUCTION_FILE's names; the walk's own test stays the authority. LC_ALL=C makes -i ASCII-only."

**Location:** `scripts/lib/dev-cycle-read.sh:483-487`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the name pattern against INSTRUCTION_FILE. It does not cover non-ASCII case folding beyond the C locale.
**Legibility-target:** for-orchestrator-synthesis

`grep -zaiE '(^|/)((claude|agents?|gemini)(\.[a-z0-9_-]+)?|skill)\.md$'` (`:487`) has the same shape as `INSTRUCTION_FILE='^(claude|agents?|gemini)(\.[abc...9_-]+)?\.md$|^skill\.md$'` (`:438`), and imported_names re-tests each name against it (`:496`). X5 keeps `CLAUDE.md`, `docs/agents.local.md`, `x/Skill.md`, `AGENT.md` and `gemini.v2.md`, and drops `claude.md.bak`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:438`, `:487`, `:496`, `/tmp/u2a2f-fc3-YhOO/logs/untr.out`

---

## Claim 16: untracked_md: "The checkout's untracked and ignored .md files, NUL-separated: --others without --exclude-standard already lists ignored files."

**Location:** `scripts/lib/dev-cycle-read.sh:488-490`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers top-level and nested names, any case of `.md`. It does not cover a checkout with `GIT_LITERAL_PATHSPECS`-style overrides beyond the one the function sets.
**Legibility-target:** for-orchestrator-synthesis

The function runs `GIT_LITERAL_PATHSPECS=0 git ls-files -z --others -- ':(glob,icase)**/*.md'` (`:490`). X5 lists the ignored `ign.md`, the ignored `sub/IGN2.MD` and the untracked `top.md`, and skips the tracked and `.txt` files. With `--exclude-standard` only `top.md` is listed.

**Evidence:** `scripts/lib/dev-cycle-read.sh:490`, `/tmp/u2a2f-fc3-YhOO/logs/untr.out`

---

## Claim 17: isimported: "Whether path $2 (any case) is imported, by the walk $1 names: tree (U2a3 adds main ...). A walk name it does not know answers imported (0), so a caller testing it with `if` refuses. Run it in the caller's shell: the walk exits through need_root and caches its result."

**Location:** `scripts/lib/dev-cycle-read.sh:509-513`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both arms, the lower-casing, the need_root exit and U2a3's main arm. It does not cover callers that run it in `$(...)`, and none does.
**Legibility-target:** for-orchestrator-synthesis

The function is `need_root; lp="$(lower "$2")"; case "$1" in tree) imported_names; [[ "$IMPORTED" == *$'\n'"$lp"$'\n'* ]] ;; *) return 0 ;; esac` (`:514-521`). IMPORTED holds `"$(lower "$p")"` (`:504`).

- The `nounknown` mutant (`*) return 1`) fails test 2 (X4).
- Test 1's `claude.md` lookup of `CLAUDE.md` passes.
- `feat/build-loop-u2a3` has `main) main_imports || return 0; ...` (its line 615).

**Evidence:** `scripts/lib/dev-cycle-read.sh:491-521`, `/tmp/u2a2f-fc3-YhOO/logs/m-nounknown.log`

---

## Claim 18: build-loop-check.bats header "the reader lib's import walks (... isimported, import_targets; main_imports from U2a3)" and imps' comment '"walk: ok" or "walk: failed" (main_imports' return; tree always reads ok)'

**Location:** `test/scripts/build-loop-check.bats:3-7`, `:14-16`
**Type:** Staleness / Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the helper against this branch. It does not cover U2a3's use of `imps main`.
**Legibility-target:** for-author

On this branch the `"walk: failed"` path is unreachable. The test runs `if [[ "$w" != main ]] || main_imports; then echo "walk: ok"` (`:21`), and no test passes `main`. main_imports does not exist here (grep finds no definition in `scripts/`). `imps main` would print `walk: failed` because the command is missing, not because a walk returned 1. The header marks main_imports "from U2a3", but imps' comment does not. Test 1 never asserts `walk: ok`.

**Evidence:** `test/scripts/build-loop-check.bats:14-24`

---

## Claim 19a: Test 1 name: "Unicode spaces end a token, punctuation is read kept and stripped, a ..x name is followed, ... a cycle ends"

**Location:** `test/scripts/build-loop-check.bats:27`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each named property through a mutant that breaks it. It covers U+00A0 and U+FEFF of the 19 spaces.
**Legibility-target:** for-orchestrator-synthesis

Test 1 fails under each mutant in X4: `feff` (U+FEFF), `nokept` (kept punctuation), `dotdot` (`..x`) and `noseen` (cycle; `timeout 60`). Negative checks guard against over-reading: `want docs/other.md -; want docs/nb.md. -` (`:38`).

**Evidence:** `test/scripts/build-loop-check.bats:27-39`, `/tmp/u2a2f-fc3-YhOO/logs/mut.out`

---

## Claim 19b: Test 1 name: "a NUL hides no import"

**Location:** `test/scripts/build-loop-check.bats:27`, `:29`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which assertion carries the NUL property. It does not judge test priority.
**Legibility-target:** for-author

The fixture puts `@docs/a.md\0 then @docs/b.md` on CLAUDE.md's line (`:29`). But `docs/c.md` also imports `@b.md` (`:31`), so `docs/b.md: imported` holds even if the import after the NUL is lost. In the `nulfix` mutant the fixture is changed to `then docs/b.md`, with no `@`, and test 1 still passes 2/2 (X4). Reading a NUL-holding file at all is protected: the `noa` mutant (no `-a`) fails, because every CLAUDE.md token is lost. Only the narrower "an import after a NUL on the same line" goes unasserted. The precise test would remove `@b.md` from `docs/c.md` or assert a name that only the post-NUL token imports.

**Evidence:** `test/scripts/build-loop-check.bats:28-38`, `/tmp/u2a2f-fc3-YhOO/logs/m-nulfix.log`, `/tmp/u2a2f-fc3-YhOO/logs/m-noa.log`

---

## Claim 20: Test 2 name: "isimported answers imported under if for a walk name it does not know"

**Location:** `test/scripts/build-loop-check.bats:41-45`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the unknown-word arm under `if`. It does not cover a call outside `if`.
**Legibility-target:** for-orchestrator-synthesis

The test runs `if isimported bogus docs/z.md; then echo "bogus: imported"; fi` and checks `[ "$output" = "bogus: imported" ]`. The `nounknown` mutant fails it, so the assertion is not vacuous.

**Evidence:** `test/scripts/build-loop-check.bats:41-45`, `/tmp/u2a2f-fc3-YhOO/logs/m-nounknown.log`

---

## Claim 21: dev-cycle.bats: the sourced-lib inventory names the five new functions and UNI_SPACES; entry_why's test adds the one-argument call (C13)

**Location:** `test/scripts/dev-cycle.bats:1086-1089`, `:1339-1356`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers presence and the passing run. The inventory checks only that each name is defined, not what it does.
**Legibility-target:** for-orchestrator-synthesis

The inventory adds `isimported inrepo_here import_targets instruction_names untracked_md` and `UNI_SPACES`. The entry_why test adds `entry_why error` with the expected subjectless line. Both pass in X1.

**Evidence:** `test/scripts/dev-cycle.bats:1083-1090`, `:1337-1357`, `/tmp/u2a2f-fc3-YhOO/logs/tests.log`

---

## Claim 22: fixture-git-env.bats: "This suite's own fixture must stay out of an inherited GIT_DIR too"; "The inner runs name the victim's index too: it must come out byte for byte."; the inner dev-cycle test stages (C12)

**Location:** `test/scripts/fixture-git-env.bats:11-19`, `:27`, `:32`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the unset, the index check and the inner test choice. It does not cover the five row-327 suites (settled, Defer).
**Legibility-target:** for-orchestrator-synthesis

Setup runs `unset $(git rev-parse --local-env-vars)` before `git init` (`:13`) and copies the index with `cp "$V/.git/index" "$BATS_TEST_TMPDIR/index.before"` (`:19`). victim_unchanged then runs `cmp -s` (`:27`). The inner test `--check-answer needs a default branch found by name` runs `git add -A && git commit` (`test/scripts/dev-cycle.bats:1209`) and is the only test matching the filter, since victim_unchanged requires `1..1`. In X6, with dev-cycle.bats unsetting only `GIT_DIR`, the suite fails at line 27, the index `cmp`. The index check is therefore not vacuous.

**Evidence:** `test/scripts/fixture-git-env.bats:9-33`, `test/scripts/dev-cycle.bats:1207-1212`, `/tmp/u2a2f-fc3-YhOO/logs/m-idx.log`

---

## Claim 23: Commit 39ed1d53: C12/C13 patches "applied ... as written"; C14's plan edits; "C16 (pin_hermetic_git) stays carried: its trigger is an edit of one of row 327's suites, and none is edited here"; "Tests: 105 across dev-cycle, build-loop-read, build-loop-check, fixture-git-env and hermeticity"

**Location:** commit `39ed1d53` message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count at 39ed1d53, row 327's suite list against the branch's edited files, and the patches' described content. It does not diff the Appendix patch byte for byte.
**Legibility-target:** for-orchestrator-synthesis

- X7 at 39ed1d53 prints `1..105` with 105 `ok`.
- Row 327 names test/merge-safety.bats, test/cc-push.bats, test/scripts/archive-working-docs.bats, test/si-clean-state.bats and test/cc-isolated-functions.bats (`docs/reviews/override-log.md:327`). None of them is in `git diff --name-only main...HEAD`.
- The Appendix's described changes (the `unset` before `git init`, the index `cp`/`cmp`, the inner filter `check-answer needs a default branch found by name`; `docs/reviews/test-strategy-review-2026-10-06-i3-build-loop-u2a1.md:51-66`) all match the fixture-git-env.bats diff.

**Evidence:** `/tmp/u2a2f-fc3-YhOO/logs/at39.log`, `docs/reviews/override-log.md:327`, `:335`

---

## Claim 24a: Commit bff4ded2: the split contents, the fixes kept (B1, B13, B9, B10, B5 tree half, B7), "build-loop-check.bats 2", "mutants of U+FEFF, the kept name and the tree walk's seen check each fail", "100 across the five suites", "166 changed code lines against main"; "known issue A5 and plan F11 move to U2a3"

**Location:** commit `bff4ded2` message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each count and mutant at HEAD. The line count at HEAD equals the count at bff4ded2, because 7697c6e6 touches only `docs/`.
**Legibility-target:** for-orchestrator-synthesis

- **Tests:** `grep -c '^@test' test/scripts/build-loop-check.bats` gives 2, and X1 gives 100.
- **Lines:** `git diff --numstat main...HEAD -- ':(top)' ':(top,exclude)docs/'` gives 1+2, 71+29, 45+0, 6+4 and 7+1, which sum to 166.
- **Mutants:** in X4, `feff`, `nokept` and `noseen` each fail test 1.
- **Moves:** the known-issues file has no diff against main, and F11 at bff4ded2 equals main's.

**Evidence:** `/tmp/u2a2f-fc3-YhOO/logs/tests.log`, `/tmp/u2a2f-fc3-YhOO/logs/mut.out`

---

## Claim 24b: Commit bff4ded2 Notes: "emitting a punctuation-ended token's whole name makes --check-fix refuse slightly more (never less)" (shared3.md: "Changes to --check-fix are only toward refusing more")

**Location:** commit `bff4ded2` message (Notes)
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the branch's net token-rule change through the CLI. Per the Unicode-space regex evidence at override-log.md:356, the refusal lost is one Claude Code would not apply either. The Notes sentence attributes the change only to the whole-name emission and is accurate for that part alone.
**Legibility-target:** for-orchestrator-synthesis

The Unicode-space cut shortens tokens that main read whole, so main's walk could reach a file that HEAD's cannot. In X3, AGENTS.md holds `see @docs/w\xc2\xa0x.md`, that file holds `deep @t.md`, and `docs/t.md` exists. Main's `dev-cycle.sh --check-fix docs/t.md` prints `skip docs/t.md: an instruction file imports it with @ ...`. HEAD prints `ok docs/t.md`. U+FEFF works the same way.

The same run shows the refusing direction for the other changes: `docs/viaq.md` (via `..q.md`), `docs/f.md` (U+FEFF) and `docs/n.md` (after a NUL) go from `ok` to `skip`. The precise version would be: "--check-fix refuses more, except files reachable only through an import name that holds a Unicode space, which Claude Code would not follow".

**Evidence:** `/tmp/u2a2f-fc3-YhOO/logs/corner.out`, `/tmp/u2a2f-fc3-YhOO/logs/corner.sh`

---

## Claim 24c: Commit bff4ded2: "B13's evidence recorded on the settled token-form row"

**Location:** commit `bff4ded2` message
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers where the evidence lives. It does not cover the evidence itself (Claim 14i).
**Legibility-target:** for-author

The evidence is a new row that cites the settled one: `Executed evidence on the \`feat/build-loop-u2a\` row "backslash or trailing-\`_\` token form"` (`docs/reviews/override-log.md:356`). The settled row (`:350`) is unchanged, as an append-only log requires. The precise wording would be "recorded in a new row against the settled token-form row".

**Evidence:** `docs/reviews/override-log.md:350`, `:356`

---

## Claim 25: Commit 7697c6e6: "F11 names U2a3's main_imports as the floor's walk"

**Location:** commit `7697c6e6` message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the F11 text only.
**Legibility-target:** for-orchestrator-synthesis

F11 now reads `Floor item 1 walks main's commit with \`main_imports\` (U2a3, stacked on U2a2's shared token parser)` (`docs/working/plan-build-loop-handoff.md:126`).

**Evidence:** `docs/working/plan-build-loop-handoff.md:126`

---

## Claim 26: Plan U2a3/U2a4 bullets: U2a3 "carries U2a2 iteration 2's rows B2-B6, B8, B10-B12, B14"; U2a4 is "the floor in the lib ... over U2a3's walk"

**Location:** `docs/working/plan-build-loop-handoff.md:276-277`
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the B-row list against the rubric's Unit column, which matches. U2a3's modelling list and U2a4's content are future units outside this scope.
**Legibility-target:** for-orchestrator-synthesis

The rubric's Unit column marks B2, B3, B4, B6, B8, B11, B12 and B14 as "U2a3", and B5 and B10 as split between U2a2 and U2a3 (`code-review-rubric-2026-10-06-feat-build-loop-u2a2.md:18-31`). The bullet's list matches that column. Whether U2a3 models what the bullet lists ("a doubled name, ... a checkout symlink it would read") belongs to U2a3's review. U2a4 does not exist yet.

**Evidence:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a2.md:16-31`

---

## Claims Requiring Attention

### Incorrect
- **Claim 14c** (`scripts/lib/dev-cycle-read.sh:462`): `[` does not end a token, because IMPORT_RE's bracket excludes `]` but not `[` (`@c[x].md` reads `c[x`). Change the comment to "( ) or ]".
- **Claim 24b** (commit bff4ded2 Notes; shared3.md's PR summary): the claim that --check-fix refuses "never less" fails when a file is reachable only through an import name holding a Unicode space. Main skips `docs/t.md` and HEAD prints `ok` (executed). Claude Code would not follow that import either. This is a commit message, so the fix would be an Accepted-immutable row.

### Mostly Accurate
- **Claim 1b** (rubric B10): fixed beside inrepo_here, not in the header the finding named.
- **Claim 7** (`docs/working/questions.md:392-393`): the update names U2a3 as the unit [3] replaces, while :393 still says "[3] replaces U2a2's walk".
- **Claim 14f** (`scripts/lib/dev-cycle-read.sh:466`): every `~`-leading token is dropped, not only `~/`.
- **Claim 18** (`test/scripts/build-loop-check.bats:14-16`): imps' main_imports path does not exist on this branch.
- **Claim 19b** (`test/scripts/build-loop-check.bats:27-31`): the import after the NUL on the same line is also reached via `docs/c.md`, so "a NUL hides no import" is not asserted for it (`nulfix` mutant passes).
- **Claim 24c** (commit bff4ded2): the evidence is a new row, not an edit of the settled row.

### Unverifiable
- **Claim 14i** (`scripts/lib/dev-cycle-read.sh:452`, `:463`): Claude Code's real token rule. Verifying it needs a reader of the claude.exe bundle (denied here) or a live Claude Code run on a fixture.
- **Claim 26** (`docs/working/plan-build-loop-handoff.md:276-277`): U2a3's and U2a4's content is future work. Only the B-row list was checked, and it matches.

## Escalations

- **E1 (Claim 24b, doc accuracy, Low).** shared3.md's "Changes to --check-fix are only toward refusing more" and bff4ded2's "never less" are refuted by execution in one corner: a file reachable only through an import name holding a Unicode space or U+FEFF. That refusal matched no Claude Code import, given the settled `\s` evidence, so no safety property is lost. But a synthesis that repeats "only refusing more" would be inaccurate.
- **E2 (Claim 14c, Low).** The token-end comment misstates the regex for `[`. B14 already routes Claude Code's own `[`/`]` handling to U2a3. This finding is only about the lib's comment and is not a re-filing of B14.
- **E3 (test strength, Low).** Claim 19b's NUL assertion is redundant with `docs/c.md`'s `@b.md`. Reading a NUL-holding file is still protected through the `noa` mutant.
- **E4 (blocker).** The permission classifier denied reading Claude Code's bundled import code. Claims about Claude Code's rule (14i, and the "as Claude Code does" in 12) stay Unverifiable in this replicate.
- **E5.** The hallucination-pattern log was not updated. Neither Incorrect verdict is a fabricated symbol, and shared3.md forbids repo writes beyond this report.

## Goal-Alignment Note

- **Success criterion (verbatim):** "a markdown report saved at the path given in your tail, structured per your skill, with `Commit: 7697c6e6` as its first line."
- **Answered:** yes. The report is saved at `docs/reviews/code-fact-check-report-build-loop-u2a2-f-r2.md` with `Commit: 7697c6e6` on line 1. All nine brief items are covered:
  1. import_targets' comment: Claims 14a-14i.
  2. UNI_SPACES: Claim 13 (all 19 code points, executed against node's `\s`).
  3. The other comments: Claims 9, 10, 12, 15, 16.
  4. isimported: Claim 17.
  5. check_fix: Claims 8 and 24b.
  6. entry_why: Claim 11.
  7. Commit messages: Claims 23-25.
  8. Tests: Claims 18-22 (four non-vacuity mutants plus X6).
  9. Docs: Claims 1-7 and 26.
- **Out of scope:** U2a3's main_imports and its B rows. Code-quality judgments. Re-filing the settled 2026-10-06 rows: the `[`/`]` Claude Code question stays B14's.
- **Escalate:** E1-E3 are Low. None blocks, and none is a behavioural defect in check_fix's refusals relative to Claude Code's settled rule.
- **Decisions:** Claim 24b is verdicted Incorrect rather than Mostly accurate, because "never less" is a stated conclusion that execution refutes, even though the lost refusal is not a real import.
