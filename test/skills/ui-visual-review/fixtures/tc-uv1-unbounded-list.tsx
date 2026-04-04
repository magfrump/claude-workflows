// Test case: Unbounded content without scroll caps
// A list container whose children can grow without limit but lacks
// max-height constraint and overflow handling.
//
// Expected finding: Critical — container needs max-h-* + overflow-auto

import React from "react";

interface Item {
  id: string;
  name: string;
}

export function ItemList({ items }: { items: Item[] }) {
  return (
    <div className="flex flex-col p-6">
      <h2 className="text-lg font-bold shrink-0">Items</h2>
      {/* BUG: No max-height or overflow — list pushes everything below it offscreen */}
      <div className="flex flex-col gap-4">
        {items.map((item) => (
          <div key={item.id} className="border p-4 rounded">
            {item.name}
          </div>
        ))}
      </div>
      <button className="mt-4 py-2 px-4 bg-blue-500 text-white rounded">
        Add Item
      </button>
    </div>
  );
}
