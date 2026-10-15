Commit: 9001bf80

# API Consistency Review — Q-089 unit B (feat/q089b3-host-tool-gate)

**Scope:** `git diff cc2640b7 9001bf80` (hooks/live-verify-gate.sh, test/hooks/live-verify-gate.bats, docs/decisions/log.md row 71, guides/cc-isolated-usage.md, guides/devcontainer-setup.md)
**Date:** 2026-10-14
**Based on:** docs/reviews/code-fact-check-report-q089b.md (its stale gate header, the dangling Q-147 and the `--help` refusal are not repeated here except where they hit a consumer)
**Iteration:** 1 of 3, `--loop-pass`, full scope

## Baseline Conventions

The public surface here is a commit-message contract plus the gate's regex, which other docs read by name.

- **Trailer names.** The repo's commit trailers are `Live-verified:` (decision log 45), `Confidence:` / `Notes:` (global CLAUDE.md, autonomous commits), `Co-Authored-By:`, `Claude-Session:`, and the rubric marker `Loop-pass short-circuit:`. All of them are Capitalized-hyphenated words followed by `:` and free text. `Live-verified` has the shape `<qualifier>-<past participle>`.
- **Value grammar.** For `Live-verified:` the value is a positive token (the blessed hash) or `no — <reason>; <what will run it>`, and `git log --grep 'Live-verified: no'` is the documented debt list (guides/devcontainer-setup.md:249, hooks/live-verify-gate.sh:20-21).
- **Detection.** `has_trailer` matches the name anywhere the text has `(^|[[:space:]"'])Name:`. That covers `-m`, heredocs and `-F`/`--file`.
- **BLOCKED message shape.** `BLOCKED: this commit changes <X> but says nothing about <Y>.`, then a list header, the indented paths, both accepted value forms, and a reason paragraph.
- **Regex as an interface.** Three documents point at "the `enforcement` regex / pattern in `hooks/live-verify-gate.sh`" as the definition of an *enforcement file*: code-review mechanic 7 (skills/code-review/SKILL.md:745-750), RPI step 3 and its checklist (workflows/research-plan-implement.md:233, :349), and decision log rows 60 and 61(4).

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `Host-tool-tested:` | commit trailer | `Live-verified:`, `Co-Authored-By:`, `Claude-Session:` | `hooks/live-verify-gate.sh:16-21`; `git log` trailer blocks | Consistent. Same Capitalized-hyphenated `<qualifier>-<past participle>` shape as `Live-verified`, same `no — <reason>; <what will run it>` value form. |
| `Host-tool-tested: no — …` (debt list) | log query | `git log --grep 'Live-verified: no'` | `guides/devcontainer-setup.md:249` | Inconsistent (Minor): the sibling debt query is not documented. See F4. |
| `host_tools` (regex var) | gate variable | `enforcement` | `hooks/live-verify-gate.sh:73` | Consistent with `host_tool_files()` (cc-isolated.sh:199). Anchoring differs from `enforcement`. See F5. |
| `boundary_touched` / `host_touched` | gate variable | `touched`, `files` | `hooks/live-verify-gate.sh` (pre-diff) | Consistent. Private locals, listed for completeness. |
| `BLOCKED: this commit changes a host-only tool but says nothing about testing it on a host.` | error message | `BLOCKED: this commit changes the cc-isolated boundary but says nothing about live verification.` | `hooks/live-verify-gate.sh:162` | Consistent shape. The list header uses a different noun. See F6. |
| "host-only tool(s)" / "host tool(s)" | doc term | `host_tool_files()`, "enforcement files" | `devcontainer-config/cc-isolated.sh:192-203`; `guides/devcontainer-setup.md:262-269` | Mixed: both terms appear, sometimes in the same block. See F6. |

## Findings

#### F1. Host tools drop out of every consumer that defines "enforcement file" by the gate's regex (code-review mechanic 7, RPI step 3, decision rows 60/61)

**Severity:** Breaking
**Location:** `hooks/live-verify-gate.sh:73`; consumers `skills/code-review/SKILL.md:745-750`, `workflows/research-plan-implement.md:233` and `:349`, `docs/decisions/log.md` rows 60 and 61(4)
**Move:** 3 (consumer contract)
**Confidence:** High
**Legibility-target:** the reviewer or planner deciding whether a diff to `cc-push.sh` / `cc-exit-scan.sh` / `cc-gitdir.sh` forces the security critic or a bypass-family pre-mortem

