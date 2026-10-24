# DuoBar v2.7.2 Beta 5 — Rootless package verification

Beta 5 is rebuilt by GitHub Actions with the standard Theos toolchain. Its Rootless package uses `iphoneos-arm64` and includes both `arm64` and `arm64e` slices. CI checks that the Settings executable and its parent directories are accessible for execution. The 5G/LTE label is slightly larger than in beta4.

Install only the standard Dopamine Rootless package `DuoBar_2.7.2-beta5_Rootless.deb` (package `local.duobar.rootless`). Do not install the locally built beta5 or beta6 packages previously shared in chat.

## Device checks

- Open Settings → DuoBar and confirm the preferences load, the icon and size slider appear, and the enable switch works.
- Confirm DuoBar appears on the Home Screen, in apps, and in Control Center.
- Rotate the screen and rapidly open/close Control Center. Confirm the stock battery does not return and DuoBar does not jump, disappear, or trigger Safe Mode.
- Check the Wi-Fi/Personal Hotspot mark, battery percentage, cellular dots, and 5G/LTE label.
- Test the size slider at 70%, 100%, and 140%, then toggle DuoBar off and on.

If SpringBoard enters Safe Mode, disable tweak injection in Dopamine, uninstall DuoBar, and restore the last CI-built beta4 or stable v2.7.1. Stable release and Sileo source remain unchanged.
