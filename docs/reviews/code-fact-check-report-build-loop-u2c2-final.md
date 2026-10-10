# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u2c2 (branch `feat/build-loop-u2c2`, HEAD 8786f8fc)
**Commit:** 8786f8fc
**Replication:** k=3
**Scope:** `git diff main...HEAD -- scripts test` (code commits 3111ee9d, 07af69c0, 2be3db37), those three commit messages, and the Fixed/Defer statuses (A1-A16, B1-B5) in `docs/reviews/code-review-rubric-2026-10-10-feat-build-loop-u2c2.md`. Final confirming pass, merged from replicates r1 (`code-fact-check-report-build-loop-u2c2-final-r1.md`, agent `fcf1`, 33 claims), r2 (`-r2.md`, agent `fcf2`, 40 claims) and r3 (`-r3.md`, agent `fcf3`, 30 claims) by most-severe-wins (`skills/code-review/SKILL.md`, "Merging replicate verdicts").
**Checked:** 2026-10-10
**Total claims checked:** 49
**Summary:** 36 verified, 8 mostly accurate, 1 stale, 2 incorrect, 2 unverifiable

Merge notes. This report is collation only: every verdict, quote and probe result below comes from one of the three replicate reports, and the merge adds no claim or evidence. Each claim's prose and `**Evidence:**` are carried from the replicate that assigned the winning verdict (named in the prose's first line). Where a replicate verdicted a sentence as one compound claim and another split it, the merged report carries the split rows and records the compound verdict on each row as `(compound)`. All three replicates read `docs/reviews/hallucination-patterns.md` first and found no claim matching a logged pattern.

