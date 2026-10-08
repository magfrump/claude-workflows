Commit: d7cdc1ea

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u2a4 (branch feat/build-loop-u2a4)
**Scope:** `git diff main...HEAD` (main = 7afdb8d2, HEAD = d7cdc1ea): comments and docstrings in scripts/lib/dev-cycle-read.sh and scripts/dev-cycle.sh, the lib header's numbered gate caller contract, docs/working/known-issues-dev-cycle.md A5, docs/working/plan-build-loop-handoff.md (F11, U2a4 and U2b bullets), the six new rows of docs/reviews/override-log.md (lines 462-467), and the commit messages of `git log main..HEAD`
**Checked:** 2026-10-07 (probes ran 2026-10-08T06:16Z-06:22Z UTC)
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 30
**Summary:** 22 verified, 6 mostly accurate, 1 stale, 0 incorrect, 1 unverifiable

Execution provenance: every executed probe ran with `LC_ALL=C` and `TMPDIR=/tmp/u2a4-cfc-hECA` (the brief's own-TMPDIR rule; the task allows writing only this report, so captured output lives there, not under `docs/reviews/execution-logs/`). Probe scripts: `/tmp/u2a4-cfc-hECA/probe/p*.sh`; logs beside them. Every probe ran under `timeout` and exited; nothing was left running.

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) read first. Claim 2b is the same class as the logged "specific measured value quoted from an artifact set that does not contain it" entries (a count off by 5), but its substantive conclusion holds, so it is Mostly accurate, not a fabrication; not appended (this pass may write only this report).

---

## Claim 1: "`truthrule` in the lib returns one word per denial (instr, dot, cycle, settings, user, record), and both callers word it; the lists still differ on purpose (check_fix: docs and README.md only, docs/thoughts/ fixable; floor: gate code, docs/thoughts/, other briefs' files)"

