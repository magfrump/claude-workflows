Commit: 5ee8315

# Security Review — fix/agents-md-no-imports

**Scope:** `git diff main...HEAD` in `/workspace/.claude/wt-agents-md` (AGENTS.md, docs/decisions/log.md, scripts/health-check.sh, test/agents-gemini-sync.bats)
**Date:** 2026-09-29
**Based on:** Stage-1 code-fact-check (k=3, merged), summarized in the critic brief

## Trust Boundary Map

```
B1: [AGENTS.md text in repo]          → [Claude Code @-import expansion at session start] → [model context as project instructions]
B2: [file named by an @path]          → [inline expansion, no review of target content]  → [model context as project instructions] (removed for the 9 workflow entries)
B3: [workflows/*.md named by filename] → [agent's own Read tool call, visible to hooks]     → [model context as read file content] (new)
B4: [AGENTS.md edit in a commit]      → [test/agents-gemini-sync.bats guard + sync diff]  → [merged main] (new guard)
```

| Label | Source | Mutability | Trust classification |
|---|---|---|---|
| S1 | AGENTS.md / GEMINI.md contents | deploy-time (committed, reviewed) | trusted as instruction text, to the extent reviewed |
| S2 | Target of an `@path` import | whatever the target's mutability is (committed file, gitignored file, a file under `~/`, a tool-written file) | UNTRUSTED toward the instruction sink unless the target is itself committed and reviewed: the import line is reviewed, the target content is not |
| S3 | `workflows/*.md` read on demand | deploy-time (committed) | trusted as instruction text; now loaded by explicit Read, which `hooks/log-usage.sh` can observe |
| S4 | Installed copy at `~/.claude/workflows` → `/opt/claude-workflows/workflows` | separate checkout, updated by install | trusted, but may differ from the repo's `workflows/` |

The diff removes nine B2 crossings (repo-internal `@./workflows/*.md` targets, all committed files, so no untrusted content was actually entering) and replaces them with B3, where content enters only when an agent chooses to read it. The one new control is the B4 guard. The security questions are therefore: (a) does dropping the inlined workflow text remove any safety gate an agent was relying on, and (b) does the B4 guard stop an `@` import that would let unreviewed or sensitive content into the instruction channel.

## Findings

#### B4 guard misses `@` forms that pull unreviewed or sensitive files into model context

**Severity:** Low
**Location:** `test/agents-gemini-sync.bats:34`
**Boundary:** B4, B2
**Move:** #11 (enumerate bypasses for every guardrail)
**Confidence:** High (probed)
**Legibility-target:** the author of the next AGENTS.md edit, and the reviewer reading row 65

Evidence (verbatim regex): `grep -nE '(^|[[:space:]*`])@\.{0,2}/' "$AGENTS"`. Running the probe strings through this regex gave: `@workflows/pr-prep.md` MISSED, `@~/.ssh/id_rsa` MISSED, `(@./workflows/x.md)` MISSED, `"@./x.md"` MISSED, `[@../x](y)` MISSED; `` `@./x.md` `` CAUGHT (a false positive, since Claude Code does not expand imports inside code spans); `mail a@b.com` not matched (correct). Claude Code's import syntax accepts relative paths with no `./` prefix and home-relative `@~/…` paths, so a line like `- @~/.aws/credentials` or `- @docs/working/notes.md` would pass the guard and be expanded. The first puts credential material into every session's context, and so into API traffic and transcripts. The second raises a gitignored or tool-written file to project-instruction authority, even though the reviewed AGENTS.md diff shows only a harmless-looking path. That is runtime-mutable content arriving with instruction authority (S2). The severity stays below the Medium floor because adding such a line already requires committing to AGENTS.md, which gives the same author direct control of the instruction text. The added risk is **review evasion** (the line looks harmless and the target content is not in the diff), not new capability. The guard is also stated as a cost control rather than a security control. The fact-check already records the correctness side (INCORRECT: row 65 says "fails on any `@path` import").

**Recommendation:** Widen the pattern to what Claude Code actually expands: `@` followed by a path-like token (`~/`, `/`, `./`, `../`, or `name/…`/`name.md`), preceded by start of line, whitespace or common punctuation (`(`, `[`, `"`, `*`). Also exclude code spans, or accept that false positive. Alternatively, narrow the wording of row 65 to the forms actually caught. Add the MISSED strings above as fixture cases so the guard's coverage is pinned.

#### Bare filenames can resolve to the installed workflow copy rather than the repo copy

**Severity:** Informational
**Location:** `AGENTS.md:9-18`
**Boundary:** B3 (S3 vs S4)
**Move:** #2 (implicit assumption about where a name resolves)
**Confidence:** Medium
**Legibility-target:** agents following AGENTS.md in this repo

