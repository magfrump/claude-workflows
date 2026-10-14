Commit: 1bc823ea

# API Consistency Review — feat/build-loop-u4c (U4c, loop pass i1)

**Scope:** `git diff main...feat/build-loop-u4c` (6 files): the D6 snippet's contract in `skills/dev-cycle/SKILL.md`, its call sites, the bats helpers, comments and plan text
**Date:** 2026-10-13
**Based on:** docs/reviews/code-fact-check-report-2026-10-13-u4c-i1.md (Stage 1, k=1)

## Baseline Conventions

- **Script contract (build-loop.sh, the snippet).** Exit 0 is an answer. Exit 2 comes with machine lines whose first token names the producer (`refuse state`, `refuse main-log:`, `refuse d6:`) on stdout. Exit 1 is a usage or internal error, reported on stderr (`d6: the first argument is …`; build-loop.sh's `Unknown option: … (usage: …)`). questions.sh has only 0 and 1 (`die()` → `✗ questions.sh: …` on stderr, exit 1; `scripts/questions.sh:76`), so exit 2 from a questions.sh call through the snippet can only mean `refuse d6:`. That separation holds.
- **SKILL.md call sites.** Each call names its script and the checkout it runs from: "through the D6 block from WT" (steps 0.4 and 1) or "from MAIN_WT" (steps 0.1 and 0.2). The Rules give the general form once (`SKILL.md:36-59`).
- **Bats helpers** (`test/scripts/build-loop-orchestrator.bats`): short `noun`/`noun_verb` names (`bl`, `d6`, `d6_is`, `state_is`, `lc_is`, `cd_is`). `*_is WANT` asserts exit 2 plus exactly WANT; setup helpers set globals (`D6`, `U`, `B`, `T`).

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `questions.sh` as SCRIPT (first argument) | CLI argument value | `build-loop.sh`, `dev-cycle.sh` | `skills/dev-cycle/SKILL.md:224` | Consistent: a bare script basename, like its two siblings |
| `d6: the first argument is build-loop.sh, dev-cycle.sh or questions.sh` | usage message | the old text with two names | `test/lib/d6-snippet.bash` (deleted) at main | Consistent: same shape, list extended; the test asserts the new text (`bats:295`) |
| `refuse d6: X is not a regular file` (now for the image files only) | refusal line | `refuse d6: X is not root-owned, a plain path and unwritable here` | `SKILL.md:159,175` | Consistent shape; see F3 for the missing-file case |
| "The D6 block" section as the canonical copy | doc anchor that a test parses | the `hg()` one-liner, which a test also greps from SKILL.md | `bats:336-337` (hg grep) | Consistent: SKILL.md text is already a test fixture |
| `d6_copy OPT [trust]` (was `d6_copy ROOT OPT`) | test helper | `d6_setup`, `d6_is`, `shim` | `test/scripts/build-loop-orchestrator.bats:233-246` | Consistent naming. Signature changed; all 5 callers updated. See F5 for the flag form |
| `opt_copy DIR` | test helper | `d6_copy`, `commit_all`, `brief` | `bats:233-240` | Consistent: `noun_verb`, matches `d6_copy` |
| `refuse d6: X is missing` | refusal text (test stub only) | real `own()` text | `bats:237` | Test only; never produced by the real snippet (see F3) |

## Findings

#### F1. The Rules' D6 sentences still scope the call form, the stop semantics and the timeout stop to "build-loop.sh and dev-cycle.sh"; step 1 contradicts them for questions.sh

**Severity:** Inconsistent
**Location:** `skills/dev-cycle/SKILL.md:36-59`, `:360-363`, `:689`
**Move:** 3 (consumer contract), 4 (error consistency)
**Confidence:** High
**Legibility-target:** the orchestrator reading the Rules as the contract for every snippet call

Evidence (Rule): "Every `build-loop.sh` and `dev-cycle.sh` call
  runs from WT (step 0's first two from MAIN_WT; step 7's self-merge from its GT …)" and "but a call of either
  script that the Bash tool timed out, and a `refuse d6:` line, are stops too." The questions.sh sentence was added only at the end: "`questions.sh` runs through the D6 block
  too (its first argument), never as `~/.claude/scripts/questions.sh`, a uid-owned link."

Evidence (step 1): "run `questions.sh init` … and then
  `questions.sh archive` (it also reindexes) through the D6 block from WT, so
  answered entries leave the live file. If either fails, note it in the record and go on".

The snippet now accepts three scripts, and the block section says so ("SCRIPT is `build-loop.sh`, `dev-cycle.sh` or `questions.sh`", `:190-191`). The Rule that defines what a call's result means does not. A reader cannot tell whether a timed-out questions.sh call is a stop, since "either script" names two. A `refuse d6:` line from `questions.sh init` is a stop under the Rule but a "note it and go on" failure under step 1. Step 9's "after `questions.sh index` and `check` in WT" (`:689`) does not say what an exit 1 from `check` means, and does not repeat "through the D6 block". Before U4c, questions.sh ran outside the snippet, so the Rule's two-script wording was accurate. This diff routed questions.sh through the snippet and made the wording incomplete.

**Recommendation:** Make the first Rule sentence "Every `build-loop.sh`, `dev-cycle.sh` and `questions.sh` call", and change "either script" to "any of them". In step 1, say that a `refuse d6:` line (exit 2) is a stop as the Rules say, while a questions.sh exit 1 is noted and the step goes on. In step 9, say what an exit 1 from `check` means (it stops the land, or the fix is staged first).

#### F2. Plan text still promises main's-copy extraction and "the gate itself does not wait"

**Severity:** Inconsistent
**Location:** `docs/working/plan-build-loop-handoff.md:77`, `:157-158`, `:396`, `:432`
**Move:** 3 (documentation drift)
**Confidence:** High
**Legibility-target:** a reader of the plan's D6, its F/T tables and the "image lags main" risk

Evidence: `:432` "The installed skill (`~/.claude/skills`) is the image copy, so the orchestrator loop runs in this repo only after a release (step 12). The gate itself does not wait (D6)." `:396` T33: "extracts the four files into `$T/scripts/{,lib/}` … the SKILL.md block and `test/lib/d6-snippet.bash` are byte-equal". `:77` "The gate runs from main's commit". `:158` F40: "`questions.sh` extracted too (T33)".

The superseded note at `:81` covers only the D6 bullets. Under Q-140 [1], the gate does wait for the image. That is now the main operational consequence (the image at 774a0eef lacks `--land-cycle`: `Unknown option: --land-cycle` from `/opt/claude-workflows/scripts/build-loop.sh`). `:432` states the opposite. T33's row names a file this diff deletes and a mechanism (temp-dir extraction, byte equality) that no longer exists. Stage 1 also flagged these lines as Stale; they are filed here because readers of the plan rely on them.

**Recommendation:** Change `:432` to say the gate also waits for the release. Rewrite the T33 row to describe what the test now asserts (one block in SKILL.md, no main or home read, the image copy run by absolute path). Mark `:77`, F39 and F40 as superseded by Q-140 [1], as `:81` already does.

#### F3. A missing image file is reported as "not root-owned, a plain path and unwritable", and the test asserts stub text instead

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:159`, `:174-176`; `test/scripts/build-loop-orchestrator.bats:237`, `:293`
**Move:** 4 (error consistency)
**Confidence:** High
**Legibility-target:** the orchestrator or user filing the `refuse d6:` line in an `agent` entry

Evidence: `own() { [[ ! -L "$1" && -e "$1" && "$(stat -c %u -- "$1")" == 0 && ! -w "$1" ]] || no "$1 is not root-owned, a plain path and unwritable here"; }`. Test: `rm "$U/scripts/questions.sh"; d6_is "refuse d6: $U/scripts/questions.sh is missing"`.

With the image as the only copy, an image that predates or lacks one of the four files is now a realistic failure, and an old image is the known state. That case gets a refusal worded as an ownership or tampering problem rather than a missing file. The header's list ("one of those files … that is not root-owned, a plain path and unwritable here") never names "missing". The only test of the missing case asserts the stub's `is missing` text, which the real snippet never prints. So the documented refusal set and the tested refusal set differ (Stage 1 also noted this).

**Recommendation:** Either split `own()` so a missing path refuses with "`X` does not exist" (and name that case in the header), or keep the single message and make the trust stub reuse it, so the test asserts the real text.

#### F4. questions.sh's own messages tell the operator to run the spelling the Rules forbid

**Severity:** Informational
**Location:** `scripts/questions.sh:74`, `:137`, `:279`, `:296` (not changed by the diff; reached through it)
**Move:** 3 (consumer contract)
**Confidence:** High
**Legibility-target:** the orchestrator reading `check`/`index` output in step 9

Precedent: messages name the canonical installed path, used in `scripts/questions.sh:74` (`QS_CMD='~/.claude/scripts/questions.sh'`)

Evidence: `echo "  ✗ $(basename "$file"): index is stale — run: $QS_CMD index" >&2`, against SKILL.md:58-59 "never as `~/.claude/scripts/questions.sh`, a uid-owned link."

The orchestrator now runs questions.sh only through the snippet, but the script's remediation hints still name `~/.claude/scripts/questions.sh`. The Rules treat script output as data, so this is not an instruction hazard. It is still a contradictory hint at the moment the orchestrator is fixing a stale index. This is a naming finding with precedent, so its severity was not downgraded; it stays Informational because the Rules already neutralise the hint.

**Recommendation:** No code change is needed in this unit. Optionally add a clause in step 9: "questions.sh's 'run: …' hints mean the same command through the D6 block".

#### F5. `d6_copy`'s `trust` is any non-empty second argument

**Severity:** Informational
**Location:** `test/scripts/build-loop-orchestrator.bats:237`
**Move:** 2 (naming/contract of a helper)
**Confidence:** High
**Legibility-target:** the next test author calling `d6_copy`

No existing precedent in `test/scripts/build-loop-orchestrator.bats` helper definitions (no other helper takes a mode word; the `*_is` helpers take a WANT string)

Evidence: `[[ -z "${2:-}" ]] || { grep -q '^  own() { ' "$D6" && sed -i …`

Any second argument, `false` included, swaps out the ownership check. This is harmless today: there are five callers, and the only one that passes a second argument passes `trust`. Under the no-precedent rule the severity drops from Minor to Informational.

**Recommendation:** Match the literal: `[[ "${2:-}" != trust ]] ||`, and have any other non-empty value fail.

#### F6. The digest's "questions.sh missing" cause is now unreachable through the snippet

**Severity:** Informational
**Location:** `skills/dev-cycle/SKILL.md:408-411`; `scripts/dev-cycle.sh:390`
**Move:** 3 (documentation drift)
**Confidence:** Medium
**Legibility-target:** a reader of step 3

Evidence: SKILL.md "(with the cause: a skipped questions file or archive, questions.sh missing, or `questions.sh open` failing)"; dev-cycle.sh `[[ -f "$QS" ]] || QS="$HOME/.claude/scripts/questions.sh"`.

The snippet now refuses before dev-cycle.sh runs unless the image's questions.sh is present and root-owned. So when the digest runs through D6, neither the "missing" cause nor the `~/.claude/scripts` fallback can occur. The text is still correct for dev-cycle.sh run by other routes, so this is a note, not a defect.

**Recommendation:** None required. Optionally note "(not reachable through the D6 block)".

## What Looks Good

- **Refusal set and handling text agree.** No text anywhere outside `docs/reviews/` and the archives still promises or routes the removed perl, Digest, temp-dir, "read whole" or "does not hash" refusals. I grepped for `d6-snippet`, `refuse d6`, `D6_ROOT`, `verified reader`, `temp dir` and `perl` over the repo. The Rules' `refuse d6:` handling (exit 2, nothing ran, a stop) is generic and matches the new header's list exactly.
- **Exit codes stay disjoint per script.** questions.sh never exits 2 (`die` exits 1), so exit 2 through the snippet unambiguously means `refuse d6:` for it. For build-loop.sh, the first-line rule disambiguates.
- **One copy, test-anchored.** The awk extraction (`bats:236`) keys on the exact `## The D6 block` heading and call-form line. T33 asserts both lines occur exactly once (`bats:255`) and that the last extracted line is `d6 "$@" </dev/null`. So an edit that breaks the anchors fails the test instead of passing silently. The `G=(env …)` line is grep-counted as exactly one in SKILL.md before the HARDEN pin compares it (`bats:336`).
- **The usage message and its test moved together.** Each refusal string in the header has a matching `d6_is` assertion, except the missing-file case (F3).
- **The image's questions.sh supports every mode SKILL.md calls** (`init`, `archive`, `index`, `check`, `open`). It is byte-identical to the branch's copy (`cmp` clean). So routing questions.sh through the image changes no mode contract today.
- **The comment updates are consistent with the new contract:** `scripts/build-loop.sh:1040-1043` (the snippet-reader aside removed) and `scripts/lib/dev-cycle-read.sh:1962-1966` (GATE_CODE rationale).

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| F1 | Rules scope call form, stops and timeout to two scripts; step 1 "note and go on" contradicts the `refuse d6:` stop; step 9 check exit unspecified | Inconsistent | `skills/dev-cycle/SKILL.md:36-59,360-363,689` | High |
| F2 | Plan still says the gate does not wait, T33 names the deleted file, D6/F39/F40 describe extraction | Inconsistent | `docs/working/plan-build-loop-handoff.md:77,157-158,396,432` | High |
| F3 | Missing image file refused as "not root-owned…"; test asserts stub-only "is missing" | Minor | `skills/dev-cycle/SKILL.md:159,174-176`; `bats:237,293` | High |
| F4 | questions.sh hints name `~/.claude/scripts/questions.sh`, which the Rules forbid | Informational | `scripts/questions.sh:74,279,296` | High |
| F5 | `d6_copy`'s `trust` is any non-empty argument | Informational | `bats:237` | High |
| F6 | "questions.sh missing" digest cause unreachable through D6 | Informational | `skills/dev-cycle/SKILL.md:408-411` | Medium |

## Overall Assessment

The snippet's own contract is consistent and well tested: three accepted scripts, the `refuse d6:` line plus exit 2, the usage line plus exit 1, and a header that lists exactly the refusals the code makes. Nothing still routes the deleted perl, Digest or temp-dir refusals. The inconsistencies are at the edges. First, the Rules' definition of what a call result means was not widened when questions.sh joined the snippet, and step 1's failure handling now contradicts it for a `refuse d6:` line (F1). Second, the plan still says the gate does not wait for the image, which is the opposite of the consequence Q-140 [1] accepted (F2). Both are text-only fixes in place. The missing-file wording (F3) matters more now that an old image is the expected state, and is a one-line fix. Consumer impact is low: the orchestrator's behaviour is still defined for every case except the questions.sh failure path.

## Goal-Alignment Note
- Success criterion (restated verbatim): a report saved to /workspace/.claude/wt-build-loop-u4c/docs/reviews/api-consistency-review-2026-10-13-u4c-i1.md (first line `Commit: 1bc823ea`), structured per the skill.
- Answered: the snippet's contract (first argument set, refusal lines, exit codes, usage message) checked against SKILL.md's Rules and every call site (step 0.1/0.2 from MAIN_WT, 0.4 digest, step 1 init/archive, step 7 GT, step 9 index/check, step 3's questions.sh mention, line 74's `--state` rerun). Checked whether any `refuse d6:` handling text still promises the removed refusals (none does). Checked the bats helpers' contract (`d6_copy OPT [trust]`, `opt_copy`, `d6_setup`'s `U`, `d6_is`).
- Out of scope: PATH and uid-writable interpreter resolution, and questions.sh's unhardened git (security-reviewer; Stage 1 flagged both). The override-log D6 rows were not re-filed (canonical copy, refuse-d6 handling, trust root); none of these findings changes their basis. bats was not re-run (Stage 1 reports 25/25).
- Escalate: none. F1 and F2 are text fixes within U4c's scope.
