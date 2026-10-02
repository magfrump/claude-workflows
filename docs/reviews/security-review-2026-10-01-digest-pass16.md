Commit: 09f6fe7 (A) / 5423a33 (B)

# Security Review — dev-cycle loop pass 16 (pass-15 fix round)

**Scope:** Partial. A: `git diff f47de85..09f6fe7 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` (worktree `/workspace/.claude/wt-digest`). B: `git diff cb2e5f9..5423a33 -- skills/dev-cycle/SKILL.md` (worktree `/workspace/.claude/wt-devcycle`). Everything else on both branches is context only.
**Date:** 2026-10-01
**Based on:** `docs/reviews/code-fact-check-report-digest-pass15.md` (loop pass 15, k=1; it verdicts f47de85 / cb2e5f9, the parents of this round, so it is context for what this round fixes, not a check of it).
**Replication:** k=1 (loop pass)

Execution (scratch, not committed) under `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/sec16/`:
- `bats.log`: `timeout 600 bats test/scripts/dev-cycle.bats`, cwd `/workspace/.claude/wt-digest` (HEAD 6d4000d; `git diff --stat 09f6fe7 HEAD -- scripts test` is empty), exit 0, 23/23 ok.
- `probe.log` (script `sec16/probe.sh`): `timeout 300 ./probe.sh`, exit 0. Every repo under one `mktemp -d`, removed on exit; `$HOME` pointed at an empty directory; the 09f6fe7 script run once from a directory holding the 09f6fe7 `questions.sh` and once from a directory without it. Cases C1–C9 below; files outside each repo hold the marker strings `SECRET-OUTSIDE` / `SECRET-ARCH`.

Legibility-target values: **agent** (the model running the skill or reading the digest), **maintainer** (someone editing the script or skill), **user** (the human reading the digest, record or roadmap).

## Trust Boundary Map

```
B1: [repo tree: docs/, docs/working/, questions.md, questions-archive.md] → [blocker()/skipped()/inrepo() walk, dev-cycle.sh:250-258] → [questions.sh open (reads both files)]
B2: [questions.sh stdout/stderr (derived from repo text)]                 → [awk column filter + ``` fence + scrub()]   → [digest section 3 read by the cycle agent]
B3: [questions.md / questions-archive.md entries (answers, Opened, text)] → [In-flight steps 2-3, SKILL.md:228-237]    → [brief Status/Kept:/Answered: edits and new you: judgment entries]
B4: [digest section 3 banner text]                                         → [cycle step 3, SKILL.md:156-158]           → [agent "fix or report" action on questions files]
```

B1 is the boundary this round changes (moved: the archive check now runs once, before the branch chain, instead of inside two branches). B3 changes its matching key (dates → question IDs plus "names the brief's path"). B2 and B4 change only their banner text.

Input-source classification:

```
S1: docs/working/questions.md, questions-archive.md, docs/, docs/working/ (repo tree)
      — runtime-mutable (any merged commit, any clone) — UNTRUSTED for path-follow / file-read sinks
        (a committed symlink can point anywhere on the host); UNTRUSTED as instructions
S2: question entries' text and answers inside S1          — runtime-mutable — UNTRUSTED as instructions;
        accepted as the user's decision channel only for entries on the default branch (the skill's
        design trust root; a forged entry needs a user-merged commit)
