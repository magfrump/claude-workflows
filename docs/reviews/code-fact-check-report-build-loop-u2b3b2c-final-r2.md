Commit: 007e867f
# Code Fact-Check Report

**Repository:** /workspace (worktree /workspace/.claude/wt-build-loop-u2b3b2c, branch feat/build-loop-u2b3b2c)
**Scope:** `git diff main...HEAD` (main 8e550626, HEAD 007e867f; commits f7e1bea2, 8976fbdf, c69f352f, 007e867f): `scripts/lib/dev-cycle-read.sh` (header, contract items 1-9, walk doc block, import_readers, import_outside, outside_ok, root_copies, prompt_marks, outside_seeds, config_seeds, c1_seeds, imported_names, main_imports), `test/scripts/build-loop-check.bats` (the six U2b3b2c tests), `test/scripts/dev-cycle.bats` (inventory), and the four commit messages. Final confirming pass, replicate r2.
**Checked:** 2026-10-09 (runs 2026-10-10T06:11Z-06:18Z UTC)
**Total claims checked:** 40
**Summary:** 34 verified, 4 mostly accurate, 2 stale, 0 incorrect, 0 unverifiable

I read the hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) first. The commit messages' "287/287", "242 names" and "377 changed code lines" belong to the logged "specific measured test count" class (the "All 85 tests" and "mode1-equiv 33" entries), so I recounted all three (Claims 34-37). All three hold. No Incorrect verdict was issued, so no fabrication pattern is added.

Execution provenance for every `executed` claim is in Appendix A (E1-E9). The review rules allow writing only this file, so the captured output is copied there instead of into `docs/reviews/execution-logs/`.

---

## Claim 1: "and, through root_copies, other roots' copies of the names they reach (sha1sum)"

**Location:** `scripts/lib/dev-cycle-read.sh:42-47`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the file header's tool attribution: sha1sum moved from the seed listing to root_copies. It does not establish that the header lists every tool each walk forks (it never claimed to; realpath and xargs are unnamed).

The header now reads "the other roots' file trees (find, grep, python3 on installed_plugins.json), and, through root_copies, other roots' copies of the names they reach (sha1sum)" (`:45-46`). The only sha1sum call left in the lib is root_copies': `nul_list rl xargs -0r -a <(printf '%s\0' "${hs[@]}") sha1sum -z --` (`:1292`). c1_seeds no longer hashes (paraphrased, no quote available because the claim is about the absence of code: `rg -n sha1sum scripts/lib/dev-cycle-read.sh` hits only `:46`, `:767` and `:1292`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:42-47`, `:1292`, `:1422-1449`

---

## Claim 2: Contract item 4: "CLAUDE_CONFIG_DIR or IMPORT_MANAGED_DIR (outside_seeds reads them)"

**Location:** `scripts/lib/dev-cycle-read.sh:71-72`
**Type:** Architectural / Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers whether item 4 survived the split. It does not re-verify the rest of item 4, which the branch did not touch.

The split moved the reads into config_seeds: `[[ -z "${CLAUDE_CONFIG_DIR:-}" ]] || cf+=("$CLAUDE_CONFIG_DIR"); cf+=("$IMPORT_MANAGED_DIR")` (`:1353`). outside_seeds calls it, `config_seeds os_a || return 1` (`:1327`), so outside_seeds still reads both variables, through its helper.

**Evidence:** `scripts/lib/dev-cycle-read.sh:71-72`, `:1324-1331`, `:1350-1353`

---

## Claim 3: Contract item 9: "nor IMPORT_ROOTS, IMPORT_HOMES, IMPORT_DOTNEST or IMPORT_OTHER: they are import_readers' results, which a cache hit does not recompute."

**Location:** `scripts/lib/dev-cycle-read.sh:96-98`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers who writes the four variables and what a memo hit does. It does not establish that no caller sets them; that is the contract's own rule.

All four are cleared at source time: `IMPORT_ROOTS=""; IMPORT_HOMES=""; IMPORT_DOTNEST=""; IMPORT_OTHER=""; ...` (`:1075`). They are recomputed only past the memo check: `if [[ "$IMPORT_READERS_DONE" == "$IMPORT_READERS_KEY" ]]; then [[ -n "$IMPORT_ROOTS" ]]; return; fi` (`:1098`), followed by the reset at `:1099` and the build at `:1128` and `:1145`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:96-98`, `:1075`, `:1092-1146`

---

## Claim 4: "# root_copies batches the same test: change the two together." (and its twin at root_copies: "rawfile's test is batched here (realpath -m with -f): change the two together")

**Location:** `scripts/lib/dev-cycle-read.sh:162`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the equivalence of the two tests on an existing file. It does not cover a file removed between root_copies' `-f` and its realpath batch, where `-m` and `-e` would differ.

rawfile: `[[ -n "${ROOT_REAL:-}" && -f "$1" ]] && r="$(realpath -e -- "$1" 2>/dev/null)" && [[ "$r" == "$ROOT_REAL/$1" ]]` (`:163`). root_copies: `-f "${ps[i]}" && "${rl[i]}" == "$ROOT_REAL/${ps[i]}"`, with `rl` from one `realpath -mz` batch (`:1286`, `:1288`). Once `-f` holds the file exists, so `-m` and `-e` give the same path.

**Evidence:** `scripts/lib/dev-cycle-read.sh:162-163`, `:1264-1265`, `:1286-1288`

---

## Claim 5: imported_names fails "when the start listing (...), outside_seeds, root_copies, prompt_marks, lower, a file read, import_readers or the parser (...) fails"

**Location:** `scripts/lib/dev-cycle-read.sh:686-690`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three newly listed failure sources and that each leaves IMPORTED="error". It does not re-verify the pre-existing entries.

`IMPORTED=error` is set before any of them run (`:1546`). The failure arms are `outside_seeds sd || return 1` (`:1558`), `root_copies cq cmp pdir "${queue[@]}" || return 1` (`:1567`), `... prompt_marks pdir pext out "$f"; } || { IMPORTED=error; return 1; }` (`:1578`), and `root_copies cq cmp pdir "${nm[@]}" || { IMPORTED=error; return 1; }` (`:1590`). E2 test 6 (a stub sha1sum that exits 1, and an unreadable checkout file) passes on HEAD for both walks with `walk: failed`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:686-690`, `:1546-1592`; Appendix A E1, E5

---

## Claim 6: "A seed that is a dangling link joins the queue as a // name, which only outside_proj reads (...); a prompt's projected names are read as prompts (prompt_marks; one the walk already read is not read again, and one main stores as a symlink fails the main walk, as a symlinked prompt start does)."

