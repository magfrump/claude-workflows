**Commit:** 0ae7d801

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u1b (unit `feat/build-loop-u1a...feat/build-loop-u1b`)
**Scope:** Submitted claims only (security-reviewer x2, performance-reviewer x1) about `scripts/build-loop.sh`; no fresh harvesting (Stage 1 covered the diff)
**Checked:** 2026-10-05
**Total claims checked:** 3 (split into 5 atoms: 42, 43a, 43b, 44a, 44b)
**Summary:** 3 verified, 0 mostly accurate, 0 stale, 1 incorrect, 1 unverifiable

Line numbers below are those of `scripts/build-loop.sh` at 0ae7d801 (192 lines). The submitted locations were given in diff-hunk numbering; the mapping is: claim 1's `:150-183` is the file's `:113-185` (main_file through read_settings), claim 2's `:157` is the file's `:157`, and claim 3's `:194-198` does not exist (the file ends at `:192`); the call site is `:187-191`.

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) consulted: no submitted claim matches a logged fabrication pattern, and no claim below is a fabrication (43b is a wrong edge case, not an invented symbol), so the log is not updated.

Executed-probe provenance (shared by claims 42 and 43):
- Commands: `timeout 120 bash probe.sh > probe-out.txt 2>&1` (started 2026-10-05T11:29:09Z, exit 0) and `timeout 60 bash probe2.sh > probe2-out.txt 2>&1` (started 2026-10-05T11:29:21Z, exit 0).
- Working directory: `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b-i2/submitted/` (each probe builds a throwaway repo, `repo/` or `repo2/`, inside it, under a hermetic git environment, and runs the worktree's `scripts/build-loop.sh --settings` with `DEV_CYCLE_SCRUBBED=1` so the output is what read_settings built, before the scrub).
- Scripts and captured output: `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b-i2/submitted/probe.sh`, `probe-out.txt`, `probe2.sh`, `probe2-out.txt`. Every `--settings` run in them exited 0.

---

## Submitted Claims

## Claim 42: "Policy and slots lines print no repo text besides line numbers; the never line prints the value only after every entry passed globform (NAMECHARS plus `*` `?`)."

**Submitted by:** security-reviewer
**Legibility-target:** security-reviewer (the trust-boundary row for `--settings` output: what repo-controlled bytes can reach stdout)
**Location:** `scripts/build-loop.sh:113-185`
**Type:** Invariant / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every assignment to POLICY_LINE, SLOTS_LINE and NEVER_LINE in read_settings (`:135-185`), including `many()`, the FILE_WHY strings set by main_file (`:113-129`) and the lib's `oddwhy`, on the raw pre-scrub output; does not establish anything about POLICY/NEVER as later modes will consume them (U1c/U2), does not cover stderr text from git or awk failures, and does not claim the printed globs are safe for a consumer that expands them with a shell (the line holds literal `*` and `?`).

Policy and slots lines. Every value that is not a fixed string is a line number or a regex capture of a fixed alternative:

```bash
# scripts/build-loop.sh:177-183
        POLICY_LINE="policy review unset: line ${first[policy]} reads self-merge, but the Self-merge never: line is malformed, so self-merge is off"
      else POLICY="$v"; POLICY_LINE="policy $v set: line ${first[policy]} $where"; fi
    else POLICY_LINE="policy review unset: line ${first[policy]} is not exactly \"Build-loop policy: self-merge\" or \"Build-loop policy: review\""; fi
    if [[ -z "${cnt[slots]-}" ]]; then SLOTS_LINE='slots 3 default: no line starts "Build-loop slots:"'
    elif [[ "${cnt[slots]}" -gt 1 ]]; then SLOTS_LINE="slots 3 default: $(many 'Build-loop slots:' slots)"
    elif [[ "${text[slots]}" =~ ^Build-loop\ slots:\ ([123456789])$ ]]; then SLOTS_LINE="slots ${BASH_REMATCH[1]} set: line ${first[slots]} $where"
    else SLOTS_LINE="slots 3 default: line ${first[slots]} is not exactly \"Build-loop slots: N\" with N from 1 to 9"; fi
```
(excerpt starts :177 inside the policy branch begun at `:172`; enclosing read_settings() runs `:135-185` — read)

`$v` on the policy line is `BASH_REMATCH[1]` of `^Build-loop\ policy:\ (self-merge|review)$` (`:174-175`), so only those two words; `first[...]`/`second[...]` come from awk's `NR` (`l1[k] = NR` and `l2[k] = NR`, SETTINGS_AWK `:111`); `many()` prints only those two numbers and its fixed key argument (`:150`). `$where` is `"of $f on the default branch"` with the constant `f=docs/dev-cycle.md` (`:136-138`). The key `k` read back at `:147` is one of the three literals awk assigns (`k = "policy"`, `"slots"`, `"never"`, SETTINGS_AWK `:108-110`).

When the file is not read, the three lines carry FILE_WHY:

```bash
# scripts/build-loop.sh:117-128
  e="$(main_entry "$f")"
  case "$e" in
    blob) ;;
    absent) FILE_WHY=absent; return 1 ;;
    notdir\ *) FILE_WHY="${e#notdir } is not a directory on the default branch"; return 1 ;;
    *) FILE_WHY="$f is not a regular file on the default branch"; return 1 ;;
  esac
  FILE_OUT="$(git cat-file blob "$MAIN_SHA:$f" | env LC_ALL=C awk "$FENCE_AWK$2")"
  case "$FILE_OUT" in
    odd\ *) read -r _ n why <<<"$FILE_OUT"; FILE_WHY="line $n of $f $(oddwhy "$why"), so the file is not read"; return 1 ;;
    unbalanced\ *) FILE_WHY="the code fence opened at line ${FILE_OUT#unbalanced } of $f is never closed, so the file is not read"; return 1 ;;
  esac
```
(excerpt ends :128; enclosing main_file() continues to :129 — read)

The `notdir` PART is a prefix of the script's own constant path (main_entry builds `want` from `$1` only: `while [[ "$rest" == */* ]]; do p="${p:+$p/}${rest%%/*}"; ...` at `scripts/lib/dev-cycle-read.sh:260`), so it can only be `docs`. `n` is awk's `NR`/`fline`, and `why` is one of FENCE_AWK's fixed `refuse()` arguments, mapped to fixed prose by `oddwhy` (`scripts/lib/dev-cycle-read.sh:231-241`). SETTINGS_AWK's body prints nothing; its END prints only `"odd " odd " " oddwhy`, `"unbalanced " fline`, or the per-key records (`:113-117`), so no repo line reaches FILE_OUT's `odd`/`unbalanced` forms.

Never line. NEVER_LINE carries `$v` only at `:170`, which is reached only when `why` stayed empty, i.e. the line passed the exact-prefix, no-tab/VT/FF/CR and single-space checks (`:157`) and every `${g%/}` passed globform and the duplicate check (`:161-167`). globform's first test is `[[ "$1" =~ ^[*?$NAMECHARS]+$ && "$1" != /* && "$1" != -* ]] || return 1` (`:124`), with `NAMECHARS='abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._/-'` (`scripts/lib/dev-cycle-read.sh:139`). The only bytes not checked by globform are a stripped trailing `/` (itself a NAMECHARS byte) and the single separating spaces, so the printed value is NAMECHARS, `*`, `?` and space only.

Executed (probe-out.txt, probe2-out.txt): `Build-loop policy: self-merge EVIL\033[31m$(id)` and `Build-loop slots: 4 EVIL` printed `policy review unset: line 1 is not exactly ...` and `slots 3 default: line 2 is not exactly ...`; duplicate hostile keys printed only `(lines 1 and 2)` / `(lines 3 and 4)`; `Self-merge never: a/ $(touch PWNED) b`, `a/ EVIL\033[2J`, `a/ caf\xc3\xa9 \xe2\x80\xae (U+202E)`, `a @`, `a //` and a NBSP separator all printed `never malformed: line 2 lists entry N, which is not an allowed glob form` (or the single-spaces reason) with no entry text; no `PWNED` file was created. HTML, refdef, unbalanced-fence (`` ```EVIL8 ``) and NUL files printed only the fixed oddwhy reasons with line numbers; a `docs` symlink to `EVIL$(id)` printed `docs is not a directory on the default branch`. No raw output contained ESC, VT, FF, CR or TAB. Accepted globs printed verbatim: `never * ?/ **/x .github/ set: ...`. The associative-array subscripts `seen[*]` behaved as a literal key: `* a` and `a b *` were accepted, `* *` and `* a *` were refused as `lists entry N twice`.

Residue noted, not a claim failure: main_entry's `error` result (ls-tree failed) falls into main_file's `*)` arm and is reported as `docs/dev-cycle.md is not a regular file on the default branch` (`:122`), a mislabel of a fixed string, not repo text, and it still turns self-merge off (`never malformed`, `:143`).

**Evidence:** `scripts/build-loop.sh:113-129`, `scripts/build-loop.sh:101-117`, `scripts/build-loop.sh:122-129`, `scripts/build-loop.sh:135-185`, `scripts/lib/dev-cycle-read.sh:139`, `scripts/lib/dev-cycle-read.sh:231-241`, `scripts/lib/dev-cycle-read.sh:256-267`, `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b-i2/submitted/probe-out.txt`, `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b-i2/submitted/probe2-out.txt`

---

## Claim 43a: "A tab, VT [or] FF ... in the never value makes the line malformed and turns self-merge off (R1/A1)."

**Submitted by:** security-reviewer
**Legibility-target:** security-reviewer (R1/A1 closure: blanks other than a single space in `Self-merge never:`)
**Location:** `scripts/build-loop.sh:157`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers TAB, VT and FF anywhere in the value (interior, trailing, and TAB leading/mixed per the suite's T45 cases), each making NEVER_LINE `never malformed` and the policy line `policy review unset ... so self-merge is off`; does not establish behavior for other Unicode blanks beyond NBSP (those fail globform instead, as one probe showed for NBSP) and does not cover CR (Claim 43b).

```bash
# scripts/build-loop.sh:155-158
      t="${text[never]}"; v="${t#Self-merge never: }"; why=""
      # Single spaces only: a tab or other blank would split differently in a later reader.
      if [[ "$t" != "Self-merge never: "* || "$v" == *[$'\t\v\f\r']* || ! "$v" =~ ^[^\ ]+(\ [^\ ]+)*$ ]]; then
        why='is not exactly "Self-merge never: GLOB ..." with single spaces'
```
(excerpt ends :158; enclosing read_settings() continues to :185 — read)

A non-empty `why` sets `never_ok=""` (`:169`), and `never_ok` empty turns a `self-merge` policy into `policy review unset` (`:176-177`). Executed (probe-out.txt): `a\tb`, `a\vb`, `a\v`, `a\fb`, `a\f` each printed `never malformed: line 2 is not exactly "Self-merge never: GLOB ..." with single spaces` and `policy review unset: line 1 reads self-merge, but the Self-merge never: line is malformed, so self-merge is off`.

**Evidence:** `scripts/build-loop.sh:155-158`, `scripts/build-loop.sh:169-177`, `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b-i2/submitted/probe-out.txt` (cases c2-tab, c2-vt, c2-vt-trail, c2-ff, c2-ff-trail)

---

## Claim 43b: "A ... CR in the never value makes the line malformed and turns self-merge off (R1/A1)."

**Submitted by:** security-reviewer
**Legibility-target:** security-reviewer (R1/A1 closure; whether `:157`'s `\r` test is a live guard)
**Location:** `scripts/build-loop.sh:157`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a single trailing CR (accepted: line set), a CR inside the line or two trailing CRs (file refused by FENCE_AWK, so self-merge off by the not-read path); does not establish any security impact, which is nil: the case where the claim fails is a CRLF line ending that is dropped before any check, leaving no CR in the value.

A single trailing CR never reaches `:157`: SETTINGS_AWK drops it before the line is recorded, and the stored text has no CR.

```awk
# scripts/build-loop.sh:101-102 (SETTINGS_AWK)
{ sub(/\r$/, "") }
fence($0) { next }
```
(excerpt ends :102; enclosing SETTINGS_AWK string continues to :117 — read)

Any other CR is refused by FENCE_AWK's `if (index(l, "\r")) { refuse("cr"); return 1 }` (`scripts/lib/dev-cycle-read.sh:215`), so the whole file is not read and the never line is `never malformed: line N of docs/dev-cycle.md holds a carriage return that does not end it, so the file is not read` (main_file `:126`, read_settings `:143`). Therefore the `\r` member of `[$'\t\v\f\r']` at `:157` is unreachable, and "a CR makes the line malformed" is false for the one CR that survives: executed (probe-out.txt, case c2-cr-trail), `Self-merge never: a\r` printed `never a set: line 2 of docs/dev-cycle.md on the default branch` with `policy self-merge set`. Cases c2-cr-mid (`a\rb`) and c2-crcr-trail (`a\r\r`) printed the file-refused reason on all three lines, with policy `review unset`: self-merge off, but by the file-not-read mechanism, not by `:157`.

A precise version: "A tab, VT or FF in the never value makes the line malformed; a CR inside the line makes the whole file unread (FENCE_AWK), which also turns self-merge off; one trailing CR is dropped."

**Evidence:** `scripts/build-loop.sh:101-102`, `scripts/build-loop.sh:126`, `scripts/build-loop.sh:141-143`, `scripts/build-loop.sh:157`, `scripts/lib/dev-cycle-read.sh:213-216`, `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b-i2/submitted/probe-out.txt` (cases c2-cr-mid, c2-cr-trail, c2-crcr-trail)

---

## Claim 44a: "read_settings is called once per --settings run"

**Submitted by:** performance-reviewer
**Legibility-target:** performance-reviewer (per-run cost: one ls-tree, one cat-file and one awk pass over docs/dev-cycle.md)
**Location:** `scripts/build-loop.sh:187-191` (submitted as `:194-198`, which is past the file's last line, `:192`)
**Type:** Architectural / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the call count in build-loop.sh at 0ae7d801 (one call, in the only mode); does not establish the cost of the re-exec under scrub_reexec (`:89`), which runs the whole script body twice as processes but read_settings only in the child, and does not cover future modes.

```bash
# scripts/build-loop.sh:187-192
case "$MODE" in
  settings)
    read_settings
    printf '%s\n' "$POLICY_LINE" "$SLOTS_LINE" "$NEVER_LINE"
    ;;
