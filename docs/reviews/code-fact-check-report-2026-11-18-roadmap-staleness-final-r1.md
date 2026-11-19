# Code Fact-Check Report

**Repository:** claude-workflows (worktree `/workspace/.claude/wt-roadmap-staleness`)
**Scope:** branch `fix/dev-cycle-roadmap-staleness` vs `main` (`git diff main...HEAD`: `scripts/dev-cycle.sh`, `scripts/lib/migrations.sh`, `skills/dev-cycle/SKILL.md`, `test/scripts/dev-cycle.bats`, `docs/working/{research,plan}-2026-11-18-roadmap-staleness.md`, the rubric's pass-3 rows) and the commit messages of `main..HEAD`
**Commit:** 70a69b59
**Checked:** 2026-11-18
**Total claims checked:** 43
**Summary:** 31 verified, 6 mostly accurate, 2 stale, 4 incorrect, 0 unverifiable

Final confirming pass, round 1. Earlier passes' reports and the rubric were read as context only; every claim below was verdicted against the code at 70a69b59.

Execution provenance (all runs on 2026-11-19 UTC, i.e. 2026-11-18 local; scratch dir `S=/tmp/claude-1000/-workspace/711f86df-792b-492f-9d5e-95022839ec2c/scratchpad/fc-final-r1-2097892`):

- E1: `timeout 900 bats test/scripts/dev-cycle.bats`, cwd the worktree, exit 0, 97/97 ok. Output: `$S/bats.out` (timestamp in `$S/bats.ts`).
- E2: `timeout 300 bash scripts/dev-cycle.sh`, cwd the worktree, 2026-11-19T06:44:36Z, exit 0. Output: `$S/digest.out`. Section 5 printed e.g. `- Now 1 · open: Q-301 (trigger) · "Agent: confine-tests follow-ups"` and `- Next 1 · no open entry or watch names it · "A8 post-restructure token measurement"`.
- E3 (mutations; scripts/ and test/ copied under `$S/tree` and `$S/t-*`, never into the worktree): (a) `read -ra … for id in "${id_list[@]}"` + the `^Q-[0-9]+$` check replaced by `for id in $ids` → the 0x1f/glob test still **passes** (`$S/mut-glob.out`, exit 0); (b) `gsub(/[\t\037]/, " ")` removed → that test fails (`$S/m-tab.out`, exit 1); (c) the no-file branch's `open_ok=1` removed → the "no questions file" test fails (`$S/m-nofile.out`, exit 1); (d) first-Status-wins in the `answered` awk → the "last Needs line" test fails (`$S/m-last.out`, exit 1).
- E4: digest in a fixture repo with `docs/working/watching.md` holding open watch Q-020, no `questions.md`, roadmap item `- **Held by watch** (Q-020)`: 2026-11-19T06:45:10Z, exit 0; section 5 printed `- Now 1 · no open entry or watch names it · "Held by watch"` (`$S/repo-noq/out.txt`).
- E5: digest in a fixture repo whose `docs/working/questions.md` is a symlink: exit 0; section 3 printed `**Watched questions were NOT checked** — …`, section 5 printed the `**Now and Next items were NOT checked against open entries and watches** — …` line (`$S/repo-link/out.txt`).
- E6: `questions.sh init/index/check` on a fixture live file with one entry carrying two `**Needs:**` lines (ANSWERED then OPEN): `check` exit 0, `✓ questions: structure valid, indexes current` (`$S/qchk/check.out`).
- E7: `bash scripts/lib/migrations.sh fingerprint .` (worktree): `record f7f4746bca47b0bd`; same on a `git archive main` extract: `record cd3e54279e1ed41b`, all other conventions identical; `bash scripts/lib/migrations.sh check .` exit 0.
- E8: pr-prep step 1a's command, `git diff --numstat "$B" -- ':(top)' ':(top,exclude)docs/' | awk '{ n += $1 + $2 } END { print n+0 }'`: `main...HEAD` 313, `main...HEAD~1` 245, `HEAD~1...HEAD` 144.
- E9: shell probes (bash 5.2.15, mawk): `IFS=$'\x1f' read` keeps an empty middle field, `IFS=$'\t' read` collapses it; `read -ra` on `Q-* *` with files `Q-1 Q-2` present gives `<Q-*><*>`, unquoted `for` gives `[Q-1][Q-2][Q-1][Q-2]`; mawk `substr("ééééé",1,3)` returns 3 bytes (`é` plus half a character).

Hallucination-pattern log read. Claim 35 resembles the logged pattern "commit-message count overclaimed" (e.g. "All 85 tests … pass" claimed in commit 59ca38f, "mode1-equiv 33" in 37c5ea9). No Incorrect verdict here is a fabricated symbol, so no log entry is due (and this pass writes nothing but this report).

---

## Claim 1: "Fixed: the comment states the well-formed scope, which `check` enforces"

**Location:** `docs/reviews/code-review-rubric-2026-11-18-fix-dev-cycle-roadmap-staleness.md:32`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers whether `questions.sh check` enforces the "one **Needs:** line" part of the comment's well-formed scope; does not establish anything about the digest's behavior, which matches `parse_entries` whatever the Needs layout (claim 15a).
**Legibility-target:** for-author

The comment the row points to defines well-formed as "one **Needs:** line with all three fields, which `check` requires" (`scripts/dev-cycle.sh:484-485`). `check` validates the merged fields `parse_entries` emits, not the line count:

```bash
# scripts/questions.sh:324-338 (excerpt ends :338; enclosing cmd_check() continues to :430 — read)
        while IFS=$'\t' read -r id route opened status slug _; do
            ...
            if [[ ! "$route" =~ ^($VALID_ROUTES)$ ]]; then
            ...
            if [[ "$status" != "OPEN" && "$status" != "ANSWERED" ]]; then
```

E6 ran `check` on an entry with two `**Needs:**` lines and it passed (exit 0). So `check` enforces "all three fields valid" but not "one Needs line". The row's "which `check` enforces" is true for the three fields only.

**Evidence:** `scripts/questions.sh:292-372`, `scripts/dev-cycle.sh:483-488`, `$S/qchk/check.out`

---

## Claim 2: plan step 1's output format, "`- Now N · TITLE: open Q-NNN (route), …` or `- Now N · TITLE: no open entry or watch names it`" (with "**Task status**: complete")

**Location:** `docs/working/plan-2026-11-18-roadmap-staleness.md:14`
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the line shape and header the plan says section 5 prints; does not establish the plan's other steps (they match the skill text, claims 20-26).
**Legibility-target:** for-author

The digest now prints the verdict first and the title last, in quotes, under a different header:

```bash
# scripts/dev-cycle.sh:520, 532-533
      echo "Now and Next items, each with the open entries and watches it names, then its title (step 6 moves or explains every item none names):"
        if [[ -n "$held" ]]; then echo "- $sec $num · open: $held · \"$title\""
        else echo "- $sec $num · no open entry or watch names it · \"$title\""; fi
```

E2 printed lines of that shape. The plan describes e50efe75's first layout, which pass 3 (A7) changed. The plan says the task is complete, so it now names a format the code no longer prints.

**Evidence:** `docs/working/plan-2026-11-18-roadmap-staleness.md:14`, `scripts/dev-cycle.sh:517-535`, `$S/digest.out`

---

## Claim 3: "`open_q`: one line per live-file entry of any status, plus each watch not marked ANSWERED, `ID  ROUTE  slug` [observed: `scripts/questions.sh` `cmd_open`]"

**Location:** `docs/working/research-2026-11-18-roadmap-staleness.md:11`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers `cmd_open`'s selection and line format when both of section 3's calls succeed; does not establish `open_q`'s content on a failed call, which section 5 does not read (it gates on `open_ok`).
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/questions.sh:580-585 (excerpt ends :585; enclosing cmd_open() ends :586 — read)
    { parse_entries "$LIVE"; parse_entries "$WATCHING" | awk -F'\t' '{ s = $4; sub(/\r$/, "", s) } s != "ANSWERED"'; } \
        | route_rank | sort -t$'\t' -k1,1 -k2,2 | cut -f2- \
        | while IFS=$'\t' read -r id route _ _ slug _; do
            printf '%s  %-16s  %s\n' "$id" "$route" "$slug"
```

The live file is not filtered by status. Watches are filtered on an exact ANSWERED, with the CR stripped.

**Evidence:** `scripts/questions.sh:569-586`, `scripts/dev-cycle.sh:417-418`

---

## Claim 4: research doc's remaining [observed] claims: section 5 printed only Next on main; step 3 covers "Now's agent work items" and a light pass skips step 3; step 6 had no rule for finished Now items; step 8's two quoted phrases; scrub at `:102`; the "prints all eight sections" test; GATE_CODE; `--cycle-diff`'s roadmap rules (row 751); section 7's heading rule

**Location:** `docs/working/research-2026-11-18-roadmap-staleness.md:10-28`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each cited symbol, test name and quoted phrase existing as described (main's text for the "what exists" lines); does not establish the "about 109 iterations" figure at line 6, which is not tagged [observed] and was not counted.
**Legibility-target:** for-orchestrator-synthesis

- `scrub_reexec "${BASH_SOURCE[0]}" "$@"` is at `scripts/dev-cycle.sh:102`.
- `@test "prints all eight sections in a repo with no docs"` (`test/scripts/dev-cycle.bats:40`), and the two section-3 test names (`:428`, `:682`) exist.
- `GATE_CODE='^scripts/(build-loop|d6|dev-cycle|questions)\.sh$|^scripts/lib/|^skills/dev-cycle/'` (`scripts/lib/dev-cycle-read.sh:1037`).
- `An owner call holds an item only when a questions-file entry asks it` (`skills/dev-cycle/SKILL.md:783`) and "naming each held item and its hold, not a category" (`:788-789`).
- On main, `- Read Now's agent work items.` and "A light pass skips" are present (`git show main:skills/dev-cycle/SKILL.md`, lines 508 and 358).
- Section 7's heading test is `t == g || index(t, g " ") == 1 || index(t, g "(") == 1` (`scripts/dev-cycle.sh:584`).

**Evidence:** `scripts/dev-cycle.sh:102,584,631`, `scripts/lib/dev-cycle-read.sh:1037`, `test/scripts/dev-cycle.bats:40,428,682`, `skills/dev-cycle/SKILL.md:645-648,783-791`

---

## Claim 5: "Every item names old answered IDs in its history … [observed: the roadmap at 686258b1]"

**Location:** `docs/working/research-2026-11-18-roadmap-staleness.md:33`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count of Q-IDs per Now and Next item in `git show 686258b1:docs/roadmap.md`; does not establish which of those IDs were answered on that date.
**Legibility-target:** for-author

The quoted history line exists (`686258b1:docs/roadmap.md:107`, "Unit 1 merged at 236f21ee (Q-224 [1])"). A per-item count of `Q-[0-9]+` mentions at that commit gave Now 1-5: 11, 6, 3, 6, 5, and Next 1-2: 0, 0. Every **Now** item names IDs, but the two Next items name none. The precise version: "every Now item".

**Evidence:** `git show 686258b1:docs/roadmap.md` (probe output in this session; paraphrased — no quote available because the per-item counts come from an awk pass over the whole file, not from one line)

---

## Claim 6: "so section 5 gates on `open_ok`, set only when both succeed"

**Location:** `docs/working/research-2026-11-18-roadmap-staleness.md:35`
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every assignment of `open_ok`; does not establish the first half of the sentence (`open_q` may hold the first call's list when the second fails), which holds.
**Legibility-target:** for-author

Pass 3 added a second place that sets it, where no `qopen` call runs at all:

```bash
# scripts/dev-cycle.sh:401-403
elif ! inrepo docs/working/questions.md; then
  echo "No docs/working/questions.md in this repo."
  open_ok=1   # nothing is open: section 5 lists every item as unheld
```

Now it is "set when both calls succeed, or when the repo has no questions file".

**Evidence:** `scripts/dev-cycle.sh:385,401-403,418-419`

---

## Claim 7: "open_ok=1   # nothing is open: section 5 lists every item as unheld"

**Location:** `scripts/dev-cycle.sh:403`
**Type:** Behavioral / Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the no-questions-file branch's effect on section 5, including when `watching.md` exists; does not establish how often a repo has `watching.md` without `questions.md` (`questions.sh init` creates both).
**Legibility-target:** for-author

The behavioral half holds: with no `questions.md`, `open_q` stays `""` (`:385`) and every item prints "no open entry or watch names it" (E1's test at `test/scripts/dev-cycle.bats:1795`; E3c shows the test depends on this line). The rationale "nothing is open" leaves out a qualifier. This branch never reads `docs/working/watching.md`, so an open watch there is invisible. In E4, an item naming open watch Q-020 printed `- Now 1 · no open entry or watch names it · "Held by watch"`. The precise version: "no questions file: section 5 lists every item as unheld (a `watching.md` without a questions file is not read)".

**Evidence:** `scripts/dev-cycle.sh:385,399-411,489-496,526-533`, `$S/repo-noq/out.txt`

---

## Claim 8: "open_ok=1   # section 5 reads open_q too"

**Location:** `scripts/dev-cycle.sh:419`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that section 5 reads `open_q` and only behind `open_ok`; does not establish other consumers of `open_q` (section 3's own `watched` and `routes` reads at `:426-440`).
**Legibility-target:** for-orchestrator-synthesis

It is set inside `if open_q="$(qopen …)" && open_l="$(qopen …)"; then` (`:418`), and section 5 reads it behind the gate: `if [[ "$open_ok" != 1 ]]; then` (`:480`), `r="$(printf '%s\n' "$open_q" | awk -v id="$id" '$1 == id { … }')"` (`:529`).

**Evidence:** `scripts/dev-cycle.sh:418-419,480,529`

---

## Claim 9: "An item names old answered IDs in its history, so only an open one counts: `questions.sh open` lists every live-file entry whatever its status, so an entry marked ANSWERED but not archived yet (step 1 archives after this digest runs) is left out here too."

**Location:** `scripts/dev-cycle.sh:467-470`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that a held ID must appear in `open_q` and not in the live-file ANSWERED set, and that the skill's step 1 runs `questions.sh archive` after step 0's digest; does not establish archive-file entries, which `open` never lists.
**Legibility-target:** for-orchestrator-synthesis

`[[ "$id" =~ ^Q-[0-9]+$ && "$answered" != *" $id "* ]] || continue` and then `[[ -z "$r" ]] || held+=…` (`:528-530`). Step 1 runs "`questions.sh init` … and then `questions.sh archive` … so answered entries leave the live file" (`skills/dev-cycle/SKILL.md:404-406`). E1's tests at `:1699` and `:1737` cover the behavior (Q-011 and Q-013 marked ANSWERED in the live file read as no hold).

**Evidence:** `scripts/dev-cycle.sh:483-534`, `scripts/questions.sh:575-586`, `skills/dev-cycle/SKILL.md:404-406`, `$S/bats.out`

---

## Claim 10: "An item is its column-0 line and the indented lines under it; a column-0 line that is no item (prose, a ### heading) ends it."

**Location:** `scripts/dev-cycle.sh:470-472`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers item start, continuation and termination in the `items` awk; does not establish blank-line handling, which the comment leaves out: a blank line neither continues nor ends an item, so an indented line after a blank line still joins it.
**Legibility-target:** for-orchestrator-synthesis

```awk
# scripts/dev-cycle.sh:513-516 (excerpt ends :516; the awk program ends :516 — read)
      sec != "" && /^([-*] |[0-9]+\. )/ { flush(); cur = sec; num = ++n[sec]; text = $0; next }
      cur != "" && /^[ ]/ && NF { text = text " " $0; next }
      NF { flush() }
      END { flush() }' docs/roadmap.md)"
```

Tabs become spaces first (`:508`), so a tab-indented line continues too. E1's test at `:1699` shows column-0 prose and a `###` heading ending an item.

**Evidence:** `scripts/dev-cycle.sh:497-516`, `test/scripts/dev-cycle.bats:1699-1735`

---

## Claim 11: "Only the first Now and the first Next heading count, as in section 7."

**Location:** `scripts/dev-cycle.sh:472-473`
**Type:** Behavioral / Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers section 5's `seen_now`/`seen_next` rule against section 7's item-count loop (`:583-586`) and `now_of` (`:631`); does not establish any roadmap in use having two adjacent Now headings.
**Legibility-target:** for-author

Section 5 takes the first of each: `if (!seen_now && (…)) { sec = "Now"; seen_now = 1 }` (`:510`). Section 7's `now_of` stops at the first Now's end (`on && /^## / { on = 0; d = 1 } !d && !on && …`, `:631`). Section 7's count loop tests the heading match before its exit rule (`… { on = 1; next } on && /^## / { exit }`, `:584`), so a second `## Now` directly after the first keeps counting. A probe on `## Now / - a / ## Now / - b` printed `2`, while section 5 lists one item. The two agree on any roadmap whose Now section is not immediately followed by another Now heading.

**Evidence:** `scripts/dev-cycle.sh:509-512,583-586,631`

---

## Claim 12: "Each line prints the verdict before the item's title, the title quoted, so a title cannot stand where step 6 reads the verdict."

**Location:** `scripts/dev-cycle.sh:473-474`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the verdict field always comes before the title; does not establish that the quoting is unambiguous: a `"` inside a title is printed unescaped.
**Legibility-target:** for-orchestrator-synthesis

`echo "- $sec $num · open: $held · \"$title\""` / `echo "- $sec $num · no open entry or watch names it · \"$title\""` (`:532-533`). E1's test at `:1803` asserts that a title shaped like a verdict lands after the verdict: `- Now 2 · open: Q-010 (you: judgment) · "B: open: Q-010 (you: judgment)"`.

**Evidence:** `scripts/dev-cycle.sh:532-533`, `test/scripts/dev-cycle.bats:1803-1815`

---

## Claim 13: "TITLE (its first bold span, else its first 80 characters; one trailing period dropped)"

**Location:** `scripts/dev-cycle.sh:475-476`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the title rule under the system awk (mawk); does not establish the scrub's handling of a split UTF-8 sequence in the printed title.
**Legibility-target:** for-author

```awk
# scripts/dev-cycle.sh:500-502
        if (match(text, /\*\*[^*]+\*\*/)) title = substr(text, RSTART + 2, RLENGTH - 4)
        else { title = text; sub(/^([-*] |[0-9]+\. )/, "", title); title = substr(title, 1, 80); sub(/ +$/, "", title) }
        sub(/\.$/, "", title)
```

`awk` here is `/usr/bin/mawk`, whose `substr` counts bytes (E9: `substr("ééééé",1,3)` returned `é` plus half a character). So the fallback is the first 80 **bytes**, and it can cut a multi-byte character. `scripts/questions.sh:241-249` documents and works around the same behavior. The bold-span and period rules hold (E1, tests `:1622`, `:1699`).

**Evidence:** `scripts/dev-cycle.sh:498-507`, `scripts/questions.sh:241-249`

---

## Claim 14: "joined by \x1f, which the awk first turns to a space wherever the roadmap holds one (a tab is IFS whitespace: an empty field would collapse and shift the rest)"

**Location:** `scripts/dev-cycle.sh:476-478`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the separator, the pre-conversion, and bash's field handling for tab vs 0x1f; does not establish anything for a NUL byte in the roadmap.
**Legibility-target:** for-orchestrator-synthesis

`printf "%s\037%d\037%s\037%s\n", cur, num, title, ids` (`:505`) after `gsub(/[\t\037]/, " ")` (`:508`; it also turns tabs to spaces, which the comment leaves out), read with `while IFS=$'\x1f' read -r sec num title ids` (`:522`). E9: an empty middle field survives with `\x1f` (`[Now][1][][ Q-1]`) and collapses with a tab (`[Now][1][ Q-1][]`). E3b: removing the gsub fails the 0x1f test.

**Evidence:** `scripts/dev-cycle.sh:505,508,522`, `$S/m-tab.out`

---

## Claim 15a: "IDs whose live-file Status is exactly ANSWERED, read as questions.sh's parse_entries reads a well-formed entry …: the Status field of the last **Needs:** line under a "### Q-NNN " heading, the fields split on " · ", compared whole, as `archive` compares it."

**Location:** `scripts/dev-cycle.sh:483-487`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers parity of the `answered` set with `parse_entries` + `cmd_archive` for entries whose heading passes `check`'s grammar; does not establish parity for a heading `check` refuses (e.g. `### Q-012 extra · slug`: the digest takes `$2` = `Q-012`, `parse_entries` takes `Q-012 extra`).
**Legibility-target:** for-orchestrator-synthesis

```awk
# scripts/dev-cycle.sh:491-495
      answered=" $(awk 'function fl() { if (id != "" && st == "ANSWERED") printf "%s ", id; id = ""; st = "" }
        /^### Q-[0-9]+ / { fl(); id = $2; next }
        /^\*\*Needs:\*\*/ && id != "" { l = $0; gsub(/\*\*/, "", l); n = split(l, f, " · ")
          for (i = 1; i <= n; i++) if (f[i] ~ /^Status:/) st = substr(f[i], 9) }
        END { fl() }' docs/working/questions.md) "
```

This mirrors `parse_entries` (`scripts/questions.sh:221-231`: same `gsub`, `split(line, f, " · ")`, `status = substr(f[i], 9)`, later Needs lines overwrite). `cmd_archive` compares `[[ "$status" == "ANSWERED" ]]` (`:465`). Neither strips a CR or trailing space, so both treat `ANSWERED\r` as not answered. The parity is actually wider than the comment claims: it holds for any Needs layout (a later Needs line without a Status field keeps the earlier status in both). E3d: first-wins fails the test at `:1773`.

**Evidence:** `scripts/dev-cycle.sh:489-496`, `scripts/questions.sh:200-256,460-481`, `$S/m-last.out`

---

## Claim 15b: "(one **Needs:** line with all three fields, which `check` requires)"

**Location:** `scripts/dev-cycle.sh:484-485`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what `questions.sh check` refuses about Needs lines; does not change claim 15a (the digest's parity does not depend on this parenthetical).
**Legibility-target:** for-author

`check` validates route, Opened date and Status from `parse_entries`' merged output (`scripts/questions.sh:324-338`) and never counts Needs lines. E6: an entry with two Needs lines passed `check` (exit 0). The precise version: "all three fields valid, which `check` requires". `check` does not require a single Needs line. Same finding as claim 1.

**Evidence:** `scripts/questions.sh:292-372`, `$S/qchk/check.out`

---

## Claim 16: "Section 3's list still carries these entries."

**Location:** `scripts/dev-cycle.sh:487-488`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that `open_q` includes live-file entries of status ANSWERED; does not establish whether section 3 prints them (it prints only non-owner, non-agent routes, `:426-427`).
**Legibility-target:** for-orchestrator-synthesis

`parse_entries "$LIVE"` is passed to the printer unfiltered (`scripts/questions.sh:580`).

**Evidence:** `scripts/questions.sh:580`, `scripts/dev-cycle.sh:418,426-427`

---

## Claim 17: "read -a splits without pathname expansion; each word is checked again against the ID shape the awk extracts."

**Location:** `scripts/dev-cycle.sh:524-528`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `read -ra` not globbing and the regex matching the awk's `/Q-[0-9]+/` extraction; does not establish that any input could put a glob in `ids` in the first place (the awk emits only `Q-` plus digits; see claim 34b).
**Legibility-target:** for-orchestrator-synthesis

`read -ra id_list <<< "$ids"` then `[[ "$id" =~ ^Q-[0-9]+$ && …` (`:526-528`). The `IFS=$'\x1f'` at `:522` is a prefix assignment scoped to that `read`, so `:526` splits on default IFS. E9 under bash: `read -ra` kept `Q-*` and `*` literal while unquoted `for` expanded them.

**Evidence:** `scripts/dev-cycle.sh:504,522-531`

---

## Claim 18: section 3's branches and section 5 under `set -u` (no unbound variable on any path; NOT checked exactly when section 3 did not read the files)

**Location:** `scripts/dev-cycle.sh:385-447,480-536`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers all six section-3 branches (skipped live file, no live file, questions.sh missing, skipped archive, skipped watching, the `qopen` call succeeding or failing) for their `open_ok`/`open_q` effect; does not establish the watching.md-only case's correctness (claim 7).
**Legibility-target:** for-orchestrator-synthesis

`open_ok=0; open_q=""` is set before every branch (`:385`). Only `:403` and `:419` set `open_ok=1`. `answered`, `items`, `held` and `r` are assigned before use (`:489-530`), and an empty `id_list` expands to nothing under bash 5.2 `set -u` (E9). Executed: skipped live file → NOT-checked line (E5). No live file → every item unheld (E1, `:1795`). `qopen` failure from a missing archive → NOT checked (E1, `:1622`, final block). Success → E2. questions.sh missing and a skipped archive or watching file take the same `open_ok=0` path (static).

**Evidence:** `scripts/dev-cycle.sh:385-447,479-536`, `$S/repo-link/out.txt`, `$S/bats.out`

---

## Claim 19: `mig record-6-roadmap-holds record f7f4746bca47b0bd - - 'none: the record's 6. line only gained what moved and each unheld item's hold; every record written before stays valid'`

**Location:** `scripts/lib/migrations.sh:165`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the FP matching the current record source, the record convention being the only one this branch changed, and nothing parsing the `6.` line's content; does not establish how a human reads old records.
**Legibility-target:** for-orchestrator-synthesis

E7: `record f7f4746bca47b0bd` in the worktree, `record cd3e54279e1ed41b` (the previous registry line's FP, `:164`) on main, other conventions unchanged, and `migrations.sh check .` exit 0. The template line went from `6. roadmap: <done>` to `6. roadmap: <done>; moved: …; unheld: …` (`skills/dev-cycle/SKILL.md:862`), a pure extension. `rg` over `scripts hooks test` for a reader of the `6.` line found none (paraphrased — no quote available because the claim covers absence of code: zero matches).

**Evidence:** `scripts/lib/migrations.sh:160-165`, `skills/dev-cycle/SKILL.md:862`

---

## Claim 20: step 0's section map, "5 roadmap (steps 6 and 8)"

**Location:** `skills/dev-cycle/SKILL.md:328`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that steps 6 and 8 read section 5; does not establish that no other step reads it.
**Legibility-target:** for-orchestrator-synthesis

Step 6: "the digest's section 5 lists each Now and Next item …" (`:626`). Step 8: "The holds come from the digest's section 5 list" (`:789-790`).

**Evidence:** `skills/dev-cycle/SKILL.md:326-330,626-643,789-791`

---

## Claim 21: step 0.5: "Step 6's check of roadmap items that no open entry or watch names runs in a light pass too."

**Location:** `skills/dev-cycle/SKILL.md:363-365`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers consistency with the light-pass rule and with step 6's own text; does not establish that section 3's data is fresh in a light pass beyond the digest itself, which always runs section 3.
**Legibility-target:** for-orchestrator-synthesis

"A light pass skips steps 2, 3, 4 and 4b and runs every other step as written" (`:358-359`). Step 6 says "Every iteration, a light pass included, reads that list" (`:627-628`). The digest's section 3 runs whatever the pass type (no pass-type input in `scripts/dev-cycle.sh:384-447`).

**Evidence:** `skills/dev-cycle/SKILL.md:358-365,626-628`, `scripts/dev-cycle.sh:384-447`

---

## Claim 22: step 3: "Every other Now item is checked in step 6, which a light pass runs too."

**Location:** `skills/dev-cycle/SKILL.md:513-515`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that step 6 covers all column-0 Now items the digest lists; does not establish coverage of items in a second Now section (claim 11).
**Legibility-target:** for-orchestrator-synthesis

Section 5 lists every column-0 item of the first Now (`scripts/dev-cycle.sh:510-513`), and step 6 acts on each one shown as unheld (`skills/dev-cycle/SKILL.md:626-629`).

**Evidence:** `skills/dev-cycle/SKILL.md:508-515,626-643`

---

## Claim 23: Ideas takes "parked items, each with the owner answer that parked it and what brings it back"; Done: "an item moved from Now or Next: the commit or answer that finished it"

**Location:** `skills/dev-cycle/SKILL.md:620-625`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers consistency with step 6's move rules; does not establish `--cycle-diff`'s acceptance of each move (research claim 4 cites row 751 for that).
**Legibility-target:** for-orchestrator-synthesis

Step 6: finished "→ Done, with the commit or answer that finished it" and parked "→ Ideas, with that answer's ID as its reason and what brings it back" (`:630-633`).

**Evidence:** `skills/dev-cycle/SKILL.md:620-633`

---

## Claim 24: step 6's "Items no open entry or watch names" bullet: the list's shape, the quoted verdict "no open entry or watch names it", and "When section 5 prints "Now and Next items were NOT checked", no item is moved on its account: the `6.` line says so, with section 3's cause"

**Location:** `skills/dev-cycle/SKILL.md:626-643`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each quoted string against the digest's exact output and the cause being findable in section 3; does not establish the judgment rules (finished/parked/outside hold), which are instructions.
**Legibility-target:** for-orchestrator-synthesis

The digest prints `… · no open entry or watch names it · "$title"` (`scripts/dev-cycle.sh:533`), an exact match. It prints `**Now and Next items were NOT checked against open entries and watches** — section 3 did not read the questions files (see it above).` (`:481`), which contains the skill's quoted prefix. Section 3 prints its own `**Watched questions were NOT checked** — <cause>` on every `open_ok=0` path (`:398-409,443`; E5). "lists each Now and Next item with the open entries and watches it names, then its title" matches the line order at `:532-533`.

**Evidence:** `scripts/dev-cycle.sh:398-446,480-481,532-533`, `$S/repo-link/out.txt`

---

## Claim 25: step 8: "The holds come from the digest's section 5 list and the record's `6.` line, never from the last record's `8.` line"

**Location:** `skills/dev-cycle/SKILL.md:789-791`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that both named sources exist and carry per-item holds; does not establish how this sentence sits with the rule just above, which reads the two latest records' `8.` lines to expire a rides-with hold (`:785-787`). That rule uses old `8.` lines as expiry evidence, not as the hold's source, so the two do not contradict.
**Legibility-target:** for-orchestrator-synthesis

Section 5 lists per-item open holds (`scripts/dev-cycle.sh:532`). The `6.` template carries `unheld: <ITEM: its hold, …>` (`skills/dev-cycle/SKILL.md:862`).

**Evidence:** `skills/dev-cycle/SKILL.md:783-791,862`

---

## Claim 26: the record template's `6.` line, "`6. roadmap: <done>; moved: <ITEM → Done or Ideas (why), … / none>; unheld: <ITEM: its hold, … / none / not checked: why>`"

**Location:** `skills/dev-cycle/SKILL.md:862`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the template has a slot for each `6.` output step 6 asks for (moves, outside holds, the not-checked cause); does not establish any parser for it (none exists, claim 19).
**Legibility-target:** for-orchestrator-synthesis

Step 6 requires "the record's `6.` line names that hold for this item" (`:636-637`) and, on NOT checked, "the `6.` line says so, with section 3's cause" (`:641-642`). Those map to `unheld: ITEM: its hold` and `not checked: why`.

**Evidence:** `skills/dev-cycle/SKILL.md:626-643,862`

---

## Claim 27: test "section 5 lists each Now and Next item with the open entries and watches it names (roadmap staleness, 2026-11-18)"

**Location:** `test/scripts/dev-cycle.bats:1622`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the assertions check per-item open IDs with routes (live entry and watch), unheld items, sub-steps, the exclusion of In flight and Ideas, CRLF, and the not-checked path; does not establish the watching-only case (claim 7).
**Legibility-target:** for-orchestrator-synthesis

Asserts `- Now 2 · open: Q-010 (you: judgment), Q-020 (trigger) · "Held work"`, the absence of `Now 4`, `In flight item` and `An idea`, and the NOT-checked line after `rm docs/working/questions-archive.md`. E1: ok.

**Evidence:** `test/scripts/dev-cycle.bats:1622-1675`, `$S/bats.out`

---

## Claim 28: test "section 5 says when Now and Next hold no items, and prints no list without a roadmap"

**Location:** `test/scripts/dev-cycle.bats:1677`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both named halves; does not establish a skipped (non-plain) roadmap's output.
**Legibility-target:** for-orchestrator-synthesis

Asserts `"No items in Now or Next."`, then after `rm docs/roadmap.md`, `"No docs/roadmap.md yet"` and no `"Now and Next items"`. E1: ok.

**Evidence:** `test/scripts/dev-cycle.bats:1677-1688`, `scripts/dev-cycle.sh:517-518,539-541`

---

## Claim 29: test "section 5 counts an open ID named in an item's indented sub-step as holding the item"

**Location:** `test/scripts/dev-cycle.bats:1690`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a space-indented numbered sub-step; does not establish a sub-step separated from its item by a blank line (claim 10's residue).
**Legibility-target:** for-orchestrator-synthesis

The fixture names Q-010 only in `  1. Step one waits on Q-010.`, and the test asserts `- Now 1 · open: Q-010 (you: judgment) · "Item"` and no `Now 2`. E1: ok.

**Evidence:** `test/scripts/dev-cycle.bats:1690-1697`

---

## Claim 30: test name "…; only the first Now and Next count (review 2026-11-18, claims 11b, 9a, 9b)"

**Location:** `test/scripts/dev-cycle.bats:1699`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers which halves of the name the assertions exercise; does not establish anything beyond this test.
**Legibility-target:** for-author

The fixture has a second `## Now` (`- **A second Now section** (Q-010)`), and the test asserts it is not listed. It has only one `## Next`, so "only the first … Next count[s]" is not exercised. The ANSWERED-not-archived and column-0-prose halves are asserted (`- Now 1 · no open entry …`, `- Now 2 · no open entry …`).

**Evidence:** `test/scripts/dev-cycle.bats:1699-1735`

---

## Claim 31: test "section 5 reads an entry's Status only from its Needs line, exactly, as questions.sh does (… claim 5b)"

**Location:** `test/scripts/dev-cycle.bats:1737`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers body text and a later `##` section quoting `**Status:** ANSWERED`, and a status with a suffix; does not establish CR-terminated status lines.
**Legibility-target:** for-orchestrator-synthesis

Asserts Q-010 (body quotes ANSWERED) and Q-012 (`ANSWERED (2026-11-02)`) still hold, while Q-013 does not. Its comment "Q-012's status is not exactly ANSWERED, so archive would not move it" matches `[[ "$status" == "ANSWERED" ]]` (`scripts/questions.sh:465`). E1: ok.

**Evidence:** `test/scripts/dev-cycle.bats:1737-1771`, `scripts/questions.sh:465`

---

## Claim 32: test "section 5: the last Needs line of an entry wins, as in questions.sh parse_entries (… claim 6b)"

**Location:** `test/scripts/dev-cycle.bats:1773`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both orders (OPEN→ANSWERED and ANSWERED→OPEN); does not establish a last Needs line with no Status field (claim 15a covers that by reading).
**Legibility-target:** for-orchestrator-synthesis

E3d: with first-Status-wins the test fails and prints `- Now 1 · open: Q-001 …` and `- Now 2 · no open entry …`, so the test tells the two orders apart.

**Evidence:** `test/scripts/dev-cycle.bats:1773-1793`, `$S/m-last.out`

---

## Claim 33: test "section 5 lists every item as unheld when the repo has no questions file, never as NOT checked (… api-consistency 1)"

**Location:** `test/scripts/dev-cycle.bats:1795`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the no-questions-file, no-watching-file case; does not establish the case where `watching.md` exists (claim 7).
**Legibility-target:** for-orchestrator-synthesis

E3c: removing `open_ok=1` at `scripts/dev-cycle.sh:403` fails this test.

**Evidence:** `test/scripts/dev-cycle.bats:1795-1801`, `$S/m-nofile.out`

---

## Claim 34a: test name "a 0x1f byte … in the roadmap shifts no field"

**Location:** `test/scripts/dev-cycle.bats:1803`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a 0x1f inside a bold title and between words; does not establish a tab in the same positions (the same gsub handles it, untested).
**Legibility-target:** for-orchestrator-synthesis

Asserts `- Now 1 · no open entry or watch names it · "A B"`. E3b: removing the gsub fails it.

**Evidence:** `test/scripts/dev-cycle.bats:1803-1815`, `$S/m-tab.out`

---

## Claim 34b: test name "a … glob character in the roadmap … expands nothing" and its comment "A tracked file named like an ID: a glob in the IDs field would match it."

**Location:** `test/scripts/dev-cycle.bats:1803,1807`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers whether the test exercises pathname expansion in the IDs field; does not establish any defect in the shipped code, which does not glob (claim 17).
**Legibility-target:** for-author

The fixture's `Q-0* waits` never puts a glob in the IDs field. The awk takes only `/Q-[0-9]+/` matches (`scripts/dev-cycle.sh:504`), so the field holds `Q-0` (probe: `Q-0* waits` → `Q-0`). The lone `*` is never extracted. E3a: replacing `read -ra` and the `^Q-[0-9]+$` check with the old `for id in $ids` still **passes** this test. So the test does not guard the property its name and comment claim, and the comment's premise (a glob reaches the IDs field) does not hold for this fixture or for any roadmap text.

**Evidence:** `test/scripts/dev-cycle.bats:1803-1815`, `scripts/dev-cycle.sh:504,526-528`, `$S/mut-glob.out`

---

## Claim 34c: test name "a verdict-like title stays quoted after the verdict"

**Location:** `test/scripts/dev-cycle.bats:1803`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the line order for a title shaped like `open: Q-NNN (route)`; does not establish a title containing `"`.
**Legibility-target:** for-orchestrator-synthesis

Asserts `- Now 2 · open: Q-010 (you: judgment) · "B: open: Q-010 (you: judgment)"`. The `open:` verdict comes from the Q-010 the title itself names. E1: ok.

**Evidence:** `test/scripts/dev-cycle.bats:1812-1815`

---

## Claim 35: "Size: 389 code lines against main (245 committed + 144 here)."

**Location:** commit `70a69b59` message
**Type:** Configuration
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count under pr-prep step 1a's command, which the `Size:` line convention names (`workflows/review-fix-loop.md:59`); does not establish that the unit is over any cap (313 is under ~400).
**Legibility-target:** for-author

E8: `main...HEAD` = **313**. 245 (`main...HEAD~1`) and 144 (`HEAD~1...HEAD`) are each right, but adding them counts twice the lines pass 3 rewrote, which is not the unit's size against main. Resembles the logged pattern of commit-message counts overclaimed (commits 59ca38f, 37c5ea9).

**Evidence:** `workflows/pr-prep.md:88-92`, `workflows/review-fix-loop.md:59`, E8 (command output in this session)

---

## Claim 36: commit `70a69b59`'s fix bullets: R3 (last Needs line wins), R4 (no questions file → unheld), A6/A7 (0x1f → space; `read -a` and `^Q-[0-9]+$`; verdict then quoted title), A8/A9 (skill handles NOT checked; bold-and-dash shape; one trailing period; Done widened; one wording; step 0.5; `6.` reshaped; FP f7f4746bca47b0bd), C1/C2 (override-log rows)

**Location:** commit `70a69b59` message
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each bullet's change being present at HEAD; does not establish that "parity is claimed for well-formed entries only" is accurately qualified (claim 15b), and "one wording" holds for the skill text, while the code comment at `scripts/dev-cycle.sh:466` still says "every item nothing open holds".
**Legibility-target:** for-orchestrator-synthesis

Each bullet maps to code read above: claims 15a, 7/33, 14, 17, 12, 24, 13, 23, 21, 26, 19. The NOT-checked line copies section 3's `**Watched questions were NOT checked** —` shape (`scripts/dev-cycle.sh:398,481`). The override log gained two rows (`docs/reviews/override-log.md`, diff `+2`). E1 passes.

**Evidence:** `git show 70a69b59 --stat`, `scripts/dev-cycle.sh:398,481`, `docs/reviews/override-log.md`

---

## Claim 37: "compares it exactly, as `archive` does, so the digest drops exactly what step 1 archives."

**Location:** commit `57e8950a` message
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the claim at today's code and at its own commit; does not establish entries with a heading `check` refuses (claim 15a's residue).
**Legibility-target:** for-author

At HEAD it holds for headings `check` accepts (claim 15a). At 57e8950a the awk took the first Needs line while `parse_entries` takes the last (rubric R3), so an OPEN-then-ANSWERED entry differed then. The precise version, in force since 70a69b59: "drops exactly what step 1 archives, for entries `check` accepts".

**Evidence:** `scripts/dev-cycle.sh:491-495`, `docs/reviews/code-review-rubric-2026-11-18-fix-dev-cycle-roadmap-staleness.md:16`

---

## Claim 38: commit `22f9cd8f`'s bullets: R1 (drop live-file ANSWERED IDs), A1 (only indented lines continue an item), A2 (only the first Now and Next headings), A3 (research doc corrected)

**Location:** commit `22f9cd8f` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the behaviors at HEAD; does not re-verdict A2's "as in section 7" (claim 11).
**Legibility-target:** for-orchestrator-synthesis

Claims 9, 10 and the `seen_now`/`seen_next` guard (`scripts/dev-cycle.sh:510-511`) all hold at HEAD, and the test at `:1699` passes (E1).

**Evidence:** `scripts/dev-cycle.sh:491-516`, `test/scripts/dev-cycle.bats:1699`

---

## Claim 39: "their holds (Q-227, Q-234, Q-274) were answered"

**Location:** commit `e50efe75` message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the three IDs' current status; does not establish the "for weeks" duration.
**Legibility-target:** for-orchestrator-synthesis

All three entries carry `**Status:** ANSWERED` in `docs/working/questions-archive.md` (paraphrased — no quote available because the three entries sit far apart in the archive; matched by `rg -A1 "^### Q-NNN "`).

**Evidence:** `docs/working/questions-archive.md`

---

## Claim 40: "The record template's 6. line changed, so migrations.sh gains record-6-roadmap-holds (none: older records stay valid)."

**Location:** commit `b7ebe774` message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the registry line's presence and its FP at HEAD (updated by 70a69b59); does not establish the FP b7ebe774 itself carried.
**Legibility-target:** for-orchestrator-synthesis

See claim 19 (E7).

**Evidence:** `scripts/lib/migrations.sh:165`

---

## Claims Requiring Attention

### Incorrect
- **Claim 1** (`docs/reviews/code-review-rubric-2026-11-18-fix-dev-cycle-roadmap-staleness.md:32`): A10's "which `check` enforces": `check` passes an entry with two Needs lines (E6). It enforces three valid fields, not one Needs line.
- **Claim 15b** (`scripts/dev-cycle.sh:484-485`): "(one **Needs:** line with all three fields, which `check` requires)": same. Say "all three fields valid, which `check` requires".
- **Claim 34b** (`test/scripts/dev-cycle.bats:1803,1807`): the glob half of the test is non-discriminating. The awk never puts a glob in the IDs field (`Q-0*` → `Q-0`), and the old `for id in $ids` passes the test (E3a).
- **Claim 35** (commit `70a69b59`): "389 code lines against main": step 1a's command prints 313. 245 + 144 counts pass 3's rewritten lines twice.

### Stale
- **Claim 2** (`docs/working/plan-2026-11-18-roadmap-staleness.md:14`): the plan's `- Now N · TITLE: …` format is the pre-A7 layout. The digest now prints the verdict, then the title in quotes, under a new header.
- **Claim 6** (`docs/working/research-2026-11-18-roadmap-staleness.md:35`): "`open_ok`, set only when both succeed": it is also set when the repo has no questions file (`scripts/dev-cycle.sh:403`).

### Mostly Accurate
- **Claim 5** (`docs/working/research-2026-11-18-roadmap-staleness.md:33`): "Every item names old answered IDs": every Now item did at 686258b1, but both Next items named none.
- **Claim 7** (`scripts/dev-cycle.sh:403`): "nothing is open": an open watch in an existing `watching.md` is not read when `questions.md` is absent, so an item it holds prints as unheld (E4).
- **Claim 11** (`scripts/dev-cycle.sh:472-473`): "as in section 7": section 7's item count keeps counting through a second `## Now` that directly follows the first. `now_of` and section 5 do not.
- **Claim 13** (`scripts/dev-cycle.sh:475-476`): "first 80 characters" is 80 bytes under mawk and can split a multi-byte character.
- **Claim 30** (`test/scripts/dev-cycle.bats:1699`): "only the first Now and Next count": the fixture has no second Next, so the Next half is not exercised.
- **Claim 37** (commit `57e8950a`): "drops exactly what step 1 archives" was false at its own commit (first Needs line wins, R3). It holds at HEAD for entries `check` accepts.

### Unverifiable
- None.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the path given at the end of this prompt, structured per the code-fact-check skill, with `**Commit:** 70a69b59` in its header.
- Answered: all six focus areas. (1) every section-5 comment (claims 9-17); (2) `open_ok` in every section-3 branch under `set -u` (claims 7, 8, 18); (3) every listed SKILL.md sentence against the digest's exact strings (claims 20-26); (4) the migration FP and its 'none' rationale (claim 19); (5) section-5 test names against their assertions, with mutations (claims 27-34c); (6) commit-message facts and the research and plan docs' [observed] claims (claims 2-6, 35-40). Report saved at `docs/reviews/code-fact-check-report-2026-11-18-roadmap-staleness-final-r1.md`; bats 97/97 pass.
- Out of scope: code quality and whether these corner cases need fixing (sibling critics and rubric); the research doc's untagged "about 109 iterations"; the hallucination-pattern log (no fabrication found, and this pass writes only the report).
- Escalate: none blocking. The four Incorrect verdicts are wording and test-coverage defects, not behavior defects in the shipped digest. The closest to behavior is claim 7's watching.md-without-questions.md case (an open watch reads as no hold), which the orchestrator may want to weigh.
