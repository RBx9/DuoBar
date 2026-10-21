# DuoBar v0.2.5 — Personal Hotspot & Control Center (RootHide)

**Stable release for iOS 16.x with Dopamine RootHide**, promoted after on-device confirmation of Beta 10.

## What's new

- **Personal Hotspot support:** the chain-link icon now appears inside the DuoBar circle when connected to another iPhone's hotspot.
- **Rotation-lock overlap fixed:** the orientation-lock indicator is placed to the left of DuoBar when opening Control Center, instead of overlapping the ring.
- **Smoother transitions:** native battery/Wi-Fi/cellular icons no longer briefly flash over DuoBar when entering or leaving Control Center.
- Preserves the customizable **70%–140% size slider**, charging / Low Power Mode colors, Settings icon, and live on/off switch.

## Install / upgrade

1. Open **Sileo → Sources → RBx9 Repo** (`https://rbx9.github.io/`) and refresh.
2. Select **DuoBar (RootHide) v0.2.5** and tap **Upgrade**.
3. Respring after installation.

Alternatively install the attached `DuoBar_0.2.5_RootHide.deb` with a RootHide-compatible package manager.

**Package:** `local.duobar` · **Architecture:** `iphoneos-arm64e` · **Supported OS:** iOS 16.x.

**Important:** **DuoBar (Rootless)** is a separate package (`local.duobar.rootless`) and remains at **v0.2.3**; it has not received these RootHide-tested fixes yet. Do not install the RootHide binary on standard Rootless.

### Device testing

Beta 10 fixed the Control Center rotation-lock overlap and was explicitly approved for stable release by the tester. Earlier hotspot and transition fixes were also confirmed on-device. Other iOS 16 builds and devices may have different private status-bar view layouts.

Developed by **RBx9** · [RBx9 Repo](https://rbx9.github.io/) · [GitHub source](https://github.com/RBx9/DuoBar).
