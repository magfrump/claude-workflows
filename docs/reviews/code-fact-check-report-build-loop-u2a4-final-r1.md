Commit: 2b6f2f91
**Replication:** k=3 final confirming pass, replicate r1 (independent; no coordination)

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u2a4 (branch `feat/build-loop-u2a4`, HEAD 2b6f2f91, main 7afdb8d2)
**Scope:** `git diff main...HEAD`: code comments in `scripts/lib/dev-cycle-read.sh` (the header's gate caller contract 1-8, isstart/prompt_dir/prompt_bases, the walk block comments, IMPORT_AWK, truthrule/truthwalk/floor/ownfile) and `scripts/dev-cycle.sh`; commit messages `git log main..HEAD` (d861183d, c934adbc, d7cdc1ea, ee5108bd, 03be719e, a5ad8c08, 2b6f2f91); known issues A2 and A5; plan F11 and the U2a4/U2b bullets; the override-log rows dated 2026-10-07 for `feat/build-loop-u2a4` (462-480); the rubric's code claims.
**Checked:** 2026-10-08
**Total claims checked:** 34
**Summary:** 27 verified, 6 mostly accurate, 1 stale, 0 incorrect, 0 unverifiable

Hallucination-pattern log read first. The test-count class (commit tallies, entries at lines 28 and 30) was checked: every count on this branch matches `bats --count` at the commit it names (Claim 32). No fabricated symbol was found, so nothing qualifies for the log.

Execution provenance: every command ran with `TMPDIR=/tmp/u2a4f-fcr1-fxUr` and `LC_ALL=C`, under `timeout`, between 2026-10-08T07:08Z and 07:13Z. The working directory was `/workspace/.claude/wt-build-loop-u2a4` unless the claim says otherwise. Probe scripts are `/tmp/u2a4f-fcr1-fxUr/{cf,probe1..probe5}.sh`, and captured output is under `/tmp/u2a4f-fcr1-fxUr/logs/`. Fixture repos were made under `$TMPDIR` and removed by their scripts. No process was left running (checked with `ps` after the last probe).

Suites at HEAD (`logs/build-loop-check.log`, `logs/build-loop-read.log`, `logs/dev-cycle.log`, each with its `.ts` timestamp and exit file): build-loop-check 78/78, build-loop-read 19/19, dev-cycle 78/78, every one exit 0. `shellcheck -S warning` on both scripts: exit 0 with empty output (`logs/shellcheck.log`, 07:12:39Z).

---

## Claim 1: Rubric A6: "A table test compares the two over 138 paths: 3 depths × (10 basenames, 4 of them negatives, + 6 dirs × 3 tails × 2 cases)"; R1, A7, A8: "Fixed ... Tested"

**Location:** `docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a4.md:18-25,66`
**Type:** Reference / Behavioral
**Legibility-target:** for-orchestrator-synthesis
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the A6 test's path arithmetic and the passing tests named for R1, A7 and A8; does not establish the rubric's severity calls.

The test builds `for d in "" a/ a/b/; do for n in CLAUDE.md ... claude.md.bak; do` (10 names) `for c in rules commands agents output-styles skills notes; do for t in x.md sub/X.MD x.txt; do ps+=("$d.claude/$c/$t" "$d.Claude/$c/$t")` (`test/scripts/build-loop-check.bats`, the "instruction_names, the tree walk's prefilter" test). That is 3 × (10 + 6 × 3 × 2) = 138. Tests 76 and 77 (the prefilter test, and the quoted-mention / `c/.claude/.claude/` / 2,000-quote test) pass at HEAD (`ok 76`, `ok 77` in `logs/build-loop-check.log`).

**Evidence:** `test/scripts/build-loop-check.bats` (tests 76, 77); `/tmp/u2a4f-fcr1-fxUr/logs/build-loop-check.log` (`timeout 900 bats test/scripts/build-loop-check.bats`, exit 0, 07:08:35Z)

---

## Claim 2: Override row 462: "--check-fix over this repo's tracked paths is identical to main's (3,092 of 3,097: the comparison skips the five names holding whitespace)"

**Location:** `docs/reviews/override-log.md:462`
**Type:** Behavioral / Reference
**Legibility-target:** for-orchestrator-synthesis
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count at c934adbc's tree and identity at HEAD over every tracked path; does not establish identity at c934adbc's own code (not re-run there).

At c934adbc, `git ls-tree -r --name-only` lists 3,097 paths, 5 of them holding whitespace, so 3,092 whitespace-free (`logs/cf-run.txt` and the count run). Claim 5 re-runs the comparison at HEAD over all paths.

**Evidence:** `docs/reviews/override-log.md:462`; `/tmp/u2a4f-fcr1-fxUr/logs/cf-run.txt`

---

## Claim 3: Override rows 463-466: isstart adds the prompt directories and gives the tree walk rules/; the bases; the quoted name; a symlinked prompt start fails the main walk and the tree walk skips it; truthwalk owns the order; check_fix lowers through `lower`; one numbered contract; both walks pop by index; the floor never calls pathform or main_entry and its dot rule refuses `.github/x.yml` (tested)

**Location:** `docs/reviews/override-log.md:463-466`
**Type:** Behavioral
**Legibility-target:** for-orchestrator-synthesis
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each code fact the four rows state; does not establish the rows' disposition choices (Fixed / Defer), which are settled decisions.

`floor()` (`scripts/lib/dev-cycle-read.sh:1039-1061`, read whole) calls `lower`, `truthrule`, `ownfile`, `truthwalk` and nothing else: no `pathform`, no `main_entry`. The T10 test asserts `.github/x.yml "$DOT"` and passes. Probe 3 (`logs/probe3.log`) ran three cases. A checkout-only symlinked prompt gives `main docs/p.md: [walk]` and `tree docs/p.md: - []`. Both walks' pops are `f="${queue[qi]}"; qi=$((qi + 1))` (`:857`, `:919`). check_fix's lower is `if ! lp="$(lower "$a")"; then echo "skip $a: the path could not be lower-cased; file it instead"; return; fi` (`scripts/dev-cycle.sh:176`), and the failing-tr test passes.

**Evidence:** `scripts/lib/dev-cycle-read.sh:857,919,1039-1061`; `scripts/dev-cycle.sh:176`; `/tmp/u2a4f-fcr1-fxUr/logs/probe3.log` (`timeout 300 bash probe3.sh`, cwd `/tmp/u2a4f-fcr1-fxUr`, exit 0, 07:10:57Z)

---

## Claim 4: Override row 479: "iteration 2's fixes ... took the unit to 469; ... the unit lands whole and the merge message states the size"

**Location:** `docs/reviews/override-log.md:479`
**Type:** Configuration (measured value)
**Legibility-target:** for-author
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the changed code lines (`git diff --numstat main...<c> -- scripts test`) at each commit; does not establish which count the merge message will carry.

The counts are exact at the commits they name: c934adbc 333 + 48 = 381, 03be719e 393 + 50 = 443, and a5ad8c08 411 + 58 = 469. At HEAD the count is `10 12 scripts/dev-cycle.sh`, `205 46 scripts/lib/dev-cycle-read.sh` and `198 0 test/scripts/build-loop-check.bats`, which is 471. 2b6f2f91 added two comment lines (`+    # such a name can match a real file, which the floor then refuses (pathform` / `+    # already refuses it to --check-fix).`). The merge message's size should be 471, or should say that 469 was measured at a5ad8c08.

**Evidence:** `git diff --numstat main...HEAD -- scripts test`; `git show 2b6f2f91 -- scripts`

---

## Claim 5: check_fix's output equals main's for every tracked path (commit messages c934adbc, 03be719e, a5ad8c08; rubric; override rows 462, 480)

**Location:** `scripts/dev-cycle.sh:171-184`
**Type:** Behavioral
**Legibility-target:** for-automated-gate
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers byte-identical `--check-fix` output from main's dev-cycle.sh and lib (extracted with `git show main:...`) against HEAD's, over all 3,104 tracked paths, whitespace names included, plus 17 probe paths (mixed case, `.claude/commands/x.md`, `docs/.claude/commands/x.md`, `docs/thoughts/x.md`, `DOCS/ROADMAP.md`, `.envrc`, `docs/a b.md` and others). Does not establish identity where a tracked prompt file or an @ import of a tracked doc exists: this repo has neither (`git ls-files .claude` is empty, and no output line is an "after an @" skip), so the walk half compares two empty import sets here; fixture tests 73/77 cover that half.

`cf.sh` ran `bash $T/main/scripts/dev-cycle.sh --check-fix "${P[@]}"` and `bash scripts/dev-cycle.sh --check-fix "${P[@]}"` over 3,121 arguments. Both exited 0, and `cmp` printed `IDENTICAL`. By reading: the new `truthrule "$lp" && [[ "$TRUTH_WHY" == cycle ]]` matches the old `writable "$a" || writable "$lp"` (a writable path is never a start or dot path, and `lp` is lower-case so `case` never fires). Every other truthrule word goes to the same prose skip line as the old `||` chain (`scripts/dev-cycle.sh:177-178`).

**Evidence:** `scripts/dev-cycle.sh:171-184`; `/tmp/u2a4f-fcr1-fxUr/logs/cf-run.txt`, `logs/cf-main.txt`, `logs/cf-head.txt` (`timeout 600 bash cf.sh`, exit 0 both, 07:09:06Z)

---

## Claim 6: --check-fix header "an instruction or prompt file, or a file one names after an @"; check_fix comment "The denials it shares with the self-merge floor are the lib's truthrule."

**Location:** `scripts/dev-cycle.sh:53,169-170`
**Type:** Behavioral / Architectural
**Legibility-target:** for-orchestrator-synthesis
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers check_fix's calls; does not establish that the in-cycle skip line names prompt files (it does not, which override row 475 records).

check_fix calls `truthrule "$lp"` (`:177`) and `truthwalk tree "$lp"` (`:180`). truthrule's `instr` is isstart, which takes in prompt files.

**Evidence:** `scripts/dev-cycle.sh:53,170-184`; `scripts/lib/dev-cycle-read.sh:990-1000`

---

## Claim 7: Known issue A2: "The tree walk skips a symlinked start file, instruction or prompt (`inrepo` drops it), so an import from one passes `--check-fix`; the main walk follows a symlinked instruction file and fails on a symlinked prompt, so the floor refuses."

**Location:** `docs/working/known-issues-dev-cycle.md:16`
**Type:** Behavioral
**Legibility-target:** for-author
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both walks on a symlinked instruction file and a symlinked prompt, main-stored and checkout-only. It does not establish behavior under a symlinked directory, which is A5's not-covered list.

The tree walk drops both kinds: `if ! isstart "$lp" || ! inrepo_here "$f"; then continue; fi` (`scripts/lib/dev-cycle-read.sh:849`). The main walk follows a main-stored symlinked instruction file: probe 4 gives `docs/t.md [imported]` through `sub/CLAUDE.md -> ../docs/inst.md`. A checkout-only symlinked instruction file is not followed, though. main_checkout answers 1 for it (`plaindir "$c" || return 1`, `:834`), so the walk fails: probe 3 gives `main docs/t.md: [walk]` for the checkout-only `sub2/CLAUDE.md` link. The precise version: "the main walk follows a symlinked instruction file main stores and fails on any other symlinked start (a prompt main stores, or any checkout-only one)". Either way the floor refuses, so the error is on the safe side.

**Evidence:** `scripts/lib/dev-cycle-read.sh:810-837,849,926-928`; `/tmp/u2a4f-fcr1-fxUr/logs/probe3.log` (07:10:57Z, exit 0), `logs/probe4.log` (`timeout 60 bash probe4.sh`, exit 0, 07:11:14Z)

---

## Claim 8: Known issue A5's U2a4 sentences: isstart's files start both walks (instruction files and `.md` under `.claude/` rules/commands/agents/output-styles/skills at any depth); command names "resolved against the top level and every enclosing `.claude/`'s directory as well as their own, a quoted `@"name"` read without its quote ..., and fails the main walk on one main stores as a symlink"; the header contract "is the one statement of what a caller owes"

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Behavioral / Reference
**Legibility-target:** for-orchestrator-synthesis
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the start set, the bases (as a lower bound: "against X"), the quoted read and the symlink failure; does not establish that the bases are only those (see Claim 15 for an extra base).

Tests 73, 74 and 77 pass in both walks. The quoted read is `if (substr(line, i + 1, 1) == "\"") names(line, i + 2, L, 1)` (`:674`). The plan U2b bullet and F11 point to the header (Claims 10, 11), and nothing else restates the duties.

**Evidence:** `scripts/lib/dev-cycle-read.sh:484-503,674`; `/tmp/u2a4f-fcr1-fxUr/logs/build-loop-check.log`

---

## Claim 9: Plan F11: "the caller contract is the lib header's numbered list (U2a4)"; "one start rule (`isstart`: instruction files and `.md` files under `.claude/{rules,commands,agents,output-styles,skills}/` at any depth; ... also resolve against its session directories (the top level and each enclosing `.claude/`'s directory), a quoted `@"name"` is read without its quote, and a prompt start main stores as a symlink fails the walk)"

**Location:** `docs/working/plan-build-loop-handoff.md:126`
**Type:** Behavioral / Reference
**Legibility-target:** for-orchestrator-synthesis
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the same facts as Claim 8 and the contract's location; does not establish F11's "partly" rating.

The facts are the same as in Claim 8. The contract is at `scripts/lib/dev-cycle-read.sh:41-68`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:41-68,476-503`

---

## Claim 10: Plan U2a4 bullet: "`truthrule` ... and `truthwalk` (walk, then isimported), which check_fix and floor both call; `isstart` for both walks ...; the index queue pop (row 461); the lib header's numbered gate caller contract (row 459)"

**Location:** `docs/working/plan-build-loop-handoff.md:278`
**Type:** Architectural
**Legibility-target:** for-orchestrator-synthesis
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the call graph and the named pieces; does not establish U2b/U2c scope.

floor calls `truthrule "$lp"` (`:1044`) and `truthwalk main "$lp"` (`:1057`). check_fix calls both (`scripts/dev-cycle.sh:177,180`). The walks test `isstart "$lp"` (`:849`) and `isstart "$f"` (`:908`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:849,908,1039-1061`; `scripts/dev-cycle.sh:177-180`

---

## Claim 11: Plan U2b bullet: "keeps every item of the lib header's numbered gate caller contract (U2a4; the one statement of these duties, not restated here), and builds item 3's refusal (A5)"

**Location:** `docs/working/plan-build-loop-handoff.md:279`
**Type:** Reference
**Legibility-target:** for-orchestrator-synthesis
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the pointer and item 3's match with the header; does not establish U2b's design.

Header item 3 is `Refuse a checkout whose core.symlinks is false or with a working-tree-encoding, filter or ident attribute on any path the walk reads ... U2b builds this; the walk does not check it.` (`:51-54`). The bullet's restatement of item 3 is the build target and matches it. `rg "check-attr|core.symlinks"` in the lib finds only the comment at `:51`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:51-54`

---

## Claim 12: Header: "inrepo, dirok, skipped, check_brief, isimported, truthwalk (for tree or main), floor and the import walks exit 1 (need_root) unless ROOT_REAL is set ..."

**Location:** `scripts/lib/dev-cycle-read.sh:17-19`
**Type:** Error-handling
**Legibility-target:** for-orchestrator-synthesis
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers floor, truthwalk tree/main and truthwalk with an unknown WALK; does not re-check the pre-existing members (inrepo, dirok, skipped, check_brief).

floor starts `local lp` / `need_root` (`:1040-1041`). truthwalk is `case "$1" in main) main_imports || return 0 ;; tree) imported_names || return 0 ;; *) return 0 ;; esac` (`:1009`), and both walks call `need_root`. With ROOT_REAL unset, `floor docs/x.md s M` and `truthwalk tree docs/x.md` each printed `dev-cycle-read.sh: ROOT_REAL is not set ...` and exited 1, and `truthwalk bogus` returned `0 [walk]` without exiting (`logs/probe3.log`, `logs/probe1.log`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:127-131,1007-1011,1039-1041`; `/tmp/u2a4f-fcr1-fxUr/logs/probe1.log` (`timeout 120 bash probe1.sh`, exit 0, 07:10:12Z), `logs/probe3.log`

---

## Claim 13: Contract items 1-2: "under LC_ALL=C (under a UTF-8 locale a non-UTF-8 name on main fails the walk)"; "the walk reads main's blob for every path main stores, and the checkout only where main lacks a path), where git ls-files prints nothing on stderr (any fails the walk)"

**Location:** `scripts/lib/dev-cycle-read.sh:43-50`
**Type:** Behavioral
**Legibility-target:** for-orchestrator-synthesis
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the locale effect, the read-source dispatch and checkout_md's stderr rule; does not establish the git-environment list (a caller duty, not lib behavior).

A commit holding `docs/\xff.md` gives `C: main docs/a.md: [imported]` but `C.UTF-8: main docs/a.md: [walk]` and `C.utf8: ... [walk]` (`logs/probe3.log`). The read source is `case "${ent[$f]-checkout}" in checkout) ... capped_read < "$f"` and `100644|100755) ... git cat-file blob "$MAIN_SHA:$f"` (`:922-925`). The stderr rule is `checkout_md() { local e; { e="$(md_ls --cached --others 2>&1 >&3)"; } 3>&1 && [[ -z "$e" ]]; }` (`:792`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:792,894-925`; `/tmp/u2a4f-fcr1-fxUr/logs/probe3.log`

