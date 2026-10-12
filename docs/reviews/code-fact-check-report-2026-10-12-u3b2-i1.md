Commit: 1d829fee

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u3b2 (branch `feat/build-loop-u3b2`)
**Scope:** branch diff `main...HEAD` (main b5f21758, HEAD 1d829fee): `scripts/build-loop.sh`, `docs/working/plan-build-loop-handoff.md` (U3b2 "As built"), `docs/reviews/override-log.md` (four new rows), `test/scripts/build-loop-orchestrator.bats`, and the commit message of 1d829fee
**Checked:** 2026-10-12
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 31
**Summary:** 24 verified, 7 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`, 5 entries, all about quoted measured values or file-to-symbol associations): no claim below matches a logged pattern. The one numeric claim (N, the commit count) was executed.

Execution provenance shared by the `executed` claims (all run 2026-10-12, timeouts applied, temp dirs under `/tmp/u3b2rv-fc-` removed afterwards):

- E1: `TMPDIR=/tmp/u3b2rv-fc-Gn4t timeout 600 bats test/scripts/build-loop-orchestrator.bats`, cwd `/workspace/.claude/wt-build-loop-u3b2`, 22:35:07Z, exit 0 (10/10 ok, tests 9-10 are --main-log). Output: `/tmp/claude-1000/-workspace/fbda3e17-2975-43f6-8d47-8f94722b03ec/scratchpad/orch.log`
- E2: `TMPDIR=/tmp/u3b2rv-fc-Gn4t timeout 600 bats test/scripts/build-loop-merge.bats`, same cwd, 22:35Z, exit 0 (12/12 ok). Output: `/tmp/claude-1000/-workspace/fbda3e17-2975-43f6-8d47-8f94722b03ec/scratchpad/merge.log`
- E3: `timeout 300 bash /tmp/claude-1000/-workspace/fbda3e17-2975-43f6-8d47-8f94722b03ec/scratchpad/fc-probe.sh`, cwd `/tmp` (the script makes and enters its own `/tmp/u3b2rv-fc-XXXX`, refuses git outside it), 22:35:54Z, exit 0. A throwaway repo exercising: SINCE equal to MAIN; a multi-line answer, a note under an answer, an archive move, a chmod +x of questions.md, an answer line in an executable questions.md, a CRLF answer line, a Status-only header change; a chore merge with an " into " subject and a CRLF record; a fast-forwarded chore branch; a chore merge whose record is mode 100755; a random full id; and `TMPDIR` pointing at a missing directory. Output: `/tmp/claude-1000/-workspace/fbda3e17-2975-43f6-8d47-8f94722b03ec/scratchpad/fc-probe.out`

---

## Claim 1: "Row 662 discharged: `gate_msg` is the one definition of the merge message land writes and --main-log reads as gate ... land and log_class both call gate_msg; the reader compares the commit's message byte for byte with gate_msg's output."

**Location:** `docs/reviews/override-log.md:718`
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two call sites of gate_msg and the byte comparison in log_class; does not establish that no other writer (outside scripts/) spells the message, beyond a grep of scripts/, scripts/lib/ and skills/*/SKILL.md.

land writes through it: `gate_msg "${VERDICT[branch]}" "$what" "${VERDICT[stem]}" "${2-}" > "$GATE_TMP/msg"` (`scripts/build-loop.sh:1448`). The reader regenerates and compares: `gate_msg "$b" "$x" "$p" "$q" > "$GATE_TMP/want" && cmp -s "$GATE_TMP/want" "$GATE_TMP/m" && CLASS=gate` (`scripts/build-loop.sh:1632`), where `$GATE_TMP/m` is the raw message from `perl -0777 -ne 's/\A.*?\n\n//s and print'` (`scripts/build-loop.sh:1624`). A grep for `Build-loop-gate`, `build-loop %s` and `gate_msg` over scripts/, scripts/lib/ and skills/*/SKILL.md finds no other printf of the message (paraphrased — no quote available because the claim covers absence of code (no other matching grep results); the only other hit is the help text at `scripts/build-loop.sh:302`). E1 test 9 classifies a real `--merge` commit as gate.

**Evidence:** `scripts/build-loop.sh:1358-1364`, `scripts/build-loop.sh:1448`, `scripts/build-loop.sh:1624-1632`, scratchpad/orch.log

---

## Claim 2: "--main-log's chore class needs U4's land to match it: a `git merge --no-ff` of `chore/dev-cycle-DATE[-HHMM]` (a fast-forward lands the chore commits as other), a subject starting "Merge branch 'B'", and the cycle record ... holding the line "Branch: B" ... The rule is read from the merge itself, so it survives the branch's deletion ... and needs no caller input."

**Location:** `docs/reviews/override-log.md:719`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the --no-ff requirement, the fast-forward consequence, the record-line requirement and the absence of caller input; does not establish anything about U4's land (not yet written).

The coupling is right and the fast-forward consequence holds: in E3 a fast-forwarded chore branch's record commit printed `other f3c670c7... record2`. Two requirements U4 must meet are missing from the row. First, the subject must be followed by the end, " into " or ":" (`'\'($|\ into\ |:)` at `scripts/build-loop.sh:1633`), so a custom `-m "Merge branch 'B' (cycle)"` reads as other. Second, the record must be written as mode 100644 (`"$meta" =~ ^:[01234567]{6}\ 100644\ ...\ [AM]$`, `scripts/build-loop.sh:1637`). In E3 a chore merge whose record was 100755 printed `other 6984ad5c... Merge branch 'chore/dev-cycle-2026-10-14'`. The help text at `scripts/build-loop.sh:150-151` does state the suffix rule. Precise version: "a subject starting "Merge branch 'B'" followed by the end, " into " or ":", and a non-executable regular record file". Branch-deletion independence holds: the class reads only the merge commit, its first-parent diff and the record blob (`scripts/build-loop.sh:1635-1639`), and takes no argument but SINCE.

