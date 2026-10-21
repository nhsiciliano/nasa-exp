"""Print the UDID of the iPhone simulator CI should test on.

Prefers "iPhone 17" on the newest iOS runtime; otherwise the highest-numbered
iPhone on the newest runtime. Reads `xcrun simctl list devices available --json`
from stdin.
"""

import json
import re
import sys


def runtime_version(identifier):
    match = re.search(r"iOS-(\d+)-(\d+)", identifier)
    return (int(match[1]), int(match[2])) if match else (0, 0)


candidates = []
for runtime, devices in json.load(sys.stdin)["devices"].items():
    if "SimRuntime.iOS" not in runtime:
        continue
    for device in devices:
        model = re.match(r"iPhone (\d+)", device["name"])
        if device.get("isAvailable", True) and model:
            candidates.append((
                device["name"] == "iPhone 17",
                runtime_version(runtime),
                int(model[1]),
                -len(device["name"]),
                device["udid"],
                device["name"],
            ))

if not candidates:
    sys.exit("No iPhone simulator available")

best = max(candidates)
print(f"Using {best[5]} (iOS {best[1][0]}.{best[1][1]})", file=sys.stderr)
print(best[4])
