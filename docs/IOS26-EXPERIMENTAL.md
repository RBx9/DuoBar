# DuoBar iOS 26 — Experimental Rootless Test

**This is an unverified compatibility prototype, not a stable release.**

Dopamine 3 provides a standard Rootless jailbreak on **selected A12/A13 iPhones running iOS 26.0 or 26.0.1**. This separate package is **not** intended for all iOS 26 devices, newer iPhones without compatible jailbreaks, or devices running 26.1+.

## How this prototype works

The iOS 16 DuoBar codebase is rebuilt as a separate Rootless package named **DuoBar (iOS 26 Experimental)**, with a different package ID: `local.duobar.ios26`. Its installation is restricted by firmware dependencies to **26.0–26.0.1**.

The loader checks the running OS and the presence of every required private UIKit battery/status-bar method before enabling any hooks. If Apple changed an essential class or selector, **DuoBar stays inactive instead of hiding the stock indicators**. The system log will show a `[DuoBar iOS26 Beta]` compatibility message.

Compiling and checking the iOS package does **not** establish functional support for iOS 26. Private status-bar views and Liquid Glass layout have not been validated. The experimental package is built against the available iOS 16.5 SDK; runtime compatibility still has to be demonstrated on a device.

## Installation

- Requires a compatible **standard Dopamine Rootless** jailbreak on a supported iOS **26.0–26.0.1** device.
- Install **DuoBar_0.2.8-iOS26-Rootless-Beta1.deb** through a Rootless-compatible package manager.
- Respring. Check **Settings → DuoBar**; the version should show `0.2.8 iOS 26 Beta 1`.
- Test battery %, Wi-Fi, cellular, charging, Control Center, Personal Hotspot, landscape and dark/light backgrounds. Try 70% and 140% sizes.
- If the stock indicators stay unchanged, report the OS/build/model and the `[DuoBar iOS26 Beta]` log line, as this likely means a private iOS 26 class or selector changed.
- If SpringBoard crashes, boot into a tweak-disabled/safe mode and uninstall `local.duobar.ios26`.

**This test package is deliberately NOT listed in the public RBx9 Sileo source yet.** Existing RootHide and Rootless iOS 16 releases stay unchanged. Wait for real-device confirmation before describing DuoBar as supported on iOS 26.

## How to help

Use Settings → DuoBar → **Report a Bug** to prepare an email to `Rmbx998@gmail.com`. Include device model, exact iOS version and a screenshot or screen recording if possible. Report any status-bar crashes or safe-mode entries.

Source: https://github.com/RBx9/DuoBar