**Evidence:** `scripts/build-loop.sh:1633-1640`, `scripts/build-loop.sh:150-155`, scratchpad/fc-probe.out ("chore probes")

---

## Claim 3: "--main-log's answers class is strict: a multi-line answer, a note under the answer, or the user's archive move reads as other ... Fails closed: other stops dispatch, never lets a change through."

**Location:** `docs/reviews/override-log.md:720`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three named cases and the exit-2 consequence; does not establish what U4's orchestrator does on exit 2 (not yet written).

E3 printed `other 1b22fa3f... multiline`, `other c1331b11... note` and `other fd6fc855... archive`, with exit 2. The mechanism: any non-blank changed line that is neither an answer label nor a `**Needs:**` header sets `bad = 1` (`scripts/build-loop.sh:1611`). The dispatch maps any other to exit 2: `main_log "${ARGS[0]}" || exit 2` (`scripts/build-loop.sh:1681`).

**Evidence:** `scripts/build-loop.sh:1604-1613`, `scripts/build-loop.sh:1665-1667`, `scripts/build-loop.sh:1681`, scratchpad/fc-probe.out ("answers probes")

---

## Claim 4: "--main-log reads history commits without store_check (only main's tip tree is re-hashed), and classes are read from each commit's own text: a loop that writes the gate message or a record line by hand passes as gate or chore"

**Location:** `docs/reviews/override-log.md:721`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which objects store_check re-hashes in this mode and the hand-written-message pass; does not establish whether rev-list's first-parent walk can be misled (core.commitGraph is off via harden, but no store_check covers history).

"Only main's tip tree" is narrower than the code. `state_start` runs `store_check --main "$MAIN_SHA"` (`scripts/build-loop.sh:1214`). That call re-hashes the tip **commit** as well as its tree and every tree and blob below it. Per store_check's own comment: "Each REV (a commit or a tree), its root tree, and every tree and blob below it ... are read in one cat-file --batch and re-hashed" (`scripts/build-loop.sh:948-950`). Precise version: "only main's tip commit and its tree are re-hashed". No history commit is checked: log_class calls no store_check (`scripts/build-loop.sh:1618-1654`, read whole). The forged-message half holds. In E1 test 10 a commit-tree commit carrying the hand-written gate message is printed as `gate` (`test/scripts/build-loop-orchestrator.bats:194-200`).

**Evidence:** `scripts/build-loop.sh:948-962`, `scripts/build-loop.sh:1210-1216`, `scripts/build-loop.sh:1618-1654`, `test/scripts/build-loop-orchestrator.bats:192-200`, scratchpad/orch.log

---

## Claim 5: "gated (the GATED default), after state_start (default_gate, the gate repository, main's objects re-hashed); every commit and diff is read in the gate repository, so no repo config or checkout attribute changes a diff."

**Location:** `docs/working/plan-build-loop-handoff.md:325`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the gating and that every git call in log_class and main_log goes through gate_git; does not establish isolation from objects/info files in the real object store (gate_git points GIT_OBJECT_DIRECTORY at it), which the claim does not address.

