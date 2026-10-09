Commit: 82bb5281

# API Consistency Review — feat/build-loop-u2b3b2a (U2b3b2a, final confirming pass)

**Scope:** the whole branch, `git diff main...HEAD -- scripts test` (HEAD 82bb5281): scripts/lib/dev-cycle-read.sh, test/scripts/build-loop-check.bats, test/scripts/dev-cycle.bats
**Date:** 2026-10-09
**Based on:** shared brief u2b3b2a-i3/shared.md; Stage-1 fact-check summary (docs/reviews/code-fact-check-report-build-loop-u2b3b2a-final.md, k=3); earlier reports docs/reviews/api-consistency-review-2026-10-09-u2b3b2a.md (i1, F1-F6) and -i2.md (F1-F3); override rows 558-572 in docs/reviews/override-log.md.

## Baseline Conventions

- **Contract comments.** Each lib function has a leading `name ARGS: ...` comment that says what it prints and when it returns 1 (import_work :1159-1162, import_readers :1000-1015, capped_read :1187-1194, nul_list :1180).
- **Pipes and pipefail.** The lib's header (:15-17) says the caller sets `-euo pipefail`. Helpers that need it regardless set `local -; set -o pipefail` themselves (lower_all :1186, tree_starts :1198, the walks :1249, :1300). import_targets avoids the question with "Two steps, not a pipe" (:1106-1107).
- **Parser output.** Newline-separated lines: repo-relative names, then `/N` (the work trailer, only with IMPORT_WORK_LEFT set). import_work strips it and fails on a missing trailer or a TOTAL past IMPORT_WORK_MAX.
- **Knobs and memo globals.** `IMPORT_*` globals read as `${X:-}`. The reader-set globals are newline-separated with no trailing newline, cleared together on recompute and at source, and listed in the sourcing inventory (test/scripts/dev-cycle.bats:1107-1114).
- **Errors.** Return 1 with no stderr. A walk turns any helper's 1 into `IMPORTED=error` / `IMPORTED_MAIN=error`.

## Final contract inventory (the branch's lib surface)

| Contract | State at 82bb5281 | Consistent with baseline? |
|---|---|---|
| import_targets output | Three line kinds: repo-relative, `//`+absolute (second channel), `/N` trailer. Disjoint: a repo name never starts with `/`. A `//` line ending in digits cannot match import_work's `( "$iw_o" == "/$iw_w" \|\| "$iw_o" == *$'\n'"/$iw_w" )` test (the fact-check executed this) | Yes |
| import_targets arguments | `DIR [DIRS...]`. A DIR or DIRS entry led by `/` is joined alone, others under every root (emit, :863-865). Documented in the header (:777-784) and the made-absolute sentence (:811-812) | Yes |
| import_targets reader set | `import_readers \|\| return 1` only (H5/A1). One refusal state. The ROOT_REAL-only fallback is gone. The direct-call change was declined (row 565) | Yes |
| IMPORT_WHOLE | Cleared at source (:1035). Set only as a one-call prefix (:1148). The bash test (`-z "${IMPORT_WHOLE:-}"`) and the awk test (`IT_WHOLE != ""`) agree: any non-empty value. The comment explains why IMPORT_LEFT/IMPORT_WORK_LEFT need no clearing (i2 F2 resolved) | Yes |
| IMPORT_DOTNEST | Declared, cleared and memoized beside IMPORT_ROOTS/HOMES. Trailing newline stripped (:1095). Has its own sentence in import_readers' header. Inventoried | Yes |
| import_outside `FILE [DIRS...]` | Always prints one summed trailer. Its header says it needs IMPORT_WORK_LEFT. Its returns-1 list is short by one reason (F1) | Mostly |
| import_file `FILE DIR [DIRS...]` | A repo FILE gets import_targets' contract. An absolute FILE gets import_outside's, and its header now says IMPORT_WORK_LEFT is needed and that a 1 means a failed walk (i2 F1 resolved). DIR is ignored for an absolute FILE (declined row 570) | Yes |
| outside_ok `PATH` | `-f && -r`, the one admission rule, used by both walks' `//` arms. Naming declined (row 569) | Yes |
| import_work | Header now says a second-channel name starts with `//`. Logic unchanged | Yes |
| Walk lists (IMPORTED, IMPORTED_MAIN) | Also hold lower-cased `//` names. The header says so (:737-738). isimported's whole-line match means a repo-relative `$2` cannot hit one | Yes |
| Walk-header exception list vs import_outside's header | They disagree on a file removed during the walk (F2) | No |

