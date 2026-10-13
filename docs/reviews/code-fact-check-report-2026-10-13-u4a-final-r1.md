Commit: c4e36d1d

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u4a (claude-workflows, branch feat/build-loop-u4a)
**Scope:** full diff main...HEAD (c4e36d1d): scripts/build-loop.sh, scripts/lib/dev-cycle-read.sh, test/scripts/build-loop-orchestrator.bats (last three tests), docs/working/plan-build-loop-handoff.md (U4a as-built note, script-interface bullets), commit messages 722c2e10, 70d24331, 4e14d1cc, 4df6ec58. Final confirming pass, replicate r1 of k=3.
**Checked:** 2026-10-13
**Total claims checked:** 31
**Summary:** 25 verified, 2 mostly accurate, 2 stale, 1 incorrect, 1 unverifiable

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) read first; no claim below matches a logged pattern.

Execution logs (all under `/tmp/claude-1000/-workspace/8681a912-a74a-4649-a416-551a1bfd4a4f/scratchpad/`):
- `u4a-fcf-r1-bats.log`: `LC_ALL=C TMPDIR=$(mktemp -d /tmp/u4a-fcf-r1-XXXX) timeout 900 bats test/scripts/build-loop-orchestrator.bats`, cwd the worktree, started 2026-10-13T20:57:02Z, exit 0, 27/27 ok (tests 25-27 are U4a's).
- `u4a-fcf-r1/probe1b.out` (script `u4a-fcf-r1/probe1b.sh`): both land paths with hooks planted in the repo's hooks dir; cwd a fresh `/tmp/u4a-fcf-r1-Nbjw`, 2026-10-13T20:58:44Z, exit 0. (`probe1.out` is a first run whose two hook lines came from the probe's own un-hardened `git checkout -b`, fixed in probe1b.)
- `u4a-fcf-r1/probe2.out` (script `u4a-fcf-r1/probe2.sh`): --cycle-diff edge cases P1-P5; cwd `/tmp/u4a-fcf-r1-UIo2`, 2026-10-13T20:59:16Z, exit 0.
- A one-off `git merge` message probe (cwd `/tmp/u4a-fcf-r1-*`, 2026-10-13 ~21:00Z, exit 0, git 2.39.5): `git merge --no-edit chore/dev-cycle-2026-10-12` on main wrote exactly `Merge branch 'chore/dev-cycle-2026-10-12'` (od -c output inline in the run; no file captured, so it is cited as supporting only).

---

## Claim 1: "--land-cycle --main SHA [--answered Q-NNN]..." (synopsis, usage text, argument parsing)

**Location:** `scripts/build-loop.sh:12`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the parser accepting `--main` once (full 40/64-hex) and any number of `--answered Q-NNN`, and requiring `--main`; does not establish the usage-exit path by execution (no test runs a bad --land-cycle argument).
**Legibility-target:** operator reading `--help` / usage error

```bash
# scripts/build-loop.sh:540-546
      if [[ "$1" == --main && "$MODE" == land-cycle && $# -ge 2 && -z "$LAND_MAIN" && "$2" =~ ^([0123456789abcdef]{40}|[0123456789abcdef]{64})$ ]]; then LAND_MAIN="$2"
      elif [[ "$1" == --answered && $# -ge 2 && "$2" =~ ^Q-[0123456789]+$ ]]; then ANSWERED+=("$2")
      ...
    [[ "$MODE" == cycle-diff || -n "$LAND_MAIN" ]] || usage "--land-cycle needs --main SHA, the default branch's commit --cycle-diff checked" ;;
```

**Evidence:** `scripts/build-loop.sh:12`, `scripts/build-loop.sh:527`, `scripts/build-loop.sh:537-546`

---

## Claim 2: "a cycle record the merge adds or changes (docs/working/cycles/cycle-YYYY-MM-DD.md, mode 100644) holding the line "Branch: B""

**Location:** `scripts/build-loop.sh:163`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers --main-log's chore class now reading only dated record names (isrecord) through chore_record; does not establish dev-cycle.sh's window reader uses isrecord (it keeps its own glob, settled override row 2026-10-13 i1 architecture 5).
**Legibility-target:** operator reading `--help` (--main-log section)

```bash
# scripts/build-loop.sh:1736-1744 (chore_record, whole function)
chore_record() {
  local i
  for i in "${!RAW_P[@]}"; do
    isrecord "${RAW_P[i]}" && [[ "${RAW_NM[i]}" == 100644 && "${RAW_S[i]}" =~ ^[AM]$ ]] || continue
    gate_git cat-file blob "${RAW_NO[i]}" | LC_ALL=C awk -v w="Branch: $1" '{ sub(/\r$/, "") } $0 == w { f = 1 } END { exit !f }' && return 0
  done
  return 1
}
```

`isrecord() { [[ "$1" =~ ^docs/working/cycles/cycle-$DIGIT{4}-$DIGIT{2}-$DIGIT{2}\.md$ ]]; }` (`scripts/lib/dev-cycle-read.sh:246`); log_class calls `! chore_record "$b" || CLASS=chore` (`scripts/build-loop.sh:1776`). Test 26 asserts `--main-log` prints `chore <sha> Merge branch '$B'` after a land (bats log, ok 26).

