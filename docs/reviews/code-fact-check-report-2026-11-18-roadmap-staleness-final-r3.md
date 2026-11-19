# Code Fact-Check Report

**Repository:** claude-workflows (worktree /workspace/.claude/wt-roadmap-staleness)
**Scope:** branch `fix/dev-cycle-roadmap-staleness` vs `main`, full branch (`git diff main...HEAD`), plus `git log main..HEAD` commit messages; final confirming pass
**Commit:** 70a69b59
**Checked:** 2026-11-18
**Total claims checked:** 39
**Summary:** 30 verified, 5 mostly accurate, 2 stale, 2 incorrect, 0 unverifiable

Hallucination pattern log (`docs/reviews/hallucination-patterns.md`, 8 entries) read first. No claim below matches a logged pattern, and none of the Incorrect verdicts is a fabricated symbol, so nothing is added to the log. (This pass was read-only apart from this report.)

Execution logs are in the session scratch dir, `/tmp/claude-1000/-workspace/711f86df-792b-492f-9d5e-95022839ec2c/scratchpad/fc-final-r3-2129843/`, called `$X` below:
- `$X/bats.txt`: `timeout 900 bats test/scripts/dev-cycle.bats`, run from the worktree, started 2026-11-19T06:39Z (`$X/ts-bats.txt`), exit 0, 97/97 ok.
- `$X/migrations.txt`: `bash scripts/lib/migrations.sh fingerprint .` and `check .`, run from the worktree at 2026-11-19T06:39:42Z (`$X/ts-mig.txt`), both exit 0.
- `$X/dc-worktree.txt`: `timeout 120 bash scripts/dev-cycle.sh`, run from the worktree at 2026-11-19T06:42:44Z, exit 0.
- `$X/probe1/` (two Needs lines vs `check`; a multibyte title cut), `$X/probe2/branches.txt` (every section-3 branch), `$X/probe3/watch-noq.txt` (an open watch with no questions.md), `$X/probe4/mut.txt` (mutant without `read -a`). Each probe ran in a throwaway git repo under `$X`, with HOME and git config isolated, between 06:40Z and 06:45Z.

---

## Claim 1: Plan step 1's output format: "`- Now N · TITLE: open Q-NNN (route), …` or `- Now N · TITLE: no open entry or watch names it`", header "`Now and Next items, with the open entries or watches each names:`"

**Location:** `docs/working/plan-2026-11-18-roadmap-staleness.md:14`
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the plan's described output strings against the digest's current echo lines. Does not establish anything about the plan's other steps.
**Legibility-target:** for-author

The plan says it is complete (`**Task status**: complete`, line 5), but the digest now prints the verdict first and the title last, in quotes, under a different header:

```bash
# scripts/dev-cycle.sh:520,532-533
echo "Now and Next items, each with the open entries and watches it names, then its title (step 6 moves or explains every item none names):"
if [[ -n "$held" ]]; then echo "- $sec $num · open: $held · \"$title\""
else echo "- $sec $num · no open entry or watch names it · \"$title\""; fi
```

The format changed with A7 in 70a69b59. The plan still shows the e50efe75 shape.

**Evidence:** `docs/working/plan-2026-11-18-roadmap-staleness.md:14`, `scripts/dev-cycle.sh:520-533`

---

## Claim 2: "section 5 prints only the roadmap's Next section, quoted … Section 7 counts items in Now, In flight and Next and compares Now with the last brainstorm's commit (`now_of`) [observed]"

**Location:** `docs/working/research-2026-11-18-roadmap-staleness.md:10`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers section 5 as it was on main and section 7's count and `now_of`. Does not cover section 5 after this branch, which adds the list.
**Legibility-target:** for-orchestrator-synthesis

Section 7 counts the three sections:

```bash
# scripts/dev-cycle.sh:583-584
for sec in Now "In flight" Next; do
  n="$(awk -v h="## $sec" '… on && /^## / { exit } on && /^([-*] |[0-9]+\. )/ { c++ } END { print c + 0 }' docs/roadmap.md)"
```