## Name-Pattern Audit

No new public names since iteration 2. The audit below is the final inventory for the branch.

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `import_outside` | function | `import_targets`, `import_work`, `import_readers` | scripts/lib/dev-cycle-read.sh:1000-1168 | Consistent |
| `import_file` | function | `import_targets`, `import_outside` | scripts/lib/dev-cycle-read.sh:1097-1154 | Consistent |
| `outside_ok` | predicate | `dirok`, `plaindir`, `inrepo_here` | scripts/lib/dev-cycle-read.sh:159-187 | Informational drift, declined (row 569). Not re-raised |
| `IMPORT_WHOLE` | knob | `IMPORT_LEFT`, `IMPORT_WORK_LEFT`, `IMPORT_READER_WHY` | scripts/lib/dev-cycle-read.sh:1030-1035 | Consistent |
| `IMPORT_DOTNEST` | memo global | `IMPORT_ROOTS`, `IMPORT_HOMES` | scripts/lib/dev-cycle-read.sh:1030, :1050, :1093-1095 | Consistent |
| `IT_WHOLE`, `IT_DOTNEST` | awk env | `IT_ROOTS`, `IT_HOMES`, `IT_WORK` | scripts/lib/dev-cycle-read.sh:957-966, :1123-1124 | Consistent |
| `//PATH` line | output kind | repo-relative lines, `/N` trailer | scripts/lib/dev-cycle-read.sh:897-899, :1159-1168 | Consistent |

## Findings

#### F1. import_outside's returns-1 list omits the summed IMPORT_WORK_MAX case, and its "a read fails" holds only under the caller's pipefail

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:1135-1139` (header), `:1140-1150` (body)
**Move:** 3 (consumer contract), 4 (error consistency)
**Confidence:** High
**Legibility-target:** import_outside's header, the contract U2b3b2b's outside seeds will call through import_file

Evidence (verbatim, :1135-1139; excerpt ends inside the header, which import_outside's body follows at :1140-1150, read):
```
# the walk's own import_work check is what bounds the pair. It returns 1 when
# IMPORT_WORK_LEFT is unset or empty (no trailer to sum), when realpath, a
# read or import_targets fails, or on a real path holding a newline (the
# projection reads one name per line: U2b3b2a i1 fact-check), so a file that
# changed after the walk admitted it fails the walk rather than being skipped.
```
and the body's `&& import_work a w || return 1` (twice). import_work `(( (iw_t += iw_w) <= IMPORT_WORK_MAX ))`.

Probe (my fixture under mktemp, `set -euo pipefail`): `IMPORT_WORK_MAX=1; IMPORT_WORK_LEFT=100000 import_outside $T/out/l.md` gave `rc=1 out=[]`. That is a fifth reason, not in the list. Commit 82bb5281 says the list is complete (fact-check Claims 3-4, Mostly accurate). Also, with pipefail off, `import_outside` on a mode-000 regular file gave `rc=0 out=[/0]`. The failed `< "$1"` redirect is hidden by the pipe, and the file reads as importing nothing. That fits the lib's header contract ("The caller sets -euo pipefail", :15). But import_targets' own comment (:1106-1107) avoids relying on it, and lower_all and tree_starts set `local -; set -o pipefail` themselves. Inside a walk nothing breaks: both walks set pipefail, and a walk admits only readable files. A direct caller that skips pipefail would get a quiet "imports nothing" where the header promises a 1.

**Recommendation:** Add "or the summed trailer passes IMPORT_WORK_MAX" to the list. Then either write "a read fails (under the pipefail the lib's callers set)" or add `local -; set -o pipefail` to import_outside and import_file, as lower_all and tree_starts do.

#### F2. The walk header and import_outside's header disagree on a file removed during the walk

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:732-733` vs `:1138-1139`
**Move:** 7 (asymmetry between two statements of one contract)
**Confidence:** High
**Legibility-target:** the walk header's exception sentence (what U2b3b2b's author reads first)

Evidence (verbatim):
```
# F1, F2). The walk reads outside files as they are when it runs: one
# changed or removed during the walk is read as it then is (i2 security F2).
```
(excerpt ends :733; the header continues to :739, read) and
```
# projection reads one name per line: U2b3b2a i1 fact-check), so a file that
# changed after the walk admitted it fails the walk rather than being skipped.
```

