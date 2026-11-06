# Security Review — test/q089-source-guard-narrow

Commit: 2174b7af
**Scope:** `git diff db31db8b..HEAD` (`test/cc-host-tool-sources.bats`, the research doc, the fact-check report), plus `devcontainer-config/cc-verify.sh` `source_lines_ok` and the entry-point lines the test reads
**Date:** 2026-11-05
**Based on:** `docs/reviews/code-fact-check-report-q089-source-guard.md` (pass 1) and the threat-model lines in the brief; `docs/constraints.md` read from `main`, unchanged by this diff

**Result (pass 2, at 2174b7af):** no findings; Findings 1 to 3 are closed. See "Pass 2" at the end.

**Result (pass 1, at cb59c2bb; line numbers in the pass 1 sections are from that commit):** one Medium finding, fixable in the test with no host-tool edit, and two Informational wording gaps. No runtime code changes, no HALT pattern.

## Trust Boundary Map

```
B1 (new): [branch devcontainer-config/cc-*.sh]    → [cp to $T/cfg; read as text by grep and source_lines_ok] → [check_entry verdict]
B2 (new): [branch cc-verify.sh]                   → [sed extraction, then `source` in the bats shell]         → [test process code]
B3 (new): [branch cc-isolated.sh copy]            → [`bash -c` source, stopped by the main-execution guard]   → [host_tool_files list]
B4 (new): [check_entry verdict]                   → [bats run in the health check]                            → [merge decision]
```

```
S1: devcontainer-config/cc-*.sh text — deploy-time (written by same-uid loops on a branch)
    — UNTRUSTED as a claim of what is checked (it is what the guard judges);
      trusted for exec at the level of every other test that sources the launcher (H1 interim Q-149 [2])
S2: source_lines_ok body in cc-verify.sh — deploy-time — same as S1; a host tool, so a change needs `Host-tool-tested:` and a re-bless
S3: mktemp path $T — request-time, local — trusted for path sinks (created in setup, quoted at every use)
S4: seed text in the test file — code-constant — trusted (all sinks)
```

Everything entering is repo text on the branch, and the only consequence is a pass or fail. The diff adds no path from outside text to a sink. H1: reading the grammar from `cc-verify.sh` gives a change no power it lacks, since the same change can edit `test/` itself, which the interim exception already names. So this is not a new H1 breach.

## Findings

#### 1. A plain `source` on a last line with no newline passes the guard unseen

**Severity:** Medium
**Location:** `test/cc-host-tool-sources.bats:45-46`, through `devcontainer-config/cc-verify.sh:54,62`
**Boundary:** B1
**Move:** 11 (bypasses), 2 (assumed coverage)
**Confidence:** High on the mechanism (executed). Likelihood is low: the line has to be the last in its file and the file has to lack a final newline.
**Legibility-target:** for-author

**Evidence:**

- Loop in `source_lines_ok`: `while IFS= read -r line; do` … `done < "$f"`. `read` returns non-zero on an unterminated last line, so the body never sees it.
- Direct run, under bash, on a two-line file whose last line is the plain `source` form:

```
no-newline: rc=0 SOURCED=[]
RAN-HELPER
with-newline: rc=0 SOURCED=[cc-helper.sh]
```

- Full test, seeded scratch tree (`bats -f 'plain source lines'`):

```
P1-nonl-unlisted-gitdir   rc=0
P1ctl-with-newline        rc=1  # cc-isolated.sh sources cc-helper.sh unchecked
P1b-nonl-push-entry       rc=0
```

The helper is sourced by bash and missed by the guard. This is the one miss I found that is a plain spelling, which is the only thing the header claims to guard ("A grep guards plain spellings only"). It is an honest slip, not an evasion: a `printf` append, or a file written without a final newline, produces it. It is in neither the header's list, the research doc's reach list, nor the fact-check report. All five `cc-*.sh` files end in a newline today, so nothing is exposed now. The result is finding A6's case again, with a green test: a new helper runs with no hash check. The floor rule sets Medium, since a slip reaches it. The diff makes nothing worse at runtime.

