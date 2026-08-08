#!/bin/sh
#
# Compiles a Core Image Metal kernel into a metallib.
#
# Swift Package Manager cannot pass the `-fcikernel` and `-cikernel` flags that Core Image kernels
# require, and it has no equivalent of an Xcode build rule, so the two compilation steps are driven
# by hand here from a build tool plugin.
#
# Usage: build-cikernel.sh <source.ci.metal> <output.metallib> <work-directory>

set -eu

src="$1"
out="$2"
work="$3"

# The metallib embeds the target triple, so a library built for the simulator will not load on a
# device and vice versa. Xcode exports SDKROOT for the destination being built; refuse to guess when
# it is absent rather than silently emitting a macOS library that fails to load at runtime.
if [ -z "${SDKROOT:-}" ]; then
  echo "error: SDKROOT is not set, cannot tell which platform to compile the kernel for." >&2
  echo "note: this kernel is compiled by an Xcode build; 'swift build' is not supported." >&2
  exit 1
fi

if ! xcrun -f metal >/dev/null 2>&1; then
  echo "error: the Metal toolchain is not installed." >&2
  echo "note: run 'xcodebuild -downloadComponent MetalToolchain'" >&2
  exit 1
fi

air="$work/$(basename "$src" .metal).air"
cache="$work/ModuleCache"
mkdir -p "$cache"

# Clang enables modules for Metal by default, and its default cache lives outside the plugin
# sandbox, so point it inside the work directory.
xcrun metal -c -fcikernel -isysroot "$SDKROOT" -fmodules-cache-path="$cache" "$src" -o "$air"
xcrun metallib -cikernel "$air" -o "$out"
