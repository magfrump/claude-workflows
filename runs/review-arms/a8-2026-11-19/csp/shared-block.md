# Review pass: shared context (identical for every agent in this pass)

User goal: A full code review (terminal pass, not a loop pass) of the change d86d2dc..d90d6bb in the meta-formalism-copilot repository, so the owner learns what is wrong with it before it ships.

The reviewed state is checked out at /tmp/claude-1000/-workspace/711f86df-792b-492f-9d5e-95022839ec2c/scratchpad/2026-11-19-a8-token-measurement/wt-csp (detached HEAD d90d6bb). Run git commands there (for example `git -C <that path> diff d86d2dc..d90d6bb`). Do not modify, commit or check out anything in that worktree; it is read-only for you. You may read any file in it, including files outside the diff (consumers, callers, config).

Rules for this pass:
- Complete-unit reading rule: before verdicting a claim or filing a finding about code inside a function or method, read the entire enclosing unit, signature to final line, explicitly including the lines after the last line the finding cites, plus the flow of any value the analyzed lines produce to its first point of use. Any quoted excerpt that ends inside its enclosing unit must carry a truncation marker naming the remainder (for example `excerpt ends :99; enclosing getClient() continues to :108 — read`).
- Probe-cleanup rule: any process you start (a sleep, a FIFO reader, a background script, a dev server) runs under `timeout` and is killed before you report. Do not install packages or use the network.

Scope: the full change d86d2dc..d90d6bb (3 commits, 2 files). The whole changeset is under review; no sibling work outside the scope.

## What this PR is trying to accomplish

Adds a strict Content-Security-Policy with per-request nonces via a Next.js 16 proxy (proxy.ts) as an XSS guardrail, and makes the root layout dynamic so the proxy runs on every request. Commits: "feat: add strict CSP with per-request nonces", "fix: correct layout comment to reference proxy.ts (renamed from middleware.ts)", "refactor: minor cleanup of CSP proxy and layout comment".

Commit message of 9b4e453 (verbatim body):

> The XSS surface in the app is already defensive (no dangerouslySetInnerHTML, no rehype-raw, KaTeX trust:false), so this is a guardrail, not a fix. CSP catches the regression where someone later adds rehype-raw for "render the LLM markdown more faithfully" and forgets that LLM output is user-derived.
>
> Implementation notes:
> - File is named proxy.ts because Next.js 16 renamed Middleware to Proxy (middleware.ts builds with a deprecation warning).
> - The matcher skips /api routes, _next/static, and prefetches so we don't burn nonces on requests that don't render HTML.
> - Layout reads headers() to opt out of static rendering — required because per-request nonces can't be cached.
> - style-src keeps 'unsafe-inline' as a deliberate carve-out for Tailwind v4. Documented in proxy.ts; tightening would require reworking how Tailwind ships styles in dev/SSR.
> - connect-src is just 'self' because all external API calls (Anthropic, OpenAlex, OpenRouter) go server-to-server, never browser-to-third-party.
>
> Verified prod build emits the CSP header and Next applies the nonce to every <script> tag it generates. Manual end-to-end browser verification on the Vercel preview is still recommended — CSP issues sometimes only appear once Next's full bootstrap is exercised.

Commit message of d90d6bb (verbatim body):

> - proxy.ts: add explicit return type, inline single-use csp local.
> - layout.tsx: correct comment — headers() is called to opt out of static rendering so the proxy can attach per-request CSP, not to read x-nonce (the nonce is only written, never read by the layout).
>
> No behavior change; CSP directives preserved exactly. Lint clean; 221/221 tests pass.

## The diff (git diff d86d2dc..d90d6bb)

