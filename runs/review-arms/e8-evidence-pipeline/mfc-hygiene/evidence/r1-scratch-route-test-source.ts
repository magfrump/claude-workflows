// Archived copy of the scratch test run as app/api/edit/artifact/__r1scratch.route.test.ts
// (deleted from the clone after the run; output: r1-redaction-scratch-tests.txt)
import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";

vi.mock("@/app/lib/llm/callLlm", async (importOriginal) => {
  const orig = await importOriginal<typeof import("@/app/lib/llm/callLlm")>();
  return {
    ...orig,
    callLlm: vi.fn(async () => ({
      text: "USER_SOURCE_MATERIAL not json ".repeat(30), // 900 chars, invalid JSON
      usage: {
        provider: "openrouter",
        model: "m",
        inputTokens: 1,
        outputTokens: 1,
        costUsd: 0,
        latencyMs: 0,
      },
    })),
  };
});

let errorSpy: ReturnType<typeof vi.spyOn>;
beforeEach(() => {
  errorSpy = vi.spyOn(console, "error").mockImplementation(() => {});
});
afterEach(() => {
  errorSpy.mockRestore();
});

describe("edit/artifact invalid-JSON handling", () => {
  it("logs only the char count; response 502 carries a 500-char details slice", async () => {
    const { POST } = await import("./route");
    const { NextRequest } = await import("next/server");

    const req = new NextRequest("http://localhost:4600/api/edit/artifact", {
      method: "POST",
      body: JSON.stringify({ content: "{\"a\":1}", instruction: "edit it" }),
      headers: { "Content-Type": "application/json" },
    });

    const res = await POST(req);
    expect(res.status).toBe(502);
    const body = await res.json();
    console.log("CAPTURED-RESPONSE-BODY:", JSON.stringify(body).slice(0, 200));
    expect(body.error).toBe("LLM response was not valid JSON");
    expect(body.details.length).toBe(500);
    expect(body.details).toContain("USER_SOURCE_MATERIAL");

    const logged = errorSpy.mock.calls.map((c) => c.join(" ")).join("\n");
    console.log("CAPTURED-LOG-ROUTE:", JSON.stringify(logged));
    expect(logged).toContain("[edit/artifact] LLM returned invalid JSON: 900 chars");
    expect(logged).not.toContain("USER_SOURCE_MATERIAL");
  });
});
