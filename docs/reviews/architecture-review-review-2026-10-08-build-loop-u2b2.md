Commit: c10b972a

# Architecture Review — feat/build-loop-u2b2 (iteration 1)

**Scope:** `git diff main...HEAD` in `/workspace/.claude/wt-build-loop-u2b2` (c10b972a). Code: `scripts/build-loop.sh` (read whole; new `checkout_gate` `:591-648`, `check_line` `:655-709`, dispatch `:720-733`). Contract: `scripts/lib/dev-cycle-read.sh:1-80` (the gate caller contract). Docs: `docs/working/plan-build-loop-handoff.md` (D1 `:28`, `:83`, U2b `:279`, U2b2 `:284`, U2c `:286`), `docs/working/known-issues-dev-cycle.md` (A5). The tests are context only.
**Date:** 2026-10-08
**Based on:** `docs/reviews/code-fact-check-report-build-loop-u2b2.md` (k=1, 20 claims, 0 Incorrect). This review uses Claims 1, 6 and 10.

## Scope check

In scope under two triggers.

- **Cross-cutting concern.** `checkout_gate` is a new precondition. It decides whether any self-merge verdict may be issued at all.
- **Public API and contract.** `--check` gains a new refusal shape. The lib's numbered gate caller contract (items 2-4) now names an owner for its duties.

## Dependency Map

The parent shell's `--check` arm calls the functions in this order:

1. `read_settings`, which sets `POLICY`.
2. `open_shared`.
3. `gate_repo`, which sets `GATE_TMP` and `GATE_ENV`.
4. `checkout_gate`, only when `POLICY == self-merge` (`:726`). It writes the global `CHECKOUT_WHY` and the scratch files `$GATE_TMP/others` and `$GATE_TMP/tree`.
5. For each brief, `check_line` inside `$(...)` (`:729`).

`check_line` calls `import_reset`, a lib function, in its subshell. It reads `pol` from `status_line`, which derives it from `POLICY` and the brief's `Policy:` line (`:482`). It then reads the global `CHECKOUT_WHY` (`:668`).

Dependencies point from the script, the caller, to the lib, the walk and contract owner. None points back. The lib header now names `build-loop.sh`'s `checkout_gate` in prose (`dev-cycle-read.sh:55-57`). That is a documentation pointer, not a code edge, so the direction is unchanged.

The new coupling is temporal. A verdict computed once in the parent shell is consumed per brief in a subshell. U2c will place the floor walk that this verdict guards inside the same per-brief subshell.

**Trust-boundary cross-reference: no-op.** The most recent `docs/reviews/security-review-*.md` files cover the egress zones and the pass-38 digest. None of them has a Trust Boundary Map for `--check`'s checkout, so no boundary label applies. Only the security-reviewer reviews for earlier units use the `security-reviewer-review-*` naming, and no such file exists for U2b2 yet.

## Findings

#### F1. The checkout is checked once per run, but U2c's walk reads it once per brief: the precondition and its consumer run at different granularities

**Severity:** Coupling
**Location:** `scripts/build-loop.sh:725-726`, `:657`, `:668-670`; `scripts/lib/dev-cycle-read.sh:46-51` (item 2, "final before the walk")
**Move:** 7 (coupling surface, temporal), 3 (module boundary / contract)
**Confidence:** High on the structure, Medium on the consequence (U2c is not written yet)
**Legibility-target:** the plan's U2c bullet (`plan-build-loop-handoff.md:286`), which should name how U2c re-establishes item 2 before each walk

Evidence. The gate runs once, in the parent, before any brief:

```
    # Once, in this shell, before any verdict; only self-merge briefs read it.
    if [[ "$POLICY" == self-merge ]]; then checkout_gate || true; fi
```

Meanwhile the walk cache is reset per decision, inside each brief's subshell:

```
  import_reset  # caller contract item 4: no walk cache outlives a decision
```

The contract asks for both:

> 2. Walk a clean worktree at MAIN_SHA, final before the walk

The diff treats item 4 (the cache) per decision but item 2 (the checkout state the cache was built from) per run. The two duties guard the same thing, so they should share a lifetime. Once U2c puts the floor walk in `check_line`, brief N's walk can run long after `checkout_gate` sampled the checkout. Brief 1's walk alone can take seconds: `IMPORT_WORK_MAX` comments cite roughly 0.1-4 s per bounded file.

The checkout most likely to move in that window is the shared one. In this repo, other sessions switch `/workspace`'s branch. Fact-check Claim 10 already notes that "final before the walk" is not checked.

