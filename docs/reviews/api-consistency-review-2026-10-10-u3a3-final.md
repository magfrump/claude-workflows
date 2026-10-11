Commit: 01a2935f

# API Consistency Review: feat/build-loop-u3a3 (U3a3, final confirming pass)

**Scope:** `git diff main...HEAD` (full branch: 18f32952, a7a4f784, e25a6e89, 01a2935f). Surfaces: the `--approved Q-NNN` flag, its refusal lines, the approved merge's message, trailer and reflog, the `merge[-gate]-STEM-SHA12` slug grammar, and the lib names ANSWER_HEADING, TRUTH_WHERE, floor_why, the FLOOR_WHY words, IMPORTED_WHY and GATE_CODE.
**Date:** 2026-10-10
**Based on:** docs/reviews/code-fact-check-report-u3a3-final.md (0 behavioural Incorrect; wording items in claims 1-6; escalation: the header names ": Fast-forward" only for self-merge). Rubric docs/reviews/code-review-rubric-2026-10-10-feat-build-loop-u3a3.md and the 2026-10-10 `feat/build-loop-u3a3` override rows: C1 (expected heading not printed by --check, deferred to U4), C8, C9, C10 (Won't-Fix) are settled and are not re-raised. None of them regressed.
**Runs:** `bats test/scripts/build-loop-merge.bats` serially at 01a2935f: all 12 tests pass.

## Baseline Conventions

These are unchanged from iteration 1 (docs/reviews/api-consistency-review-2026-10-10-u3a3-i1.md):

- **CLI flags.** A mode comes first, then modifiers that name the mode they go with (`--expect` goes with `--check`/`--merge`). A malformed or misplaced flag is a usage error: it exits 1 with the one-line usage. `--approved` follows this: "--approved goes with --merge", "--approved takes one question ID (Q- and digits), given once" (`scripts/build-loop.sh:320-322`).
- **Verdict lines.** These are `ok|merged|refuse|deny|path BRIEF ...`. A refusal is `refuse BRIEF: WHY` and exits 2, with the ok line's path lines following. The approved arm uses the same shape (`:1225-1229`).
- **Message, trailer and reflog.** These are `Merge branch 'B' (build-loop AUTH)`, the `Build-loop-gate: STEM` trailer and the reflog `build-loop: AUTH of STEM`. The approved arm reuses the shape with AUTH = "approved merge" and adds `Build-loop-approved: Q-NNN` in the same `Build-loop-*: VALUE` form (`:1178-1179`).
- **Questions headings.** These are `### Q-NNN · <slug>`, and the slug grammar is `[a-z0-9-]+` (`scripts/questions.sh:250`). A brief stem is `YYYY-MM-DD-<SLUG>`, with SLUG `[a-z0-9-]+` (`scripts/lib/dev-cycle-read.sh:238, 433`). A 12-hex prefix is lower-case hex. So `merge-STEM-SHA12` and `merge-gate-STEM-SHA12` always satisfy `questions.sh check`'s slug grammar.
- **Lib side values.** These are UPPER_SNAKE globals reset at function entry and documented in the function's comment. Reasons are held as a word and turned into a sentence by a `*_why` function: `IMPORTED_MAIN_WHY`→`walk_why`, main_entry's word→`entry_why`, `oddwhy`. The FLOOR_WHY→`floor_why` change in this branch completes that pattern.

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `--approved Q-NNN` | CLI flag | `--expect SHA`, `--check-answer Q-NNN` | `scripts/build-loop.sh:316-319`; `scripts/dev-cycle.sh:209` | Consistent. It is a mode modifier with a typed argument, and the ID grammar matches check_answer's `^Q-[0-9]+$` |
| `merged`/`refuse` lines under --approved | verdict line | the self-merge arm's lines | `scripts/build-loop.sh:1224-1229` | Consistent. Same lines and exit codes |
| `Build-loop-approved: Q-NNN` | commit trailer | `Build-loop-gate: STEM` | `scripts/build-loop.sh:1178-1179` | Consistent. Same `Build-loop-` prefix |
| `build-loop: approved merge of STEM` | reflog text | `build-loop: self-merge of STEM` | `scripts/build-loop.sh:1197-1198` | Consistent. Same `build-loop: WHAT of STEM` shape |
| `merge-STEM-SHA12`, `merge-gate-STEM-SHA12` | slug grammar | `[a-z0-9-]+`; plan D4 `merge-<stem>-<first 12 of TIP>` | `scripts/questions.sh:250`; `docs/working/plan-build-loop-handoff.md:60-61` | Consistent. It always passes questions.sh check, and the gate set matches plan D4 since e25a6e89 |
| `approval` | function | `land`, `floor`, `ownfile` | `scripts/build-loop.sh`; `scripts/lib/dev-cycle-read.sh:1905-1990` | Consistent. A bare noun for a predicate that sets `MERGE_WHY` and returns 1, as `land` does |
| `AUTH` | script global | `MODE`, `EXPECT`, `APPROVED` | `scripts/build-loop.sh:312` | Consistent |
| `VERDICT[gate]` | assoc key | `tip`, `tree`, `policy`, `branch`, `stem` | `scripts/build-loop.sh:1038` | Consistent. A lower-case one-word key; set (1) or empty, as the comment says |
| `ANSWER_HEADING` | lib side value | `TRUTH_WHY`, `FLOOR_WHY`, `IMPORTED_MAIN_WHY` | `scripts/lib/dev-cycle-read.sh:2079-2083` | Consistent. Reset at entry and documented; "heading" is the lib's word (awk `heading()`) |
| `TRUTH_WHERE` | lib side value | `TRUTH_WHY` | `scripts/lib/dev-cycle-read.sh:1888-1911` | Won't-Fix row (C10). Not re-raised |
| `IMPORTED_WHY` | lib side value | `IMPORTED_MAIN_WHY` | `scripts/lib/dev-cycle-read.sh:808-810` | Consistent. Mirrors the main walk's name |
| `floor_why` | lib function | `walk_why`, `entry_why`, `oddwhy` | `scripts/lib/dev-cycle-read.sh:812-834` | Consistent. Word→sentence, with a catch-all for unknown words |
| FLOOR_WHY words `instr dot cycle user record case gate working review walk imported below` | enum | truthrule's TRUTH_WHY words `instr dot user record case settings` | `scripts/lib/dev-cycle-read.sh` truthrule | Consistent. It reuses truthrule's words directly. Only `settings`→`cycle` is renamed, to keep the old sentence ("one of the dev cycle's own files") |
| `GATE_CODE` (adds `^skills/dev-cycle/`) | lib regex | `INSTRUCTION_FILE`, `PROMPT_DIR` | `scripts/lib/dev-cycle-read.sh:1926` | Consistent. Anchored, and the trailing `/` keeps `skills/dev-cycle-x/` out (T10 pins it since 01a2935f) |

## Findings

#### 1. The header gives the reflog's ": Fast-forward" suffix only for the self-merge reflog, though the approved reflog gets it too

**Severity:** Minor
**Location:** `scripts/build-loop.sh:222-237` (header); behaviour at `:1192`
**Move:** 3 (consumer contract: documentation drift)
**Confidence:** High
**Legibility-target:** for-author

Evidence:
```
scripts/build-loop.sh:223-225:  its reflog entry reads "build-loop:
                 self-merge of STEM" (git adds ": Fast-forward" when W
                 moves it). With --approved Q-NNN it lands ...
scripts/build-loop.sh:235-237:  and the reflog "build-loop:
                 approved merge of STEM". The heading pins only TIP's
scripts/build-loop.sh:1192:    GIT_REFLOG_ACTION="$msg" git -C "$w" ... merge --ff-only -q "$NEW"
```

Both authorities pass `$msg` to the same `merge --ff-only` in W. An approved merge with main checked out in a worktree therefore logs `build-loop: approved merge of STEM: Fast-forward`. This was the fact-check's escalation (r2). A consumer that reads the header literally (U4's orchestrator matching reflog text, or a human auditing `git reflog main`) expects the bare string for an approved merge. The parenthetical sits inside the self-merge sentence, so a reader takes it as specific to that sentence. Only the CAS path's approved reflog is tested (`test/scripts/build-loop-merge.bats`, "approved merge of 2026-10-01-x"). Nothing fails closed or opens here; the cost is a wrong string-match.

