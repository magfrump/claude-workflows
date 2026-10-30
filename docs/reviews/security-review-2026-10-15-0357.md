Commit: 16136a60

# Security Review: chore/dev-cycle-2026-10-15-0357

**Scope:** `git diff main...HEAD` at 16136a60. It touches 5 files, all under `docs/`: `docs/working/questions.md`, `docs/roadmap.md`, `docs/working/idea-log.md`, `docs/working/questions-archive.md` and `docs/working/cycles/cycle-2026-10-14.md`. The review also covers the branches and docs that the new entries tell the user to run or merge.
**Date:** 2026-10-15
**Based on:** `docs/reviews/code-fact-check-report-2026-10-15-0357.md` (stage 1, k=1, untracked in this worktree)

No HALT escalation. None of the five escalation patterns matches. A grep of the diff's added lines for key, token, password and private-key shapes found only the prose word "secret" in Q-176.

## Trust Boundary Map

The diff adds no executable code. Its security surface is shell text that the user copies from an agent-written document and runs with their own host privileges, plus option tables that tell the user what a merge decision costs.

```
B1 (new): [agent-written doc text (questions.md, spike doc)] → [user copy-paste]              → [host shell, user uid, outside any sandbox]
B2 (new): [agent-movable git refs (merge/*, fix/*)]           → [paste's `git merge <name>`]   → [main → install.sh → host tools / image]
B3 (new): [host `claude` session, user uid]                   → [always-allow PreToolUse hook] → [host Bash execution]
B4:       [branch config tree (devcontainer.json, staged)]    → [main's launcher, staged run]  → [docker on host / "Live-verified" record]
B5:       [option-table framing in a you: judgment entry]     → [user's answer]                → [what enforcement/gate code lands]
```

Input-source classification:

```
S1: questions.md / spike-doc text in /workspace          — runtime-mutable (any agent session with repo write) — UNTRUSTED toward host exec;
                                                            trusted only as far as the user re-derives it from a pinned commit
S2: branch refs merge/ready-2026-10-15, merge/u5-and-q145,
    merge/build-loop-u5-resolved                         — runtime-mutable (agents create and move them; the ready branch took 19
                                                            first-parent merges) — UNTRUSTED toward merge-into-main
S3: pinned commit hashes in the entries (c035f2e7…, unit hashes) — code-constant once read from a reviewed commit — trusted for merge
S4: model-chosen Bash commands in the Q-176 host session — request-time (model output) — UNTRUSTED toward exec
S5: host Claude Code version (Q-176) vs container version — deploy-time — trusted as a fact, but not interchangeable (see F4)
S6: staged config tree (Q-166/Q-169)                     — runtime-mutable until bless (A17/A18 residuals) — UNTRUSTED toward docker/exec
```

Prose summary. Everything the user runs comes from an agent-writable checkout (S1, S2). The entries assume that what the user pastes, and the ref it names, are what was reviewed. Only a self-reported hash (Q-169) and the hash-pinned option in Q-163 bind them to it. B3 and B5 are framing boundaries: there, the text decides how much host authority a check grants and how much enforcement coverage an answer gives up.

## Findings

#### F1. Merge pastes bind to movable branch names, not reviewed hashes

**Severity:** Medium
**Location:** `docs/working/questions.md:83-89` (Q-162), `:113-115` (Q-163), `:143-145` (Q-164)
**Boundary:** B2, B1
**Move:** 1 (trust per sink), 4 (TOCTOU)
**Confidence:** Medium
**Legibility-target:** for-author

Evidence:
```
git merge --no-ff merge/ready-2026-10-15 -m "Merge branch 'merge/ready-2026-10-15': T69, Q-110, ...
if git merge-base --is-ancestor 7c91b974... HEAD; then B=merge/u5-and-q145; else B=c035f2e77f8c083156b397fb32e164dd17cc6b44; fi && \
if git merge-base --is-ancestor c035f2e7... HEAD; then B=merge/u5-and-q145; else B=merge/build-loop-u5-resolved; fi && \
- **Gate for the whole branch** (3fe6d6e3, 2026-10-15): ... The branch changes no gate or lib code.
```

