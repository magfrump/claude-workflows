Commit: 414c9295

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u3c (branch `feat/build-loop-u3c`)
**Scope:** branch diff `main...414c9295` (main = dafc0e74): `docs/working/plan-build-loop-handoff.md` (the U3c bullet), `scripts/build-loop.sh` (the `--cycle-diff` header, raw_records, check_line, log_class, QKEYS_AWK, QDIFF_AWK, ROADMAP_AWK, cyc_blob, cycle_diff), `scripts/health-check.sh` (take_lock and its env doc), `test/scripts/build-loop-orchestrator.bats` (the two T38 tests), `test/scripts/health-check-lock.bats` (T43), and the messages of 6f347256, 3021d0a4, f34fceb0, 414c9295.
**Checked:** 2026-10-12 (execution timestamps below are UTC, 2026-10-13T05:15Z-05:19Z)
**Commit:** 414c9295
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 33
**Summary:** 22 verified, 7 mostly accurate, 0 stale, 4 incorrect, 0 unverifiable

I read the hallucination-pattern log (`docs/reviews/hallucination-patterns.md`). No claim here matches a logged pattern, and no fabricated symbol, API or flag turned up: the four Incorrect verdicts are one behaviour mismatch, quoted in three places, plus one test comment. The log is not edited. The brief allows writing only this file.

**Execution runs.** All logs are under `S=/tmp/claude-1000/-workspace/f335f5f6-1b17-4519-891d-602641cba507/scratchpad/fc-u3c-i1`. Every fixture repo was created under `$S/p-*` (probes) or `/tmp/u3c-fc-u3c-i1-*` (the suites). The worktree was only read.

- **E1** (2026-10-13T05:15:18Z), cwd `/workspace/.claude/wt-build-loop-u3c`: `TMPDIR=$(mktemp -d /tmp/u3c-fc-u3c-i1-XXXX) timeout 600 bats -f 'cycle-diff' test/scripts/build-loop-orchestrator.bats`. Exit 0, both T38 tests ok. Log: `$S/logs/t38.log`.
- **E2** (same call, right after E1), cwd the worktree: `TMPDIR=$(mktemp -d /tmp/u3c-fc-u3c-i1-XXXX) timeout 300 bats test/scripts/health-check-lock.bats`. Exit 0, both T43 tests ok. Log: `$S/logs/t43.log`.
- **E3** (2026-10-13T05:16:00Z): `bash $S/run-probe.sh`, which makes `$S/p-XXXX`, cds into it, sets TMPDIR there and runs `bats --show-output-of-passing-tests $S/probe.bats` (probes P1-P9, each in a fresh `bl_setup` repo). Exit 1, because P7's fixture lacked `mkdir docs`. Every other probe printed its result. Log: `$S/logs/probe.log`. **E3b** (05:16:07Z): `bash $S/run-probe.sh -f P7` after the fixture fix. Exit 0. Log: `$S/logs/probe-p7.log`.
- **E4** (2026-10-13T05:16:27Z): `bash $S/mutants.sh`. Each mutant runs in its own `$S/p-XXXX/mN` copy of `scripts/` and `test/`. M1 restores f34fceb0's health-check.sh (the `exec 8>>` take_lock). M2 drops the `take_lock "$@"` call. M3 drops the nested-run exemption line. M4 makes `base="$MAIN_SHA"`. Exit 0 for the script; the mutant results are in the log. Log: `$S/logs/mutants.log`.
- **E5** (~05:18Z): `bash $S/live-keys.sh`. It runs `FENCE_AWK` + `QKEYS_AWK` over HEAD's two questions files and counts entries that have two or more answer lines or Needs lines. Exit 0. Log: `$S/logs/live-keys.log`.

---

## Claim 1: "Base: the fork point, not MAIN_SHA. … the index is compared with `git merge-base HEAD MAIN_SHA` (MAIN_SHA itself when main has not moved). That is exactly what the chore branch adds when it lands, its earlier commits included … No merge base (HEAD unborn or unrelated) refuses."

**Location:** `docs/working/plan-build-loop-handoff.md:328`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the base computation, main moving after the fork (T38), main merged into the chore branch with an earlier chore commit (P6), HEAD on main and detached (P4), and unborn HEAD (the T38 orphan case). It does not establish the unrelated-history case by execution (it is static: merge-base exits non-zero), or which base `git merge-base` prints when there are several merge bases (criss-cross).

The code is `if ! base="$(git merge-base HEAD "$MAIN_SHA" 2>/dev/null)"; then echo "refuse HEAD: it shares no commit with the default branch's $MAIN_SHA, or could not be read"; return 1; fi` (`scripts/build-loop.sh:1804`).

- **P6 (E3):** the chore branch commits an idea-log rewrite, then main moves and is merged into the chore branch. merge-base then equals main's tip, and `--cycle-diff` still prints `refuse docs/working/idea-log.md: edited other than by appending`, so the earlier chore commit is judged.
- **M4 (E4, base = MAIN_SHA):** T38 fails at line 407, the main-moved line, with `refuse docs/working/questions.md: Q-003 is a new entry filed answered …`. It also fails the orphan case, which then prints `ok`.

