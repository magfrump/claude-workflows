Commit: ec9ba0c7

# Code Review Rubric: feat/build-loop-u3b1 (U3b1, --state / --marker)

**Iteration 1 of 3** · scope: full branch `main...ec9ba0c7` (no prior rubric for this loop) · delivery mode: self-read · fact-check k=1 (loop pass, decision 031), opus · report `docs/reviews/code-fact-check-report-u3b1-i1.md` (29 claims: 21 Verified, 4 Mostly Accurate, 3 Incorrect, 1 Unverifiable) · critics (opus, parallel): security, performance, api-consistency, architecture (`*-2026-10-12-u3b1-i1.md`); test-strategy not selected (tests changed with the source).

Status (iteration 1): no 🔴 · 🟡 9 · 🟢 12. B1-B10 fixed in the iteration-1 fix commit; the rest carry override rows dated 2026-10-12. No short-circuit: the one code Incorrect (claim 13) changes a refusal's reason, not its decision, so it is tiered 🟡 under policy T.

## 🔴 Must Fix

None.

## 🟡 Must Address

| ID | Finding | Source | Evidence | Status |
|---|---|---|---|---|
| B1 | A body line `<!-- index:start -->` passes `--marker`; questions.sh's render_index matches it anywhere in a line and truncates the file on the next `index`/`archive` (executed: Q-002, Q-003 lost) | security F1 (Medium) | `scripts/questions.sh:340` index($0, start); `scripts/build-loop.sh` marker rule | Fixed (`--marker` refuses any `<!--` line; questions.sh half: row) |
| B2 | A body that is not valid UTF-8 (written raw with hash-object) passes and fails `questions.sh check` for the whole file | security F2 (Medium) | `scripts/build-loop.sh` marker perl | Fixed (utf8::decode per line) |
| B3 | `--marker` reads the whole untrusted body into memory before cutting it (16 MB body: 16.7 s, 1.16 GB RSS) | performance 1 (Medium) | `my @l = map { s/\n\z//r } <STDIN>` | Fixed (marker commit over 64 KiB skipped unread, `cat-file -s` first) |
| B4 | default_gate's new check compared the ref with the startup MAIN_SHA, so land's re-run reported a concurrently moved main as "names an object that is not a commit" (executed, p6) | fact-check claim 13 (Incorrect, code), architecture 1, api-consistency 1 | `[[ "$(git show-ref --verify --hash "refs/heads/$MAIN" ...)" == "$MAIN_SHA" ]]` | Fixed (the ref's own `cat-file -t`) |
| B5 | `--state`'s help said it runs "before its own git reads"; it does not protect the orchestrator's bare git, and is a snapshot | security F3 (Medium) | header `--state` paragraph | Fixed (text narrowed) + Defer (U4 duty, row) |
| B6 | Two caller plantings exit 1 with stderr only (non-decimal count, GIT_DIR naming no repo), against the plan's ok / refuse-state contract | api-consistency 5, fact-check 4b | `scripts/build-loop.sh` harden, ROOT | Fixed (documented in the header and the plan's as-built note) |
| B7 | The plan's "Script interface" bullets were not updated for what U3b1 built | api-consistency 4 | plan `:207` | Fixed (as-built note supersedes them) |
| B8 | harden's six keys in three copies (harden, caller_gate's regex, help) | architecture 2 (Coupling) | `HARDEN` | Fixed (one `HARDEN` array) |
| B9 | caller_gate refuses by key whatever the value, so a caller hardened like harden fails `--state` | architecture 3 (Coupling) | caller_gate | Defer (row; constraint for U3b3/U4) |

## 🟢 Consider

| ID | Finding | Source | Status |
|---|---|---|---|
| B10 | Text: a GIT_CONFIG_COUNT pair does not override harden (only git -c wins); GIT_GRAFT_FILE / GIT_OBJECT_DIRECTORY move files the state gate reads; BODY_RULE omitted "in any case" and the list markers; the prompt's cap read as a hard rule | fact-check claims 5, 9 (Incorrect, text); api-consistency 2, 3; architecture 5 | Fixed |
| B11 | "Only --state reads the caller's environment" was tested against ungated --settings only; the quoted-form FENCE pass was untested | fact-check claims 26, 27; api-consistency 8 | Fixed (a --check case; a link reference definition inside a balanced fence) |
| B12 | Copy-pasted caller-variable scan in caller_gate and checkout_gate | architecture 4 | Fixed (`stray_vars`) |
| B13 | Bare `ok` from --state | api-consistency 6 | Won't-Fix (row) |
| B14 | One skip shape for three causes | api-consistency 7 | Defer U4 (row) |
| B15 | FENCE_AWK internals read by a third caller | architecture 6 | Defer (row) |
| B16 | BASH_ENV, PATH and other keys pass caller_gate | security F4 | Won't-Fix (row; comment narrowed) |
| B17 | The orchestrator model reading the pasted body | security F5 | Defer U4 (row) |
| B18 | Planted state after --state reaches ungated --marker/--status | security (untested) | Defer U4 (row) |
| B19 | Rows 666, 311, 281 only partly discharged | fact-check claim 24 | Defer U3b3 (row; plan note says so) |
| B20 | Dispatch still runs the full gate startup (row 690) | fact-check 24, performance 4 | Defer (row) |
| B21 | A fourth read of the marker commit | performance 3 | Won't-Fix (row) |

Rows 493/494/517 "close on the flow" (fact-check claim 23, Unverifiable): the plan note now says they close once U4 starts each iteration with `--state`.

## 🧩 Composition check

B4 (fact-check 13, architecture 1, api-consistency 1; default_gate at `scripts/build-loop.sh:543-545` and land `:1385`): distinct defects: no; one root, stated by each fragment already (compare the ref with itself, not with the startup snapshot). No other multi-source co-located cluster qualified.

## Considered overrides

Rows 247, 252, 259, 273, 276, 281, 311, 493, 494, 517, 525, 656, 666, 689, 690, 696 (U3b's revisit triggers) were read; their dispositions are in plan step 9's U3b1 note.

## ⏭️ Skipped Core Critics

None.

## Iteration log

- Iteration 1 (full scope, k=1, full panel): 0 red, 9 amber, 12 green. Fixes mutation-checked (6 mutants killed: the `<!--` rule, the UTF-8 rule, the size cap, the quoted FENCE pass, the HARDEN key match, the tag check). Size 398 changed code lines.
