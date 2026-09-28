Commit: 795ff71

# Security Review — integrate/q077-q078-q080 (Q-077 focus)

**Scope:** `git diff main...HEAD -- . ':!docs/reviews'` at 795ff71. Security surface: `hooks/auto-approve-allowed-commands.sh`, `hooks/wiring.json`, the Q-077 wording in `docs/decisions/log.md` row 53 and `guides/bare-host-hook-wiring.md`, and the tests. Q-078 (report stamps, `.gitignore`) and Q-080 (SKILL.md descriptions) were scanned. Neither crosses a trust boundary a security critic should rule on (see Out of scope).
**Date:** 2026-09-27
**Based on:** `docs/reviews/iter2-code-fact-check-report.md` (Claims 20a–21, 32–37) and the iteration-3 replicates `code-fact-check-report-r1..r3.md`
**Method:** read the whole hook (`:1-697`), then ran probes against the working-tree hook with a scratch HOME and project. The probe scripts are `probe1.sh`, `probe2.sh` and `probe3.sh` in the session scratchpad `sec/`. They are not committed, and every result quoted below is their verbatim output.

## Trust Boundary Map

```
B1: [agent-authored Bash command, prompt-injectable]   → [hook: raw-string deny glob :264, shfmt extraction :290, per-command deny + allow :313-321] → [PreToolUse "allow": Claude Code runs it with no prompt]
B2: [settings JSON: ~/.claude, <git-root>/.claude, .local] → [jq + deny_rules_to_globs :119-149 / extract_prefixes_from_file :92-106]                  → [deny glob list / allow prefix list inside the hook]
B3: [hooks/wiring.json (repo)]                         → [link-claude-home.sh merge into ${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json]                   → [Claude Code permissions.deny + the hook's B2 input]
B4: [hook "allow" decision]                            → [Claude Code permission engine]                                                                        → [does permissions.deny still apply after an allow? unverified, Claim 20b]
```

| Label | Source | Mutability | Trust classification (per sink) |
|---|---|---|---|
| S1 | `tool_input.command` | request-time | UNTRUSTED for every sink: the deny/allow matchers, the shfmt parse and the final exec. It is written by the model, which a prompt injection can steer. |
| S2 | `$HOME/.claude/settings.json` | runtime-mutable. The linker and the user write it; wiring denies the agent Edit/Write on it. | Trusted for rule *content*. UNTRUSTED for *well-formedness* toward the jq parse sink: a hand edit or an interrupted merge can leave it unparseable. |
| S3 | `<git-root>/.claude/settings.json`, `settings.local.json` | runtime-mutable, in the repo, editable by the agent through Edit/Write (guard-trusted-writes asks) | Untrusted toward the allow-list sink (pre-existing). Well-formedness untrusted, as for S2. |
| S4 | `hooks/wiring.json` deny list | code constant | trusted |
| S5 | `HOME`, `CLAUDE_CONFIG_DIR` | deploy-time | Trusted, but the two can disagree on bare hosts (Finding 3). |

S1 decides the outcome. B1 is the boundary that matters. Because B4 is unverified, the hook has to treat its own "allow" as final: any deny rule the hook fails to see or fails to match should be assumed not to apply. The branch adopts exactly that stance, and the findings below are the places where the hook does not fully meet it.

## Findings

#### 1. One unparseable settings file silently drops the deny rules of every settings file read after it, while the allow rules still load

**Severity:** Medium
**Location:** `hooks/auto-approve-allowed-commands.sh:124-149` (compare `:99-105`)
**Boundary:** B2, B1
**Move:** 3 (error path), 5 (invert the access-control model)
**Confidence:** High on the mechanism (executed). Low to Medium on likelihood.
**Legibility-target:** for-author

