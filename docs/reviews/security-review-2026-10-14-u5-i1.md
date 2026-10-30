Commit: 42414307

# Security Review — feat/build-loop-u5 (U5: docs, settings, questions), iteration 1

**Scope:** `git diff main...HEAD` on feat/build-loop-u5 (12 files), plus the code the changed docs describe: `scripts/build-loop.sh` (`read_settings`, `list_entries`, `globform`, `never_res`, `srules`, `nrules`, `check_line`, `marker`, `log_class`), `scripts/lib/dev-cycle-read.sh` (`floor`, `truthrule`, `GATE_CODE`, `ANSWER_AWK`), `scripts/questions.sh` (`render_index`), `devcontainer-config/install.sh` (header, trust notes), `scripts/health-check.sh`, `AGENTS.md`, decisions 035 and 037
**Date:** 2026-10-14
**Based on:** `docs/reviews/code-fact-check-report-2026-10-14-u5-i1.md` (Stage 1, k=1). Claims 12, 18, 25, 26 and 28 are not re-reported. Findings 3 and 4 add to Claim 12.

## Trust Boundary Map

```
B1: build-loop branch tree (same-uid loop)       → gate --merge S rules (floor, never line, Paths:) → main
B2: docs/dev-cycle.md on main's commit           → read_settings / never_res                        → gate policy, slots, never globs
B3: main first-parent subjects + C..M path names → orchestrator, SKILL.md step 0.1 (new)            → image-lag entry in questions.md → questions.sh index/archive, answer readers
B4: host checkout (sandbox-writable tree + refs) → user's release paste (rev-parse guard)           → install.sh on the host → /opt image, ~/.claude
B5: files merged to main                         → orchestrator WT / sessions in /workspace         → health-check + bats executed; checkout docs read as instructions
B6: Q-103 / Q-149 prose                          → user's policy decision                           → `Build-loop policy:` / `Self-merge never:` lines
```

Input-source classification:

```
S1: loop branch tree, commit subjects     — request-time    — UNTRUSTED (all sinks)
S2: docs/dev-cycle.md on main             — runtime-mutable — trusted for gate configuration only (floored: no
                                                              self-merge or cycle land writes it), but a plain
                                                              commit to main (F19) can change it
S3: main first-parent commit subjects     — runtime-mutable — UNTRUSTED for questions-file / Markdown sinks (user
                                                              commits, answers-shaped commits and F19 pushes carry
                                                              free text; gate and chore subjects are fixed formats)
S4: C..M changed path names               — runtime-mutable — UNTRUSTED for questions-file sinks unless every commit
                                                              is a gate merge (pathform then holds)
S5: host checkout working tree + refs/heads/main — runtime-mutable (bind-mounted rw into sandboxes) — UNTRUSTED
                                                              for host exec
S6: /opt/claude-workflows/.manifest (C)   — deploy-time (root-owned image) — trusted
S7: merged non-floor files (scripts/health-check.sh, run-tests.sh, test/**, devcontainer-config/**,
    skills/** besides SKILL.md, patterns/, guides/) — runtime-mutable via self-merge — UNTRUSTED for exec and
    instruction sinks once Q-103 permits self-merge
```

U5 adds no code to the gate. It sets the gate's configuration (B2: the never line `workflows/`, the slots line) and adds the step 0.1 instruction that copies main's commit subjects and path names into a questions entry (B3). It writes a host release paste (B4) and frames the policy decision (B6). The trust assumption under review: the never line, together with the floor, keeps everything that takes effect on merge out of self-merge, and "your review of the release is the gate" for everything else. Findings 1, 3 and 4 show the first half does not hold. Finding 1 shows the second half cannot hold for `install.sh`.

## Findings

#### 1. Self-merge can land `devcontainer-config/install.sh` and host tools, which the release paste then runs on the host unreviewed

**Severity:** High
**Location:** `docs/dev-cycle.md:11`, `docs/dev-cycle.md:36-40`; `docs/working/questions.md:101`, `:109`; `docs/working/questions.md:480`
**Boundary:** B1, B4, B6
**Move:** 5 (invert the access control model), 1 (per-consequence trust)
**Confidence:** Medium (reachable only once Q-103 is answered [2] and a brief lists the path in `Paths:`. Briefs are not read by the user (D10).)
**Legibility-target:** for-author

