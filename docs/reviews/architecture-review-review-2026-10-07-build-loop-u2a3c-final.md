Commit: 3a35c8b9

# Architecture Review — feat/build-loop-u2a3c (iteration 3, final confirming pass)

**Scope:** `git diff main...HEAD` in `/workspace/.claude/wt-build-loop-u2a3c`. Code: `scripts/lib/dev-cycle-read.sh`. Contract docs: `docs/working/known-issues-dev-cycle.md` (A5), `docs/working/plan-build-loop-handoff.md` (F11, U2a3c and U2b bullets). The tests and the `docs/reviews/*` history are context only.
**Date:** 2026-10-07
**Based on:** the Stage-1 summary (`u2a3c-i3-stage1.md`) and the `## Escalations` sections of `docs/reviews/code-fact-check-report-build-loop-u2a3c-r{1,2,3}.md`. All three replicates escalated the `:753` memo write to architecture, security or API review.

## Scope check

In scope. The diff changes cross-cutting structure inside the lib. It adds a new admission function with shared mutable state (`main_checkout` and its MEMO). It changes the parser's output protocol, which now has an optional `/N` trailer consumed by `import_work`. It adds a shared reader (`capped_read`) and a walk-wide budget (`IMPORT_WORK_MAX`). It also restates the walk's caller contract across the lib and two planning docs that later units (U2a4, U2b) build against.

## Dependency Map

All of the new code is internal to `scripts/lib/dev-cycle-read.sh`. `rg` finds no caller of `main_checkout`, `capped_read`, `import_work` or `IMPORT_WORK_LEFT` outside the lib and its two bats files. The dependencies run one way:

- `isimported main` calls `main_imports`.
- `main_imports` calls `nul_list`, `checkout_md`, `lower_all`, `main_checkout` (which calls `rawfile` and `plaindir`), `capped_read`, `import_targets` (the parser) and `import_work`.
- `imported_names` calls `tree_starts`, `inrepo_here`, `capped_read`, `import_targets` and `import_work`.

The parser and the budget are joined by an in-band protocol. `import_targets` prints a `/N` last line when `IMPORT_WORK_LEFT` is set, and `import_work` strips it and charges it. Iteration 2 settled this as the three-times-written reader→parser→trailer→budget chain. Its premise is unchanged: the chain is still written out at `:775`, `:837` and `:839`.

The planned consumers are U2a4 (the self-merge floor, through `isimported main`) and U2b (`--check`, which owns the checkout the walk reads). The plan's U2b bullet also anticipates "a caller of `main_checkout` other than `main_imports`".

Trust-boundary cross-reference: no security review exists for this diff at `docs/reviews/security-review-*.md`. The most recent one by date is `docs/reviews/security-review-2026-10-02-digest-pass38.md` (Commit: `90364c73`). Its `B2` reads: "[instruction files …] → [imported_names() walk …] → [IMPORTED refusal set]". `main_checkout` is the admission step on the main-walk counterpart of that boundary. That security review predates this diff, so the boundary may be stale.

## Findings

#### F1. `main_checkout`'s MEMO is valid only under a caller precondition (PATH not in ENT) that neither the function nor either written contract states

**Severity:** Coupling
**Location:** `scripts/lib/dev-cycle-read.sh:717-723, 752-754` (the contract text is also in `docs/working/plan-build-loop-handoff.md:279`)
**Move:** 3 (module boundary / encapsulation), 6 (substitutability against 21b35ebf's top-down version)
**Confidence:** High (all three fact-check replicates executed it, and so did this review)
**Legibility-target:** the `main_checkout` block comment and the U2b bullet's "A caller of `main_checkout` other than `main_imports`" sentence

Evidence. The comment states the invariant:

```
# loads), set only once its own and every higher ancestor's main mode passed.
# A MEMO hit skips that mode check too, so a MEMO serves one walk and one ENT.
```

Every ancestor write honours it: `:742` `[[ ! "${mc_e[$c]:-}" =~ ^1[26]0000$ ]] || return 1` runs before `:747` `mc_m[$c]="$st"`. The PATH arm does not:

```
  plaindir "$c" || return 1
  [[ ! -x "$c" ]] || mc_m[$c]=d  # a prefix candidate's directory, which longer ones pass through
  return 2
}
```

The plan states the caller's duty as only "passes a fresh MEMO per walk and ENT (a MEMO hit skips main's mode check too)".

