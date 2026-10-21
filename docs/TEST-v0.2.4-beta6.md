# DuoBar v0.2.4 beta 6 — App status-bar visibility

**TEST BUILD — Not published in Sileo.**

## Fixed in this beta
- When iOS 16 replaces Wi-Fi with the Personal Hotspot chain-link indicator, DuoBar attempts to detect that status indicator and renders a matching chain-link **inside its circular battery glyph**.
- The original hotspot indicator is covered while DuoBar is active; disabling DuoBar restores native icon drawing.
- App and Control Center status bars use a device battery-reading fallback when their container does not expose a native battery view.
- Status-bar containers are rescanned as apps enter the foreground and their status-bar views attach or relayout.
- Existing ordinary Wi-Fi drawing, cellular dots, charging indicators, and adjustable size remain unchanged.

## Install
- **RootHide beta only:** `DuoBar_0.2.4-beta6_RootHide.deb` — package `local.duobar`, architecture `iphoneos-arm64e`

Download `DuoBar_0.2.4-beta6_RootHide.deb` from the [GitHub beta 6 prerelease](https://github.com/RBx9/DuoBar/releases/tag/v0.2.4-beta.6). Install it with your RootHide-compatible package manager, then respring. Rootless packaging is deferred until the fix is confirmed and ready for the stable release.

## Device testing checklist
1. Join a regular Wi-Fi network and verify the normal in-ring Wi-Fi symbol.
2. Open the Home Screen, Settings, and other apps; confirm DuoBar stays visible in each app's status bar.
3. Open Control Center over an app and confirm DuoBar stays visible there too.
4. Connect to another iPhone's Personal Hotspot and confirm the native Apple chain-link shape appears **inside** the DuoBar ring.
5. Open and close Control Center while connected to the hotspot; verify the stock battery percent doesn't duplicate.
6. Disconnect from hotspot; check normal Wi-Fi comes back.
7. Toggle DuoBar off and ensure the stock hotspot indicator returns.
8. Test the size slider and orientation-lock indicator.

The build verifies compatibility with Theos and package file layout, **not** live hotspot detection on your iPhone. If the chain icon is unchanged or there is a layout issue, send a screenshot and iOS/jailbreak version so it can be revised before any Sileo update.

## Rollback
Install [v0.2.3 RootHide](https://github.com/RBx9/DuoBar/releases/tag/v0.2.3) or [v0.2.3 Rootless](https://github.com/RBx9/DuoBar/releases/tag/v0.2.3-rootless.1).
