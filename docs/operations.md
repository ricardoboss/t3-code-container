# Operations

## Included tools

| Area | Included |
| --- | --- |
| Agents | T3, Codex, Claude Code, OpenCode, Grok |
| JavaScript | Node.js, npm, n, Corepack, pnpm, Yarn |
| Python | Python 3, pip, venv, pipx, uv/uvx, Ruff; native extension headers |
| .NET | .NET SDK; global user tools on PATH |
| Flutter | Flutter and bundled Dart SDK; pre-cached web and test artifacts |
| Native builds | GCC/G++, Rust/Cargo, Make, CMake, Ninja, pkg-config, gettext; curl, Expat, OpenSSL, ICU, SQLite, libffi and zlib headers |
| Git/hosting | Git, Git LFS, OpenSSH client, GitHub CLI, GitLab CLI |
| Files/data | ripgrep, fd, tree, jq, yq, SQLite, rsync, file, patch, less |
| Archives | zip/unzip, xz, zstd, 7zip |
| Shell checks | ShellCheck, shfmt |
| Shells | Bash (login shell), PowerShell Core (`pwsh`) |
| Diagnostics | procps, psmisc, iproute2, DNS utilities, netcat, lsof |
| Network | curl, wget, CA certificates |
| Containers | Docker CLI, Buildx, Compose; optional dedicated daemon |
| Preview | T3's matching headless Chrome, runtime libraries, Liberation/Noto/emoji fonts |

`yq` is Debian's jq-based YAML processor. Project-local formatters, test frameworks,
and language servers remain project dependencies. Corepack includes the pinned
pnpm/Yarn defaults; projects can request other versions through `packageManager`.
Dependency restores can still need network access.

**No Android SDK/NDK, JDK, emulator, or other optional language SDKs are included.**
Flutter can analyze/test Dart and build web apps. Android builds need additional
tooling; iOS builds require macOS. Linux desktop build dependencies are not included.

## Installation and persistence

| Location | Purpose |
| --- | --- |
| `/workspace` | Dedicated host bind for repositories and worktrees |
| `/home/node` | Persistent T3 state, credentials, user overrides, and dependency caches |
| `/opt/agent-tools` | Image-owned package managers and utility tools |
| `/opt/tools` | Persistent, versioned SDKs and agent harnesses |
| `/opt/dotnet`, `/opt/flutter` | Links to the selected SDKs in the tools volume |
| `/opt/toolchain` | Release pins, resolved tool manifest, Debian package inventory |
| `/tmp` | Disk-backed scratch volume; survives recreation |

SDKs and harnesses are installed as UID 1000 into a release directory keyed by the
version pins and installer scripts. A completion marker is written only after
installation and checks succeed; the active tools link switches afterwards.
Failed setup stops startup and is retried on the next run. Provisioning is
serialized across commands sharing the tools volume. Changed pins or installers
create a new release; an existing tools volume cannot hide an image update.

The entrypoint also seeds the writable T3 runtime/browser cache and imports the
package-manager cache. Flutter writes its cache directly in the tools volume,
avoiding an image copy plus a second writable cache. This favors smaller image
downloads over initial startup speed; installed tools still occupy disk space.

User installations in `$HOME/.local/bin` take precedence over image tools, followed
by .NET global tools, provisioned Python and PowerShell, bundled CLIs, Flutter, and .NET. They are deliberate overrides:
an existing provider installed there continues to shadow the image after a rebuild.
Use `check-tools` to see the selected executable; remove an unwanted override with
its package manager to return to the bundled version. Never delete credentials to
refresh a tool. Existing homes and user-selected T3 runtimes are preserved.

On each startup, the entrypoint disables `keepAwakeWhileAgentsWork` in T3's
`userdata/settings.json`, preserving other settings. T3 0.1.10 introduced this
desktop feature, which invokes `systemd-inhibit` on Linux. Containers cannot
inhibit host sleep and have no systemd/logind service; host power management
belongs on the server. This also applies to runtimes installed through T3's updater.

Provider/GitHub authentication and updates are available through `setup-tools`.
Updates install user overrides rather than modifying the image. GitLab uses its
native `glab auth login` flow. User Node versions can be installed with `n`;
.NET global tools with `dotnet tool install --global`.

Python is pinned and provisioned in the tools volume. To select a newer default
`python`/`python3`, run `uv python install --default VERSION` (for example,
`uv python install --default 3.15`). User Python installations and executable links
live in the persistent home and take precedence after restart or image updates.
Use `uv python upgrade` for patch updates to these user installations and
`python3 -m pip` or `uv pip` to target the selected interpreter; the Debian `pip`
command belongs to the system Python. The system Python remains for OS tools.

Git source-build dependencies, including Cargo for Git 2.56's default Rust code,
are included. Build a newer upstream release with
`make prefix="$HOME/.local" all` and `make prefix="$HOME/.local" install` in its
extracted source directory. This installs a persistent user override without root
access or changes to the read-only image.

Change pinned SDK/harness versions by editing `versions.env`, rebuilding, and
recreating the container. Do not run `flutter upgrade` inside a versioned SDK.

PowerShell Core is pinned and checksum-verified in the tools volume. Run `pwsh`
to use it; Bash remains the login shell. Both shells inherit the toolchain PATH.