**Evidence:** `scripts/build-loop.sh:1736-1744`, `scripts/build-loop.sh:1771-1776`, `scripts/lib/dev-cycle-read.sh:246`, `u4a-fcf-r1-bats.log`

---

## Claim 3: "merge main into HEAD first. That refusal is printed alone."

**Location:** `scripts/build-loop.sh:205`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the questions guard returning before cycle_rules runs, so no other refusal line follows it; does not establish that earlier cycle_diff refusals (merge base, listing) can co-occur (they also return at once).
**Legibility-target:** operator reading `--help` (--cycle-diff section)

```bash
# scripts/build-loop.sh:1888-1895 (cycle_diff continues to :1896 — read)
  for p in "${RAW_P[@]}"; do
    [[ "$p" == docs/working/questions.md || "$p" == docs/working/questions-archive.md ]] || continue
    ...
    cmp -s "$t.lb" "$t.lm" || { echo "refuse docs/working/questions.md: the default branch changed ...; merge it into HEAD, then stage again"; return 1; }
    break
  done
  cycle_rules "$base" index
```

**Evidence:** `scripts/build-loop.sh:1873-1896`

---

## Claim 4: "A path of the gate's own code (GATE_CODE) refuses, and so does one the lib's truthrule reads as truth (an instruction or prompt file, a dot path, docs/dev-cycle.md, docs/constraints.md, docs/decisions/, docs/human-author/; --check-fix refuses them too), both compared lower-cased, and a cycle file spelled in another case."

**Location:** `scripts/build-loop.sh:216-221`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed class refusing on the lowered path, the cycle class exempt when spelled lower-case, and a case-spelled cycle file refusing; does not establish that docs an instruction file @-imports refuse (they do not; settled row 2026-10-13 i2 security F-e), nor the "--check-fix refuses them too" parenthesis beyond truthrule being shared.
**Legibility-target:** operator reading `--help`; U4b author naming the rules

```bash
# scripts/build-loop.sh:1918-1923 (excerpt ends :1923; enclosing cycle_rules continues to :1980 — read)
    if [[ "$lp" =~ $GATE_CODE ]]; then echo "refuse $p: the gate's own code; an in-cycle fix never edits it"; bad=1; continue; fi
    if truthrule "$lp" && [[ "$TRUTH_WHY" != cycle ]]; then
      w="the dev cycle's settings file"; [[ "$TRUTH_WHY" == settings ]] || w="$(floor_why "$TRUTH_WHY")"
      echo "refuse $p: $w; an in-cycle fix never edits it (--check-fix refuses it too)"; bad=1; continue
    fi
    if [[ "$TRUTH_WHY" == cycle && "$p" != "$lp" ]]; then echo "refuse $p: one of the dev cycle's own files, spelled in another case, which these rules do not read"; bad=1; continue; fi
```

Executed: test 25 (AGENTS.md, SKILLS/dev-cycle/x.md, scripts/lib/a.sh, docs/dev-cycle.md, docs/working/Questions.md) passes; probe P3 refused `.GitHub/w.yml` (dot), `Agents.md` (instr), `Docs/Decisions/x.md` (record) and `docs/working/Briefs/2026-10-02-y.md` (case-spelled cycle file); probe P2 passed a record, docs/thoughts/a.md, README.md, a move to closed/, a new roadmap and idea log (`ok`).

**Evidence:** `scripts/build-loop.sh:1907-1923`, `scripts/lib/dev-cycle-read.sh:1914-1925`, `u4a-fcf-r1-bats.log`, `u4a-fcf-r1/probe2.out`

---

## Claim 5a: "A brief's first unfenced "Asked:" line, matched by file name (a move to closed/ under its name too; two changed paths with one name on a side refuse), must be as on BASE, or BASE's line followed by ", " and more (no line on BASE: every item is added). Each item added must be exactly Q-NNN or Q-NNN@SHA (7-64 hex), name an entry the questions files gain"

**Location:** `scripts/build-loop.sh:221-228`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the extension test, item grammar, the new-entry test against both questions files on both sides, name matching across closed/, and the same-name-twice refusal; does not establish behaviour when questions_rules fails early (then cy.new is empty and every added item also refuses, a fail-closed extra line).
**Legibility-target:** operator reading `--help`; U4b author

```bash
# scripts/build-loop.sh:1963-1973 (excerpt ends :1973; cycle_rules continues to :1980 — read)
  for f in "${!an[@]}"; do
    o="${ao[$f]-}"; n="${an[$f]}"
    [[ "$n" != "$o" ]] || continue
    if [[ -z "$o" ]]; then a="${n#Asked:}"; a="${a# }"
    elif [[ "$n" == "$o, "* ]]; then a="${n#"$o, "}"
    else echo "refuse ${ap[$f]}: its first Asked: line drops or changes an ID it held; the cycle only appends one"; bad=1; continue; fi
    a+=", "
    while [[ -n "$a" ]]; do
      x="${a%%, *}"; a="${a#*, }"
      if ! [[ "$x" =~ ^(Q-[0123456789]+)(@[0123456789abcdef]{7,64})?$ ]]; then echo "refuse ...: its first Asked: line adds \"$x\", which is not Q-NNN or Q-NNN@SHA"; bad=1; continue; fi
```

