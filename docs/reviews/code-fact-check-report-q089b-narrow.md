# Code Fact-Check Report

**Repository:** /workspace (worktree `.claude/wt-q089b`, branch `feat/q089b4-host-tool-gate`)
**Commit:** 70097ae0
**Replication:** k=1 (narrow check, Q-148 [1])
**Scope:** `git show 70097ae0` against its parent 5baa9d2f: `hooks/live-verify-gate.sh`, `test/hooks/live-verify-gate.bats`, `guides/devcontainer-setup.md`, `docs/roadmap.md`, and the commit message. The review artifacts the commit adds are context, not checked.
**Checked:** 2026-10-14
**Total claims checked:** 13
**Summary:** 11 verified, 2 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Hallucination log read (`docs/reviews/hallucination-patterns.md`, 5 patterns). The closest prior pattern is the test-count miscount class ("All 85 tests…", "mode1-equiv 33"). Claim 11 is a count claim and was executed for that reason. It matches.

Execution provenance for every `executed` claim: script `docs/reviews/execution-logs/fc-q089b-narrow/run-narrow.sh`, cwd `/workspace/.claude/wt-q089b`, command `timeout 1200 bash docs/reviews/execution-logs/fc-q089b-narrow/run-narrow.sh "$PWD/docs/reviews/execution-logs/fc-q089b-narrow"`, exit 0, started 2026-10-15T03:04:22Z. Probe root `mktemp -d /home/node/.claude/jobs/00bcf178/tmp/fc-narrow.XXXXXX` from `git archive 70097ae0`, with `HOME`, `TMPDIR` redirected, `LC_ALL=C` and `GIT_CONFIG_NOSYSTEM=1`. Removed at the end. Outputs are `summary.txt`, `bats-<name>.log` and `direct-probes.log` in that directory.

---

## Claim 1: "a non-ASCII path is quoted in `--name-only` output under the default `core.quotePath` and misses the anchors (read with `-z`); `diff.relative` with the hook run from a subdirectory drops paths (`--no-relative`)"

**Location:** `docs/roadmap.md:67-70`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both failure modes and both named remedies on the `--cached` name list in a fresh repo. It does not establish the `-a` name list (line 77) under the same conditions, and it does not establish whether the harness ever runs the hook from a subdirectory.

Both quoted paths feed the anchored regexes:

```bash
# hooks/live-verify-gate.sh:73
files="$(git diff --cached --name-only --no-renames 2>/dev/null)" || exit 0
```

The executed probes (`direct-probes.log`, D7 and D8):

```
-- D7 roadmap F3: non-ASCII path under default core.quotePath
   name-only: "devcontainer-config/egress/caf\303\251.txt"
   src: exit 0  (0 = missed by the anchors)
   name-only -z: devcontainer-config/egress/café.txt
-- D8 roadmap F4: diff.relative, hook cwd a subdirectory
   name-only from src/: []  with --no-relative: [devcontainer-config/egress/base.txt]
   src hook from src/: exit 0  (0 = dropped)
```

Probe D6 showed the same miss for an ASCII name containing `"`, which git also quotes: `"devcontainer-config/egress/t\"q.txt"`, exit 0. The Idea says "non-ASCII", which is the narrower case.

**Evidence:** `docs/roadmap.md:63-70`, `hooks/live-verify-gate.sh:73,77,92-93`, `docs/reviews/execution-logs/fc-q089b-narrow/direct-probes.log`

---

## Claim 2: "Host-only tools are not enforcement files for this sequence (decision log row 71; they still count as enforcement files for code-review's mechanic 7 and RPI's bypass-family pre-mortem). They are `cc-exit-scan.sh` … `cc-gitdir.sh` … and `cc-push.sh`."

**Location:** `guides/devcontainer-setup.md:272-276`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the restructured sentence's references (row 71, mechanic 7, the RPI pre-mortem) and its list of three tools. It does not re-verify the rest of the paragraph, which this commit leaves unchanged.

