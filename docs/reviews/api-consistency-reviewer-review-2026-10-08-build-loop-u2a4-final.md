Commit: 2b6f2f91

# API Consistency Review — feat/build-loop-u2a4 final confirming pass (iteration 3)

**Scope:** `git diff main...HEAD` (main = 7afdb8d2, HEAD = 2b6f2f91) in /workspace/.claude/wt-build-loop-u2a4: the public surface of scripts/lib/dev-cycle-read.sh, and scripts/dev-cycle.sh --check-fix
**Date:** 2026-10-08
**Based on:** the Stage 1 summary of code-fact-check-report-build-loop-u2a4-final-r{1,2,3}.md (0 Incorrect; 1 Stale in r1), and iteration 1's docs/reviews/api-consistency-reviewer-review-2026-10-07-build-loop-u2a4.md

Probe provenance: two probes, `scratchpad/u2a4-api-final-probe.sh` and `scratchpad/u2a4-api-final-probe2.sh`, each run under `timeout 120` from the worktree, each in its own `mktemp -d /tmp/u2a4f-api*-XXXX` fixture repo (removed at the end of the run, with no processes left behind). Fixture 1: `AGENTS.md` holds `see @docs/a.md`, `.claude/commands/c.md` holds `@docs/b.md and @"docs/q r.md"`, and `sub/.claude/commands/s.md` holds `@../docs/n.md`. Fixture 2: `AGENTS.md` holds `see @docs/a.md`. Both have one commit on `main`. Output is quoted below as "probe". The suites were not re-run, since Stage 1 ran them green at this HEAD (78/19/78/2/2/53).

## Baseline Conventions

These are unchanged from iteration 1 and were re-checked at HEAD:

- **Word, then wording.** A refusal check answers with a short lower-case word, and a separate step turns the word into prose. `main_entry` → `entry_why`, `fence`'s `BRIEF_ODD` → `oddwhy`, and now `truthrule`/`truthwalk`'s `TRUTH_WHY` → floor's `case` arms and check_fix's lines.
- **Polarity.** Refusal predicates return 0 when they refuse (`isimported`, `truthrule`, `truthwalk`, `floor`). The walks return 1 when they fail.
- **Argument order.** A nameref output comes first (`nul_list NAME`, `main_checkout ENT MEMO PATH`, `prompt_dir MAP LP PATH`, `prompt_bases NAME LP PATH`). A mode comes before its subject (`isimported WALK PATH`, `truthwalk WALK PATH`).
- **Case.** Fixed-pattern predicates take an already lower-cased path (`writable`, `isbrief`, `isstart`, `ownfile`). Entry points that receive repo text lower-case it themselves (`isimported`, `floor`, check_fix).
- **Caller's shell.** Functions that exit through `need_root` or set globals are named in the header, or in their own comment.
- **Names.** Functions use two styles: run-together (`isstart`, `truthrule`, `ownfile`) and `import_*` snake_case (`import_targets`, `import_home`, `import_work`, now `import_reset`). Regex variables are UPPER_SNAKE (`INSTRUCTION_FILE`, `PROMPT_DIR`, `GATE_CODE`). Reason globals are `*_WHY` or `BRIEF_ODD`.
- **--check-fix output contract** (scripts/dev-cycle.sh:50-55): one `ok <path>` or `skip <path>: <reason>` line per argument, including "for every path when the import walk fails"; exit 0.

## Iteration 1 findings: do the fixes hold?

