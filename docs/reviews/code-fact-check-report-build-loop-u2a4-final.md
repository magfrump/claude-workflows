Commit: 2b6f2f91

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u2a4 (branch `feat/build-loop-u2a4`, HEAD 2b6f2f91, main 7afdb8d2)
**Scope:** `git diff main...HEAD`: code comments in `scripts/lib/dev-cycle-read.sh` (the header's gate caller contract 1-8, isstart/prompt_dir/prompt_bases, the walk block comments, IMPORT_AWK, truthrule/truthwalk/floor/ownfile) and `scripts/dev-cycle.sh`; the test comments in `test/scripts/build-loop-check.bats`; commit messages `git log main..HEAD` (d861183d, c934adbc, d7cdc1ea, ee5108bd, 03be719e, a5ad8c08, 2b6f2f91); known issues A2 and A5; plan F11 and the U2a4/U2b bullets; the override-log rows dated 2026-10-07 for `feat/build-loop-u2a4` (462-480); the rubric's code claims. U2a4 final confirming pass: merged canonical report of replicates r1, r2 and r3.
**Checked:** 2026-10-08
**Total claims checked:** 58
**Summary:** 43 verified, 12 mostly accurate, 1 stale, 0 incorrect, 2 unverifiable
**Commit:** 2b6f2f91
**Replication:** k=3

Merge provenance. This report collates `docs/reviews/code-fact-check-report-build-loop-u2a4-final-r1.md` (34 claims), `-r2.md` (36 claims) and `-r3.md` (40 claims, numbered 1-40 with 38a/38b), all at `Commit: 2b6f2f91`, per `skills/code-review/SKILL.md` "Merging replicate verdicts (most-severe-wins)". Nothing here is new evidence: each claim carries the winning replicate's evidence, and every other replicate's caveats sit in `**Replicate annotations:**`. Where one replicate split a claim and another verdicted it as a whole, the merged report emits the finer rows, and the compound verdict is recorded on each row marked `(compound)`. All three replicates ran the suites at 2b6f2f91 and got build-loop-check 78/78, build-loop-read 19/19, dev-cycle 78/78, exit 0, with `shellcheck -S warning` clean on both scripts (r1 `/tmp/u2a4f-fcr1-fxUr/logs/`; r2 `/tmp/u2a4f-fc2-wXyc/logs/`; r3 `/tmp/u2a4f-fcr3-iU2i/`). r2 and r3 also ran fixture-git-env 2, fixture-hermeticity 2 and hermeticity-lint 53, all passing. Log paths inside claims are the reporting replicate's own. Every replicate read the hallucination-pattern log first, and none added an entry.

## Claims Requiring Attention

### Incorrect
None.

### Stale
- **Claim 36** (`scripts/lib/dev-cycle-read.sh:593-605`): the superset paragraph, which A5 and F11 call "the one statement" of the parser's rules, omits this branch's quoted run (`@"..."` read to the closing quote, blanks included, no `\ ` escape) and the further base directories (`ROOT_REAL/dirs[i]/name`, not only `ROOT_REAL/$1/name`). Both omissions under-describe an over-read. r1 Stale; r2 and r3 Mostly accurate (r2 also names the bases, r3 only the quoted run).

### Mostly Accurate
- **Claim 2** (`docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a4.md:24`; test comment `test/scripts/build-loop-check.bats:1188`): "a 2,000-quote line walks ok" holds for an instruction file, the tested case. In a prompt start the second base takes the output past IMPORT_OUT_MAX, and both walks fail closed, so the floor refuses every path (r2 only, executed; r1 and r3 Verified on the tested shape).
- **Claim 6** (`docs/reviews/override-log.md:463`): the untraced superset is agents/, output-styles/ and skills/. The row names only the first two (r3 only).
- **Claim 10** (`docs/reviews/override-log.md:478`; commit d861183d): this verdict comes from r1's compound verdict, whose defect is the c934adbc base half (Claim 51). On this half, r1 and r2 both confirmed that all 7 new tests fail on main's code.
- **Claim 11** (`docs/reviews/override-log.md:479`): 469 was the size at a5ad8c08. HEAD is 471 (2b6f2f91 added 2 comment lines), so the merge message should state 471 (all three).
- **Claim 13** (`docs/working/known-issues-dev-cycle.md:16`): A2 says "the main walk follows a symlinked instruction file". That holds only for one main stores; a checkout-only symlinked instruction file fails the main walk. Fails safe (r1 verdict; r2 and r3 Verified but scope-caveat the same case).
- **Claim 15** (`docs/working/known-issues-dev-cycle.md:18`; `scripts/lib/dev-cycle-read.sh:42-43`): "the one statement" holds for the numbered list, but the IMPORTED=, IMPORT_OUT_MAX/IMPORT_WORK_MAX and main_checkout comments still restate items 4 and 7, consistently (r2 only).
- **Claim 31** (`scripts/lib/dev-cycle-read.sh:490-494`): prompt_bases also adds the directory holding any component that begins `.claude` (`.claudex`, `.claude-x`, `.claude.x`, `.claude-old`) above a real `.claude/`, because `${rest#*/.claude}` matches a prefix. Over-read only (all three).
- **Claim 46** (`scripts/lib/dev-cycle-read.sh:1001-1006`): truthwalk also returns 0 with TRUTH_WHY=imported when isimported cannot lower-case PATH. Fails closed (r3 only).
- **Claim 50** (`scripts/lib/dev-cycle-read.sh:1059`): the floor's import reason says "an instruction file on the default branch". The importer may be a prompt file or a checkout-only start such as CLAUDE.local.md, and the test pins that wording for docs/private.md (r3 only, single-replicate).
- **Claim 51** (commit c934adbc): "stacked on main dfa75374". The parent is 7afdb8d2, a docs-only checkpoint with the same lib. Immutable (r1 only, single-replicate).
- **Claim 52** (commit a5ad8c08): "3,098 paths" is 03be719e's whitespace-free count. a5ad8c08's tree has 3,099, and identity holds at HEAD (all three).
- **Claim 53** (commit 03be719e): "3,092 paths" is not 03be719e's whitespace-free count (3,098), and the bases statement was false at 03be719e for a doubled `.claude/`. Settled by override row 480 (r1 only, single-replicate).

### Unverifiable
- **Claim 42** (`scripts/lib/dev-cycle-read.sh:669-670`): that Claude Code 2.1.293's command expansion calls the quote-accepting prompt-mention reader. Needs a caller trace in the binary (no egress) (r2, r3; r1 scoped it out).
- **Claim 58** (commit c934adbc): "health check passed". Needs `scripts/health-check.sh` run at c934adbc, routed to pr-prep step 5a by rubric C21 (r3 only, single-replicate).

---

## Claim 1: Rubric A6: "A table test compares the two over 138 paths: 3 depths × (10 basenames, 4 of them negatives, + 6 dirs × 3 tails × 2 cases)"

**Location:** `docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a4.md:66`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test's path count and its negatives. It does not establish that 138 paths cover every shape (r3 Claim 22 adds a 40,000-path fuzz and newline cases).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=— · r3=Verified
**Replicate annotations:** r1: "does not establish the rubric's severity calls"

The test builds `for d in "" a/ a/b/; do for n in CLAUDE.md claude.local.md Agents.MD agent.md GEMINI.md SKILL.md skills.md x.md x.txt claude.md.bak; do ps+=("$d$n"); done` and `for c in rules commands agents output-styles skills notes; do for t in x.md sub/X.MD x.txt; do ps+=("$d.claude/$c/$t" "$d.Claude/$c/$t")`. That gives 3 × (10 + 6·3·2) = 138. The negatives among the basenames are `skills.md x.md x.txt claude.md.bak`, which makes 4. The suite passed (r3 Claim 39; r1 `ok 76`).

**Evidence:** `test/scripts/build-loop-check.bats:1172-1180`; `/tmp/u2a4f-fcr3-iU2i/blc.out`; `/tmp/u2a4f-fcr1-fxUr/logs/build-loop-check.log`

---

## Claim 2: Rubric A7 author note and test comment: "A 2,000-quote line walks ok (tested)" / "A line of 2,000 quotes after an @ costs quadratic, not cubic, parser work: the walk passes."

**Location:** `docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a4.md:24`; `test/scripts/build-loop-check.bats:1188`
**Type:** Behavioral / Performance
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a 2,000-quote line in an instruction file (the tested case) and in a top-level `.claude/commands/` prompt; does not establish a work-bound failure (the failure seen is the output bound).
**Legibility-target:** for-author
**Replicate verdicts:** r1=Verified (compound) · r2=Mostly accurate · r3=Verified
**Replicate annotations:** r1: tests 76 and 77 (the prefilter test, and the quoted-mention / `c/.claude/.claude/` / 2,000-quote test) pass at HEAD; does not establish the rubric's severity calls · r3 (Verified, Medium): "Covers this line shape: one `@`, then 2,000 `"`. ... It does not cover lines with many `@`s, which are cubic in either run and stopped by the work bound (fail closed, pre-existing)" · r2: the prompt-start failure "is the class override row 469 (U2a4 i1 performance F2) already declined"; escalated (see Escalations 3)

r2's evidence (winning). The test puts the line in an instruction file only: `{ printf 'see @'; for ((i = 0; i < 2000; i++)); do printf '"'; done; printf '\n'; } > CLAUDE.md` (`:1189`). The same line in a prompt start fails both walks, so floor refuses every path. `probe5.sh` printed `instr tree ok`, `instr main ok`, `instr floor docs/x.md passes`, `prompt tree FAILED`, `prompt main FAILED`, `prompt floor docs/x.md: the default branch's instruction files could not be walked for @ imports`. A prompt adds bases: `prompt_bases` always seeds `pb_a=("")` (`:497`), so `.claude/commands/q.md` is read against `.claude/commands` and `""`. The unquoted run's 2,000 prefixes print about 2 MB per base, so two bases pass `IMPORT_OUT_MAX=4000000` (`:562`). `probe2.sh` on the parser alone: two bases, work `/6094844` (under the 50,000,000 work bound), rc=1, which points to the output bound. The fix A7 names (no cubic recursion) holds; the failure is closed. The claim holds for the case the test covers; for a prompt start it does not.

**Evidence:** `test/scripts/build-loop-check.bats:1188-1195`; `scripts/lib/dev-cycle-read.sh:495-503`, `:562`, `:677-686`; `/tmp/u2a4f-fc2-wXyc/logs/probe5.out`, `/tmp/u2a4f-fc2-wXyc/logs/probe2.out`

---

## Claim 3: Rubric R1 and A8: "Fixed ... Tested"

**Location:** `docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a4.md:18-25`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the passing tests named for R1 and A8; does not establish the rubric's severity calls.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=— · r3=— · single-replicate detection
**Replicate annotations:** none

Tests 76 and 77 (the prefilter test, and the quoted-mention / `c/.claude/.claude/` / 2,000-quote test) pass at HEAD (`ok 76`, `ok 77` in `logs/build-loop-check.log`).

**Evidence:** `test/scripts/build-loop-check.bats` (tests 76, 77); `/tmp/u2a4f-fcr1-fxUr/logs/build-loop-check.log` (`timeout 900 bats test/scripts/build-loop-check.bats`, exit 0, 07:08:35Z)

---

## Claim 4: The suites pass at HEAD (the rubric's and commits' "Tests:" lines, as executable guarantees)

**Location:** `docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a4.md:51`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers build-loop-check (78), build-loop-read (19), dev-cycle (78), fixture-git-env, fixture-hermeticity and hermeticity-lint (57 together), and shellcheck. It does not cover the full repo suite.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=— · r2=— · r3=Verified · single-replicate detection
**Replicate annotations:** none

Every suite exited 0, and the outputs hold no `not ok` lines (r3 Claim 38a).

**Evidence:** `/tmp/u2a4f-fcr3-iU2i/blc.out`, `/tmp/u2a4f-fcr3-iU2i/blr.out`, `/tmp/u2a4f-fcr3-iU2i/dc.out`, `/tmp/u2a4f-fcr3-iU2i/fx.out`

---

## Claim 5: Override row 462: "--check-fix over this repo's tracked paths is identical to main's (3,092 of 3,097: the comparison skips the five names holding whitespace)"

**Location:** `docs/reviews/override-log.md:462`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers byte-identical `--check-fix` stdout from main's `dev-cycle.sh` and lib (extracted with `git show main:...`) and HEAD's, over all 3,104 tracked paths at HEAD (the five whitespace names included) plus 17 synthetic paths; does not establish identity in a checkout that holds tracked prompt or rules files (this repo has none), where the tree walk now has more starts by design.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: "does not establish identity at c934adbc's own code (not re-run there)"; at c934adbc `git ls-tree` lists 3,097 paths, 5 with whitespace · r3: "the 3,092/3,097 figures describe c934adbc's tree, not HEAD's"; r3's run covered the 3,099 whitespace-free paths at HEAD, not the five whitespace names; c934adbc's tree holds 3,092 whitespace-free paths

r2's evidence (tie on Verified; r2's Scope is the most specific). `cmp.sh` ran main's copy and HEAD's over the same 3,121 arguments and printed `main rc=0`, `head rc=0`, `IDENTICAL` (16 `ok`, 3,105 `skip`). r3's independent run over the 3,099 whitespace-free paths also gave IDENTICAL (15 `ok`, 3,084 `skip`), and r1's over 3,121 arguments gave IDENTICAL.

