#!/usr/bin/env python3
"""Verify a CI-built DuoBar package before it is shared with testers.

Checks the problems seen in earlier unsafe builds as well as the package
contract that RootHide and Rootless installs depend on:

- control metadata (identifier, version, architecture, dependencies);
- payload ownership, install prefix and file modes (0755 directories and
  Mach-O executables, 0644 resources);
- universal arm64 + arm64e binaries, with arm64e built for the new pointer
  authentication ABI, an iOS 16 deployment target and a code signature;
- substrate linkage for the selected scheme and no build-machine paths;
- no non-weak imports of private, underscore-prefixed UIKit classes;
- Settings, PreferenceLoader and injection-filter plists and RGBA icons;
- optionally, a Theos build log free of compiler and linker warnings.

Usage: verify-deb.py --scheme {roothide,rootless} --version 2.7.2~beta7
                     [--build-log build.log] package.deb

Only the Python standard library is used, so the same check runs on the
GitHub macOS runner and on any machine inspecting a downloaded package.
"""
import argparse
import io
import lzma
import gzip
import bz2
import plistlib
import re
import struct
import sys
import tarfile
from pathlib import PurePosixPath

PACKAGES = {
    "roothide": {"package": "local.duobar", "architecture": "iphoneos-arm64e", "prefix": ""},
    "rootless": {"package": "local.duobar.rootless", "architecture": "iphoneos-arm64",
                 "prefix": "var/jb/"},
}
TWEAK = "Library/MobileSubstrate/DynamicLibraries/DuoBar.dylib"
PREFS = "Library/PreferenceBundles/DuoBarPrefs.bundle/DuoBarPrefs"
REQUIRED = [
    TWEAK,
    "Library/MobileSubstrate/DynamicLibraries/DuoBar.plist",
    PREFS,
    "Library/PreferenceBundles/DuoBarPrefs.bundle/Info.plist",
    "Library/PreferenceBundles/DuoBarPrefs.bundle/DuoBarIcon.png",
    "Library/PreferenceBundles/DuoBarPrefs.bundle/DuoBar.png",
    "Library/PreferenceBundles/DuoBarPrefs.bundle/DuoBar@2x.png",
    "Library/PreferenceBundles/DuoBarPrefs.bundle/DuoBar@3x.png",
    "Library/PreferenceLoader/Preferences/DuoBar.plist",
    "Library/PreferenceLoader/Preferences/DuoBar.png",
    "Library/PreferenceLoader/Preferences/DuoBar@2x.png",
    "Library/PreferenceLoader/Preferences/DuoBar@3x.png",
]
DEPENDS = ["mobilesubstrate", "preferenceloader", "firmware (>= 16.0)", "firmware (<< 17.0)"]
# Theos always prints this obsolete-flag notice from Apple's linker.
ALLOWED_LOG_WARNINGS = ["ld: warning: -multiply_defined is obsolete"]

CPU_TYPE_ARM64 = 0x0100000C
CPU_SUBTYPE_ARM64_ALL = 0
CPU_SUBTYPE_ARM64E = 2
CPU_SUBTYPE_PTRAUTH_ABI = 0x80000000
LC_REQ_DYLD = 0x80000000
LC_SYMTAB = 0x2
LC_LOAD_DYLIB, LC_ID_DYLIB, LC_LOAD_WEAK_DYLIB = 0xC, 0xD, 0x18 | LC_REQ_DYLD
LC_REEXPORT_DYLIB, LC_LAZY_LOAD_DYLIB, LC_LOAD_UPWARD_DYLIB = 0x1F | LC_REQ_DYLD, 0x20, 0x23 | LC_REQ_DYLD
DYLIB_COMMANDS = {LC_LOAD_DYLIB, LC_ID_DYLIB, LC_LOAD_WEAK_DYLIB, LC_REEXPORT_DYLIB,
                  LC_LAZY_LOAD_DYLIB, LC_LOAD_UPWARD_DYLIB}
LC_RPATH = 0x1C | LC_REQ_DYLD
LC_CODE_SIGNATURE = 0x1D
LC_ENCRYPTION_INFO_64 = 0x2C
LC_BUILD_VERSION = 0x32
PLATFORM_IOS = 2
N_TYPE, N_UNDF, N_EXT, N_WEAK_REF = 0x0E, 0x0, 0x01, 0x0040


class Report:
    def __init__(self):
        self.failures = []

    def check(self, condition, message):
        if not condition:
            self.failures.append(message)
        return condition


