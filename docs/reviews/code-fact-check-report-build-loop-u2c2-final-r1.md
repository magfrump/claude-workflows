Commit: 8786f8fc

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u2c2 (branch `feat/build-loop-u2c2`)
**Scope:** `git diff main...HEAD -- scripts test` (commits 3111ee9d, 07af69c0, 2be3db37), plus those three commit messages and the rubric `docs/reviews/code-review-rubric-2026-10-10-feat-build-loop-u2c2.md` (Fixed statuses A1-A16, B1-B5). Final confirming pass, replicate r1 (agent `fcf1`).
**Checked:** 2026-10-10
**Total claims checked:** 33
**Summary:** 26 verified, 5 mostly accurate, 0 stale, 0 incorrect, 2 unverifiable

Hallucination log read (`docs/reviews/hallucination-patterns.md`). No claim below matches a logged pattern, and no claim names a symbol that does not exist. Every function and global the docs name greps in the lib.

Execution provenance. Every probe ran under `LC_ALL=C` in a fresh fixture repo under `/tmp/claude-1000/-workspace/843b51ad-a12f-4e61-b040-53f5def15aef/scratchpad/u2c2-review/fcf1-XXXX`, which was removed afterwards. The one exception is probe 3, which ran read-only walks in the review worktree. The scripts and their captured output sit next to each other in that directory:
- `fcf1-bats.sh` → `fcf1-bats.log`. 2026-10-10T17:04:26Z, cwd the review worktree, exit 0. It runs the six changed or new build-loop-check tests serially with `TMPDIR` set to the probe's own directory, and all six pass.
- `fcf1-probe.sh` → `fcf1-probe.log`. 17:05:08Z, exit 0. Probes P1-P9.
- `fcf1-probe2.sh` → `fcf1-probe2.log`. 17:05:54Z, exit 0. Security F3's probe PC against main's lib and HEAD's lib, plus timing.
- `fcf1-probe3.sh` → `fcf1-probe3.log`. 17:06:40Z, exit 0. Both walks over the review worktree with main's lib and HEAD's lib, plus cached floor timing.
- `fcf1-probe4.sh` → `fcf1-probe4.log`. 17:07:33Z, exit 0. Counts forks per cached floor call from the `ns_last_pid` counter. Two earlier clean runs gave 0, 300 and 100 per 100 calls with a noise baseline of 0. The logged run carries noise from concurrent agents: 0, 336 and 129.
- `fcf1-probe5.sh` → `fcf1-probe5.log`. 17:08:07Z, exit 0. Prints the main walk's list for a one-import fixture.

Environment note: this sandbox exports `CLAUDE_CONFIG_DIR=/home/node/.claude`, so every walk above also read that config dir.

---

## Claim 1: "--check help: the self-merge floor (... a path below a start file's or an imported .md file's name, ...; a walk that fails refuses every path, its reason saying where, with a PATH outside pathform's characters shown as ?; ...)"

**Location:** `scripts/build-loop.sh:177-184`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** a `--check` user reading `--help` (operator)
**Scope:** Covers floor's below-a-name rule, the walk-failure wording and the `?` substitution as srules reaches them. It does not establish what happens to the brief's own file or to a path the N rules refuse, since floor is not run on either.

The help sentence names each rule floor implements. The below-a-name loop is `scripts/lib/dev-cycle-read.sh:1947-1949`: `d="${d%/*}"; ! isstart "$d" && { [[ "$d" != *.md ]] || ! walk_has main "$d"; } || { FLOOR_WHY="a path below the name of ..."`. The walk-failure reason is `:1943`: `FLOOR_WHY="... could not be walked for @ imports: $(walk_why "$IMPORTED_MAIN_WHY")"`. The `?` rule is in walk_why at `:811`: `[[ -z "$d" || "$d" =~ ^[$NAMECHARS]+$ ]] || d="?"`. "Refuses every path" holds because a path that reaches the walk is refused with the walk reason, and any earlier floor rule refuses with its own reason. Bats test "floor fails closed when main's walk fails, saying where" passes (fcf1-bats.log), including the `? could not be read` row for `a b/CLAUDE.md`.

**Evidence:** `scripts/build-loop.sh:177-184`, `scripts/lib/dev-cycle-read.sh:1925-1952`, `scripts/lib/dev-cycle-read.sh:808-826`, fcf1-bats.log

---

## Claim 2: srules passes the lowered path as floor's $4 "so floor forks no lower"

**Location:** `scripts/build-loop.sh:671`; floor doc `scripts/lib/dev-cycle-read.sh:1908-1911`
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer of build-loop.sh and the lib's floor
**Scope:** Covers srules' fourth argument and floor's use of it. It does not establish forks inside a walk that misses its cache.

`scripts/build-loop.sh:671` reads `if [[ -z "$5" ]] && floor "$2" "$1" "$4" "$3"; then`. Its caller passes `"${lps[$i]}"`, which comes from `nul_list lps lower_all "${ps[@]}"` at `:840` and `:844`. Floor's first line, `:1926-1928`, is `local lp="${4-}" d` … `[[ -n "$lp" ]] || lp="$(lower "$1")"`, so a non-empty $4 skips the lower. Probe 4 counted 0 forks per 100 cached floor calls with $4, against about 300 (3 per call) without it (fcf1-probe4.log).

**Evidence:** `scripts/build-loop.sh:668-682`, `scripts/build-loop.sh:838-845`, `scripts/lib/dev-cycle-read.sh:1925-1928`, fcf1-probe4.log

---

