Commit: 10c2809 (A) / 875b41f (B)

# Security Review — dev-cycle pass 26 (the pass-25 fix round)

**Scope:** Partial. A: `git diff cbfdf35..10c2809 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` (worktree `/workspace/.claude/wt-digest`). B: `git diff 77e21af..875b41f -- skills/dev-cycle/SKILL.md` (worktree `/workspace/.claude/wt-devcycle`, merge bf5dfac). Everything else is context only.
**Date:** 2026-10-02
**Based on:** the shared brief `digest-pass26-brief-dc1aa358.md`; the Stage-1 context `docs/reviews/code-fact-check-report-digest-pass25.md` (it covers cbfdf35, so every function cited below was re-read in full at 10c2809); the pass-25 security review, for what was already filed.
**Replication:** k=1 (loop pass)

**Probe discipline.** Each probe was one script. Each started with `set -eu`, created its own `mktemp -d -p sec26/` directory in that same script, and checked `case "$PWD"` before any `git init`, commit or write. Code was extracted with `git archive <commit> | tar -x` into the temp dir. Every process ran under `timeout`, and none of mine is still running. The bats processes visible in `pgrep` afterwards belong to another session's full-suite run in wt-devcycle (`install-host.bats`); I did not start or stop them. Apart from this report, nothing was written to `/workspace` or to either worktree. Afterwards, `/workspace` was on `main` and both worktrees showed an empty `git status --short`. Probes ran with `LC_ALL=C.utf8` (the only awk is mawk).

Scratch is under `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/sec26/` (below, `sec26/`):
- `probe1.sh` / `probe1.log`. E1: bats at 10c2809, 41/41 ok, 0 `not ok` (`bats.log`). E2: `hermeticity-lint --root .` clean (`lint.log`). E3: shellcheck clean. E4: `--help` ends on the Exit paragraph. E5: `--check-answer` on all 102 real IDs (875b41f's `questions.md` and `questions-archive.md`) under cbfdf35 and 10c2809 (`ans-old.log`, `ans-new.log`), plus the shape of every real header.
- `probe2.sh` / `probe2.log`: crafted `--check-answer` entries (Q-001 to Q-017), old against new.
- `probe3.sh` / `probe3.log`: `--check-brief` edges, `--check-branch` dates, `--check-fix` names, no default branch, `origin/HEAD` naming a feature branch, per-entry fence balance in the real files.
- `probe4.sh` / `probe4.log`: the `--check-brief` pipe abort by blob size (old against new), and `--check-fix` anchor probes.

Legibility-target values:
- **agent**: the model running the dev-cycle skill acts on the output.
- **user**: the human who answers questions and reads the roadmap.
- **maintainer**: someone editing the script or skill.

---

## Trust Boundary Map

```
B1 (moved): questions files (user answers as recorded, plus text any session writes) → --check-answer awk (header-only ANSWERED gate, in-entry fence skip, line-start label) → keep/drop/done/open → brief Kept:/Applied:/close (SKILL:272-286)
B2 (moved): brief blob on the default branch (written by the cycle, edited by any merged change) → --check-brief awk (first unfenced "Status:" line, must be exact) → Done / Ideas / git mv to closed/ (SKILL:261-271)
B3 (moved): repo-text path (an in-cycle fix target) → --check-fix (denylist incl. $INSTRUCTION_FILE + check_path) → in-cycle edit of a tracked docs/**.md or README.md
B4 (moved): brief's branch (name from repo text; commits from whoever pushes to it) → --check-branch (name form, show-ref, peel, rev-list count, %cs tip date) → "shows no work" → keep-or-drop entry (SKILL:287-296)
B5 (moved): local refs / origin/HEAD (remote-chosen name) → default-branch resolution + new MAIN_BY_NAME gate → MAIN_SHA read by every check mode
B6 (moved): roadmap In flight path + glob + this cycle's writes → slot rule (SKILL:81-85) → Build briefs cap (SKILL:307-309)
```

| Label | Source | Mutability | Trust classification |
|---|---|---|---|
| S1 | questions-file content (working tree) | runtime-mutable (the user, any session, the cycle) | UNTRUSTED toward the close/keep decision. Only the recorded answer of the entry itself, once its header is ANSWERED, should decide. |
| S2 | brief blob on the default branch | runtime-mutable (any merge) | UNTRUSTED toward Done/dropped. Accepted by design as a self-report reviewed at merge. |
| S3 | brief branch's tip commit (committer date) | runtime-mutable (anyone who commits to the branch; the date is set by the committer's clock or `GIT_COMMITTER_DATE`) | UNTRUSTED toward the idle decision. Trusted for nothing else, and only a hash is passed to git. |
| S4 | path named in repo text (fix target) | per cycle | UNTRUSTED toward write sinks |
| S5 | `refs/remotes/origin/HEAD` symbolic target | set at clone, or by `remote set-head` / fetch | Trusted toward picking the default branch: it names the remote's own default. That is a remote-owner choice, which this review takes as trusted. |
| S6 | local refs `main`/`master` | host-local | Trusted |