| i1 # | Disposition (rubric) | Holds at 2b6f2f91? | Evidence |
|---|---|---|---|
| 1 truthwalk left TRUTH_WHY=imported on 1 | A4 Fixed | Yes | `TRUTH_WHY=imported; isimported "$1" "$2" \|\| { TRUTH_WHY=""; return 1; }`. Probe: `truthwalk tree x: 1 []`, `floor [docs/x.md]: 1 FLOOR_WHY=[] TRUTH_WHY=[]` |
| 2 LP functions disagree on case | A5 Fixed | Yes for truthrule (probe: `truthrule [Docs/X.md]: 0 case`). isstart and ownfile still under-read mixed case, as contract item 8 says; see Finding 4 for prompt_dir | contract item 8 at lib:67 |
| 3 truthwalk (LP, WALK) order | C9 Fixed | Yes: `truthwalk WALK PATH` at lib:1007, `truthwalk tree "$lp"` at dev-cycle.sh:180, `truthwalk main "$lp"` in floor | — |
| 4 "an instruction file names it" for prompt imports; header | C10 header fixed, skip wording kept | Partly. Header fixed (dev-cycle.sh:53). floor's import arm is not covered by the stated reason and has no row | Finding 1 |
| 5 FLOOR_WHY is prose | C11 Deferred, override row 472 | Row is right: trigger U2c, paired with row 376's IMPORTED_MAIN_WHY | — |
| 6 need_root list omits floor, truthwalk | C12 Fixed | Yes: "check_brief, isimported, truthwalk (for tree or main), floor and the import walks exit 1 (need_root)" (lib:18). truthrule's global is noted in its own comment ("Run both in the caller's shell: they set TRUTH_WHY") | — |
| 7 status letter, D paths, floor before resolve_main | C13: letter documented; rest Won't-Fix (row 473) | Yes, and it fails closed. Floor's comment says "the diff-tree status letter alone (R for R100; only A makes a review the brief's own)". Probe: `floor R100: 0 [a review record ...]`, `floor working empty stem: 0 [a working file that is not this brief's own ...]` | — |

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `floor PATH STEM STATUS` | refusal fn | `check_brief`, `main_entry`, `isimported` | `scripts/lib/dev-cycle-read.sh:302`, `:383`, `:969` | Consistent: 0 = refuse, need_root, sets a `*_WHY` global |
| `FLOOR_WHY` | reason global | `BRIEF_ODD`, `TRUTH_WHY` | `scripts/lib/dev-cycle-read.sh:351-383`, `:989` | Prose, not a word: deferred by row 472 (right) |
| `truthrule LP` | refusal fn | `writable`, `pathform`, `main_entry` (words) | `scripts/lib/dev-cycle-read.sh:179-201`, `:302` | Consistent |
| `TRUTH_WHY` words `instr dot cycle settings user record case walk imported` | enum | `main_entry`'s `blob absent notfile notdir badform error` | `scripts/lib/dev-cycle-read.sh:302-326` | Consistent: lower-case single words. `case` is a bash keyword, but it is only a string and the floor `case` arm parses (tests green) |
| `truthwalk WALK PATH` | refusal fn | `isimported WALK PATH` | `scripts/lib/dev-cycle-read.sh:969` | Consistent (fixed since i1) |
| `isstart LP` | predicate | `isbrief`, `isclosed`, `isimported` | `scripts/lib/dev-cycle-read.sh:196-197` | Consistent |
| `prompt_dir MAP LP PATH` | map setter | `nul_list NAME`, `main_checkout ENT MEMO PATH` | `scripts/lib/dev-cycle-read.sh:771`, `:810` | Consistent order. Name collides with `PROMPT_DIR` except for case (Finding 5) |
| `prompt_bases NAME LP PATH` | array setter | `nul_list NAME`, `lower_all` | `scripts/lib/dev-cycle-read.sh:771-776` | Consistent |
| `PROMPT_DIR` | regex var | `INSTRUCTION_FILE`, `NAMECHARS` | `scripts/lib/dev-cycle-read.sh:483` | Consistent (UPPER_SNAKE) |
| `GATE_CODE` | regex var | `INSTRUCTION_FILE` | `scripts/lib/dev-cycle-read.sh:483` | Consistent; matches plan D5 item 3 |
| `import_reset` | cache fn | `import_home`, `import_work`, `import_targets` | `scripts/lib/dev-cycle-read.sh:717-753` | Consistent `import_*` family; a second, older statement of the duty remains (Finding 2) |
| `import_targets DIR [XDIR...]` | parser fn (changed) | its one-argument form on main | `scripts/lib/dev-cycle-read.sh:724` | Backward-compatible variadic. Its grammar paragraph is stale (Finding 3) |
| `ownfile LP STEM STATUS` | predicate | `writable`, `isbrief` | `scripts/lib/dev-cycle-read.sh:196-201` | Consistent |

## Findings

