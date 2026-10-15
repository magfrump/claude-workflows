Commit: 25d8f272

# API Consistency Review — Q-089 unit B, iteration 3 (feat/q089b4-host-tool-gate)

**Scope:** `git diff 79f22357 25d8f272` (iteration-2 fixes: hooks/live-verify-gate.sh, test/hooks/live-verify-gate.bats, guides/devcontainer-setup.md, docs/decisions/log.md row 71; the review reports and execution logs in the range are inputs, not reviewed surface)
**Date:** 2026-10-14
**Based on:** docs/reviews/api-consistency-review-2026-10-14-q089b-it2.md (N1-N5); commit message of 25d8f272 (claims N1-N4 fixed, N5 left)
**Iteration:** 3 of 3, `--loop-pass`

> ⚠️ **No code fact-check report provided for this range.** API documentation claims in the delta have not been independently verified against implementation beyond the probes below. For full verification, run the `code-fact-check` skill first or use the code-review orchestrator.

## Baseline Conventions

Unchanged from iterations 1-2: trailer shape `<Qualifier>-<past participle>:`, value `<evidence>` or `no — <reason>; <what will run it>`, debt list by `git log --grep '<Trailer>: no'`, `BLOCKED: this commit changes <X> but says nothing about <Y>.` message shape. Points relevant to this delta:

- **Scope phrase for the wider "enforcement file" reading.** Row 71 and the guide now use the same words, "code-review's mechanic 7 and RPI's bypass-family pre-mortem". "Mechanic 7" is the name `skills/code-review/SKILL.md` itself uses (:697, :712, :757). RPI step 3 (:233) heads its paragraph "enumerate the bypass families".
- **Git diff hardening flags.** The repo already reads diffs for machine judgement with `--no-ext-diff --no-textconv`: `scripts/build-loop.sh:1787` (`gate_git diff-tree -p -U0 --no-renames --no-ext-diff --no-textconv --text --no-color`).
- **Bats test names** in the gate suite are plain sentences stating the behaviour, with the edge case in parentheses where there is one (`install.sh is gated although it is not manifest-hashed (decision 035)`, :146). Placeholder trailer values in the suite are `no — n/a` (9 uses).

## Status of iteration-2 findings

| # | Iteration-2 finding | Status at 25d8f272 | Evidence |
|---|---|---|---|
| N1 | Guide says host tools "are not enforcement files" unscoped | **Fixed** (main recommendation; optional RPI:349 qualifier not taken) | guides/devcontainer-setup.md:272-274 "**Host-only tools are not enforcement files for this sequence** (decision log row 71); / they still count as enforcement files for code-review's mechanic 7 and RPI's / bypass-family pre-mortem". A wording residue is N6. |
| N2 | Row 71 quotes a phrase only RPI uses | **Fixed** (second option: quote dropped) | log.md:94 "both now name the gate's `enforcement` and `host_tools` regexes". True of both consumers: SKILL.md:746 says "regex", RPI:233 says "pattern", and both name both variables. |
| N3 | Bats header describes one trailer | **Fixed** | live-verify-gate.bats:5-10 "…with a `Live-verified:` trailer, and one that carries a / host-only tool (cc-exit-scan.sh, cc-gitdir.sh, cc-push.sh; decision log row 71) / unless it carries a `Host-tool-tested:` trailer." A pre-existing residue is N7. |
| N4 | Unanchored `host_tools` pinned by no test | **Fixed**, and the test bites | New test 31 `a stray sibling of a host tool (cc-push.sh.orig) is gated as a host tool`. Restoring the `$` fails it (probe below). |
| N5 | Hook mixes "decision log row 71" and "#71" | **Left, as stated** in 25d8f272's Notes | hook:23, :84 "decision log row 71"; hook:205 "decision log #71". Carried as Informational, no change. |

Probe (snapshot `git archive 25d8f272` ×4, under `/home/node/.claude/jobs/00bcf178/tmp/acr3.qpwc`, script `/home/node/.claude/jobs/00bcf178/tmp/acr3-probe.sh`, `LC_ALL=C`, each suite under `timeout 300`):
```
clean exit=0 ok=31 notok=0
textconv exit=1 ok=30 notok=1      (mutation: drop --no-textconv --no-ext-diff from comment_only_diff)
not ok 30 a repo-local textconv driver cannot make a real change read as comment-only
anchor exit=1 ok=30 notok=1        (mutation: host_tools regex end-anchored with $)
not ok 31 a stray sibling of a host tool (cc-push.sh.orig) is gated as a host tool
renames77 exit=1 ok=30 notok=1     (mutation: drop --no-renames from the -a name list, hook:77)
not ok 29 a rename committed with -a (new name only intent-to-add) is still gated
```
Each new test fails under exactly the mutation it exists to catch, and only that test fails.

