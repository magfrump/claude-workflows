Commit: cf7dd447

# Security Review: feat/build-loop-u2c1, iteration 2 (fix range)

**Scope:** `git diff eddfd5f9..HEAD -- scripts test` (d435100e, cf7dd447): scripts/build-loop.sh (list_entries, read_settings' never branch, read_paths, srules, check_line's re-read, --help and Exit: text), test/scripts/build-loop-check.bats, and plan :238, :311, :312
**Date:** 2026-10-10
**Based on:** docs/reviews/code-fact-check-report-build-loop-u2c1-i2.md (20 claims: 17 verified, 3 mostly accurate) and my iteration-1 report docs/reviews/security-review-2026-10-10-u2c1.md
**Threat model (unchanged from i1):** a build loop, honest or hostile, writes its own branch. `--check` under self-merge decides what lands from main's commit with no human review.

Probe log: `/tmp/claude-1000/-workspace/54247aa5-2a95-449b-b931-3ed456da322c/scratchpad/u2c1-i2-security/` holds `probe.sh`, `probe.bats.part` and `run-probe.txt`. The script starts `set -eu` and makes its own `mktemp -d /tmp/u2c1-security-XXXX`. It extracts `git archive cf7dd447 scripts test` into that directory and forces check_line's re-read to fail (`if brief_fields "$a"` becomes `if false`, the same edit as the fact-check's FCPROBE 2). It appends one SECPROBE test and runs it with `LC_ALL=C TMPDIR=<own> bats -f SECPROBE`, serially. Then it removes the directory. No git write command ran in /workspace or in the worktree.

## Trust Boundary Map

```
B2: [changed path, N rules passed]   → [srules: floor → never globs → ownfile(as spelled) / Paths:] → [path lands unreviewed] (moved: ownfile now gets $2)
B3: [main's brief (cycle-written)]   → [brief_fields re-read, read_paths → list_entries]           → [PATHS allowlist] (moved: new parser; failed re-read now lands own files)
B4: [main's docs/dev-cycle.md]       → [read_settings → list_entries, globform]                    → [NEVER, then NEVER_RES] (moved: shared parser)
B6: [check_line exit/status]         → [parent-shell loop, Exit: text]                             → [--check exit code to caller] (text only)
```

```
S1: branch tree paths            — request-time (loop-written) — UNTRUSTED for every sink
S2: brief Paths: line on main    — written by the cycle; N rules deny briefs/ to the loop — trusted as allowlist content; parsed, not executed
S3: Self-merge never: line       — written by the cycle; N rules deny docs/dev-cycle.md — trusted, but feeds a regex and now a deny message, so charset checked
S4: brief path argument → stem   — caller-supplied, checked by check_brief — trusted after that check
```

The fix range adds no new boundary. It moves three things. B3 and B4 now share one parser. On B2, ownfile gets the path as spelled. On B3, a failed re-read lands own files where it used to refuse the brief.

## Findings

#### F1: A failed re-read of the brief now gives an `ok` verdict when every changed path is an own file, and the output does not show that the re-read failed

**Severity:** Informational
**Location:** `scripts/build-loop.sh:808-809`
**Boundary:** B3
**Move:** 3 (error path)
**Confidence:** High (executed)
**Legibility-target:** for-author

Evidence (the new code):

```bash
  # A failed read lands only own files, with every path line still printed.
  if [[ "$pol" == self-merge ]]; then if brief_fields "$a"; then read_paths; else PATHS=(); PATHS_WHY="could not be read again"; fi; fi
```

eddfd5f9 had `brief_fields "$a" || { echo "refuse $a: the brief could not be read again"; return 0; }`, which refused the whole brief. Probe SECPROBE i2-1 forces the failure and changes only own files (`docs/working/plan-2026-10-01-x.md`, `docs/reviews/2026-10-01-x.md`). It printed `status 0`, `ok docs/working/briefs/2026-10-01-x.md d779e04… 8dd8aea…`, and two `path` lines. The reason "could not be read again" shows only on deny lines for paths that are not own files, so in this case nothing in the output says the read failed.

This is not a bypass. Own files are chosen by the stem (from `$a`), not by the brief's text. They still go through the floor and the never globs first. The same paths would land under any well-formed Paths: line. A loop also cannot cause the failure: the re-read uses the same MAIN_SHA that status_line read without error, so only a transient git or awk failure can trigger it. Row 613 records this as an intended change. The cost is legibility: the run goes from "refused, visible" to "landed, with the error hidden".

**Recommendation:** None needed for security. If U3 logs gate decisions, consider printing the reason once per brief (for example, on the verdict line) instead of only on deny lines. Row 612 already tracks the related "malformed Paths: shows only per deny line" item, so this can be folded into its trigger.

#### F2: check_line's new comment "set -e applies" is wider than what bash does, and the floor's fail-closed behaviour rests on its explicit guards, not on errexit

