Commit: 007e867f

# API Consistency Review — feat/build-loop-u2b3b2c (final confirming pass)

**Scope:** `git diff main...HEAD` (main 8e550626, HEAD 007e867f): scripts/lib/dev-cycle-read.sh (header contract items 1-9, the walk doc block, import_readers, root_copies, prompt_marks, outside_seeds, config_seeds, c1_seeds, with_at, outside_proj, import_outside, imported_names, main_imports, rawfile), test/scripts/build-loop-check.bats (U2b3b2c tests), the sourcing inventory in test/scripts/dev-cycle.bats
**Date:** 2026-10-09
**Based on:** the orchestrator's shared brief (Stage 1 fact-check replicates r1-r3 at 007e867f), and docs/reviews/api-consistency-review-2026-10-09-u2b3b2c-i1.md

## Baseline Conventions

Unchanged from i1 (that report's Baseline section): output name-ref first, then inputs, bound as `local -n xx_a="$1"` with a per-function two-letter prefix; "array NAME gets ..." means the function clears NAME first (with_at :1244, outside_seeds :1326, prompt_bases :672); "MAP[PATH] gets LP" for a keyed write into a caller's map (prompt_dir :661-664); "the variable OUT" for a scalar in/out, and "appended to OUT" when a function appends (outside_proj :1217); return codes 0/1 documented as "It returns 1 when ...", every walk treating 1 as a failed walk with `IMPORTED[_MAIN]=error`; `IMPORT_*` globals cleared at source time and at the top of import_readers, named in contract item 9 when a caller must never set them; "Run it after import_readers" on a reader of import_readers' results; the inventory test lists each new lib helper and global as it lands.

## i1 findings: status

| i1 | Finding | Status at 007e867f |
|---|---|---|
| F1 | Inventory omits root_copies, IMPORT_OTHER | **Fixed.** dev-cycle.bats:1111 adds `root_copies prompt_marks config_seeds c1_seeds`; :1115 adds `IMPORT_OTHER`. |
| F2 | Item 9 omits IMPORT_OTHER; root_copies lacks "Run it after import_readers" | **Fixed in the contract** (lib :96-98 names IMPORT_ROOTS, IMPORT_HOMES, IMPORT_DOTNEST and IMPORT_OTHER and says a cache hit does not recompute them). The "Run it after" line is on outside_seeds only; see N3. |
| F3 | root_copies appends to Q | **Fixed.** `rc_q=()` at :1274 and the doc says "The array Q is cleared"; the call sites' `cq=()` are gone (:1609 area, :1700 area per the diff). CMP and PDIR are now documented as in/out ("it then is one", "is added to it"). |
| F4 | Docs credit outside_seeds with sha1sum; main_imports' doc misses //PATH and root_copies | **Fixed.** Inputs paragraph :42-46 routes sha1sum through root_copies; the walk block :766-767 lists "a root_copies realpath or sha1sum"; imported_names' and main_imports' failure lists add outside_seeds, root_copies, prompt_marks; main_imports' phase-2 comment names "outside seeds, // imports and other roots' copies, and //PATH entries". |
| F5 | IMPORT_OTHER partial on refusal | Override row (u2b3b2c, "IMPORT_OTHER partial on refusal and its name"); not re-filed. |
| F6 | IMPORT_OTHER lacks a noun | Same override row; not re-filed. |

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `root_copies Q CMP PDIR NAME...` | function | `with_at NAME PATH...`, `prompt_bases NAME LP PATH`, `outside_proj OUT TOTAL` | `scripts/lib/dev-cycle-read.sh:1221,1241,670` | Consistent: outputs by name first, variadic inputs last, `rc_` prefix, Q cleared as "gets" implies, 0/1 with a "returns 1 when" list. |
| `prompt_marks PDIR PEXT OUT F` | function | `prompt_dir MAP LP PATH`, `outside_proj OUT TOTAL`, `import_work OUT TOTAL` | `scripts/lib/dev-cycle-read.sh:664,1221,1454` | Consistent in order (maps and the variable OUT by name, then the value F), `pm_` prefix, "returns 1 when lower fails" (prompt_bases cannot fail). PEXT's write is an append, documented as "gets" (N2). |
| `config_seeds NAME` | function | `outside_seeds NAME`, `with_at NAME PATH...` | `scripts/lib/dev-cycle-read.sh:1324,1241` | Consistent: clears `cs_a`, "returns 1 when" list matches the body (find, grep via with_at, realpath, lower_all, CLAUDE_CONFIG_DIR; python3 failure falls back, so it is rightly absent). |
| `c1_seeds NAME` | function | `outside_seeds NAME`, `root_starts ROOT` | `scripts/lib/dev-cycle-read.sh:1324,1235` | Consistent: clears `c1_a`; "returns 1 when a find, grep or lower_all fails" matches (root_starts, with_at, lower_all; its realpath and sha1sum moved to import_readers and root_copies). `c1_` prefix breaks the two-letter pattern only by a digit, which the name carries. |
| `IMPORT_OTHER` | global | `IMPORT_ROOTS`, `IMPORT_DOTNEST`, `IMPORT_READER_ROOTS` | `scripts/lib/dev-cycle-read.sh:1075` | Consistent in reset, format and memo; now in item 9 and the inventory. Name: override row. |
| queue entry `//PATH`; maps `pdir`, `cmp`, `pext` | walk-internal convention | parser-output `//PATH`; `pdir`, `pok` | `scripts/lib/dev-cycle-read.sh:1590-1610,1640-1720` | Consistent and identical in both walks: `//PATH` is a parser-output line, so `out="$f"` hands it to outside_proj unchanged; `pdir`/`pext`/`cmp` are declared `local -A` in both walks and keyed alike (pdir by queue entry, pext by repo name). |

Name-ref collisions: none. root_copies' locals (`p r i n rs ps cs rl hs sp qs qn`), prompt_marks' (`p l b pm_b`), config_seeds' and c1_seeds' do not shadow the names their callers pass (`cq cmp pdir pext out`, `os_a`, `os_c`). outside_seeds passes its own name-ref `os_a` to config_seeds, which binds `cs_a` to it; config_seeds declares no `os_a`, so the chain resolves to the caller's array (confirmed by the suites' seed tests, per the fact-check).

