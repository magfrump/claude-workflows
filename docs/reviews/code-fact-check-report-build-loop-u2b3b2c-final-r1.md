Commit: 007e867f
# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u2b3b2c (branch `feat/build-loop-u2b3b2c`, HEAD 007e867f, main 8e550626)
**Scope:** `git diff main...HEAD`, final confirming pass, replicate r1: `scripts/lib/dev-cycle-read.sh` (file header, contract item 9, walk doc block, import_readers' IMPORT_OTHER, rawfile, import_outside, outside_ok, root_copies, prompt_marks, outside_seeds, config_seeds, c1_seeds, imported_names, main_imports), `test/scripts/build-loop-check.bats` (the six U2b3b2c tests and the C1 test), `test/scripts/dev-cycle.bats` (inventory), and commit messages f7e1bea2, 8976fbdf, c69f352f, 007e867f
**Checked:** 2026-10-09 (container clock 2026-10-10T06:12Z-06:17Z UTC)
**Total claims checked:** 34
**Summary:** 28 verified, 2 mostly accurate, 3 stale, 0 incorrect, 1 unverifiable

I read the hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) first. The commit messages' specific counts (284, 286, 287 tests; 242 names; 357 and 377 lines) fall in the logged "specific measured test count" class, so I recounted each one (Claims 30a, 31 and 33). All of them hold. None of the findings is a fabricated symbol, so the log is unchanged. I wrote no other file. Execution provenance is in Appendix A. The raw captures were kept in my scratch directories and deleted afterwards under the probe-cleanup rule, so the appendix copies the output lines that matter.

Legibility tags: every non-Verified claim is **for-author**, except Claim 30b (Unverifiable), which is **for-orchestrator-synthesis** like every Verified claim.

---

## Claim 1: "Both walks also read … and, through root_copies, other roots' copies of the names they reach (sha1sum)"

**Location:** `scripts/lib/dev-cycle-read.sh:42-47`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the claim that both walks call root_copies and that root_copies runs sha1sum. It does not establish that the tool list is exhaustive: root_copies and config_seeds also run realpath, which the sentence does not name, and it never claimed to.

Both walks call it: `root_copies cq cmp pdir "${queue[@]}" || return 1` (`:1567`) and `root_copies cq cmp pdir "${nm[@]}"` (`:1590`) in imported_names, and `:1663`, `:1721` in main_imports. It hashes with `nul_list rl xargs -0r -a <(printf '%s\0' "${hs[@]}") sha1sum -z --` (`:1292`). sha1sum has left outside_seeds: grepping `sha1sum` over config_seeds and c1_seeds (`:1347-1449`) finds no hits (paraphrased — no quote available because the claim covers absence of code).

**Evidence:** `scripts/lib/dev-cycle-read.sh:42-47`, `:1292`, `:1567`, `:1590`, `:1663`, `:1721`

---

## Claim 2: Contract item 9: "nor IMPORT_ROOTS, IMPORT_HOMES, IMPORT_DOTNEST or IMPORT_OTHER: they are import_readers' results, which a cache hit does not recompute."

**Location:** `scripts/lib/dev-cycle-read.sh:95-98`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the claims that import_readers sets all four variables and that a cache hit returns before recomputing them. It does not establish that no caller sets them, since the item is an instruction.

