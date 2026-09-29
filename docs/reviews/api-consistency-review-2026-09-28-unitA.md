Commit: 1a513a8

# API Consistency Review — Unit A, `feat/hook-refuse-redirects` (pass 3)

**Scope:** `git diff main...HEAD` in `/workspace/.claude/wt-hook-a` (HEAD 1a513a8). Consumer-facing surface only: which commands the hook approves for a given allow list, the `parse_commands` subcommand, the CLI options, the header's RULE SYNTAX table, decision log row 64, and the docs that describe the hook.
**Date:** 2026-09-28
**Based on:** `docs/reviews/code-fact-check-report-unitA-pass1-f05043f.md`, `docs/reviews/code-fact-check-report-unitA-pass2-033ccd6.md` (context; pass 2's `ls/x` Incorrect is the origin of finding 1), plus fresh probes run for this review (main vs HEAD, below).

> ⚠️ **No code fact-check report at HEAD 1a513a8 was provided.** The two reports above predate 9fad6ec. Behavior claims below rest on the probes in this review, not on a fact-check at this commit.

## Probe log (evidence for the findings)

Script `probe-a3.sh` in the session scratchpad: each row feeds the command to `main`'s hook and HEAD's hook with `--permissions <rules> --deny '[]'`, and prints the decision (`fallthrough` = no decision, so Claude Code's normal permission check runs). Output, verbatim (locale warning line omitted):

```
HEAD=1a513a8
ls/x                                         | ["Bash(ls)"]                                                 | main=allow       | HEAD=fallthrough
ls/x                                         | ["Bash(ls:*)"]                                               | main=allow       | HEAD=fallthrough
.claude/skills/foo.sh                        | ["Bash(.claude/skills:*)"]                                   | main=allow       | HEAD=fallthrough
.claude/skills/foo.sh a | head               | ["Bash(.claude/skills:*)","Bash(head:*)"]                    | main=allow       | HEAD=fallthrough
python3 .claude/skills/foo/bar.py            | ["Bash(python3 .claude/skills:*)"]                           | main=allow       | HEAD=allow
test -f x && echo ok                         | ["Bash(test:*)","Bash(echo:*)"]                              | main=allow       | HEAD=fallthrough
read x                                       | ["Bash(read:*)"]                                             | main=allow       | HEAD=fallthrough
printf "%s\n" a | wc -l                      | ["Bash(printf:*)","Bash(wc:*)"]                              | main=allow       | HEAD=fallthrough
bash scripts/run-tests.sh a 2>&1 | tail -5   | ["Bash(bash scripts/run-tests.sh:*)","Bash(tail:*)"]         | main=allow       | HEAD=fallthrough
bash -n x.sh && echo ok                      | ["Bash(bash -n:*)","Bash(echo:*)"]                           | main=allow       | HEAD=fallthrough
bash -n x.sh                                 | ["Bash(bash -n:*)"]                                          | main=allow       | HEAD=fallthrough
timeout 5 ls                                 | ["Bash(timeout:*)"]                                          | main=allow       | HEAD=fallthrough
grep foo < file                              | ["Bash(grep:*)"]                                             | main=allow       | HEAD=fallthrough
grep foo file 2>/dev/null | head             | ["Bash(grep:*)","Bash(head:*)"]                              | main=allow       | HEAD=allow
                                             | ["Bash(ls:*)"]                                               | main=fallthrough | HEAD=fallthrough
# only a comment                             | ["Bash(ls:*)"]                                               | main=allow       | HEAD=fallthrough
echo "$(git rev-parse HEAD)"                 | ["Bash(echo:*)","Bash(git rev-parse:*)"]                     | main=allow       | HEAD=fallthrough
kill -0 123                                  | ["Bash(kill:*)"]                                             | main=allow       | HEAD=fallthrough
type -a ls                                   | ["Bash(type:*)"]                                             | main=allow       | HEAD=allow
--- parse_commands (extractor CLI)
[.../hook-main.sh]
test -f x
read y
ls
rc=0
[hooks/auto-approve-allowed-commands.sh]
test -f x
read y
ls
rc=0
```

## Baseline Conventions

- **Documentation home.** The hook header declares itself the single statement of rule semantics: `guides/bare-host-hook-wiring.md:152-154` says "the hook header's WHAT THE DENY CHECK GUARANTEES and RULE SYNTAX sections are the one statement of what it covers", and `hooks/wiring.json` defers to the header the same way. So the header's RULE SYNTAX table is the consumer contract for how an allow rule reads.
- **Rule semantics on main.** An allow rule is a literal command prefix, matched as `==`, `"$allowed "*` or `"$allowed/"*`, per extracted component (`is_command_allowed`). Rule authors write `Bash(name:*)` or `Bash(name args:*)` expecting "this program, with any arguments, alone or in a pipe".
- **Behavior changes are recorded** in the header (formerly ACCEPTED RISK, now CLOSED GAPS), in a decision log row, and, where they touch the wiring, in `guides/bare-host-hook-wiring.md` and `docs/decisions/023-*`.
- **Failure direction.** Everything the hook will not approve falls through to Claude Code's normal check (no `deny`, no `ask`); this is kept in the diff.
- **Shell naming.** Global flags are UPPER_SNAKE booleans (`DEBUG`, `NUL_DELIM`, `DENY_ALL`, `CUSTOM_DENY_SET`); jq programs are heredoc variables (`JQ_FILTER`, `SETTINGS_RULES_JQ`); predicates are lower_snake verb phrases (`is_command_allowed`, `matches_deny`).

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `REFUSE_CONSTRUCTS` | global flag | `NUL_DELIM`, `DENY_ALL`, `CUSTOM_DENY_SET` | `hooks/auto-approve-allowed-commands.sh:110-133` | Consistent: UPPER_SNAKE boolean set by `main` |
| `SHAPE_FILTER` | jq program variable | `JQ_FILTER`, `SETTINGS_RULES_JQ` | `hooks/auto-approve-allowed-commands.sh:154,578` | Consistent with `JQ_FILTER` (`*_FILTER`) |
| `refuses_construct` | predicate function | `matches_deny`, `is_command_allowed` | `hooks/auto-approve-allowed-commands.sh:311,335` | Consistent: third-person verb predicate like `matches_deny`; returns 0 when refusing, as its name reads |
| jq defs `lit_word`, `plain_param`, `wrappers`, `builtins`, `safe_builtins` | jq internals | `extract_commands` (jq def in `JQ_FILTER`) | `hooks/auto-approve-allowed-commands.sh:578-675` | Consistent; internal to the filter, not consumer-facing |

No new CLI option, subcommand or output field. `parse_commands` output is unchanged (probe log): `REFUSE_CONSTRUCTS` is set only in `main`.

## Findings

#### 1. RULE SYNTAX table still documents `Bash(ls)` approving `ls/x`

**Severity:** Inconsistent
**Location:** `hooks/auto-approve-allowed-commands.sh:93` (table) vs `:344-349` (code)
**Move:** 3 (documentation drift)
**Confidence:** High
**Legibility-target:** rule authors reading the header, which the guide names as "the one statement" of rule semantics

**Evidence:**
```
#   rule         as allow                               as deny
#   Bash(ls)     prefix: `ls`, `ls -la`, `ls/x`          exact: `ls` only
```
```
    # The "$allowed/" form is for path-prefix rules ("python3 .claude/skills").
    # It applies only when the rule has an argument: for a bare name like
    # "ls", "ls/x" is a different program, which bash runs from a directory
    # named ls (decision log row 64).
    if [[ "$full_command" == "$allowed" ]] || [[ "$full_command" == "$allowed "* ]] \
       || { [[ "$allowed" == *" "* ]] && [[ "$full_command" == "$allowed/"* ]]; }; then
```
Probe: `ls/x | ["Bash(ls)"] | main=allow | HEAD=fallthrough`.

The canonical table now states the opposite of what the hook does. This is the same row pass 2's fact-check flagged; 9fad6ec changed the code and row 64 but not the table. A reader relying on the table will believe `Bash(ls)` covers `ls/x`.

**Recommendation:** Change the allow cell to `prefix: \`ls\`, \`ls -la\` (not \`ls/x\`)` and add a table row for the path-prefix form that keeps `/` (e.g. `Bash(python3 .claude/skills:*)` → `python3 .claude/skills/x.py`).

#### 2. The `/` rule drops every no-space rule, not only bare names: `Bash(.claude/skills:*)` stops approving `.claude/skills/foo.sh`

**Severity:** Breaking (latent: no rule of this shape was found in the searched settings)
**Location:** `hooks/auto-approve-allowed-commands.sh:344-349`; `docs/decisions/log.md:87` (row 64)
**Move:** 3 (subtle breaking change: narrowed accepted input)
**Confidence:** High on behavior; Medium on impact
**Legibility-target:** rule authors with directory-prefix rules; the row-64 reader

**Evidence:**
```
       || { [[ "$allowed" == *" "* ]] && [[ "$full_command" == "$allowed/"* ]]; }; then
```
Row 64: "and a bare-name rule (`Bash(ls:*)`) no longer approves `ls/x`."
Probe: `.claude/skills/foo.sh | ["Bash(.claude/skills:*)"] | main=allow | HEAD=fallthrough` and `.claude/skills/foo.sh a | head | [...] | main=allow | HEAD=fallthrough`.

The gate is "rule contains a space", so a rule that is itself a directory path (`Bash(.claude/skills:*)`, `Bash(scripts:*)`, `Bash(./bin:*)`) loses the `/` continuation too. On main that was the obvious reading of the `$allowed/` form, and the code comment still calls it "for path-prefix rules". Row 64 and the code comment describe only the bare-name case, so the change is wider than documented. Searched `/workspace/.claude/settings.json`, `~/.claude/settings.json` (no allow rules) and the shelved list on `feat/wiring-allowlist` (`hooks/wiring.json`, 849 `Bash(` rules): no rule of this shape, so nothing in this repo breaks today.

**Recommendation:** Either keep `/` for rules that already contain a `/` (`[[ "$allowed" == *" "* || "$allowed" == */* ]]`), which still refuses `ls/x`, or state in row 64 and the RULE SYNTAX table that a directory rule needs an argument form. The first keeps the old contract for path rules and fixes only the bug.

#### 3. Allow rules whose command is a wrapper or non-safe builtin no longer work through the hook, and the docs name only part of it

**Severity:** Breaking (documented only in part)
**Location:** `hooks/auto-approve-allowed-commands.sh:695-730` (SHAPE_FILTER `wrappers`/`builtins`), header `:26-43`; `docs/decisions/log.md:87`
**Move:** 3 (consumer contract)
**Confidence:** High on behavior; Medium on how the native engine treats the simple form (not measured here)
**Legibility-target:** anyone maintaining a project allow list, starting with this repo's own `.claude/settings.json`

**Evidence:** `/workspace/.claude/settings.json` (read-only):
```
      "Bash(bash -n:*)",
      ...
      "Bash(bash scripts/run-tests.sh:*)",
      "Bash(bash /workspace/scripts/health-check.sh:*)",
      "Bash(claude --version)",
      "Bash(bash devcontainer-config/init-firewall.sh --print-domains)",
```
```
def wrappers:
  ["bash","sh","zsh","dash","ksh","fish","env","xargs","sudo","nohup","nice",
   "timeout","stdbuf","watch","parallel","script","su"];
```
Probes: `bash -n x.sh | ["Bash(bash -n:*)"] | main=allow | HEAD=fallthrough`; `bash scripts/run-tests.sh a 2>&1 | tail -5 | ... | main=allow | HEAD=fallthrough`; `timeout 5 ls`, `read x`, `printf ... | wc -l`, `kill -0 123`, `test -f x && echo ok` all `main=allow | HEAD=fallthrough`.

4 of this repo's 16 project allow rules start with `bash` and are now refused by command name, whatever the rule pins after it. The hook's job is the compound form (pipes, `2>&1`), so `bash scripts/run-tests.sh … | tail` will always prompt; the simple form now depends on Claude Code's native matching. Rules like `Bash(test:*)`, `Bash(read:*)`, `Bash(printf:*)`, `Bash(kill:*)`, `Bash(timeout:*)`, `Bash(env:*)` are dead for the hook too. Row 64 says this ("a literal command name that is neither an interpreter or wrapper … nor a bash builtin"), but its **Cost** clause lists only `test` among these, and the header's CLOSED GAPS summary omits the command-name refusal entirely (next finding). A rule author reading either would not expect their `Bash(bash scripts/run-tests.sh:*)` to stop covering piped runs. The refusal also ignores what the rule pins: `bash scripts/run-tests.sh` names a fixed script, not an arbitrary `-c` string.

**Recommendation:** Add to row 64's Cost and the header a sentence such as "Allow rules whose command is a wrapper (`bash`, `env`, `timeout`, …) or a builtin other than cd/pwd/echo/true/false/type no longer approve anything through this hook; this repo's `Bash(bash …)` rules are affected." Separately (a judgment for the user, not this review), decide whether a rule that pins a script path after `bash` should be honored; that belongs in `questions.md` if not settled here.

#### 4. Header CLOSED GAPS summary omits the command-name refusal and lists a narrower Cost than row 64

**Severity:** Minor
**Location:** `hooks/auto-approve-allowed-commands.sh:37-43` vs `docs/decisions/log.md:87`
**Move:** 3 (documentation drift, internal)
**Confidence:** High
**Legibility-target:** header readers

**Evidence:**
```
# escaped backticks in bash -c, `tr < secret`). The hook now approves only an
# allowlist of AST SHAPES (refuses_construct): literal words, plain $NAME,
# pipes and && || ;, and redirects that neither write nor read a path. Any
# other construct prompts, including ones nobody has listed. Cost: compound
# one-liners (`echo "$(git rev-parse HEAD)"`, `for ...`, `[[ ]]`) now prompt.
```
Row 64: "Cost: compound one-liners (`$(…)`, `$((…))`, `[[ ]]`, `test`, loops, `export`, `< file`) prompt."

The header summary does not say that wrapper and builtin command names, `VAR=` prefixes and `&` are refused, and its Cost list lacks `test`, `export` and `< file`, which row 64 names. The full list is in the `refuses_construct` comment (`:777-807`), so the header summary should either match it or point to it.

**Recommendation:** Add "no `VAR=`, no `&`, and a command name that is not an interpreter/wrapper or a builtin other than cd/pwd/echo/true/false/type" to the summary, and align its Cost list with row 64.

#### 5. `guides/bare-host-hook-wiring.md` still says the gaps are accepted as risk in row 53

**Severity:** Inconsistent
**Location:** `guides/bare-host-hook-wiring.md:148-150`
**Move:** 3 (documentation drift, external doc)
**Confidence:** High
**Legibility-target:** bare-host users wiring the hook

**Evidence:**
```
- `auto-approve-allowed-commands.sh` has filter-coverage gaps: arithmetic expansion,
  heredoc bodies, `VAR=` prefixes and redirect targets. They are accepted as risk in
  decision log row 53. Commands it cannot parse fall through to the normal prompt.
```
The unit closes exactly these four gaps (header "CLOSED GAPS", row 64) and does not touch the guide (`git diff --stat main...HEAD` lists no `guides/` file). The guide now tells users about a risk that no longer exists and says nothing about the new cost (compound commands and wrapper/builtin rules prompt; commands that extract to nothing are not approved).

**Recommendation:** Replace the bullet with: the hook approves only an allowlist of AST shapes (decision log row 64, superseding row 53); unparseable commands, unapproved shapes and commands that extract to nothing fall through to the normal prompt.

#### 6. README's one-line description still says "piped/compound commands"

**Severity:** Informational
**Location:** `README.md:162`
**Move:** 3
**Confidence:** Medium (wording judgment)
**Legibility-target:** README readers

**Evidence:**
```
- `hooks/auto-approve-allowed-commands.sh` — `PreToolUse` Bash hook that auto-approves piped/compound commands when every component matches an allowlisted prefix (Claude Code's native prefix matching doesn't handle pipes); depends on `shfmt` + `jq`
```
"Compound" is still true for `&&`, `||` and `;`, but not for subshells, loops, `$(…)` or `{ }`, which now prompt.

**Recommendation:** Optional: "piped and `&&`/`||`/`;`-joined simple commands", or add "(see row 64 for the approved shapes)".

## What Looks Good

- **CLI surface unchanged.** `--debug`, `--permissions`, `--deny` and their semantics are untouched; no new option.
- **`parse_commands` is kept stable.** The shape check is gated on `REFUSE_CONSTRUCTS`, set only in `main`, so the extractor still lists `test -f x`, `read y`, `ls` for a command the hook refuses (probe log). Consumers of the subcommand see no change.
- **Failure direction is preserved.** Every new refusal, including the old "no commands found, allowing" branch, becomes a fall-through, never a `deny` or `ask`; that matches the header's existing "Parse FAILURES do fail closed" convention and cannot override a user's own rules.
- **The fix is narrow where it can be.** `python3 .claude/skills/foo/bar.py` under `Bash(python3 .claude/skills:*)` still approves, and `grep … 2>/dev/null | head` still approves.
- **Row 64 is thorough** on what is approvable, and Q-097 line 200 records that `read`/`test`/`printf` are refused whatever the rules say.
- **Names follow the file's conventions** (audit above).

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 2 | `/` continuation dropped for every no-space rule, not only bare names | Breaking (latent) | `hooks/auto-approve-allowed-commands.sh:349` | High / Medium impact |
| 3 | Wrapper/builtin-named allow rules (4 of this repo's 16) stop working through the hook; Cost clause names only `test` | Breaking (partly documented) | SHAPE_FILTER `:695-730`; log row 64 | High / Medium |
| 1 | RULE SYNTAX table still says `Bash(ls)` approves `ls/x` | Inconsistent | `hooks/auto-approve-allowed-commands.sh:93` | High |
| 5 | Bare-host guide still says the gaps are accepted (row 53) | Inconsistent | `guides/bare-host-hook-wiring.md:148-150` | High |
| 4 | Header CLOSED GAPS summary narrower than row 64 | Minor | `hooks/auto-approve-allowed-commands.sh:37-43` | High |
| 6 | README "piped/compound" wording | Informational | `README.md:162` | Medium |

## Overall Assessment

The code changes are consistent with the hook's own conventions (names, fail-to-prompt, unchanged CLI and `parse_commands`), and row 64 is a good record. The problems are about the approval contract as rule authors see it. The canonical RULE SYNTAX table contradicts the new `/` behavior (1). The `/` change is wider than documented and breaks directory-prefix rules nobody asked to break (2). Allow rules naming `bash`, `timeout`, `env`, `test`, `read`, `printf`, `kill` and the like, including four of this repo's own project rules, silently stop working through the hook, and the Cost statements under-describe this (3, 4). The bare-host guide still reports the old accepted risk (5). All are fixable in place: one line of code for (2), and doc edits for the rest. Finding 3's second half (whether a rule that pins a script after `bash` should be honored) is a design judgment for the user.

## Goal-Alignment Note
- Success criterion (restated verbatim): A critique saved to /workspace/.claude/wt-hook-a/docs/reviews/api-consistency-review-2026-09-28-unitA.md with `Commit: 1a513a8` at the top, structured per the api-consistency-reviewer skill, every finding with Severity/Confidence/Legibility-target and a verbatim Evidence field, and a Goal-Alignment Note at the end.
- Answered: whether the approval contract is documented consistently (no: header table, header summary, bare-host guide lag row 64); whether `Bash(name/…)` contradicts the rule table (yes, finding 1, and it is wider than documented, finding 2); whether existing project and common rules silently stop working (yes for `Bash(bash …)` ×4 in this repo and `test`/`read`/`printf`/`kill`/`timeout`/`env` rules, finding 3; documented only in part); CLI options and `parse_commands` unchanged (verified by probe).
- Out of scope: whether each refused shape is truly dangerous (security review); what an allowed external program does with its own flags (Q-097); test-suite adequacy.
- Escalate: (a) whether Claude Code's native engine still approves the simple form of the `Bash(bash …)` rules once the hook falls through was not measured; finding 3's impact on non-piped runs depends on it. (b) Whether an allow rule that pins a script after `bash`/`timeout` should be honored is a user judgment, candidate for `questions.md`.
