Commit: f4d27d2 (A) / a7dfc0c (B)

# API Consistency Review: dev-cycle pass 30 (pass-29 fix round)

**Scope:** A: `git diff 38578a9..f4d27d2 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` (worktree `/workspace/.claude/wt-digest`, commits e2f2d54 and f4d27d2). B: `git diff c345865..a7dfc0c -- skills/dev-cycle/SKILL.md` (worktree `/workspace/.claude/wt-devcycle`, merge 35987c1; SKILL.md is identical at a7dfc0c and 35987c1). Partial scope. Everything else is context only.
**Date:** 2026-10-02
**Based on:** `docs/reviews/code-fact-check-report-digest-pass29.md` (Stage-1 context), the shared brief `digest-pass30-brief-dc1aa358.md`, and my own pass-29 report (`api-consistency-review-2026-10-02-digest-pass29.md`).
**Replication:** k=1 loop pass.

**Probe discipline.** Each probe was one `set -eu` script. It made its own `mktemp -d -p .../scratchpad/api30` dir in that same script and checked `case "$PWD"` before any `git init`, commit or write. Probes ran the scripts from `git show <commit>:scripts/dev-cycle.sh` (f4d27d2, 38578a9 and 366efd7, copied into `api30/`), or from `git archive f4d27d2`, under `GIT_CONFIG_GLOBAL=/dev/null` and `LC_ALL=C`, with every process under `timeout`. Real questions files were read with `git show` and copied into temp repos. I wrote nothing outside `api30/` except this file and left no processes running. The system awk is mawk 1.3.4 20200120. No CommonMark implementation is installed in the sandbox (no markdown-it, commonmark, cmark or pandoc), so the "CommonMark" column below comes from the spec's rules, cited in F1, not from a renderer.

Gates at f4d27d2 (from `git archive`): `bats test/scripts/dev-cycle.bats` gave 48 ok, 0 not ok. `python3 scripts/hermeticity-lint --root .` printed "126 test file(s) checked, no unstubbed network spawns." `--help` (`sed -n '2,67p'`) ends at "...a failed step exits non-zero mid-digest. Printed repo text is data.", which is line 67, the last header line; line 68 is blank. So the range is right.

Legibility-target values: **agent** (the model running the skill acts on the text), **maintainer** (someone editing the script or tests), **user** (the human reading help, record or final message).

## Baseline Conventions

- Check modes print one line per argument: `<verdict> <arg> [fields]`, or `skip <arg>: <lowercase reason clause>`. A skip is an answer, not an error (exit 0). Precedent: `scripts/dev-cycle.sh:433-449` (`check_answer`) and `:288-314` (`check_brief`).
- `--check-answer` verdicts are `keep|drop|done|open|unrecognized`. Every way of failing to read an entry is a `skip` with a reason. The skill keys on the verdict word only (`skills/dev-cycle/SKILL.md:285-299`).
- `FENCE_AWK` is shared by `--check-brief` and `--check-answer`, so a change to fence semantics changes both contracts.
- The fail-safe convention, from the code comments and the brief: every result is the CommonMark reading, or a `skip`/`open`/`unrecognized`, and never a wrong `keep`, `drop` or `done`.
- Entry headings follow questions.sh: `/^### Q-[0-9]+ /` starts an entry (`~/.claude/scripts/questions.sh:161, 223, 364`).

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `skip Q-NNN: a code fence in <f> is never closed, so nothing after it can be trusted` | skip reason | `skip Q-NNN: more than one entry with this heading in <f> (…)`, `skip Q-NNN: its heading appears only inside a code fence in <f>` | `scripts/dev-cycle.sh:441-444` | Consistent in shape (`skip <id>: <clause>` naming the file). The clause's "after it" disagrees with the behavior (F2). |
| `unbalanced` (internal awk result) | internal token | `dup`, `fenced`, `open`, `unrecognized` | `scripts/dev-cycle.sh:427-432` | Consistent: internal only, mapped to a skip line and never printed bare |
| `spaces()`, `opens()`, `closes()`, global `fcol` | awk functions/state | `run()`, `fch`, `flen`; the removed `lead()` | `scripts/dev-cycle.sh:264-280` | Consistent: same terse lowercase style. `opens()` declares an unused local `m` (F5). |
| `/^### Q-[0123456789]+ /` as the in-fence entry end | pattern | questions.sh's `/^### Q-[0-9]+ /` | `~/.claude/scripts/questions.sh:161, 223, 364` | Consistent: the same heading shape questions.sh splits on, so the reader ends an entry exactly where archive would |
| Help phrase "a code fence never closed" | help text | "no such entry, a duplicate heading, a heading only inside a code fence, a questions file that is not plain" | `scripts/dev-cycle.sh:54-57` | Consistent |
| Help phrase "no answer line was found, or the first one's text…" | help text | the pass-28 wording | `scripts/dev-cycle.sh:51-53` | Consistent, and correct (pass-29 F2 closed) |
| B: "the glob prints `ok` for" (In flight, orphan rule) | skill phrase | the slot rule's "the glob prints `ok` for it" | `skills/dev-cycle/SKILL.md:84-85` | Consistent: all three places now use the same phrase |
| B: "each `closed/` brief that reads `open` or `new`" (final message) | skill phrase | the Rules' "a `closed/` brief that reads `open` or `new`" | `skills/dev-cycle/SKILL.md:91-92` | Consistent wording. The qualifier is missing (F4). |