**Location:** `scripts/lib/dev-cycle-read.sh:753-757`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both walks' seed loops, the `//` arm, prompt_marks' call site and the 120000 arm's refusal. It does not cover a projected name the walk already read plain (named; override row 595).

Seed loop: `p="${f:1}"; outside_ok "$p" || { [[ -L "$p" ]] || continue; p="/$p"; }` (`:1560`, `:1656`). A `//` entry is never read as a file: `if [[ "$f" == //* ]]; then out="$f"` (`:1575`, `:1673`). The 120000 arm refuses any prompt: `[[ ${#xs[@]} -eq 0 ]] || { IMPORTED_MAIN=error; return 1; }` (`:1680`), and prompt_bases always gives at least `""` (`pb_a=("")`, `:672`). E6 (a dangling prompt link in side whose target main stores as a symlink) gave `main rc=1`, `IMPORTED_MAIN=error`. E2's test 5 (dangling seeds) and test 3 (dangling prompt links) pass on HEAD and fail on main's lib.

**Evidence:** `scripts/lib/dev-cycle-read.sh:753-757`, `:1556-1563`, `:1652-1659`, `:1673-1680`; Appendix A E3, E6

---

## Claim 7: "For every repo name a walk reaches, a start included, root_copies also reads each other reader root's copy that ROOT_REAL lacks or holds with other bytes, so an import a start in another root reaches there is followed (...); the main walk compares with the checkout's file, which contract item 2's clean checkout makes main's."

**Location:** `scripts/lib/dev-cycle-read.sh:757-762`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the stated reads: every start, every non-`//` name each read yields, and the copy read when ROOT_REAL lacks a plain file there or the bytes differ. It is not an exhaustive list of reads: a prompt copy is always read, and so is a copy with a link on either side, so the sentence understates what is read. Nothing it states is missed.

