# DuoBar v2.7.2 Beta 3 — RootHide

This RootHide update fixes a status-bar transition issue where the stock battery could reappear after rotating the screen or opening Control Center. It rescans UIKit's rebuilt status-bar views and refreshes DuoBar immediately after layout. During zero-height transition layouts, it keeps the last valid DuoBar drawn and the native icons covered, while allowing retired status-bar containers to cleanly restore their native views.

The build retains the compact 5G/LTE label, Wi-Fi and Personal Hotspot marks, battery percentage, cellular dots, size slider, Settings, and the v2.7.1-based Control Center behavior.

## Device checks

- Rotate between portrait and landscape on the Home Screen, inside an app, and while Control Center is open. Confirm the stock battery does not return and DuoBar stays aligned.
- Open and close Control Center rapidly while rotating, then repeat with an app in the foreground. Confirm DuoBar does not jump, disappear, or leave the stock battery exposed.
- Confirm the compact `5G` or `LTE` label appears inside DuoBar in the Home Screen, in an app, and in Control Center.
- Confirm Wi-Fi and the Personal Hotspot chain appear inside the circle in their respective states.
- Set the size slider to 70%, 100%, and 140% and confirm DuoBar remains within the status-bar area in portrait and landscape.
- Turn DuoBar off and confirm iOS restores its normal battery, Wi-Fi, cellular, and carrier indicators; re-enable it and repeat the checks.

Compilation and package contents are verified by GitHub Actions. Live rotation and Control Center behavior still requires testing on iOS 16 with Dopamine RootHide.
