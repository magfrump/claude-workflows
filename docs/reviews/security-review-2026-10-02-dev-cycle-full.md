Commit: bc5dc76

# Security Review — feat/dev-cycle, full branch (final confirming pass, k=1)

**Scope:** `git diff main...HEAD -- . ':!docs/reviews'` in `/workspace/.claude/wt-devcycle` (13 files). Security-relevant: `scripts/dev-cycle.sh`, `skills/dev-cycle/SKILL.md`, `docs/dev-cycle.md`, `workflows/codebase-onboarding.md` step 13. The others are docs and were read for anything that widens a boundary.
**Date:** 2026-10-02
**Based on:** no fact-check report for this pass yet (the full-branch fact-check runs alongside). Prior passes' reports and the rubric `docs/reviews/code-review-rubric-2026-09-29-feat-dev-cycle-digest.md` were used as context only.
**Replication:** k=1

> ⚠️ **No code fact-check report provided.** Claims about security properties in comments and documentation have not been independently verified. For full verification, run the `code-fact-check` skill first or use the code-review orchestrator. (The parallel full-branch fact-check covers this.)

Legibility-target values: **agent** (the model running the skill or reading the digest), **maintainer** (someone editing the script or skill), **user** (the human reading the digest, record or roadmap).

Execution (scratch only, under `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/secF/`, throwaway repos under `mktemp -d`, every run under `timeout`; nothing written to the worktree except this file):
- `timeout 300 bats test/scripts/dev-cycle.bats` (cwd the worktree, HEAD bc5dc76): 23/23 ok.
- P1: a repo whose decision record's trigger line holds ESC/BEL/CSI, `\xc2\x9b`, a nested RLO (`\xe2\x80\xc2\x85\xae`), a C0-split RLO (`\xe2\x00\x80\xae`), a tag character, U+2028, CR, a lone `\x9b31m` and U+200B. It also has `docs/decisions/002-evil.md -> /etc/passwd`, `docs/working/cycles/cycle-2026-09-30.md -> /etc`, `docs/roadmap.md` as a FIFO and `docs/working/questions.md -> ` an outside file. Exit 0. Every removable sequence was removed; the lone `\x9b` and U+200B survive (both documented as not covered). All four non-plain paths were skipped and listed in section 8. The Window line gave the "records … were skipped" source. No outside content was printed.
- P1 rerun with `PERLIO=:utf8 PERL_UNICODE=SDA`: 0 lines with `\xc2[\x80-\x9f]`, `\xe2\x80\xae`, ESC or `\xf3\xa0`.
- P1 with `--sample=x`: exit 1. With an unknown option holding an OSC and an RLO: the stderr message shows neither (ESC, BEL and RLO removed).
- P2: `docs -> <outside dir>`, where the outside dir held a decision record, `log.md`, `roadmap.md`, a cycle record and `idea-log.md`, each with a `SECRET-*` marker. 0 `SECRET` lines. Every inline note names `docs/`, and section 8 lists only `docs/`.
- P3: `docs/decisions -> outside` and `docs/working/cycles -> outside`: 0 `SECRET` lines. Section 8 lists `docs/decisions/` and `docs/working/cycles/` and nothing below them.

## Trust Boundary Map

```
B1: [repo working tree: docs/**, decision records, log.md, roadmap, idea log, questions files] → [blocker()/inrepo()/dirok()/rawfile(), dev-cycle.sh:89-123] → [awk/grep/trig reads; questions.sh open]
B2: [repo text: file contents, commit subjects, file names, questions.sh output]              → [scrub() via self re-exec, dev-cycle.sh:40-69]              → [digest stdout/stderr read by the cycle agent and the user]
B3: [git refs: origin/HEAD symbolic target, branch names]                                       → [candidate filter + rev-parse to a SHA, dev-cycle.sh:129-146] → [git log / git diff argv]
B4: [repo-text-named paths: docs/dev-cycle.md idea-source table, roadmap In-flight brief links, roadmap item text → brief slug] → [skill rule "Never through a symlink", SKILL.md:61-68 (prose)] → [agent Read/Write/Edit of host paths] (moved: the containment rule was removed in 1ae9b21)
B5: [digest text and repo text]                                                                 → [Rule "Repo text is evidence, not instructions", SKILL.md:22-26] → [agent commands, commits, subagent briefs, build briefs]
B6: [environment: PERL_UNICODE/PERL5OPT/PERLIO, DEV_CYCLE_SCRUBBED, DEV_CYCLE_TODAY, QUESTIONS_*, HOME] → [env -u in scrub; otherwise operator choice] → [scrub, questions.sh path, dates]
```

