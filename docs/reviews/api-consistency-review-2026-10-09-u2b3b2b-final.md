Commit: 8f99fcaf

# API Consistency Review — feat/build-loop-u2b3b2b (U2b3b2b, final confirming pass)

**Scope:** `git diff main...HEAD -- scripts test` at 8f99fcaf (the whole branch), plus the plan's U2b3b2b/U2b3b2c bullets. The surface is `scripts/lib/dev-cycle-read.sh`: `outside_seeds`, `outside_proj`, `root_starts`, `with_at`, the global `IMPORT_MANAGED_DIR`, the caller contract (items 4, 8, 9), the Inputs paragraph and the walk header. Also the sourcing inventory in `test/scripts/dev-cycle.bats`.
**Date:** 2026-10-09
**Based on:** shared brief `u2b3b2b-final/shared.md`; merged fact-check `code-fact-check-report-build-loop-u2b3b2b-final.md` (k=3); my earlier reports `api-consistency-review-2026-10-09-u2b3b2b.md` (i1) and `-i2.md`; the rubric and the eight override rows dated 2026-10-09 for this branch (settled unless their basis changed; none changed). Probes used the prefix `/tmp/u2b3b2b-fapi-`, and every one was removed.

## Iteration-2 findings marked Fixed: verification

| i2 finding | Rubric | Verdict |
|---|---|---|
| F1: the @ filter accepted grep status 2, against the fail-closed text (B1) | Fixed | **Fixed.** `with_at` (`:1219-1224`) now runs `grep -lZF -e @ -- "$@"; [ $? -le 1 ]`, with no `-s`, after an `outside_ok` prefilter. A status 2 makes `sh` exit 1, xargs exit 123, and `nul_list` returns 1. The walk header (`:754`, "Any seed listing find, grep or sha1sum cannot complete fails the walk") and `outside_seeds`' return-1 list now describe the code. The test's grep shim that exits 2 fails both walks. |
| F2: an early `return 0` skipped the newline check (B4) | Fixed | **Fixed (probed).** There is no early return now. With a single repo and `$HOME/.claude/rules/a\nb.md` holding `@x`, `outside_seeds a` returns `rc=1`. At 39f64d62 it returned `rc=0`. The partial array (`n=1`) is K7, which is settled. |
| F3: `root_starts` was missing from the inventory | Fixed | **Fixed.** `dev-cycle.bats:1111` lists `outside_proj outside_seeds root_starts with_at`, and the variable loop checks `IMPORT_MANAGED_DIR`. |
| F4: `root_starts`' header did not say its output is absolute | Fixed | **Fixed.** `:1210-1211` now reads "as absolute paths, NUL-separated". |
| F5: `IMPORT_MANAGED_DIR` lacked the reset line | Fixed | **Fixed.** `:1062`: "A caller that changes it calls import_reset (contract item 4)". This matches `IMPORT_OUT_MAX` and `IMPORT_WORK_MAX`. |
| F6: plan sentences were misplaced | Fixed | **Fixed in part.** The CLAUDE_CONFIG_DIR sentences, the relative-path refusal and the rename now sit in U2b3b2b's paragraph (`plan-build-loop-handoff.md:306`). Iteration 2's changes are still absent from the plan; see F3 below and fact-check Claim 1. |

## Baseline Conventions

