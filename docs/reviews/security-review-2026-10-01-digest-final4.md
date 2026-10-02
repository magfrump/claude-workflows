Commit: db0e5ca

# Security Review: feat/dev-cycle-digest (final pass 4)

**Scope:** `git diff main...HEAD -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` (both new on the branch, 241 + 263 lines)
**Date:** 2026-10-01
**Based on:** Stage-1 merged fact-check summary (`digest-final4-stage1-dc1aa358.md`; replicates `docs/reviews/code-fact-check-report-r{1,2,3}-digest-final4.md`)

Probes ran in throwaway repos under `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/sec-final4/`, each under `timeout`. Nothing was written to the worktree except this file. `bats test/scripts/dev-cycle.bats`: 18/18 ok at db0e5ca.

## Trust Boundary Map

```
B1: [repo file contents: decision records, log.md, roadmap, idea log]   → [awk/grep extraction, "> " / "- " prefixes, scrub()] → [digest stdout → terminal and dev-cycle agent (LLM)]
B2: [repo-derived names and git metadata: file names, merge subjects]    → [${f//\n/ }, tr '\0\n' '\n ', %s, scrub()]       → [digest stdout → terminal and agent]
B3: [repo working-tree paths (committed symlinks)]                       → [[[ -f ]] then grep/awk/redirect open]               → [host filesystem read outside the repo]
B4: [process environment: PERL_UNICODE, PERL5OPT, LC_ALL, DEV_CYCLE_TODAY, HOME] → [perl/date/git invocation]               → [behavior of scrub() and of the date window]
B5: [git refs: origin/HEAD, branch names] (unchanged since pass 3)       → [refs/heads/ hash resolution, leading "-" rejected] → [git log/diff argv]
B6: [questions.sh (SCRIPT_DIR, else $HOME/.claude/scripts)]             → [bash "$QS" open, stderr to mktemp file]             → [digest section 3]
```

Input-source classification:

```
S1: repo file contents (docs/decisions/*.md, log.md, roadmap.md, idea-log.md, questions.md)
      runtime-mutable (any merged branch, including agent-authored or third-party ones)
      UNTRUSTED toward terminal/LLM output sinks; trusted for availability (counting)
S2: repo file names and commit subjects
      runtime-mutable. UNTRUSTED toward output sinks and git argv
S3: committed symlinks in the working tree
      runtime-mutable. UNTRUSTED toward file-open sinks (they choose which host file is read)
S4: environment variables (PERL_UNICODE, PERL5OPT, DEV_CYCLE_TODAY, HOME)
      deploy-time (the invoking user's shell). Trusted as an attacker channel, but they set scrub()'s
      operating conditions, so they count as a correctness precondition for the S1/S2 sinks
S5: git refs (origin/HEAD from a remote)
      runtime-mutable. UNTRUSTED toward git argv (guarded, cleared in pass 3)
S6: SCRIPT_DIR/questions.sh, $HOME/.claude/scripts/questions.sh
      deploy-time. Trusted for exec
```

Repo-derived text (S1, S2) leaves the script at one sink: stdout/stderr, which the user's terminal and the dev-cycle agent both read. That agent may copy what it reads into a committed cycle record. The diff treats `scrub()` as the only guard on that sink ("The one scrub for everything printed"). It also assumes that every repo path the script opens resolves inside the repo, but nothing checks this.

## Findings

#### 1. scrub() is a single pass that runs `s///` before `tr`, so nested or C0-split sequences put C1, bidi and tag characters back together

**Severity:** Medium
**Location:** `scripts/dev-cycle.sh:24-31`
**Boundary:** B1, B2
**Move:** #11 (enumerate bypasses), #2 (implicit sanitization)
**Confidence:** High (executed)
**Legibility-target:** maintainer of `scrub()` / reader of the header's "Printed repo text is data"

