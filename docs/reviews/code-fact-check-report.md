**Commit:** 654c0ed

# Code Fact-Check Report

**Repository:** claude-workflows (/workspace)
**Scope:** `git diff e8d5fa1..answers-2026-09-20` (32 commits, 50 files)
**Checked:** 2026-09-21
**Total claims checked:** 27
**Summary:** 13 verified, 7 mostly accurate, 0 stale, 6 incorrect, 1 unverifiable
**Replication:** k=3

Merged by the code-review orchestrator from `code-fact-check-report-r1.md` (33 claims),
`-r2.md` (22 claims), and `-r3.md` (34 claims), all `Commit: 654c0ed`. The verdict is
most-severe-wins, and annotations are the union of all replicates' annotations. Clusters
are emitted at the finest split any replicate used. Replicate claim numbers are cited as
`rN#C` so each merged claim can be traced to its source. Execution logs are in
`docs/reviews/execution-logs/cfc-r1-*`. r2's and r3's logs were written to the session
scratchpad and did not persist.

---

## Claim 1: Guard hook "must NEVER 'ask' on a HARD path — it DEFERS" (file tools)

**Location:** `hooks/guard-trusted-writes.py:13-17` (code at `:80-109`, `:172-184`)
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers Edit/Write classification in the **installed layout**, where `~/.claude/hooks` and `~/.claude/CLAUDE.md` are symlinks into `/opt/claude-workflows/`. It does not establish whether Claude Code's own deny matcher normalises `..` or follows symlinks.
**Replicate verdicts:** r1=Incorrect (r1#5) · r2=Incorrect (r2#2b) · r3=Verified (r3#3)
**Replicate annotations:** r1+r2: "`resolve()` follows the installed symlinks out of `~/.claude` into `/opt/claude-workflows/`, which is not in `GLOBAL_DIRS`; the unresolved candidate with a `..` segment fails `_global_rel`; the path then falls to the `.claude`-in-parts SOFT branch → **ask** when tainted" · r1+r2: "Regressions vs e8d5fa1 (tainted): `Edit ~/.claude/x/../CLAUDE.md`, and a project `.claude` symlinked to `~/.claude` (its `hooks/*` and `CLAUDE.md`) — NEW ask, OLD defer. r2 also: `~/x/../.claude/hooks/*`. `~/.claude/x/../hooks/*` asked on both versions (pre-existing)." · r1+r2: "`settings.json` is a real file, so its variants still defer." · r3: "Verified in a synthetic fakehome where `~/.claude/hooks` is a real directory: `//`, `/./`, `..` and a project `.claude` symlinked to the global dir all resolve to HARD and defer. Case variants (`SETTINGS.JSON`, `Hooks/`) classify soft, and on Linux no deny glob covers them." (The disagreement is explained by layout: r3 did not reproduce the installed symlinked hooks dir.)
**Legibility-target:** for-author

```python
# hooks/guard-trusted-writes.py:88-95
        rel = _global_rel(cand)
        if rel is not None and rel.parts:
            if rel.parts[0] == "hooks":
                return "hard"
```
(excerpt ends :91; enclosing `classify_path` continues to :109 — read)

In a tainted session, an ask on these paths overrides `permissions.deny`. That is Claude Code issue #39344, the exact case the docstring says must never happen.

**Evidence:** `hooks/guard-trusted-writes.py:80-109,172-184`; `docs/reviews/execution-logs/cfc-r1-guard-filetools.txt`

---

## Claim 2: Bash CLAUDE.md is HARD "only when qualified as global: `~/`, `$HOME/`, `${HOME}/`, literal home, `global-instructions/`" (as a literal description)

**Location:** `hooks/guard-trusted-writes.py:24-29`, `:121-129`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the literal spellings listed. It does not cover shell-equivalent spellings (see Claim 3).
**Replicate verdicts:** r1=Verified (r1#7a) · r2=Verified (r2#3a) · r3=Verified (r3#5a)
**Replicate annotations:** none
**Legibility-target:** for-orchestrator-synthesis

The five listed spellings deny. A bare `CLAUDE.md` classifies soft.

**Evidence:** `hooks/guard-trusted-writes.py:121-132`

---

## Claim 3: Bash writes naming the global CLAUDE.md are HARD → "deny" outright (shell-equivalent spellings)

**Location:** `hooks/guard-trusted-writes.py:15-17,24-29,121-129`; commit 4c7a2bb
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `HARD_FRAG`/`SOFT_FRAG` classification of Bash command text, compared with e8d5fa1. It does not cover the accepted `cd ~ && … > CLAUDE.md` residual, which is excluded by the brief.
**Replicate verdicts:** r1=Incorrect (r1#7b) · r2=Incorrect (r2#3b) · r3=Incorrect (r3#5b)
**Replicate annotations:** r1+r2+r3: "Now SOFT (ask if tainted, no gate if untainted), were deny at e8d5fa1: `\"$HOME\"/CLAUDE.md`, `~//CLAUDE.md`, `~/./CLAUDE.md`, `${HOME:-}/CLAUDE.md`, `~/\"CLAUDE.md\"`, `$HOME/x/../CLAUDE.md`" · r2+r3: "`\"${HOME}\"/`, `${HOME%/}/`, `/home/node//`, `/home/node/./`, `$HOME/\"CLAUDE.md\"`, `\"$HOME/\"CLAUDE.md`" · r3: "`\"$HOME\"/CLAUDE.md` is the ordinary quoted form — not only crafted input" · r3: "`./global-instructions//CLAUDE.md`, `global-instructions/./CLAUDE.md`" · r1: "the global config's own file too: `~/.claude//CLAUDE.md`, `~/.claude/./CLAUDE.md` (these escape the `.claude/CLAUDE.md` fragment)"
**Legibility-target:** for-author

```python
HARD_FRAG = re.compile(
    r"\.claude/hooks(/|\b)|\.claude/settings|\.claude/CLAUDE\.md|managed-settings"
    r"|(?:" + "|".join(_GLOBAL_PREFIXES) + r")/CLAUDE\.md",
    re.I)
```

The prefix must be immediately followed by `/CLAUDE.md`. Any quote, `//`, `/./`, `..` or parameter-expansion modifier breaks the match. The old pattern `(^|[\s\"'=~/])CLAUDE\.md` matched all of these.

**Evidence:** `hooks/guard-trusted-writes.py:121-132`; `docs/reviews/execution-logs/cfc-r1-*`

---

## Claim 4: Bash `.claude/hooks|settings` fragments are HARD "global or project"

**Location:** `hooks/guard-trusted-writes.py:24-26`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers literal-fragment matching. It does not cover normalised or quoted variants.
**Replicate verdicts:** r1=— · r2=Verified (r2#5) · r3=Mostly accurate (r3#6)
**Replicate annotations:** r3: "`~/.claude//settings.json`, `~/.claude/./settings.json`, `~/\".claude\"/settings.json`, and `cd ~/.claude && … > settings.json` classify None (not even SOFT); gap predates the diff" · r2: "a project settings write is an ask via Edit/Write but a deny via Bash — confirmed"
**Legibility-target:** for-author

**Evidence:** `hooks/guard-trusted-writes.py:121-124`

---

## Claim 5: "HARD = the global config dir ($CLAUDE_CONFIG_DIR when set, else ~/.claude — the same {{CLAUDE_DIR}} hooks/wiring.json substitutes)"

**Location:** `hooks/guard-trusted-writes.py:10-12`, `:56-68`
**Type:** Configuration
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `_global_dirs()` compared with the wiring substitution in `devcontainer-config/link-claude-home.sh`. When `CLAUDE_CONFIG_DIR` is unset or equals `~/.claude`, the claim holds (r3#2a Verified).
**Replicate verdicts:** r1=Incorrect (r1#4) · r2=Mostly accurate (r2#1) · r3=Incorrect (r3#2b)
**Replicate annotations:** r1+r2+r3: "Code always keeps `~/.claude` and adds `$CLAUDE_CONFIG_DIR`; deny rules cover only `{{CLAUDE_DIR}}`. With the var set elsewhere, `~/.claude/settings*.json` and `~/.claude/hooks/**` are HARD → deferred → **no gate** (the state the Q-026 rationale says to avoid)" · r1+r2+r3: "hook expands leading `~` in the var (`os.path.expanduser`), linker does not" · r1+r3: "a relative `CLAUDE_CONFIG_DIR` stays unresolved in the given form and matches relative paths from any cwd"
**Legibility-target:** for-author

**Evidence:** `hooks/guard-trusted-writes.py:56-68`; `devcontainer-config/link-claude-home.sh`

---

## Claim 6: Commit 4c7a2bb "Global paths are unchanged" / "matching wiring.json"

**Location:** commit `4c7a2bb` message
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Immutable merged commit message. Refuted by Claims 1, 3 and 5.
**Replicate verdicts:** r1=Incorrect (r1#29a) · r2=Incorrect (r2#2b, counted separately in its summary) · r3=Mostly accurate (r3#26)
**Replicate annotations:** r3: "nested global paths `~/.claude/sub/settings.json`, `~/.claude/projects/x/CLAUDE.md` moved HARD→SOFT" · r1+r2+r3: "Accepted-immutable candidate"
**Legibility-target:** for-author

**Evidence:** commit 4c7a2bb message; `hooks/guard-trusted-writes.py:56-132`

---

## Claim 7: Project `.claude/` is SOFT for file tools, ask only when tainted

**Location:** `hooks/guard-trusted-writes.py:18-21`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the Edit/Write tier for project settings/hooks paths.
**Replicate verdicts:** r1=Verified (r1#6) · r2=Verified (r2#5) · r3=Verified (r3#4)
**Replicate annotations:** none
**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `hooks/guard-trusted-writes.py:100-109`

---

## Claim 8: `HOME="/"` would make the prefix empty and match any `/CLAUDE.md`

**Location:** `hooks/guard-trusted-writes.py:124`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the guard expression.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none
**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `hooks/guard-trusted-writes.py:124-125`

---

## Claim 9: Guard tests "14 new cases (40/40 pass)"

**Location:** commit 4c7a2bb
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** `bats test/hooks/guard-trusted-writes.bats` → 40/40.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2+r3: "no test covers the quoted/normalised Bash spellings or the symlinked-hooks layout"
**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `test/hooks/guard-trusted-writes.bats`; `docs/reviews/execution-logs/cfc-r1-bats-guard.txt`

---

## Claim 10: questions.sh resolves from the git toplevel of $PWD; $PWD outside git; QUESTIONS_* overrides

**Location:** `scripts/questions.sh:35-39,51-57`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers subdirectories, worktrees, nested repos, non-git directories and the overrides.
**Replicate verdicts:** r1=Verified (r1#17) · r2=Verified (r2#7) · r3=Mostly accurate (r3#16b)
**Replicate annotations:** r1+r3: "run from inside a `.git/` directory, `rev-parse --show-toplevel` fails and the fallback creates `.git/docs/working/`" · r3: "health-check pins its questions gate to this repo's files"
**Legibility-target:** for-author

**Evidence:** `scripts/questions.sh:51-57`; `docs/reviews/execution-logs/cfc-r1-si-questions-probe.txt`

---

## Claim 11: `questions.sh init` "never touches a file that exists"

**Location:** `scripts/questions.sh:314-331`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers existing regular files, which are untouched, and dangling symlinks.
**Replicate verdicts:** r1=Mostly accurate (r1#18) · r2=Mostly accurate (r2#8) · r3=Mostly accurate (r3#17)
**Replicate annotations:** r1+r2+r3: "`[[ -e ]]` is false for a dangling symlink; `>` writes through it, creating the target (possibly outside the project)"
**Legibility-target:** for-author

**Evidence:** `scripts/questions.sh:314-331`

---

## Claim 12: Installed path `~/.claude/scripts/questions.sh` / `lite-review.py` reachable from every project

**Location:** `global-instructions/CLAUDE.md:281`, `devcontainer-config/link-claude-home.sh:36`, `README.md`, `install.sh`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers linker entries and `test/link-claude-home-wiring.bats` (14/14).
**Replicate verdicts:** r1=Verified (r1#2,#3) · r2=Verified (r2#9) · r3=Verified (r3#1,#24)
**Replicate annotations:** none
**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `devcontainer-config/link-claude-home.sh:36`; `test/link-claude-home-wiring.bats`

---

## Claim 13: SI_RUN_ID "only [A-Za-z0-9._-] is accepted"; archive-working-docs.sh reads si-run-id.txt so the two agree

**Location:** `scripts/self-improvement.sh:451-463`; `scripts/archive-working-docs.sh:39-49`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the regex on both sides and the default-prefix fallback.
**Replicate verdicts:** r1=Verified (r1#9,#19,#20) · r2=Verified (r2#10) · r3=Verified (r3#9,#18a,#18b)
**Replicate annotations:** r1+r2+r3: "regex accepts `.`, `..`, `-rf`; harmless because of how the archive script builds and moves the name, not because of the check itself" · r3: "si-run-id.txt is not in PERMANENT, so the archive pass archives it too"
**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `scripts/self-improvement.sh:458-463`; `scripts/archive-working-docs.sh:43-49`

---

## Claim 14: `_migrate_hypothesis_log_run_column` — data rows untouched; no-op when Run present; "Checked at Round" never counts

**Location:** `scripts/lib/si-functions.sh:542-568`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the header/separator rewrite and idempotence.
**Replicate verdicts:** r1=Mostly accurate (r1#12, compound) · r2=Verified (r2#11) · r3=Verified (r3#13a)
**Replicate annotations:** r1: "mode 0600 after a real migration" (see Claim 15)
**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `scripts/lib/si-functions.sh:542-568`

---

## Claim 15: `_migrate_hypothesis_log_run_column` — "No-op when … no header is found"

**Location:** `scripts/lib/si-functions.sh:545-568`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers file identity and mode after the no-header path.
**Replicate verdicts:** r1=Mostly accurate (r1#12, compound) · r2=— · r3=Incorrect (r3#13b)
**Replicate annotations:** r1+r3: "file rewritten via `mktemp`+`mv` even with no header: new inode, mode 0600; every real migration also leaves `hypothesis-log.md` at 0600"
**Legibility-target:** for-author

**Evidence:** `scripts/lib/si-functions.sh:545-568`

---

## Claim 16: Absent Run cells are "unknown run", resolved newest-first; `_find_tasks_file` / `_live_run_matches` lookup order

**Location:** `scripts/lib/si-morning-summary.sh:1017` (`_live_run_matches`, `_find_tasks_file`)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the lookup order and the absent-cell fallback.
**Replicate verdicts:** r1=Mostly accurate (r1#13), Verified (r1#14) · r2=Mostly accurate (r2#12), Verified (r2#13) · r3=Verified (r3#12,#14)
**Replicate annotations:** r2: "rows whose hypothesis contains an escaped `\|` read the wrong cell as Run — an old row reads its Evidence value, a new row loses its run id; effect limited by newest-first fallback" · r1: "`_live_run_matches` is also true when si-run-id.txt exists but its first line is empty — unlisted case"
**Legibility-target:** for-author

**Evidence:** `scripts/lib/si-morning-summary.sh:1017`

---

## Claim 17: health-check gate 5 runs fast then slow; red fast blocks slow; recursion guard

**Location:** `scripts/health-check.sh:370-391` (gate 5); commit 0ccbdb8
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** `test/scripts/health-check.bats` 17/17. The full slow run was not executed.
**Replicate verdicts:** r1=Verified (r1#10) · r2=Verified (r2#14) · r3=Verified (r3#10,#11,#28)
**Replicate annotations:** none
**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `scripts/health-check.sh:378-391`; `docs/reviews/execution-logs/cfc-r1-bats-health-check.txt`

---

## Claim 18: `rubric.md#-must-address` anchor

**Location:** `workflows/pr-prep.md:190`, `workflows/review-fix-loop.md:43`
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers anchor generation, since the heading sits in a fenced block at `skills/code-review/references/rubric.md:31-158`. All other links added in the diff resolve.
**Replicate verdicts:** r1=Incorrect (r1#27) · r2=Incorrect (r2#18) · r3=Incorrect (r3#23)
**Replicate annotations:** r1: "`#deliverable-2-code-review-rubric` exists and is the likely target"
**Legibility-target:** for-author

**Evidence:** `skills/code-review/references/rubric.md:31-158`; `docs/reviews/execution-logs/cfc-r1-anchors.txt`

---

## Claim 19: test-strategy "P1 → 🟡, P2 and below → 🟢" contextual-critic mapping

**Location:** `skills/code-review/references/rubric.md:288-292` (also `:340`, `:504`, `skills/code-review/SKILL.md:1230`)
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the test-strategy output schema.
**Replicate verdicts:** r1=Incorrect (r1#22) · r2=— · r3=Incorrect (r3#20)
**Replicate annotations:** r1+r3: "test-strategy emits only `Priority: high/medium/low` (`skills/test-strategy/SKILL.md:196`); the mapped scale does not exist" · r1+r3: "hallucination-patterns.md candidate (entry proposed at end of r1/r3)"
**Legibility-target:** for-author

**Evidence:** `skills/test-strategy/SKILL.md:196`; `skills/code-review/references/rubric.md:288-292`

---

## Claim 20: performance-reviewer "Macro × Cold | Low (matches the hot-path gate; escalate when … runs over large data, e.g. a nightly batch)"

**Location:** `skills/performance-reviewer/SKILL.md:283` (gate at `:46`)
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** The default Low matches the gate. The large-data escalation does not appear in the gate.
**Replicate verdicts:** r1=Mostly accurate (r1#26) · r2=Mostly accurate (r2#16) · r3=Verified (r3#22a) / Mostly accurate (r3#22b)
**Replicate annotations:** none
**Legibility-target:** for-author

**Evidence:** `skills/performance-reviewer/SKILL.md:46`, `skills/performance-reviewer/SKILL.md:283`

---

## Claim 21: fact-check "a verdict resting only on `[abstract]` reads caps at Medium; High requires a `[deep-read]`"

**Location:** `skills/fact-check/SKILL.md:1`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers consistency across all restatements in the skill.
**Replicate verdicts:** r1=Verified (r1#25) · r2=Verified (r2#17) · r3=Verified (r3#21)
**Replicate annotations:** none
**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `skills/fact-check/SKILL.md`

---

## Claim 22: Doc cross-references (Disputed/Secondary-only Amber rows, self-eval repo-only, Accepted-immutable rows, rules 4/5 exhaustive, security-review Commit line, rubric archive gitignored)

**Location:** `skills/draft-review/SKILL.md:1`, `skills/self-eval/SKILL.md:1`, `skills/code-review/references/rubric.md:1`, `.gitignore:13`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the existence and consistency of the cited sections.
**Replicate verdicts:** r1=Verified (r1#21,#23,#24,#28) · r2=Verified (r2#19) · r3=Verified (r3#19)
**Replicate annotations:** none
**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `skills/draft-review/SKILL.md`, `skills/self-eval/SKILL.md`

---

## Claim 23: Commit test counts (794 ok at 5928c47; d659fa9 "test/skills: 656/656 pass"; a45f4a9 test list; archive README no callers)

**Location:** commit messages 5928c47, d659fa9, a45f4a9; `archive/failure-analysis/README.md:24-26`
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the static counts and the test lists. The d659fa9 656 pass count was not re-run (r1#30b Unverifiable: not run, to avoid disturbing the background loop).
**Replicate verdicts:** r1=Verified (r1#1,#30a,#31) / Unverifiable (r1#30b) · r2=Verified (r2#15) · r3=Verified (r3#27)
**Replicate annotations:** r1: "656 pass not executed"
**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `archive/failure-analysis/README.md:24-26`

---

## Claim 24: lite-review.py "a --bare call on a subscription-only machine prints 'Not logged in' and still exits 0"

**Location:** `scripts/lite-review.py:1` (module docstring)
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Would need a live subscription `claude` call, and the sandbox has no egress. It was confirmed only that the call omits `--bare` (r1#15 Verified).
**Replicate verdicts:** r1=Unverifiable (r1#16) · r2=Unverifiable (r2#20) · r3=Unverifiable (r3#15)
**Replicate annotations:** none
**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `scripts/lite-review.py`

---

## Submitted Claims

## Claim 25: "SI_RUN_ID is validated with the same regex both where it is written (scripts/self-improvement.sh) and where archive-working-docs.sh reads it back, and neither accepts `/`, so archive names cannot escape `archive/`."

**Submitted by:** security-reviewer
**Location:** `scripts/self-improvement.sh:458-463`, `scripts/archive-working-docs.sh:43-49,58`; related reader `scripts/lib/si-morning-summary.sh:1017,1159-1190,1330-1346`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the regex at both sites, the `dest=` construction in archive-working-docs.sh, and the Run-cell read paths in si-morning-summary.sh. It does not cover the explicit CLI `PREFIX` argument of archive-working-docs.sh. That argument is unvalidated and was just as unvalidated at e8d5fa1 (`*) PREFIX="$arg"`), so it is outside this claim.
**Legibility-target:** the security-reviewer's "What Looks Good" endorsement of SI_RUN_ID sanitization

**The part about the write path is correct.** Both sites use the identical literal `^[A-Za-z0-9._-]+$` (self-improvement.sh:459, archive-working-docs.sh:45). The writer exits 1 on a mismatch before `printf '%s\n' "$SI_RUN_ID" > .../si-run-id.txt` (:463). The reader falls back to the date when the id doesn't match, and then builds `dest="$ARCHIVE_DIR/${PREFIX}-${name}"` (:58).

Executed: `bash sub/runid-regex-probe.txt` (cwd scratchpad, bash from the container, locale C/C.UTF-8; en_US.UTF-8 is not installed and falls back to C). Output is in `runid-regex-probe.out.txt`:
- Rejected: `../x`, `a/b`, `a\nb`, `a\r`, `é`, fullwidth `ａ`, `~`, empty, `a b`.
- Accepted: `..`, `.`, `-rf`, `2026-09-21`.

`..` is accepted, but it can't traverse, because the name always gets `-${name}` appended.

Executed: `bash sub/archive-runid-probe.txt`, which runs the real `scripts/archive-working-docs.sh` in throwaway dirs with a planted `si-run-id.txt`. Output is in `archive-runid-probe.out.txt`:
- id `..` → `docs/working/archive/..-plan-foo.md`. The file stays inside `archive/`.
- id `../../evil` → rejected. The script fell back to the date prefix (`2026-09-22-…` under TZ=UTC).
- id `ok-run` → `archive/ok-run-plan-foo.md`.

All three exited 0.

**Why the verdict is only "mostly accurate".** The other reader builds paths from the hypothesis-log **Run cell** without any validation. `row_run=$(_pick_col fields "$run_col")` (si-morning-summary.sh:1017) goes unchanged into:
- `_find_tasks_file` → `"$working_dir/archive/${run}-tasks-round-$round.json"` (:1181)
- `_days_since_round` → `"$working_dir/archive/${run}-round-$round-report.json"` (:1337)

Read `_find_tasks_file` whole (:1170-1190) and `_days_since_round` (:1329-1370). Both use the path only for `[ -f ]` and `jq` reads. Nothing writes to it.

Executed: `bash sub/morning-run-cell-probe.txt`, which sources the real lib and plants `outside/x-tasks-round-3.json` outside `archive/`. Output is in `morning-run-cell-probe.out.txt`. With a Run cell of `../../outside/x`, `_find_tasks_file` returned `.../w/archive/../../outside/x-tasks-round-3.json`, and `_resolve_hypothesis_target` then reported `skill:foo` from that out-of-tree file.

So archive **names** can't escape `archive/`, as the claim says. The morning summary, though, can be pointed at files outside `archive/` for **reading** by editing the Run cell in `hypothesis-log.md`. The loop itself fills that cell from the validated `$SI_RUN_ID` (self-improvement.sh:1874). The exposure is read-only and needs the repo-tracked log to be edited. That is low severity. The simple fix is to apply the same regex to `row_run`, or drop it when it doesn't match.

Side note: `si-run-id.txt` is not in archive-working-docs.sh's `PERMANENT` list, so an archive run moves it too (`archive/<id>-si-run-id.txt` in both probe outputs). `_live_run_matches` then treats a missing file as "matches" (:1152). That looks intended, but it isn't written down.

**Evidence:** `scripts/self-improvement.sh:458-463`, `scripts/archive-working-docs.sh:43-49,58`, `scripts/lib/si-morning-summary.sh:1017,1150-1190,1329-1346`, probe outputs `runid-regex-probe.out.txt`, `archive-runid-probe.out.txt`, `morning-run-cell-probe.out.txt`

---

## Claim 26: "Project `.claude/` paths (settings*.json, hooks/**) now get an 'ask' through the file tools in tainted sessions, where before they got no gate."

**Submitted by:** security-reviewer
**Location:** `hooks/guard-trusted-writes.py:80-109` (classify_path), `:172-184` (main file-tool branch); baseline `git show e8d5fa1:hooks/guard-trusted-writes.py:41-68,124-136`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the Write tool on project and global `.claude/{settings.json, settings.local.json, hooks/x.sh, CLAUDE.md, notes.md}`, in tainted and clean sessions, for both hook versions, with `CLAUDE_CONFIG_DIR` unset. Edit and MultiEdit take the same branch (:172) and were read, not run. "No gate" here means that neither the hook nor the `hooks/wiring.json` deny rules gated these paths. Claude Code's own built-in permission prompts and any user allow rules are outside this claim and were not assessed.
**Legibility-target:** the security-reviewer's endorsement of the Q-026 tier change

**Before (e8d5fa1).** classify_path matched any `.claude` segment followed by `hooks`, any `settings*.json` under a `.claude` segment, and any `claude.md` under `.claude` as **hard**, whether global or project (old :49-56). main then `defer()`ed on hard (old :129-132). That left the path to the deny rules. But `hooks/wiring.json:120-127` names only `{{CLAUDE_DIR}}/…` and `~/CLAUDE.md`, so a project `.claude/settings.json` fell through both the hook and the deny list.

**After.** Hard now applies only to paths relative to `GLOBAL_DIRS` (:56-78, :88-95). A project `.claude/` path falls through to `if ".claude" in low: return "soft"` (:107-108). That returns `ask` when the session is tainted (:181-183).

Executed: `bash sub/guard-project-claude-probe.txt` (fake HOME, `CC_WEB_TAINT_DIR` with session `sess1` marked tainted, `CLAUDE_CONFIG_DIR` unset). Output is in `guard-project-claude-probe.out.txt`:

| path | old tainted | new tainted | new clean |
|---|---|---|---|
| project `.claude/settings.json` | defer (no output) | **ask** | defer |
| project `.claude/settings.local.json` | defer | **ask** | defer |
| project `.claude/hooks/x.sh` | defer | **ask** | defer |
| project `.claude/CLAUDE.md` | defer | **ask** | defer |
| project `.claude/notes.md` | ask | ask | defer |
| global `.claude/settings.json`, `hooks/x.sh`, `CLAUDE.md` | defer | defer | defer |

The claim is accurate, including the qualifier "in tainted sessions". Clean sessions still defer, and global HARD paths still defer to the deny rules and never ask. The old behaviour was therefore "hook defers, and no deny rule matches". It was not an ask or a deny.

**Evidence:** `hooks/guard-trusted-writes.py:56-109,172-184`, `git show e8d5fa1:hooks/guard-trusted-writes.py` lines 41-68 and 124-136, `hooks/wiring.json:120-127`, `guard-project-claude-probe.out.txt`

---

## Claim 27: "The new hook adds only ~1–2 ms per call over the pre-diff hook on ~20 ms python startup."

**Submitted by:** performance-reviewer
**Location:** `hooks/guard-trusted-writes.py:56-69` (`_global_dirs()` evaluated at import as `GLOBAL_DIRS`)
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Per-invocation wall time of the whole hook subprocess. Two payloads: a Write to a project `.claude/settings.json` in a tainted session, and a Bash `echo hi > out.txt`. Tested with `CLAUDE_CONFIG_DIR` unset and set. This is one 16-core WSL2 host with load around 2–3, Python 3.11.2. The fake HOME is shallow, so `resolve()` had no symlinks to follow. Deep or network-mounted HOME paths were not tested.
**Legibility-target:** the performance-reviewer's "What Looks Good" endorsement of hook overhead

Executed: `python3 sub/guard-bench.py.txt 150` (cwd scratchpad). It runs old and new interleaved, N=150 each, with a hermetic HOME and taint dir. Output is in `guard-bench.out.txt`:

| case | old median | new median | delta |
|---|---|---|---|
| no CLAUDE_CONFIG_DIR, Write project settings | 17.62 ms | 17.98 ms | +0.36 ms |
| no CLAUDE_CONFIG_DIR, Bash echo | 17.09 ms | 16.92 ms | −0.17 ms |
| CLAUDE_CONFIG_DIR set, Write project settings | 17.92 ms | 18.16 ms | +0.24 ms |
| CLAUDE_CONFIG_DIR set, Bash echo | 18.64 ms | 18.44 ms | −0.19 ms |

- The `_global_dirs()` body costs about 34 µs per call in-process.
- Bare `python3 -c pass` takes a median of 6.41 ms.
- The p10–p90 spread (about 15–25 ms) is far wider than any delta.

The claim's direction holds: the overhead is negligible. It overstates the size, though. The measured delta is ≤0.4 ms and inside the noise, not about 1–2 ms. A whole hook call is about 17–18 ms, and bare interpreter startup is about 6 ms, not about 20 ms. As an upper bound the claim is safe. The two figures should be corrected to "<0.5 ms, noise-level, on ~17 ms per call".

**Evidence:** `hooks/guard-trusted-writes.py:56-78`, `guard-bench.py.txt`, `guard-bench.out.txt`

---

### Submitted claims requiring attention
- **Claim 25** (`scripts/lib/si-morning-summary.sh:1017,1181,1337`): the writer and the archive reader are both correct, but the morning summary builds read paths from the unvalidated hypothesis-log Run cell. A cell like `../../x` makes it read files outside `archive/`. Apply the same `^[A-Za-z0-9._-]+$` check to `row_run`.
- **Claim 27** (`hooks/guard-trusted-writes.py:56-69`): the overhead is overstated. It measures ≤0.4 ms (noise), and a hook call is about 17 ms, not about 20 ms.

---

(Appended from `code-fact-check-submitted-claims.md`, Stage 2.5, k=1.)

---

## Claims Requiring Attention

### Incorrect
- **Claim 1** (`hooks/guard-trusted-writes.py:80-109`): in the installed symlinked layout, file tools ask on global HARD paths spelled with `..` or reached through a symlinked project `.claude`.
- **Claim 3** (`hooks/guard-trusted-writes.py:121-132`): Bash writes to the global memory file via quoted, `//`, `/./`, `..` or `${HOME:-}` spellings are no longer denied.
- **Claim 5** (`hooks/guard-trusted-writes.py:56-68`): the hook always includes `~/.claude` while the deny rules name only `$CLAUDE_CONFIG_DIR`, so there is no gate when the variable is set elsewhere.
- **Claim 6** (commit 4c7a2bb): "Global paths are unchanged" is refuted. The commit is immutable.
- **Claim 15** (`scripts/lib/si-functions.sh:545`): the no-header path is not a no-op; it rewrites the file with mode 0600.
- **Claim 18** (`workflows/pr-prep.md:190`, `workflows/review-fix-loop.md:43`): the anchor `rubric.md#-must-address` is dead.
- **Claim 19** (`skills/code-review/references/rubric.md:288-292`): test-strategy has no P1/P2 scale.

### Mostly Accurate
- Claims 4, 10, 11, 16, 20 (see sections)

### Unverifiable
- Claim 24 (`scripts/lite-review.py`): needs a live subscription call.

### Submitted claims requiring attention
- **Claim 25** (`scripts/lib/si-morning-summary.sh:1017,1181,1337`): the writer and the archive reader are both correct, but the morning summary builds read paths from the unvalidated hypothesis-log Run cell. A cell like `../../x` makes it read files outside `archive/`. Apply the same `^[A-Za-z0-9._-]+$` check to `row_run`.
- **Claim 27** (`hooks/guard-trusted-writes.py:56-69`): the overhead is overstated. It measures ≤0.4 ms (noise), and a hook call is about 17 ms, not about 20 ms.

---

(Appended from `code-fact-check-submitted-claims.md`, Stage 2.5, k=1.)

---

## Claims Requiring Attention

- **Incorrect:** Claims 1, 3, 5 (guard hook security), 6 (immutable commit message), 15, 18, 19
- **Mostly accurate:** Claims 4, 10, 11, 16, 20
- **Unverifiable:** Claim 24
- **Submitted (Stage 2.5):** Claim 25 Mostly accurate (morning-summary Run cell unvalidated in path build), Claim 26 Verified (executed), Claim 27 Mostly accurate

## Escalations

- `hooks/guard-trusted-writes.py:80-109`: the file-tool ask on global HARD paths via symlinked hooks and `..` (Claim 1). Raised by r1 and r2. Addressee: security-reviewer.
- `hooks/guard-trusted-writes.py:121-129`: Bash global-CLAUDE.md bypass spellings (Claim 3). Raised by r1, r2 and r3. Addressee: security-reviewer.
- `hooks/guard-trusted-writes.py:56-68`: `CLAUDE_CONFIG_DIR` leaves `~/.claude` ungated (Claim 5). Raised by r3 and r1. Addressee: security-reviewer.
- `docs/reviews/hallucination-patterns.md`: append the Claim 19 entry proposed in r1 and r3. Raised by r1 and r3. Addressee: orchestrator.
- Commit 4c7a2bb message: Accepted-immutable override-log row (Claim 6). Raised by r1, r2 and r3. Addressee: orchestrator.

## Verdict stability

- Clusters: 24
- All reporting replicates agreed: 17
- Disagreed (7):
  - C1: r1 Incorrect, r2 Incorrect, r3 Verified. The layout differed: r3 used a synthetic fakehome.
  - C4: r2 Verified, r3 Mostly.
  - C5: r1 Incorrect, r2 Mostly, r3 Incorrect.
  - C6: r1 Incorrect, r2 Incorrect, r3 Mostly.
  - C10: r1 Verified, r2 Verified, r3 Mostly.
  - C14 and C15: r1 compound Mostly, r3 split.
  - C16: mixed within replicates.
  - C20: r3 split.
- Agreement rate: 17/24 = 71%. This is below the 90% threshold at which k could drop.

## Goal-Alignment Note
- Success criterion (restated verbatim): Merged canonical fact-check report from k=3 replicates.
- Answered: yes. All three replicates were substantive and merged.
- Out of scope: the full test/skills run (d659fa9 656 pass) was not executed.
- Escalate: see `## Escalations`.
