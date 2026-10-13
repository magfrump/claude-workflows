Commit: ec9dace7

# Code Fact-Check Report

**Replication:** replicate of k=3
**Repository:** /workspace/.claude/wt-build-loop-u3c (branch feat/build-loop-u3c)
**Scope:** `git diff main...HEAD` (main = dafc0e74, HEAD = ec9dace7): comments, header text, plan bullet, the eight override-log rows this branch added, test names/comments in `test/scripts/build-loop-orchestrator.bats` and `test/scripts/health-check-lock.bats`, and the commit bodies of `git log main..HEAD` (code commits). Review-report files under `docs/reviews/` other than override-log.md are context only.
**Checked:** 2026-10-12
**Total claims checked:** 48
**Summary:** 38 verified, 7 mostly accurate, 0 stale, 1 incorrect, 2 unverifiable

Hallucination pattern log (`docs/reviews/hallucination-patterns.md`, 8 entries) was read first; no claim in this diff matches a logged pattern (no entry concerns flock, merge-base, ls-tree, cmp or awk).

Execution provenance (all captured outputs live in this agent's scratch dir, `S=/tmp/claude-1000/-workspace/f335f5f6-1b17-4519-891d-602641cba507/scratchpad/fc-u3c-final-r3`, because the brief allows only this report in the repo):

- **E1** `bats -f 'cycle-diff|answer label regex' test/scripts/build-loop-orchestrator.bats` and `bats test/scripts/health-check-lock.bats`, cwd the worktree, TMPDIR a fresh `/tmp/u3c-fc-u3c-final-r3-*`, 2026-10-12T23:09:21-07:00, exit 0 both (3/3 and 2/2 ok). Output: `$S/logs/bats-orch.log`, `$S/logs/bats-lock.log`.
- **E2** `bash $S/probe1.sh` (fixture repo under `$S/p-*`, runs the branch's `scripts/build-loop.sh --cycle-diff`), cwd `$S`, 2026-10-12T23:10:58-07:00, exit 0. Output: `$S/logs/probe1.log`.
- **E3** `bash $S/mutants.sh` (copies of `scripts/` and `test/` from `git archive HEAD` under `$S/p-*`, each mutated, then T38/T43 run), cwd `$S`, 2026-10-12T23:11:36-07:00, exit 0. Output: `$S/logs/mutants.log`; the MF mutant rerun alone: `timeout -k 5 60 bats test/scripts/health-check-lock.bats`, cwd `$S/p-*/MF`, exit 124 (hang), output `$S/logs/mf.log`.
- **E4** `bash $S/probe2.sh` (quoted-heading probe, fixture repo under `$S/p-*`), cwd `$S`, 2026-10-12T23:16:48-07:00, exit 0. Output: `$S/logs/probe2.log`.
- **E5** `bats test/scripts/{build-loop-orchestrator,build-loop-check,build-loop-merge}.bats` serially, cwd the worktree, 2026-10-12T23:17:25-07:00, exit 0 each (24/24, 146/146, 12/12). Output: `$S/logs/bats-build-loop-*.log`.

No process from these runs was left running (checked with `ps` after E3/E4; the processes seen belonged to other replicates' scratch dirs).

---

## Claim 1: "--cycle-diff judges only the questions files, the roadmap and the idea log; every other staged path is not judged"

**Location:** `docs/reviews/override-log.md:745`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the path filter in cycle_diff's record loop; does not establish anything about how U4 will list the unjudged paths.

The record loop skips every other path:

```bash
# scripts/build-loop.sh:1813-1817 (inside cycle_diff, 1803-1867 — read)
    case "$p" in
      docs/working/questions.md|docs/working/questions-archive.md) qi+=("$i"); continue ;;
      docs/roadmap.md|docs/working/idea-log.md) ;;
      *) continue ;;
    esac
```

T38's second test stages `other.md` beside the cycle's rewrites and gets `ok` (E1).

**Evidence:** `scripts/build-loop.sh:1811-1829`, `test/scripts/build-loop-orchestrator.bats:441-443`, `$S/logs/bats-orch.log`

---

## Claim 2: "Row 724 discharged: one `raw_records` reads every `--raw -z` listing whole (check_line, log_class's chore and answers loops, --cycle-diff) … Equivalent to the three old readers …, but log_class's chore loop now reads a commit with an unparsed or incomplete record as other instead of skipping the record"

**Location:** `docs/reviews/override-log.md:746`
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four `--raw -z` call sites in build-loop.sh and the old-versus-new acceptance of each; does not establish behaviour for raw listings outside build-loop.sh (none in the diff).

`grep -n 'raw_records\|--raw'` over build-loop.sh finds exactly four listings, each followed by raw_records (`:1312/1315` check_line, `:1701` chore, `:1708` answers, `:1807-1808` cycle_diff). Old check_line refused an unparsed record and also counted NULs (`tr -cd '\000' … -ne $((2 * ${#ps[@]}))`, removed diff lines); the new `IFS= read -r -d '' p || return 1` (`scripts/build-loop.sh:974`) refuses the same half record, and trailing bytes after the last NUL make `read` fail and end the loop in both versions. Old answers loop: `|| return 0` on any non-matching record and `x -gt 0` plus the NUL count; new: `raw_records … && [[ ${#RAW_P[@]} -gt 0 ]] || return 0` then the same per-record test (`:1708-1711`). Old chore loop: `|| continue` past a non-matching record; new: `… && raw_records "$GATE_TMP/d" || return 0` (`:1701`), so any unparsed record makes the commit other, as the row says. The full check, merge and orchestrator suites pass (E5: 146, 12, 24 tests).

**Evidence:** `scripts/build-loop.sh:965-980`, `scripts/build-loop.sh:1312-1317`, `scripts/build-loop.sh:1699-1712`, `$S/logs/bats-build-loop-check.log`, `$S/logs/bats-build-loop-merge.log`, `$S/logs/bats-build-loop-orchestrator.log`

---

## Claim 3: "--cycle-diff reads the index only"

**Location:** `docs/reviews/override-log.md:747`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the staged-side source (`diff-index --cached` blob ids, read by id); does not establish that the later `git commit` takes that index (the row's U4 duty).

```bash
# scripts/build-loop.sh:1807
  if ! git diff-index --cached --raw -z --no-renames --ignore-submodules=none "$base" > "$t.raw" 2>"$GATE_TMP/err" \
```

The new side of every judged file is read by the index's blob id (`cyc_blob "${RAW_NM[i]}" "${RAW_NO[i]}"`, `:1818`, `:1844`); the working tree is never read.

**Evidence:** `scripts/build-loop.sh:1807-1829`, `scripts/build-loop.sh:1844`

---

## Claim 4: "`--answered` is the orchestrator's own claim and is never recorded"

**Location:** `docs/reviews/override-log.md:748`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers build-loop.sh's handling of ANSWERED; does not establish what U4 will record.

ANSWERED is only appended in argument parsing (`ANSWERED+=("$2")`, `scripts/build-loop.sh:491`) and passed to awk (`-v ids="${ANSWERED[*]}"`, `:1859`); no write of it anywhere (paraphrased — no quote available because the claim covers absence of code: `grep -n ANSWERED scripts/build-loop.sh` shows only these uses and the declaration).

**Evidence:** `scripts/build-loop.sh:478`, `scripts/build-loop.sh:487-492`, `scripts/build-loop.sh:1859`

---

## Claim 5: "health-check.sh's wait for the lock is unbounded …; a FIFO swapped in between the plain-file test and flock's open hangs instead of refusing; flock missing exits with flock's own status … every failure exits non-zero"

**Location:** `docs/reviews/override-log.md:750`
**Type:** Behavioral / Error-handling
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers take_lock's wait and its exit paths; does not establish the FIFO race by execution (needs a same-uid swap mid-call).

The blocking retry has no bound: `rc=0; flock -o "$lk" bash "$REPO_ROOT/scripts/health-check.sh" "$@" || rc=$?` (`scripts/health-check.sh:1116`). "flock missing exits with flock's own status" is imprecise: a missing flock never runs, so `rc` is bash's command-not-found status 127 (paraphrased — no quote available because the claim covers bash's behaviour for an absent binary, not a line of this script), and `exit "$rc"` (`:1118`) passes that on. Non-zero either way, so the row's conclusion holds; the precise text is "flock missing exits 127 (the shell's not-found status)".

**Evidence:** `scripts/health-check.sh:1104-1118`

---

## Claim 6: "the Done match now follows dev-cycle.sh"

**Location:** `docs/reviews/override-log.md:751`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the heading predicate; does not establish that dev-cycle.sh reads a Done section anywhere (it reads Next and named sections with the same predicate).

```awk
# scripts/build-loop.sh:1781 (ROADMAP_AWK)
/^## / { h[s] = h[s] "\n" $0; d = tolower($0); done[s] = (d == "## done" || index(d, "## done ") == 1 || index(d, "## done(") == 1); in2[s] = 1; next }
```

```awk
# scripts/dev-cycle.sh:490
t == g || index(t, g " ") == 1 || index(t, g "(") == 1 { on = 1; next }
```

Same predicate (equal, followed by a space, or followed by "(").

**Evidence:** `scripts/build-loop.sh:1779-1794`, `scripts/dev-cycle.sh:442`, `scripts/dev-cycle.sh:490`

---

## Claim 7: "--cycle-diff now refuses a questions change while main has changed the questions files since the fork point"

**Location:** `docs/reviews/override-log.md:752`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a change to either questions file on main (ls-tree compares both entries) when the index changes either file; does not establish a check when the index changes neither (then the merge takes main's copy, nothing to capture).

The ls-tree comparison (`scripts/build-loop.sh:1835-1838`, quoted under Claim 26) lists both paths. E2 P4: main changed only the archive, the chore added an open entry, refused with the "default branch changed the questions files" line; P4b: same main, the chore staged only a roadmap, `ok`. T38's onmain case is red without the rule (E3 mutant MA, `not ok 1 … line 428`).

**Evidence:** `scripts/build-loop.sh:1830-1838`, `$S/logs/probe1.log`, `$S/logs/mutants.log`

---

## Claim 8: "compares the staged files with the fork point of HEAD and `MAIN_SHA` …, and refuses a questions change while main has changed the questions files since then. It refuses a change to an existing entry's header or answer lines whose ID is not in `--answered` …, and a roadmap or idea-log line removed or edited other than by the cycle's own documented moves (F42)."

**Location:** `docs/working/plan-build-loop-handoff.md:104`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the base, the main-changed refusal and the two rule families at the summary level; does not establish the detail limits recorded in Claims 11, 14 and 17.

`base="$(git merge-base HEAD "$MAIN_SHA" …)"` (`scripts/build-loop.sh:1805`); refusals exercised in T38 (E1) and E2.

**Evidence:** `scripts/build-loop.sh:1803-1867`, `$S/logs/bats-orch.log`, `$S/logs/probe1.log`

---

## Claim 9: "`--cycle-diff [--answered Q-…]` → `ok`, or `refuse PATH: why` (exit 2); run in the orchestrator's worktree against the fork point of HEAD and `MAIN_SHA` (U3c)."

**Location:** `docs/working/plan-build-loop-handoff.md:209`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the mode's own output; does not cover the `refuse state …` lines state_gate/state_start print first (exit 2), which the script header's Exit paragraph covers.

```bash
# scripts/build-loop.sh:1880-1884
  cycle-diff)
    state_start
    cycle_diff || exit 2
    echo ok
    ;;
```

**Evidence:** `scripts/build-loop.sh:1880-1884`, `$S/logs/probe1.log`

---

## Claim 10: "the index is compared with `git merge-base HEAD MAIN_SHA` (MAIN_SHA itself when main has not moved). That is exactly what the chore branch adds when it lands, its earlier commits included … No merge base (HEAD unborn or unrelated) refuses."

**Location:** `docs/working/plan-build-loop-handoff.md:328`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers merge-base selection, earlier chore commits, HEAD on main, detached HEAD, unborn and unrelated HEAD; does not establish behaviour under a criss-cross history with several merge bases (git prints one).

E2: P3 (an earlier commit on the chore branch flips Q-001, index otherwise clean) refuses, so committed changes since the base are judged; P5 (HEAD is main) and P6 (detached at main) pass with an open entry; P7 (a committed unrelated orphan) prints `refuse HEAD: it shares no commit …`; T38's unborn orphan case refuses the same way (E1). Mutant MB (`base="$MAIN_SHA"`) fails T38 at the main-moved line (E3).

**Evidence:** `scripts/build-loop.sh:1805`, `$S/logs/probe1.log`, `$S/logs/mutants.log`

---

## Claim 11: "each entry as `--check-answer` delimits it (FENCE_AWK first; a refused file refuses)"

**Location:** `docs/working/plan-build-loop-handoff.md:330`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers entry delimitation (heading rule, entry end, fences) and FENCE_AWK's own refusals (odd, unbalanced); does not hold for --check-answer's other whole-file refusal, a question heading inside a fence ("quoted"), which QKEYS_AWK does not reproduce (see Claim 14).

Same finding as Claim 14: "a refused file refuses" is true for what FENCE_AWK refuses, but --check-answer also refuses a file for a fenced `### Q-NNN ` heading (`infence && /^### Q-[0123456789]+ / { if (!qline) qline = NR; inside = 0 }`, `scripts/lib/dev-cycle-read.sh:2082`), and --cycle-diff does not. Precise version: "FENCE_AWK first; a file FENCE_AWK refuses refuses; a fenced question heading does not".

**Evidence:** `scripts/lib/dev-cycle-read.sh:2082`, `scripts/build-loop.sh:1743-1751`, `$S/logs/probe2.log`

---

## Claim 12: roadmap and idea-log interim reading: "the idea log edited other than by appending (the base's bytes must be a prefix of the index's …); the roadmap's lines above its first `## ` heading, or its `## ` heading lines, changed; a brief file name a roadmap line outside Done names on the base that no line names in the index … Every other path is not judged"

**Location:** `docs/working/plan-build-loop-handoff.md:331`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three roadmap refusals, the idea-log prefix rule, the Done exemption and `closed/` names; does not establish detection of a brief named under a subdirectory of `briefs/` other than `closed/` (not matched: E2 P12), nor of a brief named only in the preamble (the preamble is frozen whole instead).

```bash
# scripts/build-loop.sh:1823-1824 (excerpt ends :1824; enclosing cycle_diff continues to :1867 — read)
      k="$(wc -c < "$t.o")"
      [[ "$(wc -c < "$t.n")" -ge "$k" ]] && cmp -s -n "$k" "$t.o" "$t.n" || { echo "refuse $p: edited other than by appending"; bad=1; }
```

T38's roadmap test (E1) passes the step-6 rewrites and refuses each named case; E2 P10 (empty base idea log, then appended) passes (`cmp -n 0`); E2 P11 (a dropped brief under a heading Done does not match) refuses.

**Evidence:** `scripts/build-loop.sh:1779-1794`, `scripts/build-loop.sh:1823-1829`, `$S/logs/bats-orch.log`, `$S/logs/probe1.log`

---

## Claim 13: "`scripts/health-check.sh`'s main takes `flock` on `$(git rev-parse --git-common-dir)/health-check.lock` (plain file only …), printing one line when it waits; a run inside a run … is exempt through an exported variable"

**Location:** `docs/working/plan-build-loop-handoff.md:333`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers take_lock's lock path, plain-file check, wait message and exemption; does not compare it with the dispatch lock's own rule ("as the dispatch lock").

`main()` calls `take_lock "$@"` first (`scripts/health-check.sh:1122`); T43 (E1) shows serialisation, the wait line, the nested exemption and the FIFO refusal.

**Evidence:** `scripts/health-check.sh:1104-1122`, `$S/logs/bats-lock.log`

---

## Claim 14: "The questions files, read together (an entry may move between them, delimited as --check-answer reads them; a copy FENCE_AWK refuses refuses)"

**Location:** `scripts/build-loop.sh:190-192`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the per-entry heading rule, entry end, fence handling, the Needs and answer-line sets (QKEYS_AWK tags a superset of what ANSWER_AWK reads, in file order); does not hold for --check-answer's "quoted" whole-file skip, which a free body-line edit can lift without changing any key line.

Delimitation matches. ANSWER_AWK: `heading($0) { … }` then `/^(#|##|###) / { inside = 0; next }` (`scripts/lib/dev-cycle-read.sh:2084-2085`); QKEYS_AWK:

```awk
# scripts/build-loop.sh:1744-1751 (QKEYS_AWK)
{ sub(/\r$/, "") }
fence($0) { next }
/^### Q-[0123456789]+([ \t]|$)/ { id = substr($0, 5); sub(/[ \t].*/, "", id); print id "\t" f "\th\t" $0; next }
/^(#|##|###) / { id = ""; next }
id == "" { next }
/^\*\*Needs:\*\*/ { print id "\t" f "\tn\t" $0; next }
{ t = $0; sub(/^- /, "", t); if (t ~ /^Q-[0123456789]+:/ || tolower(t) ~ /^\*\*answer(:|ed| \()/) print id "\t" f "\ta\t" $0 }
END { if (odd) print "odd " odd " " oddwhy; else if (infence) print "unbalanced " fline }'
```

Every line ANSWER_AWK reads (its heading, first Needs line, first `ID:` or `**Answer` line) is a key line here, and duplicates or a cross-file copy change the key-line sequence, so for a file --check-answer reads, an identical sequence gives an identical result. The residue: ANSWER_AWK skips the whole file when a `### Q-NNN ` heading sits inside a fence (`scripts/lib/dev-cycle-read.sh:2082`, `:2111`); QKEYS_AWK skips that line silently. E4 builds a main whose questions.md has a stray fence pair hiding Q-002's heading, so the `**Answer:** [1]` below it falls in Q-001's entry; `--check-answer Q-001` on main prints `skip Q-001: line 6 … is a question heading inside a code fence`. The chore index deletes only the fenced heading line (a body line to QKEYS_AWK); `--cycle-diff` with no `--answered` prints `ok`, exit 0; after `git merge --no-ff` into main, `--check-answer Q-001` prints `keep Q-001`. Precondition: main already holds a fenced question heading (the lib says no real file has one), so this is a gap of the stated equivalence, not a common path.

**Evidence:** `scripts/build-loop.sh:1738-1751`, `scripts/lib/dev-cycle-read.sh:2076-2114`, `$S/probe2.sh`, `$S/logs/probe2.log`

---

## Claim 15: header refusal list and non-judged set: "an entry on BASE whose heading, **Needs:** or answer lines … differ in the index, in order, or are gone; a new entry filed answered …; WHY starts with its ID … A deletion, a side not a regular 100644 file, or a failed read refuses; a new roadmap or idea log, and every other path, is not judged."

**Location:** `scripts/build-loop.sh:183-213`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed refusal (HEAD, index, questions gone/new, main-changed, idea log, roadmap preamble/headings/briefs, deletion, non-100644 side) and the not-judged set; the "A deletion … refuses" sentence is read as scoped to the roadmap and idea log (where it sits): a deleted questions file is judged entry by entry instead, so deleting one whose IDs are all in `--answered` (or that holds no entry) passes (E2 P1).

Every refusal in the header has an `echo "refuse …"` in cycle_diff (`:1805`, `:1809`, `:1818`, `:1820`, `:1824`, `:1826-1827`, `:1837`, `:1844`, `:1847-1849`, `:1853-1855`, `:1863-1864`), and nothing outside the four paths is read (`:1816`). WHY starts with the ID: `echo "refuse docs/working/$f: $i's heading, …"` (`:1863`). E2 P13 (questions.md made 100755) refuses as "a side is not a regular file"; T38 covers deletion and a symlink idea log (E1).

**Evidence:** `scripts/build-loop.sh:183-213`, `scripts/build-loop.sh:1803-1867`, `$S/logs/probe1.log`, `$S/logs/bats-orch.log`

---

## Claim 16: "Except IDs given with --answered (…; exact IDs, Q-14 is not Q-014; a repeat or an unused one is ignored)"

**Location:** `scripts/build-loop.sh:195-198`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers QDIFF_AWK's `ok[]` lookup; does not establish argument parsing beyond `^Q-[0-9]+$`.

```awk
# scripts/build-loop.sh:1765 (QDIFF_AWK)
BEGIN { n = split(ids, x, " "); for (i = 1; i <= n; i++) ok[x[i]] = 1 }
```

String keys (exact), a set (repeats collapse), consulted only for IDs present (`!(id in ok)`, `:1770-1771`).

**Evidence:** `scripts/build-loop.sh:1758-1772`

---

## Claim 17: "(Done as dev-cycle.sh reads a section: "## Done", any case, alone or before a blank or "(")"

**Location:** `scripts/build-loop.sh:206-208`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the predicate and its parity with dev-cycle.sh; "a blank" is a space only, not a tab.

`index(d, "## done ") == 1` (`scripts/build-loop.sh:1781`) matches a space only. E2 P11: a heading `## Done<TAB>(tab)` is not Done, and a brief dropped under it refuses. dev-cycle.sh behaves the same (`index(t, g " ")`, `scripts/dev-cycle.sh:490`), so "as dev-cycle.sh reads" is right; precise wording: "alone or before a space or "("". Fails closed.

**Evidence:** `scripts/build-loop.sh:1781`, `scripts/dev-cycle.sh:490`, `$S/logs/probe1.log`

---

## Claim 18: "As --main-log, BASE's objects are not re-hashed: it catches the orchestrator's own slip, not a forged commit."

**Location:** `scripts/build-loop.sh:212-213`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers state_start's store_check scope; does not establish anything about the index's blobs (also not re-hashed, not stated).

```bash
# scripts/build-loop.sh:1256-1262
state_start() {
  default_gate || exit 2
  GATE_TMP="$(mktemp -d)"; trap 'rm -rf -- "$GATE_TMP"' EXIT
  gate_repo || { echo "refuse state gate: its merge repository could not be set up"; exit 2; }
  store_check --main "$MAIN_SHA" \
    || { echo "refuse state objects: …"; exit 2; }
}
```

Only MAIN_SHA's objects are checked; BASE equals MAIN_SHA only when main has not moved.

**Evidence:** `scripts/build-loop.sh:1256-1262`

---

## Claim 19: "after --state's gate but its caller check"

**Location:** `scripts/build-loop.sh:185`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers which gates run before cycle_diff; does not cover the D6 snippet that U4 will run around it.

```bash
# scripts/build-loop.sh:646-649
GATED=""; [[ "$MODE" =~ ^(settings|status|marker)$ ]] || GATED=1  # not the gate repository's GATE_*
…
if [[ "$MODE" == state ]]; then caller_gate || exit 2; fi
if [[ -n "$GATED" ]]; then state_gate || exit 2; fi
```

cycle-diff is GATED, then calls state_start (default_gate, store_check), and caller_gate runs only for `--state`.

**Evidence:** `scripts/build-loop.sh:646-650`, `scripts/build-loop.sh:1880-1884`

---

## Claim 20: Exit paragraph: "for --cycle-diff ok" (exit 0), "a --cycle-diff refuse line" (exit 2), "a failed mktemp (… --cycle-diff …; no line printed)" (exit 1)

**Location:** `scripts/build-loop.sh:452-462`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the mode's dispatch and state_start's mktemp under `set -e`; does not establish exit codes for an I/O failure inside cycle_diff on lines not guarded (cycle_diff runs in a `||` context, where `set -e` is off).

`cycle_diff || exit 2; echo ok` (`:1882-1883`); E2 shows 0 for `ok` and 2 for every refusal.

**Evidence:** `scripts/build-loop.sh:452-462`, `scripts/build-loop.sh:1256-1258`, `scripts/build-loop.sh:1880-1884`, `$S/logs/probe1.log`

---

## Claim 21: "raw_records FILE: a --raw -z listing … read whole, the one reader every caller shares (row 724) … Returns 1 when a record does not parse or lacks its path (a half record; bytes after the last NUL are not read …). Fork-free"

**Location:** `scripts/build-loop.sh:965-970`
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the function body; does not establish the timing figure in ec9dace7's body (Claim 46).

```bash
# scripts/build-loop.sh:972-980
raw_records() {
  local meta p
  RAW_OM=(); RAW_NM=(); RAW_OO=(); RAW_NO=(); RAW_S=(); RAW_P=()
  while IFS= read -r -d '' meta; do
    IFS= read -r -d '' p || return 1
    [[ "$meta" =~ ^:([01234567]{6})\ ([01234567]{6})\ ([0123456789abcdef]+)\ ([0123456789abcdef]+)\ ([AMDT])$ ]] || return 1
    RAW_OM+=(…); … RAW_P+=("$p")
  done < "$1"
}
```

Builtins and a redirect only, no subshell or external command.

**Evidence:** `scripts/build-loop.sh:965-980`

---

## Claim 22: QKEYS_AWK comment: "'ID F K LINE' (tab-separated) per key line of an entry, as --check-answer delimits one: K is h …, n …, a for an answer line (ANSWERS_AWK's labels, any ID); F names the file. Then 'odd' or 'unbalanced' when FENCE_AWK refuses the file."

**Location:** `scripts/build-loop.sh:1737-1741`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the output format and the label set (quoted under Claim 14); the "as --check-answer delimits one" residue is Claim 14's.

The `print id "\t" f "\t…"` lines and the END rule match the comment (`scripts/build-loop.sh:1746-1751`, quoted in Claim 14); cycle_diff passes `-v f="${f##*/}"` (`:1853`).

**Evidence:** `scripts/build-loop.sh:1737-1751`, `scripts/build-loop.sh:1855-1860`

---

## Claim 23: QDIFF_AWK comment: "each side questions.md's then the archive's … An entry's key lines are compared in file order … and without F, so an archive move is no change."

**Location:** `scripts/build-loop.sh:1752-1757`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers concatenation order, the F-free comparison and in-entry order; does not establish order-independence across entries (not claimed; it holds because each ID is compared separately: E2 P2).

```awk
# scripts/build-loop.sh:1766-1768 (QDIFF_AWK; continues to :1772 — read)
{ id = $1; k = $3; l = $0; sub(/^[^\t]*\t[^\t]*\t[^\t]*\t/, "", l) }
FILENAME == ARGV[1] { o[id] = o[id] "\n" k l; of[id] = $2; next }
{ nw[id] = nw[id] "\n" k l; nf[id] = $2; if (answered(k, l)) an[id] = 1 }
```

cycle_diff appends questions.md's keys then the archive's (`for f in docs/working/questions.md docs/working/questions-archive.md`, `:1841`). T38's archive move passes and the swap refuses (E1); E2 P2 (two entries reordered) passes; mutant MC (sorted sides) fails at the swap line (E3).

**Evidence:** `scripts/build-loop.sh:1752-1772`, `scripts/build-loop.sh:1839-1861`, `$S/logs/probe1.log`, `$S/logs/mutants.log`

---

## Claim 24: ROADMAP_AWK comment: "The lines above the first '## ' heading and the heading lines stay; a brief file a line outside '## Done' names on the base is named on some line of the index."

**Location:** `scripts/build-loop.sh:1773-1777`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three checks; "some line of the index" includes Done lines and excludes the preamble (preamble lines go to `p[s]` and are not scanned), which the frozen preamble makes moot.

```awk
# scripts/build-loop.sh:1782-1789 (ROADMAP_AWK; continues to :1794 — read)
!in2[s] { p[s] = p[s] "\n" $0; next }
{
  r = $0
  while (match(r, /docs\/working\/briefs\/(closed\/)?[A-Za-z0-9._-]+\.md/)) {
    b = substr(r, RSTART, RLENGTH); sub(/.*\//, "", b); r = substr(r, RSTART + RLENGTH)
    if (s == 2) named[b] = 1; else if (!done[1]) need[b] = 1
  }
}
```

**Evidence:** `scripts/build-loop.sh:1773-1794`, `$S/logs/bats-orch.log`

---

## Claim 25: "cyc_blob MODE ID OUT: … an absent side (MODE 000000) is an empty file. Returns non-zero when MODE is neither 000000 nor 100644 …, or the read fails."

**Location:** `scripts/build-loop.sh:1795-1797`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the function; does not establish that a read failure is distinguishable from a mode refusal (both give the same message).

```bash
# scripts/build-loop.sh:1798-1801
cyc_blob() {
  if [[ "$1" == 000000 ]]; then : > "$3"; return 0; fi
  [[ "$1" == 100644 ]] && gate_git cat-file blob "$2" > "$3"
}
```

E2 P13 (100755) and T38's symlink case refuse (E1, E2).

**Evidence:** `scripts/build-loop.sh:1795-1801`, `$S/logs/probe1.log`

---

## Claim 26: "The chore branch lands as a merge, and --check-answer reads the merged file: lines judged free here (a fence pair, a heading) can capture an answer main gained since the fork (i2 security F1). So the questions files must be as on main"

**Location:** `scripts/build-loop.sh:1831-1834`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the comparison that follows and its effect; does not establish the capture shape itself by a fresh execution here (taken from the i2 security report), only that the guard is necessary to T38 (mutant MA red).

```bash
# scripts/build-loop.sh:1835-1838
  if ! gate_git ls-tree -z "$base" -- docs/working/questions.md docs/working/questions-archive.md > "$t.lb" \
    || ! gate_git ls-tree -z "$MAIN_SHA" -- docs/working/questions.md docs/working/questions-archive.md > "$t.lm" || ! cmp -s "$t.lb" "$t.lm"; then
    echo "refuse docs/working/questions.md: the default branch changed the questions files since the fork point $base, …"; return 1
  fi
```

check_answer reads `git cat-file blob "$MAIN_SHA:$f"` (`scripts/lib/dev-cycle-read.sh:2140`), i.e. the landed merge.

**Evidence:** `scripts/build-loop.sh:1830-1838`, `scripts/lib/dev-cycle-read.sh:2127-2154`, `$S/logs/mutants.log`

---

## Claim 27: "The checkout's own git, for its index (state_gate has run on it)."

**Location:** `scripts/build-loop.sh:1806`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that diff-index uses plain `git` after the top-level state_gate; does not establish that caller_gate ran (it does not: Claim 19).

`git diff-index --cached …` (`:1807`) is plain `git`, not `gate_git`; state_gate ran at `:649`.

**Evidence:** `scripts/build-loop.sh:649`, `scripts/build-loop.sh:1806-1810`

---

## Claim 28: "Unchanged in the index: the base's copy on both sides; no entry, no copy (…: a failed read refuses)."

**Location:** `scripts/build-loop.sh:1846`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the ls-tree and blob reads; does not cover the following `cp` (unguarded, `set -e` off inside a `||`-called function), which is a copy, not a read.

```bash
# scripts/build-loop.sh:1847-1850
      gate_git ls-tree -z "$base" -- "$f" > "$t.lt" || { echo "refuse $f: it could not be listed on the base"; return 1; }
      [[ -s "$t.lt" ]] || continue
      IFS=$' \t' read -r -d '' md _ id _ < "$t.lt" && cyc_blob "$md" "$id" "$t.o" || { echo "refuse $f: not a regular file (mode 100644) on the base, or could not be read"; return 1; }
      cp "$t.o" "$t.n"
```

**Evidence:** `scripts/build-loop.sh:1845-1851`

---

## Claim 29: "HEALTH_CHECK_LOCK_HELD When 1, takes no lock. Set to 1 for the run that holds health-check.lock …, so a run it starts never waits on it. Not only a test seam: any caller setting it skips the lock."

**Location:** `scripts/health-check.sh:27-31`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers take_lock's test and export; does not establish that every nested launcher preserves the environment (bats and run-tests.sh do in practice).

`[[ "${HEALTH_CHECK_LOCK_HELD:-}" != 1 ]] || return 0` (`scripts/health-check.sh:1106`) and `export HEALTH_CHECK_LOCK_HELD=1` before flock (`:1112`). T43 test 2 (E1); mutant MF without the test hangs T43 (E3).

**Evidence:** `scripts/health-check.sh:1104-1118`, `$S/logs/bats-lock.log`, `$S/logs/mf.log`

---

## Claim 30a: take_lock's mechanism: "flock(1) holds it and re-runs this script as its child with the descriptor closed (-o), so nothing a suite leaves running keeps it; -E 75 marks 'held elsewhere' … The child, and a run inside it …, get HEALTH_CHECK_LOCK_HELD=1 and take no lock. Only a plain file is locked …; outside a git repository there is nothing to share."

**Location:** `scripts/health-check.sh:1096-1103`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the flock invocation, the 75 retry, the exemption, the plain-file test and the no-repo return; does not establish the FIFO-swap race (override row) or behaviour when flock is absent (Claim 5).

```bash
# scripts/health-check.sh:1104-1118
take_lock() {
    local d lk rc=0
    [[ "${HEALTH_CHECK_LOCK_HELD:-}" != 1 ]] || return 0
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

T43 passes (E1); the f34fceb0 `exec 8>>` version fails T43's leftover-process line (E3 mutant MD, line 38). `main "$@"` passes arguments through (`:1153`).

**Evidence:** `scripts/health-check.sh:1096-1122`, `scripts/health-check.sh:1151-1154`, `$S/logs/bats-lock.log`, `$S/logs/mutants.log`

---

## Claim 30b: "(this script exits 0 or 1)"

**Location:** `scripts/health-check.sh:1100`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers main's normal exits; does not hold for an unguarded command failing under `set -euo pipefail`, which exits with that command's status.

`exit "$FAIL"` with `FAIL=0`/`fail() { …; FAIL=1; }` (`scripts/health-check.sh:60`, `:70`, `:1148`) and `exit 1` (`:1110`) are the explicit exits, but `set -euo pipefail` (`:49`) lets any unguarded failure exit with its own status (paraphrased — no quote available because the claim covers every unguarded command in a 1,150-line script). A child exiting 75 would be read as "held elsewhere" and rerun once; precise version: "this script's own exits are 0 or 1".

**Evidence:** `scripts/health-check.sh:49`, `scripts/health-check.sh:60-70`, `scripts/health-check.sh:1110`, `scripts/health-check.sh:1148`

---

## Claim 31: "build-loop.sh's ANSWERS_AWK …, QKEYS_AWK and QDIFF_AWK (--cycle-diff: also this heading rule and entry end) copy these labels and the header line's Status field: change all of them together … build-loop-orchestrator.bats checks the label regex"

**Location:** `scripts/lib/dev-cycle-read.sh:2055-2059`
**Type:** Architectural / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the label regex appears in all three readers and the test pins its count; does not establish exact Status-rule parity (QDIFF_AWK's `answered()` accepts any `**Status:** ANSWERED` field on any Needs line, stricter than the lib's last-field-of-first-line rule, and applies only to new entries) or that the `Q-NNN:` label is pinned by the test.

```bash
# test/scripts/build-loop-orchestrator.bats:432-435
@test "the answer label regex is the same in the lib's ANSWER_AWK, ANSWERS_AWK and QKEYS_AWK (U3c i2 architecture 1)" {
    r='/^\*\*answer(:|ed| \()/'
    [ "$(grep -cF "$r" "$REPO_ROOT/scripts/lib/dev-cycle-read.sh")" -eq 1 ] && [ "$(grep -cF "$r" "$BL")" -eq 2 ]
}
```

Passes (E1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:2055-2059`, `scripts/lib/dev-cycle-read.sh:2097`, `scripts/build-loop.sh:1657`, `scripts/build-loop.sh:1750`, `$S/logs/bats-orch.log`

---

## Claim 32: test helper comment: "cd_is WANT [ARG...]: --cycle-diff ARG... printed exactly WANT, exit 0 for 'ok' and 2 otherwise. onmain PATH TEXT: main moves by one commit setting PATH to TEXT, the checkout untouched. qa: the questions files on main, then a chore branch."

**Location:** `test/scripts/build-loop-orchestrator.bats:391-399`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the three helpers; cd_is also requires empty stderr (not stated).

onmain builds the commit in a temporary index (`GIT_INDEX_FILE="$x" git read-tree main`) and moves only `refs/heads/main` with update-ref (`:394-395`), leaving the checkout and its index alone.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:391-399`

---

## Claim 33: T38 test 1 name and comments ("refuses an entry's header or answer changed or gone without --answered, and passes body edits, an open new entry and an archive move"; "A user's answer on main meanwhile: the merge could fence it off …")

**Location:** `test/scripts/build-loop-orchestrator.bats:400-430`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each assertion against its comment; the "user's answer on main" case writes `# Q` to main's questions.md, a change but not an answer.

The name and the other comments match their assertions (E1). Line 427's comment says "A user's answer on main", but the fixture is `onmain docs/working/questions.md "# Q"` (`:428`), which tests "main changed the questions files", the rule's actual trigger. Precise version: "main changes the questions files meanwhile (a user's answer, say)".

**Evidence:** `test/scripts/build-loop-orchestrator.bats:400-430`, `$S/logs/bats-orch.log`

---

## Claim 34: T38 test 2 name and comments ("refuses a roadmap preamble, heading or dropped brief line and an idea log edited, not appended; passes the cycle's own rewrites"; "No merge base; usage.")

**Location:** `test/scripts/build-loop-orchestrator.bats:437-456`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the assertions; the "No merge base" case is an unborn orphan HEAD, not a committed unrelated history (that one checked in E2 P7).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:437-456`, `$S/logs/bats-orch.log`, `$S/logs/probe1.log`

---

## Claim 35: T43 header and test names: "Each test copies the script and the libs it sources into a throwaway repo …, with check 5's runner stubbed, so no real suite runs"; "two concurrent health checks serialize …, and says it waits"; "a run inside a run takes no lock, nor does a process a run leaves behind; a lock path that is not a plain file stops the run"

**Location:** `test/scripts/health-check-lock.bats:3-41`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the copies (health-check.sh sources exactly log-format, md-utils, skill-paths: `scripts/health-check.sh:63-67`) and each assertion; test 1's "says it waits" is timing-dependent (a 1 s stub makes overlap likely, not certain).

**Evidence:** `test/scripts/health-check-lock.bats:1-41`, `scripts/health-check.sh:63-67`, `$S/logs/bats-lock.log`

---

## Claim 36: 6f347256 body: "interim /away reading of 'the cycle's own documented moves' for the roadmap (preamble and headings fixed, briefs never dropped outside Done, idea log append-only); the base is the fork point rather than MAIN_SHA because step 7 merges move main mid-iteration"

**Location:** `6f347256` (commit body)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement between the body and the plan bullet and code; does not judge the reading.

**Evidence:** `docs/working/plan-build-loop-handoff.md:327-333`, `scripts/build-loop.sh:1805`

---

## Claim 37: 3021d0a4 body (T38/T43 case list)

**Location:** `3021d0a4` (commit body)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the listed cases as present in HEAD's tests; later commits added cases (swap, deleted entry, main-changed questions, regex parity).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:400-456`, `test/scripts/health-check-lock.bats:15-41`, `$S/logs/bats-orch.log`

---

## Claim 38: 3021d0a4 Notes: "mutants run: base = MAIN_SHA fails T38 at the main-moved line; no take_lock and no nested-run exemption each fail T43."

**Location:** `3021d0a4` (commit body)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three mutants on HEAD's tests; "fail" for the nested-run mutant is a hang (a deadlock), red only under a timeout.

E3: MB fails T38 test 1 at line 426 (`onmain docs/roadmap.md "# R"; cd_is ok --answered Q-001`, the main-moved line); ME fails both T43 tests (lines 24, 41); MF never completes: bats was killed by `timeout` after 60 s with only `1..2` printed (exit 124, `$S/logs/mf.log`). Precise version: "no nested-run exemption hangs T43 (the child waits on its own parent's lock)".

**Evidence:** `$S/logs/mutants.log`, `$S/logs/mf.log`

---

## Claim 39: f34fceb0 body: "questions entries' heading, Needs and answer lines change only for --answered IDs, a new entry is never filed answered without one; the idea log only appends; the roadmap keeps its preamble and headings and never drops a brief named outside Done. raw_records reads every --raw -z listing whole …: check_line, log_class's chore and answers loops, --cycle-diff. health-check.sh takes a flock …, waiting; a nested run is exempt."

**Location:** `f34fceb0` (commit body)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the literal rules (each verified in Claims 1-30); does not carry the Claim 14 residue, because the body states the key-line rule, which holds literally in E4 (no key line changed).

**Evidence:** `scripts/build-loop.sh:1737-1867`, `scripts/health-check.sh:1096-1122`, `$S/logs/probe1.log`, `$S/logs/probe2.log`

---

## Claim 40: 414c9295 body: "With exec 8>> every suite and any process a test left running inherited the lock's descriptor …; flock -o now holds the lock and runs the script again as its child with the descriptor closed; -E 75 tells 'held elsewhere' from the run's own status. T43 gains the leftover-process case (red on the exec version)."

**Location:** `414c9295` (commit body)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the exec-version regression with HEAD's T43; does not establish the -E 75 / child-75 collision beyond Claim 30b.

f34fceb0's take_lock used `exec 8>>"$lk"` then `flock -n 8 || { …; flock 8; }` (`git show f34fceb0:scripts/health-check.sh`). E3 mutant MD (that file under HEAD's T43): `not ok 2 …` at line 38, the leftover-process assertion.

**Evidence:** `scripts/health-check.sh:1104-1118`, `$S/logs/mutants.log`

---

## Claim 41: d77dae74 body: "Sorting each side's key lines lost their order inside an entry … two swapped answer lines turned drop into keep and passed with no --answered … T38 gains the swap and a deleted-entry case (the swap is red on the sorting code)."

**Location:** `d77dae74` (commit body)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the swap case red under sorting; the sorting mutant is a re-insertion of f34fceb0's `sort -o` of each side before QDIFF_AWK, not the f34fceb0 file itself.

f34fceb0 had `LC_ALL=C sort -o "$t.qo" "$t.qo" && LC_ALL=C sort -o "$t.qn" "$t.qn"` (its line 1848). E3 mutant MC fails T38 at line 409, the swap (`sed -i '/^- \*\*Answer/{h;d}; /^Q-000/G' …`).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:407-409`, `$S/logs/mutants.log`

---

## Claim 42: d77dae74 Notes: "A6 (QKEYS_AWK lacks ANSWER_AWK's whole-file refusals) left as is: it fails safe."

**Location:** `d77dae74` (commit body)
**Type:** Error-handling
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the "quoted" whole-file refusal (a question heading inside a fence); the "dup" and "both files" refusals do fail safe (removing a duplicate changes the key-line sequence and refuses), and "odd"/"unbalanced" are reproduced by QKEYS_AWK.

The missing "quoted" refusal does not always fail safe. When main's questions.md holds a fenced `### Q-NNN ` heading, --check-answer skips every ID in the file (`scripts/lib/dev-cycle-read.sh:2082`, `:2111`). Deleting that fenced line is a body-line edit to QKEYS_AWK (`fence($0) { next }`, `scripts/build-loop.sh:1745`), so no key line changes and --cycle-diff passes. The merged file then makes --check-answer return an answer for an ID not in `--answered`. E4: the base gives `skip Q-001: line 6 … is a question heading inside a code fence`, `--cycle-diff` with no `--answered` gives `ok` (exit 0), and after the `--no-ff` merge to main the result is `keep Q-001`. In that fixture, the `**Answer:** [1]` that --check-answer now reads as Q-001's sat below the hidden Q-002 heading. Precondition: main already holds a stray fence pair around a question heading (the lib's comment says "No real questions file has any of them"). To make it fail safe, QKEYS_AWK can print `quoted N` for a fenced `### Q-NNN ` heading, as ANSWER_AWK does, so cycle_diff refuses that copy.

**Evidence:** `scripts/lib/dev-cycle-read.sh:2082`, `scripts/lib/dev-cycle-read.sh:2108-2113`, `scripts/build-loop.sh:1743-1751`, `$S/probe2.sh`, `$S/logs/probe2.log`

---

## Claim 43: ec9dace7 B1: "A questions change now refuses while main's questions files differ from the fork point's (an ls-tree comparison in the gate repository …): merge main into HEAD first. T38 case; red without the rule."

**Location:** `ec9dace7` (commit body)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the rule, where it reads (gate_git) and the red mutant; the "diff-tree's pathspec misread there" aside is Claim 44.

E3 mutant MA (the ls-tree block removed) fails T38 test 1 at line 428; HEAD passes (E1).

**Evidence:** `scripts/build-loop.sh:1835-1838`, `$S/logs/mutants.log`, `$S/logs/bats-orch.log`

---

## Claim 44: ec9dace7 B1 aside: "diff-tree's pathspec misread there"

**Location:** `ec9dace7` (commit body)
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers nothing about diff-tree's pathspec in the gate repository. This replicate did not run it.

Not executed. Verifying it needs a `gate_git diff-tree <base> <main> -- docs/working/questions.md` run in a gate repository (GIT_DIR in `$GATE_TMP/git`, cwd `$GATE_TMP/work`) set up as gate_repo does.

**Evidence:** `scripts/build-loop.sh:945-963`

---

## Claim 45: ec9dace7 B5/B9/B10 and "plan lines 104/209": "Done is matched as dev-cycle.sh matches a section … HEALTH_CHECK_LOCK_HELD == 1 … plan lines 104/209"

**Location:** `ec9dace7` (commit body)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the named fixes being present in HEAD; does not re-check B7's Exit paragraph beyond Claim 20.

The plan diff's hunks land at lines 104 and 209 (`@@ -101,7 +101,7 @@`, `@@ -206,7 +206,7 @@` in `git diff main...HEAD -- docs/working/plan-build-loop-handoff.md`). For Done see Claim 6, for `!= 1` see Claim 29.

**Evidence:** `docs/working/plan-build-loop-handoff.md:104`, `docs/working/plan-build-loop-handoff.md:209`, `scripts/build-loop.sh:1781`, `scripts/health-check.sh:1106`

---

## Claim 46: ec9dace7 B6: "raw_records is fork-free (--main-log over 1,100 commits had grown 4.3 s)"

**Location:** `ec9dace7` (commit body)
**Type:** Performance
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** The fork-free part is verified (Claim 21). This replicate did not reproduce the 4.3 s figure for the previous version over 1,100 commits.

Verifying the figure needs a timed `--main-log` run over a history of about 1,100 commits with the i1 raw_records, which used `tr | wc` forks, against HEAD's version.

**Evidence:** `scripts/build-loop.sh:965-980`

---

## Claim 47: ec9dace7 Notes: "unit at 386 code lines after compressing two comment blocks"

**Location:** `ec9dace7` (commit body)
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count as changed lines (added plus removed, comments included) under `scripts/` and `test/`, the measure plan row 62 uses. It does not count non-comment lines alone, which come to 261.

`git diff --numstat main...HEAD -- scripts test` gives 210/29, 31/0, 5/2, 67/0 and 42/0. That is 355 + 31 = 386.

**Evidence:** `scripts/build-loop.sh:1`, `test/scripts/health-check-lock.bats:1`

---

## Claims Requiring Attention

### Incorrect
- **Claim 42** (`d77dae74` Notes): "A6 … fails safe" is false for the "quoted" refusal. If main has a fenced question heading, deleting that fenced line passes --cycle-diff with no `--answered`, and --check-answer then reads `keep` instead of `skip` (executed, E4). Fix: QKEYS_AWK prints `quoted N` for a fenced `### Q-NNN ` heading, so cycle_diff refuses that copy.

### Stale
- (none)

### Mostly Accurate
- **Claim 5** (`docs/reviews/override-log.md:750`): when flock is missing the status is bash's 127, not "flock's own status".
- **Claim 11** (`docs/working/plan-build-loop-handoff.md:330`): "a refused file refuses" covers what FENCE_AWK refuses, not --check-answer's quoted-heading refusal.
- **Claim 14** (`scripts/build-loop.sh:190-192`): "delimited as --check-answer reads them" holds per entry but omits the whole-file quoted skip (Claim 42).
- **Claim 17** (`scripts/build-loop.sh:206-208`): "before a blank" means a space only; a tab after "## Done" is not Done (fails closed, same as dev-cycle.sh).
- **Claim 30b** (`scripts/health-check.sh:1100`): "this script exits 0 or 1" applies only to its explicit exits. Under `set -euo pipefail`, other statuses are possible.
- **Claim 33** (`test/scripts/build-loop-orchestrator.bats:427`): the "user's answer on main" fixture writes `# Q`, which is a change to the questions files, not an answer.
- **Claim 38** (`3021d0a4` Notes): the no-nested-exemption mutant hangs T43 (a deadlock under a timeout). It does not fail it.

### Unverifiable
- **Claim 44** (`ec9dace7`): to check "diff-tree's pathspec misread" in the gate repository, run diff-tree there.
- **Claim 46** (`ec9dace7`): checking the 4.3 s / 1,100-commit figure needs a timed --main-log comparison.

## Escalations

1. **Claim 42 / 14 / 11: the quoted-heading gap.** It is a laundering shape that the iteration-2 B1 fix does not cover and that no earlier report names. It needs a main that already holds a fenced `### Q-NNN ` heading, which questions.sh archive splitting can leave. Given that, the orchestrator can lift --check-answer's whole-file skip by deleting one fenced line, which --cycle-diff counts as free. An answer line that --check-answer then attributes to an ID not in `--answered` reaches main and unblocks `--approved` or a brief's `Asked:` line. The fix is one awk line, with a refusal to match. Severity is low because of the precondition, but the commit note claiming it fails safe is wrong.
2. Everything else in the brief's checklist held under execution. That covers merge-base shapes (an earlier chore commit, HEAD on main, detached, unborn, unrelated), main changing only the archive, raw_records parity (full check, merge and orchestrator suites green), and the take_lock exit and exemption paths.
