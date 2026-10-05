Commit: 4dc84ce4

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u1c (claude-workflows, branch feat/build-loop-u1c)
**Scope:** `git diff main...feat/build-loop-u1c -- . ':!docs/reviews'` at 4dc84ce4 (scripts/build-loop.sh, scripts/lib/dev-cycle-read.sh, scripts/dev-cycle.sh, test/lib/build-loop-fixtures.bash, test/scripts/build-loop-read.bats) plus the unit's own commit messages (859e29e8, aaae80c6, 553a50d5, c143b929, 4dc84ce4)
**Checked:** 2026-10-05
**Total claims checked:** 32
**Summary:** 27 verified, 2 mostly accurate, 0 stale, 1 incorrect, 2 unverifiable

Replicate: r1. Scratch / execution logs: `/home/node/.claude/jobs/989f3e5a/tmp/review-u1c-i3/fc-r1/` (probe scripts `probe-c1.sh`..`probe-c6.sh`, logs `c1.log`..`c6.log`, `mut.log`, `head-bats.log`). Every probe ran with cwd = that scratch dir, under `timeout`, and left no processes. Hallucination-pattern log read (8 entries); no claim matches a logged pattern, and no fabrication was found, so the log is not updated.

Execution provenance (shared by the executed claims below):

| Log | Command (cwd = scratch dir) | Exit | Time (UTC) |
|---|---|---|---|
| `c1.log` | `./probe-c1.sh` (constraint task-box shapes via `--settings`) | 0 | 2026-10-05T17:32:26Z |
| `c2.log` | `./probe-c2.sh` (marker edge cases via `--status`) | 0 | 2026-10-05T17:32:55Z |
| `c3.log` | `./probe-c3.sh` (F31 under repo config variants) | 0 | 2026-10-05T17:33:13Z |
| `c4.log` | `./probe-c4.sh` (instrumented copy: BRIEF at use time) | 0 | 2026-10-05T17:33:39Z |
| `c5.log` | `./probe-c5.sh` (--status timing, new vs c143b929) | 0 | 2026-10-05T17:34:05Z |
| `mut.log` | `bats --tempdir bt/m -f T44 mut/test/scripts/build-loop-read.bats` (END check deleted) | 1 | 2026-10-05T17:34:33Z |
| `head-bats.log` | `bats --tempdir bt/h test/scripts/build-loop-read.bats` (cwd worktree) | 0 | 2026-10-05T17:34:33Z |
| `c6.log` | `./probe-c6.sh` (constraint grammar edges) + `shellcheck` | 0 | 2026-10-05T17:35:36Z |

---

## Claim 1: "--settings  four lines from the default branch's commit ... Lines 1-3 from one line of docs/dev-cycle.md"

**Location:** `scripts/build-loop.sh:10-12`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count and order of `--settings` output lines and that lines 1-3 come from docs/dev-cycle.md; does not establish anything about the fourth line's grammar (Claims 2-3).
**Legibility-target:** for-orchestrator-synthesis

`scripts/build-loop.sh:361` prints `printf '%s\n' "$POLICY_LINE" "$SLOTS_LINE" "$NEVER_LINE" "$CONSTRAINTS_LINE"`; the three settings lines come from `main_file "$f" "$SETTINGS_AWK"` with `f=docs/dev-cycle.md` (`:204-208`). The bats test "--settings prints its four lines in order" passes at HEAD (`head-bats.log`).

**Evidence:** `scripts/build-loop.sh:203-271`, `scripts/build-loop.sh:359-362`, `head-bats.log`

---

## Claim 2: "A constraint is a line "H<n>: text" (hard) or "S<n>: text" (soft) at column 0, optionally after "- ", n without a leading 0; a hard one needs a "success: <observable>" line (any indent, optionally after "- ") before the next constraint or "#" heading; no ID repeats; fences are skipped."

