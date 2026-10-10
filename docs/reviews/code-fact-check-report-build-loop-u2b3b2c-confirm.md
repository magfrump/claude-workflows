Commit: 80a1720d

# Code Fact-Check Report

**Repository:** /workspace (worktree `/workspace/.claude/wt-build-loop-u2b3b2c`, branch `feat/build-loop-u2b3b2c`)
**Scope:** `git diff 007e867f..HEAD` (commits 8da3dfd3 and 80a1720d): `scripts/lib/dev-cycle-read.sh`, `test/scripts/build-loop-check.bats`, `test/scripts/dev-cycle.bats`, the two commit messages, and the override-log rows the range touches or leaves stale. The rest of the branch (main..007e867f) is context only.
**Replication:** k=1 (confirming pass)
**Checked:** 2026-10-09 (executions 2026-10-10T06:45Z-06:52Z UTC)
**Total claims checked:** 41
**Summary:** 30 verified, 8 mostly accurate, 2 stale, 0 incorrect, 1 unverifiable

I read `docs/reviews/hallucination-patterns.md` first. The commit counts (288/288, 242 names, 356/358 lines) belong to its logged "specific measured test count" class, so each was re-run (they hold). No claim matched a logged fabrication pattern. The one removed-symbol finding (Claims 18 and 36: `c1_seeds`, `config_seeds`) is a stale reference to a function this range deleted, not a fabrication, so it does not go in the log. Per the shared brief I wrote only this report.

Execution logs are in `/tmp/claude-1000/-workspace/7b3fc9c7-3eb6-446f-a5f2-81568cdc2745/scratchpad/fcc-u2c/logs/` (cited below as `logs/…`). Appendix A records each run's provenance.

---

## Claim 1: "a prompt's projected names are read as prompts with the link's bases, again when the walk read them before (prompt_marks; one main stores as a symlink fails the main walk, as a symlinked prompt start does)"

**Location:** `scripts/lib/dev-cycle-read.sh:755-757`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what triggers the re-read in both walks. It does not establish that a re-read finds anything new, which the tests in Claim 26a cover.

Both walks queue a re-marked name again when it is in `seen`, not only when it has already been read:

```bash
# scripts/lib/dev-cycle-read.sh:1590
for p in "${rq[@]}"; do [[ "$seen" != *$'\n'"$p"$'\n'* ]] || queue+=("$p"); done
```

The main walk does the same (`:1724`, `[[ -n "${seen[$p]+set}" ]] || continue`). A name that is queued but not yet popped is therefore queued twice and read twice, both times with the new marks. "Again when the walk read them before" leaves that case out. The extra read is harmless and goes through the normal loop, so it is charged to the budgets. The precise wording is "again when the walk has already queued them".

The symlink half holds: the 120000 arm fails when `xs` is non-empty (`:1692`, `[[ ${#xs[@]} -eq 0 ]] || { IMPORTED_MAIN=error; return 1; }`). The prompt-with-bases half was executed. E3: on HEAD, PA, PB and PG each give `imported` in both walks.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1588-1590`, `:1718-1727`, `:1692`; `logs/probe.out` (E3)

---

## Claim 2: "root_copies also reads each other reader root's copy unless reading it could add nothing (its comment: ROOT_REAL lacks it, holds other bytes, a link on either side, or a prompt copy with bases of its own), and projects a copy that is a dangling link or lies below a linked directory"

**Location:** `scripts/lib/dev-cycle-read.sh:758-763`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the four read conditions and the two projection conditions as root_copies codes them. It does not establish that the walks read every queued copy, which is the walk loops' job (Claim 9).

The skip test is `( -z "${rc_p[${ps[i]}]+set}" || -z "${rx[${cr[i]}]+set}" ) && -f "${ps[i]}" && "${rl[i]}" == "$ROOT_REAL/${ps[i]}" && "${rl[n + i]}" == "${cs[i]}"`, followed by the sha1 compare (`:1306`, `:1312`). Any failed conjunct reads the copy:
- `-f` false: ROOT_REAL lacks it.
- A realpath mismatch: a link on either side.
- The rx term: a prompt copy with bases of its own.
- A sha1 mismatch: other bytes.

Projection: `elif [[ -L "$r/$p" ]]; then qs+=("/$r/$p")` (`:1298`), and a missing copy whose realpath differs (`:1308`). A copy that exists below a linked directory is read (realpath mismatch), and import_outside then projects its real path (`:1205`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1294-1313`, `:1205`

---

## Claim 3: "a live prompt link in another root whose target there holds other bytes than the repo path it projects to, which is read plain (final security F3, not a regression; routed to U2c)"

**Location:** `scripts/lib/dev-cycle-read.sh:767-769`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the named exception's layout in both walks on HEAD. It does not establish the "not a regression" history; the override row (`docs/reviews/override-log.md`, final security F3) records that as measured by security.

