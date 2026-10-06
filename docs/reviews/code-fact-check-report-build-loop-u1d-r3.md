Commit: ab71bce5

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u1d (branch feat/build-loop-u1d)
**Scope:** `git diff main...HEAD -- scripts test` at ab71bce5 (scripts/build-loop.sh, scripts/dev-cycle.sh, scripts/lib/dev-cycle-read.sh, test/scripts/build-loop-read.bats, test/scripts/dev-cycle.bats) and the messages of 83cdb005, 6c83af2a and 07c354c5. Final confirming pass, replicate r3 of k=3.
**Checked:** 2026-10-06
**Total claims checked:** 34
**Summary:** 31 verified, 2 mostly accurate, 0 stale, 1 incorrect, 0 unverifiable

The hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) was read first. Its five entries are of two kinds: a measured value quoted from an artifact set that does not hold it, and a file-to-symbol link that was never grepped. Every measured value here was recomputed: the 118 and 151 line counts and the 19/73 test counts. Every symbol named was grepped: main_entry's callers, rows 291 and 293, and the pipefail setters. No claim matches a logged pattern.

**Execution provenance.** `$S` = `/tmp/claude-1000/-workspace/57e599b8-f769-48da-96c7-3a02f99f2a8d/scratchpad/review-u1d/f-fc3` and `$L` = `$S/logs`. `$S/base` is a copy of the worktree's scripts/, test/ and docs/dev-cycle.md at ab71bce5, and `git diff 07c354c5 HEAD -- scripts test` is empty. Each mutant is a fresh copy `$S/m-NAME` of `$S/base`, made by `$S/mut.sh` or `$S/mutl.sh` (a literal perl replacement). Each runs `timeout 600 bats -f FILTER SUITE` in that copy. Its log `$L/mut-NAME.txt` records the applied diff, the command, a UTC timestamp on line 1 and the exit code on the last line. `$S/old83` and `$S/old6c` are `git archive` copies of 83cdb005 and 6c83af2a, with logs `$L/m83-*.txt` and `$L/m6c-*.txt`. Baseline: `timeout 900 bats test/scripts/build-loop-read.bats test/scripts/dev-cycle.bats test/fixture-hermeticity.bats` in `$S/base` at 2026-10-06T05:21:34Z exited 0 with 94/94 ok (`$L/baseline.txt`).

---

## Claim 1: "Self-merge also needs one valid never line. A never list in markup the copy count sees (bold, a list marker, an unchecked task box) counts as a copy, so self-merge is off; one it misses (a checked task box, a fence) is ignored, so self-merge rests on the valid line alone."

**Location:** `scripts/build-loop.sh:17-21`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the five named markup forms (plus `- [X]`), each alone, before and after a valid `Self-merge never: none` line, with `Build-loop policy: self-merge`. It does not cover other markup the header's best-effort clause (`:42-45`) already calls unreliable, such as tags or other letter-adding prefixes.

The copy count drops all but letters (`scripts/build-loop.sh:156`: `s = tolower($0); gsub(/[^a-z]/, "", s)`), so `**`, `- ` and `[ ]` add no letters, while `[x]` adds an `x`. Fence lines never reach it (`:153` `fence($0) { next }`). Self-merge needs never_ok (`:254` `if [[ "$v" == self-merge && -z "$never_ok" ]]`). Probe `$S/probe-never.sh`, run as `timeout 300 $S/probe-never.sh` (cwd `$S/probe-never`, exit 0, 2026-10-06T05:26:58Z). Bold, list and unchecked: alone, the line is malformed ("is not exactly"). Beside a valid line, either order: "more than one line starts" and policy review unset. Checked (`[x]` and `[X]`) and fenced: alone gives `never none: no line starts` with self-merge off. Beside a valid line, either order: `policy self-merge set`. The printed reason uses "valid" (`:255` "there is no valid Self-merge never: line"), matching the header.

**Evidence:** `scripts/build-loop.sh:151-166`, `scripts/build-loop.sh:226-256`, `$L/probe-never.txt`

---

## Claim 2: "A tip on a branch level with main, or whose subject does not start "handoff:", is working. DISPATCHED: the brief's "Dispatched: N" (0-99), or 0 without one."

**Location:** `scripts/build-loop.sh:64-66`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a branch level with main whose tip says `handoff: bogus2`, and the 0/99 bounds through the Dispatched mutants. A branch *behind* main (also 0 ahead) also reads working. The sentence does not name that case, though the marker definition at `:58-59` ("at least one commit ahead") implies it. Not covered: a reader treating "level with" as the only non-ahead case.

`loop=working` is set before the marker read, which runs only when `[[ "$ahead" -gt 0 ]]` (`scripts/build-loop.sh:353-354`), and `marker_kind` prints `working` for a non-`handoff:` subject (`:287`). In probe A of `$S/probe-status.sh` (cwd `$S/probe-status`, exit 0, 2026-10-06T05:27:35Z), `feat/lv` level with main read `ok ... feat/lv working`. `feat/bh` behind main with a `handoff: bogus` tip read `ok ... feat/bh working`. Dispatched is parsed by `:338` `^Dispatched:\ (0|[123456789][0123456789]?)$`, and `disp=0` is the default (`:327`). Mutants `disp0` (drop `0|`) and `disp99` (drop the second digit) each fail the U1d --status test, at `:455` and `:462` (`$L/mut-disp0.txt`, `$L/mut-disp99.txt`, both exit 1).

