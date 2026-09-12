# Security Review — questions.md close-out (`3a94fdc~1..HEAD`)

**Commit:** 435f46a
**Scope:** `git diff 3a94fdc~1..HEAD` — commits `3a94fdc`, `8980861`, `435f46a`; files `devcontainer-config/install.sh`, `docs/decisions/log.md`, `docs/working/questions.md`, `scripts/cross-model-review.py`, `scripts/lite-review.py`, `test/cc-isolated-functions.bats`, `test/lite-review-grammar.bats`
**Date:** 2026-09-12
**Based on:** `docs/reviews/code-fact-check-report.md` (merged, k=3), incl. escalation E1
**Prior art consulted:** `docs/reviews/security-review-2026-09-12.md` (install.sh enforcement-set gap, Informational)

No escalation block: none of the five HALT patterns matched. No credentials, no
injection into SQL/shell, no TLS downgrade, no hardcoded keys, no dependency
manifest touched.

---

## Trust Boundary Map

```
B1 (moved): [repo working tree, agent-writable]  → [human `[y/N]` at install.sh:102-110]
                                                 → [installed config under the launcher's config dir + `cc-isolated --bless`]
B2 (new)  : [install.sh stdin: tty, pipe, or EOF] → [`read -r reply || reply=""` :106 + `case` :107-110]
                                                 → [bless-or-abort decision]
B3        : [git diff text, authored by whoever wrote the commits]
                                                 → [`template.format(diff=…)` lite-review.py:158, no delimiter defense]
                                                 → [LLM prompt → model response → `parse_findings` :86-108]
                                                 → [review verdict consumed by pr-prep §3c / review-fix-loop]
B4        : [`claude` CLI stdout]                → [`json.loads` :128 + envelope check :162]
                                                 → [`text = env["result"]` fed to the parser]
B5        : [env CLAUDE_DEVC_CONFIG_DIR / CLAUDE_DEVC_BIN_DIR]
                                                 → [no validation]
                                                 → [`rm -rf "${DEST:?}/$item"` :120, `cp -r` :121, `ln -sf` :126]
```

### Input-source classification

```
S1: install.sh stdin at the bless prompt  — request-time    — UNTRUSTED for the bless decision
                                                              (pipe/EOF/partial line are all reachable)
S2: repo working tree, incl. install.sh   — runtime-mutable — UNTRUSTED for exec/payload sinks:
    itself and CLAUDE_HOME_SRC entries                        the file's own header (:7-12) states
                                                              agent sessions bind-mount this rw
S3: `git diff` output fed to the prompt   — runtime-mutable — UNTRUSTED for the prompt/verdict sink;
                                                              trusted for availability only
S4: `claude` CLI JSON stdout              — third-party     — UNTRUSTED for the verdict sink
                                            response          (a refusal is a valid response);
                                                              trusted for availability
S5: CLAUDE_DEVC_CONFIG_DIR / _BIN_DIR     — deploy-time env — trusted for path sinks (the caller
                                                              already holds a host shell)
S6: argparse args (--range/--model/--out) — invocation-time — trusted for exec; --range is
                                                              argv-injection-shaped into `git diff`
S7: DEFAULT_MODEL, SYSTEM_PROMPT,         — code-constant   — trusted (all sinks)
    FINDING_RE
```

