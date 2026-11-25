# syntax=docker/dockerfile:1
ARG NODE_IMAGE=node:26.13.1-trixie-slim@sha256:abe7e5a82b61a8ef67b315b85497c9e65173387ccf2f4a029248184b8e020be5
ARG DOCKER_CLI_IMAGE=docker:29.10.1-cli@sha256:6e26c5a09acc481245d6b50836f1f713c609e51ebc88735c08f5aa4b3c91e15a
FROM ${DOCKER_CLI_IMAGE} AS docker-cli
FROM ${NODE_IMAGE} AS runtime

# This image is validated on amd64, including the pinned preview browser.
ARG TARGETARCH
RUN test "$TARGETARCH" = amd64

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      build-essential ca-certificates cargo cmake curl file gettext git git-lfs jq less rustc \
      libcurl4-openssl-dev libexpat1-dev \
      libatomic1 libffi-dev libglu1-mesa libgssapi-krb5-2 libicu-dev \
      libsqlite3-dev libssl-dev ninja-build openssh-client patch pkg-config \
      libnspr4 libnss3 libglib2.0-0t64 libatk1.0-0t64 libatk-bridge2.0-0t64 libatspi2.0-0t64 \
      libcups2t64 libcairo2 libpango-1.0-0 libdbus-1-3 libdrm2 libx11-6 libxcb1 \
      libxcomposite1 libxdamage1 libxext6 libxfixes3 libxrandr2 libxkbcommon0 \
      libgbm1 libasound2t64 libexpat1 \
      python3 python3-dev python3-venv python3-pip pipx ripgrep rsync sqlite3 \
      unzip wget xz-utils zip zstd 7zip zlib1g-dev \
      fd-find tree shellcheck shfmt procps psmisc iproute2 dnsutils \
      netcat-openbsd lsof util-linux yq fontconfig fonts-liberation \
      fonts-noto-core fonts-noto-color-emoji \
    && ln -s /usr/bin/fdfind /usr/local/bin/fd \
    && rm -rf /var/lib/apt/lists/*

COPY --from=docker-cli /usr/local/bin/docker /usr/local/bin/docker
COPY --from=docker-cli /usr/local/libexec/docker/cli-plugins/ /usr/local/libexec/docker/cli-plugins/
COPY versions.env /opt/toolchain/versions.env
COPY --chmod=0755 install-forge-cli.sh install-image-tools.sh /usr/local/bin/
RUN /usr/local/bin/install-image-tools.sh
COPY --chmod=0755 install-flutter.sh /usr/local/bin/
COPY --chmod=0755 provision-tools.sh /usr/local/bin/provision-tools

ENV HOME=/home/node \
    T3CODE_HOME=/home/node/.t3 \
    T3CODE_HOST=127.0.0.1 \
    T3CODE_PORT=3773 \
    T3CODE_NO_BROWSER=true \
    T3CODE_TELEMETRY_ENABLED=false \
    T3CODE_SERVER_BROWSER_SANDBOX=0 \
    NPM_CONFIG_PREFIX=/home/node/.local \
    N_PREFIX=/home/node/.local \
    COREPACK_HOME=/home/node/.cache/corepack \
    DOTNET_ROOT=/opt/dotnet \
    DOTNET_CLI_TELEMETRY_OPTOUT=1 \
    FLUTTER_ROOT=/opt/flutter \
    PUB_CACHE=/home/node/.cache/pub \
    PATH="/home/node/.local/bin:/home/node/.dotnet/tools:/opt/tools/current/python/bin:/opt/tools/current/harnesses/bin:/opt/agent-tools/bin:/opt/flutter/bin:/opt/dotnet:${PATH}"

COPY --chmod=0755 t3-entrypoint.sh /usr/local/bin/t3
COPY --chmod=0755 setup-tools.sh /usr/local/bin/setup-tools
COPY --chmod=0755 check-tools.sh /usr/local/bin/check-tools
RUN ln -s /usr/local/bin/install-forge-cli.sh /usr/local/bin/install-forge-cli \
    && mkdir -p /workspace/repos /workspace/worktrees /home/node/.t3 /opt/tools \
      /home/node/.local/bin /home/node/.cache \
    && ln -s /opt/tools/current/dotnet /opt/dotnet \
    && ln -s /opt/tools/current/flutter /opt/flutter \
    && ln -s /opt/tools/current/tool-versions.txt /opt/toolchain/tool-versions.txt \
    && ln -s /workspace/worktrees /home/node/.t3/worktrees \
    && git config --system --add safe.directory /opt/flutter \
    && git lfs install --system \
    && printf "export PATH='%s'\n" "$PATH" > /etc/profile.d/toolchain-path.sh \
    && chown -R node:node /workspace /home/node /opt/tools

USER node
WORKDIR /workspace
ENTRYPOINT ["t3"]
CMD []
