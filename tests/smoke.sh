#!/bin/bash
set -euo pipefail

t3 --version
check-tools
for tool in codex claude opencode gh glab uv ruff npm pnpm yarn; do
  "$tool" --version
done
docker compose version
docker buildx version
dotnet --list-sdks
flutter --version
dart --version

scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
cd "$scratch"
mkdir npm-project
printf '{"name":"npm-project","version":"1.0.0"}\n' > npm-project/package.json
npm install --offline --prefix npm-project
printf '#include <stdio.h>\nint main(void) { puts("native-ok"); }\n' > main.c
cc main.c -o main
test "$(./main)" = native-ok
uv venv --offline .venv
.venv/bin/python -c 'import ssl, sqlite3, ctypes; print("python-ok")'
mkdir empty-feed
dotnet new console --no-restore --output dotnet-app
dotnet restore dotnet-app --source "$scratch/empty-feed" -p:NuGetAudit=false
dotnet run --project dotnet-app --no-restore

browser_version=$(cat /opt/t3-browser/version)
browser="$T3CODE_HOME/tools/chrome-headless-shell/linux64/$browser_version/chrome-headless-shell"
"$browser" --no-sandbox --disable-gpu --dump-dom 'data:text/html,<title>preview-ok</title>' | grep -F preview-ok
"$browser" --no-sandbox --disable-gpu --screenshot="$scratch/preview.png" 'data:text/html,<h1>preview-ok</h1>'
test -s "$scratch/preview.png"

flutter create --offline --platforms=web --project-name smoke_app app
cd app
flutter test
flutter build web --no-pub