The function clears all four on a miss: `IMPORT_READERS_DONE="$IMPORT_READERS_KEY"; IMPORT_ROOTS=""; IMPORT_HOMES=""; IMPORT_DOTNEST=""; IMPORT_OTHER=""` (`:1099`). It fills them at `:1128`, `:1138-1139` and `:1143-1145`. A hit returns first: `if [[ "$IMPORT_READERS_DONE" == "$IMPORT_READERS_KEY" ]]; then [[ -n "$IMPORT_ROOTS" ]]; return; fi` (`:1098`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1092-1146`

---

## Claim 3: Tree walk failure list: "It returns 1 … when the start listing (git ls-files, untracked_md, instruction_names), outside_seeds, root_copies, prompt_marks, lower, a file read, … fails"

**Location:** `scripts/lib/dev-cycle-read.sh:686-690`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three entries this branch added (outside_seeds, root_copies, prompt_marks) and the claim that IMPORTED reads "error" on each. It does not re-check the entries that predate the branch.

`IMPORTED=error` is set before any listing (`:1546`). `outside_seeds sd || return 1` (`:1558`) and `root_copies cq cmp pdir "${queue[@]}" || return 1` (`:1567`) return while IMPORTED is still error. Inside the loop: `outside_proj out work && { … || prompt_marks pdir pext out "$f"; } || { IMPORTED=error; return 1; }` (`:1578`) and `root_copies cq cmp pdir "${nm[@]}" || { IMPORTED=error; return 1; }` (`:1590`). Executed: the test "both walks fail closed when another worktree's copy cannot be compared…" passes at HEAD (E1, E2).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1539-1593`; Appendix A E1, E2

---

## Claim 4: Walk doc block: "A seed that is a dangling link joins the queue as a // name, which only outside_proj reads …; a prompt's projected names are read as prompts (prompt_marks; one the walk already read is not read again, and one main stores as a symlink fails the main walk, as a symlinked prompt start does)."

**Location:** `scripts/lib/dev-cycle-read.sh:753-757`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `//` queuing of dangling seeds, the reading of projected names as prompts, and both stated exceptions in both walks. It does not establish how often the "already read" exception fires: probe P3 shows that in the main walk it fires for any link target that main's own starts import (see the Goal-Alignment Note).

Seed loop: `p="${f:1}"; outside_ok "$p" || { [[ -L "$p" ]] || continue; p="/$p"; }` (`:1560`, `:1656`). Only outside_proj reads a `//` entry: `if [[ "$f" == //* ]]; then out="$f"` (`:1575`, `:1673`). prompt_marks only sets the mark when none is set: `[[ -n "${pm_p[$p]+set}" ]] || pm_p[$p]="$(lower "$p")"` (`:1314`). A name already seen is not queued again (`:1588`, `:1715`). The symlink arm refuses prompt directories: `[[ ${#xs[@]} -eq 0 ]] || { IMPORTED_MAIN=error; return 1; }` (`:1680`).

Executed (E3). P1: a top-level dangling prompt link gives `.claude/commands/sib.md: imported` in both walks. P2: when main stores the target as a symlink, the main walk prints `walk: failed`. P3: when main's AGENTS.md imports the target, the tree walk reaches `top.md: imported`, but the main walk gives `top.md: -`, which is the named exception.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1556-1563`, `:1575-1578`, `:1652-1659`, `:1672-1706`, `:1308-1317`; Appendix A E3

---

## Claim 5: Walk doc block: "For every repo name a walk reaches, a start included, root_copies also reads each other reader root's copy that ROOT_REAL lacks or holds with other bytes"

**Location:** `scripts/lib/dev-cycle-read.sh:757-762`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the sentence's mechanism (every reached repo name, starts included) and its two read conditions. It does not establish the full read set, which this sentence understates; that understatement is the finding.

root_copies also reads two kinds of copy with equal bytes, and the sentence names neither. The first is a prompt copy: the skip needs `-z "${rc_p[${ps[i]}]+set}"` (`:1288`). The second is a copy with a link on the way on either side: the skip needs `"${rl[i]}" == "$ROOT_REAL/${ps[i]}" && "${rl[n + i]}" == "${cs[i]}"` (`:1288`). It also queues `//ROOT/NAME` for a dangling link: `elif [[ -L "$r/$p" ]]; then qs+=("/$r/$p")` (`:1281`). root_copies' own header states all three (`:1254-1261`). A precise version would read: "…each other reader root's copy that ROOT_REAL lacks, holds with other bytes, or that is a prompt or reached through a link (or `//ROOT/NAME` for a dangling one)".

**Evidence:** `scripts/lib/dev-cycle-read.sh:757-762`, `:1272-1299`

---

## Claim 6: Walk doc block: "Named exceptions: a home or root this container cannot see …; a symlinked directory in another root (A5); and a C1 start or copy ROOT_REAL holds in a checkout that is not clean … Any seed listing find, grep or realpath cannot complete, or a root_copies realpath or sha1sum, fails the walk"

**Location:** `scripts/lib/dev-cycle-read.sh:763-767`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the failure sources (find and grep in config_seeds and c1_seeds, realpath in config_seeds, and realpath and sha1sum in root_copies) and the clean-checkout exception. It does not cover the inaccessible-host exception, which predates this branch.

Failure sources: `nul_list rl xargs … realpath -mz -- && … || return 1` (`:1286`), `… sha1sum -z -- && … || return 1` (`:1292`), the config_seeds find and realpath calls at `:1377-1397`, and `nul_list fl root_starts "$r" || return 1` (`:1430`). Executed: test 6 (unreadable checkout copy, and sha1sum stubbed to exit 1) gives `walk: failed` in both walks (E1, E2). Clean-checkout exception: root_copies compares the bytes of the checkout file, not of main's blob (`hs+=("${cs[i]}" "${ps[i]}")`, `:1288`), and c1_seeds skips by `rawfile "${ir[i]}"` on the checkout (`:1447`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1272-1299`, `:1347-1449`; Appendix A E1, E2

---

## Claim 7: "root_copies costs 66 ms per walk over 7 other roots here, and about 11 ms per copy it reads: a worktree at a commit where many imported files differ adds a read per file"

**Location:** `scripts/lib/dev-cycle-read.sh:775-777`
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers root_copies' own time per walk and the cost of one copy read on today's /workspace registry (7 other roots, 4 copies queued per walk). It does not establish the cost on another registry, or for copies larger than SKILL.md/AGENTS.md.

E4: wrapping root_copies over three runs gave tree 74.5/67.2/64.7 ms and main 70.6/68.7/68.4 ms, with 31 calls and 4 copies per walk at a load average of about 2.8. E5: `import_file` plus `lower` on 14 real copies (SKILL.md, AGENTS.md and CLAUDE.md from the other roots) cost 9.4/9.8/9.7 ms each. Add the walk's per-name loop and "about 11 ms" fits. The "adds a read per file" part follows from root_copies queuing one entry per (name, root) pair: `ps+=("$p"); cs+=("$r/$p")` (`:1280`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1272-1299`; Appendix A E4, E5

---

## Claim 8: "IMPORT_OTHER holds every root's real path but ROOT_REAL's that is a directory here, once each, newline-separated: the roots whose copies root_copies and outside_seeds read."

**Location:** `scripts/lib/dev-cycle-read.sh:1070-1072`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers how IMPORT_OTHER is built and who reads it. It does not cover the partial value left after a refusal (override row 596).

`p="${rs_real[i]}"; [[ $t == h || "$p" == "$ROOT_REAL" || -n "${rs_seen[o$p]+set}" || ! -d "$p" ]] || { rs_seen[o$p]=1; IMPORT_OTHER+="$p"$'\n'; }` (`:1128`). The trailing newline is stripped at `:1145`. Readers: root_copies at `:1275-1276` and c1_seeds at `:1425`. Through c1_seeds this matches the comment's "outside_seeds". E6: outside_seeds output on /workspace is identical under f7e1bea2's lib (which listed roots with realpath -m inside C1) and HEAD's (9 seeds; `diff` empty).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1092-1146`, `:1425`; Appendix A E6

---

## Claim 9: import_outside: "FILE, an absolute path (for the walks, a name from the parser's second channel, below no reader root, or an outside_seeds start, which may lie in another root)"

**Location:** `scripts/lib/dev-cycle-read.sh:1176-1179`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the list of what the walks pass as FILE. It does not question import_outside's behaviour.

The branch adds a third source that the list omits: another root's copy from root_copies. That is an absolute path inside another reader root, and it is neither a seed nor a second-channel name. root_copies queues it as `qs+=("${cs[i]}")` (`:1288`). Each walk then reads it through `import_file "$f" "$d" "${xs[@]}"` (`:1576`, `:1674`), and import_file sends every absolute path to import_outside (`:1207`). The precise text would add "or another root's copy (root_copies)".

**Evidence:** `scripts/lib/dev-cycle-read.sh:1176-1200`, `:1207`, `:1288`, `:1576`, `:1674`

---

## Claim 10: outside_ok: "whether a walk reads PATH, an absolute name (one below no reader root, or an outside_seeds start, which may lie in another root): a readable regular file (the one admission rule both walks apply)"

**Location:** `scripts/lib/dev-cycle-read.sh:1208-1211`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the parenthetical list of the names outside_ok admits. It does not question the rule itself (`-f` and `-r`).

root_copies now also admits other roots' copies with this function: `if outside_ok "$r/$p"; then ps+=("$p"); cs+=("$r/$p")` (`:1280`). The parenthetical names only second-channel names and seeds, so it is stale in the same way as Claim 9.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1208-1212`, `:1280`

---

## Claim 11: "# root_copies batches the same test: change the two together." (above rawfile), and root_copies' "rawfile's test is batched here (realpath -m with -f): change the two together."

**Location:** `scripts/lib/dev-cycle-read.sh:162`, `:1264-1265`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the claim that the two tests are equivalent for existing files. It does not cover rawfile's `-n ROOT_REAL` guard, which root_copies does not need because need_root runs first.

rawfile: `[[ -n "${ROOT_REAL:-}" && -f "$1" ]] && r="$(realpath -e -- "$1" 2>/dev/null)" && [[ "$r" == "$ROOT_REAL/$1" ]]` (`:163`). root_copies: `-f "${ps[i]}" && "${rl[i]}" == "$ROOT_REAL/${ps[i]}"`, where rl comes from `realpath -mz` (`:1286-1288`). Once `-f` holds, `-e` and `-m` resolve to the same path.

**Evidence:** `scripts/lib/dev-cycle-read.sh:162-163`, `:1286-1288`

---

## Claim 12: root_copies' header, clause by clause (Q cleared; skip of absolute or // names and of CMP keys; ROOT/NAME when outside_ok admits it "unless NAME is no prompt, rawfile's test holds on both sides … and their bytes are equal"; "resolve its relative names against every root"; "a prompt copy is always read, since its absolute path can add prompt bases"; //ROOT/NAME for a link outside_ok rejects; PDIR marking of the copy and its // form; batches and return 1; the A5-class not-covered sentence; the cost sentence)

**Location:** `scripts/lib/dev-cycle-read.sh:1248-1271`
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each clause listed against the function body (`:1272-1299`) and the parser it relies on (`:903`). It does not establish behaviour for a root whose real path holds a newline, which import_readers refuses upstream. The `//` form's PDIR mark is verified statically only, since no test drives it (override row 601).

- *Q cleared*: `rc_q=()` comes before the early `return 0` (`:1274-1275`).
- *Skips*: `[[ -n "$p" && "$p" != /* && -z "${rc_c[$p]+set}" ]] || continue; rc_c[$p]=1` (`:1278`). An absolute name and a `//` name both start with `/`.
- *Skip conditions*: the read is skipped only if `-z "${rc_p[${ps[i]}]+set}" && -f "${ps[i]}" && "${rl[i]}" == "$ROOT_REAL/${ps[i]}" && "${rl[n + i]}" == "${cs[i]}"` (`:1288`) and the sha1sums match (`:1293`). The copy side's `-f` comes from `outside_ok` (`:1280`). One xargs realpath covers both sides: `printf '%s\0' "${ps[@]}" "${cs[@]}"` (`:1286`).
- *"resolve its relative names against every root"*: in the parser, a relative directory is joined under every root and an absolute one as it stands: `if (substr(dirs[i], 1, 1) == "/") put(dirs[i] "/" c); else for (r = 1; r <= nr; r++) put(roots[r] "/" dirs[i] "/" c)` (`:903`). So the names of an equal-bytes plain copy are a subset of the names from ROOT_REAL's file. That also supports the cost sentence: a copy read under its own absolute directory resolves a `..` that leaves its root against that root only, so a dedupe by bytes alone would lose the other roots' resolutions.
- *Prompt copy always read*: executed. Test "a prompt copy with this checkout's bytes is still read…" passes at HEAD and fails on c69f352f's lib (E2).
- *// form*: `elif [[ -L "$r/$p" ]]; then qs+=("/$r/$p"); qn+=("$p"); fi` (`:1281`). Executed: removing this line makes test 1 fail with `want: docs/gone.md: imported` (E7).
- *PDIR marking*: `[[ -z "${rc_p[${qn[i]}]+set}" ]] || rc_p[${qs[i]}]="$(lower "${qs[i]}")" || return 1` (`:1296`). This applies to both the absolute and the `//` entries in qs.
- *A5 class*: a path below a dangling linked directory fails both `outside_ok` and `-L` (lstat of the leaf fails), so it is skipped (paraphrased — no quote available because the claim covers the fall-through of the `if/elif` at `:1280-1281`).
- *Cost*: 11 ms is checked in Claim 7. "13 s over 8 worktrees … 50 imported files" matches the i1 performance table's W=8 row of 12.7-13.4 s (`docs/reviews/performance-review-2026-10-09-u2b3b2c-i1.md:26`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1248-1299`, `:903`; Appendix A E2, E7

---

## Claim 13: prompt_marks' header: "PDIR gets it lower-cased (its own prompt bases), and the associative array PEXT gets the link's directory and the link's own prompt bases (absolute, newline-separated), which the walks add to its DIRS (… i2 fact-check 9b: a link under a nested .claude/). A name already read is not read again as a prompt: a named exception. It returns 1 when lower fails."

**Location:** `scripts/lib/dev-cycle-read.sh:1300-1307`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both walks for a dangling prompt link at a top-level `.claude/` and under a nested one, including the main walk's 100644 arm with absolute DIRS and its 120000 arm (fails closed). It does not establish that a session would otherwise resolve against the link's directory: that is a model of Claude Code that I did not trace.

`printf -v b '%s\n' "${l%/*}" "${pm_b[@]:1}"` (`:1311`) builds the link's directory plus its absolute bases (pm_b comes from `prompt_bases pm_b "${pm_p[$4]#/}" "$l"`, `:1310`). Index 0, the empty top-level base, is dropped. The top level is still covered because the target's own mark `pm_p[$p]="$(lower "$p")"` (`:1314`) gives it the `""` base, joined under every root. Both walks append PEXT: `mapfile -t -O "${#xs[@]}" xs <<<"${pext[$f]}"` (`:1573`, `:1670`). The 100644 arm passes xs to `import_targets "$d" "${xs[@]}"` (`:1676`), which joins absolute directories as they stand (`:903`). The 120000 arm fails when xs is non-empty (`:1680`).

Executed (E2, E3). Test 3 passes at HEAD; on c69f352f's lib it fails only at `sub/top2.md: -`. P1 (top-level link; the name resolves only against the link's directory `.claude/commands`) gives imported in both walks. P4 (nested link) gives `sub/a.md`, `sub/.claude/commands/b.md` and `a.md` imported in both walks. P2 gives main `walk: failed`. P3 confirms the already-read exception in the main walk.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1300-1317`, `:670-679`, `:1571-1578`, `:1667-1706`; Appendix A E2, E3

---

## Claim 14: outside_seeds: "config_seeds', then c1_seeds'. It returns 1 when either does, or a seed's path holds a newline. Run it after import_readers (IMPORT_ROOTS, IMPORT_HOMES and IMPORT_OTHER)."

**Location:** `scripts/lib/dev-cycle-read.sh:1318-1323`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the order, the return rules, the dependencies, and the claim of the same seeds as f7e1bea2's unsplit function on /workspace. It does not prove seed equality on every layout (the i2 report also checked a fixture).

`config_seeds os_a || return 1; c1_seeds os_c || return 1; os_a+=("${os_c[@]}"); for d in "${os_a[@]}"; do [[ "$d" != *$'\n'* ]] || return 1; done` (`:1327-1330`). config_seeds reads IMPORT_ROOTS and IMPORT_HOMES (`:1351`), and c1_seeds reads IMPORT_OTHER (`:1425`). E6: 9 seeds, identical to f7e1bea2's.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1324-1331`; Appendix A E6

