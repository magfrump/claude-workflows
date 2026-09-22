**Commit:** 31f53e8

# Code Fact-Check Report

**Repository:** /workspace (claude-workflows), branch `answers-2026-09-20`
**Scope:** `git diff 2d93589..answers-2026-09-20` (818c568, a577546, 739cbbb, fd0ad24 merge, b951c4f, 31f53e8), plus the commit messages. Iteration 3, the final confirmation pass. This is the merged report, most-severe-wins, built from `code-fact-check-report-iter3-r1.md`, `-r2.md` and `-r3.md`.
**Checked:** 2026-09-21
**Total claims checked:** 36 merged claims (from 30 + 28 + 30 replicate claims; where any replicate split a claim, it is emitted at the finer granularity)
**Summary:** 18 verified, 13 mostly accurate, 0 stale, 3 incorrect, 2 unverifiable
**Replication:** k=3

This merge is mechanical collation. Headline evidence and reasoning are carried from the replicate that set the winning verdict. Replicate annotations are merged by union. Execution logs:
- r2's logs are in `docs/reviews/execution-logs/iter3-r2-*`.
- r1's and r3's logs are in the session scratchpad and are not tracked.

---

## Claim 1: override-log N2 row — "`hooks/guard-trusted-writes.py:190-205` Bash writes still ungated for … Discoverable TODO: `# TODO(N2)` block beside the Bash indicators (a577546)"

**Location:** `docs/reviews/override-log.md` (iter2 N2 row)
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the row's code reference, its TODO pointer and its "ungated" wording. It does not re-open N2's substance, which is settled.
**Replicate verdicts:** r1=Verified · r2=Mostly accurate · r3=Verified
**Replicate annotations:**
- r2: "`:190-205` is where `bash_targets` sat at iteration 2; it is now `:225-240`. 'Ungated' overstates two of the listed shapes: the bare `cd` and `/home/$USER` CLAUDE.md shapes get SOFT, which asks when tainted."
- r1+r3: the `# TODO(N2)` block exists at `:172-184`, and the revisit trigger is concrete.
**Legibility-target:** for-author

The row pins a line range that has since moved. `bash_targets` is now at `hooks/guard-trusted-writes.py:225-240`, and the TODO block is at `:172-184`. The qualifying note itself (a TODO plus a trigger) is present.

**Evidence:** `docs/reviews/override-log.md` N2 row; `hooks/guard-trusted-writes.py:172-184,225-240`

---

## Claim 2: override-log N3 row — "Tracked as Q-049 in `docs/working/questions.md` with a paste. Revisit trigger: Q-049's answer."

**Location:** `docs/reviews/override-log.md` (iter2 N3 row)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that Q-049 exists and carries a paste. It does not establish that the paste is sound; see Claim 7.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none
**Legibility-target:** for-orchestrator-synthesis

Q-049 exists in `docs/working/questions.md`. It is a `you: terminal` entry with a paste and an interim line.

**Evidence:** `docs/working/questions.md` (Q-049)

---

## Claim 3: override-log A6 row — "the run-id charset … is copied in `scripts/self-improvement.sh`, `scripts/archive-working-docs.sh` and `scripts/lib/si-morning-summary.sh` … All three copies are identical"

**Location:** `docs/reviews/override-log.md` (iter2 A6 row)
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the count of regex copies. It does not dispute the Defer disposition.
**Replicate verdicts:** r1=— · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r2+r3: "four copies in three files, not three: 818c568 added a second copy in `archive-working-docs.sh` (the explicit-prefix check at `:50-55`)."
**Legibility-target:** for-author

There are four copies of `^[A-Za-z0-9._-]+$` across three files. The new explicit-prefix validation in 818c568 adds a second one inside `archive-working-docs.sh`. The Defer row understates the count by one.

**Evidence:** `scripts/archive-working-docs.sh:50-55` and its recorded-id check; `scripts/self-improvement.sh`; `scripts/lib/si-morning-summary.sh` `_valid_run_id`

---

## Claim 4: override-log 4c7a2bb row — "Refuted at `…:56-132` as of `4c7a2bb` … The defects it hid were R1/R4 …, fixed in `c5a7c96`."

**Location:** `docs/reviews/override-log.md` (4c7a2bb row)
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the pin and the "fixed" wording.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Mostly accurate
**Replicate annotations:**
- r3: "'fixed in c5a7c96' is only partly true for R1; R1's residue is N2 (Deferred)."
- r1+r2: the pin to `4c7a2bb` is correct.
**Legibility-target:** for-author

The N7 re-pin is correct. "Fixed in c5a7c96" is complete for R4. For R1 it is complete only for the listed spellings; the residue is carried as N2.

**Evidence:** `docs/reviews/override-log.md` 4c7a2bb row; iter2 rubric, R1 status row

---

## Claim 5: Q-023 timings — "42–60s depending on load and slow ~80–100s … Full health check measured 216s on the merged tip."

**Location:** `docs/working/questions-archive.md:833`
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers single timing runs under concurrent agent load. It does not establish the distribution.
**Replicate verdicts:** r1=Verified · r2=Mostly accurate · r3=Verified
**Replicate annotations:**
- r2: "`health-check.bats` took 63s here, above the stated 42–60s, with other agents running."
- r1: 56s and `--slow` 96s. r1 did not re-measure the 216s figure.
- r3: 49s, `--slow` 79s (the bottom edge of ~80–100s), full health check 210s.
**Legibility-target:** for-author

Measured values: 49s, 56s and 63s for `health-check.bats`; 79s and 96s for `--slow`; 210s for the full check. The stated ranges hold roughly. They are exceeded once under heavy contention.

