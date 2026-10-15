# Code Fact-Check Report

**Repository:** claude-workflows (worktree `/workspace/.claude/wt-q089b`, branch `feat/q089b4-host-tool-gate`)
**Scope:** `git diff 79f22357 25d8f272`: the iteration-2 fix commit 25d8f272 (its message, `hooks/live-verify-gate.sh`, `test/hooks/live-verify-gate.bats`, `guides/devcontainer-setup.md`, `docs/decisions/log.md` row 71, and the probe scripts it adds under `docs/reviews/execution-logs/`). 5baa9d2f (the Q-148 questions entry) is after the scope.
**Commit:** 25d8f272
**Replication:** k=1 (loop pass, decision 031)
**Checked:** 2026-10-14
**Total claims checked:** 13
**Summary:** 11 verified, 1 mostly accurate, 1 stale, 0 incorrect, 0 unverifiable

Execution: every executed claim ran under `timeout` in a fresh `mktemp -d` probe root
(`/home/node/.claude/jobs/00bcf178/tmp/fc-it3.MvtTEz`, removed afterwards), extracted from
`git archive 25d8f272` (plus `git archive 79f22357 hooks/live-verify-gate.sh` for the
old-hook run), with `HOME` redirected into the probe root, `LC_ALL=C`,
`GIT_CONFIG_NOSYSTEM=1`, and `CLAUDE_DEVC_CONFIG_DIR`, `CLAUDE_CONFIG_DIR` and
`CC_LIVE_VERIFY_GATE_DISABLE` unset. Driver:
`docs/reviews/execution-logs/fc-q089b-it3/run-it3.sh`, invoked from `/workspace/.claude/wt-q089b`
as `timeout 1500 bash docs/reviews/execution-logs/fc-q089b-it3/run-it3.sh <abs logs dir>`,
exit 0, 2026-10-15T02:57:02Z to 02:58:04Z (`fc-q089b-it3/summary.txt`). Each mutation edits
one copy of the hook and runs the full suite; per-run logs are `fc-q089b-it3/bats-<name>.log`,
each recording cwd, start time, command and `exit=`. Tool versions: bats 1.8.2, shellcheck 0.9.0.
The hallucination pattern log (`docs/reviews/hallucination-patterns.md`) was read first; no
claim below matches a logged pattern (its entries are mis-quoted counts and file-to-symbol
associations; both counts in this commit check out, Claims 10 and 11).

| Run | Mutation | Result |
|---|---|---|
| clean | none | 31/31 ok |
| old-hook-79f22357 | 79f22357's hook under 25d8f272's suite | 1 not ok: 30 (textconv) |
| M1-swap-full | `init-firewall.sh` moved from `enforcement` to `host_tools` | 2 not ok: 8, 26 |
| Ma-all-renames | `--no-renames` dropped from the `-a` name list (:77) | 1 not ok: 29 |
| Mb-cached-both | both flags dropped from the `--cached` diff (:111) | 1 not ok: 30 |
| Mc-cached-textconv | only `--no-textconv` dropped (:111) | 1 not ok: 30 |
| Md-cached-extdiff | only `--no-ext-diff` dropped (:111) | 31/31 ok |
| Me-all-both | both flags dropped from the `-a` worktree diff (:113) | 31/31 ok |
| Mf-endanchor | `$` anchor restored on `host_tools` (:91) | 1 not ok: 31 |
| Mg-install-host-full | `install\.sh$` moved from `enforcement` to `host_tools` | 2 not ok: 9 (at :155), 26 |

---

## Claim 1: "They remain enforcement files for code-review's mechanic 7 and RPI's bypass-family pre-mortem (rows 60, 61(4)): both now name the gate's `enforcement` and `host_tools` regexes." (and the commit's "api N2: row 71 no longer quotes a phrase only one consumer uses")