## Name-Pattern Audit

The delta adds no new trailer, variable, function, message or flag of the gate's own. New public-facing names are three test names, one doc scope phrase and one pair of git flags.

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `a rename committed with -a (new name only intent-to-add) is still gated` | bats test name | `renaming a gated file to an ungated name is still gated`, `counts unstaged tracked changes when -a is given`, `the -a path honors the narrowing too` | `test/hooks/live-verify-gate.bats:383,104,233` | Consistent. Sentence form, "is still gated" matches its rename sibling, parenthesised edge case matches :146. |
| `a repo-local textconv driver cannot make a real change read as comment-only` | bats test name | `a diff that changes a comment AND a real line still blocks`, `a comment-only edit to an egress list passes without a trailer` | `test/hooks/live-verify-gate.bats:190,182` | Consistent. Uses the suite's own term "comment-only". |
| `a stray sibling of a host tool (cc-push.sh.orig) is gated as a host tool` | bats test name | `every host_tool_files entry is gated by the host-tool trailer, none by Live-verified`; hook comment "a stray sibling such as cc-push.sh.orig is gated too" | `test/hooks/live-verify-gate.bats:343`; `hooks/live-verify-gate.sh:89-90` | Consistent. Reuses the hook comment's exact words, so a grep for "stray sibling" finds the contract and its test together. |
| "for code-review's mechanic 7 and RPI's bypass-family pre-mortem" | doc scope phrase | row 71 "for code-review's mechanic 7 and RPI's bypass-family pre-mortem"; SKILL.md "mechanic 7"; RPI:233 "enumerate the bypass families" | `docs/decisions/log.md:94`; `skills/code-review/SKILL.md:697`; `workflows/research-plan-implement.md:233` | Consistent. Identical to row 71's wording. |
| `--no-textconv --no-ext-diff` | git flags on a judging diff | `--no-ext-diff --no-textconv` | `scripts/build-loop.sh:1787` | Consistent. Same pair, same purpose (a diff read by a gate, not shown to a person). |
| "A boundary file, not a host tool" (test comment, :152) | doc term | "boundary file" in the hook, :153; in the same suite, :135-140, :313 | `hooks/live-verify-gate.sh:153`; `test/hooks/live-verify-gate.bats:135` | Consistent. Existing term for the `Live-verified:` set. |

## Findings

#### N6. The guide's new scope clause leaves the list of host tools hanging off "pre-mortem:"

**Severity:** Informational
**Location:** `guides/devcontainer-setup.md:272-276`
**Move:** 3 (documentation legibility)
**Confidence:** Medium
**Legibility-target:** a reader skimming the guide to learn which files are host-only tools

Evidence:
```
**Host-only tools are not enforcement files for this sequence** (decision log row 71);
they still count as enforcement files for code-review's mechanic 7 and RPI's
bypass-family pre-mortem: `cc-exit-scan.sh`
(the session-exit scan the launcher sources), `cc-gitdir.sh` (the git-directory tests
it and cc-push source) and `cc-push.sh`.
```

The N1 fix inserted its clause before the colon that used to follow the bold lead, so the colon that introduced "which files are host-only tools" now follows "pre-mortem". It reads as though the three files were the content of the pre-mortem. The meaning is recoverable, and row 71 opens with the same names, so nothing is lost. It is only a sentence that parses two ways.

**Recommendation:** Optional. Put the list first: "**Host-only tools** (`cc-exit-scan.sh` …, `cc-gitdir.sh` … and `cc-push.sh`) **are not enforcement files for this sequence** (decision log row 71); they still count as enforcement files for code-review's mechanic 7 and RPI's bypass-family pre-mortem."

#### N7. The bats header still says the gated set is "what the trust manifest hashes"

**Severity:** Informational
**Location:** `test/hooks/live-verify-gate.bats:5-10`
**Move:** 3 (test/documentation drift)
**Confidence:** High
**Legibility-target:** a maintainer who reads the test file's header as the gate's contract