`GATED=""; [[ "$MODE" =~ ^(settings|status|marker)$ ]] || GATED=1` (`scripts/build-loop.sh:619`). Then `if [[ -n "$GATED" ]]; then state_gate || exit 2; fi` (`:622`), and the mode runs `state_start` before `main_log` (`:1680-1681`). state_start runs `default_gate || exit 2`, `gate_repo`, then `store_check --main "$MAIN_SHA"` (`:1211-1215`). gate_git runs `(cd "$GATE_TMP/work" && "${GATE_ENV[@]}" git "$@")` (`:934`). GATE_ENV sets `GIT_DIR="$GATE_TMP/git"`, whose config holds only the format lines (`:925-927`). Every git call in log_class and main_log is `gate_git ...` (`:1621, 1635, 1639, 1642, 1650, 1659`).

**Evidence:** `scripts/build-loop.sh:619-622`, `scripts/build-loop.sh:918-937`, `scripts/build-loop.sh:1210-1216`, `scripts/build-loop.sh:1618-1668`, `scripts/build-loop.sh:1680-1681`

---

## Claim 6: "SINCE is a full id on main's first-parent history, else `refuse main-log: WHY`."

**Location:** `docs/working/plan-build-loop-handoff.md:325`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both failure routes for SINCE; does not establish anything beyond them.

