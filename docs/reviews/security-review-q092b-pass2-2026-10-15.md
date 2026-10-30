Commit: c9ff3e84

# Security Review — Q-092 unit 2, loop pass 2 (q092b, fix/q092-drop-hook-deny-reader)

**Scope:** delta `git diff ed06dec1..c9ff3e84 -- hooks/ test/ docs/decisions/` (merges of unit 1 are context): SETTINGS_RULES_JQ, header ROLE / DENY RULES / FAILS CLOSED / rule table, the bats deltas, decision log row 53.
**Date:** 2026-10-15
**Based on:** docs/reviews/security-review-q092b-2026-10-15.md (pass 1), docs/reviews/code-review-rubric-2026-10-15-fix-q092-drop-hook-deny-reader.md, docs/reviews/code-fact-check-report-q092b-pass2-2026-10-15.md

## Trust Boundary Map

```
B1: [model-authored Bash command]                    → [shfmt + refuses_construct, is_command_allowed] → [hook stdout "allow"]
B2: [settings files: global, project, project-local] → [read_settings_rules: SETTINGS_RULES_JQ, jq exit status via wait $!] → [ALLOW_PREFIXES]
B3: [same settings files]                            → [Claude Code's own parser + schema (may drop a whole file)] → [CC allow/deny/ask rules]
B4: [hook stdout]                                    → [Claude Code permission engine (deny applied after hook allow, Q-082)] → [execution]
```

```
S1: tool_input.command              — request-time    — UNTRUSTED (all sinks)
S2: settings files (global/project) — runtime-mutable — UNTRUSTED for the approve decision (project files model-writable via Edit/Write)
S3: --permissions CLI arg           — deploy-time     — test-only
```

The delta tightens B2 so that a file whose `permissions`, `allow`, `deny` or `ask` has a shape Claude Code would reject feeds no allow rules. The security property at stake is agreement between B2 and B3: any file B3 drops but B2 reads lets the hook approve from allow rules whose sibling deny rules Claude Code no longer applies.

## Pass-1 findings: fix verification

| Pass-1 finding | Rubric says | Verified |
|---|---|---|
| 1 (Medium): whole-file drop family; hook still approved from a file with a non-string allow entry, `deny: null/false`, or any `ask` | A1 Fixed in part; residual stated | Yes for the named cases. Each of `{"permissions":null}`, `deny: null`, `deny: false`, `allow: [5]`, `allow: null`, `ask: "Bash"`, `ask: [1]` is in the "wrong shape fail closed" loop; I also ran the filter directly on `allow` containing an object and on NUL in allow/deny (all `error`, jq exit 5). The remaining part is stated as a RESIDUAL at `hooks/auto-approve-allowed-commands.sh:80-82`, plan F6/F6b and row 53. |
| 2 (Low): version drift / Q-082 version | A3 Fixed | Yes. ROLE (header :55-59) carries the Q-091 2.1.284 note, `@latest`, and a re-test trigger; row 53 points at it. |
| api-consistency A2: NUL in deny no longer failed closed | Fixed | Yes; new test "a NUL inside a settings deny or ask rule fails closed" plus my direct probe. |

## Probes of the new filter (move 11)

Ran the extracted SETTINGS_RULES_JQ (jq 1.6, the version in this image) under `timeout`, and Node's `JSON.parse` on the same bytes as a stand-in for Claude Code's parser.

**Can it emit an allow record for a file it should reject?**
- Error ordering within one file: the comma's left branch (`["allow","deny","ask"][] ... error`) runs to completion before `(.allow // [])[]`, so a bad deny/ask errors before any allow from that file is emitted. Tested.
- Multiple files: good file then bad file (`{"permissions":{"ask":5}}`) prints the first file's record and then errors, jq exit 5. `load_rules` discards all records when `wait $!` fails (`return 0` before the add loop; read in full, :225-240). Tested at the jq level; the bats "wrong shape" loop exercises it end to end with a good project file and a bad global file.
- `has` on non-objects: `has("permissions")` runs only after `type != "object"` errors; `has($k)` runs only in the object branch. No `has` on an array/scalar is reachable. Read-static, consistent with probes.
- Duplicate keys: `{"permissions":5,"permissions":{...}}` and `{"deny":"bad",...,"deny":[]}`: jq takes the last value, as `JSON.parse` does. Agree. Tested.
- Deep nesting (5000 and 20000 levels, in an unchecked key and inside `deny`): jq 1.6 "Exceeds depth limit for parsing" → exit non-zero → fail closed. Tested.
- Huge value: a 50 MB string in `deny` took about 35 s and then emitted the allow record. The new `explode` now also runs over deny/ask strings, but the old filter already exploded allow strings, so the cost class is not new; a hook timeout yields no decision, i.e. the prompt. Cleared (fails safe; also needs a writer of S2).
- `permissions.allow` non-string entries were previously skipped and are now an error: stricter, fails closed.

**Does it reject a legitimate file Claude Code accepts?** `{"permissions":{}}`, no `permissions`, `ask` absent, empty arrays, `additionalDirectories` + `defaultMode` all pass (and a non-string `defaultMode` passes, which is the stated residual). A lone surrogate `"\ud800"` elsewhere in the file is rejected by jq 1.6 but accepted by `JSON.parse`: that over-rejects toward the prompt, which is the safe direction.

**Parser divergence in the unsafe direction:** jq 1.6 accepts a UTF-8 BOM, and the literals `nan`, `NaN` and `Infinity` anywhere in the file, and emits the allow rules; `JSON.parse` rejects all four. See Finding 1.