## Findings

#### N1. The named exception "a name already read is not read again as a prompt" is reachable from a plain layout, and the planned fix must also cover a target already read as a prompt (PEXT growth)

**Severity:** Inconsistent
**Location:** `scripts/lib/dev-cycle-read.sh:1306-1316` (prompt_marks), `:755-757` (walk block), callers at imported_names' and main_imports' `outside_proj out work && { ... prompt_marks pdir pext out "$f"; }`
**Move:** 3 (consumer contract), 7 (asymmetry between the two walks)
**Confidence:** High (both cases reproduced)
**Legibility target:** for-author

**Evidence:**
```
prompt_marks() {
  local -n pm_p="$1" pm_x="$2" pm_o="$3"; local p l="${4#/}" b pm_b=()
  prompt_bases pm_b "${pm_p[$4]#/}" "$l"
  printf -v b '%s\n' "${l%/*}" "${pm_b[@]:1}"; b="${b%$'\n'}"
  while IFS= read -r p; do
    [[ -n "$p" && "$p" != /* ]] || continue
    [[ -n "${pm_p[$p]+set}" ]] || pm_p[$p]="$(lower "$p")" || return 1
    pm_x[$p]="${pm_x[$p]:+${pm_x[$p]}$'\n'}$b"
  done < <(printf '%s\n' "$pm_o")
}
```
```
# not read again as a prompt: a named exception. It returns 1 when lower fails.
```

The walks' contract (the gate's floor) is that a missed import is a fail-open; the exception was justified as rare. Two probes on a copy of the worktree (bats, `imps` harness):

- **P1 (the escalation, confirmed):** AGENTS.md imports docs/t.md (`t: @top.md`); another worktree holds a dangling `.claude/commands/k.md -> ../../docs/t.md`. Tree walk: `top.md: imported`; main walk: `top.md: -`. The main walk reads docs/t.md plain in phase 1, before the seed's phase-2 projection marks it. The two walks disagree on the same layout, which nothing in the contract names.
- **P2 (beyond the escalation):** this checkout holds the prompt start `.claude/commands/x.md` (`x: @top2.md`) and `sub/top2.md`; another worktree lacks x.md and holds `sub/.claude/commands/k.md -> ../../../.claude/commands/x.md` (dangling). Both walks: `sub/top2.md: -`. This is the same model as the passing test "a dangling prompt link in another worktree reads its target as a prompt" (nested link, `sub/top2.md imported`), except that the target was already read, as a start, with pdir already set.