It also defines `now_of` at `scripts/dev-cycle.sh:631`. On main, section 5 was only the line-464 quote of Next (paraphrased — no quote available because the claim is about main's version, where the only addition is the whole block at lines 465-536).

**Evidence:** `scripts/dev-cycle.sh:464`, `scripts/dev-cycle.sh:583-584`, `scripts/dev-cycle.sh:631`

---

## Claim 3: "keeping its output in `open_q`: one line per live-file entry of any status, plus each watch not marked ANSWERED, `ID  ROUTE  slug` [observed]"

**Location:** `docs/working/research-2026-11-18-roadmap-staleness.md:11`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers `cmd_open`'s filter and print format. Does not cover a malformed entry's route column (C2, override-logged).
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/questions.sh:580,585
{ parse_entries "$LIVE"; parse_entries "$WATCHING" | awk -F'\t' '{ s = $4; sub(/\r$/, "", s) } s != "ANSWERED"'; } \
    printf '%s  %-16s  %s\n' "$id" "$route" "$slug"
```

`cmd_open` (lines 575-587) was read in full.

**Evidence:** `scripts/questions.sh:575-587`

---

## Claim 4: On main, "Step 3 checks staleness for 'Now's agent work items' only … A light pass skips step 3", "Step 6 … has no rule for a Now or Next item that is finished or parked", and "Step 8 already says … 'each held item and its hold, not a category' … 'an owner call holds an item only when a questions-file entry asks it' [observed]"

**Location:** `docs/working/research-2026-11-18-roadmap-staleness.md:13-15`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers main's copy of `skills/dev-cycle/SKILL.md` (`git show main:…`). Does not cover the claim "Nothing checks either" beyond the absence of a script reader.
**Legibility-target:** for-orchestrator-synthesis

Main's step 3 reads `- Read Now's agent work items. One filed before the last cycle record is stale…` (main SKILL.md:508). Main's step 8 reads `An owner call holds an item only when a questions-file entry asks it` (main:761) and `naming each held item and its hold, not a category` (main:769-770). The step 6 rule for Now and Next items exists only in this branch's addition (`SKILL.md:626-643`). The light-pass skip of step 3 is at `SKILL.md:359`: `A light pass skips steps 2, 3, 4 and 4b`.

**Evidence:** main `skills/dev-cycle/SKILL.md:508`, `:761`, `:769-770`; `skills/dev-cycle/SKILL.md:359`, `:626-643`

---

## Claim 5: Invariants: tests "a questions.sh failure is reported…" and "section 3 lists watches…"; "`scrub_reexec` … `scripts/dev-cycle.sh:102`"; "prints all eight sections"; GATE_CODE covers `skills/dev-cycle/` and `scripts/dev-cycle.sh` [observed]

**Location:** `docs/working/research-2026-11-18-roadmap-staleness.md:19-22`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that each cited test, line and pattern exists as described. Does not establish that the scrub sanitizes invalid UTF-8 (see Claim 16).
**Legibility-target:** for-orchestrator-synthesis

`test/scripts/dev-cycle.bats:428` reads `@test "a questions.sh failure is reported, never shown as 'None open.'"`, and `:682` reads `@test "section 3 lists watches from watching.md …"`. `scripts/dev-cycle.sh:102` is `scrub_reexec "${BASH_SOURCE[0]}" "$@"`. The test at bats:40 checks all eight headings. GATE_CODE is `GATE_CODE='^scripts/(build-loop|d6|dev-cycle|questions)\.sh$|^scripts/lib/|^skills/dev-cycle/'` (`scripts/lib/dev-cycle-read.sh:1037`).

**Evidence:** `test/scripts/dev-cycle.bats:40-51`, `:428`, `:682`; `scripts/dev-cycle.sh:102`; `scripts/lib/dev-cycle-read.sh:1037`

---

## Claim 6: "`--cycle-diff` holds the roadmap's preamble and `## ` headings fixed … [observed: SKILL.md step 6, row 751]" and "Section 7's heading rule … is the one to reuse [observed]"

**Location:** `docs/working/research-2026-11-18-roadmap-staleness.md:23`, `:28`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the skill text the claim cites and that the heading test is the same. Does not cover `--cycle-diff`'s implementation in `build-loop.sh`, which was not read.
**Legibility-target:** for-orchestrator-synthesis

The skill says: `Step 9's --cycle-diff holds the roadmap to these moves (row 751): the lines above the first ## heading and the ## lines never change` (`SKILL.md:652-653`). Section 5's heading test `t == "## now" || index(t, "## now ") == 1 || index(t, "## now(") == 1` (`scripts/dev-cycle.sh:510`) is the same as section 7's `now_of` (`:631`).

**Evidence:** `skills/dev-cycle/SKILL.md:652-655`, `scripts/dev-cycle.sh:510-511`, `:631`

---

## Claim 7: "'Unit 1 merged at 236f21ee (Q-224 [1])' … [observed: the roadmap at 686258b1]"; "Next items are numbered … Now items are bullets … indented numbered sub-steps [observed]"

**Location:** `docs/working/research-2026-11-18-roadmap-staleness.md:33-34`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the quoted text and the item shapes in `git show 686258b1:docs/roadmap.md`. Does not cover today's roadmap.
**Legibility-target:** for-orchestrator-synthesis

At 686258b1, line 107 reads `Unit 1 merged at 236f21ee (Q-224 [1]); unit 2 merged at 6ee39f24 …`, Now items start `- **…`, and Next starts `1. **A8 post-restructure token measurement.**` (line 138).

**Evidence:** `686258b1:docs/roadmap.md:16`, `:107`, `:138`

---

## Claim 8: "section 5 gates on `open_ok`, set only when both succeed [observed: review 2026-11-18, claim 8]"

**Location:** `docs/working/research-2026-11-18-roadmap-staleness.md:35`
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every assignment of `open_ok`. Does not cover the clause before it (`open_q` may hold the first call's full list), which holds.
**Legibility-target:** for-author

Since 70a69b59 (R4), `open_ok` is also set in the branch for a repo with no questions file, where no `qopen` call runs:

```bash
# scripts/dev-cycle.sh:401-403
elif ! inrepo docs/working/questions.md; then
  echo "No docs/working/questions.md in this repo."
  open_ok=1   # nothing is open: section 5 lists every item as unheld
```

The other assignment is `:419`, after both calls succeed. "Set only when both succeed" was true before R4.

**Evidence:** `scripts/dev-cycle.sh:385`, `:401-403`, `:418-419`

---

## Claim 9a: "`open_ok=1   # nothing is open: section 5 lists every item as unheld`" (what section 5 prints)

**Location:** `scripts/dev-cycle.sh:403`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what section 5 prints when questions.md is absent. Does not cover whether "nothing is open" holds (Claim 9b).
**Legibility-target:** for-orchestrator-synthesis

With no questions file, `answered=" "` (line 489; the `[[ -f docs/working/questions.md ]]` guard skips the awk) and `open_q=""` (line 385). The lookup `r=…` at :529 therefore finds nothing, and every item prints `no open entry or watch names it`. Executed: `$X/probe2/branches.txt`, case "no questions file", exit 0, printed `- Now 1 · no open entry or watch names it · "A"`. Bats test 96 also passes (`$X/bats.txt`).

**Evidence:** `scripts/dev-cycle.sh:385`, `:489-496`, `:527-533`; `$X/probe2/branches.txt`; `$X/bats.txt`

---

## Claim 9b: "nothing is open" when docs/working/questions.md is absent

**Location:** `scripts/dev-cycle.sh:403`
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a repo with `docs/working/watching.md` holding an open watch and no `questions.md`. Does not establish how often that state occurs: `questions.sh init` creates all three files, and step 1 creates a missing `questions.md`.
**Legibility-target:** for-author

The no-questions-file branch never reads `watching.md`, but open watches live there (decision 040). With an open `trigger` watch Q-020 in `watching.md`, no `questions.md`, and a Now item `- **Held by watch** (Q-020)`, the digest printed (`$X/probe3/watch-noq.txt`, exit 0):

```
No docs/working/questions.md in this repo.
- Now 1 · no open entry or watch names it · "Held by watch"
```

Before this branch, this state stopped at section 3. Now it gives step 6 a false "no open … watch names it" line to act on, and step 6 may move an item that an open watch holds. Either the comment, or the branch (reading `watching.md` too), needs to change.

**Evidence:** `scripts/dev-cycle.sh:399-412`, `:527-533`; `$X/probe3/watch-noq.txt`

---

## Claim 10: "`open_ok=1   # section 5 reads open_q too`" and "Each column-0 item of Now and Next, with the open entries and watches it names (section 3's open_q)"

**Location:** `scripts/dev-cycle.sh:419`, `:465-466`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that section 5's route lookup reads `open_q`. Does not cover the watched or legacy split, which is section 3's alone.
**Legibility-target:** for-orchestrator-synthesis

`r="$(printf '%s\n' "$open_q" | awk -v id="$id" '$1 == id { r = substr($0, index($0, "  ") + 2, 16); … }')"` (`:529`). This is the same positional read as section 3's (`:426`).

**Evidence:** `scripts/dev-cycle.sh:418-419`, `:426`, `:529`

---

## Claim 11: "`questions.sh open` lists every live-file entry whatever its status, so an entry marked ANSWERED but not archived yet (step 1 archives after this digest runs) is left out here too"

**Location:** `scripts/dev-cycle.sh:467-470`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers well-formed live entries whose status is exactly ANSWERED, and the step order in the skill. Does not cover watching.md's closed entries, which `open` already drops.
**Legibility-target:** for-orchestrator-synthesis

`cmd_open` filters only `$WATCHING` by status (`questions.sh:580`). Step 1 runs `` `questions.sh archive` `` (SKILL.md, step 1, the 39th line of that section) after step 0.4's digest. In section 5, `[[ "$id" =~ ^Q-[0-9]+$ && "$answered" != *" $id "* ]] || continue` (`:528`) leaves those IDs out. Bats test 93 (`"Answered, not archived" … no open entry`) passes.

**Evidence:** `scripts/questions.sh:580`; `skills/dev-cycle/SKILL.md` step 1; `scripts/dev-cycle.sh:528`; `$X/bats.txt` (ok 93)

---

## Claim 12: "An item is its column-0 line and the indented lines under it; a column-0 line that is no item (prose, a ### heading) ends it."

**Location:** `scripts/dev-cycle.sh:470-472`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers item start, indented continuation and the end at a column-0 non-item line. Does not establish what happens at blank lines: they neither end an item nor join it, so an indented line after a blank line still continues the item (the comment makes no claim about this).
**Legibility-target:** for-orchestrator-synthesis

```awk
# scripts/dev-cycle.sh:513-515
sec != "" && /^([-*] |[0-9]+\. )/ { flush(); cur = sec; num = ++n[sec]; text = $0; next }
cur != "" && /^[ ]/ && NF { text = text " " $0; next }
NF { flush() }
```

Tabs become spaces first (`:508`), so a tab-indented line also continues an item. Bats tests 90, 92 and 93 pass.

**Evidence:** `scripts/dev-cycle.sh:497-516`; `$X/bats.txt` (ok 90, 92, 93)

---

## Claim 13: "Only the first Now and the first Next heading count, as in section 7."

**Location:** `scripts/dev-cycle.sh:472-473`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers section 5's `seen_now`/`seen_next` guards against section 7's count (`exit` at the next `## `) and `now_of` (`!d`). Does not cover headings other than Now and Next.
**Legibility-target:** for-orchestrator-synthesis

`if (!seen_now && (…)) { sec = "Now"; seen_now = 1 } else if (!seen_next && (…)) { sec = "Next"; seen_next = 1 }` (`:510-511`). Section 7's count stops at the first heading's end, `on && /^## / { exit }` (`:584`), and `now_of` does the same with `on && /^## / { on = 0; d = 1 } !d && …` (`:631`). Bats test 93 (no `A second Now section`) passes.

**Evidence:** `scripts/dev-cycle.sh:509-512`, `:584`, `:631`; `$X/bats.txt` (ok 93)

---

## Claim 14: "Each line prints the verdict before the item's title, the title quoted, so a title cannot stand where step 6 reads the verdict."

**Location:** `scripts/dev-cycle.sh:473-474`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the field order and the quotes. Does not establish that a title containing `"` is escaped: it is not escaped, but it still follows the verdict.
**Legibility-target:** for-orchestrator-synthesis

The echo lines at `:532-533` (quoted in Claim 1) put `$held` or the fixed verdict text before `\"$title\"`. In bats test 97, the title `B: open: Q-010 (you: judgment)` prints after the real verdict.

**Evidence:** `scripts/dev-cycle.sh:532-533`; `$X/bats.txt` (ok 97)

---

## Claim 15: "TITLE (its first bold span, else its first 80 characters; one trailing period dropped)"

**Location:** `scripts/dev-cycle.sh:475-476`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the title extraction under the awk this sandbox runs (mawk 1.3.4). Does not cover gawk in a UTF-8 locale, where `substr` counts characters.
**Legibility-target:** for-author

```awk
# scripts/dev-cycle.sh:500-502
if (match(text, /\*\*[^*]+\*\*/)) title = substr(text, RSTART + 2, RLENGTH - 4)
else { title = text; sub(/^([-*] |[0-9]+\. )/, "", title); title = substr(title, 1, 80); sub(/ +$/, "", title) }
sub(/\.$/, "", title)
```

Under mawk, `substr` counts bytes, so this is 80 bytes, not 80 characters. A cut can split a multibyte character. Executed: the item `- a` followed by 60 copies of `é` printed a title whose last byte is a lone `0xc3`, and Python's UTF-8 decode failed at byte 126 (`$X/probe1/`; grep called the output a "binary file"). The scrub does not repair it. `parse_entries` handles the same problem with `sub(/[\302-\364][\200-\277]*$/, "", summary)` (`questions.sh:242`). Precise version: "first 80 bytes (mawk)". "First bold span" means the first in the whole item, indented lines included, since `text` holds them.

**Evidence:** `scripts/dev-cycle.sh:498-506`; `scripts/questions.sh:232-245`; `$X/probe1/repo/out.txt`

---

## Claim 16: "joined by \x1f, which the awk first turns to a space wherever the roadmap holds one (a tab is IFS whitespace: an empty field would collapse and shift the rest)"

**Location:** `scripts/dev-cycle.sh:476-478`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the record separator, the `gsub` and the `IFS=$'\x1f' read`. Does not cover the separate conversion of tabs to spaces on the same line, which the comment does not explain.
**Legibility-target:** for-orchestrator-synthesis

`gsub(/[\t\037]/, " ")` (`:508`) runs on every line before any record is built, and `printf "%s\037%d\037%s\037%s\n"` (`:505`) writes the record. The reader is `while IFS=$'\x1f' read -r sec num title ids` (`:522`). Bash collapses runs of IFS whitespace (a tab) but not runs of non-whitespace delimiters like 0x1f, so the stated rationale is right. Bats test 97 (`"A B"`) passes.

**Evidence:** `scripts/dev-cycle.sh:505`, `:508`, `:522`; `$X/bats.txt` (ok 97)

---

## Claim 17: "**Now and Next items were NOT checked against open entries and watches** — section 3 did not read the questions files (see it above). Step 6 reports this; it never reads as every item held."

**Location:** `scripts/dev-cycle.sh:481`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every branch that leaves `open_ok=0`, and the skill's handling of this line. Does not cover the no-questions-file branch (Claim 9b).
**Legibility-target:** for-orchestrator-synthesis

Executed, `$X/probe2/branches.txt`: with questions.sh missing, a symlinked archive, a symlinked watching.md, a symlinked questions.md, or a failing `open`, each run exited 0, printed `**Watched questions were NOT checked** — …` in section 3 and this line in section 5, and printed no per-item lines. The skill handles the line: `When section 5 prints "Now and Next items were NOT checked", no item is moved on its account: the 6. line says so, with section 3's cause` (`SKILL.md:641-643`).

**Evidence:** `scripts/dev-cycle.sh:398-447`, `:480-481`; `skills/dev-cycle/SKILL.md:641-643`; `$X/probe2/branches.txt`

---

## Claim 18a: "read as questions.sh's parse_entries reads a well-formed entry …: the Status field of the last **Needs:** line under a "### Q-NNN " heading, the fields split on " · ""

**Location:** `scripts/dev-cycle.sh:483-486`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the heading match, the Needs-line match, the split, the `substr(…, 9)` and the last-wins rule against `parse_entries` (`questions.sh:200-251`, read in full). Does not cover malformed headings, where `$2` and `parts[1]` differ (for example `### Q-12 X` with no ` · `).
**Legibility-target:** for-orchestrator-synthesis

```awk
# scripts/dev-cycle.sh:491-495
function fl() { if (id != "" && st == "ANSWERED") printf "%s ", id; id = ""; st = "" }
/^### Q-[0-9]+ / { fl(); id = $2; next }
/^\*\*Needs:\*\*/ && id != "" { l = $0; gsub(/\*\*/, "", l); n = split(l, f, " · ")
  for (i = 1; i <= n; i++) if (f[i] ~ /^Status:/) st = substr(f[i], 9) }
END { fl() }
```

This mirrors `parse_entries`' `if (f[i] ~ /^Status:/) { status = substr(f[i], 9) }`, which runs on every Needs line, with the flush on the next heading (`questions.sh:211-231`). Bats test 95 (last wins, both orders) passes.

**Evidence:** `scripts/dev-cycle.sh:489-496`; `scripts/questions.sh:200-251`; `$X/bats.txt` (ok 95)

---

## Claim 18b: "(one **Needs:** line with all three fields, which `check` requires)"

**Location:** `scripts/dev-cycle.sh:484-485`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what `cmd_check` refuses. Does not cover `index`, whose "stale" error is unrelated.
**Legibility-target:** for-author

`check` requires a valid route, Opened date and status (`questions.sh:330-340`), but nothing in `cmd_check` (`:292-392`, read in full) counts Needs lines. Executed (`$X/probe1/`): an entry with two Needs lines (OPEN, then ANSWERED) got only the `⚠ … is ANSWERED but still in questions.md` warning and an index-stale error. Neither refuses the second Needs line. Precise version: "all three fields, which `check` requires". The "one line" part is not enforced. The conclusion holds anyway, because last-wins matches `parse_entries`.

**Evidence:** `scripts/questions.sh:292-392`; `$X/probe1/` (the check run's output is in the probe's console log: `check exit=1` with only the two messages above)

---

## Claim 18c: "compared whole, as `archive` compares it"

**Location:** `scripts/dev-cycle.sh:487`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the equality test on well-formed entries. Does not cover an entry with an empty field: `archive`'s `IFS=$'\t' read` collapses empty tab fields, so its `status` can shift (the well-formed qualifier at :484 covers this).
**Legibility-target:** for-orchestrator-synthesis

`st == "ANSWERED"` (`:491`) against `[[ "$status" == "ANSWERED" ]] || continue` (`questions.sh:465`). Neither strips a CR. Bats test 94 (`ANSWERED (2026-11-02)` still holds) passes.

**Evidence:** `scripts/dev-cycle.sh:491`; `scripts/questions.sh:460-481`; `$X/bats.txt` (ok 94)

---

## Claim 18d: "Section 3's list still carries these entries."

**Location:** `scripts/dev-cycle.sh:487-488`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers `open`'s unfiltered live file. Does not cover section 3's display, which prints only watch routes.
**Legibility-target:** for-orchestrator-synthesis

`{ parse_entries "$LIVE"; parse_entries "$WATCHING" | awk … s != "ANSWERED"'; }` (`questions.sh:580`): only the watching file is filtered.

**Evidence:** `scripts/questions.sh:580`

---

## Claim 19: "read -a splits without pathname expansion; each word is checked again against the ID shape the awk extracts."

**Location:** `scripts/dev-cycle.sh:524-525`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `read -ra` against a word-splitting `for`. Does not establish that a glob character can reach `$ids` at all: it cannot, since the awk extracts only `Q-[0-9]+` and 0x1f is mapped (see Claim 31).
**Legibility-target:** for-orchestrator-synthesis

Executed (`$X/probe1/`, under bash 5.2.15): with a file `Q-001` present, `read -ra a <<< " Q-0* *"` gave `[Q-0*] [*]`, while `for x in $ids` expanded to `Q-001 Q-001 home repo`. The recheck is `[[ "$id" =~ ^Q-[0-9]+$ … ]] || continue` (`:528`).

**Evidence:** `scripts/dev-cycle.sh:526-531`; `$X/probe1/`

---

## Claim 20: Section 3's new `open_ok=1` and every other branch's effect on section 5 under `set -u`

**Location:** `scripts/dev-cycle.sh:385`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the seven section-3 branches (normal, questions.sh missing, archive, watching or questions file not plain, `open` failing, no questions file) under the script's own `set -euo pipefail` (`:90`) and bash 5.2. Does not cover bash older than 4.4, where `"${id_list[@]}"` on an empty array trips `set -u`.
**Legibility-target:** for-orchestrator-synthesis

`open_ok=0; open_q=""` (`:385`) runs before any branch, so both are set wherever section 5 reads them. `answered`, `held` and `id_list` are assigned before use (`:489`, `:523`, `:526`). All seven runs exited 0 (`$X/probe2/branches.txt`, plus the no-file case in `$X/probe3/`). The real worktree digest also exited 0 and listed five items (`$X/dc-worktree.txt`).

**Evidence:** `scripts/dev-cycle.sh:90`, `:385`, `:489`, `:523-526`; `$X/probe2/branches.txt`; `$X/dc-worktree.txt`

---

## Claim 21: `mig record-6-roadmap-holds record f7f4746bca47b0bd - - 'none: the record's 6. line only gained what moved and each unheld item's hold; every record written before stays valid'`

**Location:** `scripts/lib/migrations.sh:165`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the fingerprint against the source and the "none" rationale (no script parses a record's `6.` line). Does not cover the convention-migrations bats file, which was not run.
**Legibility-target:** for-orchestrator-synthesis

`bash scripts/lib/migrations.sh fingerprint .` printed `record f7f4746bca47b0bd`, and `check .` exited 0 (`$X/migrations.txt`). A grep of `scripts/` and `hooks/` for a `6. roadmap` reader found none (paraphrased — no quote available because the claim covers absence of code). The template's change is additive: `6. roadmap: <done>; moved: …; unheld: …` (`SKILL.md:862`).

**Evidence:** `scripts/lib/migrations.sh:155-165`; `skills/dev-cycle/SKILL.md:862`; `$X/migrations.txt`

---

## Claim 22: Step 0's section map: "5 roadmap (steps 6 and 8)"

**Location:** `skills/dev-cycle/SKILL.md:328`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that steps 6 and 8 read section 5. Does not cover other steps.
**Legibility-target:** for-orchestrator-synthesis

Step 6 reads it (`the digest's section 5 lists each Now and Next item`, `:626`), and so does step 8 (`The holds come from the digest's section 5 list`, `:793-794`).

**Evidence:** `skills/dev-cycle/SKILL.md:328`, `:626`, `:793-795`

---

## Claim 23: Step 0.5: "a stale agent item in step 3 … waits for the day's first iteration … Step 6's check of roadmap items that no open entry or watch names runs in a light pass too."

**Location:** `skills/dev-cycle/SKILL.md:363-365`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers consistency with the light-pass skip list and step 6's text. Does not cover whether light-pass detection works.
**Legibility-target:** for-orchestrator-synthesis

`A light pass skips steps 2, 3, 4 and 4b and runs every other step as written` (`:359-360`), and step 6 says `Every iteration, a light pass included, reads that list` (`:627-628`). The phrase matches the digest's verdict text `no open entry or watch names it` (`scripts/dev-cycle.sh:533`).

**Evidence:** `skills/dev-cycle/SKILL.md:359-365`, `:626-628`

---

## Claim 24: Step 3: "Every other Now item is checked in step 6, which a light pass runs too."

**Location:** `skills/dev-cycle/SKILL.md:514-515`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers that every Now item appears on section 5's list and that step 6 reads the whole list. Does not establish that step 6 acts on a held item: it acts only on unheld items and on items whose only open ID is mentioned in passing.
**Legibility-target:** for-orchestrator-synthesis

Section 5 lists every column-0 item of the first Now (`scripts/dev-cycle.sh:513`). Step 6 `reads that list and acts on each item it shows as "no open entry or watch names it", and on each whose only open ID it names in passing` (`SKILL.md:628-629`). Medium confidence, because "checked" is a loose word for "listed and read".

**Evidence:** `skills/dev-cycle/SKILL.md:514-515`, `:626-629`; `scripts/dev-cycle.sh:513`

---

## Claim 25: The Ideas and Done definitions ("parked items, each with the owner answer that parked it and what brings it back"; "an item moved from Now or Next: the commit or answer that finished it")

**Location:** `skills/dev-cycle/SKILL.md:620-625`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers consistency with step 6's bullets. Does not cover `--cycle-diff` acceptance of the moves.
**Legibility-target:** for-orchestrator-synthesis

Step 6's bullets send items `→ Done, with the commit or answer that finished it` and `→ Ideas, with that answer's ID as its reason and what brings it back` (`:630-633`), which match both definitions.

**Evidence:** `skills/dev-cycle/SKILL.md:620-633`

---

## Claim 26: Step 6's "Items no open entry or watch names" bullet: "lists each Now and Next item with the open entries and watches it names, then its title", the quoted "no open entry or watch names it", and the "Now and Next items were NOT checked" handling

**Location:** `skills/dev-cycle/SKILL.md:626-643`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each quoted string against the digest's printed output. Does not cover the false-unheld case in Claim 9b, where the string is printed when it should not be.
**Legibility-target:** for-orchestrator-synthesis

The digest's header line is `Now and Next items, each with the open entries and watches it names, then its title …` (`scripts/dev-cycle.sh:520`), its verdict text is `no open entry or watch names it` (`:533`), and the not-checked line starts `**Now and Next items were NOT checked against …` (`:481`). The skill's quoted string is a literal substring of that line, without the bold markers. All three appear in executed output (`$X/dc-worktree.txt`, `$X/probe2/branches.txt`).

**Evidence:** `skills/dev-cycle/SKILL.md:626-643`; `scripts/dev-cycle.sh:481`, `:520`, `:533`

---

## Claim 27: Step 8: "The holds come from the digest's section 5 list and the record's `6.` line, never from the last record's `8.` line"

**Location:** `skills/dev-cycle/SKILL.md:793-795`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that both named sources exist and carry holds. Does not establish that any check enforces the rule: none does (the rule is prose).
**Legibility-target:** for-orchestrator-synthesis

Section 5 prints `open: Q-NNN (route)` per item (`scripts/dev-cycle.sh:532`), and the template's `unheld: <ITEM: its hold, …>` (`SKILL.md:862`) carries the other holds.

**Evidence:** `skills/dev-cycle/SKILL.md:793-795`, `:862`; `scripts/dev-cycle.sh:532`

---

## Claim 28: Record template: "`6. roadmap: <done>; moved: <ITEM → Done or Ideas (why), … / none>; unheld: <ITEM: its hold, … / none / not checked: why>`"

**Location:** `skills/dev-cycle/SKILL.md:862`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers consistency with step 6's outcomes (moved, held outside the questions files, not checked) and the `; ` and ` / ` shape of the other lines. Does not cover any parser, since none exists.
**Legibility-target:** for-orchestrator-synthesis

Step 6 sends items to Done or Ideas (`moved:`), names the hold of an item that stays (`the record's 6. line names that hold`, `:634-636`), and handles NOT checked (`:641-643`). The line uses ` / ` for alternatives and `; ` between fields, as the `8.` line does (`:865`).

**Evidence:** `skills/dev-cycle/SKILL.md:630-643`, `:862-865`

---

## Claim 29: Test 90's comments: "An indented sub-step belongs to its item (its IDs count there), not an item of its own; In flight and Ideas are not listed." and "CRLF endings read the same."

**Location:** `test/scripts/dev-cycle.bats:1663-1666`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what these assertions in test 90 check. Does not cover test 92, which does check that a sub-step's open ID counts.
**Legibility-target:** for-author

In this test the sub-step names only `Q-001`, which is archived (`e Q-001 old-answer … ANSWERED`, `:1626`). "Its IDs count there" is therefore not exercised: an open ID in the sub-step would change Now 1's verdict, and the test expects `no open entry` either way. The assertion checks only `!= *"Now 4"*` (`:1665`). Test 92 (`:1690-1697`) covers the claim. The CRLF assertion checks one line (`Now 2`, `:1668`), not the whole list. Precise version: "not an item of its own (test 92 checks that its IDs count)".

**Evidence:** `test/scripts/dev-cycle.bats:1622-1675`, `:1690-1697`

---

## Claim 30: Test names and comments for tests 91-96 (no items or no roadmap; indented sub-step holds; answered-not-archived, column-0 prose and first headings; Status only from the Needs line, exactly, with "Q-012's status is not exactly ANSWERED, so archive would not move it and it still holds"; the last Needs line wins; no questions file lists every item as unheld)

**Location:** `test/scripts/dev-cycle.bats:1677-1801`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each name against its assertions, and the run passing. Does not cover the open-watch edge of test 96's scenario (Claim 9b).
**Legibility-target:** for-orchestrator-synthesis

Each test's assertions check the behavior its name states (each test was read in full). For example, test 94 asserts `- Now 2 · open: Q-012 (you: judgment) · "B"` and `- Now 3 · no open entry …"C"`, matching `archive`'s exact comparison (`questions.sh:465`). All passed (`$X/bats.txt`: ok 91-96).

**Evidence:** `test/scripts/dev-cycle.bats:1677-1801`; `$X/bats.txt`

---

## Claim 31: Test 97 name: "a 0x1f byte or glob character in the roadmap shifts no field and expands nothing; a verdict-like title stays quoted after the verdict"

**Location:** `test/scripts/dev-cycle.bats:1803`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers whether the test detects the loss of each defense. Does not dispute that the behavior holds.
**Legibility-target:** for-author

The behavior holds, but the glob half does not test the `read -a` change. Once 0x1f is mapped to a space, `$ids` can hold only `Q-[0-9]+` tokens, so no glob character reaches the loop. Executed mutation (`$X/probe4/mut.txt`): `read -ra id_list … for id in "${id_list[@]}"` was replaced by the pre-fix `for id in $ids` and the test's scenario rerun. It printed `- Now 1 · no open entry or watch names it · "A B"` and no `Q-001 (`, so both assertions pass with the mutant. The test guards the 0x1f mapping and the quoting. Nothing tests the `read -a` line or the `^Q-[0-9]+$` recheck on their own.

**Evidence:** `test/scripts/dev-cycle.bats:1803-1815`; `scripts/dev-cycle.sh:524-531`; `$X/probe4/mut.txt`

---

## Claim 32: 70a69b59: "Size: 389 code lines against main (245 committed + 144 here)."

**Location:** commit `70a69b59` message
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `git diff --numstat` over non-docs paths (scripts, skill, tests). Does not decide which files count as "code".
**Legibility-target:** for-author

The addends are right: `main...969e8227` churn is 61+1+26+6+151 = 245, and `969e8227..HEAD` is 31+17+1+1+14+10+57+13 = 144 (python3 arithmetic). Their sum, 389, is the churn across the two segments, though, not the branch against main. `git diff --numstat main...HEAD` over the same paths gives 75+1+33+9+195 = 313, because lines added and then rewritten count twice in the sum. Precise version: "389 lines of churn (245 + 144), 313 against main".

**Evidence:** `git diff --numstat main...969e8227 -- . ':!docs'`, `969e8227..HEAD`, `main...HEAD` (command output in this session, not saved to a file)

---

## Claim 33: 70a69b59's other factual claims: R3 last Needs line wins; R4 no questions file lists every item as unheld; A6/A7 (0x1f → space, `read -a`, `^Q-[0-9]+$`, verdict then quoted title); A8/A9 (step 6 handles NOT checked, bold-and-dash shape, one trailing period dropped, Done widened, one wording, step 0.5, the `6.` line reshaped, new fingerprint f7f4746bca47b0bd); C1 and C2 override-log rows

**Location:** commit `70a69b59` message
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed change being present in `git show 70a69b59`, which the claims above verify. Does not cover R4's open-watch edge (Claim 9b), which the commit's wording ("a repo with no questions file") does not claim.
**Legibility-target:** for-orchestrator-synthesis

Each change is at the location cited in Claims 13-28. `docs/reviews/override-log.md` gains two 2026-11-18 rows, one for the `printf | awk` fork and one for the slug shown as the route. The wording `no open entry or watch names` is the only form in the skill (grep: `SKILL.md:365`, `:626`, `:628`).

**Evidence:** `scripts/dev-cycle.sh:403`, `:481`, `:502`, `:508`, `:526-533`; `skills/dev-cycle/SKILL.md:365`, `:626-643`, `:862`; `docs/reviews/override-log.md` (last two rows); `$X/migrations.txt`

---

## Claim 34: 57e8950a: "It now reads the Status field of the **Needs:** line alone, split on " · " as questions.sh's parse_entries splits it, and compares it exactly, as `archive` does, so the digest drops exactly what step 1 archives."

**Location:** commit `57e8950a` message
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the code at 57e8950a. Does not cover HEAD, where 70a69b59 (R3) fixed the mechanism and the comment, so no code action remains.
**Legibility-target:** for-author

At 57e8950a the awk reset `id = ""` after the first Needs line, so the first line won while `parse_entries` and `archive` take the last:

```awk
# 57e8950a:scripts/dev-cycle.sh:483-486
answered=" $(awk '/^### Q-[0-9]+ / { id = $2; next }
  /^\*\*Needs:\*\*/ && id != "" { … if (f[i] ~ /^Status:/ && substr(f[i], 9) == "ANSWERED") printf "%s ", id
    id = "" }' docs/working/questions.md) "
```

"Exactly what step 1 archives" was therefore false for an entry with an OPEN Needs line followed by an ANSWERED one. The rubric records this as R3 (Fixed). A commit message cannot be amended, so the rubric row is the correction.

**Evidence:** `git show 57e8950a:scripts/dev-cycle.sh` lines 476-487; `docs/reviews/code-review-rubric-2026-11-18-fix-dev-cycle-roadmap-staleness.md` (R3)

---

## Claim 35: e50efe75's motive ("their holds (Q-227, Q-234, Q-274) were answered"), 22f9cd8f's A1/A2 claims, and b7ebe774's "no change to --cycle-diff"

**Location:** commits `e50efe75`, `22f9cd8f`, `b7ebe774` messages
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the three IDs' archive status on main, the item-boundary and first-heading rules (Claims 12-13), and that `build-loop.sh` is absent from the branch diff. Does not verify "stayed in Now for weeks".
**Legibility-target:** for-orchestrator-synthesis

On main's `docs/working/questions-archive.md`, Q-227 (`image-lag`), Q-234 (`migrate-questions-owner-routes-040`) and Q-274 (`self-answer-plan-how-far`) each carry `**Status:** ANSWERED`. `git diff --stat main...HEAD` lists no `scripts/build-loop.sh` (paraphrased — no quote available because the claim covers the absence of a file from the diff).

**Evidence:** `main:docs/working/questions-archive.md` (the Q-227, Q-234 and Q-274 headings); `scripts/dev-cycle.sh:513-515`

---

## Claims Requiring Attention

### Incorrect
- **Claim 9b** (`scripts/dev-cycle.sh:403`): "nothing is open" is false when `watching.md` holds an open watch and `questions.md` is absent. Section 5 then prints "no open entry or watch names it" for an item that an open watch holds (executed). Either read `watching.md` in that branch, or qualify the comment and the step 6 handling.
- **Claim 34** (commit 57e8950a): "drops exactly what step 1 archives" was false at that commit (the first Needs line won). The code is already fixed by 70a69b59 (R3), and the rubric row is the correction.

### Stale
- **Claim 1** (`docs/working/plan-2026-11-18-roadmap-staleness.md:14`): the output format and header shown are the e50efe75 shape. The digest now prints the verdict first and the title last, in quotes, under a new header.
- **Claim 8** (`docs/working/research-2026-11-18-roadmap-staleness.md:35`): "open_ok, set only when both succeed": the no-questions-file branch also sets it (R4).

### Mostly Accurate
- **Claim 15** (`scripts/dev-cycle.sh:475-476`): "first 80 characters" is 80 bytes under mawk, and a cut can split a multibyte character, putting invalid UTF-8 into the digest (executed).
- **Claim 18b** (`scripts/dev-cycle.sh:484-485`): `check` requires the three valid fields, not one Needs line. A second Needs line passes `check` (executed).
- **Claim 29** (`test/scripts/dev-cycle.bats:1663-1666`): "its IDs count there" is not exercised in test 90 (the sub-step's ID is archived; test 92 covers it), and the CRLF check covers one line.
- **Claim 31** (`test/scripts/dev-cycle.bats:1803`): the glob half of test 97 passes with the pre-fix `for id in $ids` loop (mutation executed). Nothing tests `read -a` or the `^Q-[0-9]+$` recheck on their own.
- **Claim 32** (commit 70a69b59): 389 is the sum of the two segments' churn (245 + 144). The branch against main is 313 lines.

### Unverifiable
- None.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the path given at the end of this prompt, structured per the code-fact-check skill, with `**Commit:** 70a69b59` in its header.
- Answered: all six listed claim groups were verdicted against HEAD 70a69b59. That covers the section 5 comments, the section-3 `open_ok` branches under `set -u` (all seven run), the skill text against the digest's exact strings, the migration fingerprint (run), the test names (bats 97/97 ok, plus one mutation), and the commit and research or plan claims. Report saved at `docs/reviews/code-fact-check-report-2026-11-18-roadmap-staleness-final-r3.md`.
- Out of scope: code quality and performance (C1 is already override-logged); research line 4's "about 109 iterations" (not tagged [observed]); `--cycle-diff`'s implementation in `build-loop.sh`; behavior under gawk or bash older than 4.4.
- Escalate: Claim 9b is the one new behavioral finding (a false "unheld" line in a repo with `watching.md` but no `questions.md`). The orchestrator should decide whether it is red (step 6 could move an item an open watch holds) or amber (the state is unlikely, since `init` and step 1 create `questions.md`).