**Location:** `docs/reviews/override-log.md:462`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers truthrule's six words and that check_fix and floor both call it and add the stated rules; does not establish that the two callers' remaining extra rules are the only differences (check_fix also refuses `docs/working/` and `docs/reviews/`, which the row's parenthetical omits but which predate this unit).
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/lib/dev-cycle-read.sh:965-975
truthrule() {
  TRUTH_WHY=""
  if isstart "$1"; then TRUTH_WHY="instr"
  elif [[ "/$1" == */.* ]]; then TRUTH_WHY="dot"
  elif writable "$1"; then TRUTH_WHY="cycle"
  elif [[ "$1" == docs/dev-cycle.md ]]; then TRUTH_WHY="settings"
  elif [[ "$1" == docs/constraints.md ]]; then TRUTH_WHY="user"
  elif [[ "$1" =~ ^docs/(decisions|human-author)/ ]]; then TRUTH_WHY="record"
  else return 1; fi
}
```

check_fix calls it (`scripts/dev-cycle.sh:177-178`: `if truthrule "$lp" && [[ "$TRUTH_WHY" == cycle ]]`, then `elif [[ -n "$TRUTH_WHY" || ! "$lp" =~ ^docs/.*\.md$|^readme\.md$ || "$lp" =~ ^docs/(working|reviews)/ ]]`), and floor calls it and then adds `$GATE_CODE`, `docs/thoughts/*`, and the non-own `docs/working/*` / `docs/reviews/*` rules (`scripts/lib/dev-cycle-read.sh:1016-1029`). The build-loop-check test "check_fix and floor share one read-as-truth rule" passed (docs/thoughts/t.md: `ok` from --check-fix, `$REC` from floor).

**Evidence:** `scripts/lib/dev-cycle-read.sh:965-975`, `scripts/lib/dev-cycle-read.sh:1011-1032`, `scripts/dev-cycle.sh:171-185`; `bats test/scripts/build-loop-check.bats` (cwd worktree, exit 0, 2026-10-08T06:16:02Z), output `/tmp/u2a4-cfc-hECA/bats-build-loop-check.log`

---

## Claim 2a: "--check-fix over this repo's ... tracked paths is identical to main's" (also commit c934adbc: "Its output over this repo's 3,092 tracked paths is identical to main's")

**Location:** `docs/reviews/override-log.md:462`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers byte-identical --check-fix output of main's `scripts/dev-cycle.sh` + lib versus the branch's, over every tracked path of this worktree plus 20 synthetic paths (mixed case, dot components, `.claude/{rules,commands}` under docs/, instruction names under docs/, a brief named `...-claude.md`); does not establish identity in a repo that tracks `.claude/rules|commands|agents|output-styles` files (this one tracks none, so the new starts are not exercised here; by design they make the branch stricter there).
**Legibility-target:** for-orchestrator-synthesis

Command (`/tmp/u2a4-cfc-hECA/probe/p5.sh`, cwd `/workspace/.claude/wt-build-loop-u2a4`): main's two files extracted with `git show main:...` into `/tmp/u2a4-cfc-hECA/mainsc/scripts/`, then `xargs -0 bash <script> --check-fix < paths.z` for each copy. Result: `main exit=0`, `branch exit=0`, 3,117 lines each, `IDENTICAL` (2026-10-08T06:17:15Z-06:17:32Z). Static reading agrees (paraphrased — no quote available because the argument spans the old and new condition chains): every path truthrule words `instr`, `dot`, `settings`, `user` or `record` was already refused by main's combined condition with the same message, `cycle` keeps its own branch (no path is both `writable` and `isstart`/dot), and truthwalk reproduces main's `imported_names` then `isimported tree` order.

**Evidence:** `scripts/dev-cycle.sh:171-185`, `/tmp/u2a4-cfc-hECA/probe/p5.log`, `/tmp/u2a4-cfc-hECA/cf-main.txt`, `/tmp/u2a4-cfc-hECA/cf-branch.txt`

---

## Claim 2b: "this repo's 3,092 tracked paths"

**Location:** `docs/reviews/override-log.md:462` (and commit c934adbc body)
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the path count at main (7afdb8d2), the branch base dfa75374 and HEAD; does not establish which checkout or commit the author counted in.
**Legibility-target:** for-author

`git ls-tree -r --name-only` gives 3,097 at 7afdb8d2, dfa75374 and HEAD (the branch adds no file), and `git ls-files -z` in the worktree lists 3,097. 3,092 is the count at 4ce2c6bf, three commits before the base. The identity result (Claim 2a) holds over the 3,097; the number should read 3,097.

**Evidence:** `git ls-tree -r --name-only <commit> | wc -l` over the last 12 main commits (7afdb8d2 3097, dfa75374 3097, 16d42087 3095, c8bd58c7 3094, 4ce2c6bf 3092); `/tmp/u2a4-cfc-hECA/probe/p5.log` ("tracked: 3097")

---

## Claim 3: "`isstart` ... adds `.md` files under `.claude/{commands,agents,output-styles}/` at any depth (and gives the tree walk `.claude/rules/`); a prompt's names also resolve against the directory holding its `.claude/` and the top level ...; and a prompt start main stores as a symlink fails the walk."

**Location:** `docs/reviews/override-log.md:463`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the start rule, the extra base directories, and the main walk's symlinked-prompt failure; does not establish what the tree walk (--check-fix) does with a symlinked prompt start (it skips it silently, see below), nor Claude Code's resolution rule ("as the L2-confirm probe showed"), which is outside this sandbox.
**Legibility-target:** for-author

The start rule and the base directories hold (test "both walks start at .md files under .claude/rules/, commands/, agents/ and output-styles/ ..." passed for `tree` and `main`). "fails the walk" is true of the main walk only:

```bash
# scripts/lib/dev-cycle-read.sh:901-903 (excerpt ends :903; enclosing main_imports continues to :937 — read)
      120000)  # a symlink: its text names the file read, as one more import
        # A prompt's names resolve against the session, not its target's directory: not modelled.
        [[ ${#xs[@]} -eq 0 ]] || { IMPORTED_MAIN=error; return 1; }
```

The tree walk drops a symlinked start before it is queued: `if ! isstart "$lp" || ! inrepo_here "$f"; then continue; fi` (`scripts/lib/dev-cycle-read.sh:824`), and `inrepo_here` is `[[ -z "$(blocker "$1" file)" && -f "$1" ]]` (`:158`), whose `rawfile` refuses a symlink (`:130`). This is known issue A2's existing behaviour for symlinked instruction files, not new, but the sentence's subject ("the one start rule both walks use") invites reading "the walk" as both. Precise version: "a prompt start main stores as a symlink fails the main walk; the tree walk skips it (A2)."

**Evidence:** `scripts/lib/dev-cycle-read.sh:130`, `:158`, `:813-856`, `:860-937`; `/tmp/u2a4-cfc-hECA/bats-build-loop-check.log` (tests 73, 74 ok)

---

## Claim 4: "`truthwalk` owns the order for both callers; the caller contract's item 6 says to read a walk only through isimported or truthwalk; check_fix lower-cases through the lib's `lower` and refuses with a reason when tr fails (tested)."

**Location:** `docs/reviews/override-log.md:464`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers check_fix's and floor's tr-failure paths and both callers' use of truthwalk; does not establish behaviour when `lower` succeeds with truncated output (tr exiting 0 after a partial write).
**Legibility-target:** for-orchestrator-synthesis

`if ! lp="$(lower "$a")"; then echo "skip $a: the path could not be lower-cased; file it instead"; return; fi` (`scripts/dev-cycle.sh:176`); floor: `lp="$(lower "$1")" || { FLOOR_WHY="the path could not be lower-cased"; return 0; }` (`scripts/lib/dev-cycle-read.sh:1015`). The test "floor fails closed when main's walk fails, main is not found by name, or a path cannot be lower-cased" (a `tr` shim that exits 1) passed, and on main's code it fails (Claim 29). Both callers call `truthwalk "$lp" tree` / `truthwalk "$lp" main` (`scripts/dev-cycle.sh:180`, `scripts/lib/dev-cycle-read.sh:1028`).

**Evidence:** `scripts/dev-cycle.sh:171-185`, `scripts/lib/dev-cycle-read.sh:976-985`, `:1011-1032`; `/tmp/u2a4-cfc-hECA/bats-build-loop-check.log`

---

## Claim 5: "Both walks pop by index; the pop has no timing test (...), and the walk tests cover its order."

**Location:** `docs/reviews/override-log.md:465`
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that neither walk copies its queue per pop and that the walk tests pass; does not establish the walk's run time at 5,000 files (no timing run here).
**Legibility-target:** for-orchestrator-synthesis

`f="${queue[qi]}"; qi=$((qi + 1))` in both loops (`scripts/lib/dev-cycle-read.sh:831-832`, `:892-894`); no `queue=("${queue[@]:1}")` remains (grep). All 75 build-loop-check tests passed.

**Evidence:** `scripts/lib/dev-cycle-read.sh:830-833`, `:891-894`; `/tmp/u2a4-cfc-hECA/bats-build-loop-check.log`

---

## Claim 6: "The floor itself never calls pathform or main_entry, and its dot rule refuses `.github/x.yml` (tested). These are duties of the gate's caller, now items 4 and 5 of the lib's caller contract"

**Location:** `docs/reviews/override-log.md:466`
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers floor's whole call graph (lower, truthrule→isstart/writable/isbrief/isclosed, ownfile, truthwalk→main_imports→main_checkout/import_targets/…, isimported) and the `.github/x.yml` answer; does not establish that a future caller obeys item 5's order.
**Legibility-target:** for-orchestrator-synthesis

A grep for `pathform`, `main_entry`, `check-attr` and `core.symlinks` over lines 813-1059 (both walks, isimported, truthrule, truthwalk, ownfile, floor) finds no call, and the functions they call above line 813 (`main_checkout`, `rawfile`, `plaindir`, `nul_list`, `lower_all`, `import_targets`) contain none (paraphrased — no quote available because the claim covers absence of code across the call graph). Executed in a fixture repo (`/tmp/u2a4-cfc-hECA/probe/p1.sh`): `floor: a dotfile or a path under a dot-directory`, `pathform: refused`, `main_entry: badform` for `.github/x.yml`, so asking floor first is what makes the dot wording appear, as item 5 says.

**Evidence:** `scripts/lib/dev-cycle-read.sh:177-188`, `:813-1032`; `/tmp/u2a4-cfc-hECA/probe/p1.log` (exit 0, ~2026-10-08T06:21Z)

---

## Claim 7: "The floor words a failed walk as one reason and does not call main_entry."

**Location:** `docs/reviews/override-log.md:467`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers floor's walk-failure wording; does not establish anything about U2c's future IMPORTED_MAIN_WHY.
**Legibility-target:** for-orchestrator-synthesis

`if [[ "$TRUTH_WHY" == walk ]]; then FLOOR_WHY="the default branch's instruction files could not be walked for @ imports"` (`scripts/lib/dev-cycle-read.sh:1029`); no main_entry call (Claim 6).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1028-1031`

---

## Claim 8: "`isstart`'s files start both walks (U2a4: instruction files and `.md` files under `.claude/rules/`, `commands/`, `agents/` and `output-styles/` at any depth)"

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both walks' start selection (tree: `isstart "$lp"` at `:824`; main: `isstart "$f"` at `:883`) and the prefilter's agreement (Claim 22); does not establish that a symlinked start in the tree walk is a start (it is skipped, A2).
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/lib/dev-cycle-read.sh:482-483
PROMPT_DIR='^(.*/)?\.claude/(commands|agents|output-styles)/'
isstart() { [[ "${1##*/}" =~ $INSTRUCTION_FILE ]] || [[ "$1" == *.md && ( "$1" =~ $PROMPT_DIR || "/$1" == */.claude/rules/* ) ]]; }
```

Test "both walks start at .md files under .claude/rules/, commands/, agents/ and output-styles/ at any depth, tracked or not" passed for both walks, including `sub/.claude/commands/x.md` and an untracked `.claude/commands/u.md`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:482-483`, `:813-856`, `:860-937`; `/tmp/u2a4-cfc-hECA/bats-build-loop-check.log`

---

## Claim 9: "the lib header's numbered gate caller contract, U2a4, is the one statement of what a caller owes the walk and the floor: a clean worktree at MAIN_SHA, empty `ls-files` stderr, the git environment, `LC_ALL=C`, the cache, the order of floor and main_entry"

**Location:** `docs/working/known-issues-dev-cycle.md:18` (same claim in the lib header, `scripts/lib/dev-cycle-read.sh:42`: "(the one statement of it; plan step 5's U2b bullet and known issue A5 point here; override row 459)")
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the lib header holds all the listed duties and that A5 and the U2b bullet point to it; does not establish "the one statement": the duties are still restated in full elsewhere.
**Legibility-target:** for-author

The header holds every listed duty (`scripts/lib/dev-cycle-read.sh:43-66`). But the plan's U2b bullet still restates them in full ("owing the walk four things: that checkout a clean worktree at MAIN_SHA ...; a git that prints nothing on stderr for `ls-files` ...; A caller of `main_checkout` other than `main_imports` passes a fresh MEMO per walk and ENT ...", `docs/working/plan-build-loop-handoff.md:279`), and itself says so ("the one statement of these duties, which the rest of this sentence predates"). The cache duty is also restated in the block above `IMPORTED=` ("a caller whose checkout may have changed ... sets IMPORTED_MAIN_DONE="" to walk again", `scripts/lib/dev-cycle-read.sh:529-533`), and item 7 in main_checkout's comment (`:775-776`). Precise version: "the one numbered statement; the plan's U2b bullet and the walk's comments still restate parts of it."

**Evidence:** `scripts/lib/dev-cycle-read.sh:41-66`, `:529-533`, `:772-784`; `docs/working/plan-build-loop-handoff.md:279`

---

## Claim 10: "U2a4 makes them starts in both walks (`isstart`), resolved against the directory holding their `.claude/` and the top level as well as their own, and fails the main walk on one main stores as a symlink"

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers command files at a single `.claude/` level, at the top level and under `sub/`; does not establish the nested-`.claude/` case (Claim 20).
**Legibility-target:** for-orchestrator-synthesis

`xs=(); [[ -z "${pdir[$f]+set}" ]] || xs=("${pdir[$f]}" "")` then `import_targets "$d" "${xs[@]}"` in the tree walk (`scripts/lib/dev-cycle-read.sh:832-834`) and in both main-walk read arms (`:894`, `:897-900`). Tests 73 and 74 passed: `sub/.claude/commands/x.md`'s `@docs/s1.md` yields `sub/.claude/commands/docs/s1.md`, `sub/docs/s1.md` and `docs/s1.md` in both walks; the main walk fails on a `.claude/commands/t.md` symlink. This one says "the main walk", unlike Claim 3.

**Evidence:** `scripts/lib/dev-cycle-read.sh:813-937`; `/tmp/u2a4-cfc-hECA/bats-build-loop-check.log`

---

## Claim 11: "the caller contract is in the U2b bullet" (and commit d7cdc1ea's subject: "A5 and F11 name the one start rule and the caller contract")

**Location:** `docs/working/plan-build-loop-handoff.md:126`
**Type:** Reference / Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the F11 row's pointer to the caller contract; does not establish any behavioural defect (the U2b bullet now points on to the lib header, so the chain still ends in the right place).
**Legibility-target:** for-author

This branch rewrote the F11 row (the U2a4 sentence about `isstart` is new) but kept "...and a checkout listing git prints any stderr for fails the walk; the caller contract is in the U2b bullet." Since U2a4 the contract is the lib header's numbered list (`scripts/lib/dev-cycle-read.sh:41-66`), and the U2b bullet says it "keeps the lib header's numbered gate caller contract (U2a4; the one statement of these duties ...)" (`:279`). So F11 does not name the contract, which the d7cdc1ea subject says it does. Precise version: "the caller contract is the lib header's numbered list (U2a4)."

**Evidence:** `docs/working/plan-build-loop-handoff.md:126`, `:279`; `scripts/lib/dev-cycle-read.sh:41-42`

---

## Claim 12: "The walks share one name parser and, from U2a4, one start rule (`isstart`: instruction files and `.md` files under `.claude/{rules,commands,agents,output-styles}/` at any depth; a command's names ... also resolve against its session directories, and a prompt start main stores as a symlink fails the walk)"

**Location:** `docs/working/plan-build-loop-handoff.md:126`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the shared predicate and the main walk's symlink failure; "fails the walk" here means the main walk (the same caveat as Claim 3: the tree walk skips a symlinked start).
**Legibility-target:** for-orchestrator-synthesis

Same evidence as Claims 8 and 10: `isstart` is called at `scripts/lib/dev-cycle-read.sh:824` and `:883`, and the symlink rule is at `:903`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:482-483`, `:824`, `:883`, `:903`

---

## Claim 13: "Built 2026-10-07 (`feat/build-loop-u2a4`): `truthrule` ... and `truthwalk` (walk, then isimported), which check_fix and floor both call; `isstart` for both walks, ...; the index queue pop (row 461); the lib header's numbered gate caller contract (row 459). Outside-repo starts stay U2b's; `IMPORTED_MAIN_WHY` (row 376) moves to U2c."

**Location:** `docs/working/plan-build-loop-handoff.md:278`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each named artefact's presence in the diff; does not establish anything about U2b/U2c.
**Legibility-target:** for-orchestrator-synthesis

Every named symbol exists: `truthrule` (`:965`), `truthwalk` (`:980`), `isstart` (`:483`), `prompt_dir` (`:490`), index pops (`:830-832`, `:891-894`), the contract (`:41-66`); `IMPORTED_MAIN_WHY` does not appear in the lib (grep), consistent with "moves to U2c".

**Evidence:** `scripts/lib/dev-cycle-read.sh:41-66`, `:482-490`, `:965-985`

---

## Claim 14: "The denials it shares with the self-merge floor are the lib's truthrule."

**Location:** `scripts/dev-cycle.sh:170`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers check_fix's call of truthrule; does not establish that check_fix's own extra denials (`docs/working/`, `docs/reviews/`, non-docs) are shared (they are not, on purpose).
**Legibility-target:** for-orchestrator-synthesis

`if truthrule "$lp" && [[ "$TRUTH_WHY" == cycle ]]; then ...` (`scripts/dev-cycle.sh:177`).

**Evidence:** `scripts/dev-cycle.sh:166-185`

---

## Claim 15: Gate caller contract item 1: "Run as above, with main found by name, under LC_ALL=C (under a UTF-8 locale a non-UTF-8 name on main fails the walk)."

**Location:** `scripts/lib/dev-cycle-read.sh:43-44`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers main_imports' answer for a main commit holding `docs/n\xff.md` under `C` and `C.utf8`; does not establish the tree walk's behaviour under UTF-8.
**Legibility-target:** for-orchestrator-synthesis

`main_by_name || return 1` (`:867`). Executed (`/tmp/u2a4-cfc-hECA/probe/p1.sh`): `LC_ALL=C` → `walk ok`; `LC_ALL=C.utf8` → `walk failed` (the tree record regex at `:870` does not match the invalid byte under UTF-8).

**Evidence:** `scripts/lib/dev-cycle-read.sh:860-875`; `/tmp/u2a4-cfc-hECA/probe/p1.log`

---

## Claim 16: Contract items 2-4 and 6-7 (clean worktree at MAIN_SHA, "the walk reads main's blob for every path main stores, and the checkout only where main lacks a path", empty ls-files stderr; "U2b builds this; the walk does not check it"; clear IMPORTED_MAIN_DONE / both caches; "IMPORTED_MAIN=error reads as "not imported" to a raw membership test"; "A second caller of main_checkout passes a fresh MEMO per walk and ENT, and only a PATH main lacks")

**Location:** `scripts/lib/dev-cycle-read.sh:45-56`, `:61-64`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each item's stated mechanism against the code; does not establish U2b's future enforcement of items 2-4.
**Legibility-target:** for-orchestrator-synthesis

Item 2: `case "${ent[$f]-checkout}" in checkout) ... capped_read < "$f" ...; 100644|100755) ... git cat-file blob "$MAIN_SHA:$f"` (`:896-900`), and `checkout_md() { local e; { e="$(md_ls --cached --others 2>&1 >&3)"; } 3>&1 && [[ -z "$e" ]]; }` (`:767`). Item 3: the only `check-attr`/`core.symlinks` mention in the lib is in comments (executed grep, `/tmp/u2a4-cfc-hECA/probe/p1.log`: one line). Item 4: the cache key is `"$MAIN_SHA $MAIN_BY_NAME $ROOT_REAL"` (`:866`), without the checkout or HOME. Item 6: with `IMPORTED_MAIN=error`, `[[ "$IMPORTED_MAIN" == *$'\n'"$lp"$'\n'* ]]` (`:949`) is false. Item 7 matches main_checkout's own comment: "A MEMO hit skips that mode check too, so a MEMO serves one walk and one ENT. main_imports calls it only for paths main lacks." (`:775-776`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:45-56`, `:61-64`, `:767`, `:772-811`, `:860-948`

---

## Claim 17: Contract item 5: "Ask floor about each changed path, in this shell, before pathform or main_entry (so .github/x.yml is refused as a dotfile, not as badform), and refuse the whole branch on any main_entry word but blob or absent (rows 308, 324). Floor item 5 (symlinks, gitlinks) and the brief's own Status change are the caller's rules."

**Location:** `scripts/lib/dev-cycle-read.sh:57-60`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `.github/x.yml` wording, the row references, and that floor checks no mode or Status; does not establish a caller that obeys the order (none exists until U2b/U2c).
**Legibility-target:** for-orchestrator-synthesis

See Claim 6 for the execution. Rows 308 and 324 (`docs/reviews/override-log.md:308`, `:324`) are the ones about main_entry `error` and floor-before-main_entry. Plan D5 item 5 is "symlinks and gitlinks" (`docs/working/plan-build-loop-handoff.md:73`). Floor reads no mode, and a brief path is refused as `cycle` (`writable` → `isbrief`, `:196-199`), so the caller must judge the own brief's Status first, as floor's comment says ("the caller judges the brief's own Status change before this", `:1007`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:57-60`, `:1000-1032`; `docs/reviews/override-log.md:308`, `:324`; `/tmp/u2a4-cfc-hECA/probe/p1.log`

---

## Claim 18: "an instruction file's name, or a .md file at any depth under a .claude/ directory's rules/ (...) or PROMPT_DIR's commands/, agents/ or output-styles/ ..."

**Location:** `scripts/lib/dev-cycle-read.sh:474-481`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers isstart over 234,256 generated lower-cased paths (Claim 22's probe); does not establish Claude Code's loading of `agents/` and `output-styles/` (untraced, as the comment says).
**Legibility-target:** for-orchestrator-synthesis

See the `isstart` quote in Claim 8. `"/$1" == */.claude/rules/*` matches a top-level `.claude/rules/` and any deeper one; `^(.*/)?\.claude/` does the same for the prompt directories.

**Evidence:** `scripts/lib/dev-cycle-read.sh:474-483`; `/tmp/u2a4-cfc-hECA/probe/p2.log`

---

## Claim 19: "truthrule refuses the same names"

**Location:** `scripts/lib/dev-cycle-read.sh:480-481`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers truthrule's first branch; does not establish that a caller lower-cases before calling (both do).
**Legibility-target:** for-orchestrator-synthesis

`if isstart "$1"; then TRUTH_WHY="instr"` (`:967`): the same predicate, not a copy.

**Evidence:** `scripts/lib/dev-cycle-read.sh:965-975`

---

## Claim 20: "prompt_dir MAP LP PATH: for a start under PROMPT_DIR (...), MAP[PATH] gets the directory holding its .claude/ ("" at the top level; as PATH spells it), where a session resolving its names starts; a walk reads it against that and the top level. Not covered: a session started in any other directory (U2b's reader model)."

**Location:** `scripts/lib/dev-cycle-read.sh:484-490`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers prompt_dir's output for single and nested `.claude/` paths, mixed case, and BASH_REMATCH ordering; does not establish whether Claude Code loads a command from a `.claude/` nested inside another prompt directory (untraced; medium confidence rests on that).
**Legibility-target:** for-author

```bash
# scripts/lib/dev-cycle-read.sh:490
prompt_dir() { local -n pd_m="$1"; [[ ! "$2" =~ $PROMPT_DIR ]] || pd_m[$3]="${3:0:${#BASH_REMATCH[1]}}"; }
```

BASH_REMATCH is set by prompt_dir's own `=~` right before it is read, so an earlier isstart call cannot clobber it, and LP and PATH have the same byte length (ASCII-only `tr`). Executed (`/tmp/u2a4-cfc-hECA/probe/p3.sh`): `.claude/commands/x.md -> ""`, `.Claude/Commands/ns/X.md -> ""`, `Sub/.claude/agents/r.md -> Sub/`, `.claude/rules/x.md -> <unset>`. With two `.claude/` levels, `(.*/)?` is greedy and picks the innermost: `a/.claude/commands/b/.claude/commands/x.md -> a/.claude/commands/b/`, so a session in `a` (the directory holding the outer `.claude/`) is not read. The "Not covered: any other directory" clause can be read to include this, but "the directory holding its .claude/" reads as unique. Precise version: "the directory holding its innermost .claude/". The value also keeps a trailing `/` (`Sub/`), which `put`'s split absorbs.

**Evidence:** `scripts/lib/dev-cycle-read.sh:482-490`; `/tmp/u2a4-cfc-hECA/probe/p3.log` (exit 0)

---

## Claim 21: "a prompt start (prompt_dir) main stores as a symlink ... fail the walk" and "(floor refuses start files by truthrule)"

**Location:** `scripts/lib/dev-cycle-read.sh:514`, `:523`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the main walk's 120000 arm for a prompt start and floor's `instr` answer; does not establish a prompt start reached only through a symlinked directory (not listed by `ls-tree -r`: A5's "start files under a symlinked directory").
**Legibility-target:** for-orchestrator-synthesis

`[[ ${#xs[@]} -eq 0 ]] || { IMPORTED_MAIN=error; return 1; }` (`:903`); test 74 passed (`walk failed` after `ln -s ../../docs/t.md .claude/commands/t.md`). Floor test 70 gives `$INSTR` for `.claude/rules/x.md` and `.claude/commands/c.md`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:901-903`, `:1016-1018`; `/tmp/u2a4-cfc-hECA/bats-build-loop-check.log`

---

## Claim 22: "instruction_names is its grep prefilter" / "It matches isstart's names; isstart stays the authority."

**Location:** `scripts/lib/dev-cycle-read.sh:481`, `:735-739`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers case, depth, the `.claude/rules/` vs `*/.claude/rules/*` glob, prompt directories and top-level starts, over 234,256 generated paths; does not establish names holding a newline (refused by the walk only after the prefilter passes them, pre-existing) or non-ASCII case folding (both sides are ASCII-only).
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/lib/dev-cycle-read.sh:739
instruction_names() { env LC_ALL=C grep -zaiE '(^|/)((claude|agents?|gemini)(\.[a-z0-9_-]+)?|skill)\.md$|(^|/)\.claude/(rules|commands|agents|output-styles)/.*\.md$' || [[ $? -eq 1 ]]; }
```

Probe `/tmp/u2a4-cfc-hECA/probe/p2.sh` (cwd that dir, `LC_ALL=C timeout 600 bash p2.sh`, exit 0, 2026-10-08T06:16:18Z): every 1-4-component path over 22 components (`.claude`, `.Claude`, `rules`, `Rules`, `commands`, `agents`, `output-styles`, `CLAUDE.md`, `Skill.MD`, `.md`, `x y.md`, `b.mD`, ...) fed through `instruction_names` raw and through `isstart` lower-cased: `total 234256 isstart=66528 miss=0 grep-only=0`. The prefilter is a superset (here, exactly equal), so it drops no start isstart accepts. (One harmless `bad array subscript` line is the probe's own empty path.)

**Evidence:** `scripts/lib/dev-cycle-read.sh:482-483`, `:739`, `:763`; `/tmp/u2a4-cfc-hECA/probe/p2.log`

---

## Claim 23: "The walk starts at every start file in the checkout (isstart), tracked or not ..., resolves each @path against the importing file's directory (and a prompt's against prompt_dir's)"

**Location:** `scripts/lib/dev-cycle-read.sh:491-495`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the tree walk's starts and base directories (a prompt is also read against the top level, as prompt_dir's comment says); does not establish symlinked starts (skipped, A2).
**Legibility-target:** for-orchestrator-synthesis

`if ! isstart "$lp" || ! inrepo_here "$f"; then continue; fi` and `prompt_dir pdir "$lp" "$f"` (`:824-826`); `import_targets "$d" "${xs[@]}"` (`:834`). Test 73 (tree arm) passed.

**Evidence:** `scripts/lib/dev-cycle-read.sh:813-856`; `/tmp/u2a4-cfc-hECA/bats-build-loop-check.log`

---

## Claim 24: "a relative name resolved against $1 and against each further directory given (a prompt's session directories: prompt_dirs)"

**Location:** `scripts/lib/dev-cycle-read.sh:564-566`
**Type:** Behavioral / Staleness
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers import_targets' multi-directory resolution; does not establish anything about a symbol named `prompt_dirs`, which does not exist.
**Legibility-target:** for-author

The behaviour holds: `import_targets docs "" "" sub/` on `@~/k.md @r.md` prints `docs/r.md`, `r.md`, `sub/r.md` (`/tmp/u2a4-cfc-hECA/probe/p4.log`), and test 75 passed. But `prompt_dirs` does not grep anywhere in scripts/, test/ or docs/ outside this comment; the function is `prompt_dir` (`:490`). Precise version: "(a prompt's session directories: prompt_dir)".

**Evidence:** `scripts/lib/dev-cycle-read.sh:490`, `:564-566`; `/tmp/u2a4-cfc-hECA/probe/p4.log`

---

## Claim 25: IMPORT_AWK: "IT_XDIRS: the further directories, each led by an x so "" survives split." (with the emit/put split: the work charge, the `tried` memo, and `~/` names)

**Location:** `scripts/lib/dev-cycle-read.sh:613-627`, `:672-673`; `:742`
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the encoding (no trailing empty element, `""` kept), single-directory parity with main's parser (names and work trailer), and once-per-spelling `~/` puts; does not establish the cost of the extra puts on adversarial input (a prompt pays up to 3 resolved spellings per candidate, each charged).
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/lib/dev-cycle-read.sh:742
  [[ $# -lt 2 ]] || x="$(printf 'x%s\n' "${@:2}")"  # the walks refuse a name holding a newline
```

`$(...)` strips the final newline, so `split(ENVIRON["IT_XDIRS"], dirs, "\n")` yields exactly one element per directory, and `substr(dirs[i], 2)` turns `x` into `""` (`:673`); with no extra directory `x=""` and `nd=0`. `emit` returns after one `put(c)` for an absolute name, and a `~/` name becomes absolute before that test (`:620-626`), so it is put once per spelling, not once per directory; `put` charges `work += length(c)` before `if (c in tried) return` (`:631-633`), as main's `put` did. Executed (`/tmp/u2a4-cfc-hECA/probe/p4.sh`, exit 0): main's and the branch's `import_targets` with one directory print identical output and identical work trailers on `AGENTS.md` (`/0`), `docs/working/known-issues-dev-cycle.md` (`/1812`) and `docs/working/plan-build-loop-handoff.md` (`/5570`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:613-680`, `:699-723`; `/tmp/u2a4-cfc-hECA/probe/p4.log`

---

## Claim 26: "An index, not a copy per pop" (both walks) and the phase-2 swap "`queue=("${tq[@]}"); tq=(); qi=0`  # phase 2: main's walk is done", against "Phase 2 begins when queue empties: tq's checkout files then join it"

**Location:** `scripts/lib/dev-cycle-read.sh:830`, `:891-893`, `:857-858`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the ordering: main's queue drains before tq is swapped in, main paths found in phase 2 still go to `queue` and run before the remaining tq items, as on main; does not establish run time.
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/lib/dev-cycle-read.sh:892-894 (excerpt ends :894; enclosing main_imports continues to :937 — read)
  while [[ $qi -lt ${#queue[@]} || ${#tq[@]} -gt 0 ]]; do
    [[ $qi -lt ${#queue[@]} ]] || { queue=("${tq[@]}"); tq=(); qi=0; }  # phase 2: main's walk is done
    f="${queue[qi]}"; qi=$((qi + 1)); xs=(); [[ -z "${pdir[$f]+set}" ]] || xs=("${pdir[$f]}" "")
```

The swap fires exactly when main's old test `[[ ${#queue[@]} -gt 0 ]]` would have been false (all queued items consumed), resets `qi`, and the appends at `:935` (`queue+=` for a path main stores, `tq+=` for an admitted checkout path) are unchanged. All walk tests passed, including the U2a3c phase-ordering tests.

**Evidence:** `scripts/lib/dev-cycle-read.sh:857-937`; `/tmp/u2a4-cfc-hECA/bats-build-loop-check.log`

---

## Claim 27: isimported: "a caller that words a failed walk asks truthwalk, which runs the walk first"; truthwalk: "Returns 0 when the walk fails (TRUTH_WHY=walk) or reaches LP (TRUTH_WHY=imported), else 1; an unknown WALK answers walk."

**Location:** `scripts/lib/dev-cycle-read.sh:941-942`, `:976-980`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers truthwalk's three outcomes; does not establish the case where `lower` fails inside isimported after a successful walk (isimported answers 0, and truthwalk then reports `imported`, not `walk`: a refusal either way, worded as an import).
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/lib/dev-cycle-read.sh:980-983
truthwalk() {
  TRUTH_WHY=walk
  case "$2" in main) main_imports || return 0 ;; tree) imported_names || return 0 ;; *) return 0 ;; esac
  TRUTH_WHY=imported; isimported "$2" "$1"
}
```

**Evidence:** `scripts/lib/dev-cycle-read.sh:939-985`

---

## Claim 28: floor's comment: ported from feat/build-loop-u2a2-full; "Returns 0 with FLOOR_WHY set when the floor refuses, else 1. ... The caller's duties are the gate caller contract's (the lib's header)"; truthrule's "(plan D5 items 1, 2 and 4; override rows 204, 322, 348)"

**Location:** `scripts/lib/dev-cycle-read.sh:954-963`, `:1000-1010`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers floor's return contract, its refusal set against the ancestor's, and the row and D5 item references; does not establish identical FLOOR_WHY ordering with the ancestor (the walk now runs last, so a path that is both imported and, say, another brief's working file is worded as a working file; both refuse).
**Legibility-target:** for-orchestrator-synthesis

The ancestor (`git show feat/build-loop-u2a2-full:scripts/lib/dev-cycle-read.sh`, `floor()` at its line 617) refuses the same set but tested the walk before the cycle, record and working rules; the branch's floor checks `truthrule`, `$GATE_CODE`, `docs/thoughts/*`, working, reviews, and then `truthwalk` (`:1016-1031`). Rows 204, 322 and 348 are the check_fix/floor shared-list rows (`docs/reviews/override-log.md:204`, `:322`, `:348`); plan D5 items 1, 2 and 4 are instruction files and imports, dot components, and read-as-truth files (`docs/working/plan-build-loop-handoff.md:69-72`). Floor tests 70-72 passed.

**Evidence:** `scripts/lib/dev-cycle-read.sh:954-1032`; `docs/working/plan-build-loop-handoff.md:66-73`; `/tmp/u2a4-cfc-hECA/bats-build-loop-check.log`

---

## Claim 29: Commit d861183d: "All 7 fail on main's code."

**Location:** `git log main..HEAD` (d861183d body)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the seven U2a4 tests as committed in d861183d and as at HEAD, each against main's and the branch's code; does not establish anything about the other 68 tests.
**Legibility-target:** for-author

Executed (`/tmp/u2a4-cfc-hECA/probe/p7.sh`, `p7b.sh`; `bats -f U2a4`, cwd a `git archive` copy of the code under test, 2026-10-08T06:18:06Z and 06:19:01Z): d861183d's tests on main's code: `not ok 1`-`not ok 7` (true as written). But d861183d's test 6 also fails on the branch's own code: its fixture wrote `printf 'see @docs/x.md\n' > docs/t.md`, which resolves to `docs/docs/x.md`, so its first assertion (`want docs/x.md imported` for the rules symlink) fails whatever the code. c934adbc changed the fixture to `@x.md` without saying so in its message. HEAD's tests on main's code: all 7 fail, test 6 now at the right assertion (`want walk failed`, got `walk ok`). Precise version: "6 fail on main's code for the missing feature; test 6's fixture was corrected in the feat commit."

**Evidence:** `/tmp/u2a4-cfc-hECA/probe/p7.log`, `/tmp/u2a4-cfc-hECA/probe/p7b.log`; `git diff d861183d HEAD -- test/` (one line, `test/scripts/build-loop-check.bats:1157`)

---

## Claim 30: Commit c934adbc: "Tests: build-loop-check 75, build-loop-read 19, dev-cycle 78, fixture-git-env 2, fixture-hermeticity 2, hermeticity-lint 53; health check passed. 381 changed code lines against main." (also "the tree walk gains rules/ (main had it only in main_imports)")

**Location:** `git log main..HEAD` (c934adbc body)
**Type:** Configuration / Behavioral
**Verdict:** Unverifiable
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the six counts (`bats --count`), the three gate suites passing, the 381-line figure, and the rules/ statement; the "health check passed" atom is not established (the health check runs the whole test suite; not run in this pass). Every other atom is Verified; the claim carries Unverifiable only for that atom.
**Legibility-target:** for-orchestrator-synthesis

`bats --count`: build-loop-check 75, build-loop-read 19, dev-cycle 78, fixture-git-env 2, `test/fixture-hermeticity.bats` 2, `test/hermeticity-lint.bats` 53. `bats test/scripts/{build-loop-check,build-loop-read,dev-cycle}.bats` (cwd worktree, `TMPDIR=/tmp/u2a4-cfc-hECA`, 2026-10-08T06:16:02Z-06:16:49Z): all three exit 0. `git diff --numstat main...HEAD` over scripts/ and test/: 9+11+167+37+157 = 381. Main's tree walk tested only `"$lp" =~ $INSTRUCTION_FILE` on the basename, while main's main_imports also had `.claude/rules/` (removed lines in the diff at `scripts/lib/dev-cycle-read.sh` old `:776`, `:826`). To verify the remaining atom: run `scripts/health-check.sh` on HEAD.

**Evidence:** `/tmp/u2a4-cfc-hECA/bats-build-loop-check.log`, `/tmp/u2a4-cfc-hECA/bats-build-loop-read.log`, `/tmp/u2a4-cfc-hECA/bats-dev-cycle.log`; `git diff --numstat main...HEAD`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
- **Claim 11** (`docs/working/plan-build-loop-handoff.md:126`): F11 still says "the caller contract is in the U2b bullet"; it is the lib header's numbered list now, so d7cdc1ea's subject ("A5 and F11 name ... the caller contract") overstates F11.

### Mostly Accurate
- **Claim 2b** (`docs/reviews/override-log.md:462`, c934adbc body): "3,092 tracked paths" should be 3,097 (3,092 was 4ce2c6bf's count); the identity result holds over 3,097.
- **Claim 3** (`docs/reviews/override-log.md:463`): "a prompt start main stores as a symlink fails the walk" is true of the main walk only; the tree walk skips a symlinked prompt start (A2).
- **Claim 9** (`docs/working/known-issues-dev-cycle.md:18`, `scripts/lib/dev-cycle-read.sh:42`): "the one statement" of the caller contract; the U2b bullet and the walk comments still restate it.
- **Claim 20** (`scripts/lib/dev-cycle-read.sh:484-490`): prompt_dir picks the innermost `.claude/` on a nested path (`a/.claude/commands/b/.claude/commands/x.md -> a/.claude/commands/b/`); the outer directory `a` is not a base.
- **Claim 24** (`scripts/lib/dev-cycle-read.sh:566`): `prompt_dirs` names no symbol; the function is `prompt_dir`.
- **Claim 29** (d861183d body): "All 7 fail on main's code" holds, but the red commit's test 6 failed for a fixture error that also failed on the branch's code; c934adbc fixed the fixture silently.

### Unverifiable
- **Claim 30** (c934adbc body): "health check passed" not re-run (it runs the full suite); counts, suites and line count verified.

## Goal-Alignment Note
- Success criterion (restated verbatim): your report saved at the path your task names, structured per your skill, with every finding grounded in verbatim evidence.
- Answered: yes. All eight focus areas were checked, and areas 1-7 were executed. No behavioural or contract defect: the prefilter equals isstart over 234k paths, the BASH_REMATCH order is safe, IT_XDIRS keeps "" with no trailing element, --check-fix output is identical to main's, and the phase ordering is preserved.
- Out of scope: the health check (full suite) was not run, and hallucination-patterns.md was not updated, since the brief allows writing this report only. Claude Code's real behaviour for nested `.claude/` command directories and for agents/output-styles cannot be checked without egress.
- Escalate: (1) Claim 20's nested-`.claude/` base directory is a possible under-read (the failure class the brief names), low likelihood and untraced: decide whether prompt_dir should add every enclosing `.claude/`'s directory or A5 should name the case. (2) The d861183d red-test claim was partly vacuous for test 6 (Claim 29). This is a process note for the test-first record.
- Decisions I made: Claim 2b is Mostly accurate rather than Incorrect, because the count is off by 5 while the identity result holds; Incorrect would fit the logged "specific measured value" pattern. Claim 20 is Mostly accurate rather than Verified-with-residue, because "the directory holding its .claude/" reads as unique.
