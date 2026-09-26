Commit: 5bdee46

# Architecture Review: skill-fixtures (Q-062 [2], Q-063 [1]), iteration 4 (user-authorized terminal pass)

**Scope:** `git diff main...HEAD` on skill-fixtures (HEAD 5bdee46), the whole branch. The weight is on 37c5ea9 (iteration 3's fixes, not yet reviewed) and on regressions. Code files: `test/skills/arithmetic-eval/mode1-equiv.py`, `test/skills/generate-reports.bash` (the deny-record verdict), `test/skills/eval-helpers.bash` (`tool_inputs_checked`, `assert_mode1_equiv`), `test/skills/runner-contract.bash`, and `devcontainer-config/install.sh` (`procs_in_checkout`, `agent_gate`). Prose that restates a code contract (the generator header, the DD doc's "As built" section, log #56) is reviewed only as a copy of that contract.
**Date:** 2026-09-25
**Based on:** `docs/reviews/code-fact-check-report.md` (Commit 5bdee46, 31 claims). This review does not re-verify what that report established. It builds on Claims 9b, 13, 14, 16b, 18 and 20a-20c. I ran one new cross-component probe, `docs/reviews/execution-logs/arch-5bdee46-gen-vs-mode1.txt`. It feeds the generator's jq program and mode1-equiv.py the same malformed transcripts. The fact-check report tested each component on its own.

**Scope check.** Three trigger categories apply:
- *Public APIs:* the checker hook's exit protocol (0/1/2), and the `tool_called:` / `no_tool_called:` vocabulary with its new init requirement.
- *Cross-cutting:* the deny-record run-voiding pipeline (generator verdict → `.failed` → `eval_fixture` gate → checks), and install.sh's detector-to-gate return-code protocol.
- *Data models:* the positional TSV that the generator's jq verdict hands to bash, and the stream-json event shape that three parsers read.

**Trust-boundary cross-reference.** The newest security review is `docs/reviews/security-review-2026-09-25-q062-q063-iter3.md` (Commit: `c7747c7`). That review predates this diff, so its boundaries may be stale. Its labels used below:
- `B3`: CLI stream-json → transcript.jsonl → generator tripwire and canary → `.failed`.
- `B4`: transcript.jsonl → eval-helpers transcript checks and mode1-equiv.py → the fixture's pass or fail.
- `B6`: same-uid processes → `procs_in_checkout` and pgrep → `agent_gate`.

Finding 1's recommendation removes a re-check on `B4`. It is tagged with a Security implication and deferred to a combined review.

**Not re-filed (settled or owned elsewhere):** A1/Q-064, A20, C3, C4, C5, C6, C9, C13, C14, C15, C24, C30, trap RETURN, `--tools` variadic, RUNNER_ALLOWED_TOOLS naming. C8 (the tripwire is implemented twice) is open by choice. Finding 1 does not re-open it on the old grounds. It brings new evidence, which the brief asked for: the Claim 13 crash site is the duplicate itself, and the duplicate's semantics differ from the generator's (Claim 9b).

## Dependency Map

The harness layering has not changed since iteration 3:

`runner.bash` → `runner-contract.bash` (validates settings) → `generate-reports.bash` (argv, then **one jq verdict** for deny-record runs → `.failed`) → `eval-helpers.bash` (`eval_fixture`: `.failed` gate first, then the check dispatch) → the skill-owned `test/skills/<skill>/mode1-equiv.py`.

What 37c5ea9 changed structurally:

- **Generator.** The tripwire, the parser canary and the init canary are now a single jq program over the whole stream. Its output is a positional TSV `undenied unseen init_state cli_version`, which one `read -r` consumes (`generate-reports.bash:273-303`).
- **Check layer.** `tool_inputs_checked` now requires an init event, as iteration 3's F2 recommended.
- **mode1-equiv.py.** `bash_calls` type-guards events: non-object, non-list and non-dict shapes are skipped, and a bad `input`/`command` raises `SetupError`. The duplicate tripwire comprehension below the `try` was not touched.
- **install.sh.** The blind-scan NOTE moved from the detector to the gate. `procs_in_checkout` now reports only through its return code (0/2/3/4) and stdout, and `agent_gate` owns every message. This resolves iteration 3's F4.

Stream-json schema knowledge still lives in three parsers:
- the generator's jq, which is whole-stream, `objects`, `[]?`, and `tostring` for ids;
- eval-helpers' jq, which is line-by-line `fromjson?` with `[]?`;
- mode1-equiv's Python, which uses `isinstance` skips plus raw `set` membership on ids.

`eval_fixture` orders them. The generator's verdict is checked (`.failed`) before any check runs.

## Findings

#### 1. The A10→A11→A19→Claim 13 re-fires share one cause. mode1-equiv promises a total exit-code classification over the transcript's shape, but it does not own transcript validity. Its duplicate tripwire re-parses denials with semantics that differ from the generator's

**Severity:** Coupling
**Location:** `test/skills/arithmetic-eval/mode1-equiv.py:31-36` (docstring contract), `:159-186` (main's `try` and the tripwire after it); `test/skills/generate-reports.bash:273-303` (the generator verdict); `test/skills/eval-helpers.bash:80-83` (`.failed` gate), `:481-494` (`assert_mode1_equiv`)
**Move:** #3 module boundary (whose contract is this?), #7 coupling surface (duplicated schema logic with different semantics)
**Confidence:** High. The mechanism was executed (fact-check Claim 13 and my probe log). The practical exposure is low: every case fails closed.
**Legibility-target:** for-orchestrator-synthesis

**Evidence (verbatim):**
```python
# test/skills/arithmetic-eval/mode1-equiv.py:31-36 (end of the module docstring, :2-37)
Exit 0 on a match (or a valid spec), 1 on no match (per-call diagnostics on
stdout), 2 on any setup error: usage, value spec, an unreadable file, a
transcript event of the wrong shape, or a SKILL.md whose Mode 1 block does
not extract (message on stderr). Every setup error goes through SetupError in
main(), so none can escape as a traceback with exit 1, which would read as
"the model did not compute the value".
```
```python
# test/skills/arithmetic-eval/mode1-equiv.py:172-186 (inside main, :159-207; the per-call loop :188-207 follows)
        evs = events(transcript_path)
        calls = bash_calls(evs)
    except SetupError as e:
        print("mode1-equiv: " + str(e), file=sys.stderr)
        return 2

    denied = {d.get("tool_use_id") for ev in evs
              if isinstance(ev, dict) and ev.get("type") == "result"
              for d in (ev.get("permission_denials") or []) if isinstance(d, dict)}
    denied.discard(None)
    # A call with no id counts as undenied (review iteration 3, C28).
    undenied = [cid for cid, _ in calls if cid is None or cid not in denied]
    if undenied:
        print(f"Bash tripwire: {len(undenied)} Bash call(s) not in permission_denials (may have executed): {undenied}")
        return 1
```
```bash
# test/skills/generate-reports.bash:277-279 (inside the jq program :275-286, inside generate_one :139-314)
        | ([$ev[] | select(.type == "result") | .permission_denials[]?
            | select(type == "object" and .tool_name == "Bash") | .tool_use_id]) as $denied
        | ($denied | map(select(. != null) | {(tostring): true}) | add // {}) as $dset
```
```
# docs/reviews/execution-logs/arch-5bdee46-gen-vs-mode1.txt (probe; generator voids unless "0 0 bash")
pd=5, no calls               gen=0	0	bash	unknown  m1=1 TypeError: 'int' object is not iterable
pd=5, one call               gen=1	0	bash	unknown  m1=1 TypeError: 'int' object is not iterable
list id both sides           gen=0	0	bash	unknown  m1=1 TypeError: unhashable type: 'list'
list id denial only          gen=1	1	bash	unknown  m1=1 TypeError: unhashable type: 'list'
obj id both sides            gen=0	0	bash	unknown  m1=1 TypeError: unhashable type: 'dict'
denied under Read (9b)       gen=1	0	bash	unknown  m1=1
string message               gen=jq: error (…) Cannot index string with string "content"  m1=1
```

**Why this keeps re-firing.** Each iteration listed more wrong shapes and routed them to `SetupError`:
- A10: spec and usage errors.
- A11: unreadable files, `nan`, negative tolerance.
- A19: a bad `input` or `command`.

The docstring made a promise about *every* transcript shape, so each pass could find one more shape outside the list. Claim 13 finds two more classes. Both come from the same structural fact: **transcript validity is the generator's job, and mode1-equiv holds a second, divergent copy of part of it.**

- *(a) The crashes are all in the duplicate.* The three tracebacks in Claim 13 (`permission_denials: 5`, a list id, an object id) are raised by the tripwire comprehension at :178-183. That code is outside the `try` because it was never meant to validate anything. It re-derives a verdict the generator has already made, under different rules. The generator filters denials by `tool_name == "Bash"` and compares ids with `tostring`. mode1-equiv accepts any tool's denial (Claim 9b) and hashes raw values.
- *(b) The "skips" are consistent with the harness, not a defect.* A non-object line, a string `content` or a non-dict block is skipped by `bash_calls`. The generator (`objects`, `[]?`) and `transcript_tool_inputs` (`fromjson?`, `[]?`) skip them the same way. A string `message` makes the generator's jq fail, so that run is voided before any check. The parser canary catches Bash calls hidden this way. So exit 1 "No Mode 1 call" on these inputs is the harness's shared parse rule working as designed. The docstring promises more than the design needs.

**What reaches the checker through the real path.** `eval_fixture` refuses any fixture with a `.failed` marker before it dispatches (`eval-helpers.bash:80-83`), so only transcripts the generator accepted ("0 0 bash") reach mode1-equiv. In the probe, those are:
- `permission_denials: 5` with no Bash calls. Exit 1 is *truthful* here: the model made no call.
- Non-string ids that match on both sides. The generator's `tostring` accepts them and mode1-equiv crashes. No CLI emits these.

So through `eval_fixture` the duplicate adds no detection, only a crash surface and a second definition to keep in step. It is still the only guard in one real case, though, because the `.failed` marker is *negative*: its absence means either "checked and passed" or "never checked". The report is written at :245-246, before the deny-record verdict at :273. A generator interrupted between those lines (Ctrl-C, an OOM kill) leaves a report and a transcript with no marker, and `eval_fixture` then grades them. (Static reading: `load_eval_report` grades any report that exists; this window was not executed.)

**Answer to the brief's question.** "Whole checker = boundary, any unexpected exception → exit 2" is necessary but not sufficient, and it is the wrong fix to do alone:
- It closes (a) by construction. A top-level `except Exception` makes "no traceback exits 1" true without enumerating shapes, which is what ends the re-fire series.
- It leaves the divergent tripwire in place: two definitions of "denied", C8 plus Claim 9b.
- It leaves (b)'s over-promise in the docstring.
- It turns a checker bug into "setup error", which is acceptable if the label says "checker or setup error".

Dropping the duplicate and trusting `.failed` is the better structure. It is safe only once the marker is fail-closed by construction, so do it in this order:

1. **Make the generator's verdict the single authority, positively.** Write `.failed` ("generation incomplete") right after the `rm -f` at :152, and remove or overwrite it only once every check has run (:306-313). Absence of the marker then means "checked and passed", never "not checked", and the interrupt window closes.
2. **Delete mode1-equiv's tripwire** (:178-186) and its test (`mode1-equiv.bats:139`). The docstring should state the precondition: "runs on a transcript `eval_fixture` admitted (no `.failed` marker); the deny-record tripwire is `generate-reports.bash`'s". This closes C8's tripwire half and Claim 9b.
3. **Keep a catch-all as a backstop.** In `__main__`, map any exception other than `SetupError` to exit 2 with "checker error (not a model result)". Code the tripwire never touched can still raise, for example `FileNotFoundError` from `subprocess.run(["python3", …])`.
4. **Narrow the docstring to what the design guarantees.** Exit 2 means the checker's own inputs (argv, spec, SKILL.md, file read) or a checker error. Transcript shapes that the harness-wide parse rule skips are "no call seen" (exit 1), and the generator's parser canary covers hidden calls.
5. **Pin it with one test,** so the next pass does not rediscover the shapes by probe. Feed a table of malformed transcripts to the checker and assert that the exit code is 1 or 2 and that stderr has no `Traceback`. A19's shape handling has no test today: `rg 'string input' test/` matches only the source.

If the author keeps the duplicate as defense in depth instead, do step 3 regardless. Then make the duplicate *identical* to the generator's rule: filter denials by `tool_name == "Bash"` and compare `str()`/JSON-serialized ids. Also say in the docstring why it exists (the interrupt window). An enumerated `SetupError` list will re-fire again.

**Recommendation:** Do steps 1-5 above, or at minimum steps 3-5. That makes "whole checker = boundary" a backstop, not the contract. Record the choice in the rubric row so a fifth pass does not reopen it.

**Security implication:** Step 2 removes the re-check on `B4`, and the tripwire then lives only on `B3` (`docs/reviews/security-review-2026-09-25-q062-q063-iter3.md`, Commit: `c7747c7`; that review predates this diff, so the boundary may be stale). Step 1 is what makes that safe: without a positive marker, an interrupted generation reaches `B4` unchecked. Do not do step 2 without step 1. The security reviewer should confirm that `B3` alone is acceptable, together with C29 (the tripwire catches accidental breaches, not concealed ones).

#### 2. Transcript well-formedness has two owners that apply different rules: an init requirement only for deny-record runs in the generator, and one for every transcript run in `tool_inputs_checked`. The init selector is still spelled twice

**Severity:** Minor
**Location:** `test/skills/generate-reports.bash:247-256` (result-state check, all transcript runs), `:265-267, 276, 299` (init canary, deny-record only); `test/skills/eval-helpers.bash:376-401` (`tool_inputs_checked`)
**Move:** #2 responsibility boundaries, #7 coupling (schema selector duplicated)
**Confidence:** Medium
**Legibility-target:** for-author

**Evidence (verbatim):**
```bash
# test/skills/eval-helpers.bash:376-383 (comment above tool_inputs_checked, :384-401)
# tool_inputs_checked <transcript> <tool>: print the tool's inputs (as
# transcript_tool_inputs does), or fail with a message when the file cannot be
# read, when it holds no init event (a junk or truncated transcript, which
# would otherwise read as "no calls" and let a negative check pass), or when
# the init event lists the run's tools and <tool> is not one of them (a
# misspelled name such as "bash"). It does not detect a changed event shape
# that hides tool_use blocks: generate-reports.bash's parser canary does, for
# deny-record runs, and eval_fixture fails any run with a .failed marker.
```
```bash
# test/skills/eval-helpers.bash:390-394 (inside tool_inputs_checked, :384-401)
  # grep, not jq -e: jq's exit status reflects only the last input line.
  if ! jq -rR 'fromjson? | select(.type == "system" and .subtype == "init") | "init"' "$t" 2>/dev/null | grep -q .; then
    echo "No init event in $t: not a complete stream-json transcript"
    return 1
  fi
```
```bash
# test/skills/generate-reports.bash:248-255 (inside generate_one, :139-314)
    if [ -z "$failure" ]; then
      local result_state
      result_state=$(jq -rR 'fromjson? | select(.type == "result") | if .is_error then "error" else "ok" end' \
        "$transcript_path" 2>/dev/null | tail -n 1)
      case "$result_state" in
        ok) ;;
        error) failure="the result event is an error" ;;
        *) failure="no result event in the stream" ;;
      esac
```

37c5ea9 did what iteration 3's F2 asked, and the check layer now fails closed without an init event. But "is this a complete stream?" is now answered in three places, with three scopes:
- the generator checks the result event for every transcript run;
- the generator checks the init event for deny-record runs only;
- `tool_inputs_checked` checks the init event for every transcript run, but only when a `tool_called`/`no_tool_called` check is dispatched.

The drift the fact-check found follows from this. `tool_inputs_checked` claims to catch "truncated" transcripts. A tail truncation is caught upstream by the result-state check (Claim 16b). The generator comment says "start with". Neither copy checks position (Claim 20c). A future CLI change to the init event (`subtype` renamed, `tools` moved) must be made in the generator's fused jq and in two eval-helpers jq calls. If it is made only in eval-helpers, deny-record runs are voided as "no init event". If it is made only in the generator, every `no_tool_called` fails. Both fail closed, but they fail in different places.

**Recommendation:** Give well-formedness one owner, the generator. Move the init-presence check next to the result-state check for every `FIXTURE_TRANSCRIPT=1` run, so `.failed` becomes the one "complete stream" verdict. `tool_inputs_checked` keeps only what the generator cannot know, the tool-name check against the init event's `tools`, and its comment points upstream for completeness. Either keep eval-helpers' init check as a documented belt, or drop it. That is a local call. Also fix "start with" to "contain".

#### 3. The voiding conditions are restated in four places, and the one the DD doc names as the reference is stale. This is the C21 pattern again, for voiding rules instead of flags

**Severity:** Minor
**Location:** `test/skills/generate-reports.bash:31-37` (header `FIXTURE_BASH` entry), `:257-272` (block comment), `docs/working/dd-arith-eval-bash-grant.md:174-175`, `docs/decisions/log.md:77`
**Move:** #3 module boundary (where the contract's single statement lives)
**Confidence:** High (fact-check Claims 18 and 7)
**Legibility-target:** for-author

**Evidence (verbatim):**
```bash
# test/skills/generate-reports.bash:31-37 (header comment, :1-80)
#   FIXTURE_BASH (optional) — "deny-record" lets FIXTURE_TOOLS be exactly Bash
#                     and pins DENY_RECORD_FLAGS (defined below, with why), so
#                     every Bash call is denied and only recorded (Q-063 [1]).
#                     Needs FIXTURE_TRANSCRIPT=1; refuses CLAUDE_FLAGS. A run is
#                     recorded as failed when any Bash call is missing from the
#                     result's permission_denials (it may have executed), or
#                     when the init event does not list Bash (canary).
```
```markdown
<!-- docs/working/dd-arith-eval-bash-grant.md:174 (the "Contract." bullet, whole line) -->
- **Contract.** The code is the reference: the `FIXTURE_BASH` entry in `generate-reports.bash`'s header, `DENY_RECORD_FLAGS` below it, and `check_runner_settings` in `runner-contract.bash`. …
```
(the bullet continues with the summary of the contract; read)

C21 fixed this pattern for the flags by naming one array and pointing all prose at it. The voiding rules got no such anchor. The block comment at :257-272 is accurate apart from "start with". The header, the DD doc's Run-voiding bullet and log #56 each restate the list. The header is the copy the DD doc names as "the reference", and it lists two conditions where the code has four. Each new canary means four edits, and the reference copy is the one that was missed.

**Recommendation:** Make the block comment above the verdict jq (:257-272) the single statement. The header entry should say "voiding rules: see the 'Deny-record checks' comment in generate_one" instead of listing them, and the DD doc's Contract bullet should name that comment. Log #56 is a dated record and may keep its snapshot.

#### 4. The one-pass jq verdict is a sound single authority, but its output is a positional TSV with an implicit schema, and any jq error collapses all four checks into one cause

**Severity:** Informational
**Location:** `test/skills/generate-reports.bash:273-303`
**Move:** #7 coupling surface (stamp coupling through a positional record)
**Confidence:** High
**Legibility-target:** for-author

**Evidence (verbatim):**
```bash
# test/skills/generate-reports.bash:283-293 (inside generate_one, :139-314; the case on init_state follows at :297-301)
        | [ ($calls | map(select(. == null or ($dset[tostring] | not))) | length),
            ($denied | map(select(. == null or ($cset[tostring] | not))) | length),
            (if $init == null then "none" elif (($init.tools // []) | index("Bash")) then "bash" else "nobash" end),
            ($init.claude_code_version // "unknown") ] | @tsv' \
        "$transcript_path" 2>/dev/null) || verdict="unreadable"
      local undenied unseen init_state cli_version
      if [ "$verdict" = unreadable ] || [ -z "$verdict" ]; then
        failure="${failure:+$failure; }Bash tripwire: the transcript could not be read, so denials are unverified"
      else
        IFS=$'\t' read -r undenied unseen init_state cli_version <<< "$verdict"
        [ "$undenied" = 0 ] \
```

The design is right. There is one read of the stream, one decision and one place that writes `.failed`, and it answers the brief's question: as the deny-record verdict, it deserves to be the *only* one (Finding 1). Two structural notes, neither harmful today:
- **The field order is a schema that nobody names.** The array order in jq and the variable order in `read -r` must match by hand. Every mismatch fails closed, because a shifted field is not `0`/`bash`. Even so, adding a fifth field touches both ends with nothing to connect them.
- **Every jq error reads as the tripwire.** A string `message` fails the whole program, and the run is voided as "Bash tripwire: the transcript could not be read" (Claim 9a scope). That still fails closed, but the message names the wrong mechanism.

The fact-check extracted this program verbatim into `cfc-5bdee46-gen.jq` so it could run 24 probes against it. That shows the program wants to be a file of its own.

**Recommendation:** None required. If the program changes again, move it to `test/skills/deny-record-verdict.jq`. The generator runs it with `-f`, tests probe it directly, and a header comment names the output fields in order. Change the unreadable message to "deny-record checks: the transcript could not be parsed".

#### 5. install.sh's rc protocol after rc 4 is clean for today's states. Q-064's candidate answers need a per-process output class that a return code cannot carry

**Severity:** Informational
**Location:** `devcontainer-config/install.sh:1142-1173` (`procs_in_checkout`), `:1192-1211` (the gate's `case`)
**Move:** #8 extension points
**Confidence:** Medium
**Legibility-target:** for-author

**Evidence (verbatim):**
```bash
# devcontainer-config/install.sh:1157-1173 (procs_in_checkout, whole function)
procs_in_checkout() {
  local root d pid cwd cmd readable=0
  [ -d /proc/self ] || return 2
  root="$(cd "$REPO_ROOT" && pwd -P)" || return 3
  for d in /proc/[0-9]*; do
    [ -O "$d" ] || continue                     # this uid's processes only
    cwd="$(readlink "$d/cwd" 2>/dev/null)" || continue   # unreadable: see above
    readable=$((readable + 1))
    case "$cwd" in "$root"|"$root"/*) ;; *) continue ;; esac
    pid="${d#/proc/}"
    in_lineage "$pid" && continue
    cmd="$(tr '\0' ' ' 2>/dev/null < "$d/cmdline")"
    [ -n "$cmd" ] || continue                   # exited, or a kernel thread
    printf '%s %s\n' "$pid" "${cmd% }"
  done
  [ "$readable" -gt 0 ] || return 4
}
```

37c5ea9 fixed iteration 3's F4. The detector no longer writes to stderr. It reports through its return code and stdout only, and `agent_gate` owns every message: the rc 2/3 refusals, the rc 4 NOTE in the docker NOTE's "not checked, treated as none" shape, and a catch-all `*)`. The dependency direction (gate → detector → `/proc`) is intact.

The return code carries one status that is not an error. rc 4 means a *wholly* blind scan, and it comes out of the same channel as the errors (2, 3). That works because rc 4 is output-free by construction. A partly blind scan (ssh-agent, or a non-dumpable helper) is rc 0 with the skips silent, which is A1, acknowledged. Q-064's options [2] "refuse" and [3] "skip but name" both need per-process "cwd unknown" lines next to the hit lines (C22 noted this). When Q-064 is answered, the protocol has to become tagged stdout lines (for example `hit <pid> <cmd>` / `unknown <pid> <cmd>`), and rc 4 becomes the degenerate case "every line is unknown". Nothing needs to change now.

**Recommendation:** None now. Add a line to Q-064's entry: "answering [2]/[3] changes `procs_in_checkout`'s output to tagged lines; rc 4 becomes derivable from them".

## What Looks Good

- **One verdict, one writer.** The generator's three deny-record checks became one pass with one `failure` accumulator, and the checks run even when the run already failed (C10). The parser canary is the right shape of defense against schema drift. It cross-checks two independent parts of the stream (assistant calls against result denials), so one parser change cannot blind both unless both shapes change together (Claim 20b).
- **The init canary splits "did not start" from "deny rule removed Bash"** (A17). Each failure now names its real cause, and the CLI version is recorded for each run.
- **The install gate owns all of its text.** The detector is now a pure producer (return code plus stdout). This fixes iteration 3's F4 in the form it recommended, and it reuses the docker NOTE's wording, so the gate's NOTEs read as one family.
- **The pattern suite calls the grader's own matchers** under `run`, with a self-test that they can fail. The offline suite now tests the real code path, not a copy (iteration 3's F5 is resolved, and R1 is closed by construction).
- **runner-contract checks FIXTURE_BASH before the loop that reads it** (C26), so validation order follows data dependency.
- **C25's dispatcher test runs a stub checker for a second skill.** That makes the per-skill resolution a tested contract, not a comment.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | The re-fire chain's cause: mode1-equiv promises total shape classification but does not own transcript validity. Its duplicate tripwire (outside the `try`, with semantics that differ from the generator's) is the only crash site, and `.failed` is a negative marker. Fix: a positive marker, drop the duplicate, a catch-all backstop, a narrowed docstring, a shape-table test | Coupling | `mode1-equiv.py:31-36, 159-186`; `generate-reports.bash:152, 245-246, 273-313`; `eval-helpers.bash:80-83` | High (mechanism) / Low (exposure) |
| 2 | Two owners for well-formedness with different scopes. The generator checks init only for deny-record runs, `tool_inputs_checked` checks it for all runs, and the init selector is spelled in both | Minor | `generate-reports.bash:247-256, 265-267, 276`; `eval-helpers.bash:376-401` | Medium |
| 3 | The voiding rules are restated in four places. The header, which the DD doc names as the reference, lists two of the four | Minor | `generate-reports.bash:31-37, 257-272`; `dd-arith-eval-bash-grant.md:174-175`; `log.md:77` | High |
| 4 | The one-pass jq verdict is right as the single authority. Its positional TSV has an implicit schema, and every jq error is labelled "tripwire" | Informational | `generate-reports.bash:273-303` | High |
| 5 | The rc protocol is clean after rc 4 moved to the gate. Q-064 [2]/[3] will need tagged output lines | Informational | `install.sh:1142-1211` | Medium |

## Overall Assessment

37c5ea9 improves the structure. The deny-record verdict is now one pass with one writer, the install gate owns all of its messages, and the pattern suite tests the real matchers. Three iteration-3 findings (F2, F4 and F5) are resolved in the recommended form, and I found no regression in dependency direction.

The one issue that matters is Finding 1, and it explains the A10→A11→A19→Claim 13 chain. Each fix added shapes to a list, because the docstring promised a total classification of transcript shapes. But the checker is not the component that owns transcript validity. The generator is, and the duplicate tripwire, which re-parses with different rules, is where every remaining crash comes from. A catch-all alone would stop the tracebacks but keep two definitions of "denied".

The durable fix is to make the generator's `.failed` fail-closed by construction (written first, cleared last), then delete the duplicate. Keep a catch-all as a backstop, narrow the docstring, and pin it with a shape-table test. This is fixable in place: about 20 lines across two files and one test. It does not block the merge. Every path fails closed, and none produces a false pass.

## Goal-Alignment Note

- **Success criterion (verbatim):** "A markdown critique saved to the path named in your role section below, structured per your skill."
- **Answered:** Yes. The critique is saved to `docs/reviews/architecture-review-2026-09-25-q062-q063-iter4.md`, with `Commit: 5bdee46` at the top, and nothing is committed. Every finding has a Severity, Location, verbatim Evidence (with a truncation marker on each partial excerpt), Confidence and Legibility-target. Coverage of the four focus areas:
  - the re-fire chain and "boundary vs drop the duplicate": Finding 1 answers it, with a recommended order and why neither option is enough alone;
  - the one-pass jq verdict: Findings 1 and 4, and What Looks Good;
  - `tool_inputs_checked` vs the generator's responsibilities: Finding 2;
  - the install.sh rc protocol after rc 4: Finding 5, and What Looks Good.
- **New evidence:** `docs/reviews/execution-logs/arch-5bdee46-gen-vs-mode1.txt`. It shows that all three Claim 13 crashes happen in the duplicate tripwire, and that only non-string ids matching on both sides (never emitted by the CLI) and "`permission_denials: 5` with no calls" (where exit 1 is truthful) get past the generator to the checker.
- **Regressions from 37c5ea9:** none structural. The docstring over-promise (Claim 13/14), the stale header (Claim 18) and "start with" (Claim 20c) are prose that lags the code, covered by Findings 1-3.
- **Out of scope:** Claim 24b and Claim 21 (commit-message and test-name accuracy); whether `B3` alone is an acceptable trust placement (security-reviewer); and the settled items listed at the top.
- **Escalate:**
  - To the orchestrator: Finding 1's step order. Step 2 (drop the duplicate) must not land without step 1 (a positive marker). If the author does only part of it, steps 3-5 are the minimum that ends the re-fires.
  - To security-reviewer: Finding 1's Security implication on `B3`/`B4`, and the interrupt window, in which a report and transcript with no `.failed` marker are graded. That window was found by static reading and not executed.
- **Decisions:** None made. I wrote one probe log and changed nothing else.
