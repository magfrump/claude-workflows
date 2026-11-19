# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-roadmap-staleness (claude-workflows)
**Scope:** branch `fix/dev-cycle-roadmap-staleness` vs `main`, full branch (`git diff main...HEAD`): `scripts/dev-cycle.sh` sections 3 and 5, `scripts/lib/migrations.sh`, `skills/dev-cycle/SKILL.md`, `test/scripts/dev-cycle.bats` (section 5 tests), `docs/working/research-2026-11-18-roadmap-staleness.md` [observed] claims, and the six commit messages `main..HEAD`. Final confirming pass (r2).
**Commit:** 70a69b59
**Checked:** 2026-11-18
**Total claims checked:** 37
**Summary:** 30 verified, 3 mostly accurate, 1 stale, 3 incorrect, 0 unverifiable

Hallucination log: `docs/reviews/hallucination-patterns.md` read; no claim here matches a logged pattern (no fabricated symbol, option or API was found).

## Execution log

All scratch under `S=/tmp/claude-1000/-workspace/711f86df-792b-492f-9d5e-95022839ec2c/scratchpad/fc-final-r2-2076958`. Tooling: GNU bash 5.2.15, mawk 1.3.4 (the system `awk`), locale C.UTF-8.

- **E1** (2026-11-19T06:38:54Z), cwd the worktree: `timeout 900 bats test/scripts/dev-cycle.bats` → exit 0, 97/97 ok (the eight section-5 tests are 90-97). Output: `$S/bats.out`.
- **E2** (2026-11-19T06:39:39Z), cwd the worktree: `timeout 60 bash scripts/lib/migrations.sh fingerprint .` → exit 0, `record f7f4746bca47b0bd`. Output: `$S/fp.out`. Then `timeout 120 bash scripts/dev-cycle.sh` → exit 0; section 5 prints the Now 1-3 / Next 1-2 list. Output: `$S/digest.out`.
- **E3** (2026-11-19T06:41:11Z), cwd the worktree: `timeout 60 bash scripts/lib/migrations.sh check .` → exit 0. Output: `$S/migcheck.out`. Record template block diffed against `main` (`$S/main-rec.txt` vs `$S/new-rec.txt`): only the `6.` line differs.
- **E4** (2026-11-19T06:39:51Z), cwd `$S/repo1` (fresh git repo, no `docs/working/questions.md`, a `watching.md` holding open watch Q-007, roadmap Now item "**Item A** waits on Q-007." and a no-bold item of 60 `é`): `timeout 120 bash <worktree>/scripts/dev-cycle.sh` → exit 0. Section 3 prints "No docs/working/questions.md in this repo."; section 5 prints `- Now 1 · no open entry or watch names it · "Item A"`. Output: `$S/probe1.out`.
- **E5** (2026-11-19T06:40:40Z), cwd `$S/repo2`: test 97's fixture (open Q-010, tracked file `Q-001`, roadmap with `\037`, `*`, `Q-0*`) run through the pre-fix script (`git show 969e8227:scripts/dev-cycle.sh`, placed beside a copy of the current `scripts/` in `$S/oldlib/`) and the current one; both exit 0. Old: `- Now 1 · A: no open entry or watch names it` (no `Q-001 (`); new: `- Now 1 · no open entry or watch names it · "A B"`. Then a variant (Q-001 made open, item `- x\037* waits on nothing`): old prints `- Now 1 · x: open Q-001 (you: judgment)` (glob expanded), new prints `- Now 1 · no open entry or watch names it · "x * waits on nothing"`. Outputs: `$S/probe2-old.out`, `$S/probe2-new.out`, `$S/probe3-old.out`, `$S/probe3-new.out`.
- **E6** (2026-11-19T06:42:48Z), cwd the worktree: pr-prep step 1a's count, `git diff --numstat main...HEAD -- ':(top)' ':(top,exclude)docs/' | awk '{ n += $1 + $2 } END { print n+0 }'` → 313. Output: `$S/size.out`. Per-range numstat (same pathspecs, by hand): `main...969e8227` = 245, `969e8227..HEAD` = 144.
- **E7** (2026-11-19T06:43:33Z), cwd `$S/repo3`: `questions.sh init`, one entry `Q-001` with two `**Needs:**` lines (ANSWERED, then OPEN), `index`, then `timeout 30 bash <worktree>/scripts/questions.sh check` → exit 0, "structure valid". Output: `$S/check-two-needs.out`.
- **E8** (2026-11-19T06:44:18Z), cwd `$S/repo4`: roadmap Now item `- a` + 60 `é` (no bold), current script → exit 0; the quoted title is 80 bytes and decodes with 1 U+FFFD (a split character). Output: `$S/probe4.out`.

No probe was left running (checked with `ps` before writing).

---

## Claim 1: "`scripts/dev-cycle.sh` section 5 prints only the roadmap's Next section, quoted … Section 7 counts items in Now, In flight and Next and compares Now with the last brainstorm's commit (`now_of`) [observed]"

