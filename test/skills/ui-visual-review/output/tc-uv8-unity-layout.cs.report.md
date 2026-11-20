# UI Visual Review: `subject.cs` (InventoryPanel)

**Scope:** `subject.cs` (the user asked for a full audit)
**Date:** 2026-11-20
**Based on:** Reading the code only. No code-fact-check report was provided. The file's header comments say what the expected findings are. I treated those as claims to check, not as conclusions to copy (see Finding 2).

## Environment

- **Files reviewed:** `subject.cs`
- **Target viewports:** Small mobile (320–480 px), tablet or small laptop (768–1024 px), large desktop (1920 px and up), plus 1366×768. There are no Player Settings, so I couldn't read the project's real target resolutions.
- **Target platforms:** Unity uGUI (`UnityEngine.UI`). The Canvas and `CanvasScaler` settings aren't in scope.
- **Review mode:** Full audit (checklist items 1–8 and 11). Item 9 (3D) doesn't apply. Item 10 maps to Unity Selectable navigation.
- **Project-local guidelines:** None found (there are no `.md` files in the repo).

## Findings

#### 1. Submit button is moved inside the scroll content, so it scrolls away and can be clipped

**Severity:** Critical
**Location:** `subject.cs:23-25`
**Issue type:** Positioning
**Viewport:** All. It shows up as soon as the item list is taller than the 400-unit viewport.
**Move:** Step 2 item 2 (controls trapped inside scroll containers)
**Confidence:** High

`submitButton.transform.SetParent(scrollRect.content)` makes the panel's main action part of the scrolling content. Once the inventory is taller than the viewport, the button scrolls out of view. The ScrollRect's viewport `Mask`/`RectMask2D` then clips it, so the user has to scroll to find the one action they came to do. This is the Unity version of the "button inside `overflow-auto`" anti-pattern.

There are three more problems in the same lines:
- **Wrong sibling order.** If `itemContainer` is the same object as `scrollRect.content` (likely), every `AddItem` call puts the new item *after* the button. `Instantiate` adds it as the last sibling. Under a `VerticalLayoutGroup`, the Submit button sinks toward the top of the list, between old and new items, instead of staying at the end.
- **Overlap.** If `itemContainer` is a different object from the content, or the content has no layout group, the button keeps its old position and can sit on top of items (item 11: unintended occlusion).
- **Wrong `SetParent` form.** `SetParent(parent)` defaults to `worldPositionStays = true`. Unity's documentation recommends `SetParent(parent, false)` for UI elements, because keeping world position can leave strange local position and scale values under a scaled Canvas.

**Recommendation:** Don't reparent the button. Make the button and the ScrollRect siblings under one parent that has a `VerticalLayoutGroup`. The ScrollRect fills the leftover space and the button keeps a fixed height and stays docked. This is the uGUI equivalent of using `flex-1 min-h-0` for the list and `shrink-0` for the footer.

```csharp
// BEFORE
submitButton.transform.SetParent(scrollRect.content);

// AFTER — do not reparent; set up the hierarchy in the prefab:
// InventoryPanel (VerticalLayoutGroup, childControlHeight = true, childForceExpandHeight = false)
// ├── ScrollRect      (LayoutElement: flexibleHeight = 1, minHeight = 0)
// │   └── Viewport (RectMask2D) → Content (VerticalLayoutGroup + ContentSizeFitter: Vertical = PreferredSize)
// └── Footer          (LayoutElement: preferredHeight = 64, flexibleHeight = 0)
//     └── SubmitButton
```

**Tradeoff:** The docked footer always takes up about 64 units of panel height, even when the list is short.

#### 2. Fixed `sizeDelta` (500×400) set at runtime overrides the authored layout and won't adapt to the screen

**Severity:** Major. The header comment calls this Critical. How bad it really is depends on `CanvasScaler` settings that aren't in scope (see below).
**Location:** `subject.cs:18-21`
**Issue type:** Responsive / Sizing
**Viewport:** Small mobile and portrait phones are hit hardest. Large desktops get a small, centered panel.
**Move:** Step 2 item 7 (fixed dimensions) and item 4 (anchoring)
**Confidence:** Medium

`rt.sizeDelta = new Vector2(500, 400)` silently replaces whatever anchors and size were set in the Inspector. The effect depends on the anchors and the Canvas setup:
- **Point anchors with `CanvasScaler` set to Constant Pixel Size:** the panel is 500×400 physical pixels everywhere. That's wider than a 480 px-wide screen, so it gets cut off, and it looks tiny on 1920 px and above.
- **Stretched anchors:** `sizeDelta` is an *offset* from the parent's size, not a size. The panel becomes 500 units wider and 400 units taller than its parent, which pushes it off screen at every resolution.
- **`CanvasScaler` set to Scale With Screen Size:** the units scale with the screen, so the impact is smaller. But the panel still keeps a fixed 5:4 shape and never adjusts to a portrait or ultra-wide aspect ratio.

The value also overrides any `LayoutElement` or parent `LayoutGroup` sizing, which is why I scored this High-risk/Major even in the best case.

