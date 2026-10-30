#!/bin/bash
# Probe DuoBar's private status-bar APIs on every available iOS simulator
# runtime, render DuoBar in Settings and on the Home Screen at 70%, 100% and
# 140%, and trace it in SpringBoard while Control Center opens and closes.
# iOS 16 uses the real DuoBar build. Newer runtimes use DuoBar-anyos.dylib, a
# simulator-only build with the iOS 16 gate raised, to evaluate them.
# Results go to the job log: DUOPROBE lines, Control Center trace summaries, a
# DUOSUMMARY block, and base64 contact sheets.
# Usage: tests/simulator/run.sh <build-dir> <python-with-pillow>
set -uo pipefail
dir="$1"
python="$2"
here="$(cd "$(dirname "$0")" && pwd)"
shots="$dir/shots"
mkdir -p "$shots"

python3 -I "$here/plan.py" > "$dir/plan.tsv"
echo "== Test plan"; cat "$dir/plan.tsv"

wait_for() { # file pattern seconds
    local i
    for ((i = 0; i < $3; i++)); do grep -q "$2" "$1" 2>/dev/null && return 0; sleep 1; done
    return 1
}

override() { # udid network battery
    xcrun simctl status_bar "$1" override --time 9:41 --operatorName DuoBar \
        --cellularMode active --cellularBars 3 --wifiMode active --wifiBars 2 \
        --batteryState "$3" --batteryLevel 76 --dataNetwork "$2"
}

while IFS=$'\t' read -r runtime version device <&3; do
    major="${version%%.*}"
    slug="$(echo "ios$version-$device" | tr -c 'A-Za-z0-9.\n' '-')"
    if [ "$major" = 16 ]; then
        build="$dir/DuoBar.dylib"; kind="release gate"
        app_states=("1.0 5g discharging" "0.7 5g discharging" "1.4 5g discharging" "1.0 wifi charging" "1.4 lte discharging")
        sizes=(0.7 1.0 1.4)
    else
        build="$dir/DuoBar-anyos.dylib"; kind="TEST BUILD, iOS gate raised"
        app_states=("1.0 5g discharging" "1.4 lte discharging")
        sizes=(1.0 1.4)
    fi
    inject="$build:$dir/DuoProbe.dylib"
    echo "== iOS $version on $device ($kind)"
    udid="$(xcrun simctl create "duobar-$slug" "$device" "$runtime")" || {
        echo "::warning::Could not create $device on iOS $version"; continue; }
    if ! xcrun simctl boot "$udid" || ! xcrun simctl bootstatus "$udid" -b >/dev/null; then
        echo "::warning::Could not boot $device on iOS $version"; xcrun simctl delete "$udid"; continue
    fi

    # Settings app status bar.
    first=1
    for state in "${app_states[@]}"; do
        read -r size network battery <<< "$state"
        label="iOS $version $device app ${size}x $network $battery"
        out="$shots/$slug-app-$size-$network-$battery.txt"
        override "$udid" "$network" "$battery"
        xcrun simctl spawn "$udid" defaults write local.duobar SizeScale -float "$size"
        SIMCTL_CHILD_DYLD_INSERT_LIBRARIES="$inject" SIMCTL_CHILD_DUO_PROBE_LABEL="$label" \
            xcrun simctl launch --terminate-running-process --stdout="$out" --stderr="$out.err" \
            "$udid" com.apple.Preferences >/dev/null
        sleep 7
        xcrun simctl io "$udid" screenshot "${out%.txt}.png" >/dev/null 2>&1
        if [ "$first" = 1 ]; then
            grep DUOPROBE "$out" || echo "::warning::No probe output for $label"; first=0
        else
            grep -E "DUOPROBE .*(DuoGlyphView|_UIBatteryView)" "$out" || true
        fi
        printf '%s\t%s\t%s\n' "iOS $version $device app ${size}x $network" "${out%.txt}.png" "$out" >> "$dir/sheet-$major.tsv"
    done
    xcrun simctl terminate "$udid" com.apple.Preferences >/dev/null 2>&1

    # SpringBoard: Home Screen status bar, then open and close Control Center
    # while the probe traces DuoBar's on-screen frame.
    override "$udid" 5g discharging
    for size in "${sizes[@]}"; do
        sbout="$shots/$slug-springboard-$size.txt"
        : > "$sbout"
        xcrun simctl spawn "$udid" defaults write local.duobar SizeScale -float "$size"
        for kv in "DYLD_INSERT_LIBRARIES=$inject" "DUO_PROBE_OUT=$sbout" "DUO_PROBE_CC=1" \
                  "DUO_PROBE_LABEL=iOS $version $device SpringBoard ${size}x"; do
            xcrun simctl spawn "$udid" launchctl setenv "${kv%%=*}" "${kv#*=}"
        done
        xcrun simctl spawn "$udid" launchctl stop com.apple.backboardd || true
        if wait_for "$sbout" "cc present called" 120; then
            sleep 1.5
            xcrun simctl io "$udid" screenshot "$shots/$slug-cc-open-$size.png" >/dev/null 2>&1
            wait_for "$sbout" "cc trace done" 30
            sleep 1
            xcrun simctl io "$udid" screenshot "$shots/$slug-home-$size.png" >/dev/null 2>&1
            printf '%s\t%s\t%s\n' "iOS $version $device Home ${size}x" "$shots/$slug-home-$size.png" \
                "$sbout" >> "$dir/sheet-$major.tsv"
            echo "== Control Center trace: iOS $version $device ${size}x"
            python3 -I "$here/trace.py" "$sbout" | tee "$sbout.summary"
            # Which classes draw SpringBoard's status bar on this iOS version.
            if [ "$size" = 1.0 ] && ! grep -qx "$version" "$dir/regions-printed" 2>/dev/null; then
                echo "== Status-bar views in SpringBoard: iOS $version $device"
                grep -E "DUOPROBE .* region " "$sbout" | sed 's/^DUOPROBE \[[^]]*\] //' | head -160
                { echo "== Status-bar inventory in SpringBoard: iOS $version $device"
                  grep -E "DUOPROBE .* (inventory|scene|window-list|anyview) " "$sbout" |
                      sed 's/^DUOPROBE \[[^]]*\] //' | head -200; } | tee -a "$dir/inventory.txt"
                echo "$version" >> "$dir/regions-printed"
            fi
        else
            echo "::warning::SpringBoard probe did not report on $device (iOS $version, ${size}x)"
            head -c 3000 "$sbout"
        fi
    done
    xcrun simctl spawn "$udid" launchctl unsetenv DYLD_INSERT_LIBRARIES || true
    xcrun simctl shutdown "$udid" >/dev/null 2>&1
    xcrun simctl delete "$udid" >/dev/null 2>&1
done 3< "$dir/plan.tsv"

# Repeated at the end so it survives tools that only fetch a log's tail.
echo "DUOINVENTORY-BEGIN"
cat "$dir/inventory.txt" 2>/dev/null
echo "DUOINVENTORY-END"

echo "DUOSUMMARY-BEGIN"
python3 -I "$here/summary.py" "$shots"
echo "DUOSUMMARY-END"

for manifest in "$dir"/sheet-*.tsv; do
    [ -e "$manifest" ] || continue
    name="$(basename "$manifest" .tsv)"
    if "$python" "$here/sheet.py" "$manifest" "$dir/$name.png"; then
        echo "DUOSHEET-BEGIN $name $(wc -c < "$dir/$name.png") bytes"
        base64 -i "$dir/$name.png" | fold -w 160
        echo "DUOSHEET-END $name"
    fi
done
