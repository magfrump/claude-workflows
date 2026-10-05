**Commit:** 1d79ffef

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u1b (unit `feat/build-loop-u1a...feat/build-loop-u1b`)
**Scope:** Submitted claims only (security-reviewer x2) about `scripts/build-loop.sh` at 1d79ffef, review iteration 3; no fresh harvesting (Stage 1 covered the diff)
**Checked:** 2026-10-05
**Total claims checked:** 2 (Claims 46-47, continuing the merged report's numbering)
**Summary:** 2 verified, 0 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Line numbers below are those of `scripts/build-loop.sh` at 1d79ffef (186 lines). The submitted locations are in file numbering already: `:143` is `many()`, `:177` is the last slots branch, `:100` is SETTINGS_AWK's next-line test, `:152` is the "followed by a non-blank line" branch and `:170-171` is the self-merge-off branch of the policy line.

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`): no verdict here is Incorrect, so the log is not updated.

Executed-probe provenance (shared by both claims):
- Commands: `timeout 120 bash probe.sh > probe-out.txt 2>&1` (exit 2, from the script's last line `ls /tmp/pwn`, which found no such file: the `$(...)` payloads ran nothing) and `timeout 120 bash probe2.sh > probe2-out.txt 2>&1` (exit 0); a mutation run in `mut/` (below); and `bats test/scripts/build-loop-read.bats` in the worktree (9/9 ok).
- Working directory: `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b-i3/submitted/`. Each probe builds a throwaway repo (`repo/`, `repo2/`) there under a hermetic git environment (`GIT_CONFIG_GLOBAL=/dev/null`, `GIT_CONFIG_NOSYSTEM=1`, `HOME` in the scratch dir, `LC_ALL=C`), commits `docs/dev-cycle.md` on `main`, and runs the worktree's `scripts/build-loop.sh --settings` with `DEV_CYCLE_SCRUBBED=1`, so the captured output is what read_settings built, before the scrub. Output is shown through `cat -A` in probe-out.txt, so any control byte would show as `^[`, `^I` and the like.
- Every `--settings` run in both probes exited 0 and wrote nothing to stderr.

---

## Submitted Claims

## Claim 46: "The policy and slots lines print no repo text besides line numbers, and the never line prints its value only after every entry passes globform."

**Submitted by:** security-reviewer
**Legibility-target:** security-reviewer (the trust-boundary row for `--settings` output: which repo-controlled bytes can reach stdout)
**Location:** `scripts/build-loop.sh:143-177`; `test/scripts/build-loop-read.bats:117-118` (T45 no-echo assertion)
**Type:** Invariant / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every assignment to POLICY_LINE, SLOTS_LINE and NEVER_LINE in read_settings (`:127-179`), `many()`, main_file's FILE_WHY strings (`:71-88`) and the lib's `oddwhy`, on the raw pre-scrub output, for the hostile payloads listed below; also confirms by mutation that the T45 assertion at `:117-118` fails when a malformed never entry is echoed. Does not establish anything about how later modes (U1c/U2) consume POLICY/NEVER, does not cover stderr from a git or awk failure, and does not claim the printed globs are safe for a consumer that expands them with a shell (the set line holds literal `*` and `?`). "Line numbers" is read loosely: the policy set line also prints the regex capture `self-merge`/`review` and the slots set line the captured digit 1-9; both are fixed alternatives, not free repo text.

Policy and slots lines. Every value that is not a fixed string is a line number from awk's `NR` or a capture of a fixed alternative:

```bash
# scripts/build-loop.sh:166-177
    if [[ -z "${cnt[policy]-}" ]]; then POLICY_LINE='policy review unset: no line starts "Build-loop policy:"'
    elif [[ "${cnt[policy]}" -gt 1 ]]; then POLICY_LINE="policy review unset: $(many 'Build-loop policy:' policy)"
    elif [[ "${text[policy]}" =~ ^Build-loop\ policy:\ (self-merge|review)$ ]]; then
      v="${BASH_REMATCH[1]}"
      if [[ "$v" == self-merge && -z "$never_ok" ]]; then
        POLICY_LINE="policy review unset: line ${first[policy]} reads self-merge, but the Self-merge never: line is malformed, so self-merge is off"
      else POLICY="$v"; POLICY_LINE="policy $v set: line ${first[policy]} $where"; fi
    else POLICY_LINE="policy review unset: line ${first[policy]} is not exactly \"Build-loop policy: self-merge\" or \"Build-loop policy: review\""; fi
    if [[ -z "${cnt[slots]-}" ]]; then SLOTS_LINE='slots 3 default: no line starts "Build-loop slots:"'
    elif [[ "${cnt[slots]}" -gt 1 ]]; then SLOTS_LINE="slots 3 default: $(many 'Build-loop slots:' slots)"
    elif [[ "${text[slots]}" =~ ^Build-loop\ slots:\ ([123456789])$ ]]; then SLOTS_LINE="slots ${BASH_REMATCH[1]} set: line ${first[slots]} $where"
    else SLOTS_LINE="slots 3 default: line ${first[slots]} is not exactly \"Build-loop slots: N\" with N from 1 to 9"; fi
```
(excerpt ends :177; enclosing read_settings() continues to :179 (closing `fi` and `}`) — read; the values flow to the `printf` at `:184`, their first and only use)

`first[...]`/`second[...]` are awk's `NR` (`l1[k] = NR`, `l2[k] = NR`, `:105`), parsed from the part of each record before its first tab (`read -r k c l1 l2 nx <<<"${l%%$'\t'*}"`, `:140`); that prefix is built entirely by the END block (`print k " " c[k] " " l1[k] ...`), so it holds no repo bytes. `many()` prints only those numbers and its fixed key argument (`:143`). `$where` is built from the constant `f=docs/dev-cycle.md` (`:128`, `:131`). When the file is not read, FILE_WHY holds only fixed prose, the constant path, a line number and `oddwhy`'s fixed reason (main_file `:84-87`, lib `oddwhy`); SETTINGS_AWK's END prints `odd`/`unbalanced` records only from `odd`, `oddwhy` (fixed `refuse()` arguments) and `fline`.

Never line. `$v` reaches NEVER_LINE only on the set branch:

```bash
# scripts/build-loop.sh:150-164
      if [[ "$t" != "Self-merge never: "* || ! "$v" =~ ^[^\ ]+(\ [^\ ]+)*$ ]]; then
        why='is not exactly "Self-merge never: GLOB ..." with single spaces'
      elif [[ "${next[never]}" != 1 ]]; then why="is followed by a non-blank line (Markdown would join it as more globs)"
      else
        i=0
        IFS=' ' read -ra parts <<<"$v"  # not a bare $v: the shell would expand * and ? against files
        for g in "${parts[@]}"; do
          i=$((i + 1))
          if ! globform "${g%/}"; then why="lists entry $i, which is not an allowed glob form"; break; fi
          if [[ -n "${seen[${g%/}]-}" ]]; then why="lists entry $i twice"; break; fi
          seen[${g%/}]=1
        done
      fi
      if [[ -n "$why" ]]; then NEVER_LINE="never malformed: line ${first[never]} $why"; never_ok=""
      else NEVER=("${parts[@]}"); NEVER_LINE="never $v set: line ${first[never]} $where"; fi
```
(excerpt starts inside the never `else` arm opened at `:147`; enclosing read_settings() runs `:127-179` — read)

The `=~` test makes `$v` exactly the single-space join of non-space runs, and `read -ra` with `IFS=' '` splits on exactly those spaces, so `parts` covers every byte of `$v` but the separators. Each `${g%/}` must pass globform (`:114-121`, NAMECHARS plus `*` `?`, not starting `/` or `-`, no empty, `.` or `..` part), so the printed value is NAMECHARS, `*`, `?`, `/` and single spaces. The malformed branch prints only `line N` and fixed `why` text with the entry index `i`.

Executed (probe-out.txt, 21 cases). Payloads: ESC/OSC sequences (`\e[31m`, `\e]0;title\a`, `\e[2J`) in the policy, slots and never values; `$(touch /tmp/pwn)` and backticks in policy and never; non-ASCII (Arabic-Indic digit for slots, `caf\xc3\xa9`, U+202E in never); a 6000-byte policy line and never line (valid, and with a trailing ESC); duplicate keys whose second copy holds ESC (`**build loop policy** \e x`); three hostile slots copies; near-miss keys (`Build loop policy: self-merge`, `BUILD_LOOP_SLOTS=5`, `Self merge never - x/`, `Buildlooppolicy:self-merge`); `a[b] c\d` and a tab separator in never; files refused by FENCE_AWK (a `<div>\e[31m` line, a mid-line CR followed by ESC, an indented fence with ESC). Results: every policy/slots line was a fixed reason with line numbers only (e.g. `policy review unset: line 1 is not exactly ...`, `slots 3 default: more than one line starts "Build-loop slots:" (lines 1 and 2)`); every hostile never value gave `never malformed: line 2 lists entry 1, which is not an allowed glob form` or the single-spaces reason; refused files printed only `line 2 of docs/dev-cycle.md <oddwhy reason>, so the file is not read` on all three lines. `cat -A` showed no `^[` or other control byte in any output, and `/tmp/pwn` was not created. Accepted values printed verbatim and only NAMECHARS/`*`/`?`: `never * ? */*.sh set: ...`, `never .github/ x/* set: ...`, and the 6000-`a` entry whole (pre-scrub; the scrub's 4096-byte cut of such a line is settled as C2).

Mutation (`submitted/mut/`, copies only): changing `:163` to `NEVER_LINE="never malformed: line ${first[never]} $why [$v]"` makes T45 fail at `test/scripts/build-loop-read.bats:118` with `echoed a malformed entry: ... never malformed: line 2 lists entry 1, which is not an allowed glob form [../x]`, so the cited no-echo assertion is live for the never line. (Echoing on the policy/slots lines would be caught by the exact-string `settings_is` checks of T2 and the slots test instead.)

**Evidence:** `scripts/build-loop.sh:71-88`, `scripts/build-loop.sh:96-111`, `scripts/build-loop.sh:114-121`, `scripts/build-loop.sh:127-179`, `scripts/build-loop.sh:181-186`, `scripts/lib/dev-cycle-read.sh:139`, `scripts/lib/dev-cycle-read.sh:231-241`, `test/scripts/build-loop-read.bats:117-118`, `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b-i3/submitted/probe.sh`, `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b-i3/submitted/probe-out.txt`, `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b-i3/submitted/mut/`

---

## Claim 47: "A never line followed by a non-blank, non-fence line is malformed and turns self-merge off."

**Submitted by:** security-reviewer
**Legibility-target:** security-reviewer (A5 closure: a never line Markdown would continue on the next line must not be read short)
**Location:** `scripts/build-loop.sh:100`, `:152`, `:170-171`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the line after the first never copy outside a fence: text, an indented line, a list item, a heading, a one-line HTML comment, another key line, a form feed (all malformed), and a blank, whitespace-only, CRLF-blank line or EOF (all set); fence lines after the never line; and the self-merge-off consequence on the policy line. Does not establish a matching rule for the policy or slots lines (there is none; see below), and does not judge whether the rule matches CommonMark beyond failing closed.

```awk
# scripts/build-loop.sh:97-106 (SETTINGS_AWK)
{ sub(/\r$/, "") }
fence($0) { next }
{
  if (pk != "") { nx[pk] = ($0 ~ /^[ \t]*$/); pk = "" }
  s = tolower($0); gsub(/[^a-z]/, "", s); k = ""
  if (index(s, "buildlooppolicy") == 1) k = "policy"
  else if (index(s, "buildloopslots") == 1) k = "slots"
  else if (index(s, "selfmergenever") == 1) k = "never"
  if (k != "") { c[k]++; if (c[k] == 1) { l1[k] = NR; t[k] = $0; nx[k] = 1; pk = k } else if (c[k] == 2) l2[k] = NR }
}
```
(excerpt ends :106; the SETTINGS_AWK string continues to :111 (END block, which prints `nx[k]` as the NEXT field) — read)

`nx[never]` starts at 1 (blank-or-EOF) and is overwritten by the next record that is not consumed by `fence($0) { next }`; `next[never] != 1` gives the malformed reason at `:152`, `never_ok=""` at `:163`, and `:170-171` turns a `self-merge` policy into `policy review unset ... so self-merge is off`. Lines that `fence()` refuses (open comment, raw HTML, refdef, CR, NUL) make the whole file unread, which is `never malformed` by the not-read path (`:136`).

Executed (probe2-out.txt). Malformed with `policy review unset: line 1 reads self-merge, but the Self-merge never: line is malformed, so self-merge is off`: next line `b/`, `    b/`, `- b/`, `# H`, `<!-- note -->`, `\f`, `Build-loop slots: 4`, and the policy line itself (`Self-merge never: a/` then `Build-loop policy: self-merge` gives `never malformed: line 1 is followed by a non-blank line ...` and `policy review unset: line 2 reads self-merge ...`). Set (`never a/ set`, `policy self-merge set`): next line empty, spaces-and-tab only, `\r` alone, or EOF. Fence cases: a fenced block right after the never line is skipped, so the next unfenced line decides: block then blank or EOF is set; block then `b/` is malformed (backtick and tilde fences alike). An open comment after the never line refuses the file (`line 3 ... opens an HTML comment ...`, all three lines; policy review unset). With `Build-loop policy: review`, a continued never line is still `never malformed` and policy stays `review set`, so "turns self-merge off" is vacuous there, as expected.

Observation for the critic (not a verdict input; the claim asserts nothing about it): the next-line rule is applied only to the never line. `Build-loop policy: self-merge` followed by `except on Fridays` prints `policy self-merge set: line 1 ...`, and `Build-loop slots: 4` followed by `more` prints `slots 4 set`, though Markdown would render each as one longer paragraph. `nx[k]` is computed for every key (`:100`, `:105`) but read only for `never` (`:152`). Whether that asymmetry matters is the critic's call; the header (`:13-17`) documents "exactly" for policy and slots, which holds line by line.

**Evidence:** `scripts/build-loop.sh:96-111`, `scripts/build-loop.sh:136`, `scripts/build-loop.sh:147-164`, `scripts/build-loop.sh:168-173`, `scripts/lib/dev-cycle-read.sh:186-229` (FENCE_AWK `fence()`), `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b-i3/submitted/probe2.sh`, `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b-i3/submitted/probe2-out.txt`

---

## Claims Requiring Attention

None: both submitted claims are Verified. One observation is attached to Claim 47 for the critic: the policy and slots lines have no next-line rule, so a continued `Build-loop policy: self-merge` paragraph still reads `self-merge set`.

## Goal-Alignment Note

The user's goal is a final confirming review of U1b before local merge. Both security-reviewer endorsements hold on executed hostile inputs: `--settings` prints no free repo text on the policy and slots lines and prints never entries only after globform (46, with the T45 no-echo assertion shown live by mutation), and a never line continued by a non-blank line fails closed (47). Neither verdict blocks the merge. The one item for the orchestrator to weigh is Claim 47's observation, that policy and slots lines are not checked for a continuation line; it is outside the submitted claims and settled-decision list as far as this pass can tell, so the rubric should judge its severity.
