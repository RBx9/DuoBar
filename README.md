# DuoBar

An iPhone Duo-inspired status bar for **iOS 16 with Dopamine RootHide or standard Rootless**. DuoBar brings battery percentage, Wi-Fi strength, and cellular signal together in one circular icon.

Developed by **RBx9** · [Twitter / X: @RedaBuali](https://twitter.com/RedaBuali)

![DuoBar demonstration showing the circular battery ring, percentage, central Wi-Fi symbol, and four cellular dots](docs/demo.png)

*Design preview drawn from the tweak’s icon geometry; not a device screenshot.*

## Install using Sileo (recommended)

1. Open **Sileo → Sources → +**.
2. Add the **RBx9 Repo** source: **https://rbx9.github.io/**
3. Refresh sources, open **RBx9 Repo**, and install **DuoBar**.
4. Respring, then open **Settings → DuoBar** to configure it.

The **RBx9 Repo** hosts two distinct iOS 16 packages: **DuoBar (RootHide)** for Dopamine RootHide and **DuoBar (Rootless)** for standard Rootless/Dopamine. Install only the package matching your jailbreak.

## Download .deb manually

[**Download DuoBar v2.7.1 for RootHide (.deb)**](https://github.com/RBx9/DuoBar/releases/download/v2.7.1/DuoBar_2.7.1_RootHide.deb)

[**Unified v2.7.1 Release (RootHide and Rootless)**](https://github.com/RBx9/DuoBar/releases/tag/v2.7.1) · [Previous stable v0.2.6](https://github.com/RBx9/DuoBar/releases/tag/v0.2.6)

**Standard Rootless edition:** [DuoBar v2.7.1 Rootless .deb](https://github.com/RBx9/DuoBar/releases/download/v2.7.1/DuoBar_2.7.1_Rootless.deb) · [Rootless compatibility and installation](docs/ROOTLESS.md). It uses the separate package ID `local.duobar.rootless` and `iphoneos-arm64`. The package passed build verification but still needs an on-device Rootless test.

No compiling is needed. The RootHide package uses `iphoneos-arm64e`; standard Rootless uses `iphoneos-arm64`.

## Features

- Battery percentage above an open circular charge ring.
- Wi-Fi strength in the center and four cellular signal dots below.
- Charging indicator, low-battery red, and Low Power Mode yellow.
- Light and dark status-bar styling, with clear gaps around the cellular dots.
- A persistent **Enable DuoBar** switch in **Settings → DuoBar**.
- Adjustable **DuoBar Size** slider (70%–140%), a current-size percentage, and Reset Size to 100%. Changes apply without respringing.
- Fixes for duplicate battery percentage and rotation-lock icon overlap in Control Center.
- **v0.2.5 RootHide:** Personal Hotspot chain-link inside DuoBar, reliable Control Center rotation-lock spacing and no brief native-icon flash during transitions.
- A clean transparent Settings icon and organized preference page with direct **RBx9 Repo** and **Sileo source** links.
- **Report a Bug** and **Help Test Other iOS Versions** email actions in Settings; bug reports suggest attaching a screenshot or short video.
- Improved links and update options in **Settings → DuoBar → Links & Updates**.
- v0.2.2 fixes PreferenceLoader icon discovery by including icon sizes in the actual preferences bundle.

## Manual installation

1. Download the `.deb` on your jailbroken iPhone.
2. Open it in your RootHide package manager or RootHide-compatible Filza and install it.
3. Respring once, then reopen Settings and any apps that were already running.
4. Open **Settings → DuoBar** to turn the design on or off. Switch changes apply immediately.

Existing DuoBar installations can be upgraded with the same package. See the [installation guide](docs/INSTALL.md) for more detail.

## Compatibility

The supplied download targets **iOS 16.x and Dopamine RootHide**, with tweak injection and PreferenceLoader. PreferenceLoader is declared as a package dependency. This download is not a standard Dopamine/rootless package.

This v2.7.1 release changes the version numbering and retains the existing v0.2.7 indicator and Settings features for both editions. Both installers passed automated build checks; on-device confirmation for standard Rootless is still needed. Read the [device checklist](docs/DEVICE-TESTING.md) for further compatibility testing.

## Build from source

The stable RootHide installer is compiled by a dedicated GitHub Actions workflow with package metadata and transparent Settings icon verification. Rootless is a separately built package using standard Theos and the `iphoneos-arm64` architecture.

Local builds require Theos, an iOS SDK, and a compatible compiler. RootHide builds require the [RootHide Theos fork](https://github.com/roothide/theos):

```sh
make clean package FINALPACKAGE=1 THEOS_PACKAGE_SCHEME=roothide
```

See [build verification](docs/BUILD-VERIFICATION.md) for the supplied binary’s toolchain, arm64e conversion, and signing details.

## License

Source code is available under the [MIT license](LICENSE).