**Evidence:** `docs/reviews/execution-logs/iter3-r2-health-check-bats.txt`; r1 and r3 scratchpad logs

---

## Claim 6: Q-049 entry format — you: terminal, one copy-pasteable block and an interim line; `questions.sh check` passes

**Location:** `docs/working/questions.md` (Q-049)
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the grammar and the `check` result. It does not establish the paste's correctness; see Claim 7.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none
**Legibility-target:** for-orchestrator-synthesis

`scripts/questions.sh check` exits 0.

**Evidence:** `docs/reviews/execution-logs/iter3-r2-questions-check.txt`

---

## Claim 7: Q-049 paste — "For each rule form it grants Write, denies the target, asks Claude to write it, and reports whether the file appeared" / "if single-slash is enforced, N3 is closed as a non-issue"

**Location:** `docs/working/questions.md:57-69`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the paste's decision logic, and r2 ran it against a failing stand-in `claude`. It does not establish Claude Code's real deny-path semantics (see Claim 9).
**Replicate verdicts:** r1=Incorrect · r2=Incorrect · r3=Incorrect
**Replicate annotations:**
- r1+r3: all `claude -p` output and stderr go to `/dev/null`, and there is no control run without the deny rule.
- r1: the target `$t` is in a second `mktemp -d` dir outside the cwd `$d`, so an outside-cwd permission prompt that `-p` cannot answer would also print "enforced". A "Not logged in" exit-0 run would too; the user's own memory note says to judge headless runs by JSON `num_turns`.
- r2: "It also tests project settings, while N3 is about user settings."
- r3: fix by adding an allow-only run that must print "NOT enforced", and keep the JSON and stderr.
**Legibility-target:** for-author

Excerpt of the paste:

```bash
  (cd "$d" && claude -p "Use the Write tool to create the file $t containing: hi" --output-format json >/dev/null 2>&1)
  [ -e "$t" ] && echo "$form-slash rule: NOT enforced (file written)" || echo "$form-slash rule: enforced"
```

The excerpt ends inside the loop, which closes with `done`. r2 ran the paste with a stand-in `claude` that just fails. It printed "single-slash rule: enforced" and "double-slash rule: enforced". The entry's plan then closes N3 on that output, so a failed run would close a security finding with no evidence.

**Evidence:** `docs/working/questions.md:57-69`; `docs/reviews/execution-logs/iter3-r2-q049-stub.txt`

---

## Claim 8: Q-049 premises — "`link-claude-home.sh` writes them as `Edit(/home/node/.claude/settings*.json)`, with one leading slash … `devcontainer-config/link-claude-home.sh:137`"

**Location:** `docs/working/questions.md` (Q-049 body)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the substitution site and the rendered form.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none
**Legibility-target:** for-orchestrator-synthesis

The `{{CLAUDE_DIR}}` substitution happens at `devcontainer-config/link-claude-home.sh:137` and renders as a single-slash absolute path.

**Evidence:** `devcontainer-config/link-claude-home.sh:137`; `hooks/wiring.json:120-127`

---

## Claim 9: Q-049 — "If Claude Code reads `/path` as relative to the settings file and needs `//path` for an absolute path … every global-dir deny rule matches nothing"

**Location:** `docs/working/questions.md` (Q-049)
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Claude Code's own deny matcher is not available in the sandbox, which has no egress.
**Replicate verdicts:** r1=Unverifiable · r2=— · r3=Unverifiable
**Replicate annotations:** r1: the same gap covers whether a deny rule matches the `..`-folded or `//` spelling, and whether Edit rules cover MultiEdit (the N3 residue).
**Legibility-target:** for-orchestrator-synthesis

This is settled as N3 / Q-049 and is not re-raised.

**Evidence:** none available in-sandbox

---

## Claim 10: Q-048 rule description — "applied only to commands that contain a write … If the command names `CLAUDE.md`, it is denied when it also contains … `~`, `$HOME` … `.claude`, `global-instructions` or the config dir…"

**Location:** `docs/working/questions.md:76`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the description against `bash_targets` (`hooks/guard-trusted-writes.py:225-240`).
**Replicate verdicts:** r1=Mostly accurate · r2=Verified · r3=Mostly accurate
**Replicate annotations:**
- r1+r3: the description omits that the literal `CLAUDE_CONFIG_DIR` token triggers both rules, and that a write naming `managed-settings`, `.claude/hooks` or `.claude/settings` (HARD_FRAG) is denied with no second indicator.
- r3: it also omits that matching is case-insensitive.
**Legibility-target:** for-author

The N6 correction fixed the two errors found in iteration 2. It is still incomplete: the HARD_FRAG single-token denies and the `CLAUDE_CONFIG_DIR` token are not mentioned.

**Evidence:** `hooks/guard-trusted-writes.py:225-240`; `docs/reviews/execution-logs/iter3-r2-bash-probes.txt`

---

## Claim 11: Q-048 false denies — "a heredoc that writes a message file mentioning `CLAUDE.md` next to `HEAD~1`, and any Bash write into an agent worktree's `hooks/`"

**Location:** `docs/working/questions.md:76`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two example false denies.
**Replicate verdicts:** r1=— · r2=— · r3=Verified · single-replicate detection
**Replicate annotations:** none
**Legibility-target:** for-orchestrator-synthesis

Both example commands return deny.

**Evidence:** r3 scratchpad probe log

---

## Claim 12a: hook docstring — "Matching is case-sensitive, like the deny rules and like Linux paths: ~/.claude/HOOKS/x is not the hooks dir (it falls to SOFT)"

