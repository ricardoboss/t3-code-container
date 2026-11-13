#!/bin/bash
set -euo pipefail
# shellcheck source=versions.env
source /opt/toolchain/versions.env
flutter_root=${1:?Supply the versioned Flutter installation directory}
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT

# Fetch source plus only the requested artifacts, rather than a bundle with mobile caches.
git clone --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$flutter_root"
test "$(git -C "$flutter_root" rev-parse HEAD)" = "$FLUTTER_COMMIT"
"$flutter_root/bin/flutter" config --no-analytics --no-enable-android --no-enable-ios --no-enable-linux-desktop
"$flutter_root/bin/flutter" precache --web --no-android --no-ios --no-linux --no-windows --no-macos --no-fuchsia
"$flutter_root/bin/flutter" create --platforms=web --project-name smoke_app "$scratch/app"
cd "$scratch/app"
"$flutter_root/bin/flutter" test
"$flutter_root/bin/flutter" build web --no-pub
