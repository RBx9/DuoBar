# Changelog

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
