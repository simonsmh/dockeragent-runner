#!/usr/bin/env bash
# 全局安装 npm 包（需要 root 权限）
set -euo pipefail

echo "[npm] installing global packages..."
sudo npm install -g \
    playwright@latest \
    @anthropic-ai/claude-code@latest \
    @zed-industries/claude-agent-acp@latest \
    @mariozechner/pi-coding-agent@latest \
    pi-acp@latest

echo "[npm] done"
npm list -g --depth=0 2>/dev/null || true
