Commit: db9cc040

# Code Fact-Check Report

**Repository:** /workspace (worktree /workspace/.claude/wt-build-loop-u2a, branch feat/build-loop-u2a)
**Scope:** full branch diff `git diff main...HEAD` at db9cc040 (final confirming pass, replicate r3 of k=3): `scripts/lib/dev-cycle-read.sh`, `scripts/dev-cycle.sh`, `scripts/build-loop.sh`, `skills/dev-cycle/SKILL.md`, `docs/working/plan-build-loop-handoff.md`, `docs/working/known-issues-dev-cycle.md`, `docs/reviews/override-log.md` (rows 321-334), `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a.md` (iteration-2 section), `test/lib/build-loop-fixtures.bash`, `test/scripts/{build-loop-check,dev-cycle,build-loop-read}.bats`, and the branch's commit messages (`git log main..HEAD`: four commits, cfbf34d2, b9ffe7a8, 36b79f72, db9cc040). The other added review reports were read as the rubric's sources only.
**Checked:** 2026-10-06
**Total claims checked:** 43
**Summary:** 30 verified, 9 mostly accurate, 0 stale, 4 incorrect, 0 unverifiable

Hallucination log: `docs/reviews/hallucination-patterns.md` (8 entries) was read; no claim below matches a logged pattern, and none of the Incorrect verdicts is a fabricated symbol, so the log is not updated.

Execution provenance (all runs from cwd `/workspace/.claude/wt-build-loop-u2a` unless noted; outputs under the scratch dir `S=/tmp/claude-1000/-workspace/f2b09f27-e8e1-48a1-9e62-9ab10d974ed8/scratchpad/review-u2a/fc3r3/`):

