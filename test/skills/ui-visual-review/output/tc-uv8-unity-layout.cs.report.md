# UI Visual Review: `InventoryPanel` (subject.cs)

**Scope:** `subject.cs` (single file, Unity uGUI)
**Date:** 2026-11-20
**Based on:** No code-fact-check report was provided, so this review uses code analysis only. The file's header comment states an "Expected finding". I did my own analysis and didn't take that comment as given.

## Environment

- **Files reviewed:** `subject.cs`
- **Project guidelines:** None found. The repo has no `docs/UI_LAYOUT_GUIDELINES.md` or other `.md` files.
- **Target viewports:** Small mobile (320–480 px wide), tablet/small laptop (768–1024 px), large desktop (1920 px+), plus 1366×768.
- **Target browsers / platforms:** Unity uGUI on any player resolution. The `CanvasScaler` mode and the scene/prefab setup aren't visible from this file.
- **Review mode:** Full audit

> **Limitation:** In Unity, much of the layout lives in the scene or prefab: anchors, `CanvasScaler`, `LayoutGroup`, `ContentSizeFitter`, `Mask`, and Button transitions. This review covers what the C# code does to the layout. Where an outcome depends on inspector settings, the finding says so and its confidence is lowered.

---

## Findings

#### 1. Submit button is moved into the scroll content, so growing inventory pushes it out of view

**Severity:** Critical
**Location:** `subject.cs:25`
**Issue type:** Positioning
**Viewport:** All
**Move:** Step 2 item 2 (controls trapped inside scroll containers), plus item 4 (wrong anchoring parent)
**Confidence:** High

`submitButton.transform.SetParent(scrollRect.content)` makes the panel's main action a child of the scrolling content. As items are added (`AddItem`, line 31), the content gets taller than the 400-unit viewport. The button then scrolls out of the masked viewport and is clipped. The user has to discover that they need to scroll to the end to finish the task. Under this skill's severity rules, a main action that growing content pushes out of view is Critical even if scrolling can reach it.

Three things make it worse:

- **If `itemContainer` is the same object as `scrollRect.content`:** `Instantiate` appends each new item as the last sibling. The button then ends up in the middle of the list, above the newer items, not at the bottom.
- **`SetParent(parent)` keeps world position by default** (`worldPositionStays = true`). For UI, that can leave the button with an unexpected `localPosition` and `localScale` under its new parent. Unity's docs recommend `SetParent(parent, false)` for UI elements.
- **The button's anchors now refer to the content RectTransform,** whose size changes with the item count. Any anchoring the designer set up against the original parent stops meaning what it did.

**Recommendation:** Don't reparent the button. Use a docked footer that sits outside the scroll region, the uGUI version of the two-layer pattern.

```csharp
// BEFORE
submitButton.transform.SetParent(scrollRect.content);

// AFTER — delete the reparent. Build the hierarchy in the prefab:
// InventoryPanel  (VerticalLayoutGroup, childControlHeight = true, childForceExpandHeight = false)
// ├── ScrollView  (ScrollRect + LayoutElement { flexibleHeight = 1, minHeight = 120 })
// │   └── Viewport (RectMask2D)
// │       └── Content = itemContainer (VerticalLayoutGroup + ContentSizeFitter.verticalFit = PreferredSize)
// └── Footer      (LayoutElement { preferredHeight = 64, flexibleHeight = 0 })   // "shrink-0"
//     └── SubmitButton
```

If the reparent has to stay in code for some reason, at least call `SetParent(footer, false)` so it targets a non-scrolling parent and doesn't keep world position.

**Tradeoff:** The footer always takes about 64 units of height, even when the list is short.

---

#### 2. `sizeDelta = (500, 400)` in `Start()` overrides the authored layout and can overflow the screen

**Severity:** Major
**Location:** `subject.cs:19-21`
**Issue type:** Sizing / Responsive
**Viewport:** Depends on scaler setup. Under Constant Pixel Size, it overflows at widths ≤ 500 px and looks undersized at 1920 px+. At any resolution, it oversizes if the anchors are stretched.
**Move:** Step 2 item 7 (fixed dimensions), plus item 3 (fill vs. size-to-content)
**Confidence:** Medium

What `sizeDelta` means depends on the anchors. The comment on line 18 is only partly right:

- **Point anchors, `CanvasScaler` set to Constant Pixel Size:** the panel is a fixed 500×400 px. It won't fit a 320–480 px wide portrait phone, so it gets cut off horizontally. On a 1920×1080 or 4K display it's a small box in a large empty area.
- **Point anchors, Scale With Screen Size:** it scales with the screen. It still keeps a fixed 5:4 aspect, though, so it can't use extra height on tall phones or extra width on ultrawide screens.
- **Stretched anchors** (common for scroll views): `sizeDelta` is a size *relative to the parent*. `(500, 400)` makes the panel **500 units wider and 400 units taller than its parent**, so it overflows at every resolution.

Setting the size at runtime also silently overrides whatever the designer set in the inspector, so the code and the prefab disagree with each other.

