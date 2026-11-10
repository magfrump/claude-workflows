Commit: de1f4bf9

# API Consistency Review — fix/confine-tests-dash-and-fallback

**Scope:** `git diff 23ffb16c..de1f4bf9`: the command-line contract of `scripts/confine-tests.sh` (exit statuses, stdout/stderr text and order, argv handed to the test command, `--help`) and how `guides/test-hermeticity.md` and `test/scripts/confine-tests.bats` describe it
**Date:** 2026-11-10
**Based on:** `docs/reviews/code-fact-check-report-2026-11-10-confine-tests-dash-and-fallback.md` (stage 1, 53 claims) and runs of the old script (`git show 23ffb16c:scripts/confine-tests.sh`) and the new one, driven side by side with permissive stand-ins in the scratch directory `review-i1-api/` (`probe.sh`, output `probe.out`)

## Baseline Conventions

Established by the script at 23ffb16c and kept by the diff:

- **Message prefix.** Every message the script writes starts `confine-tests: ` (`:73`, `:102`, `:170`, `:185`, `:191`, `:197`, `:219`, and the body's own `:270`). Warnings add `WARNING — ` (`--no-loopback`'s, the only one at base). No message carries a line number.
- **Streams.** The `--probe` verdict goes to stdout; everything else (banner, warnings, refusals, usage errors) goes to stderr.
- **Exit statuses.** 0 / the child's status on a run; 2 usage errors and a `--no-loopback` that cannot be served; 3 no primitive, no `ip`, `lo` cannot be raised. On a run the script `exec`s, so a name that cannot be run gets the executing layer's status (127 not found, 126 not executable).
- **Vocabulary.** "primitive" (bwrap / unshare) everywhere in the consumer surface; "tier" appears only in research docs and the pre-mortem. The script's own refusal is "refuse/refusing/refused" (`:102`, `:46`, `:181`, test names "is refused (exit 3)"); a primitive that does not work is "unusable"/"not usable" (`:108`, `:172`, `:46`), and `explain_unavailable` names the no-primitive case. The test file at base already said "bwrap ... installed and refused" for a failed bwrap probe (base test name "--probe reports unshare when bwrap is not installed, or is installed and refused").
- **Callers.** No code in the repo parses the script's output: `rg -n "denying network via|primitive available|confine-tests\.sh"` outside `docs/working`, `docs/reviews`, `archive`, the script and its test finds only prose mentions (`scripts/hermeticity-lint:29,935,1019`, `guides/test-hermeticity.md`, `test/fixture-hermeticity.bats:15`, `docs/roadmap.md`, decisions 017/018, `CLAUDE.md`). The consumers are humans and briefs that read `--probe`'s exit status (`docs/roadmap.md:49`).

### What the runs show (old vs new, stand-ins; real primitives not exercised here)

Three run forms, same command, PATH stand-ins for bwrap/unshare that `exec -- "$@"`, `sh` linked to dash or bash for the old script:

| Command | bwrap | unshare+lo, old, sh=dash | unshare+lo, old, sh=bash | unshare+lo, new (either sh) | unshare --no-loopback |
|---|---|---|---|---|---|
| `-record -x` | runs, 0 | runs, 0 | `exec: -r: invalid option`, 2 | runs, 0 | runs, 0 |
| `-a x -record one` | not found, 127 | not found, 127 | invalid option, 2 | `confine-tests: line 6: exec: -a: not found`, 127 | not found, 127 |
| `nofile` | 127 | 127 | 127 | 127 | 127 |
| a directory | 126 | 126 (`Permission denied`) | 126 | 126 (two lines: `Is a directory`, `cannot execute`) | 126 |
| `""` (empty name) | 127 | **126** (`exec: : Permission denied`) | 127 | 127 | 127 |
| `cd /` (builtin, no file) | 127 | 127 | 127 | 127 | 127 |
| `eval echo hi` (no file) | 127 | 127 | 127 | 127 | 127 |

With the new script the three forms agree on status for every input tried, and argv[0] reaches the child as given on all three. The bwrap and `--no-loopback` columns are the stand-ins' own bash `exec`, not the real tools [unverified — submitted as claim: that real util-linux `unshare` returns 127/126 here, and real bwrap returns 1 on an exec failure; see finding 8].