esac
```

A repo-wide grep finds one definition and one call (paraphrased — no quote available because the claim covers absence of other call sites: `grep -rn read_settings` over `*.sh`, `*.bats`, `*.bash` returns `scripts/build-loop.sh:135` (definition) and `:189` (call), plus the unrelated `read_settings_rules` in `hooks/auto-approve-allowed-commands.sh`). The outer process returns from `scrub_reexec` only in the child (`scripts/lib/dev-cycle-read.sh:77-80`: the parent `exit`s after the pipeline), so the call runs once per invocation.

**Evidence:** `scripts/build-loop.sh:89`, `scripts/build-loop.sh:135`, `scripts/build-loop.sh:187-192`, `scripts/lib/dev-cycle-read.sh:76-81`

---

## Claim 44b: "U1c/U2 will call it once per process as well."

**Submitted by:** performance-reviewer
**Legibility-target:** performance-reviewer (whether the per-run cost bound carries to --status / --check)
**Location:** `scripts/build-loop.sh:130-133` (the comment naming the future consumers); U1c and U2 code does not exist yet
**Type:** Architectural
**Verdict:** Unverifiable
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what the code and plan at 0ae7d801 say about future callers; does not establish how U1c (`--status BRIEF…`) or U2 (`--check`/`--merge`) will call read_settings, and does not establish that a second in-process call would be correct (see below).

The code only says the globals are meant for later modes: `# Sets POLICY, POLICY_LINE, SLOTS_LINE, NEVER (the globs, or empty) and / NEVER_LINE from main's commit. POLICY and NEVER are / for the modes that judge a brief (--status, then the gate).` (`scripts/build-loop.sh:130-132`). The plan specifies `--status BRIEF…` (several briefs in one process) and `--check BRIEF… [--expect SHA]` (`docs/working/plan-build-loop-handoff.md:205`, `:214`), which makes once-per-process the natural design, but nothing written fixes it. Needed to verify: U1c's and U2's code.

