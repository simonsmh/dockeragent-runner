FROM node:24-slim

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# /opt/tools：全局只读工具目录，任意 UID 可执行
ENV DEBIAN_FRONTEND=noninteractive \
    PLAYWRIGHT_BROWSERS_PATH=/opt/playwright-browsers \
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
        unzip \
        zip \
    ; \
    npm install -g playwright; \
    npx playwright install-deps chromium; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*

# ---------- 安装 CLI 工具，二进制 cp 到 /opt/tools/bin（不依赖运行时 HOME） ----------
RUN set -eux; \
    BUILD_HOME="/tmp/build-home"; \
    mkdir -p "${TOOLS_DIR}/bin" "${BUILD_HOME}"; \
    export HOME="${BUILD_HOME}"; \
    export XDG_DATA_HOME="${BUILD_HOME}/.local/share"; \
    export CARGO_HOME="${BUILD_HOME}/.cargo"; \
    curl --proto '=https' --tlsv1.2 -LsSf https://releases.astral.sh/github/uv/releases/download/0.11.0/uv-installer.sh | sh; \
    cp "${BUILD_HOME}/.local/bin/uv" "${TOOLS_DIR}/bin/uv" 2>/dev/null \
        || cp "${BUILD_HOME}/.cargo/bin/uv" "${TOOLS_DIR}/bin/uv" 2>/dev/null \
        || true; \
    curl --proto '=https' --tlsv1.2 -fsSL https://cursor.com/install | bash; \
    curl --proto '=https' --tlsv1.2 -fsSL https://qoder.com/install | bash; \
    curl --proto '=https' --tlsv1.2 -fsSL https://claude.ai/install.sh | bash; \
    npm install -g @zed-industries/claude-agent-acp; \
    CURSOR_BIN="$(find "${BUILD_HOME}" -type f -name cursor-agent 2>/dev/null | sort -V | tail -n 1)"; \
    [ -n "$CURSOR_BIN" ] && cp "$CURSOR_BIN" "${TOOLS_DIR}/bin/agent"; \
    QODER_BIN="$(find "${BUILD_HOME}" -type f -name 'qodercli-*' 2>/dev/null | sort -V | tail -n 1)"; \
    [ -n "$QODER_BIN" ] && cp "$QODER_BIN" "${TOOLS_DIR}/bin/qodercli"; \
    CLAUDE_BIN="$(find "${BUILD_HOME}" -type f -name claude -o -name 'claude-*' 2>/dev/null | head -n 1)"; \
    [ -n "$CLAUDE_BIN" ] && cp "$CLAUDE_BIN" "${TOOLS_DIR}/bin/claude"; \
    chmod -R a+rwx "${TOOLS_DIR}"; \
    rm -rf "${BUILD_HOME}"; \
    echo "=== Installed tools ===" && ls -la "${TOOLS_DIR}/bin/"

ENV PATH="${TOOLS_DIR}/bin:/usr/local/bin:${PATH}"

CMD ["bash"]
