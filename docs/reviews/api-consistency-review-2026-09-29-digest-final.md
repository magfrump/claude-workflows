Commit: 3aee138

# API Consistency Review — feat/dev-cycle-digest (final confirming pass)

**Scope:** `git diff main...HEAD`: `scripts/dev-cycle.sh`, `test/scripts/dev-cycle.bats`, and the commit message
**Date:** 2026-09-29
**Based on:** brief-digest-final.md, plus the pass-1 fixes it lists (commit 89a3d3b)

> ⚠️ **No code fact-check report provided.** API documentation claims have not been
> independently verified against implementation. For full verification, run the
> `code-fact-check` skill first or use the code-review orchestrator. (To make up for this, I checked the header and commit-message claims on my surfaces by running the script in throwaway repos under the scratchpad. The results are below.)

## Baseline Conventions

Surveyed `scripts/questions.sh`, `scripts/skill-usage-report.sh`, `scripts/flag-removal-candidates.sh`, `scripts/archive-working-docs.sh`, `scripts/run-tests.sh`, `scripts/confine-tests.sh`, `scripts/health-check.sh`.

- **Flags:** long options, `--name=value` form (`--project=`, `--round=`, `--markdown`). Only the `=` form is parsed in the siblings.
- **Unknown option:** `echo "Unknown option: $arg" >&2; exit 1` (skill-usage-report, flag-removal-candidates, archive-working-docs). run-tests and confine-tests use exit 2 for usage errors, so the repo is split, but 1 is the majority.
- **Help:** only some scripts have `-h|--help` (run-tests, confine-tests). questions.sh prints its `# Usage:` header block with `sed`, which is the same pattern dev-cycle uses.
- **Env overrides:** the header documents them, and each is named with a script-specific prefix (`QUESTIONS_LIVE`, `QUESTIONS_ARCHIVE`, `USAGE_LOG_FILE`, `SKILLS_DIR`).
- **Repo resolution:** acts on the git toplevel of `$PWD`, not on the repo the script lives in (questions.sh header), and installs to `~/.claude/scripts/`.
- **Output:** questions.sh `open` prints `ID  route  slug` in columns separated by 2+ spaces. dev-cycle consumes that format correctly (`awk -F'  +'`).

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `scripts/dev-cycle.sh` | script | `questions.sh`, `skill-usage-report.sh`, `flag-removal-candidates.sh` | `scripts/*.sh` | Consistent: kebab-case, `.sh` |
| `--since=YYYY-MM-DD` | CLI flag | `git log --since` (health-check.sh:838, code-review SKILL.md:171) | `scripts/health-check.sh` | Consistent: reuses git's own term. Midnight anchoring is documented |
| `--sample=N` | CLI flag | `--round=`, `--project=` | `scripts/flag-removal-candidates.sh`, `scripts/skill-usage-report.sh` | Consistent `--name=value` shape. Also accepts `--sample N`, which is a superset of sibling behaviour |
| `-h`/`--help` | CLI flag | `-h\|--help` | `scripts/run-tests.sh:104`, `scripts/confine-tests.sh:58` | Consistent |
| exit 1 (usage / not a repo / no branch) | exit code | exit 1 on unknown option | `scripts/{skill-usage-report,flag-removal-candidates,archive-working-docs}.sh` | Consistent with the majority. The documented contract is partly unmet (F3) |
| `Unknown option: $1` | error text | identical string | same three scripts | Consistent |
| `DEV_CYCLE_TODAY` | env var | `QUESTIONS_LIVE`, `USAGE_LOG_FILE` | `scripts/questions.sh` header, `scripts/skill-usage-report.sh:33` | Name consistent (script prefix). Undocumented in help and only pins part of the date use (F4) |
| `## 1. Activity` … `## 5. Roadmap` | digest headings | none (first markdown digest consumed by a skill) | none — searched `scripts/` for numbered `## N.` output | New contract. Stable, tested by test 1 |
| `### <path> (last changed <date>)`, `- log row N (date): …`, `Carried forward (N): …` | digest line shapes | none | none — searched `scripts/` | New contract. See F5 on the carried-forward list |

## Findings

#### F1. The digest labels itself as describing `main`, but sections 2 and 5 read the checked-out tree and HEAD

**Severity:** Inconsistent
**Location:** `scripts/dev-cycle.sh:91, 114-126, 192-195`
**Move:** 7 (asymmetry) / 3 (consumer contract)
**Confidence:** High

The Window line says ``on `main` at <sha>``, and section 1 uses `$MAIN_SHA`. Section 2 globs `docs/decisions/*.md` from the working tree and runs `git log -1 --since … -- "$f"` against HEAD. Section 5 reads `docs/roadmap.md` from the working tree. Probe: on a branch `feat` holding a decision record that `main` lacks, the digest printed "on `main` at 61a1c1b" and then printed `### docs/decisions/001-a.md (last changed 2026-09-29)`. The stacked skill will read the header as the scope of the whole digest. Run from a feature branch, it will judge triggers that `main` does not have.

