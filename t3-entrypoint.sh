#!/bin/sh
set -eu

# Serialize initial provisioning when commands share a persistent home.
mkdir -p "$HOME/.cache"
exec 9>"$HOME/.cache/t3-image-seed.lock"
flock 9

# No server/agent starts until the persistent SDK and harness installation is ready.
PATH=/opt/agent-tools/bin:/usr/local/bin:/usr/bin:/bin /usr/local/bin/provision-tools >&2

# Seed only missing caches. Credentials and deliberate user tool overrides stay intact.
if ! cmp -s /opt/toolchain/corepack.versions "$COREPACK_HOME/.image-ready"; then
    corepack install --global /opt/toolchain/corepack.tgz >&2
    # pnpm's package fetches its native executable on first use, beyond Corepack's archive.
    /opt/agent-tools/bin/pnpm --version >&2
    /opt/agent-tools/bin/yarn --version >&2
    cp /opt/toolchain/corepack.versions "$COREPACK_HOME/.image-ready"
fi

browser_version=$(cat /opt/t3-browser/version)
browser_root="$T3CODE_HOME/tools/chrome-headless-shell/linux64"
mkdir -p "$browser_root"
if [ ! -e "$browser_root/$browser_version" ]; then
    staging=$(mktemp -d "$browser_root/.seed-XXXXXX")
    trap 'rm -rf "$staging"' EXIT
    cp -a /opt/t3-browser/. "$staging/"
    mv "$staging" "$browser_root/$browser_version"
    trap - EXIT
fi

runtime="$T3CODE_HOME/runtime"
state="$runtime/service-state.json"
if [ ! -f "$state" ]; then
    version=$(cat /opt/t3/version)
    mkdir -p "$runtime/versions"
    staging=$(mktemp -d "$runtime/versions/.seed-XXXXXX")
    trap 'rm -rf "$staging"' EXIT
    cp -a /opt/t3/. "$staging/"
    if [ ! -d "$runtime/versions/$version" ]; then
        mv "$staging" "$runtime/versions/$version"
    fi
    rm -rf "$staging"
    trap - EXIT
    jq -n --arg version "$version" '{protocol: 3, activeVersion: $version}' > "$runtime/.service-state.tmp"
    mv "$runtime/.service-state.tmp" "$state"
fi
flock -u 9
exec 9>&-

# Resolve the active runtime on every invocation, including after a UI update.
version=$(jq -er '.activeVersion | select(test("^[0-9]+\\.[0-9]+\\.[0-9]+([-+][0-9A-Za-z.+-]+)?$"))' "$state")
executable="$runtime/versions/$version/t3"
if [ "$(cat "$runtime/versions/$version/.install-complete")" != "$version" ]; then
    echo "Incomplete T3 runtime: $version" >&2
    exit 1
fi

if [ "$#" -eq 0 ]; then
    set -- __service-launcher
fi
check-tools > /dev/null
exec "$executable" "$@"