Evidence: the never line reads `Self-merge never: workflows/`. Nothing in `floor`/`truthrule`/`GATE_CODE` covers `devcontainer-config/` (`GATE_CODE='^scripts/(build-loop|dev-cycle|questions)\.sh$|^scripts/lib/|^skills/dev-cycle/'`). Q-103 says: "**F58, releases (partly).** Self-mergeable code reaches running sessions only through an image release, and your review of the release is the gate." Q-103 [2] says: "most work in this repo touches gate code, instruction files or skills' `SKILL.md`, which still comes to you". install.sh's own header says: "The exception is this script itself, which is NOT inert: it runs on the host from the repo and decides which diff the human reads and what gets written". Decision 035 adds: "an agent that edits `install.sh` and a human who blesses without reading still lose".

Under self-merge, a brief whose `Paths:` lists `devcontainer-config/install.sh` (or `cc-isolated.sh`, `cc-push.sh`, `cc-exit-scan.sh`, `cc-gitdir.sh`, the egress profiles, the Dockerfile) lands with no human read. The gate's commit-tree merge also never passes through the `live-verify-gate.sh` PreToolUse hook, which is the only control decision 035 names for install.sh edits. The release paste then executes that install.sh on the host, outside every sandbox. That happens before the user sees any diff, because install.sh renders the diff. The F58 mitigation is circular for this file: the release entry gives only path names, and the reviewer of the content is the code under review. Today every commit to main is hand-merged, so this path is new with self-merge. U5 is the unit that sets this repo's never line and presents the policy choice, yet neither the never line, Q-149 nor Q-103's residual list names it.

**Recommendation:** Add `devcontainer-config/` (at minimum `install.sh` and the host tools) to the interim never line, and state in Q-103's F58 bullet that host-executed files are excluded from "the release is the gate". Alternatively, require the image-lag entry to carry `git diff C M -- devcontainer-config/install.sh` in full. Never-listing is simpler and matches decision 035's "review changes to it as boundary changes".

#### 2. Q-156's paste guard is a tautology on main and binds nothing to the reviewed listing

**Severity:** Medium
**Location:** `docs/working/questions.md:480`, `:484`
**Boundary:** B4
**Move:** 4 (TOCTOU), 11 (bypass enumeration)
**Confidence:** High for the mechanism (executed). Medium for impact: install.sh still shows its own payload diff, and a moved main also needs a same-uid writer (F19).
**Legibility-target:** for-author

Evidence: `cd /home/magfrump/claude-workflows && test "$(git rev-parse HEAD)" = "$(git rev-parse refs/heads/main)" && ./devcontainer-config/install.sh`. With main checked out, HEAD is the symbolic ref `refs/heads/main`, so both sides are always equal. The guard checks only that the checkout is on main. Executed in a scratch repo: after `git update-ref refs/heads/main <planted>`, the Q-156 guard passed at the planted commit and the fixed-M guard (`= <reviewed sha>`) refused. Step 0.1's paste pins a fixed M exactly to stop this. Q-156 cannot, because M does not exist when the entry is written. Its fallback, "the next cycle's step 0.1 rewrites this body with the exact M and list", cannot fire before the paste. Q-156 itself says the image's skill lacks U4c (and so step 0.1), and that the orchestrator loop does not run until this release. So no fixed-M paste will ever be offered for this release. The user runs whatever main is at paste time. That includes anything a sandbox process moved main to (F19) after the listing the user read.

**Recommendation:** When U5 merges, rewrite Q-156 by hand with the merge SHA as M (`test "$(git rev-parse HEAD)" = <full M>`) and the final listing. Or tell the user not to paste until that rewrite lands. Drop the `refs/heads/main` form.

#### 3. The never line's own rationale covers skills/ (beyond SKILL.md), patterns/ and guides/, which it omits

**Severity:** Medium
**Location:** `docs/dev-cycle.md:36-40`; `docs/working/questions.md:348-366` (Q-149)
**Boundary:** B5, B6
**Move:** 1 (trust per sink), 5
**Confidence:** Medium (depends on sessions reading these from the checkout. Evidence below shows they do in this repo.)
**Legibility-target:** for-author

