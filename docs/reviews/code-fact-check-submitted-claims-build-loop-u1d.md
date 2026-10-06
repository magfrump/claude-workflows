Commit: 83cdb005

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u1d (branch feat/build-loop-u1d)
**Scope:** Submitted claims S1-S4 only (Stage 2.5, k=1); no fresh harvesting. Numbering continues from the merged report's Claim 25.
**Checked:** 2026-10-06
**Total claims checked:** 4
**Summary:** 4 verified, 0 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Execution setup (shared by every executed claim): each variant is a `git archive 83cdb005 scripts test` copy under the scratch directory `/tmp/claude-1000/-workspace/57e599b8-f769-48da-96c7-3a02f99f2a8d/scratchpad/review-u1d/s25/<variant>/`. No tracked file was modified. Suite command, run in each `<variant>/` directory with `TMPDIR=$S/tmp`: `timeout 500 bats test/scripts/build-loop-read.bats test/scripts/dev-cycle.bats > ../<variant>.log`. Run 2026-10-06T04:54:56Z to 04:55:34Z. Every variant exited 1, because build-loop-read.bats test 4 ("--settings on this repo's own docs/dev-cycle.md") also fails on the unmutated `base` copy: it copies `$REPO_ROOT/docs/dev-cycle.md`, and the archive copy has no `docs/`. That failure comes from the environment, appears in every variant, and has no bearing on any claim below. Logs: `$S/<variant>.log`, exit codes: `$S/<variant>.rc`. No logged hallucination pattern (docs/reviews/hallucination-patterns.md) matches these claims.

| Variant | Mutation | Failing tests besides env test 4 |
|---|---|---|
| base | none | none |
| s1 | main_entry guard reverted to main's `main_by_name \|\| { echo error; return; }` (no pathform) | 92 (dev-cycle.bats "main_entry refuses a path pathform refuses") |
| s3a | build-loop.sh:112 replace-ref config pair deleted | 5, 17 |
| s3b | pair added only when the caller set no GIT_CONFIG_COUNT | 17 only |
| s3c | pair exported but GIT_CONFIG_COUNT not bumped | 5, 17 |
| s3d | `GIT_NO_REPLACE_OBJECTS=1` dropped (pair kept); a control, not the claim's subject | none |
| s4 | brief_fields' `! pathform "$1" \|\|` dropped | none |

---

## Submitted Claims

## Claim 26: "main_entry's new pathform guard leaves every current caller's output unchanged (brief_fields, check_brief, check_answer, build-loop.sh main_file)."