Relevant to the claim's premise: read_settings does not reset POLICY or NEVER on entry. They are initialized once at file scope, `POLICY=review; POLICY_LINE=""; SLOTS_LINE=""; NEVER=""; NEVER_LINE=""` (`scripts/build-loop.sh:133`), and set only on success, `else NEVER="$v"; ...` (`:170`) and `else POLICY="$v"; ...` (`:178`). So a second call in one process whose read fails or finds a malformed line would leave the first call's POLICY and NEVER in place while the *_LINE strings report review/malformed. Once-per-process is therefore a correctness precondition for U1c/U2, not only a performance property.

**Evidence:** `scripts/build-loop.sh:130-133`, `scripts/build-loop.sh:135-185`, `docs/working/plan-build-loop-handoff.md:203-215`

---

## Claims Requiring Attention

### Incorrect
- **Claim 43b** (`scripts/build-loop.sh:157`): a single trailing CR is dropped by SETTINGS_AWK (`:101`) and the line is accepted (`never a set`); any other CR makes FENCE_AWK refuse the whole file. The `\r` in `:157`'s blank test is unreachable; no security impact.

### Unverifiable
- **Claim 44b** (`scripts/build-loop.sh:130-133`): U1c/U2 are not written. Note for them: read_settings does not reset POLICY/NEVER on entry (`:133`, `:170`, `:178`), so a second call in one process could keep stale values.

## Goal-Alignment Note

The user's goal is a full code review of U1b before it lands. These verdicts clear the security-reviewer's output-boundary endorsement (42) on executed hostile inputs, and its R1/A1 closure for tab/VT/FF (43a). The one Incorrect (43b) is about an edge case, not a hole: R1/A1's fail-closed property holds for every CR that reaches the value, but via FENCE_AWK rather than `:157`, so the endorsement should cite that path. The performance claim's present-tense half holds (44a). Its future half (44b) is unverifiable now, and it surfaced a constraint for U1c/U2 to record: no repeated read_settings call per process unless POLICY and NEVER are reset on entry. No finding here blocks U1b.