**Location:** `hooks/guard-trusted-writes.py:14-15`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers Linux (ext4) behaviour. It does not establish behaviour on a case-insensitive filesystem; no such mount was available.
**Replicate verdicts:** r1=Verified · r2=Mostly accurate · r3=Verified
**Replicate annotations:** r2: "Correct on Linux, but the README supports macOS bare hosts. On a case-insensitive filesystem `~/.claude/SETTINGS.JSON` IS the real settings file, and it now defers untainted. Not tested: no case-insensitive mount available."
**Legibility-target:** for-author

On Linux, case variants fall to SOFT: they defer when clean and ask when tainted. On a case-insensitive host filesystem (macOS, which the README supports), `SETTINGS.JSON` names the protected file. The hook then defers untainted. Whether the deny rule catches it depends on the Claude Code matcher, which could not be tested here.

**Evidence:** `hooks/guard-trusted-writes.py:14-15,118-133`; `docs/reviews/execution-logs/iter3-r2-hook-probes.txt`

---

## Claim 12b: `_is_hard` docstring — "Case-SENSITIVE, like the deny rules (N1): lowercasing here made ~/.claude/HOOKS/x … 'HARD', so the hook deferred onto a rule that does not name them"

**Location:** `hooks/guard-trusted-writes.py:118-120`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the code change (no `.lower()` in `_is_hard`).
**Replicate verdicts:** r1=Verified (compound, in Claim 8) · r2=— · r3=Verified
**Replicate annotations:** none
**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `hooks/guard-trusted-writes.py:121-133`

---

## Claim 12c: a577546 — "Case variants route to SOFT (ask when tainted, defer otherwise), not HARD"

**Location:** commit `a577546` (Notes)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Linux only (see Claim 12a).
**Replicate verdicts:** r1=Verified (compound, in Claim 8) · r2=Verified · r3=Verified
**Replicate annotations:** none
**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `test/hooks/guard-trusted-writes.bats` (N1 case-variant test); r2 hook-probe logs

---

## Claim 13: hard-resolved tier — "HARD only after resolve() or only under the config dir's resolved form … the hook returns 'deny' itself, tainted or not. Never 'ask'."

**Location:** `hooks/guard-trusted-writes.py:22-27,149-155,279-285`; commit `a577546`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the /opt payload by its real path (including `x/../`), a config dir that is itself a symlink, a symlinked HOME, a relative `CLAUDE_CONFIG_DIR`, and a project `.claude` symlinked to `~/.claude`, each clean and tainted. It does not establish the Claude Code matcher's view of the "covered" spellings (Claim 14).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2+r3 (invariant sweep): no probed HARD path returned "ask", and every resolve-only HARD path returned "deny". The only defers on spellings no deny rule verifiably names are `..`, `//` and MultiEdit, the disclosed N3 residue.
**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `docs/reviews/execution-logs/iter3-r2-hook-probes*.txt`; r1 and r3 scratchpad logs

---

## Claim 14: docstring — "covered = the path AS GIVEN (lexical, or normpath with `..` folded) … A deny rule names that string, so the hook DEFERS to it."

**Location:** `hooks/guard-trusted-writes.py:18-21,145-148`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the hook's side of the claim. Whether the deny matcher folds `..` or `//` is not established.
**Replicate verdicts:** r1=Unverifiable · r2=Verified (compound, in Claim 10) · r3=Mostly accurate
**Replicate annotations:** r3: "'a deny rule names that string' is stated as fact for `..`-folded and `//` spellings; that is unverified (N3-adjacent). The commit Notes disclose it; the docstring does not."
**Legibility-target:** for-author

The code defers on the normpath match. The docstring asserts, as fact, that a deny rule covers that spelling. The a577546 commit Notes disclose that this is unverified, but the docstring does not.

**Evidence:** `hooks/guard-trusted-writes.py:18-21,145-148`; a577546 Notes

---

## Claim 15: resolved-tier examples — "e.g. the payload CLAUDE.md addressed by its real /opt path … or a project .claude symlinked to ~/.claude" (a577546's parenthetical lists the hard-resolved set)

**Location:** `hooks/guard-trusted-writes.py:22-27`; commit `a577546`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the hard-resolved set contains under the README bare-host install. It does not establish whether denying the checkout's global CLAUDE.md is the intended policy.
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=— (raised the same finding inside its deny-message claim, merged Claim 19)
**Replicate annotations:**
- r1+r2+r3: **there is an undisclosed behaviour change on the README bare-host install.** `README.md:14` links `~/.claude/CLAUDE.md` to `~/claude-workflows/global-instructions/CLAUDE.md`. So `_HARD_FILE_TARGETS` (`:95`) contains the repo checkout's `global-instructions/CLAUDE.md`, and file-tool edits to it are now **denied**, clean or tainted. At `2d93589` they deferred; both hooks were probed on the same path.
- r1: "The Bash rules already block this file, so the deny may be intended, but neither the docstring nor the commit says so."
- r2+r3: repo `hooks/*.py` are not affected, because README links hooks per file into a real `~/.claude/hooks/`. The devcontainer's `/workspace` is not affected either.
**Legibility-target:** for-author

The r2 probe from 2026-09-22T04:17Z: `Edit ~/claude-workflows/global-instructions/CLAUDE.md` in a clean session returns **deny**. The pre-fix hook at `2d93589` returned DEFER. A bare-host session developing this repo can no longer edit its own global instructions with Edit or Write.

**Evidence:** `hooks/guard-trusted-writes.py:95`; `README.md:14,29`; `docs/reviews/execution-logs/iter3-r2-hook-probes-b.txt`; `docs/reviews/execution-logs/iter3-r2-hook-probes-b-prefix.txt`

---

## Claim 16: `config_dir()` docstring — "This matches the linker for an unset, empty or absolute value. It DIFFERS for a relative value … anchors it at the hook's own cwd with abspath()"