---

## Claim 15: config_seeds' header: "Only a seed holding an @ byte, or whose real path differs and lies below a reader root (a link the walks project as that repo path; a dangling one included …), can yield a name … It returns 1 when a find, grep, realpath or lower_all fails, or CLAUDE_CONFIG_DIR is set but not absolute."

**Location:** `scripts/lib/dev-cycle-read.sh:1332-1346`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the keep rule, the inclusion of dangling links (`-type l` under `-L`, `-xtype l` under `-H`) and the return list. It does not cover python3's failure, which falls back to the cache directory rather than failing, and the comment does not claim it does.

Keep rule: `in=""; [[ -z "${cs_at[${cx[i]}]+set}" ]] || in=1; [[ -n "$in" || "${rl[i]}" == "${cx[i]}" ]] || for q in "${rs[@]}"; do [[ "${rl[i]}" != "$q"/* ]] || in=1; done` (`:1399-1400`). Dangling links: `'(' -type f -o -type l ')'` (`:1377-1380`) and `'(' -xtype f -o -xtype l ')'` (`:1387`). Executed: test 5 (`$HOME/.claude/CLAUDE.md` and `rules/r.md` dangling into side, `rules/x.md` dangling to `/nonexistent`) passes at HEAD and fails on main's lib (E1, E2).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1347-1403`; Appendix A E1, E2

