Commit: 38578a9 (A) / c345865 (B)

# Security Review — dev-cycle pass 29 (the pass-28 fix round)

**Scope:** Partial. A: `git diff 366efd7..38578a9 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` (worktree `/workspace/.claude/wt-digest`). B: `git diff b73069e..c345865 -- skills/dev-cycle/SKILL.md` (worktree `/workspace/.claude/wt-devcycle`). Merge 5a50016 carries 38578a9's script and bats blobs (`2b4c8e2`, `aa8fc81`) and c345865's SKILL.md (`6da1506`), checked with `git rev-parse`. Everything else is context only.
**Date:** 2026-10-02
**Based on:** shared brief `digest-pass29-brief-dc1aa358.md`; Stage-1 context `docs/reviews/code-fact-check-report-digest-pass28.md` (it covers 366efd7, so every unit cited below was re-read whole at 38578a9: FENCE_AWK `:254-277`, check_brief `:278-311`, ANSWER_AWK and check_answer `:352-443`); the pass-28 security report, whose probes were rerun; `scripts/questions.sh` (unchanged, `df58181` in all three commits) read as context for the whole-file trade.
**Replication:** k=1 (loop pass)

**Probe discipline.** Each probe was one script that started with `set -eu`, made its own `mktemp -d -p sec29/` directory in that same script, and checked `case "$PWD"` before any `git init`, commit, write or `rm`. Each sub-case got its own `mktemp -d` under that directory. Code came from `git show <commit>:<path>` or `git archive <commit> | tar -x` into the temp dir. Every process ran under `timeout` in the foreground, and all of them exited. `GIT_CONFIG_GLOBAL=/dev/null`. Apart from this report, nothing was written to `/workspace` or either worktree. Afterwards `/workspace` was on `main`. `wt-devcycle` was clean. `wt-digest` showed only other critics' untracked pass-29 reports. The bats processes in `pgrep` are another session's suite in `wt-devcycle/test/`. I did not start or stop them. The system awk is mawk 1.3.4 20200120.

Scratch: `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/sec29/` (`sec29/` below):
- `probe1.sh`/`.log`: bats (`bats.log`), lint (`lint.log`), shellcheck, `--help`, and every real ID at 366efd7 vs 38578a9. The ID sources were B 5a50016 and c345865, A 38578a9 and `/workspace` main. It also checked fence balance in the real files.
- `probe2.sh`/`.log`: pass-28 security and fact-check shapes, plus new candidates N1–N9 and H1–H7. Each case ran isolated, as `--check-answer` and `--check-brief`.
- `probe3.sh`/`.log`: cross-entry parity (P1, P2) and `questions.sh archive` on a fenced heading (P3).
- `probe4.sh`/`.log`: fenced `#`/`##`/`###` comment lines, and mawk `split` on ` · ` in the C locale.

Legibility-target values: **agent** (the model running the dev-cycle skill acts on the output); **user** (the human who answers questions and reads the roadmap or record); **maintainer** (someone editing the script, tests or skill).

---

## Trust Boundary Map

```
B1 (moved): questions files (recorded answers + any session's text; questions.sh rewrites them) → --check-answer awk (FENCE_AWK over the WHOLE file; fenced headings are quotes; " · "-field ANSWERED gate) → keep/drop/done/open/unrecognized/skip → brief Kept:/Applied:/close (SKILL:285-299)
B2: brief blob on the default branch (briefs/ or briefs/closed/) → --check-brief awk (FENCE_AWK with the new lead()) → open/done/dropped + commit → Done / Ideas / git mv (SKILL:273-284)
B3: brief branch tip (committer date) → --check-branch → idle iff count 0, > 14 days old, or > 2 days in the future (SKILL:300-312)
B4 (moved): roadmap In flight lines + briefs glob → membership (glob-listed or cycle-written, any state; plus closed/ lines) → checks 1-3; closed/ open|new → record + final message (SKILL:84-95, :269-312, :369-374)
```