S3: questions.sh path ($SCRIPT_DIR or $HOME/.claude/scripts) — deploy-time — trusted for exec
S4: QUESTIONS_LIVE / QUESTIONS_ARCHIVE environment         — deploy-time (operator) — trusted; exempt by questions.sh's own header
S5: brief files docs/working/handoffs/*.md (Status:, Kept:, Answered:) — runtime-mutable — UNTRUSTED as instructions;
        state the cycle itself writes
```

What enters from outside is the repo tree (S1/S2): its shape decides whether questions.sh runs at all, and its entries decide whether a brief is kept, closed or re-asked. The diff assumes the shape check (B1) completes before any read through a symlink, and that entries "naming this brief" are the keep-or-drop questions the cycle filed.

## Findings

#### 1. In-flight steps 2–3 key on "questions naming this brief", not on the questions the cycle filed

**Severity:** Informational
**Location:** `skills/dev-cycle/SKILL.md:228-237` (B, 5423a33)
**Boundary:** B3
**Move:** 2 (implicit sanitization assumption), 5 (invert the access model)
**Confidence:** Medium
**Legibility-target:** agent
**Evidence (verbatim):** `Search\n     \`questions.md\` and \`questions-archive.md\` for questions naming this brief` (`:229-230`) … `apply\n     each answered one whose ID is not on that line` (`:231-232`) … `and no\n     question naming this brief is open, file one \`you: judgment\` entry` (`:235-236`) [excerpt; the item continues to `:237` "Until it is answered, the brief still holds its slot."]

The selector is "names the brief's path"; "keep-or-drop" appears only in the step's lead sentence (`:228`). Any other entry that links the brief (a question a build session files with a `**Read:**` link to its brief, which the questions grammar asks for, or an entry arriving in a merged contributor commit) is inside both sets: an answered one is a candidate "keep"/"drop" in step 2, and an open one satisfies step 3's "no question naming this brief is open" guard, so the 14-day ask is suppressed for as long as that entry stays open and the brief holds one of the three slots. Preconditions: such an entry on the default branch. Security impact is bounded: a forged or stray entry can close or prolong a brief (visible in the roadmap, reversible), never run code, and S2 entries reach the default branch only through a user-approved merge, so this does not meet the floor rule's reachable-environment bar; the same exposure existed under cb2e5f9's text-keyed search, and the ID-on-`Answered:` rule itself does stop double application. The overlap is mainly correctness (route to api-consistency / code-fact-check).
**Recommendation:** Have step 3 record the ID it files on the brief (e.g. `Asked: Q-NNN`), and make step 2 apply, and step 3's guard check, only IDs on that line. That closes the stray-match case and means a repo-authored entry can never stand in for the cycle's own question.

#### 2. Cycle step 3's "fix" for a skipped questions file does not repeat the no-follow rule

**Severity:** Informational
**Location:** `skills/dev-cycle/SKILL.md:156-158` (B, 5423a33)
**Boundary:** B4
**Move:** 3 (error path)
**Confidence:** Low
**Legibility-target:** agent
**Evidence (verbatim):** `- If the digest says watched questions were NOT checked (it gives the cause: a skipped\n  questions file or archive, questions.sh missing, or \`questions.sh open\` failing), fix or\n  report that first; the section was not checked.` (complete bullet)

The diff adds "a skipped questions file" (a symlinked `questions.md` or `docs/working/`) to the causes the agent is told to "fix". The tempting fix for a symlinked file is to replace it with its target's content, which would copy a host file into the repo (and into a commit). Step 0 guards its equivalent with "(never read, copy or rewrite through them)" (`SKILL.md:107`); step 3 does not. The global rule "**Never through a symlink.**" (`SKILL.md:61-68`) already forbids reading questions through a symlink, so this is defense in depth, not a reachable bypass.
**Recommendation:** Append "(never read, copy or rewrite through them; report the path, as step 0 does)" to the bullet, or point it at `## Rules`.

## Untested bypass candidates

None left untested for the B1 guard. Candidates and dispositions (all on 09f6fe7):

| # | Bypass input | How dispositioned | Outcome |
|---|---|---|---|
| 1 | archive is a symlink to a host file (with questions.md plain) | executed: bats test 10; probe C10 (0 `SECRET` lines) | banner, questions.sh not run, archive in section 8 |
| 2 | archive is a dangling symlink | executed: probe C7 | banner; archive listed |
| 3 | archive is a directory | executed: probe C1, and C9 with questions.md absent | banner (C1) / "No docs/working/questions.md" (C9); archive listed in both |
| 4 | archive is a FIFO | executed: probe C2 | banner; no hang (blocker uses `-e`/`realpath`, never opens it) |
| 5 | `docs/` or `docs/working/` is a symlink | executed: probe C3, C4 | banner naming `docs/` / `docs/working/`; only that part listed; nothing below probed |
| 6 | questions.md and archive both symlinks | executed: probe C6 | banner names questions.md; both listed in section 8 |
| 7 | archive symlink with questions.sh absent | executed: probe C5 | banner names questions.sh missing; archive still listed (the "checked once, up front" aim) |
| 8 | archive is a hard link to a host file | traced: `realpath` returns the in-repo path, so `rawfile` passes it | passes the guard, but git cannot check out hard links; needs local write to the checkout, i.e. host control — below the bar |
| 9 | swap the archive for a symlink between `dev-cycle.sh:250` and `:262` | traced (move 4) | needs concurrent local write to the checkout — host control |
| 10 | `QUESTIONS_ARCHIVE` set to another path | traced: questions.sh honours it, digest checks the default path | S4 operator choice, exempt by questions.sh's header |

No case printed either marker string (probe: `0 0 0 0 0 0 0 0 0`).

## Endorsement Claims

- **Claim:** At 09f6fe7, for every probed archive/questions.md/parent shape that `blocker` rejects, section 3 prints a "**Watched questions were NOT checked** —" banner or the absent message and does not run `questions.sh open`, and no outside-file content reaches the digest.
  **Location:** `scripts/dev-cycle.sh:250-276`
  **Evidence:** executed
  **Verified:** probe C1–C10 and bats test 10 (outputs above; `SECRET` count 0 in all nine full-digest runs).
  **Not verified:** the `questions.sh open` failure branch (`:273-276`) was not driven (no repo shape made `open` exit non-zero), so the content of a real error inside the fence was not observed.
  **route: code-fact-check**
- **Claim:** At 09f6fe7 a non-plain archive is listed in section 8 on each section-3 branch probed (questions.md skipped, absent, questions.sh missing, archive banner).
  **Location:** `scripts/dev-cycle.sh:250`, section 8 (`dev-cycle.sh:371-377`)
  **Evidence:** executed
  **Verified:** probe C5, C6, C9, C1; bats test 10's new section-8 assertion.
  **Not verified:** the branch where `questions.sh open` fails with a plain archive (no archive to list there; the listing path is the same `qa_at` line).
  **route: code-fact-check**
- **Claim:** The four causes cycle step 3 names (skipped questions file, skipped archive, questions.sh missing, `questions.sh open` failing) correspond one-to-one with the four `$nc` echo sites in 09f6fe7 section 3, and "No docs/working/questions.md in this repo." is the one non-banner outcome, which step 0's "If the repo has no `docs/working/questions.md`" covers.
  **Location:** `skills/dev-cycle/SKILL.md:99-100,156-158`; `scripts/dev-cycle.sh:252-276`
  **Evidence:** read-static
  **Verified:** read both units in full; `grep -n '\$nc'` gives sites at `:253`, `:257`, `:259`, `:274`.
  **Not verified:** B's own tree at 5423a33 does not contain 09f6fe7 (`git merge-base --is-ancestor` fails), so on B alone the "questions.sh missing" cause prints the older "No docs/working/questions.md (or questions.sh)" line; the correspondence holds once the digest branch is merged first.
  **route: code-fact-check**
- **Claim:** Under 5423a33's step 2, an answer whose ID is on the brief's `Answered:` line is not applied again, and a question naming a different brief path is not in the search set for this brief.
  **Location:** `skills/dev-cycle/SKILL.md:228-233`
  **Evidence:** read-static
  **Verified:** read In-flight items 1–3 and the build-brief paragraph (`:247-253`); brief paths carry the date and slug, so two briefs for one item differ in path unless written the same day with the same slug.
  **Not verified:** how an agent maps a non-literal answer (e.g. `Q-NNN: [1]`) to "keep"/"drop"; an unmapped answer stays off `Answered:` and is re-read each cycle.
  **route: code-fact-check**

## Primitive sweep

Primitive: process exec / file read of repo-controlled paths (path traversal through symlinks)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/dev-cycle.sh:250` `skipped "$QA"` (blocker walk: `-e`, `-L`, `realpath`) | S1 | probes only; stops at the first non-plain part | cleared — probe C1–C10 |
| `scripts/dev-cycle.sh:252` `skipped docs/working/questions.md` | S1 | same walk | cleared — C3, C4, C6 |
| `scripts/dev-cycle.sh:254` `inrepo docs/working/questions.md` | S1 | walk, then `-f` | cleared — C9 |
| `scripts/dev-cycle.sh:262` `bash "$QS" open` (reads S1 files) | S3 exec path; S1 data | runs only after `:252-258` all pass | cleared — reachable only with both files plain or absent archive (C8) |
| `scripts/dev-cycle.sh:276` `cat "$qs_err"` | `mktemp` file; content from questions.sh | fenced, scrubbed | cleared for path; content fence pre-dates this diff (out of scope) |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | In-flight steps 2–3 key on "questions naming this brief", so stray or repo-authored entries that link the brief are applied or suppress the ask | Informational | B3 | `skills/dev-cycle/SKILL.md:228-237` | Medium |
| 2 | Cycle step 3 "fix" for a skipped questions file lacks step 0's no-follow parenthetical | Informational | B4 | `skills/dev-cycle/SKILL.md:156-158` | Low |

## Overall Assessment

A (09f6fe7): no findings within the code paths read and executed. The section-3 chain is ordered as the round intends, the archive is probed once before any branch, every non-plain shape I tried (symlink, dangling symlink, directory, FIFO, symlinked `docs/` or `docs/working/`) keeps `questions.sh` from running, and section 8 lists the archive in every branch probed. The only unexercised branch is `questions.sh open` failing. B (5423a33): two Informational items, both defense in depth; the ID-on-`Answered:` rule does stop an answer being applied twice, and keying on the brief path does keep an older brief's answers out. The most useful change is Finding 1's: have the brief record the IDs it asked, and act only on those. Merge-order note (not a finding): B's step 3 names the "questions.sh missing" banner, which only exists once 09f6fe7 is in, so the digest branch must merge first, as planned. Endorsement claims are pending execution verification where marked read-static: *no findings within the code paths read; endorsement claims pending execution verification* for B.

## Goal-Alignment Note

Success criterion (verbatim from the brief): "a markdown report saved at the path your role instructions give, structured per your skill file."

Saved at `/workspace/.claude/wt-digest/docs/reviews/security-review-2026-10-01-digest-pass16.md` with first line `Commit: 09f6fe7 (A) / 5423a33 (B)`, and the skill's sections: Trust Boundary Map with source table, findings carrying Severity, Location, Evidence (verbatim), Confidence and Legibility-target, untested-bypass list, endorsements routed to code-fact-check, primitive sweep, summary and overall assessment. Against the round's aims: A's chain and up-front archive check hold in every probed combination; B's ID-keyed answers apply each answer once and keep an old brief's answers out, with two Informational hardening items. Not committed; nothing written to either worktree beyond this file.