Evidence (25d8f272):
```
# The gate blocks a `git commit` that carries a cc-isolated enforcement file
# (what the trust manifest hashes) unless the commit message names its live
...
# unless it carries a `Host-tool-tested:` trailer. Everything else — other
# commands, other files, malformed input — must be a silent exit 0.
```
Evidence (same file, :146): `@test "install.sh is gated although it is not manifest-hashed (decision 035)" {`

The header now describes both trailers (N3 fixed), but "what the trust manifest hashes" plus "Everything else … silent exit 0" still leaves out `install.sh`, which the same file pins as gated. This was true before this branch (decision 035 predates it), and this delta's new assertions at :152-157 make install.sh's trailer more prominent. Not a regression.

**Recommendation:** Optional. "(what the trust manifest hashes, plus install.sh, decision 035)".

#### N5 (carried). The hook cites the decision log in two forms

**Severity:** Informational
**Location:** `hooks/live-verify-gate.sh:23,84` ("decision log row 71"), `:205` ("decision log #71")
**Move:** 2 (naming against the grain)
**Confidence:** Medium
**Legibility-target:** a reader grepping the hook for references to a given decision

Precedent: `#NN` form in the hook's own header, `hooks/live-verify-gate.sh:5-7` ("Decision log #40 and #41", "(#44)"), and in `hooks/wiring.json:28` ("decision log #45, #71")

Evidence: unchanged from iteration 2. 25d8f272's Notes: "api N5 (#71 vs row 71 citation forms) left as is."

A deliberate leave, recorded in the commit body. It stays Informational. Both forms match a grep for `71`.

**Recommendation:** None required for merge.

## What Looks Good

- **Every claimed fix is real.** N1-N4 are fixed as the commit says, and N5 is left as it says. The commit body maps each finding to its change, so the review trail is auditable.
- **The new tests bite.** Each of the three new tests fails under its own mutation, and only that test fails. N4's gap (an `$` restored silently) is closed. The same goes for the security-side `-a` rename and textconv cases, which now carry their contracts as tests rather than as comments.
- **One scope phrase in two places.** The guide and row 71 now say "for code-review's mechanic 7 and RPI's bypass-family pre-mortem" word for word, so a grep for either finds both. Row 71's claim about the consumers is now true of both.
- **The textconv hardening follows existing precedent.** It uses the same flag pair as `scripts/build-loop.sh:1787`, and its comment explains why.
- **install.sh's trailer is now pinned in both directions** (:152-157), with a comment that says why the per-file loop does not cover it, using the suite's existing term "boundary file".
- **Test names follow the suite's style:** behaviour sentences, the suite's own vocabulary ("comment-only", "still gated", "stray sibling"), and the edge case in parentheses.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| N6 | Guide's scope clause makes the host-tool list follow "pre-mortem:" | Informational | `guides/devcontainer-setup.md:272-276` | Medium |
| N7 | Bats header's "what the trust manifest hashes" omits install.sh (pre-existing) | Informational | `test/hooks/live-verify-gate.bats:5-10` | High |
| N5 | Hook mixes "row 71" and "#71" (carried, deliberately left) | Informational | `hooks/live-verify-gate.sh:23,84,205` | Medium |

No Breaking, Inconsistent or Minor findings.

## Overall Assessment

The iteration-2 delta is consistent with the gate's established conventions. It closes all four findings it claimed to close, introduces no new public name that departs from its neighbours, and adds no new consumer contract. The three new tests pin their contracts: under mutation each fails alone, and the clean suite is 31/31. What remains is three Informational wording items. Two are optional rewordings (N6, N7) and one is a deliberate, recorded leave (N5). None changes behaviour or what a consumer would do. From the API-consistency side this unit is clean for merge.

## Goal-Alignment Note

The PR's goal is for host-tool commits to stop carrying an unpayable `Live-verified: no`, so that debt list holds only probe-payable debt, while host tools keep every review safeguard. This iteration finishes the legibility work for that goal. Whichever doc a reader starts from (guide, row 71, mechanic 7, RPI step 3, the hook or its test header), they now get the same two-set, two-trailer contract and the same wider scope for "enforcement file". The previously comment-only promises (unanchored host regex, `-a` renames, diff-driver immunity) are now tests that fail when broken. Nothing here works against the goal, and the remaining Informational items do not affect it.
