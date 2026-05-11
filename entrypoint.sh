#!/usr/bin/env bash
# entrypoint.sh
#
# 首次启动时把 /opt/home 的预热产物同步到 workspace（/home/node）。
# 用版本戳判断是否需要同步，支持镜像升级后增量补齐新文件。
#
# 设计原则：
#   - cp -an：no-clobber，不覆盖用户已有文件（保护对话历史、用户配置）
#   - 版本戳最后写，保证中断时下次重试
#   - 容器以 1000:1000 启动（docker_infra.py _CONTAINER_USER），无需降权
set -eu

WARMUP_SRC=/opt/home
WORKSPACE=/home/node

SRC_VER="$(cat "${WARMUP_SRC}/.warmup/version" 2>/dev/null || echo none)"
DST_VER="$(cat "${WORKSPACE}/.warmup/version" 2>/dev/null || echo none)"

if [ "${SRC_VER}" != "${DST_VER}" ]; then
    echo "[entrypoint] syncing warmup home: src_ver=${SRC_VER} dst_ver=${DST_VER}"
    # -a 保留属性，-n 不覆盖已有文件（保护用户数据）
    # /opt/home 在构建时已 chown 1000:1000，容器以 1000:1000 启动，直接可写
    cp -an "${WARMUP_SRC}/." "${WORKSPACE}/" 2>/dev/null || true
    # 版本戳最后写，保证中断时下次还会重试
    mkdir -p "${WORKSPACE}/.warmup"
    cp "${WARMUP_SRC}/.warmup/version" "${WORKSPACE}/.warmup/version"
    echo "[entrypoint] sync done"
fi

exec "$@"
