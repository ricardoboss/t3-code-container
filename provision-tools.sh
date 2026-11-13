#!/bin/bash
set -euo pipefail
# shellcheck source=versions.env
source /opt/toolchain/versions.env

tools_root=/opt/tools
mkdir -p "$tools_root/releases"
exec 8>"$tools_root/.provision.lock"
flock 8
# Include installer changes so a fixed setup is retried after an image update.
key=$(cat /opt/toolchain/versions.env /usr/local/bin/provision-tools /usr/local/bin/install-flutter.sh | sha256sum | cut -d' ' -f1)
release="$tools_root/releases/$key"

if [[ ! -f "$release/.ready" ]]; then
  printf 'Provisioning pinned SDKs and agent harnesses. T3 starts after verification.\n' >&2
  # Only this hash-derived, lock-protected release can be an incomplete installation.
  rm -rf "$release"
  mkdir -p "$release"
  trap 'printf "Tool provisioning failed; restart to retry. T3 has not started.\n" >&2' ERR
  bash /opt/toolchain/dotnet-install.sh --version "$DOTNET_VERSION" --install-dir "$release/dotnet" --no-path
  /opt/agent-tools/bin/npm install --global --prefix "$release/harnesses" \
    --allow-scripts=@openai/codex,@anthropic-ai/claude-code,@opencode/cli \
    "@openai/codex@$CODEX_VERSION" "@anthropic-ai/claude-code@$CLAUDE_VERSION" "@opencode/cli@$OPENCODE_VERSION"
  /usr/local/bin/install-flutter.sh "$release/flutter"
  {
    cat /opt/toolchain/versions.env
    "$release/dotnet/dotnet" --list-sdks
    "$release/harnesses/bin/codex" --version
    "$release/harnesses/bin/claude" --version
    "$release/harnesses/bin/opencode" --version
    "$release/flutter/bin/flutter" --version
  } > "$release/tool-versions.txt"
  touch "$release/.ready"
fi

if [[ $(readlink "$tools_root/current" || true) != "releases/$key" ]]; then
  ln -s "releases/$key" "$tools_root/.current-$$"
  mv -Tf "$tools_root/.current-$$" "$tools_root/current"
fi