**Evidence (verbatim):**
```
# The one scrub for everything printed, stdout and stderr: drops C0 controls but
# TAB and LF, DEL, C1 controls (U+0080-009F), bidi controls (U+200E/F,
# U+202A-202E, U+2066-2069) and tag characters (U+E0000-E007F). Byte patterns
# under LC_ALL=C, so invalid UTF-8 in a file name cannot make perl warn or die.
scrub() {
  LC_ALL=C perl -pe 's/\xC2[\x80-\x9F]|\xE2\x80[\x8E\x8F\xAA-\xAE]|\xE2\x81[\xA6-\xA9]|\xF3\xA0[\x80\x81][\x80-\xBF]//g; tr/\000-\010\013-\037\177//d'
}
exec > >(scrub) 2> >(scrub >&2)
```

Two bypass shapes, both executed:
- **Nesting (new; not in Stage 1):** `s///g` makes one left-to-right pass and never rescans its own output. The input `\xC2 \xC2\x9B \x9B` loses its middle pair, which leaves `\xC2\x9B` (U+009B CSI). The same works for RLO (`\xE2\x80 \xE2\x80\xAE \xAE`) and tag characters (`\xF3\xA0 \xF3\xA0\x81\x81 \x81\x81`).
- **C0 split (Stage 1 r1):** `\xC2\x01\x9B` survives `s///`, then `tr` deletes `\x01`, which produces `\xC2\x9B`.

End to end: I committed a decision record whose `## Revisit triggers` line held all of these. Section 2 printed `\xC2\x9B` (CSI), `\xE2\x80\xAE` (RLO) and `\xF3\xA0\x81\x81` (TAG LATIN CAPITAL A) on stdout (`cat -v`: `M-BM-^[`, `M-bM-^@M-.`, `M-sM- M-^AM-^A`). Both shapes need invalid UTF-8 input, and repo file contents and file names can carry that freely. Commit subjects did not, because git re-encoded the invalid message.

**Impact:** a committed record can put invisible tag-character text (the "ASCII smuggling" channel for hidden LLM instructions) or RLO-reordered text in front of the dev-cycle agent. On terminals that act on UTF-8-encoded C1 controls, it can also deliver a CSI sequence. This is the A2 property the commit claims to close. The bats test (`:93`) covers only single, well-formed sequences, so it passes. 7-bit ESC is always removed, so ordinary `ESC[` sequences cannot get through.

**Recommendation:** Delete C0 first (`tr` before `s///`). Then repeat the substitution until nothing changes (`1 while s/…//g`), or match in decoded form on a stream that has a fixed decoding (see Finding 2). Add nested and C0-split cases to test 5.

#### 2. Setting PERL_UNICODE or PERL5OPT in the user's environment turns scrub() off for C1 and bidi characters

**Severity:** Medium
**Location:** `scripts/dev-cycle.sh:29`
**Boundary:** B4 (precondition) feeding B1/B2
**Move:** #11, #1 (per-consequence trust)
**Confidence:** Medium (the mechanism is executed; how many users set these variables is unknown)
**Legibility-target:** maintainer of `scrub()`

**Evidence (verbatim):**
```
  LC_ALL=C perl -pe 's/\xC2[\x80-\x9F]|...//g; tr/\000-\010\013-\037\177//d'
```

`LC_ALL=C` does not control perl's I/O layers. With `PERL_UNICODE=SDA` or `PERL5OPT=-CSD`, perl decodes STDIN as UTF-8. The byte-level patterns then never match, because U+009B becomes one character, not `\xC2\x9B`, and the text is re-encoded on output. I committed a record line `plain C1 \xC2\x9B and RLO \xE2\x80\xAE end`. Without either variable it printed scrubbed. With `PERL_UNICODE=SDA` or `PERL5OPT=-CSD` it printed `302 233` and `342 200 256` intact. The attacker does not set the environment. The user's own shell profile is a reachable environment, and in it a repo-controlled payload goes through unscrubbed with no warning. This confirms the r2/r3 escalation from Stage 1. The comment's "so invalid UTF-8 … cannot make perl warn or die" names the wrong mechanism.

