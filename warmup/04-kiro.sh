#!/usr/bin/env bash
# 预热 kiro-cli：触发 session/new 让其下载 all-MiniLM-L6-v2 语义搜索模型（~91MB）
set -euo pipefail

: "${KIRO_API_KEY:?KIRO_API_KEY is required}"

INIT='{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":1,"clientCapabilities":{"fs":{"readTextFile":true,"writeTextFile":true},"terminal":true}}}'
SESSION='{"jsonrpc":"2.0","id":2,"method":"session/new","params":{"cwd":"/home/node","mcpServers":[]}}'

mkfifo /tmp/kiro-warmup.in
( printf '%s\n%s\n' "$INIT" "$SESSION"; sleep 300 ) > /tmp/kiro-warmup.in &
WRITER_PID=$!

kiro-cli acp --trust-all-tools < /tmp/kiro-warmup.in > /tmp/kiro-warmup.log 2>&1 &
ACP_PID=$!

MODEL_DIR="${WARMUP_HOME}/.semantic_search/models/all-MiniLM-L6-v2"
for i in $(seq 1 90); do
    if [ -s "${MODEL_DIR}/model.safetensors" ] && [ -s "${MODEL_DIR}/tokenizer.json" ]; then
        echo "[warmup/kiro] model ready at ${i}x2s (~$((i*2))s)"
        ls -lh "${MODEL_DIR}/"
        break
    elif ! kill -0 $ACP_PID 2>/dev/null; then
        echo "[warmup/kiro] kiro-cli exited prematurely."
        cat /tmp/kiro-warmup.log
        break
    elif grep -q '"error"' /tmp/kiro-warmup.log 2>/dev/null; then
        echo "[warmup/kiro] error in kiro-cli log:"
        cat /tmp/kiro-warmup.log
        break
    fi
    sleep 2
done

kill $ACP_PID $WRITER_PID 2>/dev/null || true
wait $ACP_PID 2>/dev/null || true
rm -f /tmp/kiro-warmup.in /tmp/kiro-warmup.log

test -s "${MODEL_DIR}/model.safetensors" || { echo "[warmup/kiro] FAILED: model not downloaded"; exit 1; }
echo "[warmup/kiro] done"