**Recommendation:** Remove the runtime sizing. Let the ScrollView fill the leftover space in the panel (`LayoutElement.flexibleHeight = 1`, as in Finding 1). If code must set the size, use anchors and offsets.

```csharp
// BEFORE
rt.sizeDelta = new Vector2(500, 400);

// AFTER — fill parent with margins; footer space handled by the layout group
rt.anchorMin = Vector2.zero;
rt.anchorMax = Vector2.one;
rt.offsetMin = new Vector2(16, 16);
rt.offsetMax = new Vector2(-16, -16);
```

Pair this with a `CanvasScaler` set to Scale With Screen Size (e.g., reference 1920×1080, Match ≈ 0.5). To avoid an oversized panel on large desktops, put the panel inside a parent sized with `LayoutElement.preferredWidth`, or use an `AspectRatioFitter`.

**Tradeoff:** A stretched panel looks more sparse on very large screens unless you add a max-width-style container.

---

#### 3. Content height may not grow, so items beyond the viewport can't be scrolled to

**Severity:** Major
**Location:** `subject.cs:28-32` (together with `itemContainer` on line 13)
**Issue type:** Overflow
**Viewport:** All, once the items are taller than 400 units
**Move:** Step 2 item 1 (unbounded content without scroll caps)
**Confidence:** Low (this depends on the prefab)

The comment on line 30 ("no cap on content height") reads the problem backwards. The ScrollRect's 400-unit viewport *is* the cap. The real risk is the reverse: a ScrollRect only scrolls as far as its `content` RectTransform's bounds. Two setups would break it:

- **No `ContentSizeFitter` + `LayoutGroup` on the content:** the content rect stays at its authored size. Items spill past it, the mask clips them, and the user can't scroll to them, even though they exist.
- **`itemContainer` isn't `scrollRect.content`:** these are two separately serialized references, and nothing checks that they match. Items would then be added outside the scroll view entirely and have no bounds at all.

**Recommendation:** Make the content grow with its items, and catch a mismatched reference early.

```csharp
void Awake()
{
    var scrollRect = GetComponent<ScrollRect>();
    Debug.Assert(itemContainer == scrollRect.content,
        "itemContainer must be the ScrollRect content so items are scrollable", this);
}
```

On the content object, add `VerticalLayoutGroup` (`childControlHeight = true`) and `ContentSizeFitter` (`verticalFit = PreferredSize`). On the ScrollRect, set the vertical scrollbar to **Auto Hide And Expand Viewport** so the scrollbar is visible exactly when the content overflows.

---

#### 4. With controller or keyboard navigation, the selection can go to off-screen items and the view doesn't follow

**Severity:** Major
**Location:** `subject.cs:25`, `subject.cs:31`
**Issue type:** Focus
**Viewport:** All (controller and keyboard input)
**Move:** Step 2 item 8 (state matrix: focus), plus Keyboard Navigation
**Confidence:** Medium

uGUI's `ScrollRect` doesn't scroll to keep the `EventSystem.current.currentSelectedGameObject` in view. With the button in the scroll content (Finding 1), arrowing down can select the masked, invisible Submit button. Any selectable inventory items have the same problem. This fails WCAG 2.4.11 (Focus Not Obscured), and the user can't see what pressing Submit will act on.

**Recommendation:** Fixing Finding 1 takes care of the button. For selectable items, add a small script that scrolls the selected item into view.

```csharp
void LateUpdate()
{
    var sel = EventSystem.current?.currentSelectedGameObject;
    if (sel == null || !sel.transform.IsChildOf(scrollRect.content)) return;
    var item = (RectTransform)sel.transform;
    var vp = scrollRect.viewport;
    Vector3[] c = new Vector3[4]; item.GetWorldCorners(c);
    Vector3[] v = new Vector3[4]; vp.GetWorldCorners(v);
    float delta = 0f;
    if (c[0].y < v[0].y) delta = v[0].y - c[0].y;      // below viewport
    else if (c[1].y > v[1].y) delta = v[1].y - c[1].y; // above viewport
    if (delta != 0f)
        scrollRect.content.position += new Vector3(0, delta, 0);
}
```

---

#### 5. `GetComponent<ScrollRect>()` isn't null-checked

**Severity:** Informational
**Location:** `subject.cs:19-20`
**Issue type:** Other
**Viewport:** All
**Move:** Step 2 item 1 (incidental)
**Confidence:** High

If the component is attached to an object without a `ScrollRect`, line 20 throws a `NullReferenceException`. Execution stops before line 25, so the button stays wherever it was authored. Failing silently like this leaves layout state that's hard to diagnose.

**Recommendation:** Add `[RequireComponent(typeof(ScrollRect))]` to the class. You can also use `(RectTransform)transform` instead of a second `GetComponent`.

---

## What Looks Good

- `itemContainer` and `submitButton` are `[SerializeField] private`, so designers can wire them in the inspector without exposing public state.
- Items are created with `Instantiate(prefab, parent)`, the parent overload. That avoids the world-position-stays problem for items, unlike the button reparent on line 25.
- Using a `ScrollRect` for a list that can grow without limit is the right structure. The bugs are in how it's configured, not in the choice.