---

## Claim 14: Contract items 4-8 and `import_reset`: "Call import_reset before each gate decision ... neither walk's cache key holds them"; "Ask floor ... before pathform or main_entry (so .github/x.yml is refused as a dotfile, not as badform)"; "IMPORTED_MAIN=error reads as 'not imported' to a raw membership test"; item 7; "Pass truthrule, isstart and ownfile a lower-cased path (floor and check_fix lower first; truthrule refuses an upper-case letter as case)"

**Location:** `scripts/lib/dev-cycle-read.sh:55-68,554-555`
**Type:** Behavioral / Invariant
**Legibility-target:** for-orchestrator-synthesis
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each item's statement about lib code. It does not establish that U2b/U2c will keep the duties: floor has no caller.

`import_reset() { IMPORTED_DONE=""; IMPORTED_MAIN_DONE=""; }` cleared both keys in probe 1 (`[][][c]`). It leaves IMPORT_HOME_DONE alone, which is right, because import_home re-keys on `HOME` itself (`key="x${HOME+set}:${HOME-}"`, `:718`). The cache keys are `"$ROOT_REAL"` (`:843`) and `"$MAIN_SHA $MAIN_BY_NAME $ROOT_REAL"` (`:891`), and neither holds HOME or the budgets. `pathform` refuses `[.][gG][iI][tT]*` components (`:186`), so main_entry would answer `badform` for `.github/x.yml`, while floor's truthrule answers `dot`. `"error"` holds no newline, so `[[ "$IMPORTED_MAIN" == *$'\n'"$lp"$'\n'* ]]` is false for it. floor passes `lp` to truthrule and ownfile (`:1044,1055-1056`). truthrule's first test is `if [[ "$1" == *[ABCDEFGHIJKLMNOPQRSTUVWXYZ]* ]]; then TRUTH_WHY="case"`, and probe 1 gives `Docs/x.md: case`. The import_reset test (78) passes.

