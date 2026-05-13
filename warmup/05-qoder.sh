#!/usr/bin/env bash
# 预热 qodercli：触发 session/new 让其完成首次初始化（下载模型/缓存等）
set -euo pipefail

: "${QODER_PERSONAL_ACCESS_TOKEN:?QODER_PERSONAL_ACCESS_TOKEN is required}"

INIT='{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":1,"clientCapabilities":{"fs":{"readTextFile":true,"writeTextFile":true},"terminal":true}}}'
SESSION='{"jsonrpc":"2.0","id":2,"method":"session/new","params":{"cwd":"/home/node","mcpServers":[]}}'

mkfifo /tmp/qoder-warmup.in
( printf '%s\n%s\n' "$INIT" "$SESSION"; sleep 300 ) > /tmp/qoder-warmup.in &
WRITER_PID=$!

qodercli --dangerously-skip-permissions --acp < /tmp/qoder-warmup.in > /tmp/qoder-warmup.log 2>&1 &
ACP_PID=$!

# 等待 session/new response（最多 120s）
for i in $(seq 1 60); do
    if grep -q '"sessionId"' /tmp/qoder-warmup.log 2>/dev/null; then
        echo "[warmup/qoder] session/new done at ${i}x2s"
        break
    fi
    sleep 2
done

kill $ACP_PID $WRITER_PID 2>/dev/null || true
wait $ACP_PID 2>/dev/null || true
rm -f /tmp/qoder-warmup.in /tmp/qoder-warmup.log

echo "[warmup/qoder] done"
echo "[warmup/qoder] workspace contents:"
ls -la "${WARMUP_HOME}/" 2>/dev/null || true
