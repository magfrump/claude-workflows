Commit: c034a75 (A) / a218ad8 (B)

# API Consistency Review — dev-cycle loop pass 11 (pass-10 fix round)

**Scope:** Partial. A: `git diff b88a9c4..c034a75 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` (worktree `/workspace/.claude/wt-digest`). B: `git diff 79b1bfe..a218ad8 -- skills/dev-cycle/SKILL.md docs/working/questions.md docs/working/seed-build-loop-handoff.md` (worktree `/workspace/.claude/wt-devcycle`). Everything else on both branches is context only.
**Date:** 2026-10-01
**Based on:** `docs/reviews/code-fact-check-report-digest-pass10.md` (Stage-1 context; it covers the pass-9 round at b88a9c4 / 79b1bfe, so the claims new in c034a75 / a218ad8 were checked here by reading the code and by probes, below).
**Replication:** k=1 loop pass.

Surface under review: the digest's printed format (the Window line, section 2, 3, 5, 7 and 8 messages) as read by the dev-cycle skill's agent; the A↔B contract (section 8 → the record's `## Skipped inputs`, step 0's reading of the Window line); and consistency across the skill, Q-103 and the handoff seed.

Execution (scratch, not committed): `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/api11/probe.sh` and `probe.out` (the script at c034a75, extracted to `api11/dev-cycle.sh`, run under `timeout 60` in a `mktemp -d` repo the trap removes, `DEV_CYCLE_TODAY=2026-03-01`). `bats test/scripts/dev-cycle.bats` at c034a75: 21/21 ok (`git diff --stat c034a75 HEAD -- scripts test` is empty).

Legibility-target values: **agent** (the model running the skill acts on the text), **maintainer** (someone editing the script or tests), **user** (the human reading briefs, Q-103 or the record).

## Baseline Conventions

- **Skip-not-absent.** Since pass 9 an input that exists but fails the plain-file test is reported where it would have been read ("… NOT read (section 8)") and listed in section 8, while a missing input gets a distinct "No …" message. Precedent in `scripts/dev-cycle.sh:226-229`, `:248-251`, `:298-302`, `:317-321`. Pass 10 extended this to the Window line and section 2; that extension is what this round is judged against.
- **One category word.** c034a75 replaces "reached through a symlink" with "not a plain file (reached through a symlink, or not a regular file)" in every inline message and the section 8 header (`:227`, `:249`, `:299`, `:318`, `:327`).
- **Helper naming.** Predicates are bare lowercase words with no prefix: `inrepo` (`:92`), `skipped` (`:101`), `trig` (`:172`), `scrub` (`:40`). Globals that count or gate are lowercase snake_case (`last_record`, `n_merges`, `merges_full`).
- **Skill ↔ digest names.** The skill names each digest section by number and topic (`skills/dev-cycle/SKILL.md:95-98`), and the record template reuses the section's title as its heading (`:251`).
- **Questions grammar.** Entries follow the global "Running questions document" template: options table, `Interim`, `If the answer differs` (precedent: every open entry in `docs/working/questions.md`, e.g. Q-090).

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `plaindir` | function (internal) | `inrepo`, `skipped`, `trig` | `scripts/dev-cycle.sh:92,101,172` | Consistent: bare lowercase predicate, same `realpath -e` equality shape as `inrepo` |
| `skipdir` | function (internal) | `skipped`, `inrepo` | `scripts/dev-cycle.sh:101` | Consistent: mirrors `skipped` (same guard, same `SKIPPED+=`); the dir form appends `/`, which marks it as a directory in section 8 |
| `records_skipped`, `n_before_triggers`, `decisions_glob` | globals | `last_record`, `n_merges`, `merges_full` | `scripts/dev-cycle.sh:127,161,163` | Consistent: snake_case, `n_` prefix for a count already used |
| "not a plain file (reached through a symlink, or not a regular file)" | printed message | "is reached through a symlink: NOT read" (b88a9c4) | `scripts/dev-cycle.sh:227,249,299,318,327` | Consistent: one wording in all five places |
| "no readable cycle record (one or more were skipped as not plain files: section 8), so the default of 14 days" | Window-line source note | "no cycle record found, so the default of 14 days (…)" | `scripts/dev-cycle.sh:145,147` | Consistent with its sibling's shape; coverage gap in F2 |
| "No revisit triggers read: decision records or the log were skipped as not plain files (section 8)." | section 2 message | "No revisit triggers recorded." | `scripts/dev-cycle.sh:201-202` | Consistent wording; coverage gap in F1 |
| "None: every input is a plain file." | section 8 message | "None: no input is reached through a symlink." (b88a9c4) | `scripts/dev-cycle.sh:325` | Inconsistent: false when an input is absent (F4) |
| "(nothing to brief)" | section 7 message | "(0 items ready for 6b)" (b88a9c4) | `scripts/dev-cycle.sh:301` | Consistent: no longer names a removed step |
| `## Skipped inputs` | record heading | `## 8. Skipped inputs` (digest), `## Trigger verdicts` | `skills/dev-cycle/SKILL.md:66,98,251`; `scripts/dev-cycle.sh:323` | Consistent: one name on both sides; `git grep "Skipped paths" a218ad8 -- . ':!docs/reviews'` returns nothing |
| "keep or drop the brief for <item>?" | questions entry title | "merge <branch>?" | `docs/working/questions.md:56`; `docs/dev-cycle.md:14` | Consistent: same "<verb> <object>?" shape |
| "hooks, enforcement and harness config" | list term (Q-103 [2]) | "hooks, enforcement and harness settings" | `docs/working/seed-build-loop-handoff.md:33-34` | Inconsistent: F6 |