---

## Claim 16: c1_seeds' header, including: "One is skipped when it is not a link and ROOT_REAL holds a plain file (rawfile) at its path below its innermost root that is a start of the same kind (f or p) there: both walks start at that file and pass it to root_copies, which reads this copy when its bytes differ"

**Location:** `scripts/lib/dev-cycle-read.sh:1404-1421`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the keep rule (`@` or link), the skip rule, the claim that both walks start at ROOT_REAL's file and pass every start to root_copies, and the return list. "Reads this copy when its bytes differ" is a lower bound: since 007e867f a prompt copy is read at any bytes, and so is a copy with a link on the way. That only adds reads. It does not cover an unclean checkout (contract item 2).

Skip: `[[ ! -L "${cx[i]}" && "$q" == "$c" ]] && isstart "$d" && rawfile "${ir[i]}" || c1_a+=("$c${cx[i]}")` (`:1447`). The tree walk starts at every isstart and inrepo_here file from `tree_starts` (`:1547-1555`). inrepo_here is `[[ -z "$(blocker "$1" file)" && -f "$1" ]]` (`:191`), which a rawfile passes. The main walk takes starts from main's tree and checkout_md (`:1641-1651`). Both then call `root_copies … "${queue[@]}"` (`:1567`) or `"${queue[@]}" "${tq[@]}"` (`:1663`) after pdir is set. Returns: `root_starts … || return 1` (`:1430`), lower_all (`:1438`) and `with_at … || return 1` (`:1439`). E6 shows the same seeds as before the split.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1404-1449`, `:191`, `:1539-1568`, `:1640-1664`; Appendix A E6