The structural cost lands on U2c, which inherits a choice it cannot see. It can trust a stale global, re-run the whole gate per brief, which costs a `hash-object` over every file main stores, or add its own re-check. Each option changes `checkout_gate`'s interface after U2b2 has fixed it.

**Recommendation:** Name the lifetime now. Either split `checkout_gate` into a once-per-run part (env, config, the blob-hash pass) and a cheap per-decision part (HEAD, `git status`, index flags) that `check_line` runs next to `import_reset`, or have U2c re-check HEAD and status after each walk and refuse on a change. Record the choice in the U2c bullet.

#### F2. A checkout precondition is reported as the brief's verdict and stops the N rules, so a loop's advisory `--check` on a self-merge brief now returns no path lines

**Severity:** Coupling
**Location:** `scripts/build-loop.sh:668-670`, header `:125-126`; plan `:28`, `:83`
**Move:** 2 (responsibility boundaries), 7 (control coupling)
**Confidence:** High (read from the code: the refusal `return`s before `merge_result` and `nrules`)
**Legibility-target:** the help header's sentence "A review brief does not read the checkout, so a loop can run --check from its own branch."

Evidence. The plan keeps the loop's own run as a deliberate feature:

> The loop still runs `--check` itself as an advisory dry run.

The new refusal sits before the merge:

```
  if [[ "$pol" == self-merge && -n "$CHECKOUT_WHY" ]]; then
    echo "refuse $a: a self-merge brief needs --check run from a clean checkout of the default branch's commit; $CHECKOUT_WHY"; return
  fi
  tree="$(merge_result "$sha")" || rc=$?
```

A loop runs from its own worktree, whose HEAD is its branch tip and not MAIN_SHA. For every self-merge brief it therefore gets this one line, and never the `path`/`deny` lines that tell it which N rule it broke.

The header's carve-out covers only review briefs. It is silent about self-merge briefs, which are exactly the ones whose loops most need the dry run, because nobody reviews them. Two concerns are merged into one verdict channel: "can this environment judge?" and "does this branch pass?". The first now hides the second. A loop that always sees the same refusal also learns to ignore `--check`'s first line.

**Recommendation:** Keep the refusal, so the verdict still fails, but let the rules that do not read the checkout still run. The merge, the N rules and later the S rules except the floor can print their `path`/`deny` lines after the refusal, so the advisory run stays useful. If that is not wanted, state in the header and in plan D1 that a self-merge loop's advisory run carries no path lines.

#### F3. An empty `CHECKOUT_WHY` means "passed", and two separate call sites must agree that the gate ran

**Severity:** Minor
**Location:** `scripts/build-loop.sh:602`, `:726`, `:668`
**Move:** 7 (control coupling via a global), 3
**Confidence:** High on the structure. There is no live bypass today: `pol=self-merge` implies `POLICY=self-merge`, which implies the gate ran.
**Legibility-target:** the comment above `checkout_gate` ("Sets CHECKOUT_WHY to why the checkout fails them, or empties it")

Evidence. The global's default is `CHECKOUT_WHY=""` (`:602`). The producer is guarded by one predicate:

```
if [[ "$POLICY" == self-merge ]]; then checkout_gate || true; fi
```

The consumer is guarded by another (`pol`, derived in `status_line` `:482`):

```
if [[ "$pol" == self-merge && -n "$CHECKOUT_WHY" ]]; then
```

"Not run" and "passed" are the same value. A future path that reaches `check_line` without the dispatch arm would fail open without any visible sign. Examples are a U3b mode that reuses it, or U2c moving the gate per brief (F1). The dispatch arm's `|| true` also discards the return code, so the global is the only channel. Elsewhere this gate fails closed: its comment says "fail closed", and `status_line` answers `bad`, never `working`, on a failed read (row 307). This sentinel is the one place that pattern is inverted.

**Recommendation:** Use a positive state, for example `CHECKOUT_STATE=unchecked|ok|WHY`, and have `check_line` refuse a self-merge brief unless the state is `ok`.