Untrusted text reaches decision sinks through the questions files (S1) and the brief blob (S2). The branch tip's date (S3) is a new untrusted input to a decision. This round narrows B1's gate to the header line, and that holds on every real entry. But the fence reorder lets one entry's open fence carry the read into the next entry (F1). B2's new fence-aware reader has a mixed-fence bypass (F3) and the same early-exit pipe abort as before (F4).

## Findings

#### F1. An unclosed fence in the target entry swallows the next entry's heading, so the next entry's answer line decides this one

**Severity:** Medium
**Location:** `scripts/dev-cycle.sh:350-353` (10c2809)
**Boundary:** B1
**Move:** 11 (bypass enumeration), 3
**Confidence:** High that the mechanism exists (executed). Likelihood is low: every real entry has balanced fences (`probe3.log`, "per-entry fence balance": no odd entry in either file). It needs an ANSWERED entry with an unbalanced ```` ``` ````/`~~~` line, for example a `you: terminal` paste block whose closing fence was dropped.
**Legibility-target:** agent, user, maintainer

**Evidence (verbatim):**
```awk
# scripts/dev-cycle.sh:350-355
inside && /^(```|~~~)/ { fence = !fence; next }
inside && fence { next }
heading($0) { count++; inside = (count == 1); fence = 0; header = 0; next }
/^(#|##|###) / { inside = 0 }
!inside { next }
!header && /^\*\*Needs:\*\*/ { header = 1; answered = ($0 ~ /\*\*Status:\*\* ANSWERED( |$)/); next }
```
(excerpt; the `!done` answer block :356-369 and `END` :370-373 follow, read)

Once a fence opens inside the target entry, `inside && fence { next }` runs before both `heading()` and the `/^(#|##|###) /` entry end. Nothing then ends the entry until a fence line toggles it back, and that line can be in a later entry. Probe Q-001 (`probe2.log`): Q-001 is ANSWERED and has an unclosed ```` ``` ````. The next entry, Q-002 (OPEN), opens its own fence, and that closes Q-001's. Q-002's `**Answer:** [2] drop` then becomes Q-001's answer:

```
== old            == new
unrecognized Q-001   drop Q-001
```

The cbfdf35 order (heading first) ended the entry at Q-002's heading and read `unrecognized`, which is fail-safe. The new order closes a brief on text the user wrote for a different question. The same swallow hides a real duplicate `### Q-001` heading that follows the open fence, so the `dup` safety skip does not fire. The floor rule applies: the mechanism is concrete, and it is reachable by any session that writes the file. So Medium, with the low likelihood carried in Confidence.

**Recommendation:** End the entry at a line that matches the questions.sh heading grammar (`^### Q-[0-9]+ · `) even when it is inside a fence. Read an entry whose fence is still open at its end as `unrecognized`. That keeps the Q-016 fix: a fenced `### Q-016 · fake` in Q-016's own body is still a fence line, and only a heading that ends the fence region triggers this. Alternatively, track fence state over the whole file (pass-25 F3's recommendation), and treat any open fence at a grammar heading as malformed (`unrecognized`). Add a bats case for the Q-001/Q-002 shape.