**Recommendation:** Either read sections 2 and 5 from `$MAIN_SHA` (`git show "$MAIN_SHA:<path>"` and `git log "$MAIN_SHA" …`), or keep the working-tree behaviour and state it in the Window line (e.g. "triggers and roadmap from the working tree at `<branch>`"). The second is the cheaper fix, and the skill can say to run on `main`.

#### F2. An uncommitted file gets an empty date, and an uncommitted decision record is carried forward as if it already had a verdict

**Severity:** Inconsistent
**Location:** `scripts/dev-cycle.sh:118-124, 121, 193`
**Move:** 8 (nullability)
**Confidence:** High

For an untracked file, `git log -1 --format=%ad -- f` exits 0 with empty output. As a result:
- (a) section 2 prints `(last changed )`;
- (b) section 5 prints `docs/roadmap.md last changed . Its Next section:`, because the `|| echo 'never (uncommitted)'` fallback on line 193 never runs (dead code);
- (c) after a cycle record exists, a new uncommitted decision record has an empty `changed`, so it lands in `Carried forward (1): 001-a.md`. The section's own text says a carried item's "verdict carries forward from docs/working/cycles/cycle-…md", and this record has no verdict to carry.

All three were reproduced. Case (c) is a silent miss of the kind this script exists to prevent.

**Recommendation:** Treat an empty `git log` result as "uncommitted". Print that date text in both places (e.g. `${d:-uncommitted}`), and print such records in full instead of carrying them. Alternatively, key "changed" on "not present at the cycle record's commit".

#### F3. `--since` checks the date's shape, not whether it is a real date: `2026-13-45` exits 0

**Severity:** Minor
**Location:** `scripts/dev-cycle.sh:85`
**Move:** 3 (documented contract: "1 bad usage")
**Confidence:** High

`--since=2026-13-45` passes the regex and prints a full digest with `Window: since 2026-13-45` and rc=0. git interprets the malformed date however it chooses. The header promises exit 1 on bad usage.

**Recommendation:** Add `date -d "$SINCE" +%F >/dev/null 2>&1 || { echo "--since must be a valid YYYY-MM-DD date" >&2; exit 1; }` after the regex. The script already depends on GNU `date -d`.

#### F4. `DEV_CYCLE_TODAY` pins only the title and the sample seed, not the default window, and help does not mention it

**Severity:** Minor
**Location:** `scripts/dev-cycle.sh:45-46, 82`
**Move:** 3
**Confidence:** High

The comment says the variable exists "so tests can pin the date". With `DEV_CYCLE_TODAY=2020-01-01` and no cycle record, the digest title says 2020-01-01 but the window is `since 2026-09-15`, because `date -d '14 days ago'` uses the real clock. A test that pins the date and relies on the default window will depend on when it runs. questions.sh documents its env overrides in the header that `--help` prints. This variable sits on line 45, outside the `sed -n '2,23p'` help range.

**Recommendation:** Compute the default as `date -d "$TODAY - 14 days" +%F`. Then either add a line to the header's usage block, or state there that the variable is test-only.

#### F5. The "Carried forward" list mixes two naming forms in one space-separated list

**Severity:** Minor
**Location:** `scripts/dev-cycle.sh:124, 140, 146`
**Move:** 7 (asymmetry; digest as a machine-read contract)
**Confidence:** Medium

A record printed in full is labelled `### docs/decisions/001-old.md`, but the same record, when carried, is `001-old.md`. Carried log rows are `log row 8`, which contains spaces, and all items are joined with single spaces (`Carried forward (2): 001-old.md log row 8`). A human can read this. The stacked skill, or any grep that matches carried names against the previous cycle record, has no clean way to split items.

**Recommendation:** Use the same identifier form as the full-print lines, and join with `, ` (e.g. `Carried forward (2): docs/decisions/001-old.md, log row 8`). Update test 3's expected string to match.

#### F6. `--sample=0` reports "No merges in the window to sample." even when there are merges

**Severity:** Minor
**Location:** `scripts/dev-cycle.sh:180-187`
**Move:** 4 (message accuracy)
**Confidence:** High

With one merge in the window and `--sample=0`, section 4 claims there are no merges. Section 1 of the same digest lists one, so the digest contradicts itself.

**Recommendation:** Split the two cases: `Sampling disabled (--sample=0).` versus the no-merges message.

