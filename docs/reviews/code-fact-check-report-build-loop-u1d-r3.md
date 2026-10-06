Commit: 83cdb005

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u1d (branch feat/build-loop-u1d)
**Scope:** `git diff main...HEAD` (one commit, 83cdb005): scripts/build-loop.sh, scripts/dev-cycle.sh, scripts/lib/dev-cycle-read.sh, test/scripts/build-loop-read.bats, test/scripts/dev-cycle.bats, and the commit message. Replicate r3 of k=3.
**Checked:** 2026-10-06
**Total claims checked:** 22
**Summary:** 15 verified, 7 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) read first. Its five entries are all "a measured value quoted from an artifact set that does not hold it" or "a file-to-symbol association never grepped". The one measured value here ("118 changed code lines", Claim 19) was recomputed, and every symbol named (main_entry's callers, row 293, the pipefail setters) was grepped. No claim matches a logged pattern.

Execution setup. All probes and mutants ran under `$S=/tmp/claude-1000/-workspace/57e599b8-f769-48da-96c7-3a02f99f2a8d/scratchpad/review-u1d/fc3`. `$S/base` is `git archive 83cdb005 scripts test docs/dev-cycle.md`. Each mutant `$S/mut/<M>` is a copy of base with one exact, single-occurrence replacement, made by `$S/mkmut.py`. bats ran with `TMPDIR=$S/tmp` (bash 5.2, git 2.39.5). Baseline: `bats test/scripts/build-loop-read.bats test/scripts/dev-cycle.bats` (cwd `$S/base`, 2026-10-06T04:31:41Z) passed 91 of 92. The failure was test 4 (T3), which copies the repo's own docs/dev-cycle.md, and that file was not yet in the archive. After it was added, test 4 passed (`$S/logs/t4.txt`), and every later full run passed 92/92. Logs: `$S/logs/baseline.txt`, `$S/logs/t4.txt`.

Mutant table (cwd `$S/mut/<M>`, 2026-10-06T04:34:27Z, `bats -f '<test>' <file>`, logs `$S/logs/mut-<M>.txt`; full-suite runs `$S/logs/full-<M>.txt`, about 04:35Z):

| Mutant | Change | Test run | Result |
|---|---|---|---|
| M1a | drop `BRIEF=()` from shared_branches' `local -A` | --status deferred | passes (survives; full suite 92/92) |
| M1b | M1a plus move the `shared_branches` call to just after `brief_fields "$a"` in status_line | --status deferred | **fails** at :457 (`ok … feat/q absent - - 3`) |
| M1c | move the call only (local BRIEF kept) | --status deferred | passes (correct code) |
| M2 | `isbrief "${f/closed\//}"` (un-anchored, the pre-C30 form) | --status deferred | **fails** at :453 (o skips) |
| M10 | grep regex without `\r?` | --status deferred | **fails** |
| M12a | drop the loop's `Status: open` check | --status deferred | passes (survives; full 92/92) |
| M12b | grep regex `'^Status: '` (loop check kept) | --status deferred | passes (survives; full 92/92) |
| M12c | M12a + M12b | --status deferred | **fails** at :443 |
| M13 | `rc -gt 0` (fail closed on exit 1, "none") | --status deferred | passes (survives; full 92/92) |
| M14 | FENCE_AWK's NUL refusal disabled | --status deferred | **fails** |
| M3 | guard pair line (build-loop.sh:112) replaced by `:` | --settings deferred | **fails** at :425 (`policy self-merge set`) |
| M4 | guard index fixed at 0 (`cfg=0`), clobbering the caller's pair | --settings deferred | passes (survives; full 92/92) |
| M4c | `GIT_CONFIG_COUNT=$((cfg + 0))` (guard pair not counted) | --settings deferred | **fails** |
| M7a | next-line check moved before `fence($0) { next }` | --settings deferred | **fails** at :413 |
| M7b | blank test `/^$/` instead of `/^[ \t]*$/` | --settings deferred | **fails** |
| M5 | main_entry guard without `pathform` | main_entry test | **fails** (`absent error absent absent`) |
| M5b | pathform moved after the ls-tree read | main_entry test | passes (survives; full 92/92) |
| M6 | `--check-answer` dropped from dev-cycle.sh's default-branch gate | --check-answer gate test | **fails** at :818 (`[ "$status" -eq 1 ]`) |

---

## Claim 1: "Self-merge also needs a valid never line, so a never list hidden in markup, with no exact never line beside it, turns it off."

**Location:** `scripts/build-loop.sh:16-18`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers read_settings' derivation of POLICY from never_ok for a hidden never list alone, an exact line plus a counted hidden copy, an exact line plus an uncounted (letter-adding) copy, and a fenced copy. It does not establish anything about hidden copies of the policy or slots keys.

The stated case holds. A hidden list alone always turns self-merge off. With markup the letters-only count still sees (`- Self-merge never: a/`), the one copy is not exact, so `never malformed: line 3 is not exactly …`. With markup that adds letters (`- [x] …`), the copy is not counted, so `never none: no line starts …`. Either way the policy reads `policy review unset: … no valid Self-merge never: line`. This follows from:

```bash
# scripts/build-loop.sh:250-251
      if [[ "$v" == self-merge && -z "$never_ok" ]]; then
        POLICY_LINE="policy review unset: line ${first[policy]} reads self-merge, but there is no valid Self-merge never: line …"
```

The qualifier implies that an exact never line beside a hidden list keeps self-merge on. That holds only when the hidden copy escapes the letters-only count (p4: `- [x] Self-merge never: b/` next to `Self-merge never: a/` gives `policy self-merge set`, `never a/ set`) or sits in a fence (p5, the same result). A copy the count does see makes two copies. Then `never malformed: more than one line starts "Self-merge never:" (lines 3 and 5)` and `policy review unset` (p3), from:

```bash
# scripts/build-loop.sh:224
    elif [[ "${cnt[never]}" -gt 1 ]]; then NEVER_LINE="never malformed: $(many 'Self-merge never:' never)"
```

The precise version: a hidden list turns self-merge off unless an exact never line sits beside it and the hidden copy is invisible to the copy count. A counted copy turns it off even next to an exact line. That fails closed, so the gap is in wording, not safety.

Provenance: `$S/probe-settings.sh $S/base/scripts/build-loop.sh <name> <lines…>` for p1-p5 (cwd `$S`, 2026-10-06T04:32:28Z, each exit 0), output `$S/logs/probe-settings.txt`.

**Evidence:** `scripts/build-loop.sh:16-18`, `scripts/build-loop.sh:147-162`, `scripts/build-loop.sh:205-258` (read_settings, read whole), `$S/logs/probe-settings.txt`

---

## Claim 2: "A tip on a branch level with main, or whose subject does not start "handoff:", is working." (re-wrapped; commit: "the help is re-wrapped")

**Location:** `scripts/build-loop.sh:61-63`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the 0-ahead path and the re-wrap (no header line over 80 columns, where main's line 62 was 115). It does not establish the help's line widths after scrub, or anything beyond the header.

The marker is only consulted when ahead > 0:

```bash
# scripts/build-loop.sh:348-356
  loop=working
  if [[ "$ahead" -gt 0 ]]; then
    kind="$(marker_kind "$sha")"
    …
  fi
```

marker_kind returns `working` for a non-`handoff:` subject (`[[ "$subj" == handoff:* ]] || { echo working; return; }`, `scripts/build-loop.sh:283`). Probe: a branch level with main whose tip subject is `handoff: junk` printed `ok … open review feat/a working <sha> 2026-10-05 0`. Width: `awk 'NR<=80 && length($0)>80'` over the header prints nothing at HEAD, and prints `main 62: 115` and `main 69: 91` on main's copy.

Provenance: `bash $S/probe-status.sh $S/base/scripts/build-loop.sh` (cwd `$S/repos/status1`, 2026-10-06T04:32:45Z, exit 0), output `$S/logs/probe-status.txt`.

**Evidence:** `scripts/build-loop.sh:61-63`, `scripts/build-loop.sh:278-298`, `scripts/build-loop.sh:321-358`, `$S/logs/probe-status.txt`

---

## Claim 3: skip list: "for an open brief, another open brief on main … names the same branch (ignoring case) or the open briefs on main could not be listed, or on a branch ahead of main the tip's subject … starts "handoff:" but it is not a marker."

**Location:** `scripts/build-loop.sh:68-72`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers status_line's open-only F31 and "could not be listed" skips, the ahead > 0 marker skip, and marker_kind's `bad` arm. It does not establish that the marker skip holds when git's own config is broken (see below; pre-existing check_branch behaviour, outside the diff).

Code matches each part:

```bash
# scripts/build-loop.sh:338
  if [[ "$st" == open && "$SHARED_BRANCHES" == error ]]; then echo "skip $a: the open briefs on the default branch could not be listed"; return; fi
# scripts/build-loop.sh:352
      bad\ *) echo "skip $a: the tip of $br starts \"handoff:\" but is not a marker: ${kind#bad }"; return ;;
```

`bad` is reachable only after the subject has passed the `handoff:*` test (`:283`). Probes: a 0-ahead `handoff: junk` tip reads `working` (no skip). A 1-ahead `handoff: junk` tip skips with `the tip of feat/b starts "handoff:" but is not a marker: …`, and that brief was a **done** one. With `grep.patternType bogus`, the open brief skips with "could not be listed" and the done brief prints `ok`.

Why only Mostly accurate: the sentence nests "for an open brief" ahead of the list, and the marker clause follows only a comma and "or". A reader can take the marker skip as open-only, but the probe shows it applies to a done brief too. The precise version starts that clause as its own item, for example "; for any brief, on a branch ahead of main …". Residue: with the same bogus config, the done brief on a branch one commit ahead with a non-marker tip printed `ok … done review feat/b working 6cf3c072…  0` (empty DATE) instead of the skip. check_branch's `git rev-list --count` and `git log` also read grep config and fail, `ahead` comes back empty, and `[[ "" -gt 0 ]]` is false. That is pre-existing code, untouched by this diff.

Provenance: `bash $S/probe-status.sh $S/base/scripts/build-loop.sh` (cwd `$S/repos/status1`, 2026-10-06T04:32:45Z, exit 0), output `$S/logs/probe-status.txt`.

**Evidence:** `scripts/build-loop.sh:64-72`, `scripts/build-loop.sh:278-358` (marker_kind, shared_branches, status_line read whole), `scripts/lib/dev-cycle-read.sh:372-385` (check_branch), `$S/logs/probe-status.txt`

---

## Claim 4: "# the header, to the first non-empty line not starting with #" (help-range comment)

**Location:** `scripts/build-loop.sh:99`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers GNU sed's `2,/^[^#]/{/^#/p}` on empty, whitespace-only and comment lines, and this script's actual help output. It does not establish BSD sed behaviour (row 286: GNU only).

`^[^#]` needs one character that is not `#`, so an empty line neither matches nor ends the range, and it is not printed (only `/^#/` lines print). A whitespace-only line is non-empty and ends the range. Probe file `#!/bin/sh`, `# a`, empty, `# b`, two spaces, `# c`, `x=1`: output `# a`, `# b`. The range ended at the two-space line, and the empty line 3 did not end it. In build-loop.sh the first line from 3 on matching `^[^#]` is `81: set -euo pipefail`, after the empty line 80. `bash build-loop.sh --help` exited 0 with 78 lines, first `The build-loop handoff's state and checks: …`, last `lib/dev-cycle-read.sh, or no default branch found by name.`

Provenance: the commands in `$S/logs/probe-sed.txt` (cwd `$S` and `$S/repos`, 2026-10-06T04:32:59Z, help exit 0), output `$S/logs/probe-sed.txt`, `$S/logs/bl-help.txt`.

**Evidence:** `scripts/build-loop.sh:99`, `scripts/build-loop.sh:1-81`, `$S/logs/probe-sed.txt`, `$S/logs/bl-help.txt`

---

## Claim 5: "whether the next line outside a fence after the first is blank or the end of the file (NEXT 1) or not"

**Location:** `scripts/build-loop.sh:143-145`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers SETTINGS_AWK's nx[] for EOF, fenced lines (``` and ~~~), whitespace-only lines, a CR-only line and a key line directly after. It does not establish files FENCE_AWK refuses (those are not read at all).

```awk
# scripts/build-loop.sh:148-151, 156
{ sub(/\r$/, "") }
fence($0) { next }
{
  if (pk != "") { nx[pk] = ($0 ~ /^[ \t]*$/); pk = "" }
  …
  if (k != "") { c[k]++; if (c[k] == 1) { l1[k] = NR; t[k] = $0; nx[k] = 1; pk = k } …
```

(excerpt ends :156; SETTINGS_AWK continues to :162 — read)

Fence lines and fenced content hit `next` before pk is consumed. nx starts at 1, so EOF leaves it 1. "Blank" includes spaces and tabs. Probes: EOF gives `never a/ set` (n1). Tabs and spaces give set (n2). A fence then EOF gives set (n3). A fence then `y` gives `never malformed: line 2 is followed by a non-blank line outside a fence` (n4). A CR-only line gives set (n5). A policy line directly after gives malformed (n6). A ~~~ fence then a blank line gives set (n7). Mutants M7a (check before the fence skip) and M7b (`/^$/`) each fail the new --settings test.

Provenance: `$S/probe-settings.sh` n1-n7 (cwd `$S`, 2026-10-06T04:32:28Z, exit 0), `$S/logs/probe-settings.txt`, `$S/logs/mut-M7a.txt`, `$S/logs/mut-M7b.txt`.

**Evidence:** `scripts/build-loop.sh:140-162`, `scripts/lib/dev-cycle-read.sh:214-230` (fence()), `$S/logs/probe-settings.txt`

---

## Claim 6: "Exit 1 is "none"; an exit above 1 fails closed (SHARED_BRANCHES=error: every open brief skips). A brief git grep cannot read is not counted (row 293)."

**Location:** `scripts/build-loop.sh:307-309`
**Type:** Error-handling / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git grep 2.39.5's exit codes for a config error, a bad revision, no match and a missing blob, and how shared_branches and status_line then answer. It does not establish exit codes on other git versions, and it reads row 293's rationale as extending to git-grep-unreadable briefs (its text says only "unreadable open brief").

```bash
# scripts/build-loop.sh:310-311
  list="$(git grep --no-color -l -E '^Status: open'$'\r''?$' "$MAIN_SHA" -- docs/working/briefs/)" || rc=$?
  if [[ "$rc" -gt 1 ]]; then SHARED_BRANCHES=error; return; fi
```

(excerpt ends :311; enclosing shared_branches() continues to :320 — read)

Measured: `-c grep.patternType=bogus` gives rc=128, a bad revision gives rc=128, no match gives rc=1. With one open brief's blob deleted from `.git/objects`, git grep prints `error: '…:2026-10-01-c.md': unable to read 2929c19f…` and exits **0**, listing the other two. So the unreadable brief is not counted. a and c (both `feat/a`) then no longer collide, and a prints `ok`. c's own --status line is `skip …-c.md: the brief could not be read from the default branch`. Row 293 (`docs/reviews/override-log.md:293`) reads: "An unreadable open brief is not counted for F31 … Won't-Fix | The unreadable brief skips in its own --status line, so it is never dispatched." The probe shows that rationale holds for the git-grep case. "Every open brief skips" on error, with done briefs still answering, is confirmed in `$S/logs/probe-status.txt`.

Provenance: commands in `$S/logs/probe-grep.txt` (cwd `$S/repos/grep1`, 2026-10-06T04:33:08Z) and `$S/logs/probe-grep-rc.txt` (04:33:18Z); the build-loop.sh runs exited 0.

**Evidence:** `scripts/build-loop.sh:299-320`, `docs/reviews/override-log.md:293`, `$S/logs/probe-grep.txt`, `$S/logs/probe-grep-rc.txt`

---

## Claim 7: commit: "--status' "could not be listed" skip drops "(git grep failed)", matching the other reasons (U1c C38)."

**Location:** `scripts/build-loop.sh:338`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the printed string and its test. It does not establish that downstream readers (U4's skill, not yet written) did not depend on the old suffix.

`echo "skip $a: the open briefs on the default branch could not be listed"` (`scripts/build-loop.sh:338`). The probe printed exactly that, and the existing test asserts it exactly (`test/scripts/build-loop-read.bats:388`). No other skip reason in status_line names a mechanism in parentheses except "(compared ignoring case)", which names a rule.

**Evidence:** `scripts/build-loop.sh:321-358`, `test/scripts/build-loop-read.bats:386-389`, `$S/logs/probe-status.txt`

---

## Claim 8: "it reads what main's copy says until it lands there" (--check-answer help)

**Location:** `scripts/dev-cycle.sh:59`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers check_answer reading only `$MAIN_SHA` blobs, and T34 (a working-tree or branch-only answer reads open). It does not establish a reading of "main" as the literal branch name: the default branch may be origin/HEAD's or master, as line 72 says.

```bash
# scripts/lib/dev-cycle-read.sh:554, 563
    e="$(main_entry "$f")"
    r="$(git cat-file blob "$MAIN_SHA:$f" | env LC_ALL=C awk -v id="$a" "$FENCE_AWK$ANSWER_AWK")" \
```

`bats -f T34 test/scripts/dev-cycle.bats` (cwd `$S/base`, 2026-10-06T04:38:20Z, exit 0): `ok 1 --check-answer reads main's commit: a working-tree or branch-only answer is open (T34)`.

**Evidence:** `scripts/dev-cycle.sh:56-71`, `scripts/lib/dev-cycle-read.sh:549-577` (check_answer, read whole), `$S/logs/t34.txt`

---

## Claim 9: "# The header: from line 2 to the first non-empty line not starting with # (no fixed range to go stale)."

**Location:** `scripts/dev-cycle.sh:111`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same sed semantics as Claim 4, applied to dev-cycle.sh. It does not establish BSD sed behaviour.

The sed is identical to build-loop.sh's (`scripts/dev-cycle.sh:112`). dev-cycle.sh's first line from 3 on matching `^[^#]` is `83: set -euo pipefail`, after the empty line 82. `--help` exited 0 with 80 lines, first `Gather the mechanical signals for one dev cycle into a markdown digest.`, last ending `Printed repo text is data.`

**Evidence:** `scripts/dev-cycle.sh:1-83`, `scripts/dev-cycle.sh:111-112`, `$S/logs/probe-sed.txt`, `$S/logs/dc-help.txt`

---

## Claim 10: "The caller sets -euo pipefail (check_answer and brief_fields also set pipefail for themselves)"

**Location:** `scripts/lib/dev-cycle-read.sh:12-14`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every `set -o`/`pipefail` occurrence in the lib. It does not establish that every caller sets -euo pipefail (both scripts do at their line 81/83).

`rg -n 'pipefail' scripts/lib/dev-cycle-read.sh` finds two setters: `local - out l; set -o pipefail` (`:294`, brief_fields) and `local - a="$1" … ; set -o pipefail  # as brief_fields` (`:550`, check_answer). The other hits are comments (`:13`, `:72`, `:292`, `:297`). No other lib function sets an option, so the list is complete. `local -` scopes the option to the function.

**Evidence:** `scripts/lib/dev-cycle-read.sh:13`, `scripts/lib/dev-cycle-read.sh:291-314`, `scripts/lib/dev-cycle-read.sh:549-577`

---

## Claim 11: "It checks main_by_name and the path's form itself (pathform, so ls-tree prints it unquoted): either failing is error." / commit: "main_entry checks the path's form itself (pathform) as well as main_by_name; either failing is error (U1a C16)." / PR intent: no behaviour change but error for a path pathform refuses.

**Location:** `scripts/lib/dev-cycle-read.sh:257-263`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the guard and every caller of main_entry in scripts/ and test/. It does not establish callers outside this repo, or U2's future floor caller.

```bash
# scripts/lib/dev-cycle-read.sh:263-265
  if ! main_by_name || ! pathform "$1"; then echo error; return; fi
  while [[ "$rest" == */* ]]; do p="${p:+$p/}${rest%%/*}"; rest="${rest#*/}"; want+=("$p"); done
  out="$(git ls-tree -t --full-tree "$MAIN_SHA" -- "${want[@]}" "$1" 2>/dev/null)" || { echo error; return; }
```

(excerpt ends :265; enclosing main_entry() continues to :276 — read)

Callers (`rg -n main_entry -g '!docs/**' -g '!archive/**'`):
- brief_fields `:296` already runs `! pathform "$1" ||` first.
- check_brief `:334` runs after `pathform "$a"` at `:327`.
- check_answer `:554` passes only `docs/working/questions.md` and `docs/working/questions-archive.md`.
- build-loop.sh main_file `:124` passes only `docs/dev-cycle.md` and `docs/constraints.md` (`:206`, `:259`).
- dev-cycle.sh has no call.
- Tests call it directly (dev-cycle.bats:1234-1235, :1330).

All four fixed names pass pathform: letters, `/`, `-`, `.`, and no `.git` part. pathform is locale-independent (`:136-140`). No caller can newly get `error`, and every caller's mapping of `error` is unchanged. Mutant M5 (guard without pathform) makes the new test print `absent error absent absent`. Only `../x` already reached `error` through ls-tree.

**Evidence:** `scripts/lib/dev-cycle-read.sh:141-150`, `scripts/lib/dev-cycle-read.sh:248-276`, `:291-362`, `:549-577`, `scripts/build-loop.sh:121-138`, `$S/logs/mut-M5.txt`

---

## Claim 12: test comment "A caller's own GIT_CONFIG_COUNT pairs stay, and the guard still applies after them." / commit: "a caller's own GIT_CONFIG_COUNT pairs with a replace ref"

**Location:** `test/scripts/build-loop-read.bats:420-425`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which guard regressions the test detects. It does not establish (and the test does not assert) that the caller's own pair survives.

The test passes `GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=user.name …` with a planted replace ref and `core.useReplaceRefs true`, and asserts only `[[ "$(line policy)" == "policy review set:"* ]]` (`:425`). Removing the guard pair (M3) fails it: the replace blob is read and the result is `policy self-merge set`. Not counting the pair (M4c) also fails it. So "the guard still applies after them" is tested. "Pairs stay" is true of the code (`export "GIT_CONFIG_KEY_$cfg=…" … GIT_CONFIG_COUNT=$((cfg + 1))`, `scripts/build-loop.sh:112`), but it is not asserted. M4 (`cfg=0`, which overwrites the caller's KEY_0) passes this test and the full suite, 92/92. A test that kills M4 must observe the caller's pair, for example by checking `git config user.name` through a stub.

**Evidence:** `test/scripts/build-loop-read.bats:420-425`, `scripts/build-loop.sh:108-113`, `$S/logs/mut-M3.txt`, `$S/logs/mut-M4.txt`, `$S/logs/mut-M4c.txt`, `$S/logs/full-M4.txt`

---

## Claim 13: test title "--settings: deferred cases: reasons, review with a malformed never line, the next-line rule, an absent file, a caller's config (U1d)" and commit bullet "exact "not an allowed glob form" and "twice" reasons; review with a malformed never line; the fence half of the next-line rule; a whitespace-only blank line; the slots line for an absent file"

**Location:** `test/scripts/build-loop-read.bats:402-426`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each named case's assertion and its power to fail (M7a, M7b; exact strings for the reasons and the policy). It does not establish the "unread file" half of row 246's "absent or unread" slots gap. No test anywhere asserts the slots line for a file FENCE_AWK refuses: `:48` and `:54` assert policy and never only.

Each named case has an exact or prefix assertion:
- the reasons, exact: `:405`, `:407`;
- review with a malformed never line, `policy review set: line 1 …`: `:410`;
- fence then blank gives set, and fence then `b/` gives malformed: `:412-415`;
- whitespace-only gives set: `:416-417`;
- absent file, `slots 3 default: no docs/dev-cycle.md on the default branch`: `:419`.

The commit says "an absent file", not "absent or unread", so the claim is accurate as written. Row 246's unread case stays open. The whole test passes at base (`$S/logs/base-filtered.txt`).

**Evidence:** `test/scripts/build-loop-read.bats:402-426`, `scripts/build-loop.sh:205-214`, `$S/logs/base-filtered.txt`, `$S/logs/mut-M7a.txt`, `$S/logs/mut-M7b.txt`

---

## Claim 14: test title "build-loop.sh --help prints the whole header, through its last line (U1d)" / commit: "build-loop.sh --help ends at the header's last line"

**Location:** `test/scripts/build-loop-read.bats:428-432`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers status 0, the first line, and the last line matching the header's line 79. It does not establish that middle lines are all printed, or the `-h` spelling (row 246 G11 named -h; it shares the case arm).

The assertions are `lines[0]` == `"The build-loop handoff's state and checks"*` and the last line == `*"or no default branch found by name."` (`:430-431`). These match the header's first and last comment lines (`scripts/build-loop.sh:2`, `:79`) and the probe's output (`$S/logs/bl-help.txt`).

**Evidence:** `test/scripts/build-loop-read.bats:428-432`, `scripts/build-loop.sh:2-79`, `$S/logs/bl-help.txt`

---

## Claim 15a: test title/comment "no open brief" ("No open brief on main at all (git grep exits 1): a done brief reads normally.")

**Location:** `test/scripts/build-loop-read.bats:436-439`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the fixture state (only a done brief, so git grep exits 1) and the asserted output. It does not establish that the exit-1 ("none") branch is tested.

The comment's facts hold: the only brief is `Status: done`, so git grep finds nothing and exits 1 (measured rc=1 for no match, `$S/logs/probe-grep-rc.txt`), and the done brief prints `ok`. But status_line consults SHARED_BRANCHES only when `"$st" == open` (`scripts/build-loop.sh:338-339`), so a done brief's line cannot show how exit 1 was handled. Mutant M13 (`rc -gt 0`, failing closed on "none") passes this test and the full suite, 92/92. As a regression test for "Exit 1 is none" it has no power. An open queried brief always makes git grep exit 0, so that branch is observable only with, for example, a fenced or CR-mangled Status line.

**Evidence:** `test/scripts/build-loop-read.bats:436-439`, `scripts/build-loop.sh:310-311`, `:338`, `$S/logs/mut-M13.txt`, `$S/logs/full-M13.txt`

---

## Claim 15b: test title "F31's open-only filter" / commit "a done brief sharing an open brief's branch"

**Location:** `test/scripts/build-loop-read.bats:440-443`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the done-plus-open same-branch case against three filter mutants. It does not establish that either of F31's two open filters is tested on its own.

F31 filters for open twice: git grep's `'^Status: open'$'\r''?$'` (`:310`) and the loop's `"${BRIEF[status]-}" == "Status: open"` (`:315`). Removing the loop check (M12a) passes, because grep never lists the done brief. Loosening grep to `'^Status: '` (M12b) passes, because the loop check drops it. Only both together (M12c) fail, at `:443`. The commit bullet ("a done brief sharing an open brief's branch") is exactly what the test does. The title's "F31's open-only filter" holds for the pair, not for either filter.

**Evidence:** `test/scripts/build-loop-read.bats:440-443`, `scripts/build-loop.sh:310-317`, `$S/logs/mut-M12a.txt`, `$S/logs/mut-M12b.txt`, `$S/logs/mut-M12c.txt`, `$S/logs/full-M12a.txt`, `$S/logs/full-M12b.txt`

---

## Claim 15c: test cases "CRLF", "an unanchored closed", "NUL", "BRIEF kept" (commit: "a CRLF open brief counting for F31; the queried brief's fields kept while F31 reads others; a directory whose name contains "closed"; a NUL byte in a brief")

**Location:** `test/scripts/build-loop-read.bats:444-462`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers M10 (CRLF), M2 (anchor), M14 (NUL) and M1b (BRIEF kept with the call moved). It does not establish that "BRIEF kept" detects a dropped local BRIEF while the call order stays as it is (M1a survives; see Claim 18).

- M10 (no `\r?` in the grep regex) fails.
- M2 (`${f/closed\//}`) fails at `:453`: o skips because `2026-10-0closed/1-x.md` maps to an isbrief path.
- M14 (NUL refusal off) fails.
- M1b fails at `:457` with `ok … feat/q absent - - 3`, so q's fields replaced o's.

**Evidence:** `test/scripts/build-loop-read.bats:444-462`, `scripts/build-loop.sh:303-358`, `scripts/lib/dev-cycle-read.sh:217`, `$S/logs/mut-M10.txt`, `$S/logs/mut-M2.txt`, `$S/logs/mut-M14.txt`, `$S/logs/mut-M1b.txt`

---

## Claim 16: test title "--check-brief, --check-branch and --check-answer need a default branch found by name; the others do not", with the loop extended to --check-answer feat/x

**Location:** `test/scripts/dev-cycle.bats:813-823`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers dev-cycle.sh's script-level gate (`:193`) for --check-answer. It does not establish check_answer's own `main_by_name` guard (`lib:552`), which the gate shadows, or "the others" beyond --check-path.

At base, `--check-answer feat/x` on a trunk-only repo exits 1 with `--check-answer needs a default branch (origin/HEAD, main or master); found none`. With the gate's `--check-answer` dropped (M6), it exits 0 with `skip feat/x: not a question ID (Q- and digits)`. That fails the test at `[ "$status" -eq 1 ]` (`:818`), so it fails for the gate's absence. Because `feat/x` is not a question ID, check_answer rejects it before its own main_by_name check (`lib:551` precedes `:552`). The argument therefore never exercises the lib's default-branch reason, but the test is about the script gate.

Provenance: `bash $S/{base,mut/M6}/scripts/dev-cycle.sh --check-answer feat/x` (cwd `$S/repos/m6`, 2026-10-06T04:38:20Z, exit 1 and 0), `$S/logs/m6-direct.txt`.

**Evidence:** `test/scripts/dev-cycle.bats:813-823`, `scripts/dev-cycle.sh:188-195`, `scripts/lib/dev-cycle-read.sh:549-552`, `$S/logs/mut-M6.txt`, `$S/logs/m6-direct.txt`

---

## Claim 17: test title "main_entry refuses a path pathform refuses, before any read (U1d)"

**Location:** `test/scripts/dev-cycle.bats:1328-1335`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the refusal (`error` for four refused paths) and the code's ordering. It does not establish that the test detects a read before the refusal.

The code checks before reading (`:263` precedes the ls-tree at `:265`), and M5 fails the test (Claim 11). But "before any read" is not asserted. Mutant M5b moves pathform after the ls-tree read and passes this test and the full suite, 92/92, because the output is still `error` ×4. Asserting the ordering needs a git PATH shim that logs argv, as the U1a review did (`docs/reviews/code-fact-check-submitted-claims-build-loop-u1a.md`, Claim 42).

**Evidence:** `test/scripts/dev-cycle.bats:1328-1335`, `scripts/lib/dev-cycle-read.sh:260-276`, `$S/logs/mut-M5.txt`, `$S/logs/mut-M5b.txt`, `$S/logs/full-M5b.txt`

---

## Claim 18: commit: "Mutants that drop the local BRIEF (moving the call), or un-anchor the closed/ prefix, fail the new --status test."

**Location:** commit 83cdb005 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two mutants as described: local BRIEF dropped together with the shared_branches call moved after brief_fields, and the pre-C30 `${f/closed\//}`. It does not establish that dropping the local BRIEF alone is caught: M1a survives, so the parenthetical is load-bearing.

M1b and M2 each fail `--status: deferred cases …` (table above). M1a (local dropped, call order unchanged) passes it and the full suite, 92/92. status_line calls shared_branches before its own `brief_fields "$a"` (`scripts/build-loop.sh:323`, `:328`), so the order alone still protects BRIEF. M1c (call moved, local kept) passes, which shows the local BRIEF alone is enough.

**Evidence:** `scripts/build-loop.sh:303-305`, `:321-328`, `$S/logs/mut-M1a.txt`, `$S/logs/mut-M1b.txt`, `$S/logs/mut-M1c.txt`, `$S/logs/mut-M2.txt`, `$S/logs/full-M1a.txt`

---

## Claim 19: commit Notes: "118 changed code lines."

**Location:** commit 83cdb005 message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `git diff --numstat main...HEAD` added + deleted. It does not establish a count of non-comment code lines: the 118 include comment and test lines, as earlier units' cap counts did.

`git diff --numstat main...HEAD` (cwd the worktree, 2026-10-06 about 04:33Z, exit 0) gives 15/12 build-loop.sh, 2/2 dev-cycle.sh, 6/4 lib, 63/1 build-loop-read.bats and 11/2 dev-cycle.bats. That sums to 97 + 21 = 118.

**Evidence:** `git diff --numstat main...HEAD` output (reproduced in this claim; command shown, exit 0)

---

## Claim 20: commit Wording bullets: "U1a A19-A22, C19 … U1b A25-A27 … U1c A24, A25, C37" land as worded

**Location:** commit 83cdb005 message; `scripts/build-loop.sh:17-18, 61-72, 99, 143-145, 308-309`, `scripts/dev-cycle.sh:59, 111`, `scripts/lib/dev-cycle-read.sh:13-14, 257-259`, `test/scripts/dev-cycle.bats:813`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers whether each named wording item appears in the diff as the override rows ask. It does not re-verdict the wording's truth (Claims 1-11 do that).

Each item is present:
- A19: the title and loop include --check-answer.
- A20: "until it lands there".
- A21, A27: both help-range comments.
- A22: main_entry's comment.
- C19: the lib header.
- A25: "with no exact never line beside it".
- A26: "next line outside a fence … or the end of the file".
- U1c A24: "on a branch ahead of main", and line 62 is re-wrapped.
- U1c A25: "an exit above 1".
- C37: "could not be listed" is in the skip list.

Only Mostly accurate because A25's chosen wording carries the implication refuted in Claim 1, and U1c A24's insertion placed the marker clause where it can read as open-only (Claim 3).

**Evidence:** `docs/reviews/override-log.md:278`, `:283`, `:287`, `:299`; the diff hunks in the cited lines

---

## Claims Requiring Attention

### Incorrect
- None.

### Stale
- None.

### Mostly Accurate
- **Claim 1** (`scripts/build-loop.sh:17-18`): an exact never line beside a hidden copy keeps self-merge on only when the copy is uncounted (letter-adding markup) or fenced. A counted copy (`- Self-merge never: …`) makes two copies, malformed, so off. Say "…with no exact never line beside it (and a second counted copy still turns it off)", or similar.
- **Claim 3** (`scripts/build-loop.sh:68-72`): the marker skip applies to any brief state, but it sits after "for an open brief, …" joined by ", or". Make it a separate item. Residue: under a broken git config, check_branch's empty ahead count skips the marker check (pre-existing).
- **Claim 12** (`test/scripts/build-loop-read.bats:420`): "pairs stay" is unasserted. M4 (guard clobbers the caller's KEY_0) survives.
- **Claim 15a** (`test/scripts/build-loop-read.bats:436`): the "no open brief" case cannot fail on a regression of the exit-1 branch. M13 survives.
- **Claim 15b** (`test/scripts/build-loop-read.bats:440`): "F31's open-only filter" kills only both filters removed together. M12a and M12b each survive.
- **Claim 17** (`test/scripts/dev-cycle.bats:1328`): "before any read" is unasserted. M5b (pathform after ls-tree) survives.
- **Claim 20** (commit Wording bullets): all items land; two carry the residues of Claims 1 and 3.

### Unverifiable
- None.

## Goal-Alignment Note

Goal: fact-check every claim in U1d's comments, help, test titles and commit message, executing where possible. All 22 claims (20 numbered, three of them split) were executed or grepped. The two code changes (main_entry's pathform guard, the shortened skip reason) behave as stated and change nothing else for any caller (Claim 11). The wording deferrals all land (Claim 20), with two imprecisions (Claims 1, 3). The test deferrals are present, but four new cases are weaker than their titles or comments: Claims 12, 15a, 15b and 17, each with a surviving mutant named. Row 246's "unread" slots case is also still unasserted (Claim 13 scope). None blocks the goal; they are inputs for the rubric.
