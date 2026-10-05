Commit: 4dc84ce4

# Architecture Review — feat/build-loop-u1c, final confirming pass (iteration 3)

**Scope:** `git diff main...feat/build-loop-u1c -- . ":!docs/reviews"` at 4dc84ce4. The focus is `scripts/build-loop.sh:297-352` (`shared_branches`, `status_line`) and how it uses `scripts/lib/dev-cycle-read.sh`.
**Date:** 2026-10-05
**Based on:** the Stage-1 merged code-fact-check (`docs/reviews/code-fact-check-report-build-loop-u1c.md`, Claim 20b Incorrect, Claim 22 Verified), the iteration-2 rubric (`docs/reviews/code-review-rubric-2026-10-05-feat-build-loop-u1c.md`: A14, A15, X1), and override rows 229 and 292.

Scope check: in scope. The diff adds a public mode (`--status`), a fourth `--settings` line, and line formats that U2-U4 parse (trigger categories 2 and 3).

Trust-boundary cross-reference: active. `docs/reviews/security-review-*.md` matches. The most recent by name is `docs/reviews/security-review-2026-10-02-digest-pass38.md` (Commit: `90364c73`). Its `B5` reads "[default-branch tree entry at a brief path] → [check_brief() ls-tree mode gate] → [brief Status read / slot decision]". F1 below sits on `B5`. The security review predates this diff, so the boundary may be stale. No recommendation here moves the crossing. Each one routes reads back through the gate that `B5` already names.

## Dependency Map

- `scripts/build-loop.sh` sources the lib and depends only in that direction. It uses `main_entry`, `brief_fields` (the global `BRIEF`), `check_brief`, `check_branch`, `isbrief`, `lower`, `FENCE_AWK` and `oddwhy`. The lib's only change is two comment lines.
- `status` mode: `read_settings` → `status_line` for each argument. At 4dc84ce4 `status_line` runs `shared_branches` first (`:318`). It then runs `check_brief` in a subshell, then `brief_fields "$a"` (`:323`), then `check_branch`, then `marker_kind`.
- `shared_branches` (`:301-315`) now has two read paths into main's tree. The first is new: `git grep -l` over `docs/working/briefs/` at `$MAIN_SHA`, recursive, whose output it parses as `SHA:path`. The second is the lib's (`isbrief` on a `closed/`-stripped name, then `brief_fields`, which calls `main_entry` and `cat-file`). Every other main read in the script goes through `main_entry` (`main_file`, `check_brief`, `brief_fields`).
- Downstream: U2's `--check` must also do the F31 skip (plan `:146`, "`--status`/`--check` skip both") and must read `BRIEF[paths]`/`BRIEF[policy]` for the gate.

## Prior findings: status at 4dc84ce4

- **A14 (lazy `shared_branches` overwrites `BRIEF` mid-judgement): resolved for `status_line`.** The guard now runs before the queried brief is read. An instrumented copy, run with `--status a a` on a repo with briefs `a` (`feat/a`) and `z` (`feat/z`), printed:
  ```
  PROBE after-guard: Branch: feat/z
  PROBE after-own: Branch: feat/a
  PROBE after-guard: Branch: feat/a
  ok docs/working/briefs/2026-10-01-a.md open review feat/a absent - - 0
  PROBE after-own: Branch: feat/a
  ```
  Every read of `BRIEF` in `status_line` sees the queried brief, which matches FC Claim 22. The first line shows the clobber still happens. It has moved to a point where nothing reads `BRIEF`. See F3 for what that leaves U2.