**Evidence:** `scripts/lib/dev-cycle-read.sh:186,554-555,718,843,891,992,1039-1061`; `/tmp/u2a4f-fcr1-fxUr/logs/probe1.log`

---

## Claim 15: prompt_bases: "the top level and the one holding each .claude/ in its path (a nested one too: U2a4 i1 security F3), as PATH spells them, once each"

**Location:** `scripts/lib/dev-cycle-read.sh:490-494`
**Type:** Behavioral
**Legibility-target:** for-author
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers prompt_bases over 9 shapes (top level, nested, doubled and tripled `.claude/`, mixed case, a component beginning `.claude` such as `.claudex` or `.claude-x`, `.claude/` under rules/) and a walk end to end. It does not establish whether Claude Code would start a session in such a directory.

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

The loop's guard needs `/.claude/`, but the strip `${rest#*/.claude}` takes the shortest prefix ending in `/.claude`, and that can end inside a longer component. For `a/.claudex/b/.claude/commands/x.md` it returns `[] [a] [a/.claudex/b]`, where `a` holds `.claudex`, not a `.claude/`. The same happens with `a/.claude-x/...`, which gives `[a]` (`logs/probe1.log`). In a walk, `a/.claudex/b/.claude/commands/x.md` holding `@n.md` makes the floor refuse `a/n.md` as imported (`logs/probe5.log`). Every other shape is exact and once each: `a/.claude/.claude/commands/x.md -> [] [a] [a/.claude]` and `A/.Claude/Commands/X.md -> [] [A]`. `n` strictly increases, so no base repeats. The extra base only reads more, which is the safe direction. The precise version: "... and, for each component beginning `.claude`, the directory holding it (a superset)".

