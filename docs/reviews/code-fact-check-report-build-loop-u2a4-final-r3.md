Commit: 2b6f2f91
# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u2a4 (branch `feat/build-loop-u2a4`)
**Scope:** `git diff main...HEAD` (main 7afdb8d2, HEAD 2b6f2f91): code comments in `scripts/lib/dev-cycle-read.sh` and `scripts/dev-cycle.sh`, the test comments in `test/scripts/build-loop-check.bats`, known issues A2 and A5, plan F11 and the U2a4/U2b bullets, the override-log rows dated 2026-10-07 for `feat/build-loop-u2a4`, the rubric's code claims, and the messages of `git log main..HEAD` (7 commits). Final confirming pass, replicate r3 of k=3.
**Checked:** 2026-10-08
**Total claims checked:** 40
**Summary:** 31 verified, 7 mostly accurate, 0 stale, 0 incorrect, 2 unverifiable

Hallucination-pattern log read first (`docs/reviews/hallucination-patterns.md`, 5 entries). No claim below matches a logged pattern. The closest class, "a measured count quoted from an artifact set", was checked for every count in scope (test counts, line counts, path counts). All match except the off-by-one in Claim 38b.

Execution provenance: every executed command ran with `TMPDIR=/tmp/u2a4f-fcr3-iU2i`, either in cwd `/workspace/.claude/wt-build-loop-u2a4` (suites, the --check-fix comparison, line counts) or in fixture repos under that TMPDIR (probes). Captured output is in that TMPDIR, not under `docs/reviews/execution-logs/`, because this pass was told to write only this report. Probe scripts are in `/tmp/u2a4f-fcr3-iU2i/probes/`. Each probe ran under `timeout`, and none left a process running.

---

## Claim 1: "A table test compares the two over 138 paths: 3 depths × (10 basenames, 4 of them negatives, + 6 dirs × 3 tails × 2 cases)"

**Location:** `docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a4.md:66`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the test's path count and its negatives. It does not establish that 138 paths cover every shape (Claim 22 adds a 40,000-path fuzz and newline cases).

The test builds the paths as follows:

```bash
# test/scripts/build-loop-check.bats (instruction_names test)
for d in "" a/ a/b/; do for n in CLAUDE.md claude.local.md Agents.MD agent.md GEMINI.md SKILL.md skills.md x.md x.txt claude.md.bak; do ps+=("$d$n"); done
    for c in rules commands agents output-styles skills notes; do for t in x.md sub/X.MD x.txt; do ps+=("$d.claude/$c/$t" "$d.Claude/$c/$t"); done; done; done
```

That gives 3 × (10 + 6·3·2) = 138. The negatives among the basenames are `skills.md x.md x.txt claude.md.bak`, which makes 4. The suite passed (Claim 39).

**Evidence:** `test/scripts/build-loop-check.bats:1172-1180`, `/tmp/u2a4f-fcr3-iU2i/blc.out`

---

## Claim 2: "--check-fix over this repo's tracked paths is identical to main's (3,092 of 3,097: the comparison skips the five names holding whitespace)"

**Location:** `docs/reviews/override-log.md:462`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers byte-identical output over every whitespace-free tracked path at HEAD. It does not establish identity for prompt files (none is tracked) or for the five whitespace names, and the 3,092/3,097 figures describe c934adbc's tree, not HEAD's.

Re-run at HEAD. Main's `scripts/dev-cycle.sh` and lib were extracted with `git show main:...` into `/tmp/u2a4f-fcr3-iU2i/mainscripts/`. Both scripts then ran `--check-fix` over `git ls-files | grep -v '[[:space:]]'`, which is 3,099 of 3,104 tracked paths (5 skipped, as the row says). Command: `bash -c 'mapfile -t P < paths.txt; bash mainscripts/dev-cycle.sh --check-fix "${P[@]}" > cf-main.txt; bash scripts/dev-cycle.sh --check-fix "${P[@]}" > cf-head.txt'`. Run at 2026-10-08T07:08:30Z: both exited 0, `cmp` reported IDENTICAL, and the output held 15 `ok` and 3,084 `skip` lines. c934adbc's tree holds 3,092 whitespace-free paths (`git ls-tree -r --name-only c934adbc | grep -vc '[[:space:]]'` → 3092), which matches the row.

**Evidence:** `scripts/dev-cycle.sh:168-184`, `/tmp/u2a4f-fcr3-iU2i/cf-main.txt`, `/tmp/u2a4f-fcr3-iU2i/cf-head.txt`

---

## Claim 3: "`isstart` ... adds `.md` files under `.claude/{commands,agents,output-styles,skills}/` at any depth (and gives the tree walk `.claude/rules/`); ... a prompt start main stores as a symlink fails the main walk ... `agents/` and `output-styles/` are an untraced superset."

**Location:** `docs/reviews/override-log.md:463`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the start set, the tree walk gaining rules/, and the symlinked-prompt failure. It does not establish that Claude Code expands `@` in any of agents/, output-styles/ or skills/.

Everything the row says about the code holds. Main's prefilter had no `.claude/` term (`git show main:scripts/lib/dev-cycle-read.sh`, line 693: `instruction_names() { env LC_ALL=C grep -zaiE '(^|/)((claude|agents?|gemini)(\.[a-z0-9_-]+)?|skill)\.md$' ...`). HEAD has `PROMPT_DIR='(^|/)\.claude/(commands|agents|output-styles|skills)/'` (`scripts/lib/dev-cycle-read.sh:484`), and a probe showed a checkout-only symlinked prompt failing the main walk (Claim 5). The imprecision is in the untraced list. The lib's own comment names three untraced directories: "the other three are untraced, read as a superset" (`scripts/lib/dev-cycle-read.sh:481-482`). The rubric's A2 says skills/ was added "(an untraced superset)". The row names only agents/ and output-styles/. The precise version: "`agents/`, `output-styles/` and `skills/` are an untraced superset."

**Evidence:** `docs/reviews/override-log.md:463`, `scripts/lib/dev-cycle-read.sh:476-485`, `docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a4.md:62`

---

## Claim 4: Rows 464-467: "`truthwalk` owns the order for both callers; ... check_fix lower-cases through the lib's `lower` and refuses with a reason when tr fails (tested)"; "Both walks pop by index"; "The floor itself never calls pathform or main_entry, and its dot rule refuses `.github/x.yml` (tested)"; "The floor words a failed walk as one reason and does not call main_entry."

