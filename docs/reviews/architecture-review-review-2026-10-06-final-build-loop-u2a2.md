Commit: 7697c6e6

# Architecture Review — feat/build-loop-u2a2 (iteration 3, final confirming pass)

**Scope:** full branch, net diff `git diff main...HEAD` (main 20347279, HEAD 7697c6e6). Code: `scripts/lib/dev-cycle-read.sh`, `scripts/dev-cycle.sh`, `test/scripts/build-loop-check.bats`, `test/scripts/dev-cycle.bats`, `test/scripts/fixture-git-env.bats`; docs `docs/working/plan-build-loop-handoff.md`, `docs/working/questions.md`, `docs/reviews/override-log.md`. Added `docs/reviews/*-build-loop-u2a*.md` files are review history, read for context only.
**Date:** 2026-10-06
**Based on:** Stage-1 summary `fc3-summary.md` (k=3 replicates `code-fact-check-report-build-loop-u2a2-f-r{1,2,3}.md` at 7697c6e6); the U2a3 consumer read from `feat/build-loop-u2a3` commit 579ebca2 (context only); plan step 5 (`docs/working/plan-build-loop-handoff.md:273-280`); the iteration-2 architecture review and rubric (`architecture-review-review-2026-10-06-build-loop-u2a2.md`, `code-review-rubric-2026-10-06-feat-build-loop-u2a2.md`).

**Scope check:** in scope.
- **Public APIs:** the diff adds public lib functions (`import_targets`, `isimported`, `inrepo_here`, `instruction_names`, `untracked_md`) and a public constant, `UNI_SPACES`. All are listed in dev-cycle.bats' inventory test.
- **Cross-cutting concerns:** `check_fix`'s caller contract changes from reading the `$IMPORTED` cache to calling a predicate.

The test and doc files were reviewed only for what they say about the structure. 100/100 tests pass at HEAD (re-run here).

**Trust-boundary cross-reference:** active.
- **The glob match.** The most recent `docs/reviews/security-review-*.md` is `security-review-2026-10-02-digest-pass38.md` (Commit: `90364c73`, as recorded by the iteration-2 review). Its `B2` is the working-tree import walk. That security review predates this diff, so the boundary may be stale.
- **This unit's own map.** The unit's own security review, `security-reviewer-review-2026-10-06-build-loop-u2a2.md` (Commit: `7c970bfe`), does not match the glob. It labels this unit's two crossings:
  - `B4`: Claude Code's grammar → `IMPORT_RE`, `UNI_SPACES` → the walk's model;
  - `B5 (moved)`: the working tree → `imported_names` via `isimported tree` → `check_fix`.
- Findings 1-3 sit on those crossings. No recommendation below moves any of them.

## Dependency Map

- **Caller to lib.** `scripts/dev-cycle.sh` (the cycle CLI, volatile) sources `scripts/lib/dev-cycle-read.sh` (stable). It now reaches the import walk only through `isimported tree "$lp"` (dev-cycle.sh:181). It no longer calls `imported_names` or reads `$IMPORTED`. This is the direction plan:192 asked for ("an `isimported` predicate so neither caller reads the walk's cache format").
- **Inside the lib.** The tree walk has been decomposed into leaf helpers:
  - `import_targets DIR < text`: the token grammar plus repo-relative resolution. It reads globals `ROOT_REAL`, `IMPORT_RE` and `UNI_SPACES`.
  - `instruction_names`: a start-name prefilter.
  - `untracked_md`: the untracked and ignored `.md` listing.
  - `inrepo_here`: an unguarded plain-file check.

  `imported_names` composes these and keeps the queue and the cache. `isimported` is the dispatch. It is keyed by walk name: `tree` runs the walk, and any other name answers "imported" (fail closed).
- **Downstream (stacked, not in this unit).** U2a3 (579ebca2) adds `main_imports`, which consumes `import_targets`, `untracked_md` and `inrepo_here` unchanged, plus a `main)` arm in `isimported`. `git diff 7697c6e6 feat/build-loop-u2a3 -- scripts/` touches none of the U2a2 helpers' bodies. That is direct evidence the seam holds for its second consumer. U2a4's floor consumes `isimported main`. `instruction_names` has one caller (the tree walk), and U2a3 does not use it.
- **Direction and cycles.** Dependencies flow from CLI to lib. The lib depends on neither script. No cycle.

## Findings

