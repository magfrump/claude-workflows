// Test case: Controls trapped inside a scroll container
// The submit button is inside an overflow-auto container, so it scrolls
// away when content is long.
//
// Expected finding: Critical — button must be moved outside the scroll container

import React from "react";

export function FormPanel({ children }: { children: React.ReactNode }) {
  return (
    <div className="h-full">
      {/* BUG: Button is inside the scrollable area — scrolls out of view */}
      <div className="overflow-auto h-full p-6">
        <h2 className="text-lg font-bold">Form</h2>
        {children}
        <div className="mt-8 space-y-4">
          <textarea className="w-full border p-2" rows={8} />
          <textarea className="w-full border p-2" rows={8} />
          <textarea className="w-full border p-2" rows={8} />
        </div>
        <button className="mt-4 py-3 px-6 bg-blue-600 text-white font-semibold rounded">
          Submit
        </button>
      </div>
    </div>
  );
}
