FROM node:22-bookworm

RUN apt-get update && apt-get install -y \
    wget \
    curl \
    gnupg2 \
    sudo \
    nano \
    && rm -rf /var/lib/{apt,dpkg,cache,log}/

RUN curl -fsSL https://openclaw.ai/install.sh | bash -s -- --no-onboard

RUN apt-get clean autoclean && \
    apt-get autoremove --yes && \
    rm -rf /var/lib/{apt,dpkg,cache,log}/

RUN groupadd -g 1000 coder && \
    useradd -m -u 1000 -g 1000 -s /bin/bash coder && \
    echo 'coder ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/coder && \
    chmod 0440 /etc/sudoers.d/coder && \
    usermod -aG sudo coder

# 复制自定义启动脚本
COPY start.sh /app/
RUN chmod +x /app/start.sh

ENTRYPOINT ["/app/start.sh"]
