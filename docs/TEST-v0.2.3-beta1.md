# DuoBar v0.2.3 beta 1 — Adjustable Size

**Private testing candidate, not a stable Sileo update.**

## What's new

- **Settings → DuoBar → DuoBar Size** adds a slider from **70% to 140%**.
- The default **100%** matches the existing v0.2.2 size.
- **Current Size** displays the selected percentage.
- **Reset Size to 100%** restores the original setting.
- A change updates the on-screen DuoBar glyph immediately without a respring.
- The original Control Center battery-percentage and rotation-lock fixes are preserved.

## Install on your RootHide iPhone

Download the attached **DuoBar_0.2.3-beta1_RootHide.deb** from this prerelease and install it using your RootHide-compatible package manager. Respring after installing. The package ID remains `local.duobar`, so this upgrades the existing installation.

**Important:** The beta is **not added to RBx9 Repo in Sileo**. Only install it directly from this GitHub prerelease. Don't publish the beta as stable until testing is successful.

## Check before release

1. Open Settings → DuoBar and confirm the DuoBar Size slider is visible.
2. Verify 100% matches the previous size.
3. Try 70%, 85%, 115%, and 140% on the normal status bar.
4. Open Control Center at each size; ensure that the duplicate percentage stays hidden and the rotation-lock badge does not overlap.
5. Verify live changes without respringing, then use Reset Size to 100%.
6. Toggle Enable DuoBar off and on; verify stock icons return when disabled.
7. Check light/dark backgrounds and the lock screen.

Some status-bar containers clip subviews, so large settings may be constrained by available layout. Please report which values work on your device.

**Rollback:** Reinstall [DuoBar v0.2.2](https://github.com/RBx9/DuoBar/releases/tag/v0.2.2) and respring.

Platform: **iOS 16.x + Dopamine RootHide** · Package: `local.duobar` · Version: `0.2.3~beta1` · Architecture: `iphoneos-arm64e`.
