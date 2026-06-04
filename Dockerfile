FROM node:24

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV DEBIAN_FRONTEND=noninteractive \
    PLAYWRIGHT_BROWSERS_PATH=/opt/home/.playwright-browsers \
    PIP_INDEX_URL=https://mirrors.aliyun.com/pypi/simple/ \
    PIP_TRUSTED_HOST=mirrors.aliyun.com \
    UV_INDEX_URL=https://mirrors.aliyun.com/pypi/simple/ \
    npm_config_registry=https://registry.npmmirror.com \
    WARMUP_HOME=/opt/home

# === [ROOT] 系统依赖 + Google Chrome ===
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
        ffmpeg \
        fonts-liberation \
        fd-find \
        jq \
        libasound2 \
        libatk-bridge2.0-0 \
        libatk1.0-0 \
        libcups2 \
        libdbus-1-3 \
        libgdk-pixbuf2.0-0 \
        libgtk-3-0 \
        libnspr4 \
        libnss3 \
        libx11-xcb1 \
        libxcomposite1 \
        libxdamage1 \
        libxrandr2 \
        poppler-utils \
        python3-venv \
        ripgrep \
        sudo \
        xdg-utils \
        xvfb \
        zip \
    ; \
    echo "ALL ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/nopasswd && chmod 0440 /etc/sudoers.d/nopasswd; \
    ARCH="$(dpkg --print-architecture)"; \
    if [ "${ARCH}" = "amd64" ]; then \
        wget -q -O /tmp/google-chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb; \
        apt-get install -y --no-install-recommends /tmp/google-chrome.deb; \
        rm -f /tmp/google-chrome.deb; \
    else \
        echo "Skipping Google Chrome on ${ARCH}"; \
    fi; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*; \
    mkdir -p "${WARMUP_HOME}" && chown 1000:1000 "${WARMUP_HOME}"

# === [ROOT] 拷贝 warmup 脚本并赋权 ===
COPY --chmod=755 warmup/ /opt/warmup/

ARG KIRO_API_KEY
ARG QODER_PERSONAL_ACCESS_TOKEN
ARG CURSOR_API_KEY

# === [USER node] 以 uid=1000 执行预热 ===
# 原因：
# 1) 工具安装到 $HOME/.local/，HOME 内联为 /opt/home（已 chown 1000），直接可写
# 2) qodercli 在 /tmp 创建 native 临时文件，uid 必须和运行时一致（都是 1000），
#    否则运行时 rename() 会 EPERM（sticky bit + root owner 不匹配）
# 3) kiro-cli/qodercli/cursor 的配置目录以当前 uid 落盘，和运行时对齐
# 注意：用 HOME=... RUN 内联而非 ENV HOME，避免全局污染运行时 HOME
USER node
RUN set -eux; \
    export HOME="${WARMUP_HOME}"; \
    export PATH="${WARMUP_HOME}/.local/bin:${WARMUP_HOME}/.qoder/.bin:${PATH}"; \
    KIRO_API_KEY="${KIRO_API_KEY:-}" \
    QODER_PERSONAL_ACCESS_TOKEN="${QODER_PERSONAL_ACCESS_TOKEN:-}" \
    CURSOR_API_KEY="${CURSOR_API_KEY:-}" \
    /opt/warmup/run-all.sh; \
    echo "=== /opt/home/.local/bin ==="; \
    ls -la "${WARMUP_HOME}/.local/bin/" 2>/dev/null || true; \
    echo "=== /opt/home (top-level) ==="; \
    ls -la "${WARMUP_HOME}/"

# === [ROOT] entrypoint 安装 ===
# /usr/local/bin/ 只有 root 可写
USER root
ENV PATH="${WARMUP_HOME}/.local/bin:${PATH}"
COPY --chmod=755 entrypoint.sh /usr/local/bin/entrypoint.sh

# === [USER node] 声明默认运行用户 ===
# 双保险：docker run 不带 --user 时也是 1000；符合最小权限原则
USER node
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["bash"]