#### 1. floor words every import refusal as "an instruction file on the default branch imports it", although its own `instr` arm and the --check-fix header now say "instruction or prompt file"; C10's disposition covers check_fix's line only, and no override row records floor's

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:1046` vs `:1059`; `test/scripts/build-loop-check.bats:35`; rubric C10
**Move:** 4 (error consistency), 3 (documentation drift)
**Confidence:** High
**Legibility-target:** for-author

Evidence:

```bash
      instr) FLOOR_WHY="an instruction or prompt file, which sessions load from the checkout" ;;
...
    else FLOOR_WHY="an instruction file on the default branch imports it with @ (directly or through another import)"; fi
```

Probe: `docs/b.md` is imported only by `.claude/commands/c.md`, and `docs/n.md` only by `sub/.claude/commands/s.md`. Floor answers `floor [docs/b.md]: 0 FLOOR_WHY=[an instruction file on the default branch imports it with @ ...]` for the first, and the same text for `docs/n.md` and `docs/q r.md`. The refusal is right; the stated cause is narrower than the rule. As fact-check r3 notes, it also covers checkout-only importers, which are not "on the default branch". Rubric C10 justifies keeping the old wording as "skip wording kept (pinned by dev-cycle.bats)". That holds for check_fix's line (dev-cycle.bats:1027-1097). Floor's string, though, is pinned only by this branch's own `IMP=` at build-loop-check.bats:35, so the rationale does not reach it. Every other deferred or declined Consider item from iteration 1 (C5-C8, C11, C13-C17) has a row dated 2026-10-07 in the override log, and C10 has none. Floor has no caller yet, so U2c's --check will be the first to print this string to a user.

**Recommendation:** Reword floor's import line, for example "an instruction or prompt file (on the default branch or in the checkout) imports it with @ ..." with its `IMP=` test string, which costs two lines. Alternatively, add a row for C10's floor half with U2c as its trigger, beside row 472.

#### 2. The cache block comment still tells a caller to assign IMPORTED_MAIN_DONE="" (and both caches on a HOME change), beside contract item 4's import_reset, which also names IMPORT_OUT_MAX and IMPORT_WORK_MAX; the duty is stated twice, differently

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:543-548` vs `:55-57` (contract item 4) and `:554-555`
**Move:** 3 (documentation drift), 7 (asymmetry)
**Confidence:** High
**Legibility-target:** for-author

Evidence:

```bash
# whose files it read, so a caller whose checkout may have changed (a file
# added or edited) sets IMPORTED_MAIN_DONE="" to walk again, and a cached
# error returns 1 again. A caller that changes HOME clears both
# IMPORTED_DONE and IMPORTED_MAIN_DONE (both caches are keyed without it).
```

versus contract item 4: "Call import_reset before each gate decision and after any checkout change (rows 372, 439), or when HOME, IMPORT_OUT_MAX or IMPORT_WORK_MAX changes: neither walk's cache key holds them."

The header calls the contract "the one statement of it". Iteration 1's A3 (architecture F1) added `import_reset` precisely so that a caller would not reset the cache by assigning a variable by name. The pre-existing block comment, which this branch edited nearby (`prompt_bases' directories`, :540), still prescribes the by-name assignment. It also omits the two budget variables. Both mechanisms have the same effect today, so nothing is wrong at runtime. But a U2b author who reads the walk's own comment rather than the header gets the older, narrower rule.

**Recommendation:** Replace the two sentences with a pointer: "a caller clears the cache with import_reset (contract item 4)".

#### 3. The superset paragraph, the "one statement" of the parser's grammar that A5 and F11 point to, omits the quoted run and the further base directories, and pins 2.1.292 where the new quoted-run comment cites 2.1.293

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:593-617` vs `:579-582`, `:668-672`
**Move:** 3 (documentation drift); builds on fact-check r1 Stale
**Confidence:** High
**Legibility-target:** for-author

Evidence: "each prefix of the run after it, up to the first blank ... is a candidate name" and "made absolute (ROOT_REAL/$1/name unless it starts with /)". The code, however, also reads `names(line, i + 2, L, 1)` after `@"`, "up to the closing quote, blanks included", and resolves against `dirs[0..nd]` (`for (i = 0; i <= nd; i++) put(root "/" dirs[i] "/" c)`). The function's own lead paragraph (:579-582) was updated for the extra directories, and the paragraph that claims to be the one statement was not. The code reads more than the text says, which is the safe direction, so this is wording only. The version pin also differs: the claim says "every name Claude Code 2.1.292 can import", while the quoted-run comment says "the prompt-mention reader of Claude Code 2.1.293 accepts". That leaves the paragraph's revisit trigger ("Re-check the superset when Claude Code changes its import grammar") anchored to a version older than one of its own rules.

