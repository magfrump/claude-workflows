Commit: 83f75281

# Security Review — feat/build-loop-u3a1, iteration 2 (fix range 65007bf8..83f75281)

**Scope:** `git diff 65007bf8..83f75281` (docs/reviews excluded): `scripts/build-loop.sh` (store_check, state_gate, gate_start, check_line messages), `test/scripts/build-loop-check.bats`, plan step 7 note
**Date:** 2026-10-10
**Based on:** `docs/reviews/code-fact-check-report-build-loop-u3a1-i2.md` (0 Incorrect; executed second pack, loose+packed, truncated/unreadable .idx, unreadable fan-out dir, midx pack without .idx: all refuse); iteration 1 report `security-reviewer-review-2026-10-10-build-loop-u3a1.md` (F1).

**Method note:** this pass is **read-static**. I did not re-run iteration 1's forged-pack probes or build new ones. Every bypass candidate below is either traced through the code or listed as untested. Executed evidence for the fix comes from the fact-check report.

**Bottom line:** the one-copy rule closes iteration 1's F1 as reproduced: two copies of a checked id in two `.idx` files, or loose and packed, now refuse (executed by the fact-check). It does not provably close F1 for every way git can find bytes for an id. The duplicate scan enumerates copies its own way: `"$o"/pack/*.idx` by bash glob, and loose files by `find` without following symlinks. Git enumerates packs and loose files differently, and three gaps follow from that difference (F1 below, all untested). The skip of already-checked ids widens the window in which a persistent rewrite goes unnoticed (F2, Q-103 family). The alternates refusal is placed correctly (before any object read).

---

## Trust Boundary Map

```
B1: .git/objects (loose files, pack/*.pack+*.idx, pack/multi-pack-index) → store_check re-hash + one-copy scan → $GATE_TMP/checked ids trusted
B2: .git/objects                         → decision reads (brief_fields cat-file blob MAIN:PATH; own_blob; open_shared)  → verdict fields
B3: .git/objects via GIT_OBJECT_DIRECTORY → gate_git (merge-tree, diff-tree, --batch-check) in a repo with its own config      → merge result / path list
B4 (moved): repo config / objects/info/alternates → state_gate (now incl. alternates)                              → gate may run
```

```
S1: loose object files and fan-out dirs           — runtime-mutable (same-uid writer) — UNTRUSTED for verdict-integrity sinks (rows 492/503)
S2: pack dir entries (.pack/.idx/midx, any name)  — runtime-mutable (same-uid writer) — UNTRUSTED for verdict-integrity sinks
S3: .git/config keys outside STATE_KEYS_RE        — runtime-mutable                   — UNTRUSTED where they change object lookup
S4: $GATE_TMP/checked                             — written by store_check in a mktemp dir — trusted (same-process, private dir)
```

What changed: B1 now claims "one copy ⇒ every read gets the checked bytes". That claim holds only to the extent that the scan's enumeration of copies matches git's own lookup across B2 and B3. B3 runs with a different config (the gate repo's minimal config plus harden pairs) than B1/B2 (the real repo's config), so any lookup-affecting key not pinned by harden is a place where the two can diverge.

---

## Findings

#### F1. The one-copy scan enumerates copies differently from git's object lookup (dot-named packs, symlinked fan-out dirs, `core.multiPackIndex` divergence between real and gate repo)

