Commit: d7cdc1ea

# API Consistency Review — feat/build-loop-u2a4 (U2a4, the self-merge floor)

**Scope:** `git diff main...HEAD` (main = 7afdb8d2, HEAD = d7cdc1ea), in /workspace/.claude/wt-build-loop-u2a4; public surface of scripts/lib/dev-cycle-read.sh and scripts/dev-cycle.sh --check-fix
**Date:** 2026-10-07
**Based on:** docs/reviews/code-fact-check-report-build-loop-u2a4.md (30 claims; 22 verified, 6 mostly accurate, 1 stale, 1 unverifiable)

Probe provenance: one probe, `/tmp/claude-1000/-workspace/f0b98466-dcdf-4fba-b738-6bc01cfddae2/scratchpad/u2a4-api-probe.sh`, run as `timeout 120 bash <probe> $PWD/scripts/lib/dev-cycle-read.sh $PWD/scripts/dev-cycle.sh` from the worktree (exit 0), in a fixture repo under its own `mktemp -d /tmp/u2a4-api-XXXX` (removed after the run). Fixture: `AGENTS.md` holds `see @docs/a.md`; `.claude/commands/c.md` holds `@docs/b.md`; `docs/x.md` is plain; one commit on `main`. Output quoted below as "probe".

## Baseline Conventions

Read from scripts/lib/dev-cycle-read.sh (main and HEAD) and scripts/dev-cycle.sh:

- **Return code + global, word then wording.** A check that refuses answers with a short *word* and a separate function turns the word into a sentence: `main_entry` prints `blob|absent|notfile|notdir PART|badform|error` and `entry_why` words it (plan U2a1: "one shared reason mapping, `entry_why` (rows 228, 306)"); `fence()` records `odd N WHY` in `BRIEF_ODD` and `oddwhy` words it. A global that carries a reason is reset at entry and is empty on the "nothing to report" path: `brief_fields` does `BRIEF=(); BRIEF_ODD=""` first and leaves `BRIEF_ODD` empty on success.
- **Polarity.** Refusal predicates return 0 for "refuse" when a caller tests them under `if`: `isimported` ("A failed walk ... answers imported (0), so a caller testing it with `if` refuses"). Walk functions return 1 on failure ("call them under if or ||").
- **Case.** Predicates over fixed lower-case patterns take the path as given and leave case to the caller (`writable`, `isbrief`, `isclosed`, `pathform`); the one path query that is safety-critical and takes repo text, `isimported`, lowers its own argument ("Whether path $2 (any case) is imported").
- **Argument order.** Name-reference outputs first (`nul_list NAME CMD...`, `main_checkout ENT MEMO PATH`, `import_work OUT TOTAL`); `isimported WALK PATH`, mode before subject.
- **Caller's shell.** Functions that exit through `need_root` or set globals are called in the caller's shell; the header lists them ("inrepo, dirok, skipped, check_brief, isimported and the import walks exit 1 (need_root)").
- **Naming.** Two styles coexist in the lib with no rule between them: run-together (`pathform`, `rawfile`, `plaindir`, `inrepo`, `dirok`, `writable`, `oddwhy`, `isbrief`, `isclosed`, `isimported`) and snake_case (`main_entry`, `entry_why`, `brief_fields`, `import_targets`, `main_imports`, `imported_names`, `need_root`, `lower_all`). Predicates use an `is` prefix. Regex variables are UPPER_SNAKE (`INSTRUCTION_FILE`, `NAMECHARS`, `DIGIT`, `SLUG`).
- **--check-fix output contract** (scripts/dev-cycle.sh:50-55, 79-80): one line per argument, `"ok <path>"` or `"skip <path>: <reason>"`, "and for every path when the import walk fails"; exit 0 when every argument is answered ("a skip is an answer, not an error").

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `isstart` | predicate fn | `isbrief`, `isclosed`, `isimported` | `scripts/lib/dev-cycle-read.sh:194-195`, `:944` | Consistent: `is` + noun, run-together |
| `truthrule` | refusal fn | `pathform`, `writable`, `blocker` | `scripts/lib/dev-cycle-read.sh:141-199` | Consistent (run-together noun); returns a word like `main_entry` |
| `truthwalk LP WALK` | refusal fn | `isimported WALK PATH` | `scripts/lib/dev-cycle-read.sh:944` | Inconsistent argument order (Finding 3) |
| `ownfile LP STEM STATUS` | predicate fn | `isbrief`, `writable` | `scripts/lib/dev-cycle-read.sh:194-199` | Consistent enough (run-together); not `is`-prefixed, but `writable` isn't either |
| `floor PATH STEM STATUS` | refusal fn | `check_brief`, `main_entry` | `scripts/lib/dev-cycle-read.sh:300`, `:381` | Consistent; argument order matches `ownfile` |
| `prompt_dir MAP LP PATH` | map-setter fn | `nul_list NAME ...`, `main_checkout ENT MEMO PATH` | `scripts/lib/dev-cycle-read.sh:746`, `:785` | Consistent: nameref output first; snake_case like `main_checkout` |
| `import_targets DIR [XDIR...]` | parser fn (changed) | its own one-arg form | `scripts/lib/dev-cycle-read.sh:699` (main) | Backward-compatible variadic addition |
| `PROMPT_DIR` | regex var | `INSTRUCTION_FILE`, `NAMECHARS` | `scripts/lib/dev-cycle-read.sh:473`, `:176` | Consistent |
| `GATE_CODE` | regex var | `INSTRUCTION_FILE` | `scripts/lib/dev-cycle-read.sh:473` | Consistent; matches plan D5 item 3's file list |
| `TRUTH_WHY` | reason global | `BRIEF_ODD`, `SKIP_AT` | `scripts/lib/dev-cycle-read.sh:348`, `:140` | Consistent shape; reset rule broken by truthwalk (Finding 1) |
| `FLOOR_WHY` | reason global | `BRIEF_ODD` (word), `entry_why` (wording fn) | `scripts/lib/dev-cycle-read.sh:324-348` | Holds prose, not a word (Finding 5) |

