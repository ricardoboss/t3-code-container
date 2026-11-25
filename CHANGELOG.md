# Changelog

## [Unreleased]

## [v1.0.6] - 2026-11-25

- Provide pinned PowerShell Core (`pwsh`) alongside the existing Bash login shell.
- Include curl and Expat development headers, gettext, and Rust/Cargo so users can build Git into their persistent home without root access.
- Provision pinned Python in the tools volume and support persistent user-selected `python3` versions through uv.
- Refresh stable tool releases, the T3/browser pair, Flutter, and Node/Docker image digests.

## [v1.0.5] - 2026-11-21

- Include the remaining Debian runtime libraries required by full Chromium builds (`libcups2t64`, `libcairo2`, `libpango-1.0-0`, plus explicit `libdrm2` and `libnspr4`) and smoke-test loading all Chromium shared libraries.

## [v1.0.4] - 2026-11-19

- Keep the toolchain `PATH` in login shells, so `t3` and provisioned tools work in agent commands run through `bash -lc`.

## [v1.0.3] - 2026-11-18

- Fix project-scoped `npm install` failing with `EALLOWSCRIPTS` by removing the image-wide `NPM_CONFIG_ALLOW_SCRIPTS`; harness installs already approve their scripts explicitly.

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