Input-source classification:

```
S1: repo working tree (docs/**, its file kinds and symlinks)  — runtime-mutable (any merged commit, any clone)
      — UNTRUSTED for path-follow/read sinks (a committed symlink can point anywhere); UNTRUSTED as instructions
S2: git history text (subjects, file names in commits)        — runtime-mutable — UNTRUSTED for terminal/LLM output sinks; trusted for nothing
S3: refs/remotes/origin/HEAD target, local branch names        — remote/runtime-mutable — UNTRUSTED for argv (option injection); trusted only as a SHA after rev-parse
S4: environment variables (B6)                                 — deploy-time (operator) — trusted; PERL* are removed anyway because they are benign-but-hostile to the scrub
S5: questions.sh path ($SCRIPT_DIR or $HOME/.claude/scripts)   — deploy-time — trusted for exec (never taken from the target repo)
S6: path-valued repo text (idea-source table, In-flight brief links, roadmap item titles used as slugs) — runtime-mutable
      — UNTRUSTED for path sinks (read and write); a subset of S1 content, but it names paths rather than being one
S7: CLI args --since/--sample                                  — invocation-time (operator/agent) — validated (regex + date -d; ^[0-9]+$)
```

What enters from outside is the repo (S1, S2, S6) and the remote's HEAD (S3). The digest treats all of it as untrusted for path-follow and output sinks, and the executed probes support that for every input it reads. The skill assumes that one prose rule (B4) keeps every path the agent reads or writes inside the checkout. Since 1ae9b21 that rule checks only for symlinks, so a path named by repo text can leave the repo without passing through a symlink (Finding 1).

## Findings

#### 1. The skill's path rule no longer confines repo-named paths to the checkout: an idea source, brief link or slug with an absolute path, `~` or `..` passes the symlink check

**Severity:** Medium (floor rule: a named mechanism, a committed table row, in a reachable environment, a repo whose default branch takes merged changes, or any cloned repo, since the installed skill serves any project)
**Location:** `skills/dev-cycle/SKILL.md:61-68`, `:201-203`, `:227-237`, `:254`; `docs/dev-cycle.md:26-27`
**Boundary:** B4 (moved)
**Move:** 1 (runtime-mutable ⇒ compromise-reachable), 2 (implicit sanitization assumption), 11 (guardrail bypass)
**Confidence:** Medium. Read-static. Whether an agent reads `~/.ssh/*` or `../../x` on a table row's say-so depends on the model's own caution. The skill's text does not forbid it.
**Legibility-target:** agent, maintainer
**Evidence (verbatim):**
- `SKILL.md:61-66`: `**Never through a symlink.** The cycle reads and writes repo files (idea sources and their\nglob matches, the idea log, briefs, the record, the roadmap, questions) only by plain paths:\nbefore each read or write, check that no part of the path below the repo root is a symlink\n(\`test -L\` on each component; a file not yet created is checked through its directories),\nand expand a glob only inside a directory that passes the same check. A path that fails is\nskipped and listed in the record under \`## Skipped inputs\`.` [excerpt; the paragraph continues to `:68` with the digest's rule and section 8]
- `SKILL.md:201-203`: `Otherwise read this cycle's signals, the idea log and the\nidea sources \`docs/dev-cycle.md\` lists` [excerpt; the sentence continues with the fallback and "generate 3–8 ideas"]
- `docs/dev-cycle.md:27`: `Plain paths only: the skill never reads through a symlink.`
- Removed by 1ae9b21 (pass-8 fixes), `git show 1ae9b21 -- skills/dev-cycle/SKILL.md`: `-**Paths stay inside the repo.** Every file the cycle reads or writes because a setting, a\n-glob or a default names it (idea sources, the idea log, briefs, the record, the roadmap) must\n-resolve, symlinks followed, to a path inside the checkout: the digest's \`inrepo\` rule.`

The rubric records the pass-7 security F2 / A2 Medium ("The sources file can also point seeding or brainstorm reads outside the repo") as fixed by cfe4b51: "every path must resolve inside the checkout". Pass 8 then replaced that containment rule with the symlink-only rule above, so the fix regressed. The current check walks components "below the repo root" and tests each with `test -L`. A table row `| x | /home/node/.claude/.credentials.json | … |`, `~/.ssh/*` or `../../other-project/docs/*.md` contains no symlink, so it passes, and step 5 tells the agent to read what the table lists. Brainstorm ideas carry a `signal:` naming what prompted them. The idea log and the roadmap's Ideas section are committed and landed on the default branch in step 7, so out-of-repo text can be disclosed into history (and to any remote). The write side has the same gap. A roadmap In-flight entry's brief link (read and edited in steps 1–2 of In flight: `Status: closed`, `Kept:`, `Applied:`) and the brief slug derived from a Now item's title (`:254`) are both repo text. A `..` in either reaches a file outside the checkout without any symlink. The digest itself is not affected: every path it reads is a constant or a glob item (pass 12's trace, re-read here at `:149-150`, `:204`, `:215`, `:252`, `:291`, `:341`, `:352`).
**Recommendation:** Restore containment next to the symlink rule, for every path that a setting, a link or repo text names. The path must be relative, contain no `..` component and no leading `~` or `/`, and also pass the symlink walk. A path that fails is skipped and listed under `## Skipped inputs`. Add the same sentence to `docs/dev-cycle.md:27` ("relative paths inside this repo only; no symlinks"), and make step 6 say that a slug is `[a-z0-9-]` only.

