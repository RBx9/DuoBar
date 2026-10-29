#!/bin/bash
# Build simulator-only test dylibs. Never packaged.
# - DuoBar.dylib: the real Sources/Tweak.xm, preprocessed with the Logos
#   internal generator so it needs no Substrate in the simulator.
# - DuoBar-anyos.dylib: the same source with the iOS 16 gate raised
#   (DUO_MAX_IOS_MAJOR=99), only to evaluate newer iOS versions in the simulator.
# - DuoProbe.dylib: tests/simulator/DuoProbe.m.
# Usage: tests/simulator/build.sh <output-dir>
set -euo pipefail
out="$1"
root="$(cd "$(dirname "$0")/../.." && pwd)"
mkdir -p "$out/include"
[ -d "$out/logos" ] || git clone --depth 1 https://github.com/theos/logos.git "$out/logos"
: > "$out/include/substrate.h"
perl "$out/logos/bin/logos.pl" -c generator=internal "$root/Sources/Tweak.xm" > "$out/Tweak.mm"
sdk="$(xcrun --sdk iphonesimulator --show-sdk-path)"
cc=(xcrun -sdk iphonesimulator clang -target "$(uname -m)-apple-ios16.0-simulator" -isysroot "$sdk"
    -dynamiclib -fobjc-arc -Wall -Wextra)
"${cc[@]}" -I"$root/Sources" -I"$root/Shared" -I"$out/include" "$out/Tweak.mm" "$root/Sources/DuoGlyphView.m" \
    -framework UIKit -framework QuartzCore -framework CoreGraphics -framework CoreFoundation -framework Foundation \
    -o "$out/DuoBar.dylib"
"${cc[@]}" -DDUO_MAX_IOS_MAJOR=99 -I"$root/Sources" -I"$root/Shared" -I"$out/include" "$out/Tweak.mm" \
    "$root/Sources/DuoGlyphView.m" -framework UIKit -framework QuartzCore -framework CoreGraphics \
    -framework CoreFoundation -framework Foundation -o "$out/DuoBar-anyos.dylib"
"${cc[@]}" "$root/tests/simulator/DuoProbe.m" -framework UIKit -framework QuartzCore -framework CoreGraphics -framework Foundation \
    -o "$out/DuoProbe.dylib"
ls -l "$out"/*.dylib
