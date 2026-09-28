Commit: 77a4ca5

# Code Fact-Check Report

**Repository:** claude-workflows (worktree `u4-code-review-skill`, branch `feat/u4-code-review-skill`)
**Scope:** branch diff `git diff main...feat/u4-code-review-skill` (docs/decisions/log.md, skills/code-review/SKILL.md, skills/code-review/references/rubric.md) plus commit message of 77a4ca5
**Checked:** 2026-09-28
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 23
**Summary:** 14 verified, 9 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`); no claim matches a logged pattern. Each claim carries a `Legibility-target:` tag naming the reader whom the claim has to serve.

---

## Claim 1: "The enforcement set is the one `hooks/live-verify-gate.sh` gates."

**Location:** `docs/decisions/log.md:83`
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the existence of a single named regex in the hook that selects enforcement files. It does not establish that the hook is the canonical owner of the list (see Claim 17).
**Legibility-target:** future SKILL maintainer

The hook defines a grep-able regex under the variable name `enforcement` and uses it to select the files it gates:

```sh
# hooks/live-verify-gate.sh:73-74
enforcement='^devcontainer-config/(Dockerfile|devcontainer\.json|init-firewall\.sh|cc-sni-proxy\.py|link-claude-home\.sh|cc-isolated\.sh|cc-exit-scan\.sh|cc-gitdir\.sh|cc-push\.sh|install\.sh$|egress/)'
touched="$(printf '%s\n' "$files" | grep -E "$enforcement" | sort -u)"
```

`$files` holds repo-relative paths from `git diff --cached --name-only` (`hooks/live-verify-gate.sh:63`), so the regex applies directly to the `git diff --name-only` output a review would use.

**Evidence:** `hooks/live-verify-gate.sh:63`, `hooks/live-verify-gate.sh:70-74`

---

## Claim 2: "In Q-076 every fact-check round had a red, so the security, architecture, performance and API critics first ran after four rounds, and security then found 2 High ('don't merge') issues"

**Location:** `docs/decisions/log.md:83` (repeated at `skills/code-review/SKILL.md:704-707`)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High for the 2 High findings. Medium for "four rounds", which is sourced only from the proposal.
**Verification mode:** static
**Scope:** Covers the 2 High findings and the merge-blocking recommendation in the Q-076 security review, and the proposal's statement of the round count. It does not independently reconstruct the round count from the Q-076 artifacts.
**Legibility-target:** decision-log reader auditing the rationale

The Q-076 security review has two findings rated `**Severity:** High` (`docs/reviews/q076-security-review-2026-09-27.md:48`, `:64`) and closes with "**Recommend: do not merge until Findings 1 and 2 are fixed**" (`docs/reviews/q076-security-review-2026-09-27.md:185`). The proposal states: "The security, architecture, performance and API critics first ran after four fact-check rounds. Security then found 2 High issues ("don't merge")." (`docs/working/proposal-2026-09-27-smaller-review-units.md:10`).

**Evidence:** `docs/reviews/q076-security-review-2026-09-27.md:48`, `docs/reviews/q076-security-review-2026-09-27.md:64`, `docs/reviews/q076-security-review-2026-09-27.md:185`, `docs/working/proposal-2026-09-27-smaller-review-units.md:10`

---

## Claim 3: "It keeps 032 H1: the terminal pass still runs the full panel."

**Location:** `docs/decisions/log.md:83`
**Type:** Reference / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the fact that the amendment leaves mechanic 5 (terminal pass never short-circuits) intact and that this mechanic is 032's stated H1 mitigation. It does not establish that H1 recall is unaffected by the new delta scope (see Claim 11).
**Legibility-target:** decision-log reader

Decision 032 #4: "**always run the full panel on the final otherwise-clean pass**" (`docs/decisions/032-review-loop-token-reduction-levers.md:38-39`). H1 is defined at `:57`: "**H1** no behavioral-red recall regression vs the 031 baseline". SKILL.md mechanic 5 is unchanged by the diff: "**The terminal pass never short-circuits.** `pr-prep` runs the final, otherwise-clean pass **without** `--loop-pass`" (`skills/code-review/SKILL.md:697-698`).

**Evidence:** `docs/decisions/032-review-loop-token-reduction-levers.md:36-40`, `docs/decisions/032-review-loop-token-reduction-levers.md:57`, `skills/code-review/SKILL.md:697-701`

---

## Claim 4: "Leftover reviewer probes tripped `install.sh`'s no-agent guard and failed `install-host` tests in full runs."

**Location:** `docs/decisions/log.md:83` (repeated at `skills/code-review/SKILL.md:290-291`)
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium. The claim matches the proposal's diagnosis, and the underlying test runs were not replayed.
**Verification mode:** static
**Scope:** Covers agreement with the proposal's recorded diagnosis. It does not establish the causal diagnosis by reproduction.
**Legibility-target:** reviewer-agent brief author

The proposal records: "*Environmental* (3): install-host T33, T83 and T6. Each failed only in full runs and passed alone. Leftover probe processes from review agents (a sleep, a `cc-push` Ctrl-C probe blocked on a FIFO) tripped install.sh's no-agent guard." (`docs/working/proposal-2026-09-27-smaller-review-units.md:13`).

**Evidence:** `docs/working/proposal-2026-09-27-smaller-review-units.md:13`

---

## Claim 5: Decision-log row number "60"

**Location:** `docs/decisions/log.md:83`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers sequential numbering against `main`. It does not cover collisions with sibling branches.
**Legibility-target:** merger of the U-series units

On `main`, the last row is `| 59 | 2026-09-27` (`git show main:docs/decisions/log.md | tail -1`), and on this branch row 60 follows it at `docs/decisions/log.md:83`. **Merge note (not a defect of this unit):** sibling unit U3 (`feat/u3-review-docs`) also adds a row 60. Whichever unit merges second must renumber its row, and the commit messages ("Decision log row 60") will then point to the wrong row for one of them.

**Evidence:** `docs/decisions/log.md:82-83`

---

## Claim 6: "`--full` (the default above, stated explicitly — use it to override the loop-pass default below)"

**Location:** `skills/code-review/SKILL.md:108-109`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that `--full` appears in the only scope-flag list in the repo and has no name clash with an existing flag. It does not establish what happens when `--full` and `--range` are passed together, which is unspecified.
**Legibility-target:** skill user / pr-prep loop driver

Step 1's override list is the only place the scope flags are listed. Step 6 (`skills/code-review/SKILL.md:222-241`) lists only critic-selection flags (`--include`, `--exclude`, `--only`, `--all-critics`, `--chain`, `--loop-pass`). No other file in `skills/`, `workflows/` or `guides/` lists `/code-review` scope flags: paraphrased — no quote available because the claim covers absence of code (a grep for `--staged`/`--full`/`--range` outside SKILL.md hits only `lite-review.py --range` at `workflows/pr-prep.md:237` and `workflows/review-fix-loop.md:79-80`, which is a different tool). No existing flag is named `--full`. The text does not say whether `--full` and `--range` are mutually exclusive, but passing both is not a plausible use.

**Evidence:** `skills/code-review/SKILL.md:103-109`, `skills/code-review/SKILL.md:222-241`, `workflows/pr-prep.md:237`

---

## Claim 7: "The loop's rubric is the one file matching `docs/reviews/code-review-rubric-*-<branch-slug>.md` with the date as the only wildcard"

**Location:** `skills/code-review/SKILL.md:112-114`
**Type:** Behavioral / Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers whether the "one file per loop" premise holds against the rubric naming rule and the real rubric history. It does not establish anything about how an agent parses the rule in practice.
**Legibility-target:** loop-pass orchestrator (the agent computing the range)

The rule assumes a loop has one rubric file. The naming rule says otherwise for loops that span a date: "A *new* file is created only when the date or the branch changes" (`skills/code-review/references/rubric.md:15-16`). Any loop that crosses midnight therefore produces two matching files. The SKILL then takes its ambiguous branch ("If more than one file matches … require an explicit `--range` or `--full`", `SKILL.md:118-120`) on every later pass, and mechanic 6 turns the short-circuit off ("If the loop's rubric cannot be identified unambiguously, do not short-circuit", `SKILL.md:716-717`). The short-circuit marker also stays in the earlier-dated file. Both fallbacks fail safe.

This already happens in practice. Applying the rule (regex `^code-review-rubric-YYYY-MM-DD-<slug>\.md$`) to the real `docs/reviews/` history gives two matches each for `exp-cross-model-openrouter-sweep` (2026-07-30, 2026-07-31) and `feat-crb-direction1-harness` (2026-08-18, 2026-08-19), and one match each for `q076`, `skill-fixtures`, `ans-copy-install` and `answers-2026-09-20`. The practical gap: a multi-day loop requires the user to supply the scope flag on every later pass. That conflicts with `--loop-pass` implying a non-interactive run (`SKILL.md:239-240`).

**Evidence:** `skills/code-review/SKILL.md:111-120`, `skills/code-review/references/rubric.md:14-17`, `skills/code-review/SKILL.md:711-717`. Command: `for slug in …; do ls docs/reviews | grep -E "^code-review-rubric-[0-9]{4}-[0-9]{2}-[0-9]{2}-${slug}\.md$"; done`, run in the worktree root on 2026-09-28 (~18:28Z). Exit 0. Output was captured to the chat only; the result is reproducible from `ls docs/reviews`.

---

## Claim 8: "its stamp is its first line, `Commit: <sha>`" / "The file's first line is `Commit: <reviewed HEAD short SHA>`"

**Location:** `skills/code-review/SKILL.md:115`; `skills/code-review/references/rubric.md:20-21`
**Type:** Configuration / Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the new convention requires, compared with existing rubrics and the rubric worked example. It does not establish that the format-contract test would catch a missing stamp (it would not).
**Legibility-target:** rubric author (Stage 3) and format-contract test maintainer

The convention is new as a rubric-specific rule, and existing files follow it only partly. Of 22 existing `docs/reviews/code-review-rubric-*.md` files, 10 have `Commit: <sha>` as line 1 (e.g. `code-review-rubric-2026-09-27-q076.md: Commit: 623ca02`). The other 12 start with `# Code Review Rubric` (e.g. `code-review-rubric-2026-09-24-ans-copy-install-q058.md`). SKILL handles an unstamped file safely ("its stamp is missing … use full-branch scope", `SKILL.md:117-118`). However, rubric.md says the worked example "`test/skills/code-review/rubric-current-format.md`" is "kept in sync" with the format and must change "in the same commit" (`references/rubric.md:32-35`), and that example still begins `# Code Review Rubric` (`test/skills/code-review/rubric-current-format.md:1`). The new text places the line "above the template below", so the sync obligation can be read as not applying. Even so, the example no longer shows a compliant file, and no test asserts the stamp.