Probes and refusals (new vs old): `--probe` stdout and status are identical for every route; stderr differs only in `--no-loopback --probe` over a working bwrap (finding 2). A fallback with no command prints the usage error alone, as before; `--no-loopback` with a working bwrap and no command prints its warning then the usage error, as before.

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `warn_unshare_only` | internal function | `explain_unavailable`, `detect_primitive` | `scripts/confine-tests.sh:86,100` | Consistent — verb_object snake_case, prints a multi-line message from a quoted heredoc like `explain_unavailable` |
| `fell_back` | internal variable | `probe_only`, `loopback`, `primitive` | `scripts/confine-tests.sh:56-58` | Consistent — lowercase, 0/1 integer flag like `probe_only` |
| `confine-tests: WARNING — bwrap is not installed; falling back to the unshare primitive.` | stderr message (headline) | `confine-tests: WARNING — --no-loopback forces the unshare primitive.` | `scripts/confine-tests.sh:166` (base `:137`) | Consistent — same prefix, em dash, "the unshare primitive", sentence ends with a period |
| `confine-tests: WARNING — bwrap was refused here; falling back to the unshare primitive.` | stderr message (headline) | `It needs \`unshare -rn\`, which is unusable here.`; `Neither primitive is usable in this environment` | `scripts/confine-tests.sh:108,172` | Minor — "refused" is the script's word for its own refusals; see finding 3 |
| `$0` of the body: `confine-tests` (was `sh`) | argv[0] of the inner shell | the script's message prefix `confine-tests:` | `scripts/confine-tests.sh:73,185,197` | Mixed — matches the prefix, but bash appends `line N:`; see finding 4 |
| test constants `NO_BWRAP_WARNING`, `BWRAP_REFUSED_WARNING`, `UNSHARE_BANNER` | test fixtures | `LO_WARNING`, `NO_IP`, `NO_LO_OVER_BWRAP`, `NO_PRIMITIVE` | `test/scripts/confine-tests.bats:25-28` | Consistent — SCREAMING_SNAKE message constants |

No flag is added, removed or renamed.

## Findings

#### 1. The header says `--no-loopback` warns on a `--probe`; it does not where bwrap is unavailable

**Severity:** Minor
**Location:** `scripts/confine-tests.sh:44-46`
**Move:** 3 (documentation drift)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**
```
#   `unshare` primitive (above). You are trading filesystem confinement for
#   loopback denial. The script says so, in the fallback warning's words, on
#   a run and on a --probe, and refuses outright when unshare is unusable.
```

This is `--help` text. Run: with bwrap not installed, `--no-loopback --probe` prints `confine-tests: primitive available: unshare (loopback=0)` on stdout and nothing on stderr (old and new alike), and a `--no-loopback` run prints the fallback's headline (`bwrap is not installed; ...`), not the flag's. The same header says the opposite eleven lines up (`:34-35`: "A --probe that falls back prints its verdict ... and not this warning"), so a reader of `--help` gets two answers for `--no-loopback --probe` on a host without bwrap. The fact-check rated it "Mostly accurate".

**Recommendation:** Say where it holds: "on a run, and on a --probe where bwrap works; where bwrap is unavailable a run prints the fallback's warning and a probe prints none."

#### 2. `--probe`'s stderr changed for `--no-loopback` over a working bwrap; the docs say `--probe` is unchanged for every input

**Severity:** Minor
**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:47` (also `:197`); the behaviour at `scripts/confine-tests.sh:166-168`
**Move:** 3 (subtle contract change), 6
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

**Evidence:**
```
- Which primitive is chosen, every exit status other than D1's, and `--probe` (stdout, stderr and status, for every input) do not change (brief). The tests pin this: the selection tests are untouched, and the fallback probe's stderr is now pinned empty.
```
```
    warn_unshare_only "--no-loopback forces the unshare primitive." \
      "Drop the flag to get the hardened profile (loopback is not egress — the" \
      "namespace has no route off the host)."
