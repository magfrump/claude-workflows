# Failure Pattern Library

> Append-only one-line log of root-caused bugs. Append from pr-prep when a fix
> commit ships; grep from research phase to surface relevant prior patterns.
> Read the schema below before writing a new entry or grep'ing for an existing one.

Last verified: 2026-09-17
Relevant paths: workflows/pr-prep.md (write-side: append FP-NNN on fix commits) · workflows/research-plan-implement.md (read-side: grep audit token in research phase)

## When to read this file

- **RPI research phase** greps this file by symptom keyword (e.g., `null`, `timezone`, `n+1`, `race`, `stale`) to surface prior bugs with the same observable signature. A match is a strong prior on the cause — the recorded fix shape is often the first thing to test.
- **Codebase onboarding** can skim this for institutional debugging memory: recurring failure modes, hot spots, and the fix shapes the project keeps reaching for.

## Schema

Each entry is a single markdown list item with this exact form:

    - **FP-NNN** YYYY-MM-DD symptom:<keywords> cause:<category> fix:<category> ref:<diagnosis-doc-or-commit>

Fields are whitespace-delimited. Use hyphens (not spaces) inside field values so that each `key:value` pair is a single grep-friendly token.

| Field | Example | Notes |
|---|---|---|
| `FP-NNN` | `FP-007` | Sequential, zero-padded to 3 digits. Look at the last entry to pick the next number. Stable forever — cite by ID. |
| `YYYY-MM-DD` | `2026-05-13` | Date the pattern was recorded. |
| `symptom:<keywords>` | `symptom:null-from-parseDate-tz-offset` | Hyphenated tokens drawn from the error message and observable behavior. Pick terms a future `grep` would actually try (root tokens like `null`, `timezone`, `n+1`, `race`, `stale`, plus a discriminator). |
| `cause:<category>` | `cause:incomplete-regex` | Reusable root-cause category. See "Cause vocabulary" — prefer reusing an existing category. |
| `fix:<category>` | `fix:extend-regex` | Reusable fix-shape category. See "Fix vocabulary". |
| `ref:<path-or-sha>` | `ref:docs/working/diagnosis-date-parsing.md` | Diagnosis log path or fix commit SHA — where the full reasoning lives. |

## Cause vocabulary (starter set)

Reuse an existing category when it fits. If none fit, add yours to this list in the same commit so the next diagnosis can reuse it.

- `incomplete-regex` — a pattern omits a valid input case (timezone offset, escape chars, unicode, multiline)
- `n+1-query` — one query per parent row instead of a single eager/batched fetch
- `cache-staleness` — cached value not invalidated when the source mutated
- `race-condition` — concurrent access to shared state without serialization
- `null-deref` — value was unexpectedly null/undefined at use site
- `off-by-one` — boundary condition (loop bound, slice index, range comparison)
- `stale-fixture` — test fixture or seed data drifted from current schema
- `wrong-default` — default value applied where an explicit value was expected
- `lost-error` — exception swallowed, return value not checked, error path unobserved
- `config-drift` — environment/feature-flag/config differs between expected and actual contexts

### Backfilled 2026-09-17 — the vocabulary this corpus actually uses

164 entries harvested from the 105 `fix(...)` commits on `main` since this file was
created (2026-05-18). Commits naming several distinct root causes got one entry each.

The categories below are **the** categories — reuse one rather than coining a new
token, because a `cause:` that appears once is a label, not an index. Specificity
belongs in `symptom:`, which is where the grep-able detail lives.

**Cause categories**, by how often this repo has produced them:

| count | `cause:` | what it means |
|---|---|---|
| 25 | `fail-open` | an error path, empty input or missing value was treated as success |
| 17 | `guard-misses-subject` | the check was real but keyed on something the subject did not carry |
| 16 | `vacuous-assertion` | the assertion could not fail — it passed without examining anything |
| 13 | `environment-divergence` | the code assumed a default the target environment does not have |
| 13 | `boundary-too-wide` | a security or isolation boundary admitted more than intended |
| 10 | `ordering` | a step ran before the state it depends on, or after the exit that skips it |
| 9 | `path-resolution` | a path resolved against the wrong base, or to something absent |
| 9 | `unverified-claim` | a number, enumeration or artifact was asserted without being checked |
| 8 | `overbroad-guard` | the check was correct but rejected legitimate input as well |
| 6 | `wrong-denominator` | the measurement selected its own denominator, or scored a degenerate case high |
| 5 | `stale-state` | state survived an operation meant to clear it, or was silently re-initialised |
| 4 | `artifact-lifecycle` | an artifact was destroyed, overwritten or orphaned by its own lifecycle |
| 4 | `exit-code-overloaded` | one exit status meant several different things to its caller |
| 4 | `parser-quote-unaware` | a hand-written scanner walked structure without tracking quotes |
| 4 | `resource-cap-wrong` | a limit bounded the wrong quantity, or was missing entirely |
| 4 | `instruction-drift` | duplicated instructions diverged, or one was read as permission for less |
| 4 | `delimiter-handling` | a delimiter collided, was discarded downstream, or carried two meanings |
| 3 | `encoding` | bytes were treated as characters, or a literal was read in the wrong base |
| 2 | `untrusted-interpolation` | untrusted text reached a shell or command string |
| 1 | `reflection-escape` | a denylist was bypassed by reaching the blocked object indirectly |
| 1 | `null-deref` | a value was unexpectedly null/undefined at its use site |
| 1 | `cache-staleness` | a skip-if-present cache served a previous run’s value |
| 1 | `identity-by-value` | two things were compared by content where provenance was meant |

