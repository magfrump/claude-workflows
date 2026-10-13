Commit: 74deb04e

# Architecture Review — feat/build-loop-u3c (iteration 2, full branch)

**Scope:** `git diff main...HEAD` (main = dafc0e74, HEAD = 74deb04e): `scripts/build-loop.sh` (`--cycle-diff`, QKEYS_AWK, QDIFF_AWK, ROADMAP_AWK, cyc_blob, cycle_diff, raw_records, check_line and log_class on raw_records), `scripts/health-check.sh` (take_lock), the two test files and the plan bullet as context.
**Date:** 2026-10-12
**Based on:** `docs/reviews/code-fact-check-report-2026-10-12-u3c-i2.md` (33 claims: 29 verified, 4 mostly accurate, 0 incorrect). Its behaviour verdicts are taken as given and not re-verified here.

Scope check: in scope. The diff adds a public CLI mode (`--cycle-diff`) whose contract U4 consumes, a shared reader (`raw_records`) that three existing callers now depend on, a third copy of the questions-entry grammar, and a cross-cutting lock on the repository's health gate.

## Dependency Map

- `scripts/build-loop.sh` sources `scripts/lib/dev-cycle-read.sh` (the shared readers: FENCE_AWK, ANSWER_AWK/check_answer, main_entry, isbrief/isclosed, git_harden). The dependency runs one way, script to lib. The lib only *mentions* build-loop.sh in comments: ANSWER_AWK's "build-loop.sh's ANSWERS_AWK ... copies these labels ... change both together" (`dev-cycle-read.sh:2055-2056`).
- Inside build-loop.sh, `raw_records` (`:967-980`) is a new internal hub. It is called by check_line (`:1316`), by log_class's chore loop (`:1702`) and answers loop (`:1709`), and by cycle_diff (`:1811`). It hands results back through six global arrays. cyc_blob (`:1799-1804`) reads those globals by record index.
- cycle_diff depends on FENCE_AWK (lib) and on QKEYS_AWK and QDIFF_AWK (local). By its own comments it also depends on the meaning of the lib's ANSWER_AWK ("as --check-answer delimits one") and of ANSWERS_AWK ("ANSWERS_AWK's labels"). Those are semantic dependencies on another module's internals, not calls.
- ROADMAP_AWK (`:1779-1794`) depends on the meaning of `skills/dev-cycle/SKILL.md` step 6: the template's headings, the Done section, and the `briefs/closed/` move. It does not call anything there; it re-encodes the prose as code.
- `scripts/health-check.sh` gains take_lock (`:1106-1121`). It depends on flock(1) and git's common dir, and adds one environment variable, `HEALTH_CHECK_LOCK_HELD`, that every descendant inherits. It sources none of build-loop.sh's code. Its plain-file test is a by-hand copy of the dispatch lock's (`build-loop.sh:1919`).
- No new cycles. Dependency direction is preserved: nothing in the lib or the skill depends on build-loop.sh's new code.

Trust-boundary cross-reference: the most recent security review, `docs/reviews/security-review-2026-10-12-u3b3-i2.md` (Commit: `5d175c0e`; it predates this diff, so its boundaries may be stale), maps B1–B5 around the D6 snippet and git_harden. None of the findings below moves or relocates one of those crossings. Finding 1 concerns the answer-trust decision (which recorded answers count), which that map does not label.

## Findings

#### 1. The questions-entry grammar now has three hand-kept readers and four Status parses, but the "change both together" pointer names only two; drift fails open for --cycle-diff