**Evidence:** `scripts/lib/dev-cycle-read.sh:490-503`; `/tmp/u2a4f-fcr1-fxUr/logs/probe1.log`, `logs/probe5.log` (`timeout 120 bash probe5.sh`, exit 0, 07:12:50Z)

---

## Claim 16: prompt_bases inline: "Up to /.claude, not /.claude/: a .claude/ directly inside another keeps its slash"

**Location:** `scripts/lib/dev-cycle-read.sh:499`
**Type:** Behavioral
**Legibility-target:** for-orchestrator-synthesis
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers doubled and tripled `.claude/`; does not cover the `.claudex` residue (Claim 15).

The results were `.claude/.claude/.claude/commands/x.md -> [] [.claude] [.claude/.claude]` and `a/.claude/.claude/commands/x.md -> [] [a] [a/.claude]`. Test 77's `c/.claude/.claude/commands/y.md` reads `c/.claude/d.md` in both walks.

**Evidence:** `scripts/lib/dev-cycle-read.sh:498-501`; `/tmp/u2a4f-fcr1-fxUr/logs/probe1.log`

---

## Claim 17: isstart comment: the one start rule, "an instruction file's name, or a .md file at any depth under a .claude/ directory's rules/ ... or PROMPT_DIR's commands/, agents/, output-styles/ or skills/ ... truthrule refuses the same names; instruction_names is its grep prefilter, and a test holds the two equal"; instruction_names: "It matches isstart's names"

**Location:** `scripts/lib/dev-cycle-read.sh:476-485,759-764`
**Type:** Invariant
**Legibility-target:** for-orchestrator-synthesis
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers 1,518 generated paths (6 directory prefixes × 11 subdirectory spellings including `Rules`, `output_styles` and `notes` × 8 tails × 3 `.claude` spellings, plus 13 basenames per prefix); does not cover names holding a newline (both walks refuse them first).

