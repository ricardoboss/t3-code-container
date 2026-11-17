# Changelog

## [v1.0.2] - 2026-11-17

- Disable T3's host sleep inhibitor in containers, including existing homes and updated runtimes, while preserving other settings.
- Update T3 to 0.1.10 with its matching preview browser, pnpm, Yarn, uv, Claude Code, Docker, and pinned release workflow actions to their latest stable releases; use the Ubuntu 26.04 release runner.

## [v1.0.1] - 2026-11-14

- Remove Discord webhook forwarding and the hardcoded GitHub host.
- Keep optional deployment settings as commented examples and document base-image overrides as maintenance settings.
- Reuse image defaults for telemetry and the preview browser sandbox instead of repeating them in Compose.

## [v1] - 2026-11-13

- Headless T3 Code deployment with T3 Connect and a bundled preview browser.
- Pinned Codex, Claude Code, OpenCode, .NET, and Flutter/Dart provisioned into persistent storage before T3 starts.
- Common development, Git, shell, archive, and diagnostic tools included in the image.
- Optional Docker-in-Docker service, configurable resource limits, and shared dependency caches.
- Non-root execution with a read-only image and persistent workspace, state, tools, and scratch storage.
- Version-tag publishing to GHCR and GitHub Releases, gated by regression and offline smoke tests.
