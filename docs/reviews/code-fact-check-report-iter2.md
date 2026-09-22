# Code Fact-Check Report

**Commit:** 16f2978
**Replication:** k=3

**Repository:** /workspace (claude-workflows)
**Scope:** partial — `git diff f023357..answers-2026-09-20` (review-fix iteration 2 fix commits; 23 files). Commits before f023357 are context only.
**Checked:** 2026-09-21
**Total claims checked:** 29
**Summary:** 13 verified, 10 mostly accurate, 1 stale, 5 incorrect, 0 unverifiable

Merged most-severe-wins by the code-review orchestrator from `code-fact-check-report-iter2-r1.md`, `-r2.md`, `-r3.md` (all `Commit: 16f2978`). Iteration-1 artifacts (`code-fact-check-report.md`, `-r1/-r2/-r3.md` at 654c0ed) were left in place for audit rather than overwritten; this run's files carry the `-iter2` infix. Probe outputs live under the session scratchpad (`cfc-r1/`, `cfc-r2/`, `cfc-r3/`). Evidence below is the winning replicate's; see the replicate reports for full probe transcripts.

---

## Claim 1: c5a7c96 — "the global CLAUDE.md tier no longer depends on exact path spellings … The residual: shell obfuscation of the file name itself (CLAUDE.m*, C${x}.md) and A8 primitives are still unguarded."

**Location:** commit c5a7c96 message; code `hooks/guard-trusted-writes.py:166-205`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the completeness of the stated residual. Does not cover the accepted filename-obfuscation residual or Q-048's false denies.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Incorrect · r2=Incorrect · r3=Incorrect
**Replicate annotations:** r1+r2+r3: "bare `cd` to home (`cd; echo x > CLAUDE.md`, `cd && …`) and `/home/$USER/CLAUDE.md` get no opinion" · r1+r2+r3: "obfuscating the `.claude` *directory* (`~/.clau*/settings.json`, `~/.cl""aude/…`, `~/.cl?ude/hooks`, `~/.clau\de/`, `D=.cl; ~/${D}aude/…`) gets no opinion; settings/hooks cases match no SOFT fragment, so they are ungated even when tainted" · r2: "quoting inside file names (`~/.claude/set\tings.json`, `hoo"ks"`, `~/.claude/"settings".json`) gets no opinion" · r1: "`echo x > /opt/claude-workflows/hooks/g.py` defers; the commit's 'installed /opt payload is unaffected' may rest on it being root-owned, not checked" · r3: "`cd /home && echo x > tester/CLAUDE.md`, `/home/*/CLAUDE.md`" · r1+r2+r3: "commit already merged into the branch via 1759fc8 — immutable-history exception may apply to the message; the bypasses are live in code"

All 13 listed spellings do deny (Claim 16), but the co-occurrence rule still keys on a literal indicator token. Probe (r1, `cfc-r1/probe-bash.out`):
```
defer  | echo x > /home/$USER/CLAUDE.md
defer  | cd; echo x > CLAUDE.md
defer  | echo x > ~/.clau*/settings.json
defer  | cp y ~/.cl*/hooks/x.sh
defer  | cd ~/.cl""aude && echo {} > settings.json
defer  | echo x > /opt/claude-workflows/hooks/g.py
```

**Evidence:** `hooks/guard-trusted-writes.py:166-205`; replicate probe logs.

---

## Claim 2: c5a7c96 — "Tests: 18 new bats cases"

**Location:** commit c5a7c96 message; `test/hooks/guard-trusted-writes.bats:301-456`
**Type:** Numerical
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count of new `@test` blocks in the commit.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Incorrect · r2=Incorrect · r3=Incorrect
**Replicate annotations:** r2: "matches a count-mismatch pattern already in hallucination-patterns.md; not added (tracked-file edit forbidden)"

`git show c5a7c96 -- test/hooks/guard-trusted-writes.bats | grep -c '^+@test'` → 14.

**Evidence:** `git show c5a7c96`

---

## Claim 3: c5a7c96 — "every new R-test fails against the pre-fix hook"

**Location:** commit c5a7c96 message; `test/hooks/guard-trusted-writes.bats`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers running the new bats file against `c5a7c96^:hooks/guard-trusted-writes.py`.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Incorrect · r2=Incorrect · r3=Incorrect
**Replicate annotations:** r1: "the 4 passing are R1 heredoc, R1 bare-SOFT, R3 empty CLAUDE_CONFIG_DIR, R4 real project .claude" · r2: "the listed Bash spellings themselves all got no opinion from the pre-fix hook — the load-bearing tests do fail pre-fix"

4 of 14 new tests pass against the pre-fix hook (tests 39, 40, 43, 49). They are regression-guard/negative tests, not reproductions.