**Location:** `hooks/guard-trusted-writes.py:76-79`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four value classes.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none
**Legibility-target:** for-orchestrator-synthesis

The N10 correction is accurate.

**Evidence:** `hooks/guard-trusted-writes.py:70-83`; `devcontainer-config/link-claude-home.sh`

---

## Claim 17: "Case-folded on purpose: SOFT only ever asks, so over-matching is safe."

**Location:** `hooks/guard-trusted-writes.py:158`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the SOFT branch outcomes.
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Verified
**Replicate annotations:**
- r1: "SOFT asks only in a tainted session and defers otherwise. Over-matching is safe because HARD is checked first, and that relies on a case-sensitive filesystem."
- r2: "More precisely: SOFT never denies and asks only when tainted."
**Legibility-target:** for-author

The comment is imprecise: SOFT never denies, and it asks only when the session is tainted. The safety argument holds on Linux.

**Evidence:** `hooks/guard-trusted-writes.py:156-169,287-290`

---

## Claim 18: TODO(N2) — "command TEXT that writes a global policy file but carries no indicator token … so it gets no opinion"

**Location:** `hooks/guard-trusted-writes.py:172-184`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed shape, clean and tainted.
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r1+r2+r3: the bare `cd; echo x > CLAUDE.md` and `/home/$USER/CLAUDE.md` shapes get SOFT, which asks when tainted, not "no opinion". The other nine shapes really do get no opinion. Every listed shape still misses HARD, so the TODO is still live.
**Legibility-target:** for-author

**Evidence:** `docs/reviews/execution-logs/iter3-r2-n2-todo-probes.txt`

---

## Claim 19: deny reason — "… through a symlink or resolved path that permissions.deny does not name. Edit it at its ~/.claude path, with review."

**Location:** `hooks/guard-trusted-writes.py:282-285`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what happens when the agent follows the advice under both N3 outcomes, and in the bare-host layout. It does not establish Claude Code's matcher (N3/Q-049).
**Replicate verdicts:** r1=Incorrect · r2=Incorrect · r3=Incorrect
**Replicate annotations:**
- r1+r2+r3: the `~/.claude` spelling is exactly what `permissions.deny` blocks, and a deny cannot be approved, so "with review" is impossible. In the devcontainer the target is also root-owned and read-only.
- r3: if the deny rules do not match (N3), the hook defers on that spelling, so the edit goes through with **no** review.
- r1: when `CLAUDE_CONFIG_DIR` points elsewhere, the file is not under `~/.claude` at all.
- r3: the message also fires on the bare-host regression in merged Claim 15, pointing the user at a spelling that is denied too.
**Legibility-target:** for-author

Neither N3 outcome lets the user "edit it there, with review". The only real route is a human editing outside Claude Code, and the message does not say so.

**Evidence:** `hooks/guard-trusted-writes.py:95,154-155,279-285`; `hooks/wiring.json:120-127`; `README.md:14`

---

## Claim 20: a577546 — "bats test/hooks/: 144 ok, 0 not ok."

**Location:** commit `a577546`
**Type:** Test
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Count at HEAD 31f53e8.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none
**Legibility-target:** for-orchestrator-synthesis

All three replicates counted 144 ok, 0 not ok.

**Evidence:** `docs/reviews/execution-logs/iter3-r2-bats-hooks.txt`

---

## Claim 21: a577546 — "Probed against this container's installed layout: /opt/claude-workflows/CLAUDE.md -> deny, ~/.claude/CLAUDE.md -> defer, ~/.claude/HOOKS/x -> defer (untainted)."

**Location:** commit `a577546`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Read-only probes against the real layout.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none
**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `docs/reviews/execution-logs/iter3-r2-real-layout.txt`

---

## Claim 22: test header — "A path that is HARD only after resolve() is named by no deny rule, so the hook denies it itself (N1)", plus the five new N1 tests

**Location:** `test/hooks/guard-trusted-writes.bats:14-16,440-507`
**Type:** Test
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the tests passing and exercising the stated behaviour.
**Replicate verdicts:** r1=Verified · r2=— · r3=— · single-replicate detection
**Replicate annotations:** none
**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `test/hooks/guard-trusted-writes.bats:440-507`

---

## Claim 23: archive prefix — "hold an explicit prefix to the same charset as the recorded one" (`[A-Za-z0-9._-]+`)

**Location:** `scripts/archive-working-docs.sh:50-55`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers rejection of out-of-charset prefixes.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "`.` and `..` pass the regex but stay inside `archive/`."
**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `scripts/archive-working-docs.sh:50-55`; `test/scripts/archive-working-docs.bats`

---

## Claim 24: "an existing archive copy is never overwritten" / "must not overwrite the first run's copy"

**Location:** `scripts/archive-working-docs.sh:138-143`; commit `818c568`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a real collision, a dangling-symlink destination, and races.
**Replicate verdicts:** r1=Mostly accurate · r2=Verified · r3=Verified
**Replicate annotations:**
- r1+r2: a **dangling symlink** at the destination is overwritten, because `[ -e ]` follows links.
- r1+r2+r3: on a real collision the source is skipped and left in place, a "skip" line goes to stderr, and the exit code is 0. A check-then-`mv` race window remains.
**Legibility-target:** for-author

The claim holds for real files. It does not hold for a dangling symlink at the destination, and it is subject to a narrow race.

**Evidence:** `scripts/archive-working-docs.sh:138-143`

---

## Claim 25: si-functions — "Run (Q-047) is the self-improvement run's id (si_default_run_id above, or SI_RUN_ID)"

**Location:** `scripts/lib/si-functions.sh:481`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the pointer direction.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none
**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `scripts/lib/si-functions.sh:469,481`

