# DuoBar v0.2.4 Beta 10 — Control Center rotation-lock overlap

**RootHide test build only. Not published to Sileo.**

The user confirmed the hotspot indicator and stock-icon transitions were fixed in Beta 8 but still saw the rotation-lock icon INSIDE the DuoBar ring in Beta 9. Merely enlarging the spacing did not work.

## Targeted change

- Look for the actual overlapping rotation-lock indicator in the full Control Center window if it is not inside DuoBar's own status-bar container.
- Compute both icon positions in window coordinates, rather than clamping the lock's movement to the battery container.
- Shift the detected indicator to the **left** of the circle with a 10-point target gap, and restore its original transform when no longer applicable.
- Preserve the working Personal Hotspot symbol inside the circle, the zero-flash transitions, battery/cellular display and 70–140% size slider.

## Test

Install `DuoBar_0.2.4-beta10_RootHide.deb` on your iOS 16 Dopamine RootHide device and respring. Enable rotation lock, open Control Center, and check whether the lock symbol now sits **beside**, not inside, the circle. Repeat with hotspot on/off and open/close Control Center quickly. Disable DuoBar and verify iOS's default indicators return.

If the lock remains embedded, the status glyph may be rendered as an unnamed image inside a different private UIKit view; the next fix will require a device hierarchy trace or more targeted image identification. Do not publish a stable update without a successful device test.

**Rollback:** [Beta 8](https://github.com/RBx9/DuoBar/releases/tag/v0.2.4-beta.8) or [stable v0.2.3](https://github.com/RBx9/DuoBar/releases/tag/v0.2.3).
