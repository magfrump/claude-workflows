Commit: 8786f8fc

# Architecture Review — feat/build-loop-u2c2 (U2c2, final confirming pass)

**Scope:** `git diff main...HEAD -- scripts test` (3111ee9d, 07af69c0, 2be3db37): `scripts/lib/dev-cycle-read.sh`, `scripts/build-loop.sh`, `test/scripts/build-loop-check.bats`, `test/scripts/dev-cycle.bats`
**Date:** 2026-10-10
**Based on:** the Stage-1 summary of the k=3 fact-check (`code-fact-check-report-build-loop-u2c2-final-r1..r3.md`), the shared final brief, my iteration-1 report (`architecture-review-2026-10-10-u2c2.md`), the rubric (A1-A17, B1-B7), and the trust-boundary map of `docs/reviews/security-review-2026-10-10-u2c2.md` (Commit: `3111ee9d`). That security review predates the fix commits 07af69c0 and 2be3db37, so its boundaries may be stale.

**Scope check:** in scope. The diff touches all four trigger categories:
- Module structure: new functions `readers_root`, `walk_why`, `walk_has`, `config_seeds` and `c1_seeds`.
- Public API: floor's optional `$4`, and contract items 4, 8 and 9.
- Data model: `IMPORTED_MAIN_WHY` ("KIND [PATH]"), `IMPORT_CONFIGS`, and both walk cache keys.
- Cross-cutting concerns: the root check (need_root / readers_root) and the reader memo.

## Dependency Map

- **build-loop.sh into the lib.** `srules` calls `floor PATH STEM STATUS LOWERED`, which crosses B1. floor runs these in order:
  1. `truthrule`;
  2. the ownfile rules;
  3. `truthwalk main`, which calls `main_imports`;
  4. on a failed walk, `walk_why "$IMPORTED_MAIN_WHY"`;
  5. otherwise, the new ancestor loop, which calls `isstart` and `walk_has main` directly.
- **dev-cycle.sh into the lib.** `check_fix` calls `truthwalk tree`, which calls `imported_names`. check_fix still words the walk failure itself.
- **Inside the walks.** Both walks follow the same chain:
  1. `readers_root` (which uses `import_home`, `import_readers_key`, the reader memo and `need_root`);
  2. `import_readers`, which now computes `IMPORT_CONFIGS`;
  3. the walk's cache check;
  4. `need_root`;
  5. `outside_seeds`, a three-step wrapper: `config_seeds`, then `c1_seeds`, then the newline check.
- **Membership.** `isimported` and `truthwalk` both end in `walk_has`. floor's ancestor loop is a third direct caller of walk_has.
- **Direction.** Dependencies run the right way:
  - Wording depends on the walk vocabulary: walk_why depends on the KIND words.
  - Seed listing depends on reader discovery: config_seeds reads IMPORT_CONFIGS rather than the environment.
  - No cycles.

## Findings