**Evidence:** `scripts/build-loop.sh:1802-1809`, `test/scripts/build-loop-orchestrator.bats:405-407,440-441`, `$S/logs/probe.log` (P4, P6), `$S/logs/mutants.log` (M4)

---

## Claim 2: "The index only (`git diff-index --cached --raw -z --no-renames` in the checkout)"

**Location:** `docs/working/plan-build-loop-handoff.md:329`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the listing is the index against BASE, run with the checkout's git after `cd "$ROOT"` and state_gate. It does not establish that U4's chore commit takes the index as is (the plan marks that as a U4 duty).

The listing is `git diff-index --cached --raw -z --no-renames --ignore-submodules=none "$base" > "$t.raw" 2>"$GATE_TMP/err"` (`scripts/build-loop.sh:1806`). Any stderr output, or a failure in raw_records, refuses with `refuse index: …` (`:1807-1809`). The top level runs `cd "$ROOT"` (`:637`) and `if [[ -n "$GATED" ]]; then state_gate || exit 2; fi` (`:649`), and cycle-diff is gated.

**Evidence:** `scripts/build-loop.sh:637,646-649,1806-1809`

---

## Claim 3: "each entry as `--check-answer` delimits it (FENCE_AWK first; a refused file refuses), its key lines are its heading, its `**Needs:**` lines and its answer lines (ANSWERS_AWK's labels, any ID)"

**Location:** `docs/working/plan-build-loop-handoff.md:330`
**Type:** Behavioral / Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers entry start and end, fence handling, CR handling, the Needs regex and the answer labels, all checked against ANSWER_AWK. It does not cover two check_answer whole-file refusals that QKEYS does not reproduce (a `### Q-` heading inside a fence, and a duplicate heading), or line order inside an entry (Claim 4).

The two programs agree on these points:
- **Heading.** QKEYS uses `/^### Q-[0123456789]+([ \t]|$)/` with the ID cut at the first blank (`scripts/build-loop.sh:1745`). ANSWER_AWK's `heading()` accepts `h == id || index(h, id " ") == 1 || index(h, id "\t") == 1` (`scripts/lib/dev-cycle-read.sh:2077-2081`).
- **Entry end.** Both use `/^(#|##|###) /`.
- **CR, then fence.** Both run `sub(/\r$/, "")` and then `fence($0)`.
- **Needs.** QKEYS uses `/^\*\*Needs:\*\*/`.
- **Answer labels.** QKEYS uses `t ~ /^Q-[0123456789]+:/ || tolower(t) ~ /^\*\*answer(:|ed| \()/` after stripping one `- ` (`:1749`). That is the same label test ANSWER_AWK applies, widened to any ID.

ANSWER_AWK also refuses two shapes:
- `infence && /^### Q-[0123456789]+ / { if (!qline) qline = NR; … }`, which yields `quoted`.
- `count > 1`, which yields `dup` (`dev-cycle-read.sh:2083,2114-2116`).

QKEYS skips fenced lines and keeps duplicate headings without refusing. Both differences fail safe for laundering, because check_answer skips those files anyway. Even so, "delimits as --check-answer" does not cover them.

**Evidence:** `scripts/build-loop.sh:1742-1750`, `scripts/lib/dev-cycle-read.sh:2058-2117`

---

## Claim 4: "An entry on the base whose key lines differ in the index, or that is gone, refuses unless its ID is in `--answered`"

**Location:** `docs/working/plan-build-loop-handoff.md:330`
**Type:** Behavioral / Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the comparison as built: a sorted multiset of key lines per ID. It establishes that a reorder of an entry's key lines, which changes what check_answer reads, passes. It does not establish other bypasses; none was found for split, duplicate, fenced or CR shapes (Claim 3).

Both key-line files are sorted whole before they are compared: `LC_ALL=C sort -o "$t.qo" "$t.qo" && LC_ALL=C sort -o "$t.qn" "$t.qn" && LC_ALL=C awk -F '\t' -v ids="${ANSWERED[*]}" "$QDIFF_AWK" …` (`scripts/build-loop.sh:1848-1850`). QDIFF_AWK then concatenates each ID's lines in that sorted order: `o[id] = o[id] "\n" k l` (`:1764`). The order of key lines inside an entry is therefore lost.

check_answer depends on that order. It takes the **first** `**Needs:**` line as the header (`!header && /^\*\*Needs:\*\*/ { header = 1; …`), and it takes the **first** answer line (`!done { … done = 1 }`) (`scripts/lib/dev-cycle-read.sh:2087-2108`).

