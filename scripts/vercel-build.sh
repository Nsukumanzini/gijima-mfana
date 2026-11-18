#!/usr/bin/env bash
set -euo pipefail

# Vercel's static build image does not include Flutter. Install the exact stable
# SDK revision used by the project, then publish the complete web output.
FLUTTER_REVISION="${FLUTTER_REVISION:-ab2912035e}"
FLUTTER_ROOT="${TMPDIR:-/tmp}/gijima-flutter-${FLUTTER_REVISION}"

if [[ ! -x "$FLUTTER_ROOT/bin/flutter" ]]; then
  mkdir -p "$FLUTTER_ROOT"
  git -C "$FLUTTER_ROOT" init -q
  git -C "$FLUTTER_ROOT" remote add origin https://github.com/flutter/flutter.git
  git -C "$FLUTTER_ROOT" fetch --depth 1 origin "$FLUTTER_REVISION"
  git -C "$FLUTTER_ROOT" checkout -q FETCH_HEAD
fi

export PUB_CACHE="${PUB_CACHE:-${TMPDIR:-/tmp}/gijima-pub-cache}"
"$FLUTTER_ROOT/bin/flutter" config --enable-web
"$FLUTTER_ROOT/bin/flutter" pub get
"$FLUTTER_ROOT/bin/flutter" build web --release

rm -rf public
mkdir -p public
cp -R build/web/. public/
rm -rf public/canvaskit public/flutter.js.map
