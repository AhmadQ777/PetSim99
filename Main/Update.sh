# ==============================
# TERMUX FULL AUTO WATCHDOG FIXED
# ==============================

pkg update -y && pkg upgrade -y
pkg install python curl tmux procps -y
pip install requests
termux-setup-storage

mkdir -p ~/PetSim99
mkdir -p /storage/emulated/0/Delta/Autoexecute
mkdir -p /storage/emulated/0/Delta/Workspace

cd ~/PetSim99

# ---------------- STATE SAFE ----------------
echo '{"lua_ver":"","py_ver":""}' > state.json

# ---------------- WEBHOOK ----------------
WEBHOOK="https://discord.com/api/webhooks/XXXXX"

send_hook() {
    MSG="$1"
    curl -s -H "Content-Type: application/json" \
    -d "{\"content\":\"$MSG\"}" \
    "$WEBHOOK" >/dev/null 2>&1
}

send_hook "🟢 Watchdog gestartet"

# ---------------- API START ----------------
start_api() {
    pkill -f "API.py" 2>/dev/null
    sleep 1
    nohup python /storage/emulated/0/Delta/Workspace/API.py >/dev/null 2>&1 &
}

# ---------------- SAFE DOWNLOAD ----------------
retry_download() {
    URL="$1"
    OUT="$2"

    for i in 1 2 3; do
        curl -s --fail --max-time 10 "$URL" -o "$OUT" && return 0
        sleep 2
    done
    return 1
}

# ---------------- LOOP ----------------
while true; do

    # CONFIG
    if ! retry_download "https://raw.githubusercontent.com/AhmadQ777/PetSim99/main/Data/Config.json" "Config.json"; then
        sleep 180
        continue
    fi

    # VALIDATE JSON
    python - <<'EOF'
import json,sys
try:
    json.load(open("Config.json"))
except:
    sys.exit(1)
EOF

    [ $? -ne 0 ] && sleep 180 && continue

    # READ CONFIG
    LUA_URL=$(python -c "import json;d=json.load(open('Config.json'));print(d['Info']['Main']['Url'])")
    LUA_VER=$(python -c "import json;d=json.load(open('Config.json'));print(d['Info']['Main']['Version'])")

    PY_URL=$(python -c "import json;d=json.load(open('Config.json'));print(d['Info']['API']['Url'])")
    PY_VER=$(python -c "import json;d=json.load(open('Config.json'));print(d['Info']['API']['Version'])")

    LUA_STATE=$(python -c "import json;d=json.load(open('state.json'));print(d.get('lua_ver',''))")
    PY_STATE=$(python -c "import json;d=json.load(open('state.json'));print(d.get('py_ver',''))")

    # LUA UPDATE
    if [ "$LUA_VER" != "$LUA_STATE" ]; then
        if retry_download "$LUA_URL" "/storage/emulated/0/Delta/Autoexecute/Main.lua"; then
            python -c "import json;d=json.load(open('state.json'));d['lua_ver']='$LUA_VER';json.dump(d,open('state.json','w'))"
            send_hook "📦 LUA updated $LUA_VER"
        fi
    fi

    # PY UPDATE
    if [ "$PY_VER" != "$PY_STATE" ]; then
        if retry_download "$PY_URL" "/storage/emulated/0/Delta/Workspace/API.py"; then
            python -c "import json;d=json.load(open('state.json'));d['py_ver']='$PY_VER';json.dump(d,open('state.json','w'))"
            send_hook "📦 API updated $PY_VER"
        fi
    fi

    # CRASH SAFE API CHECK
    if ! pgrep -f "API.py" >/dev/null; then
        start_api
        send_hook "🔁 API restarted"
    fi

    sleep 180

done