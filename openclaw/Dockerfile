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

# 复制自定义启动脚本
COPY start.sh /app/
RUN chmod +x /app/start.sh

ENTRYPOINT ["/app/start.sh"]