**Location:** `docs/decisions/log.md:94`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that both named consumers name both regexes and that row 71 no longer carries the quoted phrase; does not establish that rows 60 and 61(4) themselves were amended to mention host tools (they still define the set by `enforcement_files()` alone, and row 71 amends them by reference).

Both consumers name both regexes, in different words, and row 71 now paraphrases rather than quotes:

```
# skills/code-review/SKILL.md:745-749
7. **Security on enforcement files.** If the reviewed diff touches an enforcement file (a path
   matched by the `enforcement` or the `host_tools` regex in `hooks/live-verify-gate.sh`, ...
   still enforcement files here, decision log row 71),
```

```
# workflows/research-plan-implement.md:233
... a path matching the `enforcement` or `host_tools` pattern in `hooks/live-verify-gate.sh`; the host-only tools count, decision log row 71 ...
```

A repo grep at 25d8f272 for "enforcement` or `host_tools` pattern" hits only
`workflows/research-plan-implement.md` (1) and the review documents under `docs/reviews/`, not
`docs/decisions/log.md` (paraphrased — no quote available because the claim is about where a phrase is absent, from `git grep -c` results). Row 60's own text still reads "its regex mirrors `cc-isolated.sh`'s `enforcement_files()`" (`docs/decisions/log.md:83`).

**Evidence:** `docs/decisions/log.md:83`, `docs/decisions/log.md:94`, `skills/code-review/SKILL.md:745-749`, `workflows/research-plan-implement.md:233`

---

## Claim 2: "**Host-only tools are not enforcement files for this sequence** (decision log row 71); they still count as enforcement files for code-review's mechanic 7 and RPI's bypass-family pre-mortem"

**Location:** `guides/devcontainer-setup.md:272-274`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that "this sequence" resolves to the section it sits in and that the two named consumers include host tools; does not establish what other docs (outside these two consumers) mean when they say "enforcement file".

The sentence sits under the heading `### The sequence, every time an enforcement file changes`
(`guides/devcontainer-setup.md:265`), so "this sequence" is that section's rebuild/probe/bless
sequence, and the paragraph goes on: "so no probe can exercise them and the sequence below does
not apply" (`guides/devcontainer-setup.md:279-280`). The two consumers it names say "host tools
carry their own trailer but are still enforcement files here" (`skills/code-review/SKILL.md:748-749`)
and "the host-only tools count" (`workflows/research-plan-implement.md:233`).

**Evidence:** `guides/devcontainer-setup.md:265-285`, `skills/code-review/SKILL.md:745-749`, `workflows/research-plan-implement.md:233`

---

## Claim 3: "Not end-anchored, like `enforcement`: a stray sibling such as cc-push.sh.orig is gated too" and the commit's "api N4: a test pins the un-anchored host regex (cc-push.sh.orig)"

**Location:** `hooks/live-verify-gate.sh:89-91`; `test/hooks/live-verify-gate.bats:406-413`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that `cc-push.sh.orig` is gated as a host tool (Live-verified alone blocks, Host-tool-tested passes) and that restoring the `$` anchor turns that test red; does not establish siblings of `cc-exit-scan.sh` or `cc-gitdir.sh` (same alternation, not tested by name).

```
# hooks/live-verify-gate.sh:91
host_tools='^devcontainer-config/(cc-exit-scan\.sh|cc-gitdir\.sh|cc-push\.sh)'
```

```
# test/hooks/live-verify-gate.bats:409-412
  run bash "$HOOK" <<< "$(payload 'git commit -m "x" -m "Live-verified: no — n/a"')"
  [ "$status" -eq 2 ]
  run bash "$HOOK" <<< "$(payload 'git commit -m "x" -m "Host-tool-tested: no — n/a"')"
  [ "$status" -eq 0 ]
```

Mutation Mf-endanchor (`cc-push\.sh)$'`) leaves 30/31 green and fails only `not ok 31 a stray sibling of a host tool (cc-push.sh.orig) is gated as a host tool`, at line 410 (`[ "$status" -eq 2 ]' failed`). Command `timeout 300 bats test/hooks/live-verify-gate.bats`, cwd `<probe>/mut-Mf-endanchor`, exit 1, 2026-10-15T02:57Z.