New IDs come from `awk -F '\t' 'FILENAME == ARGV[1] { if ($3 == "h") o[$1]; next } $3 == "h" && !($1 in o) { print $1 }' "$t.qo" "$t.qn" > "$t.new"` (`scripts/build-loop.sh:2018`), where qo/qn hold both questions files of each side. Test 25 pins appended/new/missing/inexact/same-name/closed-move cases; probe P4 (new brief, no BASE line, new entry) printed `ok`; P5 (Asked: line removed, file kept) refused as "drops or changes".

**Evidence:** `scripts/build-loop.sh:1924-1938`, `scripts/build-loop.sh:1960-1976`, `scripts/build-loop.sh:1986-2020`, `u4a-fcf-r1-bats.log`, `u4a-fcf-r1/probe2.out`

---

## Claim 5b: "and be added by no other brief" / refusal "which another brief's Asked: line adds too" (cycle_rules comment: "no other brief takes")

**Location:** `scripts/build-loop.sh:228`, `scripts/build-loop.sh:1975`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the one-brief-per-ID check's wording against the case of one brief adding the same new ID twice; does not establish any bypass (the code is stricter than the text, so it fails closed).
**Legibility-target:** operator reading the refusal line at run time

The `used` map is keyed by ID alone, not by brief, so a repeat within the same brief trips it:

```bash
# scripts/build-loop.sh:1973-1976 (cycle_rules continues to :1980 — read)
      id="${BASH_REMATCH[1]}"
      if ! grep -qxF -- "$id" "$t.new"; then echo "refuse ${ap[$f]}: its first Asked: line adds $x, which names no question entry this change files"; bad=1
      elif [[ -n "${used[$id]-}" ]]; then echo "refuse ${ap[$f]}: its first Asked: line adds $x, which another brief's Asked: line adds too"; bad=1
      else used[$id]=1; fi
```

Probe P1: one brief, `Asked: Q-001, Q-002, Q-002`, Q-002 newly filed, no other brief changed. Output: `refuse docs/working/briefs/2026-10-01-x.md: its first Asked: line adds Q-002, which another brief's Asked: line adds too`. No other brief adds it; the refusal names a cause that is not there, and the header's rule ("by no other brief") does not say a repeat in one brief refuses. Message/header only: the behaviour (refusing) is safe.

**Evidence:** `scripts/build-loop.sh:1973-1976`, `scripts/build-loop.sh:228`, `u4a-fcf-r1/probe2.out` (P1)

---

## Claim 6: "A brief with an Asked: line deleted, or renamed to another file name, refuses."

**Location:** `scripts/build-loop.sh:228-229`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers deletion (executed in test 25) and rename (static: the old name gets no new-side entry); does not establish anything for a brief whose only Asked: line is fenced (asked() reads none, so it passes, as the header's "unfenced" says).
**Legibility-target:** operator reading `--help`

```bash
# scripts/build-loop.sh:1960-1962
  for f in "${!ao[@]}"; do
    [[ -z "${ao[$f]}" || -n "${an[$f]+set}" ]] || { echo "refuse ${aop[$f]}: deleted or renamed with its Asked: line; the cycle only moves a brief to closed/ under its name"; bad=1; }
  done
```

**Evidence:** `scripts/build-loop.sh:1960-1962`, `u4a-fcf-r1-bats.log` (ok 25)

---

## Claim 7: "--land-cycle ... after --state's gate but its caller check: HEAD must be on chore/dev-cycle-DATE or chore/dev-cycle-DATE-HHMM, the index as its commit, and --main the default branch's commit"

**Location:** `scripts/build-loop.sh:236-240`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers state_gate (GATED) + state_start's default_gate/store_check, no caller_gate, and the three preconditions; does not establish the order of the checks (the code checks branch, --main, then index; the header lists no order).
**Legibility-target:** operator reading `--help`

`if [[ "$MODE" == state ]]; then caller_gate || exit 2; fi` / `if [[ -n "$GATED" ]]; then state_gate || exit 2; fi` (`scripts/build-loop.sh:702-703`); land_cycle's checks at `scripts/build-loop.sh:2026-2034` (branch regex, `[[ "$LAND_MAIN" == "$MAIN_SHA" ]]`, `git diff-index --cached --quiet ... "$h"`). Test 26 executes each refusal (not on a chore branch, moved main, staged change).

**Evidence:** `scripts/build-loop.sh:702-703`, `scripts/build-loop.sh:1310-1316`, `scripts/build-loop.sh:2025-2034`, `u4a-fcf-r1-bats.log` (ok 26)

---

## Claim 8: "The merge of HEAD into main, as --check's (merge-tree, no repo config), is judged against main by --cycle-diff's rules with these --answered IDs (what lands: a rename git pairs into a questions file, or a fence pair that captures main's answer, shows here)"

**Location:** `scripts/build-loop.sh:240-245`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers merge_result in the gate repository, the diff MAIN_SHA..R fed to cycle_rules (ANSWERED read by questions_rules), and the rename case; the fence-pair case is not executed here; does not establish that --cycle-diff's questions guard runs (it does not; the brief says it is --cycle-diff's alone).
**Legibility-target:** operator reading `--help`; reviewer of row 753

```bash
# scripts/build-loop.sh:2037, 2048-2051 (land_cycle continues to :2058 — read)
  rc=0; r="$(merge_result "$h")" || rc=$?
  ...
  gate_git diff-tree -r --no-renames --raw -z --ignore-submodules=none "$MAIN_SHA" "$r" > "$GATE_TMP/diff" && raw_records "$GATE_TMP/diff" \
    || { echo "refuse HEAD: the paths its merge changes could not be listed"; return 1; }
  cycle_rules "$MAIN_SHA" merge || return 1
```