**Recommendation:** Pin perl's layers explicitly: `env -u PERL5OPT -u PERL_UNICODE LC_ALL=C perl -C0 -pe …`, or call `binmode STDIN/STDOUT, ':raw'` in a `BEGIN` block. Then add a test case that sets `PERL_UNICODE=SDA`.

#### 3. A committed symlink makes the digest read and print a file from outside the repo

**Severity:** Medium
**Location:** `scripts/dev-cycle.sh:111-119`, `:171-175`, `:227-232`
**Boundary:** B3 → B1
**Move:** #1, #4 (the check `-f` follows the link; the read happens at the link's target)
**Confidence:** Medium on the mechanism (executed). Low on impact: section 2 prints only text under a `## Revisit triggers` heading, section 5 only under `## Next`, and the idea log leaks only a date and a count.
**Legibility-target:** maintainer; the threat model in the header ("Acts on $PWD's git repo")

**Evidence (verbatim):**
```
for f in docs/decisions/[0-9][0-9][0-9]-*.md; do
  [[ -f "$f" ]] || continue
  grep -q '^## Revisit triggers' "$f" || continue
  ...
  trig < "$f" | sed 's/^/> /'
done
```
```
if [[ -f docs/roadmap.md ]]; then
  ...
  awk '/^## Next/ { on = 1; next } on && /^## / { exit } on && NF { print "> " $0 }' docs/roadmap.md
```

Probe: I committed `docs/decisions/002-link.md -> ../../../secret/notes.md`, with the target outside the repo. The digest printed `### docs/decisions/002-link.md …` followed by `> PRIVATE-LINE-FROM-OUTSIDE-REPO` from the outside file. Section 7 also listed the link as a changed decision record. `[[ -f ]]` rejects devices and FIFOs, so `/dev/zero`-style hangs are blocked. A regular file anywhere the user can read is accepted. The dev-cycle agent can then copy the text into a committed and possibly pushed cycle record. That turns a local read into disclosure. The precondition is narrow: the target file must contain the matching heading.

**Recommendation:** Skip a path that is a symlink (`[[ -L "$f" ]] && continue`, or print a note), or require `realpath` to stay under `$ROOT`. Do this for the decision records, `log.md`, `roadmap.md` and `idea-log.md`. `questions.sh` already guards its write targets (`assert_write_targets`). Reads in this script have no matching guard.