E7 built this layout: this checkout's `docs/t.md` holds `t: @top.md`, side's `docs/t.md` holds other bytes, and side's `.claude/commands/k.md` is a live link to `../../docs/t.md`. Both walks gave `top.md: -`. With side's bytes equal, both gave `top.md: imported`. The mechanism matches: prompt_marks runs only for a `//` entry (`:1588`, `[[ "$f" != //* || -z "${pdir[$f]+set}" ]] || prompt_marks …`). A live link is read through import_outside and its projected repo name is read without prompt marks.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1588`, `:1200-1207`; `logs/probe2.out` (E7)

---

## Claim 4a: "root_copies adds about 0.2 s per walk over 7 other roots here (interleaved against main's lib, 2026-10-09 …)"

**Location:** `scripts/lib/dev-cycle-read.sh:780-781`
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers today's /workspace registry (7 other roots) at load 1.0-1.4. It does not establish the cost on another registry, which scales with the names reached and the roots.

E5 ran six interleaved rounds of main's lib, HEAD's lib and 007e867f's lib. Medians:

| Walk | main's lib | HEAD's lib | Added |
|---|---|---|---|
| Tree | 1.719 s | 1.847 s | +0.13 s |
| Main | 2.144 s | 2.441 s | +0.30 s |

The two walks average about +0.21 s. E4: `other_roots=7`. The split by walk (0.13 / 0.30) is wider than "about 0.2 s per walk" suggests.

**Evidence:** `logs/timing.log` (E5), `logs/n-head.tree` (E4)

## Claim 4b: "(…: most of it the realpath of every missing copy)"

**Location:** `scripts/lib/dev-cycle-read.sh:781-782`
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the missing-copy realpath's share of the added time on today's registry. It does not establish the shares under other loads.

E6 removed the line `elif [[ ! -e "$r/$p" ]]; then ms+=…` (`:1299`) from a copy of HEAD's lib (`noms`). Over three rounds, root_copies' own time per walk was:

| Walk | HEAD | Without missing copies | Missing copies cost |
|---|---|---|---|
| Tree | 0.130-0.134 s | 0.059-0.060 s | about 0.072 s |
| Main | 0.148-0.158 s | 0.061-0.064 s | about 0.088 s |

That is about 3,878 missing copies over the two walks' 62 calls. The walk lists were identical. Against the measured added time (Claim 4a), the missing-copy realpath is about 55% of the tree walk's +0.13 s but only about 29% of the main walk's +0.30 s. It is the largest single part and most of root_copies' own new cost over 007e867f's lib. It is not most of the 0.2 s overall. The precise version is "the largest part of it the realpath of every missing copy".

**Evidence:** `scripts/lib/dev-cycle-read.sh:1299`, `:1304`; `logs/timing2.log` (E6), `logs/timing.log` (E5)

---

## Claim 5: import_outside's FILE is "an outside_seeds start, which may lie in another root, or another root's copy from root_copies"

**Location:** `scripts/lib/dev-cycle-read.sh:1182-1185`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the walks' absolute queue entries reaching import_file. It does not establish other callers of import_outside outside the walks.

root_copies queues `cs[i]` (absolute `$r/$p`, `:1297`, `:1306`). The walks pass each non-`//` entry to `import_file "$f" …` (`:1586`, `:1686`), which routes an absolute path to `import_outside` (`:1214`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1214`, `:1297-1316`, `:1586`, `:1686`

---

## Claim 6: outside_ok's PATH may be "another root's copy, which root_copies admits"

**Location:** `scripts/lib/dev-cycle-read.sh:1215-1217`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers root_copies' use of outside_ok. It does not establish anything about with_at's use.

