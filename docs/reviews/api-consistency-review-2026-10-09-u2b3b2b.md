Commit: 1c820663

# API Consistency Review — feat/build-loop-u2b3b2b (U2b3b2b, iteration 1)

**Scope:** `git diff main...HEAD` at 1c820663; surface is `scripts/lib/dev-cycle-read.sh`'s new functions `outside_proj` and `outside_seeds`, new global `MANAGED_DIR`, the walk header and caller contract (items 1-9), and the sourcing inventory in `test/scripts/dev-cycle.bats`
**Date:** 2026-10-09

> ⚠️ **No code fact-check report provided.** API documentation claims have not been
> independently verified against implementation. For full verification, run the
> `code-fact-check` skill first or use the code-review orchestrator.
> (The fact-check runs in parallel this iteration; one behaviour below, F1, was verified by a hermetic probe.)

## Baseline Conventions

Survey of neighbouring lib functions (`import_work`, `nul_list`, `prompt_bases`, `prompt_dir`, `lower_all`, `import_outside`, `import_readers`, `outside_ok`) and the lib header:

- **Signatures:** output goes through a nameref, with the parameter spelled in caps in the comment (`import_work OUT TOTAL`, `nul_list NAME CMD...`, `prompt_bases NAME LP PATH`, `prompt_dir MAP LP PATH`). Nameref locals take a two-letter function prefix (`iw_o`, `nl_a`, `pb_a`, `pd_m`) so they cannot shadow the caller's name.
- **Return codes:** 0 success, 1 failure, which every walk turns into a failed walk (fail closed). `main_checkout` alone uses a 0/1/2 scheme. `nul_list` empties its array on failure.
- **Comment style:** a header comment opens with `name ARGS:`, states what it returns 1 on, and cites the review finding that motivated it.
- **Globals:** walk tuning and walk inputs use an `IMPORT_` prefix (`IMPORT_OUT_MAX`, `IMPORT_WORK_MAX`, `IMPORT_WHOLE`, `IMPORT_READER_ROOTS/HOMES`). A global the environment must not set is assigned at source time and documented that way (`IMPORT_READER_*`, `IMPORT_WHOLE`).
- **Contract item 8:** `prompt_dir` and `prompt_bases` take a **lower-cased** LP plus the path as spelled. Both checkout start loops honour this (lines 1389, 1467).
- **Caching (contract item 4):** both walks key on `import_readers`' roots and homes, plus main's SHA for the main walk. Item 4 lists every other input whose change needs `import_reset`.
- **Inventory test:** `test/scripts/dev-cycle.bats` checks every lib function and global with `declare -F` and `declare -p`.

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `outside_proj OUT TOTAL` | function | `import_work OUT TOTAL`, `outside_ok PATH`, `import_outside FILE` | `scripts/lib/dev-cycle-read.sh:1174-1178, 1285-1295` | Consistent. It has the same OUT/TOTAL nameref pair and return-1 semantics as `import_work`, and the `outside_` prefix matches `outside_ok`. |
| `outside_seeds NAME` | function | `prompt_bases NAME`, `nul_list NAME`, `tree_starts` | `scripts/lib/dev-cycle-read.sh:663, 1307, 1324` | Consistent in name and nameref shape. Its entry encoding and state on failure differ from neighbours (F5, F6). |
| `op_o`, `op_t`, `os_a`, `os_s` | nameref/locals | `iw_o`, `iw_t`, `pb_a`, `nl_a` | `scripts/lib/dev-cycle-read.sh:663-665, 1291, 1307` | Consistent: two-letter function prefix. |
| `MANAGED_DIR` | global | `IMPORT_WHOLE`, `IMPORT_READER_ROOTS`, `IMPORT_WORK_MAX` | `scripts/lib/dev-cycle-read.sh:1040-1049` | Minor. It is a walk input without the `IMPORT_` prefix (F4). |
| `f` / `p` seed tags | data encoding | `m:` / `t:` cand tags in `main_imports` | `scripts/lib/dev-cycle-read.sh:1446, 1459` | Informational. This is a second tag shape inside one file (F6). |

## Findings

#### F1 — Outside prompt seeds pass `prompt_bases` an un-lowered LP, breaking contract item 8 and diverging from the checkout's own prompt starts