**Evidence:** `scripts/dev-cycle.sh:166-184`; `/tmp/u2a4f-fc2-wXyc/logs/cmp.log`, `/tmp/u2a4f-fc2-wXyc/main.out`, `/tmp/u2a4f-fc2-wXyc/head.out`

---

## Claim 6: Override row 463: "`isstart` ... adds `.md` files under `.claude/{commands,agents,output-styles,skills}/` at any depth (and gives the tree walk `.claude/rules/`); ... a prompt start main stores as a symlink fails the main walk ... `agents/` and `output-styles/` are an untraced superset."

**Location:** `docs/reviews/override-log.md:463`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the start set, the tree walk gaining rules/, and the symlinked-prompt failure. It does not establish that Claude Code expands `@` in any of agents/, output-styles/ or skills/.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Mostly accurate
**Replicate annotations:** r1: "does not establish the rows' disposition choices (Fixed / Defer), which are settled decisions" · r2: "does not establish Claude Code's own behaviour for agents/output-styles/skills (the row itself says 'untraced superset'), and the bases are a superset (Claim 24)"

r3's evidence (winning). Everything the row says about the code holds. Main's prefilter had no `.claude/` term (`git show main:scripts/lib/dev-cycle-read.sh`, line 693). HEAD has `PROMPT_DIR='(^|/)\.claude/(commands|agents|output-styles|skills)/'` (`:484`), and a probe showed a checkout-only symlinked prompt failing the main walk. The imprecision is in the untraced list. The lib's own comment names three untraced directories: "the other three are untraced, read as a superset" (`:481-482`). The rubric's A2 says skills/ was added "(an untraced superset)". The row names only agents/ and output-styles/. The precise version: "`agents/`, `output-styles/` and `skills/` are an untraced superset."

**Evidence:** `docs/reviews/override-log.md:463`, `scripts/lib/dev-cycle-read.sh:476-485`, `docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a4.md:62`

---

## Claim 7: Override rows 464-467: "`truthwalk` owns the order for both callers; ... check_fix lower-cases through the lib's `lower` and refuses with a reason when tr fails (tested)"; "Both walks pop by index"; "The floor itself never calls pathform or main_entry, and its dot rule refuses `.github/x.yml` (tested)"; "The floor words a failed walk as one reason and does not call main_entry."

**Location:** `docs/reviews/override-log.md:464-467`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers floor's body (no pathform or main_entry call), its `.github/x.yml` wording, and the failing-tr test; does not establish U2b/U2c's ordering, which has no caller yet.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1: "does not establish the rows' disposition choices (Fixed / Defer), which are settled decisions"; r1's compound (rows 463-466) also covered "a symlinked prompt start fails the main walk and the tree walk skips it" (probe 3: `main docs/p.md: [walk]`, `tree docs/p.md: - []`) · r3: "does not establish the deferred items' revisit triggers"

r2's evidence (tie on Verified; most specific Scope). `sed -n '/^floor() {/,/^}/p' ... | grep -c 'pathform\|main_entry'` → `0`. `probe4.sh` printed `REFUSE .github/x.yml: a dotfile or a path under a dot-directory` and `main_entry .github/x.yml: badform`. The tests are at `test/scripts/build-loop-check.bats:1045` (`.github/x.yml "$DOT"`) and `:1086-1091` (a failing `tr` → `skip docs/b.md: the path could not be lower-cased; file it instead`). Both walks pop by `f="${queue[qi]}"; qi=$((qi + 1))` (`:857`, `:919`; r1, r3).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1039-1061`; `scripts/dev-cycle.sh:176`; `/tmp/u2a4f-fc2-wXyc/logs/probe4.out`

---

## Claim 8: Override row 468: "The tree walk skips a symlinked prompt start (`inrepo_here`), so --check-fix answers ok for a doc only that command names, while the floor fails closed ... No prompt file is tracked here."

**Location:** `docs/reviews/override-log.md:468`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a symlinked prompt start that exists only in the checkout, and this repo's tracked set. It does not establish behaviour for a symlinked rules/ start; rules/ is not PROMPT_DIR, and main follows those links.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=— · r2=— · r3=Verified · single-replicate detection
**Replicate annotations:** none

Probe `probes/walks.sh` added `.claude/commands/l.md -> ../../docs/t.md` (t.md holds `@z.md`) to a fixture after a successful walk, then called `import_reset`. Output: `after checkout prompt link: main walk failed; tree walk ok` and `tree docs/z.md: -`. The tree walk requires `inrepo_here "$f"` (`:849`), and main_checkout refuses a non-plain path with `plaindir "$c" || return 1` (`:834`). `git ls-files -z | instruction_names | grep -i '\.claude/'` printed nothing.

**Evidence:** `scripts/lib/dev-cycle-read.sh:845-852`, `:832-836`, `/tmp/u2a4f-fcr3-iU2i/walks.out`

---

## Claim 9: Override rows 473, 475, 477: "floor run before resolve_main words its refusal as a walk failure"; "truthrule empties TRUTH_WHY when it passes"; "prompt_bases now returns one list of bases"

**Location:** `docs/reviews/override-log.md:473`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the three code statements (rows 473, 475, 477). It does not establish the rows' dispositions.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=— · r2=— · r3=Verified · single-replicate detection
**Replicate annotations:** none

