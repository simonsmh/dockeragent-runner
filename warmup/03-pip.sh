#!/usr/bin/env bash
# 预装常用 Python 包（通过 uv，安装到系统级）
# 依赖 02-install.sh 已安装 uv
set -euo pipefail

echo "[pip] installing Python packages..."
sudo env PATH="${PATH}" uv pip install --system \
    Pillow \
    opencv-python-headless \
    pandas \
    numpy \
    openpyxl \
    python-docx \
    pypdf \
    requests \
    beautifulsoup4 \
    lxml \
    camoufox \
    python-pptx

echo "[pip] done"
sudo env PATH="${PATH}" uv pip list --system 2>/dev/null || true
