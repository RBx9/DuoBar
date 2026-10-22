# DuoBar v0.2.4 beta 8 — 5G/LTE label and status-bar checks

**RootHide test build only. A local package build succeeded; live iPhone behavior still needs device testing.**

## Changes in this beta

- Draws compact 5G or LTE text in DuoBar's existing center slot in app status bars and Control Center.
- Hides the matching native carrier text only while the in-circle label is visible, preserving its native text and layout state for restoration.
- Uses the existing center slot for 5G/LTE when available, retains the usual Wi-Fi mark otherwise, and keeps the hotspot link as the center mark while connected.
- Keeps the existing battery ring, cellular dots, icon, Enable DuoBar switch, and live size slider.
- Keeps the hotspot link as the center mark while connected to Personal Hotspot.

## Install

- Package: `DuoBar_0.2.4-beta8_RootHide.deb`
- Package ID: `local.duobar`
- Architecture: `iphoneos-arm64e`
- Jailbreak: Dopamine RootHide on iOS 16

Install the `.deb` from the beta 8 GitHub prerelease with a RootHide-compatible package manager, then respring. Do not install this test package on a standard Rootless setup. Rootless and Sileo stable packages remain deferred.

## Device checks

1. With 5G service, check Home Screen, Settings, and a third-party app. Confirm a small centered `5G` appears inside DuoBar and the separate native `5G` text is hidden.
2. Repeat on LTE service. Confirm `LTE` fits inside the circle without touching the ring or dots.
3. Open Control Center over an app on 5G and LTE. Confirm the label appears inside DuoBar there and no carrier text remains beside the circle.
4. Connect to another iPhone's Personal Hotspot. Confirm the Apple chain link remains inside DuoBar and the hotspot behavior from beta 7 is preserved.
5. In Settings → DuoBar, test 70%, 100%, and 140% sizes in apps and Control Center, then reset to 100%.
6. Open and close Control Center rapidly at least 20 times. Confirm DuoBar does not jump, float, duplicate, or disappear.
7. Turn DuoBar off and confirm iOS restores native indicators, including the 5G/LTE carrier label. Turn it on again and confirm the compact label returns.

The RootHide build and package contents can be checked locally and in CI. Private UIKit status-bar behavior and Control Center transitions need confirmation on the target iPhone before this change is considered stable.
