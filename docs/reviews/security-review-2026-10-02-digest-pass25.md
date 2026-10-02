Commit: cbfdf35 (A) / 77e21af (B)

# Security Review — dev-cycle pass 25 (the pass-24 fix round)

**Scope:** Partial. A: `git diff c1d0a80..cbfdf35 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` (worktree `/workspace/.claude/wt-digest`). B: `git diff fb643e2..77e21af -- skills/dev-cycle/SKILL.md` (worktree `/workspace/.claude/wt-devcycle`, merge 60fb513). Everything else is context only.
**Date:** 2026-10-02
**Based on:** the shared brief `digest-pass25-brief-dc1aa358.md`, the Stage-1 context `docs/reviews/code-fact-check-report-digest-pass24.md` (it covers c1d0a80, so every function cited below was re-read in full at cbfdf35), and the pass-24 security review (`security-review-2026-10-02-digest-pass24.md`) for what was already filed.
**Replication:** k=1 (loop pass)

**Probe discipline.** Every probe was one script. Each started with `set -eu`, created its own `mktemp -d -p sec25/` directory in that same script, and checked `case "$PWD"` before any `git init`, commit or write. Every process ran under `timeout`, and none of mine is still running. The bats processes visible afterwards in `pgrep` belong to another session's full-suite run in wt-devcycle; I did not start or stop them. The code under review was extracted with `git -C <worktree> archive <commit> | tar -x` into the temp directory. Apart from this report, nothing was written to `/workspace` or to either worktree. Afterwards, `/workspace` was on `main` and both worktrees showed a clean `git status --short`. The probes ran with `LC_ALL=C.utf8`, and the only awk was mawk 1.3.4.

