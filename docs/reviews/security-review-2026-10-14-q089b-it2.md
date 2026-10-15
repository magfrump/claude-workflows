Commit: 79f22357

# Security Review — Q-089 unit B, iteration 2 (live-verify-gate host-tool split, it1 fixes)

**Scope:** `git diff 88432f39 79f22357`. Code: `hooks/live-verify-gate.sh`, `test/hooks/live-verify-gate.bats`. Prose: `hooks/wiring.json`, `README.md`, `guides/{devcontainer-setup,cc-isolated-usage}.md`, `skills/code-review/SKILL.md` (mechanic 7), `workflows/research-plan-implement.md`, decision log row 71. Context read at 79f22357: `devcontainer-config/cc-isolated.sh` (`enforcement_files`, `host_tool_files`), the full bats file.
**Date:** 2026-10-14
**Based on:** `docs/reviews/code-fact-check-report-q089b.md` (it2), and iteration 1 `docs/reviews/security-review-2026-10-14-q089b.md` (F1-F7).
**Iteration:** 2 of 3, unit B review-fix loop (`--loop-pass`), delta scope.
**Probes:** fresh `mktemp -d` under `/home/node/.claude/jobs/00bcf178/tmp/`, the gate taken from `git archive 79f22357`, `HOME` redirected, `LC_ALL=C`, `GIT_CONFIG_NOSYSTEM=1`, and every hook run under `timeout 20`. Mutants were written to the probe dir only. Script and log: `docs/reviews/execution-logs/sec-q089b-it2/probe-it2.{sh,log}` (written, not committed). The probe repos were removed afterwards, and no process was left running.

The property is unchanged from iteration 1: a commit that changes the boundary cannot leave live verification unasked (decision 45), and a commit that changes a host tool cannot leave host testing unasked (row 71). The gate is a process control, not an adversarial barrier.

## Trust Boundary Map

```
B1: [commit command text + -F file (agent-written)] → [has_trailer grep, per set]                 → [commit allowed into history]
B2: [staged/worktree path list (agent-written)]     → [--no-renames name lists → two regexes] (moved) → [which trailer is demanded]
B3: [staged diff text + repo git config/attributes] → [comment_only_diff, per set]                → [trailer waived]
B4: [repo copy of the two regexes]                  → [bats pins (enforcement_files / host_tool_files)] → [live gate after install]
```

B2 is marked moved: the path list now comes from `--no-renames` calls, and the host regex is no longer end-anchored.

```
S1: tool_input.command / -F file       — request-time  — UNTRUSTED for the trailer decision (the gated party's own text)
S3: git index / worktree path list     — request-time  — UNTRUSTED for set membership (agent picks paths, renames, i-t-a entries)
S4: staged diff body                   — request-time  — UNTRUSTED for the comment-only waiver
S5: the regexes in live-verify-gate.sh — repo-mutable  — UNTRUSTED toward the "which trailer" sink; pinned only as far as bats reaches
S6: enforcement_files()/host_tool_files() — repo-mutable — trusted as the set definitions (the pins' source of truth)
S7: .git/config diff drivers + .gitattributes — repo-mutable (agent-writable) — UNTRUSTED toward the waiver sink
```

The delta's new trust assumptions are that the bats pins tie S5 to S6 in both directions for every gated path, and that `--no-renames` makes S3 list both sides of every move. Both hold for the paths `enforcement_files()` emits. They do not hold for `install.sh`, the one enforcement-regex member that is not in `enforcement_files()` (Finding 1). S7 is new to the map: it is pre-existing and was not listed in iteration 1.

## Verdict on iteration-1 findings

