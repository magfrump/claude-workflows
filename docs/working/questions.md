# Running questions

Questions raised during autonomous work that did not justify stopping. Check off
with the answer inline; move lasting answers to `docs/decisions/` or `docs/thoughts/`.

- [ ] 2026-09-03 Does a long session survive OAuth access-token expiry with `platform.claude.com` newly in `base.txt`? · context: telemetry/base cleanup (finding 7) added it per the CC network-config docs; it was never in base yet logins worked, so it may be reachable via a Cloudflare IP already admitted · interim: added it (harmless if redundant) · answer changes: nothing to redo; if refresh fails after rebuild, the entry is the first thing to check.
- [ ] 2026-09-03 Does CC still attempt `sentry.io`/`statsig.com` with `DISABLE_ERROR_REPORTING=1` and both dropped from base? · context: finding 7 · interim: dropped them; any attempt now fails silently against default-deny · answer changes: if Remote Control or feature flags misbehave after rebuild, restore `statsig.com` first.
- [ ] 2026-09-03 Under Docker Engine on Linux, are any host ports other than 53 relied on today? · context: the bridge /24 accept was narrowed to gateway:53 and the ipset is now port-scoped (finding 5) · interim: none assumed; `host.docker.internal:11434` is the only host entry · answer changes: add `host:port` lines to the relevant profile.
- [ ] 2026-09-03 Should `GH_TOKEN` passthrough stay opt-in via host env, or move to a host-side credential broker now? · context: finding 3 · interim: opt-in env passthrough modeled on `OPENROUTER_API_KEY`, guide section written · answer changes: broker is a separate piece of work; the env entry would be removed.
