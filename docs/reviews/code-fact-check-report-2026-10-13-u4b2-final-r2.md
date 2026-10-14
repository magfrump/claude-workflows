**Commit:** c39a9692

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u4b2 (feat/build-loop-u4b2)
**Scope:** full branch `main...HEAD` at c39a9692: `skills/dev-cycle/SKILL.md` (the whole post-change file was read; claims are taken from the changed text and the unchanged text it relies on), `test/scripts/build-loop-orchestrator.bats` (the one new test), and the messages of 9777c1ff, adc8a176 and c39a9692. Checked against `scripts/build-loop.sh`, `scripts/dev-cycle.sh`, `scripts/lib/dev-cycle-read.sh`, `scripts/questions.sh` and plan D1-D14.
**Checked:** 2026-10-13 (local; probes ran 2026-10-14 UTC)
**Replication:** replicate r2 of 3 (final pass, iteration 3)
**Total claims checked:** 37 (32 numbered; claims 7, 14 and 15 split into a/b, claim 32 into a/b/c)
**Summary:** 30 verified, 2 mostly accurate, 0 stale, 5 incorrect, 0 unverifiable

Legibility-target per claim: **orchestrator** (text the orchestrator executes; a wrong statement is behavioural) or **reader** (doc-only).

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`): no claim here matches a logged pattern, and no Incorrect verdict below is a fabricated symbol, so the log is not updated. This review writes only this report, as the brief requires.

Executed probes. Scratch dir `S=/tmp/claude-1000/-workspace/3f9d7e3a-3058-4f14-a27e-9ecde97197ee/scratchpad/u4b2-i3/fc-r2/`. Each probe makes its own fixture under `mktemp -d /tmp/u4b2rv-fc-r2-XXXX` and refuses to run outside it. Git is hermetic (`GIT_CONFIG_GLOBAL=/dev/null`, `GIT_CONFIG_NOSYSTEM=1`, a fixture HOME). The scripts run from the worktree at c39a9692 by path; the D6 block is not written yet (Q-140). Inside each probe, every build-loop.sh call prints its own exit code to the output.

| Probe | Command (cwd `S`) | Started (UTC) | Exit | Output | What it runs |
|---|---|---|---|---|---|
| P1 | `bash p1-landing.sh` (second run, after a fixture `mkdir`) | 2026-10-14T02:42:43Z | 0 | `S/p1.out` | `--main-log` with 40 zeros; step 9's land (`--check-write`, `--state`, `--cycle-diff`, `commit --no-verify`, tree check, `--land-cycle`, `is-ancestor`, a fast-forward of the main checkout); `--start`; step 10's second land (`Dispatched: 1` and the `10.` line); `--main-log MAIN0`; `--status` reading `Dispatched:`; the bootstrap `git log -G` probe; `worktree remove --force` |
| P2 | `timeout 300 bash p2-answers-dispatch.sh` | 2026-10-14T02:43:09Z | 0 | `S/p2.out` | `--settings`; `--check-answer` over twelve answer texts; `--start` (cap refusal); `--prompt --steal` against an ended loop, the same lock again, and a fresh working loop; `--prompt` without `--steal`; `--check` on a review brief; `--merge --approved`; `--prompt --steal` on a merged (done) brief |
| P3 | `timeout 300 bash p3-selfmerge.sh` | 2026-10-14T02:44:26Z | 0 | `S/p3.out` | self-merge `--merge` from an edited WT and from a per-call detached GT (clean path, gate path, symlink); `--approved` under `merge-` and `merge-gate-` headings; an N-rule deny under `--approved` |
| P4 | `timeout 300 bash p4-cyclediff.sh` (second run, after a fixture `mkdir`) | 2026-10-14T02:46:09Z | 0 | `S/p4.out` | `--cycle-diff` on `blocked-`/`capped-` entries with their `Asked:` items (including `Q-NNN` with no `@TIP`), `Applied:` and `Dispatched:`; an item with no new entry; a `merge-` slug as an item; `--check-answer` with a raw `<!--` reason line and with step 7's withheld line (the merge-main-in part of this probe conflicted because of the fixture, and P5 replaces it) |
| P5 | `timeout 300 bash p5-withheld-land.sh` | 2026-10-14T02:46:46Z | 0 | `S/p5.out` | `--cycle-diff` with step 7's withheld-reason line staged; the same entry with no `<!--`; `--land-cycle` with main moved; `--state` then merging main into WT (step 9's form); `--cycle-diff`; `--land-cycle` with a tracked edit in MAIN_WT, then clean; `--main-log` |
| P6 | `TMPDIR=$(mktemp -d /tmp/u4b2rv-fc-r2-bats-XXXX) timeout 600 bats -f "merge-entry slug rule" test/scripts/build-loop-orchestrator.bats` (cwd worktree) | 2026-10-14T02:46:54Z | 0 | `S/p6-bats.out` | the new test |

---

## Claim 1: "Every `build-loop.sh` and `dev-cycle.sh` call runs from WT (step 0's first two from MAIN_WT, step 7's self-merge from its GT)"

**Location:** `skills/dev-cycle/SKILL.md:47-48`
**Type:** Architectural
**Legibility-target:** orchestrator
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the self-merge exception (GT) and the claim that every other build-loop mode step 7 uses (`--check`, `--merge --approved`, `--marker`) answers correctly from WT. It does not cover the D6 block itself, which is not written (Q-140).

P3 (`S/p3.out`): from an edited WT, a self-merge `--merge` refuses `a self-merge brief needs --check run from a clean checkout of the default branch's commit; the checkout's index or tracked files differ from that commit (git status)`. From GT it prints `merged ...`. `--merge --approved` from that same edited WT prints `merged` for the gate brief, because `--approved` skips the checkout rule:

```bash
# scripts/build-loop.sh:1361
  [[ "$pol" != self-merge || "$AUTH" == approved ]] || sm=1  # the S rules and the checkout