**Recommendation:** Move the parenthetical after the approved sentence, or rephrase it to cover both: "(either reflog entry gains git's ': Fast-forward' when W moves it)". The merge message is a fine place to note it if the branch is otherwise frozen.

#### 2. ANSWER_AWK's comment still describes a one-word output; since a7a4f784 the single-entry case prints the heading as a second line

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:1991-1994` (comment); `:2069` (`print head`)
**Move:** 3 (consumer contract: documentation drift on a lib constant)
**Confidence:** High (fact-check claim 2, Stale, 2/2 replicates)
**Legibility-target:** for-author

Evidence:
```
scripts/lib/dev-cycle-read.sh:2069:  else if (count) { print (!answered ? "open" : done ? result : "unrecognized"); print head }
scripts/lib/dev-cycle-read.sh:2101:    hit="${r%%$'\n'*}"; head="${r#*$'\n'}"; where="$f"
```

ANSWER_AWK is a lib-level string that any script sourcing the lib can splice into awk. Its comment still describes its output as one word. A second consumer written against that comment would compare `$r` to `keep` and see `keep\nQ-NNN · slug`. Today check_answer is the only consumer and splits off the heading correctly, and `dev-cycle.sh --check-answer` output is unchanged (it prints only `"$hit $a"`). So no existing caller is affected.

**Recommendation:** Add one clause to the comment: "and, when exactly one entry matches, the heading after '### ' as a second line (check_answer splits it off)".

#### 3. The lib header and check_answer's comment slightly overstate the ANSWER_HEADING calling convention

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:35-38, 2076-2079`
**Move:** 8 (nullability contract)
**Confidence:** High (fact-check claims 3, 4: Mostly accurate)
**Legibility-target:** for-author