Evidence:
```
124 extract_deny_from_file() {
125   local file="$1"
126   [[ -f "$file" ]] || return 0
127   jq -r '.permissions.deny[]? // empty' "$file" 2>/dev/null | deny_rules_to_globs
128 }
...
139   {
140     extract_deny_from_file "$HOME/.claude/settings.json"
141     if [[ -n "$git_root" ]]; then
142       extract_deny_from_file "$git_root/.claude/settings.json"
143       extract_deny_from_file "$git_root/.claude/settings.local.json"
...
148   } | sort -u
```
The allow loader keeps going. Its comment explains it was hardened against exactly this abort:
```
 99   # `|| true`: under `set -eo pipefail`, grep exits 1 when a file has no
100   # Bash(...) entries ... which aborted the whole loader before the project files were read.
102   jq -r '.permissions.allow[]? // empty' "$file" 2>/dev/null \
...
105     || true
```
(`get_deny_globs` excerpt ends at `:148`; the enclosing function closes at `:149`, read. Its only consumer is `mapfile -t deny_globs < <(get_deny_globs)` at `:262`, read through to `:332`.)

The hook runs under `set -euo pipefail` (`:63`), and that errexit carries into the `<( )` subshell. When jq fails on a file, the pipeline returns non-zero and the subshell exits. No deny rules from any later file are emitted. `extract_prefixes_from_file` has `|| true`, so the allow prefixes from those same later files still load. The asymmetry fails open. Probe output (`probe3.sh`: the project file allows `Bash(ls:*)` and also denies `Bash(ls:*)` and `Bash(*.credentials.json*)`):
```
global={"permissions":{}}
[DEBUG] Loaded 2 Bash deny rules
[DEBUG] Decision: BLOCK (deny rule; falling through to normal permission check)
global={not json
[DEBUG] Loaded 0 Bash deny rules
[DEBUG] Loaded 1 allowed prefixes
[DEBUG] Decision: ALLOW (all commands passed)
global={"permissions":[]}
[DEBUG] Loaded 0 Bash deny rules
...
[DEBUG] Decision: ALLOW (all commands passed)
```
`probe2.sh` shows the same result for `cat ~/.claude/.credentials.json`: with a malformed global it gets `ALLOW`, and with a malformed project `settings.json` and the deny in `settings.local.json` it also gets `ALLOW`. Fact-check r2 (iter2 Claim 21 dissent line, `:619`) noted that a malformed file contributes no deny rules *of its own*. The loss of *every later file's* rules, with allow rules still loading, is new here.

Attack scenario: a trailing comma left by a hand edit, an interrupted linker merge, or a `"permissions": []` makes the global file fail to parse. In cc-isolated that file holds the wired `Bash(*.credentials.json*)`. From then on the hook approves any allow-listed command, credentials path included, and Claude Code's own handling of the rule after an allow is unverified (B4). Nothing reports the failure: jq's stderr goes to `/dev/null`. The agent cannot write the global file directly, since wiring denies Edit/Write on `settings*.json`. The realistic trigger is therefore an accident, not an attack. That is why the severity is Medium and not higher. The floor rule applies: the mechanism is concrete and reachable.

**Recommendation:** Make the deny loader fail closed. If an existing settings file fails to parse, emit `*` so the hook never approves: `jq ... "$file" 2>/dev/null || { echo '*'; return 0; }` feeding `deny_rules_to_globs`, or a sentinel that `main` treats as "fall through". Add one bats case per failure shape: invalid JSON, `permissions` as an array, invalid JSON in `settings.json` with the deny in `.local`.

#### 2. Per-command deny matching compares against the quote-preserving reconstruction, so a deny rule narrower than an allow rule is bypassed by quoting one word

**Severity:** Medium
**Location:** `hooks/auto-approve-allowed-commands.sh:313-321`, with the rendering at `:441-455`
**Boundary:** B1, B4
**Move:** 11 (enumerate bypasses)
**Confidence:** High on the mechanism (executed). Low on present exposure: no live settings in this repo hold a command-prefix Bash deny rule under a broader allow.
**Legibility-target:** for-author

