Commit: 069ddfa9

# Security Review: feat/build-loop-u2c1 (confirming pass after the final pass)

**Scope:** `git diff fcc2dd9b..HEAD -- scripts test` (0f9b6a46 D1-D6, 069ddfa9 comment), plus the override-log rows added in fcc2dd9b (`git diff 9e7c61c5..fcc2dd9b -- docs/reviews/override-log.md`). The rest of the branch is context only.
**Date:** 2026-10-10
**Based on:** final-pass report security-review-2026-10-10-u2c1-final.md (F1 Medium, F2 Informational); probes in `u2c1-confirm-sec/` (probe.sh/probe.log, probe2.sh/probe2.log, suite.log).
**Threat model (i1, unchanged):** can a path that the D5 floor, a never glob or the Paths: allowlist should refuse land under self-merge?

## Trust Boundary Map (delta only)

The fixes touch two sinks of the final-pass map:
- B1 → srules' allowlist: the own-file arm is now gated on `"$2" == "$3"` (path as spelled equals its lower-cased spelling) before ownfile (`scripts/build-loop.sh:672`).
- B5 → srules: a failed re-read now sets the sentinel `PATHS_WHY=unread` (`scripts/build-loop.sh:825`), read at `:673` with its own deny text.

No new source, sink or primitive enters. No exec, eval, regex or glob built from repo text is added.

## Prior findings

### F1 (final, Medium): upper-case NAME own review lands under `Paths: none` — **closed**

Evidence (code, `scripts/build-loop.sh:672`):

```bash
  [[ "$2" != "$3" ]] || ! ownfile "$2" "$1" "$4" || return 0
```

The return-0 (land) happens only when `$2 == $3` and ownfile matches. `$3` is the `lower_all` spelling computed under check_line's `local -x LC_ALL=C` (`:778`, `:831`), so any ASCII upper-case letter anywhere in the path (prefix, NAME, STEM) makes `$2 != $3`, and the arm falls through to the Paths: check. Executed (probe.log, PROBE1). Main held `docs/reviews/code-review-2026-10-01-x.md`, brief x had `Paths: none`, and the branch added eight files:

```
refuse docs/working/briefs/2026-10-01-x.md: 4 of 8 changed paths refused ...
deny ... A docs/Reviews/sub2-2026-10-01-x.md: neither listed in the brief's Paths: line nor one of its own files
path ... A docs/reviews/2026-10-01-x.md
deny ... A docs/reviews/Code-Review-2026-10-01-x.md: neither listed ...
deny ... A docs/reviews/Sub-2026-10-01-x.md: neither listed ...
deny ... A docs/reviews/code-review-2026-10-01-X.md: neither listed ...
path ... A docs/reviews/r.v_2-2026-10-01-x.md
path ... A docs/working/handoff-2026-10-01-x.md
path ... A docs/working/test-strategy-2026-10-01-x.md
```

So every case variant is refused, including the collision candidate `Code-Review-…-x.md` against an existing `code-review-…-x.md`. The lower-case own files all still land: STEM.md, a NAME holding `.`, `_` and digits, and two working-doc kinds not in the existing tests. The existing test T9 (`build-loop-check.bats:1938-1945`) covers lower-case `plan-`/`research-`/`checkpoint-` working docs and `code-review-STEM.md`. The new deny row (`:1976`) covers `Code-Review-STEM.md`. Full suite at 069ddfa9: 138/138 ok (suite.log), run serially under `LC_ALL=C` and a fresh TMPDIR.

D1 opens nothing. It adds a precondition to a return-0 and removes none. The floor is unchanged: it runs first and still folds case. The never-glob loop sits above the changed line and is unchanged.

### F2 (final, Informational): failed re-read deny text said "so only its own files land" — **closed**

Evidence (`scripts/build-loop.sh:673`, `:825`):

```bash
  [[ "$PATHS_WHY" != unread ]] || { DENY="the brief could not be read again from the default branch"; return 0; }
    if brief_fields "$a"; then read_paths; else PATHS=(); PATHS_WHY=unread; co="${co:-refuse $a: the brief could not be read again from the default branch}"; fi
```

Executed with a mutant (probe2.sh): brief_fields fails only in the parent shell (`$BASHPID == $$`), i.e. check_line's re-read, and passes in status_line's subshell. Brief `Paths: docs/a` on main:

```
refuse docs/working/briefs/2026-10-01-x.md: the brief could not be read again from the default branch
deny ... A docs/a: the brief could not be read again from the default branch
deny ... A docs/b: the brief could not be read again from the default branch
deny ... A docs/reviews/Code-Review-2026-10-01-x.md: the brief could not be read again from the default branch
path ... A docs/working/plan-2026-10-01-x.md
```

