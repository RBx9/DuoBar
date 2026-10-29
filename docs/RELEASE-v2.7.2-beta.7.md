RootHide and standard Rootless community-test builds of DuoBar v2.7.2 Beta 7. Choose the package that matches the jailbreak, and do not install both variants.

Beta 7 keeps the beta 5 design: the compact 5G/LTE label inside DuoBar, the Wi-Fi and Personal Hotspot marks, the battery percentage, the cellular dots, the size slider, and the Control Center and rotation handling.

On iPhones with a 20 pt status bar, such as the iPhone 8 Plus, sizes above about 110% previously pushed the ring past the top of the screen. It now moves down into view at the selected size. Face ID iPhones and Control Center keep their previous placement. Beta 7 also looks up the private `_UIStatusBarStringView` class at runtime instead of linking to it, which beta 5 did and which could stop the tweak from loading. It also limits DuoBar's status-bar tracking to the main thread.

Install `DuoBar_2.7.2-beta7_RootHide.deb` on Dopamine RootHide, or `DuoBar_2.7.2-beta7_Rootless.deb` on standard Rootless (Dopamine or palera1n), then respring. GitHub Actions built both packages with the official Theos toolchains. `scripts/verify-deb.py` checked the package metadata, root ownership, 0755/0644 modes, arm64 and new-ABI arm64e slices, code signatures, substrate linkage, private-class imports, Settings plists, icons, and warning-free build logs.

There is no beta 6. Locally built beta 5 and beta 6 packages are unsafe and must not be installed. Follow `docs/TEST-v2.7.2-beta7.md` for device checks. If Safe Mode occurs, it explains how to collect the SpringBoard crash log.

This is a prerelease for community testing. Stable v2.7.1 and the Sileo source remain unchanged until device testing is complete.
