Commit: 39f64d62

# API Consistency Review — feat/build-loop-u2b3b2b (U2b3b2b, iteration 2)

**Scope:** `git diff 1c820663..39f64d62` (the iteration-1 fix commit). The surface is `scripts/lib/dev-cycle-read.sh`: the new `root_starts`, the changed `outside_seeds` (its @ filter, C1 rawfile skip and relative CLAUDE_CONFIG_DIR refusal), the `MANAGED_DIR` → `IMPORT_MANAGED_DIR` rename, the seed loops' `pdir`, contract item 4, and the lib, walk and function headers. Also the sourcing inventory in `test/scripts/dev-cycle.bats`. Commit 1c820663 is context only.
**Date:** 2026-10-09
**Based on:** shared brief u2b3b2b-i2/shared.md; iteration-1 rubric `code-review-rubric-2026-10-09-feat-build-loop-u2b3b2b.md` and `code-fact-check-report-build-loop-u2b3b2b.md` (iteration 1). No iteration-2 fact-check was supplied: the documentation claims below were checked by reading the code and by the hermetic probes named in each finding (prefix `/tmp/u2b3b2b-aa2-`, all removed).

## Iteration-1 findings marked Fixed: verification

| i1 finding | Rubric | Verdict |
|---|---|---|
| F1: prompt seeds' LP was not lower-cased (A4) | Fixed | **Fixed.** Both seed loops now set `pdir[$p]="$(lower "$p")" \|\| return 1` (lines 1432 and 1513). `IMPORTED=error` / `IMPORTED_MAIN=error` is already set at that point, so a failed `lower` leaves the error state that contract item 6 relies on. This matches the checkout loop's `lp="$(lower "$f")" \|\| return 1` (line 1423). The C1 test's `sub/.CLAUDE/commands/p.md` → `sub/docs/up.md imported` passes for both walks (I ran it). The seeds assign `pdir` directly rather than calling `prompt_dir`. That is correct here: the `p` tag already carries the prompt decision, including `plugins/cache` prompts, which `PROMPT_DIR` would not match. |
| F2: contract item 4 omitted the two uncached inputs (A5) | Fixed (in part) | **Fixed.** Item 4 (lines 68-74) now names `CLAUDE_CONFIG_DIR or IMPORT_MANAGED_DIR (outside_seeds reads them)`. Moving them into `import_readers`' key is deferred by an override row. The text is accurate: neither `IMPORTED_DONE` nor `IMPORTED_MAIN_DONE` holds them. |
| F3: Inputs paragraph (K4) | Fixed | **Fixed.** Lines 42-46 name the config dirs, ancestors, other roots' trees and the tools. The second half of the recommendation, naming the `//` outside files that `import_outside` reads (from U2b3b2a), was not taken. That half was optional, so this is Informational residue only. |
| F4: `MANAGED_DIR` lacked the `IMPORT_` prefix (K5) | Fixed | **Fixed.** An `rg` over the repo (with `--no-ignore`) finds no bare `MANAGED_DIR` in code or tests. The remaining references are lib lines 44, 70, 1061, 1216 and 1250, `build-loop-check.bats` 19, 25 and 740, and the inventory (`dev-cycle.bats:1115`), which now checks `IMPORT_MANAGED_DIR`. The one bare spelling left is in the plan's historical "Plan (2026-10-09, before code)" paragraph (`plan-build-loop-handoff.md:306`). That paragraph is a pre-code record, so leaving it is acceptable. The name now sits with the other source-time-assigned, caller-resettable walk inputs, `IMPORT_OUT_MAX` (773) and `IMPORT_WORK_MAX` (793). |
| F5: relative CLAUDE_CONFIG_DIR silently skipped (K6) | Fixed | **Fixed.** Line 1247 now has `[[ -z "${CLAUDE_CONFIG_DIR:-}" \|\| "$CLAUDE_CONFIG_DIR" == /* ]] \|\| return 1`, and the header lists it as a return-1 condition. A new test (`CLAUDE_CONFIG_DIR=rel imps "$w" ...; want walk failed`) passes. This matches the precedent in `hooks/auto-approve-allowed-commands.sh`. |
| F6: seed tags, partial array (K7) | Won't-Fix (override row) | Settled. The basis is unchanged: every caller still returns on failure without reading the array. |

## Baseline Conventions