## Findings

#### F1. Section 2 still says "No revisit triggers recorded." when `docs/decisions` itself is skipped and holds no `log.md`

**Severity:** Inconsistent
**Location:** `scripts/dev-cycle.sh:173-175`, `scripts/dev-cycle.sh:200-203` (A, c034a75)
**Move:** 3 (consumer contract), 8 (absent vs skipped)
**Confidence:** High
**Legibility-target:** agent

**Evidence:**
```
decisions_glob=()
if plaindir docs/decisions; then decisions_glob=(docs/decisions/[0-9][0-9][0-9]-*.md); else skipdir docs/decisions || true; fi
n_before_triggers=${#SKIPPED[@]}
```
and
```
if [[ $found -eq 0 ]]; then
  if [[ ${#SKIPPED[@]} -gt $n_before_triggers ]]; then echo "No revisit triggers read: decision records or the log were skipped as not plain files (section 8)."
  else echo "No revisit triggers recorded."; fi
fi
```

The baseline is drawn after `skipdir` has already appended `docs/decisions/`, so a skipped directory never counts. The skipped branch fires only if the later `log.md` check also adds an entry, which needs a `log.md` to exist inside the link target. Probe P2: `docs/decisions` → an outside directory holding `001-x.md` with a `## Revisit triggers` section and no `log.md`. Section 2 prints `No revisit triggers recorded.` while section 8 prints `- docs/decisions/`. Probe P6 (a regular file at `docs/decisions`) gives the same result. P3 (target has a `log.md`) prints the "read" message, but only because of the log entry. This is the exact pass-10 R1 defect, in the directory case this round added. c034a75's message says "section 2 says "No revisit triggers read" when its inputs were skipped (api F2)". New test 7 sets up the P2 layout (`outside/dec/001-private-plan.md`, no log) but asserts nothing about section 2. Test 6 covers only per-file skips. Precondition: a committed symlink (or non-directory) at `docs/decisions` whose target has no `log.md`. The agent then records "no triggers" as a fact in step 2, although section 8 shows the reason.

**Recommendation:** Move `n_before_triggers=${#SKIPPED[@]}` above the `plaindir docs/decisions` line. Add `[[ "$output" == *"No revisit triggers read"* ]]` to test 7's first run.

#### F2. A skipped cycle record newer than a readable one still reads as absent: the Window line names the older record as "the last", and step 0 then diagnoses a skipped step 7

