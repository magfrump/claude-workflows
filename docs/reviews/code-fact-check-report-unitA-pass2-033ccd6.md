**Commit:** 033ccd6
**Replication:** k=1 (loop pass, decision 031)

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-hook-a (claude-workflows), branch feat/hook-refuse-redirects
**Scope:** `git diff main...HEAD` at 033ccd6 — hooks/auto-approve-allowed-commands.sh, test/auto-approve-allowed-commands.bats, docs/decisions/log.md row 64, docs/working/questions.md (Q-095, Q-097; Q-093/Q-094/Q-096 text from commit 0a6cbdc is another session's and was read as context only), commit messages main..HEAD (4dff0e9 and f05043f were checked in pass 1 and are re-checked here only where a pass-1 Incorrect claim sits in them), plus a resolution check of the 9 Incorrect claims in docs/reviews/code-fact-check-report-unitA-pass1-f05043f.md
**Checked:** 2026-09-28
**Total claims checked:** 45
**Summary:** 35 verified, 4 mostly accurate, 2 stale, 3 incorrect, 1 unverifiable

Execution logs (all under `/tmp/claude-1000/-workspace/aef7a10c-6785-42b5-b88a-f42ac33780a8/scratchpad/fcA2/`, abbreviated `$FC/` below; every script exited 0; each log carries its own UTC timestamp line; cwd for suites was the worktree, for probes `$FC`):

| Log | Command | What it records |
|---|---|---|
| `$FC/probes1.txt` | `SCR=$FC bash harness.sh probes1.bin` (2026-09-29T04:13:01Z) | pass-1 families + arithmetic-subscript builtins, hook decision and, if approved, real bash run with marker files |
| `$FC/probes2.txt` | `SCR=$FC bash harness.sh probes2.bin <allow>` (04:13:40Z) | builtins that run arguments as code, quoting tricks |
| `$FC/probes3.txt` | `bash harness.sh probes3.bin '["Bash(ls:*)"]'` + shfmt Op dump (04:19:41Z) | fd-dup / `/dev/null` redirect edges; `Op` of `>` |
| `$FC/locale-probe.txt` | `bash locale-probe.sh` (04:14:44Z) | redirect slicing under `C` and `C.UTF-8` |
| `$FC/ast-probe.txt` | inline shfmt/jq (04:18:02Z) | node types, Type-less objects, jq 1.6 `contains("\u0000")` |
| `$FC/suites-hooks.txt` | `bash run-suites.sh` = `bats test/hooks/*.bats test/auto-approve-allowed-commands.bats test/link-claude-home-wiring.bats` (HEAD 033ccd6) | `1..235`, 235 ok, `# exit=0` |
| `$FC/vacuity.txt` | `bash vacuity.sh` (04:17:23Z) | refusal reason for every must-prompt test item |
| `$FC/vacuity2.txt` | `bash vacuity2.sh` | same items against a copy of the hook with main's `REFUSE_CONSTRUCTS=true` flipped to `false` |
| `$FC/leak-probe.txt` | `bash leak-probe.sh` (04:19:04Z) | Q-097 leak list: HEAD hook + feat/wiring-allowlist-b's 778 allow / deny rules (decision only, nothing run); guard-trusted-writes.py on `--output` |
| `$FC/gitexec.txt` | `bash gitexec.sh` (04:21:39Z) | scratch repo: fsmonitor / diff.external / textconv; `man -l`, `date -f` |

No claim matches a pattern in `docs/reviews/hallucination-patterns.md` (5 logged patterns, all test-count or corpus-number fabrications in other files).

---

## Claim 1: "The auto-approve hook approves only an allowlist of AST shapes; anything else falls through to the normal prompt. Approvable: node types `File`, `CallExpr`, `BinaryCmd` …, `Lit`, `SglQuoted`, `DblQuoted`, and a plain `$NAME`/`${NAME}`/`${#NAME}`; statements not backgrounded; simple commands with no `VAR=` assignment, a literal command name, and not an interpreter or wrapper (…); redirects that neither write nor read a path"

**Location:** `docs/decisions/log.md:87`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the AST-shape gate (node types, ParamExp form, background, assignments, command-name literalness and the named wrapper set, redirect targets) for every probed shape; does not establish that an approved shape runs only the named commands — a builtin named in an allow rule can still evaluate its arguments as code (Claims 7b, 26).

The filter walks every typed node and names the first disallowed one:

```
# hooks/auto-approve-allowed-commands.sh:693-696
[ .. | objects
  | if has("Type") then
      if (.Type | IN("File","CallExpr","BinaryCmd","Lit","SglQuoted","DblQuoted","ParamExp") | not)
        then "node type \(.Type)"
```

Every construct family probed was refused by that gate with the matching reason (`$FC/vacuity.txt`: `Refusing: node type LetClause`, `TestClause`, `ArithmExp`, `DeclClause`, `CmdSubst`, `ProcSubst`, `Subshell`, `Block`, `IfClause`, `ForClause`, `WhileClause`, `CaseClause`, `FuncDecl`, `TimeClause`, `CoprocClause`; `background statement`; `assignment`; `parameter expansion with an operator`; `non-literal command name`), and `$FC/probes1.txt` shows all four pass-1 approved-and-executed families now `hook=prompt`. Objects without a `Type` key are only Stmt, Word, Redirect, Pos and the `Param` Lit (`$FC/ast-probe.txt`: `[["Cmd","End","Pos","Position"],…,["End","Parts","Pos"],…]`), so no code-bearing node escapes the `has("Type")` test.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:678-710`, `hooks/auto-approve-allowed-commands.sh:786-810`, `$FC/vacuity.txt`, `$FC/probes1.txt`, `$FC/ast-probe.txt`

---

## Claim 2: "A command that extracts to no commands is no longer approved."

**Location:** `docs/decisions/log.md:87`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers main's empty-extraction branch; does not establish anything about the empty-string input, which exits even earlier (`No command found`).

```
# hooks/auto-approve-allowed-commands.sh:437-440
  if [[ ${#extracted_commands[@]} -eq 0 ]] || [[ -z "${extracted_commands[0]}" ]]; then
    debug "No commands found in input; falling through to normal permission check"
    exit 0
  fi
```

No `allow` is printed on that path. `' '` and `'# just a comment'` hit it and are not approved (`$FC/vacuity.txt`: `prompt | \  | [DEBUG] No commands found in input; falling through…`).

**Evidence:** `hooks/auto-approve-allowed-commands.sh:436-440`, `$FC/vacuity.txt`

---

## Claim 3: "Cost: compound one-liners (`$(…)`, `$((…))`, `[[ ]]`, loops, `export`) prompt."

**Location:** `docs/decisions/log.md:87`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the five named forms with every inner command allow-listed; does not establish user-facing prompt frequency.

`$FC/vacuity.txt` (SHAPE_RULES allow `ls`, `wc`, `echo`, …): `ls $(pwd)` → `node type CmdSubst`; `ls $((1 + 2))` → `ArithmExp`; `[[ … ]]` → `TestClause`; `for i in 1; do ls; done` → `ForClause`; `export PATH=/x:$PATH; ls` → `DeclClause`; all `prompt`.

**Evidence:** `$FC/vacuity.txt`

---

## Claim 4: "Row 53 accepted four extraction gaps."

**Location:** `docs/decisions/log.md:87`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers row 53's text; does not re-verify the row-53 reproductions themselves.

```
# docs/decisions/log.md:76 (row 53)
Four constructs the filter does not descend into still get `allow` on the outer command alone (reproduced): arithmetic expansion (`echo $((1 + $(cmd)))`), heredoc bodies, `VAR=` assignment prefixes (`PATH=`, `LD_PRELOAD=`), and redirect targets (`ls > ~/.bashrc`).
```

**Evidence:** `docs/decisions/log.md:76`

---

## Claim 5: "They were survivable in cc-isolated only because most projects had no allowed command to hang them on; a global allow list in `hooks/wiring.json` gives one to every project."

**Location:** `docs/decisions/log.md:87`
**Type:** Configuration / Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers whether `hooks/wiring.json` carries a global allow list at 033ccd6; does not dispute that such a list motivated the unit or that the shape gate protects projects' own allow rules.

`hooks/wiring.json` at HEAD (and at 51bbfb6, where row 64 was written) has only a deny list: `jq '.permissions | keys' hooks/wiring.json` → `["deny"]` (paraphrased — no quote available because the output was captured to the terminal only; command re-runnable as given). The list lived on `feat/wiring-allowlist` (857 rules) and `feat/wiring-allowlist-b` (778 rules), and this unit's own last commit shelved it:

```
# docs/working/questions.md (Q-097)
**Interim:** no global allow list. cc-isolated sessions prompt for commands not in their project's `.claude/settings.json`.
```

The present-tense "gives one to every project" was the plan when written; after Q-097 the rationale should say the unit protects each project's own allow rules and would be needed again when a global list ships.

**Evidence:** `docs/decisions/log.md:87`, `hooks/wiring.json`, `docs/working/questions.md:189-201`

---

## Claim 6: "Two rounds tried listing bad constructs … and each review round's fact-check, run against the hook, found a new family: `let 'a[$(cmd)]=1'` via the old "no commands found, allowing" branch, `export PATH=…`, escaped backticks and `$'\x3e'` inside `bash -c`, `tr -d x < ~/.claude/.c*`."

**Location:** `docs/decisions/log.md:87`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the attribution of each family to a committed fact-check report; does not re-execute the pre-fix hooks.

Pass 1 of this unit records the first four (`docs/reviews/code-fact-check-report-unitA-pass1-f05043f.md`, Claim 1a: `hook=ALLOW | cmd: let 'a[$(touch M_let)]=1'`; Claim 1b: `export PATH=$PWD/evil:$PATH; ls`; Claim 1c: `bash -c $'ls \x3e M_ansi'`), and the unit-B report on `feat/wiring-allowlist-b` records the fifth:

```
# feat/wiring-allowlist-b:docs/reviews/code-fact-check-report-wiring-pass2-e511a14.md:213
APPROVED | tr -d x < ~/.claude/.c*
```

**Evidence:** `docs/reviews/code-fact-check-report-unitA-pass1-f05043f.md:29-110`, `feat/wiring-allowlist-b:docs/reviews/code-fact-check-report-wiring-pass2-e511a14.md:39,213`

---

## Claim 7a: "an unknown construct prompts."

**Location:** `docs/decisions/log.md:87`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers AST node types not in the allowlist (any such type yields `node type X`); does not cover code execution reached through an allowed CallExpr's arguments (Claim 7b).

The test is membership in a fixed list (`IN("File",…,"ParamExp") | not` → `"node type \(.Type)"`, `hooks/auto-approve-allowed-commands.sh:695-696`), so an unlisted type is refused by construction. Probed types never named in the tests were also refused, e.g. `echo $[1+1]` → `Refusing: node type ArithmExp` (`$FC/probes2.txt`).

**Evidence:** `hooks/auto-approve-allowed-commands.sh:694-698`, `$FC/probes2.txt`

---

## Claim 7b: "An allowlist of shapes converges where a denylist did not"

**Location:** `docs/decisions/log.md:87`
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers whether the same code-execution family the row lists (`let 'a[$(cmd)]=1'`: bash arithmetic evaluating a quoted array subscript) is closed for plausibly allow-listed commands; does not establish Claude Code's own engine outcome, and does not cover git/tool flags (the commit's acknowledged residual).

The row cites `let 'a[$(cmd)]=1'` as a family that proved the denylist did not converge. The same mechanism is reachable through builtins whose argument is a variable name; each is a CallExpr with a SglQuoted argument, so it is an approvable shape, and bash evaluates the subscript. Approved and executed (`$FC/probes1.txt`, marker file created by real bash):

```
hook=ALLOW  | read\ \'a\[\$\(touch\ M_read\)\]\'\ \<\<\<\ 1 | created: ./M_read
hook=ALLOW  | printf\ -v\ \'a\[\$\(touch\ M_printfv\)\]\'\ x | created: ./M_printfv
hook=ALLOW  | test\ -v\ \'a\[\$\(touch\ M_testv\)\]\' | created: ./M_testv
hook=ALLOW  | \[\ -v\ \'a\[\$\(touch\ M_bracketv\)\]\'\ \] | created: ./M_bracketv
```

`read` is in the unit's own test allow list (`SHAPE_RULES`, `test/auto-approve-allowed-commands.bats:472`), and with `feat/wiring-allowlist-b`'s 778-rule list `read 'a[$(id)]' <<< 1` and `test -v 'a[$(id)]'` are approved by the HEAD hook (`$FC/leak-probe.txt`). Builtins that take a code string are a second route (`mapfile -C`, `compgen -C`, Claim 26). So "converges" is refuted for the row's own example family: the allowlist converges on *constructs* (Claim 7a), not on code execution with an allowed command. The precise version would scope the claim to AST constructs and name builtin-argument evaluation as a residual alongside the git-flag one.

**Evidence:** `docs/decisions/log.md:87`, `hooks/auto-approve-allowed-commands.sh:699-706`, `test/auto-approve-allowed-commands.bats:472`, `$FC/probes1.txt`, `$FC/leak-probe.txt`

---

## Claim 8: "Redirect operators are read from source text at shfmt's byte offsets, not its numeric `Op` code (no stability promise)."

**Location:** `docs/decisions/log.md:87`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the implementation (offset slicing, not `Op`); does not establish shfmt's stability policy, which was not consulted.

```
# hooks/auto-approve-allowed-commands.sh:794-798
  while read -r op_off word_off word_end; do
    op=${cmd:op_off:word_off-op_off}
    op=${op//[[:space:]]/}
    word=${cmd:word_off:word_end-word_off}
```

The offsets come from `"\(.OpPos.Offset) \(.Word.Pos.Offset) \(.Word.End.Offset)"` (`:813-814`); `.Op` is never read in `refuses_construct`. Under both `C` and `C.UTF-8`, multibyte prefixes slice correctly (`$FC/locale-probe.txt`: `[C.UTF-8] prompt | ls ééééé >a/dev/nul | … Refusing redirect: '>' 'a/dev/nul'`).

**Evidence:** `hooks/auto-approve-allowed-commands.sh:786-818`, `$FC/locale-probe.txt`

---

## Claim 9: "User chose each step (redirects → nested exec → safe shapes)."

**Location:** `docs/decisions/log.md:87`
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers whether a repo artifact records each choice; does not establish the conversation itself.

The commits record it as user choice (f05043f `Notes:` "with the user's explicit choice after the probe results"; 51bbfb6 `Notes:` "the allowlist is the user's choice after the class-based fix leaked"), but no answered `Q-NNN` entry records the three choices (paraphrased — no quote available because the claim is about the absence of a questions entry; `grep -n "safe shapes\|nested exec" docs/working/questions.md` finds none). Would need the session transcript.

**Evidence:** `docs/working/questions.md`, commits f05043f and 51bbfb6

---

## Claim 10: "Branch `feat/wiring-allowlist` (5d929dd) adds the host's 857-rule allow list … The unit is 915 changed code lines"

**Location:** `docs/working/questions.md:159-178` (Q-095)
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the rule count and 5d929dd's own numstat; does not establish that the list is a verbatim host copy.

`git show 5d929dd:hooks/wiring.json | jq '.permissions.allow|length'` → `857`; `git diff --numstat 5d929dd~1 5d929dd` → `870 1 hooks/wiring.json`, `15 0 test/…`, `26 3 test/…`, total `915` (paraphrased — no quote available because captured to the terminal only; commands re-runnable as given).

**Evidence:** `docs/working/questions.md:159-178`, commit 5d929dd

---

## Claim 11: "the review stopped at the fact-check gate. The list auto-approved credentials reads and config-volume writes. … harden the hook first (now `feat/hook-refuse-redirects`, decision log 64)"

**Location:** `docs/working/questions.md:164` (Q-095, Superseded)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the gate stop and the branch name; does not re-probe the 857-rule list.

e511a14's message: "Pass 1 on 5094b99 stopped at the Fact-Check Gate (user: fix first). … found credentials glob reads and config-volume writes auto-approved". `git branch --show-current` in this worktree prints `feat/hook-refuse-redirects`, and row 64 is at `docs/decisions/log.md:87`.

**Evidence:** commit e511a14, `docs/decisions/log.md:87`

---

## Claim 12: "Branch `feat/wiring-allowlist-b` holds the 778-rule list, its tests and two review passes."

**Location:** `docs/working/questions.md:192` (Q-097)
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the count and the two review commits; does not assess those reviews.

`git show feat/wiring-allowlist-b:hooks/wiring.json | jq '.permissions.allow|length'` → `778`; `git log main..feat/wiring-allowlist-b` lists `e511a14 docs(reviews): wiring allow list review pass 1 …` and `4b6da9f docs(reviews): wiring allow list pass 2 fact-check …` (paraphrased — no quote available because captured to the terminal only).

**Evidence:** `feat/wiring-allowlist-b:hooks/wiring.json`, commits e511a14, 4b6da9f

---

## Claim 13: "**Read:** `docs/reviews/code-fact-check-report-wiring-pass1-5094b99.md` (on that branch) · the unit-B pass-2 fact-check (below)"

**Location:** `docs/working/questions.md:194` (Q-097)
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers whether both references resolve; does not assess the reports.

The first path exists on the branch (`git ls-tree` lists `docs/reviews/code-fact-check-report-wiring-pass1-5094b99.md`). The second has no path and "(below)" points at nothing in the entry; the report is `docs/reviews/code-fact-check-report-wiring-pass2-e511a14.md` on `feat/wiring-allowlist-b`. Commit 51bbfb6 calls the same report "Unit B's pass-1 fact-check" (Claim 35), so the two names disagree. Precise version: cite the pass-2 file path.

**Evidence:** `docs/working/questions.md:194`, `feat/wiring-allowlist-b:docs/reviews/code-fact-check-report-wiring-pass2-e511a14.md`

---

## Claim 14: "Each item was approved with no prompt by the 778-rule list and the shape-checked hook …: `git diff --no-index /dev/null ~/.claude/.c*` reads the credentials file; `git log -1 --format=%B --output=/home/node/.claude/settings.json` writes the config volume (`guard-trusted-writes.py` does not catch `--output`)"

**Location:** `docs/working/questions.md:195-197` (Q-097)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the HEAD hook's decision with the branch's allow and deny lists and the guard's decision; does not execute either command against the real config volume (decision only), and does not establish Claude Code's engine outcome.

```
# $FC/leak-probe.txt
hook=ALLOW | git diff --no-index /dev/null ~/.claude/.c*
hook=ALLOW | git log -1 --format=%B --output=/home/node/.claude/settings.json
## guard-trusted-writes.py on the --output write (decision only)
guard output: exit=0
```

The guard printed nothing and exited 0, its "no opinion" form per `hooks/guard-trusted-writes.py:66` ("For "no opinion", exit 0 with NO output").

**Evidence:** `$FC/leak-probe.txt`, `hooks/guard-trusted-writes.py:66`

---

## Claim 15: "`git status`, `git diff`, `git log -p` and `git show` run `core.fsmonitor`, `diff.external` and textconv drivers from repo config the agent can edit"

**Location:** `docs/working/questions.md:198` (Q-097)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each driver with at least one listed command in git 2.39.5; does not establish that `git log -p` runs `diff.external` without `--ext-diff` (it does not; it does run textconv).

```
# $FC/gitexec.txt
git status   -> 1 M_fsmonitor
git diff     -> 1 M_diffext
git log -p (no --ext-diff) -> 0
git show     -> 1 M_textconv
git log -p   -> 1 M_textconv
```

**Evidence:** `$FC/gitexec.txt`

---

## Claim 16: "`man -l <file>` reads a file. `date -f <file>` probably does too (not probed)."

**Location:** `docs/working/questions.md:199` (Q-097)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers content disclosure to stdout/stderr for a one-line file; does not establish multi-line or binary files.

`$FC/gitexec.txt`: `man -l      -> 1 lines with SECRET-LINE`, `date -f     -> 1 lines with SECRET-LINE` (date's "invalid date" error echoes the line). Both are approved by the HEAD hook with the 778 list (`$FC/leak-probe.txt`: `hook=ALLOW | man -l /etc/hostname`, `hook=ALLOW | date -f /etc/hostname`). The "probably" is now confirmed.

**Evidence:** `$FC/gitexec.txt`, `$FC/leak-probe.txt`

---

## Claim 17: "without a sandbox, allowed tools leak through their own flags. The hook's shape check (decision log 64) cannot see that."

**Location:** `docs/working/questions.md:189` (Q-097)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the flag-based leaks listed; does not cover the builtin-argument code execution of Claim 7b, which the leak list omits (`read 'a[$(id)]'`, `test -v 'a[$(id)]'` are approved with the 778 list).

All flag forms are plain CallExpr shapes and are approved at HEAD (`$FC/leak-probe.txt`, Claim 14). Missing from the leak list (the sandbox spike's test set), also approved there: `hook=ALLOW | read 'a[$(id)]' <<< 1`, `hook=ALLOW | test -v 'a[$(id)]'`.

**Evidence:** `$FC/leak-probe.txt`

---

## Claim 18: "These used to get "allow" when only the outer command was allow-listed: echo $((1 + $(cmd))) … heredoc bodies … PATH=/x ls, LD_PRELOAD= … ls > ~/.bashrc"

**Location:** `hooks/auto-approve-allowed-commands.sh:27-34`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers agreement with row 53 and main's header; does not re-run main.

main's header read "Reproduced bypasses — each gets "allow" when only the outer command is allow-listed:" with the same four lines (`git diff main...HEAD`, removed lines at `@@ -24,16`), and row 53 lists the same four (Claim 4).

**Evidence:** `hooks/auto-approve-allowed-commands.sh:27-34`, `docs/decisions/log.md:76`

---

## Claim 19: "The hook now approves only an allowlist of AST SHAPES (refuses_construct): literal words, plain $NAME, pipes and && || ;, and redirects that neither write nor read a path. Any other construct prompts, including ones nobody has listed. … Parse FAILURES and commands that extract to nothing fail closed too."

**Location:** `hooks/auto-approve-allowed-commands.sh:37-42`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the construct gate and both fail-closed paths; does not establish that approved shapes are free of code execution (Claims 7b, 26).

Same evidence as Claims 1, 2, 7a. Parse failure: `mapfile -d '' extracted_commands < <(extract_commands_from_string "$command")` then `if ! wait $!; then … exit 0` (`hooks/auto-approve-allowed-commands.sh:423-427`), and `refuses_construct` returning true makes `extract_commands_raw` `return 1` (`:748-750`).

**Evidence:** `hooks/auto-approve-allowed-commands.sh:37-42`, `hooks/auto-approve-allowed-commands.sh:411-440`, `hooks/auto-approve-allowed-commands.sh:742-754`, `$FC/vacuity.txt`

---

## Claim 20: "Set by main only: the hook refuses constructs (refuses_construct) that the parse_commands extractor must still be able to list."

**Location:** `hooks/auto-approve-allowed-commands.sh:112-114`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers every assignment of the flag; does not establish callers outside this file.

`REFUSE_CONSTRUCTS=true` occurs once, inside `main` (`:414`); the only other assignment is the `false` default (`:114`) (paraphrased — no quote available because the claim is about the absence of other assignments; `grep -n REFUSE_CONSTRUCTS=` returns those two lines). The test "the parse_commands extractor still lists commands the hook refuses to approve" passes (`$FC/suites-hooks.txt`, 235/235).

**Evidence:** `hooks/auto-approve-allowed-commands.sh:112-114`, `hooks/auto-approve-allowed-commands.sh:414`, `test/auto-approve-allowed-commands.bats:542-548`, `$FC/suites-hooks.txt`

---

## Claim 21: "FAIL CLOSED on a parse failure, and on any AST shape refuses_construct does not allow: extraction fails for both, so the command falls through to the normal prompt."

**Location:** `hooks/auto-approve-allowed-commands.sh:415-417`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the outer level and every `bash -c` recursion level (`extract_commands_from_string "$inner" || return 1`, `:877`); does not cover a jq crash inside the extraction filter itself (stderr discarded, `2>/dev/null` at `:753`).

`refuses_construct` true → `return 1` (`:748-750`) → `raw_commands=$(extract_commands_raw "$cmd") || return 1` (`:864`) → `if ! wait $!; then … exit 0` (`:423-427`), no `allow` printed. A jq error in the shape filter maps to refusal: `reason=$(jq -r "$SHAPE_FILTER" <<<"$ast") || reason="shape check failed"` (`:789`). All refused items in `$FC/vacuity.txt` end with no allow.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:411-427`, `hooks/auto-approve-allowed-commands.sh:742-754`, `hooks/auto-approve-allowed-commands.sh:786-793`, `$FC/vacuity.txt`

---

## Claim 22: "Not approved: `let 'a[$(cmd)]=1'` extracted to nothing and used to be approved here, while bash ran the substitution (decision log row 64)."

**Location:** `hooks/auto-approve-allowed-commands.sh:435-436`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the history at f05043f; does not imply `let` now reaches this branch — it is refused earlier as `node type LetClause` (`$FC/vacuity.txt`).

Pass 1 (Claim 1a) quotes `hook=ALLOW | cmd: let 'a[$(touch M_let)]=1' | files created: M_let` and attributes it to "`debug "No commands found in input, allowing"` (`hooks/auto-approve-allowed-commands.sh:434`)".

**Evidence:** `docs/reviews/code-fact-check-report-unitA-pass1-f05043f.md:29-55`, `docs/reviews/execution-logs/cfc-f05043f-probes-2.txt`

---

## Claim 23: "A command name is the first Arg's literal text (Lit, SglQuoted and literal-only DblQuoted parts joined, backslashes and any leading path dropped, so 'ba''sh', \bash and /bin/bash all read as bash); any other part (e.g. $X) makes it non-literal. The marker is \u0001, not \u0000: jq 1.6's contains() treats a NUL-led needle as empty and matches everything."

**Location:** `hooks/auto-approve-allowed-commands.sh:672-677`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the name normalization and the jq 1.6 behavior; does not establish that ANSI-C escapes in a name (`$'\x62ash'`) are decoded — they are not, but such a name then extracts as `'\x62ash'`, which no ordinary prefix rule matches.

```
# hooks/auto-approve-allowed-commands.sh:702-704
        ((.Args[0] // {}) | lit_word | gsub("\\\\"; "") | sub(".*/"; "")) as $name
        | if $name == "" or ($name | index("\u0001") != null) then "non-literal command name"
          elif ($name | IN(wrappers[])) then "interpreter or wrapper: \($name)"
```

`$FC/vacuity.txt`: `/bin/bash -c ls`, `\bash -c ls`, `'ba''sh' -c ls` → `interpreter or wrapper: bash`; `$X ls`, `"$X" ls` → `non-literal command name`. jq 1.6 (`jq-1.6`): `["abc" | contains("\u0000"), ("abc" | index("\u0001")), ("a\u0001" | index("\u0001"))]` → `[true,null,1]` (`$FC/ast-probe.txt`).

**Evidence:** `hooks/auto-approve-allowed-commands.sh:672-710`, `$FC/vacuity.txt`, `$FC/ast-probe.txt`

---

## Claim 24: "bash -c / sh -c never reach the inner recursion with approval possible: refuses_construct already refuses those command names at the outer level."

**Location:** `hooks/auto-approve-allowed-commands.sh:742-747`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers every form `get_shell_c_inner` recognizes (`bash`/`sh`, absolute path, `env` prefix); does not cover the extractor path (`parse_commands`), where the refusal is off by design.

`get_shell_c_inner` only matches `^(bash|sh)[[:space:]]+-c…` after stripping `env ` and a `/path/` prefix (`:849-851`); the shape filter refuses `bash`, `sh` and `env` names after the same normalizations. Probed: `bash -c ls`, `sh -c ls`, `/bin/bash -c ls`, `bash -c "ls \`id\`"`, `bash -c $'ls \x3e f'` → `interpreter or wrapper: bash|sh`; `env ls` → `interpreter or wrapper: env` (`$FC/vacuity.txt`); the pass-1 approved forms now prompt (`$FC/probes1.txt`).

**Evidence:** `hooks/auto-approve-allowed-commands.sh:742-750`, `hooks/auto-approve-allowed-commands.sh:820-852`, `$FC/vacuity.txt`, `$FC/probes1.txt`

---

## Claim 25: "node types File, CallExpr, BinaryCmd (| |& && ||), Lit, SglQuoted, DblQuoted, and ParamExp that is a plain $NAME / ${NAME} / ${#NAME} (no ${x:-}, ${!x}, ${x@P}, ${a[i]}, ${x/a/b}, ${x:1}: several of those evaluate code). So no $(...), `...`, <(...), $((...)), [[ ]], (( )), let, export/declare/local/readonly, subshells, { }, if/for/while/case, functions, time, coproc; statements that are not backgrounded (&); simple commands with no VAR= assignment"

**Location:** `hooks/auto-approve-allowed-commands.sh:762-770`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each listed exclusion and the three plain ParamExp forms; does not cover ParamExp keys that shfmt might add in other versions (the filter deletes a fixed key set and refuses any remainder, which fails closed).

```
# hooks/auto-approve-allowed-commands.sh:686-688
def plain_param:
  (del(.Pos, .End, .Type, .Dollar, .Param, .Rbrace, .Short, .Length)
   | with_entries(select(.value != null and .value != false)) | length) == 0;
```

`${x}`, `${#x}`, `$1`, `$@` carry only deleted keys (`$FC/ast-probe.txt`); every listed exclusion is refused with its reason (`$FC/vacuity.txt`); the approvable-shapes test passes (`$FC/suites-hooks.txt`).

**Evidence:** `hooks/auto-approve-allowed-commands.sh:686-706`, `$FC/ast-probe.txt`, `$FC/vacuity.txt`, `$FC/suites-hooks.txt`

---

## Claim 26: "simple commands … whose command name is literal (not $X) and is not an interpreter or wrapper that runs its arguments as code (bash -c, eval, source, env, xargs, ...)"

**Location:** `hooks/auto-approve-allowed-commands.sh:770-772`
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers bash builtins that take a code string or rebind a command name, with the builtin allow-listed; does not cover external tools with exec flags (`find -exec`, `git -c`), which the commit assigns to the allow list.

The approvable set is "not in `wrappers`", a fixed name list:

```
# hooks/auto-approve-allowed-commands.sh:689-692
def wrappers:
  ["bash","sh","zsh","dash","ksh","fish","eval","source",".","exec","command",
   "builtin","env","xargs","sudo","nohup","trap","alias","enable","nice",
   "timeout","stdbuf","watch","parallel","script","su"];
```

Builtins that run an argument as code are missing and approvable (`$FC/probes2.txt`, run by real bash):

```
hook=ALLOW  | mapfile\ -C\ \'touch\ M_mapcb\;:\'\ -c\ 1\ x\ \<\<\<\ a | created: ./M_mapcb
hook=ALLOW  | compgen\ -C\ \'touch\ M_compgen\'\ x | created: ./M_compgen
hook=ALLOW  | hash\ -p\ /usr/bin/touch\ ls\;\ ls\ M_hash | created: ./M_hash
```

`hash -p` makes the approved `ls` run `touch`, so the extracted command name is not what bash executes. Also `complete -C`, `bind -x` are approved (not executed in a non-interactive shell here). With the named builtin allow-listed, the sentence's promise — no approvable command runs its arguments as code — does not hold. Precise version: "not one of the listed interpreters/wrappers", plus adding `mapfile`, `readarray`, `compgen`, `complete`, `bind`, `hash`, `fc` to the list (and see Claim 7b for `read`/`printf -v`/`test -v`).

**Evidence:** `hooks/auto-approve-allowed-commands.sh:689-706`, `hooks/auto-approve-allowed-commands.sh:770-772`, `$FC/probes2.txt`

---

## Claim 27: "redirects that cannot write or read a file: any operator containing '>' (>, >>, &>, &>>, >|, <>, >&) is refused unless its target is exactly /dev/null or it duplicates an fd (>&N, >&-); an input redirect `<` or `<&` is refused unless it reads /dev/null or duplicates an fd. Here-docs and here-strings (<<, <<<) pass: their text is inline."

**Location:** `hooks/auto-approve-allowed-commands.sh:772-777`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers every operator listed, fd duplication, `/dev/null`, line continuations and multibyte prefixes; does not establish `/dev/null` reads via `<&` (refused, stricter than the sentence) or `>&/dev/null` (refused).

`$FC/vacuity.txt`: `>`, `>>`, `&>`, `&>>`, `>|`, `<>`, `>&`, `2>` to a file, `<` from a file, `0<` → refused. `$FC/probes1.txt`/`probes3.txt`: `ls 2>&1-` refused (`'>&' '1-'`), `ls >&-`, `ls <&0`, `ls < /dev/null`, `ls <>/dev/null`, `ls >>/dev/null`, `ls >|/dev/null` approved; `ls >\<newline>M_contout` refused; `ls {fd}>M_namedfd` refused; `ls <&/dev/null` refused. Here-string with a substitution is refused by the node gate (`ls <<<"$(touch M_herestr)"` → `node type CmdSubst`).

**Evidence:** `hooks/auto-approve-allowed-commands.sh:795-818`, `$FC/vacuity.txt`, `$FC/probes1.txt`, `$FC/probes3.txt`

---

## Claim 28: "Needed once hooks/wiring.json gave every cc-isolated project a global allow list: any one allowed command is an outer command for these constructs."

**Location:** `hooks/auto-approve-allowed-commands.sh:778-779`
**Type:** Configuration / Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers whether `hooks/wiring.json` gives a global allow list at 033ccd6; does not dispute the second clause (any allowed command is an outer command).

`hooks/wiring.json` has only `permissions.deny` at HEAD and at 51bbfb6 (`jq '.permissions|keys'` → `["deny"]`, paraphrased — no quote available because captured to the terminal only), and Q-097 shelves the list: "**Interim:** no global allow list." Same drift as Claim 5; the comment should justify the gate by each project's own allow rules.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:778-779`, `hooks/wiring.json`, `docs/working/questions.md:201`

---

## Claim 29: "Op is a numeric token code (63 is `>` in shfmt 3.13.1) with no stability promise across versions. … Those are byte offsets into the string shfmt parsed, so $1 must be that same (normalized) string, and slicing is done under LC_ALL=C (bytes)."

**Location:** `hooks/auto-approve-allowed-commands.sh:781-785`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the Op value, that the sliced string is the parsed one, and byte slicing under a UTF-8 locale; does not establish shfmt's stability policy.

shfmt v3.13.1: `printf 'ls > x\n' | shfmt -ln bash -tojson | jq -c '[.. | objects | select(has("Op")) | .Op]'` → `[63]` (`$FC/probes3.txt`). `extract_commands_raw` normalizes `cmd`, parses `echo "$cmd"`, and passes the same `$cmd` (`cmd=$(normalize_for_shfmt "$cmd")` `:730`, `refuses_construct "$cmd" "$ast"` `:748`); `local LC_ALL=C` at `:788`. `$FC/locale-probe.txt` shows identical, correct slices under `C` and `C.UTF-8`. The perl normalization only reorders the contiguous `[[ \!` run into `! [[ ` (`s/\[\[\s*\\?!\s+(.+?)\s+=~\s*/! [[ $1 =~ /g`, `:719`), so it cannot move a quote boundary, and every `[[` is refused anyway.

**Evidence:** `hooks/auto-approve-allowed-commands.sh:715-754`, `hooks/auto-approve-allowed-commands.sh:781-790`, `$FC/probes3.txt`, `$FC/locale-probe.txt`

---

## Claim 30: "A plain `<` (or `<&`) opens a path, and any approved command that prints its input would print that file (`tr -d x < ~/.claude/.c*`), so it passes only from /dev/null or as an fd duplication."

**Location:** `hooks/auto-approve-allowed-commands.sh:799-802`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the input-redirect branch; does not establish `<&/dev/null` (refused, since `/dev/null` is accepted only for plain `<`).

```
# hooks/auto-approve-allowed-commands.sh:802-808
    if [[ "$op" == '<<'* ]]; then continue; fi
    if [[ "$op" == '<&' && "$word" =~ ^([0-9]+|-)$ ]]; then continue; fi
    if [[ "$op" == '<' && "$word" == /dev/null ]]; then continue; fi
    if [[ "$op" == '<'* && "$op" != *'>'* ]]; then
      debug "Refusing input redirect: '$op' '$word'"
      return 0
    fi
```

`tr -d x < ~/.claude/.c*` and `tr -d x < /etc/hostname` → `Refusing input redirect` (`$FC/vacuity.txt`, `$FC/probes1.txt`).

**Evidence:** `hooks/auto-approve-allowed-commands.sh:795-818`, `$FC/vacuity.txt`, `$FC/probes1.txt`

---

## Claim 31: "Since log 64 the hook refuses every substitution, so REPRO is refused with or without a deny rule. The deny tests below use PLAIN, the same exfiltration with no substitution, so they still exercise the deny check."

**Location:** `test/auto-approve-allowed-commands.bats:120-122`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the REPRO refusal and the PLAIN baseline; does not establish that each deny test's other spellings are non-vacuous individually.

The baseline test asserts PLAIN is approved with `Bash(curl:*)` and no deny rule (`[[ "$output" == *'"permissionDecision":"allow"'* ]]`, `:145`), so the deny tests' "not approved" results depend on the deny check. All pass (`$FC/suites-hooks.txt`: `1..235`, 235 `ok`, `# exit=0`).

**Evidence:** `test/auto-approve-allowed-commands.bats:116-160`, `$FC/suites-hooks.txt`

---

## Claim 32a: "Each command below is a bypass family a review round found"

**Location:** `test/auto-approve-allowed-commands.bats:466-471`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers provenance of the listed items; does not affect the assertions.

Most items trace to row 53 or the review reports (Claim 6), but some are ordinary negatives, not found bypasses: `'ls $((1 + 2))'`, `'ls 2> err.log'`, and `'ls > "/dev/null"'`, which writes only to `/dev/null` in bash and is refused because its source text is `"/dev/null"` (`$FC/vacuity.txt`: `Refusing redirect: '>' '"/dev/null"'`). Precise version: "families found, plus near variants".

**Evidence:** `test/auto-approve-allowed-commands.bats:466-483`, `$FC/vacuity.txt`

---

## Claim 32b: "all must prompt with the outer commands allowed."

**Location:** `test/auto-approve-allowed-commands.bats:470-471`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers whether each must-prompt item's outer command is in `SHAPE_RULES`, i.e. whether the item exercises `refuses_construct`; does not dispute that every item prompts.

`SHAPE_RULES` allows only `ls wc tr echo read cd bash sh` (`:472`). With `REFUSE_CONSTRUCTS` switched off in a scratch copy of the hook, these items still prompt because the outer command is not allowed (`$FC/vacuity2.txt`): `eval ls`, `env ls`, `xargs ls`, `source x`, `. x`, `exec ls`, `command ls`, `builtin cd`, `nohup ls`, `/bin/bash -c ls`, `\bash -c ls`, `'ba''sh' -c ls`, `$X ls`, `"$X" ls` (e.g. `BLOCKED: 'eval ls' (no matching prefix)`), plus `ls $(pwd)`, ``ls `pwd` ``, `while false; …`, `f(){ ls; }; f`. So 14 of the 18 interpreter/wrapper items would stay green if `eval`, `env`, `xargs`, `source`, `.`, `exec`, `command`, `builtin`, `nohup` were deleted from `wrappers`, or if the path/backslash/quote normalization of the name were removed. To exercise the gate, add those names (e.g. `Bash(eval:*)`, `Bash(env:*)`, `Bash(/bin/bash:*)`) to the rules for that test, or assert the refusal reason with `--debug`.

**Evidence:** `test/auto-approve-allowed-commands.bats:466-520`, `$FC/vacuity2.txt`, `$FC/vacuity.txt`

---

## Claim 33: "a command that extracts to nothing is not approved (used to be: 'no commands found, allowing')"

**Location:** `test/auto-approve-allowed-commands.bats:522-528`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers which items reach main's empty-extraction branch; does not dispute that all four prompt.

Of the four items, only `' '` and `'# just a comment'` reach the branch; `let 'a[$(id)]=1'` is refused earlier by `node type LetClause`, and `''` exits at `No command found` before extraction (`$FC/vacuity.txt`). The dangerous item therefore does not test the branch change; the two that do are harmless inputs. Since every approvable shape that extracts to nothing is empty or a comment (Claim 1), the branch change is defense in depth — the title should say so, or the `let` item should move to the constructs test.

**Evidence:** `test/auto-approve-allowed-commands.bats:522-528`, `hooks/auto-approve-allowed-commands.sh:390-393,437-440`, `$FC/vacuity.txt`

---

## Claim 34: "Unit A review pass 1 … found 9 Incorrect claims, all the same failure … Approved and executed with one allowed command: `let 'a[$(cmd)]=1'`, `[[ 'a[$(cmd)]' -eq 0 ]]` …; `export PATH=$PWD/evil:$PATH; ls` …; `bash -c "ls \`cmd\`"`, `bash -c $'ls \x3e f'`"

**Location:** commit 51bbfb6 message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers agreement with the pass-1 report; does not re-run f05043f.

Pass-1 header: `**Summary:** 24 verified, 3 mostly accurate, 0 stale, 9 incorrect, 1 unverifiable`; its Claims 1a/1b/1c quote each listed family as `hook=ALLOW` with marker files created.

**Evidence:** `docs/reviews/code-fact-check-report-unitA-pass1-f05043f.md:8-9,29-110`

---

## Claim 35: "Unit B's pass-1 fact-check added `tr -d x < <config>/.c*`: an input redirect lets any approved printer read any path."

**Location:** commit 51bbfb6 message
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers which report holds the finding; does not dispute the finding (executed there and re-probed here, Claim 30).

The finding is in `docs/reviews/code-fact-check-report-wiring-pass2-e511a14.md` on `feat/wiring-allowlist-b` (`APPROVED | tr -d x < ~/.claude/.c*`, `:213`), committed as "wiring allow list pass 2 fact-check" (4b6da9f); the wiring pass-1 report (`…-wiring-pass1-5094b99.md`) has no `tr -d` line (paraphrased — no quote available because the claim is about absence; `grep -c 'tr -d'` → 0). It is unit B's first pass on the narrowed list, so "pass-1" is defensible, but Q-097 names the same report "pass-2" (Claim 13). Precise version: cite the file.

**Evidence:** `feat/wiring-allowlist-b:docs/reviews/code-fact-check-report-wiring-pass2-e511a14.md:39,213`

---

## Claim 36: "refuses_construct now runs SHAPE_FILTER (jq) and refuses anything but: node types File, CallExpr, BinaryCmd, Lit, SglQuoted, DblQuoted and a plain $NAME/${NAME}/${#NAME} ParamExp; no background/coproc; no VAR= assignment; a literal command name that is not an interpreter or wrapper (bash, sh, eval, source, env, xargs, exec, command, builtin, sudo, nohup, ...; 'ba''sh', \bash and /bin/bash all count); and redirects that neither write nor read a path … main no longer approves a command that extracts to nothing. An unknown construct now prompts by default."

**Location:** commit 51bbfb6 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the mechanism as described with the named wrapper set; does not establish that the "..." covers every code-running builtin (it does not — Claim 26).

Same evidence as Claims 1, 2, 7a, 23, 27; every named wrapper is in `wrappers` (`hooks/auto-approve-allowed-commands.sh:689-692`).

**Evidence:** `hooks/auto-approve-allowed-commands.sh:672-818`, `$FC/vacuity.txt`, `$FC/probes1.txt`

---

## Claim 37: "jq 1.6 note: contains("\u0000") matches every string (NUL-terminated needle), so the non-literal marker is \u0001 with index()."

**Location:** commit 51bbfb6 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the observed behavior in jq-1.6; the "NUL-terminated needle" cause is not verified from jq source.

`$FC/ast-probe.txt`: `"abc" | contains("\u0000")` → `true`; `index("\u0001")` → `null` on `"abc"`, `1` on `"a\u0001"`.

**Evidence:** `$FC/ast-probe.txt`

---

## Claim 38: "every bypass family found so far (…) must prompt with ls, wc, tr, echo, read, cd, bash and sh all allowed, and 18 ordinary shapes are still approved. 235/235 in the hook and wiring suites."

**Location:** commit 51bbfb6 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the listed test items, the 18-item count and the suite total (the 235 includes `test/hooks/*.bats`, as in pass 1's 233); does not establish that the tests exercise every wrapper (Claim 32b) or that the let family is closed with `read` allowed (Claim 7b).

The approvable-shapes loop has 18 items (`test/auto-approve-allowed-commands.bats:530-540`, counted). `$FC/suites-hooks.txt`: `1..235`, 235 `ok`, no `not ok`, `# exit=0`, HEAD 033ccd6 (51bbfb6's hook and test are unchanged since: `git diff 51bbfb6 033ccd6 -- hooks test` is empty — paraphrased, no quote available because the claim is an empty diff).

**Evidence:** `test/auto-approve-allowed-commands.bats:466-548`, `$FC/suites-hooks.txt`

---

## Claim 39: "Decision log row 64 rewritten for the shape allowlist; header and comments updated (the stale ${x:-...} and "every bash -c level" wording is gone)."

**Location:** commit 51bbfb6 message
**Type:** Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the hook, the test file and row 64; does not cover commit messages 4dff0e9/f05043f, which are immutable.

`grep -n 'every bash -c\|x:-\.\.\.\|never searched\|Every nesting'` over the hook, test and log returns nothing (paraphrased — no quote available because the claim is about absence).

**Evidence:** `hooks/auto-approve-allowed-commands.sh`, `test/auto-approve-allowed-commands.bats`, `docs/decisions/log.md:87`

---

## Claim 40: "Behavior change: compound one-liners ($(...), $((...)), [[ ]], loops, export, `< file`) now prompt even when every command is allowed."

**Location:** commit 51bbfb6 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Same as Claim 3 plus `< file`; does not measure prompt volume.

Claim 3's evidence, and `wc -l < in` → `Refusing input redirect` (`$FC/vacuity.txt`).

**Evidence:** `$FC/vacuity.txt`

---

## Claim 41: "Residual: an allowed command can still do dangerous things with its own arguments (e.g. git --output=, git config-driven exec); that is the allow list's job (unit B), not the shell-shape check."

**Location:** commit 51bbfb6 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the two git examples; does not establish that the residual is only external-tool flags — shell builtins evaluate their own arguments as code too (Claims 7b, 26), which the row and header do not name.

`git log -1 --format=%B --output=/home/node/.claude/settings.json` → `hook=ALLOW` (`$FC/leak-probe.txt`); config-driven exec runs (`$FC/gitexec.txt`, Claim 15).

**Evidence:** `$FC/leak-probe.txt`, `$FC/gitexec.txt`

---

## Claim 42: "37 claims: 24 Verified, 3 Mostly accurate, 9 Incorrect, 1 Unverifiable. The Incorrect claims (row 64 "never approves", header, commits) were refuted by executed probes; fixed by the shape allowlist in the parent commit."

**Location:** commit cd71199 message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the counts and the parent; the "fixed" part is checked in the resolution table below.

Pass-1 header `**Total claims checked:** 37`, `**Summary:** 24 verified, 3 mostly accurate, 0 stale, 9 incorrect, 1 unverifiable`; `git log -1 --format='%h %P' cd71199` → `cd71199 51bbfb68…` (paraphrased — no quote available beyond this line, captured to the terminal).

**Evidence:** `docs/reviews/code-fact-check-report-unitA-pass1-f05043f.md:8-9`

---

## Claim 43: "Q-097 (deferred on Q-088) keeps the branch and the leak list … carries the Q-095 and the other session's Q-093/Q-096 questions commits onto this unit"

**Location:** commit 033ccd6 message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers Q-097's route/trigger and the carried commits' session ids; does not check Q-093/Q-096 content (other session).

Q-097: `**Needs:** deferred` and "**Trigger:** Q-088 answers [1] …". 0a6cbdc carries `Claude-Session: …session_01R7PJktbkLUGuWbBm3CGxaF`, unlike this session's `…session_01J2SwVd473vBZr6jJbYvHML`; 2df841a and 9657bf8 are the Q-095 commits.

**Evidence:** `docs/working/questions.md:186-201`, commits 0a6cbdc, 2df841a, 9657bf8

---

## Pass-1 Incorrect claims — resolution

| Pass-1 claim | Location then | Status at 033ccd6 | Evidence |
|---|---|---|---|
| 1a (substitutions "never approved") | log.md:87 | Resolved: row rewritten; `let`, `[[ ]]`, escaped-backtick `bash -c`/`sh -c` now prompt | `$FC/probes1.txt` |
| 1b (`VAR=` "never approved") | log.md:87 | Resolved: `export PATH=…; ls` → `DeclClause` refused | `$FC/probes1.txt` |
| 1c (writing redirect at every `bash -c` level) | log.md:87 | Resolved: `bash -c $'ls \x3e M_ansi'` → wrapper refused | `$FC/probes1.txt` |
| 5 ("converges" by class) | log.md:87 | Wording replaced, but the new "allowlist converges" is again refuted for the same let family via `read`/`printf -v`/`test -v` (Claim 7b) | `$FC/probes1.txt` |
| 9 (header "never approves … ANY substitution") | hook:35-38 | Resolved: header rewritten to the shape allowlist (Claim 19) | `$FC/vacuity.txt` |
| 13 ("every bash -c level is covered") | hook:699-702 | Resolved: comment now says bash/sh are refused at the outer level (Claim 24) | `$FC/vacuity.txt` |
| 15b (`${x:-...}` "not searched") | hook:715 | Resolved: wording removed (Claim 39) | grep |
| 23 (test "never searched" list) | bats:483-484 | Resolved: test replaced (Claim 39) | grep |
| 26 (4dff0e9 "every bash -c level") | commit 4dff0e9 | Immutable commit message; superseded by 51bbfb6, and the behavior is fixed (Claim 24) | `$FC/probes1.txt` |

---

## Claims Requiring Attention

### Incorrect
- **Claim 7b** (`docs/decisions/log.md:87`): "An allowlist of shapes converges" — the row's own `let 'a[$(cmd)]=1'` family is approved and executed through allowed builtins: `read 'a[$(touch M)]' <<< 1`, `printf -v 'a[$(touch M)]' x`, `test -v 'a[…]'`, `[ -v 'a[…]' ]` (`read` is in the tests' own allow list; `read`/`test` are approved by the 778-rule list). Scope "converges" to AST constructs and name builtin-argument evaluation as a residual, or refuse these builtins/subscripted-name arguments.
- **Claim 26** (`hooks/auto-approve-allowed-commands.sh:770-772`): approvable names are "not an interpreter or wrapper that runs its arguments as code", but `mapfile -C`, `compgen -C` (executed) and `hash -p` (makes the approved `ls` run another binary) pass the fixed `wrappers` list. Add `mapfile`, `readarray`, `compgen`, `complete`, `bind`, `hash`, `fc` or reword to "not one of the listed names".
- **Claim 32b** (`test/auto-approve-allowed-commands.bats:470-471`): "all must prompt with the outer commands allowed" — 14 of 18 interpreter/wrapper items (and `ls $(pwd)`, `while false`, `f(){…}; f`) prompt because their outer command is not in `SHAPE_RULES`, so the test stays green with those wrappers removed. Allow the outer commands in that test or assert the debug reason.

### Stale
- **Claim 5** (`docs/decisions/log.md:87`): "a global allow list in `hooks/wiring.json` gives one to every project" — wiring.json has only deny rules; Q-097 shelved the list.
- **Claim 28** (`hooks/auto-approve-allowed-commands.sh:778-779`): "Needed once hooks/wiring.json gave every cc-isolated project a global allow list" — same drift; justify by projects' own allow rules.

### Mostly Accurate
- **Claim 13** (`docs/working/questions.md:194`): "the unit-B pass-2 fact-check (below)" has no path; cite `docs/reviews/code-fact-check-report-wiring-pass2-e511a14.md` on `feat/wiring-allowlist-b`.
- **Claim 32a** (`test/auto-approve-allowed-commands.bats:466-471`): not every item is a found bypass family (`ls $((1 + 2))`, `ls > "/dev/null"`, `ls 2> err.log`).
- **Claim 33** (`test/auto-approve-allowed-commands.bats:522-528`): the `let` item is refused by the shape gate, not the empty-extraction branch; only harmless inputs reach that branch.
- **Claim 35** (commit 51bbfb6): the `tr -d x <` finding is in the file named `…wiring-pass2-e511a14.md`, which Q-097 calls pass 2.

### Unverifiable
- **Claim 9** (`docs/decisions/log.md:87`): "User chose each step" — needs the session record; no answered Q entry holds the three choices.

## Goal-Alignment Note
- Success criterion (restated verbatim): A report saved to /workspace/.claude/wt-hook-a/docs/reviews/code-fact-check-report.md (overwrite it) in the code-fact-check schema, with `**Commit:** 033ccd6` and `**Replication:** k=1 (loop pass, decision 031)` in the header, a Legibility-target on every claim, and a Goal-Alignment Note at the end. Put execution logs under /tmp/claude-1000/-workspace/aef7a10c-6785-42b5-b88a-f42ac33780a8/scratchpad/fcA2/. Reply with counts by verdict and every Incorrect claim.
- Answered: yes — 45 claims, every behavioral claim executed against the hook (and approved probes run in real bash with marker files); all 9 pass-1 Incorrect claims checked (8 resolved; pass-1 Claim 5's non-convergence recurs as Claim 7b).
- Out of scope: Q-093/Q-094/Q-096 text (another session's commit 0a6cbdc); 4dff0e9/f05043f message claims already verdicted in pass 1; Claude Code's own engine decision (the hook's output is what was tested). Pre-existing, not in this diff: `is_command_allowed` accepts `"$allowed/"*`, so with `Bash(ls:*)` the hook approves `ls/*` or `ls/../x`, which bash runs as a path if a directory `ls` exists (`$FC/probes2.txt`: `hook=ALLOW | ls/\*`).
- Escalate: Claim 7b/26 are security-relevant to the unit's goal ("no allow-listed command can be turned into … arbitrary code through shell constructs"): with `read`, `printf`, `test`/`[`, `mapfile`, `compgen` or `hash` allowed, the HEAD hook approves commands that run arbitrary code. `read`/`test` are in the shelved 778-rule list, and Q-097's leak list (the sandbox spike's test set) omits them.