---

## Claim 26: `_migrate_hypothesis_log_run_column` — "Exit 0 = header has a Run cell, 3 = no header row at all, 1 = migrate. 3, not 2: awk itself exits 2 on a runtime error … that must fail the call"

**Location:** `scripts/lib/si-functions.sh:566-580`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the propagation and the callers.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:**
- r1+r2+r3: an unreadable log now makes the function return 2. Under `set -euo pipefail` in `scripts/self-improvement.sh`, that aborts the SI run at the hypothesis-logging step, which comes after merges.
- r3: "matches the comment's stated intent, but nobody designed the caller's handling."
- No code or test expects exit 2.
**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `docs/reviews/execution-logs/iter3-r2-migrate.txt`

---

## Claim 27: `_project_state_open_hypotheses` — escaped pipes swapped for `\036` before splitting, restored as `|`, fields joined with `\037`

**Location:** `scripts/lib/si-morning-summary.sh:402-445`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the N4 counting and display on piped rows, and the consistency of the three readers.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: all three readers now split consistently.
**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `docs/reviews/execution-logs/iter3-r2-pre818-n4.txt`; `test/morning-summary-clusters.bats`

---

## Claim 28: `_split_row_fields` — "Assumed, not checked, to be absent from log rows: the writer never emits it"

**Location:** `scripts/lib/si-morning-summary.sh:1532-1536`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the writer's handling of the byte.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Mostly accurate
**Replicate annotations:** r3: "the writer never *adds* `\x1e`, but it passes it through from the task JSON unfiltered."
**Legibility-target:** for-author

**Evidence:** `scripts/lib/si-morning-summary.sh:1532-1536`; the hypothesis-log writer in `scripts/lib/si-functions.sh`

---

## Claim 29a: questions.sh header — "Writes never go through a symlinked questions file or docs/working/ dir, and, for the default paths, never land outside the git toplevel … Explicit QUESTIONS_LIVE/ARCHIVE paths get only the symlink checks."

**Location:** `scripts/questions.sh:47-51`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the per-file and per-dir checks and default-path containment.
**Replicate verdicts:** r1=Verified · r2=Mostly accurate (compound) · r3=Mostly accurate (compound)
**Replicate annotations:** the compound Mostly-accurate verdicts from r2 and r3 rest entirely on the ancestor clause (29b). r1 verdicted this sub-claim Verified on its own.
**Legibility-target:** for-author

**Evidence:** `scripts/questions.sh:47-51,91-100`

---

## Claim 29b: questions.sh header — "(an ancestor symlink such as a symlinked docs/ is caught by that check, not by the per-file one)"

**Location:** `scripts/questions.sh:49-50`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers in-repo and outside-repo ancestor symlinks.
**Replicate verdicts:** r1=Incorrect · r2=Mostly accurate (compound) · r3=Mostly accurate (compound)
**Replicate annotations:** r1+r2+r3: `docs -> .git` and `docs -> ./x` still let `init` write through the link, with exit 0. Only a `docs/` pointing *outside* the repo is refused. This is the iteration-2 N5 counterexample, unchanged.
**Legibility-target:** for-author

The N5 rewording still overclaims. A symlinked `docs/` is caught only when it leads outside the toplevel.

**Evidence:** `docs/reviews/execution-logs/iter3-r2-questions-ancestor.txt`

---

## Claim 30: rubric.md (N8) — "carry a qualifying author note (a discoverable TODO or a concrete revisit trigger; see 'Qualifying author note' in `skills/code-review/references/rubric.md`)"

**Location:** `skills/code-review/references/rubric.md:155-157`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the plain-text pointer.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none
**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `skills/code-review/references/rubric.md:155-176`

---

## Claim 31a: 818c568 — "N4 test fails on the pre-fix lib"

**Location:** commit `818c568`
**Type:** Test
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Hermetic copy of the pre-fix tree.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r2+r3: both A6 tests also fail pre-fix.
**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `docs/reviews/execution-logs/iter3-r2-pre818-n4.txt`

---

## Claim 31b: 818c568 — "85/85 SI suites pass."

**Location:** commit `818c568`
**Type:** Test
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed
**Scope:** The commit names no suite set.
**Replicate verdicts:** r1=Verified (compound) · r2=Unverifiable · r3=Verified (compound)
**Replicate annotations:** r1+r2+r3: `precondition-gate` + `append-approved-hypotheses` + `morning-summary-clusters` = 40 + 20 + 25 = 85, which is inferred from the arithmetic. Every candidate set passes: r2 counted 105/105 over five suites, and r3 counted 143/143 over eight.
**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `docs/reviews/execution-logs/iter3-r2-bats-si.txt`, `iter3-r2-bats-si5.txt`

---

## Claim 32: Q-049 interim — "Interim: unchanged. The devcontainer's `/opt` payload is read-only … `~/.claude/settings*.json` is not bounded that way."

**Location:** `docs/working/questions.md` (Q-049)
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers file ownership and mode in the container.
**Replicate verdicts:** r1=Verified · r2=— · r3=— · single-replicate detection
**Replicate annotations:** none
**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `ls -la /opt/claude-workflows ~/.claude`

---

## Claims Requiring Attention

- **Incorrect:**
  - Claim 7: the Q-049 paste cannot tell "enforced" from "never ran".
  - Claim 19: the deny-message advice is impossible to follow.
  - Claim 29b: the questions.sh ancestor-symlink comment.