#### F7. The window's source note nests parentheses, and a flag name appears as its "source"

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:78, 83, 91`
**Move:** 2
**Confidence:** High

This renders as `Window: since 2026-09-15 (from no cycle record found, so the default of 14 days (the previous cycle, if any, did not write its record)), …` and as `(from --since)`. Both are readable but awkward in a header that the skill reads.

**Recommendation:** Reword the notes so each fits `(from …)` without nesting, e.g. `the --since flag` and `the 14-day default: no cycle record found`.

#### F8. The option-name regression test guards two layers together, so it cannot show which one holds

**Severity:** Informational
**Location:** `test/scripts/dev-cycle.bats:185-195`; `scripts/dev-cycle.sh:58, 95`
**Move:** 3
**Confidence:** High

Mutation results on scratch copies:
- removing only the `-*` skip (line 58) passes;
- passing `$MAIN` instead of `$MAIN_SHA` to `git log` passes;
- doing both fails.

So both defences work, and the test catches their joint removal. That is the right property for a security regression test, but one layer could rot without any test failing.

**Recommendation:** Optional: add a unit-level assertion that the only ref argument given to git is a 40-hex hash (e.g. check the Window line's short sha against `rev-parse`). Or accept as is.

#### F9. The boundary "log row dated exactly on SINCE prints in full" is correct but untested

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:132`; `test/scripts/dev-cycle.bats:66-79`
**Move:** 3
**Confidence:** High

Mutating `! "$d" < "$SINCE"` to `"$d" > "$SINCE"` (which excludes the boundary day) still passes test 3, because its rows are dated 2020 and 2099. The code behaves as its message says ("dated on or after it").

**Recommendation:** Optional: add a row dated on the cycle-record date to test 3.

## What Looks Good

- **Pass-1 fixes hold (all executed):**
  - An option-like origin/HEAD cannot reach git; the victim file stays intact.
  - `-p` is skipped. A detached HEAD with no main/master, or an empty repo, exits 1 with a clear message. The same happens when the current branch has an option-like name.
  - `--since` is anchored at midnight.
  - The questions.sh failure is reported.
  - master-only repos and runs from a subdirectory with a relative path both work.
  - The seed changes with the date. Test 7 fails if it reverts to `yes "$TODAY"`, and test 5 fails if the midnight anchor is removed.
- The flag surface matches the siblings: `--name=value`, `Unknown option: …` then exit 1, `-h|--help` printing the header like questions.sh. `--since` reuses git's own vocabulary.
- An explicit `--since` prints everything in full (`source_note == "--since"` sets `full=1`), which matches the brief's intended contract.
- The digest's five numbered headings are a stable contract that test 1 pins. The questions.sh `open` column format is consumed correctly, including the space inside the `you: judgment` route.
- The header's "read-only" claim holds: nothing is written except a `mktemp` file that the trap removes.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---|---|---|---|
| 1 | Digest claims `main`; sections 2 and 5 read the working tree and HEAD | Inconsistent | `dev-cycle.sh:91,114-126,192` | High |
| 2 | Uncommitted files: empty date, dead fallback, new record carried with no verdict | Inconsistent | `dev-cycle.sh:118-124,193` | High |
| 3 | `--since` accepts impossible dates, exit 0 | Minor | `dev-cycle.sh:85` | High |
| 4 | `DEV_CYCLE_TODAY` doesn't pin the default window; missing from help | Minor | `dev-cycle.sh:45,82` | High |
| 5 | Carried-forward list: mixed name forms, ambiguous separator | Minor | `dev-cycle.sh:124,140,146` | Medium |
| 6 | `--sample=0` says "No merges" | Minor | `dev-cycle.sh:180-187` | High |
| 7 | Nested parentheses in the window source note | Informational | `dev-cycle.sh:78,83` | High |
| 8 | Option-name test guards two layers together | Informational | `dev-cycle.bats:185` | High |
| 9 | SINCE-day boundary untested | Informational | `dev-cycle.sh:132` | High |

## Overall Assessment

The CLI surface is consistent with the sibling scripts, and every pass-1 fix holds under execution, including the hostile-name cases. No finding is Breaking. The two Inconsistent findings concern the digest's contract with its stacked consumer:
- **F1:** the header claims a scope (`main`) that sections 2 and 5 don't honour;
- **F2:** an uncommitted decision record is silently carried forward as if it had a verdict.

Both can be fixed in place with a few lines each. F3–F6 are small accuracy fixes. None of these needs a redesign.

## Goal-Alignment Note
- **Answered:** a confirming API-consistency pass on flags, exit codes, help, the digest markdown contract, `DEV_CYCLE_TODAY`, and consistency with questions.sh and other scripts. Pass-1 fixes were verified by execution, and mutation-checked 5 behaviours (midnight, seed, option-name ×3 variants, SINCE boundary).
- **Out of scope:** security exploitability beyond re-checking the named fix; performance; mutation of all 13 tests (I mutated the ones relevant to my surfaces); portability of GNU `date -d`/`shuf`/`sha256sum` beyond noting that health-check.sh already uses `date -d`.
- **Escalate:** F1 and F2 are contract choices the stacked skill depends on: whether the digest should describe `main` or the working tree, and how uncommitted records should be handled. The author should decide before feat/dev-cycle builds on them.
