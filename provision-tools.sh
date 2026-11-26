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
  UV_PYTHON_BIN_DIR="$release/python/bin" /opt/agent-tools/bin/uv python install \
    --install-dir "$release/python" --default "$PYTHON_VERSION"
  "$release/python/bin/python3" -c 'import ssl, sqlite3, ctypes, bz2, lzma, zlib, venv'
  bash /opt/toolchain/dotnet-install.sh --version "$DOTNET_VERSION" --install-dir "$release/dotnet" --no-path
  mkdir -p "$release/powershell"
  curl -fsSL "https://github.com/PowerShell/PowerShell/releases/download/v$POWERSHELL_VERSION/powershell-$POWERSHELL_VERSION-linux-x64.tar.gz" \
    -o "$release/powershell.tar.gz"
  printf '%s  %s\n' "$POWERSHELL_SHA256" "$release/powershell.tar.gz" | sha256sum -c -
  tar -xzf "$release/powershell.tar.gz" -C "$release/powershell"
  rm "$release/powershell.tar.gz"
  chmod +x "$release/powershell/pwsh"
  # Isolate GROK_HOME so @xai-official/grok postinstall does not write binaries or config into $HOME/.grok.
  GROK_HOME="$release/.grok-postinstall" /opt/agent-tools/bin/npm install --global --prefix "$release/harnesses" \
    --allow-scripts=@openai/codex,@anthropic-ai/claude-code,@opencode/cli,@xai-official/grok \
    "@openai/codex@$CODEX_VERSION" "@anthropic-ai/claude-code@$CLAUDE_VERSION" \
    "@opencode/cli@$OPENCODE_VERSION" "@xai-official/grok@$GROK_VERSION"
  rm -rf "$release/.grok-postinstall"
  /usr/local/bin/install-flutter.sh "$release/flutter"
  {
    cat /opt/toolchain/versions.env
    "$release/python/bin/python3" --version
    "$release/dotnet/dotnet" --list-sdks
    "$release/powershell/pwsh" --version
    "$release/harnesses/bin/codex" --version
    "$release/harnesses/bin/claude" --version
    "$release/harnesses/bin/opencode" --version
    "$release/harnesses/bin/grok" --version
    "$release/flutter/bin/flutter" --version
  } > "$release/tool-versions.txt"
  touch "$release/.ready"
fi

if [[ $(readlink "$tools_root/current" || true) != "releases/$key" ]]; then
  ln -s "releases/$key" "$tools_root/.current-$$"
  mv -Tf "$tools_root/.current-$$" "$tools_root/current"
fi
