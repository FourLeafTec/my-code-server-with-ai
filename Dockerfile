FROM debian:bookworm-slim

ARG TARGETARCH
ARG TARGETVARIANT

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    wget \
    git \
    sudo \
    nano \
    vim \
    unzip \
    ssh \
    tzdata \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_24.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list \
    && apt-get update \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

RUN ARCH=$(dpkg --print-architecture) && \
    if [ "$TARGETARCH" = "amd64" ] || [ "$ARCH" = "amd64" ]; then \
    echo "Installing VS Code for amd64..." && \
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /tmp/packages.microsoft.gpg && \
    install -o root -g root -m 644 /tmp/packages.microsoft.gpg /etc/apt/trusted.gpg.d/ && \
    echo "deb [arch=amd64 signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list && \
    rm /tmp/packages.microsoft.gpg && \
    apt-get update && apt-get install -y code && rm -rf /var/lib/apt/lists/*; \
    elif [ "$TARGETARCH" = "arm64" ] || [ "$ARCH" = "arm64" ]; then \
    echo "Installing VS Code for arm64..." && \
    wget https://aka.ms/linux-arm64-deb -O /tmp/vscode-arm64.deb && \
    apt-get update && apt-get install -y /tmp/vscode-arm64.deb && \
    rm /tmp/vscode-arm64.deb && rm -rf /var/lib/apt/lists/*; \
    fi

RUN npm install -g opencode-ai
RUN npx oh-my-opencode install --no-tui --claude=no --gemini=no --copilot=no

RUN curl -fsSL https://openclaw.ai/install-cli.sh | bash -s -- --prefix /usr/local/openclaw --no-onboard

RUN apt-get update && apt-get install -y \
    dumb-init \
    curl \
    && rm -rf /var/lib/apt/lists/*

RUN sh -c "$(curl --location https://raw.githubusercontent.com/F1bonacc1/process-compose/main/scripts/get-pc.sh)" -- -d -b /usr/local/bin && \
    chmod +x /usr/local/bin/process-compose

RUN groupadd -g 1000 coder && \
    useradd -m -u 1000 -g 1000 -s /bin/bash coder && \
    echo 'coder ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/coder && \
    chmod 0440 /etc/sudoers.d/coder && \
    usermod -aG sudo coder

COPY --chown=coder:coder process-compose.yaml /app/process-compose.yaml
COPY --chown=coder:coder start.sh /app/start.sh
COPY --chown=coder:coder fix-cdn-proxy.sh /app/fix-cdn-proxy.sh
RUN chmod +x /app/start.sh /app/fix-cdn-proxy.sh /usr/local/bin/process-compose

ENV HOME=/home/coder
ENV PATH="/usr/local/openclaw/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

USER root

ENTRYPOINT ["/app/start.sh"]
