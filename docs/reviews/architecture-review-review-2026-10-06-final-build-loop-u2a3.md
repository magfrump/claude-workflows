Commit: cc1aa864

# Architecture Review — feat/build-loop-u2a3 (final confirming pass, i3)

**Scope:** `git diff main...HEAD` (base 62d366a7, HEAD cc1aa864): `scripts/lib/dev-cycle-read.sh` (main_imports, nul_list, isimported, header and block comments). Tests, plan, known issues and review artifacts were read for context only.
**Date:** 2026-10-06
**Based on:** the final-pass fact-check summary (replicates `code-fact-check-report-build-loop-u2a3-f-r1.md`, `-f-r2.md`, `-f-r3.md`). Trust boundaries come from `docs/reviews/security-reviewer-review-2026-10-06-build-loop-u2a3.md` (Commit: 34edec56). That review predates this diff, so its boundaries may be stale.

**Scope check:** in scope. The diff adds a public lib function (`main_imports`), a new `isimported main` selector, a new helper (`nul_list`) and module globals (`IMPORTED_MAIN`, `IMPORTED_MAIN_DONE`) that have a cache contract.

**Settled rows not re-filed:** cache key ignores checkout state, errexit off under `||`, the `link_target` extraction and three-copies gap list (all Won't-Fix/Defer, 2026-10-06 `feat/build-loop-u2a3`). Finding 3 below cites the `link_target` row and gives new evidence.

## Dependency Map

- `scripts/lib/dev-cycle-read.sh` is a leaf module that `dev-cycle.sh` and `build-loop.sh` source. Nothing calls `main_imports` yet. U2a4's floor will be the first caller.
- `main_imports` depends on lib primitives (`need_root`, `main_by_name`, `untracked_md`, `nul_list`, `inrepo_here`/`blocker`, `INSTRUCTION_FILE`, `lower`), on the shared parser `import_targets`, and on git plumbing (`ls-tree`, `cat-file`). No dependency points outward. `nul_list` is a new general-purpose primitive, and U2a3b will reuse it.
- The walk reads from two sources, which match B1 (main's commit) and B2 (gate checkout) of the security review (Commit 34edec56, which predates this diff, so the boundaries may be stale). B2 is crossed at five sites:
  - `:564-565`: untracked start list
  - `:571-572`: starts are queued and marked `seen`
  - `:580-583`: the `t:` arm reads a checkout file
  - `:600`: `-L` probes of link-text components
  - `:612-614`: the enqueue-time check for a path main lacks under a directory link main stores
- Shape of the walk: one BFS. **Producers** add items to the queue: the start loop `:569-574` and the import loop `:607-616`. The **consumer** is the dequeue arms `:579-605`. Validation is split between them.

## Findings

#### 1. The main-link parent check is placed at one producer, not at the consumer; starts enter through a second producer and skip it

**Severity:** Coupling
**Location:** `scripts/lib/dev-cycle-read.sh:571-572`, `:610-614`, `:579-583`; invariant claim `:32-35`
**Move:** 3 (module boundary: B2 input enters shared state), 8 (an extension point where every new producer has to remember the check)
**Confidence:** High (executed, and the variant was run against the suite)
**Legibility-target:** Implementer of the i3 fix (lib `main_imports`)

**Evidence:**
```
571:    if [[ "${f##*/}" =~ $INSTRUCTION_FILE || "$f" == .claude/rules/*.md || "$f" == */.claude/rules/*.md ]]; then
572:      seen[${cand[i]:2}]=1; queue+=("${cand[i]}")
```
```
610:      [[ -z "${seen[$p]+set}" ]] || continue
611:      seen[$p]=1
612:      if [[ -n "${ent[$p]+set}" ]]; then queue+=("m:$p"); continue; fi
613:      # Main lacks p: under a directory link main stores (the checkout may lack it), fail.
614:      for (( c = ${#p}; c > 0; c-- )); do [[ "${p:c:1}" != / || "${ent[${p:0:c}]:-}" != 120000 ]] || { IMPORTED_MAIN=error; return 1; }; done
```
(The excerpts end at :614. The enclosing loop continues to :616 and main_imports to :618. All of it was read.)

e7b5d7ed placed the i2 fix in the import loop, after the `seen` test. An untracked start, which comes from B2, is marked `seen` at :572 before the walk runs. An import that names the same path then stops at :610 and never reaches :614. The start's own dequeue in the `t:` arm (:580) checks only checkout links, through `blocker`. So checkout data changes which main-side checks run, and this breaks the header's invariant (:32-35) that the checkout "can only add imports or fail it".

The fact-check rated the exposure as limited to start-shaped names. A probe in `/tmp/u2a3-arch-i3-GcXn/setup2.sh` shows it is wider. Main stores `.claude/rules -> ../docs`, and `AGENTS.md` holds `@.claude/rules/x.md`. With main alone, the walk fails (correct). With a checkout where `.claude/rules` is a plain directory (unstaged from the index) holding an untracked `x.md`, the result is **walk ok, `docs/x.md -`**. `docs/x.md` has no instruction-file name and no dot component, so the floor's own rule does not cover it either. (Whether the gate's checkout can reach that state is a question for security.)

This is the architectural cause of the residue. Validation that depends on where a path lives happens where a path is *produced*. There are two producers, and only one of them carries the check. Any later producer, such as `.claude/commands` starts if the F3 row is reopened, or tracked-in-checkout starts (A5), would need to remember it again.

**Recommendation:** Move the :613-614 loop into the `t:` arm, run against `$f` before `inrepo_here`, so every checkout item passes through it, starts included. In the producer loop, keep only record, dedupe and route. A scratch copy with only that move (net 0 lines) passed `build-loop-check.bats` 16/16. Both probes (`setup1.sh`, `setup2.sh`) then fail closed. The test 15 sub-case that pins the i2 fix still passes. Add the `.claude/rules` probe as a test sub-case.
**Security implication:** B2 → B1. The move does not relocate the boundary crossing. It consolidates the B2-side check for main-link parents at the one consumer site (`t:` arm) instead of the producer.

#### 2. In the gate walk, "cannot tell" reads as "absent" on the checkout side because the walk reuses the digest's primitives

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:580-583` (with `blocker` :111-121, `inrepo_here` :128); `nul_list` :519 over `untracked_md` :517
**Move:** 7 (coupling to a primitive whose contract was written for another consumer)
**Confidence:** Medium. The mechanism comes from fact-check r2 Claim 19b (executed) and was not re-executed here. The remedy shape is untested.
**Legibility-target:** U2a4 floor author / the i3 fixer, when deciding the r2 19b escalation

**Evidence:**
```
580:      if inrepo_here "$f"; then out="$(import_targets "$d" < "$f")" || { IMPORTED_MAIN=error; return 1; }
581:      elif [[ -d "$f" && ! -L "$f" && -z "$(blocker "$f" dir)" ]]; then continue  # a directory: nothing loads
582:      elif [[ -e "$f" || -L "$f" ]]; then IMPORTED_MAIN=error; return 1
583:      else continue; fi
```
```
115:    [[ -e "$p" || -L "$p" ]] || return 0
```
(The first excerpt is the whole `t:` arm. `blocker` was read in full, :111-121.)

`blocker` and `inrepo_here` were written for the digest, where an absent path is a benign skip ("An absent path is not skipped, just absent", :109). The gate walk reuses them, but there an absent path that is really unreadable fails open. When a checkout directory is mode 000, `-e`/`-L` on a path below it are false, so :583 takes `continue` (r2 19b). The listing side has the same problem: `nul_list` takes rc=0 as "listed whole", but `git ls-files --others` exits 0 with only a warning when it cannot open a directory. The new shapes found in i2 and i3 sit on this checkout side. The main side is a closed vocabulary (four modes, parsed records), while the checkout side is an open filesystem probed with test operators that treat "unknown" the same as "absent".

**Recommendation:** Give the gate a single checkout classifier, for example `ckind PATH` printing `file|dir|absent` or failing. It should return "absent" only when the nearest existing ancestor is a plain, searchable directory (`-x`). The `t:` arm (and Finding 1's moved check) would then call it. For the listing, treat any stderr from `untracked_md` as a failure, for example by capturing it in nul_list's caller. If this is out of the 400-line budget, narrow the :32-35 and :546-547 claims ("cannot read") to the file's own mode, and record a Defer row with U2a4 as the trigger.

#### 3. A second here-string survives in the link-text step, outside the rule c42f017f established

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:596`
**Move:** 2 (an inline algorithm in a case arm)
**Confidence:** High (all three fact-check replicates found it). Exposure: not materialisable through a real symlink (PATH_MAX).
**Legibility-target:** Whoever next touches the 120000 arm

**Evidence:**
```
596:          lk=""; p="$d"; IFS=/ read -ra parts <<<"$out"
```
(The excerpt is one line of the 120000 arm, :587-603, which was read in full.)

c42f017f replaced the import-list here-string with process substitution, and the commit message states the rule (past 64 KiB a failed write reads as empty). The link-text split is the second instance and was not covered. That is the same producer-not-choke-point pattern as Finding 1, applied to an I/O idiom. This is new evidence against the `link_target` Won't-Fix row: the inline arm has now carried three fixes (4f087967, 34edec56, plus this residue), and each fix landed only at the site the probe went through.

**Recommendation:** Split without I/O (`mapfile -d / -t parts < <(printf %s "$out")`, or parameter expansion in a loop). The cheaper alternative is an Accepted row noting that the case is unreachable. Revisit extracting the arm when it next changes.

#### 4. Is the shape-by-shape design converging? On main's side yes; on the checkout side not yet, and one structure would close it

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:549-618` (main_imports); invariant claim `:32-35`
**Move:** 1 (inputs and dependency direction), 8 (extension)
**Confidence:** Medium (a judgement over three iterations of evidence)
**Legibility-target:** Reviewer deciding whether U2a3 is merge-ready, and the U2a4/U2b authors

**Evidence:** Fail-open shapes by iteration:
- i1: `..` after a symlink in link text, a main-side resolution rule.
- i2: a path main lacks under a main directory link, which only fails open when the checkout lacks the link.
- i3: the start bypass (Finding 1), an unsearchable checkout directory and ls-files exit 0 (Finding 2), and the :596 here-string (Finding 3, unreachable).

All three main-side shapes, once fixed, stayed fixed. Every live i3 shape involves B2 checkout input: it either injects state (`seen`) or is misread as absent. The walk interleaves both sources in one BFS with one `seen` map. That interleaving is why the invariant "the checkout can only add imports or fail it" has to be re-proved for each new shape.

**Recommendation:** For this unit, Finding 1's move is enough. It closes the observed class: every checkout item now passes one check site. If another checkout-side fail-open appears (trigger: U2a4 or U2b review), restructure into two phases.
- Phase 1 walks main's commit alone to a fixpoint. Any path main lacks is deferred and not read, so phase 1's result and failures depend only on B1, plus `-L` probes that can only fail it.
- Phase 2 seeds from the untracked starts plus the deferred paths, with `seen` copied from phase 1, and only appends to the result.

With this structure the :32-35 invariant holds by construction instead of by enumeration. It costs roughly 10-15 lines, so it does not fit at the cap now.

## What Looks Good

- **Fail-closed by one sentinel.** `IMPORTED_MAIN=error` is set before any work (:554) and is mapped to "imported" by `isimported main` (:629). An unrun or failed walk therefore never reads as an empty set.
- **`nul_list` is a good primitive.** It turns "this listing ended with rc=0" into one reusable check (U2a3b will reuse it), instead of the duplicated `printf rc=0` sentinel that I2-C3 flagged. Its contract is limited to the exit status (Finding 2).
- **Process substitution for the import list** (:616) removes a whole class of silent-empty reads at the main data path.
- **The cache key includes `MAIN_BY_NAME`** (:553), and the checkout half of the contract is stated at :472-475, as the settled row requires.
- **Dependency direction is unchanged.** The lib stays a leaf. The new code depends only on lib primitives and git plumbing.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Main-link parent check sits at the import producer after `seen`; untracked starts (B2) mark `seen` first and bypass it. Fail-open reaches a non-start file (`docs/x.md` via a `.claude/rules` link). Moving the check to the `t:` arm closes it (16/16 tests, probes fail closed) | Coupling | `scripts/lib/dev-cycle-read.sh:571-572`, `:610-614` | High |
| 2 | Gate's checkout side reuses digest primitives where "cannot tell" means "absent" (mode-000 dir, ls-files exit 0 with warning); needs one gate-specific classifier or narrowed claims | Minor | `scripts/lib/dev-cycle-read.sh:580-583`, `:519` | Medium |
| 3 | Second here-string at the link-text split, outside c42f017f's rule; unreachable in practice | Informational | `scripts/lib/dev-cycle-read.sh:596` | High |
| 4 | Convergence: main-side shapes closed; checkout-side shapes keep surfacing; two-phase walk would make the "checkout only adds or fails" invariant structural | Informational | `scripts/lib/dev-cycle-read.sh:549-618` | Medium |

Rubric mapping: Finding 1 is 🟡 Must Address. Findings 2-4 are 🟢 Consider.

## Overall Assessment

The module boundary and dependency direction are still sound. The walk is a leaf behind one fail-closed predicate. The fail-closed-shapes approach has converged on main's side but not on the checkout's. The most important structural concern is Finding 1. A B2 input (untracked starts) writes into shared walk state (`seen`) before a B1-derived check that runs only at one producer, so the checkout can still remove an answer. That violates the module's own stated invariant and reaches a file the floor does not otherwise cover. The fix moves one line from the producer to the consumer, fits the 400-line cap with no net change, and passes the existing suite. With it, every queued checkout path, starts included, is checked against main's links in one place. That is the class-closing change the brief asked about, at the scale that fits this unit. The two-phase restructure (Finding 4) is the next step if the checkout side produces another shape. I do not disagree with the security review's boundary placement: Finding 1 consolidates a B2 check and does not move the boundary.

## Goal-Alignment Note

**Success criterion (verbatim):** A markdown report saved to docs/reviews/architecture-review-review-2026-10-06-final-build-loop-u2a3.md, structured per the architecture-review skill (Structural / Coupling / Minor / Informational).

**Answered:** Yes. The report is saved at that path, with four findings that each carry Evidence, Severity, Confidence and Legibility-target. The convergence question is answered in Finding 4: main side converged, checkout side not. The structural change it asked about is Finding 1's single check site for every queued checkout path, verified in a scratch copy. That copy is at `/tmp/u2a3-arch-i3-GcXn/copy`, the variant was made with `mut.py`, and the probes are `setup1.sh` and `setup2.sh`.

**Out of scope:** exploitability of the `.claude/rules`-link checkout state, i.e. whether the gate's checkout can reach it and whether the floor's `.claude/` refusal fires first (security). Test coverage for the new sub-case and test 9's moved failure point (test-strategy). Wording fixes to commit messages and the return-1 comment (fact-check / Accepted-immutable rows). Parser behaviour (fixed in U2a3b, stacked).

**Escalate:** Implementer: apply Finding 1's move, or narrow every copy of the "checkout can only add or fail" claim and add an override row. The probe shows a non-start file fails open, so the fact-check's "limited to start-shaped names" understates the exposure. Security: rate the `setup2.sh` state. Implementer: decide Finding 2, either a classifier or narrowed claims plus a Defer row with U2a4 as the trigger.
