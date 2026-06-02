#!/usr/bin/env bash
# 安装所有 AI agent CLI 工具到 $WARMUP_HOME/.local/
# 所有安装脚本都遵循 $HOME/.local 约定，设置 HOME=/opt/home 即可直接安装到目标位置
set -euo pipefail

echo "[install] HOME=${HOME} (should be ${WARMUP_HOME})"
mkdir -p "${HOME}/.local/bin"

# uv（Python 包管理器）
echo "[install] installing uv..."
curl --proto '=https' --tlsv1.2 -LsSf https://astral.sh/uv/install.sh | sh

# cursor agent
echo "[install] installing cursor agent..."
curl -fsSL https://cursor.com/install | bash

# kiro-cli
echo "[install] installing kiro-cli..."
curl -fsSL https://cli.kiro.dev/install | bash

# qodercli
echo "[install] installing qodercli..."
curl -fsSL https://qoder.com/install | bash


# pi
sudo HOME="/home/node" pi install npm:pi-provider-env
sudo HOME="/home/node" pi install npm:pi-mcp-adapter
sudo HOME="/home/node" pi install npm:pi-web-access
sudo HOME="/home/node" pi install npm:context-mode

# Configure settings.json to optimize startup and suppress redundant warnings/telemetry
SETTINGS_FILE="/home/node/.pi/agent/settings.json"
if [ -f "$SETTINGS_FILE" ]; then
    echo "[warmup/pi] optimizing settings.json..."
    sudo jq '.quietStartup = true | .enableInstallTelemetry = false | .warnings.anthropicExtraUsage = false' "$SETTINGS_FILE" > /tmp/settings.json.tmp
    sudo mv /tmp/settings.json.tmp "$SETTINGS_FILE"
fi

sudo chown -R node:node "/home/node/.pi"

echo "[install] installed tools:"
ls -la "${HOME}/.local/bin/"