## Claim 3: "check_brief, isimported and the import walks (truthwalk and floor through them; ...) exit 1 (need_root) unless ROOT_REAL is set, is the current directory and is a repository's top level"

**Location:** `scripts/lib/dev-cycle-read.sh:18-21`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** a gate caller reading the lib header
**Scope:** Covers floor's and truthwalk's exit behavior under an unset ROOT_REAL. It does not establish check_brief's behavior, which this diff did not change.

floor has no root check of its own any more. It exits only when a path reaches `truthwalk main`. A path an earlier rule refuses returns 0 without any root check. In probe P1, with ROOT_REAL unset, `floor CLAUDE.md` printed `claude.md: an instruction or prompt file, ...` and `floor docs/working/z.md` printed `working: a working file that is not this brief's own ...`. Only `floor docs/x.md` exited 1, with `ROOT_REAL is not set` (fcf1-probe.log). truthwalk with an unknown WALK also returns without a check: `*) return 0 ;;` at `:1883`. The result still fails closed, because every such path is refused. The precise version is "...floor through them when it walks". Floor's own doc already says this at `:1919`: "It reads nothing but through main_imports, whose root check runs when it walks".

**Evidence:** `scripts/lib/dev-cycle-read.sh:18-21`, `scripts/lib/dev-cycle-read.sh:1925-1952`, `scripts/lib/dev-cycle-read.sh:1881-1887`, fcf1-probe.log (P1)

---

## Claim 4: "a call the walk's caches answer checks only that ROOT_REAL is set"

**Location:** `scripts/lib/dev-cycle-read.sh:20`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** a gate caller reading the lib header
**Scope:** Covers main_imports and imported_names on a hit in both import_readers' memo (a held result) and the walk cache. It does not establish isimported, which keeps its own `need_root` at `:1836`.

On a hit, readers_root (`:833`) is satisfied by `[[ -n "${ROOT_REAL:-}" ]] && import_home && import_readers_key && [[ "$IMPORT_READERS_DONE" == "$IMPORT_READERS_KEY" && -n "$IMPORT_ROOTS" ]]`. Both walks then return from the cache check before their own `need_root` (`:1629-1630`, `:1704-1706`). In P2 the walk was cached, then the probe ran `cd /`. `floor docs/q.md` still answered `-` and `floor docs/a.md` answered imported, while `isimported main docs/a.md` exited with "ROOT_REAL is not the current directory" (fcf1-probe.log).

**Evidence:** `scripts/lib/dev-cycle-read.sh:827-833`, `scripts/lib/dev-cycle-read.sh:1623-1631`, `scripts/lib/dev-cycle-read.sh:1698-1707`, fcf1-probe.log (P2)

---

## Claim 5: Contract item 4: "neither walk's cache key holds them (both hold import_readers' roots, homes and config dirs, so HOME, IMPORT_READER_*, CLAUDE_CONFIG_DIR and IMPORT_MANAGED_DIR need no reset; the worktree registry is read again after a reset or when one of those changes ...)"

**Location:** `scripts/lib/dev-cycle-read.sh:70-76`
**Type:** Invariant / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** a gate caller (contract reader)
**Scope:** Covers the two walk keys and import_readers' key. It does not establish IMPORT_OUT_MAX or IMPORT_WORK_MAX handling, which is unchanged and still needs a reset.

The key at `:1146-1147` is `local f="${CLAUDE_CONFIG_DIR+x}${CLAUDE_CONFIG_DIR-}" g="$IMPORT_MANAGED_DIR"` followed by `IMPORT_READERS_KEY="... ${#f}:$f ${#g}:$g"`. HOME enters through `IMPORT_HOME_DONE` (`b`), and both reader lists through `c` and `d`. Both walk keys append `"$IMPORT_CONFIGS"` (`:1629`, `:1704`). Bats test "both walks key on the config dirs ..." passes. It sets CLAUDE_CONFIG_DIR after a walk, with no import_reset, and both walks then answer `set: imported` (fcf1-bats.log).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1141-1160`, `scripts/lib/dev-cycle-read.sh:1629`, `scripts/lib/dev-cycle-read.sh:1704`, fcf1-bats.log

---

## Claim 6: Contract item 8: "Pass truthrule, truthwalk, ... a lower-cased path (...; floor lowers first unless its caller passes the lowered path, ...; truthrule refuses an upper-case letter as case, truthwalk as imported)"

**Location:** `scripts/lib/dev-cycle-read.sh:91-96`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** a gate caller (contract reader)
**Scope:** Covers truthwalk's and floor's case handling. It does not establish truthwalk's behavior when its walk fails, where it answers `walk` before any case test.

truthwalk at `:1885`: `[[ "$2" != *[ABCDEFGHIJKLMNOPQRSTUVWXYZ]* ]] && ! walk_has "$1" "$2" || return 0`, with `TRUTH_WHY=imported` set at `:1884`. In P4, `truthwalk main Docs/Q.md` printed `upper: 0 imported` and the lower-case miss printed `lower: 1 []` (fcf1-probe.log). For floor's half, see Claim 23.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1881-1887`, fcf1-probe.log (P4)

---

## Claim 7: Contract item 9 adds IMPORT_CONFIGS to "Never set these yourself ...: they are import_readers' results, which a cache hit does not recompute"

**Location:** `scripts/lib/dev-cycle-read.sh:101-104`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** a gate caller (contract reader)
**Scope:** Covers who assigns IMPORT_CONFIGS. It does not establish that no caller sets it, though no script under scripts/ does.

