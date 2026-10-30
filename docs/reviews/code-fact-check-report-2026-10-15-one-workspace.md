# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-one-ws (branch `fix/cc-isolated-one-workspace`)
**Scope:** branch diff `5e6e9266..a54bb3b0` (cc-isolated.sh, install.sh, guides/cc-isolated-usage.md, test/cc-isolated-functions.bats, docs/working/plan-2026-10-15-cc-isolated-one-workspace.md) plus commit message a54bb3b0, plus one out-of-diff comment that references the changed behaviour (init-firewall.sh:347-349)
**Commit:** a54bb3b0
**Replication:** k=1 (loop pass, decision 031)
**Checked:** 2026-10-15
**Total claims checked:** 22
**Summary:** 15 verified, 6 mostly accurate, 1 stale, 2 incorrect, 0 unverifiable (24 verdicts: 22 numbered claims, of which Claims 6 and 8 are split into a/b sub-claims)

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`). Claim 21 matches the logged class "test-count claimed in a commit message differs from the run" (entries for 59ca38f and 37c5ea9). No fabricated symbol, API or flag found, so no log entry is due (and this agent's brief forbids editing repo files other than this report).

**Execution provenance (shared by the executed claims).** All captured output lives in `/home/node/.claude/jobs/00bcf178/tmp/one-ws/cfc/` (the scratch dir; not in the repo, per the probe rules). Stubbed devcontainer CLI throughout (the bats `smart_devcontainer_stub`); no Docker, no real install.

| Log | Command (cwd) | Exit | Started |
|---|---|---|---|
| `bats-new.log` | `timeout 600 bats -f 'workspace\|pasted\|after --\|#x\|Next steps' test/cc-isolated-functions.bats` (worktree) | 0 | 2026-10-15T05:30:53-07:00 |
| `probe.log` | `CFC_NEW=…/new CFC_OLD=…/old/devcontainer-config CFC_BAD=…/newbad timeout 600 bats --show-output-of-passing-tests probe.bats` (scratch; `old` = `git archive 5e6e9266`, `newbad` = HEAD copy with a malformed `host-tools.sha256`) | 0 | 2026-10-15T05:31:43-07:00 |
| `head-default.log`, `head-cutf8.log`, `base-default.log` | `timeout 600 bats -j 4 test/cc-isolated-functions.bats test/cc-push.bats test/install-host.bats` at HEAD (default locale en_US.UTF-8, which is not installed), at HEAD with `LC_ALL=C.UTF-8`, and on a `git archive 5e6e9266` tree | 1 / 0 / 1 | 2026-10-15T05:32:08-07:00 |
| `head-serial-reds.log` | the six HEAD reds re-run serially (worktree) | 1 | 2026-10-15T05:35:02-07:00 |
| `newtests-on-old.log` | the five new bats tests run against 5e6e9266's devcontainer-config (scratch `mix/`) | 1 (all 5 fail) | 2026-10-15T05:36:01-07:00 |
| `zsh-probe.log` | `printf '…' \| timeout 20 zsh -f -i` (scratch), zsh 5.9 | 0 | 2026-10-15T05:36:14-07:00 |
| `probe2.log` | `CFC_NEW=…/new timeout 300 bats --show-output-of-passing-tests probe2.bats` (scratch) | 0 | 2026-10-15T05:36:43-07:00 |

---

## Claim 1: "One workspace per run. A second one, or a word starting with '#' (a pasted '# note': zsh passes it as words unless interactive_comments is set), is bad usage, exit 2; name a directory called '#x' as ./#x."

**Location:** `devcontainer-config/cc-isolated.sh:18-20` (printed by `--help`)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Severity:** Minor
**Legibility-target:** for-author
**Scope:** Covers the second-workspace refusal, the `#` refusal before `--`, the zsh mechanism and the `./#x` escape; does not establish behaviour for a `#` word after `--` (which this header leaves unqualified).

The `#` refusal is a case arm of the pre-`--` loop only:

