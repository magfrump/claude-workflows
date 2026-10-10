Commit: eddfd5f9

# Security Review: feat/build-loop-u2c1 (U2c1, the S rules in --check)

**Scope:** `git diff main...HEAD` (eddfd5f9): scripts/build-loop.sh, scripts/lib/dev-cycle-read.sh, test/scripts/build-loop-check.bats, docs/working/plan-build-loop-handoff.md
**Date:** 2026-10-10
**Based on:** docs/reviews/code-fact-check-report-build-loop-u2c1.md (21 claims; Claim 1 stale, Claim 2a mostly accurate)
**Threat model (from dispatch):** a build loop, honest but fallible or turned hostile, writes its own branch. The gate (`--check` under self-merge) decides what lands from main's commit and the merge result, with no human review.

Probe log: `/tmp/claude-1000/-workspace/54247aa5-2a95-449b-b931-3ed456da322c/scratchpad/u2c1-i1-security/` holds `probe.sh`, `probe-tests.bats.part` and `run-probes.txt`. The script ran `git archive eddfd5f9 scripts test` into a fresh `mktemp -d /tmp/u2c1-security-XXXX` (removed afterwards). It appended two SECPROBE tests and ran `LC_ALL=C TMPDIR=<own> bats -f SECPROBE` serially. Each probe ends `show; return 1` so its output prints. Both printed `status 0` with an `ok` verdict.

## Trust Boundary Map

```
B1: [loop branch tip (hostile-capable)] → [merge_result + diff-tree -r --no-renames, N rules] → [changed-path list judged per path]
B2: [changed path, N rules passed]      → [srules: floor → never globs → ownfile / Paths:]  → [path lands on main unreviewed] (new)
B3: [main's brief (cycle-written)]      → [brief_fields from MAIN_SHA, paths_read]            → [PATHS allowlist] (new)
B4: [main's docs/dev-cycle.md]          → [read_settings, globform, never_res]                → [NEVER_RES regexes] (new)
B5: [main checkout on disk]             → [checkout_gate, then floor's import walk]           → [floor verdict] (moved: now in parent shell under LC_ALL=C)
B6: [check_line exit/status]            → [parent-shell loop, head -c 3 "ok "]                → [--check exit code to caller] (moved)
```

```
S1: branch tree paths, modes, blobs  — request-time (loop-written) — UNTRUSTED for every sink (path match, landing)
S2: brief Paths: line on main        — deploy-time-ish (the cycle writes it; N rules stop a loop editing briefs/) — trusted as the allowlist; the loop cannot change it
S3: Self-merge never: line on main   — deploy-time (N rules deny docs/dev-cycle.md) — trusted for the regex sink, though the regex is built from it, so escaping is checked (move 2)
S4: brief path argument ($a) → stem  — caller-supplied, checked by check_brief (pathform + anybrief) — trusted after that check
S5: checkout working tree            — runtime-mutable (the same uid as the loop) — UNTRUSTED. The walk reads main's commit first and the checkout only to add imports or fail
S6: locale environment (LC_ALL)      — caller env — now overridden to C inside check_line
```

S1 is the only hostile input. The diff adds B2: from here, a path that the N rules pass can land with no review if the floor, the never globs and the allowlist all let it through. Every finding below is a path that passes all three where the plan's intent says it should be refused, or a gap between the docs and the code about what lands.

## Findings

#### F1: An instruction-file name or an @-import target can be used as a directory under a listed directory, and that lands

**Severity:** Low
**Location:** `scripts/build-loop.sh:601-604` (nrules prefix loop), `scripts/lib/dev-cycle-read.sh:1826-1850` (floor), `scripts/lib/dev-cycle-read.sh:663` (isstart)
**Boundary:** B2
**Move:** 11 (bypass enumeration, prefix boundary)
**Confidence:** High (executed)
**Legibility-target:** for-author

U2c1 makes nrules refuse a path below a cycle file's name (row 523: such a directory keeps the cycle from writing the file). It does this only for truthrule's `cycle|settings|user` words:

```bash
[[ ! "$TRUTH_WHY" =~ ^(cycle|settings|user)$ ]] || DENY="a path below the name of one of the dev cycle's own files or the constraints doc"
```

floor tests only the whole path. isstart reads the basename (`[[ "${1##*/}" =~ $INSTRUCTION_FILE ]]`), and truthwalk asks whether the exact path is imported. So nothing catches a directory that sits at an instruction file's name or at an import target main lacks. Probe SECPROBE 1 used main `CLAUDE.md` = `see @docs/imp.md`, with no docs/imp.md on main, and `Paths: docs/ src/`. It returned `status 0`:

```
path docs/working/briefs/2026-10-01-x.md A docs/imp.md/n.txt
path docs/working/briefs/2026-10-01-x.md A src/CLAUDE.md/n.txt
path docs/working/briefs/2026-10-01-x.md A src/skills/q/SKILL.md/n.txt
```

The effect is the one row 523 names, applied to floor item 1's files: once this lands, nobody can create the instruction file or the import target at that path until a human removes the directory. I rate it Low rather than Medium for two reasons. Integrity holds: as far as I know, Claude Code loads neither a directory named CLAUDE.md nor an @-import that resolves to a directory, so no text becomes instructions. That last point is unverified. And the harm is availability that a human will see, unlike row 523's case, where the cycle's own write breaks.

**Recommendation:** Decide whether row 523's reasoning covers floor item 1. If it does, add `instr` to the prefix loop's words (or test `isstart "$d"`). Also check whether a lower-cased prefix is in IMPORTED_MAIN, in floor or srules, so this is not left as an N-rule special case. If it does not, record the asymmetry in the nrules comment and the help text ("a path below one of those names" names only the cycle and constraints files).

#### F2: An own file or own review with a case-variant name lands, though the plan says the allowlist widens nothing by case

**Severity:** Low
**Location:** `scripts/build-loop.sh:658`, `scripts/lib/dev-cycle-read.sh:1805-1810`, `docs/working/plan-build-loop-handoff.md:311`, `scripts/build-loop.sh:183-189`
**Boundary:** B2
**Move:** 5 (invert the allowlist), 11
**Confidence:** High (executed; fact-check FCPROBE 1 and SECPROBE 2)
**Legibility-target:** for-author

srules passes the lower-cased spelling to ownfile: `! ownfile "$3" "$1" "$4" || return 0`, where `$3` is `${lps[$i]}`. Probe SECPROBE 2 (`Paths: docs/a`) printed `path docs/working/briefs/2026-10-01-x.md A Docs/Reviews/Code-Review-2026-10-01-X.md` with `status 0`. The fact-check's FCPROBE 1 printed the same for `Docs/Working/Plan-2026-10-01-x.md`. So "Paths: … compared exactly" holds, but the allowlist's other half does not compare exactly. The help text and plan:311 ("an allowlist widens nothing by case") read as if the whole allowlist compares exactly.

I found no path to a floor bypass. floor lower-cases everything (`lp="$(lower "$1")"`), so the case variant passes the floor only because the lower-cased name is the brief's own file. Two side effects remain. First, it adds a second-spelling tree (`Docs/`) on main. On a case-insensitive clone (not the gate's: checkout_gate refuses core.ignoreCase) that tree collides only with the brief's own file. Second, a review saved under a case-variant name sits where a later reader of `docs/reviews/` does not look, which can hide it from readers. It cannot overwrite anything, because only an added review counts as the brief's own.