**Evidence:** `hooks/live-verify-gate.sh:89-91`, `test/hooks/live-verify-gate.bats:406-413`, `docs/reviews/execution-logs/fc-q089b-it3/bats-Mf-endanchor.log`

---

## Claim 4a: "--no-textconv --no-ext-diff: a repo-local diff driver (.gitattributes plus diff.<x>.textconv) could otherwise render a real change as comment lines." (commit: "comment_only_diff passes --no-textconv --no-ext-diff, so a repo-local diff driver cannot render a real change as comment lines")

**Location:** `hooks/live-verify-gate.sh:109-113`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both flags on both `git diff` calls in `comment_only_diff` against a textconv driver and an external-diff driver set by repo-local config; does not establish other config that rewrites diff output (e.g. `diff.noprefix`, `color.diff=always` is already countered by `--no-color`) or the `--name-only` calls at :73/:77, which take no flags (names are unaffected by drivers).

```
# hooks/live-verify-gate.sh:111-113
  diff_text="$(git diff --cached -U0 --no-color --no-textconv --no-ext-diff -- "${touched_files[@]}" 2>/dev/null)" || return 1
  if [ "$commit_all" = "1" ]; then
    diff_text="$diff_text"$'\n'"$(git diff -U0 --no-color --no-textconv --no-ext-diff -- "${touched_files[@]}" 2>/dev/null)"
```

Executed (`fc-q089b-it3/direct-probes.log`, 2026-10-15T02:58:02Z): X1 sets `diff.cm.command`
to a script printing `@@ -1 +1 @@` / `+# looks like a comment` and stages a real `widened`
line; plain `git diff --cached -U0` prints only those two lines. The real hook exits 2; with
`--no-ext-diff` dropped (Md) or both flags dropped (Mb) it exits 0. X2 uses the textconv driver
`sed s/^/#/` with an unstaged change and `git commit -am`: the real hook exits 2, Me (flags
dropped from :113) exits 0. The old hook (79f22357) under the new suite fails exactly test 30,
the textconv test (`bats-old-hook-79f22357.log`), so this was a real gap the commit closes.

**Evidence:** `hooks/live-verify-gate.sh:109-113`, `docs/reviews/execution-logs/fc-q089b-it3/direct-probes.log`, `docs/reviews/execution-logs/fc-q089b-it3/bats-old-hook-79f22357.log`

---

## Claim 4b: "...; new test." (the test that pins 4a: "a repo-local textconv driver cannot make a real change read as comment-only")

**Location:** `test/hooks/live-verify-gate.bats:398-404`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which of the four flag occurrences the new test pins; does not establish that the unpinned three are wrong (Claim 4a shows each does real work).

```
# test/hooks/live-verify-gate.bats:398-404
@test "a repo-local textconv driver cannot make a real change read as comment-only" {
  echo 'devcontainer-config/egress/*.txt diff=cm' > .gitattributes
  git config diff.cm.textconv "sed s/^/#/"
  stage_enforcement
  run bash "$HOOK" <<< "$(payload 'git commit -m "x"')"
  [ "$status" -eq 2 ]
}
```

The test fails without `--no-textconv` on the `--cached` call (Mb and Mc each: `not ok 30`, exit 1).
It stays green with `--no-ext-diff` dropped from that call (Md, 31/31, exit 0) and with both
flags dropped from the `-a` call at :113 (Me, 31/31, exit 0). So the test pins one of the four
flag occurrences: `--no-textconv` on the index diff. The precise statement is "new test for the
textconv driver on the index diff"; an external driver (`diff.<x>.command`) and the `-a` path
are unpinned.