Reproduced in a scratch repo. With `ENT=([a]=120000)` and a plain directory `a/` holding `f.md`, the call order matters:

```
a 2
a/f.md 0
fresh a/f.md 1
```

A caller that passes a path main stores as a link or gitlink, while the checkout holds a directory there, poisons the MEMO. Every later call below that path then skips the link refusal and admits a file (0) that 21b35ebf, and a fresh MEMO, refuse (1).

`main_imports` is safe. Both of its call sites guard on `ent`: `:825` admits only `t:` candidates, which `:819` adds only when `ent` lacks the path, and `:870` reads `[[ -n "${ent[$p]+set}" ]] || main_checkout ent pok "$p"`. The design problem is where the guarantee lives. `main_checkout` is now a stateful function: one call's misuse silently corrupts the answers to later, correct calls, and the failure shows up far from its cause, in the fail-open direction, on the admission step of the walk's trust boundary (`B2` above). Both written statements of the caller contract, the lib comment and the plan's U2b bullet, omit this precondition. U2a4's shared start predicate and any U2b caller would build against those texts.

Enforce it, rather than document it. The function can check the precondition with a single lookup it already performs for ancestors. The other duties cannot be checked from inside: a fresh MEMO per walk, and one ENT per MEMO. With the check, the comment's "set only once its own … main mode passed" becomes true by construction. Without it, the claim holds only for one caller.

**Recommendation:** Make the function's domain explicit at entry: `[[ -z "${mc_e[$3]+set}" ]] || return 1`, after the `${x@a}` test. A path main stores is not this function's question, and refusing it fails closed. Alternatively, guard only the `:753` write with that lookup. Pin the change with T1's shape table: one row for "ENT holds PATH as 120000, then a path below it". State the domain in the comment's first line ("PATH, a path ENT lacks").