**Fix shapes:**

| count | `fix:` | what it means |
|---|---|---|
| 25 | `fail-closed` | make the error, empty or unknown case stop the run |
| 18 | `rekey-the-guard` | key the check on the property that actually discriminates |
| 18 | `arm-the-assertion` | anchor, scope or re-idiom the check so weakening the subject fails it |
| 15 | `structural-parse` | parse the structure properly instead of pattern-matching it |
| 14 | `install-the-dependency` | supply the thing the code assumed was already there |
| 12 | `narrow-the-guard` | keep the check, shrink what it rejects |
| 10 | `degrade-gracefully` | fall through to a safe weaker state instead of aborting or escalating |
| 9 | `invalidate-state` | clear or exclude the state that outlived its meaning |
| 8 | `reorder` | move the step to where its precondition holds |
| 8 | `fix-the-path` | anchor or derive the path instead of assuming a base |
| 8 | `fix-the-denominator` | count the set you meant to count |
| 7 | `remove-the-path` | delete the capability rather than guarding it |
| 4 | `verify-the-artifact` | check the artifact against a hash or an enumeration before use |
| 3 | `adjust-the-cap` | bound the quantity that actually grows |
| 3 | `align-the-contract` | make the duplicated statements agree, or collapse them to one |
| 2 | `make-it-loud` | keep the behaviour, print what it did |

**What the distribution says.** Three categories — `fail-open`, `guard-misses-subject`
and `vacuous-assertion` — are 58 of 164 entries, more than a third, and they are the
same failure wearing three hats: *a check that reports success without having
established it*. That is worth knowing before writing the next guard. The single most
repeated concrete shape is a bare `! grep` or an unanchored pattern in a bats test
(`FP-060`, `FP-156`, `FP-168`), which this repo has now fixed at least three times in
three different files.

## Fix vocabulary (starter set)

- `extend-regex` — add missing branches/groups to the pattern
- `remove-eager-load` / `eager-load` — change query planner shape
- `invalidate-cache` — wire cache invalidation to the source mutation
- `serialize-access` — gate concurrent access (mutex, queue, single-writer)
- `null-guard` — handle the missing-value case at the use site
- `upstream-init` — fix where the null came from, not where it crashed
- `fix-boundary` — adjust loop/index/range condition
- `rebuild-fixture` — regenerate fixture to match current schema
- `propagate-error` — stop swallowing the error; surface it to the caller
- `align-config` — sync configuration across environments

## How to grep

```bash
# By symptom keyword (anywhere in the symptom field):
grep -i 'symptom:[^ ]*null' docs/thoughts/failure-patterns.md

# By cause category:
grep 'cause:n+1-query' docs/thoughts/failure-patterns.md

# By fix shape:
grep 'fix:invalidate-cache' docs/thoughts/failure-patterns.md

# By pattern ID:
grep -E '^- \*\*FP-007\*\*' docs/thoughts/failure-patterns.md
```

When citing a matched pattern in a research doc, commit message, or hypothesis, use the form `FP-NNN`. When tagging a hypothesis as derived from a prior pattern, use the source-tag form `[from prior bug FP-NNN]`.

## Patterns

<!-- Append one line per root-caused bug. Newest at the bottom. Do not edit
     past entries except to fix typos in symptom keywords (which would hurt
     future grep recall). -->

