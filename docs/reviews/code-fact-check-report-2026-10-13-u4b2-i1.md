# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u4b2 (feat/build-loop-u4b2)
**Scope:** branch diff `main...HEAD` at 9777c1ff: `skills/dev-cycle/SKILL.md` (new and changed text, plus unchanged cross-references the renumbering touches), `test/scripts/build-loop-orchestrator.bats` (one new test), commit 9777c1ff's message; checked against `scripts/build-loop.sh`, `scripts/dev-cycle.sh`, `scripts/lib/dev-cycle-read.sh`, `scripts/questions.sh`
**Checked:** 2026-10-13
**Replication:** k=1 (loop pass, decision 031)
**Commit:** 9777c1ff
**Total claims checked:** 27 (24 numbered, three split into a/b)
**Summary:** 20 verified, 1 mostly accurate, 2 stale, 4 incorrect, 0 unverifiable

Legibility-target per claim: **orchestrator** (text the orchestrator executes as an instruction; a wrong statement is behavioural) or **reader** (a human reading the skill, the test or the commit; doc-only).

Executed probes (scripts and captured output; all fixtures under their own `mktemp -d /tmp/u4b2rv-fc-XXXX`, git hermetic: `GIT_CONFIG_GLOBAL=/dev/null`, `GIT_CONFIG_NOSYSTEM=1`, fixture HOME). Scratch dir `S=/tmp/claude-1000/-workspace/3f9d7e3a-3058-4f14-a27e-9ecde97197ee/scratchpad/u4b2-i1/fc/`:

| Probe | Command (cwd `S`) | Started (UTC) | Exit | Output |
|---|---|---|---|---|
| P1 | `timeout 300 bash probe1.sh` | 2026-10-14T02:18:48Z | 0 | `S/probe1.out` |
| P2 | `timeout 300 bash probe2.sh` | 2026-10-14T02:19:18Z (rerun after a mkdir fix, same minute) | 0 | `S/probe2.out` |
| P3 | `timeout 300 bash probe3.sh` | 2026-10-14T02:19:43Z | 0 | `S/probe3.out` |
| P4 | `timeout 300 bash probe4.sh` | 2026-10-14T02:20:50Z | 0 | `S/probe4.out` |
| B1 | `TMPDIR=$(mktemp -d …) bats -f "merge-entry slug rule quotes" test/scripts/build-loop-orchestrator.bats` (cwd worktree) | 2026-10-14T02:20:28Z | 0 | `S/bats-gate-code.out` |
| B2 | `TMPDIR=$(mktemp -d …) bats -f "cycle-diff\|land-cycle" test/scripts/build-loop-orchestrator.bats` (cwd worktree) | 2026-10-14T02:21:40Z | 0 | `S/bats-cycle-diff-land.out` |

(The probe exit codes are the scripts'; each script records every build-loop.sh call's own exit in its output.)

---

## Claim 1: "Every subagent brief this cycle writes (steps 2, 3, 4 and 4b) and every build brief (step 6) says so."

**Location:** `skills/dev-cycle/SKILL.md:35-36`
**Type:** Staleness / Reference
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the step number this unchanged Rules line gives for build briefs; does not establish anything about the briefs' content rule itself, which step 8 still states.
**Legibility-target:** reader

The diff moves build-brief writing out of step 6 into a new step: `### 8. Build briefs` (`skills/dev-cycle/SKILL.md:515`), and step 6 is now `### 6. Roadmap` (`:409`) with no brief-writing text. The Rules line was not updated and still says "every build brief (step 6)". Fix: "(step 8)".

**Evidence:** `skills/dev-cycle/SKILL.md:35-36`, `skills/dev-cycle/SKILL.md:409`, `skills/dev-cycle/SKILL.md:515`

---

## Claim 2: "In flight's check 1 then moves it" / "so check 1 can close it" / "(check 1 moves it, never drops it)"

**Location:** `skills/dev-cycle/SKILL.md:173`, `:429`, `:454`
**Type:** Staleness / Reference
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers whether a "check 1" still exists for these three references to name; does not establish any behavioural difference (the single remaining check is the one meant).
**Legibility-target:** reader

