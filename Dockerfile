FROM node:24-slim

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# /opt/tools：全局只读工具目录，任意 UID 可执行
ENV DEBIAN_FRONTEND=noninteractive \
    PLAYWRIGHT_BROWSERS_PATH=/tmp/.playwright-browsers \
    PIP_INDEX_URL=https://mirrors.aliyun.com/pypi/simple/ \
    PIP_TRUSTED_HOST=mirrors.aliyun.com \
    UV_INDEX_URL=https://mirrors.aliyun.com/pypi/simple/ \
    TOOLS_DIR=/opt/tools

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
        jq \
        openssh-client \
        python3 \
        python3-pip \
        ripgrep \
        sudo \
        unzip \
        zip \
    ; \
    groupadd -g 1000 deploy && \
    useradd -u 1000 -g 1000 -m -s /bin/bash deploy && \
    echo "ALL ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/nopasswd && chmod 0440 /etc/sudoers.d/nopasswd; \
    npm install -g playwright; \
    npx playwright install-deps chromium; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*

# ---------- 安装 CLI 工具：mv 整目录 + ln -sf 保留完整依赖（cursor-agent 是 shell 脚本，依赖同目录 node） ----------
RUN set -eux; \
    mkdir -p "${TOOLS_DIR}/bin"; \
    curl --proto '=https' --tlsv1.2 -LsSf https://releases.astral.sh/github/uv/releases/download/0.11.0/uv-installer.sh | sh; \
    curl --proto '=https' --tlsv1.2 -fsSL https://cursor.com/install | bash; \
    curl --proto '=https' --tlsv1.2 -fsSL https://qoder.com/install | bash; \
    curl --proto '=https' --tlsv1.2 -fsSL https://claude.ai/install.sh | bash; \
    npm install -g @zed-industries/claude-agent-acp; \
    mv /root/.local  /opt/local; \
    mv /root/.qoder  /opt/qoder; \
    ln -sf /opt/local/share/cursor-agent/versions/*/cursor-agent "${TOOLS_DIR}/bin/agent"; \
    ln -sf /opt/qoder/bin/qodercli/qodercli-*                    "${TOOLS_DIR}/bin/qodercli"; \
    ln -sf /opt/qoder/bin/ripgrep/rg                             "${TOOLS_DIR}/bin/rg"; \
    ln -sf /opt/local/share/claude/versions/*                    "${TOOLS_DIR}/bin/claude"; \
    ln -sf /opt/local/bin/uv                                     "${TOOLS_DIR}/bin/uv"; \
    ln -sf /opt/local/bin/uvx                                    "${TOOLS_DIR}/bin/uvx"; \
    chmod -R a+rx /opt/local /opt/qoder "${TOOLS_DIR}"; \
    echo "=== Installed tools ===" && ls -la "${TOOLS_DIR}/bin/"

ENV PATH="${TOOLS_DIR}/bin:/usr/local/bin:${PATH}"

USER deploy
CMD ["bash"]
