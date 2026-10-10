Commit: 8f99fcaf

# Architecture Review — feat/build-loop-u2b3b2b (U2b3b2b, final confirming pass)

**Scope:** `git diff main...HEAD -- scripts test` (whole branch: 1c820663, 39f64d62, 8f99fcaf), plus the plan's U2b3b2b/U2b3b2c bullets and the branch's override rows. The functions were read in full: `outside_seeds` (`scripts/lib/dev-cycle-read.sh:1258-1344`, header 1226-1257), `with_at` (1214-1225), `root_starts` (1210-1213), `outside_ok`, `outside_proj`, `import_outside`, `import_file`, both walks, the walk header (735-764), `isstart`/`prompt_dir`/`prompt_bases` (645-678), `scan`'s comment (937-938), and contract items 1-9.
**Date:** 2026-10-09
**Based on:** shared brief `u2b3b2b-final/shared.md`; merged fact-check `docs/reviews/code-fact-check-report-build-loop-u2b3b2b-final.md` (Commit: 8f99fcaf); my earlier reports `architecture-review-2026-10-09-u2b3b2b.md` and `-i2.md`; override-log rows 579-586. I ran one probe (prefix `/tmp/u2b3b2b-farch-`, removed). It reproduces Claim 21 and checks the fix proposed in Finding 1.

Scope check: in scope. The branch adds three lib functions (`outside_seeds`, `root_starts`, `with_at`), extends `outside_proj`'s role, adds a walk input (`IMPORT_MANAGED_DIR`), and changes contract item 4.

Trust-boundary cross-reference: the most recent security review is `docs/reviews/security-review-2026-10-09-u2b3b2b-i2.md` (Commit: `39f64d62`). Its `B1` is "[other reader roots' working trees (find -P)] → [root_starts → isstart(innermost-root path) → @/link filter → rawfile+sha1sum skip] → [walk seeds (C1)]". That review predates 8f99fcaf, so the boundary may be stale: since B3, the isstart step reads the whole path, not the innermost-root path (fact-check Claim 19).

## Iteration-2 findings: verification

| i2 finding | Status at 8f99fcaf |
|---|---|
| 1: the @ filter relies on scan's @ trigger, with no cross-reference | **Fixed.** `with_at`'s header (1216-1218) names scan, and scan's comment (937-938) names the filter. The test for the link half is still missing; see Finding 3. |
| 2: early C1 `return 0` skipped the newline check; `fl`/`os_at` carried over between phases | **Fixed.** The early return is gone. `with_at` resets its output (`wa_a=()`), and each phase guards `lo`/`rl` with `=()` before its fill. The one newline check (1343) now covers both phases. `os_at` still spans both phases, but the property it records belongs to the path itself, so the carry-over is harmless. |
| 3: the @-filter wrapper was inlined twice | **Fixed.** `with_at` is one helper, called at 1306 and 1331. It also owns admission (`outside_ok`) and the grep status rule. |

## Dependency Map

- `imported_names` / `main_imports` → `import_readers`, then `outside_seeds` → {`root_starts` → `find -P` + `instruction_names`; `with_at` → `outside_ok` + `nul_list` + xargs/grep; `isstart`, `PROMPT_DIR`, `rawfile`, `lower_all`, `realpath`, `sha1sum`, `python3`}. The walks consume the seeds through `outside_ok` and `import_file` → `import_outside`, and project names through `outside_proj`.
- Dependencies point from the walks down to leaf helpers. Nothing depends upward, and there is no cycle. `root_starts` and `tree_starts` have the same shape (a listing piped into `instruction_names`).
- There is one lateral dependency that is not a call. The C1 byte skip (1337) is a claim about how the walks would read ROOT_REAL's copy of a file: it asserts the walks start at that copy and read it the same way. Finding 1 is about that dependency.

## Findings

#### 1. The C1 byte skip's equivalence key leaves out the read mode (prompt vs file), so the skip drops a seed that the walks would read differently

