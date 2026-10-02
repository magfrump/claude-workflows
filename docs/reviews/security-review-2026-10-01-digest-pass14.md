Commit: 096042b (A) / 374d559 (B)

# Security Review — dev-cycle loop pass 14 (pass-13 fix round)

**Scope:** Partial. A: `git diff 591f098..096042b -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` (commit 096042b), worktree `/workspace/.claude/wt-digest`. B: `git diff 44d06b7..374d559 -- skills/dev-cycle/SKILL.md` (commit 374d559), worktree `/workspace/.claude/wt-devcycle`. Everything else on both branches is context only.
**Date:** 2026-10-01
**Based on:** `docs/reviews/code-fact-check-report-digest-pass13.md` (Stage 1 context, pass 13, k=1) and pass 13's security review (`docs/reviews/security-review-2026-10-01-digest-pass13.md`, Findings 1 and 2), which this round answers.

Execution: `scripts/dev-cycle.sh`, `scripts/questions.sh` and `test/scripts/dev-cycle.bats` were taken from 096042b with `git show` into `sec14/pin/`. `timeout 300 bats sec14/pin/test/scripts/dev-cycle.bats` gave 23/23 `ok`, exit 0 (`sec14/bats.log`). Probes P1–P12 (`sec14/probe.sh`, `sec14/probe2.sh`; logs `probe.log`, `probe2.log`) ran the pinned script under `timeout 60` with `DEV_CYCLE_TODAY=2026-03-01`, each in its own repo under one `mktemp -d` directory that was removed on exit. Lookup tracing used `DEV_CYCLE_SCRUBBED=1 bash -x` and grepped for every `[[ -d/-e/-f/-L ]]` test and `realpath -e` call on a path below the blocking part; a positive control on a plain tree did produce such lines (`probe2.log`), so an empty grep means no lookups happened. `strace` is not installed. Nothing was written to either worktree except this report, and no processes were left running. All scratch is under `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/sec14/`.

Legibility-target values: **maintainer** (someone editing the script, tests or skill), **agent** (the model running the dev-cycle skill on the digest), **user** (the human reading the digest or record).

## Trust Boundary Map

```
B1:       [committed tree shape under docs/: symlinks, non-regular entries] → [blocker() walk :103-113 via inrepo :117, dirok :120 (new), skipped :121] → [section 8, inline notes, Window line, section 2 "Not read:" lines (new)]
B2 (moved): [committed tree shape: docs/working/questions-archive.md]        → [skipped "$QA" gate :250 before questions.sh runs]                        → [questions.sh `open` → require_files stat (questions.sh:132-138)]
B3:       [committed file names in docs/decisions/]                          → [blocker newline→space :112, scrub :40-57]                              → [section 2 "Not read:" line text (new), section 8]
B4:       [digest output (Window line, section 8)]                           → [skill step 0 first bullet, SKILL.md:103-108]                            → [`agent` entry in questions.md, --since rerun]
B5:       [questions.md / questions-archive.md answer text and dates]        → [agent applying SKILL.md:226-232 (answer once, by search)]               → [brief `Kept:` / `Status: closed`]
```

Input-source classification:

```
S1: committed tree entries (symlink targets, entry types) — repo content — UNTRUSTED for path-resolution / existence-probe sinks
S2: committed file names in docs/decisions/, docs/working/cycles/ — repo content — UNTRUSTED for text-output sinks (section 2 and 8 lines, agent entry)
S3: host filesystem behind a symlink target — the protected asset — must not reach any output sink, not even existence
S4: SCRIPT_DIR / HOME (QS lookup :243-244), DEV_CYCLE_TODAY, QUESTIONS_LIVE/ARCHIVE env — operator environment — trusted (all sinks)
S5: digest output — derived from S1/S2 — UNTRUSTED toward agent-instruction sinks (data, never directions)
S6: answer entries and brief text in docs/working/ — repo content, same author set as the brief files — untrusted for path sinks; same-trust for slot accounting
```

