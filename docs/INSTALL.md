# Install DuoBar

The supplied `.deb` is for **iOS 16.x with Dopamine RootHide**. Its package architecture is `iphoneos-arm64e`. It requires working tweak injection and PreferenceLoader; the package manager handles declared dependencies.

## Installation or upgrade

1. On your iPhone, [download DuoBar v0.2.0](https://github.com/RBx9/DuoBar/releases/download/v0.2.0/DuoBar_0.2.0_RootHide.deb).
2. Open the downloaded file in your RootHide package manager or RootHide-compatible Filza, then install it.
3. If an earlier DuoBar version is installed, install this package over it.
4. Respring when installation finishes.
5. Close and reopen Settings and any apps that were running before installation.

## Turn the design on or off

Open **Settings → DuoBar** and use **Enable DuoBar**.

- **On:** show the circular battery, Wi-Fi, and cellular design.
- **Off:** restore the system’s original status-bar icons.

The switch is intended to apply immediately, and its saved state is read when apps start or become active. A respring is needed for initial installation, not for ordinary switch changes. The new Settings functionality in v0.2.0 has not yet been verified on a device.

The same page includes the tweak description, version, developer credit, and a Twitter / X link for [@RedaBuali](https://twitter.com/RedaBuali).

## Remove DuoBar

Remove **DuoBar** in the package manager and respring. This restores the stock icons.

If another status-bar tweak changes the same icons, disable that tweak while checking DuoBar’s appearance. If a compatibility issue prevents normal loading, use the jailbreak’s recovery or tweak-disable option to remove DuoBar.

See [build verification](BUILD-VERIFICATION.md) for binary checks and [device testing](DEVICE-TESTING.md) for runtime checks still to complete.
