Commit: 1c820663

# Architecture Review — feat/build-loop-u2b3b2b (U2b3b2b, iteration 1)

**Scope:** `git diff main...HEAD` (1c820663 against 07fe578b): scripts/lib/dev-cycle-read.sh (outside_proj, outside_seeds, MANAGED_DIR, both walks' seed loops, walk header), test/lib/build-loop-fixtures.bash, test/scripts/build-loop-check.bats, test/scripts/dev-cycle.bats, plan paragraph
**Date:** 2026-10-09
**Based on:** shared brief u2b3b2b-i1/shared.md; the code-fact-check runs in parallel this iteration, so it was not available as input.

> **No code fact-check report provided.** Architectural claims in comments and documentation have not been independently verified here beyond the probes named below. For full verification, see this iteration's code-fact-check report.

Scope check: in scope. The diff adds two library functions to the walks' shared surface (`outside_proj`, `outside_seeds`, both now in dev-cycle.bats' sourced-function list), a new module-level variable (`MANAGED_DIR`), and a new input dimension for both walks (the config dirs, ancestors and peer roots). That is a cross-cutting change to the reader model.

Trust-boundary cross-reference: the most recent `docs/reviews/security-review-*.md` by mtime is `security-review-egress-zone-entries-2026-09-19.md`, whose map (egress profiles, SNI) has no boundary in this module, so it does not apply. The review covering this module is `docs/reviews/security-review-2026-10-09-u2b3b2a.md` (Commit: `55490d15`). That review predates this diff, so its boundaries may be stale. Finding 2 cites its `B1`.

## Dependency Map

- `imported_names` (tree walk) and `main_imports` (main walk) → `import_readers` (roots and homes, memoized per decision) → `outside_seeds` (new). `outside_seeds` → `IMPORT_ROOTS`, `IMPORT_HOMES`, `ROOT_REAL`, `$CLAUDE_CONFIG_DIR` (environment), `MANAGED_DIR` (lib global), `isstart`, `PROMPT_DIR`, `lower_all`, `nul_list`, `outside_ok`, and the external tools `find`, `realpath`, `python3`, `sha1sum`.
- Both walks → `import_file` → `import_outside` (absolute paths) → `import_targets` (IMPORT_AWK). Their `//` arms → `outside_ok` → queue (tree) or `tq` (main).
- Both walks → `outside_proj` (new). It runs after `import_work` on every file's output, calls `outside_ok`, and uses `realpath -m` and `import_targets` with IMPORT_WHOLE, the same projection mechanism `import_outside` uses.
- Dependencies point the right way. The new code is a leaf below the walks and above the parser. It adds no new caller into scripts/, and the scripts gain no new dependency on the lib. The new couplings are lateral: outside_seeds' skip depends on how each walk reads ROOT_REAL, and the walks' caches depend on environment state outside their keys.

## Findings

#### 1. The C1 same-bytes skip in the shared seed function encodes a rule that holds for each walk only through a caller contract

**Severity:** Coupling
**Location:** `scripts/lib/dev-cycle-read.sh:1270-1282` (inside `outside_seeds`, 1216-1284)
**Move:** 7 (coupling surface), 2 (responsibility)
**Confidence:** Medium
**Legibility-target:** the outside_seeds header and the walk header's "Named exceptions" sentence

Evidence:
```
    # A C1 start whose bytes equal ROOT_REAL's file at its path below its
    # innermost root yields no name that file does not (the parser joins a
    # repo file's names under every root), and the walks read that file as a
    # start already: compared below, in one sha1sum (most of them, here).
    q=""; [[ $i -lt $nt ]] || for r in "${cr[@]}"; do [[ "${abs[i]}" != "$r"/* || ${#r} -le ${#q} ]] || q="$r"; done
    d="${abs[i]#"$q"/}"  # its path below that root; lower-cased, the same length's tail of lo's
    if [[ -n "$q" && -f "$d" ]] && isstart "${lo[i]:${#lo[i]}-${#d}}" && outside_ok "${abs[i]}"; then sp+=("$c${abs[i]}"); hs+=("${abs[i]}" "${abs[i]#"$q"/}"); else os_a+=("$c${abs[i]}"); fi
```
(the loop continues to 1282, where the sha1sum results decide which `sp` entries join `os_a`.)

