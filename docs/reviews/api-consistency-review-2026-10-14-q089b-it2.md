Commit: 79f22357

# API Consistency Review — Q-089 unit B, iteration 2 (feat/q089b4-host-tool-gate)

**Scope:** `git diff 88432f39 79f22357` (iteration-1 fixes: hooks/live-verify-gate.sh, test/hooks/live-verify-gate.bats, README.md, hooks/wiring.json, skills/code-review/SKILL.md, workflows/research-plan-implement.md, docs/decisions/log.md row 71, guides/devcontainer-setup.md, guides/cc-isolated-usage.md, docs/roadmap.md, docs/working/questions.md), plus a repo-wide sweep of every consumer of the gate's regexes and trailers
**Date:** 2026-10-14
**Based on:** docs/reviews/api-consistency-review-2026-10-14-q089b.md (iteration 1, F1-F7); docs/reviews/code-fact-check-report-q089b.md (it2, Claims 3 and the M4/M6 mutation notes are referenced, not re-verified)
**Iteration:** 2 of 3, `--loop-pass`

## Baseline Conventions

Same baseline as iteration 1 (trailer shape `<Qualifier>-<past participle>:`, value `<evidence>` or `no — <reason>; <what will run it>`, debt list by `git log --grep '<Trailer>: no'`, `BLOCKED: this commit changes <X> but says nothing about <Y>.` message shape). Two points matter more this pass:

- **"Enforcement file" is defined by pointing at the gate.** Pre-diff, code-review mechanic 7 said "the `enforcement` regex", RPI step 3 said "the `enforcement` pattern", decision log row 60 says "The enforcement set is the one `hooks/live-verify-gate.sh` gates (its regex mirrors `cc-isolated.sh`'s `enforcement_files()`…)", and row 61(4) says "(`hooks/live-verify-gate.sh`'s set)". "Regex" and "pattern" were already used interchangeably for the same variable.
- **Decision-log citation form.** The hook header cites `Decision log #40 and #41` / `(#44)`; README cites `decision log row 64`; hooks/wiring.json cites `decision log #45`. Each file had one form.

Consumer sweep (`git grep` at 79f22357 for `enforcement` regex/pattern, `live-verify-gate`, `Live-verified`, `Host-tool-tested`, `host_tools`, `host-only tool`, `enforcement file`, excluding `docs/reviews/` and `archive/`): 208 hits across 35 files. The living contracts are README.md:161, hooks/wiring.json:27-28, hooks/live-verify-gate.sh, skills/code-review/SKILL.md:683,728,745-749, workflows/research-plan-implement.md:233,349, docs/decisions/log.md rows 45/60/61/71, guides/devcontainer-setup.md:244-252,264-288, guides/cc-isolated-usage.md:826-830,927-930, devcontainer-config/cc-isolated.sh:196-198,317, devcontainer-config/install.sh:22, test/hooks/live-verify-gate.bats. The rest are dated working docs (plans, DDs, checkpoints, cycle records, questions archive) that describe the state at their own date. None of those is stale in a way a consumer acts on: `docs/working/plan-q094-exit-scan-worktree-layout.md:4` ("`cc-exit-scan.sh` (`hooks/live-verify-gate.sh` set)") is still true under the widened mechanic-7 / RPI reading.

## Status of iteration-1 findings

