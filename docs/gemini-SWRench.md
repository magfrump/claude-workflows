# Specification: SWR-Bench Multi-Dimensional Judge & Audit System (v2.0)

## 1. Overview & Context

SWR-Bench evaluates Automated Code Review (ACR) tools against historical Pull Request (PR) data. In its original design, predicted review points are semantically matched (by an LLM judge) against ground-truth changes derived from historical human review comments; any finding that fails to match is counted as a **False Positive (FP)**, regardless of whether it is correct. (The original judge does grade the inherent severity of each potential FP on a 1–10 scale, but that grade does not change the FP classification.)

Spot-checking generated reviews suggests that this binary per-point matching decision penalizes findings that appear valid — such as correct non-blocking suggestions, out-of-scope codebase improvements, or plausible unmentioned bugs. On ground-truth-clean PRs, *every* predicted finding scores as FP by construction. Whether these unmatched findings are in fact high-quality is an open empirical question; measuring it is one of the purposes of this update, not an assumption behind it.

This specification defines **v2.0 of the SWR-Bench Evaluation Judge**. The update supplements the binary per-point matching decision with a **multi-dimensional utility model**. It incorporates static context verification, legacy-safe handling for historical Python repositories, and human-auditability artifact generation.

**Metric coexistence (normative):** The Weighted Utility Score defined below is reported *alongside* the original PR-level and point-level precision/recall/F1 metrics, never in place of them. The legacy metrics remain the comparability anchor against published results and pinned-judge baselines; WUS is an analysis layer over the same judge output.

---

## 2. Taxonomy & Utility Scoring Model

Every finding predicted by an ACR tool is evaluated across four logical axes: **Accuracy**, **Scope**, **Ground-Truth Attestation**, and **Severity**.

### 2.1 Category Definitions

| Category ID | Category Name | Description |
| :--- | :--- | :--- |
| **`TP`** | **True Positive** | Factually correct, strictly within the PR diff scope, and matches a historical human review comment — at any severity. A finding the human reviewer actually raised is never penalized for being low-severity. |
| **`VU`** | **Valid Unattested** | Factually correct, strictly within the PR diff scope, blocking/functional in severity, but was missed or silently resolved by human reviewers. |
| **`OOS`** | **Out of Scope** | Factually correct finding located in surrounding files or legacy code adjacent to the PR diff, but not introduced or modified by the PR itself. |
| **`NB`** | **Non-Blocking** | Factually correct, within PR scope, and unattested, but low-severity (e.g., formatting, variable naming, minor refactoring, lint/type-checker duplicate). |
| **`FP`** | **False Positive** | Factually incorrect claim, non-existent bug, incorrect logic, or suggestion that introduces syntax/runtime errors. |

### 2.2 Weighted Utility Score (WUS)

In addition to the traditional precision/recall/F1 scores (which are always reported), models receive a **Weighted Utility Score (WUS)**:

$$\text{WUS} = \frac{\sum_{i \in \text{Categories}} w_i \cdot N_i}{N_{\text{total\_predictions}}}$$

Where the category weights ($w_i$) are defined as:

$$\begin{aligned}
w_{\text{TP}} &= +1.0 \\
w_{\text{VU}} &= +0.8 \\
w_{\text{OOS}} &= 0.0 \quad \text{(Informational / Neutral)} \\
w_{\text{NB}} &= -0.1 \quad \text{(Mild Noise)} \\
w_{\text{FP}} &= -1.0 \quad \text{(High Developer Friction)}
\end{aligned}$$

**Weights are provisional.** The values above are starting points, not validated constants. Before WUS is used to compare tools, the weights and the judge's category assignments MUST be calibrated against a human-adjudicated sample (see §7, criterion 3).

**WUS measures precision-side utility only.** The denominator counts predictions made, so missed ground-truth issues do not lower WUS — a tool that emits a single confident finding per PR can score near 1.0 while missing everything else. WUS therefore MUST NOT be used as a standalone ranking metric: coverage is measured by the legacy recall/F1 metrics, and any reported WUS figure must appear next to the same run's recall. (A composite that couples the two is possible future work; this spec deliberately does not define one.)

---

## 3. Sequential Judge Decision Flow

The judge follows a sequential decision procedure rather than a free-form zero-shot classification. In the reference implementation, this is enforced **within a single structured-output call**: the response schema's fields are ordered (fact → scope → attestation → severity) and the model is instructed to fill them in order, short-circuiting to a terminal category as soon as a gate fails. Implementations MAY split the stages into separate calls for stronger isolation; the normative requirements are the stage *ordering* and the short-circuit routing, not the call topology.

Ground-truth attestation is checked **before** severity. This ordering is deliberate: a finding the human reviewer actually raised is the benchmark's gold standard and is classified TP regardless of severity, so low-severity human-attested findings are never routed to the penalized NB bucket. Severity discriminates only among *unattested* findings (VU vs. NB) — which also concentrates the judge's least-validated faculty (severity assessment) on the narrowest decision.

