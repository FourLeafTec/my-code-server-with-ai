FROM node:22-bookworm

RUN apt-get update && apt-get install -y \
    wget \
    curl \
    gnupg2 \
    sudo \
    gosu \
    nano \
    && rm -rf /var/lib/{apt,dpkg,cache,log}/

# node 用户已经有 UID 1000 和 GID 1000，直接重命名为 coder
RUN usermod -l coder node && \
    groupmod -n coder node && \
    usermod -d /home/coder -m coder && \
    echo 'coder ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/coder && \
    chmod 0440 /etc/sudoers.d/coder && \
    usermod -aG sudo coder

USER coder
RUN curl -fsSL https://openclaw.ai/install.sh | bash -s -- --no-onboard

USER root
RUN apt-get clean autoclean && \
    apt-get autoremove --yes && \
    rm -rf /var/lib/{apt,dpkg,cache,log}/

# 复制自定义启动脚本并设置所有权
COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh && \
    chown coder:coder /app/start.sh

# ENTRYPOINT以root用户启动，start.sh内部使用gosu切换到coder用户
USER root

ENTRYPOINT ["/app/start.sh"]
