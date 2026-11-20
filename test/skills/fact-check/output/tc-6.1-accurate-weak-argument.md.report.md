# Fact-Check Report: A Questionable Conclusion

**User goal:** Check the factual claims in "A Questionable Conclusion" and give a calibrated verdict for each.
**Draft author:** Not stated
**Checked:** 2026-11-20
**Total claims checked:** 3
**Summary:** 1 accurate, 1 mostly accurate, 0 disputed, 1 inaccurate, 0 unverified, 0 secondary-only
**Provenance:** 2 observed, 1 inferred, 0 assumed
**Scrutiny:** 0 deep-read, 3 abstract, 0 inferred
**Prioritization:** 1 load-bearing, 2 peripheral

> **Limits of this check:** I couldn't open any page in full. Every attempt to fetch BLS, OECD, O*NET and FFYF failed with a DNS error (`EAI_AGAIN`), so every verdict rests on search-result text. Under the confidence rules, that caps every verdict at Medium. This matters most for C3: an Inaccurate verdict should be confirmed against the full source, and I couldn't do that.

---

## Claims identified

- **C1** `[load-bearing]` — "The median childcare worker earns $13.71 per hour." (paragraph 1)
- **C2** `[peripheral]` — "The US has roughly 1 million childcare workers." (paragraph 1)
- **C3** `[peripheral]` — "Federal childcare spending is approximately 0.4% of GDP." (paragraph 1)

*Not checked:* Paragraph 2 ("triple everyone's pay," "the problem will solve itself," "the only approach that makes sense," "anyone who disagrees is not paying attention") is a mix of recommendation, prediction and value judgment. None of it can be fact-checked.

---

## Verdict for C1: "The median childcare worker earns $13.71 per hour."

**Verdict:** Mostly accurate
**Confidence:** Medium
**Provenance:** [observed]
**Scrutiny:** [abstract]

$13.71 is the real BLS median hourly wage for childcare workers (SOC 39-9011), but it comes from the **May 2022** survey and is out of date. Later BLS releases are higher: $14.60 (May 2023) and $15.41 (May 2024, in the Occupational Outlook Handbook). O*NET, citing 2025 BLS data, reports $16.82, but I couldn't open that page. The confidence rule would allow High here, since the separate BLS releases agree with each other. It is capped at Medium because I read only search-result text. Opening the BLS May 2024 table and its May 2025 successor would confirm the current figure.

**Sources:** BLS Occupational Employment and Wage Statistics (OEWS), May 2022, 2023 and current; BLS Occupational Outlook Handbook (May 2024 data); O*NET National Wages (2025 data, not opened)
**Citation:** https://www.bls.gov/oes/2022/may/oes399011.htm

---

## Verdict for C2: "The US has roughly 1 million childcare workers."

**Verdict:** Accurate
**Confidence:** Medium
**Provenance:** [observed]
**Scrutiny:** [abstract]

The BLS Occupational Outlook Handbook counts about 991,600 childcare worker jobs in 2024, so "roughly 1 million" is a fair rounding. Note that this counts jobs in the narrow childcare-worker occupation. It leaves out preschool teachers and childcare center directors, so the wider early-childhood workforce is bigger. Confidence is Medium because this rests on one primary source, read only at search-result level. A second independent source, such as Census or Current Population Survey (CPS) counts, would raise it.

**Sources:** BLS Occupational Outlook Handbook, Childcare Workers (2024 employment)
**Citation:** https://www.bls.gov/ooh/personal-care-and-service/childcare-workers.htm#tab-1

---

## Verdict for C3: "Federal childcare spending is approximately 0.4% of GDP."

**Verdict:** Inaccurate
**Confidence:** Medium
**Provenance:** [inferred]
**Scrutiny:** [abstract]

The most natural reading is federal spending only. The reasoning:
1. FY2024 federal appropriations were about $21 billion: $8.7B for the Child Care and Development Block Grant (CCDBG) plus $12.27B for Head Start.
2. A broader 2026 estimate (FFYF) puts all federal birth-to-five funding at about $31B a year.
3. 2024 nominal GDP was about $29.3 trillion (FRED, republishing BEA data).
4. So federal spending is about 0.07–0.11% of GDP. 0.4% would be roughly $117B, about four times the broad figure.

I didn't check federal childcare tax breaks, such as the Child and Dependent Care Tax Credit. Including them would raise the share, but I found nothing showing they would push it near 0.4%.

The 0.4% figure does roughly match **total public spending (federal, state and local) on early childhood education and care, including pre-primary education**. The OECD puts the US below 0.5% of GDP on that measure, and EPI estimated 0.33% for 2015. So the number may come from a different, broader measure than the one the draft names.

Because this verdict asks the author to change something, it should be confirmed by fully reading the appropriations totals and the OECD PF3.1 table. My attempts to fetch them failed.

**Sources:** FFYF FY2024 appropriations summary (2024); Child Care Aware FY24/FY25 funding update (2024); FFYF "ABCs 2026" (2026, not opened); FRED GDPA series, from BEA (2025); OECD Family Database PF3.1 (not opened); EPI report on early-childhood public spending
**Citation:** "$21 billion for child care and early learning programs, including $8.7 billion for the Child Care and Development Block Grant" (FFYF, 2024)

---

## Claims Requiring Author Attention

- **C1** — $13.71 is the May 2022 BLS median. The latest BLS medians are $15.41 (May 2024) and reportedly $16.82 (2025). Update the figure or state the year it comes from.
- **C3** — Federal-only childcare spending is about 0.07–0.11% of GDP, not 0.4%. The 0.4% figure roughly matches *total public* early-childhood spending (federal, state and local, including pre-K). Name that measure or replace the number.

---

I couldn't save this to `docs/reviews/fact-check-report.md` because I have no file-writing tool in this session. The report above is the complete text to save.

**Sources:**
- [BLS OOH – Childcare Workers](https://www.bls.gov/ooh/personal-care-and-service/childcare-workers.htm)
- [BLS OEWS May 2022 – 39-9011](https://www.bls.gov/oes/2022/may/oes399011.htm)
- [BLS OEWS May 2023 – 39-9011](https://www.bls.gov/oes/2023/May/oes399011.htm)
- [BLS OEWS current – 39-9011](https://www.bls.gov/oes/current/oes399011.htm)
- [O*NET National Wages – Childcare Workers](https://www.onetonline.org/link/localwages/39-9011.00)
- [FFYF – FY2024 funding bill](https://www.ffyf.org/2024/03/21/fy2024-funding-bill-includes-1-billion-increase-for-federal-early-learning-and-child-care-programs/)
- [Child Care Aware – FY24/FY25 funding news](https://info.childcareaware.org/blog/fy24-fy25-child-care-funding-news)
- [FFYF – ABCs 2026](https://www.ffyf.org/wp-content/uploads/2026/02/ABCs-2026.pdf)
- [FRED – GDPA](https://fred.stlouisfed.org/series/GDPA)
- [OECD PF3.1 – Public spending on childcare and early education](https://oecd.org/els/soc/PF3_1_Public_spending_on_childcare_and_early_education.pdf?os=qtfT_2)
- [EPI report](https://www.epi.org/181729/pre/e5c638070b788b254b42829bc2683c00bb1c8a4fc7399df95e5752d41112c5dc)
- [JEC Democrats – US invests less in child care than almost every OECD country](https://www.jec.senate.gov/public/index.cfm/democrats/2021/8/fast-facts-the-united-states-invests-less-in-child-care-than-almost-every-other-oecd-country)