Before resolve_main, `main_imports` returns at `main_by_name || return 1` (`:892`). truthwalk then returns 0 with `TRUTH_WHY=walk`, and floor words it as `"the default branch's instruction files could not be walked for @ imports"` (`:1058`). The test "No default branch found by name" pins this. truthrule opens with `TRUTH_WHY=""` (`:991`). prompt_bases sets one array (`:495-503`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:889-892`, `:990-1011`, `:1057-1059`, `test/scripts/build-loop-check.bats:1097-1102`

---

## Claim 10: Override row 478 and commit d861183d: "All 7 fail on main's code"

**Location:** `docs/reviews/override-log.md:478`
**Type:** Behavioral / Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the red run of d861183d's seven tests against its parent's lib. It does not establish why each test failed beyond the first-seen reason: override row 478 already records a fixture error in test 6.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Mostly accurate (compound) · r2=Verified · r3=—
**Replicate annotations:** merge note: r1 verdicted this and c934adbc's "stacked on main dfa75374" (Claim 51) as one compound, and its Mostly accurate rests on the base half; on this half r1 wrote "The lib is identical, so the code claim holds" · r2: "does not re-establish *why* test 6 failed (the row records a fixture error, iteration 1 Claim 29)"

r1's evidence (winning, compound). `git archive d861183d` was extracted to `$T/d86`, and `bats -f U2a4 test/scripts/build-loop-check.bats` gave `not ok 1`..`not ok 7`, exit 1, failing with `floor: command not found` among other errors. r2 independently ran the full file in an export of d861183d: `not ok` for tests 69-75 only, 68 `ok` (`/tmp/u2a4f-fc2-wXyc/logs/red-d861183d.tap`). The compound's defect is the base (Claim 51).

**Evidence:** `/tmp/u2a4f-fcr1-fxUr/logs/d86-u2a4.log` (`timeout 600 bats -f 'U2a4' test/scripts/build-loop-check.bats`, cwd `/tmp/u2a4f-fcr1-fxUr/d86`, exit 1); `/tmp/u2a4f-fc2-wXyc/logs/red-d861183d.tap`

---

## Claim 11: Override row 479: "iteration 2's fixes ... took the unit to 469; no part splits off without the rest it fixes, so the unit lands whole and the merge message states the size."

**Location:** `docs/reviews/override-log.md:479`
**Type:** Configuration (measured value)
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the changed code lines (`git diff --numstat main...<c> -- scripts test`) at each commit; does not establish which count the merge message will carry.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r2+r3: "does not establish which counting rule decision log 62 uses/intends"; both confirm the row's "37 test lines and 25 lib and dev-cycle.sh lines" (test 157→194, scripts 224→249) · r3 measured outside `docs/` (`-- . ':!docs'`) with the same totals · r2: the same figure appears in commit a5ad8c08 ("469 code lines against main (381 at step 1a)"), correct at that commit · all three: escalated for the merge message (see Escalations 1)

r1's evidence (three-way tie; r1 is lowest). The counts are exact at the commits they name: c934adbc 333 + 48 = 381, 03be719e 393 + 50 = 443, and a5ad8c08 411 + 58 = 469. At HEAD the count is `10 12 scripts/dev-cycle.sh`, `205 46 scripts/lib/dev-cycle-read.sh` and `198 0 test/scripts/build-loop-check.bats`, which is 471. 2b6f2f91 added two comment lines (`+    # such a name can match a real file, which the floor then refuses (pathform` / `+    # already refuses it to --check-fix).`). The merge message's size should be 471, or should say that 469 was measured at a5ad8c08.

**Evidence:** `git diff --numstat main...HEAD -- scripts test`; `git show 2b6f2f91 -- scripts`; `docs/reviews/override-log.md:479`

---

## Claim 12: Override row 480: "Re-run at 03be719e over 3,098 paths: identical."

**Location:** `docs/reviews/override-log.md:480`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the path count of 03be719e's tree. It does not re-run the comparison at 03be719e; the identity was re-run at HEAD (Claim 5).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=— · r2=— · r3=Verified · single-replicate detection
**Replicate annotations:** none

`git ls-tree -r --name-only 03be719e | grep -vc '[[:space:]]'` gives 3098.

**Evidence:** `docs/reviews/override-log.md:480`

---

## Claim 13: Known issue A2: "The tree walk skips a symlinked start file, instruction or prompt (`inrepo` drops it), so an import from one passes `--check-fix`; the main walk follows a symlinked instruction file and fails on a symlinked prompt, so the floor refuses."

**Location:** `docs/working/known-issues-dev-cycle.md:16`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both walks on a symlinked instruction file and a symlinked prompt, main-stored and checkout-only. It does not establish behavior under a symlinked directory, which is A5's not-covered list.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Verified · r3=Verified
**Replicate annotations:** r2 (Verified): "does not cover a symlinked start that only the checkout holds, which `main_checkout` refuses (`:832-834`), so the main walk fails rather than follows. The floor still refuses." · r3 (Verified): "A checkout-only symlinked instruction file also fails the walk instead of being followed: main_checkout answers 1, and the floor still refuses. And the tree walk's check is `inrepo_here`, the need_root-free form of `inrepo`." · r3: a prompt always has at least the top-level base (`pb_a=("")`, `:497`), so the symlink arm always refuses a prompt

r1's evidence (winning). The tree walk drops both kinds: `if ! isstart "$lp" || ! inrepo_here "$f"; then continue; fi` (`:849`). The main walk follows a main-stored symlinked instruction file: probe 4 gives `docs/t.md [imported]` through `sub/CLAUDE.md -> ../docs/inst.md`. A checkout-only symlinked instruction file is not followed, though. main_checkout answers 1 for it (`plaindir "$c" || return 1`, `:834`), so the walk fails: probe 3 gives `main docs/t.md: [walk]` for the checkout-only `sub2/CLAUDE.md` link. The precise version: "the main walk follows a symlinked instruction file main stores and fails on any other symlinked start (a prompt main stores, or any checkout-only one)". Either way the floor refuses, so the error is on the safe side.

**Evidence:** `scripts/lib/dev-cycle-read.sh:810-837,849,926-928`; `/tmp/u2a4f-fcr1-fxUr/logs/probe3.log`, `/tmp/u2a4f-fcr1-fxUr/logs/probe4.log`

---

## Claim 14: Known issue A5's U2a4 sentences: `isstart`'s files start both walks (instruction files and `.md` under `.claude/` rules/commands/agents/output-styles/skills at any depth); "resolved against the top level and every enclosing `.claude/`'s directory as well as their own, a quoted `@"name"` read without its quote ..., and fails the main walk on one main stores as a symlink"

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the start set, the bases (the top level and every enclosing `.claude/`'s directory are all present), the quoted read and the symlink rule; does not establish that only those bases are added (Claim 31's superset) or Claude Code's behaviour for the three untraced directories.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r1: verdicted the bases "as a lower bound: 'against X'"; "does not establish that the bases are only those (see Claim 15 for an extra base)" · r3: "does not cover the extra bases noted in Claim 27, which only over-read"

r2's evidence (tie on Verified; r2 is the atomic claim). In `probe1.out`, `a/.claude/.claude/.claude/commands/x.md -> [] [a] [a/.claude] [a/.claude/.claude]`: each enclosing `.claude/`'s directory is present. r1: tests 73, 74 and 77 pass in both walks; the quoted read is `if (substr(line, i + 1, 1) == "\"") names(line, i + 2, L, 1)` (`:674`). r3: walks.sh showed both walks resolving `c/.claude/.claude/commands/y.md`'s `@q.md` to `c/.claude/q.md`, `c/q.md`, `q.md` and the file's own directory, and `@"docs/s p.md"` reaching `docs/s p.md`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:476-503`; `/tmp/u2a4f-fc2-wXyc/logs/probe1.out`; `/tmp/u2a4f-fc2-wXyc/logs/build-loop-check.tap`

---

## Claim 15: "the lib header's numbered gate caller contract, U2a4, is the one statement of what a caller owes the walk and the floor" (the header: "the one statement of it; plan step 5's U2b bullet and known issue A5 point here")

**Location:** `docs/working/known-issues-dev-cycle.md:18`; `scripts/lib/dev-cycle-read.sh:42-43`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the plan's U2b bullet and A5 now point to the header and no longer copy it, and that the other lib comments agree with it; does not establish that the header is the only place the duties are written.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Verified (compound) · r2=Mostly accurate · r3=Verified (compound)
**Replicate annotations:** r1: "The plan U2b bullet and F11 point to the header ..., and nothing else restates the duties" · r3: the header's items 1 (LC_ALL=C), 2 (clean worktree, stderr, git environment), 4 (cache) and 5 (floor before main_entry) carry exactly the topics A5 lists (`:44-62`)

r2's evidence (winning). The plan no longer restates the duties: U2b "keeps every item of the lib header's numbered gate caller contract (U2a4; the one statement of these duties, not restated here)" (`docs/working/plan-build-loop-handoff.md:279`). Inside the lib, three comments still state item 4's and item 7's duties in their own words, all consistent with the header: `:545-548` ("a caller whose checkout may have changed ... sets IMPORTED_MAIN_DONE="" to walk again ... A caller that changes HOME clears both IMPORTED_DONE and IMPORTED_MAIN_DONE"), `:560-561` ("A caller that changes it clears IMPORTED_DONE and IMPORTED_MAIN_DONE before walking again"), and `:800-801` ("a MEMO serves one walk and one ENT. main_imports calls it only for paths main lacks."). "The one statement" is accurate for the numbered list. The cache duty is still also spelled as a raw assignment rather than `import_reset`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:42-68`, `:543-555`, `:560-561`, `:569-570`, `:793-809`; `docs/working/plan-build-loop-handoff.md:279`

---

## Claim 16: Plan F11: "the caller contract is the lib header's numbered list (U2a4)"; gap "a prompt file read by a session started outside the top level and the directories holding its enclosing `.claude/` directories"; "one start rule (`isstart`: ...) ... a quoted `@"name"` is read without its quote, and a prompt start main stores as a symlink fails the walk"

**Location:** `docs/working/plan-build-loop-handoff.md:126`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the code facts F11 states; does not establish the untraced Claude Code behaviour behind them.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: "does not establish F11's 'partly' rating" · r3: "does not cover the pre-existing U2a3/U2a3c text, which earlier passes checked"; `PROMPT_DIR` excludes rules/, so rules/ files resolve only against their own directory, consistent with "a command's names"

r2's evidence (tie; r2's Scope chosen). Same code and runs as Claims 13, 14 and 29-39. The gap wording matches the lib's own Not-covered line: "a prompt read by a session started outside prompt_bases' directories" (`:539-540`). r1: the contract is at `:41-68`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:476-503`, `:536-541`; `/tmp/u2a4f-fc2-wXyc/logs/probe1.out`

---

## Claim 17: Plan U2a4 bullet: "Built 2026-10-07: `truthrule` ... and `truthwalk` (walk, then isimported), which check_fix and floor both call; `isstart` for both walks, ...; the index queue pop (row 461); the lib header's numbered gate caller contract (row 459). ... `IMPORTED_MAIN_WHY` (row 376) moves to U2c."

**Location:** `docs/working/plan-build-loop-handoff.md:278`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers callers and the listed pieces; does not establish U2c's future work.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r3: "does not establish the deferral of IMPORTED_MAIN_WHY (a decision)"; rows 459 and 461 are the U2a3c caller-contract and queue-pop rows

r1's evidence (tie; lowest). floor calls `truthrule "$lp"` (`:1044`) and `truthwalk main "$lp"` (`:1057`). check_fix calls both (`scripts/dev-cycle.sh:177,180`). The walks test `isstart "$lp"` (`:849`) and `isstart "$f"` (`:908`). r2: both walks pop by index (`:857`, `:919`), and `IMPORTED_MAIN_WHY` appears nowhere in `scripts/`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:849,908,1039-1061`; `scripts/dev-cycle.sh:177-180`

---

## Claim 18: Plan U2b bullet: "keeps every item of the lib header's numbered gate caller contract (U2a4; the one statement of these duties, not restated here), and builds item 3's refusal (A5): a checkout where `git check-attr` shows a `working-tree-encoding`, `filter` or `ident` attribute on any path the walk reads, or whose `core.symlinks` is false"

**Location:** `docs/working/plan-build-loop-handoff.md:279`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the pointer and item 3's match with the header; does not establish U2b's design.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

Header item 3 is `Refuse a checkout whose core.symlinks is false or with a working-tree-encoding, filter or ident attribute on any path the walk reads ... U2b builds this; the walk does not check it.` (`:51-54`). The bullet's restatement of item 3 is the build target and matches it. `rg "check-attr|core.symlinks"` in the lib finds only the comment at `:51` (r2 and r3: the same over `scripts/*.sh`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:51-54`

---

## Claim 19: --check-fix header: "(not ... a dot-directory or dotfile, an instruction or prompt file, or a file one names after an @, read broadly; compared ignoring case)"; check_fix comment: "The denials it shares with the self-merge floor are the lib's truthrule."

**Location:** `scripts/dev-cycle.sh:50-54`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers check_fix's use of truthrule and truthwalk and its output for prompt, dot and mixed-case paths; does not establish that every truthrule word gets its own message (only `cycle` does, by design: override row 475).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: "does not establish that the in-cycle skip line names prompt files (it does not, which override row 475 records)" · r3: "does not cover a symlinked prompt start, which the tree walk skips (A2, Claim 5)"

r2's evidence (tie; r2 executed). The synthetic `docs/.claude/commands/x.md`, `.claude/rules/a.md` and `Readme.MD` rows in Claim 5's run give identical skip/ok lines on main and HEAD. check_fix calls `truthrule "$lp"` (`:177`) and `truthwalk tree "$lp"` (`:180`); truthrule's `instr` is isstart, which takes in prompt files (r1).

**Evidence:** `scripts/dev-cycle.sh:166-184`; `scripts/lib/dev-cycle-read.sh:990-1000`; `/tmp/u2a4f-fc2-wXyc/head.out`

---

## Claim 20: check_fix's output equals main's for every tracked path (commit messages c934adbc, 03be719e, a5ad8c08; rubric; override rows 462, 480)