#### 4. Format characters not covered by the scrub (U+2028, U+200B, U+2060, U+FEFF) pass through

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:24-29`
**Boundary:** B1, B2
**Move:** #11
**Confidence:** High (executed)
**Legibility-target:** maintainer of `scrub()`

**Evidence:** the input `a\xE2\x80\xA8b\xE2\x80\x8Bc\xE2\x81\xA0d\xEF\xBB\xBFe` came out of `scrub()` with every byte intact. The comment does not claim to cover these characters, so this is not a contradiction. They are invisible to a human reader but still visible to the agent, which is the same concern as Finding 1 at lower strength. None of them makes a new line in a terminal or in markdown, so none can forge a digest line.

**Recommendation:** If the property you want is "no invisible text reaches the reader", add the zero-width and format characters (U+200B-200D, U+2060-2064, U+FEFF, U+2028/9) to the same pattern. If not, write down in the comment that they are intentionally out of scope.

#### 5. The script does not wait for the scrub filters, so the reader can get a truncated digest with no error

**Severity:** Informational (integrity/availability, not exploitable by repo content)
**Location:** `scripts/dev-cycle.sh:31`
**Boundary:** Internal — no boundary. This is a lifecycle property of the guard, not something input crosses.
**Move:** #3 (error path)
**Confidence:** Medium (Stage 1 executed it: 1 in 20 runs short on 300k lines)
**Legibility-target:** header exit-code contract (`:18-19`)

**Evidence (verbatim):** `exec > >(scrub) 2> >(scrub >&2)`. Nothing waits on the process-substitution PIDs before exit. Stage 1 also reports that with `2>&1` an error can print before the header (pass-3 C6 is still open). No security property depends on this. It is listed so that the "exit 0 = digest printed" contract is not taken as a guarantee that the output arrived complete.

**Recommendation:** At the end of the script, close stdout/stderr and `wait` for the substitution PIDs (`exec >&- 2>&-; wait "$scrub_pid"`), or run the script body in a function piped through `scrub`.

## Untested bypass candidates

- Terminals that act on UTF-8-encoded C1 controls. Which terminals turn the reassembled `\xC2\x9B` into a live CSI was not tested (no terminal emulator in the sandbox). Finding 1 does not depend on this, because the tag/RLO-to-agent path is enough.
- Raw 8-bit C1 bytes (`\x9B` with no lead byte). They pass `scrub()` (executed: `61 9b 62`). Whether a non-UTF-8 terminal locale treats them as CSI was not tested.
- Commit subjects carrying the nested payload while marked `encoding UTF-8` in the commit header, so git does not re-encode them. Not built. Decision-record contents are enough to show Finding 1.

## Endorsement Claims

- **Claim:** In the probed repos, no repo-derived text (record names, record contents, log rows, merge subjects, section 7 file names) produced a line that was not prefixed or fenced. CR, VT, FF and NEL were removed before output.
  **Location:** `scripts/dev-cycle.sh:105,118-119,130,190,204-214`
  **Evidence:** executed (only the record and merge-subject fixtures above). Stage 1 independently reports no new line-forging path.
  **Verified:** the section 2 heading replaces newlines; `sed 's/^/> /'` prefixes each trigger line; `%s` returns the subject on one line; `tr '\0\n' '\n '` handles section 7 names.
  **Not verified:** a section 3 `open` slug containing U+2028 or other separators rendered by the agent's markdown viewer.
  **route: code-fact-check**
- **Claim:** The section 3 error fence (`cat "$qs_err"` inside a code fence) does not print repo content. On the `open` path, questions.sh's stderr messages contain only file paths that come from env or code constants (`:135-137`, `die`).
  **Location:** `scripts/dev-cycle.sh:152-154`; `scripts/questions.sh:76,135-137,408-414`
  **Evidence:** read-static
  **Verified:** `require_files` and `die` message text; `cmd_open`'s pipeline has no stderr writes of its own.
  **Not verified:** awk/sort runtime errors inside `parse_entries` on a malformed `questions.md` (their messages could quote input).
- **Claim:** No repo-controlled value is executed. `bash "$QS"` resolves only to `SCRIPT_DIR` or `$HOME/.claude/scripts`. Git receives only hashes (`$full`, `$oldest^1`, `$MAIN_SHA`), `--` paths under `GIT_LITERAL_PATHSPECS=1`, and a `$SINCE` checked against a regex and `date`.
  **Location:** `scripts/dev-cycle.sh:52,55-72,88,116,136-140,186,199-204`
  **Evidence:** read-static
  **Verified:** the argv construction at each call site listed in the primitive sweep.
  **Not verified:** repo-local `.git/config` keys that git honors on `log`/`diff` (`log.showSignature` with `gpg.program`, `diff.external` is not used by `--name-only`). These sit on the host-control side of the floor rule and are out of scope.
  **route: code-fact-check**

## Primitive sweep

Primitive: file open on a repo path (symlink-following read)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/dev-cycle.sh:75-79` cycle-record glob | S2 | name only, never opened | cleared: file name parsed, contents unread |
| `:111-119` decision records (`grep -q`, `trig <`) | S1, S3 | `-f` (follows links) | Finding 3 |
| `:121-131` `docs/decisions/log.md` (`grep`) | S1, S3 | `-f` | Finding 3 (same mechanism; prints only rows matching `^\| [0-9]+ \|` and `revisit`) |
| `:138-140` `docs/working/questions.md` via questions.sh | S1, S3 | `-f`; questions.sh `require_files` | not analyzed for symlinks inside questions.sh's read path; prints only parsed entry columns |
| `:171-175` `docs/roadmap.md` (`awk`) | S1, S3 | `-f` | Finding 3 |
| `:219-222` `docs/roadmap.md` counts | S1, S3 | `-f` | cleared for content: prints counts only |
| `:227-238` `docs/working/idea-log.md` | S1, S3 | `-f` | Finding 3 (prints only a date and a count; low impact) |