**Evidence:** `scripts/build-loop.sh:327-362`, `$L/probe-status.txt`, `$L/mut-disp0.txt`, `$L/mut-disp99.txt`

---

## Claim 3: skip list: "... on a branch ahead of main the tip's subject (its message's first line) starts "handoff:" but it is not a marker, or, for an open brief only, another open brief on main (in briefs/ or closed/) names the same branch (ignoring case) or the open briefs on main could not be listed."

**Location:** `scripts/build-loop.sh:71-75`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the marker skip for open, done and dropped briefs on an ahead branch, and the shared-branch and could-not-be-listed skips firing for open briefs but not done ones. It does not re-test the earlier clauses (unreadable, Branch/Dispatched malformed, refused name), which this diff only re-wraps.

The marker skip has no state condition: `scripts/build-loop.sh:354-357` (`if [[ "$ahead" -gt 0 ]]; then kind="$(marker_kind "$sha")"` … `bad\ *) echo "skip $a: the tip of $br starts \"handoff:\" but is not a marker: ..."`). Both F31 skips are gated on `st == open` (`:343` and `:344`). Probe A gave skip lines for open `op`, done `dn` and dropped `dr` on ahead branches. Probe B gave open a and b skipping on a shared branch while done c read `ok`. Probe C (corrupt object) gave open a skipping "could not be listed" while done c read `ok`.

**Evidence:** `scripts/build-loop.sh:326-362`, `$L/probe-status.txt`

---

## Claim 4: "# The header: from line 2 to the first non-empty line not starting with # (no fixed range to go stale)."

**Location:** `scripts/build-loop.sh:102`, `scripts/dev-cycle.sh:111`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both scripts' -h and --help output against their headers. It does not cover non-GNU sed (row 286, Won't-Fix).

`sed -n '2,/^[^#]/{/^#/p}'` (`scripts/build-loop.sh:103`): `^[^#]` needs one character that is not `#`, so an empty line cannot end the range, and only `#` lines print. In `$S/base` at 2026-10-06T05:28:04Z (`$L/probe-help.txt`), build-loop.sh's range ends at line 84 (`set -euo pipefail`). -h and --help each print 81 lines (exit 0), the header's 81 `#` lines from 2 to 83, the last being "lib/dev-cycle-read.sh, or no default branch found by name.". dev-cycle.sh ends at line 83, with 80 lines and last "... Printed repo text is data.". Both comments now sit on their own line, as 07c354c5's C15 says.

**Evidence:** `scripts/build-loop.sh:102-103`, `scripts/dev-cycle.sh:111-112`, `$L/probe-help.txt`

---

## Claim 5: "whether the next line outside a fence after the first is blank or the end of the file (NEXT 1) or not"

**Location:** `scripts/build-loop.sh:147-149`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the fence-skip, whitespace-only and end-of-file arms. It does not cover a file FENCE_AWK refuses, which is never read.

`nx[k] = 1` on the first copy (`scripts/build-loop.sh:160`), which stands if no later line comes (end of file). The next line that reaches `:155` sets `nx[pk] = ($0 ~ /^[ \t]*$/)`, and fence lines are skipped by `:153` before it. Mutant `fencenext` moves the NEXT update above `fence($0) { next }` and fails the U1d settings test at `:425` (`$L/mut-fencenext.txt`, exit 1). Mutant `tabblank` (`/^ *$/`) fails it at `:429`, the `$' \t '` step (`$L/mut-tabblank.txt`, exit 1).

**Evidence:** `scripts/build-loop.sh:151-166`, `$L/mut-fencenext.txt`, `$L/mut-tabblank.txt`

---

## Claim 6: "Exit 1 is "none"; an exit above 1, a corrupt object's included, fails closed (SHARED_BRANCHES=error: every open brief skips). A brief whose object is missing (git grep warns, exits 0 or 1) is not counted (row 293)."

**Location:** `scripts/build-loop.sh:311-314`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a corrupt loose object (exit 128), a missing loose object with another match (exit 0) and without one (exit 1), and the --status line each yields. It does not cover packed-object corruption, which security i2 executed. Row 293's text is about unreadable briefs in general; it is cited, not re-derived.

`if [[ "$rc" -gt 1 ]]; then SHARED_BRANCHES=error; return; fi` (`scripts/build-loop.sh:316`). Probe C, with open brief b's loose blob overwritten: `git grep exit 128` ("loose object ... is corrupt"), and `--status` printed `skip ...-a.md: the open briefs on the default branch could not be listed` while done brief c read `ok`. Probe D, with b's blob deleted: `git grep exit 0` listing only a, with a warning ("unable to read"). Brief a, which shares b's branch, read `ok ... open review feat/x`, so b was not counted. Probe E (the only open brief's blob deleted): `git grep exit 1`. All in `$L/probe-status.txt` (`timeout 300 $S/probe-status.sh`, cwd `$S/probe-status`, exit 0, 2026-10-06T05:27:35Z).

**Evidence:** `scripts/build-loop.sh:307-325`, `$L/probe-status.txt`

---

## Claim 7: commit 83cdb005: "--status' "could not be listed" skip drops "(git grep failed)", matching the other reasons (U1c C38)." / PR intent: behaviour changes only there and in main_entry.

**Location:** `scripts/build-loop.sh:343`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every changed non-comment line in scripts/. It does not establish that no consumer parses the old suffix; the grep below found none in scripts/ or test/.