| Label | Source | Mutability | Trust classification |
|---|---|---|---|
| S1 | questions-file content (working tree), including what `questions.sh archive` moves between the two files | runtime-mutable (user, any session, the cycle, questions.sh) | UNTRUSTED toward the keep/drop/done decision. Only the target entry's own recorded answer, once its header is ANSWERED, should decide |
| S2 | brief blob and its history on the default branch | runtime-mutable (any merge) | UNTRUSTED toward Done/dropped. Accepted by design as a self-report reviewed at merge |
| S3 | brief branch tip commit date | runtime-mutable (any committer) | UNTRUSTED toward the idle decision. Its only effect is to ask the user |
| S4 | path named in repo text (In flight line, closed/ target) | per cycle | UNTRUSTED toward write sinks (`--check-write`, `git mv`) |
| S5 | `FENCE_AWK`/`ANSWER_AWK` program text, ID regex | code-constant | trusted |

Untrusted text still reaches decision sinks only through S1 and S2. This round makes fence state file-wide and puts quoted headings into `dup`/`fenced` skips. That closes pass-28 F1 for its own shapes. It also widens `lead()` to any indentation and a list marker, which closes pass-28 F2. It applies the same `lead()` to closers, though, and that opens a new divergence class (F1 below). A divergence early in the file now carries to the end of the file (F2). The repo's own `questions.sh archive` can make a file unbalanced (F3).

## Findings

#### F1. `lead()` is applied to closers too: a list-marker line or a line indented 4+ spaces inside a fence closes it, and an indented-code line opens one. Quoted answers and statuses are exposed (wrong `drop`/`keep`/`done`)

**Severity:** Low (same class as pass-28 F1/F2: a quoted line decides; whoever wrote the quote could write the decisive line directly)
**Location:** `scripts/dev-cycle.sh:254-277` (FENCE_AWK; used at `:295-300` for briefs and `:397-398` for answers)
**Boundary:** B1, B2
**Move:** 11 (bypass enumeration)
**Confidence:** High for the code's readings (executed). Medium-High for the CommonMark column, which comes from the spec. No reference parser is installed: a closing fence takes at most 3 spaces of indentation and no list marker, and 4+ spaces outside a list is an indented code block. Preconditions: the target entry or brief holds one of these lines in a position where the quote is not balanced by its own pair. None occurs in the real files (`probe1.log`: 0 indented or list-marker fence-shaped lines in any of the 8 files).
**Legibility-target:** maintainer

**Evidence (verbatim):**
```awk
# scripts/dev-cycle.sh:260-264, :273-276 (FENCE_AWK :259-277, read whole)
function lead(l) {
  sub(/^[ \t]+/, "", l)
  if (l ~ /^[-*+][ \t]/ || l ~ /^[0123456789]+[.)][ \t]/) { sub(/^[^ \t]+[ \t]+/, "", l) }
  return l
}
...
function closes(l,   s, n) {
  s = lead(l); n = run(s, fch)
  return n >= flen && substr(s, n + 1) ~ /^[ \t]*$/
}
```
The comment at `:254-257` says the indentation and list-marker allowance applies "before an opener" ("a line of 3 or more ` or ~ opens one (after any indentation and an optional list marker …)"). The code applies it to closers as well.

