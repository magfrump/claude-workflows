Commit: 4e14d1cc

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u4a (branch `feat/build-loop-u4a`)
**Scope:** Partial scope: the fix range 722c2e10..4e14d1cc (70d24331, c0cafb66, 4e14d1cc; diff `u4a-i2.diff`) in `scripts/build-loop.sh` and `test/scripts/build-loop-orchestrator.bats`, plus the commit messages of 70d24331 and 4e14d1cc. 722c2e10 is context only, not under review.
**Replication:** k=1 (loop pass, decision 031)
**Checked:** 2026-10-13
**Total claims checked:** 26
**Summary:** 21 verified, 4 mostly accurate, 0 stale, 1 incorrect, 0 unverifiable

Hallucination pattern log (`docs/reviews/hallucination-patterns.md`) read first. No claim here matches a logged pattern, and no Incorrect verdict is a fabrication (claim 4b is a validation gap, not a symbol that does not exist). The brief allows only this file to be written, so the log is not updated.

## Execution log (provenance for every `executed` claim)

Each probe ran under `timeout`, in a temp dir with the `/tmp/u4a-fc2-` prefix, against `git archive` trees (read-only on the worktree). No process outlived its call.

- **E1:** cwd `/workspace/.claude/wt-build-loop-u4a`; `LC_ALL=C TMPDIR=/tmp/u4a-fc2-bats-5Ezg timeout 900 bats test/scripts/build-loop-orchestrator.bats`; exit 0 (27/27 ok); 2026-10-13T20:38:08Z; output `/tmp/u4a-fc2-bats-5Ezg/out.txt`.
- **E2:** cwd `/tmp/u4a-fc2-old-ZUkh/src` (`git archive 722c2e10` with 4e14d1cc's bats file copied in); `LC_ALL=C TMPDIR=/tmp/u4a-fc2-old-ZUkh/tmp timeout 900 bats -f 'truth files and a brief' test/scripts/build-loop-orchestrator.bats`; exit 1 (the rewritten test fails on the old code at its first F1 case); 2026-10-13 about 20:38Z; output `/tmp/u4a-fc2-old-ZUkh/out.txt`.
- **E3:** probe file `/tmp/u4a-fc2-probe-IPkP/probe.bats` (14 isolated `--cycle-diff` cases P1 to P12, each printing status and output); run in cwd `/tmp/u4a-fc2-probe-IPkP/new` (`git archive 4e14d1cc`) and `/tmp/u4a-fc2-probe-IPkP/old` (`git archive 722c2e10`) as `LC_ALL=C TMPDIR=... timeout 600 bats test/scripts/probe.bats`; exit 0 for both runs; 2026-10-13T20:39:10Z; outputs `/tmp/u4a-fc2-probe-IPkP/new.txt` and `/tmp/u4a-fc2-probe-IPkP/old.txt`.
- **E4:** probe file `new/test/scripts/probe2.bats` under `/tmp/u4a-fc2-land-GCUh` (L1 land plus reflog, L2 a merge copy refused whole, L3 `--expect` given to `--land-cycle`); cwd `/tmp/u4a-fc2-land-GCUh/new` (`git archive 4e14d1cc`); `LC_ALL=C TMPDIR=/tmp/u4a-fc2-land-GCUh/tmp timeout 300 bats test/scripts/probe2.bats`; exit 0; 2026-10-13T20:39:51Z; output `/tmp/u4a-fc2-land-GCUh/out.txt`.

---

## Claim 1: "--land-cycle --main SHA [--answered Q-NNN]..." (usage and parser: --main replaces --expect)

**Location:** `scripts/build-loop.sh:10`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** header text (usage line) and the usage() message
**Scope:** Covers the parser accepting `--main` once with a full hex id and refusing `--expect` for `--land-cycle`; does not establish behaviour for a 64-hex id in a sha1 repo (it parses, then the CAS check compares it to MAIN_SHA).

The parser takes `--main` only for land-cycle:

```bash
# scripts/build-loop.sh:537
      if [[ "$1" == --main && "$MODE" == land-cycle && $# -ge 2 && -z "$LAND_MAIN" && "$2" =~ ^([0123456789abcdef]{40}|[0123456789abcdef]{64})$ ]]; then LAND_MAIN="$2"
```

E4 L3 ran `--land-cycle --expect <main>` and got status 1 with `--land-cycle takes --main SHA (the default branch's full commit id), once, and --answered Q-NNN, one ID each (usage: ...)` on stderr. Every `--land-cycle` call in the suite uses `--main`, and the suite passes (E1).

**Evidence:** `scripts/build-loop.sh:10`, `scripts/build-loop.sh:535-543`, `/tmp/u4a-fc2-land-GCUh/out.txt`, `/tmp/u4a-fc2-bats-5Ezg/out.txt`

---

## Claim 2: "a path of the gate's own code (GATE_CODE) or one the lib's truthrule reads as truth, other than a cycle file (an instruction or prompt file, a dot path, docs/dev-cycle.md, docs/constraints.md, docs/decisions/, docs/human-author/; both compared lower-cased) refuses: --check-fix refuses them too"

**Location:** `scripts/build-loop.sh:216-222`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** header text (--cycle-diff rules)
**Scope:** Covers the refused class list against truthrule's words, lower-casing, and --check-fix also refusing every class; does not establish coverage of files reached only through an instruction file's @-import (truthwalk), which cycle_rules does not run (see claim 23).

The code refuses truthrule's classes except `cycle`, on the lower-cased path:

```bash
# scripts/build-loop.sh:1907,1912-1913
    p="${RAW_P[i]}"; lp="$(lower "$p")"
    if [[ "$lp" =~ $GATE_CODE ]]; then echo "refuse $p: the gate's own code; ..."; bad=1; continue; fi
    if truthrule "$lp" && [[ "$TRUTH_WHY" != cycle ]]; then echo "refuse $p: a file sessions or later cycles read as truth ($TRUTH_WHY); ..."; bad=1; continue; fi
```

truthrule's non-cycle words are instr, dot, settings, user and record (`scripts/lib/dev-cycle-read.sh:1914-1920`; its `case` word cannot fire on a lowered path). These match the parenthetical's list exactly. E3 P4 refused `.github/x.yml` (dot), `AGENTS.md` (instr), `docs/constraints.md` (user) and `docs/decisions/log.md` (record). P4b refused `Docs/Dev-Cycle.md` as (settings), which shows the lower-casing. `--check-fix` refuses all of these and any non-docs path, gate code included (`scripts/dev-cycle.sh:191-193`: it skips any path where `TRUTH_WHY` is set, or that is not `^docs/.*\.md$|^readme\.md$`).

The precise version: the parenthetical lists the *refused* truth classes, but grammatically it follows "a cycle file", so it reads as a list of cycle files (the files that are allowed). A reader can take it the wrong way round. The precise wording would be "one the lib's truthrule reads as truth (...), other than a cycle file".

**Evidence:** `scripts/build-loop.sh:216-222`, `scripts/build-loop.sh:1907-1913`, `scripts/lib/dev-cycle-read.sh:1912-1922`, `scripts/dev-cycle.sh:184-197`, `/tmp/u4a-fc2-probe-IPkP/new.txt`

---

## Claim 3: "must be as on BASE, or BASE's line followed by ", " and more (none on BASE: any line)"

**Location:** `scripts/build-loop.sh:223-224`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** header text (--cycle-diff rules)
**Scope:** Covers the line-shape rule for a brief with and without an Asked: line on BASE; does not establish the item-form rule (claim 4b).

When BASE has no Asked: line, the code strips `Asked:` and one space, then judges each item:

```bash
# scripts/build-loop.sh:1988
    if [[ -z "$o" ]]; then a="${n#Asked:}"; a="${a# }"
```

So "any line" holds only while every item names a new entry, which the next clause states. A bare `Asked:` line on a new brief is not accepted: E3 P6 printed `refuse docs/working/briefs/2026-10-02-y.md: its Asked: line adds , which names no question entry this change files` (an empty item). The precise version: "(none on BASE: any non-empty line)". The impact is low, because the skill adds Asked: only in later cycles (`skills/dev-cycle/SKILL.md:356`).

**Evidence:** `scripts/build-loop.sh:223-224`, `scripts/build-loop.sh:1985-1998`, `/tmp/u4a-fc2-probe-IPkP/new.txt` (P6)

---

## Claim 4a: "each item added ... must name an entry the questions files gain (a "### Q-NNN" heading BASE lacks)" / "each an entry this change files (NEW, one ID per line)"

**Location:** `scripts/build-loop.sh:225-227`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** header text and the asked_rule comment (`:1973-1976`)
**Scope:** Covers NEW as QKEYS h-lines of both questions files on both sides (the unchanged file's BASE copy on both sides), and the rule running when no questions file changed (NEW empty); does not establish the item-form parsing (claim 4b).

NEW is the set of IDs with an `h` line in the listing's keys and not in BASE's:

```bash
# scripts/build-loop.sh:1968
  LC_ALL=C awk -F '\t' 'FILENAME == ARGV[1] { if ($3 == "h") o[$1]; next } $3 == "h" && !($1 in o) { print $1 }' "$t.qo" "$t.qn" > "$t.new" \
```

`$t.qo` and `$t.qn` collect both files per side (`:1942-1958`). With no questions change, NEW is empty and asked_rule still runs (`:1938-1939`: `: > "$t.new"` then `asked_rule "$t.new"`). Executed (E3): P1 refused `Q-002@def` with no entry and the questions files unchanged; P2 refused `Q-003@def`, which names an entry already on BASE; P12 refused `Q-000`, which is in the archive on BASE; P10 passed `Q-002` filed in the archive; P6b passed a new brief whose `Asked: Q-002` names a new entry.

**Evidence:** `scripts/build-loop.sh:1938-1970`, `scripts/build-loop.sh:1995`, `/tmp/u4a-fc2-probe-IPkP/new.txt`

---

## Claim 4b: "each item added (", "-separated, Q-NNN or Q-NNN@SHA)" / "Each added item, ", "-separated: Q-NNN, or Q-NNN@MARKER-SHA (D4)."

**Location:** `scripts/build-loop.sh:225-226`
**Type:** Behavioral / Invariant
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** header text and code comment (`:1991`)
**Scope:** Covers the item form the code accepts; does not establish how the dev-cycle skill's reader would split a malformed item (the medium confidence rests on that).

The code checks only that an item *starts* with `Q-NNN` followed by `@` or the end of the item. Nothing after `@` is checked:

```bash
# scripts/build-loop.sh:1995-1996
      [[ "$x" =~ ^(Q-[0123456789]+)(@|$) ]] && grep -qxF -- "${BASH_REMATCH[1]}" "$1" \
        || { echo "refuse ${ap[$f]}: its Asked: line adds $x, which names no question entry this change files"; bad=1; }
```

E3 P5 appended `, Q-002@def,Q-003` (comma without a space) with only Q-002 filed new, and got status 0 `ok`. P5b appended `, Q-002@ Q-003` and also got `ok`. Q-003 is an existing answered entry on BASE, so a second ID that names another question passes inside one "item", which is the i1 F1 class the rule targets. The skill reads Asked: IDs as ", "-separated (`skills/dev-cycle/SKILL.md:319`), so whether Q-003 would be applied depends on that reader. The suite's own fixture IDs (`@abc`, `@def`) are not SHAs either. To match the text, the code would have to anchor the item, for example `^(Q-[0-9]+)(@[0-9a-f]+)?$`. Otherwise the text should say "starting Q-NNN, then @ and anything".

Classification: behavioral (the documented item contract is not enforced), not comment-only.

**Evidence:** `scripts/build-loop.sh:225-226`, `scripts/build-loop.sh:1991-1997`, `skills/dev-cycle/SKILL.md:319`, `/tmp/u4a-fc2-probe-IPkP/new.txt` (P5, P5b)

---

## Claim 5: "a brief with an Asked: line deleted, or renamed to another file name, refuses"

**Location:** `scripts/build-loop.sh:227-228`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** header text and the asked_rule comment (`:1977-1978`)
**Scope:** Covers deletion and a rename within briefs/ to a new name; does not establish a rename whose old side has no Asked: line (not refused, by design).

```bash
# scripts/build-loop.sh:1982-1984
  for f in "${!ao[@]}"; do
    [[ -z "${ao[$f]}" || -n "${an[$f]+set}" ]] || { echo "refuse ${aop[$f]}: deleted or renamed with its Asked: line; the cycle only moves a brief to closed/ under its name"; bad=1; }
  done
```

E3 P3 (`git rm`) refused with that line. P9 (rename to `2026-10-01-z.md`) refused it, and also refused the new name's Asked: line as adding `Q-001@abc`. On 722c2e10's code both passed `ok` (old.txt).

**Evidence:** `scripts/build-loop.sh:1982-1984`, `/tmp/u4a-fc2-probe-IPkP/new.txt`, `/tmp/u4a-fc2-probe-IPkP/old.txt`

---

## Claim 6: "--main the default branch's commit (the one --cycle-diff checked; --merge's --expect is a branch tip instead)"

**Location:** `scripts/build-loop.sh:235-237`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** header text (--land-cycle)
**Scope:** Covers the compare-and-swap refusal when main moved and its wording; does not establish that the caller passes the same SHA --cycle-diff saw (the caller's duty).

```bash
# scripts/build-loop.sh:2009
  [[ "$LAND_MAIN" == "$MAIN_SHA" ]] || { echo "refuse HEAD: the default branch is at $MAIN_SHA, not --main's $LAND_MAIN; merge it into HEAD, run --cycle-diff again and land with --main $MAIN_SHA"; return 1; }
```

E1 test 26 pins this exact refusal after `onmain` moves main.

**Evidence:** `scripts/build-loop.sh:2009`, `test/scripts/build-loop-orchestrator.bats:349`, `/tmp/u4a-fc2-bats-5Ezg/out.txt`

---

## Claim 7: "landed B HEAD TREE NEW ... B: the branch; HEAD: its commit (the merge's second parent); TREE: the merge's tree; NEW: the merge commit, now the default branch's (its reflog entry reads "build-loop: cycle land of B")"

**Location:** `scripts/build-loop.sh:244-251`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** header text (--land-cycle output)
**Scope:** Covers the output fields and the reflog message on the update-ref path; does not separately check the reflog of the fast-forward path (it uses the same `$msg` via `GIT_REFLOG_ACTION`, `:1558`).

`land` sets `what="cycle land"` (`:1479`) and `msg="build-loop: $what of ${VERDICT[stem]}"` (`:1480`), with stem = B (`:2033`). E4 L1 printed `landed chore/dev-cycle-2026-10-12 <h> <tree> <new>`, and `git reflog show -1 main` read `build-loop: cycle land of chore/dev-cycle-2026-10-12`. Test 26 checks `main^1 main^2 main^{tree}` against `N2 H T`.

**Evidence:** `scripts/build-loop.sh:1479-1480`, `scripts/build-loop.sh:2033-2036`, `test/scripts/build-loop-orchestrator.bats:353-355`, `/tmp/u4a-fc2-land-GCUh/out.txt`

---

## Claim 8: "--cycle-diff's rules' (PATH a file; a copy of the merge is "its merge copy")"

**Location:** `scripts/build-loop.sh:252-253`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** header text (--land-cycle refusals)
**Scope:** Covers the whole-file refusal wording under SIDE=merge; does not establish other refusal texts (they name no side).

`k=base; [[ "$p" == o ]] || k="$side"` (`:1955`), with land passing `merge` (`:2030`). E4 L2: `refuse docs/working/questions.md: --check-answer refuses its merge copy whole (unbalanced 6)`.

**Evidence:** `scripts/build-loop.sh:1955-1956`, `scripts/build-loop.sh:2030`, `/tmp/u4a-fc2-land-GCUh/out.txt`

---

## Claim 9: "refuse HEAD: WHY ... the default branch moved (merge it into HEAD, run --cycle-diff again, land with --main at its commit); staged changes; ...; or a read that fails (HEAD's commit, the merge, its paths)."

**Location:** `scripts/build-loop.sh:254-260`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** header text (--land-cycle refusals)
**Scope:** Covers that each listed reason has a `refuse HEAD:` line in land_cycle; does not establish land()'s own MERGE_WHY texts.

Each reason maps to a line in land_cycle: the branch check (`:2007`), the CAS (`:2009`), "its commit could not be read" (`:2010`), staged changes (`:2012-2013`), "no commit the default branch lacks" (`:2015`), the conflict and "could not be computed" (`:2019-2020`), store_check (`:2024`), "the paths its merge changes could not be listed" (`:2028`), no record (`:2031`), and `land cycle || { echo "refuse HEAD: $MERGE_WHY"` (`:2035`).

**Evidence:** `scripts/build-loop.sh:2004-2037`

---

## Claim 10: "chore_msg B: the message of a chore merge, as git merge writes it and --land-cycle writes it (land); log_class reads it back by its subject regex."

**Location:** `scripts/build-loop.sh:1726-1728`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** code comment
**Scope:** Covers that chore_msg is the only writer of the chore message and that log_class matches it by regex (not by calling chore_msg); does not establish git's own merge message in every config.

`chore_msg() { printf "Merge branch '%s'\n" "$1"; }` (`:1728`) is called only at `:1545`. A grep for `Merge branch '%s'` finds otherwise only gate_msg (`:1456`). log_class matches `^Merge\ branch\ \'(chore/dev-cycle-...)\'($|\ into\ |:)` (`:1768`).

**Evidence:** `scripts/build-loop.sh:1545`, `scripts/build-loop.sh:1726-1728`, `scripts/build-loop.sh:1768`

---

## Claim 11: questions guard moved into cycle_diff: "So a staged questions change needs the questions files as on main ... (--land-cycle judges the merge itself.)" (with commit 70d24331's "The questions guard moves into cycle_diff")

**Location:** `scripts/build-loop.sh:1879-1890`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** code comment and commit message
**Scope:** Covers that the guard fires on the same trigger with the same refusal and exit, and that it was vacuous for --land-cycle; does not establish identical output: the guard now returns before cycle_rules, so the other refusal lines it used to print alongside are no longer printed.

The trigger is unchanged. Before, `qi` collected exactly the RAW_P entries equal to the two questions paths, and truthrule reads those paths as `cycle`, so no earlier rule catches them. Now the loop at `:1884-1890` tests the same equality. For --land-cycle the old guard compared `ls-tree $MAIN_SHA` with itself (BASE was MAIN_SHA), so it could only refuse on a read failure. Dropping it loses nothing there. E3 P7 (gate code and a questions change staged, main's questions changed): 722c2e10 printed two lines, `refuse scripts/lib/a.sh: the gate's own code; ...` and then the guard line. 4e14d1cc prints only the guard line and exits 2. The refusal is kept, but the remaining refusals show only after a second run.

**Evidence:** `scripts/build-loop.sh:1879-1891`, `scripts/build-loop.sh:1921-1922`, `/tmp/u4a-fc2-probe-IPkP/new.txt` (P7), `/tmp/u4a-fc2-probe-IPkP/old.txt` (P7)

---

## Claim 12: "asked FILE: a brief's first "Asked:" line outside a fence, a trailing CR dropped, or nothing: brief_fields' reading, but for a brief FENCE_AWK refuses after that line, which brief_fields does not read at all."

**Location:** `scripts/build-loop.sh:1893-1897`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** code comment
**Scope:** Covers the divergence when a FENCE_AWK refusal follows the Asked: line (asked prints the line, brief_fields sets no key); does not separately establish the "unbalanced" case, which brief_fields refuses in its own END block and which the comment's "FENCE_AWK refuses" covers only loosely.

asked exits at the first match (`/^Asked:/ { print; exit }`, `:1897`). brief_fields reads the whole blob and refuses on `odd` or `infence` in END (`scripts/lib/dev-cycle-read.sh:448`). A refusal before the line makes `fence()` return 1 for every later line (`if (odd) return 1`), so asked prints nothing, which agrees with brief_fields setting no key.

**Evidence:** `scripts/build-loop.sh:1897`, `scripts/lib/dev-cycle-read.sh:440-458`, `scripts/lib/dev-cycle-read.sh:300-304`

---

## Claim 13: "cycle_rules BASE SIDE: ... --cycle-diff's (BASE the merge base, SIDE "index") and --land-cycle's (BASE main's commit, SIDE "merge", the merge it writes), SIDE naming the listing's side in refusals."

**Location:** `scripts/build-loop.sh:1898-1902`
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** code comment
**Scope:** Covers both call sites and SIDE's one use; does not establish other wording differences (there are none: SIDE is read only at `:1955`).

Call sites: `cycle_rules "$base" index` (`:1891`) and `cycle_rules "$MAIN_SHA" merge` (`:2030`). SIDE is used only in `k="$side"` (`:1955`). E4 L2 shows "its merge copy".

**Evidence:** `scripts/build-loop.sh:1891`, `scripts/build-loop.sh:1955`, `scripts/build-loop.sh:2030`, `/tmp/u4a-fc2-land-GCUh/out.txt`

---

## Claim 14: "An in-cycle fix edits only docs --check-fix allows: never the gate's code, ... nor a file sessions or the cycle read as truth, other than the cycle's own (truthrule, which --check-fix refuses too: i1 security F2)."

**Location:** `scripts/build-loop.sh:1908-1911`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** code comment
**Scope:** Covers the two refusal lines that follow and --check-fix's agreement; does not establish @-import coverage (claim 23).

The code is quoted in claim 2 (`:1912-1913`). This comment has no misplaced parenthetical. E3 P11 passed `docs/thoughts/t.md`, `docs/guides/g.md`, the cycle record, a new roadmap and idea log, and `README.md`, which are all paths a real cycle or `--check-fix` allows.

**Evidence:** `scripts/build-loop.sh:1908-1913`, `scripts/dev-cycle.sh:184-197`, `/tmp/u4a-fc2-probe-IPkP/new.txt` (P4, P11)

---

## Claim 15: "The entries this change files: a heading the listing has and BASE lacks."

**Location:** `scripts/build-loop.sh:1967`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** code comment
**Scope:** Covers the h-key comparison over both files and both sides; does not establish fenced headings (QKEYS skips fenced lines, and a fenced question heading is refused whole first).

Quoted in claim 4a (`:1968`). A heading that moves between the two files is not new, because the IDs are compared without F (P12 refused `Q-000`, which is on BASE in the archive). A heading added to the archive counts as new (P10 ok).

**Evidence:** `scripts/build-loop.sh:1967-1969`, `/tmp/u4a-fc2-probe-IPkP/new.txt` (P10, P12)

---

## Claim 16: "Reads cycle_rules' ao, an, ap and aop (bash scope is dynamic); called only there. Returns 1 on any refusal."

**Location:** `scripts/build-loop.sh:1978-1979`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** code comment
**Scope:** Covers the call sites and variable use; does not establish the item-form claim (4b).

`grep asked_rule` finds only `:1939` and `:1970`, both inside cycle_rules. Those arrays are `local -A ao=() an=() ap=() aop=()` there (`:1905`), and asked_rule declares only `local f o n a x bad=0` (`:1981`). It ends with `return "$bad"` (`:1999`).

**Evidence:** `scripts/build-loop.sh:1905`, `scripts/build-loop.sh:1939`, `scripts/build-loop.sh:1970`, `scripts/build-loop.sh:1980-2000`

---

## Claim 17: "Also what check_line's blob-presence check gives --merge: store_check reads every blob of R, so a blob the store lacks refuses here (i1 architecture 1)."

**Location:** `scripts/build-loop.sh:2022-2023`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** code comment
**Scope:** Covers that every tree and blob id under R (listed with `ls-tree -r -t`) goes to `cat-file --batch`, and that a `missing` line fails the perl check; does not establish anything for ids on main's skip list, which store_check skips because gate_start's `--main` call has already hashed them.

```bash
# scripts/build-loop.sh (store_check)
      git ls-tree -r -t --full-tree --format='%(objecttype) %(objectname)' "$r" 2>/dev/null | awk '$1 != "commit" { print $2 }' || exit 1
    done; } | awk 'FILENAME != "-" { seen[$0]; next } !($0 in seen) { seen[$0]; print }' "$GATE_TMP/main" - | git cat-file --batch \
```
(excerpt; store_check continues through the copy count, read)

The perl reader exits 1 on a header that does not match `^([0-9a-f]+) ([a-z]+) ([0-9]+)\n` ("NAME missing" too).

**Evidence:** `scripts/build-loop.sh:2022-2024`, `scripts/build-loop.sh` store_check (defined after the comment block ending "Needs GATE_TMP.")

---

## Claim 18: "cycle_rules reads RAW_* and leaves it as raw_records filled it, for chore_record and CHANGED."

**Location:** `scripts/build-loop.sh:2029`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** code comment
**Scope:** Covers cycle_rules and asked_rule bodies; does not establish helpers outside them (cyc_blob, lower and truthrule do not touch RAW_*).

Neither function calls raw_records or assigns any RAW_ array (paraphrased, no quote available because the claim is about the absence of code across `:1903-2000`; a grep for `RAW_[A-Z]*=` or `raw_records` in that range finds nothing).

**Evidence:** `scripts/build-loop.sh:1903-2000`

---

## Claim 19: "Every key check_line sets, so land reads none unset (i1 architecture 4)."

**Location:** `scripts/build-loop.sh:2032-2033`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** code comment
**Scope:** Covers key-set equality with check_line's assignment; does not establish the values' meaning for land (policy `-`, gate empty).

check_line: `VERDICT=([tip]="$sha" [tree]="$tree" [policy]="$pol" [branch]="$br" [stem]="$stem" [gate]="$gc")` (`:1393`). land_cycle: `VERDICT=([tip]="$h" [tree]="$r" [policy]=- [branch]="$b" [stem]="$b" [gate]="")` (`:2033`). Same six keys.

**Evidence:** `scripts/build-loop.sh:1393`, `scripts/build-loop.sh:2033`

---

## Claim 20: test "--cycle-diff refuses the gate's code, truth files and a brief's Asked: line other than extended by entries the change files, matched by name across a move to closed/ (row 745, U4a, i1 security F1-F3)" and its case comments

**Location:** `test/scripts/build-loop-orchestrator.bats:304`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** test name and test comments (`:311`, `:321`)
**Scope:** Covers that each new case (F1 none/another's, F3 delete, F2 truth classes, lower-cased) fails on 722c2e10's code; does not establish coverage of the item-form gap (claim 4b) or of a rename within briefs/ (covered only by my probe P9).

E1: the test passes at 4e14d1cc. E2: on 722c2e10's script the test fails at its first F1 case (`want: refuse ...: its Asked: line adds Q-002@def ...`, got `ok`). E3 isolates the remaining cases: on 722c2e10, P2 (`Q-003@def`, another question's), P3 (`git rm`) and P4/P4b (truth files) each print `ok`, and the test pins refusals for each. The AGENTS.md line asserts `(instr)`, which pins the lowered path: unlowered, truthrule would say `(case)`. The positive case (Q-002 filed new) and the two W cases pass on both versions, as context.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:304-328`, `/tmp/u4a-fc2-old-ZUkh/out.txt`, `/tmp/u4a-fc2-probe-IPkP/old.txt`, `/tmp/u4a-fc2-bats-5Ezg/out.txt`

---

## Claim 21a: commit 70d24331 body bullets 1, 3, 4 and 5 (Asked: items must name a new entry, delete/rename refuses; --main not --expect; guard into cycle_diff, cycle_rules takes SIDE; chore_msg, every VERDICT key, comments)

**Location:** commit `70d24331` body
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** commit message
**Scope:** Covers each bullet against the code as in claims 1, 4a, 5, 10, 11, 13, 16, 17 and 19; does not establish the item-form residue (claim 4b) or the guard's suppressed co-refusals (claim 11), which the bullets do not assert against.

Bullet 1 ("An item added to a brief's first Asked: line must name an entry the questions files gain in this change; a brief deleted or renamed with an Asked: line refuses") matches E3 P1 to P3, P9 and P12. Bullet 3 matches E4 L3. Bullet 4 ("cycle_rules takes SIDE (index or merge) for its wording") matches `:1891`, `:2030` and `:1955`. Bullet 5 matches `:1728` and `:2033`.

**Evidence:** `git log -1 70d24331`, `scripts/build-loop.sh:1884-1891`, `scripts/build-loop.sh:1955`, `scripts/build-loop.sh:1980-2000`, `scripts/build-loop.sh:2033`

---

## Claim 21b: "cycle_rules refuses truthrule's files but the cycle's own (instruction and prompt files, dot paths, docs/dev-cycle.md, docs/constraints.md, docs/decisions/, docs/human-author/), as --check-fix does (i1 security F2)."

**Location:** commit `70d24331` body, bullet 2
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** commit message
**Scope:** Covers the class list and the --check-fix agreement; does not establish @-import coverage (claim 23).

The behaviour is as stated (claim 2, E3 P4/P4b). As in the header, the parenthetical sits after "the cycle's own", so it reads as a list of the cycle's own files rather than the refused classes. This is the same "but" wording that 4e14d1cc corrected in the code but cannot correct in this commit body.

**Evidence:** `git log -1 70d24331`, `scripts/build-loop.sh:1913`, `/tmp/u4a-fc2-probe-IPkP/new.txt`

---

## Claim 22: "Correction to 722c2e10's body: the land answers row 749 by judging HEAD's commit, not by running no hooks; the chore commit's own hooks remain the skill's (U4b)."

**Location:** commit `70d24331` body
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** commit message
**Scope:** Covers that the land refuses staged leftovers and judges the merge of HEAD's commit (so files a hook re-stages into the commit are judged); does not establish that the skill text (U4b) disables commit hooks.

Row 749 (override-log) is about a planted pre-commit hook re-staging files after --cycle-diff passed. land_cycle takes `h="$(git rev-parse --verify -q 'HEAD^{commit}')"`, refuses an index that differs from it (`:2012-2013`), and runs `cycle_rules "$MAIN_SHA" merge` over the merge of `h` (`:2016-2030`). So what was committed is what gets judged. 722c2e10's body said "(no hooks run: rows 719, 749, 752)". That refers to the land, which runs no hooks, but it does not address 749's commit-time hook, so the correction is accurate.

**Evidence:** `git log -1 722c2e10`, `docs/reviews/override-log.md:749`, `scripts/build-loop.sh:2010-2030`

---

## Claim 23: "truthrule does not cover files instruction files @-import (that needs the import walk, which --check-fix runs); an in-cycle fix that edits one lands. ... check_fix's own walk refuses such an edit before it is staged."

**Location:** commit `70d24331` body (Notes)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** commit message
**Scope:** Covers that cycle_rules runs no truthwalk and that check_fix does; does not establish that the skill always runs --check-fix before staging (U4b's text).

cycle_rules calls only `truthrule "$lp"` (`:1913`). A grep for `truthwalk` in `scripts/build-loop.sh` finds no call. check_fix runs `elif truthwalk tree "$lp"; then` and skips on a hit (`scripts/dev-cycle.sh:194-196`).

**Evidence:** `scripts/build-loop.sh:1913`, `scripts/dev-cycle.sh:194-196`

---

## Claim 24: commit 4e14d1cc "U4a fix-drift: "other than a cycle file", not "but" ... wording only"

**Location:** commit `4e14d1cc`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** commit message
**Scope:** Covers the diff's content (two comment lines, no code); does not establish that the new wording is unambiguous (see claim 2).

`git show 4e14d1cc` changes 2 lines in `scripts/build-loop.sh`, both comments: `truthrule reads as truth but a cycle file` becomes `truthrule reads as truth, other than a cycle file`, and `read as truth but the cycle's own` becomes `read as truth, other than the cycle's own`.

**Evidence:** `git show 4e14d1cc`, `scripts/build-loop.sh:218`, `scripts/build-loop.sh:1910`

---

## Claims Requiring Attention

### Incorrect
- **Claim 4b** (`scripts/build-loop.sh:225-226`, `:1991`, `:1995`): an item only has to *start* `Q-NNN` then `@` or end, so `Q-002@def,Q-003` or `Q-002@ Q-003` passes with Q-003 an existing entry (executed P5, P5b). Behavioral: anchor the item (e.g. `^(Q-[0-9]+)(@[0-9a-f]+)?$`) or reword the text.

### Mostly Accurate
- **Claim 2** (`scripts/build-loop.sh:218-221`): the list of refused classes sits after "other than a cycle file", so it reads as a list of cycle files. Move the parenthetical before "other than".
- **Claim 3** (`scripts/build-loop.sh:224`): "none on BASE: any line" does not cover a bare `Asked:` line, which refuses as adding an empty item.
- **Claim 11** (`scripts/build-loop.sh:1879-1890`): the moved guard returns before cycle_rules, so its refusal no longer comes with the other refusal lines (722c2e10 printed both).
- **Claim 21b** (commit 70d24331): the same misplaced parenthetical as claim 2, with the "but" wording 4e14d1cc fixed in code.

## Goal-Alignment Note

Success criterion: a markdown report saved at the exact path your own prompt names, structured per your skill.

This report is saved at `docs/reviews/code-fact-check-report-2026-10-13-u4a-i2.md`. Its first line is `Commit: 4e14d1cc`, and it carries the Replication header and a Legibility-target field on every claim. It covers the partial scope (722c2e10..4e14d1cc plus the bodies of 70d24331 and 4e14d1cc) and the brief's six named claims: 1 is claims 4a/4b/15, 2 is claim 11, 3 is claims 2/14, 4 is claims 1-9, 5 is claim 20, and 6 is claims 21a-24. One behavioral Incorrect (4b) bears on landing U4a: it is the i1 F1 class in a malformed-separator form.
