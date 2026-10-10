Commit: 007e867f
# Code Fact-Check Report

**Repository:** /workspace (worktree /workspace/.claude/wt-build-loop-u2b3b2c)
**Scope:** `git diff main...HEAD` on feat/build-loop-u2b3b2c (HEAD 007e867f, main 8e550626): scripts/lib/dev-cycle-read.sh (changed functions read whole: import_readers, root_copies, prompt_marks, outside_seeds, config_seeds, c1_seeds, with_at, outside_proj, import_outside, import_file, outside_ok, imported_names, main_imports, rawfile, prompt_bases; header contract items 1-9; the walk doc block), test/scripts/build-loop-check.bats (every U2b3b2c test and the C1 test), test/scripts/dev-cycle.bats (inventory), and commit messages f7e1bea2, 8976fbdf, c69f352f and 007e867f. Final confirming pass, replicate r3.
**Checked:** 2026-10-09
**Total claims checked:** 34
**Summary:** 28 verified, 2 mostly accurate, 2 stale, 1 incorrect, 1 unverifiable

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`, 5 entries) read first. No claim matches a logged pattern. The one Incorrect verdict (claim 22) is a causal misstatement in a test comment, not a fabricated symbol, so the log is not updated.

Execution provenance: every executed command below ran as uid node on 2026-10-09 between 23:09 and 23:17 -07:00. Its raw output was captured to files under `/tmp/fcf-r3-u2c-*`. The review rules require those scratch directories to be removed, and I may write no file but this report, so the load-bearing output is copied verbatim into the **Execution appendix** at the end. The appendix is the captured-output reference for every `executed` claim.

---

## Claim 1: "Both walks also read ... and, through root_copies, other roots' copies of the names they reach (sha1sum)"

**Location:** `scripts/lib/dev-cycle-read.sh:42-46`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the claim that root_copies, called by both walks, reads other roots' copies and is the lib's only sha1sum user. It does not establish that the parenthetical tool lists are complete: realpath and xargs are run too, as the outside_seeds list before this branch already left out.

Both walks call it: `root_copies cq cmp pdir "${queue[@]}" || return 1` (`:1567`, imported_names) and `root_copies cq cmp pdir "${queue[@]}" "${tq[@]}" || return 1` (`:1663`, main_imports), plus once per file read (`:1590`, `:1721`). sha1sum appears only in root_copies: `nul_list rl xargs -0r -a <(printf '%s\0' "${hs[@]}") sha1sum -z --` (`:1292`). A grep for `sha1sum` over the lib finds only `:46` and `:1292` besides comments (paraphrased — no quote available because the claim covers the absence of other matches).

**Evidence:** `scripts/lib/dev-cycle-read.sh:42-46`, `:1292`, `:1567`, `:1590`, `:1663`, `:1721`

---

## Claim 2: Contract item 9: "nor IMPORT_ROOTS, IMPORT_HOMES, IMPORT_DOTNEST or IMPORT_OTHER: they are import_readers' results, which a cache hit does not recompute."

**Location:** `scripts/lib/dev-cycle-read.sh:95-98`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the claim that all four variables are set only by import_readers and that its memo hit returns before touching them. It does not establish that no caller sets them, which is a caller obligation.

`if [[ "$IMPORT_READERS_DONE" == "$IMPORT_READERS_KEY" ]]; then [[ -n "$IMPORT_ROOTS" ]]; return; fi` (`:1098`) returns before `IMPORT_ROOTS=""; IMPORT_HOMES=""; IMPORT_DOTNEST=""; IMPORT_OTHER=""` (`:1099`), and the function fills all four afterwards (`:1128`, `:1138-1139`, `:1143-1145`). No other assignment exists apart from the source-time clear at `:1075` (paraphrased — no quote available because the claim covers the absence of other writers, checked by grep).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1075`, `:1092-1146`

---

## Claim 3: "# root_copies batches the same test: change the two together."

**Location:** `scripts/lib/dev-cycle-read.sh:162`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the equivalence of rawfile's test and root_copies' batched form for paths where `-f` holds. It does not establish anything about plaindir, which root_copies does not mirror.

rawfile is `[[ -n "${ROOT_REAL:-}" && -f "$1" ]] && r="$(realpath -e -- "$1" 2>/dev/null)" && [[ "$r" == "$ROOT_REAL/$1" ]]` (`:163`). root_copies does `-f "${ps[i]}" && "${rl[i]}" == "$ROOT_REAL/${ps[i]}"` over a batched `realpath -mz` (`:1286-1288`). When `-f` holds, every component exists, so `-m` and `-e` resolve to the same path.

**Evidence:** `scripts/lib/dev-cycle-read.sh:162-163`, `:1286-1288`

---

## Claim 4: Tree walk failure list: "It returns 1, with IMPORTED set to "error", when the start listing ..., outside_seeds, root_copies, prompt_marks, lower, a file read, import_readers or the parser ... fails"

**Location:** `scripts/lib/dev-cycle-read.sh:686-690`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the three newly listed failure sources and the error marker on each. It does not establish that the list is exhaustive: an outside_proj realpath failure also fails the walk, and that was left out before this branch too.