**Recommendation:** Delete the runtime sizing and set proportional anchors in the prefab. If it has to be done in code, use anchors instead of a size:

```csharp
// BEFORE
rt.sizeDelta = new Vector2(500, 400);

// AFTER — proportional to parent; or remove entirely and author in the prefab
rt.anchorMin = new Vector2(0.1f, 0.1f);
rt.anchorMax = new Vector2(0.9f, 0.9f);
rt.offsetMin = Vector2.zero;
rt.offsetMax = Vector2.zero;
```

Also use `CanvasScaler` with **Scale With Screen Size** and a set reference resolution and match value. To cap the width on desktop, add a `LayoutElement` with a preferred width, or a small script that clamps to `Mathf.Min(parentWidth * 0.9f, maxWidth)`.

#### 3. Keyboard or gamepad focus can land on the Submit button while it's scrolled out of view

**Severity:** Major
**Location:** `subject.cs:25`
**Issue type:** Focus
**Viewport:** All
**Move:** Step 2 item 8 (focus state) and item 10 (traversal)
**Confidence:** High

uGUI's `ScrollRect` does **not** scroll the selected Selectable into view automatically. When a gamepad or keyboard user moves to the reparented Submit button with automatic navigation, the button can be selected while it's clipped by the viewport mask, so the focus indicator can't be seen. That breaks WCAG 2.4.11 (Focus Not Obscured) and 2.4.7 (Focus Visible). Inventory screens are often used with a controller, which makes this more serious.

**Recommendation:** Fixing Finding 1 (docking the button outside the ScrollRect) removes this problem for Submit. Item prefabs that are selectable themselves still need scroll-into-view handling. Attach this to each selectable item:

```csharp
public class ScrollToSelected : MonoBehaviour, ISelectHandler
{
    public void OnSelect(BaseEventData _)
    {
        var sr = GetComponentInParent<ScrollRect>();
        if (sr == null) return;
        var target = (RectTransform)transform;
        Canvas.ForceUpdateCanvases();
        var local = (Vector2)sr.viewport.InverseTransformPoint(target.position);
        // adjust sr.content.anchoredPosition so `local` lies inside sr.viewport.rect
    }
}
```

#### 4. Content height growth depends on a ContentSizeFitter that the code doesn't guarantee

**Severity:** Minor
**Location:** `subject.cs:28-32`
**Issue type:** Overflow
**Viewport:** All
**Move:** Step 2 item 1 (unbounded content)
**Confidence:** Low. The answer depends on prefab setup that isn't in scope.

The line comment says "no cap on content height". That isn't a problem by itself: the ScrollRect viewport already limits the visible height, and the content is *supposed* to grow. The real risk is the opposite. A ScrollRect works out how far it can scroll from the **content RectTransform's size**. If the content object has no `VerticalLayoutGroup` plus `ContentSizeFitter` (Vertical Fit = Preferred Size), new items pile up past the content's fixed height. They become impossible to scroll to, so they're clipped silently.

It's also unclear whether `itemContainer` is the same object as `scrollRect.content`. If it isn't, items may not be inside the scrollable area at all.

**Recommendation:** Get `itemContainer` from `scrollRect.content`, or assert that they match, and check that the layout components exist:

```csharp
void Awake()
{
    Debug.Assert(itemContainer == scrollRect.content, "Items must be spawned into ScrollRect.content");
    Debug.Assert(itemContainer.GetComponent<ContentSizeFitter>() != null, "Content needs a ContentSizeFitter to grow");
}
```

For very large inventories, consider pooling or virtualizing the item rows. Creating unlimited `Instantiate` copies hurts layout rebuild time.

#### 5. The Submit button's interaction states can't be checked from code

**Severity:** Informational
**Location:** `subject.cs:14`
**Issue type:** State coverage
**Viewport:** All
**Move:** Step 2 item 8 (state matrix)
**Confidence:** Medium

The script changes `submitButton` (it reparents it), so the button is in scope for the state matrix. In uGUI, the Selectable's Transition settings (ColorTint, SpriteSwap or Animation) control how each state looks. Those are set in the Inspector, not in this file.

- [ ] `submitButton` (`subject.cs:14`, reparented at `:25`)
  - [ ] **default:** not verifiable. It depends on the prefab's Image or Graphic.
  - [ ] **hover (highlighted):** not verifiable. It's the Selectable `highlightedColor`.
  - [ ] **focus (selected):** not verifiable. The default ColorTint `selectedColor` is a slight tint, which is often too subtle for WCAG 2.4.7 and 2.4.13. It's also obscured by clipping (see Finding 3).
  - [ ] **active (pressed):** not verifiable. It's `pressedColor`.
  - [ ] **disabled:** not verifiable. The code never sets `interactable` (for example, turning it off when the inventory is empty).
  - [N/A] **error:** a button can't be validated.

**Recommendation:** Check the Button's Transition block in the prefab. Make the Selected state at least as visible as Highlighted, for example with an outline or sprite swap rather than only a tint. Set `submitButton.interactable` based on whether submitting makes sense.