```bash
# devcontainer-config/cc-isolated.sh:778-785
      --)           shift; break ;;
      -*)           echo "ERROR: unknown flag: $1" >&2; usage >&2; exit 2 ;;
      # Checked at the first word of a note, so a note's later words can never act
      # as flags (`cc-isolated  # --bless` would otherwise run a bless).
      \#*)          workspace_usage_error "$(printf '%q is not a workspace; ...' "$1" "$1")" ;;
      *)
        [ "$ws_given" = 0 ] || two_workspaces "$ws_arg" "$1"
        ws_arg="$1"; ws_given=1; shift ;;
```
(excerpt ends :785; enclosing main() continues to :1013 — read; the `\#*)` line is shortened here, full text at :783)

After `--` the word is taken as the workspace with no `#` check (`ws_arg="$1"`, `cc-isolated.sh:795`). Executed: `--probe-only -- '#nope'` exits 1 with `ERROR: not a directory: #nope`, not 2 (probe.log, P7), and `--probe-only -- '#x'` on a real dir exits 0 (bats-new.log, test "a directory named '#x'…"). So "a word starting with '#' … is bad usage, exit 2" is true only before `--`; the guide says "before `--`", the header does not. The header also names only `./#x`, not the `-- '#x'` form the guide and tests give (an omission, not an error). The zsh half is confirmed under Claim 12. The second-workspace half: three modes exit 2 (bats-new.log, test "a second workspace…").

**Evidence:** `devcontainer-config/cc-isolated.sh:18-20`, `devcontainer-config/cc-isolated.sh:778-796`, probe.log (P7, P9), bats-new.log

---

## Claim 2: "The parser used to keep the LAST positional, so the note's last word became the workspace."

**Location:** `devcontainer-config/cc-isolated.sh:742-745`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Severity:** Info
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers 5e6e9266's `*)` arm overwriting `ws_arg`; does not establish anything about the old `--` path (Claim 7).

Old code: `*)            ws_arg="$1"; shift ;;` (`git show 5e6e9266:devcontainer-config/cc-isolated.sh:759`). Executed against the old tree: `--probe-only A '#' note` → `status=1`, `ERROR: not a directory: note` (probe.log, P3).

**Evidence:** `5e6e9266:devcontainer-config/cc-isolated.sh:740-761`, probe.log (P3)

---

## Claim 3: "Now a second workspace, or a word starting with '#', is a usage error raised while parsing, before any check or action runs."

**Location:** `devcontainer-config/cc-isolated.sh:745-746` (same statement in commit a54bb3b0: "while parsing and before any check or action")
**Type:** Behavioral / Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Severity:** Minor
**Legibility-target:** for-author
**Scope:** Covers ordering against the host-tool *refusal*, the devcontainer-CLI check and the `--register` write; does not establish that no check runs first, because the host-tool hash check itself runs at script load, before `main`.

The host-tool check runs at top level when the script loads, before `main "$@"`:

```bash
# devcontainer-config/cc-isolated.sh:727-734
CC_ISOLATED_DIR="$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")"
HOST_TOOLS_ERR=""
if HOST_TOOLS_ERR="$(verify_host_tools "$CC_ISOLATED_DIR" cc-exit-scan.sh cc-gitdir.sh)"; then
  # shellcheck source=cc-exit-scan.sh
  source "$CC_ISOLATED_DIR/cc-exit-scan.sh"
else
  HOST_TOOLS_ERR="${HOST_TOOLS_ERR:-host-tool check failed}"
fi
```

Only its refusal (`cc-isolated.sh:797`) comes after the parse loop. Executed: with a malformed host-tool manifest, `--probe-only A B` exits 2 with the two-workspaces message, and `--probe-only A` exits 1 with the host-tool refusal (probe.log, P4). With no `devcontainer` on PATH, `A '#' x` exits 2 and `A` exits 1 (probe.log, P5). The `--register` path writes nothing (the `assert_refused_untouched` checks, bats-new.log). Precise version: "before any refusal or action" (the comment at `:724-726` already says this correctly: "--help and usage errors are answered first").

**Evidence:** `devcontainer-config/cc-isolated.sh:727-734`, `devcontainer-config/cc-isolated.sh:761-819`, probe.log (P4, P5), bats-new.log

