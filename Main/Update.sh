pkg update -y && pkg upgrade -y && pkg install python curl tmux procps -y && pip install requests && termux-setup-storage && termux-wake-lock

mkdir -p ~/PetSim99
mkdir -p /storage/emulated/0/Delta/Autoexecute
mkdir -p /storage/emulated/0/Delta/Workspace
cd ~/PetSim99

# ---------------- STATE ----------------
[ ! -f state.json ] && echo '{"lua_ver":"","py_ver":""}' > state.json

# ---------------- WEBHOOK ----------------
WEBHOOK="https://discord.com/api/webhooks/1518233664771588307/pbbS7bP6GRvczqDjs-fzhjRVuTabzOaohnnffrpjWApjuInrqsFCcHgIx72TPvubH36X"

send_hook() {
    MSG="$1"
    curl -s -H "Content-Type: application/json" \
    -d "{\"content\":\"$MSG\"}" \
    "$WEBHOOK" >/dev/null 2>&1
}

send_hook "🟢 Watchdog gestartet"

# ---------------- SIMPLE SAFE START ----------------
start_api() {
    pkill -f "API.py" 2>/dev/null
    sleep 1
    nohup python /storage/emulated/0/Delta/Workspace/API.py >/dev/null 2>&1 &
}

# ---------------- RETRY DOWNLOAD (NO SPAM SAFE) ----------------
retry_download() {
    URL="$1"
    OUT="$2"

    for i in 1 2 3; do
        if curl -s --fail --max-time 10 "$URL" -o "$OUT"; then
            return 0
        fi
        sleep 2
    done
    return 1
}

# ---------------- MAIN LOOP ----------------
while true; do

    # -------- CONFIG --------
    if ! retry_download \
    "https://raw.githubusercontent.com/AhmadQ777/PetSim99/main/Data/Config.json" \
    "Config.json"; then
        sleep 180
        continue
    fi

    python - <<'EOF'
import json, sys
try:
    json.load(open("Config.json"))
except:
    sys.exit(1)
EOF

    [ $? -ne 0 ] && sleep 180 && continue

    # -------- READ CONFIG --------
    LUA_URL=$(python -c "import json;print(json.load(open('Config.json'))['Info']['Main']['Url'])")
    LUA_VER=$(python -c "import json;print(json.load(open('Config.json'))['Info']['Main']['Version'])")

    PY_URL=$(python -c "import json;print(json.load(open('Config.json'))['Info']['API']['Url'])")
    PY_VER=$(python -c "import json;print(json.load(open('Config.json'))['Info']['API']['Version'])")

    LUA_STATE=$(python -c "import json;print(json.load(open('state.json'))['lua_ver'])")
    PY_STATE=$(python -c "import json;print(json.load(open('state.json'))['py_ver'])")

    # -------- LUA UPDATE --------
    if [ "$LUA_VER" != "$LUA_STATE" ] || [ ! -f /storage/emulated/0/Delta/Autoexecute/Main.lua ]; then
        if retry_download "$LUA_URL" "/storage/emulated/0/Delta/Autoexecute/Main.lua"; then
            python -c "import json;d=json.load(open('state.json'));d['lua_ver']='$LUA_VER';json.dump(d,open('state.json','w'))"
            send_hook "📦 LUA updated $LUA_VER"
        fi
    fi

    # -------- PY UPDATE --------
    if [ "$PY_VER" != "$PY_STATE" ] || [ ! -f /storage/emulated/0/Delta/Workspace/API.py ]; then
        if retry_download "$PY_URL" "/storage/emulated/0/Delta/Workspace/API.py"; then
            python -c "import json;d=json.load(open('state.json'));d['py_ver']='$PY_VER';json.dump(d,open('state.json','w'))"
            send_hook "📦 API updated $PY_VER"
        fi
    fi

    # -------- CRASH SAFE CHECK (NO SPAM) --------
    if ! pgrep -f "API.py" >/dev/null; then
        start_api
        send_hook "🔁 API restarted"
    fi

    # -------- STABLE LOOP DELAY --------
    sleep 180

done