Evidence: the never-line prose reads: "every later session in this repo reads `workflows/` from its own checkout, so a workflow change takes effect on merge, while scripts, skills, hooks and guides reach running sessions only through an image release you cut". But `AGENTS.md` is loaded as project instructions here and points at checkout paths for more than workflows: "Skills are focused, single-purpose process docs in `skills/` ... read the skill file before starting the work it covers" (`AGENTS.md:24`) and "See `guides/doc-freshness.md`" (`AGENTS.md:63`). Skill files link into the checkout too: `skills/security-reviewer/SKILL.md` cites `../../patterns/orchestrated-review.md` (the goal-preamble and Goal-Alignment contract) and `guides/skill-recovery.md`. This very review was dispatched to read `skills/security-reviewer/SKILL.md` from the worktree. The floor catches `SKILL.md` (instr), but not `skills/code-review/references/{rubric,override-log,chat-synthesis}.md`, `skills/ai-personas-critique/personas.md`, `skills/ui-visual-review/references/*`, `patterns/**` or `guides/**`. Plain Markdown links and path mentions are not `@`-imports, so the floor's walk does not reach them. A self-merged edit to `skills/code-review/references/rubric.md` or `patterns/orchestrated-review.md` steers every later review in the repo, which is the same harm Q-149 [2] names for workflows.

**Recommendation:** Extend the interim never line to `workflows/ skills/ patterns/ guides/`, or narrow the prose claim and record acceptance. Either way, Q-149's question should cover these, not workflows/ alone (this widens Claim 28).

#### 4. Adds to Claim 12: the self-mergeable health-check surface is the backstop Q-103 [2] relies on, and it executes more than health-check.sh

**Severity:** Medium
**Location:** `docs/working/questions.md:109`; `docs/dev-cycle.md:36-40`; `skills/dev-cycle/SKILL.md:376-386`
**Boundary:** B5, B6
**Move:** 3 (error path), 5
**Confidence:** High (read-static)
**Legibility-target:** for-author

Evidence: Q-103 [2] "If it's wrong" reads: "the next cycle's health check, spot-check and drift check might catch it". Step 1 runs "the repo's health check from WT". `scripts/health-check.sh` runs `"${HEALTH_CHECK_RUN_TESTS:-$REPO_ROOT/scripts/run-tests.sh}"` over every suite under `test/`, and those suites source `devcontainer-config/cc-isolated.sh`, `hooks/*.sh` and `scripts/*.sh`. Only `scripts/lib/` and the three gate scripts are floored. Beyond what Claim 12 says, (a) `scripts/run-tests.sh`, `test/**` (including `test/lib/` helpers) and every script a suite sources all run unreviewed in the orchestrator's iteration after a self-merge. (b) More to the point for the policy decision: a self-merge that edits `health-check.sh`, `run-tests.sh` or a suite can silence the check Q-103 lists as the detector for bad self-merges. The backstop can be disabled by the change it is meant to catch. This adds no privilege over a hostile loop, which already has the same uid and shell. It does remove a detection layer for the honest-but-wrong case, which is the case the [2] row describes.

**Recommendation:** Either never-list `scripts/health-check.sh scripts/run-tests.sh test/`, or reword Q-103 [2]'s detection column to say the health check is itself self-mergeable.

#### 5. Step 0.1 copies main's commit subjects and path names into questions.md without `--marker`'s scrub

**Severity:** Low
**Location:** `skills/dev-cycle/SKILL.md:298-303`
**Boundary:** B3
**Move:** 2 (implicit sanitization), 12
**Confidence:** Medium
**Legibility-target:** for-author

Evidence: the new step 0.1 text says the entry holds "every first-parent commit after C as a list item (`hg -C MAIN_WT log --first-parent --format='%h %s' C..M` ...), every path changed from C to M outside `docs/`". There is no rule like `BODY_RULE`, which `--marker` applies because "questions.sh finds its index markers anywhere in a line (security i1 F1)". Executed in a scratch copy: inserting the list item `- 0123abcd fix: note <!-- index:start --> in subject` into Q-156 and running `questions.sh index` (step 1's `archive` reindexes the same way) exited 0 and deleted every line after it to the end of the file. Q-156 is last, so its heading and Needs line survive and `questions_rules` would pass the truncated body. Any entry after it would make the land refuse. A subject with an unclosed `<!--` or a CR makes FENCE_AWK refuse the whole file, which refuses every land until fixed. Step 0.1 rewrites the entry every iteration, so the wedge repeats. Answer forgery is not reachable (the `- %h ` prefix keeps a subject off `ANSWER_AWK`'s line start), and gate and chore subjects and pathform-checked gate paths cannot carry these strings. The prerequisite is a free-text commit on main's first-parent: a user commit, an answers-shaped commit or an F19 push. That actor can already do more, which is why this sits below the floor rule's bar.