#### 2. Two skill-only inputs get no mechanical check: `docs/working/handoffs/` and `docs/dev-cycle.md`

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:114-123` (the checked inputs); `skills/dev-cycle/SKILL.md:129-131`, `:201-203`, `:254`
**Boundary:** B1, B4
**Move:** 11 (alternate paths that skip the guard)
**Confidence:** Medium
**Legibility-target:** maintainer
**Evidence (verbatim):** `SKILL.md:66-68`: `The digest applies the same rule\nto everything it reads (and also skips anything that is not a regular file or directory) and\nlists what it skipped in its section 8.` (end of the paragraph). `SKILL.md:254`: `For each, write \`docs/working/handoffs/YYYY-MM-DD-<slug>.md\`` [excerpt; the sentence continues with the path-uniqueness rule].

Every other path the skill reads or writes has its symlink state surfaced mechanically in digest section 8: the cycle-record directory, the decision inputs, `docs/working/questions*.md`, the roadmap and the idea log. (`questions.sh` also refuses symlinked write targets, `scripts/questions.sh:88-127`.) The briefs directory, read in step 1 and In flight and written in step 6, and the settings file, read in step 5, are checked only by the prose rule, which Q-074's evidence says is the weakest kind of guard. A committed `docs/working/handoffs -> ~/.claude/` would make step 6's Write create a brief in the user's global directory. The prose rule forbids this, so this is defense in depth, not a reachable bypass.
**Recommendation:** Have the digest run `skipdir docs/working/handoffs` and `skipped docs/dev-cycle.md` (no reads) so section 8 names them when they are not plain. That puts every skill input under the one `blocker()` rule.

## Untested bypass candidates

For `scrub()` (`dev-cycle.sh:40-57`):
- **Lone 0x9B (8-bit CSI) and other lone 0x80–0x9F bytes or overlong encodings** on a terminal set to accept 8-bit C1 controls in a non-UTF-8 locale. Executed: the byte reaches the output (P1, `H\x9b31m`), as the header's "Not covered" list says. Not tested against such a terminal: none is available in the sandbox. The digest's designed consumer is the agent's tool output, which interprets no C1. A user running it by hand in an xterm in a Latin-1 locale is the only place it acts. Because this candidate is untested, the scrub does not appear in Endorsement Claims.
- **U+200B / other zero-width and format characters** (executed: U+200B survives). They are documented as not covered. They cannot start a line or reorder text, so they can hide words but not forge digest structure.

Tested candidates for `scrub()` (all removed): ESC/BEL/CR (C0), `\xc2\x9b` (C1 as UTF-8), RLO rebuilt from the bytes around a deleted C1 sequence, RLO split by a C0 byte, a tag character, U+2028, hostile `PERLIO`/`PERL_UNICODE`, and an OSC/RLO in an option name on stderr.

Tested candidates for `blocker()` (B1): a symlinked file at a glob item (`002-evil.md`), a symlinked cycle record to a directory, a FIFO at a fixed path (git cannot commit one; tested anyway), a file symlink to an outside file (`questions.md`), a symlinked `docs/`, and symlinked `docs/decisions` and `docs/working/cycles`. None printed outside content, and each listed only the first blocking part.