`echo "skip $a: the open briefs on the default branch could not be listed"; return` (`scripts/build-loop.sh:343`). The other non-comment changes in scripts/ are the `-h|--help` line, which only loses its trailing comment (`:103`), and main_entry's guard (`scripts/lib/dev-cycle-read.sh:265`). dev-cycle.sh's two changes are comments. Paraphrased — no quote available because this is the absence of other code changes, read from `git diff main...HEAD -- scripts`.

**Evidence:** `scripts/build-loop.sh:343`, `scripts/build-loop.sh:103`, `scripts/lib/dev-cycle-read.sh:265`

---

## Claim 8: "(an answer only in the working tree is not seen: it reads what main's copy says until it lands there)"

**Location:** `scripts/dev-cycle.sh:58-59`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers check_answer's read source. It does not establish when an answer "lands" (any commit on the default branch's tip counts).

`r="$(git cat-file blob "$MAIN_SHA:$f" | env LC_ALL=C awk ...)"` (`scripts/lib/dev-cycle-read.sh:565`). check_answer reads only `$MAIN_SHA`'s blobs, after `main_entry "$f"` checks the same commit's tree (`:556`). It never opens a working-tree file.

**Evidence:** `scripts/lib/dev-cycle-read.sh:543-579`

---

## Claim 9: "The caller sets -euo pipefail (check_answer and brief_fields also set pipefail for themselves)"

**Location:** `scripts/lib/dev-cycle-read.sh:12-14`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every `pipefail` in the lib and both callers. It does not establish behaviour under a caller that omits `-e`.

`local - out l; set -o pipefail` (`scripts/lib/dev-cycle-read.sh:296`, brief_fields) and `local - a="$1" ... ; set -o pipefail  # as brief_fields` (`:552`, check_answer) are the only `set -o pipefail` in the lib. `scripts/build-loop.sh:84` and `scripts/dev-cycle.sh:83` set `set -euo pipefail`. scrub_reexec reads `${PIPESTATUS[0]}` (`:82`) and sets nothing.

**Evidence:** `scripts/lib/dev-cycle-read.sh:78-83`, `scripts/lib/dev-cycle-read.sh:293-316`, `scripts/lib/dev-cycle-read.sh:551-552`

---

## Claim 10: "(main_entry and brief_fields answer error)" without main found by name, in the header (lib:23-25) and the MAIN comment ("never for the current branch's fallback or before resolve_main has succeeded (main_entry and brief_fields answer error)")

**Location:** `scripts/lib/dev-cycle-read.sh:23-25`, `scripts/lib/dev-cycle-read.sh:244-247`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both functions before resolve_main, after a fallback resolve_main (no main or master) and with main. For brief_fields, "answer error" means it sets `BRIEF_ODD=error` and returns 1 with no keys set; it prints nothing. That is the meaning its own docstring (`:288-290`) gives.

`if ! main_by_name || ! pathform "$1"; then echo error; return; fi` (`scripts/lib/dev-cycle-read.sh:265`). `if ! pathform "$1" || [[ "$(main_entry "$1")" != blob ]]; then BRIEF_ODD=error; return 1; fi` (`:298`). `$S/probe-lib.sh` (cwd `$S/probe-lib`, exit 0, 2026-10-06T05:27:58Z) printed: before resolve_main, `main_entry=error` and `bf rc=1 BRIEF_ODD=error keys=0`. After a fallback (MAIN=trunk, BY_NAME empty), both gave error. With main, `blob` and `bf ok`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:244-249`, `scripts/lib/dev-cycle-read.sh:262-278`, `scripts/lib/dev-cycle-read.sh:293-298`, `$L/probe-lib.txt`

---

## Claim 11: main_entry's comment: "error" (no default branch found by name, a path pathform refuses, ls-tree failed, or the tree lists a name twice ...). "It runs main_by_name and pathform itself, before any read (pathform also means ls-tree prints the name unquoted)." / commit: "main_entry checks the path's form itself (pathform) as well as main_by_name; either failing is error (U1a C16)."

**Location:** `scripts/lib/dev-cycle-read.sh:255-261`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the guard's place (before ls-tree) and its answer for seven refused forms. "Unquoted" rests on pathform's character set (`:139`, letters, digits, `._/-`), none of which git's quotePath escapes. That was read, not run against every byte.

The guard is the function's first statement after its locals (`scripts/lib/dev-cycle-read.sh:265`), before `git ls-tree` at `:267`. `$L/probe-lib.txt` printed `error` for `a"b.md`, `../x`, `-x`, `docs//x.md`, `.gitattributes`, `.github/x.yml` and `docs/a b.md`. Mutant `meguard` drops `|| ! pathform "$1"` and fails `main_entry answers error ... (U1d)`, printing `absent / error / absent / absent` (`$L/mut-meguard.txt`, exit 1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:250-278`, `$L/probe-lib.txt`, `$L/mut-meguard.txt`

---

## Claim 12: (orchestrator item 4) every caller of main_entry: no output change beyond the stated two

**Location:** `scripts/lib/dev-cycle-read.sh:298`, `scripts/lib/dev-cycle-read.sh:336`, `scripts/lib/dev-cycle-read.sh:556`, `scripts/build-loop.sh:128`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four call sites found by `rg -n main_entry` outside docs/ (dev-cycle.sh has none). The tests at dev-cycle.bats:1234-1235 and :1332 call it directly. It does not cover U2's planned callers (row 306, deferred).

