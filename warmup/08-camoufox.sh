#!/usr/bin/env bash
# 预装 camoufox 浏览器到 WARMUP_HOME
# 依赖 03-pip.sh 已安装 camoufox
set -euo pipefail

echo "[camoufox] fetching camoufox browser..."
python3 -m camoufox fetch

echo "[camoufox] done"
python3 -m camoufox --version 2>/dev/null || true
