# Changelog

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