**Severity:** Coupling
**Location:** `scripts/build-loop.sh:1744-1752` (QKEYS_AWK), `:1759-1765` (QDIFF_AWK's answered()), `:1640-1658` (ANSWERS_AWK), `scripts/lib/dev-cycle-read.sh:2055-2094` (ANSWER_AWK)
**Move:** 7 (coupling surface), 3 (module boundary)
**Confidence:** High
**Legibility-target:** for-author

ANSWER_AWK in the lib defines what an answer is. That definition gates `--approved` and a brief's `Asked:` IDs: an entry heading, an entry end, which lines are answer labels, and how the Status field is read. ANSWERS_AWK already copied the labels and the Status field, with a two-way comment pair. QKEYS_AWK makes a third copy of the labels plus the entry delimiting (heading regex, `#`/`##`/`###` end, fence skip). QDIFF_AWK's `answered()` is a fourth parse of the Status field, with different trimming and a different "which field" rule (any field, not the last). None of the four pointer comments names QKEYS_AWK or QDIFF_AWK. The lib's says "build-loop.sh's ANSWERS_AWK ... copies these labels ... change both together".

The direction of drift matters. Suppose someone widens ANSWER_AWK by following its own comment and updating ANSWERS_AWK too, say with a new label or a looser heading. check_answer would then read a line that QKEYS_AWK does not tag. A cycle could add that line to an existing entry with no `--answered`, and --cycle-diff would print `ok`. That reopens the laundering path F42 this unit closes (fact-check Claim 11 confirms the current copies agree; the risk is the next edit). It is the same class as override row 724 for `--raw -z`, which this unit fixes for raw listings and recreates here for the questions grammar.

Evidence (verbatim):

```awk
# scripts/lib/dev-cycle-read.sh:2055-2056
# build-loop.sh's ANSWERS_AWK (--main-log's answers class) copies these labels
# and the header line's Status field: change both together.
```
```awk
# scripts/lib/dev-cycle-read.sh:2088-2094 (in ANSWER_AWK's main rules; the !done block continues to :2104 and END to :2111, read)
  if (index(line, id ":") == 1) { result = option(substr(line, length(id) + 2)); done = 1; next }
  low = tolower(line)
  if (low !~ /^\*\*answer(:|ed| \()/) next
```
```awk
# scripts/build-loop.sh:1658 (ANSWERS_AWK)
  if (t ~ /^Q-[0123456789]+:/ || tolower(t) ~ /^\*\*answer(:|ed| \()/) { if (s == "+") n++; next }
# scripts/build-loop.sh:1751 (QKEYS_AWK)
{ t = $0; sub(/^- /, "", t); if (t ~ /^Q-[0123456789]+:/ || tolower(t) ~ /^\*\*answer(:|ed| \()/) print id "\t" f "\ta\t" $0 }
# scripts/build-loop.sh:1760-1764 (QDIFF_AWK answered(), whole)
function answered(k, l,   n, i, g) {
  if (k == "a") return 1
  n = split(l, fld, " · ")
  for (i = 1; i <= n; i++) { g = fld[i]; sub(/^[ \t]+/, "", g); sub(/[ \t]+$/, "", g); if (k == "n" && g == "**Status:** ANSWERED") return 1 }
  return 0
}
```

Does it belong in the lib? QKEYS_AWK as a whole does not. Its output format (`ID F K LINE`) is cycle_diff's own. The grammar predicates it shares do belong there: "is this an answer-label line", "is this a `### Q-N` heading, and which ID", "does this end an entry", and "is this Needs line ANSWERED". The lib already owns the canonical reader, and both scripts source it.

**Recommendation:** Move the shared predicates into the lib as one awk function prelude, for example `QGRAMMAR_AWK` with `function qlabel(t)`, `function qhead_id(l)` and `function qend(l)`. Prepend it the way FENCE_AWK is prepended (`"$FENCE_AWK$QGRAMMAR_AWK$ANSWER_AWK"`), and call it from ANSWER_AWK, ANSWERS_AWK and QKEYS_AWK. That is roughly 10–15 changed lines and fits the cap. If that is too much for this unit, the minimum is to name QKEYS_AWK and QDIFF_AWK's answered() in the lib's pointer at `:2055-2056` and in ANSWERS_AWK's, and to add a one-line bats check that the label regex text is identical in all three programs. The fail-open direction is why this is Coupling rather than Minor.

#### 2. raw_records returns through six globals that cycle_diff and cyc_blob address by index across the whole function

**Severity:** Minor
**Location:** `scripts/build-loop.sh:967-980` (raw_records), `:1799-1804` (cyc_blob), `:1806-1840` (cycle_diff's `qi` and second loop)
**Move:** 3 (module boundary), 7 (coupling)
**Confidence:** Medium
**Legibility-target:** for-author

Row 724 is discharged: there is now one parser, and check_line's refusal text is unchanged (fact-check Claims 2, 8, 18). The helper's output, though, is shared mutable state that its callers consume in two styles. check_line copies the arrays into locals right away (`oms=("${RAW_OM[@]}")`, `:1317`). log_class and cycle_diff read `RAW_*` in place. cycle_diff keeps record indices in `qi` and passes `$i`/`$k` to cyc_blob, which looks them up in the globals. That works only because no `raw_records` call happens between `:1811` and the end of the second files loop. If a later edit adds one, for example a `diff-tree` check inside that span or a helper that lists another commit, cyc_blob silently reads another listing's modes and ids. Nothing would fail; the wrong blob would be judged. cyc_blob's signature (`I SIDE OUT`) hides that dependency.

Evidence (verbatim):

```bash
# scripts/build-loop.sh:1799-1804 (cyc_blob, whole)
cyc_blob() {
  local md="${RAW_NM[$1]}" id="${RAW_NO[$1]}"
  [[ "$2" == new ]] || { md="${RAW_OM[$1]}"; id="${RAW_OO[$1]}"; }
  if [[ "$md" == 000000 ]]; then : > "$3"; return 0; fi
  [[ "$md" == 100644 ]] && gate_git cat-file blob "$id" > "$3"
}
```

**Recommendation:** Make cyc_blob take `MODE ID OUT`, so the caller passes `"${RAW_OM[i]}" "${RAW_OO[i]}"`. Optionally snapshot the arrays into locals at `:1811`, as check_line does. Say in raw_records' comment that callers must copy before they call anything that may list again. About 4 changed lines. Finding 3's fix can reuse the same signature.

#### 3. cycle_diff has a second, inline "file at path on BASE" reader beside cyc_blob, and that is where fact-check Claim 15's exception lives

**Severity:** Minor
**Location:** `scripts/build-loop.sh:1840-1844`
**Move:** 2 (responsibility boundaries), 8 (extension points)
**Confidence:** Medium
**Legibility-target:** for-author

A questions file is read from BASE in one of two ways. A changed one goes through cyc_blob (mode taken from the raw record; absent means mode 000000). An unchanged one goes through an inline `cat-file -e` probe, then `ls-tree | cut -c1-6`, then `cat-file blob "$base:$f"`. The second path has its own idea of "absent", namely that the probe failed. That is why a failed read is skipped rather than refused (fact-check Claim 15, E7). It also asks for the mode and the content in two separate git calls on a path. The lib's `main_entry` solves the same problem for MAIN_SHA. The result is three "what is at PATH on REV, and is it a regular file" readers, each with its own failure semantics.

Evidence (verbatim):

```bash
# scripts/build-loop.sh:1840-1844 (the unchanged-file branch; the files loop continues to :1851, read)
    elif gate_git cat-file -e "$base:$f" 2>/dev/null; then
      [[ "$(gate_git ls-tree "$base" -- "$f" | cut -c1-6)" == 100644 ]] && gate_git cat-file blob "$base:$f" > "$t.o" \
        || { echo "refuse $f: not a regular file on the base, or could not be read"; return 1; }
      cp "$t.o" "$t.n"
    else continue; fi
```

**Recommendation:** Run one `gate_git ls-tree -z "$base" -- "$f"`. An empty result with exit 0 means absent; a failure refuses. Then feed its mode and id to the same blob reader as the raw records (Finding 2's `cyc_blob MODE ID OUT`). That gives one reader with one absent-or-failed rule, and it removes Claim 15's exception. About 4–5 lines.

#### 4. ROADMAP_AWK re-encodes SKILL.md step 6 with no back-pointer, a stricter Done match than dev-cycle.sh's section reader, and a looser brief-name grammar than the lib's isbrief

**Severity:** Minor
**Location:** `scripts/build-loop.sh:1779-1794` (esp. `:1787`), against `skills/dev-cycle/SKILL.md:260-332`, `scripts/dev-cycle.sh:442,490`, `scripts/lib/dev-cycle-read.sh:240-241`
**Move:** 7 (coupling), 2 (responsibility)
**Confidence:** Medium
**Legibility-target:** for-author

The roadmap rule turns three prose facts from SKILL.md step 6 into code:
- the section headings and the preamble never change;
- the Done section is spelled exactly `## Done`;
- briefs are named `docs/working/briefs/[closed/]NAME.md` and moved, never dropped.

SKILL.md does not point back to `--cycle-diff`, and U4 is scheduled to rewrite steps 6–10 (plan step 10). The rule also disagrees with the repo's other readers of the same file:
- dev-cycle.sh finds a section case-insensitively and accepts a suffix (`t == g || index(t, g " ") == 1 || index(t, g "(") == 1`). ROADMAP_AWK requires `sec[1] != "## Done"` byte for byte.
- The lib's `isbrief` pins `YYYY-MM-DD-<slug>.md`. ROADMAP_AWK accepts `[A-Za-z0-9._-]+\.md`.

Every one of these mismatches fails closed. A `## Done (since 2026-10-12)` heading, a new `## In flight` added to an older roadmap, or the dated "first re-checked by the dev cycle" line in the live preamble (`docs/roadmap.md:9-10`) being updated would each refuse the chore commit. So this is an availability coupling, not a laundering path. Its cost lands on U4, as an unexplained `refuse docs/roadmap.md` mid-cycle. The interim reading itself is documented and tested (fact-check Claims 7, 13).

Evidence (verbatim):

```awk
# scripts/build-loop.sh:1787 (in ROADMAP_AWK's line rule, :1782-1789; END :1790-1794 read)
    if (s == 2) named[b] = 1; else if (sec[1] != "## Done") need[b] = 1
```
```bash
# scripts/dev-cycle.sh:490 (in the roadmap counts loop)
    n="$(awk -v h="## $sec" '{ sub(/\r$/, ""); t = tolower($0); g = tolower(h) } t == g || index(t, g " ") == 1 || index(t, g "(") == 1 { on = 1; next } on && /^## / { exit } on && /^([-*] |[0-9]+\. )/ { c++ } END { print c + 0 }' docs/roadmap.md)"
```

**Recommendation:** Match Done the way dev-cycle.sh matches a section (lowercase, then exact, or followed by a space or `(`): a one-line change. Add an override row or plan hand-off naming U4: "step 6's text and --cycle-diff's roadmap rule change together; SKILL.md step 6 names `--cycle-diff`'s three refusals". Leave the looser brief regex; it fails closed, and a short comment saying so is enough.

#### 5. HEALTH_CHECK_LOCK_HELD is one environment seam doing three jobs, and the lock's plain-file test is a by-hand copy of the dispatch lock's

**Severity:** Informational
**Location:** `scripts/health-check.sh:27-29`, `:1094-1121`
**Move:** 7 (coupling), 3 (module boundary)
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

take_lock's structure is sound. flock(1) holds the lock in its own process and re-runs the script as its child with `-o`, so the lock lives exactly as long as the run and no suite inherits the descriptor (fact-check Claims 27, 32). The exported variable does three jobs:
1. it tells flock's child that it already holds the lock;
2. it exempts a nested run (check 5's health-check.bats);
3. any caller can set it.

Job 3 makes it an unconditional bypass of the serialization this unit adds for concurrent orchestrator and loop gates. It also leaks into every suite run under check 5, so any future test of the lock has to `unset` it, as T43 already does at `health-check-lock.bats:16`. The header lists it beside the "test-only seam" variables, which undersells that it changes production behaviour. Separately, the re-run names `$REPO_ROOT/scripts/health-check.sh` instead of `${BASH_SOURCE[0]}`. That is equivalent today, but it is a second spelling of the script's own path. The plain-file test duplicates `build-loop.sh:1919`. Sharing it would make health-check.sh source dev-cycle-read.sh, a new dependency for one line, so the duplication is the right call.

Evidence (verbatim):

```bash
# scripts/health-check.sh:1106-1121 (take_lock, whole)
take_lock() {
    local d lk rc=0
    [[ -z "${HEALTH_CHECK_LOCK_HELD:-}" ]] || return 0
    d="$(git -C "$REPO_ROOT" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)" || return 0
    lk="$d/health-check.lock"
    if [[ -L "$lk" || ( -e "$lk" && ! -f "$lk" ) ]]; then
        red "health-check.lock in $d is not a plain file"; exit 1
    fi
    export HEALTH_CHECK_LOCK_HELD=1
    flock -n -E 75 -o "$lk" bash "$REPO_ROOT/scripts/health-check.sh" "$@" || rc=$?
    if [[ "$rc" -eq 75 ]]; then
        yellow "waiting for another health check in this repository (health-check.lock)"
        rc=0; flock -o "$lk" bash "$REPO_ROOT/scripts/health-check.sh" "$@" || rc=$?
    fi
    exit "$rc"
}
```

**Recommendation:** No change needed in this unit. Optionally, say in the header line that setting the variable skips the lock for that run and everything it starts, and re-run `"${BASH_SOURCE[0]}"`. Each is a one-line edit.

## What Looks Good

- **Row 724 discharged cleanly.** One parser with one acceptance rule (regex plus NUL count) replaces three loops, and each caller keeps its own refusal wording (fact-check Claim 18). The one behaviour change, an unparsed or incomplete chore record now reading as other, moves toward the stricter side.
- **`--cycle-diff` sits in the existing mode dispatch.** It is gated like the other modes (`state_start`, then `state_gate`), with the same `ok` / `refuse PATH: WHY` / exit 2 contract as `--check` and `--main-log`. U4 consumes one more mode of an interface it already parses, not a new one.
- **The fork-point base is the right abstraction.** `git merge-base HEAD MAIN_SHA` judges exactly what the chore branch adds, and keeps step 7's moves of main out of the diff (fact-check Claim 4, mutant m3).
- **Index only, no working-tree reads.** cycle_diff reads only git objects, and the "commit takes the index as is" duty is handed to U4 by override row rather than left implicit.
- **The health-check lock is independent.** It lives in health-check.sh, depends on nothing in the build-loop code, keys on the common git dir (one lock across worktrees, which is the point), and keeps the lock out of the process tree under test.
- **QKEYS_AWK is composed with FENCE_AWK.** It is prepended to the lib's FENCE_AWK rather than re-implementing fences, so one of the grammar's hardest parts is already shared.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | The questions grammar has three readers and four Status parses; the lib's "change both together" names only ANSWERS_AWK; drift fails open | Coupling | `scripts/build-loop.sh:1744-1765`, `scripts/lib/dev-cycle-read.sh:2055-2056` | High |
| 2 | raw_records' six globals are read by index across cycle_diff; cyc_blob's signature hides it | Minor | `scripts/build-loop.sh:967-980`, `:1799-1804` | Medium |
| 3 | A second inline BASE-file reader beside cyc_blob (the source of Claim 15's skip-not-refuse) | Minor | `scripts/build-loop.sh:1840-1844` | Medium |
| 4 | ROADMAP_AWK re-encodes SKILL.md step 6 with no back-pointer; its Done match is stricter than dev-cycle.sh's (fails closed) | Minor | `scripts/build-loop.sh:1787` | Medium |
| 5 | HEALTH_CHECK_LOCK_HELD is marker, exemption and bypass in one; the plain-file test is duplicated (acceptable) | Informational | `scripts/health-check.sh:27-29`, `:1106-1121` | Medium |

Rubric mapping: 1 → 🟡 Must Address; 2–5 → 🟢 Consider.

## Overall Assessment

The change keeps the system's structure intact and improves it in one place: row 724's three raw-listing readers become one. The new mode sits in the existing dispatch with the existing output contract, and the health-check lock is a self-contained, correctly scoped addition. The most important structural concern is Finding 1. The unit closes a laundering path (F42) by adding a third hand-kept copy of the grammar that defines an answer. The copies agree today (fact-check Claim 11), but the cross-reference that is supposed to keep them in step names only two of the three. A future label or heading change made by following that comment would leave --cycle-diff blind to it, and would fail open. That is the same pattern row 724 just retired for `--raw -z`. Every finding can be fixed in place, and together they fit the remaining ~43 lines of the 400-line cap. In priority order:
- Finding 1: the shared awk prelude, about 10–15 lines, or the minimum pointer plus a test, about 5.
- Findings 2 and 3 together: one blob-reader signature, about 8 lines.
- Finding 4: the Done match plus a U4 hand-off row, 1 line of code.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the exact path your tail names, structured per your skill, with a `Commit: <HEAD short sha>` first line.
- Answered: yes. It covers raw_records and its globals, QKEYS_AWK as a third grammar reader (duplication, drift direction, lib placement), ROADMAP_AWK's coupling to SKILL.md step 6, and take_lock's re-run and environment seam.
- Out of scope: correctness of the rules themselves (the fact-check executed them), security exploitability of the HEALTH_CHECK_LOCK_HELD bypass (security-reviewer's), and test wording (fact-check Claim 28).
- Escalate: Finding 1 is 🟡. If it is deferred instead of fixed, its override row should name a revisit trigger at the next edit to ANSWER_AWK's labels or heading rule.
- Decisions I made: rated Finding 1 Coupling rather than Minor because its drift fails open on the property this unit exists to enforce (the alternative was Minor, since today's copies agree). Rated Finding 4 Minor rather than Coupling because every mismatch fails closed.