`if outside_ok "$r/$p"; then ps+=("$p"); cs+=("$r/$p"); cr+=("$r")` (`:1297`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1220`, `:1297`

---

## Claim 7: root_copies: "Run it after import_readers (IMPORT_OTHER, IMPORT_ROOTS). The array Q is cleared, then, for each NAME (an absolute one or a // name is skipped) not yet a key of the associative array CMP (it then is one) and each IMPORT_OTHER root, gets ROOT/NAME when outside_ok admits it"

**Location:** `scripts/lib/dev-cycle-read.sh:1259-1262`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the globals read, the clearing, the NAME filter and the CMP memo. It does not establish the callers' ordering, which both walks satisfy (`:1553`, `:1628`).

`rc_q=()` (`:1286`); `mapfile -t rs <<<"$IMPORT_OTHER"` (`:1288`); `$'\n'"$IMPORT_ROOTS"$'\n'` (`:1292`); `[[ -n "$p" && "$p" != /* && -z "${rc_c[$p]+set}" ]] || continue; rc_c[$p]=1` (`:1295`). A `//` name starts with `/`, so it is skipped too.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1284-1297`

---

## Claim 8: "unless rawfile's test holds on both sides …, their bytes are equal …, and NAME is no prompt or ROOT lies below no .claude/ component whose parent is not a reader root (only such a parent adds prompt bases ROOT_REAL's copy lacks: i2 fact-check 16, final performance F1)"

**Location:** `scripts/lib/dev-cycle-read.sh:1262-1269`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the rx rule as coded, its case-folding, and a probe of the reader-root-parent case. It does not trace every parser path behind "adds nothing" (IMPORT_DOTNEST handling was not traced).

The rx rule is coded per root:

```bash
# scripts/lib/dev-cycle-read.sh:1290-1293
for r in "${rs[@]}"; do
  IFS=/ read -r -a parts <<<"${r#/}"; p=""
  for c in "${parts[@]}"; do [[ "${c,,}" != .claude || $'\n'"$IMPORT_ROOTS"$'\n' == *$'\n'"${p:-/}"$'\n'* ]] || rx[$r]=1; p+="/$c"; done
done
```

The skip needs `-z rc_p[NAME]` (no prompt) or `-z rx[ROOT]` (`:1306`). The root's own last component counts as well, which is the right reading for a root named `.claude`.

"Only such a parent adds bases" (paraphrased — no quote available because the argument spans prompt_bases (`:670-679`) and the parser's joining rule): a copy at `R/NAME` gets prompt bases `""` plus the parent of each `.claude` component on its whole path (`:676`). Parents inside NAME are `R/<prefix>`, and R is a reader root. Parents inside R are absolute paths. ROOT_REAL's copy gets `""`, which import_targets joins "under every reader root" (`:826`). So the copy adds a base only when some such parent is not a reader root, which is rx.

E3 ("C3-rootparent") added a worktree at `ROOT/.claude/wt`, whose `.claude` parent is ROOT_REAL. On HEAD, root_copies returned no copy of the equal-bytes prompt. On 007e867f it returned `…/.claude/wt/.claude/commands/k.md`. The non-root-parent case still reads: test "a prompt copy with this checkout's bytes is still read" passes on HEAD (E1, E2).

**Evidence:** `scripts/lib/dev-cycle-read.sh:670-679`, `:823-830`, `:1290-1306`; `logs/probe.out` (E3), `logs/red.log` (E2)

---

## Claim 9: "and //ROOT/NAME when it is a link outside_ok rejects (a dangling one) or is missing with a link on the way (a linked directory: final security F2), which the walks project as outside_proj projects a // name"

**Location:** `scripts/lib/dev-cycle-read.sh:1269-1272`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the missing-copy route and the dangling-link route. It does not establish the live-link-to-a-non-regular-file case, which the same `-L` branch also projects (the parenthetical names only the dangling example).

`elif [[ ! -e "$r/$p" ]]; then ms+=("$r/$p")` (`:1299`). After the batched realpath, `[[ "${rl[2 * n + i]}" == "${ms[i]}" ]] || { qs+=("/${ms[i]}"); …; }` (`:1308`). The walks pass a `//` entry to `outside_proj` (`:1585`, `:1685`). E2: the new assertion at `test/scripts/build-loop-check.bats:786` is `real/x.md: -` on 007e867f and `ok` on HEAD.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1298-1308`, `:1585`, `:1685`; `logs/red.log` (E2)

---

## Claim 10: "A copy's mark is taken when NAME is first compared: a name marked later keeps plain copies, which a session in that root loads through its own links, not this one's."

**Location:** `scripts/lib/dev-cycle-read.sh:1275-1277`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the mechanism: the mark is read once, at first compare, and never revisited. It does not establish the session-model rationale ("loads through its own links"), which is design reasoning, not code.

`[[ -z "${rc_p[${qn[i]}]+set}" ]] || rc_p[${qs[i]}]="$(lower …)"` (`:1315`) runs only in the call that first compares NAME, because the CMP memo skips it afterwards (`:1295`). prompt_marks re-queues only the repo name `p` (`:1337`), never its copies.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1295`, `:1315`, `:1337`

---

## Claim 11: "# rx: roots below a .claude/ component whose parent is no reader root (prompt bases of their own)."

**Location:** `scripts/lib/dev-cycle-read.sh:1289`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the loop below it. It does not cover the "below" nuance for a root whose own last component is `.claude`, which the loop also marks (see Claim 8).

See the quote in Claim 8 (`:1290-1293`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1289-1293`

---

## Claim 12a: prompt_marks: "F is a // queue entry the associative array PDIR holds (a dangling prompt link), just projected into the variable OUT. Each repo name in OUT is read as a prompt …: PDIR gets it lower-cased when it lacks it …, and the link's directory and the link's own prompt bases (absolute, newline-separated) are appended to its entry in the associative array PEXT … Each name whose marks changed is appended to the array RQ … It returns 1 when lower fails."

**Location:** `scripts/lib/dev-cycle-read.sh:1319-1328`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the parameters, the PDIR and PEXT updates, the RQ append rule and the return. It does not establish what the walks do with RQ (Claim 12b).

The only callers call it after `outside_proj out work` and only when `f == //*` and `pdir[$f]` is set (`:1588`, `:1718`). `b` is the link's directory plus `pm_b[@]:1` (`:1332`). The no-change skip is `[[ -z "${pm_p[$p]+set}" || $'\n'"${pm_x[$p]-}"$'\n' != *$'\n'"$b"$'\n'* ]] || continue` (`:1335`). PDIR is set only when unset (`:1336`). The append and the RQ entry are `pm_x[$p]="${pm_x[$p]:+${pm_x[$p]}$'\n'}$b"; pm_r+=("$p")` (`:1337`). The only `|| return 1` is on `lower`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1329-1339`, `:1588`, `:1718`

## Claim 12b: "a walk that has already read it reads it again (final security F1: a plain read, or one without these bases)"

**Location:** `scripts/lib/dev-cycle-read.sh:1326-1328`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the walks' trigger for a re-read. It does not establish whether the double read of a queued-but-unread name has any effect beyond cost.

The trigger is `seen`, not "already read" (see Claim 1, `:1590`, `:1724`). A name in `seen` that is still waiting in the queue is queued a second time. The precise version is "a walk that has already queued it queues it again".

**Evidence:** `scripts/lib/dev-cycle-read.sh:1590`, `:1724`

---

## Claim 13: outside_seeds: "a dangling link kept when its real path lies below a reader root (…; a C1 link is kept whatever it names)"

**Location:** `scripts/lib/dev-cycle-read.sh:1349-1351`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers config and top-level seeds and C1 seeds. It does not establish the find -L listing of dangling links (`-type l` under -L), which predates the range.

Config seeds: `[[ -n "$in" || "${rl[i]}" == "${cx[i]}" ]] || for q in "${rs[@]}"; do [[ "${rl[i]}" != "$q"/* ]] || in=1; done` (`:1429`). A dangling link holds no @ (with_at needs outside_ok), so it is kept only via a real path below a root. C1: `isstart "${lo[i]}" && [[ -n "${os_at[${cx[i]}]+set}" || -L "${cx[i]}" ]] || continue` and `[[ ! -L "${cx[i]}" && … ]] && … || os_a+=(…)` (`:1451`, `:1456`). Any link is kept.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1423-1431`, `:1450-1457`

---

## Claim 14: "both walks start at that file and pass it to root_copies, which reads this copy unless reading it could add nothing"

**Location:** `scripts/lib/dev-cycle-read.sh:1360-1362`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the hand-off from C1's skip to root_copies over the starts. It does not re-verify the clean-checkout premise (contract item 2).

`root_copies cq cmp pdir "${queue[@]}"` after the starts and seeds (`:1577`), and `root_copies cq cmp pdir "${queue[@]}" "${tq[@]}"` (`:1675`). E1: the copies test passes; its comment (Claim 22) describes this route.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1456`, `:1577`, `:1675`; `logs/suite-build-loop-check.log` (E1)

---

## Claim 15: "It returns 1 when a find, grep, realpath or lower_all fails, a seed's path holds a newline, or CLAUDE_CONFIG_DIR is set but not absolute."

**Location:** `scripts/lib/dev-cycle-read.sh:1372-1374`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every `return 1` in the body. It does not establish that the python3 plugin reader's failure returns 1 (it does not; it falls back to the cache dirs, `:1403`, which the header's earlier text describes).

The returns are at `:1379`, the finds `:1406`, `:1407`, `:1409`, `:1416`, lower_all `:1417`, `:1447`, with_at (grep) `:1423`, `:1448`, the realpath xargs `:1426`, root_starts (find and grep) `:1439`, and the newline check `:1458`. The sha1sum the f7e1bea2 text listed is gone: no sha1sum call is in the body.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1376-1459`

---

## Claim 16: outside_seeds' body is f7e1bea2's (D1 revert)

**Location:** `scripts/lib/dev-cycle-read.sh:1376-1459`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the body byte for byte, from `outside_seeds() {` to its closing brace. The header differs by the three text edits listed below, which Claims 13-15 verdict.

E8 extracted the function from `git show f7e1bea2:scripts/lib/dev-cycle-read.sh` and from HEAD (84 lines each), and `diff` printed `BODY-EQUAL`. The header diff shows only three edits: the dangling-link rule, the root_copies hand-off and the removed `sha1sum`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1376-1459`; `logs/body-diff.log` (E8)

---

## Claim 17: "# rawfile: a ROOT_REAL copy reached through a link the tree walk does not start at (i1 fact-check 19b)."

**Location:** `scripts/lib/dev-cycle-read.sh:1453`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the tree walk's start admission. It does not establish the main walk's handling of a link start (START_LINK), which differs.

The tree walk admits a start only if `inrepo_here "$f"` (`:1562`), which is `[[ -z "$(blocker "$1" file)" && -f "$1" ]]` (`:191`), and blocker blocks at the first symlink. rawfile is `-f` plus `realpath -e` equal to `$ROOT_REAL/$1` (`:163`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:163`, `:191`, `:1453-1456`, `:1562`

---

## Claim 18: "c1_seeds skips another root's start that has the same kind here only because every start passes through here, pdir already set."

**Location:** `scripts/lib/dev-cycle-read.sh:1575-1576` and `:1673-1674`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers whether the named symbol exists. It does not dispute the sentence's mechanism, which now lives in outside_seeds' C1 part (`:1450-1456`).

This range removed `c1_seeds()` (D1, Claim 16). A grep of HEAD's `scripts/` and `test/` finds `c1_seeds` only in these two comments. f7e1bea2 has neither the function nor these sentences. 8976fbdf added both, and the revert kept the sentences. Rename the subject to "outside_seeds' C1 part".

**Evidence:** `scripts/lib/dev-cycle-read.sh:1574-1576`, `:1672-1674`; `logs/body-diff.log` (E8, f7e1bea2's comment at its `:1506`)

---

## Claim 19: "# A name read before its prompt marks changed is read again with them (final security F1; charged to the budgets)."

**Location:** `scripts/lib/dev-cycle-read.sh:1589`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the tree walk's re-queue and the budget charge. It does not establish that the PA layout reaches the read-before order in this walk (Claim 26b).

`for p in "${rq[@]}"; do [[ "$seen" != *$'\n'"$p"$'\n'* ]] || queue+=("$p"); done` (`:1590`). The condition is "seen", so a queued-but-unread name is queued twice (as in Claim 12b). The re-queued entry goes through the normal pop, so `used` and `work` are charged (`:1586-1587`, `:1592`). E3 (HEAD) shows PB and PG imported in the tree walk; E3 (007e867f) shows both missing.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1581-1592`; `logs/probe.out` (E3)

---

## Claim 20a: "A name read before its prompt marks changed is read again with them, as in imported_names."

**Location:** `scripts/lib/dev-cycle-read.sh:1719-1720`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the main walk's re-queue rule. It does not establish the order of reads within phase 2.

The trigger is `[[ -n "${seen[$p]+set}" ]] || continue` (`:1724`), which is "seen", as in Claim 19. E3: PA, PB and PG are red on 007e867f and green on HEAD in the main walk.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1723-1727`; `logs/probe.out` (E3)

## Claim 20b: "A // entry is only ever popped in phase 2, where queue holds tq's former entries, so the name joins the queue being walked."

**Location:** `scripts/lib/dev-cycle-read.sh:1720-1721`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every site that enqueues a `//` entry in main_imports. It does not cover imported_names, which has one queue.

`//` entries are added only to `tq`: seeds `tq+=("$p")` (`:1670`), and root_copies' results (`:1676`, `:1743`). A `//` import line is stripped to one slash before `tq+=` (`:1735`). Phase 2 swaps `queue=("${tq[@]}"); tq=(); qi=0` (`:1680`). prompt_marks runs only for `//` entries (`:1718`), so `queue+=` at `:1726` appends to the queue being walked.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1667-1680`, `:1718-1743`

## Claim 20c: "A seen name main lacks and main_checkout answers 2 for was never read: skipped."

**Location:** `scripts/lib/dev-cycle-read.sh:1721-1722`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the start and import admission paths. It does not consider a checkout that changes mid-walk (main_checkout's memo makes a repeat answer the same within the walk).

At the starts, `[[ $c -eq 0 ]] || continue` comes before `seen[$f]=1` (`:1660-1661`). For imports, `seen[$p]=1` is set, then `elif [[ $c -eq 0 ]]; then tq+=` (`:1739-1740`), so a 2 is seen but never queued. The re-read loop queues only `c == 0` and fails on `c == 1` (`:1725-1726`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1656-1661`, `:1735-1740`, `:1723-1727`

---

## Claim 21: C1 test title: "skipping one this checkout holds as a plain start of the same kind (root_copies compares the bytes) or that holds no @"

**Location:** `test/scripts/build-loop-check.bats:724`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the parenthetical's mechanism. It does not dispute the skip rule, which the test asserts and E1 passes.

root_copies compares bytes only when the skip conjuncts hold. A copy of a prompt name in an rx root is read without any compare (`:1306`, `( -z rc_p… || -z rx… ) && …`). Precise version: "(root_copies compares the bytes, unless the copy is a prompt with bases of its own)".

**Evidence:** `test/scripts/build-loop-check.bats:724`; `scripts/lib/dev-cycle-read.sh:1306`

---

## Claim 22: "This checkout holds the prompt as a plain start, so C1 leaves side's copy to root_copies, which reads it (its bytes differ): its @docs/k2.md resolves against side's top level only as a prompt."

**Location:** `test/scripts/build-loop-check.bats:767-768`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers this fixture. It does not establish the rx case, which the fixture lacks.

The fixture commits `.claude/commands/k.md` (`:762`). Side's copy differs (`:769`). C1 skips a non-link plain start of the same kind (`scripts/lib/dev-cycle-read.sh:1456`), and root_copies' sha1 compare fails (`:1312`). `docs/k2.md` is asserted imported in both walks, and E1 passes.

**Evidence:** `test/scripts/build-loop-check.bats:761-773`; `logs/suite-build-loop-check.log` (E1)

---

## Claim 23: "(A plain copy of a non-prompt name with equal bytes is skipped as a cost: the parser already resolves this checkout's relative names against every root, so reading it could add nothing.)"

**Location:** `test/scripts/build-loop-check.bats:778-779`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the non-prompt skip, which the first `want real/x.md -` at `:781` asserts. It does not cover prompt names (Claim 8).

`-z "${rc_p[…]+set}"` holds for a non-prompt, so equal bytes skip (`scripts/lib/dev-cycle-read.sh:1306`, `:1312`). E1 passes.

**Evidence:** `test/scripts/build-loop-check.bats:777-786`; `logs/suite-build-loop-check.log` (E1)

---

## Claim 24: "# A copy the linked directory lacks is projected all the same (final security F2)." (new assertion)

**Location:** `test/scripts/build-loop-check.bats:785-786`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers red on 007e867f's lib for the tree walk (the first iteration failed, so the main iteration did not run there), and green on HEAD for both walks. It does not separately establish red for the main walk.

E2 on 007e867f: `not ok 2 … line 786 … want: real/x.md: imported / walk: ok / real/x.md: -`. On HEAD: `ok 2`.

**Evidence:** `test/scripts/build-loop-check.bats:785-786`; `logs/red.log` (E2)

---

## Claim 25: dev-cycle.bats' function list drops config_seeds and c1_seeds

**Location:** `test/scripts/dev-cycle.bats:1111`
**Type:** Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the declare -F list matching the lib's functions. It does not cover other lists.

The list ends `… root_starts with_at root_copies prompt_marks; do`. E1: dev-cycle.bats is `1..79`, 79 ok.

**Evidence:** `test/scripts/dev-cycle.bats:1108-1115`; `logs/suite-dev-cycle.log` (E1)

---

## Claim 26a: New test title and comment: "read again as a prompt when the walk read it before: plain, as a start, or with other bases" / "PB: the target is a start; PG: the target is a prompt here, linked under side's sub/.claude/."

**Location:** `test/scripts/build-loop-check.bats:801-803`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers PB and PG in both walks. It does not cover PA (Claim 26b).

E3 split the three layouts. On 007e867f, PB and PG gave `-` in both walks. On HEAD, both gave `imported` in both walks. PB's `docs/d/CLAUDE.md` is a start (isstart, `scripts/lib/dev-cycle-read.sh:660`), read before any seed. PG's `.claude/commands/x.md` is a prompt here, and side's link sits under `sub/.claude/` (`:806`), whose base `sub` makes `sub/top2.md` reachable.

**Evidence:** `test/scripts/build-loop-check.bats:801-812`; `logs/probe.out` (E3), `logs/red.log` (E2)

## Claim 26b: "PA: AGENTS.md reads docs/t.md plainly first"

**Location:** `test/scripts/build-loop-check.bats:803`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the order of reads per walk for the PA layout alone. It does not dispute that the tree walk's re-read code is exercised (PB exercises it).

The comment holds in the main walk only. In the tree walk, outside_seeds' `//` link seed is queued with the starts (`scripts/lib/dev-cycle-read.sh:1569-1573`), before AGENTS.md's import queues `docs/t.md`. So prompt_marks marks `docs/t.md` before its first read. E3 with PA alone, on 007e867f: tree `top.md: imported`, main `top.md: -`. HEAD gives both imported. The `want top.md imported` assertion is therefore red on 007e867f only in the main iteration. The precise version is "PA: in the main walk, AGENTS.md reads docs/t.md plainly first".

**Evidence:** `scripts/lib/dev-cycle-read.sh:1558-1578`; `logs/probe.out` (E3)

---

## Claim 27: Commit 8da3dfd3: "C1 …: prompt_marks reports each name whose prompt marks changed, and both walks re-read the ones already read (PA plain first, PB a start, PG new bases)."

**Location:** `git log -1 8da3dfd3`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the bullet. It does not cover the other bullets (Claim 28).

Two imprecisions: "the ones already read" is really "the ones already seen" (Claim 12b), and "PA plain first" holds in the main walk only (Claim 26b). The fix itself works: E3 shows all three layouts imported on HEAD in both walks.

**Evidence:** `git log -1 8da3dfd3`; `logs/probe.out` (E3)

---

## Claim 28: Commit 8da3dfd3: C2 "a copy missing below a linked directory in another root is projected (//ROOT/NAME) from the batched realpath -m"; C3 "an equal-bytes prompt copy is skipped unless its root sits below a .claude/ whose parent is no reader root"; C4 "routed to U2c with an override row"

**Location:** `git log -1 8da3dfd3`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three bullets as code, tests and override rows. It does not cover C5 ("text").

C2: see Claim 9 (E2). C3: see Claim 8 (E3). C4: the override-log row "A live prompt link in another root whose target there holds other bytes … Defer (routed to U2c)" was added in 8da3dfd3. E7 confirms the layout.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1299-1308`; `docs/reviews/override-log.md` (8da3dfd3 rows); `logs/red.log`, `logs/probe.out`, `logs/probe2.out`

---

## Claim 29: Commit 8da3dfd3 and override row: "D1: the outside_seeds split is reverted to stay under the cap (417 with it)"

**Location:** `git log -1 8da3dfd3`; `docs/reviews/override-log.md:603`
**Type:** Configuration
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the order of magnitude and the over-cap conclusion. It does not establish the exact 417, which depends on header text the author wrote for a split version that was never committed.

E9 rebuilt that version: HEAD's lib with its outside_seeds region (header and body) replaced by 007e867f's split region. A diff count against main gave 346 lib lines against HEAD's 272. That is about 432 total, over the 400 cap like the stated 417. The exact figure would need the author's uncommitted split text. The row's "356 without" is right for 8da3dfd3; HEAD is 358 (Claim 30).

**Evidence:** `logs/numstat.log` (E10); E9 (Appendix A)

---

## Claim 30: Commit 8da3dfd3: "Suites 288/288 (serial); both walks over /workspace give main's 242 names; +0.2 s per walk interleaved against main's lib; 356 changed code lines."

**Location:** `git log -1 8da3dfd3`
**Type:** Configuration / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each figure at HEAD (and at 8da3dfd3 for the line count). It does not establish the timing beyond today's registry and load.

- E1: the six suites gave `1..132`, `1..20`, `1..79`, `1..2`, `1..2`, `1..53`. That is 288 ok, 0 not ok and 0 skip, all rc=0.
- E4: HEAD's lib, main's lib and 007e867f's lib each gave 242 names in each walk. The sorted lists are identical (`IDENT`).
- E5: about +0.21 s mean (Claim 4a).
- E10: the numstat command gives 356 at `main...8da3dfd3` and 358 at `main...HEAD` (80a1720d is a net +2).

**Evidence:** `logs/suites.summary` (E1), `logs/n-*.tree|main` (E4), `logs/timing.log` (E5), `logs/numstat.log` (E10)

---

## Claim 31: Commit 80a1720d: "the main walk's re-read comment says which queue"; "comment only"

**Location:** `git log -1 80a1720d`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the commit's diff. The new comment's content is verdicted in Claims 20a-20c.

`git show 80a1720d` touches only `scripts/lib/dev-cycle-read.sh` (3 insertions, 1 deletion), all `#` lines at `:1719-1722`.

**Evidence:** `git show 80a1720d`; `scripts/lib/dev-cycle-read.sh:1719-1722`

---

## Claim 32: Header "rawfile's test is batched here (realpath -m with -f): change the two together. The realpaths and the sha1sums run in xargs batches; it returns 1 when one fails or lower does."

**Location:** `scripts/lib/dev-cycle-read.sh:1277-1279`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the batches, which now include the missing copies, and the returns. It does not cover the count-mismatch returns, which the "fails" reading includes.

`nul_list rl xargs -0r -a <(printf '%s\0' "${ps[@]}" "${cs[@]}" "${ms[@]}") realpath -mz -- && [[ ${#rl[@]} -eq $((2 * n + m)) ]] || return 1` (`:1304`); sha1sum at `:1311`; lower at `:1315`. rawfile is at `:163`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:163`, `:1304-1315`

---

## Claim 33: Walk header error list: "outside_seeds, root_copies, prompt_marks, lower, a file read, … fails"

**Location:** `scripts/lib/dev-cycle-read.sh:687-690`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the calls the range added or changed (prompt_marks with RQ, the re-read loop). It does not re-audit the whole list.

The tree walk's re-read loop adds no failing call (`:1590`). prompt_marks' failure still fails the walk (`:1588`). The main walk's re-read can also fail through main_checkout's 1, which the main header's "main_checkout refuses … an import main lacks" covers (`:1612-1613`, `:1726`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1588-1590`, `:1612-1613`, `:1723-1727`

---

## Claim 34: Walk doc block: "Any seed listing find, grep or realpath cannot complete, or a root_copies realpath or sha1sum, fails the walk"

**Location:** `scripts/lib/dev-cycle-read.sh:771-772`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the batched realpath that now includes missing copies. It does not cover a realpath on a missing path, which `-m` does not fail.

The missing copies join the same batch (`:1304`), whose failure returns 1. Both walks then fail (`:1577`, `:1602`, `:1675`, `:1742`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1304`, `:1577`, `:1602`, `:1675`, `:1742`

---

## Claim 35: Test comment "# side lacks all three targets"

**Location:** `test/scripts/build-loop-check.bats:802`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the fixture's ordering. It does not cover other fixtures.

`git worktree add -q --detach ../side` runs before any of `docs/t.md`, `docs/d/CLAUDE.md` or `.claude/commands/x.md` is committed (`:802-805`), so side's three links dangle.

**Evidence:** `test/scripts/build-loop-check.bats:802-806`

---

## Claim 36: Override-log rows keyed to `config_seeds` / `c1_seeds`

**Location:** `docs/reviews/override-log.md` (rows "Commit f7e1bea2 says dangling config seeds are kept … config_seeds' comment states the rule" and "No test drives root_copies' `//ROOT/NAME` entry for a prompt name … Revisit trigger: a change to c1_seeds' link rule")
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers whether the named functions exist at HEAD. It does not ask to rewrite history rows: these are pointers that no longer grep, and one of them is a revisit trigger keyed to a removed function.

Neither `config_seeds` nor `c1_seeds` is defined at HEAD (paraphrased — no quote available because the claim covers absence of code: `grep -n 'config_seeds\|c1_seeds' scripts/lib/dev-cycle-read.sh` hits only the two comments in Claim 18). The new row at `:603` ("The outside_seeds split (i1 A8, config_seeds and c1_seeds) was reverted") names them correctly as history. The rule each older row points to now lives in outside_seeds' header (`scripts/lib/dev-cycle-read.sh:1349-1351`) and its C1 part (`:1450-1456`).

**Evidence:** `docs/reviews/override-log.md:603`; `scripts/lib/dev-cycle-read.sh:1349-1351`, `:1450-1456`

---

## Claims Requiring Attention

### Stale
- **Claim 18** (`scripts/lib/dev-cycle-read.sh:1575`, `:1673`): both walks' comments name `c1_seeds`, which this range removed (D1 revert). Say "outside_seeds' C1 part".
- **Claim 36** (`docs/reviews/override-log.md`): two earlier U2b3b2c rows point at `config_seeds` / `c1_seeds`, one as a revisit trigger ("a change to c1_seeds' link rule"). Re-key the trigger to outside_seeds' C1 link rule.

### Mostly Accurate
- **Claim 1** (`:755-757`), **Claim 12b** (`:1326-1328`), **Claim 19** (`:1589`), **Claim 20a** (`:1719-1720`): the re-read triggers on `seen`, so a queued-but-unread name is also queued again and read twice. "Already read" should be "already queued/seen". This costs a read; it opens nothing.
- **Claim 4b** (`:781-782`): the missing-copy realpath is about 0.07-0.09 s per walk, which is about 55% of the tree walk's +0.13 s and 29% of the main walk's +0.30 s. Say "the largest part", not "most".
- **Claim 21** (`build-loop-check.bats:724`): "(root_copies compares the bytes)" omits that an rx prompt copy is read without a compare.
- **Claim 26b** (`build-loop-check.bats:803`): "PA: AGENTS.md reads docs/t.md plainly first" holds in the main walk only. In the tree walk the seed marks the name before its first read, so PA's assertion is red on 007e867f only in the main iteration.
- **Claim 27** (commit 8da3dfd3): the same two imprecisions ("already read", "PA plain first").

### Unverifiable
- **Claim 29** (commit 8da3dfd3 / override row 603): "417 with it" needs the never-committed split text. A rebuild from 007e867f's split gives about 432, which is still over the cap, so the decision holds.

---

## Appendix A: execution provenance

The scripts are in `/tmp/claude-1000/-workspace/7b3fc9c7-3eb6-446f-a5f2-81568cdc2745/scratchpad/fcc-u2c/`, and the logs are in its `logs/`. Every process ran under `timeout`. The fixture and copy dirs were `mktemp -d /tmp/fcc-u2c-*`, and each was removed by its script; `ls -d /tmp/fcc-u2c*` afterwards matched nothing. No git write ran in /workspace or the review worktree. The walks over /workspace only read. The lib copies were `git show <rev>:scripts/lib/dev-cycle-read.sh` saved as `main.sh`, `f7.sh` and `007.sh`, plus `head.sh` (HEAD's file).

- **E1** (2026-10-10T06:45:04Z-06:46:53Z; cwd the review worktree): `suites.sh` runs `TMPDIR=$(mktemp -d /tmp/fcc-u2c-t-XXXX) timeout 1500 bats <suite>` serially over `test/scripts/build-loop-check.bats`, `build-loop-read.bats`, `dev-cycle.bats`, `fixture-git-env.bats`, `test/fixture-hermeticity.bats` and `test/hermeticity-lint.bats`. All rc=0. ok counts 132/20/79/2/2/53 = 288, 0 not ok, 0 skip. Output: `logs/suites.summary`, `logs/suite-*.log`.
- **E2** (06:45:16Z-06:45:18Z; cwd `/tmp/fcc-u2c-red-6cd0/wt`, a `cp -a` copy with the lib swapped): `timeout 900 bats -f '<the four U2b3b2c copy/C1 test titles>' test/scripts/build-loop-check.bats`. 007e867f's lib gave rc=1 (`not ok` 2 at `:786`, `not ok` 3 at `:810` with `top.md: imported`, `topc.md: -`, `sub/top2.md: -`). HEAD's lib gave rc=0 (4/4 ok). Output: `logs/red.log`.
- **E3** (06:46:04Z-06:46:05Z; cwd a `cp -a` copy under `/tmp/fcc-u2c-pr-*`): `timeout 600 bats test/scripts/zz-probe.bats` (`probe.bats` copied in) per lib. Each layout (PA, PB, PG) ran alone in both walks, and a C3 fixture wrapped root_copies to print Q. Both runs rc=0. Output: `logs/probe.out`.
- **E4** (06:46:31Z-06:46:44Z; cwd `/workspace`): `timeout 300 bash walks.sh <lib> logs/n-<lib>` for head, main and 007. `walks.sh` sources the lib, sets `ROOT_REAL=$(pwd -P)`, runs `resolve_main; reader_settings; imported_names; main_imports`, and writes the sorted non-`//` names. All walks rc=0, 242/242 names each, `other_roots=7` (head, 007). `diff` of head against main (both walks) and of head's tree against head's main printed `IDENT`. Output: `logs/n-*.tree`, `logs/n-*.main`.
- **E5** (06:47:04Z-06:48:46Z; cwd `/workspace`; load 1.05 to 1.42): `bash timing.sh` runs 6 interleaved rounds of main/head/007 walks, then 3 rounds of `RCTIME=1` (root_copies wrapped with `$EPOCHREALTIME`) for head and 007. All rc=0. Output: `logs/timing.log`.
- **E6** (about 06:49Z-06:50Z; cwd `/workspace`): `RCTIME=1 timeout 300 bash walks.sh <lib>` alternating `head.sh` and `noms.sh` (HEAD minus the `! -e` → `ms` line), 3 rounds. Then `cnt.sh` (HEAD plus an `MS/PS` count line) printed `total MS=3878 PS=630 calls=62`. The noms and head tree lists were identical. Output: `logs/timing2.log`.
- **E7** (about 06:51Z; cwd a `cp -a` copy under `/tmp/fcc-u2c-pr-*`): `probe2.sh` ran the C4 "other bytes" and "equal bytes" fixtures on HEAD's lib, rc=0. Output: `logs/probe2.out`.
- **E8** (06:51Z; cwd the review worktree): `bash fcc-u2c-s1.sh` extracts outside_seeds from f7e1bea2 and HEAD and diffs them: `BODY-EQUAL`, 84 lines each. It also diffs the headers; the script's rc=1 is that last header `diff` finding the three edits. Output: `logs/body-diff.log`.
- **E9** (06:51Z; cwd the scratch dir): `python3 -I split.py` built `split-lib.sh` (HEAD with 007e867f's split region). `diff -U3 main.sh <lib> | grep -c` changed lines gave head 272 (equal to numstat's 208+64), split-lib 346 and 007 309. The output was printed, not saved: re-run `split.py` and the same `diff | grep -c` to reproduce.
- **E10** (2026-10-10T06:51:32Z; cwd the review worktree): `git diff --numstat main...HEAD -- ':(top)' ':(top,exclude)docs/' | awk '{n+=$1+$2} END{print n}'` printed 358, and with `main...8da3dfd3` it printed 356. rc=0. Output: `logs/numstat.log`.

---

## Goal-Alignment Note

- **Success criterion (verbatim):** "A markdown report saved to /workspace/.claude/wt-build-loop-u2b3b2c/docs/reviews/code-fact-check-report-build-loop-u2b3b2c-confirm.md, structured per the code-fact-check skill, with `Commit: 80a1720d` as its first line and `**Replication:** k=1 (confirming pass)` in its header."
- **Answered:** Yes. Every claim area the brief named was checked against the code that runs it, and the behavioural ones were executed:
  - root_copies' header, clause by clause, including the rx rule and the mark-timing sentence.
  - prompt_marks' header.
  - Both walks' re-read comments and code.
  - The walk block's rewritten sentences, the C4 exception and the timed cost paragraph.
  - The import_outside, outside_ok and outside_seeds texts, and outside_seeds' body against f7e1bea2.
  - The changed test titles and comments, each new assertion against 007e867f's lib, and both commit messages.
- **The fixes hold:**
  - 288/288, 242 names and 358/356 lines reproduce.
  - The PB, PG and linked-directory assertions are red on 007e867f and green on HEAD. PA's is red only in the main walk.
  - C4 behaves as named.
- **No claim is Incorrect.**
- **Findings (all text):**
  - Two stale names: the `c1_seeds` comments in both walks, and the override-log rows keyed to removed functions.
  - Four places where "already read" should be "already seen", since the re-read also re-queues a queued, unread name. That is harmless.
  - "Most of it" in the cost line should be "the largest part".
  - The PA comment holds for the main walk only.
- **Severity:** Low for all of them. None hides a code path. The tree walk's re-read is still exercised, by PB.
- **Legibility-target tags:**
  - Claims 18 and 36 [for-author]: rename or re-key.
  - Claims 1, 12b, 19, 20a, 4b, 21, 26b [for-author]: wording.
  - Claims 27 and 29 [for-reviewer]: immutable commit message.
- **Out of scope:** Code quality, and whether the double read of a queued name is worth avoiding. Those belong to the critics.
- **Escalate:** Nothing to security. Claim 26b may interest the test-strategy owner: no layout drives the tree walk's re-read for a name first read plain (the PA order). PB covers the same code line through a start.
- **Decisions I made:**
  - I verdicted the "already read" sentences Mostly accurate rather than Incorrect, because the mechanism over-reads, never under-reads.
  - I verdicted "417" Unverifiable rather than Mostly accurate, because the exact text it counts was never committed.