#### 1. The token grammar is split across two representations that do not compose, so the "one grammar" seam has a crack both walks inherit

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:450-456`, `:472`, `:481`
**Move:** 7 (coupling surface), 3 (module boundary: `B4` from `security-reviewer-review-2026-10-06-build-loop-u2a2.md`, Commit `7c970bfe`, not the glob match)
**Confidence:** High (fact-check E1, re-executed here)
**Legibility-target:** the `UNI_SPACES` comment and `import_targets`

Evidence:

```
450: # UTF-8 spaces that end an import token, as a blank does: U+00A0, U+1680,
456: IMPORT_RE='(^|[^[:alnum:]])@[^][:space:]\\#`()]+'
472:     for u in "${UNI_SPACES[@]}"; do t="${t%%"$u"*}"; done
481:   done < <(env LC_ALL=C grep -aoE "$IMPORT_RE" || true)
```

Probe: `printf '@docs/a.md\xc2\xa0@docs/b.md\n' | import_targets ""` prints only `docs/a.md`.

The unit's premise is that one parser holds one grammar, so the walks cannot drift. Inside `import_targets`, though, the token boundary is defined twice, in sequence:
- a byte-level ASCII regex (`IMPORT_RE`) splits the matches;
- a bash post-cut (`UNI_SPACES`) then trims each match.

The regex does not know the Unicode spaces. A match therefore runs through an NBSP's bytes and swallows the next `@token`, and the post-cut then discards it. The comment's "as a blank does" holds only for the token's end, not for what follows it.

This is a correctness gap (fact-check E1, Medium, fail-open, not a regression: main misses it too), but its cause is structural. Any future boundary character (`B4` is expected to track Claude Code's grammar) has to be added in two places with different semantics, and only one of them decides where the next token starts. Because U2a3's `main_imports` consumes `import_targets` unchanged, the gate inherits the gap the moment U2a3 lands.

**Recommendation:** Make the boundary a single rule. One option: normalise every `UNI_SPACES` sequence to an ASCII blank on the input stream, in one byte-level substitution ahead of the one `grep`. The regex alone then decides token starts and ends, and "as a blank does" is true by construction. Fix it in this unit, or carry it as an explicit U2a3 row, since the parser is the shared seam. Do not patch it inside `main_imports`.

#### 2. Moving the tree walk behind a predicate under `elif` switched errexit off for it, and the walk has no explicit failure path

**Severity:** Minor
**Location:** `scripts/dev-cycle.sh:181`; `scripts/lib/dev-cycle-read.sh:504`, `:517-519`
**Move:** 3 (caller contract at `B5 (moved)`, same security review as above), 7
**Confidence:** High for the mechanism (executed). Practical exposure is very low.
**Legibility-target:** the `isimported` comment (`:509-513`) and the lib header's caller contract (`:12-27`)

Evidence:

```
main:  imported_names                       # a plain statement, under set -e
HEAD:  elif isimported tree "$lp"; then     # dev-cycle.sh:181
504:      IMPORTED+="$(lower "$p")"$'\n'
517:   lp="$(lower "$2")"
519:     tree) imported_names; [[ "$IMPORTED" == *$'\n'"$lp"$'\n'* ]] ;;
```

On main, `check_fix` ran `imported_names` as a plain statement. The walk's one unchecked command (`IMPORTED+="$(lower ...)"`, :504) therefore stopped the script under `set -e` if it failed, which fails closed.

At HEAD, the walk runs inside the condition of `elif`, where bash ignores errexit for the whole call tree. I made `lower` fail only for edges recorded inside `imported_names`, in a scratch repo where `AGENTS.md` imports `docs/a.md`:
- a plain `imported_names` exits 3;
- `if isimported tree docs/a.md` answers "not imported" and exits 0.

`lp="$(lower "$2")"` at :517 has the same shape. If it fails, `lp` is empty and the path reads as not imported.

This is the same class as iteration-2 finding 1 (B3). U2a3 fixes that class for `main_imports` with explicit `|| { IMPORTED_MAIN=error; return 1; }` guards. The tree arm got nothing. So the unit's statement "changes to --check-fix are only toward refusing more" has one pathological exception. It needs `tr` to fail, which a same-uid run essentially never sees. The real cost is the design rule the code now implies but does not state: *every walk reached through `isimported` runs with errexit off, so every walk must check its own failures*. The lib header (:18-27) still teaches the opposite habit ("read it as `out="$(check_brief ...)"` under set -e").

**Recommendation:** Two lines:
- `lp="$(lower "$2")" || return 0` in `isimported`;
- `IMPORTED+="$(lower "$p")"$'\n' || { IMPORTED_DONE=""; IMPORTED=$'\n'; return 1; }` with the tree arm reading `imported_names || return 0`.

Then add one sentence to the `isimported` comment: "the walks run under `if`, so each checks its own failures; none relies on set -e". This is a hardening note, not a regression of practical weight. Recording it as a carried row is also proportionate.

#### 3. `import_targets` is a public seam with an unstated precondition and a status that always reads success

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:458-482` (comment `:458-467`, `:476`, `:481`)
**Move:** 3 (module boundary), 5 (interface contract)
**Confidence:** High (executed)
**Legibility-target:** `import_targets`' doc comment

Evidence:

