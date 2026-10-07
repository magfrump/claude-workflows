Commit: 0bb98f27

# Architecture Review — feat/build-loop-u2a3 (loop 2, iteration 3, final confirming pass)

**Scope:** `git diff main...HEAD` (base 62d366a7, HEAD 0bb98f27). The structural review covers `scripts/lib/dev-cycle-read.sh`: the header :29-35, the walk comment block :452-474, `untracked_md` :517, `nul_list` :519, `main_imports` :550-615 and `isimported` :621-630. The plan (F11, the U2a3/U2a3c/U2b bullets), known issue A5, the tests and the override log were read for context.
**Date:** 2026-10-06
**Based on:** the iteration-3 fact-check summary (replicates `docs/reviews/code-fact-check-report-build-loop-u2a3-L3-r1.md`, `-r2.md`, `-r3.md`, Commit 0bb98f27; no Incorrect). Trust boundaries come from `docs/reviews/security-reviewer-review-2026-10-06-L2f-build-loop-u2a3.md` (Commit: 1898d21c). That review predates this diff (99cce51b and 0bb98f27 came later), so its boundaries may be stale. The skill's `security-review-*.md` glob matches only older digest reviews, so this report uses the branch's own security review instead.

**Scope check:** in scope. The diff adds a public lib function (`main_imports`), a new `isimported main` selector, a shared helper (`nul_list`, which U2a3b reuses) and module globals with a cache contract (`IMPORTED_MAIN`, `IMPORTED_MAIN_DONE`).

**Settled rows not re-filed:** two-phase walk (taken as the split), cache ignoring checkout state (row :372), errexit off inside `isimported main` (:374), link_target helper and the not-covered list in three places (:375), no reason word on a failed walk (:376), unsearchable checkout directory (:383), the deep-token cost (:386), untested git-hardening bypasses (:387), `working-tree-encoding`/`filter` (:391) and `core.symlinks=false` (:392) deferred to U2b, the unreachable `*)` arm (:393). Finding 1 below is not a re-file of :391 or :375. It concerns how U2b's planned refusal is *shaped*, and it rests on new evidence: the fact-check r1 probe shows `ident` passes the walk. Neither row covers that.

**Probes:** none run beyond reading. The fact-check replicates executed the shapes this report relies on. Scratch dir `/tmp/u2a3-arch3-i3-FLAT` was created and left empty. No processes were started.

## Status of the loop-2 iteration-2 architecture findings

| L2f # | Status at 0bb98f27 | Where |
|---|---|---|
| 1 `ent` assumes a prefix-free namespace (tree+symlink doubled name passes) | Fixed | lib :566, a memoised ancestor pass after the record loop. Override row :390 records it. The fact-check re-probed doubled trees, tree+gitlink, tree+blob, unsorted names and a `.` subtree, and every case fails closed. |
| 2 Two checkout listings, pathspec duplicated | Partly taken | lib :567 is now one `ls-files --cached --others` call. No named helper was added, so the pathspec is now written twice: in `untracked_md` (:517) and inline at :567. See Finding 3. |
| 3 Index precondition masks refusals in tests | Fixed for tests 5, 9 and 12; one new mask remains | The fact-check (r3) found that test 10's tree-listing refusal (:565) is masked by a stale index `docs/CLAUDE.md`. That belongs to test-strategy and is not re-filed here. |

## Dependency Map

- `scripts/lib/dev-cycle-read.sh` is a leaf that `dev-cycle.sh` and `build-loop.sh` source. Nothing calls `main_imports` or `isimported main` yet. `dev-cycle.sh:181` calls only `isimported tree`. U2a4's floor will be the first caller. The new code depends on:
  - lib primitives: `need_root`, `main_by_name`, `nul_list`, `blocker`, `lower`, `INSTRUCTION_FILE`
  - the shared parser `import_targets`
  - git plumbing: `ls-tree`, `ls-files`, `cat-file`

  No dependency points outward. The dependency direction is unchanged from main.
- `main_imports` has this shape at HEAD:
  - **Index of main** (:557-566): the record loop builds `ent` (path → mode) and enforces three invariants: unique names (:561), no newline in a name (:561), and no name that is an ancestor of another (:566). Start candidates are tagged `m:`.
  - **Checkout listing** (:567-568): one listing. Every `.md` the checkout lists that `ent` lacks is tagged `t:`.
  - **Start loop** (:571-577): a `t:` start fails the walk. `m:` starts seed `seen` and `queue`.
  - **Drain loop** (:579-614): a dispatch on `ent[$f]` with a fail-closed default `*)`, then one producer.
