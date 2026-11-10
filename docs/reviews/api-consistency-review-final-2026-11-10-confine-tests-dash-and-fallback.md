Commit: bd312d15

# API Consistency Review — fix/confine-tests-dash-and-fallback (final confirming pass)

**Scope:** `git diff 23ffb16c..bd312d15`: the command-line contract of `scripts/confine-tests.sh` (flags, exit statuses, stdout/stderr text and order, the argv and argv[0] handed to the test command, `--help`), and how `guides/test-hermeticity.md`, the test names in `test/scripts/confine-tests.bats` and the research doc's "Exit statuses" section describe it
**Date:** 2026-11-10
**Based on:** the three final fact-check replicates (`docs/reviews/code-fact-check-report-final-r{1,2,3}-2026-11-10-confine-tests-dash-and-fallback.md`, as merged in the critic brief) and my own old-against-new runs in `/tmp/claude-1000/-workspace/ef8b0455-8f52-48b8-9dd3-f1af8e1680d1/scratchpad/2026-11-10-confine-tests-dash-and-fallback/review-final-api/` (`matrix.sh` → `matrix.txt`, `warn.sh` → `warn.txt`, `dirprobe.sh`, `cwdprobe.sh`)

## Baseline Conventions

Set by the script at 23ffb16c:

- **Prefix.** Every message the script writes starts `confine-tests: `; the one warning at base adds `WARNING — ` (em dash). Refusals use "refuse/refusing" (`NO CONFINEMENT PRIMITIVE AVAILABLE — refusing to run.`). A primitive that does not work is "unusable"/"not usable" (`which is unusable here`, `Neither primitive is usable in this environment`). The script calls bwrap and unshare "primitive"s; the stronger one gives "the hardened profile".
- **Streams and order.** The `--probe` verdict goes to stdout. Everything else goes to stderr: banner, warnings, refusals, usage. A run prints one banner line (`denying network via P (loopback=N)`) just before it `exec`s, and the `--no-loopback` warning comes before the banner.
- **Exit statuses.** A run returns the child's status. Usage errors, and a `--no-loopback` that cannot be served, exit 2. No primitive, no `ip`, or `lo` that cannot be raised exit 3. When a name cannot be run, the status comes from whichever layer does the exec. For the unshare forms that is 127 (not found) or 126 (cannot execute); real bwrap exits 1 [unverified — submitted as claim; modelled below].
- **Message shape.** Multi-line messages are a headline plus lines indented two spaces, wrapped at about 75 columns (`explain_unavailable`, and the `--no-loopback` warning and refusal).
- **Callers.** No code reads the script's output. `rg -n "confine-tests"` and `rg -n "denying network via|primitive available"` outside the script, its test, `archive/`, `docs/reviews/` and this unit's research doc find only prose: `scripts/hermeticity-lint:29,935,1019`, `CLAUDE.md:9,15`, `test/fixture-hermeticity.bats:15`, the guide, `docs/roadmap.md` and the decisions. Briefs read only the exit status of `--probe` (`docs/working/briefs/2026-11-10-dev-cycle-skill-held-fixes.md:29`: "on exit 0 the tests also pass confined; on exit 3 quote its first line").

### What the runs show

I drove both scripts on built PATHs under `env -i`, in four run forms: bwrap; unshare with loopback, where bwrap is absent; `--no-loopback` over a working bwrap; and `--no-loopback` where bwrap is absent. On the loopback form `sh` was bash, dash or absent; on the other forms it was dash. The bwrap and unshare stand-ins hand the command to `execmodel.py`, a model of how the real tools exec: glibc `execvp`, ENOENT for an empty name, bwrap exits 1, util-linux unshare exits 127 on ENOENT and 126 otherwise. That differs from the test file's stand-ins, which `exec` through bash. It is a model, not the real tools [unverified — submitted as claim]. All 196 rows are in `matrix.txt`. Summarised for the new script:

