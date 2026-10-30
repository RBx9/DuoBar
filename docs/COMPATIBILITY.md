# DuoBar compatibility (October 2026)

DuoBar is enabled on **iOS 16.0–16.7.x only**. Both packages declare `firmware (>= 16.0), firmware (<< 17.0)`, and the tweak checks the same range at runtime (`DUO_MAX_IOS_MAJOR`, tied to the packages by `scripts/check-private-api.py`). At load it also checks every private class and selector it hooks, and leaves out any feature whose API is missing.

## What each status means

- **Package-verified**: GitHub Actions built the package with the official Theos toolchains and `scripts/verify-deb.py` passed (metadata, 0755/0644 modes, arm64 + new-ABI arm64e slices, signatures, linkage, no non-weak private-class imports, plists, warning-free build log).
- **Simulator-tested**: DuoBar was loaded into SpringBoard in an iOS simulator by `.github/workflows/simulator-check.yml`, rendered on the Home Screen, and traced while Control Center opened and closed. A simulator is not a jailbroken device.
- **Device-tested**: installed and tested on a physical jailbroken iPhone and reported back. Only stated where a report exists.
- **Unavailable**: the iPhone cannot run that iOS version, or there is no public jailbreak with tweak injection for that combination.

## iPhone 12–18

There is no iOS 19–25: Apple went from iOS 18 to iOS 26.

| iPhone (chip) | iOS 16 | iOS 17 | iOS 18 | iOS 26 |
|---|---|---|---|---|
| 12, 12 mini, 12 Pro, 12 Pro Max (A14) | **Supported** where a jailbreak covers the build¹. Package-verified; simulator-tested (12 on 16.4). | Jailbreak reported for 17.0–17.3.1². DuoBar not enabled³. | No public jailbreak | No public jailbreak |
| 13, 13 mini, 13 Pro, 13 Pro Max (A15) | **Supported** where a jailbreak covers the build¹. Package-verified; simulator-tested (13 mini on 16.4). | Jailbreak reported for 17.0–17.3.1². DuoBar not enabled³. | No public jailbreak | No public jailbreak |
| 14, 14 Plus (A15), 14 Pro, 14 Pro Max (A16) | **Supported** where a jailbreak covers the build¹. Package-verified; simulator-tested (14, 14 Pro, 14 Pro Max on 16.4); **device-tested: 14 Pro Max on 16.4.1**⁴. | Jailbreak reported for 17.0–17.3.1². DuoBar not enabled³. | No public jailbreak | No public jailbreak |
| 15, 15 Plus (A16), 15 Pro, 15 Pro Max (A17 Pro) | Unavailable: shipped with iOS 17 | Jailbreak reported for 17.0–17.3.1². DuoBar not enabled³. | No public jailbreak | No public jailbreak |
| 16, 16 Plus, 16 Pro, 16 Pro Max, 16e (A18) | Unavailable | Unavailable | No public jailbreak | No public jailbreak |
| 17, Air, 17 Pro, 17 Pro Max, 17e (A19) | Unavailable | Unavailable | Unavailable | No public jailbreak |
| 18 Pro, 18 Pro Max (A20 Pro) | Unavailable: shipped with iOS 27 | Unavailable | Unavailable | Unavailable |

No other iPhone 12–18 model has a beta 8 device report yet. Stable v2.7.1 Rootless was community-tested on iPhones that were not identified.

1. Dopamine and Dopamine RootHide cover iOS 16 up to 16.5–16.6.1 depending on the chip. Public sources disagree on whether A15/A16 are covered on 16.5.1–16.6.1, so testers should check their exact build.
2. Dopamine 3.0 (August 2026) reportedly supports iOS 16.5.1–17.3.1 on these chips. iOS 17.4 and later have no public jailbreak on A14 and newer.
3. See *iOS 17, 18 and 26 in the simulator* below.
4. Beta 8 device report (30 October 2026): iPhone 14 Pro Max on iOS 16.4.1, reported stable. The tester did not state the jailbreak or package variant, or report on the specific checks in `docs/TEST-v2.7.2-beta8.md`.