Q-162's prose lists each unit's reviewed hash. The command itself merges whatever `merge/ready-2026-10-15` points to at paste time, and the entry never states that tip. The ref is agent-writable: the branch is at a760a5e5 now, after 19 first-parent merges, while the "whole branch" gate was run at 3fe6d6e3. Two code units, `fix/rebuild-hint-recreate` (c29d1acf) and `fix/cc-isolated-one-workspace` (fc4c6840), were merged in after that gate. Each unit was gated on its own, but no gate is recorded at the tip the user will merge. Q-164 merges by name in both arms, and Q-163 does in one arm.

Any agent session with repo write can move one of these refs between review and paste. A buggy dispatch or a hostile-branch merge would do it without intent. The user then lands unreviewed content in main. From main it flows into `install.sh` (Q-167) and so into host tools and the image. The install review diff is the remaining stop, and it is a human reading a large diff.

I checked the refs today: a760a5e5 contains exactly the units Q-162 lists, and none of Q-106, Q-168, Q-092 or the egress fix. So nothing is wrong now. The weakness is that the binding is missing.

Q-162 also has no `|| git merge --abort`. The fact-check (Claim 13) found that it conflicts on today's main and merges cleanly only after this branch lands. On a conflict it leaves the shared `/workspace` checkout mid-merge, where other sessions operate.

**Recommendation:** pin each paste to the tip hash it was reviewed at. Either merge the hash (`git merge --no-ff a760a5e5…`) or guard the merge with `test "$(git rev-parse merge/ready-2026-10-15)" = <full hash>`. Record the gate at that tip, not at 3fe6d6e3. Give Q-162 the same `|| { git merge --abort; …; }` wrapper that Q-163 and Q-164 use.

#### F2. Q-176's host check auto-approves every Bash command in an unsandboxed host session

**Severity:** Medium
**Location:** `docs/working/questions.md:368-379` (Q-176)
**Boundary:** B3, B1
**Move:** 5 (invert the access model), 11 (bypasses)
**Confidence:** Medium
**Legibility-target:** for-author

Evidence:
```
mkdir -p ~/q092/.claude && cd ~/q092 && ... '  "hooks": { "PreToolUse": [ { "matcher": "Bash", "hooks": [ { "type": "command",' '    "command": "echo '"'"'{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"allow\"}}'"'"'" } ] } ] }' '}' > .claude/settings.local.json && claude --version && claude
This check settles it with a throwaway always-allow hook; it needs no merge. Run on the host:
```

The hook returns `allow` for every Bash call. The deny list holds only `Bash(*.q092-canary*)` and `Bash(rm -rf:*)`, plus whatever the user's global settings contribute. So in this session, any Bash command that no deny rule matches runs on the host without a prompt, with the user's uid, credentials, SSH keys and Docker socket.

The test is built to produce denials, and a model that is denied tends to try alternatives: a different spelling, `python -c open(...)`, `ls`, `cd ..`. Each of those retries is auto-approved. The three test payloads are benign (a canary file, a non-existent `./nothing-here`). The model's own follow-ups are not bounded by them.

The entry calls the hook "throwaway" and says nothing about this exposure. If the user skips the final `rm -rf ~/q092`, the allow-all `settings.local.json` stays behind for any later `claude` started there.

**Recommendation:** make the hook approve only the three exact test commands and emit nothing otherwise, so normal prompting applies to anything else. Alternatively, run the check inside a `cc-isolated` container, which also fixes F4's version question. Add one line telling the user to answer "no" to any other tool call, and to delete `~/q092` even if the session errors.

#### F3. Q-176 omits two of the four spellings its own source names, but "all denied" lands Q-092

**Severity:** Medium
**Location:** `docs/working/questions.md:368`, `:374-377` (Q-176); `:393` (Q-177 option [1])
**Boundary:** B5, B3
**Move:** 11 (enumerate bypasses)
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

Evidence:
```
Main's hook stays silent on `.cred""entials.json`, `.c\redentials.json`, `git "push"` and `cat "secret"`; the branch's hook approves them.
1. `cat x.q092-ca""nary`
2. `cat x.q092-c\anary`
3. `echo hi && rm -rf ./nothing-here`
| **[1] Merge if Q-176 is all "denied"** | The loop adds both units to the ready branch | Nothing more | — |
```

The independent review's MA1 (`docs/reviews/independent-review-2026-10-15-q092b.md:29-30` at aeda94b2) names four spellings that go from silent to `allow`. Two use a glob rule with a quote or backslash mid-word, and two quote a whole word under a prefix rule (`git "push"`) or an exact rule (`cat "secret"`). Q-176 tests both glob spellings and an unquoted compound against a prefix rule. It does not test a quoted word under a prefix or exact rule.