**Evidence:** `test/hooks/live-verify-gate.bats:398-404`, `docs/reviews/execution-logs/fc-q089b-it3/bats-Mb-cached-both.log`, `docs/reviews/execution-logs/fc-q089b-it3/bats-Mc-cached-textconv.log`, `docs/reviews/execution-logs/fc-q089b-it3/bats-Md-cached-extdiff.log`, `docs/reviews/execution-logs/fc-q089b-it3/bats-Me-all-both.log`

---

## Claim 5: "The gate blocks a `git commit` that carries a cc-isolated enforcement file ... with a `Live-verified:` trailer, and one that carries a host-only tool (cc-exit-scan.sh, cc-gitdir.sh, cc-push.sh; decision log row 71) unless it carries a `Host-tool-tested:` trailer." (commit: "api N3: the bats header describes both trailers")

**Location:** `test/hooks/live-verify-gate.bats:5-10`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the header's two-trailer description against the hook; does not establish the rest of the header (see Claim 6).

The three named tools match `host_tool_files()` (`devcontainer-config/cc-isolated.sh:199-203`:
`echo "cc-exit-scan.sh"`, `echo "cc-gitdir.sh"`, `echo "cc-push.sh"`) and the hook's
`need+=("Live-verified")` / `need+=("Host-tool-tested")` per set (`hooks/live-verify-gate.sh:155-156`).

**Evidence:** `test/hooks/live-verify-gate.bats:5-10`, `hooks/live-verify-gate.sh:155-156`, `devcontainer-config/cc-isolated.sh:199-203`

---

## Claim 6: "Eleven tests exercising the script say nothing about whether it is wired into the live settings.json" (also "Eleven behaviour tests above")

**Location:** `test/hooks/live-verify-gate.bats:20-22`, `test/hooks/live-verify-gate.bats:256`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count; does not establish anything about the wiring test's behaviour, which is unchanged. Pre-existing text, not changed by 25d8f272, but it sits in the header N3 edited.

```
# test/hooks/live-verify-gate.bats:20-21
#   2. Installed-ness. Eleven tests exercising the script say nothing about
#      whether it is wired into the live settings.json, which is how it can fall
```

`bats --count test/hooks/live-verify-gate.bats` at 25d8f272 prints 31 (`fc-q089b-it3/summary.txt`, `== count: 31`); 30 are behaviour tests and one is the wiring test, which runs as `ok 20` of 31, not last ("The last test reads", :22; eleven tests follow it, :280-413), per `fc-q089b-it3/bats-clean.log:26`. The text implies a twelve-test suite with the wiring test last (paraphrased — no quote available because this is an inference from the header's own wording; the suite's history was not bisected).

**Evidence:** `test/hooks/live-verify-gate.bats:20-22`, `test/hooks/live-verify-gate.bats:255-257`, `docs/reviews/execution-logs/fc-q089b-it3/summary.txt`

---

## Claim 7: "A boundary file, not a host tool (it is not in enforcement_files, so the per-file loop does not cover it): Host-tool-tested alone does not pass it." (commit: "security F1: install.sh is not in enforcement_files ...; its test now asserts Host-tool-tested alone blocks it and Live-verified passes it")

**Location:** `test/hooks/live-verify-gate.bats:152-157`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers install.sh's absence from `enforcement_files()`, both new assertions, and that moving install.sh into `host_tools` fails the new assertion; does not establish install.sh's comment-only behaviour (a new file in the test, so the structural check gates it whatever its text).

`enforcement_files()` echoes six fixed names and the egress/projects/claude-home globs; there is
no `install.sh` (`devcontainer-config/cc-isolated.sh:131-136`: `echo "devcontainer.json"` ...
`echo "cc-isolated.sh"`). The new assertions:

```
# test/hooks/live-verify-gate.bats:154-157
  run bash "$HOOK" <<< "$(payload 'git commit -m "x" -m "Host-tool-tested: no — n/a"')"
  [ "$status" -eq 2 ]
  run bash "$HOOK" <<< "$(payload 'git commit -m "x" -m "Live-verified: no — n/a"')"
  [ "$status" -eq 0 ]
```