def read_ar(data):
    if not data.startswith(b"!<arch>\n"):
        raise ValueError("not a Debian ar archive")
    members, offset = {}, 8
    while offset + 60 <= len(data):
        header = data[offset:offset + 60]
        name = header[:16].decode().strip().rstrip("/")
        size = int(header[48:58].decode().strip())
        members[name] = data[offset + 60:offset + 60 + size]
        offset += 60 + size + (size & 1)
    return members


def decompress(name, payload):
    if name.endswith(".tar"):
        return payload
    if name.endswith(".gz"):
        return gzip.decompress(payload)
    if name.endswith(".bz2"):
        return bz2.decompress(payload)
    if name.endswith((".xz", ".lzma")):
        return lzma.decompress(payload, format=lzma.FORMAT_AUTO)
    raise ValueError(f"unsupported compression for {name}")


def open_member(members, stem):
    names = [name for name in members if name.startswith(stem)]
    if len(names) != 1:
        raise ValueError(f"expected one {stem} member, found {names}")
    return tarfile.open(fileobj=io.BytesIO(decompress(names[0], members[names[0]])))


def tar_name(member):
    name = member.name[2:] if member.name.startswith("./") else member.name
    name = name.rstrip("/")
    return "" if name == "." else name


def parse_control(text):
    fields, key = {}, None
    for line in text.splitlines():
        if line[:1] in (" ", "\t") and key:
            fields[key] += "\n" + line.strip()
        elif ":" in line:
            key, value = line.split(":", 1)
            fields[key.strip()] = value.strip()
    return fields


def macho_slices(data):
    magic = struct.unpack(">I", data[:4])[0]
    if magic != 0xCAFEBABE:
        raise ValueError("not a universal (fat) Mach-O binary")
    count = struct.unpack(">I", data[4:8])[0]
    slices = []
    for index in range(count):
        cputype, subtype, offset, size, _ = struct.unpack(">IIIII", data[8 + index * 20:28 + index * 20])
        slices.append((cputype, subtype, data[offset:offset + size]))
    return slices


def macho_info(image):
    magic, cputype, subtype, filetype, ncmds, _, _, _ = struct.unpack("<IIIIIIII", image[:32])
    if magic != 0xFEEDFACF:
        raise ValueError("slice is not a 64-bit Mach-O image")
    info = {"filetype": filetype, "cputype": cputype, "subtype": subtype, "dylibs": [], "rpaths": [],
            "codesign": False, "encrypted": False, "platform": None, "minos": None, "imports": []}
    offset = 32
    for _ in range(ncmds):
        cmd, size = struct.unpack("<II", image[offset:offset + 8])
        body = image[offset:offset + size]
        if cmd in DYLIB_COMMANDS or cmd == LC_RPATH:
            name_offset = struct.unpack("<I", body[8:12])[0]
            path = body[name_offset:].split(b"\0", 1)[0].decode()
            if cmd == LC_RPATH:
                info["rpaths"].append(path)
            elif cmd != LC_ID_DYLIB:
                info["dylibs"].append((path, cmd == LC_LOAD_WEAK_DYLIB))
            else:
                info["install_name"] = path
        elif cmd == LC_CODE_SIGNATURE:
            info["codesign"] = True
        elif cmd == LC_ENCRYPTION_INFO_64:
            info["encrypted"] = struct.unpack("<I", body[16:20])[0] != 0
        elif cmd == LC_BUILD_VERSION:
            platform, minos = struct.unpack("<II", body[8:16])
            info["platform"], info["minos"] = platform, (minos >> 16, (minos >> 8) & 0xFF)
        elif cmd == LC_SYMTAB:
            symoff, nsyms, stroff, _ = struct.unpack("<IIII", body[8:24])
            for index in range(nsyms):
                strx, ntype, _, desc, _ = struct.unpack("<IBBHQ", image[symoff + index * 16:symoff + index * 16 + 16])
                if ntype & N_EXT and ntype & N_TYPE == N_UNDF:
                    name = image[stroff + strx:].split(b"\0", 1)[0].decode()
                    info["imports"].append((name, bool(desc & N_WEAK_REF)))
        offset += size
    return info


