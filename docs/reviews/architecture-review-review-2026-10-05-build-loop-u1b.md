Commit: 0ae7d801

# Architecture Review — feat/build-loop-u1b (review-fix loop iteration 2)

**Scope:** `feat/build-loop-u1a...feat/build-loop-u1b` (merge-base 2da477b7): `scripts/build-loop.sh` (new, 192 lines), `test/lib/build-loop-fixtures.bash` (new), `test/scripts/build-loop-read.bats` (new); enclosing context `scripts/lib/dev-cycle-read.sh` at HEAD (unchanged by this unit)
**Date:** 2026-10-05
**Based on:** `docs/reviews/code-fact-check-report-build-loop-u1b.md` (Stage 1, k=3 merged); plan `docs/working/plan-build-loop-handoff.md` rev 4, "Script interface" (:201-241) and "Approach" (:181-199); `docs/reviews/override-log.md` rows dated 2026-10-05

Trigger categories: module structure (yes: a new script module and a new test fixture library), public APIs (yes: the `--settings` output contract and the globals `POLICY`/`NEVER` that later units read), data models (yes: the three-line settings format and `NEVER`'s shape), cross-cutting concerns (no new ones; the scrub and default-branch resolution are consumed, not changed).

Trust-boundary cross-reference: the scan found `docs/reviews/security-review-*.md` files, none for this unit. The newest by date, `docs/reviews/security-review-2026-10-02-digest-pass38.md` (Commit: `90364c73`), labels `B5: [default-branch tree entry at a brief path] → [check_brief() ls-tree mode gate] → [brief Status read / slot decision]`, which C1 below touches. That review predates this diff, so the boundary may be stale. The parallel U1b security review in this iteration uses the `security-reviewer-review-*` name and does not match the scan pattern.

## Dependency Map

- `scripts/build-loop.sh` → `scripts/lib/dev-cycle-read.sh`: one-way, sourced from `$SCRIPT_DIR` (:46-53). Consumed: `scrub_reexec`, `resolve_main`, `main_by_name`, `MAIN_SHA`, `main_entry`, `FENCE_AWK` (with its awk globals `odd`, `oddwhy`, `infence`, `fline`), `oddwhy`, `NAMECHARS`. Provided to the lib: `ROOT_REAL` (:68; unused by U1b's paths, set for later file checks).
- The lib does not depend on build-loop.sh in code. Its header names its callers in prose (lib :2-3, :10-12).
- `build-loop.sh` exports state for later units (U1c `--status`, U2 gate): `POLICY`, `NEVER` (comment :130-132), plus `*_LINE` strings and `FILE_OUT`/`FILE_WHY` from `main_file`.
- `test/scripts/build-loop-read.bats` → `test/lib/build-loop-fixtures.bash` → runs `scripts/build-loop.sh` as a subprocess only. No test sources the lib or the script directly.
- Separate process, same data: `docs/dev-cycle.md` now has two readers. dev-cycle.sh reads its idea-source rows (`check_path`, using `pathform … glob`), and build-loop.sh reads its three keys (`SETTINGS_AWK`, `globform`).

The direction is correct: the volatile CLI depends on the stable shared reader, and nothing in the lib depends on the new module.

## Findings

#### C1. `main_file` is a third private copy of the lib's "read a blob on main under FENCE_AWK" protocol, and it reads the lib's awk internals across the boundary

**Severity:** Coupling
**Location:** `scripts/build-loop.sh:79-94`, `scripts/build-loop.sh:113-117`
**Move:** 7 (coupling surface), 3 (module boundary)
**Confidence:** High (the duplication and the cross-boundary names); Medium (the cost, which depends on U1c/U2 adding more readers)
**Legibility-target:** for-orchestrator-synthesis

Evidence (`scripts/build-loop.sh:82-93`, excerpt ends :93; enclosing `main_file()` closes at :94, read):
```
  e="$(main_entry "$f")"
  case "$e" in
    blob) ;;
    absent) FILE_WHY=absent; return 1 ;;
    notdir\ *) FILE_WHY="${e#notdir } is not a directory on the default branch"; return 1 ;;
    *) FILE_WHY="$f is not a regular file on the default branch"; return 1 ;;
  esac
  FILE_OUT="$(git cat-file blob "$MAIN_SHA:$f" | env LC_ALL=C awk "$FENCE_AWK$2")"
  case "$FILE_OUT" in
    odd\ *) read -r _ n why <<<"$FILE_OUT"; FILE_WHY="line $n of $f $(oddwhy "$why"), so the file is not read"; return 1 ;;
    unbalanced\ *) FILE_WHY="the code fence opened at line ${FILE_OUT#unbalanced } of $f is never closed, so the file is not read"; return 1 ;;
```
and `scripts/build-loop.sh:113-116` (excerpt ends :116; `SETTINGS_AWK` closes at :117, read):
```
END {
  if (odd) print "odd " odd " " oddwhy
  else if (infence) print "unbalanced " fline
  else for (k in c) print k " " c[k] " " l1[k] " " (k in l2 ? l2[k] : 0) "\t" t[k]
```

The sequence main_entry → cat-file → `FENCE_AWK$PROGRAM` → an END block printing `odd N WHY`/`unbalanced N` → decode with `oddwhy` now exists three times. `brief_fields` plus `check_brief` (lib :286-292, :320-332) and `check_answer` (lib :539-553) are the other two, each with its own way of reporting the result (`BRIEF_ODD`, a returned string `r`, and here `FILE_OUT`/`FILE_WHY`). This copy lives outside the lib. That puts the lib's private awk state (`odd`, `oddwhy`, `infence`, `fline`) and its END-block reporting protocol into the interface build-loop.sh relies on. The FENCE_AWK comment (lib :176-179) documents `odd`, `oddwhy` and `fline`, but not `infence`. The copies have already diverged. `main_entry`'s documented `error` output (lib :251-252), which `check_brief` (lib :325) and `check_answer` (lib :544) report as "could not be read", falls into `*)` here and is reported as "is not a regular file" (fact-check Claim 13; it still fails closed). The plan gives this helper more users. U1c's `constraints` line reads `docs/constraints.md` "under FENCE_AWK" (plan :204), and every later main-commit reader would either call this script-local helper or write a fourth copy. If the lib changes FENCE_AWK's reporting (renaming `infence`, adding a refusal kind with a new END output), all three copies must change in step, and the build-loop.sh copy is the only one outside the lib's own suite's direct reach. This sits on `B5` from `docs/reviews/security-review-2026-10-02-digest-pass38.md` (Commit: `90364c73`; the security review predates this diff, so the boundary may be stale). The recommendation keeps the crossing at `main_entry`'s mode gate and does not move it.

**Recommendation:** When U1c adds the constraints reader (the helper's second user), move `main_file` into the lib as the one "file on main under FENCE_AWK" reader. Give `error` its own `FILE_WHY`. Name the END-block protocol, including `infence`, in the FENCE_AWK comment as the interface for callers' programs. Optionally re-base `brief_fields` on it in a later lib unit.

#### C2. `NEVER` is exported as the raw line text: later readers must re-run the parse that `read_settings` has just done

**Severity:** Coupling
**Location:** `scripts/build-loop.sh:130-133`, `scripts/build-loop.sh:155-170`
**Move:** 3 (module boundary: the globals interface), 7 (stamp coupling)
**Confidence:** Medium (no consumer exists yet; U2's gate is the named one)
**Legibility-target:** for-author

Evidence (`scripts/build-loop.sh:130-133`):
```
# Sets POLICY, POLICY_LINE, SLOTS_LINE, NEVER (the globs, or empty) and
# NEVER_LINE from main's commit. POLICY and NEVER are
# for the modes that judge a brief (--status, then the gate).
POLICY=review; POLICY_LINE=""; SLOTS_LINE=""; NEVER=""; NEVER_LINE=""
```
and `scripts/build-loop.sh:156`, `:161`, `:164-166`, `:170` (excerpt; enclosing `read_settings()` runs :135-185, read):
```
      # Single spaces only: a tab or other blank would split differently in a later reader.
        IFS=' ' read -ra parts <<<"$v"  # not a bare $v: the shell would expand * and ? against files
          if ! globform "${g%/}"; then why="lists entry $i, which is not an allowed glob form"; break; fi
          if [[ -n "${seen[${g%/}]-}" ]]; then why="lists entry $i twice"; break; fi
          seen[${g%/}]=1
      else NEVER="$v"; NEVER_LINE="never $v set: line ${first[never]} $where"; fi
```

`read_settings` splits the line into entries, normalises each (`${g%/}`) and deduplicates on the normalised form. It then throws that result away and exports `NEVER="$v"`, the unsplit text with trailing slashes kept (`workflows/ hooks/*.sh`). The comment at :156 anticipates "a later reader" splitting it again. That reader (U2's S rules, which decide whether self-merge may land a path) has to re-implement the same split with globbing disabled (the hazard named at :161) and the same trailing-slash rule (the header says "a trailing / ignored", :24). The interface comment says only "the globs, or empty", so none of those obligations appears where the consumer will look. This is the input to a fail-closed gate, and a split that disagrees with the validator is the A1 class of bug that iteration 1 had to fix.

**Recommendation:** Export the parsed form, for example `NEVER_GLOBS=()` filled with the normalised entries (reset to empty on any malformed or absent line), and keep `NEVER`/`NEVER_LINE` for printing. Or, at minimum, document `NEVER`'s exact format at :130-132 (single-space separated, may hold `*`/`?`, so split with `read -ra` and never word-split; a trailing `/` is significant or not).

#### M1. `read_settings` does not reset `POLICY` or `NEVER` on entry, so a second call that fails leaves the previous self-merge in place

**Severity:** Minor
**Location:** `scripts/build-loop.sh:133-143`
**Move:** 3 (contract of the globals interface)
**Confidence:** High (code path); Low (that a second call happens: no caller makes one today)
**Legibility-target:** for-author

Evidence (`scripts/build-loop.sh:133-141`, excerpt ends :141; enclosing `read_settings()` continues to :185, read; `POLICY` is assigned only at :178 and `NEVER` only at :170):
```
POLICY=review; POLICY_LINE=""; SLOTS_LINE=""; NEVER=""; NEVER_LINE=""
# shellcheck disable=SC2034  # POLICY and NEVER: see above
read_settings() {
  local f=docs/dev-cycle.md where l k c l1 l2 t v g i why never_ok=1 parts=()
  local -A cnt=() first=() second=() text=() seen=()
  where="of $f on the default branch"
  if ! main_file "$f" "$SETTINGS_AWK"; then
    [[ "$FILE_WHY" == absent ]] && why="no $f on the default branch" || why="$FILE_WHY"
    POLICY_LINE="policy review unset: $why"; SLOTS_LINE="slots 3 default: $why"
```

The defaults are set once, at file scope. Each function that sets globals in the same module resets them at entry: `main_file` at :81 (`FILE_OUT=""; FILE_WHY=""`), and the lib's `brief_fields` at lib :283 (`BRIEF=(); BRIEF_ODD=""`). `read_settings` does not. The lib documents that a second `resolve_main` call re-reads main (lib :21-22). If a later mode re-resolves main (for example U3's `--merge` around its CAS) and calls `read_settings` again, an unreadable or malformed file sets `POLICY_LINE` to "review unset" while `POLICY` stays `self-merge` from the first call. The printed line and the machine value would then disagree in the fail-open direction.

**Recommendation:** Start `read_settings` with `POLICY=review; NEVER=""` (and empty `*_LINE`), matching `main_file` and `brief_fields`.

#### M2. `globform` forks the lib's path-form rule outside the lib, and the lib's header still names `pathform` as the rule for settings rows

**Severity:** Minor
**Location:** `scripts/build-loop.sh:118-129`; `scripts/lib/dev-cycle-read.sh:127-134`
**Move:** 2 (responsibility boundaries), 3
**Confidence:** Medium
**Legibility-target:** for-author

Evidence (`scripts/build-loop.sh:118-124`, excerpt ends :124; `globform()` closes at :129, read):
```
# A Self-merge never: entry: pathform's characters and glob marks, not starting
# / or -, no empty, . or .. part. Unlike pathform it allows a part starting .git
# (.github/, .gitignore): the list only adds refusals, so naming one must not
# make the line malformed and turn self-merge off.
globform() {
  local rest="$1/" c
  [[ "$1" =~ ^[*?$NAMECHARS]+$ && "$1" != /* && "$1" != -* ]] || return 1
```
and `scripts/lib/dev-cycle-read.sh:127-129`:
```
# The path rule for repo text (commit messages, plans, settings rows, roadmap
# brief paths), so the skill runs it instead of re-deriving it in prose:
#  - form: only letters, digits, . _ - / (and * ? in a glob), not starting with
```

The divergence is deliberate and well argued: a denylist entry must not be refused for naming `.git*` (A4). The issue is where it lives. The lib says it owns "the path rule for repo text", and `docs/dev-cycle.md` now has two path rules for two kinds of row, in two modules. `globform` copies `pathform`'s character test and part walk word for word apart from one clause, so a change to the form rule (to `NAMECHARS`'s use, or the part checks) has to be made twice. U2's floor and gate, which the plan puts in the lib (plan :187 amendment), are the consumers of `NEVER`, so the rule for what a `NEVER` glob may be will be read in the lib and defined in the script.

**Recommendation:** Move `globform` into the lib beside `pathform`, for example as a third `pathform` mode (`pathform "$g" deny`) that skips only the `.git*` clause. Update the lib's path-rule comment to name both forms. This is a small change that fits U1c or U2.

#### M3. `-h` prints a hard-coded header range, so the next mode's documentation will be cut off silently

**Severity:** Minor
**Location:** `scripts/build-loop.sh:56-63`, `scripts/build-loop.sh:187-192`
**Move:** 8 (extension points)
**Confidence:** High
**Legibility-target:** for-automated-gate

Evidence (`scripts/build-loop.sh:56-62`, excerpt ends :62; the `case` closes at :63, read):
```
usage() { echo "$1 (usage: build-loop.sh --settings)" >&2; exit 1; }
MODE=""
case "${1:-}" in
  --settings) MODE=settings; [[ $# -eq 1 ]] || usage "--settings takes no arguments" ;;
  -h|--help) sed -n '2,41p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
  '') usage "no mode given" ;;
  *) usage "unknown option: $1" ;;
```

The header block ends exactly at line 41 today. The plan adds a fourth `--settings` line (constraints, U1c) and seven more modes (`--status`, `--marker`, `--state`, `--main-log`, `--cycle-diff`, `--check`/`--merge`, `--start`/`--prompt`). Each one grows the header. Unless `'2,41p'` is edited in the same commit, `-h` drops the tail of the help, and no test checks the help text. Adding a mode means editing four places: the header, the `usage` string (which names only `--settings`), the argument `case`, and the `MODE` `case`. Two of those (the help range and the usage string) fail silently. This is pragmatic for one mode, but it will repeat for nine.

**Recommendation:** Print the header up to the first non-`#` line (for example `awk 'NR>1 && !/^#/{exit} NR>1' "$0"`) rather than a fixed range. Optionally add a one-line test asserting that `-h` output contains the last header line.

#### M4. The fixture library's assertion helpers are status-returning predicates, and the suite chains them with `&&`, where bats does not enforce a non-final failure

**Severity:** Minor
**Location:** `test/lib/build-loop-fixtures.bash:33-34` (helpers); `test/scripts/build-loop-read.bats:80`, `:84`, `:126`
**Move:** 5 (interface segregation, applied to the fixture library's interface)
**Confidence:** High (fact-check Claim 38, reproduced by r2/r3; escalation E2)
**Legibility-target:** for-automated-gate

Evidence (`test/lib/build-loop-fixtures.bash:33-34`; `test/scripts/build-loop-read.bats:80`, `:126`):
```
settings_is() { run --separate-stderr bash "$BL" --settings; [ "$(line "$1")" = "$2" ] || { echo "want: $2"; echo "$output $stderr"; return 1; }; }
settings_like() { run --separate-stderr bash "$BL" --settings; [[ "$(line "$1")" == "$2"* ]] || { echo "want: $2..."; echo "$output $stderr"; return 1; }; }
    settings_like policy "policy review set:" && settings_like slots "slots 3 default:"
    settings_like never "never .github/ .gitignore set:" && settings_like policy "policy self-merge set:"
```

This is the architectural root of E2. The shared library exposes assertions whose failure is only a return status, so how a caller composes them decides whether they assert at all. 0ae7d801 introduced the helpers to fit the 400-line cap, and the first `&&` operand at :80 and :126 (the latter the A4 regression check) became advisory. Every future `build-loop-*.bats` suite that loads this library inherits the trap. Test-strategy owns the coverage consequence. The structural point is that the helper contract does not say "one per line".

**Recommendation:** Put each helper call on its own line at the three sites. State in the fixture header that the helpers are assertions to be called as statements, never chained. A grep-based lint on `&& settings_` in `test/scripts/build-loop-*.bats` would catch regressions.

#### M5. The fixture library copies dev-cycle.bats' hermetic git block and exports an unused `LIB`

**Severity:** Minor
**Location:** `test/lib/build-loop-fixtures.bash:7-21` (`bl_setup`)
**Move:** 2, 7
**Confidence:** Medium
**Legibility-target:** for-author

Evidence (`test/lib/build-loop-fixtures.bash:11-15`, excerpt ends :15; `bl_setup()` continues to :21, read):
```
    # shellcheck disable=SC2034  # read by the suites that load this file
    LIB="$REPO_ROOT/scripts/lib/dev-cycle-read.sh"
    export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
    export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@example.invalid
    export GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@example.invalid
```
and `test/scripts/dev-cycle.bats:11-13` holds the same three `export` lines.

The fixture file's own header says it uses "the same hermetic git environment as test/scripts/dev-cycle.bats". It reaches that by copying, while `test/lib/hermetic-env.bash` already exists as the shared home for environment pinning (it sets locale only). The two suites test one shared lib, so their environments should not drift apart. `LIB` is exported "for the suites that load this file", but no suite reads it. Override row 196 (u0a, Defer, trigger "U1's test unit") wanted a test that sources the lib from build-loop.sh's side. This unit covers that through the script subprocess, which satisfies the row's intent, so `LIB` is dead for now. The helpers also take generic names (`line`, `settings`, `commit_all`) in a library meant to be loaded by several suites.

**Recommendation:** Move the git-identity and config block into `test/lib/hermetic-env.bash` (for example `pin_hermetic_git`) and call it from both setups. Drop `LIB` until a suite uses it. Consider a `bl_` prefix on the helpers before a second suite loads them.

#### I1. The rule for what counts as a copy of a key line now differs between the two readers that feed self-merge

**Severity:** Informational
**Location:** `scripts/build-loop.sh:104-111`; `scripts/lib/dev-cycle-read.sh:289-290`
**Move:** 2, 3
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

Evidence (`scripts/build-loop.sh:106`, `:111`; enclosing `SETTINGS_AWK` :101-117, read):
```
  if (match(s, /^([ \t>#*_`~]|[-+][ \t]|[0123456789]+[.)][ \t]|\357\273\277)*/)) s = substr(s, RLENGTH + 1)
  if (k != "") { c[k]++; if (c[k] == 1) { l1[k] = NR; t[k] = $0 } else if (c[k] == 2) l2[k] = NR }