```

Run (`--no-loopback --probe`, bwrap working): stderr lines 5-7 were `...real filesystem. Drop the flag to` / `get the hardened profile (loopback is not egress — the namespace has` / `no route off the host).` and are now `...real filesystem.` / `Drop the flag to get the hardened profile (loopback is not egress — the` / `namespace has no route off the host).` Same seven lines, same words, line 1 byte-identical; stdout and status unchanged. Who could depend on it: a caller that diffs or line-greps the full warning (e.g. `grep 'Drop the flag to$'`, or a golden file of stderr). None exists in the repo (see Baseline, Callers), the text is prose for a human, and the only key a reader is likely to use, line 1, is unchanged. The doc contradicts itself: `:208` already says "its words are unchanged, its line breaks are not."

**Recommendation:** Correct the claim, do not restore the old breaks. Restoring them would mean splitting a shared heredoc sentence across the function boundary, defeating the one-source design (`warn_unshare_only`). Reword `:47` and `:197` to "stdout and status unchanged for every input; stderr unchanged except the re-wrapped `--no-loopback` warning (see Other choices)", and say the same in the results section, since commit 6465a156's message cannot be amended.

#### 3. "bwrap was refused here" uses the script's word for its own refusals

**Severity:** Minor
**Location:** `scripts/confine-tests.sh:210`
**Move:** 2 (naming against the grain)
**Confidence:** Medium
**Legibility-target:** for-author

Precedent: a primitive whose probe fails is "unusable"/"not usable" in `scripts/confine-tests.sh:108,172` and `:46`; "refuse/refusing" is the script's own exit-2/3 refusal in `scripts/confine-tests.sh:102,181` and `:46`.

**Evidence:**
```
    warn_unshare_only "bwrap was refused here; falling back to the unshare primitive." \
```
```
    echo "  It needs \`unshare -rn\`, which is unusable here. Re-run without" >&2
```

In one stderr stream a reader can now see "refusing to run" (the script refused) and "bwrap was refused here" (the kernel or bwrap refused the probe, and the run goes ahead). The test file already used "installed and refused" for this case at base, and the header (`:32`) and guide (`guides/test-hermeticity.md:60`) now repeat "is refused", so the word has a foothold. Still, the script's user-facing text had one meaning for it until this diff, and the sibling phrase is one line of the same file away. The detection also cannot tell a policy refusal from a broken bwrap (it is any non-zero exit of `bwrap --ro-bind / / --unshare-net -- true`), and "unusable" is accurate for both.

**Recommendation:** `bwrap is installed but unusable here; falling back to the unshare primitive.`, and "not installed or unusable" in the header `:32` and guide `:60`. The test constant `BWRAP_REFUSED_WARNING` changes with it. If the author prefers "refused", leave it; it is a one-word style point.

#### 4. The body's errors now read `confine-tests: line 6: ...`, which looks like a location in the script file

**Severity:** Minor
**Location:** `scripts/confine-tests.sh:268-273`
**Move:** 4 (error consistency)
**Confidence:** High
**Legibility-target:** for-author

Precedent: script messages are `confine-tests: <sentence>` with no line number, in `scripts/confine-tests.sh:73,185,197,270`.

**Evidence:**
```
  exec unshare -rn -- "$BASH" -c '
    if ! ip link set lo up; then
      echo "confine-tests: failed to bring loopback up inside the namespace." >&2
      exit 3
    fi
    exec -- "$@"' confine-tests "${cmd[@]}"
```

Run: `-- -a x -record one` and `-- nofile` print `confine-tests: line 6: exec: -a: not found` / `... nofile: not found`; a directory prints two such lines. "line 6" counts from the body's opening quote (its line 1 is empty), so it names line 273 of the script; `scripts/confine-tests.sh:6` is a header comment ("# it also denies a subprocess `curl`..."). Before, the prefix `sh: 6:` / `sh: line 6:` at least marked the message as a shell's. The research doc (`:209` in its "Other choices") presents the change as "like the script's other messages", which holds for the prefix and not for the `line N:` part. The status (127/126) is right and matches the other forms; only the text could send a reader to the wrong line. The test pins it loosely (`"confine-tests: "*"exec: -a: not found"`), so either fix keeps it green.

**Recommendation:** Cheapest: keep it and correct the research doc's sentence ("bash's own format, with a body-relative line number"). If the author wants it unambiguous, set the body's `$0` to a name that cannot be read as the file, e.g. `confine-tests[unshare]` → `confine-tests[unshare]: line 6: exec: -a: not found`, and update the argv pin in the unshare run test. Do not strip the line number by rewriting the message: that means catching exec's failure inside the body, which is more code on the reference line than the issue warrants.

#### 5. On hosts where `sh` is dash, an empty command name moves from 126 to 127, and every body error changes text

**Severity:** Informational
**Location:** `scripts/confine-tests.sh:268-273`; claim at `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:47`
**Move:** 3, 6
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

**Evidence:**
```
    exec -- "$@"' confine-tests "${cmd[@]}"