- **Mostly accurate:**
  - Claims 1, 3 and 4: override-log rows.
  - Claim 5: timings.
  - Claim 10: the Q-048 text.
  - Claim 12a: case-insensitive filesystems.
  - Claim 14: the "covered" docstring.
  - Claim 15: the undisclosed bare-host deny of `global-instructions/CLAUDE.md`.
  - Claim 17: "SOFT only ever asks".
  - Claim 18: the TODO(N2) wording.
  - Claim 24: dangling-symlink overwrite.
  - Claim 28: the `\x1e` pass-through.
  - Claim 29a: compound.
- **Unverifiable:** Claims 9 and 31b.

## Escalations

- `hooks/guard-trusted-writes.py:95,154-155` / `README.md:14`:
  - **Issue:** the bare-host "hard-resolved" deny of the repo checkout's `global-instructions/CLAUDE.md` is a behavioural change, not just wording.
  - **Raised by:** r1, r2, r3.
  - **Addressee:** security-reviewer, api-consistency-reviewer.
- `docs/working/questions.md:57-69`:
  - **Issue:** running the Q-049 paste as written could wrongly close N3.
  - **Raised by:** r1, r2, r3.
  - **Addressee:** security-reviewer.
- `scripts/lib/si-functions.sh:566-580`:
  - **Issue:** awk failure now aborts the SI run after merges; the caller's handling was never designed.
  - **Raised by:** r3.
  - **Addressee:** orchestrator.
- `hooks/guard-trusted-writes.py:14-15`:
  - **Issue:** case-insensitive host filesystems (macOS) could not be tested.
  - **Raised by:** r2.
  - **Addressee:** security-reviewer.

## Verdict stability

- Total merged claims (sub-claim rows): 36.
- Rows where every reporting replicate agreed: 24.
- Rows where verdicts disagreed: 12. Per-replicate verdicts for each:
  - Claim 1: V / MA / V
  - Claim 4: V / V / MA
  - Claim 5: V / MA / V
  - Claim 10: MA / V / MA
  - Claim 12a: V / MA / V
  - Claim 14: U / V(compound) / MA
  - Claim 17: MA / MA / V
  - Claim 24: MA / V / V
  - Claim 28: V / V / MA
  - Claim 29a: V / MA(c) / MA(c)
  - Claim 29b: I / MA(c) / MA(c)
  - Claim 31b: V(c) / U / V(c)
- Agreement rate: 24/36 = 67%.
- All three Incorrect verdicts that stand at the top level were unanimous for Claims 7 and 19. Claim 29b's Incorrect came from r1 alone; the other two verdicted it only as part of a compound claim.

---

## Submitted Claims

## Claim 33: "No file-tool path that the hook classifies as HARD reaches the `ask` branch. The `"hard"` return defers, `"hard-resolved"` emits deny, and both come before the SOFT check."

**Submitted by:** security-reviewer (architecture-review made the same claim)
**Location:** `hooks/guard-trusted-writes.py:146-155,275-286`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every path that `classify_path` returns as `"hard"` or `"hard-resolved"`, for Edit, Write and MultiEdit, through both the `file_path` and `path` keys, tainted and clean, across five layouts. The layouts are: installed; `CLAUDE_CONFIG_DIR` set explicitly; config dir itself a symlink; HOME a symlink; a plain config dir. It does not establish anything about spellings the hook does not classify as HARD. That includes case variants on a case-insensitive filesystem: on Linux ext4 they classify `soft` and do ask when tainted. The probe could not test a case-insensitive filesystem. It also does not cover Bash, which has its own tier logic.

In `classify_path`, both HARD returns come before the SOFT loop:

```python
# hooks/guard-trusted-writes.py:146-159
    for cand in (p, norm):
        if _is_hard(cand, [CONFIG_DIR]):
            return "hard"
    ...
    for cand in cands:
        if _is_hard(cand, GLOBAL_DIRS):
            return "hard-resolved"
    if rp in _HARD_FILE_TARGETS or any(rp == d or d in rp.parents for d in _HARD_DIR_TARGETS):
        return "hard-resolved"
    # SOFT. ...
    for cand in cands:
(excerpt ends :159; enclosing classify_path continues to :169 and returns only "soft" or "none" — read)
```

In `main()`, both HARD tiers leave the process before the `ask` branch runs:

```python
# hooks/guard-trusted-writes.py:275-289
        if tier == "hard":
            ...
            defer()
        if tier == "hard-resolved":
            ...
            emit("deny", f"This write reaches a protected policy file ...")
        if tier == "soft" and tainted:
            emit("ask", ...)
        defer()
```

Both `defer()` and `emit()` end in `sys.exit(0)`, so neither HARD tier can fall through (`hooks/guard-trusted-writes.py:57-65`: `print(json.dumps(...)); sys.exit(0)` / `def defer(): sys.exit(0)`).

The executed probe covered 296 HARD-classified (path × layout) cases: 240 `hard` and 56 `hard-resolved`. Each case ran 8 times, once per tool, key and taint combination, by driving the real `main()` with the payload on stdin. Zero violations: every `hard` case produced no output (defer), and every `hard-resolved` case produced `deny`. Separate CLI runs (`python3 hook < payload`) confirmed that lexical `settings.json`, `hooks/foo.sh` and `~/CLAUDE.md` give empty output with rc=0, tainted and clean alike.

The case variants (`~/.claude/SETTINGS.json`, `HOOKS/foo.sh`, `claude.md`) classified `soft` and gave `ask` when tainted and defer when clean. They are outside this claim, as the critic's scope says. On a case-insensitive filesystem they would be the real files, so they are the gap the critic flagged, not a counterexample here.

- Command: `bash /tmp/claude-1000/-workspace/104b63ce-e414-465c-a24f-dda1e4116218/scratchpad/subm/probe-s1s2.sh.txt` (cwd `/workspace`, exit 0, 2026-09-22T04:39:17Z)
- Command: `bash .../subm/probe-s2-extra.sh.txt` (cwd `/workspace`, exit 0, 2026-09-22T04:39:40Z)