**Severity:** Coupling
**Location:** `scripts/lib/dev-cycle-read.sh:1333-1337` (code); `:1237-1245` (header: Claims 19 and 12, stale and incomplete)
**Move:** 7 (coupling surface), 2 (responsibility)
**Confidence:** High (executed; fact-check Claim 21, reproduced here)
**Legibility-target:** for-author: outside_seeds' C1 loop and its header

Evidence:
```
    isstart "${lo[i]}" && [[ -n "${os_at[${cx[i]}]+set}" || -L "${cx[i]}" ]] || continue
    c=f; [[ ! "${lo[i]}" =~ $PROMPT_DIR ]] || c=p
    # rawfile: a ROOT_REAL copy reached through a link the tree walk does not start at (i1 fact-check 19b).
    # isstart on the inner path's tail of lo: ROOT_REAL's copy must be a start there too.
    if [[ ! -L "${cx[i]}" ]] && isstart "${lo[i]:${#lo[i]}-${#ir[i]}}" && rawfile "${ir[i]}" && outside_ok "${cx[i]}"; then sp+=("$c${cx[i]}"); hs+=("${cx[i]}" "${ir[i]}"); else os_a+=("$c${cx[i]}"); fi
```
(The excerpt ends inside the loop. The remainder, 1338-1344, compares the `sha1sum` of each pair and appends to `os_a` only the pairs whose hashes differ, then runs the newline check.)

```
# whose files that listing drops: then it is listed itself (and a root below
# it twice, which the walks' seen absorbs). One whose bytes equal ROOT_REAL's
# plain file (rawfile) at that path is skipped: the parser joins that file's
# names under every root and the walks start there too
```

The skip is only sound if "the walks read ROOT_REAL's copy exactly as they would read this seed". That takes three things: equal bytes, the same start membership, and the same read mode (a `p` seed is also read against `prompt_bases`). The code keys the skip on bytes and on start membership at the inner path. But it takes the seed's class `c` from the whole path. Because `PROMPT_DIR` matching the inner path implies matching the whole path, the classes can disagree in only one direction: a prompt by the whole path but a plain start at the inner path. A worktree nested under another root's `.claude/skills/` (or `commands/`, `agents/`, `output-styles/`) produces exactly that. My probe set up a `side/sub/.claude/skills/wt/CLAUDE.md` with ROOT_REAL's bytes, `@docs/z.md`. With the lib as it stands, both walks answer `sub/docs/z.md -`. With the skip also requiring the inner path's class to equal `c`, both answer `sub/docs/z.md imported`, and `docs/z.md` and the negative control are unchanged.

The structural point is this. The skip is a fourth local copy of "what the walks start at and how they read it", after `isstart`, the walks' `prompt_dir` calls and the C1 tagging. Each iteration has changed one copy and broken the skip's equivalence:
- i1 fact-check 19b: link admission, fixed with `rawfile`.
- i2 B3: the whole-path start test, patched with the inner-path `isstart`.
- this pass: the read mode.

The header has also drifted at this point. It still says isstart reads "its path below its innermost root" (Claim 19), and its skip sentence omits the `! -L` and inner-start conditions (Claim 12). Nothing in this repository's layout triggers the gap today (fact-check scope). In the floor's direction, though, it is a missed import, not an over-read.

**Recommendation:** In this unit, derive the skip from one function that returns the read class of a lower-cased path (`none`/`f`/`p`, beside `isstart`). Then skip only when the inner path's class equals `c`. The probe's variant is two lines: `il=...; ic=f; [[ ! "$il" =~ $PROMPT_DIR ]] || ic=p` and `"$ic" == "$c"` in the condition. Add a fixture beside the nested `.claude/skills/wt` case: a `CLAUDE.md` with ROOT_REAL's bytes whose relative name only a prompt base reaches. Rewrite the header's C1 sentence to the whole-path rule and list all four skip conditions. Alternatively, name the case as an exception in the walk header and the override log. That costs nothing now but leaves the coupling in place.
**Security implication:** none on placement. The fix narrows the skip at B1's existing transition point ("rawfile+sha1sum skip", from `docs/reviews/security-review-2026-10-09-u2b3b2b-i2.md`, Commit: `39f64d62`; that review predates this diff, so the boundary may be stale), so more seeds pass. Nothing moves across the boundary.

