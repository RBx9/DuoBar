# Install DuoBar

The supplied `.deb` is for **iOS 16.x with Dopamine RootHide**. Its package architecture is `iphoneos-arm64e`. It requires working tweak injection and PreferenceLoader; the package manager handles declared dependencies.

## Install from Sileo (recommended)

1. Open **Sileo → Sources → +**.
2. Add **https://rbx9.github.io/** (RBx9 Repo).
3. Refresh your sources, find **DuoBar** in RBx9 Repo, and install or upgrade it.
4. Respring, then reopen Settings and any previously running apps.

You can keep the same RBx9 Repo source for future compatible tweaks and upgrades. This version is for **RootHide**; the separate **Rootless** edition has a v2.7.1 build for standard Dopamine Rootless iOS 16. Choose the correct package; the RootHide installer is not compatible with Rootless.

## Manual .deb installation or upgrade

1. On your iPhone, [download DuoBar v2.7.1](https://github.com/RBx9/DuoBar/releases/download/v2.7.1/DuoBar_2.7.1_RootHide.deb).
2. Open the downloaded file in your RootHide package manager or RootHide-compatible Filza, then install it.
3. If an earlier DuoBar version is installed, install this package over it.
4. Respring when installation finishes.
5. Close and reopen Settings and any apps that were running before installation.

## Turn the design on or off

Open **Settings → DuoBar** and use **Enable DuoBar**.

- **On:** show the circular battery, Wi-Fi, and cellular design.
- **Off:** restore the system’s original status-bar icons.

The switch is intended to apply immediately, and its saved state is read when apps start or become active. A respring is needed for initial installation, not for ordinary switch changes. Version 0.2.1 adds the Settings icon and repository links; these new preference elements should be checked on-device after updating.

The page includes the tweak description, version, developer credit, and links to [RBx9 Repo](https://rbx9.github.io/), Sileo, the GitHub project, and [@RedaBuali](https://twitter.com/RedaBuali).

## Adjust the size

Open **Settings → DuoBar → DuoBar Size**. Drag the slider from **70% to 140%**, in 5% steps, and see the result without respringing. Use **Reset Size to 100%** to restore the original size. Compact status bars can limit large sizes.

## Report an issue or help test another iOS version

In **Settings → DuoBar → Feedback & iOS Testing**, choose **Report a Bug** to compose an editable email with the current DuoBar and iOS versions. Attach a screenshot or screen recording in the email app if possible. Choose **Help Test Other iOS Versions** to volunteer an iPhone model, iOS version, and jailbreak details. Neither option sends an email automatically.

## Remove DuoBar

Remove **DuoBar** in the package manager and respring. This restores the stock icons.

If another status-bar tweak changes the same icons, disable that tweak while checking DuoBar’s appearance. If a compatibility issue prevents normal loading, use the jailbreak’s recovery or tweak-disable option to remove DuoBar.

See [build verification](BUILD-VERIFICATION.md) for binary checks and [device testing](DEVICE-TESTING.md) for runtime checks still to complete.