#### F2. The walk's caller contract is stated in five or more places, and the two pointers to it name different homes

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:486-491, 501-502, 509-510, 723, 729`; `docs/working/known-issues-dev-cycle.md` (A5); `docs/working/plan-build-loop-handoff.md:126` (F11), `:279` (U2b)
**Move:** 2 (responsibility boundaries), 3
**Confidence:** High
**Legibility-target:** the A5 and F11 sentences that say where the contract lives

Evidence. A5 says the contract lives in the lib:

> the lib's block comment above `IMPORTED=` holds the caller contract; the U2b bullet names what U2b owes it

F11 says it lives in the plan:

> the caller contract (cache clear, empty `ls-files` stderr, the git environment) is in the U2b bullet

The duties themselves are spread across these places:

| Duty | Where it is stated |
|---|---|
| Clear `IMPORTED_MAIN_DONE` after a checkout change | lib `:488-490` and the U2b bullet |
| A HOME change clears both caches | lib `:490-491` only |
| Changing `IMPORT_OUT_MAX` or `IMPORT_WORK_MAX` clears both caches | lib `:501-502` and `:509-510` |
| One MEMO per walk and per ENT; test return 1 as a refusal | lib `:723` and `:729`, and the U2b bullet |
| Git environment (`GIT_INDEX_FILE`, `GIT_WORK_TREE`, fsmonitor, …) | U2b bullet only |
| `LC_ALL=C` | U2b bullet only |

The Stage-1 summary's "Mostly accurate" verdict on A5 points at the same gap: the git-environment and `LC_ALL` duties are only in the U2b bullet.

This is exactly the kind of drift the question anticipated. The MEMO rule is written twice, in the lib and in the plan, and both copies miss the same precondition (F1). Iteration 2's restoration of B1 rebuilt the contract by adding pointers rather than one statement. The superset claim is the model to copy: it is stated once, above `import_targets`, and A5 and F11 point there. U2a4 and U2b each add duties, so every added copy is one more place for them to diverge.

**Recommendation:** Collect every caller duty into one numbered block in the lib, above `IMPORTED=`. Make the U2b bullet list only what U2b builds to meet each duty, by number. Make A5 and F11 point at that one block. If merge timing matters more, at minimum make A5 and F11 name the same home.

## Settled, not re-filed

- **The three-times-written parse chain and `main_checkout` as a second traversal beside `blocker`.** These are iteration-2 deferrals. The premise is unchanged: the chain is still at `:775`, `:837` and `:839`, and `:730-731` still states "a second traversal on purpose".
- **The cache key ignores the checkout, and the three-valued return and its name.** Both have override rows. F1 does not reopen the three-valued return. It asks only that the function enforce its domain.

## What Looks Good

- **One reader.** `capped_read` is the single reader both walks parse, and draining is an explicit argument at the one arm that needs it (`:839`), not a `/proc`-dependent probe. This removes a dependency on the environment.
- **The `.git` special case is gone.** The top-level `.git` file is now read as an ordinary checkout file. Removing that branch narrows the walk's rule set, which is the extension-over-modification direction.
- **The bottom-up memo is structured soundly.** Every ancestor write at `:747` follows the `:742` mode check on that same ancestor. A shorter prefix memoized as 2 does not hide a deeper link: the deeper ancestor is not memoized, so `:742` still checks it. The only write that skips the check is `:753` (F1). This matches the Stage-1 differential: 0 mismatches over about 45,000 in-contract calls.
- **Admission happens before `seen` at both phase-2 sites (`:825-827`, `:870-872`).** This keeps iteration 1's A3 fix intact. The `[[ -e || -L ]] || return 2` fast return at `:750` keeps C1's no-fork path.
- **`IMPORT_WORK_MAX` reuses an existing channel.** It reaches the parser through the environment, the same channel `IMPORT_LEFT` already uses, rather than a new parameter. That is the consistent extension of an established channel.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | MEMO validity depends on an unenforced, undocumented precondition (PATH not in ENT); the `:753` write skips PATH's own mode check | Coupling | `scripts/lib/dev-cycle-read.sh:717-723, 752-754`; plan `:279` | High |
| 2 | The caller contract is stated in five or more places; A5 and F11 name different homes; git-environment and `LC_ALL` duties appear only in the plan | Minor | lib `:486-510, 723, 729`; A5; plan `:126`, `:279` | High |

## Overall Assessment

The change keeps the lib's structure intact and improves it: one reader, one admission function, one walk-wide budget threaded through the existing environment channel, and one special case fewer. Both findings can be fixed in place.

The most important structural concern is F1. Iteration 2 made `main_checkout` stateful across calls. The function now carries state whose validity depends on a caller precondition, and neither the function nor the contract U2a4 and U2b will build against states it. For a boundary that later units consume, the function should enforce its own domain. The check costs one associative lookup and turns a non-local fail-open into a local refusal. Documentation alone is not enough, because the contract is already written twice and both copies missed this.

F2 is the drift mechanism behind F1. Consolidating the contract into one lib block before U2a4 adds its duties is cheap now and gets more expensive with each unit.

No security trust-boundary placement is contradicted. F1's fix strengthens the admission step on `B2` (`docs/reviews/security-review-2026-10-02-digest-pass38.md`, Commit: `90364c73`; that review predates this diff, so the boundary may be stale) and does not move it.

## Goal-Alignment Note

The goal is to land `feat/build-loop-u2a3c` on main once its loop is clean.

- **F1 (Coupling, so 🟡 Must Address).** It does not block on live behaviour: the walk is safe today. It does need either a one-line enforcement with a T1 row, or, at minimum, the precondition added to both contract texts with an override row, so that U2a4 and U2b inherit a correct contract.
- **F2 (Minor).** Can be done in the same fix commit, or deferred with an override row that triggers at U2a4.

Nothing here argues against merging after F1 is addressed. Nothing re-opens a settled decision.