**Recommendation:** Fix it in the test, which needs no host-tool edit: after the `cp` in `setup()`, append a newline to each copy (`for f in "$T"/cfg/cc-*.sh; do echo >> "$f"; done`), and add a seeded case using `printf` with no newline (H2 asks for one per failure path). The shipped `source_lines_ok` has the same gap, so a `|| [ -n "$line" ]` on the loop is a separate follow-up that needs `Host-tool-tested:` and a re-bless.

#### 2. The header's limits do not say a listed helper may still be sourced outside the check's `if`

**Severity:** Informational
**Location:** `test/cc-host-tool-sources.bats:11-14`
**Boundary:** B1, B4
**Move:** 5 (what does this not cover)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:** header: `the lists `--list` passes, or whether the check comes before the source.` Seed: helper in the list and in `host_tool_files`, source placed after the `fi`:

```
else
  HOST_TOOLS_ERR="${HOST_TOOLS_ERR:-host-tool check failed}"
fi
source "$CC_ISOLATED_DIR/cc-helper.sh"
```

Result: `P2-source-after-fi rc=0`. The check comes first here, so the header's stated limit does not describe this case, yet a failed check would not stop the source. This is the same family as the order gap the fact-check raised (`o-after`), and it is inside the guard's stated contract of list membership. No property the test claims is broken, and no such line exists today, so the floor rule does not apply.

**Recommendation:** Widen the header's phrase to "whether the check comes before the source or gates it". No code change.

#### 3. Text quoting the call ahead of the real check replaces the real list, not only a missing call

**Severity:** Informational
**Location:** `test/cc-host-tool-sources.bats:41-42`
**Boundary:** B1
**Move:** 11
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `| grep -oE 'verify_host_tools "\$CC_(ISOLATED|PUSH)_DIR"( [a-z-]+\.sh)+' | head -1 | cut -d' ' -f3-)" || true`. Seed: `: # verify_host_tools "$CC_ISOLATED_DIR" cc-exit-scan.sh cc-gitdir.sh cc-helper.sh` placed above the real, narrower call, with the helper sourced: `P3b-eol-comment-wider rc=0`.

This extends the fact-check's Claim 18: because of `head -1`, the stand-in also wins when the real call is present. The code comment says "first verify_host_tools call", so it behaves as stated. The limit is recorded in the research doc but not in the file header. The needed text is unusual, and nothing like it precedes `cc-isolated.sh:748` today.

**Recommendation:** Add "an end-of-line comment or string quoting the call can stand in for it" to the header's limits, beside Finding 2's wording.

## Bypass candidates (move 11)

All run in scratch copies of the tree against case 1, except where marked. rc=0 means the guard passed the seed.