**Location:** `docs/reviews/override-log.md:464-467`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each row's statement about the code at HEAD. It does not establish the deferred items' revisit triggers.

check_fix's code:

```bash
# scripts/dev-cycle.sh:175-180 (excerpt ends :180; check_fix continues to :184 — read)
  if ! lp="$(lower "$a")"; then echo "skip $a: the path could not be lower-cased; file it instead"; return; fi
  if truthrule "$lp" && [[ "$TRUTH_WHY" == cycle ]]; then ...
  elif truthwalk tree "$lp"; then
```

Both walks pop by index: `f="${queue[qi]}"; qi=$((qi + 1))` (`scripts/lib/dev-cycle-read.sh:857`, `:919`). floor's body (`:1039-1061`) calls only `need_root`, `lower`, `truthrule`, `ownfile` and `truthwalk`, so neither `pathform` nor `main_entry` is called (paraphrased — no quote available because the claim is an absence over the whole function, read in full). The tests pin `.github/x.yml "$DOT"` and check_fix's tr-failure line.

**Evidence:** `scripts/dev-cycle.sh:171-184`, `scripts/lib/dev-cycle-read.sh:856-858`, `:917-919`, `:1039-1061`, `test/scripts/build-loop-check.bats:1031-1061`, `:1081-1105`

---

## Claim 5: "The tree walk skips a symlinked prompt start (`inrepo_here`), so --check-fix answers ok for a doc only that command names, while the floor fails closed ... No prompt file is tracked here."

**Location:** `docs/reviews/override-log.md:468`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a symlinked prompt start that exists only in the checkout, and this repo's tracked set. It does not establish behaviour for a symlinked rules/ start; rules/ is not PROMPT_DIR, and main follows those links.

Probe `probes/walks.sh` added `.claude/commands/l.md -> ../../docs/t.md` (t.md holds `@z.md`) to a fixture after a successful walk, then called `import_reset`. Output: `after checkout prompt link: main walk failed; tree walk ok` and `tree docs/z.md: -`. The code: the tree walk requires `inrepo_here "$f"` (`scripts/lib/dev-cycle-read.sh:849`), and main_checkout refuses a non-plain path with `plaindir "$c" || return 1` (`:834`). The tracked prompt set is empty: `git ls-files -z | instruction_names | grep -i '\.claude/'` printed nothing. Command: `timeout 60 env LC_ALL=C bash probes/walks.sh /tmp/u2a4f-fcr3-iU2i/r1`, run at 2026-10-08T07:11Z, exit 0.

**Evidence:** `scripts/lib/dev-cycle-read.sh:845-852`, `:832-836`, `/tmp/u2a4f-fcr3-iU2i/walks.out`

---

## Claim 6: "floor run before resolve_main words its refusal as a walk failure"; "truthrule empties TRUTH_WHY when it passes"; "prompt_bases now returns one list of bases"

**Location:** `docs/reviews/override-log.md:473`, `:475`, `:477`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the three code statements. It does not establish the rows' dispositions.

