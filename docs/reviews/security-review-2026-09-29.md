Commit: de96617

# Security Review — feat/workflow-router-skills

**Scope:** `git diff main...HEAD` (8 new `skills/<name>/SKILL.md` routers, `test/skills/workflow-routers.bats`, `global-instructions/CLAUDE.md` paragraph, README count, decision log row 66). Review artifacts under `docs/reviews/` read as context only.
**Date:** 2026-09-29
**Based on:** critic brief b (Stage-1 fact-check summary, k=3 on 3a63c56, fixes in 881762a)

The code-fact-check report was supplied only as a summary in the brief; I relied on it for router-vs-workflow factual accuracy and did not re-verify those facts, except where a gate is involved.

Threat model: these files contain no executable code except a bats test. What matters for security is **agent-instruction integrity**. The routers are loaded as user-level skills in every project (via `~/.claude/skills -> /opt/claude-workflows/skills`). The questions are whether a router weakens an approval gate its workflow carries, routes an agent around one, or lets less-trusted content take over the gate-bearing procedure.

## Trust Boundary Map

```
B1 (new): [skill listing: router description/when, every session] → [agent's skill-selection + first action] → [workflow procedure incl. gates]
B2 (new): [router body "Read and follow `workflows/<name>.md`"]    → [agent path resolution, relative to cwd] → [file treated as the user's own workflow, "end to end"]
B3:       [project-level skills / project files of the current repo] → [same skill name / same relative path]  → [user-level router authority]
B4:       [test/skills/workflow-routers.bats]                      → [bats, repo-local paths only]           → [CI/health-check verdict]
```

| Label | Source | Mutability | Trust (per sink) |
|---|---|---|---|
| S1 | Router frontmatter + body in `skills/` (this repo, installed to `/opt/claude-workflows`) | deploy-time (install.sh review diff, decision 037) | trusted for all sinks (user-authored, reviewed at install) |
| S2 | `~/.claude/workflows/<name>.md` (installed copy) | deploy-time | trusted as the gate-bearing procedure |
| S3 | `./workflows/<name>.md` inside **whatever repo the session is in** | request-time / repo-controlled (any cloned repo) | UNTRUSTED as a source of approval-gate policy. In claude-workflows itself it is the same file as S2's source, so it is trusted there. |
| S4 | Project-level `.claude/skills/<same-name>/` in a foreign repo | repo-controlled | UNTRUSTED toward "user's workflow" authority |
| S5 | `workflows/*.md` enumerated by the bats test | repo files | trusted (test reads, never executes them) |

The diff adds B1 and B2. The routers are trusted, user-level instructions. B2 tells the agent to follow a **cwd-relative** path first and names the installed copy only in a parenthetical. So in any project other than claude-workflows, the file that gets "read and followed end to end" is chosen by the current repo's contents whenever a same-named file exists. The global paragraph and the routers otherwise strengthen gates: the RPI and branch-strategy routers restate their hard gates correctly, and none tells the agent to skip one.

## Findings

#### 1. Router handoff resolves a cwd-relative path first, so a repo-local `workflows/<name>.md` can replace the gate-bearing workflow in other projects

**Severity:** Medium
**Location:** `skills/{branch-strategy,codebase-onboarding,parallel-worktrees,pr-prep,research-plan-implement,spike,task-decomposition,user-testing-workflow}/SKILL.md` (the "Hand off to the workflow" paragraph, lines ~25-31 in each); pinned by `test/skills/workflow-routers.bats:95` (`grep -qF "Read and follow **\`workflows/$name.md\`**"`)
**Boundary:** B2, B3 (S3)
**Move:** #1 trust boundaries (runtime-mutable/repo-controlled ⇒ untrusted toward high-consequence sinks); #5 invert the access model
**Confidence:** Medium on the mechanism. Low on real-world likelihood: it needs a same-named `.md` under `workflows/`, and a malicious repo already has a stronger channel through its own CLAUDE.md.
**Legibility-target:** router author / reviewer of row 66

Evidence (verbatim, pr-prep router):
> Read and follow **`workflows/pr-prep.md`** end to end (installed copy:
> `~/.claude/workflows/pr-prep.md`).

