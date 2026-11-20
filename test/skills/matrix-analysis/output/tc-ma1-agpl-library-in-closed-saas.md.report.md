Stage 2 (evaluation) complete: 4/4 criterion sub-agents returned (12 ratings total, 0 failures) — synthesizing into comparison matrix and recommendation.

# Deliverable 1: Chat synthesis

## Recommendation: Folio
Folio is the only option that passes Legal's licence rule and is likely to stay maintained. Its rendering has one known problem: tables can mis-align when a cell wraps across a page break. Check how often that hits real invoices before you commit.

## The matrix

| | Licence compatibility | Rendering fidelity | Throughput | Maintenance health |
|---|---|---|---|---|
| **Kestrel** | - | ++ | ++ | ++ |
| **Parchment** | ++ | + | ++ | - |
| **Folio** | ++ | + | ++ | ++ |

`++` Strong · `+` Adequate · `-` Weak. No weights were applied, but licence compatibility is treated as a pass/fail requirement because of Legal's rule.

## Key findings
- **Kestrel** scores best on everything except the licence. It is Strong on three of four criteria, but it fails the licence test.
  - The AGPL-3.0 licence obliges you to publish source to anyone who uses the software over a network. Bundling Kestrel into Brightline could pull Brightline's own code into that obligation.
  - Kestrel offers no commercial licence, so there is no way around this.
- **Folio** is Strong on three criteria and Adequate on rendering fidelity. It has no Weak scores.
- **Parchment** is Weak on maintenance health:
  - It has one maintainer, who has said publicly they are looking for a successor.
  - The right-to-left (RTL) plugin your Israeli and Gulf invoices would need has not been updated for a year.
- **Throughput doesn't separate the options.** The need is about 28 pages/second even if the whole month were rendered in one 8-hour window, assuming about 2 pages per invoice. The slowest library manages about 70.
- **Rendering fidelity is where the libraries really differ.** Only Kestrel has no rendering problems. Parchment and Folio are both Adequate, for different reasons.

## Tradeoffs
- **Kestrel's rendering against the licence rule.** Kestrel is the best renderer, but Legal's rule is a hard constraint and Kestrel has no commercial licence. That isn't a tradeoff you can weigh, so Kestrel is out.
- **Parchment against Folio is a choice between two kinds of risk.**
  - Parchment's risk is a stale RTL plugin. No actual defect is recorded, but it sits on a project whose only maintainer wants to leave.
  - Folio's risk is a confirmed table/page-break defect. A fix is scheduled, and the project has a foundation and twelve committers behind it.
  - The rendering sub-agent narrowly ranked Parchment above Folio, because an unproven risk is less serious than a confirmed defect. Over a multi-year horizon, though, Parchment's maintenance problem gets worse while Folio's defect has a fix coming.

## Risks and gaps
- **Folio's page-break defect could drop it to Weak.** "Occasionally mis-aligns" might be serious for financial documents. Test it on real multi-page invoices with wrapping cells, and confirm when the fix will ship.
- **Folio's release cadence is unknown.** Its Strong maintenance score rests on governance and committer count.
- **The benchmark setup is unknown.** Its hardware, concurrency and test document were not stated. The headroom is large enough (about 200 times the average load) that this is unlikely to change any rating, but treat the throughput figures as provisional.
- **Parchment's RTL plugin hasn't been tested on Hebrew or Arabic invoices.** Nobody has evidence of how well it works today.
- **No item was rated "Insufficient information."** No criterion was Weak for every option.
- **Throughput was Strong for all three**, so it is not a deciding criterion.
- **Legal should confirm the Kestrel ruling** so no more evaluation effort goes into it.

## Recommendation in detail
- **Choose Folio.** It passes the licence test, has the healthiest project, and has built-in RTL support, so it doesn't depend on a third-party plugin.
- **Before you commit:**
  1. Reproduce the page-break table defect on real invoice templates.
  2. Get a date for the fix, and Folio's release cadence.
  3. If the defect shows up often, look for a template-level workaround until the fix lands, such as keeping table rows from splitting across pages. Whether that works depends on your templates.