Test 27: --cycle-diff prints ok while merge-tree's result holds `Q-001: [1]`, and --land-cycle refuses "Q-001 is a new entry filed answered"; ok 27.

**Evidence:** `scripts/build-loop.sh:1101-1111`, `scripts/build-loop.sh:2025-2058`, `scripts/build-loop.sh:2011`, `u4a-fcf-r1-bats.log` (ok 27)

---

## Claim 9: "Then it writes the merge with the message "Merge branch 'B'" and moves the default branch as --merge does (a compare-and-swap from that commit, or a fast-forward in the worktree that has it checked out; no hooks run)."

**Location:** `scripts/build-loop.sh:246-250`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers message bytes, parents MAIN_SHA and HEAD's commit, tree R, update-ref CAS and merge --ff-only in W, and no repo hook (reference-transaction, post-merge, post-commit, pre-merge-commit) firing on either path; does not establish hooks configured outside the repo's hooks dir (core.hooksPath in config is refused by the state gate; HARDEN sets core.hooksPath=/dev/null).
**Legibility-target:** operator reading `--help`; reviewer of rows 719, 749, 752

```bash
# scripts/build-loop.sh:1548-1550 (excerpt ends :1550; land continues to :1565 — read)
  { if [[ "$1" == cycle ]]; then chore_msg "${VERDICT[branch]}"; else gate_msg ...; fi; } > "$GATE_TMP/msg" \
    && x="$(gate_git commit-tree --no-gpg-sign -p "$MAIN_SHA" -p "${VERDICT[tip]}" "${VERDICT[tree]}" < "$GATE_TMP/msg")" \
```

`HARDEN=(... core.hooksPath=/dev/null ...)` (`scripts/lib/dev-cycle-read.sh:352`). probe1b: hooks planted in the repo's hooks dir; both lands printed `landed ...`, `hooks.log: (none)` after each; main's commit has parents `<old main> <HEAD>` and message `Merge branch 'chore/dev-cycle-2026-10-13'`. Test 26 asserts `main^1 main^2 main^{tree}` and the message.

**Evidence:** `scripts/build-loop.sh:1479-1565`, `scripts/lib/dev-cycle-read.sh:352`, `u4a-fcf-r1/probe1b.out`, `u4a-fcf-r1-bats.log` (ok 26)

---

## Claim 10a: "Prints landed B HEAD TREE NEW — B: the branch; HEAD: its commit (the merge's second parent); TREE: the merge's tree; NEW: the merge commit, now the default branch's"

**Location:** `scripts/build-loop.sh:251-255`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the output fields; does not establish the reflog wording (Claim 10b).
**Legibility-target:** operator / U4b skill text parsing the line

`echo "landed $b $h $r $NEW"` (`scripts/build-loop.sh:2057`); test 26 compares the whole line against `landed $B $H $T $(git rev-parse main)`.

**Evidence:** `scripts/build-loop.sh:2057`, `u4a-fcf-r1-bats.log` (ok 26)

---

## Claim 10b: "(its reflog entry reads "build-loop: cycle land of B")"

**Location:** `scripts/build-loop.sh:254-255`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both move paths' reflog text; does not establish W's HEAD reflog.
**Legibility-target:** operator reading the reflog

`msg="build-loop: $what of ${VERDICT[stem]}"` with `what="cycle land"` (`scripts/build-loop.sh:1482-1483`). probe1b: the CAS path's main reflog reads `build-loop: cycle land of chore/dev-cycle-2026-10-12`; the fast-forward path's reads `build-loop: cycle land of chore/dev-cycle-2026-10-13: Fast-forward`. --merge's header states that suffix ("git adds ": Fast-forward" when W moves it", `scripts/build-loop.sh:397-398`); --land-cycle's does not. Precise version: "... cycle land of B" (git adds ": Fast-forward" when W moves it).

**Evidence:** `scripts/build-loop.sh:1480-1483`, `scripts/build-loop.sh:1557-1563`, `u4a-fcf-r1/probe1b.out`

---

## Claim 11: "or refuse lines and exit 2: --cycle-diff's rules' (PATH a file; a copy of the merge is "its merge copy"), or refuse HEAD: WHY — Not on such a branch; the default branch moved ...; staged changes; nothing the default branch lacks; a conflict; an object that does not hash or has two copies; no such record; --merge's own refusals of the move; or a read that fails (HEAD's commit, the merge, its paths)."

**Location:** `scripts/build-loop.sh:256-264`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every `refuse HEAD` echo in land_cycle mapping to a listed reason and `k="$side"` giving "its merge copy"; does not establish the state-gate refusal lines (`refuse state ...`), which the header covers by "after --state's gate".
**Legibility-target:** operator / U4b skill text

Each echo in land_cycle (`scripts/build-loop.sh:2026-2056`) maps to one listed reason (paraphrased — no quote available because the list spans eleven echo statements across 30 lines; read whole). `k=base; [[ "$p" == o ]] || k="$side"` (`scripts/build-loop.sh:2006`). Test 26/27 execute branch, moved main, staged, nothing-lacking, no record, conflict and a cycle-rules refusal.