- **F1 (regex swap): closed for every `enforcement_files()` entry, open for `install.sh`.** The per-file loop now asserts both trailer directions (`bats:133-138`). A move of any listed file into `host_tools`, under any spelling, turns "Host-tool-tested alone → 2" red. The new names test (`bats:352-361`) pins the host side. Residual: Finding 1 below.
- **F2 (renames): closed.** The index path is pinned by `bats:375-380`. I executed the `-a` path (R1): an intent-to-add rename (`mv` + `git add -N` + `commit -a`) lists only the destination without `--no-renames`. The gate at 79f22357 blocks it (exit 2). A mutant that drops the flag from the `-a` call lets it through (exit 0). So the flag is load-bearing there, which corrects the fact-check's reading that it might be inert, but no test pins it (Finding 2).
- **F6 (single-trailer docs): closed** (header `:23-27`, behaviour table `:40-47`, `wiring.json`, README).
- **Un-anchored host regex: works, and opens nothing.** R4: `cc-push.sh.orig` is gated as a host tool (Live-verified alone → 2, Host-tool-tested → 0). The only tracked `devcontainer-config/` files with a host-tool prefix are the three tools themselves, and no enforcement name shares a prefix with a host name. The widening is fail-closed only: `boundary_touched` is computed independently of `host_tools`, so nothing added to `host_tools` can drop the Live-verified demand.
- **Mechanic 7 / RPI pre-mortem now naming `host_tools`:** this widens security-critic coverage, which is the safe direction.
- F3-F5 (pathspec/`-o`, `git -C`, shebang) are unchanged and remain pre-existing roadmap Ideas.

## Findings

#### 1. `install.sh` can still move into `host_tools` with every test green

**Severity:** Medium
**Location:** `test/hooks/live-verify-gate.bats:144-156`; `hooks/live-verify-gate.sh:83,91`; `test/hooks/live-verify-gate.bats:355`
**Boundary:** B2, B4 (S5)
**Move:** 11 (bypasses), 5 (invert the access model)
**Confidence:** Medium (the mechanism is executed; it needs a non-canonical spelling to slip past the names test)
**Legibility-target:** for-author

Evidence:

```bash
# bats:144-149 — install.sh's only pin checks the exit code, not which trailer
@test "install.sh is gated although it is not manifest-hashed (decision 035)" {
  echo 'echo hi' > devcontainer-config/install.sh
  git add devcontainer-config/install.sh
  run bash "$HOOK" <<< "$(payload 'git commit -m "fix(install): x"')"
  [ "$status" -eq 2 ]
```
```bash
# bats:355 — the names extractor only sees `\.sh`-escaped names
regex_names="$(grep -E "^host_tools='" "$HOOK" | grep -oE '[a-z-]+\\\.sh' | sed 's/\\\././' | LC_ALL=C sort)"
```
```
# probe-it2.log, R3 (mutant: install\.sh$ removed from enforcement, `install.sh$` added to host_tools)
R3 mutant, install.sh, no trailer: exit 2
R3 mutant, install.sh, Host-tool-tested only: exit 0
R3b extractor on mutant host_tools line:
  cc-exit-scan.sh
  cc-gitdir.sh
  cc-push.sh
```

The F1 fix iterates `enforcement_files()`, and `install.sh` is not in it (decision 035 gates it without hashing it). Its own test was not given the two trailer assertions. `install.sh` is also the most plausible file to "move": it runs on the host, which is the row-71 description of a host tool. Suppose an edit drops `|install\.sh$` from `enforcement` and adds `install.sh` with an unescaped dot (or `install\.(sh)`, or `ins[t]all\.sh`) to `host_tools`. All tests stay green, and from then on an `install.sh` change commits with `Host-tool-tested: no` alone. That is the decision-45 state for the script that picks the diff the human reviews. The canonical spelling `install\.sh` is caught by the names test, which is why confidence is Medium, not High.

**Recommendation:** Add the same two assertions to the `install.sh` test (Host-tool-tested alone → 2, Live-verified → 0). That pins it by behaviour under any spelling. Optionally harden the names test to fail on any host_tools alternative it cannot parse.

#### 2. `--no-renames` on the `-a` call is load-bearing but unpinned

**Severity:** Low
**Location:** `hooks/live-verify-gate.sh:77`; no test
**Boundary:** B2 (S3)
**Move:** 11 (bypasses)
**Confidence:** High
**Legibility-target:** for-author

