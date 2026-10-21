# DuoBar v0.2.4 beta 2 — Hotspot indicator compatibility

**TEST BUILD — Not published in Sileo.**

## Fixed in this beta
- When iOS 16 replaces Wi-Fi with the Personal Hotspot chain-link indicator, DuoBar attempts to detect that status indicator and renders a matching chain-link **inside its circular battery glyph**.
- The original hotspot indicator is covered while DuoBar is active; disabling DuoBar restores native icon drawing.
- Control Center uses a battery-reading fallback if a hotspot layout doesn't expose a normal battery status view.
- Existing ordinary Wi-Fi drawing, cellular dots, charging indicators, and adjustable size remain unchanged.

## Install
- **RootHide beta only:** `DuoBar_0.2.4-beta2_RootHide.deb` — package `local.duobar`, architecture `iphoneos-arm64e`

Download `DuoBar_0.2.4-beta2_RootHide.deb` from the [GitHub beta 2 prerelease](https://github.com/RBx9/DuoBar/releases/tag/v0.2.4-beta.2). Install it with your RootHide-compatible package manager, then respring. Rootless packaging is deferred until the fix is confirmed and ready for the stable release.

## Device testing checklist
1. Join a regular Wi-Fi network and verify the normal in-ring Wi-Fi symbol.
2. Connect to another iPhone's Personal Hotspot and confirm the chain link appears **inside** the DuoBar ring with no duplicate native link beside it.
3. Open and close Control Center while connected to the hotspot; verify DuoBar remains visible and the stock battery percent doesn't duplicate.
4. Disconnect from hotspot; check normal Wi-Fi comes back.
5. Toggle DuoBar off and ensure the stock hotspot indicator returns.
6. Test the size slider and orientation-lock indicator.

The build verifies compatibility with Theos and package file layout, **not** live hotspot detection on your iPhone. If the chain icon is unchanged or there is a layout issue, send a screenshot and iOS/jailbreak version so it can be revised before any Sileo update.

## Rollback
Install [v0.2.3 RootHide](https://github.com/RBx9/DuoBar/releases/tag/v0.2.3) or [v0.2.3 Rootless](https://github.com/RBx9/DuoBar/releases/tag/v0.2.3-rootless.1).
