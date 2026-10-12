Commit: 5e816c5b
Loop closed at 5e816c5b

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

## Iteration 2 (scope `ec9ba0c7..91659c66`, loop pass, k=1; short-circuited at fact-check)

Fact-check `docs/reviews/code-fact-check-report-u3b1-i2.md`: 24 claims, 19 Verified, 2 Mostly Accurate, 3 Incorrect (1 behavioural). Critics skipped: loop-pass short-circuit (behavioral red confirmed); build-loop.sh is not an enforcement file. Prior B1-B8: B1, B3-B8 resolved; B2 partly open (C1).

| ID | Finding | Tier | Source | Status |
|---|---|---|---|---|
| C1 | The UTF-8 rule used Perl's decoder, which takes surrogates, code points past U+10FFFF and 5-byte sequences that questions.sh check refuses (B2 still reachable) | 🔴 behavioural | fact-check claim 7b (Incorrect) | Fixed 8367359f (strict match; raw-commit tests; mutant killed) |
| C2 | "skipped unread": the body was read before the cap test, and marker_kind reads the commit anyway | 🟡 (text) | claim 15 (Incorrect, text) | Fixed (cap before the read; text) |
| C3 | B4's description named only the compare-and-swap; no test pinned B4 | 🟡 | claim 14 (Mostly Accurate) | Fixed (text; merge-suite case; mutant killed) |
| C4 | --state's exit-1 list: an existing non-repo GIT_WORK_TREE refuses with exit 2 | 🟢 | claim 9 (Mostly Accurate) | Fixed (text) |
| C5 | Override row rationale "capped at 64 KiB" for marker_kind's reads | 🟢 | claim 4 (Incorrect, text) | Fixed (row text) |

Commit-body corrections owed in the merge message: 8f99a919 says "valid UTF-8" and "skipped unread".

## Iteration 3: final confirming pass (full branch `main...5e816c5b`, k=3 fact-check, full panel, opus)

Fact-check merged `docs/reviews/code-fact-check-report-u3b1-final.md` (r1 31, r2 40, r3 32 claims): 0 behavioural Incorrect; 1 Incorrect cluster (ec9ba0c7 and 8f99a919 commit-body text), 4 Mostly-accurate clusters (help and plan text), 2 Unverifiable. Critics (`*-2026-10-12-u3b1-final.md`): security 1 Low; performance 1 Informational + 1 outside lane; api-consistency 1 Minor + 1 Informational; architecture 0 red, 0 amber, 5 green. Prior B1-B21 and C1-C5: resolved or settled by their rows (critics re-checked; none re-filed). Stage 2.5: the routed endorsements (count check before any git call, caller-pair precedence, every printed line `>`-led, quoted body cannot open a fence, default_gate on a tag) were each executed by at least one final fact-check replicate or critic probe and are Verified there; no ✅ rows are claimed beyond them.

Status: **0 🔴 · 0 🟡 · 🟢 12** — single-sample review; absence of findings is not an attestation.

| ID | Finding | Source | Status |
|---|---|---|---|
| D1 | ec9ba0c7's body: GIT_GRAFT_FILE and the object directories "never read"; 8f99a919's body: "skipped unread", "valid UTF-8", CAS only | fact-check cluster 1, 2 (Incorrect, commit text) | Corrected in the merge message |
| D2 | --state's exit-1 list incomplete | fact-check cluster 3; api-consistency 1 | Fixed (text: "when a caller's git setting stops git or the script first ..."; plan names U4's rule) |
| D3 | Header: FENCE_AWK reads the body "as written" | fact-check cluster 4 | Fixed (text: "as printed") |
| D4 | Plan: "anything but a commit" | fact-check cluster 5 | Fixed (text: an annotated tag) |
| D5 | U3b3's git_harden has no recorded contract for HARDEN and CALLER_COUNT | architecture 1 | Fixed (plan's U3b3 bullet) |
| D6 | U3b2 should say whether --main-log is gated | architecture 5 | Fixed (plan's U3b2 bullet) |
| D7 | scrub's 4096-byte cut splits a character, skipping a long valid line | performance (outside lane) | Defer (row) |
| D8 | Strict UTF-8 regex recursion limit | performance 1 | Defer (row) |
| D9 | Pasted body becomes the index summary; `\|` shifts cells | security 1, api-consistency 2 | Defer U4 (row) |
| D10 | HARDEN key marked by a trailing blank | architecture 2 | Won't-Fix (row) |
| D11 | BODY_RULE and its regex are two literals | architecture 3 | Defer (row) |
| D12 | Help lists HARDEN's keys as prose | architecture 4 | Won't-Fix (row) |

## 🧩 Composition check

B4 (fact-check 13, architecture 1, api-consistency 1; default_gate at `scripts/build-loop.sh:543-545` and land `:1385`): distinct defects: no; one root, stated by each fragment already (compare the ref with itself, not with the startup snapshot). No other multi-source co-located cluster qualified.

## Considered overrides

Rows 247, 252, 259, 273, 276, 281, 311, 493, 494, 517, 525, 656, 666, 689, 690, 696 (U3b's revisit triggers) were read; their dispositions are in plan step 9's U3b1 note.

## ⏭️ Skipped Core Critics

None.

## Iteration log

- Iteration 3 (final, full branch, k=3, full panel): 0 red, 0 amber; text fixes after it (D2-D6) are docs and help comments, checked by the lite fix-drift reviewer; loop closed at 5e816c5b.
- Iteration 2 (fix range, k=1, short-circuited at fact-check): 1 behavioural red (C1), fixed with C2-C5 in 8367359f; 399 lines.
- Iteration 1 (full scope, k=1, full panel): 0 red, 9 amber, 12 green. Fixes mutation-checked (6 mutants killed: the `<!--` rule, the UTF-8 rule, the size cap, the quoted FENCE pass, the HARDEN key match, the tag check). Size 398 changed code lines.