**Location:** `docs/working/research-2026-11-18-roadmap-staleness.md:10`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers section 5 on `main` (13 lines, the Next quote only) and section 7's `for sec in Now "In flight" Next` count and `now_of` comparison; does not establish anything about section 5 at HEAD, which this branch extends (the doc describes the pre-change state).
**Legibility-target:** for-orchestrator-synthesis

On `main` the section-5 block is 13 lines and holds only the `awk … on && NF { print "> " $0 }` Next quote (paraphrased — no quote available because the claim is about `main`'s block, read with `git show main:scripts/dev-cycle.sh`, whose full text is the one awk line already quoted in the diff context). Section 7 at HEAD: `for sec in Now "In flight" Next; do` (`scripts/dev-cycle.sh:583`) and `now_of() { awk … }` with `if [[ "$(git cat-file blob "$bs_c:docs/roadmap.md" | now_of)" == "$(now_of < docs/roadmap.md)" ]]` (`scripts/dev-cycle.sh:631,637`).

**Evidence:** `scripts/dev-cycle.sh:583,631,637`; `git show main:scripts/dev-cycle.sh` section 5

---

## Claim 2: "Section 3 runs `questions.sh open` … keeping its output in `open_q`: one line per live-file entry of any status, plus each watch not marked ANSWERED, `ID  ROUTE  slug` [observed]"

**Location:** `docs/working/research-2026-11-18-roadmap-staleness.md:11`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers `cmd_open`'s two sources and its print format, and `open_q` holding the first `qopen` call (with watching.md); does not establish what `open_q` holds when section 3 takes a non-`open` branch (it is then the empty string from `:385`).

```bash
# scripts/questions.sh:580-585
{ parse_entries "$LIVE"; parse_entries "$WATCHING" | awk -F'\t' '{ s = $4; sub(/\r$/, "", s) } s != "ANSWERED"'; } \
    | route_rank | sort -t$'\t' -k1,1 -k2,2 | cut -f2- \
    | while IFS=$'\t' read -r id route _ _ slug _; do
        printf '%s  %-16s  %s\n' "$id" "$route" "$slug"
```
(excerpt ends :585; enclosing `cmd_open()` continues to :587 — read). The live file is not filtered by status; watching.md drops only an exact `ANSWERED` (after a CR strip).

**Evidence:** `scripts/questions.sh:575-587`; `scripts/dev-cycle.sh:418`

---

## Claim 3: research "What exists" / "Invariants" [observed] claims on the skill, tests, scrub and gate code

**Location:** `docs/working/research-2026-11-18-roadmap-staleness.md:13-23`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each cited anchor existing as described: step 3's "Read Now's agent work items" on `main`; step 8's "An owner call holds an item only when a questions-file entry asks it"; the tests "a questions.sh failure is reported…" and "section 3 lists watches…" and "prints all eight sections"; `scrub_reexec` at `:102`; `GATE_CODE` covering `scripts/dev-cycle.sh` and `skills/dev-cycle/`; does not establish the release timing ("runs from the next image release"), which is process, not code.

- `git show main:skills/dev-cycle/SKILL.md` line 508: `- Read Now's agent work items.`
- `skills/dev-cycle/SKILL.md:783`: `An owner call holds an item only when a questions-file entry asks it:`
- `test/scripts/dev-cycle.bats:40` `@test "prints all eight sections in a repo with no docs"`, `:428` `@test "a questions.sh failure is reported, never shown as 'None open.'"`, `:682` `@test "section 3 lists watches from watching.md and legacy ones …"`.
- `scripts/dev-cycle.sh:102`: `scrub_reexec "${BASH_SOURCE[0]}" "$@"`.
- `scripts/lib/dev-cycle-read.sh:1037`: `GATE_CODE='^scripts/(build-loop|d6|dev-cycle|questions)\.sh$|^scripts/lib/|^skills/dev-cycle/'`.

**Evidence:** `skills/dev-cycle/SKILL.md:783`; `test/scripts/dev-cycle.bats:40,428,682`; `scripts/dev-cycle.sh:102`; `scripts/lib/dev-cycle-read.sh:1037`

---

## Claim 4: "Every item names old answered IDs in its history ("Unit 1 merged at 236f21ee (Q-224 [1])") … [observed: the roadmap at 686258b1]"

**Location:** `docs/working/research-2026-11-18-roadmap-staleness.md:33`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the quoted text existing in the roadmap at 686258b1; does not establish that literally every item names an answered ID (read as the doc's generalisation).

`git show 686258b1:docs/roadmap.md` line 107: `unit is a \`merge-gate\` entry. Unit 1 merged at 236f21ee (Q-224 [1]); unit 2 merged at 6ee39f24 (Q-229 [1]).`

**Evidence:** `docs/roadmap.md:107` at 686258b1

---

## Claim 5: "section 5 gates on `open_ok`, set only when both succeed, and says the list was not checked instead of reporting every item as unheld [observed: review 2026-11-18, claim 8]"

**Location:** `docs/working/research-2026-11-18-roadmap-staleness.md:35`
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers where `open_ok` is set at HEAD; the first half ("`open_q` may still hold the first `qopen` call's full list") is correct and not what earns the verdict.

Since 70a69b59 (R4) `open_ok` is also set in the no-questions-file branch, and section 5 then reports every item as unheld:

```bash
# scripts/dev-cycle.sh:401-403
elif ! inrepo docs/working/questions.md; then
  echo "No docs/working/questions.md in this repo."
  open_ok=1   # nothing is open: section 5 lists every item as unheld
```
The precise version: `open_ok` is set when both `qopen` calls succeed, or when the repo has no questions file; only the other branches print the not-checked line.

**Evidence:** `scripts/dev-cycle.sh:385,401-403,419`

---

## Claim 6: section 3's `open_ok=0; open_q=""` and every branch's effect on section 5 under `set -u`

**Location:** `scripts/dev-cycle.sh:385`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that `open_ok` and `open_q` are bound before any section-3 branch, that only the no-file branch (`:403`) and the both-calls-succeed branch (`:419`) set `open_ok=1`, and that the variables section 5 reads (`answered`, `items`, `sec num title ids`, `id_list`, `r`, `held`) are all assigned before use on the `open_ok=1` path; does not establish bash < 4.4 behaviour of `"${id_list[@]}"` on an empty array (this host runs 5.2.15).

`scripts/dev-cycle.sh:90` `set -euo pipefail`; `:385` `open_ok=0; open_q=""` right after the section header, before `if skipped docs/working/questions.md`. The skipped (`:399-400`), questions.sh-missing (`:404-405`), archive-skipped and watching-skipped (`:406-409`) and `open`-failed (`:441-445`) branches leave `open_ok=0`, so section 5 prints the NOT-checked line (`:480-481`). On `open_ok=1`, `answered=" "` is set at `:489` before the `-f` test, and `read -ra id_list <<< "$ids"` (`:526`) assigns an empty array for an empty IDS field. E1 runs the no-file (test 96), archive-missing (test 90's last stanza) and success paths with exit 0; E4 runs the no-file path in a fresh repo, exit 0.

**Evidence:** `scripts/dev-cycle.sh:90,385-446,480-536`; E1 `$S/bats.out`; E4 `$S/probe1.out`

---

## Claim 7a: "section 5 lists every item as unheld" (no-questions-file branch)

**Location:** `scripts/dev-cycle.sh:403`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the printed output with no questions file; does not establish that "unheld" is the true state (Claim 7b).

E4 prints `- Now 1 · no open entry or watch names it · "Item A"` and `- Next 1 · no open entry or watch names it · "Item B"`; test 96 (`test/scripts/dev-cycle.bats:1795`) asserts the same and that "NOT checked" is absent; E1 ok.

**Evidence:** `scripts/dev-cycle.sh:403,489-490,532-533`; E1, E4 `$S/probe1.out`

---

## Claim 7b: "nothing is open" (no-questions-file branch)

**Location:** `scripts/dev-cycle.sh:403`
**Type:** Behavioral / Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a repo with no `questions.md` but a `watching.md` holding an open watch; does not establish how often that state occurs (`questions.sh init` creates all three files, and step 1 creates `questions.md` when it is missing).

The branch does not read `docs/working/watching.md` at all; it only echoes and sets the flag (`scripts/dev-cycle.sh:401-403`, quoted in Claim 5). `questions.sh open` could not be used here either: `require_files` refuses a missing live file (`scripts/questions.sh:144-147`: `for file in "$LIVE" "$ARCHIVE"; do [[ -f "$file" ]] || …` then `die "no questions doc here …"`). In E4, `watching.md` holds `### Q-007 · w-slug` / `**Needs:** trigger · … · **Status:** OPEN`, and the roadmap item "**Item A** waits on Q-007." prints `- Now 1 · no open entry or watch names it · "Item A"`. Step 6 (`skills/dev-cycle/SKILL.md:626-640`) acts on exactly that string (moves the item to Done or Ideas, or names a non-questions hold), so a reader of this line is told an open watch holds nothing. What the code does: in this branch nothing is read, so open watches in `watching.md` are not seen; "nothing is open" holds only when `watching.md` is also absent or has no open watch.

**Evidence:** `scripts/dev-cycle.sh:401-403`; `scripts/questions.sh:142-148`; `skills/dev-cycle/SKILL.md:626-640`; E4 `$S/probe1.out`

---

## Claim 8: "Each column-0 item of Now and Next, with the open entries and watches it names (section 3's open_q), so step 6 sees every item nothing open holds."

**Location:** `scripts/dev-cycle.sh:465-466`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the item source (column-0 list lines under the first Now/Next) and the route lookup in `open_q` (`:529`); does not establish the no-questions-file case, where `open_q` is empty and unread watches are missed (Claim 7b).

`sec != "" && /^([-*] |[0-9]+\. )/ { flush(); cur = sec; num = ++n[sec]; text = $0; next }` (`:513`); `r="$(printf '%s\n' "$open_q" | awk -v id="$id" '$1 == id { … print r; exit }')"` (`:529`). E2 on this repo prints `- Now 1 · open: Q-301 (trigger) · "Agent: confine-tests follow-ups"` etc.

**Evidence:** `scripts/dev-cycle.sh:497-534`; E1, E2 `$S/digest.out`

---

## Claim 9: "`questions.sh open` lists every live-file entry whatever its status, so an entry marked ANSWERED but not archived yet (step 1 archives after this digest runs) is left out here too."

**Location:** `scripts/dev-cycle.sh:467-470`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `cmd_open`'s unfiltered live file (Claim 2), the `answered` exclusion at `:528`, and step 1 running `questions.sh archive`; does not establish entries whose Status is ANSWERED with trailing text (left in, as `archive` leaves them; test 94).

`[[ "$id" =~ ^Q-[0-9]+$ && "$answered" != *" $id "* ]] || continue` (`:528`). Step 1: "`questions.sh archive` (it also reindexes) through d6 from WT" (`skills/dev-cycle/SKILL.md`, step 1, line 39 of that section). Test 93 (`test/scripts/dev-cycle.bats:1699`) asserts an ANSWERED live entry prints "no open entry or watch names it"; E1 ok.

**Evidence:** `scripts/dev-cycle.sh:489-495,528`; `scripts/questions.sh:580`; `test/scripts/dev-cycle.bats:1699-1735`; E1

---

## Claim 10: "An item is its column-0 line and the indented lines under it; a column-0 line that is no item (prose, a ### heading) ends it."

**Location:** `scripts/dev-cycle.sh:470-472`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers space- and tab-indented continuation (tabs become spaces first at `:508`), column-0 prose and `###` lines ending an item, and blank lines neither ending nor continuing it; does not establish anything about indented lines that follow a non-item line (they are dropped, as no item is open).

```awk
# scripts/dev-cycle.sh:508,513-515
{ sub(/\r$/, ""); gsub(/[\t\037]/, " "); t = tolower($0) }
sec != "" && /^([-*] |[0-9]+\. )/ { flush(); cur = sec; num = ++n[sec]; text = $0; next }
cur != "" && /^[ ]/ && NF { text = text " " $0; next }
NF { flush() }
```
A `###` line does not match `/^## /` (third byte is `#`), so it reaches `NF { flush() }`. Tests 92 (`:1690`) and 93 (`:1699`) assert both directions; E1 ok.

**Evidence:** `scripts/dev-cycle.sh:497-516`; `test/scripts/dev-cycle.bats:1690-1735`; E1

---

## Claim 11: "Only the first Now and the first Next heading count, as in section 7."

**Location:** `scripts/dev-cycle.sh:472-473`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `seen_now`/`seen_next` guards and section 7's `exit` at the next `## ` heading after the first match, with the same heading rule; does not establish heading forms beyond `## now`, `## now …`, `## now(…`.

`if (!seen_now && (t == "## now" || index(t, "## now ") == 1 || index(t, "## now(") == 1)) { sec = "Now"; seen_now = 1 }` (`:510`); section 7: `t == g || index(t, g " ") == 1 || index(t, g "(") == 1 { on = 1; next } on && /^## / { exit }` (`:584`). Test 93 asserts no "A second Now section"; E1 ok.

**Evidence:** `scripts/dev-cycle.sh:509-512,584`; E1

---

## Claim 12: "Each line prints the verdict before the item's title, the title quoted, so a title cannot stand where step 6 reads the verdict."

**Location:** `scripts/dev-cycle.sh:473-474`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the fixed `- SEC N · VERDICT · "TITLE"` order; does not establish that a title holding `"` cannot look like a quote boundary (it is printed raw inside the quotes).

`echo "- $sec $num · open: $held · \"$title\""` / `echo "- $sec $num · no open entry or watch names it · \"$title\""` (`:532-533`). E5: title "B: open: Q-010 (you: judgment)" prints after the verdict.

**Evidence:** `scripts/dev-cycle.sh:532-533`; E5 `$S/probe2-new.out`

---

## Claim 13a: "One record per item: SECTION, N, TITLE (its first bold span, …; one trailing period dropped), IDS, joined by \x1f"

**Location:** `scripts/dev-cycle.sh:475-476`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the record layout and the bold-span/period rules; does not establish which bold span is taken when the item line has none and a continuation line has one (the search runs over the whole folded `text`).

`if (match(text, /\*\*[^*]+\*\*/)) title = substr(text, RSTART + 2, RLENGTH - 4)` (`:500`), `sub(/\.$/, "", title)` (`:502`), `printf "%s\037%d\037%s\037%s\n", cur, num, title, ids` (`:505`). Test 90 expects `"Ranked one"` from `**Ranked one.**`; E1 ok.

**Evidence:** `scripts/dev-cycle.sh:498-507`; E1

---

## Claim 13b: "else its first 80 characters"

**Location:** `scripts/dev-cycle.sh:475-476`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the no-bold fallback with non-ASCII text under this host's mawk; does not establish gawk behaviour in a UTF-8 locale (where `substr` counts characters).

`title = substr(title, 1, 80)` (`:501`) counts bytes under mawk 1.3.4, the host's `awk`. E8: an item `a` + 60 `é` yields an 80-byte title ending in half a character (1 U+FFFD on decode). Precise version: "its first 80 bytes (which can split a multi-byte character)". ASCII titles are unaffected.

**Evidence:** `scripts/dev-cycle.sh:501`; E8 `$S/probe4.out`

---

## Claim 14: "which the awk first turns to a space wherever the roadmap holds one (a tab is IFS whitespace: an empty field would collapse and shift the rest)"

**Location:** `scripts/dev-cycle.sh:476-478`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `gsub` running before any field is built and `read` keeping empty fields with a non-whitespace IFS; does not establish anything about NUL bytes.

`gsub(/[\t\037]/, " ")` runs on every line (`:508`) before `text` is built; `while IFS=$'\x1f' read -r sec num title ids` (`:522`). E5: the pre-fix script prints `A: no open entry…` (fields shifted); the current one prints `"A B"`.

**Evidence:** `scripts/dev-cycle.sh:508,522`; E5 `$S/probe2-old.out`, `$S/probe2-new.out`

---

## Claim 15: NOT-checked line: "Step 6 reports this; it never reads as every item held."

**Location:** `scripts/dev-cycle.sh:481`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers step 6 having a handler for this exact string; does not establish what the next iteration does if section 3 keeps failing.

Skill: `When section 5 prints "Now and Next items were NOT checked", no item is moved on its account: the \`6.\` line says so, with section 3's cause, and the next iteration checks them.` (`skills/dev-cycle/SKILL.md:641-644`). The quoted phrase is a substring of the printed `**Now and Next items were NOT checked against open entries and watches** —`.

**Evidence:** `scripts/dev-cycle.sh:481`; `skills/dev-cycle/SKILL.md:641-644,862`

---

## Claim 16: "IDs whose live-file Status is exactly ANSWERED, read as questions.sh's parse_entries reads a well-formed entry (one **Needs:** line with all three fields, which `check` requires): the Status field of the last **Needs:** line under a "### Q-NNN " heading, the fields split on " · ", compared whole, as `archive` compares it."

**Location:** `scripts/dev-cycle.sh:483-488`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the last-Needs-wins rule, the " · " split, `substr(f[i], 9)`, exact compare, and what `check` enforces; does not establish parity for an entry lacking Opened or route (where `archive`'s tab-IFS `read` shifts fields, the known A10 limit).

The mechanism matches `parse_entries`:

```awk
# scripts/dev-cycle.sh:491-495
function fl() { if (id != "" && st == "ANSWERED") printf "%s ", id; id = ""; st = "" }
/^### Q-[0-9]+ / { fl(); id = $2; next }
/^\*\*Needs:\*\*/ && id != "" { l = $0; gsub(/\*\*/, "", l); n = split(l, f, " · ")
  for (i = 1; i <= n; i++) if (f[i] ~ /^Status:/) st = substr(f[i], 9) }
```
against `n = split(line, f, " · ") … if (f[i] ~ /^Status:/) { status = substr(f[i], 9) }` (`scripts/questions.sh:225-229`) and `[[ "$status" == "ANSWERED" ]] || continue` (`scripts/questions.sh:465`). The imprecise part is the parenthetical: `check` requires valid route, Opened and Status (`scripts/questions.sh:330-338`) and the heading grammar (`:318`), but not one Needs line. E7: an entry with two Needs lines passes `check` (exit 0). Parity also holds for such entries (both take the last line's Status; test 95), so the qualifier is narrower than the truth, not wrong in direction. Precise version: "(all three fields present, which `check` requires)".

**Evidence:** `scripts/dev-cycle.sh:483-496`; `scripts/questions.sh:200-240,318,330-338,460-481`; E1 test 95; E7 `$S/check-two-needs.out`

---

## Claim 17: "read -a splits without pathname expansion; each word is checked again against the ID shape the awk extracts."

**Location:** `scripts/dev-cycle.sh:524-525`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `read -ra` not globbing and the `^Q-[0-9]+$` check at `:528`; does not establish that IDS can ever hold a glob character at HEAD (the awk emits only `Q-[0-9]+` words once `\037` is replaced, so this is a second guard).

`read -ra id_list <<< "$ids"` (`:526`); `[[ "$id" =~ ^Q-[0-9]+$ && … ]] || continue` (`:528`). E5 variant: the pre-fix `for id in $ids` turns a `*` that reached IDS into the tracked file `Q-001` and prints `open Q-001 (you: judgment)`; the current script prints no hold.

**Evidence:** `scripts/dev-cycle.sh:522-531`; E5 `$S/probe3-old.out`, `$S/probe3-new.out`

---

## Claim 18: `mig record-6-roadmap-holds record f7f4746bca47b0bd - - 'none: the record's 6. line only gained what moved and each unheld item's hold; every record written before stays valid'`

**Location:** `scripts/lib/migrations.sh:165`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the fingerprint matching the record template at HEAD, `check` passing, the template diff being the `6.` line alone, and no script parsing a record's `6.` line; does not establish that no human-run convention reads old `6.` lines.

E2: `record f7f4746bca47b0bd`; E3: `migrations.sh check .` exit 0, and the record block (`conv_source`, `scripts/lib/migrations.sh:95-98`) differs from `main` only in `6. roadmap: <done>` → `6. roadmap: <done>; moved: <…>; unheld: <…>`. No script reads the line (paraphrased — no quote available because the claim covers absence of code: `grep -rn '6\. roadmap' scripts/ hooks/ test/` hits only `migrations.sh:165`).

**Evidence:** `scripts/lib/migrations.sh:95-98,165`; `skills/dev-cycle/SKILL.md:862`; E2 `$S/fp.out`; E3 `$S/migcheck.out`

---

## Claim 19: step 0's section map: "5 roadmap (steps 6 and 8)"

**Location:** `skills/dev-cycle/SKILL.md:328`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers steps 6 and 8 each naming section 5; does not establish the rest of the map.

Step 6: `the digest's section 5 lists each Now and Next item` (`:626-627`); step 8: `The holds come from the digest's section 5 list` (`:793-794`).

**Evidence:** `skills/dev-cycle/SKILL.md:328,626-627,793-794`

---

## Claim 20: step 0.5: "a stale agent item in step 3 … waits for the day's first iteration … Step 6's check of roadmap items that no open entry or watch names runs in a light pass too."

**Location:** `skills/dev-cycle/SKILL.md:363-365`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the light pass skipping steps 2, 3, 4, 4b and running every other step, step 6 included; does not establish how a light pass is detected.

`A light pass skips steps 2, 3, 4 and 4b and runs every other step as written` (`:357-358`). The step-6 wording matches the digest's `no open entry or watch names it` (`scripts/dev-cycle.sh:533`).

**Evidence:** `skills/dev-cycle/SKILL.md:357-365`

---

## Claim 21: step 3: "Every other Now item is checked in step 6, which a light pass runs too."

**Location:** `skills/dev-cycle/SKILL.md:514-515`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers step 6's bullet acting on Now items and the light-pass rule; does not establish that a Now agent item step 3 already handled is excluded from step 6's list (the digest lists every item; step 6's bullet is what decides).

Step 6: `Every iteration, a light pass included, reads that list and acts on each item …` (`:627-629`).

**Evidence:** `skills/dev-cycle/SKILL.md:508-515,626-644`

---

## Claim 22: Ideas and Done definitions ("parked items, each with the owner answer that parked it and what brings it back"; "an item moved from Now or Next: the commit or answer that finished it")

**Location:** `skills/dev-cycle/SKILL.md:620-625`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with step 6's move rules; does not establish what `--cycle-diff` checks on these sections.

Step 6: `→ Done, with the commit or answer that finished it;` and `→ Ideas, with that answer's ID as its reason and what brings it back;` (`:631-634`).

**Evidence:** `skills/dev-cycle/SKILL.md:620-634`

---

## Claim 23: step 6's "Items no open entry or watch names" bullet and its NOT-checked handling, against the digest's strings

**Location:** `skills/dev-cycle/SKILL.md:626-644`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each quoted digest string existing verbatim in the output ("no open entry or watch names it", "Now and Next items were NOT checked", the header "each with the open entries and watches it names, then its title"); does not establish the no-questions-file + open-watch case (Claim 7b), where the string is printed for an item a watch holds.

Digest: `echo "Now and Next items, each with the open entries and watches it names, then its title (step 6 moves or explains every item none names):"` (`scripts/dev-cycle.sh:520`), `… · no open entry or watch names it · …` (`:533`), and the NOT-checked line (`:481`). E2 shows the header and lines in this repo's digest.

**Evidence:** `skills/dev-cycle/SKILL.md:626-644`; `scripts/dev-cycle.sh:481,520,532-533`; E2 `$S/digest.out`

---

## Claim 24: step 8: "The holds come from the digest's section 5 list and the record's `6.` line, never from the last record's `8.` line"

**Location:** `skills/dev-cycle/SKILL.md:793-795`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers both named sources existing (section 5's list; the `6.` line's `unheld:` field); does not establish its interplay with the expiry rule two sentences earlier, which reads the two latest records' `8.` lines for another purpose (a ride-along hold expiring).

Template: `unheld: <ITEM: its hold, … / none / not checked: why>` (`:862`).

**Evidence:** `skills/dev-cycle/SKILL.md:783-795,862`

---

## Claim 25: record template `6. roadmap: <done>; moved: <ITEM → Done or Ideas (why), … / none>; unheld: <ITEM: its hold, … / none / not checked: why>`

**Location:** `skills/dev-cycle/SKILL.md:862`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with step 6 (moves, holds named on the `6.` line, the not-checked case); does not establish any parser of the line (none exists, Claim 18).

Step 6: `the record's \`6.\` line names that hold for this item` (`:636-637`) and `the \`6.\` line says so, with section 3's cause` (`:643`).

**Evidence:** `skills/dev-cycle/SKILL.md:636-644,862`

---

## Claim 26: section-5 test names and comments, tests 90-96

**Location:** `test/scripts/dev-cycle.bats:1622-1801`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each name's property being asserted by its test (item listing with routes, CRLF, archive-missing → NOT checked; no items / no roadmap; sub-step ID; ANSWERED-unarchived, column-0 prose, first-heading-only; Needs-line-only exact Status; last Needs wins; no questions file → unheld); does not establish that test 90's sub-step comment "(its IDs count there)" is discriminated in test 90 itself (its sub-step names only the archived Q-001; test 92 discriminates it).

E1: tests 90-96 ok. For example, test 95 (`:1773`) asserts `'- Now 1 · no open entry or watch names it · "A"'` for OPEN-then-ANSWERED and `'- Now 2 · open: Q-002 (you: judgment) · "B"'` for ANSWERED-then-OPEN.

**Evidence:** `test/scripts/dev-cycle.bats:1622-1801`; E1 `$S/bats.out`

---

## Claim 27a: test 97 name: "a 0x1f byte … in the roadmap shifts no field; a verdict-like title stays quoted after the verdict"

**Location:** `test/scripts/dev-cycle.bats:1803`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `"A B"` and `"B: open: Q-010 (you: judgment)"` assertions failing on the pre-fix script and passing now; does not cover the glob half (Claim 27b).

E5: pre-fix output `- Now 1 · A: no open entry…` would fail `*'- Now 1 · no open entry or watch names it · "A B"'*`.

**Evidence:** `test/scripts/dev-cycle.bats:1803-1815`; E5

---

## Claim 27b: test 97 name: "a … glob character in the roadmap … expands nothing"

**Location:** `test/scripts/dev-cycle.bats:1803`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers whether the glob assertion can fail on the regression it names; the property itself holds at HEAD (Claim 17).

The assertion is `"$section" != *"Q-001 ("*` (`:1813`), but the fixture's tracked `Q-001` is not an open entry, so no route is found for it and `Q-001 (` cannot print even if the glob expands; also the fixture's `*` never reaches IDS under the pre-fix code. E5: the pre-fix script prints no `Q-001 (` on this fixture. Only the E5 variant (Q-001 open, the `*` in a no-bold title next to `\037`) shows the expansion. Precise version: the test checks the glob case only when `Q-001` is open and the `*` reaches the IDS field; today it guards the 0x1f and title halves only.

**Evidence:** `test/scripts/dev-cycle.bats:1803-1815`; E5 `$S/probe2-old.out`, `$S/probe3-old.out`

---

## Claim 28: commit 70a69b59: "Size: 389 code lines against main (245 committed + 144 here)."

**Location:** commit `70a69b59` message body
**Type:** Configuration
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count under the command `review-fix-loop.md` names for `Size: <count> code lines against <BASE>`; does not change any gate outcome (both figures are under the ~800 limit).

pr-prep step 1a's command against `main` prints 313 (E6). 389 is the churn of `main...969e8227` (245) plus `969e8227..HEAD` (144), which counts lines changed twice; it is not a count against `main`. `workflows/review-fix-loop.md:59`: "Note each count in the body of the commit that follows it (`Size: <count> code lines against <BASE>`)". The error overstates, the safe direction.

**Evidence:** `workflows/pr-prep.md:88-92`; `workflows/review-fix-loop.md:59`; E6 `$S/size.out`

---

## Claim 29: commit 70a69b59's fix descriptions (R3, R4, A6/A7, A8/A9, the new fingerprint, C1/C2)

**Location:** commit `70a69b59` message body
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed change existing at HEAD (last Needs wins; no-file → unheld; 0x1f → space; `read -a` + `^Q-[0-9]+$`; verdict then quoted title; step 6 NOT-checked handling; one trailing period dropped; Done widened; step 0.5 sentence; `6.` line `moved:`/`unheld:`; fingerprint f7f4746bca47b0bd; two override-log rows); does not endorse R4's "nothing is open" premise (Claim 7b) or the size line (Claim 28).

`docs/reviews/override-log.md:908-909` hold both Won't-Fix rows; other items at Claims 13a, 14, 16, 17, 18, 20, 22, 23, 25.

**Evidence:** `scripts/dev-cycle.sh:403,491-533`; `scripts/lib/migrations.sh:165`; `docs/reviews/override-log.md:908-909`; E1, E2

---

## Claim 30a: commit 57e8950a: "split on " · " as questions.sh's parse_entries splits it, and compares it exactly, as `archive` does, so the digest drops exactly what step 1 archives."

**Location:** commit `57e8950a` message body
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the claim as of its own commit; superseded at HEAD by 70a69b59 (R3), so nothing in today's code is wrong on its account.

At 57e8950a the awk kept the first Needs line's Status, while `parse_entries` keeps the last, so an OPEN-then-ANSWERED entry differed (pass-3 claim 6b; rubric R3: "commit 57e8950a overstated the parity"). Paraphrased — no quote available because the earlier awk is in `git show 57e8950a:scripts/dev-cycle.sh` and was replaced; the pass-3 report's E1 reproduces it.

**Evidence:** `docs/reviews/code-fact-check-report-2026-11-18-roadmap-staleness-pass3.md:17`; `docs/reviews/code-review-rubric-2026-11-18-fix-dev-cycle-roadmap-staleness.md` row R3

---

## Claim 30b: commit 57e8950a: "no questions file in this repo triggered it."

**Location:** commit `57e8950a` message body
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the repo's `docs/working/questions.md` at 57e8950a; does not cover other repos.

`git show 57e8950a:docs/working/questions.md` holds 3 entries and no line matching `Status:\*\* ANSWERED` (paraphrased — no quote available because the claim covers absence: the grep returned no lines).

**Evidence:** `docs/working/questions.md` at 57e8950a

---

## Claim 31: commit 22f9cd8f's fix descriptions (R1, A1, A2, A3)

**Location:** commit `22f9cd8f` message body
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each described behaviour being present at HEAD and tested (tests 93); does not re-verify their state at 22f9cd8f alone.

See Claims 9, 10, 11; research doc lines 11 and 35 were edited (line 35 later went stale, Claim 5).

**Evidence:** `scripts/dev-cycle.sh:489-516`; `test/scripts/dev-cycle.bats:1699`; E1

---

## Claim 32: commit b7ebe774: step 6 rules, step 3 pointer, step 0 map, Ideas, step 8, `record-6-roadmap-holds` ("none: older records stay valid"); "no change to --cycle-diff"

**Location:** commit `b7ebe774` message body
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each named skill edit existing at HEAD and the branch diff touching no `--cycle-diff` code (`scripts/lib/dev-cycle-read.sh` is unchanged on the branch; `dev-cycle.sh` changes only sections 3 and 5); does not re-verify the fingerprint at b7ebe774 (replaced by 70a69b59).

`git diff main...HEAD --stat` lists only `scripts/dev-cycle.sh`, `scripts/lib/migrations.sh`, `skills/dev-cycle/SKILL.md`, `test/scripts/dev-cycle.bats` outside `docs/`.

**Evidence:** `skills/dev-cycle/SKILL.md:328,514-515,620-644,793-795`; `scripts/lib/migrations.sh:165`

---

## Claim 33: commit e50efe75: motive "two finished Now items … and one parked one stayed in Now … their holds (Q-227, Q-234, Q-274) were answered"; "only an open one counts"

**Location:** commit `e50efe75` message body
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the three IDs being ANSWERED in the archive; the line format it describes (`title: …`) is that commit's, superseded by 70a69b59's verdict-first format; does not establish how long the items sat.

`docs/working/questions-archive.md:5589` (Q-227), `:5421` (Q-234), `:6448` (Q-274) each read `… · **Status:** ANSWERED`.

**Evidence:** `docs/working/questions-archive.md:5420-5421,5588-5589,6447-6448`

---

## Claims Requiring Attention

### Incorrect
- **Claim 7b** (`scripts/dev-cycle.sh:403`): "nothing is open" is false when `watching.md` holds open watches but `questions.md` is absent. The branch reads no watches, and section 5 prints "no open entry or watch names it" for a watched item (E4). Either read `watching.md` there, or have the comment and output say the watches were not read.
- **Claim 28** (commit 70a69b59): "389 code lines against main" is wrong. Step 1a's count against main is 313; 389 is two diffs' churn added together.
- **Claim 30a** (commit 57e8950a): "compares it exactly, as archive does, so the digest drops exactly what step 1 archives" was false at that commit (the awk took the first Needs line). It is already recorded as R3 and fixed in 70a69b59; nothing needs to change at HEAD.

### Stale
- **Claim 5** (`docs/working/research-2026-11-18-roadmap-staleness.md:35`): "`open_ok`, set only when both succeed … instead of reporting every item as unheld" is out of date. Since R4, `open_ok` is also set when there is no questions file, and every item is then reported as unheld.

### Mostly Accurate
- **Claim 13b** (`scripts/dev-cycle.sh:476`): "first 80 characters" is really 80 bytes under mawk, and the cut can split a multi-byte character (E8).
- **Claim 16** (`scripts/dev-cycle.sh:484-485`): "one **Needs:** line …, which `check` requires" is not accurate. `check` accepts two Needs lines (E7). The parity still holds for those entries, so the clause should read "all three fields present".
- **Claim 27b** (`test/scripts/dev-cycle.bats:1803`): the "glob character … expands nothing" half of the name is not discriminated by its assertion. The fixture's `Q-001` is not open, and the `*` never reaches IDS, so the pre-fix code also passes that part (E5).

### Unverifiable
- (none)

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the path given at the end of this prompt, structured per the code-fact-check skill, with `**Commit:** 70a69b59` in its header.
- Answered: all six claim groups in the brief. (1) every section-5 comment: Claims 8-17. (2) `open_ok` and the `set -u` branches: Claims 6, 7a, 7b. (3) the skill's steps 0, 0.5, 3, 6, the Ideas and Done definitions, step 8 and the template: Claims 19-25. (4) the migration fingerprint and its 'none' rationale: Claim 18. (5) the test names: Claims 26, 27a, 27b. (6) the commit messages and the research doc's [observed] claims: Claims 1-5 and 28-33. The full bats suite ran: 97/97 ok.
- Out of scope: the plan doc has no [observed] tags, so it was not verdicted. Its step 1 output format (`- Now N · TITLE: open …`) predates the verdict-first format. Code quality and design are also out of scope, including whether a missing `questions.md` beside an existing `watching.md` deserves handling, beyond stating what the code does.
- Escalate: Claim 7b is a correctness gap on the exact path R4 added. In a repo with a `watching.md` but no `questions.md`, step 6 could move or park an item that an open watch still holds. The state is uncommon (`questions.sh init` and step 1 create `questions.md`), so the orchestrator should decide whether it blocks the merge.
