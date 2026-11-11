#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/../.."

# Select one available iPhone and iPad without depending on a particular
# runner image's device names. Keep a result bundle with UI screenshots.
destinations=()
while IFS= read -r device; do
  destinations+=(-destination "platform=iOS Simulator,id=$device")
done < <(xcrun simctl list devices available -j | python3 -c '
import json, sys
devices = json.load(sys.stdin)["devices"]
for family in ("iPhone", "iPad"):
    matches = [device for runtime, entries in sorted(devices.items(), reverse=True) if ".iOS-" in runtime
               for device in entries if device["name"].startswith(family)]
    if not matches:
        raise SystemExit("No available " + family + " Simulator")
    print(matches[0]["udid"])
')
if [[ ${#destinations[@]} -ne 4 ]]; then
  echo "Expected an available iPhone and iPad Simulator" >&2
  exit 1
fi

mkdir -p build
xcodebuild -quiet test \
  -project GestaltX.xcodeproj \
  -scheme GestaltXNavigationTests \
  -configuration Debug \
  "${destinations[@]}" \
  -disable-concurrent-destination-testing \
  -parallel-testing-enabled NO \
  -test-timeouts-enabled YES \
  -maximum-test-execution-time-allowance 120 \
  -resultBundlePath build/navigation-tests.xcresult \
  CODE_SIGNING_ALLOWED=YES \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="-" \
  DEVELOPMENT_TEAM=""
