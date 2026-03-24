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
