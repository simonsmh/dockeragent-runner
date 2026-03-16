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

RUN curl https://cursor.com/install -fsS | bash \
    && curl -fsSL https://qoder.com/install | bash \
    && curl -fsSL https://claude.ai/install.sh | bash \
    && mv /root/.local /opt/local \
    && mv /root/.qoder /opt/qoder \
    && ln -sf /opt/local/share/cursor-agent/versions/*/cursor-agent /usr/local/bin/agent \
    && ln -sf /opt/qoder/bin/qodercli/qodercli-* /usr/local/bin/qodercli \
    && ln -sf /opt/qoder/bin/ripgrep/rg /usr/local/bin/rg \
    && ln -sf /opt/local/share/claude/versions/* /usr/local/bin/claude