**Recommendation:** Tell step 0.1 to drop or replace any subject or path holding `<!--`, a CR or non-UTF-8 (the `BODY_RULE` checks), or have a script emit the listing. Prose alone leaves it to the LLM.

#### 6. The release flag keys on a subject suffix, not on `--main-log`'s class

**Severity:** Informational
**Location:** `skills/dev-cycle/SKILL.md:301-302`; `docs/working/questions.md:101`
**Boundary:** B3, B6
**Move:** 11
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Evidence: "flag a subject ending `(build-loop self-merge)`, which no one reviewed". `log_class` decides `gate` from the subject, the `Build-loop-gate:` trailer, a byte-exact `gate_msg` and a clean merge. In this repo every hand commit (for example d7e140ea, b279a2ba) is class `other`. So the listing cannot tell the user's commits from an F19 push, and Q-103's "flags self-merges" is accurate but does not cover unreviewed `other` commits. This is not exploitable beyond F19, and step 0.2 stops on `other` lines in its window.

**Recommendation:** Annotate each listed commit with its `--main-log` class, or leave it and say so in F58.

#### 7. Both pastes execute the working-tree `install.sh`, not M's blob (pre-existing)

**Severity:** Informational
**Location:** `docs/working/questions.md:480`; `skills/dev-cycle/SKILL.md:303-304`
**Boundary:** B4
**Move:** 4
**Confidence:** High (pre-existing; accepted by decision 035)
**Legibility-target:** for-author

Evidence: `test "$(git rev-parse HEAD)" = M && ./devcontainer-config/install.sh`. The guard binds HEAD, but the shell reads the script from the sandbox-writable working tree. Decision 035 accepts this. U5's step 0.1 text describes the paste's git exposure in detail ("the paste's only git call before install.sh's state gate is `rev-parse`") but not this.

**Recommendation (optional):** Add `&& test "$(git hash-object --no-filters devcontainer-config/install.sh)" = "$(git rev-parse M:devcontainer-config/install.sh)"` before running it. This is untested here, and the git config `hash-object` reads should be checked first.

### Untested bypass candidates

None for the never-line matcher itself (dispositioned under Endorsement Claims). Scope gaps around it are Findings 1, 3 and 4.

## Endorsement Claims

- **Claim:** The committed `docs/dev-cycle.md` reads as policy review (unset), never `workflows/` set and slots 3 through `--settings`.
  **Location:** `docs/dev-cycle.md:7-11`; `test/scripts/build-loop-read.bats:79-81`
  **Evidence:** executed
  **Verified:** `timeout 300 bats -f settings test/scripts/build-loop-read.bats`: 12/12 ok, including test 4 with the U5 assertions.
  **Not verified:** that main's commit after the merge carries the same bytes (the test reads the fixture copy).
- **Claim:** The never glob is matched against the lower-cased path, at the path or any directory above it. A symlink or gitlink is refused by `nrules` before `srules`. Renames appear as delete+add (`--no-renames`), so moving a file out of `workflows/` is matched on its old path. Non-ASCII spellings fail `pathform`.
  **Location:** `scripts/build-loop.sh:1181-1214`, `:1141-1150`, `check_line` (`diff-tree -r --no-renames`, `lower_all`)
  **Evidence:** read-static
  **Verified:** `never_res` regex construction `^$re(/|\$)` over `lower "${g%/}"`. `srules` tests `$3` (from `lps`). `nrules` mode rule `^(000000|100644|100755)`.
  **Not verified:** the `--approved` path, which skips `srules` by design.
  **route: code-fact-check**
- **Claim:** Q-156's commit list equals `git log --first-parent 8d0e660e..main` at b279a2ba, and no subject ends `(build-loop self-merge)`. C is on main's first-parent history, and 28 non-docs paths differ from C to HEAD.
  **Location:** `docs/working/questions.md:458-478`
  **Evidence:** executed
  **Verified:** the listed git commands against `/opt/claude-workflows/.manifest` `commit=8d0e660e…`.
  **Not verified:** the `log_class` class of each commit.
