FROM debian:latest

RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    && mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list \
    && apt-get update \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y \
    wget \
    curl \
    gnupg2 \
    sudo \
    nano \
    && rm -rf /var/lib/{apt,dpkg,cache,log}/

RUN npm install -g opencode-ai

RUN apt-get clean autoclean && \
    apt-get autoremove --yes && \
    rm -rf /var/lib/{apt,dpkg,cache,log}/

COPY start.sh /app/

RUN chmod +x /app/start.sh

RUN groupadd -g 1000 opencodeuser && \
    useradd -m -u 1000 -g 1000 -s /bin/bash opencodeuser && \
    echo 'opencodeuser ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/opencodeuser && \
    chmod 0440 /etc/sudoers.d/opencodeuser && \
    usermod -aG sudo opencodeuser

ENV HOME=/home/opencodeuser

ENTRYPOINT ["/app/start.sh"]