---

## Claim 17: "rawfile, not -f, on ROOT_REAL's copy: one reached through a link there is no tree walk start (U2b3b2b i1 fact-check 19b)."

**Location:** `scripts/lib/dev-cycle-read.sh:1444`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the tree walk, which the comment names. It does not cover the main walk, which reads main's blob for a path main stores.

A file reached through a linked directory fails inrepo_here's blocker test (`:191`), so `if ! isstart "$lp" || ! inrepo_here "$f"; then continue; fi` (`:1552`) drops it as a start.

**Evidence:** `scripts/lib/dev-cycle-read.sh:191`, `:1444-1447`, `:1552`

---

## Claim 18: imported_names' comments: "a dangling link as //PATH, which the loop projects alone (outside_proj)"; "c1_seeds skips another root's start that has the same kind here only because every start passes through here, pdir already set"; "a dangling prompt link's bases (prompt_marks)"; "a dangling link: outside_proj reads its real path alone"

**Location:** `scripts/lib/dev-cycle-read.sh:1556-1557`, `:1564-1566`, `:1573`, `:1575`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the four comments against the lines they annotate. It does not cover main_imports, which Claims 19 and 20 check.

`if [[ "$f" == //* ]]; then out="$f"` skips import_file. `outside_proj out work` (`:1578`) then projects it. The root_copies call follows the start and seed loops (`:1548-1567`), where `prompt_dir pdir` (`:1554`) and the seed `pdir[$p]` (`:1562`) have already run.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1539-1593`

---

## Claim 19: main_imports' failure list ("outside_seeds, root_copies or prompt_marks fails") and the tq comment ("tq's checkout files and outside files (absolute paths, never main's: outside seeds, // imports and other roots' copies, and //PATH entries, dangling links outside_proj projects)")

**Location:** `scripts/lib/dev-cycle-read.sh:1600`, `:1607-1610`
**Type:** Error-handling / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three added failure sources and what tq holds. It does not re-check the failure entries that predate the branch.

`IMPORTED_MAIN=error` is set at `:1618`, before `outside_seeds sd || return 1` (`:1654`) and `root_copies … || return 1` (`:1663`). In the loop, prompt_marks and root_copies set error (`:1706`, `:1721`). tq gets seeds (`:1658`), `//` imports (`:1714`), copies (`:1664`, `:1722`) and checkout files (`:1649`, `:1719`). Test 6 executes the root_copies failure (E1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1594-1724`; Appendix A E1

---

## Claim 20: main_imports' comments: "a dangling link as //PATH, projected alone, as in imported_names"; "Other roots' copies of the starts, then of every name the loop reaches (root_copies), in phase 2. c1_seeds skips … only because every start passes through here, pdir already set."; "a dangling link: outside_proj below reads its real path alone"

**Location:** `scripts/lib/dev-cycle-read.sh:1652-1653`, `:1660-1662`, `:1673`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the annotated lines. "In phase 2" means the copies are queued on tq, which is how the code does it.