**Severity:** Informational
**Location:** `scripts/build-loop.sh:759-760`; `scripts/build-loop.sh:659`; `scripts/lib/dev-cycle-read.sh:1826-1849`
**Boundary:** B2, B6
**Move:** 3 (error path)
**Confidence:** High (fact-check Claim 14a, executed)
**Legibility-target:** for-author

Evidence: the comment reads `It runs in the caller's shell (set -e applies; an exit ends the run)`. floor is called as `if [[ -z "$5" ]] && floor "$2" "$1" "$4"; then`. Bash turns errexit off inside any function called from an `if`/`&&` condition. That covers the whole floor and its import walk, and also brief_fields, checkout_gate and nul_list. The fact-check's `ee.sh` probe shows a `false` skipped in that context. Today floor fails closed through explicit guards: `lp="$(lower "$1")" || { FLOOR_WHY=…; return 0; }`, need_root's own `exit 1`, and truthwalk's `walk` reason. In floor, any command whose failure is not guarded and that falls through to `else return 1` would let the path pass the floor. The comment invites a future author to rely on set -e inside floor, which would fail open. I found no such unguarded command in floor's body (read in full, :1826-1849). truthrule and truthwalk are called in conditions, as they were in eddfd5f9.

**Recommendation:** Take the fact-check's wording: "set -e applies to its own lines and to nrules/srules, not inside floor's walk or the helpers it tests in conditions". Or add "floor must fail closed by its own guards" to floor's comment.

## Fix-range checks (the dispatch's questions)

| Question | Result | Evidence |
|---|---|---|
| Does list_entries change the never line's parse? | No outcome changes. The form reason comes first. The next-line reason overrides the others (as the old elif order did). `none` gives an empty list. Entries pass globform before `seen[...]` is touched. | Fact-check Claim 10: 44-case differential, 0 differences. build-loop-read.bats 20/20 (fact-check run). Static: `if [[ "$why" != "is not exactly"* && "${next[never]}" != 1 ]]` (`:418`) |
| Does `${1#"$2": }` or `"$2: "*` treat the KEY as a pattern? | No. KEY is quoted in both, and the two callers pass the constants "Self-merge never" and "Paths" | `:363`, `:367`, `:416`, `:628` |
| Does FORM by name open anything? | No. `"$4"` is a constant at both call sites (globform, pathform). It runs in an `if` condition, so a refusal sets LIST_WHY and never trips errexit | `:372`; fact-check Claim 9 |
| Does read_paths widen Paths:? | It narrows. `Paths: none` used to be the one entry `none` and is now empty. Bare `Paths:` is now malformed (only own files, as before). `Paths: none/` is a directory entry at a root-level `none/`, which a cycle has to write | `:625-629`; fact-check Claim 19 |
| Can LIST leak between the two callers? | No. Each caller copies LIST right after its own call: NEVER at `:421`, PATHS at `:629`. read_settings runs once, before never_res, so NEVER_RES stays aligned with NEVER | `:841`; grep shows no other LIST user in build-loop.sh or the lib |
| ownfile as spelled (B1): does it open a path? | It closes one. An unlisted case-variant own file or review is now denied. The floor still lower-cases before its own ownfile call. So a case-variant own path lands only when the cycle's Paths: lists it exactly, which a loop cannot arrange | `:663`; lib `:1830`, `:1842-1843`; fact-check Claims 5, 12; mutation run fails with B1 reverted |
| Glob-named deny (B8): can a never glob inject into the deny line? | No. globform allows only `*?` and NAMECHARS: no space, colon or newline, and no leading `/` or `-`. NEVER_RES has one entry per NEVER entry, in order | `:380-382`; `:636-646`; fact-check Claim 13 |
| Exit: text (B6/B7) | It fails closed. A failed command exits with its own status (128 or 2), never 0. The text's "a caller reads any exit but 0 as nothing decided" keeps U3 safe. Fact-check Claim 7 notes the "1" is approximate | `:198-203`, `:849`, `:853` |

## Iteration-1 findings: dispositions confirmed

| i1 # | Finding | Disposition | Confirmed |
|---|---|---|---|
| F1 | Directory at an instruction name or import target lands | Deferred to U2c2 (override row 608; plan :312 names it "U2c1 i1 security 1") | Yes, the row and the plan route exist. The code is unchanged, as a deferral expects |
| F2 | Own files matched lower-cased | Fixed (B1): `ownfile "$2"` | Yes, for every route a loop can reach. Fact-check Claim 5 found a remaining help-text imprecision: the floor arm still folds case. That needs a cycle-written Paths: entry, so it is not a loop-reachable bypass |
| F3 | plan:238 stale | Fixed: plan:238 now reads "lands only the brief's own files" | Yes (fact-check Claim 2) |
| F4 | NAME-STEM review collision | Won't-Fix (row 609) | Yes. The precondition still cannot be reached (the cycle names briefs) |
| F5 | need_root exit drops the line; U3 must treat non-zero as nothing decided | Fixed in text (Exit: line, B6) | Yes. The text says so. The exit-status detail is fact-check Claim 7's Mostly accurate |