The skip compares a peer root's file with the gate checkout's file at the same path, using `-f "$d"` and `sha1sum` against the cwd. Neither walk reads that checkout file as a start in exactly that sense. The main walk reads main's blob for every path main stores. The skip matches main only because build-loop.sh's `checkout_gate` enforces contract item 2, a clean checkout at MAIN_SHA. The tree walk admits a checkout start only through `inrepo_here` (`blocker` plus `-f`), which is stricter than the skip's `-f`. The walk header lists the non-clean checkout as a named exception, so the rule is documented. Structurally, though, one function shared by both walks now holds a third copy of "what the walk reads as a start at this path", in a weaker form than either walk's own admission (`inrepo_here`, or `ent`/`main_checkout`). Its correctness depends on a precondition owned by a different file (build-loop.sh). A later change to either walk's start admission, or to checkout_gate's cleanliness check, can break the skip without touching outside_seeds.

I probed one divergence (a symlinked `CLAUDE.md` in both roots, /tmp/u2b3b2b-arch-*, removed). It is skipped as same-bytes. Neither walk reaches its target from ROOT_REAL either, with or without the side worktree, so this diff opens no new gap there. The coupling is real but not shown to change an answer today.

**Recommendation:** Let each walk decide the skip with its own admission. outside_seeds would return the C1 candidates with their below-root path, and each walk would drop the ones its own start set already holds with equal bytes: `inrepo_here` plus checkout bytes in the tree walk, `ent[$path]` plus main's blob hash in the main walk (`git ls-tree` already gives the blob id, so the main walk would need no sha1sum of the checkout). At minimum, name contract item 2 in the skip's comment as the main walk's precondition.

#### 2. "Outside" now covers files below a reader root: import_outside, outside_ok and B1 serve peer-root starts

**Severity:** Coupling
**Location:** `scripts/lib/dev-cycle-read.sh:1160-1178` (import_outside, import_file, outside_ok contracts), `1392-1396`, `1473-1477` (seed loops)
**Move:** 3 (module boundary)
**Confidence:** High
**Legibility-target:** import_outside's and outside_ok's header comments

Evidence:
```
# import_outside FILE [DIRS...]: import_targets' output for FILE, an absolute
# path (for the walks, one below no reader root: a name from the parser's
# second channel), read
```
```
# outside_ok PATH: whether a walk reads PATH, a name below no reader root: a
```
```
  outside_seeds sd || return 1
  for f in "${sd[@]}"; do
    p="${f:1}"; outside_ok "$p" && [[ "$seen" != *$'\n'"$p"$'\n'* ]] || continue
```

C1 seeds are by definition files below another reader root (for example `$sd/CLAUDE.local.md` in the C1 test). They are queued as absolute paths and read through `import_file` → `import_outside`, whose contract still says "one below no reader root". The parser handles it: an absolute IT_DIR under a root projects relative names back to repo names, as the C1 test shows. But the function contracts and the U2b3b2a security map's `B1` ("outside file named by a // second-channel name", from `security-review-2026-10-09-u2b3b2a.md`, Commit `55490d15`; that review predates this diff, so the boundary may be stale) now understate what flows through. That path also carries files a hostile peer loop writes (the U2b3b2a map's S2 class). A maintainer who tightens `outside_ok` or `import_outside` for "below no root" files, for example by asserting that no root holds the path, would silently break C1.

**Security implication:** none from a structural change, since this finding recommends no restructuring. It does mean `B1`'s source set widened from "// names" to "// names, config-dir seeds and peer-root starts", which security-reviewer should re-map.

**Recommendation:** Update the import_outside and outside_ok headers to "an absolute path: a second-channel name or an outside_seeds start, which may lie below another reader root". Alternatively, rename the concept from "outside" to "absolute". A comment fix is enough.

#### 3. CLAUDE_CONFIG_DIR and MANAGED_DIR feed both walks but sit outside their cache keys and outside contract item 4

**Severity:** Coupling
**Location:** `scripts/lib/dev-cycle-read.sh:1214-1215`, `1221`, `1052`, versus contract item 4 at `64-69` and the cache keys at `1380-1381`, `1435-1436`
**Move:** 7 (coupling surface), 3 (fit with the reader model)
**Confidence:** High
**Legibility-target:** contract item 4

