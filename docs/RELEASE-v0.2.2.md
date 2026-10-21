# DuoBar v0.2.2 — Settings icon compatibility update

A small compatibility update for **iOS 16.x with Dopamine RootHide**.

## Fixed
- DuoBar icon missing from the iOS **Settings** tweak list.
- Installed the approved blue DuoBar artwork inside **DuoBarPrefs.bundle**, where PreferenceLoader loads its icon, as well as in the usual PreferenceLoader folder.
- Added a robust icon-file fallback for the icon in the settings page header.
- Updated the package version shown in both **Settings → DuoBar** and Sileo to **0.2.2**.

All previously confirmed v0.2.1 Control Center fixes, preferences, and RBx9 Repo links are retained.

## Installation

Open **Sileo → Sources → RBx9 Repo**, refresh, and choose **Upgrade** on **DuoBar (RootHide)**. The repo URL is `https://rbx9.github.io/`. Respring and fully close/reopen Settings after installing, as Settings can cache icons.

You can also install the attached `DuoBar_0.2.2_RootHide.deb` manually with a RootHide-compatible package manager.

Package: `local.duobar` · Architecture: `iphoneos-arm64e` · Version: `0.2.2`.

The installer is built and icon files inspected by GitHub Actions; the new Settings icon still needs a final visual confirmation on your phone.
