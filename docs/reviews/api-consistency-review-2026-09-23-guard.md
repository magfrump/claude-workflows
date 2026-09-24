Commit: 3e9e448

# API Consistency Review — `ans/guard-q048-q050` (confirmation pass)

**Scope:** net diff `970e525..3e9e448`: `hooks/guard-trusted-writes.py` (whole file read, 326 lines), `test/hooks/guard-trusted-writes.bats` (N12/N15/Q-048 sections), `guides/bare-host-hook-wiring.md` (+14)
**Date:** 2026-09-23
**Based on:** `docs/reviews/code-fact-check-report.md` (Commit 3e9e448, 19 claims, executed E1–E5). Behaviour it established is cited by claim number and not re-run here.

The consumer-facing surfaces reviewed are: (1) the hook's decision contract, meaning which tool/tier combinations get deny, ask or no opinion; (2) the deny/ask reason strings that agents and users act on; (3) the bare-host guide paragraph, read as instructions.

## Baseline Conventions

- **Decision contract (`hooks/wiring.json` `_comment`, `hooks/guard-trusted-writes.py:5-65`).** HARD file-tool writes defer, so the `permissions.deny` rules block them. "Hard-resolved" file-tool writes are denied by the hook, because no deny rule names that spelling. SOFT gets an ask only when the session is tainted. Bash HARD is denied outright, and Bash SOFT gets an ask when tainted. "No opinion" means exit 0 with no output. This branch keeps that model. N12 widens *what* counts as hard-resolved; it does not add a decision kind.
- **Reason-string conventions (`:291-320`).** There are two deny strings and two ask strings, one of each per tool family (Bash, file tools). Deny strings call the target a "protected policy file". Ask strings call it a "trusted-policy file" and open with "This session fetched web content and this …". File-tool strings interpolate `({Path(fp).name})`, while the Bash strings name no file. Before this branch each deny string ended in a remedy clause ("Edit it directly with review…", "Edit it at its ~/.claude path, with review"). Both remedies were impossible (N15, `docs/reviews/code-review-rubric-2026-09-21-answers-2026-09-20-iter3.md` row N15).
- **Matcher.** `"Edit|Write|MultiEdit|Bash"` (`hooks/wiring.json:50`). The code treats `Edit`, `Write` and `MultiEdit` as one family (`:301`).
- **Guide conventions (`guides/bare-host-hook-wiring.md`).** It cites decision records and upstream issues by ID ("decision 023 amendment B", "Claude Code issue #39344"). It says "Edit/Write" for the file tools (`:56`) and wraps prose at about 85 columns.

## Name-Pattern Audit

The diff adds no new code identifiers, flags, fields or decision values. The only module-level symbol touched is the loop variable `_e`/`_t`, which is private. The new public "names" are reason-string phrasings and a guide heading. They are audited against their siblings below.

| New name / phrase | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| "Claude cannot write these: make the change outside Claude…" (Bash deny remedy) | reason text | file-tool deny "…Claude's file tools cannot edit it. Make the change outside Claude…"; ask strings "Review it … before allowing" | `hooks/guard-trusted-writes.py:291-320` | Inconsistent: scope differs from the file-tool deny, and the claim is wrong for project/worktree `.claude` (F1, F2) |
| "…so Claude's file tools cannot edit it" (file-tool deny) | reason text | Bash deny "Claude cannot write these" | `hooks/guard-trusted-writes.py:291-293` | Inconsistent: narrower scope than its sibling while Bash to the same path defers (F2) |
| "a global hook, settings or CLAUDE.md" (file-tool deny enumeration) | reason text | Bash deny "(.claude hooks/settings, global CLAUDE.md)" | `hooks/guard-trusted-writes.py:291` | Minor: two phrasings of one set (F5) |
| "protected policy file" (both denies) | reason text | ask strings "trusted-policy file"; wiring `_comment` "trusted-policy paths" | `hooks/guard-trusted-writes.py:297,319`, `hooks/wiring.json:20` | Consistent with the prior deny wording (pre-existing split from the asks; noted only) |
| "Make the change outside Claude, in your own editor or shell, and review it there." | reason text | the same sentence in the other deny | `hooks/guard-trusted-writes.py:292-293,316-317` | Consistent: verbatim across both denies |
| "**Symlinked global files can't be edited from Claude.**" | guide heading | the guide's own body "denies Claude's file tools" / "Bash writes … are NOT gated" | `guides/bare-host-hook-wiring.md:59-68` | Inconsistent with its own body (F3) |
| "Q-050", "N2/A8" in the guide | doc cross-ref | "decision 023 amendment B", "issue #39344" | `guides/bare-host-hook-wiring.md:5,56` | Minor: review-finding IDs where the guide otherwise cites durable records (F6) |

