Commit: ef0471c (A) / 5e8bfd9 (B)

# Code Fact-Check Report

**Repository:** claude-workflows — A: `/workspace/.claude/wt-digest` (feat/dev-cycle-digest, HEAD ef0471c); B: `/workspace/.claude/wt-devcycle` (feat/dev-cycle, HEAD 5e8bfd9)
**Scope:** Partial (this round's fixes only). A: `git diff 28c6178..ef0471c -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` plus commit message ef0471c. B: `git diff c079e8c..5e8bfd9 -- skills/dev-cycle/SKILL.md docs/decisions/log.md guides/skill-creation.md docs/dev-cycle.md docs/dev-cycle-sources.md workflows/codebase-onboarding.md` plus commit message 5e8bfd9. Everything else on both branches is context only (reviewed in final passes 1–5).
**Checked:** 2026-10-01 (executions timestamped 2026-10-02T03:51–03:55Z UTC)
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 42 (40 numbered; 15 and 30 split into a/b)
**Summary:** 29 verified, 7 mostly accurate, 0 stale, 6 incorrect, 0 unverifiable

Execution logs (scratch, not committed): `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/fc6/logs/` — referred to below as `fc6/logs/`. Probe inputs and the extracted scrub variants (`scrub-new.sh` = the function at ef0471c verbatim; `scrub-nocut.sh` = the same minus the cut line; `oldcut.sh` = 28c6178's `1 while s///g` loop plus the new cut, PERLIO removal and binmode; `scrub-old.sh` = 28c6178 verbatim) are in the parent `fc6/` directory. All probes ran under `timeout` in `mktemp -d` dirs; no process left running.

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`). The relevant prior pattern is test-tally claims in commit messages ("All 85 tests…", "mode1-equiv 33"); this round's "20/20" and "tests 5, 19 and 20 fail on 28c6178" were executed and do not repeat it.

---

## Claim 1: "drops C0 controls but TAB and LF, DEL, C1 controls (U+0080-009F), bidi controls (U+200E/F, U+202A-202E, U+2066-2069) and tag characters (U+E0000-E007F)"

**Location:** `scripts/dev-cycle.sh:25-27`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the byte classes deleted by the scrub for well-formed UTF-8 encodings of the listed ranges, on random and nested input; does not establish handling of the "Not covered" classes (claim 6) or terminal-side rendering.

```perl
# scripts/dev-cycle.sh:41-45
    tr/\000-\010\013-\037\177//d;
    my $i = 0;
    while (1) {
      pos($_) = $i;
      last unless /\xC2[\x80-\x9F]|\xE2\x80[\x8E\x8F\xAA-\xAE]|\xE2\x81[\xA6-\xA9]|\xF3\xA0[\x80\x81][\x80-\xBF]/g;
```
(excerpt ends :45; enclosing loop continues to :49 and the perl program to :50 — read)

The encodings match the ranges: U+0080-009F = `C2 80-9F`; U+200E/F = `E2 80 8E/8F`; U+202A-202E = `E2 80 AA-AE`; U+2066-2069 = `E2 81 A6-A9`; U+E0000-E007F = `F3 A0 80-81 80-BF`. `tr` keeps `\011` (TAB) and `\012` (LF). Executed: 250,000 fuzz lines (random bytes over the relevant alphabet, and nested insertions of every sequence) leave zero residual matches of the C0/DEL/C1/bidi/tag pattern.

Command: `bash -c 'source ./scrub-new.sh; scrub < fuzz-in.txt > fuzz-new.txt'` (and fuzz2), then a residual-match perl one-liner; cwd `fc6/`; exit 0; 2026-10-02T03:55:22Z. Bats test 5 also passes at ef0471c.

**Evidence:** `scripts/dev-cycle.sh:36-51`, `fc6/logs/fuzz.txt`, `fc6/logs/bats-ef0471c.txt`

---

## Claim 2: "and cuts lines over 4096 bytes"

**Location:** `scripts/dev-cycle.sh:27-28`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers newline-terminated lines and the marker text; does not establish memory bounds (perl still reads the whole line before cutting).

```perl
# scripts/dev-cycle.sh:40
    $_ = substr($_, 0, 4096) . " [line cut at 4096 bytes]\n" if length($_) > 4097;
```

`$_` includes the newline under `-n`, so a terminated line with 4097+ content bytes is cut and one with exactly 4096 is not. Probe results: 4096 content bytes → `len 4096 uncut`; 4097 content bytes → `CUT`; a sequence straddling byte 4096 (`C2|9B`, `F3 A0|81 81`) → cut, no sequence left (the marker starts with an ASCII space, so the cut cannot complete one). Two precision gaps: an unterminated final line of exactly 4097 bytes is not cut (`line 6: len 4097 uncut`), and the cut counts raw input bytes before C0 deletion (a 5000-byte line of `\x01` + `B` comes out as only the marker, `len 25 CUT`). The precise version: "cuts each input line to its first 4096 bytes when it is longer (a final line without a newline may keep one more byte)".

Command: `bash -c 'source ./scrub-new.sh; scrub < cut-in.txt' | perl …`; cwd `fc6/`; exit 0; 2026-10-02T03:5xZ.

**Evidence:** `scripts/dev-cycle.sh:40`, `fc6/cut.pl`, `fc6/logs/cut-probe.txt`

---

## Claim 3: "Perl is pinned to bytes: PERL_UNICODE, PERL5OPT and PERLIO are removed (each can turn on UTF-8 decoding and switch the byte patterns off), -C0 is set, and both handles are binmoded."

**Location:** `scripts/dev-cycle.sh:28-30`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three env vars, `-C0` and `binmode` against PERLIO `:utf8`, `:encoding(UTF-8)`, `:crlf`, `:raw:utf8`, PERL_UNICODE=SDA, PERL5OPT=-CSD and all three combined; does not establish immunity to other perl env vars (e.g. PERL5LIB), which the comment does not claim.

```bash
# scripts/dev-cycle.sh:38-39
  env -u PERL_UNICODE -u PERL5OPT -u PERLIO LC_ALL=C perl -C0 -ne '
    BEGIN { $| = 1; binmode STDIN; binmode STDOUT }
```

All eight environment variants produce `if abcdef.` / `if ghijkl.` from the test-5 inputs. The "each can switch the patterns off" half holds for PERLIO: test 5 (new) fails on 28c6178 with `env: PERLIO=:utf8`.

Command: `env $e bash -c 'source ./scrub-new.sh; scrub < env-in.txt'` for each `$e`; cwd `fc6/`; exit 0; 2026-10-02T03:5xZ. Old-code failure: `bats test/scripts/dev-cycle.bats` in an archive of 28c6178 with ef0471c's bats file; exit 1; 2026-10-02T03:51:16Z.

**Evidence:** `scripts/dev-cycle.sh:38-39`, `fc6/logs/env-probe.txt`, `fc6/logs/bats-newtests-on-28c6178.txt`

---

## Claim 4: "C0 goes first; after each deletion the search resumes 3 bytes before it (no sequence is longer than 4 bytes), so a control byte inside a sequence or a nested sequence cannot reassemble one"

**Location:** `scripts/dev-cycle.sh:30-32`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers closure (no listed sequence survives) and equivalence to a run-to-fixpoint reference on 250,000 fuzz lines; does not establish the "linear" half of the same sentence (claim 5).

```perl
# scripts/dev-cycle.sh:46-48
      my $s = $-[0];
      substr($_, $s, $+[0] - $s) = "";
      $i = $s > 3 ? $s - 3 : 0;
```
(excerpt ends :48; enclosing `while` closes at :49, then `print` :50 — read)

The longest pattern is 4 bytes, so a sequence newly formed across the deletion point must start at or after `s-3`; nothing before `s` changed and the leftmost-match search already found no match before `s`. `tr` runs on `:41` before the loop, and deletions cannot create C0 bytes. Executed: output equals `1 while s///g` to fixpoint on 200,000 random lines and 50,000 nested-insertion lines; residual matches 0.

Command: as claim 1; exit 0; 2026-10-02T03:55:22Z.

**Evidence:** `scripts/dev-cycle.sh:41-50`, `fc6/fuzz.pl`, `fc6/fuzz2.pl`, `fc6/ref.pl`, `fc6/logs/fuzz.txt`

---

## Claim 5: "and the work stays linear in the line"

**Location:** `scripts/dev-cycle.sh:32-33`
**Type:** Performance
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the resume loop's cost as a function of line length with the cut removed; does not establish any practical slowness of the shipped script, where the 4096-byte cut bounds the work.

Each deletion is `substr($_, $s, …) = ""` (`scripts/dev-cycle.sh:47`), which moves the rest of the line, so k deletions cost O(k·n), not O(n). Timings with the cut removed on `"if m" . "\xC2" x N . "\x9B" x N`: N=40,000 → 63 ms, 80,000 → 190 ms, 160,000 → 658 ms (×3.0 then ×3.5 per doubling: superlinear). With the cut in place the line never exceeds 4096 bytes, so the shipped script is fast regardless (4 ms at every N). The claim is wrong as stated, but the scrub's behavior is fine: wording only.

Command: `timeout 900 bash timing.sh`; cwd `fc6/`; exit 0; 2026-10-02T03:52:18Z.

**Evidence:** `scripts/dev-cycle.sh:40-49`, `fc6/timing.sh`, `fc6/logs/timing.txt`

---

## Claim 6: "Not covered: lone bytes 0x80-0x9F and overlong encodings (invalid UTF-8, which a UTF-8 terminal does not decode), U+061C and U+2028/2029, and zero-width characters (none can start a line)."

**Location:** `scripts/dev-cycle.sh:33-35`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers that the pattern on `:45` matches none of the listed classes (so they really are not covered); does not establish terminal decoding behavior, or that the list is complete — other invisible format characters (U+206A-206F, U+FFF9-FFFB, U+00AD) also pass and are not named unless "zero-width characters" is read to include them.

The pattern (quoted in claim 1, `scripts/dev-cycle.sh:45`) requires a `C2`, `E2 80`, `E2 81` or `F3 A0` lead, so a lone `0x9B`, an overlong `E0 82 9B`, `D8 9C` (U+061C) and `E2 80 A8/A9` (U+2028/2029) do not match.

**Evidence:** `scripts/dev-cycle.sh:45`

---

## Claim 7: re-exec comment — "Each stream keeps its own order; merged with 2>&1 the two may interleave differently. fd 3 takes the outer pipe (to the outer scrub), then inside the group the child's stderr takes the inner pipe and its stdout goes to fd 3. Exit status: the body's … DEV_CYCLE_SCRUBBED marks the child; a caller that sets it skips the scrub"

**Location:** `scripts/dev-cycle.sh:54-59`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the fd wiring, the stderr path, exit status on a failing body and the bypass; does not establish the interleaving order under `2>&1` (asserted only as "may").

```bash
# scripts/dev-cycle.sh:60-63
if [[ -z "${DEV_CYCLE_SCRUBBED:-}" ]]; then
  { DEV_CYCLE_SCRUBBED=1 bash "${BASH_SOURCE[0]}" "$@" 2>&1 1>&3 3>&- | scrub >&2; } 3>&1 | scrub
  exit "${PIPESTATUS[0]}"
fi
```

`3>&1` on the group makes fd 3 the outer pipe; inside, the child's fd 1 is the inner pipe, `2>&1` sends stderr there, `1>&3` sends stdout to the outer pipe, `3>&-` closes 3 in the child. Probe: `--x<ESC>y` gives `Unknown option: --xy` on stderr with stdout discarded (scrubbed); with `DEV_CYCLE_SCRUBBED=1` the ESC (`033`) passes through. Bats 7 (exit status and whole digest survive a redirect) and 18 (unknown option exit 1) pass.

Command: `timeout 20 bash $DC $'--x\033y' 2>&1 >/dev/null | od -c` with and without `DEV_CYCLE_SCRUBBED=1`; cwd a `mktemp -d` repo; exit 0; 2026-10-02T03:5xZ.

**Evidence:** `scripts/dev-cycle.sh:52-63`, `fc6/logs/sec7-probe.txt`, `fc6/logs/bats-ef0471c.txt`

---

## Claim 8: cycle-record glob goes through `inrepo()` (commit C8)

**Location:** `scripts/dev-cycle.sh:112-113`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the window-start loop; does not establish other globs (all others already used `inrepo`).

```bash
# scripts/dev-cycle.sh:112-115
for f in docs/working/cycles/cycle-[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9].md; do
  inrepo "$f" || continue
  d="${f##*/cycle-}"; d="${d%.md}"
  [[ "$d" > "$last_record" && ! "$d" > "$TODAY" ]] && last_record="$d"  # ignore future-dated
```
(excerpt ends :115; loop closes :116 — read)

**Evidence:** `scripts/dev-cycle.sh:86`, `scripts/dev-cycle.sh:112-116`

---

## Claim 9: sections 5 and 7 match roadmap headings "case-insensitively by prefix" (commit C1)

**Location:** `scripts/dev-cycle.sh:212`, `scripts/dev-cycle.sh:258`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `## NOW`, `## In Flight (loops)`, `## Next steps`; does not establish that a section ends at a later heading sharing the prefix — it does not (see below).

```awk
# scripts/dev-cycle.sh:258
n="$(awk -v h="## $sec" 'index(tolower($0), tolower(h)) == 1 { on = 1; next } on && /^## / { exit } on && /^([-*] |[0-9]+\. )/ { c++ } END { print c + 0 }' docs/roadmap.md)"
```

Probe roadmap: `## NOW` (2 items) → "Now: 2"; `## In Flight (loops)` → "In flight: 1". Side effect of prefix matching, as the commit describes: a later `## Nextgen` heading matches the first rule before the exit rule, so its item is counted under Next and printed in section 5 (`> - e`; "Roadmap Next: 2"). Templates use only the five fixed headings, so this is an edge case, not a contradiction of the claim.

Command: `DEV_CYCLE_TODAY=2026-10-01 timeout 60 bash $DC --since=2000-01-01`; cwd a `mktemp -d` repo; exit 0; 2026-10-02T03:5xZ.

**Evidence:** `scripts/dev-cycle.sh:212`, `scripts/dev-cycle.sh:256-260`, `fc6/logs/sec7-probe.txt`

---

## Claim 10: "a path under docs/, a *.md file, or a file named README or README.*, all any case"

**Location:** `scripts/dev-cycle.sh:218-220`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the classification awk; does not establish rename handling (unchanged this round).

```awk
# scripts/dev-cycle.sh:224 (inner awk)
NF { b = tolower($0); sub(/.*\//, "", b); p = tolower($0); if (p ~ /^docs\// || p ~ /\.md$/ || b == "readme" || index(b, "readme.") == 1) d++; else c++ }
```

Bats 19 adds `md-upper:NOTES.MD w.sh:ok` and passes at ef0471c, fails on 28c6178.

**Evidence:** `scripts/dev-cycle.sh:221-227`, `fc6/logs/bats-ef0471c.txt`, `fc6/logs/bats-newtests-on-28c6178.txt`

---

## Claim 11: "core.quotePath=false prints non-ASCII names as they are; git still quotes a name holding a control character (so each name is one line), and the patterns below accept the quote."

**Location:** `scripts/dev-cycle.sh:238-244`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers non-ASCII, tab, newline and double-quote names under `skills/` and `docs/decisions/`; does not establish that printed names are unescaped (they keep git's C-style escapes, e.g. `"skills/tab\tx/SKILL.md"`).

```bash
# scripts/dev-cycle.sh:243-244
skills_changed="$(printf '%s\n' "$changed" | grep -E '^"?(skills/.*/SKILL\.md|workflows/[^/]*\.md)"?$' || true)"
records_changed="$(printf '%s\n' "$changed" | grep -E '^"?docs/decisions/[0-9]{3}-[^/]*\.md"?$' || true)"
```

Probe: skills `tab<TAB>x`, `q"uote`, `café`, `nl<LF>y` → count 4, `skills/café/SKILL.md` printed raw, the others quoted on one line each; records `001-café.md`, `002-a"b.md` → count 2.

**Evidence:** `scripts/dev-cycle.sh:241-253`, `fc6/logs/sec7-probe.txt`

---

## Claim 12: "seeding appends "- <idea> (signal: …)" lines, and only lines of that shape count"

**Location:** `scripts/dev-cycle.sh:266-271`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the counting regex; does not establish strict shape checking (no closing `)` required; `-  x (signal: y)` with two spaces counts; `(signal:y)` without a space and `*` bullets do not).

```awk
# scripts/dev-cycle.sh:271 (awk)
/^## Brainstorm [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/ { c = 0; next } /^- .*\(signal: / { c++ } END { print c + 0 }
```

Probe log after `## Brainstorm 2026-09-01`: `- one (signal: a)`, `- two (signal:b)`, `-  three (signal: c)`, `* four (signal: d)`, `- five (Signal: e)` → "Ideas seeded since: 2".

**Evidence:** `scripts/dev-cycle.sh:264-280`, `fc6/logs/sec7-probe.txt`

---

## Claim 13: "Deep nesting stays fast (the scrub used to restart the line per layer), and an over-long line is cut."

**Location:** `test/scripts/dev-cycle.bats:104-109`
**Type:** Behavioral (test intent)
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the 40,000-layer case exercises; does not establish anything wrong with the resume loop itself (claim 4 verifies it).

```bash
# test/scripts/dev-cycle.bats:106-109
    perl -e 'print "# 003\n\n## Revisit triggers\nif m", "\xC2" x 40000, "\x9B" x 40000, "n.\n"' > docs/decisions/003-z.md
    run --separate-stderr timeout 20 bash "$DC"
    [ "$status" -eq 0 ] || { echo "status $status (124 = timed out)"; return 1; }
    [[ "$output" == *"[line cut at 4096 bytes]"* ]]
```
(excerpt ends :109; test 5 continues to :116 — read)

The line is cut to its first 4096 bytes (`"> if m"` + `\xC2` × ~4090) before the loop runs, so no `\x9B` survives and there is no nesting to resolve. Measured: the old restart-per-layer loop plus the new cut (`oldcut.sh`) also takes 4 ms on this input. The test therefore guards the cut, not the "stays fast on deep nesting" property; removing the resume logic would not fail it. Test and wording only, not behavioral.

Command: `timeout 900 bash timing.sh`; cwd `fc6/`; exit 0; 2026-10-02T03:52:18Z.

**Evidence:** `test/scripts/dev-cycle.bats:104-109`, `scripts/dev-cycle.sh:40`, `fc6/logs/timing.txt`

---

## Claim 14: commit ef0471c — "R1: the scrub also removes PERLIO and binmodes both handles; test 5 adds PERLIO=:utf8 and :raw:utf8."

**Location:** commit ef0471c message
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the code change and the test loop; see claim 3 for the probes.

```bash
# test/scripts/dev-cycle.bats:100
    for env in "" PERL_UNICODE=SDA PERL5OPT=-CSD PERLIO=:utf8 PERLIO=:raw:utf8; do
```

**Evidence:** `scripts/dev-cycle.sh:38-39`, `test/scripts/dev-cycle.bats:100`, `fc6/logs/env-probe.txt`

---

## Claim 15a: commit ef0471c — "A1 (X1): after each deletion the search resumes 3 bytes before it … and lines over 4096 bytes are cut with a marker."

**Location:** commit ef0471c message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the resume and the cut as implemented (claims 2, 4); does not establish the linearity half (15b).

`scripts/dev-cycle.sh:48` `$i = $s > 3 ? $s - 3 : 0;` and `:40` (quoted in claim 2).

**Evidence:** `scripts/dev-cycle.sh:40-49`, `fc6/logs/fuzz.txt`, `fc6/logs/cut-probe.txt`

---

## Claim 15b: commit ef0471c — "so nested input is linear (40k-layer line in test 5, 20 s timeout)"

**Location:** commit ef0471c message
**Type:** Performance / Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the linearity claim and the test cited as its evidence; does not establish practical slowness (the cut bounds it).

The resume loop is superlinear without the cut (claim 5: 63/190/658 ms at 40k/80k/160k layers), and the cited test does not exercise nesting at all (claim 13: the old loop plus the cut passes it in 4 ms). What makes nested input fast in the shipped script is the 4096-byte cut. Wording only.

**Evidence:** `fc6/logs/timing.txt`, `test/scripts/dev-cycle.bats:104-109`

---

## Claim 16: commit ef0471c — A5, C1, C3, C7, C8 as listed

**Location:** commit ef0471c message
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers presence and behavior of each listed change (claims 7–12); does not re-verify unchanged code.

A5: `git -c core.quotePath=false log …` at `scripts/dev-cycle.sh:241`, test 20 adds `skills/café`. C1: claim 9. C3: claim 12. C7: comments at `:33-35` and `:54-59`. C8: claims 8, 10.

**Evidence:** `scripts/dev-cycle.sh:33-35,54-59,113,212,224,241-244,258,271`, `test/scripts/dev-cycle.bats:276-305`

---

## Claim 17: commit ef0471c — "20/20 tests; tests 5, 19 and 20 fail on 28c6178."

**Location:** commit ef0471c message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers ef0471c's bats file against ef0471c's script and against 28c6178's script; does not establish the rest of the repo's suites.

At ef0471c: 20 `ok`, exit 0. ef0471c's test file on a `git archive 28c6178` tree: `not ok 5`, `not ok 19`, `not ok 20` and no others, exit 1.

Commands: `timeout 500 bats test/scripts/dev-cycle.bats` in `/workspace/.claude/wt-digest` (clean tree, HEAD ef0471c), exit 0, 2026-10-02T03:51:07Z; same in `fc6/tmp.r4TPEONG2z` (28c6178 archive + new bats file), exit 1, 2026-10-02T03:51:16Z.

**Evidence:** `fc6/logs/bats-ef0471c.txt`, `fc6/logs/bats-newtests-on-28c6178.txt`

---

## Claim 18: commit ef0471c — "shellcheck clean (the bats file too)."

**Location:** commit ef0471c message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers shellcheck 0.9.0 with default settings; does not establish other versions.

`shellcheck scripts/dev-cycle.sh` exit 0; `shellcheck test/scripts/dev-cycle.bats` exit 0; cwd `/workspace/.claude/wt-digest`; 2026-10-02T03:51:25Z.

**Evidence:** `fc6/logs/shellcheck-script.txt`, `fc6/logs/shellcheck-bats.txt`

---

## Claim 19: decision log row 67 — "**Revised by #68 (2026-10-01).**"

**Location:** `docs/decisions/log.md:90` (B)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the marker and that row 68 exists and revises 67; does not re-check row 67's historical body.

Row 68 opens "**The dev cycle is the standard work loop, revised from the approval doc…**" with "log 67" in its references column (`docs/decisions/log.md:91`).

**Evidence:** `docs/decisions/log.md:90-91`

---

## Claim 20: decision log row 68 — "brainstorm (step 5) is conditional (0–1 Now items ready, 10+ seeds, a week since the last, a reopened direction, or asked)"

**Location:** `docs/decisions/log.md:91` (B)
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the condition list against the skill's step 5; does not establish the remaining clauses (claim 21).

The skill adds a fifth condition variant the row omits: `skills/dev-cycle/SKILL.md:160-161` "a week or more since the last brainstorm, by date, or none recorded yet". Precise version: "…a week since the last (or none yet)…".

**Evidence:** `docs/decisions/log.md:91`, `skills/dev-cycle/SKILL.md:157-162`

---

## Claim 21: decision log row 68 — 4b "files a scoped deep-audit task (which re-reads the full history)"; "build briefs in step 6 … step 6b, at most 3 In flight … after the cycle branch lands"; "whether a loop merges on its own or stops for a separate PR review is a per-project build-loop policy in `docs/dev-cycle.md`, set during onboarding"; revisit clause

**Location:** `docs/decisions/log.md:91` (B)
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each clause against the skill and onboarding text; does not establish that onboarding sets the idea sources (that claim is made elsewhere, claim 23).

Skill: `:147-148` "add a scoped deep-audit task to the roadmap", `:138` "A deep audit re-reads the whole history", `:203-204` "at most 3 items In flight at once", `:243` "Runs after step 7 has landed", `:247` "follows the build-loop policy in `docs/dev-cycle.md`"; onboarding `workflows/codebase-onboarding.md:453` "Also settle the project's **build-loop policy** with the user".

**Evidence:** `skills/dev-cycle/SKILL.md:138-149,202-210,241-256`, `workflows/codebase-onboarding.md:453`

---

## Claim 22: deletion of `docs/dev-cycle-sources.md`, "replaced by docs/dev-cycle.md" (commit 5e8bfd9)

**Location:** `docs/dev-cycle-sources.md` (deleted), commit 5e8bfd9 (B)
**Type:** Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers live references outside `docs/reviews/`; the one remaining mention is a historical answer note in `docs/working/questions-archive.md:1832`, which is a record, not a pointer.

`rg -n 'dev-cycle-sources' --glob '!docs/reviews/**'` returns only `docs/working/questions-archive.md:1832` (paraphrased — no quote needed beyond the path; claim covers absence of live references).

**Evidence:** `docs/working/questions-archive.md:1832`

---

## Claim 23: "Codebase onboarding sets them (its step 13)" — "them" being the settings: the build-loop policy and the idea sources

**Location:** `docs/dev-cycle.md:3-4` (B)
**Type:** Architectural / Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what onboarding step 13 asks for; does not establish any harm beyond the fallback (step 5 then uses "the repo's own idea backlog").

```markdown
<!-- docs/dev-cycle.md:3-4 -->
This repo's settings for the dev-cycle skill (`skills/dev-cycle/SKILL.md`). Codebase
onboarding sets them (its step 13); change them by editing this file.
```

Onboarding step 13 settles only the policy: "Record it as `Build-loop policy: <value>` in `docs/dev-cycle.md`" (`workflows/codebase-onboarding.md:453`), and its new done-when line is "`docs/dev-cycle.md` records the build-loop policy the user chose" (`:457`). Nothing in onboarding mentions idea sources (`rg 'idea source|Idea sources' workflows/codebase-onboarding.md` → no hits). Precise version: "Codebase onboarding sets the build-loop policy (its step 13)". Doc and procedure mismatch, not code.

**Evidence:** `docs/dev-cycle.md:3-4`, `workflows/codebase-onboarding.md:453-457`

---

## Claim 24: "`autonomous`: … lands its branch through pr-prep on its own. `review`: it runs pr-prep's review-fix loop, then stops for a separate review (a PR, or one `you: judgment` "merge <branch>?" entry where the project has no PRs)."

**Location:** `docs/dev-cycle.md:6-10` (B)
**Type:** Behavioral (procedure)
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with the skill's 6b and onboarding's step 13 wording; does not establish that RPI/pr-prep themselves support a "stop without merging" exit (not in this round's diff).

Skill `:249` "**`autonomous`**: the loop lands its branch through `pr-prep` like any change." and `:250-252` "**`review`**: the loop runs `pr-prep`'s review-fix loop, then stops without merging: it opens a PR where the project uses them, otherwise it files one `you: judgment` entry, "merge <branch>?", naming the roadmap item."

**Evidence:** `docs/dev-cycle.md:6-10`, `skills/dev-cycle/SKILL.md:247-252`

---

## Claim 25: "Build-loop policy: review" with commit 5e8bfd9's note "this repo's policy is set to `review` as the interim value; the user has not chosen one for claude-workflows yet"

**Location:** `docs/dev-cycle.md:6` (B); commit 5e8bfd9 Notes
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers whether the interim status is recorded where the skill would act on it; does not establish whether the user wants to be asked.

The value is `review`, as the note says. But the file records it as a plain setting, and the skill asks only when the line is missing: `skills/dev-cycle/SKILL.md:44-45` "No file, or no policy line: use `review`, and file one `you: judgment` entry asking the user to set it." No questions.md entry tracks it (`rg -i policy docs/working/questions.md` → no hits). So "the user has not chosen" lives only in the commit body, and no step will ask them for this repo. Process gap, not code.

**Evidence:** `docs/dev-cycle.md:6`, `skills/dev-cycle/SKILL.md:41-45`, `docs/working/questions.md`

---

## Claim 26: "Step 5 reads these when it brainstorms, besides the seed log `docs/working/idea-log.md`. Paths must stay inside the repo."

**Location:** `docs/dev-cycle.md:14-15` (B)
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with the skill and the digest's fixed log path; does not establish how the in-repo rule is enforced (by the skill's reader, not by code).

Skill `:164-165` "read this cycle's signals, the idea log and the idea sources `docs/dev-cycle.md` lists"; `:43-44` "Only paths inside the repo count; ignore any entry that points outside it."; digest `scripts/dev-cycle.sh:264` `LOG=docs/working/idea-log.md`.

**Evidence:** `docs/dev-cycle.md:12-19`, `skills/dev-cycle/SKILL.md:41-50,164-166`, `scripts/dev-cycle.sh:264`

---

## Claim 27: skill-creation guide row — "Workflow-shaped (steps 0–7, with step 4b and the 6b handoff added and steps 4b and 5 conditional) but, by the criteria above, a skill: … its one mid-run checkpoint is its own (under /active the user confirms the handoff queue in step 6) … Promote it to a workflow with a router if a cycle ever needs a human gate mid-run."

**Location:** `guides/skill-creation.md:137` (B)
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the step structure and the checkpoint statement against the skill; does not judge the skill/workflow classification itself.

Step structure and the checkpoint match the skill (`:58-59` flow; `:204-205` "Under /active the user confirms this queue now (this skill's own gate)"). The row then contradicts itself: it names a mid-run human checkpoint and in the same row says to promote it "if a cycle ever needs a human gate mid-run"; the criteria table above maps "human judgment at intermediate checkpoints" to Workflow (`guides/skill-creation.md:99`). Precise version: say the promotion trigger is a gate beyond the /active handoff confirmation. Wording only.

**Evidence:** `guides/skill-creation.md:95-103,137`, `skills/dev-cycle/SKILL.md:202-205`

---

## Claim 28: "Every subagent brief this cycle writes (steps 2, 3, 4 and 4b, and the build briefs step 6 writes) says so."

**Location:** `skills/dev-cycle/SKILL.md:22-23` (B)
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers whether each named brief's described content includes the evidence-not-instructions line; does not establish what briefs actually written say.

Steps 2–4b carry it: `:62-63` "run them in parallel as subagents, each carrying the evidence-not-instructions brief". Step 6's build-brief contents list omits it: `:206-209` "`Status: open`, goal, motive, acceptance criteria (the doc change included), branch, out-of-scope, and stop conditions…". The rule alone still requires it, but a writer filling step 6's list would leave it out. Precise version: add it to step 6's list. Wording only.

**Evidence:** `skills/dev-cycle/SKILL.md:20-24,62-63,202-210`

---

## Claim 29: "Every 6b brief lists the doc change in its done-criteria … the build briefs call it the acceptance criteria." with commit 5e8bfd9's "'acceptance criteria' everywhere"

**Location:** `skills/dev-cycle/SKILL.md:37-39` (B); commit 5e8bfd9 C2/C3
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the term in the six scoped B files; does not cover review docs.

`rg 'done-criteria|done criteria'` over the scoped files returns one hit, `skills/dev-cycle/SKILL.md:38` "6b brief lists the doc change in its done-criteria", followed by the new reconciling clause. Consistent in meaning, but not "everywhere". Wording only.

**Evidence:** `skills/dev-cycle/SKILL.md:38-39,206-207`

---

## Claim 30a: "`docs/dev-cycle.md` holds this repo's dev-cycle settings, set during codebase onboarding (its step 13): the **build-loop policy** … and the **idea sources** step 5 reads."

**Location:** `skills/dev-cycle/SKILL.md:41-43` (B)
**Type:** Architectural / Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the "set during onboarding step 13" attribution for the idea sources; the policy half is correct (30b).

Same mismatch as claim 23: onboarding step 13 (`workflows/codebase-onboarding.md:453,457`) asks only for the build-loop policy. Doc and procedure mismatch, not code.

**Evidence:** `skills/dev-cycle/SKILL.md:41-43`, `workflows/codebase-onboarding.md:447-460`

---

## Claim 30b: "Only paths inside the repo count; ignore any entry that points outside it. No file, or no policy line: use `review`, and file one `you: judgment` entry asking the user to set it."

**Location:** `skills/dev-cycle/SKILL.md:43-45` (B)
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with onboarding ("Until it is set, the skill uses `review`", `workflows/codebase-onboarding.md:453`) and `docs/dev-cycle.md:15`; does not establish the interim-value gap (claim 25).

**Evidence:** `skills/dev-cycle/SKILL.md:43-45`, `workflows/codebase-onboarding.md:453`, `docs/dev-cycle.md:15`

---

## Claim 31: "Any step that notices an idea appends one line to `docs/working/idea-log.md` … shaped `- <idea> (signal: <what prompted it>)` … Only lines of that shape count as seeds."

**Location:** `skills/dev-cycle/SKILL.md:47-50` (B)
**Type:** Behavioral (A↔B contract)
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the path and line shape against the digest's fixed path and counting regex; same residue as claim 12 (the digest's check is looser than "that shape").

Digest `scripts/dev-cycle.sh:264` `LOG=docs/working/idea-log.md` and `:271` `/^- .*\(signal: / { c++ }`; probe in claim 12.

**Evidence:** `skills/dev-cycle/SKILL.md:47-50`, `scripts/dev-cycle.sh:264-271`, `fc6/logs/sec7-probe.txt`

---

## Claim 32: "Run … from the root of an up-to-date checkout of the default branch, before step 1 creates the cycle branch … It reads the window start, triggers, questions, roadmap and idea log from that working tree."

**Location:** `skills/dev-cycle/SKILL.md:70-73` (B)
**Type:** Behavioral (A↔B contract)
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers which digest inputs come from the working tree; does not establish that the digest itself checks the checkout is up to date or on the default branch (it does not; the merge/commit sections use the default-branch hash regardless).

Digest: cycle-record glob on the working tree (`scripts/dev-cycle.sh:112`), triggers `:148` `for f in docs/decisions/[0-9][0-9][0-9]-*.md`, questions `:175` `inrepo docs/working/questions.md`, roadmap `:208`, idea log `:264-265`; its Window line says so (`:129` "Triggers: all of them, from the working tree. Questions, roadmap, idea log: the working tree.").

**Evidence:** `scripts/dev-cycle.sh:111-129,148,175,208,264`

---

## Claim 33: "Skip any branch or worktree a brief in `docs/working/handoffs/` with `Status: open` names"

**Location:** `skills/dev-cycle/SKILL.md:96-98` (B)
**Type:** Behavioral (procedure)
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that `Status:` is defined where briefs are written and closed; does not establish timing for briefs whose status should flip (see claim 35).

Briefs start `Status: open` (`:206`) and are set `Status: closed` on merge or stall (`:191-193`).

**Evidence:** `skills/dev-cycle/SKILL.md:96-98,190-193,206`

---

## Claim 34: step 5 conditions — "(the digest's section 7 prints the counts and dates; readiness and direction are judged here)" … "roadmap Now holds 0–1 items ready for a build loop" … "or none recorded yet"

**Location:** `skills/dev-cycle/SKILL.md:154-161` (B)
**Type:** Behavioral (A↔B contract)
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what section 7 prints (Now/In flight/Next counts, last brainstorm date or "none recorded", seeds since); does not establish readiness, which the digest does not compute and the text says is judged.

Digest prints "Roadmap Now: N item(s)" (`scripts/dev-cycle.sh:259`), "Last brainstorm: none recorded in …" (`:275`), "Ideas seeded since: N" (`:277`); probe output in `fc6/logs/sec7-probe.txt`.

**Evidence:** `skills/dev-cycle/SKILL.md:151-169`, `scripts/dev-cycle.sh:255-280`, `fc6/logs/sec7-probe.txt`

---

## Claim 35: In flight lifecycle — "merged → Done and its brief `Status: closed`; still running or waiting on the user's merge decision → stays; stopped on a stop condition, or no commit on its branch for 7 days → back to Now marked stalled, with the reason, and its brief `Status: closed`."

**Location:** `skills/dev-cycle/SKILL.md:190-193` (B)
**Type:** Behavioral (procedure) / Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the internal consistency of the three branches with the `review` policy (6b) and the handoff queue (step 6); does not establish how often a review waits 7+ days.

The branches overlap. Under `review` (the default and this repo's setting), a finished loop stops without merging and its branch gets no further commits (`:250-252`), so after 7 days it matches both "waiting on the user's merge decision → stays" and "no commit on its branch for 7 days → back to Now … `Status: closed`". If the stall branch wins, the item returns to Now. Where the project uses PRs, no `you: judgment` entry names it, so step 6's handoff queue (`:202-203` "Take the Now items whose first step needs no open choice (no open `you: judgment` names them)") can hand it to a second build loop while the first PR is still open. The rule needs an explicit exception for an item waiting on review. This is a procedure defect that can do the wrong thing, not wording; there is no code involved.

**Evidence:** `skills/dev-cycle/SKILL.md:190-193,202-210,247-252`

---

## Claim 36: handoff queue — brief at `docs/working/handoffs/YYYY-MM-DD-<slug>.md` with `Status: open` …; "stop conditions, which always include touching enforcement, hook or settings files, adding a dependency, and any change the out-of-scope list names"; "Under /active the user confirms this queue now (this skill's own gate)"

**Location:** `skills/dev-cycle/SKILL.md:202-210` (B)
**Type:** Configuration (procedure)
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with commit 5e8bfd9 ("briefs always stop on enforcement, hook or settings files and new deps"), the guide row and the 6b launch; does not establish that "settings files" excludes `docs/dev-cycle.md` (ambiguous but harmless: a loop editing it would stop).

**Evidence:** `skills/dev-cycle/SKILL.md:202-210`, `guides/skill-creation.md:137`

---

## Claim 37: "if a cycle skips its record, the next window widens back to the older record"

**Location:** `skills/dev-cycle/SKILL.md:236-237` (B)
**Type:** Behavioral (A↔B contract)
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the digest's window-start fallback; does not establish the skill's step 0 rerun guidance (unchanged).

When no older record exists, the digest does not widen to a record but falls back to 14 days, which may be wider or narrower than the skipped cycle: `scripts/dev-cycle.sh:121-123` `SINCE="$(date -d "$TODAY - 14 days" +%F)"`. Precise version: "widens back to the older record, or to the 14-day default if there is none". Wording only.

**Evidence:** `scripts/dev-cycle.sh:111-124`, `skills/dev-cycle/SKILL.md:235-239`

---

## Claim 38: 6b — "in its own worktree on the brief's branch, from the default branch, giving it the brief's path and the landed commit; the loop reads the brief from that commit … The brief stands in for RPI's plan approval." and the two policy end states

**Location:** `skills/dev-cycle/SKILL.md:243-256` (B)
**Type:** Behavioral (procedure)
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers agreement with commit 5e8bfd9 (A3, C4), `docs/dev-cycle.md:8-10` and onboarding step 13; does not establish that RPI's or pr-prep's own text recognizes a brief as plan approval or a review-and-stop exit (outside this round's diff), nor the lifecycle overlap (claim 35).

**Evidence:** `skills/dev-cycle/SKILL.md:241-256`, `docs/dev-cycle.md:6-10`, `workflows/codebase-onboarding.md:453`

---

## Claim 39: onboarding step 13 — "Record it as `Build-loop policy: <value>` in `docs/dev-cycle.md` (the skill's settings file; create it from the skill's description if missing). Until it is set, the skill uses `review`." and done-when "`docs/dev-cycle.md` records the build-loop policy the user chose"

**Location:** `workflows/codebase-onboarding.md:453,457` (B)
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the step number (it is `### 13. Gate — validate with the team`, `:447`), the line format matching `docs/dev-cycle.md:6`, and the default matching the skill; does not establish that the skill's description is enough to recreate the file's idea-sources table (it describes the settings, not the layout).

**Evidence:** `workflows/codebase-onboarding.md:447-460`, `docs/dev-cycle.md:6`, `skills/dev-cycle/SKILL.md:41-45`

---

## Claim 40: commit 5e8bfd9 — A3, A2 (X2), A4, A6, C2/C3 as listed ("A4: … stopped or 7 days idle → back to Now as stalled; briefs carry Status: open|closed, and step 1 skips only open ones"; "A6: decision log row 67 marked revised by #68; row 68 and the skill-creation guide row corrected"; "C2/C3: digest runs on an up-to-date default-branch checkout; step 5 condition is about Now; record template wording; seed line shape; … rule 1 names step 6's briefs")

**Location:** commit 5e8bfd9 message (B)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers presence of each listed change in the diff; correctness issues inside them are verdicted separately (claims 20, 23, 25, 27, 28, 29, 30a, 35, 37); "'acceptance criteria' everywhere" is claim 29.

Each change is present in `git diff c079e8c..5e8bfd9`: `skills/dev-cycle/SKILL.md:41-50,70-73,96-98,157,190-193,219,227,243-256`, `docs/decisions/log.md:90-91`, `guides/skill-creation.md:137`, `workflows/codebase-onboarding.md:453,457`, `docs/dev-cycle.md` (new), `docs/dev-cycle-sources.md` (deleted) (paraphrased — no quote available because the claim is a change inventory spanning six files; individual quotes appear in the claims cited).

**Evidence:** `skills/dev-cycle/SKILL.md:20-256`, `docs/decisions/log.md:90-91`, `guides/skill-creation.md:137`, `workflows/codebase-onboarding.md:453-457`, `docs/dev-cycle.md:1-19`

---

## Claims Requiring Attention

### Incorrect
- **Claim 5** (`scripts/dev-cycle.sh:32-33`): "the work stays linear in the line": each deletion moves the tail, and with the cut removed the timings are superlinear (×3.0, ×3.5 per doubling). The 4096-byte cut is what bounds the work. Reword (e.g. "the 4096-byte cut bounds the work"). Wording only.
- **Claim 13** (`test/scripts/dev-cycle.bats:104-109`): the 40k-layer case is cut to 4096 bytes before scrubbing, leaving no `\x9B`, so it never exercises nesting; the old loop plus the cut passes it in 4 ms. To test the resume, use a nested line under 4096 bytes (e.g. 2000 layers) and assert both the result and the time. Test and wording, not behavioral.
- **Claim 15b** (commit ef0471c): "nested input is linear (40k-layer line in test 5…)": same two facts as claims 5 and 13. Wording only.
- **Claims 23 / 30a** (`docs/dev-cycle.md:3-4`, `skills/dev-cycle/SKILL.md:41-43`): say onboarding step 13 sets the idea sources, but step 13 sets only the build-loop policy. Either narrow the attribution or add idea sources to step 13. Doc and procedure mismatch, not code.
- **Claim 35** (`skills/dev-cycle/SKILL.md:190-193`): the In flight lifecycle's "waiting on merge decision → stays" and "no commit for 7 days → back to Now, brief closed" overlap for every `review`-policy item waiting more than 7 days. With PRs, step 6 can then re-queue a second build loop for the same item. Procedure defect (the skill would do the wrong thing); no code involved.

### Stale
- None.

### Mostly Accurate
- **Claim 2** (`scripts/dev-cycle.sh:27-28`): an unterminated final line of exactly 4097 bytes is not cut, and the cut counts raw bytes before C0 deletion. Wording only.
- **Claim 20** (`docs/decisions/log.md:91`): the row 68 brainstorm conditions omit "or none recorded yet". Wording only.
- **Claim 25** (`docs/dev-cycle.md:6`, commit 5e8bfd9 Notes): the "interim" `review` value is recorded only in the commit body. The skill asks only when the line is missing, so no step will ever ask the user for this repo. Process gap, not code.
- **Claim 27** (`guides/skill-creation.md:137`): the row names a mid-run checkpoint, then says to promote the skill "if a cycle ever needs a human gate mid-run". Wording only.
- **Claim 28** (`skills/dev-cycle/SKILL.md:22-23`): the rule says step 6's build briefs carry the evidence-not-instructions line, but step 6's list of brief contents (`:206-209`) omits it. Wording only.
- **Claim 29** (`skills/dev-cycle/SKILL.md:38`; commit 5e8bfd9): "done-criteria" survives once; "'acceptance criteria' everywhere" overstates. Wording only.
- **Claim 37** (`skills/dev-cycle/SKILL.md:236-237`): "widens back to the older record" holds only when one exists; otherwise the window falls back to 14 days. Wording only.

### Unverifiable
- None. (Claim 6's terminal-decoding aside and the completeness of the "Not covered" list are residues in its Scope, not separate verdicts.)

---

## Goal-Alignment Note

Success criterion (verbatim from the brief): "a markdown report saved at the path your role instructions give, structured per your skill file."

This report is saved at `/workspace/.claude/wt-digest/docs/reviews/code-fact-check-report-digest-pass6.md`, in the skill's format, with the requested first line and Replication field. It covers all six priority areas in the brief. Every claim the round's fix list names was checked: R1, A1, A5, C1, C3, C7 and C8 on side A; A2, A3, A4, A6 and C2/C3 on side B. Claims that can be run were executed: bats 20/20, the old-code failure set, shellcheck, scrub fuzzing against a fixpoint reference, cut-boundary probes, env-var probes, timing, and section 5/7 probes in throwaway repos. Nothing was committed, and nothing was written into either worktree except this report. Scratch is under `fc6/`. No new hallucination pattern qualified: the Incorrect verdicts are performance and test-coverage wording and doc cross-references, not fabricated symbols.