**Severity:** Inconsistent
**Location:** `scripts/lib/dev-cycle-read.sh:1395` (imported_names), `scripts/lib/dev-cycle-read.sh:1476` (main_imports), contract `scripts/lib/dev-cycle-read.sh:82-85`
**Move:** 3 (consumer contract) / 7 (asymmetry)
**Confidence:** High (probed)
**Legibility-target:** the two seed loops in the walks, and `outside_seeds`' header (which should say whether it hands back a lower-cased form)

Evidence (contract, lines 82-84):
```
#  8. Pass truthrule, isstart, ownfile, prompt_dir and prompt_bases a
#     lower-cased path (prompt_dir and prompt_bases also take the path as
#     spelled; floor, check_fix and the walks lower first; truthrule refuses an
```
Evidence (checkout starts, line 1389): `seen+="$f"$'\n'; queue+=("$f"); prompt_dir pdir "$lp" "$f"`
Evidence (outside seeds, line 1395): `seen+="$p"$'\n'; queue+=("$p"); [[ "$f" != p* ]] || pdir[$p]="$p"`

`outside_seeds` decides that an entry is a prompt (`p`) from the lower-cased path (`c=f; [[ ! "${lo[i]}" =~ $PROMPT_DIR ]] || c=p`). Both walks then store the path as spelled as the LP. `prompt_bases` splits LP on `/` and matches each component against the literal `.claude`, so a `.CLAUDE/` component yields no base. The seed is still treated as a prompt.

**Probe** (temp dir `/tmp/u2b3b2b-api-*`, removed): a sibling worktree held `sub/.claude/commands/l.md` (`@docs/lo.md`) and `sub/.CLAUDE/commands/u.md` (`@docs/up.md`), and the repo held `sub/docs/{lo,up}.md`. Results:
- Both walks reported `sub/docs/lo.md: imported` and `sub/docs/up.md: -`. Both files appeared as `p` seeds.
- With the same `.CLAUDE` prompt placed in this checkout instead, both walks reported `sub/docs/up.md: imported`.

So one walk input gets two different superset rules depending on where the file sits. This only matters on a case-insensitive file system, which is the case the lower-casing exists for.

**Recommendation:** Have `outside_seeds` carry the lower-cased form, or lower it in the seed loops, and call `prompt_dir pdir "$lp" "$p"` as the checkout loop does. Add the `.CLAUDE` variant to the C1 test.

#### F2 — Contract item 4 (the "one statement" of the cache contract) does not name the two new uncached walk inputs

**Severity:** Inconsistent
**Location:** `scripts/lib/dev-cycle-read.sh:65-70` (item 4), `:1214-1215` (outside_seeds), `:1050-1052` (MANAGED_DIR)
**Move:** 3 (documentation drift)
**Confidence:** High
**Legibility-target:** caller contract item 4

Evidence (item 4):
```
#  4. Call import_reset before each gate decision and after any checkout
#     change (rows 372, 439), or when IMPORT_OUT_MAX or IMPORT_WORK_MAX
#     changes: neither walk's cache key holds them (both hold import_readers'
#     roots and homes, so HOME and IMPORT_READER_* need no reset; ...
```
Evidence (outside_seeds): `# Run it after import_readers. CLAUDE_CONFIG_DIR is read on each call: a caller` / `# that changes it calls import_reset.`

Each walk now reads `CLAUDE_CONFIG_DIR` and `MANAGED_DIR` through `outside_seeds`, and neither is in `IMPORTED_DONE` or `IMPORTED_MAIN_DONE`. The reset rule for `CLAUDE_CONFIG_DIR` appears only in a function comment. Item 4 still enumerates the reset triggers as if it were complete, and it is the place the header calls "the one statement of it". It also says nothing about `MANAGED_DIR`, which a test reassigns after sourcing.

Item 4's first clause ("before each gate decision") does cover the gate. The non-gate caller (`--check-fix`'s tree walk) and any future caller read item 4 as the list.

**Recommendation:** Add `CLAUDE_CONFIG_DIR` and `MANAGED_DIR` to item 4's list of inputs that need `import_reset`, or add them to both cache keys. Item 9's "never set these yourself" list could also say whether `MANAGED_DIR` is caller-settable.

