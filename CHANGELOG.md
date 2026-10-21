# Changelog

## 0.2.4 beta 9 — More rotation-lock spacing

- Move the rotation-lock indicator up to five additional points left by expanding the desired gap with DuoBar from 5 to 10 points.
- Retain the safe screen-edge clamp, hotspot symbol and no-flash transition fixes from beta 8.
- RootHide-only device test; Sileo remains on stable v0.2.3.

## 0.2.4 beta 8 — Rotation lock and status-bar transitions

- Restore a safe Control Center rotation-lock adjustment, moving an overlapping lock indicator just LEFT of the DuoBar ring.
- Preserve and restore UIKit's original orientation-icon transform when Control Center closes or the tweak is switched off.
- Re-cover native battery/Wi-Fi/cellular layers synchronously after UIKit layout rather than allowing a visible stock-icon flash before the next deferred redraw.
- Render new status-bar containers in the same layout cycle to reduce transition flashes.
- Keep the working hotspot link inside the DuoBar circle and retain the size slider.
- Test build only; leave public Sileo v0.2.3 unchanged.

## 0.2.4 beta 7 — Restore hotspot glyph and stabilize transitions

- Detect Personal Hotspot chain symbols even when iOS exposes them as vector/template images.
- Keep DuoBar's own in-ring link image out of native-indicator detection so it remains visible.
- Coalesce status-bar relayout updates and use a stable Control Center position during presentation changes.
- Keep the existing 70%–140% size slider, app status bars, and RootHide-only beta packaging.

## 0.2.4 beta 6 — Keep DuoBar visible in apps

- Use the device battery reading when an app's status-bar container has no native battery view.
- Refresh all status-bar controllers as an app enters the foreground and becomes active.
- RootHide test build only; Rootless remains deferred until the fix is confirmed.

## 0.2.4 beta 5 — Control Center hotspot image fallback

- Reads the hotspot glyph from either the status-bar image view or its layer contents.
- Forces the inner glyph view to lay out after Control Center positions DuoBar.
- RootHide test build only; Rootless remains deferred until the fix is confirmed.

## 0.2.4 beta 4 — Native Personal Hotspot symbol

- Reuses the chain-link image supplied by iOS and scales it inside DuoBar.
- Falls back to Apple's standard `link` symbol when the status-bar image is unavailable.
- RootHide test build only; Rootless remains deferred until the fix is confirmed.

## 0.2.4 beta 3 — Compact Personal Hotspot glyph

- Shrinks the chain-link mark and removes its rotation so it sits level inside the DuoBar ring.
- RootHide test build only; Rootless remains deferred until the fix is confirmed.

## 0.2.4 beta 2 — Personal Hotspot indicator compatibility

- Detects unlabeled Personal Hotspot chain glyphs by their rendered shape.
- Scans both the regular status bar and Control Center for the hotspot indicator.
- RootHide test build only; Rootless is deferred until the fix is confirmed.

## 0.2.4 beta 1 — Personal Hotspot indicator compatibility

- Render the Personal Hotspot link symbol inside DuoBar when iOS replaces Wi-Fi with the hotspot status indicator.
- Hide the original hotspot glyph only while DuoBar is visible and enabled, restoring it on disable or disconnect.
- Add a Control Center battery-reading fallback for hotspot layouts that omit the native battery view.
- Preserve standard Wi-Fi rendering and v0.2.3 size/Control Center settings.
- Beta only: RootHide and Rootless device testing required before publishing to Sileo.

## 0.2.3 — Adjustable DuoBar size

- Added a DuoBar Size slider in Settings with 70%–140% scale in 5% increments.
- Current Size shows the selected percentage, and Reset Size returns to 100%.
- Size changes notify SpringBoard and update the current glyph without respringing.
- Reused existing glyph rendering and Control Center positioning logic.
- Tested as a RootHide beta and approved for stable release.

## 0.2.2 — Settings icon compatibility

- Fixed the missing DuoBar icon on the iOS Settings main list by bundling all icon sizes inside DuoBarPrefs.bundle, where PreferenceLoader resolves entry images.
- Kept icon files in the PreferenceLoader directory for compatibility with other implementations.
- Added an image-file fallback for the in-page DuoBar icon.
- Sileo package metadata and Settings version now use 0.2.2.

## 0.2.1 — Control Center and Settings update

- Fixed the duplicate stock battery percentage in Control Center.
- Fixed the rotation-lock status indicator overlap with DuoBar.
- Added the custom blue DuoBar icon to Settings and the preference page header.
- Reorganized Settings into Appearance, About DuoBar, and Links & Updates.
- Added RBx9 Repo, one-tap Sileo source, GitHub project, and developer links.
- Preserved the live Enable DuoBar switch and stock status-bar restoration.
- Control Center corrections confirmed on a jailbroken iPhone.

## 0.2.0

- Added a Settings page with a persistent Enable DuoBar switch.
- Added live switching between the circular design and stock status-bar icons.
- Added the tweak description, RBx9 developer credit, and @RedaBuali Twitter / X link.
- Added PreferenceLoader as a package dependency.

## 0.1.1

- Shortened the lower battery arc ends to give the outer cellular dots a clear gap.
- Preserved the dots’ size and curved placement.

## 0.1.0

- Introduced the combined circular battery, Wi-Fi, and cellular status icon.
- Added live battery percentage, charging indication, Low Power Mode and low-battery colors.
- Added light and dark styling and a Dopamine RootHide package for iOS 16.