A full id off the history is refused: E3's random id printed `refuse main-log: 0123... is not on the default branch's first-parent history at ...` with exit 2. A non-full id is not a refuse line, though. It is a usage error, exit 1, on stderr: `|| usage "--main-log takes one full 40- or 64-hex commit id"` (`scripts/build-loop.sh:443`). E1 test 10 asserts `[ "$status" -eq 1 ]` for a 12-hex id. Precise version: "SINCE must be a full id (else usage, exit 1); one not on main's first-parent history reads `refuse main-log: WHY` (exit 2)". The help text gets this right.

**Evidence:** `scripts/build-loop.sh:441-443`, `scripts/build-loop.sh:1659-1662`, `test/scripts/build-loop-orchestrator.bats:297-299`, scratchpad/fc-probe.out ("random id")

---

## Claim 7: "Output `main MAIN N`, then `gate|chore|answers|other SHA SUBJECT` per first-parent commit after SINCE, oldest first; exit 2 on any other or a refusal. gate: two parents and gate_msg's message byte for byte ... chore: ... two parents, a subject starting "Merge branch 'chore/dev-cycle-DATE[-HHMM]'" (then the end, " into " or ":"), and a changed docs/working/cycles/cycle-*.md holding "Branch: B" ... Anything unread is other."

**Location:** `docs/working/plan-build-loop-handoff.md:325`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the output shape, the order, the exit, and the gate and chore rules as stated; does not establish the record's file mode (100644 required; see Claim 11), which this sentence does not state.

`echo "main $MAIN_SHA $(wc -l < "$GATE_TMP/after")"` (`scripts/build-loop.sh:1663`), then `log_class "$c"; echo "$CLASS $c $SUBJ"` over `tac "$GATE_TMP/after"` (`:1665-1666`). E1 test 9 asserts the exact five-line output in oldest-first order. E3 verified an " into " subject with a CRLF record (`chore 801a58e6... Merge branch 'chore/dev-cycle-2026-10-12' into main`).

**Evidence:** `scripts/build-loop.sh:1626-1640`, `scripts/build-loop.sh:1657-1668`, `test/scripts/build-loop-orchestrator.bats:257-276`, scratchpad/orch.log, scratchpad/fc-probe.out

---

## Claim 8: "answers: one parent, only the questions files modified (regular files), changed lines blank, answer lines (--check-answer's labels) or header lines whose Status field alone changed, matched per hunk; at least one non-blank line."

**Location:** `docs/working/plan-build-loop-handoff.md:325`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the full answers rule; the one imprecision is the file-mode qualifier.

All of the rule matches the code (see Claims 12-15), except "(regular files)". The code accepts only mode 100644 on both sides: `"$meta" =~ ^:100644\ 100644\ ...\ M$` (`scripts/build-loop.sh:1645`). In E3 an answer line added to a 100755 questions.md printed `other aece0021... execanswer`. Precise version: "(non-executable regular files, mode 100644 before and after)".

**Evidence:** `scripts/build-loop.sh:1641-1651`, scratchpad/fc-probe.out ("answers probes")

---

## Claim 9: "--main-log ... after --state's gate but its caller check."

**Location:** `scripts/build-loop.sh:138-141`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers which startup checks the mode runs; does not establish the orchestrator's call order (U4).

The caller check runs only for `--state`: `if [[ "$MODE" == state ]]; then caller_gate || exit 2; fi` (`scripts/build-loop.sh:621`). The state gate runs for every gated mode (`:622`), and main-log runs `state_start` (`:1680`), the same half `--state` runs (`:1675-1677`).

**Evidence:** `scripts/build-loop.sh:619-622`, `scripts/build-loop.sh:1675-1682`

---

## Claim 10: "SINCE: a full 40- or 64-hex id ... Prints main MAIN N — MAIN: the default branch's commit; N: the first-parent commits after SINCE up to MAIN, one line each after this, oldest first"

**Location:** `scripts/build-loop.sh:141-146`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the argument form, N's value and the order, including SINCE equal to MAIN (N = 0); does not establish behavior when MAIN itself changes during the run.

The awk at `scripts/build-loop.sh:1661` reads `'$0 == s { f = 1; exit } { print } END { exit !f }'` over newest-first rev-list output, so it prints exactly the commits above SINCE. `wc -l` counts them (`:1663`), and `tac` reverses them (`:1666`). E3 printed `main e7247... 0` for SINCE equal to MAIN, and N=7 matched the seven class lines. E1 test 9 asserts `main $T 5` with five lines.

**Evidence:** `scripts/build-loop.sh:441-443`, `scripts/build-loop.sh:1657-1668`, scratchpad/fc-probe.out, scratchpad/orch.log

---

## Claim 11a: "gate: two parents and the message --merge writes, byte for byte. chore: two parents, a subject starting "Merge branch 'B'" (then the end, " into " or ":"), B being chore/dev-cycle-DATE or chore/dev-cycle-DATE-HHMM (DATE YYYY-MM-DD), and a cycle record the merge adds or changes ... holding the line "Branch: B" (a trailing CR dropped)."

**Location:** `scripts/build-loop.sh:148-155`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the gate and chore rules except the file-mode qualifier (Claim 11b); "DATE YYYY-MM-DD" is a digit shape, not a calendar check, and no reader would take it as more.

Gate: `${#ps[@]} -eq 2` plus the regenerated-message `cmp -s` (`scripts/build-loop.sh:1626-1632`). E1 test 10 shows the near misses read other: a line more, one parent, and approved without its trailer. Chore: `'\'($|\ into\ |:)` (`:1633`). The diff runs against the first parent: `diff-tree ... "${ps[0]}" "$c"` with status `[AM]` (`:1635-1637`). The record check is `awk -v w="Branch: $b" '{ sub(/\r$/, "") } $0 == w ...'` (`:1639`). E3 verified the " into " subject and the CRLF record. E1 tests 9-10 cover ":", a record naming another branch, and an out-of-pattern branch.

**Evidence:** `scripts/build-loop.sh:1626-1640`, `test/scripts/build-loop-orchestrator.bats:278-296`, scratchpad/orch.log, scratchpad/fc-probe.out

## Claim 11b: "(a regular file docs/working/cycles/cycle-*.md)"

**Location:** `scripts/build-loop.sh:153-154`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the record's accepted modes and path shape.

The code accepts a new mode of 100644 only: `"$meta" =~ ^:[01234567]{6}\ 100644\ ...` (`scripts/build-loop.sh:1637`). An executable regular file (100755) is rejected. In E3 such a record made the merge print `other 6984ad5c...`. The path regex `^docs/working/cycles/cycle-[^/]+\.md$` also excludes the empty-star name `cycle-.md`, which the glob would match (trivial). Precise version: "a non-executable regular file (mode 100644)".

**Evidence:** `scripts/build-loop.sh:1637`, scratchpad/fc-probe.out ("chore probes")

---

## Claim 12: "answers: one parent, and only docs/working/questions.md or questions-archive.md change, regular files kept regular"

**Location:** `scripts/build-loop.sh:155-157`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the parent count, the path set and the mode rule; does not establish anything about the line rules (Claims 13-14).

One parent (`elif [[ ${#ps[@]} -eq 1 ]]`, `:1641`) and the path set (`:1645`) are as stated, and an empty commit reads other (`x -gt 0`, `:1649`). "Regular files kept regular" is broader than the code, which requires exactly 100644 to 100644 with status M (`:1645`). A 100755 questions file, kept 100755, is still other. In E3 both `chmod` and `execanswer` printed other. Precise version: "non-executable regular files (100644) both before and after, modified (not added or deleted)".

**Evidence:** `scripts/build-loop.sh:1641-1649`, scratchpad/fc-probe.out ("answers probes")

---

## Claim 13: "answer lines (after an optional "- ", "Q-" and digits and ":", or a bold "**Answer:", "**Answer (" or "**Answered" in any case: --check-answer's labels)"

**Location:** `scripts/build-loop.sh:157-160`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the label match and its correspondence with ANSWER_AWK; does not establish that the answer's value parses (--check-answer's `option()` is not applied here, and the claim does not say it is).

