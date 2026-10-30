Commit: c4bab9ca

# API Consistency Review: fix/q145-ancestor-vanish (final confirming pass)

**Scope:** `git diff main...HEAD` in /workspace/.claude/wt-q145 (code: `scripts/lib/dev-cycle-read.sh`, `test/scripts/build-loop-check.bats`, `test/scripts/dev-cycle.bats`; docs: `docs/thoughts/failure-patterns.md`, plus review artifacts)
**Date:** 2026-10-14
**Based on:** `docs/reviews/code-fact-check-report-2026-10-14-q145-final-r{1,2,3}.md` (k=3, 0 code defects); prior review `docs/reviews/api-consistency-review-2026-10-14-q145.md` (iteration 2, at 0d573a7b)

## Baseline Conventions

The baseline is the same as in iteration 2. It was re-checked against the current file.

- **NAME-array helpers** (`with_at` :1363, `outside_seeds` :1503, `config_seeds` :1513, `c1_seeds` :1600, `nul_list` :1649): the output array's name comes first, then the inputs. The header opens `fn NAME ARG...:` and says "array NAME gets" when the array is replaced and "appends ... to array NAME" when it is added to. The output nameref is `<initials>_a`, and other locals carry the same prefix (`wa_ok`, `ow_d`), apart from some bare short names (`with_at`'s `p`, `config_seeds`' `d q r c i`).
- **Return contracts:** "It returns 1 when ..." or "It fails ... when ...", and any provenance tag goes in parentheses at the end of the clause.
- **Nameref collisions:** these are documented only at the outermost entry point, `outside_seeds` (:1500-1502: "NAME must not be one of the three functions' locals (a nameref to one reads that local)"). `with_at` and `nul_list` do not document their own locals. Probe: `p=(stale); with_at p a.md` returned 0 and left `p` as `stale`. A NAME that matches a helper's local therefore already fails silently in the existing code.
- **Test knobs:** `T_*` variables are documented as `imps` inputs (`build-loop-check.bats:16-19`). Shims take no knobs elsewhere in the file.

## Status of Prior Findings

| # | Prior finding | Status at c4bab9ca | Evidence |
|---|---|---|---|
| F1 | Shim knobs in imps' `T_` namespace | **Fixed** | Renamed `SHIM_ONCE` / `SHIM_RMTOP`. `build-loop-check.bats:733` adds "(SHIM_*, not T_*: the shim reads them, not imps.)" |
| F2 | config_seeds header tied three tries to a vanished entry only | **Fixed** | `:1508-1512` now says "the top-level listing (top_files) fails it only when all three of its tries fail (a directory entry that vanishes mid-listing fails one; a vanished file is skipped: Q-145)". This is accurate: the call site at `:1566` retries any failure |
| F3 | top_files header omitted the dangling DIR-link entry | **Fixed** (by the stronger option) | The `-d` recheck moved into top_files (`:1595`). The header (`:1583-1592`) now documents that a linked DIR appears in NAME, and that a DIR which is no longer a directory fails the call with NAME empty. Unit test at `build-loop-check.bats:779` pins this (`dead: failed, 0 left`) |
| F4 | NAME `nl_a` collides with nul_list's nameref | **Accepted** (unchanged, still Informational) | Re-probed: `top_files nl_a DIR` gives rc=0, the correct result, and 7 circular-reference warnings |
| F5 | top_files embeds nul_list (with_at shape) | No change needed | n/a |

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `top_files` | lib function | `root_starts`, `tree_starts`, `with_at` | `scripts/lib/dev-cycle-read.sh:1357,1363,1666` | Consistent (unchanged from iteration 2) |
| `top_files NAME DIR...` | signature | `with_at NAME PATH...`, `nul_list NAME CMD...` | `scripts/lib/dev-cycle-read.sh:1358,1648` | Consistent |
| `tf_d` (new local) | helper local | `ow_d` (`outside_seeds`), `wa_ok` (`with_at`) | `scripts/lib/dev-cycle-read.sh:1504,1364` | Consistent: initials-prefixed loop variable, same shape as `ow_d` |
| `tf_a` (new nameref) | nameref local | `wa_a`, `ow_a`, `os_a`, `c1_a`, `nl_a` | `scripts/lib/dev-cycle-read.sh:1364,1504,1514,1649` | Consistent: `<initials>_a` |
| `SHIM_ONCE`, `SHIM_RMTOP` (`1` / `drop`) | test shim knobs | `T_SETTINGS`, `T_MANAGED` (imps inputs, a different consumer) | `test/scripts/build-loop-check.bats:16-19` | Consistent now: the separate prefix marks a separate consumer, and the test comment documents it (F1 fixed) |
| test title "top_files lists ... (Q-145 final fact-check r3)" | test name | "(Q-145)", "(U2b3b2b; ... i1 fact-check 19b, api F1 ...)" | `test/scripts/build-loop-check.bats:724,790` | Consistent: a behaviour sentence followed by a provenance tag |
| FP-173 | failure-pattern entry | FP-170..172 | `docs/thoughts/failure-patterns.md:312-314` | Consistent |