---

## Claim 4: "Values are printed with %q: they are untrusted text going to a terminal."

**Location:** `devcontainer-config/cc-isolated.sh:746-747`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Severity:** Info
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers both new message builders; does not cover other ERROR lines in main (e.g. `unknown flag: $1` at :779, which is unchanged and prints raw).

`two_workspaces` uses `printf 'two workspaces given: %q and %q. …'` (`:758-759`), and the `#` arm uses `printf '%q is not a workspace; …' "$1" "$1"` (`:783`). `workspace_usage_error` prints the already-quoted string with `printf 'ERROR: %s\n' "$1"` (`:750`). Executed output shows the escaping: `\# is not a workspace; … ./\#).` (assertion in bats test "a pasted '# note'…", passing in bats-new.log).

**Evidence:** `devcontainer-config/cc-isolated.sh:749-760`, `devcontainer-config/cc-isolated.sh:783`, bats-new.log

---

## Claim 5: "(cc-push's rule)" — after `--`, at most one word, and only when no workspace came before it

**Location:** `devcontainer-config/cc-isolated.sh:789-790`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Severity:** Info
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the shape of the `--` rule in both parsers; does not establish identical behaviour for an empty-string first positional (cc-push tests `-z "$start"`, cc-isolated tests a `ws_given` flag, so `'' -- B` is refused by cc-isolated and accepted by cc-push), nor the `#` refusal, which cc-push does not have.

```bash
# devcontainer-config/cc-push.sh:442-449
      *)  [ -z "$start" ] || usage_die "one checkout at a time"; start="$1"; shift ;;
    esac
  done
  # After `--`: at most one word, and only when no checkout was named before it.
  if [ $# -gt 0 ]; then
    [ $# -eq 1 ] && [ -z "$start" ] || usage_die "one checkout at a time"
    start="$1"
  fi
```
(excerpt ends :449; enclosing cc-push main continues past :472 — read to the find_checkout use at :452)

cc-isolated's post-loop block (`:791-796`) applies the same two conditions.

**Evidence:** `devcontainer-config/cc-push.sh:432-453`, `devcontainer-config/cc-isolated.sh:789-796`

---

## Claim 6a: "(`cc-isolated  # --bless` would otherwise run a bless)"

**Location:** `devcontainer-config/cc-isolated.sh:781-782`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Severity:** Info
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the old parser's behaviour on `'#' --bless`, and the new one's refusal; does not cover other flag words in a note.

Old tree, `'#' --bless`: `status=0`, `Blessed …/manifest.sha256 (8 entries)` (probe.log, P1 old). New tree: exit 2 (probe.log, P1 new).

**Evidence:** `5e6e9266:devcontainer-config/cc-isolated.sh:742-761`, probe.log (P1)

## Claim 6b: "a note's later words can never act as flags"

**Location:** `devcontainer-config/cc-isolated.sh:780-781`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Severity:** Minor
**Legibility-target:** for-author
**Scope:** True whenever the note's first word reaches the `case` as `$1`; does not hold when that word is consumed as the value of a preceding `--profile`.

`--profile` takes the next word without inspecting it: `profiles="$2"; shift 2 ;;` (`cc-isolated.sh:776`). Executed: `cc-isolated --profile '#' --bless` → `status=0`, `Blessed …` (probe.log, P8). The trigger is a copyable line ending in a bare `--profile` followed by a note; no current copyable line does that. Precise version: "…can never act as flags, unless the note's `#` is taken as `--profile`'s value."

**Evidence:** `devcontainer-config/cc-isolated.sh:767-786`, probe.log (P8)

---

## Claim 7: "It used to drop everything after `--`, opening $PWD instead."

**Location:** `devcontainer-config/cc-isolated.sh:790` (also commit a54bb3b0, and plan F2: "`cc-isolated -- ~/a` silently opened `$PWD`")
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Severity:** Info
**Legibility-target:** for-author
**Scope:** Covers the old `--) shift; break` with nothing reading `$@` afterwards; the "opening $PWD" half holds only when no workspace preceded `--`.

