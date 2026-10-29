RootHide and standard Rootless community-test builds of DuoBar v2.7.2 Beta 8 for iOS 16. Choose the package that matches the jailbreak, and do not install both variants.

Beta 8 fixes DuoBar moving down and left as Control Center finishes closing. Control Center's own DuoBar now uses the Home Screen placement, so it lands exactly on the Home Screen's DuoBar. In the iOS 16.4 simulator, inside SpringBoard, the end-of-close jump was up to 12 pt sideways and 7.2 pt down before this change and 0.0 pt after it, on the iPhone 12, 13 mini, 14, 14 Pro and 14 Pro Max at 70%, 100% and 140%. While Control Center is open, the ring now sits where the battery is, about 12 pt further left than in beta 7.

The 5G/LTE label, Personal Hotspot mark, Control Center and status-bar hooks are now installed only when every private iOS method they need is present, so a changed firmware disables one feature instead of hooking a missing method. The design, Settings, size slider, enable switch, battery percentage, charging and Low Power Mode colors, Wi-Fi and cellular indicators are unchanged.

Install `DuoBar_2.7.2-beta8_RootHide.deb` on Dopamine RootHide, or `DuoBar_2.7.2-beta8_Rootless.deb` on standard Rootless (Dopamine or palera1n), then respring. GitHub Actions built both packages with the official Theos toolchains, and `scripts/verify-deb.py` checked their metadata, ownership, 0755/0644 modes, arm64 and new-ABI arm64e slices, code signatures, linkage, private-class imports, Settings plists, icons and warning-free build logs.

DuoBar still supports iOS 16 only. Simulator results and the jailbreak availability for iOS 17, 18 and 26 are in `docs/COMPATIBILITY.md`. Follow `docs/TEST-v2.7.2-beta8.md` for device checks; it explains how to collect a SpringBoard crash log if Safe Mode occurs.

This is a prerelease for community testing; it has not yet been tested on a physical device. Stable v2.7.1 and the Sileo source remain unchanged.