ANSWERS_AWK: `t = l; sub(/^- /, "", t)` then `if (t ~ /^Q-[0123456789]+:/ || tolower(t) ~ /^\*\*answer(:|ed| \()/) next` (`scripts/build-loop.sh:1608-1609`). --check-answer's ANSWER_AWK: `line = $0; sub(/^- /, "", line)`, then `if (index(line, id ":") == 1)`, then `low = tolower(line)`, `if (low !~ /^\*\*answer(:|ed| \()/) next` (`scripts/lib/dev-cycle-read.sh:2053-2056`). The labels match. The Q- form accepts any digits rather than one entry's id, which the header states as "Q- and digits". "In any case" applies to the bold labels only, as worded.

**Evidence:** `scripts/build-loop.sh:1604-1612`, `scripts/lib/dev-cycle-read.sh:2046-2056`

---

## Claim 14: "header lines ("**Needs:**") whose Status field alone changed (in each hunk the removed and the added header lines, Status values set aside, match in order); at least one such line not blank."

**Location:** `scripts/build-loop.sh:160-163`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the per-hunk, in-order comparison and the non-blank requirement; does not establish anything about header lines of other forms (a "- **Needs:**" line is not a header here, as `l` rather than `t` is tested).

`needs()` replaces a field whose trimmed text starts with `"**Status:** "` with `"**Status:**"` (`scripts/build-loop.sh:1595-1598`). `flush()` sets bad unless `nr == na` and each `r[i] == a[i]` (`:1600`). It runs at each `diff --git`, each `@@` and END (`:1601-1602, 1613`). `n` counts the non-blank changed lines, and END requires `n > 0 && !bad` (`:1608, 1613`). E3: a Status-only change printed `answers e8c9a821... statusonly`. E1 test 10: a route change on the same header line, and a blank-only commit, both read other.

**Evidence:** `scripts/build-loop.sh:1594-1613`, `test/scripts/build-loop-orchestrator.bats:290-296`, scratchpad/fc-probe.out, scratchpad/orch.log

---

## Claim 15: "Any other commit, or one whose message, parents or changes cannot be read, is other."

**Location:** `scripts/build-loop.sh:163-165`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each read in log_class (cat-file, perl, diff-tree, blob read, NUL count); does not establish detection of a failure inside the `mapfile ... < <(awk ...)` parent read (a process-substitution status is not observed), though that awk reads a file cat-file has just written.

`CLASS=other` is the default (`scripts/build-loop.sh:1620`). Each read returns early on failure: `gate_git cat-file commit ... || return 0` (`:1621`), the perl at `:1624` `|| return 0`, both `diff-tree` calls (`:1635, 1642, 1650`) `|| return 0`, and the record pipe under pipefail (`:1639`). gate_git returns 3 when git wrote to stderr (`:932-937`). Root and octopus commits match no branch and stay other (paraphrased — no quote available because the claim covers absence of code: no branch of the if/elif chain at `:1626-1652` takes 0 or 3+ parents).

**Evidence:** `scripts/build-loop.sh:932-937`, `scripts/build-loop.sh:1618-1654`

---

## Claim 16: "The class is read from the commit's own text (and its objects are not re-hashed): it catches an honest slip, not a commit made to look like one of the others (F19)."

**Location:** `scripts/build-loop.sh:165-167`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers which classified commits' objects are re-hashed; the threat-model clause is design rationale and is not verdicted.

This holds for every classified commit but the newest. That commit is MAIN itself, and state_start's `store_check --main "$MAIN_SHA"` (`scripts/build-loop.sh:1214`) has re-hashed its commit object and its tree (store_check: "Each REV (a commit or a tree), its root tree, and every tree and blob below it", `:948-949`). Its first parent's tree, which the diff also reads, is not re-hashed. Precise version: "its objects are not re-hashed (but main's own commit and tree, which --state's half checks)". This does not change any class.

**Evidence:** `scripts/build-loop.sh:948-962`, `scripts/build-loop.sh:1210-1216`

---

## Claim 17: "or refuse main-log: WHY, when SINCE is not on that history (main was rewritten, or SINCE is on another branch) or it cannot be listed."

**Location:** `scripts/build-loop.sh:168-170`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both refuse lines; does not establish the rev-list failure path by execution (static only for that half).

