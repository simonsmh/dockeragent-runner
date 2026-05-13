#!/usr/bin/env bash
# 生成环境说明文档，供 AI agent 启动时了解可用工具
set -euo pipefail

README="${WARMUP_HOME}/.warmup/README.md"
mkdir -p "$(dirname "${README}")"

cat > "${README}" << 'EOF'
# Agent Runtime Environment

This document describes the pre-installed tools and packages available in this environment.

## System Tools (apt)

- `curl`, `wget` — HTTP 下载
- `git` — 版本控制
- `jq` — JSON 处理
- `ripgrep` (`rg`) — 高速文本搜索
- `ffmpeg` — 音视频处理
- `python3`, `python3-pip`, `python3-venv` — Python 运行时
- `xvfb` — 虚拟显示（无头 GUI）
- `unzip`, `zip` — 压缩解压
- `openssh-client` — SSH 客户端
- `poppler-utils` — PDF 工具（pdftotext 等）（如已安装）

## Node.js Global Packages (npm -g)

- `playwright` — 浏览器自动化
- `@anthropic-ai/claude-code` — Claude Code CLI
- `@zed-industries/claude-agent-acp` — Zed Claude Agent
- `@mariozechner/pi-coding-agent` / `pi-acp` / `pi-mcp-adapter` — Pi coding agent

## Python Packages (pip)

- `Pillow` — 图片处理
- `opencv-python-headless` — 计算机视觉
- `pandas`, `numpy` — 数据处理
- `openpyxl` — Excel 读写
- `python-docx` — Word 文档读写
- `python-pptx` — PowerPoint 读写
- `pypdf` — PDF 解析
- `requests` — HTTP 客户端
- `beautifulsoup4`, `lxml` — HTML/XML 解析

## CLI Tools (~/.local/bin)

- `uv` — Python 包管理器（pip 替代）
- `kiro-cli` — Kiro AI agent CLI
- `qodercli` — Qoder AI agent CLI
- `agent` (cursor) — Cursor AI agent CLI

## Browsers

- Chromium（via Playwright，路径：`~/.playwright-browsers/`）
- Google Chrome（amd64 only）
- Camoufox（反指纹浏览器，via `python3 -m camoufox`）
- 浏览器自动化推荐直接使用 `npx playwright`

## Notes

- Python 包通过 `uv pip install --system` 安装，可直接 `import` 使用
- 新增 Python 包推荐用 `uv pip install <pkg>`
- 当前用户（node）已配置 `sudo` 免密，可执行需要 root 权限的操作
- 运行时基于 `node:24`，可直接使用 `node`、`npm`、`npx`
EOF

echo "[readme] written to ${README}"
cat "${README}"