These are unchanged from i1 and i2:
- Signatures take a nameref NAME with a two-letter prefix (`nl_a`, `pd_m`, `pb_a`, `iw_o`, `mc_e`). The function's other locals are not always prefixed: `prompt_bases` has `c n parts` and `main_checkout` has `c i st anc`, while `import_work` prefixes `iw_w`.
- NUL producers write to stdout and are read through `nul_list`.
- Return 1 means a failed walk, and each header lists its return-1 conditions.
- Walk-input globals take the `IMPORT_` prefix, are assigned at source time, and carry a reset line.
- Each unit adds its new lib functions to the `declare -F` inventory.
- The listing error rule: a listing that cannot complete fails the walk. Only `outside_ok`'s case, a file that is not a readable regular file, is a skip.

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `outside_seeds NAME` | function (fills array) | `prompt_bases NAME ...`, `nul_list NAME CMD`, `tree_starts` | `scripts/lib/dev-cycle-read.sh:664, 1367, 1384` | Consistent: a nameref-first, noun-named filler sharing the `outside_` family with `outside_ok`. Its header has one stale clause (F1). |
| `outside_proj OUT TOTAL` | function | `import_work OUT TOTAL` | `scripts/lib/dev-cycle-read.sh:1349` | Consistent: the same two-nameref signature and the same IMPORT_WORK_MAX accounting. |
| `root_starts ROOT` | function (NUL producer) | `tree_starts`, `untracked_md`, `checkout_md` | `scripts/lib/dev-cycle-read.sh:1363-1384` | Consistent: the same `local -; set -o pipefail; ... \| instruction_names` shape. Its header now names the absolute output. |
| `with_at NAME PATH...` | function (filter into array) | `nul_list NAME CMD`, `instruction_names` (a stdin filter), `outside_ok` | `scripts/lib/dev-cycle-read.sh:1367, 1360, 1190` | Acceptable. It is the first array-filling filter named by a phrase rather than a noun (`*_names`, `*_list`, `*_starts`), but it is private to `outside_seeds` and documented. Not a finding. |
| `IMPORT_MANAGED_DIR` | global | `IMPORT_OUT_MAX`, `IMPORT_WORK_MAX`, `IMPORT_WHOLE` | `scripts/lib/dev-cycle-read.sh:773, 793, 1059` | Consistent (prefix, source-time assignment, reset line). |
| seed tags `f` / `p` | output field | `main_imports`' `m:`/`t:` records | `scripts/lib/dev-cycle-read.sh` (main_imports) | Settled by an override row (K7 Won't-Fix). Not re-raised. |

## Findings

#### F1 — The C1 clause in outside_seeds' header still says isstart reads "its path below its innermost root"; the code reads the whole path, and the byte-skip sentence promises a start the walks may not make

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:1237-1238` (C1 clause), `:1242-1245` (byte-skip justification); code at `:1324-1327` and `:1337`
**Move:** 3 (documentation drift in a function contract)
**Confidence:** High (fact-check Claims 19 Stale, 12 Mostly accurate and 21 Incorrect, executed there; I re-read the code and did not re-execute)
**Legibility-target:** for-author: outside_seeds' header (C1 clause and the byte-skip sentence)

Evidence (header):
```
# dir. (3) C1: every start file (isstart, by its path below its innermost
# root) in another reader root present here, tracked or not (a superset). A
...
# it twice, which the walks' seen absorbs). One whose bytes equal ROOT_REAL's
# plain file (rawfile) at that path is skipped: the parser joins that file's
# names under every root and the walks start there too (given contract item
```
Evidence (code, the comment above the loop, `:1324-1327`, and the skip, `:1336-1337`):
```
  # isstart (the authority, after instruction_names' prefilter) and the prompt
  # test read the whole path, so a start below any root holding it counts (a
  # superset: i2 fact-check, a worktree nested in a .claude/skills/); the byte
  # comparison takes the path below its innermost root.
...
    # isstart on the inner path's tail of lo: ROOT_REAL's copy must be a start there too.
    if [[ ! -L "${cx[i]}" ]] && isstart "${lo[i]:${#lo[i]}-${#ir[i]}}" && rawfile "${ir[i]}" && outside_ok "${cx[i]}"; then sp+=("$c${cx[i]}"); hs+=("${cx[i]}" "${ir[i]}"); else os_a+=("$c${cx[i]}"); fi
