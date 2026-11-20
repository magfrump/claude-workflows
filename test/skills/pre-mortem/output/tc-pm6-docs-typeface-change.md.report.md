ℹ️ **No upstream what-if analysis provided.** These failure narratives come straight from the proposal. They would be sharper if seeded with assumptions and coupling points mapped by `what-if-analysis`.

ℹ️ **Prior Art Check skipped.** No repository was available, so `docs/decisions/` and `docs/working/` were not searched. No narrative is tagged `[PRIOR CONSIDERATION]`.

# Pre-Mortem: Internal dev-docs typeface switch

**Proposal:** Switch internal developer docs body text to a high-legibility sans-serif and code to a distinct-glyph monospace, via `theme/typography.css`, behind the `theme_variant` cookie
**Date:** 2026-11-19
**Upstream what-if analysis:** none

---

## Framing

This is a low-stakes change, and the failure narratives should reflect that. It touches no content, state, URLs, or external dependencies. It is CSS on a static site with a five-minute rollback, and it already has accessibility sign-off and cross-browser checks. None of the stories below reaches High or Catastrophic severity. Most of the realistic failure comes from three gaps:

- the **feedback process**, which may produce a misleading signal;
- the **long tail** of 1,350 pages that were not rendered;
- the **clean-up step**, which quietly removes the rollback guarantee the proposal relies on.

---

## Failure Narratives

### 1. "Silence Counted as Consent"

- **Root cause:** Preview enrollment is opt-in through a footer link (Rollout §1). The default-flip criterion is "feedback is neutral or positive" (Rollout §2), and it has no minimum sample size and no definition of "neutral."
- **Chain of consequences:**
  1. Over the two weeks, about 25 of 300 engineers opt in. They are mostly the people who complained about the old font and were primed to like the new one.
  2. #devdocs gets 6 messages: 5 positive and 1 "looks fine." No negative feedback arrives, because the engineers who would dislike the change never saw it.
  3. DevEx reads this as "neutral or positive" and flips the default.
  4. In the following week, the other ~275 engineers meet the change unannounced. Several dislike the extra vertical length from line height 1.55, which means roughly 10% more scrolling on long reference pages. They post in #devdocs and in team channels, and a thread asking "who approved this?" collects 40 reactions.
  5. DevEx spends a week mediating taste arguments it could have resolved during preview. The planned clean-up is delayed indefinitely, and the site carries both typographies with no end date.
- **Observable outcome:** Preview opt-in cookie count is under 10% of weekly unique visitors. Negative #devdocs messages spike in the week after the default flip, not during preview. Usage of the old-typography cookie rises after the flip.
- **Plausibility:** Likely
- **Severity:** Low
- **Mitigation:** Amend Rollout §2 so the default flip requires (a) at least 60 distinct opted-in visitors, measured from `theme_variant` cookie hits in the access logs, and (b) an explicit one-question poll in #devdocs. Before the poll, run a short forced-exposure window, such as a site banner linking to a side-by-side comparison, so that people who did not self-select also see the change.

### 2. "The Box-Drawing Collapse"

- **Root cause:** The new monospace ships as a Latin-only subset or simply lacks some glyphs, such as box-drawing (`─│┌└├`), arrows (`→ ⇒`), or math symbols (`≤ ≥ ≠`). These appear in ASCII architecture diagrams and CLI output samples that are scattered through the long tail of the 1,400 pages. The 50 most-visited pages that were checked are mostly prose-heavy landing pages without such diagrams.
- **Chain of consequences:**
  1. In code blocks, missing glyphs fall back to the browser's next font in the stack, typically DejaVu Sans Mono, Menlo, or Consolas depending on OS. Each fallback has a different advance width than the new face.
  2. ASCII diagrams in runbooks and architecture pages lose column alignment. Boxes no longer close, and arrows point at the wrong component.
  3. In a separate effect, the new monospace is wider per character than the old one. Code samples that fit in 100 columns now scroll horizontally on 13" laptops.
  4. An on-call engineer at 2 a.m. reads a misaligned failover diagram in the payments runbook and misreads which replica is the primary. This costs time during the incident rather than causing the incident.
- **Observable outcome:** Screenshots of broken diagrams appear in #devdocs or incident retros. Code blocks show a horizontal scrollbar where they did not before. Rendering differs by OS, so the bug is "works on my Mac" and the reports are inconsistent.
- **Plausibility:** Plausible
- **Severity:** Low (Medium for the subset of runbook pages used during incidents)
- **Mitigation:** Before the preview starts, grep the docs source for non-ASCII characters inside fenced code blocks, for example `grep -rlP '[^\x00-\x7F]'` scoped to code fences. Render every matching page, not just the top 50, and confirm the chosen monospace covers the U+2500–U+257F box-drawing block. Then add an explicit metric-compatible fallback at the end of the code `font-family` stack in `theme/typography.css`.

### 3. "The PDF Export Lost Its Font"

- **Root cause:** "Checks already done" says the print stylesheet and PDF export "use their own font settings." That is true at the CSS level, but the PDF export's font settings reference the *old* font files by path in the same static-assets bucket. Rollout §3 deletes those files.
- **Chain of consequences:**
  1. Clean-up removes the old font files and the cookie branch. The site renders correctly, because nothing on the site references the old files anymore.
  2. The next scheduled PDF export job runs. For example, a quarterly compliance bundle of security runbooks, or the onboarding pack sent to new hires.
  3. The headless renderer cannot resolve the deleted font URLs and silently substitutes a system default, such as a serif Times-like face. Alternatively, a stricter toolchain fails the build outright.
  4. Nobody notices for weeks, because PDF exports are generated rarely and read by people outside DevEx: new hires, auditors, other teams.
  5. Someone in compliance or onboarding reports that the PDFs "look broken." By then the old files are gone, and rollback is no longer the "one-line config change" from the Rollback section. The files have to be recovered from bucket versioning, if it is enabled, or from git history.