**Location:** `scripts/build-loop.sh:30-35`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the exact-ID regex, the success-line regex, column-0 `#` headings, duplicate detection (hard and soft) and fence skipping; does not establish that an indented ATX heading (`   ## Other`, a heading in CommonMark) ends a pending hard constraint — it does not, which the help's "a "#" line" wording permits.

`scripts/build-loop.sh:167` `/^(- )?[HS][123456789][0123456789]*: [^ \t]/`, `:177` `/^#/ { ... bad = "nosuccess " ...}`, `:178` `/^[ \t]*(- )?success: [^ \t]/ { pend = "" }`, `:170` the `dup` check, `:166` `fence($0) { next }`. Probe results (`c6.log`): a fenced `H2: x` gives `ok 1-hard`; `    - success: b` and tab-indented `success: b` satisfy H1; `Success: b` does not; `H0:` is refused; a repeated `S1` gives "listed twice". `   ## Other` followed by `  success: b` gives `ok` (the indented heading does not end H1).

**Evidence:** `scripts/build-loop.sh:164-186`, `c6.log`

---

## Claim 3: "A line starting like "h1"/"s1" in letters and digits (after marks and a task box) but not exact makes the file unreadable (best effort)."

**Location:** `scripts/build-loop.sh:36-38`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the GFM task-box shapes `[ ]`, `[x]`, `[X]` behind `- `, `* `, `1. ` or nothing, and mark prefixes; does not establish refusal of non-GFM bracket shapes containing letters (`- [x ] H2:`, `- [ x] H2:`, `- [xx] H2:` all give `constraints ok`, silently dropping H2), which fall in the letter-prefix family of override row 290 ("behind a prose word", Q-112 [1]) rather than being a new shape.

