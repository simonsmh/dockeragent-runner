#!/usr/bin/env bash
# 按序号执行所有 warmup 脚本，单个失败不中断整体构建
set -u

WARMUP_DIR="$(dirname "$0")"
mkdir -p "${WARMUP_HOME}/.warmup"

# 确保安装后的工具在 PATH 里（00-install.sh 安装到 $HOME/.local/bin）
export PATH="${WARMUP_HOME}/.local/bin:${PATH}"

for script in "${WARMUP_DIR}"/[0-9][0-9]-*.sh; do
    [ -f "$script" ] || continue
    echo "[warmup] running ${script}"
    "${script}" || echo "[warmup] ${script} failed (non-fatal), continuing"
done

# 写版本戳：entrypoint 用它判断是否需要同步到 workspace
date -u +%Y%m%d%H%M%S > "${WARMUP_HOME}/.warmup/version"
echo "[warmup] done, version=$(cat "${WARMUP_HOME}/.warmup/version")"