When a session in a non-claude-workflows project invokes `pr-prep` or `branch-strategy` (for example "ship it" or "merge all open PRs"), the first path an agent resolves is `./workflows/pr-prep.md` in that project. A repo that ships a file of that name controls the procedure the agent now treats as the user's own workflow. The router says to follow it "end to end", and the router is user-level, so it lends the file user authority. That file can drop the /active-mode "ask first" before merging into `main`, or branch-strategy's "force-push over shared `dev` requires explicit approval". A benign name collision gives the same wrong outcome: the agent follows an unrelated project's `workflows/spike.md` as if it were this repo's spike protocol. The two routers that restate their gate (branch-strategy: "Replacing a shared branch always needs explicit user approval, in any operating mode"; RPI: "hard gate is plan approval") limit the damage for those two. The pr-prep, parallel-worktrees and spike routers restate no gate. The pattern is inherited from `skills/divergent-design/SKILL.md` (pre-existing), but this branch copies it to the two workflows that carry merge and force-push gates. The DD hook (`hooks/dd-routing-reminder.sh:53`) already points at the installed path, `~/.claude/workflows/divergent-design.md`, which shows the safer prior art.

**Recommendation:** Make the path explicit and scoped. Suggested wording: "In the claude-workflows repo, read `workflows/<name>.md` (the working-tree copy). In any other project, read `~/.claude/workflows/<name>.md`, never a same-named file in that project." Update the bats handoff assertion to match. Optionally, restate the one-line merge gate in the pr-prep router, the same way branch-strategy restates its gate.

#### 2. pr-prep and parallel-worktrees descriptions list "merge" as an outcome of the flow without its gate, and the description is the only text guaranteed to reach the agent

**Severity:** Low
**Location:** `skills/pr-prep/SKILL.md:4-8`, `skills/parallel-worktrees/SKILL.md:4-8`
**Boundary:** B1
**Move:** #5 invert the access model (what does the always-loaded text authorize?)
**Confidence:** Low. The gate survives in two places the agent should also read: global CLAUDE.md Operating Modes, and `workflows/pr-prep.md` "Merging into `main` follows the Operating Modes … in /active mode, ask first". A violation requires the agent to act on the description alone.
**Legibility-target:** agent reading the skill listing

Evidence:
> history cleanup, verification, then a local merge (solo) or a GitHub PR.
> Triggers: "ready to merge", "open a PR", "ready for review", "package this up", "ship it",

> parallel git worktrees, then review and merge each item as soon as it is clean.

These descriptions sit in every session's context. They describe merging as the flow's end state, with broad triggers ("ship it", "wrap this up"). In /active mode, a merge into `main` and pushing or opening a PR each need approval. That gate is absent from both descriptions and from the pr-prep router body, while the branch-strategy router does restate its gate. This is not a bypass; the gate text is intact elsewhere. It is an inconsistency, and a one-phrase fix would close it.

**Recommendation:** Add "(merge/PR per Operating Modes: ask first in /active)" to the pr-prep router body's "When to use" line, or to its description. Say "merge each item when clean, with approval per Operating Modes" in parallel-worktrees.

#### 3. Generic user-level skill names can be shadowed by project-level skills of the same name

**Severity:** Informational
**Location:** `name:` frontmatter of all 8 routers (e.g. `name: pr-prep`, `name: spike`)
**Boundary:** B3 (S4)
**Move:** #1 trust boundaries
**Confidence:** Low. Claude Code's precedence between personal and project skills of the same name was **not tested** here.
**Legibility-target:** maintainer

If project skills take precedence, a foreign repo's `.claude/skills/pr-prep/` would replace the gate-bearing router, and the global instruction "invoke its skill rather than paraphrasing" would then direct the agent into the project's version. As with finding 1, a malicious repo already has project CLAUDE.md, so the added risk is small. It matters mainly for benign collisions: generic names like `spike` and `pr-prep` make them likelier.

**Recommendation:** None required. If a collision is ever observed, consider namespaced names (e.g. `cw-pr-prep`). Record the precedence question as a Known Unknown.

## Untested bypass candidates

Guardrail: the bats contract test (as a guard against a router drifting into restating or weakening its workflow).
- A router that stays ≤45 body lines, keeps the handoff string, and still adds a sentence contradicting a gate (e.g. "merging needs no approval in solo projects"). Untested because the test checks only structure, never gate content. The Stage-1 fact-check covered content at 881762a; nothing mechanical guards it afterwards.
- A router whose **description** (not body) weakens a gate. The test asserts only the `name`/`description`/`when` keys exist. Untested for the same reason.
- A new workflow added to `EXEMPT` to dodge the router requirement. The test only checks the exempted workflow exists and has no router; reviewers catch this, not the test.