`gate_git rev-list --first-parent "$MAIN_SHA" > "$GATE_TMP/fp" || { echo "refuse main-log: the default branch's first-parent history could not be listed"; return 1; }` (`scripts/build-loop.sh:1659`). The not-found refusal is at `:1661-1662`. E3 and E1 test 10 show the refusal, with exit 2, for a random id and for a second-parent tip.

**Evidence:** `scripts/build-loop.sh:1657-1662`, scratchpad/fc-probe.out, scratchpad/orch.log

---

## Claim 18: "Exit: 0 ... for --main-log no other line ... 2 ... --main-log's other or refuse line"

**Location:** `scripts/build-loop.sh:410-412`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers main_log's own exits; the state-gate exit 2 and the usage exit 1 are covered by the existing clauses of the same section.

`main_log "${ARGS[0]}" || exit 2` (`scripts/build-loop.sh:1681`), and main_log returns `"$o"`, set by `[[ "$CLASS" != other ]] || o=1` (`:1665-1667`). E1 and E3: exit 0 with no other line, exit 2 with any other line or a refuse line.

**Evidence:** `scripts/build-loop.sh:1663-1667`, `scripts/build-loop.sh:1680-1682`, scratchpad/fc-probe.out, scratchpad/orch.log

---

## Claim 19: "1 ... a failed mktemp (--state, --main-log, --check, --merge, --start, --prompt; no line printed)"

**Location:** `scripts/build-loop.sh:416-418`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers --main-log's entry in the list; the other modes' entries predate this branch and were not re-run.

`GATE_TMP="$(mktemp -d)"` in state_start (`scripts/build-loop.sh:1212`) runs at the top level under `set -euo pipefail` (`:421`). E3 ran with `TMPDIR` pointing at a missing directory: exit 1, 0 bytes on stdout, and only mktemp's own stderr.

**Evidence:** `scripts/build-loop.sh:421`, `scripts/build-loop.sh:1210-1212`, scratchpad/fc-probe.out ("mktemp")

---

## Claim 20: "gate_msg BRANCH WHAT STEM [Q-NNN]: the message of the merge --merge writes (land) and --main-log reads as gate, its one definition (row 662). WHAT is self-merge, or "approved merge" with its Q-NNN."

**Location:** `scripts/build-loop.sh:1358-1360`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers gate_msg's callers and the WHAT values land passes; see Claim 1 for the sole-definition grep.

land sets `what="$1"` and `[[ "$1" != approved ]] || what="approved merge"` (`scripts/build-loop.sh:1381-1382`), where `$1` is AUTH, either `self-merge` or `approved` (`:1703`). log_class captures `(self-merge|approved merge)` (`:1626`).

**Evidence:** `scripts/build-loop.sh:1358-1364`, `scripts/build-loop.sh:1380-1382`, `scripts/build-loop.sh:1448`, `scripts/build-loop.sh:1626-1632`, `scripts/build-loop.sh:1703-1711`

---

## Claim 21: land's message is byte-identical to before the refactor (brief claim 6: gate_msg vs the old printf, through the caller `land "$AUTH" "$APPROVED"`)

**Location:** `scripts/build-loop.sh:1448`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both authorities through the only caller; does not establish byte-exactness by the merge suite alone (it compares `git log --format=%B`, which trims trailing whitespace), so the static comparison below carries the trailing bytes.

Old code: `[[ "$1" != approved ]] || printf 'Build-loop-approved: %s\n' "$2"` (diff line 135). New code: `[[ -z "${4-}" ]] || printf ...` (`scripts/build-loop.sh:1363`), with `"${2-}"` passed as the fourth argument. The two conditions agree because the only caller sets `AUTH=self-merge; [[ -z "$APPROVED" ]] || AUTH=approved` (`:1703`). APPROVED is non-empty whenever given, since it must match `^Q-[0123456789]+$` (`:453`). So `$1 == approved` exactly when `$2` is non-empty. The first printf's format and arguments are unchanged. E2 (12/12) asserts both messages (`test/scripts/build-loop-merge.bats:46-47, 205-207`).

**Evidence:** `scripts/build-loop.sh:453-455`, `scripts/build-loop.sh:1361-1364`, `scripts/build-loop.sh:1448`, `scripts/build-loop.sh:1703-1711`, `test/scripts/build-loop-merge.bats:40-48`, `test/scripts/build-loop-merge.bats:200-208`, scratchpad/merge.log

---

