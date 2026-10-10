Commit: c69f352f
# Code Fact-Check Report

**Repository:** /workspace (worktree /workspace/.claude/wt-build-loop-u2b3b2c, branch feat/build-loop-u2b3b2c)
**Scope:** Partial (iteration 2): `git diff f7e1bea2..HEAD` (commits 8976fbdf and c69f352f): `scripts/lib/dev-cycle-read.sh`, `test/scripts/build-loop-check.bats`, `test/scripts/dev-cycle.bats`, and both commit messages. f7e1bea2 over main 8e550626 is context only.
**Replication:** k=1 (loop pass, decision 031)
**Checked:** 2026-10-09
**Total claims checked:** 21
**Summary:** 18 verified, 1 mostly accurate, 0 stale, 2 incorrect, 0 unverifiable

I read the hallucination-pattern log (`docs/reviews/hallucination-patterns.md`). The commit's "Suites 286/286", "242 names" and "357 changed code lines" match the logged "specific measured test count" class (the "All 85 tests" and "mode1-equiv 33" entries), so I recounted all three (Claim 19). They hold. No new fabrication pattern turned up: both Incorrect verdicts concern how behaviour is modelled, not symbols that do not exist. The log is unchanged.

Execution provenance for every `executed` claim is in Appendix A. The review rules let me write only this file, so the captured output is reproduced there and not under `docs/reviews/execution-logs/`.

---

## Claim 1: "and, through root_copies, other roots' copies of the names they reach (sha1sum)"

**Location:** `scripts/lib/dev-cycle-read.sh:45-46`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the file header's statement that root_copies reads other roots' copies and uses sha1sum, and the removal of sha1sum from outside_seeds' tool list. It does not establish that the parenthetical tool lists are complete: root_copies and config_seeds also run realpath, which neither list names (it was not listed before either).

