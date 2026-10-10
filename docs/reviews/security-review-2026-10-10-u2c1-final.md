Commit: 9e7c61c5

# Security Review: feat/build-loop-u2c1 (final confirming pass, full branch)

**Scope:** `git diff main...HEAD` at 9e7c61c5: scripts/build-loop.sh, scripts/lib/dev-cycle-read.sh, test/scripts/build-loop-check.bats, docs/working/plan-build-loop-handoff.md, and the override-log rows dated 2026-10-10. Review reports are out of scope.
**Date:** 2026-10-10
**Based on:** u2c1-final-fc-summary.md and the replicates docs/reviews/code-fact-check-report-build-loop-u2c1-final-r1.md, -r2.md, -r3.md (r3's E7 probe is the evidence behind F1). Earlier passes: security-review-2026-10-10-u2c1.md and -i2.md.
**Threat model (i1):** can a path that the D5 floor, a never glob or the Paths: allowlist should refuse land under self-merge?

## Trust Boundary Map

```
B1: loop branch tree (diff-tree paths, modes, status)  → nrules (pathform, mode, own brief, cycle names + prefix loop) → srules
B2: brief text on MAIN_SHA (Paths: line)                → brief_fields → list_entries/pathform (read_paths)              → PATHS allowlist
B3: docs/dev-cycle.md on MAIN_SHA (Self-merge never:)   → read_settings → list_entries/globform → never_res              → NEVER_RES regexes
B4: the checkout --check runs from                      → checkout_gate (co) → floor's import walk (only when co empty)   → FLOOR_WHY
B5: per-brief verdict (check_line, now in parent shell) → $GATE_TMP/line → head -c 3 == "ok "                              → exit status for U3
```

| Label | Source | Mutability | Trust (per sink) |
|---|---|---|---|
| S1 | changed paths, modes and status letters of the loop's merge | request-time (loop-written) | UNTRUSTED for every gate decision; the shown path is printed only when every character is in NAMECHARS |
| S2 | brief's Paths: line, read from main's commit | runtime-mutable (cycle-written; briefs/ is N-denied to loops, and the merge's copy is never read) | trusted as the cycle's authorization for the allowlist sink only; parsed strictly (malformed: own files only) |
| S3 | Self-merge never: line in docs/dev-cycle.md on main | runtime-mutable (user/cycle-written) | trusted as extra refusals; globform-restricted characters before becoming regexes |
| S4 | the brief path argument `$a` and its stem | request-time (caller) | validated by status_line (anybrief); stem drives ownfile |
| S5 | the checkout's files (for the floor's walk) | runtime-mutable | UNTRUSTED; gated by checkout_gate before the walk |

What enters from outside is the loop's tree (S1); the allowlist (S2) and denylist (S3) come only from main's commit, so a loop cannot widen either by editing them in its own branch. The branch adds the S rules as a deny chain floor → never → allowlist. The case rule is where it breaks down: the floor folds case, and the allowlist is meant to fold nothing.

## Findings

#### F1: An added review with any upper-case letters in NAME counts as the brief's own file, so it lands under `Paths: none`, though the plan, --help and srules all say own files land only in lower case

**Severity:** Medium
**Location:** `scripts/lib/dev-cycle-read.sh:1810`; `scripts/build-loop.sh:665`; claimed at `scripts/build-loop.sh:185-186`, `docs/working/plan-build-loop-handoff.md:311`, srules' comment `scripts/build-loop.sh:654-657`
**Boundary:** B1
**Move:** 11 (bypass enumeration), 5 (invert the access model)
**Confidence:** High that it lands (executed twice). Medium on the impact, which is inferred from how git checks out case-colliding entries; I did not run it on a case-insensitive filesystem.
**Legibility-target:** for-author

Evidence: the code.

```bash
  ! ownfile "$2" "$1" "$4" || return 0                                   # build-loop.sh:665, $2 as spelled
  [[ "$3" == A && "$1" == docs/reviews/* && "$b" != */* && ( "$b" == "$2.md" || "$b" == *"-$2.md" ) ]]   # lib:1810
```

The text it contradicts, at build-loop.sh:185-186: `the allowlist takes these only in lower case, though the floor passes any case`. At plan:311: `an own file counts only when the diff spells it in lower case, as ownfile's patterns are (i1 security 2)`.

ownfile's `*"-$2.md"` takes NAME as a glob, so NAME may hold upper-case letters. The `docs/reviews/` prefix and STEM are matched case-sensitively, but NAME is not. In my probe FSEC1 (`u2c1-final-security/probe.log`), main held `docs/reviews/code-review-2026-10-01-x.md` and brief x had `Paths: none`. The run printed `path … A docs/reviews/Code-Review-2026-10-01-x.md` and `path … A docs/reviews/Sub-2026-10-01-x.md` (both land). Only the STEM-case variant was refused: `deny … A docs/reviews/code-review-2026-10-01-X.md: neither listed in the brief's Paths: line nor one of its own files`. The fact-check replicate r3 (E7) saw the same result.

The floor lower-cases the path and treats it as an own review, so the allowlist is the only check meant to refuse this case variant, and it does not. The added entry is a new path in git's tree. On a case-insensitive checkout (a human's macOS or Windows clone), though, it collides with the existing `code-review-…-x.md`, and whichever file is written last wins. A self-merge can therefore in effect rewrite one of this brief's existing reviews. The lib's rule says `a modified or deleted review is never its own: reviews are records` (lib:1804-1805), so this breaks it. The reach is limited to reviews ending in `-STEM.md`: this brief's own reviews, or a sibling's under row 609's precondition. The gate's own runs are not affected, because checkout_gate refuses core.ignoreCase. i1 F2 was fixed for working docs and STEM.md reviews, and my i2 pass confirmed that fix "for every route a loop can reach" but missed this NAME arm. This is the same class of bug, still open in one arm.

**Recommendation:** In srules, accept an own file only when the whole path is lower-case: `[[ "$2" == "$3" ]] && ownfile "$2" "$1" "$4" && return 0`. This also meets contract item 8's "pass ownfile a lower-cased path" (lib:90-93), which the fact-check flags as stale. Then add `docs/reviews/Code-Review-STEM.md` to the "spelled in lower case" test (build-loop-check.bats:1967) as a deny. The other option is to narrow the three texts to "the working docs and STEM.md", but that leaves the collision open.

#### F2: When the brief re-read fails, every non-own deny line still says "so only its own files land", though the verdict now refuses everything

**Severity:** Informational
**Location:** `scripts/build-loop.sh:666`, `scripts/build-loop.sh:817`; `docs/reviews/override-log.md:613`
**Boundary:** B5
**Move:** 3 (error path)
**Confidence:** High (static; the fact-check replicates r1 and r2 report the same)
**Legibility-target:** for-author

Evidence: `PATHS_WHY="could not be read again"; co="${co:-refuse $a: the brief could not be read again from the default branch}"` (:817), then `DENY="the brief's Paths: line $PATHS_WHY, so only its own files land"` (:666). Override row 613 still says the failed re-read "now lands only own files with every line printed". Since C1 the verdict line is a refuse, so this fails closed and closes my i2 F1. Only the per-path text and the row are wrong about what lands. Nothing a loop can trigger changes the outcome.

**Recommendation:** When the re-read fails, word the per-path reason without "so only its own files land", or leave it out (the verdict line already carries the reason). Amend row 613 in the next override-log edit.

## Bypass candidates tested (move 11, whole branch)

| Guard | Candidate | Outcome |
|---|---|---|
| allowlist (ownfile as spelled) | `docs/reviews/Code-Review-STEM.md`, `docs/reviews/Sub-STEM.md` under `Paths: none` | **lands** (FSEC1; r3 E7): F1 |
| allowlist (ownfile as spelled) | `docs/reviews/code-review-2026-10-01-X.md` (STEM case) | refused (FSEC1) |
| allowlist (ownfile as spelled) | `Docs/Working/Plan-STEM.md` unlisted | refused (test :1967; r3 E7) |
| globals across briefs | brief x `Paths: src/`, brief y self-merge with no Paths:, both in one --check | y's `src/b` denied with NLIST, x's `src/a` lands (FSEC2b): BRIEF, PATHS and LIST do not leak |
| Paths: parser | `Paths: src//`, `Paths: src/./a` | malformed, only own files (FSEC3) |
| Paths: parser | `Paths: none src/` | two entries, `none` (a file) and `src/`; src/a lands (FSEC3). The cycle wrote src/, so this widens nothing a loop controls |
| never regex | `?rc/` against `src/q`, `SRC/Q`; `s*/a` against `sx/a`, `sx/sub/a` | the first three denied; `sx/sub/a` passes (`*` stays within one part, as --help says) (FSEC4) |
| never regex | ERE metacharacters in a glob | globform allows only `*?` and NAMECHARS. never_res escapes `.` and maps `*`/`?`, and `-`, `_`, `/` are literal outside brackets (static, never_res :636-646) |
| Paths: from the merge | the loop edits its own brief's Paths: line | not read: brief_fields reads `$MAIN_SHA:$1` (lib :386-405), and nrules lets the own brief change only its Status line |
| verdict parse | multi-line output, verdict not first | check_line prints the verdict before its rows (:835-836); `head -c 3` reads the verdict |
| mid-run stop | need_root's exit or an errexit inside check_line | the run stops non-zero before `cat`; the Exit: text tells callers to read any exit but 0 as nothing decided (executed in fact-check mutants) |

## Untested bypass candidates

- A case collision on a real case-insensitive filesystem (F1's impact, and i1's general note). Not run: the sandbox has no case-insensitive mount I may write to.
- NTFS trailing-dot and alternate-stream names (from i1). pathform allows `a.` as a part. Not run, for the same reason.
- A directory at an instruction-file name or import target (row 608, deferred to U2c2). Not retested; the code is unchanged.

## Endorsement Claims

- **Claim:** A second self-merge brief in one --check does not inherit the first brief's Paths: entries.
  **Location:** `scripts/build-loop.sh:815-818`, `scripts/build-loop.sh:625-630`, lib `:386-390`
  **Evidence:** executed
  **Verified:** FSEC2b. x `Paths: src/` gave ok for `src/a`; y with no Paths: line refused `src/b` with NLIST. brief_fields empties BRIEF, and read_paths empties PATHS/PATHS_WHY before use.
  **Not verified:** a brief whose brief_fields fails after a prior brief's read set PATHS. Code read: the else arm sets `PATHS=()` and a refusing `co`.
  **route: code-fact-check**
- **Claim:** A never glob matches case-insensitively, `*`/`?` match within one part, and a glob also matches a directory above the path.
  **Location:** `scripts/build-loop.sh:636-646`, `:661-663`
  **Evidence:** executed
  **Verified:** FSEC4, and the test at build-loop-check.bats (T45).
  **Not verified:** globs with several adjacent `*` (`**`). That maps to `[^/]*[^/]*`, still within one part (not run).
  **route: code-fact-check**
- **Claim:** The Paths: allowlist compares entries exactly. A trailing `/` matches at a part boundary, and malformed lines (`//`, `.`, `..`, leading `/`, doubled spaces, bare `Paths:`) land only own files.
  **Location:** `scripts/build-loop.sh:363-377`, `:667-669`
  **Evidence:** executed
  **Verified:** FSEC3 and the tests at :1950 and :1967.
  **Not verified:** a Paths: line with a trailing CR on a CRLF brief. Static: brief_fields drops one CR before list_entries sees the line.
  **route: code-fact-check**
- **Claim:** The floor runs only when the checkout and the re-read passed (`co` empty), and a non-empty `co` always becomes the verdict line.
  **Location:** `scripts/build-loop.sh:661`, `:813-817`, `:835`
  **Evidence:** read-static (r1/r2 executed the re-read refusal)
  **Verified:** srules' first line tests `-z "$5"`, and check_line's verdict line prints `$co` first.
  **Not verified:** the timing of a checkout change between checkout_gate and the floor's walk (a TOCTOU in the human's own checkout, not loop-reachable).