Old code: `--)           shift; break ;;` and no use of the remaining `$@` before `resolve_workspace "$ws_arg"` (`5e6e9266:devcontainer-config/cc-isolated.sh:757-761`). Executed on the old tree: `--probe-only -- B` from cwd A → `devcontainer up … --workspace-folder …/a` (probe.log, P2). `--probe-only B -- A` → `--workspace-folder …/b` (probe.log, P2b), so words after `--` were dropped but the earlier workspace, not `$PWD`, was opened. Precise version: "…dropped everything after `--` (opening $PWD when no workspace came before it)".

**Evidence:** `5e6e9266:devcontainer-config/cc-isolated.sh:740-761`, probe.log (P2, P2b)

---

## Claim 8a: "Each command on a line of its own, its note on the line below"

**Location:** `devcontainer-config/install.sh:610`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Severity:** Minor
**Legibility-target:** for-author
**Scope:** Covers the order of note and command lines in the echo block; does not cover other printed text in install.sh.

Each note is printed above its command:

```bash
# devcontainer-config/install.sh:614-618
  echo "Next steps (copy the command lines only):"
  echo "  Once, if you haven't; it strengthens the H1 probe:"
  echo "    touch ~/.ssh/canary"
  echo "  REQUIRED after any boundary change: recreate the container from this config,"
  echo "  probe it, and record it verified live on a pass:"
```
(excerpt ends :618; the block continues the same pattern to :625 — read)

The commit message says it correctly ("with its note above it"). Fix: "its note on the line above".

**Evidence:** `devcontainer-config/install.sh:608-629`

## Claim 8b: "a pasted line carrying a trailing '# note' reaches the command as extra words in zsh (no interactive_comments by default), and cc-isolated refuses those (exit 2)"

**Location:** `devcontainer-config/install.sh:611-612`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Severity:** Info
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers zsh 5.9 with `-f` (no rc files) and cc-isolated's refusal; does not cover the `touch` and `cc-push` lines in the same block (cc-push would reject a note as a second checkout, not as a `#` word).

zsh probe: `[a][#][note][--bless]` without the option, `[a]` after `setopt interactive_comments` (zsh-probe.log). Refusal: Claims 1 and 6a.

**Evidence:** `devcontainer-config/install.sh:610-612`, zsh-probe.log, probe.log (P1 new)

---

## Claim 9: "REQUIRED after any boundary change: recreate the container from this config, probe it, and record it verified live on a pass"

**Location:** `devcontainer-config/install.sh:617-619`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Severity:** Info
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers `--probe-only`'s always-recreate path and its record on a pass; does not establish the probe's own correctness.

```bash
# devcontainer-config/cc-isolated.sh:925-930
  if [ "$action" = "probe" ]; then
    # --probe-only is the verification command, so it always recreates: probing a
    # container left over from an earlier config would verify the wrong boundary.
    devcontainer up --remove-existing-container "${dc[@]}"
    probe_boundary "$ws"
    exit 0
```
(excerpt ends :930; main continues to :1013 — read)

`probe_boundary` calls `record_verified_live` after zero failures (`cc-isolated.sh:715`). Stub log shows `devcontainer up --remove-existing-container --workspace-folder …` (probe.log, P2).

**Evidence:** `devcontainer-config/cc-isolated.sh:925-930`, `devcontainer-config/cc-isolated.sh:709-718`, probe.log

---

## Claim 10: "`cc-push` takes one checkout … and `cc-isolated` one workspace, under the same rule. `cc-isolated` also refuses a word starting with `#` before `--`."

**Location:** `guides/cc-isolated-usage.md:38-41`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Severity:** Info
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the second-positional and `--` rules and the "before `--`" qualifier; does not establish identical empty-string handling (see Claim 5).

Rule shape: Claim 5. "before `--`" is the correct qualifier (probe.log, P7). Refusal of `A B`, `A -- B`, `-- A B`: bats-new.log.

**Evidence:** `guides/cc-isolated-usage.md:38-44`, `devcontainer-config/cc-isolated.sh:778-796`, bats-new.log, probe.log (P7)

