// Test case: overflow-hidden silently clipping content
// A container uses overflow-hidden which silently clips content rather
// than making it scrollable.
//
// Expected finding: Major — overflow-hidden should be overflow-auto
// so users can see clipped content

import React from "react";

export function ErrorDisplay({ errors }: { errors: string[] }) {
  return (
    <div className="p-4">
      <h3 className="font-bold mb-2">Errors</h3>
      {/* BUG: overflow-hidden clips errors silently — user can't see all errors */}
      <div className="h-32 overflow-hidden bg-red-50 border border-red-200 rounded p-2">
        {errors.map((err, i) => (
          <p key={i} className="text-red-700 text-sm">{err}</p>
        ))}
      </div>
    </div>
  );
}