#### F3 — The lib header's "Inputs" paragraph does not list the walks' new file-system reads

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:34-44`
**Move:** 3 (documentation drift)
**Confidence:** High
**Legibility-target:** lib header, Inputs paragraph

Evidence (lines 41-43):
```
# imported_names, checkout_md and main_checkout read the working tree at ROOT_REAL.
# Both walks also read the repository's worktree registry (import_readers),
# and reader_settings reads docs/dev-cycle.md from the default branch's commit.
```
This paragraph is the header's inventory of what each entry point reads. The walks now also read:
- every reader home's `.claude` and `$CLAUDE_CONFIG_DIR`
- `/etc/claude-code`
- the ancestors of every reader root and their `.claude`
- the whole file tree of every other reader root (`find -P`)

They also run `find`, `sha1sum` and `python3` on `installed_plugins.json`. Only the walk header (lines 740-754) says this. A caller deciding whether the walk is hermetic, or what to sandbox, reads the Inputs paragraph and is told only the working tree and the registry. The python3 sentence at line 13 is still accurate, since a missing python3 for plugins gives a superset rather than a failure.

**Recommendation:** Add one sentence to the Inputs paragraph that names outside_seeds' sources (or points to its comment), and add the outside imports `import_outside` reads (from U2b3b2a).

#### F4 — `MANAGED_DIR` breaks the `IMPORT_` prefix the lib uses for walk inputs and tuning

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:1050-1052`
**Move:** 2 (naming)
**Confidence:** Medium
**Legibility-target:** the global's name and comment

Precedent: walk-input and walk-tuning globals are `IMPORT_*` (`IMPORT_OUT_MAX`, `IMPORT_WORK_MAX`, `IMPORT_WHOLE`, `IMPORT_READER_ROOTS`, `IMPORT_READER_HOMES`) used in scripts/lib/dev-cycle-read.sh:1040-1049, 785-800

Evidence: `MANAGED_DIR=/etc/claude-code`

The lib is sourced into the scripts' global namespace. A generic name like `MANAGED_DIR` is easier to collide with in a caller (or a future script) than the prefixed family, and it does not tell a reader that the walks consume it. Un-prefixed globals do exist (`PROMPT_DIR`, `START_LINK`, `MAIN`), but those are regexes or results, not walk inputs. No current caller uses the name (rg over `scripts/`, `hooks/` and `test/`).

**Recommendation:** Rename it `IMPORT_MANAGED_DIR`, or keep the name and say in item 9 that it is a test hook only.

