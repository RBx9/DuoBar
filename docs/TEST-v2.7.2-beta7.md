# DuoBar v2.7.2 Beta 7 — RootHide and Rootless

Beta 7 keeps the beta 5 design and behavior. On iPhones with a 20 pt status bar, such as the iPhone 8 Plus, an enlarged DuoBar now moves down into view instead of being cut off at the top of the screen. Beta 7 also removes a hard link to the private `_UIStatusBarStringView` class, which could stop the tweak from loading, and limits DuoBar's status-bar tracking to the main thread. There is no beta 6: that version number belonged to an unsafe local package, which must not be installed.

Install only a package built by GitHub Actions and checked by `scripts/verify-deb.py`:

- **Dopamine RootHide:** `DuoBar_2.7.2-beta7_RootHide.deb`, package `local.duobar`, architecture `iphoneos-arm64e`.
- **Standard Rootless (Dopamine or palera1n):** `DuoBar_2.7.2-beta7_Rootless.deb`, package `local.duobar.rootless`, architecture `iphoneos-arm64`. It contains both the arm64 slice used by A11 iPhones such as the 8 Plus and the arm64e slice used by newer iPhones.

Do not install both variants. Compare the package checksum with `SHA256SUMS-RootHide.txt` or `SHA256SUMS-Rootless.txt` from the same CI run or release.

## Device checks

- Open Settings → DuoBar. Confirm the page loads, the version reads `2.7.2-beta.7`, and the icon, size slider and enable switch work.
- Confirm DuoBar appears on the Home Screen, in several apps and in Control Center, with a single battery percentage in Control Center.
- On cellular data, confirm the compact 5G or LTE label still appears inside the ring. This confirms the runtime class lookup installed the status-bar text hooks.
- Check Wi-Fi, Personal Hotspot, the cellular dots, charging and Low Power Mode.
- Rotate between portrait and landscape, and open and close Control Center rapidly at least 20 times. Confirm the stock battery does not return, and that DuoBar does not jump, disappear or trigger Safe Mode.
- Test the size slider at 70%, 100% and 140%, then toggle DuoBar off and on and confirm the native indicators return and disappear again.

### Home-button iPhones (iPhone 8, 8 Plus, SE)

- Set the size slider to 110%, 120%, 130% and 140%. At each size, confirm the top of the ring is fully visible on the Home Screen, the Lock Screen and in apps, and that the ring sits slightly lower instead of being cut off.
- Confirm the ring does not cover app content you need, such as navigation-bar buttons, at 140%.
- With Settings → Battery → Battery Percentage turned on, check whether iOS's own "86%" text still appears beside DuoBar. Send a screenshot if it does: DuoBar does not hide that separate label outside Control Center yet.
- Open Control Center and confirm DuoBar and the rotation-lock icon look right once it closes.

## If Safe Mode occurs

Do not reinstall the package or assume it is safe. Collect the crash log first:

1. Note the iPhone model, exact iOS version, jailbreak and its version (Dopamine or palera1n), RootHide or Rootless, the DuoBar package file name, other status-bar tweaks installed, and what happened just before the crash (respring, rotation, Control Center, Settings).
2. Uninstall DuoBar from the package manager while still in Safe Mode, then respring.
3. Open Settings → Privacy & Security → Analytics & Improvements → Analytics Data. Find the newest `SpringBoard-<date>.ips` entry from the time of the crash. Also look for `ExcResource_SpringBoard-<date>` or `JetsamEvent-<date>` entries from the same minute.
4. Share the complete `.ips` file, not a screenshot. Its exception type, termination reason, crashed thread and any frames mentioning `DuoBar.dylib` identify the cause.

Then restore stable v2.7.1 or wait for a fixed CI beta. Stable v2.7.1 and the Sileo source remain unchanged.