The two rules are `isstart() { [[ "${1##*/}" =~ $INSTRUCTION_FILE ]] || [[ "$1" == *.md && ( "$1" =~ $PROMPT_DIR || "/$1" == */.claude/rules/* ) ]]; }` and the grep alternation `(^|/)\.claude/(rules|commands|agents|output-styles|skills)/.*\.md$` (`:764`). Probe 1 gives `n=1518 starts=468` and `SAME`, and the table test (76) passes. truthrule tests `isstart "$1"` second, after the case check (`:993`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:484-485,764,990-1000`; `/tmp/u2a4f-fcr1-fxUr/logs/probe1.log`

---

## Claim 18: prompt_dir: "for a start under PROMPT_DIR (LP lower-cased, PATH as spelled), MAP[PATH] gets LP, so a walk knows to read it against prompt_bases"

**Location:** `scripts/lib/dev-cycle-read.sh:486-489`
**Type:** Behavioral
**Legibility-target:** for-orchestrator-synthesis
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers both call sites and the pop-time lookups; does not establish that rules/ files get bases (they do not, by design: "memory, whose names resolve against the file's own directory").

`prompt_dir() { local -n pd_m="$1"; [[ ! "$2" =~ $PROMPT_DIR ]] || pd_m[$3]="$2"; }`. The tree walk calls `prompt_dir pdir "$lp" "$f"` (`:851`), and the main walk calls `prompt_dir pdir "$f" "${cand[i]:2}"` with `f` lower-cased (`:909`). Both pops run `[[ -z "${pdir[$f]+set}" ]] || prompt_bases xs "${pdir[$f]}" "$f"` (`:857`, `:919`), keyed on the spelled path the queue holds.

**Evidence:** `scripts/lib/dev-cycle-read.sh:489,851,857,909,919`

---

## Claim 19: Both walks apply the bases in every read arm; "A prompt's names resolve against the session, not its target's directory: not modelled" (the symlink arm fails); main_imports' block: "a prompt start (prompt_dir) main stores as a symlink ... fail the walk"; "(floor refuses start files by truthrule)"

**Location:** `scripts/lib/dev-cycle-read.sh:527,536,927-928`
**Type:** Behavioral
**Legibility-target:** for-orchestrator-synthesis
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the tree walk's one read arm and the main walk's checkout, blob and symlink arms, including phase-2 (tq) prompt starts; does not establish behavior for a prompt under a symlinked directory (A5 not-covered).

The tree arm runs `import_targets "$d" "${xs[@]}"` (`:859`). In the main walk, the checkout arm (`:922`) and the blob arm (`:924`) both pass `"${xs[@]}"`, and the symlink arm runs `[[ ${#xs[@]} -eq 0 ]] || { IMPORTED_MAIN=error; return 1; }` (`:928`). prompt_dir runs before main_checkout's admission (`:909`), so a phase-2 prompt start keeps its bases. Test 74 (the main-stored command link gives `walk failed`, while a rules link is followed) passes. The floor gives `.claude/commands/c.md "$INSTR"` in test 72.

**Evidence:** `scripts/lib/dev-cycle-read.sh:857-861,909-913,919-929`; `/tmp/u2a4f-fcr1-fxUr/logs/build-loop-check.log`

---

## Claim 20: imported_names' block: "The walk starts at every start file in the checkout (isstart), tracked or not ..., resolves each @path against the importing file's directory (and a prompt's also against prompt_bases')"

**Location:** `scripts/lib/dev-cycle-read.sh:504-509`
**Type:** Behavioral
**Legibility-target:** for-orchestrator-synthesis
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers start selection and base use for prompt starts. It does not establish anything for symlinked starts, which are skipped (A2, Claim 7) and not named here as an exception.

The start loop reads `nul_list recs tree_starts`, then `lp="$(lower "$f")"; if ! isstart "$lp" || ! inrepo_here "$f"; then continue; fi`. `tree_starts` lists `git ls-files -z && untracked_md`. Tests 73 and 77 pass for `tree`, including the untracked `.claude/commands/u.md`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:788,844-853`

---

## Claim 21: The superset statement above import_targets ("the one statement of it; known issue A5 and plan F11 point here"): "each prefix of the run after it, up to the first blank ..., is a candidate name, with a backslash-escaped space read as a space ... Each candidate is ... made absolute (ROOT_REAL/$1/name unless it starts with /)"

**Location:** `scripts/lib/dev-cycle-read.sh:593-605`
**Type:** Behavioral / Staleness
**Legibility-target:** for-author
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the paragraph's account of candidate runs and resolution against this branch's IMPORT_AWK; does not establish the Claude Code side of the superset claim (untraced, no egress).

This branch adds two rules the "one statement" does not carry. First, a second run after `@"`, which ends only at the closing quote and keeps blanks, tabs and `\r` (`if (q) { if (ch == "\"") break }`, `:681`). It does not read `\ ` as a space: probe 2 gives `un closed tab\there` as a candidate, and `a\ b.md` kept literal. Second, resolution against every further base directory (`for (i = 0; i <= nd; i++) put(root "/" dirs[i] "/" c)`, `:642`), where the paragraph says only `ROOT_REAL/$1/name`. The rules sit in the scan comment (`:669-674`) and in import_targets' first paragraph (`:579-581`), but A5 and F11 send a reader to this paragraph for "the claim, its rules and its exceptions". Both rules read more than the paragraph says (the safe direction). The paragraph should name the quoted run and the further base directories.

**Evidence:** `scripts/lib/dev-cycle-read.sh:579-581,593-605,636-643,664-686`; `/tmp/u2a4f-fcr1-fxUr/logs/probe2.log` (`timeout 120 bash probe2.sh`, exit 0, 07:10:33Z)

---

## Claim 22: import_targets: "a relative name resolved against $1 and against each further directory given (a prompt's session directories: prompt_bases)"; BEGIN: "IT_XDIRS: the further directories, each led by an x so "" survives split"; "the walks refuse a name holding a newline"

**Location:** `scripts/lib/dev-cycle-read.sh:579-581,697-698,727`
**Type:** Behavioral
**Legibility-target:** for-orchestrator-synthesis
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the encoding for `""`, `sub` and multi-base lists and the newline premise; does not establish behavior for a caller passing a base with a newline (no caller can).

`x="$(printf 'x%s\n' "${@:2}")"` is decoded by `nd = split(ENVIRON["IT_XDIRS"], dirs, "\n"); for (i = nd; i >= 1; i--) dirs[i] = substr(dirs[i], 2)`. With no further dirs `x=""`, so `split` returns 0. `printf '@"q r.md"\n' | import_targets .claude/commands "" sub` yields `.claude/commands/q r.md`, `q r.md` and `sub/q r.md`, and test 75 passes. The bases come from PATH, and both walks return 1 on a name holding a newline (`[[ "$f" != *$'\n'* ]] || return 1`, `:847`; `:897`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:697-699,724-748,847,897`; `/tmp/u2a4f-fcr1-fxUr/logs/probe2.log`

---

## Claim 23: IMPORT_AWK: the quoted run ("the run after the quote is read too, up to the closing quote, blanks included"), the unquoted run still ends at blanks, the work charge and output bound still hold with bases, `~/` names once per spelling, and the line of quotes costs quadratic, not cubic, work

**Location:** `scripts/lib/dev-cycle-read.sh:628-686`
**Type:** Behavioral / Performance
**Legibility-target:** for-orchestrator-synthesis
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers emit/put/names/scan as rewritten. It does not establish whether Claude Code's command expansion calls the quote-accepting extractor (Unverifiable in i2 Claim 19c, still untraced).

`printf '@"docs/a b.md" tail @docs/c d.md @"un closed tab\there\n'` yields `docs/a b.md`, and the unquoted runs stop at `docs/c` and `un`. The `~/` arm runs `put(homereal ...)`, then `c = home "/" ...`, then `if (substr(c, 1, 1) == "/") { put(c); return }`. With three bases `@~/x.md` yields `h/x.md` and `hl/x.md` once each. Only the bare `~` prefix is joined to each base (`d/~ e/~ f/~ ~`). The output bound: `IMPORT_LEFT=5` with 3 bases prints `a/a` and `a`, then rc=1. The work bound: `IMPORT_WORK_LEFT=10` gives rc=1. 3,000 quotes cost `/8079566` work (≈ n²), and test 77's 2,000-quote line walks ok.

**Evidence:** `scripts/lib/dev-cycle-read.sh:628-686`; `/tmp/u2a4f-fcr1-fxUr/logs/probe2.log`

---

## Claim 24: scan (2b6f2f91): "such a name can match a real file, which the floor then refuses (pathform already refuses it to --check-fix)"

**Location:** `scripts/lib/dev-cycle-read.sh:672-673`
**Type:** Behavioral
**Legibility-target:** for-orchestrator-synthesis
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a quoted name with a blank that matches a tracked file; does not establish anything for a quoted name with no blank (not the comment's subject).

In a fixture with `.claude/commands/q.md` holding `run @"docs/a b.md"`, `floor "docs/a b.md"` prints `an instruction file on the default branch imports it with @ ...`, and `--check-fix "docs/a b.md"` prints `skip docs/a b.md: not an allowed path form` (`logs/probe5.log`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:672-675`; `/tmp/u2a4f-fcr1-fxUr/logs/probe5.log`

---

## Claim 25: Index pop: "An index, not a copy per pop (quadratic in the files read: override row 461)"; "phase 2: main's walk is done"

**Location:** `scripts/lib/dev-cycle-read.sh:855,916-918`
**Type:** Behavioral / Performance
**Legibility-target:** for-orchestrator-synthesis
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the pop and the phase switch; does not establish timing (row 465: no timing test).

`while [[ $qi -lt ${#queue[@]} || ${#tq[@]} -gt 0 ]]; do [[ $qi -lt ${#queue[@]} ]] || { queue=("${tq[@]}"); tq=(); qi=0; }`. Phase 2 starts only when the index has reached the end of main's queue. Phase-2 imports main stores join `queue` and are popped in order.

**Evidence:** `scripts/lib/dev-cycle-read.sh:855-858,916-920`

---

## Claim 26: truthrule comment: words and order, "instr ..., dot (a .-prefixed component, a top-level one included), cycle (writable), settings (docs/dev-cycle.md), user (docs/constraints.md ...) or record (docs/decisions/, docs/human-author/), and case for a path holding an upper-case letter"; docs/thoughts/ floor-only

**Location:** `scripts/lib/dev-cycle-read.sh:979-989`
**Type:** Behavioral
**Legibility-target:** for-orchestrator-synthesis
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the six words plus `case`, their order (case, instr, dot, cycle, settings, user, record), and empty TRUTH_WHY on a pass; does not establish D5 item 4's "other briefs' working docs" (floor's, not truthrule's).

The code order is case, instr, dot, cycle, settings, user, record, `else return 1`, and TRUTH_WHY is set empty first. Probe 1 gives `.envrc: dot`, `docs/.x/claude.md: instr` (instr outranks dot), `docs/working/questions.md: cycle`, and `docs/thoughts/a.md: - []`. Test 73's check_fix answers `ok docs/thoughts/t.md`, and floor answers `$REC`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:990-1000`; `/tmp/u2a4f-fcr1-fxUr/logs/probe1.log`

---

## Claim 27: truthwalk: "runs the import walk WALK ..., then asks it about PATH (any case), as isimported WALK PATH does ... Returns 0 when the walk fails (TRUTH_WHY=walk) or reaches PATH (TRUTH_WHY=imported), else 1 with TRUTH_WHY empty; an unknown WALK answers walk without running one. For tree or main it exits through need_root."; isimported: "a caller that words a failed walk asks truthwalk"

**Location:** `scripts/lib/dev-cycle-read.sh:964-968,1001-1011`
**Type:** Behavioral
**Legibility-target:** for-orchestrator-synthesis
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers all four outcomes for both walks; does not establish anything for a walk that is cached in error (it returns 1 again, so the outcome is `walk`, by reading).

```bash
# scripts/lib/dev-cycle-read.sh:1007-1011
truthwalk() {
  TRUTH_WHY=walk
  case "$1" in main) main_imports || return 0 ;; tree) imported_names || return 0 ;; *) return 0 ;; esac
  TRUTH_WHY=imported; isimported "$1" "$2" || { TRUTH_WHY=""; return 1; }
}
```

Probe 3 gives `main docs/zzz.md: - []`, `main docs/a.md: [imported]`, the same for `tree`, `main docs/p.md: [walk]`, and `bogus: 0 [walk]`. The need_root exits are in Claim 12.

**Evidence:** `scripts/lib/dev-cycle-read.sh:969-978,1007-1011`; `/tmp/u2a4f-fcr1-fxUr/logs/probe1.log`, `logs/probe3.log`

---

## Claim 28: floor comment: "The self-merge floor (plan D5 items 1-4) ... $3 the diff-tree status letter alone (R for R100; only A makes a review the brief's own) ... The caller's duties are the gate caller contract's ...: floor item 5, symlinks and gitlinks, is the caller's mode rule"; ownfile and GATE_CODE ported from feat/build-loop-u2a2-full

**Location:** `scripts/lib/dev-cycle-read.sh:1012-1038`
**Type:** Behavioral / Reference
**Legibility-target:** for-orchestrator-synthesis
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers floor against D5 items 1-4 (`docs/working/plan-build-loop-handoff.md:66-72`) and ownfile/GATE_CODE against the ancestor; does not establish item 5 (no mode check, by design).

D5 item 1 is covered by `instr` and `truthwalk main`, item 2 by `dot`, item 3 by `[[ "$lp" =~ $GATE_CODE ]]`, and item 4 by cycle/settings/user/record plus `docs/thoughts/*` and the non-own `docs/working/*`. Only `ownfile`'s `[[ "$3" == A && ... ]]` reads the status letter. `ownfile()` and `GATE_CODE=` are byte-identical to `git show feat/build-loop-u2a2-full:scripts/lib/dev-cycle-read.sh` `:597-605`. Tests 72 and 73 pass.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1018-1061`; `feat/build-loop-u2a2-full:scripts/lib/dev-cycle-read.sh:597-638`; `docs/working/plan-build-loop-handoff.md:66-72`

---

## Claim 29: (Task check 6) Nothing the pre-split ancestor's floor (feat/build-loop-u2a2-full) refused passes HEAD's floor

**Location:** `scripts/lib/dev-cycle-read.sh:1039-1061`
**Type:** Behavioral
**Legibility-target:** for-orchestrator-synthesis
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the floor's refusal rules and the parser and walk on main's commit. It does not establish phase-2 checkout behavior: U2a3c, already merged, changed the ancestor's checkout reads, and that is outside this unit.

The ancestor refused, in this order: `$low =~ $INSTRUCTION_FILE`, `"/$lp" == */.*`, GATE_CODE, `! main_imports`, `isimported main`, `writable || docs/dev-cycle.md`, `docs/constraints.md`, `^docs/(decisions|thoughts|human-author)/`, and non-own working/reviews. HEAD refuses each of these:
- isstart ⊇ INSTRUCTION_FILE.
- The dot test is the same.
- GATE_CODE is unchanged.
- cycle/settings/user/record plus a separate `docs/thoughts/*` arm cover the rest.
- working/reviews go through the same ownfile.
- A walk failure or import refuses through `truthwalk main`.

The ancestor ran that last test before the cycle rules, while HEAD runs it after, but every path HEAD's earlier rules skip still reaches it. The parser only grew: the ancestor resolved `root "/" dir "/" c` alone, and HEAD resolves `dirs[0]=IT_DIR` plus the bases and the quoted run. The main-commit start set only grew: the ancestor took `$INSTRUCTION_FILE || .claude/rules/*.md` at top level only. The ancestor read an untracked start in the checkout (`src == t`: `inrepo_here "$f" || continue`), while HEAD admits through main_checkout, where a non-plain node fails the walk. HEAD also refuses a path `lower` cannot lower-case, where the ancestor's `lp="$(lower "$1")"` had no guard. The confidence is Medium because the walks cannot be compared on one fixture: the ancestor's lib does not carry U2a3/U2a3c.

**Evidence:** `feat/build-loop-u2a2-full:scripts/lib/dev-cycle-read.sh:520-575,617-634`; `scripts/lib/dev-cycle-read.sh:885-962,1039-1061`

---

## Claim 30: Commit d861183d: "All 7 fail on main's code"; c934adbc: "Plan step 5's U2a4 (no new mode), stacked on main dfa75374"

**Location:** commit d861183d, commit c934adbc
**Type:** Reference
**Legibility-target:** for-orchestrator-synthesis
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the red run of d861183d's seven tests against its parent's lib and the stated base. It does not establish why each test failed beyond the first-seen reason: override row 478 already records a fixture error in test 6.

`git archive d861183d` was extracted to `$T/d86`, and `bats -f U2a4 test/scripts/build-loop-check.bats` gave `not ok 1`..`not ok 7`, exit 1, failing with `floor: command not found` among other errors (`logs/d86-u2a4.log`, 07:09:51Z). The base is not dfa75374 as c934adbc says: `git rev-parse d861183d^` is `7afdb8d2` (main), a checkpoint commit whose only change from dfa75374 is `docs/working/checkpoint-build-loop-handoff.md` (8+/8-). The lib is identical, so the code claim holds. The commits are immutable, so this is for the record only.

**Evidence:** `/tmp/u2a4f-fcr1-fxUr/logs/d86-u2a4.log` (`timeout 600 bats -f 'U2a4' test/scripts/build-loop-check.bats`, cwd `/tmp/u2a4f-fcr1-fxUr/d86`, exit 1); `git diff --stat dfa75374 7afdb8d2`

---

## Claim 31: Commit a5ad8c08: "--check-fix identical to main's over 3,098 paths"

**Location:** commit a5ad8c08
**Type:** Reference (measured value)
**Legibility-target:** for-orchestrator-synthesis
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count at a5ad8c08's tree and identity at HEAD; does not establish a re-run at a5ad8c08's own code.

a5ad8c08's tree has 3,104 paths, 5 with whitespace, so 3,099 whitespace-free. 3,098 is its parent 03be719e's count. The conclusion holds: identity was re-run at HEAD over all 3,104 paths (Claim 5). This is the logged count-from-an-earlier-file-set class, and no override row covers this commit's figure (rows 478 and 480 cover d861183d, c934adbc and 03be719e).

**Evidence:** `git ls-tree -r --name-only a5ad8c08`; `/tmp/u2a4f-fcr1-fxUr/logs/cf-run.txt`

---

## Claim 32: Commit test and line tallies: c934adbc "build-loop-check 75 ... 381 changed code lines"; 03be719e and a5ad8c08 "build-loop-check 78/78, build-loop-read 19, dev-cycle 78, fixture-git-env 2, fixture-hermeticity 2, hermeticity-lint 53; shellcheck -S warning clean"; 03be719e "grew from 381 to 443"; a5ad8c08 "469 code lines against main (381 at step 1a)"

**Location:** commits c934adbc, 03be719e, a5ad8c08
**Type:** Configuration (measured values)
**Legibility-target:** for-orchestrator-synthesis
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `@test` counts at each commit, suite results and shellcheck at HEAD, and numstat line counts at each commit; does not re-run the suites at the earlier commits.

The `@test` counts in build-loop-check are main 68, d861183d 75, c934adbc 75, 03be719e 78 and a5ad8c08 78. `bats --count` at HEAD gives 78, 19, 78, 2, 2, 53, and the three main suites pass. Line counts are 381, 443 and 469 at their commits (Claim 4), and shellcheck is clean at HEAD.

**Evidence:** `git show <c>:test/scripts/build-loop-check.bats | grep -c '^@test'`; `/tmp/u2a4f-fcr1-fxUr/logs/*.log`, `logs/shellcheck.log`

---

## Claim 33: Commit ee5108bd: "Fact-check (30 claims: 0 Incorrect, 1 Stale, 6 Mostly accurate)"; a5ad8c08's R1/A7/A8 descriptions

**Location:** commits ee5108bd, a5ad8c08
**Type:** Reference / Behavioral
**Legibility-target:** for-orchestrator-synthesis
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the i1 report's header tally and the three fix descriptions against HEAD's code; does not establish the i1 verdicts themselves.

The i1 report's header reads `**Total claims checked:** 30` / `**Summary:** 22 verified, 6 mostly accurate, 1 stale, 0 incorrect, 1 unverifiable`. R1 is the `${rest#*/.claude}` strip with `- 8` (Claim 16). A7 is `names(line, i + 2, L, 1)` from scan, not a recursion in emit (`:664-686`; 3,000 quotes cost 8.08M work). A8 is a quoted run that ends only at `"` (Claim 23).

**Evidence:** `docs/reviews/code-fact-check-report-build-loop-u2a4.md:9-10`; `scripts/lib/dev-cycle-read.sh:664-686`; `/tmp/u2a4f-fcr1-fxUr/logs/probe2.log`

---

## Claim 34: Commit 03be719e: "--check-fix still identical to main's over 3,092 paths"; "prompt_bases gives each prompt start one list of bases, the top level and the directory holding every enclosing .claude/, once each"

**Location:** commit 03be719e
**Type:** Reference / Behavioral
**Legibility-target:** for-orchestrator-synthesis
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count and the bases statement; settled by override row 480 (Accepted-immutable). This is recorded for completeness, not as a new finding.

03be719e's tree holds 3,098 whitespace-free paths. The base statement was false at 03be719e for a doubled `.claude/` and is fixed at HEAD (Claim 16). At HEAD it carries the `.claudex` over-read (Claim 15).

**Evidence:** `docs/reviews/override-log.md:480`; `git ls-tree -r --name-only 03be719e`

---

## Claims Requiring Attention

### Incorrect
None.

### Stale
- **Claim 21** (`scripts/lib/dev-cycle-read.sh:593-605`): the superset paragraph, which A5 and F11 call the one statement of the parser's rules, omits this branch's quoted run (`@"..."` read to the closing quote, blanks included, no `\ ` escape) and the further base directories. Add both. The code reads more than the paragraph says.

### Mostly Accurate
- **Claim 4** (`docs/reviews/override-log.md:479`): 469 was the size at a5ad8c08. HEAD is 471 (2b6f2f91 added 2 comment lines), so the merge message should say 471 or name the commit it was measured at.
- **Claim 7** (`docs/working/known-issues-dev-cycle.md:16`): A2 says "the main walk follows a symlinked instruction file". That holds only for one main stores. A checkout-only symlinked instruction file fails the main walk, like a prompt. Fails safe.
- **Claim 15** (`scripts/lib/dev-cycle-read.sh:490-494`): prompt_bases also adds the directory holding any component that begins `.claude` (`.claudex`, `.claude-x`), not only one holding a `.claude/`. This is an over-read (safe), but "the one holding each .claude/" is not exact.
- **Claim 30** (commit c934adbc): "stacked on main dfa75374". The parent is 7afdb8d2, a docs-only checkpoint with the same lib. Immutable.
- **Claim 31** (commit a5ad8c08): "3,098 paths" is the parent's whitespace-free count. a5ad8c08's own is 3,099, and identity holds at HEAD over all 3,104. Immutable, and no override row covers it.
- **Claim 34** (commit 03be719e): already settled by override row 480.

### Unverifiable
None.

## Goal-Alignment Note
- Success criterion (restated verbatim): your report saved at the path your task names, structured per your skill, with every finding grounded in verbatim evidence.
- Answered: yes. All 7 requested checks were run, most by execution: contract 1-8, prompt_bases and the walks, IMPORT_AWK, isstart vs the prefilter and the truthrule/truthwalk semantics, check_fix vs main over all tracked paths, floor vs D5 and the ancestor, and the commit and row claims.
- Out of scope: whether Claude Code's command expansion accepts `@"..."` or loads `agents/`, `output-styles/` and `skills/` (no egress; untraced superset, settled). Timing claims in override rows 465, 469-471 (prior measurements, not re-run).
- Escalate: nothing blocking. Claim 21 (Stale, comment/doc) is the only one that touches the "one statement" contract A5 points to. Claim 4's size figure should be corrected in the merge message.
- Decisions I made: I verdicted A5's "resolved against the top level and every enclosing .claude/'s directory" as Verified (a lower bound) and put the `.claudex` extra base on prompt_bases' "the one holding each ... once each" (Claim 15). I treated the check_fix identity as Verified while scoping out the walk half, because this repo has no imports to compare.