```

Run: old script, sh=dash, `-- ""` → `sh: 6: exec: : Permission denied`, exit 126; new → `confine-tests: line 6: exec: : not found`, exit 127. The bwrap and `--no-loopback` forms (stand-ins) give 127, so the new status brings the third form into line with the others. It is an exit-status change outside D1 as the brief words it ("no change ... to exit statuses other than D1's"), caused by the same interpreter swap, and the brief's invariant line does not mention it. Likewise all body error texts on dash hosts change prefix (`sh: 6:` → `confine-tests: line 6:`), and a directory now prints two lines instead of one. No caller depends on either.

**Recommendation:** No code change. Add one line to the research doc's results: "the interpreter swap also changes, on dash hosts, the empty-name status (126 → 127, now matching the other run forms) and the text of the body's exec errors."

#### 6. The guide says `--probe` names the primitive "on its first line" without saying which stream

**Severity:** Informational
**Location:** `guides/test-hermeticity.md:62`
**Move:** 3
**Confidence:** Medium
**Legibility-target:** for-author

**Evidence:**
```
`--probe` names the primitive it found (`bwrap` or `unshare`) on its first line.
```

True of stdout on every route. With `--no-loopback` over a working bwrap the warning goes to stderr first, and a caller that runs `--probe 2>&1 | head -1` (the natural way to "read the first line") gets `confine-tests: WARNING — --no-loopback forces the unshare primitive.` [unverified — submitted as claim: ordering under a merged pipe depends on buffering; in the script both are unbuffered `echo`s and stderr is written first.]

**Recommendation:** "on the first line of stdout".

#### 7. Decision 018's `:220` anchor is stale; one in-branch claim about it is wrong

**Severity:** Informational
**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:22` and `:265`; `scripts/confine-tests.sh:261-268`
**Move:** 3 (documentation drift)
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

**Evidence:**
```
Callers: none in code [observed: `grep -rn confine-tests` over `*.sh`, `*.bats`, `*.py`]. `CLAUDE.md` and decision 018 (`docs/decisions/018-argv-exec-over-shell-string-interpolation.md:43,117`) cite `scripts/confine-tests.sh:220` as the reference for "static shell body, values as positional arguments".
```
```
- Untrusted or operator-shaped text reaches a subprocess as its own argv element, or through a quoted heredoc (`<<'EOF'`). Never interpolate it into a string a shell re-parses: `sh -c "$x"`, `eval`, `shell: true`. Keep a needed shell body static, pass values as `"$1"`…, and put `--` or `./` before path arguments (record 018; the reference pattern is in `scripts/confine-tests.sh`).
```
(the second is `CLAUDE.md:9`)

