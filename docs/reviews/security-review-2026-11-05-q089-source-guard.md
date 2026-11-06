# Security Review — test/q089-source-guard-narrow

Commit: cb59c2bb3e240f17d653bedf332b460950e86569
**Scope:** `git diff db31db8b..HEAD` (`test/cc-host-tool-sources.bats`, the research doc, the fact-check report), plus `devcontainer-config/cc-verify.sh` `source_lines_ok` and the entry-point lines the test reads
**Date:** 2026-11-05
**Based on:** `docs/reviews/code-fact-check-report-q089-source-guard.md` (pass 1) and the threat-model lines in the brief; `docs/constraints.md` read from `main`, unchanged by this diff

**Result:** one Medium finding, fixable in the test with no host-tool edit, and two Informational wording gaps. No runtime code changes, no HALT pattern.

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

## Goal-Alignment Note
- Success criterion (restated verbatim): a critique at docs/reviews/security-review-2026-11-05-q089-source-guard.md with a `Commit:` line, ending in a Goal-Alignment Note. Findings carry Severity, Location, verbatim Evidence, Confidence, Legibility-target. Do not commit or edit anything else.
- Answered: yes; 16 seeds run, every finding executed
- Out of scope: hostile obfuscation (S1); the shipped `source_lines_ok` beyond noting that it shares Finding 1's gap
- Escalate: follow-up for `cc-verify.sh`'s read loop (host-tool change, needs `Host-tool-tested:` and a re-bless); `scripts/confine-tests.sh` needs a host run
- Decisions I made: rated Finding 1 Medium under the floor rule rather than Low, since a slip reaches it though nothing is exposed today; rated Findings 2 and 3 Informational because each is inside the test's stated contract, though each also names a mechanism