Primitive: process exec

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `:29` perl `scrub` | S4 | none on PERL_UNICODE/PERL5OPT | Finding 2 |
| `:140` `bash "$QS" open` | S6 | path from SCRIPT_DIR/HOME only | cleared: deploy-time |
| `:57-72` git refs to hashes | S5 | `refs/heads/` + `^{commit}`, leading `-` rejected | cleared (pass 3; test 15) |
| `:99,102,199` `git log "$MAIN_SHA"` | S5 | hash only | cleared |
| `:116,172` `git log -1 -- "$f"` | S2 | `--`, `GIT_LITERAL_PATHSPECS=1`, path starts `docs/` | cleared |
| `:186,190` `git diff/log "$full^1" "$full"` | S2 (hash from `%H`) | hash only | cleared (correctness of a missing `^1` on a root merge is out of the security lane) |
| `:203-204` `git rev-parse "$oldest^1"`, `git diff … -- skills workflows docs/decisions` | S2 (hash) | hash + literal pathspecs | cleared |
| `:85,88,233-234` `date -d` | S4 (`DEV_CYCLE_TODAY`), S1 (`last_bs`, regex-bounded), `$SINCE` (regex-checked) | regex | cleared; `DEV_CYCLE_TODAY` is test-only env |
| `:164-165` `sha256sum`, `shuf --random-source` | `$TODAY` | none needed | cleared |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | scrub() single pass with `s///` before `tr`: nested and C0-split sequences rebuild C1/RLO/tag | Medium | B1, B2 | `scripts/dev-cycle.sh:24-31` | High |
| 2 | PERL_UNICODE / PERL5OPT turns the byte-pattern scrub off | Medium | B4 → B1/B2 | `scripts/dev-cycle.sh:29` | Medium |
| 3 | Committed symlink: digest reads and prints an out-of-repo file | Medium | B3 → B1 | `scripts/dev-cycle.sh:111-119,171-175,227-232` | Medium (impact Low) |
| 4 | Zero-width / format characters not covered by the scrub | Informational | B1, B2 | `scripts/dev-cycle.sh:24-29` | High |
| 5 | Filters not waited for: possible silent truncation | Informational | Internal | `scripts/dev-cycle.sh:31` | Medium |

## Overall Assessment

The cut did what it was meant to do from a security angle. The carry-forward printing that allowed line forging (R1) is gone, and I found no new way to forge a line. The changes since pass 3 add no exec path that repo content controls. A2 is still open, though. `scrub()` is now the single guard on the only sink, and it can be bypassed two ways. Repo bytes can be nested or C0-split so the guard rebuilds C1, RLO and tag characters (executed, Finding 1). A common perl environment setting turns the guard off (executed, Finding 2). The tag-character path matters most for this tool, because the digest's main reader is an LLM agent. Both problems can be fixed in place in one line plus tests: `tr` first, repeat the substitution until stable, and pin perl's I/O layers. The symlink read (Finding 3) is a small separate hardening fix. Fix Finding 1 first. No findings within the other code paths read; endorsement claims pending execution verification.

## Goal-Alignment Note

Success criterion (verbatim from the brief): "a markdown report saved at the path your role instructions give, structured per your skill file."

This report is saved at `docs/reviews/security-review-2026-10-01-digest-final4.md` with `Commit: db0e5ca` first. It follows the security-reviewer structure: trust boundary map and source table, anchored findings, untested bypass candidates, routed endorsement claims, primitive sweep, summary, assessment. For the user's merge decision on Q-101's "add one scrub": the scrub exists, but it does not yet hold against repo-supplied bytes or a common perl env setting, so the A2 item it was meant to close is still open.