```
and `scripts/lib/dev-cycle-read.sh:289-290` (inside `brief_fields()` :281-300, read):
```
    match($0, /^(Status|Branch|Policy|Paths|Asked|Dispatched):/) {
      k = tolower(substr($0, 1, RLENGTH - 1)); if (!(k in got)) { got[k] = 1; kv[++nk] = k "\t" $0 }
```

The settings reader strips Markdown prefixes, matches the key in any case and treats a second copy as making the key unset. The brief reader takes the first column-0 line and ignores later copies. Plan :239-240 has U2 combine the two: the brief's `Policy:`/`Paths:` with the settings `POLICY`/`NEVER` into the "stricter policy". Each module therefore has its own answer to "does a rendered copy of this key exist?". The fact-check's E1/E3 (bold copies with the markup closed before the colon, task items, NBSP, and so on) would be fixed in `SETTINGS_AWK` only. This is not a defect in U1b. It is a model that is about to have two owners.

**Recommendation:** Before U2 combines the two policies, decide whether the copy-detection model is one shared lib function (an awk helper beside `fence()`) or deliberately differs per file. Record that decision in `docs/decisions/log.md`.

#### I2. The lib's header still calls build-loop.sh "planned"

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:2-3`, `:10-12` (not changed by this unit)
**Move:** 1
**Confidence:** High
**Legibility-target:** for-author

Evidence (`scripts/lib/dev-cycle-read.sh:2-3`):
```
# The dev cycle's reader, used by scripts/dev-cycle.sh and kept apart so the
# planned scripts/build-loop.sh can share it: the output scrub, the plain-file
```

Now that the second caller has landed, the header is stale. Override row 197 (u0a) was satisfied by the "both callers' suites" sentence at :10-12, which can now name `test/scripts/build-loop-read.bats`.

**Recommendation:** A one-line edit in U1c, which already touches this area. No code change.

#### I3. `many()` is defined inside `read_settings` and becomes a global function bound to its locals by dynamic scope

**Severity:** Informational
**Location:** `scripts/build-loop.sh:150`
**Move:** 3
**Confidence:** High
**Legibility-target:** for-author

Evidence (`scripts/build-loop.sh:150`):
```
    many() { echo "more than one line starts \"$1\" (lines ${first[$2]} and ${second[$2]})"; }
```

Bash has no nested functions. `many` is defined at the global scope on the first call, and outside `read_settings` it would read whatever `first`/`second` are visible there. It is harmless in a single-mode script. The pattern does not appear elsewhere in this script or the lib, so it is best not copied.

**Recommendation:** Inline the two uses, or define `many` at file scope with its arrays passed by name.

## What Looks Good

- **Dependency direction.** build-loop.sh depends only on the lib's documented surface (`scrub_reexec`, `resolve_main`/`main_by_name`, `main_entry`, `FENCE_AWK`/`oddwhy`, `NAMECHARS`), and the lib gains no reference to it. The lib is sourced from `$SCRIPT_DIR`, never the target repo (:47-53), and a test pins this (bats :152-159). This matches the plan's "Both scripts source the lib from their own `SCRIPT_DIR`".
- **The u0 override rows hold.** build-loop.sh calls the lib directly with no `dev-cycle.sh` subprocess (row 207). It gates on `main_by_name`, not `resolve_main`'s status (row 215: `resolve_main || true; main_by_name || …`, :70-71). It reads git objects only (`main_entry` + `cat-file`), so the working tree a loop can write never decides (T4 pins this).
- **Fail-closed ordering is structural, not incidental.** The never line is evaluated first, and `never_ok` feeds the policy decision (:151, :176-177), so self-merge cannot be printed beside a malformed denylist.
- **One sentence of documentation, not a copy.** 0ae7d801 points the header at FENCE_AWK's comment for the refused shapes (:66-68) instead of restating them. The other U1b docs should follow the same practice.
- **The tests go through the public CLI only.** The suite exercises `--settings`'s printed contract, never internals, so the C1/C2/M2 restructures in later units would not churn these tests.
- **The fixture library is a proper seam** for the planned `build-loop-*.bats` family (M4 and M5 are about its contents, not its existence).

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| C1 | `main_file` is a third copy of the FENCE_AWK main-blob protocol outside the lib, reading lib awk internals (`infence` undocumented); `error` folded into "not a regular file" | Coupling | `scripts/build-loop.sh:79-94`, `:113-117` | High |
| C2 | `NEVER` exported as raw text; U2 must re-split, re-normalise `/` and avoid globbing; format undocumented | Coupling | `scripts/build-loop.sh:130-133`, `:155-170` | Medium |
| M1 | `read_settings` does not reset `POLICY`/`NEVER`; a second failing call keeps a stale self-merge | Minor | `scripts/build-loop.sh:133-143` | High (path) / Low (reach) |
| M2 | `globform` forks `pathform` outside the lib, whose header claims the path rule for settings rows | Minor | `scripts/build-loop.sh:118-129` | Medium |
| M3 | `-h` prints a fixed `2,41p` range; the usage string names only `--settings`; the next mode cuts the help | Minor | `scripts/build-loop.sh:56-63` | High |
| M4 | Fixture assertions are status predicates chained with `&&` (E2); the A4 check is advisory | Minor | `test/scripts/build-loop-read.bats:80`, `:84`, `:126` | High |
| M5 | Fixture copies dev-cycle.bats' git env instead of `test/lib/hermetic-env.bash`; `LIB` unused | Minor | `test/lib/build-loop-fixtures.bash:11-15` | Medium |
| I1 | The rule for a key-line copy differs between `SETTINGS_AWK` and `brief_fields`, which U2 combines | Informational | `scripts/build-loop.sh:106`, `lib:289-290` | Medium |
| I2 | Lib header still says "planned scripts/build-loop.sh" | Informational | `scripts/lib/dev-cycle-read.sh:2-3` | High |
| I3 | Nested `many()` becomes a global bound by dynamic scope | Informational | `scripts/build-loop.sh:150` | High |

## Overall Assessment

U1b keeps the system's structure sound. The dependency runs one way, from a thin CLI module to the shared reader, sourced self-contained; there is no cycle and no layer violation, and there are no Structural findings. The two Coupling findings are about the seams this unit opens for later units rather than about U1b's own behaviour. The more important one is C1. `main_file` is the generic "file on main, under FENCE_AWK" reader that U1c (constraints) and later modes will reuse, and it sits outside the lib while copying the lib's private END-block protocol. That is the third such copy, and it has already drifted on `error`. Both C1 and C2 are fixable in place in U1c/U2 without restructuring, and the 400-line cap explains why they were not done here. The single most important structural concern is to move `main_file` (and `globform`) into the lib before a second reader depends on the script-local copy.

## Goal-Alignment Note

- **Success criterion (restated verbatim):** "a markdown report saved to /workspace/.claude/wt-build-loop-u1b/docs/reviews/architecture-review-review-2026-10-05-build-loop-u1b.md, structured per the architecture-review skill, with its severity mapping (Structural / Coupling / Minor / Informational)."
- **Answered:** Yes. Module boundaries (C1, M2, I2), dependency direction (Dependency Map, What Looks Good), the globals interface for U1c/U2 (C2, M1) and the test fixture library (M4, M5) are each covered. Every finding carries Severity, Location, verbatim Evidence, Confidence and a Legibility-target. Settled override-log rows were respected: rows 207 and 215 were checked and their premises hold; row 196's premise (a test sourcing the lib from build-loop.sh's side) is met through the script subprocess, noted in M5; nothing settled is re-raised.
- **Out of scope:** The exploitability of hidden key copies (fact-check E1/E3) belongs to security-reviewer. Test coverage gaps (Claims 23, 30, 39) belong to test-strategy. Help/usage naming consistency belongs to api-consistency. The lib's own internals are U1a's, reviewed separately.
- **Escalate:** C1 and C2 for the orchestrator, as U1c/U2 plan inputs (where `main_file`'s and `globform`'s home goes, and `NEVER`'s exported shape), not as U1b blockers. I1 for the orchestrator before U2: one copy-detection model or two.
- **Questions / Decisions:** Should C1's move happen in U1c (the second user arrives there) or in a dedicated lib unit? Recommended: U1c, within its line budget, or defer it with an override-log row whose revisit trigger is U1c.
