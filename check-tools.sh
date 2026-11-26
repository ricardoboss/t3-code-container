#!/bin/bash
set -euo pipefail

if [[ ${1:-} == --manifest ]]; then
  cat /opt/toolchain/versions.env
  printf '\n# Base runtimes\n'
  node --version
  python3 --version
  dotnet --list-sdks
  pwsh --version
  printf '\n# Debian packages\n'
  cat /opt/toolchain/debian-packages.tsv
  exit 0
fi

failed=0
for tool in t3 codex claude opencode grok node npm n pnpm yarn corepack python3 pip pipx uv uvx \
  ruff dotnet pwsh bash flutter dart docker gh glab git git-lfs rg fd jq yq tree curl wget \
  cmake ninja gcc g++ rustc cargo make pkg-config shellcheck shfmt ps pstree ip dig nc lsof \
  sqlite3 rsync zip unzip xz zstd 7z flock; do
  if location=$(command -v "$tool"); then
    printf '%-14s %s\n' "$tool" "$location"
  else
    printf 'Missing tool: %s\n' "$tool" >&2
    failed=1
  fi
done

if [[ ${1:-} == --auth ]]; then
  for tool in gh codex claude opencode grok; do
    printf '\n--- %s authentication ---\n' "$tool"
    case "$tool" in
      gh) gh auth status --hostname "${GH_HOST:-github.com}" || failed=1 ;;
      codex) codex login status || failed=1 ;;
      claude) claude auth status --text || failed=1 ;;
      opencode) opencode auth list || failed=1 ;;
      grok)
        if output=$(grok models 2>&1); then
          printf '%s\n' "$output"
          if [[ -z ${XAI_API_KEY:-} && "$output" =~ [Nn]ot\ (authenticated|logged\ in) ]]; then
            failed=1
          fi
        else
          printf '%s\n' "$output" >&2
          failed=1
        fi
        ;;
    esac
  done
  printf '\nT3 Connect: use t3 connect status to inspect the environment link.\n'
fi
exit "$failed"