**Recommendation:** Add the quoted run and "against $1 and each further directory" to the paragraph, and name both versions (2.1.292's import regex, 2.1.293's mention reader).

#### 4. Contract item 8 names truthrule, isstart and ownfile as the lower-cased-path functions; prompt_dir and prompt_bases also match LP against lower-case patterns and under-read silently when it is not lower-cased

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:67-68` (item 8), `:489`, `:495-503`
**Move:** 3 (consumer contract)
**Confidence:** High
**Legibility-target:** for-author

Probe: `isstart mixed: 1` and `prompt_dir mixed: 0 entries` for `.Claude/Commands/z.md`. Both walks call these helpers with `lower`'s output (`lp="$(lower "$f")"`, `low[i]`), and each helper's comment says "LP lower-cased", so nothing is live. Item 8 is the contract's list of functions that need a lower-cased argument, and it is one function pair short. truthrule now catches the gap for itself (`case`); the walk helpers do not.

**Recommendation:** Extend item 8 to "truthrule, isstart, ownfile, prompt_dir and prompt_bases", or leave it, since the two are walk-internal.

#### 5. `PROMPT_DIR` (regex) and `prompt_dir` (map setter) share one name, differing only in case

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:484`, `:489`
**Move:** 2 (naming)
**Confidence:** Medium
**Legibility-target:** for-author

Precedent: a regex variable and the functions that use it have distinct names: `INSTRUCTION_FILE` used by `isstart`/`instruction_names`, and `UTF8_WELL_FORMED`, `GATE_CODE` used by `floor`, in `scripts/lib/dev-cycle-read.sh`

Bash keeps variables and functions in separate namespaces, so this works. But `prompt_dir pdir "$lp" "$f"` and `"$2" =~ $PROMPT_DIR` sit on adjacent lines, and a reader searching for "prompt_dir" case-insensitively lands on both. With the precedent the severity would be Minor; it is downgraded to Informational because the cost is readability only.

**Recommendation:** Optional: name the setter for what it records (for example `prompt_mark`), or leave it.