Glob, prefix and exact matching are separate cases in Claude Code's matcher, so passing the glob cases says nothing about `git "push"`. Under Q-177 [1], an "all denied" result lands Q-092, removing the hook's backstop for exactly the untested class. In cc-isolated (no sandbox until Q-125), a quoted `git "push"` or a quoted credential read could then auto-approve.

Q-177 [1]'s "If it's wrong" cell is `—`, which understates this. The test also has no positive control (an unquoted `cat x.q092-canary` expected "denied"), so a malformed glob rule would show up as quote bypasses. That failure mode is conservative, but it wastes a round.

**Recommendation:** add a prefix-rule deny (for example `Bash(git push:*)` against a throwaway remote, or `Bash(cat secret-q092:*)`) and test `git "push"`-shaped and `cat "secret-q092"`-shaped spellings, plus one unquoted control. Fill Q-177 [1]'s "If it's wrong" cell.

#### F4. The host's Claude Code version stands in for the container's

**Severity:** Medium
**Location:** `docs/working/questions.md:371` (`claude --version && claude`), `:379`, `:382`
**Boundary:** B5 (S5)
**Move:** 2 (implicit assumption)
**Confidence:** Low
**Legibility-target:** for-orchestrator-synthesis

Evidence:
```
Then exit and `rm -rf ~/q092`. Paste back the version line and the three results.
- **If the answer differs:** any "runs" sends Q-177 to its options; all "denied" lands Q-092.
```

The hook that loses its deny reader runs in cc-isolated sessions. The deny matcher that has to replace it is therefore the container's Claude Code, and this diff's own idea log records that "a recreated container goes back to the image's Claude Code version" (image lag). Q-176 runs the host `claude`. Nothing compares the version it pastes back with the container's, and the landing rule does not depend on them matching.

If the container's Claude Code is older and its matcher misses a spelling the host build catches, Q-092 lands on a host result that does not hold where the hook runs. Confidence is Low because the two versions may well match on the day.

**Recommendation:** record the container's `claude --version` next to the host's and make "all denied" land Q-092 only if they match. Running the check in cc-isolated (F2) resolves this too.

#### F5. Q-169's integrity check is self-reported, and the doc it comes from is agent-writable

**Severity:** Medium
**Location:** `docs/working/questions.md:247-248` (Q-169); `docs/working/spike-cc-verify-q117.md:343-345` (on `merge/ready-2026-10-15`, lands via Q-162)
**Boundary:** B1 (S1)
**Move:** 2 (implicit sanitization assumption), 6
**Confidence:** High (mechanism); Medium (likelihood)
**Legibility-target:** for-author

