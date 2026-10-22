# DuoBar (Rootless) v0.2.6 — iOS 16

**Initial updated standard Rootless build.** This edition is compiled for **Dopamine Rootless** (not RootHide) and needs real-device testing.

## What's new

- Clean rounded Settings icon, with transparent corners and no white background.
- **Report a Bug** shortcut that prepares an email draft and suggests attaching a screenshot or short video.
- **Help Test Other iOS Versions** invitation for volunteers with other iOS versions and jailbreaks.
- Updated to the v0.2.6 codebase, including the Personal Hotspot symbol inside DuoBar, Control Center rotation-lock positioning, smoother transitions, and the 70%–140% size slider.

## Installation

Open **Sileo → Sources → RBx9 Repo** (`https://rbx9.github.io/`) and choose **DuoBar (Rootless) v0.2.6**. Respring after upgrading. Close/reopen Settings if the previous icon is cached.

The same installer is attached as `DuoBar_0.2.6_Rootless.deb`. Install **only on standard Rootless/Dopamine iOS 16**, not RootHide. Do not install both versions.

**Package ID:** `local.duobar.rootless` · **Version:** `0.2.6` · **Architecture:** `iphoneos-arm64` · **Prefix:** `/var/jb`.

## Verification and limitations

The installer is compiled and checked with standard Theos for the Rootless package architecture, /var/jb layout, PreferenceLoader icon assets, and version. **It has not yet been confirmed on a real Rootless iPhone**, so test the status-bar icon, Control Center, hotspot, Settings icon, email buttons and slider after installation. If you encounter a crash, uninstall from your package manager or use the jailbreak's tweak-disabled/safe mode.

**RootHide users:** Install [DuoBar (RootHide) v0.2.6](https://github.com/RBx9/DuoBar/releases/tag/v0.2.6) instead.

[Source code](https://github.com/RBx9/DuoBar) · [RBx9 Repo](https://rbx9.github.io/) · Developer **RBx9**.