```
(excerpt ends :1361; enclosing check_line() continues to :1430 — read)

**Evidence:** `scripts/build-loop.sh:1352-1430`, `S/p3.out`

---

## Claim 2: "pass 40 zeros: it prints `main MAIN -` and refuses" · bootstrap probe "`... -G'^Main at: ' MAIN0 -- docs/working/cycles/`, the lib's check_brief flags"

**Location:** `skills/dev-cycle/SKILL.md:239-245`
**Type:** Behavioral
**Legibility-target:** orchestrator
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what `--main-log` prints for 40 zeros, that the flags match check_brief's, and that the probe finds a `Main at:` line a chore merge adds. It does not cover the stop rule across sessions, which the text itself names as a Q-103 residual.

P1 printed `main 2eaec73... -` and then `refuse main-log: 0000000000000000000000000000000000000000 is not on the default branch's first-parent history at 2eaec73...`, with exit 2. After the land, the `git log -1 ... -G'^Main at: '` probe printed the first chore merge. The flags are the lib's:

```bash
# scripts/lib/dev-cycle-read.sh:508
  c="$(git log -1 --format=%H --first-parent --diff-merges=first-parent -s --no-textconv --no-show-signature --no-follow -G'^Status: ' "$MAIN_SHA" -- "$a")"
```
(excerpt ends :508; enclosing check_brief() continues to :~520 — read)

**Evidence:** `scripts/build-loop.sh:1796-1811`, `scripts/lib/dev-cycle-read.sh:500-512`, `S/p1.out`

---

## Claim 3: "WT is removed (`hg -C MAIN_WT worktree remove --force WT`) once step 10's land is verified"

**Location:** `skills/dev-cycle/SKILL.md:260-263`
**Type:** Behavioral
**Legibility-target:** orchestrator
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers removing WT after the second land while the loop's locked worktree stays. It does not cover a filter planted in config, which is the reason given for `--force` and which this probe did not plant.

P1: after `landed` and `ancestor ok` for the second land, `worktree remove --force` left only the main worktree and the loop's `[feat/foo] locked` worktree in `worktree list`.

**Evidence:** `S/p1.out`

---

## Claim 4: health check "skipped ... or when MAIN is the commit an earlier iteration's recorded health check passed on" (with the record's `9. land: <landed NEW, health check's MAIN if it ran ...>`)

**Location:** `skills/dev-cycle/SKILL.md:291-294`, `:593`; also commit c39a9692 ("B13 ... health check skipped on a passed MAIN")
**Type:** Behavioral
**Legibility-target:** orchestrator
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers whether this skip can ever fire under the skill's own landing. It does not establish what a working rule should compare (trees, or "only cycle files changed since").

Every iteration that reaches a recorded health check also lands. `--land-cycle` always writes a new two-parent merge as main's commit:

```
# scripts/build-loop.sh:251-255 (header)
#             cycle record holding "Branch: B" (--main-log's chore). Then it
#             writes the merge with the message "Merge branch 'B'" and moves
#             the default branch as --merge does
```
(excerpt ends :255; the --land-cycle paragraph continues to :270 — read)