- **P1 (E3):** a base entry is ANSWERED with `- **Answer:** [2]` and then `Q-001: [1]`. check_answer's awk reads `drop` on the base and `keep` after the two lines are swapped in the index. `--cycle-diff` with no `--answered` prints `ok`, exit 0.
- **P2 (E3):** a base entry has `… **Status:** OPEN`, then `… **Status:** ANSWERED`, then `Q-001: [1]`. check_answer reads `open` on the base and `keep` after the two Needs lines are swapped. `--cycle-diff` prints `ok`, exit 0.

This is the F33 laundering the rule exists to stop. A `keep` that would unblock `--approved` reaches the index with no `--answered`. **E5:** HEAD's questions files already hold one entry with two answer lines (Q-045), so P1's precondition occurs in practice.

**Evidence:** `scripts/build-loop.sh:1755-1769,1848-1850`, `scripts/lib/dev-cycle-read.sh:2083-2117`, `$S/logs/probe.log` (P1, P2), `$S/logs/live-keys.log`

---

## Claim 5: "a new entry is free unless it is filed answered (Status ANSWERED or an answer line)"

**Location:** `docs/working/plan-build-loop-handoff.md:330`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers new entries in an existing file (T38: Status ANSWERED), in a newly added archive file (P3: Status ANSWERED plus an answer line), and an open new entry (T38). It does not establish that a new entry's answer line alone, with Status OPEN, refuses; that is static only, through `if (k == "a") return 1`.

QDIFF_AWK's `answered()` returns 1 for any `a` line, or for an `n` line with a trimmed field equal to `**Status:** ANSWERED` (`scripts/build-loop.sh:1756-1761`). The rule is `for (id in nw) if (!(id in o) && !(id in ok) && an[id]) print id " " nf[id] " new"` (`:1768`).

E1 passes T38's Q-004 case. P3 (E3) prints `refuse docs/working/questions-archive.md: Q-009 is a new entry filed answered …`, exit 2.

**Evidence:** `scripts/build-loop.sh:1755-1769`, `test/scripts/build-loop-orchestrator.bats:416-418`, `$S/logs/probe.log` (P3)

---

## Claim 6: "Refused instead: the idea log edited other than by appending (the base's bytes must be a prefix of the index's …); the roadmap's lines above its first `## ` heading, or its `## ` heading lines, changed; a brief file name a roadmap line outside Done names on the base that no line names in the index … Every other path is not judged"

**Location:** `docs/working/plan-build-loop-handoff.md:331`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three roadmap refusals, the Done exemption (an exact `## Done` line), and `closed/` names matched by basename. The idea-log prefix rule is covered including an empty base (P9). It does not establish brief paths outside the `docs/working/briefs/[closed/]NAME.md` shape (a subdirectory is not matched), or a roadmap whose Done heading carries extra text (P7: `## Done (last cycle)` is not exempt). The repo's roadmap and SKILL.md both use a bare `## Done`.

- **Idea log:** `[[ "$(wc -c < "$t.n")" -ge "$k" ]] && cmp -s -n "$k" "$t.o" "$t.n"` (`scripts/build-loop.sh:1823`).
- **ROADMAP_AWK:** `if (s == 2) named[b] = 1; else if (sec[1] != "## Done") need[b] = 1` (`:1783`).
- **Other paths:** `*) continue ;;` (`:1815`).

E1 passes the roadmap T38 test. P7 shows the exact-match Done rule. P8 shows a new roadmap symlink refused. P9 shows an empty base idea log taking any content.

**Evidence:** `scripts/build-loop.sh:1775-1790,1810-1828`, `$S/logs/t38.log`, `$S/logs/probe.log`, `$S/logs/probe-p7.log`

---

## Claim 7: "One `raw_records` helper (row 724) reads every `--raw -z` listing whole: check_line, log_class's chore and answers loops, and `--cycle-diff`."

**Location:** `docs/working/plan-build-loop-handoff.md:332`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every `--raw` call in `scripts/build-loop.sh`, `scripts/lib/*.sh` and `scripts/dev-cycle.sh`. It does not cover other `-z` listings (ls-tree, ls-files), which this claim does not name.

`grep -- '--raw'` finds four calls (`scripts/build-loop.sh:1311,1700,1707,1806`). Each one feeds `raw_records`, at `:1314`, `:1700`, `:1707` and `:1807`.

**Evidence:** `scripts/build-loop.sh:1311-1316,1700,1707,1806-1807`

---

## Claim 8: "Health-check lock … takes `flock` on `$(git rev-parse --git-common-dir)/health-check.lock` (plain file only, as the dispatch lock), printing one line when it waits; a run inside a run … is exempt through an exported variable, or it would wait on itself."

**Location:** `docs/working/plan-build-loop-handoff.md:333`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers serialization, the wait line, the nested exemption, and a FIFO lock path. It does not establish a symlinked lock path by execution; that is static, via `-L`.

`take_lock` checks `[[ -L "$lk" || ( -e "$lk" && ! -f "$lk" ) ]]`, as dispatch does at `scripts/build-loop.sh:1916`. It prints `yellow "waiting for another health check …"` once before the blocking flock (`scripts/health-check.sh:1110-1119`).

