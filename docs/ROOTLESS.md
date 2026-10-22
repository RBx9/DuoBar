# DuoBar v2.7.1 (Rootless) — iOS 16

This is the **standard Rootless/Dopamine** build of DuoBar, using the same
v2.7.1 drawing engine and settings as the RootHide edition, but compiled
for the `iphoneos-arm64` rootless environment.

## Package separation
- **DuoBar (RootHide)** — `local.duobar`, `iphoneos-arm64e`
- **DuoBar (Rootless)** — `local.duobar.rootless`, `iphoneos-arm64`

Both share the same codebase. Do not install both variants simultaneously.
A conflict is declared to prevent accidentally installing both under one
package manager. The rootless package owns the `/var/jb` preferences,
dynamic library, and PreferenceLoader files.

## Compatibility and testing
This build targets **iOS 16.0–16.x with Dopamine Rootless**. Private status
bar view classes can vary across iOS versions and devices. A successful build
does not prove that the tweak actually displays or resizes correctly.

To test: install from Sileo on a Rootless jailbroken device, respring, then
check that the glyph is visible, Control Center does not duplicate the battery
percentage, rotation lock doesn't overlap, and Settings → DuoBar shows the
size slider, transparent blue icon, bug-report email and iOS testing links.
Test Personal Hotspot connecting/disconnecting, transitions, rotation lock,
and size values of 70%, 100% and 140%. Ensure the off switch restores native
icons. Report bugs with screenshots if possible.

The underlying RootHide features were tested on-device, and **community members have now also tested the standard Rootless edition on actual iPhones**. The v2.7.1 packages passed automated compilation and file-layout checks, but this does not establish compatibility with every iOS 16 build or iPhone model. Please continue reporting device-specific issues.

If a conflict, missing UI, or SpringBoard crash occurs, remove the package via
your package manager or jailbreak safe mode. The known working RootHide package
remains unchanged.

## Developers
`packaging/control.rootless` contains independent Debian metadata.
`control` remains the RootHide version. The CI rootless workflow makes a
temporary copy of the rootless control file while building, without modifying
the stable RootHide source tree.

The source URL remains `https://rbx9.github.io/`.