| Case (`probe2.log`, isolated) | 366efd7 | 38578a9 | CommonMark |
|---|---|---|---|
| N1 ```` ``` ```` / ```` - ``` ```` / `**Answer:** [2] drop` / ```` ``` ```` / `**Answer:** [1] keep` | keep | **drop** | keep |
| N1b ```` ```markdown ```` / ```` 1. ``` ```` / `[2]` / ```` ``` ```` / `[1]` | keep | **drop** | keep |
| N2 ```` ``` ```` / 8 spaces + ```` ``` ```` / `[2]` / ```` ``` ```` / `[1]` | keep | **drop** | keep |
| N3 ```` - - ``` ```` / `    x` / 4 spaces + ```` ``` ```` / ```` ``` ```` / `[2]` / ```` ``` ```` / `[1]` / ```` ``` ```` (nested list) | unrecognized | **drop** | keep |
| fc Q-031 / Q-032: 4-space or tab ```` ``` ```` lines around `[2]`, then `[1]` | drop / drop | **keep / keep** | drop / drop |
| brief N1 ```` ``` ```` / ```` - ``` ```` / `Status: done` / ```` ``` ```` / `Status: open` | open | **done** | open |
| brief N2 (4-space line inside the fence) / brief N3 (nested list) | open / open | **done / done** | open / open |
| brief N4: 4-space ```` ``` ```` lines around `Status: done`, then `Status: open` | done | open | done |
| s28 Q-013, Q-017, N4 (indented-code ```` ``` ```` line, then a real `[1]`) | keep ×3 | unrecognized ×3 | keep (loss, fail-closed) |
| s28 Q-014 (4-space line inside the fence before `[1]`) | keep | unrecognized | keep (loss) |

N1, N1b and N2 regress against 366efd7, and so do the briefs N1/N2 and Q-031/Q-032. The brief asked that every result be the CommonMark reading or a skip/unrecognized, "never a wrong keep/drop/done". These rows break that. Brief N1–N3 can send a brief to Done on a quoted `Status: done`. In CommonMark a top-level fence's closer can never carry a list marker or 4+ spaces, so the closer-side widening buys nothing for top-level fences. For a list-item fence, the closer's allowed indentation depends on the opener's content column.

**Recommendation:** Give `closes()` its own prefix rule: no list marker, and indentation at most the opener's content column + 3. Record the column in `opens()` next to `fch`/`flen`. In `opens()`, strip list markers repeatedly (N3). Do not treat 4+ spaces without a marker as a fence, or else make such a line end the read as `unrecognized`/skip. Add N1, N2, N3 and Q-031 as bats cases, and reword `:254-257`.

#### F2. One reader-only fence line anywhere before an entry inverts the parity for the rest of the file, and the pass-28 F1 forged-entry read returns (`done` for a lost ID); the `:358-360` guarantee does not hold