Not tested, and outside this diff's code: an agent interpolating a repo-text branch name from a brief (`Branch:` line) into a git command in In flight step 1 (option injection such as `--output=…`). Git refs cannot start with `-`, but argv parsing happens before ref validation. This depends on how the agent builds the command, which the skill does not script.

## Endorsement Claims

- **Claim:** With `docs/`, `docs/decisions` or `docs/working/cycles` a committed symlink to an outside directory, the digest prints no content from the outside directory and lists only the symlinked component in section 8.
  **Location:** `scripts/dev-cycle.sh:103-123`, `:149-162`, `:204`
  **Evidence:** executed
  **Verified:** probes P2 and P3 (`SECRET-*` markers in five outside files; 0 matching lines; section 8 lists `docs/`, or `docs/decisions/` and `docs/working/cycles/`); bats 23/23.
  **Not verified:** a symlink *inside* `docs/working/` to a sibling directory in the repo (e.g. `cycles -> ../archive`): read-static, the realpath differs, so it is skipped.
  **route: code-fact-check**
- **Claim:** Only a full SHA reaches `git log`/`git diff` as a revision argument. A remote HEAD or current branch whose name begins with `-` is not used.
  **Location:** `scripts/dev-cycle.sh:129-146`, `:190`, `:193`, `:309`, `:326`
  **Evidence:** read-static
  **Verified:** the candidate loop skips `-*` names, takes `MAIN_SHA` from `rev-parse --verify` on `refs/heads/$c^{commit}`, and the git calls pass `$MAIN_SHA` or `$full` (a `%H` from git's own output). Pathspecs are literal (`GIT_LITERAL_PATHSPECS=1`) and follow `--`.
  **Not verified:** a run against a repo whose `origin/HEAD` points at a branch literally named `--output=x` (not executed this pass).
  **route: code-fact-check**
- **Claim:** A failing digest step propagates a non-zero exit through the two scrub filters.
  **Location:** `scripts/dev-cycle.sh:66-69`
  **Evidence:** executed
  **Verified:** `--sample=x` exited 1 through the re-exec.
  **Not verified:** a failure mid-digest after output has begun (e.g. a `git log` failure in section 7).
- **Claim:** `questions.sh` is taken from the script's own directory or `~/.claude/scripts`, never from the target repo, and runs only after both questions files pass the walk.
  **Location:** `scripts/dev-cycle.sh:243-262`
  **Evidence:** read-static
  **Verified:** `QS="$SCRIPT_DIR/questions.sh"` with `$HOME` fallback. The archive is checked up front (`:250`), and the `elif` chain reaches `bash "$QS" open` only when `docs/working/questions.md` passes `inrepo` and `qa_at` is empty.
  **Not verified:** an operator-set `QUESTIONS_LIVE`/`QUESTIONS_ARCHIVE` makes questions.sh read a path other than the one the digest checked. This is env-controlled (S4) and exempted by questions.sh's own header.

## Primitive sweep

Primitive: process exec
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `dev-cycle.sh:67` `bash "${BASH_SOURCE[0]}"` | S5 (own path) | none needed | cleared — the script re-execs itself |
| `dev-cycle.sh:262` `bash "$QS" open` | S5 | fixed locations, not repo | cleared — deploy-time path |
| `dev-cycle.sh:42` `perl -C0 -ne` | code constant | `env -u PERL*`, `LC_ALL=C` | cleared — executed with hostile PERLIO |
| `dev-cycle.sh:79` `sed -n '2,21p' "$0"` | S5 | none needed | cleared |
| `SKILL.md:121-124` health check; `:166-168` cited tests | S1 (repo code) | Rule `:25-26` (only named commands and tests in the repo's tree) | cleared — repo code on the default branch is the user's merged code; running it is the purpose |

Primitive: path read/traversal (file reads)
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `dev-cycle.sh:150-158` cycle glob | S1 | `dirok` + `rawfile` | cleared — P1, P3 |
| `dev-cycle.sh:204-213` decision glob, `grep`/`trig <` | S1 | `dirok` + `rawfile` | cleared — P1, P3 |
| `dev-cycle.sh:215-225` `log.md` | S1 | `inrepo` | cleared — P2 |
| `dev-cycle.sh:250-262` questions files (via questions.sh) | S1 | `skipped`/`inrepo` | cleared — P1 |
| `dev-cycle.sh:291-295`, `:341-345` roadmap | S1 | `inrepo` | cleared — P1 (FIFO), P2 |
| `dev-cycle.sh:352-358` idea log | S1 | `inrepo` | cleared — P2 |
| `SKILL.md:201-203` idea sources from `docs/dev-cycle.md` | S6 | symlink walk only (prose) | Finding 1 |
| `SKILL.md:227-237` In-flight brief links (read + edit) | S6 | symlink walk only (prose) | Finding 1 |
| `SKILL.md:254` brief path from slug (write) | S6 | symlink walk only (prose) | Finding 1; dir unchecked by digest, Finding 2 |
| `SKILL.md:263` cycle record (write) | S1 | prose walk; digest lists a non-plain `docs/working/cycles/` | cleared — fixed name, surfaced by section 8 |

Primitive: git argv (option/pathspec injection)
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `dev-cycle.sh:136` `rev-parse refs/heads/$c^{commit}` | S3 | `-*` filter, `refs/heads/` prefix | cleared — read-static |
| `dev-cycle.sh:190`, `:193`, `:326` `git log "$MAIN_SHA"` | S3→SHA | SHA only | cleared |
| `dev-cycle.sh:210`, `:292` `git log -1 -- "$f"` | S1 names | `--`, `GIT_LITERAL_PATHSPECS=1` | cleared |
| `dev-cycle.sh:309` `git diff "$full^1" "$full"` | S2 (`%H`) | git-produced hash | cleared |

Primitive: `date -d` / `awk -v` (value interpretation)
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `dev-cycle.sh:172` `date -d "$TODAY - 14 days"` | S4 | none (env) | cleared — operator value, no exec |
| `dev-cycle.sh:179` `date -d "$SINCE"` | S7 / S1 file name | regex `^[0-9]{4}-…$` first | cleared |
| `dev-cycle.sh:359-360` `date -d "$last_bs"` | S1 | `grep -oE` digits-only extraction | cleared |
| `dev-cycle.sh:190`, `:193`, `:327` `awk -v s="$SINCE"` | S7 | validated at `:179` | cleared |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Skill path rule lost containment (regression from 1ae9b21): repo-named idea sources, brief links and slugs can reach outside the checkout without a symlink | Medium | B4 | `skills/dev-cycle/SKILL.md:61-68,201-203,227-237,254`; `docs/dev-cycle.md:27` | Medium |
| 2 | `docs/working/handoffs/` and `docs/dev-cycle.md` get no mechanical check in the digest | Informational | B1, B4 | `scripts/dev-cycle.sh:114-123`; `SKILL.md:129-131,201-203,254` | Medium |

## Overall Assessment

The digest's own boundaries hold in every probe run against bc5dc76. No outside content was read through any symlinked file or directory, the scrub removed every sequence it claims to (including under a hostile PERLIO), only SHAs reach git as revisions, and a failure exits non-zero through both filters. The remaining scrub gap (lone C1 bytes on an 8-bit terminal) is documented and untested here. The skill is a different story. Pass 8's rewrite of the path rule from "resolve inside the checkout" to "no symlink component" re-opened the pass-7 Medium (A2): a committed idea-source row, In-flight link or slug can name an absolute, `~` or `..` path that passes the new check. That is one sentence to restore in `SKILL.md:61-68` and `docs/dev-cycle.md:27`, and it is the single most important thing to fix before merge. It is fixable in place and needs no architectural change. Under the brief's rule (any amber means one more fix round), Finding 1 calls for one more round. Endorsement claims are scoped above, with their `Not verified` hops named, and are pending execution verification by code-fact-check.

## Goal-Alignment Note

Success criterion (verbatim): "a markdown report saved at the path your role instructions give, structured per your skill file."

Saved at `/workspace/.claude/wt-devcycle/docs/reviews/security-review-2026-10-02-dev-cycle-full.md`, first line `Commit: bc5dc76`. It has the skill's sections: Trust Boundary Map with source table, findings carrying Severity, Location, Evidence (verbatim), Confidence and Legibility-target, untested bypass candidates, Endorsement Claims routed to code-fact-check, primitive sweep, summary and overall assessment. Against the user goal (merge on a clean pass): this pass is not clean. Finding 1 is Medium (amber) and is a regression of an earlier fixed finding. Not committed. Nothing else was written to the worktree.