Evidence:

```bash
# hooks/live-verify-gate.sh:77
  files="$files"$'\n'"$(git diff --name-only --no-renames 2>/dev/null)"
```
```
# probe-it2.log, R1 (mv egress/base.txt base-moved.txt; git add -N base-moved.txt)
R1 worktree name-only (renames on):
  devcontainer-config/base-moved.txt
R1 hook 79f22357, commit -a, no trailer: exit 2
R1 mutant (no --no-renames on -a call), commit -a: exit 0
```

The current code is correct. Removing the flag from line 77 would reopen F2 for `commit -a` with an intent-to-add destination, and nothing would go red. This is a regression-guard gap, not a live bypass. The exposure is narrow (it needs `git add -N`), so it is rated Low.

**Recommendation:** Add a bats case: `mv` a gated file to an ungated name, `git add -N` the destination, `git commit -am x` → exit 2 naming the source path.

#### 3. A repo-local textconv driver makes a real boundary change read as comment-only (pre-existing)

**Severity:** Medium
**Location:** `hooks/live-verify-gate.sh:109,111`
**Boundary:** B3 (S7)
**Move:** 2 (implicit sanitization assumption), 11
**Confidence:** High (executed)
**Legibility-target:** for-author

Evidence:

```bash
# hooks/live-verify-gate.sh:109
  diff_text="$(git diff --cached -U0 --no-color -- "${touched_files[@]}" 2>/dev/null)" || return 1
```
```
# probe-it2.log, R2 (.gitattributes `devcontainer-config/** diff=cm`; git config diff.cm.textconv "sed s/^/#/";
#                    egress/base.txt gains `evil.example.com`)
R2 textconv, real egress widening, no trailer: exit 0
R2 control (textconv removed), no trailer: exit 2
```

Porcelain `git diff` applies textconv filters, and `diff.external` drivers too, unless told not to. The waiver therefore judges filtered text, not the bytes being committed. A committed `.gitattributes` line plus a local `.git/config` driver turns any egress or firewall change into "comment-only", and the commit passes with no trailer. The same applies to host tools. This is not in the delta: `comment_only_diff`'s diff calls are unchanged. It was missed in iteration 1, and it belongs with F3-F5 (the agent controls the gate's inputs). The runtime backstop still holds, because the bless diff shows the real bytes. A `diff.external` driver also runs a program from inside the hook, but it runs as the same user, so it grants no privilege.

**Recommendation:** Pass `--no-textconv --no-ext-diff` to both `git diff` calls in `comment_only_diff`. The name-only calls are not affected. It is one flag pair, so it can ride along with this unit or join the F3-F5 Idea.

## Untested bypass candidates

- A `diff.<driver>.command` external driver set through `.gitattributes` without textconv: this is the same mechanism class as Finding 3 and has the same fix. Not run separately.
- A `core.quotePath`/non-ASCII path in the name list, quoted so the `^devcontainer-config/` regex misses it: no current enforcement name is non-ASCII, but a new `egress/` file could be. Not tested. Pre-existing.
- A case-insensitive filesystem (`Devcontainer-Config/…`): not available here, the same as iteration 1.

## Endorsement Claims

- **Claim:** For each path `enforcement_files()` emits, moving it from `enforcement` into `host_tools` under any spelling turns a bats test red.
  **Location:** `test/hooks/live-verify-gate.bats:121-142`
  **Evidence:** read-static (the loop's assertions, read against the hook's independent set computation at `:92-93`)
  **Verified:** the loop asserts Host-tool-tested alone → 2 and Live-verified → 0 per file; `boundary_touched` is computed from `enforcement` alone.
  **Not verified:** the bats suite was not re-run here (the fact-check it2 ran it); `install.sh`, which the loop does not reach (Finding 1).
  **route: code-fact-check**
- **Claim:** At 79f22357, a rename out of a gated path is gated on both the index path and the `commit -a` intent-to-add path.
  **Location:** `hooks/live-verify-gate.sh:73,77`
  **Evidence:** executed (R1; bats `:375-380` per the fact-check)
  **Verified:** R1 exit 2 on the gate, exit 0 on the flag-dropped mutant.
  **Not verified:** pathspec commits (`git commit -- <path>`), which never read this list (F3, pre-existing).
- **Claim:** The un-anchored `host_tools` regex gates a stray sibling as a host tool and adds no path to the enforcement demand.
  **Location:** `hooks/live-verify-gate.sh:91-93`
  **Evidence:** executed (R4)
  **Verified:** `cc-push.sh.orig`: Live-verified alone → 2, Host-tool-tested → 0.
  **Not verified:** siblings of `cc-exit-scan.sh`/`cc-gitdir.sh` (same regex alternation, not run separately).

## Primitive sweep

Primitive: `git diff` driven by agent-written repo state (S3, S4, S7)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `hooks/live-verify-gate.sh:73` `git diff --cached --name-only --no-renames` | S3 | `--no-renames` | cleared for renames (F2 closed). Pathspec commits bypass it: F3, pre-existing |
| `hooks/live-verify-gate.sh:77` `git diff --name-only --no-renames` | S3 | `--no-renames` | cleared in behaviour; unpinned: Finding 2 |
| `hooks/live-verify-gate.sh:109` `git diff --cached -U0 --no-color --` | S4, S7 | `--`, `--no-color` | Finding 3 (textconv/ext-diff) |
| `hooks/live-verify-gate.sh:111` `git diff -U0 --no-color --` | S4, S7 | `--`, `--no-color` | Finding 3 |

The `-F` file read at `:163` is unchanged since iteration 1 (cleared there). There is no eval, deserialization or network use in scope.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | `install.sh` movable into `host_tools` with all tests green (F1 residual) | Medium | B2, B4 | `bats:144-156`, `hook:83,91` | Medium |
| 3 | textconv/ext-diff driver fakes a comment-only diff (pre-existing) | Medium | B3 | `hook:109,111` | High |
| 2 | `--no-renames` on the `-a` call is unpinned | Low | B2 | `hook:77` | High |

## Overall Assessment

The iteration-1 fixes hold. F2 is closed on both name-list calls, and the `-a` flag does real work: it is not inert, as the fact-check suspected, though it is unpinned. F1 is closed for every manifest-hashed file but not for `install.sh`, the one gated path the new per-file loop cannot reach. That residual (Finding 1) is the single thing to fix before merge, and the fix is two assertions in an existing test. The delta opens nothing: un-anchoring `host_tools` only widens gating, and the doc and mechanic changes widen review coverage. Finding 2 is a cheap regression pin. Finding 3 is a pre-existing waiver bypass of the same class as F3-F5. Its one-flag-pair fix could ride along, or it can join that Idea. No findings beyond these within the code paths read. The first endorsement claim is pending execution verification.

## Goal-Alignment Note
- Success criterion (restated verbatim): report at /workspace/.claude/wt-q089b/docs/reviews/security-review-2026-10-14-q089b-it2.md per the security-reviewer skill, `Commit: 79f22357` at top.
- Answered: yes. F1 is judged closed except for `install.sh` (Finding 1), and F2 is judged closed (executed on both calls). The delta was checked for new openings: none found. The three flagged test gaps were each judged (the `-a` flag: Finding 2; the regex extractor: subsumed by Finding 1; the un-anchored regex: executed, needs no failing test because it is fail-closed).
- Out of scope: F3-F5 (unchanged, roadmap Ideas); the A1/A2 launcher code.
- Escalate: none. Finding 3 is pre-existing; route it with F3-F5 unless the author takes the one-line fix now.
- Decisions I made: rated Finding 1 Medium per the floor rule (a named, executed mechanism), with confidence lowered for the spelling precondition; rated Finding 2 Low because the current code is correct; wrote probe artifacts to `docs/reviews/execution-logs/sec-q089b-it2/` without committing them.