Mechanic 7 says: "host tools carry their own trailer but are still enforcement files here, decision log row 71" (`skills/code-review/SKILL.md:748-749`). The RPI pre-mortem says: "a path matching the `enforcement` or `host_tools` pattern in `hooks/live-verify-gate.sh`; the host-only tools count, decision log row 71" (`workflows/research-plan-implement.md:233`). Decision log row 71 says: "`cc-exit-scan.sh`, `cc-gitdir.sh` and `cc-push.sh` leave `enforcement_files()` for `host_tool_files()`" (`docs/decisions/log.md:94`). The list matches `host_tools='^devcontainer-config/(cc-exit-scan\.sh|cc-gitdir\.sh|cc-push\.sh)'` (`hooks/live-verify-gate.sh:91`). API N6's complaint was that the list hung off "pre-mortem:". After this commit it hangs off "They are" instead.

**Evidence:** `guides/devcontainer-setup.md:272-276`, `skills/code-review/SKILL.md:745-749`, `workflows/research-plan-implement.md:233`, `docs/decisions/log.md:94`, `hooks/live-verify-gate.sh:91`

---

## Claim 3a: "bash runs a `//usr/bin/x` line as a command"

**Location:** `hooks/live-verify-gate.sh:129-130`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bash running a `//`-prefixed absolute path as a command. It does not establish how the Dockerfile parser or python treat a `//` line. Those are parse errors, not commands, and the comment does not claim otherwise.

Probe D0 ran a script whose second line is `//usr/bin/echo RAN` and printed `RAN`, exit 0 (`direct-probes.log`).

**Evidence:** `hooks/live-verify-gate.sh:129-130`, `docs/reviews/execution-logs/fc-q089b-narrow/direct-probes.log`

---

## Claim 3b: "`//` is a comment only in the jsonc devcontainer.json … for every other file it is code" (also "jsonc comment, devcontainer.json only" at :149; "`//` covers the jsonc devcontainer.json" at :101-102)

**Location:** `hooks/live-verify-gate.sh:129-132,149`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which files get the `//` leniency in the touched sets. It does not establish that any consumer reads the extra files that get it. A static check found none.

The leniency is keyed on the header's suffix, not on the one enforcement path:

```bash
# hooks/live-verify-gate.sh:127-133
      'diff --git '*)
        in_header=1
        # `//` is a comment only in the jsonc devcontainer.json: bash runs a
        # `//usr/bin/x` line as a command, so for every other file it is code.
        slashes=0
        case "$line" in *'/devcontainer.json') slashes=1 ;; esac
        continue ;;
```

Neither regex is end-anchored for `egress/` or the host tools (`hooks/live-verify-gate.sh:83,91`). So any touched file named `devcontainer.json` under `devcontainer-config/egress/` or under `devcontainer-config/cc-push.sh.d/` gets the leniency too. Probe D5 added a `//usr/bin/true` line to each, and both passed with no trailer (exit 0, `direct-probes.log`). In practice this does not matter: the manifest hashes only `egress/*.txt` (`for f in egress/*.txt; do …` at `devcontainer-config/cc-isolated.sh:144`), and no script runs these files. That part is paraphrased — no quote available because it is a claim of absence: `git grep devcontainer.json` over `devcontainer-config/` at 70097ae0 finds only the top-level file read (`--override-config "$(config_dir)/devcontainer.json"`, `cc-isolated.sh:582,835`); `install.sh:110` copies `egress` wholesale, so such a file would be installed but never read. A quoted header (`"b/…"`) ends in `"` and never gets the leniency. That is the strict direction, and such paths miss the touched set anyway (Claim 1). The precise version: "`//` is a comment only in files named devcontainer.json".

