// Stub Lean verifier for code-fact-check r2. Mode via argv: "error500" | "invalid".
const http = require("http");
const mode = process.argv[2] || "error500";
http
  .createServer((req, res) => {
    let body = "";
    req.on("data", (c) => (body += c));
    req.on("end", () => {
      if (mode === "error500") {
        res.writeHead(500, { "Content-Type": "application/json" });
        res.end(JSON.stringify({ error: "stub internal error" }));
      } else {
        res.writeHead(200, { "Content-Type": "application/json" });
        res.end(JSON.stringify({ valid: false, errors: "stub: unsolved goals" }));
      }
    });
  })
  .listen(4461, "127.0.0.1", () => console.log("stub up mode=" + mode));