## Findings

#### 1. A NAME of `tf_d` makes top_files return 0 with the caller's array untouched (collision contract)

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:1583-1596`
**Move:** 3 (consumer contract) / 8 (output contract)
**Confidence:** High
**Legibility-target:** a future direct caller of top_files (today the only caller is config_seeds, which passes `fl`)

**Evidence:**
```
# It fails, with NAME empty, when find reports any error (...) or a DIR is no longer
# a directory after the listing: ...
top_files() {
  local tf_d; nul_list "$1" find -H "${@:2}" -maxdepth 1 -ignore_readdir_race '(' -xtype f -o -xtype l ')' -print0 || return 1
  for tf_d in "${@:2}"; do [[ -d "$tf_d" ]] || { local -n tf_a="$1"; tf_a=(); return 1; }; done
}
```
Probe at c4bab9ca (findutils/bash in this container):
```
tf_d rc=0 n=1 v=stale          # success path: caller's array not filled
tf_d dead rc=1 n=1 v=stale     # failure path: rc 1, but NAME not emptied
tf_a dead rc=1 n=0 err=...: local: warning: tf_a: circular name reference
```

`local tf_d` is declared before `nul_list "$1"` runs. When NAME is `tf_d`, nul_list's nameref therefore resolves to top_files' own local, so the listing lands there and the loop then overwrites it. The caller gets status 0 and its array unchanged. On the failure path the header's "with NAME empty" promise also fails. NAME `tf_a` only produces a stderr warning, and the result is still correct. This follows the lib's existing pattern, which is why it is Informational. `with_at` has the same silent behaviour for NAME `p` (probe: rc=0, `p` left as `stale`), and the lib documents collisions only at `outside_seeds`. The `outside_seeds` rule is still complete: top_files never receives outside_seeds' NAME (config_seeds passes its own `fl`), so top_files' locals do not need to join "the three functions' locals". The only cost is that the new header's "with NAME empty" guarantee is unconditional on paper but conditional in fact.

**Recommendation:** None required for merge. If wanted, append "NAME must not be tf_d, tf_a or nl_a" to the header. Alternatively, move `local tf_d` after the nul_list call, which removes the silent case and leaves only the warning cases.

## What Looks Good

- **All three Minor findings were fixed in place.** F3 used the stronger option: the guarantee now travels with the function, not the call site. The header was rewritten to match, and a dedicated unit test pins it.
- **The new locals follow the prefix convention.** `tf_d` and `tf_a` match `ow_d` and `wa_a`/`os_a`. The nameref is bound lazily, only on the failure branch, which is the cheapest place for it.
- **The return contract matches nul_list's.** Both success and failure leave NAME replaced or emptied, so "gets" stays the right verb.
- **The config_seeds header and the walk-level comment (`:828-836`) now agree.** Any failure is retried, a persistent error still fails the walk, and a vanished file is skipped.
- **The function-list pin** (`test/scripts/dev-cycle.bats:1115`) includes `top_files`. Both new tests and the pin test pass at c4bab9ca (`bats -f 'Q-145'`: 2/2 ok; dev-cycle function-list test: ok).

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | NAME `tf_d` gives rc 0 with the caller's array untouched; "with NAME empty" fails for it (same class as with_at's `p`; undocumented, per the lib's convention) | Informational | `scripts/lib/dev-cycle-read.sh:1583-1596` | High |
| (F4) | NAME `nl_a` gives circular-reference warnings (inherited, accepted) | Informational | `scripts/lib/dev-cycle-read.sh:1593,1649` | High |

## Overall Assessment

The branch is consistent with the lib's API conventions. Prior findings F1, F2 and F3 are fixed, F4 stays accepted, and the move of the `-d` recheck into top_files left the code with a cleaner contract. That contract is self-contained, documented and unit-tested. The one new observation is that top_files' locals (`tf_d`, and to a lesser degree `tf_a`) join the set of names a caller must not pass as NAME. This behaves exactly as existing helpers do with their locals (`with_at`'s `p`), and the only caller cannot hit it. Nothing is Breaking, Inconsistent or Minor, and config_seeds' and outside_seeds' 0/1 return contracts are unchanged. From an API-consistency standpoint, there is no reason not to merge.

## Goal-Alignment Note

The PR's goal is to stop config_seeds' top-level ancestor listing from failing the walk when another process deletes an entry mid-listing, while still failing closed on every other error. The final API serves that goal more directly than iteration 2 did. Both halves of the fail-closed behaviour now live inside `top_files`: a find error, and a DIR that is no longer a directory. The function's header states them and its own unit test pins them, so config_seeds' call site is reduced to the retry policy alone (three tries, stderr dropped on the first two). The other three find listings in config_seeds are untouched and still fail on the first error, which keeps the "narrow-the-guard" scope of FP-173. The remaining Informational item affects only a hypothetical second caller that picks a reserved array name. It does not touch the race handling or the fail-closed path the PR exists to protect.