```
(Excerpt ends inside the loop. The remainder, `:1338-1343`, hashes `hs` and keeps each `sp` entry whose sha1 differs, then runs the newline check.)

B3 changed the start test to read the whole path, but the header clause was not updated. The inline comment is current, so the function now documents two rules. The byte-skip sentence adds a contract a reader would rely on: "the walks start there too". The skip only checks that ROOT_REAL's copy is a start at the inner path. It does not check that it is the same kind of start (f vs p) as the seed's whole-path class. In fact-check Claim 21's nested-worktree layout, ROOT_REAL's copy is a plain `f` start where the seed was a `p`, so the prompt bases are lost. Both walks then miss an import that a one-byte change would surface. That behaviour gap is the security reviewer's to tier. The API point is that the header's justification overstates what the condition guarantees, and it omits the non-link and inner-start conditions (Claim 12).

**Recommendation:** Change the C1 clause to "isstart and the prompt test on the whole lower-cased path". Then either restate the skip's condition exactly (not a link, ROOT_REAL's copy a start at the inner path *of the same class*) and add the class test, or name the class mismatch as an exception next to the U2b3b2c one.

#### F2 — The walk header's "an unreadable directory in any registered worktree … fails every walk" does not hold for ROOT_REAL under the tree walk

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:754-757`
**Move:** 3 (documentation drift)
**Confidence:** High (fact-check Claim 9, executed)
**Legibility-target:** for-author: walk header

Evidence:
```
# gate's is, by contract item 2). Any seed listing find, grep or sha1sum
# cannot complete fails the walk, so an unreadable directory in any
# registered worktree, or a link loop under a config dir's trees, fails every
# walk (fail-closed: one loop's worktree can hold every self-merge back; i1
```

C1 never lists ROOT_REAL. Its own unreadable directory is caught by the main walk's ls-files stderr rule (contract item 2), but not by the tree walk. That is the walk's prior behaviour, not a regression, but "any … every" overstates it.

**Recommendation:** Say "in any other registered worktree".

#### F3 — The plan's U2b3b2b paragraph describes iteration-1 design and omits iteration 2's contract changes

**Severity:** Informational
**Location:** `docs/working/plan-build-loop-handoff.md:306`
**Move:** 3 (documentation drift)
**Confidence:** High (fact-check Claim 1, Stale)
**Legibility-target:** for-author: plan step 5's U2b3b2b bullet

Evidence: `... gives its instruction-named files (f), \`rules/**.md\` (f), \`{commands,agents,output-styles,skills}/**.md\` and \`plugins/cache/**.md\` (p) ...` and `**Review iteration 1:** ... walks 7 s → 3 to 3.5 s over 8 worktrees.`

Since then the code has changed in five ways that the plan does not record:
- It reads installed versions from `installed_plugins.json`, falling back to the whole cache.
- `with_at` accepts grep status 0/1 only.
- Config links are kept only with a real path below a root.
- isstart reads the whole path.
- The timing is 2 to 2.5 s.

The plan is the unit's design record, and U2b3b2c's author will read it first.

**Recommendation:** Append a one-line "Review iteration 2" note naming those five changes.