Evidence:
```
# Run it after import_readers. CLAUDE_CONFIG_DIR is read on each call: a caller
# that changes it calls import_reset.
```
```
#  4. Call import_reset before each gate decision and after any checkout
#     change (rows 372, 439), or when IMPORT_OUT_MAX or IMPORT_WORK_MAX
#     changes: neither walk's cache key holds them (both hold import_readers'
#     roots and homes, so HOME and IMPORT_READER_* need no reset; ...
```
```
  [[ "$IMPORTED_DONE" == "$IMPORT_ROOTS"$'\n\n'"$IMPORT_HOMES" ]] && { [[ "$IMPORTED" != error ]]; return; }
```

The reader model is import_readers' roots and homes, memoized on a length-prefixed key, and the walks key their caches on that key. This unit adds a third reader dimension, config dirs: every home's `.claude`, `$CLAUDE_CONFIG_DIR` and `MANAGED_DIR`. It is computed inside `outside_seeds`, outside `import_readers`, and neither walk's key includes it. Contract item 4 is the place a caller reads for reset triggers, and it still lists only the two budgets. The reset rule for CLAUDE_CONFIG_DIR lives only in outside_seeds' header, and MANAGED_DIR's (which a test reassigns) is not stated anywhere. In practice contract item 4 already makes callers reset before each decision, so there is no live bug today. The cost is legibility and drift: the reader model now has two homes, and only one is memoized and keyed. A related point: CLAUDE_CONFIG_DIR is the gate process's own environment, not a reader's. Host readers' config dirs are modeled only as `IMPORT_READER_HOMES`/.claude, not through reader_settings. That is consistent with the named exception for unseen homes, but it is a modeling choice worth stating.

**Recommendation:** Add CLAUDE_CONFIG_DIR and MANAGED_DIR to contract item 4's reset list. Preferably, compute the config-dir list in `import_readers` (as an `IMPORT_CONFIG_DIRS` beside `IMPORT_HOMES`) and add `$CLAUDE_CONFIG_DIR` and `MANAGED_DIR` to `import_readers_key`. The walks' keys would then cover them for free, and the reader model would live in one function.

#### 4. outside_seeds holds three seed sources, a JSON parse and a content-equality dedupe in one 69-line function with index-coupled arrays

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:1216-1284`
**Move:** 2 (responsibility boundaries)
**Confidence:** High
**Legibility-target:** outside_seeds

Evidence:
```
  local -n os_a="$1"; local d q r c i in nt rs=() cf=() tops=() fr=() pr=() mr=() fl=() rl=() cr=() rel=() abs=() lo=() sp=() hs=() pj=(); local -A os_s=()
