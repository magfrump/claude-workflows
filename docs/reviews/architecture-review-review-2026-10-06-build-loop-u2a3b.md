Commit: 7ddff454

# Architecture Review — feat/build-loop-u2a3b (iteration 2, loop pass)

**Scope:** `git diff 45ad17b0..7ddff454 -- scripts test` (scripts/lib/dev-cycle-read.sh :440-650 and the lib header; test/scripts/build-loop-check.bats). U2a3's main_imports, already on the branch, is context.
**Date:** 2026-10-06
**Based on:** `docs/reviews/code-fact-check-report-build-loop-u2a3b-i2.md` (Commit: 7ddff454; 22 verified, 3 mostly accurate)
**Trust-boundary map:** `docs/reviews/security-reviewer-review-2026-10-06-final-build-loop-u2a2.md` (Commit: `7697c6e6`). That security review predates this diff, so its boundaries may be stale. Its labels B2, B3 and B4 are cited below.

**Scope check:** in scope under *Public APIs*, because the failure contracts of lib functions change. import_targets, instruction_names and imported_names now return non-zero, and isimported tree now answers "imported" on a failed walk. It is also in scope under *Cross-cutting concerns*: the error pipeline across both walks, and the shared token grammar that every walk and `--check-fix` read. Settled rows 343, 347 and 348 are not re-filed.

## Dependency Map

- `scripts/dev-cycle.sh` `check_fix` (:170-184) → `isimported tree` → `imported_names` → {`git ls-files`, `untracked_md`, `instruction_names`, `lower`, `inrepo_here`→`blocker`, **`import_targets`**}.
- The U2a4 floor (planned) → `isimported main` → `main_imports` → {`git ls-tree`, `untracked_md`, `tr`, `inrepo_here`, `git cat-file`, **`import_targets`**, `lower`}.
- `import_targets` → {`UNI_SPACES`, `IMPORT_RE`, `sed`, `grep`, `realpath`, `ROOT_REAL`}. Its rules depend on an external, unversioned reference: Claude Code's loader (the marked lexer plus the import regex; B4/S5 in the security map).
- Dependencies point the right way. The callers depend on `isimported`, and the walks depend on the parser. Neither caller reads a walk's cache variable: check_fix uses the predicate only. The one dependency that crosses outward is the parser's on Claude Code's grammar (finding 1).

## Findings

#### 1. The parser now mirrors one Claude Code version's grammar, but no plan, known-issue or code text records the version or says when to re-check it

**Severity:** Coupling
**Location:** `scripts/lib/dev-cycle-read.sh:482`, `:487-499`; `docs/working/plan-build-loop-handoff.md:126` (F11)
**Move:** 7 (coupling surface), 1 (dependency direction)
**Confidence:** Medium
**Legibility-target:** for-author

Evidence:
```
IMPORT_RE='(^|[^[:alnum:]])@[^[:space:]\\#]+'
```
```
# blank, a UNI_SPACES space included, or at a backslash, as the import token of
# Claude Code does, and at #, where Claude Code cuts the name it captured (so a
# token after a # is an over-read; ...
# ... while the Markdown
# around a token (emphasis, a link or image, inline HTML, a code span) may end
# it sooner, so each token yields its whole, its part before the first of
# [ ] ( ) < ! * _ or a backtick, ...
```
(excerpt ends :499; the enclosing comment block runs to :499 and import_targets() continues to :519. Read in full.)

The security map already names this dependency: "B4: [Claude Code's real grammar: marked lexer + reo (S5)] → [IMPORT_RE / UNI_SPACES / token-end rules (S4)]", and "S5 | Claude Code 2.1.292 loader (marked + `reo`) | external, version-dependent". (B4 comes from the security review at Commit `7697c6e6`, which predates this diff, so the boundary may be stale.)

Before this unit, the parser used its own conservative token: it ended at brackets, parentheses and backticks. Now it reproduces the shape of 2.1.292's capture regex, and its cut set copies the points where marked's inline lexer ends a text token. That makes the gate's correctness depend on the shipped bytes of an external tool that changes without notice. When those bytes change, every walk under-reads silently and fails open. The security review states the invariant: "the walk's token set has to be a superset of the names Claude Code resolves".