What enters is the committed tree (S1, S2) plus repo-authored answer text (S6). This round moves the questions-archive boundary (B2) in front of `questions.sh`, which closes pass 13's Finding 1 (a one-bit existence oracle on any host path a committer names): P3, P4, P5 and test 10 show `questions.sh` does not run when the archive, or anything above it, is not plain. It also moves the two glob-directory gates onto the walk (`dirok`), which closes pass 13's Finding 2: P7–P10 trace no lookup below `docs/`, `docs/working/`, `docs/decisions/` or `docs/working/cycles/` when that part is a symlink. No new boundary leaks S3. What remains is wording and a skill-side date rule.

## Findings

#### 1. Section 2's summary "every decision input that exists was skipped" is printed when a plain decision record exists but has no triggers

**Severity:** Informational (no security property is violated: the per-path "Not read:" lines above it are accurate, and the summary overstates the skip, not understates it)
**Location:** `scripts/dev-cycle.sh:237-239`
**Boundary:** B1
**Move:** 3 (error path), checked against the brief's claim 1 wording
**Confidence:** High
**Legibility-target:** user, agent

Evidence (verbatim): `if [[ ${#SKIPPED[@]} -gt $n_before_triggers ]]; then echo "No revisit triggers read: every decision input that exists was skipped."` (`:238`; the `if [[ $found -eq 0 ]]` block ends at `:240` — read). The condition is "no trigger printed and something was skipped", not "everything that exists was skipped". `found` stays 0 for a plain record without `## Revisit triggers` (`:207`). P1 (plain `001-plain.md` with no triggers section, symlinked `002-link.md`, no log) prints:

```
Not read: docs/decisions/002-link.md is not a plain file or directory (section 8); its triggers are missing above.
No revisit triggers read: every decision input that exists was skipped.
```

The second line is false: `001-plain.md` exists and was read. Because the "Not read:" line already names exactly what was skipped, nothing is hidden. The harm is that a reader may take the line as meaning the repo's decision inputs were all symlinked away, and look for an attack on the tree that is not there.