- **E1** `timeout 900 bats test/scripts/build-loop-check.bats test/scripts/dev-cycle.bats test/scripts/build-loop-read.bats` · exit 0 · 2026-10-06T06:55:39Z-06:56:03Z · 97 `ok`, 0 `not ok` · output `$S/bats.out`.
- **E2** `timeout 300 bash $S/adv.sh` (adversarial trees C1-C7 built with `git mktree -z` in throwaway repos under `$S/repos/`, each answered by the lib's `floor` with `LC_ALL=C`, `resolve_main`, `ROOT_REAL=$(pwd -P)`) · exit 0 · 2026-10-06T06:57:48Z · output `$S/adv.out`; the C1 re-run dumping `IMPORTED_MAIN` (`|docs/b.md|`, `isimported secret rc=1`) was run inline at ~06:58Z.
- **E3** `timeout 120 bash $S/more.sh` (two same-named trees, a blob and a tree sharing a name, isimported with an unknown walk name and with ROOT_REAL unset, ignored files in `ls-files --others`) · exit 0 · ~2026-10-06T07:01Z · output `$S/more.out`.
- **E4** walk parity and timing on this repo: `main_imports` and `imported_names` sets compared at HEAD (3 entries each, `SAME`), at b9ffe7a8 and 36b79f72 (libs extracted with `git show` to `$S/lib-*.sh`; `same: 3` each); `main_imports` timed 3x with `$EPOCHREALTIME`: 0.379 / 0.384 / 0.387 s · exit 0 · 2026-10-06T06:59:45Z · sets in `$S/tree.set`, `$S/main.set`.
- **E5** size gate: `git diff --numstat A...B -- ':(top)' ':(top,exclude)docs/' | awk '{ n += $1 + $2 } END { print n+0 }'` (pr-prep 1a): main...b9ffe7a8 = 393, main...36b79f72 = 417, main...db9cc040 = 479 · exit 0 · ~07:00Z.
- **E6** mutation of 36b79f72's guards: `git archive 36b79f72 scripts test` into `$S/c36`, each guard replaced by `:`, `timeout 300 bats -f 'lists twice' test/scripts/build-loop-check.bats` (cwd `$S/c36`): regex guard removed → `not ok 1`, listed guard removed → `not ok 1`, unmutated → `ok 1` · ~07:02Z.

---

## Claim 1: "Reports (all `Commit: 36b79f72`): `code-fact-check-report-build-loop-u2a.md` (25 claims: 16 Verified, 5 Mostly accurate, 3 Incorrect, 1 Unverifiable), `security-reviewer-...` (3 Medium, 1 Informational), `performance-reviewer-...` (1 Low, 1 Informational), `api-consistency-reviewer-...` (1 Inconsistent, 4 Minor, 3 Informational), `architecture-review-...` (5 Minor, 2 Informational ...)"

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a.md:36`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the commit lines and verdict/severity counts of the five iteration-2 reports and the rubric's FC claim citations (11, 15b, 16a Incorrect; 9b, 12, 16c, 16f Mostly accurate; 5b Unverifiable); does not establish that every iteration-2 finding is routed (FC Claim 3, Mostly accurate, appears in no rubric row).
**Legibility-target:** for-orchestrator-synthesis

The fact-check report's header reads `**Total claims checked:** 25` / `**Summary:** 16 verified, 5 mostly accurate, 0 stale, 3 incorrect, 1 unverifiable` (`docs/reviews/code-fact-check-report-build-loop-u2a.md:11-12`), and a `**Verdict:**` tally gave 16/5/3/1. `**Severity:**` greps of the four critic reports gave security Medium x3 + Informational, performance Low + Informational, api Inconsistent + Minor x4 + Informational x3, architecture Minor x5 + Informational x2. Each file starts `Commit: 36b79f72`. FC Claim 3 ("Rubric line citations ... `:443-445`, `:502-510`", Mostly accurate) has no rubric row (paraphrased — no quote available because the claim covers absence: no rubric line names FC 3).

**Evidence:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a.md:36-52`, `docs/reviews/code-fact-check-report-build-loop-u2a.md:1-12`, the four critic reports' `**Severity:**` lines

---

## Claim 2: "every name goes into one map, a doubled name of any kind fails the walk"

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a.md:40`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers names that `ls-tree -r` lists twice (same path, any mode) and same-named entries the walk later reads; does not establish a failure for a tree holding two same-named entries whose recursive listing never repeats a path.
**Legibility-target:** for-author

The guard rejects a repeated path in the recursive listing:

```bash
# scripts/lib/dev-cycle-read.sh:521-523
    f="${BASH_REMATCH[2]}"
    [[ -z "${ent[$f]+set}" ]] || return 1
    ent[$f]="${BASH_REMATCH[1]}"
```

E3 built a root tree with `docs` twice (two trees, children `a.md` and `b.md`) and `z` twice (a blob and a tree): `ls-tree -r` lists `docs/a.md`, `docs/b.md`, `z`, `z/a.md`, each once, and `main_imports` returned `walk rc=0`. The doubled names fail the walk only when it reads beneath them (E2 C3/C4: `fatal: path 'docs/b.md' does not exist`, floor answers the walk-failure reason), so it still fails closed where it matters. Precise wording: "a path the listing names twice, of any mode, fails the walk; other same-named entries fail it when read".

**Evidence:** `scripts/lib/dev-cycle-read.sh:517-525`, `$S/more.out`, `$S/adv.out` (C3, C4)

---

## Claim 3: "| C2-C11 | api 4, 6, 7; performance F1, F2; architecture 2, 3, 6; security F3 residue, F4; FC 5b | ... | Override rows dated 2026-10-06 (`feat/build-loop-u2a`) |"

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a.md:52`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the mapping of the listed sources to override rows 324-334; does not establish anything about the rows' content (Claims 4-5).
**Legibility-target:** for-author

The label C2-C11 names ten items, but the source list has eleven entries (3 api + 2 performance + 3 architecture + 2 security + 1 FC) and the branch adds eleven rows in db9cc040 (`git show --numstat db9cc040 -- docs/reviews/override-log.md` → `11`; rows `:324-:334`). Security F4 and architecture 7 share row `:333`, so the eleven sources fill eleven rows, not ten. Precise version: "C2-C12" or eleven rows.

**Evidence:** `docs/reviews/override-log.md:324-334`

---

## Claim 4: Override rows 324-331 and 333: entry_why repeats the path; floor and isimported both lower-case; one cat-file per instruction blob, "45 files here"; the start-file rule spelled in both walks with no parity test; check_fix and floor spell shared denials separately; floor covers D5 items 1-4 only; untracked starts come from the checkout the script runs in

**Location:** `docs/reviews/override-log.md:324-331`, `docs/reviews/override-log.md:333`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each row's statement about the code and the 45-file count; does not establish the timing figures (~1 ms per lower, ~3-4 ms per cat-file, ~4 s at 1,000 files), which were not measured.
**Legibility-target:** for-orchestrator-synthesis

`check_brief` prints `echo "skip $a: $(entry_why "$e" "$a")"` (`scripts/lib/dev-cycle-read.sh:355`) and `entry_why` prints `notfile) echo "$2 is not a regular file on the default branch"` (`:288`), so the path appears twice (the dev-cycle.bats expectation at `test/scripts/dev-cycle.bats:1039` shows it). `floor` runs `lp="$(lower "$1")"` (`:604`) and `isimported` runs `lp="$(lower "$2")"` (`:569`). The m-arm reads `git cat-file blob "$MAIN_SHA:$f" | import_targets "$d"` per queue item (`:545`). Main holds 45 instruction-file names by INSTRUCTION_FILE and none under `.claude/rules/` (E4-era count: `45`, `0`). A grep of `test/scripts/*.bats` for "agree|parity" finds only the T31 brief tests, none comparing walks (paraphrased — no quote available because the claim covers absence of a test). `check_fix`'s denials sit at `scripts/dev-cycle.sh:179-181`, floor's at `scripts/lib/dev-cycle-read.sh:605-615`. Floor's comment says "Floor item 5, symlinks and gitlinks, is the caller's mode rule" (`:597-598`). `untracked_md` runs `git ls-files -z --others` in the current checkout (`:484`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:285-293`, `:355`, `:484`, `:545`, `:567-575`, `:591-618`, `scripts/dev-cycle.sh:172-186`, `test/scripts/dev-cycle.bats:1039`

---

## Claim 5: "The gate walk still misses paths through a symlinked directory, other names on a case-insensitive checkout, absolute imports into the repo, and a backslash or trailing-`_` token form"

**Location:** `docs/reviews/override-log.md:332`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four named gaps (each confirmed by the code's token and resolution rules) and the row's completeness as the deferred residue; does not establish exploitability, since every gap needs the shape on main.
**Legibility-target:** for-author

The four named gaps are real (`IMPORT_RE='(^|[^[:alnum:]])@[^][:space:]\\#\`()]+'` ends a token at `\`, `:461`; `while [[ "$t" == *[.,\;:!?*_~] ]]; do t="${t%?}"; done` strips a trailing `_`, `:470`; `[[ ... "$t" != /* ]] || continue` drops absolute imports, `:471`). The row is the deferral record for the walk's residue but omits three more shapes that E2 shows passing the floor: a start-file path holding newlines that poisons the walk's `seen` set (C1, `docs/secret.md: -`), a symlink whose text ends in a newline (C2, `docs/leak.md: -`), and a symlink whose text is absolute into the repo (C5, `deep2.md: -`; code `[[ "$out" != /* ]] || continue`, `:548`). See Claims 19b and 19c.

**Evidence:** `scripts/lib/dev-cycle-read.sh:461-475`, `:546-550`, `:558`, `$S/adv.out` (C1, C2, C5)

---

## Claim 6: "The gate's walk (`main_imports`, U2a) closes A2 and A3's symlinked-file half for the self-merge floor (symlinked start files and targets are followed, `.claude/rules/` starts), but not paths through a symlinked directory, other names one file has on a case-insensitive checkout, or absolute imports into the repo; and its untracked start files come from the checkout the gate runs in."

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the walk's handling of relative symlink text, `.claude/rules/` starts and the named residue; does not establish closure for symlinks with absolute text or text ending in a newline, nor for newline-named start paths.
**Legibility-target:** for-author

Relative symlinked starts, chains and loops are followed (E2 C5: `deep.md`, `l2.md`, `real.md`, `la.md`, `lb.md` all refused; test 5 refuses `real.md` and `docs/b.md` through `CLAUDE.md -> real.md`), and a nested `.claude/rules/sub/x.md` starts (E2 C6: `docs/rr.md` refused). But the symlinked-file half is not wholly closed: absolute symlink text is skipped (`[[ "$out" != /* ]] || continue`, `scripts/lib/dev-cycle-read.sh:548`; E2 C5: `deep2.md: -`) and a text ending in a newline is followed to a different path (Claim 19c). The listed residue omits those and the `seen` poisoning (Claim 19b).

**Evidence:** `scripts/lib/dev-cycle-read.sh:546-550`, `test/scripts/build-loop-check.bats:133-152`, `$S/adv.out`

---

## Claim 7: F10 row: "Floor item 4 (lib `floor`): `docs/decisions/`, `docs/thoughts/`, `docs/human-author/`, `docs/constraints.md`, the cycle files, other briefs' working docs and reviews; own files keyed on the full brief stem. `check_fix` keeps its own list: it now refuses `docs/constraints.md` too but still fixes `docs/thoughts/`"

**Location:** `docs/working/plan-build-loop-handoff.md:125`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers floor's item-4 arms and check_fix's constraints/thoughts behavior; does not establish U2c's use of floor.
**Legibility-target:** for-orchestrator-synthesis

Floor: `elif [[ "$lp" == docs/constraints.md ]]` (`:612`), `elif [[ "$lp" =~ ^docs/(decisions|thoughts|human-author)/ ]]` (`:613`), working and review arms via `ownfile "$lp" "$2" "$3"` (`:614-615`). check_fix refuses `"$lp" == docs/constraints.md` (`scripts/dev-cycle.sh:181`) and its regex `^docs/(working|human-author|reviews|decisions)/` omits thoughts (`:180`). E1 passes `"skip docs/Constraints.md: in-cycle fixes edit only" "ok docs/thoughts/t.md"` (`test/scripts/dev-cycle.bats:1026`) and floor test 1's `docs/thoughts/x.md "$REC"`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:602-618`, `scripts/dev-cycle.sh:172-186`, `$S/bats.out`

---

## Claim 8: F11 row: "Floor item 1 walks main's commit (`main_imports`, U2a: one NUL-safe listing, symlinks followed, `.claude/rules/` and the checkout's untracked instruction files as starts). Gaps: known issue A4 (symlinked directories, case-insensitive names, absolute imports), and the untracked starts come from the checkout `--check` runs in"

**Location:** `docs/working/plan-build-loop-handoff.md:126`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the listing (`mapfile -d ''`), starts and named gaps; does not establish that the walk as a whole is newline-safe or that every symlink is followed.
**Legibility-target:** for-author

The listing is NUL-separated: `mapfile -d '' recs < <(git ls-tree -r -z --full-tree "$MAIN_SHA"; printf 'rc=%s' "$?")` (`scripts/lib/dev-cycle-read.sh:515`). The row is "partly", but its gap list is incomplete: the walk's `seen` set is newline-joined (`seen+="${cand[i]:2}"$'\n'`, `:535`), so a newline-named start path can hide a target's imports (Claim 19b), and absolute or newline-terminated symlink texts are not followed as written (Claim 19c).

**Evidence:** `scripts/lib/dev-cycle-read.sh:509-561`, `$S/adv.out`

---

## Claim 9: "**U2 split (2026-10-06).** U1 measured four units against a planned one, and U2 carries about twenty override rows, so it lands as three stacked units: U2a ... (one `ls-tree -r`, then each instruction blob), started from main's instruction files plus the checkout's untracked ones (they can only add refusals) ..."

**Location:** `docs/working/plan-build-loop-handoff.md:273-277`
**Type:** Reference / Architectural
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the U1 unit count, the override-row count with U2 revisit triggers on main, and U2a's described content; does not establish the U2b/U2c contents, which are future.
**Legibility-target:** for-author

`git log --oneline main` names U1a, U1b, U1c and U1d (four units). Rows on main with a `Revisit trigger:` naming U2 number 26 (30 rows mention U2 at all), so "about twenty" undercounts by about a quarter (paraphrased — no quote available because the figure comes from a grep count over `git show main:docs/reviews/override-log.md`). U2a's described walk matches the code at HEAD except that U2a also starts at `.claude/rules/` files (`f == .claude/rules/*.md`, `scripts/lib/dev-cycle-read.sh:534`), which the note predates.

**Evidence:** `docs/working/plan-build-loop-handoff.md:273-277`, `docs/reviews/override-log.md` (main), `scripts/lib/dev-cycle-read.sh:530-537`

---

## Claim 10: build-loop.sh header: "Markup that adds letters (a checked task box, a tag) can still hide a copy"; "A tip on a branch not ahead of main ... is working"; main_file's refusals through entry_why

**Location:** `scripts/build-loop.sh:44`, `scripts/build-loop.sh:65`, `scripts/build-loop.sh:133`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the copy-count letter rule, the ahead test before the marker read, and main_file's refusal wording; does not establish --settings output beyond the bats coverage.
**Legibility-target:** for-orchestrator-synthesis

The settings pass keeps only letters, case folded ("everything but letters is dropped and case folded", `scripts/build-loop.sh:144`), so `- [ ]` adds no letters and `- [x]` adds `x`. `loop=working` then `if [[ "$ahead" -gt 0 ]]; then kind="$(marker_kind "$sha")"` (`:352-353`): a tip with zero commits ahead stays working. main_file: `*) FILE_WHY="$(entry_why "$e" "$f")"; return 1 ;;` (`:133`).

**Evidence:** `scripts/build-loop.sh:40-46`, `:62-66`, `:126-137`, `:143-150`, `:340-361`

---

## Claim 11: check_fix header and design comment: refuses "constraints.md (the user's: plan D2)"; isimported tree replaces the IMPORTED read

**Location:** `scripts/dev-cycle.sh:49-54`, `scripts/dev-cycle.sh:167-171`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the constraints refusal, its reason text and the import arm; does not establish the tree walk's own known gaps (A2/A3).
**Legibility-target:** for-orchestrator-synthesis

`|| "$lp" == docs/dev-cycle.md || "$lp" == docs/constraints.md || "$a" == */.* ...` (`scripts/dev-cycle.sh:181`) with the skip text naming `constraints.md` (`:182`), and `elif isimported tree "$lp"; then` (`:183`). Plan D2 says of `docs/constraints.md`: "Creating the doc is your work" (`docs/working/plan-build-loop-handoff.md:50`). E1 passed the check-fix test.

**Evidence:** `scripts/dev-cycle.sh:172-186`, `docs/working/plan-build-loop-handoff.md:43-52`, `$S/bats.out`

---

## Claim 12: "the instruction-file import walks, the self-merge floor, and the default branch" / "A change here must pass test/scripts/dev-cycle.bats and build-loop.sh's suites (build-loop-*.bats)"

**Location:** `scripts/lib/dev-cycle-read.sh:6`, `scripts/lib/dev-cycle-read.sh:10-11`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the lib's contents list and that the named suites pass at HEAD; does not establish other suites.
**Legibility-target:** for-orchestrator-synthesis

Both walks (`imported_names`, `main_imports`) and `floor` are defined at `:486` and `:509`, `:602`. `ls test/scripts/build-loop-*.bats` lists `build-loop-check.bats` and `build-loop-read.bats`; E1 ran both plus dev-cycle.bats: 97 ok.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1-11`, `$S/bats.out`

---

## Claim 13: "inrepo, dirok, skipped, check_brief, isimported, floor and the import walks exit 1 (need_root) unless ROOT_REAL is set"

**Location:** `scripts/lib/dev-cycle-read.sh:15-17`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers floor, both walks and isimported's `tree`/`main` arms; does not hold for isimported's unknown-name arm.
**Legibility-target:** for-author

`floor()` runs `need_root` first (`:603`) and both walks do (`:489`, `:512`); E3 with ROOT_REAL unset: `floor CLAUDE.md` and `isimported main x` print "ROOT_REAL is not set" and exit. But `isimported` reaches need_root only through a walk: `*) return 2 ;;` (`:573`), so E3's `isimported bogus x` with ROOT_REAL unset printed `isimported bogus no-root rc=2` and did not exit. It is still a refusal, so nothing fails open. Precise version: "isimported (for tree or main)".

**Evidence:** `scripts/lib/dev-cycle-read.sh:93-97`, `:567-575`, `:602-603`, `$S/more.out`

---

## Claim 14: "Inputs: check_brief, check_branch, check_answer, main_entry and brief_fields read the default branch's commit, never the working tree ..., and so does floor (its import walk also starts from the checkout's untracked instruction files)"

**Location:** `scripts/lib/dev-cycle-read.sh:30-34`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what floor's walk reads; does not establish the other functions' inputs (unchanged on this branch).
**Legibility-target:** for-author

Besides the untracked starts, the walk reads any checkout file an import names when main lacks it: `if [[ -n "${ent[$p]+set}" ]]; then queue+=("m:$p"); else queue+=("t:$p"); fi` (`:559`), then `inrepo_here "$f" || continue; out="$(import_targets "$d" < "$f")"` (`:541`), tracked or not (E2 C7: `n2.md`, reached through an untracked note, is refused). Precise version: "...also starts from the checkout's untracked instruction files and reads checkout files main lacks".

**Evidence:** `scripts/lib/dev-cycle-read.sh:538-561`, `$S/adv.out` (C7)

---

## Claim 15: "inrepo for a caller that has run need_root itself (a walk, per path)."

**Location:** `scripts/lib/dev-cycle-read.sh:124-125`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers inrepo_here's body and its three callers; does not establish blocker's own semantics (unchanged).
**Legibility-target:** for-orchestrator-synthesis

`inrepo() { need_root; inrepo_here "$1"; }` and `inrepo_here() { [[ -z "$(blocker "$1" file)" && -f "$1" ]]; }` (`:123-125`). Its other callers, `imported_names` (`:491`, `:499`) and `main_imports` (`:541`), each run `need_root` at their top (`:489`, `:512`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:123-125`, `:486-502`, `:509-541`

---

## Claim 16: isclosed "spells the closed/ rule once (row 292)"

**Location:** `scripts/lib/dev-cycle-read.sh:162`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers code uses of the closed/ path in scripts/ and scripts/lib/; does not establish prose copies elsewhere.
**Legibility-target:** for-orchestrator-synthesis

`isclosed() { [[ "$1" == docs/working/briefs/closed/* ]] && isbrief "docs/working/briefs/${1#docs/working/briefs/closed/}"; }` is the only non-comment code line naming `briefs/closed` in `scripts/*.sh scripts/lib/*.sh` (grep); `writable` (`:165`), `check_brief` (`:345`) and `shared_branches` (`scripts/build-loop.sh:318`) call it.

**Evidence:** `scripts/lib/dev-cycle-read.sh:162-167`, `:345`, `scripts/build-loop.sh:318`

---

## Claim 17: main_entry: "badform (a path pathform refuses: a .git* part such as .gitattributes, say) or error (no default branch found by name, ls-tree failed, or the tree lists a name twice ...). Only blob reads the file, and only absent means there is none ... It runs main_by_name and pathform itself, before any read"

**Location:** `scripts/lib/dev-cycle-read.sh:251-265`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the word set and check order; does not establish callers' handling beyond entry_why (Claim 18).
**Legibility-target:** for-orchestrator-synthesis

`if ! main_by_name; then echo error; return; fi` / `if ! pathform "$1"; then echo badform; return; fi` (`:269-270`) precede the ls-tree (`:272`). pathform refuses `[.][gG][iI][tT]*` parts (`:152`). E1's test "main_entry answers badform for a path pathform refuses, absent for a plain missing one" expects `absent` then six `badform` lines including `.gitattributes` and `.github/x.yml` and passes.

**Evidence:** `scripts/lib/dev-cycle-read.sh:144-154`, `:266-283`, `test/scripts/dev-cycle.bats:1335-1345`, `$S/bats.out`

---

## Claim 18: "Why main_entry's word $1 for path $2 is not a file to read, for a skip line." (entry_why; db9cc040 A9 "an explicit error arm; the default names the word")

**Location:** `scripts/lib/dev-cycle-read.sh:284-293`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the five arms and the three callers' use; does not establish wording consistency with FLOOR_WHY (deferred, row 326).
**Legibility-target:** for-orchestrator-synthesis

Arms: `notdir\ *)`, `notfile)`, `badform)`, `error) echo "the tree of the default branch could not be read" ;;`, `*) echo "the default branch answered $1 for $2" ;;` (`:286-291`). Callers: check_brief `:355`, check_answer `:714`, main_file `scripts/build-loop.sh:133`. E1's updated expectations (`dev-cycle.bats:1039`, `:1195`, `:1223-1225`) pass.

**Evidence:** `scripts/lib/dev-cycle-read.sh:284-293`, `:355`, `:714`, `scripts/build-loop.sh:133`, `$S/bats.out`

---

## Claim 19a: "main_imports walks the default branch's commit instead, for floor: it starts at every instruction file stored there (and every .md under .claude/rules/, which Claude Code also loads), plus the checkout's untracked ones"

**Location:** `scripts/lib/dev-cycle-read.sh:445-447`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the start set for blob, symlink and nested-rules starts, and untracked starts; does not establish that every start's imports are then followed (Claim 19b).
**Legibility-target:** for-orchestrator-synthesis

Candidates are every `*.md` record (`[[ "$f" != *.[mM][dD] ]] || cand+=("m:$f")`, `:524`) and every untracked `.md` (`:529`), kept when `"${f##*/}" =~ $INSTRUCTION_FILE || "$f" == .claude/rules/*.md` on the lower-cased name (`:534`; `[[ == ]]`'s `*` crosses `/`). E2: nested `.claude/rules/sub/x.md` starts (C6), a symlinked start is followed (C5), a start under a directory whose name holds a tab is read (`a<TAB>b/docs/t.md` refused), and an untracked `CLAUDE.local.md` starts (C7). A gitlink named `CLAUDE.md` is skipped (`*) continue ;;`, `:551`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:517-537`, `$S/adv.out` (C5, C6, C7)

---

## Claim 19b: "and follows an import into the file main stores at that path, whatever its name"

**Location:** `scripts/lib/dev-cycle-read.sh:447-448`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the walk's follow step for a target main stores; does not establish how likely such tree shapes are on a real main (they need a crafted commit on main).
**Legibility-target:** for-author

The walk follows a target only when it is not already in `seen`, and `seen` is a newline-joined string into which start paths go unescaped:

```bash
# scripts/lib/dev-cycle-read.sh:535 (start loop) and :556-559 (follow step)
      seen+="${cand[i]:2}"$'\n'; queue+=("${cand[i]}")
...
      IMPORTED_MAIN+="$(lower "$p")"$'\n'
      [[ "$seen" != *$'\n'"$p"$'\n'* ]] || continue
      seen+="$p"$'\n'
      if [[ -n "${ent[$p]+set}" ]]; then queue+=("m:$p"); else queue+=("t:$p"); fi
```

E2 C1: main stores `CLAUDE.md` (`@docs/b.md`), `docs/b.md` (`@secret.md`), `docs/secret.md`, and a start file at `q<LF>docs/b.md<LF>r/CLAUDE.md` (directories `q<LF>docs` and `b.md<LF>r`). The start path puts `<LF>docs/b.md<LF>` into `seen`, so `docs/b.md` is listed but never read: `IMPORTED_MAIN` is `|docs/b.md|`, `isimported main docs/secret.md` returns 1, and floor prints `[docs/secret.md]: -`. The control tree without the extra directory refuses `docs/secret.md`. Separately, a file named `..x.md` that main stores is never followed: `import_targets` drops any resolved path matching `[[ "$p" != ..* ]] || continue` (`:473`), so its import `hid.md` passes floor (E2 C5, `[hid.md]: -`). The listing itself is NUL-safe (Claim 23); the walk's bookkeeping is not.

**Evidence:** `scripts/lib/dev-cycle-read.sh:463-476`, `:509-561`, `$S/adv.out` (C1, C5 last case)

---

## Claim 19c: "a symlink there is followed to the path its text names"

**Location:** `scripts/lib/dev-cycle-read.sh:448-449`, `scripts/lib/dev-cycle-read.sh:546`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the 120000 arm for relative, absolute and newline-terminated text; does not establish how the checkout's OS or Claude Code treats absolute text from another root.
**Legibility-target:** for-author

```bash
# scripts/lib/dev-cycle-read.sh:546-550
        120000)  # a symlink: its text names the file read, as one more import
          if ! out="$(git cat-file blob "$MAIN_SHA:$f")" || [[ "$out" == *$'\n'* ]]; then IMPORTED_MAIN=error; return 1; fi
          [[ "$out" != /* ]] || continue
          out="$(realpath -ms --relative-to="$ROOT_REAL" -- "$ROOT_REAL/${d:+$d/}$out" 2>/dev/null)" || continue
          [[ "$out" != ..* ]] || continue ;;
```

`$(...)` strips trailing newlines before the newline test, so a text `docs/x.md<LF>` is followed as `docs/x.md`, not the stored file `docs/x.md<LF>` the OS link names. E2 C2: `CLAUDE.md -> "docs/x.md\n"`, with `docs/x.md<LF>` importing `@leak.md`: floor refuses `docs/x.md` (a file that does not exist) and passes `docs/leak.md`. An inner newline does fail the walk (E2 C2b). Absolute text is skipped without failing (E2 C5: `AGENTS.md -> $R/real2.md`, `real2.md: -`, `deep2.md: -`), and the comment's "Not covered" list names absolute imports, not absolute symlink text.

**Evidence:** `scripts/lib/dev-cycle-read.sh:538-561`, `$S/adv.out` (C2, C5)

---

## Claim 19d: "A target main does not have is read from the checkout when it is a plain file there. Reading the checkout can only add refusals."

**Location:** `scripts/lib/dev-cycle-read.sh:449-450`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the t-arm and that checkout reads only append to IMPORTED_MAIN; does not establish behavior when a checkout file changes between calls (the cache is keyed on commit and root only).
**Legibility-target:** for-orchestrator-synthesis

`if [[ "$src" == t ]]; then inrepo_here "$f" || continue; out="$(import_targets "$d" < "$f")"` (`:541`); results only append (`IMPORTED_MAIN+=`, `:556`), and a failed checkout read leaves `out` empty rather than failing the walk (paraphrased — no quote available because this follows from the assignment's status being unchecked on `:541`, read through `:561`). E2 C7: untracked `CLAUDE.local.md -> n1.md -> n2.md` refuses both; under a symlinked directory only the plain path (`real/n3.md`) is refused.

**Evidence:** `scripts/lib/dev-cycle-read.sh:538-561`, `$S/adv.out` (C7)

---

## Claim 19e: "Not covered (known issues A2/A3): a path through a symlinked directory, other names that one file has on a case-insensitive checkout, and absolute imports."

**Location:** `scripts/lib/dev-cycle-read.sh:450-452`
**Type:** Reference / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three listed gaps and the cited issue IDs; does not establish exploitability.
**Legibility-target:** for-author

The three gaps are real (absolute imports: `"$t" != /*`, `:471`). The citation is off: the known-issues file's row for this walk is A4 (`docs/working/known-issues-dev-cycle.md:18`, "The gate's walk (`main_imports`, U2a) ... but not paths through a symlinked directory, other names ..., or absolute imports"); A2 (rules and symlinked starts) is closed for this walk, and the case-insensitive gap appears only in A4. The list also omits the shapes in Claims 19b and 19c (newline-poisoned `seen`, `..`-prefixed names, absolute or newline-terminated symlink text), plus the backslash and trailing-`_` token forms override row 332 names.

**Evidence:** `scripts/lib/dev-cycle-read.sh:445-454`, `docs/working/known-issues-dev-cycle.md:16-18`, `docs/reviews/override-log.md:332`

---

## Claim 19f: "Its result is cached for the commit and root in IMPORTED_MAIN_DONE."

**Location:** `scripts/lib/dev-cycle-read.sh:452-453`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the cache key and the cached failure; does not establish invalidation on checkout changes.
**Legibility-target:** for-orchestrator-synthesis

`[[ "$IMPORTED_MAIN_DONE" == "$MAIN_SHA $ROOT_REAL" ]] && { [[ "$IMPORTED_MAIN" != error ]]; return; }` then `IMPORTED_MAIN=error; IMPORTED_MAIN_DONE="$MAIN_SHA $ROOT_REAL"` (`:513-514`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:513-514`

---

## Claim 20: "UTF-8 spaces that end an import token, as a blank does: U+00A0, U+1680, U+2000-200A, U+2028/2029, U+202F, U+205F and U+3000."

**Location:** `scripts/lib/dev-cycle-read.sh:456-460`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the 18 byte sequences and the cut in both C and C.UTF-8 locales; does not establish that Claude Code ends tokens at exactly these characters.
**Legibility-target:** for-orchestrator-synthesis

Decoding `UNI_SPACES` with python gave 18 entries equal to `[0xa0, 0x1680, 0x2000..0x200a, 0x2028, 0x2029, 0x202f, 0x205f, 0x3000]` (`True 18`); these are every Zs character above U+0020 plus Zl/Zp. `import_targets` on `@docs/nb.md<NBSP>for @a<U+3000>b @c<U+200A>d.md.` printed `docs/nb.md|a|c|` under both `LC_ALL=C` and `LC_ALL=C.UTF-8` (inline run ~06:59Z, output in this paragraph).

**Evidence:** `scripts/lib/dev-cycle-read.sh:456-460`, `:465-476`

---

## Claim 21: "The import targets in the text on stdin, for a file in directory $1 ("" at the top level): one repo-relative path per line, case kept."

**Location:** `scripts/lib/dev-cycle-read.sh:463-464`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers output shape and case; does not establish that every path Claude Code would load is printed (`..`-prefixed names are dropped, Claim 19b).
**Legibility-target:** for-orchestrator-synthesis

`p="$(realpath -ms --relative-to="$ROOT_REAL" -- "$ROOT_REAL/${1:+$1/}$t" 2>/dev/null)"` then `printf '%s\n' "$p"` (`:472-474`); no lower-casing in the function. E2/Claim 20 runs show one path per line.

**Evidence:** `scripts/lib/dev-cycle-read.sh:465-476`

---

## Claim 22: instruction_names "matches INSTRUCTION_FILE's names; the walk's own test stays the authority. LC_ALL=C makes -i ASCII-only." / untracked_md: "--others without --exclude-standard already lists ignored files"

**Location:** `scripts/lib/dev-cycle-read.sh:477-484`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the prefilter's superset relation and the ignored-file listing; does not establish case-insensitive path-glob behavior on other git versions.
**Legibility-target:** for-orchestrator-synthesis

The grep `(^|/)((claude|agents?|gemini)(\.[a-z0-9_-]+)?|skill)\.md$` (`:481`) matches INSTRUCTION_FILE's alternatives (`:432`); `imported_names` re-tests `$INSTRUCTION_FILE` per path (`:491`). E3: with `ign.md` in `.gitignore`, `git ls-files --others` listed `ign.md`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:432`, `:477-492`, `$S/more.out`

---

## Claim 23: "The main walk; returns 1, with IMPORTED_MAIN set to "error", when the commit's tree cannot be listed whole, lists a name twice (git would read the first copy, whatever its mode) or a blob cannot be read ... The listing stays NUL-separated as git writes it (a name may hold a newline), with its exit status after the last NUL."

**Location:** `scripts/lib/dev-cycle-read.sh:503-508`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the listing parse, its exit-status check, the doubled-path guard and blob-read failures; does not establish newline safety of the walk's `seen` bookkeeping after the listing (Claim 19b).
**Legibility-target:** for-orchestrator-synthesis

`mapfile -d '' recs < <(git ls-tree -r -z --full-tree "$MAIN_SHA"; printf 'rc=%s' "$?")` / `[[ "${recs[-1]}" == rc=0 ]] || return 1` (`:515-516`); per record the mode/type/id regex and `[[ -z "${ent[$f]+set}" ]] || return 1` (`:519-522`); blob reads `|| { IMPORTED_MAIN=error; return 1; }` under `set -o pipefail` (`:510`, `:545`). E1's tests 3-4 pass (missing blob; doubled `a.md`, doubled symlink+blob `AGENTS.md`, doubled `z.txt`; forged newline records read). git reads the first copy: a tree with `120000 AGENTS.md` before `100644 AGENTS.md` resolves `<tree>:AGENTS.md` to the symlink blob (inline check). IMPORTED_MAIN is `error` on each `return 1` because `:514` sets it before the parse and `:538` replaces it only after.

**Evidence:** `scripts/lib/dev-cycle-read.sh:509-561`, `test/scripts/build-loop-check.bats:82-131`, `$S/bats.out`

---

## Claim 24: "Returns 0 imported, 1 not, 2 when the main walk failed or $1 is neither (fail closed: a caller that tests it with `if` refuses). Run it in the caller's shell: the walk exits through need_root and caches its result."

**Location:** `scripts/lib/dev-cycle-read.sh:563-566`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers return codes and floor's reading of them; does not establish other future callers' handling of 2.
**Legibility-target:** for-orchestrator-synthesis

`main) main_imports || return 2; [[ "$IMPORTED_MAIN" == *$'\n'"$lp"$'\n'* ]] ;;`, `tree) imported_names; ...`, `*) return 2 ;;` (`:571-573`). E3: `isimported bogus x` → `rc=2`. floor: `elif rc=0; isimported main "$lp" || rc=$?; [[ "$rc" -ne 1 ]]; then if [[ "$rc" -eq 2 ]]; then FLOOR_WHY="the default branch's instruction files could not be walked ..."` (`:608-609`); E1 test 3 shows the walk-failure reason.

**Evidence:** `scripts/lib/dev-cycle-read.sh:567-575`, `:608-610`, `$S/more.out`, `$S/bats.out`

---

## Claim 25: ownfile: "its working docs, docs/working/{research,plan,checkpoint,handoff,test-strategy}-STEM.md, and a review it adds, docs/reviews/STEM.md or docs/reviews/NAME-STEM.md (a modified or deleted review is never its own)"

**Location:** `scripts/lib/dev-cycle-read.sh:576-581`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the working-doc regex, the A-only review rule and the empty stem; does not establish status handling for working docs (any status owns them, which the comment does not restrict).
**Legibility-target:** for-orchestrator-synthesis

`[[ -n "$2" ]] || return 1`, the working regex with `"${BASH_REMATCH[2]}" == "$2"`, and `[[ "$3" == A && "$1" == docs/reviews/* && "$b" != */* && ( "$b" == "$2.md" || "$b" == *"-$2.md" ) ]]` (`:584-586`). E1 test 2 covers added, deleted, nested, other-stem and empty-stem cases.

**Evidence:** `scripts/lib/dev-cycle-read.sh:582-587`, `test/scripts/build-loop-check.bats:66-80`

---

## Claim 26: "The gate's own code: main's copy runs the next merge (plan D6), so a change to it lands only through a merge-gate- review entry, never a self-merge."

**Location:** `scripts/lib/dev-cycle-read.sh:588-590`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the regex and its D5/D6 rationale; does not establish the merge-gate- path, which is U3.
**Legibility-target:** for-orchestrator-synthesis

`GATE_CODE='^scripts/(build-loop|dev-cycle|questions)\.sh$|^scripts/lib/'` covers D5 item 3's four files ("`scripts/build-loop.sh`, `scripts/dev-cycle.sh`, `scripts/questions.sh`, `scripts/lib/dev-cycle-read.sh` ... falls to review under a `merge-gate-` entry", plan `:71`) and the rest of `scripts/lib/`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:588-590`, `docs/working/plan-build-loop-handoff.md:71`

---

## Claim 27: floor: "(plan D5): a changed path that a self-merge never lands ... Returns 0 with FLOOR_WHY set when the floor refuses, else 1. Paths compare lower-cased ... Floor item 5, symlinks and gitlinks, is the caller's mode rule"; reasons for D5 items 1-4

**Location:** `scripts/lib/dev-cycle-read.sh:591-618`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers floor's arms, return codes and lower-casing against D5 items 1-4; does not establish the completeness of the import arm, which inherits Claims 19b-19c.
**Legibility-target:** for-orchestrator-synthesis

Arms in order: INSTRUCTION_FILE (item 1), `"/$lp" == */.*` (item 2), `$GATE_CODE` (item 3), `isimported main` (item 1's imports), `writable`/`docs/dev-cycle.md`, `docs/constraints.md`, decisions/thoughts/human-author, other working docs and reviews (item 4), `else return 1; fi` (`:605-617`). Plan D5 items 1-4 (`docs/working/plan-build-loop-handoff.md:69-72`) match. E1 test 1 passes 48 paths (37 refused, 11 passed), with mixed-case inputs (`Docs/Roadmap.md`, `Scripts/Build-Loop.sh`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:591-618`, `docs/working/plan-build-loop-handoff.md:66-73`, `test/scripts/build-loop-check.bats:33-64`

---

## Claim 28: SKILL.md: "a tracked `.md` file under `docs/` (not ... `docs/dev-cycle.md`, `docs/constraints.md`, a dot-directory or dotfile, an instruction file, or a file an instruction file imports with `@` ...)"

**Location:** `skills/dev-cycle/SKILL.md:72-75`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the added constraints.md clause against check_fix; does not establish the rest of the skill.
**Legibility-target:** for-orchestrator-synthesis

Matches `scripts/dev-cycle.sh:181` (`"$lp" == docs/constraints.md`) and E1's `skip docs/Constraints.md` expectation.

**Evidence:** `skills/dev-cycle/SKILL.md:72-77`, `scripts/dev-cycle.sh:181`

---

## Claim 29: "An inherited GIT_DIR (a run from a git hook, say) would send every fixture command to that repo instead of the throwaway one."

**Location:** `test/lib/build-loop-fixtures.bash:11-13`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the unset list; does not establish other inherited git env (e.g. GIT_CEILING_DIRECTORIES).
**Legibility-target:** for-orchestrator-synthesis

`unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES` (`:13`); git honors GIT_DIR over the cwd's repository (paraphrased — no quote available because this is git's documented environment behavior, not repo code).

**Evidence:** `test/lib/build-loop-fixtures.bash:8-16`

---

## Claim 30: build-loop-check.bats header, helper comments and test titles 1-5 (e.g. "a name the tree lists twice fails the walk; a name holding a newline, even one shaped like a record, is read"; "A start file listed twice (a symlink first, which git reads)"; "floor follows what Claude Code loads: symlinks, any name main stores, the checkout's files, .claude/rules/, a token ended by a Unicode space")

**Location:** `test/scripts/build-loop-check.bats:3-6`, `test/scripts/build-loop-check.bats:13-21`, `test/scripts/build-loop-check.bats:33-152`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each title and comment against its body and E1's pass; does not establish the broader properties the titles gesture at ("any name main stores" fails for C1 and `..x.md`, Claim 19b).
**Legibility-target:** for-orchestrator-synthesis

Test 4 asserts `[ "$(git ls-tree -r -z --name-only main | tr -cd '\0' | wc -c)" -eq 2 ]` and `want docs/d.md "$IMP"` / `want docs/p.md "$IMP"` (`:127-130`); git's read of the doubled `AGENTS.md` resolves to the symlink (Claim 23). Test 1's comment "a working-tree edit of a tracked one does not (main's copy decides)" (`:40-41`) holds: `docs/wt-only.md` is in `pass`. E1: all 5 pass.

**Evidence:** `test/scripts/build-loop-check.bats:1-152`, `$S/bats.out`

---

## Claim 31: Edited tests: dev-cycle.bats ("main_entry answers badform for a path pathform refuses, absent for a plain missing one (U1d, U2a)", the inventory, the check-fix constraints/thoughts comment, entry_why wording) and build-loop-read.bats (T7 comment "one commit on top of base, with its tree"; the split chains and `git replace -d`)

**Location:** `test/scripts/dev-cycle.bats:1013-1029`, `test/scripts/dev-cycle.bats:1079-1087`, `test/scripts/dev-cycle.bats:1335-1345`, `test/scripts/build-loop-read.bats:297`, `test/scripts/build-loop-read.bats:436-440`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers titles/comments against bodies and E1's pass; does not establish that the inventory lists every lib global (it lists the new ones).
**Legibility-target:** for-orchestrator-synthesis

The T7 commit is built as `tree <base^{tree}>` / `parent <base>` (`build-loop-read.bats:298`), one commit on base with its tree. The inventory adds `isclosed entry_why isimported ownfile floor inrepo_here main_imports import_targets instruction_names untracked_md` and `GATE_CODE UNI_SPACES` / `IMPORTED_MAIN IMPORTED_MAIN_DONE FLOOR_WHY` (`dev-cycle.bats:1083-1087`). E1: 97 ok.

**Evidence:** `test/scripts/dev-cycle.bats`, `test/scripts/build-loop-read.bats`, `$S/bats.out`

---

## Claim 32: cfbf34d2 message: lib-level floor tests; "main_entry answers badform for refused forms, with an absent positive control (row 320)"; "--check-fix refuses docs/constraints.md and still fixes docs/thoughts/ (row 204)"; "the three fixture && chains split, :436 followed by a standalone git replace -d (row 317)"; "bl_setup unsets GIT_DIR and the other repo-locating variables (row 314)"

**Location:** `git log cfbf34d2`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the statements not already settled by override rows 322-323 (the "walk failing closed (... a tree listing a name twice ...)" and "these fail until the U2a code commit" clauses, Accepted-immutable); does not re-verdict those.
**Legibility-target:** for-orchestrator-synthesis

`:436` names main's line `git replace ... && git config core.useReplaceRefs true` (`git show main:test/scripts/build-loop-read.bats` line 436), split at cfbf34d2 with `git replace -d` at its line 440; the three split chains are the replace, the CRLF brief and the odd-dir chains (diff of `build-loop-read.bats`). The other items match Claims 29 and 31.

**Evidence:** `test/scripts/build-loop-read.bats:436-440`, `test/scripts/build-loop-read.bats:466-475`, `test/lib/build-loop-fixtures.bash:13`

---

## Claim 33: b9ffe7a8 message: floor's list (plan D5 items 1-4); "a failed listing or a main_entry error fails closed (row 308). Agrees with the working-tree walk on this repo."; "the main walk does not follow a target whose name pathform refuses (parity gap with the tree walk, documented). 393 changed code lines."

**Location:** `git log b9ffe7a8`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the statements as of b9ffe7a8 (later reworked); does not establish that b9ffe7a8's walk started at every start file (iteration 1's R1 refuted that, fixed since).
**Legibility-target:** for-orchestrator-synthesis

At b9ffe7a8: `out="$(git ls-tree -r -z --full-tree "$MAIN_SHA" | instruction_names | tr '\0' '\n')" || return 1` and `error) IMPORTED_MAIN=error; return 1 ;;` on `main_entry`, and the comment "a target pathform refuses is listed, not followed" (`git show b9ffe7a8:scripts/lib/dev-cycle-read.sh`, main_imports). E4: b9ffe7a8's lib gives `same: 3` against the tree walk. E5: main...b9ffe7a8 = 393.

**Evidence:** `scripts/lib/dev-cycle-read.sh` at b9ffe7a8 (`:496-530`), `$S/lib-b9ffe7a8.sh`

---

## Claim 34a: 36b79f72 subject and R1: "the main import walk fails closed on split or doubled start files" / "Every record must now start with a mode, a type and an object id, and any name listed twice (any mode) fails the walk."

**Location:** `git log 36b79f72`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the subject's fail-closed claim at 36b79f72; does not apply to HEAD, where db9cc040 replaced the newline-joined parse.
**Legibility-target:** for-author

At 36b79f72 the parse still ran `tr '\0' '\n'` and only anchored the record's start (`[[ "$rec" =~ ^[01234567]{6}\ [abcdefghijklmnopqrstuvwxyz]+\ [0123456789abcdef]{40,64}$'\t' ]] || return 1`), so a directory name holding a newline whose halves both look like records split past the guard. Iteration 2's fact-check verdicted this Incorrect (Claim 16a, probes P8/P8b), and HEAD's test 4 now pins the fixed shape. No override row covers this commit message (rows 322-323 cover cfbf34d2 only); it is immutable history superseded by db9cc040 (paraphrased — no quote available because the claim covers absence of a row in `docs/reviews/override-log.md`).

**Evidence:** `$S/c36/scripts/lib/dev-cycle-read.sh` (36b79f72 main_imports), `docs/reviews/code-fact-check-report-build-loop-u2a.md` (Claim 16a)

---

## Claim 34b: 36b79f72: "Tests: both shapes in build-loop-check.bats; deleting either guard fails the test." and A1-A4

**Location:** `git log 36b79f72`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two-guard mutation and A1 (need_root first), A3 (constraints reason), A4 (FLOOR_WHY comment) at HEAD; does not re-verdict A2's comment, which db9cc040 rewrote.
**Legibility-target:** for-orchestrator-synthesis

E6: removing the regex guard → `not ok 1`; removing the listed guard → `not ok 1`; unmutated → `ok 1`. HEAD: `need_root` first in floor (`:603`), `FLOOR_WHY="the user's constraints doc, which every loop prompt carries"` (`:612`), `FLOOR_WHY=""  # read by floor's caller (U2c's --check)` (`:600`).

**Evidence:** `$S/c36/test/scripts/build-loop-check.bats:98`, `scripts/lib/dev-cycle-read.sh:600-612`

---

## Claim 35a: db9cc040 R1: "The listing now stays NUL-separated (mapfile -d '', ls-tree's exit status after the last NUL); every name goes into one map, and a name listed twice, of any kind, fails the walk. Test 4 reads a plain and a forged newline name."

**Location:** `git log db9cc040`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the listing, map and doubled-path guard as stated ("listed twice"); does not establish newline safety past the listing (Claim 19b) or failure for doubled names the listing does not repeat (Claim 2).
**Legibility-target:** for-orchestrator-synthesis

Same code as Claim 23 (`:515-523`); test 4's newline section at `test/scripts/build-loop-check.bats:119-130` passes in E1.

**Evidence:** `scripts/lib/dev-cycle-read.sh:515-523`, `test/scripts/build-loop-check.bats:98-131`

---

## Claim 35b: db9cc040 A5/A7: "import targets are followed through main's map whatever their name (.github/, a+b.md)" / "symlinked start files and targets are followed to the path their text names"

**Location:** `git log db9cc040`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two stated guarantees; the named examples (`.github/`, `a+b.md`, relative symlinks) do work (test 5).
**Legibility-target:** for-author

Same defects as Claims 19b and 19c: E2 C1 (`docs/secret.md: -` through a `seen`-poisoning start path), E2 C5 (`hid.md: -` behind `..x.md`), E2 C2 (a symlink text ending in a newline followed as a different path, `docs/leak.md: -`), and absolute symlink text skipped (`deep2.md: -`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:473`, `:535`, `:546-559`, `$S/adv.out`

---

## Claim 35c: db9cc040 Notes and A-list: "the early-split trigger fired (3 Incorrect in main_imports)"; "The unit grows past the 400-line cap"; "Walk parity with the tree walk re-measured on this repo (same set); main_imports ~0.45 s here."; "11 override rows"; "inrepo_here (was plainfile)"; "isimported has explicit tree/main arms and returns 2 for a failed walk or an unknown name"

**Location:** `git log db9cc040`
**Type:** Configuration / Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the counts, the parity set and the timing order of magnitude on this machine; does not establish timing on other hardware (measured 0.38 s, against the stated ~0.45 s).
**Legibility-target:** for-orchestrator-synthesis

E4: tree and main sets equal (3 entries), main_imports 0.379-0.387 s. E5: main...db9cc040 = 479 (> 400). `git show --numstat db9cc040 -- docs/reviews/override-log.md` → 11. Iteration-2 FC Incorrect claims 11, 15b, 16a all concern main_imports' behavior (comment, test title, commit message). 36b79f72 had `plainfile` (`$S/c36/scripts/lib/dev-cycle-read.sh`); isimported per Claim 24.

**Evidence:** `$S/tree.set`, `$S/main.set`, `docs/reviews/override-log.md:324-334`, `scripts/lib/dev-cycle-read.sh:567-575`

---

## Claims Requiring Attention

### Incorrect
- **Claim 19b** (`scripts/lib/dev-cycle-read.sh:447-448`): the walk's `seen` set is newline-joined, so a start path like `q<LF>docs/b.md<LF>r/CLAUDE.md` marks `docs/b.md` seen and its imports are never read (`docs/secret.md` passes floor); `..`-prefixed names are never followed either. Fix: keep `seen` in an associative array (or NUL-safe), and narrow the `..*` test to `..` / `../*`.
- **Claim 19c** (`scripts/lib/dev-cycle-read.sh:448-449`, `:546`): `$(...)` strips a symlink text's trailing newline, so the walk follows a different path than the link names; absolute text is skipped silently. Fix: read the text with a sentinel (or `git cat-file` into a file) and fail on any newline; list absolute symlink text under Not covered or fail on it.
- **Claim 34a** (`git log 36b79f72`): "fails closed on split ... start files" was false at that commit (forged record halves); immutable, superseded by db9cc040, and no override row records it.
- **Claim 35b** (`git log db9cc040`): A5/A7's "whatever their name" and "to the path their text names" are refuted by the same shapes as 19b/19c.

### Stale
- none

### Mostly Accurate
- **Claim 2** (`docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a.md:40`): "a doubled name of any kind" holds only for paths the `-r` listing repeats; same-named trees or a blob+tree pass the parse and fail only when read.
- **Claim 3** (`docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a.md:52`): C2-C11 is ten labels for eleven sources/rows.
- **Claim 5** (`docs/reviews/override-log.md:332`): the deferred-gap row omits the 19b/19c shapes and absolute symlink text.
- **Claim 6** (`docs/working/known-issues-dev-cycle.md:18`): A4 says A3's symlinked-file half is closed; absolute and newline-terminated symlink texts are not, and the 19b shape is unlisted.
- **Claim 8** (`docs/working/plan-build-loop-handoff.md:126`): F11's gap list omits the same shapes.
- **Claim 9** (`docs/working/plan-build-loop-handoff.md:273`): "about twenty override rows": 26 rows on main carry a U2 revisit trigger.
- **Claim 13** (`scripts/lib/dev-cycle-read.sh:15-17`): isimported's unknown-name arm returns 2 without need_root; say "isimported (tree or main)".
- **Claim 14** (`scripts/lib/dev-cycle-read.sh:30-34`): floor's walk also reads checkout files main lacks, not only untracked start files.
- **Claim 19e** (`scripts/lib/dev-cycle-read.sh:450-452`): cites A2/A3 where the walk's row is A4; the Not-covered list omits the 19b/19c shapes and the token forms in row 332.

### Unverifiable
- none

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to docs/reviews/code-fact-check-report-build-loop-u2a-rN.md (first line `Commit: db9cc040`), structured per the code-fact-check skill, where N is your replicate number given at the end of this prompt.
- Answered: yes: 43 claims over the full branch diff, the four commit messages, the rubric's iteration-2 section and override rows 321-334, with adversarial trees executed (C1-C7) and the three suites run (97 ok).
- Out of scope: the tree walk's (`imported_names`) own copy of the newline-joined `seen` pattern (`:492`, `:499`) is pre-existing and was not verdicted; timing figures in override rows 327-328 were not measured.
- Escalate: Claims 19b/19c to security-reviewer: two executed fail-open shapes in floor's import arm (a newline-named start path hides a target's imports; a newline-terminated symlink text is followed as another path), neither in A4, F11 or override row 332.
- Decisions I made: the brief says "all five branch commit messages", but `git log main..HEAD` has four (cfbf34d2, b9ffe7a8, 36b79f72, db9cc040); I checked those four. Override rows 322-323 (Accepted-immutable) were not re-verdicted. Execution logs stay in the scratch dir as instructed, not under `docs/reviews/execution-logs/`.
