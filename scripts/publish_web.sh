#!/usr/bin/env sh
set -eu
FLUTTER_BIN="${FLUTTER_BIN:-./toolchains/flutter/bin/flutter}"
export XDG_CONFIG_HOME="${FLUTTER_CONFIG_HOME:-./.config}"
export PUB_CACHE="${PUB_CACHE:-./.pub-cache}"
export FLUTTER_SUPPRESS_ANALYTICS=true
"$FLUTTER_BIN" build web --release
rm -rf public
mkdir -p public
cp -R build/web/. public/
# Flutter's loader uses its engine-revision-pinned public CanvasKit CDN by
# default. These local copies are not used unless useLocalCanvasKit is enabled.
rm -rf public/canvaskit public/flutter.js.map
echo 'Vercel static web files prepared in public/.'