**Evidence:** `skills/code-review/references/rubric.md:20-24`, `skills/code-review/references/rubric.md:32-35`, `test/skills/code-review/rubric-current-format.md:1`. Command: `for f in docs/reviews/code-review-rubric-*.md; do echo "$f: $(head -1 $f)"; done` (worktree root, 2026-09-28, exit 0; output in chat, reproducible).

---

## Claim 9: "If that file exists, its stamp is an ancestor of HEAD (`git merge-base --is-ancestor <sha> HEAD`) and differs from HEAD, the scope is `<sha>..HEAD`"

**Location:** `skills/code-review/SKILL.md:115-118`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the command's semantics and that a short SHA stamp works with it. It does not establish behavior when a 7-character stamp becomes ambiguous in the object store (git then errors, which lands in the "not an ancestor" branch only if the agent treats a non-zero exit that way).
**Legibility-target:** loop-pass orchestrator

`git merge-base --is-ancestor 623ca02 HEAD` (the Q-076 rubric's stamp) returned exit 0 in the worktree, so short SHAs are accepted. The ancestor test is the right guard. After pr-prep's Phase 2 rebase (`git rebase -i origin/main`, `workflows/pr-prep.md` step 4), old stamps stop being ancestors and the rule falls back to full scope instead of computing a range that no longer exists. The "differs from HEAD" clause prevents an empty `<sha>..HEAD`. One edge case: a 4-character probe (`5ddf`) returned "short object ID 5ddf is ambiguous", and `--is-ancestor` exits non-zero on that error. The SKILL does not say how to classify that error, but in practice stamps are ≥7 characters.

**Evidence:** `skills/code-review/SKILL.md:115-118`. Command: `git merge-base --is-ancestor 623ca02 HEAD; echo $?` in the worktree root, 2026-09-28 ~18:28Z. Exit 0. Output captured in chat.

---

## Claim 10: "A run without `--loop-pass` (the confirming pass) keeps the full-branch default."

**Location:** `skills/code-review/SKILL.md:121`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the consistency of "confirming pass = no `--loop-pass`" across SKILL.md and pr-prep. It does not establish which of the two 2-clean passes a driver will actually run with the flag.
**Legibility-target:** pr-prep loop driver

pr-prep agrees: "run that final confirmation pass **without** it" (`workflows/pr-prep.md:251-253`). Another part of the same SKILL, which the diff does not touch, describes confirmation passes as loop passes: "On a `--loop-pass` (an intermediate or confirmation pass inside the review-fix loop, which requires **2 consecutive clean passes** before merge), run **k=1**" (`skills/code-review/SKILL.md:434-436`). Under decision 031's 2-clean rule there are two confirming passes. By `:434`, the first of them is a `--loop-pass` and so gets the new delta range. The parenthetical at `:121` assumes a single confirming pass without the flag. The wording at `:434` predates this unit, but `:121` now depends on the distinction.

**Evidence:** `skills/code-review/SKILL.md:121`, `skills/code-review/SKILL.md:434-440`, `workflows/pr-prep.md:250-254`

---

## Claim 11: Implicit — the loop-pass default range is compatible with decision 031 (k=1 on loop passes, 2-clean)

**Location:** `skills/code-review/SKILL.md:111-126`; `docs/decisions/log.md:83` (cites 032 only)
**Type:** Reference / Invariant
**Verdict:** Mostly accurate
**Confidence:** Medium. This rests on reading 031's recall argument, and nothing was measured.
**Verification mode:** static
**Scope:** Covers the mechanical consistency (k=1, `--no-gate`, and a full terminal pass are all kept) and the recall rationale 031 relies on. It does not establish the size of any recall change.
**Legibility-target:** decision-record reader weighing recall vs cost

The mechanics match 031: loop passes stay k=1 (`SKILL.md:434-437`, `:716`). 031's *justification* for k=1, however, depends on re-sampling each defect on every pass. It says "across N k=1 passes at 1−(1−p)ᴺ … the loop favors k=1 for N≥3 — *provided the defect survives to be re-drawn*" (`docs/decisions/031-review-loop-tier-and-factcheck-policy.md:115-117`), and that 2-clean "gives every finding … a second independent draw" (`:124-127`). With the delta default, code that no fix touches is drawn on the first full pass and on the terminal full pass, not on every pass. That is still ≥2 draws, so 2-clean's minimum holds, but the N≥3 parity argument no longer applies to unchanged code. Row 60 cites only 032 and does not mention this effect on 031's rationale. The same tension already existed in pr-prep 3d's prose rule (Claim 12); this unit turns that rule into the computed default. The verdict is Mostly accurate rather than Incorrect because no text in the diff claims 031's rationale still holds.

**Evidence:** `docs/decisions/031-review-loop-tier-and-factcheck-policy.md:104-131`, `skills/code-review/SKILL.md:111-126`, `docs/decisions/log.md:83`

---

## Claim 12: "in Q-076 every round re-checked the whole diff although pr-prep 3d already said to review only the fixes"

**Location:** `skills/code-review/SKILL.md:123-126`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers pr-prep 3d's text, the anchor `#3-review-fix-loop`, and the proposal's Q-076 account. It does not replay the Q-076 briefs themselves.
**Legibility-target:** SKILL maintainer

pr-prep 3d: "**Diff only the fixes.** Use `git diff <last-review-commit>..HEAD` to isolate code changed since the last review iteration." (`workflows/pr-prep.md:244`). The proposal records: "The iteration 2 and 3 fact-check briefs said "every checkable claim … in the pass-1 diff"" (`docs/working/proposal-2026-09-27-smaller-review-units.md:9`). The heading `#### 3. Review-fix loop` resolves to the linked anchor.

**Evidence:** `workflows/pr-prep.md:244`, `docs/working/proposal-2026-09-27-smaller-review-units.md:9`

---

## Claim 13: "The preamble MUST also carry the **probe-cleanup rule**: any process the agent starts … runs under `timeout` and is killed before the agent reports."

**Location:** `skills/code-review/SKILL.md:288-291`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers placement in the shared-block item 1 (the goal preamble, so the rule reaches every agent) and agreement with proposal C6's second bullet. It does not cover C6's pre-gate `pgrep` quiesce step, which this unit does not implement and does not claim to.
**Legibility-target:** every reviewer agent

The rule sits under list item 1, "The goal preamble (what a review pass is). The preamble MUST include the …" (`SKILL.md:277`), which belongs to the shared block placed "**first, verbatim**, in every agent prompt" (`SKILL.md:263`). The proposal's C6 reads: "Tell review agents that build adversarial probes to run them under `timeout` and to reap them before reporting." (`proposal-2026-09-27-smaller-review-units.md:74`).

**Evidence:** `skills/code-review/SKILL.md:262-263`, `skills/code-review/SKILL.md:277-291`, `docs/working/proposal-2026-09-27-smaller-review-units.md:72-74`

---

## Claim 14: Unqualified statements of the pre-amendment short-circuit remain in the section ("do not launch the remaining review work"; "skip the **entire** Stage-1.5/Stage-2 critic panel"; "Amber is NOT collected on a short-circuited pass")

**Location:** `skills/code-review/SKILL.md:667-669`, `:682-683`, `:695`
**Type:** Behavioral / Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the internal consistency of the whole "First-red short-circuit" section (`:661-730`) and the `--loop-pass` flag text. It does not establish how an agent resolves the conflict.
**Legibility-target:** agent executing the short-circuit

The new mechanics 6 and 7 are stated as exceptions, but the earlier absolute statements were not qualified. Mechanic 2 still says "skip the **entire** Stage-1.5/Stage-2 critic panel for this pass" (`:682-683`), while mechanic 7 says to "run the security critic even on a pass that short-circuits" (`:720`). Mechanic 4 still says "**Amber is NOT collected on a short-circuited pass.**" (`:695`), while mechanic 7 says "Its findings enter the rubric at their mapped tier, amber included" (`:721`). An agent that reads mechanics 1–5 as the definition of the short-circuit and stops there will apply the old unbounded behavior. The bound's lead-in (`:703`) and the closing paragraph (`:726-727`, "plus the security critic's findings under mechanic 7") make the intent recoverable. No other file restates the old behavior: `workflows/pr-prep.md:250-254` defers to the SKILL, and the grep hits in `workflows/`, `skills/` and `guides/` are otherwise only the SKILL itself.

**Evidence:** `skills/code-review/SKILL.md:661-730`, `workflows/pr-prep.md:250-254`

---

## Claim 15: "#4's token rationale holds for one deferred pass … It does not hold for a string of them"

**Location:** `skills/code-review/SKILL.md:703-710`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers consistency with decision 032 #4 as written, including its falsifier. It does not evaluate whether the bound is the best remedy.
**Legibility-target:** decision-record reader

032 anticipated this failure. Its falsifier reads: "Falsifier for #4: a red-gated pass whose skipped critics would have found an *independent* red that changes the fix → collect reds panel-wide before short-circuiting." (`docs/decisions/032-review-loop-token-reduction-levers.md:90-91`). The Q-076 security Highs are such a case. The amendment adopts a bound rather than the falsifier's named remedy (collect reds panel-wide), and says openly that it departs from #4, so it is not a silent contradiction. Row 60 could cite `032:90-91` as the tripped falsifier; it does not.

**Evidence:** `docs/decisions/032-review-loop-token-reduction-levers.md:36-40`, `docs/decisions/032-review-loop-token-reduction-levers.md:90-91`, `skills/code-review/SKILL.md:703-710`

---

## Claim 16: "Run Stage 2 in full despite the red … The run still implies `--no-gate` and k=1."

**Location:** `skills/code-review/SKILL.md:714-716`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers consistency with the `--loop-pass` definition and the Stage 1 replication rule. It does not cover Stage 2.5, which stays skipped on a loop pass per `:986-988`; mechanic 6 does not override that skip.
**Legibility-target:** agent executing a bounded pass

`--loop-pass` "implies `--no-gate`" (`SKILL.md:239`), and a `--loop-pass` runs "**k=1**" (`SKILL.md:436`). Both statements match mechanic 6.

**Evidence:** `skills/code-review/SKILL.md:236-241`, `skills/code-review/SKILL.md:434-437`, `skills/code-review/SKILL.md:711-717`

---

## Claim 17: "a path matched by the `enforcement` pattern in `hooks/live-verify-gate.sh`, which owns the list"

**Location:** `skills/code-review/SKILL.md:718-719`
**Type:** Reference / Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the pattern's existence and usability (Claim 1) and which file is the source of truth. It does not establish that the hook's copy is currently in sync with `cc-isolated.sh`.
**Legibility-target:** future maintainer adding an enforcement file

The pattern exists and works for this purpose (Claim 1), but the hook does not own the list. Its own comment names another file as the source: "The enforcement set: what cc-isolated.sh's enforcement_files() hashes, as repo paths. Keep in step with that function. Plus install.sh, which is not hashed …" (`hooks/live-verify-gate.sh:70-72`). The authoritative list is `enforcement_files()` at `devcontainer-config/cc-isolated.sh:126-137` (plus install.sh). Pointing at the hook's regex is a sensible choice because it is the only grep-able form. The precise wording would be "matched by the hook's `enforcement` regex, which mirrors `cc-isolated.sh`'s `enforcement_files()` plus `install.sh`".

**Evidence:** `hooks/live-verify-gate.sh:70-73`, `devcontainer-config/cc-isolated.sh:126-137`

---

## Claim 18: "Both rules are owned by SKILL.md: Step 1's loop-pass default range and the first-red short-circuit's once-per-loop bound."

**Location:** `skills/code-review/references/rubric.md:22-24`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that both named sections exist in SKILL.md and contain the rules. It does not cover the rubric-template sync issue (Claim 8).
**Legibility-target:** rubric author

Step 1's "**Loop-pass default range.**" paragraph (`SKILL.md:111`) and mechanic 6 "**Once per loop.**" (`SKILL.md:711`) both exist, and both describe the `Commit:` line and the marker as rubric.md says.

**Evidence:** `skills/code-review/SKILL.md:111-126`, `skills/code-review/SKILL.md:711-717`, `skills/code-review/SKILL.md:726-729`

---

## Claim 19: "No existing suite pins the short-circuit section, so no assertion was added."

**Location:** commit message of 77a4ca5
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `test/` grep and a passing run of all `test/skills/code-review-*.bats` suites at 77a4ca5. It does not establish that the new rules have test coverage (they have none).
**Legibility-target:** reviewer deciding whether tests are needed

A grep of `test/` for `short-circuit`/`First-red`/`loop-pass`/`Loop-pass` finds only `test/skills/code-review-factcheck-replication.bats:148` (the k=1 Replication header vocabulary) and an unrelated `ai-personas-critique-format.bats:136` comment. `Skipped Core Critics` is asserted only as a section name (`code-review-format.bats:72-73`, `code-review-format-contract.bats:40`). All code-review suites pass on the branch: 106 `ok`, 0 `not ok`.

**Evidence:** `test/skills/code-review-factcheck-replication.bats:148`, `test/skills/code-review-format.bats:72-73`. Command: `LC_ALL=C.UTF-8 timeout 300 bats test/skills/code-review-*.bats`. cwd: worktree root. Exit 0. Timestamp 2026-09-28T18:28:58Z. Output: `/tmp/claude-1000/-workspace/fe8d5f41-d34b-4387-9352-6d6b13c2ada9/scratchpad/u4-code-review-bats.log`. LC_ALL was pinned because the ambient `en_US.UTF-8` is not installed (proposal C7).

---

## Claim 20: "ad-hoc names (-iter2, -final) do not match and fall back to full scope (the safe direction)"

**Location:** commit message of 77a4ca5 (Notes)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers matching against real rubric names. It does not claim that ad-hoc names will keep being created under the new in-place rule.
**Legibility-target:** reviewer of the B1 design

Ad-hoc suffixes do not match. When a base-named file for the same slug also exists, though, the result is not full scope. The rule then matches the base file and uses its older stamp. For `answers-2026-09-20` the matching file is `code-review-rubric-2026-09-21-answers-2026-09-20.md` (`Commit: 654c0ed`), while the latest pass was recorded in `-iter3.md` (`Commit: 31f53e8`). For `ans-copy-install` the base file (`d0fdd04`) matches instead of `-final` (`9ae6e46`). In each case the range is wider than the latest delta. That errs toward reviewing more, so the "safe direction" part holds for scope. It does not hold for the once-per-loop bound: a marker written into an ad-hoc-named file would not be seen, and a second short-circuit could happen.

**Evidence:** Command: `ls docs/reviews | grep -E "^code-review-rubric-[0-9]{4}-[0-9]{2}-[0-9]{2}-${slug}\.md$"` for each slug, plus `head -1` of each rubric (worktree root, 2026-09-28, exit 0; output in chat, reproducible).

---

## Claim 21: "When the rubric cannot be identified, the run does not short-circuit."

**Location:** commit message of 77a4ca5 (Notes); cf. `skills/code-review/SKILL.md:716-717`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium. This is a question of how the rule reads, not of what code does.
**Verification mode:** static
**Scope:** Covers the gap between the commit message's wording and the SKILL's wording. It does not establish which reading the author intended.
**Legibility-target:** agent executing the first loop pass

The SKILL says "cannot be identified **unambiguously**" (`SKILL.md:716-717`), which reads as the multi-match or detached-HEAD case from Step 1 (`:118-120`). The commit message drops "unambiguously". On the first pass of a loop no rubric exists yet, so read literally the message's rule would stop the first pass from ever short-circuiting. That is the one pass the bound means to allow. The SKILL is also unclear on this point, because "no such file" (`:117`) is a separate Step-1 branch from "more than one file matches", and mechanic 6 does not say which of the two counts as "cannot be identified". The precise version: "if more than one rubric matches or HEAD is detached, do not short-circuit. If no rubric exists yet, no marker exists, so the short-circuit is allowed."

**Evidence:** `skills/code-review/SKILL.md:115-120`, `skills/code-review/SKILL.md:711-717`

---

## Claim 22: "B3: the loop-pass short-circuit (decision 032 #4) may skip Stage 2 at most once per loop … When the reviewed diff touches an enforcement file … the security critic runs even on the short-circuited pass."

**Location:** commit message of 77a4ca5 (B3 paragraph); row 60 cites "(B1, B3, C6)" at `docs/decisions/log.md:83`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers how faithfully the implementation follows the proposal's B3 text. It does not judge whether the narrower implementation is the better design.
**Legibility-target:** user tracking which proposal items landed

Proposal B3 reads: "**B3 · Run the critic panel in iteration 1 alongside fact-check** (with `--loop-pass`) for any unit that touches an enforcement file." (`docs/working/proposal-2026-09-27-smaller-review-units.md:42`). The implementation differs from that text in two ways. First, it adds a once-per-loop bound that applies to every unit, not only enforcement units. Second, for enforcement units it forces only the **security** critic, not the full panel (`SKILL.md:718-722`, "Only the other critics are skipped"). Neither the commit message nor row 60 says B3 was reinterpreted or narrowed. The Q-076 motivation the unit cites (the security Highs) is covered by the security-only choice.

**Evidence:** `docs/working/proposal-2026-09-27-smaller-review-units.md:42`, `skills/code-review/SKILL.md:703-722`

---

## Claim 23: "Added a `--full` flag so the full-branch fallback stays an explicit flag (proposal B1)."

**Location:** commit message of 77a4ca5 (Notes)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the flag's correspondence to B1's last sentence. It does not cover B1's proposed `--since <sha>` flag, which the unit replaced with a default range plus the existing `--range`. The commit body describes that correctly as "a --loop-pass with no scope flag defaults to <stamp>..HEAD".
**Legibility-target:** user tracking which proposal items landed

B1: "Falling back to a full review (pr-prep 3d's "fixes touched most of the PR") stays an explicit flag." (`docs/working/proposal-2026-09-27-smaller-review-units.md:38`). SKILL.md: "`--full` (the default above, stated explicitly — use it to override the loop-pass default below)" (`skills/code-review/SKILL.md:108-109`).

**Evidence:** `docs/working/proposal-2026-09-27-smaller-review-units.md:38`, `skills/code-review/SKILL.md:108-109`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 7** (`skills/code-review/SKILL.md:112-114`): "The one file per loop" is false for loops that span a date, because rubric.md starts a new file on each new date. Real history has two such branches. Every later pass then needs an explicit `--range`/`--full` on a nominally non-interactive run, and the short-circuit is disabled.
- **Claim 8** (`skills/code-review/references/rubric.md:20`, `SKILL.md:115`): the first-line `Commit:` stamp is a new requirement that 12 of 22 existing rubrics lack. The worked example `test/skills/code-review/rubric-current-format.md:1` (which rubric.md says is kept in sync) has no stamp, and no test asserts one.
- **Claim 10** (`skills/code-review/SKILL.md:121`): "without `--loop-pass` (the confirming pass)" conflicts with `SKILL.md:434`, which calls confirmation passes loop passes under 2-clean.
- **Claim 11** (`SKILL.md:111-126`, `log.md:83`): the delta default weakens 031's k=1 resampling argument (N≥3 draws) for code no fix touches. Row 60 cites only 032.
- **Claim 14** (`SKILL.md:682-683`, `:695`): mechanics 2 and 4 still state the pre-amendment absolutes ("entire" panel skipped; amber NOT collected). Mechanic 7 contradicts them without qualifying them.
- **Claim 17** (`SKILL.md:718-719`): "which owns the list" is wrong. The hook itself defers to `cc-isolated.sh`'s `enforcement_files()` plus install.sh.
- **Claim 20** (commit message): ad-hoc names do not fall back to full scope when a base-named file exists. They use an older stamp (a wider range), and a marker in an ad-hoc file would be missed.
- **Claim 21** (commit message vs `SKILL.md:716-717`): "cannot be identified" (message) vs "cannot be identified unambiguously" (SKILL). The no-rubric first pass is unclassified.
- **Claim 22** (commit message B3): the unit narrows proposal B3 (full panel for enforcement units) to the security critic only and adds a bound for all units, without saying so.

### Unverifiable
(none)

**Merge note (not a verdict):** U3 (`feat/u3-review-docs`) also adds decision-log row 60 (Claim 5). The second unit to merge must renumber its row.

---

## Goal-Alignment Note

- **Answered:** I checked all seven claims the brief highlighted: the enforcement pattern (Claims 1 and 17), the rubric stamp and filename rule against real names (7, 8, 9, 20), consistency with 031 and 032 (3, 11, 15, 16), the `--full` flag (6, 23), leftover statements of the old behavior (10, 14), row 60 (5), and the no-suite claim (19). I also checked the other factual claims in the diff and the commit message. I read the whole Step 1, Step 6, Stage 1 replication paragraph, shared-block list and "First-red short-circuit" section of SKILL.md, not only the diff hunks.
- **Out of scope:** I did not assess whether the bound or the delta default is good design; that belongs to the critics. The pre-existing `SKILL.md:434` wording and the Step 7 "3 fact-check replicates" count both predate this unit. I cite `:434` only where the new text depends on it. I did not verify U3's row 60 content.
- **Escalate:** Claim 11 is a recall-policy tension with decision 031 that the decision log does not record. Claim 7's multi-day-loop ambiguity collides with `--loop-pass`'s non-interactive intent. The user or the architecture critic should settle both; fact-checking cannot. No silent guesses: the "four rounds" count (Claim 2) and the probe diagnosis (Claim 4) rest on the proposal document and are tagged Medium where relevant.