E2 passes T43. M3 (E4, no exemption) hangs until the 120 s timeout. With `-o`, the re-run child sees the lock held by its own parent flock and waits forever, which matches "or it would wait on itself".

**Evidence:** `scripts/health-check.sh:1106-1121`, `$S/logs/t43.log`, `$S/logs/mutants.log` (M3)

---

## Claim 9: "--cycle-diff … after --state's gate but its caller check"

**Location:** `scripts/build-loop.sh:183-186`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers which startup gates run for this mode. It does not establish what state_gate itself checks.

Only `--state` runs `caller_gate`: `if [[ "$MODE" == state ]]; then caller_gate || exit 2; fi` (`:648`). cycle-diff is GATED (`:646`), so state_gate runs (`:649`). The mode body is `state_start; cycle_diff || exit 2; echo ok` (`:1876-1880`).

**Evidence:** `scripts/build-loop.sh:646-649,1876-1880`

---

## Claim 10: "an entry on BASE whose heading, **Needs:** lines or answer lines … differ in the index, or are gone, and a new entry filed answered …, unless its ID was given with --answered …; an entry's other lines are free."

**Location:** `scripts/build-loop.sh:191-197`
**Type:** Behavioral / Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the "differ" half, which has the same mechanism as Claim 4: a reorder of key lines inside an entry is not a difference to the code, but it changes check_answer's reading. The new-entry half and the "other lines are free" half are correct (Claim 5, T38).

Paraphrased — no quote available because the evidence is the same as Claim 4's (`scripts/build-loop.sh:1848-1850` sorts both sides, `:1764` concatenates in sorted order). P1 and P2 print `ok` for a drop→keep and an open→keep flip with no `--answered`.

**Evidence:** `scripts/build-loop.sh:1764,1848-1850`, `$S/logs/probe.log`

---

## Claim 11: "Entries are delimited as --check-answer reads them, and a copy FENCE_AWK refuses refuses."

**Location:** `scripts/build-loop.sh:198-199`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** The FENCE_AWK half is Verified by execution (T38: `FENCE_AWK refuses its index copy (unbalanced 9)`). The delimitation half matches for start and end, with the residue named in Claim 3: check_answer's `quoted` and `dup` file refusals are not reproduced, and entry line order is ignored (Claim 4).

`if grep -qv '^Q-' "$t.k"; then echo "refuse $f: FENCE_AWK refuses its $k copy …"; return 1; fi` (`scripts/build-loop.sh:1844`) applies to both the base copy and the index copy.

**Evidence:** `scripts/build-loop.sh:1841-1846`, `test/scripts/build-loop-orchestrator.bats:420-421`, `$S/logs/t38.log`

---

## Claim 12: "docs/working/idea-log.md changed other than by appending (BASE's bytes start the index's), or deleted. docs/roadmap.md deleted, its lines above the first "## " heading or its "## " heading lines changed, or a brief file … named on no line of the index"

**Location:** `scripts/build-loop.sh:200-207`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same coverage and residue as Claim 6, plus deletion (T38: `refuse docs/roadmap.md: the index deletes it`).

`if [[ "${RAW_S[i]}" == D ]]; then echo "refuse $p: the index deletes it"; bad=1` (`scripts/build-loop.sh:1819`).

**Evidence:** `scripts/build-loop.sh:1817-1828`, `$S/logs/t38.log`

---

## Claim 13: "A new file, and every other path, is not judged. One of these files not a regular file, or a read that fails, refuses; so do HEAD with no merge base ("refuse HEAD") and an index that cannot be listed ("refuse index")."

**Location:** `scripts/build-loop.sh:208-211`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Holds for a new roadmap or idea log that is a regular file. It does not hold for a new questions file, which is judged.

A new roadmap or idea log is skipped by `if [[ "${RAW_OM[i]}" == 000000 ]]; then continue; fi` (`:1818`). That skip comes only after `cyc_blob` has checked both sides, so a new symlink still refuses (P8). The questions files are taken out of the loop before that skip (`qi+=("$i"); continue`, `:1813`). A new questions-archive.md holding an answered entry refuses (P3). A precise version would read "a new roadmap or idea log (a regular file) is not judged".

**Evidence:** `scripts/build-loop.sh:1810-1818`, `$S/logs/probe.log` (P3, P8)

---

## Claim 14: "As --main-log, it reads BASE's objects without re-hashing them: it catches the orchestrator's own slip, not a forged commit."

**Location:** `scripts/build-loop.sh:211-213`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the fact that only MAIN_SHA's commit and tree are re-hashed. It does not establish whether BASE's tree shares objects with MAIN_SHA's. Index blobs are not re-hashed either, and the claim does not mention them.

`state_start` runs `store_check --main "$MAIN_SHA"` (`:1259`). After that, cycle_diff reads `gate_git cat-file blob "$id"` and `"$base:$f"` (`:1799,1837`) with no further store_check.

