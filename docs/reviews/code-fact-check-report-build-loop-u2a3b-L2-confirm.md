Commit: 4828727d

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u2a3b (branch feat/build-loop-u2a3b)
**Scope:** `git diff main...4828727d -- . ':!docs/reviews'` (scripts/lib/dev-cycle-read.sh, scripts/dev-cycle.sh, skills/dev-cycle/SKILL.md, test/scripts/build-loop-check.bats, test/scripts/dev-cycle.bats, docs/working/known-issues-dev-cycle.md, docs/working/plan-build-loop-handoff.md) and the commit messages `main..4828727d`, weighted to aa379ee9 (every comment, test comment/title and commit sentence it added or changed) and 4828727d. U2a3b loop 2, confirming pass over the L2-final fixes: merged canonical report of replicates r1, r2 and r3.
**Checked:** 2026-10-07
**Total claims checked:** 37
**Summary:** 30 verified, 6 mostly accurate, 0 stale, 1 incorrect, 0 unverifiable
**Commit:** 4828727d
**Replication:** k=3

Merge provenance. This report collates `docs/reviews/code-fact-check-report-build-loop-u2a3b-L2-confirm-r1.md` (38 claims), `-r2.md` (31 claims) and `-r3.md` (37 claims), all at `Commit: 4828727d`, per `skills/code-review/SKILL.md` "Merging replicate verdicts (most-severe-wins)". Nothing here is new evidence: each cluster carries the winning replicate's evidence, and every other replicate's caveats sit in `**Replicate annotations:**`. Where one replicate split a sentence and another verdicted it as a whole, the merged report emits the finer rows and records the compound verdict on each row marked `(compound)`. Where a replicate reported two rows on one claim (for example a lib comment and its mirror in a known-issues row), they are one cluster.

Execution provenance. All three replicates ran the five suites at 4828727d (dev-cycle 78, build-loop-check 48, build-loop-read 19, fixture-git-env 2, fixture-hermeticity 2): **149/149 ok**, exit 0. r2 ran the two large suites itself (126 ok) and the other three separately. Log abbreviations used below, each the reporting replicate's own: **X1/** = `/tmp/u2a3bfcc1-5a3b/x/` (r1; suites `bats.log`, probes and mutants beside it); **X2/** = `/tmp/claude-1000/u2a3bfcc2-HXxN/` (r2; `bats.log`, `herm.log`, `probe1..11.log`); **SP/** = `/tmp/claude-1000/-workspace/d85c9919-8193-4546-8b61-a9f00fc88d03/scratchpad/` (r3; `u2a3bfcc3-suites.txt`, `-cc-probe.txt`, `-mut.txt`, `-timing.txt`, `-home.txt`, `-py.txt`, `-cf.txt`, `-node.txt`). All three ran Claude Code 2.1.292 headless with a throwaway HOME and CLAUDE_CONFIG_DIR and no network, and none left a process running. The hallucination log was read by all three; its test-count pattern was checked against aa379ee9's "149/149" and does not recur (Claim 35).

## Claims Requiring Attention

### Incorrect
- **Claim 29** (`test/scripts/build-loop-check.bats:683-684`): the title and comment say the main walk "skips" a nested `.git` directory. Since aa379ee9 only the top-level `.git` is skipped. A nested directory passes the plain-directory check and is recorded as imported, as the lib's own comment (`scripts/lib/dev-cycle-read.sh:773-775`) says. The test's assertions pass (r2 Incorrect, r3 Mostly accurate, r1 Verified). Reword to "passes".

### Stale
- None.

### Mostly Accurate
- **Claim 4** (`docs/working/plan-build-loop-handoff.md:279`): "a parent of every worktree here" holds for the container's worktrees. `git worktree list` also registers the host path `/home/magfrump/cw-egress-verify` (prunable here), and the host checkout this bullet adds need not nest (r2, r3).
- **Claim 9** (`scripts/lib/dev-cycle-read.sh:480-483`): the sentence says both caches are keyed without HOME but tells a HOME-changing caller to clear only `IMPORTED_MAIN_DONE`. `IMPORTED_DONE` needs clearing too, which r3 showed by execution (r1, r3; r2 Verified).
- **Claim 19** (`scripts/lib/dev-cycle-read.sh:633-634`): "13 in all" adds r1's 8 and r3's 5 L2-final probes, which overlap (at most 8 distinct shapes). The cited "U2a3b L2 security F1" compared python3 with Node, not the binary (all three).
- **Claim 31** (`test/scripts/build-loop-check.bats:736-738`): "over 150 characters" is about 135 under bats' default TMPDIR. The bound still trips. The "22 s" belongs to the 4 MiB file, not this input (all three).
- **Claim 32** (commit aa379ee9): this verdict is r1's compound verdict on the "4 MiB ... and 200k distinct" sentence. r1's text says the 4 MiB half "matches this claim's shape", and the fault is in Claim 33 (r1 compound; r2 and r3 Verified).
- **Claim 33** (commit aa379ee9): "200k distinct names ... fail in 1.8 s" is evidence of the print budget, which already stopped that input at e1654266, not of the new charge (r1, r3; r2 Verified on the outcome).

### Unverifiable
- None.

---

## Claim 1: Known issue A3: "Imports through a symlinked file or directory print `ok`. ... (Absolute-path imports into the repo are refused since U2a3b.)"

**Location:** `docs/working/known-issues-dev-cycle.md:17`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers an absolute import spelled under ROOT_REAL being yielded by the parser, so `--check-fix` refuses it; does not establish the symlinked-file and symlinked-directory halves (not re-probed), and does not cover an absolute name spelled through a symlinked alias of the root, which the parser drops (Claude Code 2.1.292 also refuses that spelling, so it is not a miss).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "does not re-trace the symlinked-directory regression"; the tree walk queues only `inrepo_here` paths (`inrepo_here() { [[ -z "$(blocker "$1" file)" && -f "$1" ]]; }`, `scripts/lib/dev-cycle-read.sh:131`), so a symlinked file's own imports are not followed · r3: "does not cover absolute names into another checkout (U2b)"; the suite tests `bats:503` and `dev-cycle.bats:1016` pass · This parenthetical is the fix for the L2-final Stale row on A3.

The parser keeps an absolute name below ROOT_REAL:

```awk
# scripts/lib/dev-cycle-read.sh:558, :571 (excerpt ends :571; enclosing put() continues to :577 — read)
  if (substr(c, 1, 1) != "/") c = root "/" dir "/" c
  if (index(out, pre) != 1 || length(out) <= length(pre)) return
```

Executed (`bash x/alias.sh <lib> <alias>`, cwd `/tmp/u2a3bfcc1-5a3b/x/hrepo`, exit 0, 2026-10-07T15:50Z): input `@<ROOT_REAL>/docs/real.md and @<alias>/docs/alias.md` printed `docs/real.md` only, rc=0. Claude Code control: an `@` through the alias logged no import, while the real-path spelling logged `skipping /tmp/u2a3bfcc1-cc-F564/proj/docs/d3`; the binary's `iH` rejects a non-canonical symlinked path (paraphrased — no quote available because the helper names are minified and were resolved only by reading `iH(e,n){if(!n.isSymlink||n.isCanonical)return!1;...}` in the extracted strings).

**Evidence:** `scripts/lib/dev-cycle-read.sh:131`, `scripts/lib/dev-cycle-read.sh:557-577`, `test/scripts/build-loop-check.bats:503`, X1/alias-out.txt, X1/cc-alias-probe.txt, X1/cc-alias-control.txt, X2/bats.log, SP/u2a3bfcc3-suites.txt

---

## Claim 2: A5: "Not covered by either walk (...pre-existing on main): instruction files outside the repo that a session loads, a parent directory's CLAUDE.md and the user's memory file, whose imports reach files in the repo; routed to U2b's reader model." / lib: "Neither walk starts at an instruction file outside the repo, though Claude Code loads them and follows their imports into it"