The diff removed checks 2 and 3 and un-numbered the remaining one: `after its brief moved to \`closed/\`, each naming its brief path. Every cycle checks each:` (`skills/dev-cycle/SKILL.md:430`) followed by an unnumbered `` `--check-brief` prints `done` `` paragraph (`:431`). There is no numbered "check 1" left, yet `:173` (pre-existing, in the diff's context), `:429` (changed in this diff) and `:454` (new in this diff) still cite it. Fix: "In flight's check" (or restore the numbering).

**Evidence:** `skills/dev-cycle/SKILL.md:173`, `skills/dev-cycle/SKILL.md:428-441`, `skills/dev-cycle/SKILL.md:454`

---

## Claim 3: "a stop, with one `you: judgment` entry, once this session has landed a `Main at:` line ... across sessions nothing anchors this, a Q-103 residual"

**Location:** `skills/dev-cycle/SKILL.md:244-246`
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers that Q-103 exists as an open entry and that the bootstrap path is the one --main-log refuses with `main MAIN -`; does not establish that Q-103's list actually carries this residual (the entry was not edited in this diff).
**Legibility-target:** reader

`docs/working/questions.md:76` reads `### Q-103 · dev-cycle-build-loop-policy`. The header documents the bootstrap refusal: `or "main MAIN -" and refuse main-log: WHY, when SINCE ... is not on that history` (`scripts/build-loop.sh:181-184`). The new sentence adds only the stop condition; its logic (a Main at: this session landed and main later shows none means main was rewritten) is reasoning, not a script claim.

**Evidence:** `docs/working/questions.md:76`, `scripts/build-loop.sh:181-184`

---

## Claim 4: "skipped when step 0.2 read an `other` line, whose unreviewed test code it would run: row 776"

**Location:** `skills/dev-cycle/SKILL.md:291-292`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the row citation; does not establish that the health check is the only path that runs code from an `other` commit.
**Legibility-target:** reader

`docs/reviews/override-log.md:776` reads: `An \`other\` commit on main blocks dispatch, but step 1 still runs main's health check, so the ungated commit's test code runs (\`skills/dev-cycle/SKILL.md\` step 0.2, step 1; i2 security F5)` (excerpt ends mid-row; the row continues with its Defer rationale — read). The new text discharges exactly that row.

**Evidence:** `docs/reviews/override-log.md:776`

---

## Claim 5: "Step 9's `--cycle-diff` holds the roadmap to these moves (row 751): the lines above the first `## ` heading and the `## ` lines never change ..., and a brief file a line outside Done names stays named on some line ... The idea log is only appended to."

**Location:** `skills/dev-cycle/SKILL.md:452-455`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers --cycle-diff's roadmap-preamble, heading, dropped-brief-line and append-only idea-log refusals as the suite pins them; does not establish --land-cycle's handling of the same rules beyond the suite's own land tests.
**Legibility-target:** orchestrator

The header: `docs/roadmap.md: its lines above the first "## " heading or its "## " lines changed, or a brief file (docs/working/briefs/[closed/]NAME.md) named outside Done on BASE named on no line of the index` and `docs/working/idea-log.md other than appended to (BASE's bytes start the index's)` (`scripts/build-loop.sh:203-208`). The idea-log rule in code: `[[ "$(wc -c < "$t.n")" -ge "$k" ]] && cmp -s -n "$k" "$t.o" "$t.n" || { echo "refuse $p: edited other than by appending"; bad=1; }` (`scripts/build-loop.sh:1960`; enclosing cycle_rules continues to :2005 — read). B2's test 2, "--cycle-diff refuses a roadmap preamble, heading or dropped brief line and an idea log edited, not appended", passed.

**Evidence:** `scripts/build-loop.sh:200-215`, `scripts/build-loop.sh:1915-2005`, `S/bats-cycle-diff-land.out`

---

## Claim 6: "Read every loop's state (D4) with one `build-loop.sh --status` call naming every brief ... A `skip` line is recorded ... For each `ok` line whose STATE is `open`, by LOOP (TIP below is the line's SHA, the branch tip ...)"

**Location:** `skills/dev-cycle/SKILL.md:459-463`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers --status's line shape (STATE, POLICY, BRANCH, LOOP, SHA, DATE, DISPATCHED) and that SHA is the branch tip; does not establish every skip WHY.
**Legibility-target:** orchestrator

Header: `ok BRIEF STATE POLICY BRANCH LOOP SHA DATE DISPATCHED [REASON]` (`scripts/build-loop.sh:70`). P1 printed `ok docs/working/briefs/2026-10-01-x.md open self-merge feat/x ready 5103a206... 2026-10-13 0`, where 5103a206 is `git rev-parse feat/x`; P3 printed `... open review feat/x working fda91d12... 2026-10-13 0` for a loop with work and no marker.

**Evidence:** `scripts/build-loop.sh:66-103`, `scripts/build-loop.sh:886-929`, `S/probe1.out`, `S/probe3.out`

---

## Claim 7a: "One step 7 sends back ... `--prompt BRIEF`" (no `--steal`), for a brief whose tip is a handoff marker

**Location:** `skills/dev-cycle/SKILL.md:629-631` (with `:505-510`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a send-back whose branch tip is a ready/blocked/stopped marker with the dispatch lock naming an older tip; does not cover the working-tip send-backs in Claim 7b.
**Legibility-target:** orchestrator

`ended()` takes the lock without `--steal` when `[[ "${STATUS[loop]}" == ready || "${STATUS[loop]}" == blocked || "${STATUS[loop]}" == stopped ]] || return 1` (`scripts/build-loop.sh:1620`; enclosing ended() continues to :1623 — read: the lock's tip must differ from and be an ancestor of the marker). P3: after `handoff: stopped: cannot fix`, `--prompt` without `--steal` printed `ok ... feat/x .../wt-2026-10-01-x` and `dispatched 1`, exit 0.

**Evidence:** `scripts/build-loop.sh:1614-1623`, `S/probe3.out`

---

## Claim 7b: "unless its TIP has not moved in two hours ...: then stop its task by ID and file it as `stopped`, reason "stalled" ... Any other (its subagent ended with no marker ...) goes to step 10 for `--prompt`" with step 7's "A stopped entry: `keep` re-dispatches" and step 10's "one step 7 sends back ...: `--prompt BRIEF`" (`--steal` only for "a working one an ended session left")

**Location:** `skills/dev-cycle/SKILL.md:467-470`, `:506`, `:629-631`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers --prompt without --steal on a branch whose tip is not a marker (a stalled loop the orchestrator stopped, or a this-session subagent that ended with no marker) and whose worktree still carries the dispatch lock; does not establish what --steal does once both lock and tip are over two hours old (the steal path, statically consistent).
**Legibility-target:** orchestrator

A stalled or markerless loop leaves LOOP `working`, so `ended()` returns 1 at `scripts/build-loop.sh:1620`, and `steal()` returns 1 without the flag: `[[ -n "$STEAL" ]] || return 1` (`scripts/build-loop.sh:1604`). P3 (working tip, fresh lock, no `--steal`):

```
refuse docs/working/briefs/2026-10-01-x.md: its worktree .../wt-2026-10-01-x is locked (locked build-loop dispatch of 2026-10-01-x at 54a6996a..., UTC 2026-10-14T02:19:43Z): a live loop may hold it; --steal takes it once the lock and the tip are over 2 hours old
```

That text neither ends "retry once it ends" nor says "under 2 hours old", so step 10 routes it as "Any other refusal ...: recorded, and one `agent` entry" (`skills/dev-cycle/SKILL.md:637-639`). The re-dispatch that step 7 promises for a kept stalled entry (and the `--prompt` for a markerless ended subagent) never happens. The precise text should send these with `--steal` (a stalled tip is by construction over two hours old; the lock age must be too), or explain why not.

**Evidence:** `scripts/build-loop.sh:1601-1613`, `scripts/build-loop.sh:1614-1623`, `scripts/build-loop.sh:1641-1652`, `S/probe3.out`

---

## Claim 8a: "A refusal that path lines follow falls through to review: a merge entry as below, quoting `--merge`'s lines; one without them (a conflict, a failed read) is `stopped`."

**Location:** `skills/dev-cycle/SKILL.md:472-473`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which --merge refusals carry path lines (K-of-N, the checkout refusal, --merge's own post-verdict refusals) and which do not (check_line's early refusals); does not establish what the fall-through entry's heading must be (Claim 9b).
**Legibility-target:** orchestrator

Early refusals return before any path line: `1) echo "refuse $a: $br conflicts with the default branch"; return ;;` (`scripts/build-loop.sh:1367`; enclosing check_line continues to :1420 — read). The checkout refusal still prints rows: `if [[ -n "$co" ]]; then echo "$co"; elif ...` then `printf '%s\n' "${rows[@]}"` (`scripts/build-loop.sh:1419-1420`). P1 and P4 show path/deny lines following the refusal.

**Evidence:** `scripts/build-loop.sh:1351-1421`, `scripts/build-loop.sh:2120-2131`, `S/probe1.out`, `S/probe4.out`

---

## Claim 8b: "**ready**, POLICY `self-merge`: `--merge BRIEF --expect TIP`. A `merged` line goes in the record." (run, per the Rules, "from WT")

**Location:** `skills/dev-cycle/SKILL.md:471-472` (with Rules `:47-48`)
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers --merge's checkout rule for a self-merge brief run from the orchestrator's WT once WT has any tracked edit or main has moved past WT's HEAD; does not establish behaviour from a clean checkout of main (where it merges, P1).
**Legibility-target:** orchestrator

The Rules put every build-loop.sh call in WT (`skills/dev-cycle/SKILL.md:47-48`). By step 7, WT normally carries tracked edits (step 1's `questions.sh archive`, step 3/4 fixes, step 6's roadmap rewrite), and every merge step 7 makes moves main past WT's HEAD. The checkout rule refuses both: `[[ "$x" == "$MAIN_SHA" ]] || { CHECKOUT_WHY="the checkout's HEAD is $x, not the default branch's commit $MAIN_SHA"; return 1; }` (`scripts/build-loop.sh:1243`) and `CHECKOUT_WHY="the checkout's index or tracked files differ from that commit (git status)"` (`scripts/build-loop.sh:1262`; enclosing checkout_gate continues to :1299 — read). P1, WT with one appended roadmap line:

```
refuse docs/working/briefs/2026-10-01-x.md: a self-merge brief needs --check run from a clean checkout of the default branch's commit; the checkout's index or tracked files differ from that commit (git status)
path docs/working/briefs/2026-10-01-x.md A work.txt
```

The same --merge from the clean WT printed `merged ...`. So as written, the self-merge path practically never yields `merged`: it always falls through to a review merge entry (Claim 8a). The loop prompt also tells loops "The orchestrator's run, from the default branch's commit, decides" (`scripts/build-loop.sh:1679`), which the skill never arranges. Not a safety hole (fails closed), but self-merge policy is inert.

**Evidence:** `scripts/build-loop.sh:1235-1299`, `scripts/build-loop.sh:1396`, `scripts/build-loop.sh:1679`, `S/probe1.out`

---

## Claim 9a: "On `ok`, one merge entry, heading `### Q-NNN · merge-STEM-SHA12` (SHA12: TIP's first 12 hex digits), or `merge-gate-STEM-SHA12` when a `path` line's PATH, lower-cased, matches the lib's GATE_CODE ... `--approved` accepts no other heading" (review policy, `--check`)

**Location:** `skills/dev-cycle/SKILL.md:474-477`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the review-policy `--check` path, where every changed path prints as a `path` line unless an N rule denies it (and then the verdict is not `ok`); does not cover the self-merge fall-through (Claim 9b) or a gate path shown as `?`.
**Legibility-target:** orchestrator

`approval()`: `[[ -z "${VERDICT[gate]}" ]] || { s="merge-gate-"; ...}` then `s+="${VERDICT[stem]}-${VERDICT[tip]:0:12}"` (`scripts/build-loop.sh:1444-1445`) and `[[ "$ANSWER_HEADING" == "$1 · $s" ]]` (`:1456`); the gate flag: `[[ ! "${lps[$i]}" =~ $GATE_CODE ]] || gc=1` over lower-cased paths (`:1413`). P3: `--check` printed `path ... A scripts/lib/new.sh`; `--approved Q-010` under `merge-2026-10-01-g-c7792a53ab8b` refused (`its heading must read "Q-010 · merge-gate-2026-10-01-g-c7792a53ab8b"`), `--approved Q-011` under the `merge-gate-` heading printed `merged ...`.

**Evidence:** `scripts/build-loop.sh:1407-1421`, `scripts/build-loop.sh:1442-1458`, `S/probe3.out`

---

## Claim 9b: the same heading rule ("when a `path` line's PATH ... matches GATE_CODE") applied to step 7's self-merge fall-through, "a merge entry as below, quoting `--merge`'s lines"

**Location:** `skills/dev-cycle/SKILL.md:472-476`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a self-merge brief whose branch changes gate code, --merge run where the checkout passes (so the floor runs); does not establish the dirty-WT case, where the checkout refusal skips the floor and the gate path prints as a `path` line.
**Legibility-target:** orchestrator

For a self-merge brief the floor denies gate code, so the gate path is a `deny` line, not a `path` line: lib `gate) echo "the gate's own code, which lands only through a merge-gate- review entry" ;;` (`scripts/lib/dev-cycle-read.sh:2026`). P4 (clean main checkout, Paths: listing the gate file):

```
refuse ...: 1 of 2 changed paths refused in the merge of b124ed2e... (tree 9c1a3544...)
deny docs/working/briefs/2026-10-01-g.md A scripts/lib/new.sh: the gate's own code, which lands only through a merge-gate- review entry
path docs/working/briefs/2026-10-01-g.md A work.txt
```

Following the text, no `path` line matches GATE_CODE, so the orchestrator files `merge-STEM-SHA12`; `approval()` still sets the gate flag from all changed paths (`scripts/build-loop.sh:1413`) and demands `merge-gate-` (P3 shows that refusal), so the user's [1] lands nothing and the brief is filed `stopped`. Precise version: "a `path` or `deny` line's PATH".

**Evidence:** `scripts/build-loop.sh:1407-1421`, `scripts/lib/dev-cycle-read.sh:2026`, `S/probe4.out`, `S/probe3.out`

---

## Claim 10: "(a test holds this copy to it ...)" `^scripts/(build-loop|dev-cycle|questions)\.sh$|^scripts/lib/|^skills/dev-cycle/`

**Location:** `skills/dev-cycle/SKILL.md:477-478`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers byte equality of the quoted regex with the lib's GATE_CODE and that one SKILL.md line holds exactly it (two-space indent, backticks); does not establish that the test would catch a second, different copy elsewhere in SKILL.md.
**Legibility-target:** orchestrator

`GATE_CODE='^scripts/(build-loop|dev-cycle|questions)\.sh$|^scripts/lib/|^skills/dev-cycle/'` (`scripts/lib/dev-cycle-read.sh:1969`) matches `:478` byte for byte. B1 (the new test) passed.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1969`, `skills/dev-cycle/SKILL.md:478`, `S/bats-gate-code.out`

---

## Claim 11: "A `--marker` skip (row 701) whose WHY says the tip is no such marker, or that a read failed, is recorded and read again next iteration; any other WHY (the body breaks the marker rules or is too large) is filed as `stopped`"

**Location:** `skills/dev-cycle/SKILL.md:484-487`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that marker()'s skip WHYs split into those two families by fixed text; does not establish a WHY inherited from --status's skips (those briefs are already skipped by step 7's --status call).
**Legibility-target:** orchestrator

`skip $a: the tip of ${STATUS[branch]} is not a blocked or stopped marker (${STATUS[loop]})` (`scripts/build-loop.sh:953`); read failures say `its marker could not be read` / `its marker's body could not be read`; the rest name the cap, the body rule, an empty blocked body or a fence (`scripts/build-loop.sh:955-991`, read). P3 printed `skip ...: the tip of feat/x is not a blocked or stopped marker (working)`, exit 0.

**Evidence:** `scripts/build-loop.sh:948-1000`, `S/probe3.out`

---

## Claim 12: "slug `blocked-STEM-N` or `stopped-STEM-N` ... the shape `--cycle-diff` requires, Q-141 ... Add `Q-NNN@TIP` to the brief's `Asked:` line (", " between items; none yet: a line `Asked: ITEM` at its end)" (and step 10's `capped-STEM-N`, "one entry as step 7 files them")

**Location:** `skills/dev-cycle/SKILL.md:489-496`, `:640-643`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers --cycle-diff and --land-cycle accepting these slugs and Q-NNN@TIP items when the entry is filed in the same change, and refusing an item for an entry an earlier land filed or a `merge-` slug; does not establish N's "one more than the highest" counting (orchestrator arithmetic).
**Legibility-target:** orchestrator

`elif ! [[ "${newh[$id]#* · }" =~ ^[abcdefghijklmnopqrstuvwxyz]+(-[abcdefghijklmnopqrstuvwxyz]+)*-"${f%.md}"-[0123456789]+$ ]]` (`scripts/build-loop.sh:1993`; enclosing cycle_rules continues to :2005 — read). P2: a new `blocked-2026-10-01-x-1` and `stopped-...-1` with `Asked: Q-001@<40 hex>, Q-002@<40 hex>` passed `--cycle-diff` and `--land-cycle`; a second land adding `Q-004@TIP` for a new `capped-2026-10-01-x-1` passed; re-adding `Q-001@TIP` without a new entry refused (`names no question entry this change files`), and a `merge-...` slug on Asked: refused (`whose entry's heading is not WORDS-2026-10-01-x-N`).

**Evidence:** `scripts/build-loop.sh:1975-2004`, `S/probe2.out`

---

## Claim 13: "Then answers, only through `--check-answer` (main's commit ...), one call with the IDs of every brief's `Asked:` items and merge entries ... `[1]`, `[2]` and `[3]` read as `keep`, `drop` and `done`."

**Location:** `skills/dev-cycle/SKILL.md:498-501`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the option mapping and that only bare IDs are accepted (so the `@TIP` suffix of an Asked: item must be stripped, as "the IDs of" implies); does not establish the reading of free-text answers beyond [4] → unrecognized.
**Legibility-target:** orchestrator

`if (substr(s, 1, 3) == "[1]") return "keep"` / `"[2]"` → `"drop"` / `"[3]"` → `"done"` (`scripts/lib/dev-cycle-read.sh:2072-2074`; enclosing option() continues to :2080 — read). `if [[ ! "$a" =~ ^Q-[0123456789]+$ ]]; then echo "skip ...: not a question ID (Q- and digits)"` (`scripts/lib/dev-cycle-read.sh:2138`). P1 printed `keep Q-001`, `drop Q-002`, `done Q-003`, `unrecognized Q-004`, `skip Q-001@abcdef1: not a question ID (Q- and digits)`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:2070-2120`, `scripts/lib/dev-cycle-read.sh:2135-2162`, `S/probe1.out`

---

## Claim 14: "A merge entry: `keep` runs `--merge BRIEF --expect TIP --approved Q-NNN`, TIP the full one the entry names, never the branch's live tip"

**Location:** `skills/dev-cycle/SKILL.md:508-509`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that option 1 (`keep`) is what --approved accepts and that --expect binds the full tip; does not establish the stale-tip case's refusal text (statically: `the tip of $br is $sha, not the expected $EXPECT`).
**Legibility-target:** orchestrator

`"keep $1") ;;` and every other result sets MERGE_WHY (`scripts/build-loop.sh:1449-1455`); `if [[ -n "$EXPECT" && "$sha" != "$EXPECT" ]]; then echo "refuse $a: the tip of $br is $sha, not the expected $EXPECT"` (`scripts/build-loop.sh:1364`). P3's approved merge landed with the full TIP.

**Evidence:** `scripts/build-loop.sh:1442-1458`, `scripts/build-loop.sh:1364`, `S/probe3.out`

---

## Claim 15: "a line `Branch: NAME` ... and the policy lines `--status` reads: `Policy: self-merge` only when `--settings` prints `policy self-merge set` ..., then with it `Paths: PATH ...` naming those paths (single spaces ...); else `Policy: review` and no `Paths:` line."

**Location:** `skills/dev-cycle/SKILL.md:528-533`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers --status reading POLICY and BRANCH from these lines and --check's Paths: form; does not establish the "never one under docs/reviews/" advice beyond the header's own-file rule.
**Legibility-target:** orchestrator

Header: `POLICY: self-merge only when --settings' policy is self-merge and the brief's first "Policy:" line is exactly "Policy: self-merge"; else review. BRANCH: from the brief's first "Branch: NAME" line` (`scripts/build-loop.sh:74-77`) and `"Paths: PATH ..." lists paths pathform allows, with single spaces, each once` (`:380-381`). P1: `--settings` printed `policy self-merge set: line 3 ...`, and `--status` read the brief (`Policy: self-merge`, `Paths: work.txt`) as `self-merge feat/x`; P3 read a brief with no Policy: line as `review`.

**Evidence:** `scripts/build-loop.sh:66-103`, `scripts/build-loop.sh:370-385`, `S/probe1.out`, `S/probe3.out`

---

## Claim 16: "Later iterations add `Asked:`, `Applied:` and `Dispatched:` lines at its end ..." / "Write `Dispatched: N` on the brief (the old line replaced; none yet: a new line at its end)"

**Location:** `skills/dev-cycle/SKILL.md:541-543`, `:635-636`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers --status reading the first Dispatched: line, --cycle-diff judging only the first unfenced Asked: line of a brief and leaving Applied:/Dispatched: unjudged; does not establish 3-way merge behaviour of a loop's Status change against these end-of-file lines on a short brief.
**Legibility-target:** orchestrator

`[[ "${BRIEF[dispatched]}" =~ ^Dispatched:\ (0|[123456789][0123456789]?)$ ]] || { STATUS[line]="skip $a: its first Dispatched: line is not exactly ..."` (`scripts/build-loop.sh:902-903`). For brief paths, cycle_rules records only `ao[$f]="$(asked "$t.o")"` / `an[$f]=...` and `continue`s (`scripts/build-loop.sh:1933-1944`), so other brief lines pass. P2 landed `Applied: Q-000` and `Dispatched: 1` through both --cycle-diff and --land-cycle.

**Evidence:** `scripts/build-loop.sh:886-929`, `scripts/build-loop.sh:1925-1945`, `S/probe2.out`

---

## Claim 17: "Write the record `docs/working/cycles/cycle-YYYY-MM-DD.md`, dated as the digest dates (`date +%F`, local time ...)"

**Location:** `skills/dev-cycle/SKILL.md:548-549`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the digest's own date source; does not establish anything about a mid-iteration midnight crossing.
**Legibility-target:** orchestrator

`TODAY="${DEV_CYCLE_TODAY:-$(date +%F)}"` (`scripts/dev-cycle.sh:139`). No script matches the record's date to the branch name's DATE: chore_record checks only `isrecord` and the `Branch: B` line (`scripts/build-loop.sh:1743-1750`), so the local-vs-UTC split cannot refuse a land.

**Evidence:** `scripts/dev-cycle.sh:139`, `scripts/build-loop.sh:1739-1751`, `scripts/lib/dev-cycle-read.sh:246`

---

## Claim 18: "`Branch:` and `Main at:` stay unfenced at column 0: `--main-log` and `--land-cycle` find the iteration's land by its `Branch:` line"

**Location:** `skills/dev-cycle/SKILL.md:580-581`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the exact-line match (a trailing CR dropped) that both modes share; does not establish that a fenced `Branch:` line would fail (the awk matches any whole line, fenced or not, so "unfenced" is a convention, not a check).
**Legibility-target:** orchestrator

`gate_git cat-file blob "${RAW_NO[i]}" | LC_ALL=C awk -v w="Branch: $1" '{ sub(/\r$/, "") } $0 == w { f = 1 } END { exit !f }' && return 0` (`scripts/build-loop.sh:1748`). P2: both lands printed `landed chore/dev-cycle-2026-10-13-0900 ...`, and `--main-log` from M0 classed both merges `chore`.

**Evidence:** `scripts/build-loop.sh:1743-1751`, `scripts/build-loop.sh:2073`, `S/probe2.out`

---

## Claim 19: land steps 1-5: "BASE being `hg -C WT merge-base HEAD refs/heads/main`" · "`--state` ... Read M ... and T, `hg -C WT write-tree`" · "Commit what `--cycle-diff` read: `... commit -q --no-verify -F MSGFILE` ... check `... rev-parse HEAD^{tree}` prints T" · "`--land-cycle --main M` ... `landed B HEAD TREE NEW`: check `merge-base --is-ancestor HEAD refs/heads/main`" · "While MAIN_WT has main checked out, the land fast-forwards it"; and step 10's "Then land again as step 9 does (1 to 5)"

**Location:** `skills/dev-cycle/SKILL.md:590-615`, `:645-646`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the full sequence twice on one chore branch (the second land with BASE = the first land's HEAD), with MAIN_WT having main checked out; does not establish the refusals on MAIN_WT's tracked edits or mid-merge state (header only), nor the merge-main-in path (`:617-619`, not executed).
**Legibility-target:** orchestrator

`base="$(git merge-base --all HEAD "$MAIN_SHA" ...)"` (`scripts/build-loop.sh:1882`). P2, land 1: `--state` ok, `--cycle-diff` ok, `tree matches T`, `landed chore/dev-cycle-2026-10-13-0900 c99a6b20... d51f4e23... 2f2f9d1a...`, `HEAD is an ancestor of main`; land 2: `BASE c99a6b20...` (the first land's HEAD), `--cycle-diff` ok, `landed ... f2d649ae...`. B2's test 4 covers the fast-forward where main is checked out.

**Evidence:** `scripts/build-loop.sh:1880-1900`, `scripts/build-loop.sh:2046-2080`, `scripts/build-loop.sh:244-270`, `S/probe2.out`, `S/bats-cycle-diff-land.out`

---

## Claim 20: "It refuses (rows 745, 757): a questions entry's heading, **Needs:** or answer lines changed or gone, or a new entry filed answered, without `--answered`; a questions change while main's questions files changed since BASE; the idea log other than appended to; the roadmap moves step 6 names; any path but the cycle's own files, a `.md` under `docs/` or `README.md`; the gate's own code; a truth file (instruction files, dot paths, `docs/dev-cycle.md`, `docs/constraints.md`, `docs/decisions/`, `docs/human-author/`); a cycle file in another case; and an `Asked:` line other than extended by items step 7's form allows."

**Location:** `skills/dev-cycle/SKILL.md:599-606`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed refusal against the header and cycle_rules (B2 tests 1-3 pass); does not establish completeness, which it lacks.
**Legibility-target:** orchestrator

Every listed case exists (`scripts/build-loop.sh:1922-1934`, `:1952-1960`, `:1975-2004`; B2 tests 1-3). The list omits refusals the orchestrator can hit: deleting the roadmap or idea log, or a side not a regular 100644 file (`echo "refuse $p: it is deleted"`, `scripts/build-loop.sh:1956`; header `:209-211`); a brief with an Asked: line deleted or renamed to another file name (`refuse ${aop[$f]}: deleted or renamed with its Asked: line`, `:1979`); two changed brief paths sharing a file name (`:1943`); `refuse index` when the staged changes cannot be listed (`:1888`); and "prompt files" in the truth list (header `:221`). Since step 9.3's remedy line ("The remedy for each is to unstage or fix") reads as exhaustive, add "and the rest of the header's list".

**Evidence:** `scripts/build-loop.sh:185-235`, `scripts/build-loop.sh:1880-2005`, `S/bats-cycle-diff-land.out`

---

## Claim 21: "`ok BRIEF BRANCH DIR` and `dispatched N`: start one background subagent ... whose prompt is every line after `dispatched N`" · "A refusal ending "retry once it ends" or saying "under 2 hours old" is tried again next iteration" · "`--steal`, which takes a lock only when both it and the tip are over two hours old"

**Location:** `skills/dev-cycle/SKILL.md:629-639`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers --start/--prompt's first two lines, the prompt following them, the two retryable texts and --steal's age rule; does not cover the send-back routing defect in Claim 7b.
**Legibility-target:** orchestrator

`printf 'ok %s %s %s\ndispatched %s\n' "$a" "$br" "$DIR" "$n"` then `loop_prompt ...` (`scripts/build-loop.sh:1667-1668`); `flock -n 9 || { echo "refuse ${ARGS[0]}: another --start or --prompt is running in this repository; retry once it ends"; exit 2; }` (`:2145`); `STEAL_WHY="its worktree $WT is locked, and its lock or tip is under $(( STEAL_AGE / 3600 )) hours old"` after `[[ "$t" -le "$l" ]] || l="$t"` (the later of lock and tip time must be over 7200 s: `:1611-1612`). P3: `--start` printed `ok ... feat/x .../wt-2026-10-01-x`, `dispatched 1`, then the prompt's first line; `--prompt --steal` on a fresh lock printed the "under 2 hours old" text.

**Evidence:** `scripts/build-loop.sh:1595-1613`, `scripts/build-loop.sh:1628-1669`, `scripts/build-loop.sh:2136-2148`, `S/probe3.out`

---

## Claim 22: "A brief `--status` read with DISPATCHED 4 (the cap, D1) is never dispatched again"

**Location:** `skills/dev-cycle/SKILL.md:640`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers --start and --prompt refusing at Dispatched: 4 as main records it; does not establish the count's accuracy when a Dispatched: line is lost (Claim 23).
**Legibility-target:** orchestrator

`DISPATCH_CAP=4` (`scripts/build-loop.sh:1595`); `elif [[ "${STATUS[dispatched]}" -ge "$DISPATCH_CAP" ]]; then x="it was dispatched ${STATUS[dispatched]} times, and the cap is $DISPATCH_CAP"` (`:1637`). P3: `refuse ...-y.md: it was dispatched 4 times, and the cap is 4`, exit 2.

**Evidence:** `scripts/build-loop.sh:1595`, `scripts/build-loop.sh:1637`, `S/probe3.out`

---

## Claim 23: "Then land again as step 9 does (1 to 5): the briefs' `Dispatched:` lines and the record's `10.` line. A stop here loses only those lines; the next iteration writes them."

**Location:** `skills/dev-cycle/SKILL.md:645-646`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers whether any later step re-derives and writes a lost `Dispatched: N` or `10.` line; does not establish how often the second land stops.
**Legibility-target:** orchestrator

No later step writes them (paraphrased — no quote available because the claim is about absence: steps 7-10 at `skills/dev-cycle/SKILL.md:457-647` were read in full). N is printed only by `--start`/`--prompt` at dispatch (`printf 'ok %s %s %s\ndispatched %s\n'`, `scripts/build-loop.sh:1667`), and the dispatched loop then reads as `working` (held by this session's subagent), which step 10 does not dispatch again, so no N is printed for the next iteration to write. A stop also removes WT with `--force` (`skills/dev-cycle/SKILL.md:64-65`), discarding the uncommitted line, and a record block is "never edit[ed]" by later iterations (`:550`). Consequence: main's count stays one short, and --status's DISPATCHED (which the cap reads, `scripts/build-loop.sh:1637`) undercounts until the next dispatch of that brief prints the same N again. Precise version: "A stop here loses those lines: that dispatch goes uncounted on main (the cap reads one fewer) and the record lacks its `10.` line."

**Evidence:** `skills/dev-cycle/SKILL.md:457-647`, `scripts/build-loop.sh:1628-1669`, `scripts/build-loop.sh:1637`

---

## Claim 24: Test name "SKILL.md's merge-entry slug rule quotes the lib's GATE_CODE, which --approved's heading reads, on one line of its own (row 674, U4b2)"; commit 9777c1ff: "files merge entries with the --approved heading rule (GATE_CODE quoted, pinned to the lib by a test) ... lands through --state, --cycle-diff, a hook-free commit of that index, and --land-cycle, merging main in on a moved main ... Step 6 drops keep-or-drop (checks 2-3) and names --cycle-diff's roadmap rule."

**Location:** `test/scripts/build-loop-orchestrator.bats:374-379`; commit `9777c1ff` message
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test's assertion (lib GATE_CODE sourced, exactly one SKILL.md line `  \`GATE_CODE\``), that approval's gate flag reads GATE_CODE, row 674's subject, and the commit message's sequence and step-6 claims; does not establish that the "merge entries with the --approved heading rule" are correct in the self-merge fall-through (Claim 9b), or that "merging main in" was executed (not probed).
**Legibility-target:** reader

Test body: `[ "$(grep -cxF "  $q$g$q" "$REPO_ROOT/skills/dev-cycle/SKILL.md")" -eq 1 ]` (`test/scripts/build-loop-orchestrator.bats:377`); B1 passed. Approval reads GATE_CODE through `gc` (`scripts/build-loop.sh:1413`, `:1444`). Row 674 is the deferred "--check ... print neither VERDICT[gate] nor the heading --approved will accept, so the merge-entry filer re-derives the slug rule" (`docs/reviews/override-log.md:674`, excerpt ends mid-row — read). The land sequence ran clean twice in P2. Checks 2-3 (keep-or-drop) are gone from step 6 in the diff and `:452-455` names the roadmap rule.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:374-379`, `scripts/build-loop.sh:1413`, `docs/reviews/override-log.md:674`, `S/bats-gate-code.out`, `S/probe2.out`

---

## Claims Requiring Attention

### Incorrect
- **Claim 7b** (`skills/dev-cycle/SKILL.md:467-470, 506, 629-631`): a stalled loop the orchestrator stopped, or a this-session subagent that ended with no marker, has a working tip and a live lock; `--prompt` without `--steal` refuses with "a live loop may hold it", which step 10 routes as an agent entry, so "keep re-dispatches" never happens. Send these with `--steal` (or say why not).
- **Claim 8b** (`skills/dev-cycle/SKILL.md:471-472` with Rules `:47-48`): `--merge` for a self-merge brief run from WT refuses for the checkout whenever WT has a tracked edit (steps 1/3/4/6 make them) or a step 7 merge moved main; self-merge never yields `merged` as written. Run self-merge `--merge` from a clean checkout of main's commit, or document that self-merge always falls through to review.
- **Claim 9b** (`skills/dev-cycle/SKILL.md:472-476`): on the self-merge fall-through with the floor run, gate code prints as a `deny` line, not a `path` line; the heading rule keyed on `path` lines files `merge-` where `--approved` needs `merge-gate-`. Say "a `path` or `deny` line's PATH".
- **Claim 23** (`skills/dev-cycle/SKILL.md:645-646`): nothing writes a lost `Dispatched: N` or `10.` line later; the dispatch goes uncounted on main (the cap reads one fewer).

### Stale
- **Claim 1** (`skills/dev-cycle/SKILL.md:36`): "every build brief (step 6)" is now step 8.
- **Claim 2** (`skills/dev-cycle/SKILL.md:173, 429, 454`): "check 1" names a numbered check that no longer exists after checks 2-3 were removed.

### Mostly Accurate
- **Claim 20** (`skills/dev-cycle/SKILL.md:599-606`): the `--cycle-diff` refusal list omits the roadmap/idea-log deletion, non-regular sides, an Asked:-line brief deleted or renamed, two brief paths sharing a name, `refuse index`, and prompt files; add "and the rest of the header's list".

### Unverifiable
- None. The merge-main-in command (`skills/dev-cycle/SKILL.md:617-619`) was not executed; it is named in Claims 19 and 24 as residue, not verdicted.

## Escalations

1. **Self-merge is inert from WT (Claim 8b), behavioural, blocking-grade for the D7 self-merge path.** Executed: P1. Fails closed (falls through to a review entry), so not a safety issue, but plan D7's self-merge never happens as the skill is written.
2. **Send-back of a working-tip loop never dispatches (Claim 7b), behavioural.** Executed: P3. A kept "stalled" entry becomes an agent entry instead of a re-dispatch.
3. **merge-gate heading on the self-merge fall-through (Claim 9b), behavioural.** Executed: P4 + P3. The user's approval lands nothing; the brief is filed stopped. Only reachable when the checkout passes, i.e. once escalation 1 is fixed, so the two fixes interact.

## Goal-Alignment Note

Success criterion: "A code-fact-check report saved at the given path, every checkable claim in the diff verdicted with evidence." Met for the claims the brief named (steps 7-10's script contracts, step 6's roadmap rule, step 0.2/1 changes, the new test, the commit message), each with quoted code and, for every executable script-mode claim, an executed probe with captured output. Not exhaustively atomized: the Final message and Wait (D12) paragraphs (`skills/dev-cycle/SKILL.md:649-662`) and the queue-counting rule in step 8 (`:517-520`) are orchestrator design rules with no script contract to check them against, so they carry no verdict; the merge-main-in command (`:617-619`) was checked only statically against the header's "a git merge with git's defaults (no -s or -X...)" wording. No hallucination-pattern entry was added: none of the Incorrect claims names a symbol, flag or API that does not exist.