**Evidence:** `scripts/build-loop.sh:1255-1261,1795-1800,1836-1838`

---

## Claim 15: "raw_records FILE: … read whole, the one reader every caller shares (row 724) … Returns 1 when a record does not parse or the NULs are not two per record"

**Location:** `scripts/build-loop.sh:965-969`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers parsing and the NUL count. The callers' acceptance is compared with the old loops (brief item 5). check_line and the answers loop accept the same records as before. log_class's chore loop is now stricter: an unparsed record, or an odd NUL count, makes the commit other, where the old loop `continue`d past it. The comment does not deny that change. It cannot occur with git's own output.

The loop is `[[ "$meta" =~ ^:([01234567]{6})\ ([01234567]{6})\ ([0123456789abcdef]+)\ ([0123456789abcdef]+)\ ([AMDT])$ ]] || return 1`, followed by `[[ "$(tr -cd '\000' < "$1" | wc -c)" -eq $((2 * ${#RAW_P[@]})) ]]` (`:974-978`).

- **Old check_line:** the same regex, minus the old-id capture, plus the same NUL test (diff `-` lines at the old `:1261-1269`).
- **Old answers loop:** it required `^:100644\ 100644\ … M$` and at least one record. The new loop requires `"100644 100644 M"` and `${#RAW_P[@]} -gt 0` (`:1707-1710`).

**Evidence:** `scripts/build-loop.sh:965-979,1314-1316,1700-1710`

---

## Claim 16: check_line's refusal text unchanged (brief item 5)

**Location:** `scripts/build-loop.sh:1314`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the refusal string and the ids list built for regular files. It does not establish other check_line behaviour.

The new line, `raw_records "$GATE_TMP/diff" || { echo "refuse $a: the paths the merge of $br changes could not be read"; return; }`, keeps the old string byte for byte. That string appeared twice in the removed lines. The `ids` loop keeps the 100644/100755 filter (`:1316`).

**Evidence:** `scripts/build-loop.sh:1314-1316`

---

## Claim 17: QKEYS_AWK: "per key line of an entry, as --check-answer delimits one … Then "odd" or "unbalanced" when FENCE_AWK refuses the file."

**Location:** `scripts/build-loop.sh:1736-1740`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** The output format and the odd/unbalanced END line are Verified, from `END { if (odd) print "odd " odd " " oddwhy; else if (infence) print "unbalanced " fline }` (`:1750`). For "as --check-answer delimits one", the residue is the one Claim 3 names (no `quoted`/`dup` refusal).

Paraphrased — no quote available because the comparison is the one quoted in Claim 3.

**Evidence:** `scripts/build-loop.sh:1742-1750`

---

## Claim 18: "An entry's key lines are compared without F, so an archive move is no change."

**Location:** `scripts/build-loop.sh:1751-1753`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers order independence across the two files, via F dropped and both sides sorted. It does not establish order sensitivity inside an entry. The same sort makes a reorder within one entry no change (Claim 4).

The code is `{ id = $1; k = $3; l = $0; sub(/^[^\t]*\t[^\t]*\t[^\t]*\t/, "", l) }` with `o[id] = o[id] "\n" k l` (`:1763-1764`). T38's Q-003 archive move passes (E1).

**Evidence:** `scripts/build-loop.sh:1755-1769`, `test/scripts/build-loop-orchestrator.bats:413-415`, `$S/logs/t38.log`

---

## Claim 19: ROADMAP_AWK: "The lines above the first "## " heading and the heading lines stay; a brief file a line outside "## Done" names on the base is named on some line of the index."

**Location:** `scripts/build-loop.sh:1770-1773`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claim 6. Heading order counts, because `h[s]` is concatenated in file order. The index's preamble lines are not scanned for names, which matters only if the preamble is unchanged and the base preamble named the brief.

`/^## / { h[s] = h[s] "\n" $0; sec[s] = $0; in2[s] = 1; next }` and `!in2[s] { p[s] = p[s] "\n" $0; next }` (`:1777-1778`).

**Evidence:** `scripts/build-loop.sh:1775-1790`, `$S/logs/probe-p7.log`

---

## Claim 20: cyc_blob: "an absent side (all-zero id) is an empty file. Returns 1 when that side is not absent or a regular 100644 file, or the read fails."

**Location:** `scripts/build-loop.sh:1791-1794`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the tested condition and the return value. It does not establish behaviour for a raw record whose mode and id disagree, which git does not emit.

The code tests the **mode**, not the id: `if [[ "$md" == 000000 ]]; then : > "$3"; return 0; fi` (`:1798`). On failure it returns `gate_git`'s status, `[[ "$md" == 100644 ]] && gate_git cat-file blob "$id" > "$3"` (`:1799`), which can be 3 (stderr) or git's own code rather than 1. Every caller tests only for non-zero (`! cyc_blob`, `cyc_blob … || …`). A precise version would read "an absent side (mode 000000) … returns non-zero".