- **Observable outcome:** PDF export job logs show font-load warnings or 404s against the old font paths in the assets bucket, or the job fails. Exported PDFs render in a fallback serif face.
- **Plausibility:** Plausible. This depends on how the export is wired, which the proposal asserts but does not show.
- **Severity:** Medium. It is recoverable, but it is noticed late and reverses a step the team considered finished.
- **Mitigation:** Add a gate to Rollout §3. Before deleting the old font files, grep the whole repo, including the print stylesheet and the PDF export config and templates, for every old font filename. Run the PDF export once against a bucket with the old files temporarily removed or renamed. Make sure bucket object versioning is enabled so the deletion can be undone.

### 4. "Deep Links Land in the Wrong Paragraph"

- **Root cause:** The variant is chosen at runtime by the `theme_variant` cookie on a statically generated site. The web fonts also load asynchronously. Together, these change line height and glyph metrics *after* the browser has already scrolled to a `#fragment` anchor.
- **Chain of consequences:**
  1. An engineer clicks a Slack link such as `…/config-reference#retry-backoff`.
  2. The browser scrolls to the anchor using fallback-font metrics.
  3. About 150 ms later, the web fonts swap in and line height applies at 1.55. Every line above the anchor grows, and on a long reference page the target heading moves several screen-heights down.
  4. The engineer lands on the wrong config key's documentation. On a page of near-identical options, they copy the wrong default value.
  5. This went unnoticed in the 50-page check because those renders loaded pages from the top, not through deep links on a cold cache.
- **Observable outcome:** Reports in #devdocs like "links to sections don't work anymore." Field data shows elevated Cumulative Layout Shift on long reference pages. The bug only reproduces on a first visit or a hard refresh, so it is intermittent.
- **Plausibility:** Plausible
- **Severity:** Low
- **Mitigation:** In `theme/typography.css`, set `font-display: optional` or `swap`, and add `size-adjust` / `ascent-override` on the `@font-face` rules so the fallback metrics match the new fonts. Add `<link rel="preload" as="font" crossorigin>` for the two primary font files in the page template. Add "cold-cache deep link into a 3,000-line reference page" to the preview test checklist.

### 5. "Someone Else Was Importing `typography.css`"

- **Root cause:** `theme/typography.css`, or the font files in the shared static-assets bucket, are also consumed by something outside the docs site. Examples include an internal developer portal, an IDE plugin's embedded docs webview, or a status page that pulled in the docs theme years ago. The proposal's "no content, URLs, search index, or navigation changes" covers only the docs site itself.
- **Chain of consequences:**
  1. The default flip, or the clean-up, changes the font stack or deletes the files.
  2. The embedding consumer is on another origin and has no `theme_variant` cookie. It either changes typography without its owners' knowledge, which breaks its fixed-height layouts, or it hits CORS failures and 404s fetching the fonts from the bucket.
  3. The owning team files a bug against itself, spends half a day bisecting, and eventually traces it to DevEx.
- **Observable outcome:** Static-assets bucket access logs show requests for the font files or `typography.css` with `Referer` or `Origin` headers that are not the docs site. A ticket arrives from another team about "sudden font changes."
- **Plausibility:** Unlikely-but-catastrophic (<10%). Severity is not catastrophic; the label reflects that this is unlikely and hard to see in advance.
- **Severity:** Low
- **Revisit trigger:** Before Rollout §2, and again before §3, query the static-assets bucket access logs for the past 30 days. Look for any request to `typography.css` or the current font files whose `Referer`/`Origin` is not the docs site's host. Any non-zero count means you must contact that consumer before proceeding.

---

## Recommendations

**Must address before proceeding:** None. No narrative justifies blocking the two-week preview. The preview is cookie-gated, opt-in, reversible in minutes, and has no state. **Approve the preview as requested.**

**Worth mitigating (cheap, do before the relevant step):**

- **Before Rollout §2 (default flip):**
  - Replace "neutral or positive" with a minimum-sample criterion and a forced-exposure window (#1). This costs very little and keeps the decision from resting on a misleading signal.
  - Run the non-ASCII code-block grep and render those pages (#2).
  - Add the `@font-face` metric overrides and the font preload (#4).
- **Before Rollout §3 (clean-up):**
  - Treat this as the riskiest step in the plan. It is the point where the Rollback section's "one-line change" guarantee stops being true.
  - Gate it on a repo-wide grep for old font filenames and a test PDF export (#3).
  - Check the bucket access logs for external consumers (#5).
  - Confirm bucket versioning is enabled.
  - Consider amending the Rollback section to say plainly that it applies only through the end of step 2.

**Acknowledged risks:**

- Taste disagreement after the flip. Some engineers will prefer the old face no matter what. The month-long cookie fallback in Rollout §2 is an adequate pressure valve, and making the fallback permanent for a typography preference is not worth the added maintenance.
- The 96 KB first-load cost is negligible for an internal audience that loads the site on corporate networks and caches the fonts afterwards.