## Findings

#### F1. The new closer bound still diverges from CommonMark in two shapes, so `--check-answer` returns a wrong `drop`/`keep` and `--check-brief` a wrong `done`

**Severity:** Inconsistent. It breaks the check modes' never-a-wrong-verdict contract, the same class as pass-29 F1. It would be Breaking for a repo with the shape, but no real file has it.
**Location:** `scripts/dev-cycle.sh:274` (`fcol = i`), `:276-280` (`closes`); the comments at `:255-261` and `:360-362`; tests at `test/scripts/dev-cycle.bats` (test 48)
**Move:** 3 (consumer contract), 6 (changed semantics)
**Confidence:** High that it reproduces. Medium-High on the CommonMark reading: it follows from the spec's rules, but I could not run a CommonMark renderer here. Low-Medium that the shapes are realistic.
**Legibility-target:** agent (acts on keep/drop/done), maintainer

**Evidence (verbatim):**
```
function closes(l,   i, s, n) {
  i = spaces(l); if (i > fcol + 3) return 0
  s = substr(l, i + 1); n = run(s, fch)
  return n >= flen && substr(s, n + 1) ~ /^[ \t]*$/
}
```
That is the whole function. `fcol` is set in `opens()` as `fcol = i`, where `i` is the opener's leading spaces plus any list marker. The comment at `:259-261` says the same thing as the code: "indented at most 3 columns past the opener's fence". So code and comment agree. Both disagree with CommonMark in two ways:

- **List-marker opener (`- ```` `, `1. ```` `).** In CommonMark, a non-blank line indented less than the item's content column ends the list item. A fenced block is not a paragraph, so no lazy continuation applies, and the fence closes implicitly *without consuming that line*. An unindented ```` ``` ```` after it opens a new fence. The script accepts any line indented 0..`fcol+3` as the closer instead.
- **Opener indented 1–3 spaces.** The spec lets a closing fence have "up to 3 spaces of indentation", in absolute terms. The opener's indentation N only sets how much is stripped from content lines. The script allows up to N+3, so for `  ```` ` a content line `     ```` ` (5 spaces) closes the fence.

Each divergence consumes one fence line more or less than CommonMark does. On its own that leaves the file unbalanced, and the new `unbalanced` skip catches it (my probes LL and II gave skip). Two divergent lines restore the parity, though, and so does one divergence in a file whose CommonMark reading ends inside a fence. Then the script reads the wrong line:

