# DuoBar v0.2.3 — Rootless iOS 16 (Initial Release)

**Initial standard Rootless/Dopamine build — device testing is still needed.**

This is a separate package from DuoBar (RootHide). It is for **iOS 16.x with a standard Rootless jailbreak**, such as Dopamine. Do **not** install it on RootHide.

## Features

- Same circular battery percentage, Wi‑Fi, and cellular-signal indicator as DuoBar v0.2.3.
- Same **Settings → DuoBar** panel, blue tweak icon, and **70%–140% size slider**.
- Live size and enable/disable preference changes.
- Includes existing Control Center percentage and rotation-lock improvements.

## Compatibility

- Package: `local.duobar.rootless`
- Architecture: `iphoneos-arm64`
- iOS: 16.0–16.x
- Installation prefix: `/var/jb`
- Standard Rootless only; **not RootHide**.
- Separate from the RootHide package `local.duobar`. Do not install both variants.

## Install

Add **RBx9 Repo** in Sileo: `https://rbx9.github.io/`. Locate **DuoBar (Rootless)** and install. Respring after installation.

Alternatively download the attached **DuoBar_0.2.3_Rootless.deb** and install via a Rootless-compatible package manager.

## Testing status

The package has passed a standard Theos Rootless compile, architecture and metadata checks, `/var/jb` file-layout checks, and Settings icon inspection. These tests **cannot prove the private iOS 16 status-bar hooks behave correctly on your device**. On-device validation is pending. If you encounter crashes or missing icons, remove the package and respring through a safe mode or your package manager.

[Source and implementation details](https://github.com/RBx9/DuoBar) · [Rootless build guide](https://github.com/RBx9/DuoBar/blob/main/docs/ROOTLESS.md).