Scratch is under `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/sec25/` (below, `sec25/`):
- `probe1.sh` / `probe1.log` (E1–E4). E1: bats at cbfdf35, 39/39 ok (`bats.log`). E2: shellcheck clean. E3: `--help`. E4: `--check-answer` on all 102 real IDs (77e21af's `docs/working/questions.md` and `questions-archive.md`), under c1d0a80 and cbfdf35 (`ans-old.log`, `ans-new.log`).
- `probe2.sh` / `probe2.log`: crafted `--check-answer` entries G1–G11, and `--check-fix` bypass candidates.
- `probe3.sh` / `probe3.log`: `--check-brief` and `--check-branch` edges H1–H6.

Legibility-target values:
- **agent**: the model running the dev-cycle skill acts on the output.
- **user**: the human who answers questions and reads the roadmap.
- **maintainer**: someone editing the script or skill.

---

## Trust Boundary Map

```
B1 (moved): questions files (user answers as recorded by an agent, plus text any session writes) → --check-answer awk (ANSWERED gate, line-start label) → keep/drop/done/open → brief Kept:/Applied:/close (SKILL:266-277)
B2 (moved): brief file blob on the default branch (written by the cycle, edited by any merged build session) → --check-brief (git cat-file MAIN_SHA:path, first exact Status line) → Done / Ideas / git mv to closed/ (SKILL:257-265)
B3 (moved): repo-text path (a step 1/3/4 finding) → --check-fix (denylist + check_path) → in-cycle edit of a tracked docs/**.md or README.md
B4 (moved): brief's branch name (repo text) → --check-branch (name form, show-ref, peel, rev-list count on hashes) → "shows no work" → keep-or-drop entry (SKILL:278-286)
B5:         roadmap In-flight brief path → --check-brief + --check-path (source), --check-write (destination) → mkdir closed/ + git mv
```

| Label | Source | Mutability | Trust classification |
|---|---|---|---|
| S1 | questions-file content (`questions.md`, `questions-archive.md`, working tree) | runtime-mutable (the user, any session, the cycle) | UNTRUSTED toward the close/keep decision sink. Only the recorded user answer of an entry that is actually ANSWERED should decide. |
| S2 | brief blob on the default branch (`Status:` line) | runtime-mutable (any merge to the default branch, including the build session) | UNTRUSTED toward Done/dropped. Accepted by design as the build session's self-report, reviewed at its merge. |
| S3 | brief `Asked:`/`Applied:`/`Kept:` lines (working tree) | runtime-mutable | UNTRUSTED. IDs are validated to `^Q-[0-9]+$` before awk; dates are not validated by any check. |
| S4 | path named in repo text (fix target) | per cycle | UNTRUSTED toward write sinks |
| S5 | brief's branch name | runtime-mutable | UNTRUSTED toward git argv and ref lookup |
| S6 | local refs, `MAIN_SHA` resolution | host-local | Trusted. Crafting them needs host control. |

Untrusted text reaches decision sinks through two files: the questions files (S1) and the briefs (S2/S3). This round moves the brief's state into code that reads only the default branch's blob (B2). It gates answers on the entry's ANSWERED status (B1). The cycle no longer passes a branch to git itself (B4). B1's new gate is the weak point: it is a substring test on any line of the entry, not a read of the entry's own status field.

## Findings

#### F1. The ANSWERED gate matches `**Status:** answered` anywhere on any line of the entry, so an OPEN entry is read as answered

**Severity:** Medium
**Location:** `scripts/dev-cycle.sh:333` (cbfdf35); the gate's comment is at `:296-297`
**Boundary:** B1
**Move:** 11 (guardrail bypasses), 2 (implicit sanitization)
**Confidence:** High that the mechanism works (executed). Low to Medium that real text triggers it. It needs an OPEN keep-or-drop entry that has both a line mentioning the status marker and a line-start answer label or `Q-NNN:` line. No real entry has that today (E4).
**Legibility-target:** agent, maintainer

**Evidence (verbatim):**
```awk
# scripts/dev-cycle.sh:330-335
!inside { next }
/^(```|~~~)/ { fence = !fence; next }
fence { next }
tolower($0) ~ /\*\*status:\*\* *answered/ { answered = 1 }
!done {
  line = $0; sub(/^- /, "", line)
```
(excerpt ends inside the `!done` block, which runs to `:347`; `END` at `:348-351` prints `open` only when `!answered` — read)

The comment says "An entry whose "**Status:**" is not ANSWERED is open, whatever it contains". The code instead sets `answered` from any non-fenced line in the entry that contains the marker as a substring: a blockquote, a table cell, an Interim line, or `answered-pending`. `sec25/probe2.log`, all four entries with header `**Status:** OPEN`:
- G1: `- **Interim:** keep. When the user replies, record it and set **Status:** ANSWERED.` followed by `**Answered later by the user:** [2]` → `drop Q-1`
- G2: `> **Status:** ANSWERED` (a quoted earlier version) followed by `**Answer (agent interim):** [2]` → `drop Q-2`
- G4: `Q-4: [2] is the interim; **Status:** answered-pending` → `drop Q-4`
- G11: `| state | **Status:** ANSWERED |` followed by `**Answer:** [2]` → `drop Q-11`

The commit message for cbfdf35 says "Quoted earlier answers, blockquotes, … table rows … now read open or unrecognized". That holds for the answer label but not for the status marker. A quote or table that carries the marker still opens the gate.

Impact: In flight 2 applies the reading once. It closes the brief to Ideas (drop) or to Done (done), and puts the ID on `Applied:` (SKILL:271-275). So the user's decision is made without the user. The change is recoverable through git, and the roadmap diff shows it. Writers of `questions.md` gain no capability from this, because they could edit the entry directly. The property that breaks is the one this round added: "read only after it has been recorded".

**Recommendation:** Read the status only from the entry's header field: the first non-blank line after the heading, matching `(^|· )\*\*Status:\*\* ANSWERED( |$)`. Ignore the marker on any other line. Add G2 and G11 to the "reads nothing from an entry not marked ANSWERED" test.

#### F2. `--check-fix`'s instruction-file denylist misses `CLAUDE.local.md` and `AGENTS.override.md`

**Severity:** Medium
**Location:** `scripts/dev-cycle.sh:286-289` (cbfdf35); rule text `skills/dev-cycle/SKILL.md:72-76` (77e21af)
**Boundary:** B3
**Move:** 11
**Confidence:** Low. The gate's `ok` is executed. Whether a tool loads either file from a subdirectory of `docs/` is not verified here (see Untested bypass candidates), and it needs such a file to be tracked under `docs/`. This repo has none.
**Legibility-target:** agent, maintainer

**Evidence (verbatim):**
```bash
# scripts/dev-cycle.sh:286-289
  base="${a##*/}"; low="$(printf '%s' "$base" | tr 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' 'abcdefghijklmnopqrstuvwxyz')"
  if writable "$a"; then echo "skip $a: one of the cycle's own files (use --check-write)"
  elif [[ ! "$a" =~ ^docs/.*\.md$|^README\.md$ || "$a" =~ ^docs/(working|human-author|reviews|decisions)/ \
    || "$a" == docs/dev-cycle.md || "$a" == */.* || "$low" =~ ^(claude|agents|gemini|skill)\.md$ ]]; then
```
(excerpt ends :289; enclosing `check_fix()` ends :292 — read)

`sec25/probe2.log` (all tracked):
- `ok docs/CLAUDE.local.md`
- `ok docs/a/AGENTS.override.md`
- `ok docs/copilot-instructions.md` and `ok docs/a/x.instructions.md`. These are inert outside `.github/`, which a dot-directory refusal already covers.

`CLAUDE.local.md` is Claude Code's personal-instructions file. `AGENTS.override.md` is Codex's per-directory override of `AGENTS.md`. Both are instruction files under the skill's "instruction files … filed, not written". The pass-24 F3 mechanism therefore survives for these two names: a repo-text-chosen in-cycle fix writes into a file that later sessions load as instructions.

The parts of the fix that work, all executed:
- The four named basenames are refused in any case (`docs/a/claude.md`, `Claude.MD`, `GEMINI.md`, `skill.md`). `tr` is complete here because `pathform` admits ASCII only.
- `*/.*` inside `[[ == ]]` is a pattern match in which `*` crosses `/`. Since `pathform` already refuses `.` and `..` components, it refuses exactly the paths with a dot-component after a slash: `docs/.x/y.md` and `docs/b/.hidden.md` are refused.

**Recommendation:** Widen the basename test to `^(claude|agents|gemini)(\.[a-z0-9_-]+)?\.md$|^skill\.md$`, which covers `.local` and `.override`. Add both names to the bats refusal list.

#### F3. A forged entry inside another entry's fence is read when the real entry is absent, and now it can read `done`

**Severity:** Low
**Location:** `scripts/dev-cycle.sh:322-332` (cbfdf35)
**Boundary:** B1
**Move:** 11
**Confidence:** High (executed). It needs an `Asked:` ID whose real entry does not exist and a fenced copy of a heading with that ID somewhere in either file.
**Legibility-target:** maintainer

**Evidence (verbatim):**
```awk
# scripts/dev-cycle.sh:328-332
heading($0) { count++; inside = (count == 1); fence = 0; next }
/^(#|##|###) / { inside = 0 }
!inside { next }
/^(```|~~~)/ { fence = !fence; next }
fence { next }
```
The heading test runs before fence state is consulted, and fence state is tracked only inside the target entry. A ```` ``` ```` block in entry Q-90 that holds `### Q-7 · …` / `**Status:** ANSWERED` / `**Answer:** [3]` printed `done Q-7` when no real Q-7 exists (G7). With a real entry present, it is a `dup` skip (G8 → `skip Q-8: more than one entry …`), so a real decision is never overridden.

An `Asked:` ID with no entry is reachable. The fact-check's Claim 20 residue is one route: step 3 writes `Asked:`, but the entry is never filed. Such an ID is re-read every cycle, because a skip stays off `Applied:`. The rating is Low because it needs the exact ID in a fenced example and gives a writer of the file nothing they could not do directly. This is the integrity half of pass-24 F4, which was graded on its availability half only.

**Recommendation:** Track fence state across the whole file, not just inside the entry, and test `heading()` only outside a fence.

#### F4. `--check-brief` takes the first exact `Status:` line anywhere in the blob, so quoted text above the real line decides

**Severity:** Low
**Location:** `scripts/dev-cycle.sh:255` (cbfdf35); brief contents `skills/dev-cycle/SKILL.md:300-307` (77e21af)
**Boundary:** B2
**Move:** 2
**Confidence:** High (executed). It needs the cycle to place repo-quoted text (a plan or record excerpt containing a bare `Status: done` line) above the brief's own status line. The skill lists the status first but does not require it to be first.
**Legibility-target:** agent, maintainer

**Evidence (verbatim):**
```bash
# scripts/dev-cycle.sh:255
  st="$(git cat-file blob "$MAIN_SHA:$a" | { env LC_ALL=C grep -m1 -E '^Status: (open|done|dropped)$' || true; })"
```
(excerpt ends :255; enclosing `check_brief()` ends :259 — read)

H1 (`sec25/probe3.log`): a brief whose goal quotes a fenced `Status: done` above its real `Status: open` printed `ok … done <commit>`. That reading sends In flight 1 to Done and moves the brief to `closed/`. The build session can set `done` anyway (by design, reviewed at merge), so a build session gains nothing from this. The risk is the cycle's own quoting.

**Recommendation:** In the skill, say the status line is the brief's first line after its title. In the script, let only the first line that starts with `Status:` decide (skip it if it is not exact), and ignore fenced lines.

#### F5. `dropped` is attributed to the user, but any merge can set it, and `Asked:`/`Applied:`/`Kept:` are read from the working tree

**Severity:** Informational
**Location:** `skills/dev-cycle/SKILL.md:258-260`, `:266-286` (77e21af)
**Boundary:** B2, B3 (S3)
**Move:** 5
**Confidence:** High (H5 executed; the rest read-static)
**Legibility-target:** agent, user

**Evidence (verbatim):** "It prints `dropped` (the user set it), or keep-or-drop below says drop → Ideas, with the reason". In H5, a commit by `build-bot` setting `Status: dropped` printed `ok … dropped <commit>`, and nothing checks who made it. The Done and dropped signals are the same kind of self-report that pass-24 F2 accepted for `done`.

Separately, the keep-or-drop timer reads the brief's `Kept:` date from the working tree, and no check validates it. So a merged edit to a far-future `Kept:` keeps the brief from ever being asked. A merged `Applied:` edit suppresses answers. Both need a reviewed merge, and both fail safe for data: the brief holds its slot.

**Recommendation:** Reword "(the user set it)" to "(set in a merged change; the record names the commit's author)". Optionally, have `--check-brief` also print a `Kept:` date that it validates.

#### F6. In a repo with no `main`/`master`/`origin/HEAD`, step 6 runs on the cycle branch, which then stands in for the default branch

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:382-388`, `:270` (cbfdf35)
**Boundary:** B2, B4 (S6)
**Move:** 5
**Confidence:** High (H4 executed)
**Legibility-target:** maintainer

**Evidence (verbatim):** `MAIN="$cur"; MAIN_SHA="$(git rev-parse --verify --quiet HEAD 2>/dev/null || true)"`. In H4 (only branch `trunk`, then `chore/dev-cycle-2026-10-02` checked out with this cycle's commits), `--check-brief` read the cycle branch:
- a brief this cycle wrote printed `open`, not `new`;
- a brief the cycle had just edited printed `dropped`;
- `--check-branch` printed `ok trunk … 0` (the real default branch was not refused) and `ok chore/dev-cycle-2026-10-02 … 0`.

The skill's "on the default branch" therefore does not hold there. The failure direction is benign: no work shows, so the brief goes to keep-or-drop.

**Recommendation:** Resolve the default branch once at step 0 and pass its hash to the check modes, or have the skill note this limit.

#### F7. Name uniqueness accepts a name already used by a brief written this cycle (or by any brief, where `docs/working/` is ignored)

**Severity:** Informational (correctness on a security-adjacent path)
**Location:** `skills/dev-cycle/SKILL.md:300-303` (77e21af)
**Boundary:** B5
**Move:** 3
**Confidence:** High (H6 executed)
**Legibility-target:** agent

**Evidence (verbatim):** "`--check-brief` prints `new` for it and `--check-path` on the same name under `closed/` prints a skip". A brief written earlier in the same cycle printed `ok … new`, and the `closed/` lookup printed `skip … no tracked file`. Where `docs/working/` is gitignored, every open brief prints `new`. `--check-write` then approves overwriting it. Same-day, same-slug collisions are the precondition.

**Recommendation:** Also require `--check-path` on the name under `briefs/` to print a skip.

## Untested bypass candidates

- **Claude Code loading `docs/**/CLAUDE.local.md`, and Codex loading `docs/**/AGENTS.override.md`.** These set F2's reach. Not tested: no egress, and neither tool runs here.
- **gawk behaviour** of `tolower`, the octal dash escapes and byte `substr` under `LC_ALL=C` (`:309-316`). Only mawk is installed.
- **`--check-branch` on a case-insensitive filesystem** (`Main` resolving to `main`'s loose ref). Carried from pass 24; no such filesystem here.

## Endorsement Claims

- **Claim:** On the 102 real IDs, cbfdf35 differs from c1d0a80 only on Q-070/071/073 (keep → unrecognized) and Q-019/037/085 (unrecognized → done). Every one of the 13 `open` readings belongs to a non-ANSWERED entry.
  **Location:** `scripts/dev-cycle.sh:307-351`
  **Evidence:** executed
  **Verified:** E4 `diff sec25/ans-old.log sec25/ans-new.log` (exactly those 6 lines). New counts: 26 keep / 19 drop / 3 done / 13 open / 41 unrecognized. A Python pass over the entries joined each keep/drop/done reading to its first line-start label; each reading matches that line's leading token.
  **Not verified:** entries written after 77e21af. A keep/drop/done reading on a non-keep-or-drop entry (for example, Q-019's `[3]`) is not semantically checked, because the skill queries only `Asked:` IDs.
  **route: code-fact-check**
- **Claim:** `--check-brief` reads the status from the default branch's blob, not the working tree, and prints `new` when the blob is absent.
  **Location:** `scripts/dev-cycle.sh:249-259`
  **Evidence:** executed
  **Verified:** the bats test "--check-brief reads the status line from the default branch only" passes (E1 39/39). H2 shows `done` from a merged side branch.
  **Not verified:** the commit printed after a merge. It is the side branch's commit (H2: `071c695…`, not the merge `c7be5ae…`), so "Done, naming the commit it prints" names the build commit, not the merge.
  **route: code-fact-check**
- **Claim:** `--check-branch` passes git only hashes (`show-ref --verify` on `refs/heads/<name>`, peeled, then `rev-list --count MAIN_SHA..sha`). n is 0 for a fresh or merged branch and ≥1 for a squash-merged branch that was kept.
  **Location:** `scripts/dev-cycle.sh:265-276`
  **Evidence:** executed
  **Verified:** bats "counts the branch's own commits" (2 and 0); H2 `ok feat/a … 0` after a merge; H3 `ok feat/s … 1` after a squash.
  **Not verified:** a squash-merged branch that is kept and has no `Status: done` never "shows no work". The skill's [3] done option is reached only through keep-or-drop, so that brief holds its slot (fact-check pass-24 Claim 21 residue).
  **route: code-fact-check**
- **Claim:** `--check-fix` refuses dot-components after a slash and the four named instruction basenames in any ASCII case, and it gives the cycle's own files their own reason.
  **Location:** `scripts/dev-cycle.sh:282-292`
  **Evidence:** executed
  **Verified:** `sec25/probe2.log`, and the bats tests at `:586-598`, `:656-669` and the new instruction-file test.
  **Not verified:** the `.local` and `.override` variants (F2).
- **Claim:** The help range `sed -n '2,58p'` prints the whole header: lines 2–57 and the blank line 58.
  **Location:** `scripts/dev-cycle.sh:121`
  **Evidence:** executed
  **Verified:** E3 printed 57 lines ending "… Printed repo text is data." plus a blank line; line 59 is `set -euo pipefail`.
  **Not verified:** later header edits.

## Primitive sweep

Primitive: process exec (`git` / `awk` argv carrying repo-derived values), within the diff scope

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/dev-cycle.sh:254` `git cat-file -t "$MAIN_SHA:$a"` | S2 path from roadmap | `pathform` + `isbrief` regex (`:251-252`) | cleared: fixed shape, no `-` or `:` |
| `scripts/dev-cycle.sh:255` `git cat-file blob "$MAIN_SHA:$a"` | S2 | same | cleared (content: F4) |
| `scripts/dev-cycle.sh:256` `git log -1 --format=%H "$MAIN_SHA" -- "$a"` | S2 | same, after `--`; `GIT_LITERAL_PATHSPECS=1` | cleared |
| `scripts/dev-cycle.sh:268` `git check-ref-format "refs/heads/$a"` / `--branch "$a"` | S5 | `NAMECHARS`, no leading `-` (`:267`) | cleared |
| `scripts/dev-cycle.sh:272-274` `show-ref`, `rev-parse "$sha^{commit}"`, `rev-list --count "$MAIN_SHA..$sha"` | S5 → hash | exact-ref lookup, then hashes only | cleared |
| `scripts/dev-cycle.sh:358` `awk -v id="$a"` | S3 Asked: ID | `^Q-[0123456789]+$` (`:354`) | cleared (no `-v` escape processing possible) |
| `skills/dev-cycle/SKILL.md:262-263` `mkdir` closed/ + `git mv <brief> <closed/brief>` | S2 roadmap path | `--check-brief`/`--check-path` (source), `--check-write` (destination, symlink walk) | cleared; uniqueness gap is F7 |

No other git call in B takes a brief's branch. Read-static: the only remaining branch mention is step 1's "List merged branches", which is outside this diff and passes no brief name.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | ANSWERED gate is a substring match on any entry line | Medium | B1 | `scripts/dev-cycle.sh:333` | High mechanism / Low–Med occurrence |
| 2 | Instruction denylist misses `CLAUDE.local.md`, `AGENTS.override.md` | Medium | B3 | `scripts/dev-cycle.sh:286-289` | Low |
| 3 | Fenced forged entry read when real entry is absent (now `done` too) | Low | B1 | `scripts/dev-cycle.sh:328-332` | High |
| 4 | First exact `Status:` line anywhere decides; quoted text above wins | Low | B2 | `scripts/dev-cycle.sh:255` | High |
| 5 | `dropped` attributed to the user; S3 lines unvalidated | Informational | B2, B3 | `SKILL.md:258-286` | High |
| 6 | No-main repo: cycle branch stands in for default at step 6 | Informational | B2, B4 | `scripts/dev-cycle.sh:382-388` | High |
| 7 | Name uniqueness accepts a same-cycle (or ignored-dir) brief name | Informational | B5 | `SKILL.md:300-303` | High |

## Overall Assessment

The round moves the remaining prose-only decisions into checks, and the moves are sound in shape:
- the brief's state comes from the default branch's blob;
- the branch count is computed on hashes;
- the cycle no longer passes a branch to git;
- `closed/` is created before the move;
- the fix gate refuses dot-directories and the four named instruction files.

Two guardrails added this round have a concrete bypass. The most important one is F1. The ANSWERED gate, which is the round's main defence against reading a non-answer, is an unanchored substring test, so any quoted, tabled or prose mention of `**Status:** ANSWERED` in an OPEN entry turns the gate on. It is a one-line fix in place: read the status field from the header line only. F2 is a two-name widening of a regex. F3 and F4 are Low, fail-closed-adjacent, and fixable in place. Nothing indicates an architectural problem. No findings were found within the other code paths read. The endorsement claims are pending execution verification.

## Goal-Alignment Note

- Success criterion (restated verbatim): a markdown report saved at the path your role instructions give, structured per your skill file.

This report is saved at `/workspace/.claude/wt-digest/docs/reviews/security-review-2026-10-02-digest-pass25.md`, with first line `Commit: cbfdf35 (A) / 77e21af (B)`. It has the skill's sections: header, trust boundary map with source table, findings anchored to boundaries, untested bypass candidates, endorsement claims with Verified/Not-verified pairs and `route: code-fact-check` tags, primitive sweep, summary table and overall assessment. Each finding carries Severity, Location, Evidence (verbatim), Confidence and Legibility-target. It is not committed.

Against the brief's claims to check:
- **A, `--check-answer`.** The real-file delta is exactly as claimed (6 IDs), with no wrong keep, drop or done among the 102. Non-answer lines can still be read through the gate (F1) and through fenced forged entries (F3). An agent's line-start `**Answered (…)**` note that precedes the user's line is read first (probe G3: `drop` where the user wrote `[1]`). That needs the agent to record its own note with the answer label, so it is a variant of F1's class and is not filed separately.
- **A, `--check-brief`.** The reads come from `MAIN_SHA` only. Before its own briefs land, a brief reads `new`, which counts toward the slot cap with `--check-path ok`. The `git log -1 -- path` cost is one history walk per brief and correct for an unmoved path. The brief is never queried after `git mv`, because `isbrief` refuses `closed/`. The commit printed after a merge is the side commit (Endorsement 2). F4 and F6 are its edges.
- **A, `--check-branch`.** Merged → 0, squash-merged and kept → ≥1. The refusal applies only when the default was found by name (F6).
- **A, `--check-fix`.** The `*/.*` and case handling are correct and complete for what they name. The denylist misses two names (F2).
- **A, help range and commit.** `2,58p` is correct; 39/39; shellcheck clean.
- **B, lifecycle.** new → open → done/dropped → `closed/` is consistent with what each check prints. Gaps: F5, F6, F7. The `[3] done` option matches the reader's `[3]`/`3`/`done`. The only git commands with brief-derived values are `git mv` (validated paths) and staging.