## Findings

#### F1. The Bash deny message tells the user to go "outside Claude" for writes the file-tool contract allows

**Severity:** Inconsistent
**Location:** `hooks/guard-trusted-writes.py:288-295` (with `:248`, `:195-196`)
**Move:** 4 (error consistency), 3 (consumer contract)
**Confidence:** High
**Legibility-target:** for-author
**Evidence:** `"Claude cannot write these: make the change outside Claude, in your own "` (`:292`); `HARD_FRAG = re.compile(r"\.claude/hooks(/|\b)|\.claude/settings|managed-settings", re.I)` (`:248`); `if ".claude" in low:` / `return "soft"` (`:195-196`)

The Bash HARD tier covers *any* `.claude/hooks` or `.claude/settings`, whether it belongs to a project, to an agent worktree or to the global config. The file-tool tier treats the project and worktree cases as SOFT, which means no opinion when clean and an ask when tainted. So "Claude cannot write these" is a policy statement that the hook's own file-tool contract contradicts. Fact-check Claim 12b executed this: `[Bash echo > /srv/proj/.claude/settings.json] deny` against `[Edit /srv/proj/.claude/settings.json (clean)] defer`. This is the exact case the Q-048 withdrawal now routes to deny. The docstring's remedy for it is "agents there use Edit/Write" (`:54-55`), while the message sends the agent outside Claude. An agent that obeys the message stops and hands back to the user work it could have done with Edit. The replaced 970e525 text had the opposite error: "Edit it directly" was right for project/worktree and impossible for global. Neither version gives both halves of the contract.

**Recommendation:** Make the remedy conditional, as the contract is: "Claude can't make this change with a shell command. For a project's or worktree's own `.claude/` file, use the Edit/Write tool. For a global hook, settings file or CLAUDE.md, make the change outside Claude…". Then extend the N15 bats test to assert that the project-`.claude` Bash reason names Edit/Write.

#### F2. The two deny messages disagree on scope, and the narrower one invites a Bash workaround that currently gets no opinion

**Severity:** Inconsistent
**Location:** `hooks/guard-trusted-writes.py:314-317` vs `:291-295`
**Move:** 4 (error consistency), 7 (asymmetry)
**Confidence:** High
**Legibility-target:** for-author
**Evidence:** `"symlink), so Claude's file tools cannot edit it. Make the change outside "` (`:316`) vs `"Claude cannot write these: make the change outside Claude, in your own "` (`:292`)

Q-050 [2] decided that these files "are edited outside Claude" (docstring `:29-30`). The Bash deny states that policy: "Claude cannot write these". The file-tool deny, which is the one that fires for the N12 case, says only that *file tools* cannot edit it. For a per-file-linked hook's checkout path, the Bash route is exactly the gap: fact-check Claims 5 and 10 executed `[bash echo > checkout hook] defer` and `[bash cp -> checkout hook] defer`. An agent that reads "file tools cannot edit it" can reasonably try `cp`/`tee` next and gets no opinion from the hook. The message wording is accurate, but it steers toward the ungated route instead of stating the decision.

**Recommendation:** Use the Bash message's scope: "…so Claude cannot edit it. Make the change outside Claude…". The N15 test's `"outside Claude"` assertion already covers the shared sentence, so no test churn is needed.

#### F3. The guide heading promises more than the paragraph and the hook deliver

**Severity:** Inconsistent
**Location:** `guides/bare-host-hook-wiring.md:59-68`
**Move:** 3 (documentation drift, within the diff)
**Confidence:** High
**Legibility-target:** for-author
**Evidence:** `**Symlinked global files can't be edited from Claude.**` (`:59`); `(\`echo x > <checkout>/hooks/<name>\`, \`cp\`) are NOT gated by this hook, only` (`:67`)

The heading says "from Claude". The body says the guard denies "Claude's file tools", and eight lines later that Bash writes to the linked hook's checkout path are not gated. Fact-check Claim 1 adds the sourced-library case: `hooks/lib/usage-common.sh` is also editable. Fact-check Claim 5 adds that "that checkout path" covers `global-instructions/CLAUDE.md` too, where Bash writes *are* denied. The docstring version (`:56-58`) is scoped correctly to "a linked hook's CHECKOUT path". A reader of the guide gets three different scopes: all of Claude, file tools, and file tools minus the CLAUDE.md Bash case.

