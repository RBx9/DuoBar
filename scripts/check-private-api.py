#!/usr/bin/env python3
"""Check that DuoBar degrades safely when private iOS APIs change.

Fails when:
- a private class is referenced at compile time (`_UIFoo.class`, `[_UIFoo class]`),
  which becomes a non-weak import and can stop the tweak from loading;
- a %hook'd class is not resolved with NSClassFromString;
- a hooked private selector is not checked in %ctor before its group is
  installed (public UIView/UIImageView selectors are exempt);
- a private class or checked selector is missing from the simulator probe
  manifest, so CI would not report it per iOS runtime.

Usage: check-private-api.py [Sources/Tweak.xm] [tests/simulator/DuoProbe.m]
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TWEAK = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "Sources/Tweak.xm"
PROBE = Path(sys.argv[2]) if len(sys.argv) > 2 else ROOT / "tests/simulator/DuoProbe.m"
# Public UIKit/NSObject API: present on every supported iOS version.
PUBLIC = {"layoutSubviews", "didMoveToWindow", "setHidden:", "setAlpha:", "setImage:",
          "setAccessibilityLabel:"}


def selector(declaration):
    """`- (void)setText:(NSString *)text {` -> `setText:`."""
    body = re.sub(r"^\s*-\s*\([^)]*\)\s*", "", declaration).split("{")[0].strip()
    parts = re.findall(r"(\w+)\s*:\s*\([^)]*\)\s*\w+", body)
    return "".join(f"{part}:" for part in parts) if parts else body.split()[0]


def main():
    source = TWEAK.read_text()
    failures = []

    code = re.sub(r"/\*.*?\*/|//[^\n]*", "", source, flags=re.S)
    for match in re.finditer(r"\b(_UI\w+|CCUI\w+|SB\w+)\.class\b|\[\s*(_UI\w+|CCUI\w+|SB\w+)\s+class\s*\]", code):
        failures.append(f"compile-time reference to private class {match.group(1) or match.group(2)}; "
                        "use NSClassFromString")

    hooks = {}  # group -> (class, [selectors])
    for group, body in re.findall(r"%group\s+(\w+)(.*?)%end\s*%end", source, re.S):
        hooked = re.search(r"%hook\s+(\w+)", body).group(1)
        selectors = [selector(line) for line in re.findall(r"^-\s*\(.*$", body, re.M)]
        hooks[group] = (hooked, selectors)
    if not hooks:
        failures.append("no %group/%hook blocks found")

    ctor = source[source.index("%ctor"):]
    checked = set(re.findall(r'@"([A-Za-z_][\w:]*)"', ctor))
    resolved = set(re.findall(r'NSClassFromString\(@"(\w+)"\)', source))
    for group, (hooked, selectors) in sorted(hooks.items()):
        if hooked not in resolved:
            failures.append(f"%hook {hooked} ({group}) is not resolved with NSClassFromString")
        if f"%init({group})" not in ctor:
            failures.append(f"{group} is never installed with %init")
        for name in selectors:
            if name not in PUBLIC and name not in checked:
                failures.append(f"{hooked} -{name} ({group}) is hooked without a selector check in %ctor")

    probe = PROBE.read_text()
    manifest = {}
    for cls, sels in re.findall(r'@\[@"(\w+)",\s*@\[(.*?)\]\]', probe, re.S):
        manifest[cls] = {name.lstrip("+") for name in re.findall(r'@"([+\w:]+)"', sels)}
    private_classes = {cls for cls in resolved if cls.startswith(("_UI", "CCUI", "SB"))}
    for cls in sorted(private_classes - manifest.keys()):
        failures.append(f"private class {cls} is missing from the simulator probe manifest")
    for group, (hooked, selectors) in sorted(hooks.items()):
        for name in selectors:
            if name not in PUBLIC and name not in manifest.get(hooked, set()) and \
                    not any(name in sels for sels in manifest.values()):
                failures.append(f"{hooked} -{name} is missing from the simulator probe manifest")

    if failures:
        print("Private API safety check failed:")
        for failure in failures:
            print(f"  - {failure}")
        return 1
    total = sum(len(selectors) for _, selectors in hooks.values())
    print(f"Private API safety check passed: {len(hooks)} hook groups, {total} hooked selectors, "
          f"{len(private_classes)} private classes resolved at runtime and covered by the probe")
    return 0


if __name__ == "__main__":
    sys.exit(main())
