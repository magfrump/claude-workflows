Commit: 74deb04e

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u3c (branch `feat/build-loop-u3c`)
**Scope:** full branch diff `main...74deb04e` (main = dafc0e74): `docs/reviews/override-log.md` (three new rows), `docs/working/plan-build-loop-handoff.md` (the U3c bullet), `scripts/build-loop.sh` (the `--cycle-diff` header, raw_records, QKEYS_AWK, QDIFF_AWK, ROADMAP_AWK, cyc_blob, cycle_diff, check_line and log_class on raw_records), `scripts/health-check.sh` (take_lock), `test/scripts/build-loop-orchestrator.bats` (two T38 tests), `test/scripts/health-check-lock.bats` (T43), and the five non-review commit bodies (6f347256, 3021d0a4, f34fceb0, 414c9295, d77dae74)
**Checked:** 2026-10-12 (execution timestamps below are UTC, 2026-10-13T05:32Z-05:43Z)
**Commit:** 74deb04e
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 33
**Summary:** 29 verified, 4 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`, 8 entries) read first. None of its patterns (corpus statistics, test tallies, consumer lists, golden counts) matches a claim here. The closest kind is the test-case lists in a commit body (Claim 30). It is a miscount of cases, not a fabricated symbol.

Execution provenance. Every executed claim cites one of these runs. Scratch dir S = `/tmp/claude-1000/-workspace/f335f5f6-1b17-4519-891d-602641cba507/scratchpad/fc-u3c-i2`. Probes ran on fixture repos under `S/p-*` only. Mutants ran on scratch copies of HEAD's `scripts/` and `test/`, with no git writes in the worktree. Every logged run ended with no flock or health-check process left (checked with `ps` after E8).

| Run | Command (cwd) | Exit | Started (UTC) | Output |
|---|---|---|---|---|
| E1 | `bash S/run-suites.sh`: `bats -f cycle-diff test/scripts/build-loop-orchestrator.bats`, then `bats test/scripts/health-check-lock.bats` (cwd the worktree; TMPDIR from `mktemp -d /tmp/u3c-fc-u3c-i2-XXXX`) | 0 and 0 (2/2 and 2/2 ok) | 2026-10-13T05:32:02Z | `S/logs/t38.log`, `S/logs/t43.log` |
| E2 | `bash S/probe-q.sh` (cwd S/p-FuXO): six questions shapes. For each: `--cycle-diff`, then `dev-cycle.sh --check-answer` before, and after the index lands as main | finished (last line `T=` printed); the exit status was not captured | ~05:33Z | `S/logs/probe-q.log` |
| E3 | `bash S/probe-base.sh` (cwd S/p-HphC): base and index edge cases | 0 | 05:33:53Z | `S/logs/probe-base.log` |
| E4 | `bash S/probe-hc.sh` (cwd S/p-Kc5m): health-check outside a repository, exit passthrough, lock descriptors | 0 | 05:34:13Z | `S/logs/probe-hc.log` |
| E5 | `bash S/probe-rm.sh` (cwd S/p-Y5Du): roadmap rule | 0 | 05:34:30Z | `S/logs/probe-rm.log` |
| E6 | `bash S/probe-mut.sh`: m1 = f34fceb0's build-loop.sh (sorted key lines) under HEAD's T38; m2 = f34fceb0's health-check.sh (`exec 8>>`) under HEAD's T43 | 0 (m1: T38 not ok at the swap line; m2: T43 test 2 not ok at the leftover-process line) | 05:35:02Z | `S/logs/probe-mut.log` |
| E7 | `bash S/probe-miss.sh` (cwd S/p-Qr5a): an unchanged questions file whose base blob is missing | 0 | 05:37:02Z | `S/logs/probe-miss.log` |
| E8 | `bash S/probe-mut2.sh`: m3 base = MAIN_SHA; m4 no take_lock call; m5 no nested-run exemption | 0 (m3: T38 not ok at the main-moved line; m4: both T43 not ok; m5: T43 hung, killed by `timeout 300`, exit 124) | 05:37:48Z | `S/logs/probe-mut2.log` |

---

## Claim 1: "Re-keys row 722 (a chore merge's other paths are not read): --cycle-diff judges only the questions files, the roadmap and the idea log; every other staged path is not judged"

**Location:** `docs/reviews/override-log.md:745`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which staged paths cycle_diff reads, and row 722's revisit trigger naming U3c's --cycle-diff. It does not establish that U4's step 9 will take up the re-keyed duty.

cycle_diff's dispatch reads three path groups and skips every other record:

```bash
# scripts/build-loop.sh:1816-1820
    case "$p" in
      docs/working/questions.md|docs/working/questions-archive.md) qi+=("$i"); continue ;;
      docs/roadmap.md|docs/working/idea-log.md) ;;
      *) continue ;;
    esac