#### F2. The header gate is a substring test on the header line, so a header whose Status field is OPEN can still read as ANSWERED

**Severity:** Low
**Location:** `scripts/dev-cycle.sh:355` (10c2809)
**Boundary:** B1
**Move:** 11
**Confidence:** High (executed). It needs a header line that carries a second `**Status:** ANSWERED` token, which is not the questions.sh grammar.
**Legibility-target:** maintainer

**Evidence (verbatim):** `answered = ($0 ~ /\*\*Status:\*\* ANSWERED( |$)/)`. Probe Q-010 has the header `**Needs:** you: judgment · **Opened:** 2026-10-01 · **Status:** OPEN (was **Status:** ANSWERED earlier)`, and it read `drop Q-010`. `questions.sh check` reports the same line as `✗ Q-010: invalid status 'OPEN (was Status: ANSWERED earlier)'`, and `questions.sh archive` does not move it (its status field is not `ANSWERED`). The two readers therefore disagree about whether the entry is answered.

Graded below the floor because the only party who can produce this line is the header's writer, who could set `ANSWERED` directly. The gate protects against early reading by honest recorders, not against an adversary. Lowercase `answered` (Q-011) and a bulleted header (Q-012) now read `open`, which is fail-closed. On all 102 real entries every `**Needs:**` line ends exactly in `**Status:** OPEN` or `**Status:** ANSWERED`, and every entry has exactly one (`probe1.log`).

**Recommendation:** Anchor the test to the field as questions.sh parses it: `/ · \*\*Status:\*\* ANSWERED$/` (after the CR strip).

#### F3. `--check-brief`'s fence toggle treats ```` ``` ```` and `~~~` as one kind, so a `~~~` block quoting a ```` ``` ```` line exposes a quoted `Status: done`

**Severity:** Low
**Location:** `scripts/dev-cycle.sh:262-265` (10c2809); the same toggle at `:350`
**Boundary:** B2 (and B1)
**Move:** 11
**Confidence:** High (executed). It needs quoted text above the brief's real status line. The skill writes `Status: open` first (SKILL:314-315), so the cycle's own briefs do not have this shape unless a merged edit adds text above the status line.
**Legibility-target:** maintainer

**Evidence (verbatim):**
```awk
# scripts/dev-cycle.sh:263-265 (whole awk program)
    { sub(/\r$/, "") }
    /^(```|~~~)/ { fence = !fence; next }
    !fence && /^Status:/ { if ($0 ~ /^Status: (open|done|dropped)$/) print; exit }')"
```
The brief `# b` / `~~~` / ```` ``` ```` / `Status: done` / `~~~` / `Status: open` printed `ok … 2026-10-01-tilde.md done <commit>` (`probe3.log`). The inner ```` ``` ```` closes the `~~~` fence, so the quoted line is read. In CommonMark, only the opening character closes a fence. This is the pass-25 F4 scenario (quoted text above the real line), through the new fence handling. The same mismatch gives `drop Q-013` in `--check-answer` (old and new both). The rating stays at pass-25 F4's Low: a writer of the blob can set the status directly.

The other edges fail closed (executed):
- front matter `Status: draft` gives a skip;
- a trailing space gives a skip;
- an unclosed fence before the status gives a skip;
- CRLF gives `open`.

**Recommendation:** Record the opening character (`fence = substr($0,1,3)`) and close only on a line that starts with the same three characters. Apply the same change in `ANSWER_AWK`.

#### F4. `--check-brief` aborts the whole check run with exit 141 when a brief blob exceeds about 64 KiB

**Severity:** Low
**Location:** `scripts/dev-cycle.sh:262-265` (10c2809); `set -euo pipefail` at `:63`
**Boundary:** B2
**Move:** 3 (error path), 8
**Confidence:** High (executed). It needs a merged brief larger than the pipe buffer.
**Legibility-target:** agent, maintainer

