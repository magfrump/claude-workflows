// Test case: Controls that disappear after completion
// A button is conditionally rendered based on status — it disappears
// when the task is complete, leaving no way to re-run.
//
// Expected finding: Minor — button should update label instead of disappearing

import React, { useState } from "react";

export function TaskRunner() {
  const [status, setStatus] = useState<"idle" | "running" | "done">("idle");

  return (
    <div className="p-4 space-y-4">
      <h3 className="font-bold">Task Runner</h3>
      <div className="border p-4 rounded">
        <p>Task output appears here...</p>
      </div>
      {/* BUG: Button disappears when done — should show "Re-run" instead */}
      {status !== "done" && (
        <button
          onClick={() => setStatus("running")}
          className="py-2 px-4 bg-blue-500 text-white rounded"
        >
          {status === "running" ? "Running..." : "Run Task"}
        </button>
      )}
      {status === "done" && (
        <p className="text-green-600">Complete!</p>
      )}
    </div>
  );
}
