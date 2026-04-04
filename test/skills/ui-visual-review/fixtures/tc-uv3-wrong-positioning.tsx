// Test case: Absolute positioning anchored to wrong parent
// A floating action bar is absolute-positioned inside an outer wrapper
// that contains multiple sections, so it overlaps all sections instead
// of just its target.
//
// Expected finding: Major — FloatingBar should be inside SectionA with relative

import React from "react";

function SectionA({ children }: { children?: React.ReactNode }) {
  return (
    <div className="p-4 border-b">
      <h3 className="font-bold">Section A</h3>
      <p>Content for section A</p>
      {children}
    </div>
  );
}

function SectionB() {
  return (
    <div className="p-4">
      <h3 className="font-bold">Section B</h3>
      <p>Content for section B</p>
    </div>
  );
}

export function TwoSectionLayout() {
  return (
    // BUG: FloatingBar is absolute inside the outer relative div
    // It floats over both sections instead of just SectionA
    <div className="relative">
      <SectionA />
      <SectionB />
      <div className="absolute bottom-6 right-6 bg-white shadow-lg p-2 rounded">
        <button>Quick Action</button>
      </div>
    </div>
  );
}