| Probe (entry ANSWERED, f4d27d2) | Lines | CommonMark | f4d27d2 | 38578a9 | 366efd7 |
|---|---|---|---|---|---|
| L2x | `- ```` ` / `Q-1: [1]` / ```` ``` ```` / `Q-1: [2]` / `- ```` ` / `x` / ```` ``` ```` | keep | **drop** | drop | keep |
| I2x | `  ```` ` / `     ```` ` / `Q-1: [2]` / `  ```` ` / `Q-1: [1]` / `     ```` ` | keep | **drop** | drop | keep |
| Lblank | `1) ```` ` / *(blank)* / ```` ``` ```` / `Q-1: [1]` | unrecognized (the answer is fenced; the file ends in a fence) | **keep** | keep | keep |
| brief-lb | `- ```` ` / `Status: open` / ```` ``` ```` / `Status: done` / `- ```` ` / ```` ``` ```` | open | **done** | done | — |
| brief-ib | `  ```` ` / `     ```` ` / `Status: done` / `  ```` ` / `Status: open` / `     ```` ` | open | **done** | done | — |
| brief-la | `1. ```` ` / `Status: open` / ```` ``` ```` / `Status: done` | open | **done** | done | — |

`--check-brief` has no balance check (see F3), so brief-la needs only the one divergence. A wrong `done` sends a brief to Done (In flight check 1). A wrong `drop` sends it to Ideas with `Status: dropped`. A wrong `keep` sets `Kept:` and adds the ID to `Applied:`, so the real answer is never read. The ANSWER comment's claim at `:362`, "and no fenced line is read", is false for these inputs. The list-marker and indented-opener shapes came in at pass 28 (38578a9). Pass 29's fix closed the shapes that pass-29 F1 reported (P1, P1b, P2, P3, brief x and y now give the CommonMark result), but not these.

I own part of this. Pass-29 F1 recommended "at most the opener's content indentation plus 3 spaces", and e2f2d54 implemented that faithfully. That bound is only right for list-marker openers, and only from below.

There is also a pre-existing limit that this round did not introduce: the script tracks no list containers. `1. Run:` / `   ```` ` / `   code` / ```` ``` ```` / `Q-1: [1]` gives `keep` at f4d27d2, 38578a9 and 366efd7. Under CommonMark it is unrecognized, because the unindented ```` ``` ```` ends the item and opens a new fence. The "close to CommonMark" comment hedges this, but the `:362` claim does not.

Exposure: there is none today. I grepped `questions.md` and `questions-archive.md` at 35987c1 and at `main` for fence lines indented 1–3 spaces or after a list marker, and found 0. No briefs exist on 35987c1.

**Recommendation:** Record whether the opener had a list marker (`fmark`). In `closes()`, use the bound 0..3 for an unmarked opener, and `fcol`..`fcol+3` for a marked one. For a marked opener, a non-blank line indented less than `fcol` should end the fence *without* being consumed, so the line falls through to the normal rules: drop the `next` for that case, or set `infence = 0` before the line's other rules run. If that is more than the loop wants, the fail-safe alternative is to treat any closer whose indentation falls outside the CommonMark range as making the file untrusted (the `unbalanced` skip). Add L2x, I2x, Lblank and brief-la as bats cases. Change the `:362` claim to name the remaining approximation (no list containers).

#### F2. The never-closed skip says "nothing after it", but it skips every ID, including entries before the fence and entries in the other file, and it does not say where the fence is

**Severity:** Minor
**Location:** `scripts/dev-cycle.sh:442`; the comment at `:362-365`; `test/scripts/dev-cycle.bats` (test 47, the Q-21/Q-15 assertion)
**Move:** 4 (error helpfulness and consistency)
**Confidence:** High
**Legibility-target:** user, agent

**Evidence (verbatim):** the reason is `skip $a: a code fence in $f is never closed, so nothing after it can be trusted`. The comment says "A file that ends with a fence still open is a skip for every ID ... so nothing in that file is trusted." The bats test asserts `skip Q-15: a code fence in docs/working/questions.md is never closed`, and Q-15's entry comes *before* the open fence (Q-21 is appended after it). An open fence in `questions-archive.md` also skips IDs whose entries are in `questions.md`, because the loop reaches the archive after the hit and returns the skip. A user who reads "nothing after it" for Q-15 has no reason to think Q-15 is affected. The stated motive is that questions.sh archive splits an entry at a fenced heading. That leaves a lone fence line somewhere in a long file, and the skip names neither the line nor the entry. Every keep-or-drop ID then stays off `Applied:` until someone finds it (`SKILL.md:298-299`).

**Recommendation:** Use wording that matches the behavior and gives a location, for example `skip $a: a code fence opened at line N of $f is never closed, so no entry in it is read`. Print the opener's line number from `END`, recorded in `opens()`.