Mutation Mg-install-host-full (`install\.sh$` removed from `enforcement`, added to `host_tools`) fails `not ok 9 install.sh is gated ...` at line 155, the new Host-tool-tested assertion (and test 26, the regex-names test, which also sees the extra name). Exit 1, cwd `<probe>/mut-Mg-install-host`.

**Evidence:** `devcontainer-config/cc-isolated.sh:128-150`, `test/hooks/live-verify-gate.bats:146-164`, `docs/reviews/execution-logs/fc-q089b-it3/bats-Mg-install-host-full.log`

---

## Claim 8: "a rename committed with -a (new name only intent-to-add) is still gated" (commit: "security F2: a test for `--no-renames` on the -a path (rename, new name intent-to-add, `commit -am`)")

**Location:** `test/hooks/live-verify-gate.bats:390-396`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the test exercises the `--no-renames` on the `-a` name list (:77) and fails without it; does not establish a `-a` rename whose new name is not intent-to-add (an untracked new name is not in any diff, so only the deletion shows either way).

```
# test/hooks/live-verify-gate.bats:391-395
  mv devcontainer-config/egress/base.txt devcontainer-config/base-moved.txt
  git add -N devcontainer-config/base-moved.txt
  run bash "$HOOK" <<< "$(payload 'git commit -am "x"')"
  [ "$status" -eq 2 ]
  [[ "$output" == *"devcontainer-config/egress/base.txt"* ]]
```

In probe X3 (`direct-probes.log`), `git diff --name-only` lists only `devcontainer-config/base-moved.txt`; with `--no-renames` it lists both paths; the index list is empty. Mutation Ma-all-renames (drop `--no-renames` at :77) fails only `not ok 29`, at line 394, exit 1.

**Evidence:** `hooks/live-verify-gate.sh:73-78`, `test/hooks/live-verify-gate.bats:390-396`, `docs/reviews/execution-logs/fc-q089b-it3/direct-probes.log`, `docs/reviews/execution-logs/fc-q089b-it3/bats-Ma-all-renames.log`

---

## Claim 9: "# shellcheck disable=SC2164  # recorded reviewer probe, kept as run; gate 6 only"

**Location:** `docs/reviews/execution-logs/sec-q089b-it2/probe-it2.sh:2`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the directive (with its trailing comment) is parsed and needed under gate 6's flags, and that every `.sh`/`.bats` file in the scoped diff passes gate 6; does not establish the full `health-check.sh` run (other files outside the scope). It is the only shellcheck directive in the scoped probe scripts.

Gate 6 runs `shellcheck -x -e SC1091 -s bash -S warning "$f"` (`scripts/health-check.sh:522`). Under those flags (`fc-q089b-it3/shellcheck-gate6.log`, cwd `<probe>/src`, 2026-10-15T02:58:03Z), all nine scoped files exit 0: the seven probe scripts, `hooks/live-verify-gate.sh` and `test/hooks/live-verify-gate.bats`. With the directive line removed, `probe-it2.sh` exits 1 with `SC2164 (warning)` at its line 48, `cd "$P"; rm -rf "$P"/repo-*`, so the directive is both needed and honoured with the trailing comment.

**Evidence:** `scripts/health-check.sh:518-528`, `docs/reviews/execution-logs/sec-q089b-it2/probe-it2.sh:2`, `docs/reviews/execution-logs/fc-q089b-it3/shellcheck-gate6.log`

---

## Claim 10: "live-verify-gate.bats 31/31 under LC_ALL=C"

**Location:** commit 25d8f272 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the suite at 25d8f272 under a redirected HOME (so the wiring test skips for want of a settings.json, as it would anywhere unwired); does not establish a run against the live `~/.claude/settings.json`.