Evidence:
```
- **The paste:** the single ```bash block in `docs/working/spike-cc-verify-q117.md` (498 lines with its fences; sha256 of the block 032cc9a8…afb7). Edit only its last line, the checkout path. Its first output line must be `script sha256 a65f4c30ba1b8907`; any other value means it is not the reviewed block, so press Ctrl-C.
# Compare this with the hash the doc gives next to the block: a different hash means the
# block you pasted is not the reviewed one.
[ -n "${BASH_EXECUTION_STRING:-}" ] && echo "   script sha256 $(printf '%s' "$BASH_EXECUTION_STRING" | sha256sum | cut -c1-16)"
```

The "reviewed block" check is a line that the block prints about itself. It catches a truncated or mis-copied paste, and that is all it can catch. An edited block can print `script sha256 a65f4c30ba1b8907` as a literal and pass. The block hash in the entry is elided (`032cc9a8…afb7`), and nothing tells the user to compute it.

The entry itself names the threat: a same-uid writer, and the worst cases of host code execution and writes anywhere the user can write. The same writer can edit `docs/working/spike-cc-verify-q117.md` in the `/workspace` checkout the user copies from. That happens before the paste, so the `denyWrite` on `~/cc-verify` that Q-169 recommends does not cover it. The block is ~500 lines and runs outside any sandbox. A one-line insertion would not stand out.

I recomputed both values against the doc at a760a5e5. The heredoc body hashes to `a65f4c30ba1b8907` and the block lines 50–545 to `032cc9a81e4e1c92…ccfed4afb7`. The doc and the entry are consistent today.

**Recommendation:** have the user take the block from a pinned commit (`git show <reviewed hash>:docs/working/spike-cc-verify-q117.md`). Give the full block sha256 in the entry with a one-line command to check it before running (for example, save the block and run `sha256sum`). Reword "any other value means…" so the printed line is not presented as proof of review.

#### F6. Q-175 presents a loss of gate coverage as "the same status as wiring.json"

**Severity:** Medium
**Location:** `docs/working/questions.md:354-362` (Q-175)
**Boundary:** B5
**Move:** 1 (boundary moved), 5
**Confidence:** Medium
**Legibility-target:** for-author

Evidence:
```
Q-106 moved the settings merge jq into `hooks/lib/wiring-merge.jq`, which is outside `live-verify-gate.sh`'s `enforcement` regex.
| **[1] Accept it in the `hooks/**` class** | Same status as `wiring.json` and `guard-trusted-writes.py` | Nothing | A change to the merge program commits without a `Live-verified:` trailer |
- **Interim:** [1].
```

On main, the merge program is inline jq in `devcontainer-config/link-claude-home.sh:133` (main). That file is in the gate's regex (`hooks/live-verify-gate.sh:83`: `...|link-claude-home\.sh|...`). Q-106 (`feat/q106-host-settings-merge`, `link-claude-home.sh:92,115`) moves the program out to `hooks/lib/wiring-merge.jq`. The question is therefore whether to accept the removal of coverage that exists today, not whether to extend coverage to a new file.

The program writes the deny rules and hook wiring into the container's settings and, after Q-106, the host's. Under interim [1], a later regression that drops or rewrites deny rules commits with no live check. What remains is the trust-manifest hash and the install review diff, which a human reads.

The option text is accurate as far as it goes, but "same status as wiring.json" hides the direction of the change, and the interim defaults to the coverage loss.

**Recommendation:** reword Q-175 to say the program was gated in place and the move ungates it. Consider making [2] the interim until answered, since it restores the status quo ante.

#### F7. Q-166 [1] understates what a staged run leaves unverified for Q-125

**Severity:** Low
**Location:** `docs/working/questions.md:185-195` (Q-166)
**Boundary:** B4, B5
**Move:** 2
**Confidence:** Medium
**Legibility-target:** for-author

Evidence:
```
| **[1] Yes** | Merge on a passing staged run, with the trailer `Live-verified: <hash> — cc-verify of tree <id>`. Main's post-merge install re-probes on first launch anyway | Nothing extra | A difference between the staged and installed config shows only at that first launch; revert as in Q-125's rollback plan |
```

`feat/q125-cc-isolated-sandbox` changes host launcher code, not only config. `cc-isolated.sh` `enforcement_files()` adds `seccomp-cc-sandbox.json`, `managed-settings.json` and `cc-sandbox-settings.sh`, and install.sh's `PAYLOAD` adds the same files. A staged run executes main's launcher by design, so the branch's tamper-check list never runs. During the staged run, main's `check_manifest` also leaves the three new boundary files unchecked.

A `Live-verified:` trailer earned this way certifies the container side only. [1]'s "If it's wrong" mentions only config differences. Q-117's branch touches only `init-firewall.sh`, so it is not affected. Severity is Low because interim [2], the post-merge probe, closes the gap.

**Recommendation:** in [1], say the staged run does not exercise the branch's host-side launcher or install changes. Have `cc-verify` refuse to accept a staged pass as live-verify for a branch that touches `cc-isolated.sh` or `install.sh`.

#### F8. Q-167 (c)'s paste block holds `#` lines that default zsh runs as commands

**Severity:** Informational
**Location:** `docs/working/questions.md:224-228` (Q-167 (c))
**Boundary:** B1
**Move:** 3 (error path)
**Confidence:** Medium
**Legibility-target:** for-author

Evidence:
```
T="$(mktemp -d)" && git init -q "$T/proj" && cd "$T/proj" && ... && cc-isolated "$T/proj"; echo "cc-isolated exit=$?   (expect 3, naming hook …/mirror-repo/hooks/pre-receive)"; cd "$HOME" && rm -rf "$T"
# Step 2, inside the session at Claude's prompt, then exit the session:
#   ! printf '#!/bin/sh\necho planted\n' > mirror-repo/hooks/pre-receive && chmod +x mirror-repo/hooks/pre-receive
```