#### 2. The U2b3b2c split boundary leaves two mechanisms comparing another root's copy with ROOT_REAL's: the C1 start-level byte skip here, and U2b3b2c's planned name-level comparison

**Severity:** Minor
**Location:** `docs/working/plan-build-loop-handoff.md:307` (U2b3b2c bullet), `:306` (U2b3b2b plan text, stale per fact-check Claim 1); `scripts/lib/dev-cycle-read.sh:1337-1342`; walk header `:750-752`
**Move:** 2 (responsibility boundaries), 8 (extension points)
**Confidence:** Medium
**Legibility-target:** for-author: the U2b3b2c plan bullet

Evidence:
```
Name-driven fix: for each repo name a walk reaches, also read each other present root's copy when ROOT_REAL lacks it or its bytes differ (one batched comparison per file read).
```
```
# root reaches there through a file that root holds with other bytes or alone
# (routed to U2b3b2c);
```

U2b3b2c's planned mechanism runs a per-name "other root's copy vs ROOT_REAL's copy" comparison. The C1 skip is that same comparison, applied to start files only and keyed differently (whole-path class vs inner path; see Finding 1). If U2b3b2c lands as planned beside the C1 skip, the lib gets two implementations of one rule: "when does another root's file read differently from ROOT_REAL's?" They would need to agree on bytes, links, and start and read class, and Finding 1 shows how easily one copy drifts. The split itself is sound. The seed-everything attempt (6,720 seeds) shows the name-driven route is the right home. But the bullet does not say which unit owns the comparison. The plan text for U2b3b2b is also stale against the code: it still says `plugins/cache/**.md`, and it lacks the nesting rule's below-ROOT_REAL case and the iteration-2 changes (fact-check Claim 1).

**Recommendation:** Add one sentence to the U2b3b2c bullet: U2b3b2c's comparison owns "another root's copy differs from ROOT_REAL's", and C1's byte skip becomes a call to it, or is removed if seeding the equal-bytes starts proves cheap. Its revisit trigger already fires there, because U2b3b2c edits `outside_seeds` (override rows 582 and 585). Bring the U2b3b2b plan text up to date with the code.