**Recommendation:** Head the paragraph with what is true, for example "**Claude's file tools can't edit symlinked global files.**" Scope the Bash sentence to linked hooks, as the docstring does: "Bash writes to a linked hook's checkout path … are not gated (Bash writes to the checkout CLAUDE.md are denied)."

#### F4. The docstring's worktree remedy includes one that the hook denies

**Severity:** Minor
**Location:** `hooks/guard-trusted-writes.py:54-55`
**Move:** 3 (documentation drift)
**Confidence:** High
**Legibility-target:** for-author
**Evidence:** `and agents there use Edit/Write or absolute paths.` (`:55`)

This is the only in-code statement of what worktree agents should do after the withdrawal, so maintainers will copy it into messages (see F1). Fact-check Claim 9c is Incorrect: an absolute worktree path still contains `.claude`, and the branch's own test pins that as a deny. The 3e9e448 commit message has the precise form ("absolute paths without a policy name for Bash").

**Recommendation:** Drop "or absolute paths", or restore the commit's qualifier. Mirror the result in the F1 message.

#### F5. Two phrasings of the protected set across the sibling deny strings

**Severity:** Minor
**Location:** `hooks/guard-trusted-writes.py:291` vs `:314-315`
**Move:** 2 (naming against the grain)
**Confidence:** Medium
**Legibility-target:** for-author
**Evidence:** `"Bash write to a protected policy file (.claude hooks/settings, global CLAUDE.md). "` (`:291`); `"({Path(fp).name}: a global "` / `"hook, settings or CLAUDE.md, …"` (`:314-315`)
Precedent: the parenthesised set "(.claude hooks/settings, global CLAUDE.md)" used in `hooks/guard-trusted-writes.py:291` (unchanged Bash deny prefix, identical at 970e525)

The new file-tool string says "a global hook, settings or CLAUDE.md". The Bash string keeps ".claude hooks/settings, global CLAUDE.md". There, "global" qualifies only CLAUDE.md, which is also how F1 arises: the Bash set really does include non-global `.claude` hooks/settings. The new phrasing is the more accurate one for its own tier. Consumers matching on text see two spellings for one concept.

**Recommendation:** Settle the vocabulary when fixing F1. Keep "global hook, settings or CLAUDE.md" for global targets, and name project/worktree `.claude` separately in the Bash message.

#### F6. The guide cites review-finding IDs where it otherwise cites durable records

**Severity:** Informational
**Location:** `guides/bare-host-hook-wiring.md:66-68`
**Move:** 2 (naming against the grain)
**Confidence:** Medium
**Legibility-target:** for-author
**Evidence:** `Claude, in your own editor or shell (Q-050).` (`:66`); `Edit/Write are: a pre-existing gap, alongside the N2/A8 ones in the hook's TODOs.` (`:68`)
Precedent: decision-record and issue citations ("decision 023 amendment B", "Claude Code issue #39344") used in `guides/bare-host-hook-wiring.md:5,56`

Q-050 lives in `docs/working/questions.md`, which is an answered-then-archived working doc. "N2/A8" are review-finding IDs. The paragraph at least says where N2/A8 live ("in the hook's TODOs"), and they do resolve there (`:200`, `:213`). Line 68 also breaks the guide's roughly 85-column wrap. Cosmetic only.

**Recommendation:** Optional. When the copy-based install lands and this paragraph is rewritten, point at the decision record instead of Q-050 and re-wrap.

#### F7. `hooks/wiring.json` `_comment` still describes the file-tool HARD tier as defer-only

**Severity:** Informational
**Location:** `hooks/wiring.json:26-30`
**Move:** 3 (documentation drift)
**Confidence:** Medium
**Legibility-target:** for-author
**Evidence:** `"The permissions.deny block is not decoration: guard-trusted-writes.py DEFERS on its",` (`:26`)

The resolved-tier deny predates this branch, but N12 makes it the normal case on a README bare-host layout: every per-file-linked hook's checkout path. The wiring comment is the model a hand-merger reads, and it mentions only the defer. The guide now documents the exception (`:59`). Not a defect in the diff.

**Recommendation:** Optional one-line addition: "…except a protected file reached by its real path, which the hook denies itself (see guides/bare-host-hook-wiring.md)."