- **What would change the answer:**
  - If the page-break defect turns out to be frequent and has no workaround, Folio's rendering would be Weak. Parchment then becomes a short-term fallback only if its RTL plugin passes testing, and you'd need to be prepared to fork or maintain the plugin and possibly Parchment itself.
  - Kestrel would only come back into consideration if it offered a commercial licence. That isn't offered today.

The full matrix document is below. As you asked, it is printed here rather than saved to `docs/reviews/matrix-analysis.md`.

---

# Deliverable 2: Matrix document

```markdown
# Matrix Analysis

**Items:** Kestrel, Parchment, Folio | **Criteria:** 4 | **Date:** 2026-11-19

---

## Comparison Matrix

| | Licence compatibility | Rendering fidelity | Throughput | Maintenance health | Overall |
|---|---|---|---|---|---|
| **Kestrel** | - AGPL-3.0 network clause; no commercial licence | ++ best-in-class: RTL, embedded fonts, pixel-exact tables | ++ ~120 pages/s, ~4.3x peak headroom | ++ 3 maintainers, monthly releases | Disqualified by the licence rule despite top marks elsewhere |
| **Parchment** | ++ MIT, permissive | + good, but RTL depends on a plugin not updated for a year | ++ ~90 pages/s, ~3.2x peak headroom | - one maintainer looking for a successor; stale RTL plugin | Licence OK; long-term maintenance risk is serious |
| **Folio** | ++ Apache-2.0, permissive, explicit patent grant | + built-in RTL; known table mis-alignment at page breaks (fix scheduled) | ++ ~70 pages/s, ~2.5x peak headroom | ++ foundation-backed, 12 active committers | Recommended; check the page-break defect first |

---

## Detailed Evaluations

### Criterion 1: Licence compatibility

**Definition:** Whether the licence can be used in Brightline's closed-source, multi-tenant SaaS (customers use the software over the network and never receive code) without any obligation to publish Brightline's source.

| Item | Rating | Rationale |
|---|---|---|
| Kestrel | Weak | AGPL-3.0 Section 13 requires offering source to users who interact with a modified program over a network, which is exactly how Brightline's customers use it. Bundling Kestrel into Brightline could plausibly pull Brightline's own code into that obligation, which breaks Legal's rule. No commercial licence is offered, so there is no way around this. |
| Parchment | Strong | MIT is permissive, with no copyleft or network-use clause. Its only condition is keeping the copyright and permission notice. That never obliges Brightline to publish its source. |
| Folio | Strong | Apache-2.0 is permissive, with no copyleft or network-use clause. Its conditions (notices, the NOTICE file, marking modified files) only apply when the software is redistributed. Its explicit patent grant lowers legal ambiguity. |

**Ranking:** Folio = Parchment > Kestrel. The Apache patent grant gives Folio a slight edge but doesn't change either rating.
**Key differentiator:** Copyleft against permissive: Kestrel's AGPL network clause can create a source-disclosure obligation in a SaaS model, and the MIT and Apache-2.0 licences cannot.

---

### Criterion 2: Rendering fidelity

**Definition:** How accurately and reliably the library renders Brightline's invoices: A4 pages, tables (including tables that span page breaks), logos, embedded fonts, and right-to-left Hebrew and Arabic text.

| Item | Rating | Rationale |
|---|---|---|
| Kestrel | Strong | Best-in-class rendering with full RTL support, embedded fonts and pixel-exact tables, and no known defects. It covers every part of the invoice workload out of the box. |
| Parchment | Adequate | Rendering is good, but RTL only works through a plugin that has not been updated for a year. That puts the Hebrew and Arabic invoices at risk, although no actual RTL defect is recorded. |
| Folio | Adequate | RTL support is built in, but there is a known issue where tables mis-align when a cell wraps across a page break. That affects multi-page invoice tables directly. The fix is scheduled but not yet shipped. |

**Ranking:** Kestrel > Parchment ≈ Folio. Parchment was ranked narrowly ahead because an unproven risk is less serious than a confirmed defect.
**Key differentiator:** Only Kestrel renders both RTL text and page-spanning tables with no defect and no outside plugin.

---

### Criterion 3: Throughput

**Definition:** Whether rendering speed comfortably meets about 400,000 invoices a month, with headroom for month-end peaks and growth.

Assumptions: about 2 pages per invoice, so about 800,000 pages a month. Average load is about 0.31 pages/s. Harsh peak: the whole month in one 8-hour window, about 27.8 pages/s. Stress case: 3 pages per invoice in a 4-hour window, about 83 pages/s. All figures are per instance of the unstated benchmark setup.

| Item | Rating | Rationale |
|---|---|---|
| Kestrel | Strong | ~120 pages/s renders the full month in about 1.9 hours. That is ~4.3x headroom over the harsh peak, and it clears the stress case at ~1.4x. |
| Parchment | Strong | ~90 pages/s renders the full month in about 2.5 hours. That is ~3.2x headroom over the harsh peak, and it just clears the stress case at ~1.08x. |
| Folio | Strong | ~70 pages/s renders the full month in about 3.2 hours. That is ~2.5x headroom over the harsh peak. It falls short only in the stress case (~0.84x), where a second instance would fix it. |

**Ranking:** Kestrel > Parchment > Folio. All three are Strong against the actual need.
**Key differentiator:** Capacity far exceeds the need, so throughput barely separates the options. The only difference is how much headroom is left in extreme peak cases.

---

### Criterion 4: Maintenance health

**Definition:** How likely the project, and any components the workload depends on (such as RTL support), are to keep receiving fixes, security patches and releases over several years.

| Item | Rating | Rationale |
|---|---|---|
| Kestrel | Strong | Three maintainers and monthly releases. Without institutional backing it has a smaller cushion than a foundation, but losing one person would not stop the project. |
| Parchment | Weak | One maintainer, who has said publicly they are looking for a successor. That is a single point of failure and an early sign of abandonment. The required RTL plugin has not been updated for a year. |
| Folio | Strong | Foundation backing and twelve active committers give it the lowest bus-factor risk of the three. A fix already scheduled for a known defect shows active triage. Release cadence is not stated. |

**Ranking:** Folio > Kestrel (close) >> Parchment.
**Key differentiator:** Concentration of people and governance: a foundation with twelve committers, against three maintainers, against one maintainer who wants to leave plus a stale RTL plugin.

---

## Tradeoff Analysis

- **Kestrel's rendering against the licence rule:** this isn't a real tradeoff. Legal's rule is a hard constraint and Kestrel offers no commercial licence, so it is out however well it renders.
- **Parchment against Folio:**
  - Parchment has an unproven RTL risk, a stale plugin, and a project whose only maintainer wants to leave.
  - Folio has a confirmed but narrow table defect, a scheduled fix, and strong governance.
  - In the short term the two render about equally well. Over several years, Parchment's risks grow and Folio's should shrink.
- **Throughput** does not influence the decision. All options have ample headroom.

## Recommendation

**Adopt Folio.** It is the only option that passes the licence test and is likely to stay maintained, and its RTL support is built in. Before you commit:

1. Reproduce the page-break table mis-alignment on real multi-page invoice templates.
2. Confirm when the fix will ship, and Folio's release cadence.
3. If the defect is frequent, look for a template-level workaround until the fix lands, such as keeping table rows from splitting across pages.

What would change the answer:

- If the defect is frequent and has no workaround, Folio's rendering becomes Weak. Parchment is then a short-term fallback only if its RTL plugin passes testing on Hebrew and Arabic invoices, and you would need to be ready to fork or maintain the plugin and possibly Parchment itself.
- Kestrel would only come back into consideration if it offered a commercial licence.

---

## Evaluation Metadata

- **Scoring:** Qualitative (Strong / Adequate / Weak)
- **Weights:** None. Licence compatibility treated as a pass/fail requirement per Legal's rule.
- **Agents dispatched:** 4 criterion evaluators, all returned
- **Items with data gaps:** None rated "Insufficient information". Open caveats: benchmark hardware, concurrency and test document; Folio's release cadence and fix date; Parchment's RTL plugin untested on real invoices; Legal to confirm the AGPL ruling.
```