**Recommendation:** Say what the condition means: "No revisit triggers read; the inputs above were skipped." Or print the current text only when no plain record or log was read. route: code-fact-check (the claim's truth across the {plain record without triggers, skipped record, absent log} combinations).

#### 2. The new archive-gate comment and notice say `questions.sh` "reads" the archive; `open` only stats it

**Severity:** Informational (the gate is still needed: a stat that follows a committed symlink is the oracle pass 13 F1 named)
**Location:** `scripts/dev-cycle.sh:246-251`; `scripts/questions.sh:132-138`, `:408-410`
**Boundary:** B2
**Move:** 2 (implicit assumption, here about what the downstream tool does)
**Confidence:** High
**Legibility-target:** maintainer, user

Evidence (verbatim): `# questions.sh reads the archive too and would follow a symlink there, so the` / `# archive passes the same check before questions.sh runs.` (`:246-247`) and `echo "Watched questions were NOT checked: questions.sh reads the archive too."` (`:251`). In `questions.sh`, `cmd_open() { require_files; parse_entries "$LIVE" | …` (`:408-410`) reads only `$LIVE`. The archive's only use on that path is `[[ -f "$file" ]] || { echo "  ✗ missing: $file" >&2; missing=1; }` in `require_files` (`:134-136`), which is a stat that follows symlinks. The commit message describes it correctly ("a one-bit oracle"). A maintainer who reads "reads" might conclude that the gate matters only if content is printed, and might later relax it for `open`.

**Recommendation:** Change the comment and the notice to "checks the archive too (a stat that follows a symlink)". route: code-fact-check.

#### 3. The stale-brief answer rule (B) puts no bounds on the answer date: a future-dated answer suppresses re-asking for good, and a brief with no `Kept:` takes any earlier answer to the same question

**Severity:** Informational (the preconditions require write access to `docs/working/`, which already permits editing the brief directly, so no privilege is gained; the issue is integrity of the staleness check against repo text)
**Location:** `skills/dev-cycle/SKILL.md:226-232` (B, 374d559)
**Boundary:** B5
**Move:** 2 (validated for format, not content) and 5 (enumerate the uncovered cases)
**Confidence:** Medium (read-static; this depends on how an agent dates an answer, which the grammar does not fix)
**Legibility-target:** agent

Evidence (verbatim): `"keep" adds \`Kept: <the answer's date>\` to the brief,` / `"drop" closes it as above. Apply an answer only if it is newer than the brief's last` / `\`Kept:\` date (so each answer counts once); find it by searching \`questions.md\` and` / `\`questions-archive.md\` for that question` (`:227-230`; the bullet ends at `:232` "the brief still holds its slot." — read). The rule terminates and applies each answer once, as claimed. The answer is applied once, `Kept:` becomes its date, the entry is archived, a new ask follows 14 days later, and an equal date is not "newer". Two cases are uncovered, though:
(a) An answer dated after today (for example `2099-01-01`) becomes `Kept: 2099-01-01`. "14 days after … its last `Kept:` date" is then never reached, so the brief keeps its slot silently. The digest itself ignores future-dated cycle records (`scripts/dev-cycle.sh:155`, `:158`); the skill has no equivalent.
(b) A brief with no `Kept:` has no lower bound. Searching by question text ("keep or drop the brief for <item>?") also matches an answer to an earlier brief for the same item, so an old "drop" can close a fresh brief.
The search is over repo text (S6), so in a cloned repo either case can be caused by committed content as well as by accident.

**Recommendation:** Add "and not after today, and not before the brief's own date" to the rule. Lower-bounding by the brief date also fixes (b). route: code-fact-check for the termination and apply-once claims. The bounds belong to the correctness critics.

No other findings. Rules checked and found correct and complete within the paths read: `inrepo` (`:117`), `dirok` (`:120`), section 3's branch order (`:248-272`), section 2's dedup (`:231-236`), the "one phrase" wording, the new test 10 and the updated tests 6–7, and B's step-0 first bullet. Each is backed by an Endorsement Claim below.

## Untested bypass candidates

- **Collation-equal names in section 2's `sort -u` (`:233`).** Two symlinked decision names that differ only in a character the active locale collates as ignorable could dedup to one "Not read:" line. Not tested: the sandbox has only the C locale (`setlocale` warnings in `bats.log`). Impact if real: one skipped name is not printed in section 2. Its content is still not read, and section 8 uses the same `sort -u` (pre-existing). This is a reporting completeness issue, not a guard bypass. So section 2's dedup does not appear in the Endorsement Claims.

Bypass candidates for the archive gate (move 11), all tested:
1. Archive is a symlink: gate fires, `questions.sh` not run (test 10; P3 with `questions.md` absent; P4 with both symlinked, where the `questions.md` branch fires first).
2. Archive is a directory: gate fires (P5).
3. `docs/working/` or `docs/` is a symlink: the `questions.md` branch fires first and names the ancestor. The archive is never probed (P7, P8, empty traces).
4. Archive absent, `questions.md` plain: `questions.sh` runs and its own "missing" error shows (P2), as the brief requires.
5. `QUESTIONS_ARCHIVE` set in the environment: `questions.sh` checks the override (P12). This is S4 operator choice and cleared.
6. Swapping the archive between the gate (`:250`) and `questions.sh`'s own resolution: traced. It needs a concurrent writer on the host, which is outside the threat model (the floor rule's host-control exclusion). Cleared.

## Endorsement Claims

