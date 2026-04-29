#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
OUTPUT_PATH="${ROOT_DIR}/NCMKit.xcframework"

"${SCRIPT_DIR}/build-ios.sh" iphoneos
"${SCRIPT_DIR}/build-ios.sh" iphonesimulator

rm -rf "${OUTPUT_PATH}"

xcodebuild -create-xcframework \
  -library "${ROOT_DIR}/build/ios-arm64/libNCMKit.a" \
  -headers "${ROOT_DIR}/build/ios-arm64/Headers" \
  -library "${ROOT_DIR}/build/ios-arm64-simulator/libNCMKit.a" \
  -headers "${ROOT_DIR}/build/ios-arm64-simulator/Headers" \
  -output "${OUTPUT_PATH}"

echo "Created ${OUTPUT_PATH}"