`for p in "${cq[@]}"; do [[ -n "${seen[$p]+set}" ]] || { seen[$p]=1; tq+=("$p"); }; done` (`:1664`, `:1722`). The `checkout)` arm sets `out="$f"` for `//*` (`:1673`), and outside_proj runs after the case (`:1706`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1652-1724`

---

## Claim 21: C1 test title: "C1: both walks start at the start files another worktree holds, listed from the file system, skipping one whose bytes match this checkout's plain copy or that holds no @ …"

**Location:** `test/scripts/build-loop-check.bats:724`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the title's statement of the skip rule. It does not question the test body, which still passes at HEAD (E1).

The title is unchanged from main, but this branch removed C1's byte comparison. C1 now skips a non-link start whenever ROOT_REAL holds a plain start of the same kind at that path, whatever its bytes: `[[ ! -L "${cx[i]}" && "$q" == "$c" ]] && isstart "$d" && rawfile "${ir[i]}" || c1_a+=(…)` (`:1447`, lib). Bytes now matter only to root_copies. The body's assertions still hold, because the skipped `$sd/AGENTS.md` and `$sd/GEMINI.md` (`:747`) are each skipped for another reason. Precise text: "skipping one this checkout holds as a plain start of the same kind (root_copies compares the bytes) or that holds no @".

**Evidence:** `test/scripts/build-loop-check.bats:724-748`; `scripts/lib/dev-cycle-read.sh:1447`

---

## Claim 22: Test title: "both walks read another worktree's copy of a name they reach when this checkout lacks it or its bytes differ, through chains there; a prompt's copy reads as a prompt; a dangling one is projected (U2b3b2c; U2b3b2b i1 security F1)"

**Location:** `test/scripts/build-loop-check.bats:761`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each assertion in the title: it passes at HEAD, fails on main's lib, and the dangling branch is load-bearing. It does not cover a prompt copy with equal bytes, which test 4 covers.

The test passes at HEAD (E1, E2) and fails on main's lib with `want: docs/b.md: imported` (E2). Mutant E7 (dangling `elif` removed) fails with `want: docs/gone.md: imported`.

**Evidence:** `test/scripts/build-loop-check.bats:761-774`; Appendix A E2, E7

---

## Claim 23: "# side's prompt differs, so C1 leaves it to the name: its @docs/k2.md resolves against side's top level only as a prompt."

**Location:** `test/scripts/build-loop-check.bats:767`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the comment's account of why the walks reach `docs/k2.md`. It does not affect the assertion, which passes.

The conclusion is right on both counts. C1 leaves `$sd/.claude/commands/k.md` to root_copies, and from `.claude/commands/` the name `docs/k2.md` reaches the top level only through a prompt base. But "differs, so" gives the wrong reason for the skip. C1 skips the file because ROOT_REAL holds a prompt start at that path (`:1447`, lib), whatever its bytes. Since 007e867f, root_copies also reads a prompt copy at any bytes (`-z "${rc_p[${ps[i]}]+set}"`, `:1288`). The differing bytes matter only because side's copy is the one that names `docs/k2.md`. Precise text: "side's prompt names docs/k2.md; C1 leaves it to the name (this checkout holds a prompt there), and its @docs/k2.md resolves against side's top level only as a prompt."

**Evidence:** `test/scripts/build-loop-check.bats:761-774`; `scripts/lib/dev-cycle-read.sh:1288`, `:1447`

---

## Claim 24: Test title and note: "a copy with this checkout's bytes under a linked directory is read, so its real path is projected (U2b3b2c; i1 security F2)"; "(A plain copy with equal bytes is skipped as a cost: the parser already resolves this checkout's relative names against every root, so reading it could add nothing.)"

**Location:** `test/scripts/build-loop-check.bats:776-778`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the title (passes at HEAD, fails on f7e1bea2's lib) and the note, for a non-prompt copy with no link on the way. It does not cover prompt copies, which test 4 and Claim 12 address.

E2: fails on f7e1bea2 and main with `want: real/x.md: imported`, and passes on c69f352f and HEAD. The note holds by the parser rule `for (r = 1; r <= nr; r++) put(roots[r] "/" dirs[i] "/" c)` (lib `:903`). The absolute copy's directory is one of those joins, and with equal real paths no projection is added (`if [[ "$r" != "$1" ]]`, lib `:1198`).

**Evidence:** `test/scripts/build-loop-check.bats:776-784`; `scripts/lib/dev-cycle-read.sh:903`, `:1198`; Appendix A E2

---

## Claim 25: Test title and comment: "a dangling prompt link in another worktree reads its target as a prompt (U2b3b2c i1 security F1)"; "Under a nested .claude/, the link's own bases (side/sub) apply to its target's names too (i2 fact-check 9b)."

**Location:** `test/scripts/build-loop-check.bats:786`, `:789`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the title and the nested comment in both walks. It shows that the nested assertion is the part i2 fixed, and that the top-level part is the i1 fix.

E2: on f7e1bea2 the test fails at `want: top.md: imported`. On c69f352f it fails only at `sub/top2.md: -`, with `docs/t.md` and `top.md` imported. At HEAD it passes.

**Evidence:** `test/scripts/build-loop-check.bats:786-796`; Appendix A E2

---

## Claim 26: Test title: "a prompt copy with this checkout's bytes is still read: a worktree under a .claude/ adds prompt bases (U2b3b2c i2 fact-check 16)"

**Location:** `test/scripts/build-loop-check.bats:798`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the claim that it passes at HEAD and fails on the lib before the i2 fix. It does not show that /workspace's own layout reaches this case.

E2: fails on c69f352f and f7e1bea2 with `want: docs/z2.md: imported`, and passes at HEAD. The base comes from prompt_bases on the copy's absolute path `$h/.claude/wt/.claude/commands/k.md`. Its first `.claude` component yields `$h` (`[[ "$c" != .claude || $n -eq 0 ]] || pb_a+=("${3:0:n-1}")`, lib `:676`), and `$h/z.md` lies below no root.

**Evidence:** `test/scripts/build-loop-check.bats:798-802`; `scripts/lib/dev-cycle-read.sh:670-679`; Appendix A E2

---

## Claim 27: Test title: "a seed that is a dangling link into another worktree reads as the repo path it names (U2b3b2c; U2b3b2b final security F1)"

**Location:** `test/scripts/build-loop-check.bats:804`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the claim that it passes at HEAD and fails on main's lib. It covers config seeds only, since C1 links are covered by test 3.

E2: fails on main's lib with `want: docs/n.md: imported`, and passes on f7e1bea2 onward.

**Evidence:** `test/scripts/build-loop-check.bats:804-813`; Appendix A E2

---

## Claim 28: Test title and comment: "both walks fail closed when another worktree's copy cannot be compared with this checkout's (U2b3b2c)"; "The main walk reads main's blob, so only the comparison reads the unreadable checkout file."

**Location:** `test/scripts/build-loop-check.bats:815`, `:819`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the claim that both walks fail on the unreadable compare and on a failing sha1sum. The comment is scoped to the main walk, and in the tree walk the comparison is also what fails first (root_copies runs on `docs/a.md` before it would be read).

E2: fails on main's lib with `want: walk: failed` / `walk: ok`, and passes at HEAD. In the main walk, `docs/a.md` is in main, so the `100644|100755)` arm reads `git cat-file blob` (lib `:1676`). Only root_copies' `sha1sum` (lib `:1292`) touches the checkout file.

**Evidence:** `test/scripts/build-loop-check.bats:815-823`; `scripts/lib/dev-cycle-read.sh:1292`, `:1676`; Appendix A E2

---

## Claim 29: Sourcing inventory adds `root_copies prompt_marks config_seeds c1_seeds` and `IMPORT_OTHER`

**Location:** `test/scripts/dev-cycle.bats:1111`, `:1115`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the claim that each listed name exists after sourcing. It does not check that the inventory is complete.

The four functions are defined at lib `:1272`, `:1308`, `:1347` and `:1422`, and `IMPORT_OTHER=""` at `:1075`. The dev-cycle suite passed whole in E1.

**Evidence:** `test/scripts/dev-cycle.bats:1108-1121`; Appendix A E1

---

## Claim 30a: f7e1bea2: "Over /workspace (7 other present roots) both walks give main's 242 names … Suites 284 green"

**Location:** commit f7e1bea2 message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test count at f7e1bea2 (static count of the six suites) and the name equality, re-run at HEAD on today's registry. I did not re-run f7e1bea2's lib walks (the i2 report did).

Counting `@test` per commit over the six suites gives main 281, f7e1bea2 284, 8976fbdf 286, c69f352f 286, HEAD 287 (E8). E9: HEAD's and main's libs each give 242 distinct non-`//` names per walk, and all four sorted lists are identical. IMPORT_OTHER has 7 lines (E4).