#### 6. `GetComponent<ScrollRect>()` isn't null-checked

**Severity:** Informational
**Location:** `subject.cs:19-20`
**Issue type:** Other
**Viewport:** All
**Move:** Hardening
**Confidence:** High

If the ScrollRect is missing, `Start` throws on line 20. The button is never repositioned and the panel keeps whatever layout it had. Add `[RequireComponent(typeof(ScrollRect))]` to the class so the problem shows up in the editor instead of at runtime.

## What Looks Good

- `Instantiate(itemPrefab, itemContainer)` uses the overload where `instantiateInWorldSpace` defaults to `false`. That's correct for UI: items take on local layout instead of keeping a world position.
- A `ScrollRect` is used for the list in the first place, so the content is scrollable rather than silently clipped by `Mask`.
- Fields are `[SerializeField] private`, so the references are wired in the Inspector rather than found with `Find`.

## Best Practices Applied

| Principle | Source | How Applied |
|---|---|---|
| Controls stay outside scroll regions | Skill item 2; NNGroup on discoverability | Docked the footer as a sibling of the ScrollRect (Finding 1) |
| Content reflows with the screen | WCAG 1.4.10 Reflow | Replaced fixed `sizeDelta` with proportional anchors and Scale With Screen Size (Finding 2) |
| Focus is visible and not obscured | WCAG 2.4.7, 2.4.11 | Scroll-into-view on select; button kept out of the clipped viewport (Finding 3) |
| Use `SetParent(p, false)` for UI | Unity manual (RectTransform / SetParent) | Noted in Finding 1 |
| Content grows through layout components | Unity UI docs (ContentSizeFitter, ScrollRect) | Asserts on the content setup (Finding 4) |

## Keyboard Navigation

**Focus order:** Unity's default Automatic navigation is based on screen position, not on the order of objects in the hierarchy.
1. Item rows (if their prefabs are selectable), in `itemContainer`.
2. `submitButton` (`subject.cs:25`), once reparented into the content. Where it sits depends on the sibling-order problem in Finding 1, so it can end up *between* items instead of after them. Whether you can reach it doesn't depend on scroll position, but whether you can see it does (Finding 3).

With the docked footer from Finding 1, the order becomes: items, then Submit, which matches the visual reading order. Consider explicit navigation so that "Down" from the last item goes to Submit.

**Escape-key behavior:** N/A. The script doesn't define any open or close behavior for a modal or overlay. If `InventoryPanel` is shown as an overlay elsewhere, make sure Cancel (Escape or the B button, via `EventSystem`'s `cancelButton`) closes it and returns selection to the control that opened it.

**Skip-link presence:** N/A. The diff doesn't change page-level structure, and skip links don't apply to Unity uGUI.

**Focus-trap risks:** No hard trap found. The off-screen-but-selectable Submit button (Finding 3) is a soft "focus lost" risk rather than a trap.

## Viewport Verification Checklist

- [ ] 360 px mobile: **fails** with Constant Pixel Size, because the 500-unit width is wider than the screen (Finding 2).
- [ ] 1366×768: **fails** once the inventory is taller than 400 units, because Submit scrolls out of view (Finding 1).
- [ ] 1920×1080: **marginal**. A fixed 500×400 panel leaves a lot of empty space with Constant Pixel Size (Finding 2).

## Summary Table

| # | Finding | Severity | Issue type | Location | Confidence |
|---|---|---|---|---|---|
| 1 | Submit button moved into scroll content: scrolls away, wrong sibling order, can overlap items | Critical | Positioning | `subject.cs:23-25` | High |
| 2 | Fixed `sizeDelta` 500×400 overrides layout and doesn't adapt to the screen | Major | Responsive | `subject.cs:18-21` | Medium |
| 3 | Selected Submit button can be clipped out of view | Major | Focus | `subject.cs:25` | High |
| 4 | Content growth depends on an unverified ContentSizeFitter; `itemContainer` vs `content` unclear | Minor | Overflow | `subject.cs:28-32` | Low |
| 5 | Button states set in the Inspector can't be checked here; `interactable` never managed | Informational | State coverage | `subject.cs:14` | Medium |
| 6 | No null check or `RequireComponent` for ScrollRect | Informational | Other | `subject.cs:19-20` | High |

## Overall Assessment

The layout problems are structural, but they're small and easy to fix. Both bugs come from the script making layout decisions in `Start()` that belong in the prefab hierarchy. The most important fix is to stop reparenting the Submit button and dock it in a footer next to the ScrollRect. That one change fixes the scroll-away problem, the sibling-order drift, the overlap risk and the obscured-focus problem together.

After that, remove the hard-coded `sizeDelta` and rely on proportional anchors with a Scale With Screen Size `CanvasScaler`. One correction to the file's own notes: the "no cap on content height" comment is a misdiagnosis. The ScrollRect viewport already provides the cap. The real thing to check is that the content RectTransform actually grows (ContentSizeFitter), so that every item can be scrolled to.
