---
Last verified: 2026-03-23
Relevant paths:
  - test/skills/fact-check/fixtures/
  - test/skills/code-fact-check/fixtures/
---

# Fact-Check Report: Test Fixtures for fact-check Skills

**Checked:** 2026-03-23
**Total claims checked:** 14
**Summary:** 4 accurate, 4 mostly accurate, 1 disputed, 2 inaccurate, 3 unverified

---

## Claim 1: "US healthcare spending reached $4.3 trillion in 2023, or 17.3% of GDP"

**Verdict:** Inaccurate
**Confidence:** High

CMS reported that US national health expenditure in 2023 was $4.9 trillion, not $4.3 trillion -- a 7.5% increase from 2022. The GDP share was 17.6%, not 17.3%. The $4.3 trillion figure does not correspond to any recent year's actual spending. This claim is substantially wrong on the dollar amount (off by ~$600 billion) and slightly off on the GDP percentage.

**Test suite impact:** The test strategy (TC-1.1) does not specify an expected verdict for this claim -- it only checks that the skill cites CMS/BEA data. However, if a fact-check skill rates this as "Accurate," that would be incorrect. The claim should yield "Inaccurate" or at minimum "Mostly accurate" given the magnitude of the dollar discrepancy.

**Sources:**
- [CMS: National health spending increased 7.5% in 2023 (AHA)](https://www.aha.org/news/headline/2024-12-19-cms-national-health-spending-increased-75-2023)
- [National Health Expenditures In 2023 (Health Affairs)](https://www.healthaffairs.org/doi/10.1377/hlthaff.2024.01375)
- [NHE Fact Sheet (CMS)](https://www.cms.gov/data-research/statistics-trends-and-reports/national-health-expenditure-data/nhe-fact-sheet)

---

## Claim 2: "Oregon's SB 458 requires sellers to share appreciation with tenants who helped maintain the property"

**Verdict:** Inaccurate
**Confidence:** High

Oregon SB 458 (2021) is a middle-housing land division bill. It allows lot divisions for middle housing (duplexes, triplexes, quadplexes, townhouses, cottage clusters) so individual units can be sold or owned separately. It has nothing to do with requiring sellers to share appreciation with tenants. The bill is a follow-up to HB 2001 (which legalized middle housing) and establishes expedited land division procedures.

**Test suite impact:** The test strategy (TC-1.2) asks the skill to "look up the actual bill" and "verify whether this description is accurate." The eval criteria do not specify an expected verdict. A correct fact-check should identify this as "Inaccurate" -- the bill exists but does something completely different from what the draft claims.

**Sources:**
- [Senate Bill 458 Guidance (Oregon DLCD)](https://www.oregon.gov/lcd/UP/Documents/SB_458_Guidance.pdf)
- [SB 458 passes Oregon Legislature (Habitat for Humanity Oregon)](https://habitatoregon.org/news/sb-458/)
- [Oregon Poised to Enact Expedited Land Division Allowances (Schwabe)](https://www.schwabe.com/publication/oregon-poised-to-enact-expedited-land-division-allowances-for-middle-housing/)

---

## Claim 3: "Minnesota legalized recreational cannabis in 2023"

**Verdict:** Accurate
**Confidence:** High

Governor Tim Walz signed HF 100 into law on May 30, 2023, making Minnesota the 23rd state to legalize recreational cannabis. The law took effect on August 1, 2023. The fixture also states "signed by Governor Tim Walz and took effect on August 1st," which is correct.

**Test suite impact:** TC-1.3 and the eval criteria both expect "Accurate." This is correct.

**Sources:**
- [Minnesota governor signs law legalizing recreational marijuana (Axios)](https://www.axios.com/local/twin-cities/2023/05/30/minnesota-cannabis-legalization-dates-to-know-dispensary-open)
- [Minnesota Becomes the 23rd Legal Marijuana State (NORML)](https://norml.org/blog/2023/05/30/minnesota-becomes-the-23rd-legal-marijuana-state/)
- [Minnesota cannabis legalization (CNN)](https://www.cnn.com/2023/05/30/politics/minnesota-cannabis-legalization-recreational-marijuana/index.html)

---

## Claim 4: "Austin rents dropped 15% because a construction boom flooded the market"

**Verdict:** Mostly accurate
**Confidence:** Medium

Austin rents did decline significantly due to a construction boom, and this causal link is well-supported. However, the 15% figure is imprecise. Different sources report different magnitudes depending on the time period: rents fell ~7% from 2023 to 2024 alone, ~10% from May 2023 to May 2024, and more than 16% from 2021 to 2026. The 15% figure is within the range of reported declines but does not match any single commonly cited statistic precisely. The causal claim (construction boom) is strongly supported by multiple sources.

**Test suite impact:** TC-1.4 expects the skill to check both the magnitude and the causal link separately. A verdict of "Mostly accurate" would be appropriate -- the direction and cause are correct, but the specific 15% figure is imprecise.

**Sources:**
- [Austin's Surge of New Housing Construction Drove Down Rents (Pew)](https://www.pew.org/en/research-and-analysis/articles/2026/03/18/austins-surge-of-new-housing-construction-drove-down-rents)
- [Austin's Rent Drop Isn't "Weird" -- It's Economics (NMHC)](https://www.nmhc.org/news/research-corner/2025/austins-rent-drop-isnt-weird-its-economics/)
- [Austin rents drop by more than 20% after home building surge (BDC Network)](https://www.bdcnetwork.com/home/news/55272882/austin-rents-drop-by-more-than-20-after-home-building-surge)
- [Austin rents have fallen for nearly two years (Texas Tribune)](https://www.texastribune.org/2025/01/22/austin-texas-rents-falling/)

---

## Claim 5: "Most OECD countries provide universal pre-K"

**Verdict:** Mostly accurate
**Confidence:** Medium

Most OECD countries do provide universal or near-universal access to at least one year of early childhood education before primary school. Enrollment rates for 4-year-olds surpass 90% in two-thirds of OECD countries. However, "universal pre-K" is not a precise term -- some countries provide universal access for 3-5 year olds, others only for 4-5, and definitions of "universal" vary. The claim is directionally correct but imprecise.

**Test suite impact:** TC-1.5 and the eval criteria expect "Mostly accurate" or "Disputed." "Mostly accurate" is the better fit.

**Sources:**
- [The United States Is Far Behind Other Countries on Pre-K (Center for American Progress)](https://www.americanprogress.org/article/the-united-states-is-far-behind-other-countries-on-pre-k/)
- [Universal preschool (Wikipedia)](https://en.wikipedia.org/wiki/Universal_preschool)
- [U.S. Lags Far Behind Other Countries in Access to Early Childhood Education (NEA)](https://www.nea.org/nea-today/all-news-articles/us-lags-far-behind-other-countries-access-early-childhood-education)

---

## Claim 6: "The 2020 US Census counted 331.4 million people"

**Verdict:** Accurate
**Confidence:** High

The 2020 Census reported a total US resident population of 331,449,281 as of April 1, 2020. Rounded to one decimal place, this is 331.4 million, matching the claim exactly.

**Test suite impact:** TC-2.1 expects "Accurate" with high confidence and a Census Bureau citation. This is correct.

**Sources:**
- [First 2020 Census Data Release (Census Bureau)](https://www.census.gov/library/stories/2021/04/2020-census-data-release.html)
- [2020 Census Apportionment Results (Census Bureau)](https://www.census.gov/newsroom/press-releases/2021/2020-census-apportionment-results.html)

---

## Claim 7: "Nearly 70% of parents spend a fifth of their income on childcare"

**Verdict:** Mostly accurate
**Confidence:** Medium

This claim conflates two different survey findings. According to Care.com's 2022 survey: 51% of families spend 20% or more (a fifth) of their income on childcare. Separately, 72% (nearly 70%) of families spend at least 10% of their income on childcare. The "nearly 70%" figure and the "a fifth of their income" figure come from different thresholds. The claim merges the 70% figure (which applies to 10%+ of income) with the 20% threshold (which applies to 51% of families).

**Test suite impact:** TC-2.2 expects "Mostly accurate" with an explanation of the conflated surveys. The eval criteria (TC-4.2) also expects the skill to detect this conflation. This is correct -- the claim is directionally right but conflates two statistics.

**Sources:**
- [Majority of Families Spend at Least 20% of Household Income on Childcare (Care.com)](https://www.care.com/about/press/majority-of-families-spend-at-least-20-of-household-income-on-childcare-according-to-new-care-com-survey/)
- [Over Half of Families are Spending More Than 20% of Income on Child Care (FFYF)](https://www.ffyf.org/resources/2022/06/over-half-of-families-are-spending-more-than-20-on-child-care/)
- [Families Who Pay for Child Care Spend Nearly a Fifth of Their Income on It (LendingTree)](https://www.lendingtree.com/debt-consolidation/child-care-income-study/)

---

## Claim 8: "The minimum wage increase in Seattle reduced hours worked for low-wage employees"

**Verdict:** Disputed
**Confidence:** High

This claim reflects one side of a genuine academic disagreement. The University of Washington study (Jardim et al.) found that Seattle's minimum wage increase reduced hours worked for low-wage employees by about 9%, resulting in an average loss of ~$125/month per job. However, the UC Berkeley study (Allegretto et al.) found no significant negative employment effects when using restaurant employment as a proxy. Both studies were published in peer-reviewed venues and use different methodologies and data. The claim states the UW finding as fact without acknowledging the competing evidence.

**Test suite impact:** TC-2.3 expects "Disputed" citing both studies. This is correct.

**Sources:**
- [UW study finds Seattle's minimum wage is costing jobs (Seattle Times)](https://www.seattletimes.com/business/uw-study-finds-seattles-minimum-wage-is-costing-jobs/)
- [Minimum Wage Increases and Low-Wage Employment (NBER)](https://www.nber.org/system/files/working_papers/w23532/w23532.pdf)
- [New Study: High Minimum Wages in Six Cities, Big Impact on Pay, No Employment Losses (Berkeley IRLE)](https://irle.berkeley.edu/high-minimum-wages-in-six-cities/)

---

## Claim 9: "France banned homeschooling in 2021"

**Verdict:** Mostly accurate
**Confidence:** High

France passed the "Separatism Law" (Loi confortant le respect des principes de la Republique) in August 2021, which severely restricted homeschooling. Under the new law, homeschooling requires state authorization and is limited to four specific exceptions (health, disability, geographic distance, and other specific child needs). Previously, families only needed to file a declaration. However, calling this a "ban" is an overstatement -- homeschooling is still legally possible under the restricted conditions. Some advocacy groups (e.g., ECLJ) do describe it as effectively a ban, while the legal text frames it as an authorization regime.

**Test suite impact:** TC-2.4 expects "Inaccurate" with the explanation that France "restricted, not banned" homeschooling. The eval criteria state the same. This expected verdict is reasonable but arguably too strong -- "Mostly accurate" or "Inaccurate" are both defensible depending on how strictly one interprets "banned." The key point is that calling it a flat "ban" is misleading since exemptions exist, so the test suite's expected verdict of "Inaccurate" is defensible. However, the fixture also claims France was "the first major Western democracy to eliminate the practice entirely," which is clearly wrong since the practice was not eliminated.

**Sources:**
- [France's controversial 'separatism' bill (Al Jazeera)](https://www.aljazeera.com/news/2021/2/15/frances-controversial-separatism-bill-explained)
- [Ban on home schooling in France (ECLJ)](https://eclj.org/family/un/interdiction-de-lecole-a-la-maison-en-france--leclj-alerte-le-rapporteur-onu-sur-leducation?lng=en)
- [France home-school ban: conditions may be relaxed (Connexion France)](https://www.connexionfrance.com/article/French-news/France-home-school-ban-conditions-may-be-relaxed)
- [France (HSLDA)](https://hslda.org/post/france)

---

## Claim 10: "The median pay for childcare workers was $13.71 per hour in 2022"

**Verdict:** Accurate
**Confidence:** High

According to BLS Occupational Employment and Wage Statistics (OEWS) for May 2022, the median hourly wage for childcare workers (SOC 39-9011) was $13.71. This matches the claim exactly.

**Test suite impact:** This claim appears in the mixed draft (TC-3.3) and should be identified as a checkable factual claim.

**Sources:**
- [Childcare Workers, May 2022 OEWS (BLS)](https://www.bls.gov/oes/2022/may/oes399011.htm)

---

## Claim 11: "Denmark spends approximately 2% of GDP on early childhood education and care, compared to about 0.4% in the US"

**Verdict:** Mostly accurate
**Confidence:** Medium

Denmark's spending figure of approximately 2% of GDP on early childhood education and care is supported by OECD data -- a CED policy brief cites Denmark at 2% of GDP. However, the US figure is closer to 0.3% of GDP according to more recent OECD data, not 0.4%. Some older sources or those using different methodologies may report 0.4-0.5%, so "about 0.4%" is in the right ballpark but slightly high. The comparison is directionally correct and the Denmark figure is accurate; the US figure is approximately right but slightly overstated.

**Sources:**
- [US lags OECD average spending on early education (Quartz)](https://qz.com/2119811/us-lags-oecd-average-spending-on-early-education-and-child-care)
- [CED Policy Brief: Public Investment in Childcare and Early Ed](https://www.ced.org/pdf/CED_Policy_Brief_Childcare_Early_Ed_Policies_in_OECD_vs_US_11.11.2020.pdf)
- [PF3.1: Public spending on childcare and early education (OECD)](https://webfs.oecd.org/els-com/Family_Database/PF3_1_Public_spending_on_childcare_and_early_education.pdf)
- [The United States Invests Less in Child Care Than Almost Every Other OECD (JEC)](https://www.jec.senate.gov/public/_cache/files/c3be28bf-d058-4046-ad53-92bcac068b6f/fast-facts-child-care-oecd-final.pdf)

---

## Claim 12: "The Great Wall of China is the only man-made structure visible from space"

**Verdict:** Inaccurate
**Confidence:** High

This is a well-known myth. The Great Wall of China is not visible from space with the naked eye. The wall is long but very narrow (~10 meters wide) and does not contrast well against surrounding terrain. China's first astronaut, Yang Liwei, confirmed he could not see the wall from orbit. NASA and multiple scientific sources have debunked this claim. No man-made structure is uniquely visible from space in the way the myth suggests.

**Test suite impact:** TC-6.3 expects the skill to catch this as a myth and not skip it for being "obvious." The eval criteria confirm this. The expected behavior is correct.

**Sources:**
- [No, You Can't See the Great Wall of China from Space (Scientific American)](https://www.scientificamerican.com/article/no-you-cant-see-the-great-wall-of-china-from-space/)
- [Great Wall (NASA)](https://www.nasa.gov/image-article/great-wall/)
- [Can you see the Great Wall of China from space? (Britannica)](https://www.britannica.com/question/Can-you-see-the-Great-Wall-of-China-from-space)

---

## Claim 13: "The childcare sector employs roughly 1 million workers in the United States"

**Verdict:** Accurate
**Confidence:** Medium

BLS data shows approximately 942,000 workers employed across 77,000 childcare services establishments. "Roughly 1 million" is a reasonable approximation of this figure, and depending on how broadly "childcare sector" is defined (including preschool teachers, administrators, etc.), the total could be at or above 1 million. The claim is directionally correct and appropriately hedged with "roughly."

**Test suite impact:** This appears in the mixed draft (TC-3.3) and should be identified as a checkable claim.

**Sources:**
- [Childcare employment -- before, during, and after the COVID-19 pandemic (BLS Monthly Labor Review)](https://www.bls.gov/opub/mlr/2024/article/childcare-employment-before-during-and-after-the-covid-19-pandemic.htm)
- [Child Care Sector Jobs (Berkeley CSCCE)](https://cscce.berkeley.edu/publications/brief/child-care-sector-jobs/)

---

## Claim 14: "in Florida, the waitlist exceeded 40,000 families in 2023"

**Verdict:** Unverified
**Confidence:** Medium

I could not find reliable evidence confirming a 40,000-family waitlist for subsidized childcare in Florida in 2023. Available data shows the waitlist was approximately 4,200 children in 2022 and had risen to approximately 25,968 by 2025. The 40,000 figure does not match any data point I could locate. It is possible this figure appeared in a specific 2023 report or refers to a different program or metric, but I cannot verify it.

**Test suite impact:** This appears in the mixed draft (TC-3.3). The eval criteria list it as a checkable claim. Given that the number cannot be verified and does not match available data, a fact-check skill should flag this as "Unverified" or potentially "Inaccurate."

**Sources:**
- [Families face long waitlist for Florida's subsidized childcare program (Orlando Sentinel)](https://www.orlandosentinel.com/2025/11/23/families-face-long-waitlist-for-floridas-subsidized-childcare-program/)

---

## Claims Requiring Author Attention

1. **Claim 1 (US healthcare spending $4.3 trillion)** -- Inaccurate. Actual 2023 spending was $4.9 trillion per CMS. This is used as a test input in TC-1.1 with no expected verdict specified, but the test strategy description does not acknowledge the claim is wrong. If the intent is to test the skill's ability to catch inaccurate numbers, the test strategy should say so explicitly.

2. **Claim 2 (Oregon SB 458 and tenant appreciation)** -- Inaccurate. SB 458 is a middle-housing land division bill, not a tenant appreciation-sharing law. The test strategy (TC-1.2) does not specify an expected verdict, so this may be intentionally wrong to test the skill's lookup ability. If so, this should be documented.

3. **Claim 4 (Austin rents dropped 15%)** -- Mostly accurate. The 15% figure is in the range but imprecise. Acceptable as a "causal claims" test case.

4. **Claim 7 (70% of parents / fifth of income)** -- Mostly accurate. Conflates two statistics as intended by the test design.

5. **Claim 9 (France banned homeschooling)** -- Mostly accurate to Inaccurate. The test expects "Inaccurate" which is defensible since France restricted rather than banned homeschooling.

6. **Claim 11 (Denmark 2% vs US 0.4%)** -- Mostly accurate. The US figure is closer to 0.3% than 0.4%.

7. **Claim 14 (Florida waitlist 40,000 families)** -- Unverified. Available data does not support this specific number. If the test intends this to be a checkable accurate claim, the figure may need correction.
