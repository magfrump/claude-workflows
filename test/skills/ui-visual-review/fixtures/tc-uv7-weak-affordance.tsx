// Test case: Interactive elements with weak visual affordance
// Clickable elements that look like static text — no border, background,
// or cursor change to indicate interactivity.
//
// Expected finding: Minor — interactive elements need visible borders,
// backgrounds, or other affordances per WCAG 2.5.8 and NNGroup research

import React from "react";

interface Action {
  label: string;
  onClick: () => void;
}

export function ActionList({ actions }: { actions: Action[] }) {
  return (
    <div className="p-4 space-y-2">
      <h3 className="font-bold">Actions</h3>
      {actions.map((action, i) => (
        // BUG: Looks like plain text — no visual indicator of interactivity
        <div key={i} onClick={action.onClick} className="text-sm text-gray-600 py-1">
          {action.label}
        </div>
      ))}
    </div>
  );
}