These are unchanged from iteration 1 (see that report):
- Signatures take a nameref NAME with a two-letter local prefix. NUL-separated producers write to stdout and are read through `nul_list` (`tree_starts`, `untracked_md`, `md_ls`, `checkout_md`, `lower_all`).
- Return 1 means a failed walk. Each function header lists its return-1 conditions.
- Walk-input globals take the `IMPORT_` prefix and are assigned at source time.
- Recent units added each new lib function to the sourcing inventory in `test/scripts/dev-cycle.bats`. 3d2d8c44 (U2b3a) added `import_readers_key`. 18fba03d, U2b3b2a's iteration-1 fix commit, added `import_outside import_file outside_ok`. 1c820663 added `outside_proj outside_seeds`.
- The error rule for listings: a listing that cannot complete fails the walk. One example is `checkout_md`, which fails on any stderr because "an unreadable directory goes unlisted with only a warning". The other is any `find` failure. Skipping is reserved for `outside_ok`'s case, a file that is not a readable regular file.

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `root_starts ROOT` | function (NUL producer) | `tree_starts`, `untracked_md`, `checkout_md` | `scripts/lib/dev-cycle-read.sh:1361, 1340, 1365` | Consistent. Its shape matches `tree_starts` exactly (`local -; set -o pipefail; ... \| instruction_names`), as does the `_starts` suffix. Unlike its neighbours it prints absolute, ROOT-led paths, and its header does not say so (F4). It is missing from the inventory (F3). |
| `IMPORT_MANAGED_DIR` | global | `IMPORT_OUT_MAX`, `IMPORT_WORK_MAX`, `IMPORT_WHOLE` | `scripts/lib/dev-cycle-read.sh:773, 793, 1058` | Consistent (renamed per i1 F4). |
| `cx`, `kx`, `ir`, `os_at` | locals | `rel`, `abs`, `os_s` | `scripts/lib/dev-cycle-read.sh:1245` (i1 spelling) | Private locals, so they are not audited. Their reuse across phases is covered in the architecture report. |

## Findings

#### F1 — The @ filter accepts every grep error (status 2), while the walk header says a grep that cannot complete fails the walk

**Severity:** Inconsistent
**Location:** `scripts/lib/dev-cycle-read.sh:1288`, `:1308` (filter); `:754-758` (walk header); `:1237-1243` (outside_seeds header)
**Move:** 4 (error consistency), 3 (documentation drift)
**Confidence:** High on the text mismatch. Medium on impact: this was read, not executed, because a mid-read I/O error cannot be made here.
**Legibility-target:** the walk header's fail-closed sentence and outside_seeds' return-1 list. Optionally, a named helper for the filter.

Evidence (filter, line 1288):
```
  [[ ${#cx[@]} -eq 0 ]] || nul_list fl xargs -0r -a <(printf '%s\0' "${cx[@]}") sh -c 'grep -lsZF -e @ -- "$@"; [ $? -le 2 ]' sh || return 1
```
Evidence (walk header, lines 754-756):
```
# gate's is, by contract item 2). Any seed listing find, grep or sha1sum
# cannot complete fails the walk, so an unreadable directory in any
# registered worktree, or a link loop under a config dir's trees, fails every
```
Evidence (outside_seeds header, lines 1238-1239, 1241-1242):
```
# the rest are dropped (i1 performance F1); an unreadable file is skipped, as
# outside_ok skips it. ...
# security F2). It returns 1 when a find, grep, sha1sum,
# realpath or lower_all fails, a seed's path holds a newline, or
```

`[ $? -le 2 ]` folds every grep error into success. That includes the unreadable file the header names, and also a read error partway through a file that `outside_ok` admits (`-f && -r`). With `-s`, nothing reaches stderr. The file is then missing from `os_at` and, unless a link leads to it, it is dropped as a seed. So the only "grep fails" case that still returns 1 is grep dying on a signal (xargs 123/125). The walk header's sentence and the header's "returns 1 when ... grep ... fails" therefore describe a stricter rule than the code applies. The lib's own precedent is stricter: `checkout_md` fails on any stderr precisely because a listing tool reports an unreadable entry only as a warning. Skipping here is narrower than "the session cannot load it" only if grep's error was something other than EACCES.

**Recommendation:** Do one of two things. Either make the text match: say the @ filter treats any grep error on a file as "no @" (skipped, as outside_ok skips an unreadable file) and drop "grep" from the fail-closed sentences. Or make the code match: test `outside_ok` on the files grep did not list and still keep any that `-r` admits, so a status-2 file is dropped only when a session also could not read it.

