Commit: daf5bd82

# Security Review: chore/dev-cycle-2026-10-02 (final confirming pass, full branch)

**Scope:** `git diff main...HEAD` at daf5bd82 (12 files, all under `docs/`: roadmap, cycle record, idea log, questions Q-104..Q-110 plus the Q-096 edit, 3 build briefs, review artifacts)
**Date:** 2026-10-02
**Based on:** final fact-check, k=3 merged (`docs/reviews/code-fact-check-report-devcycle-cycle-2026-10-02-final-r{1,2,3}.md`): 0 Incorrect, 0 Stale, no security escalations; pass-1 security review `docs/reviews/security-review-2026-10-02-devcycle-cycle.md` (at 20a462d4)
**Review frame:** confirm that pass-1 F1–F3 (fixed in 7c4f5063 and 237fce88) still hold, and look for anything new, especially in brief text a build session would follow and in Q-110's described fix

No escalation pattern matched. A scan of the added lines for credential-shaped strings, TLS-off flags and key material found only prose mentions. `git diff --name-only main...HEAD` lists no file outside `docs/`.

## Trust Boundary Map

```
B1: [repo text: commits, decisions, questions, digest]  → [dev-cycle session + --check-path/--check-branch/--check-brief] → [committed briefs, entries, roadmap]
B2: [committed build brief (repo text)]                 → [user reads the brief before a loop starts (handoff brief :41-43)] → [build session with write/commit authority in a worktree]
B3: [Q-109 paste block (repo text)]                     → [user copy-paste]                                         → [shell: git branch -d in /workspace]
B4 (proposed by a brief): [brief + seed doc]            → [build-loop script: policy line, path guard, symlink check] → [autonomous loop with self-merge authority]
B5: [container-writable git config: url.*.insteadOf]    → [cc-exit-scan.sh on the host at session exit]             → [push / host git operations]
B6: [process env: RUN_TESTS_NOT_RUN_FILE]               → [scripts/run-tests.sh:356-358 write]                      → [health-check's NOT RUN warning (health-check.sh:389-397)]
```

Input-source classification:

```
S1: local branch names (git refs)            — runtime-mutable (any session sharing the checkout) — UNTRUSTED toward shell-paste sinks; gated by --check-branch's ok-only rule
S2: brief text in docs/working/briefs/       — runtime-mutable (any session can commit)            — UNTRUSTED toward exec/merge-authority sinks; a task description only after the user reads it (B2)
S3: docs/working/seed-build-loop-handoff.md  — runtime-mutable repo text                          — UNTRUSTED as a spec (the brief says "not as a spec"); evidence only
S4: git config written inside the container  — runtime-mutable by the session                    — UNTRUSTED toward every exit-scan sink (path walk, hooks, push)
S5: guides/*.md, init-firewall.sh hint text  — tracked; deploy-time for the container             — trusted as evidence of current behavior; not an exec source
S6: RUN_TESTS_NOT_RUN_FILE env var           — inherited by every child process of the runner     — trusted for availability (a count file); not a security sink, but untrusted
                                                                                                    as "set by my direct caller", since any nested run inherits it
```

The diff adds no code. What crosses trust levels is repo text that a later actor runs or acts on: a shell paste block the user will run (B3), and three briefs a build session will act on (B2). One brief commissions B4, a component that decides what autonomous loops may merge. Another extends the scanner on B5. Q-110 describes a change to the runner's B6 write. Pass-1's three findings hold at daf5bd82 (see Endorsement Claims). One residual gap sits in the B4 acceptance criteria.

## Findings

#### 1. Handoff brief pins a denylist for self-merge but not the `Paths:` allowlist, so "not covered" bypass families can ship with self-merge enabled

**Severity:** Medium (floor rule: a named mechanism in a reachable environment. The user setting `Build-loop policy: self-merge` via Q-103 is a reachable configuration. The unlikelihood is recorded in Confidence.)
**Location:** `docs/working/briefs/2026-10-02-build-loop-handoff.md:33-40`
**Boundary:** B4, B2
**Move:** 5 (invert the access-control model), 11 (bypasses)
**Confidence:** Low. The seed the builder re-verifies does carry the allowlist, the pre-mortem names the right families, and self-merge is unreachable until the user answers Q-103.
**Legibility-target:** the build session on `feat/build-loop-handoff`, and the user when Q-103 is re-routed to `you: judgment`

