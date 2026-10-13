Commit: ec9dace7

# Code Fact-Check Report

**Repository:** /workspace (worktree /workspace/.claude/wt-build-loop-u3c, branch feat/build-loop-u3c)
**Scope:** `git diff main...HEAD` (main = dafc0e74, HEAD = ec9dace7): scripts/build-loop.sh, scripts/health-check.sh, scripts/lib/dev-cycle-read.sh, test/scripts/build-loop-orchestrator.bats, test/scripts/health-check-lock.bats, docs/working/plan-build-loop-handoff.md (U3c lines), docs/reviews/override-log.md (the eight rows dated 2026-10-12 for this branch), and the bodies of commits 6f347256, 3021d0a4, f34fceb0, 414c9295, d77dae74, ec9dace7. Review-report files under docs/reviews are context only.
**Checked:** 2026-10-12
**Replication:** replicate of k=3 (agent tag fc-u3c-final-r2)
**Total claims checked:** 34
**Summary:** 28 verified, 4 mostly accurate, 0 stale, 1 incorrect, 1 unverifiable

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`, five entries: corpus sizes, golden counts, test tallies, a consumer reference, a suite count). No claim below matches a logged pattern; claim 32b (a git behaviour stated as the reason for a code choice) is the nearest kind, but it names no made-up symbol, so it is not a log entry.

**Execution provenance.** The brief allows this agent to write only its report file in the repo, so captured output lives in the agent's scratch dir rather than `docs/reviews/execution-logs/`. All of it is under `/tmp/claude-1000/-workspace/f335f5f6-1b17-4519-891d-602641cba507/scratchpad/fc-u3c-final-r2/`:
- E1, `logs/orch.txt` and `logs/lock.txt`. Command: `TMPDIR=$(mktemp -d /tmp/u3c-fc-u3c-final-r2-XXXX) bats test/scripts/build-loop-orchestrator.bats`, then `bats test/scripts/health-check-lock.bats`, serially. Cwd: the worktree. Exit 0 and 0. Time: 2026-10-13T06:07:03Z (UTC; the local date is 2026-10-12). All 24 orchestrator tests pass, and both T43 tests pass.
- E2, `logs/probe1.txt`. Command: `bash probe1.sh`, with fixture repos under its own `p-XXXX` mktemp dir. Cwd: the scratch dir. Exit 0. Time: 2026-10-13T06:10:54Z. It holds probes P1-P12, listed below.
- E3, `logs/probe2.txt`. Command: `bash probe2.sh`, which runs diff-tree with pathspecs in a gate-shaped repository. Exit 0. Time: 2026-10-13T06:11:16Z. git is 2.39.5.
- E4, `logs/probe3.txt`. Command: `bash probe3.sh`, mutants run on copies of the worktree's scripts/ and test/ in the scratch dir. Exit 0. Time: 2026-10-13T06:11:42Z.
- E5, `logs/bl-check.txt`, `logs/bl-merge.txt` and `logs/bl-read.txt`. Command: `bats test/scripts/build-loop-{check,merge,read}.bats` with a fresh TMPDIR, serially. Cwd: the worktree. All exit 0, with 146, 12 and 20 tests ok. Time: 2026-10-13T06:13:36Z.
- The probe scripts themselves are `probe1.sh`, `probe2.sh` and `probe3.sh` in the same dir.

---

## Claim 1: "Re-keys row 722 ...: --cycle-diff judges only the questions files, the roadmap and the idea log; every other staged path is not judged"

**Location:** `docs/reviews/override-log.md:745`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the path dispatch in cycle_diff. It does not establish that a mode or 100644 check applies to other paths (none does), and it does not cover the state gate that runs before cycle_diff.

The path switch sends only the four cycle files on and `continue`s everything else:
```bash
# scripts/build-loop.sh:1813-1817
    case "$p" in
      docs/working/questions.md|docs/working/questions-archive.md) qi+=("$i"); continue ;;
      docs/roadmap.md|docs/working/idea-log.md) ;;
      *) continue ;;
    esac
```
(excerpt ends :1817; enclosing cycle_diff continues to :1867 — read)

**Evidence:** `scripts/build-loop.sh:1803-1867`

---

## Claim 2: "Row 724 discharged: one `raw_records` reads every `--raw -z` listing whole (check_line, log_class's chore and answers loops, --cycle-diff) ... Equivalent to the three old readers, but log_class's chore loop now reads a commit with an unparsed or incomplete record as other instead of skipping the record"

**Location:** `docs/reviews/override-log.md:746`; also commit f34fceb0's body and the plan at `docs/working/plan-build-loop-handoff.md:331`
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that every `--raw -z` call site in build-loop.sh, the lib and dev-cycle.sh now feeds raw_records. It also covers that acceptance matches each old loop byte for byte: for check_line (same refusal text, same rule for a half record or trailing bytes) and for the answers loop (at least one record, every record `100644 100644 M` on a questions path), with the single stated change in the chore loop. It does not establish timing, beyond confirming that raw_records forks nothing.

A grep for `--raw` (`paraphrased — no quote available because the claim covers absence of code: a grep over scripts/build-loop.sh, scripts/lib/dev-cycle-read.sh and scripts/dev-cycle.sh`) finds four listings: `:1312` (check_line), `:1701` (chore), `:1708` (answers) and `:1807` (cycle_diff). The first three are gate_git diff-tree calls; the fourth is the checkout's git diff-index. Each one goes through raw_records:
```bash
# scripts/build-loop.sh:972-981
raw_records() {
  local meta p
  RAW_OM=(); RAW_NM=(); RAW_OO=(); RAW_NO=(); RAW_S=(); RAW_P=()
  while IFS= read -r -d '' meta; do
    IFS= read -r -d '' p || return 1
    [[ "$meta" =~ ^:([01234567]{6})\ ([01234567]{6})\ ([0123456789abcdef]+)\ ([0123456789abcdef]+)\ ([AMDT])$ ]] || return 1
    ...
  done < "$1"
}
```
Each old reader against the new one:
- **check_line.** The old loop refused an unparsed meta, and also refused when the NUL count was not two per record, which happens with a half record. The new code returns 1 for both, and check_line prints the unchanged text `refuse $a: the paths the merge of $br changes could not be read` (`scripts/build-loop.sh:1315`). Trailing bytes after the last NUL are accepted by both.
- **Answers loop.** The old loop needed every record to match `^:100644\ 100644\ ...\ M$` on a questions path, x>0, and the NUL count; the new one has the same predicates (`:1708-1711`).
- **Chore loop.** The old loop `continue`d past an unparsed record. The new one returns CLASS other, through `raw_records "$GATE_TMP/d" || return 0` (`:1701`), which is the stated change.

The full check, merge, read and orchestrator suites pass on HEAD (E1, E5).

**Evidence:** `scripts/build-loop.sh:965-981`, `scripts/build-loop.sh:1312-1317`, `scripts/build-loop.sh:1687-1716`, `scripts/build-loop.sh:1807-1809`, logs/bl-check.txt, logs/bl-merge.txt, logs/bl-read.txt, logs/orch.txt

---

## Claim 3: "The orchestrator's chore commit must take the index as --cycle-diff read it ... --cycle-diff reads the index only"

**Location:** `docs/reviews/override-log.md:747`; `docs/working/plan-build-loop-handoff.md:329`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the fact that cycle_diff reads only the index (diff-index --cached) and never the work tree. The U4 duty itself is not yet built, so it is not verified here.

```bash
# scripts/build-loop.sh:1807
  if ! git diff-index --cached --raw -z --no-renames --ignore-submodules=none "$base" > "$t.raw" 2>"$GATE_TMP/err" \