Q-167 (b) relies on the fact that interactive zsh does not treat `#` as a comment. In (c), the two "comment" lines are inside the copy block. With bracketed paste, they run on the host after the session exits and the shell has `cd`'d to `$HOME`. Line 3's redirect targets `$HOME/mirror-repo/hooks/…`, which does not exist, so it fails harmlessly.

Without bracketed paste, the two lines are typed into the running session's prompt. I traced this; I did not execute it. No harmful outcome was found, but the step-2 instruction belongs outside the fence. The temp-dir handling holds: when `mktemp` fails, the `&&` chain stops and `rm -rf ""` is a no-op.

**Recommendation:** move step 2's text out of the fenced block.

### Untested bypass candidates

These are for the guardrails the entries rely on (move 11). I did not execute any of them: the brief forbids running paste blocks, and none of them needs a live host to argue.

- Q-169 self-hash: an edited block that prints the expected string as a literal. Traced, F5. Not executed.
- Q-162 ref: `merge/ready-2026-10-15` moved by another session between review and paste. Traced, F1. Not executed (it would move a ref).
- Q-176 matcher: `git "push"`, `"cat" secret`, `cat "secret"` under prefix and exact rules. Not tested; F3.
- Q-176 hook: the model's own retry commands after a denial. Not tested; F2.
- Q-163 and Q-164 abort wrappers: a non-conflict merge failure such as a missing ref. Traced: `git merge --abort` then errors harmlessly and the echo misattributes it to a conflict. Not executed.

## Endorsement Claims

- **Claim:** `merge/ready-2026-10-15` at a760a5e5 contains the seven units Q-162 lists plus the two docs branches, and does not contain c6d7544f (Q-106), 75d08a94 (Q-168), b26d4b8b (egress), d27a3891 or aeda94b2 (Q-092). Every non-docs file it changes maps to one of the listed units.
  **Location:** `docs/working/questions.md:83`
  **Evidence:** executed
  **Verified:** `git merge-base --is-ancestor` for 16 hashes; a per-file `git diff --quiet main...<unit>` map.
  **Not verified:** the ref's value when the user pastes (F1).
  **route: code-fact-check**
- **Claim:** Q-169's two published hashes match the spike doc at a760a5e5. The heredoc body hashes to `a65f4c30ba1b8907`, and block lines 50–545 hash to `032cc9a8…afb7`.
  **Location:** `docs/working/questions.md:247`
  **Evidence:** executed
  **Verified:** `awk` extraction of the doc and `sha256sum` (heredoc body without its trailing newline, as `$(cat <<…)` yields).
  **Not verified:** the copy the user will open in `/workspace` after Q-162 lands (F5).
- **Claim:** Q-162's cleanup loop uses `git branch -d` and an unforced `git worktree remove`, so an unmerged branch or a dirty worktree is refused, not destroyed.
  **Location:** `docs/working/questions.md:88`
  **Evidence:** read-static
  **Verified:** the paste text, and fact-check Claim 9 and Claim 14 (all 12 branches merged, worktrees clean).
  **Not verified:** a worktree that is locked or in use by a live session when the paste runs.
- **Claim:** the added lines contain no credential-shaped literals.
  **Location:** the whole diff
  **Evidence:** executed
  **Verified:** a case-insensitive grep of `+` lines for api-key, token=, password, secret, `sk-`, `ghp_` and private-key headers; one prose hit.
  **Not verified:** branches referenced but not in this diff.

## Primitive sweep

