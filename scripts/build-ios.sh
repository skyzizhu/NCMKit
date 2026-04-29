#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
CMAKE_BIN="${CMAKE_BIN:-}"

if [[ -z "${CMAKE_BIN}" ]]; then
  if command -v cmake >/dev/null 2>&1; then
    CMAKE_BIN="$(command -v cmake)"
  elif [[ -x /opt/homebrew/opt/cmake/bin/cmake ]]; then
    CMAKE_BIN="/opt/homebrew/opt/cmake/bin/cmake"
  else
    echo "cmake not found. Set CMAKE_BIN or install cmake." >&2
    exit 1
  fi
fi

SDK="${1:-iphoneos}"
ARCH="arm64"
DEPLOYMENT_TARGET="${IOS_DEPLOYMENT_TARGET:-13.0}"
CLANG_BIN="$(xcrun --find clang)"
CLANGXX_BIN="$(xcrun --find clang++)"

case "${SDK}" in
  iphoneos)
    SLICE_NAME="ios-arm64"
    TARGET_TRIPLE="arm64-apple-ios${DEPLOYMENT_TARGET}"
    ;;
  iphonesimulator)
    SLICE_NAME="ios-arm64-simulator"
    TARGET_TRIPLE="arm64-apple-ios${DEPLOYMENT_TARGET}-simulator"
    ;;
  *)
    echo "Unsupported SDK: ${SDK}" >&2
    echo "Usage: $0 [iphoneos|iphonesimulator]" >&2
    exit 1
    ;;
esac

BUILD_ROOT="${ROOT_DIR}/build/${SLICE_NAME}"
TAGLIB_SOURCE_DIR="${ROOT_DIR}/vendor/taglib"
TAGLIB_BUILD_DIR="${BUILD_ROOT}/taglib-build"
TAGLIB_INSTALL_DIR="${BUILD_ROOT}/taglib-install"
NCMDUMP_SOURCE_DIR="${ROOT_DIR}/vendor/ncmdump"
NCMDUMP_BUILD_DIR="${BUILD_ROOT}/ncmdump-build"
NCMDUMP_INSTALL_DIR="${BUILD_ROOT}/ncmdump-install"
WRAPPER_SOURCE="${ROOT_DIR}/NCMKit/NCMKit.mm"
WRAPPER_INCLUDE_DIR="${ROOT_DIR}/NCMKit"
PUBLIC_HEADERS_DIR="${BUILD_ROOT}/Headers"
OBJECTS_DIR="${BUILD_ROOT}/objects"
OUTPUT_LIBRARY="${BUILD_ROOT}/libNCMKit.a"
SDK_PATH="$(xcrun --sdk "${SDK}" --show-sdk-path)"
TAGLIB_CMAKE_DIR="${TAGLIB_INSTALL_DIR}/lib/cmake/taglib"
TAGLIB_LIBRARY="${TAGLIB_INSTALL_DIR}/lib/libtag.a"
NCMDUMP_LIBRARY="${NCMDUMP_INSTALL_DIR}/lib/libncmdump.a"
WRAPPER_OBJECT="${OBJECTS_DIR}/NCMKit.o"

COMMON_CMAKE_ARGS=(
  -G Xcode
  -DCMAKE_SYSTEM_NAME=iOS
  -DCMAKE_OSX_SYSROOT="${SDK}"
  -DCMAKE_OSX_ARCHITECTURES="${ARCH}"
  -DCMAKE_OSX_DEPLOYMENT_TARGET="${DEPLOYMENT_TARGET}"
  -DCMAKE_BUILD_TYPE=Release
  -DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY
  -DCMAKE_XCODE_ATTRIBUTE_ONLY_ACTIVE_ARCH=NO
  -DCMAKE_C_COMPILER="${CLANG_BIN}"
  -DCMAKE_CXX_COMPILER="${CLANGXX_BIN}"
)

rm -rf "${BUILD_ROOT}"
mkdir -p "${PUBLIC_HEADERS_DIR}" "${OBJECTS_DIR}"

"${CMAKE_BIN}" -S "${TAGLIB_SOURCE_DIR}" -B "${TAGLIB_BUILD_DIR}" \
  "${COMMON_CMAKE_ARGS[@]}" \
  -DCMAKE_INSTALL_PREFIX="${TAGLIB_INSTALL_DIR}" \
  -DBUILD_SHARED_LIBS=OFF \
  -DBUILD_FRAMEWORK=OFF \
  -DBUILD_BINDINGS=OFF \
  -DBUILD_EXAMPLES=OFF \
  -DBUILD_TESTING=OFF \
  -DWITH_ZLIB=OFF

"${CMAKE_BIN}" --build "${TAGLIB_BUILD_DIR}" --config Release --target install --parallel

"${CMAKE_BIN}" -S "${NCMDUMP_SOURCE_DIR}" -B "${NCMDUMP_BUILD_DIR}" \
  "${COMMON_CMAKE_ARGS[@]}" \
  -DCMAKE_INSTALL_PREFIX="${NCMDUMP_INSTALL_DIR}" \
  -DCMAKE_PREFIX_PATH="${TAGLIB_INSTALL_DIR}" \
  -DTagLib_DIR="${TAGLIB_CMAKE_DIR}" \
  -DNCMDUMP_BUILD_CLI=OFF \
  -DNCMDUMP_BUILD_LIBRARY=ON \
  -DNCMDUMP_LIBRARY_TYPE=STATIC

"${CMAKE_BIN}" --build "${NCMDUMP_BUILD_DIR}" --config Release --target install --parallel

clang++ \
  -x objective-c++ \
  -std=c++17 \
  -fobjc-arc \
  -target "${TARGET_TRIPLE}" \
  -isysroot "${SDK_PATH}" \
  -c "${WRAPPER_SOURCE}" \
  -o "${WRAPPER_OBJECT}" \
  -I"${WRAPPER_INCLUDE_DIR}" \
  -I"${NCMDUMP_SOURCE_DIR}/src/include"

libtool -static \
  -o "${OUTPUT_LIBRARY}" \
  "${WRAPPER_OBJECT}" \
  "${NCMDUMP_LIBRARY}" \
  "${TAGLIB_LIBRARY}"

cp "${ROOT_DIR}/NCMKit/NCMKit.h" "${PUBLIC_HEADERS_DIR}/NCMKit.h"
cp "${ROOT_DIR}/NCMKit/module.modulemap" "${PUBLIC_HEADERS_DIR}/module.modulemap"

echo "Built ${OUTPUT_LIBRARY}"
echo "Headers staged at ${PUBLIC_HEADERS_DIR}"