```
```
  if [[ ${#tops[@]} -gt 0 ]]; then nul_list fl find -H "${tops[@]}" -maxdepth 1 -xtype f -print0 || return 1; rel=("${fl[@]}"); abs=("${fl[@]}"); fi
  nt=${#rel[@]}
```
```
    q=""; [[ $i -lt $nt ]] || for r in "${cr[@]}"; do ...
```
```
    nul_list lo sha1sum -z -- "${hs[@]}" && [[ ${#lo[@]} -eq ${#hs[@]} ]] || return 1
```

The function does four things. It derives config dirs and ancestors (reader model). It lists config-dir contents and reads installed_plugins.json through python3. It lists peer roots from the file system. And it dedupes by content. These share one `rel`/`abs` array pair whose first `nt` entries are top-level files and the rest C1 files, distinguished only by index. They also share one `os_s` map with `a`/`c`/`r` key prefixes, and reuse `fl`, `rl` and `lo` across unrelated phases (`lo` holds lower-cased names, then sha1sum lines). Each source changes for a different reason: Claude Code's config layout, the worktree model, plugin format. Today a change to one means re-reading all 69 lines. The interleaving also forces the `$i -lt $nt` guard, which a reorder of the two listings would silently invalidate. The commit says K5 (seed ordering) has no observable test. Separate producers would at least make each seed list testable on its own, as the C1 test already does for the whole function.

**Recommendation:** Split into `config_dirs` (or fold it into import_readers, per Finding 3), `config_seeds DIRS`, `ancestor_seeds` and `peer_root_seeds` (C1 plus its skip, or the skip moved per Finding 1). Keep `outside_seeds` as a concatenation. Doing this inside the current ~400-line unit budget is optional, but it is the cheapest point to do it, before U2c adds callers.

#### 5. The seed-admission loops and the // arms duplicate one admission rule four times over two `seen` representations

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:1392-1396`, `1410`, `1473-1477`, `1525`; `outside_proj` 1187-1196
**Move:** 7 (coupling), 8 (extension points)
**Confidence:** High
**Legibility-target:** both walks' seed blocks

Evidence:
```
    p="${f:1}"; outside_ok "$p" && [[ "$seen" != *$'\n'"$p"$'\n'* ]] || continue
    seen+="$p"$'\n'; queue+=("$p"); [[ "$f" != p* ]] || pdir[$p]="$p"
```
```
    p="${f:1}"; [[ -z "${seen[$p]+set}" ]] && outside_ok "$p" || continue
    seen[$p]=1; tq+=("$p"); [[ "$f" != p* ]] || pdir[$p]="$p"
```

"An absolute path is walked when outside_ok admits it and it is unseen" now appears in four places: two seed loops and two `//` arms. A fifth and sixth evaluation happens in `outside_proj`, which applies `outside_ok` in its negated form to choose which names to project. Every walk-level rule so far (budgets, the newline refusal, prompt handling) has had to be mirrored by hand between the two walks, and this unit adds one more mirrored pair. The pairs already differ in small ways: the tree walk tests `outside_ok` before `seen` and the main walk tests after; the tree walk keeps a newline-joined string and the main walk an associative array. Both are harmless today. The seeds' `pdir[$p]="$p"` also passes the path as spelled where contract item 8 asks for the lower-cased path as `prompt_bases`' LP. With an upper-case `.CLAUDE` component, which `PROMPT_DIR` matches through `lo`, the spelled LP yields no base for that component.

**Recommendation:** No restructure needed now: the walks' different `seen` types make a shared helper awkward. Two small changes would help. First, pass the lowered path for prompt seeds (`outside_seeds` already has `lo[i]`; carry it as a third field, or lower it in the loop) so `prompt_bases`' contract holds. Second, have the outside_seeds header say the walks admit each seed exactly as a `//` name, so the next edit to the `//` arm knows that both sites must change.

#### 6. outside_proj is a post-filter on each file's output, a second projection site beside import_outside

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:1179-1196`, `1170-1171`, `1403`, `1517`
**Move:** 2, 7
**Confidence:** Medium
**Legibility-target:** outside_proj header

Evidence:
```
  b="$(printf '%s\n' "${df[@]}" | IMPORT_WHOLE=1 IMPORT_WORK_LEFT=$((IMPORT_WORK_MAX - op_t)) import_targets /)" && import_work b op_t || return 1
```
```
  if [[ "$r" != "$1" ]]; then b="$(printf '%s\n' "$r" | IMPORT_WHOLE=1 import_targets /)" && import_work b w || return 1; fi
```

Whole-name projection of a real path now has two call sites with different inputs. import_outside projects an admitted file's `realpath -e`. outside_proj projects rejected names' `realpath -m`, appends the result to OUT and charges the walk's work total. Both walks call outside_proj in one place each, after `import_work`. This composes cleanly: projected names flow through the same `//`/repo arms, and the work accounting stays in the walk's `work`. In the main walk it also runs over output from the 120000 arm, which holds no `//` names, so it is a no-op there. The two sites stay consistent only while IMPORT_WHOLE's contract holds. Batching one `realpath` per file, as outside_proj does, is a sound reason not to fold this into the `//` arm.

**Recommendation:** None required. Optionally, have import_outside's header point to outside_proj (and the reverse) as the two projection sites, so a change to IMPORT_WHOLE handling touches both.

#### 7. The seed set is recomputed per walk, not memoized with the reader model

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:1392`, `1473`; walk header (about 7 s per walk, 1.9 s of it listing other roots)
**Move:** 1, 3
**Confidence:** Medium
**Legibility-target:** walk header's cost sentence

Evidence:
```
# cost: over this repository's 6 registered worktrees, about 140 seed files
# and 7 s per walk, against 0.7 s without (2026-10-09; the file-system
# listing of other roots is about 1.9 s of it).
```

`outside_seeds` depends only on the reader set, ROOT_REAL, the environment and the file system. The walks' own results are already valid for one decision under contract item 4. A gate that asks both walks lists every peer root twice. This is a structural observation; the performance critic owns the cost. If the seed list were memoized beside `IMPORT_READERS_DONE` (reset by `import_reset`), the seed set would become part of the decision snapshot the reader model already defines.

**Recommendation:** Consider memoizing in a later unit, together with Finding 3's move into import_readers.

## What Looks Good

- C1 lists peer roots with `find -P`, never `git -C`. This keeps the lib from executing configuration that a hostile peer loop controls, and the C1 test pins it with a git shim. That is a correct dependency boundary.
- Seeds enter each walk at the phase that matches their provenance: after the checkout's starts in the tree walk, and in phase 2 (`tq`) in the main walk, never main's arms. This preserves the main walk's "main first, then append" invariant.
- `MANAGED_DIR` is a lib-set global rather than an environment read, consistent with how the lib clears IMPORT_READER_* and IMPORT_WHOLE on sourcing. The tests override it explicitly after sourcing.
- Failure stays fail-closed. Every new listing, parse or realpath failure returns 1 through the walks' existing error paths. The one deliberate fallback (an unreadable installed_plugins.json gives the whole cache) widens the walk rather than skipping files.
- Test fixtures isolate the new ambient inputs (`unset CLAUDE_CONFIG_DIR`, a nonexistent MANAGED_DIR) at the fixture level rather than per test.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | C1 same-bytes skip re-derives the walks' start admission and relies on build-loop.sh's clean-checkout contract | Coupling | `scripts/lib/dev-cycle-read.sh:1270-1282` | Medium |
| 2 | "Outside" functions and B1 now serve files below peer reader roots; contracts unchanged | Coupling | `scripts/lib/dev-cycle-read.sh:1160-1178, 1392-1396, 1473-1477` | High |
| 3 | CLAUDE_CONFIG_DIR and MANAGED_DIR feed the walks outside their cache keys and contract item 4; config dirs sit outside import_readers | Coupling | `scripts/lib/dev-cycle-read.sh:1214-1221, 1052, 64-69` | High |
| 4 | outside_seeds bundles three sources, a JSON parse and dedupe, with index-coupled arrays | Minor | `scripts/lib/dev-cycle-read.sh:1216-1284` | High |
| 5 | Seed loops plus // arms repeat one admission rule four times; prompt seeds pass a spelled LP to prompt_bases | Minor | `scripts/lib/dev-cycle-read.sh:1392-1396, 1473-1477` | High |
| 6 | outside_proj is a second whole-name projection site beside import_outside | Informational | `scripts/lib/dev-cycle-read.sh:1179-1196` | Medium |
| 7 | Seed set recomputed per walk rather than memoized with the reader model | Informational | `scripts/lib/dev-cycle-read.sh:1392, 1473` | Medium |

## Overall Assessment

The change keeps the lib's structure intact. It adds a leaf producer below the walks, routes its output through the existing admission and projection paths, keeps dependency direction correct, and stays fail-closed. No finding is Structural. The main concern is where the reader model now lives. Findings 3 and 1 are two sides of it: config dirs and the gate's own environment are a new reader dimension computed outside `import_readers` and outside the walks' cache keys, and the C1 skip puts knowledge of how each walk reads ROOT_REAL into a function both walks share. Both are fixable in place, with a contract item 4 edit at minimum. Moving config dirs into import_readers and the skip into each walk would remove the coupling. Finding 2 is a comment-level contract update that the security reviewer should also see, since B1's source set widened.

## Goal-Alignment Note

The user goal is to land U2b3b2b after a clean review-fix loop, and this report serves that by checking the unit's structure, not its correctness. None of the findings blocks the unit's purpose: both walks still start at the outside instruction files Claude Code loads, and they fail closed. Findings 2, 3 and 5 (the prompt_bases LP) are small edits that fit within this unit. Findings 1 and 4 are restructurings, which could be deferred to U2c through the override log if the ~400-line unit budget is tight. Findings 6 and 7 need no action. I did not verify the walk header's 7 s measurement or the commit's suite counts; those belong to the fact-check.
