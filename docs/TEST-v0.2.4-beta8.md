# DuoBar v0.2.4 Beta 8 — Rotation Lock & Transitions (RootHide)

**Device-test version. Not yet in the RBx9 Sileo source.**

This beta builds on **Beta 7**, keeping its working Personal Hotspot chain symbol **inside the DuoBar ring**.

## Improvements to test

1. **Rotation lock beside DuoBar** — when Control Center opens, an overlapping rotation-lock status image is shifted just to the left of DuoBar, instead of overlapping the circle. Its original position is restored when leaving Control Center or switching DuoBar off.
2. **No stock-icon flash during transitions** — native Wi-Fi, battery, and cellular status icons are covered within the same UIKit layout cycle, instead of appearing briefly while the next asynchronous redraw is queued.
3. **Newly shown status bars** are rendered immediately where possible to reduce the momentary stock battery indicator when closing Control Center.
4. The hotspot link, size slider (70–140%), and normal battery rendering remain unchanged.

## Install

Install `DuoBar_0.2.4-beta8_RootHide.deb` using a compatible package manager on **iOS 16 Dopamine RootHide**, then respring. The package ID remains `local.duobar`. Rootless is not included in this iteration.

## Confirm before stable release

- Connect to another iPhone's hotspot: the chain-link stays **inside** DuoBar.
- Open Control Center: the rotation-lock icon should sit to the **left** of the DuoBar circle, not inside or behind it.
- Repeatedly open and close Control Center and switch between apps: **no stock status-bar flash** should appear.
- Toggle DuoBar off: native lock and status indicators should return.
- Test Wi-Fi, no-service/cellular, dark and light status bars, and multiple slider sizes.

This was compiled and package-tested but **the new transition and rotation-lock fix still requires a real-device check**. If any overlap or flash remains, share a new screen recording before we release it publicly.

**Rollback:** [Stable v0.2.3 (RootHide)](https://github.com/RBx9/DuoBar/releases/tag/v0.2.3).
