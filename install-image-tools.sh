#!/bin/bash
set -euo pipefail
# shellcheck source=versions.env
source /opt/toolchain/versions.env

export NPM_CONFIG_CACHE=/tmp/t3-npm-cache
export UV_CACHE_DIR=/tmp/t3-uv-cache
export PATH="/opt/agent-tools/bin:/opt/dotnet:$PATH"
mkdir -p /opt/agent-tools/bin /opt/toolchain

curl -fsSL https://dot.net/v1/dotnet-install.sh -o /tmp/dotnet-install.sh
mv /tmp/dotnet-install.sh /opt/toolchain/dotnet-install.sh

NPM_CONFIG_PREFIX=/opt/agent-tools npm install --global \
  "npm@$NPM_VERSION" "n@$N_VERSION" "corepack@$COREPACK_VERSION"
COREPACK_HOME=/opt/corepack corepack pack "pnpm@$PNPM_VERSION" "yarn@$YARN_VERSION" -o /opt/toolchain/corepack.tgz
printf '%s\n' "$PNPM_VERSION" "$YARN_VERSION" > /opt/toolchain/corepack.versions
corepack enable --install-directory /opt/agent-tools/bin

curl -fsSL "https://astral.sh/uv/$UV_VERSION/install.sh" -o /tmp/uv-install.sh
UV_INSTALL_DIR=/opt/agent-tools/bin UV_NO_MODIFY_PATH=1 sh /tmp/uv-install.sh
UV_TOOL_DIR=/opt/uv-tools UV_TOOL_BIN_DIR=/opt/agent-tools/bin uv tool install "ruff==$RUFF_VERSION"
rm /tmp/uv-install.sh

INSTALL_BIN_DIR=/opt/agent-tools/bin /usr/local/bin/install-forge-cli.sh gh "$GH_VERSION"
INSTALL_BIN_DIR=/opt/agent-tools/bin /usr/local/bin/install-forge-cli.sh glab "$GLAB_VERSION"

mkdir -p /opt/t3 /tmp/t3-install
cd /tmp/t3-install
archive="t3-$T3_VERSION-linux-x64.tar.gz"
release="https://github.com/pingdotgg/t3code/releases/download/v$T3_VERSION"
curl -fsSLO "$release/$archive"
curl -fsSLO "$release/SHA256SUMS"
awk -v name="$archive" '$2 == name || $2 == "*" name { print }' SHA256SUMS > selected.sha256
test -s selected.sha256
sha256sum -c selected.sha256
tar -xzf "$archive" -C /opt/t3 --strip-components=1
printf '%s\n' "$T3_VERSION" > /opt/t3/version
printf '%s\n' "$T3_VERSION" > /opt/t3/.install-complete

# Check the browser lock against the selected release's source before seeding its native cache.
curl -fsSL "https://raw.githubusercontent.com/pingdotgg/t3code/$T3_SOURCE_REF/apps/server/src/preview/PreviewBrowser.ts" -o /tmp/PreviewBrowser.ts
grep -F "const VERSION = \"$T3_BROWSER_VERSION\"" /tmp/PreviewBrowser.ts
grep -F "$T3_BROWSER_SHA256" /tmp/PreviewBrowser.ts
curl -fsSL "https://storage.googleapis.com/chrome-for-testing-public/$T3_BROWSER_VERSION/linux64/chrome-headless-shell-linux64.zip" -o /tmp/browser.zip
printf '%s  /tmp/browser.zip\n' "$T3_BROWSER_SHA256" | sha256sum -c -
unzip -q /tmp/browser.zip -d /tmp/browser
mv /tmp/browser/chrome-headless-shell-linux64 /opt/t3-browser
chmod -R a+rX /opt/t3-browser
printf '%s\n' "$T3_BROWSER_VERSION" > /opt/t3-browser/version

dpkg-query -W -f='${Package}\t${Version}\n' > /opt/toolchain/debian-packages.tsv
chown -R node:node /opt/agent-tools /opt/uv-tools
rm -rf /tmp/t3-npm-cache /tmp/t3-uv-cache /tmp/t3-install /tmp/PreviewBrowser.ts /tmp/browser.zip /tmp/browser /opt/corepack
