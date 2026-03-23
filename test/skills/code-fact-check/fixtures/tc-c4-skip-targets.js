// Test fixture for TC-C4.1 through TC-C4.4: Comments that should NOT be checked

// TC-C4.1: Design rationale (opinion) — should be skipped
// this approach is simpler than using a state machine

// TC-C4.2: TODO/HACK comments — should be skipped
// TODO: refactor this into a proper class
// HACK: temporary fix until the upstream library patches the issue

// TC-C4.3: License header — should be skipped
// Copyright 2024 Example Corp. Licensed under the Apache License, Version 2.0.
// You may not use this file except in compliance with the License.

// TC-C4.4: Trivial restatement — should be skipped
let counter = 0;
counter += 1; // increment counter

function noop() {
  return null; // returns null
}

module.exports = { counter, noop };
