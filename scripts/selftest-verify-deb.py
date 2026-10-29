#!/usr/bin/env python3
"""Prove that verify-deb.py rejects the failure modes seen in unsafe builds.

Starting from a package that passes verification, write deliberately broken
copies and require each one to fail with the expected message:

- restrictive Settings bundle modes (the local beta5/beta6 Settings failure);
- an old-ABI arm64e slice and a missing arm64e slice;
- a missing code signature;
- wrong package architecture metadata;
- a Theos build log with an arm64e toolchain warning.

Usage: selftest-verify-deb.py --scheme {roothide,rootless} --version V package.deb
"""
import argparse
import gzip
import importlib.util
import io
import struct
import sys
import tarfile
import tempfile
from pathlib import Path

sys.dont_write_bytecode = True  # keep the checkout free of __pycache__
spec = importlib.util.spec_from_file_location("verify_deb", Path(__file__).with_name("verify-deb.py"))
verify_deb = importlib.util.module_from_spec(spec)
spec.loader.exec_module(verify_deb)


def write_ar(members):
    out = bytearray(b"!<arch>\n")
    for name, payload in members:
        out += f"{name:<16}{0:<12}{0:<6}{0:<6}{'100644':<8}{len(payload):<10}`\n".encode()
        out += payload + (b"\n" if len(payload) & 1 else b"")
    return bytes(out)


def retar(tar, edit):
    """Copy a tar archive, letting edit(TarInfo, bytes) return replacements."""
    buffer = io.BytesIO()
    with tarfile.open(fileobj=buffer, mode="w", format=tarfile.GNU_FORMAT) as output:
        for member in tar.getmembers():
            content = tar.extractfile(member).read() if member.isfile() else None
            member, content = edit(member, content)
            if content is not None:
                member.size = len(content)
                output.addfile(member, io.BytesIO(content))
            else:
                output.addfile(member)
    return gzip.compress(buffer.getvalue())


def rebuild(deb, edit_data=None, edit_control=None):
    members = verify_deb.read_ar(deb)
    keep = lambda member, content: (member, content)
    control = retar(verify_deb.open_member(members, "control.tar"), edit_control or keep)
    data = retar(verify_deb.open_member(members, "data.tar"), edit_data or keep)
    return write_ar([("debian-binary", b"2.0\n"), ("control.tar.gz", control), ("data.tar.gz", data)])


def patch_slices(content, patch):
    """Apply patch(index, subtype) -> subtype to fat and thin Mach-O headers."""
    content = bytearray(content)
    for index in range(struct.unpack(">I", content[4:8])[0]):
        entry = 8 + index * 20
        subtype, offset = struct.unpack(">I", content[entry + 4:entry + 8])[0], \
            struct.unpack(">I", content[entry + 8:entry + 12])[0]
        new = patch(index, subtype)
        content[entry + 4:entry + 8] = struct.pack(">I", new)
        content[offset + 8:offset + 12] = struct.pack("<I", new)
    return bytes(content)


def drop_signature(content):
    """Rename every LC_CODE_SIGNATURE command to an unrelated load command."""
    content = bytearray(content)
    for index in range(struct.unpack(">I", content[4:8])[0]):
        offset = struct.unpack(">I", content[8 + index * 20 + 8:8 + index * 20 + 12])[0]
        ncmds = struct.unpack("<I", content[offset + 16:offset + 20])[0]
        cursor = offset + 32
        for _ in range(ncmds):
            cmd, size = struct.unpack("<II", content[cursor:cursor + 8])
            if cmd == verify_deb.LC_CODE_SIGNATURE:
                content[cursor:cursor + 4] = struct.pack("<I", 0x26)  # LC_FUNCTION_STARTS
            cursor += size
    return bytes(content)


def edit_file(suffix, change):
    def edit(member, content):
        if member.name.rstrip("/").endswith(suffix):
            return change(member, content)
        return member, content
    return edit


def chmod(mode):
    def change(member, content):
        member.mode = mode
        return member, content
    return change


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--scheme", choices=sorted(verify_deb.PACKAGES), required=True)
    parser.add_argument("--version", required=True)
    parser.add_argument("deb")
    args = parser.parse_args()
    original = Path(args.deb).read_bytes()

    baseline = verify_deb.verify(args.deb, args.scheme, args.version)
    if baseline.failures:
        print("selftest needs a package that passes verify-deb.py:", *baseline.failures, sep="\n  - ")
        return 1

    def restrictive(member, content):
        if member.name.rstrip("/").endswith("DuoBarPrefs.bundle"):
            member.mode = 0o700
        elif member.name.endswith("DuoBarPrefs.bundle/DuoBarPrefs"):
            member.mode = 0o600
        return member, content

    old_abi = lambda index, subtype: subtype & ~verify_deb.CPU_SUBTYPE_PTRAUTH_ABI
    arm64_only = lambda index, subtype: verify_deb.CPU_SUBTYPE_ARM64_ALL
    cases = [
        ("restrictive Settings modes", rebuild(original, restrictive), [],
         "DuoBarPrefs.bundle/: directory mode 0700"),
        ("old-ABI arm64e tweak", rebuild(original, edit_file(
            "DuoBar.dylib", lambda m, c: (m, patch_slices(c, old_abi)))), [], "uses the old ABI"),
        ("missing arm64e Settings slice", rebuild(original, edit_file(
            "DuoBarPrefs.bundle/DuoBarPrefs", lambda m, c: (m, patch_slices(c, arm64_only)))), [],
         "expected arm64 and arm64e"),
        ("unsigned tweak", rebuild(original, edit_file(
            "DuoBar.dylib", lambda m, c: (m, drop_signature(c)))), [], "missing code signature"),
        ("wrong architecture metadata", rebuild(original, edit_control=edit_file(
            "control", lambda m, c: (m, c.replace(b"Architecture: iphoneos-", b"Architecture: darwin-")))), [],
         "Architecture is darwin-"),
        ("tweak readable only by its owner", rebuild(original, edit_file("DuoBar.dylib", chmod(0o700))), [],
         "DuoBar.dylib: mode 0700"),
        ("arm64e toolchain warning in build log", original,
         ["==> Warning: Building for iOS 16.0, but the current toolchain can't produce arm64e "
          "binaries for iOS 14.0 or later."], "build log"),
    ]
    failed = 0
    with tempfile.TemporaryDirectory() as directory:
        # Repacking alone must not introduce failures, or the cases prove nothing.
        control_case = Path(directory) / "unchanged.deb"
        control_case.write_bytes(rebuild(original))
        repacked = verify_deb.verify(str(control_case), args.scheme, args.version).failures
        if repacked:
            print("FAIL an unmodified repack does not verify:", *repacked, sep="\n  - ")
            return 1
        print("ok   unmodified repack still verifies")
        for name, package, log_lines, expected in cases:
            deb = Path(directory) / "case.deb"
            deb.write_bytes(package)
            logs = []
            if log_lines:
                log = Path(directory) / "build.log"
                log.write_text("\n".join(log_lines) + "\n")
                logs = [str(log)]
            failures = verify_deb.verify(str(deb), args.scheme, args.version, logs).failures
            if any(expected in failure for failure in failures):
                print(f"ok   rejected {name}")
            else:
                failed += 1
                print(f"FAIL {name} was not rejected with '{expected}': {failures}")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