On the fix shape the orchestrator proposed ("re-queue an already-read name when prompt_marks marks it"): it is sufficient for P1 only if "marks" includes P2's case. In P2 `pm_p[$p]` is already set, so the only change prompt_marks makes is appending the link's bases to `pm_x[$p]`. A re-queue keyed on "pdir newly set" leaves P2 missed. The trigger should be "pdir newly set, or pext gained a base it did not hold", and the re-queue must bypass `seen` (a set in main_imports, a string in imported_names) for that name only. In main_imports, a re-queued name goes to `queue` when `ent` holds it and to `tq` otherwise, as the loop already does; a phase-2 append to `queue` is processed in phase 2, as now. No loop risk: prompt_marks runs only for `//` entries, which `seen` admits once. A secondary point, low impact: CMP memoizes root_copies by name only, so other roots' copies of a name first reached plain were judged as plain (equal-bytes copies skipped, none added to PDIR). Under the reader model that is not a miss, since a dangling link's prompt kind belongs to the link's own root, whose copy is the missing one; it only means a re-queued name should not expect root_copies to re-run for it.

**Recommendation:** Re-queue the name when prompt_marks sets a new pdir key or appends a base not already in `pext[$p]` (have prompt_marks report the names it changed, e.g. through an array name-ref cleared first, matching the "array NAME gets" convention). Add P1 and P2 as tests for both walks, and drop the named exception from prompt_marks' doc and the walk block (:755-757) and its override row.

#### N2. prompt_marks' doc says PEXT "gets" the bases, but the code appends them

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:1300-1306`
**Move:** 2 (naming/wording against the grain), 3 (doc drift)
**Confidence:** High
**Legibility target:** for-author

Precedent: "gets" means replace (`prompt_dir`: "MAP[PATH] gets LP", `scripts/lib/dev-cycle-read.sh:661-664`); "appended to" for an append (`outside_proj`, `:1217`)

**Evidence:**
```
# PDIR gets it lower-cased (its own prompt bases), and the associative array
# PEXT gets the link's directory and the link's own prompt bases (absolute,
# newline-separated), which the walks add to its DIRS (U2b3b2c i1 security F1,
```
```
    pm_x[$p]="${pm_x[$p]:+${pm_x[$p]}$'\n'}$b"
```

PDIR's write is "gets" only when unset (`|| pm_p[$p]=...`), and PEXT's is an append. A second dangling link to the same target accumulates bases, which is the intended behaviour, but the doc reads as a replace. The opening clause is also hard to parse ("after F, a // queue entry the associative array PDIR holds (a dangling prompt link), is projected, each repo name ..."): the comma before "is projected" splits subject from verb.

**Recommendation:** "PDIR gets it lower-cased unless it holds it, and PEXT[it] has the link's directory and prompt bases appended (newline-separated)". Rephrase the first clause: "once F, a // queue entry PDIR holds (a dangling prompt link), is projected into OUT, each repo name in OUT is read as a prompt".

#### N3. "Run it after import_readers" is on outside_seeds but not on root_copies, config_seeds or c1_seeds, which read its results

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:1248-1271`, `:1332-1346`, `:1404-1421`
**Move:** 3 (documentation)
**Confidence:** High
**Legibility target:** for-author

**Evidence:**
```
# too): config_seeds', then c1_seeds'. It returns 1 when either does, or a
# seed's path holds a newline. Run it after import_readers (IMPORT_ROOTS,
# IMPORT_HOMES and IMPORT_OTHER).
```
```
# does not. The array Q is cleared, then, for each NAME (an absolute one or a
# // name is skipped) not yet a key of the associative array CMP (it then is
# one) and each IMPORT_OTHER root, gets ROOT/NAME when outside_ok admits it,
```

i1 F2's second half. root_copies is called directly by both walks; before import_readers it sees an empty IMPORT_OTHER and returns 0 with Q empty (silently reading nothing, not failing). config_seeds and c1_seeds are reached only through outside_seeds, so the gap there is cosmetic. Contract item 9 now covers the "never set these" half.

**Recommendation:** Add "Run it after import_readers (IMPORT_OTHER)." to root_copies' doc; optionally the same to config_seeds (IMPORT_ROOTS, IMPORT_HOMES) and c1_seeds (IMPORT_OTHER).

#### N4. Stale or overstated doc lines the fact-check found, from the consumer side

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:1176-1178`, `:1208-1211`, `:757-762`, `:1413-1414`; `test/scripts/build-loop-check.bats:724,767,777-778`
**Move:** 3 (documentation and test drift)
**Confidence:** High (fact-check r1-r3)
**Legibility target:** for-author

**Evidence:**
```
# path (for the walks, a name from the parser's second channel, below no
# reader root, or an outside_seeds start, which may lie in another root), read
```
```
# start at that file and pass it to root_copies, which reads this copy when
# its bytes differ (U2b3b2c; given contract item 2's clean checkout, which
```
```
    # side's prompt differs, so C1 leaves it to the name: its @docs/k2.md resolves against side's top level only as a prompt.