P1 shows main moving twice in one iteration: MAIN0 `2eaec73`, then `313cac87` (step 9) and `3690c919` (step 10's second land). The next iteration's MAIN is therefore never the MAIN an earlier record's `9.` line names. Under D12 a full iteration also runs only after main moved. So the skip is dead text, and B13's "fixed" overstates it: the health check still runs on every iteration. The impact is cost only, not safety. The rule also conflicts with step 9's "never ... reading them, but for their `7.` lines and the last `Main at:`" (`:573-574`), because finding the earlier MAIN means reading `9.` lines.

**Evidence:** `scripts/build-loop.sh:240-270`, `scripts/build-loop.sh:2046-2100`, `S/p1.out`

---

## Claim 5: "Step 9's `--cycle-diff` holds the roadmap to these moves (row 751): the lines above the first `## ` heading and the `## ` lines never change ..., and a brief file a line outside Done names stays named on some line ... The idea log is only appended to."

**Location:** `skills/dev-cycle/SKILL.md:455-458`
**Type:** Behavioral
**Legibility-target:** orchestrator
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the rule as the header states it. It is not re-executed here; iteration 1's claim 5 executed it, and the code is unchanged on this branch.

```
# scripts/build-loop.sh:203-206
#                 into HEAD first. That refusal is printed alone. docs/working/idea-log.md other than appended
#                 to (BASE's bytes start the index's). docs/roadmap.md: its
#                 lines above the first "## " heading or its "## " lines
#                 changed, or a brief file (docs/working/briefs/[closed/]NAME.md)
```
(excerpt ends :206; the paragraph continues to :213 — read)

**Evidence:** `scripts/build-loop.sh:203-213`

---

## Claim 6: "Read every loop's state (D4) with one `build-loop.sh --status` call naming every brief ... For each `ok` line whose STATE is `open`, by LOOP (TIP below is the line's SHA ...)"

**Location:** `skills/dev-cycle/SKILL.md:462-466`
**Type:** Behavioral
**Legibility-target:** orchestrator
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers one call with several briefs, the field order, and LOOP values absent, working and blocked. It does not cover skip lines, which P2 did not produce.

P2: one `--status A B C` printed three `ok` lines in argument order. The fields were STATE, POLICY, BRANCH, LOOP, SHA, DATE and DISPATCHED (`... blocked 91718172... 2026-10-13 0`, `... absent - - 4`).

**Evidence:** `scripts/build-loop.sh:67-98`, `S/p2.out`

---

## Claim 7a: "once every such ID is on its `Applied:` line and no subagent of this session runs it, step 10 re-dispatches it (a loop that ended without a new commit, or a dispatch left to retry)" — for the two cases named

**Location:** `skills/dev-cycle/SKILL.md:466-469`, `:662-664`
**Type:** Behavioral
**Legibility-target:** orchestrator
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `--prompt --steal` for a brief whose tip is a marker after the lock's tip (taken at once), and for a lock taken at the marker itself or a fresh non-marker tip ("under 2 hours old", retried). It does not cover the briefs in 7b.

P2: `--prompt A --steal`, where the tip is a `handoff: blocked` marker committed after the dispatch tip, printed `ok ... dispatched 1`. Run again, with the lock now naming the marker, it printed `refuse ...: its worktree ... is locked, and its lock or tip is under 2 hours old`. So did B's fresh working tip. `ended()` requires the lock tip to be another commit and an ancestor of the tip:

```bash
# scripts/build-loop.sh:1619-1623
ended() {
  [[ "${STATUS[loop]}" == ready || "${STATUS[loop]}" == blocked || "${STATUS[loop]}" == stopped ]] || return 1
  [[ "$WT_LOCK" =~ ^locked\ build-loop\ dispatch\ of\ [^\ ]+\ at\ ([0123456789abcdef]{40}|[0123456789abcdef]{64}),\ UTC\  ]] || return 1
  [[ "${BASH_REMATCH[1]}" != "${STATUS[sha]}" ]] && git merge-base --is-ancestor "${BASH_REMATCH[1]}" "${STATUS[sha]}" 2>/dev/null
}
```

**Evidence:** `scripts/build-loop.sh:1601-1623`, `S/p2.out`

## Claim 7b: the same rule as written, applied in the iteration that acts on a merge entry's `keep` or `drop`, or a stopped entry's `drop`

**Location:** `skills/dev-cycle/SKILL.md:466-469` (with `:527-535`)
**Type:** Behavioral
**Legibility-target:** orchestrator
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers what step 10 meets when it re-dispatches a brief whose IDs were all applied by a merge or a drop. It does not establish that every orchestrator reads the step-7 preamble this literally; the per-answer bullets name only `done`, a blocked answer and a stopped `keep` as re-dispatching.

The parenthetical names two cases. The condition, though, holds for any brief whose IDs are all on `Applied:`, and step 7 adds the ID for every answer it acts on (`:534-535`). That includes a merge entry answered `keep`, which merges, and a `drop`, which closes the brief. Step 10 then runs `--prompt --steal` after step 9 has landed. P2 shows the result for a merged brief: `refuse docs/working/briefs/2026-10-01-b.md: the brief is done on the default branch; only an open brief is dispatched` (from `scripts/build-loop.sh:1636`). A dropped brief reads as dropped or new. Step 10 files these as "any other refusal" (`:671-672`), so each one becomes a spurious `agent` entry. This fails closed: no loop starts. The fix is to restrict the rule to briefs still open whose applied answers ask for re-dispatch.

**Evidence:** `scripts/build-loop.sh:1628-1640`, `S/p2.out`

---

## Claim 8: "**ready**, POLICY `self-merge`: `--merge BRIEF --expect TIP`, run from a gate checkout, not WT: `--state` (from WT), then `hg -C MAIN_WT worktree add --detach GT refs/heads/main` ... made for this one call and removed after it ... A refusal that `path` or `deny` lines follow falls through to review ... (a deny from a rule every merge applies refuses again under `--approved`, and is then filed as `stopped`); one without them ... is `stopped`."

**Location:** `skills/dev-cycle/SKILL.md:477-486`
**Type:** Behavioral
**Legibility-target:** orchestrator
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers GT made and removed per call (three in a row, one name), a clean self-merge, the S-rule fall-through (gate path), the N-rule deny (symlink), and that deny refusing again under `--approved`. It does not cover a conflict or failed-read refusal (no path lines), which is static from the header (`:300-316`).

P3: from GT, the clean brief printed `merged`. The gate brief printed `refuse ...: 1 of 2 changed paths refused ...` and then `deny ... M scripts/lib/x.sh: the gate's own code, which lands only through a merge-gate- review entry`. The link brief printed `deny ... A src/l: a symlink, gitlink or other non-file entry ...`. Under `--approved Q-002` the link brief refused again with the same deny line.

**Evidence:** `scripts/build-loop.sh:1395-1430`, `S/p3.out`

---

## Claim 9: "`merge-gate-STEM-SHA12` when a `path` or `deny` line's PATH, lower-cased, matches the lib's GATE_CODE (a test holds this copy to it; `--approved` accepts no other heading)" · "Its body: the full TIP (row 673), `--check`'s lines as printed" · "(D4's `Review handoff: pull request` route is not built ...)"

**Location:** `skills/dev-cycle/SKILL.md:487-497`
**Type:** Behavioral
**Legibility-target:** orchestrator
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the exact heading `approval()` requires, under both prefixes, and an approved land. It does not cover a gate path printed as `?` (characters outside NAMECHARS); such a path is also an N-rule deny, so `--approved` refuses it whatever the heading.

P3: `--approved Q-003` with heading `merge-2026-10-01-gate-...` refused with `its heading must read "Q-003 · merge-gate-2026-10-01-gate-03e5793e023a" (the merge changes the gate's own code)`. `Q-001` under `merge-gate-` printed `merged`.

```bash
# scripts/build-loop.sh:1443-1445
  local r s="merge-" g=""
  [[ -z "${VERDICT[gate]}" ]] || { s="merge-gate-"; g=" (the merge changes the gate's own code)"; }
  s+="${VERDICT[stem]}-${VERDICT[tip]:0:12}"
```
(excerpt ends :1445; enclosing approval() continues to :1458 — read; VERDICT[gate] is set at :1413 from each lower-cased path against GATE_CODE)

A grep finds no `Review handoff` reader anywhere in `scripts/` (paraphrased — no quote available because the claim covers absence of code: no matching grep results).

**Evidence:** `scripts/build-loop.sh:1413`, `scripts/build-loop.sh:1442-1458`, `S/p3.out`, `S/p2.out`

---

## Claim 10: "A `--marker` skip (row 701) whose WHY says the tip is no such marker, or that a read failed, is recorded and read again next iteration; any other WHY (the body breaks the marker rules or is too large) is filed as `stopped`"

**Location:** `skills/dev-cycle/SKILL.md:498-501`
**Type:** Behavioral
**Legibility-target:** orchestrator
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the WHY texts the routing reads. It does not cover a `--status`-style skip on `--marker`, which falls under "any other WHY" and is filed as stopped. That fits, because step 7 calls `--marker` only after `--status` printed `ok`.

```bash
# scripts/build-loop.sh:953-957
    || { echo "skip $a: the tip of ${STATUS[branch]} is not a blocked or stopped marker (${STATUS[loop]})"; return; }
  ...
  [[ "$n" -le "$MARKER_MAX" ]] || { echo "skip $a: its marker is $n bytes, over the $MARKER_MAX-byte cap"; return; }
```
(excerpt ends :957; enclosing marker function continues to :~995 — read; the read failures say "could not be read" at :955, :957, :980, :988)

**Evidence:** `scripts/build-loop.sh:945-995`

---

## Claim 11: "A `refuse state` line from `--merge` or `--check` is a stop (the Rules), not a brief's verdict."

**Location:** `skills/dev-cycle/SKILL.md:503-504`
**Type:** Behavioral
**Legibility-target:** orchestrator
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the line shape and that it comes before any brief verdict. It does not cover the content of the state gate.

```
# scripts/build-loop.sh:290-291
#             Each finding prints "refuse state WHAT: WHY" and exits 2 before
#             the settings or any brief is read.
```

**Evidence:** `scripts/build-loop.sh:271-291`

---

## Claim 12: "slug `blocked-STEM-N` or `stopped-STEM-N` ... the shape `--cycle-diff` requires, Q-141 ... Add `Q-NNN@TIP` to the brief's `Asked:` line" · step 10's `capped-STEM-N` "(its item `Q-NNN` alone when TIP is `-`)" · "Later iterations add `Asked:`, `Applied:` and `Dispatched:` lines at its end"

**Location:** `skills/dev-cycle/SKILL.md:504-513`, `:565-566`, `:673-676`
**Type:** Behavioral
**Legibility-target:** orchestrator
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `--cycle-diff` accepting these items with their entries in the same change, refusing an item with no new entry and a `merge-` slug, and not judging `Applied:`/`Dispatched:`. It does not cover `--status` reading a malformed `Dispatched:` (a skip, per the header).

P4: `Asked: Q-001@<40 hex>, Q-002`, together with new entries `blocked-2026-10-01-a-1` and `capped-2026-10-01-a-1`, `Applied: Q-777` and `Dispatched: 2`, gave `ok`. Adding `Q-003` gave `refuse ...: its first Asked: line adds Q-003, which names no question entry this change files`. Adding `Q-004@...` with heading `merge-2026-10-01-a-...` gave `... whose entry's heading is not WORDS-2026-10-01-a-N`.

**Evidence:** `scripts/build-loop.sh:224-237`, `S/p4.out`

---

## Claim 13: stopped/blocked entry body: "the reason, if any, on a `> ` line" (orchestrator's own question line before the pasted body)

**Location:** `skills/dev-cycle/SKILL.md:506-511`
**Type:** Behavioral
**Legibility-target:** orchestrator
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers an entry with the orchestrator's question line and a `> ` reason line without `<!--` passing `--cycle-diff`. Reasons holding `<!--` are claim 14.

P5: the same stopped entry with `> (not shown: it holds an HTML comment opener)` gave `ok`.

**Evidence:** `S/p5.out`

---

## Claim 14a: "(one holding `<!--` is replaced by "(not shown: it holds `<!--`)" ...)"

**Location:** `skills/dev-cycle/SKILL.md:508-510`; commit c39a9692 ("B3: a stopped reason quoted, <!-- withheld")
**Type:** Behavioral
**Legibility-target:** orchestrator
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the prescribed replacement line does to both questions readers. It does not cover a raw `<!--` reason elsewhere in the entry.

The replacement text holds `<!--` with no `-->` after it, which is exactly the shape the lib's FENCE_AWK refuses for a whole file:

```awk
# scripts/lib/dev-cycle-read.sh:277-280
function opencomment(l,   n, p) {  # the last <!-- on the line has no --> after it
  n = split(l, p, /<!--/)  # one linear pass; <!-- cannot overlap itself
  return n > 1 && !index(p[n], "-->")
}
```

On main, P4's `--check-answer Q-010` printed `skip Q-010: line 8 of docs/working/questions.md opens an HTML comment that does not close on the same line, so no entry in docs/working/questions.md is read`. It printed the same for the raw reason and for the prescribed line. In WT, P5's `--cycle-diff` printed `refuse docs/working/questions.md: --check-answer refuses its index copy whole (odd 8 comment)`, exit 2. So following step 7's text, a stopped entry whose REASON holds `<!--` cannot land: step 9.3's remedy has the orchestrator "fix the iteration's own change", which contradicts step 7's text. Had the line landed, every ID in the file would have read as skip. P5 shows that wording without `<!--` lands (`ok`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:250-300`, `S/p4.out`, `S/p5.out`

## Claim 14b: "... which questions.sh would read as its index marker"

**Location:** `skills/dev-cycle/SKILL.md:509-510`
**Type:** Behavioral
**Legibility-target:** reader
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers questions.sh's index-marker match. It does not cover other readers, which claim 14a covers.

questions.sh matches only the full marker strings:

```bash
# scripts/questions.sh:140-141, 339-341
INDEX_START='<!-- index:start -->'
INDEX_END='<!-- index:end -->'
...
    replace_with "$file" awk -v start="$INDEX_START" -v end="$INDEX_END" -v tbl="$tmp" '
        index($0, start) { print; while ((getline l < tbl) > 0) print l; skip = 1; next }
        index($0, end)   { skip = 0 }
```
(excerpt ends :341; the awk program continues to :343 — read)

A REASON can hold that 20-character marker, so the hazard is real for that case. A bare `<!--` does not reach questions.sh, though. For it, the broader reader is FENCE_AWK's whole-file refusal (claim 14a). The rationale should name both.

**Evidence:** `scripts/questions.sh:140-141`, `scripts/questions.sh:339-343`

---

## Claim 15a: "one call with the IDs (an `Asked:` item without its `@TIP`) ... `[1]`, `[2]` and `[3]` read as `keep`, `drop` and `done`"

**Location:** `skills/dev-cycle/SKILL.md:515-518`
**Type:** Behavioral
**Legibility-target:** orchestrator
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the bracketed options and the plain-ID argument form. It does not cover IDs filed this iteration; see escalation E4.

P2: `[1]` printed `keep Q-001`. `--check-answer` takes only `Q-` and digits (`scripts/lib/dev-cycle-read.sh:2133`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:2069-2083`, `S/p2.out`

## Claim 15b: "any other answer, words included, as `unrecognized`"

**Location:** `skills/dev-cycle/SKILL.md:518-519`
**Type:** Behavioral
**Legibility-target:** reader
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which answer texts the script maps to keep, drop and done. It does not change orchestrator routing, which acts on the word the script prints. That is why this is marked reader, not orchestrator.

```awk
# scripts/lib/dev-cycle-read.sh:2075-2082
  if (!match(s, /^(1|2|3|keep|drop|done)/)) return "unrecognized"
  w = substr(s, 1, RLENGTH); r = substr(s, RLENGTH + 1); t = r; sub(/^[ \t]+/, "", t)
  if (!(r == "" || r ~ /^[.,;:!)*]/ || (t != r && (t == "" || substr(t, 1, 1) == "-" \
      || substr(t, 1, 3) == "\342\200\224" || substr(t, 1, 3) == "\342\200\223"))))
    return "unrecognized"
  if (w == "1" || w == "keep") return "keep"
  if (w == "2" || w == "drop") return "drop"
  return "done"
```
(excerpt ends :2082; enclosing option() ends :2083 — read)

P2 confirms the mapping. `1` and `keep` read keep. `drop` reads drop. `done.`, `done, merge it` and `3 - changes` read done. `[1] merge, once X is fixed` reads keep. Only `merge`, `[4]`, `4` and `Keep it` read unrecognized. The user-visible effect is on merge entries, whose options are "[1] merge, [2] drop, [3] changes needed": an answer "done" there re-dispatches the loop rather than merging, and "keep" merges. The fix is to state the script's grammar ("[N] or N, or the word keep/drop/done, at the start").

**Evidence:** `scripts/lib/dev-cycle-read.sh:2040-2083`, `scripts/dev-cycle.sh:61-68`, `S/p2.out`

---

## Claim 16: "First run `--main-log MAIN` again: if it lists an `other` line after MAIN, act on no answer this iteration" · step 10: "with no dispatch block ... from `--main-log MAIN` run again now"

**Location:** `skills/dev-cycle/SKILL.md:519-521`, `:655-657`
**Type:** Behavioral
**Legibility-target:** orchestrator
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `--main-log MAIN` listing only commits after MAIN: the iteration's own chore lands read chore (exit 0), and another commit reads other (exit 2). It does not cover answers in an `other` commit at or before MAIN; step 0.2 files those, and they are acted on.

P1: after both lands, `--main-log MAIN0` printed `main ... 2` and two `chore` lines, exit 0. P5: a plain commit, then the land, printed `other 5ac5c2a... other` and `chore ...`, exit 2.

**Evidence:** `scripts/build-loop.sh:1761-1811`, `S/p1.out`, `S/p5.out`

---

## Claim 17: answer routing: "A blocked entry, answered (anything but `open` and `skip`...): step 10 re-dispatches" · "A stopped entry: `keep` re-dispatches ...; `drop` closes" · "A merge entry: `keep` runs `--merge BRIEF --expect TIP --approved Q-NNN` ...; a refusal is filed as `stopped`"

**Location:** `skills/dev-cycle/SKILL.md:523-532`
**Type:** Behavioral
**Legibility-target:** orchestrator
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the script outputs each bullet keys on, and `--approved` keep landing or refusing. It does not cover the over-broad re-dispatch preamble (claim 7b).

The `--check-answer` output set is {keep, drop, done, open, unrecognized, skip} (`scripts/dev-cycle.sh:61-68`; P2). In P2 and P3, `--merge --approved` printed `merged` for a correct keep and refused otherwise.

**Evidence:** `scripts/dev-cycle.sh:61-76`, `S/p2.out`, `S/p3.out`

---

## Claim 18: step 8: "while the queue is shorter than `--settings`' `slots` line" · "`Policy: self-merge` only when `--settings` prints `policy self-merge set` ... `Paths: PATH ...` (single spaces ...); else `Policy: review` and no `Paths:` line" · "a line `Branch: NAME`"

**Location:** `skills/dev-cycle/SKILL.md:539-556`
**Type:** Behavioral
**Legibility-target:** orchestrator
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `--settings` line forms and `--status` reading the brief's `Branch:` and `Policy:` lines. It does not cover a malformed `Paths:` line, which the header says lands only the brief's own files.

P2's `--settings` printed `policy self-merge set: line 3 ...` and `slots 3 set: line 5 ...`. `--status` read `review feat/foo`, `review feat/a` and so on from the briefs' lines (P1, P2). `Policy: self-merge` with `--settings` at self-merge read as self-merge in P3 (the floor ran).

**Evidence:** `scripts/build-loop.sh:19-35`, `scripts/build-loop.sh:67-87`, `S/p1.out`, `S/p2.out`, `S/p3.out`

---

## Claim 19: "Write the record `docs/working/cycles/cycle-YYYY-MM-DD.md`, dated as the digest dates (`date +%F`, local time ...): one file per day"

**Location:** `skills/dev-cycle/SKILL.md:571-574`
**Type:** Configuration
**Legibility-target:** orchestrator
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the digest's date source and the record-name predicate. It does not cover a run that crosses local midnight, which writes a new file mid-day in UTC terms.

```bash
# scripts/dev-cycle.sh:139
TODAY="${DEV_CYCLE_TODAY:-$(date +%F)}"
# scripts/lib/dev-cycle-read.sh:246
isrecord() { [[ "$1" =~ ^docs/working/cycles/cycle-$DIGIT{4}-$DIGIT{2}-$DIGIT{2}\.md$ ]]; }
```

P1 ran with local date 2026-10-13 and UTC 2026-10-14; `--check-write` printed `ok docs/working/cycles/cycle-2026-10-13.md`.

**Evidence:** `scripts/dev-cycle.sh:139`, `scripts/lib/dev-cycle-read.sh:246-249`, `S/p1.out`

---

## Claim 20: "`Branch:` and `Main at:` stay unfenced at column 0: `--main-log` and `--land-cycle` find the iteration's land by its `Branch:` line"

**Location:** `skills/dev-cycle/SKILL.md:605-608`
**Type:** Behavioral
**Legibility-target:** orchestrator
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the land is found by an exact whole line `Branch: B` (a trailing CR dropped). It does not establish that fencing matters: chore_record's awk does not track fences, so only the column-0 exact match is load-bearing.

```bash
# scripts/build-loop.sh:1748 (chore_record)
    gate_git cat-file blob "${RAW_NO[i]}" | LC_ALL=C awk -v w="Branch: $1" '{ sub(/\r$/, "") } $0 == w { f = 1 } END { exit !f }' && return 0
```
(excerpt ends :1748; enclosing chore_record() runs :1743-1752 — read)

P1: both lands printed `landed`, and `--main-log` read both as `chore`.

**Evidence:** `scripts/build-loop.sh:1743-1752`, `S/p1.out`

---

## Claim 21: land steps 1-5: "BASE being `hg -C WT merge-base HEAD refs/heads/main`" · "`--state` ... Read M ... and T, `hg -C WT write-tree`" · "`hg -C WT commit -q --no-verify -F MSGFILE` ... check `hg -C WT rev-parse HEAD^{tree}` prints T" · "`--land-cycle --main M` ... `landed B HEAD TREE NEW`: check `... merge-base --is-ancestor HEAD refs/heads/main`. `refuse HEAD` naming a moved default branch: merge main in, then 2 again. While MAIN_WT has main checked out, the land fast-forwards it, and refuses while it has tracked edits"

**Location:** `skills/dev-cycle/SKILL.md:615-647`
**Type:** Behavioral
**Legibility-target:** orchestrator
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the whole sequence on the compare-and-swap-free fast-forward path (main checked out in MAIN_WT): a moved main, a tracked edit, and a clean land. It does not cover a MAIN_WT mid-merge, which is static from the header (`:446`).

P1: `--cycle-diff` printed `ok`, `tree ok`, `landed ...`, `ancestor ok`, and the main checkout's HEAD and main both read NEW. P5: `--land-cycle --main MAIN0` after main moved printed `refuse HEAD: the default branch is at 5ac5c2a..., not --main's e71234f...; merge it into HEAD, run --cycle-diff again ...`. A tracked edit in MAIN_WT printed `refuse HEAD: the worktree with the default branch checked out has a tracked change, or git status failed or warned there`. Clean, it printed `landed`.

**Evidence:** `scripts/build-loop.sh:240-270`, `scripts/build-loop.sh:1540-1545`, `S/p1.out`, `S/p5.out`

---

## Claim 22: step 9.3's refusal list ("It refuses, among the rules its header lists ...: a questions entry's heading, **Needs:** or answer lines changed or gone ...; a questions change while main's questions files changed since BASE; ...; an `Asked:` line other than extended by items step 7's form allows ...; two changed brief paths with one file name; and a questions file `--check-answer` refuses whole ... `refuse index`, or a whole-file refusal of main's copy, is a stop")

**Location:** `skills/dev-cycle/SKILL.md:622-640`
**Type:** Behavioral
**Legibility-target:** orchestrator
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every listed refusal against the header. It executes the Asked: rules, the whole-file questions refusal and the questions-moved refusal (P4, P5). It does not re-execute the truth-file, gate-code and case rules, which iteration 1 executed and which are unchanged. Note: the "not a regular 100644 file" refusal names the file, not `index`; `refuse index` is only the failed listing.

P4 printed `refuse docs/working/questions.md: the default branch changed the questions files since the fork point ...; merge it into HEAD, then stage again`. P5 printed `--check-answer refuses its index copy whole`. P4 also shows the two Asked: refusals quoted in claim 12. Each matches its header clause at `scripts/build-loop.sh:187-237`.

**Evidence:** `scripts/build-loop.sh:182-239`, `S/p4.out`, `S/p5.out`

---

## Claim 23: "Merging main into WT: `--state` first, then `GIT_AUTHOR_NAME="$N" ... hg -C WT -c rerere.enabled=false merge --no-edit --no-ff -q refs/heads/main` ... A conflict: `hg -C WT merge --abort`, then a stop."

**Location:** `skills/dev-cycle/SKILL.md:649-651`
**Type:** Behavioral
**Legibility-target:** orchestrator
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that a merge-in followed by `--cycle-diff` and `--land-cycle` lands, and the conflict-and-abort path. It does not cover the `hg` wrapper's own pairs, which the U4b1 test holds.

In P5, after `--state` printed `ok`, `git -c rerere.enabled=false merge --no-edit --no-ff -q refs/heads/main` printed `merged-in`; `--cycle-diff` then printed `ok`, and the land printed `landed`. In P4 a conflicting fixture printed `CONFLICT`, and `merge --abort` restored WT.

**Evidence:** `S/p4.out`, `S/p5.out`

---

## Claim 24: "absent: `--start BRIEF`; any other: `--prompt BRIEF --steal`, which takes the lock at once when the loop under it has ended (a marker after the lock's tip), else only once both lock and tip are over two hours old, refusing "under 2 hours old" until then."

**Location:** `skills/dev-cycle/SKILL.md:662-664`
**Type:** Behavioral
**Legibility-target:** orchestrator
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the ended and fresh cases (claim 7a). It does not cover a lock past two hours, which no probe waited for; that part is static from `steal()` and `STEAL_AGE=7200`.

```bash
# scripts/build-loop.sh:1595
DISPATCH_CAP=4; STEAL_AGE=7200
```

**Evidence:** `scripts/build-loop.sh:1595-1623`, `S/p2.out`

---

## Claim 25: "`ok BRIEF BRANCH DIR` and `dispatched N`: start one background subagent ... whose prompt is every line after `dispatched N`, as printed ... Write `Dispatched: N` on the brief"

**Location:** `skills/dev-cycle/SKILL.md:665-669`
**Type:** Behavioral
**Legibility-target:** orchestrator
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the output shape and N being written back and read by `--status`. It does not cover the loop prompt's content about answers: the prompt says nothing about them, so the skill's added "Answered for you" line is the only channel.

P1: `ok ... feat/foo .../wt-2026-10-13-foo`, then `dispatched 1`, then the prompt's first line. After `Dispatched: 1` was landed, `--status` printed DISPATCHED `1`.

**Evidence:** `scripts/build-loop.sh:1628-1700`, `S/p1.out`

---

## Claim 26: "A refusal ending "retry once it ends" or saying "under 2 hours old" is tried again next iteration."

**Location:** `skills/dev-cycle/SKILL.md:670-672`
**Type:** Behavioral
**Legibility-target:** orchestrator
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that both texts exist as written. It does not cover header-listed git-command failures that "may clear on a retry"; the skill files those as `agent` entries.

`scripts/build-loop.sh:2145` prints `... another --start or --prompt is running in this repository; retry once it ends`. P2 printed `... its lock or tip is under 2 hours old`.

**Evidence:** `scripts/build-loop.sh:2145`, `scripts/build-loop.sh:1612`, `S/p2.out`

---

## Claim 27: "A brief `--status` read with DISPATCHED 4 (the cap, D1) is never dispatched again"

**Location:** `skills/dev-cycle/SKILL.md:673-676`
**Type:** Configuration / Behavioral
**Legibility-target:** orchestrator
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `--start` (and through dispatch(), `--prompt`) refusing at 4. It does not cover a count that reads low after a lost `Dispatched:` line, which the text states as a residual.

P2 printed `refuse docs/working/briefs/2026-10-01-c.md: it was dispatched 4 times, and the cap is 4`, exit 2 (from `scripts/build-loop.sh:1637`, `-ge "$DISPATCH_CAP"`).

**Evidence:** `scripts/build-loop.sh:1595`, `scripts/build-loop.sh:1637`, `S/p2.out`

---

## Claim 28: "Then land again as step 9 does (1 to 5): the briefs' `Dispatched:` lines and the record's `10.` line."

**Location:** `skills/dev-cycle/SKILL.md:678-683`
**Type:** Behavioral
**Legibility-target:** orchestrator
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the second land passing `--cycle-diff` (BASE = the first land's HEAD) and `--land-cycle` (the record changed and holding `Branch:`), and being read as chore. It does not cover a second land whose record is unchanged, which `--land-cycle` would refuse; the text always changes the `10.` line.

P1: BASE equalled the first land's HEAD (`ee0132d7`), and the staged diff was `M brief` and `M record`. `--cycle-diff` printed `ok`, then `landed ... 3690c919`, `ancestor ok`. `--main-log` read both lands as `chore`.

**Evidence:** `S/p1.out`

---

## Claim 29: "Wait (D12): with a loop running, the next iteration starts when one finishes ..., with a 1800 s fallback wakeup; with none, every 1200-1800 s, and only when the default branch moved since this iteration's land, a retry's wait ran out, or the user wrote, run a full iteration"

**Location:** `skills/dev-cycle/SKILL.md:694-698`
**Type:** Reference
**Legibility-target:** orchestrator
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with plan D12. It does not cover "a retry's wait ran out" as a timer, which no script provides; it is orchestrator bookkeeping.

The plan's D12 (`docs/working/plan-build-loop-handoff.md:93-96`) gives the 1800 s fallback and the 1200-1800 s cheap check, which runs only on a move of main, an answered Asked ID, or the user writing (paraphrased — no quote available because the D12 bullet spans four lines of prose).

**Evidence:** `docs/working/plan-build-loop-handoff.md:93-96`

---

## Claim 30: test "SKILL.md's merge-entry slug rule quotes the lib's GATE_CODE, which --approved's heading reads, on one line of its own (row 674, U4b2)", and it "also pins DISPATCH_CAP and STEAL_AGE"

**Location:** `test/scripts/build-loop-orchestrator.bats:374-384`
**Type:** Behavioral
**Legibility-target:** reader
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test passing and what it compares: exactly one SKILL.md line equal to two spaces plus a backticked GATE_CODE, `with DISPATCHED 4 (the cap`, and `"under 2 hours old"` derived from the script's constants. It does not establish that the matched line sits in step 7's slug rule (any line of that content would pass), nor pin the prose "over two hours old".

P6 printed `ok 1 SKILL.md's merge-entry slug rule ...`, exit 0. SKILL.md:491 is the only such line. `approval()` reads VERDICT[gate], which is set from GATE_CODE (`scripts/build-loop.sh:1413`).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:374-384`, `skills/dev-cycle/SKILL.md:491`, `S/p6-bats.out`

---

## Claim 31: commit 9777c1ff: "step 7 collects each brief's build-loop state with one --status call (D4), files merge entries with the --approved heading rule (GATE_CODE quoted, pinned to the lib by a test), blocked/stopped entries with WORDS-STEM-N slugs and Asked: items, and applies answers through --check-answer; step 8 ...; step 9 ... lands through --state, --cycle-diff, a hook-free commit of that index, and --land-cycle, merging main in on a moved main; step 10 dispatches with --start/--prompt, relays the prompt, writes Dispatched: N and lands again ... Step 6 drops keep-or-drop (checks 2-3) ..."

**Location:** commit 9777c1ff message
**Type:** Reference
**Legibility-target:** reader
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed step existing in the text as described (claims 6, 9, 12, 21, 25, 28; executed). It does not endorse the step-7 details the later fixes changed.

**Evidence:** `skills/dev-cycle/SKILL.md:412-683`, `S/p1.out`, `S/p3.out`

---

## Claim 32a: commit adc8a176: "Also the stale step-6 and "check 1" references, and step 9.3's list of --cycle-diff refusals completed."

**Location:** commit adc8a176 message
**Type:** Reference
**Legibility-target:** reader
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the "completed" claim at adc8a176. A1-A4 are covered by iteration 2's executed claims and by claims 7a, 8 and 9 here.

`git show adc8a176:skills/dev-cycle/SKILL.md | grep -c 'refuses whole'` prints `0`: the whole-file questions refusal was added only in c39a9692 (B14). So "completed" overstated the list at adc8a176, as iteration 2 also found (paraphrased — no quote available because the claim covers absence of text at that commit: no matching grep results).

**Evidence:** `skills/dev-cycle/SKILL.md:637` (at c39a9692)

## Claim 32b: commit c39a9692: "B3-B7: a stopped reason quoted, <!-- withheld ..." and "B8-B16: ... health check skipped on a passed MAIN ..."

**Location:** commit c39a9692 message
**Type:** Reference / Behavioral
**Legibility-target:** reader
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers these two fix claims only. Their text exists, but it does not do what the message says (claims 14a and 4).

The withheld line itself holds `<!--` and makes `--cycle-diff` refuse (P5). The health-check skip can never fire, because each iteration's land moves main to a new commit (P1).

**Evidence:** `S/p5.out`, `S/p1.out`

## Claim 32c: commit c39a9692: the other fix claims (B1, B2, B4-B12, B14-B16), "The GATE_CODE pin test also pins DISPATCH_CAP and STEAL_AGE", "Thirteen findings deferred or Won't-Fix with override rows"

**Location:** commit c39a9692 message
**Type:** Reference
**Legibility-target:** reader
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the text of each named fix existing as described, the pin test (P6), and the override-row count. It does not cover B9's preamble over-reach (claim 7b), which "applied, unowned briefs go back to step 10" introduced.

`git diff main...HEAD -- docs/reviews/override-log.md | grep -c '^+|'` prints `13` (paraphrased — no quote available because this is a count over the diff, not a snippet).

**Evidence:** `docs/reviews/override-log.md` (13 added rows), `S/p6-bats.out`

---

## Claims Requiring Attention

### Incorrect
- **Claim 4** (`skills/dev-cycle/SKILL.md:291-294`): the health-check skip "when MAIN is the commit an earlier iteration's recorded health check passed on" can never fire. Each iteration's own land writes a new merge on main (P1), so B13 saved nothing. To make it work, compare trees, or skip when main moved only through this design's chore merges. Also reconcile it with step 9's "never reading [earlier blocks] but for their `7.` lines and the last `Main at:`".
- **Claim 7b** (`:466-469`): the "applied, unowned brief goes back to step 10" rule also catches a brief merged (`keep`) or dropped this iteration. `--prompt` refuses "the brief is done on the default branch" (P2), and step 10 files a spurious `agent` entry. Restrict the rule to open briefs whose applied answer asks for re-dispatch.
- **Claim 14a** (`:508-510`): the prescribed replacement "(not shown: it holds `<!--`)" holds an unclosed `<!--`. FENCE_AWK refuses the whole questions file: `--check-answer` reads every ID as skip, and `--cycle-diff` refuses the land (P4, P5). Write the replacement without `<!--` (P5: `ok`).
- **Claim 15b** (`:518-519`): "any other answer, words included, as unrecognized" is wrong. Bare `1`/`2`/`3` and the words `keep`/`drop`/`done` (followed by the end, punctuation or a dash) read as keep/drop/done (P2). State the script's grammar. Reader-facing: the orchestrator routes on the printed word.
- **Claim 32b** (c39a9692 message): B3's "<!-- withheld" and B13's "health check skipped on a passed MAIN" do not hold (claims 14a and 4).

### Stale
- (none)

### Mostly Accurate
- **Claim 14b** (`:509-510`): questions.sh matches only the full `<!-- index:start -->`/`<!-- index:end -->` strings. A bare `<!--` is a hazard because FENCE_AWK refuses the file whole, so name that reader too.
- **Claim 32a** (adc8a176 message): "refusals completed" lacked the whole-file questions refusal until c39a9692.

### Unverifiable
- (none)

## Escalations

- **E1 (behavioural, amber; claim 14a):** a stopped REASON holding `<!--` puts step 7's own withheld line into WT's questions file. `--cycle-diff` refuses it as "--check-answer refuses its index copy whole". Step 9.3's remedy ("fix the iteration's own change") contradicts step 7's text, so a literal orchestrator keeps failing to land, which is a stall a loop can trigger. It fails closed: nothing wrong lands. One-word fix (P5 verified).
- **E2 (behavioural, low; claim 4):** the B13 health-check skip is unreachable. Cost only.
- **E3 (behavioural, low; claim 7b):** same-iteration re-dispatch of merged or dropped briefs, which fails closed with one `agent` entry each.
- **E4 (behavioural, low; static):** step 7's one `--check-answer` call takes "every brief's `Asked:` items and merge entries, less those on its `Applied:` line". That includes entries filed this iteration, which exist only in WT. `check_answer` prints `skip Q-NNN: no such entry in docs/working/questions.md or questions-archive.md on the default branch` for them (`scripts/lib/dev-cycle-read.sh:2160-2161`), and the text routes a skip to the record and to the final message's "skipped" list. Every new entry is then listed twice: as new and as skipped. Exclude IDs filed this iteration.
- **E5 (reader, low; out of diff):** row 731's revisit asked for a decision-log row recording the reuse of the `Main at:` name (decision-log row 68 cut it). `docs/decisions/log.md` has no such row; the plan bullet does not list it.
- Iteration 1's E2/E3 (a re-dispatched loop ending without a commit; a retry after `Applied:`) are covered now by the preamble rule (claim 7a), whose over-reach is E3.

## Goal-Alignment Note

Success criterion (verbatim from the brief): "A code-fact-check report saved at the given path, every checkable claim in the diff verdicted with evidence".

The report is saved at `/workspace/.claude/wt-build-loop-u4b2/docs/reviews/code-fact-check-report-2026-10-13-u4b2-final-r2.md`, and its first line is `**Commit:** c39a9692`. It follows the code-fact-check format: header fields, then 37 verdicts, each with the seven mandatory fields plus Legibility-target, then the attention summary and escalations. Every claim the brief singled out (steps 7-10, the land sequence, the second land, `--start`/`--prompt` texts, `--steal`, the heading rule, the new test) was executed in throwaway fixtures under `/tmp/u4b2rv-fc-r2-*`, except where marked static. Gaps: no probe waited out the two-hour steal; the D6 block is unwritten, so scripts ran by path; truth-file and case rules in `--cycle-diff` were not re-executed (unchanged since iteration 1's executed check). Probe output is in `S/` only; nothing was committed or staged, and no other worktree file was written.