Primitive: host shell execution of agent-authored paste text (an exec sink fed by S1/S2). These are all 7 fenced blocks the diff adds, plus the external block Q-169 points to.

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `questions.md:86-88` Q-162 | S1, S2 (ref name) | `test` branch = main; `-d` and unforced remove | F1 (unpinned ref, no abort) |
| `questions.md:113-115` Q-163 | S1, S2 / S3 | branch test; `merge --abort` on failure; hash in one arm | F1 (name in one arm); otherwise cleared |
| `questions.md:143-145` Q-164 | S1, S2 | branch test; `merge --abort` on failure | F1 (names in both arms) |
| `questions.md:206` Q-167 (a) | S1 | none needed (`--probe-only`, `--list`) | cleared. The expected output is wrong (fact-check Claim 22): correctness, not security |
| `questions.md:214-217` Q-167 (b) | S1 | the launcher's own exit-2 refusals | cleared. Intended refusal probes; the last line probes a user-chosen repo |
| `questions.md:225-227` Q-167 (c) | S1 | `mktemp` `&&` chain; cleanup `rm -rf "$T"` | F8 (Informational) |
| `questions.md:371` Q-176 | S1, S4 | deny list (2 rules) only | F2, F3, F4 |
| `spike-cc-verify-q117.md:49-546` via Q-169 | S1, S6 | self-reported hash; in-script refusals; the `denyWrite` advice | F5. In-script logic is out of this diff's scope (reviewed in `security-review-2026-10-15-cc-verify-spike.md` on the ready branch) |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| F1 | Merge pastes bind to movable branch names, not reviewed hashes; Q-162 has no abort | Medium | B2, B1 | `docs/working/questions.md:86-88,113-115,143-145` | Medium |
| F2 | Q-176's always-allow hook auto-approves every Bash command on the host | Medium | B3, B1 | `docs/working/questions.md:371` | Medium |
| F3 | Q-176 omits quoted prefix/exact-rule spellings, but "all denied" lands Q-092 | Medium | B5, B3 | `docs/working/questions.md:368-377,393` | Medium |
| F5 | Q-169's integrity check is self-reported; the source doc is agent-writable | Medium | B1 | `docs/working/questions.md:247-248` | High (mechanism) |
| F6 | Q-175 presents a loss of gate coverage as parity with wiring.json | Medium | B5 | `docs/working/questions.md:354-362` | Medium |
| F4 | Host Claude Code version stands in for the container's in Q-176 | Medium | B5 | `docs/working/questions.md:371,379,382` | Low |
| F7 | Q-166 [1] understates what a staged run leaves unverified for Q-125 | Low | B4, B5 | `docs/working/questions.md:191` | Medium |
| F8 | Q-167 (c)'s paste block holds `#` lines that run in default zsh | Informational | B1 | `docs/working/questions.md:226-227` | Medium |

## Overall Assessment

The diff changes only docs and runs nothing by itself. No finding blocks landing it, and landing it is what makes Q-162's merge clean (fact-check Claim 13). All the findings are text fixes inside question entries, and none needs an architectural change.

They share one pattern: host-run pastes and decision tables assume that the agent-writable text and refs the user acts on are the reviewed ones (F1, F5). In the one live-check that grants authority (Q-176), the scope of that authority, the spelling coverage and the version under test are looser than the decision it feeds (F2–F4).

The single most important fix is Q-176: narrow the always-allow hook, add the quoted prefix and exact-rule cases, and check against the container's version. Its result directly decides whether an enforcement backstop is removed. Next is pinning Q-162/Q-164 to hashes before the user pastes them.

There are no findings within the code paths read beyond those listed. Endorsement claims are pending execution verification where routed.

## Goal-Alignment Note

- **Success criterion (verbatim):** "A markdown report saved to docs/reviews/security-review-2026-10-15-0357.md (first line `Commit: 16136a60`), structured per the security-reviewer skill."
- **Answered:**
  - The paste blocks are safe to land as text.
  - Q-163 and Q-164 abort safely.
  - Q-162 is safe only after this branch lands, and it binds to an unpinned ref (F1).
  - Framing that understates trust-boundary consequences:
    - Q-175 hides that the move removes existing gate coverage (F6).
    - Q-092/Q-176/Q-177 test too narrowly and scope the always-allow hook too widely (F2–F4); Q-177 [1]'s `—` understates the consequence.
    - Q-166 [1] understates for Q-125, though not for Q-117 (F7).
    - Q-169's hash check is self-attesting (F5).
- **Out of scope:**
  - The internal logic of the ~500-line spike block (it has its own security review on the ready branch).
  - The behaviour of the Q-092, Q-106 and Q-125 branches themselves.
  - Fact-check Claim 22's wrong `--list` expectation in Q-167 (a). That is a correctness fix the author should make, and the fact-check already owns it.
  - No paste, install, merge or ref move was run. The only processes run were read-only `git` and `sha256sum` commands, all finished.
- **Escalate:** none at the HALT level. F2/F3 should be fixed before the user runs Q-176, and F1 before the user runs Q-162/Q-164, so the orchestrator should apply them as part of this branch's fix pass rather than defer them.
- **Questions/Decisions:**
  - Should Q-175's interim be [2] (restore coverage) rather than [1]? This is a user judgment; the review only flags the framing.