Evidence (diff):
```
-enforcement='^devcontainer-config/(Dockerfile|devcontainer\.json|init-firewall\.sh|cc-sni-proxy\.py|link-claude-home\.sh|cc-isolated\.sh|cc-exit-scan\.sh|cc-gitdir\.sh|cc-push\.sh|install\.sh$|egress/)'
+enforcement='^devcontainer-config/(Dockerfile|devcontainer\.json|init-firewall\.sh|cc-sni-proxy\.py|link-claude-home\.sh|cc-isolated\.sh|install\.sh$|egress/)'
```
Consumer (skills/code-review/SKILL.md:745-747, unchanged by the diff):
```
7. **Security on enforcement files.** If the reviewed diff touches an enforcement file (a path
   matched by the `enforcement` regex in `hooks/live-verify-gate.sh`, which mirrors
   `devcontainer-config/cc-isolated.sh`'s `enforcement_files()`, the owner of the list, plus
```
Consumer (workflows/research-plan-implement.md:233): "If the plan changes an enforcement file (in claude-workflows, a path matching the `enforcement` pattern in `hooks/live-verify-gate.sh`), the pre-mortem is required."

Probe (snapshot of 9001bf80, `grep -E "$enforcement"`):
```
cc-push.sh NOT matched by enforcement
cc-exit-scan.sh NOT matched by enforcement
cc-gitdir.sh NOT matched by enforcement
```

The gate's own semantics are correct: host tools still need a trailer, just a different one. But three downstream contracts key on the *variable named `enforcement`*, not on "anything the gate gates". After this commit, a diff to `cc-push.sh` (a host-side git push tool whose own tamper-resistance row 71 just designed) no longer forces the security critic on a short-circuited pass, and a plan that changes it no longer needs the bypass-family pre-mortem. Those are the two safeguards Q-076, the cc-push / exit-scan work, was the evidence for (rows 60 and 61 name Q-076). Row 71's "Not covered" list shows the host tools are still a security surface. No consumer was updated and nothing in the diff mentions the narrowing, so this is a silent semantic change to a documented interface.

**Recommendation:** Pick one meaning on purpose and write it down. Either (a) widen the three consumers to "a path matched by `enforcement` or `host_tools` in `hooks/live-verify-gate.sh`" (the smallest change; it keeps the security critic and pre-mortem on host tools), or (b) record in row 71 that host tools leave mechanic 7 and RPI step 3, and why. (a) fits row 71's own threat model better.

#### F2. The gate's header and behaviour table still describe a single `Live-verified:` contract

**Severity:** Inconsistent
**Location:** `hooks/live-verify-gate.sh:13-21`, `:34-38`; also `README.md:161`, `hooks/wiring.json:27-28`
**Move:** 3 (documentation drift)
**Confidence:** High
**Legibility-target:** a commit author or maintainer who reads the hook header, README or wiring description to learn which trailer to write

Evidence (hooks/live-verify-gate.sh:13-16 at 9001bf80):
```
# WHAT IT ENFORCES. If the files about to be committed include any enforcement
# file under devcontainer-config/ (the ones the trust manifest hashes, plus
# install.sh per decision 035), the commit
# message must carry a `Live-verified:` trailer.
```
README.md:161: "blocks a `git commit` touching a cc-isolated enforcement file unless the message carries a `Live-verified:` trailer". hooks/wiring.json:27-28: "message has no Live-verified: trailer — decision log #45".

The fact-check report already flags the header as stale. The consumer angle: the header is the contract statement for this hook, and the README and wiring.json descriptions are what a user sees when installing it. All three now under-describe the gate, which blocks on a second trailer. Accuracy is unaffected: the BLOCKED message names the trailer it wants. But the "Behavior:" table (`enforcement file staged, no trailer → exit 2`) no longer says which trailer, and it doesn't say that a mixed commit needs both.

**Recommendation:** Add `Host-tool-tested:` and the per-set rule to the WHAT IT ENFORCES paragraph and the Behavior table, and add a clause to the README and wiring.json one-liners ("…or `Host-tool-tested:` for the host-only tools, row 71").

#### F3. Row 71 cites Q-147, which does not exist on this branch

**Severity:** Minor
**Location:** `docs/decisions/log.md:94` (row 71)
**Move:** 3 (documentation drift)
**Confidence:** High (per the fact-check, Claim 14 Incorrect)
**Legibility-target:** a reader of the decision log following the deferred-work handle

Evidence: "a static test tying each entry point's `source` lines to its check list was split out as Q-147, because grep cannot cover every bash spelling."