`IMPORTED_DONE=...; IMPORTED=error` is set at `:1546` before `outside_seeds sd || return 1` (`:1558`) and `root_copies cq cmp pdir "${queue[@]}" || return 1` (`:1567`). Inside the loop the code is `outside_proj out work && { ... || prompt_marks pdir pext out "$f"; } || { IMPORTED=error; return 1; }` (`:1578`) and `root_copies cq cmp pdir "${nm[@]}" || { IMPORTED=error; return 1; }` (`:1590`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1539-1593`

---

## Claim 5: "A seed that is a dangling link joins the queue as a // name, which only outside_proj reads ...; a prompt's projected names are read as prompts (prompt_marks; one the walk already read is not read again, and one main stores as a symlink fails the main walk, as a symlinked prompt start does)."

**Location:** `scripts/lib/dev-cycle-read.sh:753-757`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `//PATH` route, the prompt marking, and the "already read" exception in both walks (probe P2 shows that a queued but still unread name *is* re-marked, so "read" is the exact boundary). It does not establish anything for links that are not dangling but still fail outside_ok, such as a link to a directory, which take the same `//` route.

Seed loop: `p="${f:1}"; outside_ok "$p" || { [[ -L "$p" ]] || continue; p="/$p"; }` (`:1560`, `:1656`). Loop: `if [[ "$f" == //* ]]; then out="$f"` (`:1575`, `:1673`), then outside_proj, then prompt_marks when `pdir[$f]` is set (`:1578`, `:1706`). Main's symlink arm refuses prompt bases: `[[ ${#xs[@]} -eq 0 ]] || { IMPORTED_MAIN=error; return 1; }` (`:1680`). xs is non-empty whenever `pdir[$f]` is set, because prompt_bases always yields `""` (`:672`). Probe P2 (appendix) checked the exception: when docs/u.md is imported plain by AGENTS.md and is also a nested dangling prompt link's target, the main walk (which reads it in phase 1) gives `sub/top2.md: -`, while the tree walk (which only queued it before the link marked it) gives `sub/top2.md: imported`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:753-757`, `:1556-1578`, `:1652-1706`; appendix P2

---

## Claim 6: "For every repo name a walk reaches, a start included, root_copies also reads each other reader root's copy that ROOT_REAL lacks or holds with other bytes, so an import a start in another root reaches there is followed ...; the main walk compares with the checkout's file, which contract item 2's clean checkout makes main's."

**Location:** `scripts/lib/dev-cycle-read.sh:757-762`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers which copies the walks read and the main walk's comparison source. It does not establish that the stated conditions are complete. They are not: two more cases are read, as described below.

The mechanism is right: copies are read for every name passed in (starts at `:1567`/`:1663`, and each file's names via `nm` at `:1590`/`:1721`). The main walk hashes the checkout path: `hs+=("${cs[i]}" "${ps[i]}")` with relative `ps` read from ROOT_REAL (`:1288`). But the skip is narrower than "lacks or holds with other bytes". A copy is skipped only when `[[ -z "${rc_p[${ps[i]}]+set}" && -f "${ps[i]}" && "${rl[i]}" == "$ROOT_REAL/${ps[i]}" && "${rl[n + i]}" == "${cs[i]}" ]]` and the hashes match (`:1288`, `:1293`). So two cases with equal bytes are still read: a **prompt** name's copy (B2, added at 007e867f) and a copy with a link on the way on either side (A2). root_copies' own header states both (claim 11), but this summary was not updated in i2. Precise version: "...each other reader root's copy, unless the name is no prompt and both are plain files with equal bytes".

**Evidence:** `scripts/lib/dev-cycle-read.sh:757-762`, `:1284-1294`

---

## Claim 7: "Named exceptions: ... Any seed listing find, grep or realpath cannot complete, or a root_copies realpath or sha1sum, fails the walk"

**Location:** `scripts/lib/dev-cycle-read.sh:763-767`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the root_copies failure sources in both walks (the sha1sum failure and the unreadable-checkout-file failure). It does not establish behaviour on a failing root_copies realpath, which was read statically: `|| return 1` at `:1286`.

Test "both walks fail closed when another worktree's copy cannot be compared with this checkout's (U2b3b2c)" passes at HEAD and fails on main's lib (appendix R1/R4). The sha1sum stub branch (`printf '#!/bin/sh\nexit 1\n' > "$S/sha1sum"`, `build-loop-check.bats:821`) gives `walk failed` for both walks. The named exceptions match the code: a copy below a dangling linked directory is skipped because `outside_ok` and `-L` both fail on it (`:1280-1281`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:763-767`, `:1286`, `:1292`; `test/scripts/build-loop-check.bats:815-823`; appendix R1, R4

---

## Claim 8: "root_copies costs 66 ms per walk over 7 other roots here, and about 11 ms per copy it reads: a worktree at a commit where many imported files differ adds a read per file"

**Location:** `scripts/lib/dev-cycle-read.sh:775-777`
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the order of magnitude on today's /workspace registry (7 other roots) and the per-copy read price. It does not establish values under other load or registries: the 11 ms includes the walk's per-file bookkeeping, which I did not time on its own.

A timed wrapper around root_copies over /workspace measured 31 calls, 4 copies, and 0.051-0.063 s per walk in 3 runs × 2 walks, with `IMPORT_OTHER` holding 7 roots. A bare `import_file` on each of the 4 copies took 8.4-9.1 ms per read. The walk's per-file `lower`, outside_proj check and root_copies on the copy's names make up the remainder. The i1 performance review measured "about 10-12 ms" per extra read (`docs/reviews/performance-review-2026-10-09-u2b3b2c-i1.md:29`). Load average was 3.5-3.9 during the runs.

**Evidence:** `scripts/lib/dev-cycle-read.sh:775-777`; `docs/reviews/performance-review-2026-10-09-u2b3b2c-i1.md:19,29`; appendix T1, T2

---

## Claim 9: "IMPORT_OTHER holds every root's real path but ROOT_REAL's that is a directory here, once each, newline-separated: the roots whose copies root_copies and outside_seeds read."

**Location:** `scripts/lib/dev-cycle-read.sh:1070-1072`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers construction and consumers. It does not establish that host-spelled roots this container cannot see are present; they are excluded by `-d`, which is the named exception.

`p="${rs_real[i]}"; [[ $t == h || "$p" == "$ROOT_REAL" || -n "${rs_seen[o$p]+set}" || ! -d "$p" ]] || { rs_seen[o$p]=1; IMPORT_OTHER+="$p"$'\n'; }` (`:1128`), then the trailing newline is trimmed (`:1145`). Its consumers are root_copies (`:1275-1276`) and c1_seeds via outside_seeds (`:1425`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1070-1072`, `:1128`, `:1145`, `:1275-1276`, `:1425`

---

## Claim 10: import_outside FILE: "(for the walks, a name from the parser's second channel, below no reader root, or an outside_seeds start, which may lie in another root)"; outside_ok PATH: "an absolute name (one below no reader root, or an outside_seeds start, which may lie in another root)"

**Location:** `scripts/lib/dev-cycle-read.sh:1176-1178`, `:1208-1209`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two parenthetical lists of which absolute paths reach these functions. It does not establish any behavioural defect: both functions handle the new class correctly.

The branch adds a third class of absolute path to both functions: other roots' copies from root_copies. Each copy is tested with `if outside_ok "$r/$p"; then ps+=("$p"); cs+=("$r/$p")` (`:1280`), queued (`:1568`, `:1591`, `:1664`, `:1722`), and read through `import_file` → `if [[ "$1" == /* ]]; then import_outside ...` (`:1207`). Both comments still list only second-channel names and outside_seeds starts. Add "or another root's copy (root_copies)".

**Evidence:** `scripts/lib/dev-cycle-read.sh:1176-1178`, `:1207-1212`, `:1280`

---

## Claim 11: root_copies' header, clause by clause

**Location:** `scripts/lib/dev-cycle-read.sh:1248-1271`
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every clause listed below against the body (`:1272-1299`) and its four call sites. It does not establish that the `//ROOT/NAME` prompt mark is exercised by any test (override row "no test of root_copies' `//` prompt mark"), and "a dangling one" names only the common case of a link that outside_ok rejects (a link to a directory or to an unreadable file takes the same branch).

Clauses:
- **"The array Q is cleared"**: `rc_q=()` (`:1274`).
- **"(an absolute one or a // name is skipped) not yet a key of ... CMP (it then is one)"**: `[[ -n "$p" && "$p" != /* && -z "${rc_c[$p]+set}" ]] || continue; rc_c[$p]=1` (`:1278`).
- **"gets ROOT/NAME when outside_ok admits it, unless NAME is no prompt, rawfile's test holds on both sides ... and their bytes are equal"**: the skip needs `-z "${rc_p[${ps[i]}]+set}"`, `-f "${ps[i]}"`, `"${rl[i]}" == "$ROOT_REAL/${ps[i]}"` and `"${rl[n + i]}" == "${cs[i]}"` (`:1288`), plus `"${rl[2*i]:0:40}" == "${rl[2*i+1]:0:40}"` (`:1293`). Copy-side `-f` comes from outside_ok (`:1280`). Both realpaths come from **one** xargs realpath over `"${ps[@]}" "${cs[@]}"` (`:1286`). Executed: the linked-directory test is red on f7e1bea2 and green at HEAD, and the prompt equal-bytes test is red on c69f352f and green at HEAD (appendix R2-R4).
- **"the walks read ROOT_REAL's file, or main's ... and resolve its relative names against every root"**: import_targets joins "each a repo-relative directory ... under every reader root" (`:819-820`), with `IT_ROOTS="$IMPORT_ROOTS"` (`:1173`).
- **"a prompt copy is always read, since its absolute path can add prompt bases"**: prompt_bases over an absolute path adds the directory holding each `.claude/` (`:675-677`). Test "a prompt copy with this checkout's bytes is still read" covers this.
- **"//ROOT/NAME when it is a link outside_ok rejects"**: `elif [[ -L "$r/$p" ]]; then qs+=("/$r/$p")` (`:1281`). Executed: test 1's `docs/b.md -> gone.md` is projected to `docs/gone.md: imported`.
- **"A copy of a NAME ... PDIR holds ... is added to it, lower-cased, ... and its // form too"**: `[[ -z "${rc_p[${qn[i]}]+set}" ]] || rc_p[${qs[i]}]="$(lower "${qs[i]}")" || return 1` (`:1296`). `qs` holds both absolute copies and `//` forms, and the walks pass `//` entries with a pdir mark to prompt_marks (`:1578`, `:1706`).
- **"realpaths and the sha1sums run in xargs batches; it returns 1 when one fails or lower does"**: `:1286`, `:1292`, `:1296`.
- **"Not covered: a copy below a dangling linked directory ... skipped (A5's class)"**: such a path fails both `outside_ok` (`-f`) and `-L` (lstat cannot pass a dangling component), so neither branch at `:1280-1281` takes it.
- **Cost sentence**: there is no dedupe across roots. Each root's copy goes to `ps`/`cs` on its own (`:1279-1281`). The "13 s over 8 worktrees at a commit where 50 imported files differ" is the i1 performance table row `| 8 | main / branch | 0.88-0.91 / 12.7-13.4 s | 0.78-0.86 / 13.0-13.9 s |` (`performance-review...-i1.md:26`). The per-bytes argument holds: a copy is read against its own absolute directory (`import_outside`: `d="${1%/*}"`, `:1194`), so a `..` name that leaves the root resolves against each root's parent, which differs from root to root.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1248-1299`, `:670-679`, `:817-823`, `:1173`, `:1193-1199`; `docs/reviews/performance-review-2026-10-09-u2b3b2c-i1.md:26,29`; appendix R1-R4

---

## Claim 12: prompt_marks' header: "... each repo name in the variable OUT is read as a prompt, as a session reads the link's target: PDIR gets it lower-cased (its own prompt bases), and ... PEXT gets the link's directory and the link's own prompt bases (absolute, newline-separated), which the walks add to its DIRS ... A name already read is not read again as a prompt: a named exception. It returns 1 when lower fails."

**Location:** `scripts/lib/dev-cycle-read.sh:1300-1307`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers PDIR/PEXT contents, both walks' use of PEXT (tree loop, main's checkout arm and main's 100644 arm), the link's own directory and its bases, for a link at top-level `.claude/` and under a nested `sub/.claude/`. It does not establish the resolution model's fidelity to Claude Code beyond being a superset: the target's own directory and the top level are also searched.

Body: `l="${4#/}"`, `prompt_bases pm_b "${pm_p[$4]#/}" "$l"`, `printf -v b '%s\n' "${l%/*}" "${pm_b[@]:1}"`, then for each non-absolute p: `[[ -n "${pm_p[$p]+set}" ]] || pm_p[$p]="$(lower "$p")" || return 1; pm_x[$p]="${pm_x[$p]:+${pm_x[$p]}$'\n'}$b"` (`:1309-1316`). Both walks then run `[[ -z "${pext[$f]+set}" ]] || mapfile -t -O "${#xs[@]}" xs <<<"${pext[$f]}"` (`:1573`, `:1670`). The 100644 arm passes `"${xs[@]}"` to import_targets (`:1676`). The 120000 arm fails on a non-empty xs (`:1680`), which is the named symlink exception. Executed: the test's nested case (`sub/top2.md`) is red on c69f352f and green at HEAD. Probe P1 resolved names against the **link's own directory** in both walks, at top level (`.claude/commands/helper.md: imported`) and nested (`sub/.claude/commands/h2.md: imported`). Probe P2 checked the "already read" exception (claim 5).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1300-1317`, `:1571-1578`, `:1667-1706`; `test/scripts/build-loop-check.bats:786-796`; appendix R3, P1, P2

---

## Claim 13: outside_seeds: "config_seeds', then c1_seeds'. It returns 1 when either does, or a seed's path holds a newline." (and 8976fbdf "same seeds")

**Location:** `scripts/lib/dev-cycle-read.sh:1318-1331`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers order, failure propagation and identical output to f7e1bea2's unsplit function on /workspace. It does not establish identity on every fixture; the i2 pass reports a second fixture.

`config_seeds os_a || return 1; c1_seeds os_c || return 1; os_a+=("${os_c[@]}"); for d in "${os_a[@]}"; do [[ "$d" != *$'\n'* ]] || return 1; done` (`:1327-1330`). Executed: outside_seeds over /workspace gave the same 9 sorted lines under f7e1bea2's lib and HEAD's (appendix S1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1318-1331`; appendix S1

---

## Claim 14: config_seeds' header (sources, the keep rule "an @ byte, or whose real path differs and lies below a reader root ... a dangling one included", return-1 list)

**Location:** `scripts/lib/dev-cycle-read.sh:1332-1346`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the keep rule and the failure sources as coded. It does not establish python3's fallback path, which does not fail and is correctly not listed.

Keep rule: `in=""; [[ -z "${cs_at[${cx[i]}]+set}" ]] || in=1; [[ -n "$in" || "${rl[i]}" == "${cx[i]}" ]] || for q in "${rs[@]}"; do [[ "${rl[i]}" != "$q"/* ]] || in=1; done` (`:1399-1400`). Dangling links are listed through `'(' -type f -o -type l ')'` under `-L` and `-xtype l` under `-H` (`:1377-1387`), and `realpath -mz` resolves them (`:1397`). Failures come from `|| return 1` on find, lower_all, with_at (grep) and realpath, plus the CLAUDE_CONFIG_DIR test at `:1350`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1347-1403`

---

## Claim 15: c1_seeds' header, including "One is skipped when it is not a link and ROOT_REAL holds a plain file (rawfile) at its path below its innermost root that is a start of the same kind (f or p) there: both walks start at that file and pass it to root_copies, which reads this copy when its bytes differ"

**Location:** `scripts/lib/dev-cycle-read.sh:1404-1421`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the skip condition, the claim that both walks pass such a file to root_copies with its kind set, and the root_copies read on differing bytes. "When its bytes differ" is a sufficient condition, not the whole rule: a prompt copy is read even when equal (claim 11). It does not establish the untracked-nested-repo exclusion beyond contract item 2.

Skip: `[[ ! -L "${cx[i]}" && "$q" == "$c" ]] && isstart "$d" && rawfile "${ir[i]}" || c1_a+=("$c${cx[i]}")` (`:1447`). The tree walk queues every listed `isstart` path that passes `inrepo_here` and sets `prompt_dir pdir` (`:1548-1554`). The main walk does the same over main's and the checkout's candidates (`:1644-1651`). Both pass the full start queue to root_copies (`:1567`, `:1663`), whose copies are `r/NAME` for each IMPORT_OTHER root, the innermost root included. Executed: the C1 test and test 1 (`docs/k2.md` from side's differing, skipped prompt) pass at HEAD. The seed set is unchanged from f7e1bea2 (S1); main's lib seeds 4 more on /workspace, the differing `skills/dev-cycle/SKILL.md` copies, which root_copies now reads instead (S2, T1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1404-1449`, `:1548-1567`, `:1644-1663`; appendix S1, S2, R4

---

## Claim 16: "# rawfile, not -f, on ROOT_REAL's copy: one reached through a link there is no tree walk start (U2b3b2b i1 fact-check 19b)."

**Location:** `scripts/lib/dev-cycle-read.sh:1444`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the tree walk. It does not establish the main walk's handling, which this comment correctly leaves out (B3).

Tree starts require `inrepo_here "$f"` (`:1552`), which is `[[ -z "$(blocker "$1" file)" && -f "$1" ]]` (`:191`). blocker reports a link on the way, so such a path is not started.

**Evidence:** `scripts/lib/dev-cycle-read.sh:191`, `:1444-1447`, `:1552`

---

## Claim 17: imported_names' inline comments: "a dangling link as //PATH, which the loop projects alone (outside_proj)"; "Other roots' copies of the starts, then of every name the loop reaches (root_copies). c1_seeds skips another root's start that has the same kind here only because every start passes through here, pdir already set."; "a dangling prompt link's bases (prompt_marks)"; "a dangling link: outside_proj reads its real path alone"

**Location:** `scripts/lib/dev-cycle-read.sh:1556-1557`, `:1564-1566`, `:1573`, `:1575`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the tree walk's sequencing (pdir set at `:1554` and `:1562` before `:1567`). It does not establish anything about main_imports (claim 19).

`queue+=("$f"); prompt_dir pdir "$lp" "$f"` (`:1554`) and the seed loop (`:1559-1563`) both run before `root_copies cq cmp pdir "${queue[@]}"` (`:1567`). For `//` entries `out="$f"` skips import_file, and `outside_proj out work` follows (`:1575-1578`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1539-1593`

---

## Claim 18: main_imports' failure list ("outside_seeds, root_copies or prompt_marks fails") and the tq comment ("absolute paths, never main's: outside seeds, // imports and other roots' copies, and //PATH entries, dangling links outside_proj projects")

**Location:** `scripts/lib/dev-cycle-read.sh:1600`, `:1607-1610`
**Type:** Error-handling / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the failure sources and the classes of tq entries. "dangling links" names the usual case of a `//PATH` entry, which also arises for any link outside_ok rejects. It does not establish anything about the checkout-file entries (relative), which the sentence's "tq's checkout files" covers.

`IMPORTED_MAIN=error` is set at `:1618` before `outside_seeds sd || return 1` (`:1654`) and `root_copies ... || return 1` (`:1663`), and the loop does `{ IMPORTED_MAIN=error; return 1; }` after prompt_marks/root_copies (`:1706`, `:1721`). tq receives seeds (`:1658`), `//` imports (`:1714`) and copies (`:1664`, `:1722`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1594-1724`

---

## Claim 19: main_imports' inline comments: "a dangling link as //PATH, projected alone, as in imported_names"; "Other roots' copies of the starts, then of every name the loop reaches (root_copies), in phase 2. c1_seeds skips ... only because every start passes through here, pdir already set."; "a dangling link: outside_proj below reads its real path alone"

**Location:** `scripts/lib/dev-cycle-read.sh:1652-1653`, `:1660-1662`, `:1670`, `:1673`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers sequencing and the checkout arm. It does not establish anything about starts main_checkout answers 2 for, which are dropped. A C1-skipped file is a rawfile there and is either main's or admitted (0), so the coupling holds under contract item 2.

`prompt_dir pdir "$f" "${cand[i]:2}"` runs before the main_checkout gate (`:1647`), and `root_copies cq cmp pdir "${queue[@]}" "${tq[@]}"` comes after both start loops (`:1663`). The checkout arm is `if [[ "$f" == //* ]]; then out="$f"` (`:1673`), with `outside_proj` at `:1706`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1640-1675`, `:1706`

---

## Claim 20: C1 test title: "C1: both walks start at the start files another worktree holds, ..., skipping one whose bytes match this checkout's plain copy or that holds no @"

**Location:** `test/scripts/build-loop-check.bats:724`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the title's skip rule against c1_seeds at HEAD. It does not establish any defect in the test's assertions, which pass (R4) and still hold.

Since f7e1bea2, C1 no longer compares bytes. It skips a non-link start whenever ROOT_REAL holds a same-kind plain start at that path, whatever its bytes: `[[ ! -L "${cx[i]}" && "$q" == "$c" ]] && isstart "$d" && rawfile "${ir[i]}" || c1_a+=(...)` (`lib:1447`). A differing copy reaches the walks through root_copies instead (test 1's side prompt is skipped by C1 and read by name). The title is untouched in this diff and still describes main's byte-comparing rule. Precise version: "skipping a non-link one this checkout holds as a plain start of the same kind (root_copies reads it when its bytes differ), or one holding no @".

**Evidence:** `test/scripts/build-loop-check.bats:724`, `:745-747`; `scripts/lib/dev-cycle-read.sh:1441-1448`

---

## Claim 21: Test 1 title: "both walks read another worktree's copy of a name they reach when this checkout lacks it or its bytes differ, through chains there; a prompt's copy reads as a prompt; a dangling one is projected (U2b3b2c; ...)"

**Location:** `test/scripts/build-loop-check.bats:761`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the fixture's assertions at HEAD and the fact that they fail on main's lib. It does not establish that the prompt part is red on main: main's lib already seeds the differing prompt through C1, so `docs/k2.md: imported` there.

Passes at HEAD and fails on main's lib with `docs/b.md: -`, `docs/n.md: -`, `docs/c.md: -`, `docs/gone.md: -` (appendix R1). The dangling `docs/b.md -> gone.md` in side projects to `docs/gone.md`.

**Evidence:** `test/scripts/build-loop-check.bats:761-774`; appendix R1, R4

---

## Claim 22: "# side's prompt differs, so C1 leaves it to the name: its @docs/k2.md resolves against side's top level only as a prompt."

**Location:** `test/scripts/build-loop-check.bats:767`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the comment's causal "differs, so C1 leaves it". It does not cover the second half ("resolves against side's top level only as a prompt"), which is right: as a plain file the copy's names resolve only against `$sd/.claude/commands`.

The natural reading is that C1 leaves side's prompt to the name *because* it differs. C1 skips it whatever its bytes, since ROOT_REAL holds `.claude/commands/k.md` as a same-kind plain start (`lib:1447`). At HEAD root_copies also reads a prompt copy whatever its bytes (`-z "${rc_p[${ps[i]}]+set}"`, `lib:1288`). The difference only gives the copy an import ROOT_REAL's copy lacks (`k: @docs/k2.md`). A reader taking the comment at its word would think C1 still compares bytes, which is the rule this branch removed. Precise version: "C1 leaves side's prompt to the name (this checkout holds it as a prompt); its different text imports docs/k2.md, which resolves against side's top level only as a prompt." Severity: low (test comment).

**Evidence:** `test/scripts/build-loop-check.bats:767-768`; `scripts/lib/dev-cycle-read.sh:1288`, `:1447`

---

## Claim 23: Test 2 title: "a copy with this checkout's bytes under a linked directory is read, so its real path is projected (U2b3b2c; i1 security F2)"

**Location:** `test/scripts/build-loop-check.bats:776`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the linked-directory case in both walks and the fact that it fails on f7e1bea2 (A2's "before its fix") and on main. It does not establish the case of a dangling linked directory, which is the named A5-class exception.

Fails on f7e1bea2 (`real/x.md: -`) and on main, passes on c69f352f and HEAD (appendix R1-R4).

**Evidence:** `test/scripts/build-loop-check.bats:776-784`; appendix R1-R4

---

## Claim 24: "(A plain copy with equal bytes is skipped as a cost: the parser already resolves this checkout's relative names against every root, so reading it could add nothing.)"

**Location:** `test/scripts/build-loop-check.bats:777-778`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the comment against root_copies at HEAD. It does not establish anything about the fixture, whose name (`docs/x.md`) is not a prompt and for which the comment holds.

The reasoning holds for a non-prompt name, but the comment lacks the qualifier B2 introduced at 007e867f. A plain copy of a **prompt** name with equal bytes is not skipped: `[[ -z "${rc_p[${ps[i]}]+set}" && ... ]]` (`lib:1288`). Reading it *can* add something, namely prompt bases from its absolute path (test 4, `:798-802`). The i2 rubric's B2 row names "the test comment claiming equal copies add nothing was wrong for prompts", but this comment did not change in 007e867f (`git diff c69f352f 007e867f -- test/` touches only tests 3 and 4). Precise version: "A plain copy of a non-prompt name with equal bytes is skipped ...".

**Evidence:** `test/scripts/build-loop-check.bats:777-778`, `:798-802`; `scripts/lib/dev-cycle-read.sh:1288`

---

## Claim 25: Test 3 title and nested comment: "a dangling prompt link in another worktree reads its target as a prompt (U2b3b2c i1 security F1)"; "Under a nested .claude/, the link's own bases (side/sub) apply to its target's names too (i2 fact-check 9b)."

**Location:** `test/scripts/build-loop-check.bats:786-790`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both walks and the red status per fix. It does not establish resolution against the link's own directory; probe P1 covered that separately.

Fails on main (`docs/t.md: -`), fails on f7e1bea2 (`top.md: -`, A1's state before its fix), fails on c69f352f only at `sub/top2.md: -` (B1's state before its fix), passes at HEAD (appendix R1-R4). `# side lacks docs/` holds: side is added before the fixture commits docs/.

**Evidence:** `test/scripts/build-loop-check.bats:786-796`; appendix R1-R4

---

## Claim 26: Test 4 title: "a prompt copy with this checkout's bytes is still read: a worktree under a .claude/ adds prompt bases (U2b3b2c i2 fact-check 16)"

**Location:** `test/scripts/build-loop-check.bats:798`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both walks and the fact that it fails on c69f352f. It does not establish behaviour for a non-prompt equal copy (claim 24).

Fails on main, f7e1bea2 and c69f352f (`docs/z2.md: -`) and passes at HEAD (appendix R1-R4).

**Evidence:** `test/scripts/build-loop-check.bats:798-802`; appendix R1-R4

---

## Claim 27: Test 5 title: "a seed that is a dangling link into another worktree reads as the repo path it names (U2b3b2c; U2b3b2b final security F1)"

**Location:** `test/scripts/build-loop-check.bats:804`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers config-dir top-level and rules/ dangling links in both walks, plus the dropped link below no root. It does not establish C1-seed dangling links, which test 3 covers.

Fails on main's lib (`docs/n.md: -`, `docs/r.md: -`, `docs/deep.md: -`) and passes at f7e1bea2, c69f352f and HEAD (appendix R1-R4).

**Evidence:** `test/scripts/build-loop-check.bats:804-813`; appendix R1-R4

---

## Claim 28: Test 6 title and comment: "both walks fail closed when another worktree's copy cannot be compared with this checkout's (U2b3b2c)"; "The main walk reads main's blob, so only the comparison reads the unreadable checkout file."

**Location:** `test/scripts/build-loop-check.bats:815-819`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the fact that it fails on main's lib and passes at HEAD, and the main walk's read path. It does not establish whether the sha1sum-stub half alone fails on main's lib: the test stops at the chmod half there, and main's C1 also ran sha1sum.

On main's lib: `want: walk: failed` / `walk: ok` (appendix R1), from the main walk, which reads `git cat-file blob` for docs/a.md (`lib:1676`). Passes at HEAD (R4).

**Evidence:** `test/scripts/build-loop-check.bats:815-823`; `scripts/lib/dev-cycle-read.sh:1676`, `:1292`; appendix R1, R4

---

## Claim 29: Sourcing inventory names root_copies, prompt_marks, config_seeds, c1_seeds and IMPORT_OTHER

**Location:** `test/scripts/dev-cycle.bats:1111-1115`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the fact that these names are defined after sourcing. It does not establish anything about other new locals (none are global).

dev-cycle.bats passed 79/79 in the serial run (appendix B2). The functions are defined at `lib:1272`, `:1308`, `:1347`, `:1422` and the variable at `:1075`.

**Evidence:** `test/scripts/dev-cycle.bats:1111-1115`; appendix B2

---

## Claim 30a: Commit f7e1bea2: "Suites 284 green"; "Over /workspace (7 other present roots) both walks give main's 242 names"; mechanism paragraph

**Location:** commit f7e1bea2 message
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the suite count by test count at that commit, the mechanism as of f7e1bea2, and the 7-root count. It does not establish the 242 at f7e1bea2 itself: I ran HEAD (claim 33), and the i1 fact-check ran f7e1bea2. The seed-wording row is already accepted-immutable in the override log.

At f7e1bea2, build-loop-check has 128 tests, plus build-loop-read 20, dev-cycle 79, fixture-git-env 2, fixture-hermeticity 2 and hermeticity-lint 53, which is 284 (`git show f7e1bea2:test/scripts/build-loop-check.bats | grep -c '^@test'` → 128, paraphrased — no quote available because the count spans six files). IMPORT_OTHER holds 7 roots today (T1).

**Evidence:** commit f7e1bea2; `test/scripts/*.bats`, `test/fixture-hermeticity.bats`, `test/hermeticity-lint.bats`; appendix T1

---

## Claim 30b: Commit f7e1bea2: "the reads add about 0.05 s per walk (tree 1.93 s, main 2.09 s)"

**Location:** commit f7e1bea2 message
**Type:** Performance
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers a point-in-time timing. It does not establish today's figure, which depends on load and the registry.

Re-measured at HEAD under load 3.5-3.9: root_copies' own time was 0.051-0.063 s per walk, and the 4 copy reads added about 4 × 8.5-9 ms. Tree walks took 2.24-2.44 s and main walks 2.45-3.97 s, against 2.05-2.08 s / 1.98-2.60 s with root_copies stubbed to return nothing (appendix T1-T3). That is the same order as "about 0.05 s", but the walk-level delta under load was noisier (0.16-0.39 s on the tree walk). To verify, interleave runs on an idle host at f7e1bea2.

**Evidence:** commit f7e1bea2; appendix T1-T3

---

## Claim 31: Commit 8976fbdf: A1-A9 summary, "Suites 286/286", "both walks over /workspace give main's 242 names", "357 changed code lines", "outside_seeds split ...; same seeds"

**Location:** commit 8976fbdf message
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the line count, the suite count by test count, same seeds (on /workspace), and the A2/A1 tests failing on f7e1bea2. It does not establish the "-j 8" run history.

`git diff --numstat main...8976fbdf -- ':(top)' ':(top,exclude)docs/' | awk '{n+=$1+$2} END{print n}'` → 357. The tests come to 130 + 156 = 286. Same seeds: S1. A1 and A2 tests fail on f7e1bea2: R2.

**Evidence:** commit 8976fbdf; appendix S1, R2

---

## Claim 32: Commit c69f352f: "the lite check read the moved comment as describing the seed; it describes ROOT_REAL's copy."

**Location:** commit c69f352f message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the comment it changed (`lib:1444`, claim 16). It does not establish anything else.

`# rawfile, not -f, on ROOT_REAL's copy: ...` (`lib:1444`); rawfile is applied to `"${ir[i]}"`, ROOT_REAL's relative path (`:1447`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1444-1447`

---

## Claim 33: Commit 007e867f: B1 and B2 descriptions; "Suites 287/287 (serial); both walks over /workspace give main's 242 names; 377 changed code lines."

**Location:** commit 007e867f message
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers all three figures at HEAD and the B1/B2 mechanisms. It does not establish that the timings in the shared brief (tree ~1.7 s, main ~1.9 s) hold today. Under load 3.5-3.9 I measured 2.2-2.4 s and 2.4-4.0 s, and the commit itself states no timing.

Serial runs: build-loop-check 131/131 (B1), and build-loop-read, dev-cycle, fixture-git-env, fixture-hermeticity and hermeticity-lint 156/156 (B2), which is 287. Both walks over /workspace with HEAD's lib and main's lib give 242 names each, with identical sets, and the tree set equals the main set (W1). The numstat command gives 377. B1 and B2: claims 11 and 12.

**Evidence:** commit 007e867f; appendix B1, B2, W1

---

## Claims Requiring Attention

### Incorrect
- **Claim 22** (`test/scripts/build-loop-check.bats:767`) [for-author]: "side's prompt differs, so C1 leaves it to the name". C1 skips that prompt whatever its bytes (same-kind plain start here). The difference only supplies the k2 import. Reword without the causal "so".

### Stale
- **Claim 10** (`scripts/lib/dev-cycle-read.sh:1176-1178`, `:1208-1209`) [for-author]: import_outside's and outside_ok's lists of absolute paths omit the branch's new class, other roots' copies from root_copies.
- **Claim 20** (`test/scripts/build-loop-check.bats:724`) [for-author]: the C1 test title still says C1 skips "one whose bytes match this checkout's plain copy". Since f7e1bea2, C1 skips a same-kind plain start here whatever its bytes, and root_copies does the byte check.

### Mostly Accurate
- **Claim 6** (`scripts/lib/dev-cycle-read.sh:757-762`) [for-author]: the walk header says root_copies reads copies "ROOT_REAL lacks or holds with other bytes". It also reads every prompt copy, and any copy with a link on the way on either side.
- **Claim 24** (`test/scripts/build-loop-check.bats:777-778`) [for-author]: "A plain copy with equal bytes is skipped" needs "of a non-prompt name". A prompt copy is always read since B2, and the i2 rubric flagged this exact comment.

### Unverifiable
- **Claim 30b** (commit f7e1bea2) [for-orchestrator-synthesis]: "+0.05 s per walk, tree 1.93 s, main 2.09 s" is a point-in-time timing. root_copies' own time re-measures at 0.05-0.06 s and the copy reads add about 0.035 s, but walk-level deltas under load were 0.16-0.39 s. Interleaved idle-host runs would be needed. The commit is immutable.

All Verified claims (1-5, 7-9, 11-19, 21, 23, 25-29, 30a, 31-33) are [for-orchestrator-synthesis].

---

## Execution appendix (captured output, verbatim excerpts)

Working directory for B1/B2: /workspace/.claude/wt-build-loop-u2b3b2c. For R1-R4 and P1/P2: a `cp -a` copy of the worktree under /tmp/fcf-r3-u2c-red-pVnF/wt, with the lib swapped per run (the review worktree was not edited). For S/T/W: /workspace, read-only walks with the lib sourced from the path named.

**B1**: `TMPDIR=$(mktemp -d /tmp/fcf-r3-u2c-t-XXXX) bats test/scripts/build-loop-check.bats`, started 2026-10-09T23:09:15-07:00, ended 23:10:07, exit 0:
```
ok 131 a refused reader set is memoized, so a decision lists the worktree registry once (U2b3b1; U2b3a final performance F1)
exit 0
(131 lines starting "ok", none "not ok")
```

**B2**: `TMPDIR=... bats test/scripts/build-loop-read.bats test/scripts/dev-cycle.bats test/scripts/fixture-git-env.bats test/fixture-hermeticity.bats test/hermeticity-lint.bats`, 23:12:04 to 23:13:02, exit 0:
```
1..156
(156 lines starting "ok", none "not ok")
exit 0
```

**R1-R4**: `TMPDIR=... bats -f 'U2b3b2c' test/scripts/build-loop-check.bats` per lib, 23:12:24 to 23:12:3x. Exit 1 for main, f7e1bea2 and c69f352f; exit 0 for HEAD:
```
=== lib main
not ok 1 both walks read another worktree's copy ... (want: docs/b.md: imported | docs/b.md: - docs/n.md: - docs/c.md: - docs/k2.md: imported docs/gone.md: - docs/e.md: -)
not ok 2 a copy with this checkout's bytes under a linked directory ... (real/x.md: -)
not ok 3 a dangling prompt link ... (docs/t.md: - top.md: - sub/top2.md: -)
not ok 4 a prompt copy with this checkout's bytes is still read ... (docs/z2.md: -)
not ok 5 a seed that is a dangling link ... (docs/n.md: - docs/r.md: - docs/deep.md: - docs/other.md: -)
not ok 6 both walks fail closed ... (want: walk: failed | walk: ok docs/a.md: imported)
=== lib f7e1bea2
ok 1 / not ok 2 (real/x.md: -) / not ok 3 (want: top.md: imported | docs/t.md: imported top.md: - sub/top2.md: -) / not ok 4 (docs/z2.md: -) / ok 5 / ok 6
=== lib c69f352f
ok 1 / ok 2 / not ok 3 (want: sub/top2.md: imported | docs/t.md: imported top.md: imported sub/top2.md: -) / not ok 4 (docs/z2.md: -) / ok 5 / ok 6
=== lib head
ok 1 .. ok 6, exit 0
```

**P1/P2**: a scratch bats file with the suite's `imps`/`want` helpers, run against HEAD's lib in the copy, exit 0:
```
P1 (side/.claude/commands/k.md -> ../../docs/t.md and side/sub/.claude/commands/k.md -> ../../../docs/u.md, both dangling; t: @helper.md, u: @h2.md)
tree: walk: ok  docs/t.md: imported  docs/u.md: imported  .claude/commands/helper.md: imported  sub/.claude/commands/h2.md: imported
main: walk: ok  docs/t.md: imported  docs/u.md: imported  .claude/commands/helper.md: imported  sub/.claude/commands/h2.md: imported
P2 (AGENTS.md: see @docs/u.md; side/sub/.claude/commands/k.md -> ../../../docs/u.md dangling; u: @top2.md)
tree: walk: ok  docs/u.md: imported  sub/top2.md: imported
main: walk: ok  docs/u.md: imported  sub/top2.md: -
```

**W1**: both walks over /workspace (resolve_main, reader_settings, ROOT_REAL), repo names (lines not starting `//`) sorted -u, about 23:13:30:
```
head tree: ok 242 names; other roots: 7
head main: ok 242 names
main tree: ok 242 names
main main: ok 242 names
tree-same / main-same / tree=main   (diff of the four lists: no output)
```

**T1-T3**: timings over /workspace, 23:13:4x to 23:14:20, load average 3.55-3.92:
```
T1 (root_copies wrapped with $EPOCHREALTIME accumulation)
tree: calls 31 copies 4 time 0.0517128 | main: calls 31 copies 4 time 0.0585144
tree: calls 31 copies 4 time 0.0556436 | main: calls 31 copies 4 time 0.0629408
tree: calls 31 copies 4 time 0.0505259 | main: calls 31 copies 4 time 0.0554113
T2 (import_file over each of root_copies' 4 copies of skills/dev-cycle/SKILL.md, 5 reads each)
9.058 / 8.51178 / 8.42061 / 8.43344 ms per read
T3 (whole walks; "norc" = HEAD's lib with root_copies returning nothing)
head tree 2.33858 / 2.23712 / 2.43607 s; head main 2.52601 / 2.44639 / 3.9711 s (242 names)
norc tree 2.05416 / 2.07852 / 2.04804 s; norc main 2.26279 / 2.59615 / 1.98111 s (241 names)
```

**S1/S2**: `outside_seeds` over /workspace after import_readers, sorted, about 23:16:
```
S1: f7e1bea2 lib 9 lines, HEAD lib 9 lines, diff: no output (same-seeds)
S2: main lib 13 lines; diff main -> HEAD drops exactly
    f.../worktrees/q125-cc-isolated-sandbox/skills/dev-cycle/SKILL.md
    f.../wt-build-loop-u2a/skills/dev-cycle/SKILL.md
    f.../wt-build-loop-u2b1a/skills/dev-cycle/SKILL.md
    f.../wt-egress-dnsmasq-ipset/skills/dev-cycle/SKILL.md
```
(These 4 are the copies root_copies returns in T2.)

Line count: `git diff --numstat main...HEAD -- ':(top)' ':(top,exclude)docs/' | awk '{n+=$1+$2} END{print n}'` → `377`. For main...8976fbdf → `357`, and for main...c69f352f → `359`.

All scratch directories (`/tmp/fcf-r3-u2c-*`) were removed after the run, and no probe process remains.

---

## Goal-Alignment Note

- **Success criterion (verbatim):** "A markdown report saved to the output path below, structured per the code-fact-check skill, with `Commit: 007e867f` as its first line."
- **Answered:** Yes. 34 claims were checked across the lib's changed comments, the U2b3b2c and C1 tests, the inventory and four commit messages. The suites, the 242-name identity, the line counts and every test's red-on-prior-lib status were executed. Every behavioural claim the orchestrator singled out (root_copies clause by clause, prompt_marks/pext in both walks at top-level and nested `.claude/` including the link's own directory, the C1 skip coupling, the cost figures) is Verified. The five non-Verified claims are all comment, test-text or commit-timing claims. None of them shows a behavioural defect.
- **Out of scope:** Code-quality, security and performance judgements (sibling critics). Override-log rows were not re-filed: the per-copy cost, the named "already read" exception and the untested `//` prompt-copy mark stand as logged.
- **Escalate:** None blocking. Claims 6, 10, 20, 22 and 24 are low-severity text fixes for the author. Claim 24 is a comment the i2 rubric's B2 row already called wrong but did not get edited.
- **Questions / Decisions:** Whether to fix the five text items before the local merge or carry them as accepted text residue is the orchestrator's call; none changes behaviour.
