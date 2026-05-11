FROM node:24-slim

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# /opt/home：预热产物目录（工具二进制 + 模型缓存），容器首次启动时 entrypoint 同步到 /home/node
ENV DEBIAN_FRONTEND=noninteractive \
    PLAYWRIGHT_BROWSERS_PATH=/tmp/.playwright-browsers \
    PIP_INDEX_URL=https://mirrors.aliyun.com/pypi/simple/ \
    PIP_TRUSTED_HOST=mirrors.aliyun.com \
    UV_INDEX_URL=https://mirrors.aliyun.com/pypi/simple/ \
    npm_config_registry=https://registry.npmmirror.com \
    WARMUP_HOME=/opt/home

# ---------- 系统依赖 + Playwright ----------
RUN set -eux; \
    if [ -f /etc/apt/sources.list.d/debian.sources ]; then \
        sed -i 's|deb.debian.org|mirrors.aliyun.com|g' /etc/apt/sources.list.d/debian.sources; \
        sed -i 's|security.debian.org/debian-security|mirrors.aliyun.com/debian-security|g' /etc/apt/sources.list.d/debian.sources; \
    elif [ -f /etc/apt/sources.list ]; then \
        sed -i 's|deb.debian.org|mirrors.aliyun.com|g' /etc/apt/sources.list; \
        sed -i 's|security.debian.org|mirrors.aliyun.com|g' /etc/apt/sources.list; \
    fi; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        bash \
        ca-certificates \
        curl \
        ffmpeg \
        git \
        gosu \
        jq \
        openssh-client \
        python3 \
        python3-pip \
        ripgrep \
        sudo \
        unzip \
        zip \
    ; \
    echo "ALL ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/nopasswd && chmod 0440 /etc/sudoers.d/nopasswd; \
    npm install -g playwright; \
    npm install -g @anthropic-ai/claude-code; \
    npm install -g @zed-industries/claude-agent-acp; \
    npm install -g @mariozechner/pi-coding-agent; \
    npm install -g pi-acp; \
    npm install -g pi-mcp-adapter; \
    npm cache clean --force; \
    npx playwright install-deps chromium; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/* /tmp/* /root/.cache /root/.npm

# ---------- warmup 脚本 ----------
COPY warmup/ /opt/warmup/
RUN chmod +x /opt/warmup/*.sh

# ---------- 安装 + 预热 ----------
# 00-install.sh：以 HOME=/opt/home 安装 uv / cursor / kiro-cli / qodercli
#   → 工具二进制落到 /opt/home/.local/bin/，无需 TOOLS_DIR 和 symlink 修复
# 01-kiro.sh：触发 session/new 下载 all-MiniLM-L6-v2 语义搜索模型（~91MB）
# 02-qoder.sh / 03-cursor.sh：触发各工具首次初始化
# 单个脚本失败不中断整体构建（run-all.sh 内部 || true）
ARG KIRO_API_KEY
ARG QODER_PERSONAL_ACCESS_TOKEN
ARG CURSOR_API_KEY

RUN set -eux; \
    mkdir -p "${WARMUP_HOME}"; \
    KIRO_API_KEY="${KIRO_API_KEY:-}" \
    QODER_PERSONAL_ACCESS_TOKEN="${QODER_PERSONAL_ACCESS_TOKEN:-}" \
    CURSOR_API_KEY="${CURSOR_API_KEY:-}" \
    HOME="${WARMUP_HOME}" \
    PATH="${WARMUP_HOME}/.local/bin:${PATH}" \
    /opt/warmup/run-all.sh; \
    echo "=== /opt/home/.local/bin ==="; \
    ls -la "${WARMUP_HOME}/.local/bin/" 2>/dev/null || true; \
    echo "=== /opt/home (top-level) ==="; \
    ls -la "${WARMUP_HOME}/" 2>/dev/null || true; \
    # warmup 以 root 执行，把产物 owner 改成 node(1000)，
    # entrypoint cp 过来后 node 用户可直接读写，无需再 chown
    chown -R 1000:1000 "${WARMUP_HOME}"

ENV PATH="${WARMUP_HOME}/.local/bin:${PATH}"

# ---------- Entrypoint：首次启动时同步 /opt/home → /home/node ----------
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

USER 1000:1000
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["bash"]
