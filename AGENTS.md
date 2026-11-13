# Repository guidance

## Product decisions

- Deliver a completely headless T3 deployment, including server-side previews and
  multiple ready-to-use agent harnesses. Do not require a desktop or display server.
- Prioritize image size over build time. Slower first startup is acceptable;
  agents must receive a fully provisioned environment.
- Include common development and diagnostic tools so agents need not install
  basic utilities or invent alternatives. Optimize for many concurrent processes.
- Keep OS dependencies, T3, its matching preview browser, and bootstrap utilities
  in the image. Provision pinned SDKs and Codex, Claude Code, and OpenCode into
  the persistent tools volume before starting T3.
- Include Flutter and its bundled Dart SDK with web/test artifacts. Exclude the
  Android SDK/NDK, JDK, emulators, and other optional SDK extensions unless requested.
- Target Linux amd64; do not advertise other architectures without validation.

## Implementation constraints

- Keep the implementation small and use supported upstream interfaces. Confirm
  tool APIs against the pinned release or a focused experiment.
- Keep release pins in `versions.env` and base-image digests in the Dockerfile
  and Compose configuration. Update T3, its source revision, and browser pins together.
- Preserve serialized provisioning, completion checks, and the startup readiness
  gate. A failed or partial installation must not expose an unready server.
- Reuse completed installations on restart. Exercise package-manager commands
  during initial setup so first-use native downloads happen before agents start.
- Preserve credentials, repositories, user tool overrides, and user-selected T3
  runtimes across recreation. Store SDK/harness toolchains separately from the home;
  update their version selection without resetting user state.
- Retain non-root execution, the read-only image, process reaping, resource limits,
  dropped capabilities, and `no-new-privileges`. Keep scratch data disk-backed.
- Keep Docker-in-Docker optional in `compose.docker.yaml`, with its dedicated
  daemon and TLS connection. Do not mount the host Docker socket or enable
  privileged mode on the T3 service to solve browser or provider issues.

## Documentation and distribution

- Keep `README.md` short and limited to getting the container running on a server.
  Use configuration downloads and the published GHCR image; require no Git clone
  or local image build. Put explanations and maintenance procedures in `docs/`.
- Publish public images under `ghcr.io/ricardoboss/t3-code-container`.
- Keep releases tag-driven: stable version tags such as `v1` and `v1.2.3` trigger
  image publication and GitHub Releases after checks pass. Use `GITHUB_TOKEN`, not
  an additional registry secret, and pin workflow actions to commit SHAs.
- Add a matching section to `CHANGELOG.md` before tagging. Follow
  [docs/releases.md](docs/releases.md); do not move published Git version tags.

## Validation

- For shell changes, run `shellcheck -x -P SCRIPTDIR *.sh tests/smoke.sh` from a
  Linux shell or equivalent tooling. Validate workflow changes with `actionlint`.
- Validate both Compose configurations with `docker compose config --quiet` and
  `docker compose -f compose.yaml -f compose.docker.yaml config --quiet`, setting
  `T3_WORKSPACE_DIR` to an existing absolute directory.
- For image or startup changes, build a candidate and provision fresh persistent
  volumes online. Reuse those volumes with networking disabled and the checkout
  mounted at `/repo`, then run:

  ```sh
  node --test /repo/tests/*.test.cjs
  bash /repo/tests/smoke.sh
  ```

  Use the container restrictions and verification procedure in
  [docs/operations.md](docs/operations.md#verification). Run these Linux integration
  checks against the candidate image, not directly on a Windows host.
- Distinguish image builds, provisioning, offline tests, and authenticated runtime
  verification. Synthetic parallel-worker tests do not establish live agent capacity.
- For documentation-only changes, check referenced paths and `git diff --check`;
  an image rebuild is unnecessary.