## Bypass candidates tested (move 11, fix range)

| Guard | Candidate | Outcome |
|---|---|---|
| ownfile (as spelled) | `Docs/Working/Plan-STEM.md`, unlisted | refused (test :1975, run in the fact-check) |
| ownfile (as spelled) | `Docs/Working/Plan-STEM.md` listed exactly in Paths: | lands (fact-check FCPROBE 1). Needs a cycle-written entry |
| Paths: parser | `Paths: none` / `Paths:` / `Paths: none none` / `Paths: none/` | empty / malformed / duplicate / directory `none/`, all static, the first two executed (test :1967) |
| never parser | tab inside an entry, `none` plus another entry, trailing `/` | same as eddfd5f9 (fact-check differential) |
| re-read failure | only own files changed | `ok` verdict, status 0 (SECPROBE i2-1): F1 |
| deny text | glob characters in the message | globform's charset; nothing a line parser splits on |

## Untested bypass candidates

None in the fix range. The i1 list (NTFS trailing dot; case collision on a human's case-insensitive clone) is unchanged and still stands.

## Endorsement Claims

- **Claim:** list_entries gives read_settings' never line the same reason and outcome as eddfd5f9 for the probed input classes.
  **Location:** `scripts/build-loop.sh:362-377`, `:413-421`
  **Evidence:** executed (fact-check diffprobe, 44 cases; build-loop-read.bats 20/20)
  **Verified:** the reason strings and their precedence, `none`, duplicates, trailing `/`, tabs.
  **Not verified:** never lines read under a non-C locale with non-ASCII bytes. read_settings runs outside check_line's `LC_ALL=C`, as it did in eddfd5f9.
  **route: code-fact-check**
- **Claim:** In srules' allowlist arm, an own file lands only when the diff spells it in lower case.
  **Location:** `scripts/build-loop.sh:663`
  **Evidence:** executed (fact-check mutation run and test :1975)
  **Verified:** `ownfile "$2"`, with ownfile folding nothing (lib :1805-1810).
  **Not verified:** a case-variant own review (only a working doc is tested).
  **route: code-fact-check**

## Primitive sweep

Primitive: regex built from repo text (`[[ =~ ]]`)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/build-loop.sh:661` (`"$3" =~ ${NEVER_RES[$i]}`) | S3 | globform charset; `.` escaped in never_res | cleared. Only the loop's index form changed |
| `scripts/build-loop.sh:367` (`"$v" =~ ^[^\ ]+(\ [^\ ]+)*$`) | S2, S3 | constant regex | cleared |

Primitive: glob or prefix comparison

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/build-loop.sh:367` (`"$1" != "$2: "*`) | code constant KEY | quoted | cleared |
| `scripts/build-loop.sh:666` (`"$2" != "$e"*`) | S2 vs S1 | `"$e"` quoted; pathform refuses `*?` | cleared (unchanged) |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Failed re-read: `ok` verdict for own-only changes, with the failure not shown | Informational | B3 | `scripts/build-loop.sh:809` | High |
| 2 | "set -e applies" is wider than bash's behaviour; floor depends on its explicit guards | Informational | B2, B6 | `scripts/build-loop.sh:759-760` | High |

## Overall Assessment

The fix range opens no path that should be refused. B1 closes the i1 case-variant route for every spelling a loop can choose. list_entries keeps the never line's parse: same reasons, same precedence, same NEVER (44-case differential plus the read suite). Its Paths: changes only narrow the allowlist (`none` now means empty, and bare `Paths:` is malformed). The glob-named deny message takes its text only from globform's charset. The one behavioural loosening is the failed re-read. It now lands own files and can give an `ok` verdict that says nothing about the failure. A loop cannot reach that state, and it lands nothing the brief's stem does not already allow. The other finding is a comment that could mislead a future floor change. Neither blocks the merge. All five i1 findings have the disposition the rubric records. I found no findings within the code paths read, and the endorsement claims are pending execution verification beyond the fact-check runs cited.

## Goal-Alignment Note

- Success criterion (restated verbatim): a markdown report saved at the output path your dispatch names, structured per your skill, every finding with verbatim Evidence and a path:line.
- Answered: yes. Two Informational findings, each with verbatim code and a path:line. The dispatch's questions get one row each. All five i1 dispositions are confirmed. One probe ran in a throwaway archive copy.
- Out of scope: code outside the fix range (eddfd5f9's own code, the lib's reader_settings copy, row 616); full suites (I relied on the fact-check's runs: build-loop-check 138/138, build-loop-read 20/20).
- Escalate: none. F1 is a legibility choice that row 613 already made deliberately.