#### F5 — A relative `CLAUDE_CONFIG_DIR` is silently ignored, where the repository's other consumer of it fails closed

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:1221`
**Move:** 4 (error consistency)
**Confidence:** Medium
**Legibility-target:** outside_seeds header ("CLAUDE_CONFIG_DIR when absolute")

Evidence: `[[ "${CLAUDE_CONFIG_DIR:-}" != /* ]] || cf+=("$CLAUDE_CONFIG_DIR"); cf+=("$MANAGED_DIR")`
Precedent: `hooks/auto-approve-allowed-commands.sh:190-193`: `# A relative CLAUDE_CONFIG_DIR resolves against this hook's cwd ... so the global deny rules could silently go missing: fail closed.`

A Claude Code session with a relative `CLAUDE_CONFIG_DIR` resolves it against its own cwd, so its config dir's instruction files could import repo paths the walk never seeds. Elsewhere the walks fail closed on input they cannot model; `import_readers` refuses a root or caller home that is not absolute. Here the input is skipped instead. The header does say "when absolute", so the behaviour is documented, but the choice differs from both precedents. It is this process's env, not necessarily the session's, which is why confidence is Medium.

**Recommendation:** Return 1 on a non-empty relative `CLAUDE_CONFIG_DIR`, matching the hook and `import_readers`. Alternatively, record the skip as a named exception in the walk header next to the others.

#### F6 — Seed-entry encoding and failure state differ from neighbours

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:1216-1286` (outside_seeds), `:1446, 1459` (main_imports `cand`), `:1307` (nul_list)
**Move:** 2 / 8
**Confidence:** High
**Legibility-target:** outside_seeds header

Precedent: tagged path lists use a letter plus colon (`cand+=("m:$f")`, `cand+=("t:$f")`, read back as `${cand[i]:2}`) in scripts/lib/dev-cycle-read.sh:1446, 1459

Evidence: `os_a+=("f$d")`, `os_a+=("p$d")`, read back as `p="${f:1}"`.

The two shapes are close enough to be mistaken for each other. The test pins the one-letter form (`"f$sd/CLAUDE.local.md"`). Also, on `return 1` the array NAME keeps a partial list, while `nul_list` documents "is emptied and 1". Both callers discard it, so this has no current impact.

**Recommendation:** Optional: use `f:`/`p:` to match `cand`, and say in the header that NAME is unspecified on 1 (or clear it).

## What Looks Good

- `outside_proj OUT TOTAL` copies `import_work`'s nameref pair, work accounting and return-1 rule. It slots into both walks with the same `&& ... || { X=error; return 1; }` chain as its neighbours (lines 1403, 1517).
- Both seed loops run after `IMPORTED=error` / `IMPORTED_MAIN=error` is set, so a bare `outside_seeds sd || return 1` leaves the error state that contract item 6 relies on. This is consistent with the lines around it (`nul_list recs tree_starts || return 1`).
- `MANAGED_DIR` follows the lib's "assigned at source time, so the environment never sets it" convention (`IMPORT_WHOLE`, `IMPORT_READER_*`). The inventory test in `test/scripts/dev-cycle.bats` was extended with both functions and the global, matching the existing pattern.
- Seeds use the same admission rule (`outside_ok`) and dedup sets (`seen`) as `//` imports, and join the same queue position (phase 2 / `tq` in the main walk). Both walks therefore treat a seed as they treat an outside import.
- Both fixtures (`build-loop-fixtures.bash`, `dev-cycle.bats`) `unset CLAUDE_CONFIG_DIR`, the same isolation `test/auto-approve-allowed-commands.bats:16` uses.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| F1 | Outside prompt seeds give prompt_bases an un-lowered LP (item 8); a `.CLAUDE/` prompt in another worktree loses its base, unlike in this checkout | Inconsistent | `scripts/lib/dev-cycle-read.sh:1395, 1476` | High |
| F2 | Contract item 4 omits CLAUDE_CONFIG_DIR and MANAGED_DIR as uncached walk inputs | Inconsistent | `scripts/lib/dev-cycle-read.sh:65-70, 1214` | High |
| F3 | Header Inputs paragraph does not list the outside reads | Minor | `scripts/lib/dev-cycle-read.sh:34-44` | High |
| F4 | MANAGED_DIR lacks the IMPORT_ prefix of walk inputs | Minor | `scripts/lib/dev-cycle-read.sh:1052` | Medium |
| F5 | Relative CLAUDE_CONFIG_DIR is skipped, not refused (hook and import_readers fail closed) | Minor | `scripts/lib/dev-cycle-read.sh:1221` | Medium |
| F6 | `f`/`p` tags vs `m:`/`t:`; partial array left on return 1 | Informational | `scripts/lib/dev-cycle-read.sh:1216-1286` | High |

## Overall Assessment

The new functions follow the lib's conventions closely: nameref signatures, prefixed nameref locals, the return-1-means-failed-walk rule, and the inventory test. `outside_proj` is a clean sibling of `import_work`. The real consistency gap is F1, where both walks treat outside prompt seeds by a different rule (spelled LP) than the checkout's prompt starts (lower-cased LP, contract item 8). A probe shows a lost base. The remaining findings are contract drift: the cache-reset list (F2) and the Inputs paragraph (F3) have not caught up with the new inputs. All of them can be fixed in place and none breaks an existing caller.

## Goal-Alignment Note

The goal is to land U2b3b2b after a clean review-fix loop. No finding blocks the unit's purpose, which is seeding the walks with files outside the repo. F1 is a small superset loss inside the new seeding, limited to case-insensitive file systems, and the fix is a two-line change plus one test variant. F2 and F3 are header and contract edits. F4 to F6 are optional polish or can be logged as overrides. Nothing here suggests the walks fail open on Linux, where the gate runs.