**Evidence:** `hooks/live-verify-gate.sh:83,91,101-102,127-133,146-150`, `devcontainer-config/cc-isolated.sh:144`, `docs/reviews/execution-logs/fc-q089b-narrow/direct-probes.log`

---

## Claim 4: "`//` now counts only in devcontainer.json (the file is read from each `diff --git` header)"

**Location:** commit 70097ae0 message; `hooks/live-verify-gate.sh:127-133`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the per-header reset across a single `--cached` diff and across the `--cached` plus worktree concatenation under `-a`, in both orders. It does not establish that any test pins the reset (see Claim 6).

`slashes=0` runs on every `diff --git` line, so a file's state never carries into the next. Hunk lines start with `+`, `-`, ` ` or `\`, so they can never match `'diff --git '*`. A commit touching both files, with a `// a note` added to devcontainer.json and `//usr/bin/curl x.invalid` appended to init-firewall.sh, gives `src: exit 2   M5-no-reset: exit 0   M1: exit 0` (D2). The diff lists devcontainer.json first. Without the reset (mutant M5), the script's `//` line inherits `slashes=1` and passes. Under `-a`, D3 (script staged, json unstaged) gives src 2 and M5 2. D4 (json staged, script unstaged) gives src 2 and M5 0. Renames never reach the loop: `grep -Eq '^(…|rename from|similarity index|…)' … && return 1` (`hooks/live-verify-gate.sh:119`).

**Evidence:** `hooks/live-verify-gate.sh:119,121-152`, `docs/reviews/execution-logs/fc-q089b-narrow/direct-probes.log`, `docs/reviews/execution-logs/fc-q089b-narrow/bats-M5-no-reset.log`

---

## Claim 5: "The tests exercising the script say nothing about whether it is wired into the live settings.json … One test reads (never writes) the live settings."

**Location:** `test/hooks/live-verify-gate.bats:20-22`, `:256-258`
**Type:** Staleness / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the count of tests that read settings.json, and the absence of any write to it. It does not establish the wiring test's pass/skip outcome on a wired host.

Only `@test "the gate is wired into the live settings.json"` (`:255`) references `settings`. It reads with `jq -e … "$settings"` (`:275-276`) and never writes. The stale count "Eleven" is gone from both places.

**Evidence:** `test/hooks/live-verify-gate.bats:20-22,255-278`

---

## Claim 6: "a // line is a comment only in devcontainer.json: in a script it is code and is gated" (new test; the commit says "New test" and "restoring `//` for every file fails the new // test")

**Location:** `test/hooks/live-verify-gate.bats:415-423`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the regression the test names, `//` accepted in every file. It does not cover the per-file reset in a mixed commit (mutant M5 survives the whole suite), and it does not cover host-tool scripts.

Mutant M1 replaces `'//'*) [ "$slashes" = 1 ] && continue ;;` with `'//'*) continue ;;`. That gives `M1-slashes-everywhere total=34 notok=1` with `not ok 32 a // line is a comment only in devcontainer.json…` (`summary.txt`). Mutant M5 (the line `slashes=0` deleted) gives `total=34 notok=0`. The test stages only init-firewall.sh, so the slashes state starts at 0 whether or not it is reset. As D2 and D4 show (Claim 4), the reset is load-bearing in a commit that also touches devcontainer.json, and no test fails without it.

**Evidence:** `test/hooks/live-verify-gate.bats:415-423`, `docs/reviews/execution-logs/fc-q089b-narrow/summary.txt`, `bats-M1-slashes-everywhere.log`, `bats-M5-no-reset.log`

---

## Claim 7: "a configured external diff driver cannot make a real change read as comment-only"

**Location:** `test/hooks/live-verify-gate.bats:425-432`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `--no-ext-diff` on the `--cached` call (line 111) against `diff.external`. It does not separately cover an attribute-scoped `diff.<x>.command` on that call.