```
        ┌─────────────────────────────────┐
        │ Predicted Finding + Code Context│
        └───────────────┬─────────────────┘
                        ▼
        ┌─────────────────────────────────┐
        │   Stage 1: Fact Verification    │
        │  Is the claim factually true in │
        │   the provided code context?    │
        └────────┬───────────────┬────────┘
             Yes │            No │
                 ▼               ▼
        ┌──────────────────┐  ┌──────┐
        │ Stage 2: Scope   │  │ [FP] │
        │ Inside the       │  └──────┘
        │ PR diff hunk?    │
        └────┬─────────┬───┘
         Yes │      No │
             ▼         ▼
   ┌──────────────────┐  ┌───────┐
   │ Stage 3: GT      │  │ [OOS] │
   │ Attestation      │  └───────┘
   │ Matches a human  │
   │ review comment?  │
   └────┬─────────┬───┘
    Yes │      No │
        ▼         ▼
    ┌──────┐  ┌──────────────────┐
    │ [TP] │  │ Stage 4:         │
    └──────┘  │ Severity Check   │
              │ Blocking bug or  │
              │ functional error?│
              └────┬─────────┬───┘
               Yes │      No │
                   ▼         ▼
               ┌──────┐  ┌──────┐
               │ [VU] │  │ [NB] │
               └──────┘  └──────┘
```

---

## 4. Static Context & Legacy Handling Protocol

To eliminate security risks and build environment friction associated with running dynamic tests on historical codebases (the dataset includes 64 PRs from 2011–2012, whose repositories carry Python 2.6/2.7-era dependencies):

1. **No Dynamic Execution:** The judge pipeline **must not** attempt to invoke runtime execution (`pytest`, `python exec`, or sandbox containers) on historical repository code.
2. **Quotation & Line Verification (universal baseline):** For every finding, the judge prompt forces the model to output exact code quotes and line numbers verifying that the targeted symbol or condition actually exists in the file before evaluating correctness. This textual check applies to all files regardless of Python version and is the minimum verification bar.
3. **Static Parse Enrichment (best-effort):** Where the target file parses under a modern Python 3 grammar, the judge environment MAY additionally extract structured context (variable declarations, import paths, enclosing function/class) using Python 3 parsers such as the standard-library `ast` module or `libCST`. These parsers cover Python 3 syntax only — they cannot parse Python 2-specific constructs (e.g., `print` statements, `except X, e:`). For files that fail to parse, the judge falls back to the textual verification of item 2 and the evaluation record is flagged with `parse_fallback: true` so audit reports show which classifications lacked AST-backed context.

No tool in this protocol is assumed to parse Python 2 source; legacy-era files are handled by the textual baseline, never silently skipped.

---

## 5. Judge Prompt Specification

The judge model MUST be prompted using the following structured system and user templates.

> **Template syntax note:** `{snake_case}` tokens in the user template are substitution
> placeholders filled by the harness. All other braces — in particular the JSON example under
> *Output Instructions* — are literal text and MUST NOT be treated as placeholders by the
> template renderer (escape them, or render the JSON block verbatim outside the substitution
> pass).

### 5.1 System Prompt

```text
You are an expert, objective code review evaluator for software benchmarks. Your task is to evaluate a predicted review comment generated by an Automated Code Review (ACR) tool against a Pull Request (PR) diff and historical human reviewer context.

Follow this sequential evaluation logic strictly:
1. Fact Check: Verify whether the finding's technical claim is factually correct given the provided codebase context. Quote the exact code you relied on. If false, classify as FP immediately.
2. Scope Check: Determine if the finding targets code modified within the PR diff. If it targets surrounding or untouched code, classify as OOS.
3. Ground Truth Check: Check if the finding corresponds to an issue raised by a human reviewer in the PR ground truth comments (semantic match, not literal wording). If yes, classify as TP regardless of severity.
4. Severity Check: For findings not matched to a human comment, determine if the finding is a blocking functional/security bug versus a low-severity/non-blocking style note or linting issue. Blocking -> VU, non-blocking -> NB.

Do not penalize valid code findings simply because historical reviewers omitted them. Provide detailed reasoning for each decision step.
```

### 5.2 User Prompt Template

```text
### Inputs
**Repository Context:** {repo_name}
**PR File Path:** {file_path}
**PR Diff Hunk:**
```diff
{diff_hunk}

```

**Full File Context Snippet:**

```python
{file_context}