- **Boundaries** (labels from the L2f security review, Commit 1898d21c, may be stale):
  - B1 (tree records → `ent`) is now fully enforced at construction.
  - B3 (checkout reads) still leads only to `return 1`.
  - B4 (git's checkout transform) has no check in the walk by design. It is delegated to U2b, which Finding 1 is about.

## Findings

#### 1. U2b's planned checkout-conversion refusal is a denylist of named attributes, and `ident` already escapes it

**Severity:** Minor
**Location:** `docs/working/plan-build-loop-handoff.md` U2b bullet (diff hunk @@ -273, the "U2b is to refuse ... `working-tree-encoding` or `filter` ... or whose `core.symlinks` is false" sentence); F11 row; `docs/working/known-issues-dev-cycle.md` A5 ("checkout conversions ...: a `working-tree-encoding` or `filter` attribute ..., and `core.symlinks=false`"); lib :470 ("checkout conversions (A5)")
**Move:** 3 (module boundary: where the B4 invariant is owned), 8 (extension point: denylist vs allowlist)
**Confidence:** High that `ident` is missing from the set (fact-check r1 executed it). Medium that other unnamed conversions exist.
**Legibility-target:** The U2b author, who will implement the refusal, and the author of this unit, who owns the A5/F11 wording.

**Evidence:**
- Fact-check r1, as carried by the iteration-3 summary: blob `@docs/x$Id$` with `ident` set in main's `.gitattributes` is checked out as `@docs/x$Id: <sha> $`. The walk reports `ok` and records `docs/x$Id: -`. So the bytes Claude Code reads differ from the blob the walk read.
- The plan's U2b bullet names exactly three triggers: `working-tree-encoding`, `filter` and `core.symlinks=false`. A5 and F11 name the same three.
- The lib header defers the list to A5 (:470, "checkout conversions (A5)"). The lib therefore holds no list of its own, which is good.

The walk's whole premise (the L2f security map's B4 note) is that `cat-file blob MAIN:path` equals the bytes on disk in the gate's checkout. U2a3 does not enforce that premise. It hands enforcement to U2b, and the plan writes that hand-off as a list of known-bad conversions. A denylist at this boundary has to grow every time a reviewer finds a new conversion. `ident` is the first one found after the list was written. Others plausibly exist, such as `eol`/`text` with `core.autocrlf` and `filter=lfs` under a host LFS config (:393), and each of them would need its own fail-open probe to be discovered. The structural cost is that B4's invariant has no single owner: the denylist is spelled out in two documents (A5 and F11), and the plan bullet adds a third copy. Each copy has to be kept in step by hand, as row :375 already notes for the not-covered list.

**Recommendation:** In this unit, add `ident` to A5 (F11 and the U2b bullet can point to A5 instead of re-listing). For U2b, state the refusal as a positive invariant rather than a list. Two forms would work: "the gate refuses unless `git check-attr -a` reports no conversion attribute (anything but `-text`/unset) on every path the walk read, and `core.symlinks` is true", or "the gate compares the bytes of each file the walk read against its blob". Either form closes future conversions by construction. This does not move B4. It only changes how its single enforcement point (U2b) decides.

#### 2. The walk's ok/fail outcome depends on the caller's locale, which goes against the lib's stated rule that checks do not depend on locale, and the header does not list the precondition

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:560` (the record regex's `(.+)`), :140-144 (the lib's locale rule), :29-35 (header inputs and preconditions)
**Move:** 3 (an implicit caller contract at the module's public surface)
**Confidence:** Medium. The fact-check (r3 Informational) executed the fail. The header gap comes from reading the code.
**Legibility-target:** The U2a4/U2b caller author.

**Evidence:**
```
140:# Characters are listed one by one, not as ranges, so the check does not depend
141:# on the caller's locale ...; setting LC_ALL here instead printed
142:# a setlocale warning per call when the caller's locale was not installed.
560:    [[ "$rec" =~ ^([01234567]{6})\ [abcdefghijklmnopqrstuvwxyz]+\ [0123456789abcdef]{40,64}$'\t'(.+)$ ]] || return 1
```
(:560 is the second line of the record loop, which ends at :565. The rest of `main_imports`, through :615, was read in full.)

The walk follows the lib's convention of listing characters one by one, but `.` in `(.+)` still matches by locale. Under a UTF-8 locale, a name on main that is not valid UTF-8 fails the walk. Under `LC_ALL=C` it passes. The failure is closed, so this is not a safety problem. It does mean the gate's verdict for the same commit can differ between hosts, and the cause is a hidden precondition. `build-loop.sh` sets no global `LC_ALL`. The header (:29-35) names the walk's other preconditions (`ROOT_REAL`, `resolve_main` having found main by name, a fresh worktree) but not this one.

**Recommendation:** Add a clause to the header's main_imports sentence, for example "run it under LC_ALL=C, or a non-UTF-8 name on main fails it", or have U2a4's floor call it under `LC_ALL=C`. That costs zero code lines in this unit. Carry it to U2a4/U2b if the comment budget is tight.

#### 3. The checkout `.md` pathspec is now written twice (`untracked_md` and :567), and U2a3c has no named seed source

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:517`, `:567`
**Move:** 8 (extension point for U2a3c), 7 (two copies that must stay in step)
**Confidence:** High (code read)
**Legibility-target:** The U2a3c author

