Commit: 335a347e

# Independent review: Q-092 unit 2 (`fix/q092-drop-hook-deny-reader`)

**Reviewer:** an independent agent (not the builder), 2026-10-15. No subagents were used.
**Scope:** `d27a3891..335a347e`: the hook at HEAD (read in full), tests, `hooks/wiring.json`, `guides/bare-host-hook-wiring.md`, the amendment to decision log row 53, the commit messages, the rubric and the inline self-review.
**Probes:** `/home/node/.claude/jobs/00bcf178/tmp/q092-indep/p1.sh` to `p4.sh`. Each ran under `timeout 60` with a temp HOME and a temp git project, and nothing was left running. The environment has jq 1.6, bash 5.2.15 and shfmt 3.13.1.
**Tests:** `bats test/auto-approve-allowed-commands.bats` passed 35/35. `bats test/link-claude-home-wiring.bats` passed 16/16.

## Verdict

**Passes, with one Must Address.** Must Fix: 0. Must Address: 1. Consider: 6.

I could not get the hook to emit `allow` for a command outside the allow rules. Every claimed fail-closed case did fail closed. The only stdout the hook produces is the allow JSON. The one Must Address is about routing: the host check that this unit's security trade depends on is not filed anywhere in the repo.

## Must Fix

None.

## Must Address

### MA1. The F3/F4 host check, and the A1 question, have no route in the repo

- **What the branch says:**
  - The plan (`docs/working/plan-q092-drop-hook-deny-reader.md`, rows F3 and F4) says "Live check queued".
  - The ed06dec1 message says "the live check is in the report".
  - The rubric's A1 and C7 notes say "question filed in the unit report" and "live check in the unit report".
- **What I found:** `docs/working/questions.md` on `main`, on `fix/q092a-drop-deny-option` and on this branch has only the original Q-092 entry. No entry covers checking on a host whether Claude Code's deny matcher catches a quote or backslash spelling, or a denied subcommand in a list.
- **Why it matters:** the unit removes a backstop for these cases. Probe p3 runs the main-branch hook against HEAD with deny rules for `*.credentials.json*`, `git push:*`, `cat secret` and `rm -rf:*`:
  - `cat ~/.claude/.cred""entials.json`, `.c\redentials.json`, `git "push"` and `cat "secret"` go from no output on main to `allow` at HEAD.
  - The plain spellings, `cat ~/.claude/.credentials.json`, `git push` and `cat secret`, also become `allow`. For these, Q-082 says Claude Code's deny still wins.
  - In cc-isolated there is no sandbox. Whether the quoted spellings are still stopped now depends entirely on Claude Code's matcher, which nobody has checked. The header, the decision log row and the plan all state this honestly.
- **What to do:** the rubric's qualifying-note rule needs a TODO someone can find, and a "unit report" outside the repo is not one. File a `you: terminal` entry with the exact host commands, and open the A1 question (which values make Claude Code drop a whole settings file) as a `trigger` or `deferred` entry, before or together with the merge.

## Consider

### C1. ROLE's exit-code claim is slightly broader than what happens

Hook lines 51 to 53 say "exit 0 on any input Claude Code sends, 4 or 5 on stdin that is not a JSON object, never 2".

- Probe p1 shows that stdin of `null`, or empty stdin, exits **0**, even though neither is a JSON object.
- `[1]`, `"s"` and `1` exit 5.
- `garbage` and `{"a":1} xx` exit 4.
- These codes come from jq 1.6. I did not check jq 1.7 on a host (this sandbox has no egress).

Nothing here changes a decision. A more precise wording would be "4 or 5 when jq cannot parse or index stdin".

### C2. jq 1.6 accepts a trailing raw NUL byte after the settings object

A file whose bytes are `{"permissions":{"allow":["Bash(ls)"]}}\0` makes the hook approve `ls` (probe p4). JSON.parse would reject that file. I have not checked whether Claude Code rejects it.

This is inside the RESIDUAL the header already states ("anything Claude Code rejects that this check accepts"), and it only matters if someone can write a settings file. If the residual is meant to be narrowed, refusing any settings file that contains a NUL byte is a cheap check. Otherwise it could be listed as an example next to BOM and NaN.

