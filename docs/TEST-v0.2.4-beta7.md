# DuoBar v0.2.4 beta 7 — Hotspot and Control Center stability

**RootHide test build only. This build has not been run on an iPhone yet.**

## Changes in this beta

- Recognizes the Personal Hotspot chain when iOS provides a vector/template status-bar image, then renders the Apple link mark inside DuoBar.
- Excludes DuoBar's own link image from native hotspot detection so it is not hidden by a later status-bar scan.
- Coalesces repeated status-bar relayouts and uses a consistent Control Center position to avoid moving neighboring indicators during presentation animations.
- Preserves the existing Enable DuoBar switch, icon, live size slider, battery fallback, and app status-bar support.

## Install

- Package: `DuoBar_0.2.4-beta7_RootHide.deb`
- Package ID: `local.duobar`
- Architecture: `iphoneos-arm64e`
- Jailbreak: Dopamine RootHide on iOS 16

Install the `.deb` from the beta 7 GitHub prerelease with a RootHide-compatible package manager, then respring. Do not install this test package on a standard Rootless setup. Rootless and Sileo stable packages remain deferred.

## Device checks

1. Connect to another iPhone's Personal Hotspot. Confirm the Apple chain-link appears inside the DuoBar circle, with no separate chain left beside it.
2. Check Home Screen, Settings, and a third-party app while connected. Confirm the DuoBar stays visible and does not overlap the time or other indicators.
3. Open Control Center over an app. Confirm the DuoBar remains visible and the hotspot link stays inside its circle.
4. Open and close Control Center rapidly at least 20 times. Confirm the DuoBar does not jump, float, duplicate, or disappear.
5. In Settings → DuoBar, test 70%, 100%, and 140% sizes. Check each size in an app and Control Center, then reset to 100%.
6. Turn DuoBar off and confirm iOS restores its native battery, Wi-Fi, cellular, and hotspot indicators. Turn it on again and confirm the combined glyph returns.
7. Disconnect from the hotspot and confirm the normal Wi-Fi glyph returns inside DuoBar.

The RootHide build and package contents can be verified in CI. Private UIKit status-bar behavior and rapid Control Center transitions need confirmation on the target iPhone before this change is considered stable.