**Evidence (verbatim):** `st="$(git cat-file blob "$MAIN_SHA:$a" | env LC_ALL=C awk '…exit }')"`. The awk `exit` at the first `Status:` line closes the pipe. `git cat-file` then dies of SIGPIPE, `pipefail` makes the assignment fail, and `set -e` ends the script. Results by blob size (`probe4.log`):

| Version | 60 KB | 70 KB | 200 KB |
|---|---|---|---|
| cbfdf35 (`grep -m1`) | rc=0 | rc=0 | rc=141, 0 lines |
| 10c2809 (awk) | rc=0 | rc=141, 0 lines | rc=141, 0 lines |

Every later argument goes unanswered, and nothing is printed for the earlier ones either. The pattern predates this round, but the threshold dropped. The skill records a non-zero exit and stops the step (SKILL:89-90), so In flight stalls every cycle until the brief shrinks. That is fail-closed, so no decision is taken wrongly. The floor rule does not bind, because no security property is violated: this is availability of a bookkeeping step, and the blob's writer controls it.

**Recommendation:** Let awk read to the end (set a flag instead of `exit`, and print in `END`), or drop the early exit. Add a bats case with a blob over 64 KiB.

#### F5. Forged entry inside another entry's fence still reads (pass-25 F3, carried, not fixed)

**Severity:** Low (unchanged)
**Location:** `scripts/dev-cycle.sh:350-353` (10c2809)
**Boundary:** B1
**Move:** 11
**Confidence:** High (executed)
**Legibility-target:** maintainer

**Evidence (verbatim):** probe Q-017. Q-090's body holds a ```` ``` ```` block containing `### Q-017 · forged` / a header with `**Status:** ANSWERED` / `**Answer:** [3]`. With no real Q-017, it printed `done Q-017` under both cbfdf35 and 10c2809. The reorder tracks fences only `inside` the target entry. Fences in other entries are still not tracked, so pass-25 F3's whole-file recommendation was not taken. The preconditions and grade are the same as in pass 25.

**Recommendation:** As pass-25 F3. Whole-file fence tracking also bears on F1's fix.

#### F6. The tip date is committer-supplied: a future-dated tip keeps a branch from ever reading idle

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:286` (10c2809); `skills/dev-cycle/SKILL.md:294-296` (875b41f)
**Boundary:** B4 (S3)
**Move:** 5
**Confidence:** High (executed)
**Legibility-target:** agent

**Evidence (verbatim):**
- Code: `$(git log -1 --format=%cs "$sha")`.
- Skill: "prints a tip date more than 14 days before today (an idle branch, …)".
- Probe output: `ok fut … 1 2099-01-01` (`GIT_COMMITTER_DATE=2099-…`).
- Time zone: a commit at `2026-10-01T23:30-12:00` (2026-10-02 UTC) printed `2026-10-01`, the committer's zone.

A future date is never "more than 14 days before today", so that brief is never asked keep-or-drop. It still holds its slot. This is the same class as pass-25 F5's far-future `Kept:` date. It fails toward keeping a slot, never toward closing a brief. The zone skew is at most one day against a 14-day threshold, which is negligible.

**Recommendation:** In the skill, treat a tip date after today as idle, or as "cannot tell" with a recorded note.

#### F7. The new by-name gate counts `origin/HEAD`, so a remote default that names a local feature branch becomes the check modes' "default branch"

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:393-402`, `:414-416` (10c2809)
**Boundary:** B5 (S5)
**Move:** 5
**Confidence:** High (executed)
**Legibility-target:** maintainer

**Evidence (verbatim):** `[[ -n "$origin_head" ]] && candidates+=("${origin_head#origin/}")` … `MAIN_BY_NAME=1`. With `origin/HEAD → origin/feat` and a local `feat` carrying `Status: done` (`probe3.log`):
- `--check-brief` printed `ok … done` from `feat`;
- `--check-branch feat` printed `skip feat: the default branch`;
- `main` printed `ok main … 0 …`.

The resolution predates this round. The new gate (`:414-416`) now presents it as the one acceptable source. This is benign where the remote's default is the real default, which is the normal case. S5 is trusted per the source table.

**Recommendation:** None required. Optionally, have the digest's Window/header line name the resolved default branch, so a surprise is visible.