**Evidence:** replicate runs against `c5a7c96^`.

---

## Claim 4: questions.sh — "Writes never go through a symlink." / refuse a destination that "is, or resolves through, a symlink"

**Location:** `scripts/questions.sh:47-51`, `:84-94`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the symlink check's reach (file and immediate directory only). Does not establish an exploit for default paths: containment still refuses default paths that resolve outside the toplevel (Claim 18).
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Incorrect · r3=Incorrect
**Replicate annotations:** r2+r3: "with QUESTIONS_LIVE/QUESTIONS_ARCHIVE overrides whose grandparent (`docs -> ../elsewhere`) is a symlink, `init` exits 0 and creates both files outside the repo" · r2: "a symlinked `docs/` pointing inside the repo is written through with default paths" · r1: "overrides are operator-chosen and exempt from containment by design (a5c2a2c Notes); the claim text is broader than the code"

**Evidence:** `scripts/questions.sh:92-94` checks `-L "$file"` and `-L "$(dirname "$file")"` only.

---

## Claim 5: Q-048 — "a write that names `CLAUDE.md`, `settings*.json` or `hooks` is denied whenever the command also contains `~`, `$HOME`, `.claude`, `global-instructions` …" and the `git commit … HEAD~1` example

**Location:** `docs/working/questions.md:38` (Q-048)
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers Q-048's description of the rule against `hooks/guard-trusted-writes.py:176,200`.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Incorrect · r2=— · r3=Mostly accurate
**Replicate annotations:** r1+r3: "for settings*.json/hooks only `.claude` or the config dir triggers deny, not `~`/`$HOME`/`global-instructions` (`echo x > ~/foo/settings.json` → no decision)" · r1+r3: "`git commit -m '… CLAUDE.md … HEAD~1'` is not denied — only a command with a write primitive is; Q-048 dropped the word 'write' that c5a7c96's Notes carry" · r1: "the user will answer Q-048 from this description — fix before they answer"

**Evidence:** `hooks/guard-trusted-writes.py:176,200`; `cfc-r1/` probes.

---

## Claim 6: override-log.md 4c7a2bb row — "Refuted at `hooks/guard-trusted-writes.py:56-132`: the Bash HARD tier … now matches only literal spellings … Live defects are R1/R4"

**Location:** `docs/reviews/override-log.md:82`
**Type:** Reference
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the row's present-tense description against the current file.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Stale · r2=— · r3=— · single-replicate detection
**Replicate annotations:** r1: "pin the reference to `4c7a2bb:` and use past tense; the line range and 'now' describe the pre-c5a7c96 file"

**Evidence:** `docs/reviews/override-log.md:82`; `hooks/guard-trusted-writes.py` at HEAD.

---

## Claim 7: "HARD = exactly what permissions.deny covers (hooks/wiring.json)"

**Location:** `hooks/guard-trusted-writes.py:10-21`, `:105`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the HARD set vs wiring.json deny rules. Does not establish how Claude Code's deny matcher treats case or symlinks (not testable here).
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r1+r2+r3: "HARD is a superset: case-insensitive matching (`SETTINGS.JSON`, `~/.claude/HOOKS/x`) and resolved `/opt` link targets are HARD, so the hook defers on paths no deny rule names" · r3: "`~/.claude/HOOKS/x` went from ask to no opinion" · r2 (escalation, unverified — no network): "Claude Code's permission docs may treat a rule path with a single leading `/` as relative to the settings file and `//` as absolute; if so the substituted `Edit(/home/node/.claude/…)` deny rules may not match, undercutting the 'deny rules do the blocking' premise — needs a live check" · r1: "nothing regressed vs e8d5fa1 on case-sensitive filesystems"

**Evidence:** `hooks/guard-trusted-writes.py:10-21,105`; `hooks/wiring.json:120-127`.

---

## Claim 8: config_dir() — "exactly what the linker substitutes as {{CLAUDE_DIR}}"

**Location:** `hooks/guard-trusted-writes.py:63-74`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers empty, `~`-prefixed and relative CLAUDE_CONFIG_DIR values.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r1+r2+r3: "a relative value is anchored at the hook's cwd with abspath; the linker writes the string verbatim — the docstring itself discloses this" · r2: "empty and `~` values match the linker"

**Evidence:** `hooks/guard-trusted-writes.py:63-74`; `devcontainer-config/link-claude-home.sh:36`.

---

## Claim 9: questions.sh init — "create with noclobber, whose O_EXCL open fails rather than following anything that appeared at the path in between"