**Severity:** Medium
**Location:** `scripts/build-loop.sh:176-182` of the diff (store_check's scan: `for p in "$o"/pack/*.idx`; `(cd "$o" && find . -mindepth 2 -maxdepth 2 ! -type d -path './[0123456789abcdef][0123456789abcdef]/*')`); `scripts/build-loop.sh:294` (`STATE_KEYS_RE`); `harden()` pairs; `gate_repo()` config
**Boundary:** B1 / B2 / B3
**Move:** #11 (bypasses of a new guardrail), #1 (two lookups over one source)
**Confidence:** Low (read-static; each depends on git-internals behaviour I did not execute on 2.39.5)
**Legibility-target:** for-author + for-orchestrator-synthesis

Evidence (verbatim, store_check):
```
  { for p in "$o"/pack/*.idx; do
      [[ -e "$p" ]] || continue
      git show-index --object-format="$fmt" < "$p" | awk '{ print $2 }' || exit 1
    done
    # From inside the store: a -path pattern would read glob characters in its path.
    (cd "$o" && find . -mindepth 2 -maxdepth 2 ! -type d -path './[0123456789abcdef][0123456789abcdef]/*') | awk -F/ '{ print $(NF - 1) $NF }'
  } | awk 'FILENAME != "-" { want[$0]; next } ($0 in want) && n[$0]++ { bad = 1 } END { exit bad }' "$GATE_TMP/checked" -
```
The fix's guarantee is that a checked id with one copy in the scan has one copy as git sees it. Three ways the scan's list may be shorter than git's:
1. **Dot-named packs.** Bash's `*.idx` does not match a name beginning with `.` (no `dotglob`). From my reading, git's pack-dir enumeration skips only `.` and `..` and adds any `*.idx` name. If so, a pack named `.x.idx`/`.x.pack` holding a second copy is invisible to the scan but visible to git.
2. **Symlinked fan-out directory.** `find` without `-L` does not descend into `./ab` when `ab` is a symlink to a directory, but git opens `objects/ab/<rest>` through the link. A loose second copy behind a symlinked fan-out dir would be missed. (The fact-check tested an *unreadable* fan-out dir, which fails closed. A symlinked one is a different case.)
3. **`core.multiPackIndex` divergence.** Neither `STATE_KEYS_RE` nor `harden` pins `core.multiPackIndex`. The real repository's reads (store_check, brief_fields) honour the repo's `.git/config`. gate_git's reads (merge-tree, diff-tree, the blob checks) run under the gate repo's minimal config, where the default applies. A copy reachable only through a multi-pack-index (a pack the midx names whose `.idx` is absent) would then be read by B3 but not by B1. The fact-check's "midx pack without .idx refuses" was run with the default config, so it does not cover this case.

None of these is demonstrated. I list them because the fix's comment asserts "With one copy every read gets the bytes checked here", and that is exactly the claim each of them would break. The actor is the same-uid writer that rows 492/503 declare in scope. The Floor rule keeps this at Medium even though each mechanism is unproven, and the doubt is carried in Confidence.

**Recommendation:** derive the copy list from git rather than from bash/find:
- Enumerate packs as git does: `shopt -s dotglob` or `nullglob`, or `git count-objects -v`, or a readdir of every `*.idx`, plus `multi-pack-index` contents via `git multi-pack-index verify`/refusal.
- Refuse a `multi-pack-index` and any symlinked fan-out directory in the state gate, the same way the alternates refusal works.
- Pin `core.multiPackIndex` in harden, so B1 and B3 agree.

Add one test per item.

#### F2. Skipping already-checked ids drops the per-brief re-hash of main's shared objects, so a persistent post-startup rewrite of a single copy goes undetected

**Severity:** Medium
**Location:** diff `scripts/build-loop.sh:164` (`awk 'FILENAME != "-" { seen[$0]; next } !($0 in seen) ...' "$GATE_TMP/checked" -`); check_line's `store_check "$sha" "$tree"`
**Boundary:** B1 / B2
**Move:** #4 (TOCTOU)
**Confidence:** Medium (read-static; consistent with the fact-check's stated residual)
**Legibility-target:** for-author + for-orchestrator-synthesis (Q-103 routing)

At 65007bf8, each brief's `store_check "$sha" "$tree"` re-read and re-hashed every object of the merge's result tree, and that tree shares all of main's unchanged blobs and trees. At 83f75281, those ids are in `$GATE_TMP/checked` from gate_start and are skipped.

The one-copy scan does still re-run over **all** checked ids on every brief, so a *second copy* added after startup is still caught. What it does not catch is a single-copy rewrite left in place: overwriting a loose object file of main, or bytes inside its pack, after gate_start. Before this fix, a rewrite like that, if it was still there at the next per-brief check, refused the brief. Now nothing re-hashes it for the rest of the run. Reads of main's objects after startup, such as brief_fields (`cat-file blob MAIN:PATH`) for briefs 2..N and the floor walk, consume those bytes.

So for an N-brief `--check`, the attack no longer needs to write and then restore within a narrow race. It only needs to write after startup. That is in the Q-103/R8 family, but it is a widening and it is not stated in the comment (the comment says only "an id already there (main's, from gate_start) is not read again").

**Recommendation:** either keep the skip and state the widened residual (any post-startup rewrite of main's objects goes undetected for the rest of the run) in the store_check comment and in Q-103, or drop the skip for the hash step and keep it only for the scan. The fix's own figure (0.3 s per pass) suggests re-hashing per brief is affordable.

#### F3. The comment's guarantee is stated categorically

**Severity:** Informational
**Location:** store_check header comment ("With one copy every read gets the bytes checked here"); plan step 7 as-built note
**Boundary:** B1
**Move:** #2
**Confidence:** High
**Legibility-target:** for-author

Given F1, the sentence asserts more than the scan establishes. Scope it to "one copy among the pack indexes the glob lists and the loose files find lists".

---

## Untested bypass candidates (move #11)

- Dot-named pack in `objects/pack/` (F1.1): not executed; it depends on git's readdir filter.
- Symlinked fan-out directory (F1.2): not executed.
- `core.multiPackIndex=false` in repo config with a midx-only copy (F1.3): not executed.
- REF_DELTA/OFS_DELTA base outside the checked set with two copies of the base: traced only. Git 2.39 resolves a REF_DELTA base inside the same pack via that pack's own idx (binary search), which is deterministic across processes, so I see no divergence. Not executed.
- A pack whose `.idx` lists one id twice: the scan counts every line, so this would refuse (traced). Not executed.
- `GIT_ALTERNATE_OBJECT_DIRECTORIES` / `GIT_OBJECT_DIRECTORY` from the invoker: the gate's existing refusal of set GIT_* variables covers these (traced, line ~780). Invoker env is trusted anyway.
- A race between the per-brief scan and the next brief's reads: Q-103 residual, accepted.

## Endorsement Claims

- **Claim:** the alternates refusal runs before any object is read: `state_gate` is called before `resolve_main`, and the alternates path is resolved with `--git-path`, so a linked worktree checks the common dir.
  **Location:** diff `scripts/build-loop.sh:66`, `:75-76`
  **Evidence:** read-static (test at bats:1630 executed by the fact-check run)
  **Verified:** the order in the top-level script; the `-s`/`-L`/non-file condition.
  **Not verified:** an alternates file added after state_gate and before store_check (race).
  **route: code-fact-check**

- **Claim:** the `FILENAME != "-"` split loads `$GATE_TMP/checked` before stdin even when `checked` is empty. The old `NR==FNR` idiom would have misread stdin as the want-list in that case.
  **Location:** diff `scripts/build-loop.sh:164`, `:182`
  **Evidence:** read-static
  **Verified:** awk semantics. `$GATE_TMP` is a mktemp path and is never "-".
  **Not verified:** awk implementations other than the one on this host.

- **Claim:** under `set -euo pipefail`, a failure of `show-index` or `find` in the scan's brace group makes store_check return non-zero, so the scan fails closed.
  **Location:** diff `scripts/build-loop.sh:176-182`; `set -euo pipefail` at line 223
  **Evidence:** read-static; executed by the fact-check (truncated/unreadable .idx, unreadable fan-out dir)
  **Verified:** pipefail is set; `|| exit 1` sits on the show-index pipe.
  **Not verified:** a `find` that succeeds but lists less than git sees (F1.2).
  **route: code-fact-check**

## Primitive sweep

Primitive: object-store enumeration/read used for an integrity decision
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| store_check `cat-file --batch` (diff :164-174) | S1/S2 by id | re-hash | cleared for ids read; skip → F2 |
| store_check `*.idx` glob + `show-index` (:176-178) | S2 | fail-closed on read error | F1.1, F1.3 |
| store_check loose `find` (:181) | S1 | fail-closed on read error | F1.2 |
| brief_fields `cat-file blob MAIN:PATH` (dev-cycle-read.sh) | S1/S2 | startup check only | F2 |
| gate_git merge-tree / diff-tree / `--batch-check` | S2/S3 (gate config) | none of its own | F1.3 |
| marker_kind parent, check_branch rev-list, merge bases | S1/S2 | none | iteration 1 F2, now documented in the comment as not checked: cleared as documented residual |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| F1 | One-copy scan's enumeration ≠ git's (dot packs, symlinked fan-out, midx config) | Medium | B1/B2/B3 | store_check scan; STATE_KEYS_RE; harden | Low |
| F2 | Skipping checked ids drops per-brief re-hash; persistent post-startup rewrite undetected | Medium | B1/B2 | store_check awk skip | Medium |
| F3 | Categorical "every read gets the bytes checked" comment | Informational | B1 | store_check comment, plan note | High |

## Overall Assessment

The fix closes the specific F1 shape that iteration 1 reproduced, and the fact-check's executed cases show the scan failing closed on read errors. Within the code paths I read, there are no findings in the alternates refusal or the FILENAME filter. The remaining risk is architectural, and it is about how copies are enumerated. The scan builds its own list of copies with bash glob and find, while git uses readdir, symlink-following opens and a config-dependent midx. The two can diverge, and the comment's guarantee depends on them agreeing (F1, all untested). The id skip widens the Q-103 window from "race" to "rewrite after startup" (F2). Both can be fixed in place: refuse a midx, a symlinked fan-out dir and dot-named pack entries in the state gate, pin `core.multiPackIndex` in harden, and either drop the hash skip or document it. This review was read-static, so: no confirmed exploit in the code paths read; endorsement claims pending execution verification.

## Goal-Alignment Note

User goal: land U3a1 through its review-fix loop. This review answers the dispatch question (does the one-copy rule close F1 for every way git picks bytes for an id): **for the reproduced shape, yes; for all shapes, not established.** F1's candidates should be probed or closed by state-gate refusals before the rows-492/503 claim is called closed. F2 is a Q-103 routing decision (widen the residual or drop the skip), not necessarily a blocker for U3a1.