#### F2 — outside_seeds' documented "returns 1 when a seed's path holds a newline" no longer holds when no other root yields a candidate

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:1303` (new early return), `:1320` (the check it skips), `:1242` (header)
**Move:** 3 (consumer contract)
**Confidence:** High (probed)
**Legibility-target:** outside_seeds' return-1 list, and the newline test's name in `test/scripts/build-loop-check.bats:756`

Evidence:
```
  [[ ${#cx[@]} -gt 0 ]] || return 0
```
```
  for d in "${os_a[@]}"; do [[ "$d" != *$'\n'* ]] || return 1; done
```

The fix commit added `return 0` after the C1 listing, when it finds no candidate. That exits before the final newline check, which also covers the config seeds already in `os_a`. Probe `/tmp/u2b3b2b-aa2-*` used a single repo with `$HOME/.claude/rules/a\nb.md` holding `@x`. Results:
- With no other worktree, `outside_seeds a` returned `rc=0` with the newline seed in `a`.
- With a sibling worktree holding an @ start, it returned `rc=1`.
- With a sibling holding no start, it returned `rc=0` again.

Both walks still fail, because `import_outside` refuses a real path holding a newline (line 1171; probe: `tree walk: failed`, `main walk: failed`). So nothing fails open. But the test "both walks fail closed when ... a seed's name holds a newline" now passes through `import_outside`'s guard, not the one outside_seeds documents. Callers other than the two walks would also get a newline-bearing array with status 0.

**Recommendation:** Move the newline loop above the C1 block (config seeds), or replace the early `return 0` with a skip of the C1 block. Optionally, have the newline test call `outside_seeds` directly, as the C1 test does, so it pins this function's contract.

#### F3 — `root_starts` is not in the sourcing inventory, unlike every lib function the last three units added

**Severity:** Minor
**Location:** `test/scripts/dev-cycle.bats:1109-1111` (function list); `scripts/lib/dev-cycle-read.sh:1211`
**Move:** 2 (naming/inventory), 3 (test drift)
**Confidence:** High
**Legibility-target:** the inventory list

Precedent: new walk helpers are added to the `declare -F` inventory in the commit that introduces them, used in test/scripts/dev-cycle.bats:1109-1111 (3d2d8c44 `import_readers_key`; 18fba03d, U2b3b2a's i1 fix commit, `import_outside import_file outside_ok`; 1c820663 `outside_proj outside_seeds`)

Evidence (list tail): `... import_readers import_readers_key import_outside import_file outside_ok outside_proj outside_seeds; do`

The fix commit edited this same test line to rename the global, but did not add the new function. The inventory is not exhaustive (`prompt_dir`, `isstart`, `truthwalk` and others from earlier units are absent), so this is drift from recent practice, not a broken invariant.

**Recommendation:** Append `root_starts` to the list.

#### F4 — `root_starts`' header does not say its output is absolute, which differs from its nearest neighbour

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:1208-1211`
**Move:** 2 / 8 (output contract)
**Confidence:** High
**Legibility-target:** root_starts' header

Precedent: `tree_starts` (line 1361) prints repo-relative names (git ls-files), and the iteration-1 C1 listing used `-printf '%P\0'` (relative to ROOT)

Evidence: `# root_starts ROOT: the start-named files (instruction_names) below ROOT, an` / `# absolute directory, NUL-separated, listed with find -P (.git pruned):`

`root_starts` prints `find -print0` paths, so they are ROOT-led and absolute. Its only caller depends on that (`[[ "$d" == "$ROOT_REAL"/* ...`, line 1301). `instruction_names` then matches the whole absolute path, including ROOT's own components. That gives a superset, which isstart narrows, so it is harmless. A reader comparing `root_starts` with `tree_starts` would expect the same spelling.

**Recommendation:** Add "as absolute paths (ROOT-led)" to the header.

#### F5 — Contract item 9 still does not say whether IMPORT_MANAGED_DIR is caller-settable; item 4 and the global's comment imply opposite readings

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:68-74` (item 4), `:90-96` (item 9), `:1059-1061`
**Move:** 3
**Confidence:** Medium
**Legibility-target:** the global's comment

Evidence: item 4: `or CLAUDE_CONFIG_DIR or IMPORT_MANAGED_DIR (outside_seeds reads / them)`, a reset trigger, which implies a caller may change it. Global: `# config dir; set here, so the environment never moves it (a test sets it).`

`IMPORT_OUT_MAX` and `IMPORT_WORK_MAX` each carry "A caller that changes it calls import_reset". The renamed global's comment says only "a test sets it". The iteration-1 F2 recommendation's optional half (item 9) was not taken. No caller sets it today.

**Recommendation:** Add "a caller that changes it calls import_reset (item 4)" to the global's comment, matching its `IMPORT_` siblings.

#### F6 — The plan's U2b3b2c bullet carries a sentence about U2b3b2b's CLAUDE_CONFIG_DIR handling

**Severity:** Informational
**Location:** `docs/working/plan-build-loop-handoff.md:307` (U2b3b2c bullet, end)
**Move:** 3 (documentation drift)
**Confidence:** High
**Legibility-target:** plan step 5's U2b3b2b and U2b3b2c bullets

Evidence: `... (both walks failed). CLAUDE_CONFIG_DIR is read per walk; a caller that changes it calls import_reset. Tests: bl_setup unsets CLAUDE_CONFIG_DIR.`

The fix commit moved these two sentences from the end of U2b3b2b's plan paragraph to the end of the new U2b3b2c bullet. The U2b3b2b paragraph also still says "`$CLAUDE_CONFIG_DIR` when absolute" (skip semantics). The iteration-1 note appended to it does not mention that a relative one now fails the walk, or the rename.

**Recommendation:** Move the sentences back to U2b3b2b's paragraph. Add "a relative CLAUDE_CONFIG_DIR fails the walk; MANAGED_DIR renamed IMPORT_MANAGED_DIR" to its review-iteration-1 note.

## What Looks Good

- The rename is complete in code and tests. The inventory test checks the new name, so a stale reference would fail it.
- `root_starts` copies `tree_starts`' shape and failure semantics, and `instruction_names`' no-match handling (`|| [[ $? -eq 1 ]]`) means a root with no start yields an empty list, not a failed walk.
- The relative-CLAUDE_CONFIG_DIR refusal now matches both precedents (the hook and `import_readers`' refusal of a non-absolute root or home), with a test.
- The `pdir` fix keeps the walk's error discipline: `|| return 1` after `IMPORTED=error`, exactly as the checkout loop treats `lower`.
- `import_outside`'s and `outside_ok`'s headers now say an absolute name may be an outside_seeds start in another root (i1 architecture 2). Contract item 4 is accurate.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| F1 | @ filter accepts every grep error (status ≤ 2); walk header and outside_seeds header say a grep that cannot complete fails the walk | Inconsistent | `scripts/lib/dev-cycle-read.sh:1288, 1308, 754-756, 1241` | High (text) / Medium (impact) |
| F2 | Early `return 0` skips the newline check; outside_seeds returns 0 with a newline seed when no other root yields a candidate (walks still fail via import_outside) | Minor | `scripts/lib/dev-cycle-read.sh:1303, 1320, 1242` | High |
| F3 | `root_starts` missing from the sourcing inventory | Minor | `test/scripts/dev-cycle.bats:1109-1111` | High |
| F4 | `root_starts` header does not state absolute output | Informational | `scripts/lib/dev-cycle-read.sh:1208-1210` | High |
| F5 | IMPORT_MANAGED_DIR comment lacks the "caller that changes it calls import_reset" its siblings carry | Informational | `scripts/lib/dev-cycle-read.sh:1059-1061` | Medium |
| F6 | Plan: U2b3b2b's CLAUDE_CONFIG_DIR sentences sit in the U2b3b2c bullet; the relative refusal and the rename are not noted | Informational | `docs/working/plan-build-loop-handoff.md:306-307` | High |

## Overall Assessment

The fix commit closes every iteration-1 API finding it marks Fixed:
- the lower-cased prompt LP
- contract item 4
- the Inputs paragraph
- the `IMPORT_` rename, with every reference updated
- the relative CLAUDE_CONFIG_DIR refusal

Each is verified, and the targeted tests pass. The fix range adds one real consistency gap. The new @ filter's error rule (accept every grep error) contradicts the fail-closed sentence the same commit wrote into the walk header, and it is looser than the lib's own listing rule (`checkout_md`). Either the text or the code should move. The rest is small: the early return that bypasses a documented return-1 condition (backstopped by `import_outside`), and inventory and header polish. None breaks a caller.

## Goal-Alignment Note

The goal is to land U2b3b2b after a clean review-fix loop. Nothing here blocks the unit's purpose, and neither walk fails open in any probe I ran. F1 is the only finding that needs a decision: whether a readable file that grep cannot finish is a skip or a failed walk. A one-line header edit settles it if the skip is intended, and a small `outside_ok` check settles it if not. F2 and F3 are one-line fixes. F4 to F6 are text. I did not re-verify the timing and suite-count claims (claim 6), which belong to the fact-check.
