Commit: 5e816c5b

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u3b1 (branch `feat/build-loop-u3b1`)
**Scope:** full branch `main...HEAD` at 5e816c5b: `scripts/build-loop.sh`, `test/scripts/build-loop-orchestrator.bats`, `test/scripts/build-loop-merge.bats` (one case), `docs/working/plan-build-loop-handoff.md:324` (U3b split, as-built note), commit bodies ec9ba0c7, 1bf01630, 8f99a919, 8367359f. Final confirming pass, replicate r3 (k=3).
**Checked:** 2026-10-12
**Total claims checked:** 32
**Summary:** 27 verified, 2 mostly accurate, 0 stale, 2 incorrect, 1 unverifiable

Legibility target for every claim: a reader who acts on the comment (the orchestrator author in U4, or the reviewer of the merge message) is not misled about what the script does.

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) read; no claim here matches a logged pattern, and neither Incorrect below is a fabricated symbol (both are mechanism or wording errors in commit bodies), so no log entry is owed.

**Execution provenance (shared by the executed claims).** All runs from `/tmp` (cwd per script: its own `mktemp -d /tmp/u3b1f3-*` dir), git 2.39.5, outputs captured in `/tmp/u3b1f3-logs-ReJQ/`:
- Suites, 2026-10-12T20:35:02Z: `TMPDIR=$(mktemp -d /tmp/u3b1f3-bats-XXXX) bats /workspace/.claude/wt-build-loop-u3b1/test/scripts/build-loop-orchestrator.bats` exit 0 (8/8), and the same for `build-loop-merge.bats` exit 0 (12/12). Logs `build-loop-orchestrator.txt`, `build-loop-merge.txt`.
- p1 (config-pair order, count parsing, git calls before harden), 20:36:12Z, `bash <scratchpad>/u3b1/f3-p1.sh` exit 0, log `p1.txt`.
- p2 (caller GIT_DIR / GIT_WORK_TREE / other variables; default branch at a tag, loose, packed and nested), 20:36:33Z, `bash <scratchpad>/u3b1/f3-p2.sh` exit 0, log `p2.txt`.
- p3 (more exit-1 cases; --marker body extraction against gpgsig/encoding/mergetag headers, CRLF, extra blank lines; UTF-8 cut at 2/3/4-byte boundaries; rule numbering; 5-byte and overlong sequences; fence past line 100; list-marker variants), 20:37:22Z, `bash <scratchpad>/u3b1/f3-p3.sh` exit 0, log `p3.txt`.
- p4 (the strict-UTF-8 regex vs Python's strict decode on 199,979 random/edge lines; `--git-path` under GIT_GRAFT_FILE, GIT_OBJECT_DIRECTORY, GIT_SHALLOW_FILE; update-ref at a tag), 20:39:30Z to 20:40Z, `bash <scratchpad>/u3b1/f3-p4.sh` exit 0 plus two one-line reruns, log `p4.txt`.
- p7 (git commit-tree re-encoding a non-UTF-8 message), 20:40Z, inline script, log `p7.txt`.
- Mutants, 20:38:04Z, `bash <scratchpad>/u3b1/f3-mut.sh` exit 0 (`git archive 5e816c5b scripts test` into a temp dir, one mutation each, orchestrator suite run on the copy), log `mutants.txt`. All 9 killed (M1 caller_gate in every mode, M2 HARDEN key mark removed, M3 caller_gate read with harden's full count, M4 quoted FENCE pass removed, M5 default_gate type check removed, M6 rule case-sensitive, M7 count check removed, M8 `<!--` rule removed, M9 T34 body unquoted).

`<scratchpad>` = `/tmp/claude-1000/-workspace/402ec840-a464-40f5-96ae-98af0cc535cf/scratchpad`.

---

## Claim 1: Plan as-built note: "prints `refuse state gate:` / `refuse state objects:` as `--check` does ... default_gate checks the ref's own object type (not MAIN_SHA), so land's re-run leaves a moved branch to the compare-and-swap. `--marker` also skips a marker commit over 64 KiB (its body not processed; --status' marker_kind has read the commit), a body line holding `<!--` ... and one that is not strict UTF-8 ... Discharged only in part, re-keyed to U3b3: rows 281, 311, 666"

**Location:** `docs/working/plan-build-loop-handoff.md:324`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the gate/objects lines, default_gate's type check and its land interaction (compare-and-swap path), and the three new --marker skip causes; does not establish W's fast-forward path (not executed) or the exit-1 sentence of the same note (Claim 6).

`state_start` prints exactly those lines: `gate_repo || { echo "refuse state gate: its merge repository could not be set up"; exit 2; }` and `|| { echo "refuse state objects: ..."; exit 2; }` (`scripts/build-loop.sh:1175-1177`), and the `state)` arm calls `state_start` then `echo ok` (`scripts/build-loop.sh:1550-1552`). default_gate tests `p="$(git show-ref --verify --hash "refs/heads/$MAIN" 2>/dev/null)" && [[ "$(git cat-file -t "$p" 2>/dev/null)" == commit ]]` (`scripts/build-loop.sh:564-565`), no MAIN_SHA. The merge suite's case at `test/scripts/build-loop-merge.bats:60-63` (main moved before land's re-run, still the compare-and-swap refusal) passed. The cap is `n="$(git cat-file -s ...)"` and `[[ "$n" -le "$MARKER_MAX" ]]` before `m="$(git cat-file commit ...)"` (`scripts/build-loop.sh:829-831`); the `<!--` and strict-UTF-8 tests are in the perl rule (`:841-842`). Mutants M5 and M8 were killed; the suites passed.

**Evidence:** `scripts/build-loop.sh:564-565`, `:829-831`, `:841-842`, `:1172-1178`, `:1550-1552`, `test/scripts/build-loop-merge.bats:60-63`, `/tmp/u3b1f3-logs-ReJQ/build-loop-merge.txt`, `/tmp/u3b1f3-logs-ReJQ/mutants.txt`

---

## Claim 2: "Rows 493/494/517 close on the flow once U4's SKILL.md starts each iteration with `--state`" (plan); "Rows 493, 494 and 517 close on the flow: the orchestrator's iteration starts with --state" (commit ec9ba0c7 Notes)

**Location:** `docs/working/plan-build-loop-handoff.md:324`
**Type:** Architectural
**Verdict:** Unverifiable
**Confidence:** High
**Verification mode:** static
**Scope:** Covers whether any caller runs `--state` at an iteration start today; does not establish U4's future flow.

No caller exists: `--state` appears only in `scripts/build-loop.sh` and its tests (paraphrased — no quote available because the claim covers absence of code: no matching grep results for `build-loop.sh --state` under `skills/` or `workflows/`). The plan's wording is conditional on U4 and correct as a plan; ec9ba0c7's present tense ("starts with --state") is a future flow. Needs U4's SKILL.md to verify.

**Evidence:** `docs/working/plan-build-loop-handoff.md:324`, `scripts/build-loop.sh:1550-1552`

---

## Claim 3: "ok BRIEF SHA / SHA: the marker (the branch tip, as --status reads it). Then the body (the message after the subject and the blank line below it, trailing blank lines dropped), scrubbed as all output is, each line prefixed "> " (an empty one ">"); at most 100 lines of 300 bytes ... with a last line "> (build-loop.sh --marker cut this body: K of N lines shown, M cut at 300 bytes)" when cut. A stopped marker's body may be empty."

**Location:** `scripts/build-loop.sh:96-106`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the ok line, the body boundaries (including commits with gpgsig, encoding and mergetag headers and an extra blank line after the subject), the prefixing, the caps and the note; does not establish that the 300-byte cap counts the "> " prefix (it does not: output lines reach 302 bytes).

`marker` reads `m="${m#*$'\n\n'}"; [[ "$m" != *$'\n'* ]] || body="${m#*$'\n'}"; body="${body#$'\n'}"` (`scripts/build-loop.sh:832`), pops trailing blank lines (`pop @l while @l && $l[-1] =~ /^[ \t]*\z/;`, `:838`), prints `print $s eq "" ? ">\n" : "> $s\n";` (`:851`) and the note (`:853`), then `echo "ok $a ${STATUS[sha]}"` (`:868`). In p3, a raw commit with an `encoding` header and a multi-line `gpgsig` whose continuation is a lone space printed `> Which one?`; a `mergetag` header with a ` ` line printed `> body line`; two blank lines after the subject printed `>` then `> body` (the second blank line is body). The suite's T32 cases pinned the 100-line note (`100 of 101 lines shown`) and the stopped/empty forms.

**Evidence:** `scripts/build-loop.sh:826-869`, `test/scripts/build-loop-orchestrator.bats:62-77,120-133`, `/tmp/u3b1f3-logs-ReJQ/p3.txt`

---

## Claim 4: "skip BRIEF: WHY — As --status skips it; the tip is no blocked or stopped marker ...; the marker commit is over 64 KiB (its body is not processed); a body line starts, after blanks, ">" and list markers ("-", "*", "+", "1." or "1)" and a blank), with "#", "**Needs:**", "**Status:**", "**Answer" or "Q-" and a digit, in any case, holds "<!--" ... or is not strict UTF-8 (no surrogate or code point past U+10FFFF, as questions.sh check reads it ...); ... a blocked marker with no body; or a read that fails."

**Location:** `scripts/build-loop.sh:107-118`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed skip cause and that every skip exits 0; does not establish the FENCE_AWK clause (Claim 5).

The prefix strip and match are `(my $s = $l[$i]) =~ s/^(?:[ \t>]|[-*+][ \t]|[0-9]+[.)][ \t])*//;` and `if ($s =~ /^(?:#|\*\*needs:\*\*|\*\*status:\*\*|\*\*answer|q-[0-9])/i || index($l[$i], "<!--") >= 0 || $l[$i] !~ /\A(?:[\x00-\x7F]|...)*\z/) { print "rule ", $i + 1, "\n"; exit 0 }` (`scripts/build-loop.sh:840-842`; excerpt ends :842, enclosing `marker` continues to :869 — read). Any digit count is accepted as a list number (p3: `12) q-3 y` refused), which is wider than "1." / "1)" but in the refusing direction. p3 also refused `+ **NEEDS:** x` and a tab/`>>-`/`#` mix, a 5-byte sequence and an overlong `\300\257`. p4: the regex agreed with Python's `decode("utf-8")` on all 199,979 fuzz lines (8,227 valid). The empty-blocked skip is `[[ -n "$body" || "${STATUS[loop]}" == stopped ]] || { echo "skip $a: its blocked marker holds no question (the body is empty)"; return; }` (`:856`). Every skip is `echo ...; return`, and the suite asserts `status -eq 0` on each (`marker_is`).

**Evidence:** `scripts/build-loop.sh:824-856`, `test/scripts/build-loop-orchestrator.bats:79-119`, `/tmp/u3b1f3-logs-ReJQ/p3.txt`, `/tmp/u3b1f3-logs-ReJQ/p4.txt`

---

## Claim 5: "a line of the body, as written or as quoted, that FENCE_AWK refuses, or a fence it leaves open" (help); "FENCE_AWK over the body as written, then as quoted; line N is the body's line N either way." (comment)

**Location:** `scripts/build-loop.sh:115-117`, `scripts/build-loop.sh:857`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the two FENCE_AWK passes read and their line numbering; does not establish any harm from the gap (the unread lines are never printed).

The first pass is not the body as written. It is the printed body with its `> ` prefix stripped: `for m in "$(printf '%s\n' "$body" | sed -E 's/^> ?//')" "$body"; do` (`scripts/build-loop.sh:859`), and `$body` by then holds perl's output: scrubbed, cut to 100 lines, each line cut to 300 bytes, plus the cut note (`:836-853`). In p3, a body of 100 numbered lines followed by an unclosed `` ``` `` printed `ok` with the note `100 of 102 lines shown`, so the fence the help lists as a skip cause was not seen. Line numbering does hold one-to-one for the printed lines. The comment two lines above, "Scrubbed first, so the rules, the caps and FENCE_AWK read what is printed" (`:833`), is the precise version. Tighten the help and `:857` to "the body as printed (after the cuts), with and without its quote prefix".

**Evidence:** `scripts/build-loop.sh:833-866`, `/tmp/u3b1f3-logs-ReJQ/p3.txt` (section "unclosed fence past line 100")

---

## Claim 6: "Exit 1 (stderr only) for a caller's GIT_CONFIG_COUNT that is not plain decimal, or a GIT_DIR naming no repository." (help); plan as-built "`--state` exits 1 (stderr only) for a non-decimal GIT_CONFIG_COUNT or a GIT_DIR naming no repository"

**Location:** `scripts/build-loop.sh:124-126`, `docs/working/plan-build-loop-handoff.md:324`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the caller-environment plantings that end --state with exit 1 and no stdout; does not establish anything about the decision itself (every case fails closed).

Both listed cases hold (p1: count `010` exit 1, `build-loop.sh: GIT_CONFIG_COUNT is not a plain decimal count`; p2: `GIT_DIR=<missing>` exit 1, `Not inside a git repository`). The list is presented as the exit-1 set but is incomplete. With stdout empty and exit 1:
- `GIT_WORK_TREE=<missing dir>` gives bash's own `build-loop.sh: line 573: cd: ...: No such file or directory` from `cd "$ROOT"` (`scripts/build-loop.sh:573`). Iteration 2's C4 rewrite dropped GIT_WORK_TREE entirely, when only the existing-directory case is exit 2 (p2 confirms that case refuses with exit 2).
- `GIT_COMMON_DIR=<missing>` and `GIT_OBJECT_DIRECTORY=<missing>` each give `Not inside a git repository` (p3).
- A plain-decimal `GIT_CONFIG_COUNT=3` with no `GIT_CONFIG_KEY_*` set, or `99999999999`, passes harden's regex. Git then fails, and the script prints `Not inside a git repository` (p3).

The footer's generic "1 ... not a git repo" (`:381-382`) covers most of these by message. The precise version: "exit 1 (stderr only) when the caller's git variables make git fail before the gate runs (a non-decimal or unusable GIT_CONFIG_COUNT, or a GIT_DIR, GIT_COMMON_DIR, GIT_OBJECT_DIRECTORY or GIT_WORK_TREE naming nothing)". Text-only: all cases print no `ok`.

**Evidence:** `scripts/build-loop.sh:458`, `:572-573`, `/tmp/u3b1f3-logs-ReJQ/p1.txt`, `/tmp/u3b1f3-logs-ReJQ/p2.txt`, `/tmp/u3b1f3-logs-ReJQ/p3.txt` (section "exit cases")

---

## Claim 7: "First, read only here, the caller's environment: a repo-local git variable set (... the caller's config pairs, GIT_NO_REPLACE_OBJECTS and GIT_PREFIX aside), or a caller pair (git -c, GIT_CONFIG_COUNT) setting a key the state gate refuses or one this script's own hardening sets (...; a git -c pair would win over it), whatever the value."

**Location:** `scripts/build-loop.sh:126-136`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which variables and pairs refuse, only in --state, before the state gate, case-folded keys and subsections; does not establish variables git does not list as repo-local (GIT_NAMESPACE passes, p2) or non-git environment (settled Won't-Fix, B16).

The only call is `if [[ "$MODE" == state ]]; then caller_gate || exit 2; fi` (`scripts/build-loop.sh:583`), before `state_gate` (`:584`). Mutant M1 (every mode) turned test 2 red. p2: GIT_DIR (another repo), GIT_WORK_TREE (existing dir), GIT_OBJECT_DIRECTORY, GIT_CONFIG and GIT_INDEX_FILE each refused with exit 2. GIT_PREFIX passed. p1: `git -c` beat a GIT_CONFIG_COUNT pair for the same key (`/dashc`, and `/params` via GIT_CONFIG_PARAMETERS), so a caller `-c` overrides harden. `Core.FsMonitor`, `Filter.LFS.clean` and `remote.Origin.promisor` were each refused (exit 2). The user.name-only pair printed `ok`.

**Evidence:** `scripts/build-loop.sh:532-546`, `:583-584`, `/tmp/u3b1f3-logs-ReJQ/p1.txt`, `/tmp/u3b1f3-logs-ReJQ/p2.txt`, `/tmp/u3b1f3-logs-ReJQ/mutants.txt`

---

## Claim 8: "--check ... the default branch a symbolic ref or naming an object that is not a commit (an annotated tag)"

**Location:** `scripts/build-loop.sh:147-148`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a loose ref, a packed ref and a tag of a tag; does not establish a ref at a tree or blob, which resolve_main skips first, so that case exits 1 "needs a default branch found by name" rather than this refusal (p2).

`default_gate` runs in `state_start`, which `gate_start` calls (`scripts/build-loop.sh:1173`, `:1180`), so --check, --merge, --start and --prompt share it. p2 printed `refuse state default-branch: refs/heads/main names an object that is not a commit` (exit 2) for the loose ref, the packed ref and the nested tag. `--settings` (ungated) still answered. resolve_main peels with `rev-parse --verify --quiet "$sha^{commit}"` (`scripts/lib/dev-cycle-read.sh:540`), so a tree-valued main is never MAIN.

**Evidence:** `scripts/build-loop.sh:552-571`, `scripts/lib/dev-cycle-read.sh:529-555`, `/tmp/u3b1f3-logs-ReJQ/p2.txt`

---

## Claim 9: "Exit: 0 every line printed (or help; a --marker skip is a line), for --state ok ...; 2 ... or the state gate (--state's included) not ok. ... 1 bad usage, a GIT_CONFIG_COUNT that is not plain decimal, not a git repo, ..., a failed mktemp (--state, ...; no line printed), or no default branch found by name."

**Location:** `scripts/build-loop.sh:375-384`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the --marker and --state exit codes in the suite and probes; does not establish the mktemp-failure path (static only: `GATE_TMP="$(mktemp -d)"` under `set -e`, `:1174`) or the missing-GIT_WORK_TREE exit-1 case, which the footer's list covers only as a shell `cd` failure (Claim 6).

The suite's `marker_is` asserts exit 0 on each skip, and `state_is` asserts 0 for `ok` and 2 for refusals (`test/scripts/build-loop-orchestrator.bats:15,20`). `--marker` with no or two briefs exits 1 (`:143-144`). The count refusal exits 1 in four modes (p1).

**Evidence:** `scripts/build-loop.sh:375-384`, `:1172-1178`, `test/scripts/build-loop-orchestrator.bats:15-20,135-144`, `/tmp/u3b1f3-logs-ReJQ/p1.txt`

---

## Claim 10: "its `git -c` pairs can still win, so --state reads them (caller_gate); a GIT_CONFIG_COUNT that is not plain decimal (010 reads as 8 here and as 10 to git) stops every mode."

**Location:** `scripts/build-loop.sh:450-452`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the -c precedence, bash's and git's readings of `010`, and that the refusal comes before any git call in --settings, --state, --status and --marker; does not establish --help and usage errors (which exit before harden), or a decimal count with missing keys (passes the regex; git then fails, Claim 6).

`[[ "$c" =~ ^(0|[123456789][0123456789]*)$ ]] || { echo "build-loop.sh: GIT_CONFIG_COUNT is not a plain decimal count" >&2; exit 1; }` (`scripts/build-loop.sh:458`) runs in `harden` (`:456-463`), called at `:464` before `git rev-parse --show-toplevel` (`:572`). p1 measured `$((010 + 0))` = 8 in bash, and git with `GIT_CONFIG_COUNT=010` read `GIT_CONFIG_KEY_9` (10 entries). With a logging git shim first on PATH, all four modes exited 1 with the message and the shim logged 0 calls.

**Evidence:** `scripts/build-loop.sh:454-465`, `/tmp/u3b1f3-logs-ReJQ/p1.txt` (sections C, C2, D)

---

## Claim 11: "callervar NAME: a repo-local variable ... the gate keeps: the caller's config pairs, which harden extends and trusts (GIT_CONFIG_PARAMETERS, GIT_CONFIG_COUNT), and GIT_NO_REPLACE_OBJECTS, which this script sets. GIT_CONFIG is not one ... (gate_repo unsets it; checkout_gate refuses it)."

**Location:** `scripts/build-loop.sh:508-513`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three kept names and GIT_CONFIG's handling; does not establish gate_repo's unset (static, pre-existing).

`callervar() { [[ "$1" == GIT_CONFIG_PARAMETERS || "$1" == GIT_CONFIG_COUNT || "$1" == GIT_NO_REPLACE_OBJECTS ]]; }` (`scripts/build-loop.sh:513`); the script exports `GIT_NO_REPLACE_OBJECTS=1` (`:470`). p2: GIT_CONFIG refused by caller_gate too (`refuse state GIT_CONFIG: ...`, exit 2), which the comment does not name but does not deny.

**Evidence:** `scripts/build-loop.sh:470`, `:508-517`, `/tmp/u3b1f3-logs-ReJQ/p2.txt`

---

## Claim 12: "stray_vars: the repo-local git variables set here, one per line, but the caller's (callervar) and GIT_PREFIX ... checkout_gate and caller_gate refuse them."

**Location:** `scripts/build-loop.sh:514-517`
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the list source and exclusions, and both callers; does not establish that checkout_gate names more than the first stray variable (it takes `${x%%$'\n'*}`, `:1096`).

`stray_vars() { local v; for v in $(git rev-parse --local-env-vars); do [[ -z "${!v+set}" || "$v" == GIT_PREFIX ]] || callervar "$v" || echo "$v"; done; }` (`:517`); callers at `:534` and `:1096`. p2 printed git 2.39.5's list (16 names, GIT_COMMON_DIR and GIT_IMPLICIT_WORK_TREE included) and the refusals in Claim 7.

**Evidence:** `scripts/build-loop.sh:517`, `:534`, `:1096-1097`, `/tmp/u3b1f3-logs-ReJQ/p2.txt`

---

## Claim 13: "GIT_REPLACE_REF_BASE, GIT_SHALLOW_FILE and GIT_ALTERNATE_OBJECT_DIRECTORIES name files the state gate does not read, and GIT_GRAFT_FILE or GIT_OBJECT_DIRECTORY move the ones it does. A caller pair (... read with the caller's count, so harden's own pairs are not listed) ... git applies git -c pairs after harden's, so they win (a GIT_CONFIG_COUNT pair comes before harden's and loses, but is refused too)."

**Location:** `scripts/build-loop.sh:522-531`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the --git-path redirections the state gate's file checks see, the count-limited listing and the precedence; does not establish behaviour on git versions other than 2.39.5.

p4: `--git-path info/grafts` became `/x/g` under GIT_GRAFT_FILE, and `objects/info/alternates` moved under GIT_OBJECT_DIRECTORY. `shallow` stayed `.git/shallow` under GIT_SHALLOW_FILE, and the state gate lists `refs/replace/` literally (`:500`). p1 B: with `GIT_CONFIG_COUNT=1` and a second pair set, `--show-scope` listed only `command x.one`. In G, a valid caller count left harden's pairs unlisted and printed `ok`. In A/E, `-c` won over a COUNT pair. Mutant M3 (full count) turned tests 1-2 red. The suite's COUNT case refused `core.hookspath` (`test/scripts/build-loop-orchestrator.bats:48-49`).

**Evidence:** `scripts/build-loop.sh:485-506`, `:532-546`, `/tmp/u3b1f3-logs-ReJQ/p1.txt`, `/tmp/u3b1f3-logs-ReJQ/p4.txt`, `/tmp/u3b1f3-logs-ReJQ/mutants.txt`

---

## Claim 14: "resolve_main peels the ref to its commit, which land's compare-and-swap would then never match (row 656). The ref itself, not MAIN_SHA: land's re-run must leave a moved branch to its own refusal (the compare-and-swap, or the fast-forward in W)."

**Location:** `scripts/build-loop.sh:560-563`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the peel, the compare-and-swap path and the moved-main re-run; does not establish the W fast-forward path (not executed).

resolve_main: `sha="$(git rev-parse --verify --quiet "$sha^{commit}" 2>/dev/null || true)"` (`scripts/lib/dev-cycle-read.sh:540`). land: `{ state_gate && default_gate && ...; }` then `git update-ref --no-deref -m "$msg" "refs/heads/$MAIN" "$NEW" "$MAIN_SHA"` (`scripts/build-loop.sh:1408-1411`). The merge suite (which moves main inside commit-tree, before the re-run) passed with the compare-and-swap's message.

**Evidence:** `scripts/build-loop.sh:552-571`, `:1408-1412`, `scripts/lib/dev-cycle-read.sh:529-555`, `test/scripts/build-loop-merge.bats:60-63`, `/tmp/u3b1f3-logs-ReJQ/build-loop-merge.txt`

---

## Claim 15: "Every mode but the read modes decides or writes ... --marker reads one marker as --status reads its tip" and "The caller's environment first: it can point the state gate's own reads elsewhere."

**Location:** `scripts/build-loop.sh:578-583`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the order caller_gate → state_gate and the ungated --marker; does not establish that nothing runs before caller_gate (harden and `git rev-parse --show-toplevel` / `cd "$ROOT"` do, `:464`, `:572-573`). Those read no object, and a GIT_DIR naming another repo still ends in caller_gate's refusal (p2).

`GATED=""; [[ "$MODE" =~ ^(settings|status|marker)$ ]] || GATED=1` (`:581`), then `:583-584`. p2: `GIT_DIR=<other repo>` → `refuse state GIT_DIR: ...`, exit 2, with no state-gate line.

**Evidence:** `scripts/build-loop.sh:572-585`, `/tmp/u3b1f3-logs-ReJQ/p2.txt`

---

## Claim 16: "A blocked marker's body rule (D3, D11), as the loop prompt states it and --marker enforces it (row 689: one string)" and "The marker commit's size cap in bytes: over it, the body is not processed (marker_kind has still read the commit, in --status' own reads)."

**Location:** `scripts/build-loop.sh:805-810`
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the string's two uses and that the regex agrees with its text; does not establish that the loop model follows it.

`BODY_RULE` is interpolated in the skip line (`:855`) and the prompt (`... at most $BODY_LINES lines of $BODY_BYTES bytes (longer is cut; a commit over $MARKER_MAX bytes is skipped): $BODY_RULE;`, `:1538`). Each clause matches the perl test (Claim 4). The cap test precedes `cat-file commit` (`:829-831`), after `status_fields` → `marker_kind` read the commit twice (`:728`, `:734`). The suite's 70,000-byte case passed.

**Evidence:** `scripts/build-loop.sh:721-739`, `:805-810`, `:826-831`, `:855`, `:1538`, `/tmp/u3b1f3-logs-ReJQ/build-loop-orchestrator.txt`

---

## Claim 17: "The orchestrator files the body inside an entry it heads itself: the questions readers anchor at column 0, so a quoted line is never read as a heading, a Needs line or an answer (E2, E3). ... any line FENCE_AWK refuses in the body or in its quoted form (the questions file is read whole by FENCE_AWK: one refused line there would stop every answer in it)"

**Location:** `scripts/build-loop.sh:816-822`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers heading, Needs/Status and answer matching in ANSWER_AWK and questions.sh parse_entries/extract/archive, and FENCE_AWK's whole-file effect; does not establish two readers that are not column-0 anchored: render_index (`index($0, start)`, closed for bodies by the `<!--` rule; questions.sh half deferred) and parse_entries' index summary, which takes the first prose line, quoted or not (summary text only).

ANSWER_AWK: `substr(l, 1, 4) != "### "`, `/^\*\*Needs:\*\*/`, `line = $0; sub(/^- /, "", line)` then `index(line, id ":") == 1` and `low !~ /^\*\*answer(:|ed| \()/` (`scripts/lib/dev-cycle-read.sh:2036,2046,2053-2056`). Its END prints `odd` before any answer: `if (odd) print "odd " odd " " oddwhy` (`:2068`). questions.sh: `/^### Q-[0-9]+ /`, `/^\*\*Needs:\*\*/` (`scripts/questions.sh:161,171,223,364`); the summary rule is `want_summary && status != "" && /[^[:space:]]/ && !/^\*\*/ && !/^###/ && !/^</` (`:184`); the anywhere matches are `grep -aqF "$INDEX_START"` and `index($0, start)` (`:312,:340`). T34 passed, and its unquoted mutant M9 failed.

**Evidence:** `scripts/lib/dev-cycle-read.sh:2020-2075`, `scripts/questions.sh:150-200,294,309-345,363-370`, `/tmp/u3b1f3-logs-ReJQ/mutants.txt`

---

## Claim 18: "marker_kind has refused a NUL and a second subject line; the headers end at the first empty line."

**Location:** `scripts/build-loop.sh:828`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers commit objects, including gpgsig/mergetag continuation lines; does not establish other object kinds (the tip is always a commit here).

marker_kind: `if [[ "$(git cat-file commit "$1" | tr -cd '\000' | wc -c)" -gt 0 ]]; then echo "bad it holds a NUL byte"` and `if [[ "$msg" == *$'\n'* && -n "${rest%%$'\n'*}" ]]; then echo "bad its subject runs onto a second line"` (`:734`, `:739`). Continuation lines start with a space, so a signature's blank line is `" "` and never `\n\n` (p3 printed the right bodies). p3: a subject followed directly by a line, and a CRLF subject, were both skipped as "its subject runs onto a second line".

**Evidence:** `scripts/build-loop.sh:721-747`, `/tmp/u3b1f3-logs-ReJQ/p3.txt`

---

## Claim 19: "Scrubbed first, so the rules, the caps and FENCE_AWK read what is printed. Prints "rule N", or the quoted lines (no lines: nothing but blanks)."

**Location:** `scripts/build-loop.sh:833-834`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the pipeline order and output forms; does not establish scrub's own rules (lib, pre-existing).

`body="$(printf '%s\n' "$body" | scrub | env LC_ALL=C N="$BODY_LINES" B="$BODY_BYTES" perl -e '...')"` (`:836`). The quoted lines always start with `>`, so `"rule "*` cannot collide. Whitespace-only bodies gave the empty-body skip (suite), and the scrub case printed `> abc` / `> de`. Rule numbering counts a leading blank body line (p3: `# heading` as the third line → `line 3`).

**Evidence:** `scripts/build-loop.sh:833-856`, `test/scripts/build-loop-orchestrator.bats:107,121-124`, `/tmp/u3b1f3-logs-ReJQ/p3.txt`

---

## Claim 20: "A lead byte whose sequence the cut left short goes with its tail." / help "(a character is never split)"

**Location:** `scripts/build-loop.sh:848`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers 2-, 3- and 4-byte characters at the 300-byte boundary on lines that passed the strict-UTF-8 rule; does not establish the cut on invalid input (unreachable: the rule skips it first).

`if ($s =~ /([\xC0-\xF7][\x80-\xBF]*)\z/) { my $b = ord($1); $s = substr($s, 0, -length($1)) if length($1) < ($b >= 0xF0 ? 4 : $b >= 0xE0 ? 3 : 2) }` (`:849`). p3 printed lines of 298+2 bytes (a € cut at 300 dropped), 297+€ (kept, 300), 299 (😀 dropped), 297 (😀 dropped) and 296+😀 (kept, 300). The whole output decoded as strict UTF-8 in Python.

**Evidence:** `scripts/build-loop.sh:845-851`, `/tmp/u3b1f3-logs-ReJQ/p3.txt` (section "UTF-8 cut")

---

## Claim 21: "state_start is its state half (all --state runs once main is found: rows 525, 690)." and gate_start calls it first

**Location:** `scripts/build-loop.sh:1170-1182`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the split and both callers; does not establish dispatch's cost (row 690 deferred).

`state_start() { default_gate || exit 2; GATE_TMP="$(mktemp -d)"; ... store_check --main "$MAIN_SHA" ... }` and `gate_start() { state_start; reader_settings; read_settings; never_res; open_shared; }` (`:1172-1182`). The `state)` arm calls only `state_start` (`:1550-1552`).

**Evidence:** `scripts/build-loop.sh:1172-1182`, `:1550-1552`

---

## Claim 22: Loop prompt: ""handoff: blocked", with the question after a blank line as plain prose and an options table, at most $BODY_LINES lines of $BODY_BYTES bytes (longer is cut; a commit over $MARKER_MAX bytes is skipped): $BODY_RULE;"

**Location:** `scripts/build-loop.sh:1538`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the values and the rule interpolated are the ones --marker uses; does not establish the prompt's other lines.

Same variables as `:810` and `:807`; the cut and skip behaviour is as in Claims 3, 4 and 16.

**Evidence:** `scripts/build-loop.sh:807-810`, `:1538`

---

## Claim 23: "# Moved before land's default_gate re-run: still the compare-and-swap's refusal, not a non-commit (U3b1 B4)."

**Location:** `test/scripts/build-loop-merge.bats:60`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the compare-and-swap case; does not establish W's fast-forward case.

`shim commit-tree "\"\$REAL\" --git-dir='$R/.git' update-ref refs/heads/main $o"` then `refused "the default branch moved after the check, or could not be updated; it was left as it is"` (`:61-62`). commit-tree runs before land's re-run (`scripts/build-loop.sh:1404-1408`). The suite passed.

**Evidence:** `test/scripts/build-loop-merge.bats:60-63`, `scripts/build-loop.sh:1402-1412`, `/tmp/u3b1f3-logs-ReJQ/build-loop-merge.txt`

---

## Claim 24: "# git's update-ref refuses a branch at a non-commit: write the ref file."

**Location:** `test/scripts/build-loop-orchestrator.bats:33`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5's update-ref; does not establish other git versions.

Executed: `git update-ref refs/heads/main <annotated tag id>` → `fatal: ... trying to write non-commit object ... to branch 'refs/heads/main'`, exit 128.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:33-35`, `/tmp/u3b1f3-logs-ReJQ/p4.txt` (last line)

---

## Claim 25: "# A plain caller pair passes; a count harden would misread stops every mode (row 276)." and "# Only --state reads the caller's environment: neither --settings nor the gated --check refuses for it."

**Location:** `test/scripts/build-loop-orchestrator.bats:50`, `test/scripts/build-loop-orchestrator.bats:56`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the behaviour both comments state; does not establish that the count loop itself exercises more than `--settings` (it does not; p1 covered four modes).

The loop runs `--settings` with `010 08 1x " 1"` (`:51-54`). p1 D showed exit 1 in --settings, --state, --status and --marker. Mutant M7 (count check removed) and M1 (caller_gate in every mode) each turned test 2 red.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:50-60`, `/tmp/u3b1f3-logs-ReJQ/p1.txt`, `/tmp/u3b1f3-logs-ReJQ/mutants.txt`

---

## Claim 26: "# Not strict UTF-8 as questions.sh check (Python) reads it: a stray byte, a surrogate Perl's own decoder takes, past U+10FFFF (i2 fact-check 7b). Written raw: git commit-tree re-encodes a message."

**Location:** `test/scripts/build-loop-orchestrator.bats:88-89`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers questions.sh check's decoder, commit-tree's re-encoding and the three byte cases; does not establish Perl's decoder behaviour (not re-run).

questions.sh check: `python3 -c 'import sys; open(sys.argv[1],"rb").read().decode("utf-8")'` (`scripts/questions.sh:242`). p7: commit-tree turned `\377` into `\303\277` and the surrogate bytes into Latin-1-to-UTF-8 pairs, with the warning "commit message did not conform to UTF-8".

**Evidence:** `test/scripts/build-loop-orchestrator.bats:88-92`, `scripts/questions.sh:242`, `/tmp/u3b1f3-logs-ReJQ/p7.txt`

---

## Claim 27: "# Inside a balanced fence the raw pass reads nothing; quoted, the line is a link reference definition.", "# A marker commit over the cap is skipped before its body is processed", "# 300 bytes kept; a two-byte character that would end past byte 300 is dropped whole."

**Location:** `test/scripts/build-loop-orchestrator.bats:110`, `:112`, `:124`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three test comments against their cases; does not establish anything beyond the cases.

Mutant M4 (quoted pass removed) turned test 5 red, so the `:110` case depends on the quoted pass. `:112-114` asserts the cap message. `:125-129` expects `${long}y` twice and `${long}` for `${long}\303\251z`. The suite passed.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:110-133`, `/tmp/u3b1f3-logs-ReJQ/mutants.txt`, `/tmp/u3b1f3-logs-ReJQ/build-loop-orchestrator.txt`

---

## Claim 28: Commit 1bf01630: "the T34 case passes now (it pins the readers) and fails with the body unquoted."

**Location:** `test/scripts/build-loop-orchestrator.bats:145-160`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the unquoted mutation of the case's printf; does not establish other ways of breaking the readers.

Mutant M9 (`printf '> %s\n'` → `printf '%s\n'` at `:152`) turned test 8 red.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:152`, `/tmp/u3b1f3-logs-ReJQ/mutants.txt`

---

## Claim 29: Commit ec9ba0c7 body: "(GIT_REPLACE_REF_BASE, GIT_GRAFT_FILE and the object directories name files the state gate never reads)"

**Location:** commit ec9ba0c7 (message body, paragraph 1)
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the GIT_GRAFT_FILE and GIT_OBJECT_DIRECTORY halves; does not dispute GIT_REPLACE_REF_BASE or GIT_ALTERNATE_OBJECT_DIRECTORIES.

The state gate checks `--git-path info/grafts` and `objects/info/alternates` (`for f in info/attributes info/grafts shallow objects/info/alternates; do p="$(git rev-parse --path-format=absolute --git-path "$f" ...)"`, `scripts/build-loop.sh:496-497`). p4: GIT_GRAFT_FILE and GIT_OBJECT_DIRECTORY move those paths, so these variables move files the gate reads. The code comment (`:523-525`) and 8f99a919's body already say this. Text-only, in a commit body: worth one line in the merge message beside the corrections the rubric already lists.

**Evidence:** `scripts/build-loop.sh:496-499`, `:522-525`, `/tmp/u3b1f3-logs-ReJQ/p4.txt`

---

## Claim 30: Commit ec9ba0c7 Notes: "caller_gate runs in --state only, so --check keeps its behaviour for a caller's variables (checkout_gate still refuses them for a self-merge brief)"

**Location:** commit ec9ba0c7 (Notes)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers --check under GIT_REPLACE_REF_BASE and a `-c merge.x.driver` pair (review brief) and checkout_gate's self-merge call site; does not establish --check under every variable.

`co=""; if [[ -n "$sm" ]] && ! checkout_gate; then co="refuse $a: a self-merge brief needs --check run from a clean checkout ...; $CHECKOUT_WHY"; fi` (`scripts/build-loop.sh:1257`). The suite's `--check` case under both plantings printed `ok` (`test/scripts/build-loop-orchestrator.bats:57-60`), and M1 turned it red.

**Evidence:** `scripts/build-loop.sh:1257`, `test/scripts/build-loop-orchestrator.bats:56-60`, `/tmp/u3b1f3-logs-ReJQ/mutants.txt`

---

## Claim 31: Commit 8f99a919 body: "a marker commit over 64 KiB is skipped unread" and "one that is not valid UTF-8 ... breaks the body rule"

**Location:** commit 8f99a919 (message body, paragraph 1)
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two phrases as they describe HEAD; does not re-open C1/C2, which 8367359f fixed in the code and text.

At HEAD, marker_kind reads the commit before the cap (`msg="$(git cat-file commit "$1" ...)"`, `scripts/build-loop.sh:728`). The rule is strict UTF-8 (`:842`), where 8f99a919 shipped Perl's lax decoder. The rubric already records these two as "Commit-body corrections owed in the merge message". They are re-listed here only so the merge-message reviewer sees them beside Claim 29. Text-only.

**Evidence:** `scripts/build-loop.sh:728`, `:829-831`, `:842`, `docs/reviews/code-review-rubric-2026-10-12-feat-build-loop-u3b1.md` (Iteration 2 section)

---

## Claim 32: Commit 8367359f: "The rule is now one strict UTF-8 match, as Python reads it" (also BODY_RULE "strict UTF-8"; help "no surrogate or code point past U+10FFFF, as questions.sh check reads it")

**Location:** commit 8367359f (C1 paragraph)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers byte-level agreement with CPython's strict `decode("utf-8")` on lines of 1-6 bytes biased to boundary bytes; does not establish exhaustive equivalence (random sample), though the regex is the RFC 3629 table.

p4: 199,979 lines, 8,227 valid, 0 disagreements between the perl regex (copied from `scripts/build-loop.sh:842`) and Python. p3 also refused a 5-byte sequence and an overlong `\300\257`.

**Evidence:** `scripts/build-loop.sh:842`, `/tmp/u3b1f3-logs-ReJQ/p4.txt`, `/tmp/u3b1f3-logs-ReJQ/p3.txt`

---

## Claims Requiring Attention

### Incorrect
- **Claim 29** (commit ec9ba0c7): says GIT_GRAFT_FILE and the object directories name files the state gate never reads. GIT_GRAFT_FILE and GIT_OBJECT_DIRECTORY move files it does read. Text-only (commit body; the code comment is already right). Add it to the merge message's corrections.
- **Claim 31** (commit 8f99a919): "skipped unread" and "valid UTF-8". Text-only, already tracked by the rubric as owed in the merge message.

### Stale
- None.

### Mostly Accurate
- **Claim 5** (`scripts/build-loop.sh:115-117`, `:857`): FENCE_AWK reads the printed body (scrubbed, cut to 100 lines × 300 bytes), not the body "as written". A fence opened past line 100 is not a skip. Text-only: say "as printed, with and without the quote prefix".
- **Claim 6** (`scripts/build-loop.sh:124-126`; plan `:324`): the exit-1 list omits GIT_WORK_TREE naming a missing directory (bash `cd` error), GIT_COMMON_DIR or GIT_OBJECT_DIRECTORY naming nothing, and a decimal GIT_CONFIG_COUNT whose keys are missing. Text-only, all fail closed.

### Unverifiable
- **Claim 2** (plan `:324`, commit ec9ba0c7): rows 493/494/517 close only when U4's SKILL.md runs `--state` at each iteration start. Needs U4.

## Goal-Alignment Note

The unit's goal is that the orchestrator can trust `--state` as a snapshot check of the script's own hardened reads, and that `--marker` output pasted under an orchestrator-headed entry is never read as entry grammar and never breaks the questions readers. The executed evidence supports both: no behavioural Incorrect was found.
- caller_gate's precedence and count-limited reading hold on git 2.39.5.
- The count refusal precedes every git call.
- default_gate's type check leaves land's moved-main case to the compare-and-swap.
- The body rule, the strict-UTF-8 match (0 disagreements with Python), the character-safe cut and the column-0 claim all hold.
- All 9 mutants of the new rules and tests were killed.

What remains is wording: two commit-body errors for the merge message and two help-text imprecisions (FENCE_AWK's "as written"; the exit-1 list). None changes a decision, and each is on the fail-closed side. Unchanged residuals: the non-column-0 readers in questions.sh (render_index, closed for bodies by the `<!--` rule; the summary line) and the U4-dependent row closures.