**Location:** `docs/working/known-issues-dev-cycle.md:18` (A5, last sentence); `scripts/lib/dev-cycle-read.sh:484-486`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that Claude Code 2.1.292 follows imports from a parent directory's CLAUDE.md and from the user memory file into the project, and that neither walk lists a start outside the repo; does not cover managed-policy memory, `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD` or `--add-dir` directories (named in the binary's load list), nor which memory file a loop under its own CLAUDE_CONFIG_DIR loads.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r3: "does not cover managed-policy memory, or which memory file a loop under its own CLAUDE_CONFIG_DIR loads (both are named in U2b's bullet and were not probed)" · r2: "does not cover managed-policy files or `--add-dir` directories" · This text is the fix for the L2-final Mostly accurate row (A5's "Not covered" list omitted out-of-repo instruction files).

Probe (`bash x/ccprobe4.sh outside /tmp/u2a3bfcc1-cc-F564`, cwd `/tmp/u2a3bfcc1-cc-F564/proj`, timeout exit 124 as designed, 2026-10-07T15:52:35Z): a parent `CLAUDE.md` holding `@proj/docs/d4` and a user memory file holding `@/tmp/u2a3bfcc1-cc-F564/proj/docs/d5` logged `skipping /tmp/u2a3bfcc1-cc-F564/proj/docs/d5` and `.../proj/docs/d4`. r2 and r3 reproduced it with their own scratch trees (`skipping .../proj/docs/fromuser`, `.../fromparent`; `.../proj/dir4`, `.../dir3`). The binary's load list walks every ancestor: `..._n(Ee()).flatMap((m)=>[...u(m),...l(m)])` with `function _n(e){let n=[];for(let r=e;r!==yn(r).root;r=hn(r))n.unshift(r);return n}` (claude.exe strings). The walks start only from repo listings:

```bash
# scripts/lib/dev-cycle-read.sh:661 (a single line)
tree_starts() { local -; set -o pipefail; { git ls-files -z && untracked_md; } | instruction_names; }
```

main_imports starts from `git ls-tree -r -z --full-tree "$MAIN_SHA"` and `git ls-files ... --cached --others` (`:715`, `:724`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:661`, `:715`, `:724`, X1/cc-outside-probe.txt, X1/strings.txt, X2/probe10.log, SP/u2a3bfcc3-cc-probe.txt (tag `parent`)

---

## Claim 3: F11 gaps "... and one shape untraced against Claude Code, and instruction files outside the repo"; "The walks share one name parser but not one start rule"; lib: "and the one shape A5 lists as untraced against Claude Code."

**Location:** `docs/working/plan-build-loop-handoff.md:126`; `scripts/lib/dev-cycle-read.sh:475-479`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement of "one shape" with A5's single untraced item, and that both walks call `import_targets` with different start rules; does not trace the untraced shape (`.claude/commands/`) itself.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none · This is the fix for the L2-final Stale rows on F11 and on the lib comment ("three shapes").

A5 names exactly one untraced item: "Untraced (no host probe yet): whether `@` references in `.claude/commands/` files load." (`docs/working/known-issues-dev-cycle.md:18`). Both walks call the parser (`import_targets "$d"` at `scripts/lib/dev-cycle-read.sh:683` and `:742`); only main_imports also starts at `.claude/rules/` (`"$f" == .claude/rules/*.md || "$f" == */.claude/rules/*.md`, `:731`), while the tree walk admits `[[ ! "$lp" =~ $INSTRUCTION_FILE ]] ... continue` (`:672`).

**Evidence:** `docs/working/known-issues-dev-cycle.md:18`, `scripts/lib/dev-cycle-read.sh:478-479`, `:672`, `:683`, `:731`, `:742`, `docs/working/plan-build-loop-handoff.md:126`

---

## Claim 4: U2b: "The main checkout's working tree is a parent of every worktree here, so its instruction files load as parent memory" / "project a name under the longest matching root, since worktrees nest inside the main checkout"

**Location:** `docs/working/plan-build-loop-handoff.md:279`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the paths `git worktree list` registers today; does not establish that /workspace holds a CLAUDE.md (it holds AGENTS.md, which Claude Code also loads), what a host session loads, or whether the stale entry matters for U2b.
**Severity:** Low
**Legibility-target:** for-author
**Replicate verdicts:** r1=— · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r2 (Confidence Medium): the host checkout `~/claude-workflows` this bullet adds has worktrees that are siblings, not children · r3: `/workspace/CLAUDE.md` does not exist and `/workspace/AGENTS.md` does (`vbt=[["CLAUDE.md"],["CLAUDE.local.md"],["AGENTS.md"],…]` in the bundle)

Fifteen of the sixteen registered worktrees lie under `/workspace`. One does not: `/home/magfrump/cw-egress-verify  b26d4b8b (detached HEAD) prunable`. It is prunable here because the path is missing inside the container, so it is a host-side worktree, which is the Q-121 case this bullet now names (`git worktree list`, run 2026-10-07T15:40-15:46Z, output transcribed in r2 and r3). The precise version is "every worktree inside the container (a host-registered one, such as /home/magfrump/cw-egress-verify, is the Q-121 case)".

**Evidence:** `docs/working/plan-build-loop-handoff.md:279`, `git -C /workspace/.claude/wt-build-loop-u2a3b worktree list` (exit 0)

---

## Claim 5: U2b: "The reader set includes the host: sessions normally run in cc-isolated, but when the image breaks the user runs one on the host in `~/claude-workflows` under the host HOME (Q-121, answered 2026-10-07)"; commit 4828727d: "Q-120 [1] goes in the rubric's iteration-4 gate section. Q-121's answer ... joins U2b's reader-model bullet ... Notes: docs only"

**Location:** `docs/working/plan-build-loop-handoff.md:279`; commit 4828727d message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that Q-121 exists and is answered 2026-10-07 as the bullet says, that Q-120 [1] is recorded in the rubric's gate section, and that 4828727d touches only the rubric and the plan; does not verify the host's actual configuration or evaluate the reader model.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

main's archive records "**Answered 2026-10-07: yes, occasionally.** Sessions normally run in cc-isolated (`/workspace` and its worktrees), but when the container image breaks the user runs one on the host directly in `~/claude-workflows` (the host HOME)" (`docs/working/questions-archive.md:2059-2063` on main). The rubric's iteration-4 gate section holds "**Answered 2026-10-07 (Q-120 [1]):** one more confirming pass under a size waiver". `git show --stat 4828727d` lists the rubric (+2) and `docs/working/plan-build-loop-handoff.md` (1 line) only.

**Evidence:** `main:docs/working/questions-archive.md:2059-2063`, `docs/working/plan-build-loop-handoff.md:279`, `git diff aa379ee9 4828727d`

---

## Claim 6: `--check-fix` help and SKILL.md: "a file an instruction file names after an @, read broadly; ... "skip <path>: <reason>" otherwise, and for every path when the import walk fails" / "refuses every path when the import walk fails"

**Location:** `scripts/dev-cycle.sh:54-55`; `skills/dev-cycle/SKILL.md:75-76`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers check_fix's arm order (every path reaching the walk arm is skipped when the walk fails; earlier arms skip for their own reasons); does not cover callers other than `--check-fix`, `--check-path` or `--check-write`.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=—
**Replicate annotations:** r3: `scripts/dev-cycle.sh`, `skills/dev-cycle/SKILL.md` and `test/scripts/dev-cycle.bats` were not changed by aa379ee9 and were not re-harvested

```bash
# scripts/dev-cycle.sh:181-185 (excerpt ends :185; enclosing check_fix() ends :186 — read)
  elif ! imported_names; then
    echo "skip $a: the instruction-file import walk failed, so an import of it cannot be ruled out; file it instead"
  elif isimported tree "$lp"; then
    echo "skip $a: an instruction file names it after an @ ..."
  else check_path "$a"; fi
```

No arm before `:181` prints `ok`. The suite test "--check-fix words a failed import walk as one and refuses (U2a3b)" (corrupt index) passed in the 149-test run.

**Evidence:** `scripts/dev-cycle.sh:170-186`, `skills/dev-cycle/SKILL.md:75-76`, X1/bats.log, X2/bats.log

---

## Claim 7: lib header: "The import walks also need python3 when a file they read holds text that is not well-formed UTF-8; without it they fail closed (every path is refused)." (and the test comment "both walks read well-formed UTF-8 without python3, which only text holding an invalid sequence needs", `bats:714`)

**Location:** `scripts/lib/dev-cycle-read.sh:12-13`; `test/scripts/build-loop-check.bats:714`
**Type:** Configuration / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the fork condition (python3 runs only when a byte above 0x7f is present and the text fails `UTF8_WELL_FORMED`) and the failure path through both walks to `isimported` (answers imported) and check_fix (walk-failed skip), for an imported non-instruction file as well; does not cover a python3 that succeeds with wrong output, or Bun's decoder (Claim 19).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r3: the probe made `docs/a.md` (imported, not a start) hold `bad \xff @docs/b.md` with a python3 shim that exits 1; the output was `tree failed`, `main failed`, `tree other: imported`, `main other: imported` (SP/u2a3bfcc3-py.txt) · This wording ("a file they read") is the fix for the L2-final Mostly accurate row ("an instruction file").

```bash
# scripts/dev-cycle-read.sh:636-637 (condensed to the gate and the failure arm)
if [[ "$toks" == *[$'\x80'-$'\xff']* ]] && ! printf '%s\n' "$toks" | env LC_ALL=C awk -v ok="$UTF8_WELL_FORMED" '$0 !~ ok { exit 1 }'; then
  d="$(... python3 -I -c '...decode("utf-8", "replace")...')" || return 1
```

Both walks turn a parser failure into `IMPORTED=error; return 1` (`:683`, `:742`), and `isimported` answers imported: `main) main_imports || return 0;` / `tree) imported_names || return 0;` (`:796-797`). Suite tests `bats:582` (failing python3 shim on an invalid byte: both walks fail) and `bats:714` (failing shim, well-formed UTF-8: both walks succeed) passed.

**Evidence:** `scripts/lib/dev-cycle-read.sh:624-647`, `:683`, `:742`, `:791-800`, `scripts/dev-cycle.sh:181-182`, `test/scripts/build-loop-check.bats:582-595`, `:714-722`, X1/bats.log, X2/bats.log, SP/u2a3bfcc3-py.txt

---

## Claim 8: imported_names: "It returns 1, with IMPORTED set to "error", when the start listing ..., lower, a file read, import_home or the parser (its comment lists why) fails, the IMPORT_OUT_MAX budget is spent, or a start file's name holds a newline"

**Location:** `scripts/lib/dev-cycle-read.sh:453-456`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each listed arm and the arms aa379ee9 added (import_home, the parser, the budget) against `imported_names` read from signature to final line (`:662-693`); does not establish that no unlisted command can fail silently (inrepo_here's failure skips its path, as the comment states), or callers' handling.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: the `import_home || return 1` at `:676` returns without resetting IMPORTED, which is already `error` from `:666`, so the stated "IMPORTED set to error" holds · This list is the fix for the L2-final Mostly accurate row (import_home and the budget arm were missing).

Arms: `nul_list recs tree_starts || return 1` (`:667`); `[[ "$f" != *$'\n'* ]] || return 1` (`:670`); `lp="$(lower "${f##*/}")" || return 1` (`:671`); `import_home || return 1` (`:676`); `out="$(head -c 4194305 -- "$f" | IMPORT_LEFT=... import_targets "$d")" || { IMPORTED=error; return 1; }` (`:683`, `head` covered by the function's `set -o pipefail` at `:663`); `(( (used += ${#out}) <= IMPORT_OUT_MAX )) || { IMPORTED=error; return 1; }` (`:685`); `lp="$(lower "$out")" || { IMPORTED=error; return 1; }` (`:687`). `IMPORTED_DONE="$ROOT_REAL"; IMPORTED=error` (`:666`) precedes every early return.

**Evidence:** `scripts/lib/dev-cycle-read.sh:662-693`

---

## Claim 9: "... so a caller whose checkout changes between calls sets IMPORTED_MAIN_DONE="" to walk again, and so does a caller that changes HOME (both caches are keyed without it)."

**Location:** `scripts/lib/dev-cycle-read.sh:480-483`
**Type:** Behavioral / Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both cache keys and what a HOME change needs; does not establish that any current caller changes HOME (none was found), or import_home's own cache (keyed on HOME, recomputes correctly).
**Severity:** Low
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Verified · r3=Mostly accurate
**Replicate annotations:** r2 (Verified, static): neither key holds HOME, "so only the walk caches go stale"; "does not establish that any caller in scripts/ changes HOME" · r1: the precise form is already used by the IMPORT_OUT_MAX comment at `:493-494` ("A caller that changes it clears IMPORTED_DONE and IMPORTED_MAIN_DONE") · r3: the rubric's L2-F-C11 "Fixed" holds only through the parenthesis

The parenthesis is right: `[[ "$IMPORTED_DONE" == "$ROOT_REAL" ]] && ...` (`:665`) and `[[ "$IMPORTED_MAIN_DONE" == "$MAIN_SHA $MAIN_BY_NAME $ROOT_REAL" ]] && ...` (`:712`). Neither key holds HOME. The instruction names only `IMPORTED_MAIN_DONE`, though, and the tree cache needs `IMPORTED_DONE=""` too. Executed (r3): `imported_names` with HOME=h1 gave `docs/h.md` imported via `@~/repo2/docs/h.md`; after setting HOME=h2 it printed `HOME=h2 (cached): imported`, and only after `IMPORTED_DONE=""` did it print `HOME=h2 (cleared): -`. The precise version is "a caller that changes HOME clears IMPORTED_DONE and IMPORTED_MAIN_DONE (both caches are keyed without it)".

**Evidence:** `scripts/lib/dev-cycle-read.sh:480-483`, `:493-494`, `:665`, `:712`, SP/u2a3bfcc3-py.txt

---

## Claim 10: IMPORT_OUT_MAX: "A fresh clone's walks print about 2 KB, /workspace's about 6 KB."

**Location:** `scripts/lib/dev-cycle-read.sh:492-493`
**Type:** Performance / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a clone at 4828727d (both walks) and the /workspace checkout's tree walk; does not cover main_imports in /workspace, which fails there (ignored instruction files, as A5 documents).
**Replicate verdicts:** r1=Verified · r2=— · r3=— · single-replicate detection
**Replicate annotations:** none

`bash x/walksize.sh <branch lib>` (exit 0, 2026-10-07T15:49Z): in `/tmp/u2a3bfcc1-5a3b/x/clone` (4828727d) `tree ok 2020`, `main ok 2020`; in `/workspace` (read-only) `tree ok 5607`, `main failed`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:489-495`, X1/walksize-out.txt

---

## Claim 11: import_targets: "It also reads ROOT_REAL, HOME (through import_home) and IMPORT_LEFT (what may still be printed; IMPORT_OUT_MAX when unset)."

**Location:** `scripts/lib/dev-cycle-read.sh:504-506`
**Type:** Architectural / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the three named inputs; does not claim the list is exhaustive (it also reads PATH's python3, UNI_SPACES, UTF8_WELL_FORMED, and writes import_home's cache globals IMPORT_HOME, IMPORT_HOME_REAL and IMPORT_HOME_DONE, which are internal).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: `:-` also defaults an empty IMPORT_LEFT, not only an unset one, which is immaterial · r3: writes made through import_home inside a walk's `$(...)` are lost, which is why the walks call `import_home` first

`import_home || return 1` (`:626`); `IT_ROOT="${ROOT_REAL:-}" IT_HOME="$IMPORT_HOME" IT_HOME_REAL="$IMPORT_HOME_REAL" IT_LEFT="${IMPORT_LEFT:-$IMPORT_OUT_MAX}"` (`:645-646`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:617-647`

---

## Claim 12: Superset exception: "a session in another checkout of the repo (an absolute name into that checkout, or a relative one that re-enters through its directory; the reader set is U2b's)" (and plan U2b: "`@../wtB/docs/x.md` re-enters another checkout through its directory name")

**Location:** `scripts/lib/dev-cycle-read.sh:525-527`; `docs/working/plan-build-loop-handoff.md:279`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that put resolves `..` lexically and keeps only names below ROOT_REAL, so a relative name resolving into a sibling checkout is dropped while a session rooted there imports it; does not establish the exception list is complete for every reader (U2b's question), and does not cover an absolute spelling through a symlinked alias of ROOT_REAL (dropped, but Claude Code refuses it too, so not a missing exception).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2 (Confidence Medium, static): "does not execute a two-worktree session against Claude Code" · This is the fix for the L2-final Mostly accurate rows on the "another checkout" parenthetical and on plan U2b.

`if (part[i] == "..") { if (k > 0) k--; continue }` ... `if (index(out, pre) != 1 || length(out) <= length(pre)) return` (`scripts/lib/dev-cycle-read.sh:567`, `:571`). The sibling-precision test (`test/scripts/build-loop-check.bats:489-500`) shows `@../<sibling>/docs/sib.md` not read as the repo's `docs/sib.md`, and passes.

**Evidence:** `scripts/lib/dev-cycle-read.sh:557-577`, `test/scripts/build-loop-check.bats:489-500`, X1/bats.log, SP/u2a3bfcc3-suites.txt

---

## Claim 13: import_targets: "It returns 1 when sed, python3, awk or import_home fails, when ROOT_REAL is empty, when a ~/ name appears and the home is not absolute, or when the candidates and comment splices run past a work bound or print past IMPORT_LEFT"

**Location:** `scripts/lib/dev-cycle-read.sh:533-536`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every listed failure arm, and that the work bound now includes resolved spellings; does not establish the bound's value is safe for every legitimate file (only this repo's 957 docs, Claim 34).
**Replicate verdicts:** r1=— · r2=Verified · r3=— · single-replicate detection
**Replicate annotations:** none

`if (root == "") exit 2` (`:602`), `if (substr(home, 1, 1) != "/") exit 4` (`:551`), `work += length(c); if (work > 50000000) exit 3` in emit (`:543`), put (`:561`) and splice (`:594`), `if (printed - 1 > left) exit 3` (`:575`); each awk exit propagates through `awk "$IMPORT_AWK" || return 1` (`:646`). Executed (r2): a 4 MiB file, 200k distinct names and the 10,100-escaped-space line all return 1 (`X2/probe1.log`, `bash u2a3bfcc2-probe1.sh <lib>`, exit 0, 2026-10-07T15:42:34Z).

**Evidence:** `scripts/lib/dev-cycle-read.sh:541-604`, `:645-646`, X2/probe1.log

---

## Claim 14: emit: "Claude Code trims the name; it rejects a name led by a space first, so trimming one only over-reads."

**Location:** `scripts/lib/dev-cycle-read.sh:544-545`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the order of the filter and the trim in the 2.1.292 bundle; does not cover names led by other whitespace, which cannot occur because the token regex excludes `\s` apart from an escaped space.
**Replicate verdicts:** r1=— · r2=— · r3=Verified · single-replicate detection
**Replicate annotations:** none

Bundle `reo`: `if(H=H.replaceAll("\\ "," "),H){if(!EP(H)&&(H.startsWith("./")||H.startsWith("~/")||H.startsWith("/")&&H!=="/"||!H.startsWith("@")&&!H.match(/^[#%^&*()]+/)&&H.match(/^[a-zA-Z0-9._-]/))){let Y=Ye(H,FT(n));` The filter runs before `Ye`, whose body begins `let n=e.trim();` (offset about 205304669). A name led by a space fails every arm of the filter.

**Evidence:** claude.exe offsets 212107515 and 205304669

---

## Claim 15: emit: "~/ joins the home directory (Claude Code: path.join(os.homedir(), rest)), also spelled through its real path, since ROOT_REAL is real."

**Location:** `scripts/lib/dev-cycle-read.sh:548-555`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers Claude Code joining `~/` to the home, the parser's two spellings, and the IT_HOMER to IT_HOME_REAL rename being complete at both ends; does not cover a `~` alone (the parser has no arm for it; the binary returns the home itself), or a home that differs from the reading session's (a named exception).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r3: `Hn` is the identity (`function Hn(t){return t}`, offset 203416965) · r2: `rg -n 'IT_HOMER|IMPORT_HOMER|IMPORT_HOME_KEY|UTF8_OK|\bhomer\b' scripts test` in the archive copy exits 1 with no matches (paraphrased — no quote available because the claim covers absence of matches) · This text no longer carries the over-read caveat that the L2-final Claim 30 recorded under a symlinked HOME.

Binary: `if(n.startsWith("~/"))return Hn(b(c(),n.slice(2)))` (claude.exe strings, `Ye`). Probe (`bash x/ccprobe2.sh u-set ...`, 2026-10-07T15:48:17Z): user memory `@~/.cargo` with `HOME=/tmp/u2a3bfcc1-cc-F564/home` logged `skipping /tmp/u2a3bfcc1-cc-F564/home/.cargo`. Parser: `if (homereal != home) put(homereal "/" substr(c, 3))` then `c = home "/" substr(c, 3)` (`scripts/lib/dev-cycle-read.sh:552-553`); `homereal = ENVIRON["IT_HOME_REAL"]` (`:601`) is set by `IT_HOME_REAL="$IMPORT_HOME_REAL"` (`:645`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:542-556`, `:601`, `:645`, X1/cc-home-probe-user.txt, X2/bats.log, claude.exe offsets 205304669 and 203416965

---

## Claim 16: put: "The resolved spelling is what costs (its length grows with the depth of the importing file), so it is charged too, and each is resolved once per file." (commit aa379ee9: "performance F1: put charges each resolved spelling ... and resolves it once per file.")

**Location:** `scripts/lib/dev-cycle-read.sh:559-563`; commit aa379ee9 message
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers put's charge (made for every call, before the `tried` check, so repeats still count) and the per-awk-process `tried` memo (one awk process per import_targets call, so once per file); does not establish dedup across different spellings that resolve alike, or the bound's exact trip point on every host (it depends on ROOT_REAL's length).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r3: "does not establish the runtime bound of the bash side, which is bounded separately by IMPORT_OUT_MAX" · r1: the no-charge mutant fails test 48 · timings in the three runs: 4 MiB `@a` 50 levels down fails in 0.5 s (r1), 0.46 s (r2) and 0.49 s (r3) at 4828727d against success after 14.62 s, 13.77 s and 14.62 s at e1654266

```awk
# scripts/lib/dev-cycle-read.sh:558-563 (excerpt ends :563; enclosing put() continues to :577 — read)
  if (substr(c, 1, 1) != "/") c = root "/" dir "/" c
  work += length(c); if (work > 50000000) exit 3
  if (c in tried) return
  tried[c] = 1
```

Executed (`bash x/timing.sh`, cwd `x/root`, 2026-10-07T15:45Z): the aa379ee9 lib returned `rc=1` in 0.5 s and the e1654266 lib `rc=0` in 14.62 s.

**Evidence:** `scripts/lib/dev-cycle-read.sh:557-577`, X1/timing.txt, X1/mutants.txt, X2/probe1.log, X2/probe5.log, X2/probe8.log, SP/u2a3bfcc3-timing.txt, SP/u2a3bfcc3-mut.txt

---

## Claim 17: import_home: "from HOME as Claude Code's runtime (Bun) reads it: unset or empty, the passwd entry (Node would read an empty HOME as "")"; test comment: "Claude Code's runtime (Bun) falls back to the passwd entry for an empty HOME as for an unset one (L2-final fact-check r1 22b)."

**Location:** `scripts/lib/dev-cycle-read.sh:610-612`; `test/scripts/build-loop-check.bats:697-700`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers Claude Code 2.1.292's `~/` resolution with HOME set, empty and unset, Node v22's `os.homedir()` for the same, and import_home's matching rule; does not cover a passwd lookup that fails (the home is then "" and the parser fails on a `~/` name), or Bun's `os.homedir` observed other than through Claude Code's resolver (`BUN_BE_BUN=1 claude -e` is not supported by this build).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: the test comment's citation is slightly off (the Bun behavior is L2-final r1 Claim 22a; 22b is the Node attribution), which does not mislead about behavior · This wording is the fix for the L2-final Incorrect rows 34 and 73 (the "Node's os.homedir" attribution).

Claude Code probes (user memory `@~/.cargo`, 2026-10-07T15:43-15:49Z; r1 `bash x/ccprobe2.sh u-{set,empty,unset}`): `HOME=<scratch>` resolves under the scratch home; `HOME=` gives `skipping /home/node/.cargo`; unset gives `skipping /home/node/.cargo` (passwd: `node:x:1000:1000::/home/node:/bin/bash`). Node: `HOME= node -p 'JSON.stringify(require("os").homedir())'` printed `""`; unset printed `"/home/node"`. The code is `h="${HOME:-$(getent passwd "$(id -u)" | cut -d: -f6)}" || h=""` (`scripts/lib/dev-cycle-read.sh:620`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:610-623`, `:551`, X1/cc-home-probe-user.txt, X2/probe3.log, X2/probe4.log, SP/u2a3bfcc3-cc-probe.txt (tags set, empty, unset), SP/u2a3bfcc3-node.txt

---

## Claim 18: import_home: "A walk calls it once, so the parser's $(...) calls inherit it; it recomputes only when HOME itself changes (IMPORT_HOME_DONE holds the HOME it was computed for)" (commit aa379ee9: "import_home is keyed on the raw HOME, so an unset HOME no longer forks getent, id and cut per file.")

**Location:** `scripts/lib/dev-cycle-read.sh:613-615`; commit aa379ee9 message
**Type:** Performance / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the key (set-ness and value, so empty and unset differ), the early return before any fork, and per-file calls inside `$(...)` inheriting the walk's precomputed key; does not establish behavior if a caller edits IMPORT_HOME_DONE, or main's walk separately (same call shape, `:736`).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r3: IMPORT_HOME_DONE holds an encoding of HOME (its set flag plus its value) rather than HOME itself, "a harmless imprecision" · r1: the relative-home failure is `if (substr(home, 1, 1) != "/") exit 4` (`:551`) · getent calls with HOME unset on a counting shim: 1 against 3 (r1, 3-file walk), 1 against 5 (r2, three-file chain; r3, four-file walk) at e1654266

`local h hr="" key="x${HOME+set}:${HOME-}"` / `[[ "$IMPORT_HOME_DONE" != "$key" ]] || return 0` (`:618-619`), before the getent fork (`:620`). Keys observed by r3: `xset:/a`, `xset:/b`, `xset:` for empty and `x:` for unset.

**Evidence:** `scripts/lib/dev-cycle-read.sh:616-623`, `:676`, `:736`, X1/homecount-out.txt, X2/probe11.log, SP/u2a3bfcc3-home.txt

---

## Claim 19: "(python3's "replace" decoding matched Claude Code 2.1.292 on every sequence probed in the binary, 13 in all: U2a3b L2 security F1, L2-final fact-check)"

**Location:** `scripts/lib/dev-cycle-read.sh:633-634`
**Type:** Reference / Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers python3's spelling against the binary on the sequences probed (8 more in r1 and 2 more in r3, all match) and the sources' counts; does not establish that the 13 are distinct, or Bun's decoder beyond the probed shapes.
**Severity:** Low
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r1: the L2-final merged report credits r1 with 8 and r3 with 5 (`docs/reviews/code-fact-check-report-build-loop-u2a3b-L2-final.md:767`) and the merged verdict on that claim was Unverifiable; its own probe (`bash x/ccprobe5.sh utf8`, 2026-10-07T15:55:29Z) matched 8 more sequences (`ff`, `c0af`, `eda080`, `e282`, `f4908080`, `f09f98`, `8080`, `e08080`) with the same U+FFFD counts (1, 2, 3, 1, 4, 1, 2, 3) · r2: "neither report lists its sequences side by side, so '13' may double-count" · r3: every one of r3's five shapes is among r1's eight, so the evidence is 13 probes of at most 8 distinct shapes; its own probe matched `@q/1\xff` and `@q/2\xc0\xaf`

r3's reading of the sources: 13 is 8 probes in L2-final r1 ("8 invalid sequences (lone `\xff`, truncated 4-byte, surrogate, overlong 3- and 2-byte, past U+10FFFF, truncated 3-byte, overlong 4-byte)", `docs/reviews/code-fact-check-report-build-loop-u2a3b-L2-final-r1.md:294`) plus 5 in r3 ("a truncated 3-byte sequence, an overlong 4-byte sequence, a surrogate, an overlong 2-byte sequence and one past U+10FFFF", `...-final-r3.md:503`). The cited "U2a3b L2 security F1" compared python3 with Node ("matched node byte for byte", `security-reviewer-review-2026-10-06-L2-build-loop-u2a3b.md:78`) and did not probe the binary. The precise version is "on every shape probed in the binary (8 shapes across 13 probes; L2-final fact-check)", or no count.

**Evidence:** `scripts/lib/dev-cycle-read.sh:631-639`, `docs/reviews/code-fact-check-report-build-loop-u2a3b-L2-final.md:767`, `docs/reviews/code-fact-check-report-build-loop-u2a3b-L2-final-r1.md:294,425`, `docs/reviews/code-fact-check-report-build-loop-u2a3b-L2-final-r3.md:277,503`, X1/cc-utf8-probe.txt, SP/u2a3bfcc3-cc-probe.txt, SP/u2a3bfcc3-node.txt

---

## Claim 20: main_imports header: returns 1 when "... import_home, the parser (its comment lists why) or a lower fails, the IMPORT_OUT_MAX budget is spent, or an imported path main lacks lies under a directory main stores as a symlink or gitlink or exists in the checkout as anything but a plain directory below the root (the top-level .git is skipped)"

**Location:** `scripts/lib/dev-cycle-read.sh:694-707`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the arms aa379ee9 added to the list and the `.git` parenthesis, against `main_imports` read from signature to final line (`:708-785`); does not re-verify the earlier arms (record parse, duplicates, symlink text).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none · This header is the fix for the L2-final Mostly accurate row 42 (the failure list omitted the parser, import_home, the budget and the per-file lower).

`import_home || return 1` (`:736`); parser `|| { IMPORTED_MAIN=error; return 1; }` (`:742`); budget `(( (used += ${#out}) <= IMPORT_OUT_MAX )) || {...}` (`:764`); lower `i="$(lower "$out")" || {...}` (`:766`); link/gitlink parent `[[ ! "${ent[$c]:-}" =~ ^1[26]0000$ ]] || {...}` (`:781`); non-plain checkout node `[[ -d "$p" && ! -L "$p" && -z "$(blocker "$p" dir)" ]] || [[ ! -e "$p" && ! -L "$p" ]] || {...}` (`:782`); top-level skip `[[ "$p" != .git ]] || continue` (`:778`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:708-785`

---

## Claim 21: "The top-level .git (a prefix candidate from @.gitignore; a linked worktree's gitfile) names no file main has, and is skipped. A nested .git is not: a nested repository's .git directory passes the plain-directory check below, and a .git file is read by Claude Code like any file, so it fails below, as files under .git do when the checkout holds them (U2a3c walks them)." (commit aa379ee9: "security F2: only the top-level .git is skipped. ... the nested .git directory arm was equivalent ..., so it is gone.")

**Location:** `scripts/lib/dev-cycle-read.sh:772-778`; commit aa379ee9 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the top-level skip, a nested `.git` directory (plain, so it passes), a nested `.git` file (fails), and Claude Code reading a nested `.git` file and following its imports; does not cover a nested `.git` that is itself a symlink or other non-plain node (it fails the `! -L` test, which is fail-closed; the old arm skipped those, so "equivalent" holds for the directory case only, as the commit says).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r3: a nested `.git` directory under a parent that main stores as a gitlink already failed before the arm, at the earlier prefix `n/.g` via `[[ ! "${ent[$c]:-}" =~ ^1[26]0000$ ]] || { IMPORTED_MAIN=error; return 1; }` (`:781`) · This is the fix for the L2-final Mostly accurate row 44 (nested paths under `.git`).

`plaindir` accepts a real directory (`plaindir() { local r; [[ -n "${ROOT_REAL:-}" && -d "$1" ]] && r="$(realpath -e -- "$1" 2>/dev/null)" && [[ "$r" == "$ROOT_REAL/$1" ]]; }`, `:106`). Claude Code probe (r1, `claude -p hi --debug` in `/tmp/u2a3bfcc1-cc-F564/proj`, 2026-10-07T15:43:00Z): CLAUDE.md `@n/.git`, where `n/.git` is a file holding `gitdir: x` / `see @docs/d`, logged `skipping /tmp/u2a3bfcc1-cc-F564/proj/n/docs/d`, so the `.git` file was read and its import followed relative to `n/`. r2 and r3 reproduced it (`.../proj/docs/viagit`, `.../proj/sub/dirx`). The binary's text-file gate keys on the extension (`let g=r8n(n).toLowerCase();if(g&&!f8n.has(g))return ... "Skipping non-text file in @include"`), and `.git` has no extension, so it passes it (paraphrased — no quote available because `r8n` is a minified name; the probe is the behavioral evidence). Test 44 (`bats:683`) passes; the mutant restoring the `*/.git` skip fails it.

**Evidence:** `scripts/lib/dev-cycle-read.sh:103-124`, `:767-783`, X1/cc-nested-git-debug-1.txt, X1/mutants.txt, X2/probe5.log, X2/probe6.log, SP/u2a3bfcc3-cc-probe.txt, SP/u2a3bfcc3-mut.txt

---

## Claim 22: precision test comments: "The NBSP ends the token: no name runs on past it", "ns: the names run on past each space. Neither walk reads one", "a tab and a CR are blanks too, as in JavaScript's \s"

**Location:** `test/scripts/build-loop-check.bats:40-41`, `:63-64`, `:548-549`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the walks yield no run-on name for each listed space, tab and CR (the assertions pass); does not cover `\v`/`\f`, which JavaScript's `\s` also ends a name at but the parser does not, which only over-reads because every prefix up to the next blank is still a candidate.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=—
**Replicate annotations:** none

The scanner breaks on `ch == " " || ch == "\t" || ch == "\r"` after sed maps each UNI_SPACES sequence and NUL to a space (`scripts/lib/dev-cycle-read.sh:586`, `:627`: `for u in "${UNI_SPACES[@]}"; do s+=(-e "s/$u/ /g"); done`). The tests passed in the 149 run.

**Evidence:** `scripts/lib/dev-cycle-read.sh:496-501`, `:578-590`, `:624-630`, X1/bats.log, X2/bats.log

---

## Claim 23: "Seven 4200-byte runs after an @: the first run's prefixes alone print past IMPORT_OUT_MAX, so the parser returns 1 (the candidate-work bound, which prints nothing, has its own test)."

**Location:** `test/scripts/build-loop-check.bats:388-390`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which bound stops the first run under the default IMPORT_OUT_MAX; does not cover the other six runs (deduplicated names) or a caller-supplied IMPORT_LEFT.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r3: the printed total passes 4,000,000 at a prefix length of about 2,828, with the work charged by then far under 50,000,000 · This is the fix for the L2-final Stale row 52 (the heavy-run test tripped the print budget but described the work bound).

Executed (r1, `bash x/heavy.sh <aa379ee9 lib> heavy1.txt`, 2026-10-07T15:50Z): one 4200-byte run gave `default rc=1`, `unbounded-print rc=0`, so the print budget alone fails it and the work bound does not trip on one run. r2: the parser stops after 2,826 lines on `if (printed - 1 > left) exit 3` (`scripts/lib/dev-cycle-read.sh:575`); with IMPORT_LEFT=999999999 it prints all 4,200 first-run names and then fails on the work bound. Test 43 is the print-free work-bound test.

**Evidence:** `test/scripts/build-loop-check.bats:388-394`, `scripts/lib/dev-cycle-read.sh:542-577`, X1/heavy-out.txt, X2/probe7.log

---

## Claim 24: "both walks fail once the parser has printed more than IMPORT_OUT_MAX characters in all"

**Location:** `test/scripts/build-loop-check.bats:406`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the walks' `${#out}` accounting (characters in the caller's locale; bytes under the test's LC_ALL=C); does not cover non-C locales, where awk's byte count can stop first, as the lib's comment at `:489-491` says.
**Replicate verdicts:** r1=— · r2=— · r3=Verified · single-replicate detection
**Replicate annotations:** none

`(( (used += ${#out}) <= IMPORT_OUT_MAX ))` (`scripts/lib/dev-cycle-read.sh:685`, `:764`). The test passes.

**Evidence:** `scripts/lib/dev-cycle-read.sh:685`, `:764`, SP/u2a3bfcc3-suites.txt

---

## Claim 25: "A sibling whose path is as long as the repo's: its docs/sib.md is not the repo's."

**Location:** `test/scripts/build-loop-check.bats:491`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the prefix test `index(out, pre) != 1` with `pre = root "/"` (a same-length sibling differs before the slash); does not cover case-insensitive file systems.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=—
**Replicate annotations:** none

`pre = (root == "/") ? "/" : root "/"` (`scripts/lib/dev-cycle-read.sh:602`) and `index(out, pre) != 1` (`:571`). The test passed.

**Evidence:** `scripts/lib/dev-cycle-read.sh:571`, `:602`, X1/bats.log, X2/bats.log

---

## Claim 26: "...on one line of many HTML comments (...; a 10 s timeout)"; "320,000 comments in one 2.24 MB line"

**Location:** `test/scripts/build-loop-check.bats:554-556`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the timeout value and the input size; the "27 s with status 0 at be94c871" history was not re-run.
**Replicate verdicts:** r1=Verified · r2=— · r3=— · single-replicate detection
**Replicate annotations:** none

`timeout 10 bash -c ...` (`:559`); `head -c 320000 /dev/zero | sed 's/\x0/<!---->/g'` gives 320,000 x 7 = 2,240,000 bytes (`:557`).

**Evidence:** `test/scripts/build-loop-check.bats:554-561`

---

## Claim 27: "import_targets prints 13 bytes for each file (a, a., a.m, a.md; 39 in all). Three files, not two: the parser gets what is left (IMPORT_LEFT), and a budget that restarted at each file would look walk-wide until the third."

**Location:** `test/scripts/build-loop-check.bats:610-612`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the byte count (1+2+3+4 names plus 3 newlines = 13, x3 = 39) and that the test kills the budget mutants run; does not cover main's walk visiting the files in another order (the order does not change the total), or the "until the third" rationale against a two-file variant beyond the mutant below.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: mutant `used = ${#out}` (both walks) passes e1654266's two-file test (`ok 1`) and fails the three-file test with `38 tree ok` (`X2/probe9.log`, 2026-10-07T15:46:21Z) · r1: a per-file-budget mutant (`(( ${#out} <= IMPORT_OUT_MAX ))`) gives `not ok 3 IMPORT_OUT_MAX bounds what the whole walk prints, not each file ...` while the other two budget tests still pass (bats `-f`, 2026-10-07T15:57Z) · r3: the expected `38 tree failed ... 39 tree ok, 39 main ok` holds · This test is the fix for the L2-final per-file budget gap (L2-F-A4).

**Evidence:** `test/scripts/build-loop-check.bats:609-618`, `scripts/lib/dev-cycle-read.sh:683-685`, `:764`, X1/mutants.txt (`== perfile`), X2/probe9.log, SP/u2a3bfcc3-suites.txt

---

## Claim 28: "10,100 escaped spaces after one @: every candidate trims to nothing, so the print budget (IMPORT_LEFT) never runs, while the candidates' lengths sum to about 51 million. About 0.5 s."

**Location:** `test/scripts/build-loop-check.bats:674-676`
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the sum (10,100 x 10,101 / 2 = 51,010,050) and that emit's charge, not put's, stops it; does not cover slower hosts (the "About 0.5 s" timing is machine-dependent; r2 measured 0.26 s).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none · The no-emit-bound mutant fails exactly this test (`not ok 43`) in all three runs. This is the fix for the L2-final Stale row 52's untested emit bound (L2-F-A3).

emit charges before trimming: `work += length(c); if (work > 50000000) exit 3` then `sub(/^ +/, "", c); sub(/ +$/, "", c)` / `if (c == "") return` (`scripts/lib/dev-cycle-read.sh:543-547`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:542-556`, X1/mutants.txt, X2/probe1.log, X2/probe5.log, SP/u2a3bfcc3-mut.txt

---

## Claim 29: test title "the main walk skips a nested .git directory, but fails closed on a nested .git file"; comment "A nested repository's .git directory names no file: a prefix of @n/.github/x.md is skipped."

**Location:** `test/scripts/build-loop-check.bats:683-684`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the mechanism the title and comment name (a skip) against main_imports; does not dispute the test's assertions, which pass, or the outcome (walk ok with a nested `.git` directory, failed with a nested `.git` file).
**Severity:** Low
**Legibility-target:** for-author
**Replicate verdicts:** r1=Verified · r2=Incorrect · r3=Mostly accurate
**Replicate annotations:** r1 (Verified, executed): read "skips" as "accepted without failing, through the plain-directory check, not through the `.git` skip line"; its scope says the same · r3 (Mostly accurate, Confidence High, executed): "The outcome is right, and the test passes. The mechanism word is not." · r2 (Incorrect, static): the removed mutant arm was the skip

The code comment the same commit wrote says the opposite: "A nested .git is not [skipped]: a nested repository's .git directory passes the plain-directory check below" (`scripts/lib/dev-cycle-read.sh:773-775`), and the only skip is `[[ "$p" != .git ]] || continue` (`:778`). The prefix `n/.git` goes through `[[ -d "$p" && ! -L "$p" && -z "$(blocker "$p" dir)" ]]` (`:782`) and stays in `IMPORTED_MAIN` (`IMPORTED_MAIN+="$i"$'\n'`, `:766`), so `isimported main n/.git` answers imported: it is admitted and recorded, not skipped. The precise wording is "the main walk passes a nested .git directory (a plain directory), but fails closed on a nested .git file".

**Evidence:** `scripts/lib/dev-cycle-read.sh:764-783`, `test/scripts/build-loop-check.bats:683-695`, X1/cc-nested-git-debug-1.txt, X1/mutants.txt

---

## Claim 30: "the tree walk fails closed on an imported file it cannot read, when the caller did not set pipefail"

**Location:** `test/scripts/build-loop-check.bats:724-725`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers imported_names' own `set -o pipefail` being what the test pins (as uid 1000, so a mode-000 file denies the read); does not cover a root runner, where the test's premise would not hold.
**Replicate verdicts:** r1=— · r2=Verified · r3=Verified
**Replicate annotations:** r1: the no-pipefail mutant fails the tree-walk test (`0 walk: ok head: cannot open 'docs/a.md' for reading: Permission denied`), reported in r1's findings summary

`local - f d p lp out used=0 seen=$'\n' queue=() recs=(); set -o pipefail` (`scripts/lib/dev-cycle-read.sh:663`), so a failing `head -c 4194305 -- "$f"` fails the `$(...)` on `:683`. With that `set -o pipefail` removed the test fails with the output above (r2, `X2/probe9.log`). The test passes as uid 1000.

**Evidence:** `scripts/lib/dev-cycle-read.sh:663`, `:683`, X2/probe9.log, SP/u2a3bfcc3-suites.txt

---

## Claim 31: "400,000 copies of @a, from a file 50 directories down: each resolves to a path of over 150 characters, past the 50,000,000 bound in all, though the name itself is one character (performance L2-final F1 measured 22 s and success before the charge)."

**Location:** `test/scripts/build-loop-check.bats:736-738`
**Type:** Performance / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the resolved length and the bound's margin under bats' default layout; does not cover the 22 s figure on the original host or for this input, or very short TMPDIR values (the bound needs a root of at least about 23 characters).
**Severity:** Low
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r1: "over 120 characters" is the precise version; the bound trips whenever ROOT_REAL is over 22 characters (400,000 x (L + 104) > 5x10^7); its own unbounded run (ROOT_REAL 26 characters, 1,398,101 copies) took 14.62 s and succeeded, not 22 s, which is host timing · r2: "about 135 characters or more"; the same input returns 1 with a 33-character root and 0 with 19- and 2-character roots; the 22 s figure was for the 4 MiB file, not this 1.2 MB one · r3: "a path of over 130 characters (under the default TMPDIR)"; a measured sibling was `len=27 /tmp/bats-run-nfnLl8/test/1`

The resolved spelling is `root "/" dir "/" c` with a 99-character `dir` (50 `d` parts), so its length is ROOT_REAL's length + 102 (`scripts/lib/dev-cycle-read.sh:558`). ROOT_REAL is `$BATS_TEST_TMPDIR/repo` (`test/lib/build-loop-fixtures.bash:21-22`). Under bats' default `TMPDIR=/tmp` that is `/tmp/bats-run-XXXXXX/test/48/repo`, 33 characters, so the path is about 135 characters, not over 150. It exceeds 150 only under a longer TMPDIR (about 151 with the 20-character mktemp dir the review brief requires). The conclusion holds: 400,000 x 136 = 54.4 million, past 50,000,000, and the test passes.

**Evidence:** `scripts/lib/dev-cycle-read.sh:557-561`, `test/lib/build-loop-fixtures.bash:21-22`, `test/scripts/build-loop-check.bats:733-744`, X1/timing.txt, X2/probe1.log

---

## Claim 32: commit aa379ee9: "A 4 MiB file of @a 50 directories down fails in 0.6 s (22 s and success before)"

**Location:** commit aa379ee9 message (same figures in the rubric's L2-F-C2 disposition)
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers fail versus success and the order of magnitude on this host against aa379ee9's and e1654266's libs; does not reproduce the author's host or exact timings (host-dependent).
**Severity:** Low
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Mostly accurate (compound) · r2=Verified (compound) · r3=Verified
**Replicate annotations:** merge note: r1 verdicted this figure and the distinct-name figure (Claim 33) as one sentence, and its Mostly accurate rests on the distinct-name half. On this half r1 wrote: "This matches the claim's shape" · r3 (Verified): "Covers fail versus success and the order of magnitude. The absolute times depend on the machine." · r2 (Verified): the 4 MiB file fails in 0.46 s (4828727d) against success in 13.77 s (e1654266) · aa379ee9 is committed, so this is a note for the rubric's L2-F-C2 line, not a wording fix

r1 (`bash x/timing.sh` / `x/timing2.sh`, cwd `/tmp/u2a3bfcc1-5a3b/x/root`, ROOT_REAL 26 characters, 2026-10-07T15:45-15:58Z): 4 MiB `@a`: new lib `rc=1` in 0.5 s; old lib `rc=0` in 14.62 s. r3: `new many rc=1 0.49s`; `old many rc=0 14.62s`.

**Evidence:** X1/timing.txt, X2/probe1.log, X2/probe8.log, SP/u2a3bfcc3-timing.txt

---

## Claim 33: commit aa379ee9: "200k distinct names at that depth fail in 1.8 s."

**Location:** commit aa379ee9 message (also the rubric's L2-F-C2 disposition)
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers 200,000 distinct in-repo names (`@a<N>`) at depth 50 against aa379ee9's and e1654266's libs; does not reproduce the author's exact input (r3 does not know the commit's test names; names that resolved outside the repo would print nothing) or host.
**Severity:** Low
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Mostly accurate · r2=Verified (compound) · r3=Mostly accurate
**Replicate annotations:** r2 (Verified, Confidence Medium): "the outcomes (fail vs success) and output identity; the timings are host-dependent and were reproduced only in direction"; 200k distinct names fail in 0.61 s · r3: "Offered as evidence for the performance-F1 fix, this case does not show the charge. Claim 29a does." (its 4 MiB case, merged Claim 32) · r1: the commit is immutable, so this is a note for the rubric's L2-F-C2 line

The distinct-name input fails under default settings, but it failed before the charge too. r1: new lib `rc=1` in 0.62 s; old lib `rc=1` in 2.32 s, and under the default budget both stop on IMPORT_LEFT (37,487 names printed in each). Only with the print budget lifted does the charge decide: new lib `rc=1` in 1.0 s, old lib `rc=0` in 13.07 s. r3: `new distinct rc=1 0.64s`, `old distinct rc=1 2.57s`. Every prefix of an in-repo name prints a path of about 100 characters, so the IMPORT_OUT_MAX print budget stops the run whether or not the charge exists.

**Evidence:** X1/timing.txt, X2/probe1.log, SP/u2a3bfcc3-timing.txt

---

## Claim 34: commit aa379ee9: "--check-fix over 948 paths identical to main; interleaved, main 2.46-2.61 s, this branch 2.70-2.71 s."

**Location:** commit aa379ee9 message
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers per-path verdicts (output identity) over every tracked `docs/*.md` and README.md in a clone at 4828727d; the path count differs because aa379ee9 adds nine review reports (948 at e1654266, 957 now); timings are host-dependent and were reproduced only in direction.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r2 (Confidence Medium on the compound): merge-base f6fdda68's scripts and 4828727d's give byte-identical output, 2.55 s against 2.57 s, one run each · r3: `paths: 957`, `main: ... ok=14 time=2.45s`, `head: ... ok=14 time=2.56s`, `verdicts identical`

r1: `git ls-tree -r --name-only <rev> -- docs README.md | rg -c '\.md$'` gives 948 at e1654266 and 957 at aa379ee9. `bash x/checkfix.sh <scripts> <out>` in a clone at 4828727d (957 paths, interleaved twice, 2026-10-07T15:46:05Z): main 2.40/2.48 s, branch 2.54/2.63 s, all rc=0, outputs byte-identical (`cmp` IDENTICAL).

**Evidence:** X1/checkfix-out.txt, X1/cf-mainscripts.txt, X1/cf-brscripts.txt, X2/probe2.log, SP/u2a3bfcc3-cf.txt

---

## Claim 35: commit aa379ee9: "149/149; the no-charge, skip-any-nested-.git and no-emit-bound mutants fail."

**Location:** commit aa379ee9 message (also the rubric's "Verification: 149/149")
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the five suites dev-cycle (78), build-loop-check (48), build-loop-read (19), fixture-git-env (2) and fixture-hermeticity (2) = 149 at 4828727d (code-identical to aa379ee9), and the three named mutants; does not cover other suites (hermeticity-lint, 53, also passes). The set of five is the replicates' inference, since the commit does not name the suites.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** none · Does not match the logged hallucination pattern "test count claimed in a commit does not match the suites" (all three).

`TMPDIR=<fresh mktemp> LC_ALL=C bats test/scripts/dev-cycle.bats test/scripts/build-loop-check.bats test/scripts/build-loop-read.bats test/scripts/fixture-git-env.bats test/fixture-hermeticity.bats` (cwd `/tmp/u2a3bfcc1-5a3b`, 2026-10-07T15:41:01Z-15:41:53Z, exit 0): `1..149`, 149 `ok`, no `not ok`. Mutants on build-loop-check: no-charge gives `not ok 48`; the `*/.git` skip restored gives `not ok 44`; emit charge removed gives `not ok 43`. Each kills exactly its named test (r1; r2 and r3 agree).

**Evidence:** X1/bats.log, X1/mutants.txt, X2/bats.log, X2/herm.log, X2/probe5.log, SP/u2a3bfcc3-suites.txt, SP/u2a3bfcc3-mut.txt

---

## Claim 36: commit aa379ee9: "The unit is 794 changed code lines against main" (rubric: "679 at e1654266")

**Location:** commit aa379ee9 message (also the rubric's "Size: 794 ... (679 at e1654266)")
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers added plus deleted lines outside `docs/` against the merge base; does not cover 4828727d (docs only, so the same), or establish that Q-104's measure is exactly this one.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** none

`git diff --numstat main...aa379ee9 -- . ':!docs'` sums to 712 + 82 = 794; for e1654266, 603 + 76 = 679 (paraphrased — no quote available because the figure is a numstat sum, not a file line).

**Evidence:** command output recorded in r1 and r3 (2026-10-07T15:46Z)

---

## Claim 37: commit aa379ee9: "api F1-F4: IMPORT_HOME_REAL (IT_HOME_REAL), IMPORT_HOME_DONE, UTF8_WELL_FORMED; import_targets names its inputs; both walk headers list their new failure arms."

**Location:** commit aa379ee9 message
**Type:** Staleness / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the old names (IMPORT_HOMER, IT_HOMER, UTF8_OK, IMPORT_HOME_KEY, `homer`) are gone outside `docs/reviews` and the new names appear; the headers are Claims 8, 11 and 20; does not cover review reports, which keep the old names on purpose.
**Replicate verdicts:** r1=Verified · r2=— · r3=Verified
**Replicate annotations:** r2 checked the same absence inside its Claim 15 (rename complete at both ends) and did not report it as a separate claim

`rg -n 'IMPORT_HOMER|IT_HOMER|UTF8_OK|IMPORT_HOME_KEY|homer\b' --glob '!docs/reviews/**'` over the 4828727d archive: no hits (claim covers absence of code; nothing to quote). The new names appear at `scripts/lib/dev-cycle-read.sh:601`, `:609-622`, `:636`, `:645`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:601-646`

---

## Escalations

1. **Wording of the rubric's L2-F-C2 disposition.** The "4 MiB ... fails in 0.6 s (22 s and success before); 200k distinct names ... fail in 1.8 s" figures put a print-budget result (the 200k case, which already failed at e1654266) next to the new charge. aa379ee9 is immutable, so any correction belongs in the rubric line. No critic is named.
   - Path: commit aa379ee9 message; `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a3b.md` (L2-F-C2)
   - Raised by: r1 (Escalate: "r1-F4 is for the rubric's L2-F-C2 wording only"), r3 (Escalate: "Claim 29b is the only one that touches the evidence offered for a fix")
   - Addressee: orchestrator
   - Merged claims: 32, 33
2. **Whether "13 in all" was meant as a disjoint union of the L2-final r1 and r3 probes.** r1 asked it as a question. It is a wording question for the lib comment's author.
   - Path: `scripts/lib/dev-cycle-read.sh:633-634`
   - Raised by: r1 (Questions)
   - Addressee: orchestrator
   - Merged claim: 19
3. **Already-routed rows, noted as not re-raised:** the U2b reader-model routing (override rows). r1 and r2 listed it as out of scope.
   - Path: `docs/working/plan-build-loop-handoff.md:279`
   - Raised by: r1 (Out of scope), r2 (Out of scope)
   - Addressee: already routed (U2b override rows)
   - Merged claims: 4, 5, 12

No replicate's `Escalate:` item names a blocking finding. r1, r2 and r3 each wrote that nothing blocks.

## Verdict stability

- **Total clusters (merged claim rows):** 37
- **Single-replicate rows:** 5 (Claims 10, 13, 14, 24, 26), with no agreement measurable
- **Rows reported by two or three replicates:** 32
  - **All reporting replicates agreed:** 28
  - **Verdicts disagreed:** 4
    - Claim 9: r1=Mostly accurate · r2=Verified · r3=Mostly accurate
    - Claim 29: r1=Verified · r2=Incorrect · r3=Mostly accurate
    - Claim 32: r1=Mostly accurate (compound) · r2=Verified (compound) · r3=Verified
    - Claim 33: r1=Mostly accurate · r2=Verified (compound) · r3=Mostly accurate
- **Agreement rate:** 28 / 32 = **87.5%** over multi-replicate rows. Counting single-replicate rows as trivially agreed gives 33 / 37 = 89.2%.
- **Detection spread:** 5 of 37 rows (14%) were surfaced by one replicate only, and all five are Verified, so no non-Verified finding depends on a single replicate. The one Incorrect (Claim 29) was raised by r2 alone at that severity; r3 called it Mostly accurate and r1 Verified. It is a test-title wording defect with passing assertions.
- This run is below the 90% falsifier threshold (the previous merged pass was 76.3%), so k stays at 3.