For an existing deployment, back up the stopped home volume and workspace before
upgrading. The default Compose project/home-volume name is retained. The old
Docker daemon is now opt-in: use the override below to retain container workloads.
Do not run `down --volumes` during migration.

## Optional Docker daemon

```sh
docker compose -f compose.yaml -f compose.docker.yaml up -d
```

Use the same two `-f` options for subsequent Compose operations. The override adds
a dedicated privileged Docker-in-Docker daemon, TLS client certificates, and a
private API network. The host Docker socket is never mounted. Its workspace mount
has the same `/workspace` path, so nested bind mounts must use workspace paths.
Nested published ports are reachable from T3 at `docker:PORT`, not `localhost`.

This daemon is for trusted agents on a dedicated host/VM; agents control containers
it launches, including privileged containers. It has separate resource limits.
When returning to the base stack, stop the daemon using the override first, or use
`--remove-orphans`; otherwise the existing daemon can keep running.

## Limits and storage

`.env` controls CPU, memory, PID limits, shared memory, and parallel build jobs.
Defaults are 4 CPUs, 8 GiB, 4096 PIDs, 512 MiB `/dev/shm`, and two Make/CMake jobs
per build. These are configurable ceilings, not a tested agent-capacity promise.
Shared memory counts toward the memory limit when used. Different build tools
may have their own worker settings.

`init: true` reaps orphan processes; shutdown has a 60-second grace period.
The container runs as UID/GID 1000 with a read-only image, no capabilities, and
`no-new-privileges`. Chrome's nested sandbox is disabled; the container is its
boundary. T3, browsers, and agents share the home, credentials, and workspace.
Separate untrusted projects into separate stacks. Outbound networking is enabled.

Docker logs rotate. Dependency caches and scratch storage are shared across
worktrees within this stack; disk usage still needs monitoring. Use native cache
maintenance (`uv cache prune`, `npm cache clean --force`) when appropriate. Stop
T3 before removing inactive releases under `/opt/tools/releases` or clearing
scratch files. Keep the release selected by `/opt/tools/current`. With the Docker override, prune build storage through that
daemon when needed. No automatic job deletes active builds or worktrees.

Back up the home and workspace with T3 stopped. `docker compose down` preserves
volumes; `down --volumes` deletes state, credentials, installed SDKs/harnesses,
caches, and scratch data.
With the Docker override it also deletes nested Docker storage and certificates.

## Versions and updates

Release versions/checksums live in `versions.env`. Node and Docker base images use
exact tags and digests in the Dockerfile/Compose override. The browser version/hash
is checked against the selected T3 source revision before download. Release archives
are checksum-verified; Flutter source is pinned to a verified Git commit and only
web/test artifacts are pre-cached. Debian packages receive current repository
security updates at build time; their resolved versions are recorded, so rebuilds
are not guaranteed bit-for-bit identical.

Base-image overrides are maintenance settings, not required deployment configuration.
For local builds, Compose accepts `NODE_IMAGE` and `DOCKER_CLI_IMAGE` as build arguments.
The optional Docker stack accepts `DOCKER_DAEMON_IMAGE` for its daemon image.
Use exact tags and `@sha256:` digests, and validate the resulting image/stack before
deployment. Normal installations use the published image and checked-in daemon pin.

After provisioning, inspect `/opt/toolchain/tool-versions.txt` and
`/opt/toolchain/debian-packages.tsv` inside the container.
To update, review the release pins together, rebuild, run the checks below, and
recreate the service. Keep the T3 version, source revision, and browser pins aligned.

```sh
docker compose build --pull
docker compose up -d
```

T3's server-runtime update action remains supported and persists across container
recreation. A newer T3 runtime may require a newer browser and download it on first
use. The no-download preview guarantee covers the bundled T3/browser pair. T3
Connect can also download its managed relay during initial authorization.

## Verification

```sh
# First provision disposable verification volumes with network access.
docker run --rm --read-only \
  --mount type=volume,src=t3-verification-home,dst=/home/node \
  --mount type=volume,src=t3-verification-tools,dst=/opt/tools \
  --mount type=volume,src=t3-verification-scratch,dst=/tmp \
  ghcr.io/ricardoboss/t3-code-container:v1 --version

# Reuse those tools without network access. Tests need no account credentials.
docker run --rm --network none --read-only --cap-drop ALL \
  --security-opt no-new-privileges:true \
  --mount type=volume,src=t3-verification-home,dst=/home/node \
  --mount type=volume,src=t3-verification-tools,dst=/opt/tools \
  --mount type=volume,src=t3-verification-scratch,dst=/tmp \
  --mount type=bind,src="$PWD",dst=/repo,readonly \
  --entrypoint bash ghcr.io/ricardoboss/t3-code-container:v1 -c \
  'node --test /repo/tests/*.test.cjs && bash /repo/tests/smoke.sh'
```

The smoke check runs native/Python/.NET tooling, headless browser rendering, provider
version checks, and a Flutter test/web build without network access. Account-backed
agent turns and Connect reachability require authenticated integration testing.
The test suite also runs 32 concurrent Node/Python workers and concurrent T3
initialization. This synthetic load does not establish capacity for live agent sessions.

References: [T3 remote access](https://github.com/pingdotgg/t3code/blob/main/docs/user/remote-access.md),
[Compose services](https://docs.docker.com/reference/compose-file/services/),
[Corepack](https://github.com/nodejs/corepack),
[Flutter installation](https://docs.flutter.dev/install/manual).