What crosses: two independent trust transitions, both of which this diff touches
without moving the boundary itself. B1/B2 is a **human-approval gate on a
security-boundary payload**, reached from the host, where the approving human's
only stated evidence is a diff (`install.sh:14` — "So: read the diff. It is the
rebuild gate"). B3/B4 is an **LLM-mediated review verdict** where the untrusted
input (the diff) and the evidence for the verdict (the model's prose) are the
same trust class. The diff's implicit assumption at B2 is that any non-`y` reply
must abort — which holds, and is the good news. The implicit assumption at B3 is
that a response containing the string `FINDINGS` came from a model that actually
reviewed the diff — which does not hold.

---

## Findings

### F1 — `install.sh` is host-executed, agent-writable, and sits outside every gate that covers the rest of `devcontainer-config/`

**Severity:** High
**Location:** `devcontainer-config/install.sh:14,25,83-99` (this diff modifies `:103-106`); `devcontainer-config/cc-isolated.sh:107-130`; `hooks/live-verify-gate.sh:57`
**Boundary:** B1 (source S2)
**Move:** #1 (trust boundaries), #5 (invert the access-control model)
**Confidence:** High on the mechanism; Medium on residual risk, which depends on a human habit the code does not enforce

`install.sh` is the one file in `devcontainer-config/` that runs **on the host**,
outside any container, with the invoking human's privileges — and it is excluded
from all three controls that cover its siblings:

1. **Its own changes are invisible to its own review gate.** `PAYLOAD` omits it
   by design, so the `diff -ru` loop at `:86-90` never shows it:

   ```
   23  # install.sh itself is not installed — it runs from the repo.
   24  # `claude-home` is assembled below from the repo root before the diff is shown.
   25  PAYLOAD=(devcontainer.json Dockerfile init-firewall.sh cc-sni-proxy.py cc-isolated.sh link-claude-home.sh egress claude-home)
   ```

   ```
   83  if [ -d "$DEST" ]; then
   84    echo "=== Changes this install would make ==========================================="
   85    changed=0
   86    for item in "${PAYLOAD[@]}"; do
   87      if ! diff -ru "$DEST/$item" "$SRC/$item" 2>/dev/null; then
   88        changed=1
   ```
   *(truncated inside the `if [ -d "$DEST" ]` block; the remainder is the
   `changed -eq 0` "(none …)" message, the `===` rule, and the `else` first-install
   branch through `:99`. Neither adds install.sh to the loop.)*

   A human who edits nothing and runs the script can be shown `(none — installed
   config already matches the repo)` while `install.sh` itself has been rewritten.

2. **It is not in the hashed enforcement set**, so it is not in the manifest, not
   in the blessed config hash, and not baked to the image's config-hash file:

   ```
   107  enforcement_files() {
   108    local cfg
   109    cfg="$(config_dir)"
   110    echo "devcontainer.json"
   111    echo "Dockerfile"
   112    echo "init-firewall.sh"
   113    echo "cc-sni-proxy.py"
   114    echo "link-claude-home.sh"
   115    echo "cc-isolated.sh"
   ```
   *(truncated mid-function; the remainder — `:116-130` — adds `egress/*.txt`,
   `projects/*.profile`, and the `claude-home` walk. `install.sh` appears nowhere,
   and cannot: the set is enumerated relative to the **installed** dir, which
   install.sh is never copied into.)*

3. **It is not in the commit gate's enforcement regex:**

   ```
   57  enforcement='^devcontainer-config/(Dockerfile|devcontainer\.json|init-firewall\.sh|cc-sni-proxy\.py|link-claude-home\.sh|cc-isolated\.sh|egress/)'
   ```

   Commit `8980861` modifies `install.sh` and carries no `Live-verified:` trailer.
   It would have passed the gate even if the gate were wired (see F2).

The attack this leaves open is exactly the one the file's own header names as the
threat model:

```
 7  # WHY A COPY RATHER THAN A SYMLINK INTO THE REPO. This directory is inside a repo
 8  # that agent sessions bind-mount read-write — an agent CAN edit these files. That is
 9  # fine, and deliberate: edits here are inert. Only the INSTALLED copy at
10  # ~/.config/claude-devcontainer/ is ever read by the launcher, it is in no bind
11  # mount, and getting an edit from here to there requires a human running this script
12  # and approving the diff below. Symlinking would hand the agent the boundary.
```

"Edits here are inert" is true of every `PAYLOAD` entry and false of `install.sh`:
an edit to `install.sh` is not inert, it is the next thing the host executes. The
argument "getting an edit from here to there requires a human … approving the diff
below" is circular for `install.sh`, because `install.sh` decides which diff is
shown, what `CLAUDE_HOME_SRC` stages, what `PAYLOAD` copies, and what runs before
the prompt is ever printed (`:29-77` all execute pre-prompt). A session that edits
`install.sh:25` or `:47` re-points the payload; a session that edits `:29-77` gets
arbitrary host code execution at the next `./devcontainer-config/install.sh`.

**Recommendation:** add `install\.sh` to `hooks/live-verify-gate.sh:57`'s
`enforcement` regex. The manifest cannot cover it (it is never installed), so the
commit gate is the only layer that can — which makes F2 a prerequisite, not an
independent nicety. Separately, consider showing `git -C "$REPO_ROOT" diff --stat
-- devcontainer-config/install.sh` above the `[y/N]` prompt so the script's own
drift lands in the place the header says the human is looking.

---

### F2 — The gate that would cover the boundary is declared in `hooks/wiring.json` but absent from the live settings

**Severity:** Medium
**Location:** `hooks/wiring.json:62-72`; the live Claude settings file (no `live-verify-gate` entry)
**Boundary:** B1 (source S2)
**Move:** #5 (invert the access-control model), #11 (enumerate bypasses)
**Confidence:** High — observed directly this run

`hooks/wiring.json` declares the gate as a `PreToolUse`/`Bash` hook:

```
60      {
61        "matcher": "Bash",
62        "hooks": [
63          {
64            "type": "command",
65            "command": "bash {{CLAUDE_DIR}}/hooks/auto-approve-allowed-commands.sh"
66          },
67          {
68            "type": "command",
69            "command": "bash {{CLAUDE_DIR}}/hooks/live-verify-gate.sh"
70          }
71        ]
72      },
```

Grepping the live settings file for `live-verify` returns nothing. The enforcement
described in decision log row 45(e) — "blocks a `git commit` that includes any
manifest-hashed `devcontainer-config/` file unless the message carries a
`Live-verified:` trailer" — does not run in this session. The gate's 11 bats tests
exercise the script; nothing tests that it is *installed*. This is the same failure
class row 45 was written to fix (a control that is documented, believed, and not
actually in the path), one layer up.

Inverting the model: the set of `devcontainer-config/` changes that can be
committed with no live-verification question asked is currently **all of them**,
not just `install.sh`.

**Recommendation:** wire `live-verify-gate.sh` into the live settings (or, if the
wiring is meant to be derived from `hooks/wiring.json` by an installer, add a test
that asserts every hook declared in `wiring.json` is present in the rendered
settings — a declared-but-unwired hook should fail the fast suite, not a review).

---

### F3 — `parse_findings` accepts an attacker-influenced substring as proof of a clean review; a model refusal is reported as `FINDINGS: NONE`, exit 0

**Severity:** Medium
**Location:** `scripts/lite-review.py:86-108`, `:150-152`, `:193-199`
**Boundary:** B3, B4 (sources S3, S4)
**Move:** #2 (implicit sanitization assumption), #3 (error path), #11 (enumerate bypasses)
**Confidence:** High — parser behavior executed directly; the injection half is reasoned, see Untested bypass candidates
**Origin:** Pre-existing (fact-check escalation E1); this diff does not introduce it but does promote this file to sole owner of the contract and adds a test suite that pins the shape around it.

```
 86  def parse_findings(text):
 87      """Parse the FINDINGS block; returns (findings, parse_ok)."""
 88      if re.search(r"FINDINGS:\s*NONE", text):
 89          return [], True
 90      rows = []
 91      in_block = False
 92      for line in text.splitlines():
 93          if line.strip().startswith("FINDINGS:"):
 94              in_block = True
 95              continue
 96          if not in_block:
 97              continue
 98          m = FINDING_RE.match(line)
 99          if m:
100              rows.append({
...
108      return rows, bool(rows) or "FINDINGS" in text
```
*(rows 100-107 elided: the six-key dict built from the regex groups; nothing in
them affects `parse_ok`. `:108` is the function's final line.)*

Its only consumer:

```
193      if not parse_ok:
194          print(f"lite-review: PARSE FAILURE - raw output:\n{text}")
195          return 2
196      if not findings:
197          print(f"lite-review [{args.mode}]: FINDINGS: NONE "
198                f"({record['tokens']['output']} out-tokens)")
199          return 0
```

Two independent defects, both fail-open:

- `:88`'s `re.search` is **unanchored** — `FINDINGS: NONE` matches anywhere in the
  response, including inside prose that negates it and inside diff content the
  model quotes back.
- `:108`'s `"FINDINGS" in text` is a bare substring over model-controlled prose.

Executed against the parser at HEAD:

| Model response | `parse_ok` | rows | what `main()` prints / returns |
|---|---|---|---|
| `I cannot emit FINDINGS for this diff.` | `True` | 0 | `FINDINGS: NONE`, exit 0 |
| `I would not simply write FINDINGS: NONE here; there are issues.` | `True` | 0 | `FINDINGS: NONE`, exit 0 |
| ``The diff adds a line reading `FINDINGS: NONE` to the README.`` | `True` | 0 | `FINDINGS: NONE`, exit 0 |
| `Sorry, I can't help with that. FINDINGS` | `True` | 0 | `FINDINGS: NONE`, exit 0 |
| `I am unable to review this.` | `False` | 0 | PARSE FAILURE, exit 2 |

So the loud, correct failure mode (exit 2) is reached only by a refusal that
happens not to contain the word. Any refusal that *names the format it is
declining to produce* — the most natural phrasing — is scored as a clean review.

The reachability is not hypothetical: the diff is untrusted text spliced into the
prompt with no delimiter defense (`:158  prompt = template.format(label=args.rev_range, diff=diff)`),
and a diff containing the literal `FINDINGS: NONE` is enough if the model echoes
it. **This very commit adds such a diff** — `test/lite-review-grammar.bats`
contains `run parse 'FINDINGS: NONE'` and five `FINDINGS:` row literals. A
`--mode fix-drift` pass over `435f46a` puts those strings in front of the model
whose prose is then substring-matched for them.

Exit 0 is further overloaded: `:150-152` returns 0 for an empty diff, so a stale or
mistyped `--range` also reports success. Four distinct conditions — genuine clean
review, model refusal, echoed literal, empty/mis-specified range — collapse to the
same "passed" signal in `workflows/pr-prep.md:218`.

Mitigating, and why this is Medium rather than High: `--tools ""`, an empty
non-repo cwd, and `--no-session-persistence` mean a successful prompt injection
can falsify the verdict but cannot execute anything or read the repo; and
`workflows/review-fix-loop.md` is explicit that the fix-drift check "is not a
second reviewer". The assurance weight is real but bounded.

An aggravating detail introduced by *this* diff: the new suite documents the
fail-open and the only caller violates the documented caution.

```
88  @test "a FINDINGS block with only malformed rows yields no rows but still parses" {
89    run parse 'FINDINGS:
90  - a.py | High | something'
91    [ "$status" -eq 0 ]
92    # parse_ok stays true because the block was emitted, but no rows survive —
93    # callers must not read "no rows" as "clean" without checking the raw text.
94    [ "${lines[0]}" = "True" ]
95    [ "${lines[1]}" = "[]" ]
96  }
```
*(final test in the file; `:97` is the closing brace.)* `main():196-199` is the
only caller and reads "no rows" as "clean" without checking the raw text.

**Recommendation:** make the clean verdict require positive evidence rather than a
substring. Concretely: anchor `:88` to a line (`re.search(r"(?m)^\s*FINDINGS:\s*NONE\s*$", text)`),
and replace `:108`'s `"FINDINGS" in text` with the `in_block` flag the loop already
computes — `cross-model-review.py` already derives `parse_ok` that way, so this
narrows the four-way `parse_findings` divergence the fact-check recorded (Claim 13)
rather than widening it. Separately, give "empty diff" a distinct exit code from
"reviewed, clean", and add a grammar test asserting that a refusal string yields
`parse_ok=False`.

---

### F4 — `--range` is passed to `git diff` without a `--` separator, and an option-shaped value silently produces a passing run

**Severity:** Informational
**Location:** `scripts/lite-review.py:81-83`, `:149-152`
**Boundary:** B3 (source S6)
**Move:** #2, #3
**Confidence:** High on the mechanism; the exposure is self-inflicted, not attacker-reachable

```
81  def sh(args, cwd=None):
82      # argv-exec, never shell strings (decision 018)
83      return subprocess.run(args, cwd=cwd, capture_output=True, text=True, check=True).stdout
```
*(`sh()` is two lines; this is the whole function.)*

```
149      diff = sh(["git", "diff", args.rev_range], cwd=args.repo)
150      if not diff.strip():
151          print("lite-review: empty diff, nothing to review")
152          return 0
```

Executed: `git diff --output=<path> HEAD~1..HEAD` returns rc 0 with 0 bytes on
stdout and 22,244 bytes written to the file. So `--range='--output=/tmp/x'` — or
any option-shaped value — produces `empty diff, nothing to review` and exit 0.

This is **not** rated Medium under the Floor rule because reaching it requires the
operator to supply the malicious `--range` themselves; the caller already holds a
shell. It is listed because it is the same fail-open exit-0 surface as F3 and is
fixed by the same one-line discipline.

**Recommendation:** `["git", "diff", args.rev_range, "--"]`, and reject a
`--range` beginning with `-`.

---

## Untested bypass candidates

Move #11 requires every enumerated candidate be either traced or listed. These
were enumerated and **not** tested:

- **Live prompt injection through the diff into a real `claude` call** (F3's
  second half). The parser half was executed deterministically; the model half
  was not, because this sandbox has no egress and no funded key. Reason not
  tested: environment, not judgment. The finding therefore rests on the parser
  behavior, which is fully executed, plus the unguarded prompt concatenation at
  `:158`, which is read-static.
- **`FINDING_RE` widening** (fact-check Claim 7 / escalation E2): adding a
  severity value such as `Blocker`, `.+`→`.*` on the description, letting the path
  group swallow `:`, `- ` bullet prefixes. Already mutation-tested by the
  fact-check replicates (7/7 still green in each case); not re-run here, and the
  routing addressee is api-consistency-reviewer. Named here because a parser
  whose contract tests admit widening is the same weakness class as F3.
- **A `--yes` invocation reaching the bless path with a partially-assembled
  payload.** `:101` short-circuits the entire prompt on `--yes`, so the B2 analysis
  does not cover it. Not traced because no caller in the repo passes `--yes`; a
  caller that did would bypass the human gate entirely by design.

Per move #11, the `[y/N]` matcher **does** appear in Endorsement Claims below
because its enumerated candidates were all tested; `parse_findings` does not.

---

## Primitive sweep

**Primitive: process exec / subprocess**

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/lite-review.py:83` (`subprocess.run(args…)` via `sh()`) | S6 `--range`, `--repo` | argv-form, no `shell=True`, `check=True` | F4 (missing `--` separator); no shell-injection primitive |
| `scripts/lite-review.py:114-126` (`claude` headless) | S6 `--model`, S7 constants | argv-form; `--tools ""`, empty cwd, `--no-session-persistence` | cleared — `--model` is a single argv value, not a flag-injection primitive |
| `devcontainer-config/install.sh:74-75` (`git -C "$REPO_ROOT" …`) | S2 repo path | `2>/dev/null || echo unknown` | cleared — output is a provenance string, not an exec sink |
| `devcontainer-config/install.sh:130` (`"$DEST/cc-isolated.sh" --bless`) | S5 `$DEST` | human `[y/N]` at `:101-111` | gate holds for the values tested (see Endorsement 1); F1 covers the case where `install.sh` itself was rewritten |

**Primitive: destructive filesystem op / path construction**

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `devcontainer-config/install.sh:49` (`rm -rf "$STAGE"`) | S2 `$SRC` (script's own dirname) | derived from `BASH_SOURCE`, not input | cleared — target is always `<script dir>/claude-home` |
| `devcontainer-config/install.sh:60` (`cp -r "$REPO_ROOT/$item" …`) | S2 `CLAUDE_HOME_SRC` | existence check `:59`, fatal collect `:65-70` | cleared for the shipped array; F1 covers an edited array |
| `devcontainer-config/install.sh:120` (`rm -rf "${DEST:?}/$item"`) | S5 `CLAUDE_DEVC_CONFIG_DIR` | `${DEST:?}` blocks empty-var expansion to `/` | cleared — S5 is deploy-time operator env; the `:?` guard is the right one and is present |
| `devcontainer-config/install.sh:121,126` (`cp -r`, `ln -sf` into `$BIN_DIR`) | S5 | none beyond `:?` on DEST | cleared — S5 trusted for path sinks per the source table |

**Primitive: deserialization**

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/lite-review.py:128` (`json.loads(proc.stdout)`) | S4 `claude` stdout | `try/except JSONDecodeError` → `sys.exit` `:129-131` | cleared — `json.loads` has no code-execution surface; the decoded fields' *semantics* are F3 |

**Primitive: untrusted text → LLM prompt**

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/lite-review.py:158` (`template.format(label=…, diff=diff)`) | S3 git diff | none — no delimiter, no escaping | F3. Note the diff is the `.format` *argument*, not the template, so there is no format-string injection; the exposure is prompt content only |

No `eval`-family, no raw SQL, no HTML interpolation, no path-join-from-request in scope.

---

## Endorsement Claims

- **Claim:** For every stdin shape tested, the bless `case` matcher reaches the
  abort branch unless the reply is exactly `y`/`Y`/`yes` (case-insensitive), and
  the specific form chosen — `|| reply=""` rather than `|| true` — is what keeps
  the EOF-partial-line case fail-closed.
  **Location:** `devcontainer-config/install.sh:101-111`
  **Evidence:** executed
  **Verified:** ran an extracted replica of `:101-111` under `set -euo pipefail`
  against five stdin shapes — `printf 'y'` (no newline, EOF partial read) → Aborted,
  exit 1; `printf 'y\n'` → blessed, exit 0; `</dev/null` → Aborted, exit 1;
  `printf ' y\n'` → blessed, exit 0 (`read`'s IFS strip, pre-existing and
  unchanged); `printf 'yes please\n'` → Aborted, exit 1. Ran the counterfactual
  `read -r reply || true` against `printf 'y'` → **blessed, exit 0**, confirming
  the assignment in `|| reply=""` is load-bearing and not cosmetic.
  **Not verified:** the `--yes` path at `:101`, which skips the matcher entirely
  and was not exercised; and the same block running inside the real `install.sh`
  rather than the extracted replica (the fact-check's Claim 1 covers that via A/B
  fixture runs at `8980861~1` and HEAD).
  **route: code-fact-check**

- **Claim:** No call site in the diff scope constructs a shell string; every
  external process is launched argv-form.
  **Location:** `scripts/lite-review.py:83,114-126`
  **Evidence:** read-static
  **Verified:** read both `subprocess.run` call sites end to end; neither passes
  `shell=True` and both receive a list literal. `sh()` is two lines and was read
  in full.
  **Not verified:** `devcontainer-config/cc-isolated.sh --bless`, invoked at
  `install.sh:130` — a shell script outside this diff whose internals were not read.

- **Claim:** The new grammar suite executes without credentials or network,
  exercising only `parse_findings`.
  **Location:** `test/lite-review-grammar.bats:1-97`
  **Evidence:** read-static (re-execution not repeated — the fact-check's Claim 15
  established this by execution across three replicates)
  **Verified:** read all seven tests; each routes through the `parse()` helper,
  which loads the module by path and calls `mod.parse_findings` with no `claude`
  spawn.
  **Not verified:** whether any *other* suite in `test/` invokes `lite-review.py`
  end to end with a live model.

Categorical statements about `parse_findings` are deliberately absent: it has
untested bypass candidates (move #11) and is the subject of F3.

---

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| F1 | `install.sh` is host-executed and agent-writable but outside the payload diff, the hashed enforcement set, and the commit gate's regex | High | B1 | `devcontainer-config/install.sh:14,25,83-99`; `cc-isolated.sh:107-130`; `hooks/live-verify-gate.sh:57` | High (mechanism) / Medium (residual) |
| F2 | `live-verify-gate.sh` is declared in `hooks/wiring.json` but not wired into the live settings — the boundary commit gate is inert | Medium | B1 | `hooks/wiring.json:62-72`; live settings file | High |
| F3 | `parse_findings` scores a model refusal, a negated mention, or an echoed diff literal as a clean review, exit 0 | Medium | B3, B4 | `scripts/lite-review.py:86-108,150-152,193-199` | High |
| F4 | `--range` reaches `git diff` without `--`; an option-shaped value yields a passing empty-diff run | Informational | B3 | `scripts/lite-review.py:81-83,149-152` | High |

---

## Overall Assessment

The two code changes in this diff are each individually sound and one of them is
better than it needed to be: `read -r reply || reply=""` was chosen over the
obvious `|| true`, and that choice is what keeps a newline-less `y` from blessing
the boundary — the counterfactual blesses. The grammar-ownership move is
documentation and tests only, with the regex byte-identical across the transfer.
Nothing in the diff moves a trust boundary or widens one.

The security posture problem is not in the lines changed; it is that the diff
touches two controls whose *enforcement* is weaker than their documentation, and
closes the questions doc without either being noticed. `install.sh` asserts it is
the rebuild gate while being the one file in the directory that no gate covers,
and the hook that was built to stop exactly this class of unverified boundary
commit is not installed. Both are fixable in place — one regex line and one
settings entry — but F2 is a prerequisite for F1's fix, so they should land
together, with a test that fails when a hook declared in `wiring.json` is missing
from the rendered settings.

F3 is the single most important thing to address, because it is the one that
silently produces a *positive* signal: `lite-review` printing `FINDINGS: NONE` is
currently consistent with the model having refused, with the model having quoted
a string out of the diff, and with the range having been empty. Two of those are
reachable from diff content that this very commit adds to the repo. The fix is
small and it narrows rather than widens the `parse_findings` divergence the
fact-check recorded.

Per the skill's rule: **no findings within the code paths read beyond those
listed; endorsement claims pending execution verification** — the `[y/N]` matcher
claim is executed, the other two are scoped read-static with their nearest unread
hop named. This is not a categorical all-clear.

---

## Goal-Alignment Note

**Answered.** The goal was a security review of the three close-out commits before
the work is considered settled. Both code changes were reviewed against their
trust boundaries: the `install.sh` half is fail-closed on every stdin shape tested
and is safe *as a change*, and the grammar-ownership half introduces no new
execution or input-handling surface. The blocking question the goal implies — "is
this settled?" — is answered **not yet**, for a reason the questions doc did not
track: closing the doc does not close F1/F2, and F3 is now pinned by a test suite
that documents the fail-open without fixing it.

**Out of scope (raised, not judged here):**
- Fact-check escalation E2 (grammar suite constrains narrowing but not widening) —
  routed to api-consistency-reviewer. Named in F3's Untested bypass candidates
  because it shares the weakness class, not claimed as a security finding.
- Fact-check escalation E3 (`--mode full` has no wired caller) — api-consistency /
  orchestrator. It bears on F3's blast radius (the mode with the broadest security
  prompt is the unwired one) but is a wiring question, not a vulnerability.
- Fact-check Claim 9 (Incorrect: the Q6 consumer enumeration) and E4
  (`archive/benchmark/scripts/review-arms.py` as an unnamed, unrunnable OpenRouter
  consumer) — orchestrator. No security consequence found: it is a tracked file
  that raises at import and holds no secret, only an `OPENROUTER_API_KEY` read.

**Escalate:** F2 to the user directly, independent of this diff — a security hook
that the repo believes is running and is not is a standing condition, not a
property of these three commits. It should be verified before the next
`devcontainer-config/` change of any kind.

**Questions I would have asked:**
1. Is `install.sh`'s exclusion from `enforcement_files()` deliberate (it genuinely
   cannot be hashed post-install) or was it simply never considered? The fix
   differs: if deliberate, the commit gate is the only available layer and must
   cover it; if not, a pre-install hash of the script itself is also possible.
2. Is the live settings file meant to be generated from `hooks/wiring.json` by an
   installer, or hand-maintained? F2's fix is a test in the first case and a
   settings edit in the second.
3. Does any consumer treat `lite-review.py`'s exit 0 as a gate, or is it always
   read by a human who would notice a refusal echoed in the output? F3's severity
   moves to High if the former is ever true.