Evidence:
```
444   elif .Type == "DblQuoted" then
445     "\"" + ([.Parts[]? | get_part_value] | join("")) + "\""
446   elif .Type == "SglQuoted" then
447     "'" + (.Value // "") + "'"
448   elif .Type == "ParamExp" then
449     "$" + (.Param.Value // "")
...
313     if matches_deny "$full_command" deny_globs; then
314       all_allowed=false
315       break
316     fi
318     if ! is_command_allowed "$full_command" allowed_prefixes; then
```
(Excerpt ends at `:318`; the loop closes at `:322`, and `main` continues to `:332`, read.)

The extracted string keeps the author's quotes and backslashes, and it renders `${X:-push}` as `$X`. The deny glob is a literal string match. Take allow `Bash(git:*)` with deny `Bash(git push:*)`. The shell runs `git push` in every case below, but the deny glob `git\ push*` misses all of these extracted strings except the first. `is_command_allowed` still sees the `git ` prefix and approves. `probe1.sh` / `probe3.sh`:
```
fall  rc=0 :: git push origin main
ALLOW rc=0 :: git "push" origin main
ALLOW rc=0 :: git 'push' origin main
ALLOW rc=0 :: git \push origin main
ALLOW rc=0 :: git pu""sh origin main
ALLOW rc=0 :: echo ok && git "push" origin
[DEBUG]   - git $X [DEBUG] Decision: ALLOW ...  <= git ${X:-push}
```
The raw-string check at `:264` does not catch these either, because the raw text is not `git push…`. The docs describe string matching only through the credentials rule ("quotes split inside the name"). They do not say that *every* command-prefix deny rule a user writes is bypassable this way. If Claude Code's own matcher normalises quotes, which is likely but unverified, then the hook's "allow" is the only thing between `git "push"` and execution (B4). The branch does not regress anything: before it, the hook ignored deny rules entirely. But this is the shape a user's deny rules most often take.

**Recommendation:** Deny matching can safely over-match, so also match each deny glob against a dequoted rendering: strip `"`, `'` and backslashes from `Lit`/`SglQuoted`/`DblQuoted` parts, and render a `ParamExp` default word inline. Otherwise fall through whenever any deny rule exists and an extracted command contains a quote, a backslash or a `$` within its first words. State in the header and the guide that the string-match limit applies to all Bash deny rules, not only the credentials one.

#### 3. The hook reads `$HOME/.claude/settings.json`, but the linker merges the deny rule into `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json`

**Severity:** Medium
**Location:** `hooks/auto-approve-allowed-commands.sh:140` against `devcontainer-config/link-claude-home.sh:36`
**Boundary:** B3, B2
**Move:** 1 (trace the trust boundaries)
**Confidence:** Medium. The result is executed; the exposure depends on bare hosts that set a non-default `CLAUDE_CONFIG_DIR`. It is not reachable in cc-isolated, where `devcontainer.json:84` sets `"CLAUDE_CONFIG_DIR": "/home/node/.claude"`.
**Legibility-target:** for-author

Evidence:
```
140     extract_deny_from_file "$HOME/.claude/settings.json"
```
```
36 DEST="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
```
`probe2.sh`, with the deny in `$CLAUDE_CONFIG_DIR/settings.json`, an empty `~/.claude/settings.json` and a project allow for `cat`:
```
ALLOW :: CLAUDE_CONFIG_DIR case
```
`wiring.json` explicitly supports a config dir other than `~/.claude` (`_comment`: "the token has to survive a config dir that is not ~/.claude"), and `scripts/health-check.sh:576` already reads `${CLAUDE_CONFIG_DIR:-$HOME/.claude}`. On such a host the wired `Bash(*.credentials.json*)` rule never reaches the hook, yet `guides/bare-host-hook-wiring.md` says the hook "never approves" a match. The same path mismatch already existed for the allow list, but there it fails safe (fewer approvals). For the deny list it fails open.