**Location:** `scripts/dev-cycle.sh:171-184`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers byte-identical `--check-fix` output from main's dev-cycle.sh and lib against HEAD's, over all 3,104 tracked paths, whitespace names included, plus 17 probe paths. Does not establish identity where a tracked prompt file or an @ import of a tracked doc exists: this repo has neither (`git ls-files .claude` is empty, and no output line is an "after an @" skip), so the walk half compares two empty import sets here; fixture tests 73/77 cover that half.
**Legibility-target:** for-automated-gate
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r2: "does not establish identity in a checkout that holds tracked prompt or rules files ..., where the tree walk now has more starts by design" · r3: "does not establish identity for prompt files (none is tracked) or for the five whitespace names"

r1's evidence (tie; lowest, with the most specific Scope). `cf.sh` ran `bash $T/main/scripts/dev-cycle.sh --check-fix "${P[@]}"` and `bash scripts/dev-cycle.sh --check-fix "${P[@]}"` over 3,121 arguments. Both exited 0, and `cmp` printed `IDENTICAL`. By reading: the new `truthrule "$lp" && [[ "$TRUTH_WHY" == cycle ]]` matches the old `writable "$a" || writable "$lp"` (a writable path is never a start or dot path, and `lp` is lower-case so `case` never fires). Every other truthrule word goes to the same prose skip line as the old `||` chain (`:177-178`). r2 adds: "The order cannot hide a word check_fix maps. No writable path is an instruction or dot path."

**Evidence:** `scripts/dev-cycle.sh:171-184`; `/tmp/u2a4f-fcr1-fxUr/logs/cf-run.txt`, `/tmp/u2a4f-fcr1-fxUr/logs/cf-main.txt`, `/tmp/u2a4f-fcr1-fxUr/logs/cf-head.txt`

---

## Claim 21: Header: "inrepo, dirok, skipped, check_brief, isimported, truthwalk (for tree or main), floor and the import walks exit 1 (need_root) unless ROOT_REAL is set, is the current directory and is a repository's top level"

**Location:** `scripts/lib/dev-cycle-read.sh:17-19`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers floor, truthwalk tree/main and truthwalk with an unknown WALK; does not re-check the pre-existing members (inrepo, dirok, skipped, check_brief).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "`exit` inside a function called from an `if`/`elif` condition still ends the shell (paraphrased ...; floor's `elif truthwalk main` at `:1058` relies on it)"

r1's evidence (tie; lowest). floor starts `local lp` / `need_root` (`:1040-1041`). truthwalk is `case "$1" in main) main_imports || return 0 ;; tree) imported_names || return 0 ;; *) return 0 ;; esac` (`:1009`), and both walks call `need_root`. With ROOT_REAL unset, `floor docs/x.md s M` and `truthwalk tree docs/x.md` each printed `dev-cycle-read.sh: ROOT_REAL is not set ...` and exited 1, and `truthwalk bogus` returned `0 [walk]` without exiting. r3 reproduced it (`bogus rc=0 why=walk (no ROOT_REAL, no exit)`; the `truthwalk tree` subshell exited 1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:127-131,1007-1011,1039-1041`; `/tmp/u2a4f-fcr1-fxUr/logs/probe1.log`, `/tmp/u2a4f-fcr1-fxUr/logs/probe3.log`

---

## Claim 22: Contract item 1: "Run as above, with main found by name, under LC_ALL=C (under a UTF-8 locale a non-UTF-8 name on main fails the walk)."

**Location:** `scripts/lib/dev-cycle-read.sh:44-45`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers main_imports' tree-record parse of a name holding byte 0xFF under C.UTF-8 vs C; does not establish every other locale-dependent test in the walks.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r3: "does not test other UTF-8 locales (en_US.UTF-8 is not installed here)"

r2's evidence (tie; most specific Scope). main_imports parses each record with `[[ "$rec" =~ ^([01234567]{6})\ ...\ [0123456789abcdef]{40,64}$'\t'(.+)$ ]] || return 1` (`:895`). `probe3.sh` with the same regex on `docs/a\xffb.md`: `LC_ALL=C.UTF-8 NOMATCH`, `LC_ALL=C MATCH`. main_by_name is required by `main_by_name || return 1` (`:892`). r1 ran the walk end to end: `C: main docs/a.md: [imported]`, `C.UTF-8: ... [walk]`, `C.utf8: ... [walk]`. r3: `C: ok`, `C.UTF-8: failed`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:885-899`; `/tmp/u2a4f-fc2-wXyc/logs/probe3.out`

---

## Claim 23: Contract item 2: "the walk reads main's blob for every path main stores, and the checkout only where main lacks a path), where git ls-files prints nothing on stderr (any fails the walk)"

**Location:** `scripts/lib/dev-cycle-read.sh:46-50`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the blob-first read and the stderr rule. It does not establish the git-environment list, which it hands to the caller.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1: "does not establish the git-environment list (a caller duty, not lib behavior)" · r2: "does not cover the tree walk's `tree_starts`, which does not test stderr (the contract is for floor and main_imports only)"

r3's evidence (tie on Verified; r3 executed it). In probe `probes/ancdiff2.sh`, CLAUDE.md on main imports docs/a.md. The fixture then ran `git rm --cached CLAUDE.md` and rewrote the file in the checkout to import docs/z.md. HEAD's floor refused docs/a.md and passed docs/z.md, so main's blob was read and the checkout copy was not. The code: `[[ -n "${ent[$f]+set}" ]] || cand+=("t:$f")` (`:903`), and `checkout_md` fails on any stderr: `{ e="$(md_ls --cached --others 2>&1 >&3)"; } 3>&1 && [[ -z "$e" ]]` (`:792`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:792`, `:902-911`, `:921-925`, `/tmp/u2a4f-fcr3-iU2i/ancdiff2.out`

---

## Claim 24: Contract item 4 and import_reset: "Call import_reset before each gate decision and after any checkout change (rows 372, 439), or when HOME, IMPORT_OUT_MAX or IMPORT_WORK_MAX changes: neither walk's cache key holds them."; "import_reset: the next call of either walk walks again (caller contract item 4)."

**Location:** `scripts/lib/dev-cycle-read.sh:55-57`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both cache keys and import_reset's effect (`:554-555`); does not establish the cost of calling it per decision.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1+r3: import_reset leaves IMPORT_HOME_DONE alone, which is right, because import_home re-keys on HOME itself (`key="x${HOME+set}:${HOME-}"`, `:718`) · r1 (items 4-8 compound): "does not establish that U2b/U2c will keep the duties: floor has no caller"

r2's evidence (tie; lowest among the atomic claims). `import_reset() { IMPORTED_DONE=""; IMPORTED_MAIN_DONE=""; }` (`:555`). Keys: `IMPORTED_DONE="$ROOT_REAL"` (`:843`) and `IMPORTED_MAIN_DONE="$MAIN_SHA $MAIN_BY_NAME $ROOT_REAL"` (`:891`). Neither holds HOME or either budget. `probe4.sh` printed `IMPORTED_MAIN_DONE before reset: 7afdb8d22df6...` and `after: '' ''`. The test at `test/scripts/build-loop-check.bats:1198-1210` (`c cached: -`, then `c: $IMP` after `import_reset`) passes.

**Evidence:** `scripts/lib/dev-cycle-read.sh:553-555`, `:841-843`, `:889-891`; `/tmp/u2a4f-fc2-wXyc/logs/probe4.out`

---

## Claim 25: Contract item 5: "Ask floor about each changed path, in this shell, before pathform or main_entry (so .github/x.yml is refused as a dotfile, not as badform) ... Floor item 5 (symlinks, gitlinks) and the brief's own Status change are the caller's rules."

**Location:** `scripts/lib/dev-cycle-read.sh:58-62`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `.github/x.yml` contrast and that floor reads no mode; does not establish any caller's order (none exists).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** none

r2's evidence (tie; lowest atomic). floor reads no mode and calls no main_entry (Claim 7). `main_entry .github/x.yml` → `badform`, `floor` → the dot wording (`probe4.out`). r1 and r3: `pathform` refuses `[.][gG][iI][tT]*` components (`:186`), while truthrule's `elif [[ "/$1" == */.* ]]; then TRUTH_WHY="dot"` (`:994`) runs first.

**Evidence:** `scripts/lib/dev-cycle-read.sh:302-319`, `:1039-1061`; `/tmp/u2a4f-fc2-wXyc/logs/probe4.out`

---

## Claim 26: Contract item 6: "Read a walk only through isimported or truthwalk: IMPORTED_MAIN=error reads as 'not imported' to a raw membership test (row 419)."

**Location:** `scripts/lib/dev-cycle-read.sh:63-64`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the error sentinel and the membership form isimported uses; does not establish that no future caller reads the list raw.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r3: "grep found only isimported doing so" (reading the lists raw)

r2's evidence (tie; lowest atomic). `IMPORTED_MAIN=error` (`:553`, `:891`). The membership test `[[ "$IMPORTED_MAIN" == *$'\n'"$lp"$'\n'* ]]` (`:974`) is false against `error`, which holds no newline. isimported runs `main_imports || return 0` first, so it answers imported on failure.

**Evidence:** `scripts/lib/dev-cycle-read.sh:553`, `:969-978`

---

## Claim 27: Contract item 7: "A second caller of main_checkout passes a fresh MEMO per walk and ENT, and only a PATH main lacks."

**Location:** `scripts/lib/dev-cycle-read.sh:65-66`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with main_checkout's own comment and main_imports' call sites; does not test a second caller (none exists).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r3: a MEMO hit breaks the bottom-up loop before any mode check above it: `if [[ -n "${mc_m[$c]+set}" ]]; then st="${mc_m[$c]}"; break; fi` (`:821`)

