// Test case: Wrong shrink-0 vs flex-1 min-h-0 usage
// The content area uses shrink-0 (sizes to content, never shrinks) instead
// of flex-1 min-h-0 (fill remaining space). This causes the layout to
// stretch beyond the viewport when content is large.
//
// Expected finding: Major — content area should use flex-1 min-h-0, not shrink-0

import React from "react";

export function AppLayout() {
  return (
    <div className="flex flex-col h-screen">
      <header className="shrink-0 p-4 border-b">
        <h1 className="text-xl font-bold">App Title</h1>
      </header>
      {/* BUG: shrink-0 on content area — should be flex-1 min-h-0 */}
      <main className="shrink-0 p-6">
        <div className="space-y-4">
          <p>This content area will push the footer off screen when it grows.</p>
          <div className="overflow-auto">
            {/* Imagine a long list here */}
          </div>
        </div>
      </main>
      <footer className="shrink-0 p-4 border-t">
        <button className="py-2 px-4 bg-gray-800 text-white rounded">Save</button>
      </footer>
    </div>
  );
}
