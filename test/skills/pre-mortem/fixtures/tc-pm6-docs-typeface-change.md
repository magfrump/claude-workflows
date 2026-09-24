# Proposal: Switch the internal developer docs to a high-legibility typeface

**Owner:** Developer Experience team · **Audience:** internal staff only

## Summary

Our internal developer docs site (about 1,400 pages, read by roughly 300
engineers) uses a condensed sans-serif that several people have reported as
hard to read, especially for code identifiers where `l`, `1` and `I` look alike.
We propose switching body text to a high-legibility sans-serif and code blocks
to a monospace with distinct glyphs for those characters. Both fonts are open
source and self-hosted; nothing is loaded from a third-party CDN.

## Change

- One CSS file (`theme/typography.css`) changes the font stacks and adjusts line
  height from 1.4 to 1.55.
- Font files are added to the site's existing static-assets bucket.
- No content, URLs, search index, or navigation changes.

## Rollout

1. **Preview.** The change is behind the site's existing `theme_variant` cookie.
   Anyone can opt in from the footer. We will leave this on for two weeks and
   collect feedback in the #devdocs channel.
2. **Default.** If feedback is neutral or positive, flip the default. The old
   typography stays available through the same cookie for another month.
3. **Clean-up.** Remove the old font files and the cookie branch.

## Rollback

Flipping the default back is a one-line config change that deploys in under
five minutes, and the site is statically generated, so there is no state to
restore. Browser caches pick up the old CSS on the next page load because the
stylesheet URL is content-hashed.

## Checks already done

- Rendered the 50 most-visited pages in Chrome, Firefox and Safari at 100% and
  200% zoom; no layout breaks.
- Font files add 96 KB on first load, cached afterwards.
- Accessibility team reviewed contrast and glyph distinctness and approved.
- The print stylesheet and the PDF export use their own font settings and are
  unaffected.

## Decision requested

Approve the two-week preview.