The fold is `scripts/build-loop.sh:175` `sub(/^([^a-zA-Z]|\[[ xX]\])*/, "", s)` then `:176` `s ~ /^[hs][0123456789]/ { ... bad = "near " NR ...}`. Probe (`c1.log`): `- [x] H2: x`, `- [X] H2: x`, `* [x] H2: x`, `1. [x] H2: x`, `[x]H2: x`, `- [ ] H2: x`, `- [x][x] H2: x`, `- [-] H2: x`, `- [x]  H2: x`, `- [x] **H2**: x`, `` - [x] `H2`: x `` → unreadable. `- [x ] H2: x`, `- [ x] H2: x`, `- [xx] H2: x` → `constraints ok 1-hard 0-soft` (none of these is a GFM task box; the help's "a task box" holds).

Behaviour change vs c143b929 (fail-closed, not contradicted by the help): the old fold `sub(/^[^a-zA-Z]*/, "", s)` (c143b929 `scripts/build-loop.sh:172`) left the `x` of a checked box in place, so `- [x] S3 bucket moved` and `- [x] h2o` were read as prose; at 4dc84ce4 both make the file unreadable (`c1.log`). `- [x] see S3` stays ok.

**Evidence:** `scripts/build-loop.sh:175-176`, `c1.log`, `git show c143b929:scripts/build-loop.sh` line 172

---

## Claim 4: "Only "ok" lets the orchestrator dispatch."

**Location:** `scripts/build-loop.sh:38`
**Type:** Architectural
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers agreement with the plan; does not establish any runtime behaviour, since no orchestrator code consumes `--settings` yet.

The plan states it: `docs/working/plan-build-loop-handoff.md:260` "**Step 10, dispatch**: only when `--settings` prints `constraints ok`". No caller exists (paraphrased — no quote available because the claim covers absence of code: `rg "constraints ok|build-loop.sh --settings|build-loop.sh --status" skills/ workflows/ scripts/` outside build-loop.sh returns nothing). Needed to verify: the dev-cycle orchestrator step (planned for a later unit).

**Evidence:** `docs/working/plan-build-loop-handoff.md:260`

---

## Claim 5: "--status  one line per brief path, in argument order, from the default branch's commit (the path must also be plain in the working tree, as --check-brief)"

**Location:** `scripts/build-loop.sh:43-45`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers order, main's-commit reading and the working-tree plainness check via `blocker`; does not establish that the path must exist in the working tree (it need not: an absent path is not blocked, and a brief not landed reads `new`).

`:357` `for a in "${ARGS[@]}"; do status_line "$a"; done`; `check_brief` (`scripts/lib/dev-cycle-read.sh:329`) `if [[ -n "$(blocker "$a" file)" ]]; then echo "skip $a: reached through a symlink, or not a regular file"`; `blocker` returns nothing for an absent path (`scripts/lib/dev-cycle-read.sh:111,114`). T21 and T28 (order across six arguments) pass at HEAD (`head-bats.log`).

**Evidence:** `scripts/build-loop.sh:354-358`, `scripts/lib/dev-cycle-read.sh:107-117`, `scripts/lib/dev-cycle-read.sh:321-360`, `head-bats.log`

---

## Claim 6: "ok BRIEF STATE POLICY BRANCH LOOP SHA DATE DISPATCHED [REASON]" with the STATE/new, POLICY, BRANCH, LOOP, SHA/DATE, marker (empty commit, one parent, exact subject, 1-120 printable ASCII reason, second line empty), REASON-last and DISPATCHED rules

**Location:** `scripts/build-loop.sh:46-63`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the field order and each field rule for a branch ahead of main; does not establish the 0-ahead case of the skip clause (Claim 8).

`:322` `echo "ok $a new review - absent - - 0"`; `:332` `[[ "$POLICY" == self-merge && "${BRIEF[policy]-}" == "Policy: self-merge" ]] && pol=self-merge`; `:328` `^Dispatched:\ (0|[123456789][0123456789]?)$`; `:351` `echo "ok $a $st $pol $br $loop $sha $date $disp$reason"`; marker rules `:282-295` (NUL, parents, `rev-parse ^{tree}` equality, second-line check `-n "${rest%%$'\n'*}"`, reason regex `[!-~]([ -~]{0,118}[!-~])?`); DATE from `git log -1 --format=%cs` (`scripts/lib/dev-cycle-read.sh:380`). Probe (`c2.log`): a whitespace-only second line skips ("runs onto a second line"), an empty second line followed by a body reads `ready`. T5/T6/T7/T8 pass (`head-bats.log`).

**Evidence:** `scripts/build-loop.sh:276-296`, `scripts/build-loop.sh:316-352`, `c2.log`, `head-bats.log`

---

## Claim 7: "A tip whose subject does not start "handoff:" is working."

**Location:** `scripts/build-loop.sh:61-62`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers case-sensitive prefix matching on the first line of `%B`; does not establish the converse (a 0-ahead tip whose subject does start "handoff:" is also working — Claim 8).

`:281` `[[ "$subj" == handoff:* ]] || { echo working; return; }`. Probe (`c2.log`): `Handoff: ready` → working; a leading blank line → working (override row 294).

**Evidence:** `scripts/build-loop.sh:279-281`, `c2.log`

---

## Claim 8: skip clause "... or the tip's subject (its message's first line) starts "handoff:" but it is not a marker."

**Location:** `scripts/build-loop.sh:69-71`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers branches at least one commit ahead of main; the clause omits that a tip on a branch 0 commits ahead whose subject starts "handoff:" (even a malformed one) is read as working, not skipped.

`:342-343` `loop=working` / `if [[ "$ahead" -gt 0 ]]; then kind="$(marker_kind "$sha")"` — marker_kind (and its "bad" skip) runs only when ahead > 0. Probe (`c2.log`): main's tip `handoff: stopped: ` (empty reason, malformed) with `feat/a` = main → `ok ... feat/a working <sha> ...`, while the clause as written predicts a skip. The marker definition earlier in the help (":55-56 A tip is a marker only when the branch is at least one commit ahead") and test `build-loop-read.bats` "A marker at main's tip with the branch 0 commits ahead is main's" agree with the code. Precise version: "...or, on a branch ahead of main, the tip's subject starts "handoff:" but it is not a marker."

**Evidence:** `scripts/build-loop.sh:342-350`, `c2.log`

---

## Claim 9: "for an open brief, another open brief on main (in briefs/ or closed/) names the same branch (ignoring case)"

**Location:** `scripts/build-loop.sh:68-69`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers default git config: open-only application, closed/ counting, case folding, working-tree briefs ignored; does NOT hold when the repo's config sets `color.ui=always` or `color.grep=always`, or when `git grep` fails — then no brief is ever skipped for sharing a branch (see Claim 18, Incorrect).

`:333` `if [[ "$st" == open && "$SHARED_BRANCHES" == *$'\n'"$(lower "$br")"$'\n'* ]]`; candidate set from `shared_branches` (`:301-315`). Probe `c3.log` baseline, CRLF, closed-open: correct skips. T28 passes.

**Evidence:** `scripts/build-loop.sh:301-335`, `c3.log`, `head-bats.log`

---

## Claim 10: usage strings "(usage: build-loop.sh --settings | --status BRIEF...)" and "--status needs at least one brief path"

**Location:** `scripts/build-loop.sh:93-97`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers exit 1 for bare `--status`; does not establish validation of the paths themselves (each is judged per line).

`:97` `--status) MODE=status; shift; ARGS=("$@"); [[ $# -gt 0 ]] || usage "--status needs at least one brief path" ;;`. The usage loop in the "four lines" test includes `"--status"` and passes.

**Evidence:** `scripts/build-loop.sh:93-101`, `head-bats.log`

---

## Claim 11: "docs/constraints.md: "ok HARD SOFT", "nosuccess ID LINE", "dup ID FIRST SECOND" or "near LINE" (the first problem found)."

**Location:** `scripts/build-loop.sh:161-162`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers CONSTRAINTS_AWK's own outputs; does not list FENCE_AWK's `odd`/`unbalanced` outputs, which main_file consumes before the caller sees FILE_OUT.

Every `bad =` assignment is guarded by `bad == ""` (`:169,170,176,177,183`), so the first problem wins; `:184` `print (bad != "" ? bad : "ok " hard + 0 " " soft + 0)`.

**Evidence:** `scripts/build-loop.sh:164-186`, `scripts/build-loop.sh:131-136`

---

## Claim 12: "Sets POLICY, POLICY_LINE, SLOTS_LINE, NEVER ..., NEVER_LINE and CONSTRAINTS_LINE from main's commit. POLICY is for --status and the planned gate, NEVER for the gate."

**Location:** `scripts/build-loop.sh:197-200`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the variables set and their current/planned readers; does not establish the gate's behaviour (not yet written).

`:332` reads `$POLICY` in status_line; NEVER has no reader in the script (paraphrased — no quote available because the claim covers absence of code: `NEVER` appears only at its assignments `:201,206,242`). The gate is planned (`docs/working/plan-build-loop-handoff.md:66-71`, D5).

**Evidence:** `scripts/build-loop.sh:197-271`, `scripts/build-loop.sh:332`

---

## Claim 13: "# shellcheck disable=SC2034  # POLICY and NEVER: see above"

**Location:** `scripts/build-loop.sh:202`
**Type:** Staleness
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which variables still trigger SC2034; does not establish anything about other directives.

With the directive removed, shellcheck reports only `NEVER appears unused` at line 242 (`c6.log` tail); POLICY is now read at `:332`, so the disable is needed only for NEVER. Precise version: "NEVER: see above". (Harmless.)

**Evidence:** `scripts/build-loop.sh:202`, `scripts/build-loop.sh:332`, `c6.log`

---

## Claim 14: "prints ready, blocked, "stopped REASON", working (no "handoff:" subject), or "bad WHY". The caller has checked that the branch is at least one commit ahead of main."

**Location:** `scripts/build-loop.sh:273-275`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers marker_kind's outputs and its sole caller; does not establish marker semantics for 0-ahead tips (not called).

Outputs at `:281,282-285,287,289-290,294-295`; sole caller `:343-344` `if [[ "$ahead" -gt 0 ]]; then kind="$(marker_kind "$sha")"`.

**Evidence:** `scripts/build-loop.sh:276-296`, `scripts/build-loop.sh:342-350`

---

## Claim 15: "git parses the object: its tree, its parents and where the message starts." (and bats: "A hand-made object with two tree lines ... git stops at the second and sees no parent")

**Location:** `scripts/build-loop.sh:278`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers rev-list/rev-parse/log parsing of the tip; does not establish behaviour under replace refs beyond `:111-112`'s guard.

`:279` `read -ra p <<<"$(git rev-list --parents -n 1 "$1")"`, `:280` `msg="$(git log -1 --format=%B "$1")"`, `:285` `rev-parse --verify "$1^{tree}"`. T7's two-tree object yields "it has no parent" and passes (`head-bats.log`).

**Evidence:** `scripts/build-loop.sh:276-296`, `test/scripts/build-loop-read.bats` T7, `head-bats.log`

---

## Claim 16: "grep in the C locale: the ranges are ASCII bytes, and no locale is switched here."

**Location:** `scripts/build-loop.sh:293`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the reason check refusing non-ASCII and control bytes; does not establish behaviour under a non-GNU grep.

`:294` `printf '%s\n' "$r" | LC_ALL=C grep -qxE '[!-~]([ -~]{0,118}[!-~])?'` — the locale is set for grep only. T7's `caf\xc3\xa9`, ESC and U+202E reasons skip (passing).

**Evidence:** `scripts/build-loop.sh:292-295`, `head-bats.log`

---

## Claim 17: "Lower-cased branch names that more than one open brief on main (in briefs/ or closed/) names, each between newlines ... status_line computes it on first use, so no caller can skip it."

**Location:** `scripts/build-loop.sh:297-299`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the set's shape and its computation on the first status_line call; does not establish that the computed set is correct under all repo configs (Claim 18).

`:313-314` `SHARED_BRANCHES=$'\n'` then `[[ "${n[$b]}" -lt 2 ]] || SHARED_BRANCHES+="$b"$'\n'`; `:318` `[[ -n "$SHARED_BRANCHES" ]] || shared_branches` (the global is never empty after the first call). `c3.log` closed-open case and T28 confirm.

**Evidence:** `scripts/build-loop.sh:297-318`, `c3.log`

---

## Claim 18: "One git grep finds the files with a "Status: open" line (a superset: fences are not modelled); brief_fields then reads only those."

**Location:** `scripts/build-loop.sh:304-306`
**Type:** Behavioral / Error-handling
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the candidate set's relation to brief_fields' `Status: open` reading under repo config and git failure; it IS a superset under default config (CRLF, `grep.patternType=perl|fixed`, `grep.fullName`, `core.quotePath=false`, `grep.column`/`grep.lineNumber`, binary attribute, nested directories all fine), so the residue is config- and failure-driven only.

```bash
# scripts/build-loop.sh:306-309
list="$(git grep -l -E '^Status: open'$'\r''?$' "$MAIN_SHA" -- docs/working/briefs/ || true)"
while IFS= read -r f; do
  f="${f#"$MAIN_SHA":}"
  if ! isbrief "${f/closed\//}" || ! brief_fields "$f"; then continue; fi
```
(excerpt ends :309; enclosing shared_branches() continues to :315 — read)

- With `color.ui=always` or `color.grep=always` in the repo's `.git/config`, `git grep -l` prefixes each line with ANSI codes even when piped (scratch `r3`: `od -c` shows `033 [ 3 5 m 9f2d...:docs/working/briefs/...`). The `${f#"$MAIN_SHA":}` strip then fails, `isbrief` rejects every path, the set is empty, and two open briefs naming `feat/x` both print `ok ... feat/x absent` (`c3.log`, cases `color.grep=always`, `color.ui=always`). F31 silently turns off.
- If `git grep` fails (e.g. `grep.patternType=bogus` → `fatal: bad grep.patterntype argument`, exit 128), `|| true` swallows it and the set is empty — same result, both open briefs `ok` (`c3.log`, case `patternType=bogus`); no line names the failure.
- Regression: at c143b929 (brief_fields over every brief, no git grep) the same repo with `color.ui=always` correctly skipped (`old/scripts/build-loop.sh --status` in scratch `r3`: "skip ...: another open brief ...").

The repo config is uid-writable (the script itself treats repo config as hostile for `core.useReplaceRefs`, `:107-111`). Not covered by any override-log row (rows 290-296 checked). The candidate list is therefore not a superset whenever config changes git grep's output, and a git failure is fail-open.

**Evidence:** `scripts/build-loop.sh:301-315`, `scripts/build-loop.sh:107-112`, `c3.log`, scratch repo `r3`

---

## Claim 19: "first: it reads other briefs into BRIEF"

**Location:** `scripts/build-loop.sh:318`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers BRIEF's contents at status_line's reads of branch, dispatched and policy for several arguments in one run, including queried briefs that git grep lists (open in briefs/, plus an open closed/ brief later in the list); does not establish other global state (BRIEF_ODD).

An instrumented copy printing BRIEF right after `:323` `brief_fields "$a"` shows, for orders `a m z`, `m a z`, `z a m`, each queried brief's own Branch/Dispatched/Policy, never the last grep-listed `closed/2026-10-01-zz.md` (`c4.log`; e.g. `DEBUG ...-a.md: Branch: feat/a | Dispatched: 3 | Policy: self-merge` → `ok ...-a.md open self-merge feat/a absent - - 3`). `check_brief` runs in `$(...)`, so its brief_fields call cannot touch the parent's BRIEF.

**Evidence:** `scripts/build-loop.sh:316-335`, `c4.log`

---

## Claim 20: "kept in a lib so scripts/build-loop.sh can share it" / "kept apart so scripts/build-loop.sh can share it"

**Location:** `scripts/dev-cycle.sh:87`, `scripts/lib/dev-cycle-read.sh:2-3`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that build-loop.sh sources the lib; does not establish which lib functions it uses beyond those read here.

`scripts/build-loop.sh:87-90` `READ_LIB="$SCRIPT_DIR/lib/dev-cycle-read.sh"` ... `source "$READ_LIB"`.

**Evidence:** `scripts/build-loop.sh:84-91`

---

## Claim 21: fixture helper comments (commit_all "an empty commit when nothing changed"; constraints; brief "sets B to its path"; work "one commit that changes a file"; tip "no cleanup ... By default it is empty ... with BRANCH's tip as its one parent")

**Location:** `test/lib/build-loop-fixtures.bash:21-66`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each helper against its body; does not establish anything about the hermetic env lines (unchanged).

`commit_all() { git add -A && git commit -q --allow-empty -m "${1:-fixture}"; }`; `brief()` sets `B="docs/working/briefs/2026-10-01-$s.md"`; `work()` writes `work-${1//\//-}.txt`; `tip()` default `t="$(git rev-parse "$b^{tree}")"; p=(-p "$(git rev-parse "$b")")` piped through `git commit-tree` (no message cleanup).

**Evidence:** `test/lib/build-loop-fixtures.bash:21-66`

---

## Claim 22: T44 case `'- S1: a' '- H1: b'` → "hard constraint H1 (line 2) has no success: line" tests the END check (C16)

**Location:** `test/scripts/build-loop-read.bats:183-184`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the mutation that deletes the END-block nosuccess line; does not establish coverage of the per-constraint (`:169`) or heading (`:177`) nosuccess paths by this case.

Deleting `:183` `if (bad == "" && pend != "") bad = "nosuccess " pend " " pendl` in a copy makes T44 fail at line 184 with `constraints ok 1-hard 1-soft` (`mut.log`, exit 1); unmutated suite passes 16/16 (`head-bats.log`).

**Evidence:** `scripts/build-loop.sh:183`, `test/scripts/build-loop-read.bats:183-184`, `mut.log`, `head-bats.log`

---

## Claim 23: "A ready marker's body is not read here (the planned --marker reads blocked and stopped bodies)."

**Location:** `test/scripts/build-loop-read.bats:256` (diff line 447)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with the plan and that no --marker mode exists yet; does not establish --marker's eventual behaviour.

Plan `docs/working/plan-build-loop-handoff.md:206` "`--marker BRIEF` → `ok BRIEF SHA`, then the `blocked` or `stopped` body"; build-loop.sh's `case` (`:95-101`) has no `--marker`.

**Evidence:** `docs/working/plan-build-loop-handoff.md:206`, `scripts/build-loop.sh:95-101`

---

## Claim 24: test comments "A marker at main's tip with the branch 0 commits ahead is main's, not the loop's", "So is a branch that is a symbolic ref to main", "An open brief left in closed/ counts too", "An open brief only in the working tree does not count", test titles T5-T8, T21, T28, T44

**Location:** `test/scripts/build-loop-read.bats:148-390` (diff hunks)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each comment/title against its assertions and the code path it reaches; does not establish untested shapes listed in override rows 291 and 295.

All 16 tests pass at HEAD (`head-bats.log`); the 0-ahead path is `:343` (marker_kind not called), the working-tree exclusion follows from `git grep ... "$MAIN_SHA"` (`:306`).

**Evidence:** `test/scripts/build-loop-read.bats`, `scripts/build-loop.sh:306,343`, `head-bats.log`

---

## Claim 25: 4dc84ce4: "One `git grep -l '^Status: open'` on main now picks the candidates, brief_fields reads only those, and status_line computes the set first."

**Location:** commit 4dc84ce4 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the described mechanism and ordering under default config; does not establish that the candidates are complete under repo color config or a git grep failure (Claim 18).

`scripts/build-loop.sh:306` and `:318` as quoted in Claims 17-18; `c4.log` confirms ordering.

**Evidence:** `scripts/build-loop.sh:301-323`, `c4.log`

---

## Claim 26: 4dc84ce4: shared_branches was "O(every closed brief), 8 s at 500"

**Location:** commit 4dc84ce4 message
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers order of magnitude on this machine with 3 open briefs and N closed `Status: done` briefs, one argument; does not establish exact timing on other hardware.

`c5.log`: c143b929 copy — N=0 0.07 s, 50 0.34 s, 200 2.41 s, 500 10.38 s; 4dc84ce4 — 0.06, 0.07, 0.07, 0.08 s. The old cost is in the claimed range (10 s here vs 8 s claimed; grows faster than linear in this run); the new cost is flat.

**Evidence:** `c5.log`

---

## Claim 27: 4dc84ce4: "A12: a leading task box (`- [x] H2:`) no longer hides a constraint ID"

**Location:** commit 4dc84ce4 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claim 3 (GFM task boxes); does not cover non-GFM bracket shapes.

`c1.log`: `- [x] H2: x` → unreadable; T44 includes it.

**Evidence:** `scripts/build-loop.sh:175`, `c1.log`

---

## Claim 28: 4dc84ce4: "433 changed code lines against main"

**Location:** commit 4dc84ce4 message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `git diff --numstat main...HEAD -- . ':!docs/reviews'` added+removed; does not establish a count that excludes docs/working.

numstat: 175+8, 1+1, 2+2, 32+2, 207+3 = 433 (all five changed paths are code/test files).

**Evidence:** `git diff --numstat main...HEAD -- . ':!docs/reviews'`

---

## Claim 29: c143b929 "426 changed code lines against U1b"; 553a50d5 "U1c stays at 399 changed code lines against U1b"

**Location:** commits c143b929, 553a50d5 messages
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers diffs against the U1b tip most recently merged before each commit (2e711a7b, 1d79ffef); does not establish counts against other U1b tips.

`git diff --numstat 2e711a7b c143b929 -- . ':!docs/reviews'` sums to 426; `1d79ffef 553a50d5` sums to 399.

**Evidence:** numstat commands above

---

## Claim 30: aaae80c6: "`git log -1 -G'^Status: '` costs about 1 ms per brief on this repo (2137 commits, 1017 first-parent) ... --status over the 3 real briefs: 79 ms."

**Location:** commit aaae80c6 message
**Type:** Performance
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** A point-in-time measurement of the repo as it stood then; not re-measured.

Paraphrased — no quote available because the claim is a historical timing, not code. Needed: re-running on a checkout of the repo at that commit's main.

**Evidence:** commit aaae80c6

---

## Claim 31: aaae80c6: "The real briefs have no Branch: line yet, so --status skips them"

**Location:** commit aaae80c6 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the briefs in this worktree at HEAD; does not establish main's later state.

`rg -n "^Branch:" docs/working/briefs/` returns nothing (paraphrased — no quote available because the claim covers absence of matching lines); `:324` then prints "skip ...: no Branch: line on the default branch".

**Evidence:** `scripts/build-loop.sh:324`, `docs/working/briefs/`

---

## Claim 32: 859e29e8: T7 covers "content, a merge, an orphan, suffixed or mis-cased subjects, an empty, control, bidi or non-ASCII reason, a two-line subject"

**Location:** commit 859e29e8 message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the T7 test body at HEAD; does not establish coverage of the NUL refusal (override row 291).

T7 builds each shape: `commit_all 'handoff: ready'` with a file change, a two-parent `tip`, an orphan `tip ... ""`, `'handoff: blocked!' 'handoff: Ready' 'handoff: stopped: ' $'...a\x1b[31mb' $'...caf\xc3\xa9' $'...x\xe2\x80\xaey'`, and `$(printf 'handoff: ready\nmore subject')`.

**Evidence:** `test/scripts/build-loop-read.bats` T7 (diff lines 453-494)

---

## Claims Requiring Attention

### Incorrect
- **Claim 18** (`scripts/build-loop.sh:304-306`): the git grep candidate set is not a superset when the repo config sets `color.ui=always`/`color.grep=always` (ANSI-prefixed paths fail `isbrief`) or when git grep fails (`|| true`); F31 then silently skips nothing, and two open briefs on one branch both print `ok`. Regression from c143b929. Precise fix direction for the comment or code: pass `--no-color` (or `-c color.grep=false`) and do not swallow a non-1 exit.

### Stale
- None.

### Mostly Accurate
- **Claim 8** (`scripts/build-loop.sh:69-71`): the "starts handoff: but is not a marker" skip applies only on a branch ahead of main; a 0-ahead handoff: tip (even malformed) is working.
- **Claim 13** (`scripts/build-loop.sh:202`): SC2034 now fires only for NEVER; POLICY is read at `:332`.

### Unverifiable
- **Claim 4** (`scripts/build-loop.sh:38`): "Only ok lets the orchestrator dispatch" matches plan :260, but no orchestrator code consumes it yet.
- **Claim 30** (commit aaae80c6): point-in-time timing; needs a re-run against that commit's repo state.

---

## Goal-Alignment Note

The goal is a final confirming review of U1c before merge. This pass verified every brief item by execution. Most help text, comments and commit claims match the code. Iteration 2's X1 fix works as described under default config: BRIEF is no longer clobbered, and the cost drops from ~10 s to 0.08 s at 500 closed briefs. The mutation test confirms the C16 test is effective. One new, merge-relevant defect appears: the X1 git grep makes F31 depend on repo config. With `color.ui=always` (or a failing git grep), the shared-branch skip turns off silently, while the code it replaced handled that case. This is outside Q-112's best-effort scope, which covers constraint detection, and no override row covers it. The orchestrator should weigh it as a possible red/amber for the rubric. The 0-ahead skip-clause wording and the SC2034 comment are minor wording drift. The non-GFM bracket shapes (`[x ]`, `[xx]`) fall under row 290's prose-word-prefix residue and should not be re-filed.
