Commit: 007e867f

# Architecture Review — feat/build-loop-u2b3b2c (final confirming pass)

**Scope:** `git diff main...HEAD` (main 8e550626, HEAD 007e867f; f7e1bea2, 8976fbdf, c69f352f, 007e867f): `scripts/lib/dev-cycle-read.sh` (import_readers' IMPORT_OTHER, root_copies, prompt_marks, outside_seeds → config_seeds + c1_seeds, both walks' seed loops, start pass, per-file loop and `//` arm), `test/scripts/build-loop-check.bats` (U2b3b2c tests and the C1 test), `test/scripts/dev-cycle.bats` (inventory). Read whole: import_readers, root_copies, prompt_marks, outside_seeds, config_seeds, c1_seeds, with_at, outside_ok, outside_proj, import_outside, import_file, prompt_dir, prompt_bases, rawfile, main_checkout, imported_names, main_imports, and the walk doc block (:730-787).
**Date:** 2026-10-09
**Based on:** the orchestrator's shared brief (fact-check Stage 1, k=3 at 007e867f: no behavioural Incorrect; replicates `code-fact-check-report-build-loop-u2b3b2c-final-r{1,2,3}.md`), considered override rows for u2b3b2b and u2b3b2c, and my i1 report (`architecture-review-2026-10-09-u2b3b2c-i1.md`).

Scope check: in scope (module structure: outside_seeds split into two functions; a new lib function and a second walk-owned map, `pext`; a cross-cutting concern: both walks feed the self-merge floor).

Trust-boundary cross-reference: active. Latest matching security review is `docs/reviews/security-review-2026-10-09-u2b3b2c-i1.md` (Commit: `f7e1bea2`) — security review predates this diff; boundary may be stale. Finding 1 sits on its `B2` ("dangling link in another root or a config dir → seed loop / root_copies // branch → outside_proj realpath -m → projected repo names").

## Confirmation of i1 items 1-3