**Evidence:** `scripts/build-loop.sh:2025-2058`, `scripts/build-loop.sh:2006`, `u4a-fcf-r1-bats.log`

---

## Claim 12: land comment: "--land-cycle's (AUTHORITY cycle, VERDICT and CHANGED set by land_cycle; the message git merge writes, "Merge branch 'B'", which --main-log reads as chore)"

**Location:** `scripts/build-loop.sh:1464-1466`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the cycle authority branch in land and git 2.39's merge message on main; does not establish git's message under merge.suppressDest settings or other git versions.
**Legibility-target:** maintainer reading land

`[[ "$1" != cycle ]] || what="cycle land"` (`scripts/build-loop.sh:1482`); `land cycle` (`scripts/build-loop.sh:2056`); VERDICT/CHANGED set at `scripts/build-loop.sh:2054-2055`. The git-merge probe wrote `Merge branch 'chore/dev-cycle-2026-10-12'` on main.

**Evidence:** `scripts/build-loop.sh:1479-1483`, `scripts/build-loop.sh:2054-2056`

---

## Claim 13: "chore_msg B: the message of a chore merge, as git merge writes it and --land-cycle writes it (land); log_class reads it back by its subject regex."

**Location:** `scripts/build-loop.sh:1729-1731`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the one definition used by land and the subject regex accepting it; does not establish that log_class calls chore_msg (it does not; it matches by regex, as stated).
**Legibility-target:** maintainer

`chore_msg() { printf "Merge branch '%s'\n" "$1"; }` (`scripts/build-loop.sh:1731`); regex `^Merge\ branch\ \'(chore/dev-cycle-...)\'($|\ into\ |:)` (`scripts/build-loop.sh:1772`); test 26's --main-log line reads chore.

**Evidence:** `scripts/build-loop.sh:1731`, `scripts/build-loop.sh:1771-1776`, `u4a-fcf-r1-bats.log`

---

## Claim 14: "chore_record B: a cycle record among RAW_* (isrecord, added or changed, mode 100644) holds the line "Branch: B" (a trailing CR dropped): what makes a merge of B chore for --main-log, and what --land-cycle checks before it writes one. Returns 1 when none does or a read fails."

