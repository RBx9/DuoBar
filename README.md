# DuoBar

An iPhone Duo-inspired status bar for **iOS 16 with Dopamine RootHide**. DuoBar brings battery percentage, Wi-Fi strength, and cellular signal together in one circular icon.

Developed by **RBx9** · [Twitter / X: @RedaBuali](https://twitter.com/RedaBuali)

![DuoBar demonstration showing the circular battery ring, percentage, central Wi-Fi symbol, and four cellular dots](docs/demo.png)

*Design preview drawn from the tweak’s icon geometry; not a device screenshot.*

## Install using Sileo (recommended)

1. Open **Sileo → Sources → +**.
2. Add the **RBx9 Repo** source: **https://rbx9.github.io/**
3. Refresh sources, open **RBx9 Repo**, and install **DuoBar**.
4. Respring, then open **Settings → DuoBar** to configure it.

This source is shared with future RBx9 tweaks, so you won't need to add a new source for each release. The included installer requires **Dopamine RootHide on iOS 16**.

## Download .deb manually

[**Download DuoBar v0.2.1 for RootHide (.deb)**](https://github.com/RBx9/DuoBar/releases/download/v0.2.1/DuoBar_0.2.1_RootHide.deb)

[All releases](https://github.com/RBx9/DuoBar/releases) · [Previous v0.2.0](https://github.com/RBx9/DuoBar/releases/tag/v0.2.0)

No compiling is needed. The supplied package uses RootHide’s `iphoneos-arm64e` package format.

## Features

- Battery percentage above an open circular charge ring.
- Wi-Fi strength in the center and four cellular signal dots below.
- Charging indicator, low-battery red, and Low Power Mode yellow.
- Light and dark status-bar styling, with clear gaps around the cellular dots.
- A persistent **Enable DuoBar** switch in **Settings → DuoBar**.
- Fixes for duplicate battery percentage and rotation-lock icon overlap in Control Center.
- An icon and organized preference page with direct **RBx9 Repo** and **Sileo source** links.

## Manual installation

1. Download the `.deb` on your jailbroken iPhone.
2. Open it in your RootHide package manager or RootHide-compatible Filza and install it.
3. Respring once, then reopen Settings and any apps that were already running.
4. Open **Settings → DuoBar** to turn the design on or off. Switch changes apply immediately.

Existing DuoBar installations can be upgraded with the same package. See the [installation guide](docs/INSTALL.md) for more detail.

## Compatibility

The supplied download targets **iOS 16.x and Dopamine RootHide**, with tweak injection and PreferenceLoader. PreferenceLoader is declared as a package dependency. This download is not a standard Dopamine/rootless package.

The Control Center positioning fix was confirmed on a test device. The new v0.2.1 Settings icon and links have been build-checked but should also be checked on-device after upgrading. Read the [device checklist](docs/DEVICE-TESTING.md) for further compatibility testing.

## Build from source

The included [Build DuoBar workflow](.github/workflows/build.yml) runs manually through GitHub Actions on macOS. It produces separate RootHide and standard rootless artifacts; the workflow itself has not been run for this release.

Local builds require Theos, an iOS SDK, and a compatible compiler. RootHide builds require the [RootHide Theos fork](https://github.com/roothide/theos):

```sh
make clean package FINALPACKAGE=1 THEOS_PACKAGE_SCHEME=roothide
```

See [build verification](docs/BUILD-VERIFICATION.md) for the supplied binary’s toolchain, arm64e conversion, and signing details.

## License

Source code is available under the [MIT license](LICENSE).
