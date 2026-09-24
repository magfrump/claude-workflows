Tallyboard is a B2B dashboard for warehouse managers. We want counts on the dashboard (orders waiting, pickers active, trucks at the dock) to update live instead of on page refresh. Options we've discussed:

- WebSockets through our existing load balancer
- Server-Sent Events (SSE)
- long polling
- short polling every 15 seconds

Facts:

- About 30% of our customers' sites sit behind corporate HTTP proxies that strip the `Upgrade` header. Our support team confirmed this on a failed chat-widget rollout last spring, when WebSocket connections silently never opened for those sites.
- Updates only flow server-to-client; the dashboard sends nothing back except page navigation.
- Freshness target: a change should appear within 5 seconds.
- We have about 4,000 concurrently open dashboards at peak, served by a Node backend.

What should we build?