```

Row 722 (`docs/reviews/override-log.md:722`) says "Revisit trigger: U3c's --cycle-diff (the staged files before the chore commit), or U4's step 9". E1's roadmap test stages `other.md` (`echo x > other.md; git add -A; cd_is ok`, `test/scripts/build-loop-orchestrator.bats:431`), and the run passes.

**Evidence:** `scripts/build-loop.sh:1812-1820`, `docs/reviews/override-log.md:722`, `test/scripts/build-loop-orchestrator.bats:430-431`, E1

---

## Claim 2: "Row 724 discharged: one `raw_records` reads every `--raw -z` listing whole (check_line, log_class's chore and answers loops, --cycle-diff) … Equivalent to the three old readers (i1 fact-check), but log_class's chore loop now reads a commit with an unparsed record as other instead of skipping the record (git never prints one)."

**Location:** `docs/reviews/override-log.md:746`
**Type:** Architectural / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that every `--raw -z` listing in scripts/ goes through raw_records, and how the old and new loops behave on the record shapes. It does not establish what git prints on a damaged object store.

**Every reader.** `--raw` appears in scripts/ only at `scripts/build-loop.sh:1313` (check_line), `:1702` (chore), `:1709` (answers) and `:1810` (cycle_diff). Each one goes through `raw_records` (`:1316`, `:1702`, `:1709`, `:1811`). This is paraphrased because the claim is about the absence of other readers, established by a grep of `scripts/*.sh` and `scripts/lib/*.sh`.

**The stated change.** The old chore loop `continue`d past any record that did not match. The new one returns before the loop when raw_records fails:

```bash
# scripts/build-loop.sh:1702 (the chore branch; enclosing log_class continues to :1715, read)
    gate_git diff-tree -r --no-renames --raw -z "${ps[0]}" "$c" > "$GATE_TMP/d" && raw_records "$GATE_TMP/d" || return 0
```

**What the row leaves out.** raw_records also fails when the NUL count is not two per record (`[[ "$(tr -cd '\000' < "$1" | wc -c)" -eq $((2 * ${#RAW_P[@]})) ]]`, `:980`). The old chore loop had no such count. It could return chore from an earlier matching record before reaching a trailing half-record. So the chore loop changes in two ways, not one: an unparsed record, or an odd trailing field, now makes the commit other. Both are shapes git does not print, so the "(git never prints one)" conclusion holds. The precise row would read "a commit with an unparsed or incomplete record". check_line and the answers loop already had the NUL count (main's copy, `scripts/build-loop.sh:1269` and `:1667`), so neither changes.

**Evidence:** `scripts/build-loop.sh:967-978`, `scripts/build-loop.sh:1313-1318`, `scripts/build-loop.sh:1699-1715`, `git show main:scripts/build-loop.sh` (old loops), `scripts/build-loop.sh:1810-1811`

---

## Claim 3: "The orchestrator's chore commit must take the index as --cycle-diff read it: no `commit -a`, no paths, no edits between the check and the commit … --cycle-diff reads the index only"

**Location:** `docs/reviews/override-log.md:747`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that cycle_diff reads only the index against BASE, never the working tree. It does not establish U4's commit step, which does not exist yet.

```bash
# scripts/build-loop.sh:1810 (in cycle_diff, which continues to :1860, read)
  if ! git diff-index --cached --raw -z --no-renames --ignore-submodules=none "$base" > "$t.raw" 2>"$GATE_TMP/err" \
```

Every blob it reads comes from a raw record's id through `gate_git cat-file blob` (`cyc_blob`, `:1803`) or from `$base:$f` (`:1841`). No working-tree file is read. This is paraphrased because the absence of a working-tree read is established across the whole of cycle_diff, `:1806-1860`.

**Evidence:** `scripts/build-loop.sh:1795-1860`

---

## Claim 4: "Base: the fork point, not MAIN_SHA … the index is compared with `git merge-base HEAD MAIN_SHA` (MAIN_SHA itself when main has not moved). That is exactly what the chore branch adds when it lands, its earlier commits included … No merge base (HEAD unborn or unrelated) refuses."

**Location:** `docs/working/plan-build-loop-handoff.md:328`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the base computation and these cases: HEAD on main, detached HEAD, main moved after the fork, main merged into the chore branch, an earlier chore commit, and an orphan HEAD. It does not establish the criss-cross case (git merge-base prints one of several bases), and does not establish that a later 3-way merge lands exactly the diff it reads when main conflicts.

```bash
# scripts/build-loop.sh:1808 (cycle_diff, :1806-1860, read whole)
  if ! base="$(git merge-base HEAD "$MAIN_SHA" 2>/dev/null)"; then echo "refuse HEAD: it shares no commit with the default branch's $MAIN_SHA, or could not be read"; return 1; fi
```

The E3 runs:
- HEAD = main with a clean index prints `ok`.
- HEAD = main with a staged ANSWERED flip refuses Q-001.
- Detached HEAD at main refuses the same flip.
- A chore branch that merged main, after main recorded a user's answer to Q-001, prints `ok`: the merge base is the merged main.
- An earlier chore commit that filed Q-002 as ANSWERED is refused as a new entry filed answered, so earlier commits count.

In E1, the orphan case prints `refuse HEAD: …`. In E8, mutant m3 (base = MAIN_SHA) fails T38 at the main-moved line with `refuse … Q-003 is a new entry filed answered`. The fork-point choice is what keeps main's own change out of the diff.

**Evidence:** `scripts/build-loop.sh:1808`, `test/scripts/build-loop-orchestrator.bats:407`, `test/scripts/build-loop-orchestrator.bats:443`, E1, E3, E8 (m3)

---

## Claim 5: "The index only (`git diff-index --cached --raw -z --no-renames` in the checkout)"

**Location:** `docs/working/plan-build-loop-handoff.md:329`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the listing command and the refusal when the index cannot be listed, including an unmerged index. It does not establish behaviour for intent-to-add entries.

`scripts/build-loop.sh:1809-1813` runs that exact command (plus `--ignore-submodules=none`) with the checkout's git. On any git failure, any stderr, or a record raw_records rejects, it prints `refuse index: …`. E3's unmerged index (stages 2 and 3 for f.txt) printed `refuse index: the staged changes against 688cfae1… could not be listed`, exit 2. This is paraphrased because the code is quoted in Claim 3.

**Evidence:** `scripts/build-loop.sh:1809-1813`, E3

---

## Claim 6: "Questions rule … over both questions files together (an archive move is no change), each entry as `--check-answer` delimits it (FENCE_AWK first; a refused file refuses), its key lines are its heading, its `**Needs:**` lines and its answer lines (ANSWERS_AWK's labels, any ID). An entry on the base whose key lines differ in the index, or that is gone, refuses unless its ID is in `--answered`; a new entry is free unless it is filed answered (Status ANSWERED or an answer line) … Body lines are free"

**Location:** `docs/working/plan-build-loop-handoff.md:330`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the rule as cycle_diff now runs it (d77dae74 makes "differ" include order), checked in E1, E2 and E6. It does not establish the whole-file refusals ANSWER_AWK adds (dup, quoted), which QKEYS_AWK lacks: A6, Won't Fix, fail-safe (see Claim 11).

QDIFF_AWK compares each base ID's concatenated key lines with the index's:

```awk
# scripts/build-loop.sh:1768-1773 (QDIFF_AWK's main rules and END, to the program's end; answered() at :1760-1765 and BEGIN at :1766 read)
FILENAME == ARGV[1] { o[id] = o[id] "\n" k l; of[id] = $2; next }
{ nw[id] = nw[id] "\n" k l; nf[id] = $2; if (answered(k, l)) an[id] = 1 }
END {
  for (id in o) if (!(id in ok) && o[id] != nw[id]) print id " " ((id in nf) ? nf[id] : of[id]) " gone"
  for (id in nw) if (!(id in o) && !(id in ok) && an[id]) print id " " nf[id] " new"
}'
```

In E1, T38 passes: the flip, the route change, the removed answer line, the deleted entry, the swap and the deleted archive all refuse; body edits, a new open entry and the archive move pass. In E6, mutant m1 (the pre-fix sort) fails the swap case. That is iteration 1's A1, now fixed.

E2 compared `--cycle-diff` with `dev-cycle.sh --check-answer` before and after landing. Each of these turns check_answer's reading into keep, or reads as answered, and `--cycle-diff` refused each one without `--answered`:
- unfencing an earlier answer line (drop → keep)
- removing a `## ` heading between Needs and the answer (unrecognized → keep)
- swapping two Needs lines (open → keep)
- a new entry whose Status field has a trailing tab (keep)

A duplicate heading refused as well, which check_answer skips.

**Evidence:** `scripts/build-loop.sh:1738-1773`, `scripts/build-loop.sh:1833-1860`, `scripts/lib/dev-cycle-read.sh:2058-2111`, E1, E2, E6 (m1)

---

## Claim 7: "Refused instead: the idea log edited other than by appending … the roadmap's lines above its first `## ` heading, or its `## ` heading lines, changed; a brief file name a roadmap line outside Done names on the base that no line names in the index (check 1 moves a brief's line to Done or Ideas and points it at `closed/`; it never drops one). Every other path is not judged"

**Location:** `docs/working/plan-build-loop-handoff.md:331`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three roadmap refusals, the exemption for Done, `closed/` names counting as the same brief, two briefs on one line, CRLF, and the idea-log prefix rule. It does not establish that SKILL.md step 6 never rewrites a heading or the preamble in a real cycle; that is the interim reading this bullet names.

Check 1's text in `skills/dev-cycle/SKILL.md:290-292` reads: "`git mv` the brief there … and point the roadmap line there". Its Done item reads "items finished since the last cycle" (`:330`). Together these support "never drops one" outside Done.

In E5:
- Dropping the second of two briefs on one line refused `the brief b.md …`.
- A CRLF-only rewrite passed.
- Dropping a Done line passed.
- A brief named only under Done in the index passed. Named on any line counts.

In E1, the T38 roadmap test passed: it checks the preamble, a heading, the dropped line, an idea-log edit, a deletion and a symlink.

**Evidence:** `scripts/build-loop.sh:1774-1794`, `scripts/build-loop.sh:1821-1831`, `skills/dev-cycle/SKILL.md:283-292`, `skills/dev-cycle/SKILL.md:330`, E1, E5

---

## Claim 8: "One `raw_records` helper (row 724) reads every `--raw -z` listing whole: check_line, log_class's chore and answers loops, and `--cycle-diff`."

**Location:** `docs/working/plan-build-loop-handoff.md:332`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the four call sites. It does not establish exact equivalence of the chore loop; see Claim 2.

The four `--raw -z` listings each feed raw_records (`scripts/build-loop.sh:1316`, `:1702`, `:1709`, `:1811`). This is paraphrased because the call sites are quoted in Claim 2.

**Evidence:** `scripts/build-loop.sh:967-978`, `scripts/build-loop.sh:1316`, `scripts/build-loop.sh:1702`, `scripts/build-loop.sh:1709`, `scripts/build-loop.sh:1811`

---

## Claim 9: "Health-check lock … `scripts/health-check.sh`'s main takes `flock` on `$(git rev-parse --git-common-dir)/health-check.lock` (plain file only, as the dispatch lock), printing one line when it waits; a run inside a run … is exempt through an exported variable, or it would wait on itself."

**Location:** `docs/working/plan-build-loop-handoff.md:333`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the lock path, the plain-file refusal, the wait line and the nested-run exemption. It does not establish behaviour when flock cannot open the file (that exits with flock's own status, unreported here).

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

The dispatch lock uses the same plain-file test: `[[ -L "$lk" || ( -e "$lk" && ! -f "$lk" ) ]]` (`scripts/build-loop.sh:1919`). In E1, T43 passes. In E8, mutant m5 (no exemption) hung T43 until `timeout 300` killed it. "It would wait on itself" holds: the child's own `flock -n` meets the lock its parent flock holds.

**Evidence:** `scripts/health-check.sh:1094-1121`, `scripts/build-loop.sh:1918-1921`, E1, E8 (m5)

---

## Claim 10: "--cycle-diff … after --state's gate but its caller check: the index against BASE, the fork point of HEAD and the default branch's commit (git merge-base …). Prints ok, or one line per finding and exit 2"

**Location:** `scripts/build-loop.sh:183-188`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the gate order (state_gate, then state_start, with caller_gate for --state only), the ok/exit-2 contract and one line per finding. It does not establish the usage-error path beyond the three shapes T38 tests (exit 1, empty stdout).

`if [[ "$MODE" == state ]]; then caller_gate || exit 2; fi` and `if [[ -n "$GATED" ]]; then state_gate || exit 2; fi` (`scripts/build-loop.sh:650-651`). cycle-diff is gated because it is not in `^(settings|status|marker)$` (`:648`). The mode then runs `state_start; cycle_diff || exit 2; echo ok` (`:1875-1879`). In E1 and E3, findings print one line each with exit 2; E1's roadmap case prints three.

**Evidence:** `scripts/build-loop.sh:648-651`, `scripts/build-loop.sh:1257-1263`, `scripts/build-loop.sh:1875-1879`, E1, E3

---

## Claim 11: "an entry on BASE whose heading, **Needs:** lines or answer lines (--main-log's answer labels, any ID) differ in the index, in order, or are gone, and a new entry filed answered (Status ANSWERED or an answer line), unless its ID was given with --answered …; an entry's other lines are free. Entries are delimited as --check-answer reads them, and a copy FENCE_AWK refuses refuses."

**Location:** `scripts/build-loop.sh:191-200`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the entry boundaries (a `### Q-N` heading start, an end at `#`/`##`/`###` + space, fenced lines skipped, a trailing CR dropped before FENCE_AWK) and the key-line labels match ANSWER_AWK, and that no shape probed lets a changed check_answer reading through. It does not establish ANSWER_AWK's whole-file "dup" and "quoted" refusals, which QKEYS_AWK lacks (A6, Won't Fix). Both make check_answer skip, which is fail-safe.

Side by side:
- QKEYS_AWK: `/^### Q-[0123456789]+([ \t]|$)/ { id = …` then `/^(#|##|###) / { id = ""; next }` (`:1747-1748`).
- ANSWER_AWK: `heading(l)` accepts `h == id || index(h, id " ") == 1 || index(h, id "\t") == 1`, then `/^(#|##|###) / { inside = 0; next }` (`scripts/lib/dev-cycle-read.sh:2073-2082`).

Both run `{ sub(/\r$/, "") }` before `fence($0)`. QKEYS_AWK tags every Needs line and any-ID answer line. check_answer reads the first Needs line and the first own-ID or label line, a subset of the tagged lines.

Per key line, "answered" is `k == "a"` or a trimmed `**Status:** ANSWERED` field (`:1760-1765`). check_answer takes the last Status field with only trailing blanks trimmed (`:2084-2088`). Any entry check_answer reads as answered also reads as answered here; the reverse is not needed.

The E2 shapes (Claim 6) all refused. The only case where check_answer's reading moved without a key-line change was the duplicate heading, which check_answer skips.

**Evidence:** `scripts/build-loop.sh:1738-1772`, `scripts/lib/dev-cycle-read.sh:2058-2111`, `scripts/lib/dev-cycle-read.sh:2116-2148`, E1, E2

---

## Claim 12: "docs/working/idea-log.md changed other than by appending (BASE's bytes start the index's), or deleted."

**Location:** `scripts/build-loop.sh:201-202`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the prefix test, the size guard, deletion and a type change. It does not establish behaviour for an idea log that is new on the index (not judged, Claim 14).

```bash
# scripts/build-loop.sh:1824-1827 (in cycle_diff's record loop, which ends :1832, read)
    elif [[ "$p" == docs/working/idea-log.md ]]; then
      # Seeding and "## Brainstorm" only append: the base's bytes start the index's.
      k="$(wc -c < "$t.o")"
      [[ "$(wc -c < "$t.n")" -ge "$k" ]] && cmp -s -n "$k" "$t.o" "$t.n" || { echo "refuse $p: edited other than by appending"; bad=1; }
```

A deletion reaches `[[ "${RAW_S[i]}" == D ]]` first (`:1823`). SKILL.md says "append `## Brainstorm YYYY-MM-DD` to the idea log" (`skills/dev-cycle/SKILL.md:257`). In E1, the append passes, an edit refuses and a symlink refuses. In E3, an append passes.

**Evidence:** `scripts/build-loop.sh:1821-1831`, `skills/dev-cycle/SKILL.md:257`, E1, E3

---

## Claim 13: "docs/roadmap.md deleted, its lines above the first "## " heading or its "## " heading lines changed, or a brief file (docs/working/briefs/[closed/]NAME.md) a line outside "## Done" names on BASE named on no line of the index"

**Location:** `scripts/build-loop.sh:203-208`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers ROADMAP_AWK's three refusals and deletion. It does not establish that brief paths in another form (no `docs/working/briefs/` prefix, or a subdirectory other than `closed/`) are read; they are not matched.

```awk
# scripts/build-loop.sh:1780-1793 (ROADMAP_AWK, whole program body)
{ sub(/\r$/, ""); s = (FILENAME == ARGV[1]) ? 1 : 2 }
/^## / { h[s] = h[s] "\n" $0; sec[s] = $0; in2[s] = 1; next }
!in2[s] { p[s] = p[s] "\n" $0; next }
{
  r = $0
  while (match(r, /docs\/working\/briefs\/(closed\/)?[A-Za-z0-9._-]+\.md/)) {
    b = substr(r, RSTART, RLENGTH); sub(/.*\//, "", b); r = substr(r, RSTART + RLENGTH)
    if (s == 2) named[b] = 1; else if (sec[1] != "## Done") need[b] = 1
  }
}
END {
  if (p[1] != p[2]) print "its lines above the first ## heading changed"
  if (h[1] != h[2]) print "its ## headings changed"
  for (b in need) if (!(b in named)) print "the brief " b ", named outside Done on the base, is named on no line"
}'
```

Results in E1 and E5 are in Claim 7.

**Evidence:** `scripts/build-loop.sh:1774-1794`, `scripts/build-loop.sh:1829-1830`, E1, E5

---

## Claim 14: "A new roadmap or idea log, and every other path, is not judged (a new questions file is: its entries are new)."

**Location:** `scripts/build-loop.sh:209-210`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the absent-base skip for the roadmap and idea log, and the path through new-entry checks for a new questions file. It does not establish anything about the paths that are not judged.

`if [[ "${RAW_OM[i]}" == 000000 ]]; then continue; fi` (`:1822`) skips a new roadmap or idea log. Questions paths are collected before that line (`:1817`). In the second loop, cyc_blob turns an absent old side into an empty file (`if [[ "$md" == 000000 ]]; then : > "$3"; return 0; fi`, `:1802`), so every entry in a new questions file reaches QDIFF_AWK as new.

**Evidence:** `scripts/build-loop.sh:1799-1804`, `scripts/build-loop.sh:1814-1822`, `scripts/build-loop.sh:1834-1845`

---

## Claim 15: "One of these files not a regular file, or a read that fails, refuses; so do HEAD with no merge base ("refuse HEAD") and an index that cannot be listed ("refuse index")."

**Location:** `scripts/build-loop.sh:210-213`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the refusals for a non-regular side, the HEAD and index refusals, and one read path that does not refuse (an unchanged questions file whose base read fails). It does not establish behaviour under other kinds of object-store damage.

**What holds.** A symlink, a mode-100755 file and a deleted file each refuse (E1, E3). So do no merge base (E1) and an unmerged index (E3).

**The exception.** For a questions file the index leaves unchanged, a failed existence probe is read as absent, not as a failed read:

```bash
# scripts/build-loop.sh:1840-1844 (the unchanged-file branch; the files loop ends :1851, read)
    elif gate_git cat-file -e "$base:$f" 2>/dev/null; then
      [[ "$(gate_git ls-tree "$base" -- "$f" | cut -c1-6)" == 100644 ]] && gate_git cat-file blob "$base:$f" > "$t.o" \
        || { echo "refuse $f: not a regular file on the base, or could not be read"; return 1; }
      cp "$t.o" "$t.n"
    else continue; fi
```

In E7, the base's archive blob was deleted. Main had moved, so state_start's store_check passed on main's tree. With only questions.md changed, the run printed `ok`, exit 0, instead of refusing. The impact is small: an unchanged file is identical on both sides, and any entry moved into or out of it makes it changed.

**A wording nit.** cyc_blob refuses any mode but 100644, so a mode-100755 file (a regular file) also gets "a side is not a regular file". cyc_blob's own comment says "a regular 100644 file". The precise header would say "not a 100644 file, or a read that fails (an unchanged questions file whose base copy cannot be probed is skipped)".

**Evidence:** `scripts/build-loop.sh:1795-1803`, `scripts/build-loop.sh:1834-1845`, E1, E3, E7

---

## Claim 16: "As --main-log, it reads BASE's objects without re-hashing them: it catches the orchestrator's own slip, not a forged commit."

**Location:** `scripts/build-loop.sh:213-215`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that store_check runs only on main's commit (`state_start`), never on BASE or the index blobs. It does not establish the security claim about forgery.

`store_check --main "$MAIN_SHA"` is state_start's only hash check (`:1261`). cycle_diff calls no store_check. This is paraphrased because it is established by the absence of any store_check call in cycle_diff, `:1806-1860`.

**Evidence:** `scripts/build-loop.sh:1257-1263`, `scripts/build-loop.sh:1806-1860`

---

## Claim 17: raw_records: "RAW_OM and RAW_NM (modes), RAW_OO and RAW_NO (ids), RAW_S (A, M, D or T) and RAW_P (paths), in git's order. Returns 1 when a record does not parse or the NULs are not two per record (bytes after the last NUL are not counted …)."

**Location:** `scripts/build-loop.sh:967-971`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the parse, the arrays and the return contract. It does not establish that callers reset nothing else (callers copy the arrays right away).

```bash
# scripts/build-loop.sh:973-978 (raw_records, whole)
raw_records() {
  local meta p
  RAW_OM=(); RAW_NM=(); RAW_OO=(); RAW_NO=(); RAW_S=(); RAW_P=()
  while IFS= read -r -d '' meta && IFS= read -r -d '' p; do
    [[ "$meta" =~ ^:([01234567]{6})\ ([01234567]{6})\ ([0123456789abcdef]+)\ ([0123456789abcdef]+)\ ([AMDT])$ ]] || return 1
```

(Excerpt ends at :977; raw_records continues to :980, read: the array appends and the NUL-count test that is its return value.)

**Evidence:** `scripts/build-loop.sh:967-980`

---

## Claim 18: check_line's refusal "the paths the merge of $br changes could not be read" is unchanged in text and condition

**Location:** `scripts/build-loop.sh:1316`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the refusal text, the regex, the NUL-count condition and the ids list match main's loop. It does not establish --merge's later use of the arrays beyond the copies made here.

`raw_records "$GATE_TMP/diff" || { echo "refuse $a: the paths the merge of $br changes could not be read"; return; }` (`:1316`). The same message was printed by both of main's failure points (main's copy, `:1263` and `:1269`). The regex differs only in the added `RAW_OO` capture. `ids` is rebuilt from `nms`/`nos` with the same mode test (`:1318`).

**Evidence:** `scripts/build-loop.sh:1313-1318`, `git show main:scripts/build-loop.sh` (check_line loop)

---

## Claim 19: QKEYS_AWK: "'ID F K LINE' (tab-separated) per key line of an entry, as --check-answer delimits one: K is h for its heading, n for a **Needs:** line, a for an answer line (ANSWERS_AWK's labels, any ID); F names the file. Then 'odd' or 'unbalanced' when FENCE_AWK refuses the file."

**Location:** `scripts/build-loop.sh:1738-1742`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the output format and the FENCE_AWK lines, and that cycle_diff refuses any line that does not start with `Q-` (`:1848`). It does not establish ANSWER_AWK's dup and quoted refusals (A6).

`END { if (odd) print "odd " odd " " oddwhy; else if (infence) print "unbalanced " fline }` (`:1752`). The labels `t ~ /^Q-[0123456789]+:/ || tolower(t) ~ /^\*\*answer(:|ed| \()/` (`:1751`) are ANSWERS_AWK's (`:1658`). In E1, T38's FENCE_AWK case printed `refuse docs/working/questions.md: FENCE_AWK refuses its index copy (unbalanced 9)`.

**Evidence:** `scripts/build-loop.sh:1744-1752`, `scripts/build-loop.sh:1643-1662`, `scripts/build-loop.sh:1846-1849`, E1

---

## Claim 20: QDIFF_AWK: "each side questions.md's then the archive's … An entry's key lines are compared in file order (--check-answer reads the first Needs and the first answer line, so a reorder can change its result: i1 A1) and without F, so an archive move is no change."

**Location:** `scripts/build-loop.sh:1753-1757`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the order-preserving comparison, F left out, and that a whole-entry move between files passes. It does not establish the case where one ID has copies in both files on one side; check_answer skips that case.

The files loop appends questions.md's key lines, then the archive's, to each side (`for f in docs/working/questions.md docs/working/questions-archive.md`, `:1836`; `cat "$t.k" >> "$t.q$p"`, `:1849`). With no sort in between, QDIFF_AWK builds `o[id]`/`nw[id]` from `k l` (no `$2`). In E1, the archive move passes and the swap refuses. In E6, m1 (sorted) passes the swap, so the order matters.

**Evidence:** `scripts/build-loop.sh:1753-1772`, `scripts/build-loop.sh:1834-1852`, E1, E6

---

## Claim 21: ROADMAP_AWK: "one WHY per line. The lines above the first "## " heading and the heading lines stay; a brief file a line outside "## Done" names on the base is named on some line of the index."

**Location:** `scripts/build-loop.sh:1774-1777`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claim 13. It does not establish anything about a `##` heading line with no space (a heading in CommonMark, not to this awk).

The program is quoted in Claim 13. In E1 and E5, each finding printed as its own `refuse docs/roadmap.md: WHY` line.

**Evidence:** `scripts/build-loop.sh:1780-1794`, `scripts/build-loop.sh:1828-1830`, E1, E5

---

## Claim 22: cyc_blob: "an absent side (mode 000000) is an empty file. Returns non-zero when that side is not absent or a regular 100644 file, or the read fails."

**Location:** `scripts/build-loop.sh:1795-1798`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers cyc_blob's own contract. It does not establish the unchanged-file branch, which does not use cyc_blob (Claim 15).

```bash
# scripts/build-loop.sh:1799-1804 (cyc_blob, whole)
cyc_blob() {
  local md="${RAW_NM[$1]}" id="${RAW_NO[$1]}"
  [[ "$2" == new ]] || { md="${RAW_OM[$1]}"; id="${RAW_OO[$1]}"; }
  if [[ "$md" == 000000 ]]; then : > "$3"; return 0; fi
  [[ "$md" == 100644 ]] && gate_git cat-file blob "$id" > "$3"
}
```

In E3, mode 100755 refused. In E1, a symlink refused.

**Evidence:** `scripts/build-loop.sh:1799-1804`, E1, E3

---

## Claim 23: "The checkout's own git, for its index (state_gate has run on it)."

**Location:** `scripts/build-loop.sh:1809`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that diff-index runs with plain `git` (the checkout) and that cycle-diff is a gated mode. It does not establish what state_gate checks.

`git diff-index --cached …` uses plain `git`, not `gate_git` (`:1810`). GATED is set for cycle-diff (`:648`), so `state_gate || exit 2` runs first (`:651`).

**Evidence:** `scripts/build-loop.sh:648-651`, `scripts/build-loop.sh:1809-1813`

---

## Claim 24: "Both questions files on each side, the unchanged one included (an entry can move between them)."

**Location:** `scripts/build-loop.sh:1834`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that an unchanged file is read from BASE onto both sides. It does not establish the failed-probe case (Claim 15), where the unchanged file is skipped.

The unchanged branch reads `$base:$f` and runs `cp "$t.o" "$t.n"` (`:1841-1843`); the code is quoted in Claim 15. In E1, the T38 cases that change only questions.md keep Q-000 (unchanged archive) on both sides, and pass where expected.

**Evidence:** `scripts/build-loop.sh:1834-1845`, E1

---

## Claim 25: "HEALTH_CHECK_LOCK_HELD   Set for the run that holds health-check.lock (one run at a time per repository: take_lock), so a run it starts takes no lock and never waits on it."

**Location:** `scripts/health-check.sh:27-29`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the export and the early return. It does not establish behaviour when a caller sets the variable outside a run; that run then takes no lock.

`export HEALTH_CHECK_LOCK_HELD=1` comes before the flock call, and `[[ -z "${HEALTH_CHECK_LOCK_HELD:-}" ]] || return 0` (`:1108`, `:1114`); quoted whole in Claim 9. In E1, the T43 nested case passes. In E8, m5 hangs.

**Evidence:** `scripts/health-check.sh:1106-1121`, E1, E8

---

## Claim 26: "flock on health-check.lock in the common git dir, waiting for a run that holds it. A run inside a run … inherits HEALTH_CHECK_LOCK_HELD and takes no lock … Outside a git repository there is nothing to share. Only a plain file is locked (a FIFO would block), as build-loop.sh's dispatch lock."

**Location:** `scripts/health-check.sh:1094-1101`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers serialization, the wait, the nested exemption, the run outside a repository and the FIFO refusal. It does not establish that "nothing to share" holds for a script copy outside any repository that other runs share by path.

In E1, T43 test 1 shows serialization and the wait line, and test 2 shows the FIFO refusal. In E4, with GIT_CEILING_DIRECTORIES stopping discovery, the run outside a repository finished (exit 1 from the copy's missing skill files): no wait line and no lock file. The take_lock code is quoted in Claim 9.

**Evidence:** `scripts/health-check.sh:1094-1121`, E1, E4

---

## Claim 27: "flock(1) holds the lock in its own process and runs this script again as its child with the lock's descriptor closed (-o): no suite, and nothing a test leaves running, inherits the lock, so it ends with this run. Exit 75 is flock's "held elsewhere" (-E), which this script never exits with."

**Location:** `scripts/health-check.sh:1101-1105`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers that the runner holds no lock descriptor, that a leftover process does not hold the lock, that a failing run's status passes through flock, and that the script's explicit exits are only 0 or 1. It does not establish that no command can end the run with 75 through `set -euo pipefail` (`:47`), which passes any failing command's status. None of its commands is known to exit 75, hence Medium.

In E4, the stub runner saw 0 descriptors naming health-check.lock in `/proc/$$/fd`. The run's status (1) came back through flock. In E6, m2 (the old `exec 8>>`) fails T43's leftover-process case, and HEAD passes it in E1. The script's own exits are `exit 1` (`:1112`), `exit "$rc"` (`:1120`) and `exit "$FAIL"` (`:1150`), with FAIL only 0 or 1 (`FAIL=0`, `:58`; `FAIL=1` in `fail()`, `:68`).

**Evidence:** `scripts/health-check.sh:47`, `scripts/health-check.sh:58`, `scripts/health-check.sh:68`, `scripts/health-check.sh:1106-1121`, `scripts/health-check.sh:1150`, E1, E4, E6

---

## Claim 28: T38 questions test: name "refuses an entry's header or answer changed or gone without --answered, and passes body edits, an open new entry and an archive move"; comments "A route change, a removed answer line, a deleted entry, two answer lines swapped"; "Free: body lines, an appended open entry, Q-003 archived (moved whole between the files)."

**Location:** `test/scripts/build-loop-orchestrator.bats:400-424`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test name and the two block comments against the lines under them. It does not establish coverage beyond these cases.

The test name holds, and the test passes (E1). Two comments are imprecise:

- **The `:408` comment lists four cases; its block runs five.** After the route change and the removed answer line comes `git rm -q docs/working/questions-archive.md; cd_is "${W0/questions.md/questions-archive.md}"` (`:414`), a deleted archive, which the comment does not name. The block also runs its cases in a different order from the list (deleted entry, swap, route, removed answer, deleted archive).
- **The `:415` comment's "an appended open entry" ends up in the archive.** `printf … '### Q-002 · y' … >> docs/working/questions.md` appends Q-002 after Q-003. Then `sed -n '/^### Q-003/,$p'` (`:417`) moves Q-003 and Q-002 together into the archive. The case still shows a new open entry passing, but not in questions.md.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:400-424`, E1

---

## Claim 29: T38 roadmap test name and "Step 6's rewrites: Next reworded, Done trimmed, X moved to Done at closed/, an idea appended, any other path."; T43's header and test names

**Location:** `test/scripts/build-loop-orchestrator.bats:426-444`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the roadmap test's name and comment, the T43 header ("each test copies the script and the libs … check 5's runner stubbed"), and the two T43 names, each against its assertions. It does not establish T43's timing margins under load.

**Roadmap test.** `sed -i 's/^1\. n/1. m/; /2026-09-01-y/d; /2026-10-01-x/d'` and then `echo '- X done: …closed/2026-10-01-x.md' >> docs/roadmap.md` (`:431`) do what the comment lists. The appended line falls after `## Done`.

**T43 test 1** asserts in/out order and the wait line (`test/scripts/health-check-lock.bats:24-25`).

**T43 test 2** covers three things:
- the nested run (`:33-34`)
- a run whose `--slow` stub leaves `sleep 5` (`:37-38`)
- a FIFO (`:39-41`)

All four tests pass (E1). In E8, m4 (no take_lock) fails both T43 tests.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:426-444`, `test/scripts/health-check-lock.bats:1-42`, `scripts/health-check.sh:392`, `scripts/health-check.sh:400`, E1, E8

---

## Claim 30: Commit 3021d0a4 body: "route change, deleted entry, removed answer line and a deleted archive refuse … mutants run: base = MAIN_SHA fails T38 at the main-moved line; no take_lock and no nested-run exemption each fail T43."

**Location:** commit `3021d0a4` message body (bare locator; no in-file line)
**Type:** Behavioral / Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test cases present at 3021d0a4 and the three mutants re-run on HEAD's tests. It does not establish that the mutants failed in the same way on 3021d0a4's own tests.

**The case list.** At 3021d0a4, T38's questions block had three refusal cases: a route change, a removed answer line (`/^Q-003/d`), and the archive `git rm`. It had no separate deleted-entry case. That case arrived in d77dae74 (`sed -i '/^### Q-001/,/^| \*\*\[1\]/d'`). So "deleted entry" lists a case the commit did not hold; iteration 1's claim 31 found the same.

**The mutants**, re-run in E8:
- m3 (base = MAIN_SHA) fails at the main-moved line (`:407`).
- m4 (no take_lock) fails both T43 tests.
- m5 (no exemption) hangs T43 until `timeout 300` kills it (exit 124). A hang is a failure, but not an assertion failure.

**Evidence:** `git show 3021d0a4:test/scripts/build-loop-orchestrator.bats` (the T38 questions block), `test/scripts/build-loop-orchestrator.bats:407-409`, E8

---

## Claim 31: Commit f34fceb0 body: "questions entries' heading, Needs and answer lines change only for --answered IDs, a new entry is never filed answered without one; the idea log only appends; the roadmap keeps its preamble and headings and never drops a brief named outside Done. raw_records reads every --raw -z listing whole … health-check.sh takes a flock on health-check.lock in the common git dir … waiting; a nested run is exempt."

**Location:** commit `f34fceb0` message body (bare locator; no in-file line)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the claim against HEAD's code. It does not clear f34fceb0's own tree: there the sorted comparison let a swap of two answer lines through (iteration 1's claim 32, Incorrect), and its take_lock used `exec 8>>`, which 414c9295 replaced. The commit message cannot be amended; d77dae74 made it true of the branch.

At HEAD, each part holds: Claims 6, 11 and 20 for the questions rule, 12 for the idea log, 13 for the roadmap, 8 for raw_records, and 9 and 25 for the lock. Each of those is executed (E1-E8), so this is paraphrased because it summarizes those claims' quoted evidence.

**Evidence:** `scripts/build-loop.sh:1738-1860`, `scripts/health-check.sh:1106-1121`, E1, E2, E5, E6

---

## Claim 32: Commit 414c9295 body: "With exec 8>> every suite and any process a test left running inherited the lock's descriptor … flock -o now holds the lock and runs the script again as its child with the descriptor closed; -E 75 tells "held elsewhere" from the run's own status. T43 gains the leftover-process case (red on the exec version)."

**Location:** commit `414c9295` message body (bare locator; no in-file line)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the old mechanism (`git show f34fceb0:scripts/health-check.sh`), the new one, and the mutant result. It does not establish other leftover shapes, such as a daemon that reopens the file.

f34fceb0's take_lock ran `exec 8>>"$lk"` and then `flock -n 8 || { yellow …; flock 8; }` in the script's own shell, so every child inherited fd 8. In E6, mutant m2 fails T43 test 2 at `[[ "$output" != *waiting* ]] && grep -qx "out q" "$L"`, and HEAD passes it (E1).

**Evidence:** `git show f34fceb0:scripts/health-check.sh` (take_lock), `scripts/health-check.sh:1106-1121`, `test/scripts/health-check-lock.bats:36-38`, E1, E6

---

## Claim 33: Commit d77dae74 body: "Sorting each side's key lines lost their order inside an entry … two swapped answer lines turned drop into keep and passed with no --answered (i1 fact-check claims 4, 10, 32, executed). The sides are now compared as read, questions.md's lines then the archive's, so a move between the files stays free. T38 gains the swap and a deleted-entry case (the swap is red on the sorting code). … A3-A5: test and header text (a new questions file is judged; cyc_blob's absent side is mode 000000)."

**Location:** commit `d77dae74` message body (bare locator; no in-file line)
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the fix, the two added cases, the mutant, the i1 references and the header and comment edits. It does not establish that no other shape reaches a changed check_answer reading, though none was found (Claims 6 and 11).

d77dae74 removes `LC_ALL=C sort -o "$t.qo" "$t.qo" && LC_ALL=C sort -o "$t.qn" "$t.qn" \` and adds the swap and deleted-entry lines (`:409`, `:410`). In E6, m1 (the sorted version) passes the swap and fails T38 there. Iteration 1's claims 4, 10 and 32 are each marked `**Verification mode:** executed` in `docs/reviews/code-fact-check-report-2026-10-12-u3c-i1.md`. The header now reads "A new roadmap or idea log, and every other path, is not judged (a new questions file is: …)" (`:209-210`), and cyc_blob's comment reads "(mode 000000)" (`:1796`).

**Evidence:** `git show d77dae74`, `scripts/build-loop.sh:209-210`, `scripts/build-loop.sh:1796`, `test/scripts/build-loop-orchestrator.bats:409-410`, E6

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 2** (`docs/reviews/override-log.md:746`): the chore loop changes in two ways, not one. An unparsed record or an incomplete record (an odd NUL count) now makes the commit other. Say "an unparsed or incomplete record".
- **Claim 15** (`scripts/build-loop.sh:210-213`): "a read that fails, refuses" has one exception. For a questions file the index leaves unchanged, a failed `cat-file -e` on BASE is read as absent and skipped (E7: `ok`). The impact is low. Also, "not a regular file" is really "not mode 100644", since a 100755 file is refused too.
- **Claim 28** (`test/scripts/build-loop-orchestrator.bats:408`, `:415`): the `:408` case-list comment leaves out the deleted-archive case it runs. The "appended open entry" at `:415` is moved into the archive along with Q-003.
- **Claim 30** (commit 3021d0a4): it lists a "deleted entry" case the commit did not hold (added in d77dae74). The nested-run mutant hangs T43 rather than failing an assertion. This is history and cannot be fixed (iteration 1's claim 31).

### Unverifiable
(none)

## Escalations

None at blocking grade.

**Brief item 2** asked whether an answer `--check-answer` would read as keep can reach the index without its ID in `--answered`. E2 ran six adversarial shapes against the real `--check-answer` after landing: an unfenced answer line, a removed heading between Needs and the answer, swapped Needs lines, a duplicate heading, a new entry with a trailing-tab Status, and a new open entry carrying an answer label. In every case where check_answer's reading moved to keep, `--cycle-diff` had refused. The remaining divergences from ANSWER_AWK (dup and quoted) only make check_answer skip (A6).

**Goal-alignment note.** The branch does what the brief's goal states. The two interim calls hold under test: the fork-point base (Claim 4, with m3 showing why) and the reading of the roadmap's "moves" (Claim 7). The one gap found, Claim 15's unchanged-file read, needs a damaged object store and changes no entry's reading.