#### F8. The single slot rule leaves a skipped brief holding a slot with no question asked; two places still say "open brief"

**Severity:** Informational
**Location:** `skills/dev-cycle/SKILL.md:81-84`, `:160`, `:272`, `:287`, `:337`, `:354` (875b41f)
**Boundary:** B6
**Move:** 5 (invert the model: what does the rule not cover?)
**Confidence:** Medium (read-static, plus the probe showing how little triggers a skip)
**Legibility-target:** agent, user

**Evidence (verbatim):**
- The Rules: "a brief the check skips keeps its slot (recorded) until the cause is fixed".
- In flight 2 and 3 run only "If the brief is still open" / "if the brief is still open".
- The record template reads "`<k>/3 open (3/3: no new briefs)`".
- Step 1 says "Skip any branch or worktree an open brief (found as in the Rules) names".

A trailing space after `Status: open` already gives a skip (`probe3.log`). A skipped brief is not "open" by `--check-brief`, so neither the keep-or-drop question nor the final message's open-brief list reaches it. Only the `## Skipped inputs` line records it. Three such briefs block new briefs indefinitely. This fails closed, since nothing is closed on unreadable state. Step 1's "open brief" might not protect a skipped brief's branch from the merged-branch list, but deletion needs the user's approval anyway.

The slot rule is otherwise consistent at every place the skill counts briefs:
- the Rules :81-85;
- Build briefs :308, "hold a slot (as in the Rules; each counted once)";
- In flight 3, "still holds its slot".

**Recommendation:**
- Put skip-held slots in the final message.
- Use "holds a slot" at :160 and :337 (`<k>/3 slots held`).