## Findings

#### 1. truthwalk leaves TRUTH_WHY=imported when it returns 1, so after floor answers "allowed" TRUTH_WHY still reads "imported"

**Severity:** Inconsistent
**Location:** `scripts/lib/dev-cycle-read.sh:980-983` (truthwalk, whole function), `:1028-1031` (floor's last arms)
**Move:** 8 (nullability contract), 7 (asymmetry)
**Confidence:** High
**Legibility-target:** for-author

Evidence:

```bash
# scripts/lib/dev-cycle-read.sh:980-983 (whole function)
truthwalk() {
  TRUTH_WHY=walk
  case "$2" in main) main_imports || return 0 ;; tree) imported_names || return 0 ;; *) return 0 ;; esac
  TRUTH_WHY=imported; isimported "$2" "$1"
}
```

Probe: `truthwalk x: 1 TRUTH_WHY=[imported]` and `floor docs/x.md: 1 FLOOR_WHY=[] TRUTH_WHY=[imported]`.

Its sibling `truthrule` resets to `""` and leaves it empty on return 1 (probe: `truthrule Docs/Roadmap.md: 1 []`), and `brief_fields` empties `BRIEF_ODD` on its "nothing to report" path. Its own comment says "Returns 0 when the walk fails (TRUTH_WHY=walk) or reaches LP (TRUTH_WHY=imported), else 1" and is silent on TRUTH_WHY's value at 1. So one global has two reset rules. No current caller reads TRUTH_WHY after a 1 (check_fix goes to `check_path`; floor returns 1 with FLOOR_WHY empty), so nothing is wrong today. But a U2b/U2c caller that tests `[[ -n "$TRUTH_WHY" ]]` after `floor` or `truthwalk`, as check_fix already does after `truthrule` (`elif [[ -n "$TRUTH_WHY" || ...`, scripts/dev-cycle.sh:178), would read an allowed path as imported. That error is in the over-refusing direction, so it is a consistency trap, not a hole.

**Recommendation:** Set `TRUTH_WHY=imported` only on the 0 path (`if isimported "$2" "$1"; then TRUTH_WHY=imported; return 0; fi; TRUTH_WHY=""; return 1`), or document "TRUTH_WHY is meaningful only when truthwalk returns 0".

#### 2. The LP functions disagree on case: truthrule (and isstart, ownfile) silently under-refuse a path that is not lower-cased, while truthwalk and isimported take any case

**Severity:** Inconsistent
**Location:** `scripts/lib/dev-cycle-read.sh:954-975` (truthrule), `:483` (isstart), `:976-983` (truthwalk), `:939-952` (isimported)
**Move:** 3 (consumer contract), 1 (baseline)
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Evidence: truthrule's comment says "for a lower-cased path", and truthwalk's says "the lower-cased path LP", but they behave differently when given a mixed-case path. Probe:

```
truthrule AGENTS.md: 1 []
truthrule agents.md: 0 instr
truthrule Docs/Constraints.md: 1 []
truthwalk DOCS/B.MD: 0 imported
```

truthwalk passes LP on to `isimported`, which does `lp="$(lower "$2")"`. truthrule passes it straight to `isstart`, `writable` and literal compares. Two functions that share a global, carry the same "LP" label and both form the read-as-truth answer therefore differ: one is case-safe, the other is not. When truthrule gets a mis-cased argument, the error falls in the under-reading direction the brief names as the failure class that matters ("an instruction file passing the floor"). Both current callers lower first (check_fix at scripts/dev-cycle.sh:176, floor at :1015), so this is a contract hazard for the next caller, such as U2c's `Self-merge never:` matching or build-loop.sh code calling truthrule directly. It is not a live bug. The safety-critical precedent is `isimported`, which takes "any case". The fact-check's Claim 19 scoped this out: "does not establish that a caller lower-cases before calling (both do)".

**Recommendation:** Pick one rule for the floor family and state it once. Either truthrule lowers its own argument (one `lower` fork, as isimported does), or the gate caller contract gains an item that every truth-family call (`truthrule`, `isstart`, `ownfile`, `prompt_dir`'s LP) takes `lower`'s output and that `floor` is the only entry point taking the stored spelling.

#### 3. truthwalk takes (LP, WALK); isimported, which it wraps, takes (WALK, PATH)

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:976-983`; callers `scripts/dev-cycle.sh:180`, `scripts/lib/dev-cycle-read.sh:1028`
**Move:** 2 (naming/parameter order)
**Confidence:** High
**Legibility-target:** for-author

Precedent: mode-before-subject `isimported WALK PATH` used in `scripts/lib/dev-cycle-read.sh:944` (callers `test/scripts/build-loop-check.bats:21`, `:212`, `:484`)

`truthwalk "$lp" tree` / `truthwalk "$lp" main` sits beside `isimported tree "$lp"`, its own body's call (`isimported "$2" "$1"`), and the old check_fix line it replaced (`elif isimported tree "$lp"`). With only two string arguments, a swapped call (`truthwalk tree "$lp"`) is not caught. The `*) return 0` arm turns it into TRUTH_WHY=walk, a refusal of every path worded as a walk failure: safe, but misleading. truthrule's `LP` first and floor's `PATH STEM STATUS` justify subject-first for the new family, so either order is defensible. The inconsistency is with the function truthwalk wraps.

**Recommendation:** Swap to `truthwalk WALK LP` to match isimported (two call sites), or keep the order and note it in truthwalk's comment ("subject first, as truthrule and floor").

#### 4. A file a prompt (command) file imports is refused with "an instruction file names it" / "an instruction file on the default branch imports it", and the --check-fix header still lists only instruction files

**Severity:** Minor
**Location:** `scripts/dev-cycle.sh:50-55` (header), `:179-182` (skip lines); `scripts/lib/dev-cycle-read.sh:1030`
**Move:** 3 (documentation drift), 4 (error consistency)
**Confidence:** High
**Legibility-target:** for-author

Probe: `docs/b.md`, imported only by `.claude/commands/c.md`, gets `skip docs/b.md: an instruction file names it after an @ (directly or through another import), so it may be read as instructions; file it instead` from --check-fix and `an instruction file on the default branch imports it with @ ...` from floor. Floor's `instr` arm was updated for U2a4 ("an instruction or prompt file, which sessions load from the checkout"), but the import arms of both callers and the --check-fix header ("an instruction file, or a file an instruction file names after an @") were not, so floor now says "instruction or prompt file" in one arm and "instruction file" in the next. The refusal is correct; only the stated reason is narrower than the rule. The header's exclusion list (`human-author/, reviews/, decisions/ ...`) is otherwise still accurate. The fact-check (Claim 2a) confirmed byte-identical output over this repo, which tracks no prompt files.

**Recommendation:** Say "an instruction or prompt file" (or "a start file") in check_fix's import and walk-failure lines, floor's import line, and the header's --check-fix paragraph.

#### 5. FLOOR_WHY carries a finished sentence, not a word, so U2c cannot tell a gate-code refusal (routed to merge-gate-) from the rest without string-matching or re-running GATE_CODE

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:1009-1031`
**Move:** 4 (error consistency), 3 (consumer contract)
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

Precedent: word-plus-wording-function `main_entry` → `entry_why` and `fence` → `BRIEF_ODD="odd N WHY"` → `oddwhy` used in `scripts/lib/dev-cycle-read.sh:268-348`; and truthrule itself returns words (`instr|dot|cycle|settings|user|record`).

`FLOOR_WHY=""  # read by floor's caller (U2c's --check)` is set to prose such as "the gate's own code, which lands only through a merge-gate- review entry". Plan D5 item 3 says a gate-code change "falls to review under a `merge-gate-` entry" and plan step 7 has `--approved` apply "the `merge-gate-` rule", so a consumer must branch on the refusal *kind*. It also folds `cycle` and `settings` into one sentence (`*) FLOOR_WHY="one of the dev cycle's own files"`), so docs/dev-cycle.md is described as a cycle bookkeeping file. Override row 467 deferred a shared main_entry mapping to U2c and row 462 settled that "both callers word" truthrule's words, so this is not a re-open of those. It concerns floor's own output shape, which U2c will consume first. U2c can work around it with `[[ "$lp" =~ $GATE_CODE ]]` (GATE_CODE is a public variable), so the fix is cheap later.

**Recommendation:** Before U2c lands, consider `FLOOR_WORD` (truthrule's words plus `gate`, `thoughts`, `working`, `review`, `walk`, `imported`, `lower`) with a `floorwhy` wording function, as `entry_why` / `oddwhy` do. Or record in U2c's bullet that the caller re-tests GATE_CODE to route merge-gate- entries.

#### 6. The header's list of need_root-exiting functions omits floor and truthwalk

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:17-22` vs `:1011-1014`, `:976-983`
**Move:** 3 (documentation drift)
**Confidence:** High
**Legibility-target:** for-author

The header says "inrepo, dirok, skipped, check_brief, isimported and the import walks exit 1 (need_root) ... Call the exiting checks in the caller's shell". `floor` calls `need_root` directly (`local lp` / `need_root` / `FLOOR_WHY=""`) and `truthwalk` reaches it through the walks. Each has the rule in its own comment ("Run it in the caller's shell, as isimported"; contract item 5 "in this shell"), so a reader of the general header list does not see them. Floor also sets a global (FLOOR_WHY) that `$(floor ...)` would lose, which is the same hazard `brief_fields`' comment spells out ("Call it in the caller's own shell: it sets globals").

**Recommendation:** Add `truthrule, truthwalk and floor` to the header sentence (truthrule for its global, the other two for need_root).

#### 7. floor's "caller contract" leaves two U2b/U2c inputs unspecified: the status letter's form and a deleted path's spelling

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:1001-1010` (floor's comment), `:986-997` (ownfile), `:41-66` (contract)
**Move:** 3 (consumer contract)
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

floor's comment says "$1 is the path as the merge result stores it, $2 the brief's full stem and $3 the diff-tree status letter", and ownfile accepts only `"$3" == A`. `git diff-tree --raw` with rename or copy detection emits `R100` / `C075` plus two paths, and a `D` path is not stored in the merge result at all. The plan's U2b bullet names "the raw `diff-tree` parse with the mode rule" but not `--no-renames`. Both cases fail closed: an `R100` review is never own, and a deleted path is still floored by name. So this only fixes the contract's wording, so that U2b does not have to infer it from ownfile's body. The probe also showed that floor without `resolve_main` answers `the default branch's instruction files could not be walked for @ imports`. That is a safe refusal, but the cause it names is wrong; contract item 1 already requires main found by name.

**Recommendation:** Add to contract item 5: "pass diff-tree's single status letter (run with --no-renames), and for D the path main stores".

## What Looks Good

- **One predicate, two walks.** `isstart` replaces three spellings of the start rule (tree walk basename test, main walk's inline `.claude/rules/` globs, check_fix's `$INSTRUCTION_FILE` on `low`), and `instruction_names` is documented as its prefilter. The fact-check (Claim 22) found the prefilter exactly equal to isstart over 234,256 generated paths.
- **truthrule returns words, not sentences**, matching `main_entry`'s word contract and letting check_fix keep its one long allowlist sentence byte-identical (fact-check Claim 2a: identical --check-fix output over 3,097 paths).
- **import_targets' extension is backward-compatible.** `DIR` stays first and required, extra base directories are variadic, the zero-extra case sets `IT_XDIRS=""` (`nd=0`), and the fact-check (Claim 25) shows identical output and work trailers to main's one-directory form. Every existing one-argument caller and test is unaffected.
- **prompt_dir follows the nameref-first convention** (`nul_list`, `main_checkout`) and keys the map on the stored spelling while matching on LP, the same split `main_imports` keeps between `low[]` and `cand[]`.
- **--check-fix's new skip line keeps the output contract.** `skip $a: the path could not be lower-cased; file it instead` is a `"skip <path>: <reason>"` line, and it ends with "file it instead" like the other filing reasons. On main, a failing `tr` in `lp="$(printf ... | tr ...)"` ended the whole script under `set -e`, so the change also brings that case under the header's exit rule ("every argument answered: a skip is an answer"). $a cannot hold a newline there, because pathform already refused it.
- **Polarity is uniform.** `truthrule`, `truthwalk`, `floor` and `isimported` all return 0 for "refuse", so `if floor ...; then refuse` reads the same as `if isimported ...`.
- **floor's argument order matches ownfile's** (subject, stem, status), and the gate caller contract is numbered and addressable (items 1-7), which U2b/U2c can cite.
- **U2b/U2c can consume floor as specified.** It is callable in the caller's shell with (stored path, full stem, status letter), returns 0 with a non-empty FLOOR_WHY on every refusal path (including lower failure and walk failure), and needs only the contract's duties (main by name, cache clear, order before pathform/main_entry). Findings 1, 5 and 7 are refinements, not blockers.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | truthwalk leaves TRUTH_WHY=imported on return 1 (truthrule resets to "") | Inconsistent | `scripts/lib/dev-cycle-read.sh:980-983` | High |
| 2 | truthrule/isstart/ownfile under-refuse a non-lower-cased path; truthwalk/isimported take any case | Inconsistent | `scripts/lib/dev-cycle-read.sh:954-983`, `:483` | High |
| 3 | truthwalk (LP, WALK) vs isimported (WALK, PATH) argument order | Minor | `scripts/lib/dev-cycle-read.sh:976-983` | High |
| 4 | Prompt-file imports worded as "an instruction file ..."; --check-fix header not updated | Minor | `scripts/dev-cycle.sh:50-55`, `:179-182`; lib `:1030` | High |
| 5 | FLOOR_WHY is prose, not a word; gate-code routing needs string-match or a GATE_CODE re-test | Minor | `scripts/lib/dev-cycle-read.sh:1009-1031` | Medium |
| 6 | Header's need_root/caller's-shell list omits floor, truthwalk (and truthrule's global) | Minor | `scripts/lib/dev-cycle-read.sh:17-22` | High |
| 7 | Contract silent on diff-tree status-letter form (renames) and D paths; no-main worded as walk failure | Informational | `scripts/lib/dev-cycle-read.sh:1001-1010`, `:41-66` | Medium |

## Overall Assessment

The new surface mostly follows the lib's conventions. Refusal predicates return 0 under `if`, truthrule answers in words like main_entry, map setters take the nameref first, regex variables are UPPER_SNAKE, and import_targets grows backward-compatibly. --check-fix's output contract holds, including the new lower-casing skip line, which also turns a former whole-script abort into an answer. Nothing breaks an existing consumer. The two Inconsistent findings concern the floor family's own contract, which U2b/U2c will be the first to consume. TRUTH_WHY's value after a negative truthwalk (Finding 1) is a trap in the over-refusing direction. The LP-case rule (Finding 2) is a trap in the under-reading direction for any future direct caller of truthrule. Both can be fixed in place in a few lines, or settled by one added contract item. The Minor items are wording and ordering, fixable in place. U2b/U2c can consume `floor` as the header contract specifies today.

## Goal-Alignment Note

- Success criterion (restated verbatim): your report saved at the path your task names, structured per your skill, with every finding grounded in verbatim evidence.
- Answered: yes. Saved at the named path with first line `Commit: d7cdc1ea`. Every finding quotes code or probe output, and the naming finding (3) carries a `Precedent:` line, as does Finding 5. The focus list was covered: floor/FLOOR_WHY (5, 6, 7), truthrule/TRUTH_WHY (1, 2), truthwalk (1, 2, 3), isstart (2, audit), prompt_dir and PROMPT_DIR (audit, What Looks Good), GATE_CODE (audit, 5), import_targets (audit, What Looks Good), the --check-fix contract and its new skip line (4, What Looks Good), and U2b/U2c's consumption of floor (5, 7, What Looks Good).
- Out of scope: the test suites were not re-run (the fact-check ran all three green at HEAD); D5 policy choices; override rows 462-467's settled decisions. Row 462 ("both callers word it") and row 467 (main_entry mapping deferred to U2c) were not re-opened, and Finding 5 concerns floor's own output shape.
- Escalate: none blocking. Finding 2 is the one in the brief's under-reading failure class (a hazard for a future direct caller, not a live path). It is worth one contract line or a self-lowering truthrule before U2c.
- Decisions I made: Finding 1 is Inconsistent, not Minor, because the same global has two reset rules within one family and check_fix already reads it with `-n`. Finding 3 is Minor, not Inconsistent, because the new family's subject-first order is itself internally consistent. Fact-check Claims 11 and 24 (stale F11 pointer, `prompt_dirs` typo) are documentation-only and are left to the fact-check rather than duplicated here.