**Evidence:** Appendix A E4, E8, E9

---

## Claim 30b: f7e1bea2: "the reads add about 0.05 s per walk (tree 1.93 s, main 2.09 s)"

**Location:** commit f7e1bea2 message
**Type:** Performance
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers whether today's measurements fit the figures. It cannot pin a 0.05 s delta, because load noise across runs here (0.5 s) is ten times that.

E9 and E4 at load averages of 2.0-2.8: main's lib gave tree 1.74/1.75 s and main 1.93/1.89 s. HEAD's lib gave tree 1.75-2.28 s and main 2.0-2.68 s. The components measured directly are root_copies' own 65-75 ms plus 4 copies at about 10 ms each, so about 0.1 s in all. That is the same order as 0.05 s, which is close if "the reads" means only the 4 copy reads (about 0.04 s). An A/B run on an idle machine with many repetitions would settle it. Tag: for-orchestrator-synthesis.

**Evidence:** Appendix A E4, E5, E9

---

## Claim 31: 8976fbdf: "Suites 286/286 …; both walks over /workspace give main's 242 names. 357 changed code lines."; "A8 … outside_seeds split into config_seeds and c1_seeds behind the wrapper; same seeds"; "A2 …: root_copies applies rawfile's test to the copy too"; "A3: the dangling-copy branch is now tested (side lacks the target)"

**Location:** commit 8976fbdf message
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count, the line count, the same seeds on /workspace (the HEAD wrapper, whose seed functions 007e867f did not change), and the A2 and A3 claims. It does not cover the "-j 8" runs, which I did not repeat because the review rules forbid them.

E8: 286 at 8976fbdf. `git diff --numstat main...8976fbdf -- ':(top)' ':(top,exclude)docs/' | awk …` prints 357. E6: the seeds are the same. A2: `"${rl[n + i]}" == "${cs[i]}"` (lib `:1288`). A3: the test's `rm "$sd/docs/gone.md"; ln -sf gone.md "$sd/docs/b.md"` (bats `:765`) and mutant E7 fails.

**Evidence:** Appendix A E6, E7, E8

---

## Claim 32: c69f352f: "the lite check read the moved comment as describing the seed; it describes ROOT_REAL's copy."

**Location:** commit c69f352f message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the claim that the comment names ROOT_REAL's copy, which the next line tests. The later "tree walk" scoping comes from 007e867f (Claim 17).