Mutant M4 drops `--no-ext-diff` from line 111. That gives `M4-cached-extdiff total=34 notok=1` with `not ok 33 a configured external diff driver…` (`summary.txt`). The clean suite passes this test.

**Evidence:** `hooks/live-verify-gate.sh:111`, `test/hooks/live-verify-gate.bats:425-432`, `docs/reviews/execution-logs/fc-q089b-narrow/bats-M4-cached-extdiff.log`

---

## Claim 8: "with -a, a textconv or external diff driver cannot make an unstaged real change read as comment-only"

**Location:** `test/hooks/live-verify-gate.bats:434-446`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both flags removed together, and `--no-ext-diff` removed alone, on the `-a` call (line 113). It does not run `--no-textconv` removed alone. The test's first half is the same shape as the cached textconv test, which the iteration-3 report already mutated.

Mutant M2 (both flags off line 113) and mutant M3 (only `--no-ext-diff` off) each give `total=34 notok=1` with `not ok 34 with -a, a textconv or external diff driver…` (`summary.txt`). M3 shows that the second half, `diff.cm.command`, bites on its own.

**Evidence:** `hooks/live-verify-gate.sh:113`, `test/hooks/live-verify-gate.bats:434-446`, `bats-M2-all-both.log`, `bats-M3-all-extdiff.log`

---

## Claim 9: "Iteration 3 of B's loop (fact-check: 0 Incorrect, 1 Mostly accurate, 1 Stale; security: 2 Medium and 1 Medium-low pre-existing, 1 Low; api: clean, 2 Info)"

**Location:** commit 70097ae0 message, lines 3-5
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the tallies against the three iteration-3 reports the commit adds. It does not judge the severities themselves.

The fact-check tally matches: `**Summary:** 11 verified, 1 mostly accurate, 1 stale, 0 incorrect, 0 unverifiable` (`docs/reviews/code-fact-check-report-q089b.md`). The API tally matches: N6 and N7 are both `**Severity:** Informational`. The security tally is imprecise. The review grades all three pre-existing findings Medium: its summary table has `| 4 | \`diff.relative\` plus a subdirectory cwd hides paths (pre-existing, conditional) | Medium | B2 | \`hook:73,77\` | Low |` (`docs/reviews/security-review-2026-10-14-q089b-it3.md:200`). The "Low" in that row is the Confidence column. No "Medium-low" grade appears in the review. The precise version: "3 Medium pre-existing (one Low-confidence), 1 Low".

**Evidence:** `docs/reviews/security-review-2026-10-14-q089b-it3.md:60,88,114,136,196-201`, `docs/reviews/api-consistency-review-2026-10-14-q089b-it3.md:57-80`, `docs/reviews/code-fact-check-report-q089b.md` (header)

---

## Claim 10: "Mutation checks: restoring `//` for every file fails the new // test; dropping the flags from the -a call fails the new -a test."

**Location:** commit 70097ae0 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both named mutations, re-run independently. It does not establish that the suite catches the per-file-reset mutation, which it does not (Claim 6).

M1 fails exactly test 32. M2 fails exactly test 34 (`summary.txt`).

**Evidence:** `docs/reviews/execution-logs/fc-q089b-narrow/summary.txt`, `bats-M1-slashes-everywhere.log`, `bats-M2-all-both.log`

---

## Claim 11: "live-verify-gate.bats 34/34 under LC_ALL=C; the regex-swap mutation still fails."

**Location:** commit 70097ae0 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count, a clean pass with the invoking environment at `LC_ALL=C`, and the init-firewall.sh regex swap into `host_tools` failing the suite. It does not mean the tests run in the C locale. `pin_hermetic_locale` (`test/lib/hermetic-env.bash:27-35`) re-exports a UTF-8 locale inside the suite.

