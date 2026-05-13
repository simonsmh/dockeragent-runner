#!/usr/bin/env bash
# 预装 Playwright chromium 浏览器到 $WARMUP_HOME/.playwright-browsers/
# 运行时 entrypoint 同步到 /home/node/.playwright-browsers/
set -euo pipefail

MCP_PACKAGE="${PLAYWRIGHT_MCP_PACKAGE:-@playwright/mcp@0.0.70}"
BROWSERS_DIR="${WARMUP_HOME}/.playwright-browsers"
export PLAYWRIGHT_BROWSERS_PATH="${BROWSERS_DIR}"

echo "[warmup/playwright] installing system deps for chromium..."
sudo npx playwright install-deps chromium

echo "[warmup/playwright] installing chromium via ${MCP_PACKAGE}"
mkdir -p "${BROWSERS_DIR}"

# 从 MCP 包解析 playwright 版本，保证浏览器版本与 MCP 一致
MCP_PW_VERSION="$(npm view "${MCP_PACKAGE}" dependencies.playwright 2>/dev/null | tr -d "\"'[:space:]")"
if [ -n "${MCP_PW_VERSION}" ] && [ "${MCP_PW_VERSION}" != "undefined" ] && [ "${MCP_PW_VERSION}" != "null" ]; then
    echo "[warmup/playwright] playwright version from MCP: ${MCP_PW_VERSION}"
    npx -y -p "playwright@${MCP_PW_VERSION}" playwright install chromium
else
    echo "[warmup/playwright] could not resolve playwright version from MCP, using bundled"
    npx playwright install chromium
fi

# 创建 -current 软链，供 PLAYWRIGHT_MCP_EXECUTABLE_PATH 使用
for prefix in chromium chromium_headless_shell; do
    latest=$(ls -d "${BROWSERS_DIR}/${prefix}"-[0-9]* 2>/dev/null | sort -t- -k2,2n | tail -1 || true)
    if [ -n "$latest" ]; then
        ln -sfn "$(basename "$latest")" "${BROWSERS_DIR}/${prefix}-current"
        echo "[warmup/playwright] symlink: ${prefix}-current -> $(basename "$latest")"
    fi
done

# 稳定入口：playwright-headless-shell
HEADLESS_CURRENT="${BROWSERS_DIR}/chromium_headless_shell-current"
if [ -d "${HEADLESS_CURRENT}" ]; then
    for candidate in \
        "chrome-headless-shell-linux64/chrome-headless-shell" \
        "chrome-linux/headless_shell"
    do
        if [ -e "${HEADLESS_CURRENT}/${candidate}" ]; then
            ln -sfn "${candidate}" "${HEADLESS_CURRENT}/playwright-headless-shell"
            echo "[warmup/playwright] stable entry: playwright-headless-shell -> ${candidate}"
            break
        fi
    done

    # 兼容入口
    if [ ! -e "${HEADLESS_CURRENT}/chrome-linux/headless_shell" ] \
        && [ -e "${HEADLESS_CURRENT}/chrome-headless-shell-linux64/chrome-headless-shell" ]; then
        mkdir -p "${HEADLESS_CURRENT}/chrome-linux"
        ln -sfn "../chrome-headless-shell-linux64/chrome-headless-shell" \
            "${HEADLESS_CURRENT}/chrome-linux/headless_shell"
        echo "[warmup/playwright] compat entry: chrome-linux/headless_shell"
    fi
fi

echo "[warmup/playwright] done"
ls -lh "${BROWSERS_DIR}/" 2>/dev/null || true