**Evidence (verbatim):**
> - The plan opens with a bypass-family pre-mortem (the script decides what autonomous loops
>   may merge), each family marked covered or not, before any code. Candidates to include:
>   root-level scripts, `.gitattributes`, renames out of a denied directory, symlinks.
> - Each of these invariants has a refusal test: anything other than the exact policy line
>   resolves to `review`; self-merge refuses any path on the seed's denylist; an added symlink
>   refuses self-merge; a loop never pushes and never writes `docs/working/questions.md`,
>   `docs/roadmap.md` or `docs/dev-cycle.md`; [...]

The pass-1 fix pins the denylist, which is default-allow. The seed's guard has two parts: a denylist of directories that later runs follow unreviewed, and a positive check, "a `Paths:` allowlist and a pre-merge `git diff --name-only` ⊆ Paths" (`seed-build-loop-handoff.md:34-36`, step 6b :119-122). The brief requires a refusal test only for the denylist half. Three of the four pre-mortem candidates it names fall outside every denied directory: root-level scripts (`.apir5-probe.sh` already exists at the root of `main`), `.gitattributes`, and renames whose new name is in an allowed place. Only the allowlist blocks them. The pre-mortem may mark a family "not covered", and no criterion says what follows from that. A builder can therefore meet every listed criterion and ship a self-merge path with no allowlist check and known uncovered families. Once the user picks self-merge in Q-103, a loop working from a repo-text brief could self-merge a new root script or a `.gitattributes` change. Later sessions then run that script or inherit those git attributes without review.

The brief's never-write list also omits `docs/working/briefs/`, which the seed lists as a stop condition (`seed:90-91`, "editing ... `docs/working/handoffs/`"). Because a loop reads its own brief "from the landed commit", it cannot change its own instructions. Without the allowlist, though, a self-merged edit to *another* open brief changes what a later loop does.

**Recommendation:** Add to the invariant list: "self-merge refuses any changed path outside the brief's `Paths:` plus the loop's own `docs/working/` research, plan and checkpoint files and `docs/reviews/` artifacts, checked with rename detection off so a move reports both names". Add `docs/working/briefs/` to the never-write list. Then add: "a pre-mortem family marked not covered either blocks self-merge or is listed in Q-103 when it is re-routed to `you: judgment`". Together these are about three lines of brief text.

#### 2. Q-110's second fix option ("have the runner refuse an inherited one") cannot tell its caller from a nested run; the hermetic fix belongs in the test

**Severity:** Informational
**Location:** `docs/working/questions.md:129` (Q-110 "Cause")
**Boundary:** B6
**Move:** 2 (implicit sanitization assumption), 3 (error path)
**Confidence:** High on the mechanism (traced). The impact is monitoring integrity, not a security property.
**Legibility-target:** the agent that picks up Q-110

**Evidence (verbatim):**
> Fix: override the variable in those calls, or have the runner refuse an inherited one; add a test.

Traced: `health-check.sh:389` and `:397` pass `RUN_TESTS_NOT_RUN_FILE` as an environment variable to the runner. The runner writes the count at `run-tests.sh:356-357` (Q-110 cites :356; the write is on :357, as the fact-check noted) and then hands the env to bats. `test/skills/eval-helpers-gating.bats:76-91` then calls `run bash "$T/scripts/run-tests.sh" --fast` with no override, so the nested runner writes 4 into the health check's file. That is a write outside the test's `mktemp -d` root. An environment variable is always inherited, so a runner cannot distinguish the health check's direct assignment from a nested bats suite's inherited copy without a second marker variable that the nested run would also inherit. The "refuse" option therefore either breaks the health check or quietly needs a depth or owner marker. The cost of getting this wrong is an under-counted NOT RUN warning. That hides how much of the suite is not running, but it grants no access.

**Recommendation:** Prefer the test-side fix: unset `RUN_TESTS_NOT_RUN_FILE` in the suite's `setup()`, or in `test/lib/hermetic-env.bash`, which today unsets only locale variables. Add a test asserting that the parent's file is untouched after the suite runs. Drop or spell out the "refuse an inherited one" option.

## Untested bypass candidates