```
476:       p="$(realpath -ms --relative-to="$ROOT_REAL" -- "$ROOT_REAL/${1:+$1/}$t" 2>/dev/null)" || continue
481:   done < <(env LC_ALL=C grep -aoE "$IMPORT_RE" || true)
```

Probes at 7697c6e6, under `set -euo pipefail`:
- With `ROOT_REAL` unset, `import_targets ""` prints `ROOT_REAL: unbound variable` twice, outputs nothing, and the caller's next line runs (`rc=0`). The unbound error happens inside `$(...)`, which is followed by `|| continue`.
- With `ROOT_REAL=""`, it outputs nothing and returns 0.
- With a directory on stdin, it prints `grep: (standard input): Is a directory`, outputs nothing and returns 0.

`import_targets` is now the contract between the parser and two walks. Its comment states the token rules but not its contract:
- It needs `ROOT_REAL` set (it has no `need_root` of its own, like `inrepo_here`).
- It always returns 0. `|| true` folds grep's "error" status (2) into "no match" (1), and every precondition failure reads as "this text imports nothing", which is the fail-open answer.

The tree walk ignores the status anyway, because it reads through `< <(...)`. U2a3's `main_imports`, however, wraps it as `out="$(... | import_targets "$d")" || { IMPORTED_MAIN=error; return 1; }`. That guard catches a failure of the producer (the redirection, `cat-file` under pipefail), but it can never see one inside the parser. Today both consumers check their input first (`inrepo_here`'s `-f`, the blob mode), so the exposure is nil. The point is that the contract is being fixed now, before its second consumer lands, and nothing says which side owns input validation.

**Recommendation:** Add two clauses to the comment: "the caller has run need_root and checked its input is a readable file; it returns 0 whatever it read, so callers cannot learn of a read failure from its status". The alternative is to let grep's status through (`rc -le 1`), so that U2a3's existing `||` guard means what it appears to mean. Either way, the seam should state who validates.

#### 4. The split's forward references are acceptable in a stack, but one decision record still names the pre-split unit

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:509-510`; `test/scripts/build-loop-check.bats:14-21`; `docs/working/questions.md:392-393`
**Move:** 1 (dependency direction across units)
**Confidence:** High
**Legibility-target:** Q-119's "If the answer differs" line

Evidence:

```
509: # Whether path $2 (any case) is imported, by the walk $1 names: tree (U2a3
510: # adds main, the walk over the default branch's commit). A walk name it does
392: ... U2a2 is the shared token parser and `isimported tree`, U2a3 the commit-reading walk, U2a4 the floor. ... Under [3], U2a3 is the unit replaced.
393: - **If the answer differs:** [2] reverts nothing on main (U2a1 stands either way); [3] replaces U2a2's walk.
```

U2a2 ships three references to code that only exists in U2a3:
- `isimported`'s comment;
- the `imps` helper's `main_imports` branch;
- the suite header.

All three are guarded (the `main` name answers "imported" until U2a3 adds the arm), and plan step 5 orders the stack. That is the right way to land a seam ahead of its second consumer. The split itself follows plan step 5's bullets exactly:
- U2a2 carries a parser and a predicate, and no policy;
- U2a3 consumes the parser unchanged;
- U2a4 consumes only `isimported main`.

The one inconsistency is Q-119. Line 392 says that under [3] the replaced unit is U2a3, and line 393 still says "[3] replaces U2a2's walk". That is also a fact-check Stale item. It matters architecturally because Q-119 is the record of which unit owns the walk if the user's answer changes the design.

**Recommendation:** Change :393 to "[3] replaces U2a3's walk (U2a2's parser stays)". No code change.

#### 5. `instruction_names` is a lib-level helper with one caller and a second spelling of `INSTRUCTION_FILE`

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:483-487`, `:441`
**Move:** 3 (public surface), 2
**Confidence:** Medium
**Legibility-target:** `instruction_names`' comment

Evidence:

```
441: INSTRUCTION_FILE='^(claude|agents?|gemini)(\.[abcdefghijklmnopqrstuvwxyz0123456789_-]+)?\.md$|^skill\.md$'
487: instruction_names() { env LC_ALL=C grep -zaiE '(^|/)((claude|agents?|gemini)(\.[a-z0-9_-]+)?|skill)\.md$' || true; }
```

Extracting `instruction_names` made the prefilter a named, inventoried lib function. Only the tree walk calls it, and U2a3's walk filters with `tr` plus `INSTRUCTION_FILE` instead. The name reads as "the instruction-file rule", but it is a lossy prefilter, and its comment says the walk's own test stays the authority. The duplication itself predates this unit (it was inline on main). The extraction only widens the surface. This does no harm, and the comment states the relationship.

**Recommendation:** None required. If a third start-set reader appears, derive the prefilter from `INSTRUCTION_FILE`, or keep it private to the tree walk.

