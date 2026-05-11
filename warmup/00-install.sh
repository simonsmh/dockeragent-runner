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

# 设置 kiro-cli 默认模型（写入 ~/.kiro/settings/cli.json）
# 原来在运行时通过 docker exec 执行，但容器启动时 OCI exec 可能失败，改为构建时预置
echo "[install] configuring kiro-cli default model..."
kiro-cli settings chat.defaultModel glm-5 || echo "[install] kiro-cli settings failed (non-fatal)"

# qodercli
echo "[install] installing qodercli..."
curl -fsSL https://qoder.com/install | bash

echo "[install] installed tools:"
ls -la "${HOME}/.local/bin/"
