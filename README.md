# DuoBar

An iPhone Duo-inspired status bar for **iOS 16 with Dopamine RootHide**. DuoBar brings battery percentage, Wi-Fi strength, and cellular signal together in one circular icon.

Developed by **RBx9** · [Twitter / X: @RedaBuali](https://twitter.com/RedaBuali)

![DuoBar demonstration showing the circular battery ring, percentage, central Wi-Fi symbol, and four cellular dots](docs/demo.png)

*Design preview drawn from the tweak’s icon geometry; not a device screenshot.*

## Download

[**Download DuoBar v0.2.0 for RootHide (.deb)**](https://github.com/RBx9/DuoBar/releases/download/v0.2.0/DuoBar_0.2.0_RootHide.deb)

[All releases](https://github.com/RBx9/DuoBar/releases) · [Repository copy](downloads/DuoBar_0.2.0_RootHide.deb?raw=true)

No compiling is needed. The supplied package uses RootHide’s `iphoneos-arm64e` package format.

## Features

- Battery percentage above an open circular charge ring.
- Wi-Fi strength in the center and four cellular signal dots below.
- Charging indicator, low-battery red, and Low Power Mode yellow.
- Light and dark status-bar styling, with clear gaps around the cellular dots.
- A persistent **Enable DuoBar** switch in **Settings → DuoBar**.

## Install

1. Download the `.deb` on your jailbroken iPhone.
2. Open it in your RootHide package manager or RootHide-compatible Filza and install it.
3. Respring once, then reopen Settings and any apps that were already running.
4. Open **Settings → DuoBar** to turn the design on or off. Switch changes apply immediately.

Existing DuoBar installations can be upgraded with the same package. See the [installation guide](docs/INSTALL.md) for more detail.

## Compatibility

The supplied download targets **iOS 16.x and Dopamine RootHide**, with tweak injection and PreferenceLoader. PreferenceLoader is declared as a package dependency. This download is not a standard Dopamine/rootless package.

Version 0.2.0 has been compiled and package-checked. Its new Settings page and live switch still need on-device verification. Read the [build verification](docs/BUILD-VERIFICATION.md) and [device checklist](docs/DEVICE-TESTING.md) for the scope of validation.

## Build from source

The included [Build DuoBar workflow](.github/workflows/build.yml) runs manually through GitHub Actions on macOS. It produces separate RootHide and standard rootless artifacts; the workflow itself has not been run for this release.

Local builds require Theos, an iOS SDK, and a compatible compiler. RootHide builds require the [RootHide Theos fork](https://github.com/roothide/theos):

```sh
make clean package FINALPACKAGE=1 THEOS_PACKAGE_SCHEME=roothide
```

See [build verification](docs/BUILD-VERIFICATION.md) for the supplied binary’s toolchain, arm64e conversion, and signing details.

## License

Source code is available under the [MIT license](LICENSE).