**Submitted by:** security-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:263`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every non-test call site of main_entry at 83cdb005 (dev-cycle-read.sh:296, :334, :554; build-loop.sh:124 by way of main_file's two callers at :210 and :260) and the existing test call at dev-cycle.bats:1234. It does not establish anything about future callers that pass unvetted paths, such as U2's floor on changed paths, where the new guard does change the answer from absent to error.

The new guard is `if ! main_by_name || ! pathform "$1"; then echo error; return; fi` (`scripts/lib/dev-cycle-read.sh:263`). It can change output only for a path that pathform refuses. Every caller either refuses such a path itself before calling, or passes a fixed name that pathform accepts:
- brief_fields: `if ! pathform "$1" || [[ "$(main_entry "$1")" != blob ]]; then BRIEF_ODD=error; return 1; fi` (`scripts/lib/dev-cycle-read.sh:296`). The `||` short-circuits, so main_entry never sees a refused path.
- check_brief: `if ! pathform "$a"; then echo "skip ${a//$'\n'/ }: not an allowed path form"; return; fi` (`scripts/lib/dev-cycle-read.sh:327`) comes before `e="$(main_entry "$a")"` (`:334`). Read from the signature at :323 through the main_entry case at :335-341 and the brief_fields call at :342.
- check_answer: `for f in docs/working/questions.md docs/working/questions-archive.md; do e="$(main_entry "$f")"` (`scripts/lib/dev-cycle-read.sh:553-554`). These are fixed names.
- main_file: `e="$(main_entry "$f")"` (`scripts/build-loop.sh:124`), where f is `local f=docs/dev-cycle.md` (`:206`) or `f=docs/constraints.md` (`:259`). Again fixed names.

Execution shows pathform accepts all four fixed names. Command: `LC_ALL=C bash -c 'source base/scripts/lib/dev-cycle-read.sh; for p in ...; do pathform "$p" && echo "pass $p" || echo "FAIL $p"; done'`, cwd `$S`, exit 0, 2026-10-06T04:55:45Z. Output: `pass` for all four (`$S/pathform-fixed.log`). The grep for callers (`grep -rn -e main_file -e brief_fields -e main_entry scripts test`) finds no other call site, and dev-cycle.sh does not call main_entry directly. On the suites, the s1 variant (main's pre-U1d guard) and base fail the same tests apart from test 92, which is the new U1d test aimed at the guard itself. No caller-level assertion in either suite tells the two apart.

**Evidence:** `scripts/lib/dev-cycle-read.sh:260-275`, `scripts/lib/dev-cycle-read.sh:291-315`, `scripts/lib/dev-cycle-read.sh:323-342`, `scripts/lib/dev-cycle-read.sh:549-570`, `scripts/build-loop.sh:121-136`, `scripts/build-loop.sh:205-210`, `scripts/build-loop.sh:259-260`; logs `$S/pathform-fixed.log`, `$S/base.log`, `$S/s1.log`

---

## Claim 27: "the U1d dev-cycle.bats test 'main_entry refuses a path pathform refuses' fails when the guard is removed."

**Submitted by:** security-reviewer
**Location:** `test/scripts/dev-cycle.bats:1328`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers removing the pathform half of the guard (reverting to main's line). It does not establish that each of the four paths would catch the removal alone: `../x` still answers error without the guard, because ls-tree refuses it, so only the other three paths carry the test.

Mutant s1 replaces `if ! main_by_name || ! pathform "$1"; then echo error; return; fi` with main's `main_by_name || { echo error; return; }`. Under it, test 92 fails at `test/scripts/dev-cycle.bats, line 1334` and prints `absent / error / absent / absent` for `"a\"b.md" "../x" "-x" "docs//x.md"` instead of four `error` lines (`$S/s1.log`). Command: the suite command in the setup note, cwd `$S/s1`, exit 1, 2026-10-06T04:54:56Z. The test asserts all four lines in one string comparison, `[ "$output" = "error\nerror\nerror\nerror" ]` (`test/scripts/dev-cycle.bats:1331-1334`), so any one path changing fails it. The base copy passes test 92.

**Evidence:** `test/scripts/dev-cycle.bats:1328-1335`, `scripts/lib/dev-cycle-read.sh:263`; logs `$S/s1.log`, `$S/base.log`

---

## Claim 28: "the U1d --settings test's GIT_CONFIG_COUNT step fails when build-loop.sh's replace-ref guard pair is lost."

**Submitted by:** security-reviewer
**Location:** `test/scripts/build-loop-read.bats:420-425`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers three ways the pair at `scripts/build-loop.sh:112` could be lost: deleted, skipped when the caller sets a count, and exported without the count bump. The step fails at its own assertion (:425) in all three. It does not establish coverage of `GIT_NO_REPLACE_OBJECTS=1` (:113). Dropping that line alone fails no test, and with core.useReplaceRefs=true in the repo it does not protect anything without the pair.

The pair is `cfg="${GIT_CONFIG_COUNT:-0}"; export "GIT_CONFIG_KEY_$cfg=core.useReplaceRefs" "GIT_CONFIG_VALUE_$cfg=false" GIT_CONFIG_COUNT=$((cfg + 1))` (`scripts/build-loop.sh:112`). The step sets up a replace ref with `git config core.useReplaceRefs true` and runs `env GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=user.name GIT_CONFIG_VALUE_0=caller bash "$BL" --settings` (`test/scripts/build-loop-read.bats:423-424`). It then asserts `[[ "$(line policy)" == "policy review set:"* ]]` (`:425`). Results for the variants (suite command, cwd `$S/<variant>`, each exit 1, 2026-10-06T04:54:56Z):
- s3a (pair deleted): test 17 fails `in test file test/scripts/build-loop-read.bats, line 425` and prints `policy self-merge set: line 1 of docs/dev-cycle.md on the default branch`, which is the replacement blob. Test 5 also fails.
- s3b (pair added only when the caller set no count): only test 17 fails, at line 425, with the same output. The new step is the only test that catches this mutant.
- s3c (pair exported, count not bumped): test 17 fails at line 425. Test 5 also fails.
- s3d (control, `GIT_NO_REPLACE_OBJECTS=1` dropped): no test fails beyond env test 4.

**Evidence:** `test/scripts/build-loop-read.bats:420-425`, `scripts/build-loop.sh:107-114`; logs `$S/s3a.log`, `$S/s3b.log`, `$S/s3c.log`, `$S/s3d.log`

---

## Claim 29: "dropping brief_fields' own pathform check (`! pathform "$1" ||` at :296) changes no behaviour now that main_entry checks pathform. BRIEF_ODD, BRIEF contents and every output path checked, including whether anything between :296 and the main_entry call reads the path first."

**Submitted by:** performance-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:296`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers brief_fields' return code, BRIEF_ODD and BRIEF, and the two suites, for refused paths, an accepted brief and a missing default branch, while main_entry keeps its :263 guard. It does not establish that the redundancy stays harmless if main_entry's guard is later removed or weakened. brief_fields would then depend on main_entry alone.

