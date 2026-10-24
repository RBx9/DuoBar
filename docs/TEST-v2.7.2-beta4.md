# DuoBar v2.7.2 Beta 4 — RootHide and Rootless

Beta 4 fixes the Rootless Settings loading error on arm64e devices. The Rootless package remains `iphoneos-arm64` for package-manager compatibility, and now includes both `arm64` and `arm64e` slices in the Preference bundle executable and tweak library. Beta 4 also retains the rotation and Control Center transition fix.

Install only the package matching the jailbreak:

- **Dopamine RootHide:** `DuoBar_2.7.2-beta4_RootHide.deb`, package `local.duobar`.
- **Standard Dopamine Rootless:** `DuoBar_2.7.2-beta4_Rootless.deb`, package `local.duobar.rootless`.

Do not install both variants.

## Device checks

- On standard Rootless, open Settings → DuoBar. Confirm the preference bundle loads without the incompatible-architecture error, shows the icon and size slider, and the enable switch works.
- Confirm DuoBar appears in the Home Screen, inside apps, and in Control Center.
- Rotate between portrait and landscape, including while opening and closing Control Center. Confirm the stock battery does not return and DuoBar does not jump or disappear.
- Confirm Wi-Fi or the Personal Hotspot chain, battery percentage, and cellular dots appear as expected.
- Test the size slider at 70%, 100%, and 140% and toggle DuoBar off and on to confirm the native indicators restore.

Both package builds, metadata, and install paths are checked by CI. Live iPhone behavior still needs community testing on iOS 16 with Dopamine.