**Recommendation:** Pass `$2` (the spelling as stored) to ownfile in srules, so own files match exactly like Paths: entries (floor's own lower-cased ownfile call is a narrower, separate question). Or keep the code and change plan:311 and the help text to say "own files compare lower-cased". Either is fine for security. The mismatch is what should go.

#### F3: plan:238 still says a malformed Paths: line means no self-merge; the code lands own files

**Severity:** Informational
**Location:** `docs/working/plan-build-loop-handoff.md:238`; code `scripts/build-loop.sh:658-659`
**Boundary:** B3
**Move:** 3 (error path)
**Confidence:** High (fact-check Claim 1, executed)
**Legibility-target:** for-author

Evidence: plan:238 reads "`Paths: P…` (a malformed or duplicate entry means no self-merge);". The code is

```bash
  ! ownfile "$3" "$1" "$4" || return 0
  [[ -z "$PATHS_WHY" ]] || { DENY="the brief's Paths: line $PATHS_WHY, so only its own files land"; return 0; }
```

The failure mode does fail closed for everything that is not an own file, and own files still pass floor and the never globs first. The risk is small: a reader of the spec (U3's author, a human auditing) would expect a malformed line to block the merge entirely. plan:311 has the new rule, so the plan contradicts itself.

**Recommendation:** Change plan:238 to match plan:311 ("…lands only the brief's own files").

#### F4: A review named NAME-STEM.md can take another brief's review name when that brief's slug ends in this brief's full stem

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:1809`
**Boundary:** B2
**Move:** 11 (own-file collision)
**Confidence:** High for the mechanism (executed), Low for the precondition ever occurring
**Legibility-target:** for-orchestrator-synthesis

`( "$b" == "$2.md" || "$b" == *"-$2.md" )` matches when NAME is itself another full stem. In SECPROBE 2, brief `2026-10-01-x` landed `path … A docs/reviews/2026-10-02-y-2026-10-01-x.md`. That name is brief `2026-10-02-y-2026-10-01-x`'s own `STEM.md` review. SLUG (`[a-z0-9-]+`) allows that slug. A hostile loop could get in first with a forged review for that sibling. The loop does not choose brief names, though: the cycle writes briefs, and the N rules deny briefs/. So the precondition is not one an attacker can reach. The mechanism lives in lib ownfile and predates this diff, but U2c1 is the first change that lets it land unreviewed.

**Recommendation:** None needed now. If the cycle's brief-naming rule ever allows a slug that starts with a date, refuse `NAME` values that themselves match `$DIGIT{4}-$DIGIT{2}-$DIGIT{2}-`.

#### F5: Under the parent-shell change, need_root's exit 1 ends --check with exit 1 rather than 2, and drops that brief's line; U3 must treat any non-zero as "nothing decided"

**Severity:** Informational
**Location:** `scripts/build-loop.sh:836-843`, `scripts/lib/dev-cycle-read.sh:160-164`
**Boundary:** B6
**Move:** 3 (error path)
**Confidence:** High (fact-check Claim 12 executed analog; static here)
**Legibility-target:** for-orchestrator-synthesis

`check_line "$a" > "$GATE_TMP/line"; cat "$GATE_TMP/line"` runs under `set -euo pipefail` (`:202`). Any exit inside, need_root's included, ends the script before `cat`, and the EXIT trap removes `$GATE_TMP/line`. Lines for earlier briefs have already printed and are true verdicts. The failing brief and every brief after it get no line, and the exit status is need_root's 1, not the documented refusal status 2. This fails closed, provided U3's caller treats every status other than 0 as "do not merge anything not already confirmed" and does not take a missing line as no objection. errexit is now live inside check_line, and that can only add exits. I found no `||`/`if` context that makes a refusal disappear: srules runs as the right side of `||`, so errexit is off inside it, but no part of srules depends on errexit.

**Recommendation:** Add a line to --help or the U3 hand-off: "exit 1: --check stopped (a contract failure); no line for that brief or later ones."

## Untested bypass candidates

- **Windows trailing dot or space (`docs/constraints.md.`):** pathform allows a trailing `.` in a part, and neither truthrule's `writable` regex nor floor matches it. On NTFS, `constraints.md.` is `constraints.md`. Not tested, because git's `core.protectNTFS` (on by default) refuses to check out such paths on Windows, and the gate's own checkout is Linux. Listed rather than cleared: the claim depends on clients' git defaults.
- **Case collision on a case-insensitive human clone:** a path inside a Paths: directory as spelled (`docs/notes/a.md`) could shadow a main file outside Paths: (`Docs/Notes/a.md`) on macOS. Main must already hold a directory that differs from a Paths: entry only by case, and the loop cannot create one (Paths: compares exactly; F2's own-file variants stay at the brief's own names). Not built as a fixture.

## Bypass candidates tested (move 11)

| Guard | Candidate | Outcome |
|---|---|---|
| floor (instr) | `src/CLAUDE.md/n.txt`, `src/skills/q/SKILL.md/n.txt` | lands: F1 |
| floor (import) | `docs/imp.md/n.txt`, with docs/imp.md imported but absent on main | lands: F1 |
| floor / GATE_CODE | `Scripts/Build-Loop.sh` | refused: floor lower-cases (`lp="$(lower "$1")"`), static |
| Paths: case | `Hooks/x.sh` with `hooks/x.sh` listed | refused (T10 test, executed in the fact-check base run) |
| Paths: prefix boundary | `docs/ab.md` with `docs/a` listed | refused (T10); a trailing `/` is required for prefix matching at `:661` |
| Paths: glob chars | `*`/`?` in an entry | pathform without `glob` refuses; `"$e"` is quoted in `[[ != "$e"* ]]`, static |
| never regex | every globform character | only `.` is special and it is escaped (fact-check Claim 8, executed) |
| own file case | `Docs/Reviews/Code-Review-2026-10-01-X.md` | lands: F2 |
| own file stem collision | `docs/reviews/2026-10-02-y-2026-10-01-x.md` | lands: F4 |
| rename | any R | `--no-renames`: both the D and the A side are judged |
| deletion | D of a floor file | floor ignores the status letter except for reviews; CLAUDE.md M/D refused (T10) |
| non-file mode | symlink/gitlink above a path | its own A/D entry, refused by the N rules' mode check (fact-check Claim 14, executed) |
| Unicode / non-ASCII | any non-NAMECHARS byte | nrules' `pathform "$6"` refuses it; check_line runs under C, so brackets compare bytewise |
| TOCTOU on checkout | the loop edits main's checkout after checkout_gate | the walk reads main's commit first; the checkout can only add imports or fail the walk (lib header :36-40), static |

## Endorsement Claims

- **Claim:** A path a `Self-merge never:` glob matches is refused before the allowlist, in any case and at any depth below a matching directory, for a self-merge brief's non-own-brief paths.
  **Location:** `scripts/build-loop.sh:633-657`
  **Evidence:** executed (fact-check T45 run and FCPROBE 3)
  **Verified:** `NEVER_RES+=("^$re(/|\$)")` built from the lower-cased glob, with `.` escaped; T45 denies `Workflows/Z.md` under `workflows/`.
  **Not verified:** a never glob made only of `*` (`*`), which builds `^[^/]*(/|$)` and denies everything. That fails closed, but no test exercises it.
  **route: code-fact-check**
- **Claim:** For a malformed Paths: line, nothing lands but the brief's own files, after floor and the never globs.
  **Location:** `scripts/build-loop.sh:613-628`, `:658-659`
  **Evidence:** executed (test :1967 in the fact-check base run)
  **Verified:** six malformed or empty variants each deny `docs/a` and pass `docs/working/plan-2026-10-01-x.md`.
  **Not verified:** a Paths: line holding a tab or CR inside an entry. Static reading says pathform refuses both, but no test runs it.
  **route: code-fact-check**
- **Claim:** The floor is skipped only when the checkout was refused, and in that case the verdict line is the refusal whatever the per-path rows say.
  **Location:** `scripts/build-loop.sh:654`, `:818`
  **Evidence:** read-static
  **Verified:** `if [[ -z "$5" ]] && floor …` and `if [[ -n "$co" ]]; then echo "$co"; …`
  **Not verified:** U3's caller reading the verdict line, not the path rows, which is outside this diff.

## Primitive sweep

Primitive: regex built from repo text (`[[ =~ $re ]]`)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/build-loop.sh:656` (`"$3" =~ $re`) | S3 never globs | globform charset; `.` escaped in never_res `:640` | cleared: no unescaped ERE metacharacter is reachable (fact-check Claim 8) |
| `scripts/build-loop.sh:599` (`"$7" =~ ^docs/working/(briefs\|cycles)(/\|$)`) | S1 path | constant regex | cleared |
| `scripts/build-loop.sh:603` (`"$TRUTH_WHY" =~ …`) | code constant | constant | cleared |

Primitive: path prefix or glob comparison (`[[ == "$e"* ]]`)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/build-loop.sh:661` | S2 Paths entries vs S1 path | `"$e"` quoted; pathform refuses `*?` | cleared; prefix only when the entry ends `/` |
| `scripts/lib/dev-cycle-read.sh:1809` (`*"-$2.md"`) | S4 stem vs S1 path | `$2` quoted | F4 (collision by design of NAME-STEM) |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Directory at an instruction name or import target lands | Low | B2 | `scripts/build-loop.sh:601-604` | High |
| 2 | Own files and reviews compare lower-cased; docs say the allowlist is exact | Low | B2 | `scripts/build-loop.sh:658` | High |
| 3 | plan:238 stale on malformed Paths: | Informational | B3 | `docs/working/plan-build-loop-handoff.md:238` | High |
| 4 | NAME-STEM review can take a sibling brief's STEM.md name | Informational | B2 | `scripts/lib/dev-cycle-read.sh:1809` | High (mechanism) / Low (precondition) |
| 5 | need_root exit 1 drops the brief's line; U3 must treat non-zero as nothing decided | Informational | B6 | `scripts/build-loop.sh:836-843` | High |

## Overall Assessment

The S rules hold against every case, Unicode, prefix-boundary, rename, deletion and mode trick I tried. None of the probes landed a path the D5 floor names as a file, a never glob matches, or Paths: leaves out (outside own files). Floor and the never globs fold case, Paths: compares exactly, and the non-ASCII and rename routes are closed further up the pipeline. The parent-shell/set -e change only adds exits, and they fail closed. Two gaps remain, both fixable in place. F1: row 523's "a directory at a protected name" reasoning stops at the cycle files and does not reach floor item 1's instruction files and import targets. F2: own files are matched lower-cased while the docs say the allowlist is exact. Neither lets instruction text or gate code land. The most important item is F1, because it is the decision of whether row 523's rule covers the floor too. Self-merge is not on in this repo and nothing calls --check to merge before U3, so none of this is live. No findings let a floor, never or allowlist path land within the code paths read. The endorsement claims are pending execution verification.

## Goal-Alignment Note

- Success criterion (restated verbatim): a markdown report saved at the output path your dispatch names, structured per your skill, every finding with verbatim Evidence and a path:line.
- Answered: yes. Five findings, each with a path:line and verbatim code or probe output; two probes run in a throwaway archive copy.
- Out of scope: the full suites (only the SECPROBE tests ran); U3's handling of exit statuses; whether Claude Code loads a directory named like an instruction file (assumed not; unverified).
- Escalate: F1 is a design question (does row 523 extend to floor item 1?) more than a code fix.