#### F9. `--check-fix`'s instruction-file pattern is name-based; `AGENT.md` and skill-loaded procedure docs under `docs/` pass

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:298`, `:305-306` (10c2809)
**Boundary:** B3 (S4)
**Move:** 11
**Confidence:** High (executed)
**Legibility-target:** maintainer

**Evidence (verbatim):** `INSTRUCTION_FILE='^(claude|agents|gemini)(\.[a-z0-9_-]+)?\.md$|^skill\.md$'`.

| Name under `docs/sub/` (`probe3.log`, `probe4.log`) | Result |
|---|---|
| `CLAUDE.md`, `CLAUDE.local.md`, `AGENTS.override.md`, `agents.MD`, `Claude.Local.MD`, `skill.md`, `GEMINI.md`, `claude.v2.md`, `claude.md.md` | skip |
| `AGENT.md` (singular), `copilot-instructions.md`, `CONVENTIONS.md`, `SKILL.local.md`, `evaluation-rubric.md` | ok |

Anchoring is correct per alternative under unquoted `=~ $VAR`: `notclaude.md`, `askill.md`, `agentsx.md` and `gemini-notes.md` are ok, and nothing unanchored leaked. The passes outside `.github/`/dot-directories are not loaded by Claude Code, and `copilot-instructions.md` only loads from `.github/`, which `*/.*` already refuses. The residual class is `docs/*.md` files that skills read as procedure (for example `docs/evaluation-rubric.md` for self-eval). This pattern cannot express that class. Pass 25's F2 (`CLAUDE.local.md`, `AGENTS.override.md`) is fixed.

**Recommendation:** Optionally add `agent` to the alternation. Name the content-role gap in the skill's in-cycle fix rule, or accept it, since such edits land through review.

## Untested bypass candidates

None. Every candidate enumerated for the four guardrails was executed:
- ANSWERED gate: Q-001, Q-010 to Q-016;
- fence handling: Q-001, Q-013, Q-015, Q-016, Q-017;
- `--check-brief` status reader: tilde, front matter, CRLF, trailing space, unclosed fence, 60K/70K/200K blobs;
- `--check-fix` pattern: 14 names plus 5 anchor probes.

## Endorsement Claims

- **Claim:** Over all 102 real entries (875b41f's two questions files), `--check-answer` gives identical output at cbfdf35 and 10c2809 (3 done, 19 drop, 26 keep, 13 open, 41 unrecognized). Every real entry has exactly one `**Needs:**` line, ending in `**Status:** OPEN` or `**Status:** ANSWERED`.
  **Location:** `scripts/dev-cycle.sh:349-373`
  **Evidence:** executed
  **Verified:** `probe1.sh` E5: `diff ans-old.log ans-new.log` is empty; awk counts of Needs lines per entry; grep for Needs lines without a final Status field returned none.
  **Not verified:** entries in `/workspace` main's questions files if they differ from 875b41f's, and entries written after 875b41f.
  **route: code-fact-check**
- **Claim:** In a repo with no `origin/HEAD`, `main` or `master`, every check mode exits 1 with a stderr reason before reading anything, while the digest still runs (rc 0).
  **Location:** `scripts/dev-cycle.sh:414-416`
  **Evidence:** executed
  **Verified:** `probe3.log`: a `trunk`-only repo printed `--check-path needs a default branch (origin/HEAD, main or master); found none`, `check rc=1`, `digest rc=0`. Bats test 41 passes.
  **Not verified:** check modes other than `--check-path` in that repo; they share the same gate line, ahead of the dispatch loop.
  **route: code-fact-check**
- **Claim:** `$INSTRUCTION_FILE`'s two alternatives are each anchored at both ends when expanded unquoted on the right of `=~`.
  **Location:** `scripts/dev-cycle.sh:298`, `:306`
  **Evidence:** executed
  **Verified:** `probe3.log` and `probe4.log`: 19 names, including the prefix and suffix probes `notclaude.md`, `askill.md`, `agentsx.md` and `gemini-notes.md`.
  **Not verified:** bash versions other than the container's.
  **route: code-fact-check**
- **Claim:** The A gates hold at 10c2809: bats 41/41, `hermeticity-lint --root .` reports no unstubbed network spawns, and shellcheck is clean.
  **Location:** `test/scripts/dev-cycle.bats`, `scripts/dev-cycle.sh`
  **Evidence:** executed
  **Verified:** `bats.log`, `lint.log`, `probe1.log` E3 (an archive of 10c2809 in its own temp repo).
  **Not verified:** the full repo suite.
  **route: code-fact-check**
- **Claim:** `--check-brief` prints a skip when the first unfenced `Status:` line is not exact. Executed cases: a trailing space, front matter `Status: draft`, and an unclosed fence.
  **Location:** `scripts/dev-cycle.sh:262-268`
  **Evidence:** executed
  **Verified:** `probe3.log`, three skip lines.
  **Not verified:** mixed fence characters; see F3, where the guard is bypassed.
- **Claim:** The skill's uniqueness rule now also requires "no file exists at the path yet", which covers the pass-25 F7 same-cycle and gitignored-`docs/working/` cases at the text level.
  **Location:** `skills/dev-cycle/SKILL.md:310-314`
  **Evidence:** read-static
  **Verified:** the sentence at :312-314.
  **Not verified:** how the agent tests existence (no check mode does it), and the `--check-write` step that follows.
- **Claim:** The 14-day idle rule asks about a slow but active branch at most once per 14 days. `Kept:` resets the clock, and step 3 waits while an `Asked:` ID is still `open` or skipped.
  **Location:** `skills/dev-cycle/SKILL.md:287-296`
  **Evidence:** read-static
  **Verified:** In flight 3's preconditions as written.
  **Not verified:** that the agent writes `Kept:` on every `keep` (In flight 2, :280).

## Primitive sweep

Primitive: process exec (`git` argv) on values from repo text or refs, in the changed lines

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/dev-cycle.sh:262` `git cat-file blob "$MAIN_SHA:$a"` | S2 path (repo text) | `pathform` + `isbrief` + `blocker`, hash prefix | cleared: argv only, and the path cannot start with `-`; F4 is the error path |
| `scripts/dev-cycle.sh:266` `git log -1 --format=%H "$MAIN_SHA" -- "$a"` | S2 path | same, after `--` | cleared |
| `scripts/dev-cycle.sh:286` `git rev-list --count "$MAIN_SHA..$sha"` and `git log -1 --format=%cs "$sha"` | S3 (hash from show-ref, peeled) | hash only | cleared; F6 covers the date's meaning |
| `scripts/dev-cycle.sh:380` `awk -v id="$a" "$ANSWER_AWK" "$f"` | S1 file, ID | ID `^Q-[0-9]+$`, constant program | cleared: `-v` escape processing is moot for that charset; F1, F2 and F5 are logic findings |

No eval, deserialization, SQL or HTML sinks in scope.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| F1 | Unclosed fence swallows next entry's heading; its answer decides this entry (regression) | Medium | B1 | `scripts/dev-cycle.sh:350-353` | High (likelihood low) |
| F2 | Header gate is a substring test; `OPEN (was **Status:** ANSWERED)` reads answered | Low | B1 | `scripts/dev-cycle.sh:355` | High |
| F3 | Mixed ``` / ~~~ fence toggle exposes a quoted `Status: done` | Low | B2, B1 | `scripts/dev-cycle.sh:264`, `:350` | High |
| F4 | `--check-brief` pipe abort (rc 141, no output) above ~64 KiB; threshold dropped | Low | B2 | `scripts/dev-cycle.sh:262-265` | High |
| F5 | Forged entry in another entry's fence still reads (pass-25 F3, carried) | Low | B1 | `scripts/dev-cycle.sh:350-353` | High |
| F6 | Committer-supplied tip date; future date is never idle | Informational | B4 | `scripts/dev-cycle.sh:286`; SKILL:294-296 | High |
| F7 | By-name gate includes remote-chosen `origin/HEAD` | Informational | B5 | `scripts/dev-cycle.sh:393-402`, `:414-416` | High |
| F8 | Skipped brief holds a slot unasked; "open brief" wording at :160, :337 | Informational | B6 | SKILL:81-84, :160, :337 | Medium |
| F9 | Instruction-file pattern is name-only (`AGENT.md`, procedure docs pass) | Informational | B3 | `scripts/dev-cycle.sh:298` | High |

## Overall Assessment

The round's targeted fixes hold:
- The header-only ANSWERED gate changes no reading on any of the 102 real entries, and it closes pass-25 F1's any-line substring.
- The instruction-file pattern closes pass-25 F2 with correct anchoring.
- The brief reader closes pass-25 F4's plain case.
- The no-default-branch exit closes pass-25 F6 fail-closed.
- The skill's slot rule is now stated once and used consistently where briefs are counted.

The one new issue worth fixing before the clean pass is F1. Moving the fence test ahead of the heading test made an unclosed fence in the target entry carry the read into the following entries. The fail-safe `unrecognized` of cbfdf35 becomes a `drop` taken from another question's answer. It is fixable in place: end the entry at a grammar heading regardless of fence, and read an unterminated fence as `unrecognized`. F2 to F4 are small, in-place hardening items: anchor the Status field, match fence characters, don't `exit` awk ahead of a producer under `pipefail`. F5 is pass-25 F3 still open. Nothing here is architectural. No findings beyond these within the code paths read; the endorsement claims are pending execution verification.

## Goal-Alignment Note

Success criterion (verbatim): "a markdown report saved at the path your role instructions give, structured per your skill file."

This report is saved at `/workspace/.claude/wt-digest/docs/reviews/security-review-2026-10-02-digest-pass26.md`, and its first line is `Commit: 10c2809 (A) / 875b41f (B)`. It follows the security-reviewer structure: header, Trust Boundary Map with an S-table, Findings, Untested bypass candidates, Endorsement Claims with `route: code-fact-check`, Primitive sweep, Summary Table, Overall Assessment. Every finding carries Severity, Location, Evidence (verbatim), Confidence and Legibility-target. The brief's attack list was covered:
- header-only ANSWERED gate (F1, F2, endorsement 1);
- fence reorder (F1, F5);
- brief status reader (F3, F4);
- tip-date field and its zone (F6);
- no-default-branch exit (endorsement 2, F7);
- widened instruction-file pattern (F9, endorsement 3);
- the single slot rule (F8, endorsement 7).

Nothing was committed.