## Claim 22: "--main-log's answers rule over one commit's diff (diff-tree -p -U0 --text): every changed line in a hunk is blank, an answer line or a header line, the removed and added header lines of each hunk match in order once their Status values are set aside, and at least one changed line is not blank."

**Location:** `scripts/build-loop.sh:1589-1592`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the awk program's acceptance rule; does not establish handling of lines before the first hunk (skipped by `!hunk`; they are diff headers by construction under -U0) beyond static reading.

Matches the code: `diff-tree -p -U0 ... --text` (`scripts/build-loop.sh:1650`), and the program at `:1594-1613` (see Claims 13-14). Lines starting with neither "-" nor "+" set bad (`:1606`), and blank lines are skipped before `n++` (`:1607-1608`).

**Evidence:** `scripts/build-loop.sh:1594-1613`, `scripts/build-loop.sh:1650-1651`, scratchpad/fc-probe.out

---

## Claim 23: "log_class C: ... C, its changes and the record it adds are read in the gate repository (no repo config or checkout attributes); any failed read makes C other."

**Location:** `scripts/build-loop.sh:1614-1617`
**Type:** Architectural / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Same as Claims 5 and 15 (the parent-read process substitution is the one unobserved status).

Every git call in the function is `gate_git` (`scripts/build-loop.sh:1621, 1635, 1639, 1642, 1650`), and each read is guarded as listed in Claim 15. The function was read whole (`:1618-1654`).

**Evidence:** `scripts/build-loop.sh:1614-1654`

---

## Claim 24: "The message, byte for byte: everything after the header's blank line."

**Location:** `scripts/build-loop.sh:1623`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the perl extraction; does not establish behavior for a commit object with no blank line (perl prints nothing and SUBJ is empty, which reads other or answers by the diff).

`LC_ALL=C perl -0777 -ne 's/\A.*?\n\n//s and print' "$GATE_TMP/c"` (`scripts/build-loop.sh:1624`) slurps the raw object and deletes through the first `\n\n`, which is the end of the header (signature headers carry " " continuation lines, not empty ones).

**Evidence:** `scripts/build-loop.sh:1621-1625`

---

## Claim 25: "pipefail: a failed read is no record."

**Location:** `scripts/build-loop.sh:1638`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the blob-read pipeline; gate_git's stderr rule (exit 3) also feeds this pipeline's status.

`set -euo pipefail` (`scripts/build-loop.sh:421`), and `gate_git cat-file blob ... | LC_ALL=C awk ... && { CLASS=chore; return 0; }` (`:1639`). A failed gate_git makes the pipeline fail, so chore is not set.

**Evidence:** `scripts/build-loop.sh:421`, `scripts/build-loop.sh:1639`

---

## Claim 26: "Every record read whole, as check_line reads its diff."