Execution provenance (carried from each replicate; the per-claim `executed` verdicts cite these logs). All probe dirs were under `/tmp/claude-1000/-workspace/843b51ad-a12f-4e61-b040-53f5def15aef/scratchpad/u2c2-review/` and were removed after each run.
- **r1 (`fcf1-*`)**, all under `LC_ALL=C`: `fcf1-bats.sh` → `fcf1-bats.log` (2026-10-10T17:04:26Z, cwd the review worktree, exit 0; the six changed or new build-loop-check tests, all pass); `fcf1-probe.sh` → `fcf1-probe.log` (17:05:08Z, exit 0; P1-P9); `fcf1-probe2.sh` → `fcf1-probe2.log` (17:05:54Z, exit 0; probe PC against main's and HEAD's lib, timing); `fcf1-probe3.sh` → `fcf1-probe3.log` (17:06:40Z, exit 0; both walks over the review worktree with both libs, cached floor timing); `fcf1-probe4.sh` → `fcf1-probe4.log` (17:07:33Z, exit 0; forks per cached floor call; logged run carries noise from concurrent agents: 0, 336 and 129 against earlier clean 0, 300, 100); `fcf1-probe5.sh` → `fcf1-probe5.log` (17:08:07Z, exit 0; the main walk's list for a one-import fixture). The sandbox exports `CLAUDE_CONFIG_DIR=/home/node/.claude`.
- **r2 (`fcf2-*`)**: E1 `bash fcf2-run.sh` (10:04:52-10:05:58-07:00, exit 0; full build-loop-check 143/143 ok → `fcf2-logs/full-build-loop-check.txt`; the six new or reworked tests against main's lib, all not ok → `fcf2-logs/old-main.txt`; against ac078bd7's lib, tests 2 and 4 not ok → `fcf2-logs/old-ac078bd7.txt`); E2 dev-cycle.bats surface test (10:06:21, exit 0, 1/1 ok → `fcf2-logs/dev-cycle-surface.txt`); E3 `bash fcf2-probe.sh` (10:05:21, exit 0 → `fcf2-probe.out`; P1-P5); E4 `bash fcf2-time.sh` (10:07:00-10:07:13, exit 0 → `fcf2-logs/timing.txt`; load average 1.73); E5 `bash fcf2-prefix.sh` (10:08:04, exit 0 → `fcf2-logs/prefix.txt`).
- **r3 (`fcf3-*`)**: P1-P7 `bash fcf3-probe1.sh` (17:04:46Z, exit 0 → `fcf3-logs/probe1.log`); suites `bash fcf3-probe2.sh` (17:04:57Z to about 17:06:35Z, exit 0; build-loop-check 143 ok, build-loop-read 20 ok, dev-cycle 79 ok → `fcf3-logs/bats-*.log`); P8/P9 `bash fcf3-probe3.sh` (17:06:53Z, exit 0 → `fcf3-logs/probe3.log`) and a P8 rerun (17:07:14Z, exit 0 → `fcf3-logs/probe3b.log`); count checks from the worktree (`git show <c>:test/scripts/build-loop-check.bats | grep -c '^@test'`: main 138, 3111ee9d 142, 07af69c0 142, 2be3db37 143; numstat sums 266, 349, 360).

---

## Claim 1: build-loop.sh --check help: "a path below a start file's or an imported .md file's name, ... a walk that fails refuses every path, its reason saying where, with a PATH outside pathform's characters shown as ?"

**Location:** `scripts/build-loop.sh:177-184`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** a `--check` user reading `--help` (operator)
**Scope:** Covers floor's below-a-name rule, the walk-failure wording and the `?` substitution as srules reaches them. It does not establish what happens to the brief's own file or to a path the N rules refuse, since floor is not run on either.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "It does not establish that every KIND's sentence names a path: readers, main, tree, list, seeds, copies and budget name a stage, not a path." · r3: "does not establish the rest of the help paragraph, which this diff did not change."

Evidence carried from r1 (three-way Verified tie; r1's scope is the most concrete). The help sentence names each rule floor implements. The below-a-name loop is `scripts/lib/dev-cycle-read.sh:1947-1949`: `d="${d%/*}"; ! isstart "$d" && { [[ "$d" != *.md ]] || ! walk_has main "$d"; } || { FLOOR_WHY="a path below the name of ..."`. The walk-failure reason is `:1943`: `FLOOR_WHY="... could not be walked for @ imports: $(walk_why "$IMPORTED_MAIN_WHY")"`. The `?` rule is in walk_why at `:811`: `[[ -z "$d" || "$d" =~ ^[$NAMECHARS]+$ ]] || d="?"`. "Refuses every path" holds because a path that reaches the walk is refused with the walk reason, and any earlier floor rule refuses with its own reason. Bats test "floor fails closed when main's walk fails, saying where" passes (fcf1-bats.log), including the `? could not be read` row for `a b/CLAUDE.md`.

**Evidence:** `scripts/build-loop.sh:177-184`, `scripts/lib/dev-cycle-read.sh:1925-1952`, `scripts/lib/dev-cycle-read.sh:808-826`, `fcf1-bats.log`

---

## Claim 2: srules passes the lowered path as floor's $4 "so floor forks no lower"

**Location:** `scripts/build-loop.sh:671`
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer of build-loop.sh and the lib's floor
**Scope:** Covers srules' fourth argument and floor's use of it. It does not establish forks inside a walk that misses its cache.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "It does not establish that another caller of floor passes `$4`: the bats `floors` helper does not, so it exercises the lowering path." · r3: "does not establish any other floor caller, because none exists (grep: floor is called only at build-loop.sh:671)."

Evidence carried from r1 (three-way Verified tie; r1 is the only executed one). `scripts/build-loop.sh:671` reads `if [[ -z "$5" ]] && floor "$2" "$1" "$4" "$3"; then`. Its caller passes `"${lps[$i]}"`, which comes from `nul_list lps lower_all "${ps[@]}"` at `:840` and `:844`. Floor's first line, `:1926-1928`, is `local lp="${4-}" d` … `[[ -n "$lp" ]] || lp="$(lower "$1")"`, so a non-empty $4 skips the lower. Probe 4 counted 0 forks per 100 cached floor calls with $4, against about 300 (3 per call) without it (fcf1-probe4.log).

**Evidence:** `scripts/build-loop.sh:668-682`, `scripts/build-loop.sh:838-845`, `scripts/lib/dev-cycle-read.sh:1925-1928`, `fcf1-probe4.log`

---

## Claim 3: Lib header: "inrepo, dirok, skipped, check_brief, isimported and the import walks (truthwalk and floor through them; ...) exit 1 (need_root) unless ROOT_REAL is set, is the current directory and is a repository's top level"

**Location:** `scripts/lib/dev-cycle-read.sh:18-21`
**Type:** Behavioral / Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** caller of the lib (a future gate script author)
**Scope:** Covers floor and truthwalk with ROOT_REAL unset. It does not establish anything about inrepo, dirok, skipped or check_brief, whose bodies this diff does not touch.
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r1+r2+r3: fail-closed — every early-returned path is a refusal, so no path lands. · r1: "truthwalk with an unknown WALK also returns without a check: `*) return 0 ;;` at `:1883`." · r1+r3: floor's own doc already says this correctly at `:1919` ("whose root check runs when it walks"); only the header list is loose. · r3 (escalation note): "build-loop.sh's comment at :867 relies on 'the floor's need_root exit ends the run' for a misconfigured root." · r1 scope: "It does not establish check_brief's behavior, which this diff did not change."

Evidence carried from r2 (three-way Mostly-accurate tie; r2 and r3 share the most specific scope, tie broken to r2). floor has no root check of its own: `local lp="${4-}" d; FLOOR_WHY=""` (`:1926-1927`). It reaches need_root only through `truthwalk main` → `main_imports` → `readers_root`. A path that truthrule, GATE_CODE, docs/thoughts/, docs/working/ or docs/reviews/ refuses returns 0 before that call. In probe P1 (E3), with ROOT_REAL unset, `floor CLAUDE.md`, `.envrc`, `docs/roadmap.md` and `scripts/lib/x.sh` each returned a refusal and the script printed `reached-end` (rc 0), with no exit. `docs/x.md`, which does reach the walk, exits 1 (test at `build-loop-check.bats:1388-1389`). The parenthetical "through them" points at this, but a reader can still take the sentence to mean that floor always exits when ROOT_REAL is unset. A precise version: floor exits through the walk only for a path that reaches the walk; an earlier rule's refusal returns 0 with no root check. That is fail-closed, so no path lands. (r1's P1 and r3's P2a/P2b reproduce the same split.)

**Evidence:** `scripts/lib/dev-cycle-read.sh:18-21`, `scripts/lib/dev-cycle-read.sh:1925-1952`, `test/scripts/build-loop-check.bats:1388-1389`, `fcf2-probe.out` (P1), `fcf1-probe.log` (P1), `fcf3-logs/probe1.log` (P2a, P2b)

---

## Claim 4: Lib header: "a call the walk's caches answer checks only that ROOT_REAL is set"

**Location:** `scripts/lib/dev-cycle-read.sh:19-20`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** a gate caller reading the lib header
**Scope:** Covers main_imports and imported_names on a hit in both import_readers' memo (a held result) and the walk cache. It does not establish isimported, which keeps its own `need_root` at `:1836`.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "It does not establish behavior when HOME changed since the memo: import_home then recomputes, the key differs, and need_root runs." · r2: "The memo key includes ROOT_REAL's value (`:1145-1147`), so 'set' in practice means 'set to the memoized value'." · r3: "It does not cover a memo miss or a memoized refusal: both run need_root, which P4 also showed."

Evidence carried from r1 (three-way Verified tie; lowest replicate). On a hit, readers_root (`:833`) is satisfied by `[[ -n "${ROOT_REAL:-}" ]] && import_home && import_readers_key && [[ "$IMPORT_READERS_DONE" == "$IMPORT_READERS_KEY" && -n "$IMPORT_ROOTS" ]]`. Both walks then return from the cache check before their own `need_root` (`:1629-1630`, `:1704-1706`). In P2 the walk was cached, then the probe ran `cd /`. `floor docs/q.md` still answered `-` and `floor docs/a.md` answered imported, while `isimported main docs/a.md` exited with "ROOT_REAL is not the current directory" (fcf1-probe.log). (r2's P4 and r3's P4 show the same held-result return from `/`.)

**Evidence:** `scripts/lib/dev-cycle-read.sh:827-833`, `scripts/lib/dev-cycle-read.sh:1623-1631`, `scripts/lib/dev-cycle-read.sh:1698-1707`, `fcf1-probe.log` (P2)

---

## Claim 5: Contract item 4: "neither walk's cache key holds them (both hold import_readers' roots, homes and config dirs, so HOME, IMPORT_READER_*, CLAUDE_CONFIG_DIR and IMPORT_MANAGED_DIR need no reset; the worktree registry is read again after a reset or when one of those changes ...)"

**Location:** `scripts/lib/dev-cycle-read.sh:70-76`
**Type:** Invariant / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** a gate caller (contract reader)
**Scope:** Covers the two walk keys and import_readers' key. It does not establish IMPORT_OUT_MAX or IMPORT_WORK_MAX handling, which is unchanged and still needs a reset.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2+r3: IMPORT_OUT_MAX and IMPORT_WORK_MAX are not established as outside every key (unchanged, still a reset duty; r2: "they are absent from the three keys read"). · r2: the config-dir test "fails on main's lib (E1, `old-main.txt` test 3)". · r3: "Probe P7 changed IMPORT_MANAGED_DIR after a tree walk, and IMPORT_CONFIGS then ended with the new directory."

Evidence carried from r1 (three-way Verified tie; lowest replicate). The key at `:1146-1147` is `local f="${CLAUDE_CONFIG_DIR+x}${CLAUDE_CONFIG_DIR-}" g="$IMPORT_MANAGED_DIR"` followed by `IMPORT_READERS_KEY="... ${#f}:$f ${#g}:$g"`. HOME enters through `IMPORT_HOME_DONE` (`b`), and both reader lists through `c` and `d`. Both walk keys append `"$IMPORT_CONFIGS"` (`:1629`, `:1704`). Bats test "both walks key on the config dirs ..." passes. It sets CLAUDE_CONFIG_DIR after a walk, with no import_reset, and both walks then answer `set: imported` (fcf1-bats.log).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1141-1160`, `scripts/lib/dev-cycle-read.sh:1629`, `scripts/lib/dev-cycle-read.sh:1704`, `fcf1-bats.log`

---

## Claim 6: Contract item 8: "Pass truthrule, truthwalk, ... a lower-cased path (...; floor lowers first unless its caller passes the lowered path, ...; truthrule refuses an upper-case letter as case, truthwalk as imported)"

**Location:** `scripts/lib/dev-cycle-read.sh:91-96`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** a gate caller (contract reader)
**Scope:** Covers truthwalk's and floor's case handling. It does not establish truthwalk's behavior when its walk fails, where it answers `walk` before any case test.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "It does not establish prompt_dir's or prompt_bases' callers, which this diff does not touch." (r2 also covers check_fix's lower at `scripts/dev-cycle.sh:180` and floor's ownfile argument, `:1940-1941`.) · r3: "It does not establish whether a future caller of truthwalk runs truthrule first; the two current callers do."

Evidence carried from r1 (three-way Verified tie; lowest replicate). truthwalk at `:1885`: `[[ "$2" != *[ABCDEFGHIJKLMNOPQRSTUVWXYZ]* ]] && ! walk_has "$1" "$2" || return 0`, with `TRUTH_WHY=imported` set at `:1884`. In P4, `truthwalk main Docs/Q.md` printed `upper: 0 imported` and the lower-case miss printed `lower: 1 []` (fcf1-probe.log). For floor's half, see Claim 30.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1881-1887`, `fcf1-probe.log` (P4)

---

## Claim 7: Contract item 9 adds IMPORT_CONFIGS to "Never set these yourself ...: they are import_readers' results, which a cache hit does not recompute"

**Location:** `scripts/lib/dev-cycle-read.sh:101-104`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** a gate caller (contract reader)
**Scope:** Covers who assigns IMPORT_CONFIGS. It does not establish that no caller sets it, though no script under scripts/ does.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r1+r2: only `scripts/` was grepped for writers. · r3: "It does not establish the other four variables beyond their unchanged code."

Evidence carried from r1 (Verified tie; lowest replicate). IMPORT_CONFIGS is assigned only at `:1132` (sourcing), `:1156` (cleared on a memo miss) and `:1198-1199` (built). A memo hit returns at `:1155` before any of those (paraphrased — no quote available because the claim covers absence of other assignments; grep over scripts/ found only these lines).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1132`, `scripts/lib/dev-cycle-read.sh:1155-1156`, `scripts/lib/dev-cycle-read.sh:1198-1199`

---

## Claim 8: Walk docs: the tree walk's result is "keyed on import_readers' roots (ROOT_REAL first), homes and config dirs (IMPORT_CONFIGS)", and the main walk's is cached "for the commit, MAIN_BY_NAME and import_readers' roots, homes and config dirs"

**Location:** `scripts/lib/dev-cycle-read.sh:697-700`, `scripts/lib/dev-cycle-read.sh:730-734`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** lib maintainer
**Scope:** Covers the two cache keys. It does not establish the checkout's exclusion from the key, which is unchanged and documented as the caller's import_reset duty.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r3: "does not establish that every input a walk reads is in a key (IMPORT_*_MAX are deliberately out; contract item 4)."

Evidence carried from r1 (Verified tie; lowest replicate). `:1631`: `IMPORTED_DONE="$IMPORT_ROOTS"$'\n\n'"$IMPORT_HOMES"$'\n\n'"$IMPORT_CONFIGS"`. `:1707`: `IMPORTED_MAIN_DONE="$MAIN_SHA $MAIN_BY_NAME $IMPORT_ROOTS"$'\n\n'"$IMPORT_HOMES"$'\n\n'"$IMPORT_CONFIGS"`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1629-1631`, `scripts/lib/dev-cycle-read.sh:1704-1707`

---

## Claim 9: "a prompt's projected names, a live link's too (U2b3b2c final security F3), are read as prompts with the link's bases", and F3 (probe PC) is covered for both walks

**Location:** `scripts/lib/dev-cycle-read.sh:762-764`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** security reviewer / lib maintainer
**Scope:** Covers a live prompt link whose real path lies below a reader root, in both walks. It does not establish a live link out of every root, which is read plain by design (Claim 19).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2+r3: a live link whose target lies outside every root is left unmarked by design (r3: "its projection holds no repo name"). · r2+r3: the security review's PC result was `top.md: -` for both walks (`docs/reviews/security-review-2026-10-09-u2b3b2c-final.md:141`); r2: the test fails on main's lib (E1, `old-main.txt` test 1).

Evidence carried from r1 (three-way Verified tie; lowest replicate). Both walks now call prompt_marks for any absolute prompt entry. The condition is `[[ "$f" != /* || -z "${pdir[$f]+set}" ]] || prompt_marks ...` at `:1663` and `:1800`. Probe 2 rebuilt PC (main's `docs/t.md` = `t: @top.md`, side's older copy plus a live `.claude/commands/k.md -> ../../docs/t.md`). With main's lib both walks print `top.md: -`. With HEAD's lib both print `top.md: imported` (fcf1-probe2.log). The bats test at `test/scripts/build-loop-check.bats:590` loops `for w in tree main` and passes.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1663`, `scripts/lib/dev-cycle-read.sh:1800`, `test/scripts/build-loop-check.bats:590-599`, `fcf1-probe2.log`

---

## Claim 10: IMPORTED_MAIN_WHY: the KIND list and "Each stage sets its KIND before it runs, so a failure a stage adds reports that stage (one with its own KIND sets it where it fails)"; each `return 1` of main_imports reports the right KIND

**Location:** `scripts/lib/dev-cycle-read.sh:792-802`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** lib maintainer / walk_why's caller
**Scope:** Covers every `return 1` in main_imports (:1698-1828, read whole). It does not establish that the stage KIND names the failing helper within a stage. outside_proj and prompt_marks failures in the read loop report `read PATH`, by the stated inherit rule.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2: does not establish that the sentence walk_why prints for each KIND names every cause in that stage (see Claims 13-15). · r2: "The `readers` failure also empties IMPORTED_MAIN_DONE, while every later failure leaves the walk key cached with its KIND." · r2: in E1 the floor test's KIND cases pass (start, readers, seeds, read, link, `?`, main).

Evidence carried from r3 (three-way Verified tie; r3's scope names the concrete helpers, the most specific). The KIND each `return 1` reports:
- `IMPORTED_MAIN_WHY=readers` on import_readers failure (`:1703`).
- `=main` before main_by_name (`:1708`).
- `=tree` before ls-tree, record parse, duplicate names, directory clash and the links' lower_all (`:1709-1726`).
- `="link ${links[i]}"` at the START_LINK test (`:1728`).
- `=list` before checkout_md, the newline test and the cand lower_all (`:1730-1734`).
- `="start $f"` (`:1739`).
- `=seeds` before outside_seeds and the seeds' lower (`:1745-1750`).
- `=copies` before the first root_copies (`:1755`) and at the loop's root_copies (`:1824`).
- `="read $f"` before every read arm (`:1765`).
- `="admit $p"` at both main_checkout refusals (`:1808`, `:1820`).
- `=budget` (`:1811`).

Probe P5 set IMPORT_OUT_MAX=3 and got `WHY=[read AGENTS.md]`: the parser trips first, as `:798` says. The bats floor test at :633-675 checks the start, readers, seeds, read, link, main and `?` wordings.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1698-1828`, `fcf3-logs/probe1.log`, `fcf3-logs/bats-build-loop-check.log`

---

## Claim 11: "It is empty after a walk that succeeds and kept with a cached failure."

**Location:** `scripts/lib/dev-cycle-read.sh:799-800`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** floor's maintainer
**Scope:** Covers main_imports' own writes. It does not establish protection against a caller assigning the global, which nothing prevents.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r2+r3: a `readers` failure clears IMPORTED_MAIN_DONE, so it is re-run rather than cached and sets `readers` again (r3 scope: "It does not establish a readers failure").

Evidence carried from r1 (Verified tie; lowest replicate). `:1827` sets `IMPORTED_MAIN_WHY=""` as the function's last line. A cache hit returns at `:1704` without touching it. In P7 a failed walk gave `1: start CLAUDE.md`, and the cached second call gave `2: start CLAUDE.md`. When the probe overwrote the global, the cached call kept the overwrite (`3: xx`), which confirms that only main_imports writes it (fcf1-probe.log).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1704`, `scripts/lib/dev-cycle-read.sh:1827`, `fcf1-probe.log` (P7)

---

## Claim 12: walk_why: "A PATH shows only when every character is one pathform allows (check_line's rule for repo text, so a crafted name prints as ?), a // entry as its absolute path"; an unknown KIND is worded

**Location:** `scripts/lib/dev-cycle-read.sh:804-811`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** operator reading a floor refusal / security critic
**Scope:** Covers the character filter, the `//` strip and the generic arm. It does not establish pathform's other rules (a leading `/`, `..`, `.git`), which walk_why does not apply: absolute host paths with clean characters print, as settled in B6.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2+r3: pathform's structural rules (no leading `/`, no `..`, no `.git`) are not applied by walk_why; r2+r3: absolute host paths whose characters pass are shown (rubric B6, settled). · r1+r3: check_line uses the same test at `scripts/build-loop.sh:842` (`[[ ! "$p" =~ ^[$NAMECHARS]+$ ]] || shown="$p"`).

Evidence carried from r2 (three-way Verified tie; r2's scope is the most specific).

```bash
# scripts/lib/dev-cycle-read.sh:809-811
  local k="${1%% *}" d=""
  [[ "$1" != *" "* ]] || d="${1#* }"; [[ "$d" != //* ]] || d="${d#/}"
  [[ -z "$d" || "$d" =~ ^[$NAMECHARS]+$ ]] || d="?"
```
P2 (E3) gives these results: `read //home/u/x.md` → `/home/u/x.md could not be read...`, `admit a b.md` → `the checkout holds ?...`, `read docs/$(x).md` → `? could not be read...`, `weird` → `the walk failed (weird)`, and the empty word → `the walk failed (no reason recorded)`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:804-826`, `fcf2-probe.out` (P2)

---

## Claim 13: IMPORTED_MAIN_WHY "list (the checkout's .md list)" and walk_why's list sentence "the checkout's .md files could not be listed or lower-cased, or one's name holds a newline"

**Location:** `scripts/lib/dev-cycle-read.sh:794-795`, `scripts/lib/dev-cycle-read.sh:818`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** operator reading a floor refusal
**Scope:** Covers the list stage's three returns. It does not establish the cost of the imprecision, which needs a failing `tr` and is cosmetic.
**Replicate verdicts:** r1=— · r2=Mostly accurate · r3=Mostly accurate (compound)
**Replicate annotations:** r2+r3: the list stage's lower_all over `cand` also lower-cases main's `m:` names (`:1716`, `:1733`), so the sentence is narrower than the stage. · r2 also verdicted all walk_why sentences as one compound (its claim 12, Verified, Medium) alongside this split row. · r2 (escalation note): "The list KIND's sentence names only the checkout's names" — to api-consistency-reviewer.

Evidence carried from r2 (the split Mostly-accurate verdict). The lower_all in the list stage lower-cases `cand`, which holds main's own `.md` names (`cand+=("m:$f")`, `:1716`) as well as the checkout-only ones (`cand+=("t:$f")`, `:1732`). So "the checkout's .md files could not be ... lower-cased" also covers main's tree names: `[[ ${#cand[@]} -eq 0 ]] || nul_list low lower_all "${cand[@]}" || return 1` (`:1733`). A precise version: "the checkout's .md files could not be listed, or main's and the checkout's .md names lower-cased, or one's name holds a newline".

**Evidence:** `scripts/lib/dev-cycle-read.sh:1716`, `scripts/lib/dev-cycle-read.sh:1730-1734`, `scripts/lib/dev-cycle-read.sh:818`

---

## Claim 14: walk_why "start|admit": "the checkout holds $d, which the walk reads, as other than a readable plain file below plain directories"

**Location:** `scripts/lib/dev-cycle-read.sh:819`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** operator reading a `--check` deny row
**Scope:** Covers the sentence against main_checkout's return-1 cases. It does not establish the other KIND sentences, which are Verified under Claims 1 and 12.
**Replicate verdicts:** r1=Mostly accurate · r2=Verified (compound) · r3=Mostly accurate (compound)
**Replicate annotations:** r2 (dissenting scope): "Under contract item 2, start/admit's 'the checkout holds PATH ... as other than a readable plain file below plain directories' also covers main_checkout's refusal of an ancestor main stores as a link (`:1609`). It does not establish the wording for main_checkout's internal refusal when ENT or MEMO is not an associative array (`:1601`), which no walk input can trigger." · r3 (dissenting on this part of its compound): "start/admit (main_checkout's refusals, including an ancestor main stores as a link, which a contract-clean checkout holds as one) ... match their returns." · r2: in E1 the floor test's start case for an unsearchable directory passes.

Evidence carried from r1 (the only split verdict; most severe). main_checkout returns 1 in three cases the sentence does not quite name. The first is an ancestor main stores as a link or gitlink (`:1609`: `[[ ! "${mc_e[$c]:-}" =~ ^1[26]0000$ ]] || return 1`), a property of main's tree rather than of what the checkout holds. The second is a plain directory that is not searchable (`:1612`: `elif ! plaindir "$c" || [[ ! -x "$c" ]]; then return 1`), which is a "plain directory" yet fails. The third is the internal ENT/MEMO type check (`:1601`). The bats case `chmod 644 docs` (`test/scripts/build-loop-check.bats:640-641`) reports this sentence for a non-searchable directory. A tighter wording would be "... below plain searchable directories, none stored on the default branch as a link or gitlink".

**Evidence:** `scripts/lib/dev-cycle-read.sh:1595-1622`, `scripts/lib/dev-cycle-read.sh:819`, `test/scripts/build-loop-check.bats:640-641`

---

## Claim 15: walk_why's remaining sentences match their failures (readers, main, tree, link, seeds, copies, read, budget)

**Location:** `scripts/lib/dev-cycle-read.sh:812-825`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** operator reading a deny row
**Scope:** Covers each sentence against the returns under its KIND; does not establish wording for KINDs never set (the `*` arm, worded generically: P3 `weird`).
**Replicate verdicts:** r1=— · r2=Verified (compound) · r3=Mostly accurate (compound)
**Replicate annotations:** r2 (evidence for its Verified compound): readers covers import_readers' refusals (`:1159-1184`) with IMPORT_READER_WHY's own sentence (`:813`); link matches `START_LINK` (`:665`); seeds covers config_seeds, c1_seeds, the newline check and the seed lower (`:1443-1447`, `:1750`); read covers the three arms plus outside_proj and prompt_marks (`:1766-1800`); budget is the bash-side `used` overrun (`:1811`). · r1 did not verdict these sentences; its claim 12 scope calls the other KIND sentences "Verified under Claims 1 and 13" (r1's ? rule and help claims).

Evidence carried from r3 (the most severe verdict on this part of the compound; r3's `list` finding is carried in Claim 13). Most sentences match. One narrower than what its KIND covers here:
- **copies:** the sentence says "another worktree's copy of an imported name" (`:821`). The first root_copies, however, runs over the starts: `root_copies cq cmp pdir "${queue[@]}" "${tq[@]}"` (`:1756`).

It is an imprecision, not a wrong mechanism. readers, main, link, seeds, read and budget match their returns.

**Evidence:** `scripts/lib/dev-cycle-read.sh:812-825`, `scripts/lib/dev-cycle-read.sh:1714-1734`, `scripts/lib/dev-cycle-read.sh:1755-1756`

---

## Claim 16: readers_root: "need_root, unless ROOT_REAL is set and import_readers' memo already holds a result for its key (a hit reads nothing; a memoized refusal checks the root too), so a walk never lists the registry from an unchecked directory; each walk calls it first and need_root again below its own cache check, so a call both caches answer forks no root check"

**Location:** `scripts/lib/dev-cycle-read.sh:827-833`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** lib maintainer
**Scope:** Covers both walks' entry. It does not establish import_targets' own import_readers call (`:878`), which runs inside a walk after the check, or the `realpath -m` import_home forks before need_root when HOME changes. That fork resolves an absolute HOME and lists no registry.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "It does not establish that a held result from a wrong cwd is safe when the walk cache misses: need_root below the cache check then exits, which is correct but was not probed separately." · r3: "It does not establish need_root's own checks, which are unchanged." · r2+r3: import_readers' own memo returns before `git worktree list` (`:1155`, `:1161`), so no listing runs from an unchecked directory.

Evidence carried from r1 (three-way Verified tie; r1's scope is the most concrete). The code is `{ [[ -n "${ROOT_REAL:-}" ]] && import_home && import_readers_key && [[ "$IMPORT_READERS_DONE" == "$IMPORT_READERS_KEY" && -n "$IMPORT_ROOTS" ]]; } || need_root`. A refusal is memoized with an empty IMPORT_ROOTS (`:1156` sets DONE first and clears the roots, then returns 1). In P3, a `CLAUDE_CONFIG_DIR=rel` refusal reported `refused: readers`, and after `cd /` the next main_imports exited with "ROOT_REAL is not the current directory" (fcf1-probe.log). Both walks call readers_root first (`:1626`, `:1702`) and need_root below the cache check (`:1630`, `:1706`). Probe 4 counted 0 forks per 100 cached floor calls.

**Evidence:** `scripts/lib/dev-cycle-read.sh:827-833`, `scripts/lib/dev-cycle-read.sh:1149-1160`, `scripts/lib/dev-cycle-read.sh:1623-1631`, `scripts/lib/dev-cycle-read.sh:1698-1707`, `fcf1-probe.log` (P3), `fcf1-probe4.log`

---

## Claim 17: import_readers memo: "keyed on ROOT_REAL, HOME, the caller's two lists, IMPORT_READER_WHY and the two config dirs"

**Location:** `scripts/lib/dev-cycle-read.sh:1116-1121`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** maintainer
**Scope:** Covers import_readers_key's seven parts. It does not establish that an import_home failure is memoized; the doc says it is not, and the code returns before the key (`:1151`).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=—
**Replicate annotations:** none

Evidence carried from r2 (the split verdict). `local a="${ROOT_REAL:-}" b="$IMPORT_HOME_DONE" c="$IMPORT_READER_ROOTS" d="$IMPORT_READER_HOMES" e="$IMPORT_READER_WHY"` and `local f="${CLAUDE_CONFIG_DIR+x}${CLAUDE_CONFIG_DIR-}" g="$IMPORT_MANAGED_DIR"` (`:1145-1146`). `IMPORT_HOME_DONE` is HOME's key (`:1088`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1088`, `scripts/lib/dev-cycle-read.sh:1144-1156`

---

## Claim 18: IMPORT_CONFIGS doc: "outside_seeds' config dirs, newline-separated: each absolute home's .claude, then CLAUDE_CONFIG_DIR when set and IMPORT_MANAGED_DIR; the key holds both, so the walks ... see a change without import_reset (override row 581). A CLAUDE_CONFIG_DIR that is not absolute or holds a newline returns 1."

**Location:** `scripts/lib/dev-cycle-read.sh:1124-1129`
**Type:** Configuration / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** caller of the lib
**Scope:** Covers the contents, order, key and refusal of IMPORT_CONFIGS. It does not establish Claude Code's own treatment of an empty CLAUDE_CONFIG_DIR.
**Replicate verdicts:** r1=Verified (compound) · r2=Mostly accurate · r3=Verified
**Replicate annotations:** r1+r3 (same substance as r2's finding, recorded under Verified): r1: "a set-but-empty CLAUDE_CONFIG_DIR is neither refused nor listed (`${CLAUDE_CONFIG_DIR:+...}`), as on main"; r3: "'When set' means set and non-empty: `${CLAUDE_CONFIG_DIR:+...}` treats empty as unset, as the old outside_seeds did." · r3: "The refusal is memoized like any import_readers refusal." · r1: P6 order `$HOME/.claude`, `/host/home/.claude`, `/cfg`, `/m`; set-empty and unset both dropped `/cfg`. · r2 (escalation note): the memo key's `${CLAUDE_CONFIG_DIR+x}` distinguishes set-empty from unset while IMPORT_CONFIGS does not — to api-consistency-reviewer.

Evidence carried from r2 (the most severe verdict). `for p in "${rs_h[@]}"; do [[ "$p" != /* ]] || IMPORT_CONFIGS+="${p%/}/.claude"$'\n'; done` and then `IMPORT_CONFIGS+="${CLAUDE_CONFIG_DIR:+$CLAUDE_CONFIG_DIR$'\n'}$IMPORT_MANAGED_DIR"` (`:1198-1199`). The `:+` takes CLAUDE_CONFIG_DIR only when it is set and non-empty, but the key's `${CLAUDE_CONFIG_DIR+x}` distinguishes set-empty from unset. In P3 (E3), `empty:` gave the same list as `unset:` (`<home>/.claude|/m`), `abs:` gave `<home>/.claude|/cfg|/m`, `rel:` was refused with `roots=[]`, and a relative HOME gave `/cfg|/m`. The refusal is `[[ -z "${CLAUDE_CONFIG_DIR:-}" || ( "$CLAUDE_CONFIG_DIR" == /* && "$CLAUDE_CONFIG_DIR" != *$'\n'* ) ]] || return 1` (`:1160`), and the newline case is tested (E1). A precise version: "CLAUDE_CONFIG_DIR when set and non-empty". The order matches main's former `cf` construction in outside_seeds, which also tested `-z`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1124-1129`, `scripts/lib/dev-cycle-read.sh:1160`, `scripts/lib/dev-cycle-read.sh:1192-1199`, `fcf2-probe.out` (P3)

---

## Claim 19: prompt_marks doc: "F is an absolute queue entry ...: a // one (a dangling prompt link), or a live one, when its real path differs and lies below a reader root (...); any other returns 0 unmarked"

**Location:** `scripts/lib/dev-cycle-read.sh:1373-1381`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer / security and performance critics
**Scope:** Covers the `//` arm, the same-path return, and the below-a-root test, which now uses a flag set inside the loop. It does not establish the cost of the extra realpath per live entry (override row, i1 performance 5).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r1: "It does not establish whether a live link whose real path equals a reader root itself (not below it) should be marked. The test is strict `"$p"/*`." · r3: "It does not establish how much the target's own names are over-read; the doc calls that over-read accepted." · r1+r3: with ac078bd7's lib the out-of-root link is marked too (r1 P8, r3 P6).

Evidence carried from r2 (the split verdict).

```bash
# scripts/lib/dev-cycle-read.sh:1392-1396
  if [[ "$l" == //* ]]; then l="${l#/}"; lp="${lp#/}"
  else
    b="$(realpath -e -- "$l")" || return 1; [[ "$b" != "$l" ]] || return 0
    while IFS= read -r p; do [[ "$b" != "$p"/* ]] || in=1; done <<<"$IMPORT_ROOTS"; [[ -n "$in" ]] || return 0
  fi
```
The test "prompt_marks marks a live prompt link's names only when its real path lies below a reader root" prints `out.md: none` and `in.md: docs/a.md`. It passes at HEAD and fails on ac078bd7's and main's libs (E1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1373-1405`, `test/scripts/build-loop-check.bats:601-607`, `fcf2-logs/old-ac078bd7.txt`, `fcf2-logs/old-main.txt`

---

## Claim 20: prompt_marks: "It returns 1 when lower or realpath fails."

**Location:** `scripts/lib/dev-cycle-read.sh:1389`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** maintainer
**Scope:** Covers prompt_marks' two failing commands and how the walks receive them. It does not establish any probe of a vanished target.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** none

Evidence carried from r2 (the split verdict). Its failures are `b="$(realpath -e -- "$l")" || return 1` (`:1394`) and `pm_p[$p]="$(lower "$p")" || return 1` (`:1402`); there are no other `return 1`s. Both walks fail on it: `... || { IMPORTED=error; return 1; }` (`:1663`, `:1800`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1390-1405`, `scripts/lib/dev-cycle-read.sh:1663`, `scripts/lib/dev-cycle-read.sh:1800`

---

## Claim 21: outside_seeds doc: "Items (1) and (2) are config_seeds', (3) is c1_seeds' ..., and each keeps its own keep-rule. It returns 1 when either does, or a seed's path holds a newline. Run it after import_readers (IMPORT_ROOTS, IMPORT_CONFIGS and IMPORT_OTHER). NAME must not be one of the three functions' locals"

**Location:** `scripts/lib/dev-cycle-read.sh:1438-1447`
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** a future third caller of outside_seeds
**Scope:** Covers the split, the return conditions, the globals read and the newline check. It does not establish item (1)'s older text about "a dangling link kept", which this diff did not change.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2+r3: seed-set equality before and after the split is not established beyond this machine; both libs' main walks give 1593 unique names here (r2 E4, r3 P8: "indirect evidence only").

Evidence carried from r1 (three-way Verified tie; lowest replicate). `:1443-1447`: `local -n ow_a="$1"; local ow_d`, then `config_seeds "$1" || return 1; c1_seeds "$1" || return 1`, then `for ow_d in "${ow_a[@]}"; do [[ "$ow_d" != *$'\n'* ]] || return 1; done`. config_seeds reads `IMPORT_ROOTS` and `IMPORT_CONFIGS` (`:1453`). c1_seeds reads `IMPORT_OTHER` and `ROOT_REAL` (`:1509-1515`). Each has its own keep-rule: config_seeds at `:1498-1501` (an @, or a real path that differs and lies below a root), c1_seeds at `:1526-1531` (an @ or a link, minus the rawfile skip). Both walks pass `sd`, which is not a local of any of the three.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1443-1533`, `scripts/lib/dev-cycle-read.sh:1643`, `scripts/lib/dev-cycle-read.sh:1746`

---

## Claim 22: "config_seeds NAME: array NAME gets outside_seeds' items (1) and (2). It returns 1 when a find, grep, realpath or lower_all fails."

**Location:** `scripts/lib/dev-cycle-read.sh:1448-1449`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** lib maintainer
**Scope:** Covers every `return 1` in config_seeds. It does not establish a python3 failure on installed_plugins.json, which falls back to the cache dir (`:1474`) rather than failing, as on main.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r1+r2+r3: a python3 failure is not a failure; it falls back to the plugin cache (`:1467-1474`). · r2: "It does not establish xargs batching limits."

Evidence carried from r1 (Verified tie; lowest replicate). The function clears the array (`os_a=()` at `:1452`). Its returns are at the find lists (`:1477`, `:1478`, `:1480`, `:1487`), lower_all (`:1488`), with_at's grep (`:1494`) and the xargs realpath (`:1497`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1450-1503`

---

## Claim 23: IMPORT_CONFIGS as outside_seeds reads it gives main's config dirs (3111ee9d: "outside_seeds reads it"; the walks unchanged in result)

**Location:** `scripts/lib/dev-cycle-read.sh:1453`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** reviewer of the refactor
**Scope:** Covers equivalence for this repository and the static mapping. It does not establish equivalence under a HOME holding a newline, where both read it as empty.
**Replicate verdicts:** r1=Verified · r2=— · r3=— · single-replicate detection
**Replicate annotations:** related (other clusters): r2 (its claim 15) and r3 (its claim 15) each note that IMPORT_CONFIGS' order matches main's former `cf` construction in outside_seeds.

Evidence carried from r1 (sole replicate). Main built `cf` from `mapfile -t fl <<<"$IMPORT_HOMES"` and `for d in "${fl[@]}"; do [[ "$d" != /* ]] || cf+=("${d%/}/.claude"); done; [[ -z "${CLAUDE_CONFIG_DIR:-}" ]] || cf+=("$CLAUDE_CONFIG_DIR"); cf+=("$IMPORT_MANAGED_DIR")`. HEAD iterates the same `rs_h` array that `IMPORT_HOMES` is printed from (`:1197-1199`). Probe 3 ran both walks over the review worktree, with CLAUDE_CONFIG_DIR set, under main's lib and HEAD's lib. Each gave 1593 names, and the lists were byte-equal across libs and across walks (fcf1-probe3.log).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1196-1199`, `scripts/lib/dev-cycle-read.sh:1450-1453`, `fcf1-probe3.log`

---

## Claim 24: "c1_seeds NAME: appends outside_seeds' item (3), C1, to array NAME: each other root's start files (IMPORT_OTHER) that hold an @ byte or are links, but the ones its skip names. It returns 1 when a find, grep or lower_all fails."

**Location:** `scripts/lib/dev-cycle-read.sh:1504-1506`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** lib maintainer
**Scope:** Covers append semantics, the keep-rule and the returns. It does not establish the skip's correctness, which is unchanged code moved from outside_seeds.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r3: "does not establish the C1 skip's soundness outside contract item 2 (security review endorsement, out of this claim)." · r2: "c1_seeds' rawfile is a test inside the skip, not a failure (`:1531`)."

Evidence carried from r1 (Verified tie; lowest replicate). There is no clear (`local -n c1_a="$1"` at `:1508`, no `c1_a=()`), and the keep at `:1531` is `c1_a+=(...)`, so it appends. The keep-rule is at `:1526`: `isstart "${lo[i]}" && [[ -n "${c1_at[${cx[i]}]+set}" || -L "${cx[i]}" ]] || continue`. Its returns are root_starts (find|grep, `:1514`), lower_all (`:1522`) and with_at (`:1523`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1507-1533`

---

## Claim 25: main_imports comment: "Below the cache check: a hit reads nothing here, so floor's cached calls fork no root check" / "need_root  # below the cache check, as in main_imports"

**Location:** `scripts/lib/dev-cycle-read.sh:1705-1706`, `scripts/lib/dev-cycle-read.sh:1630`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** performance reviewer
**Scope:** Covers the cached path of both walks. It does not establish a memo miss, for example a HOME change, which forks need_root and the registry listing.
**Replicate verdicts:** r1=— · r2=Verified · r3=Verified
**Replicate annotations:** r2: "It does not establish behavior on a memo miss (Claim 13 covers that)" (r2's readers_root claim; Claim 16 here).

Evidence carried from r3 (Verified tie; r3's scope names the concrete miss case). The cache check returns at `:1704` (main) and `:1629` (tree) before need_root. Bats :685 (`[ ! -e "$BATS_TEST_TMPDIR/calls" ]` with `pwd` and `tr` shimmed and `enable -n pwd`) passes. Probe P9 measured a cached floor with `$4` at 679 µs per path, against 6579 µs under main's lib.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1623-1631`, `scripts/lib/dev-cycle-read.sh:1698-1707`, `fcf3-logs/probe3.log`, `fcf3-logs/bats-build-loop-check.log`

---

## Claim 26: isimported doc and code: "A failed walk, a failed lower of $2, or a walk name that is neither answers imported (0)"; it lowers $2 and asks walk_has

**Location:** `scripts/lib/dev-cycle-read.sh:1829-1840`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** caller of the lib
**Scope:** Covers isimported's three 0-arms and its case handling. It does not establish callers outside `scripts/` and the bats tests.
**Replicate verdicts:** r1=— · r2=Verified · r3=— · single-replicate detection
**Replicate annotations:** related (other cluster): r1 (its claim 4 scope) notes isimported "keeps its own `need_root` at `:1836`".

Evidence carried from r2 (sole replicate). `need_root; lp="$(lower "$2")" || return 0; case "$1" in main) main_imports || return 0 ;; tree) imported_names || return 0 ;; *) return 0 ;; esac; walk_has "$1" "$lp"` (`:1836-1839`). walk_has is reached only after its walk returned 0.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1834-1840`

---

## Claim 27: walk_has: "whether the list of the walk WALK names ..., as its last call left it, holds LP, a lower-cased path: no fork. Ask it only after that walk succeeded (contract item 6: an error list holds nothing)", and every caller complies

**Location:** `scripts/lib/dev-cycle-read.sh:1841-1847`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** lib maintainer adding a walk_has caller
**Scope:** Covers all three callers. It does not establish that contract item 6's caller-facing rule ("only through isimported or truthwalk") lists floor's internal use. Floor is lib code, not a caller.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "It does not establish the glob's cost on a large list (override row, A10)." · r3: "It does not establish case folding: there is none, and the callers lower first." · r1 (escalation note): whether contract item 6 should name walk_has as the lib's own reader — to api-consistency-reviewer.

Evidence carried from r1 (three-way Verified tie; lowest replicate). The body is a nameref and one `[[ == ]]`, with no `$(...)` and no external command. Each caller asks only after a successful walk. isimported runs `main_imports || return 0` first (`:1838`). truthwalk runs `main_imports || return 0` first (`:1883`). floor's loop is in the `else` of `elif truthwalk main "$lp"`, reached only when truthwalk returned 1, which follows a successful walk (`:1942-1948`). Every caller passes a lowered path: isimported's `lp` (`:1837`), truthwalk's upper-case guard (`:1885`), and floor's `d`, cut from the lowered `lp`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1834-1847`, `scripts/lib/dev-cycle-read.sh:1881-1887`, `scripts/lib/dev-cycle-read.sh:1942-1951`

---

## Claim 28: truthwalk "asks it about PATH, lower-cased (contract item 8), through walk_has as isimported does, but with no lower ...; Returns 0 when the walk fails (TRUTH_WHY=walk) or reaches PATH or PATH holds an upper-case letter (TRUTH_WHY=imported; both callers run truthrule's case word first), else 1 with TRUTH_WHY empty; an unknown WALK answers walk without running one. For tree or main it exits through need_root when it walks."

**Location:** `scripts/lib/dev-cycle-read.sh:1872-1880`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** lib maintainer; callers floor and check_fix
**Scope:** Covers return codes, TRUTH_WHY and both callers' ordering. The "~1 ms" figure is Claim 29.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2+r3: the "~1 ms a path" parenthetical is excluded from this verdict (Claim 29). · r2+r3: check_fix's `[[ -n "$TRUTH_WHY" ...` arm skips any truthrule word, `case` included, before `truthwalk tree` (`scripts/dev-cycle.sh:181-185`).

Evidence carried from r1 (three-way Verified tie; r1 is the only executed one). The code is at `:1882-1886`. In P4: `upper: 0 imported`, `lower: 1 []`, `a: 0 imported`, `bogus: 0 walk` (fcf1-probe.log). Both callers run truthrule first. floor does at `:1929` (`if truthrule "$lp"`, with the case word at `:1935`). check_fix does at `scripts/dev-cycle.sh:181`, on a path lowered at `:180`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1881-1887`, `scripts/lib/dev-cycle-read.sh:1929-1942`, `scripts/dev-cycle.sh:176-189`, `fcf1-probe.log` (P4)

---

## Claim 29: "(isimported's lower and root check cost floor ~1 ms a path: U2c1 final performance 1)"

**Location:** `scripts/lib/dev-cycle-read.sh:1874-1875`
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** performance reviewer
**Scope:** Covers the magnitude of `need_root` plus `lower` per call on this host. It does not establish the cited report's own figure under its own load.
**Replicate verdicts:** r1=Mostly accurate · r2=Unverifiable · r3=—
**Replicate annotations:** r2: "E4 timed 400 cached floor calls (with `$4`) at 15.0 ms per call with main's lib and 1.05 ms per call with HEAD's, under load average 1.73. main's floor also forks its own lower and need_root, so the ~1 ms attributed to isimported's two forks cannot be separated from these totals. Verifying it needs a per-fork microbenchmark on an idle machine." · r3 (its truthwalk claim's scope): the figure "was not re-measured on its own"; its claim 20 measures the combined saving (6579 → 679 µs).

Evidence carried from r1 (the most severe verdict). Probe 2 timed 200 calls of `need_root; x="$(lower docs/x.md)"` at 2.17 ms per call (fcf1-probe2.log). The cited report puts need_root at 2.17 ms per four calls, about 0.54 ms each, and two lowers at most of 5.7 ms (`docs/reviews/performance-review-2026-10-10-u2c1-final.md:40,55`). Both put isimported's pair nearer 2-3 ms than 1 ms. The mechanism (a fork and a root check per path) is right, but "~1 ms" understates it by about 2x here, and the figure depends on load.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1834-1840`, `docs/reviews/performance-review-2026-10-10-u2c1-final.md:40-57`, `fcf1-probe2.log`

---

## Claim 30: floor doc: "$4, optional, $1 lower-cased (build-loop.sh passes it, so floor forks no lower ...; floor then reads only $4, so the two must agree; an upper-case letter in it refuses as case)"

**Location:** `scripts/lib/dev-cycle-read.sh:1908-1911`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** a floor caller
**Scope:** Covers $4's use and the case refusal. It does not establish behavior when $4 is a different path from $1. Floor then judges $4 alone, as the doc warns.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2+r3: behavior when `$4` is passed empty is not in the doc — floor then lowers `$1`, the same as when `$4` is omitted (r2: "a fallback the doc does not mention but that matches 'optional'"). · r2: the `tr` shim records no call for `floor docs/b.md x M docs/b.md` (E1).

Evidence carried from r1 (three-way Verified tie; lowest replicate). After `:1926-1928`, `$1` is not read again: every later test uses `$lp`. The upper-case case reaches truthrule's `case` word, which floor words "the path could not be lower-cased" (`:1935`). The bats test "floor given the lowered path ..." passes, including `C: the path could not be lower-cased` for `Docs/C.md` passed as $4 (fcf1-bats.log).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1925-1952`, `test/scripts/build-loop-check.bats:685-694`, `fcf1-bats.log`

---

## Claim 31: floor doc: "a path below a start file's name or an imported .md name is refused too (a directory there keeps the file from being created ...)"; inline: "not any import's: the parser's prefixes make every directory an import passes through one"

**Location:** `scripts/lib/dev-cycle-read.sh:1914-1916`, `scripts/lib/dev-cycle-read.sh:1946`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** security reviewer / floor maintainer
**Scope:** Covers the loop over every ancestor, the .md restriction and the prefix rationale. It does not establish a path below a non-.md import name (`@docs/notes`), which a settled override row of 2026-10-10 leaves out.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2+r3: a path below an imported non-`.md` name is not refused, by settled override row (2026-10-10). · r2: "A brief's own files can lie only directly in `docs/working/` or `docs/reviews/`, whose names are not `.md` names, so no exception lets a path below such a name through." · r2+r3: the bats test refuses `src/CLAUDE.md/n.txt`, `docs/Agents.local.md/a/b`, `skills/x/skill.md/y`, `docs/new.md/n.txt` and passes `src/claude.mdx/n.txt`, `docs/x.txt`, `docs/ne/x.txt`.

Evidence carried from r1 (three-way Verified tie; lowest replicate). In P9, `docs/a.md/x` (imported), `src/agents.md/z` (a start name) and `docs/A.md/x` were refused, while `docs/a.mdx/y` and `docs/x/y` were not (fcf1-probe.log). P5 printed the main walk's list for `@docs/new.md`, which holds `do doc docs docs/n docs/ne docs/new ... docs/new.md` (fcf1-probe5.log). This confirms that every directory on an import's path is itself an import name. The loop runs only after truthwalk returned 1, which means the walk succeeded (Claim 27).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1945-1951`, `test/scripts/build-loop-check.bats:677-683`, `fcf1-probe.log` (P9), `fcf1-probe5.log`

---

## Claim 32: floor: "It reads nothing but through main_imports, whose root check runs when it walks, so a call both of main_imports' caches answer (import_readers' memo and the walk's) forks nothing but walk_why's subshell after a failed walk; neither changes within a gate decision."

**Location:** `scripts/lib/dev-cycle-read.sh:1919-1922`
**Type:** Performance / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** caller of floor / performance critic
**Scope:** Covers floor's forks on a doubly cached call with and without `$4`. It does not establish whether HOME or the config dirs change within a gate decision; check_line does not change them.
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r1: "It does not establish the cost of the first, uncached call." · r3: "It does not establish 'neither changes within a gate decision' beyond check_line's import_reset per brief, which was not traced here." · r1: probe 4 counted about 3 forks per call without $4 (300 per 100) and 1 per call after a failed walk (walk_why's `$(...)`). · r3: truthrule, writable/anybrief (regex only, `:236-239`), ownfile, isstart and walk_has fork nothing; P9 measured 679 µs per cached path with `$4`. · r1+r2+r3 (escalation note): a future caller that omits `$4` (U3) silently pays the lower fork — to performance-reviewer.

Evidence carried from r2 (three-way Mostly-accurate tie; r2's scope is the most specific). With `$4` given, the cached call forks nothing but `$(walk_why ...)` (`:1943`), as the pwd/tr-shim test shows (E1). Without `$4`, floor forks `lower` (`:1928`) on every call. In P5 (E3), `floor docs/b.md x M` after a warm walk recorded one `tr` call through the shim. The sentence states the zero-fork result unconditionally, while `$4` is introduced as optional two sentences earlier. A precise version: "a call given `$4` that both caches answer forks nothing ...". build-loop.sh, the only production caller, passes `$4`, so the gate is unaffected.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1908-1928`, `scripts/lib/dev-cycle-read.sh:1943`, `fcf2-probe.out` (P5)

---

## Claim 33: Commit 3111ee9d's structural claims: floor "has no root check of its own, truthwalk tests the walk's list itself ..., and main_imports runs need_root below its cache check"; floor takes the lowered path as an optional $4; "both walks call it [prompt_marks] for any absolute prompt entry"; config dirs "computed and checked there ..., outside_seeds reads it, and both walk caches key on it; contract item 4 drops the reset duty"; "its C1 part is c1_seeds ... called at its end"; Notes: "floor's root check now runs only when its walk does"

**Location:** commit 3111ee9d message
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** branch history reader
**Scope:** Covers these claims against HEAD's code, all still true. It does not establish one superseded statement. "The import-name half is not taken" was true at 3111ee9d, and 07af69c0 (A8) later took its .md part.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r2: "It does not establish the state at 3111ee9d alone; 07af69c0 then added readers_root before the cache check." · r3: at 3111ee9d, `git show 3111ee9d:scripts/lib/dev-cycle-read.sh` has `c1_seeds os_a || return 1` at the end of outside_seeds (`:1454`). · r3 confidence on its compound: Medium. · The superseded "import-name half" statement is its own row (Claim 35).

Evidence carried from r1 (Verified tie; lowest replicate, executed). Each claim matches the code at HEAD: Claims 4, 9, 16, 18, 21 and 30 of this report, and r1's P1. One detail has changed: "called at its end" now reads as outside_seeds calling c1_seeds second (`:1445`), since config_seeds holds the rest.

**Evidence:** `git log -1 3111ee9d`, `scripts/lib/dev-cycle-read.sh:1443-1447`, `scripts/build-loop.sh:670`, `fcf1-probe.log`

---

## Claim 34: Commit 3111ee9d: "Measured: a cached floor call 6.5 ms -> 0.61 ms per path (400 paths about 2.6 s -> 0.25 s)"

**Location:** commit 3111ee9d message
**Type:** Performance
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** orchestrator / performance critic
**Scope:** Covers the before/after per-path cost under this run's load. It does not reproduce the absolute figures, which depend on machine load and on the walk list's size.
**Replicate verdicts:** r1=Unverifiable · r2=Unverifiable · r3=Verified (compound)
**Replicate annotations:** r1: probe 3 timed 200 cached floor calls: main's lib (no $4) 9.6 ms per path, HEAD's lib (with $4) 1.18 ms — 8x against the commit's 10.6x; "Verifying them would need the author's fixture and an idle host." · r3 (Verified): "P9 measured main's lib at 6579 µs per path and HEAD's lib with `$4` at 679 µs per path, over 400 cached calls, which matches 6.5 to 0.61 ms within noise"; r3 scope: "on a one-root fixture ... It does not establish exact milliseconds, which depend on load and root count."

Evidence carried from r2 (Unverifiable tie with r1; r2's scope names the walk list's size as well as load, the more specific). E4 measured 15.0 ms (main's lib) and 1.05 ms (HEAD's lib) per cached floor call over 400 paths at load average 1.73. That is a 14x reduction, against the 10.7x claimed. The direction and order of magnitude reproduce; the absolute numbers do not. Re-measuring on an idle machine would settle them.

**Evidence:** `fcf2-logs/timing.txt`

---

## Claim 35: Commit 3111ee9d: "The import-name half is not taken: the parser's prefix candidates make every directory an import passes through an import name"

**Location:** commit 3111ee9d message
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Legibility-target:** orchestrator
**Scope:** Covers the statement against HEAD. It was true at 3111ee9d. The prefix rationale itself is verified in Claim 31.
**Replicate verdicts:** r1=— · r2=Stale · r3=Verified (compound)
**Replicate annotations:** r1 (its claim 27a scope): "'The import-name half is not taken' was true at 3111ee9d, and 07af69c0 (A8) later took its .md part." · r3 (its compound, as of 3111ee9d): "floor's loop is start-name only. That matches the message's 'import-name half is not taken'. 07af69c0 later added the `.md` half (A8)." · All three agree on the facts; the verdicts differ on whether the statement is judged at 3111ee9d or at HEAD. A commit message cannot be amended.

Evidence carried from r2 (the most severe verdict). 07af69c0 (A8) took the `.md` part of the import-name half: floor now refuses below an imported `.md` name, `{ [[ "$d" != *.md ]] || ! walk_has main "$d"; }` (`:1948`). Only the non-`.md` part is left undone, by override row. A commit message cannot be amended, so there is nothing to do.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1946-1948`, commit `07af69c0` message (A8)

---

## Claim 36: Commit 3111ee9d: "Tests: build-loop-check 142 (5 new, 1 reworked)"

**Location:** commit 3111ee9d message
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Legibility-target:** orchestrator
**Scope:** Covers the count of `@test` lines in build-loop-check.bats at main and at 3111ee9d. It is already settled: rubric A17, Accepted-immutable, with the correction stated in 07af69c0. It is recorded here and not re-filed for action.
**Replicate verdicts:** r1=— · r2=Incorrect · r3=— · single-replicate detection
**Replicate annotations:** r1: "Settled and not re-filed: 3111ee9d's '5 new' and '266 changed code lines' (override row, Accepted-immutable; the last rows of `docs/reviews/override-log.md`). The basis has not changed." · r3 (its claim 26 scope): "Its '5 new' test count is excluded: it is settled as Accepted-immutable (rubric A17, override row)." · r3's count check reproduced the same figures (main 138, 3111ee9d 142).

Evidence carried from r2 (sole verdict). `git show main:test/scripts/build-loop-check.bats | grep -c '^@test'` gives 138, and the same count at `3111ee9d` gives 142: 4 new tests plus 1 reworked, not 5 new.

**Evidence:** paraphrased — no quote available because the claim covers a count over two revisions (`git show <rev>:test/scripts/build-loop-check.bats | grep -c '^@test'`: main 138, 3111ee9d 142, 07af69c0 142, 2be3db37 143)

---

## Claim 37: Commit 3111ee9d: "the new tests fail against main's lib"

**Location:** commit 3111ee9d message
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** branch history reader
**Scope:** Covers the F3 test only, re-run here against main's lib. It does not establish the other new tests against main's lib.
**Replicate verdicts:** r1=Unverifiable · r2=Verified (compound) · r3=Unverifiable
**Replicate annotations:** r2 (Verified, minority evidence that reaches the rest): "E1: against main's lib all six are `not ok`" (`fcf2-logs/old-main.txt`); r2 scope: "It does not run 3111ee9d's own versions of the tests." · r1+r3: the iteration-1 rubric records that a fact-check executed this (rubric :79; "the five changed tests fail on main's lib and pass here"). · r3: re-running needed a lib swap that its no-edit rule kept out of scope.

Evidence carried from r1 (Unverifiable tie with r3; r1's scope is the more concrete). Probe 2 reproduces the F3 test's scenario. Main's lib answers `top.md: -` for both walks, where the test wants `imported`, so that test fails on main (fcf1-probe2.log). The remaining new tests were not re-run against main's lib in this pass. The iteration-1 rubric records that a fact-check did so (rubric `:79`). Verifying them all would need each bats test run with `LIB` pointed at main's lib.

**Evidence:** `fcf1-probe2.log`, `docs/reviews/code-review-rubric-2026-10-10-feat-build-loop-u2c2.md:79`

---

## Claim 38: Commits 3111ee9d / 07af69c0 / 2be3db37: "266" / "349" / "360 changed code lines"

**Location:** commit 3111ee9d message; commit 07af69c0 message; commit 2be3db37 message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** orchestrator
**Scope:** Covers added plus deleted lines under `scripts` and `test` against main at each commit (the size gate's count). It does not mean non-comment lines; A17 settled that.
**Replicate verdicts:** r1=— · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r1: "266 changed code lines" settled, not re-filed (override row, Accepted-immutable). · r3: its count check gave the same sums (266, 349, 360).

Evidence carried from r2 (the split verdict). `git diff --numstat main...<c> -- scripts test` sums to 266 (190+76), 349 (259+90) and 360 (270+90).

**Evidence:** paraphrased — no quote available because the figures are numstat sums over three revisions (`git diff --numstat main...<c> -- scripts test`)

---

## Claim 39: Commit 07af69c0: "A1 ...: readers_root runs need_root unless ROOT_REAL is set and import_readers' memo answers for its key; both walks call it first and need_root again below their cache check, so an unset ROOT_REAL exits again (tested), the registry is never listed from an unchecked directory, and a cached tree walk forks no root check either"

**Location:** commit 07af69c0 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** orchestrator
**Scope:** Covers the statements at HEAD, where 2be3db37 (B3) also requires a non-empty memo. At 07af69c0 a memoized refusal skipped need_root, as B3 records.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r1: the unset-ROOT_REAL test is `test/scripts/build-loop-check.bats:672-674`. · r3: the unset-ROOT_REAL exit is its P2b and bats :673; the registry and tree-walk parts are its claims 14 and 20.

Evidence carried from r2 (the split verdict). See Claims 4 and 16. The unset-ROOT_REAL test (`build-loop-check.bats:1388-1389` in the diff) passes (E1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:833`, `scripts/lib/dev-cycle-read.sh:1626-1631`, `fcf2-logs/full-build-loop-check.txt`

---

## Claim 40: Commit 07af69c0's other fix claims: A2 (? rule, tested), A5/A15 (walk_why; unknown KIND worded), A3, A6 (walk_has shared), A8 (tested: docs/new.md/n.txt refuses, docs/ne/x.txt passes), A4/A11-A14

**Location:** commit 07af69c0 message
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** branch history reader
**Scope:** Covers each claim against HEAD. It does not establish A9 as fixed at 07af69c0 itself (Claim 41).
**Replicate verdicts:** r1=Verified (compound) · r2=— · r3=— · single-replicate detection
**Replicate annotations:** related (other clusters): r2 (its claim 38) and r3 (its claim 30) verify the same items' rubric statuses at HEAD (Claim 47).

Evidence carried from r1 (sole replicate verdicting these as commit-message claims). The `?` test is `test/scripts/build-loop-check.bats:662-666`. The A8 test is `:677-683`, and all pass (fcf1-bats.log). The unknown-KIND arm is `:824`: `*) echo "the walk failed (${k:-no reason recorded})"`, and P5 printed `the walk failed (bogus)`.

**Evidence:** `git log -1 07af69c0`, `fcf1-bats.log`, `fcf1-probe.log` (P5)

---

## Claim 41: Commit 07af69c0: "A9 (performance 1): prompt_marks marks a live entry only when its real path lies below a reader root."

**Location:** commit 07af69c0 message
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** orchestrator
**Scope:** Covers the statement as of 07af69c0 (unchanged at ac078bd7). It is already settled: iteration-2 fact-check 12a/29, rubric B1, fixed in 2be3db37. It is recorded here and not re-filed.
**Replicate verdicts:** r1=Verified (compound) · r2=Incorrect · r3=—
**Replicate annotations:** r1+r3 (same substance): A9 is not established as fixed at 07af69c0 itself; "It did nothing until 2be3db37 (B1), as that commit and the rubric record" (r1); "at 07af69c0 that fix did nothing, which iteration 2 found as rubric B1 and 2be3db37 fixed ... settled and not re-filed" (r3). r1's Verified covers the statement at HEAD only.

Evidence carried from r2 (the most severe verdict). At ac078bd7 the loop was `while IFS= read -r p; do [[ "$b" != "$p"/* ]] || break; done <<<"$IMPORT_ROOTS"; [[ "$b" == "$p"/* ]] || return 0`. When no root matches, `read` empties `p` at EOF, and `"$b" == /*` holds for every absolute `b`. The new test fails on that lib (E1, `old-ac078bd7.txt` test 2) and passes at HEAD.

**Evidence:** `git show ac078bd7:scripts/lib/dev-cycle-read.sh` lines 1388-1393, `fcf2-logs/old-ac078bd7.txt`

---

## Claim 42: Commit 07af69c0 / rubric A7: "config_seeds plus a three-call outside_seeds wrapper"

**Location:** commit 07af69c0 message; rubric `docs/reviews/code-review-rubric-2026-10-10-feat-build-loop-u2c2.md:58`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** branch history reader
**Scope:** Covers the wrapper's shape. It does not establish anything about its behavior (Claim 21).
**Replicate verdicts:** r1=Mostly accurate · r2=— · r3=— · single-replicate detection
**Replicate annotations:** related (other cluster): r2 (its claim 38) and r3 (its claim 30) verify rubric A7's Fixed status via the wrapper claim, without verdicting the "three-call" wording.

Evidence carried from r1 (sole replicate). The wrapper makes two calls and one check: `config_seeds "$1" || return 1; c1_seeds "$1" || return 1` and then the newline loop (`scripts/lib/dev-cycle-read.sh:1445-1446`). The precise wording is "a two-call wrapper with the newline check".

**Evidence:** `scripts/lib/dev-cycle-read.sh:1443-1447`

---

## Claim 43: Commit 07af69c0: "build-loop-check 142 ... both walks over this repository give main's 1593 names"

**Location:** commit 07af69c0 message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** orchestrator
**Scope:** Covers the 1593 unique names of the main walk with each of main's and HEAD's libs in this worktree, and the tree walk's total. The count holds while the registry stays at 11 worktrees.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r2: "The tree walk's unique count was not taken." · r3 (closes that gap): "P8 over this repository gives main=1593 and tree=1593 unique names, under both HEAD's lib and main's lib. Counting raw lines gives 1811, so 1593 is the unique-name count." · r1: probe 3: 1593 for both walks under both libs, lists byte-equal. · r3: `grep -c '^@test'` at 07af69c0 gives 142.

Evidence carried from r2 (three-way Verified tie; r2's scope is the most specific). E4 gives `main-lib.sh names: 1593` and `dev-cycle-read.sh names: 1593`, counted as unique non-empty lines of IMPORTED_MAIN. A separate run in this worktree gave the tree walk 1811 lines, the same total as main's walk before deduplication.

**Evidence:** `fcf2-logs/timing.txt`, `fcf3-logs/probe3b.log`, `fcf1-probe3.log`

---

## Claim 44: Commit 2be3db37: "B1 ...: read empties its variable at EOF, so the A9 test passed every absolute path; a flag now records a root match"; "B3: readers_root skips need_root only on a held result, so a memoized refusal from a wrong directory exits"

**Location:** commit 2be3db37 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** orchestrator
**Scope:** Covers the mechanism and both fixes. It does not establish the "A9 test passed every absolute path" wording for 07af69c0's test itself, which was not re-run; the mechanism is shown in Claim 41.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r1+r3: the old code (`git show 07af69c0:scripts/lib/dev-cycle-read.sh`, prompt_marks) was the `|| break` loop; P8 (r1) / P6 (r3) with ac078bd7's lib printed `out.md: docs/a.md`, HEAD's `out.md: none`.

Evidence carried from r2 (the split verdict). The flag is `in=1` inside the loop (`:1395`). The held-result test is `-n "$IMPORT_ROOTS"` (`:833`). P4 (E3) exits for the memoized refusal from `/`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:833`, `scripts/lib/dev-cycle-read.sh:1395`, `fcf2-probe.out` (P4)

---

## Claim 45: Commit 2be3db37: "New test (out-of-root link unmarked, into-root marked) fails on ac078bd7"

**Location:** commit 2be3db37 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** orchestrator
**Scope:** Covers the six new or reworked tests at HEAD, run against main's and ac078bd7's libs. It does not run 3111ee9d's own versions of the tests.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r1: P8 with ac078bd7's lib printed `out.md: docs/a.md`, HEAD's `out.md: none`. · r3: P6 confirms the 2be3db37 test separates ac078bd7's lib from HEAD's.

Evidence carried from r2 (three-way Verified tie; r2's scope is the most specific). E1: against main's lib all six are `not ok`. Against ac078bd7's lib, test 2 (prompt_marks below a root) is `not ok`. So is test 4, the floor-fails-closed test, but only on the seeds sentence that 2be3db37 (B5) changed: `old-ac078bd7.txt` shows the want line for the seeds text.

**Evidence:** `fcf2-logs/old-main.txt`, `fcf2-logs/old-ac078bd7.txt`

---

## Claim 46: Commit 2be3db37: "Tests: build-loop-check 143, read 20, dev-cycle 79 ..."; "dev-cycle.bats' surface inventory lists the new functions and globals"

**Location:** commit 2be3db37 message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** reviewer reading history
**Scope:** Covers the three suite counts with their pass status. It does not establish the git-env and hermeticity counts, which were not run here.
**Replicate verdicts:** r1=— · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r1 (its claim 29 scope): "It does not establish the run counts in the commit ('build-loop-check 143 ...'), since only the changed tests were run here." · r2: ran build-loop-check (143/143) and only the dev-cycle surface test (E2 lists `config_seeds c1_seeds ... walk_why walk_has readers_root` and `IMPORT_CONFIGS IMPORTED_MAIN_WHY`); "read 20, dev-cycle 79, git-env 2 or hermeticity 2 ... were not re-run".

Evidence carried from r3 (Verified tie; r3 ran all three suites). The suites ran 143, 20 and 79 tests, all ok (`fcf3-logs/bats-build-loop-check.log`, `bats-build-loop-read.log`, `bats-dev-cycle.log`). `grep -c '^@test'` at 2be3db37 gives 143.

**Evidence:** `fcf3-logs/bats-build-loop-check.log`, `fcf3-logs/bats-build-loop-read.log`, `fcf3-logs/bats-dev-cycle.log`, `fcf2-logs/dev-cycle-surface.txt`

---

## Claim 47: Rubric A1-A16 statuses (Fixed / Doc fixed / Fixed in text / Defer (row))

**Location:** `docs/reviews/code-review-rubric-2026-10-10-feat-build-loop-u2c2.md:47-67`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** orchestrator
**Scope:** Covers each status at HEAD. A9's "Fixed" holds only at HEAD, through B1 (Claim 41). A17 is Claim 36.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r1: "It does not establish the rubric's own Status line, which is stamped at ac078bd7 and predates this pass. A7's 'three-call' wording is Claim 28b" (Claim 42 here). · r3: "does not re-judge the Defer/Won't-Fix reasoning (settled override rows)." · r3: "Claims 13 and 25 note residual imprecision in A15's and B4's text. Each fix was made as described; what remains is a different nuance" (Claims 13/15 and 32 here).

Evidence carried from r2 (the split verdict). A1 is verified in Claims 16 and 39, A2 in Claim 12, and A3 in walk_why's read sentence (both budgets, `:822`) and the doc's "which trips first" (`:798`). A4 is verified in Claims 7 and 43, A5 by walk_why with its generic arm (`:824`), and A6 by walk_has in both callers (Claim 27). A7 is verified in Claim 21; its doc comments now name c1_seeds (`:1650`, `:1753`), and no "outside_seeds' C1 part" remains (grep). A8 is verified in Claim 31, A9 in Claim 19 (at HEAD), A11 in floor's "both of main_imports' caches" text (`:1920-1921`), and A12 in the inherit rule (`:800-802`). A13's text is at `:1910-1911`, A14's in Claim 1, and A15's in walk_why's readers, link, list and seeds texts. A10, A12's TRUTH_WHERE half and A16 have override rows dated 2026-10-10 for `feat/build-loop-u2c2` (`docs/reviews/override-log.md`, last rows).

**Evidence:** `scripts/lib/dev-cycle-read.sh:792-833`, `scripts/lib/dev-cycle-read.sh:1438-1533`, `scripts/lib/dev-cycle-read.sh:1841-1952`, `docs/reviews/override-log.md` (tail), `fcf2-logs/full-build-loop-check.txt`

---

## Claim 48: Rubric B1-B5 "Fixed" / "Fixed in text"

**Location:** `docs/reviews/code-review-rubric-2026-10-10-feat-build-loop-u2c2.md:16-28`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** orchestrator
**Scope:** Covers B1-B5 at HEAD. Rows B4 and B5 are text; B4's wording is itself Mostly accurate in its no-`$4` case (Claim 32).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** none beyond Claim 47's

Evidence carried from r2 (the split verdict). B1 is verified in Claims 19 and 41. B2: the doc now says an out-of-root link's "target's own names are read plain" (`:1380`). B3 is verified in Claim 16. B4: floor says "forks nothing but walk_why's subshell after a failed walk" (`:1921`). B5: the seeds sentence names a newline path and a failed lower-case (`:820`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:820`, `scripts/lib/dev-cycle-read.sh:833`, `scripts/lib/dev-cycle-read.sh:1373-1396`, `scripts/lib/dev-cycle-read.sh:1919-1922`, `fcf2-logs/old-ac078bd7.txt`

---

## Claim 49: Rubric lite fix-drift refutation: "import_readers sets IMPORT_READERS_DONE before any refusal (a refusal is memoized as an empty IMPORT_ROOTS), so a memoized refusal has DONE == KEY and reaches the `-n "$IMPORT_ROOTS"` test"

**Location:** `docs/reviews/code-review-rubric-2026-10-10-feat-build-loop-u2c2.md:32`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** orchestrator
**Scope:** Covers import_readers' refusals after the key is computed. An import_home failure returns before DONE is set and is not memoized; readers_root's `import_home &&` then falls to need_root.
**Replicate verdicts:** r1=— · r2=Verified · r3=— · single-replicate detection
**Replicate annotations:** related (other cluster): r1 and r3 show the same memoized-refusal path in their readers_root claims (Claim 16).

Evidence carried from r2 (sole replicate). `IMPORT_READERS_DONE="$IMPORT_READERS_KEY"; IMPORT_ROOTS=""; ...` (`:1156`) precedes every refusal (`:1159-1184`). P4 shows the memoized refusal reaching need_root (E3).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1149-1161`, `fcf2-probe.out` (P4)

---

## Claims Requiring Attention

### Incorrect
- **Claim 36** (commit 3111ee9d): "5 new, 1 reworked" is 4 new and 1 reworked (138 → 142). Settled (A17, Accepted-immutable); no action. Single-replicate (r2).
- **Claim 41** (commit 07af69c0): the A9 below-a-root fix was a no-op at that commit. Settled (B1, fixed in 2be3db37 with a test); no action.

### Stale
- **Claim 35** (commit 3111ee9d): "the import-name half is not taken" was superseded by 07af69c0's `.md` half (A8). A commit message cannot change; no action.

### Mostly Accurate
- **Claim 3** (`scripts/lib/dev-cycle-read.sh:18-21`): floor exits on an unset ROOT_REAL only for a path that reaches the walk; an earlier rule's refusal returns 0 with no root check. Fail-closed; add "when it walks".
- **Claim 13** (`scripts/lib/dev-cycle-read.sh:794-795`, `:818`): the list stage's lower_all also lower-cases main's own `.md` names, not only the checkout's.
- **Claim 14** (`scripts/lib/dev-cycle-read.sh:819`): the start/admit sentence omits non-searchable directories and ancestors main stores as a link or gitlink (r2 and r3 read the latter as covered).
- **Claim 15** (`scripts/lib/dev-cycle-read.sh:821`): the copies sentence omits that the first root_copies runs over the starts, not only imported names.
- **Claim 18** (`scripts/lib/dev-cycle-read.sh:1124-1129`): "CLAUDE_CONFIG_DIR when set" means set and non-empty (`:+`); the memo key distinguishes set-empty.
- **Claim 29** (`scripts/lib/dev-cycle-read.sh:1874-1875`): "~1 ms" for isimported's lower and root check measured about 2.2 ms (r1); r2 could not isolate it.
- **Claim 32** (`scripts/lib/dev-cycle-read.sh:1919-1922`): "forks nothing" holds only when `$4` is passed; without it a cached call forks lower.
- **Claim 42** (commit 07af69c0; rubric A7): the "three-call" outside_seeds wrapper makes two calls and a newline check.

### Unverifiable
- **Claim 34** (commit 3111ee9d): "6.5 → 0.61 ms" reproduces in direction and order (r1 9.6 → 1.18, r2 15.0 → 1.05, r3 6.579 → 0.679 ms); exact values need the author's fixture and an idle host.
- **Claim 37** (commit 3111ee9d): "the new tests fail against main's lib" — r1 re-ran only F3, r3 none; r2's E1 ran all six against main's lib (all not ok).

## Goal-Alignment Note

Carried from the three replicates (all agree on the substance). The goal is to land U2c2 after a clean review-fix loop. No replicate found a behavioral mismatch at HEAD. The U2c2 items were each checked against the code that runs them: floor's per-path cost (0 forks on a cached call with `$4`); IMPORTED_MAIN_WHY's KINDs against every `return 1` and walk_why's `?` rule as check_line's; the below-a-start or imported-`.md` refusal; F3 fixed and tested for both walks, with main's lib failing probe PC; the config dirs in the memo key and both walk keys; the c1_seeds/config_seeds split keeping main's 1593 names; and B1's fix now working, with the old lib failing the new test. Both Incorrects and the Stale are commit-message claims already settled in the rubric or override log. The Mostly-accurate items are text imprecisions that fail closed or are cost-only; none changes a gate verdict. Not run by any single replicate in full: git-env and hermeticity suites (r2 and r3 both note this).

## Escalations

- **security-reviewer** · `scripts/lib/dev-cycle-read.sh:18-21`, `:1925-1942`, `scripts/build-loop.sh:867` · raised by r1, r2, r3 · With ROOT_REAL unset, floor's early arms (truthrule, GATE_CODE, docs/thoughts/, docs/working/, docs/reviews/) refuse without running need_root (Claim 3). Fail-closed, but confirm no caller treats floor's exit, rather than its return, as the unset-ROOT_REAL signal. r3: build-loop.sh's comment at :867 relies on "the floor's need_root exit ends the run" for a misconfigured root.
- **security-reviewer** · `scripts/lib/dev-cycle-read.sh:808-826` · raised by r1, r2, r3 · walk_why still prints `IMPORT_READER_WHY` (r1) and absolute host paths whose characters pass NAMECHARS (Claim 12). Settled as B6; noted, not re-filed.
- **performance-reviewer** · `scripts/lib/dev-cycle-read.sh:1919-1928` · raised by r1, r2, r3 · A floor caller that omits `$4` pays one `lower` fork per path; the doc's unconditional "forks nothing" (Claim 32) could mislead a second caller (r3: U3 inherits the old cost silently). build-loop.sh passes `$4`; the bats `floors` helper does not (r2). Cached floor measured 1.05 ms vs 15.0 ms on main's lib (r2 E4). The walk_has glob cost over the larger list is A10's settled Defer row (r1, r2).
- **api-consistency-reviewer** · `scripts/lib/dev-cycle-read.sh:18-21` · raised by r1, r3 · The header's need_root list (Claim 3) is caller-facing and narrower than floor's behavior; decide whether the contract wording should name floor's conditional exit.
- **api-consistency-reviewer** · contract item 6, `scripts/lib/dev-cycle-read.sh:1841-1847`, `:1948` · raised by r1 · Contract item 6 says "Read a walk only through isimported or truthwalk", while floor (lib-internal) calls walk_has directly. Consistent for external callers; check whether item 6 should name walk_has as the lib's own reader.
- **api-consistency-reviewer** · `scripts/lib/dev-cycle-read.sh:1146-1147`, `:1199` · raised by r2 · IMPORT_CONFIGS treats a set-empty CLAUDE_CONFIG_DIR as unset, but the memo key does not (Claim 18). Harmless (same list, one extra registry read) but asymmetric.
- **api-consistency-reviewer** · `scripts/lib/dev-cycle-read.sh:818`, `:821` · raised by r2, r3 · walk_why's `list` sentence names only the checkout's names (Claim 13) and the `copies` sentence omits the starts (r3; Claim 15).
- **architecture-review** · `scripts/lib/dev-cycle-read.sh:1943` · raised by r1, r2, r3 · No new structural claim refuted. floor's direct read of IMPORTED_MAIN_WHY rather than through truthwalk is a settled Defer row (A12's TRUTH_WHERE half, deferred to U3); r2 also cites A16's unprefixed seed locals, documented by outside_seeds' NAME warning (Claim 21). Noted only.

## Verdict stability

- **Total clusters:** 49 (multi-replicate: 43; single-replicate detections: 6 — Claims 23, 26, 36, 40, 42, 49).
- **Agreed (every reporting replicate gave the same verdict, `(compound)` rows compared on the verdict value):** 41 (35 multi-replicate + 6 single-replicate).
- **Disagreed:** 8
  - Claim 14 (walk_why start/admit): r1=Mostly accurate · r2=Verified (compound) · r3=Mostly accurate (compound)
  - Claim 15 (walk_why remaining sentences): r1=— · r2=Verified (compound) · r3=Mostly accurate (compound)
  - Claim 18 (IMPORT_CONFIGS doc): r1=Verified (compound) · r2=Mostly accurate · r3=Verified
  - Claim 29 ("~1 ms"): r1=Mostly accurate · r2=Unverifiable · r3=—
  - Claim 34 (3111ee9d timing): r1=Unverifiable · r2=Unverifiable · r3=Verified (compound)
  - Claim 35 (3111ee9d import-name half): r1=— · r2=Stale · r3=Verified (compound)
  - Claim 37 (3111ee9d new tests fail on main): r1=Unverifiable · r2=Verified (compound) · r3=Unverifiable
  - Claim 41 (07af69c0 A9): r1=Verified (compound) · r2=Incorrect · r3=—
- **Agreement rate:** 41/49 = 83.7% over all clusters; 35/43 = 81.4% over clusters two or more replicates reported. Below the ≥90% falsifier threshold for dropping k to 2. Four of the eight disagreements (Claims 14, 18, 35, 41) are ones where the replicates agree on the facts and differ only on the verdict a fact earns: a caveat recorded under Verified versus Mostly accurate, or a commit message judged at its own commit versus at HEAD.

## Submitted Claims

## Claim 50: "prompt_marks marks a live entry only when its real path lies below a reader root, compared as a literal whole-component prefix"

**Submitted by:** security-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:1392-1396`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers prompt_marks' live (non-`//`) branch over IMPORT_ROOTS as import_readers builds it: the root test is a quoted literal prefix followed by `/`, an entry whose real path equals its own path returns unmarked, and roots spelled with `*`, `?` or `[x]` match only themselves. Does not establish the `//` (dangling) branch, which marks without a root test by design. Does not establish behaviour with an empty or `/` line in IMPORT_ROOTS, which import_readers refuses (`:1178`) and which I did not inject, or what the walks do with the marks afterwards (Claim 51).

The test is:

```bash
# scripts/lib/dev-cycle-read.sh:1392-1396
  if [[ "$l" == //* ]]; then l="${l#/}"; lp="${lp#/}"
  else
    b="$(realpath -e -- "$l")" || return 1; [[ "$b" != "$l" ]] || return 0
    while IFS= read -r p; do [[ "$b" != "$p"/* ]] || in=1; done <<<"$IMPORT_ROOTS"; [[ -n "$in" ]] || return 0
  fi
```
(excerpt ends :1396; prompt_marks continues to :1405, read: below the test it only builds the bases and appends to the caller's arrays)

`"$p"` is quoted, so it matches literally, and the `/` that follows it forces a whole-component prefix.

Executed (`sec.log` section S1). With roots `$T/a/b`, `$T/g/r*`, `$T/q/r?` and `$T/br/[x]`:
- `l1 → $T/a/bc/k.md`: none.
- `l2 → $T/a/b/docs/k.md`: `docs/a.md`.
- `l3 → $T/g/rX/k.md`: none.
- `l4 → $T/q/rZ/k.md`: none.
- `l5 → $T/br/x/k.md`: none.
- an entry whose real path is its own path: none (early return).

The suite's test "prompt_marks marks a live prompt link's names only when its real path lies below a reader root" passed (`bats.log`, ok 2).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1390-1405`, `scripts/lib/dev-cycle-read.sh:1170-1180`, `fcsub-logs/sec.log`, `fcsub-logs/bats.log`

---

## Claim 51: "F3 is closed for a link chain in another worktree and for a config-dir link into ROOT_REAL, in both walks"

**Submitted by:** security-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:1390-1405` (call sites `:1663`, `:1800`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers these shapes, each in both the main and tree walks: a 2-hop and a 3-hop relative symlink chain in another registered worktree whose target there holds older bytes, and a config-dir command link (under `$HOME/.claude` and under `CLAUDE_CONFIG_DIR`) into ROOT_REAL's file. Does not establish a link under a symlinked directory in another root (known issue A5, settled), a root reached through a bind-mount alias, or chains that leave every reader root. It also does not show that the config-dir shape was ever open: main's lib already reports it imported, so for that shape the result confirms no regression, not a fix.

Both walks call prompt_marks on each outside entry with a prompt dir:

```bash
# scripts/lib/dev-cycle-read.sh:1663
    rq=(); outside_proj out work && { [[ "$f" != /* || -z "${pdir[$f]+set}" ]] || prompt_marks pdir pext out "$f" rq; } || { IMPORTED=error; return 1; }
```
```bash
# scripts/lib/dev-cycle-read.sh:1800
    rq=(); outside_proj out work && { [[ "$f" != /* || -z "${pdir[$f]+set}" ]] || prompt_marks pdir pext out "$f" rq; } || { IMPORTED_MAIN=error; return 1; }
```
After each call, the names in `rq` are queued again (`:1665`, `:1804-1809`).

Executed (`sec.log` section S2):

| Shape | This branch, main / tree | Main's lib, main / tree |
|---|---|---|
| Chain `side3/.claude/commands/k.md → ../../docs/l.md → t.md` | imported / imported | - / - (F3 open) |
| 3-hop chain via `docs/m.md → l.md → t.md` | imported / imported | not run |
| `$HOME/.claude/commands/k.md` → ROOT_REAL's `docs/t.md` | imported / imported | imported / imported |
| `CLAUDE_CONFIG_DIR/commands/k.md` → ROOT_REAL's `docs/t.md` | imported / imported | imported / imported |

The suite's F3 test (row 602) passed (`bats.log`, ok 1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1660-1666`, `scripts/lib/dev-cycle-read.sh:1798-1809`, `fcsub-logs/sec.log`, `fcsub-logs/bats.log`

---

## Claim 52: "readers_root never lets a walk read the checkout or list the registry from an unchecked cwd; a double cache hit answers for ROOT_REAL's own walk"

**Submitted by:** security-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:833`, `:1626-1631`, `:1702-1706`
**Type:** Invariant / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both walks entered from a wrong cwd after one good walk, under each of these: a double hit, a walk-cache miss, a change to the reader roots, reader homes, CLAUDE_CONFIG_DIR or managed dir, import_reset, a memoized refusal, and an unset ROOT_REAL. It also checks that a double hit runs no external command. Does not establish the parser's or import_home's reads of non-checkout paths (HOME's realpath, getent), which run before need_root on a memo miss and touch neither the checkout nor the registry. Does not cover a caller that sets ROOT_REAL to a directory other than the one it walked.

```bash
# scripts/lib/dev-cycle-read.sh:833
readers_root() { { [[ -n "${ROOT_REAL:-}" ]] && import_home && import_readers_key && [[ "$IMPORT_READERS_DONE" == "$IMPORT_READERS_KEY" && -n "$IMPORT_ROOTS" ]]; } || need_root; }
```
```bash
# scripts/lib/dev-cycle-read.sh:1626-1631
  readers_root
  import_readers || { IMPORTED_DONE=""; IMPORTED=error; return 1; }
  # The roots never hold an empty line, so the blank line ends them.
  [[ "$IMPORTED_DONE" == "$IMPORT_ROOTS"$'\n\n'"$IMPORT_HOMES"$'\n\n'"$IMPORT_CONFIGS" ]] && { [[ "$IMPORTED" != error ]]; return; }
  need_root  # below the cache check, as in main_imports
```
(excerpt ends :1631; imported_names continues to :1686, read)

The flow is:
- The registry listing (`git worktree list`, `:1170`) is reached only on a memo miss in import_readers, and a memo miss fails readers_root's test, so need_root runs first.
- The memo key leads with ROOT_REAL (`:1146`).
- Every checkout read in the walks follows the `need_root` below each walk's cache check (`:1631`, `:1706`).

Executed (`sec.log` section S3), main and tree walks alike:
- The double hit from `$T/other` returned `TRUTH_WHY=imported` for ROOT_REAL's `docs/a.md`.
- Each of these exited 1 with need_root's message: walk miss, reader-roots change, reader-homes change, config change, managed change, import_reset, refusal memo and unset root.
- With `PATH` set to a shim dir (git, realpath and find log and exit 99), a double hit printed no shim line and returned the cached answer.

**Evidence:** `scripts/lib/dev-cycle-read.sh:833`, `scripts/lib/dev-cycle-read.sh:1144-1206`, `scripts/lib/dev-cycle-read.sh:1623-1631`, `scripts/lib/dev-cycle-read.sh:1698-1706`, `scripts/lib/dev-cycle-read.sh:163-167`, `fcsub-logs/sec.log`

---

## Claim 53: "floor gives the same answer with and without $4 when $4 is lower($1)"

**Submitted by:** security-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:1925-1952`; `scripts/build-loop.sh:671`, `:843-844`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers floor's whole decision (early rules, gate code, docs/thoughts, docs/working, docs/reviews, the import rule and the ancestor rule) when `$4` equals lower($1), and build-loop.sh's call, whose `$4` is lower_all's output for a path pathform has already admitted. Does not establish agreement when `$4` differs from lower($1). Such a `$4` cannot come from build-loop.sh: lower_all keeps a trailing newline and `$(lower …)` drops it, but nrules' pathform denies every newline path before srules runs. It also does not cover a fork failure inside lower, which only the no-`$4` call can hit and which refuses.

```bash
# scripts/lib/dev-cycle-read.sh:1926-1928
  local lp="${4-}" d
  FLOOR_WHY=""
  [[ -n "$lp" ]] || lp="$(lower "$1")" || { FLOOR_WHY="the path could not be lower-cased"; return 0; }
```
(excerpt ends :1928; floor continues to :1952, read: nothing below reads `$1`, only `lp`, `$2` and `$3`)

The caller passes the lowered path as `$4`:

```bash
# scripts/build-loop.sh:671
  if [[ -z "$5" ]] && floor "$2" "$1" "$4" "$3"; then DENY="$FLOOR_WHY"; return 0; fi
```
`srules "$stem" "$p" "${lps[$i]}" "${ss[$i]}" "$co"` (`scripts/build-loop.sh:844`) runs only when nrules set no DENY, and nrules' first test is `if ! pathform "$6"; then DENY=…` (`scripts/build-loop.sh:609`).

Executed (`sec.log` section S4): 24 paths, each floored with lower_all's output and without `$4`, gave `S4 total=24 diff=0`. The paths covered every early rule, mixed case, `.md` ancestors, an imported name, the gate code and own files.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1925-1952`, `scripts/build-loop.sh:606-610`, `scripts/build-loop.sh:668-671`, `scripts/build-loop.sh:841-845`, `fcsub-logs/sec.log`

---

## Claim 54: "walk_has matches literally; a newline in the path can only over-match"

**Submitted by:** security-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:1844-1847`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers walk_has on both arms (main → IMPORTED_MAIN, anything else → IMPORTED) with glob, extglob, bracket and backslash metacharacters and with embedded, leading and trailing newlines. Does not establish that every caller lowers its LP first (Claim 53 covers floor), or what walk_has returns on a failed walk's list (contract item 6 forbids asking then).

```bash
# scripts/lib/dev-cycle-read.sh:1844-1847
walk_has() {
  if [[ "$1" == main ]]; then local -n wh_l=IMPORTED_MAIN; else local -n wh_l=IMPORTED; fi
  [[ "$wh_l" == *$'\n'"$2"$'\n'* ]]
}
```
The operand `"$2"` is quoted, so it is literal. The list is newline-delimited, so an LP holding a newline can match only by spanning two entries (over-match). It can never fail to match an entry it names, because no entry holds a newline.

Executed (`sec.log` section S5). The list was `\ndocs/a.md\nclaude.md\na*b\n`, with the same results on both arms:
- `docs/a.md`: has.
- `docs/a.md\nclaude.md`: has (over-match).
- `a*b`: has (the literal entry).
- No match: `*`, `docs/*`, `docs/a.m?`, `[d]ocs/a.md`, `@(docs/a.md)`, `a\*b`, `aXb`, `docs/a.md*`, `docs/a.md/`, `ocs/a.md`, the empty string, `claude.md\n` and `\ndocs/a.md`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1840-1847`, `fcsub-logs/sec.log`

---

## Claim 55: "Both walks walk again without import_reset after a HOME or IMPORT_MANAGED_DIR change"

**Submitted by:** security-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:1144-1147`, `:1198-1199`, `:1629`, `:1704`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers HOME changes that alter the effective homes (another dir, a trailing slash, the passwd home) and IMPORT_MANAGED_DIR changes, in both walks, counted by walks actually run. Does not establish a re-walk when HOME changes but resolves to the same homes: from HOME set to the passwd home, to HOME unset. That case is a cache hit, and correct, since IMPORT_HOMES and IMPORT_CONFIGS are unchanged. Also not covered: a change to a config dir's contents within one decision, which is in no key (contract item 4's import_reset per decision covers it).

The memo key holds HOME (through IMPORT_HOME_DONE) and IMPORT_MANAGED_DIR:

```bash
# scripts/lib/dev-cycle-read.sh:1144-1148
import_readers_key() {
  local a="${ROOT_REAL:-}" b="$IMPORT_HOME_DONE" c="$IMPORT_READER_ROOTS" d="$IMPORT_READER_HOMES" e="$IMPORT_READER_WHY"
  local f="${CLAUDE_CONFIG_DIR+x}${CLAUDE_CONFIG_DIR-}" g="$IMPORT_MANAGED_DIR"
  IMPORT_READERS_KEY="${#a}:$a ${#b}:$b ${#c}:$c ${#d}:$d ${#e}:$e ${#f}:$f ${#g}:$g"
}
```
IMPORT_CONFIGS is rebuilt from the homes and the managed dir:

```bash
# scripts/lib/dev-cycle-read.sh:1198-1199
  for p in "${rs_h[@]}"; do [[ "$p" != /* ]] || IMPORT_CONFIGS+="${p%/}/.claude"$'\n'; done
  IMPORT_CONFIGS+="${CLAUDE_CONFIG_DIR:+$CLAUDE_CONFIG_DIR$'\n'}$IMPORT_MANAGED_DIR"
```
Each walk's cache key ends with `$IMPORT_CONFIGS` (`:1629`, `:1704`).

Executed (`sec.log` section S6), with outside_seeds wrapped to count walks. Main and tree gave the same sequence:

| Step | Result | Walks run |
|---|---|---|
| Start | `h1 e: -` | 1 |
| HOME set to h2 | `h2 e: imported` | 2 |
| Before the managed-dir change | `m: -` | 2 |
| IMPORT_MANAGED_DIR changed | `m: imported` | 3 |
| HOME given a trailing slash | walked again | 4 |
| HOME set to the passwd home | walked again | 5 |
| HOME unset (same effective home) | cache hit, answer unchanged | 5 |

**Evidence:** `scripts/lib/dev-cycle-read.sh:1087-1093`, `scripts/lib/dev-cycle-read.sh:1144-1206`, `scripts/lib/dev-cycle-read.sh:1629`, `scripts/lib/dev-cycle-read.sh:1704`, `fcsub-logs/sec.log`

---

## Claim 56: "No gate caller relies on floor's need_root exit for an early-rule refusal"

**Submitted by:** security-reviewer
**Location:** `scripts/build-loop.sh:326-329`, `:860-870`; `scripts/dev-cycle.sh:126`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every current floor call site in `scripts/` (one: build-loop.sh srules) and the setup that precedes it: cd to the toplevel and ROOT_REAL set before any mode runs, with no later `cd` in that shell. It also covers the fact that early-rule refusals return a refusal, not a pass, from a wrong cwd or an unset ROOT_REAL. Does not establish a future floor caller (U3's `--merge`). dev-cycle.sh does not call floor; its `:126` only sets ROOT_REAL for truthrule and truthwalk.

The executed grep for floor calls in `scripts/` (`sec.log` section S7) found exactly one:

```bash
# scripts/build-loop.sh:671
  if [[ -z "$5" ]] && floor "$2" "$1" "$4" "$3"; then DENY="$FLOOR_WHY"; return 0; fi
```
Setup runs before any mode:

```bash
# scripts/build-loop.sh:326-329
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "Not inside a git repository" >&2; exit 1; }
cd "$ROOT"
# shellcheck disable=SC2034  # read by the lib's file rules
ROOT_REAL="$(pwd -P)"
```
The only other `cd` lines in build-loop.sh are inside subshells: `:218`, inside `$(...)`, and `:563`, inside `( … )` (paraphrased — no quote available because the claim covers the absence of other `cd` calls, established by `grep -n 'cd '`).

Executed: from a wrong cwd, floor refused with its early-rule reason and did not exit, for six paths: `CLAUDE.md`, `.x/y`, `docs/thoughts/a`, `scripts/lib/a`, `docs/working/x` and `docs/reviews/x`. With ROOT_REAL unset, `CLAUDE.md` also refused with "an instruction or prompt file…" (`sec.log` section S7).

**Evidence:** `scripts/build-loop.sh:326-329`, `scripts/build-loop.sh:671`, `scripts/build-loop.sh:860-870`, `scripts/dev-cycle.sh:122-126`, `fcsub-logs/sec.log`

---

## Claim 57: "The per-path goal holds on the final code: --check over a 400-path fixture ~4x faster than main's lib, a cached floor call 11-14x faster over this repository"

**Submitted by:** performance-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:1925-1952` (floor); `scripts/build-loop.sh:671`
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `--check` end to end on the 1-worktree fixture (3 interleaved pairs) and cached floor with `$4` over this repository with 11 worktrees (2 runs per lib). Does not establish `--check` timed end to end against this repository, or any timing under load.

The ~4x part reproduces. `--check` took 0.68 / 0.68 / 0.68 s on this branch against 2.77 / 2.70 / 2.83 s on main's code, which is 3.97x to 4.16x (`perf-check.log`).

The "11-14x" for cached floor does not reproduce:
- This branch: 1.019 and 1.007 ms/path.
- Main's lib: 10.790 and 10.704 ms/path in the "$4 passed" column, 8.465 and 8.540 in the "no $4" column (`perf-real.log`).

Main's floor ignores a fourth argument (`git show main:…` `:1828-1832`: `lp="$(lower "$1")"` with `need_root` above it), so its two columns are the same workload. The fair ratio is therefore 8.3x to 10.7x. The critic's 11-14x divides by main's higher column only. Its own same-workload main column (8.634 / 11.736 ms) gives 8.4x to 11.5x.

The precise version is "about 8-11x". The mechanism is right: main forks need_root's `pwd -P` and lower per path, and this branch forks neither (Claim 59). The conclusion holds too: the per-path goal is met by a wide margin.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1925-1928`, `scripts/build-loop.sh:671`, `fcsub-logs/perf-real.log`, `fcsub-logs/perf-check.log`

---

## Claim 58: "After the B1 fix, prompt_marks marks 0 of 9 live entries per walk over this repository, and the main walk's time matches main's lib"

**Submitted by:** performance-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:1392-1396`
**Type:** Performance / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers this repository's state at 2026-10-10 10:26 (11 worktrees, `CLAUDE_CONFIG_DIR=/home/node/.claude`), both walks' prompt_marks census and 3 interleaved main-walk timing pairs. Does not establish other hosts or registries, where links into a root would be marked by design, or the tree walk's time against main's.

prompt_marks' live branch returns before marking unless the real path differs and lies below a root (quoted in Claim 50).

Executed census, the same for each walk (`perf-real.log`): `live=9 (realpath same=3, differs-out-of-roots=6, differs-in-root=0) requeued=0`. Both walks gave `listbytes=80855`.

Main-walk times: this branch 3.04 / 2.93 / 3.03 s, main's lib 2.98 / 4.22 / 2.95 s. The 4.22 is a single outlier, and the other pairs agree within 0.1 s. Both libs list 1,811 lines.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1390-1405`, `fcsub-logs/perf-real.log`

---

## Claim 59: "readers_root and a cached floor call with $4 fork nothing (xtrace)"

**Submitted by:** performance-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:833`, `:1925-1952`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers readers_root on a memo hit and floor with `$4` on a path that reaches the cached main walk and the ancestor loop, both at depth-0 shell work with no external command. Does not establish floor without `$4`, which forks lower's `$(printf | tr)` (3 subshell lines and a `tr` call in my run). It also does not cover floor after a failed walk, which forks walk_why's `$(...)` and, on a readers refusal, need_root's `pwd -P`.

readers_root (quoted in Claim 52) is `[[ ]]` tests plus import_home's key compare and import_readers_key's string building. floor with `$4` skips the `lower` call (`:1928`, quoted in Claim 53).

Executed with two independent detectors (`perf-fork.log`): xtrace with `PS4` showing `$BASH_SUBSHELL`, and `PATH` set to a dir of shims that log any external call.

| Call | xtrace lines | Subshell lines | Shim calls |
|---|---|---|---|
| readers_root | 42 | 0 | 0 |
| cached floor with `$4` | 3872 | 0 | 0 |

The critic's own xtrace re-run (`perf-fail.log`, `perf-real.log`) agrees: 0 subshell lines and 0 `++` lines for both.

**Evidence:** `scripts/lib/dev-cycle-read.sh:833`, `scripts/lib/dev-cycle-read.sh:1087-1090`, `scripts/lib/dev-cycle-read.sh:1144-1148`, `scripts/lib/dev-cycle-read.sh:1925-1952`, `fcsub-logs/perf-fork.log`, `fcsub-logs/perf-real.log`, `fcsub-logs/perf-fail.log`

---

## Claim 60: "The tree walk's cached call is fork-free since need_root moved below its cache check (imported_names ~0.41 ms vs ~1.0 ms on main)"

**Submitted by:** performance-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:1623-1631`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a cached imported_names call (and a cached `truthwalk tree` with a lowered path) over this repository, 11 worktrees, two runs each. Does not establish the uncached walk's cost, or isimported's tree path, which still runs need_root and lower per call (`:1836-1838`).

Main's order puts need_root first. This is paraphrased from `git show main:scripts/lib/dev-cycle-read.sh:1556-1559`, because that file is not in the worktree: there, `need_root` runs before `import_readers` and the cache test. This branch runs readers_root, which forks nothing on a memo hit, and puts need_root below the cache test (`:1626-1631`, quoted in Claim 52).

Executed:
- Fork check (`perf-fork.log`): a cached imported_names showed 0 subshell lines and 0 shim calls on this branch, against 1 subshell line on main's lib (need_root's `$(pwd -P)`). A cached `truthwalk tree` showed 0 subshell lines and 0 shim calls on this branch, against 5 and a `tr` call on main's lib.
- Timing (`perf-tree.log`): cached imported_names took 0.4076 / 0.4085 ms on this branch against 0.9423 / 0.9512 ms on main (2.3x). Cached `truthwalk tree` took 0.83 / 0.80 ms against 4.49 / 4.37 ms.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1623-1631`, `scripts/lib/dev-cycle-read.sh:1881-1887`, `fcsub-logs/perf-fork.log`, `fcsub-logs/perf-tree.log`

---

## Claim 61: "The new failure reasons cost less per path than main's lib on every failure measured (budget, readers refusal)"

**Submitted by:** performance-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:1943` (floor), `:808-826` (walk_why), `:833` (readers_root)
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two failures the critic measured: `IMPORT_OUT_MAX=1000` and an `IMPORT_READER_WHY` refusal, cached floor with `$4` over 400 paths, 11 worktrees, two runs. Does not establish other failure kinds (link, start, seeds, copies). Note that the `IMPORT_OUT_MAX=1000` failure records WHY as `read skills/code-fact-check/SKILL.md` (the per-file budget trips in import_file) rather than `budget`, so it times the `read` sentence.

```bash
# scripts/lib/dev-cycle-read.sh:1943
    if [[ "$TRUTH_WHY" == walk ]]; then FLOOR_WHY="the default branch's instruction files could not be walked for @ imports: $(walk_why "$IMPORTED_MAIN_WHY")"
```

Executed (`perf-fail.log`):

| Failure | This branch (ms/path) | Main's lib (ms/path) |
|---|---|---|
| Budget run | 1.565 / 1.502 | 4.115 / 4.154 |
| Readers refusal | 1.992 / 2.000 | 3.271 / 3.121 |

walk_why's `$(...)` costs 0.50-0.52 ms per call.

**Evidence:** `scripts/lib/dev-cycle-read.sh:808-826`, `scripts/lib/dev-cycle-read.sh:833`, `scripts/lib/dev-cycle-read.sh:1941-1944`, `fcsub-logs/perf-fail.log`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 57** (`scripts/lib/dev-cycle-read.sh:1925-1952`): the cached-floor speedup re-measures at 8.3-10.7x, not 11-14x. Main's floor ignores `$4`, so the critic's "$4 passed" main column is the same workload as its no-`$4` column (8.6-11.7 ms). State "about 8-11x". The ~4x `--check` figure reproduces (3.97-4.16x).

### Unverifiable
(none)
