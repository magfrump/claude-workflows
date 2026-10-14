# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u4b2 (feat/build-loop-u4b2)
**Scope:** full branch `main...HEAD`: `skills/dev-cycle/SKILL.md` (whole post-change file read; claims taken from the changed text and the unchanged text it relies on), `test/scripts/build-loop-orchestrator.bats` (the one new test), and the messages of 9777c1ff, adc8a176 and c39a9692; checked against `scripts/build-loop.sh`, `scripts/dev-cycle.sh`, `scripts/lib/dev-cycle-read.sh`, `scripts/questions.sh`
**Checked:** 2026-10-13
**Replication:** replicate r1 of 3 (final pass, iteration 3)
**Commit:** c39a9692
**Total claims checked:** 40 (35 numbered; Claims 4 and 9 split into a/b/c, Claim 35 into a/b)
**Summary:** 30 verified, 4 mostly accurate, 0 stale, 6 incorrect, 0 unverifiable

Legibility-target per claim: **orchestrator** (text the orchestrator executes; a wrong statement is behavioural), **reader** (a maintainer or reviewer reading the text or a commit message; doc-only) or **maintainer** (a test's own description).

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`, 5 entries): no claim here matches a logged pattern. No Incorrect verdict below is a fabrication (every named symbol, mode and line exists), so the log needs no new entry.

Executed probes. Scratch dir `S=/tmp/claude-1000/-workspace/3f9d7e3a-3058-4f14-a27e-9ecde97197ee/scratchpad/u4b2-i3/fc-r1/`. Every fixture repo is under its own `mktemp -d /tmp/u4b2rv-fc-r1-XXXX` (named in each output's first line), with hermetic git (`GIT_CONFIG_GLOBAL=/dev/null`, `GIT_CONFIG_NOSYSTEM=1`, a fixture HOME; `S/common.sh`). The scripts run from the worktree at c39a9692. Each `=== LABEL (exit N)` line in an output file gives that call's own exit code.

| Probe | Command (cwd `S`) | Started (UTC) | Exit | Output |
|---|---|---|---|---|
| PA | `LC_ALL=C timeout 300 bash probeA.sh` | 2026-10-14T02:43:05Z | 0 | `S/probeA.out` |
| PB | `LC_ALL=C timeout 300 bash probeB.sh` | 2026-10-14T02:43:38Z | 0 | `S/probeB.out` |
| PC | `LC_ALL=C timeout 300 bash probeC.sh` (PB with a safe reason line, plus Asked:/Dispatched: and merge-in cases) | 2026-10-14T02:44:34Z | 0 | `S/probeC.out` |
| PD | `LC_ALL=C timeout 300 bash probeD.sh` (second run; the first used an end-of-file questions change that conflicted) | 2026-10-14T02:45:43Z | 0 | `S/probeD.out` |
| PE | `LC_ALL=C timeout 300 bash probeE.sh` | 2026-10-14T02:46:36Z | 0 | `S/probeE.out` |
| BT | `TMPDIR=$(mktemp -d /tmp/u4b2rv-fc-r1-XXXX) LC_ALL=C timeout 600 bats -f "merge-entry slug rule quotes" test/scripts/build-loop-orchestrator.bats` (cwd worktree) | 2026-10-14T02:46:43Z | 0 | `S/bats-gate-code.out` |
| PF | `LC_ALL=C timeout 300 bash probeF.sh` (second run, after a missing `mkdir`) | 2026-10-14T02:47:22Z | 0 | `S/probeF.out` |

---

## Claim 1: "0 start and digest → 1 health and cleanup → … → 6 roadmap → 7 collect → 8 build briefs → 9 record and land → 10 dispatch → final message → wait or go again"

**Location:** `skills/dev-cycle/SKILL.md:212-216`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the Flow's step names and order against the step headings. It does not cover the steps' content.
**Legibility-target:** reader

The headings read `### 6. Roadmap`, `### 7. Collect`, `### 8. Build briefs`, `### 9. Record and land` and `### 10. Dispatch` (`skills/dev-cycle/SKILL.md:412`, `:460`, `:537`, `:569`, `:653`). The final message and the wait rule follow step 10 (`:685`, `:694`).

**Evidence:** `skills/dev-cycle/SKILL.md:212-216`, `:412-698`

---

## Claim 2: "Every `build-loop.sh` and `dev-cycle.sh` call runs from WT (step 0's first two from MAIN_WT, step 7's self-merge from its GT)"

**Location:** `skills/dev-cycle/SKILL.md:47-48`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every script call that steps 0-10 name: none runs elsewhere. It does not establish that the D6 block runs from GT (that block is pending, Q-140).
**Legibility-target:** orchestrator

Step 7 runs `--state` "(from WT)" before `hg -C MAIN_WT worktree add --detach GT refs/heads/main`, and runs only `--merge` from GT (`skills/dev-cycle/SKILL.md:477-482`). Step 9 runs "all from WT" (`:613`). Step 10's `--main-log`, `--settings`, `--start` and `--prompt` name no other checkout (paraphrased — no quote available because the claim is about the absence of any other location across `:653-683`).

**Evidence:** `skills/dev-cycle/SKILL.md:47-48`, `:477-482`, `:613`, `:653-683`

---

## Claim 3: "Read every loop's state (D4) with one `build-loop.sh --status` call … A `skip` line is recorded … (TIP below is the line's SHA, the branch tip; STEM the brief's file name without `.md`)"

**Location:** `skills/dev-cycle/SKILL.md:462-466`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `--status`'s line shape and LOOP values for absent, working, ready, blocked and stopped briefs, and REASON printed last. It does not cover every skip WHY.
**Legibility-target:** orchestrator

The header gives `ok BRIEF STATE POLICY BRANCH LOOP SHA DATE DISPATCHED [REASON]` (`scripts/build-loop.sh:70`). PB printed, among others:

```
ok docs/working/briefs/2026-10-01-c.md open review feat/c stopped d58835772695c3d4cc7353e5ae34d11df73e0ae6 2026-10-13 0 hit <!-- marker
ok docs/working/briefs/2026-10-01-d.md open review feat/d absent - - 0
```

**Evidence:** `scripts/build-loop.sh:67-98`, `:886-928`, `S/probeB.out`

---

## Claim 4a: "**ready**, POLICY `self-merge`: `--merge BRIEF --expect TIP`, run from a gate checkout, not WT … (the self-merge floor reads a clean checkout of main's commit, which WT is not once this iteration has edited it …)"

**Location:** `skills/dev-cycle/SKILL.md:477-482`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the refusal from an edited WT and the merge from a detached GT at main's commit. It does not cover GT's removal or a reused GT name (override row 788).
**Legibility-target:** orchestrator

PB, WT with one tracked edit, then GT:

```
=== merge E from edited WT (exit 2)
refuse docs/working/briefs/2026-10-01-e.md: a self-merge brief needs --check run from a clean checkout of the default branch's commit; the checkout's index or tracked files differ from that commit (git status)
...
=== merge E from GT, clean (exit 0)
merged docs/working/briefs/2026-10-01-e.md 9ff322d5…
```

The refusal comes from `checkout_gate`: `[[ ! -s "$GATE_TMP/status" ]] || { CHECKOUT_WHY="the checkout's index or tracked files differ from that commit (git status)"; return 1; }` (`scripts/build-loop.sh:1262`; enclosing checkout_gate continues to :1298 — read).

**Evidence:** `scripts/build-loop.sh:1235-1298`, `S/probeB.out`

---

## Claim 4b: "A refusal that `path` or `deny` lines follow falls through to review: a merge entry as below, quoting `--merge`'s lines …; one without them (a conflict, a failed read) is `stopped`."

**Location:** `skills/dev-cycle/SKILL.md:482-486`
**Type:** Behavioral / Error-handling
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which `--merge` refusals carry path lines. It does not establish how often the land-time refusals occur.
**Legibility-target:** orchestrator

The rule uses path lines as the sign of a path-based refusal (floor, never glob, Paths:, an N rule). But `--merge` also prints the path lines after every refusal from `land()`, which is about the repository, not the paths:

```bash
# scripts/build-loop.sh:2130-2132
    elif [[ "$AUTH" == approved ]] && ! approval "$APPROVED"; then v="refuse $a: $MERGE_WHY"
    elif land "$AUTH" "$APPROVED"; then v="merged $a ${VERDICT[tip]} ${VERDICT[tree]} $NEW"; else v="refuse $a: $MERGE_WHY"; fi
    { echo "$v"; tail -n +2 "$GATE_TMP/line"; }
```

(excerpt ends :2132; the enclosing `merge)` case continues to :2134 — read). The header documents this: "or refuse BRIEF: WHY, with the ok line's path lines following, when: … no identity is known; … the branch moved since the check … With the branch checked out in W, also when … has a tracked change" (`scripts/build-loop.sh:427-451`). PB, with one tracked edit in MAIN_WT:

```
=== merge E from GT, MAIN_WT dirty (exit 2)
refuse docs/working/briefs/2026-10-01-e.md: the worktree with the default branch checked out has a tracked change, or git status failed or warned there
path docs/working/briefs/2026-10-01-e.md A docs/e.md
```

Acting on the text, the orchestrator files a `you: judgment` merge entry for a dirty MAIN_WT, a missing identity or a race. The user's [1] then runs `--merge --approved`, which goes through the same `land()` and refuses again while the cause stands, so the brief is then filed `stopped`. That is two user judgments for an environment fault. Step 9.5 treats the same MAIN_WT condition as a stop (`skills/dev-cycle/SKILL.md:645-647`). Precise version: route a refusal by its WHY. A K-of-N refusal, or the checkout refusal, gets a merge entry. A refusal from `land()` (the header's list at `scripts/build-loop.sh:432-451`) is a stop, or a retry.