#### 3. "Can this seed yield a name?" is spelled twice with different link rules, and only the @ half is pinned by a test

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:1309-1311` (config phase), `:1333` (C1 phase), `:937-938` (scan's comment), `:1214-1218` (with_at's header)
**Move:** 7 (coupling surface)
**Confidence:** High (read; test inventory checked)
**Legibility-target:** for-author: outside_seeds, or a named predicate beside with_at

Evidence:
```
    in=""; [[ -z "${os_at[${cx[i]}]+set}" ]] || in=1
    [[ -n "$in" || "${rl[i]}" == "${cx[i]}" ]] || for q in "${rs[@]}"; do [[ "${rl[i]}" != "$q"/* ]] || in=1; done
```
```
    isstart "${lo[i]}" && [[ -n "${os_at[${cx[i]}]+set}" || -L "${cx[i]}" ]] || continue
```
```
# performance F1; confirming security F2, F4). Every name starts at an @
# byte: outside_seeds drops a seed holding none (with_at leans on this).
```

The two phases decide the same question differently:
- A config seed reached through a link is kept only when its real path lies below a reader root (L1).
- A C1 seed is kept for any link.

Both rules are supersets and both are safe. The C1 rule is just broader. But the rationale (an @-free file can yield a name only through `import_outside`'s IMPORT_WHOLE projection of its real path) is stated once, in the config branch's comment. The C1 branch does not mention it. Scan's comment, "Every name starts at an @ byte", is true of file text. It is not true of IMPORT_WHOLE input (fact-check Claim 11), and that projection is exactly the link half these predicates exist for. No test pins the link half. The C1 fixture's link (`CLAUDE.md -> docs/l.md`) points at a file holding `@`, so `with_at` admits it anyway. No config fixture has an @-free link into a root. My iteration-2 Finding 1 recommended this test, and it is still open.

**Recommendation:** When outside_seeds is next split (override row 585), use one predicate for both phases, for example `may_yield PATH REALPATH`, with the link rule written once. Qualify scan's comment: "in file text; IMPORT_WHOLE input (a link's real path) is kept by the link rule". Add one fixture: an @-free config `CLAUDE.md` linked to a repo file, which both walks must answer as imported.

## Deferred items (override rows 579-586)

- **579** (U2b3b2c, other roots' differing non-start files): the basis is unchanged. Finding 2 adds an ownership note.
- **580** (A5, symlinked directories in another root): unchanged. `root_starts` still lists with `find -P`.
- **581** (config dirs outside `import_readers`' key): the basis is unchanged. Contract item 4 and the `IMPORT_MANAGED_DIR` reset line (1062) are accurate.
- **582/585** (outside_seeds' size; split deferred, reason amended): the function is now 87 lines (1258-1344). The amended basis holds. Finding 1's defect sits in the C1 loop's own key, not in state crossing between phases, and the phase-crossing defects from i2 are fixed. The revisit trigger will fire at U2b3b2c (Finding 2).
- **583** (seeds recomputed per walk): unchanged.
- **584, 586** (Won't-Fix): unchanged.

## What Looks Good

- `with_at` is a clean leaf. It holds admission (`outside_ok`), the @ filter and the grep status policy in one place, its header names its dependency on the parser, and it always resets its output. This closes the phase-crossing class of defect from iteration 2.
- The phases now guard their own empty lists (`lo=()`, `rl=()` before conditional fills), and a single newline check at the end covers every seed. The function's tail invariant is again a tail invariant.
- The config realpath now runs in xargs batches, the same way `with_at` reads, so both config-tree passes scale the same way.
- `root_starts` still lists with the file system only (never `git -C`), and the C1 test's git shim pins that. That keeps B1's source untouched by a loop-controlled `.git`.
- The walks consume seeds through the same `outside_ok`, `import_file` and `outside_proj` path as second-channel names. Seeds added no new read path into the parser.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | C1 byte skip omits the read mode (prompt vs file) from its equivalence key; header stale at the same point | Coupling | `scripts/lib/dev-cycle-read.sh:1333-1337, 1237-1245` | High |
| 2 | U2b3b2c's planned name-level comparison and C1's byte skip would be two owners of one rule; plan text stale | Minor | `docs/working/plan-build-loop-handoff.md:306-307`; `dev-cycle-read.sh:1337-1342` | Medium |
| 3 | "May yield a name" spelled twice with different link rules; scan's @ comment overstates; link half untested | Informational | `scripts/lib/dev-cycle-read.sh:1309-1311, 1333, 937-938` | High |

## Overall Assessment

The branch keeps the lib's structure sound. Dependencies flow from the walks to leaf helpers, seeds reuse the walks' existing outside-read path, and the iteration-2 fixes (`with_at`, per-phase guards, one tail check) removed the phase-crossing state I flagged. The one structural concern is Finding 1. The C1 byte skip is an assertion about how the walks would read another file, built from local copies of the start and class rules, and every iteration has broken it once. The current break (the read mode) is fixable in place with a two-line condition, which I verified by probe, plus a header rewrite. Finding 2 keeps that comparison from forking again in U2b3b2c. I do not disagree with the security review's boundary placement. Its B1 description (commit 39f64d62) still names the innermost-root isstart step, which 8f99fcaf replaced with the whole-path test; that is for the security reviewer to refresh.

## Goal-Alignment Note

- Success criterion (verbatim): "a markdown report saved at the path your dispatch names, structured per your skill, with a Goal-Alignment Note."
- Answered: yes. Saved at `docs/reviews/architecture-review-2026-10-09-u2b3b2b-final.md`, with first line `Commit: 8f99fcaf`.
- Bearing on the user goal (land U2b3b2b after a clean loop): Finding 1 is Coupling (🟡 Must Address under the rubric mapping). Its in-unit fix is small and verified, or it can be named as an exception with an override row. Findings 2 and 3 are 🟢 Consider: plan text, a comment and one fixture.
- Out of scope: review artifacts under docs/reviews/, and timings and suite counts (the fact-check's).
- Escalate: Finding 1, together with fact-check Claim 21, to the orchestrator.