#### 6. The lib's opening summary of what it holds does not mention the floor or the read-as-truth rule

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:2-6`
**Move:** 3 (documentation drift)
**Confidence:** High
**Legibility-target:** for-author

Evidence: "the output scrub, the plain-file and path-form rules, the cycle's own file names, the Markdown shapes the readers refuse (FENCE_AWK), the brief, branch and answer checks, the instruction-file import walks, and the default branch." The unit's main export (`floor`, `truthrule`/`truthwalk`, `GATE_CODE`) is not listed, and the walks now start from prompt files as well. The numbered contract further down does name floor.

**Recommendation:** Add "the read-as-truth rule and the self-merge floor", and "instruction and prompt file import walks".

## What Looks Good

- **The --check-fix output contract holds.** Every argument gets one `ok`/`skip <path>: <reason>` line, exit 0 (probe `rc=0`). The new `skip $a: the path could not be lower-cased; file it instead` follows the filing-reason form. The cycle-file branch still says "(use --check-write)" (probe: `skip docs/roadmap.md: one of the cycle's own files (use --check-write)`), and settings, user, record, dot and instr fall to the one allowlist sentence exactly as before (probe: `docs/dev-cycle.md`, `.claude/commands/c.md`). Stage 1 found --check-fix byte-identical to main over all 3,104 tracked paths. Moving the cycle test from `writable "$a" || writable "$lp"` to `truthrule "$lp"` changes no answer: no `writable` pattern is a dot path or an instruction name, and `$a` with an upper-case letter could not have matched `writable`'s lower-case patterns.
- **U2b/U2c can consume floor exactly as the contract says.** Floor runs in the caller's shell with (stored path, full stem, single status letter). It returns 0 with a non-empty FLOOR_WHY on every refusal arm, including lower failure, `case`, walk failure and an empty stem (probe: `floor working empty stem: 0 [...]`), and returns 1 with both FLOOR_WHY and TRUTH_WHY empty (probe). Item 5's order (floor before pathform and main_entry, refuse the branch on other main_entry words) and item 4's `import_reset` are callable as stated, and the test at build-loop-check.bats:1198 pins the reset. The only open seam for U2c is row 472's word-versus-prose question, which is correctly deferred.
- **truthrule's word set extends main_entry's style.** Lower-case single words, with `case` added as a fail-closed word for a caller that skipped item 8. Both callers map them, and floor maps `case` to the same reason as a failed `lower`, which is consistent.
- **`import_targets` stays backward-compatible.** `DIR` is still first and required, the extras are variadic, `IT_XDIRS` survives `""` through the x prefix, and probe `import_targets "" "sub"` emits both bases per prefix.
- **`prompt_bases` keeps the stored spelling while matching on LP** (probe: `bases: [][A][A/.claude/B]` for `A/.claude/B/.claude/commands/x.md`), the same `low[]`/`cand[]` split main_imports uses.
- **truthwalk's unknown WALK answers `walk` without need_root** (probe `truthwalk bogus: 0 [walk]`), matching `isimported`'s `*) return 0`, and the header now says "truthwalk (for tree or main)".

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | floor's import reason says "an instruction file on the default branch" for prompt and checkout importers; C10's "pinned by dev-cycle.bats" does not cover it; no override row | Minor | `scripts/lib/dev-cycle-read.sh:1059` | High |
| 2 | Cache comment still prescribes `IMPORTED_MAIN_DONE=""` / clearing both vars; contract item 4 says import_reset and adds the two budgets | Minor | `scripts/lib/dev-cycle-read.sh:543-548` | High |
| 3 | Superset paragraph ("the one statement") omits the quoted run and the extra bases; 2.1.292 vs 2.1.293 | Minor | `scripts/lib/dev-cycle-read.sh:593-617` | High |
| 4 | Contract item 8 omits prompt_dir/prompt_bases, which under-read on mixed case | Informational | `scripts/lib/dev-cycle-read.sh:67`, `:489-503` | High |
| 5 | `PROMPT_DIR` vs `prompt_dir` name collision (case only) | Informational | `scripts/lib/dev-cycle-read.sh:484-489` | Medium |
| 6 | Lib opening summary omits the floor and the read-as-truth rule | Informational | `scripts/lib/dev-cycle-read.sh:2-6` | High |

## Overall Assessment

The branch's public surface is consistent with the lib's conventions, and nothing is Breaking or Inconsistent. Iteration 1's two Inconsistent findings (TRUTH_WHY's reset, truthrule's case rule) and its argument-order and header findings are fixed and hold under probe. The rows for the deferred FLOOR_WHY shape (472) and the Won't-Fix contract gaps (473) are correct. --check-fix keeps its output contract, and floor can be consumed by U2b/U2c exactly as the numbered contract states. All three Minor findings are wording drift between two statements of the same rule. In each case the code does more (refuses more, resets the same) than the stale text says, so none of them is in the under-read class. Finding 1 is the one that touches the rubric's own bookkeeping: C10's floor half has neither a fix nor a row.

## Goal-Alignment Note
- Success criterion (restated verbatim): your report saved at the path your task names, structured per your skill, with every finding grounded in verbatim evidence.
- Answered: yes. Saved with first line `Commit: 2b6f2f91`. It covers every focus item (floor, FLOOR_WHY, truthrule, TRUTH_WHY including `case`, truthwalk, isstart, prompt_dir, prompt_bases, PROMPT_DIR, GATE_CODE, import_reset, import_targets, the --check-fix contract, U2b/U2c consumption), plus iteration 1's fixes and its deferred rows.
- Out of scope: the suites were not re-run (Stage 1 ran them at this HEAD); prompt_bases' `.claudex` prefix over-read and the 2,000-quote budget case (behavioural, over-read only, Stage 1's); settled rows 462-475 were not re-opened.
- Escalate: Finding 1 is a bookkeeping gap: C10's floor half needs either the two-line rewording or an override row before merge.
- Decisions I made: Finding 2 is Minor rather than Informational because the header claims to be "the one statement" and A3's fix was specifically about by-name resets. Finding 5 uses a Precedent line but is still Informational, because it costs readability only.
