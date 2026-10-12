Commit: 1d829fee

# Architecture Review — feat/build-loop-u3b2 (iteration 1)

**Scope:** branch diff `main...HEAD` (main b5f21758, HEAD 1d829fee): `scripts/build-loop.sh` (`--main-log`, `gate_msg`, `ANSWERS_AWK`, `log_class`, `main_log`), read against `scripts/lib/dev-cycle-read.sh`, `scripts/dev-cycle.sh`, `skills/dev-cycle/SKILL.md` and the plan's U3b2 bullet
**Date:** 2026-10-12
**Based on:** `docs/reviews/code-fact-check-report-2026-10-12-u3b2-i1.md` (31 claims: 24 verified, 7 mostly accurate, 0 stale or incorrect)

Scope check: in scope. The diff adds a public CLI mode (`--main-log SINCE`, its output lines and exit contract), a persisted-data contract read from history (the gate merge message, the chore subject and the cycle record's `Branch:` line, the questions-file answer grammar) and a shared writer/reader definition (`gate_msg`).

Trust-boundary cross-reference: the most recent security review on disk is `docs/reviews/security-review-2026-10-09-u2b3b2c-i1.md` (Commit: `f7e1bea2`), which predates this diff; no security review for this commit exists yet. None of the findings below recommends moving a gate_git / real-repository crossing, so the cross-reference has nothing to constrain.

## Dependency Map

- `main-log` dispatch (`scripts/build-loop.sh:1679-1682`) → `state_start` (`:1210-1216`: default_gate, mktemp, gate_repo, `store_check --main`) → `main_log` (`:1657-1668`) → `log_class` (`:1618-1656`) per first-parent commit.
- `log_class` → `gate_git` only (every read in the gate repository) → `gate_msg` (`:1358-1364`, gate class) and `ANSWERS_AWK` (`:1589-1613`, answers class).
- `land` (`:1448`) → `gate_msg`: one writer and one reader of the merge message, both in `build-loop.sh`.
- Implicit (textual, not code) dependencies: `ANSWERS_AWK` restates the answer-label and `**Needs:**`/`**Status:**` grammar owned by the lib's `ANSWER_AWK` (`scripts/lib/dev-cycle-read.sh:2046-2056`); the chore rule restates the cycle-record path owned by the lib's `writable` (`dev-cycle-read.sh:245`) and `dev-cycle.sh:217`; the chore rule's `Branch: B` line and `--no-ff` landing are a forward contract on U4 (`skills/dev-cycle/SKILL.md` step 7, not yet changed).

Direction is sound: the new mode depends on existing stable pieces (gate_git, state_start, the lib), and nothing existing depends on it except `land`'s move onto `gate_msg`, which is byte-identical (fact-check Claim 21).

## Findings

#### 1. The answers grammar is defined twice, in two files

**Severity:** Minor
**Location:** `scripts/build-loop.sh:1594-1613`; `scripts/lib/dev-cycle-read.sh:2046-2056`
**Move:** 3 (module boundary), 7 (coupling surface)
**Confidence:** High
**Legibility-target:** a maintainer changing `--check-answer`'s labels in the lib, who has no pointer to `ANSWERS_AWK` in build-loop.sh

Evidence (verbatim):
- `scripts/build-loop.sh:1609`: `  if (t ~ /^Q-[0123456789]+:/ || tolower(t) ~ /^\*\*answer(:|ed| \()/) next`
- `scripts/build-loop.sh:1597`: `  for (i = 1; i <= n; i++) { f = fld[i]; t = f; sub(/^[ \t]+/, "", t); if (substr(t, 1, 12) == "**Status:** ") f = "**Status:**"; o = o (i > 1 ? " · " : "") f }`
- `scripts/lib/dev-cycle-read.sh:2056`: `  if (low !~ /^\*\*answer(:|ed| \()/) next`
- `scripts/lib/dev-cycle-read.sh:2048`: `  for (i = 1; i <= n; i++) { f = fld[i]; sub(/^[ \t]+/, "", f); if (substr(f, 1, 12) == "**Status:** ") v = substr(f, 13) }`

The help text promises the labels are "--check-answer's labels" (`build-loop.sh:160`), but they are a second literal in another file, and the lib's comment block for ANSWER_AWK names no second reader. The questions-file grammar (fences, headers, answer labels) is otherwise owned by the lib, which already exports reusable awk fragments composed by string concatenation (`"$FENCE_AWK$ANSWER_AWK"`, `dev-cycle-read.sh:2099`). Drift direction: if the lib widens its labels, honest answer commits read as `other` (fails closed, but each costs a `you: judgment` entry, the attention budget the row-719 strictness note already counts); if it narrows them, `--main-log` keeps passing lines `--check-answer` no longer treats as answers (benign: still only the questions files). Same shape as the BODY_RULE two-literals row (override-log, U3b1 final architecture 3), deferred there.

**Recommendation:** Move the two shared pieces into the lib as awk functions (e.g. `isanswer(l)` and the Status-blind `needs(l)`) in a fragment both `ANSWER_AWK` and `ANSWERS_AWK` prepend, the way `FENCE_AWK` is shared; or, at minimum, a one-line comment at `dev-cycle-read.sh:2056` naming `ANSWERS_AWK` as a dependent reader.

#### 2. Three hand-rolled readers of `diff-tree --raw -z`, each with its own strictness

**Severity:** Minor
**Location:** `scripts/build-loop.sh:1266-1277` (check_line), `:1635-1640` (log_class chore), `:1642-1649` (log_class answers)
**Move:** 8 (extension points), 7
**Confidence:** High
**Legibility-target:** the next reviewer who hardens the raw-record reader (as the NUL-count check was added in an earlier unit) and must find every copy

Evidence (verbatim):
- `:1266`: `  if ! gate_git diff-tree -r --no-renames --raw -z --ignore-submodules=none "$MAIN_SHA" "$tree" > "$GATE_TMP/diff"; then`
- `:1269-1270`: `    [[ "$meta" =~ ^:([01234567]{6})\ ([01234567]{6})\ [0123456789abcdef]+\ ([0123456789abcdef]+)\ ([AMDT])$ ]] \` / `      || { echo "refuse $a: the paths the merge of $br changes could not be read"; return; }`
- `:1277`: `  if [[ "$(tr -cd '\000' < "$GATE_TMP/diff" | wc -c)" -ne $((2 * ${#ps[@]})) ]]; then echo "refuse $a: the paths the merge of $br changes could not be read"; return; fi`
- `:1637`: `      [[ "$p" =~ ^docs/working/cycles/cycle-[^/]+\.md$ && "$meta" =~ ^:[01234567]{6}\ 100644\ [0123456789abcdef]+\ ([0123456789abcdef]+)\ [AM]$ ]] || continue`
- `:1649`: `    [[ "$x" -gt 0 && "$(tr -cd '\000' < "$GATE_TMP/d" | wc -c)" -eq $((2 * x)) ]] || return 0`

check_line refuses an unparsed record and counts NULs; the answers loop returns `other` on an unmatched record and counts NULs; the chore loop skips unmatched records (`continue`) and does not count NULs; only check_line passes `--ignore-submodules=none`. Each is correct for its purpose today (the chore loop looks for one positive match, and `read -d ''` never processes a trailing partial record; the gate repository has no config or `.gitmodules` to hide a gitlink), so this is not a defect. The cost is structural: the record grammar and the "every record read whole" invariant (`:1275-1276` comment, restated at `:1648`) now live in three places, so a future hardening of the reader lands in one and is missed in the others, and each reader has to re-argue why its omission is safe.

**Recommendation:** Extract one `raw_records FROM TO` helper that runs the diff-tree (one flag set), fills parallel arrays (old mode, new mode, new id, status, path) and returns 1 on any unread record or NUL-count mismatch; check_line and both log_class branches then apply only their own filters. Not urgent under the 400-line cap; a fit for the U3b3 / U3c lib work.

#### 3. The cycle-record name is defined three ways, and the reader is the widest

**Severity:** Minor
**Location:** `scripts/build-loop.sh:1637`; `scripts/lib/dev-cycle-read.sh:245`; `scripts/dev-cycle.sh:217`
**Move:** 7, 3 (data contract)
**Confidence:** Medium
**Legibility-target:** U4's author, who writes the record and the `Branch:` line and needs one place that says what a record is

Evidence (verbatim):
- `scripts/build-loop.sh:1637`: `      [[ "$p" =~ ^docs/working/cycles/cycle-[^/]+\.md$ && ...` (excerpt; the line continues with the meta regex quoted in finding 2)
- `scripts/lib/dev-cycle-read.sh:245`: `    || "$1" =~ ^docs/working/cycles/cycle-$DIGIT{4}-$DIGIT{2}-$DIGIT{2}\.md$ ]] || anybrief "$1"`
- `scripts/dev-cycle.sh:217`: `  for f in docs/working/cycles/cycle-[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9].md; do`
- `skills/dev-cycle/SKILL.md:362`: ``Write `docs/working/cycles/cycle-YYYY-MM-DD.md` (if one exists for today, update it in place):``

The writer's contract (writable, the digest's glob, the skill) is `cycle-YYYY-MM-DD.md`; `--main-log` accepts any `cycle-*.md`. Under the honest-slip threat model the wider pattern lets nothing dangerous through, but it is a third spelling of one data-model fact, and it is the one the next change is least likely to find. Related contract shape U4 inherits: with one branch per iteration (`chore/dev-cycle-<date>-<HHMM>`, plan line 99) and one record per day updated in place (SKILL.md:362), the record accumulates one `Branch:` line per iteration; the reader's "the line anywhere in the post-merge file" rule handles that, but neither the help text nor override row 719 says so, and U4 has to infer it.

**Recommendation:** Add an `isrecord` predicate beside `isbrief` in the lib (`DIGIT` is already there), use it in `writable` and log_class (dev-cycle.sh's glob can stay, as it lists files). In the row-719 hand-off, add one clause: a day's record holds one `Branch:` line per landed iteration.

#### 4. gate_msg is one byte definition, but the reader carries a second copy of the message's shape

**Severity:** Informational
**Location:** `scripts/build-loop.sh:1358-1364`, `:1626-1632`
**Move:** 7, 3 (persisted contract)
**Confidence:** High
**Legibility-target:** whoever next changes the merge message (a new trailer, a third authority), who edits gate_msg and must know log_class parses its shape

Evidence (verbatim):
- `:1361-1364`: `gate_msg() {` / `  printf "Merge branch '%s' (build-loop %s)\n\nBuild-loop-gate: %s\n" "$1" "$2" "$3"` / `  [[ -z "${4-}" ]] || printf 'Build-loop-approved: %s\n' "$4"` / `}`
- `:1626`: `  if [[ ${#ps[@]} -eq 2 && "$SUBJ" =~ ^Merge\ branch\ \'(.+)\'\ \(build-loop\ (self-merge|approved merge)\)$ ]]; then`
- `:1628`: `    [[ "${m[2]-}" =~ ^Build-loop-gate:\ (.+)$ ]] || return 0`
- `:1631`: `    if [[ "$x" != self-merge ]]; then [[ "${m[3]-}" =~ ^Build-loop-approved:\ (Q-[0123456789]+)$ ]] || return 0; q="${BASH_REMATCH[1]}"; fi`

Row 662's discharge holds (fact-check Claims 1, 20, 21): the bytes compared are gate_msg's own output, so no forged variant of the format passes. But log_class must first recover gate_msg's arguments, so the subject template, the WHAT vocabulary, the line positions (`m[2]`, `m[3]`) and the approval-id shape are a second encoding of the format. Drift fails closed and loud (an honest `--merge` reads as `other`; orchestrator test 9 asserts a real `--merge` reads as gate). One consequence is worth naming: the message is persisted in history, so any change to gate_msg turns every older-format gate merge still inside the SINCE window into `other` for one iteration after the upgrade.

**Recommendation:** Extend the gate_msg comment (`:1358-1360`) to name log_class as the parser of its shape and to note the one-iteration reclassification on a format change; optionally move the parse into a `gate_msg_args` function directly below gate_msg so the pair reads as one unit. No code change needed for this unit.

#### 5. On this repository's current practice, every main commit reads `other`

**Severity:** Informational
**Location:** `scripts/build-loop.sh:1657-1668`; contract with U4 (D13, F43)
**Move:** 1 (what depends on this output)
**Confidence:** Medium
**Legibility-target:** U4's author deciding what the orchestrator does on `other`

Evidence (probe, `/tmp/u3b2rv-arch-XXXX`, a `--no-local` clone of /workspace with `GIT_CONFIG_GLOBAL=/dev/null`, `--main-log` from `HEAD~5`; temp dir removed): output `main b5f217586906fc9f30c1d4d8499ede99769cf28f 5`, then five `other` lines, including `other ef7a1122f9a29cc44547a5f88d1dc8dd5b40d65b Merge branch 'feat/build-loop-u3b1': --state checks ...` and `other b5f217586906fc9f30c1d4d8499ede99769cf28f docs(checkpoint, questions): U3b1 merged at ef7a1122 ...`.

This is the rule working as designed (hand merges and checkpoint commits are neither gate, chore nor answers), and override row 720 already records the answers-class false positives. It is broader than that row, though: any human-session landing while a loop runs (the local-merge practice here) stops dispatch. That is a property of the contract between `--main-log` and U4, not of this unit's code.

**Recommendation:** None for U3b2. U4 should decide, and write into the skill, whether a run of `other` from human sessions files one judgment entry per iteration or one per SHA, so a busy day does not spend the attention budget N times.

## What Looks Good

- **Placement.** `gate_msg` sits directly above `land`, its writer; `ANSWERS_AWK`, `log_class` and `main_log` sit together just above the dispatch `case`, as the other modes' code does. The one module-boundary question (finding 1) is about the answer grammar, not about where the mode lives.
- **Every read through gate_git.** All six git calls in log_class/main_log go through the gate repository (fact-check Claim 5), so the new reader inherits the existing no-repo-config, no-checkout-attributes boundary instead of reinventing it.
- **No caller input for chore.** Reading the branch name from the merge's own record removes a second input channel (and a live-branch dependency) from the orchestrator contract; the cost is the forward contract on U4, already recorded as a Coupling-tagged row (719).
- **Gated by default, startup right-sized.** `--main-log` takes the GATED path without a special case (`GATED=""; [[ "$MODE" =~ ^(settings|status|marker)$ ]] || GATED=1`, `:619`) and reuses `state_start` whole rather than a trimmed variant. Measured on the clone above: `--state` 0.437 s, `--main-log` (5 commits) 0.484 s total, so repeating main's re-hash after the iteration's `--state` costs little and keeps one startup path.
- **Fail-closed shape.** `CLASS=other` is the default and every failed read is `return 0` before any class is set; exit 2 for both `other` and `refuse` keeps U4's branch simple while the first line (`main` vs `refuse main-log:`) still distinguishes them.
- **Globals pattern.** `CLASS`/`SUBJ` follow the script's existing out-variable convention (`VERDICT`, `STATUS`, `MERGE_WHY`).

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Answers grammar defined twice (ANSWERS_AWK vs lib ANSWER_AWK) | Minor | `scripts/build-loop.sh:1594-1613`, `scripts/lib/dev-cycle-read.sh:2046-2056` | High |
| 2 | Three raw diff-tree readers with differing strictness | Minor | `scripts/build-loop.sh:1266-1277`, `:1635-1640`, `:1642-1649` | High |
| 3 | Cycle-record name defined three ways; reader widest; `Branch:` accumulation unstated | Minor | `scripts/build-loop.sh:1637`, `scripts/lib/dev-cycle-read.sh:245`, `scripts/dev-cycle.sh:217` | Medium |
| 4 | gate_msg's shape re-encoded in the reader's parse; format change reclassifies in-window history | Informational | `scripts/build-loop.sh:1358-1364`, `:1626-1632` | High |
| 5 | Human-session landings all read `other`; U4 must budget its response | Informational | `scripts/build-loop.sh:1657-1668` | Medium |

## Overall Assessment

The change keeps the script's structure intact: the new mode depends only on existing stable pieces (state_start, gate_git, the lib), runs gated by default, and turns the merge message into one byte-level definition shared by its writer and reader, which discharges row 662. No Structural or Coupling findings. The three Minor findings share one cause: facts owned elsewhere (the lib's answer grammar, the record's name, the raw-diff record grammar) are restated locally rather than imported. Each restatement fails closed today, so all are fixable in place, and the lib extraction work already planned for U3b3 is the natural home. The most important item is finding 1, because a lib label change would otherwise silently turn honest answer commits into judgment entries.

## Goal-Alignment Note

Success criterion: "An architecture review saved to docs/reviews/architecture-review-2026-10-12-u3b2-i1.md in the worktree, per the architecture-review skill." Met: saved at that path with `Commit: 1d829fee` first, scope check, dependency map, five findings (every one with severity, location, move, confidence, verbatim evidence and a Legibility-target), what looks good, summary table and overall assessment. Every focus area in the brief is covered: gate_msg as one definition (finding 4), the answers-rule duplication (finding 1), diff parsing versus check_line (finding 2), the U4 data contract (findings 3 and 5; the --no-ff and `Branch:` requirements are already in row 719 and are not re-filed), state_start sizing and placement (What Looks Good, with a timing). The recorded override rows (662 discharge, 719, 720, 721) were not re-filed. One probe ran under `/tmp/u3b2rv-arch-`, under `timeout`, and its directory was removed. Nothing in the worktree was written but this file.