**Recommendation:** Read `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json` in `get_deny_globs`, and in `get_allowed_prefixes` for consistency. Add a bats case that sets `CLAUDE_CONFIG_DIR`.

#### 4. The Q-077 docs state the hook guarantee categorically

**Severity:** Low
**Location:** `guides/bare-host-hook-wiring.md:151`; `hooks/wiring.json` `_comment` ("reads Bash deny rules and never approves a match"); `hooks/auto-approve-allowed-commands.sh:46-47`
**Boundary:** B1, B2
**Move:** 5
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Evidence:
```
+  It never approves a command that matches a `Bash(...)` deny rule, so the wired
+  `Bash(*.credentials.json*)` backstops the credentials file where no sandbox runs
```
Findings 1 and 3 are cases where the hook approves a command that literally contains a denied string. Finding 2 is a case where it approves a command the rule's author would consider matched. The docs are otherwise honest about the credentials rule's limits: the hook header says "They stop the literal spelling, not a determined injection", and row 53 records the missing sandbox. So this is a scoping problem, not a misrepresentation of the threat model.

**Recommendation:** Scope the sentence. For example: "never approves a command whose raw text or extracted text contains a denied string, given that every settings file parses and lives under `$HOME/.claude` / the git root". Once Findings 1 and 3 are fixed, only the quoting caveat from Finding 2 remains to state.

#### 5. Residual accepted risk: in cc-isolated a determined injection still exfiltrates through any auto-approved command

**Severity:** Informational
**Location:** `docs/decisions/log.md` row 53 amendment; `hooks/auto-approve-allowed-commands.sh:50-54`
**Boundary:** B1
**Move:** 6 (follow the secrets)
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Evidence (hook header):
```
50 # Deny rules are string matches: `.cred""entials.json`, `~/.claude/.c*`, a
...
53 # spelling, not a determined injection. The quote-split, glob and variable
```
Probes confirmed further non-literal spellings with the same result. They all get `ALLOW` when `cat` is allow-listed: `.c\redentials.json`, `.credentials.jso[n]`, `.credentials.js{on,}`, `$'\x2e'credentials.json`. Reading the parent directory without naming the file (for example an archive of `~/.claude`) is the same class. Decision 55 records that base egress admits attacker-editable hosts, such as gists. So once the Q-077 changes land, cc-isolated still has no control that stops a prompt-injected agent from exfiltrating the token through an auto-approved command. The deny rule only removes the one-line literal. The documents say so, and the user accepted it (Q-070 [1]). This entry records that the sandbox follow-up is the actual fix, and that the residual should stay visible in the open question rather than be read as closed by Q-077.

**Recommendation:** None in this diff. Keep the sandbox follow-up question open. Consider cutting the auto-approve allow list in cc-isolated down to commands that cannot read arbitrary files or reach the network.

### Untested bypass candidates

- **Claude Code's own matcher for `Bash(*.credentials.json*)`**: leading `*`, compound commands, quote normalisation. Not testable offline: no live Claude Code session. Routed with Claim 20b.
- **Whether Claude Code re-applies `permissions.deny` after a hook `allow` (B4).** Same reason. If it does, Findings 1–3 fall to defence in depth.
- **Case-insensitive filesystems on bare macOS hosts** (`.CREDENTIALS.json` reaches the same file). On Linux the probe gives `ALLOW`, but it names a different file there. Not tested on APFS, and macOS Claude Code keeps credentials in the Keychain, so it may not apply.
- **Hook process cwd after the agent `cd`s into another git repo.** The hook reads `<git-root of cwd>/.claude/settings*.json` (`:138-146`). If Claude Code runs hooks in the Bash tool's current directory, a repo the agent created could supply its own allow list. This is pre-existing and allow-side, not in this diff. Not tested: it needs the live harness.

### Bypass candidates tested (dispositioned)

