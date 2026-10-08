Commit: 2b6f2f91
**Replication:** k=3 final confirming pass, replicate r2 (independent; not coordinated)

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u2a4 (branch `feat/build-loop-u2a4`)
**Scope:** `git diff main...HEAD` (main = 7afdb8d2, HEAD = 2b6f2f91): code comments in `scripts/lib/dev-cycle-read.sh` (the header's gate caller contract items 1-8, the walk block comments, isstart/prompt_dir/prompt_bases, IMPORT_AWK, truthrule/truthwalk/floor/ownfile) and `scripts/dev-cycle.sh`; commit messages `git log main..HEAD`; known issues A2 and A5; plan F11 and the U2a4/U2b bullets; the override-log rows dated 2026-10-07 for `feat/build-loop-u2a4` (lines 462-480); the rubric's A7 cell.
**Checked:** 2026-10-08
**Total claims checked:** 36
**Summary:** 29 verified, 6 mostly accurate, 0 stale, 0 incorrect, 1 unverifiable

Hallucination-pattern log read first. The path counts in Claims 2 and 33 and the line count in Claim 6 fit the logged "specific measured value quoted from an artifact set" class: each was re-measured, and each is off by 1-2 against the file set it names while its conclusion holds. None is a fabrication, so nothing goes in the log (this pass writes only this report).

Execution provenance: every command ran with `TMPDIR=/tmp/u2a4f-fc2-wXyc`, under `timeout`, from `/workspace/.claude/wt-build-loop-u2a4` unless a fixture directory is named. Probe scripts are in `/tmp/u2a4f-fc2-wXyc/`, captured output in `/tmp/u2a4f-fc2-wXyc/logs/`. Times are UTC on 2026-10-08, between 07:07 and 07:17. The fixture repos (`fx5-*`) and the `red/` tree export are under that TMPDIR. All exit codes are recorded per claim. No process was left running (`ps` checked at 07:16:35Z).

---

## Claim 1: "A 2,000-quote line walks ok (tested)."

**Location:** `docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a4.md:24` (A7 author note; the test comment `test/scripts/build-loop-check.bats:1188` says the same: "A line of 2,000 quotes after an @ costs quadratic, not cubic, parser work: the walk passes.")
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers a 2,000-quote line in an instruction file (the tested case) and in a top-level `.claude/commands/` prompt; does not establish a work-bound failure (the failure seen is the output bound).

The test puts the line in an instruction file only:

```bash
# test/scripts/build-loop-check.bats:1189
    { printf 'see @'; for ((i = 0; i < 2000; i++)); do printf '"'; done; printf '\n'; } > CLAUDE.md
```

The same line in a prompt start fails both walks, so floor refuses every path. `probe5.sh` (one fixture repo per case) printed:

```
instr tree ok
instr main ok
instr floor docs/x.md passes
prompt tree FAILED
prompt main FAILED
prompt floor docs/x.md: the default branch's instruction files could not be walked for @ imports
```

A prompt adds bases. `prompt_bases` always seeds `pb_a=("")` (`scripts/lib/dev-cycle-read.sh:497`), so `.claude/commands/q.md` is read against `.claude/commands` and `""`. The unquoted run's 2,000 prefixes print about 2 MB per base, so two bases pass `IMPORT_OUT_MAX=4000000` (`:562`). `probe2.sh` shows this on the parser alone: two bases, parser work `/6094844` (under the 50,000,000 work bound), and rc=1. That points to the output bound. The fix A7 names (no cubic recursion) holds. The failure is closed, and it is the class override row 469 (U2a4 i1 performance F2) already declined. The claim holds for the case the test covers; for a prompt start it does not.

**Evidence:** `test/scripts/build-loop-check.bats:1188-1195`; `scripts/lib/dev-cycle-read.sh:495-503`, `:562`, `:677-686`; `bash /tmp/u2a4f-fc2-wXyc/probe5.sh {instr,prompt}` (cwd: fixture `fx5-*`), exit 0 each, 07:13:43Z; `/tmp/u2a4f-fc2-wXyc/logs/probe5.out`, `/tmp/u2a4f-fc2-wXyc/logs/probe2.out`

---

## Claim 2: "--check-fix over this repo's tracked paths is identical to main's (3,092 of 3,097: the comparison skips the five names holding whitespace ...)"

**Location:** `docs/reviews/override-log.md:462` (the same conclusion in commits c934adbc, 03be719e and a5ad8c08; the counts are Claim 33)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers byte-identical `--check-fix` stdout from main's `dev-cycle.sh` and lib (extracted with `git show main:...`) and HEAD's, over all 3,104 tracked paths at HEAD (the five whitespace names included) plus 17 synthetic paths (mixed case, dot paths, prompt paths, `docs/thoughts/`, records); does not establish identity in a checkout that holds tracked prompt or rules files (this repo has none: `git ls-files | grep -ci '\.claude/'` → 0), where the tree walk now has more starts by design.

`cmp.sh` ran main's copy and HEAD's over the same 3,121 arguments and printed `main rc=0`, `head rc=0`, `IDENTICAL` (16 `ok`, 3,105 `skip`). The check_fix rewrite reads the shared rule:

```bash
# scripts/dev-cycle.sh:176-182
  if ! lp="$(lower "$a")"; then echo "skip $a: the path could not be lower-cased; file it instead"; return; fi
  if truthrule "$lp" && [[ "$TRUTH_WHY" == cycle ]]; then echo "skip $a: one of the cycle's own files (use --check-write)"
  elif [[ -n "$TRUTH_WHY" || ! "$lp" =~ ^docs/.*\.md$|^readme\.md$ || "$lp" =~ ^docs/(working|reviews)/ ]]; then
    ...
  elif truthwalk tree "$lp"; then
    if [[ "$TRUTH_WHY" == walk ]]; then echo "skip $a: the instruction-file import walk failed, ...
    else echo "skip $a: an instruction file names it after an @ ...; file it instead"; fi
  else check_path "$a"; fi
```
(excerpt ends :182; check_fix continues to :184 — read)

**Evidence:** `scripts/dev-cycle.sh:166-184`; `bash /tmp/u2a4f-fc2-wXyc/cmp.sh` (cwd `/workspace/.claude/wt-build-loop-u2a4`), exit 0, 07:07:05Z-07:07:23Z; `/tmp/u2a4f-fc2-wXyc/logs/cmp.log`, `/tmp/u2a4f-fc2-wXyc/main.out`, `/tmp/u2a4f-fc2-wXyc/head.out`

---

## Claim 3: Override row for rows 370/435: isstart adds `.claude/{commands,agents,output-styles,skills}/` .md files at any depth and gives the tree walk rules/; prompt names resolve against the top level and each enclosing `.claude/`'s directory; a quoted `@"name"` is read; a prompt start main stores as a symlink fails the main walk (the tree walk skips it)

**Location:** `docs/reviews/override-log.md:463`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each listed behaviour through the suite and the probes in Claims 23-27; does not establish Claude Code's own behaviour for agents/output-styles/skills (the row itself says "untraced superset"), and the bases are a superset (Claim 24).

The suite's tests at `test/scripts/build-loop-check.bats:1129-1163` and `:1182-1196` pass (build-loop-check 78/78). `isstart` and the symlink arm are quoted in Claims 22 and 25.

**Evidence:** `scripts/lib/dev-cycle-read.sh:484-485`, `:926-928`; `test/scripts/build-loop-check.bats:1129-1196`; `timeout 1200 bats test/scripts/build-loop-check.bats`, exit 0, 07:07:42Z; `/tmp/u2a4f-fc2-wXyc/logs/build-loop-check.tap`

---

## Claim 4: Override rows for 418/419/424 and 308/324/372/439: "truthwalk owns the order for both callers; ... check_fix lower-cases through the lib's lower and refuses with a reason when tr fails (tested)"; "The floor itself never calls pathform or main_entry, and its dot rule refuses .github/x.yml (tested)"

**Location:** `docs/reviews/override-log.md:464`, `:466`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers floor's body (no pathform or main_entry call), its `.github/x.yml` wording, and the failing-tr test; does not establish U2b/U2c's ordering, which has no caller yet.

`sed -n '/^floor() {/,/^}/p' ... | grep -c 'pathform\|main_entry'` → `0`. `probe4.sh` printed `REFUSE .github/x.yml: a dotfile or a path under a dot-directory` and `main_entry .github/x.yml: badform`. The tests are at `test/scripts/build-loop-check.bats:1045` (`.github/x.yml "$DOT"`) and `:1086-1091` (a failing `tr` → `skip docs/b.md: the path could not be lower-cased; file it instead`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1039-1061`; `scripts/dev-cycle.sh:176`; `bash /tmp/u2a4f-fc2-wXyc/probe4.sh`, exit 0, 07:12:55Z; `/tmp/u2a4f-fc2-wXyc/logs/probe4.out`

---

## Claim 5: Override row "Commit d861183d says 'All 7 fail on main's code' ..." and the d861183d message itself, "All 7 fail on main's code"

**Location:** `docs/reviews/override-log.md:478`; commit d861183d
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that d861183d's tree (its lib is main's) fails exactly the 7 new tests; does not re-establish *why* test 6 failed (the row records a fixture error, iteration 1 Claim 29).

`git archive d861183d | tar -x` into `$TMPDIR/red`, then `bats test/scripts/build-loop-check.bats` → `not ok` for tests 69-75 only, 68 `ok` (main holds 68 tests; d861183d 75).

**Evidence:** `bats test/scripts/build-loop-check.bats` (cwd `/tmp/u2a4f-fc2-wXyc/red`), exit 1, 07:08:43Z; `/tmp/u2a4f-fc2-wXyc/logs/red-d861183d.tap`

---

## Claim 6: "It fired: iteration 2's fixes ... took the unit to 469; ... the unit lands whole and the merge message states the size."

**Location:** `docs/reviews/override-log.md:479` (and commit a5ad8c08: "the unit is 469 code lines against main (381 at step 1a)")
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the numstat sum over `scripts/` and `test/` against main at each commit; does not establish which counting rule decision log 62 uses beyond this one, which reproduces every stated number.

`git diff --numstat main <c> -- scripts test` summed: c934adbc 381, 03be719e 443 (test 157→194 = +37, scripts 224→249 = +25, matching the row's "37 test lines and 25 lib and dev-cycle.sh lines"), a5ad8c08 469, and **2b6f2f91 471**. HEAD's comment-only commit added 2 lines (`scripts/lib/dev-cycle-read.sh | 4 +++-`), so the unit that lands is 471, not 469. The merge message should state 471.

**Evidence:** `git diff --numstat main {c934adbc,03be719e,a5ad8c08,2b6f2f91} -- scripts test` (cwd worktree), exit 0, 07:15Z; `git show 2b6f2f91 --stat`

---

## Claim 7: A2: "The tree walk skips a symlinked start file, instruction or prompt (`inrepo` drops it), so an import from one passes `--check-fix`; the main walk follows a symlinked instruction file and fails on a symlinked prompt, so the floor refuses. (Since U2a4 both walks start from `.claude/rules/` and the prompt directories: `isstart`.)"

**Location:** `docs/working/known-issues-dev-cycle.md:16`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers start files main stores (a symlinked rules file followed, a symlinked command file failing the walk) and the tree walk's `inrepo_here` skip; does not cover a symlinked start that only the checkout holds, which `main_checkout` refuses (`:832-834`), so the main walk fails rather than follows. The floor still refuses.

```bash
# scripts/lib/dev-cycle-read.sh:849
    if ! isstart "$lp" || ! inrepo_here "$f"; then continue; fi
# :926-928
      120000)  # a symlink: its text names the file read, as one more import
        # A prompt's names resolve against the session, not its target's directory: not modelled.
        [[ ${#xs[@]} -eq 0 ]] || { IMPORTED_MAIN=error; return 1; }
```
(excerpt ends :928; the 120000 arm continues to :946 — read)

The test at `test/scripts/build-loop-check.bats:1157-1163` (rules link → `walk ok`, `docs/x.md imported`; command link → `walk failed`) passes.

**Evidence:** `scripts/lib/dev-cycle-read.sh:838-870`, `:885-963`; `test/scripts/build-loop-check.bats:1157-1163`; `/tmp/u2a4f-fc2-wXyc/logs/build-loop-check.tap`

---

## Claim 8: A5: "`isstart`'s files start both walks (U2a4: instruction files and `.md` files under `.claude/rules/`, `commands/`, `agents/`, `output-styles/` and `skills/` at any depth)"; "U2a4 makes them starts in both walks (`isstart`), resolved against the top level and every enclosing `.claude/`'s directory as well as their own, a quoted `@"name"` read without its quote ..., and fails the main walk on one main stores as a symlink"

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the start set, the bases (the top level and every enclosing `.claude/`'s directory are all present: Claim 24), the quoted read and the symlink rule; does not establish that only those bases are added (Claim 24's superset) or Claude Code's behaviour for the three untraced directories.

See Claims 22-27 for the code and probes. In `probe1.out`, `a/.claude/.claude/.claude/commands/x.md -> [] [a] [a/.claude] [a/.claude/.claude]`: each enclosing `.claude/`'s directory is present.

**Evidence:** `scripts/lib/dev-cycle-read.sh:476-503`; `/tmp/u2a4f-fc2-wXyc/logs/probe1.out`; `/tmp/u2a4f-fc2-wXyc/logs/build-loop-check.tap`

---

## Claim 9: "the lib header's numbered gate caller contract, U2a4, is the one statement of what a caller owes the walk and the floor" (the header: "the one statement of it; plan step 5's U2b bullet and known issue A5 point here")

**Location:** `docs/working/known-issues-dev-cycle.md:18`; `scripts/lib/dev-cycle-read.sh:42-43`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers that the plan's U2b bullet and A5 now point to the header and no longer copy it, and that the other lib comments agree with it; does not establish that the header is the only place the duties are written.

The plan no longer restates the duties: U2b "keeps every item of the lib header's numbered gate caller contract (U2a4; the one statement of these duties, not restated here)" (`docs/working/plan-build-loop-handoff.md:279`). Inside the lib, three comments still state item 4's and item 7's duties in their own words. All three agree with the header:

```bash
# scripts/lib/dev-cycle-read.sh:545-548
# whose files it read, so a caller whose checkout may have changed (a file
# added or edited) sets IMPORTED_MAIN_DONE="" to walk again, and a cached
# error returns 1 again. A caller that changes HOME clears both
# IMPORTED_DONE and IMPORTED_MAIN_DONE (both caches are keyed without it).
# :560-561
# 2 KB, /workspace's about 6 KB. A caller that changes it clears IMPORTED_DONE
# and IMPORTED_MAIN_DONE before walking again.
# :800-801
# A MEMO hit skips that mode check too, so a MEMO serves one walk and one ENT.
# main_imports calls it only for paths main lacks.
```

"The one statement" is accurate for the numbered list. The cache duty is still also spelled as a raw assignment rather than `import_reset`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:42-68`, `:543-555`, `:560-561`, `:569-570`, `:793-809`; `docs/working/plan-build-loop-handoff.md:279`

---

## Claim 10: Plan F11: "the caller contract is the lib header's numbered list (U2a4)"; gap "a prompt file read by a session started outside the top level and the directories holding its enclosing `.claude/` directories"; "one start rule (`isstart`: instruction files and `.md` files under `.claude/{rules,commands,agents,output-styles,skills}/` at any depth; a command's names ... also resolve against its session directories (the top level and each enclosing `.claude/`'s directory), a quoted `@"name"` is read without its quote, and a prompt start main stores as a symlink fails the walk)"

**Location:** `docs/working/plan-build-loop-handoff.md:126`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the code facts F11 states; does not establish the untraced Claude Code behaviour behind them.

Same code and runs as Claims 7, 8 and 22-27. The gap wording matches the lib's own Not-covered line: "a prompt read by a session started outside prompt_bases' directories" (`scripts/lib/dev-cycle-read.sh:539-540`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:476-503`, `:536-541`; `/tmp/u2a4f-fc2-wXyc/logs/probe1.out`

---

## Claim 11: Plan U2a4 bullet: "Built 2026-10-07: `truthrule` (the shared denials as words) and `truthwalk` (walk, then isimported), which check_fix and floor both call; `isstart` for both walks, ...; the index queue pop (row 461); the lib header's numbered gate caller contract (row 459). ... `IMPORTED_MAIN_WHY` (row 376) moves to U2c."

**Location:** `docs/working/plan-build-loop-handoff.md:278`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers callers and the listed pieces; does not establish U2c's future work.

`grep` in `scripts/`: check_fix calls `truthrule` (`scripts/dev-cycle.sh:177`) and `truthwalk tree` (`:180`). floor calls `truthrule "$lp"` and `truthwalk main "$lp"` (`scripts/lib/dev-cycle-read.sh:1045`, `:1058`). Both walks pop by index: `f="${queue[qi]}"; qi=$((qi + 1))` (`:857`, `:919`). `IMPORTED_MAIN_WHY` appears nowhere in `scripts/` (paraphrased — no quote available because the claim covers absence of code; the grep finds no match).

**Evidence:** `scripts/dev-cycle.sh:177-180`; `scripts/lib/dev-cycle-read.sh:855-857`, `:916-919`, `:1039-1061`

---

## Claim 12: Plan U2b bullet: U2b "keeps every item of the lib header's numbered gate caller contract ... and builds item 3's refusal (A5): a checkout where `git check-attr` shows a `working-tree-encoding`, `filter` or `ident` attribute on any path the walk reads, or whose `core.symlinks` is false"

**Location:** `docs/working/plan-build-loop-handoff.md:279`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that item 3 is that refusal and that nothing in the lib builds it yet; does not establish U2b's build.

Item 3 reads: "Refuse a checkout whose core.symlinks is false or with a working-tree-encoding, filter or ident attribute on any path the walk reads ... U2b builds this; the walk does not check it." (`scripts/lib/dev-cycle-read.sh:51-54`). `grep -n 'check-attr\|core.symlinks'` over the lib and `scripts/*.sh` finds only the comment at `:51`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:51-54`

---

## Claim 13: --check-fix header: "(not ... a dot-directory or dotfile, an instruction or prompt file, or a file one names after an @, read broadly; compared ignoring case)"; check_fix comment: "The denials it shares with the self-merge floor are the lib's truthrule."

**Location:** `scripts/dev-cycle.sh:50-52`, `:169-170`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers check_fix's use of truthrule and truthwalk and its output for prompt, dot and mixed-case paths; does not establish that every truthrule word gets its own message (only `cycle` does, by design: override row 475).

The synthetic `docs/.claude/commands/x.md`, `.claude/rules/a.md` and `Readme.MD` rows in Claim 2's run give identical skip/ok lines on main and HEAD. Code is quoted in Claim 2.

**Evidence:** `scripts/dev-cycle.sh:166-184`; `/tmp/u2a4f-fc2-wXyc/head.out`

---

## Claim 14: Header: "inrepo, dirok, skipped, check_brief, isimported, truthwalk (for tree or main), floor and the import walks exit 1 (need_root) unless ROOT_REAL is set, is the current directory and is a repository's top level"

**Location:** `scripts/lib/dev-cycle-read.sh:17-19`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the new members, floor and truthwalk; does not re-check the older members.

`floor() { local lp; need_root; ...` (`:1039-1041`). truthwalk reaches need_root only through the walks: `case "$1" in main) main_imports || return 0 ;; tree) imported_names || return 0 ;; *) return 0 ;; esac` (`:1009`). Both walks call `need_root` first (`:841`, `:889`), and unknown WALK returns before any of them. `exit` inside a function called from an `if`/`elif` condition still ends the shell (paraphrased — no quote available because this is bash semantics, not repo code; floor's `elif truthwalk main` at `:1058` relies on it).

**Evidence:** `scripts/lib/dev-cycle-read.sh:127-131`, `:1007-1011`, `:1039-1061`

---

## Claim 15: Contract item 1: "Run as above, with main found by name, under LC_ALL=C (under a UTF-8 locale a non-UTF-8 name on main fails the walk)."

**Location:** `scripts/lib/dev-cycle-read.sh:44-45`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers main_imports' tree-record parse of a name holding byte 0xFF under C.UTF-8 vs C; does not establish every other locale-dependent test in the walks.

main_imports parses each record with `[[ "$rec" =~ ^([01234567]{6})\ ...\ [0123456789abcdef]{40,64}$'\t'(.+)$ ]] || return 1` (`:895`). `probe3.sh` with the same regex on `docs/a\xffb.md`: `LC_ALL=C.UTF-8 NOMATCH`, `LC_ALL=C MATCH`. So under UTF-8 the record does not parse and the walk returns 1. main_by_name is required by `main_by_name || return 1` (`:892`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:885-899`; `bash /tmp/u2a4f-fc2-wXyc/probe3.sh` under each locale, exit 0, 07:16:35Z; `/tmp/u2a4f-fc2-wXyc/logs/probe3.out`

---

## Claim 16: Contract item 2: "the walk reads main's blob for every path main stores, and the checkout only where main lacks a path), where git ls-files prints nothing on stderr (any fails the walk)"

**Location:** `scripts/lib/dev-cycle-read.sh:46-50`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers main_imports' read arms and checkout_md's stderr test; does not cover the tree walk's `tree_starts`, which does not test stderr (the contract is for floor and main_imports only).

`case "${ent[$f]-checkout}" in checkout) ... capped_read < "$f" ... 100644|100755) ... git cat-file blob "$MAIN_SHA:$f"` (`:921-925`): the checkout is read only when `ent` lacks the path. `checkout_md() { local e; { e="$(md_ls --cached --others 2>&1 >&3)"; } 3>&1 && [[ -z "$e" ]]; }` (`:792`), and main_imports runs `nul_list recs checkout_md || return 1` (`:902`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:792`, `:902`, `:921-925`

---

## Claim 17: Contract item 4: "Call import_reset before each gate decision and after any checkout change (rows 372, 439), or when HOME, IMPORT_OUT_MAX or IMPORT_WORK_MAX changes: neither walk's cache key holds them." and "import_reset: the next call of either walk walks again (caller contract item 4)."

**Location:** `scripts/lib/dev-cycle-read.sh:55-57`, `:554-555`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers both cache keys and import_reset's effect; does not establish the cost of calling it per decision.

`import_reset() { IMPORTED_DONE=""; IMPORTED_MAIN_DONE=""; }` (`:555`). Keys: `IMPORTED_DONE="$ROOT_REAL"` (`:843`) and `IMPORTED_MAIN_DONE="$MAIN_SHA $MAIN_BY_NAME $ROOT_REAL"` (`:891`). Neither holds HOME or either budget. `probe4.sh` printed `IMPORTED_MAIN_DONE before reset: 7afdb8d22df6...` and `after: '' ''`. The test at `test/scripts/build-loop-check.bats:1198-1210` (`c cached: -`, then `c: $IMP` after `import_reset`) passes.

**Evidence:** `scripts/lib/dev-cycle-read.sh:553-555`, `:841-843`, `:889-891`; `/tmp/u2a4f-fc2-wXyc/logs/probe4.out`

---

## Claim 18: Contract item 5: "Ask floor about each changed path, in this shell, before pathform or main_entry (so .github/x.yml is refused as a dotfile, not as badform) ... Floor item 5 (symlinks, gitlinks) and the brief's own Status change are the caller's rules."

**Location:** `scripts/lib/dev-cycle-read.sh:58-62`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the `.github/x.yml` contrast and that floor reads no mode; does not establish any caller's order (none exists).

floor reads no mode and calls no main_entry (Claim 4). `main_entry .github/x.yml` → `badform`, `floor` → the dot wording (`probe4.out`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:302-319`, `:1039-1061`; `/tmp/u2a4f-fc2-wXyc/logs/probe4.out`

---

## Claim 19: Contract item 6: "Read a walk only through isimported or truthwalk: IMPORTED_MAIN=error reads as 'not imported' to a raw membership test (row 419)."

**Location:** `scripts/lib/dev-cycle-read.sh:63-64`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the error sentinel and the membership form isimported uses; does not establish that no future caller reads the list raw.

`IMPORTED_MAIN=error` (`:553`, `:891`). The membership test `[[ "$IMPORTED_MAIN" == *$'\n'"$lp"$'\n'* ]]` (`:974`) is false against `error`, which holds no newline. isimported runs `main_imports || return 0` first, so it answers imported on failure.

**Evidence:** `scripts/lib/dev-cycle-read.sh:553`, `:969-978`

---

## Claim 20: Contract item 7: "A second caller of main_checkout passes a fresh MEMO per walk and ENT, and only a PATH main lacks."

**Location:** `scripts/lib/dev-cycle-read.sh:65-66`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers agreement with main_checkout's own comment and main_imports' call sites; does not test a second caller (none exists).

main_checkout's comment: "A MEMO hit skips that mode check too, so a MEMO serves one walk and one ENT. main_imports calls it only for paths main lacks." (`:800-801`). The calls are `[[ "${cand[i]:0:1}" == m ]] || main_checkout ent pok "$f"` (`:909`) and `[[ -n "${ent[$p]+set}" ]] || main_checkout ent pok "$p"` (`:957`), with `pok` local per walk (`:888`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:793-837`, `:888`, `:909`, `:957`

---

## Claim 21: Contract item 8: "Pass truthrule, isstart and ownfile a lower-cased path (floor and check_fix lower first; truthrule refuses an upper-case letter as case)."

**Location:** `scripts/lib/dev-cycle-read.sh:67-68`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers floor's, check_fix's and both walks' lower-casing before these calls, and the `case` word for ASCII upper case; does not cover non-ASCII upper case, which neither `tr` nor truthrule folds.

floor: `lp="$(lower "$1")" || {...}; if truthrule "$lp"` ... `ownfile "$lp" "$2" "$3"` (`:1042-1056`). check_fix: `lp="$(lower "$a")"` then `truthrule "$lp"` (`scripts/dev-cycle.sh:176-177`). The walks call `isstart` on `lower`/`lower_all` output (`:848-849`, `:904-908`). `probe4.sh`: `truthrule Docs/x.md -> case`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:990-1002`, `:1039-1061`; `/tmp/u2a4f-fc2-wXyc/logs/probe4.out`

---

## Claim 22: isstart comment: "an instruction file's name, or a .md file at any depth under a .claude/ directory's rules/ (memory, whose names resolve against the file's own directory) or PROMPT_DIR's commands/, agents/, output-styles/ or skills/ ... truthrule refuses the same names; instruction_names is its grep prefilter, and a test holds the two equal." and instruction_names: "It matches isstart's names; isstart stays the authority."

**Location:** `scripts/lib/dev-cycle-read.sh:476-485`, `:759-764`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the bats table (138 paths) and 39 odd names (mixed case, `.MD`, `.md` with an empty stem, non-ASCII, newlines, `.claude/other/`, `x.claude/rules/`); does not cover a name ending in a newline, which my probe mangled through `$(...)` (both walks refuse newline names before isstart: `:847`, `:897`, `:903`).

```bash
# scripts/lib/dev-cycle-read.sh:484-485
PROMPT_DIR='(^|/)\.claude/(commands|agents|output-styles|skills)/'
isstart() { [[ "${1##*/}" =~ $INSTRUCTION_FILE ]] || [[ "$1" == *.md && ( "$1" =~ $PROMPT_DIR || "/$1" == */.claude/rules/* ) ]]; }
# :764
instruction_names() { env LC_ALL=C grep -zaiE '(^|/)((claude|agents?|gemini)(\.[a-z0-9_-]+)?|skill)\.md$|(^|/)\.claude/(rules|commands|agents|output-styles|skills)/.*\.md$' || [[ $? -eq 1 ]]; }
```

`probe1.sh` printed one `DIFF` only, for `$'x/.claude/rules/y.md\n'`. That is the probe's artifact: `isstart "$(lower "$n")"` dropped the trailing newline. The test at `test/scripts/build-loop-check.bats:1172-1180` passes. Rules files are not marked by `prompt_dir`, which tests `PROMPT_DIR` only, so they resolve against their own directory. truthrule's first non-case test is `elif isstart "$1"; then TRUTH_WHY="instr"` (`:993`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:476-489`, `:759-764`, `:990-1002`; `bash /tmp/u2a4f-fc2-wXyc/probe1.sh`, exit 0, 07:10:03Z; `/tmp/u2a4f-fc2-wXyc/logs/probe1.out`

---

## Claim 23: "prompt_dir MAP LP PATH: for a start under PROMPT_DIR (LP lower-cased, PATH as spelled), MAP[PATH] gets LP, so a walk knows to read it against prompt_bases."

**Location:** `scripts/lib/dev-cycle-read.sh:486-489`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers prompt, rules and instruction inputs; does not cover imported (non-start) prompt files, which no walk marks.

`probe1.out`: `M[a/.claude/skills/s/SKILL.md]=a/.claude/skills/s/skill.md`, `M[.claude/commands/x.md]=.claude/commands/x.md`, and no entry for `.claude/rules/x.md` or `CLAUDE.md`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:489`; `/tmp/u2a4f-fc2-wXyc/logs/probe1.out`

---

## Claim 24: "prompt_bases NAME LP PATH: array NAME gets the directories a prompt start also resolves its names against, where a session reading it may have started: the top level and the one holding each .claude/ in its path (a nested one too: U2a4 i1 security F3), as PATH spells them, once each."

**Location:** `scripts/lib/dev-cycle-read.sh:490-503`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers 10 paths: top level, one level, `.claude/.claude/`, triple nesting, mixed case, two separated `.claude/`s, and a component that starts with `.claude` but is longer; does not establish whether a session can start in the extra directories (the reader model is U2b's).

The function, read whole:

```bash
# scripts/lib/dev-cycle-read.sh:495-503
prompt_bases() {
  local -n pb_a="$1"; local rest="/$2" n
  pb_a=("")
  while [[ "$rest" == */.claude/* ]]; do
    # Up to /.claude, not /.claude/: a .claude/ directly inside another keeps its slash (U2a4 i2 fact-check 1).
    rest="${rest#*/.claude}"; n=$(( ${#2} - ${#rest} - 8 ))
    (( n <= 0 )) || pb_a+=("${3:0:n}")
  done
}
```

Every real `.claude/` yields its parent, once, in PATH's spelling. For example `A/B/.claude/Commands/X.md -> [] [A/B]`, `.claude/.claude/commands/x.md -> [] [.claude]`, and `a/.claude/.claude/.claude/commands/x.md -> [] [a] [a/.claude] [a/.claude/.claude]`. The guard tests for `/.claude/`, but the strip is the shortest `*/.claude`. So a component that only *starts* with `.claude` and comes before a real `.claude/` also yields a base: `a/.claudex/.claude/commands/x.md -> [] [a] [a/.claudex]` and `a/.claude-old/b/.claude/skills/s/x.md -> [] [a] [a/.claude-old/b]`. `a` holds no `.claude/` in either path. This came with iteration 2's R1 fix: the earlier `#*/.claude/` strip matched only real ones. The extra base only over-reads (more names, refused). It costs budget, and Claim 1 shows budget can bind for prompts. A precise version: "the top level, the directory holding each .claude/ in its path, and (a superset) the one holding any earlier component that begins with .claude".

**Evidence:** `scripts/lib/dev-cycle-read.sh:490-503`; `bash /tmp/u2a4f-fc2-wXyc/probe1.sh`, exit 0, 07:10:03Z; `/tmp/u2a4f-fc2-wXyc/logs/probe1.out`

---

## Claim 25: Walk block comments: the tree walk "resolves each @path against the importing file's directory (and a prompt's also against prompt_bases')"; main_imports refuses "a prompt start (prompt_dir) main stores as a symlink"; "Not covered ... a prompt read by a session started outside prompt_bases' directories"; both walks apply the bases in every read arm

**Location:** `scripts/lib/dev-cycle-read.sh:504-542`, `:857-859`, `:919-928`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the tree walk's one read arm, main_imports' checkout and blob arms (both pass `"${xs[@]}"`) and its symlink arm (refuses when `xs` is non-empty, which it always is for a prompt since `pb_a=("")`); does not cover a prompt reached only by import (not a start), which reads against its own directory. Every tracked or listed `.md` under a prompt directory is a start, so this needs a spelling the start listing does not hold.

```bash
# scripts/lib/dev-cycle-read.sh:857-859 (tree walk; loop continues to :869 — read)
    f="${queue[qi]}"; qi=$((qi + 1)); xs=(); [[ -z "${pdir[$f]+set}" ]] || prompt_bases xs "${pdir[$f]}" "$f"
    if [[ "$f" == */* ]]; then d="${f%/*}"; else d=""; fi
    out="$(capped_read < "$f" | ... import_targets "$d" "${xs[@]}")" \
# :922, :924 (main walk): both arms end `import_targets "$d" "${xs[@]}")"`; :928 `[[ ${#xs[@]} -eq 0 ]] || { IMPORTED_MAIN=error; return 1; }`
```

Tests at `test/scripts/build-loop-check.bats:1129-1163`, `:1182-1196` pass for both walks.

**Evidence:** `scripts/lib/dev-cycle-read.sh:838-963`; `/tmp/u2a4f-fc2-wXyc/logs/build-loop-check.tap`

---

## Claim 26: import_targets: "a relative name resolved against $1 and against each further directory given (a prompt's session directories: prompt_bases)"; IMPORT_AWK BEGIN: "IT_XDIRS: the further directories, each led by an x so "" survives split."; import_targets: "the walks refuse a name holding a newline"

**Location:** `scripts/lib/dev-cycle-read.sh:579-582`, `:697-699`, `:727`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers 0, 1, 2 and 4 further directories, `""` among them (twice), absolute and `..` names; does not cover a directory holding a newline (refused upstream: `:847`, `:897`, `:903`).

`[[ $# -lt 2 ]] || x="$(printf 'x%s\n' "${@:2}")"` (`:727`), then `nd = split(ENVIRON["IT_XDIRS"], dirs, "\n"); for (i = nd; i >= 1; i--) dirs[i] = substr(dirs[i], 2)` (`:698`) and `for (i = 0; i <= nd; i++) put(root "/" dirs[i] "/" c)` (`:642`). `probe2.out`: `x @y.md` with `sub '' other/dir ''` yields `sub/y.md`, `y.md` and `other/dir/y.md`, and the duplicate `""` adds nothing (`tried`). `@/abs.md` yields nothing outside the root. `@../up.md` from `sub/deep` with base `a` yields `sub/up.md` and `up.md`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:627-704`, `:724-748`; `bash /tmp/u2a4f-fc2-wXyc/probe2.sh`, exit 0, 07:10:24Z; `/tmp/u2a4f-fc2-wXyc/logs/probe2.out`

---

## Claim 27: The superset statement: "each prefix of the run after it, up to the first blank ..., is a candidate name, with a backslash-escaped space read as a space ... Each candidate is trimmed of spaces, made absolute (ROOT_REAL/$1/name unless it starts with /) and resolved lexically" ("the one statement of it; known issue A5 and plan F11 point here")

**Location:** `scripts/lib/dev-cycle-read.sh:593-607`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the rules list inside the superset statement against IMPORT_AWK; does not change the superset conclusion. Both omissions over-read, and both are stated elsewhere in the same comment block or in scan's comment.

Called "the one statement", the rules list still gives the pre-U2a4 rules. A relative name is now joined to `ROOT_REAL/dirs[i]/name` for each further directory (`:642`), not only `ROOT_REAL/$1/name`. A quoted run is a second candidate run that reads past blanks to the closing quote (`:674`, `:681`). The function header (`:579-582`) and scan's comment (`:669-673`) state each, so the block as a whole is complete, but the "one statement" sentence a reader is pointed to is not. Precise version: "made absolute (ROOT_REAL/D/name for $1 and each further directory D, unless it starts with /)", plus "after @", also the run up to the closing quote, blanks included".

**Evidence:** `scripts/lib/dev-cycle-read.sh:579-617`, `:641-642`, `:664-686`; `/tmp/u2a4f-fc2-wXyc/logs/probe2.out`

---

## Claim 28: emit's ~/ handling with several bases: a `~/` name joins the home "in its spelled and real forms", once each, not once per base

**Location:** `scripts/lib/dev-cycle-read.sh:634-642`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers `~/n.md` with four bases; does not cover a home whose real path differs (one extra `put`, by the visible code).

```awk
# scripts/lib/dev-cycle-read.sh:636-642 (emit; starts :628 — read)
  if (substr(c, 1, 2) == "~/") {
    if (substr(home, 1, 1) != "/") exit 4
    if (homereal != home) put(homereal "/" substr(c, 3))
    c = home "/" substr(c, 3)
  }
  if (substr(c, 1, 1) == "/") { put(c); return }
  for (i = 0; i <= nd; i++) put(root "/" dirs[i] "/" c)
```

`probe2.out` for `@~/n.md` with `sub '' a b`: `home/n.md` once. The bare prefix `~` is read per base (`sub/~`, `~`, `a/~`, `b/~`), as any relative candidate is.

**Evidence:** `/tmp/u2a4f-fc2-wXyc/logs/probe2.out`

---

## Claim 29: scan/names: the quoted run is "read too, up to the closing quote, blanks included ...; such a name can match a real file, which the floor then refuses (pathform already refuses it to --check-fix)"; the unquoted run still ends at a blank; the work charge and output bound still hold

**Location:** `scripts/lib/dev-cycle-read.sh:664-686`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers a quoted run with a space and a tab, an unclosed quote, the escaped-space unquoted run, the output bound (`IMPORT_LEFT=10`) and the work bound (`IMPORT_WORK_LEFT=50`), and per-base work charging; does not cover a quoted mention spanning lines (the parser is line-based; a file name holding a newline fails both walks first).

```awk
# scripts/lib/dev-cycle-read.sh:677-686
function names(line, j, L, q,   ch, name) {
  name = ""
  for (; j <= L; j++) {
    ch = substr(line, j, 1)
    if (q) { if (ch == "\"") break }
    else if (ch == "\\" && substr(line, j + 1, 1) == " ") { ch = " "; j++ }
    else if (ch == " " || ch == "\t" || ch == "\r") break
    name = name ch; emit(name)
  }
}
```

`probe2.out`: `@"docs/a b.md" tail` yields `sub/docs/a b.md`, and the unquoted run stops at `sub/"docs/a`. `@"a<TAB>b.md"` yields `a<TAB>b.md`. `IMPORT_LEFT=10` → rc=1. `IMPORT_WORK_LEFT=50` → trailer `/58`, rc=1. The same text costs `/400` work with one base and `/1405` with four. Each `put` charges `work += length(c)` (`:647`). The floor refusing the quoted file is tested: `"docs/a b.md"` reads `imported` in both walks (`test/scripts/build-loop-check.bats:1191-1195`). pathform's `NAMECHARS` has no blank (`:178`), and check_fix runs pathform first (`scripts/dev-cycle.sh:174`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:178-188`, `:627-704`; `/tmp/u2a4f-fc2-wXyc/logs/probe2.out`

---

## Claim 30: "A mention in a command may be quoted (@"docs/a b.md", which the prompt-mention reader of Claude Code 2.1.293 accepts)"

**Location:** `scripts/lib/dev-cycle-read.sh:669-670`
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers nothing beyond the security report's quoted extractor text; does not establish that command expansion calls that extractor.

The security report quotes the binary's extractor as `(^|${JY})@"([^"]+)"` and says the caller is untraced (`docs/reviews/security-reviewer-review-2026-10-07-build-loop-u2a4.md`; i2 fact-check Claim 19c). Verifying it needs a caller trace in the 2.1.293 binary. The extractor's `[^"]+` also crosses a newline, which the line-based parser does not, but a file name holding a newline already fails both walks.

**Evidence:** `scripts/lib/dev-cycle-read.sh:669-675`; `docs/reviews/code-fact-check-report-build-loop-u2a4-i2.md:384-405`

---

## Claim 31: isimported: "a caller that words a failed walk asks truthwalk, which runs the walk first"; walk loops: "An index, not a copy per pop (quadratic in the files read: override row 461)."

**Location:** `scripts/lib/dev-cycle-read.sh:964-968`, `:855`, `:916`
**Type:** Architectural / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the call order and that the pop no longer copies; does not time the pop (override row 465 says there is no timing test).

truthwalk runs `main_imports`/`imported_names` and then `isimported "$1" "$2"` (`:1009-1010`). The pops are `f="${queue[qi]}"; qi=$((qi + 1))` (`:857`, `:919`). Phase 2 resets `qi=0` when it swaps in `tq` (`:918`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:855-857`, `:916-919`, `:964-978`, `:1007-1011`

---

## Claim 32: truthrule: "for a lower-cased path: returns 0 with TRUTH_WHY set when it refuses: instr ..., dot (a .-prefixed component, a top-level one included), cycle (writable), settings (docs/dev-cycle.md), user (docs/constraints.md ...) or record (docs/decisions/, docs/human-author/), and case for a path holding an upper-case letter"; truthwalk: "Returns 0 when the walk fails (TRUTH_WHY=walk) or reaches PATH (TRUTH_WHY=imported), else 1 with TRUTH_WHY empty; an unknown WALK answers walk without running one. For tree or main it exits through need_root."

**Location:** `scripts/lib/dev-cycle-read.sh:979-1011`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each word, the order (case, instr, dot, cycle, settings, user, record), truthwalk's three outcomes and the unknown WALK; does not establish that the comment's list order is the test order (the comment lists `case` last, while the code tests it first; the comment does not claim an order).

```bash
# scripts/lib/dev-cycle-read.sh:990-1002
truthrule() {
  TRUTH_WHY=""
  if [[ "$1" == *[ABCDEFGHIJKLMNOPQRSTUVWXYZ]* ]]; then TRUTH_WHY="case"
  elif isstart "$1"; then TRUTH_WHY="instr"
  elif [[ "/$1" == */.* ]]; then TRUTH_WHY="dot"
  elif writable "$1"; then TRUTH_WHY="cycle"
  elif [[ "$1" == docs/dev-cycle.md ]]; then TRUTH_WHY="settings"
  elif [[ "$1" == docs/constraints.md ]]; then TRUTH_WHY="user"
  elif [[ "$1" =~ ^docs/(decisions|human-author)/ ]]; then TRUTH_WHY="record"
  else return 1; fi
}
```

The order cannot hide a word check_fix maps. No writable path is an instruction or dot path: briefs start with a date, and the rest are fixed names. Claim 2's identity run confirms this. `probe4.out`: `bogus -> 0 TRUTH_WHY=walk`, `main docs/x.md -> 1 TRUTH_WHY=''`, `truthrule thoughts -> 1 ''`. The table test at `test/scripts/build-loop-check.bats:1104-1127` passes.

**Evidence:** `scripts/lib/dev-cycle-read.sh:198-201`, `:979-1011`; `/tmp/u2a4f-fc2-wXyc/logs/probe4.out`

---

## Claim 33: Commit a5ad8c08: "--check-fix identical to main's over 3,098 paths"

**Location:** commit a5ad8c08 (message body)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the count against a5ad8c08's own tree and the identity at HEAD; does not establish which file set the author's run used.

`git ls-tree -r --name-only a5ad8c08 | wc -l` → 3,104, of which five hold a blank (`git ls-files | grep -c ' '` → 5), so 3,099 whitespace-free paths. The message says 3,098, which is 03be719e's whitespace-free count, carried over: a5ad8c08 added `docs/reviews/code-fact-check-report-build-loop-u2a4-i2.md`. Identity holds over all 3,104 at HEAD (Claim 2). Override row 480 records the corrected 03be719e count but not this one.

**Evidence:** `git ls-tree -r --name-only {03be719e,a5ad8c08} | wc -l`, `git diff --name-status 03be719e a5ad8c08` (cwd worktree), exit 0, 07:13Z; `/tmp/u2a4f-fc2-wXyc/logs/cmp.log`

---

## Claim 34: Commit test counts: c934adbc "build-loop-check 75, build-loop-read 19, dev-cycle 78, fixture-git-env 2, fixture-hermeticity 2, hermeticity-lint 53"; 03be719e and a5ad8c08 "build-loop-check 78/78, build-loop-read 19, dev-cycle 78, fixture-git-env 2, fixture-hermeticity 2, hermeticity-lint 53; shellcheck -S warning clean"; 03be719e/a5ad8c08 line counts "381 ... 443 ... 469"

**Location:** commits c934adbc, 03be719e, a5ad8c08 (message bodies)
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the six suites and shellcheck at HEAD, the `@test` count of build-loop-check.bats at each commit, and the numstat line counts; does not re-run the suites at the earlier commits, or the health check c934adbc names.

At HEAD (`TMPDIR=/tmp/u2a4f-fc2-wXyc`): build-loop-check 78 ok/0 not ok, dev-cycle 78/0, build-loop-read 19/0, fixture-git-env 2/0, fixture-hermeticity 2/0, hermeticity-lint 53/0, all rc=0. `shellcheck -S warning scripts/dev-cycle.sh scripts/lib/dev-cycle-read.sh` rc=0 with empty output. `grep -c '^@test'` on build-loop-check.bats: main 68, d861183d 75, c934adbc 75, 03be719e 78, a5ad8c08 78, HEAD 78. Line counts are in Claim 6.

**Evidence:** `timeout 1200 bats test/scripts/{build-loop-check,dev-cycle,build-loop-read}.bats`, exit 0, 07:07:42Z-07:08:31Z; `timeout 600 bats test/scripts/fixture-git-env.bats test/fixture-hermeticity.bats test/hermeticity-lint.bats` and shellcheck, exit 0, 07:14:08Z-07:14:29Z; `/tmp/u2a4f-fc2-wXyc/logs/*.tap`, `/tmp/u2a4f-fc2-wXyc/logs/shellcheck.out`

---

## Claim 35: Commits a5ad8c08 and c934adbc, behavioural lines: "R1: prompt_bases strips up to /.claude, not /.claude/, so a .claude/ directly inside another keeps its base (a/.claude/.claude/commands/x.md now also reads against a/.claude)"; "A7: the quoted-mention read is a second candidate run from the character after the quote (awk function names), not a recursion in emit"; "A8: a quoted run ends only at its closing quote"; "the tree walk gains rules/ (main had it only in main_imports)"

**Location:** commits a5ad8c08, c934adbc (message bodies)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each statement against HEAD's code and main's diff; does not cover the superset side effect of R1 (Claim 24), which the message does not mention.

`probe1.out`: `a/.claude/.claude/commands/x.md -> [] [a] [a/.claude]`. `names` is quoted in Claim 29: emit has no recursion, and scan calls `names(line, i + 2, L, 1)` (`:674`). Main's tree walk tested only the basename: `- lp="$(lower "${f##*/}")"` / `- if [[ ! "$lp" =~ $INSTRUCTION_FILE ]]` (diff of `:848-849`), while main's main_imports had `"$f" == .claude/rules/*.md || "$f" == */.claude/rules/*.md`.

**Evidence:** `git diff main...HEAD -- scripts/lib/dev-cycle-read.sh`; `/tmp/u2a4f-fc2-wXyc/logs/probe1.out`, `/tmp/u2a4f-fc2-wXyc/logs/probe2.out`

---

## Claim 36: floor: "The self-merge floor (plan D5 items 1-4) ... $3 the diff-tree status letter alone (R for R100; only A makes a review the brief's own) ... The caller's duties are the gate caller contract's" and c934adbc: "floor PATH STEM STATUS, ownfile and GATE_CODE (plan D5 items 1-4), ported from feat/build-loop-u2a2-full"

**Location:** `scripts/lib/dev-cycle-read.sh:1027-1061`; commit c934adbc
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers floor's verdicts at HEAD against the pre-split ancestor's floor (`feat/build-loop-u2a2-full` 6c41aea2), run in this worktree over 3,104 tracked paths and 39 synthetic paths, for letters A and M, with stem `2026-10-07-x`; covers D5 items 1-4 clause by clause. It does not separate floor's logic from walk differences: both sides ran their own main_imports, and they agreed on this repo.

The ancestor and HEAD gave identical REFUSE/PASS for all 6,320 (path, letter) pairs (`diff` empty). So HEAD passes nothing the ancestor refused. By clause, every ancestor refusal is still in HEAD: instruction basename becomes `instr` (now a superset with prompt and rules paths), dot stays dot, GATE_CODE is unchanged, the walk failure or import moves to the last `elif truthwalk main` (still reached by every path not refused earlier, own files included), and cycle/dev-cycle.md, constraints, decisions/thoughts/human-author and non-own working/reviews files are all kept. D5 maps as follows: item 1 is `instr` plus the walk, item 2 is `dot`, item 3 is GATE_CODE (`^scripts/lib/` is wider than the one lib file D5 names), and item 4 is cycle/settings/user/record, `docs/thoughts/` and non-own working files. ownfile is byte-identical to the ancestor's. `[[ "$3" == A && ...` (`:1023`) makes only an added review the brief's own: `floor-head.out` holds `PASS A docs/reviews/2026-10-07-x.md` and `REFUSE M docs/reviews/2026-10-07-x.md`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1012-1061`; `docs/working/plan-build-loop-handoff.md:66-72`; `bash /tmp/u2a4f-fc2-wXyc/floordiff.sh {HEAD lib, anc-lib.sh} OUT`, exit 0 each, 07:11:01Z-07:12:15Z; `/tmp/u2a4f-fc2-wXyc/logs/floor-head.out`, `/tmp/u2a4f-fc2-wXyc/logs/floor-anc.out`

---

## Claims Requiring Attention

### Incorrect
None.

### Stale
None.

### Mostly Accurate
- **Claim 1** (`docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a4.md:24`; test comment `test/scripts/build-loop-check.bats:1188`): "A 2,000-quote line walks ok" holds for an instruction file, the tested case. In a prompt start the second base takes the output past IMPORT_OUT_MAX, and both walks fail closed (floor refuses every path). Say "in an instruction file", or note the prompt case under override row 469.
- **Claim 6** (`docs/reviews/override-log.md:479`): the unit is 471 code lines at HEAD (2b6f2f91 added 2), not 469. The merge message should state 471.
- **Claim 9** (`known-issues-dev-cycle.md:18`, lib `:42-43`): "the one statement" holds for the numbered list, but the IMPORTED=, IMPORT_OUT_MAX/IMPORT_WORK_MAX and main_checkout comments still restate items 4 and 7 (consistently; item 4 there as a raw `IMPORTED_MAIN_DONE=""`).
- **Claim 24** (`scripts/lib/dev-cycle-read.sh:490-494`): prompt_bases also adds the parent of any earlier component that starts with `.claude` (`.claudex`, `.claude-old`), because R1's strip is the shortest `*/.claude`. This is an over-read only; say so, or anchor the strip on `/.claude/`.
- **Claim 27** (`scripts/lib/dev-cycle-read.sh:603-604`): the superset "one statement" still says "made absolute (ROOT_REAL/$1/name ...)" and "up to the first blank". It omits the further base directories and the quoted run, which the header and scan's comment state.
- **Claim 33** (commit a5ad8c08): "3,098 paths" is 03be719e's count. a5ad8c08's tree has 3,099 whitespace-free paths, and identity holds over all 3,104 at HEAD.

### Unverifiable
- **Claim 30** (`scripts/lib/dev-cycle-read.sh:669-670`): that Claude Code 2.1.293's command expansion calls the quoted-mention extractor. Needs a caller trace in the binary (no egress here).

## Goal-Alignment Note
- Success criterion (restated verbatim): your report saved at the path your task names, structured per your skill, with every finding grounded in verbatim evidence.
- Answered: yes. All seven focus areas were checked, and each was executed where it could be: contract items 1-8 (Claims 14-21), prompt_bases and the read arms (24, 25, 7), IMPORT_AWK (26-29), isstart against the prefilter and truthrule/truthwalk (22, 32), check_fix identical to main over every tracked path including the five with whitespace (2), floor against D5 and the u2a2-full ancestor with no lost refusal (36), and the commit, override-row and rubric claims (1, 3-6, 33-35). There is no Incorrect and no behavioural under-read. The two behavioural Mostly-accurates (1, 24) are both on the safe, over-read or fail-closed side.
- Out of scope: hallucination-patterns.md was not updated (no fabrication, and the brief allows only this report). The health check and Claude Code's own prompt-mention and session-directory behaviour were not checked (no egress). Override row 465's 42.7 s timing was not re-measured.
- Escalate: (1) Claim 1: a prompt file with one long line of quotes (or any prompt whose prefix candidates print about 2 MB per base) fails both walks closed, so the floor refuses every path. This is the class override row 469 declined, but rubric A7's "walks ok" reads broader than the test. Decide whether A7's note or row 469 should name it. (2) Claim 6: the merge message should state 471 lines, not 469.
- Decisions I made: Claim 24 is Mostly accurate rather than Incorrect, because the extra base only over-reads and every real base is present. Claim 9 is Mostly accurate rather than Verified, because the header calls itself "the one statement" while three lib comments still restate parts of it, all consistently.
