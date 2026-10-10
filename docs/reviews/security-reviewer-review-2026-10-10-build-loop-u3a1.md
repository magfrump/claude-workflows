# Security Review — feat/build-loop-u3a1

Commit: 65007bf8
**Scope:** branch diff `main...HEAD` — `scripts/build-loop.sh`, `test/scripts/build-loop-check.bats`; `scripts/lib/dev-cycle-read.sh` read for context (unchanged)
**Date:** 2026-10-10
**Based on:** `docs/reviews/code-fact-check-report-build-loop-u3a1.md` (k=1; 0 Incorrect, Claims 9 and 15 "Mostly accurate" on store_check coverage)
**Focus (per dispatch):** is the rows-492/503 threat model (a same-uid writer rewriting object files behind their ids, loose or packed) closed for *every* object whose bytes decide a verdict, in read order?

Lead with conclusions; the structured sections carry the detail.

**Bottom line:** the loose-object case is closed (fact-check Claims 1/19, executed). The **packed case is not**: store_check verifies objects by **object-id** through `git cat-file --batch`, but the decisions consume main's briefs by **tree path** through `git cat-file blob MAIN_SHA:PATH`. For a packed object forged under a genuine id these two git read paths **diverge**, so store_check re-hashes bytes that pass while the decision reads the forged bytes. A same-uid writer — the exact actor rows 492/503 and Q-103 scope in — can make the gate emit `ok` on a brief it never actually verified. Reproduced deterministically (5/5) on git 2.39.5.

---

## Trust Boundary Map

```
B1 (new): .git/objects loose+pack files  → store_check re-hash (cat-file --batch BY OBJECT-ID) → verdict integrity
B2:       .git/objects loose+pack files  → decision reads (cat-file blob MAIN_SHA:PATH; checkout) → verdict fields
B3:       repo-local config / refs / info → state_gate + gate_start                               → gate may run or refuse
```

B1 and B2 read the **same object store** but through **different git plumbing**: B1 resolves an id to bytes; B2 resolves a tree path to bytes. The unit's security claim is that B1's re-hash gates everything B2 consumes. The finding is that B1 and B2 can resolve the same id to different bytes.

