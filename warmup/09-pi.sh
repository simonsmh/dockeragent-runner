#!/usr/bin/env bash
# 预热 pi-acp：预装插件扩展、执行 ACP 初始化暖机以完成首次缓存，并配置 settings
set -euo pipefail

: "${OPENAI_ENV_API_KEY:?OPENAI_ENV_API_KEY is required for pi-acp warmup}"
: "${OPENAI_ENV_BASE_URL:?OPENAI_ENV_BASE_URL is required for pi-acp warmup}"

echo "[warmup/pi] pre-installing pi extensions..."

# Enforce HOME so they write to the warmup target directory, 
# then reclaim ownership for the node user.
sudo HOME="${WARMUP_HOME}" pi install npm:pi-provider-env
sudo HOME="${WARMUP_HOME}" pi install npm:pi-mcp-adapter

# Trigger ACP initialize and session/new flow to warm up caches and configuration
echo "[warmup/pi] warming up acp connection..."
INIT='{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":1,"clientInfo":{"name":"dockeragent","version":"0.1.0"},"clientCapabilities":{"fs":{"readTextFile":true,"writeTextFile":true},"terminal":true}}}'
SESSION='{"jsonrpc":"2.0","id":2,"method":"session/new","params":{"cwd":"/home/node"}}'

mkfifo /tmp/pi-warmup.in
( printf '%s\n%s\n' "$INIT" "$SESSION"; sleep 300 ) > /tmp/pi-warmup.in &
WRITER_PID=$!

# Execute pi-acp using the warmup HOME
# Also skip update check during warmup to avoid delay
export PI_SKIP_VERSION_CHECK=1
sudo -E HOME="${WARMUP_HOME}" pi-acp < /tmp/pi-warmup.in > /tmp/pi-warmup.log 2>&1 &
ACP_PID=$!

# Wait for session/new response (up to 120s)
for i in $(seq 1 60); do
    if grep -q '"sessionId"' /tmp/pi-warmup.log 2>/dev/null; then
        echo "[warmup/pi] session/new done at ${i}x2s"
        break
    elif grep -q '"error"' /tmp/pi-warmup.log 2>/dev/null; then
        echo "[warmup/pi] warmup failed during ACP flow:"
        cat /tmp/pi-warmup.log
        kill $ACP_PID $WRITER_PID 2>/dev/null || true
        wait $ACP_PID 2>/dev/null || true
        rm -f /tmp/pi-warmup.in /tmp/pi-warmup.log
        exit 1
    fi
    sleep 2
done

kill $ACP_PID $WRITER_PID 2>/dev/null || true
wait $ACP_PID 2>/dev/null || true
rm -f /tmp/pi-warmup.in /tmp/pi-warmup.log

# Configure settings.json to optimize startup and suppress redundant warnings/telemetry
SETTINGS_FILE="${WARMUP_HOME}/.pi/agent/settings.json"
if [ -f "$SETTINGS_FILE" ]; then
    echo "[warmup/pi] optimizing settings.json..."
    sudo jq '.quietStartup = true | .enableInstallTelemetry = false | .warnings.anthropicExtraUsage = false' "$SETTINGS_FILE" > /tmp/settings.json.tmp
    sudo mv /tmp/settings.json.tmp "$SETTINGS_FILE"
fi

sudo chown -R node:node "${WARMUP_HOME}/.pi"

echo "[warmup/pi] done"