Probe: `outside_ok` admitted `$T/out/o.md`, it was then moved away, and `import_outside` returned 1 (`realpath: ... No such file or directory`, `rc=1`). So a removed file fails the walk, as import_outside says, and is not "read as it then is". An edited file is read as it then is, as the walk header says, and does not fail, against import_outside's "a file that changed ... fails the walk" (fact-check Claim 3). Each header is right for one case and wrong for the other. Both outcomes fail closed or read the current content, so no answer is wrong. A reader who checks one header against the other cannot tell which outcome a change produces.

**Recommendation:** Use one wording in both headers: "an edited file is read as it then is; a removed, unreadable or swapped-to-directory one fails the walk (a FIFO stalls it)".

#### F3. (cross-reference) put's "which no file a walk admits has" is Stale for outside files

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:880-882`
**Move:** 8 (format contract of the second channel)
**Confidence:** High (fact-check executed it)
**Legibility-target:** put's newline comment

Evidence (verbatim): `# which no file a walk admits has (and a printed one would split in two).` followed by `if (index(out, "\n") || out == "") return`.

Fact-check Claim 1 (Stale) showed that an outside file can have a newline in its name, and that both walks then answer ok without that file's import. For the API, the point is that the second channel has no way to express such a name. Dropping it silently differs from the newline handling elsewhere: import_outside returns 1 on a newline real path (:1142), and the walks fail on a newline start name. The orchestrator has escalated this to security, which owns its severity. It is recorded here only so the inventory is complete.

**Recommendation:** Defer to the security verdict. If the drop stays, the comment should say it applies to repo names only.

## What Looks Good

- All of iteration 2's contract fixes landed. import_file's header states the IMPORT_WORK_LEFT duty and that a 1 is a failed walk, never a skip. IMPORT_WHOLE's declaration says why it alone is cleared.
- The second channel is the one new output kind. It stays disjoint from both existing kinds, and every consumer (import_work, both walks' line loops, isimported) handles it in one arm each.
- import_targets' reader set now has one source and one refusal state (`import_readers || return 1`). The header's returns-1 sentence was updated to match (`import_readers fails (an empty ROOT_REAL, or refused settings, among its reasons)`).
- IMPORT_DOTNEST matches its siblings in lifecycle, shape and documentation, and the awk comment names its producer. truthrule's dot comment now points at the same producer, so the paired rule still has two named ends.
- The sourcing inventory covers every function and global the branch adds (import_outside, import_file, outside_ok, IMPORT_DOTNEST, IMPORT_WHOLE).
- The four new bats tests use the existing naming style and pin the contracts: the second channel, the absolute-DIR join, whole mode, the reader-set source, own-directory plus DIRS, and the skip set.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---|---|---|---|
| F1 | import_outside returns-1 list misses the summed IMPORT_WORK_MAX case; "a read fails" only under caller pipefail (rc=0, `/0` on an unreadable file without it) | Minor | `scripts/lib/dev-cycle-read.sh:1135-1150` | High |
| F2 | Walk header ("changed or removed ... read as it then is") and import_outside ("changed ... fails the walk") each half wrong; removed fails, edited is read | Minor | `scripts/lib/dev-cycle-read.sh:732-733, 1138-1139` | High |
| F3 | put's newline-drop comment Stale for outside names (cross-ref to the security escalation) | Informational | `scripts/lib/dev-cycle-read.sh:880-882` | High |

## Overall Assessment

The branch's lib contracts are consistent with the lib's conventions. The new output channel, the knobs and the memo global follow their siblings. The reader-set change gives one refusal state. Every earlier API finding is either resolved or declined in a row whose substance has not changed. What remains is comment precision in import_outside's header and in the walk header's exception sentence: one unlisted return-1 reason, a pipefail dependency the lib's header already assigns to the caller, and two statements about a file changing mid-walk that disagree. Each takes a clause or two to fix, and none changes a walk's answer.

## Goal-Alignment Note

The goal is to land U2b3b2a with the walks' superset and fail-closed properties intact. Neither F1 nor F2 is a false negative inside a walk. F1's unlisted case returns 1. Its no-pipefail case cannot arise in either walk, since both set pipefail and admit only readable files. F2's two outcomes either fail the walk or read the file's current content. The one fail-open on this surface is F3's newline-named outside file, which belongs to security's escalation and is not an API defect. F1 and F2 can be fixed in place or carried to U2b3b2b's first commit. The F1 fix matters most there, because U2b3b2b's outside seeds will call import_file directly, possibly from a context with different pipefail settings.