#### F3. `--check-brief` reads a file that ends inside a fence, while `--check-answer` now refuses one

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:299-304` (`check_brief`'s awk) against `:427-428`; the help at `:29-36`
**Move:** 7 (asymmetry between the two FENCE_AWK consumers)
**Confidence:** High
**Legibility-target:** maintainer

**Evidence (verbatim):** `check_brief`'s awk has no `END` and prints the first `/^Status:/` line outside a fence: `infence { if (closes($0)) infence = 0; next }` / `opens($0) { infence = 1; next }` / `/^Status:/ { seen = 1; ... }`. Probe brief-ub (```` ``` ```` / `stray` / `Status: open` / ```` ``` ```` / `Status: done` / ```` ``` ````) gives `ok … done`. That is the CommonMark reading, so it is not wrong by the contract. But f4d27d2's rationale, "One stray fence line flips everything after it ... nothing in that file is trusted", applies to a brief just as well. The archive-split motive does not apply, because questions.sh never edits briefs. Brief-la in F1 is a wrong `done` that a balance check would have turned into a skip.

**Recommendation:** Either add the same `END { if (infence) … }` guard to `check_brief`, as a skip reason like "a code fence … is never closed", or add a line in the comment at `:282-287` saying why briefs do not need it. Either is fine. The point is to make the asymmetry deliberate.

#### F4. The final message's "each `closed/` brief that reads `open` or `new`" does not say which `closed/` briefs are checked

**Severity:** Informational
**Location:** `skills/dev-cycle/SKILL.md:371-372`; the Rules at `:88-92`
**Move:** 7
**Confidence:** Medium (the Rules supply the context; this matters only to an agent reading step 7 on its own)
**Legibility-target:** agent

**Evidence (verbatim):** the final message lists "each `closed/` brief that reads `open` or `new` (for the user to set its status)". The Rules limit this to a brief that is reached when "A roadmap In flight path that `--check-path` skips ... is recorded and its line corrected: pointed at `docs/working/briefs/closed/<same name>`". The Rules' glob (`docs/working/briefs/*.md`) does not list `closed/`. An agent could read step 7 as "check every file in `closed/`". That costs extra `--check-brief` calls and surfaces old briefs nobody asked about.

**Recommendation:** Optionally, add "(an In flight line repointed there this cycle)" after "each `closed/` brief".