This is a dangling cross-reference in a consumer-facing record. It is listed here only because the decision log is the interface the dev cycle's revisit triggers read. The fact-check owns the verdict.

**Recommendation:** File Q-147 on this branch (via `questions.sh next-id` against fresh main), or reword the row so it doesn't name an ID until one exists.

#### F4. No documented debt query for `Host-tool-tested: no`, and history still puts host tools in the `Live-verified: no` list

**Severity:** Minor
**Location:** `guides/devcontainer-setup.md:249-251`
**Move:** 7 (asymmetry)
**Confidence:** Medium
**Legibility-target:** the user running the debt list to decide what to verify next

Precedent: `git log --grep 'Live-verified: no'` documented as the debt list in `guides/devcontainer-setup.md:249` and `hooks/live-verify-gate.sh:20-21`

Evidence (added text): "Host-only tools get a trailer of their own, `Host-tool-tested:`, so that list holds only debt a probe can pay (see the host-tools note below)."

The sibling trailer copies `Live-verified`'s `no — <reason>` grammar, which exists so that a grep can list the debt. But nothing tells the reader to run `git log --grep 'Host-tool-tested: no'`, so the new debt has no documented reader. The claim that the `Live-verified: no` list "holds only debt a probe can pay" is also true only going forward. Earlier host-tool commits (Q-076, Q-093, Q-094 and the A1/A2 units: questions.md:155 "every enforcement-file commit on Q-076 carries `Live-verified: no`") stay in that list, and no probe can pay them.

**Recommendation:** Add one sentence after the new line: "`git log --grep 'Host-tool-tested: no'` lists theirs; host-tool commits from before row 71 still appear under `Live-verified: no` (Q-084 tracks them)."

#### F5. `host_tools` is end-anchored and `enforcement` is not, so the gate's two halves match paths differently

**Severity:** Minor
**Location:** `hooks/live-verify-gate.sh:73` vs `:78`
**Move:** 2 (naming/shape against the grain)
**Confidence:** High

Precedent: unanchored file alternatives (only `install\.sh$` anchored) in the `enforcement` regex, `hooks/live-verify-gate.sh:73` (and its pre-diff form)

Evidence:
```
enforcement='^devcontainer-config/(Dockerfile|...|cc-isolated\.sh|install\.sh$|egress/)'
host_tools='^devcontainer-config/(cc-exit-scan\.sh|cc-gitdir\.sh|cc-push\.sh)$'
```
Probe (temp repo, staged `devcontainer-config/cc-push.sh.orig`):
```
new gate, cc-push.sh.orig: 0
old gate, cc-push.sh.orig: 2
```
The end-anchored host regex is arguably the more precise one: a stray `cc-push.sh.orig` is not a host tool. But the same gate still gates `cc-isolated.sh.orig` through `enforcement`. A reader who learns one regex's matching rule will mispredict the other. Moving the three names also quietly narrowed coverage for prefixed paths, and nothing records it.

**Recommendation:** Either anchor both consistently, or add one comment line saying `host_tools` matches exact file names on purpose (they are single files, never directories).

#### F6. "host-only tool" and "host tool" are used interchangeably, including within one message

**Severity:** Informational
**Location:** `hooks/live-verify-gate.sh:162-164`; `guides/devcontainer-setup.md:250, 269`; `guides/cc-isolated-usage.md:829, 927`
**Move:** 2
**Confidence:** Medium

Precedent: `host_tool_files()` / `host-tools.sha256` / "host tools" in `devcontainer-config/cc-isolated.sh:192-245`; "Host-only tools" in decision log row 71

Evidence (gate output, probe):
```
BLOCKED: this commit changes a host-only tool but says nothing about testing it on a host.
Host tools in the commit:
```
The boundary half pairs its first line with "Enforcement files in the commit:", the category's one name. The host half uses two nouns in two lines. The code (`host_tool_files`, `host-tools.sha256`, `ERROR: host tools differ from the bless`) consistently says "host tool". The prose says "host-only" when introducing the category. That is harmless, but a grep for one term misses the other.

**Recommendation:** Keep "host-only" for the defining sentence in row 71 and the guide, and use "host tool(s)" everywhere else, including the BLOCKED first line ("changes a host tool"). Optional.

#### F7. The host-tool BLOCKED message drops the sibling's "why" paragraph

**Severity:** Informational
**Location:** `hooks/live-verify-gate.sh:161-170`
**Move:** 4 (error consistency)
**Confidence:** Medium

