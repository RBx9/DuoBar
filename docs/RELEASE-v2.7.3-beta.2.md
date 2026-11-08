DuoBar 2.7.3 beta 2 is a test build for iOS 16, for Dopamine RootHide and standard Rootless (Dopamine, palera1n). It is not on Sileo. Stable 2.7.2 is unchanged.

## Fixes

- **Ring jumping left and right:** on an iPhone 8 Plus, DuoBar flickered sideways while the red screen-recording bar was showing. UIKit briefly dropped the native battery from a layout pass, so DuoBar anchored to the Wi-Fi icon instead. It now stays at the battery's last position until the battery is back.
- **Control Center percentage:** still includes beta 1's fix for "%33" (Turkish) and "33 %" (French).

## Install

Download the `.deb` for your jailbreak (`Rootless` for Dopamine Rootless or palera1n, `RootHide` for Dopamine RootHide), open it in your package manager and respring.