#### F4. The lib's contract now credits `checkout_gate` with all of items 2 and 3, and keeps item 3's superseded `check-attr` wording beside the new effect wording

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:46-57`
**Move:** 3 (module boundary: who owns which caller duty)
**Confidence:** High (corroborated by fact-check Claim 10)
**Legibility-target:** contract item 3's text and the new sentence "The walk does not check items 2 and 3; build-loop.sh's checkout_gate does for --check (U2b2)"

Evidence. The lib calls this list "the one statement" of what a caller owes:

```
#  3. Refuse a checkout whose core.symlinks is false or with a
#     working-tree-encoding, filter or ident attribute on any path the walk
#     reads (.gitattributes, $GIT_DIR/info/attributes, core.attributesFile).
#     The walk does not check items 2 and 3; build-loop.sh's checkout_gate
#     does for --check (U2b2), item 3 by its effect: every regular file main
#     stores hashes, unfiltered, to main's blob.
```

Item 2's duties are split across three owners:

- fsmonitor and replace refs belong to `harden` and `state_gate`;
- "git ls-files prints nothing on stderr" belongs to the walk itself;
- "final before the walk" has no owner (F1).

Item 3 now holds two rules that disagree in both directions:

- **Stricter:** the effect check also refuses an `eol` conversion.
- **Looser:** it accepts an attribute that changed no bytes.

U2c is the first reader that will rely on this map to know which duties remain its own, and the map points to one function for all of them.

**Recommendation:** Rewrite items 2-3 as one line per duty, each naming its owner: `harden`, `state_gate`, `checkout_gate`, the walk, or "the caller, per decision" for "final". Replace item 3's attribute list with the effect rule, and keep the attribute list as the rationale.

#### F5. The "trusted repo-local GIT_* variable" rule is now spelled twice, and the copies already differ

**Severity:** Minor
**Location:** `scripts/build-loop.sh:517` (`gate_repo`), `:606-610` (`checkout_gate`)
**Move:** 7 (duplicated policy), 8 (extension point missed)
**Confidence:** High
**Legibility-target:** the comment in `checkout_gate`: "harden's own config pairs (and the caller's, which it trusts) are not a checkout."

Evidence. The two loops read:

```
for v in $(git rev-parse --local-env-vars); do [[ "$v" == GIT_CONFIG* || "$v" == GIT_NO_REPLACE_OBJECTS ]] || GATE_ENV+=(-u "$v"); done
```

```
    [[ "$v" == GIT_CONFIG* || "$v" == GIT_NO_REPLACE_OBJECTS || "$v" == GIT_PREFIX || -z "${!v+set}" ]] \
