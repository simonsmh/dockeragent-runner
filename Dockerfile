FROM node:24-slim

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# /opt/tools：全局只读工具目录，任意 UID 可执行
ENV DEBIAN_FRONTEND=noninteractive \
    PLAYWRIGHT_BROWSERS_PATH=/tmp/.playwright-browsers \
    PIP_INDEX_URL=https://mirrors.aliyun.com/pypi/simple/ \
    PIP_TRUSTED_HOST=mirrors.aliyun.com \
    UV_INDEX_URL=https://mirrors.aliyun.com/pypi/simple/ \
    npm_config_registry=https://registry.npmmirror.com \
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
    echo "ALL ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/nopasswd && chmod 0440 /etc/sudoers.d/nopasswd; \
    npm install -g playwright; \
    npm install -g @anthropic-ai/claude-code; \
    npm install -g @zed-industries/claude-agent-acp; \
    npm install -g @mariozechner/pi-coding-agent; \
    npm install -g pi-acp; \
    npm install -g pi-mcp-adapter; \
    npm cache clean --force; \
    npx playwright install-deps chromium

RUN set -eux; \
    mkdir -p "${TOOLS_DIR}"; \
    curl --proto '=https' --tlsv1.2 -LsSf https://astral.sh/uv/install.sh | sh; \
    curl -fsSL https://cursor.com/install | bash; \
    curl -fsSL https://cli.kiro.dev/install | bash; \
    curl -fsSL https://qoder.com/install | bash

# ---------- 迁移到全局目录 + 修复符号链接 ----------
RUN set -eux; \
    # 1) 搬迁 .local（uv、cursor-agent、qodercli 的软链都在这里）
    mv /root/.local "${TOOLS_DIR}/.local"; \
    \
    # 2) 搬迁 .qoder（版本化存储 ~/.qoder/bin/qodercli/qodercli-*）
    if [ -d /root/.qoder ]; then \
        mv /root/.qoder "${TOOLS_DIR}/.qoder"; \
    fi; \
    \
    # 3) 修复 qodercli 符号链接（把 /root 路径替换为 ${TOOLS_DIR}）
    if [ -L "${TOOLS_DIR}/.local/bin/qodercli" ]; then \
        old_target=$(readlink "${TOOLS_DIR}/.local/bin/qodercli"); \
        new_target="${old_target//\/root/${TOOLS_DIR}}"; \
        ln -sf "${new_target}" "${TOOLS_DIR}/.local/bin/qodercli"; \
        echo "Fixed qodercli symlink: ${old_target} -> ${new_target}"; \
    fi; \
    \
    # 4) 修复其他可能存在的 qoder 相关符号链接
    find "${TOOLS_DIR}/.local/bin/" -lname '/root/*' -print0 2>/dev/null | while IFS= read -r -d '' link; do \
        old=$(readlink "$link"); \
        new="${old//\/root/${TOOLS_DIR}}"; \
        ln -sf "$new" "$link"; \
        echo "Fixed symlink: $link  $old -> $new"; \
    done; \
    \
    # 5) cursor-agent 符号链接
    ln -sf "${TOOLS_DIR}/.local/share/cursor-agent/versions"/*/cursor-agent "${TOOLS_DIR}/.local/bin/agent"; \
    ln -sf "${TOOLS_DIR}/.local/share/cursor-agent/versions"/*/cursor-agent "${TOOLS_DIR}/.local/bin/cursor-agent"; \
    # 6) 全局可读可执行
    chmod -R a+rX "${TOOLS_DIR}"; \
    echo "=== Installed tools ==="; \
    ls -la "${TOOLS_DIR}/.local/bin/"

RUN apt-get clean 2>/dev/null; \
    rm -rf /var/lib/apt/lists/* /tmp/* /root/.cache /root/.npm

ENV PATH="${TOOLS_DIR}/.local/bin:${PATH}"

USER 1000:1000
CMD ["bash"]