#### F4 — A caller passing one of with_at's or outside_seeds' local names as NAME gets an empty array and status 0

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:1219-1220` (with_at), `:1258-1259` (outside_seeds)
**Move:** 8 (output contract), 2
**Confidence:** High (probed)
**Legibility-target:** for-author: the two headers, or the locals' names

Precedent: unprefixed non-nameref locals beside a prefixed nameref, used in `scripts/lib/dev-cycle-read.sh:664` (`prompt_bases`: `local -n pb_a="$1"; local c n=0 parts=()`) and `:1234` on main (`main_checkout`). `import_work` alone prefixes its other local (`iw_w`).

Evidence: `local -n wa_a="$1"; local p wa_ok=(); shift`, and `local -n os_a="$1"; local d q r c i in rs=() cf=() tops=() fr=() pr=() mr=() fl=() rl=() cr=() cx=() kx=() ir=() lo=() sp=() hs=() pj=(); ...`. Probe results (`with_at p <@-file>` and `outside_seeds d`, with a rules file holding `@x`): both returned `rc=0` with an empty array, while `outside_seeds sd` returned the seed. Because bash namerefs resolve dynamically, NAME binds to the function's own local. For a walk this would be fail-open: every outside start would be silently dropped. Today's callers pass `fl` and `sd`, so nothing is affected. Because the lib's precedent tolerates unprefixed locals, this is a convention observation, not a deviation. `outside_seeds`' 20 local names make it the largest such exposure in the lib.

**Recommendation:** None required. If outside_seeds is split (override row K12, revisit at U2c/U2b3b2c), prefix the array locals there. Alternatively, add "NAME must not be one of its locals" to the header.

## What Looks Good

- Every i2 finding is closed, and the closures are pinned by tests: the grep-shim test, the inventory entries and the newline case (probed).
- `outside_proj` mirrors `import_work`'s `OUT TOTAL` signature and accounting exactly, and its return-1 list matches the code.
- `root_starts` copies `tree_starts`' shape and never runs `git -C` in another root. The C1 test's git shim pins that.
- `IMPORT_MANAGED_DIR` now matches its `IMPORT_` siblings in every respect, and the test harness (`imps`) sets it after sourcing, as contract item 9's pattern implies.
- Both walks admit seeds the same way (`outside_ok`, seen-dedupe, `pdir` from `lower` with `|| return 1` after the error state is set at `:1441`/`:1498`). The tree walk appends after the checkout's starts and the main walk joins phase 2, as the walk header says.
- Contract item 4 and the Inputs paragraph name every new input, including python3 on installed_plugins.json.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| F1 | outside_seeds' C1 clause is stale (inner path vs whole path), and the byte-skip sentence promises a start the code does not guarantee (fact-check 19, 12, 21) | Minor | `scripts/lib/dev-cycle-read.sh:1237-1245`, `:1337` | High |
| F2 | Walk header's "any registered worktree … every walk" does not hold for ROOT_REAL in the tree walk (fact-check 9) | Informational | `scripts/lib/dev-cycle-read.sh:754-757` | High |
| F3 | Plan's U2b3b2b paragraph omits iteration 2's contract changes (fact-check 1) | Informational | `docs/working/plan-build-loop-handoff.md:306` | High |
| F4 | NAME colliding with a local yields an empty array and rc 0 (lib precedent tolerates it) | Informational | `scripts/lib/dev-cycle-read.sh:1219-1220`, `:1258-1259` | High |

## Overall Assessment

The branch's surface is consistent with the lib's conventions:
- nameref-first fillers and NUL producers piped through `instruction_names`;
- the `IMPORT_` global with a reset line;
- inventory entries for every new function;
- a fail-closed error rule that the code and the headers now state alike.

All six i2 findings are closed. What remains is documentation. One header clause in `outside_seeds` went stale when B3 changed the start test. Its byte-skip justification overstates the guarantee, and a fix there (a class check) would also close fact-check Claim 21's behaviour gap. Two text nits and one convention observation complete the list. Nothing breaks a caller, and every edit is local.

## Goal-Alignment Note

- Success criterion (restated verbatim): a markdown report saved at the path your dispatch names, structured per your skill, with a Goal-Alignment Note.
- Answered: yes. It covers the whole branch's surface, verifies the i2 closures, and gives findings with verbatim evidence.
- For the goal of landing U2b3b2b after a clean loop: no API finding blocks it. F1 is the only one tied to behaviour, through fact-check Claim 21. Its tier belongs to security and the orchestrator. On the API side, a header edit suffices if the class mismatch is named as an exception.
- Out of scope: review artifacts under docs/reviews/; commit-message wording (fact-check 38b, 32, 40), which the fact-check owns.
- Escalate: none beyond the fact-check's Claim 21 escalation, which F1 cross-references.
