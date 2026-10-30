DuoBar v2.7.2 is a stable bug-fix release for iOS 16, for both Dopamine RootHide and standard Rootless (Dopamine, palera1n). Install the package that matches your jailbreak, and do not install both.

## Fixes

- **Control Center closing:** DuoBar no longer jumps down and to the side when Control Center finishes closing. It now lands exactly where the Home Screen's DuoBar is. While Control Center is open, the ring sits where the battery is.
- **Larger sizes on 20 pt status bars:** on Home-button iPhones such as the iPhone 8 Plus, sizes above about 110% no longer rise past the top of the screen.
- **Rotation and Control Center transitions:** the stock battery no longer flashes back while the status bar is rebuilt.
- **Safer loading:** the 5G/LTE label, Personal Hotspot mark and Control Center features each check that the iOS methods they need exist, and switch off on their own instead of risking a crash.

## New

- A compact **5G/LTE** label inside the ring.

Everything else is unchanged: the design, Settings, the 70%–140% size slider, the on/off switch, the battery percentage, Wi-Fi and Personal Hotspot marks, cellular dots, and charging and Low Power Mode colors.

## Supported versions and devices

**iOS 16.0–16.7.x only.** Both packages refuse to install on other iOS versions.

| Jailbreak | iPhones (on an iOS 16 build the jailbreak supports) | Package |
|---|---|---|
| Dopamine (Rootless) | iPhone XS, XS Max, XR, 11, 11 Pro, 11 Pro Max, SE (2nd and 3rd generation), 12, 12 mini, 12 Pro, 12 Pro Max, 13, 13 mini, 13 Pro, 13 Pro Max, 14, 14 Plus, 14 Pro, 14 Pro Max | `DuoBar_2.7.2_Rootless.deb` |
| Dopamine RootHide | Same iPhones as Dopamine | `DuoBar_2.7.2_RootHide.deb` |
| palera1n (Rootless) | iPhone 8, 8 Plus, X | `DuoBar_2.7.2_Rootless.deb` |

**Not supported:** iOS 17, 18 and 26 on any iPhone. The iPhone 15 and newer, because the iPhone 15 cannot run iOS 16 and the iPhone 16, 17 and 18 have no public jailbreak. iPad is untested.

## Testing

- Tested on an **iPhone 14 Pro Max with iOS 16.4.1** (as 2.7.2 beta 8): stable, and the Control Center fix confirmed.
- Tested in the **iOS 16.4 simulator inside SpringBoard** on the iPhone 12, 13 mini, 14, 14 Pro, 14 Pro Max and SE, at 70%, 100% and 140%: DuoBar stays on screen, does not overlap the time or carrier text, and lands exactly in place when Control Center closes.
- Both packages were built by GitHub Actions with the official Theos toolchains and checked before release: metadata, file permissions, arm64 and arm64e slices, signatures, linkage, and a warning-free build log.

## Install

Add the **RBx9 Repo** to Sileo (`https://rbx9.github.io/`) and install DuoBar, or download the matching `.deb` below and open it in your package manager. Respring, then open **Settings → DuoBar**. Existing installations upgrade in place.

If SpringBoard ever enters Safe Mode, uninstall DuoBar and send the newest `SpringBoard-<date>.ips` from Settings → Privacy & Security → Analytics & Improvements → Analytics Data.
