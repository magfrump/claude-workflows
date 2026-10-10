Commit: 007e867f
# Code Fact-Check Report

**Repository:** /workspace (worktree /workspace/.claude/wt-build-loop-u2b3b2c, branch `feat/build-loop-u2b3b2c`, HEAD 007e867f, main 8e550626)
**Scope:** `git diff main...HEAD`, final confirming pass, merged from three replicates (r1, r2, r3): `scripts/lib/dev-cycle-read.sh` (file header, contract items 4 and 9, walk doc block, parser cross-reference, import_readers' IMPORT_OTHER, rawfile, import_outside, outside_ok, root_copies, prompt_marks, outside_seeds, config_seeds, c1_seeds, imported_names, main_imports), `test/scripts/build-loop-check.bats` (the six U2b3b2c tests and the C1 test), `test/scripts/dev-cycle.bats` (inventory), the i2 rubric's red-on-prior-lib claims, and commit messages f7e1bea2, 8976fbdf, c69f352f, 007e867f
**Checked:** 2026-10-09
**Total claims checked:** 44
**Summary:** 35 verified, 4 mostly accurate, 3 stale, 1 incorrect, 1 unverifiable
**Commit:** 007e867f
**Replication:** k=3

This report merges `code-fact-check-report-build-loop-u2b3b2c-final-r1.md`, `-r2.md` and `-r3.md` by the code-review skill's most-severe-wins procedure. It is collation only: every verdict, quote and piece of evidence below comes from a replicate, and the replicate that supplied each claim's headline evidence is named in that claim. Appendix references (E1-E10, R1-R4, P1-P4, S1-S2, T1-T3, W1, B1-B2) point to the named replicate's own execution appendix. Where any replicate split a sentence or comment more finely, it is emitted at that granularity. A replicate that verdicted only the larger claim is marked `(compound)`. Legibility: every non-Verified claim is for-author, except Claim 41 (Unverifiable), which is for-orchestrator-synthesis like every Verified claim.

---

## Claim 1: Rubric: each fix's test is red on the lib before it ("red on f7e1bea2" for A1 and A2; "red on c69f352f" for B1 and B2)

**Location:** `docs/reviews/code-review-rubric-2026-10-09-feat-build-loop-u2b3b2c.md:15`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the six U2b3b2c tests run under main's, f7e1bea2's and c69f352f's libs, each swapped into a scratch copy. It does not re-run A3's mutant, which i2's E4 verified.
**Replicate verdicts:** r1=— · r2=Verified · r3=— · single-replicate detection
**Replicate annotations:** none

Carried from r2 (Claim 32). The rubric claims sit at `:15`, `:21` and `:39-40`. r2's E2 results: on main's lib, tests 1-6 are all red. On f7e1bea2's lib, tests 2 (A2), 3 (A1: `top.md: -`) and 4 are red. On c69f352f's lib, tests 3 (B1: `sub/top2.md: -`) and 4 (B2) are red. r1's E2 and r3's R1-R4 record the same per-lib red sets, under their test-title claims (Claims 31-38 here).

**Evidence:** `docs/reviews/code-review-rubric-2026-10-09-feat-build-loop-u2b3b2c.md:15`, `:21`, `:39-40`; r2 Appendix A E2

---

## Claim 2: "Both walks also read … and, through root_copies, other roots' copies of the names they reach (sha1sum)"

**Location:** `scripts/lib/dev-cycle-read.sh:42-47`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the claim that both walks call root_copies and that root_copies runs sha1sum. It does not establish that the tool list is exhaustive: root_copies and config_seeds also run realpath, which the sentence does not name, and it never claimed to.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2+r3: "xargs is also run and unnamed" · r3: "as the outside_seeds list before this branch already left out"

Carried from r1 (Claim 1). Both walks call root_copies: `root_copies cq cmp pdir "${queue[@]}" || return 1` (`:1567`) and `root_copies cq cmp pdir "${nm[@]}"` (`:1590`) in imported_names, and again at `:1663` and `:1721` in main_imports. It hashes with `nul_list rl xargs -0r -a <(printf '%s\0' "${hs[@]}") sha1sum -z --` (`:1292`). sha1sum is no longer used in outside_seeds: grepping `sha1sum` over config_seeds and c1_seeds (`:1347-1449`) finds no hits (paraphrased — no quote available because the claim covers absence of code; r2 and r3 report the same grep result).

**Evidence:** `scripts/lib/dev-cycle-read.sh:42-47`, `:1292`, `:1567`, `:1590`, `:1663`, `:1721`

---

## Claim 3: Contract item 4: "CLAUDE_CONFIG_DIR or IMPORT_MANAGED_DIR (outside_seeds reads them)"

**Location:** `scripts/lib/dev-cycle-read.sh:71-72`
**Type:** Architectural / Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers whether item 4 survived the split. It does not re-verify the rest of item 4, which the branch did not touch.
**Replicate verdicts:** r1=— · r2=Verified · r3=— · single-replicate detection
**Replicate annotations:** none

Carried from r2 (Claim 2). The split moved the reads into config_seeds: `[[ -z "${CLAUDE_CONFIG_DIR:-}" ]] || cf+=("$CLAUDE_CONFIG_DIR"); cf+=("$IMPORT_MANAGED_DIR")` (`:1353`). outside_seeds calls config_seeds with `config_seeds os_a || return 1` (`:1327`), so outside_seeds still reads both variables, through its helper.

**Evidence:** `scripts/lib/dev-cycle-read.sh:71-72`, `:1324-1331`, `:1350-1353`

---

## Claim 4: Contract item 9: "nor IMPORT_ROOTS, IMPORT_HOMES, IMPORT_DOTNEST or IMPORT_OTHER: they are import_readers' results, which a cache hit does not recompute."

**Location:** `scripts/lib/dev-cycle-read.sh:95-98`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the claims that import_readers sets all four variables and that a cache hit returns before recomputing them. It does not establish that no caller sets them, since the item is an instruction.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

Carried from r1 (Claim 2). On a miss the function clears all four: `IMPORT_READERS_DONE="$IMPORT_READERS_KEY"; IMPORT_ROOTS=""; IMPORT_HOMES=""; IMPORT_DOTNEST=""; IMPORT_OTHER=""` (`:1099`). It fills them at `:1128`, `:1138-1139` and `:1143-1145`. A hit returns first: `if [[ "$IMPORT_READERS_DONE" == "$IMPORT_READERS_KEY" ]]; then [[ -n "$IMPORT_ROOTS" ]]; return; fi` (`:1098`). r2 and r3 also cite the source-time clear at `:1075`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1075`, `:1092-1146`

---

## Claim 5: "# root_copies batches the same test: change the two together." (and its twin in root_copies: "rawfile's test is batched here (realpath -m with -f): change the two together.")

**Location:** `scripts/lib/dev-cycle-read.sh:162`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the equivalence of the two tests on an existing file. It does not cover a file removed between root_copies' `-f` and its realpath batch, where `-m` and `-e` would differ.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: "does not cover rawfile's `-n ROOT_REAL` guard, which root_copies does not need because need_root runs first" · r3: "does not establish anything about plaindir, which root_copies does not mirror"

Carried from r2 (Claim 4). rawfile: `[[ -n "${ROOT_REAL:-}" && -f "$1" ]] && r="$(realpath -e -- "$1" 2>/dev/null)" && [[ "$r" == "$ROOT_REAL/$1" ]]` (`:163`). root_copies: `-f "${ps[i]}" && "${rl[i]}" == "$ROOT_REAL/${ps[i]}"`, with `rl` from one `realpath -mz` batch (`:1286`, `:1288`). Once `-f` holds, the file exists, so `-m` and `-e` give the same path.

**Evidence:** `scripts/lib/dev-cycle-read.sh:162-163`, `:1264-1265`, `:1286-1288`

---

## Claim 6: Tree walk failure list: "It returns 1, with IMPORTED set to "error", when the start listing (…), outside_seeds, root_copies, prompt_marks, lower, a file read, import_readers or the parser (…) fails"

**Location:** `scripts/lib/dev-cycle-read.sh:686-690`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the three newly listed failure sources and the error marker on each. It does not establish that the list is exhaustive: an outside_proj realpath failure also fails the walk, and the list left it out before this branch too.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2: "does not re-check the entries that predate the branch" · r1+r2: executed, test 6 passes at HEAD with `walk: failed` (r1 E1, E2; r2 E2)

Carried from r3 (Claim 4). `IMPORTED_DONE=...; IMPORTED=error` is set at `:1546`, before `outside_seeds sd || return 1` (`:1558`) and `root_copies cq cmp pdir "${queue[@]}" || return 1` (`:1567`). Inside the loop the code is `outside_proj out work && { ... || prompt_marks pdir pext out "$f"; } || { IMPORTED=error; return 1; }` (`:1578`) and `root_copies cq cmp pdir "${nm[@]}" || { IMPORTED=error; return 1; }` (`:1590`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:686-690`, `:1539-1593`

---

## Claim 7: Walk doc block: "A seed that is a dangling link joins the queue as a // name, which only outside_proj reads …; a prompt's projected names are read as prompts (prompt_marks; one the walk already read is not read again, and one main stores as a symlink fails the main walk, as a symlinked prompt start does)."

**Location:** `scripts/lib/dev-cycle-read.sh:753-757`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `//` queuing of dangling seeds, the reading of projected names as prompts, and both stated exceptions in both walks. It does not establish how often the "already read" exception fires: probe P3 shows that in the main walk it fires for any link target that main's own starts import.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "does not cover a projected name the walk already read plain (named; override row 595)" · r3: "probe P2 shows that a queued but still unread name *is* re-marked, so 'read' is the exact boundary" · r3: "does not establish anything for links that are not dangling but still fail outside_ok, such as a link to a directory, which take the same `//` route" · r1: escalation on P3 (see Escalations, entry 1)

Carried from r1 (Claim 4). Seed loop: `p="${f:1}"; outside_ok "$p" || { [[ -L "$p" ]] || continue; p="/$p"; }` (`:1560`, `:1656`). Only outside_proj reads a `//` entry: `if [[ "$f" == //* ]]; then out="$f"` (`:1575`, `:1673`). prompt_marks only sets the mark when none is set: `[[ -n "${pm_p[$p]+set}" ]] || pm_p[$p]="$(lower "$p")"` (`:1314`). A name already seen is not queued again (`:1588`, `:1715`). The symlink arm refuses prompt directories: `[[ ${#xs[@]} -eq 0 ]] || { IMPORTED_MAIN=error; return 1; }` (`:1680`).

Executed (r1 E3). P1: a top-level dangling prompt link gives `.claude/commands/sib.md: imported` in both walks. P2: when main stores the target as a symlink, the main walk prints `walk: failed` (r2 E6 agrees: `main rc=1`, `IMPORTED_MAIN=error`). P3: when main's AGENTS.md imports the target, the tree walk reaches `top.md: imported`, but the main walk gives `top.md: -`, which is the named exception. r3's P2 reproduces the same split for a nested link: main `sub/top2.md: -`, tree `sub/top2.md: imported`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1556-1563`, `:1575-1578`, `:1652-1659`, `:1672-1706`, `:1308-1317`; r1 Appendix A E3; r2 Appendix A E6; r3 appendix P2

---

## Claim 8: Walk doc block: "For every repo name a walk reaches, a start included, root_copies also reads each other reader root's copy that ROOT_REAL lacks or holds with other bytes"

**Location:** `scripts/lib/dev-cycle-read.sh:757-762`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the sentence's mechanism (every reached repo name, starts included) and its two read conditions. It does not establish the full read set, which this sentence understates; that understatement is the finding.
**Replicate verdicts:** r1=Mostly accurate · r2=Verified · r3=Mostly accurate
**Replicate annotations:** r2: "It is not an exhaustive list of reads: a prompt copy is always read, and so is a copy with a link on either side, so the sentence understates what is read. Nothing it states is missed." · r3: "root_copies' own header states both (claim 11), but this summary was not updated in i2" · r3: alternative precise wording, "…each other reader root's copy, unless the name is no prompt and both are plain files with equal bytes" · r2: executed, test 1 passes at HEAD and is red on main's lib (`docs/b.md: -`)

Carried from r1 (Claim 5). root_copies also reads two kinds of copy with equal bytes, and the sentence names neither. The first is a prompt copy: the skip needs `-z "${rc_p[${ps[i]}]+set}"` (`:1288`). The second is a copy with a link on the way on either side: the skip needs `"${rl[i]}" == "$ROOT_REAL/${ps[i]}" && "${rl[n + i]}" == "${cs[i]}"` (`:1288`). It also queues `//ROOT/NAME` for a dangling link: `elif [[ -L "$r/$p" ]]; then qs+=("/$r/$p")` (`:1281`). root_copies' own header states all three (`:1254-1261`). A precise version would read: "…each other reader root's copy that ROOT_REAL lacks, holds with other bytes, or that is a prompt or reached through a link (or `//ROOT/NAME` for a dangling one)".

**Evidence:** `scripts/lib/dev-cycle-read.sh:757-762`, `:1272-1299`

---

## Claim 9: Walk doc block: "Named exceptions: … a symlinked directory in another root (A5); and a C1 start or copy ROOT_REAL holds in a checkout that is not clean … Any seed listing find, grep or realpath cannot complete, or a root_copies realpath or sha1sum, fails the walk"

**Location:** `scripts/lib/dev-cycle-read.sh:763-771`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the failure sources named and the dependence of the C1 skip and the copy comparison on a clean checkout. It does not establish that A5 covers root_copies' own not-covered case (Claim 16).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: "does not cover the inaccessible-host exception, which predates this branch" · r3: "does not establish behaviour on a failing root_copies realpath, which was read statically: `|| return 1` at `:1286`"

Carried from r2 (Claim 8). `nul_list rl xargs ... realpath -mz -- && [[ ${#rl[@]} -eq $((2 * n)) ]] || return 1` (`:1286`) and `... sha1sum -z -- && [[ ${#rl[@]} -eq ${#hs[@]} ]] || return 1` (`:1292`). Both walks propagate the failure (Claims 6 and 26). The C1 skip and the copy comparison both read the working tree (`rawfile "${ir[i]}"`, `:1447`; `-f "${ps[i]}"`, `:1288`), so they match main only under item 2. On main's lib, E2's test 6 is red only in the main-walk half (`walk: ok`), which shows that in the main walk the comparison is the only reader of the unreadable checkout file.

**Evidence:** `scripts/lib/dev-cycle-read.sh:763-771`, `:1286`, `:1292`, `:1447`; r2 Appendix A E2, E3

---

## Claim 10: "root_copies costs 66 ms per walk over 7 other roots here, and about 11 ms per copy it reads: a worktree at a commit where many imported files differ adds a read per file"

**Location:** `scripts/lib/dev-cycle-read.sh:775-777`
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers root_copies' own time per walk and the cost of one copy read on today's /workspace registry (7 other roots, 4 copies queued per walk). It does not establish the cost on another registry, or for copies larger than SKILL.md/AGENTS.md.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "The main walk's 66 ms reads closer to 80 ms under load [0.081-0.085 s]. That is within 'per walk' noise" · r2: "does not cover … the 13 s synthetic figure" · r3: "the 11 ms includes the walk's per-file bookkeeping, which I did not time on its own"; r3 measured 0.051-0.063 s per walk and 8.4-9.1 ms per bare import_file at load 3.5-3.9

Carried from r1 (Claim 7). E4 wrapped root_copies over three runs: tree 74.5/67.2/64.7 ms and main 70.6/68.7/68.4 ms, with 31 calls and 4 copies per walk, at a load average of about 2.8. E5: `import_file` plus `lower` on 14 real copies cost 9.4/9.8/9.7 ms each. With the walk's per-name loop added, "about 11 ms" fits. The "adds a read per file" part follows from root_copies queuing one entry per (name, root) pair: `ps+=("$p"); cs+=("$r/$p")` (`:1280`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:775-777`, `:1272-1299`; r1 Appendix A E4, E5; r2 Appendix A E4, E7, E8; r3 appendix T1, T2

---

## Claim 11: "Every name read from text starts at an @ byte (…): outside_seeds drops a seed holding none unless a link leads to it (with_at leans on this)."

**Location:** `scripts/lib/dev-cycle-read.sh:954-956`
**Type:** Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers whether this cross-reference in the parser survived the split. It does not re-verify the parser's scan.
**Replicate verdicts:** r1=— · r2=Verified · r3=— · single-replicate detection
**Replicate annotations:** none

Carried from r2 (Claim 10). Both halves of the split still filter through with_at. config_seeds keeps `cs_at` or a link below a root (`:1394-1401`). c1_seeds keeps `[[ -n "${c1_at[${cx[i]}]+set}" || -L "${cx[i]}" ]]` (`:1442`). outside_seeds is their only caller (`:1327-1328`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:954-956`, `:1324-1331`, `:1394-1401`, `:1439-1442`

---

## Claim 12: "IMPORT_OTHER holds every root's real path but ROOT_REAL's that is a directory here, once each, newline-separated: the roots whose copies root_copies and outside_seeds read."

**Location:** `scripts/lib/dev-cycle-read.sh:1070-1072`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers how IMPORT_OTHER is built and who reads it. It does not cover the partial value left after a refusal (override row 596).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r3: "does not establish that host-spelled roots this container cannot see are present; they are excluded by `-d`, which is the named exception"

Carried from r1 (Claim 8). `p="${rs_real[i]}"; [[ $t == h || "$p" == "$ROOT_REAL" || -n "${rs_seen[o$p]+set}" || ! -d "$p" ]] || { rs_seen[o$p]=1; IMPORT_OTHER+="$p"$'\n'; }` (`:1128`). The trailing newline is stripped at `:1145`. The readers are root_copies (`:1275-1276`) and c1_seeds (`:1425`), which matches the comment's "outside_seeds". E6: outside_seeds output on /workspace is identical under f7e1bea2's lib and HEAD's (9 seeds; `diff` empty).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1092-1146`, `:1425`; r1 Appendix A E6

---

## Claim 13: import_outside: "FILE, an absolute path (for the walks, a name from the parser's second channel, below no reader root, or an outside_seeds start, which may lie in another root)"

**Location:** `scripts/lib/dev-cycle-read.sh:1176-1179`
**Type:** Architectural / Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the list of absolute FILEs the walks pass. It does not affect behaviour: import_outside reads any absolute path the same way.
**Replicate verdicts:** r1=Stale · r2=Stale · r3=Stale (compound)
**Replicate annotations:** r1+r3: "does not question import_outside's behaviour" / "both functions handle the new class correctly"

Carried from r2 (Claim 12). The branch adds a third kind of absolute FILE: another root's copy from root_copies, `if outside_ok "$r/$p"; then ps+=("$p"); cs+=("$r/$p")` (`:1280`), queued as `qs+=("${cs[i]}")` (`:1288`, `:1293`). The walks then read it through `import_file "$f" ...` (`:1576`, `:1674`), which routes `/*` to import_outside (`:1207`). The parenthetical lists only the second channel and outside_seeds starts, so it no longer names every FILE the walks pass. Precise version: "...or an outside_seeds start or another root's copy (root_copies), either of which may lie in another root".

**Evidence:** `scripts/lib/dev-cycle-read.sh:1176-1180`, `:1207`, `:1280`, `:1288`, `:1576`, `:1674`

---

## Claim 14: outside_ok: "whether a walk reads PATH, an absolute name (one below no reader root, or an outside_seeds start, which may lie in another root): a readable regular file (the one admission rule both walks apply)"

**Location:** `scripts/lib/dev-cycle-read.sh:1208-1211`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the parenthetical list of the names outside_ok admits. It does not question the rule itself (`-f` and `-r`).
**Replicate verdicts:** r1=Stale · r2=Stale · r3=Stale (compound)
**Replicate annotations:** r3: "does not establish any behavioural defect: both functions handle the new class correctly"

Carried from r1 (Claim 10). root_copies now also admits other roots' copies through this function: `if outside_ok "$r/$p"; then ps+=("$p"); cs+=("$r/$p")` (`:1280`). The parenthetical names only second-channel names and seeds, so it is stale in the same way as Claim 13. Add "or another root's copy (root_copies)".

**Evidence:** `scripts/lib/dev-cycle-read.sh:1208-1212`, `:1280`

---

## Claim 15: root_copies' header, admission and read clauses: Q cleared; absolute and // names skipped; CMP keys; "gets ROOT/NAME when outside_ok admits it, unless NAME is no prompt, rawfile's test holds on both sides (…) and their bytes are equal (… resolve its relative names against every root; a prompt copy is always read, since its absolute path can add prompt bases …)"; //ROOT/NAME for a link outside_ok rejects; PDIR marking of the copy and its // form; xargs batches and return 1

**Location:** `scripts/lib/dev-cycle-read.sh:1248-1266`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each clause against root_copies' whole body (`:1272-1299`) and its four call sites. It does not establish that the `//` form of a prompt copy is driven by a test (override row 601), or that the "resolve against every root" argument holds for prompts, which the clause itself excludes.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r1: "does not establish behaviour for a root whose real path holds a newline, which import_readers refuses upstream" · r1+r3: "the `//` form's PDIR mark is verified statically only, since no test drives it (override row 601)" · r3: "'a dangling one' names only the common case of a link that outside_ok rejects (a link to a directory or to an unreadable file takes the same branch)" · r1: executed mutant E7, with the dangling `elif` at `:1281` removed, fails test 1 with `want: docs/gone.md: imported`

Carried from r2 (Claim 14a).
- **Q cleared:** `rc_q=()` (`:1274`).
- **Skips:** `[[ -n "$p" && "$p" != /* && -z "${rc_c[$p]+set}" ]] || continue; rc_c[$p]=1` (`:1278`). A `//` name starts with `/`.
- **Skip only when all hold:** `[[ -z "${rc_p[${ps[i]}]+set}" && -f "${ps[i]}" && "${rl[i]}" == "$ROOT_REAL/${ps[i]}" && "${rl[n + i]}" == "${cs[i]}" ]]` (`:1288`) admits a name to the hash list. Only equal hashes drop it: `[[ "${rl[2*i]:0:40}" == "${rl[2*i+1]:0:40}" ]] || { qs+=...; }` (`:1293`). The copy side's `-f` comes from outside_ok (`:1280`).
- **Both sides via one xargs realpath:** `printf '%s\0' "${ps[@]}" "${cs[@]}") realpath -mz --` (`:1286`).
- **`//` form:** `elif [[ -L "$r/$p" ]]; then qs+=("/$r/$p")` (`:1281`).
- **PDIR marking:** `[[ -z "${rc_p[${qn[i]}]+set}" ]] || rc_p[${qs[i]}]="$(lower "${qs[i]}")" || return 1` (`:1296`). This covers both plain and `//` entries.
- **"resolve its relative names against every root":** import_targets joins a relative DIR "under every reader root", while an absolute one is "joined as it is" (`:819-822`). So for a non-prompt plain copy with equal bytes, ROOT_REAL's read already yields each root's resolution.

E2: tests 2 and 4 (the linked-directory copy and the equal-bytes prompt copy) pass on HEAD, and are red on f7e1bea2's and c69f352f's libs respectively.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1248-1299`, `:817-822`; r2 Appendix A E1, E2, E3; r1 Appendix A E2, E7; r3 appendix R1-R4

---

## Claim 16: root_copies' header: "Not covered: a copy below a dangling linked directory in that root, which is skipped (A5's class)."

**Location:** `scripts/lib/dev-cycle-read.sh:1266-1267`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers which copy paths fall through both of root_copies' arms. It does not assess whether the wider case can hide an import a session loads.
**Replicate verdicts:** r1=Verified (compound) · r2=Mostly accurate · r3=Verified (compound)
**Replicate annotations:** r2: escalated to security-reviewer as a possible fail-open of A5's class (see Escalations, entry 2)

Carried from r2 (Claim 14b). The skip happens whenever `ROOT/NAME` is neither admitted nor a link itself: `if outside_ok "$r/$p"; then ... elif [[ -L "$r/$p" ]]; then ...; fi` (`:1280-1281`). Below a dangling directory link, `-L` on the leaf fails because lstat fails, so the stated case is skipped as claimed (r1 and r3 verify this part too). The same happens below a *live* linked directory whose target lacks NAME. For example, with `ROOT/docs -> elsewhere` and no `elsewhere/x.md`, `-f` and `-L` are both false, so the path is skipped with no projection, although outside_proj would project it as `realpath -m` names it (paraphrased — no quote available because this follows from the two tests at `:1280-1281` and is not a separate code path). Precise version: "a copy below a linked directory in that root (dangling, or whose target lacks the file)".

**Evidence:** `scripts/lib/dev-cycle-read.sh:1266-1267`, `:1279-1282`, `:1221-1231`

---

## Claim 17: root_copies' header: "The cost: about 11 ms per copy read, and a copy is read in every root holding it with other bytes (i1 performance F1: 13 s over 8 worktrees at a commit where 50 imported files differ; one read per distinct bytes would miss a .. name that leaves its root, which resolves differently in each)."

**Location:** `scripts/lib/dev-cycle-read.sh:1267-1271`
**Type:** Performance / Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the per-copy price on /workspace, the per-root read (code), the cited figure (the performance review's table) and the dedupe rationale (how import_targets treats absolute DIRs). It does not re-run the 8-worktree synthetic fixture.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** none

Carried from r2 (Claim 14c). The per-root read follows from the loop `for r in "${rs[@]}"` (`:1279`), which queues each root's differing copy under its own path. The performance review reports "8 | main / branch | 0.88-0.91 / 12.7-13.4 s" (`docs/reviews/performance-review-2026-10-09-u2b3b2c-i1.md:26`) and "Each extra read costs about 10-12 ms" (`:29`). E7 measured 9.2-11.5 ms. The dedupe rationale holds because a copy is read through import_outside with its own absolute directory, `import_targets "${d:-/}"` (`:1197`), and an absolute DIR is "joined as it is" (`:821`). A `..` that leaves the root therefore resolves against that root's parent only.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1267-1271`, `:1197`, `:1279`, `:819-822`; `docs/reviews/performance-review-2026-10-09-u2b3b2c-i1.md:26-29`; r2 Appendix A E7

---

## Claim 18: prompt_marks' header: "PDIR gets it lower-cased (its own prompt bases), and the associative array PEXT gets the link's directory and the link's own prompt bases (absolute, newline-separated), which the walks add to its DIRS (… a link under a nested .claude/). A name already read is not read again as a prompt: a named exception. It returns 1 when lower fails."

**Location:** `scripts/lib/dev-cycle-read.sh:1300-1307`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the function body, both call sites and both walks' use of pext, for a link at side's top-level `.claude/commands/` and one under `side/sub/.claude/commands/`. The main walk is covered in its 100644 and checkout arms, and its 120000 arm refuses. It does not cover a name the walk already read plain (override row 595), or root_copies' copies of a projected name, which get their own path's bases and not the link's.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r3: "does not establish that a session would otherwise resolve against the link's directory: that is a model of Claude Code that I did not trace" / "does not establish the resolution model's fidelity to Claude Code beyond being a superset" · r3: probe P1 resolved names against the link's own directory in both walks, at top level (`.claude/commands/helper.md: imported`) and nested (`sub/.claude/commands/h2.md: imported`)

Carried from r2 (Claim 15). Body: `prompt_bases pm_b "${pm_p[$4]#/}" "$l"` with `l="${4#/}"`, then `printf -v b '%s\n' "${l%/*}" "${pm_b[@]:1}"` (`:1310-1311`). That is the link's directory plus every directory holding a `.claude/` component in the link's absolute path (prompt_bases, `:670-679`). The `""` base is dropped, and pdir's own `""` supplies it. Each repo name gets `pm_p[$p]` when unset and `pm_x[$p]` appended (`:1313-1315`). Both walks consume it before the read, with `[[ -z "${pext[$f]+set}" ]] || mapfile -t -O "${#xs[@]}" xs <<<"${pext[$f]}"` (`:1573`, `:1670`). Both read arms pass `"${xs[@]}"`: the checkout arm through import_file (`:1674`), and the 100644 arm through `import_targets "$d" "${xs[@]}"` (`:1676`). With xs non-empty, the 120000 arm fails the walk (`:1680`; E6).

The call order puts prompt_marks before the name loop and root_copies (`:1578` before `:1583-1590`, and `:1706` before `:1711-1721`), so a name first reached through the link is marked before it is queued or compared. E2: test 3 passes on HEAD in both walks with `docs/t.md`, `top.md` and `sub/top2.md` imported. It was red on f7e1bea2 (`top.md: -`) and on c69f352f (`sub/top2.md: -`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1300-1317`, `:670-679`, `:1572-1578`, `:1669-1680`, `:1706`; `test/scripts/build-loop-check.bats:786-796`; r2 Appendix A E2, E3, E6; r1 Appendix A E3; r3 appendix P1

---

## Claim 19: outside_seeds: "config_seeds', then c1_seeds'. It returns 1 when either does, or a seed's path holds a newline. Run it after import_readers (IMPORT_ROOTS, IMPORT_HOMES and IMPORT_OTHER)."

**Location:** `scripts/lib/dev-cycle-read.sh:1318-1323`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the order, the return rules, the dependencies, and the claim that the seeds match f7e1bea2's unsplit function on /workspace. It does not prove seed equality on every layout (the i2 report also checked a fixture).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: seeds also identical under c69f352f's lib (1 `f`, 8 `p`); "the i2 report's E1 covered one [fixture] where a path is both a config and a C1 seed"

Carried from r1 (Claim 14). `config_seeds os_a || return 1; c1_seeds os_c || return 1; os_a+=("${os_c[@]}"); for d in "${os_a[@]}"; do [[ "$d" != *$'\n'* ]] || return 1; done` (`:1327-1330`). config_seeds reads IMPORT_ROOTS and IMPORT_HOMES (`:1351`), and c1_seeds reads IMPORT_OTHER (`:1425`). E6: 9 seeds, identical to f7e1bea2's.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1324-1331`; r1 Appendix A E6; r2 Appendix A E9; r3 appendix S1

---

## Claim 20: config_seeds' header: "Only a seed holding an @ byte, or whose real path differs and lies below a reader root (a link the walks project as that repo path; a dangling one included …), can yield a name … It returns 1 when a find, grep, realpath or lower_all fails, or CLAUDE_CONFIG_DIR is set but not absolute."

**Location:** `scripts/lib/dev-cycle-read.sh:1332-1346`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the keep rule, the inclusion of dangling links (`-type l` under `-L`, `-xtype l` under `-H`) and the return list. It does not cover python3's failure, which falls back to the cache directory rather than failing, and the comment does not claim it does.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

Carried from r1 (Claim 15). Keep rule: `in=""; [[ -z "${cs_at[${cx[i]}]+set}" ]] || in=1; [[ -n "$in" || "${rl[i]}" == "${cx[i]}" ]] || for q in "${rs[@]}"; do [[ "${rl[i]}" != "$q"/* ]] || in=1; done` (`:1399-1400`). Dangling links: `'(' -type f -o -type l ')'` (`:1377-1380`) and `'(' -xtype f -o -xtype l ')'` (`:1387`). Executed: test 5 (`$HOME/.claude/CLAUDE.md` and `rules/r.md` dangling into side, `rules/x.md` dangling to `/nonexistent`) passes at HEAD and fails on main's lib.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1347-1403`; r1 Appendix A E1, E2

---

## Claim 21: c1_seeds' header: "every start file (…) in another reader root present here (IMPORT_OTHER), tracked or not, that holds an @ byte or is a link (…). One is skipped when it is not a link and ROOT_REAL holds a plain file (rawfile) at its path below its innermost root that is a start of the same kind (f or p) there: both walks start at that file and pass it to root_copies (…). It returns 1 when a find, grep or lower_all fails."

**Location:** `scripts/lib/dev-cycle-read.sh:1404-1421`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the seed set, the skip rule, and the claim that each skipped seed's path reaches root_copies from both walks' start calls with pdir set. It assumes contract item 2's clean checkout, as the comment states. It does not cover a dirty checkout.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r3: "does not establish the untracked-nested-repo exclusion beyond contract item 2" · r3: "main's lib seeds 4 more on /workspace, the differing `skills/dev-cycle/SKILL.md` copies, which root_copies now reads instead (S2, T1)"

Carried from r2 (Claim 18a). Seed rule: `isstart "${lo[i]}" && [[ -n "${c1_at[${cx[i]}]+set}" || -L "${cx[i]}" ]] || continue` (`:1442`). Skip rule: `[[ ! -L "${cx[i]}" && "$q" == "$c" ]] && isstart "$d" && rawfile "${ir[i]}" || c1_a+=("$c${cx[i]}")` (`:1447`). Here `ir[i]` is the path below the innermost root in IMPORT_OTHER (`:1437`), so root_copies' `"$r/$p"` for that root is exactly `cx[i]`. The tree walk's starts are every ls-files and untracked .md name that passes `isstart` and `inrepo_here` (`:1547-1554`). rawfile implies inrepo_here's no-link condition, so ROOT_REAL's file is a start, and `prompt_dir pdir` marks it when it is a prompt (`:1554`). The main walk's starts are main's isstart names and the checkout's (`:1644-1651`). Both walks call root_copies over all starts after pdir is set (`:1567`, `:1663`). E9: seeds unchanged across libs on /workspace.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1404-1449`, `:1547-1567`, `:1640-1664`; r2 Appendix A E9; r3 appendix S1, S2

---

## Claim 22: c1_seeds' header: "…pass it to root_copies, which reads this copy when its bytes differ"

**Location:** `scripts/lib/dev-cycle-read.sh:1413-1414`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the read condition root_copies applies to a skipped C1 seed. The omission understates reads (the fail-closed direction). It misses no import.
**Replicate verdicts:** r1=Verified (compound) · r2=Mostly accurate · r3=Verified (compound)
**Replicate annotations:** r1+r3: "'Reads this copy when its bytes differ' is a lower bound: since 007e867f a prompt copy is read at any bytes, and so is a copy with a link on the way. That only adds reads." / "a sufficient condition, not the whole rule: a prompt copy is read even when equal" · r2 (Decisions): "each omission errs toward reading more"

Carried from r2 (Claim 18b). For a skipped `p` seed, the name is in pdir, so root_copies never takes the equal-bytes path: `[[ -z "${rc_p[${ps[i]}]+set}" && ... ]]` fails and the copy goes straight to `qs` (`:1288`). As of 007e867f a prompt copy is read whatever its bytes, but the comment still states the bytes condition alone. Precise version: "which reads this copy when its bytes differ, and a prompt's always".

**Evidence:** `scripts/lib/dev-cycle-read.sh:1413-1414`, `:1288`, `:1259`

---

## Claim 23: "# rawfile, not -f, on ROOT_REAL's copy: one reached through a link there is no tree walk start (U2b3b2b i1 fact-check 19b)."

**Location:** `scripts/lib/dev-cycle-read.sh:1444`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the tree walk, which the comment names. It does not cover the main walk, which reads main's blob for a path main stores.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

Carried from r1 (Claim 17). A file reached through a linked directory fails inrepo_here's blocker test (`:191`), so `if ! isstart "$lp" || ! inrepo_here "$f"; then continue; fi` (`:1552`) drops it as a start.

**Evidence:** `scripts/lib/dev-cycle-read.sh:191`, `:1444-1447`, `:1552`

---

## Claim 24: imported_names' seed-loop and start-pass comments: "a dangling link as //PATH, which the loop projects alone (outside_proj)"; "Other roots' copies of the starts, then of every name the loop reaches (root_copies). c1_seeds skips another root's start that has the same kind here only because every start passes through here, pdir already set."

**Location:** `scripts/lib/dev-cycle-read.sh:1556-1566`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the tree walk's comments against the lines they annotate, with pdir set at `:1554` and `:1562` before `:1567`. It does not cover main_imports (Claims 28 and 29), and the coupling's correctness is Claim 21.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** none

Carried from r1 (Claim 18). For a dangling seed, `if [[ "$f" == //* ]]; then out="$f"` skips import_file, and `outside_proj out work` (`:1578`) then projects it. The root_copies call follows the start and seed loops (`:1548-1567`), where `prompt_dir pdir` (`:1554`) and the seed's `pdir[$p]` (`:1562`) have already run.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1539-1568`

---

## Claim 25: imported_names' inline comments: "# a dangling prompt link's bases (prompt_marks)"; "# a dangling link: outside_proj reads its real path alone"

**Location:** `scripts/lib/dev-cycle-read.sh:1573-1575`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the lines they annotate. It does not cover outside_proj's own behaviour beyond the `//` entry.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** none

Carried from r2 (Claim 21). Only prompt_marks writes pext (`:1315`). For `//*`, `out="$f"`, and the next statement runs `outside_proj out work` (`:1578`). outside_proj reads every `//` line that outside_ok rejects, applies realpath -m to it, and projects the ones that differ (`:1224-1230`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1573-1578`, `:1221-1231`

---

## Claim 26: main_imports fails when "outside_seeds, root_copies or prompt_marks fails"

**Location:** `scripts/lib/dev-cycle-read.sh:1600`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three added sources. It does not re-verify the pre-existing list.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** none

Carried from r2 (Claim 22). `IMPORTED_MAIN=error` is set first (`:1618`). Then come `outside_seeds sd || return 1` (`:1654`), `root_copies ... || return 1` (`:1663`), `prompt_marks pdir pext out "$f"; } || { IMPORTED_MAIN=error; return 1; }` (`:1706`) and `root_copies cq cmp pdir "${nm[@]}" || { IMPORTED_MAIN=error; return 1; }` (`:1721`). E2, test 6's main half: `walk: failed` on HEAD, `walk: ok` on main's lib.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1600`, `:1618`, `:1654`, `:1663`, `:1706`, `:1721`; r2 Appendix A E2, E3

---

## Claim 27: "Phase 2 begins when queue empties: tq's checkout files and outside files (absolute paths, never main's: outside seeds, // imports and other roots' copies, and //PATH entries, dangling links outside_proj projects) then join it, and a path main lacks reads the checkout."

**Location:** `scripts/lib/dev-cycle-read.sh:1607-1610`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what joins tq. It does not cover names main has that a phase-2 file reaches. Those join `queue` directly (`:1719`), and the comment does not say otherwise.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r3: "'dangling links' names the usual case of a `//PATH` entry, which also arises for any link outside_ok rejects"

Carried from r2 (Claim 23). tq receives the seeds (`:1658`), the copies (`:1664`, `:1722`), the `//` imports (`:1714`) and the checkout-only names (`:1719`). `case "${ent[$f]-checkout}"` sends every non-main path, `//PATH` included, to the checkout arm (`:1672-1673`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1607-1610`, `:1649`, `:1658`, `:1664`, `:1667-1675`, `:1714-1722`

---

## Claim 28: main_imports' seed-loop and start-pass comments: "a dangling link as //PATH, projected alone, as in imported_names"; "Other roots' copies of the starts, then of every name the loop reaches (root_copies), in phase 2. c1_seeds skips … only because every start passes through here, pdir already set."

**Location:** `scripts/lib/dev-cycle-read.sh:1652-1662`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers sequencing. It does not establish anything about starts that main_checkout answers 2 for, which are dropped. A C1-skipped file is a rawfile there and is either main's or admitted (0), so the coupling holds under contract item 2.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r1: "'In phase 2' means the copies are queued on tq, which is how the code does it"

Carried from r3 (Claim 19). `prompt_dir pdir "$f" "${cand[i]:2}"` runs before the main_checkout gate (`:1647`), and `root_copies cq cmp pdir "${queue[@]}" "${tq[@]}"` comes after both start loops (`:1663`). Copies are queued with `for p in "${cq[@]}"; do [[ -n "${seen[$p]+set}" ]] || { seen[$p]=1; tq+=("$p"); }; done` (`:1664`, r1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1640-1664`

---

## Claim 29: main_imports' inline comments: "# a dangling prompt link's bases (prompt_marks)"; "# a dangling link: outside_proj below reads its real path alone"

**Location:** `scripts/lib/dev-cycle-read.sh:1670-1673`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the lines they annotate. It does not cover outside_proj's own behaviour beyond the `//` entry.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** none

Carried from r2 (Claim 21). Only prompt_marks writes pext (`:1315`). The checkout arm is `if [[ "$f" == //* ]]; then out="$f"` (`:1673`), and `outside_proj` runs after the case (`:1706`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1670-1675`, `:1706`, `:1221-1231`

---

## Claim 30: C1 test title: "C1: both walks start at the start files another worktree holds, listed from the file system, skipping one whose bytes match this checkout's plain copy or that holds no @ …"

**Location:** `test/scripts/build-loop-check.bats:724`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the title's statement of the skip rule. It does not question the test body, which still passes at HEAD.
**Replicate verdicts:** r1=Stale · r2=— · r3=Stale
**Replicate annotations:** r3: alternative precise wording, "skipping a non-link one this checkout holds as a plain start of the same kind (root_copies reads it when its bytes differ), or one holding no @"

Carried from r1 (Claim 21). The title is unchanged from main, but this branch removed C1's byte comparison. C1 now skips a non-link start whenever ROOT_REAL holds a plain start of the same kind at that path, whatever its bytes: `[[ ! -L "${cx[i]}" && "$q" == "$c" ]] && isstart "$d" && rawfile "${ir[i]}" || c1_a+=(…)` (lib `:1447`). Bytes now matter only to root_copies. The body's assertions still hold, because the skipped `$sd/AGENTS.md` and `$sd/GEMINI.md` (`:747`) are each skipped for another reason. Precise text: "skipping one this checkout holds as a plain start of the same kind (root_copies compares the bytes) or that holds no @".

**Evidence:** `test/scripts/build-loop-check.bats:724-748`; `scripts/lib/dev-cycle-read.sh:1447`

---

## Claim 31: Test title: "both walks read another worktree's copy of a name they reach when this checkout lacks it or its bytes differ, through chains there; a prompt's copy reads as a prompt; a dangling one is projected (U2b3b2c; U2b3b2b i1 security F1)"

**Location:** `test/scripts/build-loop-check.bats:761`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the fixture's assertions at HEAD and the fact that they fail on main's lib. It does not establish that the prompt part is red on main: main's lib already seeds the differing prompt through C1, so `docs/k2.md: imported` there.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: "does not cover a prompt copy with equal bytes, which test 4 covers" · r2: "does not cover a nested-root layout" · r1: mutant E7 (dangling `elif` removed) fails with `want: docs/gone.md: imported`

Carried from r3 (Claim 21). The test passes at HEAD, and fails on main's lib with `docs/b.md: -`, `docs/n.md: -`, `docs/c.md: -` and `docs/gone.md: -` (appendix R1). The dangling `docs/b.md -> gone.md` in side projects to `docs/gone.md`.

**Evidence:** `test/scripts/build-loop-check.bats:761-774`; r3 appendix R1, R4; r1 Appendix A E2, E7; r2 Appendix A E2

---

## Claim 32: "# side's prompt differs, so C1 leaves it to the name: its @docs/k2.md resolves against side's top level only as a prompt."

**Location:** `test/scripts/build-loop-check.bats:767`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the comment's causal "differs, so C1 leaves it". It does not cover the second half ("resolves against side's top level only as a prompt"), which is right: as a plain file the copy's names resolve only against `$sd/.claude/commands`.
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Incorrect
**Replicate annotations:** r1+r2: "The conclusion is right on both counts" / the second half is correct; "It does not affect the assertion, which passes" · r2 (Decisions): "verdicted … Mostly accurate rather than Incorrect … [it] misattributes a cause without changing an assertion" · r3: "Severity: low (test comment)"

Carried from r3 (Claim 22). The natural reading is that C1 leaves side's prompt to the name *because* it differs. In fact C1 skips it whatever its bytes, since ROOT_REAL holds `.claude/commands/k.md` as a same-kind plain start (`lib:1447`). At HEAD root_copies also reads a prompt copy whatever its bytes (`-z "${rc_p[${ps[i]}]+set}"`, `lib:1288`). The difference only gives the copy an import that ROOT_REAL's copy lacks (`k: @docs/k2.md`). A reader taking the comment at its word would think C1 still compares bytes, which is the rule this branch removed. Precise version: "C1 leaves side's prompt to the name (this checkout holds it as a prompt); its different text imports docs/k2.md, which resolves against side's top level only as a prompt."

**Evidence:** `test/scripts/build-loop-check.bats:767-768`; `scripts/lib/dev-cycle-read.sh:1288`, `:1447`

---

## Claim 33: Test title: "a copy with this checkout's bytes under a linked directory is read, so its real path is projected (U2b3b2c; i1 security F2)"

**Location:** `test/scripts/build-loop-check.bats:776`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a live linked directory that holds the file. It does not cover one whose target lacks the file (Claim 16).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r3: "does not establish the case of a dangling linked directory, which is the named A5-class exception"

Carried from r2 (Claim 26). `mv "$sd/docs" "$sd/real" && ln -s real "$sd/docs"`, then `want real/x.md imported` in both walks (`:781-782`). E2: passes on HEAD, red on main's and f7e1bea2's libs (`real/x.md: -`).

**Evidence:** `test/scripts/build-loop-check.bats:776-784`; r2 Appendix A E2, E3; r1 Appendix A E2; r3 appendix R1-R4

---

## Claim 34: "# (A plain copy with equal bytes is skipped as a cost: the parser already resolves this checkout's relative names against every root, so reading it could add nothing.)"

**Location:** `test/scripts/build-loop-check.bats:777-778`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the comment against root_copies at HEAD. It holds for a non-prompt plain copy, the case this test builds (`docs/x.md`). It does not hold for a prompt.
**Replicate verdicts:** r1=Verified (compound) · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r1: verified the note "for a non-prompt copy with no link on the way. It does not cover prompt copies, which test 4 and Claim 12 address" · r3: "this comment did not change in 007e867f (`git diff c69f352f 007e867f -- test/` touches only tests 3 and 4)" · r2+r3: the i2 pass (claim 16 / rubric row B2) already flagged this comment as wrong for prompts; the code was fixed, but the comment was not edited (see Escalations, entry 3)

Carried from r2 (Claim 27). Since 007e867f, a plain *prompt* copy with equal bytes is not skipped: `[[ -z "${rc_p[${ps[i]}]+set}" && -f ... ]]` (`scripts/lib/dev-cycle-read.sh:1288`). Reading it can add names, because its absolute path adds prompt bases. Test 4 (`:798-802`) asserts exactly that, and E2 shows it red on c69f352f's lib. Precise version: "A plain copy of a non-prompt name with equal bytes is skipped ...".

**Evidence:** `test/scripts/build-loop-check.bats:777-778`, `:798-802`; `scripts/lib/dev-cycle-read.sh:1259`, `:1288`; r2 Appendix A E2

---

## Claim 35: Test title and comment: "a dangling prompt link in another worktree reads its target as a prompt (U2b3b2c i1 security F1)"; "Under a nested .claude/, the link's own bases (side/sub) apply to its target's names too (i2 fact-check 9b)."

**Location:** `test/scripts/build-loop-check.bats:786-790`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the title and the nested comment in both walks. It shows that the nested assertion is the part i2 fixed, and that the top-level part is the i1 fix.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "does not cover a target already read plain" · r3: "does not establish resolution against the link's own directory; probe P1 covered that separately"

Carried from r1 (Claim 25). E2: on f7e1bea2 the test fails at `want: top.md: imported`. On c69f352f it fails only at `sub/top2.md: -`, with `docs/t.md` and `top.md` imported. At HEAD it passes. r2 and r3 add that on main's lib it fails at `docs/t.md: -`.

**Evidence:** `test/scripts/build-loop-check.bats:786-796`; r1 Appendix A E2; r2 Appendix A E2; r3 appendix R1-R4

---

## Claim 36: Test title: "a prompt copy with this checkout's bytes is still read: a worktree under a .claude/ adds prompt bases (U2b3b2c i2 fact-check 16)"

**Location:** `test/scripts/build-loop-check.bats:798`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the claim that it passes at HEAD and fails on the lib before the i2 fix. It does not show that /workspace's own layout reaches this case.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "does not cover the `//` form of a prompt copy (override row 601)" · r3: "does not establish behaviour for a non-prompt equal copy (claim 24)" [here Claim 34]

Carried from r1 (Claim 26). E2: fails on c69f352f and f7e1bea2 with `want: docs/z2.md: imported`, and passes at HEAD. The base comes from prompt_bases on the copy's absolute path `$h/.claude/wt/.claude/commands/k.md`. Its first `.claude` component yields `$h` (`[[ "$c" != .claude || $n -eq 0 ]] || pb_a+=("${3:0:n-1}")`, lib `:676`), and `$h/z.md` lies below no root.

**Evidence:** `test/scripts/build-loop-check.bats:798-802`; `scripts/lib/dev-cycle-read.sh:670-679`; r1 Appendix A E2

---

## Claim 37: Test title: "a seed that is a dangling link into another worktree reads as the repo path it names (U2b3b2c; U2b3b2b final security F1)"

**Location:** `test/scripts/build-loop-check.bats:804`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the claim that it passes at HEAD and fails on main's lib. It covers config seeds only, since C1 links are covered by test 3.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

Carried from r1 (Claim 27). E2: fails on main's lib with `want: docs/n.md: imported`, and passes on f7e1bea2 onward. r2 adds the assertions `want docs/n.md imported; want docs/r.md imported; want docs/deep.md imported; want docs/other.md -` (`:811`).

**Evidence:** `test/scripts/build-loop-check.bats:804-813`; r1 Appendix A E2

---

## Claim 38: Test title and comment: "both walks fail closed when another worktree's copy cannot be compared with this checkout's (U2b3b2c)"; "The main walk reads main's blob, so only the comparison reads the unreadable checkout file."

**Location:** `test/scripts/build-loop-check.bats:815-819`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the fact that it fails on main's lib and passes at HEAD, and the main walk's read path. It does not establish whether the sha1sum-stub half alone fails on main's lib: the test stops at the chmod half there, and main's C1 also ran sha1sum.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: "in the tree walk the comparison is also what fails first (root_copies runs on `docs/a.md` before it would be read)" · r2: "does not cover a failing realpath, which has no test" · r2: on main's lib the tree half passes because the tree walk fails reading the file itself (E5: `line 1190: docs/a.md: Permission denied tree failed`)

Carried from r3 (Claim 28). On main's lib: `want: walk: failed` / `walk: ok` (appendix R1), from the main walk, which reads `git cat-file blob` for docs/a.md (`lib:1676`). Passes at HEAD (R4).

**Evidence:** `test/scripts/build-loop-check.bats:815-823`; `scripts/lib/dev-cycle-read.sh:1676`, `:1292`; r3 appendix R1, R4; r2 Appendix A E5

---

## Claim 39: Sourcing inventory adds `root_copies prompt_marks config_seeds c1_seeds` and `IMPORT_OTHER`

**Location:** `test/scripts/dev-cycle.bats:1111-1115`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the claim that each listed name exists after sourcing. It does not check that the inventory is complete.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

Carried from r1 (Claim 29). The four functions are defined at lib `:1272`, `:1308`, `:1347` and `:1422`, and `IMPORT_OTHER=""` at `:1075`. The dev-cycle suite passed in full in E1 (r2 and r3: 79/79).

**Evidence:** `test/scripts/dev-cycle.bats:1108-1121`; r1 Appendix A E1

---

## Claim 40: Commit f7e1bea2: "Over /workspace (7 other present roots) both walks give main's 242 names … Suites 284 green"

**Location:** commit f7e1bea2 message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test count at f7e1bea2 (a static count of the six suites) and the name equality, re-run at HEAD on today's registry. It does not re-run f7e1bea2's lib walks (the i2 report did).
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r2: ran f7e1bea2's lib walks today, which gave `242 / 242 / IMPORT_OTHER lines: 7`, identical to main's (r2 E1); r2 did not re-run the 284 count (the i1 report verified it) · r3: "The seed-wording row is already accepted-immutable in the override log"

Carried from r1 (Claim 30a). Counting `@test` per commit over the six suites gives main 281, f7e1bea2 284, 8976fbdf 286, c69f352f 286 and HEAD 287 (E8). E9: HEAD's and main's libs each give 242 distinct non-`//` names per walk, and all four sorted lists are identical. IMPORT_OTHER has 7 lines (E4).

**Evidence:** `git log -1 f7e1bea2`; r1 Appendix A E4, E8, E9; r2 Appendix A E1

---

## Claim 41: Commit f7e1bea2: "the reads add about 0.05 s per walk (tree 1.93 s, main 2.09 s)"

**Location:** commit f7e1bea2 message
**Type:** Performance
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers whether today's measurements fit the figures. It cannot pin a 0.05 s delta, because load noise across runs here (0.5 s) is ten times that.
**Replicate verdicts:** r1=Unverifiable · r2=Verified (compound) · r3=Unverifiable
**Replicate annotations:** r2: "E8 (HEAD's lib, root_copies stubbed against live): +0.06-0.15 s per walk at load 3.1. This is the same order as 'about 0.05 s'" · r3: "the walk-level delta under load was noisier (0.16-0.39 s on the tree walk). To verify, interleave runs on an idle host at f7e1bea2"; "The commit is immutable"

Carried from r1 (Claim 30b). E9 and E4, at load averages of 2.0-2.8: main's lib gave tree 1.74/1.75 s and main 1.93/1.89 s, and HEAD's lib gave tree 1.75-2.28 s and main 2.0-2.68 s. The components measured directly are root_copies' own 65-75 ms plus 4 copies at about 10 ms each, about 0.1 s in all. That is the same order as 0.05 s, and close if "the reads" means only the 4 copy reads (about 0.04 s). An A/B run on an idle machine with many repetitions would settle it.

**Evidence:** `docs/reviews/code-fact-check-report-build-loop-u2b3b2c-final-r1.md` Appendix A E4, E5, E9; `docs/reviews/code-fact-check-report-build-loop-u2b3b2c-final-r2.md` Appendix A E8; `docs/reviews/code-fact-check-report-build-loop-u2b3b2c-final-r3.md` appendix T1-T3

---

## Claim 42: Commit 8976fbdf: "Suites 286/286 …; both walks over /workspace give main's 242 names. 357 changed code lines."; "A8 … outside_seeds split into config_seeds and c1_seeds behind the wrapper; same seeds"; "A2 …: root_copies applies rawfile's test to the copy too"; "A3: the dangling-copy branch is now tested (side lacks the target)"

**Location:** commit 8976fbdf message
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count, the line count, same seeds on /workspace (from the HEAD wrapper, whose seed functions 007e867f did not change), and the A2 and A3 claims. It does not cover the "-j 8" runs, which were not repeated because the review rules forbid them.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: 286 derived as HEAD's 287 minus the one test 007e867f adds; "It does not re-run the suites at 8976fbdf"

Carried from r1 (Claim 31). E8 counts 286 tests at 8976fbdf. `git diff --numstat main...8976fbdf -- ':(top)' ':(top,exclude)docs/' | awk …` prints 357 (r2 E10 and r3 agree). E6: the seeds are the same. A2: `"${rl[n + i]}" == "${cs[i]}"` (lib `:1288`). A3: the test's `rm "$sd/docs/gone.md"; ln -sf gone.md "$sd/docs/b.md"` (bats `:765`), and mutant E7 fails.

**Evidence:** `git log -1 8976fbdf`; `test/scripts/build-loop-check.bats:765`; `scripts/lib/dev-cycle-read.sh:1288`; `docs/reviews/code-fact-check-report-build-loop-u2b3b2c-final-r1.md` Appendix A E6, E7, E8; `docs/reviews/code-fact-check-report-build-loop-u2b3b2c-final-r2.md` Appendix A E10

---

## Claim 43: Commit c69f352f: "the lite check read the moved comment as describing the seed; it describes ROOT_REAL's copy."

**Location:** commit c69f352f message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the claim that the comment names ROOT_REAL's copy, which the next line tests. The later "tree walk" scoping comes from 007e867f (Claim 23).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "It does not verify what the lite check's reader thought" (r2 confidence Medium)

Carried from r1 (Claim 32). `# rawfile, not -f, on ROOT_REAL's copy: …` (lib `:1444`) annotates `rawfile "${ir[i]}"`, a path relative to ROOT_REAL (`:1447`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1444-1447`

---

## Claim 44: Commit 007e867f: "Suites 287/287 (serial); both walks over /workspace give main's 242 names; 377 changed code lines."; "B1: prompt_marks also gives the projected names the link's directory and prompt bases (pext) …"; "B2: a prompt copy is never skipped on equal bytes"

**Location:** commit 007e867f message
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each stated number and the B1 and B2 behaviour at HEAD.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r3: "does not establish that the timings in the shared brief (tree ~1.7 s, main ~1.9 s) hold today. Under load 3.5-3.9 I measured 2.2-2.4 s and 2.4-4.0 s, and the commit itself states no timing" · r2: "It does not cover `-j` runs"

Carried from r1 (Claim 33). E1: `1..287`, 287 `ok`, 0 `not ok`, 0 skips, rc=0. E9: 242 names. The given numstat command prints 377 at HEAD. B1 is checked in Claim 18 and B2 in Claim 15. r2 (E3, E10) and r3 (B1, B2, W1) reproduce 287, 242 and 377.

**Evidence:** `docs/reviews/code-fact-check-report-build-loop-u2b3b2c-final-r1.md` Appendix A E1, E2, E9; `docs/reviews/code-fact-check-report-build-loop-u2b3b2c-final-r2.md` Appendix A E3, E10; `docs/reviews/code-fact-check-report-build-loop-u2b3b2c-final-r3.md` appendix B1, B2, W1

---

## Claims Requiring Attention

### Incorrect
- **Claim 32** (`test/scripts/build-loop-check.bats:767`): "side's prompt differs, so C1 leaves it to the name" gives the wrong cause. C1 skips that prompt whatever its bytes, because this checkout holds a same-kind plain start there. The difference only supplies the `@docs/k2.md` import. Reword without the causal "so". (r3 Incorrect; r1 and r2 Mostly accurate.)

### Stale
- **Claim 13** (`scripts/lib/dev-cycle-read.sh:1176-1179`): import_outside's list of absolute FILEs the walks pass leaves out other roots' copies from root_copies. Add "or another root's copy (root_copies)".
- **Claim 14** (`scripts/lib/dev-cycle-read.sh:1208-1211`): outside_ok's parenthetical leaves out root_copies' copies, which it now also admits. Make the same addition.
- **Claim 30** (`test/scripts/build-loop-check.bats:724`): the C1 test title says C1 skips "one whose bytes match". C1 now skips a non-link start that this checkout holds as a plain start of the same kind, whatever its bytes, and root_copies compares the bytes.

### Mostly Accurate
- **Claim 8** (`scripts/lib/dev-cycle-read.sh:757-762`): the walk header lists only the "lacks or other bytes" reads. It should also say that a prompt copy, or a copy with a link on the way, is read at equal bytes, and that a dangling copy is queued as `//ROOT/NAME`.
- **Claim 16** (`scripts/lib/dev-cycle-read.sh:1266-1267`): the not-covered case is wider than "a dangling linked directory". A copy below a live linked directory whose target lacks the file is skipped the same way, with no projection. Escalated (Escalations, entry 2).
- **Claim 22** (`scripts/lib/dev-cycle-read.sh:1413-1414`): "reads this copy when its bytes differ" leaves out that a prompt copy is always read (since 007e867f). Add "and a prompt's always".
- **Claim 34** (`test/scripts/build-loop-check.bats:777-778`): "A plain copy with equal bytes is skipped … could add nothing" needs the non-prompt qualifier. B2 fixed the code but not this comment.

### Unverifiable
- **Claim 41** (commit f7e1bea2): the "+0.05 s per walk" delta is smaller than this machine's run-to-run noise. The parts measured directly sum to about 0.1 s. Settling it needs interleaved A/B runs on an idle machine.

---

## Escalations

1. **`scripts/lib/dev-cycle-read.sh:1300-1307`** (prompt_marks' "a name already read is not read again as a prompt" named exception; also the walk doc block `:753-757`). Raised by **r1** (Goal-Alignment Escalate). Addressee: **orchestrator**. r1's probe P3 shows a plain layout that hits override row 595's named exception in the main walk. main's AGENTS.md imports `docs/t.md`, and another worktree holds a dangling prompt link whose target is `docs/t.md`. The main walk reads `docs/t.md` plainly in phase 1, before the phase-2 `//` entry marks it, so it misses `top.md` (`top.md: -`), while the tree walk gives `imported`. The comments describe this correctly, but row 595's revisit trigger ("a probe showing a real layout that reaches the plain-read order") may have fired. r3's probe P2 (Claim 7 here) recorded the same main-walk split for a nested link (`sub/top2.md: -`) without escalating it.
2. **`scripts/lib/dev-cycle-read.sh:1266-1267`, `:1280-1281`** (root_copies' "Not covered" sentence; Claim 16). Raised by **r2** (Goal-Alignment Escalate and Out of scope). Addressee: **security-reviewer**, with the named-exception-or-fix decision going to the **orchestrator**. This is a possible fail-open of A5's class: in another worktree, a live linked directory whose target lacks a file main has. outside_proj would project that path, but root_copies skips it, and the comment does not name the case. r2 lists it as out of scope as "whether the wider not-covered case … needs code or only words. The critics own that."
3. **Text-only fixes before merge** (Claims 8, 13, 14, 30, 32, 34 here; r3's Claims 6, 10, 20, 22, 24), with **`test/scripts/build-loop-check.bats:777-778`** singled out. Raised by **r3** (Goal-Alignment Escalate and Questions), and the `:777-778` note by **r2+r3**. Addressee: **orchestrator**. r3: "Whether to fix the five text items before the local merge or carry them as accepted text residue is the orchestrator's call; none changes behaviour." r2 and r3 both note that the i2 rubric's B2 row (i2 claim 16) already called the `:777-778` comment wrong for prompts, and that it was not edited.
4. **Commit f7e1bea2 message** (the "+0.05 s per walk" timing; Claim 41). Raised by **r1+r3** (in claim prose). Addressee: **orchestrator**. An A/B run interleaved on an idle host is needed to settle the figure. r3 notes the commit is immutable.

---

## Verdict stability

- **Total clusters:** 44 (emitted at the finest granularity any replicate used: r2 split root_copies' header into three sub-claims and c1_seeds' header into two, and the imported_names/main_imports comment groups are split where the replicates' groupings cross).
- **Agreed (all reporting replicates gave the same verdict, `(compound)` rows included):** 38. This includes 3 single-replicate clusters (Claims 1, 3 and 11, all r2-only and Verified) and 1 two-replicate cluster (Claim 30, r1+r3 Stale, not surfaced by r2).
- **Disagreed:** 6
  - Claim 8 (`dev-cycle-read.sh:757-762`): r1=Mostly accurate · r2=Verified · r3=Mostly accurate → Mostly accurate
  - Claim 16 (`dev-cycle-read.sh:1266-1267`): r1=Verified (compound) · r2=Mostly accurate · r3=Verified (compound) → Mostly accurate
  - Claim 22 (`dev-cycle-read.sh:1413-1414`): r1=Verified (compound) · r2=Mostly accurate · r3=Verified (compound) → Mostly accurate
  - Claim 32 (`build-loop-check.bats:767`): r1=Mostly accurate · r2=Mostly accurate · r3=Incorrect → Incorrect
  - Claim 34 (`build-loop-check.bats:777-778`): r1=Verified (compound) · r2=Mostly accurate · r3=Mostly accurate → Mostly accurate
  - Claim 41 (commit f7e1bea2, timing): r1=Unverifiable · r2=Verified (compound) · r3=Unverifiable → Unverifiable
- **Agreement rate:** 38/44 = 86.4% (35/41 = 85.4% if the 3 single-replicate clusters are excluded).
- **Per-replicate totals as filed:** r1 34 claims (2 Mostly accurate, 3 Stale, 1 Unverifiable); r2 40 claims (4 Mostly accurate, 2 Stale); r3 34 claims (2 Mostly accurate, 2 Stale, 1 Incorrect, 1 Unverifiable).
- **Note:** Three of the six disagreements (Claims 16, 22, 34) are compound/atomic. The replicate that verdicted the whole construct as Verified had written the same residue into its scope or prose, as a caveat (Claims 22, 34) or as checked evidence (Claim 16), and those caveats appear above in **Replicate annotations**. Claim 32 is a severity disagreement on the same finding: all three replicates found the same wrong cause.