| Command | bwrap (model) | unshare + lo, new (any `sh`) | unshare `--no-loopback` (model) | unshare + lo, old, `sh`=dash | unshare + lo, old, `sh`=bash |
|---|---|---|---|---|---|
| `-record -x` | runs, 7 | runs, 7 | runs, 7 | runs, 7 | 2 (exec usage) |
| `-a x rec one` | 1 | 127 | 127 | 127 | **rec ran**, 7 |
| `-nonexistent y`, `-p rec one` | 1 | 127 | 127 | 127 | 2 |
| `-- rec one` | 1 | 127 | 127 | 127 | **rec ran**, 7 |
| `nofile`; `cd /` (builtin, no file) | 1 | 127 | 127 | 127 | 127 |
| `''` | 1 | 127 | 127 | **126** | 127 |
| directory, by path | 1 | 126 | 126 | 126 | 126 |
| directory, through PATH (no same name in cwd) | 1 | **127** | **126** | **126** | 127 |
| file without the x bit (by path or PATH) | 1 | 126 | 126 | 126 | 126 |
| `eval echo hi` (a file `eval` on PATH) | runs | runs the file | runs | runs | runs |
| `rec one`, `sh` absent | runs | runs | runs | (127: no `sh`) | (127: no `sh`) |

I ran the directory-through-PATH row on its own (`dirprobe.sh`). bash's PATH search skips a directory and exits 127; it reports 126 only when the cwd holds an entry of the same name, which my first matrix run did by accident. dash, and glibc `execvp`, report 126. bash does not exec a file from the cwd that is not on PATH (`cwdprobe.sh`).

Messages (`warn.txt`): on every input above, `--probe`'s stdout, stderr and status match between old and new. That includes `--no-loopback --probe` over a working bwrap, whose seven-line warning is byte-identical. A fallback run now prints six warning lines and then the banner, where before it printed the banner alone. This agrees with the fact-check's 1,650 to 4,536 runs per replicate.

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `warn_unshare_only` | internal function | `explain_unavailable`, `detect_primitive` | `scripts/confine-tests.sh:88,102` | Consistent: snake_case verb_object; prints a multi-line stderr message, partly from a quoted heredoc |
| `fell_back`, `and_flag` | internal variables | `probe_only`, `loopback`, `primitive` | `scripts/confine-tests.sh:58-60` | Consistent: lowercase snake_case; `fell_back` is a 0/1 flag like `probe_only` |
| `confine-tests: WARNING — bwrap is not installed; falling back to the unshare primitive.` | stderr headline | `confine-tests: WARNING — --no-loopback forces the unshare primitive.` | `scripts/confine-tests.sh:171` | Consistent: same prefix, em dash, "the unshare primitive", final period |
| `confine-tests: WARNING — bwrap is installed but unusable here; falling back to the unshare primitive.` | stderr headline | `It needs \`unshare -rn\`, which is unusable here.` | `scripts/confine-tests.sh:178` | Consistent in vocabulary ("unusable here"). Its 101 characters are the widest line the script prints (Finding 4) |
| way back: `Install bwrap (bubblewrap)[ and drop --no-loopback] to get the hardened profile.` / `Run where bwrap works (a CI runner or a dev host)[ and drop --no-loopback] to get the hardened profile.` | stderr text | `Drop the flag to get the hardened profile`; `Run this on a CI runner or a dev host instead` | `scripts/confine-tests.sh:172-173,119-120` | Consistent wording; the advice in the unusable variant can point back to the host the reader is on (Finding 4) |
| body `$0` `confine-tests: unshare body` (was `sh`) | inner shell's `$0`, the prefix of its errors | the `confine-tests: ` prefix | `scripts/confine-tests.sh:75,191,203` | Consistent: `confine-tests: unshare body: line 6: exec: -a: not found` keeps the prefix and says where the line number counts from |
| test constants `NO_BWRAP_WARNING`, `BWRAP_UNUSABLE_WARNING`, `LO_WARNING_TEXT`, `UNSHARE_BANNER`, `BODY_NAME` | test fixtures | `NO_PRIMITIVE`, `NO_IP`, `NO_LO_OVER_BWRAP`, `LO_WARNING` | `test/scripts/confine-tests.bats:25-28` | Consistent: SCREAMING_SNAKE message constants |
| test helper `dash_named_on_unshare` | test helper | `same_process`, `calls`, `refused`, `confine` | `test/scripts/confine-tests.bats:155-203` | Consistent: lowercase snake_case |