#### 1. readers_root re-implements import_readers' memo predicate, including how a refusal is encoded

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:833` (readers_root), `:1149-1155` (import_readers' prelude)
**Move:** 7 (coupling surface: content coupling to a sibling's internal representation), 2
**Confidence:** High
**Legibility-target:** maintainer of import_readers' memo (its key or its refusal encoding); security reviewer weighing B6 (cwd/root check)

Evidence:
```bash
# scripts/lib/dev-cycle-read.sh:833 (whole function)
readers_root() { { [[ -n "${ROOT_REAL:-}" ]] && import_home && import_readers_key && [[ "$IMPORT_READERS_DONE" == "$IMPORT_READERS_KEY" && -n "$IMPORT_ROOTS" ]]; } || need_root; }
```
```bash
# scripts/lib/dev-cycle-read.sh:1149-1155 (excerpt ends :1155; import_readers continues to :1206 — read)
import_readers() {
  local p rs_m=() ...
  import_home || return 1
  import_readers_key
  # A refusal is memoized too, as an empty IMPORT_ROOTS (a result never is:
  # ROOT_REAL leads it), so a refusing decision lists the registry once (U2b3a final performance F1).
  if [[ "$IMPORT_READERS_DONE" == "$IMPORT_READERS_KEY" ]]; then [[ -n "$IMPORT_ROOTS" ]]; return; fi
```

A1's fix is correct: fact-check executed it for a memoized refusal from a wrong cwd and for a doubly cached call. The cost is that the answer to "does import_readers' memo hold a result?" now lives in two functions, and readers_root restates all three parts of it:
- the prelude order: import_home, then the key;
- the key comparison;
- the convention that a refusal is an empty IMPORT_ROOTS.

Suppose a later unit changes how import_readers memoizes, for example by recording a refusal with an explicit flag, adding a key part computed after import_home, or letting a result have an empty IMPORT_ROOTS. readers_root then silently decides differently from import_readers. That fails in one of two directions:
- **Closed (extra need_root).** Harmless.
- **Open on the root check.** readers_root skips need_root while import_readers misses and lists the registry from an unchecked cwd. That is exactly A1's defect.

No test pins the agreement between the two predicates. The B1 test of prompt_marks and the floor fork test exercise the hit path only. This is content coupling inside one module, between adjacent functions, so it is Minor, not Coupling.

**Recommendation:** Give the predicate one owner. Add `import_readers_held` next to import_readers (import_home, then the key, then the DONE==KEY and non-empty test). Use it both in import_readers' memo branch and in readers_root, so a change to the memo's encoding is made once. A heavier alternative is to run need_root inside import_readers on its miss and refusal paths. That would retire readers_root, but it moves the B6 root check into a function whose contract is "returns 1". **Security implication:** that alternative relocates where B6's cwd check happens (`B6` from `docs/reviews/security-review-2026-10-10-u2c2.md`, Commit: `3111ee9d` — security review predates this diff; boundary may be stale), so prefer the shared predicate.

#### 2. floor's ancestor loop reads the walk list through walk_has directly, safe only because of the elif order

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:1942-1950` (floor), `:1841-1847` (walk_has), `:87-88` (contract item 6)
**Move:** 3 (module boundary: the contract's read path), 2 (floor's growth)
**Confidence:** Medium
**Legibility-target:** the next editor of floor (U3, which adds FLOOR_WHY words and TRUTH_WHERE); API-consistency reader of contract item 6

Evidence:
```bash
# scripts/lib/dev-cycle-read.sh:1942-1950 (excerpt ends :1950; floor continues to :1952 — read)
  elif truthwalk main "$lp"; then
    if [[ "$TRUTH_WHY" == walk ]]; then FLOOR_WHY="the default branch's instruction files could not be walked for @ imports: $(walk_why "$IMPORTED_MAIN_WHY")"
    else FLOOR_WHY="an instruction or prompt file (on the default branch, or only in the checkout) imports it with @ (directly or through another import)"; fi
  else
    # A directory at a start's name, or at an imported .md name (not any import's: the parser's prefixes make every directory an import passes through one; override row).
    d="$lp"; while [[ "$d" == */* ]]; do
      d="${d%/*}"; ! isstart "$d" && { [[ "$d" != *.md ]] || ! walk_has main "$d"; } || { FLOOR_WHY="a path below the name of an instruction or prompt file, or of a .md file one imports with @"; return 0; }
    done
    return 1
```
```bash
# scripts/lib/dev-cycle-read.sh:1841-1843 (walk_has' doc)
# walk_has WALK LP: whether the list of the walk WALK names (main or tree), as
# its last call left it, holds LP, a lower-cased path: no fork. Ask it only
# after that walk succeeded (contract item 6: an error list holds nothing).
```
```bash
# scripts/lib/dev-cycle-read.sh:87-88 (contract item 6)
#  6. Read a walk only through isimported or truthwalk: IMPORTED_MAIN=error
#     reads as "not imported" to a raw membership test (row 419).
```

The ancestor loop is correct today. floor reaches the `else` branch only when `truthwalk main` returned 1, and truthwalk returns 1 only after main_imports succeeded (`:1883`). Nothing in floor states that precondition, though. walk_has' own doc puts it on the caller, and contract item 6 names only isimported and truthwalk as readers.

floor has grown into five decisions:
- the lower;
- the rules;
- the walk;
- the walk's wording;
- the ancestor rule.

The ancestor rule's safety depends on its position in an elif chain. Suppose U3 reorders the chain (TRUTH_WHERE), or moves the ancestor rule ahead of the walk so a below-a-start path gets its own reason when the walk fails. walk_has would then read `IMPORTED_MAIN=error`, and the `.md` half would fail open: an imported `.md` name would read as "not imported". This is the row-419 hazard the contract exists to prevent. Fact-check escalated the same line as an API-consistency question (contract item 6), so the hazard is visible from two lenses.

**Recommendation:** Do either of the following:
- Move the ancestor rule into its own lib function (e.g. `below_start LP`) whose doc states "after a successful `truthwalk main`", and add walk_has to contract item 6 as the lib-internal reader with that precondition.
- At minimum, add a one-line comment in floor's `else` saying the walk succeeded here.

#### 3. config_seeds clears the shared array and c1_seeds appends to it: the wrapper's call order is load-bearing

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:1443-1452`, `:1507-1508`
**Move:** 7 (temporal coupling), 2
**Confidence:** High
**Legibility-target:** the next editor of outside_seeds (the revisit trigger of row 627: a fourth seed source)

Evidence:
```bash
# scripts/lib/dev-cycle-read.sh:1443-1447 (whole function)
outside_seeds() {
  local -n ow_a="$1"; local ow_d
  config_seeds "$1" || return 1; c1_seeds "$1" || return 1
  for ow_d in "${ow_a[@]}"; do [[ "$ow_d" != *$'\n'* ]] || return 1; done
}
```
```bash
# scripts/lib/dev-cycle-read.sh:1450-1452 (excerpt ends :1452; config_seeds continues to :1503 — read)
config_seeds() {
  local -n os_a="$1"; local d q r c i in rs=() cf=() ...
  os_a=()
```
```bash
# scripts/lib/dev-cycle-read.sh:1507-1508 (excerpt ends :1508; c1_seeds continues to :1533 — read)
c1_seeds() {
  local -n c1_a="$1"; local d q r c i in cr=() cx=() ir=() lo=() fl=(); local -A c1_at=()
```

The split discharges rows 582/585/589/603 as row 627 records:
- c1_seeds has its own `c1_at`, so row 585's phase-crossing state is gone;
- the newline check now covers both sources.

The reset lives in config_seeds, though, so the two halves are not symmetric:
- Swapping the order in the wrapper drops every config seed.
- Adding a fourth source with its own `=()` drops the sources before it.
- Calling c1_seeds alone appends to stale contents.

Row 627's revisit trigger is exactly "a fourth seed source", and that is when this order dependency will bite.

**Recommendation:** Move `ow_a=()` into the wrapper and make both halves append. Then each source has the same shape, and the wrapper alone owns the array's lifetime. This costs one line moved. Record it with row 627 if it is not done here.

#### 4. IMPORT_CONFIGS is documented as "outside_seeds' config dirs", but config_seeds adds the ancestors' .claude dirs itself

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:1124-1129` (import_readers' doc), `:1198-1199`, `:1454-1461` (config_seeds' ancestor loop)
**Move:** 2 (responsibility: one list with two producers)
**Confidence:** High
**Legibility-target:** maintainer of the config-dir list (row 581's follow-up)

Evidence:
```bash
# scripts/lib/dev-cycle-read.sh:1124-1127 (import_readers' doc; the paragraph ends :1129)
# root_copies and outside_seeds read. IMPORT_CONFIGS holds outside_seeds'
# config dirs, newline-separated: each absolute home's .claude, then
# CLAUDE_CONFIG_DIR when set and IMPORT_MANAGED_DIR; the key holds both, so
# the walks, keyed on IMPORT_CONFIGS too, see a change without import_reset
```
```bash
# scripts/lib/dev-cycle-read.sh:1454-1459 (config_seeds; excerpt ends :1459, the loop closes :1461, function continues to :1503 — read)
  for r in "${rs[@]}"; do
    d="$r"
    while [[ "$d" != / ]]; do
      d="${d%/*}"; d="${d:-/}"; in=""
      for q in "${rs[@]}"; do [[ "$d" != "$q" && "$d" != "$q"/* ]] || in=1; done
      [[ -n "$in" || -n "${os_s[a$d]+set}" ]] || { os_s[a$d]=1; [[ ! -d "$d" ]] || tops+=("$d"); cf+=("${d%/}/.claude"); }
```

The cache keys are complete. The ancestors derive from IMPORT_ROOTS, which both keys hold, so moving the environment-derived dirs into import_readers (row 581) is right and closes the reset duty in contract item 4. The structural residue is that "the config dirs" now has two producers:
- import_readers, for homes, CLAUDE_CONFIG_DIR and managed;
- config_seeds, for ancestors' `.claude`.

The doc presents IMPORT_CONFIGS as the whole list. A reader who adds a config-dir rule in import_readers, believing it covers every config dir, misses the ancestor branch, and vice versa.

**Recommendation:** Change the doc to say "the environment's config dirs; config_seeds adds each root ancestor's .claude". Do not move the ancestor computation: it would grow import_readers' memoized state for no key benefit.

#### 5. The `readers` sentence is now written twice, in walk_why and in check_fix

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:812-813` (walk_why), `scripts/dev-cycle.sh:186-187` (check_fix)
**Move:** 7 (duplicated vocabulary across the lib boundary)
**Confidence:** High
**Legibility-target:** U3 implementer of TRUTH_WHERE (row 630)

Evidence:
```bash
# scripts/lib/dev-cycle-read.sh:812-813 (walk_why; excerpt ends :813, walk_why continues to :826 — read)
    readers) [[ -n "$IMPORT_READER_WHY" ]] && echo "the reader settings of docs/dev-cycle.md cannot be used: $IMPORT_READER_WHY" \
      || echo "the worktree registry could not be read, or a reader root, home or CLAUDE_CONFIG_DIR is not a usable absolute path" ;;
```
```bash
# scripts/dev-cycle.sh:186-187
    if [[ "$TRUTH_WHY" == walk && -n "$IMPORT_READER_WHY" ]]; then echo "skip $a: the instruction-file import walk failed, so an import of it cannot be ruled out: the reader settings of docs/dev-cycle.md cannot be used: $IMPORT_READER_WHY; file it instead"
    elif [[ "$TRUTH_WHY" == walk ]]; then echo "skip $a: the instruction-file import walk failed, so an import of it cannot be ruled out; file it instead"
```

walk_why discharges iteration 1's Finding 3 (rubric A5) for floor. The `readers` arm reads only IMPORT_READER_WHY, not the walk's state, so check_fix could already use it. Instead, the reader-settings sentence is now kept in two files. This is not a re-filing of row 630, which defers the tree walk's own WHY to U3. It records that when U3 gives truthwalk a TRUTH_WHERE, check_fix's copied sentence is the one to delete.

**Recommendation:** None now. Add "check_fix's readers sentence → walk_why readers" to row 630's U3 scope.

## What Looks Good

- **walk_has is the one membership test.** isimported, truthwalk and floor share one fork-free predicate, which closes iteration 1's Finding 5 (rubric A6). The residue is one duplicated dispatch line (`case "$1" in main) main_imports ...`, `:1838` and `:1883`) and truthwalk's own upper-case guard (`:1885`), which restates truthrule's case word defensively. Both are a line each, not worth a function.
- **walk_why is a proper word-to-sentence function**, in the entry_why/oddwhy convention:
  - an unknown KIND is worded generically, so its "where" is not lost;
  - the path filter applies check_line's own NAMECHARS rule, which keeps B5's printing policy in one rule;
  - floor's wording collapsed from an 11-arm case to one call.
- **IMPORTED_MAIN_WHY is a small, closed vocabulary.** It is documented in one place (`:792-802`), set at stage boundaries, emptied on success and kept with a cached failure. Fact-check executed every `return 1` against its KIND.
- **IMPORT_CONFIGS in import_readers (row 581)** makes reader discovery the single owner of environment-derived config dirs:
  - CLAUDE_CONFIG_DIR is validated once per reader set;
  - both walk keys and the memo key cover the config dirs;
  - contract item 4 loses two reset duties.

  The memo key's set-empty vs unset distinction (fact-check r2) over-keys, so it is harmless.
- **The root check is symmetric again.** Both walks call `readers_root`, then import_readers, then their cache check, then `need_root`. That fixes iteration 1's Finding 1 (rubric A1), whose cause was that the two walks ordered the root check differently. The header now states the cached-call exception honestly.
- **floor's `$4`** is a documented optimization with a stated agreement rule (contract item 8), and srules passes check_line's lowered path, so B1's datum is computed once.
- **c1_seeds is independent:** own locals, own `c1_at`, own keep-rule. Row 627 honestly records the admission repetition that remains.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | readers_root re-implements import_readers' memo predicate (key order, comparison, refusal-as-empty-roots); a change to the memo can make it skip need_root on a miss | Minor | `dev-cycle-read.sh:833`, `:1149-1155` | High |
| 2 | floor's ancestor loop calls walk_has directly; safe only because the `else` follows a successful `truthwalk main`; contract item 6 does not name it | Minor | `dev-cycle-read.sh:1942-1950`, `:1841-1847`, `:87-88` | Medium |
| 3 | config_seeds resets the array, c1_seeds appends: outside_seeds' call order is load-bearing | Informational | `dev-cycle-read.sh:1443-1452`, `:1507-1508` | High |
| 4 | IMPORT_CONFIGS doc says "outside_seeds' config dirs"; config_seeds adds ancestors' .claude itself | Informational | `dev-cycle-read.sh:1124-1129`, `:1454-1461` | High |
| 5 | The readers sentence is written in walk_why and check_fix (U3 / row 630 scope) | Informational | `dev-cycle-read.sh:812-813`; `dev-cycle.sh:186-187` | High |

## Overall Assessment

The branch improves the lib's structure, and the fixes since iteration 1 resolved every finding I filed:
- Finding 1 (A1) by the symmetric readers_root and need_root order;
- Finding 2 (A7) by the config_seeds/c1_seeds wrapper;
- Finding 3 (A5) by walk_why;
- Finding 5 (A6) by walk_has;
- Findings 4, 6 and 7 by text or settled rows.

The fixes introduced two small new couplings:
- readers_root restates import_readers' memo predicate (Finding 1, the most important one here, since drift there reopens A1's defect without a failing test);
- floor reads walk_has on an ordering precondition it does not state (Finding 2).

Both are Minor, fixable in place in a few lines, and fail closed today. Nothing is Structural or Coupling-tier. I have no disagreement with the security review's boundary placement. Finding 1's heavier alternative would relocate B6's root check and is flagged as such.

The settled 2026-10-10 rows for this branch (626-632) keep their basis, and I re-file none:
- Finding 3 builds on row 627's trigger;
- Finding 5 builds on row 630's scope.

## Goal-Alignment Note

The goal is to land U2c2 after a clean review-fix loop. Architecturally the branch is landable: no 🔴 Must Fix and no 🟡 Must Address findings. All five findings are 🟢 Consider:
- Findings 1 and 2 are each a two-to-five-line change (a shared memo predicate; a precondition comment or a `below_start` function plus contract item 6), worth doing now or recording as rows keyed to U3, which is the next editor of floor and the walks.
- Findings 3-5 are notes for rows 627 and 630's existing triggers.

None of them blocks the plan's U2c2 bullet, whose six items are all structurally discharged.
