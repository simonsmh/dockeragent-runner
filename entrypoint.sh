#!/usr/bin/env bash
# entrypoint.sh
#
# 首次启动时把 /opt/home 的预热产物同步到 workspace（/home/node）。
# 用版本戳判断是否需要同步，支持镜像升级后增量补齐新文件。
#
# 设计原则：
#   - cp -an：no-clobber，不覆盖用户已有文件（保护对话历史、用户配置）
#   - 版本戳最后写，保证中断时下次重试
#   - 以 node 用户身份执行真正的命令（gosu 降权）
set -eu

WARMUP_SRC=/opt/home
WORKSPACE=/home/node

SRC_VER="$(cat "${WARMUP_SRC}/.warmup/version" 2>/dev/null || echo none)"
DST_VER="$(cat "${WORKSPACE}/.warmup/version" 2>/dev/null || echo none)"

if [ "${SRC_VER}" != "${DST_VER}" ]; then
    echo "[entrypoint] syncing warmup home: src_ver=${SRC_VER} dst_ver=${DST_VER}"
    # -a 保留属性，-n 不覆盖已有文件（保护用户数据）
    cp -an "${WARMUP_SRC}/." "${WORKSPACE}/" 2>/dev/null || true
    # copy 过来的文件 owner 是 root（warmup 以 root 执行），统一改成 node
    chown -R node:node "${WORKSPACE}/" 2>/dev/null || true
    # 版本戳最后写，保证中断时下次还会重试
    mkdir -p "${WORKSPACE}/.warmup"
    cp "${WARMUP_SRC}/.warmup/version" "${WORKSPACE}/.warmup/version"
    chown -R node:node "${WORKSPACE}/.warmup" 2>/dev/null || true
    echo "[entrypoint] sync done"
fi

# 降权到 node 用户执行真正的命令
exec gosu node "$@"