```

Both loops answer the same question, "which repo-local variable may the gate's environment carry?", and only the second exempts `GIT_PREFIX`. On this host git 2.39 lists 16 such variables. Both copies wave through all of `GIT_CONFIG*`, which includes `GIT_CONFIG` itself (fact-check Claim 6). A change to the trust rule, such as narrowing `GIT_CONFIG*` to `GIT_CONFIG_COUNT`, `GIT_CONFIG_KEY_*` and `GIT_CONFIG_VALUE_*`, must now be made twice. U3b's `--state`, which reuses the state-gate halves, would make a third copy.

**Recommendation:** Move the rule into one predicate, for example `trusted_local_env NAME`, that both loops call, with any per-site extra (`GIT_PREFIX`) stated at the call.

#### F6. The checkout gate's rule list is restated in four places, and A5's "Not covered" list still names what U2b2 now covers

**Severity:** Informational
**Location:** `scripts/build-loop.sh:113-126` and `:591-601`; `plan-build-loop-handoff.md:284`; `known-issues-dev-cycle.md:18` (A5)
**Move:** 3 (contract legibility)
**Confidence:** High (corroborated by fact-check Claim 1)
**Legibility-target:** A5's "Not covered: … checkout conversions … and `core.symlinks=false`" clause

Evidence. A5 still lists the conversion attributes and `core.symlinks=false` under "Not covered", then appends a separate sentence saying they are now refused:

> U2b2: `build-loop.sh --check` refuses a self-merge brief unless its checkout is clean at main with `core.symlinks` true …

The plan's U2b2 bullet restates the full refusal list as well. That list contains HEAD, env, `symlinks`/`ignoreCase`/`sparseCheckout`, index flags, status, nested repos and the blob hash. The help header and the function comment repeat it too, while the U2b bullet says the lib's contract is "the one statement of these duties, not restated here". Four copies of an eight-item list will drift at the next change, which F1 and F2 both invite.

**Recommendation:** Move the two items out of A5's "Not covered" list and qualify them with "for a self-merge `--check`". Reduce the plan bullet to a pointer at the help header's list.

#### F7. `checkout_gate` lives in the caller while the contract it enforces lives in the lib

**Severity:** Informational
**Location:** `scripts/build-loop.sh:591-648`; `scripts/lib/dev-cycle-read.sh:44-57`
**Move:** 2 (responsibility placement)
**Confidence:** Medium
**Legibility-target:** the lib header's "The walk does not check items 2 and 3"

Evidence. The contract is the lib's ("for floor and main_imports"), and its item 7 already anticipates "A second caller of main_checkout". With one floor caller, keeping the check in `build-loop.sh` is the pragmatic choice. It uses `GATE_TMP` and `MAIN_SHA` from this script's frame, and the refusal wording is `--check`'s. A second floor caller would still copy roughly 45 lines of checks: an orchestrator `--merge` re-check, or `dev-cycle.sh` gaining a self-merge path. No change is needed now.

**Recommendation:** None for U2b2. Add a revisit trigger to the lib header: move the check beside the contract when a second floor caller appears.

## What Looks Good

- **Item 3 is checked by its effect.** Hashing every regular file main stores with `--no-filters` replaces predicting conversions from `check-attr`. One mechanism covers every attribute source, including the global ones that `harden` hides from the gate's own git, and `eol` too. It cannot drift from git's attribute precedence rules, because it does not model them.
- **The refusal is scoped per brief, not a state-gate exit.** Review-policy runs, and review briefs under a self-merge policy, keep working from any checkout. The structure records that only the floor reads the checkout.
- **`import_reset` sits at the top of `check_line`.** That is the subshell where U2c's floor will run. The per-decision reset is therefore in the right scope, a correct, idempotent no-op until U2c.
- **The direction is unchanged.** The new code depends only on lib functions and variables (`MAIN_SHA`, `import_reset`). The lib gains no code dependency on the script.
- **Listings go to files before they are filtered** (`$GATE_TMP/others`, `$GATE_TMP/tree`). This follows the pattern U2b1b set for `diff-tree`, so a failed listing is not hidden by pipefail.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Checkout checked once per run; U2c's walk reads it per brief (item 2 "final before the walk" has no owner) | Coupling | `build-loop.sh:725-726`, `:657`, `:668` | High / Medium |
| 2 | Checkout refusal is the brief's verdict and stops the N rules; a self-merge loop's advisory `--check` gets no path lines | Coupling | `build-loop.sh:668-670`; plan `:28` | High |
| 3 | Empty `CHECKOUT_WHY` means both "passed" and "never ran" (fail-open sentinel, two predicates) | Minor | `build-loop.sh:602`, `:726`, `:668` | High |
| 4 | Lib contract credits `checkout_gate` with all of items 2-3; item 3 keeps superseded `check-attr` wording | Minor | `dev-cycle-read.sh:46-57` | High |
| 5 | Trusted-local-env rule duplicated in `gate_repo` and `checkout_gate`, already diverged | Minor | `build-loop.sh:517`, `:606-610` | High |
| 6 | Gate list restated four times; A5's "Not covered" still lists what U2b2 covers | Informational | A5; plan `:284`; header `:113-126` | High |
| 7 | `checkout_gate` sits in the caller, apart from the lib contract it enforces; revisit at a second floor caller | Informational | `build-loop.sh:591-648` | Medium |

## Overall Assessment

The change keeps the system's structure sound. It adds a self-contained precondition in the caller, with the right dependency direction, and its effect-based item-3 check is a structural improvement over the planned `check-attr` prediction. The issues can be fixed in place, and none calls for restructuring. The most important concern is F1, a granularity mismatch: the checkout verdict is computed once per run and stored in a fail-open global (F3), while the cache reset, and U2c's walk, run once per brief. That leaves "final before the walk" without an owner, and U2c will have to reshape `checkout_gate` to fix it. F2 is the other decision worth settling before merge, because it changes what the loop's advisory dry run (plan D1) gives a self-merge loop.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to /workspace/.claude/wt-build-loop-u2b2/docs/reviews/architecture-review-review-2026-10-08-build-loop-u2b2.md (first line `Commit: c10b972a`), structured per the critic skill.
- Answered: yes. The diff, `build-loop.sh` whole, the lib header 1-80 and the plan's U2b/U2b2/U2c bullets were reviewed. Seven findings: 2 Coupling, 3 Minor, 2 Informational.
- Out of scope: the cost of the per-run `hash-object` over every file (performance); whether `GIT_CONFIG`/`GIT_CONFIG_PARAMETERS` pass-through is exploitable (security); test adequacy. The override-log rows were taken as given, and nothing here reopens 459/465, 439, 366/373 or 388.
- Escalate: F2 changes the plan's D1 advisory-run behaviour for self-merge loops, which may need a user decision. F1's resolution belongs in the U2c bullet.
- Decisions I made: I rated F2 Coupling rather than Minor, treating plan D1's advisory dry run as a contract the diff degrades. The alternative was to read the header's review-brief carve-out as an accepted scope cut. I also treated the fail-open sentinel (F3) as Minor because no live bypass exists. The alternative was Coupling, given the planned U2c and U3b reuse.