---

## Claim 11: "interactive zsh passes the note as arguments unless `setopt interactive_comments` is on"

**Location:** `guides/cc-isolated-usage.md:41-42` (same fact at cc-isolated.sh:18-19 and :742-743)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Severity:** Info
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers zsh 5.9 started with `-f -i` (default options); does not cover a user's rc files, which may set the option.

zsh-probe.log: `printf "[%s]" a # note --bless` printed `[a][#][note][--bless]`; after `setopt interactive_comments` the same form printed `[a]`.

**Evidence:** zsh-probe.log

---

## Claim 12: "the launcher used to take the note's last word as the workspace; now the line exits 2 and names the values"

**Location:** `guides/cc-isolated-usage.md:42-43`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Severity:** Info
**Legibility-target:** for-author
**Scope:** Covers exit 2 for a pasted note before `--`; "names the values" holds in full only for the two-workspaces message.

The old half is Claim 2. For a pasted note (`A '#' note`) the refusal fires at the `#` word and names only that word (`\# is not a workspace; …`, bats-new.log), not the workspace or the rest of the note. Both values are named only when the error is "two workspaces given" (e.g. `A B`). Precise version: "now the line exits 2 and names the offending word".

**Evidence:** `devcontainer-config/cc-isolated.sh:783`, `devcontainer-config/cc-isolated.sh:758-760`, bats-new.log

---

## Claim 13: "A directory whose name starts with `#` is `./#name` or `-- '#name'`."

**Location:** `guides/cc-isolated-usage.md:43-44`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Severity:** Info
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers both forms with `--probe-only` and no earlier workspace; `-- '#name'` after a workspace is refused as a second workspace.

bats test "a directory named '#x' is still reachable as ./#x and after --" passes (bats-new.log) and fails on 5e6e9266 (newtests-on-old.log).

**Evidence:** `test/cc-isolated-functions.bats:446-456`, bats-new.log, newtests-on-old.log

---

## Claim 14: Test block header: "Each refusal must come before any devcontainer call and before --register writes anything."

**Location:** `test/cc-isolated-functions.bats:383-387`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Severity:** Info
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers what `assert_refused_untouched` asserts; it does not assert an empty stdout, nor that the host-tool hash check did not run (it does run, at load; Claim 3).

```bash
# test/cc-isolated-functions.bats:398-404
assert_refused_untouched() {
  [ "$status" -eq 2 ]
  [[ "$output" == *"EXIT STATUS"* ]]
  [ ! -s "$DC_LOG" ]
  [ -z "$(project_profile "$TEST_TMPDIR/a")" ]
  [ -z "$(project_profile "$TEST_TMPDIR/b")" ]
}
```

**Evidence:** `test/cc-isolated-functions.bats:383-404`, bats-new.log

---

## Claim 15: The five new test names assert what they say

**Location:** `test/cc-isolated-functions.bats:406-471`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Severity:** Info
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each name against its body and its pass at HEAD / fail at 5e6e9266; "in every mode that takes one" covers launch, `--probe-only` and `--register` (the modes the plan lists), not `--bless`/`--list` (which also refuse two positionals, probe.log P6); the install.sh test greps install.sh's source lines, not the printed output (equivalent here, since every line is a literal `echo`); the `#` test names `--bless` in a comment but exercises `--register` and `--probe-only`.

- "a second workspace is a usage error in every mode that takes one, naming both": loops `"" --probe-only "--register --profile python"`, asserts exit 2, untouched, both values (`:406-416`).
- "a pasted '# note' is refused at its first word, before its later words act as flags": `A '#' note`, `'#' --register A --profile python` (old code would register A, which the profile assertion catches), `--probe-only '#widen' B` (`:419-431`).
- "after --: one workspace, and only when none came before it": `A -- B`, `-- A B` refused, `-- B` probes B (`:433-445`).
- "a directory named '#x' …": Claim 13.
- "install.sh's Next steps print no command line carrying a trailing '# note'": 5 command lines, no `#` in any echo line of the block, no "rebuild" (`:458-471`).