`# rawfile, not -f, on ROOT_REAL's copy: …` (lib `:1444`) annotates `rawfile "${ir[i]}"`, a path relative to ROOT_REAL (`:1447`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1444-1447`

---

## Claim 33: 007e867f: "Suites 287/287 (serial); both walks over /workspace give main's 242 names; 377 changed code lines."; "B1: prompt_marks also gives the projected names the link's directory and prompt bases (pext) …"; "B2: a prompt copy is never skipped on equal bytes"

**Location:** commit 007e867f message
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each stated number and the B1 and B2 behaviour at HEAD.

E1: `1..287`, 287 `ok`, 0 `not ok`, 0 skips, rc=0. E9: 242 names. The given numstat command prints 377 at HEAD. B1 is checked in Claim 13 and B2 in Claim 12.

**Evidence:** Appendix A E1, E2, E9

---

## Claims Requiring Attention

### Incorrect
- None.

### Stale
- **Claim 9** (`scripts/lib/dev-cycle-read.sh:1176-1179`): import_outside's list of what the walks pass as FILE leaves out other roots' copies from root_copies. Add "or another root's copy (root_copies)".
- **Claim 10** (`scripts/lib/dev-cycle-read.sh:1208-1211`): outside_ok's parenthetical leaves out root_copies' copies, which it now also admits.
- **Claim 21** (`test/scripts/build-loop-check.bats:724`): the C1 test title says C1 skips "one whose bytes match". Since this branch, C1 skips a non-link start that this checkout holds as a plain start of the same kind, whatever its bytes, and root_copies compares the bytes.

### Mostly Accurate
- **Claim 5** (`scripts/lib/dev-cycle-read.sh:757-762`): the walk header lists only the "lacks or other bytes" reads. It should also say that a prompt copy, or a copy with a link on the way, is read at equal bytes, and that a dangling copy is queued as `//ROOT/NAME`.
- **Claim 23** (`test/scripts/build-loop-check.bats:767`): "side's prompt differs, so C1 leaves it to the name" gives the wrong reason. C1 leaves it because this checkout holds a prompt start there. The bytes matter only because side's copy is the one that names `docs/k2.md`.

### Unverifiable
- **Claim 30b** (commit f7e1bea2): the "+0.05 s per walk" delta is smaller than this machine's run-to-run noise. The parts measured directly sum to about 0.1 s. Settling it needs an A/B run on an idle machine.

---

## Appendix A: execution provenance

All runs were read-only against `/workspace`, or ran in scratch copies under `/tmp/fcf-r1-u2c-*`. All ran under `timeout`. Times are container UTC on 2026-10-10. The scratch directories (captures included) were removed at the end, as the review rules require. The lines below are copied from the captures.

- **E1** (06:12:22Z-06:14:26Z; cwd the review worktree): `TMPDIR=$(mktemp -d /tmp/fcf-r1-u2c-t-XXXX) timeout 3000 bats test/scripts/build-loop-check.bats test/scripts/dev-cycle.bats test/scripts/build-loop-read.bats test/scripts/fixture-git-env.bats test/fixture-hermeticity.bats test/hermeticity-lint.bats`, serial, rc=0. Capture `suites.tap`: `1..287`, 287 lines `ok`, 0 `not ok`, 0 `# skip`.
- **E2** (06:14:35Z-06:14:40Z; cwd `/tmp/fcf-r1-u2c-red-3QlN/copy`, a `cp -a` of `scripts/` and `test/` with the lib swapped for `git show <c>:scripts/lib/dev-cycle-read.sh`): `TMPDIR=$T timeout 900 bats -f 'U2b3b2c' test/scripts/build-loop-check.bats`, once per lib. main: tests 1-6 `not ok`; first wants `docs/b.md`, `real/x.md`, `docs/t.md`, `docs/z2.md`, `docs/n.md`, `walk: failed`. f7e1bea2: 1, 5, 6 ok; 2, 3, 4 `not ok` (`real/x.md`, `top.md`, `docs/z2.md`). c69f352f: 1, 2, 5, 6 ok; 3 `not ok` with only `sub/top2.md: -` (`docs/t.md`, `top.md` imported); 4 `not ok`. HEAD: 1-6 ok.
- **E3** (about 06:13Z; same copy, HEAD lib, a scratch `probe.bats` built from the suite's `imps`/`want` helpers): `TMPDIR=$T timeout 600 bats test/scripts/probe.bats`, rc=0. P1 (side `.claude/commands/k.md` → `../../docs/t.md`, dangling; `docs/t.md` = `t: @sib.md`; `.claude/commands/sib.md` tracked): tree and main `walk: ok`, `.claude/commands/sib.md: imported`. P2 (main stores `docs/t.md` as a symlink to `real.md`): tree `walk: ok`, `top.md: -`; main `walk: failed`. P3 (AGENTS.md `see @docs/t.md`; `docs/t.md` = `t: @top.md`): tree `top.md: imported`; main `walk: ok`, `top.md: -`. P4 (side `sub/.claude/commands/k.md` → `../../../docs/u.md`; `u: @a.md @b.md`): both walks `sub/a.md`, `sub/.claude/commands/b.md`, `a.md: imported`.
- **E4** (06:15:12Z; cwd `/workspace`; load average 2.79): `timeout 200 bash rctime.sh lib-HEAD.sh` ×3 (root_copies wrapped with `$EPOCHREALTIME` accumulation). Output: `other=7`; `tree … calls=31 copies=4 rc_secs=0.0745/0.0672/0.0647`; `main … calls=31 copies=4 rc_secs=0.0706/0.0687/0.0684`; walks: tree 1.85/1.89/1.79 s, main 2.31/2.18/2.68 s.
- **E5** (06:16Z; cwd `/workspace`; load 1.96): `timeout 200 bash percopy.sh lib-HEAD.sh` ×3: `import_file` plus `lower` over the 14 other-root copies of `skills/dev-cycle/SKILL.md`, `AGENTS.md` and `CLAUDE.md`. Output: `files=14 ms_per=9.4`, `9.8`, `9.7`.
- **E6** (06:16Z; cwd `/workspace`): `timeout 200 bash seeds.sh lib-<c>.sh` for f7e1bea2 and HEAD (source; reader_settings; import_readers; outside_seeds). Both rc=0 with 9 lines. `diff` was empty (`SAME`).
- **E7** (06:16Z; copy, HEAD lib with `:1281`'s `elif … fi` replaced by `fi`): `timeout 300 bats -f 'chains there' …`, `not ok 1` with `want: docs/gone.md: imported`. The lib was restored afterwards.
- **E8** (static): `git show <c>:<suite> | grep -c '^@test'` summed over the six suites: main 281, f7e1bea2 284, 8976fbdf 286, c69f352f 286, HEAD 287. The numstat command gives 205 at f7e1bea2, 357 at 8976fbdf and 377 at HEAD.
- **E9** (06:12:48Z-06:15Z; cwd `/workspace`): `timeout 300 bash walks.sh lib-<c>.sh` for HEAD and main. Every walk gave rc=0 and `242`/`242`. `diff` of the tree and main lists within each lib and across the two libs printed `IDENTICAL`. Timings for main's lib: tree 1.74/1.75 s, main 1.93/1.89 s. For HEAD's lib: tree 2.28/1.75 s, main 2.02/2.08 s.

---

## Goal-Alignment Note

- **Success criterion (verbatim):** "A markdown report saved to the output path below, structured per the code-fact-check skill, with `Commit: 007e867f` as its first line."
- **Answered:** All seven focus areas are covered. (1) root_copies' header holds clause by clause (Claim 12). (2) prompt_marks and pext are verified in both walks, for top-level and nested links and for both main-walk arms (Claim 13). (3) The seed split gives the same seeds, and the C1 skip sentence holds, with prompt copies always read (Claims 14-16). (4) The walk doc block, file header, contract item 9, failure lists, tq comment and cost paragraph are checked; one Mostly accurate (Claim 5). (5) Every U2b3b2c test passes at HEAD and fails on the lib the rubric names; two test texts are imprecise (Claims 21, 23). (6) Every commit count holds; one timing delta cannot be pinned down (Claim 30b). (7) Two parentheticals elsewhere in the lib went stale (Claims 9, 10). No behavioural defect was found in the comments checked.
- **Out of scope:** code-quality and design judgements; the `-j 8` suite runs; how Claude Code itself resolves a symlinked prompt (the lib's model is taken as given).
- **Escalate:** Probe P3 (E3) shows a plain layout that hits override row 595's named exception in the main walk. main's AGENTS.md imports `docs/t.md`, and another worktree holds a dangling prompt link whose target is `docs/t.md`. The main walk reads `docs/t.md` plainly in phase 1, before the phase-2 `//` entry marks it, so `top.md` (reached only through the prompt's top-level base) is missed: `top.md: -`. The tree walk gets `imported`. The comments describe this correctly. But row 595's revisit trigger reads "a probe showing a real layout that reaches the plain-read order", and this probe may meet it. The orchestrator should decide whether the trigger has fired.