`bats --count` prints 31; the clean run gives `total=31 notok=0 exit=0` (`fc-q089b-it3/bats-clean.log`, cwd `<probe>/src`, command `timeout 300 bats test/hooks/live-verify-gate.bats`, `LC_ALL=C`, 2026-10-15T02:57:02Z).

**Evidence:** `docs/reviews/execution-logs/fc-q089b-it3/bats-clean.log`, `docs/reviews/execution-logs/fc-q089b-it3/summary.txt`

---

## Claim 11: "the regex-swap mutation still fails 2 tests"

**Location:** commit 25d8f272 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers it2's M1-swap-full mutation (init-firewall.sh moved from `enforcement` to `host_tools`) re-run at 25d8f272; does not establish other swaps (Claim 7's install.sh swap also fails 2).

M1-swap-full: `total=31 notok=2 exit=1`, failing `not ok 8 every manifest-hashed file is in the enforcement set` and `not ok 26 the hook's host_tools regex names exactly host_tool_files, no more`, the same two as it2 (`fc-q089b-it2/bats-M1-swap-full.log`).

**Evidence:** `docs/reviews/execution-logs/fc-q089b-it3/bats-M1-swap-full.log`

---

## Claim 12: "fact-check it2 Incorrect (2b183802's Notes): the rename test is gated through `deleted file mode`, not `rename from`; recorded here, the code was right."

**Location:** commit 25d8f272 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the diff `comment_only_diff` reads for the `git mv` rename test; does not establish that `deleted file mode` is the only thing gating it (the removed `-base` line is non-comment and would gate it too).

`comment_only_diff` is given only the boundary set, `devcontainer-config/egress/base.txt`, and its pathspec-limited diff after `git mv` is a deletion (`fc-q089b-it3/rename-header-probe.log`, exit 0, 2026-10-15T02:58:32Z): `deleted file mode 100644` ... `@@ -1 +0,0 @@` / `-base`, with no `rename from` line. The structural grep matches it first:

```
# hooks/live-verify-gate.sh:119
  grep -Eq '^(new file mode|deleted file mode|old mode|new mode|rename from|similarity index|Binary files)' <<< "$diff_text" && return 1
```

**Evidence:** `hooks/live-verify-gate.sh:116-119`, `docs/reviews/execution-logs/fc-q089b-it3/rename-header-probe.log`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
- **Claim 6** (`test/hooks/live-verify-gate.bats:20-22`, `:256`): "Eleven tests" and "The last test" are out of date: the suite has 31 tests, 30 behavioural, and the wiring test is 20th of 31. Drop the count or say "the behaviour tests".

### Mostly Accurate
- **Claim 4b** (`test/hooks/live-verify-gate.bats:398-404`): the new test pins `--no-textconv` on the index diff only. Removing `--no-ext-diff`, or both flags from the `-a` diff at :113, leaves 31/31 green, although probes X1/X2 show each does real work.

### Unverifiable
(none)

No Incorrect verdicts, so no hallucination-pattern entry.

---

## Goal-Alignment Note

B's goal: host-tool commits carry `Host-tool-tested:` instead of an unpayable `Live-verified: no`,
and no gate coverage is lost in the move. The iteration-2 fixes serve that goal, and the claims
in 25d8f272's message hold. The install.sh trailer is now pinned both ways. The `-a` rename and
the un-anchored host regex each have a test that fails when the fix is reverted. The textconv
hole that predates the unit is closed. The guide and row 71 now scope "enforcement file" the
same way the two consumers do. Both counts reproduce (31/31; the swap fails 2). Two small gaps
remain, neither of them a mismatch between a claim and the code. The flag fix has
more coverage in code than in tests (Claim 4b: `--no-ext-diff` and the `-a` call are unpinned),
and the bats header still carries a stale test count (Claim 6). Neither blocks the Q-148 [1]
merge-if-clean condition on correctness grounds. Whether "clean" admits one Mostly accurate and
one Stale is the loop's call.