| # | Iteration-1 finding | Status at 79f22357 | Evidence |
|---|---|---|---|
| F1 | Host tools drop out of mechanic 7, RPI step 3, rows 60/61 | **Fixed** (option a) | SKILL.md:746 "matched by the `enforcement` or the `host_tools` regex"; RPI:233 "the `enforcement` or `host_tools` pattern … the host-only tools count, decision log row 71"; row 71 "They remain enforcement files for code-review's mechanic 7 and RPI's bypass-family pre-mortem (rows 60, 61(4))". RPI:349's checklist inherits step 3's definition. A residual scope clash is N1. |
| F2 | Header, Behavior table, README, wiring.json describe one trailer | **Fixed** for all four | hook:23-27 "HOST TOOLS (decision log row 71)…", hook:43-44 "(Live-verified: for enforcement files, Host-tool-tested: for host tools)"; README:161; wiring.json:27-28. The bats file's header was missed: N3. |
| F3 | Row 71 cites absent Q-147 | **Fixed** | `docs/working/questions.md` "### Q-147 · q089-loop-split-source-guard" |
| F4 | No `Host-tool-tested: no` debt query; history caveat | **Fixed** | devcontainer-setup.md:250-253 "so from row 71 on that list gains only debt a probe can pay (host-tool commits before it, from Q-076 on, stay in it); `git log --grep 'Host-tool-tested: no'` lists the host-tool debt"; the BLOCKED message repeats the query (hook:204). |
| F5 | `host_tools` end-anchored, `enforcement` not | **Fixed** | hook:89-91 "Not end-anchored, like `enforcement`: a stray sibling such as cc-push.sh.orig is gated too". Probe below. No test pins it (fact-check M4): N4. |
| F6 | "host-only tool" vs "host tool" in one message | **Fixed** | hook:193 "BLOCKED: this commit changes a host tool but says nothing about testing it on a host." / "Host tools in the commit:". "host-only" now appears only in the defining sentences (row 71, the guides, README's one-liner). |
| F7 | Host BLOCKED message lacks the why/pointer line | **Fixed** | hook:202-204 "These run on the host after or outside the container, so cc-isolated --probe-only / cannot exercise them (guides/devcontainer-setup.md, host-tools note; decision log #71)." |

Probe (snapshot `git archive 79f22357`, scratch repo under `/home/node/.claude/jobs/00bcf178/tmp/acr2.qkLT`, `LC_ALL=C`, each call under `timeout 20`):
```
orig [git commit -m x] -> 2 | BLOCKED: this commit changes a host tool but says nothing about testing it on a host.
orig [git commit -m x -m "Live-verified: no - n"] -> 2 | BLOCKED: this commit changes a host tool but says nothing about testing it on a host.
orig [git commit -m x -m "Host-tool-tested: no - n"] -> 0 |
rename host tool -> 2
BLOCKED: this commit changes a host tool but says nothing about testing it on a host.
Host tools in the commit:
  devcontainer-config/cc-push.sh
rename host tool + HTT -> 0
```
`timeout 300 bats test/hooks/live-verify-gate.bats` on the same snapshot: exit 0, `ok: 28  not ok: 0`.

## Name-Pattern Audit

The delta adds three public-facing names, all test names or doc strings. The trailer, regex variables and message nouns were audited in iteration 1 and are unchanged except as noted in the status table.

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `the hook's host_tools regex names exactly host_tool_files, no more` | bats test name | `every host_tool_files entry is gated by the host-tool trailer, none by Live-verified`, `install.sh is gated although it is not manifest-hashed` | `test/hooks/live-verify-gate.bats:335,352` | Consistent. Same sentence-form, names the function and variable as spelled in code. |
| `renaming a gated file to an ungated name is still gated` | bats test name | `adding a NEW enforcement file whose content is all comments still blocks` | `test/hooks/live-verify-gate.bats` | Consistent. |
| `ERROR: host-tool check failed — refusing to launch, probe or register` (troubleshooting row) | doc-quoted error string | `ERROR: cc-push refuses to run:`, `host-tool manifest … is unreadable or malformed` | `devcontainer-config/cc-isolated.sh:754`, `devcontainer-config/cc-push.sh:206` | Consistent. Matches cc-isolated.sh:754 verbatim (less its trailing `:`), and the old `ERROR: host tools differ from the bless` row it replaces no longer exists in the code. |
| "decision log #71" / "decision log row 71" | doc citation | `Decision log #40 and #41`, `decision log row 64`, `decision log #45` | `hooks/live-verify-gate.sh:5`; `README.md:162`; `hooks/wiring.json:28` | Mixed within the hook. See N5. |

## Findings

#### N1. "Enforcement file" now has two scopes, and the guide states the narrow one without a qualifier

**Severity:** Minor
**Location:** `guides/devcontainer-setup.md:272`; against `skills/code-review/SKILL.md:745-749`, `workflows/research-plan-implement.md:233,349`, `docs/decisions/log.md` row 71
**Move:** 3 (consumer contract / documentation drift)
**Confidence:** Medium
**Legibility-target:** a planner or reviewer who reaches the term "enforcement file" through the guide, or through RPI's checklist line, rather than through mechanic 7 or RPI step 3

Evidence (guides/devcontainer-setup.md:272):
```
**Host-only tools are not enforcement files** (decision log row 71): `cc-exit-scan.sh`
```
Evidence (skills/code-review/SKILL.md:748-749):
```
   the owners of the lists, plus `install.sh`; host tools carry their own trailer but are
   still enforcement files here, decision log row 71),
```
Evidence (workflows/research-plan-implement.md:349, unchanged):
```
- [ ] If the plan changes an enforcement file (high-stakes or not), `/pre-mortem` (or a spike) has run and its output lists the bypass families, each marked covered or not
```

The F1 fix took option (a), and the two consumers that define the term now say outright that host tools count. But the guide, which is where "enforcement file" is *defined* in prose ("Enforcement files are what `enforcement_files()` in `cc-isolated.sh` hashes", :266), now says flatly that host tools are not enforcement files. The other mentions of the term in code-review (:683 "never past the security critic on an enforcement file", :728) and RPI's checklist (:349) are bare. A reader who learned the definition from the guide, which the RPI pre-mortem for a cc-isolated change sends them to, will read :349 as excluding `cc-push.sh`, which is the exact outcome F1 was about. The texts don't contradict each other once you see each one's scope. The problem is that only the consumer side states that scope.

**Recommendation:** Scope the guide's sentence: "Host-only tools are not enforcement files for the live-verification sequence below (decision log row 71); they still count as enforcement files for code-review mechanic 7 and the RPI bypass-family pre-mortem." Optionally add "(host tools included, step 3)" to RPI:349.

#### N2. Row 71 quotes "the `enforcement` or `host_tools` pattern" as what both consumers read, but mechanic 7 reads "the `enforcement` or the `host_tools` regex"

**Severity:** Minor
**Location:** `docs/decisions/log.md:94` (row 71); `skills/code-review/SKILL.md:746`; `workflows/research-plan-implement.md:233`
**Move:** 3 (documentation drift)
**Confidence:** High (fact-check it2 Claim 3 reaches the same verdict)
**Legibility-target:** a maintainer who greps for the row-71 phrase to find every consumer they must update when the gate's sets next change

Precedent: "regex" and "pattern" both name the same gate variable, in `skills/code-review/SKILL.md:746` ("`enforcement` regex", pre-diff too), `docs/decisions/log.md:83` ("its regex mirrors"), `docs/decisions/035-install-sh-gating.md:29` ("enforcement regex"), against `workflows/research-plan-implement.md:233` ("`enforcement` pattern", pre-diff too)

Evidence (row 71):
```
They remain enforcement files for code-review's mechanic 7 and RPI's bypass-family pre-mortem (rows 60, 61(4)): both now read "the `enforcement` or `host_tools` pattern".
```
Evidence (SKILL.md:746): "matched by the `enforcement` or the `host_tools` regex in `hooks/live-verify-gate.sh`"

The row presents a quoted string as the shared text, and the quote is exact only for RPI. That matters because the decision log is what a maintainer follows: someone who runs `git grep 'enforcement. or .host_tools. pattern'` to find the consumers before a third set is added finds RPI and misses mechanic 7, the consumer that forces the security critic. The two words for one variable were already mixed before this diff, so this is not a new naming split. It is a quote that claims more uniformity than exists.

**Recommendation:** Pick one. Either make both consumers say "regex" (the variable is a regex, and three of the four sites already say so), or drop the quotation marks in row 71 and name the two locations ("SKILL.md mechanic 7 and RPI step 3 now name both the `enforcement` and `host_tools` regexes").

#### N3. The gate's test file header still describes a single `Live-verified:` contract

**Severity:** Minor
**Location:** `test/hooks/live-verify-gate.bats:5-8`
**Move:** 3 (test/documentation drift)
**Confidence:** High
**Legibility-target:** a maintainer who opens the test file to learn what the gate's contract is before changing it

Evidence (unchanged by the delta, though the file was edited):
```
# The gate blocks a `git commit` that carries a cc-isolated enforcement file
# (what the trust manifest hashes) unless the commit message names its live
# verification status with a `Live-verified:` trailer. Everything else — other
# commands, other files, malformed input — must be a silent exit 0.
```

The F2 fix updated the hook header, the Behavior table, README and wiring.json. This header is the fifth description of the same contract and was not updated. Its "Everything else … must be a silent exit 0" is now wrong for host-tool commits. The tests themselves are correct, and the section comment at :282 ("Host-only tools (decision log row 71): their own trailer, Host-tool-tested.") covers them. Only the summary at the top under-describes the gate.

**Recommendation:** Add a sentence: "Host-only tools (`host_tool_files()`, decision log row 71) need `Host-tool-tested:` instead; a commit touching both kinds needs both."

#### N4. The unanchored `host_tools` contract is stated in a comment but pinned by no test

**Severity:** Informational
**Location:** `hooks/live-verify-gate.sh:89-91`; `test/hooks/live-verify-gate.bats:352-361`
**Move:** 3 (contract without test)
**Confidence:** High (fact-check it2 M4: restoring the `$` leaves all 28 tests green; M6: an extra `.py` name in the regex leaves test 26 green)
**Legibility-target:** a future editor of the regex who relies on the suite to tell them which matching rule is intended

Evidence:
```
# Not end-anchored, like `enforcement`: a stray sibling such as cc-push.sh.orig is
# gated too (it was, while the tools sat in `enforcement`).
host_tools='^devcontainer-config/(cc-exit-scan\.sh|cc-gitdir\.sh|cc-push\.sh)'
```

The F5 fix is right, and the probe above confirms `cc-push.sh.orig` now needs `Host-tool-tested:`. But the reason F5 was raised was that the two halves could drift apart silently, and this only aligns them. A tidy-minded edit that puts the `$` back passes every test. The `enforcement` side has the same gap: no test stages `cc-isolated.sh.orig`. So this is a shared pre-existing gap, not a regression. Hence Informational.

**Recommendation:** Optional: one bats case staging `devcontainer-config/cc-push.sh.orig`, asserting exit 2 without a trailer and 0 with `Host-tool-tested:`. Otherwise leave it, since the fact-check already records the gap.

#### N5. The hook cites the decision log in two forms

**Severity:** Informational
**Location:** `hooks/live-verify-gate.sh:5,7` (`#NN`), `:23,84` (row 71), `:203` (#71)
**Move:** 2 (naming against the grain)
**Confidence:** Medium
**Legibility-target:** a reader grepping the hook for references to a given decision

Precedent: `#NN` form in the hook's own header, `hooks/live-verify-gate.sh:5-7` ("Decision log #40 and #41", "(#44)"), and in `hooks/wiring.json:28` ("decision log #45, #71")

Evidence:
```
# HOST TOOLS (decision log row 71). cc-exit-scan.sh, cc-gitdir.sh and cc-push.sh
...
      echo "cannot exercise them (guides/devcontainer-setup.md, host-tools note; decision log #71)."
```

The same file now says "decision log row 71" in two comments and "decision log #71" in the message, with its older header using `#NN`. Nothing breaks: both forms are greppable by `71`. But a reader searching for `#71` misses the comments, and a reader searching for `row 71` misses the message. README's "row NN" form is that file's own convention and is fine there.

**Recommendation:** Optional. Use `#71` in the hook's two comments to match its header and wiring.json.

## What Looks Good

- **F1 resolved the way the threat model wants.** Host tools keep the forced security critic and the bypass-family pre-mortem, and row 71 records the choice. The consumers name the owning functions (`enforcement_files()` and `host_tool_files()`), so the mirror relationship is documented in both directions.
- **One contract, four consistent statements.** The hook header, the Behavior table, README:161 and wiring.json:27-28 now all say the same thing: two trailers, one per set, each set judged on its own comment-only escape. The Behavior table's per-set rows match `need+=` at hook:153-154.
- **The two BLOCKED messages are now parallel.** Same first-line shape, one category noun per message ("Enforcement files" / "Host tools"), both accepted value forms, and a why-paragraph with a guide pointer. The host message also names its debt query, which the boundary message's header documents for its own trailer.
- **The debt-list claim is now accurate over history.** "from row 71 on that list gains only debt a probe can pay (host-tool commits before it, from Q-076 on, stay in it)" is the right shape for a consumer deciding what a grep result means.
- **Renames are gated by both paths** (`--no-renames`, hook:71-77). A host tool moved to an ungated name still asks for `Host-tool-tested:`, and the BLOCKED list names the source path (probe above). The bats test covers the boundary half.
- **Both directions of the host list are pinned** (tests 25 and 26), so the hand copy in the regex can no longer drift silently either way for `.sh` names.
- **The troubleshooting rows track the code.** The replaced `ERROR: host tools differ from the bless` string no longer exists in cc-isolated.sh, and its replacement and the new cc-push `no host-tool manifest` row quote cc-isolated.sh:754 and cc-push.sh:166/206 verbatim.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| N1 | Guide says host tools "are not enforcement files"; mechanic 7 / RPI say they are; bare uses (RPI:349, SKILL.md:683,728) are ambiguous | Minor | `guides/devcontainer-setup.md:272`; `workflows/research-plan-implement.md:349` | Medium |
| N2 | Row 71's quoted "…`host_tools` pattern" is exact for RPI only; mechanic 7 says "regex" | Minor | `docs/decisions/log.md:94`; `skills/code-review/SKILL.md:746` | High |
| N3 | Bats file header still describes only `Live-verified:` | Minor | `test/hooks/live-verify-gate.bats:5-8` | High |
| N4 | Unanchored `host_tools` stated in a comment, pinned by no test | Informational | `hooks/live-verify-gate.sh:89-91` | High |
| N5 | Hook mixes "decision log row 71" and "decision log #71" | Informational | `hooks/live-verify-gate.sh:23,84,203` | Medium |

No Breaking or Inconsistent findings.

## Overall Assessment

All seven iteration-1 findings are fixed, and the repo-wide consumer sweep found no live contract that still defines the gate by its old single-trailer, single-set shape. The one exception is the bats header (N3). The Breaking finding (F1) is resolved in the consumers, as recommended. What remains is wording: the term "enforcement file" is now scoped differently in the guide than in the review and planning consumers (N1), and row 71 quotes a phrase that only one of the two consumers uses (N2). Each is a one-sentence fix in place. Neither changes behaviour. The gate suite passes 28/28 on the snapshot, and the probe confirms the unanchored host regex and rename handling behave as the comments say. Consumer impact of the remaining items is limited to a reader who meets the term through the guide or RPI's checklist and comes away with the narrow scope.

## Goal-Alignment Note

The PR's goal is for host-tool commits to stop carrying an unpayable `Live-verified: no`, so that debt list holds only probe-payable debt, without losing any review safeguard on host tools. This delta completes that goal against its consumers. Commit authors get a parallel, self-explaining BLOCKED message and a documented debt query. The `Live-verified: no` list is described accurately, history included. Code-review mechanic 7 and the RPI pre-mortem explicitly keep host tools in scope. The residual items (N1-N3) are about making that scope legible from every entry point, not about the mechanism. Fixing N1 and N2 would let a maintainer find every consumer from row 71 and get the same definition whichever doc they start from. None of the five findings needs to block a merge.