**Evidence:** `scripts/build-loop.sh:1795-1800,1817,1835`, `scripts/build-loop.sh:959-964` (gate_git returns 3 on stderr)

---

## Claim 21: "cycle_diff: --cycle-diff's lines. Returns 1 on any refusal."

**Location:** `scripts/build-loop.sh:1801`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every refusal path in cycle_diff. It does not establish anything about the lines printed before an early `return 1` in the questions block (the roadmap findings are already printed by then).

Every refusal either sets `bad=1` and ends with `return "$bad"` (`:1829,1856`), or runs `return 1` directly (`:1804,1808,1835,1838,1842,1844,1850`). The mode turns that into `exit 2` (`:1878`).

**Evidence:** `scripts/build-loop.sh:1802-1857,1876-1880`

---

## Claim 22: "Seeding and "## Brainstorm" only append: the base's bytes start the index's."

**Location:** `scripts/build-loop.sh:1821`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the prefix check, including an empty base (P9) and an edited first line (T38). It does not establish that the dev cycle's seeding and Brainstorm steps really only append (SKILL.md text, not code).

`k="$(wc -c < "$t.o")"; [[ "$(wc -c < "$t.n")" -ge "$k" ]] && cmp -s -n "$k" "$t.o" "$t.n"` (`:1822-1823`).

**Evidence:** `scripts/build-loop.sh:1820-1824`, `$S/logs/t38.log`, `$S/logs/probe.log` (P9)

---

## Claim 23: "Both questions files on each side, the unchanged one included (an entry can move between them)."

**Location:** `scripts/build-loop.sh:1830`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers an unchanged file that exists on BASE. An absent unchanged file is skipped (`else continue`). Mode and readability are checked through `ls-tree`.

`elif gate_git cat-file -e "$base:$f" 2>/dev/null; then [[ "$(gate_git ls-tree "$base" -- "$f" | cut -c1-6)" == 100644 ]] && gate_git cat-file blob "$base:$f" > "$t.o" … cp "$t.o" "$t.n"` (`:1836-1839`).

**Evidence:** `scripts/build-loop.sh:1831-1847`

---

## Claim 24: "HEALTH_CHECK_LOCK_HELD   Set for the run that holds health-check.lock (one run at a time per repository: take_lock), so a run it starts takes no lock and never waits on it."

**Location:** `scripts/health-check.sh:27-29`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the export before flock and the early return. It does not establish behaviour when a caller sets the variable from outside: that run also skips the lock, by design, as T43 does.

`export HEALTH_CHECK_LOCK_HELD=1` comes before `flock … bash "$REPO_ROOT/scripts/health-check.sh" "$@"` (`:1114-1115`), and the exemption is `[[ -z "${HEALTH_CHECK_LOCK_HELD:-}" ]] || return 0` (`:1108`). health-check.bats runs the real script in the same repository (`SCRIPT=…/scripts/health-check.sh`; `run bash "$SCRIPT"`, `test/scripts/health-check.bats:13,29`), so the exemption is needed. E2 passes. M3 deadlocks (E4).

**Evidence:** `scripts/health-check.sh:1106-1121`, `test/scripts/health-check.bats:13-29`, `$S/logs/t43.log`, `$S/logs/mutants.log`

---

## Claim 25: take_lock comment: "flock on health-check.lock in the common git dir, waiting … Outside a git repository there is nothing to share. Only a plain file is locked … flock(1) holds the lock in its own process and runs this script again as its child with the lock's descriptor closed (-o): no suite, and nothing a test leaves running, inherits the lock, so it ends with this run. Exit 75 is flock's "held elsewhere" (-E), which this script never exits with."

**Location:** `scripts/health-check.sh:1094-1105`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers serialization, the leftover-process case and the FIFO case (all executed), plus the outside-repo return and the exit-75 claim (static). It does not establish signal handling: if the outer bash is killed, flock and the child keep running.

`d="$(git -C "$REPO_ROOT" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)" || return 0` (`:1109`). The script's only exits are `exit 1` (`:1112`), `exit "$rc"` (`:1120`) and `exit "$FAIL"` with `FAIL` 0 or 1 (`:58,68,1150`).

E2 passes T43, including the leftover-process case. M1 (E4) puts back the `exec 8>>` version, and T43 test 2 fails at line 38, the leftover-process assertion, with `waiting for another health check …` in the output. That shows `-o` is what releases the lock. flock is util-linux 2.38.1.

**Evidence:** `scripts/health-check.sh:1094-1121,1150`, `$S/logs/t43.log`, `$S/logs/mutants.log` (M1)

---

## Claim 26: cd_is / onmain / qa helper comments

**Location:** `test/scripts/build-loop-orchestrator.bats:391-392`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what each helper does. It does not establish the T38 case list (Claims 27-29).