r2's evidence (tie; atomic). main_checkout's comment: "A MEMO hit skips that mode check too, so a MEMO serves one walk and one ENT. main_imports calls it only for paths main lacks." (`:800-801`). The calls are `[[ "${cand[i]:0:1}" == m ]] || main_checkout ent pok "$f"` (`:909`) and `[[ -n "${ent[$p]+set}" ]] || main_checkout ent pok "$p"` (`:957`), with `pok` local per walk (`:888`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:793-837`, `:888`, `:909`, `:957`

---

## Claim 28: Contract item 8: "Pass truthrule, isstart and ownfile a lower-cased path (floor and check_fix lower first; truthrule refuses an upper-case letter as case)."

**Location:** `scripts/lib/dev-cycle-read.sh:67-68`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers floor's, check_fix's and both walks' lower-casing before these calls, and the `case` word for ASCII upper case; does not cover non-ASCII upper case, which neither `tr` nor truthrule folds.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r3: "does not establish that ownfile's stem argument is lower-case; it comes from the brief name, which isbrief requires lower-case"

r2's evidence (tie; atomic). floor: `lp="$(lower "$1")" || {...}; if truthrule "$lp"` ... `ownfile "$lp" "$2" "$3"` (`:1042-1056`). check_fix: `lp="$(lower "$a")"` then `truthrule "$lp"` (`scripts/dev-cycle.sh:176-177`). The walks call `isstart` on `lower`/`lower_all` output (`:848-849`, `:904-908`). `probe4.sh`: `truthrule Docs/x.md -> case` (r1 and r3 the same).

**Evidence:** `scripts/lib/dev-cycle-read.sh:990-1002`, `:1039-1061`; `/tmp/u2a4f-fc2-wXyc/logs/probe4.out`

---

## Claim 29: isstart comment: "an instruction file's name, or a .md file at any depth under a .claude/ directory's rules/ ... or PROMPT_DIR's commands/, agents/, output-styles/ or skills/ ... truthrule refuses the same names; instruction_names is its grep prefilter, and a test holds the two equal"; instruction_names: "It matches isstart's names; isstart stays the authority."

**Location:** `scripts/lib/dev-cycle-read.sh:476-485`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers 40,000 generated paths (components drawn from start-relevant names, mixed case, a newline, DEL and a non-ASCII byte), 11 hand-built newline paths, and both walks calling isstart. It does not cover non-ASCII case folding; both sides are ASCII-only by design.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: 1,518 generated paths, `n=1518 starts=468`, `SAME`; "does not cover names holding a newline (both walks refuse them first)" · r2: 138-path table plus 39 odd names, one `DIFF` for `$'x/.claude/rules/y.md\n'` that is "the probe's artifact: `isstart "$(lower "$n")"` dropped the trailing newline"; "does not cover a name ending in a newline" · r2: rules files are not marked by `prompt_dir`, so they resolve against their own directory

r3's evidence (tie; widest probe). Probe `probes/fuzz.py` + `probes/fuzz.sh` printed `paths=40000 isstart=12741 prefilter=12741` and `SAME`. Newline cases such as `.claude/commands/a\nb.md` (both accept) and `x/y\nCLAUDE.md` (both refuse) agreed on all 11. truthrule's `elif isstart "$1"; then TRUTH_WHY="instr"` (`:993`) refuses the same set. The walks call `isstart "$lp"` (`:849`) and `isstart "$f"` (`:908`). The code: `isstart() { [[ "${1##*/}" =~ $INSTRUCTION_FILE ]] || [[ "$1" == *.md && ( "$1" =~ $PROMPT_DIR || "/$1" == */.claude/rules/* ) ]]; }` and the prefilter alternation `(^|/)\.claude/(rules|commands|agents|output-styles|skills)/.*\.md$` (`:764`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:485`, `:759-764`, `:849`, `:908`, `:993`, `/tmp/u2a4f-fcr3-iU2i/want.bin`, `/tmp/u2a4f-fcr3-iU2i/got.bin`

---

## Claim 30: prompt_dir: "for a start under PROMPT_DIR (LP lower-cased, PATH as spelled), MAP[PATH] gets LP, so a walk knows to read it against prompt_bases."

**Location:** `scripts/lib/dev-cycle-read.sh:486-489`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers prompt, rules and instruction inputs; does not cover imported (non-start) prompt files, which no walk marks.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r3: "does not establish that rules/ files get bases (they do not, by design: 'memory, whose names resolve against the file's own directory')"

r2's evidence (tie; executed). `probe1.out`: `M[a/.claude/skills/s/SKILL.md]=a/.claude/skills/s/skill.md`, `M[.claude/commands/x.md]=.claude/commands/x.md`, and no entry for `.claude/rules/x.md` or `CLAUDE.md`. r1: the tree walk calls `prompt_dir pdir "$lp" "$f"` (`:851`) and the main walk `prompt_dir pdir "$f" "${cand[i]:2}"` (`:909`); both pops run `[[ -z "${pdir[$f]+set}" ]] || prompt_bases xs "${pdir[$f]}" "$f"` (`:857`, `:919`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:489`, `:851`, `:857`, `:909`, `:919`; `/tmp/u2a4f-fc2-wXyc/logs/probe1.out`

---

## Claim 31: prompt_bases: "array NAME gets the directories a prompt start also resolves its names against ...: the top level and the one holding each .claude/ in its path (a nested one too: U2a4 i1 security F3), as PATH spells them, once each."

**Location:** `scripts/lib/dev-cycle-read.sh:490-494`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers prompt_bases over 9 shapes (top level, nested, doubled and tripled `.claude/`, mixed case, a component beginning `.claude` such as `.claudex` or `.claude-x`, `.claude/` under rules/) and a walk end to end. It does not establish whether Claude Code would start a session in such a directory.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r2: "This came with iteration 2's R1 fix: the earlier `#*/.claude/` strip matched only real ones"; "It costs budget, and Claim 1 shows budget can bind for prompts"; fix option "anchor the strip on `/.claude/`"; probes `a/.claude-old/b/.claude/skills/s/x.md -> [] [a] [a/.claude-old/b]` · r3: "does not establish that the extra bases described below are harmless beyond over-reading (more paths refused)"; "No .claude/ directory is dropped: `/.claude` cannot overlap itself"; probe `a/.claude.x/.claude/commands/y.md -> [] [a] [a/.claude.x]` · r2: "does not establish whether a session can start in the extra directories (the reader model is U2b's)"

r1's evidence (three-way tie; r1 lowest, with an end-to-end walk). The function, read whole: `prompt_bases() { local -n pb_a="$1"; local rest="/$2" n; pb_a=(""); while [[ "$rest" == */.claude/* ]]; do rest="${rest#*/.claude}"; n=$(( ${#2} - ${#rest} - 8 )); (( n <= 0 )) || pb_a+=("${3:0:n}"); done; }` (`:495-503`). The loop's guard needs `/.claude/`, but the strip `${rest#*/.claude}` takes the shortest prefix ending in `/.claude`, and that can end inside a longer component. For `a/.claudex/b/.claude/commands/x.md` it returns `[] [a] [a/.claudex/b]`, where `a` holds `.claudex`, not a `.claude/`. The same happens with `a/.claude-x/...`, which gives `[a]`. In a walk, `a/.claudex/b/.claude/commands/x.md` holding `@n.md` makes the floor refuse `a/n.md` as imported (`probe5.log`). Every other shape is exact and once each: `a/.claude/.claude/commands/x.md -> [] [a] [a/.claude]` and `A/.Claude/Commands/X.md -> [] [A]`. `n` strictly increases, so no base repeats. The extra base only reads more, which is the safe direction. The precise version: "... and, for each component beginning `.claude`, the directory holding it (a superset)".

**Evidence:** `scripts/lib/dev-cycle-read.sh:490-503`; `/tmp/u2a4f-fcr1-fxUr/logs/probe1.log`, `/tmp/u2a4f-fcr1-fxUr/logs/probe5.log`

---

## Claim 32: prompt_bases inline: "Up to /.claude, not /.claude/: a .claude/ directly inside another keeps its slash"

**Location:** `scripts/lib/dev-cycle-read.sh:499`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers doubled and tripled `.claude/`; does not cover the `.claudex` residue (Claim 31).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=— · r3=— · single-replicate detection
**Replicate annotations:** none

The results were `.claude/.claude/.claude/commands/x.md -> [] [.claude] [.claude/.claude]` and `a/.claude/.claude/commands/x.md -> [] [a] [a/.claude]`. Test 77's `c/.claude/.claude/commands/y.md` reads `c/.claude/d.md` in both walks.

**Evidence:** `scripts/lib/dev-cycle-read.sh:498-501`; `/tmp/u2a4f-fcr1-fxUr/logs/probe1.log`

---

## Claim 33: imported_names' block: "The walk starts at every start file in the checkout (isstart), tracked or not ..., resolves each @path against the importing file's directory (and a prompt's also against prompt_bases')"

**Location:** `scripts/lib/dev-cycle-read.sh:504-509`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers start selection and base use for prompt starts. It does not establish anything for symlinked starts, which are skipped (A2, Claim 13) and not named here as an exception.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r2: "does not cover a prompt reached only by import (not a start), which reads against its own directory. Every tracked or listed `.md` under a prompt directory is a start, so this needs a spelling the start listing does not hold."

r1's evidence (tie; atomic). The start loop reads `nul_list recs tree_starts`, then `lp="$(lower "$f")"; if ! isstart "$lp" || ! inrepo_here "$f"; then continue; fi`. `tree_starts` lists `git ls-files -z && untracked_md`. Tests 73 and 77 pass for `tree`, including the untracked `.claude/commands/u.md`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:788,844-853`

---

## Claim 34: Both walks apply the bases in every read arm; "A prompt's names resolve against the session, not its target's directory: not modelled" (the symlink arm fails); main_imports' block: "a prompt start (prompt_dir) main stores as a symlink ... fail the walk"; "(floor refuses start files by truthrule)"; "Not covered ...: a prompt read by a session started outside prompt_bases' directories"

**Location:** `scripts/lib/dev-cycle-read.sh:527-542`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the tree walk's one read arm and the main walk's checkout, blob and symlink arms (`:857-859`, `:919-928`), including phase-2 (tq) prompt starts; does not establish behavior for a prompt under a symlinked directory (A5 not-covered).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r2: the symlink arm "refuses when `xs` is non-empty, which it always is for a prompt since `pb_a=("")`" · r3: "does not cover the gitlink arm, which reads nothing"; IMPORTED_MAIN gains only parser output (`IMPORTED_MAIN+="$i"$'\n'`, `:953`), so a start that nothing imports is not listed

r1's evidence (tie; atomic). The tree arm runs `import_targets "$d" "${xs[@]}"` (`:859`). In the main walk, the checkout arm (`:922`) and the blob arm (`:924`) both pass `"${xs[@]}"`, and the symlink arm runs `[[ ${#xs[@]} -eq 0 ]] || { IMPORTED_MAIN=error; return 1; }` (`:928`). prompt_dir runs before main_checkout's admission (`:909`), so a phase-2 prompt start keeps its bases. Test 74 (the main-stored command link gives `walk failed`, while a rules link is followed) passes. The floor gives `.claude/commands/c.md "$INSTR"` in test 72.

**Evidence:** `scripts/lib/dev-cycle-read.sh:857-861,909-913,919-929`; `/tmp/u2a4f-fcr1-fxUr/logs/build-loop-check.log`

---

## Claim 35: import_targets: "a relative name resolved against $1 and against each further directory given (a prompt's session directories: prompt_bases)"; IMPORT_AWK BEGIN: "IT_XDIRS: the further directories, each led by an x so "" survives split."; "the walks refuse a name holding a newline"

**Location:** `scripts/lib/dev-cycle-read.sh:579-582`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers 0, 1, 2 and 4 further directories, `""` among them (twice), absolute and `..` names (`:697-698`, `:727`); does not cover a directory holding a newline (refused upstream: `:847`, `:897`, `:903`).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

r2's evidence (tie; most specific Scope). `[[ $# -lt 2 ]] || x="$(printf 'x%s\n' "${@:2}")"` (`:727`), then `nd = split(ENVIRON["IT_XDIRS"], dirs, "\n"); for (i = nd; i >= 1; i--) dirs[i] = substr(dirs[i], 2)` (`:698`) and `for (i = 0; i <= nd; i++) put(root "/" dirs[i] "/" c)` (`:642`). `probe2.out`: `x @y.md` with `sub '' other/dir ''` yields `sub/y.md`, `y.md` and `other/dir/y.md`, and the duplicate `""` adds nothing (`tried`). `@/abs.md` yields nothing outside the root. `@../up.md` from `sub/deep` with base `a` yields `sub/up.md` and `up.md`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:627-704`, `:724-748`; `/tmp/u2a4f-fc2-wXyc/logs/probe2.out`

---

## Claim 36: The superset statement above import_targets ("the one statement of it; known issue A5 and plan F11 point here"): "each prefix of the run after it, up to the first blank ..., is a candidate name, with a backslash-escaped space read as a space ... Each candidate is ... made absolute (ROOT_REAL/$1/name unless it starts with /)"

**Location:** `scripts/lib/dev-cycle-read.sh:593-605`
**Type:** Behavioral / Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the paragraph's account of candidate runs and resolution against this branch's IMPORT_AWK; does not establish the Claude Code side of the superset claim (untraced, no egress).
**Legibility-target:** for-author
**Replicate verdicts:** r1=Stale · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r2: "Both omissions over-read, and both are stated elsewhere in the same comment block or in scan's comment"; "the block as a whole is complete, but the 'one statement' sentence a reader is pointed to is not"; precise version "made absolute (ROOT_REAL/D/name for $1 and each further directory D, unless it starts with /)" plus the quoted run · r3: "It does not dispute the superset conclusion, which only gains from the omission"; names only the quoted-run omission · r1: escalated as the only finding touching the "one statement" contract A5 points to (see Escalations 2)

r1's evidence (winning). This branch adds two rules the "one statement" does not carry. First, a second run after `@"`, which ends only at the closing quote and keeps blanks, tabs and `\r` (`if (q) { if (ch == "\"") break }`, `:681`). It does not read `\ ` as a space: probe 2 gives `un closed tab\there` as a candidate, and `a\ b.md` kept literal. Second, resolution against every further base directory (`for (i = 0; i <= nd; i++) put(root "/" dirs[i] "/" c)`, `:642`), where the paragraph says only `ROOT_REAL/$1/name`. The rules sit in the scan comment (`:669-674`) and in import_targets' first paragraph (`:579-581`), but A5 and F11 send a reader to this paragraph for "the claim, its rules and its exceptions". Both rules read more than the paragraph says (the safe direction). The paragraph should name the quoted run and the further base directories.

**Evidence:** `scripts/lib/dev-cycle-read.sh:579-581,593-605,636-643,664-686`; `/tmp/u2a4f-fcr1-fxUr/logs/probe2.log`

---

## Claim 37: IMPORT_AWK scan/names: the quoted run ("the run after the quote is read too, up to the closing quote, blanks included"), and the unquoted run still ends at blanks

**Location:** `scripts/lib/dev-cycle-read.sh:664-686`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a quoted run with a space and a tab, an unclosed quote and the escaped-space unquoted run; does not cover a quoted mention spanning lines (the parser is line-based; a file name holding a newline fails both walks first).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r1: "does not establish whether Claude Code's command expansion calls the quote-accepting extractor (Unverifiable in i2 Claim 19c, still untraced)" · r3: "The read applies in every file, not only commands, which is a superset."

r2's evidence (tie; most specific Scope). `names()` reads `if (q) { if (ch == "\"") break } else if (ch == "\\" && substr(line, j + 1, 1) == " ") { ch = " "; j++ } else if (ch == " " || ch == "\t" || ch == "\r") break; name = name ch; emit(name)` (`:677-686`). `probe2.out`: `@"docs/a b.md" tail` yields `sub/docs/a b.md`, and the unquoted run stops at `sub/"docs/a`. `@"a<TAB>b.md"` yields `a<TAB>b.md`. r1: `printf '@"docs/a b.md" tail @docs/c d.md @"un closed tab\there\n'` yields `docs/a b.md`, and the unquoted runs stop at `docs/c` and `un`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:664-686`; `/tmp/u2a4f-fc2-wXyc/logs/probe2.out`

---

## Claim 38: scan (2b6f2f91): "such a name can match a real file, which the floor then refuses (pathform already refuses it to --check-fix)"

**Location:** `scripts/lib/dev-cycle-read.sh:672-673`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a quoted name with a blank that matches a tracked file; does not establish anything for a quoted name with no blank (not the comment's subject).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** none

r1's evidence (tie; atomic). In a fixture with `.claude/commands/q.md` holding `run @"docs/a b.md"`, `floor "docs/a b.md"` prints `an instruction file on the default branch imports it with @ ...`, and `--check-fix "docs/a b.md"` prints `skip docs/a b.md: not an allowed path form`. r2 and r3: pathform's `NAMECHARS` has no blank (`:178`), check_fix runs pathform first (`scripts/dev-cycle.sh:174`), and the test pins `"docs/a b.md"` as imported in both walks (`test/scripts/build-loop-check.bats:1191-1195`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:672-675`; `/tmp/u2a4f-fcr1-fxUr/logs/probe5.log`

---

## Claim 39: IMPORT_AWK: the work charge and the output bound still hold with several bases

**Location:** `scripts/lib/dev-cycle-read.sh:628-663`
**Type:** Performance / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that every candidate from either run passes through emit's and put's charges, the output bound (`IMPORT_LEFT`) and the work bound (`IMPORT_WORK_LEFT`), and per-base work charging; does not re-measure the per-file bound's wall time.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** none

r2's evidence (tie; most specific Scope). `IMPORT_LEFT=10` → rc=1. `IMPORT_WORK_LEFT=50` → trailer `/58`, rc=1. The same text costs `/400` work with one base and `/1405` with four. Each `put` charges `work += length(c)` (`:647`). r1: `IMPORT_LEFT=5` with 3 bases prints `a/a` and `a`, then rc=1; `IMPORT_WORK_LEFT=10` gives rc=1. r3: emit charges `work += length(c); if (work > wmax) exit 3` (`:629`), and put charges the print budget (`:661`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:628-663`, `:677-686`; `/tmp/u2a4f-fc2-wXyc/logs/probe2.out`

---

## Claim 40: emit's `~/` handling with several bases: a `~/` name joins the home in its spelled and real forms, once each, not once per base

**Location:** `scripts/lib/dev-cycle-read.sh:634-642`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `~/n.md` with four bases; does not cover a home whose real path differs (one extra `put`, by the visible code).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r1+r2: only the bare `~` prefix is joined to each base (`d/~ e/~ f/~ ~`; `sub/~`, `~`, `a/~`, `b/~`), as any relative candidate is

r2's evidence (tie; atomic). emit: `if (substr(c, 1, 2) == "~/") { if (substr(home, 1, 1) != "/") exit 4; if (homereal != home) put(homereal "/" substr(c, 3)); c = home "/" substr(c, 3) }; if (substr(c, 1, 1) == "/") { put(c); return }; for (i = 0; i <= nd; i++) put(root "/" dirs[i] "/" c)` (`:636-642`). `probe2.out` for `@~/n.md` with `sub '' a b`: `home/n.md` once. r1: with three bases `@~/x.md` yields `h/x.md` and `hl/x.md` once each. r3: `home/h.md` printed once with four bases.

**Evidence:** `scripts/lib/dev-cycle-read.sh:634-642`; `/tmp/u2a4f-fc2-wXyc/logs/probe2.out`

---

## Claim 41: IMPORT_AWK: the line of quotes costs quadratic, not cubic, work

**Location:** `scripts/lib/dev-cycle-read.sh:664-686`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers emit/put/names/scan as rewritten. It does not establish whether Claude Code's command expansion calls the quote-accepting extractor.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=— · r3=— · single-replicate detection
**Replicate annotations:** none

3,000 quotes cost `/8079566` work (≈ n²), and test 77's 2,000-quote line walks ok. A7 is `names(line, i + 2, L, 1)` from scan, not a recursion in emit.

**Evidence:** `scripts/lib/dev-cycle-read.sh:664-686`; `/tmp/u2a4f-fcr1-fxUr/logs/probe2.log`

---

## Claim 42: "A mention in a command may be quoted (@"docs/a b.md", which the prompt-mention reader of Claude Code 2.1.293 accepts)"

**Location:** `scripts/lib/dev-cycle-read.sh:669-670`
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers nothing beyond the security report's quoted extractor text; does not establish that command expansion calls that extractor.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=— · r2=Unverifiable · r3=Unverifiable
**Replicate annotations:** r1 (scope of its Claim 23; Out of scope): "whether Claude Code's command expansion accepts `@"..."` ... (no egress; untraced superset, settled)" · r2: "The extractor's `[^"]+` also crosses a newline, which the line-based parser does not, but a file name holding a newline already fails both walks." · r3: "The rest of the lib says 2.1.292; this line names 2.1.293"; A5 says the oracle "is not kept"

r2's evidence (tie; lowest). The security report quotes the binary's extractor as `(^|${JY})@"([^"]+)"` and says the caller is untraced (`docs/reviews/security-reviewer-review-2026-10-07-build-loop-u2a4.md`; i2 fact-check Claim 19c). Verifying it needs a caller trace in the 2.1.293 binary.

**Evidence:** `scripts/lib/dev-cycle-read.sh:669-675`; `docs/reviews/code-fact-check-report-build-loop-u2a4-i2.md:384-405`

---

## Claim 43: Index pop: "An index, not a copy per pop (quadratic in the files read: override row 461)"; "phase 2: main's walk is done"

**Location:** `scripts/lib/dev-cycle-read.sh:855,916-918`
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the pop and the phase switch; does not establish timing (row 465: no timing test).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=—
**Replicate annotations:** none

r1's evidence (tie; atomic). `while [[ $qi -lt ${#queue[@]} || ${#tq[@]} -gt 0 ]]; do [[ $qi -lt ${#queue[@]} ]] || { queue=("${tq[@]}"); tq=(); qi=0; }`. Phase 2 starts only when the index has reached the end of main's queue. Phase-2 imports main stores join `queue` and are popped in order. The pops are `f="${queue[qi]}"; qi=$((qi + 1))` (`:857`, `:919`; r2).

**Evidence:** `scripts/lib/dev-cycle-read.sh:855-858,916-920`

---

## Claim 44: isimported: "Whether path $2 (any case) is imported ... a caller that words a failed walk asks truthwalk, which runs the walk first."

**Location:** `scripts/lib/dev-cycle-read.sh:964-968`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the pointer to truthwalk. It does not re-check isimported's pre-existing fail-closed rules.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified
**Replicate annotations:** none

r3's evidence (tie; atomic). truthwalk runs `main_imports || return 0` / `imported_names || return 0` before `isimported "$1" "$2"` (`:1009-1010`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:969-978`, `:1007-1011`

---

## Claim 45: truthrule comment: "returns 0 with TRUTH_WHY set when it refuses: instr ..., dot (a .-prefixed component, a top-level one included), cycle (writable), settings (docs/dev-cycle.md), user (docs/constraints.md ...) or record (docs/decisions/, docs/human-author/), and case for a path holding an upper-case letter"; docs/thoughts/ floor-only

**Location:** `scripts/lib/dev-cycle-read.sh:979-989`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the six words plus `case`, their order (case, instr, dot, cycle, settings, user, record), and empty TRUTH_WHY on a pass; does not establish D5 item 4's "other briefs' working docs" (floor's, not truthrule's).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r2+r3: the comment does not state an order; "the comment lists `case` last, while the code tests it first"; in the code instr is tested before dot, "so `.claude/rules/r.md` answers instr, not dot" · r2: "The order cannot hide a word check_fix maps. No writable path is an instruction or dot path: briefs start with a date, and the rest are fixed names."

r1's evidence (tie; lowest, with the most specific Scope). The code order is case, instr, dot, cycle, settings, user, record, `else return 1`, and TRUTH_WHY is set empty first. Probe 1 gives `.envrc: dot`, `docs/.x/claude.md: instr` (instr outranks dot), `docs/working/questions.md: cycle`, and `docs/thoughts/a.md: - []`. Test 73's check_fix answers `ok docs/thoughts/t.md`, and floor answers `$REC`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:990-1000`; `/tmp/u2a4f-fcr1-fxUr/logs/probe1.log`

---

## Claim 46: truthwalk: "Returns 0 when the walk fails (TRUTH_WHY=walk) or reaches PATH (TRUTH_WHY=imported), else 1 with TRUTH_WHY empty; an unknown WALK answers walk without running one. For tree or main it exits through need_root."

**Location:** `scripts/lib/dev-cycle-read.sh:1001-1006`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the walk, unknown-WALK and need_root paths (executed) and the TRUTH_WHY-empty return (suite). It does not reach an end state that misleads a caller: the extra return case below fails closed.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Mostly accurate
**Replicate annotations:** r1 (Verified): "does not establish anything for a walk that is cached in error (it returns 1 again, so the outcome is `walk`, by reading)"; probe 3 gives `main docs/zzz.md: - []`, `main docs/a.md: [imported]`, the same for `tree`, `main docs/p.md: [walk]`, `bogus: 0 [walk]` · r2 (Verified): `bogus -> 0 TRUTH_WHY=walk`, `main docs/x.md -> 1 TRUTH_WHY=''`

r3's evidence (winning). The unknown-WALK and need_root behaviour was executed (Claim 21), and the suite pins `b: []`. The comment omits one case. When isimported's own `lp="$(lower "$2")" || return 0` (`:972`) fails, truthwalk returns 0 with `TRUTH_WHY=imported` although PATH was not reached (`TRUTH_WHY=imported; isimported "$1" "$2" || ...`, `:1010`). Both callers would then print the "imports it" wording for a tr failure. The direction is safe (a refusal). The precise version: "Returns 0 when the walk fails (walk), or when it reaches PATH or PATH cannot be lower-cased (imported)."

**Evidence:** `scripts/lib/dev-cycle-read.sh:969-978`, `:1007-1011`, `/tmp/u2a4f-fcr3-iU2i/truthwalk.out`

---

## Claim 47: ownfile's comment: "its working docs, docs/working/{research,plan,checkpoint,handoff,test-strategy}-STEM.md, and a review it adds, docs/reviews/STEM.md or docs/reviews/NAME-STEM.md (a modified or deleted review is never its own)"

**Location:** `scripts/lib/dev-cycle-read.sh:1012-1017`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the full-stem match, the A-only review rule and the empty stem. It does not establish that a status letter like R100 is truncated before the call; the floor comment hands that to the caller.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=— · r2=— · r3=Verified · single-replicate detection
**Replicate annotations:** none

`[[ "$3" == A && "$1" == docs/reviews/* && "$b" != */* && ( "$b" == "$2.md" || "$b" == *"-$2.md" ) ]]` (`:1022`). The suite's ownfile test passes (including D on its own name and the empty stem), and the floordiff probe gave the same answers for A, M and D as the ancestor.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1018-1023`, `test/scripts/build-loop-check.bats:1065-1079`, `/tmp/u2a4f-fcr3-iU2i/floordiff.out`

---

## Claim 48: floor comment: "The self-merge floor (plan D5 items 1-4) ... $3 the diff-tree status letter alone (R for R100; only A makes a review the brief's own) ... floor item 5, symlinks and gitlinks, is the caller's mode rule"; c934adbc: "floor PATH STEM STATUS, ownfile and GATE_CODE (plan D5 items 1-4), ported from feat/build-loop-u2a2-full"

**Location:** `scripts/lib/dev-cycle-read.sh:1027-1038`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers floor against D5 items 1-4 (`docs/working/plan-build-loop-handoff.md:66-72`) and ownfile/GATE_CODE against the ancestor; does not establish item 5 (no mode check, by design).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r2: GATE_CODE's "`^scripts/lib/` is wider than the one lib file D5 names"; `floor-head.out` holds `PASS A docs/reviews/2026-10-07-x.md` and `REFUSE M docs/reviews/2026-10-07-x.md` · r3: GATE_CODE covers "D5 item 3's four files and all of `scripts/lib/`"

r1's evidence (tie; lowest). D5 item 1 is covered by `instr` and `truthwalk main`, item 2 by `dot`, item 3 by `[[ "$lp" =~ $GATE_CODE ]]`, and item 4 by cycle/settings/user/record plus `docs/thoughts/*` and the non-own `docs/working/*`. Only `ownfile`'s `[[ "$3" == A && ... ]]` reads the status letter. `ownfile()` and `GATE_CODE=` are byte-identical to `git show feat/build-loop-u2a2-full:scripts/lib/dev-cycle-read.sh` `:597-605`. Tests 72 and 73 pass.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1018-1061`; `feat/build-loop-u2a2-full:scripts/lib/dev-cycle-read.sh:597-638`; `docs/working/plan-build-loop-handoff.md:66-72`

---

## Claim 49: (Task check 6) Nothing the pre-split ancestor's floor (feat/build-loop-u2a2-full) refused passes HEAD's floor

**Location:** `scripts/lib/dev-cycle-read.sh:1039-1061`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers floor's verdicts at HEAD against the pre-split ancestor's floor (`feat/build-loop-u2a2-full` 6c41aea2), run over 3,104 tracked paths and 39 synthetic paths for letters A and M, with stem `2026-10-07-x`, and clause by clause. It does not separate floor's logic from walk differences: both sides ran their own main_imports, and they agreed on this repo.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r1 (Verified, Medium, static): "does not establish phase-2 checkout behavior: U2a3c, already merged, changed the ancestor's checkout reads, and that is outside this unit"; "the walks cannot be compared on one fixture: the ancestor's lib does not carry U2a3/U2a3c"; HEAD also refuses a path `lower` cannot lower-case, where the ancestor had no guard · r3: 41 paths × 3 letters in a fixture with instruction, rules and command starts: no row refused by the ancestor and passed by HEAD, and HEAD additionally refuses `docs/c.md`, which only `.claude/commands/c.md` imports; "It does not cover a non-clean checkout. There the ancestor refuses one case that HEAD passes: a start main stores, removed from the index and edited in the checkout. That violates contract item 2 and matches main's walk since U2a3c" (escalated: see Escalations 5)

r2's evidence (tie on Verified; r2's executed differential has the most specific Scope). The ancestor and HEAD gave identical REFUSE/PASS for all 6,320 (path, letter) pairs (`diff` empty). So HEAD passes nothing the ancestor refused. By clause, every ancestor refusal is still in HEAD: instruction basename becomes `instr` (now a superset with prompt and rules paths), dot stays dot, GATE_CODE is unchanged, the walk failure or import moves to the last `elif truthwalk main` (still reached by every path not refused earlier, own files included), and cycle/dev-cycle.md, constraints, decisions/thoughts/human-author and non-own working/reviews files are all kept.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1012-1061`; `docs/working/plan-build-loop-handoff.md:66-72`; `/tmp/u2a4f-fc2-wXyc/logs/floor-head.out`, `/tmp/u2a4f-fc2-wXyc/logs/floor-anc.out`

---

## Claim 50: FLOOR_WHY for an import: "an instruction file on the default branch imports it with @ (directly or through another import)"

**Location:** `scripts/lib/dev-cycle-read.sh:1059`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the refusal itself, which is right. It covers only the wording's two premises. The prompt-file half was settled as wording by rubric C10 (for check_fix's line); the checkout half is not named in the rubric or override rows.
**Legibility-target:** for-author
**Replicate verdicts:** r1=— · r2=— · r3=Mostly accurate · single-replicate detection
**Replicate annotations:** r3: "FLOOR_WHY has no caller until U2c (override row 472 already defers its shape there)" (see Escalations 7)

The refusal is correct, but the reason states two things the walk does not require. (a) The importer can be a prompt file, not an instruction file: the floordiff `docs/c.md` row. (b) The importer can be a checkout-only start, not something on the default branch. The suite pins this exact string for `docs/private.md`, which only an untracked `CLAUDE.local.md` imports: `printf 'Mine: @docs/private.md\n' > CLAUDE.local.md` ... `docs/private.md "$IMP"` (`test/scripts/build-loop-check.bats:1040`, `:1048`). A user acting on the reason would look on main and find no importer. The precise version: "an instruction or prompt file (on the default branch or in the gate's checkout) imports it with @".

**Evidence:** `scripts/lib/dev-cycle-read.sh:1057-1059`, `:517-523`, `test/scripts/build-loop-check.bats:1031-1061`, `/tmp/u2a4f-fcr3-iU2i/floordiff.out`

---

## Claim 51: Commit c934adbc: "Plan step 5's U2a4 (no new mode), stacked on main dfa75374"

**Location:** commit c934adbc
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the stated base. Immutable commit; for the record only.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Mostly accurate (compound) · r2=— · r3=— · single-replicate detection
**Replicate annotations:** merge note: r1 verdicted this with d861183d's "All 7 fail on main's code" (Claim 10) as one compound; this half carries the defect

The base is not dfa75374 as c934adbc says: `git rev-parse d861183d^` is `7afdb8d2` (main), a checkpoint commit whose only change from dfa75374 is `docs/working/checkpoint-build-loop-handoff.md` (8+/8-). The lib is identical, so the code claim holds. The commits are immutable, so this is for the record only.

**Evidence:** `git diff --stat dfa75374 7afdb8d2`; `/tmp/u2a4f-fcr1-fxUr/logs/d86-u2a4.log`

---

## Claim 52: Commit a5ad8c08: "--check-fix identical to main's over 3,098 paths"

**Location:** commit a5ad8c08
**Type:** Reference (measured value)
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count at a5ad8c08's tree and identity at HEAD; does not establish a re-run at a5ad8c08's own code.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r1+r2: "no override row covers this commit's figure" (row 480 records the corrected 03be719e count but not this one); r1: "This is the logged count-from-an-earlier-file-set class" · r2: "does not establish which file set the author's run used" · r3: "The extra path is the i2 fact-check report that commit adds, so the run likely predates staging it. ... A merge message should cite 3,099." (see Escalations 1)

r1's evidence (three-way tie; lowest). a5ad8c08's tree has 3,104 paths, 5 with whitespace, so 3,099 whitespace-free. 3,098 is its parent 03be719e's count. The conclusion holds: identity was re-run at HEAD over all 3,104 paths (Claim 20).

**Evidence:** `git ls-tree -r --name-only a5ad8c08`; `/tmp/u2a4f-fcr1-fxUr/logs/cf-run.txt`

---

## Claim 53: Commit 03be719e: "--check-fix still identical to main's over 3,092 paths"; "prompt_bases gives each prompt start one list of bases, the top level and the directory holding every enclosing .claude/, once each"

**Location:** commit 03be719e
**Type:** Reference / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count and the bases statement; settled by override row 480 (Accepted-immutable). This is recorded for completeness, not as a new finding.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Mostly accurate · r2=— · r3=— · single-replicate detection
**Replicate annotations:** none

03be719e's tree holds 3,098 whitespace-free paths. The base statement was false at 03be719e for a doubled `.claude/` and is fixed at HEAD (Claim 32). At HEAD it carries the `.claudex` over-read (Claim 31).

**Evidence:** `docs/reviews/override-log.md:480`; `git ls-tree -r --name-only 03be719e`

---

## Claim 54: Commit test and line tallies: d861183d (7 new tests); c934adbc "build-loop-check 75, build-loop-read 19, dev-cycle 78, fixture-git-env 2, fixture-hermeticity 2, hermeticity-lint 53 ... 381 changed code lines"; 03be719e and a5ad8c08 "build-loop-check 78/78 ...; shellcheck -S warning clean"; 03be719e "grew from 381 to 443"; a5ad8c08 "469 code lines against main (381 at step 1a)"

**Location:** commit c934adbc, commit 03be719e, commit a5ad8c08, commit d861183d
**Type:** Configuration (measured values)
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the six suites and shellcheck at HEAD, the `@test` count of build-loop-check.bats at each commit, and the numstat line counts; does not re-run the suites at the earlier commits, or the health check c934adbc names (Claim 58).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified (compound)
**Replicate annotations:** none

r2's evidence (tie; most specific Scope). At HEAD: build-loop-check 78 ok/0 not ok, dev-cycle 78/0, build-loop-read 19/0, fixture-git-env 2/0, fixture-hermeticity 2/0, hermeticity-lint 53/0, all rc=0. `shellcheck -S warning scripts/dev-cycle.sh scripts/lib/dev-cycle-read.sh` rc=0 with empty output. `grep -c '^@test'` on build-loop-check.bats: main 68, d861183d 75, c934adbc 75, 03be719e 78, a5ad8c08 78, HEAD 78. Line counts 381, 443 and 469 at their commits (Claim 11). r1 and r3 got the same counts.

**Evidence:** `/tmp/u2a4f-fc2-wXyc/logs/*.tap`, `/tmp/u2a4f-fc2-wXyc/logs/shellcheck.out`; `git show <c>:test/scripts/build-loop-check.bats`

---

## Claim 55: Commit ee5108bd: "Fact-check (30 claims: 0 Incorrect, 1 Stale, 6 Mostly accurate)"

**Location:** commit ee5108bd
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the i1 report's header tally; does not establish the i1 verdicts themselves.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=— · r3=Verified (compound)
**Replicate annotations:** none

r1's evidence (tie; lowest). The i1 report's header reads `**Total claims checked:** 30` / `**Summary:** 22 verified, 6 mostly accurate, 1 stale, 0 incorrect, 1 unverifiable`.

**Evidence:** `docs/reviews/code-fact-check-report-build-loop-u2a4.md:9-10`

---

## Claim 56: Commits a5ad8c08 and c934adbc, behavioural lines: "R1: prompt_bases strips up to /.claude, not /.claude/, so a .claude/ directly inside another keeps its base"; "A7: the quoted-mention read is a second candidate run from the character after the quote (awk function names), not a recursion in emit"; "A8: a quoted run ends only at its closing quote"; "the tree walk gains rules/ (main had it only in main_imports)"

**Location:** commit a5ad8c08, commit c934adbc
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each statement against HEAD's code and main's diff; does not cover the superset side effect of R1 (Claim 31), which the message does not mention.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r3: also checks a5ad8c08's C24 line (confirmed by its need_root probe, Claim 21)

r2's evidence (tie; atomic). `probe1.out`: `a/.claude/.claude/commands/x.md -> [] [a] [a/.claude]`. `names` has no recursion in emit, and scan calls `names(line, i + 2, L, 1)` (`:674`). Main's tree walk tested only the basename: `- lp="$(lower "${f##*/}")"` / `- if [[ ! "$lp" =~ $INSTRUCTION_FILE ]]` (diff of `:848-849`), while main's main_imports had `"$f" == .claude/rules/*.md || "$f" == */.claude/rules/*.md`. r1: 3,000 quotes cost 8.08M work.

**Evidence:** `git diff main...HEAD -- scripts/lib/dev-cycle-read.sh`; `/tmp/u2a4f-fc2-wXyc/logs/probe1.out`, `/tmp/u2a4f-fc2-wXyc/logs/probe2.out`

---

## Claim 57: Commit c934adbc "truthwalk LP WALK"; commit d7cdc1ea "six rows dispose of the U2a4 revisit triggers"

**Location:** commit c934adbc, commit d7cdc1ea
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each statement at its own commit.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=— · r2=— · r3=Verified (compound) · single-replicate detection
**Replicate annotations:** none

c934adbc's own truthwalk is `case "$2" in main) ...; isimported "$2" "$1"`, so "LP WALK" was true then. The six rows are `override-log.md:462-467`.

**Evidence:** `docs/reviews/override-log.md:462-467`; `git show c934adbc:scripts/lib/dev-cycle-read.sh`

---

## Claim 58: "health check passed" (commit c934adbc)

**Location:** commit c934adbc
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers nothing. The claim is about c934adbc's tree, and `scripts/health-check.sh` runs the whole repo suite (its check 5); this pass did not run it at that commit.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=— · r2=— · r3=Unverifiable · single-replicate detection
**Replicate annotations:** r2 (Out of scope, its Claim 34 scope): "does not re-run ... the health check c934adbc names" · r3: "rubric C21 routes it to pr-prep step 5a" (see Escalations 6)

Verifying this needs `scripts/health-check.sh` run in a checkout of c934adbc. That was out of r3's cost scope.

**Evidence:** `scripts/health-check.sh:1-30`

---

## Escalations

1. **The merge message must carry the corrected figures.** The unit is 471 code lines at HEAD, not 469 (2b6f2f91 added 2 comment lines). a5ad8c08's "3,098 paths" should be 3,099.
   - Path: `docs/reviews/override-log.md:479`; commit a5ad8c08
   - Raised by: r1 (Escalate: "Claim 4's size figure should be corrected in the merge message"), r2 (Escalate (2)), r3 (Escalate: "Claim 7's size ... and Claim 38b's path count (3,099) belong in the merge message")
   - Addressee: orchestrator (merge message)
   - Merged claims: 11, 52
2. **The superset paragraph that A5 and F11 call "the one statement" omits the quoted run and the further base directories.** r1 escalated it as "the only one that touches the 'one statement' contract A5 points to", with nothing blocking.
   - Path: `scripts/lib/dev-cycle-read.sh:593-605`
   - Raised by: r1 (Escalate)
   - Addressee: orchestrator
   - Merged claim: 36
3. **A long quote line in a prompt start fails both walks closed, so the floor refuses every path.** This is the class override row 469 declined, but rubric A7's "walks ok" reads broader than the test. r2 asks for a decision on whether A7's note or row 469 should name it.
   - Path: `docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a4.md:24`, `test/scripts/build-loop-check.bats:1188`
   - Raised by: r2 (Escalate (1))
   - Addressee: orchestrator
   - Merged claim: 2
4. **Claude Code's command expansion is still untraced.** Whether it calls the quote-accepting extractor, and whether it loads `agents/`, `output-styles/` and `skills/`, needs a host check with the binary (no egress here).
   - Path: `scripts/lib/dev-cycle-read.sh:669-670`, `:481-482`
   - Raised by: r1 (Out of scope), r2 (Claim 30; Out of scope), r3 (Claim 29; Out of scope)
   - Addressee: orchestrator (host check)
   - Merged claims: 42, 6
5. **Ancestor-only refusal on an unclean checkout.** The ancestor refuses, and HEAD passes, a start main stores that was removed from the index and edited in the checkout. This breaks contract item 2 and has been on main since U2a3c. r3 routes it to U2b's clean-worktree check rather than calling it a U2a4 finding.
   - Path: `scripts/lib/dev-cycle-read.sh:1027-1037`, `:46-50`
   - Raised by: r3 (Escalate)
   - Addressee: orchestrator (U2b clean-worktree check)
   - Merged claim: 49
6. **"health check passed" at c934adbc is unverified.**
   - Path: commit c934adbc; `scripts/health-check.sh`
   - Raised by: r3 (Claim 40, routed by rubric C21), r2 (Out of scope)
   - Addressee: pr-prep step 5a
   - Merged claim: 58
7. **FLOOR_WHY's import wording names only an instruction file on the default branch.** It has no caller until U2c, and override row 472 already defers its shape there.
   - Path: `scripts/lib/dev-cycle-read.sh:1059`
   - Raised by: r3 (Claim 36)
   - Addressee: orchestrator (U2c, per override row 472)
   - Merged claim: 50

No replicate named a critic in its Out-of-scope bullets. The bullets on timing (override rows 465, 469-471 not re-measured) and on the hallucination log (not updated) hand off no concrete risk, so they add no entry.

## Verdict stability

- **Total clusters (merged claim rows):** 58
- **Single-replicate rows:** 13 (Claims 3, 4, 8, 9, 12, 32, 41, 47, 50, 51, 53, 57, 58), with no agreement measurable
- **Rows reported by two or three replicates:** 45
  - **All reporting replicates agreed:** 38
  - **Verdicts disagreed:** 7
    - Claim 2: r1=Verified (compound) · r2=Mostly accurate · r3=Verified
    - Claim 6: r1=Verified (compound) · r2=Verified · r3=Mostly accurate
    - Claim 10: r1=Mostly accurate (compound) · r2=Verified · r3=—
    - Claim 13: r1=Mostly accurate · r2=Verified · r3=Verified
    - Claim 15: r1=Verified (compound) · r2=Mostly accurate · r3=Verified (compound)
    - Claim 36: r1=Stale · r2=Mostly accurate · r3=Mostly accurate
    - Claim 46: r1=Verified (compound) · r2=Verified (compound) · r3=Mostly accurate
- **Agreement rate:** 38 / 45 = **84.4%** over multi-replicate rows. Counting single-replicate rows as trivially agreed gives 51 / 58 = 87.9%.
- **Detection spread:** 13 of 58 rows (22%) were surfaced by one replicate only. Four of those are non-Verified: Claim 50 (Mostly accurate, r3), Claim 51 (Mostly accurate, r1, compound), Claim 53 (Mostly accurate, r1) and Claim 58 (Unverifiable, r3). Five more non-Verified rows rest on one replicate's verdict while the others said Verified: Claims 2 (r2), 6 (r3), 13 (r1, with r2 and r3 noting the same case in Scope), 15 (r2) and 46 (r3). Claim 10's disagreement comes only from r1's compound verdict, whose defect is in Claim 51.
- This run is below the 90% falsifier threshold, so k stays at 3.