brief_fields reads `local - out l; set -o pipefail` / `BRIEF=(); BRIEF_ODD=""` / `if ! pathform "$1" || [[ "$(main_entry "$1")" != blob ]]; then BRIEF_ODD=error; return 1; fi` (`scripts/lib/dev-cycle-read.sh:294-296`). The function was read through its end at :315. Within this line, nothing reads `$1` before main_entry. The first read of `$1` after the check is `git cat-file blob "$MAIN_SHA:$1"` (`:299`), which runs only once the check has passed. In main_entry, `if ! main_by_name || ! pathform "$1"; then echo error; return; fi` (`:263`) is the first statement after the locals. A refused path therefore yields `error`, and that is `!= blob`. The mutant takes the same branch and sets the same `BRIEF_ODD=error; return 1`, with BRIEF already emptied at :295. The only difference is the order of checks inside main_entry (main_by_name before pathform), and both failures produce the same `error`.

Executed probe: in a scratch repo `$S/probe` holding one brief, `brief_fields` ran on `"a\"b.md" "../x" "-x" "docs//x.md" ".git/HEAD"`, then on the real brief, then on `../x` with `MAIN_SHA=""`, against base and s4. Command: `LC_ALL=C bash -c 'set -euo pipefail; source "$1"; resolve_main; ...' _ ../<variant>/scripts/lib/dev-cycle-read.sh`, cwd `$S/probe`, exit 0 for both, 2026-10-06T04:55:53Z. `diff` of the two outputs: IDENTICAL. Each refused path gives `rc=1 odd=[error] n=0`, the brief gives `rc=0 odd=[] n=2 status=[Status: open]`, and the no-main case gives `rc=1 odd=[error]` (`$S/s4probe-base.log`, `$S/s4probe-s4.log`). On the suites, s4 fails nothing beyond env test 4 (`$S/s4.log`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:260-275`, `scripts/lib/dev-cycle-read.sh:291-315`; logs `$S/s4probe-base.log`, `$S/s4probe-s4.log`, `$S/s4.log`

---

## Claims Requiring Attention

None among the submitted claims. Notes for the orchestrator:
- **Claim 27**: `../x` does not test the guard on its own (it answers error either way), so the test rests on its other three paths.
- **Claim 28**: `GIT_NO_REPLACE_OBJECTS=1` at build-loop.sh:113 has no test that fails without it.

Where `$S` = `/tmp/claude-1000/-workspace/57e599b8-f769-48da-96c7-3a02f99f2a8d/scratchpad/review-u1d/s25`.

## Goal-Alignment Note

The task was verdicts on S1-S4 only, with no fresh harvesting. All four are Verified by mutants on scratch copies and by direct probes. No tracked file was modified, and this report is the only file written in the worktree. Two coverage notes sit next to the claims but outside them (the `../x` redundancy and the untested `GIT_NO_REPLACE_OBJECTS`). They are recorded as scope residue, not as findings. Neither blocks landing U1d.