Starts: `root_copies cq cmp pdir "${queue[@]}"` (`:1567`) and `root_copies cq cmp pdir "${queue[@]}" "${tq[@]}"` (`:1663`), called after pdir is set. Reached names: `nm+=("$p")` for every non-`//` line (`:1586`, `:1715`, which precedes main's seen check), then root_copies over `nm` (`:1590`, `:1721`). Comparison against the working tree: `-f "${ps[i]}"` and sha1sum over `"${ps[i]}"` (`:1288`, `:1292`). E2 test 1 passes on HEAD and is red on main's lib (`docs/b.md: -`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:757-762`, `:1567`, `:1586-1591`, `:1663`, `:1715-1722`, `:1286-1293`; Appendix A E2, E3

---

## Claim 8: "Named exceptions: ... a symlinked directory in another root (A5); and a C1 start or copy ROOT_REAL holds in a checkout that is not clean (...). Any seed listing find, grep or realpath cannot complete, or a root_copies realpath or sha1sum, fails the walk"

**Location:** `scripts/lib/dev-cycle-read.sh:763-771`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the failure sources named and the dependence of the C1 skip and the copy comparison on a clean checkout. It does not establish that A5 covers root_copies' own not-covered case (Claim 14b).

`nul_list rl xargs ... realpath -mz -- && [[ ${#rl[@]} -eq $((2 * n)) ]] || return 1` (`:1286`) and `... sha1sum -z -- && [[ ${#rl[@]} -eq ${#hs[@]} ]] || return 1` (`:1292`). Both walks propagate the failure (Claim 5, Claim 22). The C1 skip and the copy comparison both read the working tree (`rawfile "${ir[i]}"`, `:1447`; `-f "${ps[i]}"`, `:1288`), so they match main only under item 2. E2 test 6 is red on main's lib only in the main-walk half (`walk: ok`), which shows that the comparison is the only reader of the unreadable checkout file in the main walk.

**Evidence:** `scripts/lib/dev-cycle-read.sh:763-771`, `:1286`, `:1292`, `:1447`; Appendix A E2, E3

---

## Claim 9: "root_copies costs 66 ms per walk over 7 other roots here, and about 11 ms per copy it reads: a worktree at a commit where many imported files differ adds a read per file"

**Location:** `scripts/lib/dev-cycle-read.sh:775-777`
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers /workspace's registry today (7 IMPORT_OTHER roots, 31 root_copies calls and 4 copies per walk) at load averages of 0.6 to 3.1. It does not cover other registries, or the 13 s synthetic figure, which comes from the i1 performance review (Claim 14c).

E4: root_copies' own time per walk was 0.065, 0.070 and 0.072 s for the tree walk, and 0.085, 0.081 and 0.085 s for the main walk (load about 1.7, with the suites running alongside). The prior pass measured 0.059-0.070 s unloaded. E7: reading each of the 4 copies took 11.5, 9.4, 9.3 and 9.2 ms. E8: with root_copies stubbed to return nothing, the tree walk was 0.06-0.15 s faster, consistent with 66 ms plus 4 × ~10 ms. The main walk's 66 ms reads closer to 80 ms under load. That is within "per walk" noise, so I left the verdict at Verified.

**Evidence:** `scripts/lib/dev-cycle-read.sh:775-777`; Appendix A E4, E7, E8

---

## Claim 10: "Every name read from text starts at an @ byte (...): outside_seeds drops a seed holding none unless a link leads to it (with_at leans on this)."

**Location:** `scripts/lib/dev-cycle-read.sh:954-956`
**Type:** Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers whether this cross-reference in the parser survived the split. It does not re-verify the parser's scan.

Both halves still filter through with_at: config_seeds keeps `cs_at` or a link below a root (`:1394-1401`), and c1_seeds keeps `[[ -n "${c1_at[${cx[i]}]+set}" || -L "${cx[i]}" ]]` (`:1442`). outside_seeds is their only caller (`:1327-1328`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:954-956`, `:1324-1331`, `:1394-1401`, `:1439-1442`

---

## Claim 11: "IMPORT_OTHER holds every root's real path but ROOT_REAL's that is a directory here, once each, newline-separated: the roots whose copies root_copies and outside_seeds read."

**Location:** `scripts/lib/dev-cycle-read.sh:1070-1072`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers how it is built and who reads it. It does not cover a refusal path that leaves it partly filled (override row 596).

`p="${rs_real[i]}"; [[ $t == h || "$p" == "$ROOT_REAL" || -n "${rs_seen[o$p]+set}" || ! -d "$p" ]] || { rs_seen[o$p]=1; IMPORT_OTHER+="$p"$'\n'; }` (`:1128`), trimmed at `:1145`. Readers: `mapfile -t rs <<<"$IMPORT_OTHER"` (`:1276`) and c1_seeds `mapfile -t cr <<<"$IMPORT_OTHER"` (`:1425`, reached via outside_seeds). E1 on /workspace reported 7 lines.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1070-1072`, `:1125-1145`, `:1276`, `:1425`; Appendix A E1

---

## Claim 12: "import_outside FILE [DIRS...]: import_targets' output for FILE, an absolute path (for the walks, a name from the parser's second channel, below no reader root, or an outside_seeds start, which may lie in another root)"

**Location:** `scripts/lib/dev-cycle-read.sh:1176-1178`
**Type:** Architectural / Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the list of absolute FILEs the walks pass. It does not affect behaviour: import_outside reads any absolute path the same way.

The branch adds a third kind of absolute FILE, another root's copy from root_copies: `if outside_ok "$r/$p"; then ps+=("$p"); cs+=("$r/$p")` (`:1280`), queued as `qs+=("${cs[i]}")` (`:1288`, `:1293`). The walks then read it through `import_file "$f" ...` (`:1576`, `:1674`), which routes `/*` to import_outside (`:1207`). The parenthetical lists only the second channel and outside_seeds starts, so it no longer names every FILE the walks pass. Precise version: "...or an outside_seeds start or another root's copy (root_copies), either of which may lie in another root".

**Evidence:** `scripts/lib/dev-cycle-read.sh:1176-1180`, `:1207`, `:1280`, `:1288`, `:1576`, `:1674`

---

## Claim 13: "outside_ok PATH: whether a walk reads PATH, an absolute name (one below no reader root, or an outside_seeds start, which may lie in another root): a readable regular file (the one admission rule both walks apply)."

**Location:** `scripts/lib/dev-cycle-read.sh:1208-1211`
**Type:** Architectural / Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the list of PATH kinds. The rule itself (`-f` and `-r`) is unchanged and correct.

root_copies now admits copies with the same rule, `if outside_ok "$r/$p"; then ...` (`:1280`), and with_at's filter predates this branch. So outside_ok's PATH kinds now include another root's copy, which the parenthetical does not name. Precise version: add "or another root's copy (root_copies)".

**Evidence:** `scripts/lib/dev-cycle-read.sh:1208-1212`, `:1280`

---

## Claim 14a: root_copies' admission clauses: "The array Q is cleared, then, for each NAME (an absolute one or a // name is skipped) not yet a key of the associative array CMP (it then is one) and each IMPORT_OTHER root, gets ROOT/NAME when outside_ok admits it, unless NAME is no prompt, rawfile's test holds on both sides (...) and their bytes are equal (the walks read ROOT_REAL's file, or main's, which contract item 2 makes the same, and resolve its relative names against every root; a prompt copy is always read, since its absolute path can add prompt bases: i2 fact-check 16), and //ROOT/NAME when it is a link outside_ok rejects (...). A copy of a NAME the associative array PDIR holds (a prompt) is added to it, lower-cased, so it is read as one, and its // form too, so the walks read the projected names as prompts (prompt_marks). (...) The realpaths and the sha1sums run in xargs batches; it returns 1 when one fails or lower does."

**Location:** `scripts/lib/dev-cycle-read.sh:1251-1266`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each clause against root_copies' whole body (`:1272-1299`) and its four call sites. It does not establish that the `//` form of a prompt copy is driven by a test (override row 601), or that the "resolve against every root" argument holds for prompts, which the clause itself excludes.

- **Q cleared:** `rc_q=()` (`:1274`).
- **Skips:** `[[ -n "$p" && "$p" != /* && -z "${rc_c[$p]+set}" ]] || continue; rc_c[$p]=1` (`:1278`). A `//` name starts with `/`.
- **Skip only when all hold:** `[[ -z "${rc_p[${ps[i]}]+set}" && -f "${ps[i]}" && "${rl[i]}" == "$ROOT_REAL/${ps[i]}" && "${rl[n + i]}" == "${cs[i]}" ]]` (`:1288`) admits a name to the hash list. Only equal hashes drop it: `[[ "${rl[2*i]:0:40}" == "${rl[2*i+1]:0:40}" ]] || { qs+=...; }` (`:1293`). The copy side's `-f` comes from outside_ok (`:1280`).
- **Both sides via one xargs realpath:** `printf '%s\0' "${ps[@]}" "${cs[@]}") realpath -mz --` (`:1286`).
- **`//` form:** `elif [[ -L "$r/$p" ]]; then qs+=("/$r/$p")` (`:1281`).
- **PDIR marking:** `[[ -z "${rc_p[${qn[i]}]+set}" ]] || rc_p[${qs[i]}]="$(lower "${qs[i]}")" || return 1` (`:1296`). This covers both plain and `//` entries.
- **"resolve its relative names against every root":** import_targets joins a relative DIR "under every reader root", while an absolute one is "joined as it is" (`:819-822`). So for a non-prompt plain copy with equal bytes, ROOT_REAL's read already yields each root's resolution. The 242-name identity across main's and HEAD's libs (E1) is consistent with this.

E2: tests 2 and 4 (the linked-directory copy and the equal-bytes prompt copy) pass on HEAD. They are red on f7e1bea2's and c69f352f's libs respectively.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1248-1299`, `:817-822`; Appendix A E1, E2, E3

---

## Claim 14b: "Not covered: a copy below a dangling linked directory in that root, which is skipped (A5's class)."

**Location:** `scripts/lib/dev-cycle-read.sh:1266-1267`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers which copy paths fall through both of root_copies' arms. It does not assess whether the wider case can hide an import a session loads.

The skip happens whenever `ROOT/NAME` is neither admitted nor a link itself: `if outside_ok "$r/$p"; then ... elif [[ -L "$r/$p" ]]; then ...; fi` (`:1280-1281`). Below a dangling directory link, `-L` on the leaf fails (lstat fails), so the stated case is skipped as claimed. The same happens below a *live* linked directory whose target lacks NAME. For example, `ROOT/docs -> elsewhere` with no `elsewhere/x.md` gives `-f` false and `-L` false, so the path is skipped with no projection, although outside_proj would project it as `realpath -m` names it (paraphrased, no quote available because this follows from the two tests at `:1280-1281` and is not a separate code path). Precise version: "a copy below a linked directory in that root (dangling, or whose target lacks the file)".

**Evidence:** `scripts/lib/dev-cycle-read.sh:1266-1267`, `:1279-1282`, `:1221-1231`

---

## Claim 14c: "The cost: about 11 ms per copy read, and a copy is read in every root holding it with other bytes (i1 performance F1: 13 s over 8 worktrees at a commit where 50 imported files differ; one read per distinct bytes would miss a .. name that leaves its root, which resolves differently in each)."

**Location:** `scripts/lib/dev-cycle-read.sh:1267-1271`
**Type:** Performance / Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the per-copy price on /workspace (E7), the per-root read (code), the cited figure (the performance review's table) and the dedupe rationale (how import_targets treats absolute DIRs). It does not re-run the 8-worktree synthetic fixture.

The per-root read follows from the loop `for r in "${rs[@]}"` (`:1279`), which queues each root's differing copy under its own path. The performance review reports "8 | main / branch | 0.88-0.91 / 12.7-13.4 s" (`docs/reviews/performance-review-2026-10-09-u2b3b2c-i1.md:26`) and "Each extra read costs about 10-12 ms" (`:29`). E7 measured 9.2-11.5 ms. The dedupe rationale holds because a copy is read through import_outside with its own absolute directory, `import_targets "${d:-/}"` (`:1197`), and an absolute DIR is "joined as it is" (`:821`). A `..` that leaves the root therefore resolves against that root's parent only.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1267-1271`, `:1197`, `:1279`, `:819-822`; `docs/reviews/performance-review-2026-10-09-u2b3b2c-i1.md:26-29`; Appendix A E7

---

## Claim 15: prompt_marks: "after F, a // queue entry the associative array PDIR holds (a dangling prompt link), is projected, each repo name in the variable OUT is read as a prompt, as a session reads the link's target: PDIR gets it lower-cased (its own prompt bases), and the associative array PEXT gets the link's directory and the link's own prompt bases (absolute, newline-separated), which the walks add to its DIRS (...: a link under a nested .claude/). A name already read is not read again as a prompt: a named exception. It returns 1 when lower fails."

**Location:** `scripts/lib/dev-cycle-read.sh:1300-1307`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the function body, both call sites and both walks' use of pext, for a link at side's top-level `.claude/commands/` and one under `side/sub/.claude/commands/`. The main walk is covered in its 100644 and checkout arms, and its 120000 arm refuses. It does not cover a name the walk already read plain (override row 595), or root_copies' copies of a projected name, which get their own path's bases and not the link's.

Body: `prompt_bases pm_b "${pm_p[$4]#/}" "$l"` with `l="${4#/}"`, then `printf -v b '%s\n' "${l%/*}" "${pm_b[@]:1}"` (`:1310-1311`). That is the link's directory plus every directory holding a `.claude/` component in the link's absolute path (prompt_bases, `:670-679`). The `""` base is dropped, and pdir's own `""` supplies it. Each repo name gets `pm_p[$p]` when unset and `pm_x[$p]` appended (`:1313-1315`). Both walks consume it, before the read, with `[[ -z "${pext[$f]+set}" ]] || mapfile -t -O "${#xs[@]}" xs <<<"${pext[$f]}"` (`:1573`, `:1670`). Both read arms pass `"${xs[@]}"`: the checkout arm via import_file (`:1674`), and the 100644 arm via `import_targets "$d" "${xs[@]}"` (`:1676`). With xs non-empty, the 120000 arm fails the walk (`:1680`; E6).

The call order puts prompt_marks before the name loop and root_copies (`:1578` before `:1583-1590`, and `:1706` before `:1711-1721`), so a name first reached through the link is marked before it is queued or compared. E2: test 3 passes on HEAD in both walks with `docs/t.md`, `top.md` and `sub/top2.md` imported. It was red on f7e1bea2 (`top.md: -`) and on c69f352f (`sub/top2.md: -`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1300-1317`, `:670-679`, `:1572-1578`, `:1669-1680`, `:1706`; `test/scripts/build-loop-check.bats:786-796`; Appendix A E2, E3, E6

---

## Claim 16: outside_seeds: "array NAME gets the walks' outside starts (...): config_seeds', then c1_seeds'. It returns 1 when either does, or a seed's path holds a newline. Run it after import_readers (IMPORT_ROOTS, IMPORT_HOMES and IMPORT_OTHER)."

**Location:** `scripts/lib/dev-cycle-read.sh:1318-1323`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the wrapper, and identical output to f7e1bea2's and c69f352f's libs on /workspace. It does not cover fixtures beyond /workspace (the i2 report's E1 covered one where a path is both a config and a C1 seed).

`config_seeds os_a || return 1; c1_seeds os_c || return 1; os_a+=("${os_c[@]}"); for d in "${os_a[@]}"; do [[ "$d" != *$'\n'* ]] || return 1; done` (`:1327-1330`). config_seeds reads IMPORT_ROOTS and IMPORT_HOMES (`:1351`), and c1_seeds reads IMPORT_OTHER (`:1425`). E9: 9 seeds (1 `f`, 8 `p`) under HEAD's, f7e1bea2's and c69f352f's libs, with `diff` empty.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1318-1331`, `:1351`, `:1425`; Appendix A E9

---

## Claim 17: config_seeds: "(...) Only a seed holding an @ byte, or whose real path differs and lies below a reader root (a link the walks project as that repo path; a dangling one included: U2b3b2b final security F1), can yield a name, so the rest are dropped (...). It returns 1 when a find, grep, realpath or lower_all fails, or CLAUDE_CONFIG_DIR is set but not absolute."

**Location:** `scripts/lib/dev-cycle-read.sh:1332-1346`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the keep rule and the failure list. It does not cover python3's failure, which falls back to the cache directories instead of failing (`:1369-1374`, unchanged).

Dangling links are listed: `find -L ... '(' -type f -o -type l ')'` (`:1377-1380`; under -L, `-type l` matches only a broken link) and `find -H ... '(' -xtype f -o -xtype l ')'` (`:1387`). The keep rule is `in=""; [[ -z "${cs_at[${cx[i]}]+set}" ]] || in=1; [[ -n "$in" || "${rl[i]}" == "${cx[i]}" ]] || for q in "${rs[@]}"; do [[ "${rl[i]}" != "$q"/* ]] || in=1; done` (`:1399-1400`). E2 test 5 (a config CLAUDE.md and a rules link dangling into side, plus one to /nonexistent) passes on HEAD and is red on main's lib.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1332-1403`; Appendix A E2, E3

---

## Claim 18a: c1_seeds: "every start file (...) in another reader root present here (IMPORT_OTHER), tracked or not, that holds an @ byte or is a link (a dangling one included: the walks project it). (...) One is skipped when it is not a link and ROOT_REAL holds a plain file (rawfile) at its path below its innermost root that is a start of the same kind (f or p) there: both walks start at that file and pass it to root_copies (...). It returns 1 when a find, grep or lower_all fails."

**Location:** `scripts/lib/dev-cycle-read.sh:1404-1414`, `:1420-1421`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the seed set, the skip rule, and the claim that each skipped seed's path reaches root_copies from both walks' start calls with pdir set. It assumes contract item 2's clean checkout, as the comment states. It does not cover a dirty checkout.

Seed rule: `isstart "${lo[i]}" && [[ -n "${c1_at[${cx[i]}]+set}" || -L "${cx[i]}" ]] || continue` (`:1442`). Skip rule: `[[ ! -L "${cx[i]}" && "$q" == "$c" ]] && isstart "$d" && rawfile "${ir[i]}" || c1_a+=("$c${cx[i]}")` (`:1447`). Here `ir[i]` is the path below the innermost root in IMPORT_OTHER (`:1437`), so root_copies' `"$r/$p"` for that root is exactly `cx[i]`. The tree walk's starts are every ls-files and untracked .md name passing `isstart` and `inrepo_here` (`:1547-1554`). rawfile implies inrepo_here's no-link condition, so ROOT_REAL's file is a start, and `prompt_dir pdir` marks it when it is a prompt (`:1554`). The main walk's starts are main's isstart names and the checkout's (`:1644-1651`). Both call root_copies over all starts after pdir is set (`:1567`, `:1663`). E9: seeds unchanged across libs on /workspace.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1404-1449`, `:1547-1567`, `:1640-1664`; Appendix A E9

---

## Claim 18b: "...pass it to root_copies, which reads this copy when its bytes differ"

**Location:** `scripts/lib/dev-cycle-read.sh:1413-1414`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the read condition root_copies applies to a skipped C1 seed. The omission understates reads (fail-closed direction). It misses no import.

For a skipped `p` seed, the name is in pdir, so root_copies never takes the equal-bytes path: `[[ -z "${rc_p[${ps[i]}]+set}" && ... ]]` fails and the copy goes straight to `qs` (`:1288`). As of 007e867f a prompt copy is read whatever its bytes. The comment still states the bytes condition alone. Precise version: "which reads this copy when its bytes differ, and a prompt's always".

**Evidence:** `scripts/lib/dev-cycle-read.sh:1413-1414`, `:1288`, `:1259`

---

## Claim 19: "# rawfile, not -f, on ROOT_REAL's copy: one reached through a link there is no tree walk start (U2b3b2b i1 fact-check 19b)."

**Location:** `scripts/lib/dev-cycle-read.sh:1444`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the tree walk. It does not cover the main walk, which can start at a symlinked start main stores. That is why the comment names the tree walk (B3).

The tree walk admits a start only through `inrepo_here "$f"` (`:1552`), which requires `blocker` to print nothing, and blocker refuses any non-plain part of the path (`:174-184`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1444`, `:1552`, `:174-191`

---

## Claim 20: The seed-loop and start-pass comments in both walks: "a dangling link as //PATH, which the loop projects alone (outside_proj)"; "c1_seeds skips another root's start that has the same kind here only because every start passes through here, pdir already set."

**Location:** `scripts/lib/dev-cycle-read.sh:1556-1557`, `:1564-1566`, `:1652-1653`, `:1660-1662`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the four comments against the code they precede. The coupling's correctness is Claim 18a.

`p="/$p"` for a link outside_ok rejects (`:1560`, `:1656`). pdir is set by `prompt_dir` (`:1554`, `:1647`) and by the seed loops (`:1562`, `:1658`), all before `root_copies cq cmp pdir "${queue[@]}"` (`:1567`) and `... "${queue[@]}" "${tq[@]}"` (`:1663`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1556-1568`, `:1652-1664`

---

## Claim 21: Inline comments: "# a dangling prompt link's bases (prompt_marks)"; "# a dangling link: outside_proj reads its real path alone" / "...outside_proj below reads its real path alone"

**Location:** `scripts/lib/dev-cycle-read.sh:1573`, `:1575`, `:1670`, `:1673`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the lines they annotate. It does not cover outside_proj's own behaviour beyond the `//` entry.

pext is written only by prompt_marks (`:1315`). For `//*`, `out="$f"`, and the next statement runs `outside_proj out work` (`:1578`, `:1706`). outside_proj reads every `//` line outside_ok rejects, realpath -m's it, and projects the ones that differ (`:1224-1230`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1573-1578`, `:1670-1675`, `:1706`, `:1221-1231`

---

## Claim 22: main_imports fails when "outside_seeds, root_copies or prompt_marks fails"

**Location:** `scripts/lib/dev-cycle-read.sh:1600`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three added sources. It does not re-verify the pre-existing list.

`IMPORTED_MAIN=error` is set first (`:1618`). Then `outside_seeds sd || return 1` (`:1654`), `root_copies ... || return 1` (`:1663`), `prompt_marks pdir pext out "$f"; } || { IMPORTED_MAIN=error; return 1; }` (`:1706`), and `root_copies cq cmp pdir "${nm[@]}" || { IMPORTED_MAIN=error; return 1; }` (`:1721`). E2 test 6's main half: `walk: failed` on HEAD, `walk: ok` on main's lib.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1600`, `:1618`, `:1654`, `:1663`, `:1706`, `:1721`; Appendix A E2, E3

---

## Claim 23: "Phase 2 begins when queue empties: tq's checkout files and outside files (absolute paths, never main's: outside seeds, // imports and other roots' copies, and //PATH entries, dangling links outside_proj projects) then join it, and a path main lacks reads the checkout."

**Location:** `scripts/lib/dev-cycle-read.sh:1607-1610`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what joins tq. It does not cover names main has that a phase-2 file reaches. Those join `queue` directly (`:1719`), which the comment does not claim otherwise.

tq receives the seeds (`:1658`), the copies (`:1664`, `:1722`), the `//` imports (`:1714`) and the checkout-only names (`:1719`). `case "${ent[$f]-checkout}"` sends every non-main path, `//PATH` included, to the checkout arm (`:1672-1673`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1607-1610`, `:1649`, `:1658`, `:1664`, `:1667-1675`, `:1714-1722`

---

## Claim 24: Test title "both walks read another worktree's copy of a name they reach when this checkout lacks it or its bytes differ, through chains there; a prompt's copy reads as a prompt; a dangling one is projected (U2b3b2c; U2b3b2b i1 security F1)"

**Location:** `test/scripts/build-loop-check.bats:761`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each clause against the fixture (`docs/a.md` differs, `docs/n.md` side-only, `c` through the chain, `k2` via the prompt, a dangling `b` leading to `gone`) and the test's red state on main's lib. It does not cover a nested-root layout.

Assertions: `want walk ok; for f in b n c k2 gone; do want "docs/$f.md" imported; done; want docs/e.md -` (`:772`). E2 shows the test passes on HEAD. On main's lib it fails with `docs/b.md: -`, `docs/n.md: -`, `docs/c.md: -` and `docs/gone.md: -`.

**Evidence:** `test/scripts/build-loop-check.bats:761-774`; Appendix A E2, E3

---

## Claim 25: "# side's prompt differs, so C1 leaves it to the name: its @docs/k2.md resolves against side's top level only as a prompt."

**Location:** `test/scripts/build-loop-check.bats:767`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the causal "differs, so C1 leaves it". The second half (resolution against side's top level as a prompt) is correct. It does not affect the assertion.

On this branch C1's skip ignores bytes. side's `.claude/commands/k.md` is not a link, has the same kind, and ROOT_REAL holds it plain, so `[[ ! -L "${cx[i]}" && "$q" == "$c" ]] && isstart "$d" && rawfile "${ir[i]}"` (`scripts/lib/dev-cycle-read.sh:1447`) skips it whatever its bytes. As a prompt it is then always read by root_copies (`:1288`). The differing bytes are what give side's copy the `@docs/k2.md` to find, not why C1 leaves it to the name. Precise version: "ROOT_REAL holds this prompt plain, so C1 leaves it to the name; side's differs, and its @docs/k2.md ...".

**Evidence:** `test/scripts/build-loop-check.bats:767-768`; `scripts/lib/dev-cycle-read.sh:1447`, `:1288`

---

## Claim 26: Test title "a copy with this checkout's bytes under a linked directory is read, so its real path is projected (U2b3b2c; i1 security F2)"

**Location:** `test/scripts/build-loop-check.bats:776`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a live linked directory holding the file. It does not cover one whose target lacks it (Claim 14b).

`mv "$sd/docs" "$sd/real" && ln -s real "$sd/docs"`, then `want real/x.md imported` in both walks (`:781-782`). E2: passes on HEAD. It is red on main's and f7e1bea2's libs (`real/x.md: -`).

**Evidence:** `test/scripts/build-loop-check.bats:776-784`; Appendix A E2, E3

---

## Claim 27: "# (A plain copy with equal bytes is skipped as a cost: the parser already resolves this checkout's relative names against every root, so reading it could add nothing.)"

**Location:** `test/scripts/build-loop-check.bats:777-778`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the comment against root_copies at HEAD. It holds for a non-prompt plain copy, the case this test builds (`docs/x.md`). It does not hold for a prompt.

Since 007e867f a plain *prompt* copy with equal bytes is not skipped: `[[ -z "${rc_p[${ps[i]}]+set}" && -f ... ]]` (`scripts/lib/dev-cycle-read.sh:1288`). Reading it can add names, because its absolute path adds prompt bases. Test 4 (`:798-802`) asserts exactly that, and E2 shows it red on c69f352f's lib. The comment was flagged in i2 (claim 16, B2). The code was fixed, but the comment still lacks the non-prompt qualifier. Precise version: "A plain copy of a non-prompt name with equal bytes is skipped ...".

**Evidence:** `test/scripts/build-loop-check.bats:777-778`, `:798-802`; `scripts/lib/dev-cycle-read.sh:1259`, `:1288`; Appendix A E2

---

## Claim 28: Test title "a dangling prompt link in another worktree reads its target as a prompt (U2b3b2c i1 security F1)" and comment "# Under a nested .claude/, the link's own bases (side/sub) apply to its target's names too (i2 fact-check 9b)."

**Location:** `test/scripts/build-loop-check.bats:786-789`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both links (top-level and nested `.claude/`) in both walks, and the red state on each prior lib. It does not cover a target already read plain.

`want walk ok; want docs/t.md imported; want top.md imported; want sub/top2.md imported` for `w in tree main` (`:791-795`). E2: passes on HEAD. On main's lib `docs/t.md: -`; on f7e1bea2 `top.md: -`; on c69f352f `sub/top2.md: -`.

**Evidence:** `test/scripts/build-loop-check.bats:786-796`; Appendix A E2, E3

---

## Claim 29: Test title "a prompt copy with this checkout's bytes is still read: a worktree under a .claude/ adds prompt bases (U2b3b2c i2 fact-check 16)"

**Location:** `test/scripts/build-loop-check.bats:798`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the fixture (worktree at `$h/.claude/wt`, `$h/z.md` importing an absolute path into this repo) in both walks. It does not cover the `//` form of a prompt copy (override row 601).

The worktree's `.claude/commands/k.md` has this checkout's bytes, and its `@z.md` resolves against base `$h` only through the copy's absolute path. `want docs/z2.md imported` holds in both walks on HEAD. It is red on main's, f7e1bea2's and c69f352f's libs (E2).

**Evidence:** `test/scripts/build-loop-check.bats:798-802`; Appendix A E2, E3

---

## Claim 30: Test title "a seed that is a dangling link into another worktree reads as the repo path it names (U2b3b2c; U2b3b2b final security F1)"

**Location:** `test/scripts/build-loop-check.bats:804`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a config CLAUDE.md link and a rules link dangling into side, and a link to /nonexistent that is dropped. It does not cover C1 dangling seeds, which test 3 covers.

`want docs/n.md imported; want docs/r.md imported; want docs/deep.md imported; want docs/other.md -` (`:811`). E2: passes on HEAD, red on main's lib (all three `-`).

**Evidence:** `test/scripts/build-loop-check.bats:804-813`; Appendix A E2, E3

---

## Claim 31: Test title "both walks fail closed when another worktree's copy cannot be compared with this checkout's (U2b3b2c)" and comment "# The main walk reads main's blob, so only the comparison reads the unreadable checkout file."

**Location:** `test/scripts/build-loop-check.bats:815-819`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the unreadable-file and failing-sha1sum cases in both walks. It does not cover a failing realpath, which has no test.

E2 on main's lib: the tree half passes, because the tree walk fails reading the file itself (E5: `line 1190: docs/a.md: Permission denied tree failed`). The main half fails with `walk: ok`, which confirms that only the comparison reads the checkout file in the main walk. On HEAD both halves give `walk: failed`. With a side worktree, E5 shows HEAD's tree walk fails first at `sha1sum: docs/a.md: Permission denied`.

**Evidence:** `test/scripts/build-loop-check.bats:815-823`; Appendix A E2, E3, E5

---

## Claim 32: Rubric: each fix's test is red on the lib before it ("test ... red on f7e1bea2" for A1 and A2; "red on c69f352f" for B1 and B2)

**Location:** `docs/reviews/code-review-rubric-2026-10-09-feat-build-loop-u2b3b2c.md:15`, `:21`, `:39-40`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the six U2b3b2c tests under main's, f7e1bea2's and c69f352f's libs swapped into scratch copies. It does not re-run A3's mutant (verified in i2's E4).

E2 results:

| Lib | Tests red |
|---|---|
| main | 1-6 (all six) |
| f7e1bea2 | 2 (A2), 3 (A1: `top.md: -`), 4 |
| c69f352f | 3 (B1: `sub/top2.md: -`), 4 (B2) |

**Evidence:** Appendix A E2

---

## Claim 33: Inventory: root_copies, prompt_marks, config_seeds, c1_seeds are defined and IMPORT_OTHER is declared after sourcing

**Location:** `test/scripts/dev-cycle.bats:1111-1115`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the presence check. It does not check that every lib function is listed.

The four functions are defined at `scripts/lib/dev-cycle-read.sh:1272`, `:1308`, `:1347`, `:1422`, and IMPORT_OTHER at `:1075`. dev-cycle.bats ran 79/79 ok (E3).

**Evidence:** `test/scripts/dev-cycle.bats:1111-1115`; Appendix A E3

---

## Claim 34: Commit f7e1bea2: "Over /workspace (7 other present roots) both walks give main's 242 names; the reads add about 0.05 s per walk (tree 1.93 s, main 2.09 s). Suites 284 green"

**Location:** commit f7e1bea2 message
**Type:** Performance / Configuration
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the 242 names and 7 roots under f7e1bea2's lib today, and the order of magnitude of the added time. It does not re-run the 284-test count at f7e1bea2, which the i1 report verified (its Claim 19: 128+79+20+2+2+53).

E1: f7e1bea2's lib gives 242 names in each walk, identical to main's lib, with IMPORT_OTHER at 7 lines. E8 (HEAD's lib, root_copies stubbed against live): +0.06-0.15 s per walk at load 3.1. This is the same order as "about 0.05 s", and HEAD reads 4 copies through extra code that f7e1bea2 did not have.

**Evidence:** `git log -1 f7e1bea2`; Appendix A E1, E8

---

## Claim 35: Commit 8976fbdf: "outside_seeds split into config_seeds and c1_seeds behind the wrapper; same seeds"; "Suites 286/286"; "both walks over /workspace give main's 242 names. 357 changed code lines."

**Location:** commit 8976fbdf message
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the seeds on /workspace, the line count at 8976fbdf, and 286 as HEAD's 287 minus the one test added by 007e867f. It does not re-run the suites at 8976fbdf.

E9: identical seeds under f7e1bea2's and HEAD's libs. E10: `git diff --numstat main...8976fbdf -- ':(top)' ':(top,exclude)docs/' | awk ...` prints 357. 007e867f adds exactly one `@test` (test 4, see its diff), and 287 − 1 = 286.

**Evidence:** `git log -1 8976fbdf`; `git show 007e867f -- test/`; Appendix A E9, E10

---

## Claim 36: Commit c69f352f: "the lite check read the moved comment as describing the seed; it describes ROOT_REAL's copy."

**Location:** commit c69f352f message
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers what the comment describes. It does not verify what the lite check's reader thought.

The comment sits over `rawfile "${ir[i]}"` (`scripts/lib/dev-cycle-read.sh:1444-1447`), a path relative to ROOT_REAL (`:163`).

**Evidence:** `git show c69f352f`; `scripts/lib/dev-cycle-read.sh:1444-1447`

---

## Claim 37: Commit 007e867f: "Suites 287/287 (serial); both walks over /workspace give main's 242 names; 377 changed code lines."

**Location:** commit 007e867f message
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the six suites summing to 287 (build-loop-check 131, build-loop-read 20, dev-cycle 79, fixture-git-env 2, fixture-hermeticity 2, hermeticity-lint 53), run serially; today's /workspace registry; and the numstat command at HEAD. It does not cover `-j` runs.

E3: all six suites rc=0, with 287 `ok` lines, 0 `not ok` and 0 `# skip`. E1: HEAD's lib gives 242 names in each walk, sorted lists identical to main's lib and to each other. E10: the numstat command prints 377 (216+93 lib, 64+0 build-loop-check, 2+2 dev-cycle), under the ~400 cap. This matches the logged "specific measured test count" pattern class, and here it holds.

**Evidence:** `git log -1 007e867f`; Appendix A E1, E3, E10

---

## Claims Requiring Attention

### Incorrect
- None.

### Stale
- **Claim 12** (`scripts/lib/dev-cycle-read.sh:1176-1178`) [for-author]: import_outside's list of absolute FILEs the walks pass omits root_copies' copies, which it now reads. Add "or another root's copy (root_copies)".
- **Claim 13** (`scripts/lib/dev-cycle-read.sh:1208-1209`) [for-author]: outside_ok's list of PATH kinds omits root_copies' copies, which it now admits. Same addition.

### Mostly Accurate
- **Claim 14b** (`scripts/lib/dev-cycle-read.sh:1266-1267`) [for-author]: the not-covered case is wider than "a dangling linked directory". A copy below a live linked directory whose target lacks the file is skipped the same way, with no projection. Say "below a linked directory (dangling, or whose target lacks the file)".
- **Claim 18b** (`scripts/lib/dev-cycle-read.sh:1413-1414`) [for-author]: "reads this copy when its bytes differ" omits that a prompt copy is always read (since 007e867f). Add "and a prompt's always". This errs toward reading more.
- **Claim 25** (`test/scripts/build-loop-check.bats:767`) [for-author]: C1 leaves side's prompt to the name because ROOT_REAL holds it plain, not because its bytes differ. The difference is what gives it `@docs/k2.md`.
- **Claim 27** (`test/scripts/build-loop-check.bats:777-778`) [for-author]: "A plain copy with equal bytes is skipped ... could add nothing" lacks the non-prompt qualifier. B2 fixed the code; the comment kept i2 claim 16's wording.

### Unverifiable
- None.

(Verified claims 1-11, 14a, 14c, 15-17, 18a, 19-24, 26, 28-37 are tagged [for-orchestrator-synthesis].)

---

## Appendix A: execution provenance

Scratch dir `/tmp/fcf-r2-u2c-run-6eJB`. It held `head-lib.sh` (HEAD's lib), `main-lib.sh`, `f7e-lib.sh` and `c69-lib.sh` (`git show <rev>:scripts/lib/dev-cycle-read.sh`), and three `cp -a` copies of the worktree, `wt-main`, `wt-f7e` and `wt-c69`, each with its lib swapped. Every process ran under `timeout`. The walks over /workspace are read-only. Fixtures were built in their own `mktemp -d /tmp/fcf-r2-u2c-fx-XXXX` dirs and removed by the script. The scratch dir was removed at the end.

- **E1** (2026-10-10T06:12Z, cwd `/workspace`): `timeout 300 ./walks.sh <lib> /workspace <prefix>` for the head and main libs, and later f7e. The script runs `source lib; ROOT_REAL=$(pwd -P); LC_ALL=C; resolve_main; reader_settings; imported_names; main_imports`, then writes sorted non-`//` names. All runs rc=0. Head: `tree rc=0 / tree secs 1.82898 / main rc=0 / main secs 2.14123 / 242 / 242 / IMPORT_OTHER lines: 7`. Main: `tree secs 1.83022 / main secs 2.02429 / 242 / 242`. `diff` of head against main (tree and main lists) and of head's tree against head's main printed `IDENT`. f7e: `242 / 242 / IMPORT_OTHER lines: 7`, and `diff` against main printed `F7E-IDENT`.
- **E2** (2026-10-10T06:13:02Z-06:13:08Z, cwd `wt-main`, `wt-f7e`, `wt-c69`): `TMPDIR=$(mktemp -d) timeout 900 bats -f 'U2b3b2c' test/scripts/build-loop-check.bats`, rc=1 for each lib (`1..6`).
  - main: `not ok` 1-6, with `docs/b.md: -`, `real/x.md: -`, `docs/t.md: -`, `docs/z2.md: -`, `docs/n.md: -`, and test 6 `want: walk: failed / walk: ok`.
  - f7e: `not ok` 2 (`real/x.md: -`), 3 (`top.md: -`), 4 (`docs/z2.md: -`); `ok` 1, 5, 6.
  - c69: `not ok` 3 (`sub/top2.md: -`), 4 (`docs/z2.md: -`); `ok` 1, 2, 5, 6.
- **E3** (2026-10-10T06:11:48Z-06:13:41Z, cwd the review worktree, read-only): `run.sh` ran each of `test/scripts/build-loop-check.bats`, `build-loop-read.bats`, `dev-cycle.bats`, `fixture-git-env.bats`, `test/fixture-hermeticity.bats` and `test/hermeticity-lint.bats` as `TMPDIR=$(mktemp -d /tmp/fcf-r2-u2c-t-XXXX) timeout 1500 bats <suite>`, serially. All rc=0. Plans: `1..131`, `1..20`, `1..79`, `1..2`, `1..2`, `1..53`. `grep -c '^ok '` gave 287, `grep '^not ok'` nothing, and `grep -c '# skip'` 0.
- **E4** (06:12:30Z, cwd `/workspace`): `RCTIME=1 timeout 300 ./walks.sh head-lib.sh /workspace rt`, run 3 times, wraps root_copies with `$EPOCHREALTIME` deltas. Output: tree `rc_calls=31 copies=4 rc_secs=0.0648634 / 0.0703292 / 0.0721729`; main `rc_calls=31 copies=4 rc_secs=0.0848114 / 0.0811298 / 0.0849838`. Load average 1.71, with E3 running.
- **E5** (06:17Z): `SIDE={0,1} timeout 60 ./fx-unread.sh <lib>`: a repo whose AGENTS.md imports `docs/a.md`, chmod 000, optionally with a side worktree whose copy differs, then the tree walk only. Output: main lib `line 1190: docs/a.md: Permission denied tree failed` for both SIDE values; HEAD SIDE=0 `line 1207: docs/a.md: Permission denied tree failed`; HEAD SIDE=1 `sha1sum: docs/a.md: Permission denied tree failed`.
- **E6** (06:15Z): `timeout 120 ./fx-symlink.sh head-lib.sh`: main stores `docs/t.md` as a symlink to `real.md`, and side (docs/ removed) holds `.claude/commands/k.md -> ../../docs/t.md`. Output: `tree rc=0 / docs/t.md / main rc=1 / IMPORTED_MAIN=error`, script rc=0.
- **E7** (06:13Z, cwd `/workspace`): `timeout 200 ./percopy.sh head-lib.sh` collects root_copies' queued copies during imported_names, then times 10 `import_file` calls each. Output: `q125-cc-isolated-sandbox/skills/dev-cycle/SKILL.md 11.5 ms/read`, `wt-build-loop-u2a/... 9.4`, `wt-build-loop-u2b1a/... 9.3`, `wt-egress-dnsmasq-ipset/... 9.2`.
- **E8** (06:14:51Z, load average 3.10, cwd `/workspace`): `STUB={0,1} timeout 300 ./walks2.sh head-lib.sh /workspace st`, alternated 3 times (`STUB=1` replaces root_copies with one that empties Q). Output: stub=0 tree 1.80/1.74/1.82 s, main 3.07 (outlier)/2.02/1.99 s; stub=1 tree 1.74/1.67/1.67 s, main 1.81/1.82/1.88 s.
- **E9** (06:16Z, cwd `/workspace`): `timeout 120 ./seeds.sh <lib>` runs `import_readers; outside_seeds sd` and prints the seeds. head, f7e and c69 each gave rc=0 with 9 lines. `diff` was empty for all pairs (`SEEDS-IDENT`): 1 `f` seed, 8 `p` seeds.
- **E10** (06:11Z, cwd the review worktree): `git diff --numstat main...HEAD -- ':(top)' ':(top,exclude)docs/' | awk '{n+=$1+$2} END{print n}'` printed `377` (`216 93 scripts/lib/dev-cycle-read.sh`, `64 0 test/scripts/build-loop-check.bats`, `2 2 test/scripts/dev-cycle.bats`). The same command with `main...8976fbdf` printed `357`.

---

## Goal-Alignment Note

- **Success criterion (verbatim):** "A markdown report saved to the output path below, structured per the code-fact-check skill, with `Commit: 007e867f` as its first line."
- **Answered:** Yes. Every claim area in the brief was checked against the code that runs it, and the behavioural ones were executed. root_copies' header holds clause by clause, apart from a not-covered sentence narrower than the code's skip (14b). A dangling prompt link's target now resolves with the link's own directory and prompt bases, in both walks, for a top-level and a nested `.claude/`. The main walk's 100644 and checkout arms use pext, and its 120000 arm fails closed as named. The split's seeds are unchanged. Every U2b3b2c test is red on the lib the rubric names. 287 / 242 / 377 reproduce. No claim is Incorrect.
  - The non-Verified findings are text only: two comments outside the diff left stale by root_copies (import_outside's and outside_ok's lists of absolute paths), and four comments missing a qualifier (14b, 18b, 25, 27).
- **Out of scope:** code quality, and whether the wider not-covered case in 14b (a live linked directory whose target lacks the file) needs code or only words. The critics own that. The override rows listed in the shared brief were not re-filed.
- **Escalate:** Claim 14b to security, as a possible fail-open of the same class as A5. It is a layout in another worktree that the comment does not name: a linked directory whose target lacks a file main has, which outside_proj would project but root_copies skips. Whether it is a named exception or a fix is the orchestrator's call.
- **Decisions I made:** I verdicted 18b, 25 and 27 Mostly accurate rather than Incorrect. Each mechanism holds for the case it addresses, and each omission errs toward reading more (18b, 27) or misattributes a cause without changing an assertion (25). I verdicted 12 and 13 Stale because they were complete before this branch added a third kind of absolute path.