Input-source classification (sink class = *verdict integrity* — whether the `ok`/`refuse` line reflects main's real committed bytes):

```
S1: .git/objects/<xx>/<rest> loose files   — runtime-mutable (same-uid writer) — UNTRUSTED (this is the defended threat; rows 492/503)
S2: .git/objects/pack/*.pack + *.idx       — runtime-mutable (same-uid writer) — UNTRUSTED (Finding 1's source)
S3: repo-local config / refs/replace/ /    — runtime-mutable (same-uid writer) — UNTRUSTED (state_gate/default_gate defend; pre-existing)
    info/attributes, origin/HEAD
```

The diff adds no network, auth, crypto-primitive or deserialization surface; the only trust boundary it moves is B1 (store_check, new). Per the unit's own threat model (override rows 492/503, Q-103's R8 family) a same-uid writer to the object store is **in scope** — store_check exists for no other reason — so S1/S2 are legitimately UNTRUSTED here even though same-uid write is host-level access (see Finding 1's confidence note).

---

## Findings

#### 1. store_check verifies by object-id while decisions read by tree-path; a forged *packed* object slips the re-hash

**Severity:** High
**Location:** `scripts/build-loop.sh:594-610` (store_check: `git cat-file --batch`), `:822` and `:879` (call sites); divergent consumer reads `scripts/lib/dev-cycle-read.sh:398,406` (brief_fields: `git cat-file blob "$MAIN_SHA:$1"`), `scripts/build-loop.sh:635,637` (own_blob)
**Boundary:** B1 / B2
**Move:** #1 (the verification path and the consumption path are different trust transitions over the same source), #4 (what is checked is not what is used)
**Confidence:** Medium
**Legibility-target:** for-author (close the gap or scope the claim) + for-orchestrator-synthesis (bears directly on the dispatch question)

The comment claims store_check catches "a same-uid writer that rewrites an object file behind its id **(loose or packed)**" (`:587-588`). store_check reads each object by feeding its id to `git cat-file --batch` (`:601`) and re-hashing the returned bytes. The decisions, however, read main's briefs by **tree path**: `git cat-file blob "$MAIN_SHA:$1"` in brief_fields (`scripts/lib/dev-cycle-read.sh:398`) and own_blob (`scripts/build-loop.sh:635`). These are two different git object-lookup code paths. When an object is forged inside a pack under a genuine id — the packed analogue of the loose-file rewrite the unit defends against — the two paths **do not agree**: the tree-path read returns the forged bytes, while `cat-file --batch` by id returns bytes that re-hash to the genuine id, so store_check reports no mismatch and the gate proceeds. The result is an `ok` verdict whose brief fields (Branch, Status) were taken from bytes the gate never verified.

Reproduction (throwaway repos under my scratch dir; scripts at `.../security/probes/{mru2,clean,idxswap,idxswap2}.*`):
- Committed an open brief naming `Branch: feat/x`, repacked, then placed a crafted pack mapping the genuine brief-blob id to forged content naming `Branch: feat/y`, with the forged pack newer (mtime).
- Observed: `git cat-file blob main:BRIEF` → `Branch: feat/y` (forged, what the decision reads); store_check's bulk `cat-file --batch` pipeline → the blob re-hashes cleanly, rc=0 (PASS); gate verdict → `ok … / path … work-feat-y.txt` — i.e. the gate accepted **feat/y**, the forged branch. Stable across 5 consecutive runs (`.../security/probes/mru2.log`, verdict-stability block).

Evidence (verbatim):
```
# scripts/build-loop.sh:601 (store_check — reads BY ID)
    done; } | awk '!seen[$0]++' | git cat-file --batch \
```
```
# scripts/lib/dev-cycle-read.sh:398 (brief_fields — reads BY PATH; the bytes the verdict uses)
  out="$(git cat-file blob "$MAIN_SHA:$1" | env LC_ALL=C awk "$FENCE_AWK"'
```
Probe transcript (`.../security/probes/mru2.log`):
```
== cat-file blob main:...x.md (process 1)
Branch: feat/y
== store_check in isolation (sourced), echo rc
checked 7 objs
store_check-pipe rc=0
== gate verdict
ok docs/working/briefs/2026-10-01-x.md 9580fb3c… edba5247…
path docs/working/briefs/2026-10-01-x.md A work-feat-y.txt
```

Scope / honesty bounds (why Confidence is Medium, not High):
- The crafted pack is flagged corrupt by `git fsck` ("packed … is corrupt"), but **the gate never runs fsck**, and the comment itself says "only fsck would notice" — so fsck's objection does not help the gate.
- The precise divergence (why `cat-file --batch` by id and `cat-file blob` by path pick different bytes for one id when a genuine and a forged pack coexist) is a git-internals pack-preference behavior; I confirmed it on git 2.39.5 only. The *observable bypass* is stable, but its exact mechanism may vary by git version and pack layout, so I cannot assert it holds on every git.
- The actor must already have same-uid write access to `.git/objects`. By the skill's reachable-environment caveat this is near host control; however this unit **declares that actor in scope** (rows 492/503, Q-103/R8), so demonstrating store_check is bypassable for it is on-target rather than out-of-scope. The orchestrator/human should weigh severity against that declared model.

The bats test (`test/scripts/build-loop-check.bats:1856-1877`) exercises only (a) a **loose** forgery of main's tree, (b) a missing loose object, (c) a loose forgery of the tip's file, and (d) a *clean* `git repack -adq` pass. It never forges a **packed** object under a genuine id — exactly the case that fails — so the "loose or packed" claim is tested on the loose half only.

**Recommendation:** either (a) make store_check read by the **same path** the decisions use (re-hash `MAIN_SHA:PATH` / the tip tree-path bytes, i.e. verify the representation actually consumed), or (b) run `git fsck --connectivity-only`/object integrity over the packs the decision will read, or (c) narrow the comment and the plan to claim only the loose case and move the packed case to Q-103's residual with a test pinning the current (unsafe) behavior so the gap is auditable. A regression test that forges a packed object under a genuine id should accompany whichever path is taken.

#### 2. Objects a decision reads via the tip's ancestors are not re-hashed (parent commit/tree, ahead-count commits, merge bases)

**Severity:** Low
**Location:** `scripts/build-loop.sh:478,487` (marker_kind reads `${p[1]}` and `${p[1]}^{tree}`), `scripts/lib/dev-cycle-read.sh:493` (check_branch `rev-list --count MAIN_SHA..sha`), `scripts/build-loop.sh:617-621` (merge_result merge-base + merge-tree); store_check call `:879` covers only `"$sha" "$tree"`
**Boundary:** B2
**Move:** #1 (coverage grain of the verification boundary)
**Confidence:** High
**Legibility-target:** for-author

`store_check "$sha" "$tree"` (`:879`) re-hashes the tip commit, the tip tree and the merge-result tree, but several objects whose bytes still steer a verdict are read without a re-hash: the tip's **parent** commit and its tree (marker_kind's "bad it changes files" compares `$1^{tree}` to `${p[1]}^{tree}`, `:487`), the commits `rev-list --count` walks for the ahead count (`dev-cycle-read.sh:493`, which `check_line:848` refuses on), and the **merge bases** and their trees `merge_result` feeds to merge-tree (`:617-621`). A same-uid writer forging a parent tree could make a tip that does change files read as a clean marker (ready/blocked/stopped); forging a merge base changes which merge result is computed — the result tree then re-hashes fine (it is a real tree) but is the wrong merge. This is the residue fact-check Claim 9 marked "Mostly accurate"; the commit message calls out the merge-base exclusion ("the result the rules judge is") but not the parent/ancestor reads.