- cd_is asserts the status, the exact output and an empty stderr: `[ "$status" -eq "$s" ] && [ "$output" = "$w" ] && [ -z "$stderr" ]` (`:393`).
- onmain builds main's new commit in a temporary index, `GIT_INDEX_FILE="$x" git read-tree main … git update-ref refs/heads/main …` (`:394-395`), and never touches the checkout.
- qa commits on main, then runs `git checkout -q -b chore/dev-cycle-2026-10-12` (`:397-398`).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:391-398`

---

## Claim 27: Test name and comments of the questions T38 test: "refuses an entry's header or answer changed or gone without --answered, and passes body edits, an open new entry and an archive move"; "A planted ANSWERED flip …; the same with the ID listed passes"; "A route change, a deleted entry, a removed answer line."

**Location:** `test/scripts/build-loop-orchestrator.bats:400-408`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** The test name and the ANSWERED-flip comment match their assertions (E1). The `:408` comment's "a deleted entry" has no case of its own.

Three commands follow the `:408` comment:
1. a route change, `sed -i 's/you: judgment/agent/'`;
2. a removed answer line, `sed -i '/^Q-003/d'`, which deletes only `Q-003: [1]`, not the entry;
3. a deleted archive file, `git rm -q docs/working/questions-archive.md` (`:409-412`).

The only "gone" entry is Q-000, through the deleted archive. No case deletes an entry while its file stays. Separately, the "ID listed passes" step also lists the unchanged Q-003 (`cd_is ok --answered Q-003 --answered Q-001`, `:405`), which is harmless. Line 407 covers Q-001 alone.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:400-412`, `$S/logs/t38.log`

---

## Claim 28: "Free: body lines, an appended open entry, Q-003 archived (moved whole between the files), a new archive file."

**Location:** `test/scripts/build-loop-orchestrator.bats:413`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** The first three items are Verified. The last item names a case the test does not run.

The previous line ends with `git reset -q --hard` after the archive was removed (`:412`), so the archive exists again. The next commands append Q-003 to that existing file: `sed -n '/^### Q-003/,$p' docs/working/questions.md >> docs/working/questions-archive.md` (`:415`). No new archive file is created. P3 (E3) shows that a new questions-archive.md is in fact judged when it holds an answered entry.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:412-415`, `$S/logs/probe.log` (P3)

---

## Claim 29: Roadmap T38 test name and comments ("Step 6's rewrites: Next reworded, Done trimmed, X moved to Done at closed/, an idea appended, any other path."; "No merge base; usage.")

**Location:** `test/scripts/build-loop-orchestrator.bats:424-441`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every listed case. The "no merge base" case is an orphan, that is, an unborn HEAD (`git checkout -q --orphan lone`, `:441`), not unrelated history.

E1 passes. The X line is appended after `## Done`, the last section, so it lands in Done.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:424-442`, `$S/logs/t38.log`

---

## Claim 30: health-check-lock.bats header, stub comment and test names

**Location:** `test/scripts/health-check-lock.bats:3-6,11,17,27`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers "copies the script and the libs it sources" (log-format, md-utils, skill-paths, matching `scripts/health-check.sh:61-65`), the stubbed runner, and each test name against its assertions. It does not cover a symlinked lock path (only a FIFO is tested).

The stub logs `in`/`out` only for `--fast`, and leaves `sleep 5` running with `3>&-` for any other first argument when LEAVE is set (`:13`). The FIFO assertion requires `$(grep -c "^in " "$L")` to be 3 (runs n, p, q), so the refused run never started its runner. E2 passes.

**Evidence:** `test/scripts/health-check-lock.bats:1-42`, `scripts/health-check.sh:61-65`, `$S/logs/t43.log`

---

## Claim 31: Commit 3021d0a4 body: "route change, deleted entry, removed answer line and a deleted archive refuse … mutants run: base = MAIN_SHA fails T38 at the main-moved line; no take_lock and no nested-run exemption each fail T43."

**Location:** `git log 3021d0a4` (message body)
**Type:** Reference / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** The mutant claims are reproduced at HEAD:
- M4 fails at line 407.
- M2 fails both T43 tests.
- M3, at HEAD's `-o` version, deadlocks (killed by the 120 s timeout) rather than failing an assertion.

The case list's "deleted entry", separate from "a deleted archive", has no case of its own (Claim 27). The rest of the case list matches the test.

Paraphrased — no quote available because the evidence is the E4 log and the test lines already quoted in Claims 1 and 27.

**Evidence:** `$S/logs/mutants.log`, `test/scripts/build-loop-orchestrator.bats:408-412`

---

## Claim 32: Commit f34fceb0 body: "questions entries' heading, Needs and answer lines change only for --answered IDs, a new entry is never filed answered without one; the idea log only appends; the roadmap keeps its preamble and headings and never drops a brief named outside Done. raw_records reads every --raw -z listing whole … health-check.sh takes a flock … a nested run is exempt. … Row 722 (other staged paths) stays deferred, re-keyed to U4."

