Commit: 03be719e
**Replication:** k=1 (loop pass, decision 031)

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u2a4 (branch `feat/build-loop-u2a4`)
**Scope:** `git diff d7cdc1ea..HEAD` (iteration 1's fixes, commit 03be719e; ee5108bd adds review reports only): code comments and the lib header contract in `scripts/lib/dev-cycle-read.sh` and `scripts/dev-cycle.sh`, the new tests in `test/scripts/build-loop-check.bats`, commit message 03be719e, known issues A2/A5, plan F11 and the U2a4/U2b bullets, the override-log rows changed or added in the range (462-463, 468-479), and the iteration-1 rubric's Status/Author-note cells for A1-A6, C1-C4, C9-C15.
**Checked:** 2026-10-08
**Total claims checked:** 30
**Summary:** 18 verified, 9 mostly accurate, 0 stale, 2 incorrect, 1 unverifiable

Hallucination-pattern log read first. Claim 25's test counts are the logged "specific measured value quoted from an artifact set" class; every count here was checked by `bats --count` and by running the suites, and all match. Claim 26's path count (3,092) is the same class as iteration 1's Claim 2b: the count was taken over an earlier file set, and the conclusion holds. No fabrication was found, so nothing qualifies for the log (and this pass writes only this report).

Execution provenance: every command ran in `/workspace/.claude/wt-build-loop-u2a4` with `TMPDIR=/tmp/u2a4i2-factcheck-dAwk` and `LC_ALL=C`, under `timeout`. Probe scripts are in that directory, and captured output is under `/tmp/u2a4i2-factcheck-dAwk/logs/`. Fixture repos were created under `$TMPDIR` and removed by their scripts. No process was left running.

---

## Claim 1: "the top level and the one holding each .claude/ in its path (a nested one too: U2a4 i1 security F3), as PATH spells them, once each"

**Location:** `scripts/lib/dev-cycle-read.sh:490-494`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers prompt_bases over paths with zero, one and two separated `.claude/` components (top-level and nested, mixed case) and a `.claude/` placed directly inside another `.claude/`, plus both walks end to end; does not establish whether a Claude Code session started inside a `.claude/` directory loads `.claude/.claude/commands/` (the reader model is U2b's).

The function, read whole:

```bash
# scripts/lib/dev-cycle-read.sh:495-502
prompt_bases() {
  local -n pb_a="$1"; local rest="/$2" n
  pb_a=("")
  while [[ "$rest" == */.claude/* ]]; do
    rest="${rest#*/.claude/}"; n=$(( ${#2} - ${#rest} - 9 ))
    (( n <= 0 )) || pb_a+=("${3:0:n}")
  done
}
```

When the `.claude/` components are separated by at least one other component, the arithmetic is right. Executed (`pb.sh`):

```
.claude/commands/x.md -> []
.Claude/Commands/X.md -> []
a/.claude/commands/x.md -> [] [a]
A/B/.CLAUDE/skills/k/SKILL.md -> [] [A/B]
a/.claude/commands/b/.claude/commands/x.md -> [] [a] [a/.claude/commands/b]
A/.Claude/commands/B/.claude/Agents/x.md -> [] [A] [A/.Claude/commands/B]
.claude/commands/.claude/commands/x.md -> [] [.claude/commands]
a/.claude/.claude/commands/x.md -> [] [a]
x.claude/commands/y.md -> []
```

In those cases the list holds the top level once and each enclosing directory once, spelled as PATH spells it (`A/.Claude/commands/B`). It never repeats an entry, because `n` grows strictly and `n <= 0` drops the top-level match (paraphrased — no quote available because this is arithmetic over the loop above: n = (offset of the match in "/LP") − 1, so the first match at offset 0 gives −1).

The miss is a `.claude/` sitting directly inside another `.claude/`. The `${rest#*/.claude/}` strip consumes the slash that the next `*/.claude/*` test needs. For `a/.claude/.claude/commands/x.md`, the remainder `.claude/commands/x.md` has no leading `/`, so the directory holding the inner `.claude/` (`a/.claude`) never becomes a base. The same happens to `.claude/.claude/commands/x.md`, whose base `.claude` is dropped. PROMPT_DIR, `(^|/)\.claude/(commands|agents|output-styles|skills)/` (`:484`), does make both of these files prompt starts.

End to end (`walk.sh`), a committed `.claude/.claude/commands/x.md` holding `run @../docs/n1.md` and `a/.claude/.claude/commands/x.md` holding `run @../docs/n2.md` give:

```
tree docs/n1.md NOT
tree a/docs/n2.md NOT
main docs/n1.md NOT
main a/docs/n2.md NOT
```

A session whose directory is `.claude/` (or `a/.claude/`) would resolve those names to `docs/n1.md` (or `a/docs/n2.md`). That is an under-read, the failure class the brief names. In practice it needs a prompt file in a doubled `.claude/.claude/` directory. The precise statement is "each `.claude/` that follows a `/` or starts the path, unless it directly follows another `.claude/`". Keeping the slash (`rest="${rest#*/.claude}"`, then `n=$(( ${#2} - ${#rest} - 8 ))`) would make the rule match the comment.

**Evidence:** `scripts/lib/dev-cycle-read.sh:484`, `scripts/lib/dev-cycle-read.sh:490-502`, `/tmp/u2a4i2-factcheck-dAwk/pb.sh`, `/tmp/u2a4i2-factcheck-dAwk/logs/pb.log` (2026-10-08T06:48:52Z, exit 0), `/tmp/u2a4i2-factcheck-dAwk/walk.sh`, `/tmp/u2a4i2-factcheck-dAwk/logs/walk.log` (2026-10-08T06:49:11Z, exit 0)

---

## Claim 2: Restatements of "every enclosing `.claude/`'s directory" (commit 03be719e C1-C3; rubric C1 "Fixed"; known issue A5; plan U2a4 bullet; the build-loop-check test title)

**Location:** `docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a4.md:41`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the "every enclosing" wording wherever this range repeats it; does not re-verdict the reported shape (`a/.claude/commands/b/.claude/commands/x.md`), which is fixed (Claim 1).

The rubric's C1 cell reads "Fixed: `prompt_bases` adds the top level and the directory holding every enclosing `.claude/`. Tested". Commit 03be719e says "prompt_bases gives each prompt start one list of bases, the top level and the directory holding every enclosing .claude/, once each". Known issue A5 (`docs/working/known-issues-dev-cycle.md:18`) says "resolved against the top level and every enclosing `.claude/`'s directory". The plan's U2a4 bullet (`docs/working/plan-build-loop-handoff.md:278`) says "a prompt's names resolved against the top level and every enclosing `.claude/`'s directory (`prompt_bases`...)". The test title at `test/scripts/build-loop-check.bats:1182` says "every enclosing .claude/'s directory". Each statement is refuted by the same `.claude/.claude/` case shown in Claim 1. The test fixture covers only the separated shape: `a/.claude/commands/b/.claude/commands/x.md` (`test/scripts/build-loop-check.bats:1183`).

**Evidence:** `docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a4.md:41`, `docs/working/known-issues-dev-cycle.md:18`, `docs/working/plan-build-loop-handoff.md:278`, `test/scripts/build-loop-check.bats:1182-1192`, `/tmp/u2a4i2-factcheck-dAwk/logs/walk.log`

---

## Claim 3: Rubric A1 "Fixed": "`emit` also reads a name without its leading `"`, for every file (a superset). Tested in both walks."

**Location:** `docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a4.md:30`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a quoted name with no space in it, in prompt and non-prompt files, in both walks; does not cover a quoted name that holds a space (Claim 19b).

The code is `if (substr(c, 1, 1) == "\"" && length(c) > 1) emit(substr(c, 2))` (`scripts/lib/dev-cycle-read.sh:631`), inside `emit` and ahead of any check on the file kind. A non-prompt file reads it too: `printf 'see @"docs/q.md"\n' | import_targets ""` printed `docs/q.md` (`quotes.sh`). Both walks report `docs/q.md`, `docs/r.md` (`@"docs/r.md` with no closing quote) and `docs/s.md` (`@""docs/s.md""`) as imported (`walk.sh`). bats test 77 passed.

**Evidence:** `scripts/lib/dev-cycle-read.sh:627-640`, `test/scripts/build-loop-check.bats:1182-1192`, `/tmp/u2a4i2-factcheck-dAwk/logs/walk.log`, `/tmp/u2a4i2-factcheck-dAwk/logs/quotes.log` (2026-10-08T06:49:29Z, exit 0), `/tmp/u2a4i2-factcheck-dAwk/logs/blc.log`

---

## Claim 4: Rubric A2 "Fixed": "`skills` was added to PROMPT_DIR and the prefilter (an untraced superset). Tested."

**Location:** `docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a4.md:31`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers PROMPT_DIR, the prefilter and the walk result for `.claude/skills/k/SKILL.md`; does not establish whether Claude Code expands `@` in skills (untraced, as the cell says).

PROMPT_DIR is `'(^|/)\.claude/(commands|agents|output-styles|skills)/'` (`:484`), and the prefilter ends `(^|/)\.claude/(rules|commands|agents|output-styles|skills)/.*\.md$` (`:756`). Test 77 commits `.claude/skills/k/SKILL.md` with `use @docs/k.md` and expects `docs/k.md` imported in both walks. It passed.

**Evidence:** `scripts/lib/dev-cycle-read.sh:484`, `scripts/lib/dev-cycle-read.sh:756`, `test/scripts/build-loop-check.bats:1182-1192`, `/tmp/u2a4i2-factcheck-dAwk/logs/blc.log`

---

## Claim 5: Rubric A3 "Fixed": "`import_reset`, which contract item 4 now names. Tested: a checkout change goes unseen until the reset, and seen after it."

**Location:** `docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a4.md:32`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers import_reset's body, item 4's wording and test 78; does not establish that any caller calls it (none exists until U2b/U2c).

`import_reset() { IMPORTED_DONE=""; IMPORTED_MAIN_DONE=""; }` (`:554`). Item 4 reads "Call import_reset before each gate decision and after any checkout change" (`:55-57`). Test 78 adds `CLAUDE.local.md` naming `docs/c.md` after the first walk. It expects `c cached: -` before the reset and `c: $IMP` after it, and it passed.

**Evidence:** `scripts/lib/dev-cycle-read.sh:55-57`, `scripts/lib/dev-cycle-read.sh:553-554`, `test/scripts/build-loop-check.bats:1194-1206`, `/tmp/u2a4i2-factcheck-dAwk/logs/blc.log`

---

## Claim 6: Rubric A4 and C9 "Fixed": truthwalk takes WALK PATH and "now returns 1 with TRUTH_WHY empty. Tested."

**Location:** `docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a4.md:33`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers truthwalk's body, every caller in the repo and TRUTH_WHY per outcome; does not cover truthwalk's need_root behaviour for an unknown WALK (Claim 13).

```bash
# scripts/lib/dev-cycle-read.sh:999-1003
truthwalk() {
  TRUTH_WHY=walk
  case "$1" in main) main_imports || return 0 ;; tree) imported_names || return 0 ;; *) return 0 ;; esac
  TRUTH_WHY=imported; isimported "$1" "$2" || { TRUTH_WHY=""; return 1; }
}
```

`rg -n truthwalk` (excluding `docs/reviews/`) finds three call sites, all in WALK PATH order: `scripts/dev-cycle.sh:180` (`elif truthwalk tree "$lp"; then`), `scripts/lib/dev-cycle-read.sh:1049` (`elif truthwalk main "$lp"; then`) and `test/scripts/build-loop-check.bats:1197-1198`. Executed (`tw.sh`):

```
tree docs/b.md rc=1 why=[]
main docs/b.md rc=1 why=[]
tree Docs/A.md rc=0 why=[imported]
bogus rc=0 why=[walk]
```

**Evidence:** `scripts/lib/dev-cycle-read.sh:993-1003`, `scripts/dev-cycle.sh:180`, `scripts/lib/dev-cycle-read.sh:1049`, `/tmp/u2a4i2-factcheck-dAwk/tw.sh`, `/tmp/u2a4i2-factcheck-dAwk/logs/tw.log` (2026-10-08T06:51:52Z, exit 0)

---

## Claim 7: Rubric A5 "Fixed": "`truthrule` refuses an upper-case letter as `case`, and floor words it. Contract item 8 says to lower-case first. The truthrule table test has a mixed-case row."

**Location:** `docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a4.md:34`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers truthrule's case arm, floor's wording, item 8 and the test row; does not establish that isstart or ownfile refuse a mixed-case path (they do not; item 8 makes lower-casing a caller duty).

`if [[ "$1" == *[ABCDEFGHIJKLMNOPQRSTUVWXYZ]* ]]; then TRUTH_WHY="case"` (`:984`) and `case) FLOOR_WHY="the path could not be lower-cased" ;;` (`:1042`). The test row `Docs/Constraints.md: case` is at `test/scripts/build-loop-check.bats:1121`. Executed: `truthrule Docs/Constraints.md: case` and `truthrule CLAUDE.md: case`. Neither existing caller can reach the arm. check_fix runs `lp="$(lower "$a")"` (`scripts/dev-cycle.sh:176`) and floor runs `lp="$(lower "$1")" || { ... return 0; }` (`:1035`). Both lower-case first, and `lower` is `tr 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' 'abcdefghijklmnopqrstuvwxyz'` (`:577`), so no upper-case ASCII letter survives. Floor's `case` arm is dead code for its own input: executed, `floor Docs/Constraints.md` answered "the user's constraints doc...", not the case wording.

**Evidence:** `scripts/lib/dev-cycle-read.sh:67-68`, `:577`, `:982-992`, `:1031-1052`, `scripts/dev-cycle.sh:176-177`, `/tmp/u2a4i2-factcheck-dAwk/logs/tw.log`

---

## Claim 8a: Rubric A6 / the table test: instruction_names is held equal to isstart, and the test would fail if instruction_names dropped `skills`

**Location:** `test/scripts/build-loop-check.bats:1172-1180`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test's 138 generated paths and two single-word mutations (`skills` removed from the prefilter only, and from PROMPT_DIR only); does not establish equality outside the generated set (for example a component holding `\.claude` in another case pattern, or non-ASCII names).

The test body, run verbatim (`prefilter.sh`) against the HEAD lib, printed `paths=138 starts=78` and `same`. Against a copy with `skills` removed from instruction_names only, it printed `DIFF`, listing the 12 `.claude/skills/` and `.Claude/skills/` paths at each depth that isstart keeps and the prefilter drops (exit 1). Removing `skills` from PROMPT_DIR only also fails, in the other direction.

**Evidence:** `test/scripts/build-loop-check.bats:1172-1180`, `scripts/lib/dev-cycle-read.sh:756`, `/tmp/u2a4i2-factcheck-dAwk/prefilter.sh`, `/tmp/u2a4i2-factcheck-dAwk/logs/prefilter.log` (2026-10-08T06:50:06Z)

---

## Claim 8b: "A table test compares the two over 3 depths × 10 instruction names × 6 dirs × 3 tails × 2 cases."

**Location:** `docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a4.md:35`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the shape of the generated set; does not bear on whether the test is sufficient (Claim 8a).

The loops are `for d in "" a/ a/b/; do for n in CLAUDE.md claude.local.md Agents.MD agent.md GEMINI.md SKILL.md skills.md x.md x.txt claude.md.bak; do ps+=("$d$n"); done` and then `for c in rules commands agents output-styles skills notes; do for t in x.md sub/X.MD x.txt; do ps+=("$d.claude/$c/$t" "$d.Claude/$c/$t")` (`:1174-1175`). That builds 3 × (10 + 6×3×2) = 138 paths (executed: `paths=138`), not the 1,080 the × chain implies. Four of the "10 instruction names" (`skills.md`, `x.md`, `x.txt`, `claude.md.bak`) are negatives. A precise version: "3 depths × (10 basenames, 6 of them instruction names, + 6 dirs × 3 tails × 2 cases of `.claude`)".

**Evidence:** `test/scripts/build-loop-check.bats:1172-1180`, `/tmp/u2a4i2-factcheck-dAwk/logs/prefilter.log`

---

## Claim 9: Rubric C2, C3 "Fixed by `prompt_bases` (one entry each)"; "Fixed: `prompt_bases`"

**Location:** `docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a4.md:42-43`
**Type:** Performance / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that a top-level prompt now gets one base (`""`) and that both walks call one helper; does not re-measure parser cost.

`.claude/commands/x.md -> []` (`pb.log`): one entry, where the old code built `xs=("${pdir[$f]}" "")`. Both walks use `[[ -z "${pdir[$f]+set}" ]] || prompt_bases xs "${pdir[$f]}" "$f"` (`:849`, `:911`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:849`, `:911`, `/tmp/u2a4i2-factcheck-dAwk/logs/pb.log`

---

## Claim 10: Rubric C4 "Fixed: the bullet now points to the header and lists its items"; plan U2b bullet "keeps every item of the lib header's numbered gate caller contract (U2a4; the one statement of these duties: ...)"

**Location:** `docs/working/plan-build-loop-handoff.md:279`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the parenthetical list against items 1-8 at `scripts/lib/dev-cycle-read.sh:41-68`; does not judge whether the bullet should list the items at all.

The bullet points to the header correctly, and the older diverging copy is gone. Its parenthetical lists "the clean worktree at MAIN_SHA, final before the walk; empty `ls-files` stderr; the git environment; `import_reset` per gate decision; the floor before `pathform` and `main_entry`; the `main_checkout` second-caller rule; `LC_ALL=C`", and then item 3's refusal. The parenthetical leaves out item 6 ("Read a walk only through isimported or truthwalk", `:63-64`), item 8 ("Pass truthrule, isstart and ownfile a lower-cased path", `:67-68`), item 1's "with main found by name", and item 5's second half ("refuse the whole branch on any main_entry word but blob or absent", `:58-60`). Read as "the duties are these", it is again a partial copy. "lists its items" in the rubric overstates it.

**Evidence:** `docs/working/plan-build-loop-handoff.md:279`, `scripts/lib/dev-cycle-read.sh:41-68`, `docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a4.md:44`

---

## Claim 11: Plan F11: "a prompt file read by a session started outside the top level and its enclosing `.claude/` directories"

**Location:** `docs/working/plan-build-loop-handoff.md:126`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the F11 gap wording against prompt_bases; the rest of F11's new text (`skills` in the set, the quoted mention, the header contract pointer) checked Verified.

The bases are the directories that hold each `.claude/` (`"${3:0:n}"`, ending before `/.claude/`, `:500`), not the `.claude/` directories themselves. A5 and the U2a4 bullet word this correctly ("every enclosing `.claude/`'s directory"). The precise version is "outside the top level and the directories holding its enclosing `.claude/`". The `.claude/.claude/` exception in Claim 1 also applies here.

**Evidence:** `docs/working/plan-build-loop-handoff.md:126`, `scripts/lib/dev-cycle-read.sh:495-502`

---

## Claim 12: Known issue A2: "The tree walk skips a symlinked start file, instruction or prompt (`inrepo` drops it), so an import from one passes `--check-fix`; the main walk follows a symlinked instruction file and fails on a symlinked prompt, so the floor refuses."

**Location:** `docs/working/known-issues-dev-cycle.md:16`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers both walks' start handling for symlinks; not executed in this pass (iteration 1's security F4 executed the tree-walk half).

Tree walk: `if ! isstart "$lp" || ! inrepo_here "$f"; then continue; fi` (`:841`), where `inrepo_here() { [[ -z "$(blocker "$1" file)" && -f "$1" ]]; }` (`:160`) is `inrepo` without need_root (`inrepo() { need_root; inrepo_here "$1"; }`, `:157`). Main walk: the `120000)` arm follows the link text, but `[[ ${#xs[@]} -eq 0 ]] || { IMPORTED_MAIN=error; return 1; }` (`:920`) fails it for a prompt, and prompt_bases always returns at least `("")`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:157-160`, `:841`, `:918-920`, `:497`

---

## Claim 13: Header "check_brief, isimported, truthwalk, floor and the import walks exit 1 (need_root) unless ROOT_REAL is set"; truthwalk "It exits through need_root."

**Location:** `scripts/lib/dev-cycle-read.sh:18`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers truthwalk with each WALK value while ROOT_REAL is unset; floor's own `need_root` (`:1033`) is Verified.

truthwalk has no need_root of its own. It reaches need_root only through `main_imports` or `imported_names`, so an unknown WALK returns 0 without exiting (`*) return 0 ;;`, `:1001`). Executed with ROOT_REAL unset: `truthwalk bogus docs/a.md` gave `rc=0 why=[walk]` and shell exit 0. `truthwalk tree docs/a.md` printed "ROOT_REAL is not set" and exited 1. The unknown-WALK answer refuses, so it is safe. A precise version: "exits through need_root for tree and main; an unknown WALK answers walk".

**Evidence:** `scripts/lib/dev-cycle-read.sh:18`, `:993-1003`, `/tmp/u2a4i2-factcheck-dAwk/logs/tw.log`

---

## Claim 14: Contract item 4: "Call import_reset before each gate decision and after any checkout change ..., or when HOME, IMPORT_OUT_MAX or IMPORT_WORK_MAX changes: neither walk's cache key holds them."

**Location:** `scripts/lib/dev-cycle-read.sh:55-57`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two walk caches' keys and what import_reset clears; does not cover import_home's own HOME cache, which re-keys itself.

The keys are `IMPORTED_DONE="$ROOT_REAL"` (`:835`) and `IMPORTED_MAIN_DONE="$MAIN_SHA $MAIN_BY_NAME $ROOT_REAL"` (`:883`), and neither holds HOME, either budget or the checkout. import_reset clears exactly those two (`:554`). `import_home` keys its own memo on HOME (`key="x${HOME+set}:${HOME-}"`, `:710`), and main_checkout's memo `pok` is local to each walk (`local -A ... pok=()`, `:880`), so no other cache needs clearing.

**Evidence:** `scripts/lib/dev-cycle-read.sh:554`, `:710`, `:835`, `:880-883`

---

## Claim 15: Contract item 8: "Pass truthrule, isstart and ownfile a lower-cased path (floor and check_fix lower first; truthrule refuses an upper-case letter as case)."

**Location:** `scripts/lib/dev-cycle-read.sh:67-68`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both current callers and truthrule; see Claim 7 for the execution.

The evidence is as in Claim 7: `scripts/dev-cycle.sh:176` and `:1035` lower first, and `:984` refuses upper-case as `case`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:67-68`, `:984`, `:1035`, `scripts/dev-cycle.sh:176`, `/tmp/u2a4i2-factcheck-dAwk/logs/tw.log`

---

## Claim 16: isstart comment: "PROMPT_DIR's commands/, agents/, output-styles/ or skills/ ... the other three are untraced, read as a superset). truthrule refuses the same names; instruction_names is its grep prefilter, and a test holds the two equal."

**Location:** `scripts/lib/dev-cycle-read.sh:476-485`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers PROMPT_DIR's rewrite from `^(.*/)?\.claude/` to `(^|/)\.claude/` (the same matches, since the capture is no longer used) and the test; "untraced" is the reviewers' statement, not checked here.

`elif isstart "$1"; then TRUTH_WHY="instr"` (`:985`) refuses exactly isstart's names, once the path is lower-cased. The new form only drops the capture group that the old prompt_dir sliced with (`${3:0:${#BASH_REMATCH[1]}}`, removed). Equality with the prefilter is Claim 8a.

**Evidence:** `scripts/lib/dev-cycle-read.sh:476-485`, `:985`, `/tmp/u2a4i2-factcheck-dAwk/logs/prefilter.log`

---

## Claim 17: "prompt_dir MAP LP PATH: for a start under PROMPT_DIR (LP lower-cased, PATH as spelled), MAP[PATH] gets LP"

**Location:** `scripts/lib/dev-cycle-read.sh:486-489`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers both call sites' argument order; does not re-verify prompt_bases (Claim 1).

`prompt_dir() { local -n pd_m="$1"; [[ ! "$2" =~ $PROMPT_DIR ]] || pd_m[$3]="$2"; }` (`:489`). Both call sites pass the arguments in that order: `prompt_dir pdir "$lp" "$f"` (`:843`) and `prompt_dir pdir "$f" "${cand[i]:2}"`, where `f="${low[i]:2}"` (`:898-901`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:486-489`, `:843`, `:898-901`

---

## Claim 18: import_targets comment: "against each further directory given (a prompt's session directories: prompt_bases)"; walk comments "a prompt's also against prompt_bases'" and "a session started outside prompt_bases' directories"

**Location:** `scripts/lib/dev-cycle-read.sh:580`
**Type:** Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the renamed references (iteration 1's Claim 24); does not re-verify what prompt_bases returns.

`prompt_bases` exists (`:495`). `rg` finds no remaining `prompt_dirs` outside `docs/reviews/`. The walks pass `"${xs[@]}"` from prompt_bases to `import_targets "$d"` (`:851`, `:913`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:495`, `:507`, `:539`, `:580`, `:851`, `:913`

---

## Claim 19a: emit comment: "A mention in a command may be quoted (@"docs/x.md" ...): the name after the quote is read too."

**Location:** `scripts/lib/dev-cycle-read.sh:629-631`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers quoted names without a space, from the whole token and from its prefixes, in any file; the spaced form is Claim 19b and Claude Code's half is Claim 19c.

`printf '@"docs/q.md"\n' | import_targets ""` printed the prefixes `d`, `do`, ..., `docs/q.md` alongside the quoted spellings. The stripped name comes from the prefix `"docs/q.md` (`walk.log`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:627-640`, `/tmp/u2a4i2-factcheck-dAwk/logs/walk.log`

---

## Claim 19b: The same comment, for a quoted name holding a space

**Location:** `scripts/lib/dev-cycle-read.sh:629-631`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the parser on `@"docs/a b.md"`; does not establish whether Claude Code follows `@` imports inside a file a prompt mention attaches (the transitive case).

The extractor that iteration 1's security F1 quoted from the 2.1.293 binary is `new RegExp(String.raw\`(^|${JY})@"([^"]+)"\`,"g")` (`docs/reviews/security-reviewer-review-2026-10-07-build-loop-u2a4.md:43`). Its capture allows spaces. The scanner ends a name at a blank (`else if (ch == " " || ch == "\t" || ch == "\r") break`, `:674`), so `run @"docs/a b.md"` yields `"docs/a`, `docs/a` and their prefixes, never `docs/a b.md` (`spaced.sh`: "spaced name NOT read"). A directly changed path with a space is still refused before this matters: pathform's `NAMECHARS` has no space (`:178`), and check_fix runs pathform first. The residue is a spaced file on main, mentioned in quotes, whose own `@` names would go unwalked, and only if attached prompt files are expanded. The precise version: "a quoted name without spaces is read too". The security report's recommendation (emit "up to the closing quote ..., spaces included") was not carried out in full.

**Evidence:** `scripts/lib/dev-cycle-read.sh:178`, `:631`, `:666-678`, `scripts/dev-cycle.sh:174`, `/tmp/u2a4i2-factcheck-dAwk/spaced.sh`, `/tmp/u2a4i2-factcheck-dAwk/logs/spaced.log` (2026-10-08T06:53:29Z, exit 0)

---

## Claim 19c: "which the prompt-mention reader of Claude Code 2.1.293 accepts"

**Location:** `scripts/lib/dev-cycle-read.sh:629-630`
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the installed version and the extractor text the security report quotes; does not establish that command expansion calls that extractor.

`claude --version` prints `2.1.293 (Claude Code)`. The extractor text is quoted in the security report, and that report says "Not traced: that the command-expansion path calls Jfn". This pass did not trace the binary's callers. That trace is what verification needs.

**Evidence:** `docs/reviews/security-reviewer-review-2026-10-07-build-loop-u2a4.md:40-55`

---

## Claim 20: truthrule comment: "and case for a path holding an upper-case letter (a caller that did not lower it). Each caller words the words and adds its own rules (docs/thoughts/ is the floor's only: a living doc an in-cycle fix may edit). ... Run both in the caller's shell: they set TRUTH_WHY."

**Location:** `scripts/lib/dev-cycle-read.sh:971-981`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers truthrule's arms and the docs/thoughts split; the `case` arm is unreachable from today's callers (Claim 7).

The arm is `elif [[ "$lp" == docs/thoughts/* ]]; then FLOOR_WHY="a record later runs read as truth"` (`:1046`), and truthrule has no thoughts arm (`:982-992`). The existing table test runs `--check-fix docs/thoughts/t.md` and expects `ok docs/thoughts/t.md` (`test/scripts/build-loop-check.bats:1123-1124`); it passed.

**Evidence:** `scripts/lib/dev-cycle-read.sh:971-992`, `:1046`, `test/scripts/build-loop-check.bats:1104-1125`, `/tmp/u2a4i2-factcheck-dAwk/logs/blc.log`

---

## Claim 21: floor comment: "(plan D5 items 1-4)"; "$3 the diff-tree status letter alone (R for R100; only A makes a review the brief's own)"

**Location:** `scripts/lib/dev-cycle-read.sh:1019-1023`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers ownfile's use of `$3`; does not check plan D5's numbering beyond the rubric's C14 cell.

`[[ "$3" == A && "$1" == docs/reviews/* && "$b" != */* && ( "$b" == "$2.md" || "$b" == *"-$2.md" ) ]]` (`:1014`): only `A` lets a review count as the brief's own, and the working-doc arm ignores `$3` (`:1013`). Passing `R100` would compare unequal to `A`, which is the same as R, so "letter alone" is advice and does not change behaviour for reviews.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1006-1015`, `:1019-1023`

---

## Claim 22: `--check-fix` header: "an instruction or prompt file, or a file one names after an @"

**Location:** `scripts/dev-cycle.sh:53-54`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the header against check_fix's truthrule/truthwalk arms; the per-line skip wording (rubric C10, kept) is pinned by `test/scripts/dev-cycle.bats:1027-1097`.

The `instr` arm is isstart, which covers prompt files, and the tree walk starts from prompt files too (`:841`). check_fix refuses on any truthrule word (`[[ -n "$TRUTH_WHY" ...`, `scripts/dev-cycle.sh:178`) and on `truthwalk tree` (`:180`).

**Evidence:** `scripts/dev-cycle.sh:53-54`, `:171-183`, `test/scripts/dev-cycle.bats:1027`

---

## Claim 23: Override row 463 (edited): "`isstart` ... adds `.md` files under `.claude/{commands,agents,output-styles}/` ...; a prompt's names also resolve against the directory holding its `.claude/` and the top level ... `agents/` and `output-styles/` are an untraced superset."

**Location:** `docs/reviews/override-log.md:463`
**Type:** Staleness
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the row's account of the code at HEAD; the row's new parenthetical about the tree walk skipping a symlinked prompt start is Verified (Claim 12).

The row was edited in this range, but its account of the design predates iteration 1's fixes. The code now also starts from `skills/` (`:484`), resolves against every separated enclosing `.claude/`'s directory (`prompt_bases`), and counts `skills/` in the untraced superset (`:481-482`). As a record of what d7cdc1ea fixed, it is accurate. As a description of the code at HEAD, it is two fixes behind. Rows 468-477 record the follow-ups.

**Evidence:** `docs/reviews/override-log.md:463`, `scripts/lib/dev-cycle-read.sh:476-502`

---

## Claim 24: Override rows 462, 468, 475, 477-479 (factual parts)

**Location:** `docs/reviews/override-log.md:462`
**Type:** Reference / Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Row 462 "(3,092 of 3,097 ...)": Verified for d7cdc1ea (`git ls-tree -r` gives 3,097 with 5 whitespace names). Row 468 "No prompt file is tracked here": Verified (`git ls-files | grep -iE '(^|/)\.claude/'` is empty). Row 475 "truthrule empties TRUTH_WHY when it passes": Verified (`TRUTH_WHY=""` first, `:983`). Row 477 "prompt_bases now returns one list of bases": Verified. Row 478: Verified, since d861183d's message holds "All 7 fail on main's code." and c934adbc's "over this repo's 3,092 tracked paths". Row 479's split is the Mostly accurate part. Rows 469-471's timings were not re-measured: they match the performance report's figures (13,536 ms / 3,877,660 bytes; 7.4 ms and ~98 ms per path; 400 commands 10.4 s) at `docs/reviews/performance-reviewer-review-2026-10-07-build-loop-u2a4.md:59,108,148,158`.

Row 479 says "381 code lines at pr-prep step 1a and 443 after iteration 1's fixes (tests 41, lib and dev-cycle.sh 21 lines net of the fixes)". `git diff --numstat main...d7cdc1ea -- . ':!docs'` gives 9+11, 167+37 and 157+0, which is 381. Against HEAD it gives 10+12, 189+38 and 194+0, which is 443. Both totals are right. Measured against main, though, the 62-line growth is 37 in tests (194−157) and 25 in the scripts (249−224). The 41 is this range's own test churn (39+2), and 21 is just 62−41. The 41/21 split mixes the two bases.

**Evidence:** `docs/reviews/override-log.md:462-479`, `scripts/lib/dev-cycle-read.sh:983`, git numstat output (paraphrased — no quote available because it is command output, reproduced inline above)

---

## Claim 25: Commit 03be719e: "Tests: build-loop-check 78/78, build-loop-read 19, dev-cycle 78, fixture-git-env 2, fixture-hermeticity 2, hermeticity-lint 53; shellcheck -S warning clean"

**Location:** commit 03be719e message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers these six suites and shellcheck on the two scripts at HEAD (= 03be719e) in this sandbox; does not cover the other suites.

`bats --count` gives 78, 19, 78, 2, 2 and 53. Every suite ran with exit 0 (ok/not ok: 78/0, 19/0, 78/0, 2/0, 2/0, 53/0). `shellcheck -S warning scripts/dev-cycle.sh scripts/lib/dev-cycle-read.sh` exited 0. Runs started at 2026-10-08T06:47:59Z (build-loop-check) and 06:51:11Z (the others).

**Evidence:** `/tmp/u2a4i2-factcheck-dAwk/logs/blc.log`, `/tmp/u2a4i2-factcheck-dAwk/logs/dc.log`, `/tmp/u2a4i2-factcheck-dAwk/logs/build-loop-read.log`, `/tmp/u2a4i2-factcheck-dAwk/logs/fixture-git-env.log`, `/tmp/u2a4i2-factcheck-dAwk/logs/fixture-hermeticity.log`, `/tmp/u2a4i2-factcheck-dAwk/logs/hermeticity-lint.log`, `/tmp/u2a4i2-factcheck-dAwk/logs/shellcheck.log`

---

## Claim 26: Commit 03be719e: "--check-fix still identical to main's over 3,092 paths"; "The unit grew from 381 to 443 code lines"

**Location:** commit 03be719e message
**Type:** Behavioral / Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers branch-vs-main `--check-fix` output over every whitespace-free tracked path at 03be719e, and the line count; does not cover the five whitespace names.

At 03be719e, 3,103 paths are tracked and 5 hold whitespace, so 3,098 are whitespace-free. The six iteration-1 reports were committed in ee5108bd, 12 seconds before 03be719e, so "3,092" is the d7cdc1ea file set. Over all 3,098, `bash scripts/dev-cycle.sh --check-fix $(cat paths.txt)` and main 7afdb8d2's copy (`git show main:scripts/...`, run from `$TMPDIR/mainsrc`) printed byte-identical output (`cmp`: IDENTICAL; 15 ok, 3,083 skip; both exit 0; 2026-10-08T06:50:43Z). So the conclusion holds and only the count is stale. The 381 → 443 figures match `git diff --numstat` (Claim 24).

**Evidence:** `/tmp/u2a4i2-factcheck-dAwk/paths.txt`, `/tmp/u2a4i2-factcheck-dAwk/logs/cf-branch.txt`, `/tmp/u2a4i2-factcheck-dAwk/logs/cf-main.txt`

---

## Submitted Claims

## Claim 27: "emit's quote strip: recursion terminates; the work charge still bounds a line of many `"`"

**Submitted by:** orchestrator brief (checks to run, item 2)
**Location:** `scripts/lib/dev-cycle-read.sh:627-631`
**Type:** Performance / Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers runs of 100-600 `"` after an `@`, under this sandbox's awk (mawk 1.3.4 20200120), at HEAD and at d7cdc1ea; does not cover gawk or busybox awk.

The recursion does terminate. Each call strips one character, and the base case is `length(c) > 1` (`:631`). The work is charged before the recursion (`work += length(c); if (work > wmax) exit 3`, `:628`). The charge is now cubic in the run length, because each of the n prefixes recurses once per leading quote. Executed (`quotes.sh`, IMPORT_WORK_LEFT=50,000,000) at HEAD: n=200 cost 3,028,400, n=400 cost 22,776,800, n=450 cost 32,201,400. At d7cdc1ea the same lines cost 43,400, 166,800 and 210,150 (about 150× less at 450).

From n=500, mawk fails first with `awk: program limit exceeded: eval stack size=1024` (rc=1), before the work bound would have been reached (about n=520). At d7cdc1ea, n=500 and n=600 succeeded (258,500 and 370,200). Both endings fail the walk closed: floor refuses every path and --check-fix skips every path. However, one line of about 500 `"` after an `@` in any walked file (an instruction file or anything it imports) now fails the walk, and two lines of about 450 spend a whole walk's IMPORT_WORK_MAX. Before this change, such text cost under 1% of the budget. The precise version: "the charge bounds it, but it grows cubically, and under mawk the recursion depth (about 490 quotes) ends the parser first; both fail closed".

**Evidence:** `scripts/lib/dev-cycle-read.sh:627-640`, `:562-570`, `/tmp/u2a4i2-factcheck-dAwk/quotes.sh`, `/tmp/u2a4i2-factcheck-dAwk/logs/quotes.log` (HEAD, 2026-10-08T06:49:29Z, exit 0), `/tmp/u2a4i2-factcheck-dAwk/logs/quotes-d7.log` (d7cdc1ea, 2026-10-08T06:52:54Z)

---

## Claims Requiring Attention

### Incorrect
- **Claim 1** (`scripts/lib/dev-cycle-read.sh:490-502`): prompt_bases drops the directory holding a `.claude/` that sits directly inside another `.claude/` (`a/.claude/.claude/commands/x.md` gives no `a/.claude` base). Both walks miss `@../docs/n1.md` from such a prompt (executed). This is an under-read with a narrow reach. Keep the slash in the strip (`${rest#*/.claude}`, `- 8`), or narrow the comment.
- **Claim 2** (`docs/reviews/code-review-rubric-...:41`, commit 03be719e, A5, plan U2a4 bullet, test title at `build-loop-check.bats:1182`): "every enclosing `.claude/`" is restated as fixed. The same exception applies.

### Mostly Accurate
- **Claim 8b** (rubric A6): the table is 3 × (10 basenames + 6 dirs × 3 tails × 2 cases) = 138 paths, not a five-way product, and 4 of the "instruction names" are negatives.
- **Claim 10** (plan U2b bullet; rubric C4 "lists its items"): the parenthetical leaves out contract items 6 and 8, item 1's "main found by name" and item 5's whole-branch refusal.
- **Claim 11** (plan F11): "its enclosing `.claude/` directories" should be "the directories holding its enclosing `.claude/`".
- **Claim 13** (lib header `:18`, truthwalk `:998`): truthwalk exits through need_root only for tree and main. An unknown WALK returns 0 without exiting, which is safe.
- **Claim 19b** (emit comment `:629-631`): a quoted name holding a space (which the 2.1.293 extractor captures) is not read. pathform blocks the direct case, and the transitive case is untraced.
- **Claim 23** (override row 463): it still describes the d7cdc1ea set (no `skills/`, a single enclosing `.claude/`).
- **Claim 24** (override row 479): the "tests 41, lib and dev-cycle.sh 21" split mixes this range's churn with the vs-main count (37 / 25). The totals are right.
- **Claim 26** (commit 03be719e): "3,092 paths" is the d7cdc1ea file set. At 03be719e there are 3,098 whitespace-free paths, and the output is identical over all of them.
- **Claim 27** (submitted, emit recursion): the work is charged, but it grows cubically, about 150× more at 450 quotes. Under mawk, from about 500 quotes the eval stack ends the parser before the work bound does. Both fail closed.

### Unverifiable
- **Claim 19c** (`:629-630`): that Claude Code's command expansion calls the quoted-mention extractor. Verifying it needs a caller trace in the 2.1.293 binary.

## Escalations

1. **Claim 1/2 (under-read, behavioral, High confidence):** prompt_bases misses the base for a doubled `.claude/.claude/`. The brief names under-reading as the failure class that matters. The reach is narrow (a prompt file in `X/.claude/.claude/{commands,agents,output-styles,skills}/`, read by a session started in `X/.claude/`). The fix is a one-character change to the strip plus the constant.
2. **Claim 27 (new fail-closed availability cost from fix A1, behavioral, High confidence):** one line of about 500 consecutive `"` after an `@` in any walked file now fails both walks (mawk eval-stack limit), so floor refuses everything and --check-fix skips everything. Before the change it cost 258,500 of 50,000,000. This is not an under-read, but it is new behavior the fix introduced, and no comment or override row records it.
