// Probe for perf submitted claim: does per-call `new Anthropic({apiKey})`
// open a fresh TCP/TLS connection per call, or share a process-global
// connection pool?  Determined by (A) transport-binding reference identity
// in the SDK, and (B) a live localhost keep-alive socket-reuse demonstration
// through the exact same global fetch the clients use. No external network.
import Anthropic from '@anthropic-ai/sdk';
import http from 'node:http';

const line = (s) => console.log(s);

// ---- Part A: reference identity of the transport binding ----
const c1 = new Anthropic({ apiKey: 'key-A' });
const c2 = new Anthropic({ apiKey: 'key-B' });

line('== Part A: SDK transport binding (per-instance vs shared) ==');
line('c1.fetch === c2.fetch                  : ' + (c1.fetch === c2.fetch));
line('c1.fetch === globalThis.fetch          : ' + (c1.fetch === globalThis.fetch));
line('c2.fetch === globalThis.fetch          : ' + (c2.fetch === globalThis.fetch));
line('c1.fetchOptions (per-client dispatcher): ' + JSON.stringify(c1.fetchOptions ?? null));
line('c2.fetchOptions (per-client dispatcher): ' + JSON.stringify(c2.fetchOptions ?? null));
line('c1.apiKey !== c2.apiKey (distinct keys): ' + (c1.apiKey !== c2.apiKey));

// ---- Part B: live localhost keep-alive socket reuse through global fetch ----
// Each Anthropic client's `.fetch` IS globalThis.fetch (shown above), so the
// pooling behavior of the clients is exactly the pooling behavior of the one
// global fetch. Count distinct TCP sockets the server sees across requests
// issued through two different client instances' .fetch.
const sockets = new Set();
const server = http.createServer((req, res) => {
  res.setHeader('Connection', 'keep-alive');
  res.end('ok');
});
server.keepAliveTimeout = 5000;

await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
const port = server.address().port;
server.on('connection', (s) => sockets.add(s));

const url = `http://127.0.0.1:${port}/`;
// Issue requests sequentially through the two different client instances' fetch.
for (let i = 0; i < 6; i++) {
  const f = (i % 2 === 0) ? c1.fetch : c2.fetch;
  const r = await f(url, { method: 'GET' });
  await r.text(); // drain body so the socket returns to the pool
}

line('');
line('== Part B: localhost keep-alive socket reuse (6 requests via c1.fetch/c2.fetch alternating) ==');
line('distinct server-observed TCP sockets   : ' + sockets.size);
line('(1 => connections pooled/reused process-globally across both clients; 6 => fresh connection per call)');

server.close();