## Best Practices Applied

| Principle | Source | How Applied |
|-----------|--------|-------------|
| Main actions stay outside scroll regions | Skill Step 2 item 2; NNGroup on visible primary actions | Submit moved to a docked footer (`LayoutElement.flexibleHeight = 0`) |
| Proportional sizing instead of fixed sizing | WCAG 1.4.10 Reflow (adapted); Unity UI anchor docs | Fixed `sizeDelta` replaced with stretched anchors and offsets, plus `CanvasScaler` Scale With Screen Size |
| Content bounds match the items they hold | Unity ScrollRect docs | `ContentSizeFitter` + `VerticalLayoutGroup` on the content; assert `itemContainer == content` |
| Visible scroll affordance | NNGroup; Affordance Principle 1 | Scrollbar visibility set to Auto Hide And Expand Viewport |
| The selected element is never hidden | WCAG 2.4.11 Focus Not Obscured | Scroll-to-selected script; button removed from the masked region |
| `SetParent(x, false)` for UI | Unity scripting API | Recommended for any remaining reparenting |

## Interactive Element State Matrix

- [ ] `submitButton` (`subject.cs:14`, changed at `:25`)
  - [?] default: set by the Button's Target Graphic in the prefab. This file can't show it. Once moved, it's also clipped whenever it's outside the viewport mask.
  - [?] hover: controlled by Button `Transition` (Color Tint / Sprite Swap) in the inspector. Unverifiable here.
  - [ ] focus: the `Selected` color/sprite comes from the inspector. It can't be seen when the button sits off-screen inside the masked content (Finding 4).
  - [?] active: the `Pressed` transition is in the inspector. Unverifiable.
  - [?] disabled: the code never sets `interactable`. You'd expect Submit to be disabled while the inventory is empty, so check that the `Disabled` color is clearly dimmed.
  - [N/A] error: a button isn't a validated control.

## Keyboard Navigation

**Focus order.** uGUI uses `Navigation.Automatic` by default, which is spatial, not based on the hierarchy. In-scope selectables:
1. Inventory items (`subject.cs:31`), if the prefab has a `Selectable`. They're reachable by up/down navigation, but they can be off-screen (Finding 4).
2. `submitButton` (`subject.cs:25`). Spatially it sits wherever it lands among the items. If `itemContainer == content`, it's *between* older and newer items, so the navigation order doesn't match the reading order you'd expect (Submit last). That's a WCAG 2.4.3 concern. The docked footer fixes it: Submit becomes the last navigation stop below the list.

**Escape-key behavior.** N/A. The file has no modal or overlay dismiss logic. If `InventoryPanel` opens as an overlay elsewhere, Cancel/Escape handling needs to be checked there.

**Skip-link presence.** N/A. This diff doesn't change page-level structure, and skip links don't apply to Unity uGUI.

**Focus-trap risks.** No hard trap found: navigation can still leave the list. The risk is *selection that can't be seen*. Controller users can select the masked Submit button and activate it without seeing it (Finding 4).

## Viewport Verification Checklist

- [ ] 360 px mobile: **fails** under Constant Pixel Size or point anchors, because the 500-unit-wide panel is cut off horizontally (Finding 2).
- [ ] 1366×768: **fails** once the inventory overflows the 400-unit viewport, because Submit is scrolled away (Finding 1).
- [ ] 1920×1080: **marginal.** Under Constant Pixel Size, a fixed 500×400 panel leaves lots of empty space. Under Scale With Screen Size it's acceptable.

## Summary Table

| # | Finding | Severity | Issue type | Location | Confidence |
|---|---------|----------|------------|----------|------------|
| 1 | Submit button moved into scroll content and scrolls away | Critical | Positioning | `subject.cs:25` | High |
| 2 | Hard-coded `sizeDelta` overrides layout; overflows with stretched anchors or narrow screens | Major | Sizing / Responsive | `subject.cs:19-21` | Medium |
| 3 | Content may not grow or may not be the scroll content, so items can't be reached | Major | Overflow | `subject.cs:28-32` | Low |
| 4 | Selection goes to off-screen items and the view doesn't follow | Major | Focus | `subject.cs:25,31` | Medium |
| 5 | No `RequireComponent` or null check for `ScrollRect` | Informational | Other | `subject.cs:19-20` | High |

## Overall Assessment

The panel has a structural layout problem, not a cosmetic one. The code takes over layout decisions at runtime that belong to the uGUI layout system. It forces a fixed size and moves the main action into the region that scrolls. Both problems can be fixed in place by deleting lines 21 and 25 and building a vertical layout of a flexible ScrollView over a fixed-height footer in the prefab. Most important: **take the Submit button out of `scrollRect.content` and dock it in a footer outside the scroll view.** That fixes the Critical finding, the navigation-order mismatch, and most of the hidden-selection risk at once.