`CLAUDE.md:9` names the file only, so it is not stale; decision 018 (`:43`, `:117`) names `:220`, which at base was the `exec unshare -rn -- sh -c '` line and is now a blank line after the banner; the pattern is at `:268`. Decision 018 is outside the brief's Paths and its fix is already queued (`research ...:265`, "Recorded under Follow-ups"). Inside the branch: the research doc's `:22` and `:265` say `CLAUDE.md` cites `:220` (the fact-check's one Incorrect). The script itself has no stable name for the reference block, so any line citation will drift again.

**Recommendation:** Fix `:22` and `:265` to say only decision 018 cites `:220`. Optional, inside Paths: start the comment at `scripts/confine-tests.sh:261` with a greppable tag, e.g. `# Decision 018's reference pattern:`, so the follow-up can replace `:220` in 018 with that phrase rather than another line number.

#### 8. The three run forms agree under stand-ins; the real bwrap's exec-failure status is not shown here

**Severity:** Informational
**Location:** `scripts/confine-tests.sh:240-251`
**Move:** 7 (asymmetry)
**Confidence:** Low
**Legibility-target:** for-orchestrator-synthesis

**Evidence:**
```
    --chdir "$PWD" \
    -- "${cmd[@]}"
```

The diff's goal C9 (research doc) is that the unshare form "behaves the same as" the other two, and under the test stand-ins it does (table above). The stand-ins are bash scripts that `exec`, so they report bash's 127/126. [unverified — submitted as claim: real bwrap reports `bwrap: execvp NAME: No such file or directory` and exits 1, and util-linux `unshare` exits 127/126 with `unshare: failed to execute NAME: ...`.] If so, on a real host the bwrap form is the odd one out for a name that cannot be run, which is pre-existing and not caused by this diff.

**Recommendation:** Nothing for this branch. If a live run is ever made (the brief's exit-3 path), note bwrap's status for `-- nofile` in the guide so callers do not key on 127.

## What Looks Good

- One source for the shared warning text (`warn_unshare_only`, `scripts/confine-tests.sh:126-135`), with the same `confine-tests: WARNING — ` prefix, stderr stream and "the unshare primitive" wording as the base `--no-loopback` warning; the three headlines are parallel in shape. [unverified — submitted as claim]
- The warning sits before the banner on all three routes, so "the first stderr line of a run" means the same thing whichever way unshare was reached; the header (`:33`) states the order as a contract. On the fallback route this moves the banner off line 1; no in-repo caller reads it (see Baseline) and pre-mortem narrative 2 records the trade. [unverified — submitted as claim]
- `--probe`'s stdout and status, the refusal paths (no `ip`, nothing to run, no primitive) and the primitive chosen are unchanged in every case run; a fallback probe's stderr stays empty and is now pinned so. [unverified — submitted as claim]
- The headline names the cause (not installed vs refused) and the way back differs per route, so "Drop the flag" is never printed where it would be false.
- No flag, exit-status meaning or stream assignment is added or renamed; the guide's `Relevant paths:` line gains the test file as the brief asks.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | `--help` says `--no-loopback` warns on a probe; not where bwrap is unavailable | Minor | `scripts/confine-tests.sh:44-46` | High |
| 2 | `--no-loopback --probe` stderr re-wrapped; docs claim `--probe` unchanged | Minor | `docs/working/research-...:47,197` | High |
| 3 | "bwrap was refused here" overloads the script's "refuse" | Minor | `scripts/confine-tests.sh:210` | Medium |
| 4 | `confine-tests: line 6:` reads as a script-file location | Minor | `scripts/confine-tests.sh:268-273` | High |
| 5 | dash hosts: empty name 126 → 127, body error text changes | Informational | `scripts/confine-tests.sh:273` | High |
| 6 | guide's "first line" of `--probe` names no stream | Informational | `guides/test-hermeticity.md:62` | Medium |
| 7 | 018's `:220` stale; research doc wrongly says CLAUDE.md cites it | Informational | `docs/working/research-...:22,265` | High |
| 8 | real bwrap's exec-failure status unshown by stand-ins | Informational | `scripts/confine-tests.sh:240-251` | Low |

## Overall Assessment

The change is consistent with the script's conventions: the new warning reuses the existing prefix, stream, wording and position, and the D1 fix makes the third run form agree with the other two on status and argv for every input tried (dash-named, missing, a directory, empty, a builtin's name). Nothing here breaks a caller in the repo, and none parses the output. Everything open is documentation: one self-contradiction in the `--help` text (finding 1), "unchanged" claims that the run disproves in small, harmless ways (findings 2, 5, 7), and two wording choices (findings 3, 4). All are fixable in place with one-line edits; none needs a code change for correctness.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to /workspace/.claude/wt-2026-11-10-confine-tests-dash-and-fallback/docs/reviews/api-consistency-review-2026-11-10-confine-tests-dash-and-fallback.md, structured per the api-consistency-reviewer skill, with a first line `Commit: de1f4bf9`.
- Answered: yes
- Out of scope: behaviour of real bwrap/unshare (the container cannot create a namespace; stand-ins only); decision 018 itself (outside the branch's Paths); BASH_ENV exposure (security critic's area, and S1 puts a self-poisoned environment out of scope).
- Escalate: decision 018 `:43,117` line citation, already queued as a follow-up at research doc `:265`; the fix there is better made against a named tag (finding 7) than another line number.
- Decisions I made: read "no change to exit statuses other than D1's" as including the dash-host empty-name case (finding 5) and rated it Informational because it makes the forms agree; treated a prose re-wrap on stderr as a Minor contract change since no machine consumer exists.
