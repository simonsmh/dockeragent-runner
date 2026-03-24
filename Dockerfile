FROM node:lts-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    git \
    jq \
    openssh-client \
    python3 \
    python3-pip \
    ripgrep \
    curl \
    ca-certificates \
    unzip \
    zip \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g playwright \
    && npx playwright install --with-deps chromium

RUN sed -i 's|deb.debian.org|mirrors.aliyun.com|g' /etc/apt/sources.list.d/debian.sources \
    && sed -i 's|security.debian.org/debian-security|mirrors.aliyun.com/debian-security|g' /etc/apt/sources.list.d/debian.sources

ENV PIP_INDEX_URL=https://mirrors.aliyun.com/pypi/simple/ \
    PIP_TRUSTED_HOST=mirrors.aliyun.com \
    UV_INDEX_URL=https://mirrors.aliyun.com/pypi/simple/ \
    PLAYWRIGHT_BROWSERS_PATH=/opt/playwright

RUN curl --proto '=https' --tlsv1.2 -LsSf https://releases.astral.sh/github/uv/releases/download/0.11.0/uv-installer.sh | sh \
    && curl https://cursor.com/install -fsS | bash \
    && curl -fsSL https://qoder.com/install | bash \
    && curl -fsSL https://claude.ai/install.sh | bash \
    && npm install -g @zed-industries/claude-agent-acp \
    && mv /root/.local /opt/local \
    && mv /root/.qoder /opt/qoder \
    && ln -sf /opt/local/share/cursor-agent/versions/*/cursor-agent /usr/local/bin/agent \
    && ln -sf /opt/qoder/bin/qodercli/qodercli-* /usr/local/bin/qodercli \
    && ln -sf /opt/qoder/bin/ripgrep/rg /usr/local/bin/rg \
    && ln -sf /opt/local/share/claude/versions/* /usr/local/bin/claude \
    && ln -sf /opt/local/bin/uv /usr/local/bin/uv \
    && ln -sf /opt/local/bin/uvx /usr/local/bin/uvx