**Location:** `scripts/questions.sh:428-430`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers noclobber's behaviour on a symlink raced into place. Does not establish a practical exploit (needs a concurrent local attacker, out of threat model per a5c2a2c).
**Legibility-target:** for-author
**Replicate verdicts:** r1=Verified · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r2+r3: "bash noclobber follows a symlink to an existing non-regular file (`echo x > link-to-/dev/null` exits 0)"

**Evidence:** `scripts/questions.sh:428-430`.

---

## Claim 10: si_default_run_id — "Zero-padded fields keep ids lexically sortable in start order, which _archived_newest_first relies on."

**Location:** `scripts/lib/si-functions.sh:466-470`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers ordering among new ids and on the legacy transition day.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Verified · r2=Mostly accurate · r3=Verified
**Replicate annotations:** r2: "on a day with both a legacy date-only id and a timestamped id, `YYYY-MM-DD-tasks…` sorts after `YYYY-MM-DD-HHMMSS-tasks…` (disclosed in 14bfbdd Notes)"

**Evidence:** `scripts/lib/si-functions.sh:466-470`.

---

## Claim 11: "si_default_run_id below"

**Location:** `scripts/lib/si-functions.sh:481`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the comment's pointer only.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=— · r3=— · single-replicate detection
**Replicate annotations:** r1: "defined above, at `:469`"

**Evidence:** `scripts/lib/si-functions.sh:469,481`.

---

## Claim 12: "ASCII Record Separator: never present in a log row"

**Location:** `scripts/lib/si-morning-summary.sh:1527`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers whether the writer enforces the invariant.
**Legibility-target:** for-author
**Replicate verdicts:** r1=— · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r2+r3: "assumed, not enforced — the writer escapes only `|`"

**Evidence:** `scripts/lib/si-morning-summary.sh:1527`; `append_approved_hypotheses` in `scripts/lib/si-functions.sh`.

---

## Claim 13: "Locals carry a _srf_ prefix so a caller array … is not shadowed through the nameref"

**Location:** `scripts/lib/si-morning-summary.sh:1522`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers nameref collision.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Verified · r3=Verified
**Replicate annotations:** r1: "the nameref itself (`out_ref`) has no `_srf_` prefix, so a caller array named `out_ref` collides (circular-reference warnings; fields still returned)"

**Evidence:** `scripts/lib/si-morning-summary.sh:1522`.

---

## Claim 14: 685030e — "Awk failure now propagates as the return code instead of being swallowed."

**Location:** commit 685030e; `scripts/lib/si-functions.sh:545-575`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the detection awk's failure path.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=— · r3=—  · single-replicate detection
**Replicate annotations:** r1: "a failure in the detection awk exits 2, the same code as the no-header sentinel, so the function returns 0 (confirmed with an unreadable log)"

**Evidence:** `scripts/lib/si-functions.sh` migration function; `cfc-r1/si-probe` output.

---

## Claim 15: bd07c4e — "health-check.bats cache hit (405s -> 42s) … Coverage unchanged"

**Location:** commit bd07c4e; `test/scripts/health-check.bats:20-25`; `docs/working/questions-archive.md:833`
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the cache mechanism and wall time on this host.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Verified · r3=Mostly accurate
**Replicate annotations:** r1+r2+r3: "mechanism correct: 17 tests, 3 real script runs, `$$` differs per test" · r1: "60s here" · r2: "54s" · r3: "59s" — timing varies with contention

**Evidence:** `test/scripts/health-check.bats:20-25`.

---

## Claim 16: c5a7c96 — every listed R1/A10 spelling is denied

**Location:** `hooks/guard-trusted-writes.py:166-205`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the 13 spellings named in the commit plus the bats file's extras. Does not establish completeness (Claim 1).
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

**Evidence:** replicate probe logs.

---

## Claim 17: R4 — file tools HARD on lexical, normpath and resolve(); installed-layout fixture matches link-claude-home.sh

**Location:** `hooks/guard-trusted-writes.py:80-130`; `test/hooks/guard-trusted-writes.bats`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `~/.claude/x/../CLAUDE.md`, symlinked hooks/CLAUDE.md into a payload dir, and a project `.claude` symlinked to `~/.claude`; never returns ask on global paths in the fixture.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: "if a checkout of this repo is the payload ~/.claude links to, its hooks/ and CLAUDE.md now defer (disclosed)"

**Evidence:** `hooks/guard-trusted-writes.py:80-130`.

---

## Claim 18: questions.sh containment, dangling-link refusal, missing-file errors, `.git` refusal

**Location:** `scripts/questions.sh:84-130`, `:329`, `:369`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers default paths resolving outside the toplevel, dangling links, missing files for next-id/index/archive/open/check, and cwd inside `.git`.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

**Evidence:** `test/questions-doc.bats` 26/26; replicate probes.

---

## Claim 19: `replace_with` — mktemp in target dir, target mode, symlink re-check, rename