Evidence: the entries are now `**pr-prep.md**` etc., with the intro line "check `workflows/` for applicable process docs". The global instructions say that process docs live in `~/.claude/workflows/`, and in this environment `~/.claude/workflows -> /opt/claude-workflows/workflows`, a separate checkout. An agent working in this repo may open the installed copy instead of `workflows/<name>`. While a change to a workflow is in flight, the two can differ, so the agent follows the stale gate text. This is an integrity and consistency issue, not an exploit. It matches what GEMINI.md already did.

**Recommendation:** None required. If it matters, write the entries as `` `workflows/pr-prep.md` `` in both files. This breaks neither the sync test nor the guard, and `extract_workflows` would need its pattern extended.

## Untested bypass candidates

None. Every bypass candidate enumerated for the B4 guard was executed against the regex (results above).

## Endorsement Claims

- **Claim:** Removing the inlined workflow text does not remove the force-push/reset/branch-deletion approval gate from the instructions an agent sees in this repo.
  **Location:** `global-instructions/CLAUDE.md:217`; `AGENTS.md` (whole file)
  **Evidence:** read-static
  **Verified:** grep found the gate text ("Force-push, `git reset --hard`, deleting branches, dropping database tables") under "Still require user approval" in global-instructions/CLAUDE.md. That file is installed as `~/.claude/CLAUDE.md` (symlink to `/opt/claude-workflows/CLAUDE.md`).
  **Not verified:** whether the installed `/opt/claude-workflows/CLAUDE.md` matches this worktree's `global-instructions/CLAUDE.md` byte for byte, and whether non-Claude agents that read only AGENTS.md (the audience row 65 names) ever had this gate, since AGENTS.md itself does not carry it before or after the diff.
- **Claim:** The `security-reviewer` trigger row stays visible in AGENTS.md without the workflow imports.
  **Location:** `AGENTS.md:29,39`
  **Evidence:** read-static
  **Verified:** grep of the post-diff AGENTS.md shows the skill-routing row and the composition note.
  **Not verified:** whether pr-prep's code-review → security-reviewer composition, previously inlined, is reached in practice now that pr-prep.md loads only on an explicit Read.
- **Claim:** The guard rejects all nine pre-branch `@./workflows/*.md` lines.
  **Location:** `test/agents-gemini-sync.bats:33-39`
  **Evidence:** executed (per Stage-1 fact-check: "guard fails on the old AGENTS.md")
  **Verified:** the fact-check ran the guard against the old AGENTS.md; my probes confirm that the `@./` form after `*` or whitespace matches.
  **Not verified:** the non-`./` import forms listed in the finding above.

## Primitive sweep

Primitive: instruction-file `@path` import (content inclusion into model context)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `AGENTS.md:9-16,18` (pre-branch, 9 lines) | S2 → committed `workflows/*.md` | none before; B4 after | removed by the diff |
| `AGENTS.md` (post-branch) | S1 | B4 regex | no `@` imports present (grep over all import shapes returned nothing) |
| `GEMINI.md` | S1 | sync test only | no `@` imports present; Gemini CLI also supports `@` imports, and the sync test forces any import to appear in both files but does not forbid one |
| `global-instructions/CLAUDE.md`, tracked `*CLAUDE.md` | S1 | none | no `@` imports present (same grep); out of the guard's scope |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---|---|---|---|---|
| 1 | Guard misses `@~/…`, `@name/…`, punctuation-prefixed imports | Low | B4, B2 | `test/agents-gemini-sync.bats:34` | High |
| 2 | Bare filenames may resolve to the installed workflow copy | Informational | B3 | `AGENTS.md:9-18` | Medium |

## Overall Assessment

The change narrows the instruction-loading surface. Nine inline inclusions become explicit, hook-visible Reads, and no approval gate or security-routing rule is lost from what agents in this repo see (the Operating Modes gate lives in the global instructions; the security-reviewer trigger stays in AGENTS.md). The one security-relevant gap is that the new guard covers only `./`/`../`/`/`-prefixed imports after whitespace, `*` or a backtick. It misses `@~/…` and prefix-less relative imports, which are exactly the forms that could put credentials or unreviewed runtime files into context. The risk is bounded, because only someone who can already edit AGENTS.md can exploit the gap. Fixable in place: widen the regex, or narrow row 65's claim. No findings within the code paths read rise above Low. Endorsement claims are read-static except the third, and are pending execution verification where marked.

## Goal-Alignment Note

- **Answered:** Security review of the full `main...HEAD` diff at 5ee8315, covering what agents are now instructed to load and whether the new guard can be bypassed. The bypass candidates were probed by execution.
- **Out of scope:** Whether `/opt/claude-workflows` is in sync with this worktree; Gemini CLI's exact import grammar (assumed from its docs, not tested).
- **Escalate:** None. No HALT pattern matched.