**Location:** `scripts/build-loop.sh:1732-1735`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the function body (Claim 2's quote) and both callers; does not establish pipefail is on in both callers' shells (the "a read fails" half relies on it, as the inline comment says).
**Legibility-target:** maintainer

Callers: `! chore_record "$b" || CLASS=chore` (`scripts/build-loop.sh:1776`) and `chore_record "$b" || { echo "refuse HEAD: the merge adds or changes no cycle record ..."; return 1; }` (`scripts/build-loop.sh:2052`), before `land cycle` at :2056.

**Evidence:** `scripts/build-loop.sh:1732-1744`, `scripts/build-loop.sh:1776`, `scripts/build-loop.sh:2052-2056`

---

## Claim 15: "# chore_msg's subject, or git merge's with " into X" or ": ..." after it."

**Location:** `scripts/build-loop.sh:1771`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the regex's three endings; does not establish byte equality with chore_msg (the gate class compares bytes, the chore class only the subject).
**Legibility-target:** maintainer

`\'($|\ into\ |:)` (`scripts/build-loop.sh:1772`).

**Evidence:** `scripts/build-loop.sh:1771-1772`

---

## Claim 16: cycle_diff comment: "So a staged questions change needs the questions files as on main: merge the default branch into HEAD first. (--land-cycle judges the merge itself.)"

**Location:** `scripts/build-loop.sh:1883-1887`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the guard firing only when a questions path is staged and comparing base/main listings, and land_cycle not calling it; does not establish the guard catches a questions file absent on both base and main (it does not; test 27's comment says so and land catches it).
**Legibility-target:** maintainer

See Claim 3's quote; land_cycle calls `cycle_rules "$MAIN_SHA" merge` directly (`scripts/build-loop.sh:2051`), never cycle_diff.

**Evidence:** `scripts/build-loop.sh:1883-1896`, `scripts/build-loop.sh:2051`

---

## Claim 17: "asked FILE: a brief's first "Asked:" line outside a fence, a trailing CR dropped, or nothing: brief_fields' reading, but for a brief FENCE_AWK refuses after that line, which brief_fields does not read at all."

**Location:** `scripts/build-loop.sh:1897-1901`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers asked()'s awk (first unfenced line, CR dropped, exit on it); does not establish brief_fields' exact reading (settled override row 2026-10-13 i1 security F4).
**Legibility-target:** maintainer

`asked() { LC_ALL=C awk "$FENCE_AWK"'{ sub(/\r$/, "") } fence($0) { next } /^Asked:/ { print; exit }' "$1"; }` (`scripts/build-loop.sh:1901`).

**Evidence:** `scripts/build-loop.sh:1901`, `scripts/lib/dev-cycle-read.sh:435-466`

---

## Claim 18: "cycle_rules BASE SIDE: the cycle's rules over RAW_* ...: --cycle-diff's (BASE the merge base, SIDE "index") and --land-cycle's (BASE main's commit, SIDE "merge", the merge it writes), SIDE naming the listing's side in refusals. Prints "refuse PATH: WHY" per finding; returns 1 on any."

**Location:** `scripts/build-loop.sh:1902-1906`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers both call sites and SIDE's one use; does not establish that every refusal is per-path (questions_rules' "entries could not be compared" names questions.md for either file).
**Legibility-target:** maintainer

Calls `cycle_rules "$base" index` (`scripts/build-loop.sh:1895`) and `cycle_rules "$MAIN_SHA" merge` (`scripts/build-loop.sh:2051`); SIDE used only in `k="$side"` (`scripts/build-loop.sh:2006`); `return "$bad"` (`scripts/build-loop.sh:1979`).

**Evidence:** `scripts/build-loop.sh:1907-1980`, `scripts/build-loop.sh:2006`

---

## Claim 19: cycle_rules Asked: comment: "each a Q-NNN or Q-NNN@SHA (D4) naming an entry this change files ($t.new) ... A brief deleted, or renamed to another file name, with an Asked: line refuses too."

**Location:** `scripts/build-loop.sh:1946-1952`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the grammar, the new-entry and deletion parts (Claims 5a, 6); the "no other brief takes" part is Claim 5b.
**Legibility-target:** maintainer

As quoted in Claims 5a and 6.

**Evidence:** `scripts/build-loop.sh:1946-1976`, `u4a-fcf-r1/probe2.out`

---

## Claim 20: "questions_rules BASE SIDE I...: ... also writes $GATE_TMP/cy.new, the IDs of the entries the listing files (a "### Q-NNN" heading BASE lacks), one per line: empty when no questions file changed or a read failed. Prints refusals; returns 1 on any."

**Location:** `scripts/build-loop.sh:1981-1985`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the truncation at entry, the zero-index return, every early `return 1` before the final write, and the final awk's failure branch; does not establish QKEYS_AWK's heading reading beyond its regex.
**Legibility-target:** maintainer

```bash
# scripts/build-loop.sh:1987-1990 (questions_rules continues to :2020 — read)
  local base="$1" side="$2" f k i p md id bad=0 t="$GATE_TMP/cy"
  shift 2
  : > "$t.new"
  [[ $# -gt 0 ]] || return 0
```

and `... > "$t.new" || { : > "$t.new"; echo "refuse ..."; return 1; }` (`scripts/build-loop.sh:2018-2019`).

**Evidence:** `scripts/build-loop.sh:1986-2020`

---

## Claim 21: land_cycle comments: "store_check reads every blob of R, so a blob the store lacks refuses here"; "cycle_rules reads RAW_* and leaves it as raw_records filled it, for chore_record and CHANGED"; "Every key check_line sets, so land reads none unset"

**Location:** `scripts/build-loop.sh:2043-2054`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers store_check's ls-tree -r -t of each REV through cat-file --batch (a missing object fails the perl parse), that neither cycle_rules nor questions_rules nor cyc_blob/asked writes RAW_*, and VERDICT's six keys; does not establish blobs shared with main's skip list are re-read (they are skipped by design).
**Legibility-target:** maintainer

store_check: `git ls-tree -r -t --full-tree --format='%(objecttype) %(objectname)' "$r"` ... `my ($id, $t, $s) = $h =~ /^([0-9a-f]+) ([a-z]+) ([0-9]+)\n\z/ or exit 1;  # "NAME missing" too` (`scripts/build-loop.sh:1074-1080`). RAW_* writes occur only in raw_records (`scripts/build-loop.sh:1026-1034`; grep: no other assignment in cycle_rules/questions_rules — paraphrased — no quote available because the claim covers absence of code). `VERDICT=([tip]="$h" [tree]="$r" [policy]=- [branch]="$b" [stem]="$b" [gate]="")` (`scripts/build-loop.sh:2054`), the keys the check_line comment names (`scripts/build-loop.sh:1335-1338`).

**Evidence:** `scripts/build-loop.sh:1062-1095`, `scripts/build-loop.sh:1026-1034`, `scripts/build-loop.sh:2043-2055`

---

## Claim 22: "A cycle record: one per day, updated in place by each iteration (dev-cycle.sh reads the window from these names; build-loop.sh's --main-log and --land-cycle read its Branch: lines)."

**Location:** `scripts/lib/dev-cycle-read.sh:243-245`
**Type:** Architectural
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** The parenthesis is verified (dev-cycle.sh's glob `cycle-[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9].md` at `scripts/dev-cycle.sh:225`; chore_record's two callers); "one per day, updated in place by each iteration" is orchestrator behaviour no code here enforces (settled override row 2026-10-13, fact-check claim 19b, deferred to U4b).
**Legibility-target:** maintainer; U4b record template author

`for f in docs/working/cycles/cycle-[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9].md; do` (`scripts/dev-cycle.sh:225`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:243-246`, `scripts/dev-cycle.sh:225`, `scripts/build-loop.sh:1776`, `scripts/build-loop.sh:2052`

---

## Claim 23: "The read-as-truth rule --check-fix, floor and build-loop.sh's cycle_rules share (cycle_rules refuses every word but cycle, so a cycle file must never take an earlier word"

**Location:** `scripts/lib/dev-cycle-read.sh:1899-1901`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that no lower-case cycle path (roadmap, questions, archive, idea log, dated record, brief or closed brief) matches case, instr or dot; does not establish future edits keep it so (no test pins it).
**Legibility-target:** maintainer of truthrule

Words before `cycle`: case (cycle_rules passes a lowered path), instr (`INSTRUCTION_FILE='^(claude|agents?|gemini)(\.[a-z0-9_-]+)?\.md$|^skill\.md$'` on the basename, `scripts/lib/dev-cycle-read.sh:699`; a brief basename starts with a date, so it never matches; PROMPT_DIR needs `.claude/`), dot (no cycle path has a `.`-prefixed component). Probe P2 passed every cycle path.

**Evidence:** `scripts/lib/dev-cycle-read.sh:699-712`, `scripts/lib/dev-cycle-read.sh:1914-1925`, `scripts/lib/dev-cycle-read.sh:240-249`, `u4a-fcf-r1/probe2.out`

---

## Claim 24: Test 25 name: "--cycle-diff refuses the gate's code, truth files and a brief's Asked: line other than extended by entries the change files, matched by name across a move to closed/ (row 745, U4a, i1 security F1-F3, i2 F-a to F-d)"

**Location:** `test/scripts/build-loop-orchestrator.bats:441`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each named behaviour having an assertion (gate code, truth files incl. settings and instr, case-spelled cycle file, appended/new/absent IDs, inexact items, one brief per ID, closed/ move, same name twice, deletion); does not establish a rename-to-another-name case or a same-brief duplicate (not in the test).
**Legibility-target:** reviewer reading the test list

`git mv "$F" "$C"; cd_is ok; sed -i 's/^Asked: .*/Asked: Q-002@def1234/' "$C"; git add -A; cd_is "refuse $C: $W"` (`test/scripts/build-loop-orchestrator.bats:454`); the truth-file block at :461-466. ok 25.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:441-467`, `u4a-fcf-r1-bats.log`

---

## Claim 25: Test 26 name: "--land-cycle lands HEAD's chore branch as the merge --main-log reads as chore, by compare-and-swap or a fast-forward where main is checked out (D13, rows 719, 749, 752, U4a)"

**Location:** `test/scripts/build-loop-orchestrator.bats:473`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the CAS land (main not checked out: the test repo sits on the chore branch), the --main-log chore line, and the fast-forward land from a linked worktree with main checked out in the first; does not assert the reflog text or the absence of hooks (probe1b covers both).
**Legibility-target:** reviewer reading the test list

`[ "$(git rev-parse main^1 main^2 'main^{tree}')" = "$N2"$'\n'"$H"$'\n'"$T" ]` (:487) and `bl --main-log "$N2"; ... [ "${lines[1]}" = "chore $(git rev-parse main) Merge branch '$B'" ]` (:489); fast-forward at :491-494. ok 26.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:469-495`, `u4a-fcf-r1-bats.log`

---

## Claim 26: Test 27 name: "--land-cycle judges the merge, not the index: a rename git pairs into a new questions file carries main's answer, and a conflict refuses (row 753, U4a)"

**Location:** `test/scripts/build-loop-orchestrator.bats:497`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers --cycle-diff passing while merge-tree's result holds main's answer and --land-cycle refusing it, then a conflict refusal; does not cover the fence-pair capture case the header also names.
**Legibility-target:** reviewer reading the test list

`cd_is ok; git show "$(git merge-tree --write-tree main HEAD):docs/working/questions.md" | grep -qxF 'Q-001: [1]'` then `lc_is "refuse docs/working/questions.md: Q-001 is a new entry filed answered ..."` (:502-503). ok 27.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:497-506`, `u4a-fcf-r1-bats.log`

---

## Claim 27: Plan U4a as-built note and script-interface bullets ("--land-cycle takes --main SHA ...; cycle_rules BASE SIDE also refuses truthrule's files but the cycle's own ..., every Asked: item added must name an entry the questions files gain, and a brief deleted or renamed with an Asked: line refuses ...; the questions guard stays --cycle-diff's. Row 674's entry line and rows 680/683 moved to U4b: an entry line would change every --check line-count test (about 15)"; interface: "--land-cycle --main SHA [--answered Q-…] (U4a; gated) → landed B HEAD TREE NEW, or refuse HEAD: why / refuse PATH: why (exit 2) ...")

**Location:** `docs/working/plan-build-loop-handoff.md:209-212`, `docs/working/plan-build-loop-handoff.md:339`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers each code-facing statement (flag, rules, guard placement, output forms, merge-tree judgement, record, commit-tree message, --merge's move; no `entry` line in --check); does not establish the "about 15" test count (an estimate: build-loop-check.bats has 10 explicit `${#lines[@]}` assertions, plus whole-output compares not counted), and the bullets omit the case-spelled cycle-file rule, exact items and one-brief-per-ID (omissions, not errors) and the `refuse state` lines.
**Legibility-target:** U4b/U4c authors reading the plan

`grep -c 'lines\[@\]}" -eq\|#lines\[@\]' test/scripts/build-loop-check.bats` printed 10 (paraphrased — no quote available because it is a grep count, not a source line). "It replaces pr-prep's hand merge" is the intent; SKILL.md still names pr-prep (settled row 2026-10-13 i1 architecture 7).

**Evidence:** `docs/working/plan-build-loop-handoff.md:209-212`, `docs/working/plan-build-loop-handoff.md:339`, `scripts/build-loop.sh:2025-2058`

---

## Claim 28: Commit 722c2e10 body: "--land-cycle --expect MAIN [--answered Q-NNN]... lands ... (no hooks run: rows 719, 749, 752)"

**Location:** commit 722c2e10
**Type:** Reference / Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the flag name, which 70d24331 changed to `--main` (that commit's body says so); the rest (merge judged, record required, chore_record/isrecord shared, "it is deleted" wording) matches HEAD; the row-749 citation is settled (override row 2026-10-13, claim 24b).
**Legibility-target:** reviewer reading git log

At 722c2e10: `if [[ "$1" == --expect && "$MODE" == land-cycle ...` (`git show 722c2e10:scripts/build-loop.sh:523`); at HEAD `--main` (`scripts/build-loop.sh:539`).

**Evidence:** commit 722c2e10, commit 70d24331, `scripts/build-loop.sh:539`

---

## Claim 29: Commit 70d24331 body: "... (asked_rule; i1 security F1, F3) ... cycle_rules refuses truthrule's files but the cycle's own (instruction and prompt files, ...)"

**Location:** commit 70d24331
**Type:** Staleness / Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the function name asked_rule, which 4df6ec58 inlined into cycle_rules (no `asked_rule` at HEAD); the other bullets (--main, guard moved into cycle_diff, SIDE, chore_msg, VERDICT keys, correction of 722c2e10's row-749 note) match HEAD; the "but the cycle's own" wording is settled (override row 2026-10-13, fact-check i2 claims 2, 21b).
**Legibility-target:** reviewer reading git log

`asked_rule() {` at `git show 70d24331:scripts/build-loop.sh:1980`; `grep -rn asked_rule scripts/` at HEAD finds none (paraphrased — no quote available because the claim covers absence of code).

**Evidence:** commit 70d24331, commit 4df6ec58, `scripts/build-loop.sh:1907-1980`

---

## Claim 30: Commit 4e14d1cc: "U4a fix-drift: "other than a cycle file", not "but" ... wording only"

**Location:** commit 4e14d1cc
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the commit's diff (two comment lines in scripts/build-loop.sh, no code); does not establish the later wording (4df6ec58 rewrote both passages again).
**Legibility-target:** reviewer reading git log

`git show 4e14d1cc --stat`: `scripts/build-loop.sh | 4 ++--`, both hunks inside `#` comments.

**Evidence:** commit 4e14d1cc

---

## Claim 31: Commit 4df6ec58 body: exact items ("the old check read only the item's start, so ", Q-002@Q-003" carried an old answered ID"), one brief per new ID, same-name paths refuse, case-spelled cycle files refuse, Asked: rule inline, questions_rules called once, "Refusals word truthrule's classes by floor_why's prose", header items

**Location:** commit 4df6ec58
**Type:** Behavioral / Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each bullet against HEAD and the old mechanism against 70d24331; the imprecision is that the settings class is worded by cycle_rules' own string, not floor_why (floor_why has no settings word); does not re-run the old code's ", Q-002@Q-003" case.
**Legibility-target:** reviewer reading git log

Old check: `[[ "$x" =~ ^(Q-[0123456789]+)(@|$) ]] && grep -qxF -- "${BASH_REMATCH[1]}" "$1"` (`git show 70d24331:scripts/build-loop.sh:1995`), reading only the ID before `@`. HEAD: `w="the dev cycle's settings file"; [[ "$TRUTH_WHY" == settings ]] || w="$(floor_why "$TRUTH_WHY")"` (`scripts/build-loop.sh:1920`). questions_rules has one caller (`scripts/build-loop.sh:1953`). Precise version: "by floor_why's prose (the settings file by its own)".

**Evidence:** commit 4df6ec58, `scripts/build-loop.sh:1920`, `scripts/build-loop.sh:1953`, `scripts/lib/dev-cycle-read.sh:2016-2031`

---

## Claims Requiring Attention

### Incorrect
- **Claim 5b** (`scripts/build-loop.sh:1975`, header :228): one brief adding the same new ID twice refuses with "which another brief's Asked: line adds too" when no other brief adds it (probe P1); the header's "added by no other brief" does not say a repeat in one brief refuses. Message/header only, fails closed: word it "which an Asked: line already adds" (or key `used` by brief and refuse repeats separately).

### Stale
- **Claim 28** (commit 722c2e10): names `--expect MAIN`; the flag is `--main` since 70d24331.
- **Claim 29** (commit 70d24331): names `asked_rule`, inlined into cycle_rules by 4df6ec58.

### Mostly Accurate
- **Claim 10b** (`scripts/build-loop.sh:254-255`): the fast-forward path's reflog reads "build-loop: cycle land of B: Fast-forward"; say so as --merge's header does.
- **Claim 31** (commit 4df6ec58): the settings class is worded by cycle_rules' own string, not floor_why's.

### Unverifiable
- **Claim 22** (`scripts/lib/dev-cycle-read.sh:243`): "one per day, updated in place by each iteration" is orchestrator behaviour (settled, deferred to U4b's record template).

---

## Goal-Alignment Note

Success criterion: a markdown report saved at the exact path your own prompt names, structured per your skill.

This report is saved at `docs/reviews/code-fact-check-report-2026-10-13-u4a-final-r1.md` in the worktree with first line `Commit: c4e36d1d`, follows the code-fact-check structure, and tags every claim with a Legibility-target. No other file in /workspace or the worktree was written; probes ran under `/tmp/u4a-fcf-r1-*` with all processes under `timeout` and finished.