- **Claim:** A list line of the form `- %h %s` does not start with `Q-NNN:` or `**Answer` after the optional `- `, so a subject there is not read as an answer line or a heading.
  **Location:** `scripts/lib/dev-cycle-read.sh:2050-2060` (`ANSWER_AWK` comment and rule)
  **Evidence:** read-static
  **Verified:** the start-of-line rule text and the `heading()` column-0 test.
  **Not verified:** whether the orchestrator writes the line with the hash first, which is prose-only in step 0.1.

## Primitive sweep

```
Primitive: host execution of a checkout script
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `docs/working/questions.md:480` (Q-156 paste) | S5 | HEAD == refs/heads/main (tautology) | Finding 2; Finding 7 |
| `skills/dev-cycle/SKILL.md:303-304` (step 0.1 paste) | S5 | HEAD == fixed M | Finding 7 (pre-existing); cleared otherwise |
| `skills/dev-cycle/SKILL.md:379` (health check from WT, in the sandbox) | S7 | none beyond the floor | Finding 4 |

Primitive: untrusted text interpolated into questions.md (awk/marker-processed file)
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| step 0.1 commit list (`SKILL.md:300-302`) | S3 | none | Finding 5 |
| step 0.1 path list (`SKILL.md:302-303`) | S4 | pathform only for gate merges | Finding 5 |
| `--marker` body quoting (`build-loop.sh:948-1000`, prior art) | S1 | BODY_RULE + FENCE_AWK | cleared: scrubbed |
| Q-156 / Q-149..Q-155 as written in this diff | static text | hand-written | cleared: no `<!--`, CR or column-0 answer shapes in the added text |
```

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Self-merge can land install.sh / host tools; release runs them on the host unreviewed | High | B1, B4, B6 | `docs/dev-cycle.md:11`, `questions.md:101,109` | Medium |
| 2 | Q-156 paste guard is a tautology on main | Medium | B4 | `questions.md:480,484` | High |
| 3 | Never-line rationale covers skills/, patterns/, guides/ too | Medium | B5, B6 | `docs/dev-cycle.md:36-40`, Q-149 | Medium |
| 4 | Health-check backstop is self-mergeable and executes test/** and sourced scripts | Medium | B5, B6 | `questions.md:109`, `SKILL.md:376-386` | High |
| 5 | Step 0.1 copies subjects/paths unscrubbed; index marker truncates | Low | B3 | `SKILL.md:298-303` | Medium |
| 6 | Release flag keys on subject suffix, not class | Informational | B3, B6 | `SKILL.md:301-302` | High |
| 7 | Pastes run the working-tree install.sh (pre-existing) | Informational | B4 | `questions.md:480` | High |

## Overall Assessment

U5 changes no gate code, and with the policy left at `review (interim; Q-103)` none of Findings 1, 3 or 4 is reachable today. They are defects in the configuration and the decision record the user will act on. The never line `workflows/` and Q-103's residual list understate what takes effect on merge. The worst case is `devcontainer-config/install.sh`: under self-merge it can land unreviewed and then run on the host at the next release, before any diff is shown. Q-103's F58 mitigation ("your review of the release is the gate") cannot cover it. Finding 2 is live now: the Q-156 paste the user is asked to run binds nothing, and no fixed-M version can arrive before it is run. All of these can be fixed in place: widen the never line, correct the Q-103 and Q-149 prose, and rewrite Q-156 with the merge SHA. The single most important fix is never-listing `devcontainer-config/` (and saying so in Q-103) before the user answers Q-103. No findings within the other code paths read; endorsement claims marked `route: code-fact-check` are pending execution verification.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to /workspace/.claude/wt-build-loop-u5/docs/reviews/security-review-2026-10-14-u5-i1.md, first line `Commit: 42414307`, structured per the security-reviewer skill.
- Answered: yes. Covers surfaces (a)–(d): never-line adequacy (F1, F3, F4), Q-156 vs the step 0.1 paste (F2, F7), the step 0.1 subject copy (F5, F6), Q-103 completeness (F1, F3, F4, F6).
- Out of scope: the known fact-check items (Claims 12, 18, 25, 26, 28, F37 note), which were not re-reported except where extended. Gate code internals beyond what the settings feed.
- Escalate: F1 and F2 should be fixed before the user answers Q-103 or pastes Q-156.
- Decisions I made: rated F1 High on host-execution impact despite the review interim (alternative: Medium, since it is unreachable until Q-103 [2]). Rated F5 Low because its prerequisite (a free-text commit on main) is already the F19 residual (alternative: Medium under the floor rule).
