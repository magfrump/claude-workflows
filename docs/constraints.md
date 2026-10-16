This doc is for design-level constraints that steer the choices a loop makes on its own. Coding rules (argv, credentials, host actions, live verification, questions-file ownership, docs) now appear under "Moved out" below. Most of them are already enforced by code here, so no prompt needs to restate them.

H1: Code that gates, reviews or bounds a change runs from a copy that change cannot edit (the root-owned image payload or the host); what an agent session writes is input to those checks, not a source of their logic.
success: no new hook, gate, launcher or reviewer invocation reads its code or policy from the working tree; security-reviewer reports no "the reviewed branch can change its reviewer or gate" finding.

H2: Fail closed and loudly: a missing dependency, unparseable input, absent verdict or degraded primitive exits non-zero (or refuses) and names what went unenforced; nothing ships present-but-inert, and degradation only ever narrows access.
success: each new failure path has a bats case asserting a non-zero exit or refusal plus a message naming the gap; no `|| exit 0` or silent skip on a missing dependency.

H3: Every behavioural change is verifiable inside the sandbox with hermetic tests (no network, no live `claude`, no Docker, no host); a host check can add to that, never replace it.
success: `bats` passes in the sandbox with new cases for the change; `scripts/hermeticity-lint --root .` passes.

H4: An LLM judgment is a detector, never an enforcement primitive: a blocking gate keys on something re-checkable from the artifact (an exit code, a verbatim quote with file:line), and a new judgment-based check ships advisory until a recorded falsifier passes.
success: the design names the deterministic channel that carries any model output into a blocking decision; a new judgment check is capped at amber.

S1: Security measures are proportionate: weigh a restriction's friction (egress profile work, denied tools, extra host steps) against the risk it removes given what is already permitted, and do not add a restriction whose bypass is already allowed; a relaxation that states its residual risk is a valid design.
S2: Cost scales by passes, tasks and rounds: add no new mandatory agent dispatch per pass and no more than about 30 lines to always-loaded context (no `@` imports in instruction files) unless the design states the measured delta and why it pays.
S3: Reuse the existing reviewed mechanism (launcher, installer, gate, helper) before adding a second; one trust regime and one code path per job, and one source of truth per rule or grammar, never restated.
S4: Put mechanical steps in tested scripts rather than prose; prose that must guide behaviour arrives at the moment it is needed.
S5: Establish the motive before comparing options; the status quo and deciding against a feature are valid outcomes, and value in real use outside this repo outranks loop-internal metrics.
S6: A new script, skill or workflow needs a call site something actually runs and a claimed benefit with an observable that could come out negative.
S7: Measure before budgeting a saving; a cost cut in the review pipeline is recall-neutral by construction or gated on a measured recall check.
S8: Keep units small and dependency-free: under the ~400-line cap (log row 62), no growth of the 500-plus-line files (`cc-isolated.sh`, `install.sh`), python3 stdlib and bash, no new image package.
S9: Prefer the minimal change one `git revert` undoes, staged so the cheaper step is checked first; after repeated mechanism errors, escalate to a decision instead of another patch.
S10: Spend the user's attention last: at most one host paste per verification, no new recurring host chore or trust decision, nothing left behind to clean up, and no safety that depends on the user remembering a flag.
S11: Portable where it costs little: AGENTS.md-readable instructions over Claude-Code-only hooks, pure-text mechanisms over kernel or platform primitives.