#### F5. `opens()` declares an unused local `m`

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:266`
**Move:** 2 (naming hygiene)
**Confidence:** High
**Legibility-target:** maintainer

**Evidence (verbatim):** `function opens(l,   i, s, m, ch, n) {`. The body (`:267-274`) never uses `m`. It looks like a leftover from an earlier draft that used `match()` with an array, which mawk does not support.

**Recommendation:** Drop `m`.

## What Looks Good

- **Pass-29 F1's shapes are fixed.** P1, P1b, P2, P3 and T1 (a tab-indented fence line inside a fence) give `keep` at f4d27d2, where 38578a9 gave drop or unrecognized and 366efd7 gave keep. M2 (a 4-space fence line, then a real closer) gives keep. Brief x and brief y give `open`. All match CommonMark. Test 48 covers the indented and list-marker content lines and indented code.
- **`match()`/`RLENGTH` under mawk 1.3.4.** The marker regex `^([-*+]|[0123456789]+[.)])[ \t]+` with `RLENGTH` strips `- `, `1. ` and `1) ` correctly (P2, N1, L2, Lblank), and `[0123456789]` avoids locale ranges. This is correct.
- **The never-closed skip is a sound fail-safe.** U1 (a single unclosed fence), I1, I2, LL and II all give the skip where 38578a9 gave a wrong drop or unrecognized. It is checked before `dup`, so it wins. It is consistent with questions.sh archive's split at `/^### Q-[0-9]+ /` (`questions.sh:364-369`). That split leaves the archive with an opener and the live file with a lone fence line, so both now skip instead of being misread.
- **The in-fence entry end** (`/^### Q-[0123456789]+ /`) uses questions.sh's own heading shape. Probe Qtab (a fenced `### Q-7<TAB>x` line) leaves the entry open, and the answer after the fence reads as `keep`. A `### ` shell comment in a pasted block no longer loses the answer. This is correct and complete for the heading form questions.sh writes.
- **Help.** The `unrecognized` definition now covers the no-answer-line case (pass-29 F2 closed), and the skip list names the never-closed fence. The help range `2,67p` is exact.
- **Real IDs are unchanged.** All 102 IDs at 35987c1 and all 99 at `main` give identical output under f4d27d2, 38578a9 and 366efd7 (35987c1: 3 done, 19 drop, 26 keep, 13 open, 41 unrecognized). No real questions file is unbalanced.
- **Pathological input.** A 16 MiB line of spaces inside and outside a fence returns `keep Q-1` in 2 s.
- **B, orphan rule and In flight.** "A brief the glob prints `ok` for, or this cycle wrote, whose path no In flight line names ... gets one, whatever its state" (`SKILL.md:93-95`) now matches In flight's membership, "items whose brief the Rules' glob prints `ok` for or this cycle wrote (whatever state ...)" (`:269-270`). Both use the slot rule's "prints `ok`". A done or dropped brief that lost its line now reaches check 1. Pass-29 F4 is closed, and the rule is correct and complete.
- **B, final message.** It now lists `closed/` briefs that read `open` or `new`, in the Rules' own words. Pass-29 F3 is closed, with the qualifier nit in F4.
- **Commits.** e2f2d54's and f4d27d2's messages describe their diffs accurately, including the help change and the test moves. a7dfc0c's message matches its 11-line SKILL.md diff.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| F1 | Closer bound still diverges from CommonMark (list-marker opener with a less-indented line; 1–3-space opener with a 4–6-space fence line): wrong drop/keep/done | Inconsistent | `scripts/dev-cycle.sh:274-280`, `:360-362` | High (repro) / Medium-High (CM reading) / Low-Medium (realism) |
| F2 | Never-closed skip says "nothing after it" but skips every ID in both files; no line number | Minor | `scripts/dev-cycle.sh:442` | High |
| F3 | `--check-brief` has no never-closed guard, unlike `--check-answer` | Informational | `scripts/dev-cycle.sh:299-304` | High |
| F4 | Final message's `closed/` item lacks "repointed this cycle" | Informational | `skills/dev-cycle/SKILL.md:371-372` | Medium |
| F5 | Unused local `m` in `opens()` | Informational | `scripts/dev-cycle.sh:266` | High |

## Overall Assessment

The round fixes what pass 29 reported. P1–P3 and both brief variants now give the CommonMark reading. The never-closed skip turns every single-divergence and stray-fence case into a skip. Help, comments and the skill's wording agree with each other, and every real ID reads as before. The interface additions follow the existing `skip <id>: <clause>` convention. One substantive gap remains, F1. The closer bound that pass-29 F1 recommended, which e2f2d54 implemented faithfully, is not CommonMark for unmarked indented openers, and it ignores the list item ending under a list-marker opener. Two divergent lines, or one in a brief (which has no balance guard), still give a wrong `drop`, `keep` or `done`. No real file has these shapes, and the fix is local to `closes()` plus four tests. Alternatively, the fail-safe route is to make any out-of-range closer a skip. F2 is a one-line wording and location fix. F3–F5 are optional. Consumer impact today is nil. The risk is latent, and it is the same class the loop has been closing, so this pass is not clean.

## Goal-Alignment Note

Success criterion, restated verbatim: "a markdown report saved at the path your role instructions give, structured per your skill file." This report is saved at `/workspace/.claude/wt-digest/docs/reviews/api-consistency-review-2026-10-02-digest-pass30.md`. Its first line is `Commit: f4d27d2 (A) / a7dfc0c (B)`. It follows the api-consistency-reviewer structure (header, Baseline Conventions, Name-Pattern Audit, Findings, What Looks Good, Summary Table, Overall Assessment), and every finding carries Severity, Location, Evidence (verbatim), Confidence and Legibility-target. It serves the user's goal, merging `feat/dev-cycle` once a clean pass is reached. It confirms that pass 29's fixes landed, and it surfaces one remaining Inconsistent (F1) that should be fixed or turned into a skip before a clean pass is declared. Nothing was committed.