**Evidence:** `scripts/build-loop.sh:427-456`, `:1486-1572`, `:2122-2134`, `skills/dev-cycle/SKILL.md:482-486`, `:645-647`, `S/probeB.out`, `S/probeC.out`

---

## Claim 4c: "(a deny from a rule every merge applies refuses again under `--approved`, and is then filed as `stopped`)"

**Location:** `skills/dev-cycle/SKILL.md:484-485`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers an N-rule deny (the brief's own file edited beyond its Status line) and an S-rule deny (an instruction file) under `--approved`. It does not cover every N rule.
**Legibility-target:** orchestrator

PE: brief G's own-file deny refuses both self-merge and `--approved Q-004`, "deny … M docs/working/briefs/2026-10-01-g.md: this brief: only its first Status: line outside a fence may change, from open to done". Brief F's floor deny (`AGENTS.md`) refuses self-merge but merges under `--approved Q-003`. This matches `[[ "$pol" != self-merge || "$AUTH" == approved ]] || sm=1  # the S rules and the checkout` (`scripts/build-loop.sh:1360`; enclosing check_line continues to :1419 — read).

**Evidence:** `scripts/build-loop.sh:1143-1167`, `:1351-1419`, `S/probeE.out`

---

## Claim 5: "heading `### Q-NNN · merge-STEM-SHA12` …, or `merge-gate-STEM-SHA12` when a `path` or `deny` line's PATH, lower-cased, matches the lib's GATE_CODE (a test holds this copy to it; `--approved` accepts no other heading)"

**Location:** `skills/dev-cycle/SKILL.md:487-491`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the heading `approval()` requires, the GATE_CODE copy, and gate detection from a changed path. It does not cover a gate path printed as `?`, which the N rules' pathform deny refuses under `--approved` anyway.
**Legibility-target:** orchestrator

`[[ ! "${lps[$i]}" =~ $GATE_CODE ]] || gc=1` (`scripts/build-loop.sh:1413`) sets VERDICT[gate], and `approval()` requires `[[ "$ANSWER_HEADING" == "$1 · $s" ]]` with `s="merge-gate-"` when gate is set (`scripts/build-loop.sh:1443-1457`). The lib reads `GATE_CODE='^scripts/(build-loop|dev-cycle|questions)\.sh$|^scripts/lib/|^skills/dev-cycle/'` (`scripts/lib/dev-cycle-read.sh:1969`), the same text as `skills/dev-cycle/SKILL.md:491`. PE: a `merge-` heading for a branch touching `scripts/lib/x.sh` refuses with "its heading must read "Q-001 · merge-gate-2026-10-01-a-5ea0bb3e5919" (the merge changes the gate's own code)". The `merge-gate-` entry then merges. BT passes.

**Evidence:** `scripts/build-loop.sh:1413`, `:1442-1458`, `scripts/lib/dev-cycle-read.sh:1969`, `S/probeE.out`, `S/bats-gate-code.out`

---

## Claim 6: "A `--marker` skip (row 701) whose WHY says the tip is no such marker, or that a read failed, is recorded and read again next iteration; any other WHY (the body breaks the marker rules or is too large) is filed as `stopped`"

**Location:** `skills/dev-cycle/SKILL.md:498-501`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the WHYs that `marker()` prints. It does not cover the routing choice itself (override row 790, Won't-Fix).
**Legibility-target:** orchestrator

`marker()` first passes on any `--status` skip: `[[ "${STATUS[line]}" == "ok "* ]] || { echo "${STATUS[line]}"; return; }` (`scripts/build-loop.sh:951`; enclosing marker() continues to :996 — read). Those WHYs (the brief not read, a malformed `Branch:` or `Dispatched:` line, a shared branch, "the tip of B starts "handoff:" but is not a marker") are neither of the two retried kinds nor a body or size rule. Read literally, they are filed `stopped`. They arise only if the brief or tip changed between step 7's `--status` and `--marker`. Precise version: name the body and size WHYs that are filed, and treat any other WHY (the `--status` skips) as recorded and retried.

**Evidence:** `scripts/build-loop.sh:886-928`, `:948-996`

---

## Claim 7: "A `refuse state` line from `--merge` or `--check` is a stop (the Rules), not a brief's verdict."

**Location:** `skills/dev-cycle/SKILL.md:503-504`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the line form and the exit code. It does not cover `--start` or `--prompt` (same `gate_start`).
**Legibility-target:** orchestrator

`state_start() { default_gate || exit 2 … { echo "refuse state gate: its merge repository could not be set up"; exit 2; } … echo "refuse state objects: …"; exit 2; }` (`scripts/build-loop.sh:1317-1323`). `gate_start` calls it first (`:1324-1327`). Both modes call `gate_start` before any brief (`:2112`, `:2124`).

**Evidence:** `scripts/build-loop.sh:1317-1327`, `:2111-2134`

---

## Claim 8: "slug `blocked-STEM-N` or `stopped-STEM-N` (… the shape `--cycle-diff` requires, Q-141) … Add `Q-NNN@TIP` to the brief's `Asked:` line" and step 10's "`capped-STEM-N` … (its item `Q-NNN` alone when TIP is `-`)"

**Location:** `skills/dev-cycle/SKILL.md:504-513`, `:673-676`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `--cycle-diff` accepting these items when the entry is filed in the same change, and refusing a merge entry's ID on `Asked:`. It does not cover the N numbering.
**Legibility-target:** orchestrator

The rule: `elif ! [[ "${newh[$id]#* · }" =~ ^[abcdefghijklmnopqrstuvwxyz]+(-[abcdefghijklmnopqrstuvwxyz]+)*-"${f%.md}"-[0123456789]+$ ]]` (`scripts/build-loop.sh:1993`; enclosing cycle_rules continues to :1999 — read). PC accepted `Asked: Q-002@TIP` (blocked-…-b-1), `Asked: Q-003@TIP` (stopped-…-c-1) and `Asked: Q-004` (capped-…-d-1) ("ok"). It refused `Asked: Q-001@TIP` for the merge entry: "which names no question entry this change files".

**Evidence:** `scripts/build-loop.sh:1978-1999`, `S/probeC.out`

---

## Claim 9a: "then the reason, if any, on a `> ` line (one holding `<!--` is replaced by "(not shown: it holds `<!--`)" …)"

**Location:** `skills/dev-cycle/SKILL.md:508-509`
**Type:** Behavioral / Error-handling
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the replacement text the step prescribes, written as given. It does not establish what an orchestrator that paraphrases the text would write.
**Legibility-target:** orchestrator

The replacement text itself holds `<!--` with no `-->`. FENCE_AWK refuses such a line, and that refusal stops the whole file: `if (opencomment(l)) { refuse("comment"); return 1 }` (`scripts/lib/dev-cycle-read.sh:309`; enclosing fence() continues to :312 — read), where `opencomment` is "the last <!-- on the line has no --> after it" (`:277-280`). PB filed the stopped entry exactly as step 7 says:

```
=== cycle-diff (main moved by E's self-merge; BASE = MAIN0) (exit 2)
refuse docs/working/questions.md: --check-answer refuses its index copy whole (odd 30 comment)
```

Line 30 is `> (not shown: it holds `<!--`)`. `--land-cycle` refuses the merge copy the same way. Had the file reached main, `--check-answer` would skip every ID in it. PC used another replacement ("an HTML comment opener"), and the same flow passed `--cycle-diff` and landed. A loop controls REASON (`handoff: stopped: REASON`), so any loop can trigger this. Each time it does, step 9.3's remedy ("unstage or fix the iteration's own change") is needed, and its own text prescribes the bad line.

**Evidence:** `scripts/lib/dev-cycle-read.sh:272-312`, `scripts/build-loop.sh:2026-2028`, `S/probeB.out`, `S/probeC.out`

---

## Claim 9b: "… which questions.sh would read as its index marker"

**Location:** `skills/dev-cycle/SKILL.md:509-510`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the reason given for withholding `<!--`. It does not cover questions.sh's other parsing.
**Legibility-target:** reader

questions.sh matches only the full markers: `INDEX_START='<!-- index:start -->'` (`scripts/questions.sh:140`), used as a sed range at `:294`. A bare `<!--` is not read as a marker. What a bare `<!--` does break is `--check-answer`'s FENCE_AWK, which refuses the whole questions file (Claim 9a). The conclusion holds (the reason must not hold `<!--`), but the stated mechanism is imprecise. Precise version: "which `--check-answer` would refuse the whole questions file for".

**Evidence:** `scripts/questions.sh:140-141`, `:294`, `scripts/lib/dev-cycle-read.sh:277-280`

---

## Claim 9c: "then the reason, if any, on a `> ` line" (the quoted reason as inert data)

**Location:** `skills/dev-cycle/SKILL.md:508`
**Type:** Behavioral / Error-handling
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a REASON that FENCE_AWK's refdef rule reads through the `> ` prefix. It does not list every REASON shape that breaks the file.
**Legibility-target:** orchestrator

`refdef` strips leading `>` and list markers first: `if (match(l, /^([ \t>]|[-*+][ \t]|[0123456789]+[.)][ \t])*/)) l = substr(l, RLENGTH + 1)` (`scripts/lib/dev-cycle-read.sh:285`; enclosing refdef() continues to :291 — read). A REASON that starts with `[` and holds `]:` or never closes the `[` is allowed by the marker rule (1-120 printable ASCII). It then refuses the whole questions file. PD, REASON `[wip`:

```
=== cycle-diff with '> [wip' reason line (exit 2)
refuse docs/working/questions.md: --check-answer refuses its index copy whole (odd 25 refdef)
```

**Evidence:** `scripts/lib/dev-cycle-read.sh:282-291`, `scripts/build-loop.sh:872`, `S/probeD.out`

---

## Claim 10: "`[1]`, `[2]` and `[3]` read as `keep`, `drop` and `done`; any other answer, words included, as `unrecognized`."

**Location:** `skills/dev-cycle/SKILL.md:518-519`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `--check-answer`'s reading of an answered entry's first answer line. It does not cover entries that are open or skipped.
**Legibility-target:** reader (the orchestrator acts on the word `--check-answer` prints, so its actions do not change; only what it tells the user does)

`option()` also reads bare digits and the words keep, drop and done:

```awk
# scripts/lib/dev-cycle-read.sh:2071-2083
  s = tolower(span); sub(/^[ \t*]+/, "", s)
  if (substr(s, 1, 3) == "[1]") return "keep"
  ...
  if (!match(s, /^(1|2|3|keep|drop|done)/)) return "unrecognized"
  ...
  if (w == "1" || w == "keep") return "keep"
```

(excerpt elides :2074-2075 and :2077-2081, all read; option() ends :2084). PA printed `keep Q-004` for `1`, `keep Q-007` for `keep`, `drop Q-008` for `Drop.` and `done Q-009` for `done`. It printed `unrecognized` for `merge`, `keep it`, `changes needed` and `re-dispatch`. So a merge entry answered "done" re-dispatches the loop, and one answered "keep." merges. Precise version: "`[1]`, `1` or `keep` read as keep (likewise 2/drop, 3/done) when followed by the end, punctuation or a dash; anything else is `unrecognized`" (as `approval()`'s own message says: "([1], 1 or keep approve)", `scripts/build-loop.sh:1454`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:2058-2061`, `:2070-2084`, `S/probeA.out`

---

## Claim 11: "First run `--main-log MAIN` again: if it lists an `other` line after MAIN, act on no answer this iteration … so every answer acted on came in a commit the user is shown"

**Location:** `skills/dev-cycle/SKILL.md:519-521`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers an answers-only commit read as `answers` and a non-answer commit read as `other`. It does not cover a forged answers commit (F19, by design).
**Legibility-target:** orchestrator

PD: `answers 3b1ef0c4… answer Q-090` (a Status flip plus an `**Answer:** [1]` line) and `other 9e5c202b… user: notes`, exit 2.

**Evidence:** `scripts/build-loop.sh:1784-1790`, `S/probeD.out`

---

## Claim 12: "A merge entry: `keep` runs `--merge BRIEF --expect TIP --approved Q-NNN`, TIP the full one the entry names"

**Location:** `skills/dev-cycle/SKILL.md:529-530`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers an approved merge of a review brief and of a self-merge brief with a floor path, from MAIN_WT. It does not cover `--expect` against a moved tip.
**Legibility-target:** orchestrator

PE: "merged docs/working/briefs/2026-10-01-a.md 5ea0bb3e… c58bb3ec… a77c7bfa…" under `--approved Q-002`.

**Evidence:** `scripts/build-loop.sh:393-426`, `S/probeE.out`

---

## Claim 13: "Add each ID acted on to the brief's `Applied:` line … so each answer is acted on once" (Applied: is not judged by `--cycle-diff`)

**Location:** `skills/dev-cycle/SKILL.md:534-535`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `--cycle-diff` and `--land-cycle` passing an added `Applied:` line. It does not cover how a merge entry ID gets tied to its brief (override row 789).
**Legibility-target:** orchestrator

`asked()` reads only `/^Asked:/` (`scripts/build-loop.sh:1908`). PC landed `Applied: Q-001` on brief A ("landed chore/dev-cycle-2026-10-14-0230 …").

**Evidence:** `scripts/build-loop.sh:1908`, `:1937-1947`, `S/probeC.out`

---

## Claim 14: "while the queue is shorter than `--settings`' `slots` line"

**Location:** `skills/dev-cycle/SKILL.md:540`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the line's existence and form. It does not cover how the queue is counted.
**Legibility-target:** orchestrator

PB: `slots 3 set: line 5 of docs/dev-cycle.md on the default branch`.

**Evidence:** `scripts/build-loop.sh:31-32`, `S/probeB.out`

---

## Claim 15: "a line `Branch: NAME` …, and the policy lines `--status` reads: `Policy: self-merge` only when `--settings` prints `policy self-merge set` …, then with it `Paths: PATH ...` … (single spaces; never one under `docs/reviews/`: the brief's own reviews land unlisted, row 623); else `Policy: review` and no `Paths:` line"

**Location:** `skills/dev-cycle/SKILL.md:551-556`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three line forms as `--status` and `--check` read them, and the own-review allowlist. It does not establish that a loop names its reviews so they count as its own: only an added, lower-case `docs/reviews/STEM.md` or `NAME-STEM.md` does, and the loop prompt does not say so.
**Legibility-target:** orchestrator

`[[ "$POLICY" == self-merge && "${BRIEF[policy]-}" == "Policy: self-merge" ]] && pol=self-merge` (`scripts/build-loop.sh:906`). `[[ "${BRIEF[branch]}" =~ ^Branch:\ ([^\ ]+)$ ]]` (`:899`). The own-file rule is `[[ "$3" == A && "$1" == docs/reviews/* && "$b" != */* && ( "$b" == "$2.md" || "$b" == *"-$2.md" ) ]]` (`scripts/lib/dev-cycle-read.sh:1951`; enclosing ownfile() starts :1946 — read). PB: brief E (`Policy: self-merge`, `Paths: docs/e.md`) reads `self-merge` and merges from GT. Brief A (`Policy: review`) reads `review`.

**Evidence:** `scripts/build-loop.sh:886-928`, `:1173-1217`, `scripts/lib/dev-cycle-read.sh:1946-1952`, `S/probeB.out`

---

## Claim 16: "Later iterations add `Asked:`, `Applied:` and `Dispatched:` lines at its end" / step 10 "Write `Dispatched: N` on the brief (the old line replaced …)"

**Location:** `skills/dev-cycle/SKILL.md:564-566`, `:668-669`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `--status` reading the first `Dispatched:` line, and `--cycle-diff` not judging the line. It does not cover the merge-conflict rationale for "never next to the Status: line".
**Legibility-target:** orchestrator

`[[ "${BRIEF[dispatched]}" =~ ^Dispatched:\ (0|[123456789][0123456789]?)$ ]] || { STATUS[line]="skip $a: its first Dispatched: line is not exactly …"` (`scripts/build-loop.sh:902-903`). PC: two `Dispatched:` lines pass `--cycle-diff` ("ok"), so only the replace rule keeps the count right. PF: after the second land, `--status` prints DISPATCHED `1`.

**Evidence:** `scripts/build-loop.sh:901-905`, `S/probeC.out`, `S/probeF.out`

---

## Claim 17: "Write the record `docs/working/cycles/cycle-YYYY-MM-DD.md`, dated as the digest dates (`date +%F`, local time; the branch name's DATE-HHMM is UTC)"

**Location:** `skills/dev-cycle/SKILL.md:571-574`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the digest's date source and the land and `--main-log` accepting a record whose date differs from the branch's DATE. It does not cover the digest's window around midnight.
**Legibility-target:** orchestrator

`TODAY="${DEV_CYCLE_TODAY:-$(date +%F)}"` (`scripts/dev-cycle.sh:139`). `chore_record` checks any `isrecord` path holding `Branch: B` (`scripts/build-loop.sh:1743-1751`). PC landed `cycle-2026-10-13.md` for branch `chore/dev-cycle-2026-10-14-0230`, and `--main-log` read it as `chore`.

**Evidence:** `scripts/dev-cycle.sh:139`, `scripts/build-loop.sh:1743-1751`, `scripts/lib/dev-cycle-read.sh:246`, `S/probeC.out`

---

## Claim 18: "`--main-log` and `--land-cycle` find the iteration's land by its `Branch:` line"

**Location:** `skills/dev-cycle/SKILL.md:605-606`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the exact column-0 line, a trailing CR dropped. It does not establish that a fenced `Branch:` line is ignored: chore_record reads fences too, so "unfenced" is the skill's own discipline.
**Legibility-target:** orchestrator

`gate_git cat-file blob "${RAW_NO[i]}" | LC_ALL=C awk -v w="Branch: $1" '{ sub(/\r$/, "") } $0 == w { f = 1 } END { exit !f }' && return 0` (`scripts/build-loop.sh:1748`; enclosing chore_record continues to :1751 — read). Both `log_class` (`:1783`) and `land_cycle` (`:2073`) call it. Executed in PC, PD and PF.

**Evidence:** `scripts/build-loop.sh:1743-1751`, `:1779-1783`, `:2073`, `S/probeF.out`

---

## Claim 19: "list under `### Paths landed` what the land carries: `hg -C WT diff --cached --no-renames --name-status BASE`, BASE being `hg -C WT merge-base HEAD refs/heads/main`"

**Location:** `skills/dev-cycle/SKILL.md:616-619`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the command's output for the second land. It does not cover the first land after a self-merge moved main.
**Legibility-target:** orchestrator

PF printed `M docs/working/briefs/2026-10-14-new.md` and `M docs/working/cycles/cycle-2026-10-13.md`, the second land's two paths.

**Evidence:** `S/probeF.out`

---

## Claim 20: "`--state` … Read M, the default branch's commit …, and T, `hg -C WT write-tree`" / "4. Commit what `--cycle-diff` read …, and check `hg -C WT rev-parse HEAD^{tree}` prints T"

**Location:** `skills/dev-cycle/SKILL.md:620-621`, `:641-642`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the first pass through steps 2-4. The second pass, after a merge-in, is Claim 23.
**Legibility-target:** orchestrator

PB/PC: `state … ok`, then `tree check ok`.

**Evidence:** `S/probeC.out`

---

## Claim 21: step 9.3's list of `--cycle-diff` refusals ("It refuses, among the rules its header lists …: a questions entry's heading, **Needs:** or answer lines changed or gone … and a questions file `--check-answer` refuses whole")

**Location:** `skills/dev-cycle/SKILL.md:625-637`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers each listed item existing in the code. The questions-moved, Asked: and whole-file refusals were executed; the rest were read in `cycle_rules` and `questions_rules`. "(`refuse index`)" fits only the failed listing: a non-regular side prints `refuse PATH: a side is not a regular file …` (`scripts/build-loop.sh:1941`, `:1954`). It does not establish that the list is complete ("among").
**Legibility-target:** orchestrator

Executed: "refuse docs/working/questions.md: the default branch changed the questions files since the fork point …" (PC, PD); "its first Asked: line adds …, which names no question entry this change files" (PC); "--check-answer refuses its index copy whole" (PB, PD). Read: `if [[ "$lp" =~ $GATE_CODE ]]; then echo "refuse $p: the gate's own code; …"` (`scripts/build-loop.sh:1925`), the truth-file and case rules (`:1926-1930`), the path rule (`:1936`), and the idea-log and roadmap rules (`:1956-1964`).

**Evidence:** `scripts/build-loop.sh:1880-1999`, `:2007-2042`, `S/probeB.out`, `S/probeC.out`, `S/probeD.out`

---

## Claim 22: "`refuse HEAD` or the questions-moved refusal means merge main in (below) and go back to 2"

**Location:** `skills/dev-cycle/SKILL.md:638-639` (with `:649-651`)
**Type:** Behavioral / Error-handling
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a `--cycle-diff` refusal at step 3, while the iteration's changes are staged and uncommitted (the only time step 3 runs). It does not cover `--land-cycle`'s `refuse HEAD` at step 5, after the commit, where the merge-in works (Claim 24).
**Legibility-target:** orchestrator

At step 3 the index and working tree hold the iteration's edits, and the commit comes only at step 4. `git merge` will not start then. PD, with one user answer committed on main after WT forked (an answers-class commit):

```
=== merge main in with the index staged (exit 2)
error: Your local changes to the following files would be overwritten by merge:
  docs/working/briefs/2026-10-01-c.md docs/working/cycles/cycle-2026-10-13.md docs/working/questions.md
...
=== merge --abort after that (exit 128)
fatal: There is no merge to abort (MERGE_HEAD missing).
=== unstage all (reset) then merge in (exit 2)
error: Your local changes to the following files would be overwritten by merge:
	docs/working/questions.md
Please commit your changes or stash them before you merge.
```

So the remedy cannot run. The fallback the text gives ("A conflict: `hg -C WT merge --abort`, then a stop") fails too, because there is no merge to abort. The iteration stops and loses its record and WT's edits. PD shows the order that works: commit first, merge main in, then `--cycle-diff` ("ok"). Most iterations change the questions files (step 1's `questions.sh archive`, step 7's entries). So an answer the user commits on main during such an iteration, which is the loop's normal input, stops it. The same applies to `--cycle-diff`'s other `refuse HEAD` (no merge base, or several: `scripts/build-loop.sh:1882-1884`).

**Evidence:** `scripts/build-loop.sh:1895-1901`, `skills/dev-cycle/SKILL.md:615-651`, `S/probeD.out`, `S/probeC.out`

---

## Claim 23: "`refuse HEAD` naming a moved default branch: merge main in, then 2 again" (then step 4: "Commit what `--cycle-diff` read")

**Location:** `skills/dev-cycle/SKILL.md:644-645` with `:641`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the step-5 loop: merge-in, steps 2-5 again. It does not cover a conflicting merge-in.
**Legibility-target:** orchestrator

The loop works, but step 4's commit has nothing to commit on the second pass, because the merge commit already holds the index. PD:

```
=== step 4 commit again (nothing staged) (exit 1)
nothing to commit, working tree clean
tree check ok
=== land-cycle (exit 0)
landed chore/dev-cycle-2026-10-14-0300 …
```

Precise version: "then 2 again, skipping step 4's commit when the index equals HEAD", so an orchestrator does not read the exit 1 as a failure.

**Evidence:** `S/probeD.out`

---

## Claim 24: "`--land-cycle --main M` … `landed B HEAD TREE NEW`: check `hg -C WT merge-base --is-ancestor HEAD refs/heads/main` (D13). … While MAIN_WT has main checked out, the land fast-forwards it, and refuses while it has tracked edits or is mid-merge"

**Location:** `skills/dev-cycle/SKILL.md:643-647`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the success line, the ancestry check, the moved-main refusal, the merge-in path and MAIN_WT's fast-forward. The tracked-edit refusal was executed through `--merge` (same `land()`, Claim 4b), not through `--land-cycle`. It does not cover the other `land()` refusals (an untracked file at an added path and the rest).
**Legibility-target:** orchestrator

PD: "refuse HEAD: the default branch is at 9e5c…, not --main's 3b1e…; merge it into HEAD, run --cycle-diff again and land with --main 9e5c…". After the merge-in, "landed …", and `--main-log` reads `chore`. PF: `is-ancestor` exits 0 after both lands, and MAIN_WT's HEAD equals `refs/heads/main` (`f9e4397a…` twice) with no tracked change.

**Evidence:** `scripts/build-loop.sh:2046-2079`, `:1527-1571`, `S/probeD.out`, `S/probeF.out`

---

## Claim 25: "Only after step 9's land is verified, with no dispatch block from step 0.2 or from `--main-log MAIN` run again now"

**Location:** `skills/dev-cycle/SKILL.md:655-656`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `--main-log MAIN` after the iteration's own land reading `chore`, not `other`. It does not cover a gate merge between the lands (read `gate` in PC).
**Legibility-target:** orchestrator

PF: `main e174268a… 1` / `chore e174268a… Merge branch 'chore/dev-cycle-2026-10-14-0500'`, exit 0.

**Evidence:** `S/probeF.out`

---

## Claim 26: "absent: `--start BRIEF`; any other: `--prompt BRIEF --steal`, which takes the lock at once when the loop under it has ended (a marker after the lock's tip), else only once both lock and tip are over two hours old, refusing "under 2 hours old" until then."

**Location:** `skills/dev-cycle/SKILL.md:662-664`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers taking the lock at once after a new marker, and the under-2-hours refusal when the marker is the lock's own tip. It does not cover a lock reason --steal cannot parse, which refuses with another WHY (Claim 28's "any other refusal").
**Legibility-target:** orchestrator

PD: after the loop committed and ended with `handoff: blocked`, `--prompt C --steal` printed `ok …` / `dispatched 1`. PB and PC, re-dispatching at the lock's own marker: "its worktree … is locked, and its lock or tip is under 2 hours old" (`scripts/build-loop.sh:1612`). `ended()` requires "`[[ "${BASH_REMATCH[1]}" != "${STATUS[sha]}" ]] && git merge-base --is-ancestor …`" (`:1622`; enclosing ended() ends :1623).

**Evidence:** `scripts/build-loop.sh:1601-1623`, `:1645-1653`, `S/probeB.out`, `S/probeD.out`

---

## Claim 27: "`ok BRIEF BRANCH DIR` and `dispatched N`: start one background subagent … whose prompt is every line after `dispatched N`, as printed"

**Location:** `skills/dev-cycle/SKILL.md:665-666`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the output shape of `--start` and `--prompt`. It does not cover the subagent call.
**Legibility-target:** orchestrator

`printf 'ok %s %s %s\ndispatched %s\n' "$a" "$br" "$DIR" "$n"; loop_prompt …` (`scripts/build-loop.sh:1666-1667`). PB, PC, PD and PF all print this shape.

**Evidence:** `scripts/build-loop.sh:1666-1694`, `S/probeB.out`

---

## Claim 28: "plus, for a send-back, one last line: "Answered for you: Q-NNN, ..., read from the default branch's questions files.", the `Applied:` IDs of its items at TIP" (with step 7: "`done` re-dispatches it, naming the ID", for a merge entry, and "(the answer's note goes back to the loop)")

**Location:** `skills/dev-cycle/SKILL.md:667-668` with `:494-495`, `:531`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the IDs step 10 names to the loop. It does not cover what the loop does with them.
**Legibility-target:** orchestrator

"Its items" are `Asked:` items (step 7: "an item on its `Asked:` line ends `@TIP`", `skills/dev-cycle/SKILL.md:466`). A merge entry is never an `Asked:` item: it is "tracked on Applied:" only (Claim 8 shows `--cycle-diff` refuses one there). So a merge entry answered [3] "changes needed" re-dispatches the brief, but the definition at `:668` leaves its ID out of the loop's last line. The loop prompt says nothing about answers on its own (`scripts/build-loop.sh:1676-1692`). Then step 7's "the answer's note goes back to the loop" has no carrier. Precise version: "the `Applied:` IDs of its items at TIP and of its merge entry for TIP".

**Evidence:** `skills/dev-cycle/SKILL.md:466`, `:494-495`, `:531`, `:667-668`, `scripts/build-loop.sh:1673-1694`

---

## Claim 29: "A refusal ending "retry once it ends" or saying "under 2 hours old" is tried again next iteration."

**Location:** `skills/dev-cycle/SKILL.md:670-671`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two texts. It does not establish that they are the only retryable refusals: the header also names failed git commands that "may clear on a retry" (`scripts/build-loop.sh:496-497`), and these go to an `agent` entry.
**Legibility-target:** orchestrator

`flock -n 9 || { echo "refuse ${ARGS[0]}: another --start or --prompt is running in this repository; retry once it ends"; exit 2; }` (`scripts/build-loop.sh:2145`). "under 2 hours old" was executed (Claim 26).

**Evidence:** `scripts/build-loop.sh:2145`, `:1612`, `S/probeC.out`

---

## Claim 30: "A brief `--status` read with DISPATCHED 4 (the cap, D1) is never dispatched again"

**Location:** `skills/dev-cycle/SKILL.md:673`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the cap's value and the refusal. "DISPATCHED 4" is the reachable case: the script refuses at 4 or more (`-ge`), so a hand-written 5-99 also refuses.
**Legibility-target:** orchestrator

`DISPATCH_CAP=4; STEAL_AGE=7200` (`scripts/build-loop.sh:1595`). PE: "refuse docs/working/briefs/2026-10-01-h.md: it was dispatched 4 times, and the cap is 4".

**Evidence:** `scripts/build-loop.sh:1595`, `:1637`, `S/probeE.out`

---

## Claim 31: "Then land again as step 9 does (1 to 5): the briefs' `Dispatched:` lines and the record's `10.` line."

**Location:** `skills/dev-cycle/SKILL.md:678-679`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a second land with BASE at the first land's HEAD: `--cycle-diff` and `--land-cycle` pass, and `--main-log` reads both merges as `chore`. It does not cover a second land when step 10 changed nothing.
**Legibility-target:** orchestrator

PF: `cycle-diff 2` "ok", `land 2` "landed chore/dev-cycle-2026-10-14-0500 117ac857… de48f14a… f9e4397a…", then `--main-log`: two `chore` lines.

**Evidence:** `S/probeF.out`

---

## Claim 32: the new test, "SKILL.md's merge-entry slug rule quotes the lib's GATE_CODE, which --approved's heading reads, on one line of its own (row 674, U4b2)", which "also names the dispatch cap and the steal age"

**Location:** `test/scripts/build-loop-orchestrator.bats:374-384`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers GATE_CODE on exactly one indented, backticked SKILL.md line, and SKILL.md naming `DISPATCHED $cap (the cap` and `"under $h hours old"` from build-loop.sh's line. It does not pin step 7's or step 10's prose "two hours".
**Legibility-target:** maintainer

`[ "$(grep -cxF "  $q$g$q" "$REPO_ROOT/skills/dev-cycle/SKILL.md")" -eq 1 ]` (`test/scripts/build-loop-orchestrator.bats:378`), then the cap and age greps (`:380-383`). BT: `ok 1 SKILL.md's merge-entry slug rule quotes the lib's GATE_CODE …`.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:374-384`, `S/bats-gate-code.out`

---

## Claim 33: commit 9777c1ff's message ("step 7 collects … with one --status call (D4), files merge entries with the --approved heading rule (GATE_CODE quoted, pinned to the lib by a test), blocked/stopped entries with WORDS-STEM-N slugs and Asked: items … step 9 … lands through --state, --cycle-diff, a hook-free commit of that index, and --land-cycle, merging main in on a moved main")

**Location:** commit `9777c1ff` message
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the message's description of the mechanisms at HEAD (Claims 3, 5, 8, 20, 24, 31). "Merging main in on a moved main" holds for `--land-cycle`'s refusal. It does not cover the step-3 merge-in (Claim 22), which the message does not describe.
**Legibility-target:** reader

Each named mechanism is in the text and executes as described (paraphrased — no quote available because the claim summarises several steps, each verified in the claims cited in Scope).

**Evidence:** `S/probeC.out`, `S/probeF.out`, `S/bats-gate-code.out`

---

## Claim 34: commit adc8a176's message ("A1: … every non-marker tip now uses --steal. A2: … a self-merge now runs from a detached gate worktree at main's commit, made per call and removed … step 9.3's list of --cycle-diff refusals completed")

**Location:** commit `adc8a176` message
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers A1 and A2 at HEAD (Claims 4a, 26). At HEAD, 9.3 lists the whole-file refusal that iteration 2's Claim 7 found missing, and hedges with "among". It does not re-judge the message against adc8a176's own tree (iteration 2's report did).
**Legibility-target:** reader

At HEAD, "any other: `--prompt BRIEF --steal`" (`skills/dev-cycle/SKILL.md:662`) covers every non-absent brief. GT is made and removed per call (`:478-481`).

**Evidence:** `skills/dev-cycle/SKILL.md:477-482`, `:625-640`, `:662`, `S/probeB.out`

---

## Claim 35a: commit c39a9692's message, "B3-B7: a stopped reason quoted, <!-- withheld"

**Location:** commit `c39a9692` message
**Type:** Reference / Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the B3 fix as written at HEAD. It does not cover B4-B7.
**Legibility-target:** reader

The fix's replacement text holds `<!--` itself, so `<!--` is not withheld (Claim 9a, PB).

**Evidence:** `skills/dev-cycle/SKILL.md:508-510`, `S/probeB.out`

---

## Claim 35b: commit c39a9692's message, other items ("B1: any answer to a blocked entry but open or skip re-dispatches it", "--main-log MAIN again before acting on answers and before dispatch; --state before GT's worktree add and before merging main into WT; refuse state is a stop", "The GATE_CODE pin test also pins DISPATCH_CAP and STEAL_AGE")

**Location:** commit `c39a9692` message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the quoted items against the text at HEAD and the executed test. It does not judge whether B8-B16 are complete.
**Legibility-target:** reader

`skills/dev-cycle/SKILL.md:525-526` (B1), `:519`, `:655-656` (`--main-log MAIN` again), `:478`, `:649` (`--state` first), `:503` (refuse state). BT passes the cap and age pins (Claim 32).

**Evidence:** `skills/dev-cycle/SKILL.md:478`, `:503`, `:519-526`, `:649`, `:655-656`, `S/bats-gate-code.out`

---

## Claims Requiring Attention

### Incorrect
- **Claim 4b** (`skills/dev-cycle/SKILL.md:482-486`): `--merge` prints path lines after every `land()` refusal too (a dirty MAIN_WT, no identity, main moved, a rebase). Those get filed as merge entries, cost the user two judgments and then end as `stopped`. Step 9.5 calls the same MAIN_WT state a stop. Route by WHY, not by whether path lines follow.
- **Claim 9a** (`:508-509`): the prescribed replacement "(not shown: it holds `<!--`)" holds `<!--`, so FENCE_AWK refuses the whole questions file and `--cycle-diff` refuses the land (PB). Use text without `<!--`.
- **Claim 9c** (`:508`): a loop-controlled REASON that starts with `[` and holds `]:`, or never closes its `[`, breaks the file the same way (refdef, through `> `; PD). Guard the reason line against every FENCE_AWK rule, or don't quote it.
- **Claim 10** (`:518-519`): `1`/`2`/`3` and `keep`/`drop`/`done` (followed by the end, punctuation or a dash) also read as options. Restate it as `option()` does.
- **Claim 22** (`:638-639`): at step 3 the iteration's edits are staged, so `git merge` refuses ("would be overwritten") and `merge --abort` then fails. The remedy can never run, and a user answer committed mid-iteration stops the iteration. Commit first, then merge main in (or say how to set the edits aside).
- **Claim 35a** (c39a9692 message): "<!-- withheld" does not hold (see 9a).

### Stale
- (none)

### Mostly Accurate
- **Claim 6** (`:498-501`): `--status`-style skips that `--marker` passes on are filed `stopped` under the literal rule. Name them as retried.
- **Claim 9b** (`:509-510`): questions.sh matches only the full index markers. The harm from a bare `<!--` is `--check-answer`'s whole-file refusal.
- **Claim 23** (`:644-645`, `:641`): after the step-5 merge-in, step 4 has nothing to commit (exit 1). Say to skip the commit when the index equals HEAD.
- **Claim 28** (`:667-668`): a merge entry's [3] ID is not an `Asked:` item, so the send-back's last line, as defined, leaves it out, and the "note goes back to the loop" has no carrier.

### Unverifiable
- (none)

## Escalations

- **E1 (behavioural, red candidate; High, executed): Claim 22.** Step 9.3's remedy for the questions-moved refusal (and for `--cycle-diff`'s `refuse HEAD`) cannot run while the iteration's edits are uncommitted. The fallback `merge --abort` also fails ("There is no merge to abort"). Most iterations change the questions files (step 1's archive, step 7's entries). So any answer the user commits on main between step 0 and step 9 ends the iteration with no record and discards WT's edits (`--force` removal). In the loop's normal use, that happens on every answered question. Not found in iterations 1-2 (iteration 1's report marked this path "not executed").
- **E2 (behavioural, red candidate; High, executed): Claims 9a/9c.** Following step 7 literally makes the iteration's land refuse whenever a stopped loop's REASON holds `<!--` (the prescribed replacement), or starts with an open `[` or a `]:` reference shape. REASON is loop-written text, so one loop can keep re-triggering this. The next iteration files the same entry again (it never landed) and is refused again, unless the orchestrator deviates from the text. It fails closed (nothing bad lands, and `--land-cycle` re-judges the merge copy), but it stalls every land while the brief stays stopped. The marker rule (`scripts/build-loop.sh:872`) puts no limit on REASON's content.
- **E3 (behavioural, amber; High, executed): Claim 4b.** Self-merge refusals from `land()` are misrouted to user merge entries. Low risk (fails closed), but it spends attention (memory: attention is the binding budget) and contradicts step 9.5's handling of the same state.
- **E4 (amber, Medium, static): Claim 28.** A [3] "changes needed" answer on a merge entry re-dispatches the loop without naming the entry. Neither the loop prompt nor the last line tells the loop where the change request is.
- **E5 (doc-level, Low): Claims 10, 23, 6, 9b.** Wording fixes. None changes a script decision, though a user told "words are unrecognized" may answer "done" to a merge entry, which `option()` reads as [3] and re-dispatches.

## Goal-Alignment Note

Success criterion: "A code-fact-check report saved at the given path, every checkable claim in the diff verdicted with evidence." Met in substance: the report is saved at `docs/reviews/code-fact-check-report-2026-10-13-u4b2-final-r1.md` in the worktree, with the header `**Commit:** c39a9692`. Its 40 claims (35 numbered) cover steps 6-10, the changed Rules line, the Flow, the new bats test and the three branch commit messages. Each carries the seven mandatory fields plus Legibility-target. Every claim about what a script prints, refuses or accepts was executed in throwaway fixture repos under `/tmp/u4b2rv-fc-r1-*` (PA-PF, BT), with provenance in the probe table. Limits:
- Claims 6, 7, 9b and 28 are static.
- Claim 21's unexecuted refusal items rest on reading `cycle_rules`.
- The tracked-edit refusal of `--land-cycle` was executed through `--merge`'s shared `land()`, not `--land-cycle` itself.
- The step 1 and step 0.2 additions (health-check skip, bootstrap stop) are orchestrator policy with no script contract to check, and were not verdicted.
- The wait rule (D12) and D4's unbuilt PR route have no code to check against.
- The hallucination-pattern log was read but not edited: the brief allows writing only this report, and no Incorrect verdict is a fabrication.
- No probe process outlives this run. Each fixture's locked loop worktrees are left in place under its temp dir, as the brief requires.