**Severity:** Low
**Location:** `scripts/dev-cycle.sh:397-399`, `:422-426`; comment `:356-360`
**Boundary:** B1
**Move:** 3 (error path), 11
**Confidence:** High (executed). Preconditions: an `Asked:` ID with no real entry (lost or never written), a quoted copy of that entry in a plain ```` ``` ```` fence, and, earlier in the file, any line where FENCE_AWK and CommonMark disagree (F1's shapes, a blockquote fence, and so on).
**Legibility-target:** maintainer

**Evidence (verbatim):** the comment says "A fence left open hides the rest of the file, which can only make an answer unreadable (skip or unrecognized), never read one from elsewhere." The rules involved:
```awk
# scripts/dev-cycle.sh:397-399 (ANSWER_AWK :376-426, read whole)
infence { if (heading($0)) quoted++; if ($0 ~ /^### /) inside = 0; if (closes($0)) infence = 0; next }
opens($0) { infence = 1; next }
heading($0) { count++; inside = (count == 1); header = 0; next }
```
`probe3.log`:
- **P1.** Q-002 holds ```` ``` ```` / ```` - ``` ```` / ```` ``` ```` (CommonMark: one balanced block). Q-009 quotes `### Q-018` with an ANSWERED header and `**Answer:** [3]` in a plain fence. Q-010 is a real answered entry. 366efd7: `open Q-009; unrecognized Q-018; keep Q-010`. 38578a9: `skip Q-009 … only inside a code fence; done Q-018; skip Q-010 … only inside a code fence`.
- **P2.** The same, with a single 4-space ```` ``` ```` line in Q-002 (CommonMark: indented code). The result is the same: `done Q-018`.

After the inversion, the reader sees a real heading as fenced and a quoted heading as real. Real entries fail closed (skip), but a quoted copy of a lost ID is read as an entry. Each case ends with a fence still open at EOF. END never checks that.

**Recommendation:** In END, when `infence` is still set, print a skip ("a code fence is left open in $f") instead of any reading. A parity error almost always leaves the file inside a fence, so this catches P1, P2 and F3's archive split for one line. Then reword `:358-360` to match.

#### F3. `questions.sh archive` produces the unbalanced fence that the whole-file trade assumes away. It splits an entry at a fenced `### Q-NNN ` heading, the live file's later entries become skips, and the archive turns the quote into a real entry

**Severity:** Low (availability of the whole answer channel, visible as skip lines; the decisive read needs a lost ID)
**Location:** `scripts/questions.sh:161-168`, `:220-231`, `:362-372` (context, unchanged); consequence at `scripts/dev-cycle.sh:397`, `:422-426`
**Boundary:** B1 (S1 rewritten by the repo's own tool)
**Move:** 3, 4 (the check happens before the tool's later rewrite)
**Confidence:** High (executed). Precondition: a live entry quotes an entry's heading and its ANSWERED header line in a fence, and then `questions.sh archive` runs. That is the honest "here is how it was recorded" quote.
**Legibility-target:** maintainer, user

**Evidence (verbatim):** none of the three awk programs in questions.sh tracks fences. Example: `/^### Q-[0-9]+ / { … inside = (parts[1] == want) }` (`extract_entry`, `:223-227`), with the same pattern in `parse_entries` (`:161`) and `live_without_entry` (`:364-368`). `probe3.log` P3: live Q-009 (OPEN) holds ```` ```markdown ```` / `### Q-018 · keep-or-drop-x-1` / ANSWERED header / `**Answer:** [3]` / ```` ``` ````. Q-011 (OPEN) and Q-012 (ANSWERED, `[1]`) follow. `questions.sh archive` printed `archived Q-018` and `archived Q-012`.
- The live file was left as `17: ```markdown` / `18: ### Q-011 · still open` …, with the opener unclosed.
- The archive got `### Q-018 …` / `**Answer:** [3]` / `` ``` `` and then `### Q-012 …`.
- Results after the archive: 366efd7 `open Q-009; unrecognized Q-018; open Q-011; keep Q-012`. 38578a9 `open Q-009; done Q-018; skip Q-011: … only inside a code fence in docs/working/questions.md; skip Q-012: … only inside a code fence in docs/working/questions-archive.md`.

The brief's premise, "questions.sh's own layout can't produce one", is refuted. The commit Notes accept that "an unbalanced fence anywhere makes later entries unreadable". After one `archive` run, that means every later entry in both files, until someone repairs the fence by hand. Each skip keeps its ID off `Applied:` and is listed (SKILL:297-299), so it fails toward asking. `done Q-018` needs Q-018 to be a lost `Asked:` ID. Under 366efd7 the trailing fence left Q-018 `unrecognized`.

**Recommendation:** Make questions.sh's entry parsing fence-aware, sharing FENCE_AWK, or have `questions.sh check` fail on a file that ends inside a fence or holds a fenced `### Q-` line. The END skip from F2 at least turns this into a skip with a named cause. Either way it belongs in the questions.sh change, which is outside this diff, so file it if it is not fixed here.

#### F4. Any fenced `### ` line now ends the target entry, so a `###` comment or a quoted markdown heading in a code block loses the answer that follows it; the bats comment at `:759-760` is stale

**Severity:** Informational (fail-closed loss)
**Location:** `scripts/dev-cycle.sh:397`; `test/scripts/dev-cycle.bats:759-760`
**Boundary:** B1
**Move:** 3
**Confidence:** High (executed, `probe4.log`)
**Legibility-target:** maintainer

**Evidence (verbatim):** `infence { … if ($0 ~ /^### /) inside = 0; …` (`:397`). The bats comment says `# Inside a fence only a "### Q-NNN " heading ends the entry, so a shell` / `# comment in a pasted block does not cut it short.` Q-035 (```` ```bash ```` / `# comment` / `## two` / `### three` / ```` ``` ```` / `**Answer:** [3]`) read `done` at 366efd7 and reads `unrecognized` at 38578a9. CommonMark reads done. A `#### ` line does not end the entry (Q-036: keep). The test still passes because it uses a single `#`.

**Recommendation:** Headings in fences are quotes now, so end the entry only on a fenced `### Q-NNN ` line (the 366efd7 rule), or on none at all. Fix the bats comment either way.

#### F5. The ANSWERED gate is "as in questions.sh" only for headers questions.sh writes; four hand-edited shapes read answered here and OPEN (or no status) there

**Severity:** Informational (only the header's writer can produce these, and that writer can set ANSWERED directly)
**Location:** `scripts/dev-cycle.sh:402-406`; comment `:361-364`
**Boundary:** B1
**Move:** 11
**Confidence:** High (executed, `probe2.log` H1–H7). questions.sh's reading is from its code (`:170-180`).
**Legibility-target:** maintainer

**Evidence (verbatim):** `header = 1; v = ""; n = split($0, fld, " · ")` / `for (i = 1; i <= n; i++) { f = fld[i]; sub(/^[ \t]+/, "", f); if (substr(f, 1, 12) == "**Status:** ") v = substr(f, 13) }` / `sub(/[ \t]+$/, "", v); answered = (v == "ANSWERED")`. questions.sh does three things differently: it strips every `**` before splitting (`gsub(/\*\*/, "", line)`), it does not trim fields, and it rereads every `**Needs:**` line, so the last one wins.
- H2 `… · **Status:** ANSWERED · Status: OPEN`: drop here, OPEN there.
- H3 `… ·  **Status:** ANSWERED` (two spaces): drop here, no status there.
- H4 `… · **Status:** OPEN ·  **Status:** ANSWERED`: drop here (366efd7: open), OPEN there.
- H5 a second `**Needs:** … OPEN` line: drop here, OPEN there.

Fixed from pass 28: Q-006 (status quoted inside Needs), Q-007 `ANSWERED (2026-10-02)` and Q-039 `ANSWERED (by user)` now read `open`. Q-040 `OPEN · ANSWERED` now reads `drop`, which matches questions.sh's last-field rule. The mawk `split` on ` · ` splits by bytes in the C locale (`probe4.log`: `[a][b][**Status:** ANSWERED] n=3`). Every real ID reads the same as before.

**Recommendation:** Say "the last bold `**Status:** ` field of the first `**Needs:**` line" in the comment. Matching questions.sh exactly, with no trim and `**` stripped, is optional.

#### F6. A `closed/` brief that reads `open` or `new` is "listed in the final message", but the final-message paragraph does not name that category

**Severity:** Informational
**Location:** `skills/dev-cycle/SKILL.md:90-93`, `:369-374` (c345865)
**Boundary:** B4
**Move:** 5
**Confidence:** Medium (read-static; it depends on whether the agent treats the final-message list as exhaustive)
**Legibility-target:** agent

**Evidence (verbatim):** Rules: "a `closed/` brief that reads `open` or `new` is recorded and listed in the final message for the user to set, and gets no keep-or-drop question". Final message: "list the new `you: judgment` entries by ID and name, any keep-or-drop answer step 6 could not read, read as `unrecognized`, or found still `open` (each with its brief), and each brief holding a slot by path". A `closed/` brief holds no slot, so none of these items covers it. The path fails safe: the line stays in In flight, and step 3 now runs only "under `briefs/`" (`:300`). That resolves pass-28 F6's contradiction with "still holds its slot".

**Recommendation:** Add "each `closed/` brief that reads `open` or `new`, for the user to set" to the final-message list.

#### F7. In flight membership counts every glob-listed brief, but the orphan rule only adds lines for slot-holders, so a done/dropped brief under `briefs/` with no line is never reached by check 1

**Severity:** Informational
**Location:** `skills/dev-cycle/SKILL.md:93-95`, `:269-272` (c345865)
**Boundary:** B4
**Move:** 5
**Confidence:** Medium (read-static)
**Legibility-target:** agent

**Evidence (verbatim):** In flight: "items whose brief the Rules' glob lists or this cycle wrote (whatever state `--check-brief` prints, so check 1 can close it)". Rules: "A brief that holds a slot but whose path no In flight line names … gets one, so In flight's checks reach it". A brief whose merged change set `done`, with no roadmap line (written by hand, or its line removed), is In flight by definition but has no line, and no rule adds one. It stays in `briefs/` and holds no slot. Nothing closes or loses it: it is a bookkeeping gap. Pass-28 F7 is otherwise fixed: done briefs that have a line now reach check 1.

**Recommendation:** "A brief the glob lists (any state) whose path no In flight line names gets one".

## Pass-28 probe reruns (executed; not endorsements, because the fence reader has F1/F2 and untested candidates)

| Pass-28 shape (`probe2.log`, isolated) | 366efd7 | 38578a9 | CommonMark |
|---|---|---|---|
| sec F1 forged Q-018 after a quote + ```` ```bash ```` block | done | skip (only inside a fence) | no entry: skip |
| sec F1 forged Q-018 balanced / Q-023 quote at end; fc Q-037 | unrecognized ×3 | skip (fenced) ×3 | skip |
| sec F2 Q-015 list-item fence / Q-024 / brief list.md | drop / unrecognized / done | keep / keep / open | keep / keep / open |
| sec F3 Q-006 / Q-007; fc Q-039 | drop / drop / drop | open ×3 | open (q.sh OPEN/invalid) |
| sec F4 Q-021 open fence, `## Notes`, then ```` ``` ```` closes it, `[2]` | drop | drop | drop (`## Notes` is fenced text, so `[2]` is unfenced in Q-021) |
| Q-001/002/003/004/010/011/012/019/020, fc Q-033, Q-044 | keep ×11 | keep ×11 | keep |
| fc Q-038 (first answer line decides) | unrecognized | unrecognized | unrecognized |
| fc Q-040 `OPEN · ANSWERED` | open | drop | q.sh ANSWERED (last field) |
| fc Q-045 `[1]` then a fence open at EOF | unrecognized | keep | keep |
| Q-008 quotes another heading in a fence, then `[1]` | unrecognized | unrecognized | keep (F4 loss) |
| Q-013/Q-014/Q-017, fc Q-031/Q-032 | keep ×3 / drop ×2 | unrecognized ×3 / **keep ×2** | keep / drop (F1) |

Every pass-28 security F1–F3 shape now reads as CommonMark does or skips. F4's shape is CommonMark-consistent. The regressions are F1's 4-space and tab rows.

## Untested bypass candidates

- An ordered marker whose content column is ≥ 5 (`10.  ```` `), and a list-item fence closed at a deeper indentation than the opener: not run. These are F1's column rule.
- Blockquote fences with lazy unprefixed lines, and `<pre>`/HTML blocks: not run, as in pass 28. They are now also F2 parity triggers in principle.
- `questions.sh archive` where an OPEN quoted copy of an ANSWERED real entry's heading is in the live file: `extract_entry` would move both chunks. Not run.
- gawk and busybox awk: not installed. Every result is mawk 1.3.4's.
- Entries written after 5a50016: not covered by the real-ID run.

Because of F1, F2 and these candidates, neither fence reader appears in the Endorsement Claims.

## Endorsement Claims

- **Claim:** `--check-answer` output on every real ID is identical at 366efd7 and 38578a9: 102 IDs at 5a50016 and at c345865 (3 done, 19 drop, 26 keep, 13 open, 41 unrecognized), 98 at 38578a9 and 99 on `/workspace` main. The 8 real questions files are fence-balanced under FENCE_AWK (1/1 and 9/9 opens/closes, none open at EOF) and hold no indented or list-marker fence-shaped line.
  **Location:** `scripts/dev-cycle.sh:352-443`
  **Evidence:** executed
  **Verified:** `probe1.log`; `diff ans-old-*.log ans-new-*.log` empty for all four sources.
  **Not verified:** entries written after 5a50016, and any future `questions.sh archive` of a fenced heading (F3).
  **route: code-fact-check**
- **Claim:** The A gates hold at 38578a9: bats 47/47, `hermeticity-lint --root .` clean (126 files), and shellcheck on `scripts/dev-cycle.sh` clean. `--help` (`sed -n '2,66p'`) prints 65 lines ending at the Exit paragraph. Line 66 is its last comment line.
  **Location:** `scripts/dev-cycle.sh:2-66`, `:130`
  **Evidence:** executed
  **Verified:** `bats.log`, `lint.log`, `probe1.log`.
  **Not verified:** shellcheck on the bats file, and the full repo suite.
  **route: code-fact-check**
- **Claim:** The header split runs under mawk 1.3.4 in the C locale: `split` on the UTF-8 ` · ` gives the three expected fields, and `a·b · c` splits in two (an unspaced dot is not a separator).
  **Location:** `scripts/dev-cycle.sh:403`
  **Evidence:** executed
  **Verified:** `probe4.log`.
  **Not verified:** gawk or busybox awk, and a Latin-1 `\xb7` dot (which by reading gives one field, so the entry reads open).
- **Claim:** 5a50016's `scripts/dev-cycle.sh`, `test/scripts/dev-cycle.bats` and `skills/dev-cycle/SKILL.md` blobs equal 38578a9's and c345865's, and `scripts/questions.sh` is unchanged across all three.
  **Location:** merge 5a50016
  **Evidence:** executed
  **Verified:** `git rev-parse <commit>:<path>` for each.
  **Not verified:** other paths in the merge.
  **route: code-fact-check**
- **Claim:** B's future-tip tolerance of "more than two days" covers every pair of zone offsets from −12:00 to +14:00 (a 26 h spread, so at most a 2-calendar-day difference, as pass-28 fact-check E8 computed). A misread tip date only ever leads to a keep-or-drop question, never a close.
  **Location:** `skills/dev-cycle/SKILL.md:310-312`
  **Evidence:** read-static (arithmetic from pass-28 `fc28/logs/tz.txt`)
  **Verified:** the sentence at c345865, and step 3 filing a question as the only consequence of idleness.
  **Not verified:** that the agent compares calendar days, and committer clocks that are simply wrong (S3).

## Primitive sweep

Primitive: process exec (`git`/`awk` argv) on values from repo text, in the changed units. This round changes no exec site. Only the awk program text and messages change.

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/dev-cycle.sh:291` `git cat-file -t "$MAIN_SHA:$a"` | S2/S4 path | `pathform` + brief regex + `blocker`, hash prefix | cleared: argv only |
| `scripts/dev-cycle.sh:295` `git cat-file blob … \| awk "$FENCE_AWK"'…'` | S2 blob | same; S5 program | cleared as exec; F1 is reader logic |
| `scripts/dev-cycle.sh:307-308` `git log -1 … -G'^Status: ' "$MAIN_SHA" -- "$a"` | S2 path, history | same, after `--` | cleared (unchanged) |
| `scripts/dev-cycle.sh:328` `git rev-list --count`, `git log -1 --format=%cs "$sha"` | S3 hash | hash only | cleared (unchanged) |
| `scripts/dev-cycle.sh:433` `awk -v id="$a" "$FENCE_AWK$ANSWER_AWK" "$f"` | S1 file, ID | ID `^Q-[0123456789]+$`; S5 programs; fixed file names | cleared as exec; F1, F2, F4, F5 are logic |

No eval, deserialization, SQL or HTML sinks are in scope.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| F1 | `lead()` on closers: list-marker or 4+-space line closes a fence; indented code opens one. N1/N2/N3 drop, briefs done, Q-031 keep (CommonMark: keep/open/drop) | Low | B1, B2 | `scripts/dev-cycle.sh:254-277` | High (code) / Med-High (CommonMark) |
| F2 | A parity error early in the file brings back the forged read (`done Q-018`); contradicts `:358-360` | Low | B1 | `:397-399`, `:422-426` | High |
| F3 | `questions.sh archive` splits at a fenced heading, so later entries in both files skip and the quote becomes a real entry | Low | B1 | `scripts/questions.sh:161-231`, `:362-372`; `dev-cycle.sh:397` | High |
| F4 | Any fenced `### ` ends the entry: Q-035 regresses to unrecognized; bats comment stale | Informational | B1 | `:397`; bats `:759-760` | High |
| F5 | Gate differs from questions.sh on 4 hand-edited header shapes | Informational | B1 | `:402-406` | High |
| F6 | closed/ open/new "listed in the final message", but not in its list | Informational | B4 | SKILL:90-93, :369-374 | Medium |
| F7 | Orphan rule adds lines only for slot-holders, so a done brief with no line never reaches check 1 | Informational | B4 | SKILL:93-95, :269-272 | Medium |

## Overall Assessment

The pass-28 targets are fixed as executed:
- whole-file tracking turns the forged-entry shapes into `fenced`/`dup` skips;
- list-item openers read as CommonMark does;
- the header gate takes the last ` · ` field;
- the help wording is fixed, the bats run is 47/47 with the lint and shellcheck clean, and every real ID reads unchanged.

On B:
- In flight now reaches done briefs that have a line;
- a closed/ open or new brief gets no keep-or-drop question;
- the two-day tolerance is correct for every zone pair.

What remains is three Low findings in the fence class, all executed:
- **F1** is the cause. Widening `lead()` for openers also widened closers and made indented code a fence. That gives wrong decisive readings on new shapes, and four of them regress against 366efd7.
- **F2** amplifies F1. One divergent line anywhere now flips the rest of the file, which reopens the pass-28 F1 forged read.
- **F3** shows the repo's own `questions.sh archive` producing exactly the unbalanced file the trade accepts.

None gives a party a capability it lacks: every decisive case needs quoted text that its author could have written as a real line. So nothing is Medium or above. Still, F1's rows break the brief's own criterion: never a wrong keep/drop/done. The issues are fixable in place, and none is architectural. The single most useful fix is F1's closer rule (no marker; indentation at most the opener's column + 3), together with F2's END skip when a fence is still open at EOF. That one line also contains F3. F4–F7 are fail-closed or wording gaps. No further findings within the code paths read; endorsement claims pending execution verification.

## Goal-Alignment Note

Success criterion (verbatim): "a markdown report saved at the path your role instructions give, structured per your skill file."

Saved at `/workspace/.claude/wt-digest/docs/reviews/security-review-2026-10-02-digest-pass29.md`, first line `Commit: 38578a9 (A) / c345865 (B)`. It follows the security-reviewer structure: header, Trust Boundary Map and S-table, Findings, Untested bypass candidates, Endorsement Claims (`route: code-fact-check` where a claim could anchor a rubric row), Primitive sweep, Summary Table and Overall Assessment. A probe-rerun table is added, as in pass 28. Every finding carries Severity, Location, Evidence (verbatim), Confidence and Legibility-target. The brief's attack list was covered:
- pass 28's fence and header probes rerun (the rerun table, F4, F5);
- the whole-file trade: real files are balanced, but questions.sh can unbalance one (F3), and parity inversion is possible (F2);
- `lead()` with 4-space indentation, which does both expose and hide answers (F1);
- `split` under mawk in the C locale (endorsement 3);
- the 102 real IDs (endorsement 1);
- commits 38578a9 and c345865, and merge 5a50016 (endorsements 2 and 4);
- B's In flight membership and closed/ path (F6, F7, endorsement 5).

Nothing was committed.
