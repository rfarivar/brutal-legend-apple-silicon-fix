#!/bin/sh
set -eu

cd "$(dirname "$0")"
if ! /usr/bin/xcode-select -p >/dev/null 2>&1; then
    printf '%s\n' 'Install the Xcode Command Line Tools with xcode-select --install, then run the launcher again.' >&2
    exit 1
fi

build_dir="$(mktemp -d ./.build.XXXXXXXX)"
trap 'rm -rf "$build_dir"' EXIT
trap 'exit 1' HUP INT TERM
/usr/bin/clang -arch x86_64 -mmacosx-version-min=11.0 -dynamiclib \
    -O2 -Wall -Wextra -Werror -o "$build_dir/render-priority.dylib" render-priority.c
/usr/bin/codesign --force --sign - "$build_dir/render-priority.dylib"
mv -f "$build_dir/render-priority.dylib" ./render-priority.dylib