- **FP-008** 2026-05-19 symptom:dangling-reference-test-failure-after-removal cause:artifact-lifecycle fix:remove-the-path ref:0386fa0
- **FP-009** 2026-06-23 symptom:sigpipe-exit-141-no-output-jq-sort-head cause:fail-open fix:structural-parse ref:a5a7058
- **FP-010** 2026-06-23 symptom:double-scan-grep-fallback-on-clean-no-match cause:exit-code-overloaded fix:rekey-the-guard ref:8ea4dab
- **FP-011** 2026-06-24 symptom:orphaned-worktree-after-partial-add cause:ordering fix:reorder ref:f177601
- **FP-012** 2026-06-24 symptom:stale-merge-head-poisons-next-merge cause:stale-state fix:degrade-gracefully ref:f177601
- **FP-013** 2026-06-24 symptom:exit-trap-reprocesses-disposed-worktree cause:stale-state fix:invalidate-state ref:f177601
- **FP-014** 2026-06-24 symptom:stale-git-worktrees-entry-breaks-next-add cause:fail-open fix:invalidate-state ref:f177601
- **FP-015** 2026-06-24 symptom:merge-abort-failure-swallowed-wedged-tree cause:fail-open fix:fail-closed ref:e72321b
- **FP-016** 2026-07-09 symptom:test-makes-live-llm-call-network-permission-prompt cause:environment-divergence fix:install-the-dependency ref:4d39475
- **FP-017** 2026-07-13 symptom:nxdomain-allowlist-domain-bricks-firewall-init cause:fail-open fix:degrade-gracefully ref:f3d9c20
- **FP-018** 2026-07-13 symptom:duplicate-ipset-add-aborts-after-flush-before-drop cause:fail-open fix:degrade-gracefully ref:3d0c51a
- **FP-019** 2026-07-13 symptom:poststart-skipped-on-running-container-firewall-unenforced cause:ordering fix:degrade-gracefully ref:3d0c51a
- **FP-020** 2026-07-13 symptom:relative-build-path-resolves-against-workspace-not-config cause:path-resolution fix:fix-the-path ref:e87e0b5
- **FP-021** 2026-07-13 symptom:agent-writable-file-baked-into-image cause:unverified-claim fix:arm-the-assertion ref:e87e0b5
- **FP-022** 2026-07-14 symptom:setlocale-warning-in-output-breaks-exact-assertions cause:environment-divergence fix:install-the-dependency ref:7dfd8d7
- **FP-023** 2026-07-14 symptom:bw02-run-bang-assertion-ambiguous-without-version-floor cause:vacuous-assertion fix:arm-the-assertion ref:7dfd8d7
- **FP-024** 2026-07-14 symptom:lint-gate-green-having-scanned-zero-files cause:vacuous-assertion fix:arm-the-assertion ref:93f9ca3
- **FP-025** 2026-07-14 symptom:shell-param-expansion-hash-read-as-comment-blanks-line cause:parser-quote-unaware fix:structural-parse ref:695a31c
- **FP-026** 2026-07-14 symptom:brace-in-string-closes-function-body-early cause:parser-quote-unaware fix:structural-parse ref:695a31c
- **FP-027** 2026-07-14 symptom:paren-in-string-closes-command-substitution-early cause:parser-quote-unaware fix:structural-parse ref:7467997
- **FP-028** 2026-07-14 symptom:release-tarball-extracted-without-checksum cause:unverified-claim fix:verify-the-artifact ref:becf2ac
- **FP-029** 2026-07-14 symptom:dead-markdown-link-to-unmerged-branch-file cause:path-resolution fix:fix-the-path ref:9a749bd
- **FP-030** 2026-07-14 symptom:help-output-splices-shebang-and-internal-comments cause:overbroad-guard fix:narrow-the-guard ref:1460d29
- **FP-031** 2026-07-14 symptom:sdk-download-unverified-on-a-false-premise cause:unverified-claim fix:verify-the-artifact ref:a249cfe
- **FP-032** 2026-07-21 symptom:shell-injection-via-single-quote-in-interpolated-expr cause:untrusted-interpolation fix:structural-parse ref:8ef9d52
- **FP-033** 2026-07-21 symptom:substring-denylist-misses-pathlib-pickle-getattr cause:guard-misses-subject fix:structural-parse ref:8ef9d52
- **FP-034** 2026-07-21 symptom:fixed-tmp-path-symlink-toctou cause:path-resolution fix:fix-the-path ref:8ef9d52
- **FP-035** 2026-07-21 symptom:attribute-form-eval-slips-bare-name-block cause:guard-misses-subject fix:rekey-the-guard ref:62beca1
- **FP-036** 2026-07-21 symptom:open-with-variable-mode-treated-as-unknown-and-allowed cause:fail-open fix:fail-closed ref:62beca1
- **FP-037** 2026-07-21 symptom:nested-power-dos-passes-per-op-exponent-cap cause:guard-misses-subject fix:rekey-the-guard ref:62beca1
- **FP-038** 2026-07-21 symptom:legit-json-load-df-rename-rejected-by-name-only-match cause:guard-misses-subject fix:narrow-the-guard ref:62beca1
- **FP-039** 2026-07-21 symptom:missing-helper-swallowed-tempts-hallucinated-fallback cause:fail-open fix:fail-closed ref:62beca1
- **FP-040** 2026-07-21 symptom:ulimit-v-2gb-breaks-blas-virtual-arenas cause:resource-cap-wrong fix:adjust-the-cap ref:62beca1
- **FP-041** 2026-07-21 symptom:operator-attrgetter-reflection-rce cause:reflection-escape fix:remove-the-path ref:b7e4595
- **FP-042** 2026-07-21 symptom:allow-pickle-is-true-check-slips-integer-one cause:guard-misses-subject fix:fail-closed ref:b7e4595
- **FP-043** 2026-07-21 symptom:pathlib-rename-replace-hardlink-write-escape cause:boundary-too-wide fix:remove-the-path ref:b7e4595
- **FP-044** 2026-07-21 symptom:fallback-tier-ran-with-network-intact cause:boundary-too-wide fix:install-the-dependency ref:b7e4595
- **FP-045** 2026-07-21 symptom:setup-gate-checked-only-one-of-three-helpers cause:guard-misses-subject fix:install-the-dependency ref:b7e4595
- **FP-046** 2026-07-21 symptom:shell-state-not-persistent-across-bash-calls cause:environment-divergence fix:install-the-dependency ref:503ebc9
- **FP-047** 2026-07-21 symptom:poisoned-helper-persists-to-later-unsandboxed-run cause:artifact-lifecycle fix:invalidate-state ref:503ebc9
- **FP-048** 2026-07-21 symptom:positional-np-load-allow-pickle-rce cause:guard-misses-subject fix:rekey-the-guard ref:503ebc9
- **FP-049** 2026-07-21 symptom:tmpfs-mount-order-shadows-bind-hiding-script cause:ordering fix:reorder ref:0c02887
- **FP-050** 2026-07-21 symptom:unshare-tier-shares-host-mount-namespace-host-writes cause:boundary-too-wide fix:install-the-dependency ref:0c02887
- **FP-051** 2026-07-21 symptom:url-literal-check-rejects-urls-used-as-data cause:overbroad-guard fix:narrow-the-guard ref:0c02887
- **FP-052** 2026-07-21 symptom:confine-blocks-all-writes-crashing-matplotlib-font-cache cause:overbroad-guard fix:narrow-the-guard ref:0c02887
- **FP-053** 2026-07-21 symptom:inf-nan-accepted-as-verified-answer cause:resource-cap-wrong fix:adjust-the-cap ref:74d626e
- **FP-054** 2026-07-21 symptom:recursionerror-bare-traceback-on-long-flat-sum cause:resource-cap-wrong fix:adjust-the-cap ref:74d626e
- **FP-055** 2026-07-21 symptom:blanket-dunder-block-rejects-np-version-and-len cause:overbroad-guard fix:narrow-the-guard ref:74d626e
- **FP-056** 2026-07-21 symptom:sys-in-allowlist-reopens-rce-via-sys-modules-reflection cause:boundary-too-wide fix:remove-the-path ref:31e2d3a
- **FP-057** 2026-07-21 symptom:fallback-tier-blocks-writes-but-not-reads-disclosure cause:boundary-too-wide fix:fail-closed ref:08563f1
- **FP-058** 2026-07-21 symptom:bwrap-runtime-failure-drops-the-computation-silently cause:fail-open fix:degrade-gracefully ref:08563f1
- **FP-059** 2026-07-21 symptom:ast-evaluator-rejects-thousands-separators cause:resource-cap-wrong fix:structural-parse ref:08563f1
- **FP-060** 2026-07-21 symptom:bare-word-grep-system-satisfied-by-filesystem cause:vacuous-assertion fix:arm-the-assertion ref:08563f1
- **FP-061** 2026-07-22 symptom:hardcoded-home-paths-break-after-sandbox-move cause:path-resolution fix:fix-the-path ref:0a4e42d
- **FP-062** 2026-07-22 symptom:relative-env-override-resolves-worktree-base-against-wrong-dir cause:path-resolution fix:fix-the-path ref:45bea51
- **FP-063** 2026-07-22 symptom:preset-non-writable-tmpdir-aborts-first-mktemp cause:environment-divergence fix:rekey-the-guard ref:45bea51
- **FP-064** 2026-07-29 symptom:rubric-overwritten-each-run-destroys-prior-findings cause:artifact-lifecycle fix:invalidate-state ref:5aed5d6
- **FP-065** 2026-07-29 symptom:hardcoded-artifact-path-makes-suite-skip-not-fail cause:fail-open fix:arm-the-assertion ref:5aed5d6
- **FP-066** 2026-07-29 symptom:repo-skills-never-registered-in-any-container-session cause:environment-divergence fix:install-the-dependency ref:2112dcb
- **FP-067** 2026-07-29 symptom:builtin-name-collision-disguises-missing-skill cause:environment-divergence fix:verify-the-artifact ref:2112dcb
- **FP-068** 2026-07-30 symptom:gate-artifacts-generated-then-deleted-with-worktree cause:artifact-lifecycle fix:reorder ref:6b7b2eb
- **FP-069** 2026-07-30 symptom:unnonced-sentinel-spoofable-last-match-wins cause:boundary-too-wide fix:rekey-the-guard ref:6b7b2eb
- **FP-070** 2026-07-30 symptom:gate-failed-open-missing-sentinel-recorded-skip cause:fail-open fix:fail-closed ref:6b7b2eb
- **FP-071** 2026-07-30 symptom:ledger-write-has-no-owner-at-the-moment-it-is-possible cause:ordering fix:reorder ref:00d3401
- **FP-072** 2026-07-30 symptom:hook-wired-everywhere-scanned-nothing-missing-scanner-path cause:path-resolution fix:fix-the-path ref:03668e4
- **FP-073** 2026-07-30 symptom:guard-defers-to-deny-rules-that-were-never-wired cause:instruction-drift fix:install-the-dependency ref:03668e4
- **FP-074** 2026-07-30 symptom:null-content-parsed-as-clean-findings-none cause:null-deref fix:rekey-the-guard ref:d9b3464
- **FP-075** 2026-07-30 symptom:headless-session-denied-write-every-persist-instruction-inert cause:environment-divergence fix:install-the-dependency ref:96166d5
- **FP-076** 2026-07-30 symptom:headless-read-confined-to-cwd-critic-briefs-blocked cause:environment-divergence fix:install-the-dependency ref:96166d5
- **FP-077** 2026-07-30 symptom:jaccard-exceeds-one-from-many-to-one-matching cause:wrong-denominator fix:fix-the-denominator ref:7bfd5a6
- **FP-078** 2026-07-30 symptom:empty-vs-empty-scores-perfect-agreement-hiding-abstention cause:wrong-denominator fix:fix-the-denominator ref:7bfd5a6
- **FP-079** 2026-07-30 symptom:unguarded-grep-pipeline-aborts-harvest-after-merges cause:fail-open fix:fail-closed ref:365585e
- **FP-080** 2026-07-30 symptom:heredoc-delimiter-collision-executes-following-lines cause:delimiter-handling fix:structural-parse ref:b840f3b
- **FP-081** 2026-07-30 symptom:connectionless-udp-egress-unblocked-by-socket-patch cause:guard-misses-subject fix:rekey-the-guard ref:b840f3b
- **FP-082** 2026-07-30 symptom:literal-adjacency-grep-broken-by-inserted-argument cause:vacuous-assertion fix:arm-the-assertion ref:9c80aae
- **FP-083** 2026-07-30 symptom:stale-replicate-matched-by-bare-glob cause:vacuous-assertion fix:arm-the-assertion ref:7fdf28a
- **FP-084** 2026-07-30 symptom:soundness-trigger-fires-on-convention-contradictions cause:overbroad-guard fix:rekey-the-guard ref:b42b7b6
- **FP-085** 2026-07-31 symptom:k3-uniformity-clause-read-as-license-for-lean-briefs cause:instruction-drift fix:align-the-contract ref:8f49ed6
- **FP-086** 2026-07-31 symptom:binary-file-crashes-stage-1-unicodedecodeerror cause:encoding fix:structural-parse ref:8de9917
- **FP-087** 2026-07-31 symptom:cost-guard-failed-open-on-unpriced-model cause:guard-misses-subject fix:fail-closed ref:8de9917
- **FP-088** 2026-07-31 symptom:unanimity-overstated-across-families-and-replicates cause:unverified-claim fix:fix-the-denominator ref:bcccdc2
- **FP-089** 2026-07-31 symptom:count-claims-drift-across-four-citing-documents cause:unverified-claim fix:arm-the-assertion ref:0d205f3
- **FP-090** 2026-08-06 symptom:repo-without-main-crashes-each-arm-with-git-traceback cause:guard-misses-subject fix:fail-closed ref:162d74f
- **FP-091** 2026-08-06 symptom:stale-pricing-note-inverts-cheap-arm-premise cause:unverified-claim fix:fail-closed ref:440df8a
- **FP-092** 2026-08-06 symptom:public-endpoint-accepts-any-auth-header-invalid-key-passes-guard cause:guard-misses-subject fix:fail-closed ref:48a1fd1
- **FP-093** 2026-08-07 symptom:three-instruction-surfaces-contradict-the-conditional-rule cause:instruction-drift fix:align-the-contract ref:49de1ec
- **FP-094** 2026-08-14 symptom:auth-guard-fails-on-acp-mode-with-zero-stored-credentials cause:guard-misses-subject fix:degrade-gracefully ref:81b7cb0
- **FP-095** 2026-08-14 symptom:review-tool-exits-nonzero-on-findings-read-as-failure cause:exit-code-overloaded fix:rekey-the-guard ref:5c28be0
- **FP-096** 2026-08-14 symptom:bad-credential-exits-zero-banking-empty-results-as-complete cause:fail-open fix:fail-closed ref:df46486
- **FP-097** 2026-08-14 symptom:bare-headless-mode-ignores-oauth-token cause:environment-divergence fix:install-the-dependency ref:765fa6b
- **FP-098** 2026-08-14 symptom:named-volume-root-owned-container-uid-1000-eacces cause:environment-divergence fix:install-the-dependency ref:8695284
- **FP-099** 2026-08-14 symptom:free-tier-consumed-makes-billed-cost-zero-and-untrackable cause:wrong-denominator fix:fix-the-denominator ref:2900ce1
- **FP-100** 2026-08-18 symptom:preflight-tests-log-in-but-not-logged-in cause:guard-misses-subject fix:rekey-the-guard ref:ed68ced
- **FP-101** 2026-08-18 symptom:nul-delimiter-thrown-away-by-tr-cut-path-traversal cause:delimiter-handling fix:structural-parse ref:a04ef57
- **FP-102** 2026-08-18 symptom:resume-predicate-banks-errored-cell-or-repays-successful-one cause:guard-misses-subject fix:rekey-the-guard ref:a04ef57
- **FP-103** 2026-08-18 symptom:containment-failure-echoed-then-cell-banked-as-complete cause:fail-open fix:fail-closed ref:a04ef57
- **FP-104** 2026-08-18 symptom:unanchored-endpoint-glob-accepts-lookalike-host cause:vacuous-assertion fix:arm-the-assertion ref:a04ef57
- **FP-105** 2026-08-18 symptom:unquoted-interpolation-reaches-a-chmod-0755-file cause:untrusted-interpolation fix:structural-parse ref:a04ef57
- **FP-106** 2026-08-18 symptom:verify-passes-trivially-for-slug-absent-from-manifest cause:vacuous-assertion fix:arm-the-assertion ref:a04ef57
- **FP-107** 2026-08-18 symptom:grep-c-prints-zero-and-exits-one-yielding-doubled-token cause:exit-code-overloaded fix:fail-closed ref:59733d8
- **FP-108** 2026-08-18 symptom:provenance-record-sums-results-not-the-attempt-ledger cause:wrong-denominator fix:fix-the-denominator ref:59733d8
- **FP-109** 2026-08-18 symptom:git-checkout-restores-from-index-so-commits-survive-reset cause:stale-state fix:invalidate-state ref:cf6e7c9
- **FP-110** 2026-08-18 symptom:failed-cells-remove-themselves-from-the-denominator cause:wrong-denominator fix:fix-the-denominator ref:cf6e7c9
- **FP-111** 2026-08-18 symptom:provenance-write-after-loop-skipped-by-in-loop-exit cause:ordering fix:reorder ref:cf6e7c9
- **FP-112** 2026-08-18 symptom:completion-predicate-rejects-genuine-review-of-auth-code cause:vacuous-assertion fix:rekey-the-guard ref:cf6e7c9
- **FP-113** 2026-08-18 symptom:every-existing-clone-fails-the-new-pre-run-gate cause:overbroad-guard fix:degrade-gracefully ref:e159618
- **FP-114** 2026-08-18 symptom:attrition-denominator-is-the-set-that-produced-output cause:wrong-denominator fix:fix-the-denominator ref:e159618
- **FP-115** 2026-08-18 symptom:git-clean-qfdx-silently-skips-nested-repositories cause:environment-divergence fix:install-the-dependency ref:e159618
- **FP-116** 2026-08-19 symptom:host-git-runs-against-a-container-written-directory cause:boundary-too-wide fix:remove-the-path ref:1d8ea67
- **FP-117** 2026-08-19 symptom:three-state-exit-collapsed-unchecked-published-as-detected cause:exit-code-overloaded fix:fail-closed ref:1d8ea67
- **FP-118** 2026-08-19 symptom:exit-5-dead-code-pipeline-status-kills-shell-under-errexit cause:fail-open fix:fail-closed ref:4624c5d
- **FP-119** 2026-08-19 symptom:dropping-internal-flag-left-the-whole-suite-green cause:vacuous-assertion fix:arm-the-assertion ref:4624c5d
- **FP-120** 2026-08-19 symptom:empty-observation-judged-ok-dead-proxy-passes-preflight cause:fail-open fix:fail-closed ref:f91c4c3
- **FP-121** 2026-08-19 symptom:internal-false-passes-the-internal-glob cause:vacuous-assertion fix:arm-the-assertion ref:f91c4c3
- **FP-122** 2026-08-19 symptom:curl-w-prints-status-on-failure-too-yielding-000000 cause:delimiter-handling fix:fail-closed ref:28e5954
- **FP-123** 2026-08-20 symptom:dependabot-race-makes-refs-pull-1-head-the-wrong-diff cause:path-resolution fix:fix-the-path ref:9da4f61
- **FP-124** 2026-08-20 symptom:background-wait-ceiling-truncates-cell-while-result-says-success cause:environment-divergence fix:install-the-dependency ref:9ae6694
- **FP-125** 2026-08-20 symptom:skip-if-present-judge-state-reports-previous-review-score cause:cache-staleness fix:invalidate-state ref:a72e82c
- **FP-126** 2026-08-21 symptom:tests-silently-counting-zero-findings-still-passing cause:instruction-drift fix:align-the-contract ref:848c5d8
- **FP-127** 2026-08-21 symptom:lint-gate-fails-on-vendored-and-archived-third-party-code cause:overbroad-guard fix:narrow-the-guard ref:848c5d8
- **FP-128** 2026-08-29 symptom:blanket-dport-22-accept-is-an-unconditional-tunnel cause:boundary-too-wide fix:remove-the-path ref:c44c33a
- **FP-129** 2026-08-29 symptom:fail-open-else-unreachable-grep-exit-1-under-pipefail cause:fail-open fix:fail-closed ref:6edaa21
- **FP-130** 2026-08-29 symptom:fail-open-branch-re-grants-the-channel-it-removes cause:fail-open fix:narrow-the-guard ref:6edaa21
- **FP-131** 2026-08-29 symptom:ipv4-regex-validates-shape-not-range-999-999-999-999-passes cause:guard-misses-subject fix:rekey-the-guard ref:6edaa21
- **FP-132** 2026-08-29 symptom:fallback-inert-in-every-reachable-case cause:fail-open fix:fail-closed ref:5ec95c5
- **FP-133** 2026-08-29 symptom:bootstrap-window-empty-chains-and-accept-policy-unbounded cause:ordering fix:reorder ref:5ec95c5
- **FP-134** 2026-08-29 symptom:exit-trap-status-guard-no-ops-when-shell-is-signalled cause:ordering fix:rekey-the-guard ref:5ec95c5
- **FP-135** 2026-08-29 symptom:trap-made-transient-failure-permanently-unrecoverable cause:fail-open fix:degrade-gracefully ref:5ec95c5
- **FP-136** 2026-08-29 symptom:hand-written-artifact-overwrites-schema-conforming-one cause:fail-open fix:invalidate-state ref:891a864
- **FP-137** 2026-08-29 symptom:branch-reported-green-suites-run-did-not-include-the-gate cause:vacuous-assertion fix:arm-the-assertion ref:891a864
- **FP-138** 2026-08-29 symptom:rename-makes-filename-contradict-contents cause:unverified-claim fix:invalidate-state ref:4dd5c85
- **FP-139** 2026-09-03 symptom:base-egress-carried-telemetry-hosts-nobody-opted-into cause:boundary-too-wide fix:narrow-the-guard ref:b04090c
- **FP-140** 2026-09-03 symptom:egress-allowlist-not-port-scoped-bridge-24-too-wide cause:boundary-too-wide fix:narrow-the-guard ref:f1443c5
- **FP-141** 2026-09-03 symptom:daemons-inherit-firewall-lock-fd-blocking-every-later-run cause:ordering fix:reorder ref:2839e59
- **FP-142** 2026-09-03 symptom:share-dir-chowned-to-node-agent-can-replace-egress-profile cause:boundary-too-wide fix:narrow-the-guard ref:6eaa9a0
- **FP-143** 2026-09-03 symptom:single-label-entry-becomes-a-tld-forwarding-zone cause:boundary-too-wide fix:rekey-the-guard ref:6eaa9a0
- **FP-144** 2026-09-03 symptom:iptables-c-assertion-string-form-does-not-split-under-ifs cause:parser-quote-unaware fix:structural-parse ref:563448a
- **FP-145** 2026-09-03 symptom:enforcement-walk-dies-on-empty-projects-dir-fresh-install cause:fail-open fix:degrade-gracefully ref:294a6c2
- **FP-146** 2026-09-03 symptom:symlink-hashed-by-target-only-rewritten-content-invisible cause:unverified-claim fix:verify-the-artifact ref:98734ba
- **FP-147** 2026-09-03 symptom:exit-status-read-through-process-substitution-is-lost cause:fail-open fix:fail-closed ref:98734ba
- **FP-148** 2026-09-03 symptom:timed-out-lock-waiter-forces-drop-over-holders-boundary cause:boundary-too-wide fix:degrade-gracefully ref:294a6c2
- **FP-149** 2026-09-09 symptom:o-lo-never-matches-dnat-steered-packet-no-dns-no-https cause:ordering fix:narrow-the-guard ref:f906b50
- **FP-150** 2026-09-09 symptom:probe-ran-with-the-table-it-was-restructuring-flushed cause:ordering fix:reorder ref:f906b50
- **FP-151** 2026-09-12 symptom:path-keyed-guard-silently-disarmed-by-a-file-move cause:guard-misses-subject fix:rekey-the-guard ref:a9f49bf
- **FP-152** 2026-09-12 symptom:sed-range-runs-past-file-into-concatenated-siblings-heading cause:vacuous-assertion fix:arm-the-assertion ref:a9f49bf
- **FP-153** 2026-09-12 symptom:counts-written-from-recollection-not-command-output cause:unverified-claim fix:fix-the-denominator ref:a9f49bf
- **FP-154** 2026-09-12 symptom:missing-entry-point-file-continues-and-still-prints-a-pass cause:fail-open fix:fail-closed ref:3255f9b
- **FP-155** 2026-09-12 symptom:four-document-link-cycle-between-stub-and-spec cause:path-resolution fix:fix-the-path ref:3255f9b
- **FP-156** 2026-09-12 symptom:bare-substring-assertion-stays-green-across-the-move-it-covers cause:vacuous-assertion fix:arm-the-assertion ref:3255f9b
- **FP-157** 2026-09-12 symptom:pinned-value-bypasses-the-fail-closed-cost-guard cause:guard-misses-subject fix:fail-closed ref:cb5351d
- **FP-158** 2026-09-12 symptom:missing-payload-source-warns-and-continues-silent-and-total cause:fail-open fix:fail-closed ref:cb8bcb2
- **FP-159** 2026-09-12 symptom:read-at-eof-under-errexit-kills-script-before-abort-message cause:fail-open fix:fail-closed ref:8980861
- **FP-160** 2026-09-12 symptom:enumeration-named-a-non-consumer-and-omitted-a-real-one cause:vacuous-assertion fix:arm-the-assertion ref:b99e23f
- **FP-161** 2026-09-12 symptom:wiring-merge-by-deep-equality-leaves-stale-group-beside-new cause:identity-by-value fix:rekey-the-guard ref:95f5a86
- **FP-162** 2026-09-12 symptom:marker-dir-0700-root-probe-can-never-observe-a-pass cause:overbroad-guard fix:narrow-the-guard ref:6c35e39
- **FP-163** 2026-09-12 symptom:all-tests-relocate-the-subject-so-real-default-is-untested cause:vacuous-assertion fix:arm-the-assertion ref:6c35e39
- **FP-164** 2026-09-15 symptom:profile-grant-overwritten-silently-dropping-a-profile cause:stale-state fix:make-it-loud ref:c1e5abd
- **FP-165** 2026-09-15 symptom:printed-rebuild-command-loses-localenv-vars-bakes-empty-profile cause:environment-divergence fix:make-it-loud ref:c1e5abd
- **FP-166** 2026-09-17 symptom:archive-sweep-removes-cross-run-memory-that-reinits-empty cause:stale-state fix:invalidate-state ref:84350f0
- **FP-167** 2026-09-17 symptom:tracked-symlink-to-absolute-host-path-is-dangling cause:path-resolution fix:remove-the-path ref:d317721
- **FP-168** 2026-09-17 symptom:bare-bang-grep-cannot-fail-a-bats-test-vacuous-assertion cause:vacuous-assertion fix:arm-the-assertion ref:da4811b
- **FP-169** 2026-09-17 symptom:prose-appended-to-a-parsed-date-field-makes-it-unparseable cause:delimiter-handling fix:structural-parse ref:9896a5e
- **FP-170** 2026-09-17 symptom:truncation-splits-multibyte-char-grep-reports-file-as-binary cause:encoding fix:structural-parse ref:e96912d
- **FP-171** 2026-09-17 symptom:zero-padded-id-read-as-octal-hands-out-a-used-id cause:encoding fix:structural-parse ref:e96912d