All five pass at HEAD (bats-new.log); all five fail on 5e6e9266 (newtests-on-old.log: failures at `assert_refused_untouched` ×3, `[ "$status" -eq 0 ]`, `[ "${#lines[@]}" -eq 5 ]`).

**Evidence:** `test/cc-isolated-functions.bats:406-471`, bats-new.log, newtests-on-old.log

---

## Claim 16: Plan audit: "Callers that pass positionals: install.sh "Next steps" …, `rebuild_hint` …, the unregistered NOTE …, init-firewall.sh's hint, the guides …, `test/cc-isolated-functions.bats` …, `hooks/live-verify-gate.sh` messages (one). None passes two."

**Location:** `docs/working/plan-2026-10-15-cc-isolated-one-workspace.md` ("Argument grammar audit")
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Severity:** Info
**Legibility-target:** for-author
**Scope:** Covers each listed caller's command part; does not cover the documents' trailing notes: copyable lines in guides that still carry `# …` notes (`guides/devcontainer-setup.md:48,79,80,114,153,174`; `guides/cc-isolated-usage.md:21-23` command reference) now exit 2 if pasted with the note into default zsh. That is the intended behaviour, and the new guide paragraph tells readers to copy only the command.

Callers read: `rebuild_hint` prints `cc-isolated --probe-only $(printf '%q' "$ws") && cc-isolated $(printf '%q' "$ws")` (`cc-isolated.sh:572`, one per command); the NOTE prints `cc-isolated --register '$ws' --profile $suggestion` (`:853`); init-firewall prints `cc-isolated --probe-only <repo>` / `cc-isolated <repo>` (`init-firewall.sh:354-355`); live-verify-gate prints `cc-isolated --probe-only <repo>` (`hooks/live-verify-gate.sh:191,194`); cc-isolated's own `Next:` lines (`:321`, `:493`) carry one each; cc-push prints only `cc-isolated --bless` (`cc-push.sh:209`). All 340 tests in the three suites pass at HEAD under `LC_ALL=C.UTF-8` (head-cutf8.log), so no existing test relied on two positionals. (Search via `rg -e 'cc-isolated(\.sh)?\S* +[^ |&;#)]'` over devcontainer-config, guides, hooks, test and README.md — paraphrased — no quote available because the result was 100 lines, most of them prose mentions of the name.)

**Evidence:** `devcontainer-config/cc-isolated.sh:321`, `devcontainer-config/cc-isolated.sh:493`, `devcontainer-config/cc-isolated.sh:572`, `devcontainer-config/cc-isolated.sh:853`, `devcontainer-config/init-firewall.sh:354-355`, `hooks/live-verify-gate.sh:191-194`, `devcontainer-config/cc-push.sh:209`, head-cutf8.log

---

## Claim 17: Plan F5: "A note word consumed as a flag value (`--profile # x`) … **Covered already**: `register_project` rejects an unknown profile; `x` is then a second positional anyway"

**Location:** `docs/working/plan-2026-10-15-cc-isolated-one-workspace.md` (pre-mortem table, row F5)
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Severity:** Minor
**Legibility-target:** for-author
**Scope:** Covers `--profile '#'` followed by a flag, and by a word with no earlier workspace; does not suggest any current copyable line triggers it (none ends in a bare `--profile`).

`register_project`'s profile check (`cc-isolated.sh:445-454`) runs only in register mode, after resolve_workspace. Outside register mode, nothing validates `profiles`. Executed: `--profile '#' --bless` → `status=0`, `Blessed …` (probe.log, P8), so the note's `--bless` runs. `--probe-only --profile '#' B` → exit 0, probing B (probe2.log, F5a), so `x` is the first positional, not "a second positional anyway". F5 holds only when a workspace came first (`--register A --profile '#' python` → exit 2, probe2.log F5b). The same gap is the residue of Claim 6b.

**Evidence:** `devcontainer-config/cc-isolated.sh:440-454`, `devcontainer-config/cc-isolated.sh:768-776`, probe.log (P8), probe2.log

---

## Claim 18: Plan F7: "**Covered**: the parse loop runs before both [the host-tool refusal and the devcontainer check]; usage errors answer first"

**Location:** `docs/working/plan-2026-10-15-cc-isolated-one-workspace.md` (pre-mortem table, row F7)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Severity:** Info
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the two refusals F7 names; the host-tool hash check itself runs earlier, at load (Claim 3).

probe.log P4 and P5 (see Claim 3).

**Evidence:** `devcontainer-config/cc-isolated.sh:761-819`, probe.log (P4, P5)

---

## Claim 19: Commit a54bb3b0: "--bless/--list still ignore a single stray positional."

**Location:** commit a54bb3b0 message, Notes
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Severity:** Info
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers one positional with `--list` (executed) and `--bless` (static: `bless) bless_manifest; exit 0 ;;` never reads `ws_arg`, `cc-isolated.sh:822`); two positionals are refused in both modes (probe.log, P6).

`--list A` → exit 0; `--bless A B` and `--list A B` → exit 2 (probe.log, P6).

**Evidence:** `devcontainer-config/cc-isolated.sh:821-824`, probe.log (P6)

---

## Claim 20: Commit a54bb3b0 Live-verified trailer: "no — argument parsing and install.sh's printed text only, checked by bats with a stubbed devcontainer CLI; the sandbox has no Docker. blessed_hash changes on the next install.sh: run cc-isolated --probe-only <repo> after install.sh"

**Location:** commit a54bb3b0 message, trailer
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Severity:** Info
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the gate's trailer requirement for this diff, the hash change and the no-Docker claim; does not establish anything about a live probe, which has not run.

`cc-isolated.sh` and `install.sh` match the gate's enforcement regex (`hooks/live-verify-gate.sh:83`), and the diff is not comment-only, so `Live-verified` is required. No host tool (`cc-exit-scan.sh|cc-gitdir.sh|cc-push.sh`, `:91`) is touched, so `Host-tool-tested` is not. `blessed_hash` is `sha256sum < "$m" | cut -c1-16` of the manifest (`cc-isolated.sh:93-98`), and the manifest hashes `cc-isolated.sh` (probe.log P1 shows a `cc-isolated.sh` entry), so the next install changes it. The sandbox has no Docker: `command -v docker` printed nothing and `/var/run/docker.sock` does not exist (paraphrased — no quote available because the evidence is an absent command and an absent file).

**Evidence:** `hooks/live-verify-gate.sh:80-94`, `hooks/live-verify-gate.sh:160-164`, `devcontainer-config/cc-isolated.sh:93-98`, probe.log (P1)

---

## Claim 21: Commit a54bb3b0: "Four reds in the related suites are pre-existing and locale-dependent (they fail on 5e6e9266 too, pass under LC_ALL=C.UTF-8)."

**Location:** commit a54bb3b0 message, Notes
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Severity:** Minor
**Legibility-target:** for-author
**Scope:** Covers cc-isolated-functions.bats, cc-push.bats and install-host.bats (the commit does not name its "related suites"); does not establish which suites the author ran, so the count may match a narrower set.

Mechanism and conclusion hold; the count does not, for these three suites. Under the default locale (en_US.UTF-8, which is not installed: `setlocale: LC_ALL: cannot change locale`) HEAD has **six** reds: cc-isolated-functions 3 ("a repository already planted at the checkout root…", "HEAD over 255 bytes…", "exit scan Q-094: a new worktree in git's standard layout…"), cc-push 2 ("gitdir_valid and gitdir_head_kind…", "err_vis: only stderr…"), install-host 1 ("T3 --yes without a TTY…"). All six also fail serially (head-serial-reds.log, so not a `-j 4` artifact), and all six fail on the 5e6e9266 tree (base-default.log, which has two more reds, T9 and T89, probably because a `git archive` tree is not a git checkout). With `LC_ALL=C.UTF-8`, all 340 pass at HEAD (head-cutf8.log). Matches the logged hallucination-pattern class: a test count claimed in a commit message differs from the run. Precise version: "Six reds in cc-isolated-functions/cc-push/install-host…", or name the suites counted.

**Evidence:** head-default.log, head-serial-reds.log, head-cutf8.log, base-default.log

---

## Claim 22: init-firewall.sh: "interactive zsh without interactivecomments passes those words to cc-isolated as arguments, and the last positional becomes the workspace."

**Location:** `devcontainer-config/init-firewall.sh:347-349` (not in the diff; describes the behaviour this diff changes)
**Type:** Staleness / Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Severity:** Minor
**Legibility-target:** for-author
**Scope:** Covers the comment's description of cc-isolated's parser; the comment's reason for keeping notes off the command lines still holds (a note is now refused instead of misread).

At a54bb3b0 the last positional no longer becomes the workspace: a second positional or a `#` word exits 2 (bats-new.log; Claims 1-3). This is the only remaining "last positional" description outside the new comment, which uses the past tense (`rg 'last positional|LAST positional|last word'` over devcontainer-config, guides, hooks, docs/decisions: three hits — cc-isolated.sh:745 and guides/cc-isolated-usage.md:43, both past tense, and this one — paraphrased — no quote available because the evidence is a three-hit search result). init-firewall.sh is an enforcement file, but a comment-only edit passes the gate's comment-only escape (`hooks/live-verify-gate.sh:98-156`). Precise version: "…passes those words to cc-isolated as arguments, which refuses them (exit 2); before 2026-10-15 the last one became the workspace."

**Evidence:** `devcontainer-config/init-firewall.sh:343-355`, `devcontainer-config/cc-isolated.sh:742-746`, bats-new.log

---

## Claims Requiring Attention

### Incorrect
- **Claim 8a** (`devcontainer-config/install.sh:610`): the comment says each note is "on the line below"; install.sh prints it above. Change it to "above".
- **Claim 17** (plan F5): "Covered already" fails outside `--register`: `--profile '#' --bless` runs a bless (exit 0), and `--profile '#' x` with no earlier workspace opens x. No current copyable line triggers it. Either correct the row, or make the `#` check also reject a `--profile` value starting with `#`.

### Stale
- **Claim 22** (`devcontainer-config/init-firewall.sh:349`): says the last positional becomes the workspace; it is now refused with exit 2. A comment-only edit passes the gate's comment-only escape.

### Mostly Accurate
- **Claim 1** (`cc-isolated.sh:18-20`, --help header): the `#` rule applies only before `--` (`-- '#x'` is accepted); also mention the `-- '#x'` form.
- **Claim 3** (`cc-isolated.sh:745-746`, and the commit message): "before any check" is too strong, because the host-tool hash check runs at load; say "before any refusal or action".
- **Claim 6b** (`cc-isolated.sh:780-781`): "never act as flags" has one exception, a note after a bare `--profile` (same gap as Claim 17).
- **Claim 7** (`cc-isolated.sh:790`, commit, plan F2): `$PWD` was opened only when no workspace came before `--`.
- **Claim 12** (`guides/cc-isolated-usage.md:43`): for a pasted note the error names only the `#` word, not "the values".
- **Claim 21** (commit a54bb3b0): six locale reds, not four, in cc-isolated-functions, cc-push and install-host (all pre-existing, all pass under C.UTF-8). Name the suites or fix the count.

### Unverifiable
- None.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the output path named in your tail, structured per your skill, every finding with Severity, Location, verbatim Evidence, Confidence and Legibility-target.
- Answered: yes. All eight tail items were checked, by execution where possible (stubbed devcontainer; old code via `git archive 5e6e9266`), plus one out-of-diff stale comment (init-firewall.sh:349) and the plan's F5/F7 rows.
- Out of scope: code quality and whether to close the `--profile '#'` gap (a code-review/security call); the guides' remaining `# …`-annotated copyable lines (their command parts were audited, but whether they should lose their notes is a design call); not appending to hallucination-patterns.md (no fabrication, and the brief forbids editing other repo files).
- Escalate: Claim 17 / 6b (`--profile '#' --bless` still runs a bless) is a small hole in the "# note can never act as flags" property that F3 set out to close. The security critic should decide whether it matters.