For these reasons the test does not appear in Endorsement Claims as a gate-integrity guard.

## Endorsement Claims

- **Claim:** The 8 routers pass the structural contract at de96617 (frontmatter keys, handoff string, "(router)" title, ≤45 body lines, review-fix-loop exempt with no router).
  **Location:** `test/skills/workflow-routers.bats`
  **Evidence:** executed
  **Verified:** `timeout 60 bats test/skills/workflow-routers.bats`: tests 1-6 ok. `ls skills/review-fix-loop`: no such directory.
  **Not verified:** gate content of router text (see Untested bypass candidates).
- **Claim:** The branch-strategy router restates the shared-branch force-push approval gate, and the RPI router restates plan approval as the hard gate. Both are consistent with their workflows' text as read.
  **Location:** `skills/branch-strategy/SKILL.md:29-30`, `skills/research-plan-implement/SKILL.md:29-31`
  **Evidence:** read-static
  **Verified:** router lines, compared with `workflows/branch-strategy.md` "Promote only through the approval gate" and RPI step 4 "This is the hard gate".
  **Not verified:** whether an agent acting from the description alone, without reading the body, observes these gates.
  **route: code-fact-check**
- **Claim:** The workflows the routers point to are installed alongside the skills, so the parenthetical installed path exists in other projects.
  **Location:** `devcontainer-config/install.sh:135` (`CLAUDE_HOME_SRC=(... skills workflows ...)`)
  **Evidence:** read-static, plus `ls ~/.claude/workflows` in this container (all 10 present)
  **Verified:** the install source list; this container's `~/.claude/workflows`.
  **Not verified:** host installs that use `install.sh`'s non-container target.
- **Claim:** The bats test reads repo files only and passes no file content to eval or exec.
  **Location:** `test/skills/workflow-routers.bats:16-123`
  **Evidence:** read-static
  **Verified:** full file read. The only external commands are awk, tr, grep, wc and basename, on `$REPO_ROOT` paths.
  **Not verified:** the bats harness's own setup under `scripts/run-tests.sh`.

## Primitive sweep

Primitive sweep: no dangerous primitives in scope. The only executable change is the bats test, which uses `grep -qE "^name:[[:space:]]*${name}…"` with `name` taken from `workflows/*.md` basenames. That is a regex built from trusted repo filenames, with no exec, eval or deserialize sink.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Cwd-relative handoff lets a repo-local `workflows/<name>.md` replace the gate-bearing workflow in other projects | Medium | B2, B3 | 8 router handoff paragraphs; bats:95 | Medium (mechanism) / Low (likelihood) |
| 2 | pr-prep / parallel-worktrees descriptions describe merging without its Operating-Modes gate | Low | B1 | `skills/pr-prep/SKILL.md:4-8`, `skills/parallel-worktrees/SKILL.md:4-8` | Low |
| 3 | Generic skill names shadowable by project skills (precedence untested) | Informational | B3 | router `name:` fields | Low |

## Overall Assessment

No router weakens or contradicts a gate its workflow carries. The global paragraph ("invoke its skill rather than paraphrasing") and the restated gates in the branch-strategy and RPI routers make gates more likely to be applied, not less. The one design-level issue is the handoff path (finding 1): outside claude-workflows it lets the current repo's contents pick the procedure that the user-level router endorses. The fix is a one-line wording change in each router plus the matching test string. It is fixable in place and not architectural. The most important thing to address: point the routers at `~/.claude/workflows/<name>.md` outside the claude-workflows repo. No findings beyond these within the code paths read. The endorsement claims marked read-static are pending execution verification.

## Goal-Alignment Note

- **Answered:** Security critique of `main...HEAD` at de96617, focused on whether any router weakens, contradicts or routes around an approval gate: none does. Also covered: the cwd-relative path issue the brief flagged (as finding 1), description-level gate omission, and skill-name shadowing.
- **Out of scope:** Trigger-overlap and mis-routing quality, and per-session context cost (not security; left to the other critics). Router-vs-workflow factual accuracy beyond gates (relied on the Stage-1 fact-check summary).
- **Escalate:** Finding 1's recommended wording changes the bats handoff assertion, so the author needs to update the test with the text. Claude Code's personal-vs-project skill precedence (finding 3) is unverified and would need a host check.
