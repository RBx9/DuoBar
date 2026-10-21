# Build verification

The distributed `DuoBar_0.2.0_RootHide.deb` was compiled and package-checked on Linux. Version 0.2.0 has **not yet been validated on an iPhone**.

This release includes separated cellular dots and a Settings bundle with a persistent live enable switch, RBx9 developer credit, a description, and the @RedaBuali Twitter link. The Settings integration has been reviewed and package-checked; runtime checks remain listed in the device checklist.

SHA-256: `6e50eb08bbf7babb3996504c23bb1d22b4e97d542e1809fec64eb43458f80781`.

## Build

- RootHide Theos fork and its recursive submodules.
- Theos patched iPhoneOS 16.5 SDK; deployment target iOS 16.0.
- Kabir Oberai's Swift 5.8 Linux toolchain, reporting Apple LLVM/Clang 13.0.0 (`f0fb631dd1a3a2988b23ba5057cd9106713cd0b4`). No Swift code or Swift runtime dependency is used by DuoBar.
- Both `arm64` and `arm64e` slices were compiled and linked successfully for the tweak and Settings bundle, without Swift or Cephei.
- Linux arm64e output uses the old ABI. The linker reported the corresponding warnings. The final universal dylib and Settings executable were each processed using [Allemande](https://github.com/p0358/allemande), following the conversion alternative linked in [Theos rootless documentation](https://theos.dev/docs/rootless), then re-signed with Procursus `ldid`.
- The RootHide staging tree was packaged using `dpkg-deb --root-owner-group -Zxz -z9`.

Source revisions: RootHide Theos `cfba89a53a05b4a1b822121158acc3669c20602f`, SDKs `0222fd5413cf4b9af096f37b4621afa2688572f7`, Allemande `43b2ca59ad3f6a55735b1f7b5cba8c34b55bd8f9`.

Allemande is a partial compatibility conversion, not a native macOS arm64e build. Its author does not guarantee compatibility for every tweak. DuoBar uses Objective-C and UIKit, without Swift or Cephei, but successful conversion and structural checks cannot establish on-device behavior.

## Checks passed

- Debian package architecture is `iphoneos-arm64e`, version `0.2.0`, identifier `local.duobar`, with RBx9 author/maintainer and the Twitter homepage.
- Payload contains `DuoBar.dylib` and its UIKit filter, `DuoBarPrefs.bundle` and its Info.plist, and the PreferenceLoader registration plist.
- All packaged directories are owned by root with mode `0755`; both executables are `0755` and plists are `0644`.
- Both universal binaries contain the expected ARM64 slices and target iOS 16.0.
- Mach-O command and section bounds are valid; load paths contain no workspace or build-machine paths.
- The tweak's RootHide install name and substrate dependency use `@loader_path/.jbroot` paths.
- Code-signature page hashes were recomputed and matched for both slices of both executables after conversion and re-signing.
- Converted arm64e Objective-C class and CFString pointer descriptors were checked.
- Injection plist parses correctly and targets UIKit.
- Package payload matches both verified converted binaries.
- Settings domain, key, notification name, default state, bundle name, executable, principal class and loader entry match. The disable path restores native layers, and re-enable remains available without reloading hooks.
- Preview SVG and GitHub workflow structure parse correctly. GitHub Actions itself has not been run.

The remaining checks are listed in [DEVICE-TESTING.md](DEVICE-TESTING.md).