For the B4 self-merge guard (Finding 1). These were not tested because the guard does not exist yet. They are inputs for the builder's pre-mortem:
- A rename out of a denied directory. `git diff --name-only` with rename detection on (git's default since 2.9) reports only the new name, so `hooks/x` → `docs/x` looks like an allowed addition and hides a deletion from `hooks/`.
- A mode-only change (for example, setting the executable bit on an allowed file). `--name-only` lists it, but the allowlist accepts it if the path is allowed.
- `docs/decisions/` and `docs/thoughts/`, which later sessions read as context and which are on neither list.
- A merge commit on the loop branch that brings in default-branch content. `main...HEAD` (three dots) excludes it, but a merge-time diff against a moved default branch may not.

For B5 (Q-096): pass-1's candidates (pushInsteadOf, nested prefixes) are now in the brief's test list. One remains untested: a rewrite rule from the user's global config (which the container cannot write) applied to a repo-config remote (which it can). Per its header, the scan reads only hooksPath, attributesFile and includes from the user's config (`cc-exit-scan.sh:66-67`). The rule's source is host-owned, so it is likely benign. "At every config level it already reads" leaves it out of scope.

## Endorsement Claims

- **Claim:** Pass-1 F1's three requested changes are present in the handoff brief at daf5bd82: a bypass-family pre-mortem before any code; a refusal test for the policy line, the denylist, added symlinks, no-push and the no-write files; and the user still reads each brief, with the brief not standing in for plan approval "whatever the seed's step 6b says".
  **Location:** `docs/working/briefs/2026-10-02-build-loop-handoff.md:33-43`
  **Evidence:** read-static
  **Verified:** read the brief in full, and read the seed's guard text (:25-41) and step 6b (:102-127).
  **Not verified:** the allowlist half of the seed's guard, which the brief does not pin (Finding 1).
  **route: code-fact-check**

- **Claim:** Pass-1 F2's fix holds. The Q-096 brief requires `Live-verified: no — REASON`, "never a bare yes or a hash, unless the host probe actually ran", plus a `you: terminal` entry for the host probe. Its build-loop clause, under which a loop names the probe in its marker and the cycle files it, agrees with the handoff brief's rule that loops never write questions.md.
  **Location:** `docs/working/briefs/2026-10-02-exit-scan-insteadof-target.md:32-37`; `2026-10-02-build-loop-handoff.md:38-39`
  **Evidence:** read-static
  **Verified:** read both briefs in full.
  **Not verified:** `hooks/live-verify-gate.sh`'s acceptance of the value. By design it accepts free text (pass 1, :16-21), so the brief text is the only control.
  **route: code-fact-check**

- **Claim:** Pass-1 F3's fix holds. The Q-096 test list now names `pushInsteadOf`, overlapping prefixes (with "the scan walks every matching rule", an over-approximation) and a path-valued `branch.NAME.remote` rewrite.
  **Location:** `docs/working/briefs/2026-10-02-exit-scan-insteadof-target.md:24-28`
  **Evidence:** read-static
  **Verified:** read the acceptance criteria.
  **Not verified:** `remote.pushDefault` as a path-valued source, which pass 1 listed and the brief does not name.

- **Claim:** The Q-109 paste block names exactly four branches. `--check-branch` prints `ok … 0` for each at daf5bd82, and `git rev-list --count main..<b>` is 0 for each. The three brief branches print `absent`.
  **Location:** `docs/working/questions.md` (Q-109 fenced block); the briefs' `## Branch` sections
  **Evidence:** executed
  **Verified:** `timeout 30 scripts/dev-cycle.sh --check-branch …` and `git rev-list --count` on all seven names. The paste block itself was not run.
  **Not verified:** what `git branch -d` checks merge status against if the shared checkout is on another branch at paste time. `-d` refuses unmerged branches, so the expected failure mode is a refusal.
  **route: code-fact-check**

- **Claim:** The three briefs pass `--check-brief` (`ok … new`). They contain no fenced blocks, no lines starting with `<`, `[` or `<!--`, and no CRs. Every repo path they direct a later session to open passes `--check-path`, including the seed and known-issues docs and the Q-110 files (`scripts/health-check.sh`, `scripts/run-tests.sh`, `test/skills/eval-helpers-gating.bats`).
  **Location:** `docs/working/briefs/*.md`; `docs/working/questions.md` Q-110
  **Evidence:** executed
  **Verified:** `--check-brief` on each brief, `rg` for the forbidden line shapes and CRs (no output), and `--check-path` on 8 paths (all `ok`).
  **Not verified:** `--check-brief`'s line-trust check on the landed default branch. It reads `main`, so it printed `new`. Rubric row C8 already tracks this as a post-merge re-run.
  **route: code-fact-check**

- **Claim:** No line in the three briefs or in Q-104..Q-110 tells a session to push, open a PR, read or write credentials, disable or bypass a hook, or skip a pre-mortem. Both enforcement-adjacent briefs require a pre-mortem. The doc-drift brief keeps scripts out of scope.
  **Location:** `docs/working/briefs/*.md`; `docs/working/questions.md` (added entries)
  **Evidence:** read-static
  **Verified:** read each brief and each added questions entry in full.
  **Not verified:** the seed doc's sections after :48 ("Open edges pass 9 had not yet re-reviewed"). The brief already marks the seed as non-binding.

- **Claim:** Q-110's stated cause matches the code. `eval-helpers-gating.bats:76-91` calls the runner without overriding `RUN_TESTS_NOT_RUN_FILE`, and the runner writes the inherited path at `run-tests.sh:357`.
  **Location:** `docs/working/questions.md:129`
  **Evidence:** read-static
  **Verified:** read the suite's lines 1-100, the runner's lines 330-375, and every `RUN_TESTS_NOT_RUN_FILE` reference in `scripts/` and `test/`.
  **Not verified:** the reproduction itself, which pass 2 ran and this pass did not re-run.

## Primitive sweep

Primitive: shell command execution from repo text (paste blocks and commands quoted in briefs or entries)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `docs/working/questions.md` Q-109 fenced paste (`git -C /workspace branch -d …`) | S1 | `--check-branch` ok-only; `-d` refuses unmerged | cleared: 4 names, all `ok`, 0 ahead (re-run this pass); not executed |
| `doc-drift-cycle1.md:20,31` `devcontainer up --remove-existing-container` | S5 | quoted as advice to remove | cleared: no instruction to run it |
| `doc-drift-cycle1.md` `cc-isolated --probe-only NAME`, `cc-isolated NAME` | S5 | `NAME` placeholder, host-only | cleared: text for the guide |
| `exit-scan-insteadof-target.md:32` `Live-verified:` trailer | S2 | brief wording (`no — REASON`) | cleared: pass-1 F2 fixed |
| Q-110 `run-tests.sh --fast` / nested runner calls | S6 | none (env inherited) | Finding 2 (described fix, not a command to run) |
| cycle record (`bats …`, `git worktree prune`, `questions.sh`, `unshare -rn true`) | S2 | dev-cycle Rule 1: repo text is evidence | cleared: past-tense evidence, not a brief |

Primitive: path construction / write destination from repo text or env

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| Paths named in the 3 briefs and in Q-110 | S2 | `--check-path` | cleared: all `ok` |
| Seed doc referenced by the handoff brief | S3 | `--check-path` | cleared for the read; content gap is Finding 1 |
| B4 self-merge path guard (future code) | S2, S3 | denylist pinned, allowlist not | Finding 1 |
| Rewritten insteadOf targets (future code) | S4 | `_snap_inside_ws` (per brief) | cleared at brief level: tests now cover pass-1 candidates |
| `run-tests.sh:357` write to `$RUN_TESTS_NOT_RUN_FILE` | S6 | none | Finding 2 |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Handoff brief pins the self-merge denylist but not the `Paths:` allowlist; "not covered" families have no consequence; briefs dir missing from never-write list | Medium | B4, B2 | `docs/working/briefs/2026-10-02-build-loop-handoff.md:33-40` | Low |
| 2 | Q-110's "runner refuses an inherited var" option cannot work as stated; fix belongs in the test/hermetic env | Informational | B6 | `docs/working/questions.md:129` | High |

## Overall Assessment

This is a docs-only branch, and pass 1's fixes hold. The Live-verified wording and the Q-096 test list are fully addressed. The handoff brief now requires a pre-mortem, refusal tests, and the user's read of each brief. Every check that could be executed passed again at daf5bd82: `--check-branch`, `--check-path`, `--check-brief` and line shapes. Finding 1 is what remains: pass-1 F1 was fixed with a denylist alone. A denylist defaults to allow, and three of the four bypass families the brief names fall outside it. The seed's allowlist is what actually closes them, and the brief does not pin it. Self-merge stays unreachable until the user answers Q-103, and the user reads the brief before any loop starts, so the gap is not live. It is still the brief text a build session will treat as its definition of done. Fixing it is a three-line edit to the brief, best made before the merge. Finding 2 is advice for whoever picks up Q-110. There are no findings within the paths read beyond these two. Endorsement claims are pending execution verification.

## Goal-Alignment Note

The user's goal is to land this branch after a clean review. Nothing here blocks on security grounds alone: no code, no secrets, nothing reachable before Q-103. Finding 1 (Medium, Low confidence) is a wording fix in `docs/working/briefs/2026-10-02-build-loop-handoff.md` that completes pass-1 F1. Make it before the merge, because step 7 lands briefs on the default branch "before work on them starts", so a missing invariant becomes a build session's spec the moment the branch merges. The edit is in a brief and touches no reviewed record, so a fix-drift lite check of that one file should be enough to re-confirm. Finding 2 can stay where it is, as a note on Q-110.
