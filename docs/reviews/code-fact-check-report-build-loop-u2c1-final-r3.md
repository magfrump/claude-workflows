**Commit:** 9e7c61c5

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u2c1 (branch `feat/build-loop-u2c1`)
**Scope:** `git diff main...HEAD` at 9e7c61c5, the whole branch (final confirming pass, replicate r3): scripts/build-loop.sh, scripts/lib/dev-cycle-read.sh, test/scripts/build-loop-check.bats, docs/working/plan-build-loop-handoff.md, the override-log rows dated 2026-10-10 for `feat/build-loop-u2c1`, and the five branch commit messages. Review reports under docs/reviews/ are artifacts, not checked.
**Checked:** 2026-10-10
**Total claims checked:** 54
**Summary:** 40 verified, 3 mostly accurate, 2 stale, 4 incorrect, 5 unverifiable

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) read first. None of its logged patterns (corpus statistics, benchmark denominators, suite counts in commits, a non-referencing consumer) matches a claim here. The two suite-count claims (Claim 47a) were counted against the tree because that log has a suite-count entry; both counts hold.

Execution provenance (all runs on 2026-10-10 between 10:44 and 10:48 UTC, in throwaway copies made with `git archive 9e7c61c5 scripts test` under `/tmp/u2c1-fcr3-*`; captured output in this replicate's scratch dir `/tmp/claude-1000/-workspace/54247aa5-2a95-449b-b931-3ed456da322c/scratchpad/u2c1-final-fc-r3/`, called `$SCR` below):
- **E1** `LC_ALL=C TMPDIR=$(mktemp -d /tmp/u2c1-fcr3-XXXX) bats --filter 'U2c1' test/scripts/build-loop-check.bats`, cwd `/tmp/u2c1-fcr3-asKI/base`, exit 0, 6/6 ok. Output: `$SCR/bats-u2c1-base.out`, `$SCR/probe1.log`.
- **E2** the same, cwd `/tmp/u2c1-fcr3-asKI/mutA` (check_line's `import_reset` line deleted), exit 1, test 6 fails at its `worktree list` count. Output: `$SCR/bats-u2c1-mutA.out`, `$SCR/probe2.log`.
- **E3** the same, cwd `/tmp/u2c1-fcr3-asKI/mutB` (check_line's `local -x LC_ALL=C` deleted), exit 1, test 6 fails at its C.utf8 step ("could not be walked for @ imports"). Output: `$SCR/bats-u2c1-mutB.out`, `$SCR/probe2.log`.
- **E4** a probe bats test appended to a copy, `bats --filter 'PROBE fcr3'`, cwd `/tmp/u2c1-fcr3-UDk0`, exit 0. A git shim moves the fixture's `.git` away right after the second brief's `cat-file --batch-check`, so the floor's need_root fails during brief 2. Observed: status 1, stdout holds only brief 1's two lines, stderr `dev-cycle-read.sh: ROOT_REAL is not a repository's top level; the caller cds there`. Script and output: `$SCR/probe4.sh`, `$SCR/probe4.log`.
- **E5** `bash $SCR/probe5.sh` (a throwaway repo: a directory replaced by a symlink and back, then `git diff-tree -r --no-renames --raw`), cwd its own mktemp dir, exit 0. Output: `$SCR/probe5.log`.
- **E6** `bash $SCR/probe6.sh` (400 × (2 need_root + 2 lower) in a sourced lib), exit 0: 1.139 s, 2.85 ms per path on this host. Output: `$SCR/probe6.log`.
- **E7** a probe bats test appended to the E4 copy, `bats --filter 'PROBE7 fcr3'`, cwd `/tmp/u2c1-fcr3-UDk0`, exit 0. Main holds `docs/reviews/code-review-2026-10-01-x.md` and brief x has `Paths: none`. The branch adds `docs/reviews/Code-Review-2026-10-01-x.md`, `docs/reviews/CODE-2026-10-01-x.md` and `docs/working/Plan-2026-10-01-x.md`. Observed: the two mixed-case reviews print `path` lines (they land), and only the Plan doc is denied. Script and output: `$SCR/probe7.sh`, `$SCR/probe7.log`.
- **E8** `LC_ALL=C TMPDIR=... bats test/scripts/build-loop-read.bats`, cwd `/tmp/u2c1-fcr3-asKI/base`, 19/20. The one failure (test 4) was this copy's missing `docs/dev-cycle.md`. Test 4 re-run with the file extracted passed (exit 0), so the suite is 20/20. Output: `$SCR/bats-read.out`, `$SCR/probe8.log`, `$SCR/probe9.log`.

---

## Claim 1: "A directory at an instruction-file name or an @-import target lands under self-merge (`src/CLAUDE.md/n.txt`, `docs/imp.md/n.txt` while main lacks the file): the floor tests the whole path only"

**Location:** `docs/reviews/override-log.md:608`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers floor's instruction test (basename only) and its import test (exact membership of the whole lower-cased path); does not establish what U2c2's planned fix does, and does not cover this row's availability argument.

isstart tests the last part, or `*.md` under a prompt directory:

```bash
# scripts/lib/dev-cycle-read.sh:663
isstart() { [[ "${1##*/}" =~ $INSTRUCTION_FILE ]] || [[ "$1" == *.md && ( "$1" =~ $PROMPT_DIR || "/$1" == */.claude/rules/* ) ]]; }
```

The import test is exact membership of the whole path: `main) main_imports || return 0; [[ "$IMPORTED_MAIN" == *$'\n'"$lp"$'\n'* ]] ;;` (`scripts/lib/dev-cycle-read.sh:1759`). So `src/CLAUDE.md/n.txt` (basename `n.txt`) and `docs/imp.md/n.txt` (not itself a member) pass both tests. floor (`:1827-1850`, read in full) has no per-ancestor test.

**Evidence:** `scripts/lib/dev-cycle-read.sh:663`, `scripts/lib/dev-cycle-read.sh:1754-1762`, `scripts/lib/dev-cycle-read.sh:1827-1850`

---

## Claim 2: "An added review named NAME-STEM.md can take a sibling brief's STEM.md name (`docs/reviews/2026-10-02-y-2026-10-01-x.md` lands for brief x)"

**Location:** `docs/reviews/override-log.md:609`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers ownfile's NAME-STEM match for the example; does not cover the row's reason that "an added review takes no existing name". That holds case-sensitively, but on a case-insensitive checkout a mixed-case added review can share an existing review's name (Claim 15b, E7).

```bash
# scripts/lib/dev-cycle-read.sh:1810
  [[ "$3" == A && "$1" == docs/reviews/* && "$b" != */* && ( "$b" == "$2.md" || "$b" == *"-$2.md" ) ]]
```

With `$2=2026-10-01-x`, the name `2026-10-02-y-2026-10-01-x.md` matches `*"-$2.md"`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1806-1811`

---

## Claim 3a: "floor forks twice per path to lower-case it and runs need_root twice"

**Location:** `docs/reviews/override-log.md:610`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers paths that reach truthwalk (every path the earlier floor arms pass); does not establish the count for paths an earlier arm refuses, which stop after one need_root and one lower.

floor runs `need_root` and then `lp="$(lower "$1")"` (`scripts/lib/dev-cycle-read.sh:1829-1832`). Its last arm, `elif truthwalk main "$lp"; then`, calls `isimported`, which runs `need_root` again and then `lp="$(lower "$2")" || return 0` (`:1755-1758`). `lower` is `printf '%s' "$1" | tr ...` inside `$(...)` (`:825`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:825`, `scripts/lib/dev-cycle-read.sh:1754-1762`, `scripts/lib/dev-cycle-read.sh:1794-1797`, `scripts/lib/dev-cycle-read.sh:1827-1850`

---

## Claim 3b: "~5.7 ms of the S rules' ~6.4 ms per path; 400 paths take 3.1 s against main's 0.3 s"

**Location:** `docs/reviews/override-log.md:610`
**Type:** Performance
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the order of magnitude of the four calls on this host; does not reproduce the 3,000-file fixture or the 400-path end-to-end timing.

E6 measured the four calls named in 3a at 2.85 ms per path on this host, against the row's ~5.7 ms. The numbers depend on the host and its load. Checking them needs the performance reviewer's fixture.

**Evidence:** `$SCR/probe6.log` (E6), `scripts/lib/dev-cycle-read.sh:160-164`, `scripts/lib/dev-cycle-read.sh:825`

---

## Claim 4: "the glob test is 0.12 ms per path on a 28 KB walk list, 43 ms only near IMPORT_OUT_MAX"

**Location:** `docs/reviews/override-log.md:611`
**Type:** Performance
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers nothing beyond the membership test's form (one bash glob over the walk string); does not establish the timings.

The test is `[[ "$IMPORTED_MAIN" == *$'\n'"$lp"$'\n'* ]]` (`scripts/lib/dev-cycle-read.sh:1759`), linear in the list's size, which fits the row's scaling. The figures need the performance reviewer's measurement setup.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1759`

---

## Claim 5: "A malformed Paths: line shows only as the same reason on every non-own deny line, while --status still prints POLICY self-merge"

**Location:** `docs/reviews/override-log.md:612`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers srules' reason and status_line's policy test; does not establish "every non-own" for paths the floor or a never glob refuses first, which carry their own reasons.

```bash
# scripts/build-loop.sh:666
  [[ -z "$PATHS_WHY" ]] || { DENY="the brief's Paths: line $PATHS_WHY, so only its own files land"; return 0; }
```

status_line's policy test reads only Policy: (`[[ "$POLICY" == self-merge && "${BRIEF[policy]-}" == "Policy: self-merge" ]] && pol=self-merge`, `scripts/build-loop.sh:501`). E1 test 3 asserts the per-path reason.

**Evidence:** `scripts/build-loop.sh:485-536`, `scripts/build-loop.sh:658-671`, `test/scripts/build-loop-check.bats:1967-1978`, `$SCR/bats-u2c1-base.out` (E1)

---

## Claim 6: "The concrete slip (a failed re-read printed no path line) is fixed: it now lands only own files with every line printed."

**Location:** `docs/reviews/override-log.md:613`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers check_line's re-read branch and the per-path loop after it; does not cover a test, since none fails a second read.

```bash
# scripts/build-loop.sh:816-818
  if [[ "$pol" == self-merge ]]; then
    if brief_fields "$a"; then read_paths; else PATHS=(); PATHS_WHY="could not be read again"; co="${co:-refuse $a: the brief could not be read again from the default branch}"; fi
  fi
```

The per-path loop and `printf '%s\n' "${rows[@]}"` run afterwards (`:830-837`). srules lands only ownfile matches while PATHS_WHY is set (`:665-666`).

**Evidence:** `scripts/build-loop.sh:769-838`

---

## Claim 7: "check_line's `local -x LC_ALL=C` is dynamic: status_line runs under C in --check but under the caller's locale in --status"

**Location:** `docs/reviews/override-log.md:615`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers where the local is set and the two call paths to status_line; does not cover the row's claim that status_line's output is the same either way.

`local -x LC_ALL=C` is check_line's first line (`scripts/build-loop.sh:771`), and check_line then runs `out="$(status_line "$a")"` (`:774`). In --status, `for a in "${ARGS[@]}"; do status_line "$a"; done` (`:843`) runs with no such local.

**Evidence:** `scripts/build-loop.sh:771-774`, `scripts/build-loop.sh:841-844`

---

## Claim 8: "Fixed for build-loop.sh: list_entries now parses both Self-merge never: and Paths: (and Paths: takes "none" as the settings lists do). The lib's reader_settings keeps its own copy"

**Location:** `docs/reviews/override-log.md:616`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two list_entries callers and reader_settings' separate parser; does not establish that there are no other list-line parsers.

The two callers are `list_entries "$t" "Self-merge never" glob globform` (`scripts/build-loop.sh:418`) and `list_entries "${BRIEF[paths]}" Paths path pathform` (`:629`). `[[ "$v" != none ]] || return 0` (`:370`) gives "none". reader_settings has its own `... ! "$v" =~ ^[^\ ]+(\ [^\ ]+)*$ ]]; then why="line ${first[$k]} is not exactly \"$key PATH ...\" with single spaces"` (`scripts/lib/dev-cycle-read.sh:625`).

**Evidence:** `scripts/build-loop.sh:357-379`, `scripts/build-loop.sh:418`, `scripts/build-loop.sh:629`, `scripts/lib/dev-cycle-read.sh:604-650`

---

## Claim 9: "list_entries depends on nothing in build-loop.sh (pathform, globform's NAMECHARS are the lib's), so it moves then"

**Location:** `docs/reviews/override-log.md:617`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers list_entries' own body (it calls only its FORM argument); does not establish that globform, a build-loop.sh function the never caller passes in, would need no move.

The body calls only `"$4" "${e%/}"` (`scripts/build-loop.sh:374`), plus bash builtins and its own LIST, LIST_WHY and LIST_BAD globals (`:363`). globform uses the lib's `$NAMECHARS` (`:384`).

**Evidence:** `scripts/build-loop.sh:357-389`

---

## Claim 10: "`Paths: P…` (`Paths: none` or no line lists none; a malformed or duplicate entry lands only the brief's own files: U2c1)"

**Location:** `docs/working/plan-build-loop-handoff.md:238`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers none, no line, a duplicate, a bad form and bare `Paths:`; does not cover which own files land (see Claim 15b).

E1 test 3 runs each of `Paths: docs/a docs/a/`, `Paths:  docs/a`, `Paths: docs/../x`, `Paths: /docs/a`, `Paths:`, `Paths: none` and no line, and asserts the reason (`test/scripts/build-loop-check.bats:1968-1977`). read_paths: `[[ -n "${BRIEF[paths]+set}" ]] || return 0` (`scripts/build-loop.sh:628`).

**Evidence:** `scripts/build-loop.sh:622-631`, `test/scripts/build-loop-check.bats:1967-1978`, `$SCR/bats-u2c1-base.out` (E1)

---

## Claim 11a: plan step 5 U2c1 note: the order (floor only when `co` is empty, never glob, allowlist), the never-glob semantics, the Paths: grammar, check_line in the parent shell with output to a file, need_root's exit ending the run, import_reset observable via a worktree-listing count, LC_ALL=C, the S rules off under review

**Location:** `docs/working/plan-build-loop-handoff.md:311`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed atom against the code and E1-E4; does not cover the "own file … lower case" atom (11b) or the carried override rows' own reasoning.

srules: `if [[ -z "$5" ]] && floor ...`, then the NEVER_RES loop, then ownfile and Paths: (`scripts/build-loop.sh:661-670`). The main loop runs `check_line "$a" > "$GATE_TMP/line"; cat "$GATE_TMP/line"` (`:858`). The S rules are skipped unless `"$pol" == self-merge` (`:833`). E2 and E3 show test 6 fails without import_reset or without the C locale. E4 shows need_root ending the run.

**Evidence:** `scripts/build-loop.sh:658-671`, `scripts/build-loop.sh:769-838`, `scripts/build-loop.sh:849-862`, E1-E4 logs

---

## Claim 11b: "an own file counts only when the diff spells it in lower case, as ownfile's patterns are (i1 security 2)"

**Location:** `docs/working/plan-build-loop-handoff.md:311`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers added reviews named NAME-STEM.md and working docs; does not establish whether a case-colliding added review is a security problem (that is the security critic's call).

ownfile pins the case of `docs/reviews/`, the STEM and `.md`, but not NAME:

```bash
# scripts/lib/dev-cycle-read.sh:1810
  [[ "$3" == A && "$1" == docs/reviews/* && "$b" != */* && ( "$b" == "$2.md" || "$b" == *"-$2.md" ) ]]
```

In E7, `docs/reviews/Code-Review-2026-10-01-x.md` and `docs/reviews/CODE-2026-10-01-x.md` both printed `path` (landed) under `Paths: none`, while main held `docs/reviews/code-review-2026-10-01-x.md`. On a case-insensitive checkout that added review takes an existing review's name. The rule holds for working docs (E7's `docs/working/Plan-…` was denied) and for STEM.md reviews.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1806-1811`, `scripts/build-loop.sh:665`, `$SCR/probe7.log` (E7)

---

## Claim 12a: "floor's per-path cost … the forks in lower and need_root, not row 470's membership test"

**Location:** `docs/working/plan-build-loop-handoff.md:312`
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the fork structure (as Claim 3a); does not establish the split between them, which is measured.

paraphrased — no quote available because the evidence is the same floor/isimported call chain quoted in Claim 3a (`scripts/lib/dev-cycle-read.sh:1829-1832`, `:1755-1758`), and the membership test is one in-process bash glob (`:1759`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1754-1762`, `scripts/lib/dev-cycle-read.sh:1827-1850`

---

## Claim 12b: "(i1 performance: 6.4 ms per path, 400 paths 3.1 s against main's 0.3 s …)"

**Location:** `docs/working/plan-build-loop-handoff.md:312`
**Type:** Performance
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed
**Scope:** As Claim 3b.

E6 found the same order of magnitude on this host (2.85 ms for the four fork-bearing calls). The end-to-end figures need the 3,000-file fixture.

**Evidence:** `$SCR/probe6.log` (E6)

---

## Claim 13: --help's N rules: "…anything under docs/working/briefs/ or docs/working/cycles/, or either as a file) and docs/constraints.md, or a path below one of those names."

**Location:** `scripts/build-loop.sh:167-172`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the as-a-file regex and the per-ancestor loop over truthrule's cycle, settings and user words; does not establish briefs/ as a file by test (only cycles/ is tested; the regex covers both).

```bash
# scripts/build-loop.sh:614-618
      *) [[ ! "$7" =~ ^docs/working/(briefs|cycles)(/|$) ]] || DENY="one of the dev cycle's own files" ;;
    esac
    while [[ -z "$DENY" && "$d" == */* ]]; do
      d="${d%/*}"; truthrule "$d" || true
      [[ ! "$TRUTH_WHY" =~ ^(cycle|settings|user)$ ]] || DENY="a path below the name of one of the dev cycle's own files or the constraints doc"
```

(excerpt ends :618; enclosing nrules() continues to :621 — read). E1 test 5 passes (roadmap.md/f, constraints.md/f, Docs/Dev-Cycle.md/x, questions.md/a/b, cycles as a file).

**Evidence:** `scripts/build-loop.sh:597-621`, `test/scripts/build-loop-check.bats:1993-2002`, `$SCR/bats-u2c1-base.out` (E1)

---

## Claim 14: --help's S rules: "…on each path the N rules pass but the brief's own file (first match): the self-merge floor (… instruction and prompt files and what they import with @, dot paths, the gate's own code, the user's and the cycle's records, a working doc or review that is not the brief's own; not run over a checkout refused above); a glob of --settings' never line, compared lower-cased, * and ? within one part, matching the path or a directory above it"

**Location:** `scripts/build-loop.sh:173-181`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the call condition, the order, floor's arms and never_res' regex for every character globform admits; does not cover floor's walk internals.

The call condition is `[[ -n "$DENY" || "$pol" != self-merge || "$p" == "$a" ]] || srules ...` (`scripts/build-loop.sh:833`). never_res maps `'*') re+='[^/]*' ;; '?') re+='[^/]' ;; .) re+='\.' ;; *) re+="$c" ;;` and appends `"^$re(/|\$)"` (`:644-646`), with glob and path both lower-cased (`:641`; `$3` is the lower-cased path). The other characters globform admits (letters, digits, `_ - /`) are literal in an ERE. E1 test 2 checks each floor arm against a listed path. E1 test 4 checks by-part, any-case and boundary matching (`workflowsx.md` lands).

**Evidence:** `scripts/build-loop.sh:633-671`, `scripts/build-loop.sh:833`, `scripts/lib/dev-cycle-read.sh:1827-1850`, `test/scripts/build-loop-check.bats:1948-1991`, E1

---

## Claim 15a: --help's own files: "(docs/working/{research,plan,checkpoint,handoff,test-strategy}-STEM.md, an added docs/reviews/STEM.md or NAME-STEM.md; … though the floor passes any case)"

**Location:** `scripts/build-loop.sh:182-186`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the list of patterns and floor lower-casing before ownfile; does not cover the "only in lower case" atom (15b).

The patterns match ownfile (`scripts/lib/dev-cycle-read.sh:1809-1810`). floor passes `ownfile "$lp" "$2" "$3"` on the lower-cased path (`:1843-1844`). In E1 test 3, `Docs/Working/Plan-2026-10-01-x.md` gets the Paths reason, not floor's WORK reason, so floor passed it.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1806-1811`, `scripts/lib/dev-cycle-read.sh:1843-1844`, E1

---

## Claim 15b: "the allowlist takes these only in lower case"

**Location:** `scripts/build-loop.sh:185-186`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers NAME-STEM.md reviews; does not dispute the lower-case rule for working docs and STEM.md reviews.

Same mechanism as Claim 11b: the NAME part of `docs/reviews/NAME-STEM.md` matches in any case (`( "$b" == "$2.md" || "$b" == *"-$2.md" )`, `scripts/lib/dev-cycle-read.sh:1810`). In E7 the allowlist took `docs/reviews/Code-Review-2026-10-01-x.md` and `docs/reviews/CODE-2026-10-01-x.md`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:1810`, `scripts/build-loop.sh:665`, `$SCR/probe7.log` (E7)

---

## Claim 16: --help: ""Paths: P ..." lists paths pathform allows, with single spaces, each once, compared exactly (a trailing / makes a directory, matched at a part boundary; unlike a never glob, an entry without one matches that file alone); "Paths: none" or no line lists none; any other line is malformed, and only own files land."

**Location:** `scripts/build-loop.sh:186-191`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers list_entries' grammar and srules' match; does not cover a second Paths: line (brief_fields keeps the first, as "first "Paths:" line" at :183 says).

```bash
# scripts/build-loop.sh:667-669
  for e in "${PATHS[@]}"; do
    [[ "$2" != "$e" && ( "$e" != */ || "$2" != "$e"* ) ]] || return 0
  done
```

(excerpt ends :669; enclosing srules() continues to :671 — read). `$e` is quoted, so the match is literal. E1 test 2: `docs/a` lands, `docs/ab.md` and `Hooks/x.sh` (Paths lists `hooks/x.sh`) are denied, and `docs/reviews/` covers a directory. brief_fields' awk keeps the first `Paths:` (`if (!(k in got))`, `scripts/lib/dev-cycle-read.sh:398`).

**Evidence:** `scripts/build-loop.sh:357-379`, `scripts/build-loop.sh:658-671`, `scripts/lib/dev-cycle-read.sh:386-410`, E1

---

## Claim 17: "After an ok line, a K of N refusal or a checkout refusal, one line per path TREE changes against main"

**Location:** `scripts/build-loop.sh:155-157`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers which verdict lines are followed by path lines; does not cover the refuse-WHY list's wording elsewhere.

The brief re-read refusal added on this branch (`co="${co:-refuse $a: the brief could not be read again from the default branch}"`, `scripts/build-loop.sh:817`) is also followed by every path line (`if [[ -n "$co" ]]; then echo "$co"; ...; printf '%s\n' "${rows[@]}"`, `:836-837`). It is not a checkout refusal. The precise version adds it: "an ok line, a K of N refusal, a checkout refusal or a brief re-read refusal".

**Evidence:** `scripts/build-loop.sh:812-837`

---

## Claim 18: Exit text: "A --check can also stop part way, after the lines of the briefs before, with 1 (need_root) or a failed command's own status: a caller reads any exit but 0 as nothing decided."

**Location:** `scripts/build-loop.sh:200-203`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the need_root path (E4); does not run a failing command under set -e, which follows from check_line running as a plain command at :858.

In E4, brief 1's `ok` and `path` lines printed. The run then exited 1 during brief 2 with need_root's message and no line for brief 2, because brief 2's output was still in `$GATE_TMP/line` (`check_line "$a" > "$GATE_TMP/line"; cat "$GATE_TMP/line"`, `scripts/build-loop.sh:858`).

**Evidence:** `scripts/build-loop.sh:849-862`, `scripts/lib/dev-cycle-read.sh:160-164`, `$SCR/probe4.sh`, `$SCR/probe4.log` (E4)

---

## Claim 19: list_entries' contract: "LINE is exactly "KEY: none" or "KEY: E ..." with single spaces (WORD names E in the reason), and each E, a trailing / dropped, passes FORM … and is listed once. Sets LIST (the entries as written, a trailing / kept; empty for none) or LIST_WHY, and LIST_BAD to form (the line's shape) or entry (an entry), or empty."

**Location:** `scripts/build-loop.sh:357-362`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the function body and both callers' use of LIST, LIST_WHY and LIST_BAD; does not cover reader_settings' separate copy.

```bash
# scripts/build-loop.sh:369-378
  if [[ "$1" != "$2: "* || ! "$v" =~ ^[^\ ]+(\ [^\ ]+)*$ ]]; then LIST_WHY="is not exactly \"$2: ${3^^} ...\" with single spaces"; LIST_BAD=form; return 0; fi
  [[ "$v" != none ]] || return 0
  IFS=' ' read -ra LIST <<<"$v"  # not a bare $v: the shell would expand * and ? against files
  for e in "${LIST[@]}"; do
    i=$((i + 1))
    if ! "$4" "${e%/}"; then LIST_WHY="lists entry $i, which is not an allowed $3 form"; break; fi
    if [[ -n "${seen[${e%/}]-}" ]]; then LIST_WHY="lists entry $i twice"; break; fi
    seen[${e%/}]=1
  done
  [[ -z "$LIST_WHY" ]] || { LIST=(); LIST_BAD=entry; }
```

The comments on :368 and :371 also hold: tabs survive the split (IFS is a single space) and FORM refuses them; a bare `$v` would glob. E1 test 3 and E8 (the --settings never-line tests) pass.

**Evidence:** `scripts/build-loop.sh:357-379`, E1, `$SCR/bats-read.out` (E8)

---

## Claim 20: "The form reason comes first, then the next line, then the entries." (read_settings' never line; brief claim: reasons and precedence unchanged)

**Location:** `scripts/build-loop.sh:419`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the reason texts and their precedence against main's version, plus the none and set outcomes; does not cover --settings' other lines.

New code: `if [[ "$LIST_BAD" != form && "${next[never]}" != 1 ]]; then why="is followed by a non-blank line outside a fence ..."` (`scripts/build-loop.sh:420`), which overrides an entry reason but not a form reason. Main's code tested shape, then next line, then none, then entries. Both give the same precedence. `${3^^}` with WORD `glob` gives the old text `"Self-merge never: GLOB ..."`. E8 passes 20/20.

**Evidence:** `scripts/build-loop.sh:396-425`, `git diff main...HEAD -- scripts/build-loop.sh` (old lines 369-390), E8

---

## Claim 21: nrules' comment: "the cycle's files (truthrule's cycle and settings words: writable() and docs/dev-cycle.md, plus anything under docs/working/briefs/ or docs/working/cycles/) and the constraints doc … compare lower-cased …; so does a path below one of those names (docs/roadmap.md/x …: row 523)"

**Location:** `scripts/build-loop.sh:590-595`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the comment against nrules' arms; does not establish any behavioural gap (the code covers more than the comment says).

The code also denies `docs/working/briefs` and `docs/working/cycles` as files (`^docs/working/(briefs|cycles)(/|$)`, `scripts/build-loop.sh:614`). --help says so ("or either as a file", `:170-171`), but this comment still says only "anything under". The precise version: "plus docs/working/briefs and docs/working/cycles and anything under them".

**Evidence:** `scripts/build-loop.sh:586-621`

---

## Claim 22: read_paths' comment: "as list_entries reads "Paths: PATH ...", each entry pathform's, a trailing / making it a directory; "Paths: none", or no line, lists none. Sets PATHS or, for a malformed line, PATHS_WHY (which lands only the brief's own files)."

**Location:** `scripts/build-loop.sh:622-625`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers read_paths and its use in srules; does not cover the own-files case rule (15b).

`list_entries "${BRIEF[paths]}" Paths path pathform; PATHS=("${LIST[@]}"); PATHS_WHY="$LIST_WHY"` (`scripts/build-loop.sh:629-630`). E1 test 3.

**Evidence:** `scripts/build-loop.sh:622-631`, E1

---

## Claim 23: never_res' comment: "NEVER's globs as regexes for a lower-cased path (a denylist, so case folds): * and ? match within one part, and a glob matches the path or any directory above it (a trailing / changes nothing). Set once, after read_settings."

**Location:** `scripts/build-loop.sh:633-635`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the regex construction and the single call site; does not cover a NEVER changed after the call (none is).

`g="$(lower "${g%/}")"` (`scripts/build-loop.sh:641`). The single call is `read_settings; never_res` (`:850`). E1 test 4.

**Evidence:** `scripts/build-loop.sh:633-647`, `scripts/build-loop.sh:850`, E1

---

## Claim 24: srules' comment: "Sets DENY, first match winning: the floor (only when $5 is empty: it walks the checkout), a Self-merge never: glob, then the allowlist (Paths:, or ownfile)."

**Location:** `scripts/build-loop.sh:649-654`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers srules' order and its floor guard; does not cover the comment's lower-case conclusion (Claim 25).

See the code quoted in Claims 14 and 16 (`scripts/build-loop.sh:660-670`). Inside the allowlist, ownfile is tested before PATHS_WHY and Paths: entries, so own files land even when the line is malformed. That matches "(Paths:, or ownfile)".

**Evidence:** `scripts/build-loop.sh:649-671`

---

## Claim 25: srules' comment: "The allowlist widens nothing by case: Paths: entries compare exactly, and ownfile gets the path as spelled, so an own file passes only when the diff spells it in lower case (ownfile folds nothing)."

**Location:** `scripts/build-loop.sh:654-657`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the "passes only when … lower case" conclusion for NAME-STEM.md reviews; the mechanism atoms ("compare exactly", "as spelled", "folds nothing") are true.

The mechanism is right: `! ownfile "$2" "$1" "$4" || return 0` passes the spelled path (`scripts/build-loop.sh:665`). The conclusion is refuted: ownfile's `*"-$2.md"` (`scripts/lib/dev-cycle-read.sh:1810`) accepts any case in NAME, and E7 landed `docs/reviews/Code-Review-2026-10-01-x.md`. The conclusion holds for working docs and STEM.md reviews only.

**Evidence:** `scripts/build-loop.sh:649-671`, `scripts/lib/dev-cycle-read.sh:1806-1811`, `$SCR/probe7.log` (E7)

---

## Claim 26: check_line's comment: "It runs in the caller's shell, so an exit (need_root's) ends the run, and set -e applies to its own lines but not inside a helper called in a condition (floor and its walk, brief_fields, checkout_gate, nul_list) or in $(...), which refuse by their own guards."

**Location:** `scripts/build-loop.sh:761-764`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers each named helper's call site and the exit path (E4); does not establish that set -e cannot fire inside nrules, srules, read_paths or list_entries, which run outside conditions. Each line there was read and none fails on a normal path.

The call sites are `if [[ -z "$5" ]] && floor ...` (`scripts/build-loop.sh:661`), `if brief_fields "$a"` (`:817`), `! checkout_gate` (`:811`) and `if ! nul_list ...` (`:829`). Neither file sets inherit_errexit (a grep finds no match), so bash clears -e inside `$(...)`. E4 shows the exit ending the run.

**Evidence:** `scripts/build-loop.sh:658-671`, `scripts/build-loop.sh:769-838`, E4

---

## Claim 27: "Nothing but its locals and the walk caches it resets may carry from one brief to the next: each helper empties its own globals before use (DENY, PATHS and PATHS_WHY, LIST and LIST_WHY, BRIEF, CHECKOUT_WHY, FLOOR_WHY, TRUTH_WHY)."

**Location:** `scripts/build-loop.sh:765-767`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers each named global's reset point; does not cover walk globals that import_reset does not clear (recomputed after a reset), and a review brief keeps the previous brief's PATHS and BRIEF without reading them.

The resets are DENY (`:599`, `:660`), PATHS and PATHS_WHY (`:627`, or explicitly at `:817`), LIST, LIST_WHY and LIST_BAD (`:367`), BRIEF (`scripts/lib/dev-cycle-read.sh:390`), CHECKOUT_WHY (`scripts/build-loop.sh:694`), FLOOR_WHY (`scripts/lib/dev-cycle-read.sh:1830`) and TRUTH_WHY (`:1778`). srules is the only reader of PATHS, and it runs only for self-merge (`scripts/build-loop.sh:833`), after read_paths or the explicit reset.

**Evidence:** `scripts/build-loop.sh:597-631`, `scripts/build-loop.sh:658-671`, `scripts/build-loop.sh:769-838`, `scripts/lib/dev-cycle-read.sh:386-410`, `scripts/lib/dev-cycle-read.sh:1777-1787`

---

## Claim 28: "Contract item 1 (the floor's walk); exported, so its children run under it too."

**Location:** `scripts/build-loop.sh:770`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the walk running under C during --check; does not cover locales other than C.utf8.

With `local -x LC_ALL=C` deleted (E3), test 6's walk under `LC_ALL=C.utf8` fails ("could not be walked for @ imports"). With it, the walk passes (E1).

**Evidence:** `scripts/build-loop.sh:770-771`, `$SCR/bats-u2c1-mutB.out` (E3), E1

---

## Claim 29: "The S rules' inputs, read again from main's commit (status_line read them in a subshell). … A failed read refuses the verdict as a checkout refusal does (path lines still print, the floor does not run)."

**Location:** `scripts/build-loop.sh:812-815`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the branch quoted in Claim 6; does not cover a test of it.

`co` set non-empty at `:817` both suppresses floor (`[[ -z "$5" ]]`, `:661`) and replaces the verdict line (`:836`). status_line runs in `$(...)` (`:774`).

**Evidence:** `scripts/build-loop.sh:769-838`

---

## Claim 30: "In this shell, not $(...): the floor's need_root exit ends the run, and check_line's import_reset is what keeps one brief's walk from the next."

**Location:** `scripts/build-loop.sh:856-857`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both effects, by E4 and E2; does not cover other caches.

E2: with import_reset deleted, two self-merge briefs share one `worktree list` and test 6 fails. E4: the need_root exit ends the run.

**Evidence:** `scripts/build-loop.sh:856-860`, `$SCR/bats-u2c1-mutA.out` (E2), E4

---

## Claim 31: "open_shared  # once, in this shell: status_line runs in a subshell"

**Location:** `scripts/build-loop.sh:851`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers why the call is in the parent; does not cover open_shared's own contents.

`[[ -z "$OPEN_SHARED" ]] || return 0` (`scripts/lib/dev-cycle-read.sh:501`) makes it compute once per process. status_line calls `open_shared` again inside `$(...)` (`scripts/build-loop.sh:487`, `:774`), and there it hits the parent's cached value.

**Evidence:** `scripts/lib/dev-cycle-read.sh:497-513`, `scripts/build-loop.sh:485-488`

---

## Claim 32: lib header item 3: "(U2b2; its check_line runs the walk under item 1's LC_ALL=C)"

**Location:** `scripts/lib/dev-cycle-read.sh:63`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** As Claim 28.

See Claim 28 (`scripts/build-loop.sh:771`, E3).

**Evidence:** `scripts/build-loop.sh:770-771`, E3

---

## Claim 33: lib header item 5: "build-loop.sh reads diff-tree -r of main and the merge instead, where a symlink or gitlink above a path is a changed entry of its own. … build-loop.sh's N rules apply them, and pathform, under both policies, and its S rules run floor only on a path they pass"

**Location:** `scripts/lib/dev-cycle-read.sh:79-86`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a directory to symlink replacement and back (E5) and srules' call guard; does not run a gitlink case (diff-tree -r does not descend into a gitlink, which shows as a 160000 entry).

E5's output:

```
:000000 120000 ... A	a
:100644 000000 ... D	a/x
```

So the symlink is its own entry, and the N rules' mode test denies it (`scripts/build-loop.sh:601`). srules runs only when `DENY` is empty (`:833`).

**Evidence:** `$SCR/probe5.log` (E5), `scripts/build-loop.sh:597-621`, `scripts/build-loop.sh:833`

---

## Claim 34: lib header item 8: "Pass truthrule, isstart, ownfile, prompt_dir and prompt_bases a lower-cased path"

**Location:** `scripts/lib/dev-cycle-read.sh:90-91`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers ownfile's entry in item 8; does not dispute the item for truthrule, isstart, prompt_dir or prompt_bases.

This branch made srules pass ownfile the path as spelled, on purpose: `! ownfile "$2" "$1" "$4" || return 0` (`scripts/build-loop.sh:665`). ownfile's comment now says "for a path $1 (it folds no case: floor passes it lower-cased, build-loop.sh srules as spelled)" (`scripts/lib/dev-cycle-read.sh:1800-1801`). Item 8, the caller contract, still tells every caller to lower-case ownfile's path, which contradicts that caller and the comment.

**Evidence:** `scripts/lib/dev-cycle-read.sh:90-93`, `scripts/lib/dev-cycle-read.sh:1800-1801`, `scripts/build-loop.sh:665`

---

## Claim 35: ownfile's comment: "for a path $1 (it folds no case: floor passes it lower-cased, build-loop.sh srules as spelled)"

**Location:** `scripts/lib/dev-cycle-read.sh:1800-1801`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers ownfile's body and both call sites; does not cover the case of NAME (see Claim 25).

ownfile compares with `=~` and `==` on `$1` and never lower-cases it (`:1807-1810`). floor calls it with `"$lp"` (`:1843-1844`), and srules with `"$2"` (`scripts/build-loop.sh:665`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1806-1811`, `scripts/lib/dev-cycle-read.sh:1843-1844`, `scripts/build-loop.sh:665`

---

## Claim 36: "FLOOR_WHY=""  # read by floor's caller (build-loop.sh srules)"

**Location:** `scripts/lib/dev-cycle-read.sh:1825`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers build-loop.sh; does not establish that no other script reads FLOOR_WHY (the test harness also prints it).

`DENY="$FLOOR_WHY"` (`scripts/build-loop.sh:661`).

**Evidence:** `scripts/build-loop.sh:661`

---

## Claim 37: test title "--check self-merges listed paths (exec bit, a directory entry), the brief's own working docs and added reviews, and its Status line (T9, U2c1)"

**Location:** `test/scripts/build-loop-check.bats:1938`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the assertions against the title; does not cover a modified review (correctly not an own file).

The test asserts `ok`, 13 lines, `path $B M $B`, and a `path` line for each of the 11 files, which include `chmod +x scripts/other.sh`, `skills/x/` and `test/` entries, three working docs and two added reviews (`:1939-1946`). E1 ok 1.

**Evidence:** `test/scripts/build-loop-check.bats:1938-1946`, E1

---

## Claim 38: test title "--check refuses a self-merge path the floor names though Paths: lists it, a symlink at a listed path, and a path Paths: does not list exactly (T10, rows 349, 474, U2c1)"

**Location:** `test/scripts/build-loop-check.bats:1948`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the assertions; the row-474 gitlink half is not exercised by this test.

The test asserts every floor reason (instr, imp, dot, gate, rec, work, rev) for listed paths, `deny … scripts/link.sh: $NMODE` and NLIST for `docs/ab.md`, `Hooks/x.sh` and `scripts/x.sh` (`:1955-1964`). E1 ok 2.

**Evidence:** `test/scripts/build-loop-check.bats:1948-1965`, E1

---

## Claim 39: test title "--check: a malformed Paths: line lands only the brief's own files, spelled in lower case; Paths: none or no line lists nothing (T10, U2c1 i1)"

**Location:** `test/scripts/build-loop-check.bats:1967`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the assertions (a lower-case working doc lands, an upper-case one is denied, docs/a is denied); does not establish "own files … spelled in lower case" for added NAME-STEM.md reviews, which this test does not exercise and which land in any case (E7).

The assertions match the title for the working-doc pattern (`has "path $B A docs/working/plan-2026-10-01-x.md"`, the denied `Docs/Working/Plan-…`, `:1976-1977`). The title states the case rule for own files generally, and the code does not hold it for NAME-STEM.md (Claim 25). E1 ok 3.

**Evidence:** `test/scripts/build-loop-check.bats:1967-1978`, E1, E7

---

## Claim 40: test title "--check: a Self-merge never: glob refuses a listed path under self-merge, by part and in any case; review ignores it (T45, U2c1)"

**Location:** `test/scripts/build-loop-check.bats:1980`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the assertions; does not cover a `?` glob.

The test asserts `Workflows/Z.md` (any case), `docs/sub/n.txt` landing (by part), `workflowsx.md` landing (boundary), and under review status 0 with 7 lines (`:1984-1990`). E1 ok 4.

**Evidence:** `test/scripts/build-loop-check.bats:1980-1991`, E1

---

## Claim 41: test title "--check refuses a path below a cycle file's or the constraints doc's name, and cycles/ as a file (an N rule; row 523, U2c1)"

**Location:** `test/scripts/build-loop-check.bats:1993`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the assertions; does not test briefs/ as a file.

The test uses a review brief (`gated feat/x`, so it is an N rule) and asserts four below-name denials and `docs/working/cycles: $NOWN` (`:1994-2001`). E1 ok 5.

**Evidence:** `test/scripts/build-loop-check.bats:1993-2002`, `test/scripts/build-loop-check.bats:1475`, E1

---

## Claim 42: test title "--check walks once per self-merge decision (check_line's import_reset, in the parent shell) and under the C locale (contract items 1, 4; row 532, U2c1)"

**Location:** `test/scripts/build-loop-check.bats:2004`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test failing under each mutation; "walks once" is measured by the proxy of one `worktree list` per decision, not by counting walks directly.

E1: ok. E2 (import_reset removed): fails at `grep -c '^worktree list' … -eq 2`. E3 (LC_ALL=C removed): fails at the C.utf8 step. C.utf8 is installed here (`locale -a`), so the locale step is not vacuous.

**Evidence:** `test/scripts/build-loop-check.bats:2004-2016`, E1, E2, E3

---

## Claim 43: commit 9e7c61c5: "C1: a failed brief re-read refuses the verdict (path lines still print). C2: list_entries sets LIST_BAD, so read_settings no longer reads its wording. C3: ownfile's comment: it folds no case."

**Location:** `scripts/build-loop.sh:817`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers C1-C3 against the code; does not cover C4/C5 beyond Claims 17-18 and 9.

`co="${co:-refuse $a: the brief could not be read again ...}"` (`:817`). read_settings tests `"$LIST_BAD" != form` (`:420`). The ownfile comment is at `scripts/lib/dev-cycle-read.sh:1800`.

**Evidence:** `scripts/build-loop.sh:817`, `scripts/build-loop.sh:420`, `scripts/lib/dev-cycle-read.sh:1800-1801`

---

## Claim 44a: commit d435100e: "B1: ownfile gets the path as spelled, so an own file lands only in lower case."

**Location:** `scripts/build-loop.sh:665`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** As Claim 25; commit messages are immutable, so this is for the record.

Same defect as Claim 25: E7 landed `docs/reviews/Code-Review-2026-10-01-x.md` (`*"-$2.md"`, `scripts/lib/dev-cycle-read.sh:1810`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1810`, E7

---

## Claim 44b: commit d435100e: "Making bare "Paths:" malformed changes no outcome (both land only own files)"

**Location:** `scripts/build-loop.sh:369`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the landing outcome; the deny reason text differs (malformed against NLIST), which the commit does not deny.

Bare `Paths:` fails `"$1" != "$2: "*` (`:369`). With PATHS_WHY set, srules lands only ownfile matches, as an empty PATHS would. E1 test 3 covers `Paths:`.

**Evidence:** `scripts/build-loop.sh:369`, `scripts/build-loop.sh:665-670`, E1

---

## Claim 45: commit eddfd5f9: ""Paths:" alone or no line lists none"

**Location:** `scripts/build-loop.sh:369`
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the bare-`Paths:` atom; commit messages are immutable.

d435100e made bare `Paths:` malformed (its own message says so). E1 test 3 asserts `"Paths:|is not exactly \"Paths: PATH ...\" with single spaces"` (`test/scripts/build-loop-check.bats:1970`).

**Evidence:** `scripts/build-loop.sh:369`, `test/scripts/build-loop-check.bats:1968-1977`, E1

---

## Claim 46: commit eddfd5f9: "check_line now runs in the parent shell under LC_ALL=C (contract item 1), so the floor's need_root exit ends the run and import_reset is observable: a test counts one worktree listing per self-merge decision. nrules also refuses a path below a cycle file's or the constraints doc's name, and docs/working/{briefs,cycles} as a file (row 523)."

**Location:** `scripts/build-loop.sh:771`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** As Claims 13, 28 and 30.

paraphrased — no quote available because each atom is quoted in Claims 13, 28 and 30 (`scripts/build-loop.sh:614-618`, `:771`, `:858`) and executed by E1-E4.

**Evidence:** `scripts/build-loop.sh:614-618`, `scripts/build-loop.sh:771`, `scripts/build-loop.sh:858`, E1-E4

---

## Claim 47a: commit eddfd5f9: "Tests: build-loop-check 138, build-loop-read 20 … 229 changed code lines."

**Location:** `test/scripts/build-loop-check.bats:1938`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two suites counted and the line total as insertions plus deletions in scripts/ and test/; dev-cycle 79 and the fixture suites were not counted or run.

`git show eddfd5f9:test/scripts/build-loop-check.bats | grep -c '^@test'` gives 138 (main 132). E8 runs 20 build-loop-read tests. `git diff --numstat main...eddfd5f9 -- scripts test` gives 105+15, 12+9 and 87+1, which is 229. (Checked against the hallucination log's suite-count pattern: both counts hold.)

**Evidence:** `test/scripts/build-loop-check.bats:1938-2016`, E8

---

## Claim 47b: commit eddfd5f9: "Timing on a 3,284-file clone: 3.6 s for 1 path, 6.1 s for 150, 7.6 s for 400."

**Location:** `scripts/build-loop.sh:849-862`
**Type:** Performance
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Not re-run; needs the 3,284-file clone.

The final brief's same-fixture figures (branch 0.57/1.50/3.13 s) are a different measurement setup. The commit's figures cannot be reproduced without its clone.

**Evidence:** `scripts/build-loop.sh:849-862`

---

## Claim 48: commit 62877331: "fact-check 0 Incorrect, 1 Stale, 1 Mostly accurate"

**Location:** `docs/reviews/override-log.md:608`
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** The i1 fact-check report is an artifact outside this pass's scope and was not read.

paraphrased — no quote available because the claim concerns a review artifact this brief puts out of scope.

**Evidence:** `docs/reviews/override-log.md:608-617`

---

## Claims Requiring Attention

### Incorrect
- **Claim 11b** (`docs/working/plan-build-loop-handoff.md:311`): "an own file counts only when the diff spells it in lower case" is false for added `docs/reviews/NAME-STEM.md`. NAME matches in any case (E7 landed `Code-Review-2026-10-01-x.md` beside main's `code-review-…`). Narrow the claim, or make ownfile/srules pin NAME's case.
- **Claim 15b** (`scripts/build-loop.sh:185-186`): --help's "the allowlist takes these only in lower case": same NAME-STEM.md exception.
- **Claim 25** (`scripts/build-loop.sh:654-657`): srules' "an own file passes only when the diff spells it in lower case": same exception. The mechanism ("ownfile folds nothing") is right.
- **Claim 44a** (commit d435100e, `scripts/build-loop.sh:665`): "an own file lands only in lower case": same exception (immutable).

### Stale
- **Claim 34** (`scripts/lib/dev-cycle-read.sh:90-91`): contract item 8 still says pass ownfile a lower-cased path. srules now passes it as spelled, and ownfile's comment says so.
- **Claim 45** (commit eddfd5f9): '"Paths:" alone … lists none' was superseded by d435100e (bare `Paths:` is malformed).

### Mostly Accurate
- **Claim 17** (`scripts/build-loop.sh:155-157`): path lines also follow the brief re-read refusal (`:817`), not only ok, K of N and checkout refusals.
- **Claim 21** (`scripts/build-loop.sh:590-591`): nrules' comment omits that briefs/ and cycles/ as files are denied (`:614`).
- **Claim 39** (`test/scripts/build-loop-check.bats:1967`): the title's "own files, spelled in lower case" holds for the working doc it tests, not for NAME-STEM.md reviews.

### Unverifiable
- **Claim 3b** (`docs/reviews/override-log.md:610`): ms and s figures. Needs the performance fixture (this host: 2.85 ms for the four calls).
- **Claim 4** (`docs/reviews/override-log.md:611`): membership-test timings. Needs the performance setup.
- **Claim 12b** (`docs/working/plan-build-loop-handoff.md:312`): 6.4 ms, 3.1 s and 0.3 s. Needs the fixture.
- **Claim 47b** (commit eddfd5f9): the 3,284-file clone timings.
- **Claim 48** (commit 62877331): the i1 report's counts (artifact out of scope).

No Incorrect verdict is a fabrication (every symbol named exists), so nothing is appended to `docs/reviews/hallucination-patterns.md`.

## Goal-Alignment Note

Success criterion, restated verbatim: "a markdown report saved at the output path your dispatch names, structured per your skill, every finding with verbatim Evidence and a path:line." This report is at `docs/reviews/code-fact-check-report-build-loop-u2c1-final-r3.md` in the worktree and starts with `**Commit:** 9e7c61c5`. It uses the skill's header fields and seven per-claim fields. Every finding quotes the code or carries a tagged paraphrase with a path:line. Executed claims name their command, cwd, exit code and time, and point to captured output in this replicate's scratch dir.
