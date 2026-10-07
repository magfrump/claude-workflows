Commit: 0bb98f27

# Security Review — feat/build-loop-u2a3 (loop 2 iteration 3, final confirming pass)

**Scope:** `git diff main...HEAD` of `feat/build-loop-u2a3` at 0bb98f27 (base main 62d366a7); code in `scripts/lib/dev-cycle-read.sh` (`main_imports`, `nul_list`, `isimported main`), tests in `test/scripts/build-loop-check.bats`, docs A5/F11/U2b bullet
**Date:** 2026-10-06
**Based on:** Stage 1 fact-check summary L3 (r1-r3, 0 Incorrect), shared review context L2; role `sec3`, pass `i3`
**Probes:** run in `/tmp/u2a3-sec3-i3-CCsz` (crafted trees with `hash-object --literally`, the `ident` attribute from main's `.gitattributes` and from `$GIT_DIR/info/attributes`, pathspec environment overrides); `build-loop-check.bats` 17/17 ok at HEAD.

## Trust Boundary Map

```
B1: [main's commit: tree records, blobs, link text]          → [main_imports record parse + doubled-name + ancestor pass, :557-565] → [ent / start list]
B2: [main's blob text (instruction files, imported files)]    → [import_targets / link-text checks, :583-600]                         → [IMPORTED_MAIN path list]
B3: [checkout: index + untracked/ignored .md listing]         → [ls-files --cached --others, start-file refusal, :566-576]            → [walk fails closed]
B4: [checkout: filesystem at imported paths main lacks]       → [-d/-L/blocker probe, :610-612]                                        → [walk fails closed or records]
B5: [git attributes + config (main's .gitattributes, $GIT_DIR/info/attributes, core.attributesFile, core.symlinks)] → [none in U2a3; planned U2b refusal] → [bytes Claude Code reads differ from bytes the walk reads]
B6: [IMPORTED_MAIN / walk return]                              → [isimported main, :621-631]                                            → [U2a4 floor (no caller yet)]
```

| Label | Source | Mutability | Trust classification |
|---|---|---|---|
| S1 | main's tree records and blobs | merge-time (changes only through the gate or a human merge) | UNTRUSTED for the walk's model (crafted trees are in scope); trusted for "what main says" only after the walk's shape checks pass |
| S2 | the gate checkout (index, untracked/ignored files, filesystem) | runtime-mutable by the build-loop agent | UNTRUSTED toward every sink; the interim contract is: may only make the walk fail |
| S3 | attribute sources: main's `.gitattributes` (S1), `$GIT_DIR/info/attributes`, `core.attributesFile` | runtime-mutable ($GIT_DIR is shared by every linked worktree) | UNTRUSTED toward the "checked-out bytes equal the blob" assumption |
| S4 | caller environment (GIT_* pathspec vars, LC_ALL, GIT_INDEX_FILE, replace refs) | runtime | UNTRUSTED; git hardening owned by the caller (override row 387, U2b) |
| S5 | `INSTRUCTION_FILE`, `IMPORT_RE`, `UNI_SPACES` | code-constant | trusted |

What enters: main's commit (S1) is read as data and every shape the walk does not model fails it; the checkout (S2) is read only to fail. The one assumption the diff makes without enforcing is at B5: that the bytes a checkout writes for a path equal the blob main stores. A5/F11 document that gap for `working-tree-encoding`/`filter` and `core.symlinks=false`; it is wider than they say (Finding 1).

## Focus questions

**1. Is the iteration-2 fix complete?** Yes for the shapes I could construct. A name that main stores as both a file and a directory now fails the walk. The ancestor pass at `:565` runs after `ent` is fully populated. For every listed name it walks the ancestors upward and fails when an ancestor is itself a listed name. The memo `break` is sound: `dir[c]` is set only after `c` was checked against `ent`, and the climb from `c` to the root also continued without a break the first time `c` was reached, so every ancestor above `c` has been checked too. I executed these crafted trees (probes.sh `trees`):
- a symlink listed before a tree of the same name (unsorted, the reverse of test 17's order): walk failed
- a gitlink and a tree with the same name: walk failed
- a blob and a tree with the same name at depth 2 (`a/b` and `a/b/x.md`): walk failed
- two trees with the same name and distinct children (`l/x.md`, `l/y.md`). No full name is doubled, so the doubled-name and ancestor checks do not fire. A checkout writes both children, but `git cat-file blob main:l/x.md` resolves through the first `l` and fails, so the walk fails closed through the "a blob cannot be read" arm.

Every case answered `imported` for the probe paths. Test 17 pins the tree-before-link order.

**2. The `ident` gap compared with the settled rows 391 and 392.** It belongs to the same class as rows 391 and 392 and has the same severity (Medium). There is one piece of new evidence: the "needs a human-reviewed `.gitattributes` change" premise in row 391 does not hold for every attribute source. See Finding 1.

**3. Anything else fail-open in the final code?** I found nothing new in U2a3's own code. A failing `lower` at `:606` records an empty line instead of failing the walk. That gap is already fixed in U2a3b (stacked; verified at ac1a8b7b:648) and is Finding 2 for the record. Pathspec environment overrides do not hide an untracked start file (probe2.sh): with `GIT_NOGLOB_PATHSPECS=1`, `GIT_ICASE_PATHSPECS=0`, `GIT_GLOB_PATHSPECS=1` or `GIT_LITERAL_PATHSPECS=1`, the walk still failed.

## Findings

#### 1. Checkout conversions beyond the documented set: `ident`, and attribute sources other than main's `.gitattributes`

**Severity:** Medium
**Location:** `scripts/lib/dev-cycle-read.sh:583` (blob read as the walk's text); `docs/working/known-issues-dev-cycle.md` A5; `docs/working/plan-build-loop-handoff.md` F11 and the U2b bullet
**Boundary:** B5 (with B2)
**Move:** 1 (trust boundaries), 5 (invert the model: denylist of named attributes), 11 (bypass enumeration)
**Confidence:** High on the git-side mechanism (executed); Low on reachability in practice
**Evidence:** executed. Probe `probes.sh ident`:
- `AGENTS.md` contains `see @docs/x$Id$ here`, and main's `.gitattributes` sets `AGENTS.md ident`. The checkout is written as `see @docs/x$Id: 90d513cb… $ here`. The walk returns `ok` with `docs/x$Id$: imported` and `docs/x$Id:: -`. Claude Code's token ends at the blank, so it imports `docs/x$Id:`, a path the walk does not record.
- Variant p1b: the identical result with no attribute in main's tree at all, from `printf 'AGENTS.md ident\n' > .git/info/attributes`. A fresh linked worktree inherits it, because `info/attributes` lives in the common git dir.
**Legibility-target:** A5 row, the F11 cell and the U2b bullet (the author / U2b owner)

This re-raises override-log rows 391 and 392 in scope only. I am not asking to reverse their deferral. The new evidence has two parts:
- `ident` is a third conversion class that A5, F11 and the U2b refusal set do not name. The L2f review called it harmless; the r1 fact-check probe and this one refute that.
- Row 391's justification ("Needs a human-reviewed `.gitattributes` change") and the U2b bullet's planned check ("a checkout whose `.gitattributes` sets …") both assume main's `.gitattributes` is the only source of attributes. `$GIT_DIR/info/attributes` and `core.attributesFile` apply the same conversions with no change to main and no human review. `working-tree-encoding` set there transcodes main's existing bytes, as in row 391's ISO646-DE case, with nothing committed.

Exploit sketch: a self-merge branch adds `docs/x$Id:` holding arbitrary instructions. The floor does not see that path as imported, but Claude Code loads it. This needs either main to carry a `$Id$` inside an import token (human-reviewed), or write access to `$GIT_DIR`. Write access to `$GIT_DIR` is near host-equivalent while hooks are live (row 387), which is why confidence in reachability is Low. A hardened wrapper that neutralises hooks would leave `info/attributes` as a residual, which is why the floor rule keeps this at Medium.

Not exploitable today: U2a3 has no caller, and F11 already says not to rely on the floor before U2a3c.

**Recommendation:**
- Add `ident` to A5, F11 and the U2b refusal set.
- Word the planned U2b refusal as `git check-attr` (`-a`, or the named conversion attributes `filter`, `ident`, `working-tree-encoding`) run in the gate's checkout over every path the walk reads. That covers all attribute sources, unlike a parse of main's `.gitattributes`.
- Note in row 391's revisit trigger that `info/attributes` and `core.attributesFile` are in scope.

By static reading, `text`/`eol`/`crlf` add or remove only a CR. `IMPORT_RE`'s `[:space:]` (C locale) and JavaScript's `\s` both end a token at CR, so I did not add them (untested; listed below).

#### 2. A failing `lower` records an empty line instead of failing the walk

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:606`
**Boundary:** B2 → B6
**Move:** 3 (error path)
**Confidence:** High (read-static, and the stacked fix was checked)
**Evidence:** read-static. `IMPORTED_MAIN+="$(lower "$p")"$'\n'` ignores the substitution's status, so a `tr` that fails (fork failure or ENOMEM) drops `p` from the list while the walk still returns 0. `feat/build-loop-u2a3b` at ac1a8b7b:648 has `i="$(lower "$p")" || { IMPORTED_MAIN=error; return 1; }`.
**Legibility-target:** none needed in U2a3. This is fixed in U2a3b (stacked), and the shared context already names "fails closed on a failing … lower" as U2a3b's.

Not reachable without resource exhaustion on the host. It is recorded so that U2a3 does not merge without U2a3b before U2a4 relies on it. That merge order is already the plan.

**Recommendation:** none for U2a3. Keep U2a4 stacked above U2a3b, as planned.

## Untested bypass candidates

- **Doubled-name/ancestor guard (`:561-565`):** two names that differ only in case (`L` symlink, `l/x.md` tree) collide on a case-insensitive checkout. This is documented as an A5 gap, and I did not construct it. Unicode-normalisation collisions on macOS (override row 393) are also untested.
- **Start-file refusal (`:566-576`):** `GIT_INDEX_FILE`, a `core.fsmonitor` hook, a sparse checkout and replace refs (override row 387, deferred to U2b) were not re-tested.
- **Checkout conversions (B5):** `filter=lfs` with host LFS config (row 393); `text`/`eol` CR conversions (static reasoning only, see Finding 1); `core.attributesFile` (inferred from git's attribute precedence, not executed; `info/attributes` was executed).

## Endorsement Claims

- **Claim:** When `main_imports` returns 1, `isimported main` answers imported (exit 0) for any path.
  **Location:** `scripts/lib/dev-cycle-read.sh:621-631`
  **Evidence:** executed
  **Verified:** five crafted-tree probes (p2-p5) and five pathspec-environment probes: each printed `walk: failed` followed by `imported` for every probed path, including paths no import names (`a/b/secret.md` in p2).
  **Not verified:** a caller under `set -e` that calls `isimported main` outside an `if` (U2a4's floor, not yet written).
  **route: code-fact-check**

- **Claim:** `nul_list` returns 1 and empties the array unless the command exits 0 and its output is empty or ends in NUL. The `rc=0` marker fuses with an unterminated last record, so the marker test fails.
  **Location:** `scripts/lib/dev-cycle-read.sh:519`
  **Evidence:** read-static
  **Verified:** read the one-line function, both call sites (`:557`, `:566`), and the use of `recs` after each.
  **Not verified:** a command that writes a record ending in the literal bytes `rc=0` followed by NUL and then exits non-zero (the appended `rc=1` then becomes the last element, which reads as a failure; traced, not run).
  **route: code-fact-check**

I verified the iteration-2 ancestor pass by execution (Focus question 1). It is not listed as an endorsement because the case-folding candidate above is untested (move 11).

## Primitive sweep

Primitive: git object reads and path joins (path construction / file I/O)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `dev-cycle-read.sh:557` `git ls-tree -r -z --full-tree "$MAIN_SHA"` | S1 | `nul_list` whole-listing check; record regex `:559` | cleared: argv array, hash-only rev |
| `dev-cycle-read.sh:566` `git ls-files -z --cached --others ':(glob,icase)**/*.md'` | S2, S4 | `nul_list`; explicit magic | cleared: pathspec env probes failed closed; GIT_INDEX_FILE etc. deferred (row 387) |
| `dev-cycle-read.sh:583` `git cat-file blob "$MAIN_SHA:$f"` | S1, S3 | pipefail; the blob is not the checked-out bytes | Finding 1 (conversion gap, B5) |
| `dev-cycle-read.sh:587-588` `git cat-file blob` (link text) | S1 | NUL count, `x` sentinel, empty/newline/absolute refusal | cleared: crafted-link probes from earlier passes; `core.symlinks=false` is row 392 |
| `dev-cycle-read.sh:596`, `:599` `realpath -ms` joins | S1, S2 (`-L`) | `..`-after-link refusal; result outside the root fails | cleared: lexical join refused where the kernel would differ |
| `dev-cycle-read.sh:503` `realpath -ms` in `import_targets` | S1 | drops paths outside the root | cleared (U2a2 parser; U2a3b reworks) |
| `dev-cycle-read.sh:612` `-d`/`-L`/`-e`/`blocker` on the checkout | S2 | fail unless absent or a plain directory | cleared: probe-time check; checkout drift after the walk is settled (cache row) |
| `dev-cycle-read.sh:275`, `:326`, `:729` (`main_entry`, brief and answer reads) | S1 | outside this diff | not analysed (not changed by this branch) |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | `ident` and non-tree attribute sources (`info/attributes`, `core.attributesFile`) are checkout conversions missing from A5/F11/U2b's planned refusal | Medium | B5 | `dev-cycle-read.sh:583`; A5; F11; U2b bullet | High (mechanism) / Low (reachability) |
| 2 | Failing `lower` records an empty line (fixed in U2a3b, stacked) | Informational | B2→B6 | `dev-cycle-read.sh:606` | High |

## Overall Assessment

No fail-open in U2a3's own code paths was found within the paths I read and probed. The iteration-2 fix fails every file-and-directory shape I could construct, including orders and record types that test 17 does not cover. Endorsement claims are pending execution verification where they are read-static.

The one material issue is documentation and design: Finding 1 widens the settled conversion rows (391, 392) by `ident` and by attribute sources outside main's tree. It is fixable in place in the docs, and U2b's refusal should be built on `git check-attr` in the gate checkout rather than on main's `.gitattributes`. It does not block merging U2a3: there is no caller yet, and F11 already gates reliance on U2a3c. The single most important follow-up is that wording change to U2b's planned refusal, so that the "fresh worktree" premise is not read as making the checkout's attributes trustworthy.

## Goal-Alignment Note

**Success criterion (verbatim):** A markdown report saved to docs/reviews/security-reviewer-review-2026-10-06-L3-build-loop-u2a3.md, structured per the security-reviewer skill.

**Answered:**
- The iteration-2 fix is complete for the constructible shapes: link-first, gitlink+tree, depth-2 blob+tree, and same-name trees, all executed.
- `ident` is rated Medium in the same class as rows 391 and 392. The new evidence is that attributes from `$GIT_DIR/info/attributes` reach a fresh worktree without any change to main.
- No other fail-open in the final U2a3 code; `lower` is fixed in U2a3b.
- Pathspec environment overrides fail closed.

**Out of scope:** U2a3b's parser changes; U2a3c's checkout phase; U2a4's floor caller; git hardening (row 387).

**Escalate:** author / U2b owner: add `ident` and the non-tree attribute sources to A5, F11 and the U2b bullet, and specify the refusal as `git check-attr` in the gate checkout (Finding 1). No HALT-pattern match.