**Location:** `git log f34fceb0` (message body)
**Type:** Behavioral / Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** The most severe part carries the verdict: "heading, Needs and answer lines change only for --answered IDs" is refuted by P1 and P2, since a reorder changes what check_answer reads and passes. The other parts are Verified (Claims 5, 6, 7, 8, 22), with one exception. "Row 722 … re-keyed to U4" is stated in the plan and the header, but `docs/reviews/override-log.md:722` on this branch still reads "Revisit trigger: U3c's --cycle-diff (the staged files before the chore commit), or U4's step 9." The branch diff does not touch the override log, which may be pr-prep's job at merge.

Paraphrased — no quote available because each atom is verdicted in the claims cited above.

**Evidence:** `scripts/build-loop.sh:1848-1850`, `docs/reviews/override-log.md:722`, `$S/logs/probe.log`

---

## Claim 33: Commit 414c9295 body: "With exec 8>> every suite and any process a test left running inherited the lock's descriptor; one stray process would make every later health check wait. flock -o now holds the lock and runs the script again as its child with the descriptor closed; -E 75 tells "held elsewhere" from the run's own status. T43 gains the leftover-process case (red on the exec version)."

**Location:** `git log 414c9295` (message body)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the exec version's inheritance failure (M1 red on the leftover case) and the `-o`/`-E 75` mechanics. It does not establish timing under real suite load.

M1 (E4) restores f34fceb0's `if … ! { exec 8>>"$lk"; } …; flock -n 8 || { yellow "waiting …"; flock 8; }`, and T43 test 2 fails at line 38 with the waiting line printed. At HEAD, E2 is green.

**Evidence:** `scripts/health-check.sh:1106-1121`, `test/scripts/health-check-lock.bats:30-38`, `$S/logs/mutants.log` (M1), `$S/logs/t43.log`

---

## Claims Requiring Attention

### Incorrect
- **Claim 4** (`docs/working/plan-build-loop-handoff.md:330`): the questions rule compares sorted key lines, so reordering an entry's two answer lines (drop→keep) or two Needs lines (open→keep) passes with no `--answered` (P1, P2). check_answer reads the first of each. The fix is to compare key lines in file order inside each entry, keeping the cross-file move free.
- **Claim 10** (`scripts/build-loop.sh:191-197`): the header's "differ in the index … refuses" has the same mechanism as Claim 4.
- **Claim 28** (`test/scripts/build-loop-orchestrator.bats:413`): "a new archive file" is not exercised; Q-003 is appended to the existing archive.
- **Claim 32** (f34fceb0 body): "Needs and answer lines change only for --answered IDs" has the same mechanism as Claim 4. Also, override row 722 is not re-keyed in the log on this branch.

(Claims 4, 10 and 32 are three locations of one mechanism.)

### Stale
- None.

### Mostly Accurate
- **Claim 3** (`docs/working/plan-build-loop-handoff.md:330`): "delimits it as --check-answer" omits check_answer's `quoted` and `dup` whole-file refusals (fail-safe).
- **Claim 11** (`scripts/build-loop.sh:198`): the same residue as Claim 3.
- **Claim 13** (`scripts/build-loop.sh:208`): "A new file … is not judged" is false for a new questions file (P3). It holds only for a new regular roadmap or idea log.
- **Claim 17** (`scripts/build-loop.sh:1736`): the same residue as Claim 3.
- **Claim 20** (`scripts/build-loop.sh:1791`): absent is tested by mode 000000, not by the all-zero id, and the function returns non-zero (possibly 3), not 1.
- **Claim 27** (`test/scripts/build-loop-orchestrator.bats:408`): "a deleted entry" has no case of its own; only the deleted archive removes an entry.
- **Claim 31** (3021d0a4 body): the same "deleted entry" gap. At HEAD, the no-exemption mutant hangs rather than failing an assertion.

### Unverifiable
- None.

## Escalations

1. **Blocking-grade for U3c's stated purpose (F33 laundering).** `--cycle-diff`'s questions rule is order-blind inside an entry, because `scripts/build-loop.sh:1848-1850` sorts both sides. check_answer, which `--approved` and a brief's Asked: ID depend on, reads the first Needs line and the first answer line.
   - P1 turns a base `drop` into `keep`, and P2 turns an `open` entry into `keep`. Both pass `--cycle-diff` with no `--answered`.
   - P1's precondition (two answer lines in one entry) exists on HEAD today: Q-045.
   - T38 has no reorder case.
   - Brief item 2 asked exactly this question. The answer is yes, through reordering. No other bypass was found among the split-file, duplicate-ID, CR and fenced shapes.
2. **Test-comment drift (minor).** `test/scripts/build-loop-orchestrator.bats:413` names an untested "new archive file" case. The behaviour, which is judged, is shown only by this pass's P3.

## Goal-Alignment Note

The unit's goal is that the orchestrator "cannot launder an answer the user did not give it". The roadmap, idea-log, raw_records and lock claims all hold under execution. The questions rule meets its claim for every edit except a reorder of key lines inside one entry, and that edit is exactly the one that changes check_answer's verdict without adding or removing a line.