- **Claim:** With `docs/`, `docs/working/`, `docs/decisions/` or `docs/working/cycles/` committed as a symlink, the digest makes no `[[ -d/-e/-f/-L ]]` test and no `realpath -e` call on any path below that part.
  **Location:** `scripts/dev-cycle.sh:117-122`, `:149`, `:204`
  **Evidence:** executed
  **Verified:** P7, P8, P9 and P10 `bash -x` traces grep empty for lookups below the blocker. The positive control on a plain tree shows `+ [[ -f docs/working/cycles/cycle-2026-02-01.md ]]` and similar lines (`probe2.log`). P9's output contains no `SECRET` (count 0).
  **Not verified:** syscalls not visible to `bash -x` (no strace), for example a stat made inside `git log -- "$f"` at `:210` on a plain-dir glob item.
  **route: code-fact-check**

- **Claim:** Section 3 does not run `questions.sh` when `docs/working/questions-archive.md` is a symlink or a directory, and it reports the skip in section 3 and section 8.
  **Location:** `scripts/dev-cycle.sh:248-251`
  **Evidence:** executed
  **Verified:** test 10 (`ok 10`), and P3 and P5 output (`Watched questions were NOT checked`, and section 8 lists the archive). The `no-such-file` target name never appears (test 10's assertion).
  **Not verified:** a `questions.sh` that `$SCRIPT_DIR` resolves to some other install (`:243-244`) whose `open` reads files other than the two named.
  **route: code-fact-check**

- **Claim:** With a plain `questions.md` and no archive, section 3 still shows `questions.sh`'s own error.
  **Location:** `scripts/dev-cycle.sh:250-269`
  **Evidence:** executed
  **Verified:** P2 prints `**questions.sh open failed**` and the `✗ missing: …/questions-archive.md` lines.
  **Not verified:** the same case with `questions.sh` missing from both `$SCRIPT_DIR` and `$HOME/.claude/scripts` (falls to `:271`).
  **route: code-fact-check**

- **Claim:** The new `inrepo` (`blocker` empty `&& -f`) accepts exactly the inputs the old `inrepo` (`blocker` empty `&& rawfile`) accepted. In file mode, an empty `blocker` result means either the last part is absent (so `-f` is false) or `rawfile` already passed (so `-f` is true).
  **Location:** `scripts/dev-cycle.sh:110-117`
  **Evidence:** read-static
  **Verified:** `:110` returns empty for an absent last part, and `:112` prints nothing only when `rawfile "$1"` succeeds. 23/23 bats pass, including tests 6–7, which cover symlinked files and parents.
  **Not verified:** an entry replaced between the `blocker` subshell and the `-f` (host race, out of model).
  **route: code-fact-check**

- **Claim:** Attacker-chosen decision-record names in the new "Not read:" lines cannot start a line of their own. A newline becomes a space (`:112`), and C0/C1/bidi controls are scrubbed (`:40-57`).
  **Location:** `scripts/dev-cycle.sh:112`, `:231-236`
  **Evidence:** executed
  **Verified:** P11 (a symlinked name containing `; Not read: none` and a newline followed by `## 3. Watched questions`) prints one line starting `Not read: docs/decisions/002-x …`.
  **Not verified:** how a markdown renderer treats backticks inside such a name (pre-existing for section 8 and the `###` headers).

- **Claim:** B's step-0 first bullet covers every Window variant that signals skipped records. Both the "no readable cycle record (records, or a directory above them, were skipped…)" text (`dev-cycle.sh:174`) and the "a newer record … was skipped" text (`:169`) match its first clause, and the `--since` it asks for goes through the digest's date validation (`:179`).
  **Location:** `skills/dev-cycle/SKILL.md:103-108`
  **Evidence:** read-static (plus P10's Window line, executed)
  **Verified:** P10 prints the `:174` variant. The bullet asks the agent never to read, copy or rewrite through section-8 paths, which is consistent with the global "Never through a symlink" rule (`SKILL.md:61-68`). That rule also covers the new archive search in step 6.
  **Not verified:** what the agent writes as the `agent` entry when section 8 lists decision names (S2 text copied into questions.md). Read-static, this is a single line, because names cannot start with `### Q-`.
  **route: code-fact-check**

## Primitive sweep

Primitive: path resolution / file read on repo paths (changed call sites and their siblings in scope)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `dev-cycle.sh:149` `dirok docs/working/cycles` | S1 | walk first | cleared (P8, P10 traces) |
| `dev-cycle.sh:152` `rawfile "$f"` (cycles glob) | S1/S2 | dir passed `dirok` | cleared (unchanged, pass 13) |
| `dev-cycle.sh:204` `dirok docs/decisions` | S1 | walk first | cleared (P9 trace) |
| `dev-cycle.sh:206-207` `rawfile`, `grep` on glob item | S1/S2 | `rawfile` | cleared |
| `dev-cycle.sh:215` `inrepo docs/decisions/log.md` | S1 | walk + `-f` | cleared (test 10) |
| `dev-cycle.sh:248` `skipped docs/working/questions.md` | S1 | walk | cleared (P4, P7, P8) |
| `dev-cycle.sh:250` `skipped "$QA"` | S1 | walk | cleared (P3, P5, test 10) |
| `dev-cycle.sh:252` `inrepo docs/working/questions.md` | S1 | walk + `-f` | cleared |
| `dev-cycle.sh:285`, `:335` `inrepo docs/roadmap.md` | S1 | walk + `-f` | cleared (unchanged; tests 6) |
| `dev-cycle.sh:346` `inrepo "$LOG"` | S1 | walk + `-f` | cleared (unchanged; test 6) |

Primitive: process exec

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `dev-cycle.sh:254` `bash "$QS" open` | S4 (`$SCRIPT_DIR`/`$HOME`) | runs only after the `:248-252` gates | cleared. Finding 2 is about wording only |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | "every decision input that exists was skipped" printed when a plain record without triggers exists | Informational | B1 | `scripts/dev-cycle.sh:237-239` | High |
| 2 | Archive-gate comment and notice say "reads"; `open` only stats the archive | Informational | B2 | `scripts/dev-cycle.sh:246-251` | High |
| 3 | Stale-brief answer date unbounded (future-dated `Kept:`; earlier brief's answer matches) | Informational | B5 | `skills/dev-cycle/SKILL.md:226-232` | Medium |

## Overall Assessment

The round closes both pass-13 security findings. The questions archive is gated before `questions.sh` runs, which removes the host-path existence oracle (executed: test 10, P3, P5). The two glob-directory gates now walk first, so no lookup reaches below a non-plain ancestor anywhere in the digest (executed: P7–P10 traces, with a positive control). `inrepo`, `dirok`, section 3's branch order and section 2's skip lines are correct for every combination probed. What remains are three Informational wording or date-rule items, none with a security mechanism above the reporting level. They are fixable in place, and none is architectural. The most useful fix is Finding 1's summary wording, because it is the one line a reader of section 2 sees as a verdict. Within the code paths read and the probes run, there are no findings above Informational. Endorsement claims marked `route: code-fact-check` are pending execution verification there, except the `executed` ones, which this review ran itself.

## Goal-Alignment Note

Success criterion (verbatim): "a markdown report saved at the path your role instructions give, structured per your skill file."

This report is saved at `/workspace/.claude/wt-digest/docs/reviews/security-review-2026-10-01-digest-pass14.md`, with first line `Commit: 096042b (A) / 374d559 (B)`. It follows the security-reviewer skill structure (Trust Boundary Map with source table, Findings, Untested bypass candidates, Endorsement Claims, Primitive sweep, Summary Table, Overall Assessment). Every finding carries Severity, Location, Evidence (verbatim), Confidence and Legibility-target, and endorsements are routed `route: code-fact-check`. It serves the user goal of reaching a clean pass on both branches: no finding here blocks a merge on security grounds, and the three Informational items are for the fix round to accept or decline.