**Evidence:**
```
517:untracked_md() { GIT_LITERAL_PATHSPECS=0 git ls-files -z --others -- ':(glob,icase)**/*.md'; }
567:  nul_list recs env GIT_LITERAL_PATHSPECS=0 git ls-files -z --cached --others -- ':(glob,icase)**/*.md' || return 1
```
L2f Finding 2 was taken as the merge into one call, but not as the named helper. `imported_names` (:528) still uses `untracked_md`, so the env prefix and pathspec are now written twice. A later change to one copy, such as adding `.mdx` or changing case handling, silently gives the two walks different start sets. U2a3c's phase 2 seeds from :567's set.

**Recommendation:** Optional. Carry it to U2a3c: give its phase-2 seed listing one name, either `checkout_md` or `untracked_md` taking `--cached` as an argument, when U2a3c touches these lines anyway. It is not worth a cap line in this unit.

## What Looks Good

- **B1's data-model invariant is now enforced where `ent` is built** (:566). Every consumer can treat `ent` as a prefix-free path map: the parent-link check :611, the `-L`/`ent` link test, and the `cat-file MAIN:path` reads. The memoised `dir` map keeps the check linear in practice, and the pass is order-independent, so tree-first and blob-first doubled names both fail.
- **One checkout listing** (:567) means the checkout side is defined in one place inside the walk, relative to main's commit, as U2a3c's "only appends" phase needs.
- **The fail-closed shape holds end to end.** Every early return happens after `IMPORTED_MAIN=error` (:555). Every return after :578 resets the variable to `error`. `isimported main` maps any failure to "imported" (:626). The `*)` dispatch default stays as a guard.
- **The B3/B4 split is honest.** The walk never claims to model git's checkout transform. The header defers that to A5, and the plan names U2b as the owner. Finding 1 is about how that owner decides, not about the lib.
- **The plan carries the U2a3c constraints in writing**: one admission predicate, and one drain loop over two seedings.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | U2b's planned checkout-conversion refusal is a denylist (`working-tree-encoding`, `filter`, `core.symlinks`). `ident` already passes the walk and is missing from A5, F11 and the U2b bullet. State U2b's refusal as a positive invariant (no conversion attribute on any path the walk read, or bytes equal the blob), and add `ident` to A5 now. | Minor | plan U2b bullet / F11; A5; lib :470 | High (ident) / Medium (others) |
| 2 | The walk's outcome depends on the locale (`(.+)` at :560). The failure is closed, but the precondition is not in the header, and the lib's rule says checks do not depend on locale. Name `LC_ALL=C` in the header or in U2a4's caller. | Informational | lib :560, :29-35 | Medium |
| 3 | The checkout `.md` pathspec is written twice (`untracked_md` :517 and :567). Give U2a3c's seed listing one name. | Informational | lib :517, :567 | High |

Rubric mapping: all three are 🟢 Consider. There are no Structural or Coupling findings.

## Overall Assessment

The unit maintains the lib's structure, and this iteration improved it. B1's invariants are enforced at construction (:566), the checkout side is one listing, and every failure path still leads to the single `error` sentinel that `isimported main` reads as "imported". Nothing in the code needs restructuring. The one structural concern left sits outside the lib: the walk depends on "checkout bytes equal blob bytes" (B4), and U2b's planned enforcement is a list of known-bad conversions. `ident` shows that such a list will lag reality. That is a design note for U2b and a one-line A5 addition here, not a merge blocker for U2a3, because the walk has no caller until U2a4 and the gate needs U2b's checkout checks before it is relied on. None of the recommendations moves a trust boundary. Finding 1 changes how U2b decides at B4, and the enforcement point stays the same. I have no disagreement with the security review's boundary placement. **From the architecture lens, the unit is merge-ready.**

## Goal-Alignment Note

**Success criterion (verbatim):** A markdown report saved to docs/reviews/architecture-review-review-2026-10-06-L3-build-loop-u2a3.md, structured per the architecture-review skill (Structural / Coupling / Minor / Informational).

**Answered:** Yes. The report is saved at that path with three findings (one Minor, two Informational), each carrying Evidence, Severity, Confidence and Legibility-target, plus a status table for the three L2f findings (one fixed, one partly taken, one fixed with a new mask routed to test-strategy).
- **Interim contract:** fail-closed in every checkout state the fact-check probed. Nothing that main alone would catch is missed by the split.
- **Merge-ready from the architecture lens:** yes.

**Out of scope:**
- Whether `ident` (or another conversion) is merge-blocking as a fail-open: security. The walk has no caller yet.
- Test 10's masked tree-listing refusal and the test name/comment wording: test-strategy and the fact-check route.
- Commit-message and override-row wording (99cce51b's "the U2b bullet makes the gate refuse them"): fact-check route. Those are accepted-immutable or append-only.
- Parser and sed/grep failure behaviour: fixed in U2a3b (stacked).

**Escalate:**
- **Author:** add `ident` to A5 (Finding 1, which matches the fact-check escalation). Optionally, point F11 and the U2b bullet at A5 instead of re-listing.
- **U2b owner:** write the checkout-conversion refusal as a positive invariant, not a list (Finding 1).
- **U2a4/U2b caller:** run the walk under `LC_ALL=C`, or document that precondition (Finding 2).
- **U2a3c author:** give the phase-2 seed listing one name (Finding 3).