It fails closed: the verdict refuses, and `docs/a`, which main's Paths: lists, is denied because PATHS was emptied. The own working doc prints as a path line, because ownfile is checked before the sentinel (`:672` before `:673`). The verdict still refuses, as --help's new text at `:155-157` says. No existing test exercises this route. It is reachable only through a main-ref race or a read fault, not by a loop.

**Sentinel collision:** PATHS_WHY is assigned only at `:632`, `:634`, `:637` (from LIST_WHY) and `:825`. list_entries sets LIST_WHY only to `is not exactly "…" with single spaces`, `lists entry N, which is not an allowed … form` or `lists entry N twice` (`:368`, `:374`, `:375`), all fixed text, never `unread`. read_paths resets PATHS_WHY before every read (`:634`), so the sentinel from one brief's failed re-read cannot carry to the next brief: either it re-reads (reset) or it fails again (set again). Policy review briefs never reach srules (`:833`). No collision.

## Findings

None that require a change.

#### N1: A Paths: entry naming an upper-case own-review spelling still lands it, so the F1 case collision is reachable by the cycle's explicit authorization

**Severity:** Informational
**Location:** `scripts/build-loop.sh:675-677` (the Paths: loop, unchanged by this range); floor's own-review arm lib `:1845`
**Confidence:** High that it lands (executed, PROBE2). Low that it matters.
**Legibility-target:** for-reviewer

Evidence (probe.log, PROBE2): brief `Paths: docs/reviews/Code-Review-2026-10-01-x.md` →

```
ok docs/working/briefs/2026-10-01-x.md 60bced90… c75eb5fc…
path docs/working/briefs/2026-10-01-x.md A docs/reviews/Code-Review-2026-10-01-x.md
```

The floor passes the path, because its lower-cased form is an added own review. The Paths: entry then matches it exactly. A `Paths: docs/reviews/` directory entry would do the same. If main already held `code-review-…-x.md`, this could collide on a case-insensitive clone, as F1 could. The difference from F1: the Paths: line comes only from main's commit (S2, cycle-written; loops cannot edit briefs/), so a loop cannot widen it. That matches the trust model, under which Paths: is the cycle's authorization. This predates the range and the range does not change it. I record it so no one reads "F1 closed" as "no case variant of an own review can ever land". No action is needed for U2c1. If U3/U4 want the review-is-a-record rule to hold even against a careless Paths: line, the floor could refuse an added review whose lower-cased spelling equals an existing entry on main.

## Override-log rows (fcc2dd9b) — security-relevant factual statements

- Row 618 (corrections, fact-check 5, 6): "a failed brief re-read now refuses the verdict, path lines still printed, with its own deny text". Accurate per probe2 (above).
- Row 620 (Accepted-immutable): the quoted commit text is verbatim. d435100e's body has "an own file lands only in lower case" and "a failed brief re-read lands only own files". eddfd5f9's has `"Paths:" alone or no`. The parenthetical "a review's NAME part still matched any case until the post-final fix" is true (F1, fixed by 0f9b6a46).
- Row 622 (advisory run prints a floor path as a path line): consistent with `:670`, where the floor runs only when `$5` is empty, and with `--help` `:181-185`. The verdict line in such a run is always the refusal (`:836`), so nothing lands by it.
- Row 617 (need_root count): performance only. I did not verify it.

## Untested

- Non-ASCII bytes in a path: `lower_all` under C leaves them unchanged, so `$2 == $3` can hold for a path with high bytes. ownfile's patterns are ASCII, and nrules' pathform refuses non-NAMECHARS first. Static only.
- Case-insensitive filesystem behaviour (as in the final pass): no writable mount.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| F1 (final) | Upper-case NAME own review lands | closed | `scripts/build-loop.sh:672` | High (executed) |
| F2 (final) | Re-read deny text | closed | `scripts/build-loop.sh:673`, `:825` | High (executed, mutant) |
| N1 | A Paths: entry can still authorize an upper-case own-review spelling (cycle-controlled, pre-existing) | Informational | `scripts/build-loop.sh:675-677` | High / Low impact |

## Overall Assessment

F1 is closed. The one-condition change refuses every case variant of an own file, and every lower-case own file still lands. F2 is closed, and the failed re-read fails closed with its own text. The `unread` sentinel cannot collide with any value list_entries produces. The fixes open no path that should be refused. The lib contract item 8 and the --help text now match the code. No findings that require a change.

## Goal-Alignment Note

The goal is to land U2c1 after a clean loop. This range does exactly what the final rubric's D1-D6 asked, adds the test row F1 requested, and adds no scope. From a security standpoint the branch is clean to merge. N1 is a note for U3/U4's design of the record rule, not a blocker, since self-merge is not switched on in this repo before U3.
