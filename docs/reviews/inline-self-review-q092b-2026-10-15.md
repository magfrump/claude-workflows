Commit: d6395450

# Inline self-review: Q-092 unit 2 (terminal pass)

**Who ran it:** the builder, inline, on 2026-10-15, after the terminal critics stalled. The security critic, the performance/API/architecture critic and the delta fact-check each wrote nothing for over an hour, twice (first dispatch, then a re-dispatch with a tighter brief). The coordinator stopped all of them and told the builder to do these passes inline. **This is self-review. It is weaker than independent critics**, because the author checks their own reasoning. The last independent passes on this unit are pass 2 (security: one Informational; critics: one Minor API and one Informational perf, all fixed) and the final k=3 fact-check (0 Incorrect).

**Scope:** `fix/q092a-drop-deny-option..d6395450` for security; for the fact-check, the claims in `73698a91..52353da8` (commit message and docs) plus the plan.
**Probe scripts:** `/home/node/.claude/jobs/00bcf178/tmp/q092/inline/probe.sh`, `mutants.sh` (outputs `probe.out`, `mutants.out` beside them). All ran under `timeout`; no process left.

## Security pass: the pre-mortem's bypass families, re-checked against the final code

| # | Family | Probe | Result |
|---|---|---|---|
| S1 | Hook emits ask/deny/defer | `grep -o '"permissionDecision":"[a-z]*"'` on the hook | One string, `allow`. Covered |
| S2 | Output or exit 2 on odd stdin | `not json`, `[1]`, `{"tool_input":"x"}`, command 5, `{}`, empty | stdout empty every time; exits 4, 5, 5, 0, 0, 0; never 2. Covered |
| F1 | Literal credentials spelling | `cat ~/.claude/.credentials.json`, cat allowed, deny rule in settings | Hook allows; Claude Code's deny decides (Q-082). As designed |
| F2 | ask path | see S1 | Covered |
| F3/F4 | quote, backslash, denied subcommand | `.cred""entials.json`, `git "push"`, `ls && rm -rf x` | Hook allows. Accepted residual, unverified on a host (live check in the unit report) |
| F5 | glob | `cat ~/.claude/.c*` | Hook allows, as before the stack. Accepted |
| F6 | ill-shaped settings | permissions null / [], allow null, deny false, ask "x" / {}, NUL in deny / ask / allow, two documents, empty file, `[]` | No output for all twelve. Covered |
| F6 | valid settings still load | `{}`, `{"permissions":{}}`, non-string entries in all three lists, `defaultMode` | Allow for all four. Covered |
| F6 | partial jq output | good global file with a rule, unparseable project file | No output. Covered; see finding 1 for the test |
| F6b | value Claude Code rejects that jq accepts | not probed against Claude Code | Accepted residual, stated in the header |
| F7 | relative or newline CLAUDE_CONFIG_DIR | `rel`, a path with a newline | No output. Covered |
| — | shape allowlist still in force | `$(...)`, `> ~/.bashrc`, `bash -c`, `X=1 ls` | No output for all four. Covered |

No new security finding.

## Fact-check pass

| # | Claim | Location | Verdict | Evidence |
|---|---|---|---|---|
| 1 | Q-081 answered, Q-125 built and unmerged | log row 53 | Verified | `### Q-081` is in `questions-archive.md:1596`; Q-125 is open in `questions.md` with "built, unmerged in two stacked units" |
| 2 | newly fail-closed: permissions null, allow/deny null or false, any bad ask | log row 53 | Verified | probe F6 at d6395450, against unit 1's tip as reported by the final r2/r3 replicates |
| 3 | guide points at DENY RULES ARE CLAUDE CODE'S and FAILS CLOSED | `guides/bare-host-hook-wiring.md:161` | Verified | both sections exist in the header |
| 4 | ROLE: exit 0 on input Claude Code sends, 4 or 5 on stdin that is not a JSON object, never 2 | hook `:51-53` | Verified | probe S2 |
| 5 | 52353da8: "the unparseable-project test now puts a rule in the global file first, so dropping load_rules' discard of partial jq output fails it" | commit 52353da8 message | **Incorrect** | A mutant without the `return 0` passed 35/35. The program reads every document first (`[inputs ...] as $docs`), so a parse error stops it before anything prints. Only a shape error in a later file comes after the earlier file's rules have printed |
| 6 | plan sizes "~407 / ~436, 697" | plan Split section | Stale | Re-measured: 413 / 451 / 706. Fixed in unit 1 (d27a3891) |

### Finding 1 (from claim 5): the partial-output guard was still untested
**Fixed:** the test now also writes a shape-error project file (`"allow":"Bash(cat:*)"`) after the parse-error case, with a comment explaining why. The `return 0` mutant now fails test 15; the real hook passes 35/35. The commit message's claim stays as written (immutable history) and is recorded in the rubric.

## Goal-Alignment Note
- Success criterion (restated verbatim): A security pass over the deny-reader removal (bypass families from the pre-mortem, each re-checked against the final code) and a fact-check of the commit-message and doc claims since the last completed critic report, recorded as inline self-review.
- Answered: yes, both passes ran and one real finding (an untested guard) was fixed
- Out of scope: Claude Code's own behaviour (host-only, the live check)
- Escalate: nothing
