#!/usr/bin/env python3
"""Print the simulator test plan: one line per (runtime, device) to test.

Only the newest runtime of each iOS major version is used. Devices are picked
from the iPhone 12-18 range (plus one 20 pt Home-button iPhone on iOS 16) and
must be supported by the runtime.
Output: runtime-identifier<TAB>version<TAB>device-name
"""
import json
import subprocess

DEVICES = {
    16: ["iPhone 14 Pro", "iPhone 14", "iPhone 13 mini", "iPhone 14 Pro Max", "iPhone 12",
         "iPhone SE (3rd generation)"],
    17: ["iPhone 15 Pro", "iPhone 15", "iPhone 14 Pro"],
    18: ["iPhone 16 Pro", "iPhone 16e"],
    26: ["iPhone 17 Pro", "iPhone Air", "iPhone 17"],
}

runtimes = json.loads(subprocess.check_output(["xcrun", "simctl", "list", "-j", "runtimes"]))["runtimes"]
newest = {}
for runtime in runtimes:
    if runtime.get("platform", "iOS") != "iOS" or not runtime.get("isAvailable"):
        continue
    major = int(runtime["version"].split(".")[0])
    key = tuple(int(part) for part in runtime["version"].split("."))
    if major not in newest or key > newest[major][0]:
        newest[major] = (key, runtime)

for major in sorted(newest):
    runtime = newest[major][1]
    supported = {device["name"] for device in runtime.get("supportedDeviceTypes", [])}
    wanted = DEVICES.get(major) or DEVICES[max(DEVICES)]
    for name in wanted:
        if name in supported:
            print(runtime["identifier"], runtime["version"], name, sep="\t")