## What Looks Good

- **The seam is real, and the consumer proves it.** U2a3's `main_imports` uses `import_targets`, `untracked_md` and `inrepo_here` without changing them. One stdin-plus-directory interface serves both a file read and a `git cat-file` pipe. This is the strongest evidence a split can have.
- **The predicate replaces the cache read.** `check_fix` reads no walk internals (dev-cycle.sh:181). The unknown-name arm fails closed (`*) return 0`). It is pinned by its own test (build-loop-check.bats test 2), so a later unit cannot ship a caller on a walk that does not exist yet.
- **The shared-contract comment exists.** `import_targets`' "Every import walk shares these rules, so a change here changes --check-fix too" resolves iteration-2 finding 4 (rubric B9).
- **The split follows plan step 5.** The policy-free parser comes first, the commit-reading walk second, the floor third. Each later unit consumes only the previous unit's public names. `inrepo`/`inrepo_here` keeps the `need_root` guard at the public entry and lets walks skip it per path, which is the accepted row-214 pattern, now documented at the definition (B10).
- **Behaviour moves in the safe direction.** The grammar changes all widen `--check-fix`'s refusal set: U+FEFF, the kept-and-stripped punctuation, `..x` followed, `grep -a`. The one corner that goes the other way is fact-check's r2 Claim 24b: a Unicode-space file name, now resolved as Claude Code resolves it. That is a correctness alignment, not a boundary change.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Token boundary is split between `IMPORT_RE` and the `UNI_SPACES` post-cut, which do not compose; an `@` after a Unicode space is lost in both walks (E1) | Minor | `scripts/lib/dev-cycle-read.sh:450-456`, `:472`, `:481` | High |
| 2 | `isimported tree` under `elif` runs the tree walk with errexit off, and the walk has no explicit failure path (main's plain call failed closed) | Minor | `scripts/dev-cycle.sh:181`; `scripts/lib/dev-cycle-read.sh:504`, `:517-519` | High (mechanism); exposure very low |
| 3 | `import_targets`' precondition (`ROOT_REAL`) and its always-0 status are unstated at the seam U2a3 guards with `\|\|` | Minor | `scripts/lib/dev-cycle-read.sh:458-482` | High |
| 4 | Q-119:393 still says "[3] replaces U2a2's walk" after the split | Informational | `docs/working/questions.md:393` | High |
| 5 | `instruction_names` is a one-caller public helper and a second spelling of `INSTRUCTION_FILE` | Informational | `scripts/lib/dev-cycle-read.sh:483-487` | Medium |

Rubric mapping (skill's table): no Structural (🔴) or Coupling (🟡) findings. Findings 1-5 are 🟢 Consider.

## Overall Assessment

The unit improves the lib's structure:
- callers reach the import walk through one fail-closed predicate;
- the grammar lives in one function that the second walk consumes unchanged;
- the U2a2/U2a3/U2a4 split cuts at a seam the downstream code confirms.

Dependency direction is correct, and there is no cycle. Nothing here needs restructuring.

The most important structural concern is finding 1. The "one grammar" claim is undercut inside the parser itself, because two boundary rules run in sequence. The resulting fail-open gap (E1) reaches the gate as soon as U2a3 lands. It is cheapest to close at the shared seam, in this unit or as an explicit carried row, and not inside `main_imports`. Findings 2 and 3 are contract notes at the same seam. Each fits in a few lines and has negligible practical exposure today. Settled rows were not re-filed; none of their triggers fired.

## Goal-Alignment Note

- **Success criterion (verbatim):** "a markdown report saved at the path given in your tail, structured per your skill, with `Commit: 7697c6e6` as its first line."
- **Answered:** this is the architecture review of the net diff at 7697c6e6. It covers:
  - the shared parser as the seam between `--check-fix`'s tree walk and U2a3's gate walk (Dependency Map; findings 1 and 3; What Looks Good, with the U2a3 consumer checked at 579ebca2);
  - `isimported` as the dispatch (finding 2; What Looks Good);
  - the U2a2/U2a3/U2a4 split per plan step 5 (finding 4; What Looks Good).
- **Out of scope:**
  - `main_imports` itself, meaning iteration-2 rows B2-B6, B8, B10-B12 and B14, which are routed to U2a3;
  - the settled override rows dated 2026-10-06 for `feat/build-loop-u2a`, `-u2a1` and `-u2a2`, none of which was re-filed, and none of whose triggers fired;
  - the correctness of individual token shapes beyond E1's structural cause (fact-check's domain, including E2 and the `[` comment).
- **Escalate:** none. Every finding is fixable in place or can be carried as a row.
- **Questions / Decisions:** for finding 1, fix E1 in U2a2 (the seam's owner) or carry it as a U2a3 row. The orchestrator decides; either is consistent with this review.