**Location:** `scripts/build-loop.sh:1648`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the NUL-count check and its precedent; does not establish anything about bytes after the last NUL (check_line's comment notes git never ends that way).

`[[ "$x" -gt 0 && "$(tr -cd '\000' < "$GATE_TMP/d" | wc -c)" -eq $((2 * x)) ]] || return 0` (`scripts/build-loop.sh:1649`). check_line's version is `if [[ "$(tr -cd '\000' < "$GATE_TMP/diff" | wc -c)" -ne $((2 * ${#ps[@]})) ]]` (`:1277`).

**Evidence:** `scripts/build-loop.sh:1275-1277`, `scripts/build-loop.sh:1649`

---

## Claim 27: "main_log SINCE: --main-log's lines. Returns 1 when SINCE is refused or any commit is other."

**Location:** `scripts/build-loop.sh:1655-1656`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the function's return; set -e does not apply inside it (it is called under `||`), and no unguarded command in it can change the return.

`return 1` at `scripts/build-loop.sh:1659` and `:1662`, and `return "$o"` at `:1667`. The function was read whole (`:1657-1668`). Execution: E1 and E3.

**Evidence:** `scripts/build-loop.sh:1657-1668`, scratchpad/fc-probe.out

---

## Claim 28: "The commits above SINCE (rev-list lists newest first)."

**Location:** `scripts/build-loop.sh:1660`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers rev-list's default order with no sorting flag.

`gate_git rev-list --first-parent "$MAIN_SHA"` (`scripts/build-loop.sh:1659`) carries no `--reverse`. The oldest-first output after `tac` (E1 test 9) confirms the newest-first input.

**Evidence:** `scripts/build-loop.sh:1659-1666`, scratchpad/orch.log

---

## Claim 29: Commit message of 1d829fee: "Each first-parent commit after SINCE is gate (two parents, gate_msg's message byte for byte), chore (a chore/dev-cycle-* merge whose cycle record names its branch), answers (only answer and Status lines in the questions files) or other; exit 2 on any other. gate_msg is the one definition ... (row 662). Gated; reads run in the gate repository." Notes: "U4 must land the chore branch with --no-ff and write that line ... false positives cost an entry, never a pass."

**Location:** `scripts/build-loop.sh:1589-1683` (commit 1d829fee message)
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the summary as a summary; its answers clause omits blank lines and header lines whose only change is Status (it says "Status lines"), and its chore clause omits the subject-suffix and 100644 requirements. Neither omission changes the outcome a reader would expect.

Each clause maps to code verified above: gate (Claim 11a), chore (Claims 7, 11a), answers (Claims 13-14), exit 2 (Claim 18), gate_msg (Claim 1), gated reads (Claim 5). The commit touches the four files in the header scope (paraphrased — no quote available because the claim is about the commit's file list, read with `git log`/diff, not a snippet).

**Evidence:** `scripts/build-loop.sh:1358-1364`, `scripts/build-loop.sh:1614-1683`

---

## Claim 30: Test comment "ml SINCE STATUS WANT: --main-log SINCE printed exactly WANT with exit STATUS ... chore B RECORD-LINE: B with a cycle record holding RECORD-LINE, merged into main with --no-ff."

**Location:** `test/scripts/build-loop-orchestrator.bats:248-255`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the helpers' described behavior; does not establish test adequacy (test-strategy's domain).

`ml() { bl --main-log "$1"; [ "$status" -eq "$2" ] && [ "$output" = "$3" ] && [ -z "$stderr" ] ...` (`:250`), and `git merge -q --no-ff -m "Merge branch '$1': cycle" "$1"` (`:255`). E1 passes.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:248-255`, scratchpad/orch.log

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 2** (`docs/reviews/override-log.md:719`): the handoff to U4 says "a subject starting "Merge branch 'B'"" but the code also requires the end, " into " or ":" after it, and a mode-100644 record; a custom merge subject or an executable record reads as other. Add both to the row.
- **Claim 4** (`docs/reviews/override-log.md:721`): "only main's tip tree is re-hashed": store_check --main re-hashes the tip commit as well as its tree.
- **Claim 6** (`docs/working/plan-build-loop-handoff.md:325`): "else `refuse main-log: WHY`": a non-full id is a usage error (exit 1, stderr), not a refuse line; only a full id off the history is refused.
- **Claim 8** (`docs/working/plan-build-loop-handoff.md:325`) and **Claim 12** (`scripts/build-loop.sh:157`): "regular files (kept regular)": the code requires mode 100644 before and after; an executable questions file reads other.
- **Claim 11b** (`scripts/build-loop.sh:153-154`): "a regular file" record: only mode 100644 is accepted.
- **Claim 16** (`scripts/build-loop.sh:165-166`): "its objects are not re-hashed": true for history, but the newest classified commit is MAIN, whose commit and tree --state's half has re-hashed. Harmless.

### Unverifiable
(none)

---

## Goal-Alignment Note

Success criterion: "A code-fact-check report saved to docs/reviews/code-fact-check-report-2026-10-12-u3b2-i1.md in the worktree, per the code-fact-check skill." Met. This file is at that path. It carries the skill's header fields and the seven mandatory per-claim fields, and every claim has a Legibility-target tag (below). Each of the brief's six focus areas was checked against the code that exercises it, with execution where possible: the help text rules, the Exit and mktemp list, the ANSWERS_AWK/log_class/main_log comments, the plan "As built" note, the four override rows, the commit message, and land's byte identity. No Incorrect or Stale claim was found; the drift is qualifier-level (file modes, the subject suffix in U4's handoff row, usage vs refuse, the tip commit's re-hash). Per the brief's write-only-your-own-report rule, `docs/reviews/hallucination-patterns.md` was not edited; no fabrication was found that would qualify for it anyway.

Legibility-target tags (per claim): Claims 1, 2, 3, 4: `docs/reviews/override-log.md` (U4 implementer, future reviewer). Claims 5, 6, 7, 8: `docs/working/plan-build-loop-handoff.md` (U4 implementer). Claims 9-19: `scripts/build-loop.sh` help header (orchestrator author / --main-log caller). Claims 20-28: `scripts/build-loop.sh` code comments (maintainer of build-loop.sh). Claim 29: commit 1d829fee message (`git log` reader). Claim 30: `test/scripts/build-loop-orchestrator.bats` (test maintainer).