| i1 | Recommendation | Status at 007e867f | Evidence |
|---|---|---|---|
| 1 | State at both start-pass calls (and in the C1 function's doc) that C1's skip relies on root_copies over every start with pdir set | Done | `:1564-1566` "c1_seeds skips another root's start that has the same kind / here only because every start passes through here, pdir already set."; `:1660-1662` the same in main_imports; c1_seeds' doc `:1412-1414` "both walks / start at that file and pass it to root_copies, which reads this copy when / its bytes differ" |
| 2 | Tie rawfile and root_copies' batched copy of its test together | Done | `:162` "# root_copies batches the same test: change the two together."; root_copies' doc: "rawfile's test is batched here (realpath -m with -f): change the two together." |
| 3 | Minimal split of outside_seeds | Done, behaviour-preserving (fact-check: same 9 seeds before and after) | `:1324-1331` wrapper (`config_seeds os_a`, `c1_seeds os_c`, append, newline check); `config_seeds` `:1347`, `c1_seeds` `:1422`, each with its own locals and doc |

i1 item 6 (realpath not batched in root_copies) is also resolved: `:1285-1286` now batches both realpath lists through `xargs -0r -a`. Items 4 and 5 were accepted (5 as override row 598).

The split's boundaries are right: config_seeds reads only IMPORT_ROOTS/IMPORT_HOMES and the config trees; c1_seeds reads only IMPORT_OTHER and the other roots' trees; the wrapper owns only the newline check over the combined list. The one cross-function precondition (C1's skip vs the walks' start pass) is now stated on both sides. The link keep-rule differs by function (config: "real path differs and lies below a reader root"; C1: any link), each stated in its own doc, which settles row 589 as the brief says.

## Dependency Map

Unchanged in direction from i1: walks (`imported_names`, `main_imports`) → producers (`outside_seeds` → `config_seeds`, `c1_seeds`; `root_copies`; `outside_proj`; new `prompt_marks`) → readers (`import_file` → `import_outside` / `import_targets`) → primitives (`outside_ok`, `rawfile`, `with_at`, `nul_list`, `lower`, `prompt_bases`) → registry state (`import_readers`: IMPORT_ROOTS, IMPORT_HOMES, IMPORT_DOTNEST, IMPORT_OTHER). Nothing below a walk calls up into one.

What changed since i1 is the prompt-kind state. "This queue entry is read as a prompt, against these extra directories" is now held in two walk-owned maps and written from four functions:

| Writer | Map | Site | When |
|---|---|---|---|
| prompt_dir | pdir | `:1554`, `:1647` | a checkout or main start under PROMPT_DIR, at enqueue |
| walks' seed loops | pdir | `:1562`, `:1658` | a `p`-led seed (incl. its `//PATH` form), at enqueue |
| root_copies | pdir | `:1296` | a copy (or `//` copy) of a NAME pdir holds *at the time root_copies first sees NAME* (CMP memo) |
| prompt_marks | pdir, pext | `:1314-1315` | each repo name a `//` prompt entry projects, *when that entry is popped* |

Readers: both walks' bases computation (`:1572-1573`, `:1669-1670`), the walks' prompt_marks guard (`:1578`, `:1706`), root_copies' always-read rule (`:1288`) and its inheritance (`:1296`), prompt_marks' own bases (`:1310`).

So the rule has one store (pdir, plus pext for the link's bases) but no single owner, and the first three writers decide kind at enqueue while the fourth decides it later, after the name may already have been read or memoized. Finding 1 is the consequence.

## Findings

#### 1. Prompt kind can grow after a name is read, but every consumer treats it as fixed at first sight; the escalated miss is one instance, and it reaches both walks and bases growth, not only plain names

**Severity:** Coupling
**Location:** `scripts/lib/dev-cycle-read.sh:1308-1317` (prompt_marks), `:1578`, `:1706` (callers), `:1572-1573`, `:1669-1670` (bases read once per pop), `:1296` (root_copies' kind inheritance under the CMP memo)
**Move:** 7 (coupling surface: temporal coupling between producers and the walk's seen set), 2 (responsibility: who owns an entry's kind)
**Confidence:** High (walk behaviour, probed); Medium (fix-shape sufficiency conditions, by reading)
**Legibility target:** for-orchestrator-synthesis
**Boundary:** `B2` from `docs/reviews/security-review-2026-10-09-u2b3b2c-i1.md` (Commit: `f7e1bea2`) — security review predates this diff; boundary may be stale.

**Evidence:**
```
1308:prompt_marks() {
1309:  local -n pm_p="$1" pm_x="$2" pm_o="$3"; local p l="${4#/}" b pm_b=()
1310:  prompt_bases pm_b "${pm_p[$4]#/}" "$l"
1311:  printf -v b '%s\n' "${l%/*}" "${pm_b[@]:1}"; b="${b%$'\n'}"
1312:  while IFS= read -r p; do
1313:    [[ -n "$p" && "$p" != /* ]] || continue
1314:    [[ -n "${pm_p[$p]+set}" ]] || pm_p[$p]="$(lower "$p")" || return 1
1315:    pm_x[$p]="${pm_x[$p]:+${pm_x[$p]}$'\n'}$b"
1316:  done < <(printf '%s\n' "$pm_o")
1317:}
```
```
1572:    f="${queue[qi]}"; qi=$((qi + 1)); xs=(); [[ -z "${pdir[$f]+set}" ]] || prompt_bases xs "${pdir[$f]}" "$f"
1573:    [[ -z "${pext[$f]+set}" ]] || mapfile -t -O "${#xs[@]}" xs <<<"${pext[$f]}"  # a dangling prompt link's bases (prompt_marks)
```
```
1578:    outside_proj out work && { [[ "$f" != //* || -z "${pdir[$f]+set}" ]] || prompt_marks pdir pext out "$f"; } || { IMPORTED=error; return 1; }
```
(the per-file loop continues to `:1592`: the enqueue loop at `:1584-1589` skips any `p` already in `seen`, then root_copies and its enqueue at `:1590-1591`; main_imports' counterpart is `:1706-1722`, whose enqueue sets `seen[$p]=1` at `:1718` even when it does not queue `p`)

prompt_marks writes pdir/pext for a name, but the walk reads those maps only when it pops the name (`:1572-1573`). If the name was popped earlier, the new kind and bases are never used. The doc calls this a named exception (`:1307` "A name already read is / not read again as a prompt"). Probes in a scratch copy of the worktree (bats, helpers `imps`/`want`; removed afterwards) show it is broader than the escalated main-walk case:

| Layout (side = another registered worktree, at the first commit) | tree | main |
|---|---|---|
| `AGENTS.md` imports `docs/t.md` (`t: @top2.md`); side's `.claude/commands/j.md` → `../../docs/t.md` (dangling) — the escalated case | top2.md imported | **top2.md -** |
| `docs/CLAUDE.md` (`c: @top.md`) is a checkout start; side's `.claude/commands/k.md` → `../../docs/CLAUDE.md` (dangling) | **top.md -** | **top.md -** |
| `.claude/commands/x.md` (`x: @top3.md`) is a checkout prompt start; side's `sub/.claude/commands/k.md` → `../../../.claude/commands/x.md` (dangling) | **sub/top3.md -** | **sub/top3.md -** |
| control: same nested link to `docs/x2.md`, which nothing else reads | sub/top3.md imported | sub/top3.md imported |

So (a) the tree walk is not immune: it misses whenever the projected name is a start (starts are queued before seeds), and in general whenever the projected name is popped before the `//` entry (a `//` copy root_copies finds in the per-file loop is queued late in either walk); (b) the miss is not only "plain read first": a name already read *as a prompt* that gains the link's own bases through pext (row 3) is missed the same way, because prompt_marks always appends to pext but nothing re-reads. These are fail-opens on the self-merge floor; their correctness weight belongs to security, the structural cause is here: kind is mutable state with a late writer, and the walk has no "attributes changed" path.

**Is re-queueing an already-read name when prompt_marks marks it the right layer?** Yes, with conditions. Up-front marking cannot replace it: `//` entries are discovered late (root_copies' `//` copies in the per-file loop), so the walk must be a monotone worklist where an entry is revisited when its read inputs (pdir, pext) grow. The re-queue belongs in the walks (they own `seen` and the queues), with prompt_marks reporting what changed; it is not prompt_marks' job to know either walk's queue. For the fix to be sufficient:

1. **Trigger on growth, not on "newly marked".** prompt_marks should report every name whose pdir was set *or whose pext gained a line* (row 3 above has pdir already set). Re-queueing only names `:1314` newly marks leaves row 3 open.
2. **Both walks.** Row 2 fails the tree walk too; a main-walk-only fix leaves the tree walk order-dependent.
3. **Re-queue only names the walk actually admitted.** In main_imports `seen` is not "queued": `:1718` sets `seen[$p]=1` for a name main lacks and main_checkout answers 2 for (nothing loads there), and that name is never queued. Re-queueing it on `seen` alone sends it to the `checkout` arm (`${ent[$f]-checkout}`) and import_file on an absent path, which fails the walk (fail-closed, but over-refusal). The re-queue should test "queued before" (ent set, or c=0 recorded), or re-run the same admission (`ent` / main_checkout / `-f` + inrepo_here) the first enqueue ran. In the tree walk `seen` equals queued, so `seen` suffices there.
4. **Main walk target queue.** `//` entries are popped in phase 2, so a re-queued main name goes to `tq` (or the live `queue` once phase 2 has swapped); the `ent` arm then reads main's blob with the new `xs`, and a `120000` entry with non-empty `xs` fails closed at `:1680` as the doc's existing named exception says.
5. **Termination and budget.** Each `//` entry is popped once (it is in `seen`), so each name is re-queued at most once per dangling prompt link; re-reads charge IMPORT_OUT_MAX/WORK_MAX again, which is acceptable and should be stated.
6. **root_copies' memo.** `:1296` gives a copy prompt kind only if NAME was in pdir when root_copies first saw it (CMP). A name marked later keeps its copies plain (an equal-bytes copy skipped), one marked earlier gets them read as prompts. Since a dangling link loads none of those copies (its target root lacks the file), this is a superset difference, not a miss, so the fix need not clear `cmp[NAME]`; but say so in root_copies' doc ("a NAME prompt_marks marks after its copies were taken keeps them plain"), or stop inheriting prompt_marks' marks there, so copy kind is not silently order-dependent.

**Recommendation:** Give prompt_marks a fourth output, an array of the names whose pdir or pext it changed; in each walk, re-queue those that were already popped and were admitted (condition 3), bypassing the `seen` test; drop the "named exception" text at `:756` and `:1307`, and add the probe rows 1-3 (both walks) as tests that fail on 007e867f. Document condition 6.

#### 2. An entry's read-time directories are computed from two maps, merged identically in both walks

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:1572-1573`, `:1669-1670`, `:1310-1311`
**Move:** 7 (coupling surface), 2 (responsibility boundaries)
**Confidence:** High
**Legibility target:** for-author

**Evidence:**
```
1669:    f="${queue[qi]}"; qi=$((qi + 1)); xs=(); [[ -z "${pdir[$f]+set}" ]] || prompt_bases xs "${pdir[$f]}" "$f"
1670:    [[ -z "${pext[$f]+set}" ]] || mapfile -t -O "${#xs[@]}" xs <<<"${pext[$f]}"  # a dangling prompt link's bases (prompt_marks)
```

pdir's value is "the lower-cased path prompt_bases derives bases from" (the repo name for a start, the absolute path for a copy or seed, the repo name for a projected target); pext's is "absolute bases from a link". The walk merges the two in two identical lines, duplicated in each walk. Finding 1's fix will touch exactly this pair (growth of either map must trigger a re-read), so the rule "an entry's directories = prompt_bases(pdir) + pext" is now load-bearing in four places (two walks' merges, prompt_marks' growth report, the re-queue test). A small `entry_dirs XS F` helper (or prompt_marks precomputing into one map) would put it in one place.

**Recommendation:** Extract `entry_dirs` used by both walks when landing finding 1's fix; optional otherwise.

#### 3. Walk-shaped duplication grows by one pair per mechanism

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:1556-1563` / `:1655-1659` (seed loops), `:1575-1578` / `:1671-1706` (`//` arm and prompt_marks call), `:1572-1573` / `:1669-1670` (bases merge)
**Move:** 7 (coupling surface)
**Confidence:** High
**Legibility target:** for-author

**Evidence:**
```
1560:    p="${f:1}"; outside_ok "$p" || { [[ -L "$p" ]] || continue; p="/$p"; }
1561:    [[ "$seen" != *$'\n'"$p"$'\n'* ]] || continue
1562:    seen+="$p"$'\n'; queue+=("$p"); [[ "$f" != p* ]] || pdir[$p]="$(lower "$p")" || return 1
```
```
1656:    p="${f:1}"; outside_ok "$p" || { [[ -L "$p" ]] || continue; p="/$p"; }
1657:    [[ -z "${seen[$p]+set}" ]] || continue
1658:    seen[$p]=1; tq+=("$p"); [[ "$f" != p* ]] || pdir[$p]="$(lower "$p")" || return 1
```

Beyond the four root_copies enqueue loops (override row 598, not re-filed), this unit adds three more walk pairs: the seed-to-`//PATH` admission, the `//` read arm, and the prompt_marks call line; finding 1's fix will add a fourth (re-queue). Each pair differs only in the seen representation (newline string vs associative array) and the target queue. Every U2b3b2c test runs `for w in tree main`, so drift is caught today; probe row 2 of finding 1 shows how the walks' different queue orders already make the same rule behave differently. The pieces that do not touch `seen` (seed classification `p`/`f`/`//`, the bases merge) could move into walk-agnostic helpers without the coupling cost row 598 rejected.

**Recommendation:** No change required for this unit. When finding 1's fix lands, keep the walk-agnostic parts (which names changed; their directories) in helpers and leave only enqueue in the walks, consistent with row 598's reasoning.

## What Looks Good

- **The split (i1 item 3) is clean.** Each seed source is now a function with its own inputs, locals and failure list; the wrapper's only job is the combined newline check; call sites did not change; the fact-check confirmed identical seeds before and after.
- **The C1/root_copies precondition is stated on both sides** (c1_seeds' doc and both start-pass comments), so the cross-function invariant from i1 item 1 is now discoverable from either end, and the test pins it per walk.
- **`//PATH` projection of a dangling prompt link reuses outside_proj**, and prompt_marks is a narrow, walk-agnostic function (maps by nameref, no queue knowledge): the right shape to extend with a "changed names" output.
- **root_copies stays walk-agnostic** after i2's prompt rule (`:1288`: a prompt copy is always read), and its realpath is now batched like its sha1sum.
- **IMPORT_OTHER has one owner** (import_readers) and is named in the header's never-set list.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Prompt kind/bases grow after a name is read (prompt_marks), but each walk reads them once per pop; misses in both walks, for plain and already-prompt names. Re-queue is the right layer if it triggers on pdir or pext growth, runs in both walks, re-queues only admitted names (main's `seen` ≠ queued), and root_copies' memoized copy kind is documented | Coupling | `dev-cycle-read.sh:1308-1317, 1572-1578, 1669-1706, 1296` | High (behaviour, probed) / Medium (fix conditions) |
| 2 | Entry directories = prompt_bases(pdir) + pext, merged identically in both walks; extract with finding 1's fix | Minor | `dev-cycle-read.sh:1572-1573, 1669-1670` | High |
| 3 | Walk-pair duplication grows (seed admission, `//` arm, prompt_marks call; re-queue next) | Informational | `dev-cycle-read.sh:1560-1562, 1656-1658` | High |

## Overall Assessment

i1 items 1-3 are done as recommended, and item 6 too; the split's boundaries are correct and behaviour-preserving, and the start-pass precondition is stated on both sides. The one structural concern left is the prompt-kind state: one store (pdir + pext) with four writers, three of which decide at enqueue and one (prompt_marks) later, while the walks read the store once per pop. That temporal coupling is what produces the escalated miss, and probing shows its reach is wider than the brief's case: the tree walk misses when the projected name is a start, and both walks miss when a name already read as a prompt gains the link's bases. Re-queueing in the walks is the right layer, since late `//` discovery makes up-front marking impossible; the fix is sufficient only if it fires on pext growth as well as new marks, covers both walks, and in main_imports re-queues only names that were actually admitted (main's `seen` also holds names it declined to queue). Nothing here is Structural; the fix fits in place.

## Goal-Alignment Note

- **Success criterion (verbatim):** A markdown report saved to /workspace/.claude/wt-build-loop-u2b3b2c/docs/reviews/architecture-review-2026-10-09-u2b3b2c-final.md, structured per the architecture-review skill, with `Commit: 007e867f` as its first line.
- **Answered:** i1 items 1-3 confirmed (table above; item 6 also resolved); whether "a name is read as a prompt" lives in one place (one store, four writers, two maps, finding 1 and 2); the escalated plain-read-order defect assessed as a finding, with the re-queue fix judged the right layer and its six sufficiency conditions (finding 1); the split's boundaries (confirmed sound); remaining duplication between the walks (finding 3, row 598 not re-filed).
- **Out of scope:** fail-open severity of finding 1's misses (security); re-read cost (performance); the stale and mostly-accurate comments the fact-check already filed (bats :724, :767, :777-778; lib :757-762, :1176-1178, :1208-1211, :1266-1267, :1413-1414).
- **Escalate:** finding 1's probe rows 2 and 3 widen the escalated defect beyond the brief's case (tree walk, and bases growth on an already-prompt name) — to the orchestrator and security before the fix is written, so the fix and its tests cover them. The security review's B2 (Commit `f7e1bea2`) predates prompt_marks and should be redrawn.
- **Decisions:** whether root_copies should keep inheriting prompt_marks' marks (order-dependent superset) or stop (finding 1, condition 6) is the author's call; either is safe if documented.