```
(excerpt ends :1807; the condition continues to :1810 — read) Blobs are then read by id through cyc_blob, which uses gate_git cat-file (`:1798-1801`). No work-tree file is opened.

**Evidence:** `scripts/build-loop.sh:1798-1810`

---

## Claim 4: "`--answered` is the orchestrator's own claim and is never recorded: any ID it lists may be flipped, rewritten or filed answered"

**Location:** `docs/reviews/override-log.md:748`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the fact that ANSWERED feeds QDIFF_AWK's `ok[]` exemption and nothing else, with no output naming the listed IDs. It does not cover U4's future recording.

The IDs are only appended (`ANSWERED+=("$2")`, `scripts/build-loop.sh:491`) and then passed as `-v ids="${ANSWERED[*]}"` (`:1859`). In QDIFF_AWK, `!(id in ok)` guards both the gone and the new refusal (`:1770-1771`). On success the only output is `echo ok` (`:1885`).

**Evidence:** `scripts/build-loop.sh:486-491`, `scripts/build-loop.sh:1758-1775`, `scripts/build-loop.sh:1859`, `scripts/build-loop.sh:1882-1886`

---

## Claim 5: "The orchestrator's commit runs the common dir's hooks after --cycle-diff passed; a planted pre-commit hook could re-stage files"

**Location:** `docs/reviews/override-log.md:749`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the fact that --cycle-diff neither commits nor pins the tree it checked, so whatever `git commit` does afterwards, hooks included, happens outside it. It does not establish U4's commit command (not built). That a pre-commit hook can change what gets committed is git's documented behaviour; it was not re-executed here.

cycle_diff ends with `return "$bad"` (`scripts/build-loop.sh:1866`), and the mode prints `ok` (`:1885`) without recording a tree id (`paraphrased — no quote available because the claim covers absence of code: no write-tree or tree output in cycle_diff or the mode's case arm`).

**Evidence:** `scripts/build-loop.sh:1803-1867`, `scripts/build-loop.sh:1882-1886`

---

## Claim 6: "health-check.sh's wait for the lock is unbounded ...; a FIFO swapped in between the plain-file test and flock's open hangs instead of refusing; flock missing exits with flock's own status ... every failure exits non-zero"