brief_fields runs `pathform "$1"` before main_entry (`:298`). check_brief runs `main_by_name` (`:328`) and `pathform "$a"` (`:329`) before `e="$(main_entry "$a")"` (`:336`). check_answer checks `main_by_name` (`:554`) and passes only the two literal paths `docs/working/questions.md` and `docs/working/questions-archive.md` (`:555-556`). main_file is called only with `docs/dev-cycle.md` and `docs/constraints.md` (`scripts/build-loop.sh:210`, `:263`), after `main_by_name || { ... exit 1; }` (`:119`). `$L/probe-lib.txt` shows pathform accepts all four literal paths, so the new guard cannot fire on any existing call. The full suites pass unchanged (`$L/baseline.txt`, 94/94).

**Evidence:** `scripts/lib/dev-cycle-read.sh:325-344`, `scripts/lib/dev-cycle-read.sh:551-558`, `scripts/build-loop.sh:119-142`, `$L/probe-lib.txt`, `$L/baseline.txt`

---

## Claim 13: T3's new step: the slots line for an unread file (6c83af2a: "T3 asserts the slots line for an unread file")

**Location:** `test/scripts/build-loop-read.bats:55`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the unbalanced-fence arm of `SLOTS_LINE="slots 3 default: $why"`. The other not-read reasons share that line of code.

`POLICY_LINE="policy review unset: $why"; SLOTS_LINE="slots 3 default: $why"` (`scripts/build-loop.sh:216`). Mutant `slotsunread` (`slots 3 default: unread`) fails T3 at `:55` (`$L/mut-slotsunread.txt`, exit 1).

**Evidence:** `scripts/build-loop.sh:214-218`, `$L/mut-slotsunread.txt`

---

## Claim 14: "# A never list the copy count misses (a checked task box) is skipped; with no exact never line beside it, self-merge is off."