sha1sum now runs only in root_copies: `nul_list rl xargs -0r -a <(printf '%s\0' "${hs[@]}") sha1sum -z --` (`scripts/lib/dev-cycle-read.sh:1290`). Neither config_seeds (`:1339-1395`) nor c1_seeds (`:1414-1440`) calls it (paraphrased, no quote available because the claim is that a call is absent, which I checked by grep over both bodies). The copies themselves are read later by the walks through `import_file` → `import_outside` (`:1207`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:42-47`, `:1284`, `:1290`, `:1339-1440`

---

## Claim 2: "nor IMPORT_ROOTS, IMPORT_HOMES, IMPORT_DOTNEST or IMPORT_OTHER: they are import_readers' results, which a cache hit does not recompute"

**Location:** `scripts/lib/dev-cycle-read.sh:95-97` (contract item 9)
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers import_readers setting all four variables and its cache-hit path leaving them untouched. It does not establish that no other function writes them (I did not audit every assignment in the lib beyond import_readers and the sourcing line).

The cache hit returns before the reset line: `if [[ "$IMPORT_READERS_DONE" == "$IMPORT_READERS_KEY" ]]; then [[ -n "$IMPORT_ROOTS" ]]; return; fi` and then `IMPORT_READERS_DONE="$IMPORT_READERS_KEY"; IMPORT_ROOTS=""; IMPORT_HOMES=""; IMPORT_DOTNEST=""; IMPORT_OTHER=""` (`:1098-1099`). So a value a caller sets survives every cache hit. All four are written later in the same function (`:1128` for IMPORT_OTHER; `:1138-1145` for the others).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1092-1145`

---

## Claim 3: "root_copies batches the same test: change the two together."

**Location:** `scripts/lib/dev-cycle-read.sh:162`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the equivalence of rawfile's test (`-f`, then `realpath -e` equal to `$ROOT_REAL/$1`) with root_copies' batched form on the ROOT_REAL side. It does not establish that no third copy of the test exists elsewhere (main_checkout calls rawfile itself and does not duplicate it).

rawfile: `[[ -n "${ROOT_REAL:-}" && -f "$1" ]] && r="$(realpath -e -- "$1" 2>/dev/null)" && [[ "$r" == "$ROOT_REAL/$1" ]]` (`:163`). root_copies: `[[ -f "${ps[i]}" && "${rl[i]}" == "$ROOT_REAL/${ps[i]}" && "${rl[n + i]}" == "${cs[i]}" ]]` over a `realpath -mz` batch (`:1284-1286`). Once `-f` holds, the file exists, so `-m` and `-e` give the same path.

**Evidence:** `scripts/lib/dev-cycle-read.sh:163`, `:1283-1288`

---

## Claim 4: imported_names "returns 1 … when the start listing (…), outside_seeds, root_copies, prompt_marks, lower, a file read, … fails"

**Location:** `scripts/lib/dev-cycle-read.sh:687-689`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the three newly listed failure sources in imported_names. It does not re-verify the list's older entries.

`outside_seeds sd || return 1` (`:1550`), `root_copies cq cmp pdir "${queue[@]}" || return 1` (`:1559`), and `outside_proj out work && { [[ "$f" != //* || -z "${pdir[$f]+set}" ]] || prompt_marks pdir out; } || { IMPORTED=error; return 1; }` (`:1569`). The in-loop root_copies call at `:1581` also fails the walk. IMPORTED is already `error` (set at `:1538`) before the first two of these can fail.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1531-1582`

---

## Claim 5: "a prompt's projected names are read as prompts (prompt_marks; one the walk already read is not read again, and one main stores as a symlink fails the main walk, as a symlinked prompt start does)"

**Location:** `scripts/lib/dev-cycle-read.sh:754-757`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the prompt mark that prompt_marks adds, the already-read exception, and the main walk failing on a projected prompt name that main stores as a symlink. It does not establish that "read as prompts" uses the bases a session reading the link would use (see Claim 9b: it does not when the link sits under a nested `.claude/`).

A mark is added only for a name PDIR lacks: `[[ -z "$p" || "$p" == /* || -n "${pm_p[$p]+set}" ]] || pm_p[$p]="$(lower "$p")"` (`:1307`). A name already in `seen` is not queued again (`:1578`, `:1706-1709`), so it is never re-read as a prompt. The main walk's link arm refuses any prompt: `[[ ${#xs[@]} -eq 0 ]] || { IMPORTED_MAIN=error; return 1; }` (`:1670`). xs is never empty for a marked name, because prompt_bases starts with `pb_a=("")` (`:672`). Executed (Appendix A, E5): side holds a dangling `.claude/commands/k.md` → `../../docs/t.md`, and main stores `docs/t.md` as a symlink. Output: `main rc=1 IMPORTED_MAIN=error`, `tree rc=0`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:670-679`, `:1304-1309`, `:1668-1670`, `:1696-1712`; Appendix A E5

---

## Claim 6: "Any seed listing find, grep or realpath cannot complete, or a root_copies realpath or sha1sum, fails the walk"

**Location:** `scripts/lib/dev-cycle-read.sh:766-767`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the propagation of those tool failures to a walk failure. It does not cover lower_all or python3 failures. A python3 failure falls back to listing the cache rather than failing.

config_seeds' finds, with_at and realpath each end in `|| return 1` (`:1366-1389`). c1_seeds' `nul_list fl root_starts "$r" || return 1` (`:1422`). root_copies' two xargs batches each carry `|| return 1` (`:1284`, `:1290`). Each walk turns these into its own failure (Claim 4, Claim 15).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1367-1395`, `:1414-1440`, `:1270-1297`

---

## Claim 7: "root_copies costs 66 ms per walk over 7 other roots here, and about 11 ms per copy it reads"

**Location:** `scripts/lib/dev-cycle-read.sh:775-777`
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers root_copies' own time per walk on /workspace's current registry (7 other roots). The 11 ms per copy is the i1 performance review's measurement. My stub comparison is consistent with it but too noisy to pin it down. This claim does not establish the cost on any other registry.

The function is wrapped with `$EPOCHREALTIME` accumulation (Appendix A, E3). Three runs gave tree 61/59/61 ms and main 69/70/66 ms, over 31 calls with 4 copies returned per walk. IMPORT_OTHER has 7 lines. With root_copies stubbed to return nothing, the walks were 60-160 ms faster (E3b). That fits 66 ms plus about 4 × 11 ms of copy reads, though the load noise is of the same order. The 11 ms figure appears as "Each extra read costs about 10-12 ms" (`docs/reviews/performance-review-2026-10-09-u2b3b2c-i1.md:29`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:775-777`; `docs/reviews/performance-review-2026-10-09-u2b3b2c-i1.md:19,29`; Appendix A E3

---

## Claim 8: root_copies' header: Q cleared; rawfile's test "on both sides"; the // form; PDIR marking incl. the // form; batched rawfile test; xargs batches; return-1 list; A5-class not-covered; the cost sentence ("one read per distinct bytes would miss a .. name that leaves its root, which resolves differently in each")

**Location:** `scripts/lib/dev-cycle-read.sh:1248-1269`
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each clause listed against root_copies' body (`:1270-1297`) and against how the walks read a returned copy. It does not establish that the equal-bytes skip is lossless. The parenthetical "(the walks read ROOT_REAL's file, or main's …)" is true as stated, but the test comment's stronger claim that the skipped copy "could add nothing" fails for a prompt copy in a root nested under a `.claude/` (Claim 16).

- **Q cleared:** `rc_q=()` comes before `[[ -n "$IMPORT_OTHER" ]] || return 0` (`:1272-1273`). Both callers' `cq=()` were dropped (`:1581`, `:1711`).
- **Skips and CMP:** `[[ -n "$p" && "$p" != /* && -z "${rc_c[$p]+set}" ]] || continue; rc_c[$p]=1` (`:1276`). A `//` name starts with `/`, so it is skipped.
- **Both sides:** the condition at `:1286` (quoted in Claim 3) requires ROOT_REAL's name to pass rawfile's test, and requires the copy's real path to equal `"${cs[i]}"`. outside_ok has already required `-f` on the copy (`:1278`). Only then are the bytes hashed and compared (`:1290-1291`). The A2 test is red on f7e1bea2's lib (Claim 17).
- **// form:** `elif [[ -L "$r/$p" ]]; then qs+=("/$r/$p"); qn+=("$p"); fi` (`:1279`). Deleting this line makes the "chains there" test fail (Claim 17, mutant M1).
- **PDIR marking:** `[[ -z "${rc_p[${qn[i]}]+set}" ]] || rc_p[${qs[i]}]="$(lower "${qs[i]}")" || return 1` (`:1294`) runs over every queued entry, the `//` form included.
- **Batched, xargs, return 1:** `nul_list rl xargs -0r -a <(printf '%s\0' "${ps[@]}" "${cs[@]}") realpath -mz -- && [[ ${#rl[@]} -eq $((2 * n)) ]] || return 1` (`:1284`). The sha1sum batch follows the same shape at `:1290`, and lower's failure returns 1 at `:1294`.
- **A5 class:** a copy below a dangling linked directory fails both outside_ok and `-L` on the leaf, so neither arm at `:1278-1279` takes it (paraphrased, no quote available because this follows from two tests together: `-f` and `-L` both false on a path whose parent link dangles).
- **Cost sentence:** a copy is read through import_outside with its absolute directory (`a="$(capped_read < "$1" | import_targets "${d:-/}" "${@:2}")"`, `:1197`). The parser joins an absolute directory as-is and does not join it under every root: `if (substr(dirs[i], 1, 1) == "/") put(dirs[i] "/" c); else for (r = 1; r <= nr; r++) put(roots[r] "/" dirs[i] "/" c)` (`:903`). A copy's relative names are therefore resolved against its own directory only. A `..` that leaves root A resolves under A's parent, and the same bytes in root B resolve under B's parent, so one read per distinct bytes would miss the other. The claim holds. Nested roots and absolute prompt bases make the name sets differ too (Claim 16), so `..` is not the only cause, but the sentence does not say it is.
- **13 s figure:** the i1 performance table lists W=8 other roots, 12.7-13.4 s tree and 13.0-13.9 s main, with 50 differing files (`docs/reviews/performance-review-2026-10-09-u2b3b2c-i1.md:26`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1197`, `:1248-1297`, `:903`, `:1581`, `:1711`; Appendix A E4 (M1)

---

## Claim 9a: prompt_marks "each repo name in the variable OUT that PDIR lacks is added to it, lower-cased … A name already read is not read again as a prompt: a named exception. It returns 1 when lower fails."

**Location:** `scripts/lib/dev-cycle-read.sh:1298-1303`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what prompt_marks marks and when the walks call it (only after a `//` entry PDIR holds). It does not establish the bases those names are then read against (Claim 9b).

The body is quoted in Claim 5 (`:1307`). It skips empty and `/`-led lines, so only repo names are marked. Both walks call it only for a marked `//` entry: `[[ "$f" != //* || -z "${pdir[$f]+set}" ]] || prompt_marks pdir out` (`:1569`, `:1696`). Seeds keep their mark as `//` entries because the old `|| "$p" == //*` exemption was removed (`:1554`, `:1649`). The new test "a dangling prompt link in another worktree reads its target as a prompt" passes on HEAD and is red on f7e1bea2's lib with `top.md: -` (Appendix A, E2).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1304-1309`, `:1550-1555`, `:1569`, `:1645-1650`, `:1696`; Appendix A E2

---

## Claim 9b: prompt_marks marks names "so the walk reads it as a prompt, as a session reads the link's target"

**Location:** `scripts/lib/dev-cycle-read.sh:1300-1301`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a dangling prompt link in another root under a nested `.claude/` (`sub/.claude/commands/k.md`). It establishes that the walk resolves the projected target against bases derived from the target's own repo path, not the link's path. It does not establish how Claude Code itself resolves a symlinked command's names. The comparison is with the lib's own model, which treats the same link when it is live differently.

A marked name is read with `prompt_bases xs "${pdir[$f]}" "$f"` (`:1564`, `:1660`), where `$f` is the projected target (for example `docs/t.md`). prompt_bases adds a base only for each `.claude` component in that path (`[[ "$c" != .claude || $n -eq 0 ]] || pb_a+=("${3:0:n-1}")`, `:676`). The `sub/` base that the link's path `sub/.claude/commands/k.md` gives a session is lost. Executed (Appendix A, E6): side holds the dangling link `sub/.claude/commands/k.md` → `../../../docs/t.md`, and ROOT_REAL holds `docs/t.md` (`t: @top.md`), `top.md` and `sub/top.md`. Both walks print `docs/t.md top.md` and miss `sub/top.md`. When side also holds `docs/t.md`, so the link is live, both walks print `docs/t.md sub/top.md top.md`, because the live seed is read at its own path with prompt bases from that path (import_outside at `:1197`). The dangling route is therefore narrower than the live one, and a missed name here is a missed import for the floor, which fails open. This residual is not among those named in override-log row "A dangling prompt link's projected name…" (already read plain; symlink on main). For the comment to be accurate, it should state that names resolve against the target path's own bases, and name the nested-`.claude` link case as an exception. Alternatively, prompt_marks could carry the link's bases.

**Evidence:** `scripts/lib/dev-cycle-read.sh:670-679`, `:1298-1309`, `:1564`, `:1660`, `:1197`; Appendix A E6

---

## Claim 10: outside_seeds "config_seeds', then c1_seeds'. It returns 1 when either does, or a seed's path holds a newline."

**Location:** `scripts/lib/dev-cycle-read.sh:1310-1315`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the wrapper's order and its failure conditions. Seed equality with f7e1bea2 is Claim 18.

`config_seeds os_a || return 1; c1_seeds os_c || return 1; os_a+=("${os_c[@]}"); for d in "${os_a[@]}"; do [[ "$d" != *$'\n'* ]] || return 1; done` (`:1319-1322`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1316-1323`

---

## Claim 11: config_seeds' comment (seed sources; "Only a seed holding an @ byte, or whose real path differs and lies below a reader root … can yield a name"; returns 1 on find, grep, realpath, lower_all, relative CLAUDE_CONFIG_DIR)

**Location:** `scripts/lib/dev-cycle-read.sh:1324-1338`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the keep rule and the failure list against the body. It does not re-verify the seed-source enumeration, which moved unchanged from f7e1bea2.

The keep rule: `in=""; [[ -z "${cs_at[${cx[i]}]+set}" ]] || in=1` then `[[ -n "$in" || "${rl[i]}" == "${cx[i]}" ]] || for q in "${rs[@]}"; do [[ "${rl[i]}" != "$q"/* ]] || in=1; done` (`:1391-1392`). Failures: `[[ -z "${CLAUDE_CONFIG_DIR:-}" || "$CLAUDE_CONFIG_DIR" == /* ]] || return 1` (`:1342`), and each find, lower_all, with_at and realpath call carries `|| return 1` (`:1366-1389`). A python3 failure takes the fallback branch (`:1365-1366`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1339-1395`

---

## Claim 12: c1_seeds' comment ("holds an @ byte or is a link"; skip rule; "both walks start at that file and pass it to root_copies, which reads this copy when its bytes differ"; returns 1 on find, grep, lower_all)

**Location:** `scripts/lib/dev-cycle-read.sh:1396-1413`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the keep and skip rules and the claim that root_copies reads a skipped seed's copy when the bytes differ. It does not cover a checkout that is not clean, which the comment names as an exception.

Keep: `isstart "${lo[i]}" && [[ -n "${c1_at[${cx[i]}]+set}" || -L "${cx[i]}" ]] || continue` (`:1434`). Skip: `[[ ! -L "${cx[i]}" && "$q" == "$c" ]] && isstart "$d" && rawfile "${ir[i]}" || c1_a+=("$c${cx[i]}")` (`:1439`). On the copy side, find -P does not enter linked directories and the root is a real path, so the copy passes rawfile's test there too. root_copies then compares only the bytes (paraphrased, no quote available because this combines root_starts' `find -P` at `:1235` with IMPORT_OTHER holding realpath output at `:1128`). In the fixture (Appendix A, E1), side's differing `AGENTS.md` is not a seed, and the walks read it through root_copies. The i1 test "chains there" exercises the same path and passes.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1414-1440`, `:1235`, `:1128`; Appendix A E1

---

## Claim 13: "rawfile, not -f, on ROOT_REAL's copy: one reached through a link there is no walk start (U2b3b2b i1 fact-check 19b)."

**Location:** `scripts/lib/dev-cycle-read.sh:1436` (commit c69f352f)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers which of ROOT_REAL's copies each walk starts at. The choice of rawfile is right either way: a link means no skip, so the seed is kept. Only the reason given is too broad.

In the tree walk it holds: a start needs `inrepo_here "$f"` (`:1544`), which fails on any link on the way. The text c69f352f replaced said "the tree walk does not start at". The new "no walk start" also covers the main walk, where a start that main stores as a symlink (mode 120000) is queued as a start: `seen[$f]=1; if [[ -n "${ent[$f]+set}" ]]; then queue+=("$f")` (`:1640`), and it is read in the `120000)` arm (`:1668`). A more precise wording would be "the tree walk does not start at it, and the main walk starts at it only as a symlinked start, whose copy root_copies reads anyway since rawfile's test fails".

**Evidence:** `scripts/lib/dev-cycle-read.sh:1436-1439`, `:1538-1546`, `:1633-1642`, `:1668-1691`; `git show c69f352f`

---

## Claim 14: "c1_seeds skips another root's start that has the same kind here only because every start passes through here, pdir already set."

**Location:** `scripts/lib/dev-cycle-read.sh:1556-1558`, `:1651-1653`
**Type:** Architectural / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers both walks: every ROOT_REAL file that c1_seeds' skip relies on (rawfile, isstart on the same lower-cased path, same prompt kind) is in the list passed to the first root_copies call, with pdir set by the same PROMPT_DIR test. It does not cover an untracked nested repo or a checkout that is not clean (named exceptions).

Tree walk: the starts come from tree_starts, filtered by `isstart "$lp"` and `inrepo_here "$f"`, with `prompt_dir pdir "$lp" "$f"` (`:1544-1547`), and then `root_copies cq cmp pdir "${queue[@]}"` (`:1559`). rawfile implies inrepo_here, since blocker uses the same plain tests (`:174-186`). Main walk: every isstart candidate, from main's tree or the checkout, goes to queue or tq with prompt_dir set (`:1633-1642`), and then `root_copies cq cmp pdir "${queue[@]}" "${tq[@]}"` (`:1654`). c1_seeds tests the kind with the same `$PROMPT_DIR` match on the lower-cased inner path (`:1438`) that prompt_dir uses (`:664`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1531-1560`, `:1602-1655`, `:1436-1439`, `:664`

---

## Claim 15: main_imports' failure list ("outside_seeds, root_copies or prompt_marks fails") and the tq note ("outside seeds, // imports and other roots' copies, and //PATH entries, dangling links outside_proj projects")

**Location:** `scripts/lib/dev-cycle-read.sh:1591`, `:1598-1601`
**Type:** Error-handling / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the new list entries and what tq receives. It does not re-verify the older entries.

`outside_seeds sd || return 1` (`:1645`), `root_copies … || return 1` (`:1654`, `:1711`), and prompt_marks inside the `|| { IMPORTED_MAIN=error; return 1; }` chain (`:1696`). tq receives seeds (`:1649`), `//` imports (`:1704`), copies (`:1655`, `:1712`), `//PATH` entries (the seed loop at `:1647-1649` and root_copies' `//` form), and checkout files main lacks (`:1709`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1591-1601`, `:1645-1655`, `:1696-1713`

---

## Claim 16: "(A plain copy with equal bytes is skipped as a cost: the parser already resolves this checkout's relative names against every root, so reading it could add nothing.)"

**Location:** `test/scripts/build-loop-check.bats:777-778`
**Type:** Behavioral / Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers whether a skipped byte-equal plain copy's names are always a subset of ROOT_REAL's file's names. Plain relative, absolute and `~/` names are a subset. A prompt copy in a root nested under a `.claude/` component whose parent is no reader root is not. The claim does not establish that this layout occurs on /workspace, where every worktree sits under `/workspace/.claude/` and `/workspace` is itself a reader root, so the subset holds there.

The mechanism holds for plain names. ROOT_REAL's file is read with a relative directory, which the parser joins under every root (`:903`, quoted in Claim 8). The copy's absolute directory `/R/d` is one of those joins, because IMPORT_ROOTS holds each root's real path (`:1128-1132`). Absolute and `~/` names do not depend on the reading file. It does not hold for prompt bases. A copy of a prompt is marked by its absolute path (`:1294`), so `prompt_bases xs "${pdir[$f]}" "$f"` (`:1564`) adds a base for every `.claude` component in the root's own path (`pb_a+=("${3:0:n-1}")`, `:676`). ROOT_REAL's relative name never has those components. Executed (Appendix A, E7): main at `B/m`, a worktree at `B/h/.claude/wt`, and both hold `.claude/commands/k.md` = `k: @z.md`, with `B/h/z.md` present. With equal bytes the tree walk prints no `//…/h/z.md` line (0). With one extra blank line in the copy it prints 1. Reading the byte-equal copy would therefore add a name, and the skip loses it. If that outside file held `@` imports of repo names, they would be missed. The comment needs this qualification: "for a plain (non-prompt) name, or a root not nested under a `.claude/` below no root".

**Evidence:** `test/scripts/build-loop-check.bats:776-784`; `scripts/lib/dev-cycle-read.sh:670-679`, `:903`, `:1286-1294`, `:1564`; Appendix A E7

---

## Claim 17: The new tests are red on f7e1bea2's lib (rubric A1, A2), and the dangling-copy branch is now tested (A3: "the deleting mutant now fails")

**Location:** `test/scripts/build-loop-check.bats:761-795`; `docs/reviews/code-review-rubric-2026-10-09-feat-build-loop-u2b3b2c.md` (A1-A3)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two new tests' results on f7e1bea2's lib and the root_copies `//`-branch mutant against the modified "chains there" test. It does not establish that the PDIR marking of root_copies' `//` form (`:1294` on a `//ROOT/NAME` entry) is exercised: the new prompt-link test goes through the seed route, not root_copies. I did not run a mutant on that branch.

E2 ran on a copy of the worktree with f7e1bea2's lib (Appendix A). "a copy with this checkout's bytes under a linked directory is read…" failed (`want: real/x.md: imported` / `real/x.md: -`). "a dangling prompt link in another worktree…" failed (`want: top.md: imported` / `top.md: -`). The modified "chains there" test passes on the old lib, as expected for a fixture change. E4: deleting `elif [[ -L "$r/$p" ]]; then qs+=("/$r/$p"); qn+=("$p"); fi` (`:1279`) on HEAD makes "chains there" fail with `docs/gone.md: -`.

**Evidence:** `test/scripts/build-loop-check.bats:761-795`; `scripts/lib/dev-cycle-read.sh:1279`; Appendix A E2, E4

---

## Claim 18: "A8 (row 582's trigger): outside_seeds split into config_seeds and c1_seeds behind the wrapper; same seeds."

**Location:** commit 8976fbdf message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers outside_seeds' output under f7e1bea2's lib and HEAD's on /workspace's real registry and on a fixture with config, managed, ancestor and C1 seeds, including a home inside another worktree (one path both a config and a C1 seed). It does not cover a file edited between the two with_at reads, the only way the old shared os_at map could differ from the two maps now.

Before the split, C1 tested `os_at[cx]`, which config's with_at had also filled. A path in both lists gets the same with_at answer, since it is the same file grepped twice. A path only in config's list is never a C1 candidate, so separate maps give the same result (paraphrased, no quote available because the old code is at f7e1bea2 and the argument compares two versions). E1 (Appendix A): /workspace gave the same 9 seeds under both libs (`diff` empty, IMPORT_OTHER 7 lines). The fixture gave identical output under both libs, for HOME unset-like and for HOME=side, the latter producing duplicates `r2.md`, `dl.md` and `live.md` from both halves in the same order.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1316-1440`; `git show f7e1bea2:scripts/lib/dev-cycle-read.sh` (outside_seeds); Appendix A E1

---

## Claim 19: "Suites 286/286 …; both walks over /workspace give main's 242 names. 357 changed code lines."

**Location:** commit 8976fbdf message
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the six suites summing to 286 (build-loop-check 130, dev-cycle 79, build-loop-read 20, fixture-git-env 2, fixture-hermeticity 2, hermeticity-lint 53), the name counts on today's /workspace registry, and the code-line count at 8976fbdf. It does not cover `-j 8` runs; I ran serially, as the review rules require.

E8: build-loop-check plus dev-cycle gave 209/209 ok, and the other four suites gave 77/77 ok (rc=0 both). 209 + 77 = 286. E1: both walks give 242 distinct non-`//` names under HEAD's lib, f7e1bea2's lib and main's lib, with every sorted list identical. Line count: `git diff --numstat main...8976fbdf -- ':(top)' ':(top,exclude)docs/' | awk '{n+=$1+$2} END{print n}'` prints 357 at 8976fbdf. At HEAD the same command prints 359, because c69f352f changes one comment line (+1/−1). The shared brief's "now 357" is two lines stale. The count is still under the ~400 cap.

**Evidence:** Appendix A E1, E8, E9

---

## Claim 20: c69f352f: "the lite check read the moved comment as describing the seed; it describes ROOT_REAL's copy."

**Location:** commit c69f352f message
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers what the replaced comment describes: rawfile is applied to `"${ir[i]}"`, ROOT_REAL's relative path. It does not verify what the lite check's reviewer read, which is not in the tree. The new comment's own wording is Claim 13.

The comment sits above `rawfile "${ir[i]}"` (`:1439`), and rawfile tests `$1` relative to `ROOT_REAL` (`:163`), so the comment describes ROOT_REAL's copy, not the seed `cx[i]`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1436-1439`, `:163`; `git show c69f352f`

---

## Claims Requiring Attention

### Incorrect
- **Claim 9b** (`scripts/lib/dev-cycle-read.sh:1300-1301`) [for-author]: names projected from a dangling prompt link are read with bases from the target's own path. A link under a nested `sub/.claude/` loses the `sub/` base that a live link keeps (executed: `sub/top.md` missed by both walks). This fails open and is not among the named A1 residuals. Name it as an exception, or carry the link's bases.
- **Claim 16** (`test/scripts/build-loop-check.bats:777-778`) [for-author]: "reading it could add nothing" is false for a byte-equal prompt copy in a root nested under a `.claude/` whose parent is no reader root, because of absolute prompt bases (executed: a `//…/h/z.md` name is lost). Qualify the comment. The same exception applies to root_copies' equal-bytes skip.

### Stale
- None.

### Mostly Accurate
- **Claim 13** (`scripts/lib/dev-cycle-read.sh:1436`) [for-author]: "no walk start" overreaches. The main walk starts at a start main stores as a symlink. The replaced text's "the tree walk" was the precise scope.

### Unverifiable
- None.

(Verified claims 1-8, 9a, 10-12, 14-15, 17-20 are tagged [for-orchestrator-synthesis].)

---

## Appendix A: execution provenance

Every run used a scratch copy under `/tmp/fc-u2c-i2-VgIB` (a `cp -a` of the worktree at c69f352f; `old-lib.sh` = `git show f7e1bea2:scripts/lib/dev-cycle-read.sh`, `main-lib.sh` = main's). Every process ran under `timeout`. The scratch dirs were removed afterward.

- **E1** (2026-10-10T05:52Z-05:58Z, cwd `/workspace`, read-only): `timeout 300 bash seeds.sh <lib> /workspace <out>`. The script runs `source lib; ROOT_REAL=$(pwd -P); resolve_main || true; reader_settings; import_readers; outside_seeds sd; imported_names; main_imports`. rc=0 for every lib. Output: `outside_seeds rc=0`, `tree rc=0`, `main rc=0`, `242`/`242` for head, old and main libs. `diff ws-head.seeds ws-old.seeds` was empty (9 seeds), IMPORT_OTHER had 7 lines, and every walk list pair diffed empty. Fixture `timeout 120 bash fx-seeds.sh old-lib.sh head-lib.sh` exited 0 and the outputs were `IDENTICAL`: HOME=home-none gave 10 seeds, HOME=side gave 15, the same lines in the same order under both libs.
- **E2** (05:56Z, cwd `/tmp/fc-u2c-i2-VgIB/wt-old`, old lib swapped in): `TMPDIR=$T timeout 300 bats -f 'chains there|linked directory is read|dangling prompt link in another' test/scripts/build-loop-check.bats`, rc=1. Output: `ok 1 … chains there …`, `not ok 2 a copy with this checkout's bytes under a linked directory …` (`want: real/x.md: imported` / `real/x.md: -`), `not ok 3 a dangling prompt link in another worktree …` (`want: top.md: imported` / `docs/t.md: imported` / `top.md: -`).
- **E3** (05:53Z, cwd `/workspace`): `timeout 200 bash rctime.sh head-lib.sh` ×3, each run rc=0 for both walks. It wraps root_copies to accumulate `$EPOCHREALTIME` deltas. Output: `tree calls=31 copies=4 secs=0.0611832 / 0.0594499 / 0.0605869`, `main calls=31 copies=4 secs=0.0691006 / 0.0696874 / 0.0658617`. **E3b**: seeds.sh with `STUB_RC=1` (root_copies returns empty), alternated ×3, gave unstubbed tree 1.82/1.89/1.81 s against stubbed 1.76/2.85 (outlier)/1.69 s, and main 1.95/2.13/2.03 s against 1.79/2.14/1.89 s (load average 0.70-2.08).
- **E4** (05:57Z, cwd `/tmp/fc-u2c-i2-VgIB/wt-mut`): mutant M1 replaces line 1279's `elif … fi` with `fi`. `TMPDIR=$T timeout 300 bats -f 'chains there' test/scripts/build-loop-check.bats` gave rc=1 with `not ok 1 …` / `want: docs/gone.md: imported` / `docs/gone.md: -`.
- **E5** (05:59Z): `timeout 120 bash fx-symlink.sh head-lib.sh`, rc=0. Output: `main rc=1 IMPORTED_MAIN=error`, `tree rc=0`.
- **E6** (05:58Z): `timeout 120 bash fx-nest.sh head-lib.sh` (dangling `side/sub/.claude/commands/k.md` → `../../../docs/t.md`) printed `tree rc=0 / docs/t.md top.md` and `main rc=0 / docs/t.md top.md`. `fx-nest-live.sh` (side also holds `docs/t.md`) printed `tree rc=0 / docs/t.md sub/top.md top.md` and `main rc=0 / docs/t.md sub/top.md top.md`.
- **E7** (05:58Z): `timeout 120 bash fx-prompt.sh x head-lib.sh` (main `B/m`, worktree `B/h/.claude/wt`, `B/h/z.md`) printed `equal bytes: tree walk names //h/z.md lines = 0` and `differing bytes: tree walk names //h/z.md lines = 1`.
- **E8** (finished 2026-10-10T05:55:20Z, cwd `/tmp/fc-u2c-i2-VgIB/wt`): `TMPDIR=$T timeout 590 bats test/scripts/build-loop-check.bats test/scripts/dev-cycle.bats` gave `1..209`, 209 ok, rc=0. `TMPDIR=$T timeout 590 bats test/scripts/build-loop-read.bats test/scripts/fixture-git-env.bats test/fixture-hermeticity.bats test/hermeticity-lint.bats` gave `1..77`, 77 ok, rc=0.
- **E9** (cwd the scratch copy): the numstat command printed `359` at HEAD (`206 93 scripts/lib/dev-cycle-read.sh`, `56 0 …build-loop-check.bats`, `2 2 …dev-cycle.bats`) and `357` with `main...8976fbdf`.

---

## Goal-Alignment Note

- **Success criterion (verbatim):** "A markdown report saved to /workspace/.claude/wt-build-loop-u2b3b2c/docs/reviews/code-fact-check-report-build-loop-u2b3b2c-i2.md, structured per the code-fact-check skill, with `Commit: c69f352f` as its first line and `**Replication:** k=1 (loop pass, decision 031)` in its header."
- **Answered:** Yes. Every claim in the brief was checked. The iteration-1 fixes A1-A8, M1-M3 and M7 are in place and behave as claimed. The A1/A2 tests are red on f7e1bea2, the A3 mutant fails, the A8 seeds are identical, and the 286/242/357 counts reproduce. Two text claims are Incorrect. Both are narrow fail-open layouts that the comments say cannot happen: a dangling prompt link under a nested `.claude/` loses its `sub/` base (9b), and a byte-equal prompt copy in a root nested under a `.claude/` with no reader-root parent is skipped although it would add a name (16).
- **Out of scope:** code quality and whether to fix the two layouts in code or only name them. That is the critics' and the author's call. f7e1bea2's own claims were reviewed in iteration 1.
- **Escalate:** Claim 9b to security: it is an unnamed residual of i1 security F1, a fail-open. Whether it is a Must Address or a named exception is the orchestrator's decision.
- **Decisions I made:** I verdicted Claim 16 Incorrect rather than Mostly accurate. Its stated conclusion ("could add nothing") is refuted by an executed counterexample, even though its mechanism holds for plain names. I recorded the HEAD line count (359) beside the commit's 357, which is correct for its own commit.