| Candidate | Result | Disposition |
|---|---|---|
| Literal name after invalid UTF-8 bytes (`\xff\xfe`), under C and C.UTF-8 locales | fall | cleared |
| Literal name on the second line (newline inside the command) | fall | cleared: bash `*` matches `\n` |
| Literal name after a 400 KB prefix | fall, 0 s | cleared |
| Backslash-newline split (`.credentials\⏎.json`) | fall | cleared (shfmt joins the line) |
| `\.credentials.json` | fall | cleared: the raw text contains the literal |
| Quote/backslash/brace/bracket/ANSI-C spellings | ALLOW | documented class (Finding 5) |
| Command-prefix deny under a broader allow, quoted | ALLOW | Finding 2 |
| Malformed or ill-shaped earlier settings file | ALLOW | Finding 1 |
| `CLAUDE_CONFIG_DIR` ≠ `~/.claude` | ALLOW | Finding 3 |
| Deny rule with a trailing or inner space (`"Bash(*.credentials.json*) "`) | ALLOW (rule dropped) | Not filed: how Claude Code parses such a rule is unknown. Note only. |
| `--deny 'not-json'` / `--deny '[]'` | ALLOW (zero deny rules) | Cleared for production: `wiring.json` passes no arguments, and changing them needs settings write access, which already grants more. A test-only option that fails open on bad JSON. |
| `--deny` with no value | `$2: unbound variable`, rc=1, fall-through | cleared (non-blocking error) |
| Bare `Bash`, `Bash(*)`, `Bash(**)`; `?`/`[...]` literal | fall / literal | cleared (fact-check Claims 20c, 36) |

## Endorsement Claims

- **Claim:** The raw-command deny check at `:264` runs before both `allow` emitters (`:304`, `:326`). A command whose raw text contains a denied literal therefore falls through, including when extraction is empty or misses a construct (`$(( ))`, heredoc, assignment-only).
  **Location:** `hooks/auto-approve-allowed-commands.sh:262-306`
  **Evidence:** executed
  **Verified:** read `main` in full (`:218-332`). Probes: newline, long input, invalid bytes and the `$(( ))` repro all fall through once the deny list loaded.
  **Not verified:** the deny list's loading itself, which fails open (Finding 1 and Finding 3 paths).
  **route: code-fact-check** (already verdicted in iter2 Claim 33)
- **Claim:** `deny_rules_to_globs` backslash-escapes every character except `[A-Za-z0-9*]` before the unquoted `==` at `:161`, so only `*` works as a wildcard.
  **Location:** `hooks/auto-approve-allowed-commands.sh:119-122, 154-167`
  **Evidence:** executed
  **Verified:** the `?` and `[1]` literal probes (fact-check Claims 20c and 36) and the extglob characters in the escape class.
  **Not verified:** rules containing non-ASCII bytes when sed and bash run under different locales (sed escapes byte-wise under C).
  **route: code-fact-check**

## Primitive sweep

Primitive: glob pattern matching of S1-derived strings (unquoted `==` right-hand side / regex)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `hooks/auto-approve-allowed-commands.sh:161` `[[ "$str" == $glob ]]` | S1 against S2/S3 rules | `deny_rules_to_globs` escaping | cleared for the match itself. Findings 1–3 concern what reaches it. |
| `:208` `[[ "$full_command" == "$allowed "* ]]` | S1 against S2/S3 | right-hand prefix quoted | cleared (pre-existing, literal prefix) |
| `:592-606` `get_shell_c_inner` regexes | S1 | none | not analysed: pre-existing, not in the diff |

Primitive: JSON parse of settings files (jq)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `:127` deny extraction | S2/S3 | `2>/dev/null`, no status handling | Finding 1 |
| `:102-105` allow extraction | S2/S3 | `\|\| true` | Cleared as fail-safe per file. It is the asymmetry partner in Finding 1. |
| `:134` `--deny` JSON | test argument | none | cleared (test-only, see table above) |