**Location:** `test/scripts/build-loop-read.bats:118-119`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the step it annotates (`- [x] Self-merge never: b/` alone). The "ignored beside a valid line" arm is pinned by no test (row 313, Won't-Fix), though Claim 1's probe exercised it.

The step asserts `settings_is policy "$no"` (`:120`), where `$no` is the "no valid Self-merge never: line" reason (`:113`). `$L/probe-never.txt` `[checked alone]` shows `never none: no line starts "Self-merge never:"`: the line is not counted, and policy is review unset.

**Evidence:** `test/scripts/build-loop-read.bats:113-120`, `$L/probe-never.txt`

---

## Claim 15: 6c83af2a C9: "a bare "success:" line, a fenced H2 (constraints ok)"

**Location:** `test/scripts/build-loop-read.bats:185-190`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both steps against a targeted mutant each. A blunter mutant that removes CONSTRAINTS_AWK's fence() call fails earlier, at the refdef step `:178` (`$L/mut-fencedh2.txt`), so the narrow mutant below is the one that isolates the new step.

`/^[ \t]*(- )?success: [^ \t]/ { pend = "" }` (`scripts/build-loop.sh:184`) needs text after the colon. Mutant `baresuccess` (`success:/`) fails T44 at `:186` (`$L/mut-baresuccess.txt`, exit 1). Mutant `fencedh2b` reads fenced lines that start with `H`, and fails T44 at `:190` with `hard constraint H2 (line 4) has no success: line` (`$L/mut-fencedh2b.txt`, exit 1).

**Evidence:** `scripts/build-loop.sh:170-192`, `$L/mut-baresuccess.txt`, `$L/mut-fencedh2b.txt`

---

## Claim 16: 6c83af2a C9: "a 1-char stopped reason"

**Location:** `test/scripts/build-loop-read.bats:257-259`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the one-character arm of the REASON regex. The 120/121 bounds are pre-existing steps.

`LC_ALL=C grep -qxE '[!-~]([ -~]{0,118}[!-~])?'` (`scripts/build-loop.sh:300`). Mutant `stop1` makes the tail mandatory and fails T6 at `:259` (`$L/mut-stop1.txt`, exit 1). 07c354c5 split the step's `&&` chain: `:257` ends at `tip`, and `run` stands alone at `:258`.

**Evidence:** `scripts/build-loop.sh:298-301`, `test/scripts/build-loop-read.bats:257-259`, `$L/mut-stop1.txt`

---

## Claim 17: "# A marker whose message body holds a NUL byte (one commit ahead, same tree)." with the step's own update-ref and check lines (07c354c5 C13)

**Location:** `test/scripts/build-loop-read.bats:297-301`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the object is an otherwise valid empty marker, so only the NUL makes it bad, and that a deleted NUL check, a broken fixture build or a broken update-ref each fail T7. "One commit ahead" is exact only relative to `base`. Relative to main the branch is two commits ahead.

The object is built with `parent %s` = `$base` and `tree %s` = `$base^{tree}` (`:298`), and `base` is feat/a after `work` (`:272`), itself one commit ahead of main. So the NUL commit sits one commit on top of base, with base's tree, two ahead of main. The marker rule needs only "at least one commit ahead" (`scripts/build-loop.sh:58-59`), so the test is unaffected. Precise wording: "one commit on top of base, with its tree". All runs are T7 in their `$S/m-*` copy, exit 1:

- `nulcheck` (`build-loop.sh:288` deleted) fails at `:301`, printing `[nul] ... ready` (`$L/mut-nulcheck.txt`).
- `t7fix` (`--literally` → `--no-such-flag` in this step only) fails at `:299` with status 129 (`$L/mut-t7fix.txt`).
- `t7both` (both edits) fails at `:299` (`$L/mut-t7both.txt`). That confirms 07c354c5's "with --literally broken and the NUL check deleted, T7 now fails".
- `t7ur` (update-ref to a bad object) fails (`$L/mut-t7ur.txt`).

**Evidence:** `test/scripts/build-loop-read.bats:268-301`, `scripts/build-loop.sh:282-302`, `$L/mut-nulcheck.txt`, `$L/mut-t7fix.txt`, `$L/mut-t7both.txt`, `$L/mut-t7ur.txt`

---

## Claim 18: U1d --settings test title and comments: "reasons, review with a malformed never line, the next-line rule, an absent file, a caller's config"; "Under review a malformed never line leaves the policy as written."; "The next line outside a fence decides; a whitespace-only line is blank."

**Location:** `test/scripts/build-loop-read.bats:414-431`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each named case against a mutant that removes it. The two reason steps (`:415-418`) assert exact strings, so any change to `globform`'s or the dup check's wording fails them (seen in the green baseline, not mutated).

All are U1d-filtered runs, exit 1:

- `reviewmal` drops `"$v" == self-merge &&` from `:254` and fails at `:422` (`$L/mut-reviewmal.txt`).
- `fencenext` fails at `:425` (`$L/mut-fencenext.txt`).
- `tabblank` fails at `:429` (`$L/mut-tabblank.txt`).
- `slotsabs` fails at `:431`, the absent-file slots step (`$L/mut-slotsabs.txt`).

**Evidence:** `scripts/build-loop.sh:213-261`, `$L/mut-reviewmal.txt`, `$L/mut-fencenext.txt`, `$L/mut-tabblank.txt`, `$L/mut-slotsabs.txt`

---

## Claim 19: "# A caller's own GIT_CONFIG_COUNT does not stop the guard (that the caller's pairs still reach git is asserted in the --status deferred-cases test)." and "# A caller's own GIT_CONFIG_COUNT pair still reaches git beside the guard pair."

**Location:** `test/scripts/build-loop-read.bats:432-438`, `test/scripts/build-loop-read.bats:476-478`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two failure directions: the caller's count ignored (`cfg=0`) and the guard's count not raised past the caller's (`GIT_CONFIG_COUNT=1`). It does not cover a zero-padded count or `git -c`, which the script's comment (`:114-115`) leaves to the caller on purpose. `GIT_NO_REPLACE_OBJECTS` is row 311, deferred.

`cfg="${GIT_CONFIG_COUNT:-0}"; export "GIT_CONFIG_KEY_$cfg=core.useReplaceRefs" "GIT_CONFIG_VALUE_$cfg=false" GIT_CONFIG_COUNT=$((cfg + 1))` (`scripts/build-loop.sh:116`). Mutant `cfg0` passes the settings test and fails the --status test at `:478` (`$L/mut-cfg0.txt`, exit 1). Mutant `cfgcount1` fails the settings test at `:438` (`$L/mut-cfgcount1.txt`, exit 1). Each comment names the test that catches its own direction.

**Evidence:** `scripts/build-loop.sh:112-117`, `$L/mut-cfg0.txt`, `$L/mut-cfgcount1.txt`

---

## Claim 20: test titles "build-loop.sh -h and --help print the header from its first line through its last (U1d)" and "-h and --help print the header from its first line through its last"

**Location:** `test/scripts/build-loop-read.bats:441-447`, `test/scripts/dev-cycle.bats:1322-1328`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both flags and the first and last lines. A middle line dropped from the output would not be caught, and the titles do not claim it would be.

Each loops `for h in -h --help` and asserts `lines[0]` and the last line. Mutant `dash-h` (build-loop.sh `-h|--help` → `--help`) fails with `-h:` and empty output (`$L/mut-dash-h.txt`, exit 1), and `dc-dash-h` does the same for dev-cycle.sh (`$L/mut-dc-dash-h.txt`, exit 1). The asserted last lines match the headers' last lines (`$L/probe-help.txt`).

**Evidence:** `test/scripts/build-loop-read.bats:441-447`, `test/scripts/dev-cycle.bats:1322-1328`, `$L/mut-dash-h.txt`, `$L/mut-dc-dash-h.txt`, `$L/probe-help.txt`

---

## Claim 21: "# No open brief on main at all (git grep exits 1): a done brief reads normally. (A done brief never reads F31's answer, so this cannot tell exit 1 from a failure.)" / 07c354c5 A13: "a done brief never reads F31's answer (F31 still runs)."

**Location:** `test/scripts/build-loop-read.bats:451-452`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the fixture's git grep exit and status_line's use of SHARED_BRANCHES. The step does not distinguish exit 1 from a failure, and the comment says so.

`[[ -n "$SHARED_BRANCHES" ]] || shared_branches` runs for every argument (`scripts/build-loop.sh:328`). Its answer is read only under `"$st" == open` (`:343-344`). The same fixture (one done brief with Dispatched 0) gives `git grep exit 1` (`$L/probe-noopen.txt`, cwd `$S/probe-noopen`, 2026-10-06T05:30:33Z).

**Evidence:** `scripts/build-loop.sh:326-346`, `$L/probe-noopen.txt`

---

## Claim 22: "# A done brief sharing an open brief's branch does not make the open one skip, even with a later "Status: open" line that git grep lists (F31's own filter)." / title "F31's open-only filter"

**Location:** `test/scripts/build-loop-read.bats:456-461`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers F31's `BRIEF[status] == "Status: open"` term (the first Status line wins, as in brief_fields). It does not cover a dropped brief, which takes the same path.

`[[ "${BRIEF[status]-}" == "Status: open" && "${BRIEF[branch]-}" =~ ^Branch:\ ([^\ ]+)$ ]] || continue` (`scripts/build-loop.sh:320`). Mutant `f31status` drops the status term and fails at `:462` (`$L/mut-f31status.txt`, exit 1).

**Evidence:** `scripts/build-loop.sh:317-322`, `$L/mut-f31status.txt`

---

## Claim 23: "# Another open brief (CRLF line endings) on the same branch counts." and "# A directory whose name merely contains "closed" is not closed/."

**Location:** `test/scripts/build-loop-read.bats:463-470`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `\r?` in the git grep pattern and the `#` anchor of the closed/ substitution, each under normal fixture builds. Residue (executed): both fixtures are built in `&&` chains from 83cdb005 (`:464`, `:469`). If the fixture write fails, the step passes even with the guard removed, the same class 07c354c5 fixed in T7 (see Claim 33).

`git grep ... -E '^Status: open'$'\r''?$'` (`scripts/build-loop.sh:315`) and `isbrief "${f/#docs\/working\/briefs\/closed\//docs/working/briefs/}"` (`:319`). Mutant `crlf` (`'^Status: open$'`) fails at `:466`, and `unanchor` (`${f/closed\//}`) fails at `:471` (`$L/mut-crlf.txt`, `$L/mut-unanchor.txt`, exit 1). T28 alone does not catch `unanchor` (`$L/mut-unanchor2.txt`, exit 0), so this step is the one that pins it. Vacuity probes: `crlfvac` sends the CRLF printf to `/nonexistent/` and drops `\r?`, and `oddvac` does the same to the odd-dir printf and un-anchors. Both pass the U1d test (`$L/mut-crlfvac.txt`, `$L/mut-oddvac.txt`, exit 0).

**Evidence:** `scripts/build-loop.sh:315-319`, `$L/mut-crlf.txt`, `$L/mut-unanchor.txt`, `$L/mut-unanchor2.txt`, `$L/mut-crlfvac.txt`, `$L/mut-oddvac.txt`

---

## Claim 24: "# Another open brief on another branch, read by F31 after o, leaves o's fields alone." / title "BRIEF kept"

**Location:** `test/scripts/build-loop-read.bats:472-475`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers o's fields end to end, and a regression that both drops the local BRIEF and moves the F31 call after brief_fields. Dropping only the local BRIEF is not caught (row 312, deferred to U2), because status_line calls shared_branches before its own brief_fields.

`local -A n=() BRIEF=()  # a local BRIEF: the caller's stays as it was` (`scripts/build-loop.sh:309`). Mutant `briefmove` fails at `:475`, printing `ok ...-o.md open review feat/q absent - - 3` (`$L/mut-briefmove.txt`, exit 1). Mutant `brieflocal` (local only) passes (`$L/mut-brieflocal.txt`, exit 0), as row 312 records.

**Evidence:** `scripts/build-loop.sh:307-333`, `$L/mut-briefmove.txt`, `$L/mut-brieflocal.txt`

---

## Claim 25: "# A NUL byte refuses the brief, naming the line."

**Location:** `test/scripts/build-loop-read.bats:479-482`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers FENCE_AWK's NUL refusal through --status. If the overwrite failed, the placeholder `feat/\x01n` brief would be refused under a different reason, so this step cannot pass vacuously.

`if (index(l, "\0")) { refuse("nul"); return 1 }` (`scripts/lib/dev-cycle-read.sh:218`). Mutant `briefnul` deletes that line and fails at `:482`, printing `ok ... feat/nx absent - - 0` (`$L/mut-briefnul.txt`, exit 1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:215-220`, `$L/mut-briefnul.txt`

---

## Claim 26: test title "--check-brief, --check-branch and --check-answer need a default branch found by name; the others do not", with --check-answer in the loop

**Location:** `test/scripts/dev-cycle.bats:813-823`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers dev-cycle.sh's gate for --check-answer (exit 1, "needs a default branch"). The argument `feat/x` is not a question ID, so check_answer's own `main_by_name` check (`lib:554`) is never reached. "The others do not" is shown for --check-path only.

`if [[ "$CHECK" == --check-brief || "$CHECK" == --check-branch || "$CHECK" == --check-answer ]] && ! main_by_name; then` (`scripts/dev-cycle.sh:193`). Mutant `ansgate` drops the --check-answer term and fails at `:818` (`[ "$status" -eq 1 ]`) (`$L/mut-ansgate.txt`, exit 1).

**Evidence:** `scripts/dev-cycle.sh:189-195`, `$L/mut-ansgate.txt`

---

## Claim 27: test title "main_entry answers error for a path pathform refuses (U1d)"

**Location:** `test/scripts/dev-cycle.bats:1330-1337`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers four refused forms with main found by name. Three of them (`a"b.md`, `-x`, `docs//x.md`) carry the guard, and `../x` reads error without it.

`$L/mut-meguard.txt` (exit 1): without the pathform term, the output is `absent / error / absent / absent`, against four `error` lines.

**Evidence:** `test/scripts/dev-cycle.bats:1330-1337`, `$L/mut-meguard.txt`

---

## Claim 28: 83cdb005 Code and Wording bullets (main_entry's guard; "(git grep failed)" dropped; --check-answer in the title and loop; "until it lands there"; the help range; main_entry's comment; the pipefail note; "with no exact never line beside it"; NEXT outside a fence or end of file; the marker skip on a branch ahead of main; "could not be listed" in the help; the help re-wrapped; "an exit above 1 fails closed")

**Location:** commit 83cdb005 message
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each bullet against `git show 83cdb005 -- scripts test`. Later commits rewrote several of these texts. The current texts are Claims 1-11.

`git show 83cdb005` has: the help's `also needs a valid never line, so a never list hidden in markup, with no exact never line beside it, turns it off`; the skip list's `or the open briefs on main could not be listed, or on a branch ahead of main the tip's subject`; the F31 comment's `an exit above 1 fails closed`; and the re-wrapped `DISPATCHED:` line. The others match Claims 4, 5, 7-11 and 26.

**Evidence:** `scripts/build-loop.sh:14-21`, `scripts/build-loop.sh:67-75`, `scripts/build-loop.sh:310-314` (as of 83cdb005)

---

## Claim 29: 83cdb005: "Tests (U1b C10-C12, U1c C17, C18, C26, C28, C39, and U1a C16)"

**Location:** commit 83cdb005 message
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the U1c C17 and C18 attributions only (U1c rubric rows: C17 = marker_kind's commit-NUL refusal untested, C18 = F31's open-only filter untested). History only: iteration 1 already filed this (rubric A1, A11), and 6c83af2a closed both. It is not a new finding.

At 83cdb005, the NUL step tested FENCE_AWK's brief NUL, not `marker_kind`'s, and brief d had no later `Status: open` line, so git grep never listed it and F31's filter was never reached. Paraphrased — no quote available because this rests on the iteration-1 rubric rows `A1` and `A11` (`docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u1d.md:58`, `:68`), which executed those mutants against 83cdb005. Here, only the 6c83af2a side was re-run (Claim 31).

**Evidence:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u1d.md:58`, `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u1d.md:68`, `docs/reviews/code-review-rubric-2026-10-05-feat-build-loop-u1c.md` (C17/C18 as of 68343d3f)

---

## Claim 30: 83cdb005: "Mutants that drop the local BRIEF (moving the call), or un-anchor the closed/ prefix, fail the new --status test." / "Notes: 118 changed code lines."

**Location:** commit 83cdb005 message
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both mutants on 83cdb005's own tree and the pr-prep 1a count against main's merge-base at that commit (9f78df7e). The local-only mutant is Claim 24's residue.

In `$S/old83` (`git archive 83cdb005`): the unmutated copy passes (`$L/m83-base.txt`, exit 0). `unanchor` fails at `:453` (`$L/m83-unanchor.txt`, exit 1), and `briefmove` (drop the local, move the call after brief_fields) fails at `:457` with `feat/q ... 3` (`$L/m83-briefmove.txt`, exit 1). `git diff --numstat main...83cdb005 -- ':(top)' ':(top,exclude)docs/' | awk '{ n += $1 + $2 } END { print n+0 }'` prints `118` (worktree cwd, 2026-10-06).

**Evidence:** `$L/m83-base.txt`, `$L/m83-unanchor.txt`, `$L/m83-briefmove.txt`, `workflows/pr-prep.md:86-92`

---

## Claim 31: 6c83af2a: "A11/G1: T7 commits a marker whose body holds a NUL ...; deleting marker_kind's NUL check now fails T7 (row 291 C17 closed)." / "A1/G2: ... dropping that filter now fails the U1d test (row 291 C18 closed)." / Notes: "Mutants checked by hand on the patched suite"

**Location:** commit 6c83af2a message
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both mutants on 6c83af2a's own tree and at HEAD, and row 291's subject. It does not cover the `&&`-chain vacuity at 6c83af2a, which 07c354c5 fixed (Claim 33).

Row 291 reads "The NUL refusal and F31's open-only filter are untested in build-loop-read.bats (... iteration 2 C17, C18)" (`docs/reviews/override-log.md:291`). In `$S/old6c`, `m6c-nul` fails T7 at `:296` and `m6c-f31` fails the U1d test at `:456` (`$L/m6c-nul.txt`, `$L/m6c-f31.txt`, exit 1). At HEAD: Claims 17 and 22.

**Evidence:** `docs/reviews/override-log.md:291`, `$L/m6c-nul.txt`, `$L/m6c-f31.txt`, `$L/mut-nulcheck.txt`, `$L/mut-f31status.txt`

---

## Claim 32: 6c83af2a: A6, A7/A10, A3-A5, C1, C7, C8, C9, and Notes "151 changed code lines (cap 400). Tests: build-loop-read 19, dev-cycle 73, hermeticity lint green; shellcheck clean."

**Location:** commit 6c83af2a message
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count with pr-prep 1a's command (a cumulative branch total, not 6c83af2a's own 87 lines), `bats --count` at that commit, and shellcheck with health-check's flags at HEAD, where scripts/ and test/ equal 07c354c5's. Shellcheck at 6c83af2a itself was not run.

`git diff --numstat main...6c83af2a -- ':(top)' ':(top,exclude)docs/' | awk ...` prints `151`. `bats --count` on the 6c83af2a files gives build-loop-read 19, dev-cycle 73, hermeticity 2 (`$S/cnt-6c83af2a`). `shellcheck -x -e SC1091 -s bash -S warning` (`scripts/health-check.sh:480`) exits 0 on all six changed files (`$L/shellcheck-project.txt`, cwd `$S/base`). The wording items match Claims 1, 3, 4, 6, 10, 11 and 19, and the C9 cases are Claims 2, 15 and 16.

**Evidence:** `scripts/health-check.sh:480`, `$L/shellcheck-project.txt`, `$L/baseline.txt`

---

## Claim 33: 07c354c5 C13: "T7's NUL-marker step is no longer one && chain, so a fixture that fails to build fails the test instead of skipping its check (... checked: with --literally broken and the NUL check deleted, T7 now fails). The two other new && chains are split too."

**Location:** commit 07c354c5 message
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers T7's step (executed) and the two chains 6c83af2a added with a run or commit tail: stopped:x (`:257-258`) and d-later-open (`:458-459`). It does not cover same-shape chains the branch added earlier, which still pass vacuously.

The T7 part is exact (Claim 17, `$L/mut-t7both.txt`). `git diff 6c83af2a 07c354c5` shows exactly the stopped:x and d-later-open chains split. But the branch's U1d --status test still builds two fixtures in 83cdb005 `&&` chains whose failure skips the case: `brief p ... && printf ...\r\n... > "$B" && commit_all crlf` (`:464`) and `mkdir -p ... && printf ... > .../1-x.md && commit_all odd-dir` (`:469`). With either fixture write failing and its guard removed, the test passes (`$L/mut-crlfvac.txt`, `$L/mut-oddvac.txt`, exit 0). Precise version: "the two other && chains 6c83af2a added are split. The CRLF and odd-dir fixtures from 83cdb005 keep the shape." The trigger, a failing printf into a just-made directory, is unlikely, so this is Low.

**Evidence:** `test/scripts/build-loop-read.bats:257-258`, `test/scripts/build-loop-read.bats:458-459`, `test/scripts/build-loop-read.bats:464`, `test/scripts/build-loop-read.bats:469`, `$L/mut-t7both.txt`, `$L/mut-crlfvac.txt`, `$L/mut-oddvac.txt`

---

## Claim 34: 07c354c5: A12, A13, C14 ("the comment at build-loop-read.bats:118 says a checked task box is skipped"), C15, C16, C17, and Notes "build-loop-read 19, dev-cycle 73, hermeticity lint green; shellcheck clean."

**Location:** commit 07c354c5 message
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each item against 07c354c5's diff and HEAD (identical in scripts/ and test/). The counts were run at 07c354c5, and the lint and shellcheck at HEAD.

The comment is at `:118` (Claim 14). The help comment is on its own line (`scripts/build-loop.sh:102`). dev-cycle.bats' help test loops `-h --help` (`:1323`). The MAIN comment names main_entry and brief_fields (`lib:244-247`). The help says "valid", like `:255`'s reason (Claim 1). A13 is Claim 21. `bats --count` at 07c354c5 gives 19/73/2 (`$S/cnt-07c354c5`). The baseline run passes 94/94, including both hermeticity tests (`$L/baseline.txt`), and shellcheck is clean (`$L/shellcheck-project.txt`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:244-247`, `test/scripts/dev-cycle.bats:1322-1328`, `$L/baseline.txt`, `$L/shellcheck-project.txt`

---

## Claims Requiring Attention

### Incorrect
- **Claim 29** (commit 83cdb005): the Tests header credits U1c C17 and C18, but neither was tested at that commit. Already filed (iteration 1 A1, A11), fixed in 6c83af2a; history only, immutable.

### Stale
- None.

### Mostly Accurate
- **Claim 17** (`test/scripts/build-loop-read.bats:297`): "(one commit ahead, same tree)" holds relative to `base`, but the branch is two ahead of main. Precise: "one commit on top of base, with its tree".
- **Claim 33** (commit 07c354c5): "The two other new && chains are split too" is true of 6c83af2a's chains. The CRLF (`:464`) and odd-dir (`:469`) fixtures from 83cdb005 keep the shape and pass vacuously if their write fails (executed). Low.

### Unverifiable
- None.

---

## Goal-Alignment Note

The goal is to land U1d after this final confirming pass. That means every claim in the branch's comments, help, test titles and commit messages must be exact, every test must fail on the regression it names, and nothing new may be introduced. On the code side the unit meets that bar. Every changed help or comment claim in scripts/ was executed or traced and holds. That includes the never-line rule across all five markup forms in both orders, the skip list, both F31 failure modes and the help ranges.

main_entry's guard changes no existing caller's output. Its four callers either pre-check pathform or pass literal paths that pathform accepts. The only other behaviour change is the dropped "(git grep failed)". Every named test case failed on its targeted mutant, 29 mutant runs in all, and the two known survivors are deferred rows (312 local BRIEF, 313 ignored arm).

What remains is small. One historical commit-message attribution is already filed and immutable. One parenthetical in a test comment is imprecise. Two `&&`-chained fixtures in the U1d --status test are the same Low class that 07c354c5 fixed in T7. A fixture write failure there would let the CRLF and closed-dir steps pass without checking. None blocks the merge. The last item is a two-line split if the author wants the class closed in this unit rather than in U2.
