# DuoBar v0.2.6 (Rootless) — iOS 16

This is the **standard Rootless/Dopamine** build of DuoBar, using the same
v0.2.6 drawing engine and settings as the RootHide edition, but compiled
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

The RootHide v0.2.6 build was tested on-device, but the standard Rootless
edition still has no independent on-device confirmation. Automated compilation
and package verification cannot guarantee iOS private status-bar compatibility.

If a conflict, missing UI, or SpringBoard crash occurs, remove the package via
your package manager or jailbreak safe mode. The known working RootHide package
remains unchanged.

## Developers
`packaging/control.rootless` contains independent Debian metadata.
`control` remains the RootHide version. The CI rootless workflow makes a
temporary copy of the rootless control file while building, without modifying
the stable RootHide source tree.

The source URL remains `https://rbx9.github.io/`.