Evidence: the boundary message ends with "bats and shellcheck cannot see a kernel; only a container built from this config can (guides/devcontainer-setup.md, 'Changing the boundary')…". The host message ends at the `no — <reason>; <what will run it>` example, with no pointer to the guide section or row 71.

The message is fed back to the model (exit 2 stderr), and the sibling's reason line is what stops an agent from writing a ritual `no — n/a`. The new message gives only "(no live probe can exercise these)" inline.

**Recommendation:** Add one line: "See guides/devcontainer-setup.md, 'Host-only tools are not enforcement files' (decision log row 71)."

## What Looks Good

- **Trailer name and grammar.** `Host-tool-tested:` matches `Live-verified:` in casing, hyphenation and `<qualifier>-<past participle>` shape. Its value form (`<what ran>` or `no — <reason>; <what will run it>`) mirrors the sibling, so `has_trailer` and the debt-grep idiom carry over unchanged.
- **Backward-compatible where it should be.** Boundary-only commits behave exactly as before. The detection regex, the `-F`/`--file` handling and the comment-only escape are reused, not forked (`comment_only_diff` just takes its file set as `$1`).
- **Per-set judging is symmetric and tested.** A mixed commit needs both trailers. A comment-only edit on one side doesn't demand that side's trailer. When both are missing, both BLOCKED blocks print in one exit-2 run (probe output above), so the author fixes them in one round.
- **The host list is bound to its owner.** The bats test sources `host_tool_files()` and asserts each entry is gated by `Host-tool-tested` and not by `Live-verified`, so the hand copy in the regex can't drift silently on that side. All 25 gate tests pass at 9001bf80.
- **Guide troubleshooting rows quote real strings.** `ERROR: host tools differ from the bless — refusing to launch, probe or register` (cc-isolated.sh:747), `changed since the last bless` (cc-isolated.sh:260, cc-push.sh:186), `host-tool manifest … is unreadable or malformed` (cc-isolated.sh:245, cc-push.sh:171) and `ERROR: cc-push refuses to run:` (cc-push.sh:200) all exist verbatim.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Host tools fall out of code-review mechanic 7, RPI step 3 and rows 60/61, which define "enforcement file" by the `enforcement` regex | Breaking | `hooks/live-verify-gate.sh:73`; `skills/code-review/SKILL.md:745`; `workflows/research-plan-implement.md:233,349` | High |
| 2 | Gate header/Behavior table, README and wiring.json describe only `Live-verified:` | Inconsistent | `hooks/live-verify-gate.sh:13-21,34-38`; `README.md:161`; `hooks/wiring.json:27` | High |
| 3 | Row 71 cites Q-147, absent on this branch | Minor | `docs/decisions/log.md:94` | High |
| 4 | No documented `Host-tool-tested: no` debt query; old host-tool debt stays in the `Live-verified: no` list | Minor | `guides/devcontainer-setup.md:249-251` | Medium |
| 5 | `host_tools` end-anchored, `enforcement` not | Minor | `hooks/live-verify-gate.sh:73,78` | High |
| 6 | "host-only tool" vs "host tool" mixed | Informational | `hooks/live-verify-gate.sh:162-164`; guides | Medium |
| 7 | Host BLOCKED message lacks the sibling's pointer/why line | Informational | `hooks/live-verify-gate.sh:161-170` | Medium |

## Overall Assessment

The new trailer is well matched to its sibling: same name shape, same value grammar, same detection and the same escape hatch, with tests that tie the host list to its owner function. The one real consumer problem is F1. Removing the three host tools from the variable named `enforcement` changes the meaning of "enforcement file" for three documents that define it by that regex, so cc-push and exit-scan diffs silently lose the forced security critic and the bypass-family pre-mortem that Q-076 motivated. The fix belongs in the consumers (or in row 71's text), not in the gate. F2 to F5 are documentation and shape fixes the author can make in place. F6 and F7 are optional polish.

## Goal-Alignment Note

The PR's goal is to stop host-tool commits from carrying an unpayable `Live-verified: no`, so that the debt list holds only debt a probe can pay. The gate change achieves that for new commits, and the trailer naming fits the repo's conventions. Two parts of the goal are only partly met. The debt-list claim holds going forward but not over history, and the new list has no documented query (F4). The narrowing of `enforcement` also changes two review safeguards that nobody chose to change (F1). Resolving F1 and F2 would make the change complete against its stated consumers: commit authors, the `git log --grep` debt lists, and code-review mechanic 7.