**Location:** `docs/reviews/override-log.md:750`
**Type:** Behavioral / Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the unbounded wait (the second flock has no `-w`), the window between the type test and the open, and the non-zero exit when flock is missing. It does not establish the FIFO hang by execution (only the type test's refusal was executed, in T43).

```bash
# scripts/health-check.sh:1109-1118
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
```
There is no `-w` timeout, so the wait is unbounded. The type test and flock's own open are separate steps. The imprecision is in "exits with flock's own status": when flock is absent, bash itself returns 127 (command not found), `rc=127`, and the script exits 127. That is non-zero, so "every failure exits non-zero" holds, but the status is bash's, not one flock produces.

**Evidence:** `scripts/health-check.sh:1104-1119`

---

## Claim 7: "the live roadmap's preamble holds a dated 're-checked' line ...; the rule copies SKILL.md step 6's prose, which does not point back to it ... the Done match now follows dev-cycle.sh"

**Location:** `docs/reviews/override-log.md:751`; commit ec9dace7 ("B5: Done is matched as dev-cycle.sh matches a section")
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the live preamble's text, SKILL.md step 6 having no --cycle-diff pointer, and the Done-heading predicate matching dev-cycle.sh's section predicate. It does not establish that either predicate accepts a tab after "Done": neither does, since the "blank" in the header means a space.

The live preamble (`docs/roadmap.md:9-10`) reads: "Seeded 2026-09-29 by hand; first re-checked by the dev cycle on 2026-10-02". The roadmap rule's Done test is:
```awk
# scripts/build-loop.sh:1781
/^## / { h[s] = h[s] "\n" $0; d = tolower($0); done[s] = (d == "## done" || index(d, "## done ") == 1 || index(d, "## done(") == 1); in2[s] = 1; next }
```
dev-cycle.sh's section matcher is `t == g || index(t, g " ") == 1 || index(t, g "(") == 1`, with `g = tolower(h)` (`scripts/dev-cycle.sh:490`), which is the same predicate. A grep for `cycle-diff` in `skills/dev-cycle/SKILL.md` finds nothing (`paraphrased — no quote available because the claim covers absence of a match`).

**Evidence:** `docs/roadmap.md:9-10`, `scripts/build-loop.sh:1779-1794`, `scripts/dev-cycle.sh:490`, `skills/dev-cycle/SKILL.md:260-330`

---

## Claim 8: "--cycle-diff now refuses a questions change while main has changed the questions files since the fork point" (also plan :104, :328 "As reviewed", header :197-200, ec9dace7 B1)

**Location:** `docs/reviews/override-log.md:752`; `docs/working/plan-build-loop-handoff.md:104`; `docs/working/plan-build-loop-handoff.md:328`; `scripts/build-loop.sh:197-200`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers changes on main to either questions file, the archive alone included, when the index changes a questions file; and the no-refusal case when the index leaves both files untouched. It does not establish anything about a main that moves after the check (U4's compare-and-swap), and it does not apply this guard to the roadmap or the idea log, which have none (see Escalations).

```bash
# scripts/build-loop.sh:1830-1837
  [[ ${#qi[@]} -gt 0 ]] || return "$bad"
  ...
  if ! gate_git ls-tree -z "$base" -- docs/working/questions.md docs/working/questions-archive.md > "$t.lb" \
    || ! gate_git ls-tree -z "$MAIN_SHA" -- docs/working/questions.md docs/working/questions-archive.md > "$t.lm" || ! cmp -s "$t.lb" "$t.lm"; then
    echo "refuse docs/working/questions.md: the default branch changed the questions files since the fork point $base, ..."; return 1
```
(excerpt ends :1837; enclosing cycle_diff continues to :1867 — read)

Executed results:
- P2: main changed only the archive and the index changed questions.md. Result: refused, exit 2.
- P3: main changed questions.md and the index did not touch it. Result: ok.
- T38 at `test/scripts/build-loop-orchestrator.bats:428` passes.
- Mutant B (the cmp test removed) fails T38 at that line (E4), which confirms "red without the rule".

**Evidence:** `scripts/build-loop.sh:1830-1837`, logs/probe1.txt (P2, P3), logs/probe3.txt (mutant B), logs/orch.txt

---

## Claim 9: "`--cycle-diff [--answered Q-…]` → `ok`, or `refuse PATH: why` (exit 2); run in the orchestrator's worktree against the fork point of HEAD and `MAIN_SHA`"

**Location:** `docs/working/plan-build-loop-handoff.md:209`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the output shape and the base. It does not cover state-gate refusals, which print `refuse state ...` lines, also with exit 2; those are documented in the Exit paragraph (claim 18).

The mode arm is `state_start; cycle_diff || exit 2; echo ok` (`scripts/build-loop.sh:1882-1886`), and the base is `git merge-base HEAD "$MAIN_SHA"` (`:1805`). T38 asserts these exact lines and statuses (E1).

**Evidence:** `scripts/build-loop.sh:1805`, `scripts/build-loop.sh:1882-1886`, logs/orch.txt

---

## Claim 10: "the index is compared with `git merge-base HEAD MAIN_SHA` (MAIN_SHA itself when main has not moved). That is exactly what the chore branch adds when it lands, its earlier commits included ... No merge base (HEAD unborn or unrelated) refuses."

**Location:** `docs/working/plan-build-loop-handoff.md:328`; the header at `scripts/build-loop.sh:185-189`; commit 6f347256 and f34fceb0 Notes
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers an unborn HEAD, an unrelated committed HEAD, earlier commits on the chore branch, a detached HEAD, and HEAD being main itself. It does not establish criss-cross histories (git merge-base prints one of several bases) or BASE's object integrity, which is documented as not re-hashed at `:212`.

`if ! base="$(git merge-base HEAD "$MAIN_SHA" 2>/dev/null)"; then echo "refuse HEAD: ..."; return 1; fi` (`scripts/build-loop.sh:1805`). Executed results:
- P4 (an unrelated committed root): `refuse HEAD`.
- T38's orphan case (unborn HEAD) refuses.
- P5: an ANSWERED flip committed earlier on the chore branch, with nothing staged, is refused (Q-001).
- P6: the same with a detached HEAD is refused.
- P7: HEAD on main with a staged flip is refused.
- Mutant A (base = MAIN_SHA) fails T38 at the main-moved line (`build-loop-orchestrator.bats:426`, E4), as commit 3021d0a4 says.

**Evidence:** `scripts/build-loop.sh:1803-1810`, logs/probe1.txt (P4-P7), logs/probe3.txt (mutant A)

---

## Claim 11: "Questions rule ...: over both questions files together (an archive move is no change), each entry as `--check-answer` delimits it (FENCE_AWK first; a refused file refuses), its key lines are its heading, its `**Needs:**` lines and its answer lines (ANSWERS_AWK's labels, any ID). An entry on the base whose key lines differ in the index, or that is gone, refuses unless its ID is in `--answered`; a new entry is free unless it is filed answered"

**Location:** `docs/working/plan-build-loop-handoff.md:330`; the header at `scripts/build-loop.sh:190-197`; commits f34fceb0 and d77dae74
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers parity of entry delimitation and key-line selection with the lib's ANSWER_AWK: the heading match, the entry ending at any `#`/`##`/`###` heading, fenced lines skipped, the first Needs line read by check_answer being a subset of all Needs lines keyed, answer lines (`Q-NNN:` or a bold Answer label, after an optional `- `) for any ID, CR stripping, and duplicate IDs (concatenated, so any change refuses). It does not establish parity for ANSWER_AWK's two whole-file skips that QKEYS_AWK lacks, `quoted` (a `### Q-` heading inside a fence) and `dup`; see the residue under Escalations. It also does not establish parity for a heading form outside `### Q-<digits>`.

```awk
# scripts/build-loop.sh:1744-1751
{ sub(/\r$/, "") }
fence($0) { next }
/^### Q-[0123456789]+([ \t]|$)/ { id = substr($0, 5); sub(/[ \t].*/, "", id); print id "\t" f "\th\t" $0; next }
/^(#|##|###) / { id = ""; next }
id == "" { next }
/^\*\*Needs:\*\*/ { print id "\t" f "\tn\t" $0; next }
{ t = $0; sub(/^- /, "", t); if (t ~ /^Q-[0123456789]+:/ || tolower(t) ~ /^\*\*answer(:|ed| \()/) print id "\t" f "\ta\t" $0 }
END { if (odd) print "odd " odd " " oddwhy; else if (infence) print "unbalanced " fline }'
```
The lib's reader has the same shapes: `heading()` accepts `h == id || index(h, id " ") == 1 || index(h, id "\t") == 1`; then `/^(#|##|###) / { inside = 0; next }`; then `!header && /^\*\*Needs:\*\*/`; and the answer test `index(line, id ":") == 1` or `low !~ /^\*\*answer(:|ed| \()/` after `sub(/^- /, "", line)` (`scripts/lib/dev-cycle-read.sh:2076-2108`, read to `:2116`).

Because check_answer can read keep only through an answer line, and QKEYS tags every such line with `a`, a keep answer that is new or moved changes the entry's key-line string. A new answered entry trips `answered()` through `k == "a"` (`:1760`).

Executed cases:
- T38 cases all pass (E1).
- P1: the unchanged archive is read on both sides. A dup heading of archived Q-000, added to questions.md only, is refused as `Q-000 ... gone` against the archive.
- P10: `- **answered** keep` in a new entry is refused as filed answered.
- P11: `--answered Q-001` does not exempt `Q-1`.

**Evidence:** `scripts/build-loop.sh:1736-1775`, `scripts/build-loop.sh:1838-1866`, `scripts/lib/dev-cycle-read.sh:2061-2116`, logs/probe1.txt (P1, P10, P11), logs/orch.txt

---

## Claim 12: "Roadmap and idea log ...: the idea log edited other than by appending (the base's bytes must be a prefix of the index's ...); the roadmap's lines above its first `## ` heading, or its `## ` heading lines, changed; a brief file name a roadmap line outside Done names on the base that no line names in the index (check 1 moves a brief's line to Done or Ideas and points it at `closed/`; it never drops one)"

**Location:** `docs/working/plan-build-loop-handoff.md:331`; the header at `scripts/build-loop.sh:200-209`; commit f34fceb0
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three roadmap refusals, the Done exemption (by heading on the base), matching brief names by basename so that a `closed/` move counts as named, and the idea-log prefix test through `cmp -n`. It does not establish that a brief named only on a `## ` heading line or in the preamble is tracked (it is not; both are frozen instead). It also does not cover CR-only edits, which are invisible because `sub(/\r$/, "")` runs first.

```bash
# scripts/build-loop.sh:1823-1824
      k="$(wc -c < "$t.o")"
      [[ "$(wc -c < "$t.n")" -ge "$k" ]] && cmp -s -n "$k" "$t.o" "$t.n" || { echo "refuse $p: edited other than by appending"; bad=1; }
```
ROADMAP_AWK collects names with `match(r, /docs\/working\/briefs\/(closed\/)?[A-Za-z0-9._-]+\.md/)`, strips them to the basename, and records `need[b]` only when `!done[1]` (`:1785-1788`). SKILL.md step 6 check 1 says to "`git mv` the brief there (same file name ...) and point the roadmap line there" (`skills/dev-cycle/SKILL.md:290-293`). T38's roadmap test passes (E1).

**Evidence:** `scripts/build-loop.sh:1779-1794`, `scripts/build-loop.sh:1820-1828`, `skills/dev-cycle/SKILL.md:280-293`, `skills/dev-cycle/SKILL.md:330`, logs/orch.txt

---

## Claim 13: "Health-check lock (D14, F46, T43): `scripts/health-check.sh`'s main takes `flock` on `$(git rev-parse --git-common-dir)/health-check.lock` (plain file only, as the dispatch lock), printing one line when it waits; a run inside a run ... is exempt through an exported variable"

**Location:** `docs/working/plan-build-loop-handoff.md:333`; commit f34fceb0
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the lock path, the plain-file test (the same predicate as the dispatch lock's at `scripts/build-loop.sh:1926`), the single waiting line, and the nested exemption. It does not cover a bounded wait (there is none: claim 6).

The lock is computed by `d="$(git -C "$REPO_ROOT" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)" || return 0`, then `lk="$d/health-check.lock"` (`scripts/health-check.sh:1107-1108`). Both T43 tests pass (E1).

**Evidence:** `scripts/health-check.sh:1104-1119`, `scripts/build-loop.sh:1925-1928`, logs/lock.txt

---

## Claim 14: "after --state's gate but its caller check"

**Location:** `scripts/build-loop.sh:183-186`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers which startup gates the mode runs. It does not establish what a caller's environment can redirect without caller_gate: for example, GIT_INDEX_FILE would redirect the index that diff-index reads. That consequence is not documented here.

`if [[ "$MODE" == state ]]; then caller_gate || exit 2; fi` and `if [[ -n "$GATED" ]]; then state_gate || exit 2; fi` (`scripts/build-loop.sh:648-649`), with GATED set for every mode but settings, status and marker (`:646`). The mode arm then calls `state_start` (`:1883`), which is --state's own gate (`:1256-1262`).

**Evidence:** `scripts/build-loop.sh:646-649`, `scripts/build-loop.sh:1256-1262`, `scripts/build-loop.sh:1882-1886`

---

## Claim 15: "PATH is HEAD (no merge base), index (not listed) or the file."

**Location:** `scripts/build-loop.sh:189`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every refuse line cycle_diff prints. It does not cover state-gate lines.

Two refusals that concern both questions files always name `docs/working/questions.md`:
```bash
# scripts/build-loop.sh:1837
    echo "refuse docs/working/questions.md: the default branch changed the questions files since the fork point $base, ..."; return 1
# scripts/build-loop.sh:1860
    || { echo "refuse docs/working/questions.md: the entries could not be compared"; return 1; }
```
In P2 only the archive changed on main, and the line named questions.md. Its WHY says "the questions files", so the meaning survives. A more precise wording would be: "or the file (questions.md for a refusal about both questions files)".

**Evidence:** `scripts/build-loop.sh:1837`, `scripts/build-loop.sh:1859-1860`, logs/probe1.txt (P2)

---

## Claim 16: "A deletion, a side not a regular 100644 file, or a failed read refuses; a new roadmap or idea log, and every other path, is not judged."

**Location:** `scripts/build-loop.sh:209-211`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the roadmap and the idea log, where the sentence is exact for deletions and modes. It does not cover two edges the sentence implies otherwise: a deleted questions file and a new roadmap's mode.

For the roadmap and the idea log, `if [[ "${RAW_S[i]}" == D ]]; then echo "refuse $p: the index deletes it"` (`:1820`) and the cyc_blob mode test (`:1818`) behave as stated. Two imprecisions:
- (a) **A deleted questions file is not refused as a deletion.** It is judged through its entries, so deleting a questions file that holds no `### Q-` entry passes: P8 deleted an entry-less archive, and the result was `ok`, exit 0.
- (b) **"A new roadmap ... is not judged" leaves out one check.** A new roadmap's index side must still be mode 100644, because both sides go through cyc_blob before the `000000` skip (`:1818-1819`). P9 added a symlink roadmap and got `refuse docs/roadmap.md: a side is not a regular file`.

Neither edge lets an answer through.

**Evidence:** `scripts/build-loop.sh:1818-1828`, logs/probe1.txt (P8, P9)

---

## Claim 17: "As --main-log, BASE's objects are not re-hashed: it catches the orchestrator's own slip, not a forged commit."

**Location:** `scripts/build-loop.sh:212-213`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the fact that store_check runs on MAIN_SHA only (`state_start`), not on BASE or the index's blobs. It does not establish the threat model.

`store_check --main "$MAIN_SHA"` in state_start (`scripts/build-loop.sh:1260`) is the only store_check on this path. cycle_diff calls none (`paraphrased — no quote available because the claim covers absence of a call in :1803-1866`).

**Evidence:** `scripts/build-loop.sh:1256-1262`, `scripts/build-loop.sh:1803-1867`

---

## Claim 18: Exit paragraph: "for --cycle-diff ok" (0); "a --cycle-diff refuse line" (2); 1 for "a failed mktemp (... --cycle-diff ...; no line printed)"

**Location:** `scripts/build-loop.sh:452-463`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the mode arm and state_start's mktemp under `set -e`. It does not establish the status a failing helper command would return outside these paths.

`GATE_TMP="$(mktemp -d)"` runs under `set -euo pipefail` (`:464`) in state_start (`:1258`); `cycle_diff || exit 2; echo ok` (`:1884-1885`).

**Evidence:** `scripts/build-loop.sh:452-466`, `scripts/build-loop.sh:1256-1262`, `scripts/build-loop.sh:1882-1886`

---

## Claim 19: raw_records comment: "Returns 1 when a record does not parse or lacks its path (a half record; bytes after the last NUL are not read ...). Fork-free: --main-log runs it per commit"

**Location:** `scripts/build-loop.sh:965-970`
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the return paths and the fact that the function runs no subshell or external command. It does not establish the 4.3 s figure in ec9dace7 (claim 34).

`IFS= read -r -d '' p || return 1` (`:976`) handles a meta with no NUL-ended path; the regex failing gives `|| return 1` (`:977`); trailing bytes with no NUL end the `while read` loop and are not read. The body uses only builtins and `[[ =~ ]]` (`:972-981`). log_class calls it for each chore-subject merge and each one-parent commit (`:1701`, `:1708`).

**Evidence:** `scripts/build-loop.sh:965-981`, `scripts/build-loop.sh:1701`, `scripts/build-loop.sh:1708`

---

## Claim 20: QKEYS_AWK comment: "'ID F K LINE' (tab-separated) per key line of an entry, as --check-answer delimits one: K is h ..., n ..., a ... (ANSWERS_AWK's labels, any ID); F names the file. Then 'odd' or 'unbalanced' when FENCE_AWK refuses the file."

**Location:** `scripts/build-loop.sh:1736-1740`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the output format and the labels, which match ANSWERS_AWK's `t ~ /^Q-[0123456789]+:/ || tolower(t) ~ /^\*\*answer(:|ed| \()/` at `:1657`. It does not cover ANSWER_AWK's `quoted` and `dup` whole-file results, which QKEYS does not emit (Escalations).

See the quoted program in claim 11 (`:1744-1751`). The caller treats any line not starting `Q-` as a refusal: `if grep -qv '^Q-' "$t.k"; then echo "refuse $f: FENCE_AWK refuses its $k copy ..."` (`:1855`). The T38 unbalanced-fence case passes (E1).

**Evidence:** `scripts/build-loop.sh:1736-1752`, `scripts/build-loop.sh:1657`, `scripts/build-loop.sh:1850-1857`, logs/orch.txt

---

## Claim 21: QDIFF_AWK comment: "An entry's key lines are compared in file order ... and without F, so an archive move is no change." (also d77dae74: "The sides are now compared as read, questions.md's lines then the archive's")

**Location:** `scripts/build-loop.sh:1753-1757`; commit d77dae74
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers per-ID concatenation in input order with no file field, the input order being questions.md then the archive on each side, and the sort applying only to the output lines. It does not establish the claim in d77dae74 that the swap test was red on the old sorting code (not re-run; claim 33).

```awk
# scripts/build-loop.sh:1767-1768
FILENAME == ARGV[1] { o[id] = o[id] "\n" k l; of[id] = $2; next }
{ nw[id] = nw[id] "\n" k l; nf[id] = $2; if (answered(k, l)) an[id] = 1 }
```
`l` has the first three tab fields (ID, F, K) removed (`:1766`), so the file is not part of the compared string. The loop `for f in docs/working/questions.md docs/working/questions-archive.md` fills `$t.qo` and `$t.qn` in that order (`:1841`). `sort "$t.w"` sorts only the refusal lines (`:1865`). The T38 archive move passes, and the swapped-answer case refuses (E1).

**Evidence:** `scripts/build-loop.sh:1758-1775`, `scripts/build-loop.sh:1838-1866`, logs/orch.txt

---

## Claim 22: ROADMAP_AWK comment and cyc_blob comment: "an absent side (MODE 000000) is an empty file. Returns non-zero when MODE is neither 000000 nor 100644 (a symlink, an executable), or the read fails."

**Location:** `scripts/build-loop.sh:1776-1778`; `scripts/build-loop.sh:1795-1797`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both helpers as written. It does not cover a read that writes to stderr yet exits 0, which gate_git turns into status 3, so it also fails.

```bash
# scripts/build-loop.sh:1798-1801
cyc_blob() {
  if [[ "$1" == 000000 ]]; then : > "$3"; return 0; fi
  [[ "$1" == 100644 ]] && gate_git cat-file blob "$2" > "$3"
}
```
T38's symlink idea-log case and P9 refuse (E1, E2).

**Evidence:** `scripts/build-loop.sh:1776-1801`, `scripts/build-loop.sh:959-964`, logs/probe1.txt (P9)

---

## Claim 23: cycle_diff's inline comments: "The checkout's own git, for its index (state_gate has run on it)"; "Both questions files on each side, the unchanged one included"; "Unchanged in the index: the base's copy on both sides; no entry, no copy (... a failed read refuses)"

**Location:** `scripts/build-loop.sh:1806`; `scripts/build-loop.sh:1838`; `scripts/build-loop.sh:1846`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both branches of the unchanged-file read: a file absent on the base is skipped, and an ls-tree failure or a non-100644 entry refuses. It does not cover a base where `docs/working` is not a tree; ls-tree would then list nothing and the file would be skipped.

```bash
# scripts/build-loop.sh:1847-1850
      gate_git ls-tree -z "$base" -- "$f" > "$t.lt" || { echo "refuse $f: it could not be listed on the base"; return 1; }
      [[ -s "$t.lt" ]] || continue
      IFS=$' \t' read -r -d '' md _ id _ < "$t.lt" && cyc_blob "$md" "$id" "$t.o" || { echo "refuse $f: not a regular file ..."; return 1; }
      cp "$t.o" "$t.n"
```
P1 shows the unchanged archive is really read: `Q-000 ... gone` is refused against questions-archive.md (E2).

**Evidence:** `scripts/build-loop.sh:1803-1867`, logs/probe1.txt (P1)

---

## Claim 24: HEALTH_CHECK_LOCK_HELD header: "When 1, takes no lock. Set to 1 for the run that holds health-check.lock ..., so a run it starts never waits on it. Not only a test seam: any caller setting it skips the lock."

**Location:** `scripts/health-check.sh:27-31`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the exact `== 1` test and the export before flock. It does not establish that every nested path keeps the variable: run-tests.sh unsets only PARALLEL and PARALLEL_CSH (`scripts/run-tests.sh:414`). health-check-lock.bats unsets it, but only inside its own throwaway repositories, which use a different common dir.

`[[ "${HEALTH_CHECK_LOCK_HELD:-}" != 1 ]] || return 0` (`:1106`); `export HEALTH_CHECK_LOCK_HELD=1` (`:1112`). The T43 nested-run case passes with the holder sleeping (E1).

**Evidence:** `scripts/health-check.sh:1104-1119`, `scripts/run-tests.sh:414`, `test/scripts/health-check-lock.bats:14`, logs/lock.txt

---

## Claim 25: take_lock comment: "flock(1) holds it and re-runs this script as its child with the descriptor closed (-o), so nothing a suite leaves running keeps it; -E 75 marks 'held elsewhere' (this script exits 0 or 1) ... outside a git repository there is nothing to share."

**Location:** `scripts/health-check.sh:1096-1103`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the re-run of the same file (REPO_ROOT is the script's own parent, `:51`), the leftover-process behaviour, and main's `exit "$FAIL"` with FAIL set only to 0 or 1 (`:60`, `:70`, `:1148`). It does not establish that `set -e` can never end the child with another status. The no-repository branch (`|| return 0`, `:1107`) was read but not executed.

The command is `flock -n -E 75 -o "$lk" bash "$REPO_ROOT/scripts/health-check.sh" "$@" || rc=$?` (`:1113`). T43's leftover-process case passes on HEAD. On f34fceb0's `exec 8>>` version the same test fails at `health-check-lock.bats:38`, the "out q" assertion (mutant C, E4).

**Evidence:** `scripts/health-check.sh:49-51`, `scripts/health-check.sh:60-70`, `scripts/health-check.sh:1096-1119`, `scripts/health-check.sh:1148`, logs/lock.txt, logs/probe3.txt (mutant C)

---

## Claim 26: Lib pointer: "build-loop.sh's ANSWERS_AWK ..., QKEYS_AWK and QDIFF_AWK (--cycle-diff: also this heading rule and entry end) copy these labels and the header line's Status field: change all of them together (...; build-loop-orchestrator.bats checks the label regex)."

**Location:** `scripts/lib/dev-cycle-read.sh:2055-2059`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the existence of the three copies and the regex test. Read as a set: QKEYS copies the labels, the heading rule and the entry end, and QDIFF's `answered()` copies the Status field. It does not establish that the test pins the `Q-NNN:` form or the Status rule (it pins only the bold-label regex; claim 30).

The copies are at `scripts/build-loop.sh:1657` (ANSWERS_AWK labels), `:1750` (QKEYS labels), `:1746-1747` (QKEYS heading and entry end) and `:1762` (QDIFF's Status field). The test at `test/scripts/build-loop-orchestrator.bats:432-435` passes (E1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:2055-2061`, `scripts/build-loop.sh:1657`, `scripts/build-loop.sh:1743-1768`, logs/orch.txt

---

## Claim 27: T38 helper comments and test 1's name and comments ("cd_is WANT ... exit 0 for 'ok' and 2 otherwise"; "onmain PATH TEXT: main moves by one commit ..., the checkout untouched"; "A deleted entry, two answer lines swapped ..., a route change, a removed answer line, a deleted archive"; "Main moves meanwhile ..."; "A user's answer on main meanwhile ...")

**Location:** `test/scripts/build-loop-orchestrator.bats:391-430`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each comment against the commands under it. It does not establish that the "user's answer on main" case uses an answer: it writes `# Q`, which is a change to the questions files but not an answer line. That is enough for the rule, which compares ls-tree output, but the comment describes the motive, not the fixture.

The helpers match their comments. `cd_is` asserts the status, the exact output, and an empty stderr (`:393`). `onmain` commits through a private GIT_INDEX_FILE (`:394-395`). The sed lines at `:408-413` delete Q-001's entry, swap the archive's two answer lines, change both routes, delete the Q-003 answer, and `git rm` the archive, in the order the comment gives. The test passes (E1).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:391-430`, logs/orch.txt

---

## Claim 28: T38 roadmap test name and comment: "refuses a roadmap preamble, heading or dropped brief line and an idea log edited, not appended; passes the cycle's own rewrites"; "Step 6's rewrites: Next reworded, Done trimmed, X moved to Done at closed/, an idea appended, any other path."

**Location:** `test/scripts/build-loop-orchestrator.bats:437-456`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the assertions the test makes. It does not cover the Ideas move: check 1's move to Ideas is not exercised.

`sed -i 's/^1\. n/1. m/; /2026-09-01-y/d; /2026-10-01-x/d'` then `echo '- X done: ...closed/2026-10-01-x.md' >> docs/roadmap.md` (`:442`), which appends under `## Done (last cycle)` (`:439`). The test passes (E1).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:437-456`, logs/orch.txt

---

## Claim 29: health-check-lock.bats header and test names ("Each test copies the script and the libs it sources into a throwaway repo ..., with check 5's runner stubbed, so no real suite runs"; "two concurrent health checks serialize ...: the second starts after the first ends, and says it waits"; "a run inside a run takes no lock, nor does a process a run leaves behind; a lock path that is not a plain file stops the run")

**Location:** `test/scripts/health-check-lock.bats:1-42`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each assertion. It does not establish that the nested run in test 2 was actually blocked without the exemption; that rests on commit 3021d0a4's mutant note, not re-run here.

Test 1 asserts that the log is `in a/out a/in b/out b` (or the reverse) and that the waiting line appears (`:20-25`). Test 2 holds the lock with `flock ... sleep 4 &` and runs with HEALTH_CHECK_LOCK_HELD=1 without seeing a waiting line (`:30-35`). The LEAVE run is followed by a run that does not wait (`:37-38`), and a FIFO at the lock path gives exit 1 and the plain-file message (`:39-41`). Both tests pass (E1).

**Evidence:** `test/scripts/health-check-lock.bats:1-42`, logs/lock.txt

---

## Claim 30: Test name: "the answer label regex is the same in the lib's ANSWER_AWK, ANSWERS_AWK and QKEYS_AWK"

**Location:** `test/scripts/build-loop-orchestrator.bats:432-435`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the assertion checks. It does not establish which awk program holds each copy, or parity of the `Q-NNN:` form and the `- ` strip.

```bash
# test/scripts/build-loop-orchestrator.bats:433-434
    r='/^\*\*answer(:|ed| \()/'
    [ "$(grep -cF "$r" "$REPO_ROOT/scripts/lib/dev-cycle-read.sh")" -eq 1 ] && [ "$(grep -cF "$r" "$BL")" -eq 2 ]
```
The test counts the literal per file (1 in the lib, 2 in build-loop.sh). It does not tie each count to a named program. A copy edited in QKEYS_AWK, with a second unchanged copy added elsewhere in build-loop.sh, would still pass. A more precise name would be: "the answer label regex appears once in the lib and twice in build-loop.sh".

**Evidence:** `test/scripts/build-loop-orchestrator.bats:432-435`, `scripts/build-loop.sh:1657`, `scripts/build-loop.sh:1750`, `scripts/lib/dev-cycle-read.sh:2097`

---

## Claim 31: Commit 3021d0a4 Notes: "mutants run: base = MAIN_SHA fails T38 at the main-moved line; no take_lock and no nested-run exemption each fail T43."

**Location:** commit 3021d0a4 body
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the base = MAIN_SHA mutant, re-run on HEAD's test (E4). It does not establish the two T43 mutants, which were not re-run.

Mutant A (`if ! base="$MAIN_SHA"; then`) makes test 22 fail with `want: ok` at `build-loop-orchestrator.bats:426`, the main-moved line (logs/probe3.txt).

**Evidence:** logs/probe3.txt (mutant A), `test/scripts/build-loop-orchestrator.bats:424-426`

---

## Claim 32a: Commit ec9dace7 B1: "A questions change now refuses while main's questions files differ from the fork point's (an ls-tree comparison in the gate repository ...): merge main into HEAD first. T38 case; red without the rule."

**Location:** commit ec9dace7 body
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the rule, its use of gate_git ls-tree, and the red mutant. It does not cover the parenthetical reason given for choosing ls-tree (claim 32b).

See claim 8: P2 and P3, and mutant B failing at `:428`.

**Evidence:** `scripts/build-loop.sh:1834-1837`, logs/probe3.txt (mutant B), logs/probe1.txt (P2, P3)

---

## Claim 32b: Commit ec9dace7 B1: "(an ls-tree comparison in the gate repository; diff-tree's pathspec misread there)"

**Location:** commit ec9dace7 body
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers diff-tree with a pathspec, run in a repository shaped like gate_repo's (GIT_DIR with no work tree, GIT_OBJECT_DIRECTORY set, cwd an empty directory, git 2.39.5), in recursive, `--quiet` and `--exit-code` forms. It does not reproduce the exact command the author tried, which is not recorded.

In probe2 (E3), every recursive form read the pathspec correctly:
- `diff-tree --quiet B M -- docs/working/questions.md docs/working/questions-archive.md` exits 1 when the archive changed and 0 when only another path changed.
- `diff-tree -r --name-only --exit-code` prints `docs/working/questions-archive.md`.
- P12 (E2) also printed `docs/working/questions.md` for a gate-repository `diff-tree -r --name-only B M -- docs/working/questions.md`.

The only output that looks like a misread is from the non-recursive form, which prints `docs`. That is diff-tree's documented behaviour without `-r`, not a pathspec misread. The code choice (ls-tree) is sound; the stated reason is not borne out.

**Evidence:** logs/probe2.txt, logs/probe1.txt (P12), `scripts/build-loop.sh:1834-1835`

---

## Claim 33: Commit d77dae74 and f34fceb0/414c9295 bodies (other parts): "two swapped answer lines turned drop into keep and passed with no --answered ... T38 gains the swap and a deleted-entry case (the swap is red on the sorting code)"; 414c9295 "flock -o now holds the lock and runs the script again as its child with the descriptor closed; -E 75 tells 'held elsewhere' from the run's own status. T43 gains the leftover-process case (red on the exec version)."

**Location:** commit d77dae74 body; commit 414c9295 body
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the current code and tests (the swap and deleted-entry cases exist and pass), plus 414c9295's red-on-exec claim, re-run as mutant C. It does not establish d77dae74's claim that the swap was red on the sorting code: the pre-fix QDIFF was not re-run.

The swap case is at `test/scripts/build-loop-orchestrator.bats:409` and the deleted entry at `:408`, and both pass (E1). On f34fceb0's health-check.sh, T43 test 2 fails at `:38` (E4).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:407-413`, logs/probe3.txt (mutant C), logs/orch.txt

---

## Claim 34: Commit ec9dace7: "B6 (performance 1): raw_records is fork-free (--main-log over 1,100 commits had grown 4.3 s)" and "Notes: unit at 386 code lines after compressing two comment blocks."

**Location:** commit ec9dace7 body
**Type:** Performance / Configuration
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers "fork-free" (Verified statically, claim 19) and the 386 count. The verdict is Unverifiable only for the "4.3 s over 1,100 commits" figure, which is a timing of an intermediate, unreleased version that was not re-measured.

`git diff --numstat main...HEAD -- scripts test` gives 355 added and 31 deleted lines, 386 in total (command run in the worktree; output in this session, summed with awk: `355 31 386`). The 4.3 s figure would need the pre-B6 build and a 1,100-commit fixture to verify.

**Evidence:** `scripts/build-loop.sh:965-981`

---

## Claims Requiring Attention

### Incorrect
- **Claim 32b** (commit ec9dace7 body): "diff-tree's pathspec misread there" is not reproduced. In a gate-shaped repository on git 2.39.5, diff-tree with `-r`, `--quiet` or `--exit-code` reads the pathspec correctly; only the non-recursive form prints `docs`, which is git's documented behaviour. The ls-tree choice stands, but the stated reason is wrong. It is commit-message-only, with no code impact.

### Mostly Accurate
- **Claim 6** (`docs/reviews/override-log.md:750`): "flock missing exits with flock's own status". The exit is bash's 127 (command not found), not a status flock produces; "every failure exits non-zero" holds.
- **Claim 15** (`scripts/build-loop.sh:189`): "PATH is ... the file". The main-changed and "entries could not be compared" refusals always name docs/working/questions.md, even when only the archive changed (P2).
- **Claim 16** (`scripts/build-loop.sh:209-211`): "A deletion ... refuses; a new roadmap ... is not judged". A deleted questions file with no entries passes (P8), and a new roadmap must still be mode 100644 (P9 refuses a symlink).
- **Claim 30** (`test/scripts/build-loop-orchestrator.bats:432`): the test counts the regex literal per file (1 and 2). It does not check that each named program holds a copy.

### Unverifiable
- **Claim 34** (commit ec9dace7): the "4.3 s over 1,100 commits" timing of the pre-B6 build; it needs that build and a fixture to re-measure.

## Escalations

1. **QKEYS_AWK lacks two of ANSWER_AWK's whole-file skips, `quoted` and `dup`** (claim 11 residue; d77dae74's A6, recorded as "fails safe"). There is one shape where this is not purely fail-safe:
   - **Setup.** A base questions file holds a `### Q-NNN` line inside a fence. check_answer then skips every entry in that file (`scripts/lib/dev-cycle-read.sh:2082`, `:2111`).
   - **The edit.** The index removes that fenced block. Fence and body lines are free to QKEYS, so --cycle-diff passes.
   - **The effect.** After landing, check_answer reads the file again, and an entry already ANSWERED with a keep line on the base starts reading `keep`.
   - **Why it is not a new answer.** No answer line reaches the index: it was already on main, recorded earlier. So this is not the "answer the user did not give" case the brief asks about, but it does change what `--approved`/`Asked:` reads, with no --answered ID.
   - Not executed. Static reading, Medium confidence. Route: an advisory note for the rubric, or an override row if the loop wants it recorded.
2. **The roadmap and idea log have no main-moved guard.** The ec9dace7 guard (claim 8) covers only the questions files. The roadmap's brief-name rule and the idea-log prefix rule are judged on the index, but they land through a merge with main. A clean three-way merge drops only lines one side dropped, and concurrent appends to the idea log conflict (U4 forbids hand-resolving), so this review found no merge shape that drops a brief or rewrites the idea log past the rule. Static reading only, Medium confidence. No finding; listed so the panel can confirm.
3. **Process note.** Execution logs are in the agent scratch dir, not `docs/reviews/execution-logs/` as the skill's provenance rule asks, because the brief limits this agent to its report file. The orchestrator may copy them if the rubric needs them in the repo.

## Goal-Alignment Note

The user's goal is to land U3c through its review-fix loop, with this pass as one of k=3 final confirmations. The branch's load-bearing claims hold under execution:
- the fork-point base
- the questions laundering rule and its parity with --check-answer
- the main-changed guard
- the roadmap and idea-log rules
- raw_records' equivalence
- the flock lock's serialization and leftover-process behaviour

The one Incorrect claim is a commit-message rationale with no code effect. The four Mostly-accurate items are wording only. Nothing here blocks the merge on fact-check grounds. Escalation 1 is the one item a critic may want to weigh.