```

import_outside and outside_ok each enumerate the absolute names a walk passes them, and root_copies' `ROOT/NAME` copies are now a third kind; a reader of either contract would not know the walks hand them another root's repo file. c1_seeds says root_copies reads the copy "when its bytes differ", but a prompt copy is always read (root_copies :1259) and so is one with a link on either side; the walk block's "lacks or holds with other bytes" has the same gap. The bats comment at :767 states a cause C1 does not apply (C1 skips that start whatever its bytes), and :724's title still says C1 skips "one whose bytes match".

**Recommendation:** Add "or a root_copies copy" to import_outside's and outside_ok's lists; say "reads this copy unless it is a plain non-prompt file with equal bytes" in c1_seeds and the walk block; fix the two test texts. Comment-only.

## What Looks Good

- All four i1 Minor findings are fixed as recommended, including option (a) for F3 (reset Q in root_copies, call sites no longer compensate).
- The outside_seeds split keeps the public signature and semantics (`outside_seeds NAME`, cleared, `f`/`p`-led absolute paths, same newline check); the fact-check found the same 9 seeds before and after. Both halves follow the sibling contract (clear, name-ref, "returns 1 when").
- prompt_marks and root_copies take their walk state (PDIR, PEXT, CMP) by name instead of reading globals, so both walks share one implementation with identical call shapes; the `//PATH` entry reuses the parser's own line format, so the walks' `out="$f"` path needs no new projection code.
- The sourcing inventory now lists every new function and IMPORT_OTHER, so a rename fails the sourcing test.
- Contract item 9 now names every import_readers result and states why (a cache hit does not recompute them).

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| N1 | Already-read prompt target not re-read: walks disagree (P1) and both miss a nested link's bases on a prompt start (P2); fix must trigger on PEXT growth too | Inconsistent | `scripts/lib/dev-cycle-read.sh:1306-1316,755-757` | High |
| N2 | prompt_marks' "PEXT gets" is an append; first clause hard to parse | Minor | `scripts/lib/dev-cycle-read.sh:1300-1306` | High |
| N4 | import_outside/outside_ok lists omit root_copies' copies; c1_seeds/walk block overstate the byte rule; two test texts | Minor | `scripts/lib/dev-cycle-read.sh:1176-1178,1208-1211,757-762,1413-1414`; bats :724,767,777-778 | High |
| N3 | "Run it after import_readers" missing on root_copies (and the split halves) | Informational | `scripts/lib/dev-cycle-read.sh:1248-1271,1332-1346,1404-1421` | High |

## Overall Assessment

The branch is consistent with the lib's conventions: the new signatures order and bind their arguments as their siblings do, clear their array outputs, document their in/out maps, list their failure causes accurately, and avoid name-ref collisions; the inventory and contract item 9 now track the new surface. i1's F1-F4 are fixed. The one substantive item is N1: the named exception for an already-read prompt target is reached by ordinary layouts, makes the two walks disagree on one of them, and the planned re-queue fix needs a broader trigger (any new pdir key or new pext base) to close P2 as well as P1. N2-N4 are comment and test-text fixes. Nothing changes the walks' or the gate's external interface for build-loop.sh or dev-cycle.sh.

## Goal-Alignment Note

- **Success criterion (verbatim):** "A markdown report saved to /workspace/.claude/wt-build-loop-u2b3b2c/docs/reviews/api-consistency-review-2026-10-09-u2b3b2c-final.md, structured per the api-consistency-reviewer skill, with `Commit: 007e867f` as its first line."
- **Answered:** Final confirming API-consistency pass over the full branch. i1 F1-F4 confirmed fixed (F2's "Run it after" half residual as N3); new signatures audited against siblings (name-refs, clearing, return codes, "returns 1 when" lists, local-name collisions: none); `//PATH`, pdir/pext/cmp conventions consistent across both walks; inventory complete; the escalated exception assessed and reproduced, with a second case (P2) the proposed fix shape would miss. 1 Inconsistent, 2 Minor, 1 Informational.
- **Out of scope:** Security severity of N1 as a fail-open (security critic); per-copy cost (override row); override rows 579-589 and the u2b3b2c rows were not re-filed except the "already read" exception, whose basis the escalation and P2 change.
- **Escalate:** N1 to the orchestrator: widen the planned re-queue trigger to include a new base in `pext[$p]`, and add P2 (target is a prompt start in this checkout; another worktree holds a dangling `sub/.claude/commands/k.md` to it; expect `sub/top2.md imported` in both walks) alongside P1.
- **Decisions:** Scored N1 Inconsistent rather than Minor because the two walks disagree on P1 and the doc names the gap as an exception rather than a defect.
