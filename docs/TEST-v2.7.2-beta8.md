# DuoBar v2.7.2 Beta 8 — RootHide and Rootless

Beta 8 fixes DuoBar moving down and left at the moment Control Center finishes closing. It also makes the optional 5G/LTE, Personal Hotspot and Control Center features switch themselves off if their private iOS methods are missing, instead of hooking them anyway. It still supports iOS 16 only.

Install only a package built by GitHub Actions and checked by `scripts/verify-deb.py`:

- **Dopamine RootHide:** `DuoBar_2.7.2-beta8_RootHide.deb`, package `local.duobar`, architecture `iphoneos-arm64e`.
- **Standard Rootless (Dopamine or palera1n):** `DuoBar_2.7.2-beta8_Rootless.deb`, package `local.duobar.rootless`, architecture `iphoneos-arm64`, with arm64 (A11 iPhones such as the 8 Plus) and arm64e slices.

Do not install both variants. Compare the checksum with `SHA256SUMS-RootHide.txt` or `SHA256SUMS-Rootless.txt` from the same release.

## What changed visually

- When Control Center closes, DuoBar should glide into place with no final jump.
- While Control Center is open, the ring now sits where the battery is, about 12 pt further left than in beta 7. At large sizes it is also centred on the battery instead of pushed to the top of Control Center's status bar.

## Device checks

- Open Settings → DuoBar. Confirm the page loads, the version reads `2.7.2-beta.8`, and the icon, size slider and enable switch work.
- At 70%, 100% and 140%, open and close Control Center slowly, then quickly, at least 20 times. Confirm DuoBar does not jump, slide down, or flash the stock battery at the end of closing.
- With Control Center open, check that DuoBar, the rotation-lock icon, Wi-Fi or Personal Hotspot, the battery percentage, the cellular dots and the 5G/LTE label do not overlap.
- Check the Home Screen, several apps and the Lock Screen, in portrait and landscape.
- Toggle DuoBar off and on and confirm the native indicators return and disappear again.

### Home-button iPhones (iPhone 8, 8 Plus, SE)

- At 110%–140%, confirm the top of the ring is fully visible on the Home Screen, in apps and on the Lock Screen.
- With Settings → Battery → Battery Percentage turned on, report whether iOS's own "86%" text still appears beside DuoBar, with a screenshot.

## If Safe Mode occurs

Do not reinstall the package. Note the iPhone model, exact iOS version, jailbreak and version, package file name and what happened just before. Uninstall DuoBar in Safe Mode and respring. Then share the newest `SpringBoard-<date>.ips` file from Settings → Privacy & Security → Analytics & Improvements → Analytics Data, plus any `ExcResource_SpringBoard` or `JetsamEvent` entry from the same minute.

Stable v2.7.1 and the Sileo source remain unchanged.