No exec, eval, deserialisation-to-code or network primitive is introduced by the diff. The hook never executes S1, and `test/auto-approve-allowed-commands.bats` stubs `curl` with a recording shim.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---|---|---|---|---|
| 1 | An unparseable settings file drops later files' deny rules while their allows still load | Medium | B2, B1 | `hooks/auto-approve-allowed-commands.sh:124-149` | High (mechanism) |
| 2 | Quote/backslash/`${X:-…}` spellings bypass command-prefix deny rules under a broader allow | Medium | B1, B4 | `hooks/auto-approve-allowed-commands.sh:313-321, 441-455` | High (mechanism), Low (exposure) |
| 3 | The hook reads `$HOME/.claude`; the linker writes `$CLAUDE_CONFIG_DIR` | Medium | B3, B2 | `hooks/auto-approve-allowed-commands.sh:140` | Medium |
| 4 | The docs state "never approves a match" categorically | Low | B1, B2 | `guides/bare-host-hook-wiring.md:151` | High |
| 5 | Residual: a determined injection still exfiltrates in cc-isolated (accepted) | Informational | B1 | `docs/decisions/log.md` row 53 | High |

## Overall Assessment

The Q-077 change strictly improves on main. Before it the hook ignored Bash deny rules entirely. Now a command whose raw text contains a denied literal cannot be auto-approved once the deny list has loaded, and the reproduction from the review falls through as claimed. The problems are fixable in place and are not architectural. They sit in *loading* the deny list and in *which string* it is compared against. The deny side inherited the allow side's fail-safe-by-omission patterns, but for deny rules those patterns fail open. Fix Finding 1 first. It is a one-line fail-closed change, and it is the only path by which an accident, not an adversary, silently disables the wired credentials backstop in cc-isolated. After that, fix Finding 3 (path) and then Finding 2 (dequoted matching), and scope the doc sentence (Finding 4). The larger residual (Finding 5) is honestly documented and belongs to the sandbox follow-up. No findings are raised beyond these within the code paths read. The endorsement claims are pending or already carry execution verification (iter2 Claims 33, 36). Claude Code's own behaviour at B4 is unverified, and it decides whether Findings 1–3 are the last line of defence or defence in depth.

## Goal-Alignment Note

- **Success criterion (restated verbatim):** "A markdown report saved to /workspace/docs/reviews/security-review-2026-09-27.md, structured per the security-reviewer skill, with a Goal-Alignment Note."
- **Answered:**
  - Every focus question in the dispatch was probed by execution: extraction gaps, encoding, locale, newlines, long input, parse-failure paths, `--deny`, malformed settings JSON.
  - `wiring.json` was reviewed.
  - Whether the Q-077 docs overclaim the boundary is answered by Finding 4 (scoped overclaim) and Finding 5 (the residual is honestly stated).
- **Out of scope:**
  - Q-078 (`runner-contract.bash` stamp and `.gitignore` admits). Hashing less input makes staleness detection weaker, not an access-control boundary. The accepted cost is documented. No secrets or exec paths change.
  - Q-080 SKILL.md descriptions. These are routing prose. The one security-adjacent risk is a critic no longer auto-triggering, and that is a routing-coverage question for the api-consistency / fact-check critics, not a trust boundary.
  - Q-076 (not on this branch).
  - Pre-existing extraction gaps accepted in row 53.
- **Escalate:**
  - B4, whether Claude Code honours `permissions.deny` after a hook `allow`, needs one live host check. It sets the real severity of Findings 1–3.
  - The hook-cwd allow-list question (untested candidate 4) is pre-existing but may deserve its own question entry.
- **Decisions I made:**
  - Rated Findings 1–3 Medium under the floor rule (named mechanism, reachable environment), with likelihood carried in Confidence.
  - Did not file the trailing-space rule as a finding, because Claude Code's parse of it is unknown.
