Commit: a7a4f784

# API Consistency Review: feat/build-loop-u3a3 (U3a3, iteration 1, loop pass)

**Scope:** `git diff main...HEAD` (18f32952 tests, a7a4f784 code): scripts/build-loop.sh, scripts/dev-cycle.sh, scripts/lib/dev-cycle-read.sh, test/scripts/build-loop-{check,merge}.bats. Surfaces: the `--approved Q-NNN` flag, its refusal lines and exit codes, the approved merge's message, trailer and reflog, the `merge-STEM-SHA12` / `merge-gate-STEM-SHA12` slug contract that U4's orchestrator will write into questions.md, and the lib's new public names (ANSWER_HEAD, TRUTH_WHERE, IMPORTED_WHY, floor_why, the FLOOR_WHY words).
**Date:** 2026-10-10
**Based on:** docs/reviews/code-fact-check-report-u3a3-i1.md (26 claims: 22 verified, 4 mostly accurate). Its four Mostly-accurate comment wordings (build-loop.sh:213-214, :1087-1088, dev-cycle-read.sh:807, the commit's "both walks") are not repeated here. One of them matters to consumers: the --help text still opens "--merge lands a self-merge brief". That is fact-check Claim 1.
**Runs:** none of my own. Every behaviour below was read statically, or comes from the fact-check's R1 to R5 runs (merge bats 12/12, check bats 146/146, dev-cycle bats 79/79).

## Baseline Conventions

- **CLI flags.** A mode comes first (`--check`, `--merge`). A qualifier flag takes one value, and parse-time validation fails through `usage "MSG"` with exit 1. The messages read "--FLAG takes …", "--FLAG goes with …" and "given once" (build-loop.sh:306-321). Value forms are anchored with explicit character classes: `[0123456789abcdef]{40}`, and the lib's `^Q-[0123456789]+$` in check_answer (dev-cycle-read.sh:2073). dev-cycle.sh's check modes take positional IDs (`--check-answer Q-NNN...`, dev-cycle.sh:14, 209) and print one `WORD ID[: WHY]` line per ID.
- **Verdict lines.** `ok|merged BRIEF …` or `refuse BRIEF: WHY`. Path lines follow. Exit 2 is any non-ok verdict and exit 1 is bad usage (build-loop.sh header, Exit: paragraph). A WHY is a lower-case clause, and a nested reason follows a second colon or a semicolon (for example the checkout refusal at build-loop.sh:1024). A quoted lib skip passes through with its `skip ID: ` prefix stripped.
- **Merge provenance.** The message is `Merge branch 'BRANCH' (build-loop AUTH)`. The trailer is `Build-loop-gate: STEM`, and the reflog is `build-loop: AUTH of STEM` (U3a2, build-loop.sh:1168, 1101-1103).
- **Lib result globals.** A helper empties its globals on entry and returns through them. Machine reasons are short words, X_WHY (TRUTH_WHY, IMPORTED_MAIN_WHY, BRIEF_ODD's first word). Each has a matching `*_why` function that turns the word into a sentence: entry_why (dev-cycle-read.sh:366), walk_why (:811), oddwhy (:310). Some X_WHY globals hold prose instead (FILE_WHY :550, IMPORT_READER_WHY :607, CHECKOUT_WHY, MERGE_WHY). Walk pairs are named `IMPORTED*` for the tree walk and `IMPORTED_MAIN*` for the main walk (:806).
- **Questions entries.** The heading is `### Q-NNN · <slug>`. questions.sh splits it on " · " (scripts/questions.sh:162-168). The answer words of the lib's ANSWER_AWK are option 1/keep, 2/drop and 3/done (dev-cycle-read.sh:2006-2019).

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `--approved Q-NNN` | CLI flag | `--expect SHA`; `--check-answer Q-NNN` | `scripts/build-loop.sh:306-311`; `scripts/dev-cycle.sh:14` | Consistent. It qualifies one mode, takes one value, is given once, and uses check_answer's ID form. The usage text merges what --expect splits into two messages (Finding 5) |
| usage "--approved goes with --merge" | usage text | "--expect goes with exactly one brief path" | `scripts/build-loop.sh:321` | Consistent |
| `APPROVED`, `AUTH` (self-merge / approved / empty) | script globals | `EXPECT`, `MODE` | `scripts/build-loop.sh:300` | Consistent. AUTH's value `approved` becomes "approved merge" in the message and reflog. The self-merge value prints verbatim. The asymmetry is intended and documented (header :232-234) |
| `approval Q-NNN` | function | `checkout_gate`, `default_gate`, `merge_ident`, `land` | `scripts/build-loop.sh:1050-1105` | Consistent. Returns 0/1 and sets MERGE_WHY, like land |
| `Build-loop-approved: Q-NNN` | commit trailer | `Build-loop-gate: STEM` | `scripts/build-loop.sh:1168` | Consistent. `Build-loop-` prefix, kebab case |
| "(build-loop approved merge)", "build-loop: approved merge of STEM" | message, reflog | "(build-loop self-merge)", "build-loop: self-merge of STEM" | `scripts/build-loop.sh:1101-1103` (U3a2) | Consistent, symmetric |
| refusals "Q-NNN does not approve this merge: …" / "Q-NNN approves no merge of this tip: …" | verdict WHY | `refuse BRIEF: WHY`; skip quoting `skip ID: WHY` | `scripts/build-loop.sh:984-986, 1024` | Mostly consistent. The two phrasings differ (Finding 4) |
| `merge-STEM-SHA12`, `merge-gate-STEM-SHA12` | slug grammar (questions.md contract) | plan D4 `merge-<stem>-<first 12 of TIP>`; floor's "merge-gate- review entry" | `docs/working/plan-build-loop-handoff.md:60-61, 213, 319`; `scripts/lib/dev-cycle-read.sh:1914, 1970` | Matches the plan's grammar. The plan's gate-file set differs from GATE_CODE (Finding 1) |
| `VERDICT[gate]` | verdict key | `VERDICT[tip/tree/policy/branch/stem]` | `scripts/build-loop.sh:961-967` | Consistent. Set to 1 or left empty, documented |
| `ANSWER_HEAD` | lib global | `BRIEF_ODD`, `FILE_OUT`, `READERS_LINE`; awk `heading()` | `scripts/lib/dev-cycle-read.sh:385, 550, 607, 2021` | Minor. "HEAD" is git's word in these scripts (Finding 6) |
| `TRUTH_WHERE` | lib global | `TRUTH_WHY`, `IMPORTED_MAIN_WHY`, `FILE_WHY` | `scripts/lib/dev-cycle-read.sh:1866, 806, 550` | New suffix. It holds a sentence where TRUTH_WHY holds a word (Finding 7) |
| `IMPORTED_WHY` | lib global | `IMPORTED_MAIN_WHY`; `IMPORTED`/`IMPORTED_MAIN`, `IMPORTED_DONE`/`IMPORTED_MAIN_DONE` | `scripts/lib/dev-cycle-read.sh:806` | Consistent pair naming. Its value set is narrower (readers or empty) and is documented (:804-805) |
| `floor_why WORD` | lib function | `walk_why WHY`, `entry_why WORD [PATH]`, `oddwhy WHY` | `scripts/lib/dev-cycle-read.sh:811, 366, 310` | Consistent. A word-to-sentence function named for its global, with a catch-all `*)` arm like walk_why's |
| FLOOR_WHY words `case instr dot cycle user record gate working review walk imported below` | lib word set | TRUTH_WHY's `case instr dot cycle settings user record` | `scripts/lib/dev-cycle-read.sh:1866-1876` | Consistent. It reuses TRUTH_WHY's words and folds settings into cycle, as nrules does (build-loop.sh:782) |

## Findings

#### 1. The slug contract has two gate-file sets: the plan's includes `skills/dev-cycle/`, GATE_CODE does not

**Severity:** Inconsistent
**Location:** `scripts/build-loop.sh:1041`, `:1072`; `scripts/lib/dev-cycle-read.sh:1915`; against `docs/working/plan-build-loop-handoff.md:61`
**Move:** 3 (consumer contract), 7 (asymmetry between spec and implementation)
**Confidence:** High on the divergence. Medium on which side is intended, since the plan's own D5 list at :71 omits skills too.
**Legibility-target:** for-author (and for U4's skill author)

Precedent: the gate-file set written for the orchestrator in docs/working/plan-build-loop-handoff.md:61 (the D4 bullet U4 implements). The set enforced by the script is in scripts/lib/dev-cycle-read.sh:1915.

Evidence:
```
docs/working/plan-build-loop-handoff.md:61:    - A change to the gate's own files (`scripts/{build-loop,dev-cycle,questions}.sh`, `scripts/lib/`, `skills/dev-cycle/`) gets its own slug, `merge-gate-…`. Plain `--approved` refuses such a change (F52).
scripts/lib/dev-cycle-read.sh:1915:GATE_CODE='^scripts/(build-loop|dev-cycle|questions)\.sh$|^scripts/lib/'
scripts/build-loop.sh:1041:    [[ ! "${lps[$i]}" =~ $GATE_CODE ]] || gc=1
```

The slug is a two-party contract. U4's orchestrator writes `### Q-NNN · merge[-gate]-STEM-SHA12` from the plan, and this script reads it against GATE_CODE. Take a review brief that changes `skills/dev-cycle/SKILL.md`. The plan tells the orchestrator to file `merge-gate-…`, but the script requires plain `merge-…` and refuses the user's [1] answer with "its heading must read …". The user then has to be asked again. Two parts of the plan also go untrue. F52 claims that plain `--approved` refuses a dev-cycle skill change, and plan:170 marks F52 "covered", but this script lands one under `merge-`. Under --approved only the N rules run. skills/dev-cycle/SKILL.md is truthrule `instr`, which only the S-side floor refuses (build-loop.sh:780-785), so nothing else stops it. The header (build-loop.sh:229-231) documents the GATE_CODE set, so the script agrees with itself. The disagreement is with the spec U4 will be built from.

**Recommendation:** Make the two sets one. Either add `skills/dev-cycle/` to the --approved gate test (a separate regex if floor's GATE_CODE must stay as it is), or amend plan:61 and F52 to drop it. Record the choice as an override row, so U4 copies the right set.

#### 2. The orchestrator cannot read the gate bit, or the expected heading, from any output before it files the entry

**Severity:** Minor
**Location:** `scripts/build-loop.sh:1031-1033` (verdict_ok), `:1070-1084` (approval)
**Move:** 3 (consumer contract), 7 (asymmetry)
**Confidence:** High
**Legibility-target:** for-author

Evidence:
```
scripts/build-loop.sh:1033:    echo "ok $a $sha $tree"
scripts/build-loop.sh:1083:    || { MERGE_WHY="$1 approves no merge of this tip: its heading must read \"$1 · $s\"$g"; return 1; }
```

The script decides the slug (merge- or merge-gate-, from lower-cased paths against GATE_CODE), and the orchestrator has to write it. But `--check` prints only `ok BRIEF TIP TREE` and path lines. VERDICT[gate] is held in memory and never printed. The exact expected heading appears only in a refusal, after the user has answered. U4's skill must therefore re-derive "any changed path, lower-cased, matches GATE_CODE" in prose, and Finding 1 shows that prose already drifts. The failure is safe, because a wrong slug refuses. The cost is a wasted round of the user's attention, which the project counts as its scarcest budget.

**Recommendation:** Have `--check` (or a `--status`-like read) print the slug it would accept, for example a trailing `slug merge-gate-STEM-SHA12` line. The orchestrator would then copy it instead of re-implementing the rule. Or record in the plan's U4 bullet that the skill must take the slug from the refusal text. Deferring to U4 is reasonable.

#### 3. An answer that names the plan's option ("merge") is refused as "not option 1", and "keep" approves

**Severity:** Minor
**Location:** `scripts/build-loop.sh:1080`; `scripts/lib/dev-cycle-read.sh:2006-2019` (ANSWER_AWK option())
**Move:** 3 (consumer contract), 4 (error consistency)
**Confidence:** High (static: option() returns "unrecognized" for any token that is not 1/2/3/keep/drop/done or [1]/[2]/[3])
**Legibility-target:** for-author

Evidence:
```
scripts/lib/dev-cycle-read.sh:2011:  if (!match(s, /^(1|2|3|keep|drop|done)/)) return "unrecognized"
scripts/lib/dev-cycle-read.sh:2016:  if (w == "1" || w == "keep") return "keep"
scripts/build-loop.sh:1080:    *) MERGE_WHY="$1 does not approve this merge: its answer on the default branch is not option 1"; return 1 ;;
docs/working/plan-build-loop-handoff.md:60: ... The options are **[1] merge**, **[2] drop** and **[3] changes needed** ...
```

The merge entry's options are named merge/drop/changes needed. The reader's word aliases are keep/drop/done. So `Q-012: merge` is "unrecognized", and the refusal says "is not option 1". That is wrong in the user's own terms, and it hides the fact that the answer was unreadable rather than a no. `Q-012: keep` approves a merge. The catch-all arm also folds drop, done and unrecognized into one sentence. The skip arm, by contrast, quotes the lib's reason. Both directions fail closed except "keep", and "keep" is still option 1.

**Recommendation:** Give the catch-all arm the word: "its answer on the default branch is WORD, not option 1", or "cannot be read (answer [1], [2] or [3])" for unrecognized. Note in U4's bullet that the skill must ask for a numbered answer.

#### 4. The four approval refusals use two subject phrasings

**Severity:** Informational
**Location:** `scripts/build-loop.sh:1078-1083`
**Move:** 4 (error consistency)
**Confidence:** High
**Legibility-target:** for-author

Precedent: one fixed subject per refusal family, e.g. "refuse BRIEF: its branch BR …" at scripts/build-loop.sh:985-986

Evidence:
```
scripts/build-loop.sh:1078:    "open $1") MERGE_WHY="$1 does not approve this merge: it is not answered on the default branch"; return 1 ;;
scripts/build-loop.sh:1083:    || { MERGE_WHY="$1 approves no merge of this tip: its heading must read \"$1 · $s\"$g"; return 1; }
```

Three refusals read "Q-NNN does not approve this merge: …" and the heading refusal reads "Q-NNN approves no merge of this tip: …". The split is defensible: the heading case means the answer may approve a different merge. But a consumer matching on "does not approve this merge" misses one of the four. Today no consumer exists, but U4's skill is the first and will quote these lines in a re-filed entry. This is not a naming finding, so no downgrade applies, and it stays at Informational because the text is free-form WHY.

**Recommendation:** Keep it, or use "does not approve this merge: its heading must read …" for all four. Either way, write the chosen family into U4's bullet.

#### 5. `--approved`'s usage message merges the two causes that `--expect` reports separately

**Severity:** Informational
**Location:** `scripts/build-loop.sh:314`, against `:308-310`
**Move:** 2 (naming and wording against the grain), 4
**Confidence:** High
**Legibility-target:** for-author

Precedent: separate count and form messages for one flag, in scripts/build-loop.sh:308-310

Evidence:
```
scripts/build-loop.sh:308:        [[ $# -ge 2 && -z "$EXPECT" ]] || usage "--expect takes one commit id, given once"
scripts/build-loop.sh:310:        [[ "$2" =~ ^([0123456789abcdef]{40}|[0123456789abcdef]{64})$ ]] || usage "--expect takes a full 40- or 64-hex commit id"
scripts/build-loop.sh:314:        [[ $# -ge 2 && -z "$APPROVED" && "$2" =~ ^Q-[0123456789]+$ ]] || usage "--approved takes one question ID (Q- and digits), given once"
```

The behaviour is the same (exit 1, usage suffix). The combined message is accurate for all three causes. It is a small divergence of style only.

**Recommendation:** Optional. Split it to mirror --expect, or leave it.

#### 6. `ANSWER_HEAD` says HEAD for a questions heading, in scripts where HEAD means git's HEAD

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:2068-2072, 2093-2094`; read at `scripts/build-loop.sh:1074, 1082`
**Move:** 2 (naming)
**Confidence:** Medium (a readability call)
**Legibility-target:** for-author

Precedent: "heading" for the questions entry line in scripts/lib/dev-cycle-read.sh:2021 (awk `function heading`), :1980 ("dup (the heading appears more than once)") and scripts/build-loop.sh:1083 ("its heading must read")

Evidence:
```
scripts/lib/dev-cycle-read.sh:2068:ANSWER_HEAD=""
scripts/build-loop.sh:1082:  [[ "$ANSWER_HEAD" == "$1 · $s" ]] \
```

The lib's comments, the awk helper and the refusal text all call this line the "heading". build-loop.sh uses HEAD only in git's sense (the header's "HEAD or rebase or bisect state", the `hd` local in land, "HEAD reflog"). So a reader of approval() could take ANSWER_HEAD for a commit. The name is local to two call sites, which makes renaming cheap now and costly once U4 reads it.

**Recommendation:** Rename it to ANSWER_HEADING (and the awk's `head` to `heading_text`, or similar). Otherwise, keep the "after `### `" comment at the read site in build-loop.sh as well.

#### 7. `TRUTH_WHERE` adds a `_WHERE` suffix that holds a sentence, next to `TRUTH_WHY`, which holds a word

**Severity:** Informational (one tier down from Minor: no existing `_WHERE` global)
**Location:** `scripts/lib/dev-cycle-read.sh:1883-1896`; read at `scripts/dev-cycle.sh:186` and `scripts/lib/dev-cycle-read.sh:1972` (floor_why's walk arm)
**Move:** 2 (naming), 8 (nullability)
**Confidence:** High
**Legibility-target:** for-author

No existing precedent in global variable names of scripts/lib/dev-cycle-read.sh, scripts/build-loop.sh and scripts/dev-cycle.sh (`rg -n '^[A-Z_]*WHERE'`). The suffixes found are `_WHY`, `_OUT`, `_LINE` and `_DONE`.

Evidence:
```
scripts/lib/dev-cycle-read.sh:1890:  TRUTH_WHY=walk; TRUTH_WHERE=""
scripts/lib/dev-cycle-read.sh:1893:    tree) imported_names || { [[ -z "$IMPORTED_WHY" ]] || TRUTH_WHERE="$(walk_why "$IMPORTED_WHY")"; return 0; } ;;
scripts/lib/dev-cycle-read.sh:1972:    walk) echo "the default branch's instruction files could not be walked for @ imports: $TRUTH_WHERE" ;;
```

The lib's own prose already says IMPORTED_MAIN_WHY "says where" (:796), so the name follows the docs. But it holds walk_why's finished sentence, while the paired TRUTH_WHY and the walk globals hold words. The tree walk also leaves TRUTH_WHERE empty for every failure except readers, and empty never happens for the main walk. dev-cycle.sh handles the empty case with `${TRUTH_WHERE:+: …}`. floor_why's walk arm does not, but only the main walk reaches it, and that walk always sets the variable. floor_why also reads the TRUTH_WHERE global, so FLOOR_WHY=walk is not self-describing. The comment at :1960-1962 notes this ("word it before the next truthwalk").

**Recommendation:** None required. If touched, a comment line "TRUTH_WHERE: a sentence, not a word (walk_why's), empty for the tree walk unless readers" beside the declaration at :1888 would make the contract visible where the name is declared.

## What Looks Good

- **Provenance symmetry.** The approved merge keeps `Build-loop-gate: STEM` and adds `Build-loop-approved: Q-NNN`. The reflog and message take the same "build-loop: AUTH of STEM" shape. A `git log --grep '^Build-loop-gate:'` audit keeps finding every gate merge, and the approved ones are distinguished by the extra trailer. The self-merge message is unchanged, so U3a2's consumers do not break (merge bats asserts both).
- **Backward compatibility.** `--check` is untouched: AUTH is empty, so `sm=1` for a self-merge brief exactly as before. `--merge` without `--approved` behaves as it did, except the review-policy refusal now names the flag (row 661). Under `set -u` with an empty APPROVED, the second trailer is guarded by `${2-}`. dev-cycle.sh `--check-answer` output is unchanged (fact-check R4), because ANSWER_AWK's second line is consumed inside check_answer.
- **One authority value.** AUTH is computed once and read by both check_line and land (row 653). The rule set is not re-derived from APPROVED in two places.
- **Skip quoting.** The lib's skip reasons pass through approval verbatim, with the same strip-the-`skip ID: `-prefix pattern used for other quoted skips. A working-tree-only answer is refused as "not answered on the default branch" (plan D8).
- **floor_why / walk_why pairing.** FLOOR_WHY now follows the lib's word-plus-`*_why` convention, reuses TRUTH_WHY's vocabulary, and has walk_why's fallback arm. dev-cycle.sh check_fix's duplicated reader-settings sentence is gone (rows 630, 634).
- **Exact-match heading.** The `"$1 · $s"` comparison follows questions.sh's " · " split grammar (scripts/questions.sh:165), and the refusal prints the exact heading wanted.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Plan's gate-file set includes `skills/dev-cycle/`; GATE_CODE does not | Inconsistent | `scripts/lib/dev-cycle-read.sh:1915`, `scripts/build-loop.sh:1041`; plan:61 | High (divergence) / Medium (intent) |
| 2 | Gate bit and expected slug are not printed before the entry is filed | Minor | `scripts/build-loop.sh:1033, 1083` | High |
| 3 | "merge" answer refused as "not option 1"; catch-all hides the actual word | Minor | `scripts/build-loop.sh:1080`; lib :2011-2016 | High |
| 6 | `ANSWER_HEAD` says HEAD for a heading | Minor | `scripts/lib/dev-cycle-read.sh:2068` | Medium |
| 4 | Two subject phrasings across the approval refusals | Informational | `scripts/build-loop.sh:1078-1083` | High |
| 5 | `--approved` usage message merges count and form | Informational | `scripts/build-loop.sh:314` | High |
| 7 | `TRUTH_WHERE`: new `_WHERE` suffix, holds a sentence | Informational | `scripts/lib/dev-cycle-read.sh:1888` | High |

## Overall Assessment

The flag, exit codes, verdict lines, trailer and reflog all match the conventions U3a2 set, and nothing existing breaks. `--check` and plain `--merge` behave as before apart from the reworded review refusal. The lib cleanups bring FLOOR_WHY in line with the word-plus-`*_why` pattern. The one finding that needs action is the slug contract (Finding 1). The orchestrator U4 builds from the plan would file `merge-gate-` for `skills/dev-cycle/` changes, which this script rejects. The plan also claims F52 covers those changes, but the script lands them under plain `merge-`. That is fixable in place by choosing one gate-file set. Findings 2 and 3 are consumer-contract gaps that cost a re-ask rather than a wrong merge, and both can reasonably be deferred to U4 with a note in its plan bullet. The rest is wording.

## Goal-Alignment Note

Success criterion (verbatim): "a report saved to /workspace/.claude/wt-build-loop-u3a3/docs/reviews/api-consistency-review-2026-10-10-u3a3-i1.md, structured per the api-consistency-reviewer skill, with `Commit: a7a4f784` at the top."

This report is at that path, opens with `Commit: a7a4f784`, and follows the skill's structure: header with Based on, Baseline Conventions, Name-Pattern Audit, Findings with Severity, Location, verbatim Evidence, Confidence and Legibility-target, What Looks Good, Summary Table and Overall Assessment. Every naming finding carries a Precedent or No-existing-precedent line, and Finding 7 is downgraded for having none. It serves the user goal (U3a3 through its review-fix loop and merged locally): one Inconsistent finding (1) is for the fix step, and the rest are Minor or Informational and can be deferred. Nothing was committed.
