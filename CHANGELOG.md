## 2.7.2 beta 8 — Smooth Control Center closing and safer private API use

- Fix DuoBar moving down and left as Control Center finishes closing. Control Center draws its own status bar and animates it into the Home Screen's place before hiding it. Its DuoBar used an extra 12 pt offset and was clamped inside Control Center's 44 pt bar, so it ended 12 pt right of the Home Screen's DuoBar and up to 7.2 pt higher, then jumped. Measured in the iOS 16.4 simulator SpringBoard: 1.2 pt (iPhone 14 Pro, 100%), 7.2 pt (14 Pro, 140%), 2.7 pt (iPhone 14, 140%). Control Center now uses the Home Screen placement, and the same measurement shows no jump (0.0 pt) on the iPhone 12, 13 mini, 14, 14 Pro and 14 Pro Max at 70%, 100% and 140%. While Control Center is open, the ring now sits where the battery is (12 pt left of beta 7).
- Install the 5G/LTE, Personal Hotspot, Control Center and status-bar container hooks only when the private class is a view that has every hooked selector. A renamed private API on another firmware now disables just that feature instead of hooking a missing method.
- Make the iOS 16 gate an explicit constant tied to both packages' firmware dependency.
- CI: check private API use (`scripts/check-private-api.py`), test the measured Control Center handoff in `tests/layout-test.c`, and run a simulator check that probes DuoBar's private APIs on iOS 16.4, 17.5, 18.6 and 26.x and traces Control Center inside SpringBoard.
- Still iOS 16 only. In simulators with the gate raised for testing, DuoBar loaded without crashing SpringBoard on iOS 17.5, 18.6 and 26.x, but DuoBar does not find the Home Screen status bar there (on iOS 18 and 26 it finds no SpringBoard status bar at all), so it does not attach yet. See `docs/COMPATIBILITY.md`.

## 2.7.2 beta 7 — Home-button iPhone sizing, safer loading and verified CI packages

- Keep an enlarged DuoBar on screen on iPhones with a 20 pt status bar, such as the iPhone 8 Plus. Above about 110%, the ring was centred on the battery and rose past the top of the screen, cutting off a visible part of it at 130%–140%. It now moves down into view at the same size. Face ID status bars and Control Center keep their exact previous position, and if a parent view clips the status bar the ring shrinks to fit instead of being cut. The rule lives in `Sources/DuoLayout.h` and is checked by `tests/layout-test.c`.
- Look up `_UIStatusBarStringView` at runtime instead of linking to the private class. Beta 5's tweak library carried a non-weak import of that class, which would stop DuoBar from loading on a firmware that does not export it.
- Change DuoBar's status-bar tracking only on the main thread, and release the hotspot image buffer on an early return.
- Verify every CI package with `scripts/verify-deb.py`: metadata, root ownership, 0755/0644 modes, arm64 and new-ABI arm64e slices, code signatures, substrate linkage, private-class imports, Settings plists, icons and warning-free build logs. `scripts/selftest-verify-deb.py` confirms the check rejects restrictive modes, old-ABI or missing arm64e slices, missing signatures and toolchain warnings.
- Branch pushes upload CI packages as workflow artifacts only. A prerelease is published only from a matching `v2.7.2-beta.N` tag, and never replaces an existing release.
- Version 2.7.2~beta6 is skipped because an unsafe locally built package already used it. The 5G/LTE label, design, Settings, size slider, hotspot, Control Center and rotation behavior are unchanged. Stable v2.7.1 and Sileo remain unchanged.

## 2.7.2 beta 5 — Rootless package permissions and carrier label

- Build release packages with the GitHub macOS Theos toolchains; verify Rootless executable permissions and arm64/arm64e slices before publishing.
- Increase the compact 5G/LTE carrier label from 7 pt to 8.5 pt while keeping it inside the DuoBar ring.
- Community beta only; stable v2.7.1 and Sileo remain unchanged.

# Changelog

## 2.7.2 beta 4 — Rootless arm64e Settings compatibility

- Add both arm64 and arm64e slices to the Rootless tweak library and Settings executable while retaining the `iphoneos-arm64` package architecture.
- Keep the RootHide and standard Rootless packages separate and compatible with the existing beta3 transition fix.
- RootHide and Rootless test builds only; stable/Sileo remains unchanged pending device testing.

## 2.7.2 beta 2 — Rotation and Control Center transition fix

- Rescan status-bar battery, Wi-Fi, cellular, hotspot, and 5G/LTE views after UIKit rebuilds them.
- Refresh DuoBar synchronously after status-bar layout and keep the native battery covered through transient rotation and Control Center geometry.
- RootHide beta only; the Rootless and stable/Sileo releases remain deferred until device testing.

## 2.7.2 beta 3 — Keep transition coverage scoped

- Preserve the previous overlay only for zero-height UIKit layout transitions, avoiding stale overlays in retiring status-bar containers.
- The Rootless package was later superseded by Beta 4 after adding the arm64e Settings executable slice.

## 0.2.4 beta 8 — Compact 5G/LTE status label

- Put the native 5G/LTE carrier label inside DuoBar in app status bars and Control Center.
- Fit the short carrier label in the existing center slot; show the usual Wi-Fi mark when no carrier label is present, and keep the hotspot link as the center mark while connected.
- Keep the battery ring, cellular dots, and size setting unchanged.
- Keep the hotspot link as the center glyph whenever Personal Hotspot is connected.
- RootHide test build only; Rootless and stable/Sileo releases remain deferred.

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
