// Test case: Unity UI layout with unbounded content and fixed sizing
// A Unity ScrollView that uses fixed pixel dimensions instead of
// proportional sizing, and a button inside the scroll area.
//
// Expected finding: Critical — fixed pixel dimensions won't adapt to
// different screen resolutions; button trapped in scroll view

using UnityEngine;
using UnityEngine.UI;

public class InventoryPanel : MonoBehaviour
{
    [SerializeField] private Transform itemContainer;
    [SerializeField] private Button submitButton;

    void Start()
    {
        // BUG: Fixed pixel dimensions — won't adapt to different resolutions
        var scrollRect = GetComponent<ScrollRect>();
        var rt = scrollRect.GetComponent<RectTransform>();
        rt.sizeDelta = new Vector2(500, 400);

        // BUG: Submit button is a child of the scroll content
        // It will scroll away when the inventory is full
        submitButton.transform.SetParent(scrollRect.content);
    }

    public void AddItem(GameObject itemPrefab)
    {
        // Items can grow without limit — no cap on content height
        Instantiate(itemPrefab, itemContainer);
    }
}
