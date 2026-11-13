# T3 Code on your server

Requires a Linux amd64 server with Docker Engine, Docker Compose v2, and curl.

1. Download the configuration and prepare the workspace:

   ```sh
   mkdir -p t3-code-container
   cd t3-code-container
   curl -fsSLO https://raw.githubusercontent.com/ricardoboss/t3-code-container/v1/compose.yaml
   curl -fsSL https://raw.githubusercontent.com/ricardoboss/t3-code-container/v1/.env.example -o .env
   printf '\nT3_HOSTNAME=%s\n' "$(hostname)" >> .env
   sudo install -d -m 0750 -o 1000 -g 1000 \
     /srv/t3-workspace /srv/t3-workspace/repos /srv/t3-workspace/worktrees
   ```

2. Pull the image and sign in. Open the printed authorization links on another device. First setup can take several minutes.

   ```sh
   docker compose pull t3
   docker compose run --rm t3 connect link --headless
   docker compose run --rm --entrypoint setup-tools t3
   ```

3. Start T3:

   ```sh
   docker compose up -d
   docker compose ps
   ```

4. Sign into the same T3 Connect account in T3, select your server, and enable your providers in Settings. Put projects in `/workspace/repos`.

To enable Docker containers for agents:

```sh
curl -fsSLO https://raw.githubusercontent.com/ricardoboss/t3-code-container/v1/compose.docker.yaml
docker compose -f compose.yaml -f compose.docker.yaml up -d
```

[Operations and updates](docs/operations.md) · [Publishing releases](docs/releases.md)
