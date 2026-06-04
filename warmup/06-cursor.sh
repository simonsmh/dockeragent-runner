#!/usr/bin/env bash
# 预热 cursor agent：触发 session/new 让其完成首次初始化
set -euo pipefail

: "${CURSOR_API_KEY:?CURSOR_API_KEY is required}"

INIT='{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":1,"clientCapabilities":{"fs":{"readTextFile":true,"writeTextFile":true},"terminal":true}}}'
SESSION='{"jsonrpc":"2.0","id":2,"method":"session/new","params":{"cwd":"/home/node","mcpServers":[]}}'

mkfifo /tmp/cursor-warmup.in
( printf '%s\n%s\n' "$INIT" "$SESSION"; sleep 300 ) > /tmp/cursor-warmup.in &
WRITER_PID=$!

agent acp --trust --approve-mcps --skip-worktree-setup < /tmp/cursor-warmup.in > /tmp/cursor-warmup.log 2>&1 &
ACP_PID=$!

# 等待 session/new response（最多 120s）
for i in $(seq 1 60); do
    if grep -q '"sessionId"' /tmp/cursor-warmup.log 2>/dev/null; then
        echo "[warmup/cursor] session/new done at ${i}x2s"
        break
    elif ! kill -0 $ACP_PID 2>/dev/null; then
        echo "[warmup/cursor] agent exited prematurely."
        cat /tmp/cursor-warmup.log
        break
    elif grep -q '"error"' /tmp/cursor-warmup.log 2>/dev/null; then
        echo "[warmup/cursor] error in agent log:"
        cat /tmp/cursor-warmup.log
        break
    fi
    sleep 2
done

kill $ACP_PID $WRITER_PID 2>/dev/null || true
wait $ACP_PID 2>/dev/null || true
rm -f /tmp/cursor-warmup.in /tmp/cursor-warmup.log

echo "[warmup/cursor] done"
echo "[warmup/cursor] workspace contents:"
ls -la "${WARMUP_HOME}/" 2>/dev/null || true