## Primitive sweep

Primitive: regex built from repo text (bash `=~` with an unquoted pattern)
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/build-loop.sh:662` NEVER_RES match | S3 | globform charset, then never_res escaping | cleared: only `[^/]*`, `[^/]`, `\.` and literal NAMECHARS reach the regex |
| `scripts/build-loop.sh:367` list_entries shape | S2/S3 (the value tested, not the pattern) | constant pattern | cleared |

Primitive: shell glob match with repo text on the pattern side
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/build-loop.sh:668` `"$2" != "$e"*` | S2 | `$e` quoted (literal prefix); pathform entries | cleared |
| lib `:1810` `*"-$2.md"` | S4 stem (quoted) | anybrief's SLUG charset | F1: the unquoted `*` (NAME) matches any case |

No exec, fetch or deserialize primitive is added. Path construction appears only in `$GATE_TMP/line` (mktemp-owned).

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | NAME in an own review matches in any case, so `Code-Review-STEM.md` lands under `Paths: none` and can collide with an existing review on a case-insensitive clone | Medium | B1 | `scripts/lib/dev-cycle-read.sh:1810`, `scripts/build-loop.sh:665` | High (lands) / Medium (impact) |
| 2 | Deny text and row 613 say "only its own files land" after a failed re-read that refuses everything | Informational | B5 | `scripts/build-loop.sh:666`, `:817` | High |

## Overall Assessment

The S rules fail closed on every route I tried but one: the floor, the never globs, the Paths: parser, cross-brief state, the re-read refusal and mid-run stops. The exception is F1. The allowlist is meant to fold nothing, but an added review whose NAME part has upper-case letters passes it as an own file. On a case-insensitive clone, such a review can replace one of the brief's existing reviews, which the review-is-a-record rule forbids. The fix is one condition in srules (`[[ "$2" == "$3" ]]` before ownfile) plus one test row, and it makes the code match the three texts that already claim this. No architectural problem. F2 is wording only. No findings otherwise within the code paths read and the probes run; the endorsement claims are pending execution verification where marked.

## Goal-Alignment Note

The goal is to land U2c1 after a clean loop. The branch does what it set out to do (the S rules in --check, the parent-shell check_line under LC_ALL=C, the nrules prefix loop, the U2c split recorded), and self-merge is not switched on in this repo before U3. So F1 is not live today. It is still an incorrect claim, made in three places, about a security property, and the fix is small enough to make before the merge rather than route on. F2 and the stale contract item 8 and row 613 (fact-check) are text fixes that fit into the same commit.