The base iPhone 18 and 18e were not released as of October 2026.

## Older iPhones

| iPhone | Jailbreak | DuoBar |
|---|---|---|
| XS, XS Max, XR (A12) | Dopamine/RootHide on iOS 16; Dopamine 3.0 reportedly also iOS 17 and 18 up to 18.7.1. These iPhones cannot install iOS 26. | iOS 16 supported. Not enabled on 17 or 18. |
| 11, 11 Pro, 11 Pro Max, SE 2 (A13) | Dopamine/RootHide on iOS 16; Dopamine 3.0 reportedly also iOS 17, 18 up to 18.7.1, and 26.0–26.0.1 | iOS 16 supported. Not enabled on 17, 18 or 26. |
| 8, 8 Plus, X (A11) | palera1n (Rootless) on iOS 16 | iOS 16 supported via the Rootless package's arm64 slice. An iPhone 8 Plus tester reported the large-size clipping fixed in beta 7; the fix was simulator-tested on a 20 pt status bar (iPhone SE, iOS 16.4). |

## Simulator results (beta 8 code)

**iOS 16.4, release build, inside SpringBoard.** Home Screen and Control Center at 70%, 100% and 140% on the iPhone 12, 13 mini, 14, 14 Pro and 14 Pro Max: DuoBar fully on screen, no overlap with the time or carrier text. When Control Center closes, its DuoBar now lands exactly on the Home Screen's DuoBar (0.0 pt jump). Before beta 8 the jump was 12 pt sideways and up to 7.2 pt down. On the iPhone SE (20 pt status bar) at 140%, the ring is 25.2 pt tall with its top 1 pt below the screen edge. App status bars on iOS 16.4 simulators are drawn by SpringBoard rather than inside the app.

**Private API.** Every class and selector DuoBar hooks or reads exists with identical type encodings on iOS 16.4, 17.5, 18.6, 26.2 and 26.5 (49 checks). The Control Center classes exist only in SpringBoard.

**iOS 17, 18 and 26, test build with the version gate raised (never packaged).** SpringBoard did not crash with DuoBar loaded on iOS 17.5, 18.6, 26.2 or 26.5.
- iOS 17.5: Control Center opened and closed normally, and DuoBar attached to Control Center's status bar. It did not attach to the Home Screen's status bar: no battery view was found in any SpringBoard window there, so the Home Screen status bar is drawn somewhere DuoBar does not reach.
- iOS 18.6 and 26.x: DuoBar attached nowhere, and no status-bar views were found in SpringBoard's windows. The test could not open Control Center (the SpringBoard class it uses no longer exists), so Control Center was not exercised on these versions.

Supporting these versions therefore first needs research into where iOS 17 and later draw the Home Screen status bar. On iOS 18 this only matters for the iPhone XS, XR, 11 and SE 2 (up to 18.7.1), and on iOS 26 only for the iPhone 11 family and SE 2 on 26.0–26.0.1 (the XS and XR cannot install iOS 26), because newer iPhones have no public jailbreak there.

## Sources for jailbreak availability

- Dopamine 3.0 release coverage (MacRumors, 7 August 2026; iClarified, 7 August 2026): iOS 26.0–26.0.1 on A12/A13, iOS 16.5.1–17.3.1 on newer arm64e devices.
- Dopamine repository description: iOS 15.0–17.3.1 (arm64e); iOS 15.0–18.7.1 and 26.0–26.0.1 (A12/A13).
- palera1n (The Apple Wiki, GitHub): checkm8 devices (A8–A11) on iOS 15–17.
- Apple Firmwares (7 October 2026) reports no public jailbreak for iOS 27, or for iOS 17, 18 or 26 on any iPhone from the XS/XR onward. That contradicts the Dopamine 3.0 coverage above.

These sources disagree, and jailbreak support changes. Re-check before relying on a specific build.