def check_binary(report, label, data, scheme):
    try:
        slices = macho_slices(data)
    except ValueError as error:
        report.check(False, f"{label}: {error}")
        return
    kinds = {}
    for cputype, subtype, image in slices:
        if cputype != CPU_TYPE_ARM64:
            report.check(False, f"{label}: unexpected CPU type 0x{cputype:x}")
            continue
        kind = {CPU_SUBTYPE_ARM64_ALL: "arm64", CPU_SUBTYPE_ARM64E: "arm64e"}.get(subtype & 0xFFFFFF)
        if not report.check(kind is not None, f"{label}: unexpected arm64 subtype 0x{subtype:08x}"):
            continue
        kinds[kind] = subtype
        try:
            info = macho_info(image)
        except ValueError as error:
            report.check(False, f"{label} ({kind}): {error}")
            continue
        report.check(info["subtype"] == subtype, f"{label} ({kind}): fat and Mach-O subtypes differ")
        report.check(info["filetype"] in (6, 8), f"{label} ({kind}): not a dylib or bundle image")
        report.check(info["codesign"], f"{label} ({kind}): missing code signature")
        report.check(not info["encrypted"], f"{label} ({kind}): encrypted image")
        report.check(info["platform"] == PLATFORM_IOS and info["minos"] and info["minos"][0] == 16,
                     f"{label} ({kind}): deployment target is {info['minos']} on platform {info['platform']}, "
                     "expected iOS 16.x")
        paths = [path for path, _ in info["dylibs"]] + info["rpaths"] + [info.get("install_name", "")]
        for path in paths:
            report.check(not re.match(r"^/(Users|home|private/var/folders|tmp)/", path),
                         f"{label} ({kind}): build-machine path {path}")
        if label == "DuoBar.dylib":
            substrate = [path for path, _ in info["dylibs"]
                         if "libsubstrate" in path or "CydiaSubstrate" in path]
            if scheme == "rootless":
                report.check(substrate == ["@rpath/CydiaSubstrate.framework/CydiaSubstrate"],
                             f"{label} ({kind}): Rootless substrate linkage is {substrate}")
                report.check(any(path.startswith("/var/jb/") for path in info["rpaths"]),
                             f"{label} ({kind}): no /var/jb runpath for Rootless substrate")
            else:
                report.check(substrate == ["@loader_path/.jbroot/usr/lib/libsubstrate.dylib"],
                             f"{label} ({kind}): RootHide substrate linkage is {substrate}")
        for path in paths:
            if scheme == "rootless":
                report.check(not path.startswith(("/Library/", "/usr/lib/libsubstrate")),
                             f"{label} ({kind}): rootful load path {path} in a Rootless package")
        for name, weak in info["imports"]:
            # Private classes such as _UIStatusBarStringView must be looked up
            # with NSClassFromString; a strong class import can stop loading.
            report.check(weak or not name.startswith("_OBJC_CLASS_$__"),
                         f"{label} ({kind}): non-weak import of private class {name[len('_OBJC_CLASS_$_'):]}")
    report.check(sorted(kinds) == ["arm64", "arm64e"],
                 f"{label}: slices are {sorted(kinds)}, expected arm64 and arm64e")
    if "arm64e" in kinds:
        report.check(bool(kinds["arm64e"] & CPU_SUBTYPE_PTRAUTH_ABI),
                     f"{label}: arm64e slice uses the old ABI (subtype 0x{kinds['arm64e']:08x}); "
                     "iOS 14+ needs the new pointer-authentication ABI")


def check_build_log(report, path):
    text = re.sub(r"\x1b\[[0-9;]*m", "", open(path, encoding="utf-8", errors="replace").read())
    for line in text.splitlines():
        if re.search(r"\bwarning\b", line, re.IGNORECASE) and line.strip() not in ALLOWED_LOG_WARNINGS:
            report.check(False, f"build log {path}: {line.strip()}")