`== count: 34` and `clean total=34 notok=0 exit=0`. The swap (init-firewall.sh moved from `enforcement` to `host_tools`) gives `M6-swap-full total=34 notok=2`: `not ok 8 every manifest-hashed file is in the enforcement set` and `not ok 26 the hook's host_tools regex names exactly host_tool_files, no more` (`summary.txt`). Matches the hallucination log's count-claim pattern class. Here the count is correct.

**Evidence:** `docs/reviews/execution-logs/fc-q089b-narrow/summary.txt`, `bats-clean.log`, `bats-M6-swap-full.log`

---

## Claim 12: "the comment-only escape treated a `//` line as a comment in every file … so a line appended to init-firewall.sh or cc-push.sh passed with no trailer"

**Location:** commit 70097ae0 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the pre-fix rule (`'#'*|'//'*) continue ;;` at the parent's `:142`) admitting a `//` line in init-firewall.sh, executed through M1, which restores that rule. It covers cc-push.sh only statically: the host-tool set goes through the same `comment_only_diff` (`hooks/live-verify-gate.sh:163`).

The parent's rule is `'#'*|'//'*) continue ;;      # comment` (diff `-` line). With that rule restored, D2's init-firewall.sh `//usr/bin/curl` line gives `M1: exit 0`. The test at `:415` turns red (Claim 6).

**Evidence:** `hooks/live-verify-gate.sh:162-163` (70097ae0), parent `hooks/live-verify-gate.sh:142`, `docs/reviews/execution-logs/fc-q089b-narrow/direct-probes.log`

---

## Claim 13: jsonc comment edits to devcontainer.json still pass (existing test "a // comment-only change to devcontainer.json passes")

**Location:** `test/hooks/live-verify-gate.bats:243-253`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers adding a `//` line staged, editing it unstaged under `-a`, and staged edits to an existing `//` line in `devcontainer-config/devcontainer.json`. It does not cover `/* */` block comments, which gate (the strict direction).

The clean suite passes test `:243` (`bats-clean.log`). D1 gives exit 0 for the staged add, the `-a` edit, and the staged edit of an existing `//` line (`direct-probes.log`).

**Evidence:** `test/hooks/live-verify-gate.bats:243-253`, `hooks/live-verify-gate.sh:132,149`, `docs/reviews/execution-logs/fc-q089b-narrow/direct-probes.log`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 3b** (`hooks/live-verify-gate.sh:129-132,149`): the leniency applies to any touched file named `devcontainer.json` (e.g. `egress/devcontainer.json`, `cc-push.sh.d/devcontainer.json`), not only the enforcement file. It has no effect in practice, since no consumer reads those files. Precise wording: "only in files named devcontainer.json". Alternatively, match the header exactly against `b/devcontainer-config/devcontainer.json`.
- **Claim 9** (commit message): the security review grades F4 Medium, with Low confidence. There is no "Medium-low" grade. The tally is 3 Medium pre-existing plus 1 Low.

### Unverifiable
(none)

### Not a verdict, carried for the loop
- **Claim 6 / Claim 4 residue:** the per-header `slashes=0` reset is load-bearing (D2, D4), but no test pins it. Mutant M5 keeps the suite at 34/34. A mixed commit, with devcontainer.json listed before a script, is the missing case.

---

## Goal-Alignment Note

The goal is to land Q-089 unit B with its iteration-3 fix commit checked narrowly before merge. Nothing in 70097ae0 is Incorrect. Each new test fails on the regression it names (M1, M2/M3, M4), the jsonc path still passes, and the count and mutation claims reproduce. Two wording imprecisions remain (Claims 3b, 9), and neither misleads a reader acting on the gate. One gap bears on merge readiness. The fix's core mechanism, resetting `slashes` on each `diff --git` header, is correct in code but has no test, so a later edit could drop it silently and reopen security F1 for any commit that also touches devcontainer.json. Whether that warrants another fix round before merge is the loop's call under Q-148 [1]. The test is about eight lines: the `:415` case plus a `//` comment added to devcontainer.json in the same staged diff.