IMPORT_CONFIGS is assigned only at `:1132` (sourcing), `:1156` (cleared on a memo miss) and `:1198-1199` (built). A memo hit returns at `:1155` before any of those (paraphrased — no quote available because the claim covers absence of other assignments; grep over scripts/ found only these lines).

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

`:1631`: `IMPORTED_DONE="$IMPORT_ROOTS"$'\n\n'"$IMPORT_HOMES"$'\n\n'"$IMPORT_CONFIGS"`. `:1707`: `IMPORTED_MAIN_DONE="$MAIN_SHA $MAIN_BY_NAME $IMPORT_ROOTS"$'\n\n'"$IMPORT_HOMES"$'\n\n'"$IMPORT_CONFIGS"`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1629-1631`, `scripts/lib/dev-cycle-read.sh:1704-1707`

---

## Claim 9: "a prompt's projected names, a live link's too (U2b3b2c final security F3), are read as prompts with the link's bases", and F3 (probe PC) is covered for both walks

**Location:** `scripts/lib/dev-cycle-read.sh:762-764`; callers `:1663`, `:1800`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** security reviewer / lib maintainer
**Scope:** Covers a live prompt link whose real path lies below a reader root, in both walks. It does not establish a live link out of every root, which is read plain by design (Claim 18).

Both walks now call prompt_marks for any absolute prompt entry. The condition is `[[ "$f" != /* || -z "${pdir[$f]+set}" ]] || prompt_marks ...` at `:1663` and `:1800`. Probe 2 rebuilt PC (main's `docs/t.md` = `t: @top.md`, side's older copy plus a live `.claude/commands/k.md -> ../../docs/t.md`). With main's lib both walks print `top.md: -`. With HEAD's lib both print `top.md: imported` (fcf1-probe2.log). The bats test at `test/scripts/build-loop-check.bats:590` loops `for w in tree main` and passes.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1663`, `scripts/lib/dev-cycle-read.sh:1800`, `test/scripts/build-loop-check.bats:590-599`, fcf1-probe2.log

---

## Claim 10: IMPORTED_MAIN_WHY: "readers, main (not found by name), tree (...), link PATH (START_LINK), list (...), start PATH or admit PATH (main_checkout refused a start or an import main lacks), seeds, copies, read PATH (...) or budget (...). ... Each stage sets its KIND before it runs, so a failure a stage adds reports that stage (one with its own KIND sets it where it fails)."

**Location:** `scripts/lib/dev-cycle-read.sh:792-802`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** lib maintainer adding a `return 1` to main_imports
**Scope:** Covers every `return 1` in main_imports (`:1698-1828`) and the KIND it reports. It does not establish that each sentence walk_why prints names every cause in its stage (Claim 12).

I read every return in the function. `IMPORTED_MAIN_WHY=readers` is set on import_readers' failure (`:1703`). `=main` comes before main_by_name (`:1708`). `=tree` (`:1709`) covers ls-tree, the record regex, a duplicate or newline name, a directory clash and the links' lower_all. `"link ${links[i]}"` is set at `:1728`. `=list` (`:1730`) covers checkout_md, the newline test and the candidates' lower_all. `"start $f"` is set at `:1739`. `=seeds` (`:1745`) covers outside_seeds and the seed lower. `=copies` is set at `:1755` and again at `:1824`. `"read $f"` is set per pop at `:1765` and covers every arm of the case, outside_proj, prompt_marks and the lower of out. `"admit $p"` is set at `:1808` and `:1820`, and `=budget` at `:1811`. Every other `return 1` follows the stage marker of its own section.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1698-1828`

---

## Claim 11: "It is empty after a walk that succeeds and kept with a cached failure."

**Location:** `scripts/lib/dev-cycle-read.sh:799-800`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** floor's maintainer
**Scope:** Covers main_imports' own writes. It does not establish protection against a caller assigning the global, which nothing prevents.

`:1827` sets `IMPORTED_MAIN_WHY=""` as the function's last line. A cache hit returns at `:1704` without touching it. In P7 a failed walk gave `1: start CLAUDE.md`, and the cached second call gave `2: start CLAUDE.md`. When the probe overwrote the global, the cached call kept the overwrite (`3: xx`), which confirms that only main_imports writes it (fcf1-probe.log).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1704`, `scripts/lib/dev-cycle-read.sh:1827`, fcf1-probe.log (P7)

---

## Claim 12: walk_why "start|admit": "the checkout holds $d, which the walk reads, as other than a readable plain file below plain directories"

**Location:** `scripts/lib/dev-cycle-read.sh:819`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** operator reading a `--check` deny row
**Scope:** Covers the sentence against main_checkout's return-1 cases. It does not establish the other KIND sentences, which are Verified under Claims 1 and 13.

main_checkout returns 1 in three cases the sentence does not quite name. The first is an ancestor main stores as a link or gitlink (`:1609`: `[[ ! "${mc_e[$c]:-}" =~ ^1[26]0000$ ]] || return 1`), a property of main's tree rather than of what the checkout holds. The second is a plain directory that is not searchable (`:1612`: `elif ! plaindir "$c" || [[ ! -x "$c" ]]; then return 1`), which is a "plain directory" yet fails. The third is the internal ENT/MEMO type check (`:1601`). The bats case `chmod 644 docs` (`test/scripts/build-loop-check.bats:640-641`) reports this sentence for a non-searchable directory. A tighter wording would be "... below plain searchable directories, none stored on the default branch as a link or gitlink".

**Evidence:** `scripts/lib/dev-cycle-read.sh:1595-1622`, `scripts/lib/dev-cycle-read.sh:819`, `test/scripts/build-loop-check.bats:640-641`

---

## Claim 13: walk_why: "A PATH shows only when every character is one pathform allows (check_line's rule for repo text, so a crafted name prints as ?), a // entry as its absolute path."

**Location:** `scripts/lib/dev-cycle-read.sh:804-811`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** security reviewer / operator
**Scope:** Covers the character test and the // strip. It does not establish pathform's structural rules (no leading `/`, no `.git`), which walk_why does not apply and the doc does not claim.

`:810-811`: `[[ "$d" != //* ]] || d="${d#/}"` and `[[ -z "$d" || "$d" =~ ^[$NAMECHARS]+$ ]] || d="?"`. check_line uses the same test: `scripts/build-loop.sh:842` `[[ ! "$p" =~ ^[$NAMECHARS]+$ ]] || shown="$p"`. In P5, `read //opt/x y.md` printed `? could not be read ...`, `read //opt/x.md` printed `/opt/x.md could not be read ...`, and `start a b/c.md` printed `the checkout holds ?` (fcf1-probe.log).

**Evidence:** `scripts/lib/dev-cycle-read.sh:808-826`, `scripts/build-loop.sh:842`, fcf1-probe.log (P5)

---

## Claim 14: readers_root: "need_root, unless ROOT_REAL is set and import_readers' memo already holds a result for its key (a hit reads nothing; a memoized refusal checks the root too), so a walk never lists the registry from an unchecked directory; each walk calls it first and need_root again below its own cache check, so a call both caches answer forks no root check"

**Location:** `scripts/lib/dev-cycle-read.sh:827-833`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** lib maintainer
**Scope:** Covers both walks' entry. It does not establish import_targets' own import_readers call (`:878`), which runs inside a walk after the check, or the `realpath -m` import_home forks before need_root when HOME changes. That fork resolves an absolute HOME and lists no registry.

The code is `{ [[ -n "${ROOT_REAL:-}" ]] && import_home && import_readers_key && [[ "$IMPORT_READERS_DONE" == "$IMPORT_READERS_KEY" && -n "$IMPORT_ROOTS" ]]; } || need_root`. A refusal is memoized with an empty IMPORT_ROOTS (`:1156` sets DONE first and clears the roots, then returns 1). In P3, a `CLAUDE_CONFIG_DIR=rel` refusal reported `refused: readers`, and after `cd /` the next main_imports exited with "ROOT_REAL is not the current directory" (fcf1-probe.log). Both walks call readers_root first (`:1626`, `:1702`) and need_root below the cache check (`:1630`, `:1706`). Probe 4 counted 0 forks per 100 cached floor calls.

**Evidence:** `scripts/lib/dev-cycle-read.sh:827-833`, `scripts/lib/dev-cycle-read.sh:1149-1160`, `scripts/lib/dev-cycle-read.sh:1623-1631`, `scripts/lib/dev-cycle-read.sh:1698-1707`, fcf1-probe.log (P3), fcf1-probe4.log

---

## Claim 15: import_readers: "IMPORT_CONFIGS holds outside_seeds' config dirs, newline-separated: each absolute home's .claude, then CLAUDE_CONFIG_DIR when set and IMPORT_MANAGED_DIR; the key holds both, ... A CLAUDE_CONFIG_DIR that is not absolute or holds a newline returns 1." Also the memo key "the two config dirs".

**Location:** `scripts/lib/dev-cycle-read.sh:1116-1129`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** lib maintainer
**Scope:** Covers contents, order, key and refusals. It does not establish one edge of "when set": a set-but-empty CLAUDE_CONFIG_DIR is neither refused nor listed (`${CLAUDE_CONFIG_DIR:+...}`), as on main.

`:1198-1199`: `for p in "${rs_h[@]}"; do [[ "$p" != /* ]] || IMPORT_CONFIGS+="${p%/}/.claude"$'\n'; done` and `IMPORT_CONFIGS+="${CLAUDE_CONFIG_DIR:+$CLAUDE_CONFIG_DIR$'\n'}$IMPORT_MANAGED_DIR"`. The refusal is at `:1160`. In P6, with `IMPORT_READER_HOMES=/host/home`, `CLAUDE_CONFIG_DIR=/cfg` and `IMPORT_MANAGED_DIR=/m`, the order printed was `$HOME/.claude`, `/host/home/.claude`, `/cfg`, `/m`. Set-empty and unset both dropped `/cfg` (fcf1-probe.log). The bats newline case answers `refused` for both walks.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1149-1206`, fcf1-probe.log (P6), fcf1-bats.log

---

## Claim 16: truthwalk "asks it about PATH, lower-cased (contract item 8), through walk_has as isimported does, but with no lower ...; Returns 0 when the walk fails (TRUTH_WHY=walk) or reaches PATH or PATH holds an upper-case letter (TRUTH_WHY=imported; both callers run truthrule's case word first), else 1 with TRUTH_WHY empty; an unknown WALK answers walk without running one. For tree or main it exits through need_root when it walks."

**Location:** `scripts/lib/dev-cycle-read.sh:1872-1880`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** lib maintainer; callers floor and check_fix
**Scope:** Covers return codes, TRUTH_WHY and both callers' ordering. The "~1 ms" figure is Claim 17.

The code is at `:1882-1886`. In P4: `upper: 0 imported`, `lower: 1 []`, `a: 0 imported`, `bogus: 0 walk` (fcf1-probe.log). Both callers run truthrule first. floor does at `:1929` (`if truthrule "$lp"`, with the case word at `:1935`). check_fix does at `scripts/dev-cycle.sh:181`, on a path lowered at `:180`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1881-1887`, `scripts/lib/dev-cycle-read.sh:1929-1942`, `scripts/dev-cycle.sh:176-189`, fcf1-probe.log (P4)

---

## Claim 17: "(isimported's lower and root check cost floor ~1 ms a path: U2c1 final performance 1)"

**Location:** `scripts/lib/dev-cycle-read.sh:1874-1875`
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** performance reviewer
**Scope:** Covers the magnitude of `need_root` plus `lower` per call on this host. It does not establish the cited report's own figure under its own load.

Probe 2 timed 200 calls of `need_root; x="$(lower docs/x.md)"` at 2.17 ms per call (fcf1-probe2.log). The cited report puts need_root at 2.17 ms per four calls, about 0.54 ms each, and two lowers at most of 5.7 ms (`docs/reviews/performance-review-2026-10-10-u2c1-final.md:40,55`). Both put isimported's pair nearer 2-3 ms than 1 ms. The mechanism (a fork and a root check per path) is right, but "~1 ms" understates it by about 2x here, and the figure depends on load.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1834-1840`, `docs/reviews/performance-review-2026-10-10-u2c1-final.md:40-57`, fcf1-probe2.log

---

## Claim 18: prompt_marks doc: "F is an absolute queue entry the associative array PDIR holds, ...: a // one (a dangling prompt link), or a live one, when its real path differs and lies below a reader root (...; OUT also holds the target's own names, marked too, an over-read only); any other returns 0 unmarked (the projection of a link out of every root ... holds no repo name; its target's own names are read plain ...). ... It returns 1 when lower or realpath fails."

**Location:** `scripts/lib/dev-cycle-read.sh:1373-1389`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** security reviewer / lib maintainer
**Scope:** Covers the live-entry gate, the root test and the return codes. It does not establish whether a live link whose real path equals a reader root itself (not below it) should be marked. The test is strict `"$p"/*`.

The gate is at `:1393-1396`: `b="$(realpath -e -- "$l")" || return 1; [[ "$b" != "$l" ]] || return 0` and `while IFS= read -r p; do [[ "$b" != "$p"/* ]] || in=1; done <<<"$IMPORT_ROOTS"; [[ -n "$in" ]] || return 0`. The loop at `:1399-1404` marks every non-absolute name in OUT, including the target's own names. In P8, with HEAD's lib, an out-of-root link gave `out.md: none` and an into-root link gave `in.md: docs/a.md`. With ac078bd7's lib both were marked (fcf1-probe.log).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1390-1405`, fcf1-probe.log (P8)

---

## Claim 19: outside_seeds doc: "Items (1) and (2) are config_seeds', (3) is c1_seeds' (rows 582, 589), and each keeps its own keep-rule. It returns 1 when either does, or a seed's path holds a newline. Run it after import_readers (IMPORT_ROOTS, IMPORT_CONFIGS and IMPORT_OTHER). NAME must not be one of the three functions' locals (a nameref to one reads that local)."

**Location:** `scripts/lib/dev-cycle-read.sh:1438-1447`
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** a future third caller of outside_seeds
**Scope:** Covers the split, the return conditions, the globals read and the newline check. It does not establish item (1)'s older text about "a dangling link kept", which this diff did not change.

`:1443-1447`: `local -n ow_a="$1"; local ow_d`, then `config_seeds "$1" || return 1; c1_seeds "$1" || return 1`, then `for ow_d in "${ow_a[@]}"; do [[ "$ow_d" != *$'\n'* ]] || return 1; done`. config_seeds reads `IMPORT_ROOTS` and `IMPORT_CONFIGS` (`:1453`). c1_seeds reads `IMPORT_OTHER` and `ROOT_REAL` (`:1509-1515`). Each has its own keep-rule: config_seeds at `:1498-1501` (an @, or a real path that differs and lies below a root), c1_seeds at `:1526-1531` (an @ or a link, minus the rawfile skip). Both walks pass `sd`, which is not a local of any of the three.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1443-1533`, `scripts/lib/dev-cycle-read.sh:1643`, `scripts/lib/dev-cycle-read.sh:1746`

---

## Claim 20: "config_seeds NAME: array NAME gets outside_seeds' items (1) and (2). It returns 1 when a find, grep, realpath or lower_all fails."

**Location:** `scripts/lib/dev-cycle-read.sh:1448-1449`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** lib maintainer
**Scope:** Covers every `return 1` in config_seeds. It does not establish a python3 failure on installed_plugins.json, which falls back to the cache dir (`:1474`) rather than failing, as on main.

The function clears the array (`os_a=()` at `:1452`). Its returns are at the find lists (`:1477`, `:1478`, `:1480`, `:1487`), lower_all (`:1488`), with_at's grep (`:1494`) and the xargs realpath (`:1497`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1450-1503`

---

## Claim 21: "c1_seeds NAME: appends outside_seeds' item (3), C1, to array NAME: each other root's start files (IMPORT_OTHER) that hold an @ byte or are links, but the ones its skip names. It returns 1 when a find, grep or lower_all fails."

**Location:** `scripts/lib/dev-cycle-read.sh:1504-1506`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** lib maintainer
**Scope:** Covers append semantics, the keep-rule and the returns. It does not establish the skip's correctness, which is unchanged code moved from outside_seeds.

There is no clear (`local -n c1_a="$1"` at `:1508`, no `c1_a=()`), and the keep at `:1531` is `c1_a+=(...)`, so it appends. The keep-rule is at `:1526`: `isstart "${lo[i]}" && [[ -n "${c1_at[${cx[i]}]+set}" || -L "${cx[i]}" ]] || continue`. Its returns are root_starts (find|grep, `:1514`), lower_all (`:1522`) and with_at (`:1523`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1507-1533`

---

## Claim 22: IMPORT_CONFIGS as outside_seeds reads it gives main's config dirs (3111ee9d: "outside_seeds reads it"; the walks unchanged in result)

**Location:** `scripts/lib/dev-cycle-read.sh:1453`; main's `outside_seeds` (diff lines 298-301)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** reviewer of the refactor
**Scope:** Covers equivalence for this repository and the static mapping. It does not establish equivalence under a HOME holding a newline, where both read it as empty.

Main built `cf` from `mapfile -t fl <<<"$IMPORT_HOMES"` and `for d in "${fl[@]}"; do [[ "$d" != /* ]] || cf+=("${d%/}/.claude"); done; [[ -z "${CLAUDE_CONFIG_DIR:-}" ]] || cf+=("$CLAUDE_CONFIG_DIR"); cf+=("$IMPORT_MANAGED_DIR")`. HEAD iterates the same `rs_h` array that `IMPORT_HOMES` is printed from (`:1197-1199`). Probe 3 ran both walks over the review worktree, with CLAUDE_CONFIG_DIR set, under main's lib and HEAD's lib. Each gave 1593 names, and the lists were byte-equal across libs and across walks (fcf1-probe3.log).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1196-1199`, `scripts/lib/dev-cycle-read.sh:1450-1453`, fcf1-probe3.log

---

## Claim 23: floor doc: "$4, optional, $1 lower-cased (build-loop.sh passes it, so floor forks no lower ...; floor then reads only $4, so the two must agree; an upper-case letter in it refuses as case)"

**Location:** `scripts/lib/dev-cycle-read.sh:1908-1911`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** a floor caller
**Scope:** Covers $4's use and the case refusal. It does not establish behavior when $4 is a different path from $1. Floor then judges $4 alone, as the doc warns.

After `:1926-1928`, `$1` is not read again: every later test uses `$lp`. The upper-case case reaches truthrule's `case` word, which floor words "the path could not be lower-cased" (`:1935`). The bats test "floor given the lowered path ..." passes, including `C: the path could not be lower-cased` for `Docs/C.md` passed as $4 (fcf1-bats.log).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1925-1952`, `test/scripts/build-loop-check.bats:685-694`, fcf1-bats.log

---

## Claim 24: floor doc: "a path below a start file's name or an imported .md name is refused too (a directory there keeps the file from being created ...)"; inline: "not any import's: the parser's prefixes make every directory an import passes through one"

**Location:** `scripts/lib/dev-cycle-read.sh:1914-1916`, `scripts/lib/dev-cycle-read.sh:1946`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** security reviewer / floor maintainer
**Scope:** Covers the loop over every ancestor, the .md restriction and the prefix rationale. It does not establish a path below a non-.md import name (`@docs/notes`), which a settled override row of 2026-10-10 leaves out.

In P9, `docs/a.md/x` (imported), `src/agents.md/z` (a start name) and `docs/A.md/x` were refused, while `docs/a.mdx/y` and `docs/x/y` were not (fcf1-probe.log). P5 printed the main walk's list for `@docs/new.md`, which holds `do doc docs docs/n docs/ne docs/new ... docs/new.md` (fcf1-probe5.log). This confirms that every directory on an import's path is itself an import name. The loop runs only after truthwalk returned 1, which means the walk succeeded (Claim 25).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1945-1951`, `test/scripts/build-loop-check.bats:677-683`, fcf1-probe.log (P9), fcf1-probe5.log

---

## Claim 25: walk_has: "whether the list of the walk WALK names ..., as its last call left it, holds LP, a lower-cased path: no fork. Ask it only after that walk succeeded (contract item 6: an error list holds nothing)", and every caller complies

**Location:** `scripts/lib/dev-cycle-read.sh:1841-1847`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** lib maintainer adding a walk_has caller
**Scope:** Covers all three callers. It does not establish that contract item 6's caller-facing rule ("only through isimported or truthwalk") lists floor's internal use. Floor is lib code, not a caller.

The body is a nameref and one `[[ == ]]`, with no `$(...)` and no external command. Each caller asks only after a successful walk. isimported runs `main_imports || return 0` first (`:1838`). truthwalk runs `main_imports || return 0` first (`:1883`). floor's loop is in the `else` of `elif truthwalk main "$lp"`, reached only when truthwalk returned 1, which follows a successful walk (`:1942-1948`). Every caller passes a lowered path: isimported's `lp` (`:1837`), truthwalk's upper-case guard (`:1885`), and floor's `d`, cut from the lowered `lp`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1834-1847`, `scripts/lib/dev-cycle-read.sh:1881-1887`, `scripts/lib/dev-cycle-read.sh:1942-1951`

---

## Claim 26: floor: "It reads nothing but through main_imports, whose root check runs when it walks, so a call both of main_imports' caches answer ... forks nothing but walk_why's subshell after a failed walk; neither changes within a gate decision."

**Location:** `scripts/lib/dev-cycle-read.sh:1919-1922`
**Type:** Performance / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** performance reviewer / floor caller
**Scope:** Covers cached calls with and without $4 and with a failed walk. It does not establish the cost of the first, uncached call.

The claim holds when $4 is passed. Probe 4 counted 0 forks per 100 cached calls with a passing walk and 1 per call after a failed walk, which is walk_why's `$(...)` (`:1943`). Without $4, floor forks `lower` (`:1928`: `lp="$(lower "$1")"`), about 3 forks per call (300 per 100; fcf1-probe4.log). The sentence is unconditional, and the $4 condition sits only in the preceding paragraph. The precise version would add "given $4".

**Evidence:** `scripts/lib/dev-cycle-read.sh:1919-1952`, fcf1-probe4.log

---

## Claim 27a: Commit 3111ee9d's structural claims: floor "has no root check of its own, truthwalk tests the walk's list itself ..., and main_imports runs need_root below its cache check"; "both walks call it [prompt_marks] for any absolute prompt entry"; config dirs "computed and checked there ..., outside_seeds reads it, and both walk caches key on it; contract item 4 drops the reset duty"; "its C1 part is c1_seeds ... called at its end"; Notes: "floor's root check now runs only when its walk does"

**Location:** commit 3111ee9d message
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** branch history reader
**Scope:** Covers these claims against HEAD's code, all still true. It does not establish one superseded statement. "The import-name half is not taken" was true at 3111ee9d, and 07af69c0 (A8) later took its .md part.

Each claim matches the code at HEAD: Claims 4, 9, 14, 15, 19 and 23, and P1. One detail has changed: "called at its end" now reads as outside_seeds calling c1_seeds second (`:1445`), since config_seeds holds the rest.

**Evidence:** `git log -1 3111ee9d`, `scripts/lib/dev-cycle-read.sh:1443-1447`, fcf1-probe.log

---

## Claim 27b: Commit 3111ee9d: "Measured: a cached floor call 6.5 ms -> 0.61 ms per path (400 paths about 2.6 s -> 0.25 s)"

**Location:** commit 3111ee9d message
**Type:** Performance
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** performance reviewer
**Scope:** Covers the direction and order of the speed-up. It does not establish the exact figures, which depend on load and host.

Probe 3 timed 200 cached floor calls over the review worktree. Main's lib, with no $4, took 9.6 ms per path. HEAD's lib, with $4, took 1.18 ms (fcf1-probe3.log). That is an 8x reduction, against the commit's 10.6x. The exact numbers cannot be reproduced on a shared host. Verifying them would need the author's fixture and an idle host.

**Evidence:** fcf1-probe3.log

---

## Claim 28a: Commit 07af69c0's fix claims: A1 (readers_root; "an unset ROOT_REAL exits again (tested), the registry is never listed from an unchecked directory, and a cached tree walk forks no root check either"), A2 (? rule, tested), A5/A15 (walk_why; unknown KIND worded), A3, A6 (walk_has shared), A8 (tested: docs/new.md/n.txt refuses, docs/ne/x.txt passes), A9, A4/A11-A14; "both walks over this repository give main's 1593 names"

**Location:** commit 07af69c0 message
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** branch history reader
**Scope:** Covers each claim against HEAD. It does not establish A9 as fixed at 07af69c0 itself. It did nothing until 2be3db37 (B1), as that commit and the rubric record.

The unset-ROOT_REAL test is `test/scripts/build-loop-check.bats:672-674`. The `?` test is `:662-666`. The A8 test is `:677-683`, and all pass (fcf1-bats.log). The 1593-name claim was re-run by probe 3: 1593 for both walks under both libs, lists equal (fcf1-probe3.log). The unknown-KIND arm is `:824`: `*) echo "the walk failed (${k:-no reason recorded})"`, and P5 printed `the walk failed (bogus)`.

**Evidence:** `git log -1 07af69c0`, fcf1-bats.log, fcf1-probe3.log, fcf1-probe.log (P5)

---

## Claim 28b: Commit 07af69c0 / rubric A7: "config_seeds plus a three-call outside_seeds wrapper"

**Location:** commit 07af69c0 message; rubric `docs/reviews/code-review-rubric-2026-10-10-feat-build-loop-u2c2.md:58`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** branch history reader
**Scope:** Covers the wrapper's shape. It does not establish anything about its behavior (Claim 19).

The wrapper makes two calls and one check: `config_seeds "$1" || return 1; c1_seeds "$1" || return 1` and then the newline loop (`scripts/lib/dev-cycle-read.sh:1445-1446`). The precise wording is "a two-call wrapper with the newline check".

**Evidence:** `scripts/lib/dev-cycle-read.sh:1443-1447`

---

## Claim 29: Commit 2be3db37: "B1 ...: read empties its variable at EOF, so the A9 test passed every absolute path; a flag now records a root match. New test ... fails on ac078bd7"; "B3: readers_root skips need_root only on a held result, so a memoized refusal from a wrong directory exits"

**Location:** commit 2be3db37 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** branch history reader
**Scope:** Covers B1's mechanism, the fix, the failing-on-old-lib claim and B3. It does not establish the run counts in the commit ("build-loop-check 143 ..."), since only the changed tests were run here.

The old code (`git show 07af69c0:scripts/lib/dev-cycle-read.sh`, prompt_marks) was `while IFS= read -r p; do [[ "$b" != "$p"/* ]] || break; done <<<"$IMPORT_ROOTS"; [[ "$b" == "$p"/* ]] || return 0`. A loop that never breaks leaves `p` empty, and `"/"*` matches every absolute path. P8 with ac078bd7's lib printed `out.md: docs/a.md`. HEAD's lib printed `out.md: none`. B3: see Claim 14 (P3).

**Evidence:** `git log -1 2be3db37`, `scripts/lib/dev-cycle-read.sh:1390-1396`, fcf1-probe.log (P3, P8)

---

## Claim 30: Rubric Fixed statuses A1-A9, A11-A15, B1-B5 (A10, A16 Defer; A17 Accepted-immutable)

**Location:** `docs/reviews/code-review-rubric-2026-10-10-feat-build-loop-u2c2.md:16-28`, `:47-67`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** loop orchestrator / reviewer reading the rubric
**Scope:** Covers each Fixed or Fixed-in-text status against HEAD. It does not establish the rubric's own Status line, which is stamped at ac078bd7 and predates this pass. A7's "three-call" wording is Claim 28b.

Each status matches the code at HEAD:
- A1: Claims 4 and 14.
- A2: Claim 13.
- A3: `:822` names both budgets; `:797-798` says which trips first.
- A4: Claims 7 and 8, and the dev-cycle.bats inventory diff (lines 706, 711).
- A5 and A15: walk_why `:808-826`.
- A6: Claim 25.
- A7: Claim 28b.
- A8: Claim 24.
- A9 and B1: Claim 18.
- A11: floor's doc conditions on both caches, `:1920-1921`.
- A12: the inherit rule at `:800-802`; Claim 10.
- A13: `:1910-1911`.
- A14: Claim 1.
- B2: `:1380-1381`.
- B3: Claim 14.
- B4: `:1921`.
- B5: the seeds sentence at `:820`.

**Evidence:** rubric `:16-28`, `:47-67`; `scripts/lib/dev-cycle-read.sh:792-833`, `:1373-1389`, `:1904-1922`

---

## Claim 31: Commit 3111ee9d: "the new tests fail against main's lib"

**Location:** commit 3111ee9d message
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** branch history reader
**Scope:** Covers the F3 test only, re-run here against main's lib. It does not establish the other new tests against main's lib.

Probe 2 reproduces the F3 test's scenario. Main's lib answers `top.md: -` for both walks, where the test wants `imported`, so that test fails on main (fcf1-probe2.log). The remaining new tests were not re-run against main's lib in this pass. The iteration-1 rubric records that a fact-check did so (rubric `:79`). Verifying them all would need each bats test run with `LIB` pointed at main's lib.

**Evidence:** fcf1-probe2.log, rubric `:79`

---

Settled and not re-filed: 3111ee9d's "5 new" and "266 changed code lines" (override row, Accepted-immutable; the last rows of `docs/reviews/override-log.md`). The basis has not changed.

## Claims Requiring Attention

### Incorrect
None.

### Stale
None.

### Mostly Accurate
- **Claim 3** (`scripts/lib/dev-cycle-read.sh:18-21`): floor exits through need_root only for a path that reaches its walk. Earlier floor rules refuse with ROOT_REAL unset and never exit. Add "when they walk".
- **Claim 12** (`scripts/lib/dev-cycle-read.sh:819`): the start/admit sentence omits non-searchable directories and ancestors main stores as a link or gitlink.
- **Claim 17** (`scripts/lib/dev-cycle-read.sh:1874-1875`): "~1 ms" for isimported's lower and root check. Measured about 2.2 ms here, and the cited report implies 2-3 ms.
- **Claim 26** (`scripts/lib/dev-cycle-read.sh:1919-1922`): "forks nothing" holds only when $4 is passed. Without it a cached call forks lower, about 3 forks.
- **Claim 28b** (commit 07af69c0; rubric A7): the "three-call" outside_seeds wrapper makes two calls and a newline check.

### Unverifiable
- **Claim 27b** (commit 3111ee9d): the 6.5 → 0.61 ms figures. Reproduced here as 9.6 → 1.18 ms (8x). Exact values need the author's fixture and an idle host.
- **Claim 31** (commit 3111ee9d): "the new tests fail against main's lib". Re-run only for the F3 scenario, which fails on main as claimed. The rest need each test run against main's lib.

## Goal-Alignment Note

The goal is to land U2c2 after a clean review-fix loop. This pass found no Incorrect or Stale claim. All five Mostly-accurate items are wording-level and fail closed: no refuted mechanism, no behavior gap. The items U2c2 took up are each confirmed by execution against the code:
- Floor's per-path cost: 0 forks on a cached call with $4.
- IMPORTED_MAIN_WHY: every `return 1` reports its stage, and walk_why's `?` rule holds.
- The below-a-name refusal.
- F3 for both walks: main's lib fails probe PC, HEAD's lib passes.
- Config dirs in the keys.
- The c1_seeds split: both walks give main's 1593 names, byte-equal.
- B1: the A9 fix now works, and the old lib fails the new test.

## Escalations

- **security-reviewer:** (a) As Claim 3 shows, floor with ROOT_REAL unset refuses truthrule, gate and working or review paths without exiting. This fails closed, but a caller that relied on floor to detect an unset root gets refusals, not an exit. Confirm that this is acceptable. (b) walk_why still prints `IMPORT_READER_WHY` and absolute host paths unfiltered when their characters pass. This is settled as B6 and noted, not re-filed.
- **performance-reviewer:** the cached per-path cost depends on $4 (0 forks with it, about 3 without). Only build-loop.sh calls floor, and it passes $4, but the doc's unconditional "forks nothing" (Claim 26) could mislead a second caller. The walk_has glob cost is a settled Defer.
- **api-consistency-reviewer:** contract item 6 still says "Read a walk only through isimported or truthwalk", while floor (lib-internal) calls walk_has directly. This is consistent for external callers. Check whether item 6 should name walk_has as the lib's own reader. The header's exit sentence (Claim 3) is caller-facing.
- **architecture-review:** no new structural claim was refuted. Floor's direct read of IMPORTED_MAIN_WHY (rather than through truthwalk) is a settled Defer row.