No flag is added, removed or renamed. Which primitive is chosen does not change on any route.

## Findings

#### 1. The research doc's "Exit statuses" section says one status moves outside the dash-named cases; at least two do, and two dash-named rows are missing

**Severity:** Minor
**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:47`, `:288-299`
**Move:** 3 (documentation drift), 6 (versioning impact)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**
```
The first three rows are D1. The fourth is a status that moves outside the dash-named cases, on hosts where `sh` is dash: the old status was whatever that host's `sh` gave, and the new one is bash's everywhere. The brief allows no status change "other than D1's"; I count this one as D1's, because it follows from the fix itself (the body no longer runs under `sh`) and no fix that takes `sh` out keeps a status only dash gave. The review's API pass found it; it is in the marker for the cycle to see. Every other input the review compared, on every route, exits as before, and so does every `--probe`.
```
```
- Which primitive is chosen, every exit status other than D1's, and `--probe` (stdout, stderr and status, for every input) do not change (brief). The tests pin this: the selection tests are untouched, the fallback probe's stderr is pinned empty, and the `--no-loopback` probe's stderr is compared with the whole old warning, byte for byte. One status does move outside the dash-named cases; see "Exit statuses" under Results.
```

I judge the fact-check's escalations as contract changes, using the runs above:

- **`-- -- CMD` (rec ran, 0 → 127) and `-- -p CMD` (2 → 127), where `sh` is bash.** These names start with "-", so they are D1 cases proper, not changes outside it. `-- CMD` is the worst of them: like `-a x CMD`, the command that was named never ran and CMD did. The new 127 matches the `--no-loopback` form and the dash-host behaviour. The remedy is two more rows in the table. No code change is needed.
- **A directory found through PATH, where `sh` is dash (126 → 127).** This is not a dash-named case. It follows from the interpreter swap that fixes D1: bash's PATH search skips directories, while dash's does not. I count it as D1's consequence on the same reasoning the doc gives for the empty name. No fix that drops `sh` keeps a status only dash gave, short of resolving the name outside the body (DD-1 candidate 9, rejected for good reasons). It differs from the empty name in one respect. The empty-name move brings the loopback form into line with the other unshare form (127 on both). This move takes it out of line: modelled util-linux `unshare` (glibc `execvp`, EACCES) gives 126 on the `--no-loopback` form, and the loopback form now gives 127. The row should say so.
- **A host with no `sh` (every run 127 → the command runs).** This is a status change for every input, and it is an improvement. The doc records it only under DD-1's "Consequences" (`:189`), not in the table.

Consumer impact is close to nil. Every status in question is still "the command could not be exec'd" (126 or 127), or a run that now succeeds where it could not. No caller in the repo reads these statuses. The doc's sentence "Every other input the review compared, on every route, exits as before" is the claim a later reader would rely on, and it is not true as written.

**Recommendation:** Recording is the right remedy; code should not change. In the table, add rows for `-- CMD`, `-p CMD` (both D1), a directory through PATH (dash hosts 126 → 127, now unlike the `--no-loopback` form's 126 [modelled]), and "no `sh` on PATH (127 → runs)". Change `:47`'s "One status does move" to "A few statuses move outside the dash-named cases". Change the closing sentence to name the inputs compared, not "every other input".

#### 2. A test name tags a run that does not refuse with H2, whose text requires refusal

**Severity:** Minor
**Location:** `test/scripts/confine-tests.bats:476`
**Move:** 3 (documentation drift: test names as the described contract)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**
```
@test "a run that falls back to unshare first warns what unshare does not confine, in --no-loopback's words (H2)" {
```
`docs/constraints.md:6`:
```
H2: A gate or boundary fails closed and loudly: a missing dependency, unparseable or unmodelled input, absent verdict or degraded primitive refuses and names what went unenforced; nothing ships present-but-inert, and degradation only ever narrows access.
```

In the same file, test 2's "(H2)" (`:214`, "the refusal names what went unenforced (H2)") pins a refusal, as H2 asks. Test 20 pins a degraded primitive that warns and goes ahead, which by its own text H2 says should refuse. The header is honest about the choice ("A weaker primitive is a warning, on every run", `scripts/confine-tests.sh:29`), and the brief keeps refusal out of scope. The test name, though, reads as a claim that the fallback conforms to H2. The fact-check found the same paraphrase in the brief, commit 6465a156 and the research doc (Mostly accurate).

**Recommendation:** Drop "(H2)" from the name, or write "(H2's naming half; the run is not refused, by the brief)". Renaming a bats test changes no behaviour.

#### 3. The three run forms agree on what runs; on exit-failure statuses they agree as well as they did before, with one move each way

**Severity:** Informational
**Location:** `scripts/confine-tests.sh:253-264`, `:284-292`
**Move:** 7 (asymmetry)
**Confidence:** Medium (bwrap and unshare columns are a model of the real tools)
**Legibility-target:** for-orchestrator-synthesis

**Evidence:**
```
  exec unshare -rn -- "$BASH" -c '
    if ! ip link set lo up; then
      echo "confine-tests: failed to bring loopback up inside the namespace." >&2
      exit 3
    fi
    exec -- "$@"' "confine-tests: unshare body" "${cmd[@]}"
fi
exec unshare -rn -- "${cmd[@]}"
```

From the table: on every input, the same file runs or nothing runs, on all three forms, whatever `sh` is. Before the branch, on hosts where `sh` is bash, `-a x CMD` and `-- CMD` ran CMD on the loopback form only. For a name starting "-", a name with no file, a builtin's name, an empty name, a directory by path and a file without the x bit, the two unshare forms now give the same status. The one remaining split between them is a directory through PATH (Finding 1). bwrap exits 1 for every exec failure [unverified — submitted as claim, from the model], which was already so before the branch and is not caused by it. argv[0] reaches the child as the word given on every form: bash's `exec` and `execvp` both pass it unchanged, and the test pins the loopback form's argv to unshare.

**Recommendation:** Nothing in code. If the guide ever documents exit statuses, it should say that "could not exec" is 126/127 on unshare and 1 on bwrap, so callers do not key on 127.

#### 4. In the "unusable" warning the way back can point to the host the reader is already on, and its lines are the widest the script prints

**Severity:** Informational
**Location:** `scripts/confine-tests.sh:221-224`
**Move:** 4 (message consistency)
**Confidence:** Medium
**Legibility-target:** for-author

**Evidence:**
```
  if command -v bwrap >/dev/null 2>&1; then
    warn_unshare_only "bwrap is installed but unusable here; falling back to the unshare primitive." \
      "Run where bwrap works" \
      "(a CI runner or a dev host)$and_flag to get the hardened profile."
```

The header (`:16-17`) says the script runs on "CI and dev hosts". A reader who sees "installed but unusable here" is most likely on one of them already, for example a CI container whose bwrap cannot create its namespaces. In that case "Run where bwrap works (a CI runner or a dev host)" sends them to where they are. The parenthesis repeats `explain_unavailable`'s advice ("Run this on a CI runner or a dev host instead"), which fits there because that message is written for the devcontainer. Separately, the headline is 101 characters, and the `--no-loopback` variant's last line, `  (a CI runner or a dev host) and drop --no-loopback to get the hardened profile.`, is 81. Every other line the script prints wraps at about 75. Changing either is free: neither line appears on a `--probe`, so the brief's "no change to `--probe`" does not bind them.

**Recommendation:** Optional. Something like `Make bwrap usable here, or run where it works,` on one line and `to get the hardened profile.` on the next, with the headline split after "unusable here;". Update the two expected texts in test 20 and the constant at `:40` to match.

#### 5. Vocabulary left over: one test name still says bwrap "refused", and the guide names only the fallback route to unshare

**Severity:** Informational
**Location:** `test/scripts/confine-tests.bats:367`; `guides/test-hermeticity.md:183-184`
**Move:** 2 (naming against the grain)
**Confidence:** High
**Legibility-target:** for-author

Precedent: a bwrap whose probe fails is "unusable", in `scripts/confine-tests.sh:32,222` and `guides/test-hermeticity.md:60` (the name chosen in review pass 1).

**Evidence:**
```
@test "--probe reports unshare when bwrap is not installed, or is installed and refused" {
```
```
- **Reads are not confined** by the runner — `--unshare-net` denies network and nothing else. On the
  `unshare` fallback writes are not confined either (see "Triage vs. ground truth").
```

The test name dates from before the branch, but this branch edited the test (it added the comment at `:368-369`) and moved every other text to "unusable". The test file's stand-in mode is still named `refused`, which is fine as the stand-in's own term. In the guide, `--no-loopback` over a working bwrap also reaches unshare and also leaves writes unconfined. The guide never mentions `--no-loopback`, so "the `unshare` fallback" is the only route it names.

**Recommendation:** Optional. Change the name to "...or is installed and unusable". In the guide, write "On the `unshare` primitive (the fallback, or `--no-loopback`) writes are not confined either".

#### 6. The research doc's test-plan row G4 still gives the body's `$0` as `confine-tests`

**Severity:** Informational
**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:245`
**Move:** 3 (documentation drift)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**
```
| G4 (D1) | the unshare call's argv | `-rn -- <the script's bash> -c BODY confine-tests CMD...`, BODY the same for two commands | characterization | the same |
```

The script (`:290`) and the test (`:42`, `:425`) use `confine-tests: unshare body`. The fact-check marks this Stale.

**Recommendation:** Change it to `-c BODY 'confine-tests: unshare body' CMD...`.

## Earlier pass's fixes (review pass 1, API findings), checked at bd312d15

1. Finding 1, the header said `--no-loopback` warns on a probe everywhere. **Fixed, and right.** `:45-48` now say "Where bwrap works … on a run and on a --probe … Where bwrap does not work, the flag changes nothing about the primitive, and a run prints the fallback's warning." This matches the runs, and `:34-35` covers the probe.
2. Finding 2, the re-wrapped `--no-loopback --probe` stderr. **Fixed, better than the recommendation.** The pass recommended correcting the claim. Instead the author restored the warning byte for byte (`warn_unshare_only`'s `$2`/`$3…` split), so the brief's "no change to `--probe`" holds. Test 11 pins the whole text, and `warn.txt` shows old and new identical.
3. Finding 3, "refused" became "unusable". **Fixed and right**, in the script, header, guide and test constant. One test name is left over (Finding 5).
4. Finding 4, the body's `line N` read as a location in the file. **Fixed and right.** `confine-tests: unshare body: line 6: …` keeps the prefix and names the body.
5. Finding 5, the empty name 126 → 127 on dash hosts. **Recorded, as recommended**, in a new "Exit statuses" section. The section is incomplete (Finding 1).
6. Finding 6, the guide's "first line" named no stream. **Fixed:** "on the first line of its stdout".
7. Finding 7, the 018 anchor. **Fixed in the research doc.** The greppable tag "Decision 018's reference pattern" now sits at `scripts/confine-tests.sh:274`, ready for the decision 018 follow-up.
8. Finding 8, real bwrap's exec-failure status. Still unverifiable here, and modelled in Finding 3.

## What Looks Good

- The branch keeps each of the brief's invariants. The primitive chosen does not change on any route. `--probe`'s stdout, stderr and status are byte-identical for every input I ran, including the `--no-loopback --probe` warning [unverified — submitted as claim; it agrees with the fact-check's thousands of runs]. The only status changes are D1's and their direct consequences (Finding 1).
- All three warnings share the prefix `confine-tests: WARNING — `, go to stderr, use the phrase "the unshare primitive", share the same five body lines from one source, and come before the banner. "The first stderr line of a run" therefore means the same thing whichever route reached unshare, and the header states that order as the contract ("says first, on stderr", `:33`) [unverified — submitted as claim].
- The fallback's way back adds "and drop --no-loopback" only when the flag is set, so neither variant is false on its route. "Drop the flag" is never printed where dropping it would not bring bwrap back.
- Callers that read output keep working, except one that requires the banner on stderr line 1 of a fallback run. No such caller exists in the repo, and that check already failed on `--no-loopback` runs before the branch. Pre-mortem narrative 2 records the trade. A probe's stderr is unchanged.
- `--help` (the header, printed through `awk`) describes all three routes truthfully: the warning on every unshare run, none on a fallback probe, the flag's warning on a probe only where bwrap works. The guide's new paragraph agrees with it.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | "Exit statuses" says one status moves outside dash-named cases; dir-through-PATH and no-`sh` also move, and `-- CMD`, `-p CMD` rows are missing | Minor | `docs/working/research-…:47,288-299` | High |
| 2 | Test 20 is tagged "(H2)", but H2's text requires a refusal | Minor | `test/scripts/confine-tests.bats:476` | High |
| 3 | The three run forms agree on what runs; status agreement as before, one move each way | Informational | `scripts/confine-tests.sh:253-292` | Medium |
| 4 | The "unusable" way back can point to the reader's own host; widest lines in the script | Informational | `scripts/confine-tests.sh:221-224` | Medium |
| 5 | Test name still says "refused"; guide names only the fallback route to unshare | Informational | `test/scripts/confine-tests.bats:367`; `guides/test-hermeticity.md:183-184` | High |
| 6 | G4 row gives a stale body `$0` | Informational | `docs/working/research-…:245` | High |

## Overall Assessment

The branch is consistent with the script's conventions and keeps what its callers can rely on. No flag, stream assignment or `--probe` output changes. The new warnings reuse the existing prefix, vocabulary, position and text. The D1 fix makes the loopback form run the same file as the other two forms for every input tried. The fact-check's escalations come out as follows. The `-- CMD` and `-p CMD` moves are D1 cases proper. The directory-through-PATH move is a consequence of D1's interpreter swap, like the empty name, but unlike the empty name it leaves the two unshare forms disagreeing (127 against a modelled 126). None of the three justifies a code change. Listing them in the research doc's table, and correcting its "one status" and "every other input" sentences, is the right remedy (Finding 1). What remains is wording, all in docs and test names, and none of it blocks the merge. I found nothing Breaking or Inconsistent.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to /workspace/.claude/wt-2026-11-10-confine-tests-dash-and-fallback/docs/reviews/api-consistency-review-final-2026-11-10-confine-tests-dash-and-fallback.md, structured per the api-consistency-reviewer skill, with a first line `Commit: bd312d15`.
- Answered: yes
- Out of scope: behaviour under a real bwrap or unshare (this container cannot create a namespace; the bwrap and unshare columns come from a glibc-execvp model); decision 018's stale `:220` (outside the brief's Paths, already a follow-up); BASH_ENV exposure (security's area, and S1 puts a caller's own environment out of scope).
- Escalate: nothing
- Decisions I made: I modelled the real tools' exec with a Python glibc-`execvp` stand-in in place of the test file's bash-`exec` stand-ins, because the bash stand-ins hide the directory-through-PATH split between the two unshare forms. I counted the directory-through-PATH and no-`sh` moves as D1's consequences, the reading the research doc already uses for the empty name, and rated the doc gap Minor because no caller reads these statuses.