The cases the header names did fail closed:
- a raw NUL inside a string;
- two objects separated by a NUL;
- a raw newline inside a string.

### C3. The rubric's closure line and C14 are stale

- The rubric says `Commit: d6395450` and `Loop closed at d6395450`, but 907f37d2 changed the test file and the rubric after that commit.
- C14's status still says the fix was "a rule in the global file, which jq prints first". C16 records that this did not pin the guard.

I confirmed C16's own claim. With a mutant that keeps jq's partial output:
- the parse-error case still refuses;
- the shape-error case gives `allow`;
- the real hook refuses both (probe p4).

### C4. The row 53 amendment lists what got stricter, but not the one thing that got looser

On main, a non-string deny entry such as `deny:[1]` made the hook refuse everything (DENY_ALL). Now it is skipped.

The 0444b1ac message says so, and the amendment's parenthetical says non-string entries are skipped. It does not say this is looser than before. The change is low risk, because Claude Code reportedly drops such entries too (read from its binary, not run).

### C5. The guide says the hook "does not read deny rules"

`guides/bare-host-hook-wiring.md` line 156 says this, but the hook still parses `permissions.deny` and `.ask` to check their shape, and fails closed on them. "Does not apply deny rules" would match the code and the header's own wording ("shape-checked, never read").

### C6. Pre-existing and out of scope: project settings come from the hook's cwd

`settings_files` takes the project settings from `git rev-parse --show-toplevel` run in the hook's cwd. If a Bash session has `cd`'d into another repo, for example a cloned dependency with its own `.claude/settings.json`, that repo's allow rules approve commands here. Claude Code would use the session project's rules instead.

This unit does not change that, and the deny reader shared the same blind spot. It may deserve its own question once the hook is allow-only.

## Checks that held

- **Only allow or nothing on stdout.** The hook source spells exactly one `permissionDecision`. `debug` writes to stderr. Exit 2 appears only in `check_deps`, which runs only under the `parse_commands` subcommand, and `wiring.json` never calls that (`bash .../auto-approve-allowed-commands.sh` with no arguments). Missing `shfmt` or `perl` leads to no output: the parse fails or extracts nothing.
- **Fail-closed cases (probe p2).** Each of these gave no output, with a valid global allow file next to it:
  - `permissions` set to `null`, `[]` or `"x"`;
  - `allow` set to `null`, `false` or `{}`;
  - `deny` set to `null`, `false` or a string;
  - `ask` set to `null` or `{}`;
  - a NUL inside a string in `deny`, `ask` or `allow` (the case where splitting on NUL would add an allow rule);
  - an empty file, whitespace only, `{}{}`, `[]`, `null`, `//` comments, a trailing comma, bare `nan`;
  - a settings path that is a directory, or a file with mode 000;
  - a malformed project file next to a valid local file;
  - a relative `CLAUDE_CONFIG_DIR`.
- **Inputs that still load, as documented.** These approve:
  - an empty `CLAUDE_CONFIG_DIR` (falls back to `$HOME/.claude`);
  - non-string entries in `deny`, `ask` or `allow` (skipped);
  - duplicate keys, where the last one wins, as in JSON.parse;
  - a dangling symlink, which counts as a missing file.
  
  A BOM and `NaN` inside an array also load, which is the residual the header states.
- **No widening through rule parsing.** `Bash()`, `Bash(:*)`, `Bash( )`, `Bash(*)` and an allow rule containing a newline do not approve `rm -rf x`.
- **`test("\u0000")` on jq 1.6.** It is correct across the empty string, ASCII, a NUL at each position and non-BMP text. `contains("\u0000")` returns true for every string, so the comment about it is accurate.
- **Commit messages.**
  - ed06dec1 says a deny list that is not an array of strings fails closed. That was true at that commit, and 0444b1ac and the rubric's C15 later note it as superseded.
  - ed06dec1's "pinned in unit 1" is correct: the stdout test is already in d27a3891's test file.
  - 52353da8's claim about the test is wrong, as recorded in C16, and 907f37d2 fixes the test.
  - 907f37d2's mutant claim reproduces.
- **Header rule table.** It matches `parse_bash_rule` and `is_command_allowed`, and tests 22 to 25 cover each row.
- **wiring.json.** Only `_comment` changed, and the linker suite passes 16/16.