```

**Historical Human Review Comments (Ground Truth):**
{ground_truth_comments}

**Predicted Finding to Evaluate:**
"{predicted_comment}"

---

### Output Instructions

Respond in valid JSON using the following structure:

```json
{
  "fact_check": {
    "is_correct": true | false,
    "evidence_quote": "string from code",
    "parse_fallback": true | false,
    "reasoning": "string"
  },
  "scope_check": {
    "is_in_diff": true | false,
    "target_lines": [10, 11]
  },
  "ground_truth_check": {
    "matches_human_comment": true | false,
    "matched_comment_id": "string | null"
  },
  "severity_check": {
    "is_blocking": true | false,
    "rationale": "string"
  },
  "final_category": "TP" | "VU" | "OOS" | "NB" | "FP",
  "utility_weight": 1.0 | 0.8 | 0.0 | -0.1 | -1.0
}

```

---

## 6. Audit Artifact Generation Specification

For every evaluated PR run, the benchmark engine must automatically render a human-readable Markdown audit report to allow human reviewers to rapidly spot-check judge classifications.

### 6.1 Report Naming & Location Structure

Reports are saved using the following path convention, scoped so that repeat runs and multiple ACR tools never overwrite each other:

`audit_reports/{run_id}/{acr_tool}/{repo_owner}_{repo_name}/pr_{pr_number}.md`

Each run additionally writes a run-level index at `audit_reports/{run_id}/index.md` listing every evaluated PR with its category counts, WUS, and a relative link to its report, plus the run metadata (ACR tool, judge model + version pin, date).

### 6.2 Markdown Report Layout Template

```markdown
# SWR-Bench v2 Audit Report: PR #{pr_number}

**Repository:** `{repo_owner}/{repo_name}`  
**GitHub Link:** [Pull Request #{pr_number}](https://github.com/{repo_owner}/{repo_name}/pull/{pr_number})  
**ACR Tool:** `{acr_tool}` | **Run ID:** `{run_id}` | **Judge Model (pinned):** `{judge_model}`  
**Evaluation Status:** Completed  

---

## Executive Summary

| Total Predictions | True Positives (TP) | Valid Unattested (VU) | Out of Scope (OOS) | Non-Blocking (NB) | False Positives (FP) | Weighted Utility Score (WUS) |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| {total_predictions} | {count_tp} | {count_vu} | {count_oos} | {count_nb} | {count_fp} | **{wus_score}** |

*Legacy metrics for this PR (always reported alongside WUS):* precision {precision}, recall {recall}, F1 {f1}.

---

## Findings Detail

{for_each_finding}
### Finding #{finding_id}: `{category}` (Weight: {weight})

* **File Path:** `{file_path}` (Lines `{line_start}-{line_end}`)
* **Parse Fallback:** {parse_fallback}
* **Predicted Comment:** 
  > {predicted_comment}

#### Judge Evaluation Breakdowns
* **Fact Check:** {fact_check_status} — *"{fact_reasoning}"*
* **Scope:** {scope_status}
* **Ground Truth Match:** {gt_match_status}
* **Severity:** {severity_status}

#### Human Audit Override
* **Override:** _none_  <!-- A human auditor may replace this with `category: XX — reason`.
  Overrides are machine-readable and accumulate into the calibration set (§7, criterion 3). -->

<details>
<summary>View Code Context & Ground Truth</summary>

**Target Code Snippet:**
```python
{code_snippet}

```

**Ground Truth Human Comments:**

> {ground_truth_snippet}

---

{end_for_each}

```
```
---

## 7. Verification & Implementation Acceptance Criteria

An implementation of this update is considered compliant when:

1. **Schema Compliance:** The judge output parses reliably into the 5 discrete category buckets (`TP`, `VU`, `OOS`, `NB`, `FP`).
2. **Metric Coexistence:** Every report and results table that shows WUS also shows the same run's legacy precision/recall/F1. WUS is never presented as a standalone ranking metric.
3. **Calibration Before Comparison:** Before WUS figures are used to compare tools or models, the judge's category assignments are validated against a human-adjudicated sample of at least 100 findings (seeded from the existing 30-PR sample's deduplicated findings and accumulated Human Audit Overrides). Judge–human agreement (e.g., Cohen's κ per category) is reported, and the §2.2 weights are refit or the taxonomy revised if agreement is poor. A v1-vs-v2 comparison on the same runs is included so the effect of the metric change is visible.
4. **Artifact Generation:** Running an evaluation script automatically writes valid GitHub-linked Markdown reports plus a run-level index to the run- and tool-scoped `audit_reports/` structure of §6.1.
5. **No Dynamic Dependencies:** The system runs end-to-end on historical PRs without triggering subprocess execution of repo tests or setup scripts, and legacy (non-Python-3-parseable) files are handled by the §4 textual fallback with `parse_fallback` flagged.
6. **Spot-Check Auditability:** A human reviewer can open any generated Markdown audit artifact, click the GitHub link, and verify the judge decision within 60 seconds. This criterion is piloted on a handful of 2011–2012-era PRs before being treated as met.

> **Adoption note:** This spec supplements rather than replaces the original judge's verdicts, and prior project decisions (human adjudication of validity; pinned-judge comparability) still stand — a decision record should reconcile this spec with them before implementation begins.