**Recommendation:** state the boundary of store_check's coverage in the comment ("REV, its tree and every tree and blob below it — not REV's ancestors, parents or merge bases") and record the ancestor/parent reads alongside the merge-base exclusion in Q-103's residual, so the unchecked reads are enumerated rather than implied closed by "every object a decision reads from REV."

#### 3. Comment and plan claim "loose or packed" / "every object a decision reads from REV" — broader than the code enforces

**Severity:** Informational
**Location:** `scripts/build-loop.sh:585-591` (store_check header), `docs/working/plan-build-loop-handoff.md:317`
**Boundary:** B1 (documentation of the boundary's strength)
**Move:** #2 (assumed-elsewhere guarantee)
**Confidence:** High
**Legibility-target:** for-author

Consequence of Findings 1–2 at the documentation layer: a comment that states a stronger invariant than the code establishes is how a later unit (U3a2's `--merge`, which builds directly on this verdict) inherits a false sense of closure. fact-check already verdicted the headline "every object a decision reads from REV" Mostly accurate (Claim 9) and the repository-rule omission of store_check Mostly accurate (Claim 15).

**Recommendation:** fold into Finding 1's fix; whichever path is chosen, the comment should describe exactly what is re-hashed and by which read path.

---

## Endorsement Claims

- **Claim:** The re-hash perl is length-prefixed and cannot be desynced by crafted object *content* — a `NAME missing` line fails the header regex (`exit 1`) and body bytes cannot forge a `OID type SIZE` header because each record's length comes from cat-file, not the content.
  **Location:** `scripts/build-loop.sh:603-607`
  **Evidence:** read-static (+ probe-observed on missing/forged objects in `.../security/probes/mru2.log`)
  **Verified:** the regex `^([0-9a-f]+) ([a-z]+) ([0-9]+)\n\z`, the `read(STDIN,$b,$s)==$s` exact-length read and the `getc eq "\n"` trailing-newline guard; a missing object yields a 2-token line that fails the regex.
  **Not verified:** cat-file's framing under an object whose declared size overflows perl's `read` on a >2GiB blob (not exercised).
  **route: code-fact-check**

- **Claim:** `git cat-file --batch` returns raw object bytes with no filter/textconv/eol conversion, so store_check running in the real repository (not through gate_git) cannot have its hashed bytes altered by repo config.
  **Location:** `scripts/build-loop.sh:594-601`
  **Evidence:** read-static
  **Verified:** store_check uses bare `git ls-tree`/`git cat-file --batch`; `--batch` emits stored object bytes; harden() + state_gate already neutralize filter/attr/replace config before this runs.
  **Not verified:** that no git 2.x applies `.gitattributes` to `cat-file --batch` output (documented not to, not re-proven here) — the nearest unread hop.
  **route: code-fact-check**

- **Claim:** Dropping check_line's old branch re-read ("moved or could not be read again") introduces no verdict-integrity regression, because every downstream step keys off the single captured `sha`, `--expect SHA` pins it, and U3a2's `--merge` re-runs the state gate + a CAS before the ref moves.
  **Location:** `scripts/build-loop.sh:843-850`
  **Evidence:** read-static
  **Verified:** `sha="${STATUS[sha]}"` captured once; `merge_result "$sha"` and `store_check "$sha" "$tree"` both use it; `EXPECT` compared at `:849`.
  **Not verified:** U3a2's `--merge` CAS/state-gate-replay path (lives in the next unit, not this diff) — the nearest unread hop.
  **route: code-fact-check**

---

## Primitive sweep

Engaged primitive: **object-store read used for an integrity decision** (`git cat-file` / `ls-tree` / `hash-object`). The security question for each site is whether the bytes it reads are gated by store_check's re-hash.

Primitive: object-store read (verdict-deciding)
| Call site | Source | Guard (re-hashed?) | Disposition |
|---|---|---|---|
| `scripts/build-loop.sh:601` store_check `cat-file --batch` | S1/S2 by id | n/a (it *is* the guard) | reads BY ID — diverges from path reads → Finding 1 |
| `scripts/lib/dev-cycle-read.sh:398` brief_fields `cat-file blob MAIN:path` | S1/S2 by path | main's tree re-hashed in gate_start (`:822`) — but by id, not path | Finding 1 (packed divergence) |
| `scripts/build-loop.sh:635,637` own_blob `cat-file blob` + `hash-object` | S1/S2 by path | same as above | Finding 1 |
| `scripts/lib/dev-cycle-read.sh:509` open_shared `git grep MAIN` | S1/S2 by path | main's tree re-hashed (by id) | Finding 1 (same divergence; blobs enumerated here feed `skip` dedup) |
| `scripts/build-loop.sh:478,487` marker_kind parent commit/tree | S1/S2 | NOT re-hashed (parent outside `sha`/`tree`) | Finding 2 |
| `scripts/lib/dev-cycle-read.sh:493` check_branch `rev-list --count` | S1/S2 | NOT re-hashed (ancestors) | Finding 2 |
| `scripts/build-loop.sh:617-621` merge_result merge-base/merge-tree | S1/S2 | result tree re-hashed; **bases NOT** | Finding 2 (bases); result tree cleared |
| `scripts/build-loop.sh:874` check_line blob batch-check (merge ids) | S2 | objecttype only, then result tree re-hashed `:879` | cleared — existence+type check, moved earlier this diff, behavior unchanged (fact-check Claim 5) |
| `scripts/build-loop.sh:806-836` checkout_gate checked-out bytes | S1/S2 | separate blob-equality check; self-merge only | cleared for this diff — pre-existing, unchanged |

---

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | store_check reads by object-id (`cat-file --batch`) while decisions read by tree-path (`cat-file blob`); a forged packed object slips the re-hash → gate emits `ok` on unverified bytes | High | B1/B2 | `build-loop.sh:594-610,822,879`; `dev-cycle-read.sh:398` | Medium |
| 2 | Parent commit/tree, ahead-count commits and merge bases are read but not re-hashed | Low | B2 | `build-loop.sh:478,487,617-621`; `dev-cycle-read.sh:493` | High |
| 3 | "loose or packed" / "every object a decision reads from REV" comment broader than enforced | Informational | B1 | `build-loop.sh:585-591`; `plan:317` | High |

---

## Overall Assessment

The refactor half of this unit (status_fields replacing status_line, the single gate_start startup, the moved blob batch-check) is sound: fact-check established byte-identity of every `--status` line and no lost re-read guarantee, and I found no new injection, error-path or resource surface in it. The security half — store_check — correctly closes the **loose**-object rewrite that motivated rows 492/503, and its perl re-hasher is robust against content-driven desync. But its central claim, that the same defense extends to **packed** objects, does not hold as written: store_check verifies objects by id through `cat-file --batch`, a different git read path than the `cat-file blob MAIN_SHA:PATH` the decisions actually consume, and for a packed object forged under a genuine id the two paths diverge, letting a same-uid writer — the unit's declared adversary — drive an `ok` verdict from bytes the gate never verified (reproduced 5/5 on git 2.39.5). This is fixable in place (verify the representation the decisions read, or fsck the packs) rather than an architectural dead end, and the honest interim is to pin the packed case as an open Q-103 residual with a test, not to let the "loose or packed" comment assert a closure the code does not deliver. **The single most important thing to address is Finding 1** — it is the exact question the dispatch posed, and it governs what U3a2's `--merge` is allowed to assume before it moves main. Because every Endorsement Claim is scoped with its `Not verified` hop (none is `executed`-complete for the packed path) and Finding 1 is open, this review does not issue an all-clear: no findings-free verdict within the packed read path; the loose path and the refactor are clean within the code paths read, and the endorsement claims are pending execution verification.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the path your dispatch names, structured per your skill.
- Answered: yes — report saved at the dispatched path with Commit 65007bf8; the dispatch's focus question (is the packed/loose threat model closed in read order) is answered: loose yes, packed no (Finding 1), with the before-store_check / ancestor / merge-base reads dispositioned (Finding 2, primitive sweep).
- Out of scope: the status_fields byte-identity and set -u correctness (relied on from fact-check Claims 8, verified there, not re-run); U3a2's `--merge` CAS path (next unit, not in this diff).
- Escalate: Finding 1 to synthesis as the load-bearing item for whether U3a1 may merge and what U3a2 inherits; its Medium confidence reflects git-version-specific pack-preference internals, not doubt about the observed bypass.
- Decisions I made: treated the same-uid object-store writer as in-scope (the unit declares it so via rows 492/503 and Q-103) rather than dismissing it under the skill's "already controls the host" caveat — the defensible alternative was to rate Finding 1 Informational as host-level-precondition.