**Severity:** Inconsistent
**Location:** `scripts/dev-cycle.sh:127-149` (A); `skills/dev-cycle/SKILL.md:99-103` (B)
**Move:** 3 (consumer contract across A↔B)
**Confidence:** High (digest behavior, probed); Medium (the agent's reading)
**Legibility-target:** agent

**Evidence:**
```
elif [[ -n "$last_record" ]]; then
  SINCE="$last_record"; source_note="the last cycle record, docs/working/cycles/cycle-$last_record.md"
else
  SINCE="$(date -d "$TODAY - 14 days" +%F)"
  if [[ $records_skipped -gt 0 ]]; then
```
(the `else` branch continues to `:149`; `records_skipped` is read only there)
and the skill:
"If the window starts before the last cycle you know ran (or says no cycle record was found when one ran), that cycle skipped step 7: note it in this record and rerun with `--since` set to that cycle's date. If instead it says the records were skipped (section 8), the record exists but is not a plain file: note that, fix or report the link, and rerun with `--since` the same way."

`records_skipped` changes the note only when no record is readable. Probe P1: a plain `cycle-2026-01-01.md` and a symlinked `cycle-2026-02-15.md`. The output is `Window: since 2026-01-01 (from the last cycle record, docs/working/cycles/cycle-2026-01-01.md)`, and section 8 has `- docs/working/cycles/cycle-2026-02-15.md`. The Window line calls the older record "the last", and nothing in it mentions a skip. Step 0's second sentence keys on the Window line saying the records were skipped, so it does not fire. The first sentence fires instead ("starts before the last cycle you know ran"), and the agent records "that cycle skipped step 7", which is the false diagnosis pass-10 F1 / R1 set out to remove. The remedy (rerun with `--since`) is still right, so only the record's note and the missing "fix the link" action are wrong. Precondition: a skipped record dated after the newest readable one. The brief's question "can a skipped record coexist with a readable one and mislead?": yes.

**Recommendation:** In the digest, track the newest skipped record date (`d` from the skipped `f`, still capped at `TODAY`). When it is later than `last_record`, add "(a newer record, cycle-<d>.md, was skipped: section 8)" to the source note. Or widen step 0's second sentence to "If section 8 lists a cycle record dated after the window start, that record exists but is not a plain file: …".

#### F3. The 14-day "keep or drop?" rule leaves three things open: what "no commit on its branch" means, where the 14 days start, and what happens after "keep"

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:216-219` (B, a218ad8)
**Move:** 3 (contract an agent must execute), 9 (repeat-safety of the filing)
**Confidence:** Medium
**Legibility-target:** agent (to execute it), user (who answers it)

**Evidence:** "A brief open for 14 days with no commit on its branch gets one `you: judgment` entry, "keep or drop the brief for <item>?" (unless one is already open), so unstarted briefs do not hold the slots for good."

(1) A branch cut from the default branch already contains its commits. Read literally ("`git log <branch>`"), "no commit on its branch" is never true once the branch exists, so the rule fires only while the branch does not exist yet. The intended reading is "no commit on the branch beyond the default branch" (`git log <default>..<branch>`). (2) "Open for 14 days" names no clock. The brief's file name date (`YYYY-MM-DD-<slug>.md`, `:231`) is the obvious one, and it would help to say so. (3) The duplicate guard covers only an *open* entry. After the user answers "keep", the entry is archived, the condition still holds, and the next cycle files it again, every cycle, which spends the attention the rule exists to save (Rules: "Attention is the budget", `:32`). The "no branch yet" case resolves correctly under either reading: no branch means no commit, so the entry fires.

**Recommendation:** "A brief whose file date is 14+ days old and whose branch has no commit beyond the default branch (or does not exist) gets one … entry … (unless one is open, or the user answered keep since the brief's last commit)". Or record "kept YYYY-MM-DD" in the brief and count 14 days from that.

#### F4. Section 8's "None: every input is a plain file." is false when an input is absent

**Severity:** Minor
**Location:** `scripts/dev-cycle.sh:324-325` (A); asserted at `test/scripts/dev-cycle.bats` (redirect test, `tail -1 … | grep -q 'every input is a plain file'`)
**Move:** 2 (message naming against its siblings), 8 (absent vs skipped)

Precedent: section 8's previous wording "None: no input is reached through a symlink." (b88a9c4, `scripts/dev-cycle.sh` section 8) and the absent-input messages at `scripts/dev-cycle.sh:229,251,301,320`

**Confidence:** High
**Legibility-target:** agent

**Evidence:** `echo "None: every input is a plain file."`. Probe P5 (an empty repo: no roadmap, no questions, no decisions) prints it while section 5 prints "No docs/roadmap.md yet". The digest has two categories, absent and skipped. This line claims a third ("is a plain file") for inputs that do not exist. The old wording was a negative claim, so it stayed true for absent inputs; the new one is positive, so it does not. The agent copies this line into the record's `## Skipped inputs`.

**Recommendation:** `None: no input was skipped.` (and update the redirect test's grep).

#### F5. Seed item 4 and the new skill rule set different In-flight staleness rules for the same roadmap section

**Severity:** Informational
**Location:** `docs/working/seed-build-loop-handoff.md:37-39` vs `skills/dev-cycle/SKILL.md:216-219`
**Move:** 3 (cross-document contract)
**Confidence:** Medium
**Legibility-target:** maintainer (of the future handoff unit)

**Evidence:** Seed: "building (a commit within 7 days) → stays; anything else → Ideas." Skill: "A brief open for 14 days with no commit on its branch gets one `you: judgment` entry, "keep or drop …"".

The seed's design for In flight moves an item to Ideas without asking after 7 quiet days. The skill now asks after 14. These serve different units (autonomous loops vs user-started briefs), and the seed is marked "carry forward, re-verify" (`:24`), so nothing is wrong today. Whoever builds the handoff will still find two thresholds and two outcomes for the same section with no note on which one wins.

**Recommendation:** Add one line to the seed's design list or its open edges: "the skill's 14-day keep/drop entry (a218ad8) covers user-started briefs; reconcile with item 4".

#### F6. Q-103 option [2] calls its list "the seed's list" but says "harness config" where the seed says "harness settings"

**Severity:** Informational
**Location:** `docs/working/questions.md:57` (B, a218ad8)
**Move:** 2 (naming against the source it cites)

Precedent: "hooks, enforcement and harness settings" used in `docs/working/seed-build-loop-handoff.md:33-34`

**Confidence:** High
**Legibility-target:** user

**Evidence:** "(the seed's list: hooks, enforcement and harness config, instruction files, skills/, …, devcontainer-config/)". Every other item matches the seed, in the seed's order. "config" and "settings" probably cover the same files, but the option claims to quote, and a user comparing the two sees a difference that may mean nothing. Graded Informational because the meaning is unchanged and no code reads it.

**Recommendation:** Replace "harness config" with "harness settings".

#### F7. Step 0 and the "Never through a symlink" rule still speak of links while the digest's category is "not a plain file"

**Severity:** Informational
**Location:** `skills/dev-cycle/SKILL.md:61-67`, `skills/dev-cycle/SKILL.md:102-103` (B)
**Move:** 3 (A↔B contract wording)
**Confidence:** High
**Legibility-target:** agent

**Evidence:** "the record exists but is not a plain file: note that, fix or report the link, and rerun with `--since` the same way." and "check that no part of the path below the repo root is a symlink (`test -L` on each component …) … The digest applies the same rule to everything it reads".

c034a75 widened the digest's rule to "not a regular file" as well: a directory or FIFO at an input path is skipped (`inrepo` needs `-f`, `:92`). The skill's own rule checks only `test -L`, yet it says the digest applies "the same rule". Step 0 says "the link" for a case that need not be one. When the whole `docs/working/cycles/` is skipped, section 8 prints only `- docs/working/cycles/`, so "that cycle's date" for `--since` cannot be read from the digest. None of this misleads in practice, since section 8 names the path and the agent can inspect it.

**Recommendation:** "fix or report it" in step 0, and "a symlink, or not a regular file" in the rule (which would also stop the cycle's own reads from blocking on a FIFO).

#### F8. Edge cases in the new skip accounting: a contents path under a skipped directory, a future-dated skip, a non-directory labeled with `/`

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:102`, `:137`, `:186-199` (A)
**Move:** 8
**Confidence:** High
**Legibility-target:** maintainer

**Evidence:** Probe P3 lists both `- docs/decisions/` and `- docs/decisions/log.md`. The commit and test 7 ("a symlinked directory is listed once, never its contents") say only the directory is listed. The second line is a fixed name, so no outside name leaks; the security intent of A1 holds. Probe P4: the only record is a symlinked `cycle-2027-01-01.md` (future-dated, which a plain file would ignore). The Window line still says "no readable cycle record (one or more were skipped…)" because `records_skipped` counts skips without the `TODAY` cap. Probe P6: a regular file at `docs/decisions` is listed as `docs/decisions/`, with a directory slash.

**Recommendation:** Optional. Skip the `log.md` check when `docs/decisions` itself was skipped. Apply the `TODAY` cap when counting skipped records (this also fits F2's fix).

## Rules checked and found correct and complete

- **Guarded globs (`plaindir`).** A symlinked `docs/decisions` or `docs/working/cycles` is never globbed. Outside names do not reach any section (test 7; probe P2 shows no `001-x` in the output). Absent directories add nothing to section 8 (`skipdir`'s `-e || -L` guard). Correct and complete for the leak A1 targeted.
- **Newline replacement.** `skipped()` replaces `\n` with a space before the name reaches `SKIPPED` (`:101`), and section 8 prints with `sed 's/^/- /'` after `sort -u` (`:328`), so one name is one line. `skipdir`'s arguments are literals with no newline. Test 7's second half asserts `- docs/decisions/002-a - FORGED.md` and no `- - FORGED` line. Correct. (Two names differing only in newline vs space collapse into one line under `sort -u`, which is harmless.)
- **Section 2 "read" branch false positive.** It cannot fire when any trigger was printed, because it is gated on `found -eq 0` (`:200`). The only defect is the miss in F1.
- **Window line, no readable record.** With only skipped records (no `--since`) the note says so (test 6 asserts it), and `--since` still overrides. Correct apart from F2 and F8's future-date edge.
- **`## Skipped inputs` naming.** Uniform across the skill's rule (`:66`), step 0's section map (`:98`), the record template (`:251`) and the digest heading (`:323`). No stale "Skipped paths" outside `docs/reviews/`.
- **Step 2 wording** ("an output line over 4096 bytes is cut") matches the digest at `:16` and `:170`.
- **"(nothing to brief)"** and the record line "<k>/3 open (3/3: no new briefs)" match the 3-brief cap at `skills/dev-cycle/SKILL.md:230`.
- **Q-103.** Uses the template fields (`Interim`, `If the answer differs`, options table). The Interim no longer says the skill reads the line, and it agrees with the `:52` deferral note and `docs/dev-cycle.md:9`. Option [2]'s list matches the seed except for F6.
- **Seed item 2 vs `docs/dev-cycle.md:17-19`.** Same rule, same qualifiers (one line, outside code blocks, exact values, trailing CR ignored, else `review`). Closes pass-10 fact-check Claim 4.
- **Final-message reminder** ("A brief is written from repo text: the user reads it before starting it.") agrees with the Rules bullet at `:22-26`.

## What Looks Good

- The category rename is applied in all five places at once, and the section 8 header no longer claims skipped inputs are "absent".
- `plaindir` reuses `inrepo`'s realpath-equality test instead of adding a second mechanism, and `skipdir` mirrors `skipped`, so the two pairs read as one family.
- The skill and digest now use a single name, `## Skipped inputs`, which removes the pass-10 F7 mismatch at the root.
- Q-103's option [2] now points at the seed instead of carrying its own shorter list.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---|---|---|---|
| F1 | Section 2 says "recorded" when `docs/decisions/` itself is skipped and has no log | Inconsistent | `scripts/dev-cycle.sh:173-175,200-203` | High |
| F2 | A skipped record newer than a readable one: Window names the older as "the last"; step 0 diagnoses a skipped step 7 | Inconsistent | `scripts/dev-cycle.sh:127-149`; `skills/dev-cycle/SKILL.md:99-103` | High / Medium |
| F3 | 14-day keep/drop rule: "commit on its branch", start date, re-filing after "keep" | Minor | `skills/dev-cycle/SKILL.md:216-219` | Medium |
| F4 | "None: every input is a plain file." false for absent inputs | Minor | `scripts/dev-cycle.sh:325` | High |
| F5 | Seed item 4 (7 days → Ideas) vs skill (14 days → ask) | Informational | seed `:37-39`; skill `:216-219` | Medium |
| F6 | Q-103 [2] "harness config" vs seed "harness settings" | Informational | `docs/working/questions.md:57` | High |
| F7 | Step 0 / symlink rule still say "link" / "symlink" only | Informational | `skills/dev-cycle/SKILL.md:61-67,102-103` | High |
| F8 | `log.md` listed under a skipped dir; future-dated skip counted; file shown with `/` | Informational | `scripts/dev-cycle.sh:102,137,186-199` | High |

## Overall Assessment

Most of the round lands. The leak through symlinked directories is closed, newline names stay on one line, the category wording is uniform, and the skill and digest agree on `## Skipped inputs`, step 2's wording, Q-103 and the seed's policy rule. Two gaps remain in the round's central goal of saying "skipped, not absent". F1 is the section 2 counter drawn one line too late, so the directory case this round added reads as "No revisit triggers recorded", and test 7 builds that layout without asserting it. F2 is the Window line, which reports a skip only when no record is readable, so a skipped newer record still leads step 0 to a false "skipped step 7" note. Both are fixable in place with a line or two each, plus test assertions. Neither breaks a consumer's flow, because section 8 always lists the skip and the `--since` remedy is unchanged. The 14-day brief rule (F3) needs a tighter reading of "commit on its branch" and a guard against re-asking after "keep". The rest is wording.

## Goal-Alignment Note

Success criterion (verbatim): "a markdown report saved at the path your role instructions give, structured per your skill file."

This report is saved at `/workspace/.claude/wt-digest/docs/reviews/api-consistency-review-2026-10-01-digest-pass11.md`, with first line `Commit: c034a75 (A) / a218ad8 (B)`. It follows the skill's structure (header, Baseline Conventions, Name-Pattern Audit, Findings, What Looks Good, Summary Table, Overall Assessment). Every finding carries Severity, Location, Evidence (verbatim), Confidence and Legibility-target, and the naming findings (F4, F6) carry a `Precedent:` line. It serves the user goal (merge both branches once a clean pass is reached) by naming F1 and F2 as the items that keep this round from clean on the API surface. Not committed. Scratch only under `api11/`.