| Seed | rc | Disposition |
|---|---|---|
| No final newline (P1, P1b) | 0 | Finding 1 |
| Listed, sourced after `fi` (P2) | 0 | Finding 2 |
| Wider stand-in before the real call (P3b) | 0 | Finding 3 |
| `$CC_ISOLATED_DIR` pasted into `cc-push.sh`, unlisted (P4a) | 1 | named |
| Same, listed (P4b) | 0 | cleared by reading: `cc-push.sh` never assigns it, `set -euo pipefail` at `:121` aborts loudly, and nothing in the two entry points exports it |
| Helper name with a digit (P5a), multi-line list (P5b), array list (P5c) | 1 | refused: a false alarm at worst, never a silent pass |
| Helper outside `cc-*.sh`, so not copied (P6) | 1 | "is missing" |
| Grammar refactored to call a helper the `sed` does not extract (P7) | 1 | the positive control fires |
| `source \` continuation (P8) | 1 | refused as not plain |
| `coproc source f` (P9a) | 0 | not a plain spelling; the header's list is open-ended ("include"), no action |
| `FOO=1 source f` (P9b) | 0 | listed in the header |
| `grep -qx -- "$f"` treats `.` as a wildcard (`:52`) | n/a | cleared by reading: the `[a-z-]+\.sh` list check at `:51` runs first, so only the `.sh` dot reaches it |

**Untested bypass candidates:** none from the list above. Deliberate obfuscation (`so""urce`, `$c f`) was not pursued: it needs a hostile author, out of scope under S1, and the header already disclaims it.

P3a, an escaped-quote string, was refused only because my seed tripped `set -u` while the launcher was sourced; it says nothing about strings. The fact-check's `c-strplain` covers an unescaped string.

## Endorsement Claims

- **Claim:** At cb59c2bb the seven cases pass and running them changed nothing tracked in the worktree.
  **Location:** `test/cc-host-tool-sources.bats`
  **Evidence:** executed
  **Verified:** `bats test/cc-host-tool-sources.bats`, 7 ok; `git status --short` afterwards showed only another critic's untracked review file.
  **Not verified:** the full suite, and the file's behaviour when bats runs it inside the health check.

- **Claim:** The list shapes P5a-c, P6, P7 and P8 end in a named failure, not an empty pass.
  **Location:** `test/cc-host-tool-sources.bats:41-53`
  **Evidence:** executed
  **Verified:** those six seeds, against the real files, each gave rc=1 with the message shown in the table.
  **Not verified:** list spellings beyond those six, such as a list built by a function.
  **route: code-fact-check**

- **Claim:** The hermeticity lint reports no unstubbed network spawn for this file.
  **Location:** `test/cc-host-tool-sources.bats:49`
  **Evidence:** executed
  **Verified:** `scripts/hermeticity-lint --root .`, 140 files, no findings. The launcher's copy has no `install.sh` beside it, so its host-tool check takes the no-manifest branch, and the main-execution guard stops `main`.
  **Not verified:** `scripts/confine-tests.sh`, the ground truth, which exited 3 here because the session cannot confine itself. A host run is needed for that.

- **Claim:** The launcher path reaches the subprocess as an argument and the shell body is static.
  **Location:** `test/cc-host-tool-sources.bats:49`
  **Evidence:** read-static
  **Verified:** `bash -c 'source "$1"; host_tool_files' _ "$dir/cc-isolated.sh"`, which follows the repo's argv rule.
  **Not verified:** the value of `$T`, which comes from `mktemp` under the caller's `TMPDIR`.

## Primitive sweep

Primitive: code load / process exec

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `test/cc-host-tool-sources.bats:26` `source "$T/source-lines-ok.sh"` | S2 | non-empty check at `:24` | cleared: same trust as any test sourcing branch code (H1 interim) |
| `test/cc-host-tool-sources.bats:49` `bash -c 'source "$1"; …'` | S1, S3 | main-execution guard; static body | cleared: a failed source leaves `hosts` empty, which fails with "is not a host tool" |

Primitive: in-place write / delete

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `sed -i` at `:44`, `:71`, `:80`, `:103`, `:108` | S3 | every call site passes `$T/cfg` | cleared: scratch copies only |
| `rm -rf "$T"` at `:32` | S3 | quoted | cleared: an empty `$T` is a no-op, and a `mktemp` failure stops `setup()` first |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Plain `source` on an unterminated last line is unseen | Medium | B1 | `test/cc-host-tool-sources.bats:45-46`, `devcontainer-config/cc-verify.sh:54,62` | High (likelihood low) |
| 2 | Header omits "gates the source" | Informational | B1, B4 | `test/cc-host-tool-sources.bats:11-14` | High |
| 3 | Stand-in text replaces the real list | Informational | B1 | `test/cc-host-tool-sources.bats:41-42` | High |

## Overall Assessment

This is a test-only change with no new path from outside text to a sink, and its failure handling held up: every malformed list shape I tried fails loudly. The one thing to address is Finding 1, because it is a plain spelling the guard claims to cover and misses, and the fix is about two lines in the test plus a seeded case. Findings 2 and 3 are one header sentence. None is architectural. Within the code paths read, nothing here blocks landing on security grounds beyond that fix, and the endorsement claims are executed or scoped, with `confine-tests.sh` still needing a host run.

## Pass 1 Goal-Alignment Note
- Success criterion (restated verbatim): a critique at docs/reviews/security-review-2026-11-05-q089-source-guard.md with a `Commit:` line, ending in a Goal-Alignment Note. Findings carry Severity, Location, verbatim Evidence, Confidence, Legibility-target. Do not commit or edit anything else.
- Answered: yes; 16 seeds run, every finding executed
- Out of scope: hostile obfuscation (S1); the shipped `source_lines_ok` beyond noting that it shares Finding 1's gap
- Escalate: follow-up for `cc-verify.sh`'s read loop (host-tool change, needs `Host-tool-tested:` and a re-bless); `scripts/confine-tests.sh` needs a host run
- Decisions I made: rated Finding 1 Medium under the floor rule rather than Low, since a slip reaches it though nothing is exposed today; rated Findings 2 and 3 Informational because each is inside the test's stated contract, though each also names a mechanism

## Pass 2: final confirming pass at 2174b7af

**Scope:** `git diff db31db8b..2174b7af -- test/cc-host-tool-sources.bats docs/working/research-2026-11-05-q089-source-guard-narrow.md`, plus `source_lines_ok` in `devcontainer-config/cc-verify.sh`
**Based on:** the final fact-check (k=3 at cb428e81, 0 Incorrect, as stated in the brief; I did not re-read its reports) and the threat-model lines in the brief

### Trust Boundary Map

B1 to B4 and S1 to S4 stand. The fixes add no boundary and no source: `check_entry` now writes to each copy in its `dir` argument, which is S3 as a path and S4 as content. No file under `devcontainer-config/` changed.

### Findings

No findings.

Status of pass 1:

| # | Status | Evidence |
|---|---|---|
| 1 | Closed | `:48-51` adds a newline to every copy before the grammar reads it. Seeds n1 to n4 below are all named, and both stages of case 3 fail if the fix is removed or narrowed |
| 2 | Closed | Header `:12-13`: `before the source or gates it` |
| 3 | Closed | Header `:13-14`: `An end-of-line comment or string quoting a check call above the real one is read as the list.` |

The shipped `source_lines_ok` gap stays a Defer row in `docs/reviews/override-log.md`, as settled.

### Do the fixes work, and did they add anything? (moves 3, 11)

All runs are on scratch copies from `git archive 2174b7af`.

Mutations of the test, to show the fixes are pinned:

| Mutation | Result |
|---|---|
| None (baseline) | 9 ok |
| Newline line removed | case 3 fails |
| Newline added to the entry point only, so a reached file stays unterminated | case 3 fails: 2174b7af's second stage does pin the reached file |
| Rename applied to the entry point only | cases 3 and 4 fail |

Seeds against case 1 (rc=1 is a named failure):

| Seed | rc | Message |
|---|---|---|
| n1: unterminated source of `cc-exit-scan.sh` in reached `cc-gitdir.sh` | 1 | `cc-push.sh sources cc-exit-scan.sh unchecked` |
| n2: unterminated source of a helper in reached `cc-exit-scan.sh` | 1 | `cc-isolated.sh sources cc-helper.sh unchecked` |
| n3: same, in `cc-isolated.sh` itself | 1 | `cc-isolated.sh sources cc-helper.sh unchecked` |
| n4: same, in `cc-push.sh` itself | 1 | `cc-push.sh sources cc-helper.sh unchecked` |
| n5: unterminated dot source | 1 | `not a plain source line` |
| n6: unterminated `source \` | 1 | `not a plain source line` |
| n7: helper that is one unterminated comment, sourced by `cc-gitdir.sh` | 1 | `cc-isolated.sh sources cc-helper.sh unchecked` |
| n8: unterminated line ending in CR | 1 | `cc-push.sh sources cc-exit-scan.sh unchecked` |
| n9: `$MY_CC_PUSH_DIR`, a name containing the renamed one | 1 | `not a plain source line` |
| n10: test edited to run `check_entry` on one directory three times, push first | 0 | passes, as it should: repeating the rename and newline changes no verdict |

Read, not seeded:

- `args` is read before the copies are changed, so the regex's `CC_PUSH_DIR` branch still matches. An unterminated check call is matched by `grep` either way.
- `source_lines_ok` comes from `$SRC/cc-verify.sh` in `setup()`, so the rename, which touches only `$T/cfg`, does not alter the grammar under test.
- No `cc-*.sh` other than `cc-push.sh` names `CC_PUSH_DIR` today, and all five end in a newline, so the rename and newline change nothing else in the verdict at this commit.
- The research doc's changed lines (the two adjustments, the final-newline bullet, nine cases) match the file. It adds no claim about security beyond the header's.

**Untested bypass candidates:** none for the fix. Deliberate obfuscation stays out of scope under S1, as in pass 1.

### Endorsement Claims

- **Claim:** At 2174b7af the nine cases pass and running them left the worktree unchanged.
  **Location:** `test/cc-host-tool-sources.bats`
  **Evidence:** executed
  **Verified:** `bats test/cc-host-tool-sources.bats`, 9 ok; `git status --short` afterwards printed nothing; `scripts/hermeticity-lint --root .` exited 0.
  **Not verified:** the full suite, and `scripts/confine-tests.sh`, which pass 1 could not run in this session and which I did not retry. The fixes add no process that can reach a network: `sed` and `echo` only.

- **Claim:** An unterminated last line holding a plain `source`, in an entry point or a file it reaches, gives a named failure at this commit.
  **Location:** `test/cc-host-tool-sources.bats:48-51`
  **Evidence:** executed
  **Verified:** seeds n1 to n4, and the three mutations that make case 3 fail.
  **Not verified:** a reached file outside `cc-*.sh`, which is not copied; pass 1's P6 showed that gives "is missing".
  **route: code-fact-check**

### Primitive sweep

Primitive: in-place write / delete (changed since pass 1)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `sed -i` and `echo >>` at `:49-50` (new) | S3 | `$dir` is `$T/cfg` at every `check_entry` call | cleared: a grep of the file shows no call with another path |
| `sed -i` at `:101`, `:110`, `:133`, `:138` | S3 | `$T/cfg` | cleared: scratch copies |
| `rm -rf "$T"` at `:33` | S3 | quoted | cleared as in pass 1 |

Primitive: code load / process exec: no new call site. `source` is now at `:27` and `bash -c` at `:56`, dispositions as in pass 1.

### Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| n/a | No findings in pass 2 | n/a | n/a | n/a | n/a |

### Overall Assessment

The fixes work and added nothing new. Finding 1 is closed by executed seeds, both stages of the new case are pinned by mutation, and Findings 2 and 3 are in the header. Within the code paths read and run, this is safe to merge on security grounds: each endorsement claim is executed, with its `Not verified` hop named. `scripts/confine-tests.sh` still needs a host run, as pass 1 said; it is not a blocker from this review because the fixes add no network-capable process.

## Goal-Alignment Note
- Success criterion (restated verbatim): update docs/reviews/security-review-2026-11-05-q089-source-guard.md in place with `Commit: 2174b7af`, a section for this pass, ending in a Goal-Alignment Note. Findings carry Severity, Location, verbatim Evidence, Confidence, Legibility-target. Commit nothing, edit nothing else.
- Answered: yes; no findings, so no finding fields apply. Three mutations and ten seeds run, all as expected
- Out of scope: hostile obfuscation (S1); the shipped `source_lines_ok` gap, the `cc-verify.sh` comment and the forms the header lists as missed, all settled
- Escalate: `scripts/confine-tests.sh` still needs a host run; nothing else
- Decisions I made: kept pass 1's text and marked it as pass 1, renaming its note, so this file still ends in one Goal-Alignment Note; did not re-read the fact-check reports, and took their result from the brief
