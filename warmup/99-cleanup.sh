#!/usr/bin/env bash
# 清理 warmup 过程中产生的缓存和临时文件，减小镜像体积
set -euo pipefail

echo "[cleanup] cleaning apt cache..."
sudo apt-get clean
sudo rm -rf /var/lib/apt/lists/*

echo "[cleanup] cleaning npm cache..."
sudo npm cache clean --force 2>/dev/null || true
sudo rm -rf /root/.npm 2>/dev/null || true

echo "[cleanup] cleaning uv/pip cache..."
rm -rf "${HOME}/.cache/uv" "${HOME}/.cache/pip" 2>/dev/null || true

echo "[cleanup] cleaning root cache..."
sudo rm -rf /root/.cache 2>/dev/null || true

echo "[cleanup] done"
