#!/bin/bash
# Probe DuoBar's private status-bar APIs on every available iOS simulator
# runtime and render DuoBar where it loads (iOS 16). Results go to the job log:
# DUOPROBE lines, a Control Center trace summary, and base64 contact sheets.
# Usage: tests/simulator/run.sh <build-dir> <python-with-pillow>
set -uo pipefail
dir="$1"
python="$2"
here="$(cd "$(dirname "$0")" && pwd)"
inject="$dir/DuoBar.dylib:$dir/DuoProbe.dylib"
shots="$dir/shots"
mkdir -p "$shots"

python3 -I "$here/plan.py" > "$dir/plan.tsv"
echo "== Test plan"; cat "$dir/plan.tsv"

launch_settings() { # udid label size network battery output
    local udid="$1" label="$2" size="$3" network="$4" battery="$5" out="$6"
    xcrun simctl status_bar "$udid" override --time 9:41 --operatorName DuoBar \
        --cellularMode active --cellularBars 3 --wifiMode active --wifiBars 2 \
        --batteryState "$battery" --batteryLevel 76 --dataNetwork "$network"
    xcrun simctl spawn "$udid" defaults write local.duobar SizeScale -float "$size"
    SIMCTL_CHILD_DYLD_INSERT_LIBRARIES="$inject" SIMCTL_CHILD_DUO_PROBE_LABEL="$label" \
        xcrun simctl launch --terminate-running-process --stdout="$out" --stderr="$out.err" \
        "$udid" com.apple.Preferences >/dev/null
    sleep 7
}

wait_for() { # file pattern seconds
    local i
    for ((i = 0; i < $3; i++)); do grep -q "$2" "$1" 2>/dev/null && return 0; sleep 1; done
    return 1
}

while IFS=$'\t' read -r runtime version device <&3; do
    major="${version%%.*}"
    slug="$(echo "ios$version-$device" | tr -c 'A-Za-z0-9.\n' '-')"
    echo "== iOS $version on $device"
    udid="$(xcrun simctl create "duobar-$slug" "$device" "$runtime")" || {
        echo "::warning::Could not create $device on iOS $version"; continue; }
    if ! xcrun simctl boot "$udid" || ! xcrun simctl bootstatus "$udid" -b >/dev/null; then
        echo "::warning::Could not boot $device on iOS $version"; xcrun simctl delete "$udid"; continue
    fi

    # The size, data network and battery states DuoBar is rendered in. DuoBar
    # only loads on iOS 16, so other runtimes get the API probe and one stock shot.
    states=("1.0 5g discharging")
    [ "$major" = 16 ] && states+=("0.7 5g discharging" "1.4 5g discharging" "1.0 wifi charging" "1.4 lte discharging")
    first=1
    for state in "${states[@]}"; do
        read -r size network battery <<< "$state"
        label="iOS $version $device ${size}x $network $battery"
        out="$shots/$slug-$size-$network-$battery.txt"
        launch_settings "$udid" "$label" "$size" "$network" "$battery" "$out"
        xcrun simctl io "$udid" screenshot "${out%.txt}.png" >/dev/null 2>&1
        if [ "$first" = 1 ]; then
            grep DUOPROBE "$out" || echo "::warning::No probe output for $label"; first=0
        else
            grep -E "DUOPROBE .*(DuoGlyphView|_UIBatteryView)" "$out" || true
        fi
        printf '%s\t%s\t%s\n' "iOS $version $device ${size}x $network" "${out%.txt}.png" "$out" >> "$dir/sheet-$major.tsv"
    done

    # Inside SpringBoard: render the Home Screen status bar, then open and close
    # Control Center while the probe traces DuoBar's on-screen frame.
    if [ "$major" = 16 ] && [[ "$device" == "iPhone 14 Pro" || "$device" == "iPhone 14" ]]; then
        for size in 1.0 1.4; do
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
                printf '%s\t%s\t%s\n' "iOS $version $device CC open ${size}x" \
                    "$shots/$slug-cc-open-$size.png" "$sbout" >> "$dir/sheet-$major.tsv"
                wait_for "$sbout" "cc trace done" 30
                sleep 1
                xcrun simctl io "$udid" screenshot "$shots/$slug-home-$size.png" >/dev/null 2>&1
                printf '%s\t%s\t%s\n' "iOS $version $device Home ${size}x" \
                    "$shots/$slug-home-$size.png" "$sbout" >> "$dir/sheet-$major.tsv"
                echo "== Control Center trace: iOS $version $device ${size}x"
                python3 -I "$here/trace.py" "$sbout"
            else
                echo "::warning::SpringBoard probe did not report on $device (iOS $version, ${size}x)"
                head -c 2000 "$sbout"
            fi
        done
        xcrun simctl spawn "$udid" launchctl unsetenv DYLD_INSERT_LIBRARIES || true
    fi
    xcrun simctl shutdown "$udid" >/dev/null 2>&1
    xcrun simctl delete "$udid" >/dev/null 2>&1
done 3< "$dir/plan.tsv"

for manifest in "$dir"/sheet-*.tsv; do
    [ -e "$manifest" ] || continue
    name="$(basename "$manifest" .tsv)"
    if "$python" "$here/sheet.py" "$manifest" "$dir/$name.png"; then
        echo "DUOSHEET-BEGIN $name $(wc -c < "$dir/$name.png") bytes"
        base64 -i "$dir/$name.png" | fold -w 160
        echo "DUOSHEET-END $name"
    fi
done