def verify(deb_path, scheme, version, build_logs=()):
    report = Report()
    expected = PACKAGES[scheme]
    members = read_ar(open(deb_path, "rb").read())
    report.check(members.get("debian-binary") == b"2.0\n", "debian-binary is not 2.0")

    control_tar = open_member(members, "control.tar")
    control_members = {tar_name(member): member for member in control_tar.getmembers()}
    if not report.check("control" in control_members, "control archive has no control file"):
        return report
    control = parse_control(control_tar.extractfile(control_members["control"]).read().decode())
    report.check(control.get("Package") == expected["package"],
                 f"Package is {control.get('Package')}, expected {expected['package']}")
    report.check(control.get("Version") == version, f"Version is {control.get('Version')}, expected {version}")
    report.check(control.get("Architecture") == expected["architecture"],
                 f"Architecture is {control.get('Architecture')}, expected {expected['architecture']}")
    depends = [item.strip() for item in control.get("Depends", "").split(",")]
    report.check(depends == DEPENDS, f"Depends is {depends}, expected {DEPENDS}")
    if scheme == "rootless":
        report.check("local.duobar" in [item.strip() for item in control.get("Conflicts", "").split(",")],
                     "Rootless package does not conflict with local.duobar")
    for name in ("preinst", "postinst", "prerm", "postrm"):
        report.check(name not in control_members, f"unexpected maintainer script {name}")

    data_tar = open_member(members, "data.tar")
    prefix = expected["prefix"]
    # Directories that may hold the install prefix itself, e.g. var and var/jb.
    prefix_parents = {"/".join(prefix.split("/")[:depth]) for depth in range(prefix.count("/") + 1)}
    files = {}
    for member in data_tar.getmembers():
        name = tar_name(member)
        mode = member.mode & 0o7777
        # dpkg resolves owners by tar user/group name before numeric IDs;
        # Theos writes root/wheel names with the build user's numeric IDs.
        owner = (member.uname, member.gname) if member.uname else (member.uid, member.gid)
        report.check(owner in (("root", "wheel"), (0, 0)),
                     f"{name or '.'}: owned by {owner}, expected root:wheel")
        if member.isdir():
            report.check(mode == 0o755, f"{name or '.'}/: directory mode {mode:04o}, expected 0755")
            report.check(name in prefix_parents or name.startswith(prefix),
                         f"{name}/: outside the '{prefix}' install prefix")
            if scheme == "roothide":
                report.check(name != "var" and not name.startswith("var/"),
                             f"{name}/: Rootless path in a RootHide package")
            continue
        if not report.check(member.isfile(), f"{name}: unsupported tar entry type {member.type!r}"):
            continue
        report.check(name.startswith(prefix), f"{name}: outside the '{prefix}' install prefix")
        if scheme == "roothide":
            report.check(not name.startswith("var/jb/"), f"{name}: Rootless path in a RootHide package")
        relative = name[len(prefix):] if name.startswith(prefix) else name
        content = data_tar.extractfile(member).read()
        files[relative] = content
        is_macho = content[:4] in (b"\xca\xfe\xba\xbe", b"\xcf\xfa\xed\xfe")
        wanted = 0o755 if is_macho else 0o644
        report.check(mode == wanted, f"{name}: mode {mode:04o}, expected {wanted:04o}")

    for path in REQUIRED:
        report.check(path in files, f"missing {prefix}{path}")
    for path, label in ((TWEAK, "DuoBar.dylib"), (PREFS, "DuoBarPrefs")):
        if path in files:
            check_binary(report, label, files[path], scheme)

    def plist(path):
        try:
            return plistlib.loads(files[path]) if path in files else {}
        except Exception as error:  # plistlib raises several parser types
            report.check(False, f"{path}: invalid plist ({error})")
            return {}

    base_version = version.split("~", 1)[0]
    info = plist("Library/PreferenceBundles/DuoBarPrefs.bundle/Info.plist")
    report.check(info.get("CFBundleExecutable") == "DuoBarPrefs", "Settings bundle executable is not DuoBarPrefs")
    report.check(info.get("NSPrincipalClass") == "DuoRootListController",
                 "Settings principal class is not DuoRootListController")
    report.check(info.get("CFBundleShortVersionString") == base_version,
                 f"Settings bundle version is {info.get('CFBundleShortVersionString')}, expected {base_version}")
    entry = plist("Library/PreferenceLoader/Preferences/DuoBar.plist").get("entry", {})
    report.check(entry.get("bundle") == "DuoBarPrefs" and entry.get("icon") == "DuoBar.png",
                 "PreferenceLoader entry does not load DuoBarPrefs with DuoBar.png")
    bundles = plist("Library/MobileSubstrate/DynamicLibraries/DuoBar.plist").get("Filter", {}).get("Bundles")
    report.check(bundles == ["com.apple.UIKit"], f"injection filter is {bundles}, expected ['com.apple.UIKit']")
    for path, content in files.items():
        if path.endswith(".png"):
            report.check(content[:8] == bytes.fromhex("89504e470d0a1a0a") and content[24:26] == b"\x08\x06",
                         f"{path}: not an 8-bit RGBA PNG")

    for log in build_logs:
        check_build_log(report, log)
    return report


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--scheme", choices=sorted(PACKAGES), required=True)
    parser.add_argument("--version", required=True, help="Debian version, for example 2.7.2~beta7")
    parser.add_argument("--build-log", action="append", default=[], help="Theos build log to scan for warnings")
    parser.add_argument("deb")
    args = parser.parse_args()
    report = verify(args.deb, args.scheme, args.version, args.build_log)
    name = PurePosixPath(args.deb).name
    if report.failures:
        print(f"FAIL {name} ({args.scheme}):")
        for failure in report.failures:
            print(f"  - {failure}")
        return 1
    print(f"OK   {name} ({args.scheme} {args.version}): metadata, modes, arm64/arm64e (new ABI), "
          "signatures, linkage, private-class imports, plists and icons verified")
    return 0


if __name__ == "__main__":
    sys.exit(main())
