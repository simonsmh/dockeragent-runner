#!/usr/bin/env bash
# 全局安装 npm 包（需要 root 权限）
set -euo pipefail

echo "[npm] installing global packages..."
sudo npm install -g \
    playwright \
    @anthropic-ai/claude-code \
    @zed-industries/claude-agent-acp \
    @mariozechner/pi-coding-agent \
    pi-acp

echo "[npm] pre-installing pi extensions..."
sudo pi install npm:pi-provider-env
sudo pi install npm:pi-mcp-adapter

echo "[npm] done"
npm list -g --depth=0 2>/dev/null || true