The lib comment says "as the import token of Claude Code does" but gives no version. Plan F11 (`:126`) lists only A5's gaps. Known issues A2/A3/A5 do not mention grammar drift either. The repo has a precedent for this kind of dependency. Decision log row 65 pins the separate import finder in `test/agents-gemini-sync.bats` to "v2.1.284, read from the binary" and gives it a trigger: "Revisit if Claude Code's import grammar widens". That makes two independent encodings of one external grammar, at two different recorded versions (2.1.284 there; 2.1.292 only in review artifacts here), and they do not reference each other.

**Recommendation:** Record the dependency where the plan reader will find it. Add the version (2.1.292) and the method used to read it (`grep -aoE` on claude.exe, as in fact-check Claim 2) to the import_targets comment and to F11's "partly" text, or to a new known-issue row. Give it a revisit trigger in log 65's form (a Claude Code upgrade that changes the import regex or the Markdown lexer), and cross-reference the agents-gemini-sync finder. Do not merge the two encodings: they serve different purposes, one flagging and one resolving.

#### 2. The tree walk's new failure contract never reached its only production caller, so `--check-fix` reports a failed walk as an import

**Severity:** Minor
**Location:** `scripts/dev-cycle.sh:181-182`; `scripts/lib/dev-cycle-read.sh:629-643` (isimported header and body)
**Move:** 3 (module boundary), 6 (substitutability of the `isimported tree` contract)
**Confidence:** High
**Legibility-target:** for-author

Evidence:
```
  elif isimported tree "$lp"; then
    echo "skip $a: an instruction file imports it with @ (directly or through another import), so it is read as instructions; file it instead"
```
```
# A failed walk, or a walk name that is neither, answers imported (0), so
# a caller testing it with `if` refuses; a caller that words a failed walk
# runs main_imports first.
```
(isimported() is read in full, :634-643: `tree) imported_names || return 0; ...`.)

Before this unit, `isimported tree` could not fail, and imps' header still says "tree always reads ok". Now any failing command in the tree walk answers 0. The fail direction is correct: check_fix skips. But the isimported header tells only main's callers how to word a failure. The one production tree caller, check_fix, reports a corrupt index or a failing tr as a specific false fact about the path. I executed this: a scratch copy of 7ddff454, a fixture where AGENTS.md imports only docs/a.md, then `printf junk > .git/index` and `bash scripts/dev-cycle.sh --check-fix docs/b.md`. The output was:
```
fatal: .git/index: index file smaller than expected
skip docs/b.md: an instruction file imports it with @ (directly or through another import), so it is read as instructions; file it instead
```
The same fixture with a clean index prints `ok docs/b.md`. So a reader, the dev-cycle skill included, is told to file a fix because of an import that does not exist. This is the B3 path in the security map ("[check_fix → isimported tree] → [skip / check_path ok]"; Commit `7697c6e6`, which predates this diff, so it may be stale). The recommendation keeps the refusal where B3 places it, so it carries no security implication.

**Recommendation:** Generalize the header's sentence to name both walks ("runs imported_names or main_imports first"). Have check_fix call `imported_names` before `isimported tree` and print a separate skip reason for a failed walk, the way the floor will for main. Update imps' "tree always reads ok" (`test/scripts/build-loop-check.bats:14`) at the same time (finding 5).

