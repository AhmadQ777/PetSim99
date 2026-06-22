pkg update -y && pkg upgrade -y && pkg install python curl tmux procps -y && pip install requests && termux-setup-storage && termux-wake-lock

mkdir -p ~/PetSim99
mkdir -p /storage/emulated/0/Delta/Autoexecute
mkdir -p /storage/emulated/0/Delta/Workspace
cd ~/PetSim99

[ ! -f state.json ] && echo '{"lua_ver":"","py_ver":""}' > state.json

WEBHOOK="https://discord.com/api/webhooks/1518233664771588307/pbbS7bP6GRvczqDjs-fzhjRVuTabzOaohnnffrpjWApjuInrqsFCcHgIx72TPvubH36X"

send_hook() {
    curl -s -H "Content-Type: application/json" \
    -d "{\"content\":\"$1\"}" \
    "$WEBHOOK" >/dev/null 2>&1
}

send_hook "🟢 PetSim99 Ultra Watchdog gestartet"

# ---------------- RETRY QUEUE (ANTI SPAM) ----------------
retry_download() {
    URL="$1"
    OUT="$2"

    i=1
    while [ $i -le 3 ]; do
        if curl -s --fail --max-time 10 "$URL" -o "$OUT"; then
            return 0
        fi
        sleep $((i * 3))
        i=$((i + 1))
    done
    return 1
}

start_api() {
    if ! pgrep -f "API.py" > /dev/null; then
        nohup python /storage/emulated/0/Delta/Workspace/API.py >/dev/null 2>&1 &
        send_hook "🚀 API gestartet"
    fi
}

# ---------------- MAIN LOOP (LOW CPU) ----------------
while true; do

# -------- CONFIG (WITH RETRY QUEUE) --------
if ! retry_download "https://raw.githubusercontent.com/AhmadQ777/PetSim99/main/Data/Config.json" "Config.json"; then
    send_hook "❌ Config failed (3 retries)"
    sleep 10
    continue
fi

python - <<'EOF'
import json, sys
try:
    json.load(open("Config.json"))
except:
    sys.exit(1)
EOF

[ $? -ne 0 ] && send_hook "❌ Config corrupted" && sleep 10 && continue

# -------- READ CONFIG --------
LUA_URL=$(python -c "import json;print(json.load(open('Config.json'))['Info']['Main']['Url'])")
LUA_VER=$(python -c "import json;print(json.load(open('Config.json'))['Info']['Main']['Version'])")

PY_URL=$(python -c "import json;print(json.load(open('Config.json'))['Info']['API']['Url'])")
PY_VER=$(python -c "import json;print(json.load(open('Config.json'))['Info']['API']['Version'])")

LUA_STATE=$(python -c "import json;print(json.load(open('state.json'))['lua_ver'])")
PY_STATE=$(python -c "import json;print(json.load(open('state.json'))['py_ver'])")

# -------- LUA UPDATE (NO SPAM) --------
if [ "$LUA_VER" != "$LUA_STATE" ] || [ ! -f /storage/emulated/0/Delta/Autoexecute/Main.lua ]; then
    retry_download "$LUA_URL" "/storage/emulated/0/Delta/Autoexecute/Main.lua" && \
    python -c "import json;d=json.load(open('state.json'));d['lua_ver']='$LUA_VER';json.dump(d,open('state.json','w'))" && \
    send_hook "📦 LUA updated $LUA_VER"
fi

# -------- PY UPDATE (NO SPAM) --------
if [ "$PY_VER" != "$PY_STATE" ] || [ ! -f /storage/emulated/0/Delta/Workspace/API.py ]; then
    retry_download "$PY_URL" "/storage/emulated/0/Delta/Workspace/API.py" && \
    python -c "import json;d=json.load(open('state.json'));d['py_ver']='$PY_VER';json.dump(d,open('state.json','w'))" && \
    send_hook "📦 API updated $PY_VER"
fi

# -------- CRASH SAFE SUPERVISOR --------
if ! pgrep -f "API.py" > /dev/null; then
    start_api
fi

# -------- CPU OPTIMIZED LOOP --------
sleep 180

done