## Findings

#### 1. The RESIDUAL statement names a BOM but not the other parser divergences: jq accepts `nan`/`NaN`/`Infinity`

**Severity:** Informational
**Location:** `hooks/auto-approve-allowed-commands.sh:80-82`; plan F6b; decision log row 53
**Boundary:** B2, B3
**Move:** 11 (bypass enumeration), 7 (serialization boundary)
**Confidence:** Medium (Claude Code's exact settings parser was not traced; `JSON.parse` is the stand-in)
**Legibility-target:** header FAILS CLOSED / RESIDUAL

**Evidence:** "RESIDUAL: a value the hook does not check (another key, a BOM) can still make Claude Code drop the file, and its deny rules with it, while its allow rules approve here". Probe: `{"permissions":{"allow":["Bash(curl:*)"]},"x":nan}` → filter output `Bash(curl:*)`; `JSON.parse` → SyntaxError. Same for `NaN`, `Infinity`, and a leading BOM.

This is the same mechanism the residual already accepts (a file Claude Code drops but the hook reads), not a new one, so it is not rated as a bypass. But "a value the hook does not check" reads as a schema-level value; a reader would not infer that a file which is not even valid JSON to Claude Code still feeds allow rules here. The fix is wording only: name the class as "anything Claude Code rejects that jq 1.6 accepts (another key's value, a BOM, a `nan`/`Infinity` literal)". If closing it is wanted, pre-checking the raw bytes for a BOM is cheap, but `nan` would need a stricter parser; I do not recommend code for this, since the realistic writer of a project settings file can already add allow rules Claude Code honours.

**Recommendation:** Widen the residual's parenthetical to the parser class, in the header, F6b and row 53.

## Is the residual statement honest?

Yes, with Finding 1's wording gap. It states the direction correctly (the file's deny rules are lost while its allow rules approve here), says the old reader covered it, and the plan's F6 row is marked "Partly covered" rather than "Covered". The exposure it describes requires a settings file to be malformed in a way Claude Code rejects; for the shipped deny rule (global settings), that means the global file itself, which the model cannot write through Bash (guard-trusted-writes refused even my probe script that named the path) — a likelihood note, not a trust argument. Row 53's summary of the new check omits "`permissions` must be an object", which the header and tests do state; not worth a finding.

### Untested bypass candidates
- Claude Code's actual settings loader (whether it strips a BOM, uses a JSON5/lenient parser, or validates per key rather than per file). Not traced: the binary was not inspected this pass; the pass-1 review and fact-check C10 already carry this as a queued question. If CC is lenient where jq is, Finding 1 shrinks.
- jq 1.7+ (a future image) parsing differences, e.g. its handling of `nan` and of the depth limit. Not available here.

## Endorsement Claims

- **Claim:** For one settings file, SETTINGS_RULES_JQ emits no allow record when `permissions` is present and not an object, or when `allow`, `deny` or `ask` is present and not an array of NUL-free strings; across files, any such error discards every record.
  **Location:** `hooks/auto-approve-allowed-commands.sh:146-161`, `:225-240`
  **Evidence:** executed
  **Verified:** direct jq probes listed above (exit 5, records discarded by `load_rules` on `wait` failure, read in full); bats suite 34/34 at c9ff3e84 including the extended wrong-shape loop and the deny/ask NUL test.
  **Not verified:** the hook process under a real Claude Code session with such a file (bats drives the hook directly).
  **route: code-fact-check**
- **Claim:** The new filter accepts the legitimate shapes probed (`permissions: {}`, absent `ask`, `additionalDirectories`, `defaultMode`, empty arrays).
  **Location:** `hooks/auto-approve-allowed-commands.sh:146-161`
  **Evidence:** executed
  **Verified:** direct jq probes.
  **Not verified:** Claude Code's schema for other keys under `permissions` (e.g. `disableBypassPermissionsMode`), which the filter ignores.

## Primitive sweep

Primitive: jq over S2 (parse of untrusted files)
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `hooks/auto-approve-allowed-commands.sh:191` `jq -nj "$SETTINGS_RULES_JQ" files --args files` | S2 | program is a constant; files passed as arguments, newline-in-path refused, exit status checked via `wait $!` | Finding 1 (parser divergence, wording); otherwise cleared |
| `:233-236` `jq -j` over `--permissions` | S3 | test-only | unchanged; cleared |

No other dangerous primitive changed in the delta.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | RESIDUAL names a BOM but not `nan`/`NaN`/`Infinity`, which jq 1.6 accepts and `JSON.parse` rejects | Informational | B2, B3 | `hooks/auto-approve-allowed-commands.sh:80-82` | Medium |

## Overall Assessment

The pass-1 Medium is fixed as the rubric says: every named shape now fails closed, error ordering and multi-file handling cannot leak an allow record (records are discarded on any jq failure), `has` is never reached on a non-object, deep nesting fails closed, and the legitimate settings shapes probed still load. The one gap is wording: the residual's examples cover a BOM but not the other jq-accepts/JSON-rejects literals. No findings above Informational within the code paths read; endorsement claims pending execution verification against a live Claude Code session.

## Goal-Alignment Note

The goal is one interpreter per deny rule (Claude Code), with the hook never emitting `ask` and never feeding allow rules from a file Claude Code would drop. The delta moves the hook's acceptance closer to Claude Code's for the `permissions` keys and states the remainder honestly; Finding 1 only asks that the remainder be named as a parser class.