```diff
diff --git a/app/layout.tsx b/app/layout.tsx
index f030594..b298276 100644
--- a/app/layout.tsx
+++ b/app/layout.tsx
@@ -1,5 +1,6 @@
 import type { Metadata } from "next";
 import { EB_Garamond, Geist_Mono } from "next/font/google";
+import { headers } from "next/headers";
 import "./globals.css";
 import "katex/dist/katex.min.css";
 
@@ -18,11 +19,17 @@ export const metadata: Metadata = {
   description: "Two-panel interface for input and AI-assisted output editing",
 };
 
-export default function RootLayout({
+export default async function RootLayout({
   children,
 }: Readonly<{
   children: React.ReactNode;
 }>) {
+  // Opt this layout out of static rendering so proxy.ts runs on every request
+  // and can attach a fresh per-request CSP nonce. Next.js automatically tags
+  // its own bootstrap <script> elements with the nonce from the response's
+  // CSP header, so we don't need to read x-nonce here ourselves.
+  await headers();
+
   return (
     <html lang="en">
       <body
diff --git a/proxy.ts b/proxy.ts
new file mode 100644
index 0000000..7846572
--- /dev/null
+++ b/proxy.ts
@@ -0,0 +1,64 @@
+import { NextResponse } from "next/server";
+import type { NextRequest } from "next/server";
+
+/**
+ * CSP proxy (Next.js 16 renamed Middleware → Proxy) with per-request nonces.
+ *
+ * Why nonces + 'strict-dynamic': only scripts that Next.js has explicitly
+ * tagged with the nonce can run, and any scripts they load inherit trust.
+ * This keeps a hypothetical injected `<script>` tag from executing even if
+ * something slipped past markdown sanitization.
+ *
+ * Why `style-src 'unsafe-inline'`: Tailwind v4 emits inline styles. Tightening
+ * to nonces would require rebuilding how Tailwind ships styles in dev and
+ * SSR. Documented as a deliberate carve-out, not an oversight.
+ *
+ * `connect-src 'self'` is sufficient because Anthropic / OpenAlex / OpenRouter
+ * calls are server-to-server (Next API routes), not browser-to-third-party.
+ */
+function buildCsp(nonce: string): string {
+  const directives = [
+    "default-src 'self'",
+    `script-src 'self' 'nonce-${nonce}' 'strict-dynamic'`,
+    "style-src 'self' 'unsafe-inline'",
+    "img-src 'self' data: blob:",
+    "font-src 'self' data:",
+    "connect-src 'self'",
+    "frame-ancestors 'none'",
+    "base-uri 'self'",
+    "object-src 'none'",
+  ];
+  return directives.join("; ");
+}
+
+export function proxy(request: NextRequest): NextResponse {
+  // Generate a fresh nonce per request. crypto.randomUUID and Buffer are both
+  // available in the Edge runtime that Next proxy runs in.
+  const nonce = Buffer.from(crypto.randomUUID()).toString("base64");
+
+  // Forward the nonce to server components via a request header so layouts
+  // can read it via `headers()` and pass it to <Script> tags they render.
+  const requestHeaders = new Headers(request.headers);
+  requestHeaders.set("x-nonce", nonce);
+
+  const response = NextResponse.next({
+    request: { headers: requestHeaders },
+  });
+  response.headers.set("Content-Security-Policy", buildCsp(nonce));
+  return response;
+}
+
+export const config = {
+  // Apply CSP to page navigations only. Skip API routes (they don't render
+  // HTML), Next's static assets (no scripts to nonce), and prefetches (which
+  // would otherwise burn a nonce on a request that may never paint).
+  matcher: [
+    {
+      source: "/((?!api|_next/static|_next/image|favicon.ico).*)",
+      missing: [
+        { type: "header", key: "next-router-prefetch" },
+        { type: "header", key: "purpose", value: "prefetch" },
+      ],
+    },
+  ],
+};
```

## Enclosing-file context (post-change contents of the files the diff touches)

proxy.ts is a new file; its full post-change content is the diff above.

app/layout.tsx at d90d6bb:

```tsx
import type { Metadata } from "next";
import { EB_Garamond, Geist_Mono } from "next/font/google";
import { headers } from "next/headers";
import "./globals.css";
import "katex/dist/katex.min.css";

const ebGaramond = EB_Garamond({
  variable: "--font-eb-garamond",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "Meta-Formalism Copilot",
  description: "Two-panel interface for input and AI-assisted output editing",
};

export default async function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  // Opt this layout out of static rendering so proxy.ts runs on every request
  // and can attach a fresh per-request CSP nonce. Next.js automatically tags
  // its own bootstrap <script> elements with the nonce from the response's
  // CSP header, so we don't need to read x-nonce here ourselves.
  await headers();

  return (
    <html lang="en">
      <body
        className={`${ebGaramond.variable} ${geistMono.variable} font-serif antialiased`}
      >
        {children}
      </body>
    </html>
  );
}
```
