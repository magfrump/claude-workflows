# Code Fact-Check Report

**Commit:** c39a9692
**Repository:** /workspace/.claude/wt-build-loop-u4b2 (feat/build-loop-u4b2)
**Scope:** full branch `main...HEAD`: `skills/dev-cycle/SKILL.md`, `test/scripts/build-loop-orchestrator.bats`, and the messages of 9777c1ff, adc8a176, c39a9692; claims verified against `scripts/build-loop.sh`, `scripts/dev-cycle.sh`, `scripts/lib/dev-cycle-read.sh`, `scripts/questions.sh` (replicate r3 of 3)
**Checked:** 2026-10-13
**Total claims checked:** 30
**Summary:** 25 verified, 4 mostly accurate, 0 stale, 1 incorrect, 0 unverifiable

Legibility-target: every claim below is tagged `Legibility-target:` **behavioral** (skill text the
orchestrator executes, or a test/commit statement about what a script does; a wrong one changes
what the orchestrator does) or **doc-only** (a wrong one misleads a reader, but the orchestrator
acts on the script's printed output either way).

Execution provenance (all probes: `set -eu`, own `mktemp -d /tmp/u4b2rv-fc-r3-XXXX`, cwd
`/tmp/claude-1000/-workspace/3f9d7e3a-3058-4f14-a27e-9ecde97197ee/scratchpad/u4b2-i3/fc-r3/`
when launched, hermetic git env as `test/lib/build-loop-fixtures.bash`; scripts run directly with
`bash`, since the D6 block is pending, Q-140). Probe scripts and captured outputs are in that
directory:

| Probe | Command | Exit | UTC timestamp | Output file | Temp repo |
|---|---|---|---|---|---|
| A | `timeout 120 bash probe-a.sh` | 0 | 2026-10-14T02:42:33Z | `out-a.txt` | /tmp/u4b2rv-fc-r3-QH8Z |
| B | `timeout 300 bash probe-b.sh` | 0 | 2026-10-14T02:43:17Z | `out-b.txt` | /tmp/u4b2rv-fc-r3-qQLD |
| C | `timeout 300 bash probe-c.sh` | 0 | 2026-10-14T02:43:39Z | `out-c.txt` | /tmp/u4b2rv-fc-r3-pLBR |
| D | `timeout 300 bash probe-d.sh` | 0 | 2026-10-14T02:43:59Z | `out-d.txt` | /tmp/u4b2rv-fc-r3-6d13 |
| E | `timeout 300 bash probe-e.sh` | 0 | 2026-10-14T02:45:37Z | `out-e.txt` | /tmp/u4b2rv-fc-r3-dXWb |
| bats | `TMPDIR=/tmp/u4b2rv-fc-r3-Nnul timeout 900 bats test/scripts/build-loop-orchestrator.bats` (cwd the worktree) | 0 (28 ok, 0 not ok) | 2026-10-14T02:44:18Z | `out-bats.txt` | — |

`docs/reviews/hallucination-patterns.md` was read; no logged pattern matches any claim below.
No Incorrect verdict is a fabrication (the one Incorrect misstates a real reader's grammar), so
the log needs no entry (and this replicate writes only this report).

---

## Claim 1: "pass 40 zeros: it prints `main MAIN -` and refuses, and that MAIN is the bootstrap"

**Location:** `skills/dev-cycle/SKILL.md:243-245`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `--main-log` with a 40-zero SINCE on a sha1 repo (first line `main MAIN -`, a `refuse main-log:` line, exit 2); does not establish the `-G'^Main at: '` history probe that decides when zeros are passed, nor sha256 repos.
**Legibility-target:** behavioral

Probe A printed `main e2de5d32… -` then `refuse main-log: 0000…0000 is not on the default branch's first-parent history at e2de5d32…`, exit 2. The code path:

```bash
# scripts/build-loop.sh:1799-1800
  LC_ALL=C awk -v s="$1" '$0 == s { f = 1; exit } { print } END { exit !f }' "$GATE_TMP/fp" > "$GATE_TMP/after" \
    || { echo "main $MAIN_SHA -"; echo "refuse main-log: $1 is not on the default branch's first-parent history at $MAIN_SHA"; return 1; }
```
(excerpt ends :1800; enclosing main_log() continues to :1810 — read)

**Evidence:** `scripts/build-loop.sh:1793-1810`, `out-a.txt`

---

## Claim 2: "Read every loop's state (D4) with one `build-loop.sh --status` call naming every brief … (TIP below is the line's SHA, the branch tip; STEM the brief's file name without `.md`)"

**Location:** `skills/dev-cycle/SKILL.md:462-466`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers one --status call over several briefs printing `ok BRIEF STATE POLICY BRANCH LOOP SHA DATE DISPATCHED [REASON]` with SHA the branch tip; does not establish behaviour for briefs the glob skips or the same-branch skip.
**Legibility-target:** behavioral

Probe B printed `ok docs/working/briefs/2026-10-01-x.md open review feat/x blocked 9350b49… 2026-10-13 0` and `ok …-y.md open review feat/y stopped bcfd24e… 2026-10-13 0 adds a dependency` from one call. The line is assembled at:

```bash
# scripts/build-loop.sh:930-931
  STATUS=([line]="ok $a $st $pol $br $loop $sha $date $disp${reason:+ $reason}" [state]="$st" [policy]="$pol" [branch]="$br"
    [loop]="$loop" [sha]="$sha" [ahead]="$ahead" [date]="$date" [dispatched]="$disp" [reason]="$reason")
```
(excerpt is the end of status_fields(), :885-932 — read)

**Evidence:** `scripts/build-loop.sh:885-932`, `out-b.txt`

---

## Claim 3: "--merge BRIEF --expect TIP, run from a gate checkout, not WT … (the self-merge floor reads a clean checkout of main's commit, which WT is not once this iteration has edited it, and a merge moves main past any earlier one)"

**Location:** `skills/dev-cycle/SKILL.md:477-482`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers --merge of a self-merge brief from an edited WT (refused for the checkout), from an unedited WT at main's commit (merged), and from a detached GT at refs/heads/main (works; probe E merged nothing only because of planted conditions); does not establish GT's removal with `--force` or name collisions between two GTs in one iteration (deferred row, i2 architecture 5).
**Legibility-target:** behavioral

Probe C: from WT with a tracked edit, `refuse …: a self-merge brief needs --check run from a clean checkout of the default branch's commit; the checkout's index or tracked files differ from that commit (git status)` plus a `path` line, exit 2; from the same WT unedited, `merged …`, exit 0 (so WT refuses only once edited or once main has moved past its commit, as the parenthetical says). The checkout refusal is computed in check_line:

```bash
# scripts/build-loop.sh:1397
  co=""; if [[ -n "$sm" ]] && ! checkout_gate; then co="refuse $a: a self-merge brief needs --check run from a clean checkout of the default branch's commit; $CHECKOUT_WHY"; fi
```
(excerpt ends :1397; enclosing check_line() continues to :1419 — read)

**Evidence:** `scripts/build-loop.sh:1350-1419`, `out-c.txt`

---

## Claim 4: "A refusal that `path` or `deny` lines follow falls through to review: a merge entry as below, quoting `--merge`'s lines … one without them (a conflict, a failed read) is `stopped`."

**Location:** `skills/dev-cycle/SKILL.md:482-486`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which --merge refusals print path/deny lines (checkout and S-rule refusals do; conflict and read failures do not); does not establish that a path-line refusal is one review can cure: --merge's own environment refusals (no identity known, MAIN_WT with a tracked change or mid-merge, the branch moved, rebase/bisect state) also print path lines, so this rule files them as merge entries instead of a stop or a retry.
**Legibility-target:** behavioral

The mechanism holds: a conflict returns before any row prints (`1) echo "refuse $a: $br conflicts with the default branch"; return ;;`, `scripts/build-loop.sh:1373`), and the header says path lines follow "an ok line, a K of N refusal or a checkout refusal (or --merge's own refusal of an ok verdict)" (`scripts/build-loop.sh:348-349`). The parenthetical in that header is the gap: probe E ran --merge from a fresh GT with MAIN_WT (main checked out) holding a tracked edit, and got `refuse …: the worktree with the default branch checked out has a tracked change, or git status failed or warned there` followed by `path docs/working/briefs/2026-10-01-x.md A work-feat-x.txt`; with no identity it printed `refuse …: git knows no author or committer identity …` and the same path line. Under step 7's rule both become a `merge-STEM-SHA12` entry asking the user to approve a merge that the gate already passed, and which `--approved` refuses again for the same environment cause. The same MAIN_WT state at step 9.5's land is a stop (`SKILL.md:645-647`). The precise version: path lines follow the checkout refusal, a K of N refusal, and every --merge refusal of an ok verdict (policy, identity, worktree state, a moved branch); only the checkout and S-rule (deny) cases are review routes.

**Evidence:** `scripts/build-loop.sh:348-349`, `scripts/build-loop.sh:427-451`, `scripts/build-loop.sh:1370-1376`, `out-e.txt`, `out-c.txt`

---

## Claim 5: "(a deny from a rule every merge applies refuses again under `--approved`, and is then filed as `stopped`)"

**Location:** `skills/dev-cycle/SKILL.md:483-485`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that N-rule denies apply under `--approved` while S rules and the checkout do not; does not establish the filing step itself (orchestrator text).
**Legibility-target:** behavioral

```bash
# scripts/build-loop.sh:1358
  [[ "$pol" != self-merge || "$AUTH" == approved ]] || sm=1  # the S rules and the checkout
```
and per path, `nrules` runs unconditionally while `srules` runs only when `sm` is set (`[[ -n "$DENY" || -z "$sm" || "$p" == "$a" ]] || srules …`, `scripts/build-loop.sh:1414`). Probe C's `Paths: none` brief showed an S-rule deny (`neither listed in the brief's Paths: line nor one of its own files`), which by this code would not refuse under `--approved`.

**Evidence:** `scripts/build-loop.sh:1350-1419`, `scripts/build-loop.sh:356-392`

---

## Claim 6: "heading `### Q-NNN · merge-STEM-SHA12` … or `merge-gate-STEM-SHA12` when a `path` or `deny` line's PATH, lower-cased, matches the lib's GATE_CODE (a test holds this copy to it; `--approved` accepts no other heading)" and the quoted regex

**Location:** `skills/dev-cycle/SKILL.md:487-491`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the regex copy (byte-equal to the lib), the gate flag set from every changed path (path and deny lines alike), and approval()'s exact-heading match; does not establish the edge where a gate-code path holding characters outside pathform prints as `?` (it is then denied by the N rules anyway, so no approval lands).
**Legibility-target:** behavioral

```bash
# scripts/lib/dev-cycle-read.sh:1969
GATE_CODE='^scripts/(build-loop|dev-cycle|questions)\.sh$|^scripts/lib/|^skills/dev-cycle/'
# scripts/build-loop.sh:1413
    [[ ! "${lps[$i]}" =~ $GATE_CODE ]] || gc=1
# scripts/build-loop.sh:1456-1457
  [[ "$ANSWER_HEADING" == "$1 · $s" ]] \
    || { MERGE_WHY="$1 approves no merge of this tip: its heading must read \"$1 · $s\"$g"; return 1; }
```
(approval() spans :1441-1458 — read). Probe C: a review brief adding `scripts/lib/new.sh` got `--check` ok; `--approved Q-001` under `merge-2026-10-01-g-…` refused "its heading must read \"Q-001 · merge-gate-2026-10-01-g-0a3c5f657f61\""; `--approved Q-002` under the merge-gate heading merged. Bats test 21 passed.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1969`, `scripts/build-loop.sh:1405-1418`, `scripts/build-loop.sh:1441-1458`, `out-c.txt`, `out-bats.txt`

---

## Claim 7: "A `--marker` skip (row 701) whose WHY says the tip is no such marker, or that a read failed, is recorded and read again next iteration; any other WHY (the body breaks the marker rules or is too large) is filed as `stopped`"

**Location:** `skills/dev-cycle/SKILL.md:498-501`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers marker()'s own skip texts (not-a-marker, could not be read, over 64 KiB, body rule, empty blocked body, FENCE_AWK); does not establish the status_fields skips --marker repeats (a brief --status just read ok would only hit them in a race; they would fall to "any other WHY").
**Legibility-target:** behavioral

```bash
# scripts/build-loop.sh:951-955
  [[ "${STATUS[loop]}" == blocked || "${STATUS[loop]}" == stopped ]] \
    || { echo "skip $a: the tip of ${STATUS[branch]} is not a blocked or stopped marker (${STATUS[loop]})"; return; }
  n="$(git cat-file -s "${STATUS[sha]}")" || { echo "skip $a: its marker could not be read"; return; }
  [[ "$n" -le "$MARKER_MAX" ]] || { echo "skip $a: its marker is $n bytes, over the $MARKER_MAX-byte cap"; return; }
```
(excerpt ends :955; enclosing marker() continues to :994 — read; the other skips are the body rule, empty blocked body and FENCE_AWK lines at :979-991, and "its marker's body could not be read" at :977/:986.)

**Evidence:** `scripts/build-loop.sh:947-994`

---

## Claim 8: "slug `blocked-STEM-N` or `stopped-STEM-N` … the shape `--cycle-diff` requires, Q-141" and "Add `Q-NNN@TIP` to the brief's `Asked:` line (\", \" between items; none yet: a line `Asked: ITEM` at its end)"

**Location:** `skills/dev-cycle/SKILL.md:504-513`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers --cycle-diff and --land-cycle accepting a new `Asked: Q-NNN@TIP` line and an appended `, Q-NNN` item whose entries are filed in the same change with `blocked-`, `stopped-` and `capped-` slugs; and refusing an item naming no new entry, or a `merge-STEM-SHA12` entry; does not establish the N numbering rule (orchestrator arithmetic).
**Legibility-target:** behavioral

Probe B: entries `### Q-001 · blocked-2026-10-01-x-1` and `### Q-002 · stopped-2026-10-01-y-1` with `Asked: Q-001@<tip>` / `Asked: Q-002@<tip>` lines passed `--cycle-diff` (ok, exit 0) and `--land-cycle`; a second land appending `, Q-003` (a `capped-2026-10-01-y-1` entry) passed. Negatives: `refuse …-x.md: its first Asked: line adds Q-050@abcdef1, which names no question entry this change files`, and `… adds Q-004@…, whose entry's heading is not WORDS-2026-10-01-x-N`. The rule:

```bash
# scripts/build-loop.sh:1990-1993
      if ! [[ "$x" =~ ^(Q-[0123456789]+)(@[0123456789abcdef]{7,64})?$ ]]; then echo "refuse ${ap[$f]}: its first Asked: line adds \"$x\", which is not Q-NNN or Q-NNN@SHA"; bad=1; continue; fi
      id="${BASH_REMATCH[1]}"; [[ "$qrc" -ne 2 ]] || continue
      if [[ -z "${newh[$id]+set}" ]]; then echo "refuse ${ap[$f]}: its first Asked: line adds $x, which names no question entry this change files"; bad=1
      elif ! [[ "${newh[$id]#* · }" =~ ^[abcdefghijklmnopqrstuvwxyz]+(-[abcdefghijklmnopqrstuvwxyz]+)*-"${f%.md}"-[0123456789]+$ ]]; then …
```
(excerpt ends :1993; enclosing cycle_rules() continues to :1999 — read)

**Evidence:** `scripts/build-loop.sh:1981-1999`, `out-b.txt`

---

## Claim 9: "then the reason, if any, on a `> ` line (one holding `<!--` is replaced by \"(not shown: it holds `<!--`)\", which questions.sh would read as its index marker)"

**Location:** `skills/dev-cycle/SKILL.md:508-510`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers questions.sh's index-marker match and the questions readers' `<!--` rule; does not establish any effect of the replacement text itself.
**Legibility-target:** doc-only

questions.sh matches its marker as the whole string, not `<!--` alone:

```bash
# scripts/questions.sh:140, :339-340
INDEX_START='<!-- index:start -->'
    replace_with "$file" awk -v start="$INDEX_START" -v end="$INDEX_END" -v tbl="$tmp" '
        index($0, start) { print; while ((getline l < tbl) > 0) print l; skip = 1; next }
```
(excerpt ends :340; enclosing render_index() continues to :344 — read). A REASON holding the full `<!-- index:start -->` would be read so; a REASON holding a bare `<!--` would instead make --check-answer skip the whole questions file ("a line leaving a <!-- open", `scripts/dev-cycle.sh:73`). The replacement is right for both; the stated reason covers only the first. Precise version: "which questions.sh can read as its index marker, and which leaves a `<!--` open for --check-answer".

**Evidence:** `scripts/questions.sh:140-141`, `scripts/questions.sh:339-344`, `scripts/dev-cycle.sh:61-78`

---

## Claim 10: "one call with the IDs (an `Asked:` item without its `@TIP`) of every brief's `Asked:` items and merge entries"

**Location:** `skills/dev-cycle/SKILL.md:515-517`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers --check-answer taking many bare `Q-NNN` IDs in one call and printing one line each; does not establish behaviour for an `@TIP` item passed whole (it is skipped as "not a question ID", by the regex below).
**Legibility-target:** behavioral

```bash
# scripts/lib/dev-cycle-read.sh:2138
  if [[ ! "$a" =~ ^Q-[0123456789]+$ ]]; then echo "skip ${a//$'\n'/ }: not a question ID (Q- and digits)"; return; fi
```
(excerpt ends :2138; enclosing check_answer() continues to :2161 — read). Probe A answered 17 IDs in one call.

**Evidence:** `scripts/lib/dev-cycle-read.sh:2134-2161`, `out-a.txt`

---

## Claim 11: "`[1]`, `[2]` and `[3]` read as `keep`, `drop` and `done`; any other answer, words included, as `unrecognized`."

**Location:** `skills/dev-cycle/SKILL.md:518-519`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers --check-answer's reading of an answered entry's first answer line; does not establish what the orchestrator does with each word (it routes on the printed word, which is correct either way).
**Legibility-target:** doc-only (the orchestrator acts on --check-answer's printed word; the misstatement is about which user answers produce it)

The reader also takes bare `1`/`2`/`3` and the words `keep`/`drop`/`done` in any case, followed by end, punctuation or a dash:

```awk
# scripts/lib/dev-cycle-read.sh:2070-2082
function option(span,   s, w, r, t) {
  s = tolower(span); sub(/^[ \t*]+/, "", s)
  if (substr(s, 1, 3) == "[1]") return "keep"
  if (substr(s, 1, 3) == "[2]") return "drop"
  if (substr(s, 1, 3) == "[3]") return "done"
  if (!match(s, /^(1|2|3|keep|drop|done)/)) return "unrecognized"
  …
  if (w == "1" || w == "keep") return "keep"
  if (w == "2" || w == "drop") return "drop"
  return "done"
}
```
(the elided lines :2076-2079 are the end/punctuation/dash test — read; the function is whole at :2070-2082). Probe A: `1`→keep, `2`→drop, `3`→done, `keep`→keep, `drop`→drop, `done`→done, `Keep.`→keep, `done — shipped`→done; `merge`, `re-dispatch`, `yes`, `[4]`→unrecognized. Practical consequence worth knowing: on a merge entry (options [1] merge, [2] drop, [3] changes needed), a user who answers "done" gets `done` and step 7 re-dispatches the loop ("changes needed"), and one who answers "merge" gets `unrecognized`. Precise version: "`[1]`, `1` or `keep` read as `keep`; `[2]`, `2` or `drop` as `drop`; `[3]`, `3` or `done` as `done`; any other answer, other words included, as `unrecognized`."

**Evidence:** `scripts/lib/dev-cycle-read.sh:2059-2082`, `scripts/dev-cycle.sh:62-68`, `out-a.txt`

---

## Claim 12: "A merge entry: `keep` runs `--merge BRIEF --expect TIP --approved Q-NNN`"

**Location:** `skills/dev-cycle/SKILL.md:529-530`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that `keep` from --check-answer is exactly what approval() accepts (it calls the same check_answer); does not establish the TIP-binding beyond the heading (claim 6) or MAIN_WT state at the merge.
**Legibility-target:** behavioral

```bash
# scripts/build-loop.sh:1447-1449
  check_answer "$1" > "$GATE_TMP/answer"; r="$(< "$GATE_TMP/answer")"
  case "$r" in
    "keep $1") ;;
```
(approval() continues to :1458 — read). Probe C's Q-002, answered `Q-002: keep` under the merge-gate heading, merged.

**Evidence:** `scripts/build-loop.sh:1441-1458`, `out-c.txt`

---

## Claim 13: "Add each ID acted on to the brief's `Applied:` line … so each answer is acted on once" (and design call 3: merge entries tracked on `Applied:`, not `Asked:`)

**Location:** `skills/dev-cycle/SKILL.md:534-535`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that --cycle-diff does not judge `Applied:` (or `Dispatched:`) lines and accepts a new open merge entry with no Asked: item; does not establish anything enforcing "once" (orchestrator bookkeeping; deferred row, i2 architecture 6).
**Legibility-target:** behavioral

`asked()` reads only `/^Asked:/` (`scripts/build-loop.sh:1908`), and brief_fields' keys are `Status|Branch|Policy|Paths|Asked|Dispatched` (`scripts/lib/dev-cycle-read.sh:448`). Probe B: a new `### Q-004 · merge-2026-10-01-x-<SHA12>` entry plus `Applied: Q-004` on the brief → `--cycle-diff` printed `ok`, exit 0; `Applied: Q-777` and `Dispatched: 1` lines landed through both lands.

**Evidence:** `scripts/build-loop.sh:1904-1908`, `scripts/lib/dev-cycle-read.sh:443-468`, `out-b.txt`

---

## Claim 14: "the policy lines `--status` reads: `Policy: self-merge` only when `--settings` prints `policy self-merge set` … then with it `Paths: PATH ...` … else `Policy: review` and no `Paths:` line" and "a line `Branch: NAME`"

**Location:** `skills/dev-cycle/SKILL.md:551-556`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers --status's POLICY and BRANCH reading and --check's Paths: reading of these line forms; does not establish whether the orchestrator can know a path is off the floor before the loop runs.
**Legibility-target:** behavioral

```bash
# scripts/build-loop.sh:899, :906
  if [[ ! "${BRIEF[branch]}" =~ ^Branch:\ ([^\ ]+)$ ]]; then STATUS[line]="skip $a: its first Branch: line is not exactly \"Branch: NAME\""; return; fi
  [[ "$POLICY" == self-merge && "${BRIEF[policy]-}" == "Policy: self-merge" ]] && pol=self-merge
```
(status_fields() spans :885-932 — read). Probe C used exactly these forms (`Policy: self-merge`, `Paths: work-feat-x.txt`) and got a self-merge verdict; `Paths: none` gave the S-rule deny.

**Evidence:** `scripts/build-loop.sh:885-932`, `scripts/build-loop.sh:23-31`, `scripts/build-loop.sh:381-392`, `out-c.txt`

---

## Claim 15: "The briefs land with step 9, so they are on the default branch before step 10 dispatches."

**Location:** `skills/dev-cycle/SKILL.md:567`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the order (step 9's land precedes step 10, and --start reads the brief from main's commit); does not establish that step 10 dispatches this iteration's new briefs: step 10's list ("briefs step 7 sends back first, then absent ones", :659-662) is step 7's reading, and step 7's single --status call ran before step 8 wrote them, so the text does not say whether a brief written this iteration is started now or next iteration.
**Legibility-target:** behavioral

dispatch() reads the brief via status_fields from `$MAIN_SHA` (`status_fields "$a"` then `[[ "$MODE" == start && "${STATUS[loop]}" != absent ]]`, `scripts/build-loop.sh:1625, :1638`), so a landed new brief reads `open … absent` and --start accepts it.

**Evidence:** `scripts/build-loop.sh:1621-1669`, `skills/dev-cycle/SKILL.md:655-662`

---

## Claim 16: "dated as the digest dates (`date +%F`, local time; the branch name's DATE-HHMM is UTC)"

**Location:** `skills/dev-cycle/SKILL.md:571-572`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers dev-cycle.sh's TODAY; does not establish that the digest's window logic uses TODAY for picking the newest record (it reads the record file name, not-future against today).
**Legibility-target:** doc-only

```bash
# scripts/dev-cycle.sh:139
TODAY="${DEV_CYCLE_TODAY:-$(date +%F)}"
```

**Evidence:** `scripts/dev-cycle.sh:138-139`, `scripts/dev-cycle.sh:16-20`

---

## Claim 17: "`Branch:` and `Main at:` stay unfenced at column 0: `--main-log` and `--land-cycle` find the iteration's land by its `Branch:` line"

**Location:** `skills/dev-cycle/SKILL.md:605-608`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers chore_record's whole-line match (column 0, a trailing CR dropped) in both modes, and that a per-day record changed by a second land still holds the line; does not establish fence handling (chore_record reads fenced lines too, so "unfenced" is stricter than the code needs).
**Legibility-target:** behavioral

```bash
# scripts/build-loop.sh:1750
    gate_git cat-file blob "${RAW_NO[i]}" | LC_ALL=C awk -v w="Branch: $1" '{ sub(/\r$/, "") } $0 == w { f = 1 } END { exit !f }' && return 0
```
(chore_record() spans :1746-1753 — read). Probe B: both lands of one iteration printed `landed chore/dev-cycle-2026-10-13-0242 …`, and `--main-log MAIN` read both merges as `chore`.

**Evidence:** `scripts/build-loop.sh:1742-1753`, `scripts/build-loop.sh:2071-2072`, `out-b.txt`

---

## Claim 18: "list under `### Paths landed` … `hg -C WT diff --cached --no-renames --name-status BASE`, BASE being `hg -C WT merge-base HEAD refs/heads/main`"

**Location:** `skills/dev-cycle/SKILL.md:616-619`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers BASE matching --cycle-diff's own base; does not establish the criss-cross case (--cycle-diff refuses `--all` with several bases; plain `merge-base` picks one).
**Legibility-target:** behavioral

```bash
# scripts/build-loop.sh:1880
  if ! base="$(git merge-base --all HEAD "$MAIN_SHA" 2>/dev/null)" || [[ -z "$base" ]]; then echo "refuse HEAD: …"; return 1; fi
```
(cycle_diff() spans :1878-1900 — read). Probe B's listing showed the four staged paths.

**Evidence:** `scripts/build-loop.sh:1878-1900`, `out-b.txt`

---

## Claim 19: step 9.3's list of `--cycle-diff` refusals, including "a side that is not a regular 100644 file, or a listing that fails (`refuse index`)"

**Location:** `skills/dev-cycle/SKILL.md:625-640`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each listed refusal against cycle_diff/cycle_rules/questions_rules (all present; the list is complete against the header); does not establish mode checks beyond the files named: the "not a regular 100644 file" refusal applies only to the questions files, roadmap, idea log and briefs.
**Legibility-target:** doc-only

Placed as a general item, "a side that is not a regular 100644 file" reads as applying to every path; the code checks modes only where it reads the blob (`cyc_blob`), i.e. in the brief branch (:1936), the roadmap/idea-log branch (:1955) and questions_rules (:2017). A cycle record falls through `*) continue ;;` (`scripts/build-loop.sh:1953`) and a docs/*.md fix is never read, so a symlink there passes (the Rules' own text at `SKILL.md:158` says so; row 771). Precise version: "…the idea log, roadmap, a brief or a questions file with a side that is not a regular 100644 file…". The other items (entries, questions-moved, idea log, roadmap, allowlist, GATE_CODE, truth files, case, Asked:, same-name paths, whole-file questions refusal; `refuse HEAD` for no/several bases) each match code at :1880-1897 and :1916-1999.

**Evidence:** `scripts/build-loop.sh:1870-1900`, `scripts/build-loop.sh:1914-1999`, `scripts/build-loop.sh:2003-2042`

---

## Claim 20: steps 9.4-9.5: "Commit … `--no-verify` … check `hg -C WT rev-parse HEAD^{tree}` prints T … `--land-cycle --main M` … `landed B HEAD TREE NEW`: check `… merge-base --is-ancestor HEAD refs/heads/main` … While MAIN_WT has main checked out, the land fast-forwards it"

**Location:** `skills/dev-cycle/SKILL.md:641-647`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the land sequence end to end in a fixture (index committed as --cycle-diff read it, tree check, landed line, ancestry, MAIN_WT fast-forwarded); does not establish hooks (the probe ran with no hooks configured) or the D6 block.
**Legibility-target:** behavioral

Probe B: `--cycle-diff` ok; tree check ok; `landed chore/dev-cycle-2026-10-13-0242 92b3c8f… 4e10be4… ba1d2d5…`, exit 0; is-ancestor ok; `MAIN_WT HEAD: ba1d2d5… main: ba1d2d5…`. land_cycle's own refusal for a moved main:

```bash
# scripts/build-loop.sh:2051
  [[ "$LAND_MAIN" == "$MAIN_SHA" ]] || { echo "refuse HEAD: the default branch is at $MAIN_SHA, not --main's $LAND_MAIN; merge it into HEAD, run --cycle-diff again and land with --main $MAIN_SHA"; return 1; }
```
(land_cycle() spans :2046-2081 — read)

**Evidence:** `scripts/build-loop.sh:2046-2081`, `out-b.txt`

---

## Claim 21: "and refuses while it has tracked edits or is mid-merge: a stop"

**Location:** `skills/dev-cycle/SKILL.md:646-647`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the tracked-edit refusal in land()'s W checks (executed through --merge, which shares land() with --land-cycle); does not establish the mid-merge case by execution (header :446-447) or the untracked-file-at-added-path refusal the text omits.
**Legibility-target:** behavioral

Probe E (via --merge, same `land` function): `refuse …: the worktree with the default branch checked out has a tracked change, or git status failed or warned there`. land_cycle calls it: `land cycle || { echo "refuse HEAD: $MERGE_WHY"; return 1; }` (`scripts/build-loop.sh:2079`).

**Evidence:** `scripts/build-loop.sh:442-451`, `scripts/build-loop.sh:2079`, `out-e.txt`

---

## Claim 22: "absent: `--start BRIEF`; any other: `--prompt BRIEF --steal`, which takes the lock at once when the loop under it has ended (a marker after the lock's tip), else only once both lock and tip are over two hours old, refusing \"under 2 hours old\" until then."

**Location:** `skills/dev-cycle/SKILL.md:662-664`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers --prompt --steal on a fresh working lock (refused, "under 2 hours old"), on an ended loop (marker after the lock's tip: taken at once), and on a lock that names the current marker (refused as live); does not establish the >2h steal by execution (time-dependent) or a lock reason without a UTC time (refused with another text).
**Legibility-target:** behavioral

```bash
# scripts/build-loop.sh:1611-1612
  [[ "$t" -le "$l" ]] || l="$t"
  [[ $(( $(date -u +%s) - l )) -gt "$STEAL_AGE" ]] || { STEAL_WHY="its worktree $WT is locked, and its lock or tip is under $(( STEAL_AGE / 3600 )) hours old"; return 1; }
```
(steal() spans :1601-1613 — read; ended() :1619-1623). Probe D: working loop → `refuse …: its worktree … is locked, and its lock or tip is under 2 hours old`; after a `handoff: blocked` commit → `ok … feat/x …` / `dispatched 1`; again on the same marker → the "under 2 hours old" refusal.

**Evidence:** `scripts/build-loop.sh:1594-1623`, `scripts/build-loop.sh:1644-1650`, `out-d.txt`

---

## Claim 23: "`ok BRIEF BRANCH DIR` and `dispatched N`: start one background subagent … whose prompt is every line after `dispatched N`, as printed"

**Location:** `skills/dev-cycle/SKILL.md:665-669`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers --start's output shape (two lines then the prompt); does not establish the appended "Answered for you" line's effect (the loop prompt itself says nothing about answers: `scripts/build-loop.sh:1675-1700`).
**Legibility-target:** behavioral

```bash
# scripts/build-loop.sh:1667-1668
  printf 'ok %s %s %s\ndispatched %s\n' "$a" "$br" "$DIR" "$n"
  loop_prompt "$a" "$stem" "$ct" "$n" "$tip"
```
Probe D: `ok docs/working/briefs/2026-10-01-x.md feat/x …/.claude/wt-2026-10-01-x`, `dispatched 1`, then the prompt (18 lines in all).

**Evidence:** `scripts/build-loop.sh:1621-1669`, `out-d.txt`

---

## Claim 24: "A refusal ending \"retry once it ends\" or saying \"under 2 hours old\" is tried again next iteration."

**Location:** `skills/dev-cycle/SKILL.md:670`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers both texts as printed and the header's "only two can clear with no change to the repository"; does not establish the git-failure refusals the header says "may clear on a retry" (routed to an agent entry here).
**Legibility-target:** behavioral

```bash
# scripts/build-loop.sh:2145
    flock -n 9 || { echo "refuse ${ARGS[0]}: another --start or --prompt is running in this repository; retry once it ends"; exit 2; }
```
The second text is claim 22's.

**Evidence:** `scripts/build-loop.sh:2145`, `scripts/build-loop.sh:493-497`

---

## Claim 25: "A brief `--status` read with DISPATCHED 4 (the cap, D1) is never dispatched again: one entry … (its item `Q-NNN` alone when TIP is `-`), slug `capped-STEM-N`"

**Location:** `skills/dev-cycle/SKILL.md:673-676`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the cap refusal and the bare `Q-NNN` item with a `capped-` slug passing --cycle-diff; does not establish options [1] keep/[2] drop against plan D1's `stopped: dispatch cap` (Won't-Fix row, i2 api-consistency 9).
**Legibility-target:** behavioral

```bash
# scripts/build-loop.sh:1595, :1637
DISPATCH_CAP=4; STEAL_AGE=7200
  elif [[ "${STATUS[dispatched]}" -ge "$DISPATCH_CAP" ]]; then x="it was dispatched ${STATUS[dispatched]} times, and the cap is $DISPATCH_CAP"
```
Probe D: `--status` → `… blocked c10db8f… 2026-10-13 4`; `--prompt --steal` → `refuse …: it was dispatched 4 times, and the cap is 4`. Probe B: `, Q-003` (capped-2026-10-01-y-1) passed --cycle-diff and --land-cycle.

**Evidence:** `scripts/build-loop.sh:1594-1595`, `scripts/build-loop.sh:1633-1640`, `out-d.txt`, `out-b.txt`

---

## Claim 26: "Then land again as step 9 does (1 to 5): the briefs' `Dispatched:` lines and the record's `10.` line … the count on main reads one low per lost line, one more loop run under the cap"

**Location:** `skills/dev-cycle/SKILL.md:678-683`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a second --cycle-diff/--land-cycle of the same chore branch after the first land (BASE moves to the first land's HEAD; the record still holds `Branch:`), and N computed from main's Dispatched: line; does not establish the questions-moved refusal on the second land when main's questions files moved meanwhile (the step's merge-main-in path covers it).
**Legibility-target:** behavioral

Probe B: second `--cycle-diff` ok; `landed chore/dev-cycle-2026-10-13-0242 737d7b7… 204fcbb… 829f70e…`; `--status` then read `… 1` for brief x. N is main's count plus one:

```bash
# scripts/build-loop.sh:1628
  br="${STATUS[branch]}"; stem="${a##*/}"; stem="${stem%.md}"; n=$(( ${STATUS[dispatched]} + 1 )); tip="${STATUS[sha]}"
```

**Evidence:** `scripts/build-loop.sh:1621-1669`, `scripts/build-loop.sh:900-904`, `out-b.txt`

---

## Claim 27: test "SKILL.md's merge-entry slug rule quotes the lib's GATE_CODE, which --approved's heading reads, on one line of its own (row 674, U4b2)" (with "Step 10 also names the dispatch cap and the steal age")

**Location:** `test/scripts/build-loop-orchestrator.bats:374-384`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the test passes and pins (a) exactly one SKILL.md line equal to two spaces plus the backquoted lib GATE_CODE, (b) the strings "with DISPATCHED 4 (the cap" and "\"under 2 hours old\"" derived from the script's constants; does not establish by itself that --approved reads GATE_CODE (true by code, claim 6) or that build-loop.sh prints "under 2 hours old" (true by construction from STEAL_AGE, claim 22).
**Legibility-target:** behavioral

```bash
# test/scripts/build-loop-orchestrator.bats:378, :383
    [ "$(grep -cxF "  $q$g$q" "$REPO_ROOT/skills/dev-cycle/SKILL.md")" -eq 1 ] || …
    grep -qF "with DISPATCHED $cap (the cap" "$REPO_ROOT/skills/dev-cycle/SKILL.md" && grep -qF "\"under $h hours old\"" "$REPO_ROOT/skills/dev-cycle/SKILL.md"
```
(the test spans :374-384 — read). Run: `ok 21 SKILL.md's merge-entry slug rule quotes the lib's GATE_CODE…`; suite 28/28 ok.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:374-384`, `skills/dev-cycle/SKILL.md:491`, `out-bats.txt`

---

## Claim 28: "A1: a working tip with no live loop went to --prompt without --steal, which refuses as a live lock; every non-marker tip now uses --steal."

**Location:** commit adc8a176 message (`git log -1 adc8a176`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers --prompt without --steal refusing a locked working loop ("a live loop may hold it") and the skill using --steal; does not establish the narrower phrase: the skill now passes --steal on every --prompt, marker tips included (harmless: an ended loop is taken without it).
**Legibility-target:** doc-only

Probe D without --steal: `refuse …: its worktree … is locked (locked build-loop dispatch of …): a live loop may hold it; --steal takes it once the lock and the tip are over 2 hours old`. `SKILL.md:662`: "any other: `--prompt BRIEF --steal`".

**Evidence:** `scripts/build-loop.sh:1601-1604`, `skills/dev-cycle/SKILL.md:662`, `out-d.txt`

---

## Claim 29: "A2: --merge from WT refuses for the checkout; a self-merge now runs from a detached gate worktree at main's commit, made per call and removed."

**Location:** commit adc8a176 message
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers --merge from WT; does not establish GT's removal (orchestrator text).
**Legibility-target:** doc-only

Probe C: from WT edited → refused for the checkout; from WT unedited, on its chore branch at main's commit → `merged …`, exit 0. So WT refuses only once the iteration has edited it or main has moved past WT's commit, which is what SKILL.md:480-482 says; the commit message drops that qualifier.

**Evidence:** `scripts/build-loop.sh:323-345`, `out-c.txt`

---

## Claim 30: "Thirteen findings deferred or Won't-Fix with override rows." and "The GATE_CODE pin test also pins DISPATCH_CAP and STEAL_AGE." (and 9777c1ff's "lands through --state, --cycle-diff, a hook-free commit of that index, and --land-cycle, merging main in on a moved main")

**Location:** commit c39a9692 message; commit 9777c1ff message
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count of added override rows (13, all dated 2026-10-13 for `feat/build-loop-u4b2`), the test's pins (claim 27), and the land sequence (claim 20); does not establish each deferral's merit.
**Legibility-target:** doc-only

`git diff main...HEAD -- docs/reviews/override-log.md` adds one hunk `@@ -783,3 +783,16 @@` of 13 `+|` table rows (paraphrased — no quote available because the rows are long table lines; counted by `grep '^+|'`).

**Evidence:** `docs/reviews/override-log.md:786-798`, `test/scripts/build-loop-orchestrator.bats:374-384`, `out-b.txt`, `out-bats.txt`

---

## Claims Requiring Attention

### Incorrect
- **Claim 11** (`skills/dev-cycle/SKILL.md:518-519`): --check-answer reads bare `1`/`2`/`3` and the words `keep`/`drop`/`done` (any case, then end, punctuation or a dash) as options, not only `[1]`-`[3]`; "words included" is wrong. Side effect worth stating in the entry text: "done" on a merge entry re-dispatches (changes needed), "merge" reads unrecognized.

### Mostly Accurate
- **Claim 4** (`skills/dev-cycle/SKILL.md:482-486`): path lines follow every --merge refusal of an ok verdict (no identity, MAIN_WT dirty or mid-merge, moved branch, rebase state), not only checkout/S-rule refusals, so step 7 files environment failures as merge entries (behavioral; the same MAIN_WT state at step 9.5 is a stop).
- **Claim 9** (`skills/dev-cycle/SKILL.md:508-510`): questions.sh matches only the full `<!-- index:start -->`; a bare `<!--` instead makes --check-answer skip the whole questions file. Replacement right, reason partial.
- **Claim 19** (`skills/dev-cycle/SKILL.md:630-631`): "a side that is not a regular 100644 file" applies only to the questions files, roadmap, idea log and briefs; records and docs/*.md fixes are not mode-checked.
- **Claim 29** (commit adc8a176): --merge from WT refuses only once WT is edited or main moved; an unedited WT at main's commit merges.

### Unverifiable
- None.

## Goal-Alignment Note

Success criterion: "A code-fact-check report saved at the given path, every checkable claim in the diff verdicted with evidence." Met for the claims enumerated here: 30 claims over SKILL.md steps 0.2 and 6-10, the new bats test, and the three commit messages, 23 of them executed in throwaway repos (probes A-E, the bats suite). Not done: claims in the unchanged U4b1 text (Rules' hg pairs, step 0.2's `-G` probe, D6 block) beyond what the diff touched; the >2 h steal path by execution (time-dependent); the D6 block (pending, Q-140), so every probe ran the worktree's scripts directly. Escalations: Claim 4 (behavioral routing of environment refusals) and Claim 11 (answer grammar stated wrongly in skill text the orchestrator reads); also Claim 15's residue (whether step 10 starts briefs written this iteration is not stated).