Evidence:
```
scripts/lib/dev-cycle-read.sh:2076:  # ... With an answer line it
                                       # sets ANSWER_HEADING to the entry's heading ... else empties it
```

ANSWER_HEADING is set for every non-skip result. That includes `open`, which has no answer line. The one caller runs inside `elif ... && ! approval`, where set -e is off, so "under set -e" does not hold there. Neither point changes a result: approval refuses `open` before it reads the heading, and nothing in check_answer exits. A future reader relying on "empty unless answered" would still be safe, because they would get a heading they don't need, never a missing one.

**Recommendation:** Optional. Write "with an entry found (any non-skip line)" in place of "with an answer line". Drop "under set -e" from the header or qualify it.

No other findings. No settled row regressed:
- C1: --check still prints `ok BRIEF TIP TREE` with no heading. This is unchanged and deferred to U4.
- C8: the two refusal phrasings are as recorded.
- C9: the usage message is unchanged.
- C10: TRUTH_WHERE's naming is unchanged.
- C2, C3, C14 and C15 remain fixed: the option 2/3/"not read" words, ANSWER_HEADING, GATE_CODE's two reasons with floor tests, and the header's "--expect still binds the tip".

## What Looks Good

- **Backward compatibility.** `--check`, `--status` and plain `--merge` keep their lines. AUTH is empty for --check, and `sm` is set exactly when the policy is self-merge and AUTH is not approved. The only changed text on an existing path is the review refusal, reworded per row 661 to point at the new flag ("--merge lands it only with --approved Q-NNN"). The new refusal names its own remedy.
- **dev-cycle.sh --check-answer output is byte-identical.** The heading travels only in the side value.
- **The slug is checkable by questions.sh.** Stem and SHA12 grammars guarantee that `merge[-gate]-STEM-SHA12` matches `[a-z0-9-]+`, so U4's filed entry passes `questions.sh check` without escaping.
- **One authority value.** AUTH decides check_line's rules and land's message, trailer and reflog together (row 653; rubric A3 fixed). The trailer and the message can no longer disagree.
- **The FLOOR_WHY words reuse truthrule's vocabulary**, and floor_why has a catch-all that names an unknown word rather than printing nothing.
- **The refusal WHYs follow the lib's skip style:** a lower-case clause, the plan's option numbers, and the accepted forms in a parenthetical.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Header gives ": Fast-forward" only for the self-merge reflog; the approved reflog gets it too | Minor | `scripts/build-loop.sh:222-237` | High |
| 2 | ANSWER_AWK's comment describes a one-word output; it now prints the heading as a second line | Minor | `scripts/lib/dev-cycle-read.sh:1991-1994` | High |
| 3 | ANSWER_HEADING's set condition and "under set -e" slightly overstated | Informational | `scripts/lib/dev-cycle-read.sh:35-38, 2076` | High |

## Overall Assessment

The branch is consistent with the codebase's API patterns, and nothing breaks an existing consumer:
- The flag, verdict lines, exit codes, trailer, reflog shape and slug grammar all extend U3a2's conventions.
- The lib changes bring FLOOR_WHY and the tree walk's failure in line with the word-plus-`*_why` pattern.
- The final pass finds only documentation drift. The approved reflog's Fast-forward suffix and ANSWER_AWK's stale output description are both fixable in place in one comment line each, or recordable in the merge message.
- There is no consumer impact today: each affected surface has one internal consumer, which handles the real behaviour.

No 🔴 or 🟡 from this critic.

## Goal-Alignment Note

Success criterion (verbatim): "a report saved to /workspace/.claude/wt-build-loop-u3a3/docs/reviews/api-consistency-review-2026-10-10-u3a3-final.md, structured per the api-consistency-reviewer skill, with `Commit: 01a2935f` at the top."

- Met: the file is at that path, with `Commit: 01a2935f` as its first line, and has the skill's sections (header, Baseline, Name-Pattern Audit, Findings, What Looks Good, Summary Table, Overall Assessment).
- Every finding carries Severity, Location, verbatim Evidence, Confidence and Legibility-target.
- Settled rubric rows were checked for regression and not re-raised. Not committed, per the task.
