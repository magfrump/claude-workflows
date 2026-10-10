Commit: f7e1bea2

# Code Fact-Check Report

**Repository:** /workspace (worktree /workspace/.claude/wt-build-loop-u2b3b2c, branch feat/build-loop-u2b3b2c)
**Scope:** `git diff main...HEAD` (main 8e550626 .. HEAD f7e1bea2): `scripts/lib/dev-cycle-read.sh` (import_readers, root_copies, outside_seeds, imported_names, main_imports and their doc comments, plus untouched comments the diff left stale), `test/scripts/build-loop-check.bats` (the three new U2b3b2c tests), and commit message f7e1bea2
**Checked:** 2026-10-09 (UTC 2026-10-10T05:05Z to 05:25Z)
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 26
**Summary:** 18 verified, 3 mostly accurate, 3 stale, 2 incorrect, 0 unverifiable

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`). The commit's "Suites 284 green" is the logged "specific measured test count" class (the "All 85 tests" and "mode1-equiv 33" entries), so it was recounted (Claim 19). It holds.

Execution provenance for every `executed` claim is in **Appendix A** at the end of this report. The review rules allow writing only this file, so the captured output is copied there; the scratch directories were removed afterwards. All commands ran with a scratch `TMPDIR` under `/tmp/fc-u2c-i1-*`.

---

## Claim 1: "Both walks also read ... through outside_seeds, ... the other roots' file trees (find, grep, sha1sum, python3 on installed_plugins.json)"

**Location:** `scripts/lib/dev-cycle-read.sh:42-45`
**Type:** Staleness / Architectural
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers which function runs sha1sum after this diff. It does not establish whether the rest of the file-header inventory is complete; this sentence also does not mention that root_copies reads other roots' copies.

The diff removed outside_seeds' only sha1sum call (the `hs`/`sp` block at old `:1347-1350`). The only sha1sum in the lib is now in root_copies:

```bash
# scripts/lib/dev-cycle-read.sh:1271
  nul_list rl xargs -0r -a <(printf '%s\0' "${hs[@]}") sha1sum -z -- && [[ ${#rl[@]} -eq ${#hs[@]} ]] || return 1
```

`grep -n sha1sum` over the lib finds `:45`, `:760`, `:1249`, `:1271` and `:1304`, and none of them is inside `outside_seeds` (`:1308-1394`). (Paraphrased — no quote available because the claim is about the absence of code, from no matching grep results.) The header still credits sha1sum to the outside_seeds reads of "the other roots' file trees". It now runs in root_copies, over copies of the names the walks reach. The precise version: "...the other roots' file trees (find, grep, python3 on installed_plugins.json) and, through root_copies, other roots' copies of the names the walks reach (realpath, sha1sum)".

**Evidence:** `scripts/lib/dev-cycle-read.sh:42-45`, `scripts/lib/dev-cycle-read.sh:1271`, `scripts/lib/dev-cycle-read.sh:1308-1394`

---

## Claim 2: "A seed that is a dangling link joins the queue as a // name, which only outside_proj reads (U2b3b2b final security F1)"

**Location:** `scripts/lib/dev-cycle-read.sh:749-750`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers outside_seeds seeds that outside_ok rejects and that are links, in both walks. It does not establish that every dangling link under a config dir becomes a seed: outside_seeds keeps a config-tree link only when its real path lies below a reader root (see Claim 7). Links that outside_ok rejects because they point to a directory or an unreadable file take the same // route; the sentence says "dangling" only.

Both walks rewrite such a seed into a `//` name:

```bash
# scripts/lib/dev-cycle-read.sh:1502-1504 (imported_names)
    p="${f:1}"; outside_ok "$p" || { [[ -L "$p" ]] || continue; p="/$p"; }
    [[ "$seen" != *$'\n'"$p"$'\n'* ]] || continue
    seen+="$p"$'\n'; queue+=("$p"); [[ "$f" != p* || "$p" == //* ]] || pdir[$p]="$(lower "$p")" || return 1
```

The queue loop does not parse a `//` name. It passes the name to outside_proj on its own:

```bash
# scripts/lib/dev-cycle-read.sh:1514-1517
    if [[ "$f" == //* ]]; then out="$f"  # a dangling link: outside_proj reads its real path alone
    else out="$(IMPORT_LEFT=... import_file "$f" "$d" "${xs[@]}")" \
      && import_work out work || { IMPORTED=error; return 1; }; fi
    outside_proj out work || { IMPORTED=error; return 1; }
```

main_imports does the same at `:1593-1595` (seeds) and `:1607-1609` (the `checkout` arm). Executed: test 2 (`:778`) checks this for both walks. On main's lib, `docs/n.md`, `docs/r.md` and `docs/deep.md` are all MISS; on HEAD they are all HIT (Appendix A, run P1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1497-1504`, `scripts/lib/dev-cycle-read.sh:1514-1517`, `scripts/lib/dev-cycle-read.sh:1589-1595`, `scripts/lib/dev-cycle-read.sh:1607-1609`, `scripts/lib/dev-cycle-read.sh:1211-1223`; Appendix A P1

---

## Claim 3: "For every repo name a walk reaches, a start included, root_copies also reads each other reader root's copy that ROOT_REAL lacks or holds with other bytes ... the main walk compares with the checkout's file, which contract item 2's clean checkout makes main's."

**Location:** `scripts/lib/dev-cycle-read.sh:751-755`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the call sites. root_copies gets every start and every non-// name the parser prints, in both walks, and in the main walk the comparison reads the checkout's file. It does not establish two things. First, a copy that is itself a link is read even when ROOT_REAL holds the same bytes; that is a superset the sentence omits. Second, the main-walk comparison is only exact under contract item 2 (a dirty checkout compares against bytes main does not hold).

Starts: the tree walk calls `root_copies cq cmp pdir "${queue[@]}"` (`:1506`) after both the checkout starts and the outside seeds are queued. The main walk calls `root_copies cq cmp pdir "${queue[@]}" "${tq[@]}"` (`:1598`), which covers main's starts (`queue`) and the checkout starts that main lacks (`tq`). Reached names: both loops add every non-`//` name to `nm` before the seen test, then call root_copies on it:

```bash
# scripts/lib/dev-cycle-read.sh:1649-1650, 1655 (main_imports)
      nm+=("$p"); [[ -z "${seen[$p]+set}" ]] || continue
      c=0; [[ -n "${ent[$p]+set}" ]] || main_checkout ent pok "$p" || c=$?  # main lacks p: admitted before it is marked seen
...
    cq=(); root_copies cq cmp pdir "${nm[@]}" || { IMPORTED_MAIN=error; return 1; }
```

(excerpt ends `:1655`; enclosing main_imports continues to `:1658` — read). The tree walk does the same at `:1524-1530`. The comparison reads the working tree: it calls `[[ -f "${ps[i]}" ...` and sha1sum on the relative `ps[i]`, under need_root's cwd = ROOT_REAL (`:1266-1271`). Executed: in test 3, the main walk fails only because of the comparison (red on main's lib, and green again when root_copies' sha1sum failure is ignored, mutant m3: Appendix A P1/P2).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1506`, `scripts/lib/dev-cycle-read.sh:1520-1531`, `scripts/lib/dev-cycle-read.sh:1598`, `scripts/lib/dev-cycle-read.sh:1644-1658`, `scripts/lib/dev-cycle-read.sh:1252-1273`; Appendix A P1, P2

---

## Claim 4: "Any seed listing find, grep or sha1sum cannot complete fails the walk"

**Location:** `scripts/lib/dev-cycle-read.sh:759-760`
**Type:** Staleness / Error-handling
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers which step runs sha1sum. It does not dispute that a sha1sum failure still fails the walk; it does, through root_copies (Claim 6e).

Seed listing (outside_seeds) no longer runs sha1sum; see Claim 1's grep (paraphrased — no quote available because the claim is about the absence of code, from no matching grep results). A sha1sum failure now fails the walk from root_copies (`:1271` `|| return 1`, propagated at `:1506`, `:1529`, `:1598` and `:1655`). That is a comparison of copies of reached names, not a seed listing. The conclusion still holds but the mechanism is out of date. The precise version: "Any seed listing find or grep cannot complete, or a root_copies realpath or sha1sum, fails the walk".

**Evidence:** `scripts/lib/dev-cycle-read.sh:759-760`, `scripts/lib/dev-cycle-read.sh:1271`, `scripts/lib/dev-cycle-read.sh:1308-1394`

---

## Claim 5: "IMPORT_OTHER holds every root's real path but ROOT_REAL's that is a directory here, once each, newline-separated: the roots whose copies root_copies and outside_seeds read."

**Location:** `scripts/lib/dev-cycle-read.sh:1060-1062`
**Type:** Invariant / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what a successful import_readers computes, memo hits, and the two readers. It does not establish that a refusal leaves IMPORT_OTHER empty (the comment does not claim that): a `return 1` inside the root loop at `:1116` can leave a partial, newline-terminated value. No consumer reads that value, because both walks return before outside_seeds and root_copies when import_readers fails (`:1485`, `:1553`), and a memoized refusal returns 1 again (`:1088`).

```bash
# scripts/lib/dev-cycle-read.sh:1115-1118
  for i in "${!rs_x[@]}"; do
    [[ -n "${rs_real[i]//\//}" && "${rs_real[i]}" != *$'\n'* ]] || return 1
    if [[ $i -lt $n ]]; then t=r; else t=h; fi
    p="${rs_real[i]}"; [[ $t == h || "$p" == "$ROOT_REAL" || -n "${rs_seen[o$p]+set}" || ! -d "$p" ]] || { rs_seen[o$p]=1; IMPORT_OTHER+="$p"$'\n'; }
```

(excerpt ends `:1118`; enclosing import_readers continues to `:1136` — read; `:1135` strips the trailing newline.) Only root entries (`t=r`) are included: realpaths, never ROOT_REAL, only directories, de-duplicated by the `o` key. The value is reset at `:1089` before any refusal check and kept across memo hits (`:1088`), so it stays consistent with IMPORT_ROOTS until import_reset. Readers: root_copies (`:1254-1255`) and outside_seeds' C1 (`:1365`). Executed over /workspace: HEAD's lib gives 7 entries (`IMPORT_OTHER count: 7`, Appendix A T1), matching the commit's "7 other present roots".

**Evidence:** `scripts/lib/dev-cycle-read.sh:1082-1136`, `scripts/lib/dev-cycle-read.sh:1254-1255`, `scripts/lib/dev-cycle-read.sh:1364-1365`; Appendix A T1

---

## Claim 6a: "the array Q gets ROOT/NAME when outside_ok admits it, unless it is not a link and its bytes equal ROOT_REAL's plain file there (rawfile's test ...)"

**Location:** `scripts/lib/dev-cycle-read.sh:1243-1245`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the admit/compare/queue logic and whether the batched `realpath -m` plus `-f` test is equivalent to rawfile's `-f` plus `realpath -e`. It does not establish behaviour when realpath itself errors on one name (the whole call then returns 1, where rawfile would answer false; I found no input on which `-f` holds and `realpath -m` fails).

```bash
# scripts/lib/dev-cycle-read.sh:1259-1272
    for r in "${rs[@]}"; do
      if outside_ok "$r/$p"; then
        [[ -z "${rc_p[$p]+set}" ]] || rc_p[$r/$p]="$(lower "$r/$p")" || return 1
        if [[ -L "$r/$p" ]]; then rc_q+=("$r/$p"); else ps+=("$p"); cs+=("$r/$p"); fi
      elif [[ -L "$r/$p" ]]; then rc_q+=("/$r/$p"); fi
    done
  done
  [[ ${#ps[@]} -gt 0 ]] || return 0
  nul_list rl realpath -mz -- "${ps[@]}" && [[ ${#rl[@]} -eq ${#ps[@]} ]] || return 1
  for i in "${!ps[@]}"; do
    if [[ -f "${ps[i]}" && "${rl[i]}" == "$ROOT_REAL/${ps[i]}" ]]; then sp+=("${cs[i]}"); hs+=("${cs[i]}" "${ps[i]}"); else rc_q+=("${cs[i]}"); fi
  done
  [[ ${#hs[@]} -gt 0 ]] || return 0
  nul_list rl xargs -0r -a <(printf '%s\0' "${hs[@]}") sha1sum -z -- && [[ ${#rl[@]} -eq ${#hs[@]} ]] || return 1
  for i in "${!sp[@]}"; do [[ "${rl[2*i]:0:40}" == "${rl[2*i+1]:0:40}" ]] || rc_q+=("${sp[i]}"); done
```

rawfile is `[[ -n "${ROOT_REAL:-}" && -f "$1" ]] && r="$(realpath -e -- "$1" 2>/dev/null)" && [[ "$r" == "$ROOT_REAL/$1" ]]` (`:160`). When `-f p` holds, every component exists, so `realpath -m` and `realpath -e` give the same path. The relative `p` resolves against cwd, and need_root (`:157`) makes cwd ROOT_REAL. Executed: `realpath -mz` exits 0 on a self-loop link, a dangling link and a name under a mode-000 directory, where `-f` is false or `-e` fails (Appendix A R1). So the two tests diverge only where `-f` is already false. `sha1sum -z` disables file-name escaping, so `${rl[2*i]:0:40}` is always the hash. The `hs` order (copy, then ROOT_REAL's file) pairs `2i`/`2i+1` even across xargs batches. Executed: test 1 is red on main's lib for b/n/c/gone in both walks and green on HEAD (P1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1252-1273`, `scripts/lib/dev-cycle-read.sh:155-160`, `scripts/lib/dev-cycle-read.sh:1202`; Appendix A R1, P1

---

## Claim 6b: "and //ROOT/NAME when it is a link outside_ok rejects (a dangling one, which the walks project as outside_proj projects a // name)"

**Location:** `scripts/lib/dev-cycle-read.sh:1246-1248`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the code path (`:1263`, then the walks' `//` handling). It does not establish test coverage: no U2b3b2c test reaches this branch (see Claim 12). Mutant m4, which deletes it, passes all 31 probe assertions (Appendix A P2).

`elif [[ -L "$r/$p" ]]; then rc_q+=("/$r/$p"); fi` (`:1263`). `r` is absolute, so `"/$r/$p"` is a `//` name. In imported_names it joins `queue` (`:1507`); in main_imports it joins `tq` (`:1599`). Both loops send a `//` entry to outside_proj alone (`:1514`, `:1607`). outside_proj runs `realpath -m` on each `//` name outside_ok rejects and projects the ones whose real path differs (`:1214-1222`). A link's real path always differs from its own path, so the projection runs. Confidence is Medium only because no executed test exercises this exact branch. The path from `//` name to projection is the same one test 2 exercises for seeds (Claim 2).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1263`, `scripts/lib/dev-cycle-read.sh:1507`, `scripts/lib/dev-cycle-read.sh:1514-1517`, `scripts/lib/dev-cycle-read.sh:1599`, `scripts/lib/dev-cycle-read.sh:1607-1609`, `scripts/lib/dev-cycle-read.sh:1211-1223`; Appendix A P2 (m4)

---

## Claim 6c: "A copy of a NAME the associative array PDIR holds (a prompt) is added to it, lower-cased, so it is read as one."

**Location:** `scripts/lib/dev-cycle-read.sh:1248-1250`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers admitted copies (outside_ok true), including those later dropped as byte-equal. It does not cover `//` copies, which get no PDIR entry and are projected rather than read.

`[[ -z "${rc_p[$p]+set}" ]] || rc_p[$r/$p]="$(lower "$r/$p")" || return 1` (`:1261`). The walks then call `prompt_bases xs "${pdir[$f]}" "$f"` for that absolute path (`:1512`, `:1604`). Executed: mutant m2 replaces `:1261` with `:` and turns `docs/k2.md: imported` into MISS in both walks; HEAD gives HIT (P2).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1261`, `scripts/lib/dev-cycle-read.sh:1512`, `scripts/lib/dev-cycle-read.sh:1604`, `test/scripts/build-loop-check.bats:767-768`; Appendix A P2 (m2)

---

## Claim 6d: "One realpath and one sha1sum per call"

**Location:** `scripts/lib/dev-cycle-read.sh:1249`
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the process count of root_copies. It does not establish the commit's time figures (Claim 18).

realpath runs at most once (`:1267`, only when `ps` is non-empty). sha1sum runs through `xargs` (`:1271`), which starts one sha1sum per argument batch: one in practice, several for a very long `hs`. Each admitted copy of a prompt name also forks a `$(lower ...)` subshell (`:1261`), and the sentence does not mention that. The precise version: "At most one realpath and one xargs of sha1sum per call, plus one lower per admitted prompt copy".

**Evidence:** `scripts/lib/dev-cycle-read.sh:1261`, `scripts/lib/dev-cycle-read.sh:1267`, `scripts/lib/dev-cycle-read.sh:1271`

---

## Claim 6e: "it returns 1 when either, or lower, fails"

**Location:** `scripts/lib/dev-cycle-read.sh:1249-1250`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers root_copies' return and both walks' propagation. It does not establish that the failure is observed anywhere other than the walk result (IMPORTED/IMPORTED_MAIN become `error`).

`|| return 1` follows lower (`:1261`), realpath (`:1267`) and sha1sum (`:1271`). The walks propagate it: `:1506 || return 1` and `:1529 || { IMPORTED=error; return 1; }`; `:1598` and `:1655` likewise. Executed: test 3 (a mode-000 checkout file, and a `sha1sum` stub that exits 1) fails both walks on HEAD. Mutant m3 (`sha1sum ... || return 0`) makes the main walk under chmod, and both walks under the stub, report `walk: ok` (MISS against `walk failed`, P2).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1261-1271`, `scripts/lib/dev-cycle-read.sh:1506`, `scripts/lib/dev-cycle-read.sh:1529`, `scripts/lib/dev-cycle-read.sh:1598`, `scripts/lib/dev-cycle-read.sh:1655`; Appendix A P1, P2 (m3)

---

## Claim 6f: "Not covered: a copy below a dangling linked directory in that root (as find -P lists it: A5), which is skipped."

**Location:** `scripts/lib/dev-cycle-read.sh:1250-1251`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers `$r/$p` under a dangling directory link. It does not establish anything about a copy below a live linked directory; root_copies does read that one, because `-f` follows the link.

Under a dangling directory link, `$r/$p` does not exist, so both `outside_ok` (`[[ -f "$1" && -r "$1" ]]`, `:1202`) and `[[ -L "$r/$p" ]]` (`:1263`, which tests the final component) are false. Neither branch adds anything, so the copy is skipped.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1202`, `scripts/lib/dev-cycle-read.sh:1259-1264`

---

## Claim 7: "its trees followed through links (find -L ...), a dangling link kept (the walks project it, as outside_proj projects a // name ...)"

**Location:** `scripts/lib/dev-cycle-read.sh:1282-1284`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers config-dir tree and top-level seeds. It does not cover C1 links, which are kept whatever their target (`:1383`).

find lists dangling links (`'(' -type f -o -type l ')'` under `-L` at `:1338-1341`; `-xtype l` under `-H` at `:1347`). After that, a seed survives only if it holds an `@` or its `realpath -m` differs and lies below a reader root:

```bash
# scripts/lib/dev-cycle-read.sh:1359-1362
  for i in "${!cx[@]}"; do
    in=""; [[ -z "${os_at[${cx[i]}]+set}" ]] || in=1
    [[ -n "$in" || "${rl[i]}" == "${cx[i]}" ]] || for q in "${rs[@]}"; do [[ "${rl[i]}" != "$q"/* ]] || in=1; done
    [[ -z "$in" ]] || os_a+=("${kx[i]}${cx[i]}")
```

(excerpt ends `:1362`; enclosing outside_seeds continues to `:1394` — read.) A dangling link to a path below no root is dropped. Test 2's `rules/x.md -> /nonexistent/x.md` is that case, and the walk is still ok (P1). The paragraph's later sentence, "Only a seed holding an @ byte or reached through a link ... can yield a name, so the rest are dropped" (`:1298-1300`), implies the filter, but "a dangling link kept" reads as unconditional. The precise version: "a dangling link into a reader root kept".

**Evidence:** `scripts/lib/dev-cycle-read.sh:1282-1284`, `scripts/lib/dev-cycle-read.sh:1337-1347`, `scripts/lib/dev-cycle-read.sh:1352-1362`; Appendix A P1, F1

---

## Claim 8: "One is skipped when it is not a link and ROOT_REAL holds a plain file (rawfile) at its path below its innermost root that is a start of the same kind (f or p) there: the walks start at that file and root_copies reads this copy when its bytes differ"

**Location:** `scripts/lib/dev-cycle-read.sh:1290-1295`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both walks' starts, under contract item 2's clean checkout. The checks are: the tree walk's `inrepo_here` against rawfile; the main walk's main-stored (`m:`) and main-lacked (`t:`, main_checkout) starts; root_copies examining the same root and path; and the PDIR kind. It does not cover a ROOT_REAL file inside an untracked or ignored nested repository that git does not list. The comment already names that exception via contract item 2, but a nested repo that is ignored rather than untracked leaves `git status` clean too.

Skip code: `[[ ! -L "${cx[i]}" && "$q" == "$c" ]] && isstart "$d" && rawfile "${ir[i]}" || os_a+=("$c${cx[i]}")` (`:1388`). Here `d` is the lower-cased tail of length `${#ir[i]}`, and `q` is its PROMPT_DIR kind (`:1387`).

- **Tree walk.** It starts at a listed `f` when `isstart "$lp"` and `inrepo_here "$f"` (`:1494`). `inrepo_here` is `[[ -z "$(blocker "$1" file)" && -f "$1" ]]` (`:188`). blocker requires every existing prefix to pass plaindir and the file to pass rawfile (`:171-183`), and `rawfile ir` already implies that no component is a link. tree_starts lists tracked files plus `ls-files --others` without exclude options (`:1410-1412`, `:1431`).
- **Main walk.** A start main stores enters `queue` unchecked. A start main lacks goes through `main_checkout`: with every ancestor a plain searchable directory, which `rawfile ir` implies, it returns 0 when the file is readable and 1 (walk fails) when it is not (`:1476`). `c=2` (absent, or below a plain file) cannot arise when `rawfile ir` holds.
- **Comparison.** Both walks pass these starts to root_copies (`:1506`, `:1598`). Because `rawfile ir` holds, the walk spells the start `ir` exactly. root_copies checks `$r/ir` for every IMPORT_OTHER root, which includes C1's innermost root (`cr` comes from IMPORT_OTHER, `:1365`).
- **Kind.** The walk's PDIR entry for `ir` uses the same PROMPT_DIR test on the same lower-cased `ir`, so the copy inherits kind `q == c`.

Executed: test 1's prompt (`.claude/commands/k.md`) is skipped by C1 on HEAD, and `docs/k2.md` is still imported in both walks. Removing the PDIR hand-off (m2) loses it (P2).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1364-1388`, `scripts/lib/dev-cycle-read.sh:1490-1496`, `scripts/lib/dev-cycle-read.sh:1569-1580`, `scripts/lib/dev-cycle-read.sh:1453-1479`, `scripts/lib/dev-cycle-read.sh:160`, `scripts/lib/dev-cycle-read.sh:171-188`; Appendix A P2

---

## Claim 9: "It returns 1 when a find, grep, sha1sum, realpath or lower_all fails"

**Location:** `scripts/lib/dev-cycle-read.sh:1304-1305`
**Type:** Staleness / Error-handling
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers outside_seeds' own commands. It does not dispute the other listed failures.

The diff deleted outside_seeds' sha1sum block (old `:1346-1350`, replaced by the one-line skip at `:1388`), and outside_seeds (`:1308-1394`) contains no sha1sum (paraphrased — no quote available because the claim is about the absence of code, from no matching grep results). Its remaining commands are find, grep (root_starts/instruction_names, with_at), realpath, lower_all and python3. The precise version drops "sha1sum".

**Evidence:** `scripts/lib/dev-cycle-read.sh:1304-1305`, `scripts/lib/dev-cycle-read.sh:1308-1394`

---

## Claim 10: "Under -L, -type l is a dangling link" / "-xtype l is a dangling link"

**Location:** `scripts/lib/dev-cycle-read.sh:1337`, `scripts/lib/dev-cycle-read.sh:1344-1346`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers GNU find on this host. A chain that ends dangling also matches, which is consistent with the comment. It does not establish behaviour on a non-GNU find.

In a scratch directory holding `real.md`, `good.md -> real.md`, `dang.md -> nowhere.md` and `chain.md -> dang.md`, both `find -L t '(' -type f -o -type l ')' -iname '*.md'` and `find -H t -maxdepth 1 '(' -xtype f -o -xtype l ')'` list all four. The files and live links match through `f`; the dangling ones match only through `l` (Appendix A F1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1337-1347`; Appendix A F1

---

## Claim 11: "The outside starts, after the checkout's, admitted as a // name is; a dangling link as //PATH, which the loop projects alone (outside_proj)" / "Other roots' copies of the starts, then of every name the loop reaches (root_copies)[, in phase 2]"

**Location:** `scripts/lib/dev-cycle-read.sh:1497-1498`, `scripts/lib/dev-cycle-read.sh:1505`, `scripts/lib/dev-cycle-read.sh:1589-1590`, `scripts/lib/dev-cycle-read.sh:1597`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the walks' queueing comments. It does not establish anything beyond Claims 2 and 3.

The code at `:1500-1508` and `:1591-1599` matches (quoted in Claims 2 and 3). In main_imports, copies go to `tq`: `for p in "${cq[@]}"; do [[ -n "${seen[$p]+set}" ]] || { seen[$p]=1; tq+=("$p"); }; done` (`:1599`, `:1656`). `tq` becomes the queue only once main's queue empties (`:1603`), so "in phase 2" holds.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1497-1508`, `scripts/lib/dev-cycle-read.sh:1589-1603`, `scripts/lib/dev-cycle-read.sh:1655-1656`

---

## Claim 12: "its docs/b.md is a link to a file side lacks" (and the title's "a dangling one is projected")

**Location:** `test/scripts/build-loop-check.bats:765` (title at `:761`)
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what test 1's fixture builds and which root_copies branch it exercises. It does not dispute that `docs/gone.md` is imported; the import goes through the live-link path instead.

```bash
# test/scripts/build-loop-check.bats:762-765
    mkdir -p docs .claude/commands && printf 'see @docs/a.md\n' > AGENTS.md && printf 'k: @docs/k.md\n' > .claude/commands/k.md
    for f in a b c k k2 e gone; do echo "$f" > "docs/$f.md"; done; commit_all rc
    git worktree add -q --detach ../side && sd="$(cd ../side && pwd -P)"
    # side's docs/a.md differs; side alone holds docs/n.md; its docs/b.md is a link to a file side lacks.
```

`docs/gone.md` is committed before `side` is added, so side checks it out. `ln -sf gone.md "$sd/docs/b.md"` (`:766`) is therefore a live link to side's own `docs/gone.md`. Executed: the same fixture steps list `gone.md` in `side/docs` (F2). So outside_ok admits `side/docs/b.md` and root_copies queues it through the `-L` branch at `:1262`, not the `//` branch at `:1263`. The title's "a dangling one is projected" is not exercised. Mutant m4, which deletes the `//` branch, passes every assertion of all three new tests (P2). For the test to match its comment, side must lack `docs/gone.md`, for example by removing it in side after the worktree add.

**Evidence:** `test/scripts/build-loop-check.bats:761-776`, `scripts/lib/dev-cycle-read.sh:1259-1264`; Appendix A F2, P2 (m4)

---

## Claim 13: "side's prompt differs, so C1 leaves it to the name: its @docs/k2.md resolves against side's top level only as a prompt."

**Location:** `test/scripts/build-loop-check.bats:767`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers HEAD's behaviour. It does not make the assertion red on main's lib: there, C1 seeds side's differing prompt itself, and `docs/k2.md` is imported (HIT on main, P1). The assertion guards the PDIR hand-off (m2), not the U2b3b2c change as a whole.

On HEAD, C1 skips `side/.claude/commands/k.md` (not a link, prompt kind on both sides, rawfile true: `:1388`), and root_copies reads it as a prompt (Claims 6c, 8). Mutant m2 loses `docs/k2.md` in both walks (P2).

**Evidence:** `test/scripts/build-loop-check.bats:767-768`, `scripts/lib/dev-cycle-read.sh:1261`, `scripts/lib/dev-cycle-read.sh:1388`; Appendix A P1, P2 (m2)

---

## Claim 14: "A copy whose bytes match is not read: side's AGENTS.md would add docs/e.md only if it were."

**Location:** `test/scripts/build-loop-check.bats:774-775`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers whether the assertion can detect a byte-equal copy being read. It does not dispute root_copies' byte-equal skip, which Claim 6a verifies from the code.

```bash
# test/scripts/build-loop-check.bats:774-775
    # A copy whose bytes match is not read: side's AGENTS.md would add docs/e.md only if it were.
    printf 'see @docs/a.md\n' > "$sd/AGENTS.md" && imps tree docs/e.md && want docs/e.md -
```

The `printf` rewrites side's AGENTS.md with the bytes it already holds from commit `rc` (`:762`). Those bytes name only `docs/a.md`, which is read anyway, never `docs/e.md`. Reading side's AGENTS.md cannot add `docs/e.md`. Executed: mutant m1, which makes root_copies queue every admitted copy without comparing bytes, still gives `docs/e.md: -` (HIT) in both the loop assertion and this one (P2). The assertion is vacuous for the property its comment names. For it to bite, side's AGENTS.md and ROOT_REAL's would both need to import `@docs/e.md` with equal bytes, and `docs/e.md` would need to be reachable only through that copy (for example, `e.md` present only in side).

**Evidence:** `test/scripts/build-loop-check.bats:762-775`, `scripts/lib/dev-cycle-read.sh:1266-1272`; Appendix A P2 (m1)

---

## Claim 15: "a seed that is a dangling link into another worktree reads as the repo path it names (U2b3b2c; U2b3b2b final security F1)"

**Location:** `test/scripts/build-loop-check.bats:778`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the top-level (`CLAUDE.md`) and rules-tree (`rules/r.md`) dangling seeds, and a dangling seed below no root being dropped. It does not cover C1 dangling links or root_copies' `//` branch (Claim 12).

side lacks `docs/` (it is added before `docs/` is committed, `:779-781`). The links in `$HOME/.claude` therefore dangle, and on HEAD both walks import `docs/n.md`, `docs/r.md` and `docs/deep.md` (through `n.md`). All three are MISS on main's lib (P1).

**Evidence:** `test/scripts/build-loop-check.bats:778-787`; Appendix A P1

---

## Claim 16: "The main walk reads main's blob, so only the comparison reads the unreadable checkout file." (test title: "both walks fail closed when another worktree's copy cannot be compared with this checkout's")

**Location:** `test/scripts/build-loop-check.bats:793` (title at `:789`)
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the main walk under chmod 000 and both walks under the sha1sum stub. It does not establish that the tree-walk half or the stub half is red on main's lib: on main's lib the tree walk already fails reading the mode-000 file, and both walks already fail under the stub (old C1 ran sha1sum on side's byte-equal AGENTS.md). Only the main-walk chmod assertion is red on main (P1). The comment does not claim otherwise.

`docs/a.md` is on main (`100644`), so the main walk reads `git cat-file blob` (`:1610`). The only read of the checkout file is root_copies' sha1sum (`:1271`). Executed: the main walk with chmod is `walk: ok` on main's lib (MISS) and `walk: failed` on HEAD. Mutant m3 restores `walk: ok` (P1, P2).

**Evidence:** `test/scripts/build-loop-check.bats:789-797`, `scripts/lib/dev-cycle-read.sh:1610-1611`, `scripts/lib/dev-cycle-read.sh:1271`; Appendix A P1, P2 (m3)

---

## Claim 17: "Over /workspace (7 other present roots) both walks give main's 242 names"

**Location:** commit message f7e1bea2, paragraph 3
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers /workspace's state at 2026-10-10T05:23Z. It does not establish the same count at any other time: registered worktrees change.

Timing script T1 (cd /workspace; ROOT_REAL=pwd -P; source lib; `resolve_main || true; reader_settings`; both walks). Distinct non-`//` lower-cased names: 242 for the tree walk and 242 for the main walk on HEAD's lib, and 242/242 on main's lib. `diff` of the sorted lists is empty in every pairing (head vs main lib, tree vs main walk). IMPORT_OTHER has 7 entries.

**Evidence:** Appendix A T1

---

## Claim 18: "the reads add about 0.05 s per walk (tree 1.93 s, main 2.09 s)"

**Location:** commit message f7e1bea2, paragraph 3
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the added cost at this host's load (1-min load 1.6-1.8). It does not reproduce the absolute figures, which are load-dependent: they measured lower here.

Three interleaved runs per lib. HEAD: tree 1.757/1.725/1.732 s, main 1.938/1.891/1.872 s. main's lib: tree 1.740/2.737/1.709 s (one outlier), main 1.888/1.906/1.814 s. Median deltas are about 0.0 s for tree and about 0.0-0.05 s for main, which is within "about 0.05 s". The absolute times are 0.2 s below the commit's, consistent with lower load.

**Evidence:** Appendix A T1

---

## Claim 19: "Suites 284 green"

**Location:** commit message f7e1bea2, paragraph 3
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the six suites prior U2b3b2b commits name (build-loop-check, build-loop-read, dev-cycle, fixture-git-env, fixture-hermeticity) plus hermeticity-lint, which together sum to 284. The message does not name the suites, so this is the reading under which 284 holds.

`bats` at HEAD: build-loop-check 128/128 ok, dev-cycle 79/79, build-loop-read 20/20, fixture-git-env 2/2, fixture-hermeticity 2/2, hermeticity-lint 53/53. That is 284 ok, 0 not ok, 0 skipped. The arithmetic: 128+79+20+2+2+53 = 284. Logged-pattern check: this is the "specific measured test count" class, and here it holds.

**Evidence:** Appendix A S1

---

## Claim 20: "health check passed"

**Location:** commit message f7e1bea2, paragraph 3
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `scripts/health-check.sh` at HEAD f7e1bea2 with a scratch TMPDIR. It does not cover warnings that the script reports but does not fail on (two CLAUDE.md/AGENTS.md divergence warnings and stale-freshness notes).

Exit 0, with the final line "All checks passed." and 1,747 `ok` lines from check 5's full suite.

**Evidence:** Appendix A H1

---

## Claim 21: "Seeds that are dangling links (config dirs' trees and top-level files, C1) are kept and join the queue as // names"

**Location:** commit message f7e1bea2, paragraph 2
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** The same as Claim 7, for the commit message.

C1 links are kept unconditionally (`:1383`, `-L` passes the filter). A config-dir or top-level dangling link is kept only when its `realpath -m` lies below a reader root (`:1359-1362`); test 2's `/nonexistent/x.md` link is dropped. The precise version: "dangling links into a reader root".

**Evidence:** `scripts/lib/dev-cycle-read.sh:1352-1362`, `scripts/lib/dev-cycle-read.sh:1383-1388`; Appendix A P1

---

## Claims Requiring Attention

### Incorrect
- **Claim 12** (`test/scripts/build-loop-check.bats:765`, title `:761`) [for-author]: side holds `docs/gone.md`, so side's `docs/b.md` is a live link, not a dangling one. root_copies' `//ROOT/NAME` branch is untested (mutant m4 survives). Remove `docs/gone.md` in side, or fix the comment and title.
- **Claim 14** (`test/scripts/build-loop-check.bats:774-775`) [for-author]: the rewrite of side's AGENTS.md uses its existing bytes, and those bytes never name `docs/e.md`. The assertion passes even when byte-equal copies are read (mutant m1 survives). Make the equal copy the only path to a marker file.

### Stale
- **Claim 1** (`scripts/lib/dev-cycle-read.sh:45`) [for-author]: the file header credits sha1sum to outside_seeds' reads of other roots' file trees; sha1sum now runs only in root_copies.
- **Claim 4** (`scripts/lib/dev-cycle-read.sh:759-760`) [for-author]: "seed listing find, grep or sha1sum": seed listing no longer runs sha1sum. root_copies' realpath and sha1sum fail the walk.
- **Claim 9** (`scripts/lib/dev-cycle-read.sh:1304`) [for-author]: outside_seeds' return-1 list still names sha1sum.

### Mostly Accurate
- **Claim 6d** (`scripts/lib/dev-cycle-read.sh:1249`) [for-author]: "one sha1sum" is one xargs (which may batch), and each admitted prompt copy also forks a lower.
- **Claim 7** (`scripts/lib/dev-cycle-read.sh:1283-1284`) [for-author]: a config-tree dangling link is kept only when it points below a reader root.
- **Claim 21** (commit f7e1bea2) [for-author]: the same qualifier as Claim 7.

### Unverifiable
- (none)

Verified claims (2, 3, 5, 6a, 6b, 6c, 6e, 6f, 8, 10, 11, 13, 15, 16, 17, 18, 19, 20) [for-orchestrator-synthesis]: each verdict covers only its `Scope:` line. Note in particular: 6b (verified from code only, no test), 13 (not red on main's lib), and 16 (only the main-walk chmod half is red on main's lib).

---

## Appendix A: execution provenance (captured output)

All runs were on 2026-10-10 UTC. The worktree's HEAD was confirmed as f7e1bea2, with nothing modified. Mutants and main's lib ran in a scratch `git archive HEAD scripts test` copy at `/tmp/fc-u2c-i1-m-IEZA`, never in the worktree. All scratch directories were removed after the run.

**S1, suites.** cwd `/workspace/.claude/wt-build-loop-u2b3b2c`. 05:11:00Z to 05:13:03Z. For each suite: `TMPDIR=$(mktemp -d /tmp/fc-u2c-i1-t-XXXX) timeout 1500 bats <suite>`. All exit 0.
```
build-loop-check rc=0   ok=128 notok=0 plan=1..128
dev-cycle rc=0          ok=79  notok=0 plan=1..79
build-loop-read rc=0    ok=20  notok=0 plan=1..20
fixture-git-env rc=0    ok=2   notok=0 plan=1..2
fixture-hermeticity rc=0 ok=2  notok=0 plan=1..2   (test/fixture-hermeticity.bats)
hermeticity-lint rc=0   ok=53  notok=0 plan=1..53  (test/hermeticity-lint.bats)
(no "# skip" lines)
```

**H1, health check.** cwd: the worktree. 05:13:41Z to 05:23:20Z. `TMPDIR=<scratch> timeout 2400 scripts/health-check.sh`. Exit 0. Tail:
```
  2 divergence signal(s) detected
  ⚠ AGENTS.md and GEMINI.md are not read by Claude Code — ...
── Running questions ──
  ✓ questions: structure valid, indexes current

All checks passed.
```

**P1/P2, per-assertion probe.** cwd `/tmp/fc-u2c-i1-m-IEZA`, about 05:14Z to 05:20Z. `test/scripts/probe.bats` is the three new tests (`build-loop-check.bats:761-797`) verbatim, under the suite's own `setup`/`imps`. `want` is redefined to log HIT/MISS instead of returning, and the status guards log instead of returning. Run for each lib with `run-probe.sh <lib> <log>` (copy the lib in, then `PROBE_LOG=<log> TMPDIR=<scratch> timeout 900 bats test/scripts/probe.bats`). Every run exited 0. Libs:
- main = `git show main:scripts/lib/dev-cycle-read.sh`
- head = HEAD's
- m1 = head with `[[ ${#ps[@]} -gt 0 ]] || return 0` replaced by `rc_q+=("${cs[@]}"); return 0` (no byte comparison)
- m2 = head with the `rc_p[...]="$(lower ...)"` line at `:1261` replaced by `:`
- m3 = head with the sha1sum line's `|| return 1` changed to `|| return 0`
- m4 = head with `elif [[ -L "$r/$p" ]]; then rc_q+=("/$r/$p"); fi` replaced by `fi`

```
assertion                                   main  head  m1   m2   m3   m4
T1 tree/main walk: ok                       HIT   HIT   HIT  HIT  HIT  HIT
T1 tree/main docs/b.md: imported            MISS  HIT   HIT  HIT  HIT  HIT
T1 tree/main docs/n.md: imported            MISS  HIT   HIT  HIT  HIT  HIT
T1 tree/main docs/c.md: imported            MISS  HIT   HIT  HIT  HIT  HIT
T1 tree/main docs/k2.md: imported           HIT   HIT   HIT  MISS HIT  HIT
T1 tree/main docs/gone.md: imported         MISS  HIT   HIT  HIT  HIT  HIT
T1 tree/main docs/e.md: -  (x3)             HIT   HIT   HIT  HIT  HIT  HIT
T2 tree/main walk: ok                       HIT   HIT   HIT  HIT  HIT  HIT
T2 tree/main docs/n.md, r.md, deep.md       MISS  HIT   HIT  HIT  HIT  HIT
T2 tree/main docs/other.md: -               HIT   HIT   HIT  HIT  HIT  HIT
T3 tree (chmod) walk: failed                HIT   HIT   HIT  HIT  HIT  HIT
T3 main (chmod) walk: failed                MISS  HIT   MISS HIT  MISS HIT
T3 tree/main docs/a.md: imported            HIT   HIT   HIT  HIT  HIT  HIT
T3 tree (stub) walk: failed                 HIT   HIT   MISS HIT  MISS HIT
T3 main (stub) walk: failed                 HIT   HIT   MISS HIT  MISS HIT
```
(Each row stands for the identical tree and main lines. m4: 31/31 HIT.) The unmodified suite, run with `bats -f U2b3b2c` against main's lib, gave `not ok` for all three tests (first failures: `docs/b.md: imported`, `docs/n.md: imported`, `walk: failed`).

**R1, realpath.** cwd: a scratch dir holding `loop.md -> loop.md`, `x.md -> gone` and a mode-000 `dd/`. `realpath -mz -- loop.md x.md dd/a.md` exits 0 and prints three paths. `realpath -e -- loop.md` fails with "Too many levels of symbolic links" (rc=1). `[[ -f loop.md ]]` is false.

**F1, find.** cwd: a scratch dir holding `t/real.md`, `t/good.md -> real.md`, `t/dang.md -> nowhere.md` and `t/chain.md -> dang.md`. Both `find -L t '(' -type f -o -type l ')' -iname '*.md'` and `find -H t -maxdepth 1 '(' -xtype f -o -xtype l ')'` print `t/chain.md t/dang.md t/good.md t/real.md`.

**F2, test 1 fixture.** cwd: a scratch repo. Commit `docs/{a,b,gone}.md`, then `git worktree add -q --detach ../side`; `ls side/docs` shows `a.md b.md gone.md`.

**T1, walks over /workspace.** cwd `/workspace`, 05:23:24Z to 05:23:47Z, 1-min load 1.78 to 1.83. Script: `cd /workspace; LC_ALL=C; source <lib>; ROOT_REAL=$(pwd -P); resolve_main || true; reader_settings`, then each walk timed with `$EPOCHREALTIME`. Run as `timeout 120 timing.sh <lib>`, alternating head/main three times. All walks rc=0.
```
head run1: tree 1.757  main 1.938  IMPORT_OTHER 7
main run1: tree 1.74   main 1.888  IMPORT_OTHER 0
head run2: tree 1.725  main 1.891
main run2: tree 2.737  main 1.906
head run3: tree 1.732  main 1.872
main run3: tree 1.709  main 1.814
distinct non-// names: head tree 242, head main 242, main-lib tree 242, main-lib main 242; all four sorted lists identical
```

---

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to /workspace/.claude/wt-build-loop-u2b3b2c/docs/reviews/code-fact-check-report-build-loop-u2b3b2c-i1.md, structured per the code-fact-check skill, with `Commit: f7e1bea2` as its first line and `**Replication:** k=1 (loop pass, decision 031)` in its header.
- Answered: yes. The code does what the PR intent says. Every behavioural claim about root_copies, IMPORT_OTHER, the C1 skip and the dangling-seed route held under execution, and the commit's 242 names, timing, 284 suites and health check reproduce. The two Incorrect findings are test-fixture comments whose assertions are weaker than stated: root_copies' `//` branch and its byte-equal skip have no biting test (mutants m4 and m1 survive). The three Stale findings are sha1sum mentions the diff left behind (`:45`, `:759-760`, `:1304`).
- Out of scope: the plan doc's U2b3b2c bullet (not in the branch diff); security and performance judgments (sibling critics).
- Escalate: (1) Test coverage. Mutants m1 (no byte comparison) and m4 (no `//` copy branch) pass all three new tests, so neither property is guarded. (2) Sourcing inventory. `test/scripts/dev-cycle.bats:1111,1115` does not list `root_copies` or `IMPORT_OTHER`, although prior units added new functions and globals there (not in this diff, so not verdicted). (3) Red on main. Test 3's tree-walk and stub halves and test 1's `k2`/`e` assertions are not red on main's lib. No comment claims they are, but a reviewer reading the tests as red-on-base would be misled.
- Decisions I made: I read "Suites 284" as the five suites prior commits name plus hermeticity-lint (the only combination summing to 284). I copied the execution output into Appendix A instead of `docs/reviews/execution-logs/`, because the review rules allow writing only this file.