#### 3. The "listing ends with rc=0" pattern now has three copies, which drop the marker in two different ways

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:534-535` (new); main_imports `:573-575` and `:583-585` (U2a3 code, context)
**Move:** 8 (extension points), 7
**Confidence:** Medium
**Legibility-target:** for-author

Evidence:
```
  mapfile -d '' recs < <(set -o pipefail; { git ls-files -z && untracked_md; } | instruction_names && printf rc=0 || printf rc=1)
  [[ ${#recs[@]} -gt 0 && "${recs[-1]}" == rc=0 ]] || return 1
  for f in "${recs[@]:0:${#recs[@]}-1}"; do
```
(excerpt ends :536; enclosing imported_names() continues to :553. Read in full.)
```
  mapfile -d '' recs < <(untracked_md && printf rc=0 || printf rc=1)
  [[ ${#recs[@]} -gt 0 && "${recs[-1]}" == rc=0 ]] || return 1
  unset 'recs[-1]'
```
(excerpt ends :585; enclosing main_imports() continues to :628. Read in full.)

Each copy is correct only under two invariants that its call site has to meet on its own. First, every record the command prints must be NUL-terminated, so the unterminated marker becomes the last element. Second, no record may equal `rc=0`. For the tree walk, the second holds because instruction_names requires `\.md$` (fact-check Claim 1). For ls-tree, it holds because of the record format. Nothing states these invariants once. The two walks already strip the marker differently (array slice versus `unset`). The coming U2a4 floor and U2b's `--check` are likely to add more listings. A fourth copy that pipes through a filter that does not terminate with NUL would make the check pass wrongly. The answer to the dispatch question is yes, mildly: this is the walks' fail-closed primitive, and it belongs in one place.

**Recommendation:** Add one helper, for example `nul_listing ARRAY CMD...`. It would run `CMD && printf rc=0 || printf rc=1` under pipefail, check the marker, strip it into the named array (`local -n`), and document both invariants once. Then convert all three sites. If that is deferred, a one-line comment at :533 that names the two invariants would do.

#### 4. A failing inrepo_here skips the path in the tree walk but fails main's walk closed

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:452-453`, `:537`, `:550` (tree); `:601-603` (main, U2a3 code, context)
**Move:** 3, 2
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

Evidence:
```
# the parser fails (each call sits in an `if` or `||`, where set -e is off); an
# inrepo_here that fails skips its path.
```
```
      if inrepo_here "$f"; then out="$(import_targets "$d" < "$f")" || { IMPORTED_MAIN=error; return 1; }
      elif [[ -d "$f" && ! -L "$f" && -z "$(blocker "$f" dir)" ]]; then continue  # a directory: nothing loads
      elif [[ -e "$f" || -L "$f" ]]; then IMPORTED_MAIN=error; return 1
```
(excerpt ends :603; the main_imports() queue loop continues to :626. Read in full.)

`inrepo_here` → `blocker` → `rawfile` treats a failing `realpath -e` as "blocked". The predicate therefore cannot tell "a symlink or non-plain file", a legitimate skip that A2/A3 track, from "the check itself errored". Main's walk falls through to `-e`/`-L` and fails closed. The tree walk skips, so it stops following that file's imports. That is fail-open on the B2 boundary ("[instruction_names, untracked_md, inrepo_here] → [walk start set / queue]"; Commit `7697c6e6`, which predates this diff, so it may be stale). The new header sentence documents the asymmetry but does not justify it. The impact is small: the tree walk is `--check-fix`'s, A2/A3 already accept its symlink misses, and a realpath failure on an existing file is rare. I am recording it so that the "both walks fail closed" claim in the PR intent is read with this exception.

**Recommendation:** None required for this unit. If the tree walk is ever given main's stance, copy main's `elif [[ -e "$f" || -L "$f" ]]` refusal into the queue loop. Otherwise, add "except a path inrepo_here rejects (A2/A3)" to the claim. **Security implication:** copying main's refusal would turn a symlinked start file or target from a skip into a failed walk on B2, so every `--check-fix` in a repo with one would refuse. A combined architecture/security pass should weigh that.

#### 5. imps never reports the tree walk's status, so its "walk ok" is vacuous for tree now that the tree walk can fail

**Severity:** Informational
**Location:** `test/scripts/build-loop-check.bats:14`, `:20` (unchanged helper); `:64`, `:301` (new uses)
**Move:** 6
**Confidence:** High
**Legibility-target:** for-author

Evidence:
```
# "walk: ok" or "walk: failed" (main_imports' return; tree always reads ok),
```
```
        if [[ "$w" != main ]] || main_imports; then echo "walk: ok"; else echo "walk: failed"; fi
```
```
        want walk ok; for p in "${ps[@]}" docs/k.md; do want "$p" imported; done; want docs/other.md -
```

For `w=tree`, `want walk ok` always passes, and every `want … imported` would also pass on a failed walk, because isimported answers 0. The two new "both walks" tests still catch a failed tree walk, but only through their single negative assertion (`want docs/other.md -`). A future tree test with only positive assertions would pass vacuously. This is the test-side half of finding 2: the helper's contract predates the failure contract.

**Recommendation:** Make imps call `imported_names` for `w=tree`, the way it calls `main_imports` for main, and drop "tree always reads ok". (The test-strategy lane owns any further pinning.)

## What Looks Good

- **One parser, one grammar for both walks.** `import_targets` is the only place where token rules live. The Unicode-space and NUL normalization moved from a per-token post-filter into the parser's sed pre-pass, so neither walk does any token handling of its own, and `--check-fix` and the floor stay in lockstep. That answers the dispatch's first question: yes.
- **Fail-closed responsibilities sit at the right layers.** The mechanism is in `import_targets` (returns 1; "Two steps, not a pipe" keeps grep's no-match from masking a sed failure). Walk state is in the walks (`IMPORTED=error` set before every early return, and a cached error returns 1 again, which mirrors main_imports' `IMPORTED_MAIN_DONE` handling). Policy is in `isimported` (any failure, including its own `lower`, answers "imported"). Callers stay ignorant of the cache format, as plan amendment D5 required.
- `instruction_names` now separates "no match" from an error (`|| [[ $? -eq 1 ]]`) instead of `|| true`. That puts the error contract at the function boundary rather than at every caller.
- The tree walk's start-list check reuses main_imports' rc-marker shape instead of inventing a second mechanism. Finding 3 only asks to name it once.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Parser mirrors Claude Code 2.1.292's grammar with no recorded version or revisit trigger (plan F11, known issues, code comment); a second encoding in agents-gemini-sync.bats is pinned at 2.1.284 | Coupling | `scripts/lib/dev-cycle-read.sh:482`, `:487-499`; plan `:126` | Medium |
| 2 | Failed tree walk is reported by `--check-fix` as "an instruction file imports it with @"; isimported's wording guidance names main only (executed) | Minor | `scripts/dev-cycle.sh:181-182`; `scripts/lib/dev-cycle-read.sh:629-643` | High |
| 3 | rc-marker listing pattern in three copies, with two marker-drop idioms and per-site invariants; wants one helper | Minor | `scripts/lib/dev-cycle-read.sh:534-535`, `:573-575`, `:583-585` | Medium |
| 4 | Failing inrepo_here: skip (fail-open) in the tree walk, fail closed in main; the header documents it without a reason | Informational | `scripts/lib/dev-cycle-read.sh:452-453`, `:537`, `:550`, `:601-603` | Medium |
| 5 | imps' "tree always reads ok" is stale; `want walk ok` is vacuous for tree | Informational | `test/scripts/build-loop-check.bats:14`, `:20`, `:64`, `:301` | High |

## Overall Assessment

The change improves the lib's structure. The token grammar is consolidated into the one shared parser, and the failure handling follows a clean three-layer split (parser returns, walk caches the error, predicate refuses), with the same mechanism in both walks. The issues can all be fixed in place, and none needs restructuring. The most important concern is finding 1. The parser now deliberately mirrors one Claude Code version's lexer and regex, so the gate's soundness depends on an external contract that changes silently and fails open when it does. The security review names that dependency (B4), but the plan and the known issues do not, and no revisit trigger exists. Finding 2 is the most immediately visible to a user: a new failure mode surfaces under a wrong reason. No disagreement with the security trust-boundary placement.

## Goal-Alignment Note

- Success criterion (verbatim): "A markdown report saved at the output path named in your role section below, structured per your skill, with a `Commit: 7ddff454` line at the top."
- Answered: yes. All four dispatch questions are answered. On one source of truth: yes (What Looks Good). On fail-closed layering: correct, with two edge cases (findings 2 and 4). On whether the rc-marker pattern wants a helper: yes, Minor (finding 3). On grammar coupling for F11 and known issues: yes, Coupling (finding 1).
- Execution: one probe, finding 2, in `/tmp/u2a3b-arch-SYp4` (`git archive 7ddff454`; fixture repo `repo/`). No process was left running. Everything else was static, building on the fact-check report's executed claims (1, 2, 5, 14, 16b).
- Out of scope: test pinning of the unpinned guards (test-strategy; fact-check escalation), and A5's missing escaped-space text (fact-check Claim 3).
- U2a3 code (context): finding 3's two main_imports sites and finding 4's main-side branch are cited as comparisons, not as defects in U2a3.
- Decisions I made: I rated finding 1 Coupling, not Minor. The new design ties fail-open soundness to an external grammar, and the repo's own precedent (log 65) records a version and a trigger for exactly this. I rated finding 2 Minor, not Coupling, because the refusal direction is correct and only the reason is wrong.