**Location:** `scripts/questions.sh` (`replace_with`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers mode preservation and no leftover temp files.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

**Evidence:** replicate probes.

---

## Claim 20: 42bf2fc — "check reads index ids from the first column only"

**Location:** `scripts/questions.sh` (`check`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a summary quoting another entry id.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

**Evidence:** `test/questions-doc.bats`.

---

## Claim 21: 685030e (R5) — "True no-op … when the header already has a Run cell or no header is found. A real migration rewrites the file in place" keeping inode and mode

**Location:** `scripts/lib/si-functions.sh:545-575`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers no-op paths and inode/mode on migration. Awk-failure path is Claim 14.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: "mode and no-header tests fail on pre-fix code, as the commit says"

**Evidence:** `test/append-approved-hypotheses.bats`.

---

## Claim 22: `_live_run_matches` false when si-run-id.txt absent/empty; fallbacks still reach live files

**Location:** `scripts/lib/si-morning-summary.sh`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the truth table and the archived-si-run-id case.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

**Evidence:** `test/precondition-gate.bats`.

---

## Claim 23: `_valid_run_id` applied at the row reader, `_find_tasks_file`, `_days_since_round`

**Location:** `scripts/lib/si-morning-summary.sh:1145-1152` and call sites
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three readers. The claim's framing that archive-working-docs.sh "enforces" the charset is partial.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Verified · r2=Mostly accurate · r3=Verified
**Replicate annotations:** r2: "archive-working-docs.sh validates the charset only on the si-run-id.txt default; an explicit command-line prefix is not validated (`scripts/archive-working-docs.sh:33`)"

**Evidence:** `scripts/lib/si-morning-summary.sh:1145-1152`; `scripts/archive-working-docs.sh:33`.

---

## Claim 24: e6a6a5f — escaped pipes survive the split and are restored

**Location:** `scripts/lib/si-morning-summary.sh:1515-1540`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers piped hypothesis rows' cell alignment. Sentinel and nameref caveats are Claims 12, 13.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

**Evidence:** `test/morning-summary-clusters.bats`.

---

## Claim 25: managed-settings.json moving to SOFT for file tools is not a regression

**Location:** `hooks/guard-trusted-writes.py:10-30`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers file-tool tier before/after.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2: "before it was ungated (defer, no deny rule); now asks when tainted"

**Evidence:** replicate probes.

---

## Claim 26: A1 — `### Qualifying author note` anchor resolves from pr-prep.md and review-fix-loop.md

**Location:** `skills/code-review/references/rubric.md:156-160`; `workflows/pr-prep.md:190`; `workflows/review-fix-loop.md:43`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the external links (resolve) and the in-template link.
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Verified · r3=Verified
**Replicate annotations:** r1: "the in-template `(#qualifying-author-note)` sits inside the template's code fence (lines 31–157), so it is dead in every emitted rubric file"

**Evidence:** `skills/code-review/references/rubric.md:31-160`.

---

## Claim 27: A2/A13 — test-strategy mapped by high/medium/low everywhere; hot-path gate and Macro × Cold row agree

**Location:** `skills/code-review/references/rubric.md`, `skills/code-review/SKILL.md`, `skills/performance-reviewer/SKILL.md`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every repeated occurrence.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

**Evidence:** grep across the three files.

---

## Claim 28: A5 — override-log.md defines the Accepted-immutable row kind consistently with the canonical definition

**Location:** `docs/reviews/override-log.md:6-47`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the definition text; the 4c7a2bb row's staleness is Claim 6.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

**Evidence:** `docs/reviews/override-log.md`; `skills/code-review/references/override-log.md`.

---

## Claim 29: "Discoverable TODO: `# TODO(A8)` at WRITE_PRIMITIVE lists every command."

**Location:** `docs/reviews/override-log.md:80`; `hooks/guard-trusted-writes.py` (WRITE_PRIMITIVE)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers presence and completeness of the TODO list.
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

**Evidence:** `hooks/guard-trusted-writes.py` WRITE_PRIMITIVE block.

---

## Claims Requiring Attention

- Incorrect: 1 (Bash residual bypasses), 2 (test count), 3 (pre-fix failure claim), 4 (questions.sh symlink claim), 5 (Q-048 wording)
- Stale: 6 (override-log 4c7a2bb row)
- Mostly accurate: 7, 8, 9, 10, 11, 12, 13, 14, 15, 23, 26

## Escalations

- `hooks/guard-trusted-writes.py:166-205` — Claim 1's live Bash bypasses (bare `cd`, `/home/$USER`, obfuscated `.claude` directory, in-name quoting, `/opt` payload). Raised by r1, r2, r3. Addressee: security-reviewer.
- `hooks/wiring.json:120-127` — possible deny-rule path syntax problem (single `/` vs `//`), unverified, no network. Raised by r2. Addressee: security-reviewer / orchestrator (host check).
- `docs/working/questions.md:38` — fix Q-048's description before the user answers it. Raised by r1. Addressee: orchestrator.
- `docs/reviews/hallucination-patterns.md` — Claim 2 count mismatch not logged. Raised by r2. Addressee: orchestrator.
- Claims 1–3 live in merged commit c5a7c96: decide on the immutable-history exception. Raised by r1, r3. Addressee: orchestrator.

## Verdict stability

- Total clusters: 29
- All reporting replicates agreed: 19
- Disagreed: 10 — Claim 4 (r1 Mostly / r2,r3 Incorrect), 5 (r1 Incorrect / r3 Mostly), 9 (r1 Verified / r2,r3 Mostly), 10 (r2 Mostly / r1,r3 Verified), 12 (r2,r3 Mostly / r1 —), 13 (r1 Mostly / r2,r3 Verified), 15 (r2 Verified / r1,r3 Mostly), 23 (r2 Mostly / r1,r3 Verified), 26 (r1 Mostly / r2,r3 Verified), plus single-replicate detections 6, 11, 14 counted as agreement-by-default
- Agreement rate: 19/29 ≈ 66% (the disagreements are almost all Verified↔Mostly-accurate on caveat detection; the four Incorrect-headline clusters 1–3 were unanimous)

## Goal-Alignment Note
- Success criterion (restated verbatim): merged canonical report of the three replicates for iteration 2.
- Answered: yes — mechanical most-severe-wins merge; annotations unioned.
- Out of scope: pre-f023357 commits.
- Escalate: see ## Escalations.

---

## Submitted Claims

## Claim 30: "Every R1/A10 spelling listed in commit c5a7c96, plus `cd ~/.claude && cp -r /tmp/p/hooks .`, `echo x > "${HOME}"/.claude/"hooks"/g.py`, `exec 3> ~/.claude/settings.json` and `echo x >| ~/CLAUDE.md`, returns deny from the repo hook."

**Submitted by:** security-reviewer
**Location:** `hooks/guard-trusted-writes.py:190-205`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the 13 spellings named in the c5a7c96 message, each wrapped in a write primitive (`echo x > …` where the message gives only the path), plus the 4 added spellings, all with `CLAUDE_CONFIG_DIR` unset. It does not establish behavior when `CLAUDE_CONFIG_DIR` is set, for spellings outside this list (for example `$USER`-based home, `/root`, globbing `.clau*`, or obfuscation of the file name itself, which c5a7c96 names as residual), or for write primitives the hook does not recognise (A8).

All 17 commands returned `permissionDecision: "deny"` with rc 0. Excerpt from `$S/out30.txt`:

```
rc=0 deny               | echo x > "$HOME"/CLAUDE.md
rc=0 deny               | H=~; echo x > $H/CLAUDE.md
rc=0 deny               | cd ~/.claude && mv x CLAUDE.md
rc=0 deny               | cd ~/.claude && cp -r /tmp/p/hooks .
rc=0 deny               | echo x > "${HOME}"/.claude/"hooks"/g.py
rc=0 deny               | exec 3> ~/.claude/settings.json
rc=0 deny               | echo x >| ~/CLAUDE.md
```
(7 of the 17 rows shown; the other 10 in `out30.txt` are also `deny`.)

The deny comes from the co-occurrence branches of `bash_targets`:

```python
# hooks/guard-trusted-writes.py:194-201
    if HARD_FRAG.search(cmd):
        return "hard"
    # R1 / Q-035: CLAUDE.md plus any home/global indicator -> the global file may be meant.
    if CLAUDE_MD.search(cmd) and HOME_INDICATOR.search(cmd):
        return "hard"
    # A10: settings*.json / hooks plus the config dir named anywhere.
    if SETTINGS_OR_HOOKS.search(cmd) and CFG_INDICATOR.search(cmd):
        return "hard"
```
(the function continues to `:205` with the SOFT_FRAG → "soft" branch and `return None`.)

For comparison, the pre-fix hook (f023357) run through the same probe defers on 15 of the 17 commands. It denies only `exec 3> ~/.claude/settings.json` and `echo x >| ~/CLAUDE.md` (`$S/out30-prefix.txt`). So the fix is what makes the first 15 deny.

**Evidence:** `hooks/guard-trusted-writes.py:190-205`, `hooks/guard-trusted-writes.py:171-185`. Command: `python3 probe30.py /workspace/hooks/guard-trusted-writes.py`, cwd `$S`, exit 0, 2026-09-21T20:47:20-07:00. Output: `$S/out30.txt`. Pre-fix contrast: `python3 probe30.py $S/hook-f023357.py.txt`, exit 0, output `$S/out30-prefix.txt`. Inputs: `$S/probe30.py`, `$S/cmds30.txt`.

---

## Claim 31a: "`replace_with` renames over the target, so a symlink planted at the target is replaced rather than written through."

**Submitted by:** security-reviewer
**Location:** `scripts/questions.sh:115-124`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `index` against a symlink planted at the live file before the run, and `mv -f` semantics over a symlink planted after `replace_with`'s re-check. It does not establish the path for `archive` (which calls `replace_with` twice, once per file), or behavior when the directory is swapped for a symlink inside the check-to-rename window.

The conclusion (no write through a symlink) holds, but the main mechanism is refusal, not replacement. A symlink that already exists at the target never reaches the rename. `assert_write_targets` refuses it first, and `replace_with` checks again just before `mv`:

```bash
# scripts/questions.sh:115-124
replace_with() {
    local target="$1" tmp; shift
    tmp="$(mktemp "$(dirname "$target")/.questions.XXXXXX")"
    if ! "$@" > "$tmp"; then rm -f "$tmp"; return 1; fi
    chmod --reference="$target" "$tmp" 2>/dev/null || true
    if [[ -L "$target" || -L "$(dirname "$target")" ]]; then
        rm -f "$tmp"; die "refusing to write: $target became a symlink"
    fi
    mv -f -- "$tmp" "$target"
}
```

Executed: with a symlink planted at `docs/working/questions.md` pointing to a victim file, `index` exits 1 with `refusing to write: …/questions.md is a symlink`, and the victim still reads `victim` (`$S/out31.txt`, case C). The rename-over behavior only matters for a symlink planted in the window after the line-120 check. For that case, `mv -f` over a symlink replaced the link itself and left its target alone: `target is symlink after mv? no; content=new; victim2=victim` (case D). So a better wording is: "refused if present, and replaced rather than followed if planted in the race window".

**Evidence:** `scripts/questions.sh:91-124`, `scripts/questions.sh:335`, `scripts/questions.sh:345`. Command: `bash probe31.sh.txt`, cwd `$S`, exit 0, 2026-09-21T20:48:22-07:00. Output: `$S/out31.txt` (cases C, D).

---

## Claim 31b: "`docs/working -> ../other` is refused (default paths)."

**Submitted by:** security-reviewer
**Location:** `scripts/questions.sh:91-103`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `init` in a fresh git repo with default paths and `docs/working` as a relative symlink. It does not establish refusal for a symlinked ancestor that resolves inside the repo (for example `docs -> ./elsewhere`): there `docs/working` is not itself a link and containment passes, so that case was not probed as refused.

`init` exits 1 with `refusing to write: directory …/a/docs/working is a symlink` and creates nothing (`$S/out31.txt`, case A). The related case of an ancestor pointing outside the repo (`docs -> $S/q31/outside`) is also refused, this time by the containment check: `…/questions.md resolves to …/outside/working/questions.md, outside …/b` (case B).

**Evidence:** `scripts/questions.sh:94-100`, `scripts/questions.sh:417-434`. Command: `bash probe31.sh.txt`, cwd `$S`, exit 0, 2026-09-21T20:48:22-07:00. Output: `$S/out31.txt` (cases A, B).

---

## Claim 31c: "…it is the default-path *containment* check that refuses `docs/working -> ../other`."

**Submitted by:** security-reviewer
**Location:** `scripts/questions.sh:96-100`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which check in `assert_write_target` fires for this spelling. It does not establish whether the containment check is sufficient for other ancestor layouts.

The refusal comes from the directory-symlink check on line 95, not from containment:

```bash
# scripts/questions.sh:94-100
    [[ -L "$file" ]] && die "refusing to write: $file is a symlink"
    [[ -L "$dir" ]] && die "refusing to write: directory $dir is a symlink"
    if [[ -z "$overridden" ]]; then
        root="$(realpath -m -- "$PROJECT_ROOT")"
        resolved="$(realpath -m -- "$file")"
        [[ "$resolved" == "$root"/* ]] \
            || die "refusing to write: $file resolves to $resolved, outside $root"
```

`../other` resolves inside the repo, so containment on its own would let it through. `realpath -m -- docs/working/questions.md` in that repo gives `…/q31/a/other/questions.md`, which is under the root `…/q31/a`. The refusal message in case A is also the `directory … is a symlink` text. A reader who takes containment to be the guard could drop the `-L "$dir"` check as redundant and reopen in-repo redirection. The accurate wording: "the dir `-L` check refuses `docs/working -> anything`; containment catches symlinked *ancestors* that leave the repo."

**Evidence:** `scripts/questions.sh:94-100`. Command: `bash probe31.sh.txt` (case A message), then `realpath -m -- docs/working/questions.md; realpath -m -- .` in `$S/q31/a`, exit 0, 2026-09-21T20:48:22-07:00. Output: `$S/out31.txt`, plus the realpath output captured in this report's session log (`…/q31/a/other/questions.md` vs `…/q31/a`).

---

## Claim 32: "The linker (devcontainer-config/link-claude-home.sh), health-check (scripts/health-check.sh ~:575) and hook (config_dir, hooks/guard-trusted-writes.py:63-73) now all compute {{CLAUDE_DIR}} from the same expression."

**Submitted by:** api-consistency-reviewer
**Location:** `hooks/guard-trusted-writes.py:63-73`
**Type:** Architectural / Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three computation sites for `CLAUDE_CONFIG_DIR` values unset, empty, absolute, absolute with a trailing slash, relative, and `~/…`. It does not establish that every other consumer of `{{CLAUDE_DIR}}` (for example `health-check.sh:542` or `:585`, which use the same shell expression) agrees on relative values.

The two shell sites use the identical expression:

```bash
# devcontainer-config/link-claude-home.sh:36
DEST="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
# scripts/health-check.sh:575
             | sed "s#{{CLAUDE_DIR}}#${CLAUDE_CONFIG_DIR:-$HOME/.claude}#g")
```

The hook matches their fallback semantics but adds anchoring for relative values:

```python
# hooks/guard-trusted-writes.py:72-73
    cfg = os.environ.get("CLAUDE_CONFIG_DIR")
    return Path(os.path.abspath(cfg)) if cfg else HOME / ".claude"
```

Executed comparison (`$S/out32.txt`): the result is SAME for unset, empty, and `/abs/cfg`. It is DIFF for `/abs/cfg/`, which is only a string difference (pathlib drops the trailing slash, so it is harmless for comparisons). It is also DIFF for `rel/cfg` and `~/cfg`: the hook returns `$PWD/rel/cfg` and `$PWD/~/cfg`, while the shell keeps the relative string. That string is later resolved against whatever cwd the linker, health-check or Claude Code runs in. So "the same expression" is true for the realistic absolute or unset case. For relative values the hook deliberately differs, and its docstring says so ("A relative value is anchored at the hook's cwd"), but it is not the same computation.

**Evidence:** `devcontainer-config/link-claude-home.sh:36`, `devcontainer-config/link-claude-home.sh:133-137`, `scripts/health-check.sh:575`, `scripts/health-check.sh:585`, `hooks/guard-trusted-writes.py:63-73`. Command: `bash probe32.sh.txt`, cwd `$S`, exit 0, 2026-09-21T20:49:04-07:00. Output: `$S/out32.txt`.

---

## Claim 33: "managed-settings.json moving to SOFT for file tools is an improvement: ungated (defer) at f023357, asks when tainted at HEAD."

**Submitted by:** api-consistency-reviewer
**Location:** `hooks/guard-trusted-writes.py:135-144`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers Write and Edit on `~/.claude/managed-settings.json`, `/etc/claude-code/managed-settings.json` and a project-level `managed-settings.json`, in clean and tainted sessions, pre-fix and at HEAD. It does not establish the Bash path (still HARD via `HARD_FRAG` at `:185`), untainted sessions (still ungated at HEAD), or the new false-ask surface on any file named `managed-settings.json` in any project.

The factual premise holds. At f023357 the hook classified it `hard` (`if name in ("managed-settings.json",): return "hard"`, `hook-f023357.py.txt:98-99`) and so deferred. No `permissions.deny` rule names it: `hooks/wiring.json` denies only `{{CLAUDE_DIR}}/settings*.json`, `/hooks/**`, `/CLAUDE.md`, `~/CLAUDE.md` and three Read rules. So the old defer meant no gate. At HEAD it is SOFT:

```python
# hooks/guard-trusted-writes.py:142-144
        if name in ("claude.md", "agents.md", "claude.local.md", "managed-settings.json") \
                or cand.suffix.lower() == ".mdc":
            return "soft"
```

Executed (`$S/out33.txt`): f023357 returns `defer` in all 12 tool × path × taint combinations. HEAD returns `ask` in all 6 tainted combinations and `defer` in all 6 clean ones. Because no deny rule applies, the change strictly adds a gate for tainted sessions. Hence "improvement" is supported.

**Evidence:** `hooks/guard-trusted-writes.py:135-147`, `hooks/wiring.json` (`.permissions.deny`), `hook-f023357.py.txt:98-99` (git show f023357:hooks/guard-trusted-writes.py). Command: `python3 probe33.py`, cwd `$S`, exit 0, 2026-09-21T20:49:24-07:00. Output: `$S/out33.txt`.

---

## Claim 34: "The file-tool classifier matches on resolve() targets (_HARD_FILE_TARGETS/_HARD_DIR_TARGETS), not a hard-coded /opt/claude-workflows path; the /opt mentions at :17/:83 are comments only."

**Submitted by:** architecture-review
**Location:** `hooks/guard-trusted-writes.py:79-93`, `hooks/guard-trusted-writes.py:133`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the hook source's `/opt` references and an installed layout whose payload lives at a non-`/opt` path. It does not establish behavior when the symlink targets are created after the hook process starts (the targets are computed once at import).

`grep -n opt hooks/guard-trusted-writes.py` finds exactly two hits. `:17` is inside the module docstring ("/opt/claude-workflows). Critical: …"), which is a non-executing string rather than a `#` comment, but it has no effect at runtime. `:83` is a `#` comment. The HARD targets are derived only from `CONFIG_DIR`:

```python
# hooks/guard-trusted-writes.py:86,93
_HARD_FILE_TARGETS = {_safe_resolve(CONFIG_DIR / "CLAUDE.md"), _safe_resolve(HOME / "CLAUDE.md")}
_HARD_DIR_TARGETS = {_safe_resolve(CONFIG_DIR / "hooks")}
```
(lines 87-92 add the resolved `settings*.json` names to `_HARD_FILE_TARGETS`.)

Executed with `~/.claude/hooks` and `~/.claude/CLAUDE.md` symlinked into `$S/r34/srv/payload` (not `/opt`), in a tainted session (`$S/out34.txt`): `payload/hooks/x.py` returns `defer` (HARD) and `payload/CLAUDE.md` returns `defer` (HARD). The control, an unrelated `other/CLAUDE.md`, returns `ask` (SOFT). So matching follows the link targets wherever they are.

**Evidence:** `hooks/guard-trusted-writes.py:14-17`, `hooks/guard-trusted-writes.py:79-93`, `hooks/guard-trusted-writes.py:121-134`. Command: `python3 probe34.py`, cwd `$S`, exit 0, 2026-09-21T20:49:45-07:00. Output: `$S/out34.txt`.

---

## Claim 35: "Across Bash-hard, Write-none and Bash-no-write request shapes, the fix adds ≤0.3 ms in-process work per hook call and end-to-end latency stays within ~2 ms of the pre-fix hook (f023357); and WRITE_PRIMITIVE pathological 40 KB input times are unchanged by the fix."

**Submitted by:** performance-reviewer
**Location:** `hooks/guard-trusted-writes.py:79-93`, `hooks/guard-trusted-writes.py:156-205`
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers one representative input per shape (Bash-hard = `echo x > ~/.claude/settings.json`, which exits at `HARD_FRAG`; Write-none = `/workspace/src/app.py`; Bash-no-write = `git status && ls -la`), with an empty temp `~/.claude`, on this WSL2 machine. It does not establish cost for Bash-hard inputs that reach the co-occurrence branches, a `~/.claude` with many `settings*.json` or a slow filesystem for `resolve()`/`glob()`, or run-to-run variance beyond medians of 30–40 samples.

The in-process delta is module setup plus classification (`$S/out35.txt`). Import median: 0.076 → 0.227 ms (+0.15 ms). Classification: Bash-hard 0.85 → 0.70 µs, Write-none 25.9 → 44.3 µs (+0.018 ms), Bash-no-write 0.89 → 0.86 µs. Total at most about 0.17 ms, within the ≤0.3 ms bound.

End-to-end subprocess medians (40 runs): Bash-hard 16.93 → 17.45 ms, Write-none 20.95 → 18.77 ms, Bash-no-write 15.88 → 16.47 ms. Every difference is within ~2.2 ms, and the largest one is in the faster direction.

WRITE_PRIMITIVE: the compiled pattern text is byte-identical between the two versions (`pattern identical: True`; source `hooks/guard-trusted-writes.py:156-164`). The 40 KB timings match: sed-spaces 1.26/1.27 ms, python-spaces 1.27/1.19 ms, sed-a 1.36/1.37 ms, and `"dd " * 13333` 1417.66/1444.33 ms. That last input is a pre-existing ~1.4 s backtracking case on `\bdd\b[^\n]*\bof=`. It is unchanged by the fix, but worth a separate note since the claim says only "unchanged".

**Evidence:** `hooks/guard-trusted-writes.py:79-93`, `hooks/guard-trusted-writes.py:156-164`, `hooks/guard-trusted-writes.py:190-205`. Command: `timeout 500 python3 probe35.py`, cwd `$S`, exit 0, 2026-09-21T20:50:15-07:00. Output: `$S/out35.txt`.

---