**Evidence:** `hooks/guard-trusted-writes.py:57-65`, `hooks/guard-trusted-writes.py:134-169`, `hooks/guard-trusted-writes.py:270-289`; `docs/reviews/execution-logs/iter3-subm-probe-s1s2.txt` (summary lines: `class totals (path x layout): {'hard-resolved': 56, 'hard': 240, 'soft': 66, 'none': 23}` / `violations: 0`); `docs/reviews/execution-logs/iter3-subm-probe-s2-extra.txt`; the harness is at `docs/reviews/execution-logs/iter3-subm-harness.py.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 34: "A path that is HARD only after resolve() returns deny whether or not the session is tainted."

**Submitted by:** security-reviewer (backs architecture-review's point that the deny/defer split puts fail-closed where it is cheap)
**Location:** `hooks/guard-trusted-writes.py:151-155,279-285`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers paths that `classify_path` detects as HARD through resolve(), through the config dir's resolved form, or through `_HARD_FILE_TARGETS`/`_HARD_DIR_TARGETS`. The probed forms are: the payload's real `/opt` paths; a project `.claude` symlinked to `~/.claude`; the resolved form of a symlinked config dir; resolved-HOME spellings under a symlinked HOME, including a `settings.brandnew.json` that did not exist at import; and relative paths from a cwd of HOME. Every one gives `deny`, tainted and clean. It does not establish that every write reaching a protected file is HARD after resolve(). Writing the target of a per-file symlink inside `CONFIG_DIR/hooks/` is not caught: `hooks/linked.sh -> elsewhere/target.sh`, then a write to `elsewhere/target.sh`. That path resolves to itself, so it classifies `none` and defers, tainted or clean. That is the critic's not-verified item, and it is noted here for the orchestrator.

The deny is emitted with no reference to `tainted`:

```python
# hooks/guard-trusted-writes.py:279-285
        if tier == "hard-resolved":
            # No deny rule names this spelling, so a defer would be no gate at all,
            # and an ask is wrong for a HARD target. Deny outright.
            emit("deny", f"This write reaches a protected policy file ({Path(fp).name}: "
                         ".claude hooks/settings or global CLAUDE.md) through a symlink or "
                         "resolved path that permissions.deny does not name. Edit it at its "
                         "~/.claude path, with review.")
```

The `tainted` flag is read only at `:286` (`if tier == "soft" and tainted:`), after this branch exits.

Executed results (`iter3-subm-probe-s1s2.txt`): all 56 `hard-resolved` cases in layouts L1–L5 gave `deny` for both `tainted` and `clean`, across Edit, Write and MultiEdit, and across `file_path` and `path`. Examples:

- `L1 hard-resolved deny .../opt/cw/hooks/new.sh`
- `L3 hard-resolved deny .../home/proj/.claude/settings.new.json`
- `L1 hard-resolved deny CLAUDE.md` (relative, cwd = HOME)

Through the CLI (`iter3-subm-probe-s2-extra.txt`), a symlinked HOME's real-path spellings (`homereal/CLAUDE.md`, `homereal/.claude/settings.brandnew.json`, `homereal/.claude/hooks/foo.sh`) returned `deny` for both taint states.

The per-file-link case returned empty output (defer) for both taint states: `tainted R/L5/elsewhere/target.sh ->  [rc=0]`. The reason is that `_HARD_DIR_TARGETS` holds only the resolved hooks *directory* (`hooks/guard-trusted-writes.py:102`: `_HARD_DIR_TARGETS = {_safe_resolve(CONFIG_DIR / "hooks")}`), so link targets of individual files inside it are not enumerated. By contrast, the settings files and CLAUDE.md are enumerated as resolved file targets (`:95-101`).

- Commands: as in Claim 33 (`probe-s1s2.sh.txt` exit 0 at 04:39:17Z; `probe-s2-extra.sh.txt` exit 0 at 04:39:40Z; cwd `/workspace`)

**Evidence:** `hooks/guard-trusted-writes.py:95-102`, `hooks/guard-trusted-writes.py:149-155`, `hooks/guard-trusted-writes.py:279-289`; `docs/reviews/execution-logs/iter3-subm-probe-s1s2.txt`; `docs/reviews/execution-logs/iter3-subm-probe-s2-extra.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 35: "An explicit archive prefix outside `[A-Za-z0-9._-]+` is rejected before any path is built."

**Submitted by:** security-reviewer
**Location:** `scripts/archive-working-docs.sh:52-55`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers non-empty explicit prefixes containing `/`, `../`, a space, a newline, a glob, `;`, and a non-ASCII letter. Each exits 1 before `archive/` is created or any file is moved, with or without `--dry-run`. It does not establish four nearby properties:
- The regex accepts `.` and `..`. They are harmless, because the prefix is joined as `${PREFIX}-${name}`, which gives `archive/..-a.md` and cannot traverse.
- An explicit empty argument (`''`) is not rejected. It silently falls back to the run id or the date.
- Behaviour under a UTF-8 locale was not probed: the sandbox runs in the C locale, where `setlocale` fails.
- The run-id-file path (`:43-47`) is gated by its own identical regex, but this claim does not cover it.

The validation runs at `:52`, before `ARCHIVE_DIR` (`:56`) or any `dest` (`:133`) is built:

```bash
# scripts/archive-working-docs.sh:49-56
PREFIX="${PREFIX:-$(date +%Y-%m-%d)}"
# The prefix becomes part of a path, and the morning summary reads it back as a
# Run id; hold an explicit prefix to the same charset as the recorded one.
if ! [[ "$PREFIX" =~ ^[A-Za-z0-9._-]+$ ]]; then
  echo "Error: prefix '$PREFIX' must match [A-Za-z0-9._-]+" >&2
  exit 1
fi
ARCHIVE_DIR="$WORKING_DIR/archive"
```

Before `:52`, the only file access is reading `si-run-id.txt`, and only when `PREFIX` is empty (`:43`: `if [ -z "$PREFIX" ] && [ -f "$WORKING_DIR/si-run-id.txt" ]; then`). The `mkdir -p "$ARCHIVE_DIR"` is at `:121`, and `dest="$ARCHIVE_DIR/${PREFIX}-${name}"` is at `:133`.

Executed results: the script was copied into a scratch dir that was not a git checkout, with a fake `docs/working/a.md`.
- The prefixes `a/b`, `../x`, `a b`, `a\nb`, `a*`, `a;b` and `é` each gave `rc=1 no-archive-dir files: ./docs/working/a.md`, plus the error line.
- `-n a/b` also gave rc=1.
- `.` gave `archive/.-a.md` and `..` gave `archive/..-a.md`, both rc=0.
- `''` fell back to `archive/2026-09-21-a.md`.
- `run-1` gave `archive/run-1-a.md`.

- Command: `bash .../subm/probe-s3.sh.txt` (cwd the scratchpad `subm/`, exit 0, 2026-09-22T04:40:07Z)

**Evidence:** `scripts/archive-working-docs.sh:29-56`, `scripts/archive-working-docs.sh:121-151`; `docs/reviews/execution-logs/iter3-subm-probe-s3.txt`
**Legibility-target:** for-author

---

## Claim 36: "a577546 adds no resolve(), glob or filesystem call per invocation beyond the single _safe_resolve(p) the pre-fix hook already made."

**Submitted by:** performance-reviewer
**Location:** `hooks/guard-trusted-writes.py:104-169` (classify_path and helpers; compared against `2d93589:hooks/guard-trusted-writes.py`)
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers Python-level filesystem entry points, in both the import phase and `main()`, for the L1 installed layout and 77 paths, comparing 2d93589 with a577546 on CPython 3.11.2. The instrumented calls are `os.stat`, `lstat`, `readlink`, `scandir`, `listdir` and `access`, `os.path.realpath`, and `Path.resolve`, `glob` and `exists`. The a577546 copy is byte-identical to the working tree. It does not establish kernel-syscall counts: strace and ltrace are not installed. It also does not cover C-level calls that bypass these wrappers, or other layouts. The code reading below shows that those layouts use the same call sites.

Reading the code: the post-fix `classify_path` still makes exactly one resolve (`hooks/guard-trusted-writes.py:141`: `rp = _safe_resolve(p)`). The new two-pass HARD check uses only pure-path operations. `_rel_under` calls `cand.relative_to(g)` (`:108`). `_is_hard` compares `rel.parts`, `cand.name` and `cand.parent` (`:122-131`). `:154` uses `rp.parents` and set membership. The module-level resolve and glob block (`:88-102`) is unchanged from 2d93589 except for the rename of `_global_rel` to `_rel_under`, which added a `dirs` argument. Paraphrased — no quote available because this is a whole-block equality across two commits; the executed diff below shows it.

The executed results match. The import phase is identical in both versions: `{'Path.glob': 1, 'Path.resolve': 6, 'os.lstat': 86, 'os.readlink': 2, 'os.scandir': 1, 'os.stat': 7, 'posixpath.realpath': 6}`. Per-path `main()` counts were identical for all 77 paths (`paths compared: 77 paths with differing call counts: 0`). Each path makes one `Path.resolve`/`realpath`. The single `Path.exists` is the taint check at `:255`, which both versions have.

- Command: `bash .../subm/probe-s4.sh.txt` (cwd `/workspace`, exit 0, 2026-09-22T04:40:32Z; it depends on the L1 layout built by `probe-s1s2.sh.txt`)

**Evidence:** `hooks/guard-trusted-writes.py:84-155`, `hooks/guard-trusted-writes.py:254-255`; `2d93589:hooks/guard-trusted-writes.py` (`_global_rel`/`_is_hard`/`classify_path`); `docs/reviews/execution-logs/iter3-subm-probe-s4.txt`; the counter is at `docs/reviews/execution-logs/iter3-subm-fscount.py.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
(none)

### Unverifiable
(none)

Advisory for synthesis (not a verdict change): Claim 34 found an adjacent gap. The target of a per-file symlink inside `CONFIG_DIR/hooks/` classifies `none` and is not gated. Its sibling, a symlinked `settings.json` or `CLAUDE.md`, is caught by `_HARD_FILE_TARGETS`. Claim 33's scope also confirms that case variants classify `soft` on Linux, which leaves the case-insensitive-filesystem question the critic flagged open.

---

## Goal-Alignment Note

- **Answered:** I verdicted all four submitted claims (S1–S4 → Claims 33–36), each by execution with provenance and captured logs. The hook probes used the repo copy in hermetic fake layouts with `CLAUDE_CONFIG_DIR` controlled per layout.
- **Out of scope:** I did no fresh claim harvesting. Case-insensitive filesystems could not be probed: there is no such mount in the sandbox. Kernel-level syscall tracing was not possible because strace is absent. I did not edit the Stage-1 merged report.
- **Escalate:** One item for the orchestrator. Writes to the resolve target of a per-file symlink inside `~/.claude/hooks/` get no gate from the hook, and no deny rule names that path (Claim 34 scope). Whether it matters depends on whether any installed layout uses per-file hook links. The documented layout links the whole `hooks` dir.