## What Looks Good

- **Decision contract unchanged in kind.** N12 adds entries to the existing `_HARD_FILE_TARGETS`/`_HARD_DIR_TARGETS` sets (`:125-130`) and routes them through the existing `hard-resolved` → deny branch. There is no new decision value, flag or environment variable. The HARD-defer / resolved-deny / SOFT-ask model in `wiring.json` still describes every branch.
- **Q-048 withdrawal restores the prior Bash contract exactly.** The HEAD bats file passes against the 970e525 hook except N12/N15 (fact-check Claims 9a, 14, 15). Consumers see no Bash decision change apart from the reason text.
- **N15 fixed in both denies.** Neither message points at a denied or ungated spelling. The remedy sentence is verbatim-identical across the two, and a test pins it (fact-check Claims 12a, 13).
- **The Bash prose workaround is practical and correct** ("write that text with the Write tool and pass the file"; executed in fact-check Claim 12a). It addresses the known false-positive class (heredocs, commit messages) that the co-occurrence rule causes. I hit it myself during this review: an `awk '…>90…'` probe was denied by the live hook.
- **Copy vs link asymmetry is deliberate and documented** in the docstring, the N12 comment and the guide (copied hook source: no opinion; copied CLAUDE.md source: SOFT). Tests pin both (fact-check Claims 6, 8, 11).
- **The guide paragraph correctly ties "deny" to "no gate otherwise"** ("No deny rule names the checkout path"; fact-check Claim 3), so the exception to the defer rule is explained in terms the reader already met two paragraphs up.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| F1 | Bash deny says "outside Claude" for project/worktree `.claude` writes that Edit/Write may make | Inconsistent | `hooks/guard-trusted-writes.py:288-295` | High |
| F2 | File-tool deny scoped to "file tools" while Bash to the same checkout hook gets no opinion; sibling says "Claude cannot" | Inconsistent | `hooks/guard-trusted-writes.py:314-317` | High |
| F3 | Guide heading "can't be edited from Claude" contradicts its own Bash sentence; Bash sentence mis-scoped to CLAUDE.md | Inconsistent | `guides/bare-host-hook-wiring.md:59-68` | High |
| F4 | Docstring worktree remedy "or absolute paths" is denied by the hook | Minor | `hooks/guard-trusted-writes.py:54-55` | High |
| F5 | Two phrasings of the protected set in sibling deny strings | Minor | `hooks/guard-trusted-writes.py:291,314-315` | Medium |
| F6 | Guide cites Q-050 / N2/A8 instead of durable records; over-long line | Informational | `guides/bare-host-hook-wiring.md:66-68` | Medium |
| F7 | `wiring.json` comment describes the HARD file tier as defer-only | Informational | `hooks/wiring.json:26-30` | Medium |

## Overall Assessment

The decision contract is consistent. N12 extends the existing resolved-tier mechanism without adding a new outcome, and the Q-048 withdrawal returns the Bash contract to 970e525 exactly. The remaining problems are all in the text agents and users act on, and all are one kind: each surface states a different scope for "what Claude may not do". The Bash deny says all of Claude, including project `.claude` files, which is too broad (F1). The file-tool deny says file tools only, which is too narrow and steers toward the ungated Bash route (F2). The guide heading says all of Claude while its body says file tools (F3). The docstring's remedy includes a denied route (F4). F1 matters most, because it gives a worktree agent the wrong next action on exactly the path the withdrawal now denies. All four fixes are in-place wording changes with one added test assertion. No redesign is needed.

## Goal-Alignment Note

- **Success criterion (verbatim):** "a markdown report saved at the output path your task names, structured per your skill, beginning with a `Commit: 3e9e448` line."
- **Answered:** Checked the decision contract against `wiring.json`'s model (consistent), both N15 deny messages against each other and against the ask messages (F1, F2, F5), and the guide paragraph as instructions (F3, F6). The docstring's worktree remedy is F4. The name-pattern audit covers every new consumer-facing phrase.
- **Out of scope:** Whether the ungated routes (Bash to checkout hooks, sourced `hooks/lib`, nested links) should be gated is a security judgement; here they matter only as the reason F2's wording matters. How Claude Code presents a hook deny ("no approve option", fact-check Claim 4) was not checked.
- **Escalate:** F1. The Bash deny text contradicts the hook's own worktree remedy on the path Q-048's withdrawal routes to deny, so worktree agents will be told to hand back work they can do.
