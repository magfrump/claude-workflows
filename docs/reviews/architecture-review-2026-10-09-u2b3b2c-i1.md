Commit: f7e1bea2

# Architecture Review — feat/build-loop-u2b3b2c (iteration 1)

**Scope:** `git diff main...HEAD` (main 8e550626, HEAD f7e1bea2): `scripts/lib/dev-cycle-read.sh` (import_readers' IMPORT_OTHER, new root_copies, outside_seeds' C1 and dangling-link seeds, both walks' start pass and per-file loop), `test/scripts/build-loop-check.bats` (three new tests). Read whole: import_readers, import_outside, import_file, outside_ok, outside_proj, with_at, root_copies, outside_seeds, imported_names, main_imports, rawfile, and their doc comments.
**Date:** 2026-10-09
**Based on:** `docs/reviews/code-fact-check-report-build-loop-u2b3b2c-i1.md` (26 claims, 18 Verified); considered override rows 579-589 from the orchestrator's shared brief.

Scope check: in scope. The diff adds a lib function with a nameref interface (root_copies), a new lib global consumed by two functions (IMPORT_OTHER), a new queue-entry kind both walks must handle (`//PATH`), and moves a responsibility (the byte comparison) from outside_seeds to root_copies. Module structure and a cross-cutting concern (the walks feeding the self-merge floor) change.

Trust-boundary cross-reference: active. Latest matching security review is `docs/reviews/security-review-2026-10-09-u2b3b2b.md` (Commit: `1c820663`) — security review predates this diff; boundary may be stale. Its labels B1 (C1 seeds: "isstart + same-bytes skip + outside_ok") and B5 (a seed's text read against "main's blob / ROOT_REAL checkout ..., not the seed's own root") are both changed by this unit.

## Dependency Map

All changes sit in one module, the import-walk section of `scripts/lib/dev-cycle-read.sh`. The layering inside it, top to bottom:

- **Callers**: `isimported` → `imported_names` (tree walk) / `main_imports` (main walk). Each walk owns its queue, its seen set (a newline string in the tree walk, an associative array in the main walk), its prompt map `pdir`, and now a `cmp` memo.
- **Seed and expansion producers** (called by both walks): `outside_seeds` (absolute starts: config dirs, ancestors, C1), new `root_copies` (other roots' copies of repo names), `outside_proj` (projection of rejected `//` names).
- **Readers**: `import_file` → `import_outside` / `import_targets` (the awk parser).
- **Primitives**: `outside_ok`, `rawfile`, `with_at`, `nul_list`, `lower`/`lower_all`, `root_starts`.
- **Registry state**: `import_readers` fills IMPORT_ROOTS / IMPORT_HOMES / IMPORT_DOTNEST and now IMPORT_OTHER; outside_seeds' C1 and root_copies both read IMPORT_OTHER.

Direction is consistent: walks depend on producers, producers on primitives, nothing below depends on a walk. IMPORT_OTHER replaces outside_seeds' private C1 realpath pass with one registry-owned list both consumers read, which removes a duplicate. The one new upward dependency is semantic, not a call: outside_seeds' C1 skip is correct only because the walks call root_copies on their starts (finding 1).

## Findings

#### 1. The C1 skip in outside_seeds is now correct only because both walks call root_copies on their start queues — a three-site invariant documented from one side only

**Severity:** Coupling
**Location:** `scripts/lib/dev-cycle-read.sh:1388`, `:1505-1507`, `:1597-1598`, `:1291-1296`
**Move:** 7 (coupling surface), 3 (module boundary)
**Confidence:** High
**Legibility target:** for-author

**Evidence:**
```
1388:    [[ ! -L "${cx[i]}" && "$q" == "$c" ]] && isstart "$d" && rawfile "${ir[i]}" || os_a+=("$c${cx[i]}")
```
```
1506:  # Other roots' copies of the starts, then of every name the loop reaches (root_copies).
1507:  root_copies cq cmp pdir "${queue[@]}" || return 1
```
```
1597:  # Other roots' copies of the starts, then of every name the loop reaches (root_copies), in phase 2.
1598:  root_copies cq cmp pdir "${queue[@]}" "${tq[@]}" || return 1
```
```
1293:# walks start at that file and root_copies reads this copy when its bytes
1294:# differ (U2b3b2c; given contract item 2's clean checkout, which also keeps
```

Before this unit, outside_seeds' C1 skip was self-contained: it dropped another root's start only after comparing bytes itself. Now it drops every non-link C1 start whose ROOT_REAL counterpart is a same-kind start, and relies on three things it does not control: (a) each walk's start listing holds that ROOT_REAL file, (b) each walk calls root_copies over its whole start set (both `queue` and `tq` in the main walk), and (c) the start's `pdir` entry is present when root_copies runs so the copy is read as a prompt (root_copies copies kind from ROOT_REAL's name, line 1260; outside_seeds' `"$q" == "$c"` makes that equal to the C1 entry's kind). outside_seeds' doc names root_copies, but neither walk's call site says its start-pass call is what makes outside_seeds' skip safe. A future edit that narrows the start pass (for example, calling root_copies only from the per-file loop, which looks equivalent at a glance) silently turns the skip into a fail-open in that walk. The test "both walks read another worktree's copy ..." does pin this today: side's `.claude/commands/k.md` is skipped by C1 and only the start-pass call reads it (k2 imported), for both walks — so the coupling is guarded, but only through one fixture.

**Security implication:** this moves part of B1's crossing ("same-bytes skip", from `docs/reviews/security-review-2026-10-09-u2b3b2b.md`, Commit: `1c820663` — predates this diff; boundary may be stale) out of outside_seeds and into root_copies at the walks' start pass, and extends B5 (a start's text is now also read from the start's own root when its bytes differ). The structural change is sound; the security reviewer should re-draw B1/B5 for this commit rather than inherit the U2b3b2b map.

**Recommendation:** At both start-pass calls (1506, 1597), extend the comment with one clause: "outside_seeds' C1 skip relies on this call over every start, with pdir already set". If the row-582 split lands (finding 3), put the same sentence in the C1 function's doc as its stated precondition. No code change needed.

#### 2. rawfile's predicate is now implemented twice (per-file in rawfile, batched inline in root_copies)

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:160`, `:1266-1268`
**Move:** 7 (coupling surface)
**Confidence:** High
**Legibility target:** for-author

**Evidence:**
```
160:rawfile() { local r; [[ -n "${ROOT_REAL:-}" && -f "$1" ]] && r="$(realpath -e -- "$1" 2>/dev/null)" && [[ "$r" == "$ROOT_REAL/$1" ]]; }
```
```
1266:  nul_list rl realpath -mz -- "${ps[@]}" && [[ ${#rl[@]} -eq ${#ps[@]} ]] || return 1
1267:  for i in "${!ps[@]}"; do
1268:    if [[ -f "${ps[i]}" && "${rl[i]}" == "$ROOT_REAL/${ps[i]}" ]]; then sp+=("${cs[i]}"); hs+=("${cs[i]}" "${ps[i]}"); else rc_q+=("${cs[i]}"); fi
```

root_copies' doc calls this "rawfile's test", and the fact-check executed the equivalence (`-m` plus `-f` equals `-e`), so it is correct today. But the two halves of the same decision now use different copies: outside_seeds' C1 skip calls `rawfile` (line 1388), and root_copies — which must read exactly the copies C1 skipped — uses its own batched version. If rawfile changes (say, to admit a link inside ROOT_REAL, or to reject an unreadable file), C1 starts skipping copies root_copies still treats as "ROOT_REAL lacks it" or the reverse, and nothing ties the two together. Since finding 1 makes these two sites halves of one invariant, a predicate drift between them is the specific failure to prevent.

**Recommendation:** Add a one-line cross-reference in rawfile's comment ("root_copies batches this test; change both"), or extract a `rawfiles OUT NAME...` batch helper that both rawfile and root_copies use. The comment is enough for this unit.

#### 3. Override row 582 fires: outside_seeds should get its minimal split here, not wait for U2c

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:1308-1391`
**Move:** 2 (responsibility boundaries)
**Confidence:** Medium
**Legibility target:** for-orchestrator-synthesis

**Evidence:**
```
1364:  # C1: each other root's start files (IMPORT_OTHER).
1365:  [[ -z "$IMPORT_OTHER" ]] || mapfile -t cr <<<"$IMPORT_OTHER"
1366:  cx=()
```
(the C1 section continues to line 1389, the function to 1391; lines 1311-1363 are the config-dir and ancestor sources)

Row 582's trigger ("U2c or U2b3b2c, whichever edits outside_seeds next") fires on this unit. Two reasons to act now rather than defer again: (a) per plan step 5 (`docs/working/plan-build-loop-handoff.md:309`), U2c is the S rules (Paths parsing, own files, floor, Self-merge never) and has no planned reason to edit outside_seeds, so a trigger keyed to U2c would effectively never fire; (b) this unit changed C1's contract (it now depends on root_copies, finding 1), which is exactly the section a split would isolate. The C1 part and the config part already share no state except reused scratch arrays (`cx`, `fl`, `lo`, `os_at`) that are reset between them; `rs` (IMPORT_ROOTS) is used only by the config part and `cr`/`ir` only by C1. Row 589 (link keep-rule written twice, config vs C1) then resolves to one rule per function, each stated in its own doc.

**Recommendation:** Minimal shape, behaviour-preserving: move lines 1364-1389 into `c1_seeds NAME` (appends `f`/`p`-led entries to NAME; doc = today's item (3) plus the root_copies precondition from finding 1); keep lines 1311-1363 as `config_seeds NAME` (items 1-2); leave `outside_seeds NAME` as a three-line wrapper (`os_a=()`, `config_seeds`, `c1_seeds`, then the newline check at 1390) so neither walk's call site changes. Estimated ~15 changed lines plus moved comment text, keeping the unit well under 400 (205 now). If the author prefers not to move code in a security-sensitive unit, re-key row 582's trigger to something that will actually occur (for example "the next unit that edits C1 or the config seeds"), since U2c will not.

#### 4. `//PATH` as a queue entry is a third, in-band entry kind both walks branch on in several places

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:1502-1504`, `:1514`, `:1593-1595`, `:1607`, `:1257`, `:1262`
**Move:** 8 (extension points), 6 (substitutability of queue entries)
**Confidence:** Medium
**Legibility target:** for-author

**Evidence:**
```
1502:    p="${f:1}"; outside_ok "$p" || { [[ -L "$p" ]] || continue; p="/$p"; }
1503:    [[ "$seen" != *$'\n'"$p"$'\n'* ]] || continue
1504:    seen+="$p"$'\n'; queue+=("$p"); [[ "$f" != p* || "$p" == //* ]] || pdir[$p]="$(lower "$p")" || return 1
```
```
1607:      checkout) if [[ "$f" == //* ]]; then out="$f"  # a dangling link: outside_proj below reads its real path alone
```
```
1262:      elif [[ -L "$r/$p" ]]; then rc_q+=("/$r/$p"); fi
```

Queue entries now come in three kinds told apart by prefix: a repo name, an absolute path (read via import_outside), and `//PATH` (not read; its own text is fed to outside_proj as if it were parser output). The design choice is good reuse — the pseudo-file's "output" is exactly the parser's second-channel format, so outside_proj does the projection and the loop's existing name-enqueue code handles the result, with no new projection path. The cost is that the kind is re-derived by string tests in six places across two walks and root_copies, and the main walk routes `//PATH` to its `checkout` arm only because `ent[//...]` is never set (an implicit rule). This is the established style of the module (the `//` second channel already works this way), so it is not a violation, but each new entry kind multiplies these sites.

**Recommendation:** No change required. Optionally, one comment line at each walk's queue declaration listing the three entry kinds and which arm reads each, so the next reader does not have to rediscover that `//` entries reach the main walk's `checkout` arm through an unset `ent`.

#### 5. Enqueue-after-root_copies is duplicated four times, over two different seen/queue representations

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:1507-1508`, `:1529-1530`, `:1598-1599`, `:1655-1656`
**Move:** 7 (coupling surface)
**Confidence:** High
**Legibility target:** for-author

**Evidence:**
```
1529:    cq=(); root_copies cq cmp pdir "${nm[@]}" || { IMPORTED=error; return 1; }
1530:    for p in "${cq[@]}"; do [[ "$seen" == *$'\n'"$p"$'\n'* ]] || { seen+="$p"$'\n'; queue+=("$p"); }; done
```
```
1655:    cq=(); root_copies cq cmp pdir "${nm[@]}" || { IMPORTED_MAIN=error; return 1; }
1656:    for p in "${cq[@]}"; do [[ -n "${seen[$p]+set}" ]] || { seen[$p]=1; tq+=("$p"); }; done
```

The call and its enqueue loop appear twice per walk (start pass, per-file loop). Folding the enqueue into root_copies would require it to know each walk's seen representation and target queue (tree: `queue`; main: `tq`, phase 2), which is worse coupling than the duplication. Returning copies through `Q` and memoizing through `CMP` keeps root_copies walk-agnostic; the one walk-shaped piece of its interface is PDIR (a second output, written in place), which is the same map shape prompt_dir and the seed loops already write. Drift between the two walks is caught because every new test runs `for w in tree main`. Note that `nm` is collected before the seen check in the main walk (line 1649: `nm+=("$p"); [[ -z "${seen[$p]+set}" ]] || continue`) but before the `-f` check in the tree walk — both correctly hand root_copies every name, including ones this checkout lacks, which is the point of the unit.

**Recommendation:** Accept as is. The placement (name expansion after each file's names are parsed, deduplicated by a walk-owned memo) is the right layer: it is per-name, not per-seed, so it covers chains at any depth without enumerating other roots.

#### 6. The xargs batching rule for path-list forks is applied per call site, and root_copies applies it to one of its two forks

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:1266`, `:1271`, `:1358`
**Move:** 7 (coupling surface)
**Confidence:** Medium
**Legibility target:** for-author

**Evidence:**
```
1266:  nul_list rl realpath -mz -- "${ps[@]}" && [[ ${#rl[@]} -eq ${#ps[@]} ]] || return 1
```
```
1271:  nul_list rl xargs -0r -a <(printf '%s\0' "${hs[@]}") sha1sum -z -- && [[ ${#rl[@]} -eq ${#hs[@]} ]] || return 1
```
```
1357:  # In xargs batches, as with_at reads: config trees can hold any number of files (i2 fact-check 22b).
1358:  rl=(); if [[ ${#cx[@]} -gt 0 ]]; then nul_list rl xargs -0r -a <(printf '%s\0' "${cx[@]}") realpath -mz -- && [[ ${#rl[@]} -eq ${#cx[@]} ]] || return 1; fi
```

The module has a rule (i2 fact-check 22b) that a fork over an unbounded path list goes through xargs, but no helper carries it, so each site decides. root_copies' start-pass call passes (starts × other roots) paths straight to realpath while batching sha1sum. With today's sizes (242 names, 7 roots over /workspace) this is far from ARG_MAX, so it is a consistency observation, not a defect; correctness/perf of the limit belongs to the performance critic.

**Recommendation:** Optionally route line 1266 through the same `xargs -0r -a` form as 1271 for consistency, or later introduce a `nul_xargs OUT CMD...` helper that every batch site uses.

## What Looks Good

- **IMPORT_OTHER in import_readers.** The "other roots, real path, once each, directories only" list is now computed once per decision in the registry reader and consumed by both outside_seeds and root_copies, replacing outside_seeds' private realpath pass. One owner for one fact.
- **Name-driven expansion instead of seeding.** root_copies keys on the names a walk actually reaches (memoized in a walk-owned `cmp`), so cost scales with the import graph rather than with other worktrees' contents (the plan records that seeding every @-bearing file gave 6,720 seeds). This is the right layer for the fix.
- **root_copies is walk-agnostic.** Output by nameref, no knowledge of seen sets, phases or main's blobs; the main walk's "compare with the checkout file" leans on contract item 2, which the header names as a named exception rather than hiding.
- **The `//PATH` pseudo-file reuses outside_proj** instead of adding a second projection path for dangling seeds.
- **The C1 skip got simpler.** Dropping the sha1sum pair from outside_seeds removed a whole batch stage and two arrays; the remaining skip is one predicate line.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | C1 skip depends on both walks' start-pass root_copies call; invariant stated from one side only (B1/B5 relocated) | Coupling | `dev-cycle-read.sh:1388, 1506-1507, 1597-1598` | High |
| 2 | rawfile predicate duplicated (rawfile vs root_copies' batched copy) across the two halves of one decision | Minor | `dev-cycle-read.sh:160, 1266-1268` | High |
| 3 | Row 582 trigger fires; do the minimal outside_seeds → config_seeds + c1_seeds split here, or re-key the trigger (U2c will not edit it) | Minor | `dev-cycle-read.sh:1308-1391` | Medium |
| 4 | `//PATH` is a third in-band queue-entry kind, tested by prefix in six places | Informational | `dev-cycle-read.sh:1502-1504, 1607, 1262` | Medium |
| 5 | Enqueue-after-root_copies duplicated four times; accepted, right layer | Informational | `dev-cycle-read.sh:1529-1530, 1655-1656` | High |
| 6 | xargs batching applied per site; root_copies batches sha1sum but not realpath | Informational | `dev-cycle-read.sh:1266, 1271` | Medium |

## Overall Assessment

The change improves structure: it puts the cross-root copy read at the per-name layer where it covers chains of any depth, gives the "other roots" list a single owner, and shrinks outside_seeds. Nothing is Structural. The one Coupling issue is that outside_seeds' C1 skip has become one half of an invariant whose other half lives at both walks' start-pass calls; it is guarded by a test today and needs only a stated precondition at the call sites (and, if done, in the split-out C1 function's doc). On row 582: its trigger fires here and, because U2c (the S rules) has no planned reason to touch outside_seeds, deferring to U2c means deferring indefinitely; the minimal behaviour-preserving split (config_seeds + c1_seeds behind an unchanged outside_seeds wrapper) costs on the order of 15 changed lines and fits this unit's budget — do it here, or re-key the row explicitly. The security reviewer should redraw B1 and B5, since this unit moves the same-bytes check out of B1's seed producer and into the walks.

## Goal-Alignment Note

- **Success criterion (verbatim):** A markdown report saved to /workspace/.claude/wt-build-loop-u2b3b2c/docs/reviews/architecture-review-2026-10-09-u2b3b2c-i1.md, structured per the architecture-review skill, with `Commit: f7e1bea2` as its first line.
- **Answered:** root_copies' layer (finding 5: right layer, duplication accepted), the `//PATH` pseudo-file (finding 4), the start pass and the C1-skip/root_copies coupling (finding 1), duplicated rules across with_at / outside_proj / root_copies / outside_seeds (findings 2 and 6; admission is a single `outside_ok` everywhere, link handling differs by design per row 589), and row 582 (finding 3: split here, with shape).
- **Out of scope:** correctness of the fail-open/fail-closed behaviour (security), fork counts (performance), stale comments the fact-check already filed (lib :45, :759-760, :1304 sha1sum mentions; test comments :765, :774-775), the dev-cycle.bats sourcing inventory escalation.
- **Escalate:** the U2b3b2b security review's Trust Boundary Map (B1, B5) is stale for this commit; the security critic should redraw it.
- **Decisions:** whether to do the row-582 split in this unit or re-key its trigger (finding 3) is the orchestrator's/author's call; this review recommends the split here.