- **X1 (one batch read into a local map, before `status_line`'s own `brief_fields`): half done.** The performance half is done: `git grep` narrows the candidates, and FC Claim 28 measures ~0.1 s at 500 closed briefs. The coupling half was answered by reordering the calls, not by a local map. `shared_branches` still writes the global `BRIEF`.
- **A5 residue (a direct reader of `SHARED_BRANCHES` sees "nothing shared"): unchanged.** See F3.

## Findings

#### F1. `shared_branches` enumerates main's briefs through a second, unhardened read path: `git grep` and a parse of its output format

**Severity:** Coupling
**Location:** `scripts/build-loop.sh:304-309`
**Move:** 3 (module boundary: the lib owns "read a file from main's commit"), 7 (coupling to another tool's output format)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**
```
   304	  # One git grep finds the files with a "Status: open" line (a superset: fences
   305	  # are not modelled); brief_fields then reads only those.
   306	  list="$(git grep -l -E '^Status: open'$'\r''?$' "$MAIN_SHA" -- docs/working/briefs/ || true)"
   307	  while IFS= read -r f; do
   308	    f="${f#"$MAIN_SHA":}"
   309	    if ! isbrief "${f/closed\//}" || ! brief_fields "$f"; then continue; fi
   (excerpt ends :309; enclosing shared_branches() continues to :315 — read: it counts names and builds SHARED_BRANCHES)
```
lib `:258-263` (`main_entry`), the read path every other main read takes:
```
main_entry() {
  ...
  main_by_name || { echo error; return; }
  ...
  out="$(git ls-tree -t --full-tree "$MAIN_SHA" -- "${want[@]}" "$1" 2>/dev/null)" || { echo error; return; }
```

Before 4dc84ce4, the script read main's tree only through the lib. `main_entry` turns a failed `ls-tree` into `error`, refuses duplicate names, and refuses symlinks, gitlinks and non-directories above a path. `brief_fields` is the single parser of a brief's lines. F31 now also depends on three things outside the lib. First, a second definition of "open" (the grep regex), which must stay a superset of `brief_fields`' "first `Status:` line outside a fence, CR dropped". Second, `git grep`'s `<tree-ish>:<path>` output form, which the `${f#"$MAIN_SHA":}` strip assumes. Third, `git grep` being clean under the caller's config. FC Claim 20b shows the third assumption fails. I reproduced it: with `color.ui always` in the repo config, two open briefs naming `feat/a` print `ok` instead of `skip`, and the `|| true` makes a git failure look the same as "no open briefs". Because enumeration happens before the lib's checks, anything the enumeration drops never reaches the lib. Each of these drifts makes F31 fail open, and the lib cannot catch them. Changing the lib's brief parser, such as a new CR or fence rule, now also needs a matching edit to a regex in another file, or F31 silently stops counting some briefs. This sits on `B5` from `docs/reviews/security-review-2026-10-02-digest-pass38.md` (Commit: `90364c73`; that security review predates this diff, so the boundary may be stale). Its "ls-tree mode gate" is no longer the only way into main's brief entries. Security-reviewer owns the exploitability of the colour case. This finding is about where the read lives.

**Recommendation:** Put the enumeration in the lib, next to `main_entry`. One option is a `main_brief_candidates` that runs `git -c color.grep=false grep --no-color -l --full-name …`, treats an exit other than 0 or 1 as an error (fail closed: the caller skips every open brief), and returns paths only. Another is `git ls-tree --name-only` of `briefs/` and `briefs/closed/` (non-recursive, as before), with the grep kept only as a filter. Either way the client stops parsing git's output format, and the superset rule sits beside `brief_fields`, the parser it must match. Add one comment there saying the regex must stay a superset of `brief_fields`' Status rule.

#### F2. Row 292's premise changed: the recursive `git grep` makes the `closed/` substitution disagree with `check_brief`

**Severity:** Minor
**Location:** `scripts/build-loop.sh:306`, `:309`; lib `:157`, `:326`
**Move:** 3 (one rule, several spellings that are no longer equivalent)
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis (row 292 is Defer to U2; this says its premise moved)

**Evidence:**
```
   306	  list="$(git grep -l -E '^Status: open'$'\r''?$' "$MAIN_SHA" -- docs/working/briefs/ || true)"
   309	    if ! isbrief "${f/closed\//}" || ! brief_fields "$f"; then continue; fi
lib:326  if ! isbrief "$a" && [[ ! "$a" =~ ^docs/working/briefs/closed/$DIGIT{4}-$DIGIT{2}-$DIGIT{2}-$SLUG\.md$ ]]; then
```
Row 292 deferred "the closed/ path rule is spelled three ways" as a duplication of one rule. The `${f/closed\//}` spelling matched check_brief's regex only because c143b929's `ls-tree` listed direct children of `briefs/` and `briefs/closed/`. I noted that dependency in iteration 2's F2. `git grep` over the `docs/working/briefs/` pathspec recurses, so that condition no longer holds. Stripping the first `closed/` from `docs/working/briefs/2026-10-0closed/1-x.md` yields a valid brief name. Probe P1 (scratch repo `p1`): brief `a` names `feat/a`, and a file at `docs/working/briefs/2026-10-0closed/1-x.md` holds `Status: open` / `Branch: feat/a`:
```
4dc84ce4:  skip docs/working/briefs/2026-10-01-a.md: another open brief on the default branch names the same branch (compared ignoring case)
           skip docs/working/briefs/2026-10-0closed/1-x.md: not a build brief (docs/working/briefs/[closed/]YYYY-MM-DD-<slug>.md)
c143b929:  ok docs/working/briefs/2026-10-01-a.md open review feat/a absent - - 0
```
`check_brief` says the file is not a brief, but F31 counts it. The error fails closed (an extra skip), and the path is contrived, so the impact is low. It is still the drift row 292 predicted: the spellings now encode different rules, and that came from changing the enumerator, not the predicate.

**Recommendation:** Same as iteration 2's F2. Add one lib predicate for "a brief path, optionally under `closed/`" with the regex `^docs/working/briefs/(closed/)?DATE-SLUG\.md$`, and use it at lib `:161`, lib `:326` and build-loop `:309`. The orchestrator should update row 292's rationale to say the spellings now differ in behaviour, or bring the predicate forward from U2 into U1d.

#### F3. The `BRIEF` clobber is resolved by call order, a convention U2's `--check` must copy; `SHARED_BRANCHES` stays a fail-open global

**Severity:** Minor
**Location:** `scripts/build-loop.sh:297-303`, `:318`, `:333`
**Move:** 7 (temporal coupling through shared global state)
**Confidence:** High
**Legibility-target:** for-author (U2's `--check`); for-orchestrator-synthesis (whether A14 closes)

**Evidence:**
```
   297	# Lower-cased branch names that more than one open brief on main (in briefs/ or
   298	# closed/) names, each between newlines: such briefs are skipped (F31).
   299	# status_line computes it on first use, so no caller can skip it.
   300	SHARED_BRANCHES=""
   301	shared_branches() {
   302	  local f list b
   303	  local -A n=()
   318	  [[ -n "$SHARED_BRANCHES" ]] || shared_branches  # first: it reads other briefs into BRIEF
   333	  if [[ "$st" == open && "$SHARED_BRANCHES" == *$'\n'"$(lower "$br")"$'\n'* ]]; then
```
The question for this pass was whether the coupling is gone or only moved. It moved. `status_line` is correct, as P2 shows. But `shared_branches` still overwrites the global `BRIEF` ("after-guard: Branch: feat/z"), and only the comment at `:318` keeps a caller from reading `BRIEF` after it. U2's `--check` is planned to do F31 and then read `BRIEF[paths]`. It is safe if it calls `status_line`, or if it copies `:318` as its first line. It is wrong on the first brief of a run if it puts the guard after its own `brief_fields`, and nothing would fail loudly. A test catches that only when the first argument and the last open brief on main differ in the field read. The `:299` comment ("no caller can skip it") holds only for callers that go through `status_line`. A direct `[[ $SHARED_BRANCHES == *…* ]]` before any computation still reads "nothing shared". Row 229 (BRIEF global, Won't-Fix) covers the convention of a global `BRIEF`. It does not cover a helper that writes `BRIEF` for a brief its caller is not judging. The iteration-2 rubric made that distinction, and it still applies.

The fix is one line. I checked it with a probe copy: adding `BRIEF=()` to `shared_branches`' `local -A` line (`local -A n=() BRIEF=()`) shadows the global. Bash's dynamic scoping makes `brief_fields`' writes land in the local. After the guard the global read `unset`, and F31 still skipped both briefs naming `feat/a` (scratch repo `p3`). The ordering rule then disappears.

**Recommendation:** Add `BRIEF=()` to the `local -A` declaration in `shared_branches`, with a comment ("shadows the lib's global: brief_fields writes here"). The call order then stops mattering, which finishes X1's coupling half. Separately, either expose `branch_shared NAME` (computes on first use) instead of the raw variable, or reword `:299` to "callers ask through status_line". If U1c is not changed again, record "U2's `--check` runs the F31 computation before its own `brief_fields`" as a U2 precondition in the plan or the override log.

## What Looks Good

- Moving the guard to the top of `status_line` gives the right answer on every path. `check_brief` runs in a subshell, so the only `BRIEF` writer after the guard is `brief_fields "$a"` itself (P2; FC Claim 22). `route: code-fact-check`
- The candidates from `git grep` are still re-read through `brief_fields`, so `main_entry`'s mode and directory gate still decides what a brief is. The grep only prefilters. F1 is about what the prefilter can drop, not what it can admit.
- Dependencies still point one way, script to lib. `main_file` remains the single "file on main through `FENCE_AWK` plus a program" shape for both settings files.
- The F31 set is computed once per run whatever the argument order, and the output contracts (`ok …`/`skip …: WHY`) are unchanged for U4's parser.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | `shared_branches` enumerates main's briefs through `git grep` and an output-format parse, outside the lib's `main_entry` path. A second "open" rule; fails open under colour or a git error (FC 20b); sits on `B5` | Coupling | `scripts/build-loop.sh:304-309` | High |
| 2 | Row 292's premise changed: recursive grep plus `${f/closed\//}` counts a path `check_brief` calls "not a build brief" (P1, fails closed) | Minor | `scripts/build-loop.sh:306,309`; lib `:326` | High |
| 3 | A14 fixed by call order only. `shared_branches` still clobbers `BRIEF`; U2's `--check` must copy `:318`; `SHARED_BRANCHES` still a fail-open global. One-line fix: `local -A … BRIEF=()` | Minor | `scripts/build-loop.sh:297-303,318,333` | High |

## Overall Assessment

4dc84ce4 fixes A14's observable problem: `status_line` always judges the brief it was asked about. It also fixes A15's cost. The coupling has moved rather than gone. F31's correctness now depends on a call order written down only in a comment (F3), and on a second read path into main that the lib does not own (F1). The second is the structural concern that matters most. Until now, every read of main's tree in this script went through `main_entry`'s hardened gate (`B5`), and the brief format had one parser. The new `git grep` prefilter adds a second definition of "open brief", a parse of git's output format, and sensitivity to the caller's config, and each of these can make F31 fail open with no message. FC 20b shows one way it already does. All three findings can be fixed in place with small changes: move or harden the enumeration in the lib, add one brief-path predicate, and shadow `BRIEF` in `shared_branches`. None of them needs restructuring. If U1c merges as it is, F3's precondition should be recorded for U2, and row 292's rationale updated.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved at the output path your task names, structured per your skill, with a `Commit: 4dc84ce4` first line.
- Answered: yes. A14 is resolved for `status_line` by call order, but the order dependence remains for U2 (F3, with a probe-verified one-line fix). `git grep` is a second read path outside the lib (F1). Row 292's premise changed (F2, probe P1). Row 229 still covers the global-BRIEF convention, not the helper clobber.
- Out of scope: the exploitability and tiering of the colour/exit-128 fail-open (security-reviewer; FC 20b escalation); the bracketed-prefix constraint residue (row 290 / orchestrator); performance of the new path (FC Claim 28).
- Escalate: FC 20b and F1 share a root, the read path outside the lib. Fixing the colour bug in place without moving the enumeration leaves F1. Ask the orchestrator to update row 292's rationale, and to record F3's U2 precondition if U1c is not amended.
- Decisions I made: F2 is Minor, not Coupling, because it fails closed and needs a contrived path. I treated row 229 as still settled for the global convention and did not re-file it.
