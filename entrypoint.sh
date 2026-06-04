#!/usr/bin/env bash
# entrypoint.sh
#
# 首次启动时把 /opt/home 的预热产物同步到 workspace（/home/node）。
# 用版本戳判断是否需要同步，支持镜像升级后增量补齐新文件。
#
# 设计原则：
# - 不覆盖用户已有文件（保护对话历史、用户配置）
# - 排除运行时目录（.cursor / .kiro / .qoder）
# - 版本戳最后写，保证中断时下次重试
# - 容器以 1000:1000 启动，无需降权
# - 不依赖 rsync，仅使用 tar

set -eu

WARMUP_SRC=/opt/home
WORKSPACE=/home/node

SRC_VER="$(cat "${WARMUP_SRC}/.warmup/version" 2>/dev/null || echo none)"
DST_VER="$(cat "${WORKSPACE}/.warmup/version" 2>/dev/null || echo none)"

if [ "${SRC_VER}" != "${DST_VER}" ]; then
    echo "[entrypoint] syncing warmup home: src_ver=${SRC_VER} dst_ver=${DST_VER}"

    # 使用 tar pipe 做增量同步：
    # - 保留文件属性
    # - 不覆盖用户已有文件
    # - 排除运行时目录
    # - 自动包含隐藏文件
    #
    # --skip-old-files:
    #   若目标文件已存在则跳过，保护用户数据
    tar \
        --exclude='./.cursor/acp-sessions' \
        --exclude='./.kiro' \
        --exclude='./.qoder/.bin' \
        --exclude='./.qoder/.auth' \
        --exclude='./.qoder/.models' \
        --exclude='./.qoder/logs' \
        --exclude='./.local/share/kiro-cli' \
        --exclude='./.npm' \
        --exclude='./.pi' \
        --exclude='./.warmup' \
        -C "${WARMUP_SRC}" \
        -cf - . \
    | tar \
        -C "${WORKSPACE}" \
        --skip-old-files \
        -xpf -

    # 强制保留 pi 的设置：启动时覆盖或同步 .pi 目录中的 settings/plugins 等配置，至少保留 opt 对应的配置
    if [ -d "${WARMUP_SRC}/.pi" ]; then
        echo "[entrypoint] force syncing .pi configuration from ${WARMUP_SRC}"
        tar -C "${WARMUP_SRC}" -cf - .pi | tar -C "${WORKSPACE}" -xpf -
    fi

    # 版本戳最后写
    # 保证如果中途中断，下次启动仍会重试同步
    mkdir -p "${WORKSPACE}/.warmup"

    cp \
        "${WARMUP_SRC}/.warmup/version" \
        "${WORKSPACE}/.warmup/version"

    echo "[entrypoint] sync done"
fi

exec "$@"
