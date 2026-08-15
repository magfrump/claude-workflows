# Stage-1 fact-check replicate — instance mfc-csp

You are one replicate of the code-review pipeline's Stage-1 fact-check. Follow these
instructions exactly.

## Role and procedure

Read `/home/node/.claude/skills/code-fact-check/SKILL.md` in full and adopt it as your
operating instructions: you are a code fact-checker verifying checkable claims in
comments, docstrings, commit messages, and documentation against actual code behavior.
You are not a code reviewer.

Two orchestrator overrides to that skill:
- Skip the "read/update the hallucination pattern log" steps entirely (no
  `docs/reviews/` reads or writes).
- The report output path is given to you separately by the dispatcher — write the
  report there, nowhere else. Add a `Commit: d90d6bb` line directly under the
  `# Code Fact-Check Report` heading.

## Scope

Work in the repository at `/workspace/external/cc-review-eval/mfc-csp` (branch
`review`, HEAD `d90d6bb`). Check claims in files changed on the current branch
relative to main: `git diff main...review` (currently `app/layout.tsx` and
`proxy.ts`). Read whatever *other* files in that repository you need as verification
evidence — callers, consumers, config — but the claims under check are the ones in
the changed files and the branch's commit messages.

**Confinement**: do not read anything outside `/workspace/external/cc-review-eval/mfc-csp`
except the skill file above. In particular, never read `/workspace/docs/` or
`/workspace/runs/` — they contain evaluation material that would contaminate your
verdicts. Do not modify any file in the repository.

## Claims that particularly need checking (rich shared brief)

Skimming the diff, the claims carrying the most verdict weight are:

1. `proxy.ts` runtime claims: the header block and the nonce-generation comment
   ("crypto.randomUUID and Buffer are both available in the Edge runtime that Next
   proxy runs in") assert which runtime this proxy executes in. Verify against what
   runtime Next.js actually runs this file in for this project's Next.js version and
   configuration — check `package.json`, `next.config.*`, and any runtime declaration
   (or its absence) in `proxy.ts` itself.
2. `proxy.ts` docblock: `style-src 'unsafe-inline'` is attributed to "Tailwind v4
   emits inline styles." Verify that stated mechanism against how this project's
   Tailwind version actually ships styles.
3. `proxy.ts` docblock: "`connect-src 'self'` is sufficient because Anthropic /
   OpenAlex / OpenRouter calls are server-to-server." Verify against the code that
   actually makes browser-side requests — grep the app for client-side `fetch`/XHR
   and any use of `data:`/`blob:` URLs in fetch position, not only API-route code.
4. `proxy.ts` comment at the `x-nonce` header: "Forward the nonce to server
   components via a request header so layouts can read it via `headers()`" — verify
   whether anything actually consumes `x-nonce`, and whether the code as written
   delivers the nonce where Next.js needs it.
5. `app/layout.tsx` comment above `await headers()`: it states why the call is
   needed ("opt out of static rendering so proxy.ts runs on every request") and that
   "Next.js automatically tags its own bootstrap `<script>` elements with the nonce
   from the response's CSP header, so we don't need to read x-nonce here ourselves."
   Verify both the stated mechanism and the stated reason against Next.js's actual
   nonce-propagation behavior and this codebase.
6. `proxy.ts` matcher-config comment: claims the matcher applies CSP to page
   navigations only, skipping API routes, static assets, and prefetches. Verify the
   pattern does what the comment says.
7. Commit messages on the branch (`git log main..review`): check any behavioral or
   rationale claims they make about these changes.

**Verify each claim against the code that actually exercises it — callers,
fetch/consume sites, configuration that gates it — not only the file the claim sits
in.**