Before resolve_main, `main_imports` returns at `main_by_name || return 1` (`scripts/lib/dev-cycle-read.sh:892`). truthwalk then returns 0 with `TRUTH_WHY=walk`, and floor words it as `"the default branch's instruction files could not be walked for @ imports"` (`:1058`). The test "No default branch found by name" pins this. truthrule opens with `TRUTH_WHY=""` (`:991`). prompt_bases sets one array (`:495-503`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:889-892`, `:990-1011`, `:1057-1059`, `test/scripts/build-loop-check.bats:1097-1102`

---

## Claim 7: "iteration 2's fixes ... took the unit to 469; no part splits off without the rest it fixes, so the unit lands whole and the merge message states the size."

**Location:** `docs/reviews/override-log.md:479`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the line counts at each commit, measured as added plus deleted lines outside docs/. It does not establish which counting rule decision log 62 intends.

`git diff --numstat main...<c> -- . ':!docs'` totals: c934adbc 381, 03be719e 443, a5ad8c08 469, HEAD 2b6f2f91 471. The 37-line test and 25-line lib/dev-cycle.sh growth from 381 to 443 also checks out (test 194−157 = 37; 249−224 = 25). The row is correct for a5ad8c08. At HEAD the unit is 471: 2b6f2f91 added two comment lines to the lib. The merge message should state 471, not 469.

**Evidence:** `docs/reviews/override-log.md:479`; command output in this session (cwd the worktree, run at 2026-10-08T07:09Z, exit 0)

---

## Claim 8: "Re-run at 03be719e over 3,098 paths: identical."

**Location:** `docs/reviews/override-log.md:480`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the path count of 03be719e's tree. It does not re-run the comparison at 03be719e; Claim 2 re-ran it at HEAD.

`git ls-tree -r --name-only 03be719e | grep -vc '[[:space:]]'` gives 3098.

**Evidence:** `docs/reviews/override-log.md:480`

---

## Claim 9: "The tree walk skips a symlinked start file, instruction or prompt (`inrepo` drops it), so an import from one passes `--check-fix`; the main walk follows a symlinked instruction file and fails on a symlinked prompt, so the floor refuses."

**Location:** `docs/working/known-issues-dev-cycle.md:16`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a symlinked instruction file main stores (followed), a symlinked prompt main stores (walk fails; test), and a checkout-only symlinked prompt (walk fails; Claim 5). It does not cover two further cases. A checkout-only symlinked instruction file also fails the walk instead of being followed: main_checkout answers 1, and the floor still refuses. And the tree walk's check is `inrepo_here`, the need_root-free form of `inrepo`.

The main walk's symlink arm refuses whenever prompt bases exist: `[[ ${#xs[@]} -eq 0 ]] || { IMPORTED_MAIN=error; return 1; }` (`scripts/lib/dev-cycle-read.sh:928`). A prompt always has at least the top-level base, because prompt_bases starts with `pb_a=("")` (`:497`). The test "main walk fails on a prompt start main stores as a symlink" passes: a rules link gives `walk ok`, a commands link gives `walk failed`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:926-946`, `:495-503`, `test/scripts/build-loop-check.bats:1157-1163`, `/tmp/u2a4f-fcr3-iU2i/walks.out`

---

## Claim 10: A5's U2a4 additions: "`isstart`'s files start both walks (U2a4: instruction files and `.md` files under `.claude/rules/`, `commands/`, `agents/`, `output-styles/` and `skills/` at any depth)"; "the lib header's numbered gate caller contract ... is the one statement of what a caller owes the walk and the floor: a clean worktree at MAIN_SHA, empty `ls-files` stderr, the git environment, `LC_ALL=C`, the cache, the order of floor and main_entry"; "U2a4 makes them starts in both walks (`isstart`), resolved against the top level and every enclosing `.claude/`'s directory as well as their own, a quoted `@"name"` read without its quote ..., and fails the main walk on one main stores as a symlink"

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the start set, the contract's topics (header items 1-6), the base set and the quoted read. It does not cover the extra bases noted in Claim 27, which only over-read.

The header's items 1 (LC_ALL=C), 2 (clean worktree, stderr, git environment), 4 (cache) and 5 (floor before main_entry) carry exactly these topics (`scripts/lib/dev-cycle-read.sh:44-62`). Probe `walks.sh` showed, for both walks, `c/.claude/.claude/commands/y.md`'s `@q.md` reaching `c/.claude/q.md`, `c/q.md`, `q.md` and the file's own directory, and `@"docs/s p.md"` reaching `docs/s p.md`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:42-68`, `:476-503`, `/tmp/u2a4f-fcr3-iU2i/walks.out`

---

## Claim 11: F11: "the caller contract is the lib header's numbered list (U2a4)"; gap "a prompt file read by a session started outside the top level and the directories holding its enclosing `.claude/` directories"; "one start rule (`isstart`: ... `.claude/{rules,commands,agents,output-styles,skills}/` at any depth; a command's names ... also resolve against its session directories (the top level and each enclosing `.claude/`'s directory), a quoted `@"name"` is read without its quote, and a prompt start main stores as a symlink fails the walk)"

**Location:** `docs/working/plan-build-loop-handoff.md:126`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the U2a4 additions to F11. It does not cover the pre-existing U2a3/U2a3c text, which earlier passes checked.

The code matches as quoted in Claims 9 and 10. `PROMPT_DIR` excludes rules/, so rules/ files resolve only against their own directory, consistent with "a command's names".

**Evidence:** `scripts/lib/dev-cycle-read.sh:484-503`, `/tmp/u2a4f-fcr3-iU2i/walks.out`

---

## Claim 12: U2a4 bullet: "Built 2026-10-07: `truthrule` ... and `truthwalk` (walk, then isimported), which check_fix and floor both call; `isstart` for both walks, with `agents/`, `output-styles/` and `skills/` added as an untraced superset and a prompt's names resolved against the top level and every enclosing `.claude/`'s directory (`prompt_bases`, the parser's further base directories); the index queue pop (row 461); the lib header's numbered gate caller contract (row 459)."

**Location:** `docs/working/plan-build-loop-handoff.md:278`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each built item named. It does not establish the deferral of IMPORTED_MAIN_WHY (a decision).

check_fix calls `truthrule` and `truthwalk tree` (`scripts/dev-cycle.sh:177`, `:180`). floor calls `truthrule "$lp"` and `truthwalk main "$lp"` (`scripts/lib/dev-cycle-read.sh:1044`, `:1057`). Rows 459 and 461 are the U2a3c caller-contract and queue-pop rows (read at those lines).

**Evidence:** `scripts/dev-cycle.sh:171-184`, `scripts/lib/dev-cycle-read.sh:1039-1061`, `docs/reviews/override-log.md:459`, `:461`

---

## Claim 13: U2b bullet: "keeps every item of the lib header's numbered gate caller contract (U2a4; the one statement of these duties, not restated here), and builds item 3's refusal (A5): a checkout where `git check-attr` shows a `working-tree-encoding`, `filter` or `ident` attribute on any path the walk reads, or whose `core.symlinks` is false."

**Location:** `docs/working/plan-build-loop-handoff.md:279`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the pointer and item 3's content. It does not establish U2b's future build.

Header item 3: "Refuse a checkout whose core.symlinks is false or with a working-tree-encoding, filter or ident attribute on any path the walk reads ... U2b builds this; the walk does not check it." (`scripts/lib/dev-cycle-read.sh:51-54`). `grep -n 'check-attr\|core.symlinks'` over both scripts matches only the comment (paraphrased — no quote available because the claim covers absence of code).

**Evidence:** `scripts/lib/dev-cycle-read.sh:51-54`

---

## Claim 14: "--check-fix ... not ... an instruction or prompt file, or a file one names after an @, read broadly; compared ignoring case"; "The denials it shares with the self-merge floor are the lib's truthrule."

**Location:** `scripts/dev-cycle.sh:50-54`, `:169-170`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers check_fix's use of truthrule and truthwalk tree and its identity with main over tracked paths (Claim 2). It does not cover a symlinked prompt start, which the tree walk skips (A2, Claim 5).

check_fix's `truthrule "$lp"` refuses `instr` for every isstart name, and `truthwalk tree` walks from every isstart start (`scripts/lib/dev-cycle-read.sh:849`). Claim 2's comparison is the executed half.

**Evidence:** `scripts/dev-cycle.sh:166-184`, `scripts/lib/dev-cycle-read.sh:990-1011`

---

## Claim 15: "check_brief, isimported, truthwalk (for tree or main), floor and the import walks exit 1 (need_root) unless ROOT_REAL is set, is the current directory and is a repository's top level"

**Location:** `scripts/lib/dev-cycle-read.sh:17-19`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the U2a4 additions (truthwalk, floor). It does not re-check the pre-existing members.

Probe `probes/truthwalk.sh` with ROOT_REAL unset printed `bogus rc=0 why=walk (no ROOT_REAL, no exit)`. For `( truthwalk tree x; echo "not reached" )` it printed `dev-cycle-read.sh: ROOT_REAL is not set; ...` and the subshell exited 1. floor's first statement is `need_root` (`:1041`). Command: `timeout 30 env LC_ALL=C bash probes/truthwalk.sh /tmp/u2a4f-fcr3-iU2i/r1`, run at 2026-10-08T07:13Z, exit 0.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1007-1011`, `:1039-1043`, `/tmp/u2a4f-fcr3-iU2i/truthwalk.out`

---

## Claim 16: Contract item 1: "Run as above, with main found by name, under LC_ALL=C (under a UTF-8 locale a non-UTF-8 name on main fails the walk)."

**Location:** `scripts/lib/dev-cycle-read.sh:44-45`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers C.UTF-8 against C for a tracked `docs/b\xff.md`. It does not test other UTF-8 locales (en_US.UTF-8 is not installed here).

Probe `probes/locale.sh` printed `C: ok` and `C.UTF-8: failed`. Command: `timeout 60 bash probes/locale.sh /tmp/u2a4f-fcr3-iU2i/r3`, run at 2026-10-08T07:12Z, exit 0.

**Evidence:** `scripts/lib/dev-cycle-read.sh:893-899`, `/tmp/u2a4f-fcr3-iU2i/locale.out`

---

## Claim 17: Contract item 2: "the walk reads main's blob for every path main stores, and the checkout only where main lacks a path ... where git ls-files prints nothing on stderr (any fails the walk)"

**Location:** `scripts/lib/dev-cycle-read.sh:46-50`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the blob-first read and the stderr rule. It does not establish the git-environment list, which it hands to the caller.

In probe `probes/ancdiff2.sh`, CLAUDE.md on main imports docs/a.md. The fixture then ran `git rm --cached CLAUDE.md` and rewrote the file in the checkout to import docs/z.md. HEAD's floor refused docs/a.md and passed docs/z.md, so main's blob was read and the checkout copy was not. The code: `[[ -n "${ent[$f]+set}" ]] || cand+=("t:$f")` (`:903`), and `checkout_md` fails on any stderr: `{ e="$(md_ls --cached --others 2>&1 >&3)"; } 3>&1 && [[ -z "$e" ]]` (`:792`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:792`, `:902-911`, `:921-925`, `/tmp/u2a4f-fcr3-iU2i/ancdiff2.out`

---

## Claim 18: Contract item 4: "Call import_reset before each gate decision and after any checkout change ..., or when HOME, IMPORT_OUT_MAX or IMPORT_WORK_MAX changes: neither walk's cache key holds them."; "import_reset: the next call of either walk walks again"

**Location:** `scripts/lib/dev-cycle-read.sh:55-57`, `:554-555`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two cache keys and import_reset clearing both. It does not establish that IMPORT_HOME_DONE needs no reset; it does not, because it keys on HOME itself.

`import_reset() { IMPORTED_DONE=""; IMPORTED_MAIN_DONE=""; }` (`:555`). The keys are `IMPORTED_DONE="$ROOT_REAL"` (`:843`) and `IMPORTED_MAIN_DONE="$MAIN_SHA $MAIN_BY_NAME $ROOT_REAL"` (`:891`). Neither holds HOME or the budgets. The truthwalk/import_reset test ("c cached: -" then refused after the reset) passes (Claim 39).

**Evidence:** `scripts/lib/dev-cycle-read.sh:842-843`, `:890-891`, `:555`, `test/scripts/build-loop-check.bats:1198-1210`

---

## Claim 19: Contract item 5: "Ask floor about each changed path, in this shell, before pathform or main_entry (so .github/x.yml is refused as a dotfile, not as badform) ... Floor item 5 (symlinks, gitlinks) and the brief's own Status change are the caller's rules."

**Location:** `scripts/lib/dev-cycle-read.sh:58-62`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers floor's own handling of `.github/x.yml` and its lack of a mode check. It does not establish the caller's order (no caller exists yet).

truthrule's `elif [[ "/$1" == */.* ]]; then TRUTH_WHY="dot"` (`:994`) runs before anything form-based. pathform would refuse the `.github` component as badform: `[[ ... "$c" != [.][gG][iI][tT]* ]] || return 1` (`:186`). floor reads no mode (Claim 4). The suite pins `.github/x.yml "$DOT"`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:179-188`, `:990-1000`, `:1039-1061`

---

## Claim 20: Contract item 6: "Read a walk only through isimported or truthwalk: IMPORTED_MAIN=error reads as 'not imported' to a raw membership test"

**Location:** `scripts/lib/dev-cycle-read.sh:63-64`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the membership-test shape. It does not establish whether any code reads the lists raw (grep found only isimported doing so).

The membership test is `[[ "$IMPORTED_MAIN" == *$'\n'"$lp"$'\n'* ]]` (`:974`). The error value `error` holds no newline, so a raw test answers false ("not imported").

**Evidence:** `scripts/lib/dev-cycle-read.sh:553`, `:969-978`

---

## Claim 21: Contract items 7 and 8: "A second caller of main_checkout passes a fresh MEMO per walk and ENT, and only a PATH main lacks." / "Pass truthrule, isstart and ownfile a lower-cased path (floor and check_fix lower first; truthrule refuses an upper-case letter as case)."

**Location:** `scripts/lib/dev-cycle-read.sh:65-68`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the memo skip, the two callers' lowering, and truthrule's case word. It does not establish that ownfile's stem argument is lower-case; it comes from the brief name, which isbrief requires lower-case.

A MEMO hit breaks the bottom-up loop before any mode check above it: `if [[ -n "${mc_m[$c]+set}" ]]; then st="${mc_m[$c]}"; break; fi` (`:821`). floor runs `lp="$(lower "$1")"` (`:1043`), and check_fix runs `lp="$(lower "$a")"` (`scripts/dev-cycle.sh:176`). Probe output: `CLAUDE.md rc=0 case`, `Docs/X.md rc=0 case`, `.claude/rules/r.md rc=0 instr`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:810-837`, `:990-1000`, `:1043`, `/tmp/u2a4f-fcr3-iU2i/truthwalk.out`

---

## Claim 22: "The one start rule both walks use ... truthrule refuses the same names; instruction_names is its grep prefilter, and a test holds the two equal." / "It matches isstart's names; isstart stays the authority."

**Location:** `scripts/lib/dev-cycle-read.sh:476-485`, `:759-764`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers 40,000 generated paths (components drawn from start-relevant names, mixed case, a newline, DEL and a non-ASCII byte), 11 hand-built newline paths, and both walks calling isstart. It does not cover non-ASCII case folding; both sides are ASCII-only by design.

Probe `probes/fuzz.py` + `probes/fuzz.sh` printed `paths=40000 isstart=12741 prefilter=12741` and `SAME`, meaning the NUL-separated outputs were byte-identical. Newline cases such as `.claude/commands/a\nb.md` (both accept) and `x/y\nCLAUDE.md` (both refuse) agreed on all 11. truthrule's `elif isstart "$1"; then TRUTH_WHY="instr"` (`:993`) refuses the same set. The walks call `isstart "$lp"` (`:849`) and `isstart "$f"` (`:908`). Command: `python3 -I probes/fuzz.py fuzz.bin && timeout 300 bash probes/fuzz.sh /tmp/u2a4f-fcr3-iU2i`, run at 2026-10-08T07:12Z, exit 0.

**Evidence:** `scripts/lib/dev-cycle-read.sh:485`, `:764`, `:849`, `:908`, `:993`, `/tmp/u2a4f-fcr3-iU2i/want.bin`, `/tmp/u2a4f-fcr3-iU2i/got.bin`

---

## Claim 23: "prompt_dir MAP LP PATH: for a start under PROMPT_DIR (LP lower-cased, PATH as spelled), MAP[PATH] gets LP, so a walk knows to read it against prompt_bases."

**Location:** `scripts/lib/dev-cycle-read.sh:486-489`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the map write and both walks' lookups. It does not apply to rules/ starts, which by design never enter the map.

`[[ ! "$2" =~ $PROMPT_DIR ]] || pd_m[$3]="$2"` (`:489`). The lookups are `[[ -z "${pdir[$f]+set}" ]] || prompt_bases xs "${pdir[$f]}" "$f"` (`:857`, `:919`), keyed by the queued PATH as spelled. main_imports passes `prompt_dir pdir "$f" "${cand[i]:2}"` with `f` lowered (`:909`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:486-489`, `:851`, `:857`, `:909`, `:919`

---

## Claim 24: "prompt_bases NAME LP PATH: array NAME gets the directories a prompt start also resolves its names against ...: the top level and the one holding each .claude/ in its path (a nested one too ...), as PATH spells them, once each."

**Location:** `scripts/lib/dev-cycle-read.sh:490-503`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers nesting of any depth, a doubled `.claude/.claude/`, mixed-case spelling and uniqueness. It does not establish that the extra bases described below are harmless beyond over-reading (more paths refused).

The probe matched the claim for every real `.claude/`. `.claude/.claude/commands/x.md -> [] [.claude]`; `a/.claude/.claude/.claude/commands/x.md -> [] [a] [a/.claude] [a/.claude/.claude]`; `A/.Claude/Commands/B/.CLAUDE/skills/k/SKILL.md -> [] [A] [A/.Claude/Commands/B]` (as PATH spells it). No .claude/ directory is dropped: `"/.claude"` cannot overlap itself, so `${rest#*/.claude}` visits every occurrence in turn. Each base's length is strictly larger than the last, so none repeats.

The list can also hold a directory not described. A component that starts with `.claude` but is longer (`.claudex`, `.claude.x`), ahead of a real `.claude/`, adds the directory holding it: `a/.claudex/.claude/commands/x.md -> [] [a] [a/.claudex]` and `a/.claude.x/.claude/commands/y.md -> [] [a] [a/.claude.x]`. Here `[a]` is not the directory holding any `.claude/`. The cause is that `rest="${rest#*/.claude}"` (`:500`) matches `/.claude` as a prefix of `/.claudex`. This only over-reads, the safe direction. The precise version: "...the one holding each .claude/ in its path, and possibly the one holding a .claude-prefixed directory above one."

**Evidence:** `scripts/lib/dev-cycle-read.sh:495-503`, `/tmp/u2a4f-fcr3-iU2i/probes/pb.sh` (output in session: run at 2026-10-08T07:10Z, exit 0)

---

## Claim 25: Walk block comments: "resolves each @path against the importing file's directory (and a prompt's also against prompt_bases')"; "a prompt start (prompt_dir) main stores as a symlink ... fail the walk"; "A start file answers imported only when an import reaches it (floor refuses start files by truthrule)"; "Not covered ...: a prompt read by a session started outside prompt_bases' directories"

**Location:** `scripts/lib/dev-cycle-read.sh:504-552`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that both walks apply prompt_bases in every read arm (tree: one arm; main: the checkout and blob arms, with the symlink arm refusing any prompt). It does not cover the gitlink arm, which reads nothing.

Every read call passes `"${xs[@]}"`: `import_targets "$d" "${xs[@]}"` (`:859`, `:922`, `:924`). The symlink arm refuses when xs is non-empty (`:928`). IMPORTED_MAIN gains only parser output, `IMPORTED_MAIN+="$i"$'\n'` (`:953`), so a start that nothing imports is not listed. walks.sh showed both walks resolving a phase-2 (checkout-only) nested prompt against all its bases.

**Evidence:** `scripts/lib/dev-cycle-read.sh:856-869`, `:917-962`, `/tmp/u2a4f-fcr3-iU2i/walks.out`

---

## Claim 26: "The import targets in the text on stdin, for a file in directory $1 ..., a relative name resolved against $1 and against each further directory given (a prompt's session directories: prompt_bases)"; "IT_XDIRS: the further directories, each led by an x so "" survives split"; "the walks refuse a name holding a newline"

**Location:** `scripts/lib/dev-cycle-read.sh:579-582`, `:697-698`, `:727`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the encoding of several bases, including an empty one. It does not establish behaviour for a base holding a newline; the walks never build one, because both refuse newline names before prompt_bases runs.

`printf '@~/h.md @r.md\n' | import_targets a b c ""` printed `a/r.md b/r.md c/r.md r.md` among its prefixes, so the trailing `""` base survived. The code: `x="$(printf 'x%s\n' "${@:2}")"` (`:727`), then `nd = split(ENVIRON["IT_XDIRS"], dirs, "\n"); for (i = nd; i >= 1; i--) dirs[i] = substr(dirs[i], 2)` (`:698`). The suite's "parser resolves each relative name against every directory it is given" test passes.

**Evidence:** `scripts/lib/dev-cycle-read.sh:724-748`, `:696-702`, `/tmp/u2a4f-fcr3-iU2i/walks.out`

---

## Claim 27: The superset statement: "the one statement of it; known issue A5 and plan F11 point here ... each prefix of the run after it, up to the first blank (a NUL or a UNI_SPACES space counts as one), is a candidate name, with a backslash-escaped space read as a space."

**Location:** `scripts/lib/dev-cycle-read.sh:593-617`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the block's list of what the parser reads. It does not dispute the superset conclusion, which only gains from the omission.

The block calls itself "the one statement" of the parser's rules, but it does not mention the U2a4 quoted run. `if (substr(line, i + 1, 1) == "\"") names(line, i + 2, L, 1)` (`:674`) reads a second run after `@"` up to the closing quote, blanks included: `if (q) { if (ch == "\"") break }` (`:681`). walks.sh confirmed that `@"docs/s p.md"` yields `docs/s p.md`, a name that runs past a blank. Under the block's sentence, every candidate ends at the first blank. That understates what is read (over-read direction), so the superset claim still holds. The precise version adds: "after `@"`, each prefix of the run up to the closing quote, blanks included, is also a candidate."

**Evidence:** `scripts/lib/dev-cycle-read.sh:593-617`, `:664-686`, `/tmp/u2a4f-fcr3-iU2i/walks.out`

---

## Claim 28: "A mention in a command may be quoted ...: the run after the quote is read too, up to the closing quote, blanks included ...; such a name can match a real file, which the floor then refuses (pathform already refuses it to --check-fix)."

**Location:** `scripts/lib/dev-cycle-read.sh:669-674`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the parser's quoted run, both walks listing the name, and pathform refusing a name with a blank. It does not cover the Claude Code half (Claim 29). The read applies in every file, not only commands, which is a superset.

walks.sh: `tree docs/s p.md: imported` and `main docs/s p.md: imported`, so floor's `truthwalk main` refuses it. pathform's set `NAMECHARS='abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._/-'` (`:178`) excludes a blank, so check_fix answers "not an allowed path form" (`scripts/dev-cycle.sh:174`). The unquoted run still ends at blanks: `else if (ch == " " || ch == "\t" || ch == "\r") break` (`:683`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:664-686`, `:178-188`, `scripts/dev-cycle.sh:174`, `/tmp/u2a4f-fcr3-iU2i/walks.out`

---

## Claim 29: "@"docs/a b.md", which the prompt-mention reader of Claude Code 2.1.293 accepts"

**Location:** `scripts/lib/dev-cycle-read.sh:670`
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers nothing about the binary. It does not establish whether command expansion calls that reader (the rubric's i2 Claim 19c is also Unverifiable).

Checking this needs the Claude Code 2.1.293 package extracted into a scratch harness. The sandbox has no egress, and no harness is kept in the repo (A5 says the oracle "is not kept"). The rest of the lib says 2.1.292; this line names 2.1.293 (paraphrased — no quote available because the claim is about an external binary, not repo code).

**Evidence:** `scripts/lib/dev-cycle-read.sh:669-673`, `docs/working/known-issues-dev-cycle.md:18`

---

## Claim 30: The parser's work charge and output bound still hold, and a `~/` name is joined once per spelling (emit, put, names)

**Location:** `scripts/lib/dev-cycle-read.sh:628-663`, `:677-686`
**Type:** Performance / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that every candidate from either run passes through emit's and put's charges, and that ~/ names skip the base loop. It does not re-measure the per-file bound's wall time.

names() calls `emit(name)` for every prefix of both runs (`:684`). emit charges `work += length(c); if (work > wmax) exit 3` (`:629`), and put charges the resolved spelling (`:647`) and the print budget (`:661`). For `~/`, emit joins the home and returns through `if (substr(c, 1, 1) == "/") { put(c); return }` (`:641`) before the per-base loop (`:642`). Probe output for `@~/h.md` with four bases: `home/h.md` printed once. The 2,000-quote test passes (Claim 39).

**Evidence:** `scripts/lib/dev-cycle-read.sh:628-686`, `/tmp/u2a4f-fcr3-iU2i/walks.out`

---

## Claim 31: "Whether path $2 (any case) is imported ... a caller that words a failed walk asks truthwalk, which runs the walk first."

**Location:** `scripts/lib/dev-cycle-read.sh:964-968`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the pointer to truthwalk. It does not re-check isimported's pre-existing fail-closed rules.

truthwalk runs `main_imports || return 0` / `imported_names || return 0` before `isimported "$1" "$2"` (`:1009-1010`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:969-978`, `:1007-1011`

---

## Claim 32: "The read-as-truth rule --check-fix and floor share (plan D5 items 1, 2 and 4; ...): ... instr ..., dot (a .-prefixed component, a top-level one included), cycle (writable), settings (docs/dev-cycle.md), user (docs/constraints.md ...) or record (docs/decisions/, docs/human-author/), and case for a path holding an upper-case letter"

**Location:** `scripts/lib/dev-cycle-read.sh:979-989`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the seven words and their tests. It does not cover order, which the comment does not state. In the code, case is tested first and instr before dot, so `.claude/rules/r.md` answers instr, not dot.

The suite's truthrule table passes. The probe printed `docs/x/.y rc=0 dot`, `docs/working/briefs/2026-10-01-x.md rc=0 cycle`, `.claude/settings.json rc=0 dot` and `.claude/rules/r.md rc=0 instr`. The plan's D5 items 1, 2 and 4 are instruction files, dot components, and the cycle/constraints/records set (`docs/working/plan-build-loop-handoff.md:69-72`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:990-1000`, `docs/working/plan-build-loop-handoff.md:66-73`, `/tmp/u2a4f-fcr3-iU2i/truthwalk.out`

---

## Claim 33: "truthwalk WALK PATH: ... Returns 0 when the walk fails (TRUTH_WHY=walk) or reaches PATH (TRUTH_WHY=imported), else 1 with TRUTH_WHY empty; an unknown WALK answers walk without running one. For tree or main it exits through need_root."

**Location:** `scripts/lib/dev-cycle-read.sh:1001-1006`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the walk, unknown-WALK and need_root paths (executed) and the TRUTH_WHY-empty return (suite). It does not reach an end state that misleads a caller: the extra return case below fails closed.

The unknown-WALK and need_root behaviour was executed (Claim 15), and the suite pins `b: []`. The comment omits one case. When isimported's own `lp="$(lower "$2")" || return 0` (`:972`) fails, truthwalk returns 0 with `TRUTH_WHY=imported` although PATH was not reached (`TRUTH_WHY=imported; isimported "$1" "$2" || ...`, `:1010`). Both callers would then print the "imports it" wording for a tr failure. The direction is safe (a refusal). The precise version: "Returns 0 when the walk fails (walk), or when it reaches PATH or PATH cannot be lower-cased (imported)."

**Evidence:** `scripts/lib/dev-cycle-read.sh:969-978`, `:1007-1011`, `/tmp/u2a4f-fcr3-iU2i/truthwalk.out`

---

## Claim 34: ownfile's comment: "its working docs, docs/working/{research,plan,checkpoint,handoff,test-strategy}-STEM.md, and a review it adds, docs/reviews/STEM.md or docs/reviews/NAME-STEM.md (a modified or deleted review is never its own)"

**Location:** `scripts/lib/dev-cycle-read.sh:1012-1017`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the full-stem match, the A-only review rule and the empty stem. It does not establish that a status letter like R100 is truncated before the call; the floor comment hands that to the caller.

`[[ "$3" == A && "$1" == docs/reviews/* && "$b" != */* && ( "$b" == "$2.md" || "$b" == *"-$2.md" ) ]]` (`:1022`). The suite's ownfile test passes (including D on its own name and the empty stem), and the floordiff probe gave the same answers for A, M and D as the ancestor.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1018-1023`, `test/scripts/build-loop-check.bats:1065-1079`, `/tmp/u2a4f-fcr3-iU2i/floordiff.out`

---

## Claim 35: floor's comment: "The self-merge floor (plan D5 items 1-4) ... $3 the diff-tree status letter alone (R for R100; only A makes a review the brief's own) ... floor item 5, symlinks and gitlinks, is the caller's mode rule"; and (task check 6) floor refuses everything plan D5 items 1-4 and the pre-split ancestor refuse

**Location:** `scripts/lib/dev-cycle-read.sh:1027-1037`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers D5 items 1-4 against floor's branches, and a differential against `feat/build-loop-u2a2-full`'s floor (6c41aea2) over 41 paths × 3 status letters in a fixture with instruction, rules and command starts. It does not cover a non-clean checkout. There the ancestor refuses one case that HEAD passes: a start main stores, removed from the index and edited in the checkout. That violates contract item 2 and matches main's walk since U2a3c.

Probe `probes/floordiff.sh` (ancestor lib from `git show feat/build-loop-u2a2-full:scripts/lib/dev-cycle-read.sh`) produced 123 rows per lib. No row was refused by the ancestor and passed by HEAD. HEAD additionally refuses `docs/c.md`, which only `.claude/commands/c.md` imports (`DIFF A/docs/c.md#P##R#an instruction file on the default branch imports it ...`). The other differences are wording only: `instr` before `dot` for `.claude/...`, and "an instruction or prompt file". `probes/ancdiff2.sh` gave `anc.sh docs/z.md: an instruction file on the default branch imports it ...` against `dev-cycle-read.sh docs/z.md: -` for the unclean-checkout case above, which is contract item 2's documented model ("the walk reads main's blob for every path main stores"). Items 1-4 map to branches as follows: instruction and prompt (`instr`), dot, `GATE_CODE` covering D5 item 3's four files and all of `scripts/lib/`, cycle/settings/user/record plus `docs/thoughts/*` and the ownfile branches. Commands: `timeout 120 env LC_ALL=C bash probes/floordiff.sh .../r2 .../anc.sh <HEAD lib>` and `timeout 60 env LC_ALL=C bash probes/ancdiff2.sh .../r4 ...`, run at 2026-10-08T07:12-07:15Z, exit 0.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1024-1061`, `docs/working/plan-build-loop-handoff.md:66-73`, `/tmp/u2a4f-fcr3-iU2i/floordiff.out`, `/tmp/u2a4f-fcr3-iU2i/ancdiff2.out`

---

## Claim 36: FLOOR_WHY for an import: "an instruction file on the default branch imports it with @ (directly or through another import)"

**Location:** `scripts/lib/dev-cycle-read.sh:1059`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the refusal itself, which is right. It covers only the wording's two premises. The prompt-file half was settled as wording by rubric C10 (for check_fix's line); the checkout half is not named in the rubric or override rows.

The refusal is correct, but the reason states two things the walk does not require. (a) The importer can be a prompt file, not an instruction file: the floordiff `docs/c.md` row. (b) The importer can be a checkout-only start, not something on the default branch. The suite pins this exact string for `docs/private.md`, which only an untracked `CLAUDE.local.md` imports: `printf 'Mine: @docs/private.md\n' > CLAUDE.local.md` ... `docs/private.md "$IMP"` (`test/scripts/build-loop-check.bats:1040`, `:1048`). A user acting on the reason would look on main and find no importer. The precise version: "an instruction or prompt file (on the default branch or in the gate's checkout) imports it with @". FLOOR_WHY has no caller until U2c (override row 472 already defers its shape there).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1057-1059`, `:517-523`, `test/scripts/build-loop-check.bats:1031-1061`, `/tmp/u2a4f-fcr3-iU2i/floordiff.out`

---

## Claim 37: "A line of 2,000 quotes after an @ costs quadratic, not cubic, parser work: the walk passes."

**Location:** `test/scripts/build-loop-check.bats:1188`
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers this line shape: one `@`, then 2,000 `"`. Here the unquoted run is one O(L²) pass and the quoted run stops at once. It does not cover lines with many `@`s, which are cubic in either run and stopped by the work bound (fail closed, pre-existing).

The suite passes. Each `@` starts at most two runs (`:668`, `:674`). For this line the quoted run starts at a `"` and breaks at once (`if (q) { if (ch == "\"") break }`, `:681`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:664-686`, `/tmp/u2a4f-fcr3-iU2i/blc.out`

---

## Claim 38a: Commit messages' test counts, line counts and code claims: d861183d (7 new tests), c934adbc ("build-loop-check 75 ... 381 changed code lines"; "truthwalk LP WALK"), 03be719e ("build-loop-check 78/78 ... 443"), a5ad8c08 ("build-loop-check 78/78, build-loop-read 19, dev-cycle 78, fixture-git-env 2, fixture-hermeticity 2, hermeticity-lint 53; shellcheck -S warning clean ... 469"; R1 "a/.claude/.claude/commands/x.md now also reads against a/.claude"; A8; C24), ee5108bd ("30 claims: 0 Incorrect, 1 Stale, 6 Mostly accurate"), d7cdc1ea ("six rows dispose of the U2a4 revisit triggers")

**Location:** `git log main..HEAD` (commits d861183d, c934adbc, d7cdc1ea, ee5108bd, 03be719e, a5ad8c08, 2b6f2f91)
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each count at its own commit, and each behavioral claim at HEAD or at its commit. It does not cover the "--check-fix identical" path counts (Claim 38b; the earlier ones are settled in rows 478 and 480) or "health check passed" (Claim 40).

`git show <c>:test/scripts/build-loop-check.bats | grep -c '^@test'` gives main 68, d861183d 75 (+7), c934adbc 75, 03be719e 78, a5ad8c08 78. Line totals are in Claim 7. c934adbc's own truthwalk is `case "$2" in main) ...; isimported "$2" "$1"`, so "LP WALK" was true then. The i1 report's header reads `22 verified, 6 mostly accurate, 1 stale, 0 incorrect, 1 unverifiable`. The six rows are `override-log.md:462-467`. R1 and A8 were confirmed by probe (Claims 24, 28), and C24 by Claim 15. At HEAD the suites ran: build-loop-check 1..78 exit 0, build-loop-read 1..19 exit 0, dev-cycle 1..78 exit 0, and `fixture-git-env` + `fixture-hermeticity` + `hermeticity-lint` 1..57 with 0 failing (2+2+53). `shellcheck -S warning` on both scripts exited 0. Commands: `timeout 900 bats test/scripts/<suite>.bats`, cwd the worktree, run from 2026-10-08T07:05Z.

**Evidence:** `/tmp/u2a4f-fcr3-iU2i/blc.out`, `/tmp/u2a4f-fcr3-iU2i/blr.out`, `/tmp/u2a4f-fcr3-iU2i/dc.out`, `/tmp/u2a4f-fcr3-iU2i/fx.out`, `docs/reviews/code-fact-check-report-build-loop-u2a4.md:10`

---

## Claim 38b: "--check-fix identical to main's over 3,098 paths" (commit a5ad8c08)

**Location:** `git log main..HEAD` (commit a5ad8c08 message, "Tests:" paragraph)
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count against a5ad8c08's own tree. It does not dispute identity, which this pass re-ran at HEAD over 3,099 paths (Claim 2).

a5ad8c08's tree holds 3,099 whitespace-free tracked paths (`git ls-tree -r --name-only a5ad8c08 | grep -vc '[[:space:]]'` → 3099). The extra path is the i2 fact-check report that commit adds, so the run likely predates staging it. The commit is immutable. A merge message should cite 3,099.

**Evidence:** `git show --stat a5ad8c08` (adds `docs/reviews/code-fact-check-report-build-loop-u2a4-i2.md`), `/tmp/u2a4f-fcr3-iU2i/cf-head.txt`

---

## Claim 39: The suites pass at HEAD (the rubric's and commits' "Tests:" lines, as executable guarantees)

**Location:** `docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a4.md:51`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers build-loop-check (78), build-loop-read (19), dev-cycle (78), fixture-git-env, fixture-hermeticity and hermeticity-lint (57 together), and shellcheck. It does not cover the full repo suite.

Results as in Claim 38a: every suite exited 0, and the outputs hold no `not ok` lines.

**Evidence:** `/tmp/u2a4f-fcr3-iU2i/blc.out`, `/tmp/u2a4f-fcr3-iU2i/blr.out`, `/tmp/u2a4f-fcr3-iU2i/dc.out`, `/tmp/u2a4f-fcr3-iU2i/fx.out`

---

## Claim 40: "health check passed" (commit c934adbc)

**Location:** `git log main..HEAD` (commit c934adbc message)
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers nothing. The claim is about c934adbc's tree, and `scripts/health-check.sh` runs the whole repo suite (its check 5); this pass did not run it at that commit.

Verifying this needs `scripts/health-check.sh` run in a checkout of c934adbc. That was out of this pass's cost scope; rubric C21 routes it to pr-prep step 5a (paraphrased — no quote available because no execution was made).

**Evidence:** `scripts/health-check.sh:1-30`

---

## Claims Requiring Attention

### Incorrect
None.

### Stale
None.

### Mostly Accurate
- **Claim 3** (`docs/reviews/override-log.md:463`): the untraced superset is agents/, output-styles/ and skills/ (the lib comment and rubric A2 say so). The row names only the first two.
- **Claim 7** (`docs/reviews/override-log.md:479`): 469 was true at a5ad8c08. HEAD is 471 (2b6f2f91 added two comment lines), so the merge message should state 471.
- **Claim 24** (`scripts/lib/dev-cycle-read.sh:490-503`): prompt_bases also adds the directory holding a `.claude`-prefixed component (`.claudex`, `.claude.x`) that sits above a real `.claude/`, because `${rest#*/.claude}` matches a prefix. This only over-reads.
- **Claim 27** (`scripts/lib/dev-cycle-read.sh:593-617`): "the one statement" of the parser's rules says candidates end at the first blank and omits the quoted run after `@"`, which reads past blanks. This only over-reads.
- **Claim 33** (`scripts/lib/dev-cycle-read.sh:1001-1006`): truthwalk also returns 0 with TRUTH_WHY=imported when isimported cannot lower-case PATH. This fails closed.
- **Claim 36** (`scripts/lib/dev-cycle-read.sh:1059`): the floor's import reason says "an instruction file on the default branch". The importer may be a prompt file (wording settled in C10) or a checkout-only start such as CLAUDE.local.md, and the test pins that wording for docs/private.md.
- **Claim 38b** (commit a5ad8c08): "3,098 paths". Its tree holds 3,099 whitespace-free paths. Identity holds at HEAD over 3,099.

### Unverifiable
- **Claim 29** (`scripts/lib/dev-cycle-read.sh:670`): Claude Code 2.1.293's prompt-mention reader accepting `@"…"`. Needs the binary (no egress).
- **Claim 40** (commit c934adbc): "health check passed". Needs `scripts/health-check.sh` at c934adbc (routed to step 5a by C21).

## Goal-Alignment Note
- Success criterion (restated verbatim): your report saved at the path your task names, structured per your skill, with every finding grounded in verbatim evidence.
- Answered: yes. All seven named checks were run, six of them executed (contract 1-8, prompt_bases, IMPORT_AWK, isstart/prefilter/truthrule/truthwalk, check_fix against main, floor against the ancestor and D5, plus commit/row/rubric counts).
- Out of scope: Claude Code binary behaviour (no egress); a health-check run at c934adbc; re-timing the override rows' performance figures (469-471), which earlier critics measured and this pass did not re-run.
- Escalate: Claim 7's size (471 at HEAD, not 469) and Claim 38b's path count (3,099) belong in the merge message. Claim 35's ancestor-only refusal (a start main stores, removed from the index and edited in the checkout) is a contract-item-2 case already on main since U2a3c: it is for U2b's clean-worktree check, not a U2a4 finding.
- Decisions I made: execution logs stay in my TMPDIR (`/tmp/u2a4f-fcr3-iU2i`), not under `docs/reviews/execution-logs/`, because the task said to write only this file. No hallucination-log entry was added (no Incorrect verdicts, and only this file may be written).
